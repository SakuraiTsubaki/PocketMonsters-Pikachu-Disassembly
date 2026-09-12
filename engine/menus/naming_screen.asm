AskName:
	call SaveScreenTilesToBuffer1
	call GetPredefRegisters
	push hl
	ld a, [wIsInBattle]
	dec a
IF DEF(_JAPAN)
	hlcoord 1, 0
	lb bc, 4, 10
ELSE
	hlcoord 0, 0
	lb bc, 4, 11
ENDC
	call z, ClearScreenArea
	ld a, [wCurPartySpecies]
	ld [wNamedObjectIndex], a
	call GetMonName
	ld hl, DoYouWantToNicknameText
	call PrintText
	hlcoord 14, 7
	lb bc, 8, 15
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID
	pop hl
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .declinedNickname
	ld a, [wUpdateSpritesEnabled]
	push af
	xor a
	ld [wUpdateSpritesEnabled], a
	push hl
	ld a, NAME_MON_SCREEN
	ld [wNamingScreenType], a
	call DisplayNamingScreen
	ld a, [wIsInBattle]
	and a
	jr nz, .inBattle
	call ReloadMapSpriteTilePatterns
.inBattle
	call LoadScreenTilesFromBuffer1
	pop hl
	pop af
	ld [wUpdateSpritesEnabled], a
	ld a, [wStringBuffer]
	cp '@'
	ret nz
.declinedNickname
	ld d, h
	ld e, l
	ld hl, wNameBuffer
	ld bc, NAME_LENGTH
	jp CopyData

DoYouWantToNicknameText:
IF DEF(_JAPAN)
	text_ram wNameBuffer
	text "に"
	line "ニックネームを　つけますか？"
	done
ELSE
	text_far _DoYouWantToNicknameText
	text_end
ENDC

DisplayNameRaterScreen::
	ld hl, wBuffer
	xor a
	ld [wUpdateSpritesEnabled], a
	ld a, NAME_MON_SCREEN
	ld [wNamingScreenType], a
	call DisplayNamingScreen
	call GBPalWhiteOutWithDelay3
	call RestoreScreenTilesAndReloadTilePatterns
	call LoadGBPal
	ld a, [wStringBuffer]
	cp '@'
	jr z, .playerCancelled
	ld hl, wPartyMonNicks
	ld bc, NAME_LENGTH
	ld a, [wWhichPokemon]
	call AddNTimes
	ld e, l
	ld d, h
	ld hl, wBuffer
	ld bc, NAME_LENGTH
	call CopyData
	and a
	ret
.playerCancelled
	scf
	ret

DisplayNamingScreen:
	push hl
	ld hl, wStatusFlags5
	set BIT_NO_TEXT_DELAY, [hl]
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call UpdateSprites
	ld b, SET_PAL_GENERIC
	call RunPaletteCommand
	call LoadHpBarAndStatusTilePatterns
	call LoadEDTile
	farcall LoadMonPartySpriteGfx
	hlcoord 0, 4
IF DEF(_JAPAN)
	lb bc, 11, 18
ELSE
	lb bc, 9, 18
ENDC
	call TextBoxBorder
	call PrintNamingText
	ld a, 3
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a
	ld [wLastMenuItem], a
	ld [wCurrentMenuItem], a
	ld a, $ff
	ld [wMenuWatchedKeys], a
IF DEF(_JAPAN)
	ld a, 8
ELSE
	ld a, 7
ENDC
	ld [wMaxMenuItem], a
	ld a, '@'
	ld [wStringBuffer], a
	xor a
	ld hl, wNamingScreenSubmitName
	ld [hli], a
	ld [hli], a
	ld [wAnimCounter], a
.selectReturnPoint
	call PrintAlphabet
	call GBPalNormal
.ABStartReturnPoint
	ld a, [wNamingScreenSubmitName]
	and a
	jr nz, .submitNickname
	call PrintNicknameAndUnderscores
.dPadReturnPoint
	call PlaceMenuCursor
.inputLoop
	ld a, [wCurrentMenuItem]
	push af
	farcall AnimatePartyMon_ForceSpeed1
	pop af
	ld [wCurrentMenuItem], a
	call JoypadLowSensitivity
	ldh a, [hJoyPressed]
	and a
	jr z, .inputLoop
	ld hl, .namingScreenButtonFunctions
.checkForPressedButton
	sla a
	jr c, .foundPressedButton
	inc hl
	inc hl
	inc hl
	inc hl
	jr .checkForPressedButton
.foundPressedButton
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push de
	jp hl

