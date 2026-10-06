# Japanese startup main successor block

After the WRAM-clear loop, Japanese Pikachu revision 0 continues at
`0x1D94`. The 130-byte block performs HRAM setup, bank selection, display
and interrupt configuration, tile-map clearing, and initialization calls
before jumping to `0x416A`. The report records all 56 decoded instructions
and direct targets; RGBDS source is retained without a standalone ROM
fragment. The candidate remains unverified.

