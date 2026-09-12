PrintSafariZoneBattleText:
	ld hl, wSafariBaitFactor
	ld a, [hl]
	and a
	jr z, .no_bait
	dec [hl]
	ld hl, SafariZoneEatingText
	jr .done
.no_bait
	dec hl
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ld hl, SafariZoneAngryText
	jr nz, .done
	push hl
	ld a, [wEnemyMonSpecies]
	ld [wCurSpecies], a
	call GetMonHeader
	ld a, [wMonHCatchRate]
	ld [wEnemyMonActualCatchRate], a
	pop hl
.done
	push hl
	call LoadScreenTilesFromBuffer1
	pop hl
	jp PrintText

SafariZoneEatingText:
IF DEF(_JAPAN)
	text "やせいの@"
	text_ram wEnemyMonNick
	text "は"
	line "エサを　たべてる！"
	prompt
ELSE
	text_far _SafariZoneEatingText
	text_end
ENDC

SafariZoneAngryText:
IF DEF(_JAPAN)
	text "やせいの@"
	text_ram wEnemyMonNick
	text "は"
	line "おこってる！"
	prompt
ELSE
	text_far _SafariZoneAngryText
	text_end
ENDC
