PrintLetterDelay::
	ld a, [wStatusFlags5]
	bit BIT_NO_TEXT_DELAY, a
	ret nz
	ld a, [wLetterPrintingDelayFlags]
	bit BIT_TEXT_DELAY, a
	ret z
	push hl
	push de
	push bc
	ld a, [wLetterPrintingDelayFlags]
	bit BIT_FAST_TEXT_DELAY, a
	jr z, .waitOneFrame
	ld a, [wOptions]
	and $f
	ldh [hFrameCounter], a
	jr .checkButtons
.waitOneFrame
	ld a, 1
	ldh [hFrameCounter], a
.checkButtons
	call Joypad
	ldh a, [hJoyHeld]
	bit B_PAD_A, a
	jr z, .checkBButton
	jr .endWait
.checkBButton
	bit B_PAD_B, a
	jr z, .buttonsNotPressed
.endWait
	call DelayFrame
	jr .done
.buttonsNotPressed
	ldh a, [hFrameCounter]
	and a
	jr nz, .checkButtons
.done
	pop bc
	pop de
	pop hl
	ret
