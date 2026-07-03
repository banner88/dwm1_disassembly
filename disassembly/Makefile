all: game.gbc

# ── gfx/*.2bpp are SOURCE DATA, not build products ──────────────────────────
# The committed .2bpp files are ROM-exact byte slices INCBIN'd by the asm
# (banks $40/$4f/$56). The .png files beside them are a VIEWING convenience
# only: 17 of the 18 .2bpp are NOT byte-identical to `rgbgfx <png>` output
# (verified S51 — regenerating them builds a wrong-MD5 ROM, 91609a37…).
# The old `%.2bpp: %.png` pattern rules and the gfx-deleting `clean` target
# were removed for this reason. If a .2bpp is ever missing, restore it from
# git — do NOT regenerate it from the .png. See gfx/README.md.
# ─────────────────────────────────────────────────────────────────────────────

game.o: game.asm bank_*.asm
	rgbasm  -o game.o game.asm

game.gbc: game.o
	rgblink -n game.sym -m game.map -o $@ $<
	rgbfix -v -p 255 $@

	md5sum $@

clean:
	rm -f game.o game.gbc game.sym game.map
