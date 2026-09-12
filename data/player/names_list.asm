; Locale-aware fixed-width Oak intro default-name lookup lists.
; See constants/player_constants.asm.

DefaultNamesPlayerList:
IF DEF(_JAPAN)
	db "じぶんできめる@"
	list_start NAME_LENGTH - 1
ELIF DEF(_FRENCH)
	db "NOM:@"
	list_start PLAYER_NAME_LENGTH - 1
ELIF DEF(_GERMAN)
	db "NAME@"
	list_start PLAYER_NAME_LENGTH - 1
ELIF DEF(_ITALIAN)
	db "NUOVO@"
	list_start PLAYER_NAME_LENGTH - 1
ELIF DEF(_SPANISH)
	db "NUEVO N.@"
	list_start PLAYER_NAME_LENGTH - 1
ELSE
	db "NEW NAME@"
	list_start PLAYER_NAME_LENGTH - 1
ENDC
FOR n, 1, NUM_PLAYER_NAMES + 1
	li #PLAYERNAME{d:n}
ENDR
	assert_list_length NUM_PLAYER_NAMES

DefaultNamesRivalList:
IF DEF(_JAPAN)
	db "じぶんできめる@"
	list_start NAME_LENGTH - 1
ELIF DEF(_FRENCH)
	db "NOM:@"
	list_start PLAYER_NAME_LENGTH - 1
ELIF DEF(_GERMAN)
	db "NAME@"
	list_start PLAYER_NAME_LENGTH - 1
ELIF DEF(_ITALIAN)
	db "NUOVO@"
	list_start PLAYER_NAME_LENGTH - 1
ELIF DEF(_SPANISH)
	db "NUEVO N.@"
	list_start PLAYER_NAME_LENGTH - 1
ELSE
	db "NEW NAME@"
	list_start PLAYER_NAME_LENGTH - 1
ENDC
FOR n, 1, NUM_PLAYER_NAMES + 1
	li #RIVALNAME{d:n}
ENDR
	assert_list_length NUM_PLAYER_NAMES
