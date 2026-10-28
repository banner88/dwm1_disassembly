"""hints.py — S158 (ROADMAP E15): BREEDING HINTS — monuments and archives.

The user is scrambling the breeding table, so the player needs in-game hints of the
crosses. A HINT is one row of the SPECIAL breeding table (the effective table bank
$69 scans: "pedigree x mate (+ a min plus) -> child") that the project puts in its
HINT POOL. The family table is what each monster's library page already shows, so
its recipes are never hints ("basic"). The pool follows the breeding table: it is
worked out at every build from the effective table, so editing the table changes
the monuments and archives with it.

  * A MONUMENT (an examine spot in a room — typically a custom room served on gate
    floors) shows a random hint the player has NOT unlocked (of the families it
    names; with "skip owned" also not one whose child the player has ever owned),
    and unlocks it at once. Reading it again in the same visit shows the same hint;
    the next visit (another place / gate / floor) picks again. None left: its
    "worn away" words.
  * An ARCHIVE (an examine spot, one family) lists the family's unlocked hints, one
    box each with the BRED mark, "Keep reading?" after every entry; "It seems you
    have not found any clues yet…" when it has none.
  * BREEDING an egg with exactly a hint's cross unlocks it and marks it bred. A
    cross that is not in the pool is not recorded (the pool decides what counts).

Owning docs: PROJECT_COMPILER §2.66 (schema + lowering), DATA_STRUCTURES "Breeding
hints (S158)" (the engine, the save), help 78_hints.md.

Schema
------
  custom.hints = {
      "mode": "blacklist" | "whitelist",   # blacklist (default): every special row
                                           #   that can fire, minus "exclude";
                                           #   whitelist: only "include"
      "exclude": [key, ...], "include": [key, ...],   # both kept when the mode changes
      "numbers": {key: n},                 # pinned hint numbers (= the save's bits;
                                           #   the editor pins them, the compiler
                                           #   numbers the rest after the highest)
      "riddles": {key: boxes},             # a hint's riddle (optional; boxes =
                                           #   [["line", "line"], …], or a dialogue id)
      "family_words": {"Slime": "any Slime", ...},   # a family matcher's words
      "bred_word": "(bred)", "unbred_word": "",       # the {bred} insert
      "words": {"monument" | "exhausted" | "archive_ask" | "archive_empty" |
                "archive_entry" | "archive_more" | "archive_end" | "archive_no":
                boxes}                     # project defaults (else DEFAULTS below)
  }
  key = "<p1>x<p2>+<min plus>><child>", a matcher = a species id or a family name:
        "9xDragon+0>42" = Healer (9) x any Dragon -> 42 (key / parse_key).
  custom.rooms[].monuments = [{"id", "families": [names] | null (all),
        "skip_owned": true, "show": "explicit" | "riddle" | "both",
        "intro"?, "text"?, "outro"?, "exhausted"?: boxes}]   (<= 8 a room)
  custom.rooms[].archives = [{"id", "family": name, "ask"?, "empty"?, "entry"?,
        "more"?, "end"?, "no"?: boxes}]
  (every text: inline boxes — the compiler makes the dialogue entries, an archive's
   with {family} written in — or a dialogue id of custom.dialogue)
  a screen state's npcs[] entry {"kind": "monument", "x", "y", "monument": id} /
        {"kind": "archive", "x", "y", "archive": id} = an examine spot on (x, y)
        (the author's own art: a monument, a bookcase with the family's emblem).

Texts: {parent1} / {parent2} / {child} / {bred} (the cross; only in the hint words)
and, in an archive's texts, {family} (the family's name, written in at build time).

Engine: bank $79 entries 10-12 (templates/bank_079_head.asm), bank $77 story command
8, bank $60 TextOverride (the riddle), bank $69 RelocatedSpecialScan (wHintRow),
bank $16 region hint_breed_16, bank $73 HintNewGameClear, the memorial's room-load
regions memorial_tiles_0 / _1 (the visit), SRAM bank 3 $A007 "H1" + $B000 / $B100.
"""

from . import formats as F

POOL_MAX = 2048            # SRAM bank 3: 256-byte bitsets
MONUMENTS_ROOM_MAX = 8     # bank $79 HINT_SLOTS (wHintLatch)
MONUMENTS_MAX = 255        # story command arg (one byte)
WORD_MAX = 12              # a family's words: {parent1} / {parent2} budget
BRED_MAX = 15              # {bred}: a 16-byte insert slot ($F0 ends)
SHOWS = ('explicit', 'riddle', 'both')
MODES = ('blacklist', 'whitelist')
NOT_MONSTERS = range(215, 221)    # Iron Rule 8 (TERRY? + the summons, the empty id)
SCRIPT_PREFIX = '_hint_'

FAMILIES = ["Slime", "Dragon", "Beast", "Bird", "Plant", "Bug", "Devil", "Zombie",
            "Material", "Boss", "Spirit"]          # gamedata.FAMILY_NAMES, codes $F0-$FA

# the project's default words (dialogue entries the compiler adds when the project
# names none): a stone / a bookcase speaks with no name and no voice
WORD_KEYS = ('monument', 'exhausted', 'archive_ask', 'archive_empty', 'archive_entry',
             'archive_more', 'archive_end', 'archive_no')
