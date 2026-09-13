; The first of four partially duplicated sound engines.

Audio1_UpdateMusic::
	ld c, CHAN1
.loop
	ld b, 0
	ld hl, wChannelSoundIDs
	add hl, bc
	ld a, [hl]
	and a
	jr z, .nextChannel
	ld a, c
	cp CHAN5
	jr nc, .applyAffects
	ld a, [wMuteAudioAndPauseMusic]
	and a
	jr z, .applyAffects
	bit BIT_MUTE_AUDIO, a
	jr nz, .nextChannel
	set BIT_MUTE_AUDIO, a
	ld [wMuteAudioAndPauseMusic], a
	xor a
	ldh [rAUDTERM], a
	ldh [rAUD3ENA], a
	ld a, AUD3ENA_ON
	ldh [rAUD3ENA], a
	jr .nextChannel
.applyAffects
	call Audio1_ApplyMusicAffects
.nextChannel
	ld a, c
	inc c
	cp CHAN8
	jr nz, .loop
	ret

Audio1_ApplyMusicAffects:
	ld b, 0
	ld hl, wChannelNoteDelayCounters
	add hl, bc
	ld a, [hl]
	cp 1
	jp z, Audio1_PlayNextNote
	dec a
	ld [hl], a
	ld a, c
	cp CHAN5
	jr nc, .startChecks
	ld hl, wChannelSoundIDs + CHAN5
	add hl, bc
	ld a, [hl]
	and a
	jr z, .startChecks
	ret
.startChecks
	ld hl, wChannelFlags1
	add hl, bc
	bit BIT_ROTATE_DUTY_CYCLE, [hl]
	jr z, .checkForExecuteMusic
	call Audio1_ApplyDutyCyclePattern
.checkForExecuteMusic
	ld b, 0
	ld hl, wChannelFlags2
	add hl, bc
	bit BIT_EXECUTE_MUSIC, [hl]
	jr nz, .checkForPitchSlide
	ld hl, wChannelFlags1
	add hl, bc
	bit BIT_NOISE_OR_SFX, [hl]
	jr nz, .skipPitchSlideVibrato
.checkForPitchSlide
	ld hl, wChannelFlags1
	add hl, bc
	bit BIT_PITCH_SLIDE_ON, [hl]
	jr z, .checkVibratoDelay
	jp Audio1_ApplyPitchSlide
.checkVibratoDelay
	ld hl, wChannelVibratoDelayCounters
	add hl, bc
	ld a, [hl]
	and a
	jr z, .checkForVibrato
	dec [hl]
.skipPitchSlideVibrato
	ret
.checkForVibrato
	ld hl, wChannelVibratoExtents
	add hl, bc
	ld a, [hl]
	and a
	jr nz, .vibrato
	ret
.vibrato
	ld d, a
	ld hl, wChannelVibratoRates
	add hl, bc
	ld a, [hl]
	and $f
	and a
	jr z, .applyVibrato
	dec [hl]
	ret
.applyVibrato
	ld a, [hl]
	swap [hl]
	or [hl]
	ld [hl], a
	ld hl, wChannelFrequencyLowBytes
	add hl, bc
	ld e, [hl]
	ld hl, wChannelFlags1
	add hl, bc
	bit BIT_VIBRATO_DIRECTION, [hl]
	jr z, .unset
	res BIT_VIBRATO_DIRECTION, [hl]
	ld a, d
	and $f
	ld d, a
	ld a, e
	sub d
	jr nc, .noCarry
	ld a, 0
.noCarry
	jr .done
.unset
	set BIT_VIBRATO_DIRECTION, [hl]
	ld a, d
	and $f0
	swap a
	add e
	jr nc, .done
	ld a, $ff
.done
	ld d, a
	ld b, REG_FREQUENCY_LO
	call Audio1_GetRegisterPointer
	ld [hl], d
	ret

Audio1_PlayNextNote:
	ld hl, wChannelVibratoDelayCounterReloadValues
	add hl, bc
	ld a, [hl]
	ld hl, wChannelVibratoDelayCounters
	add hl, bc
	ld [hl], a
	ld hl, wChannelFlags1
	add hl, bc
	res BIT_PITCH_SLIDE_ON, [hl]
	res BIT_PITCH_SLIDE_DECREASING, [hl]
	ld a, c
	cp $4
	jr nz, .asm_918c
	ld a, [wLowHealthAlarm]
	bit BIT_LOW_HEALTH_ALARM, a
	jr z, .asm_918c
	call Audio1_EnableChannelOutput
	ret
.asm_918c
	call Audio1_sound_ret
	ret

Audio1_sound_ret:
	call Audio1_GetNextMusicByte
	ld d, a
	cp sound_ret_cmd
	jp nz, Audio1_sound_call
	ld b, 0
	ld hl, wChannelFlags1
	add hl, bc
	bit BIT_SOUND_CALL, [hl]
	jr nz, .returnFromCall
	ld a, c
	cp CHAN4
	jr nc, .noiseOrSfxChannel
	jr .disableChannelOutput
.noiseOrSfxChannel
	res BIT_NOISE_OR_SFX, [hl]
	ld hl, wChannelFlags2
	add hl, bc
	res BIT_EXECUTE_MUSIC, [hl]
	cp CHAN7
	jr nz, .skipSfxChannel3
	ld a, AUD3ENA_OFF
	ldh [rAUD3ENA], a
	ld a, AUD3ENA_ON
	ldh [rAUD3ENA], a
