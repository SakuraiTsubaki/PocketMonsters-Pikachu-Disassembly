; Bank 01 overworld movement engine.
; Most code is shared. The Japanese releases retain older sprite-position and
; NPC displacement-bound behaviour; those byte-affecting differences are kept
; narrowly in movement/positioning.asm.

IF !DEF(MAP_TILESET_SIZE)
	DEF MAP_TILESET_SIZE EQU $60
ENDC

INCLUDE "engine/overworld/movement/player_npc.asm"
INCLUDE "engine/overworld/movement/positioning.asm"
INCLUDE "engine/overworld/movement/scripted.asm"
