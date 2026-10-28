"""hints_doc.py — editing the breeding hints (S158, ROADMAP E15).

Headless Document mixin (no Qt): custom.hints (the pool: blacklist / whitelist, the
crosses ticked, pinned numbers, riddles, the words) and the rooms' monuments /
archives (editor2/core/hints.py, PROJECT_COMPILER §2.66). A MONUMENT / an ARCHIVE
stands on a cell of a screen state as an npcs[] entry {"kind": "monument" | "archive",
"x", "y", "monument" | "archive": id} — an examine spot in the game, on the author's
own art (a stone, a bookcase with the family's emblem). The Breeding tab's Hints view
and the Rooms tab read and write only through these; every change is one undo step
there.
"""

import copy

from editor2.core import hints as HT

ROLE_LABELS = {
    'monument': "a monument's words (the cross)",
    'exhausted': 'a monument with no hint left',
    'archive_ask': 'an archive asks (YES / NO)',
    'archive_empty': 'an archive with no clue yet',
    'archive_entry': 'an archive entry (one cross)',
    'archive_more': 'after each entry (YES / NO)',
    'archive_end': 'after the last entry',
    'archive_no': 'the player answered NO (optional)',
}


class HintsMixin:
    # ------------------------------------------------------------ settings
    def _hints(self):
        return self.custom.setdefault('hints', {})

    def _hint_dialogue(self, did):
        for d in self.custom.get('dialogue') or []:
            if isinstance(d, dict) and d.get('id') == did:
                return d
        return None

    def _hint_boxes(self, v):
        """A stored hint text (inline boxes, or a dialogue id) -> boxes (or None)."""
        if isinstance(v, list):
            return copy.deepcopy(v)
        if isinstance(v, str):
            d = self._hint_dialogue(v)
            if d and d.get('boxes'):
                return copy.deepcopy(d['boxes'])
        return None

    def hints_settings(self):
        """{'mode', 'words': {role: boxes or None}, 'own': {role: bool}, 'family_words':
        [11], 'bred_word', 'unbred_word'} — the compiler's defaults where the project
        has none."""
        cfg = HT.settings(self.custom)
        words, own = {}, {}
        for role in HT.WORD_KEYS:
            got = self._hint_boxes(cfg['words'].get(role))
            own[role] = got is not None
            if got is not None:
                words[role] = got
            else:
                dflt = HT.DEFAULTS[role][0]
                words[role] = copy.deepcopy(dflt) if dflt else None
        return {'mode': cfg['mode'], 'words': words, 'own': own,
                'family_words': list(cfg['family_words']),
                'bred_word': cfg['bred_word'], 'unbred_word': cfg['unbred_word']}

    def set_hints_mode(self, mode):
        """'blacklist' (every cross that can fire, minus the excluded) or 'whitelist'
        (only the included); both lists are kept."""
        if mode not in HT.MODES:
            raise ValueError(f"mode: {', '.join(HT.MODES)}")
        h = self._hints()
        if mode == 'blacklist':
            h.pop('mode', None)
        else:
            h['mode'] = mode
        self.touch()
        self.pin_hint_numbers()

    def set_hint_words(self, role, boxes):
        """The project's words for a role (boxes), or None = back to the default."""
        if role not in HT.WORD_KEYS:
            raise ValueError(role)
        h = self._hints()
        w = h.setdefault('words', {})
        if boxes is None:
            w.pop(role, None)
        else:
            HT.check_text(boxes, f'the {role} words', family=role.startswith('archive_'))
            w[role] = [list(b) for b in boxes]
        if not w:
            h.pop('words')
        self.touch()

    def set_family_word(self, family, words):
        """A family matcher's words ("any Dragon"); None = the default."""
        fi = HT.family_index(family)
        if fi is None:
            raise ValueError(f'{family!r} is not a family')
        h = self._hints()
        fw = h.setdefault('family_words', {})
        for k in list(fw):
            if HT.family_index(k) == fi:
                fw.pop(k)
        if words not in (None, '', f'any {HT.FAMILIES[fi]}'):
            fw[HT.FAMILIES[fi]] = words
        if not fw:
            h.pop('family_words')
        HT.settings(self.custom)                   # raises on bad words
        self.touch()

    def set_bred_words(self, bred=None, unbred=None):
        h = self._hints()
        for k, v, dflt in (('bred_word', bred, '(bred)'), ('unbred_word', unbred, '')):
            if v is None:
                continue
            if v == dflt:
                h.pop(k, None)
            else:
                h[k] = v
        HT.settings(self.custom)
        self.touch()

    # ------------------------------------------------------------ the pool
    def hint_rows(self):
        """Every cross that can be a hint (the effective special table, table order),
        + the project's keys whose cross is gone ('gone': True):
          [{'key', 'p1', 'p2', 'plus', 'child', 'fam', 'row', 'in_pool', 'number',
            'riddle' (boxes or None), 'gone'}]"""
        prj = self.model_project()
        cfg = HT.settings(self.custom)
        cands = HT.candidates(prj)
        try:
            hints, _n, _h = HT.pool(prj)
            num = {c['key']: c['number'] for c in hints}
        except HT.HintError:
            num = {}
        keys = set()
        out = []
        for c in cands:
            keys.add(c['key'])
            r = dict(c)
            r['in_pool'] = c['key'] in num
            r['number'] = num.get(c['key'], cfg['numbers'].get(c['key']))
            r['riddle'] = self._hint_boxes(cfg['riddles'].get(c['key']))
            r['gone'] = False
            out.append(r)
        extra = (set(cfg['include']) | set(cfg['exclude']) | set(cfg['riddles'])
                 | set(cfg['numbers'])) - keys
        for k in sorted(extra):
            try:
                p1, p2, plus, child = HT.parse_key(k)
            except ValueError:
                continue
            g = prj.gamedata()
            fc = g.fam_code(child)
            out.append({'key': k, 'p1': p1, 'p2': p2, 'plus': plus, 'child': child,
                        'fam': (fc - 0xF0) if fc else None, 'row': None, 'in_pool': False,
                        'number': cfg['numbers'].get(k), 'riddle': None, 'gone': True})
        return out

    def set_hints_in_pool(self, keys, on):
        """Put crosses in the pool (on) or take them out: blacklist mode edits
        'exclude', whitelist mode 'include'."""
        h = self._hints()
        mode = h.get('mode', 'blacklist')
        lst = h.setdefault('exclude' if mode == 'blacklist' else 'include', [])
        want_in_list = (not on) if mode == 'blacklist' else on
        for k in keys:
            HT.parse_key(k)
            if want_in_list and k not in lst:
                lst.append(k)
            elif not want_in_list and k in lst:
                lst.remove(k)
        for k2 in ('exclude', 'include'):
            if k2 in h and not h[k2]:
                h.pop(k2)
        self.touch()
        self.pin_hint_numbers()

    def pin_hint_numbers(self):
        """Every hint of the pool keeps its number from now on (the save's bit):
        numbers are only ever ADDED. Returns how many were new."""
        try:
            nums = HT.numbers_to_pin(self.model_project())
        except Exception:                                  # noqa: BLE001 — a bad table
            return 0
        h = self._hints()
        have = h.setdefault('numbers', {})
        new = 0
        for k, n in nums.items():
            if k not in have:
                have[k] = n
                new += 1
        if not have:
            h.pop('numbers')
        if new:
            self.touch()
        return new

    def renumber_hints(self):
        """Numbers again from 0 for the pool as it is (an OLD SAVE then reads other
        hints' bits — for a fresh start before release)."""
        h = self._hints()
        h.pop('numbers', None)
        self.touch()
        return self.pin_hint_numbers()

    def set_hint_riddle(self, key, boxes):
        """A hint's riddle (boxes; {parent1} / {parent2} / {child} allowed), or None."""
        HT.parse_key(key)
        h = self._hints()
        rd = h.setdefault('riddles', {})
        if boxes is None:
            rd.pop(key, None)
        else:
            HT.check_text(boxes, f'the riddle of {key}')
            rd[key] = [list(b) for b in boxes]
        if not rd:
            h.pop('riddles')
        self.touch()

    # ------------------------------------------------------------ room objects
    def monuments(self, room):
        return list(room.get('monuments') or [])

    def archives(self, room):
        return list(room.get('archives') or [])

    def monument(self, room, mid):
        return next((m for m in room.get('monuments') or [] if m.get('id') == mid), None)

    def archive(self, room, aid):
        return next((a for a in room.get('archives') or [] if a.get('id') == aid), None)

    def hint_object_places(self, room, kind, oid):
        """[(screen key, state, npcs index)] where monument / archive `oid` stands."""
        out = []
        for k, scr in (room.get('screens') or {}).items():
            for s, st in enumerate(HT._states(scr)):
                for i, n in enumerate(st.get('npcs') or []):
                    if isinstance(n, dict) and n.get('kind') == kind and n.get(kind) == oid:
                        out.append((k, s, i))
        return out

    def _hint_cell_free(self, room, key, state_idx, x, y):
        for e in self.npc_entries(room, key, state_idx):
            v = self.npc_view(room, e)
            if (v['x'], v['y']) == (int(x), int(y)) and v['kind'] in (
                    'examine', 'step', 'spawn', 'statue', 'monument', 'archive'):
                raise ValueError(f"cell ({x},{y}) already has a {v['kind']} here")

    def _hint_new_id(self, room, base):
        taken = {o.get('id') for o in (room.get('monuments') or [])
                 + (room.get('archives') or [])}
        i = 1
        while f'{base}_{i}' in taken:
            i += 1
        return f'{base}_{i}'

    def add_monument(self, room, key, state_idx, x, y, families=None, skip_owned=True,
                     show='explicit', name=None):
        """A new monument on (x, y) of this screen state -> its id."""
        if len(room.get('monuments') or []) >= HT.MONUMENTS_ROOM_MAX:
            raise ValueError(f'a room holds at most {HT.MONUMENTS_ROOM_MAX} monuments')
        if show not in HT.SHOWS:
            raise ValueError(f"show: {', '.join(HT.SHOWS)}")
        self._hint_cell_free(room, key, state_idx, x, y)
        mid = self._hint_new_id(room, 'monument')
        m = {'id': mid}
        if name:
            m['name'] = name
        if families:
            m['families'] = [HT.FAMILIES[HT.family_index(f)] for f in families]
        if not skip_owned:
            m['skip_owned'] = False
        if show != 'explicit':
            m['show'] = show
        room.setdefault('monuments', []).append(m)
        self.npc_entries(room, key, state_idx).append(
            {'kind': 'monument', 'x': int(x), 'y': int(y), 'monument': mid})
        self.touch()
        self.pin_hint_numbers()                    # the first monument: the pool's bits fixed
        return mid

    def add_archive(self, room, key, state_idx, x, y, family, name=None):
        """A new archive (one family) on (x, y) of this screen state -> its id."""
        fi = HT.family_index(family)
        if fi is None:
            raise ValueError(f'{family!r} is not a family')
        self._hint_cell_free(room, key, state_idx, x, y)
        aid = self._hint_new_id(room, 'archive')
        a = {'id': aid, 'family': HT.FAMILIES[fi]}
        if name:
            a['name'] = name
        room.setdefault('archives', []).append(a)
        self.npc_entries(room, key, state_idx).append(
            {'kind': 'archive', 'x': int(x), 'y': int(y), 'archive': aid})
        self.touch()
        self.pin_hint_numbers()
        return aid

    def place_hint_object(self, room, key, state_idx, x, y, kind, oid):
        """An EXISTING monument / archive stands on (x, y) of this screen state too."""
        if (kind == 'monument' and self.monument(room, oid) is None) or \
                (kind == 'archive' and self.archive(room, oid) is None):
            raise ValueError(f'no {kind} {oid!r} in this room')
        self._hint_cell_free(room, key, state_idx, x, y)
        self.npc_entries(room, key, state_idx).append(
            {'kind': kind, 'x': int(x), 'y': int(y), kind: oid})
        self.touch()
        return len(self.npc_entries(room, key, state_idx)) - 1

    def remove_hint_object_here(self, room, key, state_idx, index):
        """Take a monument / archive entry off this screen state; the object itself
        goes when it stands nowhere any more."""
        lst = self.npc_entries(room, key, state_idx)
        e = lst.pop(index)
        kind = e.get('kind')
        oid = e.get(kind)
        lk = 'monuments' if kind == 'monument' else 'archives'
        if oid and not self.hint_object_places(room, kind, oid):
            room[lk] = [o for o in room.get(lk) or [] if o.get('id') != oid]
            if not room[lk]:
                room.pop(lk)
        self.touch()
        return e

    def update_monument(self, room, mid, **fields):
        """families (a list, None = every family) / skip_owned / show / name."""
        m = self.monument(room, mid)
        if m is None:
            raise ValueError(f'no monument {mid!r}')
        if 'families' in fields:
            fams = fields['families']
            if fams:
                m['families'] = [HT.FAMILIES[HT.family_index(f)] for f in fams]
            else:
                m.pop('families', None)
        if 'skip_owned' in fields:
            if fields['skip_owned']:
                m.pop('skip_owned', None)
            else:
                m['skip_owned'] = False
        if 'show' in fields:
            if fields['show'] not in HT.SHOWS:
                raise ValueError(f"show: {', '.join(HT.SHOWS)}")
            if fields['show'] == 'explicit':
                m.pop('show', None)
            else:
                m['show'] = fields['show']
        if 'name' in fields:
            if fields['name']:
                m['name'] = fields['name']
            else:
                m.pop('name', None)
        self.touch()

    def update_archive(self, room, aid, family=None, name=None):
        a = self.archive(room, aid)
        if a is None:
            raise ValueError(f'no archive {aid!r}')
        if family is not None:
            fi = HT.family_index(family)
            if fi is None:
                raise ValueError(f'{family!r} is not a family')
            a['family'] = HT.FAMILIES[fi]
        if name is not None:
            if name:
                a['name'] = name
            else:
                a.pop('name', None)
        self.touch()

    def set_hint_object_words(self, room, kind, oid, role, boxes):
        """A monument's (intro / text / outro / exhausted) or an archive's (ask / empty /
        entry / more / end / no) OWN words (boxes), or None = back to the project's."""
        roles = HT.TEXT_ROLES_MON if kind == 'monument' else HT.TEXT_ROLES_ARC
        if role not in roles:
            raise ValueError(f"{kind} words: {', '.join(roles)}")
        o = self.monument(room, oid) if kind == 'monument' else self.archive(room, oid)
        if o is None:
            raise ValueError(f'no {kind} {oid!r}')
        if boxes is None:
            o.pop(role, None)
        else:
            HT.check_text(boxes, f"{kind} '{oid}' {role}", family=kind == 'archive')
            o[role] = [list(b) for b in boxes]
        self.touch()

    def hint_object_words(self, room, kind, oid):
        """{role: (boxes or None, own)} for the panel (the project's words where the
        object has none; intro / outro / no: None when nobody wrote any)."""
        o = (self.monument(room, oid) if kind == 'monument' else self.archive(room, oid)) or {}
        base = self.hints_settings()['words']
        out = {}
        if kind == 'monument':
            pairs = (('intro', None), ('text', 'monument'), ('outro', None),
                     ('exhausted', 'exhausted'))
        else:
            pairs = tuple((r, HT.ARC_ROLE_WORD[r]) for r in HT.TEXT_ROLES_ARC)
        for role, word in pairs:
            got = self._hint_boxes(o.get(role))
            if got is not None:
                out[role] = (got, True)
            else:
                out[role] = (copy.deepcopy(base.get(word)) if word else None, False)
        return out
