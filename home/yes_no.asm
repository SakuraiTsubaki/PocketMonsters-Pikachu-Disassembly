; displays yes/no choice
; yes -> set carry
YesNoChoice::
	call SaveScreenTilesToBuffer1
	call InitYesNoTextBoxParameters
	jr DisplayYesNoChoice

TwoOptionMenu:: ; unreferenced
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call InitYesNoTextBoxParameters
	jp DisplayTextBoxID

InitYesNoTextBoxParameters::
	xor a ; YES_NO_MENU
	ld [wTwoOptionMenuID], a
IF DEF(_GERMAN)
	; German widens the normal two-option box by one column.
	hlcoord 13, 7
	lb bc, 8, 14
ELSE
	hlcoord 14, 7
	lb bc, 8, 15
ENDC
	ret

YesNoChoicePokeCenter::
	call SaveScreenTilesToBuffer1
	ld a, HEAL_CANCEL_MENU
	ld [wTwoOptionMenuID], a
IF DEF(_JAPAN)
	; Japanese healing/cancel strings use the wider right-aligned box.
	hlcoord 13, 6
	lb bc, 8, 14
ELSE
	hlcoord 11, 6
	lb bc, 8, 12
ENDC
	jr DisplayYesNoChoice

WideYesNoChoice:: ; unreferenced
	call SaveScreenTilesToBuffer1
	ld a, WIDE_YES_NO_MENU
	ld [wTwoOptionMenuID], a
	hlcoord 12, 7
	lb bc, 8, 13

DisplayYesNoChoice::
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID
	jp LoadScreenTilesFromBuffer1
