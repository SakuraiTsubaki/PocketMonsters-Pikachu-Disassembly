; wSpriteLoadFlags bits, streamed from compressed sprite data
	const_def
	const BIT_USE_SPRITE_BUFFER_2 ; 0
	const BIT_LAST_SPRITE_CHUNK   ; 1

; bankswitches and runs _UncompressSpriteData
; bank is given in a, sprite input stream is pointed to in wSpriteInputPtr
UncompressSpriteData::
	ld b, a
	ldh a, [hLoadedROMBank]
	push af
	ld a, b
	call BankswitchCommon
	ld a, BANK("Sprite Buffers")
	call OpenSRAM
	call _UncompressSpriteData
	call CloseSRAM
	pop af
	call BankswitchCommon
	ret

; initializes necessary data to load a sprite and runs UncompressSpriteDataLoop
_UncompressSpriteData::
	ld hl, sSpriteBuffer1
	ld c, LOW(2 * SPRITEBUFFERSIZE)
	ld b, HIGH(2 * SPRITEBUFFERSIZE)
	xor a
	call FillMemory           ; clear sprite buffer 1 and 2
	ld a, $1
	ld [wSpriteInputBitCounter], a
	ld a, $3
	ld [wSpriteOutputBitOffset], a
	xor a
	ld [wSpriteCurPosX], a
	ld [wSpriteCurPosY], a
	ld [wSpriteLoadFlags], a
	call ReadNextInputByte    ; first byte of input determines sprite width (high nybble) and height (low nybble) in tiles (8x8 pixels)
	ld b, a
	and $f
	add a
	add a
	add a
	ld [wSpriteHeight], a
	ld a, b
	swap a
	and $f
	add a
	add a
	add a
	ld [wSpriteWidth], a
	call ReadNextInputBit
	ld [wSpriteLoadFlags], a ; initialize bit1 to 0 and bit0 to the first input bit
                             ; this will load two chunks of data to sSpriteBuffer1 and sSpriteBuffer2
                             ; bit 0 decides in which one the first chunk is placed
	; fall through

; uncompresses a chunk from the sprite input data stream (pointed to by wSpriteInputPtr) into sSpriteBuffer1 or sSpriteBuffer2
; each chunk is a 1bpp sprite. A 2bpp sprite consist of two chunks which are merged afterwards
; note that this is an endless loop which is terminated during a call to MoveToNextBufferPosition by manipulating the stack
UncompressSpriteDataLoop::
	ld hl, sSpriteBuffer1
	ld a, [wSpriteLoadFlags]
	bit BIT_USE_SPRITE_BUFFER_2, a
	jr z, .useSpriteBuffer1    ; check which buffer to use
	ld hl, sSpriteBuffer2
.useSpriteBuffer1
	call StoreSpriteOutputPointer
	ld a, [wSpriteLoadFlags]
	bit BIT_LAST_SPRITE_CHUNK, a
	jr z, .startDecompression  ; check if last iteration
	call ReadNextInputBit      ; if last chunk, read 1-2 bit unpacking mode
	and a
	jr z, .unpackingMode0      ; 0   -> mode 0
	call ReadNextInputBit      ; 1 0 -> mode 1
	inc a                      ; 1 1 -> mode 2
.unpackingMode0
	ld [wSpriteUnpackMode], a
.startDecompression
	call ReadNextInputBit
	and a
	jr z, .readRLEncodedZeros ; if first bit is 0, the input starts with zeroes, otherwise with (non-zero) input
.readNextInput
	call ReadNextInputBit
	ld c, a
	call ReadNextInputBit
	sla c
	or c                       ; read next two bits into c
	and a
	jr z, .readRLEncodedZeros ; 00 -> RLEncoded zeroes following
	call WriteSpriteBitsToBuffer  ; otherwise write input to output and repeat
	call MoveToNextBufferPosition
	jr .readNextInput
.readRLEncodedZeros
	ld c, $0                   ; number of zeroes it length encoded, the number
.countConsecutiveOnesLoop      ; of consecutive ones determines the number of bits the number has
	call ReadNextInputBit
	and a
	jr z, .countConsecutiveOnesFinished
	inc c
	jr .countConsecutiveOnesLoop
.countConsecutiveOnesFinished
	ld a, c
	add a
	ld hl, LengthEncodingOffsetList
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	ld a, [hli]                ; read offset that is added to the number later on
	ld e, a                    ; adding an offset of 2^length - 1 makes every integer uniquely
	ld d, [hl]                 ; representable in the length encoding and saves bits
	push de
	inc c
	ld e, $0
	ld d, e
.readNumberOfZerosLoop        ; reads the next c+1 bits of input
	call ReadNextInputBit
	or e
	ld e, a
	dec c
	jr z, .readNumberOfZerosDone
	sla e
	rl d
	jr .readNumberOfZerosLoop
.readNumberOfZerosDone
	pop hl                     ; add the offset
	add hl, de
	ld e, l
	ld d, h
