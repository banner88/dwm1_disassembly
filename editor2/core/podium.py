"""podium.py — S177: an examine spot that TALKS FOR an NPC (a counter, a podium, a desk).

The user (S177): "The 'podium' in the library below the librarian — can it proxy the NPC
exactly? That way player can talk to pedestal OR to NPC with exactly the same outcome
(including first lines)." Conferred: "Yes that sounds great" (as the original game: answer
only from the front, the NPC turns to face the player).

The original game does exactly this (measured S177, map $12 the Library): the counter cell
(4,3) in front of the librarian (4,2) is an examine spot `$82` (the player must face UP)
running script 14, which is `face_down 1` (the librarian turns) followed by the librarian's
own script 15 — script 14 starts 4 bytes before script 15 ($0D:$66EE / $66F2) and falls into
it. Same lines, same flags, same menu.

project.json:
  {"kind": "examine", "x": 3, "y": 4, "facing": "up", "talks_for": {"x": 3, "y": 3}}
  — no "script": the spot runs the script of the NPC standing on `talks_for` in the same
  screen state, whatever it is when the build is made (a service, a talk, a cutscene that
  wraps the talk, a breeder…).

Lowering (`lower`, the LAST step of Project.__init__ — after the services, breeders,
cutscenes and screen songs have rewritten every talk): per spot a generated script
`podium:<room>:<screen>:<state>:<x>,<y>` = the NPC's face op toward the spot (actor = 1 + the
NPC's place among the list's NPC entries — the game numbers NPC slots in list order, spots
skipped, ROOM_DATA_FORMAT "Interact entries") + a copy of the NPC's final script's ops
(their labels are local to a script, scriptgen.emit_script). The spot is then an ordinary
examine spot of that script. Talking to the NPC itself is unchanged.
"""
import copy

DIRS = {'up': (0, -1), 'down': (0, 1), 'left': (-1, 0), 'right': (1, 0)}
OPPOSITE = {'up': 'down', 'down': 'up', 'left': 'right', 'right': 'left'}
FACE_OPS = {'up': 'face_up', 'down': 'face_down', 'left': 'face_left', 'right': 'face_right'}
SCRIPT_PREFIX = 'podium:'


class PodiumError(ValueError):
    pass


def _v(x):
    return int(x, 0) if isinstance(x, str) else int(x)


def _states(scr):
    return scr.get('states') or [scr]


def is_proxy(e):
    return isinstance(e, dict) and e.get('kind') == 'examine' and e.get('talks_for') is not None


def is_spot(e):
    """An entry the game's NPC parser skips (examine / step / spawn markers) — the
    emitter's rule (emitters._is_spot): what is not a spot takes an NPC slot."""
    k = e.get('kind')
    if k in ('spawn', 'examine', 'step', 'statue', 'monument', 'archive', 'jump'):
        return True
    return k == 'raw' and _v(e['bytes'][0]) >= 0x80


def cell_of(e):
    if e.get('kind') == 'raw':
        return _v(e['bytes'][2]), _v(e['bytes'][3])
    return _v(e['x']), _v(e['y'])


def npc_at(npcs, x, y):
    """(entry, actor number) of the NPC standing on (x, y) in this list, else (None, None).
    Actor n = NPC slot n - 1 = the n-th entry that is not a spot (list order)."""
    n = 0
    for e in npcs or []:
        if not isinstance(e, dict) or is_spot(e):
            continue
        n += 1
        if cell_of(e) == (int(x), int(y)):
            return e, n
    return None, None


def toward(frm, to):
    """The direction from cell `frm` to cell `to` (the larger axis; None when equal)."""
    dx, dy = to[0] - frm[0], to[1] - frm[1]
    if (dx, dy) == (0, 0):
        return None
    if abs(dy) >= abs(dx):
        return 'down' if dy > 0 else 'up'
    return 'right' if dx > 0 else 'left'


def front_facing(spot_xy, npc_xy):
    """The facing the PLAYER needs to read the spot from its far side: toward the NPC
    (the original counter: the librarian above it -> the player faces up)."""
    return toward(spot_xy, npc_xy) or 'any'


def npc_turn(spot_xy, npc_xy):
    """The way the NPC turns: toward the spot (the player is beyond it)."""
    return toward(npc_xy, spot_xy) or 'down'


