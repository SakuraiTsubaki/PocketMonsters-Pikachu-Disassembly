# Yellow _Multiply core reconstruction

The verified wrapper targets bound an exact 100-byte `_Multiply` routine in all nine Yellow releases. Japanese rev0-rev3 are the origin reference; English, German, Spanish, French, and Italian have the same full code hash as Red, Green, and Blue despite using bank `$3d`. All use the same HRAM product layout at `$ff95..$ff98` and the same eight-iteration shift-add algorithm.

Naming follows `pret/pokered@af519899719f0754965776faac0e836a3b906e6d`, `engine/math/multiply_divide.asm`. Reports publish addresses, structure, and hashes without ROM bytes.
