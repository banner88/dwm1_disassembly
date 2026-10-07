"""your_arena.py — the project's OWN ARENA (ROADMAP P3.14e3, S128; PROJECT_COMPILER
§2.41; SIDEQUEST_MAP "Your arena (S128)").

User (S128): "there's a central arena and I want it accessible from a custom room.
Its fine to have a custom arena room I can edit, complete with 'going in animation'
and 'arena animation' like its fine to lift it wholesale I just want to be able to
edit battles (already can) as well as tiles in arena proper AND in arena entry, and
redirect outwards"; per class a lock and where a win sends you ("chosen per class");
the GreatLog arena ends on the Starry Night tournament; Monster Grandpa's match stays in the
original game's post-game arena.

So the arena = two COPIES of the game's rooms (Rooms tab → Make editable):
  * the LOBBY  — a copy of the Arena Lobby $06 (the receptionist's desk = its
                 script 6, the three party monsters on screen 0, the doors)
  * the ARENA  — a copy of the Arena Battle room $5D (the walk-in of the master and
                 his monsters, the announcer, the crowd's animation, cmd_20 per match)
whose tiles, NPCs, doors and scripts are edited like any copied room. The engine
treats the two copies as $06 / $5D at every check the original keys on the map id
(ROM0 ArenaMapID; CROSSBANK_ROOMS "S128 sites"), the class menu marks a locked class
"-" (bank $6E ArenaMarkClasses), a lost match goes back to the project's lobby (bank
$50 ArenaLossWarp50).

Schema:

  "arena": {
    "lobby": "<room id>",            # a copy of $06 (source_mapID $06)
    "battle": "<room id>",           # a copy of $5D (source_mapID $5D)
    "return": {"screen": 1, "x": 4, "y": 4},   # where a lost match / a won class
                                     # puts you in the lobby (default: the game's)
    "lines": "<line set id>",        # optional: custom.service_lines of kind "arena"
                                     # (the class menu's words, +0 .. +6)
    "words": {"lost": TEXT, "locked": TEXT, "no": TEXT},   # optional
    "classes": {"G": {"opens_when": [{"flag": f, "is": "set"|"clear"}, …],
                      "won_flag": "<flag>", "won_words": TEXT,
                      "then": THEN}, … "S": …},
    "starry": {"opens_when": [terms], "won_flag": "<flag>",
               "offer": TEXT, "yes": TEXT, "no": TEXT, "won_words": TEXT,
               "then": THEN}         # absent = the desk never offers Starry Night
  }
  TEXT = a dialogue id or {"boxes": [[line, line], …], "speaker", "voice"}
  THEN = {"to": "lobby"} (default for a class) | {"to": "room", "room": id,
          "screen": k, "x": x, "y": y} | {"to": "hub"} (the hub, arrival reason
          arena_won) | {"to": "ending"} (Starry Night only, its default: the game's
          own scene after the final + the ending, game mode 3)

What the compiler writes (Project.__init__ → lower_desk / lower_entries):
  * the lobby's script 6 (the desk) = arena:desk — Starry Night's offer when its
    terms hold (and its won flag is not set), else the class menu (op $04 4 $0710,
    the line set around it); B → "Better luck next time."; a class → the game's
    walk-in (the party vanishing through the door: $C8ED 1/3/7/$F), op $1F, the
    warp into the ARENA.
  * in front of the lobby's entry script: $D9CD = $FF (a lost match; the engine sent
    you back) → heal (op $27), the lost words; $D9CD = $FE (the arena's
    "Congratulations!" sent you back) → per class: $CAB4 := class + 1 (the menu's
    stars, the Mimics' tier), the won flag of that class and of every lower class
    that has one (the game's catch-up), the won words, THEN.
  * in front of the arena's entry script (with Starry Night): after the final
    ($D9CE 8, $D9CD 3) the Starry won flag, then THEN (or the game's own scene +
    ending for "ending").
  * in both copies' scripts: a map_transition to $06 goes to the lobby (at the
    return cell), one to $5D to the arena.
  * region arena_rooms (patches/bank_06e.asm): ARENA_LOBBY_MID, ARENA_BATTLE_MID,
    ARENA_RET_X / _Y, ARENA_LOCKED_OFS and ArenaLockTable (the classes' terms).
No "arena" = $FF ids, no locks: every byte as before (the game's arena untouched).
"""
from . import formats as F

