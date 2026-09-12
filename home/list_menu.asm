; List-menu engine shared by all Yellow releases.
; Locale differences are kept narrow: Japanese menu geometry/digits, currency
; rendering family, and the localized Cancel entry.

; INPUT:
; [wListMenuID] = list menu ID
; [wListPointer] = address of the list (2 bytes)
DisplayListMenuID::
	xor a
	ldh [hAutoBGTransferEnabled], a
	ld a, 1
	ldh [hJoy7], a
	ld a, [wBattleType]
	and a
	jr nz, .specialBattleType
	ld a, $01
	jr .bankswitch
.specialBattleType
	ld a, BANK(DisplayBattleMenu)
.bankswitch
	call BankswitchHome
	ld hl, wStatusFlags5
	set BIT_NO_TEXT_DELAY, [hl]
	xor a
	ld [wMenuItemToSwap], a
	ld [wListCount], a
	ld a, [wListPointer]
	ld l, a
	ld a, [wListPointer + 1]
	ld h, a
	ld a, [hl]
	ld [wListCount], a
	ld a, LIST_MENU_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	call UpdateSprites
	hlcoord 4, 2
	lb de, 9, 14
	ld a, [wListMenuID]
	and a
	jr nz, .skipMovingSprites
	call UpdateSprites
.skipMovingSprites
	ld a, 1
	ld [wMenuWatchMovingOutOfBounds], a
	ld a, [wListCount]
	cp 2
	jr c, .setMenuVariables
	ld a, 2
.setMenuVariables
	ld [wMaxMenuItem], a
	ld a, 4
	ld [wTopMenuItemY], a
	ld a, 5
	ld [wTopMenuItemX], a
	ld a, PAD_A | PAD_B | PAD_SELECT
	ld [wMenuWatchedKeys], a
	ld c, 10
	call DelayFrames

DisplayListMenuIDLoop::
	xor a
	ldh [hAutoBGTransferEnabled], a
	call PrintListMenuEntries
	ld a, 1
	ldh [hAutoBGTransferEnabled], a
	call Delay3
	ld a, [wBattleType]
	and a
	jr z, .notOldManBattle
	ld a, '▶'
	ldcoord_a 5, 4
	ld c, 20
	call DelayFrames
	xor a
	ld [wCurrentMenuItem], a
	hlcoord 5, 4
	ld a, l
	ld [wMenuCursorLocation], a
	ld a, h
	ld [wMenuCursorLocation + 1], a
	jr .buttonAPressed
.notOldManBattle
	call LoadGBPal
	call HandleMenuInput
	push af
	call PlaceMenuCursor
	pop af
	bit B_PAD_A, a
	jp z, .checkOtherKeys
.buttonAPressed
	ld a, [wCurrentMenuItem]
	call PlaceUnfilledArrowMenuCursor
	ld a, $01
	ld [wMenuExitMethod], a
	ld [wChosenMenuItem], a
	xor a
	ld [wMenuWatchMovingOutOfBounds], a
	ld a, [wCurrentMenuItem]
	ld c, a
	ld a, [wListScrollOffset]
	add c
	ld c, a
	ld a, [wListCount]
	and a
	jp z, ExitListMenu
	dec a
	cp c
	jp c, ExitListMenu
	ld a, c
	ld [wWhichPokemon], a
	ld a, [wListMenuID]
	cp ITEMLISTMENU
	jr nz, .skipMultiplying
	sla c
.skipMultiplying
	ld a, [wListPointer]
	ld l, a
	ld a, [wListPointer + 1]
	ld h, a
	inc hl
	ld b, 0
	add hl, bc
	ld a, [hl]
	ld [wCurListMenuItem], a
	ld a, [wListMenuID]
	and a
	jr z, .pokemonList
	ASSERT wCurListMenuItem == wCurItem
	push hl
	call GetItemPrice
	pop hl
	ld a, [wListMenuID]
	cp ITEMLISTMENU
	jr nz, .skipGettingQuantity
	inc hl
	ld a, [hl]
	ld [wMaxItemQuantity], a
