; Shared Gen I sprite decompression engine.
; EN/JP public disassemblies differ in formatting but not in the reconstructed
; retail control flow represented here. Full nine-target byte verification is
; deferred until dependent symbols and build targets are assembled.

INCLUDE "home/uncompress/decompress.asm"
INCLUDE "home/uncompress/differential_and_xor.asm"
INCLUDE "home/uncompress/postprocess.asm"
