"""cutscene_doc.py — editing the project's own cutscenes (S119, ROADMAP P3.8 part B).

Headless helpers over a Document (no Qt; the Cutscenes tab pushes each call as
one SnapshotCommand). The data lives in `custom.rooms[].cutscenes[]` and in the
room's NPC entries (`actor` names, cast members) — PROJECT_COMPILER §2.33.

Actors: an NPC is named once (`actor` on its entry); the name is put on the
same NPC in every room state of the screen (same sprite + cell — clones repeat
an NPC entry per state). A CAST member is a hidden NPC (`cast: true`) placed in
EVERY state of the screen at the same NPC number (states with fewer NPCs are
padded with hidden pads, like the helper exit's slot — the game moves NPCs by
number, so a name must mean the same number in every state).
"""

import copy
import re

from . import cutscene_build as CB
from . import formats as F

MAX_NPCS = 8                      # the engine's NPC slots per screen (S91)


def _slug(s):
    s = re.sub(r'[^A-Za-z0-9_]+', '_', str(s).strip()).strip('_').lower()
    return s or 'scene'


def scenes(doc):
    """[(room, scene)] over the project's rooms (placeholders skipped)."""
    out = []
    for r in doc.rooms:
        if r.get('placeholder'):
            continue
        for sc in r.get('cutscenes') or []:
            out.append((r, sc))
    return out


def find(doc, scene_id):
    for r, sc in scenes(doc):
        if sc.get('id') == scene_id:
            return r, sc
    raise KeyError(scene_id)


def unique_id(doc, base):
    have = {sc.get('id') for _r, sc in scenes(doc)}
    b = _slug(base)
    i, sid = 1, b
    while sid in have:
        i += 1
        sid = f'{b}_{i}'
    return sid


def new_cutscene(doc, room_id, name, screen=0, on='entry', actor=None):
    """actor (talk): an NPC's scene name, or a token of an NPC without one
    (`npc_token` — it is named now)."""
    r = doc.room(room_id)
    sid = unique_id(doc, name)
    sc = CB.new_scene(r, sid, screen, on)
    sc['name'] = name
    if on == 'talk' and actor:
        sc['trigger']['actor'] = resolve_tokens(doc, room_id, screen, actor)
    if on == 'entry':
        st = default_player_start(doc, r, screen)
        if st:
            sc['player_start'] = st
    r.setdefault('cutscenes', []).append(sc)
    doc.touch()
    return sid


def set_scene(doc, scene_id, scene):
    r, old = find(doc, scene_id)
    lst = r['cutscenes']
    lst[lst.index(old)] = copy.deepcopy(scene)
    doc.touch()


def delete_cutscene(doc, scene_id):
    r, old = find(doc, scene_id)
    r['cutscenes'].remove(old)
    if not r['cutscenes']:
        r.pop('cutscenes')
    doc.touch()


def duplicate(doc, scene_id):
    r, old = find(doc, scene_id)
    sc = copy.deepcopy(old)
    sc['id'] = unique_id(doc, old['id'] + '_copy')
    sc['name'] = (old.get('name') or old['id']) + ' (copy)'
    tr = sc.get('trigger') or {}
    tr.pop('once', None)
    r['cutscenes'].append(sc)
    doc.touch()
    return sc['id']


# ------------------------------------------------------------------ actors

def screen_states(room, screen):
    scr = room['screens'][str(screen)]
    return scr['states'] if scr.get('states') else [scr]


def npc_rows(room, screen, state=0):
    """[(n, entry)] the NPCs of one state in game order (spots skipped)."""
    sts = screen_states(room, screen)
    st = sts[min(state, len(sts) - 1)]
    out, n = [], 0
    for e in st.get('npcs') or []:
        if CB.is_npc_entry(e):
            n += 1
            out.append((n, e))
    return out


def _sig(e):
    return (CB.entry_sprite(e), CB.entry_cell(e))


