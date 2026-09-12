; function that performs initialization for DisplayTextID
DisplayTextIDInit::
	xor a
	ld [wListMenuID], a
	ld a, [wAutoTextBoxDrawingControl]
	bit BIT_NO_AUTO_TEXT_BOX, a
	jr nz, .skipDrawingTextBoxBorder
	ldh a, [hTextID]
	and a
	jr nz, .notStartMenu
; if text ID is 0 (i.e. the start menu)
; Note that the start menu text border is also drawn in DrawStartMenu.
	CheckEvent EVENT_GOT_POKEDEX
; start menu with pokedex
IF DEF(_JAPAN)
	hlcoord 12, 0
	lb bc, 14, 6
ELSE
	hlcoord 10, 0
	lb bc, 14, 8
ENDC
	jr nz, .drawTextBoxBorder
; start menu without pokedex
IF DEF(_JAPAN)
	hlcoord 12, 0
	lb bc, 12, 6
ELSE
	hlcoord 10, 0
	lb bc, 12, 8
ENDC
	jr .drawTextBoxBorder
.notStartMenu
	hlcoord 0, 12
	lb bc, 4, 18
.drawTextBoxBorder
	call TextBoxBorder
.skipDrawingTextBoxBorder
	ld hl, wFontLoaded
	set BIT_FONT_LOADED, [hl]
	ld hl, wMiscFlags
	bit BIT_NO_SPRITE_UPDATES, [hl]
	res BIT_NO_SPRITE_UPDATES, [hl]
	jr nz, .skipMovingSprites
	call UpdateSprites
.skipMovingSprites
	ld hl, wSprite01StateData1FacingDirection
	ld c, NUM_SPRITESTATEDATA_STRUCTS - 1
	ld de, SPRITESTATEDATA1_LENGTH
.spriteFacingDirectionCopyLoop
	ld a, [hl]
	inc h
	ld [hl], a
	dec h
	add hl, de
	dec c
	jr nz, .spriteFacingDirectionCopyLoop
	ld hl, wSpritePlayerStateData1ImageIndex
	ld de, SPRITESTATEDATA1_LENGTH
	ASSERT NUM_SPRITESTATEDATA_STRUCTS == SPRITESTATEDATA1_LENGTH
	ld c, e
.spriteStandStillLoop
	ld a, [hl]
	cp $ff
	jr z, .nextSprite
	and $fc
	ld [hl], a
.nextSprite
	add hl, de
	dec c
	jr nz, .spriteStandStillLoop
	ld b, HIGH(vBGMap1)
	call CopyScreenTileBufferToVRAM
	xor a
	ldh [hWY], a
	call LoadFontTilePatterns
	ld a, $01
	ldh [hAutoBGTransferEnabled], a
	ret
