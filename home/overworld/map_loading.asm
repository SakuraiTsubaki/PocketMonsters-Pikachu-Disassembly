	ld a, [wCurMap]
	call SwitchToMapRomBank
	ld a, [wCurMapTileset]
	ld b, a
	res BIT_NO_PREVIOUS_MAP, a
	ld [wCurMapTileset], a
	ldh [hPreviousTileset], a
	bit BIT_NO_PREVIOUS_MAP, b
	ret nz
	call GetMapHeaderPointer
	ld de, wCurMapHeader
	ld c, wCurMapHeaderEnd - wCurMapHeader
.copyFixedHeaderLoop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copyFixedHeaderLoop
; initialize all the connected maps to disabled at first, before loading the actual values
	ld a, $ff
	ld [wNorthConnectedMap], a
	ld [wSouthConnectedMap], a
	ld [wWestConnectedMap], a
	ld [wEastConnectedMap], a
; copy connection data (if any) to WRAM
	ld a, [wCurMapConnections]
	ld b, a
; check north
	bit NORTH_F, b
	jr z, .checkSouth
	ld de, wNorthConnectionHeader
	call CopyMapConnectionHeader
.checkSouth
	bit SOUTH_F, b
	jr z, .checkWest
	ld de, wSouthConnectionHeader
	call CopyMapConnectionHeader
.checkWest
	bit WEST_F, b
	jr z, .checkEast
	ld de, wWestConnectionHeader
	call CopyMapConnectionHeader
.checkEast
	bit EAST_F, b
	jr z, .getObjectDataPointer
	ld de, wEastConnectionHeader
	call CopyMapConnectionHeader
.getObjectDataPointer
	ld a, [hli]
	ld [wObjectDataPointerTemp], a
	ld a, [hli]
	ld [wObjectDataPointerTemp + 1], a
	push hl
	ld a, [wObjectDataPointerTemp]
	ld l, a
	ld a, [wObjectDataPointerTemp + 1]
	ld h, a ; hl = base of object data
	ld de, wMapBackgroundTile
	ld a, [hli]
	ld [de], a
; load warp data
	ld a, [hli]
	ld [wNumberOfWarps], a
	and a
	jr z, .loadSignData
	ld c, a
	ld de, wWarpEntries
.warpLoop ; one warp per loop iteration
	ld b, 4
.warpInnerLoop
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .warpInnerLoop
	dec c
	jr nz, .warpLoop
.loadSignData
	ld a, [hli] ; number of signs
	ld [wNumSigns], a
	and a ; are there any signs?
	jr z, .loadSpriteData ; if not, skip this
	call CopySignData
.loadSpriteData
	ld a, [wStatusFlags4]
	bit BIT_BATTLE_OVER_OR_BLACKOUT, a
	jr nz, .finishUp ; if so, skip this because battles don't destroy this data
	call InitSprites
.finishUp
	predef LoadTilesetHeader
	ld a, [wStatusFlags4]
	bit BIT_BATTLE_OVER_OR_BLACKOUT, a ; did a battle happen immediately before this?
	jr nz, .skip_pika_spawn
	callfar SchedulePikachuSpawnForAfterText
.skip_pika_spawn
	callfar LoadWildData
	pop hl ; restore hl from before going to the warp/sign/sprite data (this value was saved for seemingly no purpose)
	ld a, [wCurMapHeight] ; map height in 4x4 tile blocks
	add a ; double it
	ld [wCurrentMapHeight2], a ; store map height in 2x2 tile blocks
	ld a, [wCurMapWidth] ; map width in 4x4 tile blocks
	add a ; double it
	ld [wCurrentMapWidth2], a ; store map width in 2x2 tile blocks
	ld a, [wCurMap]
	ld c, a
	ld b, $00
	ldh a, [hLoadedROMBank]
	push af
	ld a, BANK(MapSongBanks)
	call BankswitchCommon
	ld hl, MapSongBanks
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld [wMapMusicSoundID], a ; music 1
	ld a, [hl]
	ld [wMapMusicROMBank], a ; music 2
	pop af
	call BankswitchCommon
	ret

