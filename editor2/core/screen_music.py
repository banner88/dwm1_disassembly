"""screen_music.py — a SCREEN'S OWN SONG in a multi-screen room (S175, ROADMAP P3.3o).

User S175: "is it possible to have different pieces of music playing on different
screens of a multi screen room" → "Yes make that now. Song only switches if a screen's
song is new."

Schema: `custom.rooms[].screens[k].music = <song>` (a project song id, or a game song
'0xNN'); absent = the room's song. Two halves, both measured (PyBoy S175, the user's
project + save; SOUND_SYSTEM §12):

1. ENTERING the room (a door, a warp) and LOADING a save there: the game derives the
   room's song in bank $01 LoadNewBGMIdIntoA → bank $71 entry 2 CustomRoomBGMResolve,
   then `cp wCurrPlayingBGM / call nz, SetBGM` (a song already playing goes on). The
   resolver now asks the SCREEN first: a MusicRuleTable row of kind $10 + the screen,
   keyed by the room (music.py MUSIC_RULE_SCREEN; templates/bank_071_head.asm). Measured
   S175 before the change: a save made on a screen with its own song CONTINUEd to the
   room's song — the room's script 0 does not run on a save load.
2. SCROLLING to another screen of the room: the game re-runs the room's SCRIPT 0 at every
   scroll (bank $06 scroll sub-state [2], $66C7 — not in a gate, not while a script runs;
   measured: ScriptInit at the scroll). `lower(prj)` puts in front of script 0:
       branch_screen k → the block of k's song (screens without a song: the room's song)
       block: if a song request is pending (wBGM $C8B7 != $FF) and it is this song → done;
              no request and the song playing (wCurrPlayingBGM $C8B5) is this song → done;
              else wBGM := this song (the next VBlank starts it; InitBGM restarts a
              song, so the tests ARE the "only switches if new").
   It writes the request byte, not op $41 set_bgm, so the restore slot $C8B6 of a
   cutscene's set_bgm / restore_bgm is left alone. Script 0 also runs on room entry
   (measured): there the resolver's request is still pending and is replaced at once
   (one song starts, no blip).
The room's song for the screens without one, at a scroll = what the room plays with no
flag rule holding: its own song (rooms[].music / music.room_defaults), else $34 (an
unassigned custom room outside a gate — LoadNewBGMIdIntoA's gate path, measured: the
user's GreatLog plays $34). A room whose song changes by flag (music_rules): warned —
the scroll plays the base song on those screens.
"""

from . import formats as F
from . import music as M

WBGM = 0xC8B7                 # the song request byte ($FF = none)
CURRENT = 0xC8B5              # wCurrPlayingBGM
UNASSIGNED_CUSTOM = 0x34      # LoadNewBGMIdIntoA's gate path (custom rooms, outside a gate)


class ScreenMusicError(ValueError):
    pass


def screen_songs(room):
    """{screen: song value} of the screens with their own song."""
    out = {}
    for k, scr in (room.get('screens') or {}).items():
        if isinstance(scr, dict) and scr.get('music') not in (None, ''):
            out[int(k)] = scr['music']
    return out


def _param(prj, v, ctx):
    """A song value -> a script param: 'song:<id>' (a project song, resolved by the
    emitter) or '0xNN' (a game song)."""
    songs = {s.get('id') for s in ((prj.custom.get('music') or {}).get('songs') or [])
             if isinstance(s, dict)}
    if isinstance(v, str) and v in songs:
        return f'song:{v}'
    try:
        n = F.val(v)
    except Exception:                                           # noqa: BLE001
        n = None
    if not isinstance(n, int):
        raise ScreenMusicError(f"{ctx}: {v!r} is neither a project song nor a game song id")
    if not 1 <= n <= M.LAST_ID:
        raise ScreenMusicError(f"{ctx}: song id {F.hexb(n)} outside $01-$FC")
    return f'0x{n:04X}'


def base_song(prj, room):
    """The room's song when no flag rule holds (a value), else None = $34."""
    if room.get('music') not in (None, ''):
        return room['music']
    mid = F.val(room['mapID'])
    for k, v in ((prj.custom.get('music') or {}).get('room_defaults') or {}).items():
        try:
            if F.val(k) == mid:
                return v
        except Exception:                                       # noqa: BLE001
            pass
    return None


