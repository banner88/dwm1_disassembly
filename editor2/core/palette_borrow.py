"""palette_borrow.py — borrow another room's colours (S132, no Qt).

User S132: "Need to be able to borrow palette from any other room without
having to recreate it". Before S132 the Rooms inspector's palette combos could
only copy a VANILLA room's default palette (screen 0, step 0 — not the Servant
room on fire, not the night Farm), listed your own rooms' palettes by palette
id, had no gate themes and no per-row copy.

A SOURCE is any room the editor can draw:
    ('vanilla', mid)  — a game room, per screen and per step (the palette that
                        step's attr-table row points at, $17:$476F; the room's
                        derived default when a step has none)
    ('room', rid)     — one of your rooms, per screen and state (its project
                        palette, or the vanilla palette it still shows)
    ('theme', t)      — a gate theme (maze floor type t, $17:$51F5[t])

`source_rows` gives the 4 environment rows (RGB555; colours 1 / 3 as the source
shows them) + whether colour 1 is the source's own (free_color1). Rows 4-7 of
a project palette are the shared system rows and are never borrowed.

`apply_borrow` is the one Document operation (the GUI wraps it in a
SnapshotCommand): either the WHOLE palette for the room or for one screen/state
(copied into a new project palette, or — for a palette of your own — shared by
id), or chosen ROWS copied into the palette this screen/state uses (made the
room's own first when it still borrows a vanilla palette; copied first when the
user asks for "only here" and other places share it).
"""

from .document import val
from .render_project import FORCED_IDX1, FORCED_IDX3

SYSTEM_ROWS = [[0x0000, 0x6BFF, 0x7FFF, 0x0000] for _ in range(4)]
THEME_PREVIEW_CELL = 0x00          # a maze screen to show a theme's colours on


def to555(rgb):
    r, g, b = rgb
    return (r >> 3) | ((g >> 3) << 5) | ((b >> 3) << 10)


# ----------------------------------------------------------------- sources
def sources(doc, renderer):
    """[(source, label)] — your rooms, then the game's rooms, then the 16
    gate themes."""
    from .maze import THEME_NAMES
    out = []
    for room in doc.rooms:
        if room.get('placeholder'):
            continue
        out.append((('room', room['id']),
                    f"Your room ${val(room['mapID']):02X}  {doc.room_name(room)}"))
    for mid, name, _scr in renderer.vanilla_rooms():
        out.append((('vanilla', int(mid)), f'Game room ${mid:02X}  {name}'))
    for t, nm in enumerate(THEME_NAMES):
        out.append((('theme', t), f'Gate theme {t}: {nm}'))
    return out


def screens_of(doc, renderer, src):
    """[(screen key, number of states)] of a source."""
    kind, v = src
    if kind == 'room':
        room = doc.room(v)
        return [(k, len(doc.states(room, k))) for k in doc.screen_keys(room)]
    if kind == 'vanilla':
        scr = next((s for m, _n, s in renderer.vanilla_rooms() if m == v), [])
        return [(k, max(1, len(renderer.vanilla_steps(v, k)))) for k in scr]
    return [(0, 1)]


def source_rows(doc, renderer, src, screen=0, state=0):
    """(4 rows of 4 RGB555 words, own_colour1, description)."""
    kind, v = src
    if kind == 'theme':
        from .maze import THEME_NAMES
        rows = [list(r) for r in renderer.theme_palette_words(v)][:4]
        return rows, False, f'gate theme {v} ({THEME_NAMES[v]})'
    if kind == 'vanilla':
        words = None
        try:
            words = renderer.vanilla_step_palette_words(v, screen, state)
        except Exception:                                     # noqa: BLE001
            words = None
        if not words:
            pals = renderer.vanilla_palettes(v)
            words = [[to555(c) for c in row] for row in pals[:4]]
        name = renderer.vanilla_name(v)
        return ([list(r) for r in words[:4]], False,
                f'game room ${v:02X} {name}, screen {screen} step {state}')
    room = doc.room(v)
    pid, words = renderer.room_palettes_555(room, screen, state)
    if words:
        free1 = bool(doc.palette(pid).get('free_color1'))
        rows = [list(r) for r in words[:4]]
        for r in rows:
            if not free1:
                r[1] = FORCED_IDX1
            r[3] = FORCED_IDX3
        return rows, free1, f'your room {doc.room_name(room)}, screen {screen} state {state} ({pid})'
    pals = renderer.room_palettes(room, screen, state)
    return ([[to555(c) for c in row] for row in pals[:4]], False,
            f'your room {doc.room_name(room)}, screen {screen} state {state} '
            '(still the game\'s palette)')


def source_pid(doc, renderer, src, screen=0, state=0):
    """The project palette id behind a source, when there is one (only then
    can it be SHARED instead of copied)."""
    if src[0] != 'room':
        return None
    pid, words = renderer.room_palettes_555(doc.room(src[1]), screen, state)
    return pid if words else None


def source_picture(doc, renderer, src, screen=0, state=0):
    """PIL picture of the source screen in its own colours."""
    kind, v = src
    if kind == 'room':
        return renderer.render_screen(doc.room(v), screen, state)
    if kind == 'vanilla':
        return renderer.render_vanilla_screen(v, screen, 1, step=state)
    gfx = renderer.theme_gfx(v)
    return renderer.render_maze_piece(THEME_PREVIEW_CELL, 0, gfx.sheet, renderer.theme_palettes(v))


