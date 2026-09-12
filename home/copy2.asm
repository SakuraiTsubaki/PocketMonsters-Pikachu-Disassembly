; International continuation of copy/VRAM helpers.
; Japanese builds keep these routines in home/copy.asm instead.

IF !DEF(_JAPAN)

IsTilePassable::
	homecall_sf _IsTilePassable
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
	ld a, ' '
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
	ld c, SCREEN_HEIGHT / 3
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
	ld a, ' '
.loop
	ld [hli], a
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	jp Delay3

ENDC
