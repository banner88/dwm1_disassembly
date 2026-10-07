"""conversation.py — conversation trees + project enemies (S101, ROADMAP P3.7b part 2).

Headless Document mixins (no Qt).

ConversationMixin — the `talk.steps` script form (PROJECT_COMPILER §2.18,
lowered by project.Project._lower_steps): a list of STEPS, each one of
    say / ask (YES/NO, both branches rejoin) / if (flag terms, then/else) /
    set / clear / battle (1-3 enemies; the steps after it run only on a WIN) /
    helper (the vanilla boss exit: Watabou flies in, spins, speaks and fades
    the player to a destination) / move / end.
The GUI edits a SPEC that is the same tree with the text INLINE:
    {'say': {'boxes': [[line, line], ...]}}
    {'ask': {'boxes': [...]}, 'yes': [STEP...], 'no': [STEP...]}
    {'helper': {..., 'say': {'boxes': [...]} | None}}
and writes one `dialogue` entry (boxes form) per text; `ask` texts get
`choice: true` (the YES/NO box). Script-level keys: on_arrival (the room's
entry script — field context), screen (only on that screen).

EnemiesMixin — `progression.enemies[]`, the PROJECT enemy rows (bank $6B,
EIDs 519+; MONSTER_DATA "Project enemy rows"): the vanilla 25-byte row
fields + `join_as` (the weaker JOIN VERSION — a fight->join redirect row).
Joinability: 0 = always joins, 1-6 = sometimes (tier-scaled chance), 7 =
never (bank $54 JoinDecision, S101 annotation).
"""

import copy
import json
import os

STEP_KINDS = ('say', 'ask', 'if', 'set', 'clear', 'battle', 'helper', 'move', 'vanish', 'heal',
              'end',
              # S129 (ROADMAP P3.14b / c)
              'give_item', 'give_monster', 'take_item', 'gold', 'refresh', 'by_progress')
STEP_NAMES = {
    'say': 'Say', 'ask': 'Ask YES / NO', 'if': 'If flags…', 'set': 'Turn flags ON',
    'clear': 'Turn flags OFF', 'battle': 'Battle', 'helper': 'Helper takes the player away',
    'move': 'Move the player',
    'vanish': 'Vanish (this NPC leaves)',      # S123: every NPC running this conversation
    'heal': 'Heal the party',                  # S125: op $27 (HP / MP full, ailments cured)
    'end': 'Stop here',
    'give_item': 'Give an item', 'give_monster': 'Give a monster',      # S129
    'take_item': 'Take an item', 'gold': 'Give / take gold',
    'refresh': 'Refresh the room', 'by_progress': 'Says by progress'}
HELPER_SPRITE = 0x39            # Warubou, the darker Watabou (user S101 r2); vanilla uses $21 Watabou
WATABOU_SPRITE = 0x21
CASTLE_THRONE = {'dest': 'vanilla:$00', 'screen': 1, 'x': 4, 'y': 5}   # vanilla boss exits

JOIN_ALWAYS, JOIN_NEVER = 0, 7

