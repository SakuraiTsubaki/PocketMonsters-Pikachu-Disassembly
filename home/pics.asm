; Uncompress the front or back sprite of the specified mon.
UncompressMonSprite::
	ld bc, wMonHeader
	add hl, bc
	ld a, [hli]
	ld [wSpriteInputPtr], a
	ld a, [hl]
	ld [wSpriteInputPtr + 1], a
	ld a, [wCurPartySpecies]
	ld b, a
	cp FOSSIL_KABUTOPS
	ld a, BANK(FossilKabutopsPic)
	jr z, .GotBank
	ld a, b
	cp TANGELA + 1
	ld a, BANK("Pics 1")
	jr c, .GotBank
	ld a, b
	cp MOLTRES + 1
	ld a, BANK("Pics 2")
	jr c, .GotBank
	ld a, b
	cp BEEDRILL + 2
	ld a, BANK("Pics 3")
	jr c, .GotBank
	ld a, b
	cp STARMIE + 1
	ld a, BANK("Pics 4")
	jr c, .GotBank
	ld a, BANK("Pics 5")
.GotBank
	jp UncompressSpriteData

LoadMonFrontSprite::
	push de
	ld hl, wMonHFrontSprite - wMonHeader
	call UncompressMonSprite
	ld hl, wMonHSpriteDim
	ld a, [hli]
	ld c, a
	pop de

LoadUncompressedSpriteData::
	push de
	and $f
	ldh [hSpriteWidth], a
	ld b, a
	ld a, $7
	sub b
	inc a
	srl a
	ld b, a
	add a
	add a
	add a
	sub b
	ldh [hSpriteOffset], a
	ld a, c
	swap a
	and $f
	ld b, a
	add a
	add a
	add a
	ldh [hSpriteHeight], a
	ld a, $7
	sub b
	ld b, a
	ldh a, [hSpriteOffset]
	add b
	add a
	add a
	add a
	ldh [hSpriteOffset], a
	ld a, BANK("Sprite Buffers")
	call OpenSRAM
	ld hl, sSpriteBuffer0
	call ZeroSpriteBuffer
	ld de, sSpriteBuffer1
	ld hl, sSpriteBuffer0
	call AlignSpriteDataCentered
	ld hl, sSpriteBuffer1
	call ZeroSpriteBuffer
	ld de, sSpriteBuffer2
	ld hl, sSpriteBuffer1
	call AlignSpriteDataCentered
	call CloseSRAM
	pop de
	jp InterlaceMergeSpriteBuffers

AlignSpriteDataCentered::
	ldh a, [hSpriteOffset]
	ld b, $0
	ld c, a
	add hl, bc
	ldh a, [hSpriteWidth]
.columnLoop
	push af
	push hl
	ldh a, [hSpriteHeight]
	ld c, a
.columnInnerLoop
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .columnInnerLoop
	pop hl
	ld bc, 7 * TILE_1BPP_SIZE
	add hl, bc
	pop af
	dec a
	jr nz, .columnLoop
	ret

ZeroSpriteBuffer::
	ld bc, SPRITEBUFFERSIZE
.nextByteLoop
	xor a
	ld [hli], a
	dec bc
	ld a, b
	or c
	jr nz, .nextByteLoop
	ret

InterlaceMergeSpriteBuffers::
	ld a, BANK("Sprite Buffers")
	call OpenSRAM
	push de
	ld hl, sSpriteBuffer2 + (SPRITEBUFFERSIZE - 1)
	ld de, sSpriteBuffer1 + (SPRITEBUFFERSIZE - 1)
	ld bc, sSpriteBuffer0 + (SPRITEBUFFERSIZE - 1)
	ld a, SPRITEBUFFERSIZE / 2
	ldh [hSpriteInterlaceCounter], a
.interlaceLoop
	ld a, [de]
	dec de
	ld [hld], a
	ld a, [bc]
	dec bc
	ld [hld], a
	ld a, [de]
	dec de
	ld [hld], a
	ld a, [bc]
	dec bc
	ld [hld], a
	ldh a, [hSpriteInterlaceCounter]
	dec a
	ldh [hSpriteInterlaceCounter], a
	jr nz, .interlaceLoop
	ld a, [wSpriteFlipped]
	and a
	jr z, .notFlipped
	ld bc, 2 * SPRITEBUFFERSIZE
	ld hl, sSpriteBuffer1
.swapLoop
	swap [hl]
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .swapLoop
.notFlipped
	pop hl
	ld de, sSpriteBuffer1
	ld c, PIC_SIZE
	ldh a, [hLoadedROMBank]
	ld b, a
	call CopyVideoData
	jp CloseSRAM
