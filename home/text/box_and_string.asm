TextBoxBorder::
; Draw a c×b text box at hl.

	; top row
	push hl
	ld a, '┌'
	ld [hli], a
	inc a ; "─"
	call PlaceChars
	inc a ; "┐"
	ld [hl], a
	pop hl

	ld de, SCREEN_WIDTH
	add hl, de

	; middle rows
.next
	push hl
	ld a, '│'
	ld [hli], a
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	call PlaceChars
	ld [hl], '│'
	pop hl

	ld de, SCREEN_WIDTH
	add hl, de
	dec b
	jr nz, .next

	; bottom row
	ld a, '└'
	ld [hli], a
	ld a, '─'
	call PlaceChars
	ld [hl], '┘'
	ret

PlaceChars::
; Place char a c times.
	ld d, c
.loop
	ld [hli], a
	dec d
	jr nz, .loop
	ret

PlaceString::
	push hl

PlaceNextChar::
	ld a, [de]
	cp '@'
	jr nz, .NotTerminator
	ld b, h
	ld c, l
	pop hl
	ret

.NotTerminator
	cp '<NEXT>'
	jr nz, .NotNext
IF DEF(_JAPAN)
	pop hl
	ld bc, 2 * SCREEN_WIDTH
	add hl, bc
	push hl
ELSE
	ld bc, 2 * SCREEN_WIDTH
	ldh a, [hUILayoutFlags]
	bit BIT_SINGLE_SPACED_LINES, a
	jr z, .nextSpacingReady
	ld bc, SCREEN_WIDTH
.nextSpacingReady
	pop hl
	add hl, bc
	push hl
ENDC
	jp NextChar

.NotNext
	cp '<LINE>'
	jr nz, .NotLine
	pop hl
	hlcoord 1, 16
	push hl
	jp NextChar

.NotLine

; Check against command characters.
	dict '<NULL>',    NullChar
	dict '<SCROLL>',  _ContTextNoPause
	dict '<_CONT>',   _ContText
	dict '<PARA>',    Paragraph
IF !DEF(_JAPAN)
	dict '<PAGE>',    PageChar
ENDC
	dict '<PLAYER>',  PrintPlayerName
	dict '<RIVAL>',   PrintRivalName
	dict '#',         PlacePOKe
	dict '<PC>',      PCChar
	dict '<ROCKET>',  RocketChar
	dict '<TM>',      TMChar
	dict '<TRAINER>', TrainerChar
	dict '<CONT>',    ContText
IF DEF(_JAPAN)
	dict '<⋯>',       SixDotsChar
ELSE
	dict '<……>',      SixDotsChar
ENDC
	dict '<DONE>',    DoneText
	dict '<PROMPT>',  PromptText
IF DEF(_JAPAN)
	dict '<GA>',      GaChar
ELSE
	dict '<PKMN>',    PlacePKMN
ENDC
	dict '<DEXEND>',  PlaceDexEnd
	dict '<TARGET>',  PlaceMoveTargetsName
	dict '<USER>',    PlaceMoveUsersName

IF DEF(_JAPAN)
; Japanese diacritic symbols. The code up to .KanaCharacter does not appear
; to be used by ordinary ROM/RAM strings, but it is part of the retail engine.
	cp '゜'
	jr z, .PlaceDiacriticSymbol
	cp '゛'
	jr nz, .KanaCharacter

.PlaceDiacriticSymbol
	push hl
	ld bc, -SCREEN_WIDTH
	add hl, bc
	ld [hl], a
	pop hl
	jr NextChar

.KanaCharacter
	cp FIRST_REGULAR_TEXT_CHAR
	jr nc, .RegularKana
	cp 'パ'
	jr nc, .Handakuten
	cp FIRST_HIRAGANA_DAKUTEN_CHAR
	jr nc, .HiraganaDakuten

	add 'カ' - 'ガ'
	jr .PlaceDakuten

.HiraganaDakuten
	add 'か' - 'が'

.PlaceDakuten
	push af
	ld a, '゛'
	push hl
	ld bc, -SCREEN_WIDTH
	add hl, bc
	ld [hl], a
	pop hl
	pop af
	jr .RegularKana

.Handakuten
	cp 'ぱ'
	jr nc, .HiraganaHandakuten

	add 'ハ' - 'パ'
	jr .PlaceHandakuten

.HiraganaHandakuten
	add 'は' - 'ぱ'

.PlaceHandakuten
	push af
	ld a, '゜'
	push hl
	ld bc, -SCREEN_WIDTH
	add hl, bc
	ld [hl], a
	pop hl
	pop af

.RegularKana
ENDC
	ld [hli], a
	call PrintLetterDelay

NextChar::
	inc de
	jp PlaceNextChar

NullChar::
	ld b, h
	ld c, l
	pop hl
	; A <NULL> character displays a debugging leftover error text.
	ld de, TextIDErrorText
	dec de
	ret

TextIDErrorText::
IF DEF(_JAPAN)
	text_decimal hTextID, 1, 2
	text "エラー"
	done
ELSE
	text_far _TextIDErrorText
	text_end
ENDC

MACRO print_name
	push de
	ld de, \1
	jr PlaceCommandCharacter
ENDM

PrintPlayerName:: print_name wPlayerName
PrintRivalName::  print_name wRivalName

TrainerChar:: print_name TrainerCharText
TMChar::      print_name TMCharText
PCChar::      print_name PCCharText
RocketChar::  print_name RocketCharText
PlacePOKe::   print_name PlacePOKeText
SixDotsChar:: print_name SixDotsCharText
IF DEF(_JAPAN)
GaChar::      print_name GaCharText
ELSE
PlacePKMN::   print_name PlacePKMNText
ENDC

PlaceMoveTargetsName::
	ldh a, [hWhoseTurn]
	xor 1
	jr PlaceMoveUsersName.place

PlaceMoveUsersName::
	ldh a, [hWhoseTurn]

.place:
	push de
	and a
	jr nz, .enemy

	ld de, wBattleMonNick
	jr PlaceCommandCharacter

.enemy
IF DEF(_FRENCH) || DEF(_ITALIAN)
	; French and Italian append the enemy qualifier after the nickname.
	ld de, wEnemyMonNick
	call PlaceString
	ld h, b
	ld l, c
	ld de, EnemyText
ELSE
	ld de, EnemyText
	call PlaceString
	ld h, b
	ld l, c
	ld de, wEnemyMonNick
ENDC
	; fallthrough

PlaceCommandCharacter::
	call PlaceString
	ld h, b
	ld l, c
	pop de
	inc de
	jp PlaceNextChar