CLASSES = ['G', 'F', 'E', 'D', 'C', 'B', 'A', 'S']
STARRY = 8
STARRY_STATES = 5                    # the Arena Battle room's step entries ($D999 0-4)
LOBBY_SOURCE, BATTLE_SOURCE = 0x06, 0x5D
DESK_SCRIPT = '6'
MENU_BASE = 0x0710                    # the class menu's text base (op $04 4 $0710)
RETURN_DEFAULT = {'screen': 1, 'x': 4, 'y': 4}     # = pixel ($E8, $48), the game's
ARENA_PX, ARENA_PY = 0x78, 0x58       # where the desk's walk-in lands in the arena
WON_TEXT = {0: 0x00E4, 1: 0x017A, 2: 0x01B6, 3: 0x021C, 4: 0x02E1, 5: 0x0341, 6: 0x039F,
            7: 0x03F1}                # the game's "Well done! You survived X class!"
LOST_TEXT = 0x00E3                    # "Too bad. You need more training. …"
NO_TEXT = 0x0713                      # menu line +3 "Better luck next time."
STARRY_OFFER, STARRY_YES, STARRY_NO = 0x04AF, 0x04B1, 0x04B0
LOCKED_DEFAULT = "That class is\nnot open yet."
# RAM the scripts use (known_RAM_map / SIDEQUEST_MAP E1)
W_C8ED, W_D951, W_D999 = 0xC8ED, 0xD951, 0xD999       # follower mask, breeding code, Starry phase
W_D9CD, W_D9CE, W_CAB4, W_C83C = 0xD9CD, 0xD9CE, 0xCAB4, 0xC83C
KEYS = {'lobby', 'battle', 'return', 'lines', 'words', 'classes', 'starry', 'comment', 'name'}
CLASS_KEYS = {'opens_when', 'won_flag', 'won_words', 'then', 'comment'}
STARRY_KEYS = {'opens_when', 'won_flag', 'won_words', 'then', 'offer', 'yes', 'no', 'comment'}
WORD_KEYS = {'lost', 'locked', 'no'}
THEN_TO = ('lobby', 'room', 'hub', 'ending')
MAX_TERMS = 8


class ArenaRoomError(ValueError):
    pass


def section(data_or_prj):
    c = data_or_prj.custom if hasattr(data_or_prj, 'custom') else \
        (data_or_prj.get('custom') or {})
    return c.get('arena')


def _room(prj, rid, ctx):
    r = prj.room_by_id(rid) if rid else None
    if r is None:
        raise ArenaRoomError(f"{ctx}: no room {rid!r} in custom.rooms")
    return r


def _src(r):
    try:
        return F.val(r.get('source_mapID'))
    except Exception:                                            # noqa: BLE001
        return None


def _terms(prj, terms, ctx):
    if terms is None:
        return []
    if not isinstance(terms, list):
        raise ArenaRoomError(f"{ctx}: a list of {{\"flag\": …, \"is\": \"set\" | \"clear\"}}")
    out = []
    for i, t in enumerate(terms):
        if not isinstance(t, dict) or 'flag' not in t:
            raise ArenaRoomError(f"{ctx}[{i}]: {{\"flag\": <flag>, \"is\": \"set\" | \"clear\"}}")
        is_ = t.get('is', 'set')
        if is_ not in ('set', 'clear'):
            raise ArenaRoomError(f"{ctx}[{i}]: 'is' must be set / clear")
        try:
            idx = prj.resolve_flag_ref(t['flag'], f"{ctx}[{i}]")
        except Exception as ex:                                  # noqa: BLE001
            raise ArenaRoomError(str(ex))
        out.append((idx, is_ == 'clear'))
    if len(out) > MAX_TERMS:
        raise ArenaRoomError(f"{ctx}: {len(out)} flag terms (max {MAX_TERMS})")
    return out


def _flag(prj, ref, ctx):
    if ref is None:
        return None
    try:
        return prj.resolve_flag_ref(ref, ctx)
    except Exception as ex:                                      # noqa: BLE001
        raise ArenaRoomError(str(ex))