def adjacent(a, b):
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) == 1


def script_id(room, key, state, x, y):
    return f"{SCRIPT_PREFIX}{room.get('id')}:{key}:{state}:{x},{y}"


def _room_name(r):
    return r.get('name') or r.get('id')


def _script_of(room, e):
    """The NPC entry's script id (a room-table index resolved), or None."""
    if e.get('kind') == 'raw':
        s = _v(e['bytes'][4])
    else:
        s = e.get('script')
    if s in (None, 'none') or s == 0xFF:
        return None
    if isinstance(s, int):
        return (room.get('scripts') or {}).get(str(s))
    return s


def entry_problem(room, key, state_idx, npcs, e):
    """An error that stops the build, or None."""
    tf = e.get('talks_for') or {}
    try:
        tx, ty = int(tf['x']), int(tf['y'])
    except (KeyError, TypeError, ValueError):
        return 'a podium spot needs "talks_for": {"x", "y"} (the NPC\'s cell)'
    npc, _n = npc_at(npcs, tx, ty)
    where = f"podium ({e['x']},{e['y']})"
    if npc is None:
        return (f'{where} talks for the NPC at ({tx},{ty}), but no NPC stands there in state '
                f'{state_idx} of the screen')
    if _script_of(room, npc) is None:
        return f'{where}: the NPC at ({tx},{ty}) has no script to run'
    return None


def lower(prj):
    """Every podium spot -> an examine spot of a generated script (the NPC's face op + its
    final script). Raises PodiumError (Project keeps it as podium_error; validators report it)."""
    custom = prj.custom
    scripts = custom.setdefault('scripts', [])
    by_id = {s.get('id'): s for s in scripts if isinstance(s, dict)}
    for r in custom.get('rooms') or []:
        if not isinstance(r, dict):
            continue
        for k, scr in (r.get('screens') or {}).items():
            if not isinstance(scr, dict):
                continue
            for si, st in enumerate(_states(scr)):
                npcs = st.get('npcs') or []
                for e in npcs:
                    if not is_proxy(e):
                        continue
                    p = entry_problem(r, k, si, npcs, e)
                    if p:
                        raise PodiumError(f"{_room_name(r)} screen {k}: {p}")
                    tf = e['talks_for']
                    tx, ty = int(tf['x']), int(tf['y'])
                    npc, actor = npc_at(npcs, tx, ty)
                    src = _script_of(r, npc)
                    body = by_id.get(src)
                    if body is None or not isinstance(body.get('ops'), list):
                        raise PodiumError(f"{_room_name(r)} screen {k}: podium ({e['x']},{e['y']}): "
                                          f"the NPC's script {src!r} is not a project script")
                    sid = script_id(r, k, si, e['x'], e['y'])
                    turn = npc_turn((int(e['x']), int(e['y'])), (tx, ty))
                    if sid not in by_id:
                        new = {'id': sid,
                               'ops': [['op', FACE_OPS[turn], actor]] + copy.deepcopy(body['ops']),
                               'comment': f"S177: the podium ({e['x']},{e['y']}) in "
                                          f"{_room_name(r)} screen {k} talks for the NPC at "
                                          f"({tx},{ty}) — it turns {turn}, then its script "
                                          f"{src} (podium.py, the original Library counter)"}
                        scripts.append(new)
                        by_id[sid] = new
                    table = r.setdefault('scripts', {})
                    if sid not in table.values():
                        if '0' not in table:
                            eid = f"{SCRIPT_PREFIX}{r.get('id')}_entry"
                            if eid not in by_id:
                                by_id[eid] = {'id': eid, 'ops': [['end']]}
                                scripts.append(by_id[eid])
                            table['0'] = eid
                        i = 1
                        while str(i) in table:
                            i += 1
                        table[str(i)] = sid
                    fac = e.get('facing') or front_facing((int(e['x']), int(e['y'])), (tx, ty))
                    x, y = int(e['x']), int(e['y'])
                    e.clear()
                    e.update({'kind': 'examine', 'x': x, 'y': y, 'facing': fac, 'script': sid,
                              'comment': f'podium: talks for the NPC at ({tx},{ty})',
                              '_podium': {'npc': [tx, ty], 'source': src}})


