# Yellow Multiply wrapper reconstruction

All nine catalogued Yellow releases contain one verified 13-byte home-bank `Multiply` wrapper. Japanese rev0-rev3 target `$3d:$598b`; the five localized releases also use bank `$3d`, with targets `$6606..$660e` recorded individually. Wrapper placement and `Bankswitch` addresses vary by revision and language and are retained per report.

Japanese is the origin reference, with English, German, Spanish, French, and Italian independently verified against their ROM hashes. Naming and macro expansion follow `pret/pokered@af519899719f0754965776faac0e836a3b906e6d`, `home/math.asm` and `macros/farcall.asm`. No ROM bytes are published.
