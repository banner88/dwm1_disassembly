# Example: DWM2 clam → Dracky battle swap (+ correct purple palette)

This reproduces the Session-23 proof. `clam_payload.bin` is the clam's battle sprite
already encoded as 36 tiles (48×48, 576 bytes) with the 4-index battle convention
(index 1 = backdrop, 0/2/3 = body). Place these files relative to the repo root.

## 1. Battle swap + recolour, standalone test ROM

```
python3 tools/build_sprite_swap.py \
    --species 78 --kind battle \
    --payload examples/sprite_swap/clam_payload.bin \
    --palette 6c17,6bff,3a75,0000 \
    --build-rom out/DWM-clam-dracky-purple.gbc
```

Result: Dracky's battle gfx-ID `$3627` → `$7e00` (clam stream placed in overflow bank
`$7e`); Dracky's palette entry at `$17:$656d` recoloured `7b 00 ff 6b 97 2a 00 00` →
`17 6c ff 6b 75 3a 00 00` (red/gold → purple/tan). Whole-ROM diff: 2 B in `$00`
(repoint) + 4 B in `$17` (palette) + the clam in `$7e`. Per-species: no other monster
changes (Slime etc. untouched).

The `--palette` values are the clam's 4 colours as RGB555: idx0 purple `$6c17`,
idx1 backdrop `$6bff` (the engine's forced backdrop), idx2 shell `$3a75`, idx3 black
`$0000`.

## 2. Re-encoding the clam from the DWM2 sheet (optional)

The clam is the top-left monster of the Water-family sheet (`W.png`), battle sprite at
x10–37, y18–47 (28×30 px). Quantise to the 4 reps above (purple / cream / tan / black,
backdrop→idx1), fit centred in 48×48, then `dwm.sprite_codec.indices_to_tiles(grid,6,6)`
→ `clam_payload.bin`. Any 4-colour 48×48 sprite works the same way; for new art prefer
`--png your.png` (the tool quantises + encodes).

## 3. Full integration test ROM (clam + Dracky→Spirit + custom room + encounters)

Build the patched ROM (all of `patches/`), then layer the swap onto it (the patched
build already has Dracky→Spirit via `extracted/spirit_family.json` and the custom rooms
with encounters):

```
# build patched ROM with all custom content, then binary-layer the swap:
#   - copy bank $7e + battle entry $2c3b + palette $17:$656d from the standalone ROM
#   - fix header + global checksums (tools/build_sprite_swap.py: fix_*_checksum)
```

Encounter a Dracky in custom Room `$6B` (pool 0 = Slime/Anteater/Dracky) → the purple
clam appears, as a Spirit-family monster, with no VRAM/glitch issues. (`roms/` holds the
prebuilt `DWM-clam-dracky-purple.gbc` and `DWM-clam-spirit-customroom.gbc`.)

## Reusing for any monster

`--species N` repoints monster N; `--kind battle` uses table `$00:$2B9F`; recolour with
`--palette` (its entry is `MonsterBattlePalettes + N*8` at `$17:$62FD`). Follower/walking
swaps (`--kind follower`, table `$01:$49DF`) are GFX-3 — the table needs a byte-perfect
re-section first (see ROADMAP).
