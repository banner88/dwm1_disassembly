"""story.py — STORY CHECKS, STORY COMMANDS, the STORY SPINE and QUESTS
(S129, ROADMAP P3.14b + P3.14c; PROJECT_COMPILER §2.42).

Headless (no Qt).

STORY CHECKS (P3.14b) — `custom.checks[]`, a named question about the game's state
that works WHEREVER a flag works:

    {"name": "has_key", "kind": "item", "item": 26, "count": 1, "comment": "…"}

Check n (list order; then the compiler's own internal checks) IS event flag
$1800 + n — a "virtual flag": bank $73 FlagAddr (ROM0 ComputeFlagAddress) routes
it to bank $77 entry 11 StoryCheck, which answers it from the game's state. So a
check name can stand in any flag term ({"flag": "has_key", "is": "set"} = the check
holds, "clear" = it does not): a conversation's / cutscene's If, a room state rule,
an NPC's shown_when, a hub / music / shop-set / gate-room / arena rule, a quest.
A check can never be turned ON / OFF (the compiler refuses a Turn ON of one).

Kinds (CHECK_KINDS): item (the bag holds >= count), gold (>= amount), species /
family (a monster of it is owned — anywhere or in the party), monsters (>= count
owned / in the party), level (a party monster / the average / every party monster
at >= level), seen (>= count species in the Library), chance (percent, rolled each
time it is read), arena (>= classes won), bag_room (>= count free bag slots),
story (the milestone or a later one is reached), all / any (AND / OR of flag terms
— checks included: "NOT" is a term with "is": "clear").

STORY COMMANDS (P3.14b) — steps of conversations and cutscenes that change the
game's state: take items, give / take gold, give items (several), refresh the room.
The first three are records of bank $77 StoryCmdPtrs run by op $24 $FF00 + n
(bank $60 CustomDrawTiles -> bank $77 entry 10 ScriptCommand); the compiler dedups
them (Project.story_command). Refresh = op $26 reload_room ($C88F++: the room loads
again where the player stands — state rules re-picked; PyBoy S129).

THE STORY SPINE (P3.14c) — `custom.story.milestones[]`: the ordered chapters of
the game, each a flag ({"flag": "met_king", "name": "Chapter 1 — the King"}).
"Reached milestone M" = M's flag or a later milestone's flag is ON (a check of kind
`story`, an internal `any` check). A conversation's "Says by progress" step
(`by_progress`) speaks by the latest milestone reached (highest first).

QUESTS (P3.14c) — `custom.quests[]` (QUEST_KEYS), lowered into the giver NPC's
conversation (custom.scripts[] `talk.steps`, script id = quest.giver): done → its
words; started → objective holds (and the bag has room for the reward) → hand over
(take) + the reward + done (+ its flags) / else the reminder; not started → offered
only when `requires` holds (else `not_yet`) → YES: started + accept / NO: decline.
The legacy `progression.quests` (S70) stays readable for old projects.
"""

import copy

from . import formats as F

STORY_FLAG_BASE = 0x1800           # check n = virtual event flag $1800 + n
STORY_CHECK_MAX = 256              # $1800-$18FF (bank $73 FlagAddr: D == $18)
STORY_CMD_MAX = 255                # op $24 $FF01-$FFFF ($FF00 = the S127 mate's name)
TERMS_MAX = 8

# kind -> (engine kind byte, label, fields)
CHECK_KINDS = {
    'item':     (0, 'has an item', ('item', 'count')),
    'gold':     (1, 'has gold', ('amount',)),
    'species':  (2, 'owns a monster (kind)', ('species', 'where')),
    'family':   (3, 'owns a monster (family)', ('family', 'where')),
    'monsters': (4, 'owns monsters', ('count', 'where')),
    'level':    (5, 'party level', ('level', 'mode')),
    'seen':     (6, 'monsters seen (Library)', ('count',)),
    'chance':   (7, 'random chance', ('percent',)),
    'arena':    (8, 'arena classes won', ('classes',)),
    'all':      (9, 'all of (AND)', ('terms',)),
    'any':      (10, 'any of (OR)', ('terms',)),
    'bag_room': (11, 'room in the bag', ('count',)),
    'story':    (None, 'story reached', ('milestone',)),   # -> an internal 'any'
}
CHECK_KIND_ORDER = ['item', 'gold', 'species', 'family', 'monsters', 'level', 'seen',
                    'chance', 'arena', 'bag_room', 'story', 'all', 'any']
