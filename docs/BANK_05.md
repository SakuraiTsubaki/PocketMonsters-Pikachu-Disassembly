# Bank 05 survey

Bank 05 covers physical ROM range `0x14000-0x17FFF`. The pinned public sources split its active material across `bank5`, `Battle Engine 2`, and `Doors and Ledges`.

## Current status

- Survey status: **complete**
- Source reconstruction: **not yet complete**
- Byte-perfect rebuild claim: **not yet made**
- Nine unique reference Bank 05 hashes recorded
- JP Rev 0A/B/C `Garbage 5` preserved as editable ASM
- JP Rev D uses a 374-byte zero-filled tail
- Reference ROM bytes remain authoritative over public source when evidence conflicts.

## Family-specific source layout

### International — 7 top-level modules

`SECTION "bank5"`:

1. `engine/gfx/load_pokedex_tiles.asm`
2. `engine/overworld/map_sprites.asm`

`SECTION "Battle Engine 2"`:

3. `engine/battle/move_effects/substitute.asm`
4. `engine/menus/pc.asm`

`SECTION "Doors and Ledges"`:

5. `engine/overworld/auto_movement.asm`
6. `engine/overworld/doors.asm`
7. `engine/overworld/ledges.asm`

The international `engine/overworld/auto_movement.asm` contains a **nested include** of `engine/events/pewter_guys.asm`.

### Japanese — 8 top-level modules

`bank5` and `Battle Engine 2` use the same four paths and order as international. `Doors and Ledges` is:

5. `engine/overworld/auto_movement.asm`
6. `engine/events/pewter_guys.asm`
7. `engine/overworld/doors.asm`
8. `engine/overworld/ledges.asm`

Thus `pewter_guys.asm` is not Japanese-only content. The family difference is **top-level versus nested include placement**, which must be reconstructed without emitting the file twice.

## Bank SHA-1 values

| Target | Bank 05 SHA-1 |
| --- | --- |
| JP Rev 0A | `f24cc30bb77a5dd7dddc06d729d5bd234a10dfcc` |
| JP Rev B | `53d7ca866e4ec23c658bfe46adfcac5eaab10d04` |
| JP Rev C | `1f196bf33674ce76bbdc320ff0dd4ccc1b65782f` |
| JP Rev D | `006cc54ac31cea12c37b7013e38b6c78c5af932d` |
| EN USA/Europe | `14cb943d332b8b777b46a2d4ddd6c9660679c733` |
| FR | `2e94d15e1ccb5f388c7fe79d91940b0457a1ed9a` |
| DE | `f134289aedca6a566565129507457a9dfb1ca793` |
| IT | `b1230d9b47d4cfac4739914f6d978370638d52cd` |
| ES | `8a32f1fc027b164a7f9aeb4afedc57d340781209` |

All nine full-bank hashes are distinct.

## Japanese active region and revisions

The active/tail boundary is bank-local `$7E8A`, physical `0x17E8A`. The active region `0x14000-0x17E89` is 16,010 bytes and the final `0x17E8A-0x17FFF` range is a 374-byte historical tail.

| Comparison | Whole-bank differing bytes | Active differing bytes |
| --- | ---: | ---: |
| Rev 0A vs Rev B | 415 | 41 |
| Rev B vs Rev C | 67 | 0 |
| Rev C vs Rev D | 349 | 0 |

Therefore **Rev B, Rev C, and Rev D have byte-identical active Bank 05 payloads**. Their full-bank differences are confined to `Garbage 5` / zero fill.

Rev 0A differs from Rev B at 41 active bytes across 40 ranges. A pinned Japanese source search for `DEF(_REV0)` found no direct revision conditional in the Bank 05 top-level module paths, so those 41 bytes are not yet classified as local semantic changes. Their status remains `pending-symbol-aware-link-validation`; relocation caused by symbols outside Bank 05 is a candidate but is not yet claimed as fact.

## Garbage 5 preservation

The pinned Japanese garbage layout assigns `Garbage 5` to Bank 5 for Rev 0A/B/C, while Rev D leaves the corresponding range zero-filled.

| Revision | Range | Length | Raw SHA-1 | Public Git blob SHA-1 |
| --- | --- | ---: | --- | --- |
| JP Rev 0A | `0x17E8A-0x17FFF` | 374 | `2d09733845a5a930d1b90259443c8c7189be5c1e` | `39f2c42c2a5379bcfe83a6be230ffc2aa728cd19` |
| JP Rev B | `0x17E8A-0x17FFF` | 374 | `a317bfc33f110d857b3bf87396fd86e167189a45` | `447bd05ce79df6fb76eb9265b11ad3424ace483a` |
| JP Rev C | `0x17E8A-0x17FFF` | 374 | `4212d3c7390b61a623bb53c909a88bedd814c327` | `d80cc462b115747532c7e61f5ff01733b32b69d9` |
| JP Rev D | `0x17E8A-0x17FFF` | 374 zero bytes | `f51ebfd66841e4f950a7011e4934f895d409ccbf` | n/a |

These bytes are historical leftover data, not active engine code.

## International padding observation

All five international Bank 05 images have their last non-zero byte at bank-local `$7DE2` and 541 trailing zero bytes. The **last non-zero byte is not a source-section boundary**; this is padding evidence only.

## Next reconstruction phase

1. Compare the union of eight Bank 05 source paths between pinned JP and international references.
2. Classify exact-shared, cosmetic-only, and substantive differences.
3. Resolve `pewter_guys.asm` top-level/nested placement without duplicate byte emission.
4. Create `banks/bank05.asm` and wire Rev 0A/B/C Garbage 5 at `$7E8A`, leaving Rev D zero-filled.
5. Use symbol-aware linking to classify the 41 Rev 0A active differences before any semantic claim.
6. Defer byte-perfect completion until all nine target Bank 05 outputs can be linked and hash-checked.

The machine-readable source of truth is `config/bank05_modules.json`; `make bank05-check` validates this survey without requiring a ROM file.
