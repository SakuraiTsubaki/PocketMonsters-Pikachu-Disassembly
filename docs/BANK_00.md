# Bank 00 Reconstruction Notes

Bank `00` is the fixed ROM0 bank (`$0000-$3FFF`). It contains reset vectors, interrupt vectors, the cartridge entry point, and high-frequency Home routines callable without switching ROM banks.

## Verified binary facts

All nine unique reference ROMs were compared directly.

### Common vectors

- `$0000`, `$0008`, `$0010`, `$0018`, `$0020`, `$0028`, `$0030`: `RST $38` followed by zero padding.
- `$0038`: normally `RST $38`; Japanese V1.0 instead contains `JP $F080`, an invalid/unused jump into echo RAM.
- `$0040`: jump to `VBlank`.
- `$0048`: jump to `LCDC`.
- `$0050`: jump to `Timer`.
- `$0058`: jump to `Serial`.
- `$0060`: `RETI` joypad interrupt stub.

Japanese releases leave `$0061-$0067` unused. International releases place high-frequency Home code immediately after `$0060`.

### Verified handler/entry addresses

These addresses are extracted directly from the nine reference ROMs and are recorded machine-readably in `config/bank00_vectors.json`.

| Target | Entry | Init | VBlank | LCDC | Serial | Timer |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `jp-rev0a` | `$1D60` | `$1D60` | `$1E35` | `$1580` | `$1FA2` | `$2193` |
| `jp-revb` | `$1D66` | `$1D66` | `$1E3B` | `$1586` | `$1FAB` | `$219C` |
| `jp-revc` | `$1D66` | `$1D66` | `$1E3B` | `$1586` | `$1FAB` | `$219C` |
| `jp-revd` | `$1D66` | `$1D66` | `$1E3B` | `$1586` | `$1FAB` | `$219C` |
| `en-us-eu` | `$01AB` | `$1D10` | `$1DE5` | `$15AC` | `$1F79` | `$216A` |
| `fr` | `$01AB` | `$1D0C` | `$1DE1` | `$15A9` | `$1F75` | `$2166` |
| `de` | `$01AB` | `$1D15` | `$1DEA` | `$15AC` | `$1F7E` | `$216F` |
| `it` | `$01AB` | `$1D10` | `$1DE5` | `$15AC` | `$1F79` | `$216A` |
| `es` | `$01AB` | `$1D0F` | `$1D0F` | `$15AC` | `$1F78` | `$2169` |

The `Serial` entry to `Timer` entry span is exactly **497 bytes in every target**.

> Note: the canonical vector/address manifest remains `config/bank00_vectors.json`; if this prose table and that manifest ever disagree, the machine-readable manifest and direct ROM survey win.

## Structural families

### Japanese family

- DMG/SGB path, MBC3 cartridge type.
- `lcd`, `clear_sprites`, and `copy` live in the main Home section.
- No international `copy2` or `cgb_palettes` modules.
- V1.0 has the unique `$0038` vector and several ROM0 revision-specific code-generation differences.
- V1.0 VBlank does not call `ReadJoypad`; V1.1-V1.3 do.
- `TrackPlayTime` calls `CountDownIgnoreInputBitReset` at a different point in V1.0/V1.1 versus V1.2/V1.3.
- Text rendering uses kana-specific dakuten/handakuten handling, full-width spaces/digits, and Japanese inline Home strings where the international family often uses far text.

### International family

- CGB-aware/SGB path, MBC5 cartridge type.
- `lcd`, `clear_sprites`, and the first copy block live in `High Home` directly after the joypad vector.
- `copy2` and `cgb_palettes` are present later in ROM0.
- VBlank preserves `rVBK`, forces VRAM bank 0 while servicing the interrupt, then restores it.
- Palette fades also mirror DMG palette changes into CGB palette update helpers.
- EN/FR/DE/IT/ES share the text-engine family but do **not** have one byte-identical character map.
- UI behavior also has locale subfamilies. For example list-menu currency rendering splits into EN/DE/IT (`MONEY_SIGN`) and FR/ES (explicit `¥` tile), while Japanese uses explicit `円`.

## Reconstruction status

Machine-readable module status is maintained in `config/bank00_modules.json`.

### Home source reconstruction: complete

Every module in the current `home.asm` Bank 00 sequence now has repository source. The status is deliberately **source reconstruction / reference cross-check**, not yet a claim of complete assembled byte identity.

The reconstructed sequence includes:

- vectors/startup, LCD/VBlank/serial/timer/audio and bank switching
- overworld movement, warps, map loading, collision, map objects and NPC movement
- text renderer, text commands, text scripts, menus, list menus and predefined text
- sprite decompression/reload/OAM routines
- inventory, item price/use/give, marts and name lookup
- trainer encounter/battle wrappers and trainer metadata helpers
- palette/SGB/CGB Home helpers
- arithmetic, arrays, string copy/compare, random, delays and other Home utilities

Large modules such as `home/overworld.asm`, `home/text.asm`, and `home/uncompress.asm` are split into maintainable include files while preserving original ROM order.

### Directly byte/address verified core

The vector/entry/interrupt core has additional direct ROM verification beyond public-source cross-checking. Current per-module levels are recorded in `config/bank00_modules.json` rather than duplicated here.

### Locale/revision evidence captured separately

- `config/text_locale_matrix.json` — fixed Home text literals and text-engine family behavior.
- `config/name_locale_matrix.json` — localized TM/HM machine prefixes and Japanese name-slot behavior.
- `config/list_menu_locale_matrix.json` — list-menu currency families, cancellation strings, layout and direct ROM offsets.
- `tools/survey_bank00.py` — direct ROM0 vector/address/difference survey.
- `tools/survey_text_literals.py` — release-aware Home text literal verification.
- `tools/survey_list_menu.py` — release-aware quantity/cancel/currency evidence verification.

Important differences are represented narrowly instead of duplicating complete files. Examples include Japanese full-width number printing, kana diacritic rendering, JP V1.0 printer/joypad/bank-call behavior, international CGB palette synchronization, German yes/no box width, Japanese Pokémon Center yes/no geometry, and locale-specific list-menu currency rendering.

## What is still required before Bank 00 is byte-perfect

Source-level Home reconstruction is complete, but Bank 00 is **not yet declared byte-perfect complete**. The remaining work is build and dependency reconstruction:

- constants and target-selection definitions
- macros used by Home (`farcall`, `homecall`, text/script/menu helpers, coordinate helpers, assertions, etc.)
- per-target charmaps
- WRAM/HRAM/SRAM/VRAM semantic symbols and aliases
- cross-bank labels referenced by Home
- Home-included data dependencies and graphics such as font/textbox/status/flower assets
- pinned/tested RGBDS compatibility
- nine explicit build targets
- generated `.map`/`.sym` output
- direct assembled `$0000-$3FFF` comparison against all nine reference ROMs

No raw `baserom.gb`/`baserom.gbc` dependency is permitted in the finished build.

## Next phase

1. Reconstruct the shared assembler foundation: hardware/constants/macros and memory-symbol layers.
2. Add per-release build definitions for EN/FR/DE/IT/ES and JP V1.0-V1.3.
3. Continue Bank 01+ source reconstruction in ROM order while defining cross-bank symbols needed by Bank 00.
4. Bring in/reconstruct referenced assets as repository source assets rather than raw-ROM `INCBIN` ranges.
5. Produce per-release `.map`/`.sym` and compare Bank 00 byte-for-byte.
6. Only then mark Bank 00 complete for a target; mark Bank 00 globally complete only after all nine targets match `$0000-$3FFF` exactly.
