import hashlib, json, struct, unittest
from pathlib import Path
ROOT=Path(__file__).parents[1]
class Tests(unittest.TestCase):
 def test_manifest_outputs(self):
  m=json.loads((ROOT/'manifests'/'title-logo-tiles.json').read_text())
  for o in m['outputs']:
   p=ROOT/o['path']; self.assertTrue(p.is_file()); self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(),o['sha256'])
 def test_distinct_origin_and_fallback_layouts(self):
  expected={'jp':(96,128,48),'en':(115,128,64)}
  for lang,(tiles,w,h) in expected.items():
   r=json.loads((ROOT/'analysis'/f'pikachu-{lang}-title-logo.json').read_text()); png=(ROOT/'graphics'/'title'/f'pokemon-logo-{lang}.png').read_bytes()
   self.assertEqual((r['tile_count'],r['source_length']),(tiles,tiles*16)); self.assertEqual(struct.unpack('>II',png[16:24]),(w*2,h*2)); self.assertNotIn('source_bytes',r)
if __name__=='__main__': unittest.main()
