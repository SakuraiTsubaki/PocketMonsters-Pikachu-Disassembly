UpdatePlayerSprite:
	ld a, [wSpritePlayerStateData2WalkAnimationCounter]
	and a
	jr z, .checkIfTextBoxInFrontOfSprite
	cp $ff
	jr z, .disableSprite
	dec a
	ld [wSpritePlayerStateData2WalkAnimationCounter], a
	jr .disableSprite
.checkIfTextBoxInFrontOfSprite
	lda_coord 8, 9
	ldh [hTilePlayerStandingOn], a
	cp MAP_TILESET_SIZE
	jr c, .lowerLeftTileIsMapTile
.disableSprite
	ld a, $ff
	ld [wSpritePlayerStateData1ImageIndex], a
	ret
.lowerLeftTileIsMapTile
	ld a, [wUpdateSpritesEnabled]
	push af
	ld a, $ff
	ld [wUpdateSpritesEnabled], a
	call DetectCollisionBetweenSprites
	pop af
	ld [wUpdateSpritesEnabled], a
	ld h, HIGH(wSpriteStateData1)
	ld a, [wWalkCounter]
	and a
	jr nz, .moving
	ld a, [wPlayerMovingDirection]
	bit PLAYER_DIR_BIT_DOWN, a
	jr z, .checkIfUp
	xor a
	jr .next
.checkIfUp
	bit PLAYER_DIR_BIT_UP, a
	jr z, .checkIfLeft
	ld a, SPRITE_FACING_UP
	jr .next
.checkIfLeft
	bit PLAYER_DIR_BIT_LEFT, a
	jr z, .checkIfRight
	ld a, SPRITE_FACING_LEFT
	jr .next
.checkIfRight
	bit PLAYER_DIR_BIT_RIGHT, a
	jr z, .notMoving
	ld a, SPRITE_FACING_RIGHT
.next
	ld [wSpritePlayerStateData1FacingDirection], a
	ld a, [wFontLoaded]
	bit BIT_FONT_LOADED, a
	jr z, .moving
.notMoving
	xor a
	ld [wSpritePlayerStateData1IntraAnimFrameCounter], a
	ld [wSpritePlayerStateData1AnimFrameCounter], a
	call Func_4e32
	jr .skipSpriteAnim
.moving
	ld a, [wMovementFlags]
	bit BIT_SPINNING, a
	jr nz, .skipSpriteAnim
	call Func_5274
	call Func_4e32
.skipSpriteAnim
	ldh a, [hTilePlayerStandingOn]
	ld c, a
	ld a, [wGrassTile]
	cp c
	ld a, 0
	jr nz, .next2
	ld a, OAM_PRIO
.next2
	ld [wSpritePlayerStateData2GrassPriority], a
	ret

Func_4e32:
	ld a, [wSpritePlayerStateData1AnimFrameCounter]
	ld b, a
	ld a, [wSpritePlayerStateData1FacingDirection]
	add b
	ld [wSpritePlayerStateData1ImageIndex], a
	ret

UpdateNPCSprite:
	ldh a, [hCurrentSpriteOffset]
	swap a
	dec a
	add a
	ld hl, wMapSpriteData
	add l
	ld l, a
	ld a, [hl]
	ld [wCurSpriteMovement2], a
	ld h, HIGH(wSpriteStateData1)
	ldh a, [hCurrentSpriteOffset]
	ld l, a
	inc l
	ld a, [hl]
	and a
	jp z, InitializeSpriteStatus
	call CheckSpriteAvailability
	ret c
	ld h, HIGH(wSpriteStateData1)
	ldh a, [hCurrentSpriteOffset]
	ld l, a
	inc l
	ld a, [hl]
	bit BIT_FACE_PLAYER, a
	jp nz, MakeNPCFacePlayer
	ld b, a
	ld a, [wFontLoaded]
	bit BIT_FONT_LOADED, a
	jp nz, NotYetMoving
	ld a, b
	cp $2
	jp z, UpdateSpriteMovementDelay
	cp $3
	jp z, UpdateSpriteInWalkingAnimation
	cp $4
	jp z, Func_5357
	ld a, [wWalkCounter]
	and a
	ret nz
	call InitializeSpriteScreenPosition
	ld h, HIGH(wSpriteStateData2)
	ldh a, [hCurrentSpriteOffset]
	add $6
	ld l, a
	ld a, [hl]
	inc a
	jp z, .randomMovement
	inc a
	jp z, .randomMovement
	dec a
	ld [hl], a
	dec a
	push hl
	ld hl, wNPCNumScriptedSteps
	dec [hl]
	pop hl
	ld de, wNPCMovementDirections
	call LoadDEPlusA
	cp NPC_CHANGE_FACING
	jp z, ChangeFacingDirection
	cp STAY
	jr nz, .next
	ld [hl], a
	ld hl, wStatusFlags5
	res BIT_SCRIPTED_NPC_MOVEMENT, [hl]
	xor a
	ld [wSimulatedJoypadStatesIndex], a
	ld [wUnusedOverrideSimulatedJoypadStatesIndex], a
	ret
