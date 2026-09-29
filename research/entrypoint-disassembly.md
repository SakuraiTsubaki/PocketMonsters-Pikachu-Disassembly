# Japanese cartridge entry disassembly

The exact-hash Japanese origin candidate stores `00c3601d` at cartridge offset `0x0100`. This decodes as `nop` followed by `jp $1d60`. The committed RGBDS source reconstructs all four bytes, and tests bind the encoded bytes to both the analysis report and source-slice SHA-256 `49b347b760add93011e7da6326f1a76a03f8cf29c2489b69d5937a0b9c429805`.

This establishes the fixed cartridge entry only. It neither promotes the candidate release nor claims that the branch target's complete routine has been disassembled.

