DoScriptedNPCMovement:
	ld a, [wStatusFlags5]
	bit BIT_SCRIPTED_MOVEMENT_STATE, a
	ret z
	ld hl, wStatusFlags4
	bit BIT_INIT_SCRIPTED_MOVEMENT, [hl]
	set BIT_INIT_SCRIPTED_MOVEMENT, [hl]
	jp z, InitScriptedNPCMovement
	ld hl, wNPCMovementDirections2
	ld a, [wNPCMovementDirections2Index]
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	ld a, [hl]
	cp NPC_MOVEMENT_UP
	jr nz, .checkIfMovingDown
	call GetSpriteScreenYPointer
	ld c, SPRITE_FACING_UP
	ld a, -2
	jr .move
.checkIfMovingDown
	cp NPC_MOVEMENT_DOWN
	jr nz, .checkIfMovingLeft
	call GetSpriteScreenYPointer
	ld c, SPRITE_FACING_DOWN
	ld a, 2
	jr .move
.checkIfMovingLeft
	cp NPC_MOVEMENT_LEFT
	jr nz, .checkIfMovingRight
	call GetSpriteScreenXPointer
	ld c, SPRITE_FACING_LEFT
	ld a, -2
	jr .move
.checkIfMovingRight
	cp NPC_MOVEMENT_RIGHT
	jr nz, .noMatch
	call GetSpriteScreenXPointer
	ld c, SPRITE_FACING_RIGHT
	ld a, 2
	jr .move
.noMatch
	cp $ff
	ret
.move
	ld b, a
	ld a, [hl]
	add b
	ld [hl], a
	ldh a, [hCurrentSpriteOffset]
	add $9
	ld l, a
	ld a, c
	ld [hl], a
	call AnimScriptedNPCMovement
	ld hl, wScriptedNPCWalkCounter
	dec [hl]
	ret nz
	ld a, 8
	ld [wScriptedNPCWalkCounter], a
	ld hl, wNPCMovementDirections2Index
	inc [hl]
	ret

InitScriptedNPCMovement:
	xor a
	ld [wNPCMovementDirections2Index], a
	ld a, 8
	ld [wScriptedNPCWalkCounter], a
	jp AnimScriptedNPCMovement

GetSpriteScreenYPointer:
	ld a, SPRITESTATEDATA1_YPIXELS
	ld b, a
	jr GetSpriteScreenXYPointerCommon

GetSpriteScreenXPointer:
	ld a, SPRITESTATEDATA1_XPIXELS
	ld b, a

GetSpriteScreenXYPointerCommon:
	ld hl, wSpriteStateData1
	ldh a, [hCurrentSpriteOffset]
	add l
	add b
	ld l, a
	ret

AnimScriptedNPCMovement:
	ld hl, wSpriteStateData2
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA2_IMAGEBASEOFFSET
	ld l, a
	ld a, [hl]
	dec a
	swap a
	ld b, a
	ld hl, wSpriteStateData1
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA1_FACINGDIRECTION
	ld l, a
	ld a, [hl]
	cp SPRITE_FACING_DOWN
	jr z, .anim
	cp SPRITE_FACING_UP
	jr z, .anim
	cp SPRITE_FACING_LEFT
	jr z, .anim
	cp SPRITE_FACING_RIGHT
	jr z, .anim
	ret
.anim
	add b
	ld b, a
	ldh [hSpriteVRAMSlotAndFacing], a
	call AdvanceScriptedNPCAnimFrameCounter
	ld hl, wSpriteStateData1
	ldh a, [hCurrentSpriteOffset]
	add SPRITESTATEDATA1_IMAGEINDEX
	ld l, a
	ldh a, [hSpriteVRAMSlotAndFacing]
	ld b, a
	ldh a, [hSpriteAnimFrameCounter]
	add b
	ld [hl], a
	ret

AdvanceScriptedNPCAnimFrameCounter:
	call Func_5274
	ld h, HIGH(wSpriteStateData1)
	ldh a, [hCurrentSpriteOffset]
	add $8
	ld l, a
	ld a, [hl]
	and $3
	ldh [hSpriteAnimFrameCounter], a
	ret

