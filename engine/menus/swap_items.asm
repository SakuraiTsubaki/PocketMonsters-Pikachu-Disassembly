HandleItemListSwapping::
	ld a, [wListMenuID]
	cp ITEMLISTMENU
	jp nz, DisplayListMenuIDLoop ; only rearrange item list menus
	push hl
	ld hl, wListPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [wCurrentMenuItem]
	ld b, a
	ld a, [wListScrollOffset]
	add b
	add a
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	pop hl
	inc a
	jp z, DisplayListMenuIDLoop
	ld a, [wMenuItemToSwap]
	and a
	jr nz, .swapItems
	ld a, [wCurrentMenuItem]
	inc a
	ld b, a
	ld a, [wListScrollOffset]
	add b
	ld [wMenuItemToSwap], a
	ld c, 20
	call DelayFrames
	jp DisplayListMenuIDLoop
.swapItems
	ld a, [wCurrentMenuItem]
	inc a
	ld b, a
	ld a, [wListScrollOffset]
	add b
	ld b, a
	ld a, [wMenuItemToSwap]
	cp b
	jp z, DisplayListMenuIDLoop
	dec a
	ld [wMenuItemToSwap], a
	ld c, 20
	call DelayFrames
	push hl
	push de
	ld hl, wListPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld d, h
	ld e, l
	ld a, [wCurrentMenuItem]
	ld b, a
	ld a, [wListScrollOffset]
	add b
	add a
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [wMenuItemToSwap]
	add a
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	ld a, [de]
	ld b, a
	ld a, [hli]
	cp b
	jr z, .swapSameItemType
	ldh [hSwapItemID], a
	ld a, [hld]
	ldh [hSwapItemQuantity], a
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hl], a
	ldh a, [hSwapItemQuantity]
	ld [de], a
	dec de
	ldh a, [hSwapItemID]
	ld [de], a
	xor a
	ld [wMenuItemToSwap], a
	pop de
	pop hl
	jp DisplayListMenuIDLoop
.swapSameItemType
	inc de
	ld a, [hl]
	ld b, a
	ld a, [de]
	add b
	cp 100
	jr c, .combineItemSlots
	sub 99
	ld [de], a
	ld a, 99
	ld [hl], a
	jr .done
.combineItemSlots
	ld [hl], a
	ld hl, wListPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	dec [hl]
	ld a, [hl]
	ld [wListCount], a
	cp 1
	jr nz, .skipSettingMaxMenuItemID
	ld [wMaxMenuItem], a
.skipSettingMaxMenuItemID
	dec de
	ld h, d
	ld l, e
	inc hl
	inc hl
.moveItemsUpLoop
	ld a, [hli]
	ld [de], a
	inc de
	inc a
	jr z, .afterMovingItemsUp
	ld a, [hli]
	ld [de], a
	inc de
	jr .moveItemsUpLoop
.afterMovingItemsUp
	xor a
	ld [wListScrollOffset], a
	ld [wCurrentMenuItem], a
.done
	xor a
	ld [wMenuItemToSwap], a
	pop de
	pop hl
	jp DisplayListMenuIDLoop
