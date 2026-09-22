# Pikachu Japanese revision 0 bank map

The Japanese origin candidate `pikachu-jp-rev0` is 1 MiB and divides exactly into 64 physical 16 KiB ROM banks. `analysis/pikachu-jp-rev0-bank-fingerprints.json` records a SHA-256 fingerprint, Shannon entropy, distinct-byte count, and zero/`0xff` counts for every bank. `analysis/banks.csv` maps bank 0 to the fixed `0x0000–0x3fff` CPU window and switchable banks to `0x4000–0x7fff`.

Bank 0 is classified only as `header-and-code`; the remaining non-padding banks stay `unclassified` until instruction/data boundaries are established from stronger evidence. Fingerprinting provides stable boundaries and change detection without claiming that entropy distinguishes code from data.

The source remains a `candidate`, not a verified retail baseline. No ROM bytes or extracted byte ranges are stored.
