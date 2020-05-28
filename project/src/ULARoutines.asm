;--------------------------------------------------------
; Routines for working with the original Spectrum Screen
;--------------------------------------------------------

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
	ld	hl, MEM_ZX_SCREEN_4000
	
	; add offset
	ld	a, d
	and	%00000111
	add	a, h
	ld	h, a
	
	; add 3rd
	ld	a, d
	and	%11000000 ; 3rd mask
	rrca	
	rrca	
	rrca	; rotate right and add to h
	add	a, h
	ld	h, a

	; add v-cell
	ld	a, d
	and	%00111000
	rlca
	rlca
	add	a, l
	ld	l,a	

	; add horizontal
	ld	a, e
	add	a, l
	ld	l, a	
	
	ret	

;------------------------------------------------------
; Clear Screen
; slow way - see https://zxsnippets.fandom.com/wiki/Clearing_screen
;
; destroys
;   hl
;   de
;   bc	
ZxClearScreen:
	ld	hl, MEM_ZX_SCREEN_4000	;pixels 
	ld	de, MEM_ZX_SCREEN_4000+1	;pixels + 1
	ld	bc, 6143	;pixels area length - 1
	ld	(hl), 0	;set first byte to '0'
	ldir  
	ret   

;------------------------------------------------------
; Fast Clear Screen
; slow way - see https://zxsnippets.fandom.com/wiki/Clearing_screen
;
; destroys
;   hl
;   bc	
ZxFastClearScreen:
	IFNDEF DISABLE_INTERRUPTS
		di			;disable interrupt
	ENDIF
	ld	(.stack + 1), sp	;store current stack pointer
	ld	hl, 0		;this value will be stored on stack
	ld	sp, MEM_ZX_SCREEN_4000 + 6144
	ld	c, 3
.loop2:
	ld	b, l		;set B to 0. it causes that DJNZ will repeat 256 times
.loop1:
	push	hl		;store hl on stack
	push	hl		;next
	push	hl		;these four push instruction stores 8 bytes on stack
	push	hl
	djnz	.loop1		;repeat for next 8 bytes
	dec	c
	jr	nz, .loop2
.stack
	ld	sp, 0		;parameter will overwritten
	IFNDEF DISABLE_INTERRUPTS
		ei
	ENDIF
	ret

;------------------------------------------------------
; Clear ZX Attributes
; slow way - see https://zxsnippets.fandom.com/wiki/Clearing_screen
;
; destroys
;   hl
;   de
;   bc  
ZxSetAttribs:
	ld	hl, MEM_ZX_ATTRIB_5800
	ld	de, MEM_ZX_ATTRIB_5800+1	;pixels + 1
	ld	bc, 767			;attr area length - 1
	ld	(hl), 0			;set first byte to '0'
	ldir  
	ret	

;------------------------------------------------------
; Clear LoRes Screen
; slow way - see https://zxsnippets.fandom.com/wiki/Clearing_screen
;
; destroys
;   hl
;   de
;   bc  
LoResClearScreen:
	ld	hl, MEM_LORES0_4000	;pixels 
	ld	de, MEM_LORES0_4000+1	;pixels + 1
	ld	bc, 6143	;pixels area length - 1
	ld	(hl), 24	;set first byte to '0'
	ldir  
	ld	hl, MEM_LORES1_6000	;pixels 
	ld	de, MEM_LORES1_6000+1	;pixels + 1
	ld	bc, 6143	;pixels area length - 1
	ld	(hl), 48	;set first byte to '0'
	ldir  
	ret	
 
;------------------------------------------------------
; Fast Clear LoRes Screen
; slow way - see https://zxsnippets.fandom.com/wiki/Clearing_screen
;
; destroys
;   hl
;   bc	
LoResFastClearScreen:
	IFNDEF DISABLE_INTERRUPTS
		di			;disable interrupt
	ENDIF
	ld	(.stack + 1), sp  ;store current stack pointer
	ld	hl, 0		;this value will be stored on stack
; first half of screen
	ld	sp, MEM_LORES0_4000 + 6144
	ld	c, 3
.loop2:
	ld	b, l		;set B to 0. it causes that DJNZ will repeat 256 times
