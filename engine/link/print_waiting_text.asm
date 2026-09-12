PrintWaitingText::
	hlcoord 3, 10
IF DEF(_GERMAN)
	lb bc, 1, 13
ELSE
	lb bc, 1, 11
ENDC
	ld a, [wIsInBattle]
	and a
	jr z, .trade
; battle
	call TextBoxBorder
	jr .border_done
.trade
	call CableClub_TextBoxBorder
.border_done
	hlcoord 4, 11
	ld de, WaitingText
	call PlaceString
	ld c, 50
	jp DelayFrames

WaitingText:
IF DEF(_JAPAN)
	db "つうしんたいきちゅう！@"
ELIF DEF(_FRENCH)
	db "UN MOMENT…@"
ELIF DEF(_GERMAN)
	db "BITTE WARTEN…@"
ELIF DEF(_ITALIAN)
	db "ATTENDERE!@"
ELIF DEF(_SPANISH)
	db "¡ESPERA...!@"
ELSE
	db "Waiting...!@"
ENDC
