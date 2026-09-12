ItemNames::
	list_start ITEM_NAME_LENGTH - 1

IF DEF(_JAPAN)
	INCLUDE "data/items/names/jp.asm"
ELIF DEF(_FRENCH)
	INCLUDE "data/items/names/fr.asm"
ELIF DEF(_GERMAN)
	INCLUDE "data/items/names/de.asm"
ELIF DEF(_ITALIAN)
	INCLUDE "data/items/names/it.asm"
ELIF DEF(_SPANISH)
	INCLUDE "data/items/names/es.asm"
ELSE
	INCLUDE "data/items/names/en.asm"
ENDC
