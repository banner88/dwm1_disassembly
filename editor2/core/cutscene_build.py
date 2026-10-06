"""cutscene_build.py — the project's OWN cutscenes (S119, ROADMAP P3.8 part B).

Headless (no Qt). A cutscene belongs to a room (`custom.rooms[].cutscenes[]`,
PROJECT_COMPILER §2.33) and is authored in TILES with named actors:

    {"id": "fount_welcome", "name": "Welcome", "screen": 0,
     "trigger": {"on": "entry" | "talk" | "examine" | "stepon",
                 "actor": "Guard",              # talk: the NPC talked to
                 "x": 6, "y": 3, "facing": "any",  # examine / step-on cell
                 "when_on": [flags], "when_off": [flags],
                 "once": "<flag name>"},        # plays once (set when it starts)
     "player_start": {"x": 5, "y": 4},          # entry scenes: where the player
                                                # stands when it starts (optional)
     "steps": [STEP, ...]}

Actors are NPCs of the scene's screen named with `"actor": "<name>"` on their
NPC entry (every state of the screen), or "player". The compiler turns a name
into the slot number the game uses (NPC n = the n-th NPC of the screen's list,
spots not counted — BANK04_SCRIPT_ENGINE "Actors") and refuses a name that has
different slots in different room states. A CAST member is an NPC entry with
`"hidden": true, "cast": true` — invisible until a scene shows it.

STEP kinds (exactly one kind key per step; every place is a CELL of the scene's
screen, 0-9 x 0-7, a little outside allowed for walking off):

    say {TEXT, box: auto|top|bottom}   ask {TEXT, yes: [..], no: [..]}
    if [{flag, is}], then: [..], else: [..]     set [flags]   clear [flags]
    walk {actor, to: [x, y], first: x|y, together, fast, keep_facing}
    face {actor, dir: up|down|left|right | toward: <actor>}
    show {actor, how: instant|flicker|spin, at: [x, y]}   hide {actor, how}
    anim {actor, move: hop|jump|...}           (ANIMS: the game's own programs)
    fly  {actor, dir: in_left|in_right|off_left|off_right, to: [x, y] (in),
          length: 1-9, curve: 0-5, together}
    wait {frames}      wait_walks true
    music {song} | "back"     sound <id>
    shake {dir: up_down|left_right|both, frames, wait}
    fade {to: black | normal, step: frames}    flash {frames}
    followers hide|show
    give_item {item, got: TEXT, full: TEXT}    give_monster {enemy, got, full}
    tiles {x, y, rows: [[metatile, ...], ...]} (S119 part d — the room's metatiles)
    battle {enemies: [1-3]}    move {dest, screen, x, y}    end true
    name_hero true            (S121: the game's naming screen for the hero's name)

TEXT = a dialogue id (str) or {"boxes": [[line, line], ...]} (inline; the
compiler adds the dialogue entry).

Everything measured in PyBoy S119 (BANK04_SCRIPT_ENGINE "Writing scenes
(S119)"): a text after ANY yielding step needs init_dialog — even in a talk
script; a box still open before `end` must be closed; $10 / $11 walk the
player or an NPC to an absolute pixel (exact wherever he stands — used when
the model does not know where the actor is); queued walks ($1A / $1B) run
together until wait_movement; shake = $C8B1 / $C8B2 frames; fades = the
vanilla shade steps of $C89B-$C89D.

The same pass produces the ops AND a model (positions in pixels, facing,
shown, a frame timeline) — the editor draws and previews the model, the
compiler emits the ops, so the two cannot drift apart.
"""

import copy

from . import formats as F
from . import script_ops as SO

DIRS = {'down': 0, 'left': 1, 'up': 2, 'right': 3}
DIR_NAMES = ['down', 'left', 'up', 'right']
FACE_OPS = {'up': 'face_up', 'down': 'face_down', 'left': 'face_left', 'right': 'face_right'}
PLAYER = 'player'
NPC_SLOTS = 0xD7D2                      # NPC n = slot n-1, 32 B (+$18 X, +$1A Y)
WALK_FRAMES_PER_PX = 4 / 3              # 1 px on 3 of 4 frames (PyBoy S118)
TEXT_FRAMES = 110                       # the preview's time per text box
CELL_MIN, CELL_MAX_X, CELL_MAX_Y = -3, 12, 10   # walking off the screen is allowed

# The game's own movement programs (opcode $1C, measured S118 — script_ops.PROGRAMS):
# name -> (NPC program, player program, label)
ANIMS = {
    'hop': (0x01, 0x01, 'hop'),
    'jump': (0x04, 0x04, 'jump'),
    'spin_jump': (0x09, 0x1A, 'spin jump'),
    'jump_up': (0x02, None, 'jump up 2 tiles'),
    'jump_up_stay': (0x0A, None, 'jump up and stay (38 px)'),
    'double_jump': (0x0B, None, 'double jump up (58 px)'),
    'leap_up': (0x0F, None, 'leap up 4 tiles'),
    'float_up': (0x0E, None, 'float up 1 tile'),
    'rise_settle': (0x13, None, 'rise high, hang, settle 40 px up'),
    'drop': (0x11, None, 'drop 4 tiles'),
    'hop_drop': (0x10, None, 'hop, then drop 4 tiles'),
    'hop_drop_short': (0x12, None, 'hop, then drop 2 tiles'),
    'leap_right': (0x05, None, 'leap 5 tiles right'),
    'leap_left': (0x19, 0x07, 'leap left (NPC 5 tiles, player 4)'),
    'run_off_left': (0x0C, None, 'run off left, sinking'),
    'spin_float_up': (None, 0x03, 'spin and float up 3 tiles'),
    'pause': (None, 0x06, 'pause 64 frames (followers catch up)'),
}
FLY = {'in_left': 0x15, 'in_right': 0x16, 'off_left': 0x17, 'off_right': 0x18}
FLY_NAMES = {'in_left': 'fly in from the upper right, landing down-left',
             'in_right': 'fly in from the upper left, landing down-right',
             'off_left': 'fly off up-left', 'off_right': 'fly off up-right'}
SHADE_NORMAL = (0xD2, 0xD2, 0xE2)       # $C89B / $C89C / $C89D (vanilla Castle fades)
SHADE_FADE = [(0xE7, 0xE7, 0xF7), (0xFB, 0xFB, 0xFB), (0xFF, 0xFF, 0xFF)]
SHADE_REGS = (0xC89B, 0xC89C, 0xC89D)

STEP_KINDS = ('say', 'ask', 'if', 'set', 'clear', 'walk', 'face', 'show', 'hide', 'anim',
              'fly', 'wait', 'wait_walks', 'music', 'sound', 'shake', 'fade', 'flash',
              'followers', 'give_item', 'give_monster', 'tiles', 'battle', 'move', 'end',
              'name_hero', 'heal')
STEP_NAMES = {
    'say': 'Say', 'ask': 'Ask YES / NO', 'if': 'If flags…', 'set': 'Turn flags ON',
    'clear': 'Turn flags OFF', 'walk': 'Walk to a tile', 'face': 'Turn to face',
    'show': 'Appear', 'hide': 'Disappear', 'anim': 'Hop / jump / leap…',
    'fly': 'Fly in / fly off', 'wait': 'Wait', 'wait_walks': 'Wait until everyone stops',
    'music': 'Music', 'sound': 'Sound effect', 'shake': 'Shake the screen',
    'fade': 'Fade to black / back', 'flash': 'Flash', 'followers': 'Hide / show the monsters',
    'give_item': 'Give an item', 'give_monster': 'Give a monster',
    'tiles': 'Change tiles of the room', 'battle': 'Battle', 'move': 'Warp the player',
    'end': 'Stop here', 'name_hero': 'Name the hero', 'heal': 'Heal the party'}
TRIGGERS = ('entry', 'talk', 'examine', 'stepon')
# S125 (ROADMAP P3.14d): why the player was sent to the hub — an entry scene with
# trigger.arrival [reasons] plays only for those (wHubReason, patches/wram.asm;
# the numbers are Project.HUB_REASONS = the HUB_* EQUs)
ARRIVALS = ('lost', 'wiped', 'warpwing', 'final_lost', 'home', 'arena_won')
ARRIVAL_NUM = {k: i + 1 for i, k in enumerate(ARRIVALS)}
ARRIVAL_NAMES = {'lost': 'lost a battle', 'wiped': 'the party fell (floor damage)',
                 'warpwing': 'WarpWing / Anchor', 'final_lost': 'lost the Starry / arena final',
                 'home': 'sent home by a script', 'arena_won': 'won an arena class'}
