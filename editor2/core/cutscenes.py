"""cutscenes.py — every script scene of the game, readable and playable (S118,
ROADMAP P3.8 part A).

Headless (no Qt). Reads the vanilla scripts straight from the ROM (banks
$0C-$0F; the master table at $41BA of each, indexed by the full map type —
BANK04_SCRIPT_ENGINE "Script data banks") and the project's own scripts
(custom.scripts[].ops, the compiler's op lists — cloned rooms carry the
vanilla scripts this way), and turns them into:

  Script   — the decoded steps of one script: pos = the word index the game's
             script counter ($D8D5/$D8D6) holds while the step runs, so the
             live counter maps straight onto a step (the Playback window
             highlights it). Vanilla scripts may share code (branch targets
             before the script's own start give negative positions).
  Scene    — one branch of a script that SHOWS something (actors move, turn,
             appear, a room change, the screen changes …): its steps in play
             order, how it is reached (the conditions on the path from the
             script's start: screen, event flags, RAM bytes) and how it is
             triggered (room entry = script 0, an NPC, an examine spot, a
             step-on spot).
  Recipe   — what the Playback window sets up to play a scene without the
             author walking there: flags / RAM to set, the room, screen,
             room state (step), where the player stands, which script and
             counter to start.
  Actors   — the per-step state of the player and the room's NPCs (pixel
             position, facing, shown / hidden), from the room's NPC list and
             the measured meaning of each step (script_ops.PROGRAMS) — the
             still preview of the storyboard. Positions are checked against
             the game at every wait (tools/census_cutscenes.py).

Coordinates: screen-local tiles inside a room screen are 10 x 8; a room is a
4 x 4 grid of screens (wScreenIndex = row * 4 + col), absolute tile =
(col * 10 + x, row * 8 + y), absolute pixel = tile * 16 + 8 (harness warp).
"""

import json
import re
import os
from collections import namedtuple

from . import script_ops as SO

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SCRIPT_TBL = 0x41BA
END, TEXT = 0x100, 0x101
ARITY = {c: len(o.params) for c, o in SO.OPS.items()}
CUSTOM_ROOM_START = 0x6B
GATE_WORLD_TYPE = 0x70        # wScriptMapType inside gates (bank $01 entry path)


def script_bank(map_type):
    """Bank $04 MapTypeDispatch: < $06 -> $0C, < $20 -> $0D, < $40 -> $0E, else $0F."""
    return 0x0C if map_type < 0x06 else 0x0D if map_type < 0x20 else \
        0x0E if map_type < 0x40 else 0x0F


def _rw(rom, bank, addr):
    o = bank * 0x4000 + (addr - 0x4000)
    return rom[o] | (rom[o + 1] << 8)


def vanilla_script_ptrs(rom, map_type):
    """The map's script start addresses (index = script id, $D8D4). A map's
    pointer list ends where the next map's list (any master-table row of
    the bank) begins."""
    bank = script_bank(map_type)
    lo, hi = {0x0C: (0, 6), 0x0D: (6, 0x20), 0x0E: (0x20, 0x40),
              0x0F: (0x40, 0x71)}[bank]
    tbl = _rw(rom, bank, SCRIPT_TBL + map_type * 2)
    starts = {_rw(rom, bank, SCRIPT_TBL + m * 2) for m in range(lo, hi)}
    nxt = min([x for x in starts if x > tbl] + [0x8000])
    ptrs, a = [], tbl
    while len(ptrs) < 100 and a < nxt:
        p = _rw(rom, bank, a)
        if not 0x4000 <= p <= 0x7FFF:
            break
        ptrs.append(p)
        a += 2
    return ptrs


Step = namedtuple('Step', 'pos code params target addr')


class Script:
    """Decoded steps keyed by pos (counter value). `target` = the pos a
    branch goes to (None otherwise)."""

    def __init__(self, key, steps, bank=None, start=None, source=''):
        self.key = key                  # ('vanilla', map, idx) | ('project', id)
        self.steps = steps              # {pos: Step}
        self.bank, self.start, self.source = bank, start, source
        self.order = sorted(steps)

    # -- control flow -----------------------------------------------------
    def next_pos(self, st):
        """The fall-through pos after a step (None after a terminal)."""
        if st.code in (END, 0x14) or st.code in SO.TERMINAL:
            return None
        return st.pos + 1 + (ARITY.get(st.code, 0) if st.code < 0x100 else 0)

    def successors(self, st):
        """[(pos, literal)] — literal = None (always) or a condition tuple:
        ('flag', n, is_set) | ('screen', k, equal) | ('ram', addr, value,
        equal) | ('test', text, taken)."""
        out = []
        nxt = self.next_pos(st)
        c, p = st.code, st.params
        if c == 0x14:
            return [(st.target, None)]
        if st.target is not None:
            if c == 0x00:
                taken, fall = ('flag', p[0], False), ('flag', p[0], True)
            elif c == 0x01:
                taken, fall = ('flag', p[0], True), ('flag', p[0], False)
            elif c == 0x0E:
                taken, fall = ('screen', p[0], True), ('screen', p[0], False)
            elif c == 0x15:
                taken, fall = ('ram', p[0], p[1] & 0xFF, True), ('ram', p[0], p[1] & 0xFF, False)
            else:
                d = SO.OPS[c].doc.split('.')[0]
                taken, fall = ('test', d, True), ('test', d, False)
            out.append((st.target, taken))
            if nxt is not None:
                out.append((nxt, fall))
            return out
        if nxt is not None:
            out.append((nxt, None))
        return out

    def entries(self):
        """Block heads: the start (pos 0) + every branch target, in order."""
        heads = {0}
        for st in self.steps.values():
            if st.target is not None:
                heads.add(st.target)
        return sorted(h for h in heads if h in self.steps)

    def run_from(self, pos, stop_at_heads=False):
        """Steps in PLAY order from pos following fall-through and goto
        (stops at a terminal or when a pos repeats)."""
        out, seen = [], set()
        heads = set(self.entries()) if stop_at_heads else set()
        while pos is not None and pos in self.steps and pos not in seen:
            if out and pos in heads:
                break
            seen.add(pos)
            st = self.steps[pos]
            out.append(st)
            if st.code == 0x14:
                pos = st.target
                continue
            pos = self.next_pos(st)
        return out

    def path_to(self, target, steps_out=None):
        """The literals on the shortest path from pos 0 to target (BFS), or
        None when unreachable. steps_out (a list) gets the path's steps."""
        from collections import deque
        q, prev = deque([0]), {0: None}
        while q:
            p = q.popleft()
            if p == target:
                break
            st = self.steps.get(p)
            if st is None:
                continue
            for n, lit in self.successors(st):
                if n not in prev and n in self.steps:
                    prev[n] = (p, lit)
                    q.append(n)
        if target not in prev:
            return None
        lits, p = [], target
        while prev[p] is not None:
            p, lit = prev[p]
            if lit is not None:
                lits.append(lit)
            if steps_out is not None:
                steps_out.append(self.steps[p])
        if steps_out is not None:
            steps_out.reverse()
        return list(reversed(lits))

    def after_battle(self, target):
        """True when every way to target passes a battle (the scene plays
        after the player WINS it — a win resumes the script)."""
        on = []
        if self.path_to(target, on) is None:
            return False
        return any(st.code < 0x100 and SO.OPS[st.code].kind == 'battle' for st in on)


SELF_REPEAT = {0x19, 0x46, 0x4C, 0x65}     # waits that re-run themselves (counter - 1)


def step_at_counter(script, ctr):
    """The step the game is on when the script counter holds ctr (between
    ticks the counter sits on the step's last word; a self-repeating wait
    leaves it one BEFORE the step)."""
    if ctr in script.steps:
        return script.steps[ctr]
    nxt = script.steps.get(ctr + 1)
    if nxt is not None and nxt.code in SELF_REPEAT:
        return nxt
    for back in range(1, 5):
        st = script.steps.get(ctr - back)
        if st is not None and st.code < 0x100 and ARITY.get(st.code, 0) >= back:
            return st
    return None


