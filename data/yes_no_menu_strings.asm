MACRO two_option_menu
	db \1, \2, \3
	dw \4
ENDM

TwoOptionMenuStrings:
; entries correspond to *_MENU constants
	table_width 5
	; width, height, blank line before first menu item?, text pointer
IF DEF(_JAPAN)
	two_option_menu 4, 3, FALSE, .YesNoMenu
	two_option_menu 4, 3, FALSE, .NorthWestMenu
	two_option_menu 4, 3, FALSE, .SouthEastMenu
	two_option_menu 6, 3, FALSE, .YesNoMenu
	two_option_menu 4, 3, FALSE, .NorthEastMenu
	two_option_menu 5, 3, FALSE, .TradeCancelMenu
	two_option_menu 5, 4, TRUE,  .HealCancelMenu
	two_option_menu 4, 3, FALSE, .NoYesMenu
ELIF DEF(_FRENCH)
	two_option_menu 4, 3, FALSE, .YesNoMenu
	two_option_menu 6, 3, FALSE, .NorthWestMenu
	two_option_menu 6, 3, FALSE, .SouthEastMenu
	two_option_menu 6, 3, FALSE, .YesNoMenu
	two_option_menu 6, 3, FALSE, .NorthEastMenu
	two_option_menu 8, 3, FALSE, .TradeCancelMenu
	two_option_menu 7, 4, TRUE,  .HealCancelMenu
	two_option_menu 4, 3, FALSE, .NoYesMenu
ELIF DEF(_GERMAN)
	two_option_menu 5, 3, FALSE, .YesNoMenu
	two_option_menu 6, 3, FALSE, .NorthWestMenu
	two_option_menu 6, 3, FALSE, .SouthEastMenu
	two_option_menu 6, 3, FALSE, .YesNoMenu
	two_option_menu 6, 3, FALSE, .NorthEastMenu
	two_option_menu 7, 3, FALSE, .TradeCancelMenu
	two_option_menu 7, 4, TRUE,  .HealCancelMenu
	two_option_menu 5, 3, FALSE, .NoYesMenu
ELSE
; EN, IT and ES share the same geometry.
	two_option_menu 4, 3, FALSE, .YesNoMenu
	two_option_menu 6, 3, FALSE, .NorthWestMenu
	two_option_menu 6, 3, FALSE, .SouthEastMenu
	two_option_menu 6, 3, FALSE, .YesNoMenu
	two_option_menu 6, 3, FALSE, .NorthEastMenu
	two_option_menu 7, 3, FALSE, .TradeCancelMenu
	two_option_menu 7, 4, TRUE,  .HealCancelMenu
	two_option_menu 4, 3, FALSE, .NoYesMenu
ENDC
	assert_table_length NUM_TWO_OPTION_MENUS

IF DEF(_FRENCH) || DEF(_GERMAN) || DEF(_ITALIAN) || DEF(_SPANISH)
; The localized European ROMs place the direction strings before yes/no.
.NorthWestMenu:
	db   "NORTH"
	next "WEST@"

.SouthEastMenu:
	db   "SOUTH"
	next "EAST@"

.NorthEastMenu:
	db   "NORTH"
	next "EAST@"

IF DEF(_FRENCH)
.NoYesMenu:
	db   "NON"
	next "OUI@"
.YesNoMenu:
	db   "OUI"
	next "NON@"
.TradeCancelMenu:
	db   "ECHANGE"
	next "RETOUR@"
.HealCancelMenu:
	db   "SOIN"
	next "RETOUR@"
ELIF DEF(_GERMAN)
.NoYesMenu:
	db   "NEIN"
	next "JA@"
.YesNoMenu:
	db   "JA"
	next "NEIN@"
.TradeCancelMenu:
	db   "TAUSCH"
	next "ZURÜCK@"
.HealCancelMenu:
	db   "HEILEN"
	next "ZURÜCK@"
ELIF DEF(_ITALIAN)
.NoYesMenu:
	db   "NO"
	next "SÌ@"
.YesNoMenu:
	db   "SÌ"
	next "NO@"
.TradeCancelMenu:
	db   "OK"
	next "ESCI@"
.HealCancelMenu:
	db   "CURA"
	next "ESCI@"
ELSE ; _SPANISH
.NoYesMenu:
	db   "NO"
	next "SÍ@"
.YesNoMenu:
	db   "SÍ"
	next "NO@"
.TradeCancelMenu:
	db   "TRATO"
	next "SALIR@"
.HealCancelMenu:
	db   "CURAR"
	next "SALIR@"
ENDC
ELSE
; EN and JP preserve the original no/yes-first string ordering.
IF DEF(_JAPAN)
.NoYesMenu:
	db   "いいえ"
	next "はい@"
.YesNoMenu:
	db   "はい"
	next "いいえ@"
.NorthWestMenu:
	db   "きた"
	next "にし@"
.SouthEastMenu:
	db   "みなみ"
	next "ひがし@"
.NorthEastMenu:
	db   "きた"
	next "ひがし@"
.TradeCancelMenu:
	db   "こうかん"
	next "やめる@"
.HealCancelMenu:
	db   "あずける"
	next "やめる@"
ELSE
.NoYesMenu:
	db   "NO"
	next "YES@"
.YesNoMenu:
	db   "YES"
	next "NO@"
.NorthWestMenu:
	db   "NORTH"
	next "WEST@"
.SouthEastMenu:
	db   "SOUTH"
	next "EAST@"
.NorthEastMenu:
	db   "NORTH"
	next "EAST@"
.TradeCancelMenu:
	db   "TRADE"
	next "CANCEL@"
.HealCancelMenu:
	db   "HEAL"
	next "CANCEL@"
ENDC
ENDC
