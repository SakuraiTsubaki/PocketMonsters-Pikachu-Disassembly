GetRowColAddressBgMap::
	xor a
	srl h
	rr a
	srl h
	rr a
	srl h
	rr a
	or l
	ld l, a
	ld a, b
	or h
	ld h, a
	ret

ClearBgMap::
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	jr FillBgMapCommon

FillBgMap::
	ld a, l

FillBgMapCommon:
	ld de, TILEMAP_AREA
	ld l, e
.loop
	ld [hli], a
	dec e
	jr nz, .loop
	dec d
	jr nz, .loop
	ret

RedrawRowOrColumn::
	ldh a, [hRedrawRowOrColumnMode]
	and a
	ret z
	ld b, a
	xor a
	ldh [hRedrawRowOrColumnMode], a
	dec b
	jr nz, .redrawRow
.redrawColumn
	ld hl, wRedrawRowOrColumnSrcTiles
	ldh a, [hRedrawRowOrColumnDest]
	ld e, a
	ldh a, [hRedrawRowOrColumnDest + 1]
	ld d, a
	ld c, SCREEN_HEIGHT
.loop1
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ld a, TILEMAP_WIDTH - 1
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	ld a, d
	and HIGH(TILEMAP_AREA - 1)
	or HIGH(vBGMap0)
	ld d, a
	dec c
	jr nz, .loop1
	xor a
	ldh [hRedrawRowOrColumnMode], a
	ret
.redrawRow
	ld hl, wRedrawRowOrColumnSrcTiles
	ldh a, [hRedrawRowOrColumnDest]
	ld e, a
	ldh a, [hRedrawRowOrColumnDest + 1]
	ld d, a
	push de
	call .DrawHalf
	pop de
	ld a, TILEMAP_WIDTH
	add e
	ld e, a
.DrawHalf
	ld c, SCREEN_WIDTH / 2
.loop2
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ld a, e
	inc a
	and %11111
	ld b, a
	ld a, e
	and %11100000
	or b
	ld e, a
	dec c
	jr nz, .loop2
	ret

AutoBgMapTransfer::
	ldh a, [hAutoBGTransferEnabled]
	and a
	ret z
	ld [hSPTemp], sp
	ldh a, [hAutoBGTransferPortion]
	and a
	jr z, .transferTopThird
	dec a
	jr z, .transferMiddleThird
.transferBottomThird
	hlcoord 0, 2 * SCREEN_HEIGHT / 3
	ld sp, hl
	ldh a, [hAutoBGTransferDest + 1]
	ld h, a
	ldh a, [hAutoBGTransferDest]
	ld l, a
	ld de, 12 * TILEMAP_WIDTH
	add hl, de
	xor a
	jr .doTransfer
.transferTopThird
	hlcoord 0, 0
	ld sp, hl
	ldh a, [hAutoBGTransferDest + 1]
	ld h, a
	ldh a, [hAutoBGTransferDest]
	ld l, a
	ld a, TRANSFERMIDDLE
	jr .doTransfer
.transferMiddleThird
	hlcoord 0, SCREEN_HEIGHT / 3
	ld sp, hl
	ldh a, [hAutoBGTransferDest + 1]
	ld h, a
	ldh a, [hAutoBGTransferDest]
	ld l, a
	ld de, 6 * TILEMAP_WIDTH
	add hl, de
	ld a, TRANSFERBOTTOM
.doTransfer
	ldh [hAutoBGTransferPortion], a
	ld b, SCREEN_HEIGHT / 3

TransferBgRows::
REPT SCREEN_WIDTH / 2 - 1
	pop de
	ld [hl], e
	inc l
	ld [hl], d
	inc l
ENDR
	pop de
	ld [hl], e
	inc l
	ld [hl], d
	ld a, TILEMAP_WIDTH - (SCREEN_WIDTH - 1)
	add l
	ld l, a
	jr nc, .ok
	inc h
.ok
	dec b
	jr nz, TransferBgRows
	ldh a, [hSPTemp]
	ld l, a
	ldh a, [hSPTemp + 1]
	ld h, a
	ld sp, hl
	ret

