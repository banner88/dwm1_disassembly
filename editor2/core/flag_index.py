"""flag_index.py — every flag of a project and every place that touches it
(S124, ROADMAP P3.14a — the Progression & Flags tab).

Headless (no Qt). Built from the project's JSON (what the author wrote — so a
use knows WHERE it was authored, in words, and the JSON PATH of the reference,
for Rename) plus, optionally, the original game's scripts (cutscenes.Catalogue)
and the few engine routines that set or test flags themselves.

A **Use** is one place that turns a flag ON, turns it OFF, or tests it:

    Use(idx, ref, role 'on'|'off'|'test', want 'set'|'clear' (tests),
        kind, where, what, nav, source 'project'|'engine'|'game', path, trigger)

A **Trigger** is one "when these flags … → this changes" of the project (a room
state rule, an NPC shown / coloured by flags, battles by flags, a gate-floor
room rule, a cutscene's start conditions, a conversation's or a cutscene's
If, a copied game script's branch); each of its flag terms is a test Use.

Where the compiler resolves a flag reference — Project.resolve_flag_ref /
Project._flag_index — this module walks the same JSON keys (the sites are
listed in KINDS below; test_compiler `test_flag_index_s124` checks that every
reference the compiler resolves and every flag op of the lowered scripts is
found here, so a new site cannot be forgotten silently).

    python3 -m editor2.core.flag_index path/to/project.json [--rom ROM]
"""

import os
import sys
from dataclasses import dataclass, field

from . import formats as F
from . import gates as G
from .project import (GAME_SHARED_FLAGS, GATE_FLAG_BASE, flag_index_ok, flag_persistent,
                      number_flags, quest_flag_entries)

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

ON, OFF, TEST = 'on', 'off', 'test'

# kind -> what the author calls it (the Triggers list's "Kind" column)
KINDS = {
    'talk': 'talk',                     # scripts[].talk then / yes / no .set / .clear
    'conversation': 'conversation',     # scripts[].talk.steps (if / set / clear, nested)
    'script': 'script',                 # scripts[].ops raw flag ops (copied game scripts)
    'prelude': 'script',                # custom.script_preludes raw ops
    'cutscene_start': 'cutscene start', # rooms[].cutscenes[].trigger when_on / when_off / once
    'cutscene': 'cutscene',             # rooms[].cutscenes[].steps (if / set / clear, nested)
    'state_rule': 'room state',         # rooms[].state_rules[].when
    'npc_shown': 'NPC shown',           # NPC entries' shown_when
    'npc_colour': 'NPC colour',         # NPC entries' colour.when
    'swirl': 'portal swirl',            # NPC entries' swirl_of: N (gate:N cleared)
    'room_battles': 'battles',          # rooms[].encounters.variants[].when
    'gate_battles': 'battles',          # gates[].encounters.variants[].when
    'gate_room': 'gate floor room',     # custom.gate_inserts[].when
    'hub': 'hub',                       # custom.hub.rules[].when (S125)
    'quest': 'quest',                   # progression.quests[] flags / actions
    'gate_win': 'boss win',             # engine: bank $76 GateBossWin
    'hook': 'Milly hook',               # the Milly hook's own flags
    'game': 'game script',              # the original game's scripts (read-only)
    'game_engine': 'game code',         # the original game's code (read-only)
}

FLAG_OPS = {0x00: (TEST, 'clear'), 0x01: (TEST, 'set'), 0x02: (OFF, None), 0x03: (ON, None)}
OP_NAMES = {'if_flag_clear': 0x00, 'if_flag_set': 0x01, 'clear_flag': 0x02, 'set_flag': 0x03}

# The original game's code that sets / tests flags itself (S124, code-read — EVENT_FLAGS
# "Engine-side flag setters"): bank $12 Pulio's farm menu ($4EE1) sets $0007 when a monster
# is taken into an EMPTY party; bank $12 $6C4B-$6C78 (the medal man) sets $0050 + the
# number of eggs already given ($D9E1, 0-7); bank $09 the gate keeper's list (screen 13)
# tests the 16 unlock flags at $09:$609E and the 16 cleared flags at $09:$607E.
GAME_ENGINE_ON = {0x0007: 'Pulio\'s farm menu: taking a monster into an empty party '
                          '(the game\'s code, bank $12)'}
for _n in range(8):
    GAME_ENGINE_ON[0x0050 + _n] = (f'the medal man\'s egg reward no. {_n + 1} (the game\'s '
                                   'code, bank $12)')
GATE_LIST_UNLOCK = (0x09, 0x609E)
GATE_LIST_CLEARED = (0x09, 0x607E)


def _cell(x, y):
    return f'({x}, {y})'


def flag_number(idx):
    return f'${idx:04X}'


# ---------------------------------------------------------------------------
@dataclass
class Trigger:
    kind: str
    terms: list                  # [(ref, want 'set'|'clear', idx or None)]
    event: str                   # '' or "you enter Room · screen 0" …
    then: str                    # what changes
    where: str
    nav: dict = None
    source: str = 'project'

    def sentence(self, name_of):
        conds = ' and '.join(f"{name_of(r, i)} is {'ON' if w == 'set' else 'OFF'}"
                             for r, w, i in self.terms)
        head = self.event + (' and ' if self.event and conds else '') + conds
        return f'When {head} → {self.then}'


@dataclass
class Use:
    idx: object                  # int, or None when the reference does not resolve
    ref: object                  # as authored
    role: str                    # on / off / test
    want: str = None             # tests: 'set' / 'clear'
    kind: str = ''
    where: str = ''
    what: str = ''
    nav: dict = None
    source: str = 'project'
    path: tuple = None           # JSON path of the authored reference (None = not renamable)
    trigger: Trigger = None
    runs: bool = True            # False: its script is used by no room (never runs)
    who: str = ''                # S124 r2: who / what runs it ("talking to Santi at (1, 6)")
    when: str = ''               # S124 r2: the deciding condition on its path ("arena class S won")
    group: tuple = None          # S124 r2: uses of one script / place are shown together
    places: list = None          # S124 r3: every place it happens (nav dicts: room / screen /
                                 # state / cell / NPC number) — the side panel steps through them


@dataclass
class FlagInfo:
    idx: int
    kind: str                    # project / quest / gate / hook / game
    name: str                    # project name, or a label
    label: str = ''              # what it means (game flags: from the game's data)
    comment: str = ''
    entry: dict = None           # the custom.flags entry (project flags)
    uses: list = field(default_factory=list)

    def by_role(self, role, source=None):
        return [u for u in self.uses if u.role == role and
                (source is None or u.source in (source if isinstance(source, tuple)
                                                else (source,)))]


@dataclass
class Problem:
    level: str                   # error / warn / info
    code: str
    idx: object
    text: str
    uses: list = field(default_factory=list)


