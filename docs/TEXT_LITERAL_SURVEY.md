# Bank 00 Text Literal Survey

The fixed command-expansion strings used by the Bank 00 text engine have now been located directly in all nine unique reference ROMs.

## International releases

| Target | ROM0 block | TM | Trainer | Rocket | Enemy phrase | Enemy composition |
| --- | --- | --- | --- | --- | --- | --- |
| EN USA/EU | `$1823-$1849` | `TM` | `TRAINER` | `ROCKET` | `Enemy ` | literal + nickname |
| FR | `$1820-$1845` | `CT` | `DRES.` | `ROCKET` | ` ennemi` | nickname + literal |
| DE | `$1823-$184E` | `TM` | `TRAINER` | `TEAM ROCKET` | `Gegn. ` | literal + nickname |
| IT | `$1823-$1849` | `MT` | `ALLEN.` | `ROCKET` | ` nemico` | nickname + literal |
| ES | `$1823-$1848` | `MT` | `ENTREN.` | `ROCKET` | `Enem.` | literal + nickname |

The exact encoded bytes and literal ordering are recorded in `config/text_locale_matrix.json`.

### Character-map finding

The English release encodes the `é` in `POKé` as `$BA`. French, German, Italian and Spanish encode the same visible `é` as `$BC`.

Therefore the international releases cannot be treated as one byte-identical character map. Locale-specific character maps must be reconstructed and selected at build time.

## Japanese releases

The Japanese literals are byte-identical across all four revisions; only their ROM0 position changes.

| Target | ROM0 block |
| --- | --- |
| JP V1.0 / Rev 0A | `$18CD-$18F4` |
| JP V1.1 / Rev B | `$18D3-$18FA` |
| JP V1.2 / Rev C | `$18D3-$18FA` |
| JP V1.3 / Rev D | `$18D3-$18FA` |

Literal order and decoded values:

1. `わざマシン`
2. `トレーナー`
3. `パソコン`
4. `ロケットだん`
5. `ポケモン`
6. `⋯⋯`
7. `てきの　`
8. `が　`

The six-byte relocation between JP V1.0 and V1.1+ is caused by earlier ROM0 layout differences; the literal bytes themselves are unchanged.

## Reproducible verification

Run:

```sh
python3 tools/survey_text_literals.py ROM [ROM ...]
```

The tool:

1. hashes each ROM with SHA-1;
2. resolves it against `config/releases.json`;
3. selects the exact release/revision literal range from `config/text_locale_matrix.json`;
4. splits the block on the `$50` string terminator;
5. compares every literal against the expected raw bytes;
6. returns a failing exit status if a known target does not match.

No ROM bytes are written to the repository.

## Consequence for source reconstruction

`home/text.asm` should be reconstructed as a shared semantic engine, while the following remain data-/family-specific:

- fixed command-expansion literals;
- international locale character maps;
- Japanese kana dakuten/handakuten rendering;
- Japanese-only `<GA>` handling;
- international `TX_FAR`, page-character and UI-layout behavior;
- language-specific enemy-name composition order.

This prevents translated strings from forcing duplicate copies of the text engine while preserving real binary differences.
