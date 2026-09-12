#!/usr/bin/env python3
"""Survey ROM0 (bank 00) without committing or modifying ROM images.

Usage:
    python3 tools/survey_bank00.py ROM [ROM ...]

The script prints hashes, cartridge-header fields, vector bytes, entry points,
and pairwise Bank 00 difference counts. It is intentionally read-only.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
from itertools import combinations

BANK_SIZE = 0x4000
VECTOR_ADDRS = (0x0000, 0x0008, 0x0010, 0x0018, 0x0020, 0x0028,
                0x0030, 0x0038, 0x0040, 0x0048, 0x0050, 0x0058, 0x0060)


def digest(data: bytes, name: str) -> str:
    h = hashlib.new(name)
    h.update(data)
    return h.hexdigest()


def diff_ranges(a: bytes, b: bytes):
    offsets = [i for i, (x, y) in enumerate(zip(a, b)) if x != y]
    if not offsets:
        return []
    out = []
    start = prev = offsets[0]
    for off in offsets[1:]:
        if off == prev + 1:
            prev = off
            continue
        out.append((start, prev))
        start = prev = off
    out.append((start, prev))
    return out


def header_info(rom: bytes) -> dict[str, str | int]:
    title_raw = rom[0x134:0x144]
    title = title_raw.rstrip(b"\0").decode("latin-1", errors="replace")
    return {
        "title": title,
        "cgb_flag": f"0x{rom[0x143]:02x}",
        "sgb_flag": f"0x{rom[0x146]:02x}",
        "cartridge_type": f"0x{rom[0x147]:02x}",
        "rom_size": f"0x{rom[0x148]:02x}",
        "ram_size": f"0x{rom[0x149]:02x}",
        "destination": f"0x{rom[0x14a]:02x}",
        "version": f"0x{rom[0x14c]:02x}",
        "header_checksum": f"0x{rom[0x14d]:02x}",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("rom", nargs="+", type=Path)
    args = ap.parse_args()

    images: dict[str, bytes] = {}
    for path in args.rom:
        data = path.read_bytes()
        if len(data) < BANK_SIZE:
            raise SystemExit(f"{path}: smaller than one 16 KiB ROM bank")
        images[path.name] = data

    for name, rom in images.items():
        bank0 = rom[:BANK_SIZE]
        print(f"[{name}]")
        print(f"size={len(rom)} sha1={digest(rom, 'sha1')}")
        print(f"bank00_sha1={digest(bank0, 'sha1')}")
        print("header=" + repr(header_info(rom)))
        for addr in VECTOR_ADDRS:
            print(f"{addr:04x}: {rom[addr:addr + 8].hex(' ')}")
        entry = rom[0x100:0x104]
        if entry[0] == 0x00 and entry[1] == 0xC3:
            target = int.from_bytes(entry[2:4], "little")
            print(f"entry_target=0x{target:04x}")
        print()

    print("[pairwise Bank 00 differences]")
    for (name_a, rom_a), (name_b, rom_b) in combinations(images.items(), 2):
        ranges = diff_ranges(rom_a[:BANK_SIZE], rom_b[:BANK_SIZE])
        differing = sum(end - start + 1 for start, end in ranges)
        print(f"{name_a} <> {name_b}: {differing} bytes / {len(ranges)} ranges")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
