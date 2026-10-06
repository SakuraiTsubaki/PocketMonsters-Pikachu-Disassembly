import hashlib,json,unittest
from pathlib import Path
ROOT=Path(__file__).parents[1]
EXPECTED={'de':'aed41ea3e785ac9c06fd641270ff30b59de5fc64fed4349e81a9aaa4ba7d31f9','fr':'77b31f874fd877fbf48757f315ffc3144e06fc7222aba6ac4eda2045ebf5d3fa','it':'e3f0663e16ac240bc1c6681cdb95ca7230d86fca23eb931ea58f4abce0002856','es':'55d56d6f73225886bfdc0db1ddb754d2f4dfc6ef5ae74ddfa079c23b6ec80039'}
class Tests(unittest.TestCase):
 def test_languages(self):
  for l,h in EXPECTED.items():
   c=json.loads((ROOT/f'analysis/pikachu-{l}-startup-dispatch.json').read_text());self.assertEqual(c['source_sha256'],h);self.assertEqual([b['start_address'] for b in c['blocks']],[0x1ab,0x1af,0x1b2]);self.assertTrue(all('block_bytes' not in b for b in c['blocks']))
 def test_manifests(self):
  for l in EXPECTED:
   m=json.loads((ROOT/f'manifests/{l}-startup-dispatch.json').read_text());[self.assertEqual(hashlib.sha256((ROOT/o['path']).read_bytes()).hexdigest(),o['sha256']) for o in m['outputs']]
if __name__=='__main__':unittest.main()
