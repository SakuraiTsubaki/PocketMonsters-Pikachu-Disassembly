DrawHP:
; Draws the HP bar in the stats screen
	call GetPredefRegisters
	ld a, $1
	jr DrawHP_

DrawHP2:
; Draws the HP bar in the party screen
	call GetPredefRegisters
	ld a, $2

DrawHP_:
	ld [wHPBarType], a
	push hl
	ld a, [wLoadedMonHP]
	ld b, a
	ld a, [wLoadedMonHP + 1]
	ld c, a
	or b
	jr nz, .nonzeroHP
	xor a
	ld c, a
	ld e, a
	ld a, $6
	ld d, a
	jp .drawHPBarAndPrintFraction
.nonzeroHP
	ld a, [wLoadedMonMaxHP]
	ld d, a
	ld a, [wLoadedMonMaxHP + 1]
	ld e, a
	predef HPBarLength
	ld a, $6
	ld d, a
	ld c, a
.drawHPBarAndPrintFraction
	pop hl
	push de
	push hl
	push hl
	call DrawHPBar
	pop hl
IF DEF(_JAPAN)
ELSE
	ldh a, [hUILayoutFlags]
	bit BIT_PARTY_MENU_HP_BAR, a
	jr z, .printFractionBelowBar
	ld bc, $9 ; right of bar
	jr .printFraction
.printFractionBelowBar
ENDC
	ld bc, SCREEN_WIDTH + 1 ; below bar
IF DEF(_JAPAN)
ELSE
.printFraction
ENDC
	add hl, bc
	ld de, wLoadedMonHP
	lb bc, 2, 3
	call PrintNumber
IF DEF(_JAPAN)
	ld a, '／'
ELSE
	ld a, '/'
ENDC
	ld [hli], a
	ld de, wLoadedMonMaxHP
	lb bc, 2, 3
	call PrintNumber
	pop hl
	pop de
	ret

StatusScreen:
	call LoadMonData
	ld a, [wMonDataLocation]
	cp BOX_DATA
	jr c, .DontRecalculate
; mon is in a box or daycare
	ld a, [wLoadedMonBoxLevel]
	ld [wLoadedMonLevel], a
	ld [wCurEnemyLevel], a
	ld hl, wLoadedMonHPExp - 1
	ld de, wLoadedMonStats
	ld b, $1
	call CalcStats
.DontRecalculate
	ld hl, wStatusFlags2
	set BIT_NO_AUDIO_FADE_OUT, [hl]
	ld a, $33
	ldh [rAUDVOL], a ; Reduce the volume
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call UpdateSprites
	call LoadHpBarAndStatusTilePatterns
	ld de, BattleHudTiles1  ; source
	ld hl, vChars2 tile $6d ; dest
	lb bc, BANK(BattleHudTiles1), 3
	call CopyVideoDataDouble ; ·│ :L and halfarrow line end
	ld de, BattleHudTiles2
	ld hl, vChars2 tile $78
	lb bc, BANK(BattleHudTiles2), 1
	call CopyVideoDataDouble ; │
	ld de, BattleHudTiles3
	ld hl, vChars2 tile $76
	lb bc, BANK(BattleHudTiles3), 2
	call CopyVideoDataDouble ; ─ ┘
	ld de, PTile
	ld hl, vChars2 tile $72
	lb bc, BANK(PTile), 1
	call CopyVideoDataDouble ; bold P (for PP)
	ldh a, [hTileAnimations]
	push af
	xor a
	ldh [hTileAnimations], a
	hlcoord 19, 1
	lb bc, 6, 10
	call DrawLineBox ; Draws the box around name, HP and status
	ld de, -6
	add hl, de
IF DEF(_JAPAN)
	ld [hl], '．'
ELSE
	ld [hl], '<DOT>'
ENDC
	dec hl
	ld [hl], '№'
	hlcoord 19, 9
	lb bc, 8, 6
	call DrawLineBox ; Draws the box around types, ID No. and OT
IF DEF(_JAPAN)
	hlcoord 10, 10
ELSE
	hlcoord 10, 9
