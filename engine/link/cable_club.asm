; performs the appropriate action when the player uses the gameboy on the table in the Colosseum or Trade Center
; In the Colosseum, it starts a battle. In the Trade Center, it displays the trade selection screen.
; Before doing either action, it swaps random numbers, trainer names and party data with the other gameboy.
CableClub_DoBattleOrTrade:
	ld c, 80
	call DelayFrames
	call ClearScreen
	call UpdateSprites
	call LoadFontTilePatterns
	call LoadHpBarAndStatusTilePatterns
	call LoadTrainerInfoTextBoxTiles
	hlcoord 3, 8
IF DEF(_GERMAN)
	lb bc, 2, 13
ELSE
	lb bc, 2, 12
ENDC
	call CableClub_TextBoxBorder
	hlcoord 4, 10
	ld de, PleaseWaitString
	call PlaceString
	ld hl, wPlayerNumHits
	xor a
	ld [hli], a
	ld [hl], $50
	; fall through

; This is called after completing a trade.
CableClub_DoBattleOrTradeAgain:
	ld hl, wSerialPlayerDataBlock
	ld a, SERIAL_PREAMBLE_BYTE
	ld b, 6
.writePlayerDataBlockPreambleLoop
	ld [hli], a
	dec b
	jr nz, .writePlayerDataBlockPreambleLoop
	ld hl, wSerialRandomNumberListBlock
	ld a, SERIAL_PREAMBLE_BYTE
	ld b, 7
.writeRandomNumberListPreambleLoop
	ld [hli], a
	dec b
	jr nz, .writeRandomNumberListPreambleLoop
	ld b, 10
.generateRandomNumberListLoop
	call Random
	cp SERIAL_PREAMBLE_BYTE
	jr nc, .generateRandomNumberListLoop
	ld [hli], a
	dec b
	jr nz, .generateRandomNumberListLoop
	ld hl, wSerialPartyMonsPatchList
	ld a, SERIAL_PREAMBLE_BYTE
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld b, $c8
	xor a
.zeroPlayerDataPatchListLoop
	ld [hli], a
	dec b
	jr nz, .zeroPlayerDataPatchListLoop
	ld hl, wLinkEnemyTrainerName
IF DEF(_JAPAN)
	; Original JP behavior: this short clear is preserved for byte-exact reconstruction.
	; It does not reach wTrainerHeaderPtr and is a later modernization/fix target.
	ld bc, $13b
ELSE
	ld bc, wTrainerHeaderPtr - wLinkEnemyTrainerName
ENDC
.zeroEnemyPartyLoop
	xor a
	ld [hli], a
	dec bc
	ld a, b
	or c
	jr nz, .zeroEnemyPartyLoop
	ld hl, wPartyMons - 1
	ld de, wSerialPartyMonsPatchList + 10
	ld bc, 0
.patchPartyMonsLoop
	inc c
	ld a, c
	cp SERIAL_PREAMBLE_BYTE
	jr z, .startPatchListPart2
	ld a, b
	dec a
	jr nz, .checkPlayerDataByte
	ld a, c
	cp (wPartyMonOT - (wPartyMons - 1)) - (SERIAL_PREAMBLE_BYTE - 1)
	jr z, .finishedPatchingPlayerData
.checkPlayerDataByte
	inc hl
	ld a, [hl]
	cp SERIAL_NO_DATA_BYTE
	jr nz, .patchPartyMonsLoop
	ld a, c
	ld [de], a
	inc de
	ld [hl], $ff
	jr .patchPartyMonsLoop
.startPatchListPart2
	ld a, SERIAL_PATCH_LIST_PART_TERMINATOR
	ld [de], a
	inc de
	lb bc, 1, 0
	jr .patchPartyMonsLoop
.finishedPatchingPlayerData
	ld a, SERIAL_PATCH_LIST_PART_TERMINATOR
	ld [de], a
	call Serial_SyncAndExchangeNybble
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr nz, .skipSendingTwoZeroBytes
	call Delay3
	xor a
	ldh [hSerialSendData], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
	call DelayFrame
	xor a
	ldh [hSerialSendData], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
