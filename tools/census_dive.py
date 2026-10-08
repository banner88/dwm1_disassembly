#!/usr/bin/env python3
"""census_dive.py — random battles per gate maze floor, from the game's own
data (S130, the Balance service's "gate dive"; GATE_GENERATION §4.4).

Writes extracted/dive_census.json, read by editor2/core/dive.py (no ROM at
runtime):

  python3 tools/census_dive.py              # census (+ the PyBoy measure when PyBoy is there)
  python3 tools/census_dive.py --floors N   # N floors per maze size (default 1000)
  python3 tools/census_dive.py --measure    # only the PyBoy walk check, print it
  python3 tools/census_dive.py --measure-specials   # only the special rooms' PyBoy walk (S131)
  python3 tools/census_dive.py --selftest   # JSON == a re-derived sample (verifier check 5)

CENSUS: for maze sizes 3-15, N floors each from random RNG states / contents
rows / $CAB4 / $C92D (as census_maze.py) through maze.MazeRom.generate (==
the game, census_maze.py); dive.walk_path = the shortest walk arrival ->
stairs over the cells whose bottom-right tile is >= $30. Then the expected
battles of every (size, floor type, rate code) = the mean over the walks of
dive.expected_battles (EncounterRateData x EncounterRateModifierTable,
RandomEncounterCounterTable — the renewal at floor entry and after each
battle).

MEASURE (PyBoy, original ROM): a new game enters gate 0; on every maze floor
wCurrentFloor := 0 (the next floor is never a special room or the boss),
wGateID := 0 / 22 / 5 (lists of rate code 3 / 2 / 4) and the NEXT floor's
type is forced at $16:$5BD2 (MEASURE_PLAN: 12 floors, 11 types). The tool
reads the grid / shape mode / stairs / items the game built and the
player's cell, walks the shortest walk with the joypad (re-planned from the
real cell after every step; the encounter counter pinned high so no battle
starts) and records every EncounterStep ($16:$6F05: $FFAA), every drain it
stores ($16:$6FA2: DE) and every SetRandomEncounterCounter ($16:$6E14).
Checked per floor: the stairs are reached (the next floor loads); over the
cells actually entered, each drained step's class and drain == the model
(EncounterRateData[type][class] x RateMod[code] // 64), screen-edge steps
and the stairs step store nothing, a picked-up item cell runs no
EncounterStep; one counter seed per floor load and none while walking.

SPECIALS (S131, ROADMAP P3.15b (2)): the walkable special rooms — the forest
maze ($53 + $61-$64, five rooms joined by edge exits), Maze 1-3 ($57-$59),
Conveyor maze 1-3 ($54-$56) — walked in their own rooms: dive.special_room
reads each room's cells / exits from the ROM (editor2/core/render_project),
dive.special_walk is the shortest walk spawn -> stairs (belts ride, edge
exits push, a room change re-seeds), the drain is EncounterStep's flat
outside-gate base (100, conveyors 80) x RateMod // 64 on every cell. The
PyBoy check (--measure-specials, part of the full run) walks all 7 variants.
"""
import hashlib
import json
import os
import random
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
ROM_PATH = os.path.join(REPO, 'data', 'DWM-original.gbc')
OUT = os.path.join(REPO, 'extracted', 'dive_census.json')
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'
SEED = 131
N_DEFAULT = 1000
SELFTEST_FLOORS = 40          # per size, re-derived by --selftest
SELFTEST_CELLS = 24           # battle-table cells recomputed by --selftest

RATE_DATA = (0x16, 0x6FAB)    # EncounterRateData
RATE_MOD = (0x16, 0x702B)     # EncounterRateModifierTable
SEEDS = (0x16, 0x6E3D)        # RandomEncounterCounterTable
STEP_ENTRY = (0x16, 0x6F05)   # EncounterStep
STEP_STORE = (0x16, 0x6FA2)   # jr_016_6fa2: the drained counter is stored (DE = drain)
SEED_ENTRY = (0x16, 0x6E14)   # SetRandomEncounterCounter
TYPE_HOOK = (0x16, 0x5BD2)    # S120: right after the maze path's SelectFloorType (A = type)
# (gate whose list sets the rate code, floor type forced on the NEXT floor):
# gate 0 lists = code 3 (size 8), gate 22 = code 2 (size 15), gate 5 = code 4 (size 3)
MEASURE_PLAN = [(0, 15), (22, 2), (5, 11), (0, 3), (22, 9), (5, 13), (0, 12), (22, 0),
                (5, 6), (0, 14), (22, 11), (5, 2)]


