import hashlib,json,unittest
from pathlib import Path
ROOT=Path(__file__).parents[1]
class Tests(unittest.TestCase):
 def test_block(self):
  r=json.loads((ROOT/'analysis/pikachu-jp-startup-main-block.json').read_text());self.assertEqual((r['start_address'],r['end_address']),(0x1D94,0x1E16));self.assertEqual(r['instruction_count'],56);self.assertEqual(r['terminator'],'jp $416a');self.assertEqual(sum(i['opcode']==0xCD for i in r['instructions']),13)
 def test_manifest(self):
  m=json.loads((ROOT/'manifests/startup-main-block.json').read_text());self.assertFalse(m['raw_rom_bytes_included']);[self.assertEqual(hashlib.sha256((ROOT/o['path']).read_bytes()).hexdigest(),o['sha256']) for o in m['outputs']]
if __name__=='__main__':unittest.main()