.skipSendingTwoZeroBytes
	call Delay3
	call StopAllMusic
	ld a, IE_SERIAL
	ldh [rIE], a
	ld hl, wSerialRandomNumberListBlock
	ld de, wSerialOtherGameboyRandomNumberListBlock
	ld bc, SERIAL_RN_PREAMBLE_LENGTH + SERIAL_RNS_LENGTH
	call Serial_ExchangeBytes
	ld a, SERIAL_NO_DATA_BYTE
	ld [de], a
	ld hl, wSerialPlayerDataBlock
	ld de, wSerialEnemyDataBlock
	ld bc, SERIAL_PREAMBLE_LENGTH + NAME_LENGTH + 1 + PARTY_LENGTH + 1 + (PARTYMON_STRUCT_LENGTH + NAME_LENGTH * 2) * PARTY_LENGTH + 3
	vc_hook Wireless_ExchangeBytes_party_structs
	call Serial_ExchangeBytes
	ld a, SERIAL_NO_DATA_BYTE
	ld [de], a
	ld hl, wSerialPartyMonsPatchList
	ld de, wSerialEnemyMonsPatchList
	ld bc, 200
	vc_hook Wireless_ExchangeBytes_patch_lists
	call Serial_ExchangeBytes
	ld a, IE_SERIAL | IE_TIMER | IE_VBLANK
	ldh [rIE], a
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr z, .skipCopyingRandomNumberList
	ld hl, wSerialOtherGameboyRandomNumberListBlock
.findStartOfRandomNumberListLoop
	ld a, [hli]
	and a
	jr z, .findStartOfRandomNumberListLoop
	cp SERIAL_PREAMBLE_BYTE
	jr z, .findStartOfRandomNumberListLoop
	cp SERIAL_NO_DATA_BYTE
	jr z, .findStartOfRandomNumberListLoop
	dec hl
	ld de, wLinkBattleRandomNumberList
	ld c, 10
.copyRandomNumberListLoop
	ld a, [hli]
	cp SERIAL_NO_DATA_BYTE
	jr z, .copyRandomNumberListLoop
	ld [de], a
	inc de
	dec c
	jr nz, .copyRandomNumberListLoop
.skipCopyingRandomNumberList
	ld hl, wSerialEnemyDataBlock + 3
.findStartOfEnemyNameLoop
	ld a, [hli]
	and a
	jr z, .findStartOfEnemyNameLoop
	cp SERIAL_PREAMBLE_BYTE
	jr z, .findStartOfEnemyNameLoop
	cp SERIAL_NO_DATA_BYTE
	jr z, .findStartOfEnemyNameLoop
	dec hl
	ld de, wLinkEnemyTrainerName
	ld c, NAME_LENGTH
.copyEnemyNameLoop
	ld a, [hli]
	cp SERIAL_NO_DATA_BYTE
	jr z, .copyEnemyNameLoop
	ld [de], a
	inc de
	dec c
	jr nz, .copyEnemyNameLoop
	ld de, wEnemyPartyCount
	ld bc, wTrainerHeaderPtr - wEnemyPartyCount
.copyEnemyPartyLoop
	ld a, [hli]
	cp SERIAL_NO_DATA_BYTE
	jr z, .copyEnemyPartyLoop
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .copyEnemyPartyLoop
	ld de, wSerialPartyMonsPatchList
	ld hl, wPartyMons
	ld c, 2
.unpatchPartyMonsLoop
	ld a, [de]
	inc de
	and a
	jr z, .unpatchPartyMonsLoop
	cp SERIAL_PREAMBLE_BYTE
	jr z, .unpatchPartyMonsLoop
	cp SERIAL_NO_DATA_BYTE
	jr z, .unpatchPartyMonsLoop
	cp SERIAL_PATCH_LIST_PART_TERMINATOR
	jr z, .finishedPartyMonsPatchListPart
	push hl
	push bc
	ld b, 0
	dec a
	ld c, a
	add hl, bc
	ld a, SERIAL_NO_DATA_BYTE
	ld [hl], a
	pop bc
	pop hl
	jr .unpatchPartyMonsLoop
.finishedPartyMonsPatchListPart
	ld hl, wPartyMons + (SERIAL_PREAMBLE_BYTE - 1)
	dec c
	jr nz, .unpatchPartyMonsLoop
	ld de, wSerialEnemyMonsPatchList
	ld hl, wEnemyMons
	ld c, 2
.unpatchEnemyMonsLoop
	ld a, [de]
	inc de
	and a
	jr z, .unpatchEnemyMonsLoop
	cp SERIAL_PREAMBLE_BYTE
	jr z, .unpatchEnemyMonsLoop
	cp SERIAL_NO_DATA_BYTE
	jr z, .unpatchEnemyMonsLoop
	cp SERIAL_PATCH_LIST_PART_TERMINATOR
	jr z, .finishedEnemyMonsPatchListPart
	push hl
	push bc
	ld b, 0
	dec a
	ld c, a
	add hl, bc
	ld a, SERIAL_NO_DATA_BYTE
	ld [hl], a
	pop bc
	pop hl
	jr .unpatchEnemyMonsLoop
