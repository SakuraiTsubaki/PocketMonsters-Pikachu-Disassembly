PrepareOAMData::
; Determine OAM data for currently visible sprites and write it to wShadowOAM.
; International Yellow adds CGB tile/palette handling; Japanese Yellow uses the DMG/SGB path.

	ld a, [wUpdateSpritesEnabled]
	dec a
	jr z, .updateEnabled

	cp -1
	ret nz
	ld [wUpdateSpritesEnabled], a
	jp HideSprites

.updateEnabled
	xor a
	ldh [hOAMBufferOffset], a

.spriteLoop
	ldh [hSpriteOffset2], a

	ld e, a
	ld d, HIGH(wSpriteStateData1)

	ld a, [de]
	and a
	jp z, .nextSprite

	inc e
	inc e
	ld a, [de]
	ld [wSavedSpriteImageIndex], a
	cp $ff
	jr nz, .visible

	call GetSpriteScreenXY
	jr .nextSprite

.visible
	cp $a0
	jr c, .usefacing
	ld a, $0
	jr .next

.usefacing
	and $f

.next
	ld c, a
	ld b, 0
	ld hl, SpriteFacingAndAnimationTable
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a

	push de
	inc d
	ld a, e
	add $5
	ld e, a
	ld a, [de]
	and $80
	ldh [hSpritePriority], a
	pop de

	call GetSpriteScreenXY

	ldh a, [hOAMBufferOffset]
	add [hl]
	cp $a0
	jr z, .hidden
	jr nc, .asm_4a41
.hidden
	call Func_4a7b
	ld [wSavedSpriteImageIndex], a
	ldh a, [hOAMBufferOffset]

	ld e, a
	ld d, HIGH(wShadowOAM)

.tileLoop
	ld a, [hli]
	ld c, a
.loop
	ldh a, [hSpriteScreenY]
	add $10
	add [hl]
	ld [de], a
	inc hl
	inc e
	ldh a, [hSpriteScreenX]
	add $8
	add [hl]
	ld [de], a
	inc hl
	inc e
	ld a, [wSavedSpriteImageIndex]
	add [hl]
IF !DEF(_JAPAN)
	cp $80
	jr c, .tileReady
	ld b, a
	ldh a, [hPikachuSpriteVRAMOffset]
	add b
.tileReady
ENDC
	ld [de], a
	inc hl
	inc e
	ld a, [hl]
	bit BIT_SPRITE_UNDER_GRASS, a
	jr z, .skipPriority
	ldh a, [hSpritePriority]
	or [hl]
.skipPriority
	and $f0
IF !DEF(_JAPAN)
	bit B_OAM_PAL1, a
	jr z, .spriteUsesOBP0
	or OAM_HIGH_PALS
.spriteUsesOBP0
ENDC
	ld [de], a
	inc hl
	inc e
	dec c
	jr nz, .loop

	ld a, e
	ldh [hOAMBufferOffset], a
.nextSprite
	ldh a, [hSpriteOffset2]
	add $10
	cp LOW($100)
	jp nz, .spriteLoop

.asm_4a41
	ld a, [wMovementFlags]
	bit BIT_LEDGE_OR_FISHING, a
	ld c, LOW(wShadowOAMEnd)
	jr z, .clear
	ld c, LOW(wShadowOAMSprite36)

.clear
	ldh a, [hOAMBufferOffset]
	cp c
	ret nc
	ld l, a
	ld h, HIGH(wShadowOAM)
	ld a, c
	ld de, $4
	ld b, $a0
.clearLoop
	ld [hl], b
	add hl, de
	cp l
	jr nz, .clearLoop
	ret

GetSpriteScreenXY:
	inc e
	inc e
	ld a, [de]
	ldh [hSpriteScreenY], a
	inc e
	inc e
	ld a, [de]
	ldh [hSpriteScreenX], a
	ld a, 4
	add e
	ld e, a
	ldh a, [hSpriteScreenY]
	add 4
	and $f0
	ld [de], a
	inc e
	ldh a, [hSpriteScreenX]
	and $f0
	ld [de], a
	ret

Func_4a7b:
	push bc
	ld a, [wSavedSpriteImageIndex]
	swap a
	and $f
	cp $b
	jr nz, .notFourTileSprite
	ld a, $a * 12 + 4
	jr .done

.notFourTileSprite
	add a
	add a
	ld c, a
	add a
	add c
.done
	pop bc
	ret

INCLUDE "engine/gfx/oam_dma.asm"

_IsTilePassable::
	ld hl, wTilesetCollisionPtr
	ld a, [hli]
	ld h, [hl]
	ld l, a
.loop
	ld a, [hli]
	cp $ff
	jr z, .tileNotPassable
	cp c
	jr nz, .loop
	xor a
	ret
.tileNotPassable
	scf
	ret

INCLUDE "data/tilesets/collision_tile_ids.asm"
