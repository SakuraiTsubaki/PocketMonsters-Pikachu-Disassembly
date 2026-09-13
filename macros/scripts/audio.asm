MACRO audio_def
	ASSERT (\1) > 0 && (\1) <= NUM_AUDIO_ENG, \
		"audio_def must be 1-{d:NUM_AUDIO_ENG}"
	DEF audio_engine = \1
ENDM

; \1 Label
; \2, \3 ... (optional) channels
MACRO audio_header
	REDEF _audio_label EQUS "\1"
	{_audio_label}::
	IF _NARG > 1
		ASSERT _NARG <= NUM_MUSIC_CHANS + 1, \
			"Exceeded maximum channel number."
		DEF _num_channels = _NARG - 2
		REPT _NARG - 1
			ASSERT 0 < (\2) && (\2) <= NUM_CHANNELS, \
				"channel id must be 1-{d:NUM_CHANNELS}"
			dn (_num_channels << 2), \2 - 1
			dw {_audio_label}_Ch\2
			DEF _num_channels = 0
			SHIFT
		ENDR
	ENDC
ENDM

; \1 Label
; \2, \3 ... (optional) channels
MACRO audio_header_eng
	REDEF _audio_label EQUS "\1"
	{_audio_label}_{d:audio_engine}::
	IF _NARG > 1
		ASSERT _NARG <= NUM_MUSIC_CHANS + 1, \
			"Exceeded maximum channel number {d:NUM_MUSIC_CHANS}"
		DEF _num_channels = _NARG - 2
		REPT _NARG - 1
			ASSERT 0 < (\2) && (\2) <= NUM_CHANNELS, \
				"channel id must be 1-{d:NUM_CHANNELS}"
			dn (_num_channels << 2), \2 - 1
			dw {_audio_label}_{d:audio_engine}_Ch\2
			DEF _num_channels = 0
			SHIFT
		ENDR
	ENDC
ENDM

; \1 SFX Label
; \2 Channel
MACRO audio_eng_channel
	ASSERT 0 < (\2) && (\2) <= NUM_CHANNELS, \
		"channel id must be 1-{d:NUM_CHANNELS}"
	\1_{d:audio_engine}_Ch\2:
ENDM

	const_def $10

; arguments: length [0, 7], pitch change [-7, 7]
	const pitch_sweep_cmd
MACRO pitch_sweep
	db pitch_sweep_cmd
	IF \2 < 0
		dn \1, %1000 | (\2 * -1)
	ELSE
		dn \1, \2
	ENDC
ENDM

	const_next $20
	const sfx_note_cmd

DEF square_note_cmd EQU sfx_note_cmd
MACRO square_note
	db square_note_cmd | \1
	IF \3 < 0
		dn \2, %1000 | (\3 * -1)
	ELSE
		dn \2, \3
	ENDC
	dw \4
ENDM

DEF noise_note_cmd EQU sfx_note_cmd
MACRO noise_note
	db noise_note_cmd | \1
	IF \3 < 0
		dn \2, %1000 | (\3 * -1)
	ELSE
		dn \2, \3
	ENDC
	db \4
ENDM

; arguments: pitch, length [1, 16]
MACRO note
	dn \1, \2 - 1
ENDM

	const_next $b0
	const drum_note_cmd
MACRO drum_note
	db drum_note_cmd | (\2 - 1)
	db \1
ENDM

; unused compact drum encoding
MACRO drum_note_short
	note \1, \2
ENDM

	const_next $c0
	const rest_cmd
MACRO rest
	db rest_cmd | (\1 - 1)
ENDM

	const_next $d0
	const note_type_cmd
MACRO note_type
	db note_type_cmd | \1
	IF \3 < 0
		dn \2, %1000 | (\3 * -1)
	ELSE
		dn \2, \3
	ENDC
ENDM

DEF drum_speed_cmd EQU note_type_cmd
MACRO drum_speed
	db drum_speed_cmd | \1
ENDM

	const_next $e0
	const octave_cmd
MACRO octave
	db octave_cmd | (8 - \1)
ENDM

	const_next $e8
	const toggle_perfect_pitch_cmd
MACRO toggle_perfect_pitch
	db toggle_perfect_pitch_cmd
ENDM

	const_skip ; $e9
	const vibrato_cmd
MACRO vibrato
	db vibrato_cmd
	db \1
	dn \2, \3
ENDM

	const pitch_slide_cmd
MACRO pitch_slide
	db pitch_slide_cmd
	db \1 - 1
	dn 8 - \2, \3
ENDM

	const duty_cycle_cmd
MACRO duty_cycle
	db duty_cycle_cmd
	db \1
ENDM

	const tempo_cmd
MACRO tempo
	db tempo_cmd
	db HIGH(\1), LOW(\1)
ENDM

	const stereo_panning_cmd
MACRO stereo_panning
	db stereo_panning_cmd
	dn \1, \2
ENDM

	const unknownmusic0xef_cmd

	const volume_cmd
MACRO volume
	db volume_cmd
	dn \1, \2
ENDM

	const_next $f8
	const execute_music_cmd
MACRO execute_music
	db execute_music_cmd
ENDM

	const_next $fc
	const duty_cycle_pattern_cmd
MACRO duty_cycle_pattern
	db duty_cycle_pattern_cmd
	db \1 << 6 | \2 << 4 | \3 << 2 | \4
ENDM

	const sound_call_cmd
MACRO sound_call
	db sound_call_cmd
	dw \1
ENDM

	const sound_loop_cmd
MACRO sound_loop
	db sound_loop_cmd
	db \1
	dw \2
ENDM

	const sound_ret_cmd
MACRO sound_ret
	db sound_ret_cmd
ENDM
