; Bank 00 serial/link routines.
; The EN and JP public reconstructions resolve to the same logical source here;
; the nine reference ROMs keep the routine at the same 497-byte span, with
; relocation-sensitive absolute addresses supplied by each target layout.

Serial::
	push af
	push bc
	push de
	push hl
	ld a, [wPrinterConnectionOpen]
	bit 0, a
	jp nz, PrinterSerial__
	ldh a, [hSerialConnectionStatus]
	inc a
	jr z, .connection_not_established
	ldh a, [rSB]
	ldh [hSerialReceiveData], a
	ldh a, [hSerialSendData]
	ldh [rSB], a
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr z, .done
	ld a, SC_START | SC_EXTERNAL
	ldh [rSC], a
	jr .done
.connection_not_established
	ldh a, [rSB]
	ldh [hSerialReceiveData], a
	ldh [hSerialConnectionStatus], a
	cp USING_INTERNAL_CLOCK
	jr z, .using_internal_clock
	xor a
	ldh [rSB], a
	ld a, $3
	ldh [rDIV], a
.wait_div
	ldh a, [rDIV]
	bit 7, a
	jr nz, .wait_div
	ld a, SC_START | SC_EXTERNAL
	ldh [rSC], a
	jr .done
.using_internal_clock
	xor a
	ldh [rSB], a
.done
	ld a, 1
	ldh [hSerialReceivedNewData], a
	ld a, SERIAL_NO_DATA_BYTE
	ldh [hSerialSendData], a
	pop hl
	pop de
	pop bc
	pop af
	reti

Serial_ExchangeBytes::
	ld a, 1
	ldh [hSerialIgnoringInitialData], a
.loop
	ld a, [hl]
	ldh [hSerialSendData], a
	call Serial_ExchangeByte
	push bc
	ld b, a
	inc hl
	ld a, 48
.wait
	dec a
	jr nz, .wait
	ldh a, [hSerialIgnoringInitialData]
	and a
	ld a, b
	pop bc
	jr z, .store
	dec hl
	cp SERIAL_PREAMBLE_BYTE
	jr nz, .loop
	xor a
	ldh [hSerialIgnoringInitialData], a
	jr .loop
.store
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

Serial_ExchangeByte::
	xor a
	ldh [hSerialReceivedNewData], a
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr nz, .loop
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
.loop
	ldh a, [hSerialReceivedNewData]
	and a
	jr nz, .ok
	ldh a, [hSerialConnectionStatus]
	cp USING_EXTERNAL_CLOCK
	jr nz, .skip_unknown_counter
	call IsUnknownCounterZero
	jr z, .skip_unknown_counter
	call WaitLoop_15Iterations
	push hl
	ld hl, wUnknownSerialCounter + 1
	inc [hl]
	jr nz, .no_carry
	dec hl
	inc [hl]
.no_carry
	pop hl
	call IsUnknownCounterZero
	jr nz, .loop
	jp SetUnknownCounterToFFFF
.skip_unknown_counter
	ldh a, [rIE]
	and IE_SERIAL | IE_TIMER | IE_STAT | IE_VBLANK
	cp IE_SERIAL
	jr nz, .loop
	ld a, [wUnknownSerialCounter2]
	dec a
	ld [wUnknownSerialCounter2], a
	jr nz, .loop
	ld a, [wUnknownSerialCounter2 + 1]
	dec a
	ld [wUnknownSerialCounter2 + 1], a
	jr nz, .loop
	ldh a, [hSerialConnectionStatus]
	cp USING_EXTERNAL_CLOCK
	jr z, .ok
	ld a, 255
.wait_timeout
	dec a
	jr nz, .wait_timeout
.ok
	xor a
	ldh [hSerialReceivedNewData], a
	ldh a, [rIE]
	and IE_SERIAL | IE_TIMER | IE_STAT | IE_VBLANK
	sub IE_SERIAL
	jr nz, .skip_reload
	ld [wUnknownSerialCounter2], a
	ld a, $50
	ld [wUnknownSerialCounter2 + 1], a
