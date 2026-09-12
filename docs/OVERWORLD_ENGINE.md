# Bank 00 Overworld Engine

`home/overworld.asm` is reconstructed as one shared semantic engine and split into smaller source units only for maintainability. The `INCLUDE` order preserves the original ROM0 instruction stream.

## Source layout

```text
home/overworld.asm
├── overworld/main_loop.asm
├── overworld/warps_and_connections.asm
├── overworld/tilemap_connections.asm
├── overworld/collisions_and_view.asm
├── overworld/input_and_player_gfx.asm
├── overworld/map_loading.asm
└── overworld/sprites.asm
```

The file boundaries do not imply binary section boundaries. Some boundaries intentionally occur in the middle of a routine; RGBDS `INCLUDE` keeps the source text continuous and therefore preserves local-label scope and instruction order.

## JP / international comparison

The English `pret/pokeyellow` and Japanese `Narishma-gb/pokeyellow-jp` overworld sources were compared across the full module. The retail overworld flow is overwhelmingly common. Differences seen in the public sources are primarily semantic labeling or equivalent constant spelling rather than distinct runtime behavior, for example:

- Japanese `wd471` versus the international semantic name `wPikachuSpawnStateFlags`.
- Japanese literal `$ff` versus international `LOST_BATTLE`, where the constant value is `$ff`.
- Japanese literal `$600` versus international `MAP_TILESET_SIZE tiles`, which evaluates to the same byte count.
- comment wording and resolved symbol naming.

The unified source therefore uses the clearer semantic symbol names rather than maintaining duplicate JP and international copies.

## Revision handling

No Japanese `_REV0` conditional was identified inside the public `home/overworld.asm` itself. Known JP revision-specific ROM0 behavior remains isolated in the modules where it actually occurs, including header, joypad, Pokemon helpers, play-time handling, audio bank switching, and other Home routines.

This does **not** mean the emitted overworld bytes have already been proven identical for all nine targets. Absolute operands can differ when referenced symbols move, even when the source-level routine is common.

## Verification state

Current status: `reference-crosschecked`.

Before promotion to `direct-byte-verified` / complete, the project must:

1. reconstruct the dependent constants/macros/WRAM/HRAM symbols and included data files;
2. assemble every supported release with the correct target definitions;
3. compare the emitted overworld ranges against each reference ROM;
4. distinguish expected relocation-sensitive operand changes from real logic differences;
5. verify the complete Bank 00 image byte-for-byte.

The reference ROM bytes, not any public disassembly, remain the final binary authority.
