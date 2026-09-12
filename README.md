# PocketMonsters-Pikachu-Disassembly

RGBDS disassembly and reconstruction project for **Pocket Monsters Pikachu / Pokémon Yellow** across languages, regions, and revisions.

The long-term goal is to restore ROM code, data, text, graphics, maps, scripts, audio, and related assets into editable source form and produce **ROM-free reproducible builds**: once a release is fully reconstructed, `git clone` + the documented toolchain + `make` should be enough to rebuild a byte-identical ROM without supplying a local original ROM.

## Repository policy

- Original and modified ROM images are never committed.
- Local reference ROMs may be used only for reverse engineering, extraction, comparison, and verification.
- Repository-owned reconstructed assets may be included with `INCBIN`; direct slices from a local `baserom` are not considered complete reconstruction.
- Every supported release has explicit hashes and cartridge-header metadata.
- A release is complete only when a clean build reproduces its recorded reference hash byte-for-byte.
- Language, region, hardware mode, mapper, and revision differences are represented explicitly.

The policy is enforced by `make check-policy` and GitHub Actions.

## Verified initial source set

The supplied reference set contains **14 filenames but 9 unique ROM images**. The paired `.gb` and `.gbc` filenames for English, French, German, Italian, and Spanish are byte-for-byte duplicates within each language.

| Target ID | Release | SHA-1 | Reconstruction |
| --- | --- | --- | --- |
| `jp-rev0a` | Pocket Monsters Pikachu (Japan) V1.0 | `1fb6c264e950d97ce3fd99b347e485b2150df4ff` | pending |
| `jp-revb` | Pocket Monsters Pikachu (Japan) V1.1 | `28e4b8531ea4ea1de5a396fccb0cfba51b06b149` | pending |
| `jp-revc` | Pocket Monsters Pikachu (Japan) V1.2 | `91864ecdf26d1c593bde4d9ed615520eb57d5e41` | pending |
| `jp-revd` | Pocket Monsters Pikachu (Japan) V1.3 | `a40298a8123613ee60cd7aab204d788b8425976e` | pending |
| `en-us-eu` | Pokémon Yellow Version (USA, Europe) | `cc7d03262ebfaf2f06772c1a480c7d9d5f4a38e1` | pending |
| `fr` | Pokémon Version Jaune (France) | `0aceec0ef7aa2ca5aa831554598d91f61a925591` | pending |
| `de` | Pokémon Gelbe Edition (Germany) | `42f3714eec6eca25200d42461ff08d57c98f6d1d` | pending |
| `it` | Pokémon Versione Gialla (Italy) | `05bb8e99f24d498613930949730afa8024e77d08` | pending |
| `es` | Pokémon Edición Amarilla (Spain) | `1dc242039218fba50928d1afb66b70565b6b9daf` | pending |

Full MD5/SHA-1/SHA-256 and cartridge-header metadata live in [`config/releases.json`](config/releases.json). See [`docs/SOURCE_SET.md`](docs/SOURCE_SET.md) for the source-set audit.

## Important architecture split

The Japanese family is DMG/SGB-oriented and reports cartridge type `0x13` (MBC3 + RAM + battery), while the localized family sets the CGB flag and uses cartridge type `0x1B` (MBC5 + RAM + battery). The two families therefore must not be modeled as simple text-localized copies of one binary layout.

## Planned source layout

```text
constants/     symbolic IDs and constants
data/          Pokémon, moves, items, trainers, encounters, tables
engine/        executable game-engine code
gfx/           reconstructed graphics and conversion sources
maps/          map block/layout data
scripts/       map and event scripts
text/          localized text and dialogue
audio/         music, SFX, cries, PCM data and audio-engine sources
macros/        RGBDS macros
tools/         extraction, conversion, comparison and validation tools
config/        release identities, hashes and build configuration
tests/         regression and byte-exact rebuild verification
docs/          research notes and reconstruction documentation
build/         generated outputs (ignored)
```

## Bootstrap commands

```sh
make help
make releases
make status
make check-policy
```

Per-release ROM build targets will be enabled as reconstruction milestones become reproducible.

## External reconstruction references

Verified public projects already reconstruct important members of this source set and will be used as comparison references rather than blindly copied:

- `pret/pokeyellow` — English USA/Europe Yellow.
- `Narishma-gb/pokeyellow-jp` — Japanese V1.0, V1.1, V1.2, and V1.3.
- `Narishma-gb/pokeyellow-fr` — French Yellow.
- `Brianum/pokeyellow-de` — German Yellow.

Italian and Spanish reconstruction will be independently verified against the local reference hashes unless equivalent public reconstruction sources are found.
