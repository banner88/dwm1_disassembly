"""screen_palettes.py — S176: a SCREEN's own colours in a multi-screen room.

The user (S176): "I WAS UNDER THE IMPRESSION PALETTE WAS FIRMLY FIXED FOR ALL ROOMS OF A
MULTISTAGE ROOM! Please allow per-screen palette! … Make it explicit visually. What I'd basically
do is keep most of the tiles but flip 1 or 2 rows just for this room for the books."

The data was always there — `screens[k].palette` (a `custom.palettes` id; states[n].palette ›
screens[k].palette › render.palette, `Document.effective_palette`) — behind one unlabelled combo.
This module is the explicit form the Palettes page uses:

  give(doc, room, key, shown)   the screen gets a COPY of the colours it shows now
                                (`pal_<room>_s<key>`); nothing looks different until a row is
                                edited. The rows stamps on that screen recorded follow.
  drop(doc, room, key)          back to the room's colours (the copy is deleted when nothing
                                else uses it)
  own(doc, room, key)           its own palette id, or None
  differing(doc, room, key, shown_room, shown_screen)   rows 0-3 that are not the room's

and the GAME'S rule for a scroll between two screens with different colours (bank $73 entries
23 / 24, measured — ROOM_DATA_FORMAT "A screen's own colours and the scroll"): one hardware
palette draws both screens while they slide, so per row that differs

  * the screen leaving draws with it, the screen arriving does not -> switched when the scroll
    ENDS (`late`);
  * else -> switched when it STARTS (`now`); when BOTH draw with it the screen leaving shows the
    new colours while it slides out (a `clash` — `scroll_report` lists them, the editor warns).

`rows_drawn` = the rows a screen's colour grid uses (every state; + the rows of the stamps on
it, which the build bakes into the grid).

Pure logic (no Qt).
"""

SCREEN_COLS = 4            # the room's screens: a 4 x 4 grid, index = row * 4 + column


def own(doc, room, key):
    """The screen's own palette id (screen level), or None = the room's colours."""
    scr = (room.get('screens') or {}).get(str(key))
    return (scr or {}).get('palette') or None


def room_palette(room):
    return (room.get('render') or {}).get('palette')


def users(doc, pid):
    """[(room id, where)] of everything that names palette `pid`."""
    out = []
    for r in doc.rooms:
        if not isinstance(r, dict):
            continue
        if room_palette(r) == pid:
            out.append((r['id'], 'room'))
        for k, scr in (r.get('screens') or {}).items():
            if scr.get('palette') == pid:
                out.append((r['id'], f'screen {k}'))
            for n, st in enumerate(scr.get('states') or []):
                if st.get('palette') == pid:
                    out.append((r['id'], f'screen {k} state {n}'))
    return out


def _to555(c):
    return (c[0] >> 3) | ((c[1] >> 3) << 5) | ((c[2] >> 3) << 10)


def give(doc, room, key, shown):
    """Give screen `key` its OWN colours: a copy of what it shows now. `shown` = the 8 x 4 RGB
    the renderer shows for it (used when it draws with a game palette). -> the new palette id.
    A screen that already has its own keeps it."""
    scr = doc.screen(room, key)
    if scr.get('palette'):
        return scr['palette']
    src = doc.effective_palette(room, key, 0)
    base = f"pal_{room['id']}_s{int(key)}"
    pid, n = base, 2
    while any(p.get('id') == pid for p in doc.palettes):
        pid = f'{base}_{n}'
        n += 1
    name = doc.room_name(room)
    if src:
        sp = doc.palette(src)
        new = {'id': pid, 'label': f'CustomPaletteColors_{pid}',
               'placement': sp.get('placement', 'b'),
               'colors_rgb555': [list(r) for r in sp['colors_rgb555']],
               'comment': [f'screen {int(key)} of {name}: its own colours (copied from {src})']}
        if sp.get('free_color1'):
            new['free_color1'] = True
    else:
        rows = [[f'0x{_to555(c):04X}' for c in row] for row in shown[:8]]
        while len(rows) < 8:
            rows.append(['0x0000', '0x6BFF', '0x7FFF', '0x0000'])
        new = {'id': pid, 'label': f'CustomPaletteColors_{pid}', 'placement': 'b',
               'colors_rgb555': rows,
               'comment': [f'screen {int(key)} of {name}: its own colours (copied from the '
                           'game\'s)']}
    doc.palettes.append(new)
    scr['palette'] = pid
    # the rows stamps on this screen recorded on the old palette are theirs on the copy too
    for pl in room.get('stamps') or []:
        if int(pl.get('screen', -1)) == int(key) and isinstance(pl.get('rows'), dict):
            if src and src in pl['rows']:
                pl['rows'][pid] = list(pl['rows'][src])
    doc.touch()
    return pid


def drop(doc, room, key):
    """Back to the room's colours. The screen's palette is deleted when nothing else uses it.
    -> the palette id it had (None = it had none)."""
    scr = doc.screen(room, key)
    pid = scr.pop('palette', None)
    if not pid:
        return None
    for pl in room.get('stamps') or []:
        if int(pl.get('screen', -1)) == int(key) and isinstance(pl.get('rows'), dict):
            pl['rows'].pop(pid, None)
    if not users(doc, pid):
        doc.custom['palettes'] = [p for p in doc.palettes if p.get('id') != pid]
    doc.touch()
    return pid


