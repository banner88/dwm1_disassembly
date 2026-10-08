"""dive.py — how many RANDOM BATTLES a gate floor costs (the Balance service's
"gate dive": a gate's maze floors walked in a row without healing, then the
boss). GATE_GENERATION §4.4 "Walking a floor" owns the facts; numbers come
from extracted/dive_census.json (tools/census_dive.py, from the ORIGINAL ROM).

Headless, no Qt, no ROM needed at runtime (the JSON carries the walks).

THE WALK (steps per floor). editor2/core/maze.py generates a floor exactly as
the game does (census_maze.py: 4,000 floors == PyBoy). The floor is one
40 x 32 grid of 16-px cells (4 x 4 screens of 10 x 8, `ScreenOriginTable`);
a cell is walkable when its BOTTOM-RIGHT 8x8 tile id >= $30 (the gate
sheets' collision threshold; ROOM_DATA_FORMAT "the bottom-right subtile
decides"); the down-stairs cell is stamped $3C-$3F. `walk_path` = the
SHORTEST walk (BFS, 4-neighbour, one step = one cell) from the arrival cell to
the stairs. Floor items are not obstacles: the blocking kinds (chests) are
opened in place and then skipped by the collision test (bank $01
RetIfNotGateworld ignores entries with bit 7 set). A real player explores, so
the shortest walk is a LOWER bound; no "realistic" factor is applied (the
game data gives none — `reachable` = walkable cells reachable from the
arrival is kept as the full-sweep upper reference).

THE DRAIN (measured, census_dive.py --measure, PyBoy on the original ROM):
bank $16 EncounterStep runs once per step; on a gate floor the drain is
    EncounterRateData[floor type][class - $0C] * RateMod[list rate code] // 64
with class = (tile id of the ENTERED cell) >> 2 — $0C / $0D / $0E (floor /
the $34-$37 tiles / the $38-$3B tiles); the stairs cell ($0F) has no check.
A step that CROSSES A SCREEN EDGE never drains (the scroll sets wGameState
bit 2 and EncounterStep returns at once), nor does a step onto a floor item
that is picked up (gold / an item: kinds with no $F8 bits — EncounterStep is
not reached on that step). A battle fires on the step whose
drain borrows (counter < drain); the counter is re-seeded
(`RandomEncounterCounterTable`, 1,100-6,000) at every room load: floor entry
and the reload after each battle. So a floor is a renewal process over its
drain sequence; `expected_battles` sums P(a battle on step k) exactly.

SPECIAL ROOMS (S131): floors 3 / 6 / 9 of gates other than 0 are a special
room half the time; the forest maze ($53 + $61-$64), Maze 1-3 ($57-$59) and
Conveyor maze 1-3 ($54-$56) are walked as their own rooms (special_room /
special_walk / special_battles; the walks in dive_census.json 'specials'):
every cell entered drains a flat 100 (conveyors 80) x RateMod // 64, belts ride
(every cell ridden is a step), edge exits fire on a push, walk-on exits and
pushes drain nothing, a room change re-seeds the counter — PyBoy 7 / 7 rooms ==
the model (GATE_GENERATION §4.4 "Special rooms (S131)").

Path strings (JSON, comma-joined per maze size): one char per step after the arrival — 'a' / 'b' / 'c' =
a drained step onto class $0C / $0D / $0E, '-' = a screen-edge step (no
drain), 'i' = a step onto a picked-up floor item (no drain); the final step onto the stairs is not written (no check) but is in
`steps`.
"""

import json
import os
from collections import deque

