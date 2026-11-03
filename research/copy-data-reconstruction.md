# Pikachu CopyData reconstruction

pikachu-jp-rev0 is the Japanese origin reference. All 9 cataloged Yellow releases (Japanese, English, German, Spanish, French, Italian) independently verify the actual 23-byte home-bank CopyData implementation from pokeyellow. It handles the 16-bit BC length in C-sized chunks and is distinct from the unrelated Red-style nine-byte loop in bank 0x3E. Reports preserve identities, addresses, semantics, and hashes without ROM bytes.
