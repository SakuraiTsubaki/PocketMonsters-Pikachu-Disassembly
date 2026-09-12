SetDebugNewGameParty:
	ld de, DebugNewGameParty
.loop
	ld a, [de]
	cp -1
	ret z
	ld [wCurPartySpecies], a
	inc de
	ld a, [de]
	ld [wCurEnemyLevel], a
	inc de
	call AddPartyMon
	jr .loop

DebugNewGameParty:
	db SNORLAX, 80
	db PERSIAN, 80
	db JIGGLYPUFF, 15
	db STARTER_PIKACHU, 5
	db -1

PrepareNewGameDebug:
IF !DEF(_JAPAN) && DEF(_DEBUG)
	xor a
	ld [wMonDataLocation], a
	dec a
	ld [wTownVisitedFlag], a
	ld [wTownVisitedFlag + 1], a
	ld a, ~(1 << BIT_EARTHBADGE)
	ld [wObtainedBadges], a
	call SetDebugNewGameParty
	ld a, SURF
	ld hl, wPartyMon4Moves + 2
	ld [hl], a
	ld hl, wPartyMon1Moves
	ld a, FLY
	ld [hli], a
	ld a, CUT
	ld [hli], a
	ld a, SURF
	ld [hli], a
	ld a, STRENGTH
	ld [hl], a
	ld hl, wNumBagItems
	ld de, DebugNewGameItemsList
.items_loop
	ld a, [de]
	cp -1
	jr z, .items_end
	ld [wCurItem], a
	inc de
	ld a, [de]
	inc de
	ld [wItemQuantity], a
	call AddItemToInventory
	jr .items_loop
.items_end
	ld hl, wPokedexOwned
	call DebugSetPokedexEntries
	ld hl, wPokedexSeen
	call DebugSetPokedexEntries
	SetEvent EVENT_GOT_POKEDEX
	ld hl, wRivalStarter
	ASSERT wRivalStarter + 2 == wPlayerStarter
	ld a, RIVAL_STARTER_JOLTEON
	ld [hli], a
	ld a, NUM_POKEMON
	ld [hli], a
	ld a, STARTER_PIKACHU
	ld [hl], a
	ld hl, wPlayerMoney
	ld a, $99
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ret

DebugSetPokedexEntries:
IF NUM_POKEMON / 8 != 0
	ld b, NUM_POKEMON / 8
	ld a, %11111111
.loop
	ld [hli], a
	dec b
	jr nz, .loop
ENDC
IF NUM_POKEMON % 8 != 0
	ld [hl], (1 << (NUM_POKEMON % 8)) - 1
ENDC
	ret

DebugNewGameItemsList:
	db MASTER_BALL, 99
	db TOWN_MAP, 1
	db BICYCLE, 1
	db FULL_RESTORE, 99
	db ESCAPE_ROPE, 99
	db RARE_CANDY, 99
	db SECRET_KEY, 1
	db CARD_KEY, 1
	db FULL_HEAL, 99
	db REVIVE, 99
	db FRESH_WATER, 99
	db S_S_TICKET, 1
	db LIFT_KEY, 1
	db PP_UP, 99
	db -1

DebugUnusedList:
	db OLD_AMBER, 1
	db DOME_FOSSIL, 1
	db HELIX_FOSSIL, 1
	db X_ACCURACY, 99
	db DIRE_HIT, 99
	db FRESH_WATER, 1
	db S_S_TICKET, 1
	db GOLD_TEETH, 1
	db COIN_CASE, 1
	db SILPH_SCOPE, 1
	db POKE_FLUTE, 1
	db LIFT_KEY, 1
	db ETHER, 99
	db MAX_ETHER, 99
	db ELIXER, 99
	db MAX_ELIXER, 99
	db TM_RAZOR_WIND, 10
	db TM_HORN_DRILL, 10
	db TM_TAKE_DOWN, 10
	db TM_BLIZZARD, 10
	db TM_HYPER_BEAM, 10
	db TM_SOLARBEAM, 10
	db TM_DRAGON_RAGE, 10
	db TM_MIMIC, 10
	db TM_BIDE, 10
	db TM_METRONOME, 10
	db TM_SELFDESTRUCT, 10
	db TM_SWIFT, 10
	db TM_SOFTBOILED, 10
	db TM_DREAM_EATER, 10
	db TM_REST, 10
	db TM_SUBSTITUTE, 10
	db -1
ELSE
	ret
ENDC
