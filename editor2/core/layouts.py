"""Bank $64/$67 payload packing — the P3.2 [G-A] backend (S92).

Turns semantic project.json content into the exact byte streams the proven
tools produced, so the emitters in emitters.py can own patches/bank_064.asm
and patches/bank_067.asm the same way rooms60 owns bank_060.asm.

Formats (doc citations):
  * Tile layout: 20x16 visible grid -> 32x16 VRAM rows (cols 20-31 = $FF)
    -> LZSS (ROOM_DATA_FORMAT "Tile Layout System"; tools/tile_layout_compiler.py
    is the proven reference implementation this mirrors).
  * Attr map: 16x20 per-position palette grid -> 256-byte block
    (8 attr-rows x 2 half-rows x 10 col-pairs, HIGH nibble = LEFT tile)
    -> LZSS (GATE_GENERATION §7.2; tools/build_gate_room.py gen_attr is the
    proven reference).
  * Tileset GFX: 2048 bytes (128 tiles x 16 B 2bpp) -> LZSS
    (ROOM_DATA_FORMAT "Tileset Graphics System"; tools/build_combined_tileset.py
    is the proven producer for combined/mashup sheets).

The compressor is tools/compress_tiles.compress_lz — deterministic, so
byte-identity regressions are meaningful (verified S92: recompressing the
decompressed committed bank $67 entry reproduces its stream exactly).
"""

import importlib.util
import os

_TOOL_CACHE = {}


def _tool(repo_root, name):
    """Load a tools/ module by path (music.py song_codec pattern)."""
    key = (repo_root, name)
    if key not in _TOOL_CACHE:
        path = os.path.join(repo_root, 'tools', name + '.py')
        spec = importlib.util.spec_from_file_location('_lay_' + name, path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        _TOOL_CACHE[key] = mod
    return _TOOL_CACHE[key]


def compress(repo_root, raw):
    return bytes(_tool(repo_root, 'compress_tiles').compress_lz(bytes(raw)))


def decompress_raw(repo_root, stream):
    """Decompress a raw LZSS stream (header + body) outside any bank image."""
    dt = _tool(repo_root, 'decompress_tiles')
    fake = bytearray(0x4000)
    fake[1] = 0x05
    fake[2] = 0x40
    fake[5:5 + len(stream)] = stream
    res = dt.decompress_lz(bytes(fake), 0, 0)
    if res is None:
        raise ValueError("LZSS stream failed to decompress")
    return res[0]


# --------------------------------------------------------------- tile layout

def pad_layout(tiles_16x20):
    """20-col visible grid -> 512-byte 32-col VRAM block ($FF padding)."""
    if len(tiles_16x20) != 16:
        raise ValueError(f"layout must have 16 rows, got {len(tiles_16x20)}")
    out = bytearray(512)
    for r in range(16):
        row = tiles_16x20[r]
        if len(row) != 20:
            raise ValueError(f"layout row {r} must have 20 cols, got {len(row)}")
        for c in range(20):
            out[r * 32 + c] = row[c] & 0xFF
        for c in range(20, 32):
            out[r * 32 + c] = 0xFF
    return bytes(out)


def compile_tiles(repo_root, tiles_16x20):
    return compress(repo_root, pad_layout(tiles_16x20))


# ----------------------------------------------------------------- attr map

def pack_attr(pal_16x20):
    """16x20 per-position palette grid -> 256-byte attr block.

    Layout: 8 attr-rows x (2 half-rows of 16 B: 10 used + 6 pad);
    each byte packs two tiles, HIGH nibble = LEFT tile's palette
    (GATE_GENERATION §7.2 / build_gate_room.gen_attr)."""
    if len(pal_16x20) != 16:
        raise ValueError(f"attr grid must have 16 rows, got {len(pal_16x20)}")
    out = bytearray(256)
    for ar in range(8):
        for half in range(2):
            tr = ar * 2 + half
            row = pal_16x20[tr]
            if len(row) != 20:
                raise ValueError(f"attr row {tr} must have 20 cols")
            base = ar * 32 + half * 16
            for cp in range(10):
                lp = row[cp * 2] & 0xF
                rp = row[cp * 2 + 1] & 0xF
                out[base + cp] = (lp << 4) | rp
    return bytes(out)


def unpack_attr(block256):
    """Inverse of pack_attr (extractor path)."""
    grid = [[0] * 20 for _ in range(16)]
    for ar in range(8):
        for half in range(2):
            tr = ar * 2 + half
            base = ar * 32 + half * 16
            for cp in range(10):
                b = block256[base + cp]
                grid[tr][cp * 2] = (b >> 4) & 0xF
                grid[tr][cp * 2 + 1] = b & 0xF
    return grid


def unpad_layout(block512):
    """Inverse of pad_layout (extractor path): drop the 12 pad columns."""
    return [[block512[r * 32 + c] for c in range(20)] for r in range(16)]


def compile_attr(repo_root, pal_16x20):
    return compress(repo_root, pack_attr(pal_16x20))


# ------------------------------------------------------------- tileset GFX

def tileset_bytes(repo_root, ts, project_dir):
    """Resolve a custom.tilesets[] entry to its 2048-byte 2bpp sheet.

    Forms:
      {"id", "raw2bpp": "<project-relative path>"}   — committed tile sheet
      {"id", "spec": "<project-relative path>"}       — multi-tileset editor
          export JSON (the S6-S10 import pipeline), built via
          tools/build_combined_tileset.py's cherry-pick core.
    """
    if 'raw2bpp' in ts:
        path = os.path.join(project_dir, ts['raw2bpp'])
        data = open(path, 'rb').read()
        if len(data) != 2048:
            raise ValueError(
                f"tileset {ts.get('id')!r}: raw2bpp must be exactly 2048 "
                f"bytes (128 tiles x 16 B 2bpp), got {len(data)}")
        return data
    if 'spec' in ts:
        import json
        bct = _tool(repo_root, 'build_combined_tileset')
        rom = open(os.path.join(repo_root, 'data', 'DWM-original.gbc'),
                   'rb').read()
        spec = json.load(open(os.path.join(project_dir, ts['spec'])))
        return build_sheet_from_spec(bct, rom, spec)
    raise ValueError(f"tileset {ts.get('id')!r}: needs 'raw2bpp' or 'spec'")


def build_sheet_from_spec(bct, rom, spec):
    """Cherry-pick 128 tiles per the editor-export palette list.

    Mirrors build_combined_tileset.py's GFX assembly: each palette row
    {"slot": N, "ts": "bank:step", "idx": tile} places the source tile at
    slot N; unfilled slots stay zero; the animated no-go indices (77/78)
    must already be respected by the export (validator-checked upstream).
    """
    sheet = bytearray(2048)
    for row in spec.get('palette', []):
        slot = int(row['slot'])
        if not (0 <= slot < 128):
            raise ValueError(f"tileset spec slot {slot} out of range 0-127")
        ts_key = row['ts']
        idx = int(row['idx'])
        if ts_key.startswith('EXT:'):
            raise ValueError(
                "EXT: source tiles need their .2bpp committed — use the "
                "raw2bpp form for externally-imported sheets (the PNG "
                "import front door is tools/extract_png_tileset.py)")
        bank, step = bct.parse_ts_key(ts_key)
        tile = bct.extract_tile_gfx(rom, bank, step, idx)
        sheet[slot * 16:slot * 16 + 16] = tile
    return bytes(sheet)
