#!/usr/bin/env python3
"""Verify international-family Bank 00 text-engine literal blocks.

This tool is read-only. It identifies a reference ROM by SHA-1 using
`config/releases.json`, reads the exact locale block range declared in
`config/text_locale_matrix.json`, and verifies every literal byte sequence.

Usage:
    python3 tools/survey_text_literals.py ROM [ROM ...]

Japanese text rendering is structurally different and is intentionally handled
by a separate survey rather than forcing it through the international parser.
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
        if release_id.startswith("jp-"):
            print("status=SKIP_JAPANESE_TEXT_FAMILY\n")
            continue

        locale = matrix["locale_literals"].get(release_id)
        if not locale or "literal_block_range" not in locale:
            print("status=NO_LITERAL_PROFILE\n")
            failures += 1
            continue

        if len(rom) < BANK_SIZE:
            print("status=ROM_TOO_SMALL\n")
            failures += 1
            continue

        start, last = parse_range(locale["literal_block_range"])
        block = rom[start:last + 1]
        rows = split_terminated(block, start)
        order = locale["literal_order"]

        if len(rows) != len(order):
            print(f"status=LITERAL_COUNT_MISMATCH expected={len(order)} actual={len(rows)}\n")
            failures += 1
            continue

        release_ok = True
        for label, (row_start, row_last, raw) in zip(order, rows):
            expected_hex = locale["raw_literals"][label]
            expected = bytes.fromhex(expected_hex)
            ok = raw == expected
            release_ok &= ok
            expected_text = locale.get(label, label)
            print(
                f"{label}: 0x{row_start:04x}-0x{row_last:04x} "
                f"{'OK' if ok else 'MISMATCH'}  {raw.hex(' ')}  "
                f"{decode_stable(raw)}  expected={expected_text!r}"
            )

        if release_id != "en-us-eu":
            poke = bytes.fromhex(locale["raw_literals"]["poke"])
            print(f"localized_poke_e_acute_byte=0x{poke[-2]:02x}")
        else:
            poke = bytes.fromhex(locale["raw_literals"]["poke"])
            print(f"english_poke_e_acute_byte=0x{poke[-2]:02x}")

        print(f"status={'PASS' if release_ok else 'FAIL'}\n")
        if not release_ok:
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
