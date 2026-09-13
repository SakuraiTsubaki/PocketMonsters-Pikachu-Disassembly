# Bank 04 survey

Bank 04 covers physical ROM range `0x10000-0x13FFF` and contains two logical RGBDS sections in the pinned public references: `bank4` and `Battle Engine 1`.

## Current status

- Survey status: **complete**
- Source reconstruction: **not yet complete**
- Byte-perfect rebuild claim: **not yet made**
- Nine unique reference targets recorded
- Japanese `Garbage 4` tails reconstructed as editable ASM for Rev 0A/B/C
- JP Rev D uses a 62-byte zero-filled tail
- Reference authority: uploaded/reference ROM bytes take precedence over public disassembly source.

## Family-specific layout

Unlike Bank 03, Bank 04 does **not** have an identical top-level module layout between Japanese and international source families.

### International — 11 top-level modules

`SECTION "bank4"`:

1. `gfx/font.asm`
2. `engine/pokemon/status_screen.asm`
3. `engine/menus/party_menu.asm`
4. `gfx/player.asm`
5. `engine/menus/start_sub_menus.asm`
6. `engine/items/tms.asm`

`SECTION "Battle Engine 1"`:

7. `engine/battle/end_of_battle.asm`
8. `engine/battle/wild_encounters.asm`
9. `engine/battle/move_effects/recoil.asm`
10. `engine/battle/move_effects/conversion.asm`
11. `engine/battle/move_effects/haze.asm`

### Japanese — 14 top-level modules

`SECTION "bank4"`:

1. `data/moves/names.asm`
2. `gfx/font.asm`
3. `engine/overworld/is_player_just_outside_map.asm`
4. `engine/pokemon/status_screen.asm`
5. `engine/menus/party_menu.asm`
6. `gfx/player.asm`
7. `engine/menus/start_sub_menus.asm`
8. `engine/items/tms.asm`

`SECTION "Battle Engine 1"`:

9. `engine/battle/end_of_battle.asm`
10. `engine/battle/wild_encounters.asm`
11. `engine/battle/move_effects/recoil.asm`
12. `engine/battle/move_effects/conversion.asm`
13. `engine/battle/move_effects/haze.asm`
14. `engine/overworld/npc_movement_2.asm`

The three Japanese-only Bank 04 placements are not automatically treated as Japanese-only content:

- `data/moves/names.asm` is placed in the international `text.asm` `Move Names` section.
- `engine/overworld/is_player_just_outside_map.asm` is placed in international `bank3A`.
- `engine/overworld/npc_movement_2.asm` is also placed in international `bank3A`.

They therefore represent **family-specific bank placement** until source/content comparison proves otherwise.

## Bank SHA-1 values

| Target | Bank 04 SHA-1 |
| --- | --- |
| JP Rev 0A | `2344a36c8e3c74a6d722ee3a133ff899caa4d65c` |
| JP Rev B | `9159a3ae11ea0def01287749c81078e22eef92e8` |
| JP Rev C | `e9cc532c17d0802c4c5499f1aa738ac65204bf3e` |
| JP Rev D | `6897c1d250a4b095e6312569ae77388c346b9e67` |
| EN USA/Europe | `5554b5f767c8016e1851df2cb5dbd5f5d55c7c8e` |
| FR | `99ad4ca19a83246c7b15cc9f7ed98e60958c756b` |
| DE | `f73b98551029dcdc457920f7b6eb3d0d96b83a26` |
| IT | `6111f4f90d2327e1bcbe66aaf50764a2b36ae647` |
| ES | `06181f63918d821aa57dd6115f40003e404f6d4c` |

All nine Bank 04 images are distinct.

## Japanese active region and revision behavior

The active Japanese Bank 04 region ends at bank-local `$7FC1`; physical range `0x10000-0x13FC1`. The final 62 bytes are bank-local `$7FC2-$7FFF`.

Direct ROM comparison shows:

| Comparison | Whole-bank differing bytes | Active-region differing bytes |
| --- | ---: | ---: |
| Rev 0A vs Rev B | 322 | 260 |
| Rev B vs Rev C | 9 | 0 |
| Rev C vs Rev D | 53 | 0 |

Therefore **Rev B, Rev C, and Rev D have byte-identical active Bank 04 payloads**. Their observed whole-bank differences are entirely in the 62-byte tail.

Rev 0A differs from Rev B at 260 active bytes across 256 contiguous difference ranges. A pinned-source search for `DEF(_REV0)` finds no direct revision conditional in the Japanese Bank 04 top-level modules. These active differences are therefore **not yet classified as local Bank 04 code changes**; external-symbol relocation is a strong candidate, but classification remains pending until symbol-aware assembly/link validation.

## Garbage 4 preservation

The pinned Japanese `garbage.asm` places `Garbage 4` in Bank 4 for `_REV0`, `_REV1`, and `_REV2`, but not `_REV3`.

| Revision | Physical range | Length | Raw SHA-1 | Public Git blob SHA-1 |
| --- | --- | ---: | --- | --- |
| JP Rev 0A | `0x13FC2-0x13FFF` | 62 | `ad0888f5257205ab467810840a334b183eeb3f52` | `05019b76fa9ad16f8e6b84a2af6ea3e507c14d7e` |
| JP Rev B | `0x13FC2-0x13FFF` | 62 | `237775b27321e2e943ff4227851619f3f4ae3b70` | `dcdb00ce7b97410f3b976ec7febbb3fa690e31ae` |
| JP Rev C | `0x13FC2-0x13FFF` | 62 | `5d1943617c7a4bb19b829a7c942663baf70e40de` | `5ce7e4dd53b9a0c47630e069aff9c27c5fca0eea` |
| JP Rev D | `0x13FC2-0x13FFF` | 62 zero bytes | `566538c1539e2db072bd6dd57dbaae4e470ad831` | n/a |

Rev 0A/B/C tails are preserved under `data/garbage/jp/<revision>/bank04_tail.asm`; Rev D intentionally has no tail source and uses zero fill.

These bytes are historical leftover data and must not be reinterpreted as active engine code.

## International padding observations

The last non-zero byte differs by locale:

| Target | Last non-zero physical byte | Trailing zeros |
| --- | --- | ---: |
| EN | `0x13A21` | 1502 |
| FR | `0x13A32` | 1485 |
| DE | `0x13A2E` | 1489 |
| IT | `0x13A4A` | 1461 |
| ES | `0x13A45` | 1466 |

The **last non-zero byte is not a source-section boundary**. These values are padding survey observations only; exact section placement must come from source reconstruction and linked-byte validation.

## Next reconstruction phase

1. Audit the 11 common Bank 04 modules against both pinned source families.
2. Classify exact-shared, cosmetic-only, and substantive source differences.
3. Preserve the three Japanese-specific placements while avoiding duplicate content in international banks.
4. Build `banks/bank04.asm` with family-specific section order and JP Garbage 4 wiring.
5. Defer any byte-perfect claim until all required cross-bank dependencies can be linked and Bank 04 is compared against all nine reference images.

The machine-readable survey is `config/bank04_modules.json`.
