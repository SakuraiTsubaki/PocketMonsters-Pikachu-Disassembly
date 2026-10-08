import hashlib
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).parents[1]
GAME = "pikachu"


class EuropeanMainFontTests(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads((ROOT / "manifests/european-main-fonts.json").read_text(encoding="utf-8"))
        self.reports = {lang: json.loads((ROOT / f"analysis/{GAME}-{lang}-main-font.json").read_text(encoding="utf-8")) for lang in ("de", "fr", "es", "it")}

    def test_all_official_languages_have_verified_ranges(self):
        self.assertEqual(set(self.manifest["releases"]), set(self.reports))
        for lang, report in self.reports.items():
            release = self.manifest["releases"][lang]
            self.assertEqual(report["rom_sha256"], release["sha256"])
            self.assertEqual(report["source_offset"], 0x10600)
            self.assertEqual(report["source_sha256"], release["range_sha256"])
            self.assertEqual((report["source_length"], report["tile_count"]), (1024, 128))

    def test_language_families_and_outputs(self):
        self.assertEqual(self.reports["de"]["source_sha256"], self.reports["fr"]["source_sha256"])
        self.assertEqual(self.reports["es"]["source_sha256"], self.reports["it"]["source_sha256"])
        self.assertNotEqual(self.reports["de"]["source_sha256"], self.reports["es"]["source_sha256"])
        self.assertFalse(self.manifest["raw_rom_bytes_included"])
        for output in self.manifest["outputs"]:
            self.assertEqual(hashlib.sha256((ROOT / output["path"]).read_bytes()).hexdigest(), output["sha256"])


if __name__ == "__main__":
    unittest.main()
