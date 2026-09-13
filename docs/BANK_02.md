# Bank 02 — Audio Engine 1

Bank 02 occupies ROM offsets `0x8000-0xBFFF` and is the first main audio bank.

## Section order

Both the international and Japanese reference disassemblies place the same five logical sections in ROMX bank `$02`:

1. Sound Effect Headers 1
2. Music Headers 1
3. Sound Effects 1
4. Audio Engine 1
5. Music 1

The public source repositories organize some individual SFX files differently, but that organizational difference is not evidence of different ROM audio content.

## Direct ROM result

The active audio payload ends at absolute ROM offset `0xBEC6` (`0x3EC6` within Bank 02).

Direct comparison of all nine reference ROMs shows that **the active Bank 02 audio content is equivalent across every supported release after linked address operands are normalized**.

- The five international releases have only 23 differing byte positions anywhere in Bank 02.
- EN versus JP Rev D has only 27 differing bytes in the active `0x8000-0xBEC6` range.
- JP Rev 0A versus Rev B has only 14 differing bytes in the active range.
- JP Rev B, Rev C, and Rev D have zero active-audio differences.
- Every resolved active-region difference is an operand for a WRAM symbol or a Home routine whose address moved because of another bank/layout revision.
- No music sequence, SFX sequence, cry definition, wave sample, audio header, or audio-command payload difference remains after those relocation operands are normalized.

The exact relocation sites and their symbol attribution are recorded in `config/bank02_relocation_matrix.json`.

### Examples of relocation-only differences

The affected symbols include:

- WRAM: `wAudioFadeOutControl`, `wLowHealthAlarm`, `wGymLeaderNo`, `wCurOpponent`, `wOptions`, `wAudioFadeOutCounterReloadValue`, and `wAudioFadeOutCounter`.
- Home routines: `StopAllMusic`, `DelayFrame`, `PlayMusic`, `DetermineAudioFunction`, `GetNextMusicByte`, `InitMusicVariables`, `InitSFXVariables`, `StopAllAudio`, and `DelayFrames`.

This means the canonical source should refer to symbols normally. The target-specific linker layout should naturally emit the historical operand bytes rather than maintaining locale-specific copies of otherwise identical audio source.

## Historical Garbage 2 tail

The active payload is followed by a 313-byte tail at `0xBEC7-0xBFFF`.

| Release family | Tail state |
| --- | --- |
| JP Rev 0A | historical `Garbage 2` present |
| JP Rev B | historical `Garbage 2` present |
| JP Rev C | historical `Garbage 2` present |
| JP Rev D | zero-filled |
| EN / FR / DE / IT / ES | zero-filled |

The three nonzero Japanese tails were independently extracted from the reference ROMs and their Git blob hashes exactly match the corresponding public `Narishma-gb/pokeyellow-jp` assets:

| Revision | Bytes | Local/reference Git blob SHA-1 |
| --- | ---: | --- |
| JP Rev 0A | 313 | `72dd62ff37238e91d7b5e990b248c42b84d11a55` |
| JP Rev B | 313 | `527ecf5802e41e223919bd4233f425bc37403802` |
| JP Rev C | 313 | `3303ea5d42ecbe546588ba1801409bf791b2152e` |

These bytes are historical leftover data, not active audio. Exact historical rebuilds must preserve them for Rev 0A/B/C, but they must remain separately classified rather than being disguised as meaningful audio or anonymous padding.

## Canonical reconstruction strategy

Bank 02 should use one shared editable audio source tree for all nine targets:

- shared SFX/music headers where byte equivalence allows it;
- shared noise instruments and cry definitions;
- shared non-cry SFX command streams;
- shared `play_battle_music`, Audio Engine 1, and alternate-tempo code;
- shared wave samples;
- shared Music 1 sequences and fanfares;
- revision-specific `Garbage 2` only for JP Rev 0A/B/C.

Public repositories are comparison references, not the repository architecture contract. Where one public project stores separate `*_1.asm` copies and another deduplicates them into common files, this project should prefer the deduplicated representation when direct ROM evidence proves equivalence.

## Current completion boundary

**Survey / equivalence verification: complete.**

**Source reconstruction: not yet complete.** The canonical Audio Bank 1 source files still need to be populated in this repository.

**Byte-perfect rebuild claim: false.** Full RGBDS target builds are still blocked by unreconstructed cross-bank dependencies. Once the source tree is complete and builds are enabled, each generated Bank 02 must be compared byte-for-byte against its matching reference ROM.