WHERE = {'anywhere': 0, 'party': 1}
LEVEL_MODES = {'any': 0, 'average': 1, 'all': 2}
GOLD_MAX = 99999                   # ROM0 CompareGold caps the purse here
ITEM_MIN, ITEM_MAX = 1, 43
PROTECTED_SPECIES = range(215, 221)  # Iron Rule 8: not monsters

CMD_KINDS = {'take_item': 0, 'give_gold': 1, 'take_gold': 2, 'give_item': 3}

QUEST_KEYS = ('id', 'name', 'giver', 'requires', 'not_yet', 'offer', 'accept', 'decline',
              'objective', 'progress', 'take', 'reward', 'complete', 'done', 'bag_full',
              'flags', 'comment', 'note')
QUEST_TEXTS = ('not_yet', 'offer', 'accept', 'decline', 'progress', 'complete', 'done',
               'bag_full')


class StoryError(ValueError):
    pass


def _int(v, what, lo=None, hi=None):
    try:
        n = F.val(v) if isinstance(v, str) else int(v)
    except (TypeError, ValueError):
        raise StoryError(f"{what}: {v!r} is not a number")
    if lo is not None and n < lo or hi is not None and n > hi:
        raise StoryError(f"{what}: {n} outside {lo}-{hi}")
    return n


def is_internal(name):
    return isinstance(name, str) and name.startswith('story:')


# ---------------------------------------------------------------------------
# checks -> engine records
# ---------------------------------------------------------------------------

def milestones(custom):
    """[(flag ref, name)] of custom.story.milestones, in story order."""
    out = []
    for i, m in enumerate(((custom or {}).get('story') or {}).get('milestones') or []):
        if isinstance(m, str):
            out.append((m, m))
        elif isinstance(m, dict) and m.get('flag'):
            out.append((m['flag'], m.get('name') or m['flag']))
        else:
            raise StoryError(f"custom.story.milestones[{i}]: {{\"flag\": name, \"name\": …}}")
    return out


def milestone_index(custom, ref):
    for i, (f, _n) in enumerate(milestones(custom)):
        if f == ref:
            return i
    return None


def check_terms_refs(chk):
    """The flag refs a check reads (all / any terms; story: the milestones)."""
    k = chk.get('kind')
    if k in ('all', 'any'):
        return [t.get('flag') for t in chk.get('terms') or []]
    return []


