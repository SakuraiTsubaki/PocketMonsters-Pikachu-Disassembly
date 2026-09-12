; function to do multiplication
; all values are big endian
Multiply::
	push hl
	push bc
	callfar _Multiply
	pop bc
	pop hl
	ret

; function to do division
; all values are big endian
Divide::
	push hl
	push de
	push bc
	homecall _Divide
	pop bc
	pop de
	pop hl
	ret
