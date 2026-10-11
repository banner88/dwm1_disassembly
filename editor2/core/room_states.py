"""room_states.py — which ROOM STATES a room keeps (S144, ROADMAP ARC CAP4c; no Qt).

User S144: "I want to be able to select states and play with states, vanilla and
custom"; a kept state the room's own scripts switch to "should stay" (a beaten
boss stays beaten after a save); a copy kept at one moment of the story talks as
it did then ("I will honestly edit a bunch of the NPC talking points anyway").

A room state = one step entry of a screen (its tile layout, NPC list, exits; the
screen's step counter picks it — ROOM_DATA_FORMAT "Room State System"). Before
S144 "Make editable" copied EVERY state of a game room and tied the copy to the
original's counters (S118c `step_counter.vanilla`): in a new romhack the original
story never runs, so every copy showed its start-of-game state for good.

A KEEP SPEC says, per screen, which states stay and which one the screen starts in:

    {"point": <story point index | None>,   # balance.VANILLA_STEPS index: "about to do"
     "fold_talk": true,                     # story flags ON at the point = fixed answers
     "screens": {"0": {"keep": [3, 4], "start": 3},
                 "5": {"follow": true}}}    # (a copy only) keep following the game

`apply(doc, room, spec)` lowers it IN the project data (the compiler is untouched —
everything is ordinary project.json: states[], scripts, flags, state rules):

  * states: the kept ones in their order with the START moved first (a custom
    room's transient counter is 0 after a CONTINUE — PROJECT_COMPILER §2.6); one
    kept state = a plain screen (layout / attr / palette carried up);
  * every script of the project that names one of the room's counters (labels
    `wCustomStep_…`, or the vanilla address a copy follows): a TEST of a one-state
    screen's counter becomes a fixed answer (the kept state's ORIGINAL number);
    of a several-state screen it is renumbered (a dropped state = never true);
    a WRITE to a one-state screen is dropped, to a several-state screen
    renumbered (a dropped state = the write is dropped);
  * persistence (user: "yes of course it should stay"): each remaining write of a
    kept, non-start state also sets a project flag of its own (and clears the
    screen's other state flags); a state rule "state n when that flag is set"
    re-selects it at every load — flags are saved, counters are not;
  * talk (`fold_talk` + `point`): a test of a vanilla story flag that the game has
    ON at the point (`story_state.state_at`), that no script of the game ever clears
    (measured S144: none of them is cleared anywhere — 587 scripts, 19 cleared flags,
    none of them story flags ON at any point) and that no script of the project
    clears, becomes a fixed answer;
  * unreachable steps of the changed scripts are removed; scripts no kept state
    uses (and nothing else in the project names) are dropped — a dropped middle
    entry of the room's script table points at a 1-word stub (the table is
    positional: `emitters._room_scripts`), trailing ones are cut;
  * layouts / palettes only the dropped states used are removed (as Delete room).

`default_spec` — what Make editable proposes: the story point = after Starry Night
(`balance.POSTGAME_FROM`), or "about to do its gate" for a game room that is a
gate's boss floor (`extracted/gate_names.json` `boss_map`); per screen the state
the game has at that point, plus every state the room's OWN scripts (kept, folded
at that point) can switch the screen to — a fixed point over the scripts. A
screen whose own scripts write values that are not states (the breeding
ceremony's `$D951` codes) keeps following the game.
"""

import copy
import json
import os

from .formats import val

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# opcode codes of the ops the lowering rewrites (names as in scriptgen.OPS)
CODE_NAMES = {0x00: 'if_flag_clear', 0x01: 'if_flag_set', 0x02: 'clear_flag',
              0x03: 'set_flag', 0x12: 'write_ram', 0x13: 'write_ram2', 0x14: 'goto',
              0x15: 'check_and_branch'}


def op_name(it):
    """The scriptgen name of an op item (hex ops '0x15' mapped by code)."""
    nm = it[1]
    if isinstance(nm, str) and not nm.lower().startswith(('0x', '$')):
        return nm
    try:
        return CODE_NAMES.get(val(nm), nm)
    except Exception:                                    # noqa: BLE001
        return nm


def _num(x):
    try:
        return val(x)
    except Exception:                                    # noqa: BLE001
        return None


def _is_ref(p):
    return isinstance(p, str) and p.startswith('@')


# ------------------------------------------------------------------ the game
_CLEARED = {}


