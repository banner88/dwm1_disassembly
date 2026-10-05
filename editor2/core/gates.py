"""gates.py — gate data model for the Gates tab + compiler (S100, ROADMAP P3.7b part 1).

Headless (no Qt). Owns:
  * the VANILLA gate list (id, name, floor count, boss room, floor-type rows,
    depth tier) from extracted/gate_names.json (tools/map_gate_names.py —
    ROM GateFloorDataTable $16:$70A6, cross-checked against the FAQ);
  * floor numbering: authored floors are the GAME's numbering — the first
    floor of a gate is 1 and the boss floor is the gate's floor count
    (entry 5 sets wCurrentFloor=0 on entry and serves the boss when
    wCurrentFloor+1 == last_floor; GATE_GENERATION §1/§3) — so
    wCurrentFloor = floor - 1;
  * custom.gate_inserts[] rule resolution helpers (PROJECT_COMPILER §2.16);
  * the stairs-down exit row and the gate-arrival pixel rule.

Engine facts these encode (all measured S100 unless marked):
  * a custom room can be served on floors 2 .. floors-1 (never the first
    floor — the user's scope; never the boss floor — entry 5 decides the boss
    floor before the fork);
  * rules are tried in list order; the first whose gate, floor, once-per-dive
    bit and flag terms hold ROLLS its chance (RNG16 mod 100 < chance); a hit
    is served, a miss tries the next rule; no hit -> vanilla (special-room
    gating: wRNG1 bit 4 AND wCurrentFloor mod 3 == 2, else the maze);
  * arrival is absolute pixels: 16*(screen_col*10 + x) + 8,
    16*(screen_row*8 + y) + 8 (standing positions are 8 mod 16 — ROOM_DATA_
    FORMAT "Arrival and edge rules"; $6D's historical $0048/$0068 = cell 4,6).
"""

import json
import os

MIN_FLOOR = 2              # user scope S100: the first floor stays vanilla
MAX_ONCE_PER_GATE = 8      # one bit each in wGateDiveMask
MAX_TERMS = 8              # same cap as state rules
FOLLOW_GATE = 0xFF         # RoomEncTable gate byte: never pin (bank $71 entry 1)

# a "stairs down" exit: dest map $00 / gate flag $80 -> wWarpGateId=0,
# wWarpFlag=$80 = "next floor of this gate" (byte-identical to the vanilla
# special rooms $50/$51 descent; GATE_GENERATION §7.5)
STAIRS_DOWN_FIELDS = {'dest': '0x00', 'gate_flag': '0x80', 'screen_byte': '0x00',
                      'spawn_x': 0, 'spawn_y': 0}

# the vanilla "next floor" hole (S100 r3): special room $51 (Gate Floor:
# Priest) cell (8,2), sheet slots $2C/$2D/$2E/$2F — a black hole ringed by
# colour 0 on a plain colour-2 square, so it sits on any floor in the cell's
# own palette ($50's copy has cream colour-1 corners). Slots >= $20 = the
# walkable side there, so "Stairs down here" keeps the cell walkable.
WELL_SRC_MAP = 0x51
WELL_SRC_TILES = (0x2C, 0x2D, 0x2E, 0x2F)
WELL_NAME = 'Next floor down (well)'
# S117 (NG2): the still swirl in the floor art of every vanilla portal —
# room $24 (Villager/Talisman) cells (2,2) / (2,6) = sheet slots $20-$23
# (BG map read in PyBoy S117; palette slot 3 there). The spinning swirl over
# it is an NPC (SWIRL_SPRITE), shown until the gate is cleared.
SWIRL_SRC_MAP = 0x24
SWIRL_SRC_TILES = (0x20, 0x21, 0x22, 0x23)
SWIRL_NAME = 'Gate swirl (portal floor)'


def _overlay_hole(hole, floor):
    """2bpp tile: the $51 hole's colour-2 pixels (its plain surround) show
    the floor tile's pixel instead; colours 0/1/3 are the hole's."""
    out = bytearray(16)
    for r in range(8):
        hl, hh, fl, fh = hole[2 * r], hole[2 * r + 1], floor[2 * r], floor[2 * r + 1]
        surround = hh & ~hl & 0xFF               # colour 2 = hi 1, lo 0
        out[2 * r] = (hl & ~surround | fl & surround) & 0xFF
        out[2 * r + 1] = (hh & ~surround | fh & surround) & 0xFF
    return bytes(out)


def _val(x):
    if isinstance(x, int):
        return x
    s = str(x).strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


def is_stairs_down(e):
    """An exit row that sends the player to the next floor of the dive."""
    try:
        return _val(e.get('gate_flag', 0)) == 0x80 and _val(e.get('dest', 0)) == 0
    except (TypeError, ValueError):
        return False


def stairs_down_row(x, y, comment=None):
    row = {'x': int(x), 'y': int(y), 'stairs': 'down'}
    row.update(STAIRS_DOWN_FIELDS)
    if comment:
        row['comment'] = comment
    return row


def arrival_px(screen, x, y):
    k = int(screen)
    col, row = k % 4, k // 4
    return 16 * (col * 10 + int(x)) + 8, 16 * (row * 8 + int(y)) + 8


def _repo_root(start):
    d = os.path.abspath(start)
    for _ in range(6):
        if os.path.exists(os.path.join(d, 'extracted', 'gate_names.json')):
            return d
        d = os.path.dirname(d)
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(here, '..', '..'))


_GATES_CACHE = {}


def vanilla_gates(start=None):
    """[{id, name, faq_name, floors, boss_map, boss_room, floor_types,
    depth_tier}] x 32 (ROM-derived, S100)."""
    root = _repo_root(start or os.path.dirname(os.path.abspath(__file__)))
    if root not in _GATES_CACHE:
        path = os.path.join(root, 'extracted', 'gate_names.json')
        data = json.load(open(path))
        _GATES_CACHE[root] = data['gates']
    return _GATES_CACHE[root]


_FT_CACHE = {}


def floor_types(start=None):
    """S120: extracted/gate_floor_types/gate_floor_types.json (tools/census_gate_floor_types.py,
    measured): the three floor-type tables (rows + odds), every vanilla gate's row bytes 0-2
    / 7, the rows each gate uses, the 16 maze pictures, the 8 special picks."""
    root = _repo_root(start or os.path.dirname(os.path.abspath(__file__)))
    if root not in _FT_CACHE:
        path = os.path.join(root, 'extracted', 'gate_floor_types', 'gate_floor_types.json')
        d = json.load(open(path)) if os.path.exists(path) else None
        if d is not None:
            d['_root'] = root
        _FT_CACHE[root] = d
    return _FT_CACHE[root]


