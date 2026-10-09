"""S126 (ROADMAP P3.14e1) — service NPCs (PROJECT_COMPILER §2.39).

The game's room-independent services are screen effects (script opcode $04
<type> <text base>; BANK04_SCRIPT_ENGINE "`$04` screen types"): their state
is global (one Vault, one farm, one medal count), so any NPC in any room may
be the Vault clerk, a farm keeper, the librarian, the Monster Namer, the
Medal Man, the egg appraiser or the gate guide — measured S126 in custom
rooms on the user's save (PyBoy), after the engine fixes below.

A service NPC's script:
    {"id": "hall_vault", "service": {"kind": "vault",
        "lines": "clerk_lines",                       # optional: a line set
        "first_time": {"text": "<dialogue id>", "flag": "<flag>"}}}  # optional
is lowered to the vanilla NPC's own shape (greeting, the opcode, farewell —
plus the namer's YES / NO loop, the library's dialog re-open, the egg
appraiser's bottom box).

LINES. Each menu speaks text base + offset (`extracted/service_lines.json`,
tools/extract_service_lines.py). A line set
(`custom.service_lines[] = {"id", "kind", "lines": {"<off>": text},
"speaker", "voice", "everywhere"}`) replaces some of them: each given line
keeps its vanilla FRAME (opener / speaker label / ending bytes — a menu
prompt ends without a wait) and gets new WORDS. The script writes the set's
number to `wServiceLines` before the opcode and 0 after it; bank $77 entry 3
SayText swaps a vanilla id for the project's text (ServiceSetTable: set 0 =
the pairs that apply to EVERY NPC of the kind — "everywhere" sets and the
medal reward lines — then set n). The greeting / farewell the script speaks
itself use the set's text directly. Shop scripts take `lines` too (kind
"shop", the shop's own menu lines).

MEDALS. `gamedata.medals.rewards` = 1-8 [{"medals", "enemy", "line"}]:
bank $12 MedalRewardTable (region gd_medal_rewards; the code's three `cp $04`
read MEDAL_REWARD_COUNT); the egg given = the enemy row (vanilla or a project
enemy); its "It's an egg of …" line = offset 2 + n of the medal block, for
every Medal Man (global pairs). No `gamedata.medals` = the game's 4 rewards
and lines (only the table's address changes).

Engine (S126): bank $77 entries 3-6 (SayText, ServiceCloseBox /
ServiceCloseTiles / ServiceOpenTiles), ScreenPush's full-screen and
"picture in the room's tile slots" rules; banks $0A / $12 screen pushes and
the three say helpers' calls redirected same-size; bank $71 entry 3 pauses
custom animations during full-screen services (AnimPauseTypes).
"""
import json
import os

from . import formats as F
from . import textenc as T

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA_JSON = ('extracted', 'service_lines.json')
WSERVICE_LINES = 'wServiceLines'
MAX_SETS = 250              # wServiceLines is a byte; 0 = none
MEDALS_MAX = 8              # the eggs given [$D9E1] set flags $0050-$0057 (8)
MEDAL_TOTAL_MAX = 999       # the Medal Man caps the count at 999 ($12:$6B4B)

# kind -> what the editor says and how the vanilla script is shaped.
# `greet` / `bye` = block offsets the SCRIPT speaks (None = none).
KINDS = {
    'vault':   dict(name='Vault keeper', screen=2, greet=0, bye=2,
                    what='stores items and gold — one Vault for the whole game'),
    'farm':    dict(name='Farm keeper', screen=3, greet=0, bye=2,
                    what='drop off / pick up / check / separate / sleep monsters — the one farm'),
    'library': dict(name='Librarian', screen=8, greet=0, bye=2,
                    what='look up the monsters you have met, family by family'),
    'namer':   dict(name='Monster Namer', screen=9, greet=0, bye=2,
                    what='rename a monster (not one another master named)'),
    'medals':  dict(name='Medal Man', screen=10, greet=0, bye=None,
                    what='takes TinyMedals, gives an egg at each reward count'),
    'eggs':    dict(name='Egg appraiser', screen=7, greet=0, bye=2,
                    what='evaluates and blesses eggs (for gold)'),
    'gates':   dict(name='Gate guide', screen=13, greet=None, bye=None,
                    what="shows the list of Travelers' Gates (the original game's 31)"),
    # S127 (ROADMAP P3.14e2): breeding — lowered by breeders.py once the rooms
    # resolve (the scripts need the NPC's slot; the room gets a return script)
    'grandpa': dict(name='Grandpa (breeding)', screen=6, greet=0, bye=2, breeding=True,
                    what='breeds two of your monsters (the night ceremony), hatches eggs '
                         'from the farm, names the newborn'),
    'breeder': dict(name='Breeder (my monster)', screen=5, greet=None, bye=0, breeding=True,
                    what="offers ONE of their own monsters as the mate — a fixed one, or one "
                         "rolled from a breeding pool each time the room appears"),
}
LINE_KINDS = ('shop', 'vault', 'farm', 'library', 'namer', 'medals', 'eggs', 'grandpa',
              'breeder', 'arena')