# S101 r3 — what happens when the helper lands the player in the Castle throne
# room (Castle_Script00 on screen 1 dispatches on the castle-arrival code
# $D92B; PyBoy-measured on the user's save, GATE_GENERATION §7.7):
#   none  — nothing ($D92B left as it is: 1-5 = no event)
#   heal  — $D92B = 6: the priest's GreatTree blessing + heal (the vanilla
#           return from a gate; the game also uses 8 after a lost battle)
#   king  — $D92B = 7 + $D9E3 = a gate's speech code: the King's speech after
#           that gate's boss ($D9E3 is read ONLY by this castle chain; no saved
#           flag changes — measured for every code below)
CASTLE_EVENTS = ('none', 'heal', 'king')
KING_SPEECHES = [   # (code, gate — boss) : the vanilla boss rooms that write each code
    (0x30, 'Gate of Beginning — Healer'), (0x31, 'Gate of Villager — Dragon'),
    (0x32, 'Gate of Talisman — Golem'), (0x33, 'Gate of Memories — MadCat'),
    (0x34, 'Gate of Bewilder — FaceTree'), (0x35, 'Bazaar Gate — MadKnight'),
    (0x36, 'Gate of Peace — FangSlime'), (0x37, 'Gate of Bravery — BigEye'),
    (0x38, 'Well Gate — Gigantes'), (0x39, 'Gate of Strength — StoneMan'),
    (0x3A, 'Gate of Wisdom — SkyDragon'), (0x3B, 'Gate of Joy — FunkyBird'),
    (0x3C, 'Gate of Anger — BattleRex'), (0x3D, 'Arena Left — Digster'),
    (0x3E, 'Gate of Happiness — Jamirus'), (0x3F, 'Gate of Temptation — Servant'),
    (0x10, 'Copycat House — Copycat'), (0x41, 'Medal Gate — Lipsy / KingSlime / Toadstool'),
    (0x42, 'Labyrinth — DarkHorn'), (0x43, 'Gate of Judgment — Akubar'),
    (0x44, 'Library Gate — Orochi'), (0x45, 'Gate of Reflection — Durran'),
    (0x46, 'Gate of Ambition — DracoLord (post-game)'),
    (0x47, 'Gate of Demolition — Hargon (post-game)'),
    (0xC7, 'Gate of Demolition — Sidoh (post-game)'),
    (0x48, 'Gate of Mastermind — Baramos (post-game)'),
    (0x49, 'Gate of Control — Zoma (post-game)'),
    (0x4A, 'Gate of Extinction — Pizzaro (post-game)'),
    (0x4B, 'Gate of Sleep — Esterk (post-game)'),
    (0x4C, 'Bazaar Edge — Mirudraas (post-game)'),
    (0x4D, 'Arena Right — Mudou (post-game)'),
    (0x4E, "Grandpa's Gate — DeathMore (post-game)"),
]
CASTLE_DEST = {'dest': 'vanilla:$00', 'screen': 1, 'x': 4, 'y': 5}
# $D9E3 has ONE other reader (ROM scan S101 r3): a castle NPC's talk at
# $0C:$5066 — $30: "These stairs go up to the monster farm", $3C: the
# GreatTree-shaking line after `write $C88A/B = 3` + op $3E (a story event —
# not played), anything else: the herb gift. The value stays until the next
# vanilla gate return (the priest path writes $FF).
SPEECH_NOTES = {
    0x30: 'afterwards a castle NPC says "These stairs go up to the monster farm" instead '
          'of giving the herb (until your next gate return)',
    0x3C: 'afterwards a castle NPC runs the GreatTree-shaking story event instead of '
          'giving the herb (until your next gate return) — not tested, avoid',
}


def join_label(j):
    j = int(j)
    if j == JOIN_ALWAYS:
        return 'always joins'
    if j == JOIN_NEVER:
        return 'never joins'
    return f'sometimes joins (tier {j})'


def _repo_root():
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(here, '..', '..'))


_CACHE = {}


def species_names(data=None):
    """{species id: name}: the 221 vanilla species (extracted/monsters_full.json)
    + the PROJECT's new species (custom.species of `data`, the project.json
    dict — S105 P3.9b; before S105 a hardcoded 224 Gorbunok from
    extracted/new_species.json, present in every project)."""
    if 'species' not in _CACHE:
        out = {}
        try:
            for m in json.load(open(os.path.join(_repo_root(), 'extracted',
                                                  'monsters_full.json'))):
                out[int(m['id'])] = m['name']
        except (OSError, ValueError):
            pass
        _CACHE['species'] = out
    out = dict(_CACHE['species'])
    for s in ((data or {}).get('custom') or {}).get('species') or []:
        if isinstance(s, dict) and isinstance(s.get('id'), int) and s.get('name'):
            out[s['id']] = s['name']
    return out


def _project_data(obj):
    """The project.json dict behind a mixin user (a Document, or a scratch
    copy holding its document in _doc)."""
    doc = getattr(obj, '_doc', None)
    return getattr(doc, 'data', None) or getattr(obj, 'data', None)


def skill_names():
    if 'skills' not in _CACHE:
        out = {}
        try:
            d = json.load(open(os.path.join(_repo_root(), 'extracted', 'skill_records.json')))
            rows = d.get('skills') or d.get('records') or []
            for r in rows:
                if 'id' in r and r.get('name'):
                    out[int(r['id'])] = r['name']
        except (OSError, ValueError, AttributeError):
            pass
        _CACHE['skills'] = out
    return _CACHE['skills']


