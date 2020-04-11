;;
;; Sample code
;;

    ; adjusting sjasmplus syntax to my taste (a bit more strict than default) + enable Z80N
    OPT --syntax=abfw --zxnext

    OPT --zxnext=cspect     ;DEBUG enable break/exit fake instructions of CSpect (remove for real board)

    ; include symbolic names for "magic numbers" like NextRegisters and I/O ports
    ; these are equates, so don't actually take up memory, hence why we can
    ; inlcude them here before we set the origin below
    INCLUDE "constants.i.asm"

MAIN_BORDER_COLOR       EQU     1 ;blue

; selecting "Next" as virtual device in assembler, which allows me to set up all banks
; of Next (0..223 8kiB pages = 1.75MiB of memory) and page-in virtual memory
; with SLOT/PAGE/MMU directives as needed, to assemble code/data to different parts
; of memory
    DEVICE ZXSPECTRUMNEXT

    ; Generate a map file for use with Cspect
    CSPECTMAP "project.map"

    org  $8000

Start:
        break   ; this will cause cspect to open the debugger on the launch
        nop
        nop

    ; disable interrupts, we will avoid using them to keep code simpler to understand
        ;di

    ; Set up a default Layer-2 palette
        xor     a               ; Set both the initial index and colour
        nextreg PALETTE_CONTROL_NR_43,%00010000   ; Set current edited palette as Layer 2's first
        nextreg PALETTE_INDEX_NR_40 ,a           ; First index to set will be 0

    ;copy bytes
paletteLoop:
        nextreg PALETTE_VALUE_NR_41,a           ; Send the colour (8-bits only)
        inc     a               ; Set up next colour to send
        jr      nz,paletteLoop         ; Repeat until all 256 colours are sent

        call SetAttribs

mainLoop:
        ; magenda border: to measure clear screen performance
        ld      a,3
        out     (ULA_P_FE),a

        call FastClearScreen

        ; green border: to measure the player AI code performance
        ld      a,4
        out     (ULA_P_FE),a

        ld      de, (InvaderPos)
        ld      a, d
        inc     a
        cp      120
        jr      z, SkipIncrement
        ld      d,a
        ld      (InvaderPos), de
SkipIncrement:
        call    CalcScreenAddress      
        ld      de, UdgInvader
        call    PrintUdg

        ; black border: to measure the jump bonus refresh code performance
        ld      a,0
        out     (ULA_P_FE),a

        call    WaitForScanlineUnderUla

; delay:
;         ld      bc, $01
; delayOuter:
;         ld      de, $1000
; delayInner:
;         dec     de
;         ld      a, d
;         or      e           ;Bitwise OR of E with A (now, A = D | E)
;         jr      nz, delayInner
;         dec     bc
;         ld      a, b
;         or      c           ;Bitwise OR of C with A (now, A = B | C)
;         jr      nz, delayOuter


    ; loop forever
        jr      mainLoop

;-----------------------------------------------------------------------------------
; Print UDG
;
; in:
;   hl = screen address
;   de = udg address
; destroys:
;   b, a, hl, de
PrintUdg:
        ld      b, 8
ScreenLoop:
        ld      a, (de)
        ld      (hl), a
        add     hl, 256
        inc     de
        djnz    ScreenLoop

;-----------------------------------------------------------------------------------
; calculate the screen address for the row, col 0, 0 is top left
; input
;   d = line
;   e = column
; out 
;   hl = contains address
; destroys
;   a
CalcScreenAddress
        ld      hl, MEM_ZX_SCREEN_4000
        
    ; add offset
        ld      a, d
        and     %00000111
        add     a, h
        ld      h, a
        
    ; add 3rd
        ld      a, d
        and     %11000000 ; 3rd mask
        rrca	
        rrca	
        rrca	; rotate right and add to h
        add     a, h
        ld      h, a

    ; add v-cell
        ld      a, d
        and     %00111000
        rlca
        rlca
        add     a, l
        ld      l,a	

    ; add horizontal
        ld      a, e
        add     a, l
        ld      l, a	
	
        ret

