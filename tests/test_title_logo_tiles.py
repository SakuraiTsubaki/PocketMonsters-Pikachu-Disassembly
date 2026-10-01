import hashlib, json, struct, unittest
from pathlib import Path
ROOT=Path(__file__).parents[1]
class Tests(unittest.TestCase):
 def test_manifest_outputs(self):
  m=json.loads((ROOT/'manifests'/'title-logo-tiles.json').read_text())
  for o in m['outputs']:
   p=ROOT/o['path']; self.assertTrue(p.is_file()); self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(),o['sha256'])
 def test_distinct_origin_and_fallback_layouts(self):
  expected={'jp':(96,128,48),'en':(115,128,64),'de':(115,128,64),'fr':(115,128,64),'es':(115,128,64),'it':(115,128,64)}
  for lang,(tiles,w,h) in expected.items():
   r=json.loads((ROOT/'analysis'/f'pikachu-{lang}-title-logo.json').read_text()); png=(ROOT/'graphics'/'title'/f'pokemon-logo-{lang}.png').read_bytes()
   self.assertEqual((r['tile_count'],r['source_length']),(tiles,tiles*16)); self.assertEqual(struct.unpack('>II',png[16:24]),(w*2,h*2)); self.assertNotIn('source_bytes',r)
 def test_composed_english_logo_provenance(self):
  r=json.loads((ROOT/'analysis'/'pikachu-en-title-logo-composed.json').read_text()); png=(ROOT/'graphics'/'title'/'pokemon-logo-composed-en.png').read_bytes()
  self.assertEqual((r['tilemap_offset'],r['tilemap_length'],r['tilemap_width'],r['tilemap_height']),(0xf45f9,112,16,7)); self.assertEqual(r['blank_tile_ids'],['0xf4']); self.assertEqual(r['extra_tiles']['first_tile_id'],'0xfd'); self.assertEqual(struct.unpack('>II',png[16:24]),(256,112)); self.assertEqual(hashlib.sha256(png).hexdigest(),r['png_sha256'])
 def test_composed_european_logo_provenance(self):
  for lang,offset in {'de':0xf45f9,'fr':0xf4605,'es':0xf45f9,'it':0xf4605}.items():
   r=json.loads((ROOT/'analysis'/f'pikachu-{lang}-title-logo-composed.json').read_text()); png=(ROOT/'graphics'/'title'/f'pokemon-logo-composed-{lang}.png').read_bytes()
   self.assertEqual((r['tilemap_offset'],r['tilemap_length']),(offset,112)); self.assertEqual(r['blank_tile_ids'],['0xf4']); self.assertEqual(r['extra_tiles']['first_tile_id'],'0xfd'); self.assertEqual(struct.unpack('>II',png[16:24]),(256,112)); self.assertEqual(hashlib.sha256(png).hexdigest(),r['png_sha256'])
if __name__=='__main__': unittest.main()
