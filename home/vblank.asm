; Bank 00 VBlank interrupt handler.
; International builds preserve/reset CGB VRAM bank state; Japanese builds do not.

VBlank::
	push af
	push bc
	push de
	push hl

IF !DEF(_JAPAN)
	ldh a, [rVBK]
	push af
	xor a
	ldh [rVBK], a
ENDC

	ldh a, [hLoadedROMBank]
	ld [wVBlankSavedROMBank], a

	ldh a, [hSCX]
	ldh [rSCX], a
	ldh a, [hSCY]
	ldh [rSCY], a

	ld a, [wDisableVBlankWYUpdate]
	and a
	jr nz, .skip_wy
	ldh a, [hWY]
	ldh [rWY], a
.skip_wy

	call AutoBgMapTransfer
	call VBlankCopyBgMap
	call RedrawRowOrColumn
	call VBlankCopy
	call VBlankCopyDouble
	call UpdateMovingBgTiles
	call hDMARoutine

	ld a, BANK(PrepareOAMData)
	ldh [hLoadedROMBank], a
	ld [rROMB], a
	call PrepareOAMData

	call TrackPlayTime
	call Random
IF !DEF(_JAPAN) || !DEF(_REV0)
	call ReadJoypad
ENDC

	ldh a, [hVBlankOccurred]
	and a
	jr z, .skip_vblank_flag
	xor a
	ldh [hVBlankOccurred], a
.skip_vblank_flag

	ldh a, [hFrameCounter]
	and a
	jr z, .skip_frame_counter
	dec a
	ldh [hFrameCounter], a
.skip_frame_counter

	call FadeOutAudio

	ld a, BANK(Music_DoLowHealthAlarm)
	call BankswitchCommon
	call Music_DoLowHealthAlarm
	ld a, BANK(Audio1_UpdateMusic)
	call BankswitchCommon
	call Audio1_UpdateMusic

	call SerialFunction

	ld a, [wVBlankSavedROMBank]
	ldh [hLoadedROMBank], a
	ld [rROMB], a

IF !DEF(_JAPAN)
	pop af
	ldh [rVBK], a
ENDC

	pop hl
	pop de
	pop bc
	pop af
	reti

DelayFrame::
	DEF NOT_VBLANKED EQU 1
	ld a, NOT_VBLANKED
	ldh [hVBlankOccurred], a
.wait
	halt
	ldh a, [hVBlankOccurred]
	and a
	jr nz, .wait
	ret