.next
	cp WALK
	jr nz, .asm_4ecb
	ld [hl], $1
	ld de, wNPCMovementDirections
	call LoadDEPlusA
.asm_4ecb
	push af
	call Func_5288
	pop bc
	ld a, b
	jr nc, .determineDirection
	ret
.randomMovement
	call GetTileSpriteStandsOn
	call Random
.determineDirection
	ld b, a
	ld a, [wCurSpriteMovement2]
	cp DOWN
	jr z, .moveDown
	cp UP
	jr z, .moveUp
	cp LEFT
	jr z, .moveLeft
	cp RIGHT
	jr z, .moveRight
	ld a, b
	cp NPC_MOVEMENT_UP
	jr nc, .notDown
	ld a, [wCurSpriteMovement2]
	cp LEFT_RIGHT
	jr z, .moveLeft
.moveDown
	ld de, 2 * SCREEN_WIDTH
	add hl, de
	lb de, 1, 0
	lb bc, 4, SPRITE_FACING_DOWN
	jr TryWalking
.notDown
	cp NPC_MOVEMENT_LEFT
	jr nc, .notUp
	ld a, [wCurSpriteMovement2]
	cp LEFT_RIGHT
	jr z, .moveRight
.moveUp
	ld de, -2 * SCREEN_WIDTH
	add hl, de
	lb de, -1, 0
	lb bc, 8, SPRITE_FACING_UP
	jr TryWalking
.notUp
	cp NPC_MOVEMENT_RIGHT
	jr nc, .notLeft
	ld a, [wCurSpriteMovement2]
	cp UP_DOWN
	jr z, .moveUp
.moveLeft
	dec hl
	dec hl
	lb de, 0, -1
	lb bc, 2, SPRITE_FACING_LEFT
	jr TryWalking
.notLeft
	ld a, [wCurSpriteMovement2]
	cp UP_DOWN
	jr z, .moveDown
.moveRight
	inc hl
	inc hl
	lb de, 0, 1
	lb bc, 1, SPRITE_FACING_RIGHT
	jr TryWalking

ChangeFacingDirection:
	ld de, $0

TryWalking:
	push hl
	call Func_5337
	pop hl
	push de
	ld c, [hl]
	call CanWalkOntoTile
	pop de
	ret c
	call Func_5349
	ldh a, [hCurrentSpriteOffset]
	ld l, a
	ld [hl], $10
	dec h
	inc l
	ld [hl], $3
	jp UpdateSpriteImage

UpdateSpriteInWalkingAnimation:
	call Func_5274
	ldh a, [hCurrentSpriteOffset]
	add $3
	ld l, a
	ld a, [hli]
	ld b, a
	ld a, [hl]
	add b
	ld [hli], a
	ld a, [hli]
	ld b, a
	ld a, [hl]
	add b
	ld [hl], a
	ldh a, [hCurrentSpriteOffset]
	ld l, a
	inc h
	ld a, [hl]
	dec a
	ld [hl], a
	ret nz
	ld a, $6
	add l
	ld l, a
	ld a, [hl]
	cp WALK
	jr nc, .initNextMovementCounter
	ldh a, [hCurrentSpriteOffset]
	inc a
	ld l, a
	dec h
	ld [hl], $1
	ret
.initNextMovementCounter
	call Random
	ldh a, [hCurrentSpriteOffset]
	add $8
	ld l, a
	ldh a, [hRandomAdd]
	and $7f
	ld [hl], a
	dec h
	ldh a, [hCurrentSpriteOffset]
	inc a
	ld l, a
	ld [hl], $2
	inc l
	inc l
	xor a
	ld b, [hl]
	ld [hli], a
	inc l
	ld c, [hl]
	ld [hl], a
	ret
