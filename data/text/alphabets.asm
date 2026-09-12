IF DEF(_FRENCH)
	INCLUDE "data/text/alphabets/fr.asm"
ELIF DEF(_GERMAN)
	INCLUDE "data/text/alphabets/de.asm"
ELIF DEF(_ITALIAN)
	INCLUDE "data/text/alphabets/it.asm"
ELIF DEF(_SPANISH)
	INCLUDE "data/text/alphabets/es.asm"
ELSE
	INCLUDE "data/text/alphabets/en.asm"
ENDC