.writeZerosLoop
	ld b, e
	xor a                      ; write 00 to buffer
	call WriteSpriteBitsToBuffer
	ld e, b
	call MoveToNextBufferPosition
	dec de
	ld a, d
	and a
	jr nz, .continueLoop
	ld a, e
	and a
.continueLoop
	jr nz, .writeZerosLoop
	jr .readNextInput

; moves output pointer to next position
; also cancels the calling function if the all output is done (by removing the return pointer from stack)
; and calls postprocessing functions according to the unpack mode
MoveToNextBufferPosition::
	ld a, [wSpriteHeight]
	ld b, a
	ld a, [wSpriteCurPosY]
	inc a
	cp b
	jr z, .curColumnDone
	ld [wSpriteCurPosY], a
	ld a, [wSpriteOutputPtr]
	inc a
	ld [wSpriteOutputPtr], a
	ret nz
	ld a, [wSpriteOutputPtr + 1]
	inc a
	ld [wSpriteOutputPtr + 1], a
	ret
.curColumnDone
	xor a
	ld [wSpriteCurPosY], a
	ld a, [wSpriteOutputBitOffset]
	and a
	jr z, .bitOffsetsDone
	dec a
	ld [wSpriteOutputBitOffset], a
	ld hl, wSpriteOutputPtrCached
	ld a, [hli]
	ld [wSpriteOutputPtr], a
	ld a, [hl]
	ld [wSpriteOutputPtr + 1], a
	ret
.bitOffsetsDone
	ld a, $3
	ld [wSpriteOutputBitOffset], a
	ld a, [wSpriteCurPosX]
	add $8
	ld [wSpriteCurPosX], a
	ld b, a
	ld a, [wSpriteWidth]
	cp b
	jr z, .allColumnsDone
	ld a, [wSpriteOutputPtr]
	ld l, a
	ld a, [wSpriteOutputPtr + 1]
	ld h, a
	inc hl
	jp StoreSpriteOutputPointer
.allColumnsDone
	pop hl
	xor a
	ld [wSpriteCurPosX], a
	ld a, [wSpriteLoadFlags]
	bit BIT_LAST_SPRITE_CHUNK, a
	jr nz, .done            ; test if there is one more sprite to go
	xor 1 << BIT_USE_SPRITE_BUFFER_2
	set BIT_LAST_SPRITE_CHUNK, a
	ld [wSpriteLoadFlags], a
	jp UncompressSpriteDataLoop
.done
	jp UnpackSprite

; writes 2 bits (from a) to the output buffer (pointed to from wSpriteOutputPtr)
WriteSpriteBitsToBuffer::
	ld e, a
	ld a, [wSpriteOutputBitOffset]
	and a
	jr z, .offset0
	cp $2
	jr c, .offset1
	jr z, .offset2
	rrc e ; offset 3
	rrc e
	jr .offset0
.offset1
	sla e
	sla e
	jr .offset0
.offset2
	swap e
.offset0
	ld a, [wSpriteOutputPtr]
	ld l, a
	ld a, [wSpriteOutputPtr + 1]
	ld h, a
	ld a, [hl]
	or e
	ld [hl], a
	ret

; reads next bit from input stream and returns it in a
ReadNextInputBit::
	ld a, [wSpriteInputBitCounter]
	dec a
	jr nz, .curByteHasMoreBitsToRead
	call ReadNextInputByte
	ld [wSpriteInputCurByte], a
	ld a, $8
.curByteHasMoreBitsToRead
	ld [wSpriteInputBitCounter], a
	ld a, [wSpriteInputCurByte]
	rlca
	ld [wSpriteInputCurByte], a
	and $1
	ret

; reads next byte from input stream and returns it in a
ReadNextInputByte::
	ld a, [wSpriteInputPtr]
	ld l, a
	ld a, [wSpriteInputPtr + 1]
	ld h, a
	ld a, [hli]
	ld b, a
	ld a, l
	ld [wSpriteInputPtr], a
	ld a, h
	ld [wSpriteInputPtr + 1], a
	ld a, b
	ret

; the nth item is 2^n - 1
LengthEncodingOffsetList::
	dw %0000000000000001
	dw %0000000000000011
	dw %0000000000000111
	dw %0000000000001111
	dw %0000000000011111
	dw %0000000000111111
	dw %0000000001111111
	dw %0000000011111111
	dw %0000000111111111
	dw %0000001111111111
	dw %0000011111111111
	dw %0000111111111111
	dw %0001111111111111
	dw %0011111111111111
	dw %0111111111111111
	dw %1111111111111111

; unpacks the sprite data depending on the unpack mode
UnpackSprite::
	ld a, [wSpriteUnpackMode]
	cp $2
	jp z, UnpackSpriteMode2
	and a
	jp nz, XorSpriteChunks
	ld hl, sSpriteBuffer1
	call SpriteDifferentialDecode
	ld hl, sSpriteBuffer2
	; fall through