.skipSfxChannel3
	jr nz, .dontDisable
	ld a, [wDisableChannelOutputWhenSfxEnds]
	and a
	jr z, .dontDisable
	xor a
	ld [wDisableChannelOutputWhenSfxEnds], a
	jr .disableChannelOutput
.dontDisable
	jr .afterDisable
.returnFromCall
	res BIT_SOUND_CALL, [hl]
	ld d, 0
	ld a, c
	add a
	ld e, a
	ld hl, wChannelCommandPointers
	add hl, de
	push hl
	ld hl, wChannelReturnAddresses
	add hl, de
	ld e, l
	ld d, h
	pop hl
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hl], a
	jp Audio1_sound_ret
.disableChannelOutput
	ld hl, Audio1_HWChannelDisableMasks
	add hl, bc
	ldh a, [rAUDTERM]
	and [hl]
	ldh [rAUDTERM], a
.afterDisable
	ld a, [wChannelSoundIDs + CHAN5]
	cp CRY_SFX_START
	jr nc, .maybeCry
	jr .skipCry
.maybeCry
	ld a, [wChannelSoundIDs + CHAN5]
	cp CRY_SFX_END
	jr z, .skipCry
	jr c, .cry
	jr .skipCry
.cry
	ld a, c
	cp CHAN5
	jr z, .skipRewind
	call Audio1_GoBackOneCommandIfCry
	ret c
.skipRewind
	ld a, [wSavedVolume]
	ldh [rAUDVOL], a
	xor a
	ld [wSavedVolume], a
.skipCry
	ld hl, wChannelSoundIDs
	add hl, bc
	ld [hl], b
	ret

Audio1_sound_call:
	cp sound_call_cmd
	jp nz, Audio1_sound_loop
	call Audio1_GetNextMusicByte
	push af
	call Audio1_GetNextMusicByte
	ld d, a
	pop af
	ld e, a
	push de
	ld d, 0
	ld a, c
	add a
	ld e, a
	ld hl, wChannelCommandPointers
	add hl, de
	push hl
	ld hl, wChannelReturnAddresses
	add hl, de
	ld e, l
	ld d, h
	pop hl
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hld]
	ld [de], a
	pop de
	ld [hl], e
	inc hl
	ld [hl], d
	ld b, 0
	ld hl, wChannelFlags1
	add hl, bc
	set BIT_SOUND_CALL, [hl]
	jp Audio1_sound_ret

Audio1_sound_loop:
	cp sound_loop_cmd
	jp nz, Audio1_note_type
	call Audio1_GetNextMusicByte
	ld e, a
	and a
	jr z, .infiniteLoop
	ld b, 0
	ld hl, wChannelLoopCounters
	add hl, bc
	ld a, [hl]
	cp e
	jr nz, .loopAgain
	ld a, 1
	ld [hl], a
	call Audio1_GetNextMusicByte
	call Audio1_GetNextMusicByte
	jp Audio1_sound_ret
.loopAgain
	inc a
	ld [hl], a
.infiniteLoop
	call Audio1_GetNextMusicByte
	push af
	call Audio1_GetNextMusicByte
	ld b, a
	ld d, 0
	ld a, c
	add a
	ld e, a
	ld hl, wChannelCommandPointers
	add hl, de
	pop af
	ld [hli], a
	ld [hl], b
	jp Audio1_sound_ret

Audio1_note_type:
	and $f0
	cp note_type_cmd
	jp nz, Audio1_toggle_perfect_pitch
	ld a, d
	and $f
	ld b, 0
	ld hl, wChannelNoteSpeeds
	add hl, bc
	ld [hl], a
	ld a, c
	cp CHAN4
	jr z, .noiseChannel
	call Audio1_GetNextMusicByte
	ld d, a
	ld a, c
	cp CHAN3
	jr z, .musicChannel3
	cp CHAN7
	jr nz, .skipChannel3
	ld hl, wSfxWaveInstrument
	jr .channel3
.musicChannel3
	ld hl, wMusicWaveInstrument
.channel3
	ld a, d
	and $f
	ld [hl], a
	ld a, d
	and $30
	sla a
	ld d, a
.skipChannel3
	ld b, 0
	ld hl, wChannelVolumes
	add hl, bc
	ld [hl], d
.noiseChannel
	jp Audio1_sound_ret

Audio1_toggle_perfect_pitch:
	ld a, d
	cp toggle_perfect_pitch_cmd
	jr nz, Audio1_vibrato
	ld b, 0
	ld hl, wChannelFlags1
	add hl, bc
	ld a, [hl]
	xor 1 << BIT_PERFECT_PITCH
	ld [hl], a
	jp Audio1_sound_ret

Audio1_vibrato:
	cp vibrato_cmd
	jr nz, Audio1_pitch_slide
	call Audio1_GetNextMusicByte
	ld b, 0
	ld hl, wChannelVibratoDelayCounters
	add hl, bc
	ld [hl], a
	ld hl, wChannelVibratoDelayCounterReloadValues
	add hl, bc
	ld [hl], a
	call Audio1_GetNextMusicByte
	ld d, a
	and $f0
	swap a
	ld b, 0
	ld hl, wChannelVibratoExtents
	add hl, bc
	srl a
	ld e, a
	adc b
	swap a
	or e
	ld [hl], a
	ld a, d
	and $f
	ld d, a
	ld hl, wChannelVibratoRates
	add hl, bc
	swap a
	or d
	ld [hl], a
	jp Audio1_sound_ret