CENSUS_JSON = os.path.join('extracted', 'dive_census.json')
SIZES = range(3, 16)            # maze sizes the editor accepts (GATE_GENERATION §4.2)
WALL_BELOW = 0x30               # gate sheets' collision threshold (ROM0 $2A5D +6)
STAIRS_TILE = 0x3F              # bottom-right tile of the stamped stairs
CLASS_CHAR = {0x0C: 'a', 0x0D: 'b', 0x0E: 'c'}
CROSS = '-'
ITEM = 'i'
NO_DRAIN = (CROSS, ITEM, 'x', 'p')   # S131: 'x' = onto a walk-on exit, 'p' = a push into an edge exit
GRID_W, GRID_H = 40, 32
SPECIAL_EVERY = 3               # specials only on floors 3, 6, 9 … (wCurrentFloor mod 3 == 2)
SPECIAL_CHANCE = 0.5            # … when wRNG1 bit 4 is set (GATE_GENERATION §3)
SPECIAL_RANDOM_BATTLES = (2, 6, 7)   # forest maze $53, mazes $57-$59, conveyors $54-$56
SPECIAL_NAMES = ['treasure', 'one rare chest', 'forest maze', 'priest', 'item shop',
                 'coliseum', 'maze', 'conveyor maze']
# S131 (ROADMAP P3.15b (2)): the walkable specials as their own rooms. The bank $16
# handlers (SpecialRoom2_ForestMaze / 6_Maze / 7_Conveyor) set wMapID + the spawn
# pixel; mazes / conveyors pick the variant by wRNG1 mod 3 (0 / 1 / 2 = 86 / 85 / 85
# of 256). Spawn cells = (pixel - 8) // 16.
SPECIAL_ROOMS = {
    2: [(0x53, (4, 6), 1.0)],
    6: [(0x57, (15, 11), 86 / 256), (0x58, (1, 2), 85 / 256), (0x59, (1, 2), 85 / 256)],
    7: [(0x54, (13, 13), 86 / 256), (0x55, (4, 22), 85 / 256), (0x56, (14, 11), 85 / 256)],
}
# EncounterStep outside gates (wInGateworld 0): a flat base for every cell —
# $50 on the conveyor maps $54-$56, else $64 (bank $16 `EncounterStep`)
SPECIAL_BASE = 100
CONVEYOR_BASE = 80
CONVEYOR_MAPS = (0x54, 0x55, 0x56)
# belts (bank $01 `ConveyorBeltPush`, CheckGateworldField): the standing cell's class
# $AA >> 2 sets a forced velocity — $0F right, $10 left, $11 down, $12 up (PyBoy S131:
# the player rides until a non-belt cell; every cell ridden is an ordinary step)
BELT_DIR = {0x0F: (1, 0), 0x10: (-1, 0), 0x11: (0, 1), 0x12: (0, -1)}
ROOM_LOAD = '|'                 # a room change: the room loads, the counter is re-seeded
EXIT_STEP = 'x'                 # the step onto a walk-on exit cell: EncounterStep runs with
#                                 wGameState bit 5 set (the transition) -> no drain (PyBoy S131)
PUSH_STEP = 'p'                 # a push into an edge exit (rows 0 / 7): EncounterStep runs, no
#                                 drain, then the room loads (PyBoy S131)

_CACHE = {}


def _root(repo):
    if repo:
        return repo
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# ---------------------------------------------------------------------------
# the walk (used by tools/census_dive.py; needs a maze.MazeRom)
# ---------------------------------------------------------------------------

def _origin(mz, scr):
    o = mz.origin[scr]
    return (o[0] | o[1] << 8) // 160, (o[2] | o[3] << 8) // 128


def floor_cells(mz, floor):
    """40 x 32 rows of the bottom-right tile id of every cell of a generated
    floor (maze.MazeRom.generate's dict), the stairs stamped."""
    g, mode = floor['grid'], floor['mode']
    T = [[0] * GRID_W for _ in range(GRID_H)]
    for scr in range(16):
        ox, oy = _origin(mz, scr)
        lay = mz.layout_bytes(mz.cell_streams(g[scr], mode)[0])
        for j in range(8):
            for k in range(10):
                T[oy * 8 + j][ox * 10 + k] = lay[(2 * j + 1) * 32 + 2 * k + 1]
    sx, sy = cell_of(mz, *floor['stairs'])
    T[sy][sx] = STAIRS_TILE
    return T