def check_record(prj, chk, ctx):
    """custom.checks entry -> the record bytes of bank $77 StoryCheckPtrs.
    prj.resolve_flag_ref resolves the terms (any / all)."""
    k = chk.get('kind')
    if k not in CHECK_KINDS or k == 'story':
        raise StoryError(f"{ctx}: kind {k!r} — one of {', '.join(CHECK_KIND_ORDER)}")
    code = CHECK_KINDS[k][0]
    if k == 'item':
        return [code, _int(chk.get('item'), ctx + '.item', ITEM_MIN, ITEM_MAX),
                _int(chk.get('count', 1), ctx + '.count', 1, 20)]
    if k == 'gold':
        a = _int(chk.get('amount'), ctx + '.amount', 0, GOLD_MAX)
        return [code, a & 0xFF, (a >> 8) & 0xFF, a >> 16]
    if k in ('species', 'family'):
        if k == 'species':
            v = _int(chk.get('species'), ctx + '.species', 0, 239)
            if v in PROTECTED_SPECIES or 220 <= v < 221:
                raise StoryError(f"{ctx}: species {v} is not a monster (TERRY? / the "
                                 "summons — Iron Rule 8)")
        else:
            v = _int(chk.get('family'), ctx + '.family', 0, 10)
        w = chk.get('where', 'anywhere')
        if w not in WHERE:
            raise StoryError(f"{ctx}.where: anywhere / party")
        return [code, v, WHERE[w]]
    if k == 'monsters':
        w = chk.get('where', 'anywhere')
        if w not in WHERE:
            raise StoryError(f"{ctx}.where: anywhere / party")
        return [code, _int(chk.get('count', 1), ctx + '.count', 1, 40), WHERE[w]]
    if k == 'level':
        m = chk.get('mode', 'any')
        if m not in LEVEL_MODES:
            raise StoryError(f"{ctx}.mode: any / average / all")
        return [code, _int(chk.get('level'), ctx + '.level', 1, 99), LEVEL_MODES[m]]
    if k == 'seen':
        return [code, _int(chk.get('count'), ctx + '.count', 1, 240)]
    if k == 'chance':
        return [code, _int(chk.get('percent'), ctx + '.percent', 1, 100)]
    if k == 'arena':
        return [code, _int(chk.get('classes'), ctx + '.classes', 1, 8)]
    if k == 'bag_room':
        return [code, _int(chk.get('count', 1), ctx + '.count', 1, 20)]
    # all / any
    terms = chk.get('terms') or []
    if not isinstance(terms, list) or not terms:
        raise StoryError(f"{ctx}: '{k}' needs at least one term")
    if len(terms) > 255:
        raise StoryError(f"{ctx}: too many terms")
    b = [code, len(terms)]
    for j, t in enumerate(terms):
        if not isinstance(t, dict) or t.get('is', 'set') not in ('set', 'clear'):
            raise StoryError(f"{ctx}.terms[{j}]: {{\"flag\": name, \"is\": set|clear}}")
        idx = prj.resolve_flag_ref(t.get('flag'), f"{ctx}.terms[{j}]")
        w = idx | (0x8000 if t.get('is', 'set') == 'clear' else 0)
        b += [w & 0xFF, w >> 8]
    return b


def check_list(custom):
    """The authored checks, validated for shape (names, kinds) -> list of dicts."""
    out = []
    seen = set()
    for i, c in enumerate((custom or {}).get('checks') or []):
        ctx = f"custom.checks[{i}]"
        if not isinstance(c, dict) or not c.get('name'):
            raise StoryError(f"{ctx}: needs a \"name\"")
        n = str(c['name'])
        if n in seen:
            raise StoryError(f"{ctx}: the name {n!r} is used twice")
        if is_internal(n) or ':' in n:
            raise StoryError(f"{ctx}: {n!r} — a name may not contain ':'")
        if c.get('kind') not in CHECK_KINDS:
            raise StoryError(f"{ctx} ({n}): kind {c.get('kind')!r} — one of "
                             + ', '.join(CHECK_KIND_ORDER))
        seen.add(n)
        out.append(c)
    return out


def expand_story_checks(custom, checks):
    """A `story` check -> an `any` check over the milestone's flag and every later one's."""
    ms = milestones(custom)
    out = []
    for c in checks:
        if c.get('kind') == 'story':
            i = milestone_index(custom, c.get('milestone'))
            if i is None:
                raise StoryError(f"check {c.get('name')}: {c.get('milestone')!r} is not a "
                                 "milestone of custom.story.milestones")
            c = dict(c, kind='any', terms=[{'flag': f} for f, _n in ms[i:]],
                     _story=c.get('milestone'))
        out.append(c)
    return out


def check_order(checks):
    """Cycle check over all / any terms that name other checks (a check may read
    another; never itself through a chain — the engine would recurse forever)."""
    names = {c['name']: c for c in checks}
    state = {}

    def visit(n, path):
        if state.get(n) == 1:
            raise StoryError("story checks read each other in a circle: "
                             + ' -> '.join(path + [n]))
        if state.get(n) == 2:
            return
        state[n] = 1
        for ref in check_terms_refs(names[n]):
            if ref in names:
                visit(ref, path + [n])
        state[n] = 2

    for n in names:
        visit(n, [])


