#!/usr/bin/env python3
"""Validate the reconstructed Bank 01 source inventory.

This is intentionally a source-structure check, not a byte-perfect ROM build
claim. Full RGBDS per-release assembly/diff validation is a later integration
step.
"""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "config" / "bank01_modules.json"
BANK_SOURCE = ROOT / "banks" / "bank01.asm"
MATRICES = (
    ROOT / "config" / "cable_club_family_matrix.json",
    ROOT / "config" / "naming_screen_family_matrix.json",
    ROOT / "config" / "text_box_family_matrix.json",
)
INCLUDE_RE = re.compile(r'^\s*INCLUDE\s+"([^"]+)"')
FORBIDDEN_ROM_REF_RE = re.compile(
    r'(?i)(?:baserom|reference_rom|source_rom).*\.(?:gb|gbc)|INCBIN\s+"[^"]*\.(?:gb|gbc)"'
)


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def fail(message: str) -> None:
    raise SystemExit(f"bank01-check: ERROR: {message}")


def main() -> None:
    manifest = load_json(MANIFEST)
    modules = manifest.get("modules", [])
    summary = manifest.get("summary", {})

    if manifest.get("bank") != "01":
        fail("config/bank01_modules.json does not describe Bank 01")
    if summary.get("module_count") != len(modules):
        fail(
            f"module_count={summary.get('module_count')} but manifest has {len(modules)} entries"
        )
    if summary.get("pending_source_modules") != 0:
        fail("Bank 01 still reports pending source modules")

    module_paths = [entry["path"] for entry in modules]
    if len(set(module_paths)) != len(module_paths):
        fail("duplicate module paths in config/bank01_modules.json")

    missing = [path for path in module_paths if not (ROOT / path).is_file()]
    if missing:
        fail("missing reconstructed module(s): " + ", ".join(missing))

    bank_text = BANK_SOURCE.read_text(encoding="utf-8")
    include_paths = [
        match.group(1)
        for line in bank_text.splitlines()
        if (match := INCLUDE_RE.match(line))
    ]
    if include_paths != module_paths:
        fail(
            "banks/bank01.asm include order differs from config/bank01_modules.json"
        )

    for matrix in MATRICES:
        data = load_json(matrix)
        if data.get("bank") != "01":
            fail(f"{matrix.relative_to(ROOT)} is not marked as Bank 01")
        if data.get("status") != "source-reconstructed":
            fail(
                f"{matrix.relative_to(ROOT)} status is {data.get('status')!r}, "
                "expected 'source-reconstructed'"
            )

    forbidden_hits: list[str] = []
    for relpath in module_paths:
        text = (ROOT / relpath).read_text(encoding="utf-8")
        if FORBIDDEN_ROM_REF_RE.search(text):
            forbidden_hits.append(relpath)
    if forbidden_hits:
        fail(
            "Bank 01 source contains forbidden base/reference-ROM dependency: "
            + ", ".join(forbidden_hits)
        )

    print(
        "bank01-check: OK — "
        f"{len(module_paths)} modules present, include order matches, "
        "family matrices are source-reconstructed, no base-ROM dependency found."
    )
    print(
        "bank01-check: NOTE — byte-perfect RGBDS assembly/diff validation is still pending."
    )


if __name__ == "__main__":
    main()