def vanilla_enemies():
    """[{eid, species, name, level, hp, mp, atk, def, agl, int, exp,
    joinability, skills, ai_weights, boss}] — extracted/enemy_stats.json
    (487 vanilla rows) + the boss census (arena_brackets gate_boss_triggers)."""
    if 'enemies' not in _CACHE:
        rows = []
        try:
            d = json.load(open(os.path.join(_repo_root(), 'extracted', 'enemy_stats.json')))
            d = d['enemies'] if isinstance(d, dict) and 'enemies' in d else d
            for r in d:
                rows.append({'eid': int(r['enemy_stats_id']), 'species': int(r['species_id']),
                             'name': r.get('species_name', ''), 'level': r['level'],
                             'hp': r['hp'], 'mp': r['mp'], 'atk': r['atk'], 'def': r['def'],
                             'agl': r['agl'], 'int': r['int'], 'exp': r['exp_reward'],
                             'joinability': r.get('joinability', 7),
                             'skills': [s for s in r.get('skills', []) if s != 255],
                             'ai_weights': list(r.get('ai_weights', [0, 0, 0, 0])),
                             'boss': ''})
        except (OSError, ValueError, KeyError):
            pass
        try:
            ab = json.load(open(os.path.join(_repo_root(), 'extracted', 'arena_brackets.json')))
            by = {r['eid']: r for r in rows}
            for t in ab.get('gate_boss_triggers', []):
                r = by.get(int(t.get('eid', -1)))
                if r is not None and not r['boss']:
                    r['boss'] = t.get('script', '').split('/')[0]
        except (OSError, ValueError):
            pass
        _CACHE['enemies'] = rows
    return _CACHE['enemies']


def describe_enemy_row(r):
    tag = f" — {r['boss']}" if r.get('boss') else ''
    return f"EID {r['eid']} {r['name']} L{r['level']} HP{r['hp']}{tag}"