def decode_words(read, start):
    """Decode from a word reader read(addr) -> word; addr in bytes, 2 per
    word. Returns {pos: Step} over every reachable step."""
    steps, pend = {}, [start]
    while pend:
        a = pend.pop()
        while True:
            pos = (a - start) // 2
            if pos in steps:
                break
            w = read(a)
            if w is None:
                break
            if w == 0xFFFF:
                steps[pos] = Step(pos, END, (), None, a)
                break
            if (w >> 8) != 0xFF:
                steps[pos] = Step(pos, TEXT, (w,), None, a)
                a += 2
                continue
            c = w & 0xFF
            if c not in ARITY:
                steps[pos] = Step(pos, END, (), None, a)   # unknown: stop the decode
                break
            pr = tuple(read(a + 2 + 2 * k) or 0 for k in range(ARITY[c]))
            tgt = None
            br = SO.OPS[c].branch
            if br is not None:
                ta = pr[br]
                tgt = (ta - start) // 2
                pend.append(ta)
            steps[pos] = Step(pos, c, pr, tgt, a)
            a += 2 + 2 * ARITY[c]
            if c == 0x14 or c in SO.TERMINAL:
                break
    return steps


def decode_vanilla(rom, map_type, idx):
    ptrs = vanilla_script_ptrs(rom, map_type)
    bank = script_bank(map_type)
    start = ptrs[idx]

    def read(a):
        if not 0x4000 <= a <= 0x7FFE:
            return None
        return _rw(rom, bank, a)
    return Script(('vanilla', map_type, idx), decode_words(read, start), bank, start,
                  f'${bank:02X}:{start:04X}')


def _pv(p):
    if isinstance(p, int):
        return p & 0xFFFF
    s = str(p).strip()
    if s.startswith('$'):
        return int(s[1:], 16)
    if s.lower().startswith('0x'):
        return int(s, 16)
    if s.lstrip('-').isdigit():
        return int(s) & 0xFFFF
    return None


def project_words(ops):
    """Lay a compiler op list out as words exactly as scriptgen emits it
    (1 word per op + its params; text 1; end 1; labels 0 words). Returns
    (words, label_pos) — words hold ints, or ('label', name) refs, or None
    for symbols the compiler resolves (RGBDS names)."""
    from . import scriptgen as SG
    code_by_name = {}
    for n, (c, _k) in SG.OPS.items():
        code_by_name.setdefault(n, c)
    for c, o in SO.OPS.items():
        code_by_name.setdefault(o.name, c)
    words, labels = [], {}
    for it in ops:
        if isinstance(it, str):
            if it.startswith('label:'):
                labels[it.split(':', 1)[1]] = len(words)
            continue
        head = it[0]
        if head == 'end':
            words.append(0xFFFF)
        elif head == 'text':
            words.append(_pv(it[1]))
        elif head == 'op':
            name = it[1]
            code = code_by_name.get(name) if isinstance(name, str) else None
            if code is None:
                code = _pv(name)
            words.append(0xFF00 | ((code or 0) & 0xFF))
            for prm in it[2:]:
                s = str(prm)
                words.append(('label', s[1:]) if s.startswith('@') else _pv(prm))
    return words, labels


def decode_project(script):
    """A project script dict ({'id', 'ops'}) -> Script (pos = word index =
    the counter value in game, since the compiler emits word for word)."""
    words, labels = project_words(script.get('ops') or [])

    def read(a):
        i = a // 2
        if not 0 <= i < len(words):
            return None
        w = words[i]
        if isinstance(w, tuple):
            return labels.get(w[1], 0) * 2
        return 0 if w is None else w
    sc = Script(('project', script.get('id')), decode_words(read, 0), None, 0,
                f"project script {script.get('id')}")
    sc.labels = {v: k for k, v in labels.items()}
    return sc


# ------------------------------------------------------------------ scenes

SHOW_KINDS = {'actor', 'world', 'screen', 'battle'}

Scene = namedtuple('Scene', 'script entry steps path title trigger shows')


def is_showy(st):
    if st.code >= 0x100:
        return False
    k = SO.OPS[st.code].kind
    if k in SHOW_KINDS:
        if st.code in (0x0D,) and st.params[1] not in (0, 0x18, 0x1A, 0xFF90):
            return False
        return True
    return False


def scenes_of(script, min_show=1):
    """The script's scenes: every block head whose straight run (to the next
    head / terminal) shows something, with the path condition from pos 0."""
    out = []
    for h in script.entries():
        run = script.run_from(h, stop_at_heads=True)
        shows = sum(1 for st in run if is_showy(st))
        if shows < min_show:
            continue
        path = script.path_to(h)
        out.append(Scene(script, h, run, path, '', None, shows))
    return out


# ------------------------------------------------------------- room context

class Rooms:
    """Vanilla room facts for actors and triggers (extracted/map_table.json,
    VanillaTable's valid-step rule) + names."""

    def __init__(self, repo=REPO):
        from .vanilla import VanillaTable
        self.vt = VanillaTable(repo)
        try:
            names = json.load(open(os.path.join(repo, 'extracted', 'npc_names.json')))
            self.sprite_names = {int(k, 16): v for k, v in
                                 names.get('sprite_names', {}).items() if v and k.startswith('0x')}
        except (OSError, ValueError):
            self.sprite_names = {}

    def name(self, mid):
        e = self.vt.entries.get(mid)
        return e['name'].replace(', crashes', '') if e else f'map ${mid:02X}'

    def screens(self, mid):
        e = self.vt.entries.get(mid)
        return [sr['c925'] for sr in e['sub_rooms']] if e else []

    def steps(self, mid, scr):
        try:
            return self.vt.valid_steps(mid, scr)
        except KeyError:
            return []

    def counter(self, mid, scr):
        try:
            return self.vt.counter(mid, scr)
        except (KeyError, ValueError):
            return None

    def npcs(self, mid, scr, step):
        sts = self.steps(mid, scr)
        if not sts:
            return []
        st = sts[min(step, len(sts) - 1)]
        out = []
        for it in st.get('interact_data', []):
            if it.get('kind') != 'npc':
                continue
            raw = [int(x, 16) for x in it['raw'].split()]
            out.append({'type': raw[0], 'sprite': raw[1], 'x': raw[2], 'y': raw[3],
                        'script': raw[4]})
        return out

    def spots(self, mid, scr, step):
        sts = self.steps(mid, scr)
        if not sts:
            return []
        st = sts[min(step, len(sts) - 1)]
        out = []
        for it in st.get('interact_data', []):
            if it.get('kind') == 'npc':
                continue
            raw = [int(x, 16) for x in it['raw'].split()]
            out.append({'type': raw[0], 'x': raw[2], 'y': raw[3], 'script': raw[4]})
        return out

    def triggers(self, mid, script_idx):
        """How a vanilla script starts: [(kind, screen, step, x, y, detail)]."""
        if script_idx == 0:
            return [('entry', None, None, None, None, 'entering the room')]
        out = []
        for scr in self.screens(mid):
            for k, st in enumerate(self.steps(mid, scr)):
                n = 0
                for it in st.get('interact_data', []):
                    raw = [int(x, 16) for x in it['raw'].split()]
                    if it.get('kind') == 'npc':
                        n += 1
                        if raw[4] == script_idx:
                            out.append(('npc', scr, k, raw[2], raw[3],
                                        f'talking to NPC {n} (sprite ${raw[1]:02X})'))
                    elif raw[4] == script_idx and raw[0] in (0x80, 0x81, 0x82, 0x83, 0x8F):
                        out.append(('examine', scr, k, raw[2], raw[3],
                                    f'examining ({raw[2]},{raw[3]})'))
                    elif raw[4] == script_idx and raw[0] == 0x90:
                        out.append(('stepon', scr, k, raw[2], raw[3],
                                    f'stepping on ({raw[2]},{raw[3]})'))
        return out

    def arrivals(self, mid, scr):
        """Player arrival pixels (absolute) of every vanilla exit that lands
        in this map + screen."""
        out = []
        col, row = scr % 4, scr // 4
        for m, e in self.vt.entries.items():
            for sr in e.get('sub_rooms', []):
                for k, st in enumerate(self.steps(m, sr['c925'])):
                    for ex in st.get('exit_data', []):
                        if ex.get('dest_map_type') != mid:
                            continue
                        sx, sy = ex.get('spawn_x', 0), ex.get('spawn_y', 0)
                        if sx // 10 == col and sy // 8 == row:
                            out.append((sx * 16 + 8, sy * 16 + 8))
        return out


