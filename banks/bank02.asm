; Canonical Bank 02 source order for every supported Pokemon Yellow release.
; The active audio payload is shared across all nine targets after relocation
; normalization. Locale/revision symbol layouts are resolved by the global
; build; only the historical JP Rev 0A/B/C tail is revision-specific here.

	audio_def 1

SECTION "Sound Effect Headers 1", ROMX[$4000], BANK[$2]

INCLUDE "audio/headers/sfx_headers_common.asm"
INCLUDE "audio/headers/sfx_headers_1_3.asm"
INCLUDE "audio/headers/sfx_headers_1.asm"


SECTION "Music Headers 1", ROMX, BANK[$2]

INCLUDE "audio/headers/music_headers_1.asm"


SECTION "Sound Effects 1", ROMX, BANK[$2]

INCLUDE "audio/noise_common.asm"

INCLUDE "audio/sfx/start_menu.asm"
INCLUDE "audio/sfx/pokeflute.asm"
INCLUDE "audio/sfx/cut.asm"
INCLUDE "audio/sfx/go_inside.asm"
INCLUDE "audio/sfx/swap.asm"
INCLUDE "audio/sfx/tink.asm"
INCLUDE "audio/sfx/59.asm"
INCLUDE "audio/sfx/purchase.asm"
INCLUDE "audio/sfx/collision.asm"
INCLUDE "audio/sfx/go_outside.asm"
INCLUDE "audio/sfx/press_ab.asm"
INCLUDE "audio/sfx/save.asm"
INCLUDE "audio/sfx/heal_hp.asm"
INCLUDE "audio/sfx/poisoned.asm"
INCLUDE "audio/sfx/heal_ailment.asm"
INCLUDE "audio/sfx/trade_machine.asm"
INCLUDE "audio/sfx/turn_on_pc.asm"
INCLUDE "audio/sfx/turn_off_pc.asm"
INCLUDE "audio/sfx/enter_pc.asm"
INCLUDE "audio/sfx/shrink.asm"
INCLUDE "audio/sfx/switch.asm"
INCLUDE "audio/sfx/healing_machine.asm"
INCLUDE "audio/sfx/teleport_exit1.asm"
INCLUDE "audio/sfx/teleport_enter1.asm"
INCLUDE "audio/sfx/teleport_exit2.asm"
INCLUDE "audio/sfx/ledge.asm"
INCLUDE "audio/sfx/teleport_enter2.asm"
INCLUDE "audio/sfx/fly.asm"
INCLUDE "audio/sfx/denied.asm"
INCLUDE "audio/sfx/arrow_tiles.asm"
INCLUDE "audio/sfx/push_boulder.asm"
INCLUDE "audio/sfx/ss_anne_horn.asm"
INCLUDE "audio/sfx/withdraw_deposit.asm"
INCLUDE "audio/sfx/safari_zone_pa.asm"

INCLUDE "audio/cry_common.asm"


SECTION "Audio Engine 1", ROMX, BANK[$2]

INCLUDE "audio/play_battle_music.asm"
INCLUDE "audio/engine_1.asm"
INCLUDE "audio/alternate_tempo.asm"


SECTION "Music 1", ROMX, BANK[$2]

Audio1_WavePointers:
INCLUDE "audio/wave_samples.asm"

INCLUDE "audio/music/pkmn_healed.asm"
INCLUDE "audio/music/routes_1.asm"
INCLUDE "audio/music/routes_2.asm"
INCLUDE "audio/music/routes_3.asm"
INCLUDE "audio/music/routes_4.asm"
INCLUDE "audio/music/indigo_plateau.asm"
INCLUDE "audio/music/pallet_town.asm"
INCLUDE "audio/music/unused_song.asm"
INCLUDE "audio/music/cities_1.asm"
INCLUDE "audio/sfx/get_item1.asm"
INCLUDE "audio/music/museum_guy.asm"
INCLUDE "audio/music/meet_prof_oak.asm"
INCLUDE "audio/music/meet_rival.asm"
INCLUDE "audio/sfx/pokedex_rating.asm"
INCLUDE "audio/sfx/get_item2.asm"
INCLUDE "audio/sfx/get_key_item.asm"
INCLUDE "audio/music/ss_anne.asm"
INCLUDE "audio/music/cities_2.asm"
INCLUDE "audio/music/celadon.asm"
INCLUDE "audio/music/cinnabar.asm"
INCLUDE "audio/music/vermilion.asm"
INCLUDE "audio/music/lavender.asm"
INCLUDE "audio/music/safari_zone.asm"
INCLUDE "audio/music/gym.asm"
INCLUDE "audio/music/pokecenter.asm"


; Physical ROM offsets $BEC7-$BFFF correspond to bank-local $7EC7-$7FFF.
; Rev D and international releases intentionally emit no tail bytes here;
; the linker fill remains zero. Rev 0A/B/C preserve their historical data.
IF DEF(_JAPAN)
SECTION "Garbage 2", ROMX[$7EC7], BANK[$2]
IF DEF(_REV0)
INCLUDE "data/garbage/jp/rev0a/bank02_tail.asm"
ELIF DEF(_REV1)
INCLUDE "data/garbage/jp/revb/bank02_tail.asm"
ELIF DEF(_REV2)
INCLUDE "data/garbage/jp/revc/bank02_tail.asm"
ENDC
ENDC