def _b(rom, bank, addr, n):
    o = bank * 0x4000 + addr - 0x4000
    return rom[o:o + n]


def rom_tables(rom):
    rd = _b(rom, *RATE_DATA, 128)
    return {'rate_data': [[rd[8 * t + 2 * c] | rd[8 * t + 2 * c + 1] << 8 for c in range(3)]
                          for t in range(16)],
            'rate_mod': list(_b(rom, *RATE_MOD, 8)),
            'counter_seeds': [[r[0], r[2] | r[3] << 8] for r in
                              (_b(rom, SEEDS[0], SEEDS[1] + 4 * i, 4) for i in range(50))]}


def sample_inputs(size, n):
    rnd = random.Random(SEED * 100 + size)
    return [(rnd.randrange(65536), rnd.randrange(16), rnd.randrange(4), rnd.randrange(8))
            for _ in range(n)]


def walk_sample(mz, size, n):
    from editor2.core import dive as DV
    out = []
    for s, cr, pr, ns in sample_inputs(size, n):
        fl = mz.generate(s, size, cr, pr, ns)
        w = DV.walk_path(mz, fl)
        out.append((w['steps'], w['path'], w['reachable']))
    return out


def size_summary(rows):
    n = len(rows)
    by = [sum(p.count(ch) for _s, p, _r in rows) / n for ch in 'abc']
    cnt = {}
    for _s, p, _r in rows:
        cnt[p] = cnt.get(p, 0) + 1
    return {'n': n,
            'steps': round(sum(s for s, _p, _r in rows) / n, 3),
            'drained': round(sum(by), 3),
            'edges': round(sum(p.count('-') for _s, p, _r in rows) / n, 3),
            'items': round(sum(p.count('i') for _s, p, _r in rows) / n, 3),
            'by_class': [round(x, 3) for x in by],
            'min': min(s for s, _p, _r in rows), 'max': max(s for s, _p, _r in rows),
            'reachable': round(sum(r for _s, _p, r in rows) / n, 1),
            'paths': ','.join(sorted(p for _s, p, _r in rows))}


def paths_of(s):
    """A size's 'paths' (comma-joined walks) -> [(path, count)]."""
    from editor2.core import dive as DV
    return DV.parse_paths(s['paths'])


def battle_cell(paths, drain3, F):
    from editor2.core import dive as DV
    n = sum(k for _p, k in paths)
    return sum(DV.expected_battles(p, drain3, F) * k for p, k in paths) / n


