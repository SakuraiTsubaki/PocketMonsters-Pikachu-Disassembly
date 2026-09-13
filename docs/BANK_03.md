# Bank 03 survey and source reconstruction ledger

Bank 03 covers physical ROM range `0xC000-0xFFFF`.

## Current status

- Survey status: **complete**
- Canonical source population: **28/28 modules present**
- Canonical logical layout: **28 top-level modules**
- JP/international source deduplication: **complete at the pinned-source level**
- Source classes: **10 exact shared + 4 cosmetic-normalized + 14 fine-grained family-conditional**
- Whole-file JP/international duplication: **0 modules**
- Bank entrypoint and Japanese revision-tail wiring: **present and CI-checked**
- Linked source reconstruction: **not yet complete**
- Byte-perfect rebuild claim: **not yet made**
- Reference authority: uploaded/reference ROM bytes take precedence over public disassembly source when any conflict exists.

The important distinction is that Bank 03 now has a complete editable source population and a deduplicated JP/international source model, but this is **not** yet a claim that RGBDS can link the complete repository and reproduce every Bank 03 reference byte. Cross-bank symbol/data dependencies still have to be reconstructed and the nine target builds have to be assembled, linked, and byte-compared.

## Canonical module order

1. `engine/joypad.asm`
2. `engine/overworld/clear_variables.asm`
3. `engine/overworld/player_state.asm`
4. `engine/events/poison.asm`
5. `engine/overworld/tilesets.asm`
6. `engine/overworld/daycare_exp.asm`
7. `data/maps/toggleable_objects.asm`
8. `engine/overworld/wild_mons.asm`
9. `engine/items/item_effects.asm`
10. `engine/menus/draw_badges.asm`
11. `engine/overworld/update_map.asm`
12. `engine/overworld/cut.asm`
13. `engine/overworld/toggleable_objects.asm`
14. `engine/overworld/push_boulder.asm`
15. `engine/pokemon/add_mon.asm`
16. `engine/flag_action.asm`
17. `engine/events/heal_party.asm`
18. `engine/math/bcd.asm`
19. `engine/movie/oak_speech/init_player_data.asm`
20. `engine/items/get_bag_item_quantity.asm`
21. `engine/overworld/pathfinding.asm`
22. `engine/gfx/hp_bar.asm`
23. `engine/events/hidden_events/bookshelves.asm`
24. `engine/events/hidden_events/indigo_plateau_statues.asm`
25. `engine/events/hidden_events/book_or_sculpture.asm`
26. `engine/events/hidden_events/elevator.asm`
27. `engine/events/hidden_events/town_map.asm`
28. `engine/events/hidden_events/pokemon_stuff.asm`

The machine-readable source of truth for the logical bank layout remains `config/bank03_modules.json`; `banks/bank03.asm` is the executable include-order representation.

## Source population and deduplication

The Bank 03 source audit is pinned to:

- international: `pret/pokeyellow` commit `e89ead154b9968aa50eed9328ff2b38b6c194382`
- Japanese: `Narishma-gb/pokeyellow-jp` commit `f282e72ae26232790fdb780aa5a5db7ec8ebf572`

The 28 modules were classified before source merging:

- **10 exact shared modules**: public JP and international source files are byte-identical and one shared source file is retained.
- **4 cosmetic-normalized modules**: comments/whitespace differ but assembly-relevant token streams are identical; the pinned international spelling is retained as the common source.
- **14 substantive modules**: assembly-relevant tokens differ. All fourteen are now represented as fine-grained family conditionals, with common lines emitted once and only genuine JP/international differences guarded.

The provenance and reconstruction ledgers are:

- `config/bank03_source_inventory.json`
- `config/bank03_variant_analysis.json`
- `config/bank03_merged_source_manifest.json`
- `config/bank03_fine_merge_batch1.json`
- `config/bank03_fine_merge_batch2.json`
- `config/bank03_large_variant_safety.json`
- `config/bank03_joypad_manual_merge.json`
- `analysis/bank03/source_diffs/`

`tools/check_bank03_sources.py` locks the source hashes, the 10/4/14 classification, the all-fine-grained final state, canonical include order, joypad verification ledger, and Japanese tail wiring.

## Joypad revision reconstruction

`engine/joypad.asm` is the exceptional substantive module. A naive JP/international line-diff wrapper is invalid because the changed Japanese spans cross existing `_REV0`/`_REV1`/`_REV2`/`_REV3` `IF/ELSE/ENDC` structure and create a duplicate `ELSE`.

The final source therefore uses a manually structured semantic merge:

- Japanese Rev 0A preserves its extra JOYP reads and alternate polling/soft-reset path.
- Japanese Rev B/C/D preserve the later Japanese polling guard and normal input path.
- International targets preserve the international normal path.
- Common instructions are emitted once wherever the selected source paths are assembly-equivalent.

