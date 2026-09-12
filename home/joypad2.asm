; this function is used when lower button sensitivity is wanted (e.g. menus)
JoypadLowSensitivity::
	call Joypad
	ldh a, [hJoy7]
	and a
	ldh a, [hJoyPressed]
	jr z, .storeButtonState
	ldh a, [hJoyHeld]
.storeButtonState
	ldh [hJoy5], a
	ldh a, [hJoyPressed]
	and a
	jr z, .noNewlyPressedButtons
	ld a, 30
	ldh [hFrameCounter], a
	ret
.noNewlyPressedButtons
	ldh a, [hFrameCounter]
	and a
	jr z, .delayOver
	xor a
	ldh [hJoy5], a
	ret
.delayOver
	ldh a, [hJoyHeld]
	and PAD_A | PAD_B
	jr z, .setShortDelay
	ldh a, [hJoy6]
	and a
	jr nz, .setShortDelay
	xor a
	ldh [hJoy5], a
.setShortDelay
	ld a, 5
	ldh [hFrameCounter], a
	ret

WaitForTextScrollButtonPress::
	ldh a, [hDownArrowBlinkCount1]
	push af
	ldh a, [hDownArrowBlinkCount2]
	push af
	xor a
	ldh [hDownArrowBlinkCount1], a
	ld a, $6
	ldh [hDownArrowBlinkCount2], a
.loop
	push hl
	ld a, [wTownMapSpriteBlinkingEnabled]
	and a
	jr z, .skipAnimation
	push de
	push bc
	callfar TownMapSpriteBlinkingAnimation
	pop bc
	pop de
.skipAnimation
	hlcoord 18, 16
	call HandleDownArrowBlinkTiming
	pop hl
	call JoypadLowSensitivity
	predef CableClub_Run
	ldh a, [hJoy5]
	and PAD_A | PAD_B
	jr z, .loop
	pop af
	ldh [hDownArrowBlinkCount2], a
	pop af
	ldh [hDownArrowBlinkCount1], a
	ret

ManualTextScroll::
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jr z, .inLinkBattle
	call WaitForTextScrollButtonPress
	call WaitForSoundToFinish
	ld a, SFX_PRESS_AB
	jp PlaySound
.inLinkBattle
	ld c, 65
	jp DelayFrames