DEFAULTS = {
    'monument': ([['Words are carved', 'into the stone...'],
                  ['{parent1} with', '{parent2} makes'], ['{child}!']], False),
    'exhausted': ([['The words on this', 'stone have worn'], ['away...']], False),
    'archive_ask': ([['The archive of the', '{family} family.'],
                     ['Would you like to', 'read it?']], True),
    'archive_empty': ([['It seems you have', 'not found any'], ['clues yet...']], False),
    'archive_entry': ([['{parent1}', 'and {parent2}'], ['make {child}', '{bred}']], False),
    'archive_more': ([['Keep reading?']], True),
    'archive_end': ([['That is all the', 'archive holds.']], False),
    'archive_no': (None, False),                   # nothing said on NO
}
TEXT_ROLES_MON = ('intro', 'text', 'outro', 'exhausted')
TEXT_ROLES_ARC = ('ask', 'empty', 'entry', 'more', 'end', 'no')
ARC_ROLE_WORD = {'ask': 'archive_ask', 'empty': 'archive_empty', 'entry': 'archive_entry',
                 'more': 'archive_more', 'end': 'archive_end', 'no': 'archive_no'}


class HintError(ValueError):
    pass


# ---------------------------------------------------------------------------
# keys
# ---------------------------------------------------------------------------

def _m(code):
    if 0xF0 <= code <= 0xFA:
        return FAMILIES[code - 0xF0]
    return str(code)


def key(p1, p2, min_plus, child):
    """A cross -> its stable key ("9xDragon+0>42")."""
    return f"{_m(p1)}x{_m(p2)}+{min_plus}>{child}"


def _parse_m(s):
    if s in FAMILIES:
        return 0xF0 + FAMILIES.index(s)
    return int(s)


def parse_key(k):
    """'9xDragon+0>42' -> (9, $F1, 0, 42); raises ValueError."""
    left, child = k.split('>')
    left, plus = left.rsplit('+', 1)
    a, b = left.split('x', 1)
    return _parse_m(a), _parse_m(b), int(plus), int(child)


def family_index(name):
    """A family name (any case) -> 0-10, else None."""
    if not isinstance(name, str):
        return None
    low = [f.lower() for f in FAMILIES]
    return low.index(name.lower()) if name.lower() in low else None


# ---------------------------------------------------------------------------
# the schema
# ---------------------------------------------------------------------------

def room_monuments(room):
    v = room.get('monuments') or []
    return v if isinstance(v, list) else []


def room_archives(room):
    v = room.get('archives') or []
    return v if isinstance(v, list) else []


def active(custom):
    """Does the project have a hint monument or archive (then the engine is built)?"""
    return any(room_monuments(r) or room_archives(r) for r in (custom.get('rooms') or [])
               if isinstance(r, dict))


def settings(custom):
    """custom.hints validated -> a dict with every key filled."""
    h = custom.get('hints') or {}
    if not isinstance(h, dict):
        raise HintError('custom.hints: must be an object')
    known = ('mode', 'exclude', 'include', 'numbers', 'riddles', 'family_words',
             'bred_word', 'unbred_word', 'words', 'comment')
    bad = [k for k in h if k not in known and not str(k).startswith('_')]
    if bad:
        raise HintError(f'custom.hints: unknown key(s) {bad} ({", ".join(known)})')
    mode = h.get('mode', 'blacklist')
    if mode not in MODES:
        raise HintError(f"custom.hints.mode: {mode!r} — 'blacklist' or 'whitelist'")
    out = {'mode': mode}
    for k in ('exclude', 'include'):
        v = h.get(k) or []
        if not isinstance(v, list) or not all(isinstance(x, str) for x in v):
            raise HintError(f'custom.hints.{k}: a list of hint keys')
        for x in v:
            _check_key(x, f'custom.hints.{k}')
        out[k] = list(v)
    nums = h.get('numbers') or {}
    if not isinstance(nums, dict):
        raise HintError('custom.hints.numbers: {key: number}')
    seen = {}
    for k, n in nums.items():
        _check_key(k, 'custom.hints.numbers')
        if isinstance(n, bool) or not isinstance(n, int) or not 0 <= n < POOL_MAX:
            raise HintError(f'custom.hints.numbers[{k!r}]: {n!r} — 0-{POOL_MAX - 1}')
        if n in seen:
            raise HintError(f'custom.hints.numbers: {n} is both {seen[n]!r} and {k!r}')
        seen[n] = k
    out['numbers'] = dict(nums)
    rid = h.get('riddles') or {}
    if not isinstance(rid, dict):
        raise HintError('custom.hints.riddles: {key: boxes}')
    for k, v in rid.items():
        _check_key(k, 'custom.hints.riddles')
        check_text(v, f'custom.hints.riddles[{k!r}]')
    out['riddles'] = dict(rid)
    fw = h.get('family_words') or {}
    if not isinstance(fw, dict):
        raise HintError('custom.hints.family_words: {family: words}')
    words = []
    from . import textenc as T
    for i, f in enumerate(FAMILIES):
        w = next((v for k, v in fw.items() if family_index(k) == i), None)
        if w is None:
            w = f'any {f}'
        if not isinstance(w, str):
            raise HintError(f'custom.hints.family_words.{f}: words')
        try:
            n = T.cells(w)
            T.check_text_chars(w)
        except T.TextError as ex:
            raise HintError(f'custom.hints.family_words.{f}: {ex}')
        if '{' in w or n > WORD_MAX or not w:
            raise HintError(f'custom.hints.family_words.{f}: {w!r} — 1-{WORD_MAX} letters '
                            '(no inserts)')
        words.append(w)
    for k in fw:
        if family_index(k) is None:
            raise HintError(f'custom.hints.family_words: {k!r} is not a family '
                            f'({", ".join(FAMILIES)})')
    out['family_words'] = words
    for k, dflt in (('bred_word', '(bred)'), ('unbred_word', '')):
        w = h.get(k, dflt)
        if not isinstance(w, str):
            raise HintError(f'custom.hints.{k}: words')
        try:
            T.check_text_chars(w)
            n = T.cells(w) if w else 0
        except T.TextError as ex:
            raise HintError(f'custom.hints.{k}: {ex}')
        if '{' in w or n > BRED_MAX:
            raise HintError(f'custom.hints.{k}: {w!r} — at most {BRED_MAX} letters')
        out[k] = w
    wd = h.get('words') or {}
    if not isinstance(wd, dict):
        raise HintError('custom.hints.words: {role: dialogue id}')
    for k, v in wd.items():
        if k not in WORD_KEYS:
            raise HintError(f'custom.hints.words: {k!r} — one of {", ".join(WORD_KEYS)}')
        if v is not None:
            check_text(v, f'custom.hints.words.{k}', family=k.startswith('archive_'),
                       choice=DEFAULTS[k][1])
    out['words'] = dict(wd)
    return out


