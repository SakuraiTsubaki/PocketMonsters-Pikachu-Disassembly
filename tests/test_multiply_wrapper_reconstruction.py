import csv,hashlib,json,unittest
from pathlib import Path
R=Path(__file__).parents[1];E={'pikachu-jp-rev0':(0x38C6,0x598B,0x3E7D),'pikachu-jp-rev1':(0x38C7,0x598B,0x3E7E),'pikachu-jp-rev2':(0x38C7,0x598B,0x3E7E),'pikachu-jp-rev3':(0x38C7,0x598B,0x3E7E),'yellow-en-rev0':(0x38A5,0x660E,0x3E84),'yellow-de-rev0':(0x38AA,0x6607,0x3E89),'yellow-es-rev0':(0x38AA,0x6606,0x3E89),'yellow-fr-rev0':(0x38A8,0x660E,0x3E87),'yellow-it-rev0':(0x38A3,0x6608,0x3E82)}
class T(unittest.TestCase):
 def test_releases(self):
  rows={x['id']:x for x in csv.DictReader((R/'research/releases.csv').read_text().splitlines())};self.assertEqual(set(rows),set(E))
  for k,(a,t,s) in E.items():
   m=json.loads((R/f'analysis/{k}-multiply-wrapper.json').read_text());f=m['function'];self.assertEqual(m['target']['sha256'],rows[k]['sha256']);self.assertEqual((f['bank'],f['address'],f['length']),(0,a,13));self.assertEqual(f['far_call']['target']['bank'],0x3D);self.assertEqual(f['far_call']['target']['address'],t);self.assertEqual(f['far_call']['bankswitch']['address'],s);self.assertFalse(m['raw_rom_bytes_included'])
 def test_manifest(self):
  m=json.loads((R/'manifests/multiply-wrapper-reconstruction.json').read_text());[self.assertEqual(hashlib.sha256((R/o['path']).read_bytes()).hexdigest(),o['sha256'])for o in m['outputs']]
if __name__=='__main__':unittest.main()