.skipGettingQuantity
	ld a, [wCurItem]
	ld [wNameListIndex], a
	ld a, BANK(ItemNames)
	ld [wPredefBank], a
	call GetName
	jr .storeChosenEntry
.pokemonList
	ASSERT wCurListMenuItem == wCurPartySpecies
	ld hl, wPartyCount
	ld a, [wListPointer]
	cp l
	ld hl, wPartyMonNicks
	jr z, .getPokemonName
	ld hl, wBoxMonNicks
.getPokemonName
	ld a, [wWhichPokemon]
	call GetPartyMonName
.storeChosenEntry
	ld de, wNameBuffer
	call CopyToStringBuffer
	ld a, CHOSE_MENU_ITEM
	ld [wMenuExitMethod], a
	ld a, [wCurrentMenuItem]
	ld [wChosenMenuItem], a
	xor a
	ldh [hJoy7], a
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	jp BankswitchBack
.checkOtherKeys
	bit B_PAD_B, a
	jp nz, ExitListMenu
	bit B_PAD_SELECT, a
	jp nz, HandleItemListSwapping
	ld b, a
	bit B_PAD_DOWN, b
	ld hl, wListScrollOffset
	jr z, .upPressed
	ld a, [hl]
	add 3
	ld b, a
	ld a, [wListCount]
	cp b
	jp c, DisplayListMenuIDLoop
	inc [hl]
	jp DisplayListMenuIDLoop
.upPressed
	ld a, [hl]
	and a
	jp z, DisplayListMenuIDLoop
	dec [hl]
	jp DisplayListMenuIDLoop

DisplayChooseQuantityMenu::
	hlcoord 15, 9
	lb bc, 1, 3
	ld a, [wListMenuID]
	cp PRICEDITEMLISTMENU
	jr nz, .drawTextBox
	hlcoord 7, 9
	lb bc, 1, 11
.drawTextBox
	call TextBoxBorder
	hlcoord 16, 10
	ld a, [wListMenuID]
	cp PRICEDITEMLISTMENU
	jr nz, .printInitialQuantity
IF DEF(_JAPAN)
	ld a, '円'
	ldcoord_a 18, 10
ELIF DEF(_FRENCH) || DEF(_SPANISH)
	; French and Spanish use the currency glyph as a separately placed tile.
	ld a, '¥'
	ldcoord_a 18, 10
ENDC
	hlcoord 8, 10
.printInitialQuantity
	ld de, InitialQuantityText
	call PlaceString
	xor a
	ld [wItemQuantity], a
	jp .incrementQuantity
.waitForKeyPressLoop
	call JoypadLowSensitivity
	ldh a, [hJoyPressed]
	bit B_PAD_A, a
	jp nz, .buttonAPressed
	bit B_PAD_B, a
	jp nz, .buttonBPressed
	bit B_PAD_UP, a
	jr nz, .incrementQuantity
	bit B_PAD_DOWN, a
	jr nz, .decrementQuantity
	jr .waitForKeyPressLoop
.incrementQuantity
	ld a, [wMaxItemQuantity]
	inc a
	ld b, a
	ld hl, wItemQuantity
	inc [hl]
	ld a, [hl]
	cp b
	jr nz, .handleNewQuantity
	ld a, 1
	ld [hl], a
	jr .handleNewQuantity
.decrementQuantity
	ld hl, wItemQuantity
	dec [hl]
	jr nz, .handleNewQuantity
	ld a, [wMaxItemQuantity]
	ld [hl], a
.handleNewQuantity
	hlcoord 17, 10
	ld a, [wListMenuID]
	cp PRICEDITEMLISTMENU
	jr nz, .printQuantity
.printPrice
	ld c, $03
	ld a, [wItemQuantity]
	ld b, a
	ld hl, hMoney
	xor a
	ld [hli], a
	ld [hli], a
	ld [hl], a
