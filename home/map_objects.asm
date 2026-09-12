; checks if the player's coordinates match an arrow movement tile's coordinates
; and if so, decodes the RLE movement data
; b = player Y
; c = player X
DecodeArrowMovementRLE::
	ld a, [hli]
	cp $ff
	ret z
	cp b
	jr nz, .nextArrowMovementTileEntry1
	ld a, [hli]
	cp c
	jr nz, .nextArrowMovementTileEntry2
	ld a, [hli]
	ld d, [hl]
	ld e, a
	ld hl, wSimulatedJoypadStatesEnd
	call DecodeRLEList
	dec a
	ld [wSimulatedJoypadStatesIndex], a
	ret
.nextArrowMovementTileEntry1
	inc hl
.nextArrowMovementTileEntry2
	inc hl
	inc hl
	jr DecodeArrowMovementRLE

TextScript_ItemStoragePC::
	call SaveScreenTilesToBuffer2
	ld b, BANK(PlayerPC)
	ld hl, PlayerPC
	jr BankswitchAndContinue

TextScript_BillsPC::
	call SaveScreenTilesToBuffer2
	ld b, BANK(BillsPC_)
	ld hl, BillsPC_
	jr BankswitchAndContinue

TextScript_GameCornerPrizeMenu::
	ld b, BANK(CeladonPrizeMenu)
	ld hl, CeladonPrizeMenu
BankswitchAndContinue::
	call Bankswitch
	jp HoldTextDisplayOpen

TextScript_PokemonCenterPC::
	ld b, BANK(ActivatePC)
	ld hl, ActivatePC
	jr BankswitchAndContinue

StartSimulatingJoypadStates::
	xor a
	ld [wOverrideSimulatedJoypadStatesMask], a
	ld [wSpritePlayerStateData2MovementByte1], a
	ld hl, wStatusFlags5
	set BIT_SCRIPTED_MOVEMENT_STATE, [hl]
	ret

IsItemInBag::
	predef GetQuantityOfItemInBag
	ld a, b
	and a
	ret

IsSurfingPikachuInParty::
	ld a, [wPikachuSpawnStateFlags]
	and ~((1 << BIT_PIKACHU_SPAWN_STARTER) | (1 << BIT_PIKACHU_SPAWN_SURFING))
	ld [wPikachuSpawnStateFlags], a
	ld hl, wPartyMon1
	ld c, PARTY_LENGTH
	ld b, SURF
.loop
	ld a, [hl]
	cp STARTER_PIKACHU
	jr nz, .notPikachu
	push hl
	ld de, $8
	add hl, de
	ld a, [hli]
	cp b
	jr z, .hasSurf
	ld a, [hli]
	cp b
	jr z, .hasSurf
	ld a, [hli]
	cp b
	jr z, .hasSurf
	ld a, [hli]
	cp b
	jr nz, .noSurf
.hasSurf
	ld a, [wPikachuSpawnStateFlags]
	set BIT_PIKACHU_SPAWN_SURFING, a
	ld [wPikachuSpawnStateFlags], a
.noSurf
	pop hl
.notPikachu
	ld de, wPartyMon2 - wPartyMon1
	add hl, de
	dec c
	jr nz, .loop
	call .checkForStarter
	ret

.checkForStarter
	push hl
	push bc
	callfar IsStarterPikachuAliveInOurParty
	pop bc
	pop hl
	ret nc
	ld a, [wPikachuSpawnStateFlags]
	set BIT_PIKACHU_SPAWN_STARTER, a
	ld [wPikachuSpawnStateFlags], a
	ret

DisplayPokedex::
	ld [wPokedexNum], a
	farjp _DisplayPokedex

SetSpriteFacingDirectionAndDelay::
	call SetSpriteFacingDirection
	ld c, 6
	jp DelayFrames

SetSpriteFacingDirection::
	ld a, SPRITESTATEDATA1_FACINGDIRECTION
	ldh [hSpriteDataOffset], a
	call GetPointerWithinSpriteStateData1
	ldh a, [hSpriteFacingDirection]
	ld [hl], a
	ret

SetSpriteImageIndexAfterSettingFacingDirection::
	ld de, SPRITESTATEDATA1_IMAGEINDEX - SPRITESTATEDATA1_FACINGDIRECTION
	add hl, de
	ld [hl], a
	ret

SpriteFunc_34a1::
	ldh a, [hSpriteIndex]
	swap a
	add $e
	ld l, a
	ld h, $c2
	ld c, [hl]
	dec c
	swap c
	ldh a, [hSpriteOffset]
	add c
	ld c, a
	ldh a, [hSpriteHeight]
	swap a
	add $2
	ld l, a
	dec h
	ld [hl], c
	ret

ArePlayerCoordsInArray::
	ld a, [wYCoord]
	ld b, a
	ld a, [wXCoord]
	ld c, a

CheckCoords::
	xor a
	ld [wCoordIndex], a
.loop
	ld a, [hli]
	cp $ff
	jr z, .notInArray
	push hl
	ld hl, wCoordIndex
	inc [hl]
	pop hl
	cp b
	jr z, .compareXCoord
	inc hl
	jr .loop
.compareXCoord
	ld a, [hli]
	cp c
	jr nz, .loop
	scf
	ret
.notInArray
	and a
	ret

CheckBoulderCoords::
	push hl
	ld hl, wSpritePlayerStateData2MapY
	ldh a, [hSpriteIndex]
	swap a
	ld d, $0
	ld e, a
	add hl, de
	ld a, [hli]
	sub $4
	ld b, a
	ld a, [hl]
	sub $4
	ld c, a
	pop hl
	jp CheckCoords

GetPointerWithinSpriteStateData1::
	ld h, HIGH(wSpriteStateData1)
	jr _GetPointerWithinSpriteStateData

GetPointerWithinSpriteStateData2::
	ld h, HIGH(wSpriteStateData2)

_GetPointerWithinSpriteStateData:
	ldh a, [hSpriteDataOffset]
	ld b, a
	ldh a, [hSpriteIndex]
	swap a
	add b
	ld l, a
	ret

DecodeRLEList::
	xor a
	ld [wRLEByteCount], a
.listLoop
	ld a, [de]
	cp $ff
	jr z, .endOfList
	ldh [hRLEByteValue], a
	inc de
	ld a, [de]
	ld b, $0
	ld c, a
	ld a, [wRLEByteCount]
	add c
	ld [wRLEByteCount], a
	ldh a, [hRLEByteValue]
	call FillMemory
	inc de
	jr .listLoop
.endOfList
	ld a, $ff
	ld [hl], a
	ld a, [wRLEByteCount]
	inc a
	ret

SetSpriteMovementBytesToFE::
	push hl
	call GetSpriteMovementByte1Pointer
	ld [hl], $fe
	call GetSpriteMovementByte2Pointer
	ldh a, [hSpriteMovementByte2]
	ld [hl], a
	pop hl
	ret

SetSpriteMovementBytesToFF::
	push hl
	call GetSpriteMovementByte1Pointer
	ld [hl], STAY
	call GetSpriteMovementByte2Pointer
	ld [hl], NONE
	pop hl
	ret

GetSpriteMovementByte1Pointer::
	ld h, HIGH(wSpriteStateData2)
	ldh a, [hSpriteIndex]
	swap a
	add 6
	ld l, a
	ret

GetSpriteMovementByte2Pointer::
	push de
	ld hl, wMapSpriteData
	ldh a, [hSpriteIndex]
	dec a
	add a
	ld e, a
	ld d, 0
	add hl, de
	pop de
	ret
