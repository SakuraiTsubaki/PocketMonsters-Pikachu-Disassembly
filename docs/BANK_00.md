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
- `lcd`, `clear_sprites`, and `copy` are placed in a separate `High Home` section immediately after the joypad vector.
- `copy2` and `cgb_palettes` are present.
- The cartridge entry point is stable at `$01AB` across EN/FR/DE/IT/ES.

The individual handler addresses vary because localization changes later ROM0 layout. That is expected and should be resolved through labels rather than hard-coded addresses.

## Source reconstruction started

The repository now contains:

- `home/header.asm` — reset vectors, interrupt vectors, and cartridge entry point.
- `home/start.asm` — international CGB boot-mode bridge plus the Japanese unused `_Start` stub.
- `home.asm` — unified JP/INTL module ordering with narrowly scoped conditionals.

These are the first real RGBDS source files in the reconstruction. Child home modules will be added and independently verified against the nine reference ROMs before Bank 00 is marked reproducible.

## External label/layout cross-checks

Public disassemblies used only as comparison references:

- `pret/pokeyellow` — international/English home layout.
- `Narishma-gb/pokeyellow-jp` — Japanese home layout and revision conditionals.
- `Narishma-gb/pokeyellow-fr` — confirms French layout follows the international family.
- `Brianum/pokeyellow-de` — confirms German layout follows the international family.

Italian and Spanish are being verified directly from their reference ROMs against the international structure.

## Next Bank 00 work

1. Reconstruct `lcd.asm`, `clear_sprites.asm`, and `copy.asm` first because their placement distinguishes JP and international ROM0 layout.
2. Reconstruct `init.asm`, `vblank.asm`, `serial.asm`, and `timer.asm`, resolving all interrupt-vector targets by label.
3. Continue through the remaining `home/` modules in ROM order.
4. Generate per-release RGBDS `.map`/`.sym` files and compare every Bank 00 byte.
5. Mark Bank 00 complete only after all nine targets reproduce `$0000-$3FFF` byte-for-byte.
