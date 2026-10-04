"""ram_names.py — plain-English names for what game scripts write and test
(S118f, user: "I want everything interpretable please").

A script step like `$D92B := 0` writes the value 0 into the game's memory at
address $D92B. This module turns those addresses (and their values) into words:

  * ROOM STATES — the $D92A-$D99A step counters that pick which version of a
    screen shows (who stands where, which tiles). Named from the room table
    (extracted/map_table.json): "Castle screen 1 → state 0".
  * the game's own variables — CURATED below, each read from the code
    (BANK04_SCRIPT_ENGINE "Script variables", known_RAM_map; the S118f
    reading is cited per entry there).
  * NPC slot fields ($D7D2 + 32·k) and the player's position (HRAM $FF92…).

describe(addr, value=None, op='write'|'test'|'inc'|'word') -> one phrase.
"""

NPC_SLOTS = 0xD7D2

# value -> words, per variable
_FOLLOW_HIDE = {0: 'everyone shown', 1: 'Terry hidden', 3: 'Terry + monster 1 hidden',
                7: 'Terry + monsters 1-2 hidden', 15: 'Terry and all monsters hidden',
                9: 'Terry + monster 3 hidden', 13: 'Terry + monsters 2-3 hidden',
                14: 'the monsters hidden (Terry shown)'}
_GAME_MODES = {0: 'the title screen', 1: 'the field', 2: 'a battle',
               3: 'the bank $02 picture scenes (the ceremony, the tree)',
               4: 'the bank $5F cutscene engine', 5: 'the bank $5F cutscene engine (2nd)'}
# (ARCHITECTURE "Top-level game mode"; 3 / 4 by what they run, not named further)
_ARENA_CLASSES = 'GFEDCBAS'


def _shades(v):
    return {0: 'all white (flash)', 0xFF: 'all black'}.get(
        v, f'shades {"-".join(str((v >> s) & 3) for s in (0, 2, 4, 6))} (0 light … 3 dark)')


def _arena_group(v):
    if v < 8:
        return f'class {_ARENA_CLASSES[v]}'
    return {8: 'the Starry Night tournament', 9: "the King's match"}.get(v, str(v))


def _chest(v):
    return {0: 'already opened', 0xFF: 'empty'}.get(v, f'holds item {v}')


