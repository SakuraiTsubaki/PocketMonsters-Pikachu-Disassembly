TextCommandProcessor::
	ld a, [wLetterPrintingDelayFlags]
	push af
	set BIT_TEXT_DELAY, a
IF DEF(_JAPAN)
	ld [wLetterPrintingDelayFlags], a
ELSE
	ld e, a
	ldh a, [hClearLetterPrintingDelayFlags]
	xor e
	ld [wLetterPrintingDelayFlags], a
ENDC
	ld a, c
	ld [wTextDest], a
	ld a, b
	ld [wTextDest + 1], a

NextTextCommand::
	ld a, [hli]
	cp TX_END
	jr nz, .TextCommand
	pop af
	ld [wLetterPrintingDelayFlags], a
	ret

.TextCommand:
	push hl
IF !DEF(_JAPAN)
	cp TX_FAR
	jp z, TextCommand_FAR
ENDC
	cp TX_SOUND_POKEDEX_RATING
	jp nc, TextCommand_SOUND
	ld hl, TextCommandJumpTable
	push bc
	add a
	ld b, 0
	ld c, a
	add hl, bc
	pop bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

TextCommand_BOX::
; Draw a box (height, width).
	pop hl
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	push hl
	ld h, d
	ld l, e
	call TextBoxBorder
	pop hl
	jr NextTextCommand

TextCommand_START::
; Write text until "@".
	pop hl
	ld d, h
	ld e, l
	ld h, b
	ld l, c
	call PlaceString
	ld h, d
	ld l, e
	inc hl
	jr NextTextCommand

TextCommand_RAM::
; Write text from a RAM address (little endian).
	pop hl
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push hl
	ld h, b
	ld l, c
	call PlaceString
	pop hl
	jr NextTextCommand

TextCommand_BCD::
; Write BCD from an address, typically RAM.
	pop hl
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	push hl
	ld h, b
	ld l, c
	ld c, a
	call PrintBCDNumber
	ld b, h
	ld c, l
	pop hl
	jr NextTextCommand

TextCommand_MOVE::
; Move to a new tile.
	pop hl
	ld a, [hli]
	ld [wTextDest], a
	ld c, a
	ld a, [hli]
	ld [wTextDest + 1], a
	ld b, a
	jp NextTextCommand

TextCommand_LOW::
; Write text at (1,16).
	pop hl
	bccoord 1, 16
	jp NextTextCommand

TextCommand_PROMPT_BUTTON::
; Wait for button press and show arrow.
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jp z, TextCommand_WAIT_BUTTON
	ld a, '▼'
	ldcoord_a 18, 16
	push bc
	call ManualTextScroll
	pop bc
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	ldcoord_a 18, 16
	pop hl
	jp NextTextCommand

TextCommand_SCROLL::
; Push text up two lines and move BC to the second dialogue row.
IF DEF(_JAPAN)
	ld a, '　'
ELSE
	ld a, ' '
ENDC
	ldcoord_a 18, 16
	call ScrollTextUpOneLine
	call ScrollTextUpOneLine
	pop hl
	bccoord 1, 16
	jp NextTextCommand

TextCommand_START_ASM::
; Run assembly code.
	pop hl
	ld de, NextTextCommand
	push de
	jp hl

TextCommand_NUM::
; Print a number.
	pop hl
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	push hl
	ld h, b
	ld l, c
	ld b, a
	and $0f
	ld c, a
	ld a, b
	and $f0
	swap a
	set BIT_LEFT_ALIGN, a
	ld b, a
	call PrintNumber
	ld b, h
	ld c, l
	pop hl
	jp NextTextCommand

TextCommand_PAUSE::
; Wait for button press or 30 frames.
	push bc
	call Joypad
	ldh a, [hJoyHeld]
	and PAD_A | PAD_B
	jr nz, .done
	ld c, 30
	call DelayFrames
.done
	pop bc
	pop hl
	jp NextTextCommand

