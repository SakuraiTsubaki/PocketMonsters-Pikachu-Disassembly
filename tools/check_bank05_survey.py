#!/usr/bin/env python3
"""Validate the ROM-free Bank 05 survey and reconstructed Japanese Garbage 5 tails."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

BANK = Path("config/bank05_modules.json")
DOC = Path("docs/BANK_05.md")

EXPECTED_BANK_SHA1 = {
    "jp-rev0a": "f24cc30bb77a5dd7dddc06d729d5bd234a10dfcc",
    "jp-revb": "53d7ca866e4ec23c658bfe46adfcac5eaab10d04",
    "jp-revc": "1f196bf33674ce76bbdc320ff0dd4ccc1b65782f",
    "jp-revd": "006cc54ac31cea12c37b7013e38b6c78c5af932d",
    "en-us-eu": "14cb943d332b8b777b46a2d4ddd6c9660679c733",
    "fr": "2e94d15e1ccb5f388c7fe79d91940b0457a1ed9a",
    "de": "f134289aedca6a566565129507457a9dfb1ca793",
    "it": "b1230d9b47d4cfac4739914f6d978370638d52cd",
    "es": "8a32f1fc027b164a7f9aeb4afedc57d340781209",
}

EXPECTED_INTL = {
    "bank5": [
        "engine/gfx/load_pokedex_tiles.asm",
        "engine/overworld/map_sprites.asm",
    ],
    "Battle Engine 2": [
        "engine/battle/move_effects/substitute.asm",
        "engine/menus/pc.asm",
    ],
    "Doors and Ledges": [
        "engine/overworld/auto_movement.asm",
        "engine/overworld/doors.asm",
        "engine/overworld/ledges.asm",
    ],
}
EXPECTED_JP = {
    "bank5": EXPECTED_INTL["bank5"],
    "Battle Engine 2": EXPECTED_INTL["Battle Engine 2"],
    "Doors and Ledges": [
        "engine/overworld/auto_movement.asm",
        "engine/events/pewter_guys.asm",
        "engine/overworld/doors.asm",
        "engine/overworld/ledges.asm",
    ],
}

TAILS = {
    "jp-rev0a": (Path("data/garbage/jp/rev0a/bank05_tail.asm"), "2d09733845a5a930d1b90259443c8c7189be5c1e", "39f2c42c2a5379bcfe83a6be230ffc2aa728cd19"),
    "jp-revb": (Path("data/garbage/jp/revb/bank05_tail.asm"), "a317bfc33f110d857b3bf87396fd86e167189a45", "447bd05ce79df6fb76eb9265b11ad3424ace483a"),
    "jp-revc": (Path("data/garbage/jp/revc/bank05_tail.asm"), "4212d3c7390b61a623bb53c909a88bedd814c327", "d80cc462b115747532c7e61f5ff01733b32b69d9"),
}
DB_BYTE = re.compile(r"\$([0-9A-Fa-f]{2})(?![0-9A-Fa-f])")


def fail(message: str) -> None:
    raise SystemExit(f"Bank 05 check FAILED: {message}")


def parse_db(path: Path) -> bytes:
    if not path.is_file():
        fail(f"missing tail source {path}")
    values: list[int] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        code = line.split(";", 1)[0]
        if "db" in code.lower():
            values.extend(int(m.group(1), 16) for m in DB_BYTE.finditer(code))
    return bytes(values)


def blob_sha1(data: bytes) -> str:
    return hashlib.sha1(f"blob {len(data)}\0".encode("ascii") + data).hexdigest()


def main() -> None:
    if not BANK.is_file() or not DOC.is_file():
        fail("missing Bank 05 survey ledger or documentation")
    bank = json.loads(BANK.read_text(encoding="utf-8"))

    if bank.get("bank") != "05" or bank.get("range") != "0x14000-0x17fff":
        fail("unexpected bank identity/range")
    if bank.get("status") != "survey-complete":
        fail("survey status changed")
    if bank.get("source_reconstruction_complete") is not False:
        fail("source reconstruction must remain unclaimed")
    if bank.get("byte_perfect_rebuild_claim") is not False:
        fail("byte-perfect rebuild must remain unclaimed")
    if bank.get("bank_sha1") != EXPECTED_BANK_SHA1:
        fail("one or more Bank 05 reference hashes changed")

    layout = bank.get("layout_crosscheck", {})
    intl = layout.get("international_reference", {})
    jp = layout.get("japanese_reference", {})
    if intl.get("top_level_module_count") != 7 or jp.get("top_level_module_count") != 8:
        fail("family top-level module counts changed")
    if intl.get("sections") != EXPECTED_INTL:
        fail("international section/module layout changed")
    if jp.get("sections") != EXPECTED_JP:
        fail("Japanese section/module layout changed")
    if layout.get("logical_layout_identical") is not False:
        fail("family-specific Bank 05 include structure must remain explicit")
    nested = intl.get("nested_include", {})
    if nested.get("parent") != "engine/overworld/auto_movement.asm" or nested.get("path") != "engine/events/pewter_guys.asm":
        fail("international pewter_guys nested-include evidence changed")

    obs = bank.get("direct_rom_observations", {})
    if obs.get("japanese_active_boundary_bank_offset") != "0x3e8a":
        fail("Japanese active/tail boundary changed")
    if obs.get("japanese_active_length") != 16010 or obs.get("japanese_tail_length") != 374:
        fail("Japanese active/tail lengths changed")
    if obs.get("later_japanese_active_payload_identity") is not True:
        fail("JP Rev B/C/D active identity must remain asserted")
    expected_pairwise = {
        "jp-rev0a_vs_jp-revb": (415, 41),
        "jp-revb_vs_jp-revc": (67, 0),
        "jp-revc_vs_jp-revd": (349, 0),
    }
    pairwise = obs.get("japanese_pairwise", {})
    for key, (whole, active) in expected_pairwise.items():
        rec = pairwise.get(key, {})
        if rec.get("whole_bank_differing_bytes") != whole or rec.get("active_differing_bytes") != active:
            fail(f"{key} difference ledger changed")
    rev0 = pairwise.get("jp-rev0a_vs_jp-revb", {})
    if rev0.get("active_difference_ranges") != 40:
        fail("Rev 0A active difference range count changed")
    if set(obs.get("international_last_nonzero_bank_offset", {}).values()) != {"0x3de2"}:
        fail("international last-nonzero observations changed")
    if obs.get("international_trailing_zero_bytes") != 541:
        fail("international trailing-zero observation changed")

    source_search = bank.get("revision_source_search", {})
    if source_search.get("bank05_top_level_matches") != 0:
        fail("unexpected direct _REV0 conditional reported in Bank 05 top-level paths")
    if source_search.get("rev0a_active_difference_classification") != "pending-symbol-aware-link-validation":
        fail("Rev 0A active-difference classification changed prematurely")

    garbage = bank.get("garbage_5", {})
    if garbage.get("range") != "0x17e8a-0x17fff" or garbage.get("length") != 374:
        fail("Garbage 5 range/length changed")
    for rev, (path, raw_expected, blob_expected) in TAILS.items():
        rec = garbage.get(rev, {})
        if rec.get("present") is not True or rec.get("source") != str(path):
            fail(f"{rev} Garbage 5 metadata changed")
        if rec.get("raw_sha1") != raw_expected or rec.get("public_git_blob_sha1") != blob_expected:
            fail(f"{rev} Garbage 5 hash metadata changed")
        data = parse_db(path)
        if len(data) != 374:
            fail(f"{rev} tail emits {len(data)} bytes instead of 374")
        if hashlib.sha1(data).hexdigest() != raw_expected:
            fail(f"{rev} tail raw SHA mismatch")
        if blob_sha1(data) != blob_expected:
            fail(f"{rev} tail Git blob SHA mismatch")

    revd = garbage.get("jp-revd", {})
    if revd.get("present") is not False or revd.get("zero_fill") is not True:
        fail("JP Rev D must use zero fill")
    zero_sha = hashlib.sha1(bytes(374)).hexdigest()
    if zero_sha != "f51ebfd66841e4f950a7011e4934f895d409ccbf" or revd.get("raw_sha1_of_zero_tail") != zero_sha:
        fail("JP Rev D zero-tail SHA mismatch")

    doc = DOC.read_text(encoding="utf-8")
    for token in (
        "7 top-level modules",
        "8 top-level modules",
        "nested include",
        "Rev B, Rev C, and Rev D have byte-identical active Bank 05 payloads",
        "0x17E8A-0x17FFF",
        "last non-zero byte is not a source-section boundary",
        "pending-symbol-aware-link-validation",
    ):
        if token not in doc:
            fail(f"documentation is missing required evidence token: {token!r}")

    print(
        "Bank 05 check passed: nine bank hashes, family-specific 7/8 top-level layouts, "
        "pewter_guys nested/top-level placement, JP Rev B/C/D active identity, Rev 0A "
        "41-byte active-difference ledger, and three 374-byte Garbage 5 ASM tails verified."
    )


if __name__ == "__main__":
    main()