# --------------------------------------------------------------- composing
def rows_to_rgb(rows, free1=False):
    """4 RGB555 rows -> 8 RGB rows as the canvas shows them (forced colours
    applied, system rows 4-7)."""
    from .render_project import rgb555, SYSTEM_PAL
    out = []
    for r in rows[:4]:
        r = list(r)
        if not free1:
            r[1] = FORCED_IDX1
        r[3] = FORCED_IDX3
        out.append([rgb555(c & 0x7FFF) for c in r])
    while len(out) < 8:
        out.append(list(SYSTEM_PAL))
    return out


def mixed_rows(mine, theirs, mapping):
    """mine / theirs: 4 RGB555 rows; mapping {my slot: their row or None}."""
    out = [list(r) for r in mine[:4]]
    for slot, row in (mapping or {}).items():
        if row is not None and 0 <= int(slot) < 4 and 0 <= int(row) < 4:
            out[int(slot)] = list(theirs[int(row)])
    return out


def palette_users(doc, pid):
    """[(room id, screen key or None, state or None)] that show palette pid
    (room default = screen None)."""
    out = []
    for room in doc.rooms:
        if (room.get('render') or {}).get('palette') == pid:
            out.append((room['id'], None, None))
        for k, scr in (room.get('screens') or {}).items():
            sts = scr.get('states')
            if sts:
                for n, st in enumerate(sts):
                    if st.get('palette') == pid:
                        out.append((room['id'], int(k), n))
            elif scr.get('palette') == pid:
                out.append((room['id'], int(k), 0))
    return out


def _new_pid_base(doc, room_id, src):
    kind, v = src
    tag = (f'{v:02X}' if kind == 'vanilla' else f'theme{v}' if kind == 'theme' else str(v))
    return f'pal_{room_id}_from_{tag}'


def apply_borrow(doc, room_id, key, state, src, src_rows, src_free1, mode,
                 scope='room', share_pid=None, mapping=None, only_here=False,
                 current_words=None, description=''):
    """Borrow colours into room `room_id`.

    mode 'whole': rows 0-3 of the source become the palette of the room
      (scope 'room': render.palette; screens / states that showed the old
      default follow it, ones with their own palette keep it) or of this
      screen/state only (scope 'here'). share_pid = use that project palette
      itself (shared); else a new project palette is made.
    mode 'rows': mapping {my slot: their row} copied into the palette this
      screen/state uses; `current_words` (8x4 RGB555 as displayed) makes it the
      room's own first when it still borrows a vanilla palette; only_here = copy
      a shared palette first so the other places keep their colours.
    Returns (palette id, what changed — a sentence)."""
    room = doc.room(room_id)
    if mode == 'whole':
        if share_pid:
            pid = share_pid
        else:
            pid = doc.add_palette_from_words(
                _new_pid_base(doc, room_id, src),
                [list(r) for r in src_rows[:4]] + [list(r) for r in SYSTEM_ROWS],
                f'borrowed from {description}' if description else 'borrowed')
            if src_free1:
                doc.palette(pid)['free_color1'] = True
        if scope == 'here':
            doc.set_state_palette(room, key, state, pid)
            return pid, f'screen {key} state {state} now uses {pid}'
        render = room.setdefault('render', {})
        old = render.get('palette')
        render['palette'] = pid
        for _k, scr in (room.get('screens') or {}).items():
            for st in (scr.get('states') or [scr]):
                if old is not None and st.get('palette') == old:
                    st.pop('palette')
        doc.touch()
        return pid, f'the room now uses {pid}'
    # rows
    if not mapping or all(v is None for v in mapping.values()):
        raise ValueError('pick at least one row to copy')
    from editor2.core.render_project import ProjectRenderer  # noqa: F401  (type only)
    pid = None
    scr = doc.screen(room, key)
    target = scr['states'][state] if scr.get('states') else scr
    pid = target.get('palette') or (room.get('render') or {}).get('palette')
    if pid is not None and not any(p.get('id') == pid for p in doc.palettes):
        pid = None
    if pid is None:
        if current_words is None:
            raise ValueError('the screen still shows the game\'s palette — current colours needed')
        pid = doc.localize_palette(room, key, state, current_words)
    elif only_here and len(palette_users(doc, pid)) > 1:
        rows = [[val(c) for c in r] for r in doc.palette(pid)['colors_rgb555']]
        new = doc.add_palette_from_words(f'{pid}_{room_id}_s{key}', rows,
                                         f'copy of {pid} for screen {key} state {state}')
        if doc.palette(pid).get('free_color1'):
            doc.palette(new)['free_color1'] = True
        doc.set_state_palette(room, key, state, new)
        pid = new
    pal = doc.palette(pid)
    changed = []
    for slot, row in sorted(mapping.items()):
        if row is None:
            continue
        words = list(src_rows[int(row)])
        pal['colors_rgb555'][int(slot)] = [f'0x{int(c) & 0x7FFF:04X}' for c in words]
        changed.append(f'slot {slot} ← their row {row}')
    doc.touch()
    return pid, f"{pid}: " + ', '.join(changed)
