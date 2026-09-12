MainMenu:
	call InitOptions
	xor a
	ld [wOptionsInitialized], a
	inc a
	ld [wSaveFileStatus], a
	call CheckForPlayerNameInSRAM
	jr nc, .mainMenuLoop

	predef TryLoadSaveFile

.mainMenuLoop
	ld c, 20
	call DelayFrames
	xor a
	ld [wLinkState], a
	ld hl, wPartyAndBillsPCSavedMenuItem
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld [wDefaultMap], a
	ld hl, wStatusFlags4
	res BIT_LINK_CONNECTED, [hl]
	call ClearScreen
	call RunDefaultPaletteCommand
	call LoadTextBoxTilePatterns
	call LoadFontTilePatterns
	ld hl, wStatusFlags5
	set BIT_NO_TEXT_DELAY, [hl]
	ld a, [wSaveFileStatus]
	cp 1
	jr z, .noSaveFile
	hlcoord 0, 0
	lb bc, 6, 13
	call TextBoxBorder
	hlcoord 2, 2
	ld de, ContinueText
	call PlaceString
	jr .next2
.noSaveFile
	hlcoord 0, 0
	lb bc, 4, 13
	call TextBoxBorder
	hlcoord 2, 2
	ld de, NewGameText
	call PlaceString
.next2
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	call UpdateSprites
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld [wMenuJoypadPollCount], a
	inc a
	ld [wTopMenuItemX], a
	inc a
	ld [wTopMenuItemY], a
	ld a, PAD_A | PAD_B | PAD_START
	ld [wMenuWatchedKeys], a
	ld a, [wSaveFileStatus]
	ld [wMaxMenuItem], a
	call HandleMenuInput
	bit B_PAD_B, a
	jp nz, DisplayTitleScreen
	ld c, 20
	call DelayFrames
	ld a, [wCurrentMenuItem]
	ld b, a
	ld a, [wSaveFileStatus]
	cp 2
	jp z, .skipInc
	inc b
.skipInc
	ld a, b
	and a
	jr z, .choseContinue
	cp 1
	jp z, StartNewGame
	call DisplayOptionMenu
	ld a, TRUE
	ld [wOptionsInitialized], a
	jp .mainMenuLoop
.choseContinue
	call DisplayContinueGameInfo
	ld hl, wCurrentMapScriptFlags
	set BIT_CUR_MAP_LOADED_1, [hl]
.inputLoop
	xor a
	ldh [hJoyPressed], a
	ldh [hJoyReleased], a
	ldh [hJoyHeld], a
	call Joypad
	ldh a, [hJoyHeld]
	bit B_PAD_A, a
	jr nz, .pressedA
	bit B_PAD_B, a
	jp nz, .mainMenuLoop
	jr .inputLoop
.pressedA
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	ld a, PLAYER_DIR_DOWN
	ld [wPlayerDirection], a
	ld c, 10
	call DelayFrames
	ld a, [wNumHoFTeams]
	and a
	jp z, SpecialEnterMap
	ld a, [wCurMap]
	cp HALL_OF_FAME
	jp nz, SpecialEnterMap
	xor a
	ld [wDestinationMap], a
	ld hl, wStatusFlags6
	set BIT_FLY_OR_DUNGEON_WARP, [hl]
	call PrepareForSpecialWarp
	jp SpecialEnterMap

InitOptions:
	ld a, 1 << BIT_FAST_TEXT_DELAY
	ld [wLetterPrintingDelayFlags], a
	ld a, TEXT_DELAY_MEDIUM
	ld [wOptions], a
	ld a, 64
	ld [wPrinterSettings], a
	ret

Func_5cc1:
	ld a, $6d
	cp $80
	ret c
	ld hl, NotEnoughMemoryText
	call PrintText
	ret

NotEnoughMemoryText:
IF DEF(_JAPAN)
	text "イエローバージョンの"
	line "メモリガ　たりません"
	done
ELSE
	text_far _NotEnoughMemoryText
	text_end
ENDC