Audio1_pitch_slide:
	cp pitch_slide_cmd
	jr nz, Audio1_duty_cycle
	call Audio1_GetNextMusicByte
	ld b, 0
	ld hl, wChannelPitchSlideLengthModifiers
	add hl, bc
	ld [hl], a
	call Audio1_GetNextMusicByte
	ld d, a
	and $f0
	swap a
	ld b, a
	ld a, d
	and $f
	call Audio1_CalculateFrequency
	ld b, 0
	ld hl, wChannelPitchSlideTargetFrequencyHighBytes
	add hl, bc
	ld [hl], d
	ld hl, wChannelPitchSlideTargetFrequencyLowBytes
	add hl, bc
	ld [hl], e
	ld b, 0
	ld hl, wChannelFlags1
	add hl, bc
	set BIT_PITCH_SLIDE_ON, [hl]
	call Audio1_GetNextMusicByte
	ld d, a
	jp Audio1_note_length

Audio1_duty_cycle:
	cp duty_cycle_cmd
	jr nz, Audio1_tempo
	call Audio1_GetNextMusicByte
	rrca
	rrca
	and $c0
	ld b, 0
	ld hl, wChannelDutyCycles
	add hl, bc
	ld [hl], a
	jp Audio1_sound_ret

Audio1_tempo:
	cp tempo_cmd
	jr nz, Audio1_stereo_panning
	ld a, c
	cp CHAN5
	jr nc, .sfxChannel
	call Audio1_GetNextMusicByte
	ld [wMusicTempo], a
	call Audio1_GetNextMusicByte
	ld [wMusicTempo + 1], a
	xor a
	ld [wChannelNoteDelayCountersFractionalPart], a
	ld [wChannelNoteDelayCountersFractionalPart + 1], a
	ld [wChannelNoteDelayCountersFractionalPart + 2], a
	ld [wChannelNoteDelayCountersFractionalPart + 3], a
	jr .musicChannelDone
.sfxChannel
	call Audio1_GetNextMusicByte
	ld [wSfxTempo], a
	call Audio1_GetNextMusicByte
	ld [wSfxTempo + 1], a
	xor a
	ld [wChannelNoteDelayCountersFractionalPart + 4], a
	ld [wChannelNoteDelayCountersFractionalPart + 5], a
	ld [wChannelNoteDelayCountersFractionalPart + 6], a
	ld [wChannelNoteDelayCountersFractionalPart + 7], a
.musicChannelDone
	jp Audio1_sound_ret

Audio1_stereo_panning:
	cp stereo_panning_cmd
	jr nz, Audio1_unknownmusic0xef
	call Audio1_GetNextMusicByte
	ld [wStereoPanning], a
	jp Audio1_sound_ret

Audio1_unknownmusic0xef:
	cp unknownmusic0xef_cmd
	jr nz, Audio1_duty_cycle_pattern
	call Audio1_GetNextMusicByte
	push bc
	ld b, a
	call DetermineAudioFunction
	pop bc
	ld a, [wDisableChannelOutputWhenSfxEnds]
	and a
	jr nz, .skip
	ld a, [wChannelSoundIDs + CHAN8]
	ld [wDisableChannelOutputWhenSfxEnds], a
	xor a
	ld [wChannelSoundIDs + CHAN8], a
.skip
	jp Audio1_sound_ret

Audio1_duty_cycle_pattern:
	cp duty_cycle_pattern_cmd
	jr nz, Audio1_volume
	call Audio1_GetNextMusicByte
	ld b, 0
	ld hl, wChannelDutyCyclePatterns
	add hl, bc
	ld [hl], a
	and %11000000
	ld hl, wChannelDutyCycles
	add hl, bc
	ld [hl], a
	ld hl, wChannelFlags1
	add hl, bc
	set BIT_ROTATE_DUTY_CYCLE, [hl]
	jp Audio1_sound_ret

Audio1_volume:
	cp volume_cmd
	jr nz, Audio1_execute_music
	call Audio1_GetNextMusicByte
	ldh [rAUDVOL], a
	jp Audio1_sound_ret

Audio1_execute_music:
	cp execute_music_cmd
	jr nz, Audio1_octave
	ld b, 0
	ld hl, wChannelFlags2
	add hl, bc
	set BIT_EXECUTE_MUSIC, [hl]
	jp Audio1_sound_ret

Audio1_octave:
	and $f0
	cp octave_cmd
	jr nz, Audio1_sfx_note
	ld hl, wChannelOctaves
	ld b, 0
	add hl, bc
	ld a, d
	and $f
	ld [hl], a
	jp Audio1_sound_ret

