# Yellow BattleRandom reconstruction

All nine Yellow releases independently match the complete 56-byte link PRNG in bank `$0f`. Japanese rev0–3 use `$7321`, link state `$d0f0`, index `$ccde`, and list `$d10d`. English uses `$7027`, `$d12a`, and `$d147`; the other international releases use link state `$d12f`, list `$d14c`, and their own entry addresses. All compare link state with `$04`, consume ten shared values, and refresh nine seeds with `5x+1`.

The basis is `pret/pokered@af519899719f0754965776faac0e836a3b906e6d`, `engine/battle/core.asm`. No ROM bytes are published.
