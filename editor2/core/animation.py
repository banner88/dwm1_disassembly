"""Room tile animation for the editor (S99, ROADMAP P3.3e).

Source of truth: extracted/room_animations.json (tools/census_room_animation.py,
PyBoy-measured; owning prose ROOM_DATA_FORMAT "Animated tiles"). One bank-$01
handler per map ID animates fixed tile SLOTS of whatever sheet is loaded:
ROLL (1 px sideways in place), the GreatTree SWAY (16 tiles, groups of 4
rolling in alternating directions) or SWAP (a shown tile trades graphics with
its hidden second frame elsewhere in the sheet). A custom room runs the
handler of its `animation` source (formats.anim_source): 'none', 'source'
(its source_mapID) or a borrowed vanilla map ID.

Pure data + bytes; no Qt. The canvas preview replays `schedule` exactly as
measured (counter 0..1023, one entry per field frame the handler acts).
"""
import json
import os

from . import formats as F

_REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
_CENSUS = None
CYCLE = 1024                      # the census schedule's counter cycle
FPS = 59.73                       # field frames per second (MainFieldLoop)


def census(repo=None):
    global _CENSUS
    if _CENSUS is None:
        path = os.path.join(repo or _REPO, 'extracted', 'room_animations.json')
        try:
            _CENSUS = json.load(open(path))
        except Exception:
            _CENSUS = {'handlers': {}, 'maps': {}}
    return _CENSUS


def map_entry(mid):
    if mid is None:
        return {}
    return census()['maps'].get('0x%02X' % mid) or {}


def handler(mid):
    e = map_entry(mid)
    return census()['handlers'].get(e.get('handler', ''), {})


def slots(mid):
    """Tile slots map `mid`'s handler animates (any sheet)."""
    if mid is None:
        return set()
    return set(handler(mid).get('slots') or [])


def shown_slots(mid):
    """Slots the vanilla room actually draws (the rest are hidden frames)."""
    return set(map_entry(mid).get('shown') or [])


def room_anim_map(room):
    """The map ID whose handler runs for a custom room, or None (no
    animation / invalid value). Absent = legacy Castle ($00)."""
    try:
        v, _kind, _why = F.anim_source(room)
    except ValueError:
        return None
    return None if v == F.ANIM_NONE else v


def room_slots(room):
    return slots(room_anim_map(room))


def describe_effects(mid):
    """Short human text for the handler of `mid` ('' when none)."""
    h = handler(mid)
    out = []
    for e in h.get('effects') or []:
        sl = rng(e['slots'])
        if e['kind'] == 'roll' and len(e['slots']) == 16:
            out.append(f'sways tiles {sl}')
        elif e['kind'] == 'roll':
            out.append(f'rolls tiles {sl} sideways')
        elif e['kind'] == 'swap':
            out.append(f"swaps tiles {sl} with hidden frames {rng(e['partners'])}"
                       f" every {e['period_frames']} frames")
    return '; '.join(out)


def rng(sl):
    sl = sorted(sl)
    out, i = [], 0
    while i < len(sl):
        j = i
        while j + 1 < len(sl) and sl[j + 1] == sl[j] + 1:
            j += 1
        out.append(str(sl[i]) if i == j else f'{sl[i]}-{sl[j]}')
        i = j + 1
    return ','.join(out)


def sources(names=None):
    """[(mid, label)] for the 'borrow' list: every vanilla map whose handler
    animates something visible in its own room (inert / cutscene handlers
    excluded), grouped so shared handlers appear once per map."""
    out = []
    for k, m in sorted(census()['maps'].items()):
        mid = int(k, 16)
        if mid >= 0x6B or not m.get('slots') or mid in F.ANIM_EXCLUDED:
            continue
        if m.get('inert_in_vanilla'):
            continue
        name = (names or {}).get(mid) or m.get('name') or f'map ${mid:02X}'
        out.append((mid, f'${mid:02X} {name} — {describe_effects(mid)}'))
    return out


# ------------------------------------------------------------- playback
def _rotr(b):
    return bytes(((x >> 1) | ((x & 1) << 7)) for x in b)


def _rotl(b):
    return bytes((((x << 1) & 0xFF) | (x >> 7)) for x in b)


class Player:
    """Replays a handler's measured schedule over a 2 KB sheet. `step(n)`
    advances n field frames and returns True when the sheet changed."""

    def __init__(self, mid, sheet):
        self.sched = {int(k): v for k, v in (handler(mid).get('schedule') or {}).items()} \
            if mid is not None else {}
        self.base = bytes(sheet)
        self.sheet = bytearray(sheet)
        self.counter = 0

    def reset(self):
        self.sheet = bytearray(self.base)
        self.counter = 0

    def _apply(self, ops):
        s = self.sheet
        for op in ops:
            if op[0] in ('R', 'L'):
                t = op[1]
                g = bytes(s[t * 16:t * 16 + 16])
                s[t * 16:t * 16 + 16] = _rotr(g) if op[0] == 'R' else _rotl(g)
            elif op[0] == 'S':
                a, b = op[1], op[2]
                ga, gb = bytes(s[a * 16:a * 16 + 16]), bytes(s[b * 16:b * 16 + 16])
                s[a * 16:a * 16 + 16], s[b * 16:b * 16 + 16] = gb, ga

    def step(self, n=1):
        changed = False
        for _ in range(n):
            ops = self.sched.get(self.counter)
            if ops:
                self._apply(ops)
                changed = True
            self.counter = (self.counter + 1) % CYCLE
            if self.counter == 0:
                # the census cycle starts from the untouched sheet; over 1024
                # frames every handler returns to it (rolls net whole turns,
                # swaps pair up — checked S99) except the Coliseum's 25-frame
                # swap ($52), which re-phases here: seamless everywhere else
                self.sheet = bytearray(self.base)
        return changed