class ConversationMixin:
    # ------------------------------------------------------------ read
    def conversation(self, sid):
        """The talk dict of a steps-form script, or None."""
        try:
            sc = self.script(sid)
        except KeyError:
            return None
        t = sc.get('talk') or {}
        return t if 'steps' in t else None

    def _dlg_spec(self, did):
        if not did:
            return None
        return dict({'boxes': self._dlg_boxes(did) or []}, **self._dlg_meta(did))

    def conversation_spec(self, sid):
        """GUI spec of a steps-form script (texts inline), or None."""
        t = self.conversation(sid)
        if t is None:
            return None

        def conv(steps):
            out = []
            for st in steps or []:
                st = copy.deepcopy(st)
                if 'say' in st:
                    st['say'] = self._dlg_spec(st['say'])
                elif 'ask' in st:
                    st['ask'] = self._dlg_spec(st['ask'])
                    st['yes'] = conv(st.get('yes'))
                    st['no'] = conv(st.get('no'))
                elif 'if' in st:
                    st['then'] = conv(st.get('then'))
                    st['else'] = conv(st.get('else'))
                elif 'helper' in st:
                    h = st['helper'] or {}
                    h['say'] = self._dlg_spec(h.get('say'))
                    st['helper'] = h
                elif 'give_item' in st or 'give_monster' in st:      # S129
                    k = 'give_item' if 'give_item' in st else 'give_monster'
                    g = dict(st[k] or {})
                    for part in ('got', 'full'):
                        if isinstance(g.get(part), str):
                            g[part] = self._dlg_spec(g[part])
                    st[k] = g
                elif 'by_progress' in st:                            # S129
                    st['by_progress'] = [dict(e, steps=conv(e.get('steps')))
                                         for e in st['by_progress'] or []]
                    st['else'] = conv(st.get('else'))
                out.append(st)
            return out
        spec = {'steps': conv(t['steps'])}
        for k in ('on_arrival', 'screen'):
            if k in t:
                spec[k] = t[k]
        return spec

    # ------------------------------------------------------------ write
    def _conversation_payload(self, sid, spec):
        n = [0]

        def dlg(part, boxes, choice=False, meta=None):
            n[0] += 1
            return self._new_dialogue(sid, f'{part}{n[0]}', boxes, choice=choice, meta=meta)

        def conv(steps):
            out = []
            for st in steps or []:
                st = copy.deepcopy(st)
                if 'say' in st:
                    b = (st['say'] or {}).get('boxes') or []
                    if not b:
                        raise ValueError('a Say step needs some text')
                    st['say'] = dlg('say', b, meta=st['say'])
                elif 'ask' in st:
                    b = (st['ask'] or {}).get('boxes') or []
                    if not b:
                        raise ValueError('an Ask step needs a question')
                    st['ask'] = dlg('ask', b, choice=True, meta=st['ask'])
                    st['yes'] = conv(st.get('yes'))
                    st['no'] = conv(st.get('no'))
                elif 'if' in st:
                    st['then'] = conv(st.get('then'))
                    st['else'] = conv(st.get('else'))
                elif 'helper' in st:
                    h = dict(st['helper'] or {})
                    b = (h.get('say') or {}).get('boxes') if isinstance(h.get('say'), dict) \
                        else None
                    if b:
                        h['say'] = dlg('helper', b, meta=h['say'])
                    else:
                        h.pop('say', None)
                    st['helper'] = h
                elif 'give_item' in st or 'give_monster' in st:      # S129
                    k = 'give_item' if 'give_item' in st else 'give_monster'
                    g = dict(st[k] or {})
                    for part in ('got', 'full'):
                        b = (g.get(part) or {}).get('boxes') if isinstance(g.get(part), dict) \
                            else None
                        if b:
                            g[part] = dlg(part, b, meta=g[part])
                        elif not isinstance(g.get(part), str):
                            g.pop(part, None)
                    st[k] = g
                elif 'by_progress' in st:                            # S129
                    st['by_progress'] = [dict(e, steps=conv(e.get('steps')))
                                         for e in st['by_progress'] or []]
                    st['else'] = conv(st.get('else'))
                out.append(st)
            return out
        t = {'steps': conv(spec.get('steps'))}
        if spec.get('on_arrival'):
            t['on_arrival'] = True
        if spec.get('screen') is not None:
            t['screen'] = int(spec['screen'])
        return t

    def new_conversation(self, room, spec, name='talk', entry=False):
        """A new steps-form script for `room`. entry=True: it becomes the
        room's ENTRY script (index 0, runs whenever a screen of the room
        loads — `spec['screen']` limits it to one screen) and the previous
        entry script is kept unreferenced only if nothing else uses it."""
        scripts = self.custom.setdefault('scripts', [])
        sids = {s.get('id') for s in scripts}
        sid = self._unique_id(f"{room['id']}_{name}", sids)
        if entry:
            spec = dict(spec)
            spec['on_arrival'] = True
        scripts.append({'id': sid, 'talk': self._conversation_payload(sid, spec)})
        table = room.setdefault('scripts', {})
        if entry:
            table['0'] = sid
        else:
            if '0' not in table:
                eid = self._unique_id(f"{room['id']}_entry", sids | {sid})
                scripts.append({'id': eid, 'ops': [['end']]})
                table['0'] = eid
            idx = 1
            while str(idx) in table:
                idx += 1
            table[str(idx)] = sid
        self.touch()
        return sid

    def set_conversation(self, sid, spec):
        sc = self.script(sid)
        self._drop_script_dialogues(sc)
        sc.pop('ops', None)
        sc.pop('talk', None)
        sc['talk'] = self._conversation_payload(sid, spec)
        self.touch()

    def conversation_dialogue_ids(self, t):
        out = []

        def walk(steps):
            for st in steps or []:
                for k in ('say', 'ask'):
                    if isinstance(st.get(k), str):
                        out.append(st[k])
                h = st.get('helper') or {}
                if isinstance(h.get('say'), str):
                    out.append(h['say'])
                for gk in ('give_item', 'give_monster'):          # S129
                    g = st.get(gk) or {}
                    for part in ('got', 'full'):
                        if isinstance(g.get(part), str):
                            out.append(g[part])
                for e in st.get('by_progress') or []:             # S129
                    walk(e.get('steps'))
                for k in ('yes', 'no', 'then', 'else'):
                    walk(st.get(k))
        walk((t or {}).get('steps'))
        return out

    @staticmethod
    def describe_step(st, enemy_name=None):
        k = next((k for k in STEP_KINDS if k in st), None)
        if k in ('say', 'ask'):
            v = st[k]
            boxes = v.get('boxes') if isinstance(v, dict) else None
            txt = ' '.join(' '.join(ln for ln in b if ln) for b in boxes) if boxes else str(v)
            return f"{STEP_NAMES[k]}: \"{txt[:48]}{'…' if len(txt) > 48 else ''}\""
        if k == 'if':
            return 'If ' + ' AND '.join(
                f"{t.get('flag')} {'is OFF' if t.get('is') == 'clear' else 'is ON'}"
                for t in st['if'] or [])
        if k in ('set', 'clear'):
            fl = st[k] if isinstance(st[k], list) else [st[k]]
            return f"{STEP_NAMES[k]}: " + ', '.join(map(str, fl))
        if k == 'battle':
            ens = (st['battle'] or {}).get('enemies') or []
            names = [enemy_name(e) if enemy_name else str(e) for e in ens]
            return 'Battle: ' + ' + '.join(names) + '  (next steps = after a WIN)'
        if k == 'helper':
            h = st['helper'] or {}
            ev = h.get('castle') or 'none'
            where = ('the Castle' if str(h.get('dest')) == 'vanilla:$00' else
                     'home (the hub)' if h.get('dest') == 'hub' else
                     f"{h.get('dest')} screen {h.get('screen', 0)} ({h.get('x')},{h.get('y')})")
            extra = {'heal': ' — priest heals', 'king': ' — King speech'}.get(ev, '')
            say = h.get('say')
            said = ''
            if isinstance(say, dict) and say.get('boxes'):
                txt = ' '.join(' '.join(ln for ln in b if ln) for b in say['boxes'])
                said = f" (says \"{txt[:24]}{'…' if len(txt) > 24 else ''}\")"
            elif isinstance(say, str):
                said = ' (says something)'
            return f"Helper takes the player to {where}{extra}{said}"
        if k == 'move':
            m = st['move'] or {}
            if m.get('dest') == 'hub':
                return 'Send the player home (the hub)'
            return f"Move the player to {m.get('dest')} screen {m.get('screen', 0)} " \
                   f"({m.get('x')},{m.get('y')})"
        if k == 'vanish':
            how = (st['vanish'] or {}).get('how', 'flicker')
            return ('Vanish: this NPC flickers out' if how == 'flicker'
                    else 'Vanish: this NPC is gone at once')
        if k == 'heal':
            return 'Heal the party (HP / MP full, ailments cured)'
        if k == 'end':
            return 'Stop here'
        if k in ('give_item', 'take_item'):
            g = st[k] or {}
            n = int(g.get('count', 1) or 1)
            return (f"{'Give' if k == 'give_item' else 'Take'} item {g.get('item')}"
                    + (f' × {n}' if n > 1 else '')
                    + ('' if k == 'give_item' else ' from the bag'))
        if k == 'give_monster':
            g = st[k] or {}
            e = g.get('enemy')
            return f"Give a monster: {enemy_name(e) if enemy_name else e}"
        if k == 'gold':
            g = st[k] or {}
            return (f"Give {g.get('give')} gold" if 'give' in g else f"Take {g.get('take')} gold")
        if k == 'refresh':
            return 'Refresh the room (its room states pick again — a door unlocked now opens)'
        if k == 'by_progress':
            lad = st[k] or []
            return 'Says by progress: ' + ', '.join(str(e.get('milestone')) for e in lad)
        return '?'

    def describe_conversation(self, spec):
        steps = (spec or {}).get('steps') or []
        return ' ▸ '.join(self.describe_step(s, self.enemy_name) for s in steps[:4]) + \
            (' ▸ …' if len(steps) > 4 else '')