def check_text(v, what, family=False, choice=False):
    """A hint text: boxes (checked as the game shows them: no speaker, no voice; an
    archive's may name {family} — the longest name counted) or a dialogue id."""
    if isinstance(v, str) and v:
        return
    from . import textenc as T
    if not isinstance(v, list) or not v or not all(
            isinstance(b, list) and all(isinstance(x, str) for x in b) for b in v):
        raise HintError(f'{what}: boxes [["line", "line"], …] (or a dialogue id)')
    boxes = [[x.replace('{family}', 'Material') if family else x for x in b] for b in v]
    if not family and any('{family}' in x for b in v for x in b):
        raise HintError(f'{what}: {{family}} only works in an archive\'s words')
    try:
        T.check_boxes(boxes, '', 'none')
    except T.TextError as ex:
        raise HintError(f'{what}: {ex}')


def _check_key(k, what):
    try:
        parse_key(k)
    except (ValueError, TypeError):
        raise HintError(f'{what}: {k!r} is not a hint key ("<pedigree>x<mate>+<plus>><child>", '
                        'a matcher = a species id or a family name)')


def _room_name(r):
    return f"room {r.get('name') or r.get('id')!r}"


def check_room(r):
    """A room's monuments + archives validated -> (monuments, archives)."""
    what = _room_name(r)
    mons = r.get('monuments')
    arcs = r.get('archives')
    for lst, kind in ((mons, 'monuments'), (arcs, 'archives')):
        if lst is not None and not isinstance(lst, list):
            raise HintError(f'{what} {kind}: a list')
    mons = mons or []
    arcs = arcs or []
    if len(mons) > MONUMENTS_ROOM_MAX:
        raise HintError(f'{what}: {len(mons)} monuments — a room holds at most '
                        f'{MONUMENTS_ROOM_MAX}')
    ids = set()
    for k, m in enumerate(mons):
        w = f'{what} monuments[{k}]'
        if not isinstance(m, dict):
            raise HintError(f'{w}: an object {{id, …}}')
        bad = [x for x in m if x not in ('id', 'name', 'families', 'skip_owned', 'show',
                                         'comment') + TEXT_ROLES_MON
               and not str(x).startswith('_')]
        if bad:
            raise HintError(f'{w}: unknown key(s) {bad}')
        mid = m.get('id')
        if not isinstance(mid, str) or not mid:
            raise HintError(f'{w}.id: a name')
        if mid in ids:
            raise HintError(f'{w}.id: {mid!r} twice in the room')
        ids.add(mid)
        fams = m.get('families')
        if fams is not None:
            if not isinstance(fams, list) or not fams:
                raise HintError(f"{w} '{mid}'.families: a list of family names (or none = all)")
            for f in fams:
                if family_index(f) is None:
                    raise HintError(f"{w} '{mid}'.families: {f!r} is not a family "
                                    f"({', '.join(FAMILIES)})")
        if m.get('show', 'explicit') not in SHOWS:
            raise HintError(f"{w} '{mid}'.show: {m.get('show')!r} — {', '.join(SHOWS)}")
        if not isinstance(m.get('skip_owned', True), bool):
            raise HintError(f"{w} '{mid}'.skip_owned: true / false")
        for k2 in TEXT_ROLES_MON:
            if m.get(k2) is not None:
                check_text(m[k2], f"{w} '{mid}'.{k2}")
    for k, a in enumerate(arcs):
        w = f'{what} archives[{k}]'
        if not isinstance(a, dict):
            raise HintError(f'{w}: an object {{id, family, …}}')
        bad = [x for x in a if x not in ('id', 'name', 'family', 'comment') + TEXT_ROLES_ARC
               and not str(x).startswith('_')]
        if bad:
            raise HintError(f'{w}: unknown key(s) {bad}')
        aid = a.get('id')
        if not isinstance(aid, str) or not aid:
            raise HintError(f'{w}.id: a name')
        if aid in ids:
            raise HintError(f'{w}.id: {aid!r} twice in the room')
        ids.add(aid)
        if family_index(a.get('family')) is None:
            raise HintError(f"{w} '{aid}'.family: {a.get('family')!r} — one of "
                            f"{', '.join(FAMILIES)}")
        for k2 in TEXT_ROLES_ARC:
            if a.get(k2) is not None:
                check_text(a[k2], f"{w} '{aid}'.{k2}", family=True,
                           choice=k2 in ('ask', 'more'))
    return mons, arcs


