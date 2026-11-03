import csv
import hashlib
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]
ADDRESSES = {
    "pikachu-jp-rev0": (0, 0x16D9),
    "pikachu-jp-rev1": (0, 0x16DF),
    "pikachu-jp-rev2": (0, 0x16DF),
    "pikachu-jp-rev3": (0, 0x16DF),
    "yellow-de-rev0": (0, 0x00B1),
    "yellow-en-rev0": (0, 0x00B1),
    "yellow-es-rev0": (0, 0x00B1),
    "yellow-fr-rev0": (0, 0x00B1),
    "yellow-it-rev0": (0, 0x00B1),
}


class CopyDataReconstructionTests(unittest.TestCase):
    def test_all_releases(self):
        with (ROOT / "research/releases.csv").open(encoding="utf-8", newline="") as handle:
            releases = {item["id"]: item for item in csv.DictReader(handle)}
        self.assertEqual(set(releases), set(ADDRESSES))
        for release, location in ADDRESSES.items():
            report = json.loads((ROOT / f"analysis/{release}-copy-data.json").read_text(encoding="utf-8"))
            function = report["function"]
            self.assertEqual(report["target"]["sha256"], releases[release]["sha256"])
            self.assertEqual((function["bank"], function["address"]), location)
            self.assertEqual(function["length"], 23)
            self.assertEqual(function["copybytes_address"], function["address"] + 16)
            self.assertEqual(report["naming_basis"]["repository"], "pret/pokeyellow")
            self.assertFalse(report["raw_rom_bytes_included"])

    def test_manifest(self):
        manifest = json.loads((ROOT / "manifests/copy-data-reconstruction.json").read_text(encoding="utf-8"))
        self.assertFalse(manifest["raw_rom_bytes_included"])
        for output in manifest["outputs"]:
            self.assertEqual(hashlib.sha256((ROOT / output["path"]).read_bytes()).hexdigest(), output["sha256"])


if __name__ == "__main__":
    unittest.main()
