#!/usr/bin/env python3
"""census_stream_banks.py — ROADMAP ARC CAP2a (S135): layouts, attr maps and
tilesets past banks $64 / $67 land in the 4 MB ROM's overflow banks ($80+) and
the GAME draws them from there.

    python3 tools/census_stream_banks.py [--rooms 48] [--sample 12] [--out DIR]
                                         [--no-pyboy]

1. Generates a STRESS project: the example project + N new rooms ($74 …), each
   with its own tileset (a deterministic variant of the example's sheet) and
   three screens, each screen its own layout + attr map (seeded pseudo-random
   grids) — enough to fill $64 and $67 and spill into several banks $80+.
2. Compiles + builds it (editor2 compiler + builder: 4 MB, check_banks).
3. STATIC: every stream of the plan is decoded from the built ROM at its
   (bank, entry) with the ROM0 decompressor's rule (pointer at $4001 + 2E) and
   compared with the bytes the project defines; every overflow bank starts with
   its own number. (That the references — room steps, render rows, $26DD
   records — carry the plan's (bank, entry) is what step 4 and test_compiler
   test_s135 check.)
4. PYBOY (unless --no-pyboy): boots, warps into a sample of the stress rooms
   (every overflow bank represented; screens 0 / 1 / 2) and compares the
   game's background with the editor's preview (editor2 ProjectRenderer), tile
   by tile, skipping tiles a sprite covers. 0 tiles differing = the game draws
   the overflow banks' layouts, colours and tilesets exactly as the editor.

Prints a summary; exit status 0 = everything matched. Nothing in the repo is
written (the stress project and its build live in --out, default a temp dir).
"""
import argparse
import copy
import json
import os
import random
import shutil
import sys
import tempfile

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, REPO)
EXAMPLE = os.path.join(REPO, 'editor2', 'example-project')
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')


# ------------------------------------------------------------------ generator
def _grid(rng, hi, runs=True):
    g = []
    for _r in range(16):
        row, v = [], rng.randrange(hi)
        for _c in range(20):
            if not runs or rng.random() < 0.55:
                v = rng.randrange(hi)
            row.append(v)
        g.append(row)
    return g


def _sheet_variant(base, i):
    """A distinct 2048-byte sheet per room: tiles rotated by i, every tile
    whose index has bit (i % 7) set inverted (a different colour index)."""
    tiles = [bytearray(base[t * 16:(t + 1) * 16]) for t in range(128)]
    tiles = tiles[i % 128:] + tiles[:i % 128]
    for t in range(128):
        if (t >> (i % 7)) & 1:
            tiles[t] = bytearray(b ^ 0xFF for b in tiles[t])
    return bytes(b''.join(tiles))


def make_stress(out_dir, n_rooms, seed=135):
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)
    shutil.copytree(EXAMPLE, out_dir, ignore=shutil.ignore_patterns('build'))
    d = json.load(open(os.path.join(out_dir, 'project.json')))
    c = d['custom']
    base = open(os.path.join(out_dir, 'assets', 'combined_room6b.2bpp'), 'rb').read()
    from editor2.core import formats as F
    used = {F.val(r['mapID']) for r in c['rooms']}
    mid = max(used) + 1
    rng = random.Random(seed)
    rooms = []
    os.makedirs(os.path.join(out_dir, 'assets', 'stress'), exist_ok=True)
    for i in range(n_rooms):
        tid = f"stress_ts_{i}"
        rel = f"assets/stress/{tid}.2bpp"
        open(os.path.join(out_dir, rel), 'wb').write(_sheet_variant(base, i + 1))
        c['tilesets'].append({'id': tid, 'raw2bpp': rel})
        screens = {}
        for k in range(3):
            lid = f"stress_{i}_s{k}"
            c['layouts'].append({'id': lid, 'tiles': _grid(rng, 0x3C),
                                 'attr': _grid(rng, 4)})
            screens[str(k)] = {'layout': {'id': lid}, 'npcs': [], 'exits': []}
        room = {'id': f"stress_{i}", 'mapID': f"0x{mid:02X}", 'source_mapID': '0x04',
                'record': {'tileset': tid, 'width_px': 480, 'height_px': 128,
                           'collision_threshold': '0x00'},
                'render': {'palette': 'pal_6b'},
                'screens': screens, 'animation': 'none'}
        c['rooms'].append(room)
        rooms.append(room)
        mid += 1
    json.dump(d, open(os.path.join(out_dir, 'project.json'), 'w'), indent=1)
    return d, rooms


# ------------------------------------------------------------------ static
def static_check(prj, rom, sym):
    from editor2.core import layouts as L
    from editor2.core.builder import parse_sym
    errs = []
    plan = prj.stream_plan()
    for b in plan['overflow']:
        if rom[b * 0x4000] != b:
            errs.append(f"bank ${b:02X}: byte $4000 = ${rom[b * 0x4000]:02X}")
    raw_of = {}
    for lay in prj.layouts:
        if 'tiles' in lay:
            raw_of[('tiles', lay['id'])] = L.pad_layout(lay['tiles'])
        if 'attr' in lay:
            raw_of[('attr', lay['id'])] = L.pack_attr(lay['attr'])
    for ts in prj.tilesets:
        raw_of[('tileset', ts['id'])] = L.tileset_bytes(REPO, ts, prj.root)
    dt = L._tool(REPO, 'decompress_tiles')
    for key, (b, e) in plan['where'].items():
        res = dt.decompress_lz(rom, b, e)
        got = bytes(res[0]) if res else None
        want = raw_of[key]
        if got is None or got[:len(want)] != want:
            errs.append(f"{key}: ROM ${b:02X} entry {e} does not decode to the project's bytes")
    return errs, len(plan['where'])


