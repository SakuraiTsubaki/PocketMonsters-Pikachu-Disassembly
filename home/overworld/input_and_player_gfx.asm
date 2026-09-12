	ret

AreInputsSimulated::
	ld a, [wStatusFlags5]
	bit BIT_SCRIPTED_MOVEMENT_STATE, a
	ret z
; if simulating button presses
	ldh a, [hJoyHeld]
	ld b, a
	ld a, [wOverrideSimulatedJoypadStatesMask] ; bit mask for button presses that override simulated ones
	and b
	ret nz ; return if the simulated button presses are overridden
	call GetSimulatedInput
	jr nc, .doneSimulating
	ldh [hJoyHeld], a ; store simulated button press in joypad state
	and a
	ret nz
	ldh [hJoyPressed], a
	ldh [hJoyReleased], a
	ret

; if done simulating button presses
.doneSimulating
	xor a
	ld [wUnusedOverrideSimulatedJoypadStatesIndex], a
	ld [wSimulatedJoypadStatesIndex], a
	ld [wSimulatedJoypadStatesEnd], a
	ld [wJoyIgnore], a
	ldh [hJoyHeld], a
	ld hl, wMovementFlags
	ld a, [hl]
	and (1 << BIT_SPINNING) | (1 << BIT_LEDGE_OR_FISHING) | (1 << 5) | (1 << 4) | (1 << 3)
	ld [hl], a
	ld hl, wStatusFlags5
	res BIT_SCRIPTED_MOVEMENT_STATE, [hl]
	ret

GetSimulatedInput::
	ld hl, wSimulatedJoypadStatesIndex
	dec [hl]
	ld a, [hl]
	cp $ff
	jr z, .endofsimulatedinputs ; if the end of the simulated button presses has been reached
	push de
	ld e, a
	ld d, $0
	ld hl, wSimulatedJoypadStatesEnd
	add hl, de
	ld a, [hl]
	pop de
	scf
	ret

.endofsimulatedinputs
	and a
	ret


; function to check the tile ahead to determine if the character should get on land or keep surfing
; sets carry if there is a collision and clears carry otherwise
; This function had a bug in Red/Blue, but it was fixed in Yellow.
CollisionCheckOnWater::
	ld a, [wStatusFlags5]
	bit BIT_SCRIPTED_MOVEMENT_STATE, a
	jp nz, .noCollision ; return and clear carry if button presses are being simulated
	ld a, [wPlayerDirection] ; the direction that the player is trying to go in
	ld d, a
	ld a, [wSpritePlayerStateData1CollisionData]
	and d ; check if a sprite is in the direction the player is trying to go
	jr nz, .collision
	ld hl, TilePairCollisionsWater
	call CheckForJumpingAndTilePairCollisions
	jr c, .collision
	predef GetTileAndCoordsInFrontOfPlayer ; get tile in front of player (puts it in c and [wTileInFrontOfPlayer])
	callfar IsNextTileShoreOrWater
	jr c, .noCollision
	ld a, [wTileInFrontOfPlayer] ; tile in front of player
	ld c, a
	call IsTilePassable
	jr nc, .stopSurfing
.collision
	ld a, [wChannelSoundIDs + CHAN5]
	cp SFX_COLLISION ; check if collision sound is already playing
	jr z, .setCarry
	ld a, SFX_COLLISION
	call PlaySound ; play collision sound (if it's not already playing)
.setCarry
	scf
	jr .done
; check if Vermilion Dock tileset
	ld a, [wCurMapTileset]
	cp SHIP_PORT
	jr nz, .noCollision ; keep surfing if it's not the boarding platform tile
	jr .stopSurfing ; if it is the boarding platform tile, stop surfing
.stopSurfing ; based game freak
	ld a, $3
	ld [wPikachuSpawnState], a
	ld hl, wPikachuOverworldStateFlags
	set 5, [hl]
	xor a
	ld [wWalkBikeSurfState], a
	call LoadPlayerSpriteGraphics
	call PlayDefaultMusic
	jr .noCollision

.noCollision ; ...and they do the same mistake twice
	and a
.done
	ret

RunMapScript::
	push hl
	push de
	push bc
	farcall TryPushingBoulder
	ld a, [wMiscFlags]
	bit BIT_BOULDER_DUST, a
	jr z, .afterBoulderEffect
	farcall DoBoulderDustAnimation
.afterBoulderEffect
	pop bc
	pop de
	pop hl
	call RunNPCMovementScript
	ld a, [wCurMap]
	call SwitchToMapRomBank
	ld hl, wCurMapScriptPtr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, .return
	push de
	jp hl
.return
	ret

LoadWalkingPlayerSpriteGraphics::
; new sprite copy stuff
	xor a
	ld [wd472], a
	ld b, BANK(RedSprite)
	ld de, RedSprite
	jr LoadPlayerSpriteGraphicsCommon

LoadSurfingPlayerSpriteGraphics2::
	ld a, [wd472]
	and a
	jr z, .asm_0d75
	dec a
	jr z, LoadSurfingPlayerSpriteGraphics
	dec a
	jr z, .asm_0d7c
.asm_0d75
	ld a, [wPikachuSpawnStateFlags]
	bit BIT_PIKACHU_SPAWN_SURFING, a
	jr z, LoadSurfingPlayerSpriteGraphics
.asm_0d7c
	ld b, BANK(SurfingPikachuSprite)
	ld de, SurfingPikachuSprite
	jr LoadPlayerSpriteGraphicsCommon

LoadSurfingPlayerSpriteGraphics::
	ld b, BANK(SeelSprite)
	ld de, SeelSprite
	jr LoadPlayerSpriteGraphicsCommon

LoadBikePlayerSpriteGraphics::
	ld b, BANK(RedBikeSprite)
	ld de, RedBikeSprite

LoadPlayerSpriteGraphicsCommon::
	ld hl, vNPCSprites
	push de
	push hl
	push bc
	ld c, $c
	call CopyVideoData
	pop bc
	pop hl
	pop de
	ld a, $c0
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	set 3, h ; add $800 ($80 tiles) to hl (1 << 3 == $8)
	ld c, $c
	jp CopyVideoData

; function to load data from the map header
LoadMapHeader::
	farcall MarkTownVisitedAndLoadToggleableObjects
	jr asm_0dbd

Func_0db5:: ; unreferenced
	farcall LoadToggleableObjectData
asm_0dbd:
	ld a, [wCurMapTileset]
	ld [wUnusedCurMapTilesetCopy], a