# addr: (name, value words: dict | callable | None, what it is)
CURATED = {
    0xC83C: ('the YES/NO answer', {0: 'YES', 1: 'NO'},
             'what the player picked in the last YES/NO box'),
    0xC842: ('the buttons held', {0: 'none'},
             'cleared so the player does not keep walking after the script'),
    0xC846: ('the buttons pressed this frame', {0: 'none'}, None),
    0xC88A: ('the game mode', _GAME_MODES, None),
    0xC88B: ('the next game mode', _GAME_MODES,
             'the mode "fade out and switch game mode" goes to'),
    0xC88E: ('the mode-change request', None, 'set → the main loop switches mode now'),
    0xC89B: ('the background palette (fade)', _shades,
             'the shades of the background — the scripts flash / fade with it'),
    0xC89C: ('sprite palette 1 (fade)', _shades, None),
    0xC89D: ('sprite palette 2 (fade)', _shades, None),
    0xC8A6: ('the field frame counter', None, None),
    0xC8B1: ('screen shake (up / down)', None, 'frames of vertical shaking'),
    0xC8B2: ('screen shake (left / right)', None, 'frames of sideways shaking'),
    0xC8EB: ('the field state', None, None),
    0xC8EC: ('all field sprites hidden', {0: 'shown', 1: 'hidden'},
             'player, monsters and NPCs drawn or not'),
    0xC8ED: ('hidden sprites', _FOLLOW_HIDE,
             'bit 0 Terry, bits 1-3 the following monsters'),
    0xC8F2: ('the name the naming screen edits', {0xCA42: "the hero's name"},
             '$CA42 = the hero name the [HERO] text code prints (bank $56)'),
    0xC8F4: ("the naming screen's default name", {0: 'none'}, None),
    0xC905: ('the battle-transition state', None, None),
    0xC96C: ('the room change in progress', {1: 'yes'}, None),
    0xC96D: ('the warp destination (gate)', None, None),
    0xC96E: ('the warp kind', None, None),
    0xCA8D: ('the number of monsters in the party', None, None),
    0xCAB4: ('the arena classes won', lambda v: f'{v} ({"none" if v == 0 else "up to class " + _ARENA_CLASSES[min(v, 8) - 1]})',
             None),
    0xCAB9: ('the Starry Night scene selector', None, None),
    0xD8E1: ('the last check\'s result', None,
             'set by the party / bag / library checks just before'),
    0xD8E3: ('the flight path of the next fly-in / fly-off', None,
             'low byte = length, high byte = curve'),
    0xD951: ('the breeding-shrine stage / return code', {
        2: 'naming the newborn', 6: 'from the intro bedroom', 7: 'the breeding ceremony',
        8: 'after the ceremony', 0xF0: 'back to the Starry Shrine (breeding)',
        0xF1: 'back to the Starry Shrine', 0xF2: 'back to the Arena Lobby / Restaurant / Queen',
        0xFF: 'the intro journey (dresser → GreatTree → Castle)'}, None),
    0xD974: ('the intro bedroom screen 4 state', {6: 'the intro finished'}, None),
    0xD9CB: ('the room effect phase', {0: 'not shown yet', 1: 'shown / step 1', 2: 'stopped'},
             'Arena Rooms: the entry sequence already shown this visit; breeding room: '
             'the palette pulse'),
    0xD9CD: ('the arena match', lambda v: {0xFE: 'the special match', 0xFF: 'none'}.get(
        v, f'match {v + 1}'), None),
    0xD9CE: ('the arena class', _arena_group, None),
    0xD9DF: ('the Goopy game round', {0: 'playing', 5: 'won'}, None),
    0xD9E0: ("the Goopy game's pick", None, None),
    0xD9E2: ('arriving at the Farm by the Shrine warp', {0: 'no', 1: 'yes'}, None),
    0xD9E3: ("the King's speech for the next Castle arrival", None, None),
    0xD9E4: ("the Well boss's tile event seen", {0: 'not yet', 1: 'seen'}, None),
    0xD9E5: ('the party is falling through a hole', {0: 'no', 1: 'yes'},
             'the next room plays the falling-in scene'),
    0xD9E6: ('the "rare breed" mark', {0: 'not rare'}, None),
    0xD9E8: ('player input locked (scripted scroll)', {0: 'free', 1: 'locked'}, None),
    0xD9E9: ('the current step of a multi-step screen', None, None),
    0xDA02: ('the battle: number of enemies', lambda v: f'{v + 1} enem{"y" if v == 0 else "ies"}',
             None),
    0xDA03: ('the battle: enemy 1', None, None),
    0xDA05: ('the battle: enemy 2', None, None),
    0xDA07: ('the battle: enemy 3', None, None),
}
# S118g: these have NO reader in the game's code — only scripts write / test them,
# so their meaning is inferred from the scripts that use them (shown as such).
INFERRED = {0xD9CD, 0xD9CE, 0xD9E2, 0xD9E3, 0xD9E4, 0xD9E5, 0xC96D, 0xC96E}
INFERRED_TAG = '  (meaning inferred from the scripts that use it)'

for _k in range(8):
    CURATED[0xD9CF + _k] = (f'treasure chest {_k + 1}', _chest,
                            'in gate rooms; the Coliseum uses the same bytes for its own '
                            'counters')

HRAM = {0xFF92: "Terry's X position (pixels)", 0xFF93: "Terry's X position (high byte)",
        0xFF95: "Terry's Y position (pixels)", 0xFF96: "Terry's Y position (high byte)",
        0xFF8E: "Terry's facing", 0xFF90: "Terry's sprite flags"}