# ------------------------------------------------------------------ actors

class ActorState:
    __slots__ = ('x', 'y', 'face', 'shown', 'sprite', 'name')

    def __init__(self, x, y, face, shown, sprite, name):
        self.x, self.y, self.face, self.shown = x, y, face, shown
        self.sprite, self.name = sprite, name

    def copy(self):
        return ActorState(self.x, self.y, self.face, self.shown, self.sprite, self.name)

    def as_tuple(self):
        return (self.x, self.y, self.face, self.shown)


_SPEAKER = re.compile(r'^([A-Za-z][A-Za-z .\'&-]{0,13}):')


def script_speaker(script, text):
    """The name an NPC's OWN talk script gives its speaker: the "Name:" in
    front of the first text that has one ("King:Oh [HERO]!" → King). None
    when its texts are anonymous ("*:…"). S118g (user: "why are random
    things named Warubou?" — the old names came from a hand-made sprite
    table, sprite $0B = "Watabou / generic helper"; this reads the game's
    own dialogue instead)."""
    if script is None:
        return None
    for pos in script.order:
        st = script.steps[pos]
        if st.code == TEXT and st.params:
            t = (text(st.params[0]) or '').lstrip()
            if t.startswith('*'):
                return None
            mm = _SPEAKER.match(t)
            if mm and mm.group(1).strip().upper() not in ('[HERO]', 'HERO'):
                return mm.group(1).strip()
            return None
    return None


def initial_actors(npcs, scr, player_xy=None, player_face=0, sprite_names=None):
    """{0: player, 1..: NPCs} in absolute pixels (npc entry tiles are
    screen-local; + the screen's grid offset)."""
    sprite_names = sprite_names or {}
    col, row = scr % 4, scr // 4
    acts = {}
    px, py = player_xy or ((col * 10 + 5) * 16 + 8, (row * 8 + 4) * 16 + 8)
    acts[0] = ActorState(px, py, player_face, True, None, 'Terry')
    for i, n in enumerate(npcs, 1):
        acts[i] = ActorState((col * 10 + n['x']) * 16 + 8, (row * 8 + n['y']) * 16 + 8,
                             (n['type'] >> 4) & 3, not (n['type'] & 0x40), n['sprite'],
                             n.get('speaker') or sprite_names.get(n['sprite'], ''))
    return acts


NPC_SLOTS = 0xD7D2              # NPC n = slot n-1, 32 bytes each (+0 type, +$18 X, +$1A Y)
WALK_FRAMES_PER_PX = 4 / 3      # 1 px on 3 of every 4 frames (PyBoy S118)


def apply_step(acts, st, pending, ctx=None):
    """Advance the actor model by one step. pending = {actor: [dx, dy, frames]}
    queued walks / programs and the frames they still need; they complete at
    the next wait, during a walk the script waits for, a text, or once delays
    have covered their time (actors move in parallel with the script)."""
    c, p = st.code, st.params
    if c >= 0x100:
        flush(acts, pending)          # a text box (or the end) outlasts any walk
        return
    a = acts.get(p[0]) if p else None
    if c in (0x1A, 0x1B):
        d = SO.s16(p[1])
        q = pending.setdefault(p[0], [0, 0, 0])
        q[0 if c == 0x1A else 1] += d
        q[2] += abs(d) * WALK_FRAMES_PER_PX
    elif c == 0x1C:
        prog, n = (p[0] >> 8) & 0xFF, p[0] & 0xFF
        pr = SO.program(prog, n)
        if n and 0x15 <= prog <= 0x18 and ctx is not None:
            fl = SO.FLY.get((prog, ctx.get('e3', 3), ctx.get('e4', 3)))
            if fl:
                pr = pr._replace(dx=fl[0], dy=fl[1], frames=fl[2])
        if pr.xlow and n in acts:
            flush(acts, pending, only=n)
            a2 = acts[n]
            a2.x = (a2.x & 0xFF00) | ((a2.x + pr.dx) & 0xFF)
            a2.y += pr.dy
        else:
            q = pending.setdefault(n, [0, 0, 0])
            q[0] += pr.dx
            q[1] += pr.dy
            q[2] += pr.frames
        if pr.show is not None and n in acts:
            acts[n].shown = pr.show
    elif c in (0x0A, 0x0B) and a is not None:
        flush(acts, pending)
        d = SO.s16(p[1])
        if c == 0x0A:
            a.x += d
            a.face = 3 if d > 0 else 1 if d < 0 else a.face
        else:
            a.y += d
            a.face = 0 if d > 0 else 2 if d < 0 else a.face
    elif c in (0x10, 0x11) and a is not None:
        flush(acts, pending)
        t = SO.s16(p[1])
        if c == 0x10:
            a.face = 3 if t > a.x else 1 if t < a.x else a.face
            a.x = t
        else:
            a.face = 0 if t > a.y else 2 if t < a.y else a.face
            a.y = t
    elif c in (0x47, 0x48, 0x49, 0x4A) and a is not None:
        a.face = {0x47: 2, 0x48: 0, 0x49: 1, 0x4A: 3}[c]
    elif c == 0x0C and a is not None:
        a.face = p[1] & 3
    elif c == 0x0D:
        if p[0] == 0 and p[1] == 0xFF90:
            acts[0].shown = not (p[2] & 0x40)
        elif p[0] and a is not None:
            if p[1] == 0:
                a.shown = not (p[2] & 0x40)
            elif p[1] == 0x18:
                a.x = (a.x & 0xFF00) | (p[2] & 0xFF)
            elif p[1] == 0x1A:
                a.y = (a.y & 0xFF00) | (p[2] & 0xFF)
    elif c in (0x12, 0x13) and p and p[0] in (0xD8E3, 0xD8E4) and ctx is not None:
        if p[0] == 0xD8E3:
            ctx['e3'] = p[1] & 0xFF
            if c == 0x13:
                ctx['e4'] = (p[1] >> 8) & 0xFF
        else:
            ctx['e4'] = p[1] & 0xFF
    elif c in (0x12, 0x13) and p and NPC_SLOTS <= p[0] < NPC_SLOTS + 32 * 8:
        # a plain RAM write into the NPC slot table (the Starry Shrine and the
        # arena place their cast this way): slot n-1 field off
        n, off = (p[0] - NPC_SLOTS) // 32 + 1, (p[0] - NPC_SLOTS) % 32
        a = acts.get(n)
        if a is not None:
            v = p[1] & (0xFF if c == 0x12 else 0xFFFF)
            vals = [(off, v & 0xFF)] + ([(off + 1, v >> 8)] if c == 0x13 else [])
            for o, b in vals:
                if o == 0:
                    a.shown = not (b & 0x40)
                elif o == 0x18:
                    a.x = (a.x & 0xFF00) | b
                elif o == 0x19:
                    a.x = (a.x & 0xFF) | (b << 8)
                elif o == 0x1A:
                    a.y = (a.y & 0xFF00) | b
                elif o == 0x1B:
                    a.y = (a.y & 0xFF) | (b << 8)
    elif c == 0x19:
        flush(acts, pending)
    elif c in (0x09, 0x4D):
        spent = p[0] * (8 if c == 0x09 else 1)
        for n in list(pending):
            pending[n][2] -= spent
            if pending[n][2] <= 0:
                flush(acts, pending, only=n)


def flush(acts, pending, only=None):
    for n in list(pending):
        if only is not None and n != only:
            continue
        q = pending.pop(n)
        dx, dy = q[0], q[1]
        a = acts.get(n)
        if a is None:
            continue
        a.x += dx
        a.y += dy
        if dy:
            a.face = 0 if dy > 0 else 2
        elif dx:
            a.face = 3 if dx > 0 else 1


def actor_frames(acts, steps, pending=None):
    """[(step, {n: ActorState})] — the state AFTER each step. pending = walks
    already queued when the replay starts ({actor: [dx, dy]})."""
    acts = {k: v.copy() for k, v in acts.items()}
    pending = {k: (list(v) + [9999])[:3] for k, v in (pending or {}).items()}
    out, ctx = [], {}
    for st in steps:
        apply_step(acts, st, pending, ctx)
        out.append((st, {k: v.copy() for k, v in acts.items()}))
    return out


