SECTION "FillMemory Reconstruction", ROM0

FillMemory::
    push af
    ld a, b
    and a
    jr z, .eight_bit_amount
    ld a, c
    and a
    jr z, .multiple_of_100
.eight_bit_amount
    inc b
.multiple_of_100
    pop af
.loop
    ld [hli], a
    dec c
    jr nz, .loop
    dec b
    jr nz, .loop
    ret
