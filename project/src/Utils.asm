;--------------------------------------------------------
; General purpose routines
;--------------------------------------------------------

;---------------------------
; Delay
; in:
;   BC - outer loop
;   DE - inner loop
Delay:
        push    de;   
.delayOuter:
        pop     de;
        push    de;
.delayInner:
        dec     de
        ld      a, d
        or      e           ;Bitwise OR of E with A (now, A = D | E)
        jr      nz, .delayInner
        dec     bc
        ld      a, b
        or      c           ;Bitwise OR of C with A (now, A = B | C)
        jr      nz, .delayOuter
        pop     de;
        ret