def differing(shown_a, shown_b):
    """Rows 0-3 whose four colours differ between two shown palettes (8 x 4 RGB)."""
    return [r for r in range(4)
            if [tuple(c[:3]) for c in shown_a[r]] != [tuple(c[:3]) for c in shown_b[r]]]


def screens_with_own(doc, room):
    """{screen key: palette id} of the screens that do not draw with the room's colours
    (screen level or any state)."""
    out = {}
    base = room_palette(room)
    for k in doc.screen_keys(room):
        for s in range(len(doc.states(room, k))):
            pid = doc.effective_palette(room, k, s)
            if pid != base:
                out[k] = pid
                break
    return out


def rows_drawn(doc, renderer, room, key, stamp_rows=None):
    """{row 0-3: tiles drawn with it} on screen `key`, over its states (the most of any state).
    `stamp_rows` = {(room id, placement index, state): rows} from stamps.simulate (optional):
    the rows the stamps on the screen are baked with count as drawn (1 tile each at least)."""
    out = {}
    for s in range(len(doc.states(room, key))):
        try:
            A, _n = renderer.attr_grid(room, key, s)
        except Exception:                                    # noqa: BLE001 — a broken screen draws nothing
            A = None
        n = {}
        for row in A or []:
            for v in row:
                r = int(v) & 7
                if r < 4:
                    n[r] = n.get(r, 0) + 1
        if A is None:
            n = {0: 320}
        for r, c in n.items():
            out[r] = max(out.get(r, 0), c)
    for (rid, i, _s), rows in (stamp_rows or {}).items():
        if rid != room['id']:
            continue
        pls = room.get('stamps') or []
        if i < len(pls) and int(pls[i].get('screen', -1)) == int(key):
            for r in rows:
                if int(r) < 4:
                    out[int(r)] = max(out.get(int(r), 0), 1)
    return out


def neighbours(room, key):
    """[(other key, direction)] of the screens next to `key` in the room's 4 x 4 grid."""
    keys = {int(k) for k in (room.get('screens') or {})}
    k = int(key)
    out = []
    if k % SCREEN_COLS and k - 1 in keys:
        out.append((k - 1, 'left'))
    if k % SCREEN_COLS != SCREEN_COLS - 1 and k + 1 in keys:
        out.append((k + 1, 'right'))
    if k - SCREEN_COLS in keys:
        out.append((k - SCREEN_COLS, 'up'))
    if k + SCREEN_COLS in keys:
        out.append((k + SCREEN_COLS, 'down'))
    return out


def scroll_rule(changed, old_drawn, new_drawn):
    """The game's rule (bank $73 ScrollScreenBuild): -> (now, late, clash) row lists.
    changed = rows whose colours differ; old_drawn / new_drawn = rows the screen leaving /
    arriving draws with."""
    late = [r for r in changed if r in old_drawn and r not in new_drawn]
    now = [r for r in changed if r not in late]
    clash = [r for r in changed if r in old_drawn and r in new_drawn]
    return now, late, clash


def scroll_report(doc, renderer, room, stamp_rows=None):
    """[{'a', 'b', 'rows' (that differ), 'clash' (rows both draw with), 'tiles_a', 'tiles_b'
    (tiles drawn with the clashing rows)}] for every pair of screens side by side whose shown
    colours differ (state 0 of each), a < b."""
    out = []
    keys = doc.screen_keys(room)
    shown = {}
    drawn = {}
    for k in keys:
        try:
            shown[k] = renderer.room_palettes(room, k, 0)
        except Exception:                                    # noqa: BLE001
            shown[k] = None
    for a in keys:
        for b, _d in neighbours(room, a):
            if b < a or shown.get(a) is None or shown.get(b) is None:
                continue
            rows = differing(shown[a], shown[b])
            if not rows:
                continue
            for k in (a, b):
                if k not in drawn:
                    drawn[k] = rows_drawn(doc, renderer, room, k, stamp_rows)
            clash = [r for r in rows if drawn[a].get(r) and drawn[b].get(r)]
            out.append({'a': a, 'b': b, 'rows': rows, 'clash': clash,
                        'tiles_a': sum(drawn[a].get(r, 0) for r in clash),
                        'tiles_b': sum(drawn[b].get(r, 0) for r in clash)})
    return out


def report_text(doc, room, rep, key=None):
    """The warning lines for the Palettes page (only the pairs with `key` when given)."""
    lines = []
    for p in rep:
        if key is not None and int(key) not in (p['a'], p['b']):
            continue
        if not p['clash']:
            continue
        rows = ', '.join(str(r) for r in p['clash'])
        lines.append(f"Walking between screen {p['a']} and screen {p['b']}: row"
                     f"{'s' if len(p['clash']) > 1 else ''} {rows} differ and BOTH screens draw "
                     f"with {'them' if len(p['clash']) > 1 else 'it'} — the screen you leave "
                     'shows the new colours for the third of a second it slides out '
                     f"({p['tiles_a']} tiles on {p['a']}, {p['tiles_b']} on {p['b']}).")
    return lines
