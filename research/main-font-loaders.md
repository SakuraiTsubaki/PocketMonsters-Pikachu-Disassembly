# Main font loader provenance

All four Japanese origin revisions and the five official global Yellow
releases were scanned independently for the Gen I 1bpp font-loading routine.
Every verified ROM contains exactly one matching loader, and every loader
resolves to the source offset and source hash already recorded by its font
extraction report.

The four Japanese revisions load the shared Japanese font from `0x10A19`.
The English, German, French, Italian, and Spanish releases load their
language-specific font from `0x10600`. Loader code positions are preserved per
release because even revisions sharing identical font bytes do not always use
the same code offset.

The reports contain ROM identity, loader location, banked address, source
range, and hashes. They contain neither instruction bytes nor font bytes.

