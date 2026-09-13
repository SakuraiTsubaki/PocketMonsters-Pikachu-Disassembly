; Bank 03 fine-grained family reconstruction.
; Common source lines are emitted once; only source-family differences are conditional.
; JP: Narishma-gb/pokeyellow-jp @ f282e72ae26232790fdb780aa5a5db7ec8ebf572
; INT: pret/pokeyellow @ e89ead154b9968aa50eed9328ff2b38b6c194382

PokemonStuffText::
IF DEF(_JAPAN)
	text "わあ！　#グッズが"
	line "たくさん　そろってるぞ！"
	done
ELSE
	text_far _PokemonStuffText
	text_end
ENDC
