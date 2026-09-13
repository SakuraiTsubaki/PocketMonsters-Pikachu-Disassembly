; Bank 03 fine-grained family reconstruction.
; Common source lines are emitted once; only source-family differences are conditional.
; JP: Narishma-gb/pokeyellow-jp @ f282e72ae26232790fdb780aa5a5db7ec8ebf572
; INT: pret/pokeyellow @ e89ead154b9968aa50eed9328ff2b38b6c194382

IndigoPlateauStatues::
	text_asm
	ld hl, IndigoPlateauStatuesText1
	call PrintText
	ld a, [wXCoord]
	bit 0, a ; even or odd?
	ld hl, IndigoPlateauStatuesText2
	jr nz, .ok
	ld hl, IndigoPlateauStatuesText3
.ok
	call PrintText
	jp TextScriptEnd

IndigoPlateauStatuesText1:
IF DEF(_JAPAN)
	text "ここは　セキエイ　こうげん"
	prompt
ELSE
	text_far _IndigoPlateauStatuesText1
	text_end
ENDC

IndigoPlateauStatuesText2:
IF DEF(_JAPAN)
	text "#　<TRAINER>の　ちょうてん！"
	line "#　リーグ　ほんぶ"
	done
ELSE
	text_far _IndigoPlateauStatuesText2
	text_end
ENDC

IndigoPlateauStatuesText3:
IF DEF(_JAPAN)
	text "#の　さいこう　きかん"
	line "#　リーグ　ほんぶ"
	done
ELSE
	text_far _IndigoPlateauStatuesText3
	text_end
ENDC
