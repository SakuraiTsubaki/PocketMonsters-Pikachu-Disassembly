# Japanese main font

The Japanese Pikachu retail ROM stores the main text font as 128 uncompressed 8×8 1bpp tiles. `FontGraphics` spans bank 4 addresses `0x4A19` through `0x4E19`, corresponding to file offsets `0x10A19` through `0x10E19`.

The layout and symbol boundary are corroborated by `Narishma-gb/pokeyellow-jp` source commit `f282e72ae26232790fdb780aa5a5db7ec8ebf572` (`gfx/font.asm`, `home/load_font.asm`, and `gfx/font/font.png`) and symbols commit `d19d9c5d5503db20e57479bfb76d5afb304a45b3` (`pokeyellow.sym`, `pokeyellow11.sym`, `pokeyellow12.sym`, and `pokeyellow13.sym`). The source PNG converts to one unique 1024-byte sequence in each verified local retail ROM at the documented offset.

Japanese revisions 0 through 3 have the same font range SHA-256, `11bfba65ad8f3b4a93f3c9b400afb611fb4072b26e2c40c77aab67bd08c9bf15`. `graphics/font/main-font-jp.png` is a deterministic 4× nearest-neighbour rendering produced by the common `extract_gb_1bpp.py` tool. The repository stores the PNG and hashes, not the raw ROM range or a ROM image.