.submitNickname
	pop de
	ld hl, wStringBuffer
	ld bc, NAME_LENGTH
	call CopyData
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call ClearSprites
	call RunDefaultPaletteCommand
	call GBPalNormal
	xor a
	ld [wAnimCounter], a
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	ld a, [wIsInBattle]
	and a
	jp z, LoadTextBoxTilePatterns
	jpfar LoadHudTilePatterns

.namingScreenButtonFunctions
	dw .dPadReturnPoint
	dw .pressedDown
	dw .dPadReturnPoint
	dw .pressedUp
	dw .dPadReturnPoint
	dw .pressedLeft
	dw .dPadReturnPoint
	dw .pressedRight
	dw .ABStartReturnPoint
	dw .pressedStart
	dw .selectReturnPoint
	dw .pressedSelect
	dw .ABStartReturnPoint
	dw .pressedB
	dw .ABStartReturnPoint
	dw .pressedA

.pressedA_changedCase
	pop de
	ld de, .selectReturnPoint
	push de
.pressedSelect
	ld a, [wAlphabetCase]
	xor $1
	ld [wAlphabetCase], a
	ret

.pressedStart
	ld a, 1
	ld [wNamingScreenSubmitName], a
	ret

.pressedA
	ld a, [wCurrentMenuItem]
IF DEF(_JAPAN)
	cp 6
ELSE
	cp $5
ENDC
	jr nz, .didNotPressED
	ld a, [wTopMenuItemX]
	cp $11
	jr z, .pressedStart
.didNotPressED
	ld a, [wCurrentMenuItem]
IF DEF(_JAPAN)
	cp $7
ELSE
	cp $6
ENDC
	jr nz, .didNotPressCaseSwitch
	ld a, [wTopMenuItemX]
	cp $1
	jr z, .pressedA_changedCase
.didNotPressCaseSwitch
	ld hl, wMenuCursorLocation
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [hl]
	ld [wNamingScreenLetter], a
	call CalcStringLength
	ld a, [wNamingScreenLetter]
IF DEF(_JAPAN)
	cp '゛'
	ld de, Dakutens
	jr z, .dakutensAndHandakutens
	cp '゜'
	ld de, Handakutens
	jr z, .dakutensAndHandakutens
	ld a, [wNamingScreenNameLength]
	cp NAME_LENGTH - 1
ELSE
	cp 'ﾞ'
	ld de, Dakutens
	jr z, .dakutensAndHandakutens
	cp 'ﾟ'
	ld de, Handakutens
	jr z, .dakutensAndHandakutens
	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	jr nc, .checkMonNameLength
	ld a, [wNamingScreenNameLength]
	cp PLAYER_NAME_LENGTH - 1
	jr .checkNameLength
.checkMonNameLength
	ld a, [wNamingScreenNameLength]
	cp NAME_LENGTH - 1
.checkNameLength
ENDC
	jr c, .addLetter
	ret

.dakutensAndHandakutens
	push hl
	call DakutensAndHandakutens
	pop hl
	ret nc
	dec hl
.addLetter
	ld a, [wNamingScreenLetter]
	ld [hli], a
	ld [hl], '@'
	ld a, SFX_PRESS_AB
	call PlaySound
	ret
.pressedB
	ld a, [wNamingScreenNameLength]
	and a
	ret z
	call CalcStringLength
	dec hl
	ld [hl], '@'
	ret
.pressedRight
	ld a, [wCurrentMenuItem]
IF DEF(_JAPAN)
	cp $7
ELSE
	cp $6
ENDC
	ret z
	ld a, [wTopMenuItemX]
	cp $11
	jp z, .wrapToFirstColumn
	inc a
	inc a
	jr .done
.wrapToFirstColumn
	ld a, $1
	jr .done
.pressedLeft
	ld a, [wCurrentMenuItem]
IF DEF(_JAPAN)
	cp $7
ELSE
	cp $6
ENDC
	ret z
	ld a, [wTopMenuItemX]
	dec a
	jp z, .wrapToLastColumn
	dec a
	jr .done
.wrapToLastColumn
	ld a, $11
	jr .done
.pressedUp
	ld a, [wCurrentMenuItem]
	dec a
	ld [wCurrentMenuItem], a
	and a
	ret nz
IF DEF(_JAPAN)
	ld a, $7
ELSE
	ld a, $6
ENDC
	ld [wCurrentMenuItem], a
	ld a, $1
	jr .done
.pressedDown
	ld a, [wCurrentMenuItem]
	inc a
	ld [wCurrentMenuItem], a
IF DEF(_JAPAN)
	cp $8
ELSE
	cp $7
ENDC
	jr nz, .wrapToTopRow
	ld a, $1
	ld [wCurrentMenuItem], a
	jr .done
.wrapToTopRow
IF DEF(_JAPAN)
	cp $7
ELSE
	cp $6