def game_cleared_flags(repo=REPO):
    """Every flag some script of the original game clears (op $02). Cached."""
    if repo not in _CLEARED:
        from . import cutscenes as CS
        rom = open(os.path.join(repo, 'data', 'DWM-original.gbc'), 'rb').read()
        cat = CS.Catalogue(rom, repo)
        out = set()
        for m in cat.map_types():
            for sc in cat.scripts(m):
                if sc is None:
                    continue
                for st in sc.steps.values():
                    if st.code == 0x02 and st.params:
                        out.add(st.params[0])
        _CLEARED[repo] = out
    return _CLEARED[repo]


_STATES = {}


def story_state(point, repo=REPO):
    """story_state.state_at(point), cached."""
    key = (repo, point)
    if key not in _STATES:
        from . import story_state as SS
        _STATES[key] = SS.state_at(point, repo)
    return _STATES[key]


def boss_gates(repo=REPO):
    """{vanilla map id: first gate id whose boss floor it is}."""
    out = {}
    try:
        gates = json.load(open(os.path.join(repo, 'extracted', 'gate_names.json')))['gates']
    except (OSError, ValueError, KeyError):
        return out
    for g in gates:
        try:
            out.setdefault(val(g['boss_map']), int(g['id']))
        except (KeyError, TypeError, ValueError):
            pass
    return out


def default_point(mid, repo=REPO):
    """The story point Make editable proposes for game room `mid`: about to do the
    gate whose boss floor it is, else right after Starry Night."""
    from .balance import VANILLA_STEPS, POSTGAME_FROM
    g = boss_gates(repo).get(mid)
    if g is not None and ('gate', g) in VANILLA_STEPS:
        return VANILLA_STEPS.index(('gate', g))
    return POSTGAME_FROM


def point_label(point):
    from .balance import VANILLA_STEPS, POSTGAME_FROM
    if point is None:
        return 'no story point'
    if point >= len(VANILLA_STEPS):
        return 'the end of the post-game'
    if point == POSTGAME_FROM:
        return 'right after Starry Night (the post-game)'
    kind, n = VANILLA_STEPS[point]
    if kind == 'gate':
        from . import place_names as _PN                 # noqa: F401
        try:
            names = {int(g['id']): g['name'] for g in json.load(open(os.path.join(
                REPO, 'extracted', 'gate_names.json')))['gates']}
        except (OSError, ValueError, KeyError):
            names = {}
        what = names.get(n, f'gate {n}')
    elif kind == 'class':
        what = f"arena class {'GFEDCBAS'[n]}"
    elif kind == 'starry':
        what = 'Starry Night'
    else:
        what = "Monster Grandpa's match"
    return f'about to do {what}' + (' (post-game)' if point > POSTGAME_FROM else '')


# ------------------------------------------------------------------ the room
def screen_keys(room):
    return sorted((room.get('screens') or {}), key=int)


def n_states(scr):
    return len(scr.get('states') or []) or 1


def counter_names(room, key):
    """Every LABEL a script may use for screen `key`'s counter: its label (dict
    form) and the compiler's default label. Never the vanilla address a copy
    follows: a script naming that address writes the ORIGINAL room (still in the
    game) — the copy's states are not its business any more."""
    from .project import Project
    scr = room['screens'][str(key)]
    sc = scr.get('step_counter')
    out = set()
    if isinstance(sc, dict):
        if sc.get('label'):
            out.add(sc['label'])
    try:
        out.add(Project._def_step_label(room, key))
    except Exception:                                    # noqa: BLE001
        pass
    return out


def vanilla_counter(room, key, repo=REPO):
    """The original game's counter of a copied game room's screen (or None)."""
    scr = room['screens'][str(key)]
    sc = scr.get('step_counter')
    if isinstance(sc, dict) and sc.get('vanilla') is not None:
        return val(sc['vanilla'])
    src = room.get('source_mapID')
    if src is None or not is_copy(room) or room.get('states_kept'):
        return None                  # S144: kept states are renumbered
    try:
        from .vanilla import VanillaTable
        return VanillaTable(repo).counter(val(src), int(key))
    except Exception:                                    # noqa: BLE001
        return None


