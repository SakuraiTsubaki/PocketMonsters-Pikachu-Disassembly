# European main fonts

The official German, French, Spanish, and Italian Yellow releases each load a 128-tile 1bpp main font from file offset `0x10600`. The common publication-safe locator at `SakuraiTsubaki/Disassembly` commit `1f9c7696f5071a5c546085afe50e1a23f49f645e` found exactly one matching loader in every ROM: German at `0x3688`, French at `0x3686`, Spanish at `0x3688`, and Italian at `0x3681`.

German and French share range SHA-256 `d05ea7a9245f217f2354a7067751b5e4b415adc9975edf256b83a352236754ab`. Spanish and Italian share `8b8fa58ed6e3e649cb9d253a1aa2732737141ec30ece6761d4260b5e4d64e575`. These are distinct from the English font because their glyph sets include localized characters.

The four `graphics/font/main-font-*.png` files are deterministic 4× nearest-neighbour renderings. Separate language paths are retained even where the bytes match so each official release has direct provenance. No ROM image or raw ROM range is published.
