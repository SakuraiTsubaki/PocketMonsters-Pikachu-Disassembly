#!/usr/bin/env python3
"""Validate Bank 04 source population, family merges, placement wiring, and provenance."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

BANK = Path("config/bank04_modules.json")
INVENTORY = Path("config/bank04_source_inventory.json")
SAFETY = Path("config/bank04_variant_safety.json")
MERGED = Path("config/bank04_merged_source_manifest.json")
ENTRYPOINT = Path("banks/bank04.asm")

ONE_SHOT_WORKFLOWS = (
    Path(".github/workflows/audit-bank04-sources.yml"),
    Path(".github/workflows/refine-bank04-safe-variants.yml"),
)


def fail(message: str) -> None:
    raise SystemExit(f"Bank 04 source check FAILED: {message}")


def raw_sha1(data: bytes) -> str:
    return hashlib.sha1(data).hexdigest()


def git_blob_sha1(data: bytes) -> str:
    return hashlib.sha1(f"blob {len(data)}\0".encode("ascii") + data).hexdigest()


def load(path: Path) -> dict:
    if not path.is_file():
        fail(f"missing {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    bank = load(BANK)
    inventory = load(INVENTORY)
    safety = load(SAFETY)
    merged = load(MERGED)

    if bank.get("source_reconstruction_complete") is not False:
        fail("Bank 04 must not claim linked source reconstruction complete yet")
    if bank.get("byte_perfect_rebuild_claim") is not False:
        fail("Bank 04 must not claim byte-perfect rebuild yet")
    if inventory.get("source_reconstruction_complete") is not False:
        fail("inventory must not claim source reconstruction complete")
    if merged.get("source_reconstruction_complete") is not False:
        fail("merged manifest must not claim source reconstruction complete")
    if merged.get("byte_perfect_rebuild_claim") is not False:
        fail("merged manifest must not claim byte-perfect rebuild")

    for workflow in ONE_SHOT_WORKFLOWS:
        if workflow.exists():
            fail(f"one-shot workflow still tracked after Bank 04 import: {workflow}")

    layout = bank.get("layout_crosscheck", {})
    intl_sections = layout.get("international_reference", {}).get("sections", {})
    jp_sections = layout.get("japanese_reference", {}).get("sections", {})
    intl_modules = intl_sections.get("bank4", []) + intl_sections.get("Battle Engine 1", [])
    jp_modules = jp_sections.get("bank4", []) + jp_sections.get("Battle Engine 1", [])
    unique_modules = list(dict.fromkeys(intl_modules + jp_modules))

    if len(intl_modules) != 11:
        fail(f"expected 11 international Bank 04 modules, got {len(intl_modules)}")
    if len(jp_modules) != 14:
        fail(f"expected 14 Japanese Bank 04 modules, got {len(jp_modules)}")
    if len(unique_modules) != 14:
        fail(f"expected 14 unique Bank 04 source paths, got {len(unique_modules)}")
    if layout.get("logical_layout_identical") is not False:
        fail("family-specific Bank 04 placement must remain explicit")

    records = {m["path"]: m for m in inventory.get("modules", [])}
    if set(records) != set(unique_modules):
        fail("source inventory does not cover exactly the 14 Bank 04 source paths")

    exact = {p for p, r in records.items() if r.get("classification") == "exact-shared"}
    cosmetic = {p for p, r in records.items() if r.get("classification") == "cosmetic-only"}
    substantive = {p for p, r in records.items() if r.get("classification") == "substantive"}
    if (len(exact), len(cosmetic), len(substantive)) != (4, 1, 9):
        fail(
            "expected source classes 4 exact + 1 cosmetic + 9 substantive, got "
            f"{len(exact)} + {len(cosmetic)} + {len(substantive)}"
        )
    if exact & cosmetic or exact & substantive or cosmetic & substantive:
        fail("Bank 04 source classes overlap")
    if exact | cosmetic | substantive != set(unique_modules):
        fail("Bank 04 source classes do not cover all unique modules")

    for path in sorted(exact):
        source = Path(path)
        if not source.is_file():
            fail(f"missing exact-shared source {path}")
        data = source.read_bytes()
        rec = records[path]
        if rec.get("international_git_blob_sha1") != rec.get("japanese_git_blob_sha1"):
            fail(f"exact-shared upstream blobs disagree for {path}")
        if git_blob_sha1(data) != rec.get("international_git_blob_sha1"):
            fail(f"exact-shared source changed: {path}")

    for path in sorted(cosmetic):
        source = Path(path)
        if not source.is_file():
            fail(f"missing cosmetic-normalized source {path}")
        if raw_sha1(source.read_bytes()) != records[path].get("international_raw_sha1"):
            fail(f"cosmetic-normalized source changed: {path}")

    if safety.get("substantive_module_count") != 9:
        fail("safety manifest substantive count must be 9")
    if safety.get("safe_count") != 9 or safety.get("manual_count") != 0:
        fail("all nine substantive modules must remain automatic-merge safe")
    if set(safety.get("safe_paths", [])) != substantive:
        fail("safety manifest safe path set changed")
    if safety.get("manual_paths") != []:
        fail("Bank 04 must have no manual-pending substantive paths")
    for rec in safety.get("modules", []):
        if rec.get("path") not in substantive:
            fail(f"unexpected safety record: {rec.get('path')}")
        if rec.get("safe_for_automatic_line_merge") is not True:
            fail(f"substantive source no longer marked safe: {rec.get('path')}")
        if rec.get("changed_opcode_directive_hit_count") != 0:
            fail(f"changed RGBDS directive detected in safety record: {rec.get('path')}")
        if rec.get("generated_conditionals_balanced") is not True:
            fail(f"generated conditional stack no longer balanced: {rec.get('path')}")

    merged_records = {m["path"]: m for m in merged.get("modules", [])}
    if set(merged_records) != substantive:
        fail("merged manifest does not cover exactly the nine substantive modules")
    if merged.get("safe_fine_grained_count") != 9:
        fail("merged manifest fine-grained count must be 9")
    if merged.get("manual_pending_count") != 0 or merged.get("manual_pending_paths") != []:
        fail("merged manifest must have no manual-pending modules")

    for path in sorted(substantive):
        source = Path(path)
        if not source.is_file():
            fail(f"missing fine-grained source {path}")
        data = source.read_bytes()
        rec = merged_records[path]
        inv = records[path]
        if rec.get("strategy") != "fine-grained-family-conditional":
            fail(f"unexpected substantive merge strategy for {path}: {rec.get('strategy')}")
        if rec.get("automatic_merge_safety_verified") is not True:
            fail(f"automatic merge safety not verified for {path}")
        if rec.get("branch_source_reconstruction_verified") is not True:
            fail(f"branch source reconstruction not verified for {path}")
        if rec.get("international_raw_sha1") != inv.get("international_raw_sha1"):
            fail(f"international provenance mismatch for {path}")
        if rec.get("japanese_raw_sha1") != inv.get("japanese_raw_sha1"):
            fail(f"Japanese provenance mismatch for {path}")
        if raw_sha1(data) != rec.get("merged_raw_sha1"):
            fail(f"merged raw SHA-1 changed: {path}")
        if git_blob_sha1(data) != rec.get("merged_git_blob_sha1"):
            fail(f"merged Git blob SHA-1 changed: {path}")
        if len(data) != rec.get("merged_length"):
            fail(f"merged source length changed: {path}")
        text = data.decode("utf-8")
        if "IF DEF(_JAPAN)" not in text or "ELSE" not in text or "ENDC" not in text:
            fail(f"fine-grained family selector missing: {path}")

    if not ENTRYPOINT.is_file():
        fail("missing banks/bank04.asm")
    entry = ENTRYPOINT.read_text(encoding="utf-8")
    required_entry_tokens = (
        'SECTION "bank4", ROMX[$4000], BANK[$4]',
        'SECTION "Battle Engine 1", ROMX, BANK[$4]',
        'IF DEF(_JAPAN)\nINCLUDE "data/moves/names.asm"\nENDC',
        'IF DEF(_JAPAN)\nINCLUDE "engine/overworld/is_player_just_outside_map.asm"\nENDC',
        'IF DEF(_JAPAN)\nINCLUDE "engine/overworld/npc_movement_2.asm"\nENDC',
        'SECTION "Garbage 4 Rev 0A", ROMX[$7FC2], BANK[$4]',
        'INCLUDE "data/garbage/jp/rev0a/bank04_tail.asm"',
        'SECTION "Garbage 4 Rev B", ROMX[$7FC2], BANK[$4]',
        'INCLUDE "data/garbage/jp/revb/bank04_tail.asm"',
        'SECTION "Garbage 4 Rev C", ROMX[$7FC2], BANK[$4]',
        'INCLUDE "data/garbage/jp/revc/bank04_tail.asm"',
    )
    for token in required_entry_tokens:
        if token not in entry:
            fail(f"Bank 04 entrypoint missing token: {token}")
    if 'data/garbage/jp/revd/bank04_tail.asm' in entry:
        fail("JP Rev D must use zero fill rather than a Garbage 4 source")

    # Every unique top-level module appears exactly once in the Bank 04 entrypoint;
    # Japanese-only placement is controlled by the three _JAPAN wrappers above.
    for path in unique_modules:
        needle = f'INCLUDE "{path}"'
        if entry.count(needle) != 1:
            fail(f"Bank 04 entrypoint must include {path} exactly once")

    # Preserve source order inside each logical section. JP-only modules are allowed
    # between common modules, but the complete Japanese order must remain monotonic.
    positions = {p: entry.index(f'INCLUDE "{p}"') for p in unique_modules}
    for family, modules in (("international", intl_modules), ("Japanese", jp_modules)):
        ordered = [positions[p] for p in modules]
        if ordered != sorted(ordered):
            fail(f"{family} Bank 04 module order changed")

    print(
        "Bank 04 source check passed: 14/14 unique sources present "
        "(4 exact shared + 1 cosmetic-normalized + 9 fine-grained), "
        "INT 11-module and JP 14-module placement order intact, provenance intact, "
        "and JP Rev 0A/B/C Garbage 4 wiring fixed at $7FC2."
    )


if __name__ == "__main__":
    main()
