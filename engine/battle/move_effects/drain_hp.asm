DrainHPEffect_:
	ld hl, wDamage
	ld a, [hl]
	srl a
	ld [hli], a
	ld a, [hl]
	rr a
	ld [hld], a
	or [hl]
	jr nz, .getAttackerHP
	inc hl
	inc [hl]
.getAttackerHP
	ld hl, wBattleMonHP
	ld de, wBattleMonMaxHP
	ldh a, [hWhoseTurn]
	and a
	jp z, .addDamageToAttackerHP
	ld hl, wEnemyMonHP
	ld de, wEnemyMonMaxHP
.addDamageToAttackerHP
	ld bc, wHPBarOldHP + 1
	ld a, [hli]
	ld [bc], a
	ld a, [hl]
	dec bc
	ld [bc], a
	ld a, [de]
	dec bc
	ld [bc], a
	inc de
	ld a, [de]
	dec bc
	ld [bc], a
	ld a, [wDamage + 1]
	ld b, [hl]
	add b
	ld [hld], a
	ld [wHPBarNewHP], a
	ld a, [wDamage]
	ld b, [hl]
	adc b
	ld [hli], a
	ld [wHPBarNewHP + 1], a
	jr c, .capToMaxHP
	ld a, [hld]
	ld b, a
	ld a, [de]
	dec de
	sub b
	ld a, [hli]
	ld b, a
	ld a, [de]
	inc de
	sbc b
	jr nc, .next
.capToMaxHP
	ld a, [de]
	ld [hld], a
	ld [wHPBarNewHP], a
	dec de
	ld a, [de]
	ld [hli], a
	ld [wHPBarNewHP + 1], a
	inc de
.next
	ldh a, [hWhoseTurn]
	and a
	hlcoord 10, 9
	ld a, $1
	jr z, .next2
	hlcoord 2, 2
	xor a
.next2
	ld [wHPBarType], a
	predef UpdateHPBar2
	predef DrawPlayerHUDAndHPBar
	predef DrawEnemyHUDAndHPBar
	callfar ReadPlayerMonCurHPAndStatus
	ld hl, SuckedHealthText
	ldh a, [hWhoseTurn]
	and a
	ld a, [wPlayerMoveEffect]
	jr z, .next3
	ld a, [wEnemyMoveEffect]
.next3
	cp DREAM_EATER_EFFECT
	jr nz, .printText
	ld hl, DreamWasEatenText
.printText
	jp PrintText

IF DEF(_JAPAN)
SuckedHealthText:
	text "<TARGET>から"
	line "たいりょくを　すいとった！"
	prompt

DreamWasEatenText:
	text "<TARGET>の"
	line "ゆめを　くった！"
	prompt
ELSE
SuckedHealthText:
	text_far _SuckedHealthText
	text_end

DreamWasEatenText:
	text_far _DreamWasEatenText
	text_end
ENDC