def families_mask(m):
    """A monument -> its 11 family bits (all when it names none)."""
    fams = m.get('families')
    if not fams:
        return (1 << len(FAMILIES)) - 1
    out = 0
    for f in fams:
        out |= 1 << family_index(f)
    return out


# ---------------------------------------------------------------------------
# the pool (from the effective special table)
# ---------------------------------------------------------------------------

def candidates(prj, g=None):
    """Every special row that can be a hint: it fires for some pair of parents (a row
    beaten everywhere would be a lie) and names no protected id (Iron Rule 8) ->
    [{'key', 'row', 'p1', 'p2', 'plus', 'child', 'fam'}] in table order (one per key:
    the first row of two identical crosses)."""
    from . import breeding as B
    g = g or prj.gamedata()
    br = B.Breeding(g)
    fast = B.FastResolver(br)
    species = list(range(215))
    species += sorted(getattr(g, 'new_species', {}) or {})
    fam_of = {s: g.fam_code(s) for s in species}
    members = {}
    for s in species:
        members.setdefault(s, [s])
        f = fam_of[s]
        if f is not None:
            members.setdefault(f, []).append(s)
    plus_levels = sorted(set(B.plus_levels(br.special)))
    out, seen = [], set()
    for i, e in enumerate(br.special):
        p1, p2, mp, child = e[0], e[1], e[2], e[3]
        if any(x in NOT_MONSTERS for x in (p1, p2, child)):
            continue
        cf = g.fam_code(child)
        if cf is None:
            continue
        k = key(p1, p2, mp, child)
        if k in seen:
            continue
        fires = False
        levels = [p for p in plus_levels if p >= mp] or [mp]
        for a in members.get(p1, []):
            for b in members.get(p2, []):
                for pl in levels:
                    res, how, idx = fast.resolve(a, b, pl)
                    if how == 'special' and idx == i:
                        fires = True
                        break
                if fires:
                    break
            if fires:
                break
        if not fires:
            continue
        seen.add(k)
        out.append({'key': k, 'row': i, 'p1': p1, 'p2': p2, 'plus': mp, 'child': child,
                    'fam': cf - 0xF0})
    return out


def pool(prj, g=None):
    """The hint pool -> (hints [{… + 'number'}] in number order, count = the highest
    number + 1, holes {number: key} = pinned numbers whose cross is not in the pool).
    Cached on the project."""
    got = getattr(prj, '_hint_pool', None)
    if got is not None:
        return got
    cfg = settings(prj.custom)
    cands = candidates(prj, g)
    if cfg['mode'] == 'whitelist':
        inc = set(cfg['include'])
        chosen = [c for c in cands if c['key'] in inc]
    else:
        exc = set(cfg['exclude'])
        chosen = [c for c in cands if c['key'] not in exc]
    nums = dict(cfg['numbers'])
    used = set(nums.values())
    nxt = max(used) + 1 if used else 0
    # new hints after the pinned ones, by family, child, row (the archive order)
    for c in sorted(chosen, key=lambda c: (c['fam'], c['child'], c['row'])):
        if c['key'] not in nums:
            nums[c['key']] = nxt
            used.add(nxt)
            nxt += 1
    for c in chosen:
        c['number'] = nums[c['key']]
    keys = {c['key'] for c in chosen}
    holes = {n: k for k, n in nums.items() if k not in keys}
    count = max([c['number'] for c in chosen] + list(holes), default=-1) + 1
    if count > POOL_MAX:
        raise HintError(f'the hint pool needs {count} numbers — at most {POOL_MAX} '
                        '(use the whitelist, or renumber the hints)')
    out = (sorted(chosen, key=lambda c: c['number']), count, holes)
    prj._hint_pool = out
    return out


def numbers_to_pin(prj, g=None):
    """{key: number} for every hint of the pool (what the editor pins)."""
    hints, _n, _h = pool(prj, g)
    return {c['key']: c['number'] for c in hints}


# ---------------------------------------------------------------------------
# lowering (Project.__init__, before the talks)
# ---------------------------------------------------------------------------

def _states(scr):
    sts = scr.get('states')
    if isinstance(sts, list) and sts:
        return sts
    return [scr]


def _ensure_dialogue(custom, did, boxes, choice, comment):
    dl = custom.setdefault('dialogue', [])
    if not any(isinstance(d, dict) and d.get('id') == did for d in dl):
        e = {'id': did, 'boxes': [list(b) for b in boxes], 'speaker': '', 'voice': 'none',
             'comment': comment}
        if choice:
            e['choice'] = True
        dl.append(e)


def _dialogue(custom, did):
    for d in custom.get('dialogue') or []:
        if isinstance(d, dict) and d.get('id') == did:
            return d
    return None


def default_word_id(role):
    return f'hints_default_{role}'


def _subst(boxes, fam):
    return [[x.replace('{family}', FAMILIES[fam]) for x in b] for b in boxes]


