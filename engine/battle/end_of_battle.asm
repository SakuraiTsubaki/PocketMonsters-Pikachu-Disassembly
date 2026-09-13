; Bank 04 fine-grained family reconstruction.
; Common source lines are emitted once; only source-family differences are conditional.
; JP: Narishma-gb/pokeyellow-jp @ f282e72ae26232790fdb780aa5a5db7ec8ebf572
; INT: pret/pokeyellow @ e89ead154b9968aa50eed9328ff2b38b6c194382

EndOfBattle:
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jr nz, .notLinkBattle
; link battle
	ld a, [wEnemyMonPartyPos]
	ld hl, wEnemyMon1Status
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	ld a, [wEnemyMonStatus]
	ld [hl], a
	call ClearScreen
	ld b, SET_PAL_OVERWORLD
	call RunPaletteCommand
	callfar DisplayLinkBattleVersusTextBox
	ld a, [wBattleResult]
	cp $1
	ld de, YouWinText
	jr c, .placeWinOrLoseString
	ld de, YouLoseText
	jr z, .placeWinOrLoseString
	ld de, DrawText
.placeWinOrLoseString
	hlcoord 6, 8
	call PlaceString
	ld c, 200
	call DelayFrames
	jr .evolution
.notLinkBattle
	ld a, [wBattleResult]
	and a
	jr nz, .resetVariables
	ld hl, wTotalPayDayMoney
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	jr z, .evolution ; if pay day money is 0, jump
	ld de, wPlayerMoney + 2
	ld c, $3
	predef AddBCDPredef
	ld hl, PickUpPayDayMoneyText
	call PrintText
.evolution
	xor a
	ld [wForceEvolution], a
	predef EvolutionAfterBattle
	ld d, $82
	callfar UpdatePikachuMoodAfterBattle
.resetVariables
	xor a
	ld [wLowHealthAlarm], a ;disable low health alarm
	ld [wChannelSoundIDs + CHAN5], a
	ld [wIsInBattle], a
	ld [wBattleType], a
	ld [wMoveMissed], a
	ld [wCurOpponent], a
	ld [wForcePlayerToChooseMon], a
	ld [wNumRunAttempts], a
	ld [wEscapedFromBattle], a
	ld hl, wPartyAndBillsPCSavedMenuItem
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld [wListScrollOffset], a
	ld hl, wBattleStatusData
	ld b, wBattleStatusDataEnd - wBattleStatusData
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ld hl, wStatusFlags2
	set BIT_WILD_ENCOUNTER_COOLDOWN, [hl]
	call WaitForSoundToFinish
	call GBPalWhiteOut
	ld a, $ff
	ld [wDestinationWarpID], a
	ret

YouWinText:
IF DEF(_JAPAN)
	db "あなたの　かち@"
ELSE
	db "YOU WIN@"
ENDC

YouLoseText:
IF DEF(_JAPAN)
	db "あなたの　まけ@"
ELSE
	db "YOU LOSE@"
ENDC

DrawText:
IF DEF(_JAPAN)
	db "　　ひきわけ@"
ELSE
	db "  DRAW@"
ENDC

PickUpPayDayMoneyText:
IF DEF(_JAPAN)
	text "<PLAYER>は　@"
	text_bcd wTotalPayDayMoney, 3 | LEADING_ZEROES | LEFT_ALIGN
	text "円"
	line "ひろった！"
	prompt
ELSE
	text_far _PickUpPayDayMoneyText
	text_end
ENDC