; function to copy map connection data from ROM to WRAM
; Input: hl = source, de = destination
CopyMapConnectionHeader::
	ld c, $0b
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	ret

CopySignData::
	ld de, wSignCoords ; start of sign coords
	ld bc, wSignTextIDs ; start of sign text ids
	ld a, [wNumSigns] ; number of signs
.signcopyloop
	push af
	ld a, [hli]
	ld [de], a ; copy y coord
	inc de
	ld a, [hli]
	ld [de], a ; copy x coord
	inc de
	ld a, [hli]
	ld [bc], a ; copy sign text id
	inc bc
	pop af
	dec a
	jr nz, .signcopyloop
	ret

; function to load map data
LoadMapData::
	ldh a, [hLoadedROMBank]
	push af
	call DisableLCD
	call ResetMapVariables
	call LoadTextBoxTilePatterns
	call LoadMapHeader
	call InitMapSprites ; load tile pattern data for sprites
	call LoadScreenRelatedData
	call CopyMapViewToVRAM
	ld a, $01
	ld [wUpdateSpritesEnabled], a
	call EnableLCD
	ld b, SET_PAL_OVERWORLD
	call RunPaletteCommand
	call LoadPlayerSpriteGraphics
	ld a, [wStatusFlags6]
	and 1 << BIT_DUNGEON_WARP | 1 << BIT_FLY_WARP
	jr nz, .restoreRomBank
	ld a, [wStatusFlags7]
	bit BIT_NO_MAP_MUSIC, a
	jr nz, .restoreRomBank
	call UpdateMusic6Times
	call PlayDefaultMusicFadeOutCurrent
.restoreRomBank
	pop af
	call BankswitchCommon
	ret

LoadScreenRelatedData::
	call LoadTileBlockMap
	call LoadTilesetTilePatternData
	call LoadCurrentMapView
	ret

ReloadMapAfterSurfingMinigame::
	ldh a, [hLoadedROMBank]
	push af
	call DisableLCD
	call ResetMapVariables
	ld a, [wCurMap]
	call SwitchToMapRomBank
	call LoadScreenRelatedData
	call CopyMapViewToVRAM
	ld de, vBGMap1
	call CopyMapViewToVRAM2
	call EnableLCD
	call ReloadMapSpriteTilePatterns
	pop af
	call BankswitchCommon
	jr FinishReloadingMap

ReloadMapAfterPrinter::
	ldh a, [hLoadedROMBank]
	push af
	ld a, [wCurMap]
	call SwitchToMapRomBank
	call LoadTileBlockMap
	pop af
	call BankswitchCommon
FinishReloadingMap:
	jpfar SetMapSpecificScriptFlagsOnMapReload
	ret ; useless

ResetMapVariables::
	ld a, HIGH(vBGMap0)
	ld [wMapViewVRAMPointer + 1], a
	xor a
	ld [wMapViewVRAMPointer], a
	ldh [hSCY], a
	ldh [hSCX], a
	ld [wWalkCounter], a
	ld [wUnusedCurMapTilesetCopy], a
	ld [wSpriteSetID], a
	ld [wWalkBikeSurfStateCopy], a
	ret

CopyMapViewToVRAM::
; copy current map view to VRAM
	ld de, vBGMap0
CopyMapViewToVRAM2:
	ld hl, wTileMap
	ld b, SCREEN_HEIGHT
.vramCopyLoop
	ld c, SCREEN_WIDTH
.vramCopyInnerLoop
	ld a, [hli]
	ld [de], a
	inc e
	dec c
	jr nz, .vramCopyInnerLoop
	ld a, TILEMAP_WIDTH - SCREEN_WIDTH
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	dec b
	jr nz, .vramCopyLoop
	ret

