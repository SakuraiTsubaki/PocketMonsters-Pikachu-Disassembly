# Initial Bank-Level Survey

All nine unique reference ROMs are 1 MiB and therefore contain 64 ROM banks of 16 KiB each (`00`-`3F`). This survey compares raw bank bytes only; a differing bank hash does not by itself prove that every contained routine or data structure differs.

## Japanese revisions

Compared across V1.0, V1.1, V1.2, and V1.3:

- Byte-identical banks across all four revisions: **3 / 64**
- Identical bank IDs: `19`, `1B`, `32`
- Banks with at least one byte difference: **61 / 64**

V1.0 compared individually with V1.1, V1.2, and V1.3 also differs in the same 61 bank IDs. This shows that the Japanese revisions cannot be represented safely as a handful of isolated patch bytes without first reconstructing their layouts and symbols.

## Localized releases

Compared across English USA/Europe, French, German, Italian, and Spanish:

- Byte-identical banks across all five localized releases: **17 / 64**
- Identical bank IDs: `0C`, `1A`, `1B`, `21`, `22`, `23`, `24`, `25`, `31`, `32`, `33`, `34`, `35`, `36`, `37`, `38`, `39`
- Banks with at least one byte difference: **47 / 64**

The high number of differing banks is consistent with localized text/data and layout changes propagating through many banks, while the 17 identical banks are strong candidates for early shared-source validation.

## Across all nine unique releases

Only two complete banks are byte-identical across every Japanese revision and every localized release:

- `1B`
- `32`

These two banks are priority candidates for a first common-source reconstruction because they provide cross-family invariants for both the MBC3 Japanese family and MBC5 localized family.

## Reconstruction implication

The repository should use shared semantic source wherever code/data is proven equivalent, but it should not force bank-level identity as the source abstraction. Bank layout, language, mapper family, and revision differences should be represented through build configuration and narrowly scoped conditional/variant sources after symbol-level comparison.

A later survey will classify each bank into code, text, graphics, audio, map/script, tables, padding/unused, and mixed regions, then map every range to labels and reconstructed source files.
