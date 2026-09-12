TextScriptEndingText::
	text_end

TextScriptEnd::
	ld hl, TextScriptEndingText
	ret

IF DEF(_JAPAN)

ExclamationText::
	text "！"
	done

GroundRoseText::
	text "どこかで　じめんがもりあがった！"
	done

BoulderText::
	text "「かいりき」　で　うごかせるかも<⋯>"
	done

MartSignText::
	text "#　グッズが　いっぱい！"
	line "フレンドリィショップ"
	done

PokeCenterSignText::
	text "#の　たいりょく　かいふく！"
	line "#センター"
	done

ELSE

ExclamationText::
	text_far _ExclamationText
	text_end

GroundRoseText::
	text_far _GroundRoseText
	text_end

BoulderText::
	text_far _BoulderText
	text_end

MartSignText::
	text_far _MartSignText
	text_end

PokeCenterSignText::
	text_far _PokeCenterSignText
	text_end

ENDC

PickUpItemText::
	text_asm
	predef PickUpItem
	jp TextScriptEnd
