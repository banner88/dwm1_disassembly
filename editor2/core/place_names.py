"""place_names.py — every place by NAME (S143, ROADMAP ARC CAP4b).

The editor shows a place (one of the project's rooms, a room of the game, the
hub, a gate) by its NAME only — never a map id or a region (user S142: "Hide",
vanilla rooms too). This module is the one place that turns any stored
reference into words, and the one place that lists the places a picker offers:

  * a project room   -> its name (unique among the project's rooms since S143:
                        Document.unique_room_name; older projects are renamed on
                        open, Document._migrate_unique_names)
  * a game room      -> `vanilla_name(mid)`: dwm/map_names.py, except the ids
                        whose table name is wrong or missing (VANILLA_OVERRIDES —
                        the eight unused ids that hold the CASTLE's room data,
                        bank $0B RoomSub_Castle_cont, and $5F = the gate item
                        shop's data); a game room is suffixed " (game room)"
                        when a project room has the same name
  * 'hub'            -> "home (the hub)",  'gate:N' -> the gate's name

The stored references do not change (`room:$XX` = the room's permanent number,
user S142 "Whatever you think is best"); only what the editor SHOWS does.

View > Show technical ids (user S143: "view show in case I want them") sets
SHOW_IDS; every label then carries the id in brackets — "[$6B]", "[region 1 $6B]",
"[game $0B]" — for debugging in SameBoy. Off by default.

Pure data, no Qt (the GUI picker is app/place_picker.py).
"""

import json
import os
from collections import namedtuple

from editor2.core.formats import val as _fval

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

SHOW_IDS = False            # View > Show technical ids (the app sets it from QSettings)

# The vanilla room table's names that are wrong or missing (S143, measured in the
# disassembly — bank $0B `MapScreenPtrTable` comments, RoomSub_Castle_cont):
# $0B $0E $11 $14 $15 $20 $21 $22 point at the CASTLE's room data (dwm/map_names.py
# calls five of them "Castle: Chest Room (variant)" — the exits that seem to lead to
# them are gate entrances, whose byte is a gate number); $5F points at the gate item
# shop's data ($50). User S143: keep them listed "so I know wtf it is".
_CASTLE_COPIES = (0x0B, 0x0E, 0x11, 0x14, 0x15, 0x20, 0x21, 0x22)
VANILLA_OVERRIDES = {m: f'Castle (unused copy {i + 1})' for i, m in enumerate(_CASTLE_COPIES)}
VANILLA_OVERRIDES[0x5F] = 'Gate Floor: Item Shop (unused copy)'

# Groups of the game's rooms in a place picker (in this order).
VANILLA_GROUPS = (
    ('Castle & GreatTree', set(range(0x00, 0x06)) | set(range(0x0A, 0x23)) | {0x2F}),
    ('Arena & Starry Shrine', {0x06, 0x07, 0x08, 0x09, 0x5D, 0x5E}),
    ("Travelers' gate rooms", set(range(0x23, 0x2F))),
    ('Boss rooms', set(range(0x30, 0x50)) - {0x40, 0x42}),
    ('Gate floors & mazes', set(range(0x50, 0x5D)) | {0x5F, 0x40, 0x42}
     | set(range(0x60, 0x6B))),
)
NO_AREA = 'No area'
SPECIAL = 'Special'
GAME = 'Game rooms'

PlaceEntry = namedtuple('PlaceEntry', 'label value group kind search')
"""label = what the picker shows; value = what the caller stores; group = the
folder it is listed under; kind = 'room' / 'vanilla' / 'special' / 'theme';
search = the text the filter matches (label + area)."""


def _mid(x):
    try:
        v = _fval(x)
    except (ValueError, TypeError):
        return None
    return v if isinstance(v, int) else None


# --------------------------------------------------------------- technical ids
def tech_id(mid, vanilla=False):
    """The id as a developer reads it: '$6B', 'region 1 $6B', 'game $0B'."""
    mid = int(mid)
    if vanilla or mid < 0x6B:
        return f'game ${mid & 0xFF:02X}'
    reg = mid >> 8
    return (f'region {reg} ' if reg else '') + f'${mid & 0xFF:02X}'


def with_id(name, mid, vanilla=False):
    """`name`, plus "  [id]" while View > Show technical ids is on."""
    if SHOW_IDS and mid is not None:
        return f'{name}  [{tech_id(mid, vanilla)}]'
    return name


# ---------------------------------------------------------------- game rooms
_MT_NAMES = None


def _map_table_names():
    global _MT_NAMES
    if _MT_NAMES is None:
        _MT_NAMES = {}
        try:
            for e in json.load(open(os.path.join(REPO, 'extracted', 'map_table.json'))):
                if isinstance(e, dict) and e.get('map_type') is not None and e.get('name'):
                    _MT_NAMES[e['map_type']] = e['name']
        except (OSError, ValueError):
            pass
    return _MT_NAMES