StartNewGame:
	ld hl, wStatusFlags6
	res BIT_DEBUG_MODE, [hl]
StartNewGameDebug:
	call OakSpeech
	ld a, PLAYER_DIR_UP
	ld [wPlayerMovingDirection], a
	ld c, 20
	call DelayFrames

SpecialEnterMap::
	xor a
	ldh [hJoyPressed], a
	ldh [hJoyHeld], a
	ldh [hJoy5], a
	ld [wCableClubDestinationMap], a
	ld hl, wStatusFlags6
	set BIT_GAME_TIMER_COUNTING, [hl]
	call ResetPlayerSpriteData
	ld c, 20
	call DelayFrames
	call Func_5cc1
	ld a, [wEnteringCableClub]
	and a
	ret nz
	jp EnterMap

ContinueText:
IF DEF(_JAPAN)
	db "つづきからはじめる"
ELIF DEF(_FRENCH)
	db "CONTINUER"
ELIF DEF(_GERMAN)
	db "WEITER"
ELIF DEF(_ITALIAN)
	db "CONTINUA"
ELIF DEF(_SPANISH)
	db "CONTINUAR"
ELSE
	db "CONTINUE"
ENDC
	next ""

NewGameText:
IF DEF(_JAPAN)
	db   "さいしょからはじめる"
	next "せっていを　かえる@"
ELIF DEF(_FRENCH)
	db   "NOUVEAU JEU"
	next "OPTIONS@"
ELIF DEF(_GERMAN)
	db   "NEUES SPIEL"
	next "OPTIONEN@"
ELIF DEF(_ITALIAN)
	db   "NUOVO GIOCO"
	next "OPZIONI@"
ELIF DEF(_SPANISH)
	db   "JUEGO NUEVO"
	next "OPCIONES@"
ELSE
	db   "NEW GAME"
	next "OPTION@"
ENDC

IF DEF(_JAPAN)
CableClubOptionsText:
	db   "トレードセンター"
	next "コロシアム"
	next "コロシアム２"
	next "やめる@"
ENDC

DisplayContinueGameInfo:
	xor a
	ldh [hAutoBGTransferEnabled], a
IF DEF(_JAPAN)
	hlcoord 4, 7
	lb bc, 8, 13
	hlcoord 4, 7
ELIF DEF(_GERMAN)
	hlcoord 3, 7
	lb bc, 8, 15
ELSE
	hlcoord 4, 7
	lb bc, 8, 14
ENDC
	call TextBoxBorder
IF DEF(_JAPAN)
	hlcoord 5, 9
	ld de, SaveScreenInfoText
	call PlaceString
	hlcoord 13, 9
	ld de, wPlayerName
	call PlaceString
	hlcoord 14, 11
	call PrintNumBadges
	hlcoord 13, 13
	call PrintNumOwnedMons
	hlcoord 12, 15
	call PrintPlayTime
ELIF DEF(_GERMAN)
	hlcoord 4, 9
	ld de, SaveScreenInfoText
	call PlaceString
	hlcoord 12, 9
	ld de, wPlayerName
	call PlaceString
	hlcoord 17, 11
	call PrintNumBadges
	hlcoord 16, 13
	call PrintNumOwnedMons
	hlcoord 13, 15
	call PrintPlayTime
ELSE
	hlcoord 5, 9
	ld de, SaveScreenInfoText
	call PlaceString
	hlcoord 12, 9
	ld de, wPlayerName
	call PlaceString
	hlcoord 17, 11
	call PrintNumBadges
	hlcoord 16, 13
	call PrintNumOwnedMons
	hlcoord 13, 15
	call PrintPlayTime
ENDC
	ld a, 1
	ldh [hAutoBGTransferEnabled], a
	ld c, 30
	jp DelayFrames

PrintSaveScreenText:
	xor a
	ldh [hAutoBGTransferEnabled], a
IF DEF(_JAPAN)
	hlcoord 5, 0
	lb bc, 8, 13
ELIF DEF(_GERMAN)
	hlcoord 3, 0
	lb bc, 8, 15
