import csv,hashlib,json,unittest
from pathlib import Path
R=Path(__file__).parents[1]
class T(unittest.TestCase):
 def test_releases(self):
  rows={x['id']:x for x in csv.DictReader((R/'research/releases.csv').read_text().splitlines())}
  for k,row in rows.items():
   m=json.loads((R/f'analysis/{k}-divide-wrapper.json').read_text());f=m['function'];x=json.loads((R/f'analysis/{k}-multiply-wrapper.json').read_text())['function'];self.assertEqual(m['target']['sha256'],row['sha256']);self.assertEqual((f['address'],f['length'],f['variant']),(x['range_end_exclusive'],22,'helper-call'));self.assertEqual(f['home_call']['target']['bank'],0x3D);self.assertEqual(f['home_call']['target']['address'],x['far_call']['target']['address']+0x64);self.assertLess(f['home_call']['bank_switch']['helper']['address'],0x4000);self.assertFalse(m['raw_rom_bytes_included'])
 def test_manifest(self):
  m=json.loads((R/'manifests/divide-wrapper-reconstruction.json').read_text());[self.assertEqual(hashlib.sha256((R/o['path']).read_bytes()).hexdigest(),o['sha256'])for o in m['outputs']]
if __name__=='__main__':unittest.main()
