; Locale-aware Oak intro name menu data.
; See constants/player_constants.asm.

DefaultNamesPlayer:
IF DEF(_JAPAN)
	db "じぶんできめる"
ELIF DEF(_FRENCH)
	db "NOM:"
ELIF DEF(_GERMAN)
	db "NAME"
ELIF DEF(_ITALIAN)
	db "NUOVO"
ELIF DEF(_SPANISH)
	db "NUEVO N."
ELSE
	db "NEW NAME"
ENDC
FOR n, 1, NUM_PLAYER_NAMES + 1
	next #PLAYERNAME{d:n}
ENDR
	db "@"

DefaultNamesRival:
IF DEF(_JAPAN)
	db "じぶんできめる"
ELIF DEF(_FRENCH)
	db "NOM:"
ELIF DEF(_GERMAN)
	db "NAME"
ELIF DEF(_ITALIAN)
	db "NUOVO"
ELIF DEF(_SPANISH)
	db "NUEVO N."
ELSE
	db "NEW NAME"
ENDC
FOR n, 1, NUM_PLAYER_NAMES + 1
	next #RIVALNAME{d:n}
ENDR
	db "@"
