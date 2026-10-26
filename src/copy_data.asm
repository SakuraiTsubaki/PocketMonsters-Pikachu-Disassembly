; Generation I byte-copy routine across all catalogued Yellow releases.
; All variants use bank $3e; JP rev0-rev3 $5e60, international addresses vary.

CopyData::
    ld a, [hli]
    ld [de], a
    inc de
    dec bc
    ld a, c
    or b
    jr nz, CopyData
    ret