# S128 (ROADMAP P3.14e3): 'arena' = the class menu of the project's arena desk
# (custom.arena.lines, editor2/core/your_arena.py) — a line kind, not a service NPC
LINE_KIND_NAMES = {'arena': 'Arena desk'}
# S127: lines of a block no line set can change — the breeding ceremony (map $08
# script 0, a vanilla script) speaks them by their ids, not through SayText
FIXED_LINES = {'grandpa': {0x0D: 'the ceremony says it ("… & … disappeared.")',
                           0x16: 'the ceremony says it ("… was born. Give it a name.")'}}
GATES_ASK, GATES_BYE = 0x0066, 0x047E     # the Gate Hub guide's question / farewell
TOKENS = {'{hero}': [0xF6], '{ins0}': [0xF9, 0x00], '{ins1}': [0xF9, 0x10],
          '{ins2}': [0xF9, 0x20], '{ins3}': [0xF9, 0x30]}
# cells the checks count for an insert: {hero} = the 4-letter default; {insN} =
# what the menu fills in (a name, a count, a price) varies — 4 is a short name,
# so the game's own lines pass ("{ins1} X {ins0}"); a long one can still run on
TOKEN_CELLS = {'{hero}': 4, '{ins0}': 4, '{ins1}': 4, '{ins2}': 4, '{ins3}': 4}


class ServiceError(ValueError):
    pass


_DATA = {}


def data(repo=None):
    repo = repo or REPO_ROOT
    if repo not in _DATA:
        _DATA[repo] = json.load(open(os.path.join(repo, *DATA_JSON), encoding='utf-8'))
    return _DATA[repo]


def block(kind, repo=None):
    return data(repo)['kinds'][kind]


def vline(kind, off, repo=None):
    b = block(kind, repo)
    if not 0 <= off < b['count']:
        raise ServiceError(f"{kind}: no line +{off} (the block has {b['count']})")
    return b['lines'][off]


def base_id(kind, repo=None):
    return int(block(kind, repo)['base'][1:], 16)


# --------------------------------------------------------------- encoding
def _items(s):
    """A line of words -> [(bytes, cells)] — the textenc glyph syntax plus the
    menu insert slots {ins0}..{ins3}."""
    out, i = [], 0
    while i < len(s):
        if s[i] == '{':
            j = s.find('}', i)
            tok = s[i:j + 1] if j > 0 else s[i:]
            if tok not in TOKENS:
                raise ServiceError(f"unknown insert {tok!r} (known: {', '.join(TOKENS)})")
            out.append((TOKENS[tok], TOKEN_CELLS[tok]))
            i = j + 1
            continue
        k = s.find('{', i)
        chunk = s[i:] if k < 0 else s[i:k]
        try:
            for kind, v, _src in T.items(chunk):
                out.append(([v], 1))
        except T.TextError as ex:
            raise ServiceError(str(ex))
        i += len(chunk)
    return out