def name_actor(doc, room_id, screen, state, n, name):
    """Name NPC n of a state; the same NPC (sprite + cell) in the other states of
    the screen gets the name too. name '' removes it. Returns how many entries."""
    r = doc.room(room_id)
    name = str(name or '').strip()
    if name.lower() == CB.PLAYER:
        raise ValueError('“player” is the player')
    rows = dict(npc_rows(r, screen, state))
    if n not in rows:
        raise KeyError(f'no NPC {n} in state {state}')
    target = rows[n]
    if name:
        for k, st in enumerate(screen_states(r, screen)):
            for e in st.get('npcs') or []:
                if CB.is_npc_entry(e) and e.get('actor') == name and _sig(e) != _sig(target):
                    raise ValueError(f'“{name}” is already another NPC of this screen')
    sig = _sig(target)
    count = 0
    for st in screen_states(r, screen):
        for e in st.get('npcs') or []:
            if CB.is_npc_entry(e) and (e is target or _sig(e) == sig):
                if name:
                    old = e.get('actor')
                    e['actor'] = name
                    if old and old != name:
                        _rename_refs(r, old, name)
                else:
                    e.pop('actor', None)
                count += 1
    doc.touch()
    return count


def _rename_refs(room, old, new):
    for sc in room.get('cutscenes') or []:
        tr = sc.get('trigger') or {}
        if tr.get('actor') == old:
            tr['actor'] = new
        for _p, st in CB.walk_steps(sc.get('steps')):
            k = CB.step_kind(st)
            v = st.get(k) if k else None
            if isinstance(v, dict):
                for key in ('actor', 'toward'):
                    if v.get(key) == old:
                        v[key] = new


def unnamed_npcs(room, screen):
    """[(state, n, entry)] the NPCs of a screen that have no scene name yet (one
    row per NPC: the same sprite + cell in several states counts once)."""
    out, seen = [], set()
    for k in range(len(screen_states(room, screen))):
        for n, e in npc_rows(room, screen, k):
            if e.get('actor') or CB.entry_sprite(e) == 0xFF:      # pads are not people
                continue
            if _sig(e) in seen:
                continue
            seen.add(_sig(e))
            out.append((k, n, e))
    return out


def npc_token(state, n):
    """What a list item holds for an NPC that gets its name when it is picked."""
    return f'#{int(state)}:{int(n)}'


def is_token(v):
    return isinstance(v, str) and v.startswith('#') and ':' in v


def _default_name(doc, room, screen, e, n):
    sid = e.get('script')
    for sc in doc.custom.get('scripts') or []:
        if isinstance(sc, dict) and sc.get('id') == sid and sc.get('shop'):
            base = 'Shopkeeper'
            break
    else:
        base = f'NPC {n}'
    have = {nm for nm, _k, _e in actors(room, screen)}
    name, i = base, 1
    while name in have:
        i += 1
        name = f'{base} {i}'
    return name


def ensure_named(doc, room_id, screen, token):
    """The scene name of the NPC a token points at — named now (a default name:
    'Shopkeeper' / 'NPC n', renamed any time) when it has none."""
    state, n = (int(x) for x in token[1:].split(':', 1))
    r = doc.room(room_id)
    rows = dict(npc_rows(r, screen, state))
    if n not in rows:
        raise KeyError(f'no NPC {n} in state {state}')
    if rows[n].get('actor'):
        return rows[n]['actor']
    name = _default_name(doc, r, screen, rows[n], n)
    name_actor(doc, room_id, screen, state, n, name)
    return name


def resolve_tokens(doc, room_id, screen, value):
    """`value` (a scene, a step, a trigger …) with every NPC token replaced by the
    NPC's name (naming it when needed)."""
    if is_token(value):
        return ensure_named(doc, room_id, screen, value)
    if isinstance(value, dict):
        return {k: resolve_tokens(doc, room_id, screen, v) for k, v in value.items()}
    if isinstance(value, list):
        return [resolve_tokens(doc, room_id, screen, v) for v in value]
    return value


def has_tokens(value):
    if is_token(value):
        return True
    if isinstance(value, dict):
        return any(has_tokens(v) for v in value.values())
    if isinstance(value, list):
        return any(has_tokens(v) for v in value)
    return False