.finishedEnemyMonsPatchListPart
	ld hl, wEnemyMons + (SERIAL_PREAMBLE_BYTE - 1)
	dec c
	jr nz, .unpatchEnemyMonsLoop
	ld a, LOW(wEnemyMonOT)
	ld [wUnusedNamePointer], a
	ld a, HIGH(wEnemyMonOT)
	ld [wUnusedNamePointer + 1], a
	xor a
	ld [wTradeCenterPointerTableIndex], a
	call StopAllMusic
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	ld c, 66
	call z, DelayFrames
	ld a, [wLinkState]
	cp LINK_STATE_START_BATTLE
	ld a, LINK_STATE_TRADING
	ld [wLinkState], a
	jr nz, .trading
	ld a, LINK_STATE_BATTLING
	ld [wLinkState], a
	ld a, OPP_RIVAL1
	ld [wCurOpponent], a
	call ClearScreen
	call Delay3
	ld b, SET_PAL_OVERWORLD
	call RunPaletteCommand
	ld hl, wOptions
	res BIT_BATTLE_ANIMATION, [hl]
	ld a, [wLetterPrintingDelayFlags]
	push af
	xor a
	ld [wLetterPrintingDelayFlags], a
	predef InitOpponent
	pop af
	ld [wLetterPrintingDelayFlags], a
	predef HealParty
	jp ReturnToCableClubRoom
.trading
	ld c, BANK(Music_GameCorner)
	ld a, MUSIC_GAME_CORNER
	call PlayMusic
	jr CallCurrentTradeCenterFunction

PleaseWaitString:
IF DEF(_JAPAN)
	db "つうしんじゅんびちゅう！@"
ELIF DEF(_FRENCH)
	db "ATTENDEZ SVP@"
ELIF DEF(_GERMAN)
	db "BITTE WARTEN!@"
ELIF DEF(_ITALIAN)
	db "ATTENDERE!@"
ELIF DEF(_SPANISH)
	db "¡ESPERA!@"
ELSE
	db "PLEASE WAIT!@"
ENDC

CallCurrentTradeCenterFunction:
	ld hl, TradeCenterPointerTable
	ld b, 0
	ld a, [wTradeCenterPointerTableIndex]
	cp $ff
	jp z, DisplayTitleScreen
	add a
	ld c, a
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

TradeCenter_SelectMon:
	call ClearScreen
	call Delay3
	ld b, SET_PAL_OVERWORLD
	call RunPaletteCommand
	call LoadTrainerInfoTextBoxTiles
	call TradeCenter_DrawPartyLists
	call TradeCenter_DrawCancelBox
	xor a
	ld hl, wSerialSyncAndExchangeNybbleReceiveData
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld [wMenuWatchMovingOutOfBounds], a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld [wMenuJoypadPollCount], a
	inc a
	ld [wSerialExchangeNybbleSendData], a
	jp .playerMonMenu
.enemyMonMenu
	xor a
	ld [wMenuWatchMovingOutOfBounds], a
	inc a
	ld [wWhichTradeMonSelectionMenu], a
	ld a, PAD_DOWN | PAD_LEFT | PAD_A
	ld [wMenuWatchedKeys], a
	ld a, [wEnemyPartyCount]
	ld [wMaxMenuItem], a
IF DEF(_JAPAN)
	ld a, 3
	ld [wTopMenuItemY], a
	ld a, $c
	ld [wTopMenuItemX], a
.enemyMonMenu_HandleInput
	call HandleMenuInput
ELSE
	ld a, 9
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a
.enemyMonMenu_HandleInput
	ld hl, hUILayoutFlags
	set BIT_DOUBLE_SPACED_MENU, [hl]
	call HandleMenuInput
	ld hl, hUILayoutFlags
	res BIT_DOUBLE_SPACED_MENU, [hl]
ENDC
	and a
	jp z, .getNewInput
	bit B_PAD_A, a
	jr z, .enemyMonMenu_ANotPressed
IF !DEF(_JAPAN)
	ld a, [wMaxMenuItem]
	ld c, a
	ld a, [wCurrentMenuItem]
	cp c
	jr c, .displayEnemyMonStats
	ld a, [wMaxMenuItem]
	dec a
	ld [wCurrentMenuItem], a
