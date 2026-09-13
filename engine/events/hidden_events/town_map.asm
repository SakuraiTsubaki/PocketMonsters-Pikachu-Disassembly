; Bank 03 fine-grained family reconstruction.
; Common source lines are emitted once; only source-family differences are conditional.
; JP: Narishma-gb/pokeyellow-jp @ f282e72ae26232790fdb780aa5a5db7ec8ebf572
; INT: pret/pokeyellow @ e89ead154b9968aa50eed9328ff2b38b6c194382

TownMapText::
IF DEF(_JAPAN)
	text "タウンマップだ！@"
ELSE
	text_far _TownMapText
ENDC
	text_promptbutton
	text_asm
	ld a, $1
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ld hl, wStatusFlags5
	set BIT_NO_TEXT_DELAY, [hl]
	call GBPalWhiteOutWithDelay3
	xor a
	ldh [hWY], a
	inc a
	ldh [hAutoBGTransferEnabled], a
	call LoadFontTilePatterns
	farcall DisplayTownMap
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	ld de, TextScriptEnd
	push de
	ldh a, [hLoadedROMBank]
	push af
	jp CloseTextDisplay
