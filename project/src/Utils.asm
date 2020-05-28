;--------------------------------------------------------
; General purpose routines
;--------------------------------------------------------

;---------------------------
; Delay
; in:
;   BC - outer loop
;   DE - inner loop
Delay:
		push	de;   
.delayOuter:
		pop	 de;
		push	de;
.delayInner:
		dec	 de
		ld	  a, d
		or	  e		   ;Bitwise OR of E with A (now, A = D | E)
		jr	  nz, .delayInner
		dec	 bc
		ld	  a, b
		or	  c		   ;Bitwise OR of C with A (now, A = B | C)
		jr	  nz, .delayOuter
		pop	 de;
		ret

ReadInputDevices:
		; read Kempston port first, will also clear the inputs
		in	  a,(KEMPSTON_JOY1_P_1F)
		ld	  e,a		 ; E = the Kempston/MD joystick inputs (---FUDLR)
		; mix the joystick inputs with OPQA<space>
		ld	  d,$FF	   ; keyboard reading bits are 1=released, 0=pressed -> $FF = no key
		ld	  a,~(1<<7)   ; eight row of matrix (<space><symbol shift>MNB)
		in	  a,(ULA_P_FE)
		rrca				; Fcarry = <space>
		rl	  d
		ld	  a,~(1<<2)   ; third row of matrix (QWERT)
		in	  a,(ULA_P_FE)
		rrca				; Fcarry = Q
		rl	  d
		ld	  a,~(1<<1)   ; second row of matrix (ASDFG)
		in	  a,(ULA_P_FE)
		rrca				; Fcarry = A
		rl	  d
		ld	  a,~(1<<5)   ; sixth row of matrix (POIUY)
		in	  a,(ULA_P_FE)
		rra
		rra				 ; Fcarry = O ("P" is now in bit 7)
		rl	  d
		rla				 ; Fcarry = P
		ld	  a,d
		rla				 ; A is complete <fire><up><down><left><right>, but inverted
		cpl				 ; invert the readings, now 1 = pressed, 0 = no key
		or	  e		   ; mix the keyboard readings together with joystick
		ld	  (Player1Controls),a	 ; store the inputs for AI routine
		ret

WaitForScanlineUnderUla:
		; because I decided early to not use interrupts to keep the code a bit simpler
		; (simpler to follow in mind, not having to expect any interrupt everywhere)
		; we will be syncing the main game loop by waiting for particular scanline
		; (just under the ULA paper area, i.e. scanline 192)
	; update the TotalFrames counter by +1
		ld	  hl,(TotalFrames)
		inc	 hl
		ld	  (TotalFrames),hl
		IFDEF DEBUG_BORDERS
			; turn the border to the "main" color during wait
			ld	  a,MAIN_BORDER_COLOR
			out	 (ULA_P_FE),a
		ENDIF
		; if HL=0, increment upper 16bit too
		ld	  a,h
		or	  l
		jr	  nz,.totalFramesUpdated
		ld	  hl,(TotalFrames+2)
		inc	 hl
		ld	  (TotalFrames+2),hl
.totalFramesUpdated:
	; read NextReg $1F - LSB of current raster line
		ld	  bc,TBBLUE_REGISTER_SELECT_P_243B
		ld	  a,RASTER_LINE_LSB_NR_1F
		out	 (c),a	   ; select NextReg $1F
		inc	 b		   ; BC = TBBLUE_REGISTER_ACCESS_P_253B
	; if already at scanline 192, then wait extra whole frame (for super-fast game loops)
.cantStartAt192:
		in	  a,(c)	   ; read the raster line LSB
		cp	  192
		jr	  z,.cantStartAt192
	; if not yet at scanline 192, wait for it ... wait for it ...
.waitLoop:
		in	  a,(c)	   ; read the raster line LSB
		cp	  192
		jr	  nz,.waitLoop
	; and because the max scanline number is between 260..319 (depends on video mode),
	; I don't need to read MSB. 256+192 = 448 -> such scanline is not part of any mode.
		ret