def cell_of(mz, scr, x, y):
    """(screen, pixel x, pixel y in the screen) -> absolute cell (col, row)."""
    ox, oy = _origin(mz, scr)
    return ox * 10 + (x - 8) // 16, oy * 8 + (y - 8) // 16


def walk_path(mz, floor, cells=None):
    """The shortest walk arrival -> stairs: {'steps', 'path', 'reachable',
    'cells': [(col, row) ...] after the arrival} (path: see the module doc)."""
    T = cells or floor_cells(mz, floor)
    start = cell_of(mz, *floor['arrival'])
    goal = cell_of(mz, *floor['stairs'])
    prev = {start: None}
    q = deque([start])
    while q:
        c = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (c[0] + dx, c[1] + dy)
            if 0 <= n[0] < GRID_W and 0 <= n[1] < GRID_H and n not in prev \
                    and T[n[1]][n[0]] >= WALL_BELOW:
                prev[n] = c
                q.append(n)
    if goal not in prev:
        raise ValueError('the stairs are not reachable from the arrival')
    seq = []
    c = goal
    while c != start:
        seq.append(c)
        c = prev[c]
    seq.reverse()
    pick = {cell_of(mz, it['screen'], it['x'], it['y']) for it in floor.get('items') or []
            if not it['kind'] & 0xF8}
    out, last = [], start
    for c in seq[:-1]:
        if c[0] // 10 != last[0] // 10 or c[1] // 8 != last[1] // 8:
            out.append(CROSS)
        elif c in pick:
            out.append(ITEM)
        else:
            out.append(CLASS_CHAR[T[c[1]][c[0]] >> 2])
        last = c
    return {'steps': len(seq), 'path': ''.join(out), 'reachable': len(prev), 'cells': seq}


# ---------------------------------------------------------------------------
# the walkable special rooms (S131; used by tools/census_dive.py)
# ---------------------------------------------------------------------------

def special_room(renderer, mid):
    """A vanilla room as a walk grid: {'map', 'w', 'h' (cells), 'cells' (rows of
    the bottom-right tile id of every cell), 'thr' (the $26DD collision
    threshold: tile < thr = wall), 'exits': {(col, row): (dest, spawn col,
    spawn row, kind)}} — kind 'walk' (Entry 6: rows 1-6 of a screen, fires on
    entering the cell) or 'up' / 'down' (Entry 9: row 0 / 7 at the ROOM's
    edge, fires on pushing into the edge from the cell). `renderer` =
    editor2/core/render_project.ProjectRenderer (the original ROM)."""
    rec = renderer.vanilla_record(mid)
    W, H = rec['width_px'] // 160, rec['height_px'] // 128
    T = [[0] * (10 * W) for _ in range(8 * H)]
    exits = {}
    for sy in range(H):
        for sx in range(W):
            k = sy * 4 + sx
            g = renderer.vanilla_screen_grid(mid, k)
            for j in range(8):
                for i in range(10):
                    T[sy * 8 + j][sx * 10 + i] = g[2 * j + 1][2 * i + 1]
            _n, ex = renderer.vanilla_markers(mid, k)
            for e in ex:
                c = (sx * 10 + e['x'], sy * 8 + e['y'])
                dest = int(e['dest'].split('$')[1], 16)
                if e['y'] == 0:
                    kind = 'up' if sy == 0 else None          # inside the room: scrolls
                elif e['y'] == 7:
                    kind = 'down' if sy == H - 1 else None
                else:
                    kind = 'walk'
                if kind:
                    exits[c] = (dest, e['spawn_x'], e['spawn_y'], kind)
    return {'map': mid, 'w': 10 * W, 'h': 8 * H, 'cells': T,
            'thr': int(rec['collision_threshold'], 16), 'exits': exits}