class EnemiesMixin:
    ENEMY_FIELDS = ('species', 'level', 'exp', 'joinability', 'hp', 'mp', 'atk', 'def',
                    'agl', 'int', 'ai_weights', 'skills', 'join_as', 'name', 'comment')

    def project_enemies(self):
        return (self.data.get('progression') or {}).get('enemies') or []

    def _enemies_list(self):
        return self.data.setdefault('progression', {}).setdefault('enemies', [])

    def set_project_enemies(self, enemies):
        """Replace the whole list (the Enemies dialog edits a scratch copy)."""
        prog = self.data.setdefault('progression', {})
        if enemies:
            prog['enemies'] = copy.deepcopy(list(enemies))
        else:
            prog.pop('enemies', None)
            if not prog:
                self.data.pop('progression', None)
        self.touch()

    def project_enemy(self, eid_or_id):
        for i, e in enumerate(self.project_enemies()):
            if e.get('id') == eid_or_id or self.project_eid(e) == eid_or_id:
                return e
        return None

    def project_eid(self, e):
        """EID of a project enemy (dense from 519 in list order unless explicit)."""
        from editor2.core.project import PROJECT_EID_BASE
        nxt = PROJECT_EID_BASE
        for x in self.project_enemies():
            eid = x.get('eid', 'auto')
            eid = nxt if str(eid) == 'auto' else int(str(eid), 0)
            nxt = max(nxt, eid + 1)
            if x is e:
                return eid
        return None

    def enemy_name(self, ref):
        """Readable name of an enemy reference (project id or EID)."""
        e = self.project_enemy(ref)
        if e is not None:
            sp = species_names(_project_data(self)).get(int(e.get('species', 0)), f"species {e.get('species')}")
            return f"{e.get('name') or e['id']} ({sp} L{e.get('level')})"
        try:
            eid = int(str(ref), 0)
        except ValueError:
            return str(ref)
        for r in vanilla_enemies():
            if r['eid'] == eid:
                return f"{r['name']} L{r['level']} (EID {eid})"
        return f'EID {eid}'

    def add_enemy(self, copy_eid=None, name=None, **fields):
        """A new project enemy row (a copy of a vanilla row when copy_eid is
        given). Returns its id."""
        base = {'species': 0, 'level': 1, 'exp': 0, 'joinability': JOIN_NEVER, 'hp': 10,
                'mp': 0, 'atk': 5, 'def': 5, 'agl': 5, 'int': 5, 'ai_weights': [0, 0, 0, 0],
                'skills': []}
        if copy_eid is not None:
            src = self.project_enemy(copy_eid)
            if src is not None:
                base.update({k: copy.deepcopy(v) for k, v in src.items()
                             if k in self.ENEMY_FIELDS and k not in ('join_as', 'name')})
            else:
                for r in vanilla_enemies():
                    if r['eid'] == int(copy_eid):
                        base.update({k: copy.deepcopy(r[k]) for k in
                                     ('species', 'level', 'exp', 'joinability', 'hp', 'mp',
                                      'atk', 'def', 'agl', 'int', 'ai_weights', 'skills')})
                        break
        base.update(fields)
        taken = {e.get('id') for e in self.project_enemies()}
        sp = species_names(_project_data(self)).get(int(base['species']), 'enemy')
        eid_name = self._unique_id(self._slug(name or sp.lower()) or 'enemy', taken)
        row = {'id': eid_name, 'eid': 'auto'}
        row.update(base)
        if name:
            row['name'] = name
        self._enemies_list().append(row)
        self.touch()
        return eid_name

    def update_enemy(self, eid_name, **fields):
        e = self.project_enemy(eid_name)
        if e is None:
            raise KeyError(eid_name)
        unknown = set(fields) - set(self.ENEMY_FIELDS)
        if unknown:
            raise ValueError(f'unknown enemy fields {sorted(unknown)}')
        for k, v in fields.items():
            if v is None:
                e.pop(k, None)
            else:
                e[k] = v
        self.touch()

    def remove_enemy(self, eid_name):
        """Remove a project enemy. Rows are addressed by position (EID =
        519 + index), so every later enemy's EID moves down — references by
        ID (battle steps, join_as, quests) follow automatically; numeric EID
        references to project rows are refused."""
        lst = self._enemies_list()
        e = self.project_enemy(eid_name)
        if e is None:
            raise KeyError(eid_name)
        users = [x['id'] for x in lst if x.get('join_as') == e['id'] and x is not e]
        if users:
            raise ValueError(f"{e['id']} is the join version of {', '.join(users)}")
        lst.remove(e)
        self.touch()

    def make_join_version(self, eid_name):
        """A weaker copy of a boss row that JOINS in its place (vanilla does
        this for every story boss: Dragon fights with 90 HP / 60 MP, joins as
        a 60 HP / 20 MP row). The copy gets exp 0, joinability 'always'
        (the join roll is the FIGHT row's), stats halved (author edits)."""
        src = self.project_enemy(eid_name)
        if src is None:
            raise KeyError(eid_name)
        f = {k: copy.deepcopy(src[k]) for k in src if k in self.ENEMY_FIELDS
             and k not in ('join_as', 'name', 'comment')}
        for k in ('hp', 'mp', 'atk', 'def', 'agl', 'int'):
            f[k] = max(1, int(f.get(k, 1)) // 2)
        f['exp'] = 0
        f['joinability'] = JOIN_ALWAYS
        jid = self.add_enemy(name=f"{src.get('name') or src['id']} (joins)", **f)
        src['join_as'] = jid
        self.touch()
        return jid