def row_settings(custom, gate_id, start=None):
    """{'maze_row', 'special_row', 'contents_row', 'depth'} in effect for a gate (its own
    S120 settings, else its source's vanilla bytes) + 'vanilla' = the source's values."""
    ft = floor_types(start)
    gs = gate_settings(custom, gate_id)
    src = int(_val(gs['copy_of'])) if is_new_gate(gate_id) and gs.get('copy_of') is not None \
        else int(gate_id)
    van = dict(ft['gates'][src]) if ft else {k: 0 for k in ROW_KEYS}
    out = {k: (int(_val(gs[k])) if gs.get(k) is not None else van[k]) for k in ROW_KEYS}
    out['vanilla'] = {k: van[k] for k in ROW_KEYS}
    return out


def row_summary(kind, row, start=None, names=None):
    """A row of table `kind` ('maze' / 'special' / 'contents') in words: who uses it and
    what it rolls."""
    ft = floor_types(start)
    if not ft:
        return f'row {row}'
    users = ft['rows_used_by'][kind].get(str(row), [])
    who = ('like ' + ', '.join((names or {}).get(g, f'gate {g}') for g in users[:3])
           + (' …' if len(users) > 3 else '')) if users else 'no vanilla gate'
    odds = ft['tables'][kind][row]['odds']
    if kind == 'maze':
        what = ', '.join(f'type {i} {p} %' for i, p in odds)
    elif kind == 'special':
        what = ', '.join(f"{ft['specials'][i].split(' (')[0].split(' —')[0]} {p} %"
                         for i, p in odds if i < len(ft['specials']))
    else:
        what = ', '.join(f'mix {i} {p} %' for i, p in odds)
    return f'row {row} — {who}: {what}'


def gate_floors(gate_id, start=None):
    for g in vanilla_gates(start):
        if g['id'] == gate_id:
            return g['floors']
    return None


# ---------------------------------------------------------------------------
# Per-gate settings (S101, ROADMAP P3.7b part 2): custom.gates[] =
#   {"gate": 0-31, "floors": 2-99, "boss": "<custom room id>" | "vanilla:$xx",
#    "hand_made": bool, "comment": "..."}
# compiled into the bank $16 GateFloorDataTable region (gate_floor_table):
# byte 3 = floor count (incl. the boss floor), byte 4 = boss map, bytes 5/6 =
# the boss room's arrival TILE (absolute; entry 5 writes 16*b+8 pixels).
# hand_made: the gate's floors are the author's rooms — rules may take floor 1
# and the validator wants every floor 1..N-1 covered by an always-served rule.
# ---------------------------------------------------------------------------
GATE_KEYS = {'gate', 'floors', 'boss', 'hand_made', 'comment',
             'encounters',   # S114: the gate's own encounter plan (encounters.py)
             'copy_of', 'name',   # S115: NEW gates only (see below)
             'maze_row', 'special_row', 'contents_row', 'depth'}   # S120 (below)
# S120 (ROADMAP P3.7b part 2): the row bytes 0-2 + 7 of any gate (vanilla or new):
# which ROW of FloorTypeSelectionTable 1 / 2 / 3 the gate rolls (the maze look, the
# special room of floors 3, 6, 9 …, the contents mix) and the depth tier (the ground
# items' tier, bank $01). The rows themselves are shared tables — choosing a row = "like
# the gates that use it" (extracted/gate_floor_types/gate_floor_types.json, measured).
ROW_KEYS = {'maze_row': (0, 15, 0), 'special_row': (0, 15, 1),
            'contents_row': (0, 15, 2), 'depth': (1, 3, 7)}
FLOORS_MIN, FLOORS_MAX = 2, 99

# ---------------------------------------------------------------------------
# NEW gates (S115, ROADMAP NG1). custom.gates[] entries with "gate" 32-95 are
# brand-new gate numbers: {"gate": 32-95, "copy_of": 0-31, "name": "...",
#   + floors / boss / hand_made / encounters as for any gate}.
# Engine: bank $16 entry 5's two GateFloorDataTable readers go through
# GateRowPtr (S115 same-size forks); for gate >= 32 it far-calls bank $76
# entry 1 NewGateRowCopy, which copies the gate's 8-byte row (compiler-owned
# NewGateRows, generated from the source gate's row + this entry) to
# wGateRowBuf. Everything else in a dive already took the 8-bit wGateID
# (GateDecisionFork, CustomGateInsert, the anchor, EncResolve). The copy
# shares the source's floor-type rows (maze look, special rooms) and depth
# tier; its vanilla encounter rule / floor value is the source's
# (NewGateSource). Entered by an exit with gate_flag 1 and dest = the gate
# number (the vanilla portal form, add_gate_entrance). The cap 95 keeps the
# number below the custom map ids ($6B+) and below every engine sentinel.
# ---------------------------------------------------------------------------
NEW_GATE_FIRST = 32
NEW_GATE_LAST = 95
NEW_GATE_ONLY_KEYS = {'copy_of', 'name'}
# a gate entrance exit: gate_flag 1 = "enter gate <dest>" (34 vanilla portal
# exits, all screen 0 / spawn 0,0 — extracted/all_exits.json)
GATE_ENTRANCE_FIELDS = {'gate_flag': 1, 'screen_byte': '0x00', 'spawn_x': 0, 'spawn_y': 0}


def is_new_gate(gate_id):
    try:
        return NEW_GATE_FIRST <= int(gate_id) <= NEW_GATE_LAST
    except (TypeError, ValueError):
        return False


def new_gate_entries(custom):
    """custom.gates[] entries of NEW gates, by number."""
    out = []
    for g in (custom or {}).get('gates') or []:
        try:
            gid = int(_val(g.get('gate', -1)))
        except (TypeError, ValueError):
            continue
        if is_new_gate(gid):
            out.append(g)
    return sorted(out, key=lambda g: int(_val(g['gate'])))


def gate_source(custom, gate_id):
    """The vanilla gate a gate copies (itself for 0-31; None if unknown)."""
    gid = int(gate_id)
    if 0 <= gid < NEW_GATE_FIRST:
        return gid
    g = gate_settings(custom, gid)
    try:
        src = int(_val(g.get('copy_of')))
    except (TypeError, ValueError):
        return None
    return src if 0 <= src < NEW_GATE_FIRST else None


