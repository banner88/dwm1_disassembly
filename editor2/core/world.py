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
    nodes, edges = {}, []

    def node(key):
        if key is None:
            return None
        if key not in nodes:
            if key[0] == 'room':
                r = doc.room(key[1])
                nodes[key] = {'key': key, 'mapID': _v(r['mapID']), 'label': doc.room_name(r),
                              'custom': True}
            else:
                try:
                    name = renderer.vanilla_name(key[1]) if renderer else ''
                except Exception:
                    name = ''
                nodes[key] = {'key': key, 'mapID': key[1], 'label': name or f'${key[1]:02X}',
                              'custom': False}
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
                    b = node(dest_key(doc, e.get('dest')))
                    sig = (k, _v(e['x']), _v(e['y']), b)
                    if b is None or sig in got:
                        continue
                    got.add(sig)
                    edges.append({'a': a, 'b': b, 'kind': 'exit', 'both': False,
                                  'label': f"one-way exit: screen {k} ({_v(e['x'])},{_v(e['y'])})"
                                           f" -> {e.get('dest')}"})
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
                               f"{_v(rd['y'])}) re-pointed one-way -> {rd.get('dest')}"})
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
                        targets.append(_v(op[2]) & 0xFF)
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
                                      'label': f"script {sid} ({part}) moves the player"})
            for mid in targets:
                b = node(dest_key(doc, f'{"room" if mid >= 0x6B else "vanilla"}:${mid:02X}'))
                if b:
                    edges.append({'a': a, 'b': b, 'kind': 'warp', 'both': False,
                                  'label': f"script {sid} warps (map_transition ${mid:02X})"})
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
                                          'label': f"vanilla exit ${mid:02X} -> {e['dest']}"})
    return list(nodes.values()), edges


def layout(nodes, edges, width=1000.0, height=700.0, iterations=250, seed=98):
    """Deterministic spring layout (Fruchterman-Reingold): {key: (x, y)}."""
    rnd = random.Random(seed)
    keys = [n['key'] for n in nodes]
    if not keys:
        return {}
    pos = {k: [rnd.uniform(0, width), rnd.uniform(0, height)] for k in keys}
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
            dx, dy = disp[k]
            d = math.hypot(dx, dy) or 0.01
            pos[k][0] = min(width, max(0.0, pos[k][0] + dx / d * min(d, t)))
            pos[k][1] = min(height, max(0.0, pos[k][1] + dy / d * min(d, t)))
        t = max(1.0, t * 0.97)
    return {k: tuple(v) for k, v in pos.items()}