.skip_reload
	ldh a, [hSerialReceiveData]
	cp SERIAL_NO_DATA_BYTE
	ret nz
	call IsUnknownCounterZero
	jr z, .done
	push hl
	ld hl, wUnknownSerialCounter + 1
	ld a, [hl]
	dec a
	ld [hld], a
	inc a
	jr nz, .no_borrow
	dec [hl]
.no_borrow
	pop hl
	call IsUnknownCounterZero
	jr z, SetUnknownCounterToFFFF
.done
	ldh a, [rIE]
	and IE_SERIAL | IE_TIMER | IE_STAT | IE_VBLANK
	cp IE_SERIAL
	ld a, SERIAL_NO_DATA_BYTE
	ret z
	ld a, [hl]
	ldh [hSerialSendData], a
	call DelayFrame
	jp Serial_ExchangeByte

WaitLoop_15Iterations::
	ld a, 15
.loop
	dec a
	jr nz, .loop
	ret

IsUnknownCounterZero::
	push hl
	ld hl, wUnknownSerialCounter
	ld a, [hli]
	or [hl]
	pop hl
	ret

SetUnknownCounterToFFFF::
	dec a
	ld [wUnknownSerialCounter], a
	ld [wUnknownSerialCounter + 1], a
	ret

Serial_ExchangeLinkMenuSelection::
	ld hl, wLinkMenuSelectionSendBuffer
	ld de, wLinkMenuSelectionReceiveBuffer
	ld c, 2
	ld a, 1
	ldh [hSerialIgnoringInitialData], a
.loop
	call DelayFrame
	ld a, [hl]
	ldh [hSerialSendData], a
	call Serial_ExchangeByte
	ld b, a
	inc hl
	ldh a, [hSerialIgnoringInitialData]
	and a
	ld a, 0
	ldh [hSerialIgnoringInitialData], a
	jr nz, .loop
	ld a, b
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	ret

Serial_PrintWaitingTextAndSyncAndExchangeNybble::
	call SaveScreenTilesToBuffer1
	callfar PrintWaitingText
	call Serial_SyncAndExchangeNybble
	jp LoadScreenTilesFromBuffer1

Serial_SyncAndExchangeNybble::
	ld a, $ff
	ld [wSerialExchangeNybbleReceiveData], a
.loop1
	call Serial_ExchangeNybble
	call DelayFrame
	call IsUnknownCounterZero
	jr z, .next1
	push hl
	ld hl, wUnknownSerialCounter + 1
	dec [hl]
	jr nz, .next2
	dec hl
	dec [hl]
	jr nz, .next2
	pop hl
	xor a
	jp SetUnknownCounterToFFFF
.next2
	pop hl
.next1
	ld a, [wSerialExchangeNybbleReceiveData]
	inc a
	jr z, .loop1
	ld b, 10
.loop2
	call DelayFrame
	call Serial_ExchangeNybble
	dec b
	jr nz, .loop2
	ld b, 10
.loop3
	call DelayFrame
	call Serial_SendZeroByte
	dec b
	jr nz, .loop3
	ld a, [wSerialExchangeNybbleReceiveData]
	ld [wSerialSyncAndExchangeNybbleReceiveData], a
	ret

Serial_ExchangeNybble::
	call .exchange
	ld a, [wSerialExchangeNybbleSendData]
	add $60
	ldh [hSerialSendData], a
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr nz, .exchange
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
.exchange
	ldh a, [hSerialReceiveData]
	ld [wSerialExchangeNybbleTempReceiveData], a
	and $f0
	cp $60
	ret nz
	xor a
	ldh [hSerialReceiveData], a
	ld a, [wSerialExchangeNybbleTempReceiveData]
	and $f
	ld [wSerialExchangeNybbleReceiveData], a
	ret

Serial_SendZeroByte::
	xor a
	ldh [hSerialSendData], a
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	ret nz
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
	ret

Serial_TryEstablishingExternallyClockedConnection::
	ld a, ESTABLISH_CONNECTION_WITH_EXTERNAL_CLOCK
	ldh [rSB], a
	xor a
	ldh [hSerialReceiveData], a
	ld a, SC_START | SC_EXTERNAL
	ldh [rSC], a
	ret

PrinterSerial__::
	call PrinterSerial
	pop hl
	pop de
	pop bc
	pop af
	reti