def add_cast(doc, room_id, screen, name, sprite, x, y, facing='down'):
    """A hidden NPC that a scene shows, at the SAME NPC number in every state of
    the screen (shorter states padded with hidden pads). Returns its number."""
    r = doc.room(room_id)
    name = str(name).strip()
    if not name or name.lower() == CB.PLAYER:
        raise ValueError('give the cast member a name')
    sts = screen_states(r, screen)
    for st in sts:
        if any(e.get('actor') == name for e in st.get('npcs') or []):
            raise ValueError(f'“{name}” is already on this screen')
    counts = [sum(1 for e in st.get('npcs') or [] if CB.is_npc_entry(e)) for st in sts]
    n = max(counts) + 1
    if n > MAX_NPCS:
        raise ValueError(f'this screen already has {n - 1} NPCs in a state — the game has '
                         f'{MAX_NPCS} NPC slots')
    for st, c in zip(sts, counts):
        lst = st.setdefault('npcs', [])
        for _ in range(n - 1 - c):
            lst.append({'kind': 'npc', 'sprite': '0xFF', 'x': 0, 'y': 0, 'hidden': True,
                        'script': 'none', 'comment': 'hidden pad (keeps the cast at one NPC number)'})
        lst.append({'kind': 'npc', 'sprite': f'0x{F.val(sprite) & 0xFF:02X}', 'x': int(x),
                    'y': int(y), 'facing': facing, 'hidden': True, 'cast': True,
                    'script': 'none', 'actor': name})
    doc.touch()
    return n


def move_cast(doc, room_id, screen, name, x, y, facing=None, sprite=None):
    r = doc.room(room_id)
    hit = 0
    for st in screen_states(r, screen):
        for e in st.get('npcs') or []:
            if e.get('actor') == name and e.get('kind') == 'npc':
                e['x'], e['y'] = int(x), int(y)
                if facing:
                    e['facing'] = facing
                if sprite is not None:
                    e['sprite'] = f'0x{F.val(sprite) & 0xFF:02X}'
                hit += 1
    if not hit:
        raise KeyError(name)
    doc.touch()


def remove_cast(doc, room_id, screen, name):
    """Remove a cast member (and the pads that only kept it in place, from the end)."""
    r = doc.room(room_id)
    for st in screen_states(r, screen):
        lst = st.get('npcs') or []
        lst[:] = [e for e in lst if not (e.get('actor') == name and e.get('cast'))]
        while lst and lst[-1].get('comment', '').startswith('hidden pad (keeps the cast'):
            lst.pop()
    doc.touch()


def actors(room, screen):
    """[(name, n, entry)] of a screen (the player first, n = 0)."""
    cast = CB.Cast(room, screen)
    out = [(CB.PLAYER, 0, None)]
    for nm in cast.names():
        n, _p = cast.slot(nm)
        out.append((nm, n, cast.entry(nm)))
    return out


# ------------------------------------------------------------------ helpers

def ensure_flag(doc, name):
    name = _slug(name)
    if not any(f.get('name') == name for f in doc.flags()):
        doc.add_flag(name)              # S124: a fixed number at once
    return name


def default_player_start(doc, room, screen):
    """Where the player arrives on this screen in the project: a door / exit of
    any room (or a redirect of a game door) leading here — the first one found;
    None when nothing leads to this screen."""
    mid = F.val(room.get('mapID'))
    col, row = int(screen) % 4, int(screen) // 4
    hits = []
    for r in doc.rooms:
        for k, scr in (r.get('screens') or {}).items():
            for st in (scr.get('states') or [scr]):
                for ex in st.get('exits') or []:
                    d = str(ex.get('dest', ''))
                    if ':' not in d:
                        continue
                    try:
                        dm = F.val(d.split(':', 1)[1])
                    except (TypeError, ValueError):
                        continue
                    if dm == mid and d.startswith('room'):
                        hits.append((ex.get('spawn_x'), ex.get('spawn_y'), ex.get('screen_byte')))
    for rd in doc.custom.get('entrance_redirects') or []:
        d = str(rd.get('dest', ''))
        if ':' in d and d.startswith('room') and F.val(d.split(':', 1)[1]) == mid:
            hits.append((rd.get('spawn_x'), rd.get('spawn_y'), rd.get('screen_byte')))
    for sx, sy, sb in hits:
        try:
            sb = F.val(sb) & 0x0F if sb is not None else 0
        except (TypeError, ValueError):
            sb = 0
        if sb == int(screen) and sx is not None and sy is not None:
            return {'x': int(sx), 'y': int(sy), 'face': 'down'}
    return None


def problems(doc, room, scene):
    """(errors, warnings) of one scene from the editor's model (no build)."""
    lw = CB.analyse(room, scene, custom=doc.custom,
                    flag_names=[f.get('name') for f in doc.flags()],
                    enemies=[e.get('id') for e in (doc.data.get('progression') or {})
                             .get('enemies') or []])
    return lw.errors, lw.warnings, lw