Audio1_sfx_note:
	cp sfx_note_cmd
	jr nz, Audio1_pitch_sweep
	ld a, c
	cp CHAN4
	jr c, Audio1_pitch_sweep
	ld b, 0
	ld hl, wChannelFlags2
	add hl, bc
	bit BIT_EXECUTE_MUSIC, [hl]
	jr nz, Audio1_pitch_sweep
	call Audio1_note_length
	ld d, a
	ld b, 0
	ld hl, wChannelDutyCycles
	add hl, bc
	ld a, [hl]
	or d
	ld d, a
	ld b, REG_DUTY_SOUND_LEN
	call Audio1_GetRegisterPointer
	ld [hl], d
	call Audio1_GetNextMusicByte
	ld d, a
	ld b, REG_VOLUME_ENVELOPE
	call Audio1_GetRegisterPointer
	ld [hl], d
	call Audio1_GetNextMusicByte
	ld e, a
	ld a, c
	cp CHAN8
	ld a, 0
	jr z, .skip
	push de
	call Audio1_GetNextMusicByte
	pop de
.skip
	ld d, a
	push de
	call Audio1_ApplyDutyCycleAndSoundLength
	call Audio1_EnableChannelOutput
	pop de
	call Audio1_ApplyWavePatternAndFrequency
	ret

Audio1_pitch_sweep:
	ld a, c
	cp CHAN5
	jr c, Audio1_note
	ld a, d
	cp pitch_sweep_cmd
	jr nz, Audio1_note
	ld b, 0
	ld hl, wChannelFlags2
	add hl, bc
	bit BIT_EXECUTE_MUSIC, [hl]
	jr nz, Audio1_note
	call Audio1_GetNextMusicByte
	ldh [rAUD1SWEEP], a
	jp Audio1_sound_ret

Audio1_note:
	ld a, c
	cp CHAN4
	jr nz, Audio1_note_length
	ld a, d
	and $f0
	cp drum_note_cmd
	jr z, .drum_note
	jr nc, Audio1_note_length
	swap a
	ld b, a
	ld a, d
	and $f
	ld d, a
	ld a, b
	push de
	push bc
	jr .playDnote
.drum_note
	ld a, d
	and $f
	push af
	push bc
	call Audio1_GetNextMusicByte
.playDnote
	ld d, a
	ld a, [wDisableChannelOutputWhenSfxEnds]
	and a
	jr nz, .skipDnote
	ld b, d
	call DetermineAudioFunction
.skipDnote
	pop bc
	pop de

Audio1_note_length:
	ld a, d
	push af
	and $f
	inc a
	ld b, 0
	ld e, a
	ld d, b
	ld hl, wChannelNoteSpeeds
	add hl, bc
	ld a, [hl]
	ld l, b
	call Audio1_MultiplyAdd
	ld a, c
	cp CHAN5
	jr nc, .sfxChannel
	ld a, [wMusicTempo]
	ld d, a
	ld a, [wMusicTempo + 1]
	ld e, a
	jr .skip
.sfxChannel
	ld d, 1
	ld e, 0
	cp CHAN8
	jr z, .skip
	call Audio1_SetSfxTempo
	ld a, [wSfxTempo]
	ld d, a
	ld a, [wSfxTempo + 1]
	ld e, a
.skip
	ld a, l
	ld b, 0
	ld hl, wChannelNoteDelayCountersFractionalPart
	add hl, bc
	ld l, [hl]
	call Audio1_MultiplyAdd
	ld e, l
	ld d, h
	ld hl, wChannelNoteDelayCountersFractionalPart
	add hl, bc
	ld [hl], e
	ld a, d
	ld hl, wChannelNoteDelayCounters
	add hl, bc
	ld [hl], a
	ld hl, wChannelFlags2
	add hl, bc
	bit BIT_EXECUTE_MUSIC, [hl]
	jr nz, Audio1_note_pitch
	ld hl, wChannelFlags1
	add hl, bc
	bit BIT_NOISE_OR_SFX, [hl]
	jr z, Audio1_note_pitch
	pop hl
	ret

Audio1_note_pitch:
	pop af
	and $f0
	cp rest_cmd
	jr nz, .notRest
	ld a, c
	cp CHAN5
	jr nc, .next
	ld hl, wChannelSoundIDs + CHAN5
	add hl, bc
	ld a, [hl]
	and a
	jr nz, .done
.next
	ld a, c
	cp CHAN3
	jr z, .channel3
	cp CHAN7
	jr nz, .notChannel3
.channel3
	ld b, 0
	ld hl, Audio1_HWChannelDisableMasks
	add hl, bc
	ldh a, [rAUDTERM]
	and [hl]
	ldh [rAUDTERM], a
	jr .done
.notChannel3
	ld b, REG_VOLUME_ENVELOPE
	call Audio1_GetRegisterPointer
	ld a, $8
	ld [hli], a
	inc hl
	ld a, $80
	ld [hl], a
.done
	ret
.notRest
	swap a
	ld b, 0
	ld hl, wChannelOctaves
	add hl, bc
	ld b, [hl]
	call Audio1_CalculateFrequency
	ld b, 0
	ld hl, wChannelFlags1
	add hl, bc
	bit BIT_PITCH_SLIDE_ON, [hl]
	jr z, .skipPitchSlide
	call Audio1_InitPitchSlideVars
.skipPitchSlide
	push de
	ld a, c
	cp CHAN5
	jr nc, .sfxChannel
	ld hl, wChannelSoundIDs + CHAN5
	ld d, 0
	ld e, a
	add hl, de
	ld a, [hl]
	and a
	jr nz, .noSfx
	jr .sfxChannel
