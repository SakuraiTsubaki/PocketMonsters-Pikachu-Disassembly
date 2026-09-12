#!/usr/bin/env python3
"""Survey Bank 01 ($4000-$7fff) across verified Yellow reference ROMs.

The tool is read-only. It identifies each ROM by the SHA-1 values in
config/releases.json, prints the Bank 01 SHA-1, and reports pairwise byte
counts. No ROM bytes are copied into the repository.

Usage:
    python3 tools/survey_bank01.py ROM [ROM ...]
"""

from __future__ import annotations

import argparse
import hashlib
import itertools
import json
from pathlib import Path

BANK_SIZE = 0x4000
BANK_INDEX = 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", nargs="+", type=Path)
    args = parser.parse_args()

    releases = json.loads(Path("config/releases.json").read_text(encoding="utf-8"))
    by_sha1 = {r["sha1"]: r["id"] for r in releases["releases"]}
    banks: dict[str, bytes] = {}
    failed = False

    for path in args.rom:
        rom = path.read_bytes()
        whole_sha1 = hashlib.sha1(rom).hexdigest()
        release_id = by_sha1.get(whole_sha1)
        if release_id is None:
            print(f"[{path.name}] unknown SHA-1 {whole_sha1}")
            failed = True
            continue
        start = BANK_INDEX * BANK_SIZE
        end = start + BANK_SIZE
        if len(rom) < end:
            print(f"[{path.name}] ROM too small for Bank 01")
            failed = True
            continue
        bank = rom[start:end]
        banks[release_id] = bank
        print(f"{release_id:10} bank01_sha1={hashlib.sha1(bank).hexdigest()}")

    if len(banks) > 1:
        print("\npairwise_differing_bytes:")
        for left, right in itertools.combinations(sorted(banks), 2):
            count = sum(a != b for a, b in zip(banks[left], banks[right]))
            print(f"{left:10} {right:10} {count:5}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