VBlankCopyBgMap::
	ldh a, [hVBlankCopyBGSource]
	and a
	ret z
	ld [hSPTemp], sp
	ldh a, [hVBlankCopyBGSource]
	ld l, a
	ldh a, [hVBlankCopyBGSource + 1]
	ld h, a
	ld sp, hl
	ldh a, [hVBlankCopyBGDest]
	ld l, a
	ldh a, [hVBlankCopyBGDest + 1]
	ld h, a
	ldh a, [hVBlankCopyBGNumRows]
	ld b, a
	xor a
	ldh [hVBlankCopyBGSource], a
	jr TransferBgRows

VBlankCopyDouble::
	ldh a, [hVBlankCopyDoubleSize]
	and a
	ret z
	ld [hSPTemp], sp
	ldh a, [hVBlankCopyDoubleSource]
	ld l, a
	ldh a, [hVBlankCopyDoubleSource + 1]
	ld h, a
	ld sp, hl
	ldh a, [hVBlankCopyDoubleDest]
	ld l, a
	ldh a, [hVBlankCopyDoubleDest + 1]
	ld h, a
	ldh a, [hVBlankCopyDoubleSize]
	ld b, a
	xor a
	ldh [hVBlankCopyDoubleSize], a
.loop
REPT TILE_SIZE / 4 - 1
	pop de
	ld [hl], e
	inc l
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	ld [hl], d
	inc l
ENDR
	pop de
	ld [hl], e
	inc l
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	ld [hl], d
	inc hl
	dec b
	jr nz, .loop
	ld [hVBlankCopyDoubleSource], sp
	ld sp, hl
	ld [hVBlankCopyDoubleDest], sp
	ldh a, [hSPTemp]
	ld l, a
	ldh a, [hSPTemp + 1]
	ld h, a
	ld sp, hl
	ret

VBlankCopy::
	ldh a, [hVBlankCopySize]
	and a
	ret z
	ld [hSPTemp], sp
	ldh a, [hVBlankCopySource]
	ld l, a
	ldh a, [hVBlankCopySource + 1]
	ld h, a
	ld sp, hl
	ldh a, [hVBlankCopyDest]
	ld l, a
	ldh a, [hVBlankCopyDest + 1]
	ld h, a
	ldh a, [hVBlankCopySize]
	ld b, a
	xor a
	ldh [hVBlankCopySize], a
.loop
REPT TILE_SIZE / 2 - 1
	pop de
	ld [hl], e
	inc l
	ld [hl], d
	inc l
ENDR
	pop de
	ld [hl], e
	inc l
	ld [hl], d
	inc hl
	dec b
	jr nz, .loop
	ld [hVBlankCopySource], sp
	ld sp, hl
	ld [hVBlankCopyDest], sp
	ldh a, [hSPTemp]
	ld l, a
	ldh a, [hSPTemp + 1]
	ld h, a
	ld sp, hl
	ret

UpdateMovingBgTiles::
	ldh a, [hTileAnimations]
	and a
	ret z
IF !DEF(_JAPAN)
	ldh a, [rLY]
	cp $90
	ret c
ENDC
	ldh a, [hMovingBGTilesCounter1]
	inc a
	ldh [hMovingBGTilesCounter1], a
	cp 20
	ret c
	cp 21
	jr z, .flower
	ld hl, vTileset tile $14
	ld c, TILE_SIZE
	ld a, [wMovingBGTilesCounter2]
	inc a
	and 7
	ld [wMovingBGTilesCounter2], a
	and 4
	jr nz, .left
.right
	ld a, [hl]
	rrca
	ld [hli], a
	dec c
	jr nz, .right
	jr .done
.left
	ld a, [hl]
	rlca
	ld [hli], a
	dec c
	jr nz, .left
.done
	ldh a, [hTileAnimations]
	rrca
	ret nc
	xor a
	ldh [hMovingBGTilesCounter1], a
	ret
.flower
	xor a
	ldh [hMovingBGTilesCounter1], a
	ld a, [wMovingBGTilesCounter2]
	and 3
	cp 2
	ld hl, FlowerTile1
	jr c, .copy
	ld hl, FlowerTile2
	jr z, .copy
	ld hl, FlowerTile3
.copy
	ld de, vTileset tile $03
	ld c, TILE_SIZE
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	ret

FlowerTile1: INCBIN "gfx/tilesets/flower/flower1.2bpp"
FlowerTile2: INCBIN "gfx/tilesets/flower/flower2.2bpp"
FlowerTile3: INCBIN "gfx/tilesets/flower/flower3.2bpp"