.noSfx
	pop de
	ret
.sfxChannel
	ld b, 0
	ld hl, wChannelVolumes
	add hl, bc
	ld d, [hl]
	ld b, REG_VOLUME_ENVELOPE
	call Audio1_GetRegisterPointer
	ld [hl], d
	call Audio1_ApplyDutyCycleAndSoundLength
	call Audio1_EnableChannelOutput
	pop de
	ld b, 0
	ld hl, wChannelFlags1
	add hl, bc
	bit BIT_PERFECT_PITCH, [hl]
	jr z, .skipFrequencyInc
	inc e
	jr nc, .skipFrequencyInc
	inc d
.skipFrequencyInc
	ld hl, wChannelFrequencyLowBytes
	add hl, bc
	ld [hl], e
	call Audio1_ApplyWavePatternAndFrequency
	ret

Audio1_EnableChannelOutput:
	ld b, 0
	call Audio1_ApplyMonoStereo
	add hl, bc
	ldh a, [rAUDTERM]
	or [hl]
	ld d, a
	ld a, c
	cp CHAN8
	jr z, .noiseChannelOrNoSfx
	cp CHAN5
	jr nc, .skip
	ld hl, wChannelSoundIDs + CHAN5
	add hl, bc
	ld a, [hl]
	and a
	jr nz, .skip
.noiseChannelOrNoSfx
	ld a, [wStereoPanning]
	call Audio1_ApplyMonoStereo
	add hl, bc
	and [hl]
	ld d, a
	ldh a, [rAUDTERM]
	ld hl, Audio1_HWChannelDisableMasks
	add hl, bc
	and [hl]
	or d
	ld d, a
.skip
	ld a, d
	ldh [rAUDTERM], a
	ret

Audio1_ApplyDutyCycleAndSoundLength:
	ld b, 0
	ld hl, wChannelNoteDelayCounters
	add hl, bc
	ld d, [hl]
	ld a, c
	cp CHAN3
	jr z, .skipDuty
	cp CHAN7
	jr z, .skipDuty
	ld a, d
	and $3f
	ld d, a
	ld hl, wChannelDutyCycles
	add hl, bc
	ld a, [hl]
	or d
	ld d, a
.skipDuty
	ld b, REG_DUTY_SOUND_LEN
	call Audio1_GetRegisterPointer
	ld [hl], d
	ret

Audio1_ApplyWavePatternAndFrequency:
	ld a, c
	cp CHAN3
	jr z, .channel3
	cp CHAN7
	jr nz, .notChannel3
.channel3
	push de
	ld de, wMusicWaveInstrument
	cp CHAN3
	jr z, .next
	ld de, wSfxWaveInstrument
.next
	ld a, [de]
	add a
	ld d, 0
	ld e, a
	ld hl, Audio1_WavePointers
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld hl, _AUD3WAVERAM
	ld b, AUD3WAVE_SIZE - 1
	xor a
	ldh [rAUD3ENA], a
.loop
	ld a, [de]
	inc de
	ld [hli], a
	ld a, b
	dec b
	and a
	jr nz, .loop
	ld a, AUD3ENA_ON
	ldh [rAUD3ENA], a
	pop de
.notChannel3
	ld a, d
	or $80
	and $c7
	ld d, a
	ld b, REG_FREQUENCY_LO
	call Audio1_GetRegisterPointer
	ld [hl], e
	inc hl
	ld [hl], d
	ld a, c
	cp $4
	jr c, .asm_9642
	call Audio1_ApplyFrequencyModifier
.asm_9642
	ret
.asm_9643
	ld a, c
	cp $4
	ret nz
	ld a, [wLowHealthAlarm]
	bit BIT_LOW_HEALTH_ALARM, a
	ret z
	xor a
	ld [wFrequencyModifier], a
	ld a, $80
	ld [wTempoModifier], a
	ret

Audio1_SetSfxTempo:
	call Audio1_IsCry
	jr c, .isCry
	call Audio1_IsBattleSFX
	jr nc, .notCry
.isCry
	ld d, 0
	ld a, [wTempoModifier]
	add $80
	jr nc, .next
	inc d
.next
	ld [wSfxTempo + 1], a
	ld a, d
	ld [wSfxTempo], a
	ret
.notCry
	xor a
	ld [wSfxTempo + 1], a
	inc a
	ld [wSfxTempo], a
	ret

Audio1_ApplyFrequencyModifier:
	call Audio1_IsCry
	jr c, .isCry
	call Audio1_IsBattleSFX
	ret nc
.isCry
	ld a, [wFrequencyModifier]
	add e
	jr nc, .noCarry
	inc d
.noCarry
	dec hl
	ld e, a
	ld [hl], e
	inc hl
	ld [hl], d
.done
	ret

Audio1_GoBackOneCommandIfCry:
	call Audio1_IsCry
	jr nc, .done
	ld hl, wChannelCommandPointers
	ld e, c
	ld d, 0
	sla e
	rl d
	add hl, de
	ld a, [hl]
	sub 1
	ld [hl], a
	inc hl
	ld a, [hl]
	sbc 0
	ld [hl], a
	scf
	ret
.done
	and a
	ret

