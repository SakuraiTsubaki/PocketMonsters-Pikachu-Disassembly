DrawHPBar::
	push hl
	push de
IF DEF(_REV0)
	push bc
ENDC
	ld a, $71
	ld [hli], a
	ld a, $62
	ld [hli], a
	push hl
	ld a, $63
.draw
	ld [hli], a
	dec d
	jr nz, .draw
	ld a, [wHPBarType]
	dec a
	ld a, $6d
	jr z, .ok
	dec a
.ok
	ld [hl], a
	pop hl
	ld a, e
	and a
	jr nz, .fill
	ld a, c
	and a
	jr z, .done
	ld e, 1
.fill
	ld a, e
	sub 8
	jr c, .partial
	ld e, a
	ld a, $6b
	ld [hli], a
	ld a, e
	and a
	jr z, .done
	jr .fill
.partial
	ld a, $63
	add e
	ld [hl], a
.done
IF DEF(_REV0)
	pop bc
ENDC
	pop de
	pop hl
	ret

LoadMonData::
	jpfar LoadMonData_

OverwritewMoves::
	ld hl, wMoves
	ld e, b
	ld d, 0
	add hl, de
	ld a, c
	ld [hl], a
	ret

LoadFlippedFrontSpriteByMonIndex::
	ld a, 1
	ld [wSpriteFlipped], a

LoadFrontSpriteByMonIndex::
	push hl
	ld a, [wPokedexNum]
	push af
	ld a, [wCurPartySpecies]
	ld [wPokedexNum], a
	predef IndexToPokedex
	ld hl, wPokedexNum
	ld a, [hl]
	pop bc
	ld [hl], b
	and a
	pop hl
	jr z, .invalidDexNumber
	cp NUM_POKEMON + 1
	jr c, .validDexNumber
.invalidDexNumber
	ld a, RHYDON
	ld [wCurPartySpecies], a
	ret
.validDexNumber
	push hl
	ld de, vFrontPic
	call LoadMonFrontSprite
	pop hl
	ldh a, [hLoadedROMBank]
	push af
	ld a, BANK(CopyUncompressedPicToHL)
	call BankswitchCommon
	xor a
	ldh [hStartTileID], a
	call CopyUncompressedPicToHL
	xor a
	ld [wSpriteFlipped], a
	pop af
IF DEF(_REV0)
	call BankswitchCommon
	ret
ELSE
	jp BankswitchCommon
ENDC

PlayCry::
	push bc
	ld b, a
	ld a, [wLowHealthAlarm]
	push af
	xor a
	ld [wLowHealthAlarm], a
	ld a, b
	call GetCryData
	call PlaySound
	call WaitForSoundToFinish
	pop af
	ld [wLowHealthAlarm], a
	pop bc
	ret

GetCryData::
	dec a
	ld c, a
	ld b, 0
	ld hl, CryData
	add hl, bc
	add hl, bc
	add hl, bc
	ld a, BANK(CryData)
	call BankswitchHome
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld [wFrequencyModifier], a
	ld a, [hl]
	ld [wTempoModifier], a
	call BankswitchBack
	ld a, b
	ld c, CRY_SFX_START
	rlca
	add b
	add c
	ret

DisplayPartyMenu::
	ldh a, [hTileAnimations]
	push af
	xor a
	ldh [hTileAnimations], a
	call GBPalWhiteOutWithDelay3
	call ClearSprites
	call PartyMenuInit
	call DrawPartyMenu
	jp HandlePartyMenuInput

GoBackToPartyMenu::
	ldh a, [hTileAnimations]
	push af
	xor a
	ldh [hTileAnimations], a
	call PartyMenuInit
	call RedrawPartyMenu
	jp HandlePartyMenuInput

PartyMenuInit::
	ld a, 1
	call BankswitchHome
	call LoadHpBarAndStatusTilePatterns
	ld hl, wStatusFlags5
	set BIT_NO_TEXT_DELAY, [hl]
	xor a
	ld [wMonDataLocation], a
	ld [wMenuWatchMovingOutOfBounds], a
	ld hl, wTopMenuItemY
	inc a
	ld [hli], a
	xor a
	ld [hli], a
	ld a, [wPartyAndBillsPCSavedMenuItem]
	push af
	ld [hli], a
	inc hl
	ld a, [wPartyCount]
	and a
	jr z, .storeMaxMenuItemID
	dec a
.storeMaxMenuItemID
	ld [hli], a
	ld a, [wForcePlayerToChooseMon]
	and a
	ld a, PAD_A | PAD_B
	jr z, .next
	xor a
	ld [wForcePlayerToChooseMon], a
	inc a
.next
	ld [hli], a
	pop af
	ld [hl], a
	ret

