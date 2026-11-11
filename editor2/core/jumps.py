"""jumps.py — JUMPING POINTS (S175, ROADMAP P3.3n): the GreatTree cliff jump, anywhere.

Headless (no Qt). How the game does it (PyBoy-measured S175 on the original ROM,
ROOM_DATA_FORMAT "Jumping points (S175)"): a jumping step is an ordinary STEP-ON
trigger ($90) on the bump cell whose script is

    write_ram $D9E8, 1        ; player input locked until the next screen scroll ends
    sound $55                 ; the jump sound
    walk_fast                 ; op $22 (scriptgen's legacy name: begin_walk)
    npc_walk_y 0, +N px       ; the player walks straight down through anything
    wait_movement
    end

(GreatTree map $01: screen 0 (6,6) script 18 and screen 4 (6,6) script 19 fall 6 cells,
screen 8 (6,7) script 20 falls 3 — bank $0C `GreatTree_Script18`-`20`). The scroll to
the screen below starts only AFTER the script ends, and $D9E8 is cleared only at the end
of a screen scroll (bank $06 `ScrollEndCommit`) — so (measured, the fall length patched
in copies of the ROM):
  * a landing on the SAME screen never scrolls: $D9E8 stays 1, the player can never move
    again (a soft lock);
  * a landing TWO screens down scrolls twice and leaves the controls odd;
  * a landing anywhere on the screen DIRECTLY BELOW works (rows 0-7); a landing in a wall
    leaves the player standing in the wall.
So a jump here always lands on the screen below, same column, a row of the author's
choice.

Schema (an entry of a screen's / state's `npcs[]`, like the statues; PROJECT_COMPILER
§2.80):  {"kind": "jump", "x": 6, "y": 6, "land_y": 4}   (+ optional "sound": "0x55")
= the jump cell (x, y) of screen k, landing on screen k + 4 at (x, land_y).
`lower(prj)` (Project.__init__) turns each into a `step` entry whose script is the
recipe above (one generated script per room and fall length / sound:
`_jump_<room id>_<pixels>[_s<sound>]`), so the emitters see nothing new; a project
without jumps compiles exactly as before.
"""

from . import formats as F

SOUND_DEFAULT = 0x55                 # the GreatTree jump sound (scripts 18-20)
SCRIPT_PREFIX = '_jump_'
CELLS_W, CELLS_H = 10, 8
GRID_COLS = 4
INPUT_LOCK = 0xD9E8                  # BANK04_SCRIPT_ENGINE "$D9E8"


class JumpError(ValueError):
    pass


def _states(scr):
    sts = scr.get('states')
    if isinstance(sts, list) and sts:
        return sts
    return [scr]


def _room_name(r):
    return r.get('name') or r.get('id') or '?'


def is_jump(e):
    return isinstance(e, dict) and e.get('kind') == 'jump'


def landing_key(key):
    """The screen a jump on screen `key` lands on (the one directly below), or None."""
    k = int(key) + GRID_COLS
    return k if k < GRID_COLS * GRID_COLS else None


def fall_px(y, land_y):
    """Pixels the player walks down: from row y of a screen to row land_y of the one below."""
    return (CELLS_H - int(y) + int(land_y)) * 16


def sound_of(e):
    s = e.get('sound')
    return SOUND_DEFAULT if s is None else F.val(s)


def script_id(room, e):
    sid = f"{SCRIPT_PREFIX}{room.get('id')}_{fall_px(e['y'], e['land_y'])}"
    if sound_of(e) != SOUND_DEFAULT:
        sid += f"_s{sound_of(e):02X}"
    return sid


def script_ops(e):
    """The game's own recipe (GreatTree_Script19), the fall in pixels."""
    return [['op', 'write_ram', f'0x{INPUT_LOCK:04X}', '0x0001'],
            ['op', '0x21', f'0x{sound_of(e):04X}'],
            ['op', 'begin_walk'],                      # op $22 walk_fast
            ['op', 'npc_walk_y', '0x0000', f"0x{fall_px(e['y'], e['land_y']):04X}"],
            ['op', 'wait_movement'],
            ['end']]


