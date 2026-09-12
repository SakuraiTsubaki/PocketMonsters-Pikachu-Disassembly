# Bank 00 Reconstruction Notes

Bank `00` is the fixed ROM0 bank (`$0000-$3FFF`). It contains reset vectors, interrupt vectors, the cartridge entry point, and the high-frequency home routines that remain callable without switching ROM banks.

## Verified binary facts

All nine unique reference ROMs were compared directly.

### Common vectors

The following vector pattern is common to every release except where noted:

- `$0000`, `$0008`, `$0010`, `$0018`, `$0020`, `$0028`, `$0030`: `RST $38` followed by zero padding to the next vector.
- `$0038`: normally `RST $38`; Japanese V1.0 instead contains `JP $F080`, an invalid/unused jump into echo RAM.
- `$0040`: jump to VBlank handler.
- `$0048`: jump to LCD STAT handler (`LCDC`).
- `$0050`: jump to Timer handler.
- `$0058`: jump to Serial handler.
- `$0060`: `RETI` joypad interrupt stub.

Japanese releases leave `$0061-$0067` unused. International releases immediately place high-frequency home code after `$0060`.

### Verified handler/entry addresses

These addresses are extracted directly from the nine reference ROMs. They are also recorded machine-readably in `config/bank00_vectors.json`.

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
| `es` | `$01AB` | `$1D0F` | `$1DE4` | `$15AC` | `$1F78` | `$2169` |

The `Serial` entry to `Timer` entry span is exactly **497 bytes in every target**. This is a strong cross-release structural invariant even though relocation-sensitive absolute operands differ between builds.

### Entry point at `$0100`

Every release begins with `NOP` + absolute `JP`.

- Japanese V1.0 jumps directly to `$1D60` (`Init`).
- Japanese V1.1/V1.2/V1.3 jump directly to `$1D66` (`Init`).
- English/French/German/Italian/Spanish jump to `$01AB`, a short CGB-detection bridge that then jumps to the release-specific `Init` address shown above.

## Structural families

Bank 00 is not one byte-identical layout with translated text. It has two structural families.

### Japanese family

- DMG/SGB cartridge path.
- MBC3 cartridge type.
- The `lcd`, `clear_sprites`, and `copy` home routines live in the main Home section.
- No international `copy2` or `cgb_palettes` home modules.
- V1.0 has a unique `$0038` vector and a substantially different ROM0 layout from V1.1+.
- V1.0 VBlank does not call `ReadJoypad`; V1.1-V1.3 do.

Adjacent revision comparison inside Bank 00:

- V1.0 -> V1.1: 15,610 differing bytes across 435 contiguous difference ranges.
- V1.1 -> V1.2: 31 differing bytes across 18 ranges.
- V1.2 -> V1.3: 200 differing bytes across 30 ranges.

### International family

- CGB-aware/SGB path.
- MBC5 cartridge type.
- `lcd`, `clear_sprites`, and the first `copy` block are placed in a separate `High Home` section immediately after the joypad vector.
- `copy2` and `cgb_palettes` are present later in ROM0.
- The cartridge entry point is stable at `$01AB` across EN/FR/DE/IT/ES.
- VBlank preserves `rVBK`, forces VRAM bank 0 while servicing the interrupt, then restores the previous bank.

## Byte-verified shared routines

The following routine groups have already been located directly in all nine ROMs:

| Routine source | International offset | Japanese V1.0 | Japanese V1.1-V1.3 |
| --- | ---: | ---: | ---: |
| `home/lcd.asm` | `$0061` | `$1597` | `$159D` |
| `home/clear_sprites.asm` | `$0082` | `$15B8` | `$15BE` |
| copy block start | `$009D` | `$15D3` | `$15D9` |

`home/lcd.asm` and `home/clear_sprites.asm` are machine-code identical across all nine releases. The copy helpers share semantics but have different grouping/order between the Japanese and international layouts.

## Source reconstruction in repository

The active RGBDS source tree now includes:

- `home/header.asm` — reset vectors, interrupt vectors, and cartridge entry point.
- `home/start.asm` — international CGB boot-mode bridge plus the Japanese unused `_Start` stub.
- `home/lcd.asm` — shared LCD disable/enable routines.
- `home/clear_sprites.asm` — shared shadow-OAM clearing/hiding routines.
- `home/copy.asm` — Japanese complete copy group / international High Home subset.
- `home/copy2.asm` — international continuation of copy and VRAM helpers.
- `home/init.asm` — unified initialization logic with JP/INTL HRAM/audio-state differences isolated.
- `home/vblank.asm` — unified VBlank handler with CGB VRAM-bank handling and JP V1.0 joypad behavior isolated.
- `home/serial.asm` — common serial/link core reconstructed for all releases.
- `home/timer.asm` — common immediate-return timer interrupt stub.
- `home.asm` — unified JP/INTL module ordering with narrowly scoped conditionals.

The read-only `tools/survey_bank00.py` utility now extracts the ROM0 hashes, header metadata, vector bytes, interrupt targets, entry/Init targets, Serial-to-Timer span, and pairwise Bank 00 differences from local reference files without copying those ROMs into the repository.

## External label/layout cross-checks

Public disassemblies used as comparison references:

- `pret/pokeyellow` — international/English home layout.
- `Narishma-gb/pokeyellow-jp` — Japanese home layout and revision conditionals.
- `Narishma-gb/pokeyellow-fr` — French international-family layout.
- `Brianum/pokeyellow-de` — German international-family layout.

Italian and Spanish are being verified directly from their reference ROMs against the international structure.

## Next Bank 00 work

1. Reconstruct the modules before `Init` in ROM order: `pikachu_cries`, `joypad`, `overworld`, `pokemon`, `print_bcd`, `pics`, `pikachu`, `lcdc`, `text`, and `vcopy`.
2. Reconstruct `fade`, `play_time`, `audio`, and `update_sprites` around the now-restored VBlank/Serial core.
3. Add hardware/constants/WRAM/HRAM definitions required to assemble the reconstructed Home modules.
4. Generate per-release RGBDS `.map`/`.sym` files and automatically compare the emitted handler addresses with `config/bank00_vectors.json`.
5. Mark Bank 00 complete only after all nine targets reproduce `$0000-$3FFF` byte-for-byte.