ENDC
	ld de, TypesIDNoOTText
	call PlaceString
	hlcoord 11, 3
	predef DrawHP
	ld hl, wStatusScreenHPBarColor
	call GetHealthBarColor
	ld b, SET_PAL_STATUS_SCREEN
	call RunPaletteCommand
	hlcoord 16, 6
	ld de, wLoadedMonStatus
	call PrintStatusCondition
	jr nz, .StatusWritten
	hlcoord 16, 6
	ld de, OKText
IF DEF(_JAPAN)
	call PlaceString
ELSE
	call PlaceString ; "OK"
ENDC
.StatusWritten
IF DEF(_JAPAN)
	hlcoord 10, 6
ELSE
	hlcoord 9, 6
ENDC
	ld de, StatusText
IF DEF(_JAPAN)
	call PlaceString
	hlcoord 16, 1
ELSE
	call PlaceString ; "STATUS/"
	hlcoord 14, 2
ENDC
	call PrintLevel
	ld a, [wMonHIndex]
	ld [wPokedexNum], a
	ld [wCurSpecies], a
	predef IndexToPokedex
	hlcoord 3, 7
	ld de, wPokedexNum
	lb bc, LEADING_ZEROES | 1, 3
	call PrintNumber ; Pokémon no.
IF DEF(_JAPAN)
	hlcoord 15, 10
ELSE
	hlcoord 11, 10
ENDC
	predef PrintMonType
	ld hl, NamePointers2
	call .GetStringPointer
	ld d, h
	ld e, l
IF DEF(_JAPAN)
	hlcoord 11, 1
ELSE
	hlcoord 9, 1
ENDC
	call PlaceString ; Pokémon name
	ld hl, OTPointers
	call .GetStringPointer
	ld d, h
	ld e, l
IF DEF(_JAPAN)
	hlcoord 14, 16
ELSE
	hlcoord 12, 16
ENDC
	call PlaceString ; OT
IF DEF(_JAPAN)
	hlcoord 14, 14
ELSE
	hlcoord 12, 14
ENDC
	ld de, wLoadedMonOTID
	lb bc, LEADING_ZEROES | 2, 5
	call PrintNumber ; ID Number
	ld d, STATUS_SCREEN_STATS_BOX
	call PrintStatsBox
	call Delay3
	call GBPalNormal
	hlcoord 1, 0
	call LoadFlippedFrontSpriteByMonIndex ; draw Pokémon picture
	ld a, [wMonDataLocation]
	cp ENEMY_PARTY_DATA
	jr z, .playRegularCry
	cp BOX_DATA
	jr z, .checkBoxData
	callfar IsThisPartyMonStarterPikachu
	jr nc, .playRegularCry
	jr .playPikachuSoundClip
.checkBoxData
	callfar IsThisBoxMonStarterPikachu
	jr nc, .playRegularCry
.playPikachuSoundClip
	ldpikacry e, PikachuCry17
	callfar PlayPikachuSoundClip
	jr .continue
.playRegularCry
	ld a, [wCurPartySpecies]
	call PlayCry
.continue
	call WaitForTextScrollButtonPress
	pop af
	ldh [hTileAnimations], a
	ret

.GetStringPointer
	ld a, [wMonDataLocation]
	add a
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wMonDataLocation]
	cp DAYCARE_DATA
	ret z
	ld a, [wWhichPokemon]
	jp SkipFixedLengthTextEntries

OTPointers:
	dw wPartyMonOT
	dw wEnemyMonOT
	dw wBoxMonOT
	dw wDayCareMonOT

NamePointers2:
	dw wPartyMonNicks
	dw wEnemyMonNicks
	dw wBoxMonNicks
	dw wDayCareMonName

TypesIDNoOTText:
IF DEF(_JAPAN)
	db   "タイプ１／"
	next "タイプ２／"
	next "<ID>№／"
	next "おや／"
ELSE
	db   "TYPE1/"
	next "TYPE2/"
	next "<ID>№/"
	next "OT/"
ENDC
	next "@"

StatusText:
IF DEF(_JAPAN)
	db "じょうたい／@"
ELSE
	db "STATUS/@"
ENDC

OKText:
IF DEF(_JAPAN)
	db "ふつう@"
ELSE
	db "OK@"
ENDC

; Draws a line starting from hl high b and wide c
DrawLineBox:
	ld de, SCREEN_WIDTH ; New line
