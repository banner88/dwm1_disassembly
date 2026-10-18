"""newgame.py — WHERE A NEW GAME STARTS (S152, ROADMAP E3 a2).

User (S152): "While I dont CARE if you can edit initial cutscene, editor probably
SHOULD have that capability. New game -> where to start -> etc." and "I guess it
would be good to audit what flags are set but I assume most of these are set by
original story?"

    custom.new_game = {
        "start": "intro" | "room",     # the game's intro bedroom (default) or a room
        "at": {"room": "<room id>", "screen": 0, "x": 5, "y": 4, "face": "down"},
        "story": "untouched" | "opening_done"}

Absent (or intro + untouched) = the original game: bank $15 TitleNewGameInit puts
the field in the intro bedroom ($2F) and bank $01 LoadFieldTilesDMA reads the
player's cell from DefaultSpawnTable[$2F] (Terry's bed).

"room" — the new game starts in one of the project's rooms (no bedroom, no
Warubou, no dresser): region `newgame_start` (patches/bank_015.asm, same size)
far-calls bank $79 entry 2 NewGameStart, which writes wMapID / wMapIDMirror,
wWarpRegion (region + 1) and the start cell into the WARP MAILBOX
(wIsPlayerChangingMaps = 1, wWarpSpawn*) — LoadFieldTilesDMA takes the mailbox
on that first load and clears the flag (measured S152, PyBoy). With the Milly
hook on, the player is MILLY from the first frame (NewGameStart sets $179F —
extended flags survive the first field load) and the hook's arrival scene plays
at the start cell (spinning in or appearing, as the hook says) — the hook's own
"Where Milly arrives" is not used then (the dresser never comes). With the hook
off, a one-step scene turns the player to `face` (the arrival forces facing up).

"opening_done" — the game's OWN rooms act as after the original opening, the
point where the King sends the player to the Travelers' Gates. Measured S152 on
the original ROM (PyBoy, the real intro played: bedroom → dresser → roots room →
the old man's walk → the Castle → the King → Pulio's farm (Slib picked up) → the
King again):

    flags  $0000 the intro bedroom done (bedroom screen 5's entry)
           $0001 arrived at the Castle (Castle script 0)
           $0002 the starter granted (Castle script 0: Slib — add_monster EID 1 —
                 into the farm; set right after, so it is given once)
           $0005 met Pulio (Farm script 26)
           $0007 the first monster taken from the farm into an empty party
                 (bank $12 $4EE1, Pulio's farm menu state 6 — engine)
           $0008 the King's second audience (Pulio to the dungeon; the gates open)
    bytes  $D92B Castle screen 1 := 1      $D92C Castle screen 5 := 3
           $D92D GreatTree screen 0 := 1   $D93C Gate Hub screen 1 := 1
           $D93F Farm screen 0 := 1        $D940 Farm screen 1 := 1
           $D944 Farm screen 6 := 1        $D974 intro bedroom screen 4 := 1

Without it a romhack that starts elsewhere (or leaves the intro by the Milly hook,
whose whirl sets $0000 / $D974 as the vanilla tail — S152) has the game's rooms in
their PRE-intro state: walking into the game's Castle plays the Minister / King
opening and gives Slib. With it, Slib is never given ($0002) and those rooms play their post-opening scenes. The first
field load of a new game (bank $01 ClearAnimationState, $C8EA = 0) zeroes
$D92A-$D9E9 — the flags and room states above — so they are set by the start
room's first scene (`ram` / `set` steps; the hook's arrival scene with the hook
on), not by NewGameStart. `$0000` / `$D974` only when the game starts in a room
(the intro sets them itself; the bedroom script skips its scene when $0000 is ON).
"intro" + "opening_done" needs the Milly hook (the game's own opening would play
past those flags and break).

Gold, items and the party start empty, as in the game (a farm keeper's *first
monster* or a *Give a monster* step gives the first one — services.py).
"""

import copy

from . import formats as F

STARTS = ('intro', 'room')
STORIES = ('untouched', 'opening_done')
FACES = ('down', 'left', 'up', 'right')
BEDROOM = 0x2F
SCENE_ID = '__game_start'
START_FLAG = 0x179E           # = the Milly hook's "arrival played" (reserved; hook off: the start scene)

OPENING_FLAGS = [0x0001, 0x0002, 0x0005, 0x0007, 0x0008]
OPENING_BYTES = [(0xD92B, 1), (0xD92C, 3), (0xD92D, 1), (0xD93C, 1), (0xD93F, 1),
                 (0xD940, 1), (0xD944, 1)]
