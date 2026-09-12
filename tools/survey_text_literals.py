#!/usr/bin/env python3
"""Survey the international-family Bank 00 text-engine literal block.

This tool is read-only. It never writes or copies ROM data into the repository.
It locates the unique `PC@` anchor in ROM0, then prints the following eight
terminated literals as offsets, raw bytes, and a conservative decoded form.

Usage:
    python3 tools/survey_text_literals.py ROM [ROM ...]

The decoder intentionally maps only stable cross-locale characters. Bytes that
may be locale-specific are emitted as `<XX>` so they can be verified against the
release-specific character table instead of silently mis-decoded.
"""

from __future__ import annotations

import argparse
from pathlib import Path

BANK_SIZE = 0x4000
TERMINATOR = 0x50
PC_ANCHOR = bytes((0x8F, 0x82, TERMINATOR))
LITERAL_COUNT = 8

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


def decode_stable(data: bytes) -> str:
    return "".join(STABLE_CHARS.get(value, f"<{value:02X}>") for value in data)


def find_unique(haystack: bytes, needle: bytes) -> int:
    offsets: list[int] = []
    start = 0
    while True:
        found = haystack.find(needle, start)
        if found < 0:
            break
        offsets.append(found)
        start = found + 1
    if len(offsets) != 1:
        rendered = ", ".join(f"0x{x:04x}" for x in offsets) or "none"
        raise ValueError(f"expected one PC@ anchor, found {len(offsets)}: {rendered}")
    return offsets[0]


def read_terminated(data: bytes, start: int) -> tuple[bytes, int]:
    end = data.find(bytes((TERMINATOR,)), start)
    if end < 0:
        raise ValueError(f"unterminated literal beginning at 0x{start:04x}")
    end += 1
    return data[start:end], end


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", nargs="+", type=Path)
    args = parser.parse_args()

    for path in args.rom:
        rom = path.read_bytes()
        if len(rom) < BANK_SIZE:
            raise SystemExit(f"{path}: file is smaller than one ROM bank")
        bank0 = rom[:BANK_SIZE]

        try:
            cursor = find_unique(bank0, PC_ANCHOR)
        except ValueError as exc:
            print(f"[{path.name}] {exc}")
            continue

        block_start = cursor
        rows: list[tuple[int, int, bytes]] = []
        for _ in range(LITERAL_COUNT):
            literal, next_cursor = read_terminated(bank0, cursor)
            rows.append((cursor, next_cursor, literal))
            cursor = next_cursor

        print(f"[{path.name}]")
        print(f"literal_block=0x{block_start:04x}-0x{cursor - 1:04x}")
        for index, (start, end, literal) in enumerate(rows):
            print(
                f"{index}: 0x{start:04x}-0x{end - 1:04x}  "
                f"{literal.hex(' ')}  {decode_stable(literal)}"
            )
        print()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