;------------------------------------------------------
; Clear Screen
; slow way - see https://zxsnippets.fandom.com/wiki/Clearing_screen
;
; destroys
;   hl
;   de
;   bc      
ClearScreen:
        ld      hl, MEM_ZX_SCREEN_4000        ;pixels 
        ld      de, MEM_ZX_SCREEN_4000+1        ;pixels + 1
        ld      bc, 6143         ;pixels area length - 1
        ld      (hl), 0          ;set first byte to '0'
        ldir  
        ret     

FastClearScreen:
        di                  ;disable interrupt
        ld      (fcs_stack + 1), sp  ;store current stack pointer
        ld      hl, 0            ;this value will be stored on stack
        ld      sp, 16384 + 6144
        ld      c, 3
fcs_loop2:
        ld      b, l             ;set B to 0. it causes that DJNZ will repeat 256 times
fcs_loop1:
        push    hl             ;store hl on stack
        push    hl             ;next
        push    hl             ;these four push instruction stores 8 bytes on stack
        push    hl
        djnz    fcs_loop1          ;repeat for next 8 bytes
        dec     c
        jr      nz, fcs_loop2
fcs_stack
        ld      sp, 0            ;parameter will overwritten
        ei
        ret

SetAttribs:
        ld      hl, MEM_ZX_ATTRIB_5800
        ld      de, MEM_ZX_ATTRIB_5800+1        ;pixels + 1
        ld      bc, 767         ;attr area length - 1
        ld      (hl), 7          ;set first byte to '0'
        ldir  
        ret         

WaitForScanlineUnderUla:
        ; because I decided early to not use interrupts to keep the code a bit simpler
        ; (simpler to follow in mind, not having to expect any interrupt everywhere)
        ; we will be syncing the main game loop by waiting for particular scanline
        ; (just under the ULA paper area, i.e. scanline 192)
    ; update the TotalFrames counter by +1
        ld      hl,(TotalFrames)
        inc     hl
        ld      (TotalFrames),hl
        ; turn the border to the "main" color during wait
        ld      a,MAIN_BORDER_COLOR
        out     (ULA_P_FE),a
        ; if HL=0, increment upper 16bit too
        ld      a,h
        or      l
        jr      nz,.totalFramesUpdated
        ld      hl,(TotalFrames+2)
        inc     hl
        ld      (TotalFrames+2),hl
.totalFramesUpdated:
    ; read NextReg $1F - LSB of current raster line
        ld      bc,TBBLUE_REGISTER_SELECT_P_243B
        ld      a,RASTER_LINE_LSB_NR_1F
        out     (c),a       ; select NextReg $1F
        inc     b           ; BC = TBBLUE_REGISTER_ACCESS_P_253B
    ; if already at scanline 192, then wait extra whole frame (for super-fast game loops)
.cantStartAt192:
        in      a,(c)       ; read the raster line LSB
        cp      192
        jr      z,.cantStartAt192
    ; if not yet at scanline 192, wait for it ... wait for it ...
.waitLoop:
        in      a,(c)       ; read the raster line LSB
        cp      192
        jr      nz,.waitLoop
    ; and because the max scanline number is between 260..319 (depends on video mode),
    ; I don't need to read MSB. 256+192 = 448 -> such scanline is not part of any mode.
        ret
    
;---------------------------------------------------------------------
; Data Area

UdgInvader:
        db %00000000
        db %00011000
        db %01111110
        db %01011010
        db %01011010
        db %01111110
        db %01010100
        db %00000000

InvaderPos:
        db 0, 0

TotalFrames:                ; count frames for purposes of slower animations/etc
        DD      0


;;
;; Set up the Nex output
;;

        ORG $C000
SpritePixelData:
        INCBIN "../data/Link.spr"

        ; This sets the name of the project, the start address, 
        ; and the initial stack pointer.
        SAVENEX OPEN "project.nex", Start, $ff40

        ; This asserts the minimum core version.  Set it to the core version 
        ; you are developing on.
        SAVENEX CORE 2,0,0

        ; This sets the border colour while loading (in this case white),
        ; what to do with the file handle of the nex file when starting (0 = 
        ; close file handle as we're not going to access the project.nex 
        ; file after starting.  See sjasmplus documentation), whether
        ; we preserve the next registers (0 = no, we set to default), and 
        ; whether we require the full 2MB expansion (0 = no we don't).
        SAVENEX CFG 7,0,0,0

        ; Generate the Nex file automatically based on which pages you use.
        SAVENEX AUTO