def _then(prj, th, ctx, starry):
    if th is None:
        th = {'to': 'ending' if starry else 'lobby'}
    if not isinstance(th, dict) or th.get('to') not in THEN_TO:
        raise ArenaRoomError(f"{ctx}: {{\"to\": {' | '.join(THEN_TO)}}}")
    to = th['to']
    if to == 'ending' and not starry:
        raise ArenaRoomError(f"{ctx}: 'ending' is Starry Night's (the game's ending "
                             "follows the tournament's final)")
    bad = set(th) - ({'to', 'room', 'screen', 'x', 'y', 'comment'} if to == 'room'
                     else {'to', 'comment'})
    if bad:
        raise ArenaRoomError(f"{ctx}: unknown keys {sorted(bad)}")
    out = {'to': to}
    if to == 'room':
        r = _room(prj, th.get('room'), ctx + '.room')
        k, x, y = int(th.get('screen', 0)), th.get('x'), th.get('y')
        if x is None or y is None:
            raise ArenaRoomError(f"{ctx}: a room needs the cell 'x' / 'y'")
        mid = F.val(r['mapID'])
        prob = prj.move_screen_problem(f'room:${mid:02X}', mid, k)
        if prob:
            raise ArenaRoomError(f"{ctx}: {prob}")
        out.update(room=r['id'], mid=mid, screen=k, x=int(x), y=int(y))
    return out


def _text(prj, txt, ident, ctx, choice=False):
    """-> a text id for a `text` op: a dialogue id as given, a number (the game's
    text), or an inline {"boxes"} made into custom.dialogue entry `ident`."""
    if txt is None:
        return None
    if isinstance(txt, int):
        return txt
    if isinstance(txt, str):
        return txt
    if isinstance(txt, dict) and txt.get('boxes'):
        from . import textenc as T
        try:
            T.check_boxes(txt['boxes'], txt.get('speaker'), txt.get('voice'))
        except T.TextError as ex:
            raise ArenaRoomError(f'{ctx}: {ex}')
        ent = {'id': ident, 'boxes': [list(b) for b in txt['boxes']],
               'comment': f'your arena ({ctx})'}
        for k in ('speaker', 'voice'):
            if txt.get(k) is not None:
                ent[k] = txt[k]
        if choice:
            ent['choice'] = True
        prj.custom.setdefault('dialogue', []).append(ent)
        return ident
    raise ArenaRoomError(f'{ctx}: a text is a dialogue id or {{"boxes": [[…]]}}')


