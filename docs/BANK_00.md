# Bank 00 Reconstruction Notes

Bank `00` is the fixed ROM0 bank (`$0000-$3FFF`). It contains reset vectors, interrupt vectors, the cartridge entry point, and high-frequency home routines callable without switching ROM banks.

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

Japanese releases leave `$0061-$0067` unused. International releases place high-frequency home code immediately after `$0060`.

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
| `es` | `$01AB` | `$1D0F` | `$1DE4` | `$15AC` | `$1F78` | `$2169` |

The `Serial` entry to `Timer` entry span is exactly **497 bytes in every target**.

## Structural families

### Japanese family

- DMG/SGB path, MBC3 cartridge type.
- `lcd`, `clear_sprites`, and `copy` live in the main Home section.
- No international `copy2` or `cgb_palettes` modules.
- V1.0 has the unique `$0038` vector and several ROM0 revision-specific code-generation differences.
- V1.0 VBlank does not call `ReadJoypad`; V1.1-V1.3 do.
- `TrackPlayTime` calls `CountDownIgnoreInputBitReset` at a different point in V1.0/V1.1 versus V1.2/V1.3.

### International family

- CGB-aware/SGB path, MBC5 cartridge type.
- `lcd`, `clear_sprites`, and the first copy block live in `High Home` directly after the joypad vector.
- `copy2` and `cgb_palettes` are present later in ROM0.
- VBlank preserves `rVBK`, forces VRAM bank 0 while servicing the interrupt, then restores it.
- Palette fades also mirror DMG palette changes into CGB palette update helpers.

## Reconstruction status

Machine-readable module status is maintained in `config/bank00_modules.json`.

### Directly byte-verified / address-verified core

- `home/header.asm`
- `home/start.asm`
- `home/lcd.asm`
- `home/clear_sprites.asm`
- `home/lcdc.asm`
- `home/init.asm`
- `home/vblank.asm`
- `home/serial.asm`
- `home/timer.asm`

`home/lcd.asm`, `home/clear_sprites.asm`, and `home/lcdc.asm` have identical machine-code bodies across all nine releases. `Serial` is also structurally invariant across the nine ROMs, including the 497-byte Serial-to-Timer span.

### Reconstructed and EN/JP reference-crosschecked

- `home/copy.asm`
- `home/copy2.asm`
- `home/pikachu_cries.asm`
- `home/joypad.asm`
- `home/pokemon.asm`
- `home/print_bcd.asm`
- `home/pics.asm`
- `home/pikachu.asm`
- `home/vcopy.asm`
- `home/fade.asm`
- `home/play_time.asm`
- `home/audio.asm`
- `home/update_sprites.asm`

Important family/revision differences are represented narrowly instead of duplicating complete files. Examples include Japanese full-width digit handling in BCD output, Japanese inline status/menu text, CGB palette calls in international fades, JP V1.0 direct bank switching in `DetermineAudioFunction`, and the Japanese V1.0 joypad/VBlank behavior.

### Still pending in the current Home sequence

- `home/overworld.asm`
- `home/text.asm`
- remaining later Home modules after `update_sprites.asm`
- constants/macros/charmaps/WRAM/HRAM definitions required for an actual clean RGBDS assembly
- reconstructed flower graphics referenced by `home/vcopy.asm`

## Verification tooling

`tools/survey_bank00.py` reads local reference ROMs without copying them into the repository. It reports ROM0 hashes, headers, vector bytes, interrupt targets, entry/Init targets, Serial-to-Timer span, and pairwise Bank 00 differences.

The public comparison references currently used are:

- `pret/pokeyellow` — English/international source layout.
- `Narishma-gb/pokeyellow-jp` — Japanese V1.0-V1.3 source/revision layout.
- `Narishma-gb/pokeyellow-fr` — French international-family layout.
- `Brianum/pokeyellow-de` — German international-family layout.

Italian and Spanish continue to be verified from the local reference ROMs against the international structure.

## Next Bank 00 work

1. Reconstruct `home/overworld.asm` and classify its JP revision/localization differences.
2. Reconstruct `home/text.asm` with separate character/charmap behavior rather than mixing localized strings into engine logic.
3. Continue the remaining Home modules in ROM order.
4. Add the required constants, macros, charmaps, WRAM/HRAM symbols, and graphics assets.
5. Pin a tested RGBDS toolchain, generate per-release `.map`/`.sym`, and compare every emitted Bank 00 byte against all nine references.
6. Mark Bank 00 complete only when `$0000-$3FFF` is byte-for-byte identical for every target.
