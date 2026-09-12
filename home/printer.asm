PrinterSerial::
IF DEF(_REV0)
	; Japanese V1.0 uses the alternate home-call encoding.
	homecall_alt PrinterSerial_
ELSE
	homecall PrinterSerial_
ENDC
	ret

SerialFunction::
	ld a, [wPrinterConnectionOpen]
	bit 0, a
	ret z
	ld a, [wPrinterOpcode]
	and a
	ret nz
	; This byte is named wHandshakeFrameDelay in the English disassembly.
	; The other reference disassemblies express the same WRAM address directly.
	ld hl, wOverworldMap + 650
	inc [hl]
	ld a, [hl]
	cp $6
	ret c
	xor a
	ld [hl], a
	ld a, $0c
	ld [wPrinterOpcode], a
	ld a, $88
	ldh [rSB], a
	ld a, $1
	ldh [rSC], a
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
	ret

DisableWaitingAfterTextDisplay::
	ld a, $01
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ret