def entry_problem(room, key, e):
    """A sentence when the jump cannot work, else None."""
    try:
        x, y, ly = int(e['x']), int(e['y']), int(e['land_y'])
    except (KeyError, TypeError, ValueError):
        return 'a jump needs x, y and land_y'
    if not (0 <= x < CELLS_W and 0 <= y < CELLS_H):
        return f'the jump cell ({x},{y}) is off the screen'
    if not 0 <= ly < CELLS_H:
        return f'the landing row {ly} is off the screen below (rows 0-7)'
    below = landing_key(key)
    if below is None:
        return (f'screen {key} is on the bottom row of the grid — there is no screen below to '
                'land on')
    if str(below) not in (room.get('screens') or {}):
        return (f'screen {key} has no screen below it (screen {below}) — a jump must land on '
                'the screen directly below (landing on the same screen locks the player for good)')
    s = sound_of(e)
    if not 0 <= s <= 0xFF:
        return f'sound {s} is not a sound id (0-255)'
    return None


def lower(prj):
    """Every jump -> a step-on trigger + its script (mutates prj.custom like the other
    lowerings). Raises JumpError (Project keeps it as jump_error; validators report it)."""
    custom = prj.custom
    scripts = custom.setdefault('scripts', [])
    have = {s.get('id') for s in scripts if isinstance(s, dict)}
    for r in custom.get('rooms') or []:
        if not isinstance(r, dict):
            continue
        found = []
        for k, scr in (r.get('screens') or {}).items():
            if not isinstance(scr, dict):
                continue
            for st in _states(scr):
                for e in st.get('npcs') or []:
                    if is_jump(e):
                        found.append((int(k), e))
        if not found:
            continue
        if r.get('mapID') is None:
            raise JumpError(f'{_room_name(r)}: jumps only work in the project\'s rooms')
        table = r.setdefault('scripts', {})
        for k, e in found:
            p = entry_problem(r, k, e)
            if p:
                raise JumpError(f"{_room_name(r)} screen {k}: {p}")
            sid = script_id(r, e)
            if sid not in have:
                scripts.append({'id': sid, 'ops': script_ops(e),
                                'comment': f"S175: a jump in {_room_name(r)} — fall "
                                           f"{fall_px(e['y'], e['land_y'])} px (jumps.py, the "
                                           "GreatTree recipe)"})
                have.add(sid)
            if sid not in table.values():
                if '0' not in table:
                    eid = f"{SCRIPT_PREFIX}{r.get('id')}_entry"
                    if eid not in have:
                        scripts.append({'id': eid, 'ops': [['end']]})
                        have.add(eid)
                    table['0'] = eid
                i = 1
                while str(i) in table:
                    i += 1
                table[str(i)] = sid
            x, y, ly = int(e['x']), int(e['y']), int(e['land_y'])
            e.clear()
            e.update({'kind': 'step', 'x': x, 'y': y, 'script': sid,
                      'comment': f'jump: lands on screen {landing_key(k)} ({x},{ly})',
                      '_jump': {'screen': k, 'land_y': ly}})


# ---------------------------------------------------------------------------
# checks (validators.validate) — the build stops on an error, warns on the rest
# ---------------------------------------------------------------------------
def _grid_of(prj_or_doc, room, key, state):
    """The 16x20 tile grid of (screen, state) when it is a project layout, else None."""
    scr = (room.get('screens') or {}).get(str(key)) or {}
    sts = scr.get('states') or []
    ref = (sts[state].get('layout') if state < len(sts) else None) or scr.get('layout') or {}
    lid = ref.get('id') if isinstance(ref, dict) else None
    if not lid:
        return None
    for lay in getattr(prj_or_doc, 'layouts', None) or []:
        if isinstance(lay, dict) and lay.get('id') == lid:
            return lay.get('tiles')
    return None


def cell_walkable(grid, threshold, x, y):
    """The engine samples the cell's BOTTOM-RIGHT subtile (ROOM_DATA_FORMAT "Walkability",
    S94); the map byte (& $FF: page 2 tile n walks like page-1 n, S168) >= the threshold."""
    return (int(grid[y * 2 + 1][x * 2 + 1]) & 0xFF) >= int(threshold)


def _threshold(room):
    try:
        return F.val((room.get('record') or {}).get('collision_threshold'))
    except Exception:                                           # noqa: BLE001
        return None


def column_cells(key, x, y, land_y):
    """[(screen, x, row)] the player walks THROUGH (after the jump cell) down to the landing."""
    out = [(int(key), int(x), r) for r in range(int(y) + 1, CELLS_H)]
    out += [(landing_key(key), int(x), r) for r in range(0, int(land_y) + 1)]
    return out


