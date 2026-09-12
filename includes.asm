; Shared assembler foundation for all supported Pokemon Yellow releases.
; Keep family-only includes narrow so a single source tree can reproduce both
; the Japanese DMG/SGB family and the international CGB-aware family.

INCLUDE "macros/asserts.asm"
INCLUDE "macros/const.asm"
INCLUDE "macros/predef.asm"
INCLUDE "macros/farcall.asm"
INCLUDE "macros/data.asm"
INCLUDE "macros/code.asm"
INCLUDE "macros/gfx.asm"
INCLUDE "macros/coords.asm"
IF !DEF(_JAPAN)
INCLUDE "macros/pikachu.asm"
ENDC
INCLUDE "macros/vc.asm"

INCLUDE "macros/scripts/audio.asm"
INCLUDE "macros/scripts/maps.asm"
INCLUDE "macros/scripts/events.asm"
INCLUDE "macros/scripts/text.asm"
INCLUDE "macros/scripts/gfx_anims.asm"

; Charmaps are release-family sensitive and will select their table from the
; target defines.
INCLUDE "constants/charmap.asm"
INCLUDE "constants/hardware.inc"
INCLUDE "constants/oam_constants.asm"
INCLUDE "constants/ram_constants.asm"
INCLUDE "constants/misc_constants.asm"
INCLUDE "constants/gfx_constants.asm"
INCLUDE "constants/serial_constants.asm"

; The public JP and international source families include text_constants at
; different points. Preserve that ordering while sharing the rest of the list.
IF !DEF(_JAPAN)
INCLUDE "constants/text_constants.asm"
ENDC
INCLUDE "constants/script_constants.asm"
INCLUDE "constants/type_constants.asm"
INCLUDE "constants/battle_constants.asm"
INCLUDE "constants/battle_anim_constants.asm"
INCLUDE "constants/move_constants.asm"
INCLUDE "constants/move_animation_constants.asm"
INCLUDE "constants/move_effect_constants.asm"
INCLUDE "constants/item_constants.asm"
INCLUDE "constants/pokemon_constants.asm"
INCLUDE "constants/pokedex_constants.asm"
INCLUDE "constants/pokemon_data_constants.asm"
INCLUDE "constants/player_constants.asm"
INCLUDE "constants/trainer_constants.asm"
IF !DEF(_JAPAN)
INCLUDE "constants/trainer_data_constants.asm"
ENDC
INCLUDE "constants/icon_constants.asm"
INCLUDE "constants/sprite_constants.asm"
INCLUDE "constants/sprite_data_constants.asm"
INCLUDE "constants/palette_constants.asm"
INCLUDE "constants/list_constants.asm"
INCLUDE "constants/map_constants.asm"
INCLUDE "constants/map_data_constants.asm"
INCLUDE "constants/map_object_constants.asm"
INCLUDE "constants/toggle_constants.asm"
INCLUDE "constants/sprite_set_constants.asm"
INCLUDE "constants/credits_constants.asm"
INCLUDE "constants/audio_constants.asm"
INCLUDE "constants/music_constants.asm"
INCLUDE "constants/tileset_constants.asm"
INCLUDE "constants/event_constants.asm"
IF DEF(_JAPAN)
INCLUDE "constants/text_constants.asm"
ENDC
INCLUDE "constants/menu_constants.asm"
INCLUDE "constants/sprite_anim_constants.asm"
INCLUDE "constants/pikachu_emotion_constants.asm"

IF DEF(_YELLOW_VC)
IF DEF(_JAPAN)
INCLUDE "vc/vc_constants.asm"
ELSE
INCLUDE "vc/pokeyellow.constants.asm"
ENDC
ENDC