_SLOT_FIELDS = {0: 'shown / type', 1: 'sprite', 4: 'script', 5: 'status', 6: 'facing',
                8: 'walk-pattern phase', 0x10: 'animation running', 0x12: 'animation',
                0x14: 'shown frame', 0x18: 'X position', 0x19: 'X position (high)',
                0x1A: 'Y position', 0x1B: 'Y position (high)'}


class RamNames:
    """Names with the room table (rooms = cutscenes.Rooms) for room states and,
    optionally, enemy names (eid -> 'Slime') for the battle set-up words."""

    def __init__(self, rooms=None, enemy_name=None):
        self.rooms = rooms
        self.enemy_name = enemy_name
        self._ctr = None

    def counters(self):
        """{counter addr: [(map, screen)]} from the room table."""
        if self._ctr is None:
            self._ctr = {}
            vt = getattr(self.rooms, 'vt', None)
            for mid, e in (vt.entries.items() if vt else []):
                for sr in e.get('sub_rooms', []):
                    try:
                        a = int(sr['ram_counter'], 16)
                    except (KeyError, ValueError, TypeError):
                        continue
                    self._ctr.setdefault(a, []).append((mid, sr['c925']))
        return self._ctr

    def _room(self, mid):
        try:
            return self.rooms.name(mid)
        except Exception:                                # noqa: BLE001
            return f'room ${mid:02X}'

    def name(self, addr):
        """(name, value-words, about) for an address, or None."""
        if addr in CURATED:
            return CURATED[addr]
        if addr in HRAM:
            return (HRAM[addr], None, None)
        if NPC_SLOTS <= addr < NPC_SLOTS + 32 * 8:
            n, off = (addr - NPC_SLOTS) // 32 + 1, (addr - NPC_SLOTS) % 32
            return (f'NPC {n}: {_SLOT_FIELDS.get(off, f"slot byte +${off:02X}")}', None, None)
        users = self.counters().get(addr)
        if users:
            seen = []
            for m, sc in sorted(users):
                w = f'{self._room(m)} screen {sc}'
                if w not in seen:
                    seen.append(w)
            where = seen[0] + (f' (+{len(seen) - 1} room variant(s) sharing it)'
                               if len(seen) > 1 else '')
            return (f'the room state of {where}', lambda v: f'state {v}',
                    'which version of the screen shows (who stands where, which tiles)')
        return None

    def value(self, addr, v):
        nm = self.name(addr)
        if nm is None or nm[1] is None:
            if addr in (0xDA03, 0xDA05, 0xDA07) and self.enemy_name:
                en = self.enemy_name(v)
                return f'{en} (enemy row {v})' if en else f'enemy row {v}'
            return str(v)
        words = nm[1]
        if callable(words):
            return words(v)
        return words.get(v, str(v))

    def write(self, addr, v, word=False):
        """'X := y' in words (+ the raw step in brackets)."""
        raw = f'[${addr:04X} := {"$%04X" % v if word else v}]'
        if word and addr == 0xD8E3:
            return f'The next fly-in / fly-off: length {v & 0xFF}, curve {v >> 8}  {raw}'
        if word and addr == 0xC8B1:
            return (f'Shake the screen: {v & 0xFF} up/down, {v >> 8} left/right  {raw}')
        nm = self.name(addr)
        if nm is None:
            return f'${addr:04X} := {v}  (not yet named)'
        val = self.value(addr, v)
        if nm[0].startswith('the room state of'):
            return f'Room state of {nm[0][len("the room state of "):]} → {val}  {raw}'
        tag = INFERRED_TAG if addr in INFERRED else ''
        return f'{nm[0][0].upper()}{nm[0][1:]}: {val}  {raw}{tag}'

    def test(self, addr, v):
        nm = self.name(addr)
        if nm is None:
            return f'${addr:04X} = {v}'
        tag = INFERRED_TAG if addr in INFERRED else ''
        return f'“{nm[0]}” is {self.value(addr, v)}{tag}'

    def inc(self, addr):
        nm = self.name(addr)
        return f'Add 1 to {nm[0] if nm else "$%04X" % addr}  [${addr:04X} + 1]'