# ---------------------------------------------------------------------------
# describing (editor + flag index)
# ---------------------------------------------------------------------------

def describe_check(chk, item_name=None, species_name=None, family_name=None,
                   milestone_name=None):
    k = chk.get('kind')
    item_name = item_name or (lambda i: f"item {i}")
    species_name = species_name or (lambda s: f"species {s}")
    family_name = family_name or (lambda f: f"family {f}")
    where = ' in the party' if chk.get('where') == 'party' else ''
    try:
        if k == 'item':
            n = int(chk.get('count', 1))
            return (f"the bag holds {n} × {item_name(F.val(chk.get('item')))}" if n > 1
                    else f"the bag holds a {item_name(F.val(chk.get('item')))}")
        if k == 'gold':
            return f"the player has {int(chk.get('amount', 0)):,} gold or more"
        if k == 'species':
            return f"a {species_name(F.val(chk.get('species')))} is owned{where}"
        if k == 'family':
            return f"a monster of the {family_name(F.val(chk.get('family')))} family is owned{where}"
        if k == 'monsters':
            return (f"{int(chk.get('count', 1))} or more monsters are in the party"
                    if chk.get('where') == 'party'
                    else f"{int(chk.get('count', 1))} or more monsters are owned")
        if k == 'level':
            m = chk.get('mode', 'any')
            lv = chk.get('level')
            return {'any': f"a party monster is level {lv} or higher",
                    'average': f"the party's average level is {lv} or higher",
                    'all': f"every party monster is level {lv} or higher"}.get(m, '?')
        if k == 'seen':
            return f"{chk.get('count')} or more monsters seen in the Library"
        if k == 'chance':
            return f"a {chk.get('percent')} % chance (rolled each time it is read)"
        if k == 'arena':
            return f"{chk.get('classes')} or more arena classes won"
        if k == 'bag_room':
            n = int(chk.get('count', 1))
            return f"the bag has room for {n} more item{'s' if n != 1 else ''}"
        if k == 'story':
            m = chk.get('milestone')
            return f"the story has reached “{(milestone_name or (lambda x: x))(m)}”"
        if k in ('all', 'any'):
            parts = [f"{t.get('flag')}{' is OFF' if t.get('is') == 'clear' else ''}"
                     for t in chk.get('terms') or []]
            return (' AND ' if k == 'all' else ' OR ').join(parts) or '(nothing)'
    except (TypeError, ValueError):
        pass
    return '?'


# ---------------------------------------------------------------------------
# commands
# ---------------------------------------------------------------------------

def cmd_record(kind, params, ctx):
    if kind not in CMD_KINDS:
        raise StoryError(f"{ctx}: unknown command {kind!r}")
    code = CMD_KINDS[kind]
    if kind in ('take_item', 'give_item'):
        return (code, _int(params.get('item'), ctx + '.item', ITEM_MIN, ITEM_MAX),
                _int(params.get('count', 1), ctx + '.count', 1, 20))
    a = _int(params.get('amount'), ctx + '.amount', 1, GOLD_MAX)
    return (code, a & 0xFF, (a >> 8) & 0xFF, a >> 16)


# ---------------------------------------------------------------------------
# quests -> conversations
# ---------------------------------------------------------------------------

def _text(v):
    """A quest text: a dialogue id (str) or {"boxes": …} (inline)."""
    return v


def quest_flags(q):
    fl = q.get('flags') or {}
    qid = q.get('id')
    return (fl.get('started') or f"{qid}_started", fl.get('done') or f"{qid}_done")


def quest_flag_entries(custom):
    """custom.flags entries the quests need that are not declared (auto)."""
    have = {f.get('name') for f in (custom or {}).get('flags', [])}
    out = []
    for q in (custom or {}).get('quests') or []:
        if not isinstance(q, dict) or not q.get('id'):
            continue
        for name, role in zip(quest_flags(q), ('started', 'done')):
            if name not in have:
                out.append({'name': name, 'comment': f"quest {q['id']}: {role}"})
                have.add(name)
    return out