def special_walk(load, start_map, start_cell):
    """The shortest walk from the spawn of a special room to its stairs (an
    exit to map $00), through the room's other rooms (the forest maze's
    edge exits): BFS over (map, cell), one step = one cell entered, a belt
    cell of a conveyor map moves only its own way. `load(mid)` ->
    special_room(...). Returns {'steps' (cells entered), 'path' (one char per
    cell entered: 'a' = drained, '-' = a screen-edge step, EXIT_STEP = onto a
    walk-on exit cell; ROOM_LOAD after a room change), 'reachable' (walkable
    cells reachable, over every room seen), 'rooms', 'cells': [(map, (col,
    row)) ...]}."""
    rooms = {}

    def room(mid):
        if mid not in rooms:
            rooms[mid] = load(mid)
        return rooms[mid]

    def walkable(r, c):
        return 0 <= c[0] < r['w'] and 0 <= c[1] < r['h'] and r['cells'][c[1]][c[0]] >= r['thr']

    start = (start_map, tuple(start_cell))
    prev = {start: None}
    how = {}
    q = deque([start])
    goal = None
    while q and goal is None:
        st = q.popleft()
        mid, c = st
        r = room(mid)
        belt = BELT_DIR.get(r['cells'][c[1]][c[0]] >> 2) if mid in CONVEYOR_MAPS else None
        dirs = [belt] if belt else [(1, 0), (-1, 0), (0, 1), (0, -1)]
        for d in dirs:
            n = (c[0] + d[0], c[1] + d[1])
            ex = r['exits'].get(c)
            if ex and ex[3] in ('up', 'down') and d == ((0, -1) if ex[3] == 'up' else (0, 1)):
                nxt, kind = (ex[0], (ex[1], ex[2])), 'push'     # push into the room's edge
            elif walkable(r, n):
                e2 = r['exits'].get(n)
                if e2 and e2[3] == 'walk':
                    nxt, kind = (e2[0], (e2[1], e2[2])), 'walk'
                else:
                    nxt, kind = (mid, n), 'move'
            else:
                continue
            if nxt[0] == 0x00:
                if goal is None:
                    goal = ('stairs', st, kind, n)
                continue
            if nxt in prev:
                continue
            prev[nxt] = st
            how[nxt] = (kind, n)
            q.append(nxt)
    if goal is None:
        raise ValueError(f'no stairs reachable from map ${start_map:02X} {start_cell}')
    # unwind
    seq = []                                    # (kind, from state, to map, cell entered)
    _s, st, kind, n = goal
    seq.append((kind, st, 0x00, n))
    while prev[st] is not None:
        k2, n2 = how[st]
        seq.append((k2, prev[st], st[0], n2))
        st = prev[st]
    seq.reverse()
    out, cells = [], []
    for kind, (m0, c0), m1, n in seq:
        if kind == 'move':
            cross = c0[0] // 10 != n[0] // 10 or c0[1] // 8 != n[1] // 8
            out.append(CROSS if cross else 'a')
            cells.append((m0, n))
        elif kind == 'walk':
            out.append(EXIT_STEP)
            cells.append((m0, n))
            if m1 != 0x00:
                out.append(ROOM_LOAD)
        else:                                   # push into the edge: no cell entered
            out.append(PUSH_STEP)
            if m1 != 0x00:
                out.append(ROOM_LOAD)
    reach = len(prev)                           # (map, cell) states the BFS reached
    # the first input (a joypad direction; None = on a belt, the ride goes on)
    kind0, (m0, c0), _m1, n0 = seq[0]
    on_belt = m0 in CONVEYOR_MAPS and (room(m0)['cells'][c0[1]][c0[0]] >> 2) in BELT_DIR
    d0 = (n0[0] - c0[0], n0[1] - c0[1])
    first = None if on_belt else {(1, 0): 'right', (-1, 0): 'left', (0, 1): 'down',
                                  (0, -1): 'up'}.get(d0)
    if kind0 == 'push' and not on_belt:
        first = 'up' if room(m0)['exits'][c0][3] == 'up' else 'down'
    return {'steps': sum(1 for ch in out if ch not in (ROOM_LOAD, PUSH_STEP)), 'path': ''.join(out),
            'reachable': reach, 'rooms': sorted(rooms), 'cells': cells, 'first': first}


