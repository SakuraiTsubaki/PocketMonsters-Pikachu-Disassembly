
DisableRegularSprites::
; disable SPRITESTATEDATA1_IMAGEINDEX (set to $ff) for sprites 01-14
	ld hl, wSprite01StateData1ImageIndex
	ld de, $10
	ld c, $e
.loop
	ld [hl], $ff
	add hl, de
	dec c
	jr nz, .loop
	ret

LoadSprite::
	push hl
	ld b, $0
	ld hl, wMapSpriteData
	add hl, bc
	ldh a, [hLoadSpriteTemp1]
	ld [hli], a ; store movement byte 2 in byte 0 of sprite entry
	ldh a, [hLoadSpriteTemp2]
	ld [hl], a ; this appears pointless, since the value is overwritten immediately after
	ldh a, [hLoadSpriteTemp2]
	ldh [hLoadSpriteTemp1], a
	and $3f
	ld [hl], a ; store text ID in byte 1 of sprite entry
	pop hl
	ldh a, [hLoadSpriteTemp1]
	bit BIT_TRAINER, a
	jr nz, .trainerSprite
	bit BIT_ITEM, a
	jr nz, .itemBallSprite
; for regular sprites
	push hl
	ld hl, wMapSpriteExtraData
	add hl, bc
; zero both bytes, since regular sprites don't use this extra space
	xor a
	ld [hli], a
	ld [hl], a
	pop hl
	ret

.trainerSprite
	ld a, [hli]
	ldh [hLoadSpriteTemp1], a ; save trainer class
	ld a, [hli]
	ldh [hLoadSpriteTemp2], a ; save trainer number (within class)
	push hl
	ld hl, wMapSpriteExtraData
	add hl, bc
	ldh a, [hLoadSpriteTemp1]
	ld [hli], a ; store trainer class in byte 0 of the entry
	ldh a, [hLoadSpriteTemp2]
	ld [hl], a ; store trainer number in byte 1 of the entry
	pop hl
	ret

.itemBallSprite
	ld a, [hli]
	ldh [hLoadSpriteTemp1], a ; save item number
	push hl
	ld hl, wMapSpriteExtraData
	add hl, bc
	ldh a, [hLoadSpriteTemp1]
	ld [hli], a ; store item number in byte 0 of the entry
	xor a
	ld [hl], a ; zero byte 1, since it is not used
	pop hl
	ret

CheckForUserInterruption::
; Return carry if Up+Select+B, Start or A are pressed in c frames.
; Used only in the intro and title screen.
	call DelayFrame

	push bc
	call JoypadLowSensitivity
	pop bc

	ldh a, [hJoyHeld]
	cp PAD_UP + PAD_SELECT + PAD_B
	jr z, .input

	ldh a, [hJoy5]
IF DEF(_DEBUG)
	and PAD_START | PAD_SELECT | PAD_A
ELSE
	and PAD_START | PAD_A
ENDC
	jr nz, .input

	dec c
	jr nz, CheckForUserInterruption

	and a
	ret

.input
	scf
	ret

; function to load position data for destination warp when switching maps
; INPUT:
; a = ID of destination warp within destination map
LoadDestinationWarpPosition::
	ld b, a
	ldh a, [hLoadedROMBank]
	push af
	ld a, [wPredefParentBank]
	ldh [hLoadedROMBank], a
	ld [rROMB], a
	ld a, b
	add a
	add a
	ld c, a
	ld b, 0
	add hl, bc
	ld bc, 4
	ld de, wCurrentTileBlockMapViewPointer
	call CopyData
	pop af
	ldh [hLoadedROMBank], a
	ld [rROMB], a
	ret