def moves(scene):
    """Something visibly moves: a walk, a movement program (hop, jump, fly,
    appear / vanish), or an NPC shown / hidden. Turning on the spot and the
    player's own "shown" (every talk script starts with it) do not count — S118
    user report: the egg appraiser's plain talk was listed as a cutscene."""
    for st in scene.steps:
        if st.code in (0x0A, 0x0B, 0x10, 0x11, 0x1A, 0x1B, 0x1C):
            return True
        if st.code == 0x0D and st.params and st.params[0] >= 1 and st.params[1] == 0:
            return True
    return False


def still_notes(scene, npcs, screen, player_xy, facing=0):
    """Walk-to steps that move nobody in this room state: the actor already
    stands where the step sends him (S118 user report — the Old Man Gate
    Room's step-on scene "did nothing": the old man was already there; the
    game does the same)."""
    acts = initial_actors(npcs, screen, player_xy, facing)
    out = []
    for st in scene.steps:
        if st.code in (0x10, 0x11) and st.params and st.params[0] in acts:
            a = acts[st.params[0]]
            have = a.x if st.code == 0x10 else a.y
            if have == SO.s16(st.params[1]):
                who = 'the player' if st.params[0] == 0 else f'NPC {st.params[0]}'
                out.append(f'{who} already stands at {"x" if st.code == 0x10 else "y"} = '
                           f'{have} px at the start — that walk moves nobody (the game does the '
                           'same; in play something else has usually moved him first)')
        pend = {}
        apply_step(acts, st, pend, {})
        flush(acts, pend)
    return out


# ------------------------------------------------------------------ recipes

Recipe = namedtuple('Recipe', 'map screen room_step player facing stands action '
                               'flags_set flags_clear ram script_type script_idx start_pos '
                               'dialog notes names target', defaults=((), None))


def room_recipe(mid, screen, x, y, facing=2):
    """S120 (ROADMAP P3.4): just the room — warp to (screen, x, y) and play from there
    (the room's own entry script runs as in the game). facing 0 down / 1 left / 2 up /
    3 right."""
    col, row = screen % 4, screen // 4
    px, py = (col * 10 + x) * 16 + 8, (row * 8 + y) * 16 + 8
    return Recipe(mid, screen, None, (px, py), facing, (), 'entry', (), (), {}, mid, 0, 0,
                  False, (f'the room ${mid:02X} from screen {screen} ({x},{y})',))


class RoomOnly:
    """A stand-in scene for room_recipe (no steps, no storyboard)."""
    steps = ()

    class script:                                        # noqa: N801
        steps = {}


# action: 'entry'  — warp in; the room-entry script (0) starts by itself
#         'talk'   — stand next to the NPC facing it, press A (the game's own talk)
#         'examine'— stand facing the spot, press A
#         'stepon' — stand next to the spot, walk onto it
#         'arm'    — start the script directly (no trigger found)
#         'newgame'— a new game itself (the bedtime scene, S118e)
#         'walkin' — enter the scene's screen ('target') by walking in from a
#                    neighbouring screen of the same room (stands = edge cells,
#                    facing = the direction to walk; S118e)
#         'head'   — start AT the scene's first step (it plays after a battle
#                    win — the set-up cannot win fights)
# stands: [(px, py, facing)] places to try for talk / examine / stepon.
# names: the insert slots ($F9 nn → $C180 + nn) the scene's texts print — the
#        set-up puts a placeholder name in a slot the game left unfilled
#        (KEY_LESSONS S118: an unfilled slot crashes the game; filling slots a
#        scene does not print crashed the Castle — so only these).


def insert_slots(scene, text):
    """The name slots ($00 / $10 / $20 / $30) the texts of the scene's
    SCRIPT insert (a scene runs on past its own steps into the next ones)."""
    out = set()
    for st in scene.script.steps.values():
        if st.code == TEXT and st.params:
            for h in re.findall(r'\[INS ([0-9A-Fa-f]{2})\]', text(st.params[0]) or ''):
                if int(h, 16) < 0x40:
                    out.add(int(h, 16))
    return tuple(sorted(out))

def _consistent(lit, fixed):
    """Is a literal compatible with a set of fixed literals?"""
    k = lit[0]
    for f in fixed:
        if f[0] != k:
            continue
        if k == 'flag' and f[1] == lit[1] and f[2] != lit[2]:
            return False
        if k == 'screen':
            if lit[2] and f[2] and lit[1] != f[1]:
                return False
            if lit[1] == f[1] and lit[2] != f[2]:
                return False
        if k == 'ram' and f[1] == lit[1]:
            if lit[3] and f[3] and lit[2] != f[2]:
                return False
            if lit[2] == f[2] and lit[3] != f[3]:
                return False
        if k == 'test' and f[1] == lit[1] and f[2] != lit[2]:
            return False
    return True


def quiet_literals(script, fixed):
    """Literals that make a room-entry script end while SHOWING as little as
    possible (Dijkstra on the number of showy steps), compatible with the
    fixed literals (the scene's own). Used when a talk / examine scene is set
    up: the room's entry script runs first on arrival and must not play some
    other scene. Returns (literals, showy_count) or (None, None)."""
    import heapq
    fixed = list(fixed)
    start = (0, 0, ())
    heap = [start]
    best = {}
    while heap:
        cost, pos, lits = heapq.heappop(heap)
        st = script.steps.get(pos)
        if st is None:
            continue
        if best.get(pos, 1 << 30) <= cost and pos in best:
            continue
        best[pos] = cost
        if st.code == END:
            return list(lits), cost
        c2 = cost + (1 if is_showy(st) else 0) + (100 if st.code in SO.TERMINAL else 0)
        if st.code in SO.TERMINAL:
            continue
        for nxt, lit in script.successors(st):
            nl = lits
            if lit is not None:
                if not _consistent(lit, fixed + list(lits)):
                    continue
                nl = lits + (lit,)
            heapq.heappush(heap, (c2, nxt, nl))
    return None, None


_SIDES = ((0, 1, 2), (0, -1, 0), (-1, 0, 3), (1, 0, 1))   # (dx, dy, facing toward)


PLAYER_POS_RAM = {0xFF92: 'x', 0xFF95: 'y', 0xFF97: 'tx', 0xFF98: 'ty'}


def _lits_to_state(lits, notes, pos_out=None):
    """flags / RAM / screen from path literals. A test of the PLAYER'S
    position (HRAM $FF92 x, $FF95 y, $FF97/$FF98 tile — e.g. the Bazaar
    counter) is never poked (a stray HRAM write wedges the game — measured
    S118): an equality goes to pos_out[...] for the recipe to stand there."""
    flags_set, flags_clear, ram, ram_ne = set(), set(), {}, {}
    screen_eq, screen_ne = None, set()
    for lit in lits:
        if lit[0] == 'ram' and lit[1] >= 0xFF80:
            if lit[3] and lit[1] in PLAYER_POS_RAM and pos_out is not None:
                pos_out[PLAYER_POS_RAM[lit[1]]] = lit[2]
            elif lit[3]:
                notes.append(f'needs ${lit[1]:04X} = {lit[2]} (not set)')
            continue
        if lit[0] == 'flag':
            (flags_set if lit[2] else flags_clear).add(lit[1])
        elif lit[0] == 'screen':
            if lit[2]:
                screen_eq = lit[1]
            else:
                screen_ne.add(lit[1])
        elif lit[0] == 'ram':
            if lit[3]:
                ram[lit[1]] = lit[2]
            else:
                ram_ne.setdefault(lit[1], set()).add(lit[2])
        else:
            notes.append(('needs: ' if lit[2] else 'needs NOT: ') + lit[1])
    for addr, bad in ram_ne.items():
        if addr not in ram:
            v = 0
            while v in bad:
                v += 1
            ram[addr] = v
    for f in flags_set & flags_clear:
        notes.append(f'flag ${f:04X} is tested both ways')
        flags_clear.discard(f)
    return flags_set, flags_clear, ram, screen_eq, screen_ne


def _apply_pos(xy, pos, notes):
    """Put the player where a position test wants him (low bytes / tiles)."""
    x, y = xy
    if 'x' in pos:
        x = (x & 0xFF00) | pos['x']
    if 'y' in pos:
        y = (y & 0xFF00) | pos['y']
    if 'tx' in pos:
        x = pos['tx'] * 16 + 8
    if 'ty' in pos:
        y = pos['ty'] * 16 + 8
    if notes is not None and pos:
        notes.append('the player stands where the scene tests his position')
    return (x, y)