ELSE
	hlcoord 4, 0
	lb bc, 8, 14
ENDC
	call TextBoxBorder
	call LoadTextBoxTilePatterns
	call UpdateSprites
IF DEF(_JAPAN)
	hlcoord 6, 2
	ld de, SaveScreenInfoText
	call PlaceString
	hlcoord 13, 2
	ld de, wPlayerName
	call PlaceString
	hlcoord 15, 4
	call PrintNumBadges
	hlcoord 14, 6
	call PrintNumOwnedMons
	hlcoord 13, 8
	call PrintPlayTime
ELIF DEF(_GERMAN)
	hlcoord 4, 2
	ld de, SaveScreenInfoText
	call PlaceString
	hlcoord 12, 2
	ld de, wPlayerName
	call PlaceString
	hlcoord 17, 4
	call PrintNumBadges
	hlcoord 16, 6
	call PrintNumOwnedMons
	hlcoord 13, 8
	call PrintPlayTime
ELSE
	hlcoord 5, 2
	ld de, SaveScreenInfoText
	call PlaceString
	hlcoord 12, 2
	ld de, wPlayerName
	call PlaceString
	hlcoord 17, 4
	call PrintNumBadges
	hlcoord 16, 6
	call PrintNumOwnedMons
	hlcoord 13, 8
	call PrintPlayTime
ENDC
	ld a, $1
	ldh [hAutoBGTransferEnabled], a
	ld c, 30
	jp DelayFrames

PrintNumBadges:
	push hl
	ld hl, wObtainedBadges
	ld b, $1
	call CountSetBits
	pop hl
	ld de, wNumSetBits
	lb bc, 1, 2
	jp PrintNumber

PrintNumOwnedMons:
	push hl
	ld hl, wPokedexOwned
	ld b, wPokedexOwnedEnd - wPokedexOwned
	call CountSetBits
	pop hl
	ld de, wNumSetBits
	lb bc, 1, 3
	jp PrintNumber

PrintPlayTime:
	ld de, wPlayTimeHours
	lb bc, 1, 3
	call PrintNumber
IF DEF(_JAPAN)
	ld [hl], ':'
ELSE
	ld [hl], $6d
ENDC
	inc hl
	ld de, wPlayTimeMinutes
	lb bc, LEADING_ZEROES | 1, 2
	jp PrintNumber

SaveScreenInfoText:
IF DEF(_JAPAN)
	db   "しゅじんこう"
	next "もっているバッジ　　　　こ"
	next "#ずかん　　　　ひき"
	next "プレイじかん@"
ELIF DEF(_FRENCH)
	db   "JOUEUR"
	next "BADGES        "
	next "#DEX       "
	next "TEMPS@"
ELIF DEF(_GERMAN)
	db   "SPIELER"
	next "ORDEN          "
	next "#DEX        "
	next "ZEIT@"
ELIF DEF(_ITALIAN)
	db   "GIOCA."
	next "MEDAGLIE    "
	next "#DEX    "
	next "TEMPO@"
ELIF DEF(_SPANISH)
	db   "JUGAD."
	next "MEDALLAS    "
	next "#DEX    "
	next "TIEMPO@"
ELSE
	db   "PLAYER"
	next "BADGES    "
	next "#DEX    "
	next "TIME@"
ENDC

DisplayOptionMenu:
	callfar DisplayOptionMenu_
	ret

CheckForPlayerNameInSRAM:
	ld a, RAMG_SRAM_ENABLE
	ld [rRAMG], a
	ld a, BMODE_ADVANCED
	ld [rBMODE], a
	ASSERT BANK(sPlayerName) == BMODE_ADVANCED
	ld [rRAMB], a
	ld b, NAME_LENGTH
	ld hl, sPlayerName
.loop
	ld a, [hli]
	cp '@'
	jr z, .found
	dec b
	jr nz, .loop
	xor a
	ld [rRAMG], a
	ld [rBMODE], a
	and a
	ret
.found
	xor a
	ld [rRAMG], a
	ld [rBMODE], a
	scf
	ret