# ---------------------------------------------------------------------------
class Place:
    """Where a script runs: an NPC / spot of a room screen state, or the room's
    entry (script index 0)."""

    def __init__(self, room, ri, k, si, nstates, kind, x=None, y=None, actor=None, n=None):
        self.room, self.ri, self.k, self.si = room, ri, k, si
        self.nstates, self.kind, self.x, self.y, self.actor = nstates, kind, x, y, actor
        self.n = n                     # S124 r3: NPC number (1-based, spots not counted)

    @property
    def room_name(self):
        return self.room.get('name') or self.room.get('id', '?')

    def room_text(self):
        t = f'{self.room_name}'
        if self.k is not None:
            t += f' · screen {self.k}'
            if self.nstates and self.nstates > 1:
                t += f' · state {self.si}'
        return t

    def thing(self):
        if self.kind == 'npc':
            if self.actor:
                return f'{self.actor} at {_cell(self.x, self.y)}'
            return f'the NPC at {_cell(self.x, self.y)}'
        if self.kind == 'examine':
            return f'the examine spot at {_cell(self.x, self.y)}'
        if self.kind == 'stepon':
            return f'the step-on spot at {_cell(self.x, self.y)}'
        return 'the room'

    def event(self):
        if self.kind == 'npc':
            # S124 r3: the NPC's name (its `actor`) when it has one
            return f'talking to {self.actor or "the NPC"} at {_cell(self.x, self.y)}'
        if self.kind == 'examine':
            return f'examining {_cell(self.x, self.y)}'
        if self.kind == 'stepon':
            return f'stepping on {_cell(self.x, self.y)}'
        return 'entering the room'

    def nav(self):
        return {'tab': 'rooms', 'room': self.room.get('id'),
                'screen': int(self.k) if self.k is not None else None,
                'state': self.si or 0, 'x': self.x, 'y': self.y,
                'n': self.n if self.kind == 'npc' else None, 'who': self.event()}


def _places_where(places, limit=2):
    """S124 r2: the rooms (· screen · state) a script runs in — who runs it is `who`."""
    if not places:
        return 'no room uses this script — it never runs'
    seen = []
    for p in places:
        t = p.room_text()
        if t not in seen:
            seen.append(t)
    more = len(seen) - limit
    return '; '.join(seen[:limit]) + (f' (and {more} more)' if more > 0 else '')


def _places_text(places, limit=2):
    if not places:
        return 'no room uses this script — it never runs'
    parts = [f'{p.event()} — {p.room_text()}' for p in places[:limit]]
    more = len(places) - limit
    return '; '.join(parts) + (f' (and {more} more)' if more > 0 else '')


