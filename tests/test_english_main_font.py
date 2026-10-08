import hashlib
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).parents[1]


class EnglishMainFontTests(unittest.TestCase):
    def setUp(self):
        self.report = json.loads((ROOT / "analysis/pikachu-en-main-font.json").read_text(encoding="utf-8"))
        self.manifest = json.loads((ROOT / "manifests/english-main-font.json").read_text(encoding="utf-8"))

    def test_verified_range_and_identity(self):
        self.assertEqual((self.report["source_offset"], self.report["source_length"]), (0x10600, 0x400))
        self.assertEqual(self.report["source_sha256"], "7da47648890723845fd71777e0ef6616c38f145a02a2aa58ca71d3460381d898")
        self.assertEqual(self.manifest["release"]["id"], "yellow-en-rev0")
        self.assertEqual(self.manifest["release"]["sha256"], self.report["rom_sha256"])
        self.assertTrue(self.manifest["reference"]["unique_rom_match"])

    def test_outputs_and_publication_boundary(self):
        self.assertFalse(self.manifest["raw_rom_bytes_included"])
        self.assertEqual((self.report["tile_count"], self.report["tiles_per_row"]), (128, 16))
        for output in self.manifest["outputs"]:
            self.assertEqual(hashlib.sha256((ROOT / output["path"]).read_bytes()).hexdigest(), output["sha256"])
        self.assertEqual(hashlib.sha256((ROOT / "graphics/font/main-font-en.png").read_bytes()).hexdigest(), self.report["png_sha256"])


if __name__ == "__main__":
    unittest.main()