def text_ref(custom, value, gen_id, choice=False, fam=None, comment=''):
    """A hint text (inline boxes or a dialogue id) -> the dialogue id a script says:
    boxes become the entry gen_id ({family} written in for an archive); an id is used
    as it is (an archive's copy with {family} written in when it names one)."""
    import copy as _c
    import json as _j
    if isinstance(value, str):
        d = _dialogue(custom, value)
        if d is None or fam is None or '{family}' not in _j.dumps(d):
            return value
        if _dialogue(custom, gen_id) is None:
            e = _c.deepcopy(d)
            e['id'] = gen_id
            e['comment'] = f"S158: {value} for the {FAMILIES[fam]} family (hints.py)"
            for k in ('boxes', 'text', 'lines'):
                if k in e:
                    e[k] = (_subst(e[k], fam) if k == 'boxes'
                            else _j.loads(_j.dumps(e[k]).replace('{family}', FAMILIES[fam])))
            custom.setdefault('dialogue', []).append(e)
        return gen_id
    boxes = _subst(value, fam) if fam is not None else value
    old = _dialogue(custom, gen_id)
    if old is None:
        _ensure_dialogue(custom, gen_id, boxes, choice, comment or 'S158: hints.py')
    return gen_id


def word_value(cfg, role):
    """The project's words for a role (boxes / an id), else the default boxes (None
    for 'archive_no')."""
    v = cfg['words'].get(role)
    if v:
        return v
    return DEFAULTS[role][0]


def lower(prj):
    """The monuments / archives -> scripts + examine spots (mutates prj.custom like the
    other lowerings). Sets prj._hint_monuments = [(room id, monument, slot)] in global
    order. Raises HintError."""
    custom = prj.custom
    prj._hint_monuments = []
    if not active(custom):
        for r in custom.get('rooms') or []:
            for _k, scr in (r.get('screens') or {}).items():
                for st in _states(scr):
                    for n in st.get('npcs') or []:
                        if isinstance(n, dict) and n.get('kind') in ('monument', 'archive'):
                            raise HintError(f"{_room_name(r)}: a {n['kind']} on ({n.get('x')}, "
                                            f"{n.get('y')}) but the room has no {n['kind']}s")
        return
    cfg = settings(custom)
    scripts = custom.setdefault('scripts', [])
    have = {s.get('id') for s in scripts}
    for r in custom.get('rooms') or []:
        if not isinstance(r, dict):
            continue
        mons, arcs = check_room(r)
        if not mons and not arcs:
            for _k, scr in (r.get('screens') or {}).items():
                for st in _states(scr):
                    for n in st.get('npcs') or []:
                        if isinstance(n, dict) and n.get('kind') in ('monument', 'archive'):
                            raise HintError(f"{_room_name(r)}: a {n['kind']} on ({n.get('x')}, "
                                            f"{n.get('y')}) but the room has none")
            continue
        if r.get('mapID') is None:
            raise HintError(f"{_room_name(r)}: monuments and archives stand only in the "
                            "project's rooms")
        table = r.setdefault('scripts', {})
        sid_of = {}
        for slot, m in enumerate(mons):
            gid = len(prj._hint_monuments)
            if gid >= MONUMENTS_MAX:
                raise HintError(f'more than {MONUMENTS_MAX} monuments in the project')
            prj._hint_monuments.append((r.get('id'), m, slot))
            base = f"{SCRIPT_PREFIX}{r.get('id')}_{m['id']}"
            step = {'monument': gid, 'show': m.get('show', 'explicit')}
            for k2, role in (('text', 'monument'), ('exhausted', 'exhausted'),
                             ('intro', None), ('outro', None)):
                v = m.get(k2)
                if v:
                    step[k2] = text_ref(custom, v, f'{base}_{k2}',
                                        comment=f"S158: monument '{m['id']}' ({k2})")
                elif role:
                    shared = cfg['words'].get(role)
                    step[k2] = text_ref(custom, shared or DEFAULTS[role][0],
                                        default_word_id(role),
                                        comment=f"S158: the breeding hints' {role} words")
            sid_of[('monument', m['id'])] = _add_script(
                prj, r, table, scripts, have, f"{SCRIPT_PREFIX}{r.get('id')}_{m['id']}",
                step, f"S158: hint monument '{m['id']}' (hints.py)")
        for a in arcs:
            fam = family_index(a['family'])
            step = {'archive': fam}
            for role in TEXT_ROLES_ARC:
                v = a.get(role) or word_value(cfg, ARC_ROLE_WORD[role])
                if v:
                    step[role] = text_ref(custom, v,
                                          f"{SCRIPT_PREFIX}{r.get('id')}_{a['id']}_{role}",
                                          choice=role in ('ask', 'more'), fam=fam,
                                          comment=f"S158: archive '{a['id']}' "
                                                  f"({a['family']}, {role})")
            sid_of[('archive', a['id'])] = _add_script(
                prj, r, table, scripts, have, f"{SCRIPT_PREFIX}{r.get('id')}_{a['id']}",
                step, f"S158: hint archive '{a['id']}' ({a['family']}; hints.py)")
        ids = {('monument', m['id']) for m in mons} | {('archive', a['id']) for a in arcs}
        for _k, scr in (r.get('screens') or {}).items():
            for st in _states(scr):
                for n in st.get('npcs') or []:
                    if not isinstance(n, dict) or n.get('kind') not in ('monument', 'archive'):
                        continue
                    kind = n['kind']
                    which = n.get(kind)
                    if (kind, which) not in ids:
                        raise HintError(f"{_room_name(r)}: the {kind} on ({n.get('x')}, "
                                        f"{n.get('y')}) names {which!r} — not one of the "
                                        f"room's {kind}s")
                    n['kind'] = 'examine'
                    n['script'] = sid_of[(kind, which)]
                    n['facing'] = n.get('facing', 'any')
                    n['_' + kind] = which