# ---------------------------------------------------------------------------
class FlagIndex:
    """The flags of one project (+ the original game's, given a Catalogue)."""

    def __init__(self, data, repo=None, catalogue=None, rom=None):
        self.data = data
        self.custom = data.get('custom') or {}
        self.progression = data.get('progression') or {}
        self.repo = repo or REPO
        self.uses = []
        self.triggers = []
        self._cur_places = None          # S124 r3: the places of the script being walked
        self._dlg = {d.get('id'): d for d in self.custom.get('dialogue') or []}
        self.catalogue = catalogue
        self._numbers()
        self._bind()
        self._walk_scripts()
        self._walk_rooms()
        self._walk_gates()
        self._walk_gate_rooms()
        self._walk_hub()
        self._walk_quests()
        self._walk_preludes()
        self._engine()
        self._hook()
        if catalogue is not None:
            self._game(catalogue)
        if rom is not None or catalogue is not None:
            self._game_engine(rom if rom is not None else catalogue.rom)
        self._collect()

    # ------------------------------------------------------------ numbering
    def _numbers(self):
        """name -> number, exactly as the compiler numbers them (project.number_flags)."""
        decl = list(self.custom.get('flags') or [])
        implicit = quest_flag_entries(self.custom, self.progression)
        try:
            nums = number_flags(decl + implicit)
        except (ValueError, TypeError):
            nums = [None] * (len(decl) + len(implicit))
        self.named = {}
        self.entries = {}
        for i, (fl, n) in enumerate(zip(decl + implicit, nums)):
            nm = fl.get('name')
            if nm is None:
                continue
            self.named[nm] = n
            self.entries[nm] = (fl if i < len(decl) else None, fl.get('comment', ''),
                                i < len(decl))

    def resolve(self, ref):
        """A flag reference -> its number, or None (what the compiler would refuse)."""
        if isinstance(ref, str):
            if ref in self.named:
                return self.named[ref]
            if ref.startswith('hook:'):
                from . import milly as MH
                return MH.FLAG_REFS.get(ref)
            if ref.startswith('gate:'):
                gid = G.parse_gate_ref(ref)
                if gid is None:
                    return None
                try:
                    info = G.gate_cleared(self.custom, gid, self.repo)
                except Exception:                                # noqa: BLE001
                    info = None
                return info['flag'] if info else None
        try:
            v = F.val(ref)
        except (TypeError, ValueError):
            return None
        return v if isinstance(v, int) and flag_index_ok(v) else None

    def name_of(self, ref, idx=None):
        """How a reference reads in a sentence."""
        if isinstance(ref, str) and ref in self.named:
            return ref
        if isinstance(ref, str) and ref.startswith('gate:'):
            gid = G.parse_gate_ref(ref)
            return self.gate_label(gid) if gid is not None else str(ref)
        if isinstance(ref, str) and ref.startswith('hook:'):
            return {'hook:milly': '“the player is Milly”',
                    'hook:milly_arrived': '“Milly has arrived”'}.get(ref, ref)
        i = idx if idx is not None else self.resolve(ref)
        if isinstance(i, int):
            for nm, n in self.named.items():
                if n == i:
                    return nm
            cat = getattr(self, 'catalogue', None)
            if cat is not None:
                try:
                    d = cat.flag_desc(i)
                except Exception:                                # noqa: BLE001
                    d = ''
                if d and not d.startswith(('set in', 'never set')):
                    # a name the game's data gives (arena classes, gates cleared…)
                    return f'“{d}” ({flag_number(i)})'
            return f'game flag {flag_number(i)}'
        return f'“{ref}” (no such flag)'

    def gate_label(self, gid):
        try:
            nm = G.gate_name(self.custom, gid, self.repo)
        except Exception:                                        # noqa: BLE001
            nm = f'gate {gid}'
        w = 'world' if gid in self._worlds() else 'gate'
        return f'“{nm} cleared” ({w} {gid})'

    def _worlds(self):
        if not hasattr(self, '_world_ids'):
            try:
                self._world_ids = set(G.world_gates(self.custom))
            except Exception:                                    # noqa: BLE001
                self._world_ids = set()
        return self._world_ids

    # ------------------------------------------------------------- text helpers
    def text_of(self, t, n=34):
        """The first words of a TEXT (a dialogue id or an inline {boxes})."""
        s = ''
        if isinstance(t, dict):
            s = ' '.join(' '.join(b) for b in t.get('boxes') or [])
        elif isinstance(t, str):
            d = self._dlg.get(t)
            if d is None:
                s = t
            elif d.get('boxes'):
                s = ' '.join(' '.join(b) for b in d['boxes'])
            elif d.get('lines'):
                s = ' '.join(d['lines'])
            else:
                s = str(d.get('text', ''))
        s = ' '.join(s.split())
        if s.startswith('*:'):
            s = s[2:].strip()
        return '«' + (s[:n] + '…' if len(s) > n else s) + '»'

    def brief(self, steps, limit=3):
        """A few words for a list of conversation / cutscene steps."""
        out = []
        for st in steps or []:
            if not isinstance(st, dict):
                continue
            if 'say' in st:
                out.append('says ' + self.text_of(st['say'] if not isinstance(st['say'], dict)
                                                  or 'boxes' in st['say']
                                                  else st['say'].get('text', '')))
            elif 'ask' in st:
                out.append('asks ' + self.text_of(st['ask'] if not isinstance(st['ask'], dict)
                                                  or 'boxes' in st['ask']
                                                  else st['ask'].get('text', '')))
            elif 'set' in st or 'clear' in st:
                k = 'set' if 'set' in st else 'clear'
                fl = st[k] if isinstance(st[k], list) else [st[k]]
                out.append(f"turns {', '.join(self.name_of(f) for f in fl)} "
                           f"{'ON' if k == 'set' else 'OFF'}")
            elif 'battle' in st:
                out.append('a battle')
            elif 'if' in st:
                out.append('checks flags')
            elif 'move' in st or 'helper' in st:
                out.append('the player is taken away')
            elif 'vanish' in st or 'hide' in st:
                out.append('someone disappears')
            elif 'show' in st:
                out.append('someone appears')
            elif 'give_item' in st:
                out.append('gives an item')
            elif 'give_monster' in st:
                out.append('gives a monster')
            elif 'end' in st:
                out.append('stops')
            if len(out) >= limit:
                break
        return ', '.join(out) if out else 'nothing'

    # ------------------------------------------------------------- bindings
    def _bind(self):
        """script id -> [Place] (who runs it)."""
        from . import cutscene_build as CB
        self.binds = {}
        self.rooms = list(self.custom.get('rooms') or [])
        for ri, r in enumerate(self.rooms):
            table = {str(k): v for k, v in (r.get('scripts') or {}).items()}
            if '0' in table:
                self.binds.setdefault(table['0'], []).append(
                    Place(r, ri, None, 0, 0, 'entry'))
            for k, scr in (r.get('screens') or {}).items():
                states = scr.get('states') or [scr]
                for si, st in enumerate(states):
                    nn = 0
                    for e in st.get('npcs') or []:
                        if CB.is_npc_entry(e):
                            nn += 1
                        try:
                            sid = CB._entry_script(e, table)
                        except Exception:                        # noqa: BLE001
                            sid = None
                        if not sid:
                            continue
                        kind = 'npc'
                        if e.get('kind') in ('examine', 'step', 'spawn') or (
                                e.get('kind') == 'raw' and F.val(e['bytes'][0]) >= 0x80):
                            kind = CB._spot_kind(e)
                        x, y = CB._spot_cell(e) if kind != 'npc' or e.get('kind') == 'raw' \
                            else (e.get('x'), e.get('y'))
                        if e.get('kind') == 'raw' and kind == 'npc':
                            x, y = F.val(e['bytes'][2]), F.val(e['bytes'][3])
                        self.binds.setdefault(sid, []).append(
                            Place(r, ri, k, si, len(states), kind, x, y, e.get('actor'),
                                  nn if kind == 'npc' else None))

    # ------------------------------------------------------------- recording
    def _use(self, ref, role, kind, where, what='', nav=None, path=None, want=None,
             trigger=None, source='project', runs=True, idx=None):
        if idx is None:
            idx = self.resolve(ref)
        u = Use(idx, ref, role, want, kind, where, what, nav, source, path, trigger, runs)
        u.places = list(self._cur_places) if self._cur_places else ([nav] if nav else [])
        self.uses.append(u)
        return u

    def _trigger(self, kind, terms, event, then, where, nav, paths, source='project',
                 runs=True):
        """terms [(ref, want)], paths [JSON path or None] (one per term)."""
        res = [(r, w, self.resolve(r)) for r, w in terms]
        t = Trigger(kind, res, event, then, where, nav, source)
        self.triggers.append(t)
        for (r, w, i), p in zip(res, paths):
            self._use(r, TEST, kind, where, then, nav, p, w, t, source, runs, idx=i)
        return t

    # ------------------------------------------------------------- scripts
    def _walk_scripts(self):
        for si_, s in enumerate(self.custom.get('scripts') or []):
            sid = s.get('id')
            places = self.binds.get(sid, [])
            self._cur_places = [p.nav() for p in places]
            runs = bool(places)
            where = _places_where(places)
            nav = places[0].nav() if places else None
            base = ('custom', 'scripts', si_)
            t = s.get('talk')
            if isinstance(t, dict) and 'steps' in t:
                ev = places[0].event() if places else f'the conversation {sid}'
                self._walk_steps(t['steps'], base + ('talk', 'steps'), [], 'conversation',
                                 ev, where, nav, runs)
            elif isinstance(t, dict):
                ev = places[0].event() if places else f'the talk {sid}'
                for part in ('then', 'yes', 'no'):
                    b = t.get(part) or {}
                    ctx = {'yes': ' — if the answer is YES', 'no': ' — if the answer is NO'}.get(part, '')
                    for role, key in ((ON, 'set'), (OFF, 'clear')):
                        for j, f in enumerate(b.get(key) or []):
                            self._use(f, role, 'talk', where, ev + ctx, nav,
                                      base + ('talk', part, key, j), runs=runs)
            elif isinstance(s.get('ops'), list):
                self._walk_ops(s['ops'], 'script', where, nav, runs,
                               f'the script “{sid}”', places)
        self._cur_places = None

    def game_text(self, tid):
        """The original game's text `tid` (extracted/dialogue.json, measured S108)."""
        if not hasattr(self, '_gtext'):
            import json
            try:
                d = json.load(open(os.path.join(self.repo, 'extracted', 'dialogue.json'),
                                   encoding='utf-8'))
                self._gtext = {int(e['id'][1:], 16): e['text'] for e in d['text_ids']}
            except (OSError, ValueError, KeyError):
                self._gtext = {}
        return self._gtext.get(tid, '')

    def _op_text(self, t, n=34):
        if isinstance(t, str) and t in self._dlg:
            return self.text_of(t, n)
        try:
            tid = F.val(t)
        except (TypeError, ValueError):
            tid = None
        if isinstance(tid, int):
            s = ' '.join(self.game_text(tid).split())
            if ':' in s[:12]:
                s = s.split(':', 1)[1].strip()
            return '«' + (s[:n] + '…' if len(s) > n else s) + '»'
        return self.text_of(t, n)

    def brief_ops(self, ops, i, limit=2):
        """A few words for what a raw op list does from item i on."""
        from . import scriptgen as SG
        out = []
        while i < len(ops) and len(out) < limit:
            it = ops[i]
            i += 1
            if isinstance(it, str):
                continue
            if not isinstance(it, list) or not it:
                continue
            if it[0] == 'end':
                out.append('stops')
                break
            if it[0] == 'text' and len(it) > 1:
                out.append('says ' + self._op_text(it[1]))
                continue
            if it[0] != 'op' or len(it) < 2:
                continue
            nm = it[1]
            code = OP_NAMES.get(nm, SG.OPS.get(nm, (None,))[0] if isinstance(nm, str) else None)
            if code is None:
                try:
                    code = F.val(nm)
                except (TypeError, ValueError):
                    code = None
            if code in (0x00, 0x01):
                out.append('checks another flag')
                break
            if code in (0x02, 0x03) and len(it) > 2:
                out.append(f"turns {self.name_of(it[2])} {'ON' if code == 3 else 'OFF'}")
            elif code == 0x14:
                break
            elif code in (0x0F, 0x3B):
                out.append('the player is taken away')
            elif code in (0x05, 0x5A, 0x5B, 0x20):
                out.append('a battle')
            elif code in (0x2A, 0x37):
                out.append('gives an item')
            elif code in (0x29, 0x18):
                out.append('gives a monster')
        return ', '.join(out) if out else 'nothing'

    def _walk_ops(self, ops, kind, where, nav, runs, label, places):
        from . import scriptgen as SG
        labels = {it[6:]: n for n, it in enumerate(ops)
                  if isinstance(it, str) and it.startswith('label:')}
        for pos, op in enumerate(ops):
            if not (isinstance(op, list) and len(op) >= 3 and op[0] == 'op'):
                continue
            name = op[1]
            code = OP_NAMES.get(name)
            if code is None:
                if isinstance(name, str) and name in SG.OPS:
                    code = SG.OPS[name][0]
                else:
                    try:
                        code = F.val(name)
                    except (TypeError, ValueError):
                        code = None
            if code not in FLAG_OPS:
                continue
            role, want = FLAG_OPS[code]
            ref = op[2]
            ev = places[0].event() if places else label
            if role == TEST:
                tgt = str(op[3])[1:] if len(op) > 3 and str(op[3]).startswith('@') else None
                jump = self.brief_ops(ops, labels[tgt] + 1) if tgt in labels else 'another branch'
                then = f'{jump}; otherwise: {self.brief_ops(ops, pos + 1)}'
                self._trigger(kind, [(ref, want)], ev, then, where, nav, [None], runs=runs)
            else:
                self._use(ref, role, kind, where, ev, nav, None, runs=runs)

    def _walk_steps(self, steps, path, ctx, kind, event, where, nav, runs):
        """Conversation / cutscene steps: if / set / clear / ask / battle, nested."""
        ctx = list(ctx)
        if not isinstance(steps, list):
            return
        for i, st in enumerate(steps):
            if not isinstance(st, dict):
                continue
            p = path + (i,)
            circ = event + (' — ' + ', '.join(ctx) if ctx else '')
            if 'if' in st and isinstance(st['if'], list):
                terms, paths = [], []
                for j, tm in enumerate(st['if']):
                    if isinstance(tm, dict) and 'flag' in tm:
                        terms.append((tm['flag'], tm.get('is', 'set')))
                        paths.append(p + ('if', j, 'flag'))
                then = (f"then: {self.brief(st.get('then'))}; otherwise: "
                        f"{self.brief(st.get('else'))}")
                self._trigger(kind, terms, event + (' — ' + ', '.join(ctx) if ctx else ''),
                              then, where, nav, paths, runs=runs)
                cond = ' and '.join(f"{self.name_of(r)} is {'ON' if w == 'set' else 'OFF'}"
                                    for r, w in terms)
                self._walk_steps(st.get('then'), p + ('then',), ctx + [f'if {cond}'], kind,
                                 event, where, nav, runs)
                self._walk_steps(st.get('else'), p + ('else',), ctx + [f'unless {cond}'],
                                 kind, event, where, nav, runs)
            for key, role in (('set', ON), ('clear', OFF)):
                if key in st:
                    v = st[key]
                    if isinstance(v, list):
                        for j, f in enumerate(v):
                            self._use(f, role, kind, where, circ, nav, p + (key, j), runs=runs)
                    elif v not in (None, ''):
                        self._use(v, role, kind, where, circ, nav, p + (key,), runs=runs)
            if 'ask' in st:
                self._walk_steps(st.get('yes'), p + ('yes',), ctx + ['answer YES'], kind,
                                 event, where, nav, runs)
                self._walk_steps(st.get('no'), p + ('no',), ctx + ['answer NO'], kind,
                                 event, where, nav, runs)
            if 'battle' in st and 'after winning the battle' not in ctx:
                ctx.append('after winning the battle')

    # ------------------------------------------------------------- rooms
    def _walk_rooms(self):
        from . import cutscene_build as CB
        for ri, r in enumerate(self.rooms):
            rid = r.get('id')
            rname = r.get('name') or rid
            rnav = {'tab': 'rooms', 'room': rid, 'screen': None, 'state': 0, 'x': None, 'y': None}
            base = ('custom', 'rooms', ri)
            # state rules
            for j, ru in enumerate(r.get('state_rules') or []):
                terms = [(t.get('flag'), t.get('is', 'set')) for t in ru.get('when') or []]
                if not terms:
                    continue
                scr = ru.get('screens')
                on = (f"screens {', '.join(str(x) for x in scr)}" if scr is not None
                      else 'every screen')
                self._trigger('state_rule', terms, '',
                              f"{rname} shows state {ru.get('state')} ({on})",
                              f'{rname} · room states', rnav,
                              [base + ('state_rules', j, 'when', t, 'flag')
                               for t in range(len(terms))])
            # NPC conditions
            for k, scr in (r.get('screens') or {}).items():
                states = scr.get('states')
                lst = states if states else [scr]
                for si, st in enumerate(lst):
                    nn = 0
                    for ei, e in enumerate(st.get('npcs') or []):
                        if isinstance(e, dict) and CB.is_npc_entry(e):
                            nn += 1
                        if not isinstance(e, dict) or e.get('kind') not in (None, 'npc', 'raw'):
                            continue
                        ep = base + ('screens', k) + (('states', si) if states else ()) + \
                            ('npcs', ei)
                        if e.get('kind') == 'raw':
                            x, y = F.val(e['bytes'][2]), F.val(e['bytes'][3])
                        else:
                            x, y = e.get('x'), e.get('y')
                        place = Place(r, ri, k, si, len(lst), 'npc', x, y, e.get('actor'), nn)
                        where, nav = place.room_text(), place.nav()
                        sw = e.get('shown_when') or []
                        terms = [(t.get('flag'), t.get('is', 'set')) for t in sw
                                 if isinstance(t, dict)]
                        if terms:
                            self._trigger('npc_shown', terms, '',
                                          f'{place.thing()} is there (else it is hidden)',
                                          where, nav,
                                          [ep + ('shown_when', t, 'flag')
                                           for t in range(len(terms))])
                        col = e.get('colour')
                        if isinstance(col, dict) and col.get('when') not in (None, ''):
                            self._trigger('npc_colour', [(col['when'], 'set')], '',
                                          f"{place.thing()} is drawn in colour "
                                          f"{col.get('palette')}", where, nav,
                                          [ep + ('colour', 'when')])
                        if e.get('swirl_of') is not None:
                            try:
                                gid = int(F.val(e['swirl_of']))
                            except (TypeError, ValueError):
                                continue
                            pal = G.cleared_swirl(self.custom, gid)
                            then = ('the portal swirl at {} spins (it stops once cleared)'
                                    if pal is None else
                                    'the portal swirl at {} spins in its own colours '
                                    f'(colour {pal} once cleared)').format(_cell(x, y))
                            self._trigger('swirl', [(f'gate:{gid}', 'clear')], '', then,
                                          where, nav, [None])
            # battles
            enc = r.get('encounters') or {}
            for j, v in enumerate(enc.get('variants') or []):
                terms = [(t.get('flag'), t.get('is', 'set')) for t in v.get('when') or []
                         if isinstance(t, dict)]
                if terms:
                    self._trigger('room_battles', terms, '',
                                  f"battles in {rname} use list {v.get('list')}",
                                  f'{rname} · battles',
                                  {'tab': 'encounters', 'room': rid},
                                  [base + ('encounters', 'variants', j, 'when', t, 'flag')
                                   for t in range(len(terms))])
            # cutscenes
            for ci, sc in enumerate(r.get('cutscenes') or []):
                self._walk_cutscene(r, ri, ci, sc)

    def _walk_cutscene(self, r, ri, ci, sc):
        rname = r.get('name') or r.get('id')
        nav = {'tab': 'cutscene', 'room': r.get('id'), 'scene': sc.get('id'),
               'screen': int(sc.get('screen', 0) or 0), 'state': 0}
        title = sc.get('name') or sc.get('id')
        where = f'{rname} · screen {sc.get("screen", 0)} · cutscene “{title}”'
        base = ('custom', 'rooms', ri, 'cutscenes', ci)
        tr = sc.get('trigger') or {}
        on = tr.get('on', 'entry')
        ev = {'entry': f'you enter {rname} (screen {sc.get("screen", 0)})',
              'talk': f"you talk to “{tr.get('actor')}”",
              'examine': f"you examine {_cell(tr.get('x'), tr.get('y'))}",
              'stepon': f"you step on {_cell(tr.get('x'), tr.get('y'))}"}.get(on, on)
        terms, paths = [], []
        for j, f in enumerate(tr.get('when_on') or []):
            terms.append((f, 'set'))
            paths.append(base + ('trigger', 'when_on', j))
        for j, f in enumerate(tr.get('when_off') or []):
            terms.append((f, 'clear'))
            paths.append(base + ('trigger', 'when_off', j))
        once = tr.get('once')
        if once:
            terms.append((once, 'clear'))
            paths.append(base + ('trigger', 'once'))
        then = f'the cutscene “{title}” plays' + (' (once)' if once else '')
        if terms:
            self._trigger('cutscene_start', terms, ev, then, where, nav, paths)
        if once:
            u = self._use(once, ON, 'cutscene_start', where,
                          f'the cutscene “{title}” starts (its plays-once flag)', nav,
                          base + ('trigger', 'once'))
            u.who, u.when = f'the cutscene “{title}”', 'as it starts (it plays once)'
        self._walk_steps(sc.get('steps'), base + ('steps',), [], 'cutscene',
                         f'during the cutscene “{title}”', where, nav, True)

    # ------------------------------------------------------------- gates
    def _walk_gates(self):
        for gi, g in enumerate(self.custom.get('gates') or []):
            try:
                gid = int(F.val(g.get('gate')))
            except (TypeError, ValueError):
                continue
            enc = g.get('encounters') or {}
            for j, v in enumerate(enc.get('variants') or []):
                terms = [(t.get('flag'), t.get('is', 'set')) for t in v.get('when') or []
                         if isinstance(t, dict)]
                if terms:
                    nm = self.gate_label(gid).split(' cleared')[0] + '”'
                    self._trigger('gate_battles', terms, '',
                                  f'the floors of {nm} use their other battle lists',
                                  f'gate {gid} · battles', {'tab': 'encounters', 'gate': gid},
                                  [('custom', 'gates', gi, 'encounters', 'variants', j,
                                    'when', t, 'flag') for t in range(len(terms))])

    def _walk_gate_rooms(self):
        rooms = {r.get('id'): r for r in self.rooms}
        for j, ru in enumerate(self.custom.get('gate_inserts') or []):
            terms = [(t.get('flag'), t.get('is', 'set')) for t in ru.get('when') or []
                     if isinstance(t, dict)]
            if not terms:
                continue
            r = rooms.get(ru.get('room'))
            rn = (r.get('name') or r.get('id')) if r else ru.get('room')
            try:
                gid = int(F.val(ru.get('gate', 0)))
            except (TypeError, ValueError):
                gid = None
            fl = ru.get('floors')
            fl = f" floors {fl[0]}-{fl[1]}" if isinstance(fl, list) and len(fl) == 2 else ''
            self._trigger('gate_room', terms, '',
                          f"{rn} may appear on gate {gid}{fl} ({ru.get('chance', 100)} %)",
                          f'gate {gid} · rooms on gate floors', {'tab': 'gates', 'gate': gid},
                          [('custom', 'gate_inserts', j, 'when', t, 'flag')
                           for t in range(len(terms))])

    def _walk_hub(self):
        """S125 (ROADMAP P3.14d): custom.hub.rules[].when — where the game sends the
        player home (lost battle, WarpWing, a script's "the hub")."""
        rooms = {r.get('id'): r for r in self.rooms}
        for j, ru in enumerate((self.custom.get('hub') or {}).get('rules') or []):
            terms = [(t.get('flag'), t.get('is', 'set')) for t in ru.get('when') or []
                     if isinstance(t, dict)]
            if not terms:
                continue
            if ru.get('room') == 'castle':
                rn = 'the Castle (the original game\'s hub)'
            else:
                r = rooms.get(ru.get('room'))
                rn = (r.get('name') or r.get('id')) if r else ru.get('room')
            self._trigger('hub', terms, '', f"the hub is {rn} (rule {j + 1})",
                          f'hub · rule {j + 1}', {'tab': 'worlds', 'hub': j},
                          [('custom', 'hub', 'rules', j, 'when', t, 'flag')
                           for t in range(len(terms))])

    # ------------------------------------------------------------- quests (legacy, S70)
    def _walk_quests(self):
        """The legacy S70 quests (retired in ROADMAP P3.14c)."""
        for qi, q in enumerate(self.progression.get('quests') or []):
            qid = q.get('id')
            places = self.binds.get(f'quest:{qid}', [])
            eplaces = self.binds.get(f'entry:{qid}', [])
            where = _places_where(places)
            who = (places[0].event() if places else f'the quest “{qid}”') + ' (quest)'
            ewho = 'entering ' + (eplaces[0].room_name if eplaces else 'its room') + ' (quest)'
            nav = places[0].nav() if places else None
            base = ('progression', 'quests', qi)
            fl = q.get('flags') or {}

            def use(ref, role, w, when, path, runs, want=None, trig=None):
                u = self._use(ref, role, 'quest', where, f'{w} — {when}', nav, path, want,
                              trig, runs=runs)
                u.who, u.when = w, when
                return u
            if fl.get('done'):
                self._trigger('quest', [(fl['done'], 'set')], who,
                              'the “already done” words instead of the offer', where, nav,
                              [base + ('flags', 'done')], runs=bool(places))
                use(fl['done'], ON, who, 'after winning the quest battle',
                    base + ('flags', 'done'), bool(places))
            if fl.get('cutscene_seen'):
                self._trigger('quest', [(fl['cutscene_seen'], 'clear')], ewho,
                              'its entry cutscene plays', where, nav,
                              [base + ('flags', 'cutscene_seen')], runs=bool(eplaces))
                use(fl['cutscene_seen'], ON, ewho, 'when its entry cutscene has played',
                    base + ('flags', 'cutscene_seen'), bool(eplaces))
            for part in ('on_win', 'entry_done'):
                for j, a in enumerate(q.get(part) or []):
                    if not isinstance(a, dict):
                        continue
                    for key, role in (('set_flag', ON), ('clear_flag', OFF)):
                        if key in a:
                            use(a[key], role, who if part == 'on_win' else ewho,
                                'after winning the quest battle' if part == 'on_win'
                                else 'once the quest is done', base + (part, j, key),
                                bool(places))

    def _walk_preludes(self):
        for sid, ops in (self.custom.get('script_preludes') or {}).items():
            if str(sid).startswith('_') or not isinstance(ops, list):
                continue
            places = self.binds.get(sid, [])
            self._walk_ops(ops, 'prelude', _places_where(places),
                           places[0].nav() if places else None, bool(places),
                           f'the start of the script “{sid}”', places)

    # ------------------------------------------------------------- engine
    def _engine(self):
        """Bank $76 GateBossWin (S117/S122): a won boss-floor battle of a new gate or a
        re-bossed vanilla gate turns the gate's own flag ON (+ a re-bossed gate's vanilla
        flags). A world never reaches its boss floor — only a conversation clears it."""
        worlds = self._worlds()
        seen = set()
        for g in self.custom.get('gates') or []:
            try:
                gid = int(F.val(g.get('gate')))
            except (TypeError, ValueError):
                continue
            if gid in seen or gid in worlds:
                continue
            seen.add(gid)
            try:
                info = G.gate_cleared(self.custom, gid, self.repo)
            except Exception:                                    # noqa: BLE001
                info = None
            if not info or not info.get('own'):
                continue
            what = ('winning the boss battle on its last floor (the editor\'s engine, '
                    'bank $76 GateBossWin)')
            nav = {'tab': 'gates', 'gate': gid}
            where = f'gate {gid} · boss floor'
            self._use(f'gate:{gid}', ON, 'gate_win', where, what, nav, source='engine')
            if gid < 32:
                if info.get('vanilla_flag') is not None:
                    self._use(info['vanilla_flag'], ON, 'gate_win', where,
                              what + ' — the game\'s own flag of this gate', nav,
                              source='engine')
                extra, tails = G.vanilla_win_program(gid, self.repo)
                for f in extra:
                    self._use(f, ON, 'gate_win', where, what, nav, source='engine')
                for t in tails:
                    for op in t.get('ops') or []:
                        try:
                            code = int(op[1])
                        except (TypeError, ValueError, IndexError):
                            continue
                        if code in (0x02, 0x03) and op[2]:
                            self._use(F.val(op[2][0]), ON if code == 3 else OFF, 'gate_win',
                                      where, what + ' — the game\'s own win bookkeeping',
                                      nav, source='engine')

    def _hook(self):
        h = self.custom.get('milly_hook')
        if not isinstance(h, dict) or not h.get('enabled'):
            return
        nav = {'tab': 'cutscenes'}
        self._use('hook:milly', ON, 'hook', 'the bedroom intro',
                  'the dresser glows (the Milly hook)', nav, source='engine')
        self._use('hook:milly_arrived', ON, 'hook', 'Milly\'s arrival room',
                  'her arrival scene plays (once)', nav, source='engine')
        self._use('hook:milly_arrived', TEST, 'hook', 'Milly\'s arrival room',
                  'her arrival scene plays only while it is OFF', nav, want='clear',
                  source='engine')

    # ------------------------------------------------------------- the game
    def _game(self, cat):
        """The original game's scripts. S124 r2 (user: "it is NOT clear how the progression
        goes … Looks like it just randomly turns on by a million things"): every use says WHO
        runs its script (the NPC / spot / room entry of the room data, named by its own
        lines), WHERE (room · screen) and WHEN (the deciding condition of its branch, from
        the path of flag tests that leads there); the uses of one script form one group."""
        from . import cutscenes as CS
        for m in cat.map_types():
            rname = cat.rooms.name(m)
            for sc in cat.scripts(m):
                if sc is None:
                    continue
                idx = sc.key[2]
                titles, paths = {}, {}
                try:
                    for scn in CS.scenes_of(sc, min_show=0):
                        t = CS.scene_title(scn, cat.text)
                        for st in scn.steps:
                            titles.setdefault(st.pos, t)
                            paths.setdefault(st.pos, scn.path)
                except Exception:                                # noqa: BLE001
                    pass
                ops = [st for st in sc.steps.values() if st.code in FLAG_OPS and st.params]
                if not ops:
                    continue
                who, where, places = self._game_who(cat, m, idx, sc, rname)
                for st in ops:
                    role, want = FLAG_OPS[st.code]
                    if role == TEST:
                        tgt = getattr(st, 'target', None)
                        what = (f'{self._game_brief(cat, sc, tgt)}; otherwise: '
                                f'{self._game_brief(cat, sc, sc.next_pos(st))}')
                    else:
                        t = titles.get(st.pos, '')
                        what = f'in the scene «{t[:40]}»' if t else ''
                    u = self._use(st.params[0], role, 'game', where, what,
                                  places[0], None, want, source='game',
                                  idx=st.params[0])
                    u.places = places
                    u.who = who
                    if role == TEST:
                        try:
                            reach = sc.path_to(st.pos)
                        except Exception:                        # noqa: BLE001
                            reach = None
                        u.when = self._reach_when(reach or [])
                    else:
                        u.when = self._path_when(paths.get(st.pos) or [])
                    u.group = ('game', m, idx)

    def _game_who(self, cat, m, idx, sc, rname):
        """(who runs game script idx of map m, where, places) — from the room data's
        triggers. S124 r3: names = the user's (custom._editor.npc_names) first, then the
        one speaker the script's own lines give; places = every screen / state / cell
        it runs at (the side panel steps through them)."""
        import re
        from . import npc_names as NN
        try:
            trig = cat.rooms.triggers(m, idx)
        except Exception:                                        # noqa: BLE001
            trig = []
        spk = self._game_name(cat, sc)
        verbs, cells, screens, places = [], {}, [], []
        for t in trig:
            kind, k, st, x, y, desc = t
            if k is not None and k not in screens:
                screens.append(k)
            n = None
            if kind == 'npc':
                mm = re.search(r'NPC (\d+) \(sprite \$([0-9A-Fa-f]{2})\)', desc or '')
                n = int(mm.group(1)) if mm else None
                user = NN.name_of(self.custom, m, k, st, n) if n else None
                nm = user or spk or (f'the NPC (sprite ${mm.group(2).upper()})' if mm
                                     else 'an NPC')
                v = f'talking to {nm}'
            elif kind == 'examine':
                v = 'examining'
            elif kind in ('stepon', 'step'):
                v = 'stepping on'
            else:
                v = 'entering the room'
            if v not in verbs:
                verbs.append(v)
            if v != 'entering the room':
                cells.setdefault(v, [])
                if (x, y) not in cells[v]:
                    cells[v].append((x, y))      # the same NPC in another room state
            places.append({'tab': 'game', 'map': m,
                           'screen': k if k is not None else (cat.rooms.screens(m) or [0])[0],
                           'state': st or 0, 'x': x, 'y': y, 'n': n,
                           'who': v + (f' at ({x}, {y})' if x is not None and
                                       v != 'entering the room' else '')})
        if not trig and idx == 0:
            verbs = ['entering the room']
        if not places:
            places = [{'tab': 'game', 'map': m, 'screen': (cat.rooms.screens(m) or [0])[0],
                       'state': 0, 'x': None, 'y': None, 'n': None, 'who': verbs[0] if verbs
                       else f'script {idx}'}]
        whos = [v + ((' at ' if v.startswith('talking') else ' ') +
                     ' / '.join(f'({x}, {y})' for x, y in cells[v][:3])
                     if cells.get(v) else '') for v in verbs]
        who = ' or '.join(whos[:2]) if whos else f'its script {idx} (run by another script)'
        scr = (' · screen ' + ', '.join(str(k) for k in screens)) if screens else ''
        return who, f'{rname}{scr} (game room ${m:02X}, script {idx})', places

    @staticmethod
    def _game_name(cat, sc):
        """The speaker name a game script's OWN lines give (exactly one "Name:" in it —
        S118g: names only from the game's text), else None."""
        from . import cutscenes as CS
        names = set()
        for pos in sc.order:
            st = sc.steps[pos]
            if st.code == 0x101 and st.params:
                t = (cat.text(st.params[0]) or '').lstrip()
                mm = CS._SPEAKER.match(t)
                if mm and mm.group(1).strip().upper() not in ('[HERO]', 'HERO', 'KING'):
                    names.add(mm.group(1).strip())
        return names.pop() if len(names) == 1 else None

    def _reach_when(self, path):
        """When the game reaches a check: the flags that must be ON / OFF on the way."""
        ons = [self.name_of(t[1], t[1]) for t in path if t[0] == 'flag' and t[2]]
        offs = [self.name_of(t[1], t[1]) for t in path if t[0] == 'flag' and not t[2]]
        if not ons and not offs:
            return 'always'
        out = []
        if ons:
            out.append('once ' + ' and '.join(ons) + ' ' + ('is' if len(ons) == 1 else 'are') + ' ON')
        if offs:
            out.append('before ' + ', '.join(offs[:3]) + (f' (+{len(offs) - 3})' if len(offs) > 3 else ''))
        return ', '.join(out)

    def _path_when(self, path):
        """The deciding condition of a branch: the last test on its path that had to
        hold (a ladder's rung) — or 'always' / 'before …'."""
        if not path:
            return 'always'
        for t in reversed(path):
            if t[0] == 'flag' and t[2]:
                return f'when {self.name_of(t[1], t[1])} is ON'
            if t[0] == 'ram' and t[3]:
                if t[1] == 0xC83C:
                    return 'after answering NO' if t[2] == 1 else 'after answering YES'
                return f'when ${t[1]:04X} = {t[2]}'
            if t[0] == 'test' and t[2]:
                return 'when ' + str(t[1]).replace('Go to target when ', '')[:40]
        offs = [t for t in path if t[0] == 'flag' and not t[2]]
        if offs:
            return f'while {self.name_of(offs[0][1], offs[0][1])} is OFF' + \
                (f' (and {len(offs) - 1} more OFF)' if len(offs) > 1 else '')
        return 'always'

    def _game_brief(self, cat, sc, pos, limit=12):
        """The first text (or a flag test / the end) the game's script reaches from pos."""
        n = 0
        while pos is not None and pos in sc.steps and n < limit:
            st = sc.steps[pos]
            n += 1
            if st.code == 0x101 and st.params:
                s = ' '.join(str(cat.text(st.params[0])).split())
                if ':' in s[:12]:
                    s = s.split(':', 1)[1].strip()
                return 'says «' + (s[:34] + '…' if len(s) > 34 else s) + '»'
            if st.code in (0x00, 0x01):
                return 'checks another flag'
            if st.code in (0x02, 0x03) and st.params:
                return f"turns {self.name_of(st.params[0], st.params[0])} " \
                       f"{'ON' if st.code == 3 else 'OFF'}"
            if st.code == 0x14 and getattr(st, 'target', None) is not None:
                pos = st.target
                continue
            nxt = sc.next_pos(st)
            if nxt is None:
                return 'stops'
            pos = nxt
        return '…'

    def _game_engine(self, rom):
        for idx, what in GAME_ENGINE_ON.items():
            self._use(idx, ON, 'game_engine', 'the original game', what, None,
                      source='game', idx=idx)
        if rom is None:
            return
        for (bank, addr), want_txt in ((GATE_LIST_UNLOCK, 'which gates are open'),
                                       (GATE_LIST_CLEARED, 'which gates are cleared')):
            o = bank * 0x4000 + addr - 0x4000
            for i in range(16):
                f = rom[o + i]
                self._use(f, TEST, 'game_engine', 'the original game',
                          f'the gate list (bank $09 screen 13) shows {want_txt}', None,
                          want='set', source='game', idx=f)

    # ------------------------------------------------------------- collect
    def _collect(self):
        # S124 r2: who / when / group for the project's uses from their sentences
        # ("talking to the NPC at (2, 6) — answer YES, after winning the battle")
        for u in self.uses:
            if u.who:
                continue
            src = (u.trigger.event if (u.trigger is not None and u.trigger.event)
                   else (u.what if u.role != TEST else ''))
            if src:
                head, _sep, rest = src.partition(' — ')
                u.who = head
                if not u.when:
                    u.when = rest
            if u.group is None:
                u.group = (u.source, u.kind, u.who, u.where)
        self.flags = {}
        for nm, n in self.named.items():
            if n is None:
                continue
            fl, com, declared = self.entries[nm]
            self.flags[n] = FlagInfo(n, 'project' if declared else 'quest', nm,
                                     '', com or '', fl)
        for u in self.uses:
            if not isinstance(u.idx, int):
                continue
            fi = self.flags.get(u.idx)
            if fi is None:
                fi = self.flags[u.idx] = self._info(u.idx, u.ref)
            fi.uses.append(u)
        # S124 r2: a game flag without a name from the game's data is labelled by who sets
        # it ("set by talking to Santi at (1, 6) (GreatTree)") — not a scene's first words
        for f in self.flags.values():
            if f.kind != 'game' or (f.label and not f.label.startswith(('set in', 'never set'))):
                continue
            ons = self.groups([u for u in f.uses if u.role == ON and u.source == 'game'])
            if ons:
                f.label = 'set by ' + self._short(ons[0][0], len(ons[0][1])) + \
                    (f' (+{len(ons) - 1} more)' if len(ons) > 1 else '')
        # every gate with its own flag is listed (a world's portal needs one)
        for g in self.custom.get('gates') or []:
            try:
                gid = int(F.val(g.get('gate')))
                info = G.gate_cleared(self.custom, gid, self.repo)
            except Exception:                                    # noqa: BLE001
                continue
            if info and info.get('flag') is not None and info['flag'] not in self.flags:
                self.flags[info['flag']] = self._info(info['flag'], f'gate:{gid}')

    def _info(self, idx, ref):
        from . import milly as MH
        if GATE_FLAG_BASE <= idx <= GATE_FLAG_BASE + 95:
            gid = idx - GATE_FLAG_BASE
            return FlagInfo(idx, 'gate', self.gate_label(gid), 'cleared when its boss is beaten')
        if idx in MH.FLAG_REFS.values():
            nm = next(k for k, v in MH.FLAG_REFS.items() if v == idx)
            return FlagInfo(idx, 'hook', self.name_of(nm), 'the Milly hook')
        if isinstance(ref, str) and ref.startswith('gate:'):
            gid = G.parse_gate_ref(ref)
            return FlagInfo(idx, 'gate', self.gate_label(gid), 'the game\'s own cleared flag')
        label = ''
        if self.catalogue is not None:
            try:
                label = self.catalogue.flag_desc(idx)
            except Exception:                                    # noqa: BLE001
                label = ''
        return FlagInfo(idx, 'game', f'game flag {flag_number(idx)}', label)

    # ------------------------------------------------------------- summaries (S124 r2)
    @staticmethod
    def groups(uses):
        """[(head use, [uses])] — the uses of one script / place together, in order."""
        out, by = [], {}
        for u in uses:
            k = u.group or (u.source, u.kind, u.who, u.where)
            if k not in by:
                by[k] = []
                out.append((u, by[k]))
            by[k].append(u)
        return out

    @staticmethod
    def _room_of(u):
        return u.where.split(' (game room')[0].split(' · ')[0]

    def _short(self, u, n=None):
        who = u.who or ''
        room = self._room_of(u)
        if not who:
            return f'{u.where}'
        extra = f', {n} of its branches' if n and n > 1 else ''
        return f'{who} ({room}{extra})' if room and room not in who else f'{who}{extra}'

    def summary(self, f):
        """The flag's story in one or two sentences: who turns it ON, what checks it."""
        def part(uses, game):
            ons = self.groups([u for u in uses if u.role == ON])
            tests = self.groups([u for u in uses if u.role == TEST])
            out = []
            if ons:
                txt = ' or '.join(self._short(h, len(g)) for h, g in ons[:3])
                more = len(ons) - 3
                out.append(f'turned ON by {txt}' + (f' (+{more} more)' if more > 0 else ''))
            else:
                out.append('nothing turns it ON')
            if tests:
                def once(h):
                    w = (h.when or '').split(', before')[0]
                    return f' {w}' if game and w.startswith('once') else ''
                txt = '; '.join(self._short(h) + once(h) for h, g in tests[:2])
                more = len(tests) - 2
                out.append(f'checked by {txt}' + (f' (+{more} more)' if more > 0 else ''))
            else:
                out.append('nothing checks it')
            return '; '.join(out)
        mine = [u for u in f.uses if u.source != 'game']
        game = [u for u in f.uses if u.source == 'game']
        lines = []
        if mine or f.kind != 'game':
            lines.append('In your game: ' + part(mine, False) + '.')
        if game:
            lines.append('In the original game: ' + part(game, True) + '.')
        return lines

    # ------------------------------------------------------------- queries
    def unresolved(self):
        return [u for u in self.uses if u.source == 'project' and not isinstance(u.idx, int)]

    def project_flags(self):
        return sorted((f for f in self.flags.values() if f.kind in ('project', 'quest')),
                      key=lambda f: f.name.lower())

    def uses_of_name(self, name):
        """Every authored reference to a project flag NAME (Rename / Delete)."""
        return [u for u in self.uses if u.source == 'project' and u.ref == name]

    def project_relevant(self, f):
        """A flag this project names, sets or tests."""
        return f.kind != 'game' or any(u.source != 'game' for u in f.uses)

    def problems(self):
        out = []
        for u in self.unresolved():
            out.append(Problem('error', 'undefined', None,
                               f'“{u.ref}” is not a flag of this project (and not a flag '
                               f'number) — {u.where}. The build stops here.', [u]))
        for f in sorted(self.flags.values(), key=lambda f: f.idx):
            proj = [u for u in f.uses if u.source != 'game']
            if f.kind == 'game' and not proj:
                continue
            ons = [u for u in f.uses if u.role == ON and u.source in ('project', 'engine')]
            live_ons = [u for u in ons if u.runs]
            game_ons = [u for u in f.uses if u.role == ON and u.source == 'game']
            tests = [u for u in f.uses if u.role == TEST and u.source == 'project']
            want_on = [u for u in tests if u.want == 'set']
            nm = self.label(f)
            if want_on and not live_ons:
                if game_ons:
                    out.append(Problem(
                        'warn', 'game_only', f.idx,
                        f'{nm}: only the original game turns it ON '
                        f'({len(game_ons)} place{"s" if len(game_ons) != 1 else ""}). '
                        f'{len(want_on)} check{"s" if len(want_on) != 1 else ""} of your '
                        'game wait for it — never true unless the player also plays those '
                        'game rooms.', want_on))
                elif f.kind == 'hook':
                    pass
                else:
                    why = (' (only a script no room uses)' if ons else '')
                    out.append(Problem(
                        'warn', 'never_on', f.idx,
                        f'{nm}: nothing turns it ON{why} — {len(want_on)} '
                        f'check{"s" if len(want_on) != 1 else ""} waiting for it '
                        'are never true.', want_on))
            if f.kind in ('project', 'quest'):
                game = [u for u in f.uses if u.source == 'game']
                if game or f.idx in GAME_SHARED_FLAGS:
                    what = (GAME_SHARED_FLAGS.get(f.idx) or
                            '; '.join(sorted({u.where for u in game}))[:120])
                    out.append(Problem(
                        'warn', 'game_shares', f.idx,
                        f'{nm}: its number {flag_number(f.idx)} is also used by {what}. '
                        'If the player reaches that place the two get mixed up — '
                        'Renumber gives it a free number.', game))
                if not f.uses:
                    out.append(Problem('info', 'unused', f.idx,
                                       f'{nm}: not used anywhere — it can be deleted.'))
                elif ons and not [u for u in f.uses if u.role == TEST]:
                    out.append(Problem('info', 'never_read', f.idx,
                                       f'{nm}: turned ON but nothing checks it.', ons))
            if proj and not flag_persistent(f.idx):
                out.append(Problem('warn', 'not_saved', f.idx,
                                   f'{nm}: flag {flag_number(f.idx)} is not saved with the '
                                   'game — it resets when the game is loaded.', proj))
        return out

    def label(self, f):
        if f.kind in ('project', 'quest'):
            return f'“{f.name}”'
        if f.kind == 'game':
            return f'game flag {flag_number(f.idx)}' + (f' ({f.label})' if f.label else '')
        return f.name

    def triggers_sentences(self):
        return [(t, t.sentence(self.name_of)) for t in self.triggers]


