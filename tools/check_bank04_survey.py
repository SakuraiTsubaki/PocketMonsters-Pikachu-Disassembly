#!/usr/bin/env python3
"""Validate the ROM-free Bank 04 survey and reconstructed Japanese Garbage 4 tails."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

BANK = Path("config/bank04_modules.json")
DOC = Path("docs/BANK_04.md")
IMPORTER = Path(".github/workflows/import-bank04-tails.yml")

EXPECTED_BANK_SHA1 = {
    "jp-rev0a": "2344a36c8e3c74a6d722ee3a133ff899caa4d65c",
    "jp-revb": "9159a3ae11ea0def01287749c81078e22eef92e8",
    "jp-revc": "e9cc532c17d0802c4c5499f1aa738ac65204bf3e",
    "jp-revd": "6897c1d250a4b095e6312569ae77388c346b9e67",
    "en-us-eu": "5554b5f767c8016e1851df2cb5dbd5f5d55c7c8e",
    "fr": "99ad4ca19a83246c7b15cc9f7ed98e60958c756b",
    "de": "f73b98551029dcdc457920f7b6eb3d0d96b83a26",
    "it": "6111f4f90d2327e1bcbe66aaf50764a2b36ae647",
    "es": "06181f63918d821aa57dd6115f40003e404f6d4c",
}

EXPECTED_INTL_BANK4 = [
    "gfx/font.asm",
    "engine/pokemon/status_screen.asm",
    "engine/menus/party_menu.asm",
    "gfx/player.asm",
    "engine/menus/start_sub_menus.asm",
    "engine/items/tms.asm",
]
EXPECTED_JP_BANK4 = [
    "data/moves/names.asm",
    "gfx/font.asm",
    "engine/overworld/is_player_just_outside_map.asm",
    "engine/pokemon/status_screen.asm",
    "engine/menus/party_menu.asm",
    "gfx/player.asm",
    "engine/menus/start_sub_menus.asm",
    "engine/items/tms.asm",
]
EXPECTED_INTL_BATTLE1 = [
    "engine/battle/end_of_battle.asm",
    "engine/battle/wild_encounters.asm",
    "engine/battle/move_effects/recoil.asm",
    "engine/battle/move_effects/conversion.asm",
    "engine/battle/move_effects/haze.asm",
]
EXPECTED_JP_BATTLE1 = EXPECTED_INTL_BATTLE1 + [
    "engine/overworld/npc_movement_2.asm"
]

TAILS = {
    "jp-rev0a": {
        "path": Path("data/garbage/jp/rev0a/bank04_tail.asm"),
        "raw_sha1": "ad0888f5257205ab467810840a334b183eeb3f52",
        "blob_sha1": "05019b76fa9ad16f8e6b84a2af6ea3e507c14d7e",
    },
    "jp-revb": {
        "path": Path("data/garbage/jp/revb/bank04_tail.asm"),
        "raw_sha1": "237775b27321e2e943ff4227851619f3f4ae3b70",
        "blob_sha1": "dcdb00ce7b97410f3b976ec7febbb3fa690e31ae",
    },
    "jp-revc": {
        "path": Path("data/garbage/jp/revc/bank04_tail.asm"),
        "raw_sha1": "5d1943617c7a4bb19b829a7c942663baf70e40de",
        "blob_sha1": "5ce7e4dd53b9a0c47630e069aff9c27c5fca0eea",
    },
}
DB_BYTE = re.compile(r"\$([0-9A-Fa-f]{2})(?![0-9A-Fa-f])")


def fail(message: str) -> None:
    raise SystemExit(f"Bank 04 check FAILED: {message}")


def parse_db_bytes(path: Path) -> bytes:
    if not path.is_file():
        fail(f"missing reconstructed tail source {path}")
    values: list[int] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        code = line.split(";", 1)[0]
        if "db" not in code.lower():
            continue
        values.extend(int(m.group(1), 16) for m in DB_BYTE.finditer(code))
    return bytes(values)


def git_blob_sha1(data: bytes) -> str:
    return hashlib.sha1(f"blob {len(data)}\0".encode("ascii") + data).hexdigest()


def main() -> None:
    for path in (BANK, DOC):
        if not path.is_file():
            fail(f"missing {path}")
    if IMPORTER.exists():
        fail("one-shot Bank 04 importer must not remain tracked")

    bank = json.loads(BANK.read_text(encoding="utf-8"))
    if bank.get("bank") != "04" or bank.get("range") != "0x10000-0x13fff":
        fail("unexpected bank identity/range")
    if bank.get("status") != "survey-complete":
        fail("survey status is not survey-complete")
    if bank.get("source_reconstruction_complete") is not False:
        fail("source reconstruction must not be claimed complete yet")
    if bank.get("byte_perfect_rebuild_claim") is not False:
        fail("byte-perfect rebuild must not be claimed yet")
    if bank.get("bank_sha1") != EXPECTED_BANK_SHA1:
        fail("one or more Bank 04 target SHA-1 values changed")

    layout = bank.get("layout_crosscheck", {})
    intl = layout.get("international_reference", {})
    jp = layout.get("japanese_reference", {})
    if intl.get("sections", {}).get("bank4") != EXPECTED_INTL_BANK4:
        fail("international bank4 module order changed")
    if intl.get("sections", {}).get("Battle Engine 1") != EXPECTED_INTL_BATTLE1:
        fail("international Battle Engine 1 module order changed")
    if jp.get("sections", {}).get("bank4") != EXPECTED_JP_BANK4:
        fail("Japanese bank4 module order changed")
    if jp.get("sections", {}).get("Battle Engine 1") != EXPECTED_JP_BATTLE1:
        fail("Japanese Battle Engine 1 module order changed")
    if intl.get("top_level_module_count") != 11 or jp.get("top_level_module_count") != 14:
        fail("family module counts changed")
    if layout.get("logical_layout_identical") is not False:
        fail("Bank 04 family layouts must remain marked non-identical")

    placements = layout.get("japanese_additional_placements", {})
    expected_placements = {
        "data/moves/names.asm": 'text.asm / SECTION "Move Names"',
        "engine/overworld/is_player_just_outside_map.asm": 'main.asm / SECTION "bank3A"',
        "engine/overworld/npc_movement_2.asm": 'main.asm / SECTION "bank3A"',
    }
    for path, placement in expected_placements.items():
        if placements.get(path, {}).get("international_placement") != placement:
            fail(f"family-specific placement evidence changed: {path}")

    obs = bank.get("direct_rom_observations", {})
    if obs.get("japanese_active_boundary_bank_offset") != "0x3fc2":
        fail("Japanese active/tail boundary changed")
    if obs.get("japanese_active_length") != 16322:
        fail("Japanese active length changed")
    pairwise = obs.get("japanese_pairwise", {})
    expected_pairwise = {
        "jp-rev0a_vs_jp-revb": (322, 260),
        "jp-revb_vs_jp-revc": (9, 0),
        "jp-revc_vs_jp-revd": (53, 0),
    }
    for key, (whole, active) in expected_pairwise.items():
        entry = pairwise.get(key, {})
        if entry.get("whole_bank_differing_bytes") != whole:
            fail(f"{key} whole-bank difference count changed")
        if entry.get("active_differing_bytes") != active:
            fail(f"{key} active difference count changed")

    source_search = bank.get("revision_source_search", {})
    if source_search.get("bank04_top_level_matches") != 0:
        fail("unexpected direct _REV0 conditional reported in Bank 04 top-level modules")

    garbage = bank.get("garbage_4", {})
    if garbage.get("length") != 62 or garbage.get("range") != "0x13fc2-0x13fff":
        fail("Garbage 4 range/length changed")
    for rev, expected in TAILS.items():
        entry = garbage.get(rev, {})
        if entry.get("present") is not True:
            fail(f"{rev} Garbage 4 must be present")
        if entry.get("source") != str(expected["path"]):
            fail(f"{rev} source path changed")
        if entry.get("raw_sha1") != expected["raw_sha1"]:
            fail(f"{rev} raw SHA metadata changed")
        if entry.get("public_git_blob_sha1") != expected["blob_sha1"]:
            fail(f"{rev} public Git blob metadata changed")
        data = parse_db_bytes(expected["path"])
        if len(data) != 62:
            fail(f"{rev} ASM tail emits {len(data)} bytes instead of 62")
        if hashlib.sha1(data).hexdigest() != expected["raw_sha1"]:
            fail(f"{rev} ASM tail raw SHA mismatch")
        if git_blob_sha1(data) != expected["blob_sha1"]:
            fail(f"{rev} ASM tail Git blob SHA mismatch")

    revd = garbage.get("jp-revd", {})
    if revd.get("present") is not False or revd.get("zero_fill") is not True:
        fail("JP Rev D must use zero fill rather than Garbage 4 source")
    zero_sha = hashlib.sha1(bytes(62)).hexdigest()
    if zero_sha != "566538c1539e2db072bd6dd57dbaae4e470ad831":
        fail("internal zero-tail SHA mismatch")
    if revd.get("raw_sha1_of_zero_tail") != zero_sha:
        fail("JP Rev D zero-tail metadata mismatch")

    doc = DOC.read_text(encoding="utf-8")
    for token in (
        "11 top-level modules",
        "14 top-level modules",
        "family-specific bank placement",
        "Rev B, Rev C, and Rev D have byte-identical active Bank 04 payloads",
        "0x13FC2-0x13FFF",
        "last non-zero byte is not a source-section boundary",
    ):
        if token not in doc:
            fail(f"documentation is missing required evidence token: {token!r}")

    print(
        "Bank 04 check passed: nine bank hashes, family-specific 11/14-module layouts, "
        "JP Rev B/C/D active identity, Rev 0A active-difference ledger, and three "
        "62-byte Garbage 4 ASM tails verified."
    )


if __name__ == "__main__":
    main()
