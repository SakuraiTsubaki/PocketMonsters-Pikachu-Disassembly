# Yellow Divide wrapper reconstruction

All nine Yellow releases place a verified 22-byte `Divide` wrapper immediately after `Multiply`. Yellow uses a compact helper-call homecall form: save `hLoadedROMBank`, load bank `$3d`, call the release-specific bank-switch helper, call `_Divide`, restore the prior bank through the same helper, restore AF/BC/DE/HL, and return. Each revision and language retains its own helper and core addresses in the report.

Japanese rev0-rev3 are the origin reference; English, German, Spanish, French, and Italian are independently verified. Symbolic naming follows `pret/pokered@af519899719f0754965776faac0e836a3b906e6d`; the retail Yellow helper variant is recorded from ROM evidence. No ROM bytes are published.
