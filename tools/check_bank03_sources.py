#!/usr/bin/env python3
"""Validate Bank 03 source population, provenance hashes, and bank entrypoint wiring."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

BANK = Path("config/bank03_modules.json")
INVENTORY = Path("config/bank03_source_inventory.json")
VARIANTS = Path("config/bank03_variant_analysis.json")
MERGED = Path("config/bank03_merged_source_manifest.json")
ENTRYPOINT = Path("banks/bank03.asm")

ONE_SHOT_WORKFLOWS = (
    Path(".github/workflows/audit-bank03-sources.yml"),
    Path(".github/workflows/analyze-bank03-variants.yml"),
    Path(".github/workflows/merge-bank03-family-sources.yml"),
)

ALLOWED_SUBSTANTIVE_STRATEGIES = {
    "family-whole-file-conditional",
    "fine-grained-family-conditional",
}


def fail(message: str) -> None:
    raise SystemExit(f"Bank 03 source check FAILED: {message}")


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
    variants = load(VARIANTS)
    merged = load(MERGED)

    canonical = bank.get("layout_crosscheck", {}).get("modules", [])
    if len(canonical) != 28 or len(set(canonical)) != 28:
        fail("canonical Bank 03 module list must contain 28 unique paths")

    if bank.get("source_reconstruction_complete") is not False:
        fail("source reconstruction must remain unclaimed until linked byte validation exists")
    if bank.get("byte_perfect_rebuild_claim") is not False:
        fail("byte-perfect rebuild must remain unclaimed")
    if merged.get("source_reconstruction_complete") is not False:
        fail("merged manifest must not claim source reconstruction complete")
    if merged.get("byte_perfect_rebuild_claim") is not False:
        fail("merged manifest must not claim byte-perfect rebuild")

    for workflow in ONE_SHOT_WORKFLOWS:
        if workflow.exists():
            fail(f"one-shot workflow still tracked after import: {workflow}")

    inventory_modules = {m["path"]: m for m in inventory.get("modules", [])}
    variant_modules = {m["path"]: m for m in variants.get("modules", [])}
    merged_modules = {m["path"]: m for m in merged.get("modules", [])}

    shared = {
        path for path, m in inventory_modules.items()
        if m.get("upstream_relation") == "identical"
    }
    cosmetic = {
        path for path, m in variant_modules.items()
        if m.get("classification") == "cosmetic-only"
    }
    substantive = {
        path for path, m in variant_modules.items()
        if m.get("classification") == "substantive"
    }

    if len(shared) != 10:
        fail(f"expected 10 byte-identical shared modules, got {len(shared)}")
    if len(cosmetic) != 4:
        fail(f"expected 4 cosmetic-only modules, got {len(cosmetic)}")
    if len(substantive) != 14:
        fail(f"expected 14 substantive modules, got {len(substantive)}")
    if set(merged_modules) != substantive:
        fail("merged manifest does not cover exactly the 14 substantive modules")
    if shared & cosmetic or shared & substantive or cosmetic & substantive:
        fail("Bank 03 source classes overlap")
    if shared | cosmetic | substantive != set(canonical):
        fail("Bank 03 source classes do not cover the canonical 28 modules")

    for path in sorted(shared):
        source = Path(path)
        if not source.is_file():
            fail(f"missing shared source {path}")
        data = source.read_bytes()
        actual_blob = git_blob_sha1(data)
        record = inventory_modules[path]
        intl_blob = record.get("international_git_blob_sha1")
        jp_blob = record.get("japanese_git_blob_sha1")
        if not intl_blob or intl_blob != jp_blob:
            fail(f"shared provenance hashes disagree for {path}")
        if actual_blob != intl_blob:
            fail(f"shared source blob changed: {path} -> {actual_blob}")

    for path in sorted(cosmetic):
        source = Path(path)
        if not source.is_file():
            fail(f"missing cosmetic-normalized source {path}")
        actual = raw_sha1(source.read_bytes())
        expected = variant_modules[path].get("international_raw_sha1")
        if actual != expected:
            fail(f"cosmetic-normalized source changed: {path} -> {actual}")

    whole_start = b"IF DEF(_JAPAN)\n\n"
    whole_else = b"\n\nELSE\n\n"
    whole_end = b"\n\nENDC\n"
    for path in sorted(substantive):
        source = Path(path)
        if not source.is_file():
            fail(f"missing family-conditional source {path}")
        data = source.read_bytes()
        record = merged_modules[path]
        strategy = record.get("strategy")
        if strategy not in ALLOWED_SUBSTANTIVE_STRATEGIES:
            fail(f"unexpected merge strategy for {path}: {strategy}")
        if raw_sha1(data) != record.get("merged_raw_sha1"):
            fail(f"merged raw SHA-1 changed: {path}")
        if git_blob_sha1(data) != record.get("merged_git_blob_sha1"):
            fail(f"merged Git blob SHA-1 changed: {path}")
        if len(data) != record.get("merged_length"):
            fail(f"merged source length changed: {path}")

        if strategy == "family-whole-file-conditional":
            if whole_start not in data or whole_else not in data or not data.endswith(whole_end):
                fail(f"whole-family selector wrapper damaged: {path}")
        else:
            text = data.decode("utf-8")
            if "IF DEF(_JAPAN)" not in text or "ELSE" not in text or "ENDC" not in text:
                fail(f"fine-grained family selector missing: {path}")

        variant = variant_modules[path]
        if record.get("japanese_raw_sha1") != variant.get("japanese_raw_sha1"):
            fail(f"Japanese provenance SHA mismatch between manifests: {path}")
        if record.get("international_raw_sha1") != variant.get("international_raw_sha1"):
            fail(f"international provenance SHA mismatch between manifests: {path}")

    if not ENTRYPOINT.is_file():
        fail("missing banks/bank03.asm")
    text = ENTRYPOINT.read_text(encoding="utf-8")
    includes = re.findall(r'^INCLUDE\s+"([^"]+)"', text, flags=re.MULTILINE)
    module_includes = [p for p in includes if p in set(canonical)]
    if module_includes != canonical:
        fail("banks/bank03.asm canonical module include order changed")

    tail_expectations = (
        ('IF DEF(_REV0)', 'SECTION "Garbage 3 Rev 0A", ROMX[$7E30], BANK[$3]', 'INCLUDE "data/garbage/jp/rev0a/bank03_tail.asm"'),
        ('ELIF DEF(_REV1)', 'SECTION "Garbage 3 Rev B", ROMX[$7E27], BANK[$3]', 'INCLUDE "data/garbage/jp/revb/bank03_tail.asm"'),
        ('ELIF DEF(_REV2)', 'SECTION "Garbage 3 Rev C", ROMX[$7E27], BANK[$3]', 'INCLUDE "data/garbage/jp/revc/bank03_tail.asm"'),
    )
    for tokens in tail_expectations:
        for token in tokens:
            if token not in text:
                fail(f"Bank 03 JP tail wiring missing token: {token}")
    if 'INCLUDE "data/garbage/jp/revd/' in text:
        fail("JP Rev D must use linker zero fill rather than a Garbage 3 source")

    fine = sum(
        1 for record in merged_modules.values()
        if record.get("strategy") == "fine-grained-family-conditional"
    )
    whole = len(substantive) - fine
    print(
        "Bank 03 source check passed: 28/28 modules present "
        f"(10 exact shared + 4 cosmetic-normalized + {fine} fine-grained + {whole} whole-family), "
        "provenance hashes intact, canonical include order intact, JP tails wired."
    )


if __name__ == "__main__":
    main()
