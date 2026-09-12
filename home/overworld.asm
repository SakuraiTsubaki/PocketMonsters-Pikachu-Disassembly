; Unified Bank 00 overworld engine.
; The retail JP and international flows are represented by one semantic source.
; Release-family differences that affect emitted bytes are introduced only when
; independently verified. See docs/OVERWORLD_ENGINE.md.

INCLUDE "home/overworld/main_loop.asm"
INCLUDE "home/overworld/warps_and_connections.asm"
INCLUDE "home/overworld/tilemap_connections.asm"
INCLUDE "home/overworld/collisions_and_view.asm"
INCLUDE "home/overworld/input_and_player_gfx.asm"
INCLUDE "home/overworld/map_loading.asm"
INCLUDE "home/overworld/sprites.asm"
