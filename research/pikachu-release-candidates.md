# Study: establish Pocket Monsters Pikachu / Pokémon Yellow release candidates

- Status: draft
- Release ID: four Japanese revisions and five localized revision-zero candidates
- Input SHA-256: recorded in `research/releases.csv`
- Last updated: 2026-09-21

## Question

Which distinct local Yellow-family ROM identities exist after eliminating duplicate files with different extensions or labels?

## Environment and tool versions

- Host: Windows
- Inspector: shared `SakuraiTsubaki/Disassembly tools/inspect_gb_rom.py` version 1.0.1
- Repository baseline: `2e8b2058b7926295588c813acd0af90720f3163e`

## Exact procedure

All fourteen filename candidates were hashed in full and validated for Nintendo logo, header checksum, and global checksum. Identities were deduplicated by SHA-256; file extension was not treated as evidence.

## Observations

- Four Japanese identities have header revisions 0, 1, 2, and 3 and CGB flag 0x00.
- Five localized identities (English, German, Spanish, French, Italian) have revision 0 and CGB compatibility flag 0x80.
- Each localized identity appeared twice under `.gb` and `.gbc` filenames, but each pair had identical SHA-1 and SHA-256.
- Nine unique ROM identities remain from fourteen local files.
- Every unique identity passed logo and both checksum validations.
- Localized German, Spanish, French, and Italian headers encode language suffixes in the 15-byte CGB title field.

## Derived results

Filename and extension duplicates are not separate releases. The release matrix records nine unique candidate identities only.

## Interpretation and confidence

Hashes, header fields, duplicate equivalence, and checksum validity are directly observed. Region and revision labels remain candidates pending independent confirmation.

## Reproduction

Run the shared inspector with `--require-valid` on all local Yellow candidates, group results by SHA-256, compare with `analysis/pikachu-release-header-report.json`, and verify the report hash using its manifest.

## Limitations and next questions

Independent confirmation is required before any candidate becomes `verified`. Revision-specific bank analysis begins only after that gate.