def room_jumps(room):
    """[(screen, state, npcs index, entry)] of every jump of a room (unlowered data)."""
    out = []
    for k, scr in (room.get('screens') or {}).items():
        if not isinstance(scr, dict):
            continue
        for s, st in enumerate(_states(scr)):
            for i, e in enumerate(st.get('npcs') or []):
                if is_jump(e):
                    out.append((int(k), s, i, e))
    return out


def warnings_for(src, room, key, state, e):
    """Words about a jump that works but may surprise (walls, exits on the way)."""
    out = []
    thr = _threshold(room)
    x, y, ly = int(e['x']), int(e['y']), int(e['land_y'])
    below = landing_key(key)
    if thr is not None:
        g = _grid_of(src, room, key, state)
        if g is not None and not cell_walkable(g, thr, x, y):
            out.append(f'the jump cell ({x},{y}) is a wall — the player can never step on it')
        scr_b = (room.get('screens') or {}).get(str(below)) or {}
        for s in range(len(_states(scr_b)) if scr_b else 0):
            gb = _grid_of(src, room, below, s)
            if gb is not None and not cell_walkable(gb, thr, x, ly):
                out.append(f'the landing cell ({x},{ly}) on screen {below} is a wall'
                           + (f' in state {s}' if len(_states(scr_b)) > 1 else '')
                           + ' — the player lands inside it and is stuck')
                break
    # S152 r3 (measured): a walk-on exit fires when a SCRIPT walks the player onto it
    for (k, cx, cy) in column_cells(key, x, y, ly):
        scr = (room.get('screens') or {}).get(str(k)) or {}
        hit = False
        for st in _states(scr):
            for ex in st.get('exits') or []:
                try:
                    if (F.val(ex.get('x')), F.val(ex.get('y'))) == (cx, cy):
                        hit = True
                except Exception:                               # noqa: BLE001
                    pass
        if hit:
            out.append(f'an exit sits on the way down (screen {k} cell ({cx},{cy})) — a walk '
                       'onto an exit fires it, even a scripted one')
    return out


def problems(prj):
    """-> (errors, warnings) in words."""
    errs, warns = [], []
    err = getattr(prj, 'jump_error', None)
    if err:
        errs.append(f'jump: {err}')
        return errs, warns
    for r in (prj.custom.get('rooms') or []):
        if not isinstance(r, dict):
            continue
        for k, scr in (r.get('screens') or {}).items():
            if not isinstance(scr, dict):
                continue
            for s, st in enumerate(_states(scr)):
                for e in st.get('npcs') or []:
                    j = e.get('_jump') if isinstance(e, dict) else None
                    if not j:
                        continue
                    view = {'x': e['x'], 'y': e['y'], 'land_y': j['land_y']}
                    for w in warnings_for(prj, r, int(k), s, view):
                        msg = f"{_room_name(r)} screen {k}: jump ({e['x']},{e['y']}): {w}"
                        if msg not in warns:
                            warns.append(msg)
    return errs, warns