.displayEnemyMonStats
ENDC
	ld a, INIT_ENEMYOT_LIST
	ld [wInitListType], a
	callfar InitList
	ld hl, wEnemyMons
	call TradeCenter_DisplayStats
	jp .getNewInput
.enemyMonMenu_ANotPressed
	bit B_PAD_LEFT, a
	jr z, .enemyMonMenu_LeftNotPressed
	xor a
	ld [wWhichTradeMonSelectionMenu], a
	ld a, [wMenuCursorLocation]
	ld l, a
	ld a, [wMenuCursorLocation + 1]
	ld h, a
	ld a, [wTileBehindCursor]
	ld [hl], a
	ld a, [wCurrentMenuItem]
	ld b, a
	ld a, [wPartyCount]
	dec a
	cp b
	jr nc, .playerMonMenu
	ld [wCurrentMenuItem], a
	jr .playerMonMenu
.enemyMonMenu_LeftNotPressed
	bit B_PAD_DOWN, a
	jp z, .getNewInput
	jp .selectedCancelMenuItem
.playerMonMenu
	xor a
	ld [wWhichTradeMonSelectionMenu], a
	ld [wMenuWatchMovingOutOfBounds], a
	ld a, PAD_DOWN | PAD_RIGHT | PAD_A
	ld [wMenuWatchedKeys], a
	ld a, [wPartyCount]
	ld [wMaxMenuItem], a
IF DEF(_JAPAN)
	ld a, 3
	ld [wTopMenuItemY], a
	ld a, 2
	ld [wTopMenuItemX], a
.playerMonMenu_HandleInput
	call HandleMenuInput
ELSE
	ld a, 1
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a
	hlcoord 1, 1
	lb bc, 6, 1
	call ClearScreenArea
.playerMonMenu_HandleInput
	ld hl, hUILayoutFlags
	set BIT_DOUBLE_SPACED_MENU, [hl]
	call HandleMenuInput
	ld hl, hUILayoutFlags
	res BIT_DOUBLE_SPACED_MENU, [hl]
ENDC
	and a
	jr nz, .playerMonMenu_SomethingPressed
	jp .getNewInput
.playerMonMenu_SomethingPressed
	bit B_PAD_A, a
	jr z, .playerMonMenu_ANotPressed
	jp .chosePlayerMon
	ld a, INIT_PLAYEROT_LIST
	ld [wInitListType], a
	callfar InitList
	call TradeCenter_DisplayStats
	jp .getNewInput
.playerMonMenu_ANotPressed
	bit B_PAD_RIGHT, a
	jr z, .playerMonMenu_RightNotPressed
	ld a, $1
	ld [wWhichTradeMonSelectionMenu], a
	ld a, [wMenuCursorLocation]
	ld l, a
	ld a, [wMenuCursorLocation + 1]
	ld h, a
	ld a, [wTileBehindCursor]
	ld [hl], a
	ld a, [wCurrentMenuItem]
	ld b, a
	ld a, [wEnemyPartyCount]
	dec a
	cp b
	jr nc, .notPastLastEnemyMon
	ld [wCurrentMenuItem], a
.notPastLastEnemyMon
	jp .enemyMonMenu
.playerMonMenu_RightNotPressed
	bit B_PAD_DOWN, a
	jr z, .getNewInput
	jp .selectedCancelMenuItem
.getNewInput
	ld a, [wWhichTradeMonSelectionMenu]
	and a
	jp z, .playerMonMenu_HandleInput
	jp .enemyMonMenu_HandleInput
.chosePlayerMon
	call SaveScreenTilesToBuffer1
	call PlaceUnfilledArrowMenuCursor
IF DEF(_JAPAN)
	ld a, [wCurrentMenuItem]
ELSE
	ld a, [wMaxMenuItem]
	ld c, a
	ld a, [wCurrentMenuItem]
	cp c
	jr c, .displayStatsTradeMenu
	ld a, [wMaxMenuItem]
	dec a
.displayStatsTradeMenu
ENDC
	push af
	hlcoord 0, 14
	lb bc, 2, 18
	call CableClub_TextBoxBorder
	hlcoord 2, 16
	ld de, .statsTrade
	call PlaceString
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld [wMenuJoypadPollCount], a
	ld [wMaxMenuItem], a
	ld a, 16
	ld [wTopMenuItemY], a
.selectStatsMenuItem
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	ldcoord_a 11, 16
	ld a, PAD_RIGHT | PAD_B | PAD_A
	ld [wMenuWatchedKeys], a
	ld a, 1
	ld [wTopMenuItemX], a
	call HandleMenuInput
	bit B_PAD_RIGHT, a
	jr nz, .selectTradeMenuItem
	bit B_PAD_B, a
	jr z, .displayPlayerMonStats
