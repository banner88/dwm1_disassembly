"""world.py — the room / warp graph (S98, ROADMAP P3.7 "World graph v0").

Pure data, no Qt: nodes are the project's custom rooms plus every vanilla
room one of them connects to (or the whole vanilla world on request); edges
are what moves the player between rooms, read from the SAME schema data the
compiler emits (nothing re-derived from bytes):

  door      two-way link between two door objects (S98 r2: `door` + `link`)
  exit      one-way exit row in a custom room (authored teleports, cloned
            vanilla exits)
  redirect  a vanilla door re-pointed one-way into a custom room (S94b)
  warp      a script warp: `map_transition` ops and talk `move` actions
  vanilla   vanilla -> vanilla exits (only with include_vanilla)
"""

import math
import random


def _v(x):
    if isinstance(x, int):
        return x
    s = str(x).strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


def dest_key(doc, dest):
    """'room:$6B' / 'vanilla:$01' -> node key, or None."""
    s = str(dest)
    if ':' not in s:
        try:
            mid = _v(s)
        except Exception:
            return None
        kind = 'vanilla' if mid < 0x6B else 'room'
    else:
        kind, v = s.split(':', 1)
        mid = int(v.lstrip('$'), 16) if v.startswith('$') else _v(v)
    if kind == 'room' or mid >= 0x6B:
        for r in doc.rooms:
            if not r.get('placeholder') and _v(r['mapID']) == mid:
                return ('room', r['id'])
        return None
    return ('vanilla', mid)