.loop1:
	push	hl		;store hl on stack
	push	hl		;next
	push	hl		;these four push instruction stores 8 bytes on stack
	push	hl
	djnz	.loop1	;repeat for next 8 bytes
	dec	c
	jr	nz, .loop2
; second half of screen
	ld	sp, MEM_LORES1_6000 + 6144
	ld	c, 3
.loop4:
	ld	b, l		;set B to 0. it causes that DJNZ will repeat 256 times
.loop3:
	push	hl		;store hl on stack
	push	hl		;next
	push	hl		;these four push instruction stores 8 bytes on stack
	push	hl
	djnz	.loop3	;repeat for next 8 bytes
	dec	c
	jr	nz, .loop4
.stack
	ld	sp, 0		;parameter will overwritten
	IFNDEF DISABLE_INTERRUPTS
		ei			
	ENDIF	
	ret

;-----------------------------------------------------------------------------------
; LoRes Print Sprite
;
; in:
;   de = screen address
;   hl = sprite address
; destroys:
;   b, a, hl, de
LoResPrintSprite:
	ld	a, 16	; 16 rows
.rowLoop:
	ld	bc, 16   ; 16 columns	
	ldir
	add	de, $F0
	dec	a
	jr	nz, .rowLoop
	ret

;-----------------------------------------------------------------------------------
; Print UDG
;
; in:
;   de = screen coords d = y, e = x, 
;   hl = sprite address
; destroys:
;   bc, a, hl, de
PrintUdg:
	; check in bounds
	ld	a, 247
	cp	e
	jr	c, .exit ; e > 247

	ld	a, 180
	cp	d
	jr	c, .exit ; d > 180

	push	hl ; preserve UDG address
	pop	bc ; bc contains UDG address
 .8	inc	d  ; repeat inc d 8 times

	pixelad
	push	hl ; row 8 address
	dec	d
	pixelad
	push	hl ; row 7 address
	dec	d
	pixelad
	push	hl ; row 6 address
	dec	d
	pixelad
	push	hl ; row 5 address
	dec	d	
	pixelad
	push	hl ; row 4 address
	dec	d
	pixelad
	push	hl ; row 3 address
	dec	d
	pixelad
	push	hl ; row 2 address
	dec	d
	pixelad
	push	hl ; row 1 address
	dec	d
	ld	a, e ; x
	push	bc  ; udg address
	pop	de  ; contains UDG address
	and	a, %00000'111
	ld	c, a ; if c > 0 then we need to shift
	ld	b, 8
.screenLoop:
	ld	a, (de) ; a is UDG byte
	push	af ; store for comparison
	xor	a ; a = 0
	cp	c ; if c > 0 then we need two writes
	jr	nz, .writeTwo
.writeSingle   
	pop	af 
	ld	(hl),a
	pop	hl  ; next row address
	inc	de  ; next byte of UDG data
	djnz	.screenLoop
.exit
	ret

.writeTwo
	; the UDG is not on a character boundary so we need to:
	;   print across two cells
	;   shift right the udg by the value in a and write the (hl)
	;   shift left by 8-a the udg value and write to (hl+1)
	; c contains the offset
	pop	af   
	push	bc ; b contains the row count  
		ld	b, c
.rotateRightUdg		
		sra	a
		djnz	.rotateRightUdg
		ld	(hl),a
		inc	hl ; next cell for udg

		; now determine how far to shift left
		ld	a, 8
		sub	a, c ; 8 - c = number of left shifts
		ld	b, a
		ld	a, (de) ; reload udg data
.rotateLeftUdg
		sla	a
		djnz	.rotateLeftUdg
		ld	(hl),a

	pop	bc ; restore row count
	pop	hl ; next row address
	inc	de ; next byte of UDG data
	djnz	.screenLoop
	ret

;----------------------------------------
; in
;   hl - write address
;   a  - value to write   

; This is expensive, obviously as the check is performed every write - probably better to ensure that the
; x, y co-ords are never out of bounds and not drawing
WriteScreenByte:
	push	hl ; save it for check
		push	de ; save udg data pointer
		ld	de, MEM_ZX_ATTRIB_5800
		sbc	hl, de
		pop	de ; pops don't mess with the stack
	pop	hl ;
	jr z, .offscreen
	jp p, .offscreen  ; no jump relative on parity :/
	ld	(hl), a
.offscreen
	ret