.cancelPlayerMonChoice
	pop af
	ld [wCurrentMenuItem], a
	call LoadScreenTilesFromBuffer1
	jp .playerMonMenu
.selectTradeMenuItem
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	ldcoord_a 1, 16
	ld a, PAD_LEFT | PAD_B | PAD_A
	ld [wMenuWatchedKeys], a
	ld a, 11
	ld [wTopMenuItemX], a
	call HandleMenuInput
	bit B_PAD_LEFT, a
	jr nz, .selectStatsMenuItem
	bit B_PAD_B, a
	jr nz, .cancelPlayerMonChoice
	jr .choseTrade
.displayPlayerMonStats
	pop af
	ld [wCurrentMenuItem], a
	ld a, INIT_PLAYEROT_LIST
	ld [wInitListType], a
	callfar InitList
	call TradeCenter_DisplayStats
	call LoadScreenTilesFromBuffer1
	jp .playerMonMenu
.choseTrade
	call PlaceUnfilledArrowMenuCursor
	pop af
	ld [wCurrentMenuItem], a
	ld [wTradingWhichPlayerMon], a
	ld [wSerialExchangeNybbleSendData], a
	call Serial_PrintWaitingTextAndSyncAndExchangeNybble
	ld a, [wSerialSyncAndExchangeNybbleReceiveData]
	cp $f
	jp z, CallCurrentTradeCenterFunction
	ld [wTradingWhichEnemyMon], a
	call TradeCenter_PlaceSelectedEnemyMonMenuCursor
	ld a, $1
	ld [wTradeCenterPointerTableIndex], a
	jp CallCurrentTradeCenterFunction
.statsTrade
IF DEF(_JAPAN)
	db "ステイタスをみる　　こうかんにだす@"
ELIF DEF(_FRENCH)
	db "STATS     ECHANGE@"
ELIF DEF(_GERMAN)
	db "STATUS    TAUSCH@"
ELIF DEF(_ITALIAN)
	db "STAT.     OK     @"
ELIF DEF(_SPANISH)
	db "ESTAD.    TRATO@"
ELSE
	db "STATS     TRADE@"
ENDC
.selectedCancelMenuItem
	ld a, [wCurrentMenuItem]
	ld b, a
	ld a, [wMaxMenuItem]
	cp b
	jp nz, .getNewInput
	ld a, [wMenuCursorLocation]
	ld l, a
	ld a, [wMenuCursorLocation + 1]
	ld h, a
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	ld [hl], a
.cancelMenuItem_Loop
	ld a, '▶'
	ldcoord_a 1, 16
.cancelMenuItem_JoypadLoop
	call JoypadLowSensitivity
	ldh a, [hJoy5]
	and a
	jr z, .cancelMenuItem_JoypadLoop
	bit B_PAD_A, a
	jr nz, .cancelMenuItem_APressed
	bit B_PAD_UP, a
	jr z, .cancelMenuItem_JoypadLoop
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	ldcoord_a 1, 16
	ld a, [wPartyCount]
	dec a
	ld [wCurrentMenuItem], a
	jp .playerMonMenu
.cancelMenuItem_APressed
	ld a, '▷'
	ldcoord_a 1, 16
	ld a, $f
	ld [wSerialExchangeNybbleSendData], a
	call Serial_PrintWaitingTextAndSyncAndExchangeNybble
	ld a, [wSerialSyncAndExchangeNybbleReceiveData]
	cp $f
	jr nz, .cancelMenuItem_Loop
	; fall through

ReturnToCableClubRoom:
	call GBPalWhiteOutWithDelay3
	ld hl, wFontLoaded
	ld a, [hl]
	push af
	push hl
	res BIT_FONT_LOADED, [hl]
	xor a
	ld [wStatusFlags3], a
	dec a
	ld [wDestinationWarpID], a
	call LoadMapData
	farcall ClearVariablesOnEnterMap
	pop hl
	pop af
	ld [hl], a
	call GBFadeInFromWhite
	ret

TradeCenter_DrawCancelBox:
IF DEF(_ITALIAN)
	hlcoord 8, 15
	ld a, $7e
	ld bc, 2 * SCREEN_WIDTH + 12
ELSE
	hlcoord 11, 15
	ld a, $7e
	ld bc, 2 * SCREEN_WIDTH + 9
ENDC
	call FillMemory
	hlcoord 0, 15
IF DEF(_GERMAN)
	lb bc, 1, 12
