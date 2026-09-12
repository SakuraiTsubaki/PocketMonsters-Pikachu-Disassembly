FieldMoveDisplayData:
IF DEF(_JAPAN)
; move id, FieldMoveNames index
	db CUT,        1
	db FLY,        2
	db ANIM_B4,    3 ; unused
	db SURF,       4
	db STRENGTH,   5
	db FLASH,      6
	db DIG,        7
	db TELEPORT,   8
	db SOFTBOILED, 9
ELSE
; move id, FieldMoveNames index, leftmost tile
; (leftmost tile = -1 + tile column in which the first
;  letter of the move's name should be displayed)
IF DEF(_GERMAN)
	db CUT,        1, $06
	db FLY,        2, $0B
	db ANIM_B4,    3, $0C ; unused
	db SURF,       4, $0C
	db STRENGTH,   5, $0C
	db FLASH,      6, $0C
	db DIG,        7, $09
	db TELEPORT,   8, $0A
	db SOFTBOILED, 9, $0B
ELIF DEF(_FRENCH)
	db CUT,        1, $0C
	db FLY,        2, $0C
	db ANIM_B4,    3, $0C ; unused
	db SURF,       4, $0C
	db STRENGTH,   5, $0C
	db FLASH,      6, $0C
	db DIG,        7, $0C
	db TELEPORT,   8, $0A
	db SOFTBOILED, 9, $0B
ELIF DEF(_ITALIAN)
; Directly verified from the Italian reference ROM at Bank 01 $76BE.
	db CUT,        1, $0C
	db FLY,        2, $0C
	db ANIM_B4,    3, $0C ; unused
	db SURF,       4, $0C
	db STRENGTH,   5, $0C
	db FLASH,      6, $0C
	db DIG,        7, $0C
	db TELEPORT,   8, $06
	db SOFTBOILED, 9, $09
ELIF DEF(_SPANISH)
; Directly verified from the Spanish reference ROM at Bank 01 $76F9.
	db CUT,        1, $0C
	db FLY,        2, $0C
	db ANIM_B4,    3, $0C ; unused
	db SURF,       4, $0C
	db STRENGTH,   5, $0C
	db FLASH,      6, $0A
	db DIG,        7, $0B
	db TELEPORT,   8, $07
	db SOFTBOILED, 9, $06
ELSE
	db CUT,        1, $0C
	db FLY,        2, $0C
	db ANIM_B4,    3, $0C ; unused
	db SURF,       4, $0C
	db STRENGTH,   5, $0A
	db FLASH,      6, $0C
	db DIG,        7, $0C
	db TELEPORT,   8, $0A
	db SOFTBOILED, 9, $08
ENDC
ENDC
	db -1 ; end
