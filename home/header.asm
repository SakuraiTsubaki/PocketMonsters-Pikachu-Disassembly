; Bank 00 reset/interrupt vectors and cartridge entry point.
; Reconstructed from the nine verified reference ROMs.

SECTION "rst0", ROM0[$0000]
	rst $38
	ds $08 - @, 0

SECTION "rst8", ROM0[$0008]
	rst $38
	ds $10 - @, 0

SECTION "rst10", ROM0[$0010]
	rst $38
	ds $18 - @, 0

SECTION "rst18", ROM0[$0018]
	rst $38
	ds $20 - @, 0

SECTION "rst20", ROM0[$0020]
	rst $38
	ds $28 - @, 0

SECTION "rst28", ROM0[$0028]
	rst $38
	ds $30 - @, 0

SECTION "rst30", ROM0[$0030]
	rst $38
	ds $38 - @, 0

SECTION "rst38", ROM0[$0038]
IF DEF(_JAPAN) && DEF(_REV0)
	; Japanese V1.0 keeps this otherwise-unused invalid jump into echo RAM.
	jp $f080
ELSE
	rst $38
ENDC
	ds $40 - @, 0

SECTION "vblank", ROM0[$0040]
	jp VBlank
	ds $48 - @, 0

SECTION "lcd", ROM0[$0048]
	jp LCDC
	ds $50 - @, 0

SECTION "timer", ROM0[$0050]
	jp Timer
	ds $58 - @, 0

SECTION "serial", ROM0[$0058]
	jp Serial
	ds $60 - @, 0

SECTION "joypad", ROM0[$0060]
	reti
IF DEF(_JAPAN)
	; Japanese builds leave $0061-$0067 unused.
	ds $68 - @, 0
ENDC

SECTION "Header", ROM0[$0100]
Start::
	nop
IF DEF(_JAPAN)
	jp Init
ELSE
	jp _Start
ENDC

; rgbfix supplies the Nintendo logo and cartridge header fields.
	ds $0150 - @

ENDSECTION