def battle_table(sizes, tables):
    """{size: [16 types][8 codes]} — one expected_battles pass per distinct
    drain triple."""
    from editor2.core import dive as DV
    F = DV._cdf_fn(cdf_of(tables))
    out = {}
    for size, s in sizes.items():
        memo = {}
        rows = []
        for t in range(16):
            row = []
            for code in range(8):
                d3 = tuple(b * tables['rate_mod'][code] // 64 for b in tables['rate_data'][t])
                if d3 not in memo:
                    memo[d3] = round(battle_cell(paths_of(s), d3, F), 4)
                row.append(memo[d3])
            rows.append(row)
        out[size] = rows
    return out


def cdf_of(tables):
    prev, run, out = -1, 0, []
    for thr, val in tables['counter_seeds']:
        hi = min(thr, 100)
        k = max(0, hi - prev)
        prev = max(prev, hi)
        if k:
            run += k
            out.append((val, run / 101.0))
        if hi >= 100:
            break
    return out


def steps_between_table(tables):
    """[16 types][8 codes] exact mean steps re-seed -> battle on class-$0C
    cells (no screen edges)."""
    out = []
    cdf = cdf_of(tables)
    for t in range(16):
        row = []
        for code in range(8):
            d = tables['rate_data'][t][0] * tables['rate_mod'][code] // 64
            prev = tot = 0.0
            for val, p in cdf:
                tot += (p - prev) * (val // d + 1)
                prev = p
            row.append(round(tot, 2))
        out.append(row)
    return out


# ---------------------------------------------------------------------------
# PyBoy: walk the shortest path on real floors
# ---------------------------------------------------------------------------

def measure(n_floors=6):
    from tools.pyboy_harness import boot, to_bedroom, adv
    from editor2.core import maze as MZ
    from editor2.core import dive as DV
    rom = open(ROM_PATH, 'rb').read()
    mz = MZ.MazeRom(rom)
    tab = rom_tables(rom)
    p = boot(ROM_PATH)
    if not to_bedroom(p):
        raise SystemExit('the new game did not reach the bedroom')
    adv(p, 200)
    mem = p.memory
    ev = []
    p.hook_register(*STEP_ENTRY, lambda _: ev.append(('E', mem[0xFFAA] >> 2)), None)
    p.hook_register(*STEP_STORE, lambda _: ev.append(('D', p.register_file.D << 8 | p.register_file.E)),
                    None)
    p.hook_register(*SEED_ENTRY, lambda _: ev.append(('S',)), None)
    want_type = [None]

    def force_type(_):
        if want_type[0] is not None:
            p.register_file.A = want_type[0]
    p.hook_register(*TYPE_HOOK, force_type, None)

    def pin():
        mem[0xCA39], mem[0xCA3A] = 0x00, 0x70

    def tick(k=1):
        for _ in range(k):
            pin()
            p.tick()

    def settle_floor(timeout=2500):
        for _ in range(timeout):
            tick()
            if mem[0xC969] == 1 and mem[0xC88A] == 1 and not (mem[0xC8EB] & 0x67):
                tick(30)
                return True
        return False

    mem[0xD8D7] = 0
    mem[0xC96D], mem[0xC96E], mem[0xC96C], mem[0xC88F] = 0, 1, 1, 1   # gate 0 (type 13)
    tick(300)
    results = []
    for _f in range(n_floors):
        if not settle_floor():
            results.append({'error': 'no maze floor'})
            break
        gate, nxt = MEASURE_PLAN[_f % len(MEASURE_PLAN)]
        mem[0xC939] = 0                        # wCurrentFloor: the next floor is 2 (never
        mem[0xC935] = gate                     # a special, never the boss); wGateID: the list
        want_type[0] = nxt
        floor_no = mem[0xC939]
        tick(2)
        fl = {'grid': [mem[0xC940 + i] for i in range(16)], 'mode': mem[0xC93F]}
        st = mem[0xC960]
        ox, oy = DV._origin(mz, st)
        fl['stairs'] = (st, (mem[0xC964] | mem[0xC965] << 8) - ox * 160,
                        (mem[0xC966] | mem[0xC967] << 8) - oy * 128)
        items = []
        a = 0xD793
        while mem[a] != 0xFF and len(items) < 40:          # [kind, sub, X, Y] absolute cells
            items.append({'kind': mem[a], 'screen': (mem[a + 3] // 8) * 4 + mem[a + 2] // 10,
                          'x': (mem[a + 2] % 10) * 16 + 8, 'y': (mem[a + 3] % 8) * 16 + 8})
            a += 4
        fl['items'] = items
        cells = DV.floor_cells(mz, fl)
        goal = DV.cell_of(mz, *fl['stairs'])
        pick = {DV.cell_of(mz, it['screen'], it['x'], it['y']) for it in items
                if not it['kind'] & 0xF8}

        def at(c):
            return (c[0] // 10 + 4 * (c[1] // 8), (c[0] % 10) * 16 + 8, (c[1] % 8) * 16 + 8)
        pos = (mem[0xFF97], mem[0xFF98])
        fl['arrival'] = at(pos)
        w = DV.walk_path(mz, fl, cells)
        ftype, size = mem[0xC968], mem[0xC93D]
        if results:
            results[-1]['seeds_to_next_floor'] = sum(1 for e in ev if e[0] == 'S')
        ev.clear()
        facing, retries, entered, ok = None, 0, [], True
        while pos != goal and len(entered) < 4 * w['steps'] + 10:
            nxt_cell = DV.walk_path(mz, dict(fl, arrival=at(pos)), cells)['cells'][0]
            d = {(1, 0): 'right', (-1, 0): 'left', (0, 1): 'down', (0, -1): 'up'}[
                (nxt_cell[0] - pos[0], nxt_cell[1] - pos[1])]
            if d != facing:                    # a tap in a new direction only turns
                p.button_press(d)
                tick(2)
                p.button_release(d)
                tick(20)
                facing = d
            moved = False
            for attempt in range(4):
                if attempt:                    # a text box (an item picked up) or the NPC
                    retries += 1               # in the way: close it, wait, try again
                    for _ in range(3):
                        p.button_press('b')
                        tick(3)
                        p.button_release('b')
                        tick(30)
                p.button_press(d)
                tick(2)
                p.button_release(d)
                for _ in range(60):
                    tick()
                    q = (mem[0xFF97], mem[0xFF98])
                    if q != pos or mem[0xC939] != floor_no:
                        moved = True
                        break
                if moved:
                    break
            if not moved:
                ok = False
                break
            if mem[0xC939] != floor_no:
                entered.append(goal)
                pos = goal
                break
            entered.append(q)
            pos = q
            if pos == goal:
                break
            for _ in range(90):
                tick()
                if not (mem[0xC8EB] & 0x04):
                    break
            tick(4)
        reached = mem[0xC939] != floor_no
        for _ in range(900):                   # the stairs: the next floor loads
            if reached:
                break
            tick()
            reached = mem[0xC939] != floor_no
        # the game's checks: E = EncounterStep ($FFAA class), D = the drain it stored
        got, k = [], 0
        steps = [e for e in ev if e[0] in 'ED']
        while k < len(steps):
            e = steps[k]
            if e[0] == 'E':
                if k + 1 < len(steps) and steps[k + 1][0] == 'D':
                    got.append((e[1], steps[k + 1][1]))
                    k += 2
                    continue
                got.append((e[1], None))
            k += 1
        code = mem[0xC8A9]
        # the model over the cells actually entered
        want, taken = [], set()
        last = DV.cell_of(mz, *fl['arrival'])
        for c in entered:
            if c[0] // 10 != last[0] // 10 or c[1] // 8 != last[1] // 8:
                want.append((cells[c[1]][c[0]] >> 2, None))      # EncounterStep returns at once
            elif c in pick and c not in taken:
                taken.add(c)                                       # picked up: no EncounterStep
            elif c == goal:
                want.append((0x0F, None))                          # the stairs: no check
            else:
                cl = cells[c[1]][c[0]] >> 2
                want.append((cl, tab['rate_data'][ftype][cl - 0x0C] * tab['rate_mod'][code] // 64))
            last = c
        same = [(g[1] is None) == (x[1] is None) and (g[1] is None or g == x)
                for g, x in zip(got, want)]
        results.append({'gate': gate, 'type': ftype, 'rate_code': code, 'size': size,
                        'shortest': w['steps'], 'walked_steps': len(entered),
                        'path': w['path'], 'walked': ok, 'reached_stairs': reached,
                        'retries': retries,
                        'drains_equal_model': len(got) == len(want) and all(same),
                        **({} if len(got) == len(want) and all(same) else
                           {'got': got, 'want': want})})
    p.stop()
    return results


# ---------------------------------------------------------------------------
# S131: the walkable special rooms (forest maze, mazes, conveyor mazes)
# ---------------------------------------------------------------------------
SPECIAL_ENTRY = (0x16, 0x5BBF)   # the maze path (jr_016_5bbf) -> PC := the special path
SPECIAL_PATH = 0x5C1C            # jr_016_5c1c
SPECIAL_PICK = (0x16, 0x5C2E)    # right after the special path's SelectFloorType (A = pick)
SPECIAL_VARIANT = ((0x16, 0x5ED8), (0x16, 0x5F4C))   # SpecialRoom6_Maze / 7_Conveyor: wRNG1 mod 3
MEASURE_SPECIALS = [(2, 0), (6, 0), (6, 1), (6, 2), (7, 0), (7, 1), (7, 2)]


def special_census(rom, tables):
    """{pick: {'variants', 'battles' [8 codes], 'sweep' [8 codes]}} from the
    ROM's room data (dive.special_variants) and the counter tables."""
    from editor2.core import dive as DV
    from editor2.core.render_project import ProjectRenderer
    R = ProjectRenderer(REPO, None, {'custom': {}})
    F = DV._cdf_fn(cdf_of(tables))
    out = {}
    for pick, vs in DV.special_variants(R).items():
        bat, swp = [], []
        for code in range(8):
            b = s = 0.0
            for v in vs:
                base = DV.CONVEYOR_BASE if v['map'] in DV.CONVEYOR_MAPS else DV.SPECIAL_BASE
                d = base * tables['rate_mod'][code] // 64
                e = DV.expected_battles(v['path'], (d, d, d), F)
                b += v['p'] * e
                s += v['p'] * e * v['reachable'] / max(1.0, v['steps'])
            bat.append(round(b, 4))
            swp.append(round(s, 4))
        out[str(pick)] = {'name': DV.SPECIAL_NAMES[pick], 'variants': vs, 'battles': bat, 'sweep': swp}
    return out


def measure_specials(cases=MEASURE_SPECIALS):
    """PyBoy, original ROM: new game -> gate 1 floor 1; the next floor is forced
    to special room `pick` (variant by wRNG1) and walked with the joypad along
    dive.special_walk (re-planned from the real cell after every step; the
    counter pinned high); every EncounterStep / drain / counter seed logged and
    compared with the model's path ('a' = drained by the room's flat drain,
    '-' / 'x' / 'p' = an EncounterStep that stores nothing, '|' = a seed)."""
    from tools.pyboy_harness import boot, to_bedroom, adv
    from editor2.core import dive as DV
    from editor2.core.render_project import ProjectRenderer
    R = ProjectRenderer(REPO, None, {'custom': {}})
    rooms = {}

    def load(m):
        if m not in rooms:
            rooms[m] = DV.special_room(R, m)
        return rooms[m]
    tab = rom_tables(open(ROM_PATH, 'rb').read())
    results = []
    for pick, var in cases:
        p = boot(ROM_PATH)
        if not to_bedroom(p):
            raise SystemExit('the new game did not reach the bedroom')
        adv(p, 200)
        mem = p.memory
        force = [False]

        def to_special(_):
            if force[0]:
                p.register_file.PC = SPECIAL_PATH

        def set_pick(_, k=pick):
            if force[0]:
                p.register_file.A = k

        def set_var(_, v=var):
            if force[0]:
                mem[0xC899] = v
        p.hook_register(*SPECIAL_ENTRY, to_special, None)
        p.hook_register(*SPECIAL_PICK, set_pick, None)
        for h in SPECIAL_VARIANT:
            p.hook_register(*h, set_var, None)
        ev = []
        p.hook_register(*STEP_ENTRY, lambda _: ev.append(('E', mem[0xC968])), None)
        p.hook_register(*STEP_STORE, lambda _: ev.append(('D', p.register_file.D << 8 | p.register_file.E)),
                        None)
        p.hook_register(*SEED_ENTRY, lambda _: ev.append(('S',)), None)

        def tick(k=1):
            for _ in range(k):
                mem[0xCA39], mem[0xCA3A] = 0x00, 0x70
                p.tick()
        mem[0xD8D7] = 0
        mem[0xC96D], mem[0xC96E], mem[0xC96C], mem[0xC88F] = 1, 1, 1, 1    # gate 1, floor 1
        tick(1400)
        force[0] = True
        mem[0xC96D], mem[0xC96E], mem[0xC96C] = 0, 0x80, 1                # the stairs kick
        mem[0xC88F] = (mem[0xC88F] + 1) & 0xFF
        tick(1400)
        force[0] = False

        def st():
            return (mem[0xC968], (mem[0xFF97], mem[0xFF98]))
        s0, floor0, code = st(), mem[0xC939], mem[0xC8A9]
        model = DV.special_walk(load, *s0)
        ev.clear()
        ok = True
        for _it in range(500):
            s = st()
            if mem[0xC939] != floor0:
                break
            try:
                d = DV.special_walk(load, *s)['first']
            except ValueError:
                ok = False
                break
            if d:
                p.button_press(d)
                tick(2)
                p.button_release(d)
            for _ in range(80):
                tick()
                if st() != s or mem[0xC939] != floor0:
                    break
            if st()[0] != s[0] and mem[0xC939] == floor0:
                tick(420)                     # a room change: the fade, then the new cell
            for _ in range(90):
                tick()
                if not (mem[0xC8EB] & 0x04):
                    break
            tick(2)
        for _ in range(900):
            if mem[0xC939] != floor0:
                break
            tick()
        reached = mem[0xC939] != floor0
        got = []
        for e in ev:
            if e[0] == 'E':
                got.append([e[1], None])
            elif e[0] == 'D' and got:
                got[-1][1] = e[1]
            elif e[0] == 'S':
                got.append(None)
        if got and got[-1] is None and reached:
            got.pop()                         # the next floor's own seed
        g = ''.join('|' if x is None else ('-' if x[1] is None else
                    ('a' if x[1] == DV.special_drain(x[0], code) else '?')) for x in got)
        want = model['path'].replace('x', '-').replace('p', '-')
        results.append({'pick': pick, 'variant': var, 'map': s0[0], 'spawn': list(s0[1]),
                        'rate_code': code, 'model_steps': model['steps'], 'walked': ok,
                        'reached_stairs': reached, 'game': g, 'equal_model': g == want,
                        **({} if g == want else {'model': want})})
        p.stop()
    del tab
    return results


def build(n):
    from editor2.core import maze as MZ
    rom = open(ROM_PATH, 'rb').read()
    if hashlib.md5(rom).hexdigest() != ORIGINAL_MD5:
        sys.exit('ERROR: data/DWM-original.gbc is not the original ROM')
    mz = MZ.MazeRom(rom)
    tables = rom_tables(rom)
    sizes = {}
    for size in range(3, 16):
        sizes[str(size)] = size_summary(walk_sample(mz, size, n))
        s = sizes[str(size)]
        print(f"size {size:2}: steps {s['steps']:6.2f} (min {s['min']}, max {s['max']}), "
              f"drained {s['drained']:6.2f} {s['by_class']}, edges {s['edges']:.2f}, "
              f"reachable {s['reachable']}")
    return {
        '_generator': (f'tools/census_dive.py (S130) from data/DWM-original.gbc {ORIGINAL_MD5}: '
                       f'editor2/core/maze.py MazeRom.generate x {n} floors per maze size 3-15 '
                       f'(random.Random({SEED}*100 + size): RNG state, contents row, $CAB4, $C92D), '
                       'dive.walk_path (shortest walk arrival -> stairs, cells with BR tile >= $30), '
                       'dive.expected_battles over EncounterRateData $16:$6FAB x '
                       'EncounterRateModifierTable $16:$702B x RandomEncounterCounterTable $16:$6E3D. '
                       'S131: specials = the forest maze / mazes / conveyor mazes walked in their own '
                       'rooms (dive.special_variants: room data from the ROM, belts, edge exits, the '
                       'outside-gate flat drain, a re-seed per room change). '
                       'Read by editor2/core/dive.py; --selftest re-derives a sample.'),
        'floors_per_size': n,
        'path_chars': {'format': 'sizes[n].paths = every walk of the sample, comma-joined, sorted; '
                                 'specials[pick].variants[k].path = that room\'s shortest walk',
                       'a': 'drained step onto class $0C ($30-$33)',
                       'b': 'drained step onto class $0D ($34-$37)',
                       'c': 'drained step onto class $0E ($38-$3B)',
                       '-': 'screen-edge step (no drain: wGameState bit 2)',
                       'i': 'step onto a floor item that is picked up (no drain: EncounterStep not reached)',
                       'x': 'specials: the step onto a walk-on exit (EncounterStep runs, no drain)',
                       'p': 'specials: a push into an edge exit (EncounterStep runs, no drain)',
                       '|': 'specials: a room change (the room loads, the counter is re-seeded)',
                       'note': 'maze floors: the final step onto the stairs ($0F, no check) is in steps, '
                               'not in the path'},
        'tables': tables,
        'sizes': sizes,
        'battles': battle_table(sizes, tables),
        'steps_between': steps_between_table(tables),
        'specials': special_census(rom, tables),
    }


def selftest():
    if not os.path.exists(ROM_PATH):
        print('SKIP: no ROM')
        return 0
    if not os.path.exists(OUT):
        print('FAIL: extracted/dive_census.json missing (run tools/census_dive.py)')
        return 1
    from editor2.core import maze as MZ
    from editor2.core import dive as DV
    rom = open(ROM_PATH, 'rb').read()
    if hashlib.md5(rom).hexdigest() != ORIGINAL_MD5:
        print('SKIP: data/DWM-original.gbc is not the original ROM')
        return 0
    d = json.load(open(OUT))
    bad = []
    tables = rom_tables(rom)
    if d['tables'] != json.loads(json.dumps(tables)):
        bad.append('tables != ROM')
    mz = MZ.MazeRom(rom)
    for size in range(3, 16):
        s = d['sizes'][str(size)]
        stored = dict(paths_of(s))
        if sum(stored.values()) != d['floors_per_size'] or s['n'] != d['floors_per_size']:
            bad.append(f'size {size}: path counts')
        want = {}
        for _st, p, _r in walk_sample(mz, size, SELFTEST_FLOORS):
            want[p] = want.get(p, 0) + 1
        for p, k in want.items():
            if stored.get(p, 0) < k:
                bad.append(f'size {size}: re-derived walk {p!r} not in the census')
                break
        rows = [(len(p) + 1, p, 0) for p, k in paths_of(s) for _ in range(k)]
        summ = size_summary(rows)
        for key in ('steps', 'drained', 'edges', 'items', 'by_class', 'min', 'max'):
            if summ[key] != s[key]:
                bad.append(f'size {size}: {key} {summ[key]} != {s[key]}')
    F = DV._cdf_fn(cdf_of(tables))
    rnd = random.Random(SEED)
    for _ in range(SELFTEST_CELLS):
        size, t, code = rnd.randrange(3, 16), rnd.randrange(16), rnd.randrange(8)
        d3 = tuple(b * tables['rate_mod'][code] // 64 for b in tables['rate_data'][t])
        v = round(battle_cell(paths_of(d['sizes'][str(size)]), d3, F), 4)
        if abs(v - d['battles'][str(size)][t][code]) > 1e-9:
            bad.append(f'battles size {size} type {t} code {code}: {v} != stored')
    if d['steps_between'] != steps_between_table(tables):
        bad.append('steps_between != ROM tables')
    if d.get('specials') != json.loads(json.dumps(special_census(rom, tables))):
        bad.append('specials != re-derived (room data / walks / battles)')
    if bad:
        for b in bad[:10]:
            print('FAIL:', b)
        return 1
    print(f'OK: dive_census.json == ROM tables; {SELFTEST_FLOORS} floors x 13 maze sizes '
          f're-derived (walks in the census, summaries consistent); {SELFTEST_CELLS} battle cells recomputed; '
          f'{len(d["specials"])} special rooms re-derived')
    return 0


def main():
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    if '--measure-specials' in sys.argv:
        for r in measure_specials():
            print(r)
        return
    if '--measure' in sys.argv:
        for r in measure(int(sys.argv[sys.argv.index('--measure') + 1])
                         if len(sys.argv) > sys.argv.index('--measure') + 1 else 6):
            print(r)
        return
    n = N_DEFAULT
    if '--floors' in sys.argv:
        n = int(sys.argv[sys.argv.index('--floors') + 1])
    out = build(n)
    try:
        import pyboy  # noqa: F401
        ms = measure(len(MEASURE_PLAN))
        out['measured'] = {
            'how': ('PyBoy, original ROM, new game -> gate 0; on each maze floor wCurrentFloor := 0 '
                    '(no special / boss next), wGateID := 0 / 22 / 5 (lists of rate code 3 / 2 / 4) and '
                    'the next floor type forced at $16:$5BD2; the shortest walk walked with the joypad, '
                    'counter pinned high; '
                    'EncounterStep $16:$6F05 / the store $16:$6FA2 (DE = drain) / '
                    'SetRandomEncounterCounter $16:$6E14 hooked'),
            'floors': ms,
            'all_ok': all(m.get('walked') and m.get('reached_stairs') and m.get('drains_equal_model')
                          and m.get('seeds_to_next_floor', 1) == 1 for m in ms)}
        print('measured:', out['measured']['all_ok'])
        for m in ms:
            print('  ', m)
        sp = measure_specials()
        out['measured_specials'] = {
            'how': ('PyBoy, original ROM, new game -> gate 1 floor 1; the next floor forced to the '
                    'special path (hook $16:$5BBF -> PC $5C1C), the pick at $16:$5C2E, the variant '
                    'by wRNG1 at SpecialRoom6_Maze / 7_Conveyor; dive.special_walk walked with the '
                    'joypad (re-planned after every step, the counter pinned high), every '
                    'EncounterStep / drain store / counter seed compared with the path'),
            'rooms': sp,
            'all_ok': all(r['walked'] and r['reached_stairs'] and r['equal_model'] for r in sp)}
        print('measured specials:', out['measured_specials']['all_ok'])
        for r in sp:
            print('  ', r)
    except ImportError:
        print('PyBoy not installed: no measurement')
    with open(OUT, 'w') as f:
        json.dump(out, f, indent=1)
        f.write('\n')
    print('wrote', OUT)


if __name__ == '__main__':
    main()
