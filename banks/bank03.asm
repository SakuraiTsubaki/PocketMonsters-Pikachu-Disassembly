; Canonical Bank 03 source order for every supported Pokemon Yellow release.
; The 28 logical modules are shared in order across the Japanese and
; international disassembly families. Individual files retain target-family
; conditionals where the source bodies differ.

SECTION "bank3", ROMX[$4000], BANK[$3]

INCLUDE "engine/joypad.asm"
INCLUDE "engine/overworld/clear_variables.asm"
INCLUDE "engine/overworld/player_state.asm"
INCLUDE "engine/events/poison.asm"
INCLUDE "engine/overworld/tilesets.asm"
INCLUDE "engine/overworld/daycare_exp.asm"
INCLUDE "data/maps/toggleable_objects.asm"
INCLUDE "engine/overworld/wild_mons.asm"
INCLUDE "engine/items/item_effects.asm"
INCLUDE "engine/menus/draw_badges.asm"
INCLUDE "engine/overworld/update_map.asm"
INCLUDE "engine/overworld/cut.asm"
INCLUDE "engine/overworld/toggleable_objects.asm"
INCLUDE "engine/overworld/push_boulder.asm"
INCLUDE "engine/pokemon/add_mon.asm"
INCLUDE "engine/flag_action.asm"
INCLUDE "engine/events/heal_party.asm"
INCLUDE "engine/math/bcd.asm"
INCLUDE "engine/movie/oak_speech/init_player_data.asm"
INCLUDE "engine/items/get_bag_item_quantity.asm"
INCLUDE "engine/overworld/pathfinding.asm"
INCLUDE "engine/gfx/hp_bar.asm"
INCLUDE "engine/events/hidden_events/bookshelves.asm"
INCLUDE "engine/events/hidden_events/indigo_plateau_statues.asm"
INCLUDE "engine/events/hidden_events/book_or_sculpture.asm"
INCLUDE "engine/events/hidden_events/elevator.asm"
INCLUDE "engine/events/hidden_events/town_map.asm"
INCLUDE "engine/events/hidden_events/pokemon_stuff.asm"


; Japanese historical Garbage 3 tails are revision-specific.
; Rev D and all international targets intentionally emit no tail source here;
; unallocated bank space remains linker zero fill.
IF DEF(_JAPAN)
IF DEF(_REV0)
SECTION "Garbage 3 Rev 0A", ROMX[$7E30], BANK[$3]
INCLUDE "data/garbage/jp/rev0a/bank03_tail.asm"
ELIF DEF(_REV1)
SECTION "Garbage 3 Rev B", ROMX[$7E27], BANK[$3]
INCLUDE "data/garbage/jp/revb/bank03_tail.asm"
ELIF DEF(_REV2)
SECTION "Garbage 3 Rev C", ROMX[$7E27], BANK[$3]
INCLUDE "data/garbage/jp/revc/bank03_tail.asm"
ENDC
ENDC