def gate_exists(custom, gate_id):
    try:
        gid = int(gate_id)
    except (TypeError, ValueError):
        return False
    if 0 <= gid < NEW_GATE_FIRST:
        return True
    return is_new_gate(gid) and gate_source(custom, gid) is not None


def gate_name(custom, gate_id, start=None):
    gid = int(gate_id)
    if gid < NEW_GATE_FIRST:
        v = next((x for x in vanilla_gates(start) if x['id'] == gid), None)
        return v['name'] if v else f'Gate {gid}'
    g = gate_settings(custom, gid)
    return g.get('name') or f'New gate {gid}'


def all_gates(custom, start=None):
    """The 32 vanilla gates (vanilla_gates rows) + the project's new gates
    as rows of the same shape plus 'new': True and 'copy_of'."""
    van = vanilla_gates(start)
    out = [dict(g, new=False) for g in van]
    by_id = {g['id']: g for g in van}
    for g in new_gate_entries(custom):
        gid = int(_val(g['gate']))
        src = gate_source(custom, gid)
        base = dict(by_id.get(src, {}))
        base.update({'id': gid, 'name': g.get('name') or f'New gate {gid}',
                     'faq_name': '', 'new': True, 'copy_of': src})
        out.append(base)
    return out


def is_gate_entrance(e):
    """An exit row that enters a gate (gate_flag 1, dest = the gate number)."""
    try:
        return _val(e.get('gate_flag', 0)) == 1
    except (TypeError, ValueError):
        return False


def entrance_gate(e):
    d = e.get('dest')
    s = str(d)
    if ':' in s:
        s = s.split(':', 1)[1]
    try:
        return _val(s)
    except (TypeError, ValueError):
        return None


# ---------------------------------------------------------------------------
# S117 (ROADMAP NG2) — a gate's CLEARED mark and its swirl.
# Vanilla (measured S117, the user's save): every portal cell carries a
# spinning swirl OBJECT (NPC sprite $4D, script $FF) over the still swirl in
# the floor art while the gate's boss is unbeaten; the boss win tail sets the
# gate's cleared flag (extracted/gate_names.json cleared_flag) and moves the
# portal room's step counter to a version without that object. The swirl
# never blocks the portal (entered in every version).
# Project rule (user S117: "Boss cleared - no swirly. Boss cleared BUT we are
# inputting new boss or redirecting to new gate - swirly"):
#   * a vanilla gate with its own boss -> its vanilla flag (nothing changes);
#   * a vanilla gate with ANOTHER boss (custom.gates boss) and every new gate
#     -> a flag of its own, GATE_FLAG_BASE + gate (extended range, never
#     moves), set by the engine on the boss-floor win (bank $76 GateBossWin;
#     a re-bossed vanilla gate also gets its vanilla flag, so story checks of
#     "gate cleared" keep working);
#   * a portal leads to the gate its exit row names (an entrance redirect
#     can re-route a vanilla portal), and its swirl follows THAT gate.
# ---------------------------------------------------------------------------
SWIRL_SPRITE = 0x4D
GATE_FLAG_BASE = 0x17A0          # + gate number (0-95): $17A0-$17FF (project.py)


def vanilla_cleared_flag(gate_id, start=None):
    for g in vanilla_gates(start):
        if g['id'] == int(gate_id):
            cf = g.get('cleared_flag')
            return _val(cf) if cf else None
    return None


def vanilla_win_program(gate_id, start=None):
    """S122 (NG2 residual a): what a custom boss win of re-bossed vanilla gate
    N replays — (extra flags, tails): the gate's further cleared flags beyond
    the first (Demolition: Sidoh's $28) and every win tail of its boss room
    (gate_names.json `win_tails`, tools/map_gate_names.py: the game's own
    bookkeeping after `write_ram $D92B 7`). Empty for gates without one."""
    for g in vanilla_gates(start):
        if g['id'] == int(gate_id):
            extra = [_val(f) for f in (g.get('cleared_flags') or [])[1:]]
            return extra, list(g.get('win_tails') or [])
    return [], []


def gate_rebossed(custom, gate_id, start=None):
    """A VANILLA gate whose boss floor serves another room than its own."""
    gid = int(gate_id)
    if gid >= 32:
        return False
    b = gate_settings(custom, gid).get('boss')
    if b in (None, '', 'vanilla'):
        return False
    if isinstance(b, str) and b.startswith('vanilla:'):
        own = next((g for g in vanilla_gates(start) if g['id'] == gid), None)
        try:
            return own is None or _val(b.split(':', 1)[1]) != _val(own['boss_map'])
        except (TypeError, ValueError):
            return True
    return True


def gate_cleared(custom, gate_id, start=None):
    """{'flag': the flag that means "this gate's boss is beaten" (None = the
    gate has none: the unused gate 31 with its own boss), 'own': True when it
    is the gate's OWN project flag (GATE_FLAG_BASE + gate), 'vanilla_flag':
    the vanilla gate's flag (None for new gates)} — or None when the gate
    does not exist."""
    gid = int(gate_id)
    if not gate_exists(custom, gid):
        return None
    vf = vanilla_cleared_flag(gid, start) if gid < 32 else None
    if gid >= 32 or gate_rebossed(custom, gid, start):
        return {'flag': GATE_FLAG_BASE + gid, 'own': True, 'vanilla_flag': vf}
    return {'flag': vf, 'own': False, 'vanilla_flag': vf}


def gate_ref(gate_id):
    """The flag reference that means "gate N is cleared" (resolve_flag_ref)."""
    return f'gate:{int(gate_id)}'


def parse_gate_ref(ref):
    s = str(ref)
    if s.startswith('gate:'):
        try:
            return int(_val(s.split(':', 1)[1]))
        except (TypeError, ValueError):
            return None
    return None


def swirl_npc(x, y, gate_id):
    """The spinning swirl object over a gate entrance: shown while the gate is
    not cleared (the compiler turns `swirl_of` into that condition)."""
    return {'kind': 'npc', 'x': int(x), 'y': int(y), 'sprite': hex(SWIRL_SPRITE),
            'script': None, 'facing': 'down', 'swirl_of': int(gate_id),
            'comment': f'gate swirl (gate {int(gate_id)}): spins until the gate is cleared'}


def gate_entrance_row(x, y, gate_id, comment=None):
    row = {'x': int(x), 'y': int(y), 'dest': f'gate:{int(gate_id)}'}
    row.update(GATE_ENTRANCE_FIELDS)
    if comment:
        row['comment'] = comment
    return row


