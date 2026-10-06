import hashlib,json,unittest
from pathlib import Path
ROOT=Path(__file__).parents[1]
class Tests(unittest.TestCase):
 def test_cfg(self):
  c=json.loads((ROOT/'analysis/pikachu-en-startup-dispatch.json').read_text());self.assertEqual(c['source_sha256'],'8cbaa499397e4f1a679c992ea9382a2dd7942ab398b48c19829c2d9529de47bf');self.assertEqual([b['start_address'] for b in c['blocks']],[0x1ab,0x1af,0x1b2]);self.assertTrue(all('block_bytes' not in b for b in c['blocks']))
 def test_manifest(self):
  m=json.loads((ROOT/'manifests/english-startup-dispatch.json').read_text());self.assertFalse(m['raw_rom_bytes_included']);[self.assertEqual(hashlib.sha256((ROOT/o['path']).read_bytes()).hexdigest(),o['sha256']) for o in m['outputs']]
if __name__=='__main__':unittest.main()
