#!/usr/bin/env python3
"""Validate the Bank 02 audio-equivalence survey metadata.

This is a repository-consistency check, not a ROM byte comparison. Reference
ROMs are intentionally not required by CI.
"""

from __future__ import annotations

import json
from pathlib import Path

BANK = Path("config/bank02_modules.json")
RELOC = Path("config/bank02_relocation_matrix.json")
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


def fail(message: str) -> None:
    raise SystemExit(f"Bank 02 survey check FAILED: {message}")


def main() -> None:
    for path in (BANK, RELOC, DOC):
        if not path.is_file():
            fail(f"missing {path}")

    bank = json.loads(BANK.read_text(encoding="utf-8"))
    reloc = json.loads(RELOC.read_text(encoding="utf-8"))

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

    print("Bank 02 survey check passed: 9 targets, active audio equivalent after relocation normalization, Garbage 2 evidence verified.")


if __name__ == "__main__":
    main()