def gate_settings(custom, gate_id):
    """The custom.gates[] entry of one gate (or {})."""
    for g in (custom or {}).get('gates') or []:
        try:
            if int(_val(g.get('gate', -1))) == int(gate_id):
                return g
        except (TypeError, ValueError):
            continue
    return {}


def gate_floor_count(custom, gate_id, start=None):
    g = gate_settings(custom, gate_id)
    if g.get('floors') is not None:
        return int(_val(g['floors']))
    src = gate_source(custom, gate_id)          # S115: a new gate = its source's
    return gate_floors(src if src is not None else gate_id, start)


def gate_min_floor(custom, gate_id):
    """First floor a custom room may take: 1 on a hand-made gate, else 2."""
    return 1 if gate_settings(custom, gate_id).get('hand_made') else MIN_FLOOR


def vanilla_boss_spawn(boss_map, start=None):
    """(tile x, tile y) where a vanilla boss room receives the player — the
    spawn bytes of the vanilla gate that owns that boss map."""
    for g in vanilla_gates(start):
        if int(g['boss_map'], 16) == int(boss_map):
            return tuple(g['boss_spawn'])
    return None


def arrival_tile(screen, x, y):
    """A room cell -> the absolute TILE entry 5's boss path takes (bytes 5/6)."""
    k = int(screen)
    return (k % 4) * 10 + int(x), (k // 4) * 8 + int(y)


def floor_range(spec, floors, min_floor=MIN_FLOOR):
    """Authored floors -> (first, last) in the game's numbering.
    spec: [a, b] | [a] | a | "all" (= every floor a room may take)."""
    if spec in (None, 'all', 'any'):
        return min_floor, (floors - 1 if floors else 254)
    if isinstance(spec, (int, str)) and not isinstance(spec, bool):
        a = b = _val(spec)
    else:
        spec = list(spec)
        if len(spec) == 1:
            a = b = _val(spec[0])
        elif len(spec) == 2:
            a, b = _val(spec[0]), _val(spec[1])
        else:
            raise ValueError(f"floors must be [first, last], [n], n or 'all' — got {spec!r}")
    return a, b


def floors_text(spec, floors=None, min_floor=MIN_FLOOR):
    a, b = floor_range(spec, floors, min_floor)
    if spec in (None, 'all', 'any'):
        return 'any floor'
    return f"floor {a}" if a == b else f"floors {a}-{b}"


def effective_chances(rules, gate_id, floor, flags_state=None):
    """Probability that each rule is the one served on `floor` of `gate_id`,
    in list order, assuming its flag terms hold (flags_state None) or
    evaluating them against {flag_idx: bool}. rules = resolved rows (see
    Project.gate_insert_rows). Returns [(row, p_served)] for rules of that
    gate covering that floor, plus the vanilla remainder as the last item
    (row None)."""
    left = 1.0
    out = []
    for row in rules:
        if row['gate'] != gate_id:
            continue
        if not (row['first'] <= floor <= row['last']):
            continue
        ok = True
        if flags_state is not None:
            for idx, must_clear in row['terms']:
                v = bool(flags_state.get(idx, False))
                if v == must_clear:
                    ok = False
        if not ok:
            out.append((row, 0.0))
            continue
        p = min(row['chance'], 100) / 100.0
        out.append((row, left * p))
        left *= (1.0 - p)
    out.append((None, left))
    return out


# ---------------------------------------------------------------------------
# Document mixin (no Qt) — the Gates tab and the Rooms tab edit through these
# ---------------------------------------------------------------------------
class GatesMixin:
    """custom.gate_inserts[] + the per-room gate settings (S100, P3.7b)."""

    # ------------------------------------------------------------ rules
    def gate_inserts(self):
        return self.custom.get('gate_inserts') or []

    def set_gate_inserts(self, rules):
        if rules:
            self.custom['gate_inserts'] = [dict(r) for r in rules]
        else:
            self.custom.pop('gate_inserts', None)
        self.touch()

    def gate_rules_for(self, gate_id):
        """[(index into gate_inserts, rule)] of one gate, in list order."""
        return [(i, r) for i, r in enumerate(self.gate_inserts())
                if int(_val(r.get('gate', -1))) == int(gate_id)]

    def rules_serving(self, room_id):
        return [(i, r) for i, r in enumerate(self.gate_inserts()) if r.get('room') == room_id]

    # ------------------------------------------------ gate settings (S101)
    def gate_setting(self, gate_id):
        return gate_settings(self.custom, gate_id)

    def set_gate_setting(self, gate_id, **fields):
        """floors (int | None = vanilla), boss (custom room id | 'vanilla:$xx' |
        None = vanilla), hand_made (bool). An entry with nothing left is
        removed (the gate is vanilla again)."""
        lst = self.custom.setdefault('gates', [])
        g = gate_settings(self.custom, gate_id)
        if not g:
            if is_new_gate(gate_id):
                raise ValueError(f'gate {gate_id} is not one of this project\'s gates')
            g = {'gate': int(gate_id)}
            lst.append(g)
        for k, v in fields.items():
            if k not in GATE_KEYS - {'gate'}:
                raise ValueError(f'unknown gate setting {k!r}')
            if k in NEW_GATE_ONLY_KEYS:
                if not is_new_gate(gate_id):
                    raise ValueError(f'{k!r} only applies to new gates')
                if v in (None, '') or (k == 'name' and not str(v).strip()):
                    raise ValueError(f'a new gate always has a {k}')
                if k == 'copy_of' and not 0 <= int(v) < NEW_GATE_FIRST:
                    raise ValueError('copy_of must be a vanilla gate 0-31')
            if k in ROW_KEYS and v is not None:
                lo, hi, _at = ROW_KEYS[k]
                if not lo <= int(v) <= hi:
                    raise ValueError(f'{k} must be {lo}-{hi}')
            # (S120: `v in (None, False, '')` was True for 0 — row 0 could not be chosen)
            if (v is None or v is False or v == '') and k != 'floors':
                g.pop(k, None)
            elif k == 'floors' and v is None:
                g.pop('floors', None)
            else:
                g[k] = v
        if set(g) <= {'gate', 'comment'}:
            lst.remove(g)
        lst.sort(key=lambda x: int(_val(x.get('gate', 0))))
        if not lst:
            self.custom.pop('gates', None)
        self.touch()

    # ------------------------------------------------ new gates (S115, NG1)
    def all_gates(self):
        return all_gates(self.custom, getattr(self, 'project_dir', None))

    def gate_name(self, gate_id):
        return gate_name(self.custom, gate_id, getattr(self, 'project_dir', None))

    def new_gate_ids(self):
        return [int(_val(g['gate'])) for g in new_gate_entries(self.custom)]

    def new_gate(self, copy_of, name, floors=None, gate_id=None):
        """Add a NEW gate (number 32-95) that starts as a copy of vanilla gate
        `copy_of`: same maze look, floor count (unless `floors`), boss room
        and encounter rule until edited. Returns its number."""
        copy_of = int(copy_of)
        if not 0 <= copy_of < NEW_GATE_FIRST:
            raise ValueError('copy_of must be a vanilla gate 0-31')
        if not str(name or '').strip():
            raise ValueError('a new gate needs a name')
        used = set(self.new_gate_ids())
        if gate_id is None:
            free = [n for n in range(NEW_GATE_FIRST, NEW_GATE_LAST + 1) if n not in used]
            if not free:
                raise ValueError(f'all {NEW_GATE_LAST - NEW_GATE_FIRST + 1} new gate '
                                 'numbers are used')
            gate_id = free[0]
        gate_id = int(gate_id)
        if not is_new_gate(gate_id) or gate_id in used:
            raise ValueError(f'gate number {gate_id} is not free')
        g = {'gate': gate_id, 'copy_of': copy_of, 'name': str(name).strip()}
        if floors is not None:
            n = int(floors)
            if not FLOORS_MIN <= n <= FLOORS_MAX:
                raise ValueError(f'floors must be {FLOORS_MIN}-{FLOORS_MAX}')
            g['floors'] = n
        lst = self.custom.setdefault('gates', [])
        lst.append(g)
        lst.sort(key=lambda x: int(_val(x.get('gate', 0))))
        self.touch()
        return gate_id

    def gate_entrances(self, gate_id=None):
        """[(room, screen key, state index, exit row)] of every gate entrance
        (of one gate, or all)."""
        out = []
        for r in self.rooms:
            if r.get('placeholder'):
                continue
            for k in self.screen_keys(r):
                for n, st in enumerate(self.states(r, k)):
                    for e in st.get('exits') or []:
                        if is_gate_entrance(e) and (gate_id is None
                                                    or entrance_gate(e) == int(gate_id)):
                            out.append((r, k, n, e))
        return out

    def delete_gate(self, gate_id):
        """Remove a NEW gate, its custom-room rules and its entrances.
        Returns {'rules': n, 'entrances': n}."""
        gid = int(gate_id)
        if not is_new_gate(gid) or not gate_settings(self.custom, gid):
            raise ValueError(f'gate {gid} is not one of this project\'s new gates')
        self.custom['gates'] = [g for g in self.custom.get('gates') or []
                                if int(_val(g.get('gate', -1))) != gid]
        if not self.custom['gates']:
            self.custom.pop('gates')
        rules = [r for r in self.gate_inserts() if int(_val(r.get('gate', -1))) != gid]
        n_rules = len(self.gate_inserts()) - len(rules)
        self.set_gate_inserts(rules)
        n_ent = 0
        for r in self.rooms:
            if r.get('placeholder'):
                continue
            for k in self.screen_keys(r):
                for st in self.states(r, k):
                    ex = st.get('exits')
                    if not ex:
                        continue
                    keep = [e for e in ex if not (is_gate_entrance(e)
                                                  and entrance_gate(e) == gid)]
                    n_ent += len(ex) - len(keep)
                    st['exits'] = keep
                for st in self.states(r, k):          # S117: its swirl objects
                    if st.get('npcs'):
                        st['npcs'] = [e for e in st['npcs']
                                      if not (e.get('swirl_of') is not None
                                              and int(_val(e['swirl_of'])) == gid)]
        reds = self.custom.get('entrance_redirects') or []
        keep = [rd for rd in reds if not (_val(rd.get('gate_flag', 0)) == 1
                                          and entrance_gate(rd) == gid)]
        n_ent += len(reds) - len(keep)
        if reds:
            if keep:
                self.custom['entrance_redirects'] = keep
            else:
                self.custom.pop('entrance_redirects', None)
        self.touch()
        return {'rules': n_rules, 'entrances': n_ent}

    def add_gate_entrance(self, room, key, state_idx, x, y, gate_id, states=None,
                          swirl=True):
        """A gate entrance exit on (x, y): stepping on it enters gate
        `gate_id` (a vanilla gate 0-31 or a new gate) at its first floor —
        the vanilla portal form (gate_flag 1, dest = the gate). S117 (NG2):
        plus the spinning swirl object on the cell, shown until the gate is
        cleared (`swirl_npc`; the 8-NPC cap permitting — returns the states
        where it did not fit)."""
        gid = int(gate_id)
        if not gate_exists(self.custom, gid):
            raise ValueError(f'gate {gid} does not exist')
        states = list(states if states is not None else [state_idx])
        for n in states:
            for e in self.exits_of(room, key, n):
                if (_val(e['x']), _val(e['y'])) == (int(x), int(y)):
                    raise ValueError(f"cell ({x},{y}) already holds an exit in state {n}")
        full = []
        for n in states:
            self.exits_of(room, key, n).append(
                gate_entrance_row(x, y, gid, f'gate entrance: {self.gate_name(gid)}'))
            if swirl:
                if self.state_capacity(room, key, n)[0] >= self.state_capacity(room, key, n)[1]:
                    full.append(n)
                else:
                    self.npc_entries(room, key, n).append(swirl_npc(x, y, gid))
        self.touch()
        return full

    def gate_swirls(self, gate_id=None):
        """[(room, key, state, npc entry)] of the swirl objects (swirl_of)."""
        out = []
        for r in self.rooms:
            if r.get('placeholder'):
                continue
            for k in self.screen_keys(r):
                for n, st in enumerate(self.states(r, k)):
                    for e in st.get('npcs') or []:
                        if e.get('swirl_of') is not None and (
                                gate_id is None or int(_val(e['swirl_of'])) == int(gate_id)):
                            out.append((r, k, n, e))
        return out

    def gate_cleared_info(self, gate_id):
        """gate_cleared() for this document (S117)."""
        return gate_cleared(self.custom, gate_id, getattr(self, 'project_dir', None))

    def gate_cleared_text(self, gate_id):
        """One line for the Gates tab: which flag means "cleared"."""
        info = self.gate_cleared_info(gate_id)
        if info is None:
            return ''
        if info['flag'] is None:
            return 'no cleared flag (the unused gate)'
        if info['own']:
            extra = (f" — beating its boss also sets the vanilla flag ${info['vanilla_flag']:04X}"
                     if info.get('vanilla_flag') is not None and int(gate_id) < 32 else '')
            why = 'a new gate' if int(gate_id) >= 32 else 'it has another boss'
            return (f"cleared flag ${info['flag']:04X} — its own ({why}): beating its boss "
                    f"sets it and its swirls stop{extra}")
        return (f"cleared flag ${info['flag']:04X} (the game's own) — its swirls stop when "
                "its boss is beaten")

    def portal_redirects(self, gate_id=None):
        """S117: entrance redirects that make a VANILLA portal lead to a gate
        (dest gate:N, gate_flag 1) — [(index, row)]."""
        out = []
        for i, rd in enumerate(self.custom.get('entrance_redirects') or []):
            try:
                if _val(rd.get('gate_flag', 0)) != 1:
                    continue
            except (TypeError, ValueError):
                continue
            g = entrance_gate(rd)
            if gate_id is None or g == int(gate_id):
                out.append((i, rd))
        return out

    def add_portal_redirect(self, source_mid, screen, x, y, gate_id, comment=None):
        """S117: make the vanilla portal (source_mid, screen, x, y) lead to
        gate `gate_id` (a new gate, or another vanilla gate). Its swirl in the
        vanilla room follows that gate's cleared flag (VanillaNPCExtTable)."""
        gid = int(gate_id)
        if not gate_exists(self.custom, gid):
            raise ValueError(f'gate {gid} does not exist')
        entry = {'mapID': f'0x{int(source_mid):02X}', 'screen': int(screen),
                 'x': int(x), 'y': int(y), 'dest': f'gate:{gid}'}
        entry.update(GATE_ENTRANCE_FIELDS)
        entry['comment'] = comment or f'portal -> gate {gid} ({self.gate_name(gid)})'
        lst = self.custom.setdefault('entrance_redirects', [])
        for i, r in enumerate(lst):
            if (_val(r['mapID']), _val(r['screen']), _val(r['x']), _val(r['y'])) == \
                    (int(source_mid), int(screen), int(x), int(y)):
                lst[i] = entry
                self.touch()
                return i
        lst.append(entry)
        self.touch()
        return len(lst) - 1

    def conversation_exits(self, room):
        """S101: helper / move steps in the conversations of a room's script table."""
        n = 0

        def walk(steps):
            c = 0
            for st in steps or []:
                if isinstance(st, dict):
                    c += ('helper' in st) + ('move' in st)
                    for k in ('yes', 'no', 'then', 'else'):
                        c += walk(st.get(k))
            return c
        by_id = {sc.get('id'): sc for sc in self.custom.get('scripts', [])}
        for sid in set((room.get('scripts') or {}).values()):
            t = (by_id.get(sid) or {}).get('talk') or {}
            n += walk(t.get('steps'))
        return n

    def gate_floor_count(self, gate_id):
        return gate_floor_count(self.custom, gate_id, getattr(self, 'project_dir', None))

    def gate_min_floor(self, gate_id):
        return gate_min_floor(self.custom, gate_id)

    def boss_gates_of(self, room_id):
        """Gates whose boss floor is this custom room."""
        return [int(_val(g['gate'])) for g in self.custom.get('gates') or []
                if g.get('boss') == room_id]

    def gate_boss_label(self, gate_id):
        g = gate_settings(self.custom, gate_id)
        b = g.get('boss')
        if not b:
            src = gate_source(self.custom, gate_id)       # S115: a new gate = its source's
            v = next((x for x in vanilla_gates(getattr(self, 'project_dir', None))
                      if x['id'] == src), None)
            return f"vanilla: {v['boss_room']}" if v else 'vanilla'
        if isinstance(b, str) and b.startswith('vanilla:'):
            mid = int(b.split(':', 1)[1].lstrip('$'), 16)
            v = next((x for x in vanilla_gates(getattr(self, 'project_dir', None))
                      if int(x['boss_map'], 16) == mid), None)
            return f"vanilla room: {v['boss_room'] if v else b}"
        return f'custom room: {b}'

    def gate_rule_rows(self, gate_id):
        """Display rows for effective_chances (flag terms unresolved)."""
        floors = self.gate_floor_count(gate_id)
        minf = self.gate_min_floor(gate_id)
        rows = []
        for i, r in self.gate_rules_for(gate_id):
            try:
                a, b = floor_range(r.get('floors', 'all'), floors, minf)
            except ValueError:
                continue
            rows.append({'index': i, 'rule': r, 'gate': int(gate_id), 'first': a,
                         'last': b, 'chance': int(_val(r.get('chance', 100))),
                         'terms': [], 'once': bool(r.get('once_per_dive'))})
        return rows

    def gate_floor_plan(self, gate_id, flags_hold=True):
        """[(floor, [(room_id, p, row)], vanilla_label, vanilla_p)] for floors
        1..N of one dive: the probability that each custom rule is the one
        served on that floor, computed floor by floor through the dive (an
        exact walk over which once-per-dive rules were already served — the
        engine's wGateDiveMask), then the vanilla remainder. Flag conditions
        are assumed to hold (flags_hold) or to fail (rules with conditions
        never serve); flags that change mid-dive are not modelled."""
        floors = self.gate_floor_count(gate_id) or 0
        hand_made = self.gate_min_floor(gate_id) == 1
        rows = self.gate_rule_rows(gate_id)
        for k, r in enumerate(rows):
            r['has_terms'] = bool(r['rule'].get('when'))
        once_bit = {}
        n = 0
        for r in rows:
            if r['once']:
                once_bit[r['index']] = 1 << n
                n += 1
        dist = {0: 1.0}                         # used-once mask -> probability
        plan = []
        for f in range(1, floors + 1):
            if f == floors:
                plan.append((f, [], 'boss floor — ' + self.gate_boss_label(gate_id), 1.0))
                continue
            if f == 1 and not hand_made:
                plan.append((f, [], "first floor — the gate's maze", 1.0))
                continue
            van = ('maze, or a special room (~50 %: treasure / priest / forest / maze rooms)'
                   if (f - 1) % 3 == 2 and gate_id != 0 else 'maze')
            served = [0.0] * len(rows)
            vanilla = 0.0
            nxt = {}
            for mask, pm in dist.items():
                left = 1.0
                for i, r in enumerate(rows):
                    if not (r['first'] <= f <= r['last']):
                        continue
                    if r['has_terms'] and not flags_hold:
                        continue
                    bit = once_bit.get(r['index'], 0)
                    if bit and mask & bit:
                        continue
                    p = min(r['chance'], 100) / 100.0
                    hit = pm * left * p
                    served[i] += hit
                    nxt[mask | bit] = nxt.get(mask | bit, 0.0) + hit
                    left *= (1.0 - p)
                vanilla += pm * left
                nxt[mask] = nxt.get(mask, 0.0) + pm * left
            dist = {m: q for m, q in nxt.items() if q > 1e-12}
            items = [(r['rule'].get('room'), served[i], r) for i, r in enumerate(rows)
                     if r['first'] <= f <= r['last']]
            plan.append((f, items, van, vanilla))
        return plan

    @staticmethod
    def describe_gate_rule(r):
        floors = r.get('floors', 'all')
        txt = f"{floors_text(floors)}, {int(_val(r.get('chance', 100)))} %"
        if r.get('once_per_dive'):
            txt += ', once per dive'
        terms = r.get('when') or []
        if terms:
            txt += ', when ' + ' AND '.join(
                f"{t.get('flag')} {'is clear' if t.get('is') == 'clear' else 'is set'}"
                for t in terms)
        return txt

    # ------------------------------------------------------------ rooms
    def set_gate_arrival(self, room, screen, x, y):
        room['gate_arrival'] = {'screen': int(screen), 'x': int(x), 'y': int(y)}
        self.touch()

    def clear_gate_arrival(self, room):
        room.pop('gate_arrival', None)
        self.touch()

    def set_can_save(self, room, on):
        if on:
            room.pop('can_save', None)          # default = allowed
        else:
            room['can_save'] = False
        self.touch()

    def encounter_mode(self, room):
        enc = room.get('encounters') or {}
        if not enc.get('enabled'):
            return 'off'
        if enc.get('list') is not None:
            return 'own'                   # S114: its own list (encounters_doc)
        return 'follow' if enc.get('follow_gate') else 'fixed'

    def set_encounter_mode(self, room, mode):
        """'off' | 'follow' (the dive's own gate/floor) | 'fixed' (keep the
        room's pinned gate/floor — never for rooms served in gates)."""
        enc = dict(room.get('encounters') or {})
        if mode == 'own':
            # S114: the list itself is chosen on the Encounters tab; picking
            # 'own' here keeps a room that already has one, else starts it on
            # the dive's list number (list 0 = the Gate of Beginning's)
            if enc.get('list') is None:
                enc = {'enabled': True, 'list': 0}
            enc['enabled'] = True
            enc.pop('follow_gate', None)
            room['encounters'] = enc
            self.touch()
            return
        if mode == 'off':
            room.pop('encounters', None)
        elif mode == 'follow':
            room['encounters'] = {'enabled': True, 'follow_gate': True}
            for k in ('rate', 'comment'):           # S114: keep the room's rate
                if k in enc:
                    room['encounters'][k] = enc[k]
        elif mode == 'fixed':
            enc.pop('follow_gate', None)
            enc['enabled'] = True
            enc.setdefault('gate_id', 0)
            enc.setdefault('floor', 1)
            room['encounters'] = enc
        else:
            raise ValueError(mode)
        self.touch()

    def set_room_music(self, room, value):
        """None = no assignment (inside a gate dive: the gate's music keeps
        playing — measured S100; outside: the vanilla derivation)."""
        if value in (None, ''):
            room.pop('music', None)
        else:
            room['music'] = value
        self.touch()

    def add_stairs(self, room, key, state_idx, x, y, states=None, well=True):
        """A Stairs down exit on (x, y): the next floor of the dive.

        S100 r3 (user: "I can't seem to import the next gate floor icon from
        anywhere … by default it should always be displayed as the 'next
        floor down'"): with `well` the cell is also PAINTED with the vanilla
        next-floor hole (paint_well). If the graphic cannot be added (no
        renderer, or the tileset is full) the stairs still work and
        `self.last_import_note` says why."""
        states = list(states if states is not None else [state_idx])
        for n in states:
            for e in self.exits_of(room, key, n):
                if (_val(e['x']), _val(e['y'])) == (int(x), int(y)):
                    raise ValueError(f"cell ({x},{y}) already holds an exit in state {n}")
            self.exits_of(room, key, n).append(stairs_down_row(x, y))
        self.last_import_note = ''
        if well:
            try:
                for n in states:
                    self.paint_well(room, key, n, x, y)
            except RuntimeError as ex:
                self.last_import_note = f'Stairs added, but the well picture was not: {ex}'
        self.touch()

    def _cell_tiles_and_sheet(self, room, key, state_idx, x, y):
        """(the 4 sheet slots drawn on cell (x, y), the room's 2 KB sheet)."""
        rec = room['record']
        ref = self.state_layout_ref(room, key, state_idx)
        if ref is None:
            raise RuntimeError(f'screen {key} has no layout')
        grid = (self.layout(ref['id'])['tiles'] if 'id' in ref
                else self.vanilla.layout_grid(ref)[0])
        cell = [grid[int(y) * 2 + dr][int(x) * 2 + dc] & 0x7F
                for dr, dc in ((0, 0), (0, 1), (1, 0), (1, 1))]
        tid = rec.get('tileset')
        sheet = (bytes(self.read_sheet(tid)[:2048]) if tid is not None else
                 bytes(self.vanilla.rom_sheet(_val(rec['gfx_bank']),
                                              _val(rec['gfx_id']))[:2048]))
        return cell, sheet

    def well_metatile(self, room, key=0, state_idx=0, x=0, y=0):
        """The vanilla next-floor hole drawn OVER the floor already on cell
        (x, y) — the hole's plain surround (colour 2 in $51) is replaced by
        that floor's own pixels, so it sits on any floor like the island's
        own pits; the rim (colour 0) and the hole (colour 3) come from $51.
        Brought into the room's tileset (identical graphics reuse their
        slots; the bottom-right lands on the walkable side). Returns the
        metatile dict. Raises RuntimeError without a renderer or free slots."""
        theme = self.gate_theme(room)
        if theme is not None and getattr(self, 'vanilla', None) is not None:
            _c, sheet = self._cell_tiles_and_sheet(room, key, state_idx, x, y)
            orig = bytes(self.vanilla.theme_gfx(theme).sheet[:2048])
            if bytes(sheet[0x3C * 16:0x40 * 16]) != orig[0x3C * 16:0x40 * 16]:
                theme = None        # slots $3C-$3F were reused: import the well
        if theme is not None:
            # S122: a room drawn with a gate theme's own sheet has the maze's
            # stairs at $3C-$3F — the same picture bank $0B stamps on a real
            # floor's stairs (Call_00b_4309); no import. (Inert as a tile in a
            # custom room — wInGateworld is 0 there; the Stairs down exit row
            # is what moves the player.)
            from editor2.core.maze import STAIR_TILES
            return {'name': 'Maze stairs (the theme\'s own)', 'tiles': list(STAIR_TILES), 'pal': 0}
        if getattr(self, 'vanilla', None) is None:
            raise RuntimeError('no ROM renderer loaded')
        src = bytes(self.vanilla.vanilla_gfx(WELL_SRC_MAP).sheet[:2048])
        cell, sheet = self._cell_tiles_and_sheet(room, key, state_idx, x, y)
        comp = [_overlay_hole(bytes(src[w * 16:w * 16 + 16]), bytes(sheet[f * 16:f * 16 + 16]))
                for w, f in zip(WELL_SRC_TILES, cell)]
        tid = room['record'].get('tileset')
        if tid is not None:                      # already have this exact picture?
            for mt in self.metatiles(tid):
                if [bytes(sheet[t * 16:t * 16 + 16]) for t in mt['tiles']] == comp:
                    return mt
        fake = bytearray(2048)                   # the 4 graphics at slots $7C-$7F,
        for i, g in enumerate(comp):             # threshold 0 = all walkable side
            fake[(0x7C + i) * 16:(0x7D + i) * 16] = g
        own = None if tid is not None else sheet
        return self.import_metatile(room, {'name': WELL_NAME, 'tiles': [0x7C, 0x7D, 0x7E, 0x7F],
                                           'pal': 0},
                                    bytes(fake), 0, own_sheet=own, name=WELL_NAME)

    def swirl_metatile(self, room, key=0, state_idx=0, x=0, y=0):
        """S117: the vanilla portal's still swirl ($24 slots $20-$23), brought
        into the room's tileset like the well (drawn in the cell's palette)."""
        if getattr(self, 'vanilla', None) is None:
            raise RuntimeError('no ROM renderer loaded')
        src = bytes(self.vanilla.vanilla_gfx(SWIRL_SRC_MAP).sheet[:2048])
        cell, sheet = self._cell_tiles_and_sheet(room, key, state_idx, x, y)
        comp = [bytes(src[w * 16:w * 16 + 16]) for w in SWIRL_SRC_TILES]
        tid = room['record'].get('tileset')
        if tid is not None:
            for mt in self.metatiles(tid):
                if [bytes(sheet[t * 16:t * 16 + 16]) for t in mt['tiles']] == comp:
                    return mt
        fake = bytearray(2048)
        for i, g in enumerate(comp):
            fake[(0x7C + i) * 16:(0x7D + i) * 16] = g
        own = None if tid is not None else sheet
        return self.import_metatile(room, {'name': SWIRL_NAME, 'tiles': [0x7C, 0x7D, 0x7E, 0x7F],
                                           'pal': 0},
                                    bytes(fake), 0, own_sheet=own, name=SWIRL_NAME)

    def paint_swirl(self, room, key, state_idx, x, y):
        """S117: paint the still portal swirl on cell (x, y) (tiles only)."""
        self._paint_cell(room, key, state_idx, x, y,
                         self.swirl_metatile(room, key, state_idx, x, y))

    def _paint_cell(self, room, key, state_idx, x, y, mt):
        ref = self.state_layout_ref(room, key, state_idx)
        if 'id' not in ref:
            grid = [list(r) for r in self.vanilla.layout_grid(ref)[0]]
            self.localize_layout(room, key, state_idx, grid)
            ref = self.state_layout_ref(room, key, state_idx)
        tiles = self.layout(ref['id'])['tiles']
        for j, (dr, dc) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
            tiles[int(y) * 2 + dr][int(x) * 2 + dc] = mt['tiles'][j]
        self.touch()

    def paint_well(self, room, key, state_idx, x, y):
        """Paint the well on cell (x, y) of screen `key` / state `state_idx`
        (tiles only — the cell keeps its palette, so the hole takes the
        room's colours like the vanilla one does)."""
        mt = self.well_metatile(room, key, state_idx, x, y)
        ref = self.state_layout_ref(room, key, state_idx)
        if 'id' not in ref:
            grid = [list(r) for r in self.vanilla.layout_grid(ref)[0]]
            self.localize_layout(room, key, state_idx, grid)
            ref = self.state_layout_ref(room, key, state_idx)
        tiles = self.layout(ref['id'])['tiles']
        for j, (dr, dc) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
            tiles[int(y) * 2 + dr][int(x) * 2 + dc] = mt['tiles'][j]
        self.touch()

    def gate_room_report(self, room):
        """What a room needs to be served inside gates — for the Gates tab
        and the inspector: {ready, problems[], notes[], stairs, arrival}."""
        problems, notes = [], []
        stairs, other = 0, 0
        for k in self.screen_keys(room):
            for st in self.states(room, k):
                for e in st.get('exits') or []:
                    if is_stairs_down(e):
                        stairs += 1
                    elif 'dest' in e:
                        other += 1
        arr = room.get('gate_arrival')
        boss_of = self.boss_gates_of(room.get('id'))
        if not arr:
            problems.append('no gate arrival cell (where the player appears)')
        if boss_of:
            # S101: a boss floor ends the dive — no stairs; the way out is a
            # conversation's Helper / Move step or an ordinary exit
            outs = self.conversation_exits(room)
            if not outs and not other and not stairs:
                problems.append('boss room with no way out — give a conversation a "Helper '
                                'takes the player away" (or Move) step, or add an exit')
            notes.append('boss floor of gate ' + ', '.join(map(str, boss_of)))
            if outs:
                notes.append(f'{outs} conversation exit(s)')
        elif not stairs:
            problems.append('no Stairs down — the player could never leave the floor')
        mode = self.encounter_mode(room)
        if mode == 'fixed':
            problems.append('encounters use a FIXED pool — that would switch the dive to '
                            'that gate; pick "follow the gate" or off')
        if other:
            notes.append(f'{other} ordinary exit(s): walking through one leaves the dive')
        notes.append('saving allowed' if room.get('can_save', not boss_of) else 'no saving here')
        notes.append({'off': 'no battles', 'follow': "battles: the gate's own monsters",
                      'fixed': 'battles: fixed pool',
                      'own': 'battles: its own list (S114 — never re-routes the dive)'}[mode])
        notes.append(f"music: {room.get('music')}" if room.get('music')
                     else "music: the gate's (keeps playing)")
        return {'ready': not problems, 'problems': problems, 'notes': notes,
                'stairs': stairs, 'arrival': arr}
