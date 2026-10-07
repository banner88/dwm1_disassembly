"""story_doc.py — the Document side of the story tools (S129, ROADMAP P3.14b-d).

Headless (no Qt). StoryMixin (mixed into Document):

  * story checks (custom.checks): add / update (rename everywhere) / delete (refused
    while used) — story.py has the kinds and the engine;
  * the story spine (custom.story.milestones);
  * quests (custom.quests): add / update / delete; the giver = an NPC's script;
    the quest's started / done flags are ordinary project flags with fixed numbers;
  * music by flag: a room's rules (rooms[].music_rules) and a gate's
    (custom.music.gates[N].rules);
  * shop item sets (custom.shop_sets);
  * lock_exit: a door / exit that stays shut until conditions hold — a second
    room state of the screen (user S129: "make a new room state and switch to
    that"): in it the exit cell(s) are walls with an examine spot that says the
    locked words; the state rules show the open state while the conditions hold.
    A conversation's "Refresh the room" step opens it at once (op $26).
"""

import copy

from . import story as ST


def _terms_ok(terms):
    out = []
    for t in terms or []:
        if not isinstance(t, dict) or not t.get('flag'):
            raise ValueError('a condition is {"flag": name, "is": "set" | "clear"}')
        is_ = t.get('is', 'set')
        if is_ not in ('set', 'clear'):
            raise ValueError("a condition's 'is' is set or clear")
        out.append({'flag': t['flag']} if is_ == 'set' else {'flag': t['flag'], 'is': 'clear'})
    return out


