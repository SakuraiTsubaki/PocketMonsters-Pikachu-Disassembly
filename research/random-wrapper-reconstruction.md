# Yellow Random wrapper reconstruction

All nine SHA-256-gated Yellow releases contain exactly one complete 17-byte home-bank `Random` wrapper. Japanese rev0 uses `$3e66`; rev1–3 use `$3e67`; international builds range from `$3e6b` to `$3e72`. Each far-calls the release's verified bank `$3d` `Random_`, reloads `hRandomAdd=$ffd3`, and restores BC, DE, and HL. Distinct `Bankswitch` and core addresses are preserved per release.

The source basis is `pret/pokered@af519899719f0754965776faac0e836a3b906e6d`, `home/random.asm` and `macros/farcall.asm`. Evidence order is Japanese, English, then German, French, Italian, and Spanish because no official Korean Generation I release exists. No ROM bytes are published.
