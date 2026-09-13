#!/usr/bin/env python3
"""Validate the ROM-free Bank 03 survey and reconstructed Japanese Garbage 3 tails."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

BANK = Path("config/bank03_modules.json")
DOC = Path("docs/BANK_03.md")
IMPORTER = Path(".github/workflows/import-bank03-tails.yml")

EXPECTED_TARGETS = {
    "en-us-eu", "fr", "de", "it", "es",
    "jp-rev0a", "jp-revb", "jp-revc", "jp-revd",
}
EXPECTED_BANK_SHA1 = {
    "en-us-eu": "49024578d9ad3816d7acc1d921685b0daa2b79c8",
    "fr": "5770ebb30737767db418a9055aebbc04e8c2ba31",
    "de": "c0beb1a2c1646d16a4d37438e540eb5c38e25037",
    "it": "a60199353eff49c41fe0df43a48a8c286133238d",
    "es": "137f63c013ddb6579ee070b86d994f2a37a720f0",
    "jp-rev0a": "ee2db89d439248c565a52ba9caf933c9bedafa12",
    "jp-revb": "79fd893281fdb0f13861f4eae9e049d66f011bd5",
    "jp-revc": "d5f0a6223ab86f7c8fc55076404c3317213fcef1",
    "jp-revd": "125942c06a0b9ed70fb2d150f8b5d550475c4053",
}
EXPECTED_MODULES = [
    "engine/joypad.asm",
    "engine/overworld/clear_variables.asm",
    "engine/overworld/player_state.asm",
    "engine/events/poison.asm",
    "engine/overworld/tilesets.asm",
    "engine/overworld/daycare_exp.asm",
    "data/maps/toggleable_objects.asm",
    "engine/overworld/wild_mons.asm",
    "engine/items/item_effects.asm",
    "engine/menus/draw_badges.asm",
    "engine/overworld/update_map.asm",
    "engine/overworld/cut.asm",
    "engine/overworld/toggleable_objects.asm",
    "engine/overworld/push_boulder.asm",
    "engine/pokemon/add_mon.asm",
    "engine/flag_action.asm",
    "engine/events/heal_party.asm",
    "engine/math/bcd.asm",
    "engine/movie/oak_speech/init_player_data.asm",
    "engine/items/get_bag_item_quantity.asm",
    "engine/overworld/pathfinding.asm",
    "engine/gfx/hp_bar.asm",
    "engine/events/hidden_events/bookshelves.asm",
    "engine/events/hidden_events/indigo_plateau_statues.asm",
    "engine/events/hidden_events/book_or_sculpture.asm",
    "engine/events/hidden_events/elevator.asm",
    "engine/events/hidden_events/town_map.asm",
    "engine/events/hidden_events/pokemon_stuff.asm",
]
TAILS = {
    "jp-rev0a": {
        "path": Path("data/garbage/jp/rev0a/bank03_tail.asm"),
        "length": 464,
        "raw_sha1": "79ac92a4cee3c1b9ed0d8a472aaa50dadf618085",
        "git_blob_sha1": "d20b7466490d31a6b1203562c277fc3ba93f065c",
    },
    "jp-revb": {
        "path": Path("data/garbage/jp/revb/bank03_tail.asm"),
        "length": 473,
        "raw_sha1": "54ba5ff8ca15bd7930827b1f8ee1b358d70cb97d",
        "git_blob_sha1": "c68d8247633afa84ce53c4a82a18bdd2df725787",
    },
    "jp-revc": {
        "path": Path("data/garbage/jp/revc/bank03_tail.asm"),
        "length": 473,
        "raw_sha1": "137053b3679654889b17fd5f0c42fd906fabc76b",
        "git_blob_sha1": "1b8ccc4a797481fee0c25b9709d419357764bcee",
    },
}
DB_BYTE = re.compile(r"\$([0-9a-fA-F]{2})(?![0-9a-fA-F])")


def fail(message: str) -> None:
    raise SystemExit(f"Bank 03 check FAILED: {message}")


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
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()


def main() -> None:
    for path in (BANK, DOC):
        if not path.is_file():
            fail(f"missing {path}")
    if IMPORTER.exists():
        fail("one-shot Bank 03 importer must be removed after source import")

    bank = json.loads(BANK.read_text(encoding="utf-8"))

    if bank.get("bank") != "03" or bank.get("range") != "0xc000-0xffff":
        fail("unexpected bank identity or range")
    if bank.get("status") != "survey-complete":
        fail("survey status is not survey-complete")
    if bank.get("source_reconstruction_complete") is not False:
        fail("source reconstruction must not be claimed complete yet")
    if bank.get("byte_perfect_rebuild_claim") is not False:
        fail("byte-perfect rebuild must not be claimed yet")

    layout = bank.get("layout_crosscheck", {})
    if layout.get("section_order_identical") is not True:
        fail("JP/international logical section order is not marked identical")
    if layout.get("module_count") != 28:
        fail("Bank 03 module count must be 28")
    if layout.get("modules") != EXPECTED_MODULES:
        fail("Bank 03 canonical module order changed")

    hashes = bank.get("bank_sha1", {})
    if set(hashes) != EXPECTED_TARGETS:
        fail("Bank 03 hash target set is incomplete")
    if hashes != EXPECTED_BANK_SHA1:
        fail("one or more Bank 03 target SHA-1 values changed")

    jp = bank.get("japanese_revision_analysis", {})
    if jp.get("jp-rev0a", {}).get("active_range") != "0xc000-0xfe2f":
        fail("JP Rev 0A active range changed")
    if jp.get("jp-rev0a", {}).get("size_delta_vs_rev1_plus") != 9:
        fail("JP Rev 0A must remain 9 bytes longer than Rev B/C/D")
    if jp.get("jp-revc", {}).get("active_payload_identical_to_jp_revb") is not True:
        fail("JP Rev B/C active payload identity is not asserted")

    revd = jp.get("jp-revd", {})
    if revd.get("active_differences_vs_jp_revb_revc") != 1:
        fail("JP Rev D must have exactly one active byte difference vs Rev B/C")
    diff = revd.get("difference", {})
    if diff.get("physical_offset") != "0xfd06":
        fail("JP Rev D relocation offset changed")
    if diff.get("jp-revb_revc") != "0xf3" or diff.get("jp-revd") != "0xfa":
        fail("JP Rev D relocation byte values changed")
    if diff.get("classification") != "external-symbol relocation only":
        fail("JP Rev D difference is no longer classified as relocation-only")
    if diff.get("source_site") != "engine/events/hidden_events/bookshelves.asm farjp PrintCardKeyText":
        fail("JP Rev D relocation source site changed")

    garbage = bank.get("garbage_3", {})
    for rev, expected in TAILS.items():
        entry = garbage.get(rev, {})
        if entry.get("present") is not True:
            fail(f"{rev} Garbage 3 must be present")
        if entry.get("length") != expected["length"]:
            fail(f"{rev} Garbage 3 length metadata mismatch")
        if entry.get("source") != str(expected["path"]):
            fail(f"{rev} Garbage 3 source path mismatch")
        if entry.get("raw_sha1") != expected["raw_sha1"]:
            fail(f"{rev} Garbage 3 raw SHA-1 metadata mismatch")
        if entry.get("git_blob_sha1") != expected["git_blob_sha1"]:
            fail(f"{rev} Garbage 3 public blob SHA-1 metadata mismatch")

        data = parse_db_bytes(expected["path"])
        if len(data) != expected["length"]:
            fail(f"{rev} tail source emits {len(data)} bytes instead of {expected['length']}")
        raw = hashlib.sha1(data).hexdigest()
        if raw != expected["raw_sha1"]:
            fail(f"{rev} tail raw SHA-1 mismatch: {raw}")
        blob = git_blob_sha1(data)
        if blob != expected["git_blob_sha1"]:
            fail(f"{rev} tail Git blob SHA-1 mismatch: {blob}")

    revd_tail = garbage.get("jp-revd", {})
    if revd_tail.get("present") is not False:
        fail("JP Rev D must not contain Garbage 3")
    if revd_tail.get("length") != 473:
        fail("JP Rev D zero tail length must be 473")
    zero_tail_sha1 = hashlib.sha1(bytes(473)).hexdigest()
    if zero_tail_sha1 != "693e31dc362426bc4d7a6b2954f7c80267476d66":
        fail("internal zero-tail SHA-1 calculation mismatch")
    if revd_tail.get("raw_sha1_of_zero_tail") != zero_tail_sha1:
        fail("JP Rev D zero-tail SHA-1 metadata mismatch")

    doc = DOC.read_text(encoding="utf-8")
    required_doc_tokens = (
        "28 top-level modules",
        "0xFE30-0xFFFF",
        "0xFE27-0xFFFF",
        "PrintCardKeyText",
        "external-symbol relocation",
        "last non-zero byte is not a source-section boundary",
    )
    for token in required_doc_tokens:
        if token not in doc:
            fail(f"documentation is missing required evidence token: {token!r}")

    print(
        "Bank 03 check passed: nine target hashes, 28-module layout, JP Rev 0A +9-byte "
        "joypad delta, Rev D relocation-only byte, and three Garbage 3 ASM tails verified."
    )


if __name__ == "__main__":
    main()
