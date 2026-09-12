; Print a BCD (binary-coded decimal) number.
; de = source BCD address, hl = destination, c = flags/length.
PrintBCDNumber::
	ld b, c
	res BIT_LEADING_ZEROES, c
	res BIT_LEFT_ALIGN, c
IF !DEF(_JAPAN)
	res BIT_MONEY_SIGN, c
	bit BIT_MONEY_SIGN, b
	jr z, .loop
	bit BIT_LEADING_ZEROES, b
	jr nz, .loop
	ld [hl], '¥'
	inc hl
ENDC
.loop
	ld a, [de]
	swap a
	call PrintBCDDigit
	ld a, [de]
	call PrintBCDDigit
	inc de
	dec c
	jr nz, .loop
	bit BIT_LEADING_ZEROES, b
	jr z, .done
	bit BIT_LEFT_ALIGN, b
	jr nz, .skipRightAlignmentAdjustment
	dec hl
.skipRightAlignmentAdjustment
IF DEF(_JAPAN)
	ld [hl], '０'
ELSE
	bit BIT_MONEY_SIGN, b
	jr z, .skipCurrencySymbol
	ld [hl], '¥'
	inc hl
.skipCurrencySymbol
	ld [hl], '0'
ENDC
	call PrintLetterDelay
	inc hl
.done
	ret

PrintBCDDigit::
	and $f
	and a
	jr z, .zeroDigit
IF DEF(_JAPAN)
	res BIT_LEADING_ZEROES, b
ELSE
	bit BIT_LEADING_ZEROES, b
	jr z, .outputDigit
	bit BIT_MONEY_SIGN, b
	jr z, .skipCurrencySymbol
	ld [hl], '¥'
	inc hl
	res BIT_MONEY_SIGN, b
.skipCurrencySymbol
	res BIT_LEADING_ZEROES, b
ENDC
.outputDigit
IF DEF(_JAPAN)
	add '０'
ELSE
	add '0'
ENDC
	ld [hli], a
	jp PrintLetterDelay
.zeroDigit
	bit BIT_LEADING_ZEROES, b
	jr z, .outputDigit
	bit BIT_LEFT_ALIGN, b
	ret nz
	inc hl
	ret
