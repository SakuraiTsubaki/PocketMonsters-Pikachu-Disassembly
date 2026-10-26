# Yellow CopyData reconstruction

All nine catalogued Yellow releases were SHA-256 gated and scanned independently. Each contains exactly one complete nine-byte `CopyData` loop in bank `$3E`. Japanese rev0-rev3 are the origin references; no official Generation I Korean release exists, so English and the remaining European languages follow.

The routine copies the nonzero BC-byte range at HL to DE, advances both pointers, and returns with BC zero. Every release has code SHA-256 `4c81b1d98cede80c642119edcb1c3f45c1f05e97c1d9aafcf250b065f33d495c`; localization changes only its address.

The name and semantics are corroborated by `pret/pokered@af519899719f0754965776faac0e836a3b906e6d`, `home/copy.asm`. Reports publish ROM identities, locations, semantics, and hashes without ROM bytes.
