; function to draw various text boxes
DisplayTextBoxID_::
	ld a, [wTextBoxID]
	cp TWO_OPTION_MENU
	jp z, DisplayTwoOptionMenu
	ld c, a
	ld hl, TextBoxFunctionTable
	ld de, 3
	call SearchTextBoxTable
	jr c, .functionTableMatch
	ld hl, TextBoxCoordTable
	ld de, 5
	call SearchTextBoxTable
	jr c, .coordTableMatch
	ld hl, TextBoxTextAndCoordTable
	ld de, 9
	call SearchTextBoxTable
	jr c, .textAndCoordTableMatch
.done
	ret
.functionTableMatch
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, .done
	push de
	jp hl
.coordTableMatch
	call GetTextBoxIDCoords
	call GetAddressOfScreenCoords
	call TextBoxBorder
	ret
.textAndCoordTableMatch
	call GetTextBoxIDCoords
	push hl
	call GetAddressOfScreenCoords
	call TextBoxBorder
	pop hl
	call GetTextBoxIDText
	ld a, [wStatusFlags5]
	push af
	set BIT_NO_TEXT_DELAY, a
	ld [wStatusFlags5], a
	call PlaceString
	pop af
	ld [wStatusFlags5], a
	call UpdateSprites
	ret

SearchTextBoxTable:
	dec de
.loop
	ld a, [hli]
	cp $ff
	jr z, .notFound
	cp c
	jr z, .found
	add hl, de
	jr .loop
.found
	scf
.notFound
	ret

GetTextBoxIDCoords:
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	sub e
	dec a
	ld c, a
	ld a, [hli]
	sub d
	dec a
	ld b, a
	ret

GetTextBoxIDText:
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push de
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	call GetAddressOfScreenCoords
	pop de
	ret

GetAddressOfScreenCoords:
	push bc
	hlcoord 0, 0
	ld bc, SCREEN_WIDTH
.loop
	ld a, d
	and a
	jr z, .addedRows
	add hl, bc
	dec d
	jr .loop
.addedRows
	pop bc
	add hl, de
	ret

INCLUDE "data/text_boxes.asm"

DisplayMoneyBox:
	ld hl, wStatusFlags5
	set BIT_NO_TEXT_DELAY, [hl]
	ld a, MONEY_BOX_TEMPLATE
	ld [wTextBoxID], a
	call DisplayTextBoxID
	hlcoord 13, 1
	lb bc, 1, 6
	call ClearScreenArea
IF DEF(_JAPAN) || DEF(_FRENCH) || DEF(_SPANISH)
	hlcoord 12, 1
	ld de, CurrencyString
	call PlaceString
	hlcoord 12, 1
	ld de, wPlayerMoney
	ld c, 3 | LEADING_ZEROES
ELSE
	hlcoord 12, 1
	ld de, wPlayerMoney
	ld c, 3 | LEADING_ZEROES | MONEY_SIGN
ENDC
	call PrintBCDNumber
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	ret

CurrencyString:
IF DEF(_JAPAN)
	db "　　　　　　円@"
ELSE
	db "      ¥@"
ENDC

DoBuySellQuitMenu:
	ld a, [wStatusFlags5]
	set BIT_NO_TEXT_DELAY, a
	ld [wStatusFlags5], a
	xor a
	ld [wChosenMenuItem], a
	ld a, BUY_SELL_QUIT_MENU_TEMPLATE
	ld [wTextBoxID], a
	call DisplayTextBoxID
	ld a, PAD_A | PAD_B
	ld [wMenuWatchedKeys], a
	ld a, $2
	ld [wMaxMenuItem], a
	ld a, $1
	ld [wTopMenuItemY], a
	ld a, $1
	ld [wTopMenuItemX], a
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld [wMenuWatchMovingOutOfBounds], a
	ld a, [wStatusFlags5]
	res BIT_NO_TEXT_DELAY, a
	ld [wStatusFlags5], a
	call HandleMenuInput
	call PlaceUnfilledArrowMenuCursor
	bit B_PAD_A, a
	jr nz, .pressedA
	bit B_PAD_B, a
	jr z, .pressedA
	ld a, CANCELLED_MENU
	ld [wMenuExitMethod], a
	jr .quit
.pressedA
	ld a, CHOSE_MENU_ITEM
	ld [wMenuExitMethod], a
	ld a, [wCurrentMenuItem]
	ld [wChosenMenuItem], a
	ld b, a
	ld a, [wMaxMenuItem]
	cp b
	jr z, .quit
	ret
.quit
	ld a, CANCELLED_MENU
	ld [wMenuExitMethod], a
	ld a, [wCurrentMenuItem]
	ld [wChosenMenuItem], a
	scf
	ret