def is_copy(room):
    """A copy of a game room (Make editable): its screens carry the counter label
    the copy step gave them (S118c) — not a new room drawn from a game room's tiles."""
    try:
        src = val(room.get('source_mapID'))
    except Exception:                                    # noqa: BLE001
        return False
    if src is None or not 0 <= src < 0x6B:
        return False
    rid = str(room.get('id', ''))
    scrs = room.get('screens') or {}
    return bool(scrs) and all(
        isinstance(s.get('step_counter'), dict) and (
            s['step_counter'].get('vanilla') is not None or
            s['step_counter'].get('label') == f"wCustomStep_{rid}_S{k}".replace('-', '_'))
        for k, s in scrs.items())


def entries_of(scr, idx):
    sts = scr.get('states')
    st = sts[idx] if sts else scr
    return st.get('npcs') or []


def entry_scripts(room, entries):
    """Script table indices / ids the NPC / spot entries run."""
    idxs, ids = set(), set()
    for e in entries:
        if e.get('kind') == 'raw':
            b = [val(x) for x in e['bytes']]
            if len(b) >= 5 and b[4] != 0xFF:
                idxs.add(b[4])
        else:
            s = e.get('script')
            if isinstance(s, int):
                idxs.add(s)
            elif isinstance(s, str) and s:
                ids.add(s)
    return idxs, ids


# --------------------------------------------------------------- the folding
class Plan:
    """How one counter name folds: single (the kept state's ORIGINAL number) or
    a renumbering {old: new} of a several-state screen; `follow` = untouched."""

    def __init__(self, key, single=None, remap=None, follow=False):
        self.key = key
        self.single = single
        self.remap = remap or {}
        self.follow = follow


def fold_ops(items, plans, flags_on, live=False):
    """Rewrite one script's items. plans: {counter name: Plan}; flags_on: the
    vanilla flags answered ON. live=True (the defaults' analysis): a several-state
    screen's tests stay both ways and its writes keep their ORIGINAL value.
    Returns (items, writes [(name, old value)], report)."""
    rep = {'tests': 0, 'writes_dropped': 0, 'flags': 0, 'other': []}
    out = []
    for it in items:
        if not (isinstance(it, list) and it and it[0] == 'op'):
            out.append(it)
            continue
        nm = op_name(it)
        p = list(it[2:])
        tgt = p[0] if p else None
        plan = plans.get(tgt) if isinstance(tgt, str) else None
        if plan is not None and not plan.follow and nm == 'check_and_branch' and len(p) == 3:
            v = _num(p[1])
            rep['tests'] += 1
            if plan.single is not None:
                if v == plan.single:
                    out.append(['op', 'goto', p[2]])
                continue
            if live:
                out.append(it)
            elif v in plan.remap:
                out.append(['op', 'check_and_branch', p[0], f'0x{plan.remap[v]:04X}', p[2]])
            continue
        if plan is not None and not plan.follow and nm in ('write_ram', 'write_ram2') \
                and len(p) == 2:
            v = _num(p[1])
            if nm == 'write_ram2' and v is not None:
                v &= 0xFF
                rep['other'].append('write_ram2 on a room counter (low byte kept)')
            if plan.single is not None:
                rep['writes_dropped'] += 1
                if live:                                       # the analysis sees it
                    out.append(['__w', p[0], v, plan.key])
                continue
            if live:
                out.append(['__w', p[0], v, plan.key])
                continue
            if v in plan.remap:
                out.append(['__w', p[0], plan.remap[v], plan.key])
            else:
                rep['writes_dropped'] += 1
            continue
        if nm in ('if_flag_set', 'if_flag_clear') and len(p) == 2:
            f = _num(p[0])
            if f is not None and f in flags_on:
                rep['flags'] += 1
                if nm == 'if_flag_set':
                    out.append(['op', 'goto', p[1]])
                continue
        if plan is not None and not plan.follow and nm not in ('check_and_branch',):
            rep['other'].append(f'{nm} names a room counter')
        out.append(it)
    out = prune(out)
    writes = []
    final = []
    for it in out:
        if isinstance(it, list) and it and it[0] == '__w':
            writes.append((it[1], it[2], it[3]))
            final.append(it)
        else:
            final.append(it)
    return final, writes, rep