def quest_steps(q, ctx, text_id=None):
    """A quest -> the giver's conversation steps (talk.steps). text_id(key, v)
    turns an inline text ({"boxes": …}) into a dialogue id (lower_quests adds the
    dialogue entry); None keeps the value as it is (the editor's preview)."""
    for k in q:
        if k not in QUEST_KEYS and not str(k).startswith('_'):
            raise StoryError(f"{ctx}: unknown key {k!r} ({', '.join(QUEST_KEYS)})")
    started, done = quest_flags(q)
    if not q.get('offer'):
        raise StoryError(f"{ctx}: a quest needs its offer (the YES / NO question)")
    if not q.get('objective'):
        raise StoryError(f"{ctx}: a quest needs an objective (what must hold to finish it)")
    if not q.get('complete'):
        raise StoryError(f"{ctx}: a quest needs the words when it is finished (complete)")

    def say(key, default=None):
        v = q.get(key) or default
        if not v:
            return []
        if text_id is not None:
            v = text_id(key, v)
        return [{'say': v}]

    reward = q.get('reward') or {}
    unknown = set(reward) - {'items', 'gold', 'monster', 'set', 'clear', 'refresh'}
    if unknown:
        raise StoryError(f"{ctx}.reward: unknown key(s) {sorted(unknown)} "
                         "(items, gold, monster, set, clear, refresh)")
    take = q.get('take') or []
    finish = []
    for i, t in enumerate(take):
        finish.append({'take_item': {'item': t.get('item'), 'count': t.get('count', 1)}})
    finish += say('complete')
    for it in reward.get('items') or []:
        finish.append({'give_item': {'item': it.get('item'), 'count': it.get('count', 1),
                                     'silent': True}})
    if reward.get('gold'):
        finish.append({'gold': {'give': reward['gold']}})
    if reward.get('monster') is not None:
        finish.append({'give_monster': {'enemy': reward['monster']}})
    finish.append({'set': [done] + list(reward.get('set') or [])})
    if reward.get('clear'):
        finish.append({'clear': list(reward['clear'])})
    if reward.get('refresh'):
        # the room loads again at once: its state rules see the new flags (a door
        # the quest unlocks opens now — story_doc.lock_exit)
        finish.append({'refresh': True})
    # the bag needs room for the reward items (they are given silently after
    # the words); the items handed over free their slots first — the objective
    # test adds a bag-room term for the difference
    n_items = sum(int(it.get('count', 1)) for it in reward.get('items') or [])
    n_taken = sum(int(t.get('count', 1)) for t in take)
    objective = list(q.get('objective') or [])
    room_term = None
    if n_items > n_taken:
        room_term = {'flag': f"story:bag_room:{n_items - n_taken}"}
    progress = say('progress', None) or say('offer')
    if room_term is not None:
        in_progress = [{'if': objective, 'then': [
            {'if': [room_term], 'then': finish,
             'else': say('bag_full', {'boxes': [["Your bag is", "full!"],
                                                  ["Make room first!"]]})}],
            'else': progress}]
    else:
        in_progress = [{'if': objective, 'then': finish, 'else': progress}]
    offer = [{'ask': text_id('offer', q['offer']) if text_id else q['offer'],
              'yes': [{'set': [started]}] + say('accept'),
              'no': say('decline')}]
    requires = list(q.get('requires') or [])
    if requires:
        offer = [{'if': requires, 'then': offer, 'else': say('not_yet')}]
    return [{'if': [{'flag': done}], 'then': say('done', q.get('complete')),
             'else': [{'if': [{'flag': started}], 'then': in_progress, 'else': offer}]}]