.PrintVerticalLine
	ld [hl], $78 ; │
	add hl, de
	dec b
	jr nz, .PrintVerticalLine
	ld [hl], $77 ; ┘
	dec hl
.PrintHorizLine
	ld [hl], $76 ; ─
	dec hl
	dec c
	jr nz, .PrintHorizLine
	ld [hl], $6f ; ← (halfarrow ending)
	ret

PTile: INCBIN "gfx/font/P.1bpp"

PrintStatsBox:
	ld a, d
	ASSERT STATUS_SCREEN_STATS_BOX == 0
	and a
	jr nz, .LevelUpStatsBox ; battle or Rare Candy
	hlcoord 0, 8
	lb bc, 8, 8
	call TextBoxBorder
IF DEF(_JAPAN)
	hlcoord 1, 10
	ld bc, 5 ; 5 columns right
ELSE
	hlcoord 1, 9
	ld bc, SCREEN_WIDTH + 5 ; one row down and 5 columns right
ENDC
	jr .PrintStats
.LevelUpStatsBox
	hlcoord 9, 2
	lb bc, 8, 9
	call TextBoxBorder
IF DEF(_JAPAN)
	hlcoord 11, 4
	ld bc, 4 ; 4 columns right
ELSE
	hlcoord 11, 3
	ld bc, SCREEN_WIDTH + 4 ; one row down and 4 columns right
ENDC
.PrintStats
	push bc
	push hl
	ld de, .StatsText
	call PlaceString
	pop hl
	pop bc
	add hl, bc
	ld de, wLoadedMonAttack
	lb bc, 2, 3
	call .PrintStat
	ld de, wLoadedMonDefense
	call .PrintStat
	ld de, wLoadedMonSpeed
	call .PrintStat
	ld de, wLoadedMonSpecial
	jp PrintNumber

.PrintStat:
	push hl
	call PrintNumber
	pop hl
	ld de, SCREEN_WIDTH * 2
	add hl, de
	ret

.StatsText:
IF DEF(_JAPAN)
	db   "こうげき"
	next "ぼうぎょ"
	next "すばやさ"
	next "とくしゅ@"
ELSE
	db   "ATTACK"
	next "DEFENSE"
	next "SPEED"
	next "SPECIAL@"
ENDC

StatusScreen2:
	ldh a, [hTileAnimations]
	push af
	xor a
	ldh [hTileAnimations], a
	ldh [hAutoBGTransferEnabled], a
	ld bc, NUM_MOVES + 1
	ld hl, wMoves
	call FillMemory
	ld hl, wLoadedMonMoves
	ld de, wMoves
	ld bc, NUM_MOVES
	call CopyData
	callfar FormatMovesString
	hlcoord 9, 2
	lb bc, 5, 10
	call ClearScreenArea ; Clear under name
	hlcoord 19, 3
IF DEF(_JAPAN)
	ld [hl], $78 ; │ (Erases right end of HP bar)
ELSE
	ld [hl], $78
ENDC
	hlcoord 0, 8
	lb bc, 8, 18
	call TextBoxBorder ; Draw move container
IF DEF(_JAPAN)
	hlcoord 2, 10
ELSE
	hlcoord 2, 9
ENDC
	ld de, wMovesString
	call PlaceString ; Print moves
	ld a, [wNumMovesMinusOne]
	inc a
	ld c, a ; number of known moves
	ld a, NUM_MOVES
	sub c
	ld b, a ; number of blank moves
	hlcoord 11, 10
	ld de, SCREEN_WIDTH * 2
IF DEF(_JAPAN)
	ld a, 'Ｐ'
	call StatusScreen_PrintPP ; Print "ＰＰ"
ELSE
	ld a, '<BOLD_P>'
	call StatusScreen_PrintPP ; Print "PP"
ENDC
	ld a, b
	and a
	jr z, .InitPP
	ld c, a
IF DEF(_JAPAN)
	ld a, 'ー'
	call StatusScreen_PrintPP ; Fill the rest with ーー
ELSE
	ld a, '-'
	call StatusScreen_PrintPP ; Fill the rest with --
ENDC
.InitPP
	ld hl, wLoadedMonMoves
	decoord 14, 10
	ld b, 0
