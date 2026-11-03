SECTION "CopyData Reconstruction", ROM0

CopyData::
    ld a, b
    and a
    jr z, .copybytes
    ld a, c
    and a
    jr z, .loop
    inc b
.loop
    call .copybytes
    dec b
    jr nz, .loop
    ret
.copybytes
    ld a, [hli]
    ld [de], a
    inc de
    dec c
    jr nz, .copybytes
    ret