def world_graph(doc, renderer=None, include_vanilla=False):
    from editor2.core import place_names as PN       # S143 (ARC CAP4b): names only
    pl = PN.Places.of(doc)
    nodes, edges = {}, []

    def node(key):
        if key is None:
            return None
        if key not in nodes:
            if key[0] == 'room':
                r = doc.room(key[1])
                nodes[key] = {'key': key, 'mapID': _v(r['mapID']), 'label': doc.room_name(r),
                              'custom': True, 'area': (r.get('area') or '').strip()}
            else:
                nodes[key] = {'key': key, 'mapID': key[1], 'label': pl.vanilla_label(key[1], ids=False),
                              'custom': False, 'area': PN.GAME}
        return key

    for r in doc.rooms:
        if not r.get('placeholder'):
            node(('room', r['id']))
    # doors (S98 r2: linked door objects; each pair drawn once)
    seen = set()
    for did in doc.door_ids():
        me, p = doc.door_end(did), doc.door_partner(did)
        if me is None or p is None or frozenset((did, p['id'])) in seen:
            continue
        seen.add(frozenset((did, p['id'])))
        ks = [node(('room', e['room']) if e['kind'] == 'room' else ('vanilla', e['mapID']))
              for e in (me, p)]
        edges.append({'a': ks[0], 'b': ks[1], 'kind': 'door', 'both': True,
                      'label': f"{me['name']} ↔ {p['name']}"})
    # one-way exits (per distinct cell, all states merged)
    for r in doc.rooms:
        if r.get('placeholder'):
            continue
        a = ('room', r['id'])
        got = set()
        for k in doc.screen_keys(r):
            for st in doc.states(r, k):
                for e in st.get('exits') or []:
                    if e.get('door') or not e.get('dest'):
                        continue
                    if _v(e.get('gate_flag', 0)) in (0x80, 1):
                        continue        # S100: Stairs down = next gate floor, not a map link;
                                        # S115: gate_flag 1 = a gate entrance (dest = a gate)
                    b = node(dest_key(doc, e.get('dest')))
                    sig = (k, _v(e['x']), _v(e['y']), b)
                    if b is None or sig in got:
                        continue
                    got.add(sig)
                    edges.append({'a': a, 'b': b, 'kind': 'exit', 'both': False,
                                  'label': f"one-way exit: screen {k} ({_v(e['x'])},{_v(e['y'])})"
                                           f" -> {pl.label(e.get('dest'))}"})
    # one-way redirects
    for rd in doc.redirects():
        if rd.get('door') or rd.get('twin_of'):
            continue
        b = node(dest_key(doc, rd.get('dest')))
        if b is None:
            continue
        a = node(('vanilla', _v(rd['mapID'])))
        edges.append({'a': a, 'b': b, 'kind': 'redirect', 'both': False,
                      'label': f"vanilla door screen {_v(rd['screen'])} ({_v(rd['x'])},"
                               f"{_v(rd['y'])}) re-pointed one-way -> {pl.label(rd.get('dest'))}"})
    # script warps (ops map_transition / talk move) of each room's scripts
    for r in doc.rooms:
        if r.get('placeholder'):
            continue
        a = ('room', r['id'])
        for _i, sid in sorted((r.get('scripts') or {}).items()):
            try:
                sc = doc.script(sid)
            except KeyError:
                continue
            targets = []
            for op in sc.get('ops') or []:
                if isinstance(op, list) and len(op) >= 3 and op[0] == 'op' and \
                        op[1] in ('map_transition', '0x0F', '0x0f'):
                    try:
                        w = _v(op[2])
                        # S143: a place's word carries its region in the high byte
                        # (PROJECT_COMPILER §2.49); a game room's high byte is a gate flag
                        targets.append(w if (w & 0xFF) >= 0x6B else w & 0xFF)
                    except Exception:
                        pass
            t = sc.get('talk') or {}
            for part in ('then', 'yes', 'no'):
                mv = (t.get(part) or {}).get('move')
                if mv:
                    k2 = dest_key(doc, mv.get('dest'))
                    if k2:
                        b = node(k2)
                        edges.append({'a': a, 'b': b, 'kind': 'warp', 'both': False,
                                      'label': f"a conversation ({part}) moves the player"})
            for mid in targets:
                b = node(dest_key(doc, f'{"room" if mid >= 0x6B else "vanilla"}:${mid:02X}'))
                if b:
                    edges.append({'a': a, 'b': b, 'kind': 'warp', 'both': False,
                                  'label': f"a script warps the player to {pl.mid_label(mid)}"})
    # the vanilla world
    if include_vanilla and renderer is not None:
        pairs = set()
        for mid, _name, screens in renderer.vanilla_rooms():
            for k in screens:
                for n in range(len(renderer.vanilla_steps(mid, k))):
                    try:
                        _np, exits = renderer.vanilla_markers(mid, k, n)
                    except Exception:
                        continue
                    for e in exits:
                        b = dest_key(doc, e['dest'])
                        if b and b != ('vanilla', mid) and (mid, b) not in pairs:
                            pairs.add((mid, b))
                            edges.append({'a': node(('vanilla', mid)), 'b': node(b),
                                          'kind': 'vanilla', 'both': False,
                                          'label': f"game exit {pl.vanilla_label(mid)} -> {pl.label(e['dest'])}"})
    return list(nodes.values()), edges


def layout(nodes, edges, width=1000.0, height=700.0, iterations=250, seed=98, fixed=None):
    """Deterministic spring layout (Fruchterman-Reingold): {key: (x, y)}.

    S142 (ARC CAP4a): vectorised with numpy (the pure-Python pair loop took
    4-6 s for 330 rooms on every show of the World tab); `fixed` {key: (x, y)}
    pins rooms where they already are (moved by hand or laid out before) — only
    the others move. Without numpy the S98 loop below runs (pins kept too)."""
    try:
        import numpy as np
    except ImportError:                                  # pragma: no cover
        np = None
    if np is not None:
        return _layout_np(np, nodes, edges, width, height, iterations, seed, fixed or {})
    return _layout_py(nodes, edges, width, height, iterations, seed, fixed or {})


