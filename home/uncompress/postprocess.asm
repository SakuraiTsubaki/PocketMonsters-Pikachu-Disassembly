	add $8
	ld [wSpriteCurPosX], a             ; go to next column
	ld b, a
	ld a, [wSpriteWidth]
	cp b
	jr nz, .xorChunksLoop               ; test if all columns finished
	xor a
	ld [wSpriteCurPosX], a
	ret

; reverses the bits in the nybble given in register a
ReverseNybble::
	ld de, NybbleReverseTable
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	ld a, [de]
	ret

; resets sprite buffer pointers to buffer 1 and 2, depending on wSpriteLoadFlags
ResetSpriteBufferPointers::
	ld a, [wSpriteLoadFlags]
	bit BIT_USE_SPRITE_BUFFER_2, a
	jr nz, .buffer2Selected
	ld de, sSpriteBuffer1
	ld hl, sSpriteBuffer2
	jr .storeBufferPointers
.buffer2Selected
	ld de, sSpriteBuffer2
	ld hl, sSpriteBuffer1
.storeBufferPointers
	ld a, l
	ld [wSpriteOutputPtr], a
	ld a, h
	ld [wSpriteOutputPtr + 1], a
	ld a, e
	ld [wSpriteOutputPtrCached], a
	ld a, d
	ld [wSpriteOutputPtrCached + 1], a
	ret

; maps each nybble to its reverse
NybbleReverseTable::
	db $0, $8, $4, $c, $2, $a, $6, $e, $1, $9, $5, $d, $3, $b, $7, $f

; combines the two loaded chunks with xor (the chunk loaded second is the destination). Both chunks are differential decoded beforehand.
UnpackSpriteMode2::
	call ResetSpriteBufferPointers
	ld a, [wSpriteFlipped]
	push af
	xor a
	ld [wSpriteFlipped], a            ; temporarily clear flipped flag for decoding the destination chunk
	ld a, [wSpriteOutputPtrCached]
	ld l, a
	ld a, [wSpriteOutputPtrCached + 1]
	ld h, a
	call SpriteDifferentialDecode
	call ResetSpriteBufferPointers
	pop af
	ld [wSpriteFlipped], a
	jp XorSpriteChunks

; stores hl into the output pointers
StoreSpriteOutputPointer::
	ld a, l
	ld [wSpriteOutputPtr], a
	ld [wSpriteOutputPtrCached], a
	ld a, h
	ld [wSpriteOutputPtr + 1], a
	ld [wSpriteOutputPtrCached + 1], a
	ret
