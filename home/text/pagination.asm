ContText::
	push de
	ld b, h
	ld c, l
	ld hl, ContCharText
	call TextCommandProcessor
	ld h, b
	ld l, c
	pop de
	inc de
	jp PlaceNextChar

ContCharText::
IF DEF(_JAPAN)
	text "<_CONT>@"
	text_end
ELSE
	text_far _ContCharText
	text_end
ENDC

PlaceDexEnd::
IF DEF(_JAPAN)
	ld [hl], '。'
ELSE
	ld [hl], '.'
ENDC
	pop hl
	ret

PromptText::
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jp z, .ok
	ld a, '▼'
	ldcoord_a 18, 16
.ok
	call ProtectedDelay3
	call ManualTextScroll
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	ldcoord_a 18, 16

DoneText::
	pop hl
	ld de, .stop
	dec de
	ret

.stop:
	text_end

Paragraph::
	push de
	ld a, '▼'
	ldcoord_a 18, 16
	call ProtectedDelay3
	call ManualTextScroll
	hlcoord 1, 13
	lb bc, 4, 18
	call ClearScreenArea
	ld c, 20
	call DelayFrames
	pop de
	hlcoord 1, 14
	jp NextChar

IF !DEF(_JAPAN)
PageChar::
	ldh a, [hUILayoutFlags]
	bit BIT_PAGE_CHAR_IS_NEXT, a
	jr z, .pageChar
	ld a, '<NEXT>'
	jp PlaceNextChar.NotTerminator

.pageChar
	push de
	ld a, '▼'
	ldcoord_a 18, 16
	call ProtectedDelay3
	call ManualTextScroll
	hlcoord 1, 10
	lb bc, 7, 18
	call ClearScreenArea
	ld c, 20
	call DelayFrames
	pop de
	pop hl
	hlcoord 1, 11
	push hl
	jp NextChar
ENDC

_ContText::
	ld a, '▼'
	ldcoord_a 18, 16
	call ProtectedDelay3
	push de
	call ManualTextScroll
	pop de
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	ldcoord_a 18, 16
_ContTextNoPause::
	push de
	call ScrollTextUpOneLine
	call ScrollTextUpOneLine
	hlcoord 1, 16
	pop de
	jp NextChar

; Move both rows of text in the normal text box up one row.
ScrollTextUpOneLine::
	hlcoord 0, 14
	decoord 0, 13
	ld b, SCREEN_WIDTH * 3
.copyText
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copyText
	hlcoord 1, 16
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	ld b, SCREEN_WIDTH - 2
.clearText
	ld [hli], a
	dec b
	jr nz, .clearText

	ld b, 5
.WaitFrame
	call DelayFrame
	dec b
	jr nz, .WaitFrame
	ret

ProtectedDelay3::
	push bc
	call Delay3
	pop bc
	ret
