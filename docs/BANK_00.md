# Bank 00 Reconstruction Notes

Bank `00` is the fixed ROM0 bank (`$0000-$3FFF`). It contains reset vectors, interrupt vectors, the cartridge entry point, and the high-frequency home routines that remain callable without switching ROM banks.

## Verified binary facts

All nine unique reference ROMs were compared directly.

### Common vectors

The following vector pattern is common to every release except where noted:

- `$0000`, `$0008`, `$0010`, `$0018`, `$0020`, `$0028`, `$0030`: `RST $38` followed by zero padding to the next vector.
- `$0038`: normally `RST $38`; Japanese V1.0 instead contains `JP $F080`, an invalid/unused jump into echo RAM.
- `$0040`: jump to VBlank handler.
- `$0048`: jump to LCD STAT handler.
- `$0050`: jump to Timer handler.
- `$0058`: jump to Serial handler.
- `$0060`: `RETI` joypad interrupt stub.

Japanese releases leave `$0061-$0067` unused. International releases immediately place high-frequency home code after `$0060`.

### Entry point at `$0100`

Every release begins with `NOP` + absolute `JP`.

- Japanese V1.0: jump target `$1D60`.
- Japanese V1.1/V1.2/V1.3: jump target `$1D66`.
- English/French/German/Italian/Spanish: jump target `$01AB`.

The international `$01AB` routine detects the CGB boot value in register A, stores a boolean in `hOnCGB`, and then jumps to the common initialization routine. Japanese headers jump directly to initialization.

## Structural families

Bank 00 is not one byte-identical layout with translated text. It has two structural families.

### Japanese family

- DMG/SGB cartridge path.
- MBC3 cartridge type.
- The `lcd`, `clear_sprites`, and `copy` home routines live in the main Home section.
- No international `copy2` or `cgb_palettes` home modules.
- V1.0 has a unique `$0038` vector and a substantially different ROM0 layout from V1.1+.

Adjacent revision comparison inside Bank 00:

- V1.0 -> V1.1: 15,610 differing bytes across 435 contiguous difference ranges.
- V1.1 -> V1.2: 31 differing bytes across 18 ranges.
- V1.2 -> V1.3: 200 differing bytes across 30 ranges.

This makes V1.1/V1.2/V1.3 good candidates for narrow revision conditionals, while V1.0 requires careful layout-aware reconstruction rather than a superficial patch list.

### International family

- CGB-aware/SGB path.
- MBC5 cartridge type.
- `lcd`, `clear_sprites`, and the first `copy` block are placed in a separate `High Home` section immediately after the joypad vector.
- `copy2` and `cgb_palettes` are present later in ROM0.
- The cartridge entry point is stable at `$01AB` across EN/FR/DE/IT/ES.

The individual handler addresses vary because localization changes later ROM0 layout. That is expected and should be resolved through labels rather than hard-coded addresses.

## Byte-verified shared routines

Two routine groups have already been located directly in all nine ROMs with identical machine-code bytes:

| Routine source | International offset | Japanese V1.0 | Japanese V1.1-V1.3 |
| --- | ---: | ---: | ---: |
| `home/lcd.asm` | `$0061` | `$1597` | `$159D` |
| `home/clear_sprites.asm` | `$0082` | `$15B8` | `$15BE` |
| copy block start | `$009D` | `$15D3` | `$15D9` |

The first two groups are therefore represented by one common source file each. The copy helpers share semantics but have different grouping/order between the Japanese and international layouts, so `home/copy.asm` and `home/copy2.asm` use narrowly scoped family conditionals.

## Source reconstruction in repository

The first real RGBDS source files now exist:

- `home/header.asm` — reset vectors, interrupt vectors, and cartridge entry point.
- `home/start.asm` — international CGB boot-mode bridge plus the Japanese unused `_Start` stub.
- `home/lcd.asm` — shared LCD disable/enable routines.
- `home/clear_sprites.asm` — shared shadow-OAM clearing/hiding routines.
- `home/copy.asm` — Japanese complete copy group / international High Home subset.
- `home/copy2.asm` — international continuation of copy and VRAM helpers.
- `home.asm` — unified JP/INTL module ordering with narrowly scoped conditionals.

The read-only `tools/survey_bank00.py` utility reproduces the ROM0 hash/header/vector/difference survey from user-supplied local reference files without copying those ROMs into the repository.

## External label/layout cross-checks

Public disassemblies used only as comparison references:

- `pret/pokeyellow` — international/English home layout.
- `Narishma-gb/pokeyellow-jp` — Japanese home layout and revision conditionals.
- `Narishma-gb/pokeyellow-fr` — confirms French layout follows the international family.
- `Brianum/pokeyellow-de` — confirms German layout follows the international family.

Italian and Spanish are being verified directly from their reference ROMs against the international structure.

## Next Bank 00 work

1. Reconstruct `init.asm`, `vblank.asm`, `serial.asm`, and `timer.asm`, resolving all interrupt-vector targets by label.
2. Reconstruct the intervening `pikachu_cries`, `joypad`, `overworld`, `pokemon`, `pics`, `pikachu`, and `lcdc` modules in ROM order.
3. Add hardware/constants/WRAM/HRAM definitions needed to assemble the reconstructed Home modules.
4. Generate per-release RGBDS `.map`/`.sym` files and compare every Bank 00 byte.
5. Mark Bank 00 complete only after all nine targets reproduce `$0000-$3FFF` byte-for-byte.
