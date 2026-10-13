import hashlib
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]


class MainFontLoaderTests(unittest.TestCase):
    def test_each_release_loader_resolves_to_extracted_font(self):
        manifest = json.loads((ROOT / "manifests/main-font-loaders.json").read_text())
        self.assertEqual(len(manifest["releases"]), 9)
        for item in manifest["releases"]:
            loader = json.loads((ROOT / item["loader_report"]).read_text())
            font = json.loads((ROOT / item["font_report"]).read_text())
            self.assertEqual(loader["rom_sha256"], item["rom_sha256"])
            self.assertEqual(len(loader["candidates"]), 1)
            candidate = loader["candidates"][0]
            self.assertEqual(candidate["loader_offset"], item["loader_offset"])
            self.assertEqual(candidate["source_offset"], font["source_offset"])
            self.assertEqual(candidate["source_sha256"], font["source_sha256"])
            self.assertEqual((candidate["source_length"], candidate["tile_count"]), (1024, 128))
            self.assertTrue(candidate["raw_bytes_omitted"])
            self.assertFalse(loader["raw_rom_bytes_included"])

    def test_manifest_outputs_are_hash_locked(self):
        manifest = json.loads((ROOT / "manifests/main-font-loaders.json").read_text())
        self.assertFalse(manifest["raw_rom_bytes_included"])
        for output in manifest["outputs"]:
            self.assertEqual(hashlib.sha256((ROOT / output["path"]).read_bytes()).hexdigest(), output["sha256"])


if __name__ == "__main__":
    unittest.main()