def prune(items):
    """Drop unreachable items (only `end` and `goto` stop the fall-through — a
    room change is kept conservative), labels nobody targets, and a goto to the
    very next label. Ends on `end` / `goto` (scriptgen's S70 rule)."""
    lab = {}
    for i, it in enumerate(items):
        if isinstance(it, str) and it.startswith('label:'):
            lab[it[6:]] = i
    reach = set()
    todo = [0]
    while todo:
        i = todo.pop()
        while i < len(items) and i not in reach:
            reach.add(i)
            it = items[i]
            if isinstance(it, str):
                i += 1
                continue
            if it[0] == 'end':
                break
            if it[0] == 'op':
                for x in it[2:]:
                    if _is_ref(x) and x[1:] in lab:
                        todo.append(lab[x[1:]])
                if op_name(it) == 'goto':
                    break
            i += 1
    out = [it for i, it in enumerate(items) if i in reach]
    changed = True
    while changed:
        changed = False
        used = {x[1:] for it in out if isinstance(it, list) and it and it[0] == 'op'
                for x in it[2:] if _is_ref(x)}
        nxt = [it for it in out if not (isinstance(it, str) and it.startswith('label:')
                                        and it[6:] not in used)]
        res = []
        for i, it in enumerate(nxt):
            if (isinstance(it, list) and it and it[0] == 'op' and op_name(it) == 'goto'
                    and len(it) > 2 and _is_ref(it[2])):
                j = i + 1
                skip = False
                while j < len(nxt) and isinstance(nxt[j], str):
                    if nxt[j] == 'label:' + it[2][1:]:
                        skip = True
                        break
                    j += 1
                if skip:
                    changed = True
                    continue
            res.append(it)
        if len(res) != len(out):
            changed = True
        out = res
    if not out or not (isinstance(out[-1], list) and (
            out[-1][0] == 'end' or (out[-1][0] == 'op' and op_name(out[-1]) == 'goto'))):
        out.append(['end'])
    return out


def words(items):
    """Script size in words (1 per op + 1 per param, 1 per text / end)."""
    n = 0
    for it in items:
        if isinstance(it, str):
            continue
        if it[0] in ('end', 'text'):
            n += 1
        elif it[0] == '__w':
            n += 3
        else:
            n += 1 + len(it) - 2
    return n


# ---------------------------------------------------------------- analysis
def _flags_on(doc, point, fold_talk, repo=REPO):
    if not fold_talk or point is None:
        return set()
    on = set(story_state(point, repo)['flags_on'])
    on -= game_cleared_flags(repo)
    # a flag any project script clears stays a live check
    for sc in doc.custom.get('scripts') or []:
        for it in sc.get('ops') or []:
            if isinstance(it, list) and it and it[0] == 'op' and op_name(it) == 'clear_flag':
                f = _num(it[2]) if len(it) > 2 else None
                if f is not None:
                    on.discard(f)
    return on


def _scripts_by_id(doc):
    return {s.get('id'): s for s in doc.custom.get('scripts') or []}


def _kept_script_ids(room, keep):
    """Script ids the kept states run: their NPC / spot entries + entry script 0."""
    table = {int(k): v for k, v in (room.get('scripts') or {}).items()}
    idxs, ids = {0}, set()
    for k in screen_keys(room):
        scr = room['screens'][k]
        for i in keep.get(k, range(n_states(scr))):
            a, b = entry_scripts(room, entries_of(scr, i))
            idxs |= a
            ids |= b
    out = {table[i] for i in idxs if i in table and isinstance(table[i], str)}
    return out | {i for i in ids if i in set(table.values())} | ids


def screen_report(doc, room, point, repo=REPO):
    """Per screen: {key: {'n': states, 'counter': vanilla addr|None,
    'at_point': the game's state there (clamped) | None}}."""
    ram = story_state(point, repo)['ram'] if point is not None else {}
    out = {}
    for k in screen_keys(room):
        scr = room['screens'][k]
        n = n_states(scr)
        vc = vanilla_counter(room, k, repo)
        at = None
        if vc is not None:
            at = min(ram.get(vc, 0), n - 1)
        out[k] = {'n': n, 'counter': vc, 'at_point': at}
    return out


