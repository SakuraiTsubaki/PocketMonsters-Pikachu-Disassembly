from __future__ import annotations
import csv, json, unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

class ReleaseReportTests(unittest.TestCase):
    def test_release_evidence_is_synchronized(self):
        project=json.loads((ROOT/"project.json").read_text(encoding="utf-8"))
        report=json.loads((ROOT/"analysis"/"pikachu-release-header-report.json").read_text(encoding="utf-8"))
        with (ROOT/"research"/"releases.csv").open(newline="",encoding="utf-8") as stream: rows=list(csv.DictReader(stream))
        p={x["id"]:x for x in project["releases"]}; r={x["id"]:x for x in report["releases"]}; c={x["id"]:x for x in rows}
        self.assertEqual(set(p),set(r)); self.assertEqual(set(p),set(c)); self.assertEqual(len(p),9)
        for release_id,item in p.items():
            self.assertEqual(item["status"],"candidate"); self.assertEqual(item["sha256"],r[release_id]["sha256"]); self.assertEqual(item["sha256"],c[release_id]["sha256"]); self.assertTrue(all(r[release_id]["validation"].values()))
    def test_duplicate_file_labels_are_not_duplicate_releases(self):
        report=json.loads((ROOT/"analysis"/"pikachu-release-header-report.json").read_text(encoding="utf-8"))
        self.assertEqual(report["duplicate_files_observed"],5)
        self.assertEqual(len({x["sha256"] for x in report["releases"]}),9)

if __name__=="__main__": unittest.main()

