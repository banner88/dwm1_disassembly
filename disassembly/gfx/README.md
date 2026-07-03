# gfx/ — READ BEFORE TOUCHING

The `.2bpp` files here are **ROM-exact source data**: byte slices of the
original ROM that the disassembly pulls back in via `INCBIN` (banks `$40`,
`$4f`, `$56`). They are committed to git and are as load-bearing as any `db`
block. Deleting or regenerating them breaks the byte-perfect build.

The `.png` files are a **viewing convenience only** (mgbdis exports them so a
human can look at the graphics). They are NOT the source: 17 of the 18
committed `.2bpp` are not byte-identical to what `rgbgfx` produces from the
matching PNG (verified 2026-07-02; a regenerated set builds MD5 `91609a37…`
instead of `1ca6579…`).

Rules:
1. **Never delete `*.2bpp`/`*.1bpp` here.** (`make clean` used to do this —
   the target was fixed S51 and no longer touches gfx.)
2. **Never regenerate a `.2bpp` from its `.png`.** If one is missing or
   suspect: `git checkout -- disassembly/gfx/<file>` (surgical, per file).
3. To rebuild the ROM, remove only `game.o game.gbc game.sym game.map`.