.addLoop
	ld de, hMoney + 2
	ld hl, hItemPrice + 2
	push bc
	predef AddBCDPredef
	pop bc
	dec b
	jr nz, .addLoop
	ldh a, [hHalveItemPrices]
	and a
	jr z, .skipHalvingPrice
	xor a
	ldh [hDivideBCDDivisor], a
	ldh [hDivideBCDDivisor + 1], a
	ld a, $02
	ldh [hDivideBCDDivisor + 2], a
	predef DivideBCDPredef3
	ldh a, [hDivideBCDQuotient]
	ldh [hMoney], a
	ldh a, [hDivideBCDQuotient + 1]
	ldh [hMoney + 1], a
	ldh a, [hDivideBCDQuotient + 2]
	ldh [hMoney + 2], a
.skipHalvingPrice
	hlcoord 12, 10
	ld de, SpacesBetweenQuantityAndPriceText
	call PlaceString
	ld de, hMoney
IF DEF(_JAPAN) || DEF(_FRENCH) || DEF(_SPANISH)
	ld c, 3 | LEADING_ZEROES
ELSE
	ld c, 3 | LEADING_ZEROES | MONEY_SIGN
ENDC
	call PrintBCDNumber
	hlcoord 9, 10
.printQuantity
	ld de, wItemQuantity
	lb bc, LEADING_ZEROES | 1, 2
	call PrintNumber
	jp .waitForKeyPressLoop
.buttonAPressed
	xor a
	ld [wMenuItemToSwap], a
	ret
.buttonBPressed
	xor a
	ld [wMenuItemToSwap], a
	ld a, $ff
	ret

InitialQuantityText::
IF DEF(_JAPAN)
	db "×０１@"
ELSE
	db "×01@"
ENDC

SpacesBetweenQuantityAndPriceText::
IF DEF(_JAPAN)
	db "　　　　　　@"
ELSE
	db "      @"
ENDC

ExitListMenu::
	ld a, [wCurrentMenuItem]
	ld [wChosenMenuItem], a
	ld a, CANCELLED_MENU
	ld [wMenuExitMethod], a
	ld [wMenuWatchMovingOutOfBounds], a
	xor a
	ldh [hJoy7], a
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	call BankswitchBack
	xor a
	ld [wMenuItemToSwap], a
	scf
	ret

PrintListMenuEntries::
	hlcoord 5, 3
	lb bc, 9, 14
	call ClearScreenArea
	ld a, [wListPointer]
	ld e, a
	ld a, [wListPointer + 1]
	ld d, a
	inc de
	ld a, [wListScrollOffset]
	ld c, a
	ld a, [wListMenuID]
	cp ITEMLISTMENU
	ld a, c
	jr nz, .skipMultiplying
	add a
	sla c
.skipMultiplying
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	hlcoord 6, 4
	ld b, 4
.loop
	ld a, b
	ld [wWhichPokemon], a
	ld a, [de]
	ld [wNamedObjectIndex], a
	cp $ff
	jp z, .printCancelMenuItem
	push bc
	push de
	push hl
	push hl
	push de
	ld a, [wListMenuID]
	and a
	jr z, .pokemonPCMenu
	cp MOVESLISTMENU
	jr z, .movesMenu
	call GetItemName
	jr .placeNameString
.pokemonPCMenu
	push hl
	ld hl, wPartyCount
	ld a, [wListPointer]
	cp l
	ld hl, wPartyMonNicks
	jr z, .getPokemonName
	ld hl, wBoxMonNicks
.getPokemonName
	ld a, [wWhichPokemon]
	ld b, a
	ld a, 4
	sub b
	ld b, a
	ld a, [wListScrollOffset]
	add b
	call GetPartyMonName
	pop hl
	jr .placeNameString
.movesMenu
	call GetMoveName
.placeNameString
	call PlaceString
	pop de
	pop hl
	ld a, [wPrintItemPrices]
	and a
	jr z, .skipPrintingItemPrice
	push hl
	ld a, [de]
	ld de, ItemPrices
	ld [wCurItem], a
	call GetItemPrice
	pop hl