def vanilla_name(mid):
    """The game room's name (no id). Never a hex fallback: an id with no name at
    all reads "Unnamed game room" (+ the id while Show technical ids is on)."""
    mid = int(mid)
    if mid in VANILLA_OVERRIDES:
        return VANILLA_OVERRIDES[mid]
    from dwm.map_names import MAP_NAMES
    return MAP_NAMES.get(mid) or _map_table_names().get(mid) or 'Unnamed game room'


def vanilla_group(mid):
    for title, ids in VANILLA_GROUPS:
        if mid in ids:
            return title
    return 'Other game rooms'


# ------------------------------------------------------------------ catalog
class Places:
    """Names of one project's places, built from its rooms (cheap: one pass).
    Build a fresh one per refresh — it does not watch the document."""

    def __init__(self, rooms, gates_custom=None):
        self.rooms = [r for r in (rooms or []) if not r.get('placeholder')]
        self.by_id = {r.get('id'): r for r in self.rooms}
        self.by_mid = {}
        for r in self.rooms:
            m = _mid(r.get('mapID'))
            if m is not None:
                self.by_mid[m] = r
        self.custom_names = {room_name(r).casefold() for r in self.rooms}
        self.gates_custom = gates_custom

    @classmethod
    def of(cls, doc_or_data):
        """From a Document, a project dict, or a list of rooms."""
        if isinstance(doc_or_data, list):
            return cls(doc_or_data)
        custom = getattr(doc_or_data, 'custom', None)
        if custom is None and isinstance(doc_or_data, dict):
            custom = doc_or_data.get('custom', doc_or_data)
        custom = custom or {}
        return cls(custom.get('rooms') or [], custom)

    # ---- single labels
    def room_label(self, room):
        return with_id(room_name(room), _mid(room.get('mapID')))

    def vanilla_label(self, mid, mixed=True, ids=True):
        """A game room's label; ' (game room)' added when `mixed` and a project
        room has the same name (a copy keeps the game's name); `ids=False` never
        adds the technical id."""
        n = vanilla_name(mid)
        if mixed and n.casefold() in self.custom_names:
            n += ' (game room)'
        return with_id(n, mid, vanilla=True) if ids else n

    def mid_label(self, mid):
        """A map id / project mapID (int or '0x6B' / '$16B')."""
        m = _mid(mid)
        if m is None:
            return str(mid)
        if m < 0x6B:
            return self.vanilla_label(m)
        r = self.by_mid.get(m)
        if r is not None:
            return self.room_label(r)
        return with_id('a deleted room', m)

    def room_id_label(self, rid):
        r = self.by_id.get(rid)
        if r is not None:
            return self.room_label(r)
        if rid in ('castle', 'vanilla:$00'):
            return self.vanilla_label(0x00)
        return f'a missing room ({rid})' if rid else 'no room'

    def gate_label(self, gid):
        try:
            from editor2.core.gates import gate_name
            return gate_name(self.gates_custom or {}, int(gid))
        except Exception:                                # noqa: BLE001
            return f'gate {gid}'

    def label(self, ref):
        """Any stored place reference -> words: 'room:$6B' / 'room:$16B',
        'vanilla:$01', 'hub', 'gate:N', 'castle', a room id, a map id (int, '0x6B',
        '$6B'), ('room', id) / ('vanilla', mid) tuples, None."""
        if ref is None or ref == '':
            return 'nowhere'
        if isinstance(ref, tuple) and len(ref) == 2:
            k, v = ref
            if k == 'room':
                return self.room_id_label(v)
            if k == 'vanilla':
                return self.vanilla_label(int(v))
            if k == 'theme':
                return f'gate theme {v}'
        if isinstance(ref, int):
            return self.mid_label(ref)
        s = str(ref)
        if s == 'hub':
            return 'home (the hub)'
        if s == 'castle':
            return self.vanilla_label(0x00)
        if s.startswith('gate:'):
            return self.gate_label(s.split(':', 1)[1])
        if s.startswith('room:'):
            m = _mid(s[5:])
            if m is None:
                return self.room_id_label(s[5:])
            r = self.by_mid.get(m)
            return self.room_label(r) if r is not None else with_id('a deleted room', m)
        if s.startswith('vanilla:'):
            m = _mid(s[8:])
            return self.vanilla_label(m) if m is not None else s
        if s in self.by_id:
            return self.room_label(self.by_id[s])
        m = _mid(s)
        if m is not None and (s.startswith('$') or s.lower().startswith('0x')):
            return self.mid_label(m)
        return s

    # ---- picker entries
    def room_entries(self, value='id', want=None, mark=None):
        """The project's rooms grouped by area (area order: as in the Rooms list —
        Document.areas() — 'No area' last). value: 'id' | 'dest' ('room:$XX') | 'mid'."""
        out = []
        for r in self.rooms:
            if want is not None and not want(r):
                continue
            m = _mid(r.get('mapID'))
            v = {'id': r.get('id'), 'mid': m,
                 'dest': f'room:${m:02X}' if m is not None else None}.get(value, r.get('id'))
            lab = self.room_label(r) + (mark(r) if mark else '')
            area = room_area(r)
            out.append(PlaceEntry(lab, v, area or NO_AREA, 'room',
                                  f'{lab} {area}'.casefold()))
        order = {}                     # the Rooms list's order: stored areas, then first use
        stored = ((self.gates_custom or {}).get('_editor') or {}).get('areas') or []
        for a in stored:
            order.setdefault(str(a).strip(), len(order))
        for e in out:
            order.setdefault(e.group, len(order) if e.group != NO_AREA else 10 ** 6)
        out.sort(key=lambda e: order[e.group])
        return out

    def vanilla_entries(self, vanilla_rooms=None, value='mid', want=None):
        """The game's rooms in their groups. `vanilla_rooms` = the renderer's
        [(mid, name, screens)] (rooms with room data); else every named id.
        value: 'mid' (int) | 'dest' ('vanilla:$XX')."""
        if vanilla_rooms is None:
            from dwm.map_names import MAP_NAMES
            mids = sorted(set(MAP_NAMES) | set(VANILLA_OVERRIDES))
        else:
            mids = [m for m, _n, _s in vanilla_rooms]
        out = []
        for m in mids:
            if want is not None and not want(m):
                continue
            lab = self.vanilla_label(m)
            v = f'vanilla:${m:02X}' if value == 'dest' else m
            g = vanilla_group(m)
            out.append(PlaceEntry(lab, v, g, 'vanilla', f'{lab} {g}'.casefold()))
        rank = {t: i for i, (t, _ids) in enumerate(VANILLA_GROUPS)}
        out.sort(key=lambda e: (rank.get(e.group, 99), _mid_of_entry(e)))
        return out

    @staticmethod
    def special_entries(hub=True, castle=True):
        out = []
        if hub:
            out.append(PlaceEntry('Home — the hub (World tab)', 'hub', SPECIAL, 'special',
                                  'home hub'))
        if castle:
            out.append(PlaceEntry(with_id('Castle throne room', 0x00, True), 'vanilla:$00',
                                  SPECIAL, 'special', 'castle throne room'))
        return out


