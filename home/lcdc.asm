; LCD STAT interrupt handler. Machine-code identical in all nine verified releases.
LCDC::
	push af
	ldh a, [hLCDCPointer]
	and a
	jr z, .done
	push hl
	ldh a, [rLY]
	ld l, a
	ld h, HIGH(wLYOverrides)
	ld h, [hl]
	ldh a, [hLCDCPointer]
	ld l, a
	ld a, h
	ld h, $ff
	ld [hl], a
	pop hl
.done
	pop af
	reti