ELIF DEF(_ITALIAN)
	lb bc, 1, 6
ELIF DEF(_SPANISH)
	lb bc, 1, 16
ELSE
	lb bc, 1, 9
ENDC
	call CableClub_TextBoxBorder
	hlcoord 2, 16
	ld de, CancelTextString
	jp PlaceString

CancelTextString:
IF DEF(_JAPAN)
	db "こうかんちゅうし@"
ELIF DEF(_FRENCH)
	db "ANNULER@"
ELIF DEF(_GERMAN)
	db "ABBRECHEN@"
ELIF DEF(_ITALIAN)
	db "ESCI@"
ELIF DEF(_SPANISH)
	db "Trato Cancelado@"
ELSE
	db "CANCEL@"
ENDC

TradeCenter_PlaceSelectedEnemyMonMenuCursor:
	ld a, [wSerialSyncAndExchangeNybbleReceiveData]
IF DEF(_JAPAN)
	hlcoord 12, 3
	ld bc, 2 * SCREEN_WIDTH
ELSE
	hlcoord 1, 9
	ld bc, SCREEN_WIDTH
ENDC
	call AddNTimes
	ld [hl], '▷'
	ret

TradeCenter_DisplayStats:
	ld a, [wCurrentMenuItem]
	ld [wWhichPokemon], a
	predef StatusScreen
	predef StatusScreen2
	call Delay3
	ld b, SET_PAL_OVERWORLD
	call RunPaletteCommand
	call GBPalNormal
	call LoadTrainerInfoTextBoxTiles
	call TradeCenter_DrawPartyLists
	jp TradeCenter_DrawCancelBox

TradeCenter_DrawPartyLists:
IF DEF(_JAPAN)
	hlcoord 0, 1
	lb bc, 12, 8
	call CableClub_TextBoxBorder
	hlcoord 10, 1
	lb bc, 12, 8
	call CableClub_TextBoxBorder
	hlcoord 3, 1
	ld de, wPlayerName
	call PlaceString
	hlcoord 13, 1
	ld de, wLinkEnemyTrainerName
	call PlaceString
	hlcoord 3, 3
	ld de, wPartySpecies
	call TradeCenter_PrintPartyListNames
	hlcoord 13, 3
	ld de, wEnemyPartySpecies
ELSE
	hlcoord 0, 0
	lb bc, 6, 18
	call CableClub_TextBoxBorder
	hlcoord 0, 8
	lb bc, 6, 18
	call CableClub_TextBoxBorder
	hlcoord 5, 0
	ld de, wPlayerName
	call PlaceString
	hlcoord 5, 8
	ld de, wLinkEnemyTrainerName
	call PlaceString
	hlcoord 2, 1
	ld de, wPartySpecies
	call TradeCenter_PrintPartyListNames
	hlcoord 2, 9
	ld de, wEnemyPartySpecies
ENDC
	; fall through

TradeCenter_PrintPartyListNames:
	ld c, $0
.loop
	ld a, [de]
	cp $ff
	ret z
	ld [wNamedObjectIndex], a
	push bc
	push hl
	push de
	push hl
	ld a, c
	ldh [hPastLeadingZeros], a
	call GetMonName
	pop hl
	call PlaceString
	pop de
	inc de
	pop hl
IF DEF(_JAPAN)
	ld bc, 2 * SCREEN_WIDTH
ELSE
	ld bc, SCREEN_WIDTH
ENDC
	add hl, bc
	pop bc
	inc c
	jr .loop

TradeCenter_Trade:
	ld c, 100
	call DelayFrames
	xor a
	ld [wSerialExchangeNybbleSendData + 1], a
	ld [wSerialExchangeNybbleReceiveData], a
	ld [wMenuWatchMovingOutOfBounds], a
	ld [wMenuJoypadPollCount], a
	hlcoord 0, 12
	lb bc, 4, 18
	call CableClub_TextBoxBorder
	ld a, [wTradingWhichPlayerMon]
	ld hl, wPartySpecies
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	ld [wNamedObjectIndex], a
	call GetMonName
	ld hl, wNameBuffer
	ld de, wNameOfPlayerMonToBeTraded
	ld bc, NAME_LENGTH
	call CopyData
	ld a, [wTradingWhichEnemyMon]
	ld hl, wEnemyPartySpecies
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	ld [wNamedObjectIndex], a
	call GetMonName
	ld hl, WillBeTradedText
	bccoord 1, 14
	call TextCommandProcessor
	call SaveScreenTilesToBuffer1
	hlcoord 10, 7
	lb bc, 8, 11
	ld a, TRADE_CANCEL_MENU
	ld [wTwoOptionMenuID], a
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID
	call LoadScreenTilesFromBuffer1
	ld a, [wCurrentMenuItem]
	and a
	jr z, .tradeConfirmed
	ld a, $1
	ld [wSerialExchangeNybbleSendData], a
	hlcoord 0, 12
	lb bc, 4, 18
	call CableClub_TextBoxBorder
	hlcoord 1, 14
	ld de, TradeCanceled
	call PlaceString
	call Serial_PrintWaitingTextAndSyncAndExchangeNybble
	jp .tradeCancelled