DisplayTwoOptionMenu:
	push hl
	ld a, [wStatusFlags5]
	set BIT_NO_TEXT_DELAY, a
	ld [wStatusFlags5], a
	xor a
	ld [wChosenMenuItem], a
	ld [wMenuExitMethod], a
	ld a, PAD_A | PAD_B
	ld [wMenuWatchedKeys], a
	ld a, $1
	ld [wMaxMenuItem], a
	ld a, b
	ld [wTopMenuItemY], a
	ld a, c
	ld [wTopMenuItemX], a
	xor a
	ld [wLastMenuItem], a
	ld [wMenuWatchMovingOutOfBounds], a
	push hl
	ld hl, wTwoOptionMenuID
	bit BIT_SECOND_MENU_OPTION_DEFAULT, [hl]
	res BIT_SECOND_MENU_OPTION_DEFAULT, [hl]
	jr z, .storeCurrentMenuItem
	inc a
.storeCurrentMenuItem
	ld [wCurrentMenuItem], a
	pop hl
	push hl
	push hl
	call TwoOptionMenu_SaveScreenTiles
	ld a, [wTwoOptionMenuID]
	ld hl, TwoOptionMenuStrings
	ld e, a
	ld d, $0
	ld a, $5
.menuStringLoop
	add hl, de
	dec a
	jr nz, .menuStringLoop
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld e, l
	ld d, h
	pop hl
	push de
	ld a, [wTwoOptionMenuID]
	cp TRADE_CANCEL_MENU
	jr nz, .notTradeCancelMenu
	call CableClub_TextBoxBorder
	jr .afterTextBoxBorder
.notTradeCancelMenu
	call TextBoxBorder
.afterTextBoxBorder
	call UpdateSprites
	pop hl
	ld a, [hli]
	and a
	ld bc, SCREEN_WIDTH + 2
	jr z, .noBlankLine
	ld bc, 2 * SCREEN_WIDTH + 2
.noBlankLine
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	pop hl
	add hl, bc
	call PlaceString
	xor a
	ld [wTwoOptionMenuID], a
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	call HandleMenuInput
	pop hl
	bit B_PAD_B, a
	jr nz, .choseSecondMenuItem
	ld a, [wCurrentMenuItem]
	ld [wChosenMenuItem], a
	and a
	jr nz, .choseSecondMenuItem
	ld a, CHOSE_FIRST_ITEM
	ld [wMenuExitMethod], a
	ld c, 15
	call DelayFrames
	call TwoOptionMenu_RestoreScreenTiles
	and a
	ret
.choseSecondMenuItem
	ld a, 1
	ld [wCurrentMenuItem], a
	ld [wChosenMenuItem], a
	ld a, CHOSE_SECOND_ITEM
	ld [wMenuExitMethod], a
	ld c, 15
	call DelayFrames
	call TwoOptionMenu_RestoreScreenTiles
	scf
	ret

TwoOptionMenu_SaveScreenTiles:
	ld de, wBuffer
IF DEF(_GERMAN)
	lb bc, 5, 7
ELSE
	lb bc, 5, 6
ENDC
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	push bc
IF DEF(_GERMAN)
	ld bc, SCREEN_WIDTH - 7
ELSE
	ld bc, SCREEN_WIDTH - 6
ENDC
	add hl, bc
	pop bc
IF DEF(_GERMAN)
	ld c, 7
ELSE
	ld c, 6
ENDC
	dec b
	jr nz, .loop
	ret

TwoOptionMenu_RestoreScreenTiles:
	ld de, wBuffer
IF DEF(_GERMAN)
	lb bc, 5, 7
ELSE
	lb bc, 5, 6
ENDC
.loop
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .loop
	push bc
IF DEF(_GERMAN)
	ld bc, SCREEN_WIDTH - 7
ELSE
	ld bc, SCREEN_WIDTH - 6
ENDC
	add hl, bc
	pop bc
IF DEF(_GERMAN)
	ld c, 7
ELSE
	ld c, 6
ENDC
	dec b
	jr nz, .loop
	call UpdateSprites
	ret

INCLUDE "data/yes_no_menu_strings.asm"

DisplayFieldMoveMonMenu:
	xor a
	ld hl, wFieldMoves
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
IF !DEF(_JAPAN)
	ld [hl], 12 ; wFieldMovesLeftmostXCoord
ENDC
	call GetMonFieldMoves
	ld a, [wNumFieldMoves]
	and a
	jr nz, .fieldMovesExist
	hlcoord 11, 11
	lb bc, 5, 7
	call TextBoxBorder
	call UpdateSprites
IF DEF(_JAPAN)
	jr .printMonMenuEntries
ELSE
	ld a, 12
	ldh [hFieldMoveMonMenuTopMenuItemX], a
	hlcoord 13, 12
	ld de, PokemonMenuEntries
	jp PlaceString
ENDC

