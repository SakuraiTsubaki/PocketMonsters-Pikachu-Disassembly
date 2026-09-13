#!/usr/bin/env python3
"""Validate the reconstructed Bank 02 Music 1 source set and entry-point order."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

INVENTORY = Path("config/bank02_source_inventory.json")
MANIFEST = Path("config/bank02_music1_blobs.json")
BANK_ENTRY = Path("banks/bank02.asm")

EXPECTED_REFERENCE = "f282e72ae26232790fdb780aa5a5db7ec8ebf572"
EXPECTED_SECTIONS = [
    "Sound Effect Headers 1",
    "Music Headers 1",
    "Sound Effects 1",
    "Audio Engine 1",
    "Music 1",
    "Garbage 2",
]
EXPECTED_MUSIC_FILES = [
    "audio/wave_samples.asm",
    "audio/music/pkmn_healed.asm",
    "audio/music/routes_1.asm",
    "audio/music/routes_2.asm",
    "audio/music/routes_3.asm",
    "audio/music/routes_4.asm",
    "audio/music/indigo_plateau.asm",
    "audio/music/pallet_town.asm",
    "audio/music/unused_song.asm",
    "audio/music/cities_1.asm",
    "audio/sfx/get_item1.asm",
    "audio/music/museum_guy.asm",
    "audio/music/meet_prof_oak.asm",
    "audio/music/meet_rival.asm",
    "audio/sfx/pokedex_rating.asm",
    "audio/sfx/get_item2.asm",
    "audio/sfx/get_key_item.asm",
    "audio/music/ss_anne.asm",
    "audio/music/cities_2.asm",
    "audio/music/celadon.asm",
    "audio/music/cinnabar.asm",
    "audio/music/vermilion.asm",
    "audio/music/lavender.asm",
    "audio/music/safari_zone.asm",
    "audio/music/gym.asm",
    "audio/music/pokecenter.asm",
]
EXPECTED_TAIL_FILES = [
    "data/garbage/jp/rev0a/bank02_tail.asm",
    "data/garbage/jp/revb/bank02_tail.asm",
    "data/garbage/jp/revc/bank02_tail.asm",
]
SECTION_LINE = re.compile(r'^\s*SECTION\s+"([^"]+)"', re.IGNORECASE)
INCLUDE_LINE = re.compile(r'^\s*INCLUDE\s+"([^"]+)"\s*(?:;.*)?$', re.IGNORECASE)


def fail(message: str) -> None:
    raise SystemExit(f"Bank 02 Music 1 check FAILED: {message}")


def git_blob_sha1(path: Path) -> str:
    data = path.read_bytes()
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()


def parse_lines(path: Path, regex: re.Pattern[str]) -> list[str]:
    values: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = regex.match(line)
        if match:
            values.append(match.group(1))
    return values


def source_group(inventory: dict, name: str) -> dict:
    matches = [g for g in inventory.get("source_groups", []) if g.get("name") == name]
    if len(matches) != 1:
        fail(f"expected exactly one source group named {name!r}")
    return matches[0]


def main() -> None:
    for path in (INVENTORY, MANIFEST, BANK_ENTRY):
        if not path.is_file():
            fail(f"missing {path}")

    inventory = json.loads(INVENTORY.read_text(encoding="utf-8"))
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    if manifest.get("bank") != "02" or manifest.get("group") != "music-1":
        fail("manifest bank/group mismatch")
    if manifest.get("hash_kind") != "git-blob-sha1":
        fail("manifest hash kind must be git-blob-sha1")
    if manifest.get("reference_repository") != "Narishma-gb/pokeyellow-jp":
        fail("unexpected reference repository")
    if manifest.get("reference_commit") != EXPECTED_REFERENCE:
        fail("reference commit is not pinned to the verified source snapshot")

    entries = manifest.get("files", [])
    manifest_paths = [entry.get("path") for entry in entries]
    if manifest_paths != EXPECTED_MUSIC_FILES:
        fail("Music 1 manifest path order mismatch")
    if len(entries) != 26 or len(set(manifest_paths)) != 26:
        fail("Music 1 manifest must contain 26 unique source files")

    for entry in entries:
        path = Path(entry["path"])
        if not path.is_file():
            fail(f"missing Music 1 source {path}")
        actual = git_blob_sha1(path)
        if actual != entry.get("sha"):
            fail(f"Git blob SHA mismatch for {path}: {actual}")

    music = source_group(inventory, "music-1")
    if music.get("status") != "source-reconstructed":
        fail("Music 1 inventory is not marked source-reconstructed")
    if music.get("files") != EXPECTED_MUSIC_FILES:
        fail("Music 1 inventory path/order mismatch")
    if music.get("wave_table_files") != 1 or music.get("sequence_or_fanfare_files") != 25:
        fail("Music 1 logical file counts changed")
    if music.get("verification_manifest") != str(MANIFEST):
        fail("Music 1 verification manifest link mismatch")

    sections = parse_lines(BANK_ENTRY, SECTION_LINE)
    if sections != EXPECTED_SECTIONS:
        fail(f"Bank 02 section order mismatch: {sections}")

    entry_includes = parse_lines(BANK_ENTRY, INCLUDE_LINE)
    music_start = entry_includes.index("audio/wave_samples.asm")
    tail_start = entry_includes.index(EXPECTED_TAIL_FILES[0])
    if entry_includes[music_start:tail_start] != EXPECTED_MUSIC_FILES:
        fail("Bank 02 Music 1 include order mismatch")
    if entry_includes[tail_start:] != EXPECTED_TAIL_FILES:
        fail("Bank 02 revision-tail include order mismatch")

    text = BANK_ENTRY.read_text(encoding="utf-8")
    if 'SECTION "Sound Effect Headers 1", ROMX[$4000], BANK[$2]' not in text:
        fail("Bank 02 start is not anchored at ROMX $4000 / bank $2")
    if 'SECTION "Garbage 2", ROMX[$7EC7], BANK[$2]' not in text:
        fail("historical tail is not anchored at bank-local $7EC7")
    for token in ("DEF(_JAPAN)", "DEF(_REV0)", "DEF(_REV1)", "DEF(_REV2)"):
        if token not in text:
            fail(f"missing revision selector {token}")

    print(
        "Bank 02 Music 1 check passed: 26/26 source blobs match the pinned reference, "
        "canonical section/include order is fixed, and JP Rev 0A/B/C tails are wired."
    )


if __name__ == "__main__":
    main()