# ---------------------------------------------------------------------------
# the drain and the counter (vanilla tables, extracted/gamedata_vanilla.json)
# ---------------------------------------------------------------------------

def _gd_rows(repo, name):
    from . import gamedata as GD
    return [bytes.fromhex(r) for r in GD.vanilla(_root(repo))['tables'][name]['rows']]


def rate_bases(repo=None):
    """EncounterRateData: 16 floor types x [base for class $0C, $0D, $0E]."""
    return [[r[0] | r[1] << 8, r[2] | r[3] << 8, r[4] | r[5] << 8]
            for r in _gd_rows(repo, 'encounter_rate_data')]


def drains(repo, floor_type, rate_code):
    """Counter drain per step (class $0C, $0D, $0E) on a maze floor of type
    `floor_type` with a list of rate code `rate_code` (Mul16x8To24, then
    Div24x8To16 by $40: integer floor). Measured S130 (census_dive --measure)."""
    from . import encounters as EN
    mod = EN.rate_modifiers(_root(repo))[rate_code & 7]
    return tuple(b * mod // 64 for b in rate_bases(repo)[floor_type & 15])


def seed_cdf(repo=None):
    """[(counter value, P(seed <= value))] of SetRandomEncounterCounter
    (RNG mod 101 -> the first row whose threshold >= it)."""
    from . import encounters as EN
    prev, run, out = -1, 0, []
    for thr, val in EN.counter_seeds(_root(repo)):
        hi = min(thr, 100)
        n = max(0, hi - prev)
        prev = max(prev, hi)
        if n:
            run += n
            out.append((val, run / 101.0))
        if hi >= 100:
            break
    return out


def _cdf_fn(cdf):
    vals = [v for v, _p in cdf]
    ps = [p for _v, p in cdf]

    def F(x):                     # P(seed <= x)
        lo, hi = 0, len(vals)
        while lo < hi:
            mid = (lo + hi) // 2
            if vals[mid] <= x:
                lo = mid + 1
            else:
                hi = mid
        return ps[lo - 1] if lo else 0.0
    return F


def expected_battles(path, drain3, cdf):
    """Expected battles over one walk: renewal at entry (k = 0) and after
    every battle; a battle at step k after a renewal at j when
    D(j, k-1) <= seed < D(j, k) (D = the drains of steps j+1..k)."""
    F = _cdf_fn(cdf) if not callable(cdf) else cdf
    if ROOM_LOAD in path:
        # S131: a room change re-seeds the counter (SetRandomEncounterCounter at
        # every room load) — a renewal, so the walk's rooms are independent
        return sum(expected_battles(seg, drain3, F) for seg in path.split(ROOM_LOAD) if seg)
    d = [0 if ch in NO_DRAIN else drain3[ord(ch) - 97] for ch in path]
    n = len(d)
    r = [0.0] * (n + 1)
    r[0] = 1.0
    for j in range(n):
        if r[j] == 0.0:
            continue
        acc, fprev = 0, 0.0          # F(D - 1) with D = 0 -> P(seed <= -1) = 0
        for k in range(j + 1, n + 1):
            dk = d[k - 1]
            if not dk:
                continue
            acc += dk
            f = F(acc - 1)
            if f > fprev:
                r[k] += r[j] * (f - fprev)
                fprev = f
            if fprev >= 1.0:
                break
    return sum(r[1:])


def steps_between(repo, floor_type, rate_code, tile_class=0x0C):
    """Exact mean steps from a re-seed to the battle on a gate floor when
    every step drains the same (no screen edges): E[floor(seed / d) + 1]."""
    d = drains(repo, floor_type, rate_code)[tile_class - 0x0C]
    prev, tot = 0.0, 0.0
    for val, p in seed_cdf(repo):
        tot += (p - prev) * (val // d + 1)
        prev = p
    return tot


# ---------------------------------------------------------------------------
# the census (extracted/dive_census.json)
# ---------------------------------------------------------------------------

def census(repo=None):
    root = _root(repo)
    key = ('census', root)
    if key not in _CACHE:
        p = os.path.join(root, CENSUS_JSON)
        _CACHE[key] = json.load(open(p)) if os.path.exists(p) else None
    return _CACHE[key]


def parse_paths(text):
    """The JSON's comma-joined walks -> [(path, count)]."""
    cnt = {}
    for p in text.split(','):
        cnt[p] = cnt.get(p, 0) + 1
    return sorted(cnt.items())


def _paths(repo, size, rom=None):
    """[(path, count)] of maze size `size`: the census JSON, or (no JSON, a
    ROM given) a small in-memory census."""
    c = census(repo)
    if c is not None and str(size) in c['sizes']:
        key = ('paths', _root(repo), size)
        if key not in _CACHE:
            _CACHE[key] = parse_paths(c['sizes'][str(size)]['paths'])
        return _CACHE[key]
    if rom is None:
        raise FileNotFoundError(f'{CENSUS_JSON} is missing (tools/census_dive.py) and no ROM given')
    key = ('live', size, id(rom))
    if key not in _CACHE:
        from . import maze as MZ
        import random
        mz = MZ.MazeRom(rom)
        rnd = random.Random(131 + size)
        cnt = {}
        for _ in range(200):
            fl = mz.generate(rnd.randrange(65536), size, rnd.randrange(16),
                             rnd.randrange(4), rnd.randrange(8))
            pth = walk_path(mz, fl)['path']
            cnt[pth] = cnt.get(pth, 0) + 1
        _CACHE[key] = sorted(cnt.items())
    return _CACHE[key]


def floor_steps(repo=None, size=15, rom=None):
    """Steps of the shortest walk on a maze floor of size `size` (list byte
    +25): {'steps' mean (the stairs step included), 'drained' (steps that
    can drain), 'edges' (screen-edge steps), 'items' (steps onto a floor
    item: picked up, no check), 'by_class' [$0C, $0D, $0E]
    means, 'min', 'max', 'reachable' (cells reachable, the sweep bound), 'n'}."""
    c = census(repo)
    s = c['sizes'].get(str(size)) if c else None
    if s is not None:
        return {k: s[k] for k in ('steps', 'drained', 'edges', 'items', 'by_class', 'min',
                                  'max', 'reachable', 'n')}
    paths = _paths(repo, size, rom)
    n = sum(k for _p, k in paths)
    by = [sum(p.count(ch) * k for p, k in paths) / n for ch in 'abc']
    edges = sum(p.count(CROSS) * k for p, k in paths) / n
    items = sum(p.count(ITEM) * k for p, k in paths) / n
    return {'steps': sum(by) + edges + items + 1, 'drained': sum(by), 'edges': edges,
            'items': items, 'by_class': by,
            'min': min(len(p) for p, _k in paths) + 1, 'max': max(len(p) for p, _k in paths) + 1,
            'reachable': None, 'n': n}


def maze_battles(repo=None, size=15, floor_type=0, rate_code=3, rom=None):
    """Expected random battles walking one maze floor (shortest walk) of size
    `size`, type `floor_type`, list rate code `rate_code`."""
    c = census(repo)
    if c is not None:
        row = c.get('battles', {}).get(str(size))
        if row is not None:
            return row[floor_type & 15][rate_code & 7]
    key = ('mb', _root(repo), size, drains(repo, floor_type, rate_code))
    if key not in _CACHE:
        paths = _paths(repo, size, rom)
        F = _cdf_fn(seed_cdf(repo))
        n = sum(k for _p, k in paths)
        dr = key[3]
        _CACHE[key] = sum(expected_battles(p, dr, F) * k for p, k in paths) / n
    return _CACHE[key]


# ---------------------------------------------------------------------------
# a gate's floors
# ---------------------------------------------------------------------------

def _select_odds(row):
    """SelectFloorType over a cumulative-percent row, roll uniform 0-99
    (maze.MazeRom._select): {index: probability}."""
    out = {}
    for c in range(100):
        i = -1
        while True:
            i += 1
            if i >= len(row):
                i = None
                break
            a = row[i]
            if a == 0:
                continue
            if a == 0x64 or a >= c:
                break
        if i is not None:
            out[i] = out.get(i, 0) + 0.01
    return out


def _ft(repo):
    from . import gates as G
    return G.floor_types(_root(repo))


def type_odds(repo, maze_row):
    """{floor type: probability} of a FloorTypeSelectionTable row."""
    return _select_odds(_ft(repo)['tables']['maze'][maze_row]['bytes'])


def special_odds(repo, special_row):
    """{special index: probability} of a FloorTypeSelectionTable2 row."""
    return _select_odds(_ft(repo)['tables']['special'][special_row]['bytes'])


def vanilla_rows(repo, gate):
    """The vanilla gate's (maze_row, special_row, floors)."""
    from . import gates as G
    g = _ft(repo)['gates'][gate]
    floors = next(v['floors'] for v in G.vanilla_gates(_root(repo)) if v['id'] == gate)
    return g['maze_row'], g['special_row'], floors


def vanilla_floor_types(repo, gate):
    """{floor type: probability} a vanilla gate's maze floors roll."""
    return type_odds(repo, vanilla_rows(repo, gate)[0])


def battles_per_floor(repo, gate_id, floor, list_bytes, rom=None, maze_row=None,
                      special_row=None, floors=None, detail=False):
    """Expected random battles on gate `gate_id`'s floor `floor` (the game's
    numbering, 1 = first) walked arrival -> stairs by the shortest walk, with
    the floor's 26-byte encounter list `list_bytes` (+0 rate code, +25 maze
    size). Vanilla rows / floor count by default; a project passes
    maze_row / special_row / floors (gates.row_settings, gate_floor_count).

    The floor's outcome mix: the boss floor (floor == floors) -> 0; floors
    3, 6, 9 … of gates other than 0 are a special room half the time —
    treasure / priest / shop / coliseum rooms have no random battles (0);
    the forest maze / mazes / conveyor mazes walk their OWN rooms (S131,
    `special_battles`: their measured shortest walks, the flat outside-gate
    drain, the forest's room changes re-seeding the counter) with the
    floor's list (its rate code).

    detail=True also gives 'battles_sweep' (the whole-floor upper bound:
    each part's battles x its reachable cells / its walk steps — mazes per
    maze size, specials per room) and 'special_battles' {name: battles}."""
    if maze_row is None or special_row is None or floors is None:
        if 0 <= gate_id < 32:
            mr, sr, fl = vanilla_rows(repo, gate_id)
        else:
            mr, sr, fl = 0, 0, 0
        maze_row = mr if maze_row is None else maze_row
        special_row = sr if special_row is None else special_row
        floors = fl if floors is None else floors
    lb = bytes(list_bytes)
    code, size = lb[0] & 7, lb[25]
    size = min(15, max(3, size))
    if floors and floor >= floors:
        res = {'battles': 0.0, 'boss_floor': True, 'size': size, 'rate_code': code}
        return res if detail else 0.0
    types = type_odds(repo, maze_row)
    mb = sum(p * maze_battles(repo, size, t, code, rom) for t, p in types.items())
    p_special = SPECIAL_CHANCE if (gate_id != 0 and floor % SPECIAL_EVERY == 0) else 0.0
    sp = special_odds(repo, special_row) if p_special else {}
    sb = {i: special_battles(repo, i, code, 'direct', rom) for i in sp if i in SPECIAL_RANDOM_BATTLES}
    battles = mb * (1.0 - p_special) + p_special * sum(p * sb.get(i, 0.0) for i, p in sp.items())
    if not detail:
        return battles
    st = floor_steps(repo, size, rom)
    reach = st.get('reachable')
    mb_sweep = mb * (reach / max(1.0, st['steps'])) if reach else mb
    sbs = {i: special_battles(repo, i, code, 'sweep', rom) for i in sb}
    sweep = mb_sweep * (1.0 - p_special) + p_special * sum(p * sbs.get(i, 0.0) for i, p in sp.items())
    return {'battles': battles, 'battles_sweep': sweep, 'maze_battles': mb, 'boss_floor': False,
            'size': size, 'rate_code': code, 'types': types,
            'steps': st['steps'], 'drained_steps': st['drained'],
            'p_special': p_special,
            'specials': {SPECIAL_NAMES[i]: p_special * p for i, p in sp.items()},
            'special_battles': {SPECIAL_NAMES[i]: v for i, v in sb.items()},
            'steps_between': {t: steps_between(repo, t, code) for t in types}}


def special_drain(mid, rate_code, repo=None):
    """Counter drain per step in special room `mid` (EncounterStep outside
    gates: a flat base x RateMod[code] // 64; measured S131)."""
    from . import encounters as EN
    base = CONVEYOR_BASE if mid in CONVEYOR_MAPS else SPECIAL_BASE
    return base * EN.rate_modifiers(_root(repo))[rate_code & 7] // 64


def special_battles(repo, pick, rate_code, walk='direct', rom=None):
    """Expected random battles walking special room `pick` (2 forest / 6 maze
    / 7 conveyor; the variants weighted by their odds) arrival -> stairs
    with a list of rate code `rate_code`. 'direct' = the shortest walk;
    'sweep' = that x reachable cells / walk steps (the whole-room bound).
    From extracted/dive_census.json 'specials' (tools/census_dive.py)."""
    c = census(repo)
    row = (c or {}).get('specials', {}).get(str(pick))
    if row is not None and 'battles' in row:
        return row['battles' if walk == 'direct' else 'sweep'][rate_code & 7]
    key = ('sp', _root(repo), pick, rate_code & 7, walk)
    if key not in _CACHE:
        variants = row['variants'] if row is not None else _live_specials(repo, rom)[pick]
        F = _cdf_fn(seed_cdf(repo))
        tot = 0.0
        for v in variants:
            d = special_drain(v['map'], rate_code, repo)
            e = expected_battles(v['path'], (d, d, d), F)
            if walk != 'direct':
                e *= v['reachable'] / max(1.0, v['steps'])
            tot += v['p'] * e
        _CACHE[key] = tot
    return _CACHE[key]


def special_variants(renderer):
    """{pick: [{'map', 'p', 'spawn', 'steps', 'path', 'reachable', 'rooms'}]}
    — every walkable special's measured walk (special_walk) from the ROM."""
    rooms = {}

    def load(m):
        if m not in rooms:
            rooms[m] = special_room(renderer, m)
        return rooms[m]
    out = {}
    for pick, vs in SPECIAL_ROOMS.items():
        out[pick] = []
        for mid, spawn, p in vs:
            w = special_walk(load, mid, spawn)
            out[pick].append({'map': mid, 'p': p, 'spawn': list(spawn), 'steps': w['steps'],
                              'path': w['path'], 'reachable': w['reachable'], 'rooms': w['rooms']})
    return out


def _live_specials(repo, rom=None):
    key = ('livesp', _root(repo))
    if key not in _CACHE:
        from .render_project import ProjectRenderer
        _CACHE[key] = special_variants(ProjectRenderer(_root(repo), None, {'custom': {}}))
    return _CACHE[key]