def _add_script(prj, r, table, scripts, have, sid, step, comment):
    if sid not in have:
        scripts.append({'id': sid, 'talk': {'steps': [{'hint': step}]}, 'comment': comment})
        have.add(sid)
    if sid not in table.values():
        if '0' not in table:
            eid = f"{SCRIPT_PREFIX}{r.get('id')}_entry"
            if eid not in have:
                scripts.append({'id': eid, 'ops': [['end']]})
                have.add(eid)
            table['0'] = eid
        i = 1
        while str(i) in table:
            i += 1
        table[str(i)] = sid
    return sid


def lower_step(prj, g, ctx, lab):
    """A 'hint' talk step -> script ops (Project._lower_steps). The monument:
        op $24 pick; $D8E1 = 0 -> the worn words
        [intro] [riddle: op $24 prepare 1 + the words (swapped to the riddle; a cross
        without one: the words as written)] [both: prepare 1, $D8E1 = 0 (no riddle)
        skips the riddle's turn, prepare 0, the words] [explicit: the words] [outro]
    the archive:
        ask (YES / NO) -> NO: [no]; op $24 start; $D8E1 = 0 -> empty
        loop: op $24 next; 0 -> end words; 2 -> the entry + end words;
              1 -> the entry, "Keep reading?" YES -> loop, NO -> [no]
    Every text right after an op $24 (it yields) opens its box (init_dialog)."""
    lab[0] += 1
    n = lab[0]

    def cmd(sub, arg):
        w = prj.story_command('hint', {'sub': sub, 'arg': arg}, ctx)
        return ['op', '0x24', f'0x{w:04X}']

    def say(did, init=False):
        return ([['op', 'init_dialog']] if init else []) + [['text', did]]

    ops = []
    if 'monument' in g:
        show = g.get('show', 'explicit')
        ops.append(cmd(0, g['monument']))
        ops.append(['op', 'check_and_branch', '0xD8E1', '0x0000', f'@hnone{n}'])
        init = True
        if g.get('intro'):
            ops += say(g['intro'], init)
            init = False
        if show == 'riddle':
            # the riddle (no riddle written for this cross: the words with the cross)
            ops.append(cmd(1, 1))
            ops += say(g['text'], True)
            init = False
        if show == 'both':
            # the riddle, if this cross has one ($D8E1 = 0: none -> its turn skipped),
            # then the words with the cross
            ops.append(cmd(1, 1))
            ops.append(['op', 'check_and_branch', '0xD8E1', '0x0000', f'@hnor{n}'])
            ops += say(g['text'], True)
            ops.append(f'label:hnor{n}')
            ops.append(cmd(1, 0))
            init = True
        if show in ('explicit', 'both'):
            ops += say(g['text'], init)
            init = False
        if g.get('outro'):
            ops += say(g['outro'], init)
        ops += [['op', 'goto', f'@hdone{n}'], f'label:hnone{n}']
        ops += say(g['exhausted'], True)
        ops.append(f'label:hdone{n}')
        return ops
    fam = g['archive']
    ops += say(g['ask'])
    ops.append(['op', 'check_and_branch', '0xC83C', '0x0001', f'@hno{n}'])
    ops.append(cmd(2, fam))
    ops.append(['op', 'check_and_branch', '0xD8E1', '0x0000', f'@hempty{n}'])
    ops.append(f'label:hloop{n}')
    ops.append(cmd(3, fam))
    ops.append(['op', 'check_and_branch', '0xD8E1', '0x0000', f'@hend{n}'])
    ops.append(['op', 'check_and_branch', '0xD8E1', '0x0002', f'@hlast{n}'])
    ops += say(g['entry'], True)
    ops += say(g['more'])
    ops.append(['op', 'check_and_branch', '0xC83C', '0x0001', f'@hno{n}'])
    ops.append(['op', 'goto', f'@hloop{n}'])
    ops.append(f'label:hlast{n}')
    ops += say(g['entry'], True)
    ops += say(g['end'])
    ops.append(['op', 'goto', f'@hdone{n}'])
    ops.append(f'label:hend{n}')
    ops += say(g['end'], True)
    ops.append(['op', 'goto', f'@hdone{n}'])
    ops.append(f'label:hempty{n}')
    ops += say(g['empty'], True)
    ops.append(['op', 'goto', f'@hdone{n}'])
    ops.append(f'label:hno{n}')
    if g.get('no'):
        ops += say(g['no'])
    ops.append(f'label:hdone{n}')
    return ops


# ---------------------------------------------------------------------------
# bank $79 data, the regions
# ---------------------------------------------------------------------------

def _str_db(s):
    from . import textenc as T
    b = (T.encode(s) if s else []) + [0xF0]
    return '    db ' + ', '.join(f'${x:02X}' for x in b)


