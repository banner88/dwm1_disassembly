#!/usr/bin/env python3
"""census_maze.py — the gate maze floors, measured against the game (S122,
ROADMAP P3.7b part 2 + Phase 2C "piece_id -> screen layout" / "carve").

Proves editor2/core/maze.py — the Python model of bank $16's floor builder
(label16_605b: shape mode, carve, variants, down-stairs, wandering NPC, the
player's arrival, floor items) and of how a cell is drawn (MazeScreenTable /
GateAttrTable + the theme's sheet and palettes) — against the ORIGINAL ROM in
PyBoy, and writes the piece catalogue to extracted/maze_pieces.json.

  python3 tools/census_maze.py              # floors + screens census, write JSON
  python3 tools/census_maze.py --floors N   # N floors (default 4000)
  python3 tools/census_maze.py --negative   # negative control: a broken model must fail
  python3 tools/census_maze.py --selftest   # maze_pieces.json == ROM (no PyBoy)

FLOORS: a new game (tools/pyboy_harness), the portal mailbox into gate 1;
a hook at label16_605b ($16:$605B) forces the RNG state, the maze size
($C93D), the contents row (wFloorType3), the progress tier ($CAB4) and the
NPC state ($C92D) — only on the first entry of a floor (a regenerated floor
re-enters with the game's own state, as the model does); a hook at the
builder's last `ret` ($16:$63AE, after jr_016_63ac writes the list end) reads the grid, the shape mode,
the stairs ($C960, $C964-$C967), the NPC ($C926-$C92C), the arrival ($C0A0,
wWarpSpawn $C96F-$C972), the item list ($D793 …) and the RNG — then jumps
back to $605B for the next floor (the builder is entered by fall-through, so
the stack is the same). SCREENS: 4 arrivals per floor type (the S120 hook
forces the type) — the screen shot vs the model's picture of that cell (+ the
stairs stamp), 8x8 tile by tile, sprites masked.
"""
import hashlib
import io
import json
import os
import random
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
ROM_PATH = os.path.join(REPO, 'data', 'DWM-original.gbc')
OUT = os.path.join(REPO, 'extracted', 'maze_pieces.json')
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'

ENTRY = (0x16, 0x605B)        # label16_605b
DONE = (0x16, 0x63AE)         # the `ret` after jr_016_63ac's `ld [hl], $ff` — the builder's end
TYPE_HOOK = (0x16, 0x5BD2)    # S120: right after the maze path's SelectFloorType
RNG1, RNG2 = 0xC899, 0xC89A


def catalogue(rom):
    from editor2.core import maze as MZ
    m = MZ.MazeRom(rom)
    pcs = []
    for p in m.pieces():
        pcs.append({'cell': f"0x{p['cell']:02X}", 'mode': p['mode'], 'piece': p['piece'],
                    'variant': p['variant'],
                    'openings': None if p['openings'] is None else MZ.openings_text(p['openings']),
                    'layout': f"${p['layout'][0]:02X}:{p['layout'][1]:02X}",
                    'attr': f"${p['attr'][0]:02X}:{p['attr'][1]:02X}"})
    return {
        'shape_modes': m.shape,
        'piece_table': [{'piece': r[1], 'openings': MZ.openings_text(r[0]),
                         'mask': r[0], 'weight_class': r[2]} for r in m.piece_rows],
        'cell_order': m.order,
        'patterns': [[f'0x{c:02X}' for c in p] for p in m.patterns],
        'npc_chance': m.npc_chance,
        'item_subtype': m.item_subtype,
        'themes': [{'type': t, 'name': MZ.THEME_NAMES[t],
                    'sheet': f"${m.theme_record(t)['gfx_bank']:02X}:{m.theme_record(t)['gfx_id']:02X}",
                    'threshold': f"0x{m.theme_record(t)['collision_threshold']:02X}",
                    'palette': [[f'0x{w:04X}' for w in row] for row in m.theme_palette_words(t)]}
                   for t in range(MZ.N_THEMES)],
        'pieces': pcs,
        'metatiles': len(m.metatiles()),
    }