.tradeConfirmed
	ld a, $2
	ld [wSerialExchangeNybbleSendData], a
	call Serial_PrintWaitingTextAndSyncAndExchangeNybble
	ld a, [wSerialSyncAndExchangeNybbleReceiveData]
	dec a
	jr nz, .doTrade
	hlcoord 0, 12
	lb bc, 4, 18
	call CableClub_TextBoxBorder
	hlcoord 1, 14
	ld de, TradeCanceled
	call PlaceString
	jp .tradeCancelled
.doTrade
	ld a, [wTradingWhichPlayerMon]
	ld hl, wPartyMonOT
	call SkipFixedLengthTextEntries
	ld de, wTradedPlayerMonOT
	ld bc, NAME_LENGTH
	call CopyData
	ld hl, wPartyMon1Species
	ld a, [wTradingWhichPlayerMon]
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	ld bc, MON_OTID
	add hl, bc
	ld a, [hli]
	ld [wTradedPlayerMonOTID], a
	ld a, [hl]
	ld [wTradedPlayerMonOTID + 1], a
	ld a, [wTradingWhichEnemyMon]
	ld hl, wEnemyMonOT
	call SkipFixedLengthTextEntries
	ld de, wTradedEnemyMonOT
	ld bc, NAME_LENGTH
	call CopyData
	ld hl, wEnemyMons
	ld a, [wTradingWhichEnemyMon]
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	ld bc, MON_OTID
	add hl, bc
	ld a, [hli]
	ld [wTradedEnemyMonOTID], a
	ld a, [hl]
	ld [wTradedEnemyMonOTID + 1], a
	ld a, [wTradingWhichPlayerMon]
	ld [wWhichPokemon], a
	ld hl, wPartySpecies
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld [wTradedPlayerMonSpecies], a
	farcall_ModifyPikachuHappiness PIKAHAPPY_TRADE
	xor a
	ld [wRemoveMonFromBox], a
	call RemovePokemon
	ld a, [wTradingWhichEnemyMon]
	ld c, a
	ld [wWhichPokemon], a
	ld hl, wEnemyPartySpecies
	ld d, 0
	ld e, a
	add hl, de
	ld a, [hl]
	ld [wCurPartySpecies], a
	ld hl, wEnemyMons
	ld a, c
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	ld de, wLoadedMon
	ld bc, PARTYMON_STRUCT_LENGTH
	call CopyData
	call AddEnemyMonToPlayerParty
	ld a, [wPartyCount]
	dec a
	ld [wWhichPokemon], a
	ld a, TRUE
	ld [wForceEvolution], a
	ld a, [wTradingWhichEnemyMon]
	ld hl, wEnemyPartySpecies
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld [wTradedEnemyMonSpecies], a
	ld a, 10
	ld [wAudioFadeOutControl], a
	ld a, BANK(Music_SafariZone)
	ld [wAudioSavedROMBank], a
	ld a, MUSIC_SAFARI_ZONE
	ld [wNewSoundID], a
	call PlaySound
	ld c, 100
	call DelayFrames
	call ClearScreen
	call LoadHpBarAndStatusTilePatterns
	xor a
	ld [wUnusedFlag], a
	ldh a, [hSerialConnectionStatus]
	cp USING_EXTERNAL_CLOCK
	jr z, .usingExternalClock
	predef InternalClockTradeAnim
	jr .tradeCompleted
.usingExternalClock
	predef ExternalClockTradeAnim
.tradeCompleted
	callfar TryEvolvingMon
	call ClearScreen
	call LoadTrainerInfoTextBoxTiles
	call Serial_PrintWaitingTextAndSyncAndExchangeNybble
	ld c, 40
	call DelayFrames
	call Delay3
	ld b, SET_PAL_OVERWORLD
	call RunPaletteCommand
	hlcoord 0, 12
	lb bc, 4, 18
	call CableClub_TextBoxBorder
	hlcoord 1, 14
	ld de, TradeCompleted
	call PlaceString
	predef SavePartyAndDexData
	vc_hook Trade_save_game_end
	ld c, 50
	call DelayFrames
	xor a
	ld [wTradeCenterPointerTableIndex], a
	jp CableClub_DoBattleOrTradeAgain
