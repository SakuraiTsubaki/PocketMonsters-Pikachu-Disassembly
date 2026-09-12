# Bank 01 reconstruction

Bank 01 covers ROM range `0x4000-0x7fff`. Its canonical source order is defined by `banks/bank01.asm` and matches the Bank 01 include order in both the checked international and Japanese public disassemblies.

## Status

- Source inventory: **33 / 33 modules reconstructed or reference-crosschecked**.
- Pending source modules: **0**.
- Canonical include order: `banks/bank01.asm`.
- Manifest: `config/bank01_modules.json`.
- Automated structural check: `make bank01-check`.
- Byte-perfect RGBDS rebuild/diff validation: **pending build integration**.

This milestone means the Bank 01 source structure is present and its known locale/revision families are represented. It does **not** yet claim that an assembled Bank 01 is byte-identical to every reference ROM.

## Reference Bank 01 SHA-1

| Target | Bank 01 SHA-1 |
| --- | --- |
| `en-us-eu` | `1d126f82afaa2aacc62f09d32886116bbd4730bd` |
| `fr` | `0a698f38ff6fc0f35fb544663171f7892ed9219a` |
| `de` | `b8e2ccf96cc8085963be1bafc6b18a137593725b` |
| `it` | `6f72d9521ef29010eb33fc5fea639cc3717dbc36` |
| `es` | `612c5604a307b9de97ead66866502db4872795ad` |
| `jp-rev0a` | `24a653b8d28d0cb2c66c4147c3a95fe4533620ed` |
| `jp-revb` | `f92926b32a031fd35be23e02214a73fb09141344` |
| `jp-revc` | `16252dfa6ec87414b4e32691322d513efa1b224c` |
| `jp-revd` | `8b1a7807d0221bba490d4d8a1ae191fde0ad9ca9` |

## Major release-family differences

### Naming screen

The naming engine has three verified behavioral layers:

1. Japanese kana keyboard: 6x9 kana grid, Japanese layout, Japanese dakuten/handakuten glyphs, and the original Japanese ED-tile loading path.
2. EN/DE Latin compositional prompt: 5x9 Latin keyboard; player/rival prefix is followed by a shared `NAME?` string.
3. FR/IT/ES Latin direct prompt: 5x9 Latin keyboard; player/rival question is a complete localized string.

See `config/naming_screen_family_matrix.json`.

### Text boxes and field moves

The international releases dynamically move the field-move menu left according to localized move-name width. Japanese uses a fixed right-side menu and a two-byte field-move display table.

German uniquely saves/restores seven columns for the two-option menu backing area; all other checked releases use six.

Money rendering also differs:

- EN/DE/IT use the `MONEY_SIGN` `PrintBCDNumber` path.
- FR/ES place the currency string first and then print the BCD value without `MONEY_SIGN`.
- JP places the Japanese yen string first and then prints the BCD value.

Italian and Spanish text-box coordinates, field-move names, and field-move left-edge values were reconstructed directly from their reference ROMs. See `config/text_box_family_matrix.json`.

### Cable Club / Trade Center

The international Trade Center uses upper/lower party boxes and one-row list placement with double-spaced menu input handling. Japanese uses left/right party boxes and a two-row list stride.

The enemy-link-buffer clear length is release-family-sensitive:

- international: `0x01A9`
- Japanese: `0x013B`

The Japanese `0x013B` clear is preserved as historical behavior even though the public source flags it as suspicious because it does not reach `wTrainerHeaderPtr`. Any correction belongs in a downstream modernization target, not the exact historical reconstruction.

Italian and Spanish wait strings, stats/trade strings, cancel-box geometry, and trade-result strings were decoded directly from their reference ROMs. See `config/cable_club_family_matrix.json`.

## Preserved historical behavior

Reconstruction keeps original unused code, redundant operations, suspicious constants, and known bugs when they are part of the source ROM behavior. Examples in Bank 01 include the Japanese Cable Club short clear and the `$ff` write in the final-slot path of `engine/pokemon/remove_mon.asm`.

Fixes belong in a separate modernization target after exact reconstruction is verified.

## Next validation step

1. Complete enough cross-bank symbols/constants/assets to assemble Bank 01 through RGBDS.
2. Assemble every supported target with the correct release defines.
3. Extract the generated Bank 01 (`0x4000-0x7fff`).
4. Compare SHA-1 and byte ranges with the reference Bank 01 hashes above.
5. Resolve source-layout mismatches without replacing reconstructed source with raw-ROM slices.
6. Record per-target `.map`/`.sym` evidence and only then mark Bank 01 byte-perfect.