def default_spec(doc, room, point=None, fold_talk=True, repo=REPO):
    """What the dialog proposes (see the module doc). `point` None = the room's
    default (a copy: `default_point(source)`; any other room: no story point —
    every state, start 0)."""
    copy_ = is_copy(room) and not room.get('states_kept')
    if point is None and copy_:
        point = default_point(val(room['source_mapID']), repo)
    rep = screen_report(doc, room, point, repo)
    if not copy_ or point is None:
        return {'point': None, 'fold_talk': False,
                'screens': {k: {'keep': list(range(i['n'])), 'start': 0}
                            for k, i in rep.items()}}
    keep = {k: {(i['at_point'] or 0)} for k, i in rep.items()}
    follow = set()
    flags_on = _flags_on(doc, point, fold_talk, repo)
    by_id = _scripts_by_id(doc)
    for _round in range(32):
        plans = {}
        for k in screen_keys(room):
            if k in follow:
                for nm in counter_names(room, k):
                    plans[nm] = Plan(k, follow=True)
                continue
            kk = keep[k]
            for nm in counter_names(room, k):
                plans[nm] = Plan(k, single=next(iter(kk))) if len(kk) == 1 else \
                    Plan(k, remap={v: v for v in kk})
        grew = False
        for sid in _kept_script_ids(room, {k: sorted(v) for k, v in keep.items()}):
            sc = by_id.get(sid)
            if not sc or not sc.get('ops'):
                continue
            _items, writes, _r = fold_ops(sc['ops'], plans, flags_on, live=True)
            for _nm, v, k in writes:
                if k in follow or v is None:
                    continue
                if not 0 <= v < rep[k]['n']:
                    follow.add(k)            # a counter used as a variable
                    grew = True
                elif v not in keep[k]:
                    keep[k].add(v)
                    grew = True
        if not grew:
            break
    screens = {}
    for k, i in rep.items():
        if k in follow:
            screens[k] = {'follow': True}
        else:
            start = i['at_point'] or 0
            screens[k] = {'keep': sorted(keep[k]), 'start': start}
    return {'point': point, 'fold_talk': bool(fold_talk), 'screens': screens}


# ------------------------------------------------------------------ apply
def _norm_spec(room, spec):
    out = {}
    for k in screen_keys(room):
        s = (spec.get('screens') or {}).get(k) or (spec.get('screens') or {}).get(int(k))
        n = n_states(room['screens'][k])
        if s is None:
            s = {'keep': list(range(n)), 'start': 0}
        if s.get('follow'):
            out[k] = {'follow': True}
            continue
        keep = sorted({int(x) for x in s.get('keep') or [] if 0 <= int(x) < n})
        start = int(s.get('start', keep[0] if keep else 0))
        if not keep:
            keep = [start]
        if start not in keep:
            keep = sorted(set(keep) | {start})
        out[k] = {'keep': keep, 'start': start}
    return out


def _flatten_into(doc, scr, st):
    """One state left: the screen itself carries it. Same picture: a state's attr
    = its own > its layout item's > the screen rule (`Project.state_attr_entry`),
    a plain screen's = its own > its layout item's > render.attr
    (`screen_attr_entry`) — so a state that took its layout item's attr gets it
    written out."""
    scr.pop('states', None)
    if 'attr' in st:
        scr['attr'] = st['attr']
    elif isinstance(st.get('layout'), dict) and 'id' in st['layout']:
        item = next((l for l in doc.layouts if l.get('id') == st['layout']['id']), None)
        if item is not None and 'attr' in item:
            scr['attr'] = {'id': item['id']}
    for key in ('layout', 'palette'):
        if key in st:
            scr[key] = st[key]
    scr['npcs'] = st.get('npcs', [])
    scr['exits'] = st.get('exits', [])


def _layout_refs(doc):
    """Every layout id any room names (screens, states, render.attr) — any key."""
    out = set()

    def walk(x):
        if isinstance(x, dict):
            for kk, v in x.items():
                if kk in ('layout', 'attr') and isinstance(v, dict) and 'id' in v:
                    out.add(v['id'])
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    for r in doc.rooms:
        walk(r)
    return out


def _palette_refs(doc):
    out = set()

    def walk(x):
        if isinstance(x, dict):
            for kk, v in x.items():
                if kk == 'palette' and isinstance(v, str):
                    out.add(v)
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    for r in doc.rooms:
        walk(r)
    return out


def _all_strings(x, acc):
    if isinstance(x, str):
        acc.add(x)
    elif isinstance(x, dict):
        for v in x.values():
            _all_strings(v, acc)
    elif isinstance(x, list):
        for v in x:
            _all_strings(v, acc)
    return acc


