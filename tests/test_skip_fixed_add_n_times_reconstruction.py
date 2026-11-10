import hashlib,json,unittest
from pathlib import Path
R=Path(__file__).parents[1]
class Tests(unittest.TestCase):
 def test_catalog(self):
  s=json.loads((R/'analysis/skip-fixed-add-n-times-summary.json').read_text());self.assertEqual(s['release_count'],9);self.assertEqual([x['language'] for x in s['releases'][3:5]],['Japanese','English'])
  for x in s['releases']:
   e=json.loads((R/x['evidence']).read_text());f=e['functions'];self.assertEqual(x['name_length'],6 if x['language']=='Japanese' else 11);self.assertEqual(f['SkipFixedLengthTextEntries']['range_end_exclusive'],f['AddNTimes']['address'])
 def test_manifest(self):
  m=json.loads((R/'manifests/skip-fixed-add-n-times-reconstruction.json').read_text());
  for x in m['outputs']:self.assertEqual(hashlib.sha256((R/x['path']).read_bytes()).hexdigest(),x['sha256'])
if __name__=='__main__':unittest.main()