def _read_floor(m):
    grid = [m[0xC940 + i] for i in range(16)]
    items = []
    a = 0xD793
    while m[a] != 0xFF and len(items) < 64:
        kind, sub, mx, my = m[a], m[a + 1], m[a + 2], m[a + 3]
        scr = (my // 8) * 4 + mx // 10
        items.append({'kind': kind, 'sub': sub, 'screen': scr,
                      'x': (mx % 10) * 16 + 8, 'y': (my % 8) * 16 + 8})
        a += 4
    st_scr = m[0xC960]
    sx = (m[0xC964] | m[0xC965] << 8)
    sy = (m[0xC966] | m[0xC967] << 8)
    return {'grid': grid, 'mode': m[0xC93F], 'stairs_screen': st_scr,
            'stairs_abs': (sx, sy), 'npc_screen': m[0xC926],
            'npc_abs': (m[0xC927] | m[0xC928] << 8, m[0xC929] | m[0xC92A] << 8),
            'npc_kind': m[0xC92B], 'npc_sub': m[0xC92C],
            'arrival_screen': m[0xC0A0],
            'arrival_abs': (m[0xC96F] | m[0xC970] << 8, m[0xC971] | m[0xC972] << 8),
            'items': items, 'rng': (m[RNG1] << 8) | m[RNG2]}


def _compare(M, inp, got):
    """Model the floor from the forced inputs; return a list of differences."""
    exp = M.generate(inp['seed'], inp['size'], inp['ft3'], inp['progress'], inp['npc_state'])
    ox = lambda s: M.origin[s][0] | M.origin[s][1] << 8          # noqa: E731
    oy = lambda s: M.origin[s][2] | M.origin[s][3] << 8          # noqa: E731
    d = []
    if exp['mode'] != got['mode']:
        d.append('mode')
    if exp['grid'] != got['grid']:
        d.append('grid')
    s, x, y = exp['stairs']
    if (s, (ox(s) + x, oy(s) + y)) != (got['stairs_screen'], got['stairs_abs']):
        d.append('stairs')
    n = exp['npc']
    if n is None:
        if got['npc_screen'] != 0xFF:
            d.append('npc')
    elif (n['screen'], (ox(n['screen']) + n['x'], oy(n['screen']) + n['y']), n['kind']) != \
            (got['npc_screen'], got['npc_abs'], got['npc_kind']):
        d.append('npc')
    s, x, y = exp['arrival']
    if (s, (ox(s) + x, oy(s) + y)) != (got['arrival_screen'], got['arrival_abs']):
        d.append('arrival')
    if [(i['kind'], i['sub'], i['screen'], i['x'], i['y']) for i in exp['items']] != \
            [(i['kind'], i['sub'], i['screen'], i['x'], i['y']) for i in got['items']]:
        d.append('items')
    if exp['rng'] != got['rng']:
        d.append('rng')
    return d, exp


def floors_census(n, negative=False, seed=122):
    from tools.pyboy_harness import adv, boot, to_bedroom
    from editor2.core import maze as MZ
    rom = open(ROM_PATH, 'rb').read()
    M = MZ.MazeRom(rom)
    if negative:                       # a deliberately wrong model must fail
        M.order[3], M.order[4] = M.order[4], M.order[3]
    p = boot(ROM_PATH)
    if not to_bedroom(p):
        raise SystemExit('the new game did not reach the bedroom')
    adv(p, 200)
    mem = p.memory
    rnd = random.Random(seed)
    state = {'armed': True, 'inp': None, 'left': n}
    rows = []

    def at_entry(_):
        if not state['armed']:
            return                                     # a regenerated floor
        inp = {'seed': rnd.randrange(65536), 'size': rnd.randrange(3, 16),   # 1-2 can freeze (freeze_probe)
               'ft3': rnd.randrange(16), 'progress': rnd.randrange(4),
               'npc_state': rnd.randrange(8)}
        mem[RNG1], mem[RNG2] = inp['seed'] >> 8, inp['seed'] & 0xFF
        mem[0xC93D] = inp['size']
        mem[0xC938] = inp['ft3']
        mem[0xCAB4] = inp['progress']
        mem[0xC92D] = inp['npc_state']
        state['inp'] = inp
        state['armed'] = False

    def at_done(_):
        if state['inp'] is None:
            return
        rows.append((state['inp'], _read_floor(mem)))
        state['inp'] = None
        state['left'] -= 1
        if state['left'] > 0:
            state['armed'] = True
            p.register_file.PC = ENTRY[1]

    p.hook_register(*ENTRY, at_entry, None)
    p.hook_register(*DONE, at_done, None)
    mem[0xD8D7] = 0
    mem[0xC96D], mem[0xC96E], mem[0xC96C], mem[0xC88F] = 1, 1, 1, 1
    for _ in range(max(3000, 40 * n)):      # one floor takes ~17 frames of CPU
        mem[0xCA39], mem[0xCA3A] = 0xFF, 0x7F
        p.tick()
        if state['left'] <= 0:
            break
    p.stop()
    bad, kinds, regen = [], {}, 0
    from collections import Counter
    modes = Counter()
    for inp, got in rows:
        if negative:            # the broken model's grid alone (its placements may spin)
            mode, g, _s = M.carve(inp['seed'], inp['size'])
            diff = [] if (mode, g) == (got['mode'], got['grid']) else ['grid']
            if diff:
                bad.append((inp, diff))
                kinds['grid'] = kinds.get('grid', 0) + 1
            modes[mode] += 1
            continue
        diff, exp = _compare(M, inp, got)
        modes[exp['mode']] += 1
        regen += exp['regenerated'] > 0
        if diff:
            bad.append((inp, diff))
            for k in diff:
                kinds[k] = kinds.get(k, 0) + 1
    # 25 floors as the GAME wrote them (+ up to 2 regenerated ones) for the
    # model's emulator-free regression (editor2/tests/test_compiler.py S122)
    keep = rows[:25] + [rw for rw in rows[25:] if not negative and
                        M.generate(rw[0]['seed'], rw[0]['size'], rw[0]['ft3'],
                                   rw[0]['progress'], rw[0]['npc_state'])['regenerated']][:2]
    samples = [{'input': i, 'game': json.loads(json.dumps(g))} for i, g in keep]
    return {'floors': len(rows), 'mismatches': len(bad), 'by_field': kinds, 'samples': samples,
            'shape_modes': {str(k): v for k, v in sorted(modes.items())},
            'regenerated': regen, 'items': sum(len(g['items']) for _i, g in rows),
            'npcs': sum(1 for _i, g in rows if g['npc_screen'] != 0xFF),
            'first_bad': bad[:3]}


def freeze_probe(seed=33170, size=2, frames=6000):
    """S122: a maze size of 2 whose carve closes every cell — the game's
    stairs search (MazePickStairsSpot) never finds a screen. Forces the floor
    and reports whether the builder ever reached its end."""
    from tools.pyboy_harness import adv, boot, to_bedroom
    p = boot(ROM_PATH)
    if not to_bedroom(p):
        raise SystemExit('the new game did not reach the bedroom')
    adv(p, 200)
    mem = p.memory
    st = {'forced': False, 'done': False}

    def at_entry(_):
        if not st['forced']:
            mem[RNG1], mem[RNG2] = seed >> 8, seed & 0xFF
            mem[0xC93D] = size
            st['forced'] = True

    def at_done(_):
        st['done'] = True
    p.hook_register(*ENTRY, at_entry, None)
    p.hook_register(*DONE, at_done, None)
    mem[0xD8D7] = 0
    mem[0xC96D], mem[0xC96E], mem[0xC96C], mem[0xC88F] = 1, 1, 1, 1
    for _ in range(frames):
        mem[0xCA39], mem[0xCA3A] = 0xFF, 0x7F
        p.tick()
        if st['done']:
            break
    grid = [mem[0xC940 + i] for i in range(16)]
    p.stop()
    return {'seed': seed, 'size': size, 'frames': frames, 'builder_finished': st['done'],
            'grid_all_empty': all(c & 0xF0 == 0xF0 for c in grid)}


def carve_sweep(step=7):
    """The model over every step-th RNG state, per maze size 1-15: carved floors
    (shape modes 0/1) that are empty / connected / split."""
    from editor2.core import maze as MZ
    M = MZ.MazeRom(open(ROM_PATH, 'rb').read())
    out = {}
    for size in range(1, 16):
        empty = conn = split = 0
        lo, hi = 16, 0
        for seed in range(0, 65536, step):
            mode, g, _s = M.carve(seed, size)
            if mode == 2:
                continue
            used = [i for i in range(16) if g[i] & 0xF0 != 0xF0]
            lo, hi = min(lo, len(used)), max(hi, len(used))
            if not used:
                empty += 1
                continue
            seen, todo = {used[0]}, [used[0]]
            while todo:
                i = todo.pop()
                for bit, j in ((8, i - 4), (4, i + 4), (2, i - 1), (1, i + 1)):
                    if not M.openings(g[i] >> 4) & bit or not 0 <= j < 16:
                        continue
                    if bit in (2, 1) and j // 4 != i // 4:
                        continue
                    if j not in seen and g[j] & 0xF0 != 0xF0:
                        seen.add(j)
                        todo.append(j)
            if len(seen) == len(used):
                conn += 1
            else:
                split += 1
        out[str(size)] = {'empty': empty, 'connected': conn, 'split': split,
                          'screens_min': lo, 'screens_max': hi}
    return out


def screens_census(per_type=4, seed=7):
    from tools.pyboy_harness import adv, boot, to_bedroom
    from tools.render_rooms import render_screen
    from editor2.core import maze as MZ
    rom = open(ROM_PATH, 'rb').read()
    M = MZ.MazeRom(rom)
    p = boot(ROM_PATH)
    if not to_bedroom(p):
        raise SystemExit('the new game did not reach the bedroom')
    adv(p, 200)
    st = io.BytesIO()
    p.save_state(st)
    mem = p.memory
    want = {}

    def force_type(_):
        if 't' in want:
            p.register_file.A = want['t']

    def force_seed(_):
        if 'seed' in want:
            mem[RNG1], mem[RNG2] = want['seed'] >> 8, want['seed'] & 0xFF
            want.pop('seed')
    p.hook_register(*TYPE_HOOK, force_type, None)
    p.hook_register(*ENTRY, force_seed, None)
    rnd = random.Random(seed)
    out = []
    for k in range(16 * per_type):
        st.seek(0)
        p.load_state(st)
        t = k % 16
        want.clear()
        want.update(t=t, seed=rnd.randrange(65536))
        mem[0xD8D7] = 0
        mem[0xC96D], mem[0xC96E], mem[0xC96C], mem[0xC88F] = 1, 1, 1, 1
        for f in range(2400):
            mem[0xCA39], mem[0xCA3A] = 0xFF, 0x7F
            p.tick()
            if mem[0xC969] and mem[0xC968] == t and mem[0xC88A] == 1 and mem[0xC88F] == 0 and f > 30:
                break
        for _ in range(240):
            mem[0xCA39], mem[0xCA3A] = 0xFF, 0x7F
            p.tick()
        grid = [mem[0xC940 + i] for i in range(16)]
        mode, scr, stair = mem[0xC93F], mem[0xC925], mem[0xC960]
        so = mem[0xC962] | (mem[0xC963] << 8)
        shot = p.screen.image.convert('RGB')
        ls, as_ = M.cell_streams(grid[scr], mode)
        lay = bytearray(M.layout_bytes(ls))
        if scr == stair:                 # bank $0B Call_00b_4309
            lay[so], lay[so + 1] = MZ.STAIR_TILES[0], MZ.STAIR_TILES[1]
            lay[so + 32], lay[so + 33] = MZ.STAIR_TILES[2], MZ.STAIR_TILES[3]
        pals = [[((w & 31) * 8, ((w >> 5) & 31) * 8, ((w >> 10) & 31) * 8) for w in row]
                for row in M.theme_palette_words(t)]
        pals += [[(96, 96, 96), (248, 248, 208), (176, 176, 176), (0, 0, 0)]] * 4
        model = render_screen(rom, M.theme_sheet(t), lay, M.layout_bytes(as_), pals, scale=1)
        spr = set()
        for i in range(40):
            y, x = mem[0xFE00 + 4 * i] - 16, mem[0xFE01 + 4 * i] - 8
            if -16 < y < 144 and -8 < x < 160:
                for dy in range(16):
                    for dx in range(8):
                        spr.add(((x + dx) // 8, (y + dy) // 8))
        bad = 0
        for ty in range(16):
            for tx in range(20):
                if (tx, ty) in spr:
                    continue
                box = (tx * 8, ty * 8, tx * 8 + 8, ty * 8 + 8)
                if shot.crop(box).tobytes() != model.crop(box).tobytes():
                    bad += 1
        out.append({'type': t, 'mode': mode, 'cell': grid[scr], 'stairs_here': scr == stair,
                    'bad_tiles': bad, 'masked_tiles': len(spr)})
    p.stop()
    return {'screens': len(out), 'with_differences': sum(1 for o in out if o['bad_tiles']),
            'stairs_screens': sum(1 for o in out if o['stairs_here']),
            'types': sorted({o['type'] for o in out})}


def selftest():
    if not os.path.exists(ROM_PATH):
        print('SKIP: no ROM')
        return 0
    rom = open(ROM_PATH, 'rb').read()
    d = json.load(open(OUT))
    cat = json.loads(json.dumps(catalogue(rom)))
    ok = all(d.get(k) == v for k, v in cat.items())
    print(('OK' if ok else 'FAIL') + f": maze_pieces.json == ROM ({len(cat['pieces'])} screens, "
          f"{len(cat['themes'])} themes, {cat['metatiles']} metatiles)")
    return 0 if ok else 1


def main():
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    rom = open(ROM_PATH, 'rb').read()
    if hashlib.md5(rom).hexdigest() != ORIGINAL_MD5:
        sys.exit('ERROR: data/DWM-original.gbc is not the original ROM')
    n = 4000
    if '--floors' in sys.argv:
        n = int(sys.argv[sys.argv.index('--floors') + 1])
    if '--negative' in sys.argv:
        r = floors_census(min(n, 300), negative=True)
        print(f"NEGATIVE CONTROL: {r['floors']} floors, {r['mismatches']} mismatches "
              f"{r['by_field']} ({'OK: the broken model fails' if r['mismatches'] else 'FAIL: not detected'})")
        sys.exit(0 if r['mismatches'] else 1)
    fl = floors_census(n)
    print(f"floors: {fl['floors']}, mismatches {fl['mismatches']} {fl['by_field']}, "
          f"modes {fl['shape_modes']}, regenerated {fl['regenerated']}, "
          f"items {fl['items']}, npcs {fl['npcs']}")
    for inp, diff in fl['first_bad']:
        print('  first bad:', inp, diff)
    sc = screens_census()
    print(f"screens: {sc['screens']} ({len(sc['types'])} types, {sc['stairs_screens']} with the "
          f"stairs), {sc['with_differences']} differ from the model")
    fz = freeze_probe()
    print(f"freeze probe (size 2, seed $8192): builder finished = {fz['builder_finished']}, "
          f"grid all empty = {fz['grid_all_empty']} ({fz['frames']} frames)")
    sw = carve_sweep()
    print('carve by size: ' + ', '.join(f"{k}: {v['empty']} empty / {v['split']} split"
                                       for k, v in sw.items()))
    data = {'_generator': ('tools/census_maze.py (S122) from data/DWM-original.gbc '
                           f'{ORIGINAL_MD5}: tables read from banks $16/$17/ROM0 by '
                           'editor2/core/maze.py; census = PyBoy (floors forced at '
                           '$16:$605B, read at $16:$63AC; screens = arrivals pixel by pixel)'),
            **catalogue(rom),
            'samples': fl['samples'],
            'census': {'floors': {k: v for k, v in fl.items() if k not in ('first_bad', 'samples')},
                       'screens': sc, 'freeze_probe': fz, 'carve_by_size': sw}}
    with open(OUT, 'w') as f:
        json.dump(data, f, indent=1)
        f.write('\n')
    print(f'wrote {OUT}')
    sys.exit(0 if not fl['mismatches'] and not sc['with_differences'] else 1)


if __name__ == '__main__':
    main()
