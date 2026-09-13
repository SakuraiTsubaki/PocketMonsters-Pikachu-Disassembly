; Alternate start for MeetRival with a different first measure.
Music_RivalAlternateStart::
	ld c, BANK(Music_MeetRival)
	ld a, MUSIC_MEET_RIVAL
	call PlayMusic
	ld hl, wChannelCommandPointers
	ld de, Music_MeetRival_Ch1_AlternateStart
	call Audio1_OverwriteChannelPointer
	ld de, Music_MeetRival_Ch2_AlternateStart
	call Audio1_OverwriteChannelPointer
	ld de, Music_MeetRival_Ch3_AlternateStart

Audio1_OverwriteChannelPointer:
	ld a, e
	ld [hli], a
	ld a, d
	ld [hli], a
	ret

; Slightly slower MeetRival tempo.
Music_RivalAlternateTempo::
	ld c, BANK(Music_MeetRival)
	ld a, MUSIC_MEET_RIVAL
	call PlayMusic
	ld de, Music_MeetRival_Ch1_AlternateTempo
	jr FinishAlternateRivalMusic

Music_RivalAlternateStartAndTempo::
	call Music_RivalAlternateStart
	ld de, Music_MeetRival_Ch1_AlternateStartAndTempo
FinishAlternateRivalMusic:
	ld hl, wChannelCommandPointers
	jp Audio1_OverwriteChannelPointer

	ret ; unused

; Faster Cities1 variant used in the Hall of Fame room.
Music_Cities1AlternateTempo::
	ld a, 10
	ld [wAudioFadeOutCounterReloadValue], a
	ld [wAudioFadeOutCounter], a
	ld a, $ff
	ld [wAudioFadeOutControl], a
	ld c, 100
	call DelayFrames
	ld c, BANK(Music_Cities1)
	ld a, MUSIC_CITIES1
	call PlayMusic
	ld hl, wChannelCommandPointers
	ld de, Music_Cities1_Ch1_AlternateTempo
	jp Audio1_OverwriteChannelPointer