ENDC
	ret nz
	ld a, $1
.done
	ld [wTopMenuItemX], a
	jp EraseMenuCursor

LoadEDTile:
	ld de, ED_Tile
	ld hl, vFont tile $70
IF DEF(_JAPAN)
	; Original JP code relies on MBC3 bank-zero behavior.
	lb bc, BANK("Home"), (ED_TileEnd - ED_Tile) / $8
	jp CopyVideoDataDouble
ELSE
	; International Yellow's MBC5-safe direct HBlank copy.
	ld c, $4
.waitForHBlankLoop
	ldh a, [rSTAT]
	and %10
	jr nz, .waitForHBlankLoop
	ld a, [de]
	ld [hli], a
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	ld [hli], a
	inc de
	dec c
	jr nz, .waitForHBlankLoop
	ret
ENDC

ED_Tile:
	INCBIN "gfx/font/ED.1bpp"
ED_TileEnd:

PrintAlphabet:
	xor a
	ldh [hAutoBGTransferEnabled], a
	ld a, [wAlphabetCase]
	and a
IF DEF(_JAPAN)
	ld de, HiraganaCharacters
	jr nz, .lowercase
	ld de, KatakanaCharacters
ELSE
	ld de, LowerCaseAlphabet
	jr nz, .lowercase
	ld de, UpperCaseAlphabet
ENDC
.lowercase
	hlcoord 2, 5
IF DEF(_JAPAN)
	lb bc, 6, 9
ELSE
	lb bc, 5, 9
ENDC
.outerLoop
	push bc
.innerLoop
	ld a, [de]
	ld [hli], a
	inc hl
	inc de
	dec c
	jr nz, .innerLoop
	ld bc, SCREEN_WIDTH + 2
	add hl, bc
	pop bc
	dec b
	jr nz, .outerLoop
	call PlaceString
IF DEF(_JAPAN)
	hlcoord 5, 17
	ld de, KanaInputText
	call PlaceString
ENDC
	ld a, $1
	ldh [hAutoBGTransferEnabled], a
	jp Delay3

IF DEF(_JAPAN)
	INCLUDE "data/text/kana.asm"
ELSE
	INCLUDE "data/text/alphabets.asm"
ENDC

PrintNicknameAndUnderscores:
	call CalcStringLength
	ld a, c
	ld [wNamingScreenNameLength], a
IF DEF(_JAPAN)
	hlcoord 13, 1
	lb bc, 2, 5
	call ClearScreenArea
	hlcoord 13, 2
	ld de, wStringBuffer
	call PlaceString
	hlcoord 13, 3
	ld a, $76
	ld b, NAME_LENGTH - 1
.placeUnderscoreLoop
	ld [hli], a
	dec b
	jr nz, .placeUnderscoreLoop
	ld a, [wNamingScreenNameLength]
	cp NAME_LENGTH - 1
	jr nz, .placeRaisedUnderscore
	call EraseMenuCursor
	ld a, $11
	ld [wTopMenuItemX], a
	ld a, $6
	ld [wCurrentMenuItem], a
	ld a, NAME_LENGTH - 2
.placeRaisedUnderscore
	hlcoord 13, 3
	add l
	ld l, a
	ld [hl], $77
	ret
ELSE
	hlcoord 10, 2
	lb bc, 1, 10
	call ClearScreenArea
	hlcoord 10, 2
	ld de, wStringBuffer
	call PlaceString
	hlcoord 10, 3
	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	jr nc, .pokemon
	ld b, PLAYER_NAME_LENGTH - 1
	jr .gotUnderscoreCount
.pokemon
	ld b, NAME_LENGTH - 1
.gotUnderscoreCount
	ld a, $76
.placeUnderscoreLoopIntl
	ld [hli], a
	dec b
	jr nz, .placeUnderscoreLoopIntl
	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	ld a, [wNamingScreenNameLength]
	jr nc, .pokemon2
	cp PLAYER_NAME_LENGTH - 1
	jr .checkEmptySpaces
.pokemon2
	cp NAME_LENGTH - 1
.checkEmptySpaces
	jr nz, .placeRaisedUnderscoreIntl
	call EraseMenuCursor
	ld a, $11
	ld [wTopMenuItemX], a
	ld a, $5
	ld [wCurrentMenuItem], a
	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	ld a, NAME_LENGTH - 2
	jr nc, .placeRaisedUnderscoreIntl
	ld a, PLAYER_NAME_LENGTH - 2
.placeRaisedUnderscoreIntl
	ld c, a
	ld b, $0
	hlcoord 10, 3
	add hl, bc
	ld [hl], $77
	ret
ENDC