def spot_notes(room, key, state_idx, npcs, e):
    """[(level, words)] for one podium spot (the editor's panel and the validators)."""
    p = entry_problem(room, key, state_idx, npcs, e)
    if p:
        return [('error', p)]
    tf = e['talks_for']
    if not adjacent((int(e['x']), int(e['y'])), (int(tf['x']), int(tf['y']))):
        return [('warning', f"podium ({e['x']},{e['y']}) is not next to the NPC it talks for "
                            f"({tf['x']},{tf['y']})")]
    return []


def problems(prj):
    """-> (errors, warnings) in words (validators.validate). The spots are lowered by now:
    an error is Project.podium_error; the warnings come from the lowered spots' `_podium`."""
    errs, warns = [], []
    err = getattr(prj, 'podium_error', None)
    if err:
        return [f'podium: {err}'], warns
    for r in (prj.custom.get('rooms') or []):
        if not isinstance(r, dict):
            continue
        for k, scr in (r.get('screens') or {}).items():
            if not isinstance(scr, dict):
                continue
            for st in _states(scr):
                for e in st.get('npcs') or []:
                    pd = e.get('_podium') if isinstance(e, dict) else None
                    if pd and not adjacent((int(e['x']), int(e['y'])), tuple(pd['npc'])):
                        msg = (f"{_room_name(r)} screen {k}: podium ({e['x']},{e['y']}) is not "
                               f"next to the NPC it talks for ({pd['npc'][0]},{pd['npc'][1]})")
                        if msg not in warns:
                            warns.append(msg)
    return errs, warns


# ---------------------------------------------------------------------------
# Document side (mixed into Document): set / clear, the NPCs a spot can talk for
# ---------------------------------------------------------------------------
class PodiumDocMixin:
    def podium_candidates(self, room, key, state_idx):
        """[(x, y, label)] of the NPCs of this screen state a spot can talk for."""
        out = []
        for e in self.npc_entries(room, key, state_idx):
            if not isinstance(e, dict) or is_spot(e):
                continue
            x, y = cell_of(e)
            sid = _script_of(room, e)
            out.append((x, y, f"the NPC at ({x},{y})" + (f" — {sid}" if sid else ' (no script)')))
        return out

    def set_talks_for(self, room, key, state_idx, index, cell):
        """Make spot `index` talk for the NPC on `cell` ((x, y)), or None = its own script
        again. The facing becomes the front (toward the NPC) when the NPC is next to it."""
        lst = self.npc_entries(room, key, state_idx)
        old = copy.deepcopy(lst[index])
        e = lst[index]
        v = self.npc_view(room, e)
        if v['kind'] not in ('examine', 'spawn'):
            raise ValueError('only an examine spot can talk for an NPC')
        if cell is None:
            if e.get('talks_for') is None:
                return old
            src = self._podium_source(room, key, state_idx, e)
            e.pop('talks_for', None)
            if src:
                e['script'] = src
            if e.get('script') in (None, 'none'):
                raise ValueError('pick a script for the spot first (it has none of its own)')
            self.touch()
            return old
        x, y = int(cell[0]), int(cell[1])
        npc, _n = npc_at(lst, x, y)
        if npc is None:
            raise ValueError(f'no NPC at ({x},{y}) on this screen')
        new = {'kind': 'examine', 'x': v['x'], 'y': v['y'], 'talks_for': {'x': x, 'y': y}}
        sp = (v['x'], v['y'])
        new['facing'] = front_facing(sp, (x, y)) if adjacent(sp, (x, y)) else v.get('facing', 'any')
        lst[index] = new
        self.touch()
        return old

    def _podium_source(self, room, key, state_idx, e):
        tf = e.get('talks_for') or {}
        npc, _n = npc_at(self.npc_entries(room, key, state_idx), tf.get('x', -1), tf.get('y', -1))
        return _script_of(room, npc) if npc is not None else None

    def follow_npc_move(self, room, key, state_idx, old_xy, new_xy):
        """An NPC moved: the spots of that state that talk for its old cell follow it."""
        for e in self.npc_entries(room, key, state_idx):
            tf = e.get('talks_for') if isinstance(e, dict) else None
            if tf and (int(tf.get('x', -1)), int(tf.get('y', -1))) == tuple(old_xy):
                tf['x'], tf['y'] = int(new_xy[0]), int(new_xy[1])
