"""npc_names.py — YOUR names for the NPCs (S124 r3, ROADMAP P3.14a).

User S124 r3: "It should also allow naming all NPCs (e.g. King at Stage X or
something - I can do it manually) and carry that through, both vanilla and in
romhack. Otherwise this is insanely hard to follow."

An NPC = NPC number n (1-based, the game's order of a state's list, spots not
counted — BANK04_SCRIPT_ENGINE "Actors") of one screen STATE of a room.

* The project's rooms: the name is the NPC entry's `actor` (the cutscene name,
  PROJECT_COMPILER §2.33) — set through cutscene_doc.name_actor, which names the
  same NPC (sprite + cell) in the screen's other states too and renames the
  cutscenes' references.
* The original game's rooms (read-only data): `custom._editor.npc_names`
  {"MM:screen:state:n": name} — editor data, never compiled. Naming one names
  the same NPC (sprite + cell) in the screen's other states too, like actors.

Every place that shows an NPC asks `name_of` first (the Progression & Flags tab,
the Rooms tab canvas, the Cutscenes tab storyboards): a user name wins over a
name the game's own lines give (S118g: other names come only from the game).
"""

KEY = 'npc_names'


def vkey(mid, screen, state, n):
    return f'{int(mid):02X}:{int(screen)}:{int(state)}:{int(n)}'


def vanilla_names(custom):
    return ((custom or {}).get('_editor') or {}).get(KEY) or {}


def _rooms():
    if not hasattr(_rooms, 'v'):
        from .cutscenes import Rooms
        _rooms.v = Rooms()
    return _rooms.v


def vanilla_rows(mid, screen, state):
    """[(n, sprite, x, y, script)] the NPCs of a game room's screen state."""
    out = []
    for n, e in enumerate(_rooms().npcs(int(mid), int(screen), int(state)), 1):
        out.append((n, e['sprite'], e['x'], e['y'], e['script']))
    return out


def vanilla_states(mid, screen):
    try:
        return len(_rooms().steps(int(mid), int(screen)))
    except Exception:                                            # noqa: BLE001
        return 1


def project_rows(room, screen, state):
    """[(n, entry)] the NPCs of a project room's screen state."""
    from . import cutscene_doc as CD
    try:
        return CD.npc_rows(room, screen, state)
    except Exception:                                            # noqa: BLE001
        return []


def name_of(custom, mid=None, screen=0, state=0, n=0, room=None):
    """The user's name of NPC n of (a project room `room` | game room `mid`)."""
    if room is not None:
        for k, e in project_rows(room, screen, state):
            if k == n:
                return e.get('actor') or None
        return None
    return vanilla_names(custom).get(vkey(mid, screen, state, n)) or None


def names_in(custom, mid=None, screen=0, state=0, room=None):
    """{n: name} of one screen state."""
    if room is not None:
        return {k: e['actor'] for k, e in project_rows(room, screen, state) if e.get('actor')}
    pre = f'{int(mid):02X}:{int(screen)}:{int(state)}:'
    return {int(k.rsplit(':', 1)[1]): v for k, v in vanilla_names(custom).items()
            if k.startswith(pre) and v}


def set_vanilla_name(custom, mid, screen, state, n, name):
    """Name NPC n of a game room's state (and the same sprite + cell in the screen's
    other states); '' removes. Returns how many states were named."""
    name = str(name or '').strip()
    rows = {k: (spr, x, y) for k, spr, x, y, _s in vanilla_rows(mid, screen, state)}
    if n not in rows:
        raise KeyError(f'no NPC {n} in that state')
    sig = rows[n]
    names = custom.setdefault('_editor', {}).setdefault(KEY, {})
    count = 0
    for st in range(vanilla_states(mid, screen)):
        for k, spr, x, y, _s in vanilla_rows(mid, screen, st):
            if (spr, x, y) == sig or (st == state and k == n):
                key = vkey(mid, screen, st, k)
                if name:
                    names[key] = name
                else:
                    names.pop(key, None)
                count += 1
    if not names:
        custom['_editor'].pop(KEY, None)
    return count