def scene_literals(scene):
    """The path literals + every conditional the scene's own run falls through."""
    lits = list(scene.path or [])
    for st in scene.steps:
        if st.target is not None and st.code != 0x14:
            for nxt, lit in scene.script.successors(st):
                if lit is not None and nxt != st.target:
                    lits.append(lit)
    return lits


ACTOR_OPS = {0x0A, 0x0B, 0x10, 0x11, 0x1A, 0x1B, 0x1C, 0x47, 0x48, 0x49, 0x4A, 0x0D}


def npc_actors_needed(scene, ctr=None):
    """The highest NPC number the scene acts on before it changes the room
    state itself (a write to the screen's counter, a room reload / change)."""
    need = 0
    for st in scene.steps:
        if (st.code == 0x12 and ctr is not None and st.params[0] == ctr) or \
                st.code in (0x26, 0x0F, 0x3B):
            break
        if st.code in ACTOR_OPS and st.params:
            need = max(need, st.params[0] & 0xFF)
    return need


NEWGAME_MAP, NEWGAME_SCREEN = 0x2F, 4      # the bedroom a new game starts in


def newgame_scene(scene, mid, r):
    """The room-entry scene a fresh new game plays: the bedroom's script 0 at a
    branch whose conditions all hold in a zeroed game (flags clear, RAM 0,
    the start screen)."""
    if mid != NEWGAME_MAP or scene.script.key[2] != 0 or r.action != 'entry':
        return False
    for lit in scene_literals(scene):
        if lit[0] == 'flag' and lit[2]:
            return False
        if lit[0] == 'ram' and (lit[2] == 0) != lit[3]:
            return False
        if lit[0] == 'screen' and (lit[1] == NEWGAME_SCREEN) != lit[2]:
            return False
        if lit[0] == 'test':
            return False
    return True


def recipe_for(scene, mid, rooms=None, player_xy=None, script_type=None,
               quiet_entry=None, state_hint=None):
    """How to play a scene without walking there (see the module doc).
    quiet_entry = the room's entry Script (vanilla script 0) — for a talk /
    examine / step-on scene its conditions are chosen so it shows as little
    as possible (it runs first on arrival)."""
    rooms = rooms or Rooms()
    notes = []
    lits = scene_literals(scene)
    _fs, _fc, _ram, screen_eq, screen_ne = _lits_to_state(lits, [])
    screens = rooms.screens(mid) or [0]
    idx = scene.script.key[2] if scene.script.key[0] == 'vanilla' else None
    trig = rooms.triggers(mid, idx) if idx is not None else []
    scr = screen_eq
    if scr is None:
        tscr = [t[1] for t in trig if t[1] is not None]
        cands = [s for s in (tscr or screens) if s not in screen_ne]
        scr = cands[0] if cands else screens[0]
    if idx and quiet_entry is not None:
        q, n = quiet_literals(quiet_entry, lits + [('screen', scr, True)])
        if q is not None:
            lits = lits + q
            if n:
                notes.append(f'the room-entry script shows {n} step(s) first')
        else:
            notes.append('the room-entry script cannot be kept quiet')
    pos = {}
    flags_set, flags_clear, ram, _se, _sn = _lits_to_state(lits, notes, pos)
    ctr = rooms.counter(mid, scr)
    step = 0
    need = npc_actors_needed(scene, ctr)
    if ctr is not None and ctr in ram:
        step = ram[ctr]
        if need and len(rooms.npcs(mid, scr, step)) < need:
            # the path tested the counter; a sibling test of the same counter that
            # branches to the same place is another way in (Castle screen 1:
            # $D92B = 0 or 4) — take the one whose state holds the NPCs
            same = {st.target for st in scene.script.steps.values()
                    if st.code == 0x15 and st.params[0] == ctr and (st.params[1] & 0xFF) == step}
            alt = sorted({st.params[1] & 0xFF for st in scene.script.steps.values()
                          if st.code == 0x15 and st.params[0] == ctr and st.target in same})
            ok = [k for k in alt if len(rooms.npcs(mid, scr, k)) >= need]
            if ok and ok[0] != step:
                notes.append(f'room state {ok[0]}: the other state the script accepts here, '
                             f'with NPC {need}')
                step = ram[ctr] = ok[0]
    else:
        here = [t for t in trig if t[1] == scr and t[2] is not None]
        hint = state_hint(ctr, flags_set, flags_clear) if (state_hint and ctr is not None) \
            else None
        if hint is not None and (not here or any(t[2] == hint[0] for t in here)):
            step = hint[0]
            notes.append(f'room state {step}: {hint[1]}')
        elif here:
            step = here[0][2]
        # the state must hold the NPCs the scene moves (S118 user report: the
        # wrong NPC acted) — else the first state that does (a talk scene: one
        # of the states its NPC is in)
        if need and len(rooms.npcs(mid, scr, step)) < need:
            cands = [t[2] for t in here] or list(range(len(rooms.steps(mid, scr))))
            ok = [k for k in cands if len(rooms.npcs(mid, scr, k)) >= need]
            if ok:
                notes.append(f'room state {ok[0]}: the first state with NPC {need}')
                step = ok[0]
        if ctr is not None:
            ram[ctr] = step
    nsteps = len(rooms.steps(mid, scr))
    if nsteps and step >= nsteps:
        notes.append(f"room state {step} is past the screen's {nsteps} valid states")
    col, row = scr % 4, scr // 4
    action, stands, facing = ('entry' if not idx else 'arm'), [], 0
    if scene.entry and scene.script.after_battle(scene.entry):
        # a scene after a battle (a boss room's exit, the King's prize …):
        # the set-up cannot win the fight — start at the scene's own first step
        notes.append('plays after a battle is won: started at its own first step')
        action = 'head'
    tr = [t for t in trig if t[1] == scr and t[0] in ('npc', 'examine', 'stepon')
          and t[2] == step] or [t for t in trig if t[1] == scr]
    if tr and idx and action != 'head':
        t = tr[0]
        action = {'npc': 'talk'}.get(t[0], t[0])
        for dx, dy, face in _SIDES:
            x, y = t[3] + dx, t[4] + dy
            if 0 <= x < 10 and 0 <= y < 8:
                stands.append(((col * 10 + x) * 16 + 8, (row * 8 + y) * 16 + 8, face))
    if player_xy is None:
        if stands:
            player_xy, facing = stands[0][:2], stands[0][2]
        else:
            arr = rooms.arrivals(mid, scr)
            player_xy = arr[0] if arr else ((col * 10 + 5) * 16 + 8, (row * 8 + 4) * 16 + 8)
    player_xy = _apply_pos(player_xy, pos, notes)
    if pos and stands:
        stands = [(_apply_pos((x, y), pos, None) + (f,)) for x, y, f in stands]
    dialog = action in ('talk', 'examine', 'arm', 'head') and bool(idx)
    return Recipe(mid, scr, step, tuple(player_xy), facing, stands, action,
                  sorted(flags_set), sorted(flags_clear), ram,
                  mid if script_type is None else script_type, idx or 0, scene.entry,
                  dialog, notes)


def scene_title(scene, text):
    """A short name: the first text's words, else the first showy step."""
    for st in scene.steps:
        if st.code == TEXT:
            t = (text(st.params[0]) or '').replace('\n', ' ').strip()
            if t:
                return ' '.join(t.split())[:48]
    for st in scene.steps:                     # the first thing that moves
        if moves(Scene(scene.script, st.pos, [st], None, '', None, 1)):
            return SO.sentence(st.code, st.params)[:48]
    for st in scene.steps:
        if is_showy(st) and not (st.code == 0x0D and st.params and st.params[0] == 0):
            return SO.sentence(st.code, st.params)[:48]
    return f'step {scene.entry}'


# ------------------------------------------------------------- the catalogue

