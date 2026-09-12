; function that displays the start menu
DrawStartMenu::
	CheckEvent EVENT_GOT_POKEDEX
; menu with pokedex
IF DEF(_JAPAN)
	hlcoord 12, 0
	lb bc, 14, 6
ELSE
	hlcoord 10, 0
	lb bc, 14, 8
ENDC
	jr nz, .drawTextBoxBorder
; shorter menu if the player doesn't have the pokedex
IF DEF(_JAPAN)
	hlcoord 12, 0
	lb bc, 12, 6
ELSE
	hlcoord 10, 0
	lb bc, 12, 8
ENDC
.drawTextBoxBorder
	call TextBoxBorder
	ld a, PAD_DOWN | PAD_UP | PAD_START | PAD_B | PAD_A
	ld [wMenuWatchedKeys], a
	ld a, $02
	ld [wTopMenuItemY], a
IF DEF(_JAPAN)
	ld a, $0d
ELSE
	ld a, $0b
ENDC
	ld [wTopMenuItemX], a
	ld a, [wBattleAndStartSavedMenuItem]
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	xor a
	ld [wMenuWatchMovingOutOfBounds], a
	ld hl, wStatusFlags5
	set BIT_NO_TEXT_DELAY, [hl]
IF DEF(_JAPAN)
	hlcoord 14, 2
ELSE
	hlcoord 12, 2
ENDC
	CheckEvent EVENT_GOT_POKEDEX
	ld a, $06
	jr z, .storeMenuItemCount
	ld de, StartMenuPokedexText
	call PrintStartMenuItem
	ld a, $07
.storeMenuItemCount
	ld [wMaxMenuItem], a
	ld de, StartMenuPokemonText
	call PrintStartMenuItem
	ld de, StartMenuItemText
	call PrintStartMenuItem
	ld de, wPlayerName
	call PrintStartMenuItem
	ld a, [wStatusFlags4]
	bit BIT_LINK_CONNECTED, a
	ld de, StartMenuSaveText
	jr z, .printSaveOrResetText
	ld de, StartMenuResetText
.printSaveOrResetText
	call PrintStartMenuItem
	ld de, StartMenuOptionText
	call PrintStartMenuItem
	ld de, StartMenuExitText
	call PlaceString
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	ret

StartMenuPokedexText:
IF DEF(_JAPAN)
	db "ずかん@"
ELIF DEF(_FRENCH)
	db "#DEX@"
ELIF DEF(_GERMAN)
	db "#DEX@"
ELIF DEF(_ITALIAN)
	db "#DEX@"
ELIF DEF(_SPANISH)
	db "#DEX@"
ELSE
	db "POKéDEX@"
ENDC

StartMenuPokemonText:
IF DEF(_JAPAN)
	db "#@"
ELSE
	db "#MON@"
ENDC

StartMenuItemText:
IF DEF(_JAPAN)
	db "どうぐ@"
ELIF DEF(_FRENCH)
	db "OBJET@"
ELIF DEF(_GERMAN)
	db "ITEM@"
ELIF DEF(_ITALIAN)
	db "STRUM.@"
ELIF DEF(_SPANISH)
	db "OBJETOS@"
ELSE
	db "ITEM@"
ENDC

StartMenuSaveText:
IF DEF(_JAPAN)
	db "レポート@"
ELIF DEF(_FRENCH)
	db "SAUVER@"
ELIF DEF(_GERMAN)
	db "SICHERN@"
ELIF DEF(_ITALIAN)
	db "SALVA@"
ELIF DEF(_SPANISH)
	db "GUARDAR@"
ELSE
	db "SAVE@"
ENDC

StartMenuResetText:
IF DEF(_JAPAN)
	db "リセット@"
ELIF DEF(_FRENCH)
	db "QUITTER@"
ELSE
	db "RESET@"
ENDC

StartMenuExitText:
IF DEF(_JAPAN)
	db "とじる@"
ELIF DEF(_FRENCH)
	db "RETOUR@"
ELIF DEF(_GERMAN)
	db "ZURÜCK@"
ELIF DEF(_ITALIAN)
	db "ESCI@"
ELIF DEF(_SPANISH)
	db "SALIR@"
ELSE
	db "EXIT@"
ENDC

StartMenuOptionText:
IF DEF(_JAPAN)
	db "せってい@"
ELIF DEF(_ITALIAN)
	db "OPZIONI@"
ELIF DEF(_SPANISH)
	db "OPCI", $cc, "N@" ; Ó = $cc in the Spanish Gen I charmap
ELSE
	db "OPTION@"
ENDC

PrintStartMenuItem:
	push hl
	call PlaceString
	pop hl
	ld de, SCREEN_WIDTH * 2
	add hl, de
	ret