ROOM_START_FLAGS = [0x0000]   # + when the game starts in a room (the intro sets them itself)
ROOM_START_BYTES = [(0xD974, 1)]
FLAG_WHAT = {0x0000: 'the intro bedroom done', 0x0001: 'arrived at the Castle',
             0x0002: 'the starter monster (Slib) given', 0x0005: 'met Pulio',
             0x0007: 'the first monster taken from the farm',
             0x0008: "the King's second audience (the gates open)"}
BYTE_WHAT = {0xD92B: 'Castle screen 1', 0xD92C: 'Castle screen 5', 0xD92D: 'GreatTree screen 0',
             0xD93C: 'Gate Hub screen 1', 0xD93F: 'Farm screen 0', 0xD940: 'Farm screen 1',
             0xD944: 'Farm screen 6', 0xD974: 'intro bedroom screen 4'}


class NewGameError(ValueError):
    pass


def settings(custom):
    """The normalized settings, or None when the project keeps the game's start
    (no custom.new_game, or intro + untouched)."""
    ng = (custom or {}).get('new_game')
    if not isinstance(ng, dict):
        return None
    start = ng.get('start', 'intro')
    story = ng.get('story', 'untouched')
    if start == 'intro' and story == 'untouched':
        return None
    return {'start': start, 'at': copy.deepcopy(ng.get('at')), 'story': story}


def active(custom):
    return settings(custom) is not None


def start_at(custom):
    """(room id, screen, x, y, face) of a room start, else None; NewGameError when
    the settings are broken."""
    s = settings(custom)
    if s is None or s['start'] != 'room':
        return None
    a = s['at']
    if not isinstance(a, dict) or not a.get('room'):
        raise NewGameError('custom.new_game: pick the room the game starts in (at.room)')
    try:
        k, x, y = int(a.get('screen', 0)), int(a['x']), int(a['y'])
    except (KeyError, TypeError, ValueError):
        raise NewGameError('custom.new_game.at: screen / x / y must be numbers')
    face = a.get('face', 'down')
    if face not in FACES:
        raise NewGameError(f'custom.new_game.at.face {face!r}: down / left / up / right')
    if not (0 <= k <= 15 and 0 <= x <= 9 and 0 <= y <= 7):
        raise NewGameError(f'custom.new_game.at: screen {k} cell ({x}, {y}) is outside the room '
                           '(screens 0-15, cells 0-9 x 0-7)')
    return str(a['room']), k, x, y, face


def _hook_on(custom):
    from . import milly as MH
    return MH.hook(custom) is not None


def story_steps(custom):
    """The cutscene steps that put the game's own rooms into their post-opening
    state ([] when the story is untouched)."""
    s = settings(custom)
    if s is None or s['story'] != 'opening_done':
        return []
    flags = list(OPENING_FLAGS)
    by = list(OPENING_BYTES)
    if s['start'] == 'room':
        flags = ROOM_START_FLAGS + flags
        by = by + ROOM_START_BYTES
    return [{'set': [f'0x{f:04X}' for f in flags]},
            {'ram': [[f'0x{a:04X}', v] for a, v in by]}]


def validate(prj):
    """(errors, warnings)."""
    errs, warns = [], []
    ng = prj.custom.get('new_game')
    if ng is None:
        return errs, warns
    if not isinstance(ng, dict):
        return ['custom.new_game: an object {start, at, story}'], warns
    unknown = set(ng) - {'start', 'at', 'story', 'comment'}
    if unknown:
        errs.append(f'custom.new_game: unknown keys {sorted(unknown)}')
    if ng.get('start', 'intro') not in STARTS:
        errs.append(f"custom.new_game.start {ng.get('start')!r}: 'intro' or 'room'")
    if ng.get('story', 'untouched') not in STORIES:
        errs.append(f"custom.new_game.story {ng.get('story')!r}: 'untouched' or 'opening_done'")
    if errs:
        return errs, warns
    s = settings(prj.custom)
    if s is None:
        return errs, warns
    if s['start'] == 'intro' and s['story'] == 'opening_done' and not _hook_on(prj.custom):
        errs.append("custom.new_game: 'the original opening as done' with the game's own intro "
                    'needs the Milly hook (otherwise the intro plays the opening the flags '
                    'say is over — start in one of your rooms, or tick the Milly hook)')
    try:
        at = start_at(prj.custom)
    except NewGameError as ex:
        return errs + [str(ex)], warns
    if at is not None:
        rid, k, x, y, _f = at
        room = next((r for r in prj.rooms if r.get('id') == rid), None)
        if room is None:
            errs.append(f'custom.new_game: the start room {rid!r} is not a room of this project')
        elif room.get('placeholder'):
            errs.append(f'custom.new_game: the start room {rid!r} is a placeholder')
        elif str(k) not in (room.get('screens') or {}):
            errs.append(f'custom.new_game: room {rid!r} has no screen {k}')
    return errs, warns


