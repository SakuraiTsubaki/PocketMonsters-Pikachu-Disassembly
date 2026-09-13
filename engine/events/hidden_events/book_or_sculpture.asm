; Bank 03 family-conditional reconstruction.
; Japanese source: Narishma-gb/pokeyellow-jp @ f282e72ae26232790fdb780aa5a5db7ec8ebf572
; International source: pret/pokeyellow @ e89ead154b9968aa50eed9328ff2b38b6c194382
; Whole-family branches are intentionally preserved losslessly until per-target byte validation allows finer deduplication.

IF DEF(_JAPAN)

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
	text "#の　ほんが　いっぱい！"
	done

DiglettSculptureText:
	text "ぶつだん　だ<⋯>"
	done

ELSE

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
	text_far _PokemonBooksText
	text_end

DiglettSculptureText:
	text_far _DiglettSculptureText
	text_end

ENDC
