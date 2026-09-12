LoadFontTilePatterns::
	ldh a, [rLCDC]
	bit B_LCDC_ENABLE, a
	jr nz, .on
; off
	ld hl, FontGraphics
	ld de, vFont
	ld bc, FontGraphicsEnd - FontGraphics
	ld a, BANK(FontGraphics)
	jp FarCopyDataDouble
.on
	ld de, FontGraphics
	ld hl, vFont
	lb bc, BANK(FontGraphics), (FontGraphicsEnd - FontGraphics) / TILE_1BPP_SIZE
	jp CopyVideoDataDouble

LoadTextBoxTilePatterns::
	ldh a, [rLCDC]
	bit B_LCDC_ENABLE, a
	jr nz, .on
; off
	ld hl, TextBoxGraphics
	ld de, vChars2 tile $60
	ld bc, TextBoxGraphicsEnd - TextBoxGraphics
	ld a, BANK(TextBoxGraphics)
	jp FarCopyData
.on
	ld de, TextBoxGraphics
	ld hl, vChars2 tile $60
	lb bc, BANK(TextBoxGraphics), (TextBoxGraphicsEnd - TextBoxGraphics) / TILE_SIZE
	jp CopyVideoData

LoadHpBarAndStatusTilePatterns::
	ldh a, [rLCDC]
	bit B_LCDC_ENABLE, a
	jr nz, .on
; off
	ld hl, HpBarAndStatusGraphics
	ld de, vChars2 tile $62
	ld bc, HpBarAndStatusGraphicsEnd - HpBarAndStatusGraphics
	ld a, BANK(HpBarAndStatusGraphics)
	jp FarCopyData
.on
	ld de, HpBarAndStatusGraphics
	ld hl, vChars2 tile $62
	lb bc, BANK(HpBarAndStatusGraphics), (HpBarAndStatusGraphicsEnd - HpBarAndStatusGraphics) / TILE_SIZE
	jp CopyVideoData
