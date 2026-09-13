; Bank 03 fine-grained family reconstruction.
; Common source lines are emitted once; only source-family differences are conditional.
; JP: Narishma-gb/pokeyellow-jp @ f282e72ae26232790fdb780aa5a5db7ec8ebf572
; INT: pret/pokeyellow @ e89ead154b9968aa50eed9328ff2b38b6c194382

BookOrSculptureText::
	text_asm
	ld hl, PokemonBooksText
	ld a, [wCurMapTileset]
	cp MANSION ; Celadon Mansion tileset
	jr nz, .ok
	lda_coord 8, 6
	cp $38
	jr nz, .ok
	ld hl, DiglettSculptureText
.ok
	call PrintText
	jp TextScriptEnd

PokemonBooksText:
IF DEF(_JAPAN)
	text "#の　ほんが　いっぱい！"
	done
ELSE
	text_far _PokemonBooksText
	text_end
ENDC

DiglettSculptureText:
IF DEF(_JAPAN)
	text "ぶつだん　だ<⋯>"
	done
ELSE
	text_far _DiglettSculptureText
	text_end
ENDC
