from __future__ import annotations
import hashlib,json,struct,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
LANGS=('de','es','fr','it')
class GlobalEntryHeaderTests(unittest.TestCase):
 def test_public_entries_sources_and_png(self):
  for lang in LANGS:
   entry_path=next((ROOT/'analysis').glob(f'*-{lang}-entrypoint.json'));entry=json.loads(entry_path.read_text());self.assertNotIn('entry_bytes',entry);self.assertTrue(all('bytes' not in i for i in entry['instructions']));self.assertIn(f"jp ${entry['target_address']:04x}",(ROOT/'src'/f'cartridge_entry_{lang}.asm').read_text());png=(ROOT/'graphics'/'header'/f'nintendo-logo-{lang}.png').read_bytes();self.assertEqual(png[:8],b'\x89PNG\r\n\x1a\n');self.assertEqual(struct.unpack('>II',png[16:24]),(384,64))
 def test_manifest_outputs(self):
  manifest=json.loads((ROOT/'manifests'/'global-entry-header.json').read_text());self.assertEqual(len(manifest['languages']),4);self.assertTrue(all(hashlib.sha256((ROOT/o['path']).read_bytes()).hexdigest()==o['sha256'] for o in manifest['outputs']))
if __name__=='__main__':unittest.main()

