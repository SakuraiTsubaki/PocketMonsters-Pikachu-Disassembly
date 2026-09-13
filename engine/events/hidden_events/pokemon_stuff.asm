; Bank 03 family-conditional reconstruction.
; Japanese source: Narishma-gb/pokeyellow-jp @ f282e72ae26232790fdb780aa5a5db7ec8ebf572
; International source: pret/pokeyellow @ e89ead154b9968aa50eed9328ff2b38b6c194382
; Whole-family branches are intentionally preserved losslessly until per-target byte validation allows finer deduplication.

IF DEF(_JAPAN)

PokemonStuffText::
	text "わあ！　#グッズが"
	line "たくさん　そろってるぞ！"
	done

ELSE

PokemonStuffText::
	text_far _PokemonStuffText
	text_end

ENDC