.tradeCancelled
	ld c, 100
	call DelayFrames
	xor a
	ld [wTradeCenterPointerTableIndex], a
	jp CallCurrentTradeCenterFunction

WillBeTradedText:
IF DEF(_JAPAN)
	text_ram wNameOfPlayerMonToBeTraded
	text "　と　@"
	text_ram wNameBuffer
	text "　を"
	line "こうかんします"
	done
ELSE
	text_far _WillBeTradedText
	text_end
ENDC

TradeCompleted:
IF DEF(_JAPAN)
	db "こうかんしゅうりょう！@"
ELIF DEF(_FRENCH)
	db "ECHANGE TERMINE!@"
ELIF DEF(_GERMAN)
	db "TAUSCH VOLLZOGEN!@"
ELIF DEF(_ITALIAN)
	db "SCAMBIO TERMINATO@"
ELIF DEF(_SPANISH)
	db "Trato completado@"
ELSE
	db "Trade completed!@"
ENDC

TradeCanceled:
IF DEF(_JAPAN)
	db   "ざんねんながら"
	next "こうかんは　キャンセルされました@"
ELIF DEF(_FRENCH)
	db   "Dommage! L'échange"
	next "est annulé!@"
ELIF DEF(_GERMAN)
	db   "Schade! Der Tausch"
	next "wurde abgebrochen!@"
ELIF DEF(_ITALIAN)
	db   "PECCATO! SCAMBIO"
	next "ANNULLATO!@"
ELIF DEF(_SPANISH)
	db   "¡Mal! ¡El trato"
	next "está cancelado!@"
ELSE
	db   "Too bad! The trade"
	next "was canceled!@"
ENDC

TradeCenterPointerTable:
	dw TradeCenter_SelectMon
	dw TradeCenter_Trade

CableClub_Run:
	ld a, [wLinkState]
	cp LINK_STATE_START_TRADE
	jr z, .doBattleOrTrade
	cp LINK_STATE_START_BATTLE
	jr z, .doBattleOrTrade
	cp LINK_STATE_RESET
	ret nz
	predef EmptyFunc
	jp Init
.doBattleOrTrade
	call CableClub_DoBattleOrTrade
	ld hl, Club_GFX
	ld a, h
	ld [wTilesetGfxPtr + 1], a
	ld a, l
	ld [wTilesetGfxPtr], a
	ld a, BANK(Club_GFX)
	ld [wTilesetBank], a
	ld hl, Club_Coll
	ld a, h
	ld [wTilesetCollisionPtr + 1], a
	ld a, l
	ld [wTilesetCollisionPtr], a
	xor a
	ld [wGrassRate], a
	inc a
	ld [wLinkState], a
	ldh [hJoy5], a
	ld a, 10
	ld [wAudioFadeOutControl], a
	ld a, BANK(Music_Celadon)
	ld [wAudioSavedROMBank], a
	ld a, MUSIC_CELADON
	ld [wNewSoundID], a
	jp PlaySound

EmptyFunc:
	ret

Diploma_TextBoxBorder:
	call GetPredefRegisters

CableClub_TextBoxBorder:
	push hl
	ld a, $78
	ld [hli], a
	inc a
	call CableClub_DrawHorizontalLine
	inc a
	ld [hl], a
	pop hl
	ld de, SCREEN_WIDTH
	add hl, de
.loop
	push hl
	ld a, $7b
	ld [hli], a
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	call CableClub_DrawHorizontalLine
	ld [hl], $77
	pop hl
	ld de, SCREEN_WIDTH
	add hl, de
	dec b
	jr nz, .loop
	ld a, $7c
	ld [hli], a
	ld a, $76
	call CableClub_DrawHorizontalLine
	ld [hl], $7d
	ret

CableClub_DrawHorizontalLine:
	ld d, c
.loop
	ld [hli], a
	dec d
	jr nz, .loop
	ret

LoadTrainerInfoTextBoxTiles:
	ld de, TrainerInfoTextBoxTileGraphics
	ld hl, vChars2 tile $76
	lb bc, BANK(TrainerInfoTextBoxTileGraphics), (TrainerInfoTextBoxTileGraphicsEnd - TrainerInfoTextBoxTileGraphics) / TILE_SIZE
	jp CopyVideoData
