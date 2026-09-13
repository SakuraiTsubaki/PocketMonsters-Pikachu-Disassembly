#!/usr/bin/env python3
"""Validate Bank 02 survey metadata and reconstructed source evidence.

This remains a ROM-free repository check. Historical JP Garbage 2 tails are
stored as editable RGBDS db source; CI parses those bytes and verifies their
reference hashes without requiring any ROM image.
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

BANK = Path("config/bank02_modules.json")
RELOC = Path("config/bank02_relocation_matrix.json")
INVENTORY = Path("config/bank02_source_inventory.json")
DOC = Path("docs/BANK_02.md")

EXPECTED_TARGETS = {
    "en-us-eu", "fr", "de", "it", "es",
    "jp-rev0a", "jp-revb", "jp-revc", "jp-revd",
}
EXPECTED_SECTIONS = [
    "Sound Effect Headers 1",
    "Music Headers 1",
    "Sound Effects 1",
    "Audio Engine 1",
    "Music 1",
]
EXPECTED_GARBAGE_BLOBS = {
    "jp-rev0a": "72dd62ff37238e91d7b5e990b248c42b84d11a55",
    "jp-revb": "527ecf5802e41e223919bd4233f425bc37403802",
    "jp-revc": "3303ea5d42ecbe546588ba1801409bf791b2152e",
}
EXPECTED_GARBAGE_RAW_SHA1 = {
    "jp-rev0a": "8b7ee3d3c414c9b31c846f39c5f83dd2324486cb",
    "jp-revb": "6bd1fed0b4151c0a4a47ac75dcea5850002f813f",
    "jp-revc": "b155e1d0401566065e442e35bb09526f7d5de304",
}
TAIL_SOURCE_FILES = {
    "jp-rev0a": Path("data/garbage/jp/rev0a/bank02_tail.asm"),
    "jp-revb": Path("data/garbage/jp/revb/bank02_tail.asm"),
    "jp-revc": Path("data/garbage/jp/revc/bank02_tail.asm"),
}
DB_BYTE = re.compile(r"\$([0-9a-fA-F]{2})(?![0-9a-fA-F])")


def fail(message: str) -> None:
    raise SystemExit(f"Bank 02 check FAILED: {message}")


def source_group(inventory: dict, name: str) -> dict:
    matches = [g for g in inventory.get("source_groups", []) if g.get("name") == name]
    if len(matches) != 1:
        fail(f"expected exactly one source group named {name!r}")
    return matches[0]


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


def main() -> None:
    for path in (BANK, RELOC, INVENTORY, DOC):
        if not path.is_file():
            fail(f"missing {path}")

    bank = json.loads(BANK.read_text(encoding="utf-8"))
    reloc = json.loads(RELOC.read_text(encoding="utf-8"))
    inventory = json.loads(INVENTORY.read_text(encoding="utf-8"))

    if bank.get("bank") != "02" or bank.get("range") != "0x8000-0xbfff":
        fail("unexpected bank identity or range")
    if bank.get("status") != "payload-equivalence-verified":
        fail("survey status is not payload-equivalence-verified")
    if bank.get("source_reconstruction_complete") is not False:
        fail("source reconstruction must not be claimed complete yet")
    if bank.get("byte_perfect_rebuild_claim") is not False:
        fail("byte-perfect rebuild must not be claimed yet")
    if set(bank.get("bank_sha1", {})) != EXPECTED_TARGETS:
        fail("Bank 02 hash target set is incomplete")
    if bank.get("layout_crosscheck", {}).get("sections") != EXPECTED_SECTIONS:
        fail("section order changed")

    payload = bank.get("active_audio_payload", {})
    if payload.get("range") != "0x8000-0xbec6":
        fail("active payload boundary changed")
    if payload.get("normalized_identical_across_all_nine_targets") is not True:
        fail("normalized nine-target equivalence is not asserted")
    if payload.get("remaining_non_relocation_differences") != 0:
        fail("unresolved active audio payload differences remain")

    tail = bank.get("garbage_tail", {})
    if tail.get("range") != "0xbec7-0xbfff" or tail.get("length") != 313:
        fail("Garbage 2 boundary/length changed")
    for rev, blob in EXPECTED_GARBAGE_BLOBS.items():
        entry = tail.get(rev, {})
        if entry.get("present") is not True or entry.get("git_blob_sha1") != blob:
            fail(f"{rev} Garbage 2 evidence mismatch")
    if tail.get("jp-revd", {}).get("present") is not False:
        fail("JP Rev D must have a zero-filled tail, not Garbage 2")

    if reloc.get("bank") != "02" or reloc.get("active_payload_range") != "0x8000-0xbec6":
        fail("relocation matrix bank/range mismatch")
    result = reloc.get("result", {})
    if result.get("normalized_active_audio_identical_across_all_targets") is not True:
        fail("relocation matrix does not assert normalized equivalence")
    if result.get("remaining_payload_differences_after_relocation_normalization") != 0:
        fail("relocation matrix reports unresolved differences")
    if reloc.get("international_union", {}).get("differing_byte_count") != 23:
        fail("international relocation union count must be 23")
    if len(reloc.get("international_union", {}).get("offsets", [])) != 23:
        fail("international relocation list length must be 23")
    if reloc.get("english_vs_japanese_revd", {}).get("active_region_differing_byte_count") != 27:
        fail("EN vs JP Rev D active difference count must be 27")
    if reloc.get("japanese_rev0a_vs_revb", {}).get("active_region_differing_byte_count") != 14:
        fail("JP Rev 0A vs Rev B active difference count must be 14")
    if reloc.get("japanese_rev0a_vs_revb", {}).get("resolution") != "relocation-only":
        fail("JP Rev 0A vs Rev B differences are not marked relocation-only")

    if inventory.get("bank") != "02" or inventory.get("status") != "reconstruction-in-progress":
        fail("source inventory identity/status mismatch")

    noncry = source_group(inventory, "noncry-sfx-1")
    if noncry.get("status") != "source-reconstructed" or noncry.get("logical_records") != 34:
        fail("34 non-cry SFX are not marked reconstructed")
    noncry_files = [Path(p) for p in noncry.get("files", [])]
    if len(noncry_files) != 34 or len(set(noncry_files)) != 34:
        fail("non-cry SFX file inventory must contain 34 unique files")
    missing_noncry = [str(p) for p in noncry_files if not p.is_file()]
    if missing_noncry:
        fail("missing non-cry SFX source(s): " + ", ".join(missing_noncry))

    revision_tail = source_group(inventory, "revision-tail")
    if revision_tail.get("status") != "source-reconstructed":
        fail("revision tail source is not marked reconstructed")
    if revision_tail.get("range") != "0xbec7-0xbfff" or revision_tail.get("length") != 313:
        fail("revision-tail inventory boundary/length mismatch")
    if set(revision_tail.get("files", [])) != {str(p) for p in TAIL_SOURCE_FILES.values()}:
        fail("revision-tail source file set mismatch")

    verification = revision_tail.get("verification", {})
    for rev, path in TAIL_SOURCE_FILES.items():
        data = parse_db_bytes(path)
        if len(data) != 313:
            fail(f"{rev} tail source emits {len(data)} bytes instead of 313")
        digest = hashlib.sha1(data).hexdigest()
        if digest != EXPECTED_GARBAGE_RAW_SHA1[rev]:
            fail(f"{rev} tail source raw SHA-1 mismatch: {digest}")
        inv = verification.get(rev, {})
        if inv.get("raw_sha1") != digest:
            fail(f"{rev} inventory raw SHA-1 mismatch")
        if inv.get("git_blob_sha1") != EXPECTED_GARBAGE_BLOBS[rev]:
            fail(f"{rev} inventory public blob SHA-1 mismatch")

    print(
        "Bank 02 check passed: 9-target active audio equivalence, 34/34 non-cry SFX, "
        "and three 313-byte JP revision tails verified from editable ASM source."
    )


if __name__ == "__main__":
    main()
