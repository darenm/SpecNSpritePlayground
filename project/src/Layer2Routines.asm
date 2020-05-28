;--------------------------------------------------------
; Routines for working with the Layer2 Spectrum Screen
;--------------------------------------------------------

; UploadSprites:
;	 ; SpecBong sprite gfx does use the default palette: color[i] = convert8bitColorTo9bit(i);
;	 ; which is set by the NEX loader in the first sprite palette
;		 ; nothing to do here in the code with sprite palette

;	 ; upload the sprite gfx patterns to patterns memory (from regular memory - loaded by NEX loader)
;		 ; preconfigure the Next for uploading patterns from slot 0
;		 ld	  bc,SPRITE_STATUS_SLOT_SELECT_P_303B
;		 xor	 a
;		 out	 (c),a	   ; select slot 0 for patterns (selects also index 0 for attributes)
;		 ; we will map full 16kiB to memory region $C000..$FFFF (to pages 25,26 with sprite pixels)
;		 nextreg MMU6_C000_NR_56,$$SpritePixelData   ; C000..DFFF <- 8k page 25
;		 nextreg MMU7_E000_NR_57,$$SpritePixelData+1 ; E000..FFFF <- 8k page 26
;		 ld	  hl,SpritePixelData	  ; HL = $C000 (beginning of the sprite pixels)
;		 ld	  bc,SPRITE_PATTERN_P_5B  ; sprite pattern-upload I/O port, B=0 (inner loop counter)
;		 ld	  a,64					; 64 patterns (outer loop counter), each pattern is 256 bytes long
; UploadSpritePatternsLoop:
;		 ; upload 256 bytes of pattern data (otir increments HL and decrements B until zero)
;		 otir							; B=0 ahead, so otir will repeat 256x ("dec b" wraps 0 to 255)
;		 dec	 a
;		 jr	  nz,UploadSpritePatternsLoop ; do 64 patterns
;		 ret


;--------------------------------------------------------
; in:
;   hl = sprite data address
UploadSprite: