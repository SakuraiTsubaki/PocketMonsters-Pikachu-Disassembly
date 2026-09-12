#!/usr/bin/env python3
"""Verify Bank 00 text-engine literal blocks for all nine Yellow targets.

This tool is read-only. It identifies a reference ROM by SHA-1 using
`config/releases.json`, reads the exact locale/revision block range declared in
`config/text_locale_matrix.json`, and verifies every literal byte sequence.

Usage:
    python3 tools/survey_text_literals.py ROM [ROM ...]
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

BANK_SIZE = 0x4000
TERMINATOR = 0x50
REPO_ROOT = Path(__file__).resolve().parents[1]
RELEASES_PATH = REPO_ROOT / "config" / "releases.json"
TEXT_MATRIX_PATH = REPO_ROOT / "config" / "text_locale_matrix.json"

STABLE_CHARS: dict[int, str] = {
    TERMINATOR: "@",
    0x75: "…",
    0x7F: " ",
    0xE0: "'",
    0xE1: "<PK>",
    0xE2: "<MN>",
    0xE3: "-",
    0xE6: "?",
    0xE7: "!",
    0xE8: ".",
    0xF3: "/",
    0xF4: ",",
}
for value, char in enumerate("ABCDEFGHIJKLMNOPQRSTUVWXYZ", start=0x80):
    STABLE_CHARS[value] = char
for value, char in enumerate("abcdefghijklmnopqrstuvwxyz", start=0xA0):
    STABLE_CHARS[value] = char
for value, char in enumerate("0123456789", start=0xF6):
    STABLE_CHARS[value] = char


def sha1(data: bytes) -> str:
    return hashlib.sha1(data).hexdigest()


def decode_stable(data: bytes) -> str:
    return "".join(STABLE_CHARS.get(value, f"<{value:02X}>") for value in data)


def parse_range(text: str) -> tuple[int, int]:
    first, last = text.split("-", 1)
    return int(first, 16), int(last, 16)


def split_terminated(block: bytes, base: int) -> list[tuple[int, int, bytes]]:
    rows: list[tuple[int, int, bytes]] = []
    cursor = 0
    while cursor < len(block):
        end = block.find(bytes((TERMINATOR,)), cursor)
        if end < 0:
            raise ValueError(f"unterminated data at ROM0 offset 0x{base + cursor:04x}")
        end += 1
        rows.append((base + cursor, base + end - 1, block[cursor:end]))
        cursor = end
    return rows


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def profile_for_release(matrix: dict, release_id: str) -> tuple[dict, str]:
    if release_id.startswith("jp-"):
        profile = matrix["locale_literals"]["jp"]
        return profile, profile["revision_ranges"][release_id]
    profile = matrix["locale_literals"][release_id]
    return profile, profile["literal_block_range"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", nargs="+", type=Path)
    args = parser.parse_args()

    releases = load_json(RELEASES_PATH)
    matrix = load_json(TEXT_MATRIX_PATH)
    by_sha1 = {release["sha1"]: release for release in releases["releases"]}

    failures = 0

    for path in args.rom:
        rom = path.read_bytes()
        digest = sha1(rom)
        release = by_sha1.get(digest)
        print(f"[{path.name}]")
        print(f"sha1={digest}")

        if release is None:
            print("status=UNKNOWN_RELEASE\n")
            failures += 1
            continue

        release_id = release["id"]
        print(f"release={release_id}")
        if len(rom) < BANK_SIZE:
            print("status=ROM_TOO_SMALL\n")
            failures += 1
            continue

        try:
            profile, range_text = profile_for_release(matrix, release_id)
        except KeyError:
            print("status=NO_LITERAL_PROFILE\n")
            failures += 1
            continue

        start, last = parse_range(range_text)
        block = rom[start:last + 1]
        try:
            rows = split_terminated(block, start)
        except ValueError as exc:
            print(f"status=PARSE_ERROR error={exc}\n")
            failures += 1
            continue

        order = profile["literal_order"]
        if len(rows) != len(order):
            print(f"status=LITERAL_COUNT_MISMATCH expected={len(order)} actual={len(rows)}\n")
            failures += 1
            continue

        release_ok = True
        for label, (row_start, row_last, raw) in zip(order, rows):
            expected = bytes.fromhex(profile["raw_literals"][label])
            ok = raw == expected
            release_ok &= ok
            expected_text = profile.get(label, label)
            decoded = expected_text + "@" if ok else decode_stable(raw)
            print(
                f"{label}: 0x{row_start:04x}-0x{row_last:04x} "
                f"{'OK' if ok else 'MISMATCH'}  {raw.hex(' ')}  "
                f"{decoded}"
            )

        if release_id == "en-us-eu":
            poke = bytes.fromhex(profile["raw_literals"]["poke"])
            print(f"poke_e_acute_byte=0x{poke[-2]:02x} family=english")
        elif release_id in {"fr", "de", "it", "es"}:
            poke = bytes.fromhex(profile["raw_literals"]["poke"])
            print(f"poke_e_acute_byte=0x{poke[-2]:02x} family=localized-international")

        print(f"status={'PASS' if release_ok else 'FAIL'}\n")
        if not release_ok:
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