Func_5274:
	ldh a, [hCurrentSpriteOffset]
	add $7
	ld l, a
	ld h, HIGH(wSpriteStateData1)
	ld a, [hl]
	inc a
	and $3
	ld [hl], a
	ret nz
	inc l
	ld a, [hl]
	inc a
	and $3
	ld [hl], a
	ret

Func_5288:
	cp $5
	jr z, .asm_52af
	cp $4
	jr z, .asm_52aa
	cp $6
	jr z, .asm_52b4
	cp $7
	jr z, .asm_52b9
	cp $11
	jr z, .asm_52c3
	cp $12
	jr z, .asm_52be
	cp $13
	jr z, .asm_52c8
	cp $14
	jr z, .asm_52cd
	xor a
	ret
.asm_52aa
	call Func_531f
	jr .asm_52e6
.asm_52af
	call Func_5325
	jr .asm_52e6
.asm_52b4
	call Func_5331
	jr .asm_52e6
.asm_52b9
	call Func_532b
	jr .asm_52e6
.asm_52be
	call Func_531f
	jr .asm_52fa
.asm_52c3
	call Func_5325
	jr .asm_52fa
.asm_52c8
	call Func_5331
	jr .asm_52fa
.asm_52cd
	call Func_532b
	jr .asm_52fa
.asm_52d2
	call Func_531f
	jr .asm_530b
.asm_52d7
	call Func_5325
	jr .asm_530b
.asm_52dc
	call Func_5331
	jr .asm_530b
.asm_52e1
	call Func_532b
	jr .asm_530b

.asm_52e6
	call Func_5337
	call Func_5349
	ldh a, [hCurrentSpriteOffset]
	ld l, a
	ld [hl], $8
	dec h
	inc l
	ld [hl], $4
	call UpdateSpriteImage
	scf
	ret

.asm_52fa
	call Func_5337
	ldh a, [hCurrentSpriteOffset]
	ld l, a
	ld [hl], $8
	dec h
	inc l
	ld [hl], $3
	call UpdateSpriteImage
	scf
	ret

.asm_530b
	call Func_5337
	call Func_5349
	ldh a, [hCurrentSpriteOffset]
	ld l, a
	ld [hl], $8
	dec h
	inc l
	ld [hl], $3
	call UpdateSpriteImage
	scf
	ret

Func_531f:
	lb de, 1, 0
	ld c, SPRITE_FACING_DOWN
	ret

Func_5325:
	lb de, -1, 0
	ld c, SPRITE_FACING_UP
	ret

Func_532b:
	lb de, 0, 1
	ld c, SPRITE_FACING_RIGHT
	ret

Func_5331:
	lb de, 0, -1
	ld c, SPRITE_FACING_LEFT
	ret

Func_5337:
	ldh a, [hCurrentSpriteOffset]
	add $9
	ld l, a
	ld h, HIGH(wSpriteStateData1)
	ld [hl], c
	ldh a, [hCurrentSpriteOffset]
	add $3
	ld l, a
	ld [hl], d
	inc l
	inc l
	ld [hl], e
	ret

Func_5349:
	ld h, HIGH(wSpriteStateData2)
	ldh a, [hCurrentSpriteOffset]
	add $4
	ld l, a
	ld a, [hl]
	add d
	ld [hli], a
	ld a, [hl]
	add e
	ld [hl], a
	ret

Func_5357:
	call Func_5274
	ldh a, [hCurrentSpriteOffset]
	add $3
	ld l, a
	ld h, HIGH(wSpriteStateData1)
	ld a, [hli]
	add a
	ld b, a
	ld a, [hl]
	add b
	ld [hli], a
	ld a, [hli]
	add a
	ld b, a
	ld a, [hl]
	add b
	ld [hl], a
	ldh a, [hCurrentSpriteOffset]
	ld l, a
	ld h, HIGH(wSpriteStateData2)
	dec [hl]
	ret nz
	ld a, $6
	add l
	ld l, a
	ld a, [hl]
	cp $fe
	jr nc, .asm_5386
	ldh a, [hCurrentSpriteOffset]
	inc a
	ld l, a
	ld h, HIGH(wSpriteStateData1)
	ld [hl], $1
	ret
.asm_5386
	call Random
	ldh a, [hCurrentSpriteOffset]
	add $8
	ld l, a
	ld h, HIGH(wSpriteStateData2)
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