# ---------------------------------------------------------------------------
def compiler_coverage(project_path, repo=REPO):
    """The check behind test_compiler `test_flag_index_s124`: compile the project
    (no assembling) while logging every flag reference Project.resolve_flag_ref /
    Project._flag_index resolve and every flag op of the lowered scripts; return
    (missed, index) — missed = [(number, role or 'resolved', context)] the index
    does not know. Validator-only resolutions (the world check) are not uses."""
    import json
    from . import compiler as C
    from .project import Project
    log = []
    orig_r, orig_i = Project.resolve_flag_ref, Project._flag_index

    def rec_r(self, ref, ctx=''):
        idx = orig_r(self, ref, ctx)
        log.append((idx, str(ctx)))
        return idx

    def rec_i(self, name, ctx):
        idx = orig_i(self, name, ctx)
        log.append((idx, str(ctx)))
        return idx
    Project.resolve_flag_ref, Project._flag_index = rec_r, rec_i
    try:
        _out, prj, _w = C.compile_project(project_path, repo)
    finally:
        Project.resolve_flag_ref, Project._flag_index = orig_r, orig_i
    path = project_path if project_path.endswith('.json') else \
        os.path.join(project_path, 'project.json')
    fi = FlagIndex(json.load(open(path, encoding='utf-8')), repo=repo)
    have = {u.idx for u in fi.uses if u.source in ('project', 'engine')}
    roles = {(u.idx, u.role) for u in fi.uses if u.source in ('project', 'engine')}
    missed = [(i, 'resolved', c) for i, c in log
              if i not in have and not c.startswith('world')]
    for sid, sc in prj._scripts.items():
        if str(sid).startswith('skill:'):
            continue                  # the custom skills' built-in scripts (not the project's)
        for op in sc.get('ops') or []:
            if not (isinstance(op, list) and len(op) >= 3 and op[0] == 'op'):
                continue
            code = OP_NAMES.get(op[1])
            if code is None:
                try:
                    code = F.val(op[1])
                except (TypeError, ValueError):
                    continue
            if code not in FLAG_OPS:
                continue
            try:
                idx = F.val(op[2])
            except (TypeError, ValueError):
                idx = None
            if not isinstance(idx, int):
                idx = fi.resolve(op[2])
            role = FLAG_OPS[code][0]
            if (idx, role) not in roles:
                missed.append((idx, role, f'script {sid}'))
    return missed, fi


