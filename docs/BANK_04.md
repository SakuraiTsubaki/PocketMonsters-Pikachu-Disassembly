# Bank 04 survey and source reconstruction

Bank 04 covers physical ROM range `0x10000-0x13FFF` and contains two logical RGBDS sections in the pinned public references: `bank4` and `Battle Engine 1`.

## Current status

- Survey status: **complete**
- Family-source population: **complete for all 14 unique source paths**
- Source classes: **4 exact-shared + 1 cosmetic-normalized + 9 fine-grained family-conditional**
- Substantive merge state: **9/9 fine-grained; 0 manual-pending**
- Family-aware entrypoint: `banks/bank04.asm`
- Linked per-target source reconstruction: **not yet complete**
- Byte-perfect rebuild claim: **not yet made**
- Nine unique reference targets recorded
- Japanese `Garbage 4` tails reconstructed as editable ASM for Rev 0A/B/C
- JP Rev D uses a 62-byte zero-filled tail
- Reference authority: uploaded/reference ROM bytes take precedence over public disassembly source.

The distinction above is intentional: all known Bank 04 top-level source material is now represented in the repository, but `source_reconstruction_complete` remains false until the source can be linked with all required cross-bank dependencies and validated against the nine reference ROM images.

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

The three Japanese-only Bank 04 placements are not Japanese-only content:

- `data/moves/names.asm` is placed in the international `text.asm` `Move Names` section.
- `engine/overworld/is_player_just_outside_map.asm` is placed in international `bank3A`.
- `engine/overworld/npc_movement_2.asm` is also placed in international `bank3A`.

They therefore represent **family-specific bank placement**. `banks/bank04.asm` preserves those placements with `_JAPAN` guards while keeping each unique source path represented only once in the Bank 04 entrypoint.

## Source population and merge classification

The pinned international and Japanese source trees were compared over the union of the 14 Bank 04 paths. The permanent source inventory is `config/bank04_source_inventory.json`; merge-safety evidence is `config/bank04_variant_safety.json`; merged-source provenance is `config/bank04_merged_source_manifest.json`.

### Exact-shared — 4

- `engine/overworld/is_player_just_outside_map.asm`
- `gfx/player.asm`
- `engine/items/tms.asm`
- `engine/overworld/npc_movement_2.asm`

These files have matching pinned upstream Git blobs and are stored once.

### Cosmetic-normalized — 1

- `engine/battle/wild_encounters.asm`

The semantic source is shared; the repository retains the normalized international representation while preserving the upstream comparison hashes in the inventory.

### Fine-grained family-conditional — 9

- `data/moves/names.asm`
- `gfx/font.asm`
- `engine/pokemon/status_screen.asm`
- `engine/menus/party_menu.asm`
- `engine/menus/start_sub_menus.asm`
- `engine/battle/end_of_battle.asm`
- `engine/battle/move_effects/recoil.asm`
- `engine/battle/move_effects/conversion.asm`
- `engine/battle/move_effects/haze.asm`

All nine substantive files passed the automatic merge-safety rule: none of the changed SequenceMatcher regions intersects an existing RGBDS `IF`/`ELIF`/`ELSE`/`ENDC`, and every generated conditional stack is balanced. Common lines are emitted once and only actual JP/international differences are wrapped in localized `IF DEF(_JAPAN) / ELSE / ENDC` blocks.

The source checker permanently requires this state to remain **9 safe / 0 manual-pending**.

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

Rev 0A differs from Rev B at 260 active bytes across 256 contiguous difference ranges. A pinned-source search for `DEF(_REV0)` finds no direct revision conditional in the Japanese Bank 04 top-level modules. These active differences are therefore **not yet classified as local Bank 04 code changes**; external-symbol relocation is a strong candidate, but attribution remains `pending-symbol-aware-link-validation` until symbol-aware assembly/link validation is available.

## Garbage 4 preservation

The pinned Japanese `garbage.asm` places `Garbage 4` in Bank 4 for `_REV0`, `_REV1`, and `_REV2`, but not `_REV3`.

| Revision | Physical range | Length | Raw SHA-1 | Public Git blob SHA-1 |
| --- | --- | ---: | --- | --- |
| JP Rev 0A | `0x13FC2-0x13FFF` | 62 | `ad0888f5257205ab467810840a334b183eeb3f52` | `05019b76fa9ad16f8e6b84a2af6ea3e507c14d7e` |
| JP Rev B | `0x13FC2-0x13FFF` | 62 | `237775b27321e2e943ff4227851619f3f4ae3b70` | `dcdb00ce7b97410f3b976ec7febbb3fa690e31ae` |
| JP Rev C | `0x13FC2-0x13FFF` | 62 | `5d1943617c7a4bb19b829a7c942663baf70e40de` | `5ce7e4dd53b9a0c47630e069aff9c27c5fca0eea` |
| JP Rev D | `0x13FC2-0x13FFF` | 62 zero bytes | `566538c1539e2db072bd6dd57dbaae4e470ad831` | n/a |

Rev 0A/B/C tails are preserved under `data/garbage/jp/<revision>/bank04_tail.asm`; Rev D intentionally has no tail source and uses zero fill. `banks/bank04.asm` fixes those historical tails at `$7FC2` for the applicable Japanese revisions.

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

The **last non-zero byte is not a source-section boundary**. These values are padding survey observations only; exact section placement must come from linked-byte validation.

## Permanent validation

`make bank04-check` now runs both:

1. `tools/check_bank04_survey.py` — nine reference bank hashes, family layouts, JP active/tail observations, and all three 62-byte Garbage 4 sources.
2. `tools/check_bank04_sources.py` — the complete 14-path source population, exact/cosmetic/substantive provenance, 9/9 fine-grained merge safety, family-specific entrypoint order, and revision-tail wiring.

The one-shot source audit and merge workflows have been removed after their outputs were committed. The permanent Repository Policy workflow calls `make bank04-check` on every push and pull request.

## Next reconstruction phase

1. Supply the remaining cross-bank constants, labels, macros, graphics/data dependencies needed to assemble the Bank 04 sections in the repository's eventual complete source tree.
2. Perform symbol-aware linking for JP Rev 0A/B/C/D and determine whether the 260 Rev0A active-byte differences are entirely external-symbol relocation or include any source-semantic difference.
3. Extend locale-specific data/text dependencies needed by EN/FR/DE/IT/ES.
4. Compare linked Bank 04 bytes against all nine reference bank SHA-1 values.
5. Only after those checks pass may `source_reconstruction_complete` and the byte-perfect claim be changed.

The machine-readable survey is `config/bank04_modules.json`.
