LearnMove:
	call SaveScreenTilesToBuffer1
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName
	ld hl, wNameBuffer
	ld de, wLearnMoveMonName
	ld bc, NAME_LENGTH
	call CopyData

DontAbandonLearning:
	ld hl, wPartyMon1Moves
	ld bc, PARTYMON_STRUCT_LENGTH
	ld a, [wWhichPokemon]
	call AddNTimes
	ld d, h
	ld e, l
	ld b, NUM_MOVES
.findEmptyMoveSlotLoop
	ld a, [hl]
	and a
	jr z, .next
	inc hl
	dec b
	jr nz, .findEmptyMoveSlotLoop
	push de
	call TryingToLearn
	pop de
	jp c, AbandonLearning
	push hl
	push de
	ld [wNamedObjectIndex], a
	call GetMoveName
	ld hl, OneTwoAndText
	call PrintText
	pop de
	pop hl
.next
	ld a, [wMoveNum]
	ld [hl], a
	ld bc, MON_PP - MON_MOVES
	add hl, bc
	push hl
	push de
	dec a
	ld hl, Moves
	ld bc, MOVE_LENGTH
	call AddNTimes
	ld de, wBuffer
	ld a, BANK(Moves)
	call FarCopyData
	ld a, [wBuffer + MOVE_PP]
	pop de
	pop hl
	ld [hl], a
	ld a, [wIsInBattle]
	and a
	jp z, PrintLearnedMove
	ld a, [wWhichPokemon]
	ld b, a
	ld a, [wPlayerMonNumber]
	cp b
	jp nz, PrintLearnedMove
	ld h, d
	ld l, e
	ld de, wBattleMonMoves
	ld bc, NUM_MOVES
	call CopyData
	ld bc, MON_PP - MON_OTID
	add hl, bc
	ld de, wBattleMonPP
	ld bc, NUM_MOVES
	call CopyData
	jp PrintLearnedMove

AbandonLearning:
	ld hl, AbandonLearningText
	call PrintText
	hlcoord 14, 7
	lb bc, 8, 15
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID
	ld a, [wCurrentMenuItem]
	and a
	jp nz, DontAbandonLearning
	ld hl, DidNotLearnText
	call PrintText
	ld b, 0
	ret

PrintLearnedMove:
	ld hl, LearnedMove1Text
	call PrintText
	ld b, 1
	ret

TryingToLearn:
	push hl
	ld hl, TryingToLearnText
	call PrintText
	hlcoord 14, 7
	lb bc, 8, 15
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID
	pop hl
	ld a, [wCurrentMenuItem]
	rra
	ret c
	ld bc, -NUM_MOVES
	add hl, bc
	push hl
	ld de, wMoves
	ld bc, NUM_MOVES
	call CopyData
	callfar FormatMovesString
	pop hl
.loop
	push hl
	ld hl, WhichMoveToForgetText
	call PrintText
IF DEF(_JAPAN)
	hlcoord 10, 8
	lb bc, 8, 8
	call TextBoxBorder
	hlcoord 12, 10
	ld de, wMovesString
	call PlaceString
	ld hl, wTopMenuItemY
	ld a, 10
	ld [hli], a
	ld a, 11
	ld [hli], a
ELSE
	hlcoord 4, 7
	lb bc, 4, 14
	call TextBoxBorder
	hlcoord 6, 8
	ld de, wMovesString
	ldh a, [hUILayoutFlags]
	set BIT_SINGLE_SPACED_LINES, a
	ldh [hUILayoutFlags], a
	call PlaceString
	ldh a, [hUILayoutFlags]
	res BIT_SINGLE_SPACED_LINES, a
	ldh [hUILayoutFlags], a
	ld hl, wTopMenuItemY
	ld a, 8
	ld [hli], a
	ld a, 5
	ld [hli], a
ENDC
	xor a
	ld [hli], a
	inc hl
	ld a, [wNumMovesMinusOne]
	ld [hli], a
	ld a, PAD_A | PAD_B
	ld [hli], a
	ld [hl], 0
IF DEF(_JAPAN)
	call HandleMenuInput
ELSE
	ld hl, hUILayoutFlags
	set BIT_DOUBLE_SPACED_MENU, [hl]
	call HandleMenuInput
	ld hl, hUILayoutFlags
	res BIT_DOUBLE_SPACED_MENU, [hl]
