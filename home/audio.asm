PlayDefaultMusic::
	call WaitForSoundToFinish
	xor a
	ld c, a
	ld d, a
	ld [wLastMusicSoundID], a
	jr PlayDefaultMusicCommon

PlayDefaultMusicFadeOutCurrent::
	ld c, 10
	ld d, 0
	ld a, [wStatusFlags4]
	bit BIT_BATTLE_OVER_OR_BLACKOUT, a
	jr z, PlayDefaultMusicCommon
	xor a
	ld [wLastMusicSoundID], a
	ld c, 8
	ld d, c

PlayDefaultMusicCommon::
	ld a, [wWalkBikeSurfState]
	and a
	jr z, .walking
	cp $2
	jr z, .surfing
	call CheckForNoBikingMusicMap
	jr c, .walking
	ld a, MUSIC_BIKE_RIDING
	jr .next
.surfing
	ld a, MUSIC_SURFING
.next
	ld b, a
	ld a, d
	and a
	ld a, BANK(Music_BikeRiding)
	jr nz, .next2
	ld [wAudioROMBank], a
.next2
	ld [wAudioSavedROMBank], a
	jr .next3
.walking
	ld a, [wMapMusicSoundID]
	ld b, a
	call CompareMapMusicBankWithCurrentBank
	jr c, .next4
.next3
	ld a, [wLastMusicSoundID]
	cp b
	ret z
.next4
	ld a, c
	ld [wAudioFadeOutControl], a
	ld a, b
	ld [wLastMusicSoundID], a
	ld [wNewSoundID], a
	jp PlaySound

CheckForNoBikingMusicMap::
	ld a, [wCurMap]
	cp ROUTE_23
	jr z, .found
	cp VICTORY_ROAD_1F
	jr z, .found
	cp VICTORY_ROAD_2F
	jr z, .found
	cp VICTORY_ROAD_3F
	jr z, .found
	cp INDIGO_PLATEAU
	jr z, .found
	and a
	ret
.found
	scf
	ret

UpdateMusic6Times::
	ld c, 6
UpdateMusicCTimes::
.loop
	push bc
	push hl
	farcall Audio1_UpdateMusic
	pop hl
	pop bc
	dec c
	jr nz, .loop
	ret

CompareMapMusicBankWithCurrentBank::
	ld a, [wMapMusicROMBank]
	ld e, a
	ld a, [wAudioROMBank]
	cp e
	jr nz, .differentBanks
	ld [wAudioSavedROMBank], a
	and a
	ret
.differentBanks
	ld a, c
	and a
	ld a, e
	jr nz, .next
	ld [wAudioROMBank], a
.next
	ld [wAudioSavedROMBank], a
	scf
	ret

PlayMusic::
	ld b, a
	ld [wNewSoundID], a
	xor a
	ld [wAudioFadeOutControl], a
	ld a, c
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, b
	jr PlaySound

Func_2223::
	xor a
	ld [wChannelSoundIDs + CHAN5], a
	ld [wChannelSoundIDs + CHAN6], a
	ld [wChannelSoundIDs + CHAN7], a
	ld [wChannelSoundIDs + CHAN8], a
	ldh [rAUD1SWEEP], a
	ret

StopAllMusic::
	ld a, SFX_STOP_ALL_MUSIC
	ld [wNewSoundID], a

PlaySound::
	push hl
	push de
	push bc
	ld b, a
	ld a, [wNewSoundID]
	and a
	jr z, .next
	xor a
	ld [wChannelSoundIDs + CHAN5], a
	ld [wChannelSoundIDs + CHAN6], a
	ld [wChannelSoundIDs + CHAN7], a
	ld [wChannelSoundIDs + CHAN8], a
.next
	ld a, [wAudioFadeOutControl]
	and a
	jr z, .noFadeOut
	ld a, [wNewSoundID]
	and a
	jr z, .done
	xor a
	ld [wNewSoundID], a
	ld a, [wLastMusicSoundID]
	cp $ff
	jr nz, .fadeOut
	xor a
	ld [wAudioFadeOutControl], a
.noFadeOut
	xor a
	ld [wNewSoundID], a
	call DetermineAudioFunction
	jr .done
.fadeOut
	ld a, b
	ld [wLastMusicSoundID], a
	ld a, [wAudioFadeOutControl]
	ld [wAudioFadeOutCounterReloadValue], a
	ld [wAudioFadeOutCounter], a
	ld a, b
	ld [wAudioFadeOutControl], a
.done
	pop bc
	pop de
	pop hl
	ret

GetNextMusicByte::
	ldh a, [hLoadedROMBank]
	push af
	ld a, [wAudioROMBank]
	call BankswitchCommon
	ld d, $0
	ld a, c
	add a
	ld e, a
	ld hl, wChannelCommandPointers
	add hl, de
	ld a, [hli]
	ld e, a
	ld a, [hld]
	ld d, a
	ld a, [de]
	inc de
	ld [hl], e
	inc hl
	ld [hl], d
	ld e, a
	pop af
	call BankswitchCommon
	ld a, e
	ret

InitMusicVariables::
	push hl
	push de
	push bc
	homecall Audio2_InitMusicVariables
	pop bc
	pop de
	pop hl
	ret

InitSFXVariables::
	push hl
	push de
	push bc
	homecall Audio2_InitSFXVariables
	pop bc
	pop de
	pop hl
	ret

StopAllAudio::
	push hl
	push de
	push bc
	homecall Audio2_StopAllAudio
	pop bc
	pop de
	pop hl
	ret

DetermineAudioFunction::
	ldh a, [hLoadedROMBank]
	push af
	ld a, [wAudioROMBank]
IF DEF(_JAPAN) && DEF(_REV0)
	ldh [hLoadedROMBank], a
	ld [rROMB], a
ELSE
	call BankswitchCommon
ENDC
	cp BANK(Audio1_PlaySound)
	jr nz, .checkForAudio2
	ld a, b
	call Audio1_PlaySound
	jr .done
.checkForAudio2
	cp BANK(Audio2_PlaySound)
	jr nz, .checkForAudio3
	ld a, b
	call Audio2_PlaySound
	jr .done
.checkForAudio3
	cp BANK(Audio3_PlaySound)
	jr nz, .audio4
	ld a, b
	call Audio3_PlaySound
	jr .done
.audio4
	ld a, b
	call Audio4_PlaySound
.done
	pop af
IF DEF(_JAPAN) && DEF(_REV0)
	ldh [hLoadedROMBank], a
	ld [rROMB], a
ELSE
	call BankswitchCommon
ENDC
	ret
