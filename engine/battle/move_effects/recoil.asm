; Bank 04 fine-grained family reconstruction.
; Common source lines are emitted once; only source-family differences are conditional.
; JP: Narishma-gb/pokeyellow-jp @ f282e72ae26232790fdb780aa5a5db7ec8ebf572
; INT: pret/pokeyellow @ e89ead154b9968aa50eed9328ff2b38b6c194382

RecoilEffect_:
	ldh a, [hWhoseTurn]
	and a
	ld a, [wPlayerMoveNum]
	ld hl, wBattleMonMaxHP
	jr z, .recoilEffect
	ld a, [wEnemyMoveNum]
	ld hl, wEnemyMonMaxHP
.recoilEffect
	ld d, a
	ld a, [wDamage]
	ld b, a
	ld a, [wDamage + 1]
	ld c, a
	srl b
	rr c
	ld a, d
	cp STRUGGLE ; struggle deals 50% recoil damage
	jr z, .gotRecoilDamage
	srl b
	rr c
.gotRecoilDamage
	ld a, b
	or c
	jr nz, .updateHP
	inc c ; minimum recoil damage is 1
.updateHP
; subtract HP from user due to the recoil damage
	ld a, [hli]
IF DEF(_JAPAN)
	ld [wHPBarMaxHP + 1], a
ELSE
	ld [wHPBarMaxHP+1], a
ENDC
	ld a, [hl]
	ld [wHPBarMaxHP], a
	push bc
	ld bc, wBattleMonHP - wBattleMonMaxHP
	add hl, bc
	pop bc
	ld a, [hl]
	ld [wHPBarOldHP], a
	sub c
	ld [hld], a
	ld [wHPBarNewHP], a
	ld a, [hl]
IF DEF(_JAPAN)
	ld [wHPBarOldHP + 1], a
ELSE
	ld [wHPBarOldHP+1], a
ENDC
	sbc b
	ld [hl], a
IF DEF(_JAPAN)
	ld [wHPBarNewHP + 1], a
ELSE
	ld [wHPBarNewHP+1], a
ENDC
	jr nc, .getHPBarCoords
; if recoil damage is higher than the Pokemon's HP, set its HP to 0
	xor a
	ld [hli], a
	ld [hl], a
	ld hl, wHPBarNewHP
	ld [hli], a
	ld [hl], a
.getHPBarCoords
	hlcoord 10, 9
	ldh a, [hWhoseTurn]
	and a
	ld a, $1
	jr z, .updateHPBar
	hlcoord 2, 2
	xor a
.updateHPBar
	ld [wHPBarType], a
	predef UpdateHPBar2
	ld hl, HitWithRecoilText
	jp PrintText
IF DEF(_JAPAN)

ELSE
ENDC
HitWithRecoilText:
IF DEF(_JAPAN)
	text "<USER>は　こうげきの"
	line "はんどうを　うけた！"
	prompt
ELSE
	text_far _HitWithRecoilText
	text_end
ENDC