def report(fi, out=sys.stdout):
    def w(s=''):
        print(s, file=out)
    w(f'{len(fi.project_flags())} project flags, '
      f'{sum(1 for f in fi.flags.values() if f.kind == "gate")} gate flags, '
      f'{len(fi.triggers)} triggers, {len(fi.uses)} uses')
    for f in fi.project_flags():
        w(f'\n{fi.label(f)} {flag_number(f.idx)}' + (f' — {f.comment}' if f.comment else ''))
        for u in f.uses:
            role = {ON: 'ON ', OFF: 'OFF', TEST: 'IF '}[u.role]
            w(f'   {role} [{KINDS.get(u.kind, u.kind)}] {u.where} :: {u.what}')
    w('\nTriggers:')
    for t, s in fi.triggers_sentences():
        w(f'  [{KINDS.get(t.kind, t.kind)}] {s}   ({t.where})')
    w('\nProblems:')
    for p in fi.problems():
        w(f'  {p.level}: {p.text}')


def main(argv=None):
    import argparse
    import json
    ap = argparse.ArgumentParser()
    ap.add_argument('project')
    ap.add_argument('--rom')
    a = ap.parse_args(argv)
    path = a.project if a.project.endswith('.json') else os.path.join(a.project, 'project.json')
    data = json.load(open(path, encoding='utf-8'))
    cat = None
    if a.rom:
        from .cutscenes import Catalogue
        cat = Catalogue(open(a.rom, 'rb').read())
    report(FlagIndex(data, catalogue=cat))


if __name__ == '__main__':
    main()
