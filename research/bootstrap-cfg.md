# Japanese bootstrap control-flow graph

A depth-one CFG begins at $1d60. Its internal WRAM-clear loop is retained as an edge without duplicating an overlapping block, while the fallthrough block at $1d94 is decoded through its terminating jump to $416a. The two contiguous blocks cover 182 exact ROM bytes. Analysis, RGBDS source, provenance manifest, and tests are committed without ROM data; release status remains unchanged.

