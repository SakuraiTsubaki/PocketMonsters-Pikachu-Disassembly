#!/usr/bin/env python3
"""Repository policy checks for the disassembly project.

Fails if a ROM image is tracked or if assembler source directly depends on a
local base/reference ROM through INCBIN. Reconstructed repository-owned binary
assets are allowed. Documentation may describe forbidden patterns without being
mistaken for an executable dependency.
"""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys

ROM_SUFFIXES = {
    ".gb", ".gbc", ".gba", ".nds", ".3ds", ".cia", ".xci", ".nsp"
}
ASSEMBLY_SUFFIXES = {".asm", ".inc"}
BASEROM_INCBIN = re.compile(
    r"\bINCBIN\b[^\n]*(?:baserom|base_rom|base-rom|reference-rom|reference_rom)",
    re.IGNORECASE,
)


def tracked_files() -> list[pathlib.Path]:
    out = subprocess.check_output(["git", "ls-files", "-z"])
    return [pathlib.Path(p.decode("utf-8")) for p in out.split(b"\0") if p]


def main() -> int:
    files = tracked_files()
    errors: list[str] = []

    for path in files:
        if path.suffix.lower() in ROM_SUFFIXES:
            errors.append(f"tracked ROM image: {path}")
            continue

        # INCBIN is an assembler directive. Restrict this check to assembler
        # sources so README/docs can explain the forbidden pattern verbatim.
        if path.suffix.lower() not in ASSEMBLY_SUFFIXES:
            continue

        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue

        if BASEROM_INCBIN.search(text):
            errors.append(f"direct base-ROM INCBIN dependency: {path}")

    if errors:
        print("Repository policy check FAILED:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(f"Repository policy check passed ({len(files)} tracked files checked).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
