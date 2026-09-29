# Japanese entry-target basic block

The exact-hash Japanese revision 0 origin candidate reaches `0x1d60`. The 52-byte first basic block disables interrupts, clears hardware registers, calls `$1597`, initializes the stack and WRAM-clear loop, then terminates at `jr nz $1d8c`. The committed RGBDS source preserves all 27 decoded instructions. The manifest binds provenance without storing ROM bytes, and the candidate remains unverified.