def _layout_np(np, nodes, edges, width, height, iterations, seed, fixed):
    rnd = random.Random(seed)
    keys = [n['key'] for n in nodes]
    if not keys:
        return {}
    idx = {k: i for i, k in enumerate(keys)}
    pos = np.array([[rnd.uniform(0, width), rnd.uniform(0, height)] for _k in keys])
    pin = np.zeros(len(keys), dtype=bool)
    for k, xy in fixed.items():
        if k in idx:
            pos[idx[k]] = xy
            pin[idx[k]] = True
    if pin.all():
        return {k: (float(pos[i][0]), float(pos[i][1])) for i, k in enumerate(keys)}
    kk = math.sqrt(width * height / len(keys)) * 0.9
    t = width / 8.0
    ea = np.array([idx[e['a']] for e in edges
                   if e['a'] in idx and e['b'] in idx and e['a'] != e['b']], dtype=int)
    eb = np.array([idx[e['b']] for e in edges
                   if e['a'] in idx and e['b'] in idx and e['a'] != e['b']], dtype=int)
    free = ~pin
    k2 = kk * kk
    for _ in range(iterations):
        x, y = pos[:, 0], pos[:, 1]
        dx = x[:, None] - x[None, :]
        dy = y[:, None] - y[None, :]
        inv = dx * dx + dy * dy
        np.maximum(inv, 1e-4, out=inv)           # d >= 0.01, as the loop below
        np.divide(k2, inv, out=inv)              # repulsion (dx / d) * (k^2 / d)
        np.fill_diagonal(inv, 0.0)
        disp = np.stack(((dx * inv).sum(axis=1), (dy * inv).sum(axis=1)), axis=1)
        if len(ea):
            dl = pos[ea] - pos[eb]
            dd = np.hypot(dl[:, 0], dl[:, 1])
            dd[dd == 0] = 0.01
            fa = (dl / dd[:, None]) * (dd * dd / kk)[:, None]
            np.add.at(disp, ea, -fa)
            np.add.at(disp, eb, fa)
        dn = np.hypot(disp[:, 0], disp[:, 1])
        dn[dn == 0] = 0.01
        step = disp / dn[:, None] * np.minimum(dn, t)[:, None]
        pos[free] += step[free]
        pos[:, 0] = np.clip(pos[:, 0], 0.0, width)
        pos[:, 1] = np.clip(pos[:, 1], 0.0, height)
        for k, xy in fixed.items():                     # pins never move (nor clip)
            if k in idx:
                pos[idx[k]] = xy
        t = max(1.0, t * 0.97)
    return {k: (float(pos[i][0]), float(pos[i][1])) for i, k in enumerate(keys)}


def _layout_py(nodes, edges, width, height, iterations, seed, fixed):
    rnd = random.Random(seed)
    keys = [n['key'] for n in nodes]
    if not keys:
        return {}
    pos = {k: [rnd.uniform(0, width), rnd.uniform(0, height)] for k in keys}
    for k, xy in fixed.items():
        if k in pos:
            pos[k] = list(xy)
    area = width * height
    kk = math.sqrt(area / len(keys)) * 0.9
    t = width / 8.0
    adj = [(e['a'], e['b']) for e in edges if e['a'] in pos and e['b'] in pos and e['a'] != e['b']]
    for _ in range(iterations):
        disp = {k: [0.0, 0.0] for k in keys}
        for i, a in enumerate(keys):
            for b in keys[i + 1:]:
                dx = pos[a][0] - pos[b][0]
                dy = pos[a][1] - pos[b][1]
                d = math.hypot(dx, dy) or 0.01
                f = kk * kk / d
                disp[a][0] += dx / d * f
                disp[a][1] += dy / d * f
                disp[b][0] -= dx / d * f
                disp[b][1] -= dy / d * f
        for a, b in adj:
            dx = pos[a][0] - pos[b][0]
            dy = pos[a][1] - pos[b][1]
            d = math.hypot(dx, dy) or 0.01
            f = d * d / kk
            disp[a][0] -= dx / d * f
            disp[a][1] -= dy / d * f
            disp[b][0] += dx / d * f
            disp[b][1] += dy / d * f
        for k in keys:
            if k in fixed:
                continue
            dx, dy = disp[k]
            d = math.hypot(dx, dy) or 0.01
            pos[k][0] = min(width, max(0.0, pos[k][0] + dx / d * min(d, t)))
            pos[k][1] = min(height, max(0.0, pos[k][1] + dy / d * min(d, t)))
        t = max(1.0, t * 0.97)
    return {k: tuple(v) for k, v in pos.items()}