HandlePartyMenuInput::
	ld a, 1
	ld [wMenuWrappingEnabled], a
	ld a, $40
	ld [wPartyMenuAnimMonEnabled], a
	call HandleMenuInput_
	push af
	bit B_PAD_B, a
	ld a, $0
	ld [wPartyMenuAnimMonEnabled], a
	ld a, [wCurrentMenuItem]
	ld [wPartyAndBillsPCSavedMenuItem], a
	jr nz, .asm_1258
	ld a, [wCurrentMenuItem]
	ld [wWhichPokemon], a
	callfar IsThisPartyMonStarterPikachu
	jr nc, .asm_1258
	call CheckPikachuFollowingPlayer
	jr nz, .asm_128f
.asm_1258
	pop af
	call PlaceUnfilledArrowMenuCursor
	ld b, a
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	ld a, [wMenuItemToSwap]
	and a
	jp nz, .swappingPokemon
	pop af
	ldh [hTileAnimations], a
	bit B_PAD_B, b
	jr nz, .noPokemonChosen
	ld a, [wPartyCount]
	and a
	jr z, .noPokemonChosen
	ld a, [wCurrentMenuItem]
	ld [wWhichPokemon], a
	ld hl, wPartySpecies
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld [wCurPartySpecies], a
	ld [wBattleMonSpecies2], a
	call BankswitchBack
	and a
	ret
.asm_128f
	pop af
	ld hl, PartyMenuText_12cc
	call PrintText
	xor a
	ld [wMenuItemToSwap], a
	pop af
	ldh [hTileAnimations], a
.noPokemonChosen
	call BankswitchBack
	scf
	ret
.swappingPokemon
	bit B_PAD_B, b
	jr z, .handleSwap
	farcall ErasePartyMenuCursors
	xor a
	ld [wMenuItemToSwap], a
	ld [wPartyMenuTypeOrMessageID], a
	call RedrawPartyMenu
	jp HandlePartyMenuInput
.handleSwap
	ld a, [wCurrentMenuItem]
	ld [wWhichPokemon], a
	farcall SwitchPartyMon
	jp HandlePartyMenuInput

PartyMenuText_12cc::
IF DEF(_JAPAN)
	text "あれ？　いない⋯"
	prompt
ELSE
	text_far _SleepingPikachuText1
	text_end
ENDC

DrawPartyMenu::
	ld hl, DrawPartyMenu_
	jr DrawPartyMenuCommon

RedrawPartyMenu::
	ld hl, RedrawPartyMenu_

DrawPartyMenuCommon:
	ld b, BANK(RedrawPartyMenu_)
	jp Bankswitch

PrintStatusCondition::
	push de
	dec de
	dec de
	ld a, [de]
	ld b, a
	dec de
	ld a, [de]
	or b
	pop de
	jr nz, PrintStatusConditionNotFainted
IF DEF(_JAPAN)
	ld_hli_a_string "ひんし"
ELSE
	ld_hli_a_string "FNT"
ENDC
	and a
	ret

PrintStatusConditionNotFainted::
IF DEF(_REV0)
	homecall_sf PrintStatusAilment
	ret
ELSE
	homejp_sf PrintStatusAilment
ENDC

PrintLevel::
	ld a, '<LV>'
	ld [hli], a
	ld c, 2
	ld a, [wLoadedMonLevel]
	cp 100
	jr c, PrintLevelCommon
	dec hl
	inc c
	jr PrintLevelCommon

PrintLevelFull::
	ld a, '<LV>'
	ld [hli], a
	ld c, 3
	ld a, [wLoadedMonLevel]

PrintLevelCommon::
	ld [wTempByteValue], a
	ld de, wTempByteValue
	ld b, LEFT_ALIGN | 1
	jp PrintNumber

GetwMoves::
	ld hl, wMoves
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	ret

GetMonHeader::
	ldh a, [hLoadedROMBank]
	push af
	ld a, BANK(BaseStats)
	call BankswitchCommon
	push bc
	push de
	push hl
	ld a, [wPokedexNum]
	push af
	ld a, [wCurSpecies]
	ld [wPokedexNum], a
	ld de, FossilKabutopsPic
	ld b, $66
	cp FOSSIL_KABUTOPS
	jr z, .specialID
	ld de, GhostPic
	cp MON_GHOST
	jr z, .specialID
	ld de, FossilAerodactylPic
	ld b, $77
	cp FOSSIL_AERODACTYL
	jr z, .specialID
	predef IndexToPokedex
	ld a, [wPokedexNum]
	dec a
	ld bc, BASE_DATA_SIZE
	ld hl, BaseStats
	call AddNTimes
	ld de, wMonHeader
	ld bc, BASE_DATA_SIZE
	call CopyData
	jr .done
.specialID
	ld hl, wMonHSpriteDim
	ld [hl], b
	inc hl
	ld [hl], e
	inc hl
	ld [hl], d
.done
	ld a, [wCurSpecies]
	ld [wMonHIndex], a
	pop af
	ld [wPokedexNum], a
	pop hl
	pop de
	pop bc
	pop af
	call BankswitchCommon
	ret

GetPartyMonName2::
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks

GetPartyMonName::
	push hl
	push bc
	call SkipFixedLengthTextEntries
	ld de, wNameBuffer
	push de
	ld bc, NAME_LENGTH
	call CopyData
	pop de
	pop bc
	pop hl
	ret
