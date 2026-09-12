UpdateSpriteMovementDelay:
	ld h, HIGH(wSpriteStateData2)
	ldh a, [hCurrentSpriteOffset]
	add $6
	ld l, a
	ld a, [hl]
	inc l
	inc l
	cp WALK
	jr nc, .tickMoveCounter
	ld [hl], $0
	jr .moving
.tickMoveCounter
	dec [hl]
	jr nz, NotYetMoving
.moving
	dec h
	ldh a, [hCurrentSpriteOffset]
	inc a
	ld l, a
	ld [hl], $1
NotYetMoving:
	ld h, HIGH(wSpriteStateData1)
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA1_ANIMFRAMECOUNTER
	ld l, a
	ld [hl], $0
	jp UpdateSpriteImage

MakeNPCFacePlayer:
	ld a, [wStatusFlags3]
	bit BIT_NO_NPC_FACE_PLAYER, a
	jr nz, NotYetMoving
	res BIT_FACE_PLAYER, [hl]
	ld a, [wPlayerDirection]
	bit PLAYER_DIR_BIT_UP, a
	jr z, .notFacingDown
	ld c, SPRITE_FACING_DOWN
	jr .facingDirectionDetermined
.notFacingDown
	bit PLAYER_DIR_BIT_DOWN, a
	jr z, .notFacingUp
	ld c, SPRITE_FACING_UP
	jr .facingDirectionDetermined
.notFacingUp
	bit PLAYER_DIR_BIT_LEFT, a
	jr z, .notFacingRight
	ld c, SPRITE_FACING_RIGHT
	jr .facingDirectionDetermined
.notFacingRight
	ld c, SPRITE_FACING_LEFT
.facingDirectionDetermined
	ldh a, [hCurrentSpriteOffset]
	add $9
	ld l, a
	ld [hl], c
	jr NotYetMoving

InitializeSpriteStatus:
	ld [hl], $1
	inc l
	ld [hl], $ff
	inc h
	ldh a, [hCurrentSpriteOffset]
	add $2
	ld l, a
	ld a, $8
	ld [hli], a
	ld [hl], a
IF DEF(_JAPAN)
	ret
ELSE
	call InitializeSpriteScreenPosition
	ret
ENDC

InitializeSpriteScreenPosition:
	ld h, HIGH(wSpriteStateData2)
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA2_MAPY
	ld l, a
	ld a, [wYCoord]
	ld b, a
	ld a, [hl]
	sub b
IF DEF(_JAPAN)
	swap a
ELSE
	call Func_5033
ENDC
	sub $4
	dec h
	ld [hli], a
	inc h
	ld a, [wXCoord]
	ld b, a
	ld a, [hli]
	sub b
IF DEF(_JAPAN)
	swap a
ELSE
	call Func_5033
ENDC
	dec h
	ld [hl], a
	ret

IF !DEF(_JAPAN)
Func_5033:
	jr nc, .positive
	cpl
	inc a
	swap a
	cpl
	inc a
	ret
.positive
	swap a
	ret
ENDC

CheckSpriteAvailability:
	predef IsObjectHidden
	ldh a, [hIsToggleableObjectOff]
	and a
	jp nz, .spriteInvisible
	ld h, HIGH(wSpriteStateData2)
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA2_MOVEMENTBYTE1
	ld l, a
	ld a, [hl]
	cp WALK
	jr c, .skipXVisibilityTest
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA2_MAPY
	ld l, a
	ld b, [hl]
	ld a, [wYCoord]
	cp b
	jr z, .skipYVisibilityTest
	jr nc, .spriteInvisible
	add SCREEN_HEIGHT / 2 - 1
	cp b
	jr c, .spriteInvisible
.skipYVisibilityTest
	inc l
	ld b, [hl]
	ld a, [wXCoord]
	cp b
	jr z, .skipXVisibilityTest
	jr nc, .spriteInvisible
	add SCREEN_WIDTH / 2 - 1
	cp b
	jr c, .spriteInvisible
.skipXVisibilityTest
	call GetTileSpriteStandsOn
	ld d, MAP_TILESET_SIZE
	ld a, [hli]
	cp d
	jr nc, .spriteInvisible
	ld a, [hld]
	cp d
	jr nc, .spriteInvisible
	ld bc, -SCREEN_WIDTH
	add hl, bc
	ld a, [hli]
	cp d
	jr nc, .spriteInvisible
	ld a, [hl]
	cp d
	jr c, .spriteVisible
