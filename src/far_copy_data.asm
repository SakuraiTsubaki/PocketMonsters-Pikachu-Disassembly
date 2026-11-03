SECTION "FarCopyData Reconstruction", ROM0

FarCopyData::
    ld [wFarCopyDataSavedROMBank], a
    ldh a, [hLoadedROMBank]
    push af
    ld a, [wFarCopyDataSavedROMBank]
    call BankswitchCommon
    call CopyData
    pop af
    call BankswitchCommon
    ret