ENDC
	push af
	call LoadScreenTilesFromBuffer1
	pop af
	pop hl
	bit B_PAD_B, a
	jr nz, .cancel
	push hl
	ld a, [wCurrentMenuItem]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	push af
	push bc
	call IsMoveHM
	pop bc
	pop de
	ld a, d
	jr c, .hm
	pop hl
	add hl, bc
	and a
	ret
.hm
	ld hl, HMCantDeleteText
	call PrintText
	pop hl
	jr .loop
.cancel
	scf
	ret

IF DEF(_JAPAN)
LearnedMove1Text:
	text_ram wLearnMoveMonName
	text "は　あたらしく"
	line "@"
	text_ram wStringBuffer
	text "を　おぼえた！@"
	sound_get_item_1
	text_promptbutton
	text_end

WhichMoveToForgetText:
	text "どの　わざを"
	next "わすれさせたい？"
	done

AbandonLearningText:
	text "それでは<⋯>　@"
	text_ram wStringBuffer
	text "を"
	line "おぼえるのを　あきらめますか？"
	done

DidNotLearnText:
	text_ram wLearnMoveMonName
	text "は　@"
	text_ram wStringBuffer
	text "を"
	line "おぼえずに　おわった！"
	prompt

TryingToLearnText:
	text_ram wLearnMoveMonName
	text "は　あたらしく"
	line "@"
	text_ram wStringBuffer
	text "を　おぼえたい<⋯>！"
	para "しかし　@"
	text_ram wLearnMoveMonName
	text "は　わざを　４つ"
	line "おぼえるので　せいいっぱいだ！"
	para "@"
	text_ram wStringBuffer
	text "の　かわりに"
	line "ほかの　わざを　わすれさせますか？"
	done

OneTwoAndText:
	text "１　２の　<⋯>@"
	text_pause
	text_asm
	push af
	push bc
	push de
	push hl
	ld a, $1
	ld [wMuteAudioAndPauseMusic], a
	call DelayFrame
	ld a, [wAudioROMBank]
	push af
	ld a, BANK(SFX_Swap_1)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	call WaitForSoundToFinish
	ld a, SFX_SWAP
	call PlaySound
	call WaitForSoundToFinish
	pop af
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	xor a
	ld [wMuteAudioAndPauseMusic], a
	pop hl
	pop de
	pop bc
	pop af
	ld hl, PoofForgotAndText
	ret

PoofForgotAndText:
	text "　ポカン！@"
	text_pause
	text_start
	para "@"
	text_ram wLearnMoveMonName
	text "は　@"
	text_ram wNameBuffer
	text "の"
	line "つかいかたを　きれいに　わすれた！"
	para "そして<⋯>！"
	prompt

HMCantDeleteText:
	text "それは　たいせつなわざです"
	line "わすれさせることは　できません！"
	prompt
ELSE
LearnedMove1Text:
	text_far _LearnedMove1Text
	sound_get_item_1
	text_promptbutton
	text_end

WhichMoveToForgetText:
	text_far _WhichMoveToForgetText
	text_end

AbandonLearningText:
	text_far _AbandonLearningText
	text_end

DidNotLearnText:
	text_far _DidNotLearnText
	text_end

TryingToLearnText:
	text_far _TryingToLearnText
	text_end

OneTwoAndText:
	text_far _OneTwoAndText
	text_pause
	text_asm
	push af
	push bc
	push de
	push hl
	ld a, $1
	ld [wMuteAudioAndPauseMusic], a
	call DelayFrame
	ld a, [wAudioROMBank]
	push af
	ld a, BANK(SFX_Swap_1)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	call WaitForSoundToFinish
	ld a, SFX_SWAP
	call PlaySound
	call WaitForSoundToFinish
	pop af
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	xor a
	ld [wMuteAudioAndPauseMusic], a
	pop hl
	pop de
	pop bc
	pop af
	ld hl, PoofText
	ret

PoofText:
	text_far _PoofText
	text_pause
ForgotAndText:
	text_far _ForgotAndText
	text_end

HMCantDeleteText:
	text_far _HMCantDeleteText
	text_end
ENDC