def data_lines(prj):
    """Bank $79's generated hint data (always emitted with the bank's head)."""
    on = active(prj.custom)
    out = ['; ' + '=' * 77,
           '; THE BREEDING HINTS (generated by editor2/core/hints.py, S158): the pool, the',
           '; monuments, the archives\' lists, the words, the riddles.',
           '; ' + '=' * 77]
    if not on:
        return out + ['HINT_COUNT EQU 0', 'HINT_MON_COUNT EQU 0', 'HintTable:',
                      'HintRiddles:', 'HintMonTable:', 'HintFamLists:',
                      *['    dw HintNoList' for _ in FAMILIES], 'HintNoList:', '    dw 0',
                      'HintFamWords:', *['    dw HintNoWord' for _ in FAMILIES],
                      'HintNoWord:', 'HintBredWord:', 'HintUnbredWord:', '    db $F0']
    from . import gamedata as G
    from .project import REPO_ROOT
    cfg = settings(prj.custom)
    hints, count, holes = pool(prj)
    names = G.monster_names(getattr(prj, 'repo_root', None) or REPO_ROOT)
    nm = (lambda m: FAMILIES[m - 0xF0] if m >= 0xF0 else names.get(m, str(m)))
    by_num = {c['number']: c for c in hints}
    out.append(f'HINT_COUNT EQU {count}          ; hint numbers 0-{max(count - 1, 0)} '
               f'({len(hints)} in the pool, {len(holes)} holes) — mode {cfg["mode"]}')
    out.append('HintTable:   ; dw special row ($FFFF hole), db pedigree, mate, child, '
               'min plus, family ($FF hole), 0')
    for k in range(count):
        c = by_num.get(k)
        if c is None:
            out.append(f'    dw $FFFF\n    db $00, $00, $00, $00, $FF, $00   ; [{k}] hole '
                       f'({holes.get(k, "unused")})')
            continue
        out.append(f"    dw {c['row']}\n    db ${c['p1']:02X}, ${c['p2']:02X}, "
                   f"${c['child']:02X}, {c['plus']}, {c['fam']}, $00   ; [{k}] "
                   f"{nm(c['p1'])} x {nm(c['p2'])}" + (f" +{c['plus']}" if c['plus'] else '')
                   + f" -> {nm(c['child'])} ({c['key']})")
    out.append('HintRiddles:   ; dw a riddle (0 = none)')
    riddles = {}
    for k in range(count):
        c = by_num.get(k)
        did = cfg['riddles'].get(c['key']) if c else None
        if did:
            riddles[k] = did
            out.append(f'    dw HintRiddle_{k}   ; [{k}]')
        else:
            out.append(f'    dw 0   ; [{k}]')
    mons = getattr(prj, '_hint_monuments', [])
    out.append(f'HINT_MON_COUNT EQU {len(mons)}')
    out.append('HintMonTable:   ; db room slot, families 0-7, families 8-10 | $80 skip owned')
    for gid, (rid, m, slot) in enumerate(mons):
        fm = families_mask(m)
        hi = (fm >> 8) | (0x80 if m.get('skip_owned', True) else 0)
        out.append(f'    db {slot}, ${fm & 0xFF:02X}, ${hi:02X}   ; [{gid}] {rid} '
                   f"'{m['id']}' ({', '.join(m.get('families') or ['every family'])}"
                   f"{'; skip owned' if m.get('skip_owned', True) else ''})")
    out.append('HintFamLists:   ; per family: the archive order (dw n, n x dw hint)')
    for f in FAMILIES:
        out.append(f'    dw HintFamList_{f}')
    for i, f in enumerate(FAMILIES):
        mem = sorted((c for c in hints if c['fam'] == i),
                     key=lambda c: (c['child'], c['row']))
        out.append(f'HintFamList_{f}:')
        out.append(f'    dw {len(mem)}')
        for k in range(0, len(mem), 8):
            out.append('    dw ' + ', '.join(str(c['number']) for c in mem[k:k + 8]))
    out.append('HintFamWords:')
    for f in FAMILIES:
        out.append(f'    dw HintWord_{f}')
    for f, w in zip(FAMILIES, cfg['family_words']):
        out.append(f'HintWord_{f}:   ; "{w}"')
        out.append(_str_db(w))
    out.append(f'HintBredWord:   ; "{cfg["bred_word"]}"')
    out.append(_str_db(cfg['bred_word']))
    out.append(f'HintUnbredWord:   ; "{cfg["unbred_word"]}"')
    out.append(_str_db(cfg['unbred_word']))
    from . import textenc as T
    for k, did in sorted(riddles.items()):
        if isinstance(did, str):
            d = _dialogue(prj.custom, did)
            out.append(f'HintRiddle_{k}:   ; {did}')
        else:
            d = {'boxes': did, 'speaker': '', 'voice': 'none'}
            out.append(f"HintRiddle_{k}:   ; {by_num[k]['key']}")
        if d is None:
            raise HintError(f"custom.hints.riddles: {by_num[k]['key']!r} names dialogue "
                            f"{did!r}, which the project does not have")
        try:
            raw = T.entry_bytes(d)
        except T.TextError as ex:
            raise HintError(f'riddle {did!r}: {ex}')
        for j in range(0, len(raw), 16):
            out.append('    db ' + ', '.join(f'${x:02X}' for x in raw[j:j + 16]))
    return out


# S158: bank $79 holds the engine head (≈ 2.4 KB measured S158: HintTable at $4A0D in a
# build with the Milly hook + new game + memorial) and the other hooks' data; the hint
# data must fit the rest. Measured: the 823-hint blacklist pool of the original table =
# 10,226 B ($4A0D-$71FE), fits.
BANK79_HINT_BUDGET = 12_500


