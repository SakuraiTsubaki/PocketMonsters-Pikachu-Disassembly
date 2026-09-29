from __future__ import annotations
import hashlib,json,struct,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class EnglishOriginArtifactsTests(unittest.TestCase):
 def setUp(self):
  self.entry_path=next((ROOT/'analysis').glob('*-en-entrypoint.json'));self.logo_path=next((ROOT/'analysis').glob('*-en-header-logo.json'));self.entry=json.loads(self.entry_path.read_text());self.logo=json.loads(self.logo_path.read_text());self.manifest=json.loads((ROOT/'manifests'/'english-entry-header.json').read_text())
 def test_public_entry_and_source(self):
  self.assertNotIn('entry_bytes',self.entry);self.assertTrue(all('bytes' not in i for i in self.entry['instructions']));source=(ROOT/'src'/'cartridge_entry_en.asm').read_text();self.assertIn(f"jp ${self.entry['target_address']:04x}",source)
 def test_png_and_manifest(self):
  png=(ROOT/'graphics'/'header'/'nintendo-logo-en.png').read_bytes();self.assertEqual(png[:8],b'\x89PNG\r\n\x1a\n');self.assertEqual(struct.unpack('>II',png[16:24]),(384,64));self.assertEqual(hashlib.sha256(png).hexdigest(),self.logo['png_sha256']);self.assertTrue(all(hashlib.sha256((ROOT/o['path']).read_bytes()).hexdigest()==o['sha256'] for o in self.manifest['outputs']))
if __name__=='__main__':unittest.main()