TextCommand_SOUND::
; Play a sound effect from TextCommandSounds.
	pop hl
	push bc
	dec hl
	ld a, [hli]
	ld b, a
	push hl
	ld hl, TextCommandSounds
.loop
	ld a, [hli]
	cp b
	jr z, .play
	inc hl
	jr .loop

.play
	cp TX_SOUND_CRY_PIKACHU
	jr z, .pokemonCry
	cp TX_SOUND_CRY_PIDGEOT
	jr z, .pokemonCry
	cp TX_SOUND_CRY_DEWGONG
	jr z, .pokemonCry
	ld a, [hl]
	call PlaySound
	call WaitForSoundToFinish
	pop hl
	pop bc
	jp NextTextCommand

.pokemonCry
	push de
	ld a, [hl]
	call PlayCry
	pop de
	pop hl
	pop bc
	jp NextTextCommand

TextCommandSounds::
	db TX_SOUND_GET_ITEM_1,           SFX_GET_ITEM_1
	db TX_SOUND_CAUGHT_MON,           SFX_CAUGHT_MON
	db TX_SOUND_POKEDEX_RATING,       SFX_POKEDEX_RATING
	db TX_SOUND_GET_ITEM_1_DUPLICATE, SFX_GET_ITEM_1
	db TX_SOUND_GET_ITEM_2,           SFX_GET_ITEM_2
	db TX_SOUND_GET_KEY_ITEM,         SFX_GET_KEY_ITEM
	db TX_SOUND_DEX_PAGE_ADDED,       SFX_DEX_PAGE_ADDED
	db TX_SOUND_CRY_PIKACHU,          STARTER_PIKACHU
	db TX_SOUND_CRY_PIDGEOT,          PIDGEOT
	db TX_SOUND_CRY_DEWGONG,          DEWGONG

TextCommand_DOTS::
; Wait for button press or 30 frames while printing ellipses.
	pop hl
	ld a, [hli]
	ld d, a
	push hl
	ld h, b
	ld l, c

.loop
IF DEF(_JAPAN)
	ld a, '⋯'
ELSE
	ld a, '…'
ENDC
	ld [hli], a
	push de
	call Joypad
	pop de
	ldh a, [hJoyHeld]
	and PAD_A | PAD_B
	jr nz, .next
	ld c, 10
	call DelayFrames
.next
	dec d
	jr nz, .loop

	ld b, h
	ld c, l
	pop hl
	jp NextTextCommand

TextCommand_WAIT_BUTTON::
; Wait for button press without showing an arrow.
	push bc
	call ManualTextScroll
	pop bc
	pop hl
	jp NextTextCommand

IF !DEF(_JAPAN)
TextCommand_FAR::
; Write text from a different bank (little endian).
	pop hl
	ldh a, [hLoadedROMBank]
	push af

	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]

	ldh [hLoadedROMBank], a
	ld [rROMB], a

	push hl
	ld l, e
	ld h, d
	call TextCommandProcessor
	pop hl

	pop af
	ldh [hLoadedROMBank], a
	ld [rROMB], a
	jp NextTextCommand
ENDC

TextCommandJumpTable::
; Entries correspond to TX_* constants (see macros/scripts/text.asm).
	dw TextCommand_START
	dw TextCommand_RAM
	dw TextCommand_BCD
	dw TextCommand_MOVE
	dw TextCommand_BOX
	dw TextCommand_LOW
	dw TextCommand_PROMPT_BUTTON
IF DEF(_JAPAN)
	dw TextCommand_SCROLL
ELSE
IF DEF(_DEBUG)
	dw _ContTextNoPause
ELSE
	dw TextCommand_SCROLL
ENDC
ENDC
	dw TextCommand_START_ASM
	dw TextCommand_NUM
	dw TextCommand_PAUSE
	dw TextCommand_SOUND
	dw TextCommand_DOTS
	dw TextCommand_WAIT_BUTTON
