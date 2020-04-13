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

    DEFINE  DISABLE_INTERRUPTS      ; disable interrupts across app
    ;DEFINE  DEBUG_BORDERS           ; enable the color stripes in border

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
        break: nop: nop   ; this will cause cspect to open the debugger on the launch

    ; disable interrupts, we will avoid using them to keep code simpler to understand
        IFDEF DISABLE_INTERRUPTS
            di
        ENDIF

        nextreg TURBO_CONTROL_NR_07,2       ; switch to 14MHz as final speed (it's more than enough)
            ; but makes it somewhat easier on the emulator than max 28MHz mode

    ; make the Layer 2 visible and reset some registers (should be reset by NEXLOAD, but to be safe)
        nextreg DISPLAY_CONTROL_NR_69,$80   ; Layer 2 visible, ULA bank 5, Timex mode 0
        nextreg SPRITE_CONTROL_NR_15,%000'100'01 ; LoRes off, layer priority USL, sprites visible
        nextreg LAYER2_RAM_BANK_NR_12,9     ; visible Layer 2 starts at bank 9
        nextreg LAYER2_CONTROL_NR_70,0      ; 256x192x8 Layer 2 mode, L2 palette offset +0
        nextreg LAYER2_XOFFSET_NR_16,0      ; Layer 2 X,Y offset = [0,0]
        nextreg LAYER2_XOFFSET_MSB_NR_71,0  ; including the new NextReg 0x71 for cores 3.0.6+
        nextreg LAYER2_YOFFSET_NR_17,0

    ; set all three clip windows (Sprites, Layer2, ULA) explicitly just to be sure
        ; helps with bug in CSpect which draws sprites "over-border" even when it is OFF
        nextreg CLIP_WINDOW_CONTROL_NR_1C,$03   ; reset write index to all three clip windows
        nextreg CLIP_LAYER2_NR_18,0
        nextreg CLIP_LAYER2_NR_18,255
        nextreg CLIP_LAYER2_NR_18,0
        nextreg CLIP_LAYER2_NR_18,191
        nextreg CLIP_SPRITE_NR_19,0
        nextreg CLIP_SPRITE_NR_19,255
        nextreg CLIP_SPRITE_NR_19,0
        nextreg CLIP_SPRITE_NR_19,191
        nextreg CLIP_ULA_LORES_NR_1A,0
        nextreg CLIP_ULA_LORES_NR_1A,255
        nextreg CLIP_ULA_LORES_NR_1A,0
        nextreg CLIP_ULA_LORES_NR_1A,191

        
            ; set ULA palette (to have background transparent) and do classic "CLS"
        nextreg PALETTE_CONTROL_NR_43,%0'000'0'0'0'0    ; Classic ULA + custom palette
        nextreg PALETTE_INDEX_NR_40,16+7    ; paper 7
        nextreg PALETTE_VALUE_NR_41,$E3
        nextreg PALETTE_INDEX_NR_40,16+8+7  ; paper 7 + bright 1
        nextreg PALETTE_VALUE_NR_41,$E3
        nextreg GLOBAL_TRANSPARENCY_NR_14,$E3
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A,%000'111'11 ; bright cyan as debug (shouldn't be seen)

    ; do the "CLS"
        ld      hl,MEM_ZX_SCREEN_4000
        ld      de,MEM_ZX_SCREEN_4000+1
        ld      bc,MEM_ZX_ATTRIB_5800-MEM_ZX_SCREEN_4000
        ld      (hl),l
        ldir
        ld      (hl),P_WHITE|BLACK          ; set all attributes to white paper + black ink
        ld      bc,32*24-1
        ldir

;     ; Set up a default Layer-2 palette
;         xor     a               ; Set both the initial index and colour
;         nextreg PALETTE_CONTROL_NR_43,%00010000   ; Set current edited palette as Layer 2's first
;         nextreg PALETTE_INDEX_NR_40 ,a           ; First index to set will be 0

;     ;copy bytes
; .paletteLoop:
;         nextreg PALETTE_VALUE_NR_41,a           ; Send the colour (8-bits only)
;         inc     a                               ; Set up next colour to send
;         jr      nz, .paletteLoop                ; Repeat until all 256 colours are sent


    ; setup Layer 2 palette - map palette data to $E000 region, to process them
        nextreg MMU7_E000_NR_57,$$BackGroundPalette ; map the memory with palette
        nextreg PALETTE_CONTROL_NR_43,%0'001'0'0'0'0    ; write to Layer 2 palette, select first palettes
        nextreg PALETTE_INDEX_NR_40,0       ; color index
        ld      b,0                         ; 256 colors (loop counter)
        ld      hl,BackGroundPalette        ; address of first byte of 256x 24 bit color def.
        ; calculate 9bit color from 24bit value for every color
        ; -> will produce pair of bytes -> write that to nextreg $44
SetPaletteLoop:
        ; TGA palette data are three bytes per color, [B,G,R] order in memory
        ; so palette data are: BBBbbbbb GGGggggg RRRrrrrr
                ; (B/G/R = 3 bits for Next, b/g/r = 5bits too fine for Next, thrown away)
        ; first byte to calculate: RRR'GGG'BB
        ld      a,(hl)      ; Blue
        inc     hl
        rlca
        rlca
        ld      c,a         ; preserve blue third bit in C.b7 ($80)
        and     %000'000'11 ; two blue bits at their position
        ld      e,a         ; preserve blue bits in E
        ld      a,(hl)      ; Green
        inc     hl
        rrca
        rrca
        rrca
        and     %000'111'00
        ld      d,a         ; preserve green bits in D
        ld      a,(hl)      ; Red
        inc     hl
        and     %111'000'00 ; top three red bits
        or      d           ; add green bits
        or      e           ; add blue bits
        nextreg PALETTE_VALUE_9BIT_NR_44,a      ; RRR'GGG'BB
        ; second byte is: p000'000B (priority will be 0 in this app)
        xor     a
        rl      c           ; move top bit from C to bottom bit in A (Blue third bit)
        rla
        nextreg PALETTE_VALUE_9BIT_NR_44,a      ; p000'000B p=0 in this image always
        djnz    SetPaletteLoop

.mainLoop:
       
        call    WaitForScanlineUnderUla

        IFDEF DEBUG_BORDERS 
            ; magenda border: to measure clear screen performance
            ld      a,MAGENTA
            out     (ULA_P_FE),a
        ENDIF

        call ZxFastClearScreen

        IFDEF DEBUG_BORDERS
            ; green border: to measure the player rendering
            ld      a,GREEN
            out     (ULA_P_FE),a
        ENDIF 
 
        ld      hl, InvaderPos1
        call    printInvader
        ld      hl, InvaderPos2
        call    printInvader
        ld      hl, InvaderPos3
        call    printInvader
        ld      hl, InvaderPos4
        call    printInvader
        ld      hl, InvaderPos5
        call    printInvader
        ld      hl, InvaderPos6
        call    printInvader
        ld      hl, InvaderPos7
        call    printInvader
        ld      hl, InvaderPos8
        call    printInvader
        ld      hl, InvaderPos9
        call    printInvader
        

        IFDEF DEBUG_BORDERS
            ; red border: to measure the scrolling
            ld      a,RED
            out     (ULA_P_FE),a
        ENDIF

        ; Scroll the background - wow very easy
        ld hl,  XScrollPos
        ld a,   (hl)
        inc     a
        ld      (hl), a
        nextreg LAYER2_XOFFSET_NR_16, a 

    ; loop forever
        jr      .mainLoop

WaitForScanlineUnderUla:
        ; because I decided early to not use interrupts to keep the code a bit simpler
        ; (simpler to follow in mind, not having to expect any interrupt everywhere)
        ; we will be syncing the main game loop by waiting for particular scanline
        ; (just under the ULA paper area, i.e. scanline 192)
    ; update the TotalFrames counter by +1
        ld      hl,(TotalFrames)
        inc     hl
        ld      (TotalFrames),hl
        IFDEF DEBUG_BORDERS
            ; turn the border to the "main" color during wait
            ld      a,MAIN_BORDER_COLOR
            out     (ULA_P_FE),a
        ENDIF
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

;---------------------------------------
; hl = position address
printInvader:
        ld      d, (hl)
        inc     d
        ld      (hl), d
        inc     hl
        ld      e, (hl)
        inc     e
        ld      (hl), e
        ; ld      d, 0
        ; ld      e, 0
        ld      hl, UdgInvader
        call    PrintUdg
        ret
    
;---------------------------------------------------------------------
; Include Modules
;---------------------------------------------------------------------
        include "Utils.asm"
        include "ULARoutines.asm" 

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

Sprite1:
	db  0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
	db  16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
	db  32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
	db  48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
	db  64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79
	db  80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95
	db  96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111
	db  112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127
	db  128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143
	db  144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	db  160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175
	db  176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191
	db  192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207
	db  208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223
	db  224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239
	db  240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255

InvaderPos1:
        db 5, 0
InvaderPos2:
        db 20, 0
InvaderPos3:
        db 40, 0
InvaderPos4:
        db 60, 0
InvaderPos5:
        db 80, 0
InvaderPos6:
        db 100, 0
InvaderPos7:
        db 120, 0
InvaderPos8:
        db 140, 0
InvaderPos9:
        db 160, 0

XScrollPos:
        db 0

TotalFrames:                ; count frames for purposes of slower animations/etc
        dword      0

;;
;; Set up the Nex output
;;
    ; pre-load the image pixel data from TGA file into memory (to store it in NEX file)
        ; the pixel data will be in 16k banks 9, 10, 11 (8k pages: 18, 19, .., 23)
        ; We will use the last page region $E000..$FFFF to map through all the pages and
        ; include the binary pixel data from the TGA file, using sjasmplus MMU directive
        MMU 7 n, 9*2    ; slot 7 = $E000..$FFFF, "n" option to auto-wrap into next page
        ; now include the binary pixel data from the TGA file at the $E000 address
        ORG $E000
        INCBIN "../data/Background1.tga", 0x12 + 3*256, 256*192
        ;INCBIN "../data/SpecBong.tga", 0x12 + 3*256, 256*192
    ; palette of image (will land to page 24, first free byte after pixel data)
        ; verify the assumption that the palette starts where expected (page 24, $E000)
        ASSERT $ == $E000 && $$ == 24
BackGroundPalette:
        INCBIN "../data/Background1.tga", 0x12, 3*256  ; 768 bytes of palette data
        ;INCBIN "../data/SpecBong.tga", 0x12, 3*256  ; 768 bytes of palette data

    ; sprite pixel data from the raw binary file SBsprite.spr, aligned to next
    ; page after palette data (8k page 25), it will occupy two pages: 25, 26
        MMU 6 7, $$BackGroundPalette + 1    ; using 16ki memory region $C000..$FFFF
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