def px_of(k, x, y):
    return ((k % 4) * 10 + x) * 16 + 8, ((k // 4) * 8 + y) * 16 + 8


def resolve(prj):
    """custom.arena checked and resolved (cached on prj._your_arena; None = no
    arena). Needs prj.rooms (resolved rooms). Raises ArenaRoomError."""
    c = getattr(prj, '_your_arena', 'unset')
    if c != 'unset':
        return c
    a = section(prj)
    if a is None:
        prj._your_arena = None
        return None
    ctx = 'custom.arena'
    if not isinstance(a, dict):
        raise ArenaRoomError(f"{ctx}: an object")
    bad = set(a) - KEYS
    if bad:
        raise ArenaRoomError(f"{ctx}: unknown keys {sorted(bad)}")
    lobby = _room(prj, a.get('lobby'), ctx + '.lobby')
    battle = _room(prj, a.get('battle'), ctx + '.battle')
    if _src(lobby) != LOBBY_SOURCE:
        raise ArenaRoomError(f"{ctx}.lobby: {lobby['id']!r} is not a copy of the Arena Lobby "
                             "($06) — make it with Make editable on the Arena Lobby")
    if _src(battle) != BATTLE_SOURCE:
        raise ArenaRoomError(f"{ctx}.battle: {battle['id']!r} is not a copy of the Arena "
                             "Battle room ($5D) — make it with Make editable on the Arena "
                             "Battle room")
    if lobby is battle:
        raise ArenaRoomError(f"{ctx}: the lobby and the arena are two rooms")
    ret = dict(RETURN_DEFAULT, **(a.get('return') or {}))
    if set(ret) - {'screen', 'x', 'y', 'comment'}:
        raise ArenaRoomError(f"{ctx}.return: {{\"screen\", \"x\", \"y\"}}")
    k, x, y = int(ret['screen']), int(ret['x']), int(ret['y'])
    if str(k) not in (lobby.get('screens') or {}) or not (0 <= x <= 9 and 0 <= y <= 7):
        raise ArenaRoomError(f"{ctx}.return: screen {k} cell ({x}, {y}) is not in the "
                             f"lobby (its screens: {', '.join(sorted(lobby.get('screens') or {}, key=int))})")
    rpx, rpy = px_of(k, x, y)
    words = a.get('words') or {}
    if set(words) - WORD_KEYS:
        raise ArenaRoomError(f"{ctx}.words: unknown keys {sorted(set(words) - WORD_KEYS)}")
    classes = a.get('classes') or {}
    if not isinstance(classes, dict) or set(classes) - set(CLASSES):
        raise ArenaRoomError(f"{ctx}.classes: keys {', '.join(CLASSES)}")
    cls = []
    for i, cname in enumerate(CLASSES):
        cc = classes.get(cname) or {}
        c2 = f"{ctx}.classes.{cname}"
        if set(cc) - CLASS_KEYS:
            raise ArenaRoomError(f"{c2}: unknown keys {sorted(set(cc) - CLASS_KEYS)}")
        cls.append({'name': cname, 'terms': _terms(prj, cc.get('opens_when'), c2 + '.opens_when'),
                    'flag': _flag(prj, cc.get('won_flag'), c2 + '.won_flag'),
                    'words': cc.get('won_words'), 'then': _then(prj, cc.get('then'), c2 + '.then',
                                                                False)})
    st = a.get('starry')
    starry = None
    if st is not None:
        c2 = f"{ctx}.starry"
        if not isinstance(st, dict) or set(st) - STARRY_KEYS:
            raise ArenaRoomError(f"{c2}: unknown keys {sorted(set(st or {}) - STARRY_KEYS)}")
        starry = {'terms': _terms(prj, st.get('opens_when'), c2 + '.opens_when'),
                  'flag': _flag(prj, st.get('won_flag'), c2 + '.won_flag'),
                  'then': _then(prj, st.get('then'), c2 + '.then', True), 'src': st}
    if starry is not None:
        n = len((battle.get('screens') or {}).get('0', {}).get('states') or [None])
        if n < STARRY_STATES:
            raise ArenaRoomError(
                f"{ctx}.battle: {battle['id']!r} has {n} state(s) — the Arena Battle room has "
                f"{STARRY_STATES} ($D999: 0 the classes, 1-3 Starry Night at night, 4 Monster Grandpa's match); "
                "this copy was made before S128, when the room's night states were skipped. "
                "Make a new copy (Make editable on the Arena Battle room) — Starry Night would "
                "load a state the copy does not have and crash")
    lines = a.get('lines')
    if lines is not None:
        from . import services as SV
        sets = SV.resolve(prj)['sets']
        if lines not in sets or sets[lines]['kind'] != 'arena':
            raise ArenaRoomError(f"{ctx}.lines: {lines!r} is not an 'arena' line set in "
                                 "custom.service_lines")
    prj._your_arena = dict(src=a, lobby=lobby, battle=battle, lobby_mid=F.val(lobby['mapID']),
                           battle_mid=F.val(battle['mapID']), ret=(k, x, y), rpx=rpx, rpy=rpy,
                           words=words, classes=cls, starry=starry, lines=lines)
    return prj._your_arena


# ------------------------------------------------------------------ lowering
def _go(prj, ar, th, ctx):
    """THEN as ops (each ends the script)."""
    to = th['to']
    if to == 'lobby':
        return [['op', 'map_transition', f"0x{ar['lobby_mid']:04X}", f"0x{ar['rpx']:04X}",
                 f"0x{ar['rpy']:04X}"], ['end']]
    if to == 'room':
        px, py = px_of(th['screen'], th['x'], th['y'])
        return [['op', 'map_transition', f"0x{th['mid']:04X}", f'0x{px:04X}', f'0x{py:04X}'],
                ['end']]
    if to == 'hub':
        return prj.hub_warp_ops('arena_won', ctx) + [['end']]
    raise ArenaRoomError(f'{ctx}: {to!r}')


def _menu_text(prj, ar, off):
    from . import services as SV
    return SV._text_ref(prj, ar['lines'], 'arena', off)


def _set_n(prj, ar):
    from . import services as SV
    return SV.resolve(prj)['numbers'].get(ar['lines']) if ar['lines'] else None


def walk_in_ops(battle_mid):
    """The game's walk into the arena (Arena Lobby script 6 $4824): the party
    vanishes through the door one by one ($C8ED 1 / 3 / 7 / $F with the player's
    step up), the player hidden ($FF90 bit 6), match 0 built (op $1F), the warp."""
    ops = ['label:ar_walk']
    for mask in (1, 3, 7):
        ops += [['op', 'write_ram', f'0x{W_C8ED:04X}', mask], ['op', 'delay', 2],
                ['op', '0x0B', 0, '0xFFF0']]
    ops += [['op', 'write_ram', f'0x{W_C8ED:04X}', 0x0F], ['op', 'delay', 2],
            ['op', 'npc_write', 0, '0xFF90', '0x0040'],
            ['op', 'write_ram', f'0x{W_D9CD:04X}', 0], ['op', '0x1F'],
            ['op', 'map_transition', f'0x{battle_mid:04X}', f'0x{ARENA_PX:04X}',
             f'0x{ARENA_PY:04X}'], ['end']]
    return ops


def desk_ops(prj, ar):
    """The receptionist (the lobby's script 6): Starry Night's offer, else the
    class menu; B -> the 'no' words; a class -> the walk-in."""
    ops = []
    st = ar['starry']
    if st is not None:
        s = st['src']
        if st['flag'] is not None:
            ops.append(['op', 'if_flag_set', st['flag'], '@ar_menu'])
        for idx, clr in st['terms']:
            ops.append(['op', 'if_flag_set' if clr else 'if_flag_clear', idx, '@ar_menu'])
        offer = _text(prj, s.get('offer'), 'arena:starry_offer', 'custom.arena.starry.offer',
                      choice=True) or STARRY_OFFER
        yes = _text(prj, s.get('yes'), 'arena:starry_yes', 'custom.arena.starry.yes') or STARRY_YES
        no = _text(prj, s.get('no'), 'arena:starry_no', 'custom.arena.starry.no') or STARRY_NO
        ops += [['text', offer], ['op', 'check_and_branch', f'0x{W_C83C:04X}', 1, '@ar_sno'],
                ['text', yes], ['op', 'delay', 4], ['op', 'face_up', 0], ['op', 'delay', 0x0C],
                ['op', '0x0B', 0, '0xFFF0'],
                ['op', 'write_ram', f'0x{W_D9CE:04X}', STARRY],
                ['op', 'write_ram', f'0x{W_D999:04X}', 1], ['op', 'goto', '@ar_walk'],
                'label:ar_sno', ['text', no], ['end'], 'label:ar_menu']
    n = _set_n(prj, ar)
    no_t = _text(prj, ar['words'].get('no'), 'arena:no', 'custom.arena.words.no') or \
        _menu_text(prj, ar, 3)
    ops += [['text', _menu_text(prj, ar, 0)]]
    ops += ([['op', 'write_ram', 'wServiceLines', n]] if n else [])
    ops += [['op', '0x04', 4, f'0x{MENU_BASE:04X}']]
    ops += ([['op', 'write_ram', 'wServiceLines', 0]] if n else [])
    ops += [['op', 'check_and_branch', f'0x{W_D9CD:04X}', 0xFF, '@ar_no'],
            ['op', 'write_ram', f'0x{W_D999:04X}', 0], ['op', 'delay', 4],
            ['op', 'face_up', 0], ['op', 'delay', 2], ['op', '0x0B', 0, '0xFFF0'],
            ['op', 'goto', '@ar_walk']]
    ops += walk_in_ops(ar['battle_mid'])
    ops += ['label:ar_no', ['text', no_t], ['op', 'write_ram', f'0x{W_D9CD:04X}', 0], ['end']]
    return ops


def lobby_return_ops(prj, ar):
    """In front of the lobby's entry script: back from the arena."""
    lost = _text(prj, ar['words'].get('lost'), 'arena:lost', 'custom.arena.words.lost') or \
        LOST_TEXT
    back = [['op', 'write_ram', f'0x{W_C8ED:04X}', 0], ['op', 'monster_party_op2'],
            ['op', 'npc_write', 0, '0xFF90', '0x0000'], ['op', 'face_left', 0]]
    ops = [['op', 'check_and_branch', f'0x{W_D951:04X}', 0xF2, '@ar_orig'],
           ['op', 'check_and_branch', f'0x{W_D9CD:04X}', 0xFE, '@ar_won'],
           ['op', 'check_and_branch', f'0x{W_D9CD:04X}', 0xFF, '@ar_lost'],
           ['op', 'goto', '@ar_orig'],
           'label:ar_lost'] + back + [
           ['op', 'write_ram', f'0x{W_D9CD:04X}', 0], ['op', 'init_dialog'], ['text', lost],
           ['end'], 'label:ar_won'] + back
    for i in range(8):
        ops.append(['op', 'check_and_branch', f'0x{W_D9CE:04X}', i, f'@ar_c{i}'])
    ops += [['op', 'write_ram', f'0x{W_D9CD:04X}', 0], ['end']]
    for i, c in enumerate(ar['classes']):
        ops += [f'label:ar_c{i}', ['op', 'write_ram', f'0x{W_CAB4:04X}', i + 1]]
        for j in range(i, -1, -1):                 # this class, then the lower ones
            f = ar['classes'][j]['flag']
            if f is not None:
                ops.append(['op', 'set_flag', f])
        ops += [['op', 'write_ram', f'0x{W_D9CD:04X}', 0], ['op', 'init_dialog'],
                ['text', _text(prj, c['words'], f'arena:won_{c["name"]}',
                               f'custom.arena.classes.{c["name"]}.won_words') or WON_TEXT[i]]]
        if c['then']['to'] == 'lobby':
            ops.append(['end'])                    # already there
        else:
            ops += [['op', 'close_text']] + _go(prj, ar, c['then'],
                                               f'custom.arena.classes.{c["name"]}.then')
    return ops


def battle_return_ops(prj, ar):
    """In front of the arena's entry script: after Starry Night's final."""
    st = ar['starry']
    ops = [['op', 'check_and_branch', f'0x{W_D9CE:04X}', STARRY, '@ar_sn'],
           ['op', 'goto', '@ar_orig'], 'label:ar_sn',
           ['op', 'check_and_branch', f'0x{W_D9CD:04X}', 3, '@ar_sw'],
           ['op', 'goto', '@ar_orig'], 'label:ar_sw']
    if st['flag'] is not None:
        ops.append(['op', 'set_flag', st['flag']])
    if st['then']['to'] == 'ending':
        return ops + [['op', 'goto', '@ar_orig']]          # the game's scene + ending
    ops += [['op', 'npc_write', 0, '0xFF90', '0x0000'],
            ['op', 'write_ram', f'0x{W_C8ED:04X}', 0],
            ['op', 'write_ram', f'0x{W_D999:04X}', 0], ['op', 'write_ram', f'0x{W_D9CD:04X}', 0]]
    w = _text(prj, st['src'].get('won_words'), 'arena:starry_won',
              'custom.arena.starry.won_words')
    if w is not None:
        ops += [['op', 'init_dialog'], ['text', w], ['op', 'close_text']]
    # the room is still fading in when its entry script starts: a warp in the first
    # tick leaves a white screen and the game waiting (PyBoy S128) — the game's own
    # warps out of this room yield first ("Congratulations!" … delay 8)
    ops.append(['op', 'delay', 8])
    return ops + _go(prj, ar, st['then'], 'custom.arena.starry.then')


def _retarget(prj, ar, room):
    """A copy's map_transition to $06 -> the lobby (at the return cell); to $5D ->
    the arena. (Only the two arena rooms' own scripts.)"""
    scripts = {s.get('id'): s for s in prj.custom.get('scripts', [])}
    for sid in set((room.get('scripts') or {}).values()):
        s = scripts.get(sid)
        if s is None or 'ops' not in s:
            continue
        for op in s['ops']:
            if isinstance(op, list) and op[:2] == ['op', 'map_transition'] and len(op) >= 5:
                try:
                    w = F.val(op[2])
                except Exception:                               # noqa: BLE001
                    continue
                if w == LOBBY_SOURCE:
                    op[2:5] = [f"0x{ar['lobby_mid']:04X}", f"0x{ar['rpx']:04X}",
                               f"0x{ar['rpy']:04X}"]
                elif w == BATTLE_SOURCE:
                    op[2] = f"0x{ar['battle_mid']:04X}"


def lower_desk(prj):
    """After the rooms resolve (before the cutscenes wrap talk scripts): the desk."""
    ar = resolve(prj)
    if ar is None:
        return
    table = ar['lobby'].setdefault('scripts', {})
    sid = 'arena:desk'
    prj.custom.setdefault('scripts', []).append(
        {'id': sid, 'ops': desk_ops(prj, ar),
         'comment': "S128: your arena's desk (editor2/core/your_arena.py)"})
    table[DESK_SCRIPT] = sid


def lower_entries(prj):
    """After the cutscenes: the return scripts in front of the two rooms' entry
    scripts, the copies' transitions retargeted."""
    from . import cutscene_build as CB
    ar = resolve(prj)
    if ar is None:
        return
    scripts = prj.custom.setdefault('scripts', [])
    by_id = {s.get('id'): s for s in scripts}
    _retarget(prj, ar, ar['lobby'])
    _retarget(prj, ar, ar['battle'])
    pairs = [(ar['lobby'], lobby_return_ops(prj, ar), 'lobby')]
    if ar['starry'] is not None:
        pairs.append((ar['battle'], battle_return_ops(prj, ar), 'arena'))
    for room, ret, what in pairs:
        table = room.setdefault('scripts', {})
        orig = by_id.get(table.get('0'))
        if orig is not None and 'ops' not in orig:
            raise ArenaRoomError(f"room {room.get('id')}: its entry script {table.get('0')!r} "
                                 'is not lowered yet')
        ops = ret + ['label:ar_orig']
        ops += CB._prefix_ops(orig['ops'], 'a_') if orig is not None else [['end']]
        gid = f"arena:{room.get('id')}:entry"
        new = {'id': gid, 'ops': ops,
               'comment': f"S128: your arena's {what} return + the room's entry script"}
        scripts.append(new)
        by_id[gid] = new
        table['0'] = gid


# ------------------------------------------------------------------ emitters
def locked_text_id(prj):
    """The dialogue id of the locked words (the class menu's +6 frame), or None."""
    return 'arena:locked'


def locked_dialogue(prj):
    """[the locked words' dialogue entry] (added by Project with the services')."""
    ar = resolve(prj)
    if ar is None or not any(c['terms'] for c in ar['classes']):
        return []
    from . import services as SV
    vl = SV.vline('arena', 6, getattr(prj, 'repo_root', None))
    txt = ar['words'].get('locked')
    if txt is None:
        txt = LOCKED_DEFAULT
    if not isinstance(txt, str):
        raise ArenaRoomError("custom.arena.words.locked: the menu's words — a string "
                             "(\\n a new line, \\n\\n a new box)")
    probs = SV.line_problems(vl, txt)
    if probs:
        raise ArenaRoomError(f"custom.arena.words.locked: {probs[0]}")
    by = SV.encode_line(vl, txt)
    return [{'id': 'arena:locked', 'raw': [['bytes'] + list(by)],
             'comment': 'your arena: a locked class chosen (menu frame +6)', '_service': True}]


def emit_rooms(prj, warnings):
    """Region arena_rooms (patches/bank_06e.asm)."""
    ar = resolve(prj)
    out = ["; (generated by editor2 `arena_rooms` from custom.arena — editor2/core/your_arena.py)"]
    if ar is None:
        out += ["ARENA_LOBBY_MID EQU $FF                 ; the project's lobby (a copy of $06); $FF = none",
                "ARENA_BATTLE_MID EQU $FF                ; the project's arena (a copy of $5D); $FF = none",
                "ARENA_RET_X EQU $00E8                   ; return pixel in the lobby (x)",
                "ARENA_RET_Y EQU $0048                   ; return pixel in the lobby (y)",
                "ARENA_LOCKED_OFS EQU $0006              ; the locked words' text id - $0710 (6 = the won line)",
                "ArenaLockTable:  ; G F E D C B A S: [n terms] + n x dw flag (bit 15 = must be clear)",
                "    db 0, 0, 0, 0, 0, 0, 0, 0"]
        return "\n".join(out) + "\n"
    tid = {e['id']: e['_tid'] for e in prj._dialogue if 'id' in e and '_tid' in e}
    lk = tid.get('arena:locked')
    ofs = (lk - MENU_BASE) & 0xFFFF if lk is not None else 6
    k, x, y = ar['ret']
    out += [f"ARENA_LOBBY_MID EQU ${ar['lobby_mid']:02X}                 ; {ar['lobby']['id']} (a copy of $06)",
            f"ARENA_BATTLE_MID EQU ${ar['battle_mid']:02X}                ; {ar['battle']['id']} (a copy of $5D)",
            f"ARENA_RET_X EQU ${ar['rpx']:04X}                   ; return: screen {k} cell ({x}, {y})",
            f"ARENA_RET_Y EQU ${ar['rpy']:04X}",
            f"ARENA_LOCKED_OFS EQU ${ofs:04X}              ; " +
            (f"text ${lk:04X} (arena:locked) - $0710" if lk is not None else "no lock: the won line"),
            "ArenaLockTable:  ; G F E D C B A S: [n terms] + n x dw flag (bit 15 = must be clear)"]
    for c in ar['classes']:
        ws = ", ".join(f"${(i | (0x8000 if clr else 0)):04X}" for i, clr in c['terms'])
        out.append(f"    db {len(c['terms'])}" + (f"\n    dw {ws}" if ws else "") +
                   f"   ; {c['name']} class")
    return "\n".join(out) + "\n"


REGIONS = [('arena_rooms', 'patches/bank_06e.asm', emit_rooms, 0x6E)]


# ------------------------------------------------------------------ the flag index
def flag_uses(prj):
    """[(flag index, role, place words, path)] for the flag index (kind 'arena')."""
    try:
        ar = resolve(prj)
    except ArenaRoomError:
        return []
    if ar is None:
        return []
    out = []
    for i, c in enumerate(ar['classes']):
        for idx, clr in c['terms']:
            out.append((idx, 'check', f"the arena's {c['name']} class opens when it is "
                        f"{'OFF' if clr else 'ON'}", ['custom', 'arena', 'classes', c['name']]))
        if c['flag'] is not None:
            out.append((c['flag'], 'set', f"winning the arena's {c['name']} class (or a higher one)",
                        ['custom', 'arena', 'classes', c['name']]))
    st = ar['starry']
    if st is not None:
        for idx, clr in st['terms']:
            out.append((idx, 'check', f"Starry Night is offered when it is "
                        f"{'OFF' if clr else 'ON'}", ['custom', 'arena', 'starry']))
        if st['flag'] is not None:
            out.append((st['flag'], 'set', "winning Starry Night's final (the desk stops "
                        "offering it)", ['custom', 'arena', 'starry']))
    return out


def validate(prj):
    """-> warnings; raises ArenaRoomError."""
    ar = resolve(prj)
    if ar is None:
        return []
    w = []
    desk = False
    for k, scr in prj.room_screens(ar['lobby']).items():
        for st in prj.screen_states(scr):
            for e in st.get('npcs', []) or []:
                # the game's desk is an examine spot ($8F) on the counter at (3, 4) of
                # screen 1 carrying script 6 — the player talks ACROSS the counter; an
                # NPC entry with script 6 works the same
                s = e.get('script')
                if e.get('kind') == 'raw':
                    try:
                        s = F.val(e['bytes'][4])
                    except Exception:                            # noqa: BLE001
                        s = None
                if s is not None and (str(s) == DESK_SCRIPT or s == 'arena:desk'):
                    desk = True
    if not desk:
        w.append(f"custom.arena: nothing in {ar['lobby']['id']} runs script "
                 f"{DESK_SCRIPT} (the receptionist's desk: the spot on the counter) — "
                 "nobody opens the class menu")
    for c in ar['classes']:
        if c['then']['to'] == 'hub' and not (prj.custom.get('hub') or {}).get('rules'):
            w.append(f"custom.arena.classes.{c['name']}.then: 'hub' with no hub rules — "
                     "a win goes to the Castle")
    return w
