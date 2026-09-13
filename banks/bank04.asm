; Family-aware Bank 04 reconstruction for Pokemon Yellow.
; International and Japanese releases share the same two logical sections,
; but Japanese places three additional modules in Bank 04 that international
; releases place in other banks/sections.

SECTION "bank4", ROMX[$4000], BANK[$4]

IF DEF(_JAPAN)
INCLUDE "data/moves/names.asm"
ENDC
INCLUDE "gfx/font.asm"
IF DEF(_JAPAN)
INCLUDE "engine/overworld/is_player_just_outside_map.asm"
ENDC
INCLUDE "engine/pokemon/status_screen.asm"
INCLUDE "engine/menus/party_menu.asm"
INCLUDE "gfx/player.asm"
INCLUDE "engine/menus/start_sub_menus.asm"
INCLUDE "engine/items/tms.asm"


SECTION "Battle Engine 1", ROMX, BANK[$4]

INCLUDE "engine/battle/end_of_battle.asm"
INCLUDE "engine/battle/wild_encounters.asm"
INCLUDE "engine/battle/move_effects/recoil.asm"
INCLUDE "engine/battle/move_effects/conversion.asm"
INCLUDE "engine/battle/move_effects/haze.asm"
IF DEF(_JAPAN)
INCLUDE "engine/overworld/npc_movement_2.asm"
ENDC


; Japanese historical Garbage 4 occupies the final 62 bytes of Bank 04 only
; in Rev 0A/B/C. Rev D and all international targets intentionally leave this
; range unallocated so the linker emits zero fill.
IF DEF(_JAPAN)
IF DEF(_REV0)
SECTION "Garbage 4 Rev 0A", ROMX[$7FC2], BANK[$4]
INCLUDE "data/garbage/jp/rev0a/bank04_tail.asm"
ELIF DEF(_REV1)
SECTION "Garbage 4 Rev B", ROMX[$7FC2], BANK[$4]
INCLUDE "data/garbage/jp/revb/bank04_tail.asm"
ELIF DEF(_REV2)
SECTION "Garbage 4 Rev C", ROMX[$7FC2], BANK[$4]
INCLUDE "data/garbage/jp/revc/bank04_tail.asm"
ENDC
ENDC