DakutensAndHandakutens:
	push de
	call CalcStringLength
	dec hl
	ld a, [hl]
	pop hl
	ld de, $2
	call IsInArray
	ret nc
	inc hl
	ld a, [hl]
	ld [wNamingScreenLetter], a
	ret

INCLUDE "data/text/dakutens.asm"

CalcStringLength:
	ld hl, wStringBuffer
	ld c, $0
.loop
	ld a, [hl]
	cp '@'
	ret z
	inc hl
	inc c
	jr .loop

PrintNamingText:
IF DEF(_JAPAN)
	hlcoord 1, 2
	ld a, [wNamingScreenType]
	ld de, YourTextString
	and a
	jr z, .notNicknameJP
	ld de, RivalsTextString
	dec a
	jr z, .notNicknameJP
	ld a, [wCurPartySpecies]
	ld [wMonPartySpriteSpecies], a
	push af
	farcall WriteMonPartySpriteOAMBySpecies
	pop af
	ld [wNamedObjectIndex], a
	call GetMonName
	hlcoord 4, 1
	call PlaceString
	ld hl, $1
	add hl, bc
	ld [hl], 'の'
	hlcoord 4, 3
	ld de, NicknameTextString
	jr .placeStringJP
.notNicknameJP
	call PlaceString
	ld l, c
	ld h, b
	ld de, NameTextString
.placeStringJP
	jp PlaceString
ELIF DEF(_FRENCH) || DEF(_ITALIAN) || DEF(_SPANISH)
	hlcoord 0, 1
	ld a, [wNamingScreenType]
	ld de, YourTextString
	and a
	jr z, .placeStringDirect
	ld de, RivalsTextString
	dec a
	jr z, .placeStringDirect
	ld a, [wCurPartySpecies]
	ld [wMonPartySpriteSpecies], a
	push af
	farcall WriteMonPartySpriteOAMBySpecies
	pop af
	ld [wNamedObjectIndex], a
	call GetMonName
	hlcoord 4, 1
	call PlaceString
	hlcoord 1, 3
	ld de, NicknameTextString
.placeStringDirect
	jp PlaceString
ELSE
	hlcoord 0, 1
	ld a, [wNamingScreenType]
	ld de, YourTextString
	and a
	jr z, .notNicknameIntl
	ld de, RivalsTextString
	dec a
	jr z, .notNicknameIntl
	ld a, [wCurPartySpecies]
	ld [wMonPartySpriteSpecies], a
	push af
	farcall WriteMonPartySpriteOAMBySpecies
	pop af
	ld [wNamedObjectIndex], a
	call GetMonName
	hlcoord 4, 1
	call PlaceString
	ld hl, $1
	add hl, bc
	ld [hl], 'の'
	hlcoord 1, 3
	ld de, NicknameTextString
	jr .placeStringIntl
.notNicknameIntl
	call PlaceString
	ld l, c
	ld h, b
	ld de, NameTextString
.placeStringIntl
	jp PlaceString
ENDC

YourTextString:
IF DEF(_JAPAN)
	db "あなた@"
ELIF DEF(_FRENCH)
	db "VOTRE NOM?@"
ELIF DEF(_GERMAN)
	db "DEIN @"
ELIF DEF(_ITALIAN)
	db "NOME TUO?@"
ELIF DEF(_SPANISH)
	db $e4, "TU NOMBRE?@" ; ¿ = $e4
ELSE
	db "YOUR @"
ENDC

RivalsTextString:
IF DEF(_JAPAN)
	db "ライバル@"
ELIF DEF(_FRENCH)
	db "NOM DU RIVAL?@"
ELIF DEF(_GERMAN)
	db "GEGNER-@"
ELIF DEF(_ITALIAN)
	db "NOME RIVALE?@"
ELIF DEF(_SPANISH)
	db $e4, "NOMBRE RIVAL?@"
ELSE
	db "RIVAL's @"
ENDC

NameTextString:
IF DEF(_JAPAN)
	db "のなまえは？@"
ELIF DEF(_FRENCH)
	db "NOM?@" ; unreferenced in the direct-prompt path
ELIF DEF(_ITALIAN)
	db "NOME?@" ; unreferenced in the direct-prompt path
ELIF DEF(_SPANISH)
	db $e4, "NOMBRE?@" ; unreferenced in the direct-prompt path
ELSE
	db "NAME?@"
ENDC

NicknameTextString:
IF DEF(_JAPAN)
	db "ニックネームは？@"
ELIF DEF(_FRENCH)
	db "SURNOM?@"
ELIF DEF(_GERMAN)
	db "ALIAS?@"
ELIF DEF(_ITALIAN)
	db "NOME?@"
ELIF DEF(_SPANISH)
	db $e4, "APODO?@"
ELSE
	db "NICKNAME?@"
ENDC