IF DEF(_JAPAN)
	ld bc, 6
ELSE
	ld bc, SCREEN_WIDTH + 5
ENDC
	add hl, bc
IF DEF(_JAPAN) || DEF(_FRENCH) || DEF(_SPANISH)
	ld c, 3 | LEADING_ZEROES
	call PrintBCDNumber
IF DEF(_JAPAN)
	ld [hl], '円'
ELSE
	ld [hl], '¥'
ENDC
ELSE
	ld c, 3 | LEADING_ZEROES | MONEY_SIGN
	call PrintBCDNumber
ENDC
.skipPrintingItemPrice
	ld a, [wListMenuID]
	and a
	jr nz, .skipPrintingPokemonLevel
	ld a, [wNamedObjectIndex]
	push af
	push hl
	ld hl, wPartyCount
	ld a, [wListPointer]
	cp l
	ld a, PLAYER_PARTY_DATA
	jr z, .next
	ld a, BOX_DATA
.next
	ld [wMonDataLocation], a
	ld hl, wWhichPokemon
	ld a, [hl]
	ld b, a
	ld a, $04
	sub b
	ld b, a
	ld a, [wListScrollOffset]
	add b
	ld [hl], a
	call LoadMonData
	ld a, [wMonDataLocation]
	and a
	jr z, .skipCopyingLevel
	ld a, [wLoadedMonBoxLevel]
	ld [wLoadedMonLevel], a
.skipCopyingLevel
	pop hl
IF DEF(_JAPAN)
	ld bc, 6
ELSE
	ld bc, SCREEN_WIDTH + 8
ENDC
	add hl, bc
	call PrintLevel
	pop af
	ld [wNamedObjectIndex], a
.skipPrintingPokemonLevel
	pop hl
	pop de
	inc de
	ld a, [wListMenuID]
	cp ITEMLISTMENU
	jr nz, .nextListEntry
	ld a, [wNamedObjectIndex]
	ld [wCurItem], a
	call IsKeyItem
	ld a, [wIsKeyItem]
	and a
	jr nz, .skipPrintingItemQuantity
	push hl
IF DEF(_JAPAN)
	ld bc, 9
ELSE
	ld bc, SCREEN_WIDTH + 8
ENDC
	add hl, bc
	ld a, '×'
	ld [hli], a
	ld a, [wNamedObjectIndex]
	push af
	ld a, [de]
	ld [wMaxItemQuantity], a
	push de
	ld de, wTempByteValue
	ld [de], a
	lb bc, 1, 2
	call PrintNumber
	pop de
	pop af
	ld [wNamedObjectIndex], a
	pop hl
.skipPrintingItemQuantity
	inc de
	pop bc
	inc c
	push bc
	inc c
	ld a, [wMenuItemToSwap]
	and a
	jr z, .nextListEntry
	add a
	cp c
	jr nz, .nextListEntry
	dec hl
	ld a, '▷'
	ld [hli], a
.nextListEntry
	ld bc, 2 * SCREEN_WIDTH
	add hl, bc
	pop bc
	inc c
	dec b
	jp nz, .loop
	ld bc, -8
	add hl, bc
	ld a, '▼'
	ld [hl], a
	ret
.printCancelMenuItem
	ld de, ListMenuCancelText
	jp PlaceString

IF DEF(_JAPAN)
ListMenuCancelText:: db "やめる@"
ELIF DEF(_FRENCH)
ListMenuCancelText:: db "RETOUR@"
ELIF DEF(_GERMAN)
ListMenuCancelText:: db "ZURÜCK@"
ELIF DEF(_ITALIAN)
; Directly verified from the Italian reference ROM.
ListMenuCancelText:: db "ESCI@"
ELIF DEF(_SPANISH)
; Directly verified from the Spanish reference ROM.
ListMenuCancelText:: db "SALIR@"
ELSE
ListMenuCancelText:: db "CANCEL@"
ENDC
