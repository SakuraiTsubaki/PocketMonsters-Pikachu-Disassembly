# Verified Reference Source Set

This document records the initial reference ROM set used to identify supported Pocket Monsters Pikachu / Pokémon Yellow releases. ROM images themselves are not stored in this repository.

## Summary

- Reference files observed: **14**
- Unique ROM images after byte-level hashing: **9**
- Size of every unique image: **1,048,576 bytes (1 MiB)**
- ROM banks per image: **64 × 16 KiB**

The paired `.gb` and `.gbc` filenames supplied for the localized English, French, German, Italian, and Spanish releases are byte-for-byte duplicates within each language. They therefore represent five unique localized ROM images, not ten.

Together with four Japanese revisions, the initial source set contains nine unique ROM images.

## Unique releases

| ID | Release | SHA-1 | Header version |
| --- | --- | --- | --- |
| `jp-rev0a` | Pocket Monsters Pikachu (Japan) Rev 0A | `1fb6c264e950d97ce3fd99b347e485b2150df4ff` | `00` |
| `jp-revb` | Pocket Monsters Pikachu (Japan) Rev B | `28e4b8531ea4ea1de5a396fccb0cfba51b06b149` | `01` |
| `jp-revc` | Pocket Monsters Pikachu (Japan) Rev C | `91864ecdf26d1c593bde4d9ed615520eb57d5e41` | `02` |
| `jp-revd` | Pocket Monsters Pikachu (Japan) Rev D | `a40298a8123613ee60cd7aab204d788b8425976e` | `03` |
| `en-us-eu` | Pokémon Yellow Version (USA, Europe) | `cc7d03262ebfaf2f06772c1a480c7d9d5f4a38e1` | `00` |
| `fr` | Pokémon Version Jaune (France) | `0aceec0ef7aa2ca5aa831554598d91f61a925591` | `00` |
| `de` | Pokémon Gelbe Edition (Germany) | `42f3714eec6eca25200d42461ff08d57c98f6d1d` | `00` |
| `it` | Pokémon Versione Gialla (Italy) | `05bb8e99f24d498613930949730afa8024e77d08` | `00` |
| `es` | Pokémon Edición Amarilla (Spain) | `1dc242039218fba50928d1afb66b70565b6b9daf` | `00` |

Full MD5, SHA-1, SHA-256, header checksum, global checksum, and cartridge-header metadata are stored in `config/releases.json`.

## Architecture split visible in cartridge headers

The initial header survey shows an important implementation boundary:

### Japanese revisions

- CGB flag: `0x00`
- SGB flag: `0x03`
- Cartridge type: `0x13` (MBC3 + RAM + battery)
- Destination code: `0x00`
- Header revisions: `00`, `01`, `02`, `03`

### Localized releases

- CGB flag: `0x80`
- SGB flag: `0x03`
- Cartridge type: `0x1B` (MBC5 + RAM + battery)
- Destination code: `0x01`
- Header revision: `00`

This difference must be modeled explicitly in the disassembly. The Japanese and localized families must not be treated as merely text-localized copies of one binary layout.

## Reconstruction rule

Reference ROMs may be used locally during reverse engineering, extraction, comparison, and byte-exact verification. A release is not considered fully reconstructed until its build no longer requires the reference ROM as an input and its generated ROM matches the recorded reference hash byte-for-byte.
