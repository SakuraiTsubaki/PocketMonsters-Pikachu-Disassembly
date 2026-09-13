; Bank 03 family-conditional reconstruction.
; Japanese source: Narishma-gb/pokeyellow-jp @ f282e72ae26232790fdb780aa5a5db7ec8ebf572
; International source: pret/pokeyellow @ e89ead154b9968aa50eed9328ff2b38b6c194382
; Whole-family branches are intentionally preserved losslessly until per-target byte validation allows finer deduplication.

IF DEF(_JAPAN)

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
	text "ここは　セキエイ　こうげん"
	prompt

IndigoPlateauStatuesText2:
	text "#　<TRAINER>の　ちょうてん！"
	line "#　リーグ　ほんぶ"
	done

IndigoPlateauStatuesText3:
	text "#の　さいこう　きかん"
	line "#　リーグ　ほんぶ"
	done

ELSE

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
	text_far _IndigoPlateauStatuesText1
	text_end

IndigoPlateauStatuesText2:
	text_far _IndigoPlateauStatuesText2
	text_end

IndigoPlateauStatuesText3:
	text_far _IndigoPlateauStatuesText3
	text_end

ENDC
