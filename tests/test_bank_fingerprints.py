from __future__ import annotations
import csv,hashlib,json,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class BankFingerprintTests(unittest.TestCase):
 def test_origin_bank_map_is_complete_and_synchronized(self):
  report=json.loads((ROOT/"analysis"/"pikachu-jp-rev0-bank-fingerprints.json").read_text(encoding="utf-8"));rows=list(csv.DictReader((ROOT/"analysis"/"banks.csv").read_text(encoding="utf-8").splitlines()));self.assertEqual(report["sha256"],"09a083624c4f84ccae99165d4091e7c5403aaf9ae44329a9349b4d59b4095436");self.assertEqual(report["bank_size"],0x4000);self.assertEqual(report["bank_count"],64);self.assertEqual(len(rows),64);self.assertEqual(len({x["sha256"] for x in report["banks"]}),64);self.assertTrue(all(x["source_sha256"]==report["sha256"] for x in rows))
 def test_manifest_hashes_outputs(self):
  manifest=json.loads((ROOT/"analysis"/"pikachu-jp-rev0-bank-manifest.json").read_text(encoding="utf-8"));
  for output in manifest["outputs"]:self.assertEqual(hashlib.sha256((ROOT/output["path"]).read_bytes()).hexdigest(),output["sha256"])
if __name__=="__main__":unittest.main()
