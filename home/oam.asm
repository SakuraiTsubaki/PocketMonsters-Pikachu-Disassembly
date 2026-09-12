; INPUT:
; a = oam block index (each block is 4 oam entries)
; b = Y coordinate of upper left corner of sprite
; c = X coordinate of upper left corner of sprite
; de = base address of 4 tile number and attribute pairs
WriteOAMBlock::
	ld h, HIGH(wShadowOAM)
	swap a
	ld l, a
	call .writeOneEntry
	push bc
	ld a, 8
	add c
	ld c, a
	call .writeOneEntry
	pop bc
	ld a, 8
	add b
	ld b, a
	call .writeOneEntry
	ld a, 8
	add c
	ld c, a
.writeOneEntry
	ld [hl], b
	inc hl
	ld [hl], c
	inc hl
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ret
