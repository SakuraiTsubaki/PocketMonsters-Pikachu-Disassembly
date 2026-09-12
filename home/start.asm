; Bank 00 boot-mode bridge.

IF DEF(_JAPAN)
_Start::
	; Japanese cartridge headers jump directly to Init, so this routine is unused.
	jp Init
ELSE
_Start::
	; CGB boot ROM leaves A=$11. Preserve that information for later palette logic.
	cp $11
	jr z, .cgb
	xor a
	jr .store
.cgb
	ld a, 1
.store
	ldh [hOnCGB], a
	jp Init
ENDC
