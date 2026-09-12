HandleMenuInput::
	xor a
	ld [wPartyMenuAnimMonEnabled], a

HandleMenuInput_::
	ldh a, [hDownArrowBlinkCount1]
	push af
	ldh a, [hDownArrowBlinkCount2]
	push af
	xor a
	ldh [hDownArrowBlinkCount1], a
	ld a, 6
	ldh [hDownArrowBlinkCount2], a
.loop1
	xor a
	ld [wAnimCounter], a
	call PlaceMenuCursor
	call Delay3
.loop2
	push hl
	ld a, [wPartyMenuAnimMonEnabled]
	and a
	jr z, .getJoypadState
	farcall AnimatePartyMon
.getJoypadState
	pop hl
	call JoypadLowSensitivity
	ldh a, [hJoy5]
	and a
	jr nz, .keyPressed
	push hl
	hlcoord 18, 11
	call HandleDownArrowBlinkTiming
	pop hl
	ld a, [wMenuJoypadPollCount]
	dec a
	jr z, .giveUpWaiting
	jr .loop2
.giveUpWaiting
	pop af
	ldh [hDownArrowBlinkCount2], a
	pop af
	ldh [hDownArrowBlinkCount1], a
	xor a
	ld [wMenuWrappingEnabled], a
	ret
.keyPressed
	xor a
	ld [wCheckFor180DegreeTurn], a
	ldh a, [hJoy5]
	ld b, a
	bit B_PAD_A, a
	jr nz, .checkOtherKeys
	bit B_PAD_UP, a
	jr z, .checkIfDownPressed
	ld a, [wCurrentMenuItem]
	and a
	jr z, .alreadyAtTop
	dec a
	ld [wCurrentMenuItem], a
	jr .checkOtherKeys
.alreadyAtTop
	ld a, [wMenuWrappingEnabled]
	and a
	jr z, .noWrappingAround
	ld a, [wMaxMenuItem]
	ld [wCurrentMenuItem], a
	jr .checkOtherKeys
.checkIfDownPressed
	bit B_PAD_DOWN, a
	jr z, .checkOtherKeys
	ld a, [wCurrentMenuItem]
	inc a
	ld c, a
	ld a, [wMaxMenuItem]
	cp c
	jr nc, .notAtBottom
	ld a, [wMenuWrappingEnabled]
	and a
	jr z, .noWrappingAround
	ld c, $00
.notAtBottom
	ld a, c
	ld [wCurrentMenuItem], a
.checkOtherKeys
	ld a, [wMenuWatchedKeys]
	and b
	jp z, .loop1
.checkIfAButtonOrBButtonPressed
	ldh a, [hJoy5]
	and PAD_A | PAD_B
	jr z, .skipPlayingSound
	push hl
	ld hl, wMiscFlags
	bit BIT_NO_MENU_BUTTON_SOUND, [hl]
	pop hl
	jr nz, .skipPlayingSound
	ld a, SFX_PRESS_AB
	call PlaySound
.skipPlayingSound
	pop af
	ldh [hDownArrowBlinkCount2], a
	pop af
	ldh [hDownArrowBlinkCount1], a
	xor a
	ld [wMenuWrappingEnabled], a
	ldh a, [hJoy5]
	ret
.noWrappingAround
	ld a, [wMenuWatchMovingOutOfBounds]
	and a
	jr z, .checkOtherKeys
	jr .checkIfAButtonOrBButtonPressed

PlaceMenuCursor::
	ld a, [wTopMenuItemY]
	and a
	jr z, .adjustForXCoord
	hlcoord 0, 0
	ld bc, SCREEN_WIDTH
.topMenuItemLoop
	add hl, bc
	dec a
	jr nz, .topMenuItemLoop
.adjustForXCoord
	ld a, [wTopMenuItemX]
	ld b, 0
	ld c, a
	add hl, bc
	push hl
	ld a, [wLastMenuItem]
	and a
	jr z, .checkForArrow1
	ld bc, SCREEN_WIDTH * 2