def locked_reason(doc, room):
    """Why a room's states cannot be chosen, or None: the arena copies (custom.arena —
    the game's match scripts switch their states, S128) keep every state."""
    ar = doc.custom.get('arena') or {}
    if isinstance(ar, dict) and room.get('id') in (ar.get('lobby'), ar.get('battle')):
        return ('your arena\'s rooms keep every state — the game\'s own match scripts switch '
                'them (the arena tab owns these rooms)')
    return None


def apply(doc, room, spec, repo=REPO):
    """Lower a keep spec into the project (module doc). Returns a report dict."""
    why = locked_reason(doc, room)
    if why:
        raise ValueError(why)
    spec = dict(spec or {})
    norm = _norm_spec(room, spec)
    point = spec.get('point')
    fold_talk = bool(spec.get('fold_talk')) and point is not None
    rid = str(room.get('id'))
    rep = {'screens': {}, 'scripts_before': 0, 'scripts_after': 0, 'dropped_scripts': [],
           'flags': [], 'rules': 0, 'tests': 0, 'writes_dropped': 0, 'talk': 0,
           'layouts_removed': [], 'palettes_removed': [], 'other': []}
    before_layouts = {l.get('id') for l in doc.layouts}
    before_palettes = {p.get('id') for p in doc.palettes}
    layouts_before = _layout_refs(doc)
    palettes_before = _palette_refs(doc)
    # 1. plans per counter name, states rebuilt
    plans = {}
    remaps = {}
    for k in screen_keys(room):
        scr = room['screens'][k]
        s = norm[k]
        names = counter_names(room, k)
        if s.get('follow'):
            for nm in names:
                plans[nm] = Plan(k, follow=True)
            rep['screens'][k] = 'follows the game'
            continue
        keep, start = s['keep'], s['start']
        order = [start] + [i for i in keep if i != start]
        remap = {old: new for new, old in enumerate(order)}
        remaps[k] = remap
        for nm in names:
            plans[nm] = Plan(k, single=start) if len(order) == 1 else Plan(k, remap=remap)
        sts = scr.get('states')
        if sts:
            new = [sts[i] for i in order]
            if len(new) == 1:
                _flatten_into(doc, scr, new[0])
            else:
                # the base fields stay; a state that relied on them keeps them as
                # they were (moving a state never changes what it draws)
                scr['states'] = new
        # the counter: its own (no longer the game's); the label is kept so any
        # script that still names it assembles
        sc = scr.get('step_counter')
        lbl = sc.get('label') if isinstance(sc, dict) else None
        if isinstance(sc, dict) and sc.get('vanilla') is not None:
            sc = {'label': lbl} if lbl else 'auto'
            scr['step_counter'] = sc
        rep['screens'][k] = (f"states {', '.join(str(i) for i in order)} "
                             f"(starts in {start})" if len(order) > 1 else
                             f"state {start} only")
    # 2. remap the room's own state rules
    rules = room.get('state_rules') or []
    if rules:
        new_rules = []
        for ru in rules:
            st = int(val(ru.get('state', 0)))
            scrs = ru.get('screens')
            ks = [str(x) for x in scrs] if scrs is not None else screen_keys(room)
            keep_ks = [k for k in ks if k in remaps and st in remaps[k]]
            if not keep_ks:
                continue
            news = {remaps[k][st] for k in keep_ks}
            if len(news) == 1:
                r2 = dict(ru)
                r2['state'] = news.pop()
                if scrs is not None or len(keep_ks) != len(ks):
                    r2['screens'] = [int(k) for k in keep_ks]
                new_rules.append(r2)
            else:
                for k in keep_ks:
                    r2 = dict(ru)
                    r2['state'] = remaps[k][st]
                    r2['screens'] = [int(k)]
                    new_rules.append(r2)
        room['state_rules'] = new_rules
        if not new_rules:
            room.pop('state_rules', None)
    # 3. fold every script of the project that names these counters; the room's
    #    own scripts also fold the story flags
    flags_on = _flags_on(doc, point, fold_talk, repo)
    by_id = _scripts_by_id(doc)
    table = {int(k): v for k, v in (room.get('scripts') or {}).items()}
    own_ids = {v for v in table.values() if isinstance(v, str)}
    rep['scripts_before'] = sum(words(by_id[s]['ops']) for s in own_ids
                                if s in by_id and by_id[s].get('ops')) * 2
    names = set(plans)
    persist = {}                     # (key, new state) -> flag name
    pending = []
    for sc in doc.custom.get('scripts') or []:
        ops = sc.get('ops')
        if not ops:
            continue
        mine = sc.get('id') in own_ids
        touches = any(isinstance(it, list) and it and it[0] == 'op' and any(
            (isinstance(p, str) and p in names) or
            False for p in it[2:3])
            for it in ops)
        if not mine and not touches:
            continue
        new, writes, r = fold_ops(ops, plans, flags_on if mine else set())
        rep['tests'] += r['tests']
        rep['writes_dropped'] += r['writes_dropped']
        rep['talk'] += r['flags']
        rep['other'] += [f"{sc.get('id')}: {o}" for o in r['other']]
        pending.append((sc, new))
        for _nm, v, k in writes:
            if len(remaps.get(k, {})) > 1 and v:
                persist.setdefault((k, v), None)
    # 4. persistence flags + state rules
    if persist:
        base = doc._slug(room.get('name') or rid)
        taken = {f.get('name') for f in doc.custom.get('flags') or []}
        for (k, v) in sorted(persist, key=lambda t: (int(t[0]), t[1])):
            nm = f'{base}_s{k}_state{v}'
            n = 2
            while nm in taken:
                nm = f'{base}_s{k}_state{v}_{n}'
                n += 1
            taken.add(nm)
            doc.add_flag(nm, f'S144: {room.get("name") or rid} screen {k} is in its kept '
                             f'state {v} (set by the room\'s own scripts; a state rule '
                             'restores it at every load — flags are saved)')
            persist[(k, v)] = nm
            rep['flags'].append(nm)
        # raw script ops carry flag NUMBERS (the compiler resolves names only in
        # authored forms — rules, talk steps); the new flags have fixed ones
        nums = {f.get('name'): f.get('index') for f in doc.custom.get('flags') or []}
        rules = room.setdefault('state_rules', [])
        for (k, v), nm in sorted(persist.items(), key=lambda t: (int(t[0][0]), t[0][1])):
            rules.insert(0, {'state': v, 'when': [{'flag': nm}], 'screens': [int(k)],
                             'comment': 'S144: kept state (saved)'})
            rep['rules'] += 1
    for sc, new in pending:
        out = []
        for it in new:
            if isinstance(it, list) and it and it[0] == '__w':
                nm, v, k = it[1], it[2], it[3]
                out.append(['op', 'write_ram', nm, f'0x{v:04X}'])
                for (kk, vv), fl in sorted(persist.items(), key=lambda t: t[0][1]):
                    if kk != k:
                        continue
                    if vv == v:
                        out.append(['op', 'set_flag', nums[fl]])
                    else:
                        out.append(['op', 'clear_flag', nums[fl]])
            else:
                out.append(it)
        sc['ops'] = out
    # 5. scripts no kept state uses
    keep_new = {k: list(range(n_states(room['screens'][k]))) for k in screen_keys(room)}
    used_ids = _kept_script_ids(room, keep_new)
    others = set()
    for r in doc.rooms:
        if r is room:
            others |= _all_strings({kk: vv for kk, vv in r.items() if kk != 'scripts'}, set())
        else:
            others |= _all_strings(r, set())
    for sc in doc.custom.get('scripts') or []:
        if sc.get('id') not in own_ids:
            _all_strings(sc, others)
    for kk, vv in doc.custom.items():
        if kk not in ('rooms', 'scripts', 'layouts', 'palettes', 'tilesets', 'dialogue'):
            _all_strings(vv, others)
    drop = set()
    for i, sid in sorted(table.items()):
        if i == 0 or not isinstance(sid, str):
            continue
        if sid in used_ids or sid in others:
            continue
        drop.add(i)
    if drop:
        last = max(table)
        keep_idx = [i for i in table if i not in drop]
        top = max(keep_idx) if keep_idx else 0
        stub = None
        new_table = {}
        for i in range(0, last + 1):
            if i not in table:
                continue
            if i not in drop:
                new_table[str(i)] = table[i]
            elif i < top:
                if stub is None:
                    stub = f'{rid}_unused'
                    n = 2
                    while stub in by_id:
                        stub = f'{rid}_unused_{n}'
                        n += 1
                    doc.custom['scripts'].append({
                        'id': stub, 'ops': [['end']],
                        'comment': 'S144: the script-table slot of a script no kept '
                                   'room state uses (the table is positional)'})
                new_table[str(i)] = stub
        room['scripts'] = new_table
        gone = {table[i] for i in drop}
        still = set(new_table.values())
        for sid in sorted(gone - still):
            rep['dropped_scripts'].append(sid)
        doc.custom['scripts'] = [s for s in doc.custom['scripts']
                                 if s.get('id') not in (gone - still)]
        # tile patches only dropped scripts drew
        pd = room.get('patch_data') or {}
        if pd:
            names_used = set()
            for s in doc.custom['scripts']:
                if s.get('id') in still:
                    for it in s.get('ops') or []:
                        for p in (it[2:] if isinstance(it, list) else []):
                            if isinstance(p, str) and p.startswith('patch:'):
                                names_used.add(p.split(':', 1)[1])
            for nm in list(pd):
                if nm not in names_used:
                    pd.pop(nm)
            if not pd:
                room.pop('patch_data', None)
    by_id = _scripts_by_id(doc)
    rep['scripts_after'] = sum(words(by_id[s]['ops']) for s in set(
        (room.get('scripts') or {}).values()) if s in by_id and by_id[s].get('ops')) * 2
    # 6. layouts / palettes only the dropped states used (as Delete room)
    lay_after = _layout_refs(doc)
    for lid in sorted((layouts_before - lay_after) & before_layouts):
        try:
            doc.remove_layout(lid)
            rep['layouts_removed'].append(lid)
        except KeyError:
            pass
    pal_after = _palette_refs(doc)
    for pid in sorted((palettes_before - pal_after) & before_palettes):
        if pid in {(r.get('render') or {}).get('palette') for r in doc.rooms}:
            continue
        doc.data['custom']['palettes'] = [p for p in doc.palettes if p.get('id') != pid]
        rep['palettes_removed'].append(pid)
    room['states_kept'] = {
        'point': point, 'fold_talk': fold_talk,
        'comment': (f'S144: room states kept — {point_label(point)}' if point is not None
                    else 'S144: room states kept')}
    doc.touch()
    return rep


