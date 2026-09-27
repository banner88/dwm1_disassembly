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


def gate_floors(gate_id, start=None):
    for g in vanilla_gates(start):
        if g['id'] == gate_id:
            return g['floors']
    return None


def floor_range(spec, floors):
    """Authored floors -> (first, last) in the game's numbering.
    spec: [a, b] | [a] | a | "all" (= every floor a room may take)."""
    if spec in (None, 'all', 'any'):
        return MIN_FLOOR, (floors - 1 if floors else 254)
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


def floors_text(spec, floors=None):
    a, b = floor_range(spec, floors)
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

    def gate_rule_rows(self, gate_id):
        """Display rows for effective_chances (flag terms unresolved)."""
        floors = gate_floors(gate_id, getattr(self, 'project_dir', None))
        rows = []
        for i, r in self.gate_rules_for(gate_id):
            try:
                a, b = floor_range(r.get('floors', 'all'), floors)
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
        floors = gate_floors(gate_id, getattr(self, 'project_dir', None)) or 0
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
                plan.append((f, [], 'boss floor', 1.0))
                continue
            if f == 1:
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
        return 'follow' if enc.get('follow_gate') else 'fixed'

    def set_encounter_mode(self, room, mode):
        """'off' | 'follow' (the dive's own gate/floor) | 'fixed' (keep the
        room's pinned gate/floor — never for rooms served in gates)."""
        enc = dict(room.get('encounters') or {})
        if mode == 'off':
            room.pop('encounters', None)
        elif mode == 'follow':
            room['encounters'] = {'enabled': True, 'follow_gate': True}
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
        if not arr:
            problems.append('no gate arrival cell (where the player appears)')
        if not stairs:
            problems.append('no Stairs down — the player could never leave the floor')
        mode = self.encounter_mode(room)
        if mode == 'fixed':
            problems.append('encounters use a FIXED pool — that would switch the dive to '
                            'that gate; pick "follow the gate" or off')
        if other:
            notes.append(f'{other} ordinary exit(s): walking through one leaves the dive')
        notes.append('saving allowed' if room.get('can_save', True) else 'no saving here')
        notes.append({'off': 'no battles', 'follow': "battles: the gate's own monsters",
                      'fixed': 'battles: fixed pool'}[mode])
        notes.append(f"music: {room.get('music')}" if room.get('music')
                     else "music: the gate's (keeps playing)")
        return {'ready': not problems, 'problems': problems, 'notes': notes,
                'stairs': stairs, 'arrival': arr}
