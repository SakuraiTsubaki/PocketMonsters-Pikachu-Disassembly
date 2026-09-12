# Bank 00 Text Engine Architecture

This project reconstructs the Pokemon Yellow text engine as one semantic engine with narrowly scoped release-family and locale differences. It does **not** maintain a full copy of `home/text.asm` for each language.

## Evidence base

The Bank 00 text engine was cross-checked against public disassemblies for:

- `pret/pokeyellow` — English international family.
- `Narishma-gb/pokeyellow-fr` — French international family.
- `Brianum/pokeyellow-de` — German international family.
- `Narishma-gb/pokeyellow-jp` — Japanese V1.0-V1.3 family.

Italian and Spanish will be reconstructed directly from the verified reference ROMs and fitted to the international-family engine only after their byte-level differences are extracted.

## Architecture

The intended source split is:

```text
home/text.asm
  -> shared text-command dispatcher and cursor/box logic
  -> release-family rendering hooks
  -> locale literal tables
  -> Japanese kana/diacritic renderer
```

Language-dependent strings are data, not separate copies of the text engine.

## International-family invariants

English, French, and German share the same main text-engine organization:

- bordered text-box drawing
- `PlaceString` / `PlaceNextChar`
- command-character dictionary
- text command processor
- common `TX_*` jump-table layout
- prompt, scrolling, numeric, BCD, sound and wait commands
- `TX_FAR` banked-text support
- page-character support

Known locale differences include fixed command-expansion strings such as TM, Trainer, Team Rocket and enemy prefixes. French also reverses the ordering used to compose the enemy-name phrase: its fixed `EnemyText` is appended after the nickname instead of prepended.

## Japanese-family differences

The Japanese source is structurally related but has real engine differences that must remain explicit:

- full-width blank character `　` instead of the international blank tile literal
- Japanese `。` Pokedex terminator instead of `.`
- kana dakuten/handakuten rendering paths in `PlaceNextChar`
- Japanese-only `<GA>` command character and `GaCharText`
- Japanese fixed strings such as `わざマシン`, `トレーナー`, `ロケットだん`, `ポケモン`, and `てきの　`
- Japanese debug `TextIDErrorText` is encoded directly in Japanese rather than reached through the international far-text resource
- Japanese text uses `⋯` where the international source uses the international ellipsis token
- the Japanese command dictionary does not use the international `<PAGE>` / `<PKMN>` entries in the same way
- the Japanese source does not use the international `TX_FAR` dispatch path in Bank 00
- the international `hUILayoutFlags` single-line spacing/page handling is not present in the same form in the Japanese engine

These are engine/layout differences, not just translation differences.

## Fixed-literal policy

Fixed text-engine literals must be represented as locale data once the exact byte sequences are verified for each target. Do not infer Italian or Spanish text from later games or from modern localization.

Each literal must carry:

- target release
- decoded text
- encoded byte sequence
- ROM0 address/range
- source/verification status

## Verification levels

`text.asm` is not complete until all of the following are true for all nine unique targets:

1. every command-handler entry address is mapped;
2. every locale literal is decoded and byte-verified;
3. every Japanese-only renderer path is identified by exact ROM range;
4. IT/ES international-family deviations are extracted directly from their ROMs;
5. an RGBDS build emits the same Bank 00 byte ranges;
6. the final whole-ROM SHA-1 matches the corresponding reference release.

Public disassemblies are reference material; the verified ROMs remain the authority for byte identity.