Audio1_IsCry:
	ld a, [wChannelSoundIDs + CHAN5]
	cp CRY_SFX_START
	jr nc, .next
	jr .no
.next
	cp CRY_SFX_END
	jr z, .no
	jr c, .yes
.no
	scf
	ccf
	ret
.yes
	scf
	ret

Audio1_IsBattleSFX:
	ld a, [wAudioROMBank]
	cp BANK("Audio Engine 2")
	jr nz, .no
	ld a, [wChannelSoundIDs + CHAN8]
	ld b, a
	ld a, [wChannelSoundIDs + CHAN5]
	or b
	cp BATTLE_SFX_START
	jr c, .no
	cp BATTLE_SFX_END
	jr z, .yes
	jr c, .yes
.no
	and a
	ret
.yes
	scf
	ret

Audio1_ApplyPitchSlide:
	ld hl, wChannelFlags1
	add hl, bc
	bit BIT_PITCH_SLIDE_DECREASING, [hl]
	jp nz, .frequencyDecreasing
	ld hl, wChannelPitchSlideCurrentFrequencyLowBytes
	add hl, bc
	ld e, [hl]
	ld hl, wChannelPitchSlideCurrentFrequencyHighBytes
	add hl, bc
	ld d, [hl]
	ld hl, wChannelPitchSlideFrequencySteps
	add hl, bc
	ld l, [hl]
	ld h, b
	add hl, de
	ld d, h
	ld e, l
	ld hl, wChannelPitchSlideCurrentFrequencyFractionalPart
	add hl, bc
	push hl
	ld hl, wChannelPitchSlideFrequencyStepsFractionalPart
	add hl, bc
	ld a, [hl]
	pop hl
	add [hl]
	ld [hl], a
	ld a, 0
	adc e
	ld e, a
	ld a, 0
	adc d
	ld d, a
	ld hl, wChannelPitchSlideTargetFrequencyHighBytes
	add hl, bc
	ld a, [hl]
	cp d
	jp c, .reachedTargetFrequency
	jr nz, .applyUpdatedFrequency
	ld hl, wChannelPitchSlideTargetFrequencyLowBytes
	add hl, bc
	ld a, [hl]
	cp e
	jp c, .reachedTargetFrequency
	jr .applyUpdatedFrequency
.frequencyDecreasing
	ld hl, wChannelPitchSlideCurrentFrequencyLowBytes
	add hl, bc
	ld a, [hl]
	ld hl, wChannelPitchSlideCurrentFrequencyHighBytes
	add hl, bc
	ld d, [hl]
	ld hl, wChannelPitchSlideFrequencySteps
	add hl, bc
	ld e, [hl]
	sub e
	ld e, a
	ld a, d
	sbc b
	ld d, a
	ld hl, wChannelPitchSlideFrequencyStepsFractionalPart
	add hl, bc
	ld a, [hl]
	add a
	ld [hl], a
	ld a, e
	sbc b
	ld e, a
	ld a, d
	sbc b
	ld d, a
	ld hl, wChannelPitchSlideTargetFrequencyHighBytes
	add hl, bc
	ld a, d
	cp [hl]
	jr c, .reachedTargetFrequency
	jr nz, .applyUpdatedFrequency
	ld hl, wChannelPitchSlideTargetFrequencyLowBytes
	add hl, bc
	ld a, e
	cp [hl]
	jr c, .reachedTargetFrequency
.applyUpdatedFrequency
	ld hl, wChannelPitchSlideCurrentFrequencyLowBytes
	add hl, bc
	ld [hl], e
	ld hl, wChannelPitchSlideCurrentFrequencyHighBytes
	add hl, bc
	ld [hl], d
	ld b, REG_FREQUENCY_LO
	call Audio1_GetRegisterPointer
	ld a, e
	ld [hli], a
	ld [hl], d
	ret
.reachedTargetFrequency
	ld hl, wChannelFlags1
	add hl, bc
	res BIT_PITCH_SLIDE_ON, [hl]
	res BIT_PITCH_SLIDE_DECREASING, [hl]
	ret

Audio1_InitPitchSlideVars:
	ld hl, wChannelPitchSlideCurrentFrequencyHighBytes
	add hl, bc
	ld [hl], d
	ld hl, wChannelPitchSlideCurrentFrequencyLowBytes
	add hl, bc
	ld [hl], e
	ld hl, wChannelNoteDelayCounters
	add hl, bc
	ld a, [hl]
	ld hl, wChannelPitchSlideLengthModifiers
	add hl, bc
	sub [hl]
	jr nc, .next
	ld a, 1
.next
	ld [hl], a
	ld hl, wChannelPitchSlideTargetFrequencyLowBytes
	add hl, bc
	ld a, e
	sub [hl]
	ld e, a
	ld a, d
	sbc b
	ld hl, wChannelPitchSlideTargetFrequencyHighBytes
	add hl, bc
	sub [hl]
	jr c, .targetFrequencyGreater
	ld d, a
	ld b, 0
	ld hl, wChannelFlags1
	add hl, bc
	set BIT_PITCH_SLIDE_DECREASING, [hl]
	jr .next2