Before the merge was accepted, a target-aware conditional evaluator compared assembly-relevant token streams against the pinned upstream source for each logical path:

| Path | Verified token count |
| --- | ---: |
| JP Rev 0A | 294 |
| JP Rev B | 297 |
| JP Rev C | 297 |
| JP Rev D | 297 |
| International | 289 |

All five comparisons passed. This is **source-branch equivalence validation**, not a substitute for the later RGBDS linked-byte comparison.

## Nine reference targets

The observed `.gb`/`.gbc` container pairs for EN/FR/DE/IT/ES are byte-identical within each language, so they collapse to five unique international images. Together with four Japanese revisions, Bank 03 therefore has nine unique reference targets.

Each target has a distinct full Bank 03 SHA-1. Logical module order is shared, but byte identity is not assumed across languages or revisions.

## Japanese revision structure

### Rev 0A

Rev 0A active Bank 03 code/data occupies `0xC000-0xFE2F` (15,920 bytes). Its active payload is **9 bytes longer** than Rev B/C/D.

The cause is the `_REV0` path in `engine/joypad.asm`: it performs extra JOYP reads and uses a different polling/reset path. The resulting 9-byte size delta shifts subsequent Bank 03 addresses.

Rev 0A then carries a 464-byte historical `Garbage 3` tail at `0xFE30-0xFFFF`.

### Rev B and Rev C

Rev B and Rev C active Bank 03 payloads are byte-identical over `0xC000-0xFE26` (15,911 bytes). Their whole-bank SHA-1 values differ because their 473-byte `Garbage 3` tails differ.

### Rev D

Rev D uses the same 15,911-byte active range `0xC000-0xFE26`, followed by a zero-filled 473-byte tail.

Compared with Rev B/C, Rev D has exactly one active-region byte difference at physical `0xFD06` (`Bank 03 + 0x3D06`):

- Rev B/C: `$F3`
- Rev D: `$FA`
- operand: `ld hl,$77F3` -> `ld hl,$77FA`

The source site is the `farjp PrintCardKeyText` in `engine/events/hidden_events/bookshelves.asm`. The semantic Bank 03 logic is unchanged; this is classified as an **external-symbol relocation** caused by the referenced target moving by 7 bytes in Rev D.

## Garbage 3 preservation

Historical tails are stored as editable RGBDS `db` source, not ROM or `.bin` files:

| Revision | Range | Length | Raw SHA-1 | Public Git blob SHA-1 |
| --- | --- | ---: | --- | --- |
| JP Rev 0A | `0xFE30-0xFFFF` | 464 | `79ac92a4cee3c1b9ed0d8a472aaa50dadf618085` | `d20b7466490d31a6b1203562c277fc3ba93f065c` |
| JP Rev B | `0xFE27-0xFFFF` | 473 | `54ba5ff8ca15bd7930827b1f8ee1b358d70cb97d` | `c68d8247633afa84ce53c4a82a18bdd2df725787` |
| JP Rev C | `0xFE27-0xFFFF` | 473 | `137053b3679654889b17fd5f0c42fd906fabc76b` | `1b8ccc4a797481fee0c25b9709d419357764bcee` |
| JP Rev D | `0xFE27-0xFFFF` | 473 zero bytes | `693e31dc362426bc4d7a6b2954f7c80267476d66` | n/a |

These bytes remain classified as historical leftover data. They are preserved for exact historical reconstruction but are not reinterpreted as active engine code.

## International boundary caution

For the five international targets, the final non-zero byte occurs at different physical offsets (`0xFAC7`-`0xFADB` range). The **last non-zero byte is not a source-section boundary**; it is only a padding survey observation. Exact locale-specific placement must be established from the eventual linked builds and byte comparisons.

## Remaining completion gate

Bank 03 is now ready for the next stage rather than another source-import pass:

1. Reconstruct the cross-bank symbols, constants, macros, data, text and other dependencies needed to assemble/link Bank 03 in the repository's unified build.
2. Enable RGBDS assembly/linking for each of the nine target definitions.
3. Compare physical Bank 03 bytes (`0xC000-0xFFFF`) against all nine reference hashes/ranges.
4. Classify any mismatches as local source content, linked-symbol relocation, padding/fill, or historical tail data and correct the source model.
5. Only after all nine linked Bank 03 outputs match may `source_reconstruction_complete` and any byte-perfect claim be promoted.

`make bank03-check` currently validates the survey, all nine recorded reference-bank hashes, 28-module source population, fine-grained source provenance, joypad target-branch equivalence ledger, canonical include order, and JP Rev 0A/B/C Garbage 3 tails without requiring a ROM file.
