; Core copy/VRAM helpers. Japanese builds keep the complete group together in
; the Home section; international builds place a small hot subset in High Home
; and continue in home/copy2.asm.

IF DEF(_JAPAN)

IsTilePassable::
	homecall_sf _IsTilePassable
	ret

FarCopyData::
	ld [wFarCopyDataSavedROMBank], a
	ldh a, [hLoadedROMBank]
	push af
	ld a, [wFarCopyDataSavedROMBank]
	call BankswitchCommon
	call CopyData
	pop af
	call BankswitchCommon
	ret

FarCopyDataDouble::
	ld [wFarCopyDataSavedROMBank], a
	ldh a, [hLoadedROMBank]
	push af
	ld a, [wFarCopyDataSavedROMBank]
	call BankswitchCommon
	ld a, h
	ld h, d
	ld d, a
	ld a, l
	ld l, e
	ld e, a
	ld a, b
	and a
	jr z, .eightbit
	ld a, c
	and a
	jr z, .loop
.eightbit
	inc b
.loop
	ld a, [de]
	inc de
	ld [hli], a
	ld [hli], a
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	pop af
	call BankswitchCommon
	ret

CopyVideoData::
	ldh a, [hAutoBGTransferEnabled]
	push af
	xor a
	ldh [hAutoBGTransferEnabled], a
	ldh a, [hLoadedROMBank]
	push af
	ld a, b
	call BankswitchCommon
	ld a, e
	ldh [hVBlankCopySource], a
	ld a, d
	ldh [hVBlankCopySource + 1], a
	ld a, l
	ldh [hVBlankCopyDest], a
	ld a, h
	ldh [hVBlankCopyDest + 1], a
.loop
	ld a, c
	cp 8
	jr nc, .eight
	ldh [hVBlankCopySize], a
	call DelayFrame
	pop af
	call BankswitchCommon
	pop af
	ldh [hAutoBGTransferEnabled], a
	ret
.eight
	ld a, 8
	ldh [hVBlankCopySize], a
	call DelayFrame
	ld a, c
	sub 8
	ld c, a
	jr .loop

CopyVideoDataDouble::
	ldh a, [hAutoBGTransferEnabled]
	push af
	xor a
	ldh [hAutoBGTransferEnabled], a
	ldh a, [hLoadedROMBank]
	push af
	ld a, b
	call BankswitchCommon
	ld a, e
	ldh [hVBlankCopyDoubleSource], a
	ld a, d
	ldh [hVBlankCopyDoubleSource + 1], a
	ld a, l
	ldh [hVBlankCopyDoubleDest], a
	ld a, h
	ldh [hVBlankCopyDoubleDest + 1], a
.loop
	ld a, c
	cp 8
	jr nc, .eight
	ldh [hVBlankCopyDoubleSize], a
	call DelayFrame
	pop af
	call BankswitchCommon
	pop af
	ldh [hAutoBGTransferEnabled], a
	ret
.eight
	ld a, 8
	ldh [hVBlankCopyDoubleSize], a
	call DelayFrame
	ld a, c
	sub 8
	ld c, a
	jr .loop

CopyVideoDataAlternate::
	ldh a, [rLCDC]
	bit B_LCDC_ENABLE, a
	jp nz, CopyVideoData
	push hl
	ld h, d
	ld l, e
	pop de
	ld a, b
	push af
	swap c
	ld a, $0f
	and c
	ld b, a
	ld a, $f0
	and c
	ld c, a
	pop af
	jp FarCopyData

CopyVideoDataDoubleAlternate::
	ldh a, [rLCDC]
	bit B_LCDC_ENABLE, a
	jp nz, CopyVideoDataDouble
	push de
	ld d, h
	ld e, l
	ld a, b
	push af
	ld h, 0
	ld l, c
	add hl, hl
	add hl, hl
	add hl, hl
	ld b, h
	ld c, l
	pop af
	pop hl
	jp FarCopyDataDouble

FillMemory::
	push af
	ld a, b
	and a
	jr z, .eightbit
	ld a, c
	and a
	jr z, .multiple256
.eightbit
	inc b
.multiple256
	pop af
.loop
	ld [hli], a
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	ret

CopyData::
	ld a, b
	and a
	jr z, .copybytes
	ld a, c
	and a
	jr z, .loop
	inc b
.loop
	call .copybytes
	dec b
	jr nz, .loop
	ret
.copybytes
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copybytes
	ret

GetFarByte::
	push bc
	ld b, a
	ldh a, [hLoadedROMBank]
	push af
	ld a, b
	call BankswitchCommon
	ld b, [hl]
	pop af
	call BankswitchCommon
	ld a, b
	pop bc
	ret

ClearScreenArea::
	ld a, '　'
	ld de, SCREEN_WIDTH
.rows
	push hl
	push bc
.tiles
	ld [hli], a
	dec c
	jr nz, .tiles
	pop bc
	pop hl
	add hl, de
	dec b
	jr nz, .rows
	ret

CopyScreenTileBufferToVRAM::
	ld c, 6
	ld hl, $0000
	decoord 0, 0
	call .setup
	call DelayFrame
	ld hl, $0600
	decoord 0, 6
	call .setup
	call DelayFrame
	ld hl, $0c00
	decoord 0, 12
	call .setup
	jp DelayFrame
.setup
	ld a, d
	ldh [hVBlankCopyBGSource + 1], a
	call GetRowColAddressBgMap
	ld a, l
	ldh [hVBlankCopyBGDest], a
	ld a, h
	ldh [hVBlankCopyBGDest + 1], a
	ld a, c
	ldh [hVBlankCopyBGNumRows], a
	ld a, e
	ldh [hVBlankCopyBGSource], a
	ret

ClearScreen::
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	inc b
	hlcoord 0, 0
	ld a, '　'
.loop
	ld [hli], a
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	jp Delay3

ELSE

FarCopyData::
	ld [wFarCopyDataSavedROMBank], a
	ldh a, [hLoadedROMBank]
	push af
	ld a, [wFarCopyDataSavedROMBank]
	call BankswitchCommon
	call CopyData
	pop af
	call BankswitchCommon
	ret

CopyData::
	ld a, b
	and a
	jr z, .copybytes
	ld a, c
	and a
	jr z, .loop
	inc b
.loop
	call .copybytes
	dec b
	jr nz, .loop
	ret
.copybytes
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copybytes
	ret

CopyVideoDataAlternate::
	ldh a, [rLCDC]
	bit B_LCDC_ENABLE, a
	jp nz, CopyVideoData
	push hl
	ld h, d
	ld l, e
	pop de
	ld a, b
	push af
	swap c
	ld a, $0f
	and c
	ld b, a
	ld a, $f0
	and c
	ld c, a
	pop af
	jp FarCopyData

CopyVideoDataDoubleAlternate::
	ldh a, [rLCDC]
	bit B_LCDC_ENABLE, a
	jp nz, CopyVideoDataDouble
	push de
	ld d, h
	ld e, l
	ld a, b
	push af
	ld h, 0
	ld l, c
	add hl, hl
	add hl, hl
	add hl, hl
	ld b, h
	ld c, l
	pop af
	pop hl
	jp FarCopyDataDouble

ENDC