.PrintPP
	ld a, [hli]
	and a
	jr z, .PPDone
	push bc
	push hl
	push de
	ld hl, wCurrentMenuItem
	ld a, [hl]
	push af
	ld a, b
	ld [hl], a
	push hl
	callfar GetMaxPP
	pop hl
	pop af
	ld [hl], a
	pop de
	pop hl
	push hl
	ld bc, MON_PP - MON_MOVES - 1
	add hl, bc
	ld a, [hl]
	and PP_MASK
	ld [wStatusScreenCurrentPP], a
	ld h, d
	ld l, e
	push hl
	ld de, wStatusScreenCurrentPP
	lb bc, 1, 2
	call PrintNumber
IF DEF(_JAPAN)
	ld a, '／'
ELSE
	ld a, '/'
ENDC
	ld [hli], a
	ld de, wMaxPP
	lb bc, 1, 2
	call PrintNumber
	pop hl
	ld de, SCREEN_WIDTH * 2
	add hl, de
	ld d, h
	ld e, l
	pop hl
	pop bc
	inc b
	ld a, b
	cp NUM_MOVES
	jr nz, .PrintPP
.PPDone
	hlcoord 9, 3
	ld de, StatusScreenExpText
	call PlaceString
	ld a, [wLoadedMonLevel]
	push af
	cp MAX_LEVEL
	jr z, .Level100
	inc a
	ld [wLoadedMonLevel], a ; Increase temporarily if not 100
.Level100
IF DEF(_JAPAN)
	hlcoord 14, 5
	ld [hl], '゛'
ELSE
ENDC
	hlcoord 14, 6
IF DEF(_JAPAN)
	ld [hl], 'て'
ELSE
	ld [hl], '<to>'
ENDC
	inc hl
	inc hl
	call PrintLevel
	pop af
	ld [wLoadedMonLevel], a
	ld de, wLoadedMonExp
	hlcoord 12, 4
	lb bc, 3, 7
	call PrintNumber ; exp
	call CalcExpToLevelUp
	ld de, wLoadedMonExp
	hlcoord 7, 6
	lb bc, 3, 7
	call PrintNumber ; exp needed to level up
IF DEF(_JAPAN)
	hlcoord 11, 0
ELSE

	; unneeded, this clears the diacritic characters in JPN versions
	hlcoord 9, 0
ENDC
	call StatusScreen_ClearName
IF DEF(_JAPAN)
	hlcoord 11, 1
ELSE

	hlcoord 9, 1
ENDC
	call StatusScreen_ClearName
	ld a, [wMonHIndex]
	ld [wNamedObjectIndex], a
	call GetMonName
IF DEF(_JAPAN)
	hlcoord 11, 1
ELSE
	hlcoord 9, 1
ENDC
	call PlaceString
	ld a, $1
	ldh [hAutoBGTransferEnabled], a
	call Delay3
	call WaitForTextScrollButtonPress
	pop af
	ldh [hTileAnimations], a
	ld hl, wStatusFlags2
	res BIT_NO_AUDIO_FADE_OUT, [hl]
	ld a, $77
	ldh [rAUDVOL], a
	call GBPalWhiteOut
	jp ClearScreen

CalcExpToLevelUp:
	ld a, [wLoadedMonLevel]
	cp MAX_LEVEL
	jr z, .atMaxLevel
	inc a
	ld d, a
	callfar CalcExperience
	ld hl, wLoadedMonExp + 2
	ldh a, [hExperience + 2]
	sub [hl]
	ld [hld], a
	ldh a, [hExperience + 1]
	sbc [hl]
	ld [hld], a
	ldh a, [hExperience]
	sbc [hl]
	ld [hld], a
	ret
.atMaxLevel
	ld hl, wLoadedMonExp
	xor a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ret

StatusScreenExpText:
IF DEF(_JAPAN)
	db   "けいけんち／"
	next "あと@"
ELSE
	db   "EXP POINTS"
	next "LEVEL UP@"
ENDC

StatusScreen_ClearName:
	ld bc, NAME_LENGTH - 1
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	jp FillMemory

StatusScreen_PrintPP:
IF DEF(_JAPAN)
; print ＰＰ or ーー c times, going down two rows each time
ELSE
; print PP or -- c times, going down two rows each time
ENDC
	ld [hli], a
	ld [hld], a
	add hl, de
	dec c
	jr nz, StatusScreen_PrintPP
	ret