.targetFrequencyGreater
	ld hl, wChannelPitchSlideCurrentFrequencyHighBytes
	add hl, bc
	ld d, [hl]
	ld hl, wChannelPitchSlideCurrentFrequencyLowBytes
	add hl, bc
	ld e, [hl]
	ld hl, wChannelPitchSlideTargetFrequencyLowBytes
	add hl, bc
	ld a, [hl]
	sub e
	ld e, a
	ld a, d
	sbc b
	ld d, a
	ld hl, wChannelPitchSlideTargetFrequencyHighBytes
	add hl, bc
	ld a, [hl]
	sub d
	ld d, a
	ld b, 0
	ld hl, wChannelFlags1
	add hl, bc
	res BIT_PITCH_SLIDE_DECREASING, [hl]
.next2
	ld hl, wChannelPitchSlideLengthModifiers
	add hl, bc
.divideLoop
	inc b
	ld a, e
	sub [hl]
	ld e, a
	jr nc, .divideLoop
	ld a, d
	and a
	jr z, .doneDividing
	dec a
	ld d, a
	jr .divideLoop
.doneDividing
	ld a, e
	add [hl]
	ld d, b
	ld b, 0
	ld hl, wChannelPitchSlideFrequencySteps
	add hl, bc
	ld [hl], d
	ld hl, wChannelPitchSlideFrequencyStepsFractionalPart
	add hl, bc
	ld [hl], a
	ld hl, wChannelPitchSlideCurrentFrequencyFractionalPart
	add hl, bc
	ld [hl], a
	ret

Audio1_ApplyDutyCyclePattern:
	ld b, 0
	ld hl, wChannelDutyCyclePatterns
	add hl, bc
	ld a, [hl]
	rlca
	rlca
	ld [hl], a
	and $c0
	ld d, a
	ld b, REG_DUTY_SOUND_LEN
	call Audio1_GetRegisterPointer
	ld a, [hl]
	and $3f
	or d
	ld [hl], a
	ret

Audio1_GetNextMusicByte:
	call GetNextMusicByte
	ret

Audio1_GetRegisterPointer:
	ld a, c
	ld hl, Audio1_HWChannelBaseAddresses
	add l
	jr nc, .noCarry
	inc h
.noCarry
	ld l, a
	ld a, [hl]
	add b
	ld l, a
	ld h, $ff
	ret

Audio1_MultiplyAdd:
	ld h, 0
.loop
	srl a
	jr nc, .skipAdd
	add hl, de
.skipAdd
	sla e
	rl d
	and a
	jr z, .done
	jr .loop
.done
	ret

Audio1_CalculateFrequency:
	ld h, 0
	ld l, a
	add hl, hl
	ld d, h
	ld e, l
	ld hl, Audio1_Pitches
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, b
.loop
	cp 7
	jr z, .done
	sra d
	rr e
	inc a
	jr .loop
.done
	ld a, 8
	add d
	ld d, a
	ret

Audio1_PlaySound::
	ld [wSoundID], a
	ld a, [wSoundID]
	cp SFX_STOP_ALL_MUSIC
	jp z, .stopAllAudio
	cp MAX_SFX_ID_1
	jp z, .playSfx
	jp c, .playSfx
	cp $fe
	jr z, .playMusic
	jp nc, .playSfx
.playMusic
	call InitMusicVariables
	jp .playSoundCommon
.playSfx
	ld l, a
	ld e, a
	ld h, 0
	ld d, h
	add hl, hl
	add hl, de
	ld de, SFX_Headers_1
	add hl, de
	ld a, h
	ld [wSfxHeaderPointer], a
	ld a, l
	ld [wSfxHeaderPointer + 1], a
	ld a, [hl]
	and $c0
	rlca
	rlca
	ld c, a
.sfxChannelLoop
	ld d, c
	ld a, c
	add a
	add c
	ld c, a
	ld b, 0
	ld a, [wSfxHeaderPointer]
	ld h, a
	ld a, [wSfxHeaderPointer + 1]
	ld l, a
	add hl, bc
	ld c, d
	ld a, [hl]
	and $f
	ld e, a
	ld d, 0
	ld hl, wChannelSoundIDs
	add hl, de
	ld a, [hl]
	and a
	jr z, .playChannel
	ld a, e
	cp CHAN8
	jr nz, .notNoiseChannel
	ld a, [wSoundID]
	cp NOISE_INSTRUMENTS_END
	jr nc, .notNoiseInstrument
	ret
.notNoiseInstrument
	ld a, [hl]
	cp NOISE_INSTRUMENTS_END
	jr z, .playChannel
	jr c, .playChannel
.notNoiseChannel
	ld a, [wSoundID]
	cp [hl]
	jr z, .playChannel
	jr c, .playChannel
	ret
.playChannel
	call InitSFXVariables
	ld a, c
	and a
	jp z, .playSoundCommon
	dec c
	jp .sfxChannelLoop
.stopAllAudio
	call StopAllAudio
	ret
.playSoundCommon
	ld a, [wSoundID]
	ld l, a
	ld e, a
	ld h, 0
	ld d, h
	add hl, hl
	add hl, de
	ld de, SFX_Headers_1
	add hl, de
	ld e, l
	ld d, h
	ld hl, wChannelCommandPointers
	ld a, [de]
	ld b, a
	rlca
	rlca
	and $3
	ld c, a
	ld a, b
	and $f
	ld b, c
	inc b
	inc de
	ld c, 0