.spriteInvisible
	ld h, HIGH(wSpriteStateData1)
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA1_IMAGEINDEX
	ld l, a
	ld [hl], $ff
	scf
	jr .done
.spriteVisible
	ld c, a
	ld a, [wWalkCounter]
	and a
	jr nz, .done
	call UpdateSpriteImage
	inc h
	ldh a, [hCurrentSpriteOffset]
	add $7
	ld l, a
	ld a, [wGrassTile]
	cp c
	ld a, 0
	jr nz, .notInGrass
	ld a, OAM_PRIO
.notInGrass
	ld [hl], a
	and a
.done
	ret

UpdateSpriteImage:
	ld h, HIGH(wSpriteStateData1)
	ldh a, [hCurrentSpriteOffset]
	add $8
	ld l, a
	ld a, [hli]
	ld b, a
	ld a, [hl]
	add b
	ld b, a
	ldh a, [hTilePlayerStandingOn]
	add b
	ld b, a
	ldh a, [hCurrentSpriteOffset]
	add $2
	ld l, a
	ld [hl], b
	ret

CanWalkOntoTile:
	ld h, HIGH(wSpriteStateData2)
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA2_MOVEMENTBYTE1
	ld l, a
	ld a, [hl]
	cp WALK
	jr nc, .notScripted
	and a
	ret
.notScripted
	call _IsTilePassable
	jr c, .impassable
	ld h, HIGH(wSpriteStateData2)
	ldh a, [hCurrentSpriteOffset]
	add $6
	ld l, a
	ld a, [hl]
	inc a
	jr z, .impassable
	ld h, HIGH(wSpriteStateData1)
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA1_YPIXELS
	ld l, a
	ld a, [hli]
	add $4
	add d
	cp $80
	jr nc, .impassable
	inc l
	ld a, [hl]
	add e
	cp $90
	jr nc, .impassable
	push de
	push bc
	ld a, [wUpdateSpritesEnabled]
	push af
	ld a, $ff
	ld [wUpdateSpritesEnabled], a
	call DetectCollisionBetweenSprites
	pop af
	ld [wUpdateSpritesEnabled], a
	pop bc
	pop de
	ld h, HIGH(wSpriteStateData1)
	ldh a, [hCurrentSpriteOffset]
	add $c
	ld l, a
	ld a, [hl]
	and b
	jr nz, .impassable
	ld h, HIGH(wSpriteStateData2)
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA2_YDISPLACEMENT
	ld l, a
	ld a, [hli]
	bit 7, d
	jr nz, .upwards
	add d
	cp $5
IF DEF(_JAPAN)
	jr c, .impassable
ENDC
	jr .checkHorizontal
.upwards
	sub $1
	jr c, .impassable
.checkHorizontal
	ld d, a
	ld a, [hl]
	bit 7, e
	jr nz, .left
	add e
	cp $5
IF DEF(_JAPAN)
	jr c, .impassable
ENDC
	jr .passable
.left
	sub $1
	jr c, .impassable
.passable
	ld [hld], a
	ld [hl], d
	and a
	ret
.impassable
	ld h, HIGH(wSpriteStateData1)
	ldh a, [hCurrentSpriteOffset]
	inc a
	ld l, a
	ld [hl], $2
	inc l
	inc l
	xor a
	ld [hli], a
	inc l
	ld [hl], a
	inc h
	ldh a, [hCurrentSpriteOffset]
	add $8
	ld l, a
	call Random
	ldh a, [hRandomAdd]
	and $7f
	ld [hl], a
	scf
	ret

GetTileSpriteStandsOn:
	ld h, HIGH(wSpriteStateData1)
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA1_YPIXELS
	ld l, a
	ld a, [hli]
	add $4
IF DEF(_JAPAN)
	and $f0
ELSE
	and $f8
ENDC
	srl a
	ld c, a
	ld b, $0
	inc l
	ld a, [hl]
	srl a
	srl a
	srl a
	add SCREEN_WIDTH
	ld d, $0
	ld e, a
	hlcoord 0, 0
	add hl, bc
	add hl, bc
	add hl, bc
	add hl, bc
	add hl, bc
	add hl, de
	ret

LoadDEPlusA:
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	ld a, [de]
	ret
