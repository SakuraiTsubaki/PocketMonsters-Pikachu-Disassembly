; Generation I hardware-divider RNG across all catalogued Yellow releases.
; JP rev0-rev3 bank $3d:$5bb9; EN/FR $3d:$67dc; DE $3d:$67d5;
; ES $3d:$67d4; IT $3d:$67d6.

Random_::
    ldh a, [rDIV]
    ld b, a
    ldh a, [hRandomAdd]
    adc b
    ldh [hRandomAdd], a
    ldh a, [rDIV]
    ld b, a
    ldh a, [hRandomSub]
    sbc b
    ldh [hRandomSub], a
    ret