def encode_body(text):
    """Words -> bytes: a run of n newlines = (n mod 2) line breaks ($EF $EE)
    then (n div 2) new boxes ($FA $F7 $EF $EE) — "\n" a line, "\n\n" a box,
    "\n\n\n" an empty second line and then a box (the game's order)."""
    import re
    out = []
    for part in re.split(r'(\n+)', text.replace('\r', '')):
        if not part:
            continue
        if part[0] == '\n':
            n = len(part)
            out += T.LINE_BREAK * (n % 2) + T.BOX_BREAK * (n // 2)
        else:
            for bs, _c in _items(part):
                out += bs
    return out


def vanilla_body(vl):
    raw = bytes.fromhex(vl['raw'])
    h = (1 if vl['voice'] else 0) + len(bytes.fromhex(vl['speaker_raw']))
    t = len(bytes.fromhex(vl['tail']))
    return list(raw[h:len(raw) - t])


def frame_head(vl, speaker=None, voice=None):
    """The opener + speaker label of a vanilla line, with an override when
    the vanilla line has one (a line that continues an open box has none)."""
    if vl['voice'] is None:
        return []
    v = voice or vl['voice']
    head = list(T.VOICES[v]) if v in T.VOICES else [0xEA]
    if vl['speaker'] is None:
        return head
    sp = vl['speaker'] if speaker is None else speaker
    if sp in ('*', None):
        return head + [0x9F, 0xA3]
    if sp == 'hero':
        return head + [0xF6, 0xA3]
    if sp == '':
        return head
    return head + [c for bs, _ in _items(sp) for c in bs] + [0xA3]


def encode_line(vl, text, speaker=None, voice=None):
    """A line's bytes: the vanilla frame around new words (words equal to the
    game's keep the game's exact bytes — "Giggle.." is two $5F, typed ".." is
    the one-cell $61)."""
    body = vanilla_body(vl) if text == vl['text'] else encode_body(text)
    return bytes(frame_head(vl, speaker, voice) + body + list(bytes.fromhex(vl['tail'])))


def tail_lines(vl):
    """1 when the line ENDS with a line break ($EF $EE in its tail: "Anything
    else?", "How many?", …) — the menu then writes on the next line, so the
    line's last box keeps one line free (PyBoy S126: a second line there
    scrolls the box over the menu window)."""
    return 1 if vl['tail'].startswith('efee') else 0


def text_boxes(text):
    """[[line, …] per box] as the game shows `text` — the encode_body rule: a
    run of n newlines = (n mod 2) line breaks, then (n div 2) new boxes (so
    "\n\n\n" ends the box with an empty line)."""
    import re
    boxes = [['']]
    for part in re.split(r'(\n+)', text.replace('\r', '')):
        if not part:
            continue
        if part[0] == '\n':
            for _ in range(len(part) % 2):
                boxes[-1].append('')
            for _ in range(len(part) // 2):
                boxes.append([''])
        else:
            boxes[-1][-1] += part
    return boxes


def line_problems(vl, text, speaker=None):
    """Box-format problems (cells per line, lines per box)."""
    probs = []
    lab = label_cells(vl, speaker)
    boxes = text_boxes(text)
    for bi, lines in enumerate(boxes):
        cap = 2 - (tail_lines(vl) if bi == len(boxes) - 1 else 0)
        if len(lines) > cap:
            probs.append(f"box {bi + 1} has {len(lines)} lines (a box shows 2)" if cap == 2 else
                         f"box {bi + 1} has {len(lines)} lines — this line ends with a new "
                         f"line (the menu writes on the line after it), so its last box "
                         f"holds 1 (a blank line before the last line starts a new box)")
        for li, ln in enumerate(lines):
            lim = T.MAX_LINE - (lab if bi == 0 and li == 0 else 0)
            n = sum(c for _b, c in _items(ln))
            if n > lim:
                probs.append(f"box {bi + 1} line {li + 1} is {n} cells (max {lim})")
    return probs


# ------------------------------------------------------------- resolution
def _sets(prj):
    out = {}
    for i, s in enumerate(prj.custom.get('service_lines') or []):
        ctx = f"custom.service_lines[{i}]"
        if not isinstance(s, dict) or not s.get('id'):
            raise ServiceError(f"{ctx}: {{\"id\", \"kind\", \"lines\": {{offset: text}}}}")
        sid = s['id']
        if sid in out:
            raise ServiceError(f"{ctx}: duplicate id {sid!r}")
        kind = s.get('kind')
        if kind not in LINE_KINDS:
            raise ServiceError(f"{ctx} {sid!r}: kind {kind!r} (one of {', '.join(LINE_KINDS)})")
        unknown = set(s) - {'id', 'kind', 'lines', 'speaker', 'voice', 'everywhere',
                            'comment', 'name'}
        if unknown:
            raise ServiceError(f"{ctx} {sid!r}: unknown keys {sorted(unknown)}")
        lines = {}
        for k, t in (s.get('lines') or {}).items():
            try:
                off = int(k)
            except (TypeError, ValueError):
                raise ServiceError(f"{ctx} {sid!r}: line key {k!r} is not an offset")
            vl = vline(kind, off, getattr(prj, 'repo_root', None))
            if off in FIXED_LINES.get(kind, {}):
                raise ServiceError(f"{ctx} {sid!r} +{off}: {FIXED_LINES[kind][off]} — "
                                   "the game's words stay")
            if not isinstance(t, str):
                raise ServiceError(f"{ctx} {sid!r} +{off}: the text must be a string")
            encode_line(vl, t, s.get('speaker'), s.get('voice'))   # raises on bad glyphs
            lines[off] = t
        if s.get('voice') not in (None, 'low', 'high'):
            raise ServiceError(f"{ctx} {sid!r}: voice {s.get('voice')!r} (low / high)")
        sp = s.get('speaker')
        if sp is not None:
            if not isinstance(sp, str):
                raise ServiceError(f"{ctx} {sid!r}: speaker must be a name, '*', 'hero' or ''")
            if sp not in ('*', 'hero', ''):
                n = sum(c for _b, c in _items(sp))
                if n + 1 > T.SPEAKER_MAX:
                    raise ServiceError(f"{ctx} {sid!r}: speaker {sp!r} is {n + 1} cells "
                                       f"with the ':' (max {T.SPEAKER_MAX})")
        out[sid] = dict(s, _lines=lines)
    return out


def _cells(s):
    return sum(c for _b, c in _items(s))


def label_cells(vl, speaker=None):
    """Cells the speaker label takes on a line's first box line."""
    if vl['voice'] is None or vl['speaker'] is None:
        return 0
    sp = vl['speaker'] if speaker is None else speaker
    if sp in ('*', None):
        return 2
    if sp == '':
        return 0
    if sp == 'hero':
        return 5
    return _cells(sp) + 1


def fit_text(vl, text, speaker=None):
    """`text` re-flowed for a speaker label of another width (the game's words
    under a longer name): each box's words wrapped again — the first line
    after the label, 2 lines a box, more boxes when needed. Unchanged when it
    already fits."""
    if not line_problems(vl, text, speaker):
        return text
    lab = label_cells(vl, speaker)
    out_boxes = []
    for bi, bx in enumerate(text.split('\n\n')):
        words = ' '.join(x for x in bx.split('\n') if x).split(' ')
        lines, cur = [], ''
        for w in words:
            if not w:
                continue
            lim = T.MAX_LINE - (lab if not out_boxes and not lines and bi == 0 else 0)
            cand = (cur + ' ' + w) if cur else w
            if _cells(cand) <= lim:
                cur = cand
            else:
                lines.append(cur)
                cur = w
        if cur:
            lines.append(cur)
        for k in range(0, len(lines), 2):
            out_boxes.append('\n'.join(lines[k:k + 2]))
    if tail_lines(vl) and out_boxes and '\n' in out_boxes[-1]:
        a, b = out_boxes[-1].split('\n', 1)        # the last box keeps a line free
        out_boxes[-1:] = [a, b]
    return '\n\n'.join(out_boxes)


def set_lines(prj, s):
    """{offset: bytes} the set changes: every given line, and — with a
    speaker / voice override — every line whose vanilla frame has a label /
    an opener (so the whole menu speaks with the new name)."""
    repo = getattr(prj, 'repo_root', None)
    b = block(s['kind'], repo)
    out = {}
    for vl in b['lines']:
        off = vl['off']
        if off in FIXED_LINES.get(s['kind'], {}):
            continue                     # S127: spoken by the ceremony script itself
        t = s['_lines'].get(off)
        relabel = (s.get('speaker') is not None and vl['speaker'] is not None
                   and s['speaker'] != vl['speaker']) or \
                  (s.get('voice') is not None and vl['voice'] is not None
                   and s['voice'] != vl['voice'])
        if t is None and not relabel:
            continue
        text = fit_text(vl, vl['text'], s.get('speaker')) if t is None else t
        by = encode_line(vl, text, s.get('speaker'), s.get('voice'))
        if by.hex() != vl['raw']:
            out[off] = by
    return out


def medal_rewards(prj):
    """[(medals, eid, line text or None)] — gamedata.medals.rewards, or the
    game's 4 (lines None = the game's)."""
    repo = getattr(prj, 'repo_root', None)
    md = (prj.data.get('gamedata') or {}).get('medals')
    van = data(repo)['medal_rewards']['rows']
    if not md:
        return [(r['medals'], r['eid'], None) for r in van], False
    rw = md.get('rewards')
    if not isinstance(rw, list) or not 1 <= len(rw) <= MEDALS_MAX:
        raise ServiceError(f"gamedata.medals.rewards: 1-{MEDALS_MAX} rewards "
                           f"(the eggs given set flags $0050-$0057)")
    out, last = [], 0
    for i, r in enumerate(rw):
        ctx = f"gamedata.medals.rewards[{i}]"
        if not isinstance(r, dict):
            raise ServiceError(f"{ctx}: {{\"medals\": N, \"enemy\": row, \"line\": text}}")
        try:
            m = int(F.val(r.get('medals')))
        except (TypeError, ValueError):
            raise ServiceError(f"{ctx}: medals must be a number")
        if not 1 <= m <= MEDAL_TOTAL_MAX:
            raise ServiceError(f"{ctx}: medals {m} (1-{MEDAL_TOTAL_MAX}; the count stops at 999)")
        if m <= last:
            raise ServiceError(f"{ctx}: {m} medals is not more than the reward before ({last})")
        last = m
        try:
            eid = prj.enemy_ref(r.get('enemy'), ctx)
        except Exception as ex:                                  # noqa: BLE001
            raise ServiceError(f"{ctx}: enemy {r.get('enemy')!r}: {ex}")
        line = r.get('line')
        if line is not None and not isinstance(line, str):
            raise ServiceError(f"{ctx}: line must be text")
        out.append((m, eid, line))
    return out, True


def reward_default(vl, name, last):
    """The game's wording fitted to reward line `vl`'s frame: lines +7..+10
    (rewards 5-8) and +6 end with a line break, so their last box holds one
    line (fit_text moves "farm!" into a box of its own)."""
    t = default_reward_line(name, last)
    return fit_text(vl, t) if line_problems(vl, t) else t


def default_reward_line(name, last):
    """The game's wording for a reward egg (+ the "no more rewards" boxes
    after the last one, as the game's 4th line has them)."""
    t = f"It's an egg of\na {name}! I'll\n\nsend it to the\nfarm!"
    if last:
        t += ("\n\n*:Oh no!\nHmmmm.\n\n*:I have no more\nrewards to give!\n\n"
              "*:Sorry but will\nyou work for free\n\nfrom now on?")
    return t


def resolve(prj):
    """Cached on prj: sets (id -> set), numbers (id -> n >= 1 for sets a script
    uses), the generated dialogue entries, set pairs [(vanilla id, dialogue
    id)] per number (0 = global) and the medal rewards."""
    c = getattr(prj, '_services', None)
    if c is not None:
        return c
    repo = getattr(prj, 'repo_root', None)
    sets = _sets(prj)
    used = []
    for s in prj.custom.get('scripts', []):
        sv = s.get('service') or {}
        sp = s.get('shop') or {}
        for ref in (sv.get('lines'), sp.get('lines') if isinstance(sp, dict) else None):
            if ref and ref in sets and ref not in used and not sets[ref].get('everywhere'):
                used.append(ref)
    ar = (prj.custom.get('arena') or {}) if isinstance(prj.custom.get('arena'), dict) else {}
    ref = ar.get('lines')                 # S128: your arena's desk (custom.arena.lines)
    if ref and ref in sets and ref not in used and not sets[ref].get('everywhere'):
        used.append(ref)
    if len(used) > MAX_SETS:
        raise ServiceError(f"{len(used)} line sets used by scripts (max {MAX_SETS})")
    numbers = {sid: i + 1 for i, sid in enumerate(used)}
    dialogue, pairs = [], {0: []}
    for sid, s in sets.items():
        kind = s['kind']
        base = base_id(kind, repo)
        ch = set_lines(prj, s)
        for off, by in sorted(ch.items()):
            did = f"svc:{sid}:{off}"
            dialogue.append({'id': did, 'raw': [['bytes'] + list(by)],
                             'comment': f"{kind} line +{off:02X} ({sid})", '_service': True})
            if s.get('everywhere'):
                pairs[0].append((base + off, did))
            elif sid in numbers:
                pairs.setdefault(numbers[sid], []).append((base + off, did))
    rewards, edited = medal_rewards(prj)
    if edited:
        names = _species_names(prj)
        mbase = base_id('medals', repo)
        for n, (m, eid, line) in enumerate(rewards, 1):
            vl = vline('medals', 2 + n, repo)
            text = line if line is not None else reward_default(vl, names(eid),
                                                                n == len(rewards))
            did = f"svc:medal_reward:{n}"
            dialogue.append({'id': did, 'raw': [['bytes'] + list(encode_line(vl, text))],
                             'comment': f"Medal Man: reward {n} ({m} medals)", '_service': True})
            # a set of the project's that also gives a reward line wins (set n first)
            pairs[0].append((mbase + 2 + n, did))
    prj._services = dict(sets=sets, numbers=numbers, dialogue=dialogue, pairs=pairs,
                         rewards=rewards, medals_edited=edited)
    return prj._services


def _species_names(prj):
    """eid -> the species name a player sees (renames included)."""
    from . import conversation as CV
    names = CV.species_names(prj.data)
    van = {r['eid']: r['species'] for r in CV.vanilla_enemies()}

    def name(eid):
        sp = None
        if eid >= 519:
            for e in prj.quest_enemy_rows():
                if e['_eid'] == eid:
                    sp = int(e.get('species', 0))
        else:
            sp = van.get(eid)
        return names.get(sp, 'monster') if sp is not None else 'monster'
    return name


# ---------------------------------------------------------------- lowering
def _text_ref(prj, sid, kind, off):
    """The dialogue id the script speaks for block line `off` (the set's
    text when it changes that line, else the game's id)."""
    r = resolve(prj)
    repo = getattr(prj, 'repo_root', None)
    if sid and sid in r['sets'] and off in set_lines(prj, r['sets'][sid]):
        return f"svc:{sid}:{off}"
    for s in r['sets'].values():               # an "everywhere" set of the kind
        if s['kind'] == kind and s.get('everywhere') and off in set_lines(prj, s):
            return f"svc:{s['id']}:{off}"
    return base_id(kind, repo) + off


def lower(prj):
    """Lower every {"service": …} script and every shop script's `lines`
    (after the shop lowering) into ops. Runs before the dialogue resolves."""
    r = resolve(prj)
    for s in prj.custom.get('scripts', []):
        sv = s.get('service')
        if sv is None or s.get('_service_lowered'):
            continue
        ctx = f"scripts[{s.get('id')}].service"
        if 'ops' in s or 'talk' in s or 'shop' in s:
            raise ServiceError(f"{ctx}: a service script has no 'ops' / 'talk' / 'shop'")
        if not isinstance(sv, dict) or sv.get('kind') not in KINDS:
            raise ServiceError(f"{ctx}: kind {sv.get('kind') if isinstance(sv, dict) else sv!r} "
                               f"(one of {', '.join(KINDS)})")
        kind = sv['kind']
        if KINDS[kind].get('breeding'):
            continue                     # S127: breeders.lower_talk, after the rooms resolve
        unknown = set(sv) - {'kind', 'lines', 'first_time', 'comment', 'ask', 'bye'}
        if unknown:
            raise ServiceError(f"{ctx}: unknown keys {sorted(unknown)}")
        sid = sv.get('lines')
        if sid is not None:
            if kind == 'gates':
                raise ServiceError(f"{ctx}: the gate guide's list has no lines of its own "
                                   "(its question / farewell are 'ask' / 'bye')")
            if sid not in r['sets']:
                raise ServiceError(f"{ctx}: line set {sid!r} is not in custom.service_lines")
            if r['sets'][sid]['kind'] != kind:
                raise ServiceError(f"{ctx}: line set {sid!r} is for {r['sets'][sid]['kind']!r}, "
                                   f"not {kind!r}")
        s['ops'] = service_ops(prj, kind, sid, sv, ctx)
        s['_service_lowered'] = True
    for s in prj.custom.get('scripts', []):
        sp = s.get('shop')
        if not isinstance(sp, dict) or not sp.get('lines') or s.get('_shop_lines_done'):
            continue
        sid = sp['lines']
        ctx = f"scripts[{s.get('id')}].shop.lines"
        if sid not in r['sets'] or r['sets'][sid]['kind'] != 'shop':
            raise ServiceError(f"{ctx}: {sid!r} is not a 'shop' line set")
        n = r['numbers'].get(sid)
        ops = s['ops']
        k = next(i for i, o in enumerate(ops) if o[:2] == ['op', '0x04'])
        if n:
            ops.insert(k, ['op', 'write_ram', WSERVICE_LINES, n])
            ops.insert(k + 2, ['op', 'write_ram', WSERVICE_LINES, 0])
        # the greeting / thank-you the script speaks: the set's when it has them
        if not sp.get('text'):
            ops[0] = ['text', _text_ref(prj, sid, 'shop', 0)]
        for i, o in enumerate(ops):
            if o[0] == 'text' and _pv(o[1]) == base_id('shop') + 2:
                ops[i] = ['text', _text_ref(prj, sid, 'shop', 2)]
        s['_shop_lines_done'] = True


def _pv(v):
    try:
        return F.val(v)
    except Exception:                                            # noqa: BLE001
        return v


def service_ops(prj, kind, sid, sv, ctx):
    """The script for one service NPC — the vanilla NPC's own shape: (the
    first visit's intro + its flag, else) the greeting, the opcode, the
    farewell; the namer's YES / NO + list / naming-screen loop; the library's
    dialog re-open; the egg appraiser's / namer's / (S137) the librarian's bottom box
    (op $3C)."""
    r = resolve(prj)
    repo = getattr(prj, 'repo_root', None)
    n = r['numbers'].get(sid) if sid else None
    on = [['op', 'write_ram', WSERVICE_LINES, n]] if n else []
    off = [['op', 'write_ram', WSERVICE_LINES, 0]] if n else []
    ft = sv.get('first_time')
    fl = intro = None
    if ft is not None:
        if not isinstance(ft, dict) or not ft.get('text') or not ft.get('flag'):
            raise ServiceError(f"{ctx}.first_time: {{\"text\": <dialogue id>, \"flag\": <flag>}}")
        fl = prj._flag_index(ft['flag'], f"{ctx}.first_time")
        intro = ft['text']
    box = [['op', '0x3C']] if kind in ('eggs', 'namer', 'library') else []
    # S137: the library too — its screen keeps speaking into the box the greeting opened
    # (the text engine's box base $C83E); the vanilla Library's counter always puts the
    # player in the upper half, so that box is the BOTTOM one. A librarian talked to from
    # the lower half got the TOP box: every two-box line (the empty family's "You haven't
    # caught any from / that family yet.") was scrolled at the top, over the family list,
    # while the library drew its own box at the bottom — the text showed twice (user S137,
    # PyBoy). The farewell box keeps the default rule (init_dialog opens it itself).
    if kind == 'gates':
        head = []
        if fl is not None:
            head = [['op', 'if_flag_set', fl, '@known'], ['text', intro],
                    ['op', 'set_flag', fl], 'label:known']
        return head + [
            ['text', sv.get('ask') or GATES_ASK], ['op', 'check_and_branch', 0xC83C, 1, '@no'],
            ['op', '0x04', KINDS['gates']['screen'], 0], ['op', 'nop'], ['op', 'init_dialog'],
            'label:no', ['text', sv.get('bye') or GATES_BYE], ['end']]
    base = base_id(kind, repo)
    scr = KINDS[kind]['screen']
    greet = ['text', _text_ref(prj, sid, kind, 0)]
    if kind == 'namer':
        lead = box + [greet]
        if fl is not None:     # the intro, then the question in a new box
            lead = [['op', 'if_flag_set', fl, '@known']] + box + [
                ['text', intro], ['op', 'set_flag', fl], 'label:known'] + box + [greet]
        return on + lead + [
            ['op', 'check_and_branch', 0xC83C, 1, '@bye'],
            'label:list', ['op', '0x04', scr, base],
            ['op', 'check_and_branch', 0xC8F4, 255, '@bye'],
            ['op', 'close_text'], ['op', '0x04', 15, 0], ['op', '0x3C'], ['op', 'init_dialog'],
            ['op', 'goto', '@list'],
            'label:bye'] + off + box + [['text', _text_ref(prj, sid, kind, 2)], ['end']]
    if fl is not None:          # the first visit says the intro INSTEAD of the greeting
        lead = [['op', 'if_flag_set', fl, '@known']] + box + [
            ['text', intro], ['op', 'set_flag', fl], ['op', 'goto', '@open'],
            'label:known'] + box + [greet, 'label:open']
    else:
        lead = box + [greet]
    seq = on + lead + [['op', '0x04', scr, base]]
    if kind == 'library':
        seq += [['op', 'nop'], ['op', 'init_dialog']]
    seq += off
    if KINDS[kind]['bye'] is not None:
        # after the library's init_dialog an op $3C would only arm the NEXT box (another
        # talk's) — the library's farewell goes without it
        seq += (box if kind != 'library' else []) + [['text', _text_ref(prj, sid, kind, 2)]]
    return seq + [['end']]


# --------------------------------------------------------------- emitters
def set_table_lines(prj):
    """Bank $77 data: SERVICE_SET_COUNT, ServiceSetTable (set 0 = global),
    the pair lists (dw vanilla id, dw the project's text id; $FFFF ends)."""
    r = resolve(prj)
    tid = {e['id']: e['_tid'] for e in prj._dialogue if 'id' in e and '_tid' in e}
    count = len(r['numbers'])
    out = ["; S126 (P3.14e1): the service lines the project replaces (bank $77 entry 3",
           "; SayText; editor2/core/services.py). Set 0 applies to every NPC of a kind,",
           "; set n while a script's wServiceLines = n.",
           f"SERVICE_SET_COUNT EQU {count}",
           "ServiceSetTable:"]
    names = {v: k for k, v in r['numbers'].items()}
    for n in range(count + 1):
        out.append(f"    dw ServicePairs_{n}   ; " + ("every NPC (everywhere sets, medal rewards)"
                                                      if n == 0 else names[n]))
    for n in range(count + 1):
        out.append(f"ServicePairs_{n}:")
        for vid, did in r['pairs'].get(n, []):
            out.append(f"    dw ${vid:04X}, ${tid[did]:04X}   ; {did}")
        out.append("    dw $FFFF")
    return out


def emit_medal_rewards(prj, warnings):
    """Region gd_medal_rewards (patches/bank_012.asm, the free tail)."""
    rewards, edited = medal_rewards(prj)
    out = ["; S126 (P3.14e1): the Medal Man's rewards (gamedata.medals; editor2 services.py).",
           "; Per egg: dw the medals that earn it, dw the enemy row the egg is made from.",
           "; Read by MedalScreen with the eggs given [$D9E1] (was $12:$6D29, 4 rows).",
           f"MEDAL_REWARD_COUNT EQU {len(rewards)}",
           "MedalRewardTable:"]
    for m, eid, _l in rewards:
        out.append(f"    dw {m}, {eid}")
    out.append("    dw $FFFF, $0000")
    return "\n".join(out) + "\n"


REGIONS = [('gd_medal_rewards', 'patches/bank_012.asm', emit_medal_rewards, 0x12)]


# -------------------------------------------------------------- validation
def validate(prj):
    """(errors, warnings) — the lowering's error, line-format problems,
    sets nobody uses, two "everywhere" sets for one kind."""
    errors, warnings = [], []
    if getattr(prj, 'service_error', None):
        errors.append(prj.service_error)
        return errors, warnings
    try:
        r = resolve(prj)
    except ServiceError as ex:
        return [str(ex)], warnings
    repo = getattr(prj, 'repo_root', None)
    used = set()
    for s in prj.custom.get('scripts', []):
        for spec in (s.get('service'), s.get('shop')):
            if isinstance(spec, dict) and spec.get('lines'):
                used.add(spec['lines'])
    every = {}
    for sid, st in r['sets'].items():
        if st.get('everywhere'):
            every.setdefault(st['kind'], []).append(sid)
        elif sid not in used:
            warnings.append(f"service lines {sid!r}: no NPC speaks them (not every NPC's: "
                            "'everywhere' is off)")
        for off, t in sorted(st['_lines'].items()):
            vl = vline(st['kind'], off, repo)
            for pr in line_problems(vl, t, st.get('speaker')):
                errors.append(f"service lines {sid!r} +${off:02X}: {pr} — the game would "
                              "wrap it in the middle of a word")
    for kind, ids in every.items():
        if len(ids) > 1:
            warnings.append(f"{kind}: {len(ids)} line sets are for every NPC ({', '.join(ids)}) "
                            "— the first one listed wins for a line both change")
    if r['medals_edited']:
        for n, (m, eid, line) in enumerate(r['rewards'], 1):
            if line is not None:
                for pr in line_problems(vline('medals', 2 + n, repo), line):
                    errors.append(f"gamedata.medals.rewards[{n - 1}] line: {pr}")
    return errors, warnings