def prefix_ops(prj, room):
    """The ops put in front of the room's script 0 (labels _sm_*; ends at 'label:_sm_done')."""
    rid = room.get('id')
    own = screen_songs(room)
    base = base_song(prj, room)
    base_p = _param(prj, base, f'room {rid} song') if base is not None \
        else f'0x{UNASSIGNED_CUSTOM:04X}'
    params, block_of = [], {}
    for k in sorted(own):
        p = _param(prj, own[k], f'room {rid} screen {k} music')
        if p not in params:
            params.append(p)
        block_of[k] = params.index(p)
    if base_p not in params:
        params.append(base_p)
    base_i = params.index(base_p)
    ops = []
    for k in sorted(own):
        if block_of[k] != base_i:
            ops.append(['op', 'branch_screen', f'0x{k:04X}', f'@_sm_{block_of[k]}'])
    ops.append(['op', 'goto', f'@_sm_{base_i}'])
    for i, p in enumerate(params):
        ops += [f'label:_sm_{i}',
                ['op', 'check_and_branch', f'0x{WBGM:04X}', '0x00FF', f'@_sm_{i}_c'],
                ['op', 'check_and_branch', f'0x{WBGM:04X}', p, '@_sm_done'],
                ['op', 'goto', f'@_sm_{i}_w'],
                f'label:_sm_{i}_c',
                ['op', 'check_and_branch', f'0x{CURRENT:04X}', p, '@_sm_done'],
                f'label:_sm_{i}_w',
                ['op', 'write_ram', f'0x{WBGM:04X}', p],
                ['op', 'goto', '@_sm_done']]
    ops.append('label:_sm_done')
    return ops


def lower(prj):
    """Every room with a screen song: its script 0 := the song check + its own entry ops."""
    from . import cutscene_build as CB
    scripts = prj.custom.setdefault('scripts', [])
    by_id = {s.get('id'): s for s in scripts if isinstance(s, dict)}
    for r in prj.rooms:
        if not screen_songs(r):
            continue
        table = r.setdefault('scripts', {})
        orig = by_id.get(table.get('0'))
        if orig is not None and 'ops' not in orig:
            raise ScreenMusicError(f"room {r.get('id')}: its entry script "
                                   f"{table.get('0')!r} is not lowered yet")
        ops = prefix_ops(prj, r)
        ops += CB._prefix_ops(orig['ops'], 'o_') if orig is not None else [['end']]
        sid = f"screenmusic:{r.get('id')}"
        new = {'id': sid, 'ops': ops,
               'comment': "S175: each screen's own song at a scroll (screen_music.py) + "
                          "the room's entry script"}
        scripts.append(new)
        by_id[sid] = new
        table['0'] = sid


def problems(prj):
    """-> (errors, warnings)."""
    errs, warns = [], []
    err = getattr(prj, 'screen_music_error', None)
    if err:
        errs.append(f'screen music: {err}')
    for r in prj.rooms:
        own = screen_songs(r)
        if not own:
            continue
        name = r.get('name') or r.get('id')
        if r.get('music_rules'):
            warns.append(f"{name}: its song changes by flag (music rules) — on the screens "
                         "without their own song a scroll plays the room's base song "
                         "(entering the room follows the rules)")
        missing = [k for k in own if str(k) not in (r.get('screens') or {})]
        if missing:
            errs.append(f"{name}: music on screens {missing} that do not exist")
    return errs, warns


# ---------------------------------------------------------------------------
# editing (Document mixin)
# ---------------------------------------------------------------------------
class ScreenMusicMixin:
    def screen_music(self, room, key):
        scr = (room.get('screens') or {}).get(str(key)) or {}
        return scr.get('music')

    def set_screen_music(self, room, key, value):
        """value None = the room's song."""
        scr = (room.get('screens') or {}).get(str(key))
        if scr is None:
            raise ValueError(f'no screen {key}')
        if value in (None, ''):
            scr.pop('music', None)
        else:
            scr['music'] = value
        self.touch()
