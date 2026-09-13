# Bank 03 survey

Bank 03 covers physical ROM range `0xC000-0xFFFF` and is the next reconstruction target after Bank 02.

## Current status

- Survey status: **complete**
- Source reconstruction: **not yet complete**
- Byte-perfect rebuild claim: **not yet made**
- Canonical logical layout: one `bank3` section containing **28 top-level modules**
- Reference authority: uploaded/reference ROM bytes take precedence over public disassembly source when any conflict exists.

The 28-module order is shared by the checked international `pret/pokeyellow` layout and the Japanese `Narishma-gb/pokeyellow-jp` layout. The machine-code bytes are not assumed to be identical across languages or revisions merely because the logical include order is the same.

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

The machine-readable source of truth is `config/bank03_modules.json`.

## Nine reference targets

The observed `.gb`/`.gbc` container pairs for EN/FR/DE/IT/ES are byte-identical within each language, so they collapse to five unique international images. Together with four Japanese revisions, Bank 03 therefore has nine unique reference targets.

Each target currently has a distinct full Bank 03 SHA-1. This is evidence that Bank 03 cannot be treated as a single byte-identical payload before relocation/content normalization.

## Japanese revision structure

### Rev 0A

Rev 0A active Bank 03 code/data occupies `0xC000-0xFE2F` (15,920 bytes). Its active payload is **9 bytes longer** than Rev B/C/D.

Public source cross-checking identifies the cause in `engine/joypad.asm`: `_REV0` has extra JOYP reads and a different polling/reset path, while `_REV1`, `_REV2`, and `_REV3` use the later guard/polling path. The 9-byte size delta shifts subsequent Bank 03 addresses.

Rev 0A then carries a 464-byte historical `Garbage 3` tail at `0xFE30-0xFFFF`.

### Rev B and Rev C

Rev B and Rev C active Bank 03 payloads are byte-identical over `0xC000-0xFE26` (15,911 bytes). Their whole-bank SHA-1 values differ because their 473-byte `Garbage 3` tails differ.

### Rev D

Rev D uses the same 15,911-byte active range `0xC000-0xFE26`, followed by a zero-filled 473-byte tail.

Compared with Rev B/C, Rev D has exactly one active-region byte difference at physical `0xFD06` (`Bank 03 + 0x3D06`):

- Rev B/C: `$F3`
- Rev D: `$FA`
- operand: `ld hl,$77F3` -> `ld hl,$77FA`

The source site is the `farjp PrintCardKeyText` in `engine/events/hidden_events/bookshelves.asm`. The semantic Bank 03 logic is unchanged; the byte difference is classified as an **external-symbol relocation** caused by the referenced target moving by 7 bytes in Rev D.

## Garbage 3 preservation

Historical tails are stored as editable RGBDS `db` source, not as ROM or `.bin` files:

| Revision | Range | Length | Raw SHA-1 | Public Git blob SHA-1 |
| --- | --- | ---: | --- | --- |
| JP Rev 0A | `0xFE30-0xFFFF` | 464 | `79ac92a4cee3c1b9ed0d8a472aaa50dadf618085` | `d20b7466490d31a6b1203562c277fc3ba93f065c` |
| JP Rev B | `0xFE27-0xFFFF` | 473 | `54ba5ff8ca15bd7930827b1f8ee1b358d70cb97d` | `c68d8247633afa84ce53c4a82a18bdd2df725787` |
| JP Rev C | `0xFE27-0xFFFF` | 473 | `137053b3679654889b17fd5f0c42fd906fabc76b` | `1b8ccc4a797481fee0c25b9709d419357764bcee` |
| JP Rev D | `0xFE27-0xFFFF` | 473 zero bytes | `693e31dc362426bc4d7a6b2954f7c80267476d66` | n/a |

These bytes are classified as historical leftover data. They must be preserved for exact historical reconstruction, but they must not be reinterpreted as active engine code.

## International boundary caution

For the five international targets, the final non-zero byte occurs at different physical offsets (`0xFAC7`-`0xFADB` range). These observations are useful for surveying padding, but **last non-zero byte is not a source-section boundary**. The exact active-layout boundary and all locale-specific relocation/content differences will be established during source reconstruction.

## Next reconstruction phase

1. Import/reconstruct the 28 modules as editable RGBDS source.
2. Create `banks/bank03.asm` using the canonical include order.
3. Encode the JP Rev 0A joypad conditional and JP Rev 0A/B/C Garbage 3 wiring without duplicating common logic.
4. Build an international/JP relocation and content-difference matrix.
5. Enable per-target byte-diff validation when Bank 03 cross-bank symbol dependencies are available.

`make bank03-check` validates this survey, the exact module order, all nine recorded bank hashes, and all three reconstructed Japanese Garbage 3 tails without requiring any ROM file.