class Catalogue:
    """Every vanilla script scene + the project's (lazy per map)."""

    def __init__(self, rom, repo=REPO):
        self.rom = rom
        self.rooms = Rooms(repo)
        self._scripts = {}
        self._text = None
        self.repo = repo

    def text(self, tid):
        if self._text is None:
            try:
                d = json.load(open(os.path.join(self.repo, 'extracted', 'dialogue.json'),
                                   encoding='utf-8'))
                self._text = {int(e['id'][1:], 16): e['text'] for e in d['text_ids']}
            except (OSError, ValueError, KeyError):
                self._text = {}
        return self._text.get(tid, '')

    def map_types(self):
        return sorted(m for m in self.rooms.vt.entries if m < CUSTOM_ROOM_START)

    def scripts(self, mid):
        if mid not in self._scripts:
            out = []
            try:
                ptrs = vanilla_script_ptrs(self.rom, mid)
            except Exception:
                ptrs = []
            for i in range(len(ptrs)):
                try:
                    out.append(decode_vanilla(self.rom, mid, i))
                except Exception:
                    out.append(None)
            self._scripts[mid] = out
        return self._scripts[mid]

    def scenes(self, mid):
        out = []
        for sc in self.scripts(mid):
            if sc is None:
                continue
            out.extend(scenes_of(sc))
        return out

    def state_hint(self, ctr, flags_set, flags_clear):
        """The room state (a screen's step counter) the game is in when a
        scene's flags hold — for scenes whose own conditions do not test the
        counter. Every vanilla script block that WRITES the counter is scored
        by the flags it sets in the same straight run: +1 per flag the scene
        needs set, -1 per flag the scene needs clear (that block runs later).
        Measured S118 (user report): GreatTree screen 0's "Oh boy! This looks
        dangerous!" needs flag $0009 — set by the Castle block that also
        writes $D92D := 2; with the default state 0 the wrong NPC (the old
        man) was NPC 1. Returns (value, why) or None."""
        if not hasattr(self, '_writes'):
            self._writes = {}
            for m in self.map_types():
                for sc in self.scripts(m):
                    if sc is None:
                        continue
                    for h in sc.entries():
                        run = sc.run_from(h, stop_at_heads=True)
                        sets = {st.params[0] for st in run if st.code == 0x03}
                        for st in run:
                            if st.code == 0x12:
                                self._writes.setdefault(st.params[0], []).append(
                                    (st.params[1] & 0xFF, sets, (m, sc.key[2], h)))
        best = None
        for val, sets, where in self._writes.get(ctr, []):
            if not sets & set(flags_set):
                continue
            score = len(sets & set(flags_set)) - len(sets & set(flags_clear))
            if score > 0 and (best is None or score > best[0]):
                best = (score, val, where, sorted(sets & set(flags_set)))
        if best is None:
            return None
        _sc, val, (m, i, h), fl = best
        return val, (f'as room ${m:02X} script {i} leaves it when it sets flag '
                     + ', '.join(f'${f:04X}' for f in fl))

    def entry_caller(self, mid, r):
        """The script block that sends the player into this room in a way the
        scene's RAM conditions expect: a block ending in a room change to `mid`
        whose RAM writes give the values the scene tests (+1 each, -1 for a
        different value). Returns ((map, script, head), (x, y), {addr: value},
        {flags set}) or None."""
        want = {a: v for a, v in r.ram.items()}
        if not want:
            return None
        best = None
        for m in self.map_types():
            for sc in self.scripts(m):
                if sc is None:
                    continue
                for h in sc.entries():
                    run = sc.run_from(h, stop_at_heads=True)
                    writes, fls = {}, set()
                    for st in run:
                        if st.code == 0x12 and not (0xC88A <= st.params[0] <= 0xC88E or
                                                    0xC89B <= st.params[0] <= 0xC89D):
                            # (not the game-mode block or the fade registers)
                            writes[st.params[0]] = st.params[1] & 0xFF
                        elif st.code == 0x03:
                            fls.add(st.params[0])
                        elif st.code in (0x0F, 0x3B) and (st.params[0] & 0xFF) == mid:
                            score = sum((1 if writes[a] == v else -1)
                                        for a, v in want.items() if a in writes)
                            if score > 0 and (best is None or score > best[0]):
                                xy = (SO.s16(st.params[1]), SO.s16(st.params[2]))
                                best = (score, (m, sc.key[2], h), xy, dict(writes), set(fls))
                            break
        if best is None:
            return None
        return best[1:]

    def room_origin(self, mid, limit=3):
        """How the game itself gets the player into a room — its exit tables
        (extracted/all_exits.json, dumped from the ROM) and the scripts' room
        changes. S118g (user: "ARE YOU NOT TAKING THIS INFO FROM GAME?"): room
        NAMES are editor labels (dwm/map_names.py, typed by people); this
        line is what anchors them to the game."""
        if not hasattr(self, '_origin'):
            self._origin = {}
            try:
                for e in json.load(open(os.path.join(self.repo, 'extracted', 'all_exits.json'))):
                    if e['dest_mt'] != e['src_mt']:
                        self._origin.setdefault(e['dest_mt'], []).append(
                            f"{self.rooms.name(e['src_mt'])} screen {e['screen'] & 0x0F} door "
                            f"({e['trigger_x']}, {e['trigger_y']})")
            except (OSError, ValueError, KeyError):
                pass
            for m in self.map_types():
                for sc in self.scripts(m):
                    if sc is None:
                        continue
                    for st in sc.steps.values():
                        if st.code in (0x0F, 0x3B) and (st.params[0] & 0xFF) != m:
                            self._origin.setdefault(st.params[0] & 0xFF, []).append(
                                f'{self.rooms.name(m)} script {sc.key[2]} (a scripted move)')
        seen = []
        for w in self._origin.get(mid, []):
            if w not in seen:
                seen.append(w)
        return seen[:limit], max(0, len(seen) - limit)

    # ---------------------------------------------- words for flags (S118f)
    def flag_desc(self, n):
        """What an event flag means: a known name (arena classes, gates
        cleared, EVENT_FLAGS "Key Flags"), else where the game SETS it —
        "set in <room>: «the scene's first words»"."""
        if not hasattr(self, '_flag_names'):
            names = {0x30 + i: f'arena class {c} won' for i, c in enumerate('GFEDCBAS')}
            names.update({0x0002: 'the starter monster given', 0x0025: 'Durran defeated',
                          0x00F1: 'the post-game (Starry Night champion)'})
            try:
                gd = json.load(open(os.path.join(self.repo, 'extracted', 'gate_names.json')))
                for g in gd.get('gates', []):
                    for f in g.get('cleared_flags') or []:
                        names.setdefault(int(f, 16), f"{g['name']} cleared")
            except (OSError, ValueError, KeyError):
                pass
            self._flag_names = names
            self._flag_set = {}
            for m in self.map_types():
                for sc in self.scripts(m):
                    if sc is None:
                        continue
                    for scn in scenes_of(sc, min_show=0):
                        for st in scn.steps:
                            if st.code == 0x03 and st.params:
                                self._flag_set.setdefault(st.params[0], (m, scn))
        if n in self._flag_names:
            return self._flag_names[n]
        hit = self._flag_set.get(n)
        if hit is None:
            if n == 0x0007:      # $12:$4EBC (S118f): Pulio's pick-up into an empty party
                return 'a monster taken from the farm (Pulio) into an empty party'
            if 0x0050 <= n <= 0x0057:
                return f'medal egg {n - 0x50 + 1} received (set by the game\'s code)'
            return 'never set anywhere — this test is always false'
        m, scn = hit
        return f'set in {self.rooms.name(m)}: «{scene_title(scn, self.text)[:40]}»'

    def gate_arrivals(self, mid, scr):
        """A boss room's arrival (the gate's GateFloorDataTable row, $16:$70A6:
        byte 4 = boss map, bytes 5/6 = arrival tile; GATE_GENERATION §7.7)."""
        if not hasattr(self, '_gate_arr'):
            self._gate_arr = {}
            base = 0x16 * 0x4000 + (0x70A6 - 0x4000)
            for g in range(32):
                row = self.rom[base + 8 * g: base + 8 * g + 8]
                if len(row) == 8:
                    x, y = row[5] * 16 + 8, row[6] * 16 + 8
                    k = (row[4], (y // 128) * 4 + x // 160)
                    self._gate_arr.setdefault(k, []).append((x, y))
        return self._gate_arr.get((mid, scr), [])

    def walk_in(self, mid, scr):
        """(neighbour screen, [(x, y, facing)]) — the edge cells of the first
        neighbouring screen of the same room, facing the scene's screen."""
        have = set(self.rooms.screens(mid))
        col, row = scr % 4, scr // 4
        for dc, dr, face in ((-1, 0, 3), (1, 0, 1), (0, -1, 0), (0, 1, 2)):
            c2, r2 = col + dc, row + dr
            if not (0 <= c2 < 4 and 0 <= r2 < 4) or (r2 * 4 + c2) not in have:
                continue
            out = []
            if dc:
                x = (col * 10 - 1) * 16 + 8 if dc < 0 else ((col + 1) * 10) * 16 + 8
                for cy in (4, 3, 5, 2, 6, 1):
                    out.append((x, (row * 8 + cy) * 16 + 8, face))
            else:
                y = (row * 8 - 1) * 16 + 8 if dr < 0 else ((row + 1) * 8) * 16 + 8
                for cx in (5, 4, 6, 3, 7, 2, 8, 1):
                    out.append(((col * 10 + cx) * 16 + 8, y, face))
            return r2 * 4 + c2, out
        return None

    def script_arrivals(self, mid, scr):
        """Arrival pixels of every vanilla SCRIPT room change (map_transition /
        warp_fade) into this map + screen — the arrival a chained scene
        expects (the intro legs up GreatTree)."""
        if not hasattr(self, '_arr'):
            self._arr = {}
            for m in self.map_types():
                for sc in self.scripts(m):
                    if sc is None:
                        continue
                    for st in sc.steps.values():
                        if st.code in (0x0F, 0x3B):
                            x, y = SO.s16(st.params[1]), SO.s16(st.params[2])
                            k = (st.params[0] & 0xFF, (y // 128) * 4 + x // 160)
                            self._arr.setdefault(k, []).append((x, y))
        return self._arr.get((mid, scr), [])

    def recipe(self, scene, mid):
        """recipe_for with this catalogue's knowledge (quiet entry script,
        script arrivals for room-entry scenes)."""
        sc0 = self.scripts(mid)[0] if self.scripts(mid) else None
        r = recipe_for(scene, mid, self.rooms, quiet_entry=sc0, state_hint=self.state_hint)
        r.notes.extend(still_notes(scene, self.rooms.npcs(mid, r.screen, r.room_step),
                                   r.screen, r.player, r.facing))
        r = r._replace(names=insert_slots(scene, self.text))
        if r.action == 'entry' and newgame_scene(scene, mid, r):
            # S118e: the scene a NEW GAME plays (Milayou and Terry's bedtime) —
            # played from the new game itself, not set up
            return r._replace(action='newgame', notes=r.notes + [
                'the opening of a new game — played from a new game itself'])
        if r.action == 'entry':
            caller = self.entry_caller(mid, r)
            if caller is not None:
                # S118c (user: the "Arena Rooms" scene reset the game) — an entry
                # scene that the game reaches through another script's room
                # change is set up the way that script leaves the game: its
                # arrival (screen + spot) and its RAM writes / flags
                (cm, ci, ch), (x, y), writes, fls = caller
                ram = dict(writes)
                ram.update(r.ram)
                scr = (y // 128) * 4 + x // 160
                ctr = self.rooms.counter(mid, scr)
                if ctr is not None and ctr not in ram:
                    ram[ctr] = r.room_step
                r = r._replace(screen=scr, player=(x, y), ram=ram,
                               flags_set=sorted(set(r.flags_set) | (fls - set(r.flags_clear))),
                               notes=r.notes + [f'set up as room ${cm:02X} script {ci} leaves the '
                                                f'game when it sends you here (screen {scr})'])
            else:
                arr = self.script_arrivals(mid, r.screen) or self.gate_arrivals(mid, r.screen)
                if arr:
                    r = r._replace(player=arr[0])
                elif not self.rooms.arrivals(mid, r.screen):
                    # S118e: no door / script / gate leads onto this screen — the
                    # player walks in from the next screen of the room (the
                    # bedroom's east room: Warubou's scene); it was the screen
                    # centre before, a place the player never stands
                    wk = self.walk_in(mid, r.screen)
                    if wk is not None:
                        nscr, cands = wk
                        # the neighbour screen's own entry branch kept quiet
                        sc0 = self.scripts(mid)[0] if self.scripts(mid) else None
                        if sc0 is not None:
                            lits = scene_literals(scene)
                            q, _n = quiet_literals(sc0, lits + [('screen', nscr, True)])
                            if q:
                                fs, fc, rm, _a, _b = _lits_to_state(q, [])
                                r = r._replace(
                                    flags_set=sorted((set(r.flags_set) | set(fs)) - set(r.flags_clear)),
                                    flags_clear=sorted((set(r.flags_clear) | set(fc)) - set(r.flags_set)))
                                for a, v in rm.items():
                                    r.ram.setdefault(a, v)
                        r = r._replace(action='walkin', target=r.screen, screen=nscr,
                                       player=cands[0][:2], stands=cands,
                                       notes=r.notes + [f'the player walks in from screen '
                                                        f'{nscr} (as in the game)'])
                        ctr = self.rooms.counter(mid, nscr)
                        if ctr is not None and ctr not in r.ram:
                            r.ram[ctr] = 0
        return r

    def title(self, scene, mid=None):
        return scene_title(scene, self.text)


# ------------------------------------------------------- the project's scenes

def _dialogue_text(entry):
    """A project dialogue entry's text as one string (boxes / lines / text)."""
    if not isinstance(entry, dict):
        return ''
    if entry.get('boxes'):
        return '\n\n'.join('\n'.join(b) for b in entry['boxes'])
    if entry.get('lines'):
        return '\n'.join(entry['lines'])
    return str(entry.get('text', ''))


class ProjectCatalogue:
    """The project's rooms that have scripts (custom rooms, incl. cloned
    vanilla rooms): their scripts AS BUILT — the compiler's own lowering
    (talk / conversation / shop / quest scripts become ops exactly as they are
    emitted), positions = the words in bank $60, so the live counter maps
    onto them too. symbols: {name: address} from the build's game.sym (RAM
    labels in params, e.g. a room's step counter)."""

    def __init__(self, data, root, symbols=None, rooms=None, vanilla=None):
        import copy
        from .project import Project
        self.prj = Project(copy.deepcopy(data), root)
        self.symbols = dict(symbols or {})
        try:                       # the project's own room-state counters (S118c:
            for lbl, addr, _c in (self.prj.step_counter_allocation()   # an EQU is not
                                  + self.prj.step_counter_game()):     # in game.sym)
                self.symbols.setdefault(lbl, addr)
        except Exception:                                # noqa: BLE001
            pass
        self.rooms = rooms or Rooms()
        self.vanilla = vanilla
        self._scripts = {}

    def flag_desc(self, n):
        """A project flag by its name (custom.flags), else the game's meaning."""
        try:
            for name, idx in self.prj.flag_map().items():
                if idx == n:
                    return f'your flag “{name}”'
        except Exception:                                # noqa: BLE001
            pass
        return self.vanilla.flag_desc(n) if self.vanilla is not None else ''

    def room_list(self):
        out = []
        for r in self.prj.rooms:
            if r.get('placeholder'):
                continue
            mid = _pv(r.get('mapID'))
            if mid is None:
                continue
            out.append((mid, r))
        return out

    def room(self, mid):
        for m, r in self.room_list():
            if m == mid:
                return r
        return None

    def text(self, tid):
        e = getattr(self.prj, '_text_by_id', {}).get(tid)
        if e is not None:
            return _dialogue_text(e)
        if self.vanilla is not None:
            return self.vanilla.text(tid)
        return ''

    def scripts(self, mid):
        if mid not in self._scripts:
            r = self.room(mid)
            out = []
            if r is not None:
                for idx, sid in self.prj.room_script_table(r):
                    try:
                        sc = self.prj.script(sid)
                    except Exception:                     # noqa: BLE001
                        continue
                    s = decode_project(dict(sc, ops=self._resolve(sc.get('ops') or [])))
                    s.key = ('project', mid, idx, sid)
                    out.append(s)
            self._scripts[mid] = out
        return self._scripts[mid]

    def _resolve(self, ops):
        """Replace RGBDS symbols in params by their build address (when the
        build's .sym is known)."""
        if not self.symbols:
            return ops
        out = []
        for it in ops:
            if isinstance(it, list) and it and it[0] == 'op':
                row = list(it[:2])
                for prm in it[2:]:
                    s = str(prm)
                    if not s.startswith('@') and _pv(prm) is None and s in self.symbols:
                        row.append(self.symbols[s])
                    else:
                        row.append(prm)
                out.append(row)
            else:
                out.append(it)
        return out

    def scenes(self, mid, min_show=1):
        out = []
        for sc in self.scripts(mid):
            out.extend(scenes_of(sc, min_show))
        return out

    def npcs(self, mid, screen, state):
        """NPC entries of a screen state in game order (the compiler emits the
        spots first, then the NPCs in list order)."""
        r = self.room(mid)
        if r is None:
            return []
        scr = (r.get('screens') or {}).get(str(screen)) or (r.get('screens') or {}).get(screen)
        if not scr:
            return []
        states = scr.get('states') or [scr]
        st = states[min(state, len(states) - 1)]
        out = []
        from . import formats as F
        for e in st.get('npcs') or []:
            k = e.get('kind')
            if k == 'raw':
                b = [_pv(x) or 0 for x in e['bytes']]
                if b[0] >= 0x80:
                    continue
                out.append({'type': b[0], 'sprite': b[1], 'x': b[2], 'y': b[3], 'script': b[4]})
            elif k == 'npc':
                fac = e.get('facing', 'down')
                t = F.FACING[fac] if isinstance(fac, str) else (_pv(fac) or 0)
                if e.get('hidden'):
                    t |= 0x40
                out.append({'type': t, 'sprite': _pv(e.get('sprite', 0)) or 0,
                            'x': int(e['x']), 'y': int(e['y']), 'script': e.get('script')})
        return out

    def triggers(self, mid, idx):
        if idx == 0:
            return [('entry', None, None, None, None, 'entering the room')]
        r = self.room(mid)
        if r is None:
            return []
        table = dict(self.prj.room_script_table(r))
        sid = table.get(idx)
        out = []
        for key, scr in (r.get('screens') or {}).items():
            states = scr.get('states') or [scr]
            for k, st in enumerate(states):
                n = 0
                for e in st.get('npcs') or []:
                    kind = e.get('kind')
                    if kind == 'raw':
                        b = [_pv(x) or 0 for x in e['bytes']]
                        hit = (b[4] == idx)
                        x, y = b[2], b[3]
                        kind = 'npc' if b[0] < 0x80 else ('stepon' if b[0] & 0xF0 == 0x90 else 'examine')
                    else:
                        hit = e.get('script') in (sid, idx)
                        x, y = e.get('x', 0), e.get('y', 0)
                        kind = {'npc': 'npc', 'examine': 'examine', 'spawn': 'examine',
                                'step': 'stepon'}.get(kind)
                    if kind == 'npc':
                        n += 1
                    if hit and kind:
                        out.append((kind, int(key), k, int(x), int(y),
                                    f'talking to NPC {n}' if kind == 'npc' else f'{kind} ({x},{y})'))
        return out

    def title(self, scene, mid=None):
        return scene_title(scene, self.text)

    def screens(self, mid):
        r = self.room(mid)
        return sorted(int(k) for k in (r.get('screens') or {})) if r else []

    def recipe(self, scene, mid):
        """A Recipe for a project scene (the built ROM): room state = 0 unless
        the path sets the screen's counter; the trigger's side to stand on."""
        notes = []
        lits = scene_literals(scene)
        idx = scene.script.key[2]
        scr0 = self.scripts(mid)[0] if self.scripts(mid) and \
            self.scripts(mid)[0].key[2] == 0 else None
        trig = self.triggers(mid, idx)
        _fs, _fc, _r, screen_eq, screen_ne = _lits_to_state(lits, [])
        screens = self.screens(mid) or [0]
        scr = screen_eq
        if scr is None:
            tscr = [t[1] for t in trig if t[1] is not None]
            cands = [s for s in (tscr or screens) if s not in screen_ne]
            scr = cands[0] if cands else screens[0]
        if idx and scr0 is not None:
            q, n = quiet_literals(scr0, lits + [('screen', scr, True)])
            if q is not None:
                lits = lits + q
        pos = {}
        flags_set, flags_clear, ram, _a, _b = _lits_to_state(lits, notes, pos)
        here = [t for t in trig if t[1] == scr]
        step = here[0][2] if here and here[0][2] is not None else 0
        # S118c: a screen that follows the game's room state — choose the state
        # as for the original room (the story's own counter writes)
        rr = self.room(mid) or {}
        sc_ctr = ((rr.get('screens') or {}).get(str(scr)) or {}).get('step_counter')
        gctr = _pv(sc_ctr.get('vanilla')) if isinstance(sc_ctr, dict) and \
            not rr.get('state_rules') else None
        if gctr is not None:
            if gctr in ram:
                step = ram[gctr]
            elif self.vanilla is not None:
                hint = self.vanilla.state_hint(gctr, flags_set, flags_clear)
                if hint is not None:
                    step = hint[0]
                    notes.append(f'room state {step}: {hint[1]}')
        need = npc_actors_needed(scene)
        if need and len(self.npcs(mid, scr, step)) < need:
            cands = [t[2] for t in here if t[2] is not None] or list(range(8))
            ok = [k for k in cands if len(self.npcs(mid, scr, k)) >= need]
            if ok:
                step = ok[0]
                notes.append(f'room state {step}: the first state with NPC {need}')
        col, row = scr % 4, scr // 4
        action, stands, facing = ('entry' if not idx else 'arm'), [], 0
        if here and idx:
            t = here[0]
            action = {'npc': 'talk'}.get(t[0], t[0])
            for dx, dy, face in _SIDES:
                x, y = t[3] + dx, t[4] + dy
                if 0 <= x < 10 and 0 <= y < 8:
                    stands.append(((col * 10 + x) * 16 + 8, (row * 8 + y) * 16 + 8, face))
        if stands:
            player, facing = stands[0][:2], stands[0][2]
        else:
            player = ((col * 10 + 5) * 16 + 8, (row * 8 + 4) * 16 + 8)
            r = self.room(mid) or {}
            arr = r.get('gate_arrival')
            if isinstance(arr, dict) and 'x' in arr:
                player = ((col * 10 + int(arr['x'])) * 16 + 8, (row * 8 + int(arr['y'])) * 16 + 8)
        if step and not any(n.startswith('room state') for n in notes):
            notes.append(f'room state {step}: set by the room\'s own rules in game')
        if gctr is not None:
            ram[gctr] = step
        player = _apply_pos(player, pos, notes)
        if pos and stands:
            stands = [(_apply_pos((x, y), pos, None) + (f,)) for x, y, f in stands]
        notes.extend(still_notes(scene, self.npcs(mid, scr, step), scr, player, facing))
        return Recipe(mid, scr, step, tuple(player), facing, stands, action,
                      sorted(flags_set), sorted(flags_clear), ram, mid, idx, scene.entry,
                      action in ('talk', 'examine', 'arm') and bool(idx), notes,
                      insert_slots(scene, lambda t: self.text(t) if isinstance(t, int) else ''))


def read_symbols(sym_path):
    """{label: address} of the WRAM / HRAM labels in a build's game.sym."""
    out = {}
    try:
        for line in open(sym_path):
            line = line.split(';')[0].strip()
            if not line or ':' not in line:
                continue
            addr, name = line.split(None, 1)
            bank, a = addr.split(':')
            a = int(a, 16)
            if a >= 0xC000:
                out[name.strip()] = a
    except OSError:
        pass
    return out


# ------------------------------------------------------------ chains

# Scenes the player walks between in the real game, played one after the
# other (each set up from the base state; a scene that ends in a room change
# simply carries on into the next room's scenes — the dresser runs all the way
# to the Castle by itself).
CHAINS = {
    'The intro (bedroom → GreatTree → Castle)': [
        (0x2F, 0, 7),       # bedtime: running in circles, "time for bed!", sleep, wake (D-pad)
        (0x2F, 0, 727),     # east room: Warubou takes Milayou, Watabou appears
        (0x2F, 10, 0),      # the dresser -> the tree tunnel ($08) -> the Starry Shrine
                            # ($09) -> the old man up GreatTree ($01) -> the Castle minister ($00)
    ],
}
