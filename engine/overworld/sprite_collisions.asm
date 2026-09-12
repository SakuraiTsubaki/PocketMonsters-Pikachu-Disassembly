_UpdateSprites::
	ld h, HIGH(wSpriteStateData1)
	inc h
	ld a, SPRITESTATEDATA2_IMAGEBASEOFFSET
.spriteLoop
	ld l, a
	sub SPRITESTATEDATA2_IMAGEBASEOFFSET
	ld c, a
	ldh [hCurrentSpriteOffset], a
	ld a, [hl]
	and a
	jr z, .skipSprite
	push hl
	push de
	push bc
	call .updateCurrentSprite
	pop bc
	pop de
	pop hl
.skipSprite
	ld a, l
	add $10
	cp SPRITESTATEDATA2_IMAGEBASEOFFSET
	jr nz, .spriteLoop
	ret
.updateCurrentSprite
	ldh a, [hCurrentSpriteOffset]
	and a
	jp z, UpdatePlayerSprite
	cp $f0
	jp z, SpawnPikachu
	ld a, [hl]

UpdateNonPlayerSprite:
	dec a
	swap a
	ldh [hTilePlayerStandingOn], a
	ld a, [wNPCMovementScriptSpriteOffset]
	ld b, a
	ldh a, [hCurrentSpriteOffset]
	cp b
	jr nz, .unequal
	jp DoScriptedNPCMovement
.unequal
	jp UpdateNPCSprite

DetectCollisionBetweenSprites:
	ld h, HIGH(wSpriteStateData1)
	ldh a, [hCurrentSpriteOffset]
	ld l, a

	ld a, [hl]
	and a
	ret z

	ld a, l
	add 3
	ld l, a

	ld a, [hli]
	call SetSpriteCollisionValues

	ld a, [hli]
	add 4
	add b
	and $f0
	or c
	ldh [hCollidingSpriteTempYValue], a

	ld a, [hli]
	call SetSpriteCollisionValues
	ld a, [hl]
	add b
	and $f0
	or c
	ldh [hCollidingSpriteTempXValue], a

	ld a, l
	add 7
	ld l, a

	xor a
	ld [hld], a
	ld [hld], a
	ldh a, [hCollidingSpriteTempXValue]
	ld [hld], a
	ldh a, [hCollidingSpriteTempYValue]
	ld [hl], a

	xor a
.loop
	ldh [hCollidingSpriteOffset], a
	swap a
	ld e, a
	ldh a, [hCurrentSpriteOffset]
	cp e
	jp z, .next

	ld d, h
	ld a, [de]
	and a
	jp z, .next

	inc e
	inc e
	ld a, [de]
	inc a
	jp z, .next

	ldh a, [hCurrentSpriteOffset]
	add 10
	ld l, a

	inc e
	ld a, [de]
	call SetSpriteCollisionValues
	inc e
	ld a, [de]
	add 4
	add b
	and $f0
	or c
	sub [hl]
	jr nc, .noCarry1
	cpl
	inc a
.noCarry1
	ldh [hCollidingSpriteTempYValue], a

	push af
	rl c
	pop af
	ccf
	rl c

	ld b, 7
	ld a, [hl]
	and $f
	jr z, .next1
	ld b, 9
.next1
	ldh a, [hCollidingSpriteTempYValue]
	sub b
	ldh [hCollidingSpriteAdjustedDistance], a
	ld a, b
	ldh [hCollidingSpriteTempYValue], a
	jr c, .checkXDistance

	ld b, 7
	dec e
	ld a, [de]
	inc e
	and a
	jr z, .next2
	ld b, 9
.next2
	ldh a, [hCollidingSpriteAdjustedDistance]
	sub b
	jr z, .checkXDistance
	jr nc, .next

.checkXDistance
	inc e
	inc l
	ld a, [de]
	push bc
	call SetSpriteCollisionValues
	inc e
	ld a, [de]
	add b
	and $f0
	or c
	pop bc
	sub [hl]
	jr nc, .noCarry2
	cpl
	inc a
.noCarry2
	ldh [hCollidingSpriteTempXValue], a

	push af
	rl c
	pop af
	ccf
	rl c

	ld b, 7
	ld a, [hl]
	and $f
	jr z, .next3
	ld b, 9
.next3
	ldh a, [hCollidingSpriteTempXValue]
	sub b
	ldh [hCollidingSpriteAdjustedDistance], a
	ld a, b
	ldh [hCollidingSpriteTempXValue], a
	jr c, .collision

	ld b, 7
	dec e
	ld a, [de]
	inc e
	and a
	jr z, .next4
	ld b, 9
.next4
	ldh a, [hCollidingSpriteAdjustedDistance]
	sub b
	jr z, .collision
	jr nc, .next

.collision
	ld a, l
	and $f0
	jr nz, .asm_4cd9
	xor a
	ld [wd433], a
	ldh a, [hCollidingSpriteOffset]
	cp $f
	jr nz, .asm_4cd9
	call Func_4d0a
	jr .asm_4cef
.asm_4cd9
	ldh a, [hCollidingSpriteTempXValue]
	ld b, a
	ldh a, [hCollidingSpriteTempYValue]
	inc l
	cp b
	jr c, .next5
	ld b, %1100
	jr .next6
.next5
	ld b, %0011
.next6
	ld a, c
	and b
	or [hl]
	ld [hl], a
	ld a, c
	inc l
	inc l
.asm_4cef
	ldh a, [hCollidingSpriteOffset]
	ld de, SpriteCollisionBitTable
	add a
	add e
	ld e, a
	jr nc, .noCarry3
	inc d
.noCarry3
	ld a, [de]
	or [hl]
	ld [hli], a
	inc de
	ld a, [de]
	or [hl]
	ld [hl], a

.next
	ldh a, [hCollidingSpriteOffset]
	inc a
	cp $10
	jp nz, .loop
	ret

Func_4d0a:
	ldh a, [hCollidingSpriteTempXValue]
	ld b, a
	ldh a, [hCollidingSpriteTempYValue]
	inc l
	cp b
	jr c, .asm_4d17
	ld b, %1100
	jr .asm_4d19
.asm_4d17
	ld b, %11
.asm_4d19
	ld a, c
	and b
	ld [wd433], a
	ld a, c
	inc l
	inc l
	ret

SetSpriteCollisionValues:
	and a
	ld b, 0
	ld c, 0
	jr z, .done
	ld c, 9
	cp -1
	jr z, .ok
	ld c, 7
	ld a, 0
.ok
	ld b, a
.done
	ret

SpriteCollisionBitTable:
FOR n, $10
	bigdw 1 << n
ENDR