def lower_quests(custom):
    """custom.quests -> the giver scripts' talk.steps (in place; idempotent: a
    script made by a quest carries `_quest`). Returns [(quest id, script id)]."""
    out = []
    scripts = custom.setdefault('scripts', [])
    by_id = {s.get('id'): s for s in scripts}
    for i, q in enumerate(custom.get('quests') or []):
        ctx = f"custom.quests[{i}]"
        if not isinstance(q, dict) or not q.get('id'):
            raise StoryError(f"{ctx}: needs an \"id\"")
        giver = q.get('giver')
        if not giver:
            raise StoryError(f"{ctx} ({q['id']}): needs a giver (the NPC's script id)")
        dlg = custom.setdefault('dialogue', [])
        have = {d.get('id') for d in dlg}

        def text_id(key, v, q=q):
            if isinstance(v, str):
                return v
            if not (isinstance(v, dict) and v.get('boxes')):
                raise StoryError(f"{ctx} ({q['id']}).{key}: a dialogue id or {{\"boxes\": …}}")
            did = f"quest_{q['id']}_{key}"
            if did not in have:
                ent = {'id': did, 'boxes': [list(b) for b in v['boxes']],
                       'comment': f"quest {q['id']}: {key}"}
                for k in ('speaker', 'voice'):
                    if v.get(k) is not None:
                        ent[k] = v[k]
                if key == 'offer':
                    ent['choice'] = True
                dlg.append(ent)
                have.add(did)
            return did
        steps = quest_steps(q, f"{ctx} ({q['id']})", text_id)
        s = by_id.get(giver)
        if s is None:
            raise StoryError(f"{ctx} ({q['id']}): giver script {giver!r} does not exist")
        if s.get('_quest') not in (None, q['id']):
            raise StoryError(f"{ctx}: the script {giver!r} already gives quest "
                             f"{s['_quest']!r}")
        s.pop('ops', None)
        s['talk'] = {'steps': steps}
        s['_quest'] = q['id']
        out.append((q['id'], giver))
    return out


def describe_quest(q):
    started, done = quest_flags(q)
    return (f"{q.get('name') or q.get('id')}: given by {q.get('giver')}; started = "
            f"{started}, done = {done}")


def copy_quest(q):
    return copy.deepcopy(q)


# ---------------------------------------------------------------------------
# emitter (bank $77, shops77)
# ---------------------------------------------------------------------------

def emit_lines(prj):
    """StoryCheckPtrs + records, StoryCmdPtrs + records (bank $77 entries 10 / 11)."""
    recs = prj.story_check_records() if hasattr(prj, 'story_check_records') else []
    cmds = prj.story_commands() if hasattr(prj, 'story_commands') else []
    out = ["; " + "=" * 77,
           "; STORY CHECKS + STORY COMMANDS (S129, ROADMAP P3.14b; generated by editor2",
           "; story.py from custom.checks, the quests / milestones and the scripts' story",
           "; steps — PROJECT_COMPILER §2.42). Check n = event flag $1800 + n.",
           "; " + "=" * 77,
           f"STORY_CHECK_COUNT EQU {len(recs)}",
           "StoryCheckPtrs:"]
    for n, (name, rec) in enumerate(recs):
        out.append(f"    dw StoryCheck_{n}   ; flag ${STORY_FLAG_BASE + n:04X} = {name}")
    for n, (name, rec) in enumerate(recs):
        out.append(f"StoryCheck_{n}:  ; {name}")
        out.append("    db " + ", ".join(f"${b:02x}" for b in rec))
    out.append("")
    out.append(f"STORY_CMD_COUNT EQU {len(cmds)}")
    out.append("StoryCmdPtrs:")
    names = {v: k for k, v in CMD_KINDS.items()}
    for n, rec in enumerate(cmds):
        out.append(f"    dw StoryCmd_{n + 1}   ; op $24 ${0xFF01 + n:04X}: {names[rec[0]]}")
    for n, rec in enumerate(cmds):
        out.append(f"StoryCmd_{n + 1}:")
        out.append("    db " + ", ".join(f"${b:02x}" for b in rec))
    out.append("")
    return out