# ---------------------------------------------------------------------------
# editing (Document mixin; every change is one undo step in the Rooms tab)
# ---------------------------------------------------------------------------
class JumpsMixin:
    """Jumps live in npcs[] like the statues: one entry per state that has the jump."""

    def _jump_cell_free(self, room, key, state_idx, x, y, skip=None):
        for i, e in enumerate(self.npc_entries(room, key, state_idx)):
            if i == skip:
                continue
            v = self.npc_view(room, e)
            if (v['x'], v['y']) == (int(x), int(y)) and v['kind'] in (
                    'examine', 'step', 'spawn', 'statue', 'monument', 'archive', 'jump'):
                raise ValueError(f"cell ({x},{y}) already has a {v['kind']} here")

    def default_landing(self, room, key, x, y=None, walkable=None):
        """The first walkable row of column x on the screen below (state 0), counted from the
        top — the plank under the cliff; `walkable(screen, x, row)` -> bool (the GUI passes
        the renderer's test); None -> row 0."""
        below = landing_key(key)
        if below is None or walkable is None:
            return 0
        for r in range(CELLS_H):
            try:
                if walkable(below, int(x), r):
                    return r
            except Exception:                                   # noqa: BLE001
                return 0
        return 0

    def add_jump(self, room, key, state_idx, x, y, land_y, states=None, sound=None):
        """A jump on (x, y) of screen `key`, landing on (x, land_y) of the screen below — in
        `states` (default: every state of the screen). -> its npcs index in `state_idx`."""
        e = {'kind': 'jump', 'x': int(x), 'y': int(y), 'land_y': int(land_y)}
        if sound is not None and F.val(sound) != SOUND_DEFAULT:
            e['sound'] = f'0x{F.val(sound):02X}'
        p = entry_problem(room, key, e)
        if p:
            raise ValueError(p)
        n = len(self.states(room, key))
        want = sorted(set(range(n) if states is None else (int(s) for s in states)) | {int(state_idx)})
        for s in want:
            self._jump_cell_free(room, key, s, x, y)
        idx = None
        for s in want:
            lst = self.npc_entries(room, key, s)
            lst.append(dict(e))
            if s == int(state_idx):
                idx = len(lst) - 1
        self.touch()
        return idx

    def _jump_rows(self, room, key, x, y):
        """[(state, npcs index)] of the jump on cell (x, y) of screen key, every state."""
        out = []
        for s in range(len(self.states(room, key))):
            for i, e in enumerate(self.npc_entries(room, key, s)):
                if is_jump(e) and (int(e['x']), int(e['y'])) == (int(x), int(y)):
                    out.append((s, i))
        return out

    def update_jump(self, room, key, state_idx, index, **fields):
        """land_y / sound / x / y of the jump (in every state that has it)."""
        e0 = self.npc_entries(room, key, state_idx)[index]
        if not is_jump(e0):
            raise ValueError('not a jump')
        new = dict(e0)
        for f in ('x', 'y', 'land_y'):
            if f in fields:
                new[f] = int(fields[f])
        if 'sound' in fields:
            sv = fields['sound']
            if sv is None or F.val(sv) == SOUND_DEFAULT:
                new.pop('sound', None)
            else:
                new['sound'] = f'0x{F.val(sv):02X}'
        p = entry_problem(room, key, new)
        if p:
            raise ValueError(p)
        rows = self._jump_rows(room, key, e0['x'], e0['y'])
        if (new['x'], new['y']) != (int(e0['x']), int(e0['y'])):
            for s, i in rows:
                self._jump_cell_free(room, key, s, new['x'], new['y'], skip=i)
        for s, i in rows:
            lst = self.npc_entries(room, key, s)
            lst[i] = dict(new)
        self.touch()
        return e0

    def jump_presence(self, room, key, state_idx, index):
        e = self.npc_entries(room, key, state_idx)[index]
        here = {s for s, _i in self._jump_rows(room, key, e['x'], e['y'])}
        return [s in here for s in range(len(self.states(room, key)))]

    def set_jump_presence(self, room, key, state_idx, index, target, present):
        e = self.npc_entries(room, key, state_idx)[index]
        rows = dict(self._jump_rows(room, key, e['x'], e['y']))
        target = int(target)
        if present and target not in rows:
            self._jump_cell_free(room, key, target, e['x'], e['y'])
            self.npc_entries(room, key, target).append(dict(e))
        elif not present and target in rows:
            if len(rows) == 1:
                raise ValueError('the jump is only in this state — Delete removes it')
            self.npc_entries(room, key, target).pop(rows[target])
        self.touch()

    def remove_jump(self, room, key, state_idx, index):
        """Remove the jump from every state of the screen."""
        e = self.npc_entries(room, key, state_idx)[index]
        rows = self._jump_rows(room, key, e['x'], e['y'])
        for s, i in sorted(rows, key=lambda t: -t[1]):
            self.npc_entries(room, key, s).pop(i)
        self.touch()

    def jumps_landing_on(self, room, key):
        """[(from screen, x, y, land_y)] of the jumps landing on screen `key` (any state)."""
        src = int(key) - GRID_COLS
        if src < 0 or str(src) not in (room.get('screens') or {}):
            return []
        seen, out = set(), []
        for _k, _s, _i, e in room_jumps({'screens': {str(src): room['screens'][str(src)]}}):
            t = (src, int(e['x']), int(e['y']), int(e['land_y']))
            if t not in seen:
                seen.add(t)
                out.append(t)
        return out