IF !DEF(_JAPAN)
	push af
	ldh a, [hUILayoutFlags]
	bit BIT_DOUBLE_SPACED_MENU, a
	jr z, .doubleSpaced1
	ld bc, SCREEN_WIDTH
.doubleSpaced1
	pop af
ENDC
.oldMenuItemLoop
	add hl, bc
	dec a
	jr nz, .oldMenuItemLoop
.checkForArrow1
	ld a, [hl]
	cp '▶'
	jr nz, .skipClearingArrow
	ld a, [wTileBehindCursor]
	ld [hl], a
.skipClearingArrow
	pop hl
	ld a, [wCurrentMenuItem]
	and a
	jr z, .checkForArrow2
	ld bc, SCREEN_WIDTH * 2
IF !DEF(_JAPAN)
	push af
	ldh a, [hUILayoutFlags]
	bit BIT_DOUBLE_SPACED_MENU, a
	jr z, .doubleSpaced2
	ld bc, SCREEN_WIDTH
.doubleSpaced2
	pop af
ENDC
.currentMenuItemLoop
	add hl, bc
	dec a
	jr nz, .currentMenuItemLoop
.checkForArrow2
	ld a, [hl]
	cp '▶'
	jr z, .skipSavingTile
	ld [wTileBehindCursor], a
.skipSavingTile
	ld a, '▶'
	ld [hl], a
	ld a, l
	ld [wMenuCursorLocation], a
	ld a, h
	ld [wMenuCursorLocation + 1], a
	ld a, [wCurrentMenuItem]
	ld [wLastMenuItem], a
	ret

PlaceUnfilledArrowMenuCursor::
	ld b, a
	ld a, [wMenuCursorLocation]
	ld l, a
	ld a, [wMenuCursorLocation + 1]
	ld h, a
	ld [hl], '▷'
	ld a, b
	ret

EraseMenuCursor::
	ld a, [wMenuCursorLocation]
	ld l, a
	ld a, [wMenuCursorLocation + 1]
	ld h, a
IF DEF(_JAPAN)
	ld [hl], '　'
ELSE
	ld [hl], ' '
ENDC
	ret

HandleDownArrowBlinkTiming::
	ld a, [hl]
	ld b, a
	ld a, '▼'
	cp b
	jr nz, .downArrowOff
.downArrowOn
	ldh a, [hDownArrowBlinkCount1]
	dec a
	ldh [hDownArrowBlinkCount1], a
	ret nz
	ldh a, [hDownArrowBlinkCount2]
	dec a
	ldh [hDownArrowBlinkCount2], a
	ret nz
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	ld [hl], a
	ld a, $ff
	ldh [hDownArrowBlinkCount1], a
	ld a, $06
	ldh [hDownArrowBlinkCount2], a
	ret
.downArrowOff
	ldh a, [hDownArrowBlinkCount1]
	and a
	ret z
	dec a
	ldh [hDownArrowBlinkCount1], a
	ret nz
	dec a
	ldh [hDownArrowBlinkCount1], a
	ldh a, [hDownArrowBlinkCount2]
	dec a
	ldh [hDownArrowBlinkCount2], a
	ret nz
	ld a, $06
	ldh [hDownArrowBlinkCount2], a
	ld a, '▼'
	ld [hl], a
	ret

EnableAutoTextBoxDrawing::
	xor a
	jr AutoTextBoxDrawingCommon

DisableAutoTextBoxDrawing::
	ld a, 1 << BIT_NO_AUTO_TEXT_BOX

AutoTextBoxDrawingCommon::
	ld [wAutoTextBoxDrawingControl], a
	xor a
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ret

PrintText::
; Print text hl at (1, 14).
	push hl
	ld a, MESSAGE_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	call UpdateSprites
	call Delay3
	pop hl
PrintText_NoCreatingTextBox::
	bccoord 1, 14
	jp TextCommandProcessor