; function to switch to the ROM bank that a map is stored in
; Input: a = map number
SwitchToMapRomBank::
	push hl
	push bc
	ld c, a
	ld b, $00
	ld a, BANK(MapHeaderBanks)
	call BankswitchHome
	ld hl, MapHeaderBanks
	add hl, bc
	ld a, [hl]
	ldh [hMapROMBank], a
	call BankswitchBack
	ldh a, [hMapROMBank]
	call BankswitchCommon
	pop bc
	pop hl
	ret

GetMapHeaderPointer::
	ldh a, [hLoadedROMBank]
	push af
	ld a, BANK(MapHeaderPointers)
	call BankswitchCommon
	push de
	ld a, [wCurMap]
	ld e, a
	ld d, $0
	ld hl, MapHeaderPointers
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop de
	pop af
	jp BankswitchCommon

IgnoreInputForHalfSecond:
	ld a, 30
	ld [wIgnoreInputCounter], a
	ld hl, wStatusFlags5
	ld a, [hl]
	or (1 << BIT_DISABLE_JOYPAD) | (1 << BIT_UNKNOWN_5_2) | (1 << BIT_UNKNOWN_5_1)
	ld [hl], a ; set ignore input bit
	ret

ResetUsingStrengthOutOfBattleBit:
	ld hl, wStatusFlags1
	res BIT_STRENGTH_ACTIVE, [hl]
	ret

ForceBikeOrSurf::
	ld b, BANK(RedSprite)
	ld hl, LoadPlayerSpriteGraphics ; in bank 0
	call Bankswitch
	jp PlayDefaultMusic ; update map/player state?

; Handle the player jumping down
; a ledge in the overworld.
HandleMidJump::
	ld a, [wMovementFlags]
	bit BIT_LEDGE_OR_FISHING, a
	ret z
	farcall _HandleMidJump
	ret

IsSpinning::
	ld a, [wMovementFlags]
	bit BIT_SPINNING, a
	ret z ; no spinning
	farjp LoadSpinnerArrowTiles ; spin while moving

Func_0ffe::
	jpfar IsPlayerTalkingToPikachu

InitSprites::
	ld a, [hli]
	ld [wNumSprites], a ; save the number of sprites
	push hl
	push de
	push bc
	call ZeroSpriteStateData
	call DisableRegularSprites
	ld hl, wMapSpriteData
	ld bc, $20
	xor a
	call FillMemory
	pop bc
	pop de
	pop hl
	ld a, [wNumSprites]
	and a ; are there any sprites?
	ret z ; don't copy sprite data if not
	ld b, a
	ld c, $0
	ld de, wSprite01StateData1
; copy sprite stuff?
.loadSpriteLoop
	ld a, [hli]
	ld [de], a ; x#SPRITESTATEDATA1_PICTUREID
	inc d
	ld a, e
	add $4
	ld e, a
	ld a, [hli]
	ld [de], a ; x#SPRITESTATEDATA2_MAPY
	inc e
	ld a, [hli]
	ld [de], a ; x#SPRITESTATEDATA2_MAPX
	inc e
	ld a, [hli]
	ld [de], a ; x#SPRITESTATEDATA2_MOVEMENTBYTE1
	ld a, [hli]
	ldh [hLoadSpriteTemp1], a ; save movement byte 2
	ld a, [hli]
	ldh [hLoadSpriteTemp2], a ; save text ID and flags byte
	push bc
	call LoadSprite
	pop bc
	dec d
	ld a, e
	add $a
	ld e, a
	inc c
	inc c
	dec b
	jr nz, .loadSpriteLoop
	ret

ZeroSpriteStateData::
; zero out sprite state data for sprites 01-14
; sprite 15 is used for Pikachu
	ld hl, wSprite01StateData1
	ld de, wSprite01StateData2
	xor a
	ld b, 14 * $10
.loop
	ld [hli], a
	ld [de], a
	inc e
	dec b
	jr nz, .loop
	ret