.fieldMovesExist
IF DEF(_JAPAN)
	hlcoord 11, 11
	lb bc, 5, 7
	ld de, -SCREEN_WIDTH * 2
ELSE
	push af
	hlcoord 0, 11
	ld a, [wFieldMovesLeftmostXCoord]
	dec a
	ld e, a
	ld d, 0
	add hl, de
	ld b, 5
	ld a, 18
	sub e
	ld c, a
	pop af
	ld de, -SCREEN_WIDTH * 2
ENDC
.textBoxHeightLoop
	add hl, de
	inc b
	inc b
	dec a
	jr nz, .textBoxHeightLoop
	ld de, -SCREEN_WIDTH
	add hl, de
	inc b
	call TextBoxBorder
	call UpdateSprites
IF DEF(_JAPAN)
	hlcoord 13, 12
ELSE
	hlcoord 0, 12
	ld a, [wFieldMovesLeftmostXCoord]
	inc a
	ld e, a
	ld d, 0
	add hl, de
ENDC
	ld de, -SCREEN_WIDTH * 2
	ld a, [wNumFieldMoves]
.calcFirstFieldMoveYLoop
	add hl, de
	dec a
	jr nz, .calcFirstFieldMoveYLoop
	xor a
	ld [wNumFieldMoves], a
	ld de, wFieldMoves
.printNamesLoop
	push hl
	ld hl, FieldMoveNames
	ld a, [de]
	and a
	jr z, .donePrintingNames
	inc de
	ld b, a
.skipNamesLoop
	dec b
	jr z, .reachedName
.skipNameLoop
	ld a, [hli]
	cp '@'
	jr nz, .skipNameLoop
	jr .skipNamesLoop
.reachedName
	ld b, h
	ld c, l
	pop hl
	push de
	ld d, b
	ld e, c
	call PlaceString
	ld bc, SCREEN_WIDTH * 2
	add hl, bc
	pop de
	jr .printNamesLoop
.donePrintingNames
	pop hl
IF DEF(_JAPAN)
.printMonMenuEntries
	hlcoord 13, 12
	ld de, PokemonMenuEntries
	jp PlaceString
ELSE
	ld a, [wFieldMovesLeftmostXCoord]
	ldh [hFieldMoveMonMenuTopMenuItemX], a
	hlcoord 0, 12
	ld a, [wFieldMovesLeftmostXCoord]
	inc a
	ld e, a
	ld d, 0
	add hl, de
	ld de, PokemonMenuEntries
	jp PlaceString
ENDC

INCLUDE "data/moves/field_move_names.asm"

PokemonMenuEntries:
IF DEF(_JAPAN)
	db   "つよさをみる"
	next "ならびかえ"
	next "キャンセル@"
ELIF DEF(_FRENCH)
	db   "STATS"
	next "ORDRE"
	next "RETOUR@"
ELIF DEF(_GERMAN)
	db   "STATUS"
	next "TAUSCH"
	next "ZURÜCK@"
ELIF DEF(_ITALIAN)
	db   "STAT."
	next "ORDINA"
	next "ESCI@"
ELIF DEF(_SPANISH)
	db   "ESTAD."
	next "CAMBIO"
	next "SALIR@"
ELSE
	db   "STATS"
	next "SWITCH"
	next "CANCEL@"
ENDC

GetMonFieldMoves:
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Moves
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	ld d, h
	ld e, l
	ld c, NUM_MOVES + 1
	ld hl, wFieldMoves
.loop
	push hl
.nextMove
	dec c
	jr z, .done
	ld a, [de]
	and a
	jr z, .done
	ld b, a
	inc de
	ld hl, FieldMoveDisplayData
.fieldMoveLoop
	ld a, [hli]
	cp $ff
	jr z, .nextMove
	cp b
	jr z, .foundFieldMove
	inc hl
IF !DEF(_JAPAN)
	inc hl
ENDC
	jr .fieldMoveLoop
.foundFieldMove
IF DEF(_JAPAN)
	ld a, [hl]
	pop hl
	ld [hli], a
	ld a, [wNumFieldMoves]
	inc a
	ld [wNumFieldMoves], a
	jr .loop
ELSE
	ld a, b
	ld [wLastFieldMoveID], a
	ld a, [hli]
	ld b, [hl]
	pop hl
	ld [hli], a
	ld a, [wNumFieldMoves]
	inc a
	ld [wNumFieldMoves], a
	ld a, [wFieldMovesLeftmostXCoord]
	cp b
	jr c, .skipUpdatingLeftmostXCoord
	ld a, b
	ld [wFieldMovesLeftmostXCoord], a
.skipUpdatingLeftmostXCoord
	ld a, [wLastFieldMoveID]
	ld b, a
	jr .loop
ENDC
.done
	pop hl
	ret

INCLUDE "data/moves/field_moves.asm"
