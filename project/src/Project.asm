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
    DEFINE  DEBUG_BORDERS           ; enable the color stripes in border

    STRUCT S_SPRITE_4B_ATTR     ; helper structure to work with 4B sprites attributes
x       BYTE    0       ; X0:7
y       BYTE    0       ; Y0:7
mrx8    BYTE    0       ; PPPP Mx My Rt X8 (pal offset, mirrors, rotation, X8)
vpat    BYTE    0       ; V 0 NNNNNN (visible, 5B type=off, pattern number 0..63)
    ENDS

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

        ;nextreg TURBO_CONTROL_NR_07,2       ; switch to 14MHz as final speed (it's more than enough)
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
        nextreg SPRITE_TRANSPARENCY_I_NR_4B, 16

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

        ;call UploadSprites

UploadSprites:
    ; SpecBong sprite gfx does use the default palette: color[i] = convert8bitColorTo9bit(i);
    ; which is set by the NEX loader in the first sprite palette
        ; nothing to do here in the code with sprite palette

    ; upload the sprite gfx patterns to patterns memory (from regular memory - loaded by NEX loader)
        ; preconfigure the Next for uploading patterns from slot 0
        ld      bc,SPRITE_STATUS_SLOT_SELECT_P_303B
        xor     a
        out     (c),a       ; select slot 0 for patterns (selects also index 0 for attributes)
        ; we will map full 16kiB to memory region $C000..$FFFF (to pages 25,26 with sprite pixels)
        nextreg MMU6_C000_NR_56,$$SpritePixelData   ; C000..DFFF <- 8k page 25
        nextreg MMU7_E000_NR_57,$$SpritePixelData+1 ; E000..FFFF <- 8k page 26
        ld      hl,SpritePixelData      ; HL = $C000 (beginning of the sprite pixels)
        ld      bc,SPRITE_PATTERN_P_5B  ; sprite pattern-upload I/O port, B=0 (inner loop counter)
        ld      a,64                    ; 64 patterns (outer loop counter), each pattern is 256 bytes long
UploadSpritePatternsLoop:
        ; upload 256 bytes of pattern data (otir increments HL and decrements B until zero)
        otir                            ; B=0 ahead, so otir will repeat 256x ("dec b" wraps 0 to 255)
        dec     a
        jr      nz,UploadSpritePatternsLoop ; do 64 patterns

; create in memory record of sprite positions?
        ; init them at some debug positions, they will for part 3 just fly around mindlessly
        ld      ix,SprSnowballs         ; IX = address of first snowball sprite
        ld      b,128                    ; define 32 of them
        ld      hl,0                    ; HL will generate X positions
        ld      e,128                    ; E will generate Y positions
        ld      d,$80 + 13              ; visible sprite + snowball pattern (52, second is 53)
InitBallsLoop:
        ; set current ball data
        ld      (ix+S_SPRITE_4B_ATTR.x),l
        ld      (ix+S_SPRITE_4B_ATTR.y),e
        ld      (ix+S_SPRITE_4B_ATTR.mrx8),h    ; clear pal offset, mirrors, rotate, set x8
        ld      (ix+S_SPRITE_4B_ATTR.vpat),d
        ; adjust initial position and pattern for next ball
        add     hl,13                   ; 13*32 = 416: will produce X coordinates 0..511 range only
        ld      a,e
        add     a,5
        ld      e,a                     ; 5*32 = 160 pixel spread vertically
        ld      a,d
        ;xor     1                       ; alternate snowball patterns between 52/53
        ld      d,a
        ; advance IX to point to next snowball
        push    de
        ld      de,S_SPRITE_4B_ATTR
        add     ix,de
        pop     de
        djnz    InitBallsLoop
        ; init player at debug position
        ld      ix,SprPlayer
        ld      (ix+S_SPRITE_4B_ATTR.x),32+16   ; near left of paper area
        ld      (ix+S_SPRITE_4B_ATTR.y),206     ; near bottom of paper area
        ld      (ix+S_SPRITE_4B_ATTR.mrx8),0    ; clear pal offset, mirrors, rotate, x8
        ld      (ix+S_SPRITE_4B_ATTR.vpat),$80 + 1  ; pattern "2" (player

.mainLoop:
       
        call    WaitForScanlineUnderUla

        IFDEF DEBUG_BORDERS             ; red border: to measure the sprite upload time by tallness of the border stripe
            ld      a,2
            out     (ULA_P_FE),a
        ENDIF

    ; upload sprite data from memory array to the actual HW sprite engine
        ; reset sprite index for upload
        ld      bc,SPRITE_STATUS_SLOT_SELECT_P_303B
        xor     a
        out     (c),a       ; select slot 0 for sprite attributes
        ld      hl,Sprites
        ld      bc,SPRITE_ATTRIBUTE_P_57       ; B = 0 (repeat 256x), C = sprite pattern-upload I/O port
        ; out 512 bytes in total (whole sprites buffer)
        otir
        otir
        otir

        IFDEF DEBUG_BORDERS 
            ; magenda border: to measure clear screen performance
            ld      a,MAGENTA
            out     (ULA_P_FE),a
        ENDIF

        ;call ZxFastClearScreen
            ; adjust sprite attributes in memory pointlessly (in debug way) just to see some movement
        call    SnowballsAI
 
        IFDEF DEBUG_BORDERS
            ; green border: to measure the player rendering
            ld      a,GREEN
            out     (ULA_P_FE),a
        ENDIF 
 
        call    ReadInputDevices
        call    Player1MoveByControls     

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

    ;-------------------------------------------------------------------------------------
    ; "AI" subroutines

Player1MoveByControls:
    ; update "cooldown" of fire button to allow it only once per 10 frames
        ld      a,(Player1FireCoolDown)
        sub     1           ; SUB to update also carry flag
        adc     a,0         ; clamp the value to 0 to not go -1
        ld      (Player1FireCoolDown),a
    ; just DEBUG: up/down/left/right over whole screen, fire changing animation frame
        ld      ix,SprPlayer
        ld      a,(Player1Controls)
        ld      b,a         ; keep control bits around in B for simplicity
        ; HL = current X coordinate (9 bit)
        ld      l,(ix+S_SPRITE_4B_ATTR.x)
        ld      h,(ix+S_SPRITE_4B_ATTR.mrx8)
        ld      c,h         ; preserve current mirrorX
        bit     JOY_BIT_RIGHT,b
        jr      z,.notGoingRight
        ld      (ix+S_SPRITE_4B_ATTR.vpat),$80+0
        inc     hl
        inc     hl          ; X += 2
        res     3,c         ; mirrorX=0 (face right)
.notGoingRight:
        bit     JOY_BIT_LEFT,b
        jr      z,.notGoingLeft
        dec     hl
        dec     hl          ; X -= 2
        set     3,c         ; mirrorX=1 (face left)
        ld      (ix+S_SPRITE_4B_ATTR.vpat),$80+0
.notGoingLeft:
        ; sanitize HL to values range 32..271 (16px sprite fully visible in PAPER area)
        ld      de,32
        ; first clear top bits of H to keep only "x8" bit of it (remove mirrors/rot/pal data)
        rr      h           ; Fcarry = x8
        ld      h,0
        rl      h           ; x8 back to H, Fcarry=0 (for sbc)
        sbc     hl,de
        add     hl,de       ; Fc=1 when HL is 0..31
        jr      nc,.XposIs32plus
        ex      de,hl       ; for 0..31 reset the Xpos=HL=32
.XposIs32plus:
        ld      de,32+256-16    ; 272 - first position when sprite has one px in border
        or      a           ; Fc=0
        sbc     hl,de
        add     hl,de       ; Fc=1 when HL is 32..271
        jr      c,.XposIsValid
        ex      de,hl
        dec     hl          ; for 272+ reset the Xpos=HL=271
.XposIsValid:
        ; store the sanitized X post and new mirrorX to player sprite values
        ld      a,c
        and     ~1          ; clear x8 bit (preserves only mirror/rotate/...)
        or      h           ; merge x8 back
        ld      (ix+S_SPRITE_4B_ATTR.x),l
        ld      (ix+S_SPRITE_4B_ATTR.mrx8),a
        ; vertical movement
        ld      a,(ix+S_SPRITE_4B_ATTR.y)

        bit     JOY_BIT_UP,b
        jr      z,.notGoingUp
        dec     a
        dec     a           ; Y -= 2
        cp      32          ; sanitize right here
        ld      (ix+S_SPRITE_4B_ATTR.vpat),$80+2
        jr      nc,.notGoingUp
        ld      a,32        ; 0..31 -> Y=32


.notGoingUp:
        bit     JOY_BIT_DOWN,b
        jr      z,.notGoingDown
        inc     a
        inc     a           ; Y += 2
        cp      32+192-16   ; sanitize right here (208+ is outside of PAPER area)
        ld      (ix+S_SPRITE_4B_ATTR.vpat),$80+1
        jr      c,.notGoingDown
        ld      a,32+192-16-1   ; 208..255 -> Y=207

.notGoingDown:
        ld      (ix+S_SPRITE_4B_ATTR.y),a
        ; change through all 64 sprite patterns when pressing fire
        bit     JOY_BIT_FIRE,b
        ret     z           ; Player1 movement done - no fire button
        ld      a,(Player1FireCoolDown)
        or      a
        ret     nz          ; check "cooldown" of fire, ignore button if still cooling down
        ld      a,10
        ld      (Player1FireCoolDown),a     ; set new "cooldown" if pattern will change
        ; ld      a,(ix+S_SPRITE_4B_ATTR.vpat)
        ; inc     a
        ; and     ~64         ; force the pattern to stay 0..63 and keep +128 for "visible"
        ; ld      (ix+S_SPRITE_4B_ATTR.vpat),a
        ;ld      (ix+S_SPRITE_4B_ATTR.vpat),2
        ret

SnowballsAI:
        ld      ix,SprSnowballs
        ld      de,S_SPRITE_4B_ATTR
        ld      b,128
.loop:
        ; HL = current X coordinate (9 bit)
        ld      l,(ix+S_SPRITE_4B_ATTR.x)
        ld      h,(ix+S_SPRITE_4B_ATTR.mrx8)
        ; adjust it by some +- value deducted from B (32..1 index)
        ld      c,0         ; mirrorX flag = 0
        ld      a,b
        and     3           ; A = 0,1,2,3
        sli     a           ; A = 1, 3, 5, 7
        sub     4           ; A = -3, -1, +1, +3
        ; do: HL += signed(A) (the "add hl,a" is "unsigned", so extra jump+adjust needed)
        jr      nc,.moveRight
        dec     h
        ld      c,$08       ; mirrorX flag = 1
.moveRight:
        add     hl,a
        ; put H and C together to work as palette_offset/mirror/rotate bits with X8 bit
        ld      a,h
        and     1           ; keep only "x8" bit
        or      c           ; add desired mirrorX bit
        ; store the new X coordinate and mirror/rotation flags
        ld      (ix+S_SPRITE_4B_ATTR.x),l
        ld      (ix+S_SPRITE_4B_ATTR.mrx8),a
        ; alternate pattern between 52 and 53
        ld      a,(ix+S_SPRITE_4B_ATTR.vpat)
        ;xor     1
        ld      (ix+S_SPRITE_4B_ATTR.vpat),a
        add     ix,de       ; next snowball
        djnz    .loop       ; do 32 of them
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
        include "Layer2Routines.asm"

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

SpritePos:
        db $20, $20

TotalFrames:                ; count frames for purposes of slower animations/etc
        dword      0

    ; bits encoding inputs as Kempston/MD: https://wiki.specnext.dev/Kempston_Joystick
Player1Controls:
        DB      0
Player1FireCoolDown:
        DB      0

                ; reserve full 128 sprites 4B type (this demo will not use 5B type sprites)
        ALIGN   256                     ; aligned at 256B boundary w/o particular reason (yet)
Sprites:
        DS      128 * S_SPRITE_4B_ATTR, 0
            ; "S_SPRITE_4B_ATTR" works as "sizeof(STRUCT), in this case it equals to 4

        ; the later sprites are drawn above the earlier, current allocation:
            ; SNOWBALLS_CNT will be used for snowballs
            ; next sprite for player
            ; then max SNOWBALLS_CNT are for collision sparks (will render above player) (FX sprite)
        ; the later sprites are drawn above the earlier, so for Part 3 the sprites
        ; 0..31 will be used for snowballs, and sprite 32 for player
        ; adding symbols to point inside the memory reserved above
SprSnowballs:   EQU     Sprites + 0*S_SPRITE_4B_ATTR    ; first snowball sprite at this address
SprPlayer:      EQU     Sprites + 128*S_SPRITE_4B_ATTR   ; player sprite is here


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

    ; palette of image (will land to page 24, first free byte after pixel data)
        ; verify the assumption that the palette starts where expected (page 24, $E000)
        ASSERT $ == $E000 && $$ == 24
BackGroundPalette:
        INCBIN "../data/Background1.tga", 0x12, 3*256  ; 768 bytes of palette data

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