W_HUB_REASON = 0xD2EF


class CutsceneError(ValueError):
    pass


def step_kind(st):
    ks = [k for k in STEP_KINDS if isinstance(st, dict) and k in st]
    return ks[0] if len(ks) == 1 else None


# ------------------------------------------------------------------ the cast

def is_npc_entry(e):
    k = e.get('kind')
    if k == 'npc':
        return True
    if k == 'raw':
        return F.val(e['bytes'][0]) < 0x80
    return False


def entry_type_byte(e):
    if e.get('kind') == 'raw':
        return F.val(e['bytes'][0]) & 0xFF
    return F.npc_type_byte(e.get('facing', 'down'), e.get('behaviour', 0),
                           bool(e.get('hidden')))


def entry_sprite(e):
    if e.get('kind') == 'raw':
        return F.val(e['bytes'][1]) & 0xFF
    if e.get('monster') is not None:
        return None
    return F.val(e.get('sprite', 0)) & 0xFF


def entry_cell(e):
    if e.get('kind') == 'raw':
        return F.val(e['bytes'][2]), F.val(e['bytes'][3])
    return int(e['x']), int(e['y'])


def screen_npc_lists(room, screen):
    """[npc list per room state] of one screen (the raw room dict)."""
    scr = (room.get('screens') or {}).get(str(screen))
    if scr is None:
        scr = (room.get('screens') or {}).get(screen)
    if scr is None:
        return []
    states = scr.get('states')
    if states:
        return [st.get('npcs') or [] for st in states]
    return [scr.get('npcs') or []]


class Cast:
    """The named actors of one screen: name -> slot number per room state."""

    def __init__(self, room, screen):
        self.room, self.screen = room, int(screen)
        self.lists = screen_npc_lists(room, screen)
        self.slots = {}           # name -> {state: n}
        self.entries = {}         # name -> [(state, entry)]
        self.count = []           # NPC count per state
        for k, lst in enumerate(self.lists):
            n = 0
            for e in lst:
                if not is_npc_entry(e):
                    continue
                n += 1
                nm = e.get('actor')
                if nm:
                    self.slots.setdefault(nm, {})[k] = n
                    self.entries.setdefault(nm, []).append((k, e))
            self.count.append(n)

    def names(self):
        return sorted(self.slots)

    def has(self, name):
        return name == PLAYER or name in self.slots

    def slot(self, name):
        """-> (n, problem or None). n = 0 for the player."""
        if name == PLAYER:
            return 0, None
        if name not in self.slots:
            return None, f'no NPC named “{name}” on screen {self.screen}'
        by = self.slots[name]
        ns = sorted(set(by.values()))
        if len(ns) > 1:
            where = ', '.join(f'state {k}: NPC {n}' for k, n in sorted(by.items()))
            return None, (f'“{name}” is a different NPC number in different room states '
                          f'({where}) — the game moves NPCs by number; keep it at the same '
                          'place in every state\'s NPC list')
        return ns[0], None

    def missing_states(self, name):
        if name == PLAYER:
            return []
        have = set(self.slots.get(name, {}))
        return [k for k in range(len(self.lists)) if k not in have]

    def entry(self, name):
        got = self.entries.get(name)
        return got[0][1] if got else None

    def start(self, name):
        """(px, py) absolute room pixels of the NPC's own cell, or None when its
        states disagree."""
        got = self.entries.get(name) or []
        cells = {entry_cell(e) for _k, e in got}
        if len(cells) != 1:
            return None
        x, y = cells.pop()
        return cell_px(self.screen, x, y)

    def face(self, name):
        e = self.entry(name)
        if e is None:
            return 0
        return (entry_type_byte(e) >> 4) & 3

    def shown(self, name):
        e = self.entry(name)
        return e is not None and not (entry_type_byte(e) & 0x40)


def cell_px(screen, x, y):
    col, row = screen % 4, screen // 4
    return ((col * 10 + x) * 16 + 8, (row * 8 + y) * 16 + 8)


def px_cell(screen, px, py):
    col, row = screen % 4, screen // 4
    return ((px - 8) / 16 - col * 10, (py - 8) / 16 - row * 8)


# ------------------------------------------------------------------ env