def preview_copy(doc, mid, renderer, repo=REPO):
    """(scratch document, its every-state copy of game room `mid`) — what Make
    editable's dialog shows and proposes from, without touching `doc`. The scratch
    holds the project's scripts that clear a flag (they keep a flag a live check)."""
    from .document import Document
    sd = Document.__new__(Document)
    sd.path, sd.project_dir = doc.path, doc.project_dir
    clears = [s for s in doc.custom.get('scripts') or []
              if any(isinstance(it, list) and it and it[0] == 'op' and op_name(it) == 'clear_flag'
                     for it in s.get('ops') or [])]
    sd.data = {'meta': {}, 'custom': {'rooms': [], 'layouts': [], 'palettes': [],
                                      'scripts': copy.deepcopy(clears), 'flags': []}}
    sd.indent, sd.trailing_newline, sd.dirty, sd.revision = 1, True, False, 0
    sd._saved_text, sd._protected, sd.vanilla, sd.migrations = '', {}, None, []
    from . import place_names as PN
    rid = sd.clone_vanilla(mid, PN.vanilla_name(mid), repo, renderer)
    return sd, sd.room(rid)


def spec_summary(room, spec):
    """'GreatTree: 8 of 21 states kept' style counts: (kept, total)."""
    kept = total = 0
    for k in screen_keys(room):
        n = n_states(room['screens'][k])
        total += n
        s = (spec.get('screens') or {}).get(k) or {}
        kept += n if s.get('follow') else len(s.get('keep') or [0])
    return kept, total


def describe(rep):
    """One paragraph for the status line / log."""
    parts = []
    for k, s in sorted(rep['screens'].items(), key=lambda t: int(t[0])):
        parts.append(f'screen {k}: {s}')
    out = '; '.join(parts)
    if rep['dropped_scripts']:
        out += f" — {len(rep['dropped_scripts'])} script(s) no kept state uses left out"
    out += (f" — scripts {rep['scripts_before']:,} → {rep['scripts_after']:,} bytes")
    if rep['talk']:
        out += f" — {rep['talk']} story-flag test(s) answered"
    if rep['flags']:
        out += f" — {len(rep['flags'])} state(s) remembered by a flag (saved)"
    return out


__all__ = ['default_spec', 'apply', 'locked_reason', 'describe', 'preview_copy', 'spec_summary', 'default_point', 'point_label',
           'screen_report', 'is_copy', 'fold_ops', 'prune', 'words', 'game_cleared_flags']
