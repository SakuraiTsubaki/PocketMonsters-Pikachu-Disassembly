; Bank 00 fixed text-engine literals.
; Literal order is release-sensitive and is preserved exactly per family/locale.
; Raw-byte expectations are documented in config/text_locale_matrix.json.

IF DEF(_JAPAN)

TMCharText::      db "わざマシン@"
TrainerCharText:: db "トレーナー@"
PCCharText::      db "パソコン@"
RocketCharText::  db "ロケットだん@"
PlacePOKeText::   db "ポケモン@"
SixDotsCharText:: db "⋯⋯@"
EnemyText::       db "てきの　@"
GaCharText::      db "が　@"

ELIF DEF(_FRENCH)

PCCharText::      db "PC@"
RocketCharText::  db "ROCKET@"
SixDotsCharText:: db "……@"
PlacePKMNText::   db "<PK><MN>@"
TMCharText::      db "CT@"
TrainerCharText:: db "DRES.@"
PlacePOKeText::   db "POKé@"
EnemyText::       db " ennemi@"

ELIF DEF(_GERMAN)

PCCharText::      db "PC@"
RocketCharText::  db "TEAM ROCKET@"
SixDotsCharText:: db "……@"
PlacePKMNText::   db "<PK><MN>@"
TMCharText::      db "TM@"
TrainerCharText:: db "TRAINER@"
PlacePOKeText::   db "POKé@"
EnemyText::       db "Gegn. @"

ELIF DEF(_ITALIAN)

PCCharText::      db "PC@"
RocketCharText::  db "ROCKET@"
SixDotsCharText:: db "……@"
PlacePKMNText::   db "<PK><MN>@"
TMCharText::      db "MT@"
TrainerCharText:: db "ALLEN.@"
PlacePOKeText::   db "POKé@"
EnemyText::       db " nemico@"

ELIF DEF(_SPANISH)

PCCharText::      db "PC@"
RocketCharText::  db "ROCKET@"
SixDotsCharText:: db "……@"
PlacePKMNText::   db "<PK><MN>@"
TMCharText::      db "MT@"
TrainerCharText:: db "ENTREN.@"
PlacePOKeText::   db "POKé@"
EnemyText::       db "Enem.@"

ELSE ; English USA/Europe

TMCharText::      db "TM@"
TrainerCharText:: db "TRAINER@"
PCCharText::      db "PC@"
RocketCharText::  db "ROCKET@"
PlacePOKeText::   db "POKé@"
SixDotsCharText:: db "……@"
EnemyText::       db "Enemy @"
PlacePKMNText::   db "<PK><MN>@"

ENDC
