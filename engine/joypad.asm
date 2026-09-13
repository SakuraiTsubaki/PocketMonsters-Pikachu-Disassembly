; Bank 03 manually structured joypad family reconstruction.
; Common instructions are emitted once. Japanese Rev 0 keeps its historical
; polling/soft-reset path; Japanese Rev 1-3 and international targets share
; the normal path wherever their source is assembly-equivalent.
; JP: Narishma-gb/pokeyellow-jp @ f282e72ae26232790fdb780aa5a5db7ec8ebf572
; INT: pret/pokeyellow @ e89ead154b9968aa50eed9328ff2b38b6c194382

ReadJoypad_::
; Poll joypad input.
; Unlike the hardware register, button
; presses are indicated by a set bit.
IF DEF(_JAPAN)
IF DEF(_REV1) || DEF(_REV2) || DEF(_REV3)
	ldh a, [hDisableJoypadPolling]
	and a
	ret nz
ENDC
ELSE
	ldh a, [hDisableJoypadPolling]
	and a
	ret nz
ENDC

	ld a, 1 << 5 ; select direction keys
IF DEF(_JAPAN) && DEF(_REV0)
	ld c, 0
ENDC

	ldh [rJOYP], a
	ldh a, [rJOYP]
	ldh a, [rJOYP]
IF DEF(_JAPAN) && DEF(_REV0)
	REPT 4
		ldh a, [rJOYP]
	ENDR
ENDC
	cpl
	and %1111
	swap a
	ld b, a

	ld a, 1 << 4 ; select button keys
	ldh [rJOYP], a
REPT 6
	ldh a, [rJOYP]
ENDR
IF DEF(_JAPAN) && DEF(_REV0)
	REPT 4
		ldh a, [rJOYP]
	ENDR
	cpl
	and %01001111

	cp PAD_BUTTONS ; soft reset
	jr nz, .notSoftReset
	jp TrySoftReset
.notSoftReset
	or b
	ld b, a
ELSE
	cpl
	and %1111
	or b

	ldh [hJoyInput], a

	ld a, 1 << 4 + 1 << 5 ; deselect keys
	ldh [rJOYP], a
	ret

_Joypad::
; hJoyReleased: (hJoyLast ^ hJoyInput) & hJoyLast
; hJoyPressed:  (hJoyLast ^ hJoyInput) & hJoyInput

	ldh a, [hJoyInput]
	ld b, a
	and PAD_BUTTONS | PAD_UP
	cp PAD_BUTTONS ; soft reset
	jp z, TrySoftReset
ENDC

	ldh a, [hJoyLast]
	ld e, a
	xor b
	ld d, a
	and e
	ldh [hJoyReleased], a
	ld a, d
	and b
	ldh [hJoyPressed], a
IF DEF(_JAPAN) && DEF(_REV0)
	ld a, 1 << 4 + 1 << 5 ; deselect keys
	ldh [rJOYP], a
ENDC
	ld a, b
	ldh [hJoyLast], a

	ld a, [wStatusFlags5]
	bit BIT_DISABLE_JOYPAD, a
	jr nz, DiscardButtonPresses

	ldh a, [hJoyLast]
	ldh [hJoyHeld], a

	ld a, [wJoyIgnore]
	and a
	ret z

	cpl
	ld b, a
	ldh a, [hJoyHeld]
	and b
	ldh [hJoyHeld], a
	ldh a, [hJoyPressed]
	and b
	ldh [hJoyPressed], a
	ret

DiscardButtonPresses:
	xor a
	ldh [hJoyHeld], a
	ldh [hJoyPressed], a
	ldh [hJoyReleased], a
	ret

TrySoftReset:
	call DelayFrame

IF DEF(_JAPAN)
	ld a, 1 << 4 + 1 << 5 ; deselect keys
ELSE
	; deselect (redundant)
	ld a, $30
ENDC
	ldh [rJOYP], a

	ld hl, hSoftReset
	dec [hl]
	jp z, SoftReset

	jp Joypad
