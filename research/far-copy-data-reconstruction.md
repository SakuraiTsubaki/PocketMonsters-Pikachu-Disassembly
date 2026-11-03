# Pikachu FarCopyData reconstruction

pikachu-jp-rev0 is the Japanese origin reference. All 9 cataloged releases (Japanese, English, German, Spanish, French, Italian) verify the 20-byte FarCopyData wrapper through BankswitchCommon. The wrapper saves the active ROM bank, selects the source bank from A, delegates the BC-byte transfer, and restores the previous bank. Addresses and hashes are preserved without publishing ROM bytes.