def lower(prj):
    """Project pass, BEFORE milly.lower: a room start with the hook on moves the
    hook's arrival to the start cell (the dresser never comes); the opening's story
    steps go into the arrival scene (milly.lower reads `_story_steps`); with the
    hook off the start room gets its own first scene. Mutates the project's copy."""
    s = settings(prj.custom)
    if s is None:
        return
    at = start_at(prj.custom)
    steps = story_steps(prj.custom)
    hook = _hook_on(prj.custom)
    if hook:
        h = prj.custom['milly_hook']
        if at is not None:
            rid, k, x, y, face = at
            h['arrive'] = {'room': rid, 'screen': k, 'x': x, 'y': y, 'face': face}
        h['_story_steps'] = steps
        return
    if at is None:
        return                       # intro + opening_done without the hook: validate stops it
    rid, k, x, y, face = at
    room = next((r for r in prj.custom.get('rooms') or [] if r.get('id') == rid), None)
    if room is None or str(k) not in (room.get('screens') or {}):
        raise NewGameError(f'custom.new_game: start room {rid!r} screen {k} is missing')
    scene = {'id': SCENE_ID, 'name': 'The game starts here (New game)', 'screen': k,
             'trigger': {'on': 'entry', 'once': f'0x{START_FLAG:04X}'},
             'player_start': {'x': x, 'y': y, 'face': face},
             'steps': steps + [{'face': {'actor': 'player', 'dir': face}}],
             '_then_next': True}
    room['cutscenes'] = [scene] + list(room.get('cutscenes') or [])


# ------------------------------------------------------------------ emitters

VANILLA_REGION = ('    ld a, $2f\n'
                  '    ld [wMapID], a\n'
                  '    ld [wMapIDMirror], a\n')


def emit_region_start(prj, warnings):
    """patches/bank_015.asm region newgame_start (8 bytes)."""
    if not active(prj.custom):
        return VANILLA_REGION
    return ('    ld hl, $7902                   ; S152 custom.new_game: bank $79 entry 2 NewGameStart\n'
            '    rst $10                        ;   (was ld a, $2f / ld [wMapID], a / ld [wMapIDMirror], a)\n'
            '    nop\n    nop\n    nop\n    nop\n')


def data_lines(prj):
    """Bank $79 NewGameData (template entry 2)."""
    s = settings(prj.custom)
    out = ['; ' + '=' * 77,
           '; NEW GAME START (generated by editor2/core/newgame.py from custom.new_game, S152)',
           '; ' + '=' * 77,
           'NewGameData:']
    flags = []
    if _hook_on(prj.custom) and s is not None and s['start'] == 'room':
        from . import milly as MH
        flags.append(MH.HOOK_FLAG)       # the player is Milly from the first frame
    at = start_at(prj.custom) if s is not None else None
    if at is None:
        out.append(f'    db ${BEDROOM:02X}, $00, $00   ; the intro bedroom, region 0, its default spawn')
        out.append('    dw $0000, $0000')
    else:
        rid, k, x, y, face = at
        room = next((r for r in prj.rooms if r.get('id') == rid), None)
        if room is None:
            raise NewGameError(f'custom.new_game: start room {rid!r} is not a room of this project')
        mid = F.val(room['mapID'])
        px = ((k % 4) * 10 + x) * 16 + 8
        py = ((k // 4) * 8 + y) * 16 + 8
        reg = F.mid_region(mid)
        out.append(f'    db ${mid & 0xFF:02X}, ${(reg + 1) if reg else 0:02X}, $01   ; {rid} '
                   f'(map ${mid & 0xFF:02X}, region {reg}), the cell below')
        out.append(f'    dw ${px:04X}, ${py:04X}   ; screen {k} cell ({x}, {y})')
    for f in flags:
        out.append(f'    dw ${f:04X}   ; extended flag ON at the start')
    out.append('    dw $FFFF')
    return out


REGIONS = [('newgame_start', 'patches/bank_015.asm', emit_region_start, 0x15)]