class Env:
    """What the lowering needs from the project. The compiler passes a Project
    (strict); the editor passes a lenient one (unknown names do not stop the
    drawing — they are reported)."""

    def __init__(self, prj=None, flag_names=(), enemies=(), strict=False):
        self.prj, self.strict = prj, strict
        self.flag_names = set(flag_names)
        self.enemies = set(enemies)
        self.dialogue = []           # new entries (inline texts)

    def custom(self):
        return self.prj.custom if self.prj is not None else (self.data_custom or {})

    data_custom = None

    def flag(self, ref, ctx):
        if self.prj is not None:
            return self.prj.resolve_flag_ref(ref, ctx)
        if isinstance(ref, str) and ref in self.flag_names:
            return 0x1000 + sorted(self.flag_names).index(ref)
        try:
            v = F.val(ref)
            if isinstance(v, int):
                return v
        except (TypeError, ValueError):
            pass
        raise CutsceneError(f'{ctx}: flag {ref!r} is not defined')

    def enemy(self, ref, ctx):
        if self.prj is not None:
            return self.prj.enemy_ref(ref, ctx)
        if isinstance(ref, str) and ref in self.enemies:
            return 519
        try:
            v = F.val(ref)
            if isinstance(v, int):
                return v
        except (TypeError, ValueError):
            pass
        raise CutsceneError(f'{ctx}: enemy {ref!r} is not defined')

    def move_words(self, mv, ctx):
        if self.prj is not None:
            return self.prj._move_words(mv, ctx)
        dest = str(mv.get('dest', ''))
        if ':' not in dest:
            raise CutsceneError(f'{ctx}: dest must be room:$xx or vanilla:$xx')
        mid = F.val(dest.split(':', 1)[1])
        k, x, y = int(mv.get('screen', 0)), int(mv.get('x', 0)), int(mv.get('y', 0))
        px, py = ((k % 4) * 10 + x) * 16 + 8, ((k // 4) * 8 + y) * 16 + 8
        return f'0x{mid:04X}', f'0x{px:04X}', f'0x{py:04X}'

    def hub_ops(self, reason, ctx):
        """S125: the warp home (the hub ladder; the editor's preview: the Castle)."""
        if self.prj is not None:
            return self.prj.hub_warp_ops(reason, ctx)
        return [['op', 'write_ram', '0xD92B', 6],
                ['op', 'map_transition', '0x0000', '0x00E8', '0x0058']]

    def text(self, txt, ident, ctx, choice=False):
        """-> a dialogue id."""
        if isinstance(txt, str):
            return txt
        if isinstance(txt, dict) and txt.get('boxes'):
            from . import textenc as T
            try:
                T.check_boxes(txt['boxes'], txt.get('speaker'), txt.get('voice'))
            except T.TextError as ex:
                raise CutsceneError(f'{ctx}: {ex}')
            ent = {'id': ident, 'boxes': [list(b) for b in txt['boxes']],
                   'comment': f'cutscene text ({ctx})'}
            for k in ('speaker', 'voice'):              # S120: who speaks, which blip
                if txt.get(k) is not None:
                    ent[k] = txt[k]
            if choice:
                ent['choice'] = True
            self.dialogue.append(ent)
            return ident
        raise CutsceneError(f'{ctx}: a text is a dialogue id or {{"boxes": [[…]]}}')


# ------------------------------------------------------------------ actor state

class Act:
    __slots__ = ('x', 'y', 'face', 'shown', 'known')

    def __init__(self, x, y, face, shown, known=True):
        self.x, self.y, self.face, self.shown, self.known = x, y, face, shown, known

    def copy(self):
        return Act(self.x, self.y, self.face, self.shown, self.known)

    def as_dict(self):
        return {'x': self.x, 'y': self.y, 'face': self.face, 'shown': self.shown,
                'known': self.known}


# ------------------------------------------------------------------ lowering

class Lowerer:
    """One scene's steps -> ops + the model. `prefix` keeps its labels unique
    inside the combined trigger script."""

    def __init__(self, env, room, scene, prefix='c'):
        self.env, self.room, self.scene, self.p = env, room, scene, prefix
        self.screen = int(scene.get('screen', 0))
        self.cast = Cast(room, self.screen)
        self.ops = []
        self.n = 0
        self.box = False
        self.locked = False
        self.fast = False
        self.T = 0
        self.busy = {}                 # actor slot -> frame its queued move ends
        self.errors, self.warnings = [], []
        self.info = []                 # per step (play order of authored steps)
        self.ended = False
        self.acts = {}                 # slot -> Act
        self.names = {}                # slot -> actor name
        self._init_actors()

    # -------------------------------------------------------------- set-up
    def _init_actors(self):
        trig = self.scene.get('trigger') or {}
        on = trig.get('on', 'entry')
        start = None
        face = DIRS['down']
        if on == 'stepon' and 'x' in trig:
            start = cell_px(self.screen, int(trig['x']), int(trig['y']))
        elif on == 'examine' and trig.get('facing') in DIRS and 'x' in trig:
            f = DIRS[trig['facing']]
            dx, dy = {0: (0, -1), 1: (1, 0), 2: (0, 1), 3: (-1, 0)}[f]
            start = cell_px(self.screen, int(trig['x']) + dx, int(trig['y']) + dy)
            face = f
        elif on == 'entry' and isinstance(self.scene.get('player_start'), dict):
            ps = self.scene['player_start']
            start = cell_px(self.screen, int(ps.get('x', 5)), int(ps.get('y', 4)))
            face = DIRS.get(ps.get('face', 'down'), 0)
        known = start is not None
        if start is None:
            ps = self.scene.get('player_start') or {}
            start = cell_px(self.screen, int(ps.get('x', 5)), int(ps.get('y', 4)))
            face = DIRS.get(ps.get('face', 'down'), 0)
            if on == 'talk':
                t = self.cast.start(trig.get('actor', ''))
                if t is not None:
                    start = (t[0], t[1] + 16)
                    face = DIRS['up']
        self.acts[0] = Act(start[0], start[1], face, True, known)
        self.names[0] = PLAYER
        for nm in self.cast.names():
            n, prob = self.cast.slot(nm)
            if n is None:
                continue
            st = self.cast.start(nm)
            if st is None:
                ent = self.cast.entry(nm)
                st = cell_px(self.screen, *entry_cell(ent))
                known = False
            else:
                known = True
            self.acts[n] = Act(st[0], st[1], self.cast.face(nm), self.cast.shown(nm), known)
            self.names[n] = nm

    def snapshot(self):
        return {self.names.get(n, f'NPC {n}'): a.as_dict() for n, a in self.acts.items()}

    # -------------------------------------------------------------- helpers
    def label(self, tag):
        self.n += 1
        return f'{self.p}_{tag}{self.n}'

    def op(self, name, *params):
        self.ops.append(['op', name] + list(params))

    def err(self, ctx, msg):
        if self.env.strict:
            raise CutsceneError(f'{ctx}: {msg}')
        self.errors.append(f'{ctx}: {msg}')

    def warn(self, ctx, msg):
        self.warnings.append(f'{ctx}: {msg}')

    def actor(self, name, ctx):
        n, prob = self.cast.slot(name) if name else (None, 'no actor chosen')
        if n is None:
            self.err(ctx, prob)
            return None
        if n and n not in self.acts:
            self.err(ctx, f'“{name}” has no place on screen {self.screen}')
            return None
        miss = self.cast.missing_states(name)
        if miss and len(self.cast.lists) > 1:
            self.warn(ctx, f'“{name}” is not in room state(s) {miss} of screen '
                           f'{self.screen}: if the scene plays in one of them, NPC {n} there '
                           'is someone else')
        return n

    def cell(self, v, ctx):
        try:
            x, y = int(v[0]), int(v[1])
        except (TypeError, ValueError, IndexError):
            self.err(ctx, 'a cell is [x, y]')
            return None
        if not (CELL_MIN <= x <= CELL_MAX_X and CELL_MIN <= y <= CELL_MAX_Y):
            self.err(ctx, f'cell ({x}, {y}) is too far outside the screen')
            return None
        if not (0 <= x <= 9 and 0 <= y <= 7):
            self.warn(ctx, f'cell ({x}, {y}) is outside the screen (the actor walks out of view)')
        return x, y

    def close(self):
        if self.box:
            self.op('close_text')
            self.box = False

    def text(self, txt, ctx, ident, pos=None, choice=False):
        try:
            tid = self.env.text(txt, ident, ctx, choice)
        except CutsceneError as ex:
            if self.env.strict:
                raise
            self.errors.append(str(ex))
            tid = ident
        if pos in ('top', 'bottom'):
            self.close()
            self.op('0x3D' if pos == 'top' else '0x3C')
        if not self.box:
            # S119 measured: a text after any yielding step needs init_dialog
            # (talk scripts too); init_dialog with the box already open is harmless
            self.op('init_dialog')
        from . import textenc as _T
        if isinstance(txt, dict) and _T.uses_lead({'boxes': txt.get('boxes')}):
            self.op('load_lead_name')        # S120: {lead} = $F9 $00 needs $C180 filled
        self.ops.append(['text', tid])
        self.box = True
        nb = len(txt['boxes']) if isinstance(txt, dict) and txt.get('boxes') else 1
        self.T += TEXT_FRAMES * nb
        return tid

    def wait_all(self):
        self.op('wait_movement')
        if self.busy:
            self.T = max([self.T] + list(self.busy.values()))
        self.busy.clear()
        self.fast = False
        if self.locked:
            self.op('unlock_movement')
            self.locked = False

    def _need_idle(self, n):
        if n in self.busy:
            self.wait_all()

    # -------------------------------------------------------------- steps
    def lower(self, steps, path=()):
        if not isinstance(steps, list):
            self.err('steps', 'steps must be a list')
            return
        for i, st in enumerate(steps):
            pth = path + (i,)
            ctx = 'step ' + '.'.join(str(x) for x in pth)
            k = step_kind(st)
            rec = {'path': pth, 'kind': k, 't0': self.T, 'moves': [], 'ops0': len(self.ops),
                   'note': []}
            self.info.append(rec)
            if k is None:
                self.err(ctx, f'a step needs exactly one of {", ".join(STEP_KINDS)}')
                rec.update(t1=self.T, state=self.snapshot(), ops1=len(self.ops))
                continue
            if self.ended:
                self.warn(ctx, 'never runs (the scene left the room / stopped before it)')
            getattr(self, 's_' + k)(st, ctx, rec, pth)
            rec.update(t1=self.T, state=self.snapshot(), ops1=len(self.ops))

    # ---- texts / flow
    def s_say(self, st, ctx, rec, pth):
        rec['text'] = st['say']
        self.text(st['say'], ctx, self.label('say'), st.get('box'))

    def s_ask(self, st, ctx, rec, pth):
        rec['text'] = st['ask']
        self.text(st['ask'], ctx, self.label('ask'), st.get('box'), choice=True)
        no, join = self.label('no'), self.label('join')
        self.op('check_and_branch', '0xC83C', '0x0001', '@' + no)
        self._branches(st.get('yes') or [], st.get('no') or [], pth + ('yes',), pth + ('no',),
                       no, join, ctx)

    def s_if(self, st, ctx, rec, pth):
        terms = st['if'] if isinstance(st['if'], list) else []
        if not terms:
            self.err(ctx, '“If” needs at least one flag')
        els, fi = self.label('else'), self.label('fi')
        self.close()
        for t in terms:
            try:
                idx = self.env.flag(t.get('flag'), ctx)
            except Exception as ex:                   # noqa: BLE001
                self.err(ctx, str(ex))
                continue
            is_ = t.get('is', 'set')
            self.op('if_flag_clear' if is_ == 'set' else 'if_flag_set', idx, '@' + els)
        self._branches(st.get('then') or [], st.get('else') or [], pth + ('then',),
                       pth + ('else',), els, fi, ctx)

    def _branches(self, a, b, pa, pb, lab_b, join, ctx):
        save = self._save()
        self.lower(a, pa)
        self.close()
        self.wait_all() if self.busy else None
        self.op('goto', '@' + join)
        sa = self._save()
        ended_a = self.ended
        self._load(save)
        self.ops.append('label:' + lab_b)
        self.lower(b, pb)
        self.close()
        self.wait_all() if self.busy else None
        self.ops.append('label:' + join)
        sb = self._save()
        # rejoin: an actor stays known only where both ways agree
        for n, act in self.acts.items():
            o = sa['acts'].get(n)
            if o is None or (o.x, o.y) != (act.x, act.y):
                act.known = False
            if o is not None and o.shown != act.shown:
                act.shown = act.shown or o.shown
        self.T = max(sa['T'], sb['T'])
        self.ended = ended_a and self.ended

    def _save(self):
        return {'acts': {n: a.copy() for n, a in self.acts.items()}, 'T': self.T,
                'box': self.box, 'busy': dict(self.busy), 'ended': self.ended}

    def _load(self, s):
        self.acts = {n: a.copy() for n, a in s['acts'].items()}
        self.T, self.box, self.busy, self.ended = s['T'], s['box'], dict(s['busy']), s['ended']

    def s_set(self, st, ctx, rec, pth, name='set_flag'):
        fl = st.get('set' if name == 'set_flag' else 'clear')
        for f in (fl if isinstance(fl, list) else [fl]):
            try:
                self.op(name, self.env.flag(f, ctx))
            except Exception as ex:                   # noqa: BLE001
                self.err(ctx, str(ex))

    def s_clear(self, st, ctx, rec, pth):
        self.s_set(st, ctx, rec, pth, 'clear_flag')

    NAMING_FRAMES = 600                 # the preview's time for the naming screen

    def s_name_hero(self, st, ctx, rec, pth):
        """S121: the naming screen for the hero (the Castle's own ops, $00 script 0
        pos 107-113: $C8F4 := 0, $C8F2 := $CA42, op $04 15). It offers the name
        the hero has — the default tiles $D3-$D6 (MILLY with the Milly hook)."""
        self.close()
        if self.busy:
            self.wait_all()
        self.op('write_ram', '0xC8F4', 0)
        self.op('write_ram2', '0xC8F2', '0xCA42')
        self.op('0x04', 15, 0)
        self.T += self.NAMING_FRAMES
        rec['note'].append('the naming screen (the player types the hero\'s name)')

    def s_end(self, st, ctx, rec, pth):
        self.close()
        self.op('goto', f'@{self.p}_done')
        self.ended = True

    def s_move(self, st, ctx, rec, pth):
        self.close()
        try:
            if (st['move'] or {}).get('dest') == 'hub':     # S125: home
                self.ops += self.env.hub_ops('home', ctx)
                rec['note'].append('to the hub (the first hub rule that holds, else the Castle)')
            else:
                self.op('map_transition', *self.env.move_words(st['move'] or {}, ctx))
        except Exception as ex:                       # noqa: BLE001
            self.err(ctx, str(ex))
        self.ended = True

    def s_heal(self, st, ctx, rec, pth):
        """S125: op $27 — every monster's HP / MP to full and its status cleared
        (bank $01 IteratePartySlots20, all 20 slots; PyBoy-measured S125)."""
        self.op('refresh_party')
        rec['note'].append('every monster: HP / MP full, status cleared')

    def s_battle(self, st, ctx, rec, pth):
        b = st['battle'] or {}
        ens = b.get('enemies') or []
        self.close()
        if self.busy:
            self.wait_all()
        if not 1 <= len(ens) <= 3:
            self.err(ctx, 'a battle has 1-3 enemies')
            return
        try:
            eids = [self.env.enemy(e, ctx) for e in ens]
        except Exception as ex:                       # noqa: BLE001
            self.err(ctx, str(ex))
            return
        if len(eids) == 1:
            self.op('trigger_battle3', eids[0])
        else:
            for j, e in enumerate(eids):
                self.op('write_ram2', f'0x{0xDA03 + 2 * j:04X}', e)
            self.op('write_ram', '0xDA02', len(eids) - 1)
            self.op('boss_battle')
        self.T += 240
        rec['note'].append('the steps after a battle run only when the player WINS')

    # ---- actors
    def s_walk(self, st, ctx, rec, pth):
        w = st['walk'] or {}
        n = self.actor(w.get('actor'), ctx)
        to = self.cell(w.get('to'), ctx)
        if n is None or to is None:
            return
        self.close()
        a = self.acts[n]
        tx, ty = cell_px(self.screen, *to)
        first = w.get('first', 'x')
        together = bool(w.get('together'))
        self._need_idle(n)
        x0, y0 = a.x, a.y
        if not a.known:
            # where the actor stands is not known here (the player who talked from
            # any side, after a branch …): walk to the ABSOLUTE pixel — exact
            # wherever he stands ($10 / $11; one actor, the scene waits)
            if together:
                self.warn(ctx, f'where {self.names.get(n, n)} stands is not known here, so '
                               'this walk is exact but the scene waits for it')
            order = ('x', 'y') if first != 'y' else ('y', 'x')
            t = self.T
            for ax in order:
                if ax == 'x':
                    self.op('0x10', n, f'0x{tx & 0xFFFF:04X}')
                else:
                    self.op('0x11', n, f'0x{ty & 0xFFFF:04X}')
            dist = abs(tx - a.x) + abs(ty - a.y)
            fr = dist * WALK_FRAMES_PER_PX
            rec['moves'].append({'actor': n, 'from': (a.x, a.y), 'to': (tx, ty), 't0': t,
                                 't1': t + fr, 'style': 'walk', 'order': order, 'exact': True})
            rec['note'].append('exact walk (the scene waits)')
            self.T += fr
            for ax in reversed(order):
                if ax == 'x' and tx != a.x:
                    a.face = 3 if tx > a.x else 1
                    break
                if ax == 'y' and ty != a.y:
                    a.face = 0 if ty > a.y else 2
                    break
            a.x, a.y, a.known = tx, ty, True
            return
        dx, dy = tx - a.x, ty - a.y
        if not dx and not dy:
            rec['note'].append('already there')
            return
        if w.get('fast'):
            self.op('begin_walk')               # $22 walk_fast — the batch runs at double speed
            self.fast = True
        if w.get('keep_facing') and not self.locked:
            self.op('lock_movement')
            self.locked = True
        sp = WALK_FRAMES_PER_PX / (2 if self.fast else 1)
        t = self.T
        if first == 'y' and dx and dy:
            self.op('npc_walk_y', n, f'0x{dy & 0xFFFF:04X}')
            self.busy[n] = t + abs(dy) * sp
            rec['moves'].append({'actor': n, 'from': (a.x, a.y), 'to': (a.x, ty), 't0': t,
                                 't1': t + abs(dy) * sp, 'style': 'walk'})
            self.wait_all()
            t = self.T
            self.op('npc_walk_x', n, f'0x{dx & 0xFFFF:04X}')
            self.busy[n] = t + abs(dx) * sp
            rec['moves'].append({'actor': n, 'from': (a.x, ty), 'to': (tx, ty), 't0': t,
                                 't1': t + abs(dx) * sp, 'style': 'walk'})
            rec['note'].append('up/down first: the scene waits between the two legs')
        else:
            if dx:
                self.op('npc_walk_x', n, f'0x{dx & 0xFFFF:04X}')
            if dy:
                self.op('npc_walk_y', n, f'0x{dy & 0xFFFF:04X}')
            mid = (tx, a.y)
            if dx:
                rec['moves'].append({'actor': n, 'from': (a.x, a.y), 'to': mid, 't0': t,
                                     't1': t + abs(dx) * sp, 'style': 'walk'})
            if dy:
                t2 = t + abs(dx) * sp
                rec['moves'].append({'actor': n, 'from': mid, 'to': (tx, ty), 't0': t2,
                                     't1': t2 + abs(dy) * sp, 'style': 'walk'})
            self.busy[n] = t + (abs(dx) + abs(dy)) * sp
        if not w.get('keep_facing'):
            if first == 'y' and dx and dy or (dx and not dy):
                a.face = 3 if dx > 0 else 1
            else:
                a.face = 0 if dy > 0 else 2
        a.x, a.y = tx, ty
        if not together:
            self.wait_all()

    def s_face(self, st, ctx, rec, pth):
        f = st['face'] or {}
        n = self.actor(f.get('actor'), ctx)
        if n is None:
            return
        a = self.acts[n]
        d = f.get('dir')
        if f.get('toward'):
            m = self.actor(f['toward'], ctx)
            if m is None:
                return
            b = self.acts[m]
            if not (a.known and b.known):
                self.err(ctx, 'where one of them stands is not known here — pick a direction')
                return
            ddx, ddy = b.x - a.x, b.y - a.y
            if not ddx and not ddy:
                self.err(ctx, 'they stand on the same tile')
                return
            d = ('right' if ddx > 0 else 'left') if abs(ddx) >= abs(ddy) else \
                ('down' if ddy > 0 else 'up')
            rec['note'].append(f'faces {d}')
        if d not in FACE_OPS:
            self.err(ctx, 'direction must be up / down / left / right')
            return
        self.close()
        self.op(FACE_OPS[d], n)
        a.face = DIRS[d]

    def _type_byte(self, n, hidden):
        nm = self.names.get(n)
        ent = self.cast.entry(nm) if nm else None
        t = entry_type_byte(ent) if ent is not None else 0
        return (t | 0x40) if hidden else (t & ~0x40 & 0x7F)

    def _place(self, n, cell, rec):
        px, py = cell_px(self.screen, *cell)
        base = NPC_SLOTS + 32 * (n - 1)
        self.op('write_ram2', f'0x{base + 0x18:04X}', f'0x{px & 0xFFFF:04X}')
        self.op('write_ram2', f'0x{base + 0x1A:04X}', f'0x{py & 0xFFFF:04X}')
        a = self.acts[n]
        rec['moves'].append({'actor': n, 'from': (px, py), 'to': (px, py), 't0': self.T,
                             't1': self.T, 'style': 'teleport'})
        a.x, a.y, a.known = px, py, True

    def s_show(self, st, ctx, rec, pth, hide=False):
        s = st['hide' if hide else 'show'] or {}
        n = self.actor(s.get('actor'), ctx)
        if n is None:
            return
        how = s.get('how', 'instant')
        self.close()
        a = self.acts[n]
        if not hide and s.get('at') is not None:
            if n == 0:
                self.err(ctx, 'the player cannot be put somewhere else — walk him there')
            else:
                c = self.cell(s['at'], ctx)
                if c is not None:
                    self._need_idle(n)
                    self._place(n, c, rec)
        if n == 0:
            if how != 'instant':
                self.err(ctx, 'the player appears / disappears instantly only (the flicker '
                              'programs are NPC programs)')
            self.op('npc_write', 0, '0xFF90', '0x0040' if hide else '0x0000')
        elif how == 'instant':
            self.op('npc_write', n, 0, f'0x{self._type_byte(n, hide):04X}')
        else:
            prog = {'flicker': 0x0D if hide else 0x08, 'spin': 0x14}.get(how)
            if prog is None or (hide and how == 'spin'):
                self.err(ctx, f'“{how}” — use instant / flicker' + ('' if hide else ' / spin'))
                return
            self._need_idle(n)
            self.op('trigger_anim', f'0x{(prog << 8) | n:04X}')
            fr = SO.PROGRAMS[prog].frames or 32
            self.busy[n] = self.T + fr
            rec['moves'].append({'actor': n, 'from': (a.x, a.y), 'to': (a.x, a.y),
                                 't0': self.T, 't1': self.T + fr,
                                 'style': 'vanish' if hide else 'appear'})
            if not s.get('together'):
                self.wait_all()
        a.shown = not hide

    def s_hide(self, st, ctx, rec, pth):
        self.s_show(st, ctx, rec, pth, hide=True)

    def s_anim(self, st, ctx, rec, pth):
        s = st['anim'] or {}
        n = self.actor(s.get('actor'), ctx)
        if n is None:
            return
        mv = ANIMS.get(s.get('move'))
        if mv is None:
            self.err(ctx, f'unknown move {s.get("move")!r}')
            return
        prog = mv[1] if n == 0 else mv[0]
        if prog is None:
            self.err(ctx, f'“{mv[2]}” is a {"NPC" if n == 0 else "player"}-only move')
            return
        self.close()
        self._need_idle(n)
        pr = SO.program(prog, n)
        self.op('trigger_anim', f'0x{(prog << 8) | n:04X}')
        a = self.acts[n]
        x1 = ((a.x & 0xFF00) | ((a.x + pr.dx) & 0xFF)) if pr.xlow else a.x + pr.dx
        y1 = a.y + pr.dy
        rec['moves'].append({'actor': n, 'from': (a.x, a.y), 'to': (x1, y1), 't0': self.T,
                             't1': self.T + pr.frames, 'style': 'jump', 'prog': prog})
        self.busy[n] = self.T + pr.frames
        a.x, a.y = x1, y1
        if (pr.dx or pr.dy) and ((x1 - 8) % 16 or (y1 - 8) % 16):
            rec['note'].append('ends between tiles')
        if not s.get('together'):
            self.wait_all()

    def s_fly(self, st, ctx, rec, pth):
        s = st['fly'] or {}
        n = self.actor(s.get('actor'), ctx)
        if n is None:
            return
        if n == 0:
            self.err(ctx, 'the flying programs are NPC programs')
            return
        d = s.get('dir', 'in_right')
        prog = FLY.get(d)
        if prog is None:
            self.err(ctx, f'direction {d!r}: in_left / in_right / off_left / off_right')
            return
        ln, cv = int(s.get('length', 3)), int(s.get('curve', 3))
        if not (1 <= ln <= 9 and 0 <= cv <= 5):
            self.err(ctx, 'length 1-9, curve 0-5')
            return
        fdx, fdy, fr = SO.FLY[(prog, ln, cv)]
        self.close()
        self._need_idle(n)
        a = self.acts[n]
        if d.startswith('in'):
            c = self.cell(s.get('to') or [a.x // 16 % 10, a.y // 16 % 8], ctx)
            if c is None:
                return
            lx, ly = cell_px(self.screen, *c)
            base = NPC_SLOTS + 32 * (n - 1)
            sx, sy = lx - fdx, ly - fdy
            self.op('write_ram2', f'0x{base + 0x18:04X}', f'0x{sx & 0xFFFF:04X}')
            self.op('write_ram2', f'0x{base + 0x1A:04X}', f'0x{sy & 0xFFFF:04X}')
            if not a.shown:
                self.op('npc_write', n, 0, f'0x{self._type_byte(n, False):04X}')
                a.shown = True
            a.x, a.y, a.known = sx, sy, True
        self.op('write_ram2', '0xD8E3', f'0x{(cv << 8) | ln:04X}')
        self.op('trigger_anim', f'0x{(prog << 8) | n:04X}')
        rec['moves'].append({'actor': n, 'from': (a.x, a.y), 'to': (a.x + fdx, a.y + fdy),
                             't0': self.T, 't1': self.T + fr, 'style': 'fly'})
        self.busy[n] = self.T + fr
        a.x, a.y = a.x + fdx, a.y + fdy
        if not s.get('together'):
            self.wait_all()

    # ---- time / sound / screen
    def s_wait(self, st, ctx, rec, pth):
        w = st['wait']
        fr = int(w.get('frames', 30) if isinstance(w, dict) else w)
        if fr <= 0:
            return
        self.close()
        left = fr
        while left > 0:
            k = min(255, left)
            self.op('long_delay', k)
            left -= k
        self.T += fr

    def s_wait_walks(self, st, ctx, rec, pth):
        self.close()
        self.wait_all()

    def s_music(self, st, ctx, rec, pth):
        m = st['music']
        if m == 'back' or (isinstance(m, dict) and m.get('back')):
            self.op('0x4B')
            return
        song = m.get('song') if isinstance(m, dict) else m
        try:
            self.op('set_bgm', F.val(song))
        except (TypeError, ValueError):
            self.err(ctx, f'song {song!r}')

    def s_sound(self, st, ctx, rec, pth):
        s = st['sound']
        sid = s.get('id') if isinstance(s, dict) else s
        try:
            self.op('0x21', F.val(sid))
        except (TypeError, ValueError):
            self.err(ctx, f'sound {sid!r}')

    def s_shake(self, st, ctx, rec, pth):
        s = st['shake'] or {}
        fr = max(1, min(255, int(s.get('frames', 30))))
        d = s.get('dir', 'both')
        if d in ('up_down', 'both'):
            self.op('write_ram', '0xC8B1', fr)
        if d in ('left_right', 'both'):
            self.op('write_ram', '0xC8B2', fr)
        if s.get('wait', True):
            self.close()
            self.op('long_delay', fr)
            self.T += fr

    def _shade(self, vals):
        for reg, v in zip(SHADE_REGS, vals):
            self.op('write_ram', f'0x{reg:04X}', f'0x{v:02X}')

    def s_fade(self, st, ctx, rec, pth):
        s = st['fade'] or {}
        step = max(1, min(255, int(s.get('step', 16))))
        self.close()
        seq = SHADE_FADE if s.get('to', 'black') == 'black' else \
            list(reversed(SHADE_FADE[:-1])) + [SHADE_NORMAL]
        for vals in seq:
            self._shade(vals)
            self.op('long_delay', step)
            self.T += step

    def s_flash(self, st, ctx, rec, pth):
        s = st['flash'] or {}
        fr = max(1, min(255, int(s.get('frames', 8) if isinstance(s, dict) else s)))
        self.close()
        self._shade((0, 0, 0))
        self.op('long_delay', fr)
        self._shade(SHADE_NORMAL)
        self.T += fr

    def s_followers(self, st, ctx, rec, pth):
        v = st['followers']
        self.op('write_ram', '0xC8ED', 14 if v == 'hide' else 0)

    def s_give_item(self, st, ctx, rec, pth, monster=False):
        g = st['give_monster' if monster else 'give_item'] or {}
        self.close()
        full, done = self.label('full'), self.label('done')
        try:
            what = self.env.enemy(g.get('enemy'), ctx) if monster else F.val(g.get('item'))
        except Exception as ex:                       # noqa: BLE001
            self.err(ctx, str(ex))
            return
        if not isinstance(what, int):
            self.err(ctx, 'pick an item' if not monster else 'pick a monster')
            return
        self.op('check_storage_full' if monster else 'check_inv_full', '@' + full)
        self.op('add_monster' if monster else 'give_item', what)
        if g.get('got'):
            self.text(g['got'], ctx, self.label('got'))
            self.close()
        self.op('goto', '@' + done)
        self.ops.append('label:' + full)
        if g.get('full'):
            self.box = False
            self.text(g['full'], ctx, self.label('fulltext'))
            self.close()
        self.ops.append('label:' + done)
        self.box = False

    def s_give_monster(self, st, ctx, rec, pth):
        self.s_give_item(st, ctx, rec, pth, monster=True)

    def s_tiles(self, st, ctx, rec, pth):
        t = st['tiles'] or {}
        c = self.cell([t.get('x'), t.get('y')], ctx)
        if c is None:
            return
        rows = tiles_rows(self.env.custom(), self.room, self.screen, t)
        if isinstance(rows, str):
            self.err(ctx, rows)
            return
        if c[0] < 0 or c[1] < 0 or c[0] + max(len(r) for r in rows) > 10 or c[1] + len(rows) > 8:
            self.err(ctx, 'the piece must lie inside the screen')
            return
        self.close()
        self.npatch = getattr(self, 'npatch', 0) + 1
        name = f'{self.p}_{self.npatch}'
        tb, ab = patch_bytes(c, rows)
        self.patches.append((name, tb, ab))
        self.op('0x24', f'patch:{name}')          # bank $60 entries 9 / 10 (S119 part d)
        self.op('0x61', f'patch:{name}_attr')
        rec['patch'] = (c, rows)

    patches = None

    # -------------------------------------------------------------- entry point
    def run(self):
        self.patches = []
        self.lower(self.scene.get('steps') or [])
        self.close()
        if self.busy or self.locked:
            self.wait_all()
        self.ops.append(f'label:{self.p}_done')
        return self.ops


# ------------------------------------------------------------------ tile patches (part d)

def _grid(v):
    if isinstance(v, str):
        import json
        return json.loads(v)
    return v


def layout_grid(custom, room, screen, state):
    """(tiles[16][20], attrs[16][20]) of a screen state of a custom room — the
    bytes the room loader writes to the BG map (measured S119: layout bytes ==
    VRAM bank 0, attr grid == VRAM bank 1), or a string saying why not."""
    lays = {l.get('id'): l for l in (custom or {}).get('layouts') or []}
    scr = (room.get('screens') or {}).get(str(screen))
    if scr is None:
        return f'the room has no screen {screen}'
    sts = scr.get('states') or []
    st = sts[state] if 0 <= state < len(sts) else {}
    lay = st.get('layout') or scr.get('layout') or {}
    if 'id' not in lay or lay['id'] not in lays or 'tiles' not in lays[lay['id']]:
        return 'that screen / state uses a layout the editor cannot read (a game layout)'
    tiles = _grid(lays[lay['id']]['tiles'])
    aref = None
    for cand in (st.get('attr'), (st.get('layout') or {}) if 'attr' in lays.get(
            (st.get('layout') or {}).get('id'), {}) else None,
                 scr.get('attr'), lay if 'attr' in lays.get(lay.get('id'), {}) else None,
                 (room.get('render') or {}).get('attr')):
        if cand and 'id' in cand and 'attr' in lays.get(cand['id'], {}):
            aref = cand['id']
            break
    attrs = _grid(lays[aref]['attr']) if aref else [[0] * 20 for _ in range(16)]
    return tiles, attrs


def tiles_rows(custom, room, screen, t):
    """The cells of a `tiles` step: rows of {'tiles': [tl, tr, bl, br], 'pal': p | [4]}
    — given (`rows`) or copied from another screen / state of the room
    (`copy`: {screen, state} — the same rectangle x, y, w, h). A string = why not."""
    if t.get('rows'):
        rows = t['rows']
        if not all(isinstance(r, list) and r for r in rows):
            return 'pick the tiles to put there'
        return rows
    cp = t.get('copy')
    if not isinstance(cp, dict):
        return 'pick the tiles to put there (or a room state to copy them from)'
    g = layout_grid(custom, room, int(cp.get('screen', screen)), int(cp.get('state', 0)))
    if isinstance(g, str):
        return g
    tiles, attrs = g
    x, y, w, h = int(t.get('x', 0)), int(t.get('y', 0)), int(t.get('w', 1)), int(t.get('h', 1))
    if w < 1 or h < 1 or x + w > 10 or y + h > 8:
        return 'the piece must lie inside the screen'
    rows = []
    for cy in range(y, y + h):
        row = []
        for cx in range(x, x + w):
            ty, tx = cy * 2, cx * 2
            row.append({'tiles': [tiles[ty][tx], tiles[ty][tx + 1], tiles[ty + 1][tx],
                                  tiles[ty + 1][tx + 1]],
                        'pal': [attrs[ty][tx], attrs[ty][tx + 1], attrs[ty + 1][tx],
                                attrs[ty + 1][tx + 1]]})
        rows.append(row)
    return rows


def patch_bytes(cell, rows):
    """-> (tile patch, colour patch) in the $24 / $61 format: offset word (8-px
    row * 32 + column from the visible top-left), the bytes of each 8-px row,
    $D8 between rows, $D9 at the end."""
    x, y = cell
    off = (y * 2) * 32 + x * 2
    tb, ab = [off & 0xFF, off >> 8], [off & 0xFF, off >> 8]
    lines_t, lines_a = [], []
    for row in rows:
        for half in (0, 1):
            lt, la = [], []
            for c in row:
                tl = [F.val(v) & 0xFF for v in c['tiles']]
                pal = c.get('pal', 0)
                pl = [F.val(v) for v in pal] if isinstance(pal, list) else [F.val(pal)] * 4
                lt += tl[half * 2: half * 2 + 2]
                la += [p & 0xFF for p in pl[half * 2: half * 2 + 2]]
            lines_t.append(lt)
            lines_a.append(la)
    for i, (lt, la) in enumerate(zip(lines_t, lines_a)):
        if i:
            tb.append(0xD8)
            ab.append(0xD8)
        tb += lt
        ab += la
    tb.append(0xD9)
    ab.append(0xD9)
    return tb, ab


# ------------------------------------------------------------------ analysis (editor)

def analyse(room, scene, custom=None, flag_names=(), enemies=()):
    """The model of one scene for the editor (the Lowerer after its run: .ops,
    .info, .errors, .warnings). Never raises."""
    env = Env(flag_names=flag_names, enemies=enemies)
    env.data_custom = custom
    lw = Lowerer(env, room, scene, 'c')
    try:
        lw.run()
    except Exception as ex:                          # noqa: BLE001
        lw.errors.append(f'{type(ex).__name__}: {ex}')
    lw.errors += trigger_problems(room, scene)
    return lw


def trigger_problems(room, scene):
    out = []
    tr = scene.get('trigger') or {}
    on = tr.get('on', 'entry')
    scr = scene.get('screen', 0)
    if str(scr) not in {str(k) for k in (room.get('screens') or {})}:
        out.append(f'the room has no screen {scr}')
        return out
    if on not in TRIGGERS:
        out.append(f'trigger {on!r}: entry / talk / examine / stepon')
    arr = tr.get('arrival')
    if arr:
        if on != 'entry':
            out.append('“arrival” reasons belong to an arrival (entry) scene')
        bad = [a for a in (arr if isinstance(arr, list) else [arr]) if a not in ARRIVALS]
        if bad or not isinstance(arr, list):
            out.append(f'arrival reasons {bad or arr}: pick from {", ".join(ARRIVALS)}')
    if on == 'talk':
        cast = Cast(room, scr)
        n, prob = cast.slot(tr.get('actor') or '')
        if n is None:
            out.append('talk trigger: ' + (prob or 'pick the NPC'))
        elif n == 0:
            out.append('talk trigger: pick an NPC (not the player)')
        elif not cast.shown(tr.get('actor')):
            out.append(f'talk trigger: “{tr.get("actor")}” is hidden in the room — '
                       'nobody can talk to it')
    if on in ('examine', 'stepon'):
        try:
            x, y = int(tr['x']), int(tr['y'])
            if not (0 <= x <= 9 and 0 <= y <= 7):
                out.append('the spot must be on the screen')
        except (KeyError, TypeError, ValueError):
            out.append(f'{on} trigger: pick the cell')
    return out


# ------------------------------------------------------------------ the compiler pass

def _prefix_ops(ops, pre):
    """Copy an op list with its labels renamed (inlined into a combined script)."""
    out = []
    for it in ops:
        if isinstance(it, str):
            out.append('label:' + pre + it.split(':', 1)[1] if it.startswith('label:') else it)
            continue
        row = list(it)
        if row and row[0] == 'op':
            row = row[:2] + [('@' + pre + p[1:]) if isinstance(p, str) and p.startswith('@')
                             else p for p in row[2:]]
        out.append(row)
    return out


def _sid(s):
    return ''.join(ch if ch.isalnum() else '_' for ch in str(s))


def lower_project(prj):
    """Project pass (called by Project.__init__ after the helper scripts are
    lowered): every room's cutscenes become ordinary scripts, wired to their
    triggers. Mutates the project's (copied) data: custom.scripts gets the
    combined trigger scripts, rooms' script tables / NPC script ids / spot
    entries point at them, custom.dialogue gets the inline texts. Returns the
    tile patches [(label, room, screen, cell, rows)] for the bank $60 emitter."""
    patches = []
    custom = prj.custom
    scripts = custom.setdefault('scripts', [])
    by_id = {s.get('id'): s for s in scripts}
    try:
        hubs = prj.hub_room_ids() if hasattr(prj, 'hub_room_ids') else set()
    except Exception as ex:                          # noqa: BLE001 (a ProjectError)
        raise CutsceneError(str(ex))                 # recorded, the editor still opens
    for r in prj.rooms:
        if r.get('placeholder') or not (r.get('cutscenes') or r.get('id') in hubs):
            continue
        rid = r.get('id')
        seen = set()
        groups = {}                  # target key -> [(scene, lowered ops)]
        for k, sc in enumerate(r.get('cutscenes') or []):
            ctx = f"rooms[{rid}].cutscenes[{sc.get('id', k)}]"
            if not sc.get('id') or sc['id'] in seen:
                raise CutsceneError(f'{ctx}: every cutscene needs its own id')
            seen.add(sc['id'])
            if sc.get('disabled'):
                continue
            probs = trigger_problems(r, sc)
            if probs:
                raise CutsceneError(f'{ctx}: ' + '; '.join(probs))
            env = Env(prj, strict=True)
            lw = Lowerer(env, r, sc, scene_prefix(sc))
            try:
                body = lw.run()
            except CutsceneError as ex:
                raise CutsceneError(f'{ctx}: {ex}')
            custom.setdefault('dialogue', []).extend(env.dialogue)
            pd = r.setdefault('patch_data', {})
            for name, tb, ab in lw.patches:
                pd[name] = tb
                pd[name + '_attr'] = ab
                patches.append((name, r))
            groups.setdefault(trigger_key(sc), []).append((sc, body, lw))
        hub = rid in hubs
        if hub:
            # S125: a hub room always has an arrival script: the arrival scenes go
            # first (the Milly hook's spin-in before them), and a reason no scene
            # took gets the default welcome — the party healed — below
            groups.setdefault(('entry',), []).sort(
                key=lambda it: 0 if it[0].get('_then_next') else
                1 if (it[0].get('trigger') or {}).get('arrival') else 2)
        table = r.setdefault('scripts', {})
        for key, items in groups.items():
            tag = '_'.join(_sid(x) for x in key)
            gid = f'cut:{rid}:{tag}'
            ops = hub_reveal_ops() if hub and key[0] == 'entry' else []
            pending = hub and key[0] == 'entry'
            for sc, body, lw in items:
                if pending and not sc.get('_then_next') and not (
                        sc.get('trigger') or {}).get('arrival'):
                    # S125: a reason no arrival scene took is healed BEFORE the room's
                    # other entry scenes (one of them may warp away)
                    ops += hub_default_ops()
                    pending = False
                ops += _guard(prj, sc, lw.p, multi_screen=len(prj.room_screens(r)) > 1
                              and key[0] == 'entry')
                ops += body
                # the end of a scene: an entry scene goes on into the room's own
                # arrival script; a talk / spot scene ends there
                if sc.get('_then_next') and key[0] == 'entry':
                    pass        # S121: the Milly hook's arrival scene goes on into
                                # the room's own entry scenes (milly.lower)
                else:
                    ops.append(['op', 'goto', '@cut_orig'] if key[0] == 'entry' else ['end'])
                ops.append(f'label:{lw.p}_skip')
            orig = _original_ops(prj, r, key, by_id)
            if pending:
                ops += hub_default_ops()
            ops.append('label:cut_orig')
            ops += _prefix_ops(orig, 'o_') if orig else [['end']]
            new = {'id': gid, 'ops': ops, 'comment': f'cutscenes {[s["id"] for s, _b, _l in items]}'}
            scripts.append(new)
            by_id[gid] = new
            if key[0] == 'entry':
                table['0'] = gid
            else:
                idx = max([int(i) for i in table] + [0]) + 1
                table[str(idx)] = gid
                _wire(r, key, gid, idx)
    return patches


def hub_reveal_ops():
    """S125: first thing in a hub room's arrival script. The WarpWing's own exit
    (bank $07, after HubWarp) sets $C8EC = 1 (every field sprite hidden) and leaves
    the clearing to the Castle's arrival code — elsewhere the player, the monsters
    and the NPCs stayed invisible (PyBoy-measured S125). A WarpWing arrival shows
    them again."""
    w = f'0x{W_HUB_REASON:04X}'
    return [['op', 'check_and_branch', w, ARRIVAL_NUM['warpwing'], '@hub_ww'],
            ['op', 'goto', '@hub_go'], 'label:hub_ww',
            ['op', 'write_ram', '0xC8EC', 0], 'label:hub_go']


def hub_default_ops():
    """S125: a hub room's arrival for a reason no arrival scene took: the party
    healed (the vanilla Castle's priest heals too), the reason taken."""
    w = f'0x{W_HUB_REASON:04X}'
    return [['op', 'check_and_branch', w, 0, '@hub_none'],
            ['op', 'refresh_party'], ['op', 'write_ram', w, 0], 'label:hub_none']


def trigger_key(sc):
    """The trigger a scene hangs on: ('entry',) | ('talk', screen, actor) |
    (examine|stepon, screen, x, y) — scenes with the same key share one script."""
    tr = sc.get('trigger') or {}
    on = tr.get('on', 'entry')
    if on == 'entry':
        return ('entry',)
    if on == 'talk':
        return ('talk', int(sc.get('screen', 0)), tr.get('actor'))
    return (on, int(sc.get('screen', 0)), int(tr.get('x', 0)), int(tr.get('y', 0)))


def scene_prefix(sc):
    return f'cs_{_sid(sc["id"])}'


def trigger_script_id(room, sc):
    return f"cut:{room.get('id')}:" + '_'.join(_sid(x) for x in trigger_key(sc))


def _guard(prj, sc, p, multi_screen):
    tr = sc.get('trigger') or {}
    ctx = f"cutscene {sc.get('id')}"
    ops = []
    if multi_screen:
        ops += [['op', 'branch_screen', int(sc.get('screen', 0)), f'@{p}_go'],
                ['op', 'goto', f'@{p}_skip'], f'label:{p}_go']
    for f in tr.get('when_on') or []:
        ops.append(['op', 'if_flag_clear', prj.resolve_flag_ref(f, ctx), f'@{p}_skip'])
    for f in tr.get('when_off') or []:
        ops.append(['op', 'if_flag_set', prj.resolve_flag_ref(f, ctx), f'@{p}_skip'])
    if tr.get('arrival'):
        # S125: only when the player was just sent to the hub for one of these
        # reasons; the scene takes the reason (wHubReason := 0) so a reload of the
        # room (scroll back, after a battle) does not play it again
        for a in tr['arrival']:
            ops.append(['op', 'check_and_branch', f'0x{W_HUB_REASON:04X}',
                        ARRIVAL_NUM[a], f'@{p}_arr'])
        ops += [['op', 'goto', f'@{p}_skip'], f'label:{p}_arr']
    if tr.get('once'):
        idx = prj.resolve_flag_ref(tr['once'], ctx)
        ops += [['op', 'if_flag_set', idx, f'@{p}_skip'], ['op', 'set_flag', idx]]
    if tr.get('arrival'):
        # taken only once every guard has passed (S125 review: a `once` scene that
        # skips must leave the reason to the default heal)
        ops.append(['op', 'write_ram', f'0x{W_HUB_REASON:04X}', 0])
    return ops


def _original_ops(prj, r, key, by_id):
    """The ops the trigger ran before the cutscenes (inlined after them)."""
    table = r.get('scripts') or {}
    sid = None
    if key[0] == 'entry':
        sid = table.get('0')
    elif key[0] == 'talk':
        cast = Cast(r, key[1])
        ent = cast.entry(key[2])
        if ent is not None:
            sid = _entry_script(ent, table)
    else:
        for lst in screen_npc_lists(r, key[1]):
            for e in lst:
                if not is_npc_entry(e) and _spot_cell(e) == (key[2], key[3]) and \
                        _spot_kind(e) == key[0]:
                    sid = _entry_script(e, table)
                    break
            if sid is not None:
                break
    if sid is None:
        return None
    s = by_id.get(sid)
    if s is None:
        return None
    if 'ops' not in s:
        raise CutsceneError(f"room {r.get('id')}: the script {sid!r} under a cutscene trigger "
                            "is not lowered yet")
    return copy.deepcopy(s['ops'])


def _entry_script(e, table):
    if e.get('kind') == 'raw':
        i = F.val(e['bytes'][4])
        return None if i == 0xFF else table.get(str(i))
    s = e.get('script')
    if s in (None, 'none'):
        return None
    if isinstance(s, int):
        return table.get(str(s))
    return s


def _spot_cell(e):
    if e.get('kind') == 'raw':
        return F.val(e['bytes'][2]), F.val(e['bytes'][3])
    return int(e.get('x', -1)), int(e.get('y', -1))


def _spot_kind(e):
    k = e.get('kind')
    if k == 'raw':
        return 'stepon' if F.val(e['bytes'][0]) & 0xF0 == 0x90 else 'examine'
    return {'step': 'stepon', 'examine': 'examine', 'spawn': 'examine'}.get(k)


def _wire(r, key, gid, idx):
    """Point the trigger (the named NPC / the spot) at the combined script."""
    scr = (r.get('screens') or {}).get(str(key[1]))
    states = scr.get('states') or [scr]
    for st in states:
        lst = st.setdefault('npcs', [])
        found = False
        for e in lst:
            if key[0] == 'talk':
                hit = is_npc_entry(e) and e.get('actor') == key[2]
            else:
                hit = (not is_npc_entry(e) and _spot_cell(e) == (key[2], key[3])
                       and _spot_kind(e) == key[0])
            if not hit:
                continue
            found = True
            if e.get('kind') == 'raw':
                e['bytes'] = list(e['bytes'])
                e['bytes'][4] = f'0x{idx:02X}'
            else:
                e['script'] = gid
        if not found and key[0] in ('examine', 'stepon'):
            spot = {'kind': 'examine' if key[0] == 'examine' else 'step',
                    'x': key[2], 'y': key[3], 'script': gid,
                    'comment': 'cutscene spot (S119)'}
            if key[0] == 'examine':
                spot['facing'] = 'any'
            lst.insert(0, spot)


# ------------------------------------------------------------------ editor helpers

def new_scene(room, scene_id, screen=0, on='entry'):
    return {'id': scene_id, 'name': scene_id.replace('_', ' '), 'screen': int(screen),
            'trigger': {'on': on}, 'steps': []}


def walk_steps(steps, path=()):
    """Yield (path, step) over a step tree (branches included)."""
    for i, st in enumerate(steps or []):
        p = path + (i,)
        yield p, st
        k = step_kind(st)
        if k == 'ask':
            yield from walk_steps(st.get('yes'), p + ('yes',))
            yield from walk_steps(st.get('no'), p + ('no',))
        elif k == 'if':
            yield from walk_steps(st.get('then'), p + ('then',))
            yield from walk_steps(st.get('else'), p + ('else',))


def describe(st, names=None):
    """One readable line for a step."""
    k = step_kind(st)
    if k is None:
        return '(empty step)'
    v = st[k]
    nm = (lambda a: 'the player' if a == PLAYER else (a or '?'))

    def txt(t):
        if isinstance(t, dict) and t.get('boxes'):
            s = ' '.join(' '.join(b) for b in t['boxes'])
            return f'“{s[:50]}”'
        return f'text {t}'
    if k == 'say':
        return f'Say {txt(v)}' + (f' (box at the {st["box"]})' if st.get('box') in ('top', 'bottom') else '')
    if k == 'ask':
        return f'Ask {txt(v)}'
    if k == 'if':
        terms = ', '.join(f"{t.get('flag')} {t.get('is', 'set')}" for t in v or [])
        return f'If {terms}'
    if k in ('set', 'clear'):
        return f'Turn {"ON" if k == "set" else "OFF"}: ' + ', '.join(str(f) for f in (v if isinstance(v, list) else [v]))
    if k == 'walk':
        to = v.get('to') or ['?', '?']
        extra = []
        if v.get('first') == 'y':
            extra.append('up/down first')
        if v.get('together'):
            extra.append('with the next step')
        if v.get('fast'):
            extra.append('running')
        if v.get('keep_facing'):
            extra.append('backwards')
        return f'{nm(v.get("actor"))} walks to ({to[0]}, {to[1]})' + (f' — {", ".join(extra)}' if extra else '')
    if k == 'face':
        if v.get('toward'):
            return f'{nm(v.get("actor"))} turns to {nm(v["toward"])}'
        return f'{nm(v.get("actor"))} faces {v.get("dir", "?")}'
    if k in ('show', 'hide'):
        how = v.get('how', 'instant')
        at = f' at ({v["at"][0]}, {v["at"][1]})' if v.get('at') else ''
        return f'{nm(v.get("actor"))} {"appears" if k == "show" else "disappears"}{at}' + \
            ('' if how == 'instant' else f' ({how})')
    if k == 'anim':
        a = ANIMS.get(v.get('move'))
        return f'{nm(v.get("actor"))}: {a[2] if a else v.get("move")}'
    if k == 'fly':
        to = f' to ({v["to"][0]}, {v["to"][1]})' if v.get('to') and str(v.get('dir', '')).startswith('in') else ''
        return f'{nm(v.get("actor"))} {FLY_NAMES.get(v.get("dir"), "flies")}{to}'
    if k == 'wait':
        fr = v.get('frames', 30) if isinstance(v, dict) else v
        return f'Wait {fr} frames ({fr / 60:.1f} s)'
    if k == 'wait_walks':
        return 'Wait until everyone stops'
    if k == 'music':
        return 'Music back to the room\'s song' if v == 'back' else f'Music ${F.val(v.get("song") if isinstance(v, dict) else v):02X}'
    if k == 'sound':
        return f'Sound effect ${F.val(v.get("id") if isinstance(v, dict) else v):02X}'
    if k == 'shake':
        return f'Shake the screen ({v.get("dir", "both").replace("_", "-")}, {v.get("frames", 30)} frames)'
    if k == 'fade':
        return 'Fade to black' if v.get('to', 'black') == 'black' else 'Fade back in'
    if k == 'flash':
        return 'Flash'
    if k == 'followers':
        return f'{"Hide" if v == "hide" else "Show"} the monsters following the player'
    if k == 'give_item':
        return f'Give item {v.get("item")}'
    if k == 'give_monster':
        return f'Give monster {v.get("enemy")}'
    if k == 'tiles':
        rows = v.get('rows') or []
        w = max((len(r) for r in rows), default=0)
        return f'Change a {w}×{len(rows)}-tile piece at ({v.get("x")}, {v.get("y")})'
    if k == 'battle':
        return 'Battle: ' + ', '.join(str(e) for e in (v or {}).get('enemies') or [])
    if k == 'move':
        if v.get('dest') == 'hub':
            return 'Send the player home (the hub)'
        return f'Warp the player to {v.get("dest")} screen {v.get("screen", 0)} ({v.get("x")}, {v.get("y")})'
    if k == 'heal':
        return 'Heal the party (HP / MP full, status cleared)'
    if k == 'end':
        return 'Stop here'
    if k == 'name_hero':
        return 'Name the hero (the naming screen)'
    return k