class StoryMixin:
    def _script_or_none(self, sid):
        try:
            return self.script(sid) if isinstance(sid, str) and sid not in ('none', '') else None
        except KeyError:
            return None

    # ================================================================ checks
    def checks(self):
        return self.custom.get('checks') or []

    def check(self, name):
        return next((c for c in self.checks() if c.get('name') == name), None)

    def check_names(self):
        return [c.get('name') for c in self.checks()]

    def _check_name_ok(self, name, old=None):
        raw = str(name or '').strip()
        if not raw:
            raise ValueError('a story check needs a name')
        nm = self._slug(raw)
        if nm != old and (any(c.get('name') == nm for c in self.checks()) or
                          any(f.get('name') == nm for f in self.flags())):
            raise ValueError(f'the name {nm!r} is already a flag or a story check')
        return nm

    def _check_spec_ok(self, spec):
        k = spec.get('kind')
        if k not in ST.CHECK_KINDS:
            raise ValueError(f'kind {k!r}: one of {", ".join(ST.CHECK_KIND_ORDER)}')
        c = {'kind': k}
        for f in ST.CHECK_KINDS[k][2]:
            if f in spec:
                c[f] = copy.deepcopy(spec[f])
        if k in ('all', 'any'):
            c['terms'] = _terms_ok(spec.get('terms'))
            if not c['terms']:
                raise ValueError('“all of” / “any of” needs at least one condition')
        if k == 'story':
            if ST.milestone_index(self.custom, spec.get('milestone')) is None:
                raise ValueError('pick a milestone of the story spine')
        if spec.get('comment'):
            c['comment'] = str(spec['comment'])
        # the shape the compiler needs (numbers in range): a dry run of the record
        if k not in ('all', 'any', 'story'):
            class _P:
                def resolve_flag_ref(self, ref, ctx=''):
                    return 0
            try:
                ST.check_record(_P(), dict(c, name='x'), 'check')
            except ST.StoryError as ex:
                raise ValueError(str(ex))
        return c

    def add_check(self, name, spec):
        nm = self._check_name_ok(name)
        c = dict({'name': nm}, **self._check_spec_ok(spec))
        if len(self.checks()) >= ST.STORY_CHECK_MAX - 32:
            raise ValueError(f'at most {ST.STORY_CHECK_MAX - 32} story checks')
        self.custom.setdefault('checks', []).append(c)
        self.touch()
        return nm

    def update_check(self, name, spec, new_name=None):
        c = self.check(name)
        if c is None:
            raise ValueError(f'no story check named {name!r}')
        body = self._check_spec_ok(spec)
        if new_name is not None and new_name != name:
            self.rename_check(name, new_name)
            c = self.check(self._slug(new_name))
        for k in list(c):
            if k != 'name':
                c.pop(k)
        c.update(body)
        self.touch()
        return c['name']

    def rename_check(self, old, new):
        c = self.check(old)
        if c is None:
            raise ValueError(f'no story check named {old!r}')
        new = self._check_name_ok(new, old)
        if new == old:
            return old
        from editor2.core.flag_index import FlagIndex
        for u in FlagIndex(self.data).uses_of_name(old):
            if u.path is not None:
                self._set_path(u.path, new)
        c['name'] = new
        self.touch()
        return new

    def check_uses(self, name):
        from editor2.core.flag_index import FlagIndex
        return FlagIndex(self.data).uses_of_name(name)

    def delete_check(self, name):
        n = len(self.check_uses(name))
        if n:
            raise ValueError(f'{name!r} is still used in {n} place{"s" if n != 1 else ""} '
                             '— remove those first')
        if self.check(name) is None:
            raise ValueError(f'no story check named {name!r}')
        self.custom['checks'] = [c for c in self.checks() if c.get('name') != name]
        if not self.custom['checks']:
            self.custom.pop('checks')
        self.touch()

    def describe_check(self, name_or_spec):
        c = self.check(name_or_spec) if isinstance(name_or_spec, str) else name_or_spec
        if not c:
            return '?'
        from .shops import item_names
        from .gamedata import FAMILY_NAMES
        items = item_names()
        try:
            from .conversation import species_names
            sp = species_names()
        except Exception:                                        # noqa: BLE001
            sp = {}
        ms = dict(ST.milestones(self.custom))
        return ST.describe_check(
            c, item_name=lambda i: items.get(i, f'item {i}'),
            species_name=lambda s: sp.get(s, f'species {s}') if isinstance(sp, dict)
            else f'species {s}',
            family_name=lambda f: FAMILY_NAMES[f] if 0 <= f < len(FAMILY_NAMES) else str(f),
            milestone_name=lambda m: ms.get(m, m))

    # ================================================================ story spine
    def milestones(self):
        return ST.milestones(self.custom)

    def set_milestones(self, items):
        """[(flag, name)] in story order."""
        out = []
        seen = set()
        for f, n in items:
            if not f:
                raise ValueError('a milestone is a flag')
            if f in seen:
                raise ValueError(f'{f!r} is a milestone twice')
            if self.check(f) is not None:
                raise ValueError(f'{f!r} is a story check — a milestone is a flag the story '
                                 'turns ON')
            seen.add(f)
            out.append({'flag': f, 'name': n or f})
        st = self.custom.setdefault('story', {})
        if out:
            st['milestones'] = out
        else:
            st.pop('milestones', None)
        if not st:
            self.custom.pop('story', None)
        self.touch()

    # ================================================================ quests
    def quests(self):
        return self.custom.get('quests') or []

    def quest(self, qid):
        return next((q for q in self.quests() if q.get('id') == qid), None)

    def add_quest(self, name, giver, spec=None):
        """A new quest given by the script `giver` (an NPC's script id). Its started /
        done flags are made now (fixed numbers)."""
        qid = self._unique_id(self._slug(name or 'quest'),
                              {q.get('id') for q in self.quests()})
        if self._script_or_none(giver) is None:
            raise ValueError('a quest needs the NPC who gives it')
        if any(q.get('giver') == giver for q in self.quests()):
            raise ValueError('that NPC already gives a quest')
        # the quest becomes the NPC's conversation: its old words go
        sc = self.script(giver)
        self._drop_script_dialogues(sc)
        sc.pop('talk', None)
        sc['ops'] = [['end']]
        q = {'id': qid, 'name': name or qid, 'giver': giver}
        q.update(copy.deepcopy(spec or {}))
        started = self.add_flag(f'{qid}_started', comment=f'quest {qid}: under way') \
            if not any(f.get('name') == f'{qid}_started' for f in self.flags()) else f'{qid}_started'
        done = self.add_flag(f'{qid}_done', comment=f'quest {qid}: finished') \
            if not any(f.get('name') == f'{qid}_done' for f in self.flags()) else f'{qid}_done'
        q['flags'] = {'started': started, 'done': done}
        self.custom.setdefault('quests', []).append(q)
        self.touch()
        return qid

    def quest_for_npc(self, room, key, state_idx, index, name):
        """A quest given by NPC `index` of a screen state: its script becomes the giver
        (a new script when it has none)."""
        ent = self.npc_entries(room, key, state_idx)[index]
        sid = ent.get('script') if isinstance(ent.get('script'), str) else None
        if self._script_or_none(sid) is None:
            scripts = self.custom.setdefault('scripts', [])
            sid = self._unique_id(f"{room['id']}_quest", {s.get('id') for s in scripts})
            scripts.append({'id': sid, 'ops': [['end']]})
            table = room.setdefault('scripts', {})
            if '0' not in table:
                eid = self._unique_id(f"{room['id']}_entry", {s.get('id') for s in scripts})
                scripts.append({'id': eid, 'ops': [['end']]})
                table['0'] = eid
            n = 1
            while str(n) in table:
                n += 1
            table[str(n)] = sid
            self.update_npc(room, key, state_idx, index, script=sid)
        return self.add_quest(name, sid)

    def update_quest(self, qid, spec):
        q = self.quest(qid)
        if q is None:
            raise ValueError(f'no quest {qid!r}')
        keep = {k: q[k] for k in ('id', 'giver', 'flags') if k in q}
        for k in list(q):
            q.pop(k)
        q.update(copy.deepcopy(spec))
        q.update(keep)
        try:
            ST.quest_steps(q, f'quest {qid}')
        except ST.StoryError as ex:
            raise ValueError(str(ex))
        self.touch()

    def delete_quest(self, qid):
        q = self.quest(qid)
        if q is None:
            raise ValueError(f'no quest {qid!r}')
        self.custom['quests'] = [x for x in self.quests() if x.get('id') != qid]
        if not self.custom['quests']:
            self.custom.pop('quests')
        sc = self._script_or_none(q.get('giver'))
        if sc is not None and sc.get('_quest') == qid:
            sc.pop('_quest', None)
            sc.pop('talk', None)
            sc['ops'] = [['end']]
        self.touch()

    # ================================================================ music by flag
    def room_music_rules(self, room):
        return room.get('music_rules') or []

    def set_room_music_rules(self, room_id, rules):
        room = self.room(room_id)
        out = []
        for ru in rules or []:
            if not ru.get('song'):
                raise ValueError('a music rule needs a song')
            out.append({'when': _terms_ok(ru.get('when')), 'song': ru['song']})
        if out:
            room['music_rules'] = out
        else:
            room.pop('music_rules', None)
        self.touch()

    def gate_music_rules(self, gid):
        g = ((self.custom.get('music') or {}).get('gates') or {}).get(str(gid)) or {}
        return g.get('rules') or []

    def set_gate_music_rules(self, gid, rules):
        out = []
        for ru in rules or []:
            if not ru.get('song'):
                raise ValueError('a music rule needs a song')
            out.append({'when': _terms_ok(ru.get('when')), 'song': ru['song']})
        m = self.custom.setdefault('music', {})
        gates = m.setdefault('gates', {})
        g = gates.setdefault(str(gid), {})
        if out:
            g['rules'] = out
        else:
            g.pop('rules', None)
        if not g:
            gates.pop(str(gid))
        if not gates:
            m.pop('gates')
        if not m:
            self.custom.pop('music')
        self.touch()

    # ================================================================ shop item sets
    def shop_sets(self, shop=None):
        sets = self.custom.get('shop_sets') or []
        return [s for s in sets if shop is None or s.get('shop') == shop]

    def set_shop_sets(self, shop, sets):
        """The item sets of one shop (in order: the first whose conditions hold sells)."""
        new = []
        for s in sets or []:
            items = [int(i) for i in s.get('items') or []]
            if not items:
                raise ValueError('an item set needs at least one item')
            if len(items) > 20:
                raise ValueError('an item set holds at most 20 items')
            ent = {'shop': shop, 'name': s.get('name') or f'{shop} set {len(new) + 1}',
                   'when': _terms_ok(s.get('when')), 'items': items}
            if not ent['when']:
                raise ValueError('an item set needs a condition (else the shop sells it '
                                 'always — change the shop\'s own list instead)')
            new.append(ent)
        rest = [s for s in self.custom.get('shop_sets') or [] if s.get('shop') != shop]
        if rest or new:
            self.custom['shop_sets'] = rest + new
        else:
            self.custom.pop('shop_sets', None)
        self.touch()

    # ================================================================ locked doors
    def exit_rows_at(self, room, key, state_idx, x, y):
        tgt = self._state_target(room, key, state_idx)
        return [e for e in tgt.get('exits') or []
                if int(e.get('x', -1)) == int(x) and int(e.get('y', -1)) == int(y)]

    def lock_exit(self, room_id, key, x, y, terms, boxes):
        """The exit / door at (x, y) of screen `key` opens only while `terms` hold
        (S129, user: "UNWALKABLE and interactable THEN walk-upon-able when flag set …
        make a new room state and switch to that"). The screen must have ONE state
        (its look = the open door): a second state is added — the LOCKED look, a
        copy with its own layout where the exit's cell(s) are walls (the bottom-right
        subtile's twin, S94) and an examine spot saying `boxes`, and without the exit
        rows. State rules: state 0 while `terms` hold, otherwise state 1. Returns the
        locked state's index. Paint the closed door in it; a step "Refresh the room"
        right after the flag turns ON opens it at once."""
        room = self.room(room_id)
        key = str(key)
        terms = _terms_ok(terms)
        if not terms:
            raise ValueError('a lock needs a condition (a flag or a story check)')
        scr = self.screen(room, key)
        if scr.get('states') and len(scr['states']) > 1:
            raise ValueError('this screen already has several room states — a lock adds '
                             'one; make the locked look by hand there (a state, its rule, '
                             'the door only in the open state, an examine spot)')
        rows = self.exit_rows_at(room, key, 0, x, y)
        if not rows:
            raise ValueError(f'no exit or door at ({x}, {y})')
        cells = {(int(x), int(y))}
        did = rows[0].get('door') or rows[0].get('twin_of')
        if did:
            for e in self._state_target(room, key, 0).get('exits') or []:
                if e.get('door') == did or e.get('twin_of') == did:
                    cells.add((int(e['x']), int(e['y'])))
        idx, lid = self.add_state(room, key, copy_from=0, own_layout=True)
        st = self.screen(room, key)['states'][idx]
        st['comment'] = f'locked: the exit at ({x}, {y}) is shut (S129 lock)'
        st['exits'] = [e for e in st.get('exits') or []
                       if (int(e.get('x', -1)), int(e.get('y', -1))) not in cells]
        tid = self.tileset_key(room)
        if lid is not None:
            for cx, cy in sorted(cells):
                try:
                    self.set_cell_walkable(lid, tid, cx, cy, False)
                except Exception:                                # noqa: BLE001
                    pass       # no wall twin in this tileset: the spot still answers
        sid = self.new_talk_script(room, boxes or [['It is locked.']], name='locked')
        for cx, cy in sorted(cells):
            self.add_spot(room, key, idx, 'examine', cx, cy, sid, 'any')
        rules = list(self.state_rules(room))
        rules.append({'state': 0, 'when': terms, 'screens': [int(key)],
                      'comment': f'the exit at ({x}, {y}) is open'})
        rules.append({'state': idx, 'when': [], 'screens': [int(key)],
                      'comment': f'otherwise the exit at ({x}, {y}) is locked'})
        self.set_state_rules(room, rules)
        self.touch()
        return idx