def _mid_of_entry(e):
    v = e.value
    if isinstance(v, int):
        return v
    m = _mid(str(v).split(':', 1)[-1])
    return m if m is not None else 0


# ------------------------------------------------------------- room helpers
def room_name(room):
    return (room.get('name') or room.get('id') or '?').strip() or '?'


def room_ref(room):
    """A project room in a message: its name ("Cave 2"); with Show technical ids
    (and in the command-line compiler) also its id and map id — "Cave 2 [cave_2,
    region 1 $6B]" — so the line can be found in project.json."""
    nm = room_name(room)
    if not SHOW_IDS:
        return f'"{nm}"'
    m = _mid(room.get('mapID'))
    bits = [str(room.get('id'))] + ([tech_id(m)] if m is not None else [])
    return f'"{nm}" [{", ".join(bits)}]'


def mid_ref(rooms, mid):
    """A map id / project mapID in a message (a room of `rooms`, or a game room)."""
    m = _mid(mid)
    if m is None:
        return str(mid)
    if m < 0x6B:
        return 'the game room ' + with_id(vanilla_name(m), m, True)
    for r in rooms or []:
        if not r.get('placeholder') and _mid(r.get('mapID')) == m:
            return 'room ' + room_ref(r)
    return with_id('a room this project does not have', m)


def strip_ids(text):
    """Text taken from extracted data that names game rooms with their ids
    ("Teto (Arena Lobby, map $06 scripts 10 / 11)") as the editor shows it: the
    ids dropped while Show technical ids is off ("Teto (Arena Lobby, scripts 10 / 11)")."""
    import re
    if SHOW_IDS or not text:
        return text
    t = re.sub(r'\bmap \$[0-9A-Fa-f]{2,3}\b\s*', '', str(text))
    return re.sub(r'\s*\(\s*\)', '', t).strip()


def room_area(room):
    return (room.get('area') or '').strip()


def next_free_name(base, taken):
    """'Cave' -> 'Cave' if free, else 'Cave 2', 'Cave 3'… (a trailing number on
    `base` is counted on from). `taken` = a set of casefolded names."""
    base = (base or 'Room').strip() or 'Room'
    if base.casefold() not in taken:
        return base
    stem, n = base, 2
    head, _, tail = base.rpartition(' ')
    if head and tail.isdigit():
        stem, n = head, int(tail) + 1
    while f'{stem} {n}'.casefold() in taken:
        n += 1
    return f'{stem} {n}'