# ------------------------------------------------------------------ pyboy
def bg_tiles(img):
    """160x144 RGB image -> {(tx, ty): bytes of the 8x8 block}."""
    px = img.convert('RGB').tobytes()
    out = {}
    for ty in range(18):
        for tx in range(20):
            blk = b''.join(px[((ty * 8 + y) * 160 + tx * 8) * 3:
                              ((ty * 8 + y) * 160 + tx * 8 + 8) * 3] for y in range(8))
            out[(tx, ty)] = blk
    return out


def sprite_tiles(p):
    cov = set()
    for i in range(40):
        y, x = p.memory[0xFE00 + 4 * i] - 16, p.memory[0xFE00 + 4 * i + 1] - 8
        if p.memory[0xFE00 + 4 * i] == 0 or y >= 144 or x >= 160:
            continue
        for dy in range(0, 16, 8):
            for yy in (y + dy, y + dy + 7):
                for xx in (x, x + 7):
                    if 0 <= xx < 160 and 0 <= yy < 144:
                        cov.add((xx // 8, yy // 8))
    return cov


def pyboy_check(rom_path, data, prj, rooms, sample, out_dir):
    from tools.pyboy_harness import boot, to_bedroom, warp, adv, MAP_ID, SCREEN_IDX
    from editor2.core.render_project import ProjectRenderer
    r = ProjectRenderer(REPO, prj.root, data, rom_path=ROM)
    plan = prj.stream_plan()
    # the sample: rooms whose tileset or layouts sit in each overflow bank, + spread
    want = []
    for b in plan['overflow']:
        for room in rooms:
            keys = [('tileset', room['record']['tileset'])] + \
                   [(kind, room['screens'][k]['layout']['id']) for k in room['screens']
                    for kind in ('tiles', 'attr')]
            if any(plan['where'][k][0] == b for k in keys) and room not in want:
                want.append(room)
                break
    step = max(1, len(rooms) // max(1, sample))
    for room in rooms[::step]:
        if room not in want:
            want.append(room)
    want = want[:max(sample, len(plan['overflow']))]
    p = boot(rom_path)
    to_bedroom(p)
    results = []
    for n, room in enumerate(want):
        mid = int(room['mapID'], 16)
        k = n % 3
        warp(p, mid, 10 * k + 5, 4, settle=240)
        got_mid, got_scr = p.memory[MAP_ID], p.memory[SCREEN_IDX]
        img = p.screen.image.copy()
        img.save(os.path.join(out_dir, f"game_{room['id']}_s{k}.png"))
        prev = r.render_screen(room, str(k))
        prev.save(os.path.join(out_dir, f"prev_{room['id']}_s{k}.png"))
        g, e = bg_tiles(img), bg_tiles(prev.crop((0, 0, 160, 144)) if prev.height >= 144
                                       else _pad144(prev))
        cov = sprite_tiles(p)
        rows = range(16)
        diff = [(tx, ty) for ty in rows for tx in range(20)
                if (tx, ty) not in cov and g[(tx, ty)] != e[(tx, ty)]]
        banks = sorted({plan['where'][kk][0] for kk in
                        [('tileset', room['record']['tileset']),
                         ('tiles', room['screens'][str(k)]['layout']['id']),
                         ('attr', room['screens'][str(k)]['layout']['id'])]})
        results.append((room['id'], k, got_mid == mid, got_scr, len(diff),
                        320 - len(cov), banks))
    p.stop(save=False)
    return results


def _pad144(img):
    from PIL import Image
    out = Image.new('RGB', (160, 144))
    out.paste(img.convert('RGB'), (0, 0))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rooms', type=int, default=48)
    ap.add_argument('--sample', type=int, default=12)
    ap.add_argument('--out', default=None)
    ap.add_argument('--no-pyboy', action='store_true')
    a = ap.parse_args()
    out = a.out or tempfile.mkdtemp(prefix='cap2a_')
    proj = os.path.join(out, 'stress-project')
    data, rooms = make_stress(proj, a.rooms)
    from editor2.core import compiler as C, builder as B
    outputs, prj, _w = C.compile_project(proj, REPO)
    C.write_outputs(outputs, proj)
    rom_path, sym_path, md5 = B.build_rom(REPO, proj, os.path.join(proj, 'build'))
    rom = open(rom_path, 'rb').read()
    plan = prj.stream_plan()
    print(f"stress project: {a.rooms} rooms, {len(plan['where'])} streams; "
          f"ROM {len(rom)} B, md5 {md5}")
    for b in [0x64, 0x67] + plan['overflow']:
        print(f"  bank ${b:02X}: {len(plan['banks'][b]):3d} streams, "
              f"{plan['used'][b]:5d} / 16384 B")
    errs, n = static_check(prj, rom, sym_path)
    print(f"static: {n} streams decoded from the ROM at their (bank, entry): "
          f"{'all match' if not errs else str(len(errs)) + ' MISMATCH'}")
    for e in errs[:10]:
        print("   ", e)
    bad = bool(errs) or len(plan['overflow']) == 0
    if not a.no_pyboy:
        res = pyboy_check(rom_path, data, prj, rooms, a.sample, out)
        for rid, k, okm, scr, nd, ncmp, banks in res:
            print(f"  game {rid} screen {k} (screen idx {scr}): map {'ok' if okm else 'WRONG'}, "
                  f"{ncmp} tiles compared, {nd} differ — streams in banks "
                  + ", ".join(f"${b:02X}" for b in banks))
            bad |= (not okm) or nd > 0 or scr != k
        print(f"pyboy: {len(res)} screens, "
              f"{sum(1 for r in res if r[4] == 0 and r[2] and r[3] == r[1])} == the editor preview; "
              f"pictures in {out}")
    print("RESULT:", "FAIL" if bad else "PASS")
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