def data_bytes(prj, hints, count, cfg):
    """An estimate of the hint data's bytes in bank $79 (data_lines' layout)."""
    from . import textenc as T
    n = 8 * count + 2 * count + 3 * len(getattr(prj, '_hint_monuments', [])) + 22
    n += 22 + 2 * len(hints) + 22
    n += sum(len(T.encode(w)) + 1 for w in cfg['family_words'])
    n += len(T.encode(cfg['bred_word'])) + len(T.encode(cfg['unbred_word'])) + 2
    keys = {c['key'] for c in hints}
    for k, v in cfg['riddles'].items():
        if k in keys:
            try:
                d = v if isinstance(v, str) else None
                boxes = (_dialogue(prj.custom, d) or {}).get('boxes') if d else v
                n += len(T.entry_bytes({'boxes': boxes, 'speaker': '', 'voice': 'none'}))
            except Exception:                              # noqa: BLE001 — reported elsewhere
                n += 64
    return n


HINT_REGION = 'hint_breed_16'
VANILLA_16 = '    call BreedResolveOffspring\n'
HOOK_16 = ('    call HintBreed16                ; S158 breeding hints: resolve, then bank $79\n'
           '                                    ;   entry 11 HintBreed marks the cross (hints.py)\n')


def emit_region_breed(prj, warnings):
    return HOOK_16 if active(prj.custom) else VANILLA_16


REGIONS = [(HINT_REGION, 'patches/bank_016.asm', emit_region_breed, 0x16)]


# ---------------------------------------------------------------------------
# checks (validators.validate)
# ---------------------------------------------------------------------------

def hint_texts(prj):
    """The dialogue ids the hint inserts may be used in."""
    out = set()
    try:
        cfg = settings(prj.custom)
    except HintError:
        return out
    out |= {v for v in cfg['riddles'].values() if isinstance(v, str)}
    out |= {v for v in cfg['words'].values() if isinstance(v, str)}
    out |= {default_word_id(r) for r in WORD_KEYS}
    for r in prj.custom.get('rooms') or []:
        if not isinstance(r, dict):
            continue
        for m in room_monuments(r):
            out |= {m.get(k) for k in TEXT_ROLES_MON if isinstance(m.get(k), str)}
        for a in room_archives(r):
            out |= {a.get(k) for k in TEXT_ROLES_ARC if isinstance(a.get(k), str)}
    return out


def _generated(did):
    return isinstance(did, str) and (did.startswith(SCRIPT_PREFIX)
                                     or did.startswith('hints_default_'))


def problems(prj):
    """-> (errors, warnings) about the breeding hints, in words."""
    errs, warns = [], []
    err = getattr(prj, 'hint_error', None)
    if err:
        errs.append(f'breeding hints: {err}')
        return errs, warns
    try:
        cfg = settings(prj.custom)
    except HintError as ex:
        return [str(ex)], warns
    allowed = hint_texts(prj)
    from . import textenc as T
    for d in prj.custom.get('dialogue') or []:
        if not isinstance(d, dict):
            continue
        body = d.get('boxes') or d.get('text') or d.get('lines') or ''
        if T.uses_hint(body) and d.get('id') not in allowed and not _generated(d.get('id')):
            errs.append(f"dialogue {d.get('id')!r}: {{parent1}} / {{parent2}} / {{child}} / "
                        "{bred} only work in the breeding hints' words (a monument, an "
                        "archive, a riddle — elsewhere the game prints whatever is in memory)")
        if '{family}' in __import__('json').dumps(body):
            errs.append(f"dialogue {d.get('id')!r}: {{family}} only works in an archive's own "
                        "words (written in the archive / the Hints settings, not as dialogue)")
    if not active(prj.custom):
        return errs, warns
    for did in cfg['riddles'].values():
        if isinstance(did, str) and _dialogue(prj.custom, did) is None:
            errs.append(f'breeding hints: a riddle names dialogue {did!r}, which the project '
                        'does not have')
    try:
        hints, count, holes = pool(prj)
    except HintError as ex:
        errs.append(f'breeding hints: {ex}')
        return errs, warns
    except Exception as ex:                            # noqa: BLE001 — a bad breeding table
        errs.append(f'breeding hints: the pool could not be worked out ({ex})')
        return errs, warns
    if not hints:
        warns.append('breeding hints: the hint pool is EMPTY — every monument says its '
                      '"worn away" words and no archive lists anything'
                      + (' (whitelist mode with nothing included)'
                         if cfg['mode'] == 'whitelist' else ''))
    est = data_bytes(prj, hints, count, cfg)
    if est > BANK79_HINT_BUDGET:
        errs.append(f'breeding hints: the pool needs about {est:,} bytes of bank $79 — at most '
                    f'{BANK79_HINT_BUDGET:,} fit beside the other story hooks ({len(hints)} hints'
                    f', {count} numbers). Use the whitelist (curate the crosses), or renumber '
                    'after taking many out')
    per = {}
    for c in hints:
        per[c['fam']] = per.get(c['fam'], 0) + 1
    big = [f'{FAMILIES[f]} {n}' for f, n in sorted(per.items()) if n > 30]
    if big:
        warns.append('breeding hints: long archives (' + ', '.join(big) + ' hints) — each '
                     'entry is a box and a "Keep reading?" (the whitelist curates them)')
    stale = [k for k in cfg['riddles'] if k not in {c['key'] for c in hints}]
    if stale:
        warns.append(f'breeding hints: {len(stale)} riddle(s) for a cross not in the pool '
                     '(kept; shown again if the cross comes back)')
    return errs, warns
