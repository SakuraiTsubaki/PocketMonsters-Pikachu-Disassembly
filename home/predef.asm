Predef::
; Call predefined function a.
; To preserve other registers, have the destination call GetPredefRegisters.
	ld [wPredefID], a
	ldh a, [hLoadedROMBank]
	ld [wPredefParentBank], a
	push af
	ld a, BANK(GetPredefPointer)
	ldh [hLoadedROMBank], a
	ld [rROMB], a
	call GetPredefPointer
	ld a, [wPredefBank]
	call BankswitchCommon
	ld de, .done
	push de
	jp hl
.done
	pop af
	call BankswitchCommon
	ret

GetPredefRegisters::
	ld a, [wPredefHL]
	ld h, a
	ld a, [wPredefHL + 1]
	ld l, a
	ld a, [wPredefDE]
	ld d, a
	ld a, [wPredefDE + 1]
	ld e, a
	ld a, [wPredefBC]
	ld b, a
	ld a, [wPredefBC + 1]
	ld c, a
	ret
