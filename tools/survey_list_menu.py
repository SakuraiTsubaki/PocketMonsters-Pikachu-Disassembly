#!/usr/bin/env python3
"""Verify Bank 00 list-menu locale evidence from local Yellow ROMs.

The tool is read-only and never copies ROM bytes into the repository. It
identifies a reference release by SHA-1, then checks the release-specific
quantity/cancel anchors and currency-rendering opcodes recorded during the
Bank 00 reconstruction.

Usage:
    python3 tools/survey_list_menu.py ROM [ROM ...]
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

BANK_SIZE = 0x4000
QUANTITY = bytes.fromhex("f1 f6 f7 50")

CANCEL_RAW = {
    "en-us-eu": bytes.fromhex("82 80 8d 82 84 8b 50"),
    "fr": bytes.fromhex("91 84 93 8e 94 91 50"),
    "de": bytes.fromhex("99 94 91 c2 82 8a 50"),
    "it": bytes.fromhex("84 92 82 88 50"),
    "es": bytes.fromhex("92 80 8b 88 91 50"),
    "jp-rev0a": bytes.fromhex("d4 d2 d9 50"),
    "jp-revb": bytes.fromhex("d4 d2 d9 50"),
    "jp-revc": bytes.fromhex("d4 d2 d9 50"),
    "jp-revd": bytes.fromhex("d4 d2 d9 50"),
}


def parse_offset(value: str) -> int:
    return int(value, 16)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", nargs="+", type=Path)
    args = parser.parse_args()

    releases = json.loads(Path("config/releases.json").read_text(encoding="utf-8"))
    matrix = json.loads(Path("config/list_menu_locale_matrix.json").read_text(encoding="utf-8"))
    by_sha1 = {release["sha1"]: release["id"] for release in releases["releases"]}

    failed = False
    for path in args.rom:
        rom = path.read_bytes()
        sha1 = hashlib.sha1(rom).hexdigest()
        release_id = by_sha1.get(sha1)
        if release_id is None:
            print(f"[{path.name}] unknown SHA-1 {sha1}")
            failed = True
            continue
        if len(rom) < BANK_SIZE:
            print(f"[{path.name}] smaller than one ROM bank")
            failed = True
            continue

        bank0 = rom[:BANK_SIZE]
        expected = matrix["targets"][release_id]
        quantity_offset = parse_offset(expected["initial_quantity_offset"])
        cancel_offset = parse_offset(expected["cancel_offset"])
        cancel_raw = CANCEL_RAW[release_id]

        quantity_ok = bank0[quantity_offset : quantity_offset + len(QUANTITY)] == QUANTITY
        cancel_ok = bank0[cancel_offset : cancel_offset + len(cancel_raw)] == cancel_raw

        currency_ok = True
        family = expected["currency_family"]
        if "quantity_currency_opcode_offset" in expected:
            off = parse_offset(expected["quantity_currency_opcode_offset"])
            currency_ok &= bank0[off : off + 2] == bytes.fromhex("3e f0")
        if "list_currency_opcode_offset" in expected:
            off = parse_offset(expected["list_currency_opcode_offset"])
            currency_ok &= bank0[off : off + 2] == bytes.fromhex("36 f0")

        ok = quantity_ok and cancel_ok and currency_ok
        failed |= not ok
        state = "OK" if ok else "FAIL"
        print(
            f"[{state}] {release_id:10} sha1={sha1} "
            f"quantity=0x{quantity_offset:04x}:{quantity_ok} "
            f"cancel=0x{cancel_offset:04x}:{cancel_ok} "
            f"currency={family}:{currency_ok}"
        )

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