.commandPointerLoop
	cp c
	jr z, .next
	inc c
	inc hl
	inc hl
	jr .commandPointerLoop
.next
	push af
	push hl
	push bc
	ld b, 0
	ld c, a
	cp CHAN4
	jr c, .skipSettingFlag
	ld hl, wChannelFlags1
	add hl, bc
	set BIT_NOISE_OR_SFX, [hl]
.skipSettingFlag
	pop bc
	pop hl
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	inc de
	pop af
	push hl
	push bc
	ld b, 0
	ld c, a
	ld hl, wChannelSoundIDs
	add hl, bc
	ld a, [wSoundID]
	ld [hl], a
	pop bc
	pop hl
	inc c
	dec b
	ld a, b
	and a
	ld a, [de]
	inc de
	jr nz, .commandPointerLoop
	ld a, [wSoundID]
	cp CRY_SFX_START
	jr nc, .maybeCry
	jr .done
.maybeCry
	ld a, [wSoundID]
	cp CRY_SFX_END
	jr z, .done
	jr c, .cry
	jr .done
.cry
	ld hl, wChannelSoundIDs + CHAN5
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld hl, wChannelCommandPointers + CHAN7 * 2
	ld de, Audio1_CryRet
	ld [hl], e
	inc hl
	ld [hl], d
	ld a, [wSavedVolume]
	and a
	jr nz, .done
	ldh a, [rAUDVOL]
	ld [wSavedVolume], a
	ld a, $77
	ldh [rAUDVOL], a
.done
	ret

Audio1_CryRet:
	sound_ret

Audio1_HWChannelBaseAddresses:
	table_width 1
	db LOW(AUD1RAM)
	db LOW(AUD2RAM)
	db LOW(AUD3RAM)
	db LOW(AUD4RAM)
	db LOW(AUD1RAM)
	db LOW(AUD2RAM)
	db LOW(AUD3RAM)
	db LOW(AUD4RAM)
	assert_table_length NUM_CHANNELS

Audio1_HWChannelDisableMasks:
	table_width 1
	db ~(AUDTERM_1_LEFT | AUDTERM_1_RIGHT)
	db ~(AUDTERM_2_LEFT | AUDTERM_2_RIGHT)
	db ~(AUDTERM_3_LEFT | AUDTERM_3_RIGHT)
	db ~(AUDTERM_4_LEFT | AUDTERM_4_RIGHT)
	db ~(AUDTERM_1_LEFT | AUDTERM_1_RIGHT)
	db ~(AUDTERM_2_LEFT | AUDTERM_2_RIGHT)
	db ~(AUDTERM_3_LEFT | AUDTERM_3_RIGHT)
	db ~(AUDTERM_4_LEFT | AUDTERM_4_RIGHT)
	assert_table_length NUM_CHANNELS

Audio1_ApplyMonoStereo:
	push af
	push bc
	ld a, [wOptions]
	and SOUND_MASK
	srl a
	ld c, a
	ld b, 0
	ld hl, Audio1_HWChannelEnableMasks
	add hl, bc
	pop bc
	pop af
	ret

Audio1_HWChannelEnableMasks:
	table_width 1
	db AUDTERM_1_LEFT | AUDTERM_1_RIGHT
	db AUDTERM_2_LEFT | AUDTERM_2_RIGHT
	db AUDTERM_3_LEFT | AUDTERM_3_RIGHT
	db AUDTERM_4_LEFT | AUDTERM_4_RIGHT
	db AUDTERM_1_LEFT | AUDTERM_1_RIGHT
	db AUDTERM_2_LEFT | AUDTERM_2_RIGHT
	db AUDTERM_3_LEFT | AUDTERM_3_RIGHT
	db AUDTERM_4_LEFT | AUDTERM_4_RIGHT
	assert_table_length NUM_CHANNELS
	db AUDTERM_1_RIGHT
	db AUDTERM_2_LEFT
	db AUDTERM_3_LEFT | AUDTERM_3_RIGHT
	db AUDTERM_4_LEFT | AUDTERM_4_RIGHT
	db AUDTERM_1_LEFT | AUDTERM_1_RIGHT
	db AUDTERM_2_LEFT | AUDTERM_2_RIGHT
	db AUDTERM_3_LEFT | AUDTERM_3_RIGHT
	db AUDTERM_4_LEFT | AUDTERM_4_RIGHT
	assert_table_length NUM_CHANNELS * 2
	db AUDTERM_1_RIGHT
	db AUDTERM_2_LEFT
	db AUDTERM_3_RIGHT
	db AUDTERM_4_LEFT
	db AUDTERM_1_RIGHT
	db AUDTERM_2_LEFT
	db AUDTERM_3_RIGHT
	db AUDTERM_4_LEFT
	assert_table_length NUM_CHANNELS * 3
	db AUDTERM_1_RIGHT
	db AUDTERM_2_RIGHT
	db AUDTERM_3_LEFT
	db AUDTERM_4_LEFT
	db AUDTERM_1_RIGHT
	db AUDTERM_2_RIGHT
	db AUDTERM_3_LEFT
	db AUDTERM_4_LEFT
	assert_table_length NUM_CHANNELS * 4

Audio1_Pitches:
INCLUDE "audio/notes.asm"
