# English main font

The official English Yellow retail ROM stores the main text font as 128 uncompressed 8×8 1bpp tiles. `FontGraphics` spans bank 4 addresses `0x4600` through `0x4A00`, corresponding to file offsets `0x10600` through `0x10A00`.

The boundary and loading format are corroborated by `pret/pokeyellow` source commit `e89ead154b9968aa50eed9328ff2b38b6c194382` (`gfx/font.asm`, `home/load_font.asm`, and `gfx/font/font.png`) and symbols commit `573535d742a347c6b20ab74f962df4c9820a0bbb` (`pokeyellow.sym`). The source PNG has the same decoded 1bpp SHA-256 as `pret/pokered`; its byte sequence occurs once in the verified English Yellow ROM at the documented offset.

The range SHA-256 is `7da47648890723845fd71777e0ef6616c38f145a02a2aa58ca71d3460381d898`. `graphics/font/main-font-en.png` is a deterministic 4× nearest-neighbour rendering. No ROM image or raw ROM range is published.
