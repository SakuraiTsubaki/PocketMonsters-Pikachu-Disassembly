; Copies [hl, bc) to [de, de + bc - hl).
CopyDataUntil::
	ld a, [hli]
	ld [de], a
	inc de
	ld a, h
	cp b
	jr nz, CopyDataUntil
	ld a, l
	cp c
	jr nz, CopyDataUntil
	ret

RemovePokemon::
	jpfar _RemovePokemon

AddPartyMon::
	push hl
	push de
	push bc
	farcall _AddPartyMon
	pop bc
	pop de
	pop hl
	ret

CalcStats::
	ld c, $0
.statsLoop
	inc c
	call CalcStat
	ldh a, [hMultiplicand + 1]
	ld [de], a
	inc de
	ldh a, [hMultiplicand + 2]
	ld [de], a
	inc de
	ld a, c
	cp NUM_STATS
	jr nz, .statsLoop
	ret

CalcStat::
	push hl
	push de
	push bc
	ld a, b
	ld d, a
	push hl
	ld hl, wMonHeader
	ld b, $0
	add hl, bc
	ld a, [hl]
	ld e, a
	pop hl
	push hl
	sla c
	ld a, d
	and a
	jr z, .statExpDone
	add hl, bc
.statExpLoop
	xor a
	ldh [hMultiplicand], a
	ldh [hMultiplicand + 1], a
	inc b
	ld a, b
	cp $ff
	jr z, .statExpDone
	ldh [hMultiplicand + 2], a
	ldh [hMultiplier], a
	call Multiply
	ld a, [hld]
	ld d, a
	ldh a, [hProduct + 3]
	sub d
	ld a, [hli]
	ld d, a
	ldh a, [hProduct + 2]
	sbc d
	jr c, .statExpLoop
.statExpDone
	srl c
	pop hl
	push bc
	ld bc, MON_DVS - (MON_HP_EXP - 1)
	add hl, bc
	pop bc
	ld a, c
	cp $2
	jr z, .getAttackIV
	cp $3
	jr z, .getDefenseIV
	cp $4
	jr z, .getSpeedIV
	cp $5
	jr z, .getSpecialIV
	push bc
	ld a, [hl]
	swap a
	and $1
	sla a
	sla a
	sla a
	ld b, a
	ld a, [hli]
	and $1
	sla a
	sla a
	add b
	ld b, a
	ld a, [hl]
	swap a
	and $1
	sla a
	add b
	ld b, a
	ld a, [hl]
	and $1
	add b
	pop bc
	jr .calcStatFromIV
.getAttackIV
	ld a, [hl]
	swap a
	and $f
	jr .calcStatFromIV
.getDefenseIV
	ld a, [hl]
	and $f
	jr .calcStatFromIV
.getSpeedIV
	inc hl
	ld a, [hl]
	swap a
	and $f
	jr .calcStatFromIV
.getSpecialIV
	inc hl
	ld a, [hl]
	and $f
.calcStatFromIV
	ld d, $0
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	sla e
	rl d
	srl b
	srl b
	ld a, b
	add e
	jr nc, .noCarry2
	inc d
.noCarry2
	ldh [hMultiplicand + 2], a
	ld a, d
	ldh [hMultiplicand + 1], a
	xor a
	ldh [hMultiplicand], a
	ld a, [wCurEnemyLevel]
	ldh [hMultiplier], a
	call Multiply
	ldh a, [hMultiplicand]
	ldh [hDividend], a
	ldh a, [hMultiplicand + 1]
	ldh [hDividend + 1], a
	ldh a, [hMultiplicand + 2]
	ldh [hDividend + 2], a
	ld a, $64
	ldh [hDivisor], a
	ld a, $3
	ld b, a
	call Divide
	ld a, c
	cp $1
	ld a, 5
	jr nz, .notHPStat
	ld a, [wCurEnemyLevel]
	ld b, a
	ldh a, [hMultiplicand + 2]
	add b
	ldh [hMultiplicand + 2], a
	jr nc, .noCarry3
	ldh a, [hMultiplicand + 1]
	inc a
	ldh [hMultiplicand + 1], a
.noCarry3
	ld a, 10
.notHPStat
	ld b, a
	ldh a, [hMultiplicand + 2]
	add b
	ldh [hMultiplicand + 2], a
	jr nc, .noCarry4
	ldh a, [hMultiplicand + 1]
	inc a
	ldh [hMultiplicand + 1], a
.noCarry4
	ldh a, [hMultiplicand + 1]
	cp HIGH(MAX_STAT_VALUE) + 1
	jr nc, .overflow
	cp HIGH(MAX_STAT_VALUE)
	jr c, .noOverflow
	ldh a, [hMultiplicand + 2]
	cp LOW(MAX_STAT_VALUE) + 1
	jr c, .noOverflow
.overflow
	ld a, HIGH(MAX_STAT_VALUE)
	ldh [hMultiplicand + 1], a
	ld a, LOW(MAX_STAT_VALUE)
	ldh [hMultiplicand + 2], a
.noOverflow
	pop bc
	pop de
	pop hl
	ret

AddEnemyMonToPlayerParty::
	homecall_sf _AddEnemyMonToPlayerParty
	ret

MoveMon::
	homecall_sf _MoveMon
	ret
