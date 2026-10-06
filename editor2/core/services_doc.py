"""services_doc.py — the Services tab's model (ROADMAP P3.14e1, S126; compiler:
editor2/core/services.py, PROJECT_COMPILER §2.39).

Mixed into Document. Every mutation edits project data only:
  * custom.scripts[] {"service": {...}}   a service NPC (an NPC's script)
  * custom.service_lines[]                the project's line sets
  * custom.scripts[] {"shop": {"lines"}}  a shopkeeper's own menu lines
  * gamedata.medals.rewards               the Medal Man's rewards
"""

from editor2.core import services as SV


class ServicesMixin:
    # ------------------------------------------------------------ reading
    def service_kinds(self):
        """[(kind, name, what)] in the order the editor offers them."""
        return [(k, v['name'], v['what']) for k, v in SV.KINDS.items()]

    def service_block(self, kind):
        """The game's lines of a service's menu: [{off, id, text, speaker,
        voice, used}] — `used` = the game's code or the NPC's script speaks it
        (the static census; a few lines are reached only through computed
        offsets and show as unused)."""
        b = SV.block(kind, getattr(self, 'repo_root', None))
        eng = set(b['engine_offsets'])
        spoken = {0, 2} if kind not in ('medals',) else {0}
        if kind == 'medals':
            spoken |= set(range(3, 3 + SV.MEDALS_MAX))     # the reward lines
        out = []
        for ln in b['lines']:
            out.append({'off': ln['off'], 'id': ln['id'], 'text': ln['text'],
                        'speaker': ln['speaker'], 'voice': ln['voice'],
                        'used': ln['off'] in eng or ln['off'] in spoken})
        return out

    def service_script(self, sid):
        for s in self.custom.get('scripts', []):
            if s.get('id') == sid and isinstance(s.get('service'), dict):
                return s
        return None

    def _npc_script_id(self, room, key, state_idx, index):
        e = self.npc_entries(room, key, state_idx)[index]
        sc = e.get('script')
        if isinstance(sc, int):
            sc = (room.get('scripts') or {}).get(str(sc))
        return sc if isinstance(sc, str) else None

    def service_of(self, room, key, state_idx, index):
        """{kind, lines, first_time {text boxes, flag}} when that NPC is a
        service NPC, else None."""
        s = self.service_script(self._npc_script_id(room, key, state_idx, index))
        if s is None:
            return None
        sv = dict(s['service'])
        ft = sv.get('first_time')
        if isinstance(ft, dict):
            boxes = None
            for d in self.custom.get('dialogue', []):
                if d.get('id') == ft.get('text'):
                    boxes = d.get('boxes')
            sv['first_time'] = {'boxes': boxes, 'flag': ft.get('flag'), 'text': ft.get('text')}
        return sv

    def service_npcs(self):
        """[(room, screen key, state index, npc entry, script id, spec)] of every
        service NPC and every shopkeeper with its own lines."""
        sids = {}
        for s in self.custom.get('scripts', []):
            if isinstance(s.get('service'), dict):
                sids[s['id']] = s['service']
            elif isinstance(s.get('shop'), dict) and s['shop'].get('lines'):
                sids[s['id']] = {'kind': 'shop', 'lines': s['shop']['lines']}
        out = []
        if not sids:
            return out
        for r in self.rooms:
            if r.get('placeholder'):
                continue
            table = r.get('scripts') or {}
            for k in self.screen_keys(r):
                for n, st in enumerate(self.states(r, k)):
                    for e in st.get('npcs') or []:
                        sc = e.get('script')
                        if isinstance(sc, int):
                            sc = table.get(str(sc))
                        if sc in sids:
                            out.append((r, k, n, e, sc, sids[sc]))
        return out

    def service_line_sets(self, kind=None):
        """[{id, kind, name, speaker, voice, everywhere, lines {off: text}, users}]."""
        users = {}
        for s in self.custom.get('scripts', []):
            for spec in (s.get('service'), s.get('shop')):
                if isinstance(spec, dict) and spec.get('lines'):
                    users.setdefault(spec['lines'], []).append(s['id'])
        out = []
        for st in self.custom.get('service_lines') or []:
            if kind is not None and st.get('kind') != kind:
                continue
            out.append({'id': st['id'], 'kind': st.get('kind'),
                        'name': st.get('name') or st['id'],
                        'speaker': st.get('speaker'), 'voice': st.get('voice'),
                        'everywhere': bool(st.get('everywhere')),
                        'lines': {int(k): v for k, v in (st.get('lines') or {}).items()},
                        'users': users.get(st['id'], [])})
        return out

    def _line_set(self, sid):
        for st in self.custom.get('service_lines') or []:
            if st.get('id') == sid:
                return st
        raise ValueError(f'no line set {sid!r}')

    def service_line_text(self, sid, off):
        """What line `off` of set `sid` says: (text, changed?) — the game's words
        (re-flowed for the set's speaker) when the set leaves it alone."""
        st = self._line_set(sid)
        vl = SV.vline(st['kind'], off, getattr(self, 'repo_root', None))
        t = (st.get('lines') or {}).get(str(off))
        if t is not None:
            return t, True
        return SV.fit_text(vl, vl['text'], st.get('speaker')), False

    def service_line_problems(self, kind, off, text, speaker=None):
        """Box-format problems of a typed line (empty list = it fits)."""
        vl = SV.vline(kind, off, getattr(self, 'repo_root', None))
        try:
            SV.encode_body(text)
        except SV.ServiceError as ex:
            return [str(ex)]
        return SV.line_problems(vl, text, speaker)

    def service_label_cells(self, kind, off, speaker=None):
        vl = SV.vline(kind, off, getattr(self, 'repo_root', None))
        return SV.label_cells(vl, speaker)

    def medal_rewards_doc(self):
        """[{medals, enemy, eid, egg, line, default_line}] — the project's rewards,
        or the game's 4 (edited False)."""
        md = (self.data.get('gamedata') or {}).get('medals')
        rows = md.get('rewards') if md else [
            {'medals': r['medals'], 'enemy': r['eid']}
            for r in SV.data(getattr(self, 'repo_root', None))['medal_rewards']['rows']]
        out = []
        repo = getattr(self, 'repo_root', None)
        for i, r in enumerate(rows):
            eid = self._medal_eid(r.get('enemy'))
            egg = self._egg_name(eid)
            vl = SV.vline('medals', 3 + i, repo) if i < SV.MEDALS_MAX else None
            line = r.get('line')
            try:
                probs = SV.line_problems(vl, line) if (vl and line) else []
            except SV.ServiceError as ex:
                probs = [str(ex)]
            out.append({'medals': r.get('medals'), 'enemy': r.get('enemy'), 'eid': eid,
                        'egg': egg, 'line': line, 'problems': probs,
                        'default_line': (SV.reward_default(vl, egg, i == len(rows) - 1)
                                         if vl else '')})
        return out, bool(md)

    def _medal_eid(self, ref):
        e = self.project_enemy(ref) if hasattr(self, 'project_enemy') else None
        if e is not None:
            return self.project_eid(e)
        try:
            return int(str(ref), 0)
        except (TypeError, ValueError):
            return None

    def _egg_name(self, eid):
        from editor2.core import conversation as CV
        names = CV.species_names(self.data)
        if eid is None:
            return '?'
        if eid >= 519:
            for e in self.project_enemies():
                if self.project_eid(e) == eid:
                    return names.get(int(e.get('species', 0)), 'monster')
            return 'monster'
        for r in CV.vanilla_enemies():
            if r['eid'] == eid:
                return names.get(r['species'], 'monster')
        return 'monster'

    # ------------------------------------------------------------ editing
    def make_service_npc(self, room, key, state_idx, index, kind, lines=None,
                         first_time=None):
        """NPC npcs[index] of (room, key, state) becomes the `kind` service.
        lines = a line set id (None = the game's lines); first_time = {"boxes":
        [[line, line], …], "flag": <name>} (the flag is created when new) or
        None. Returns the script id."""
        if kind not in SV.KINDS:
            raise ValueError(f'unknown service {kind!r}')
        if lines is not None:
            st = self._line_set(lines)
            if st.get('kind') != kind:
                raise ValueError(f'line set {lines!r} is for {st.get("kind")!r}, not {kind!r}')
        lst = self.npc_entries(room, key, state_idx)
        e = lst[index]
        old = self._npc_script_id(room, key, state_idx, index)
        scripts = self.custom.setdefault('scripts', [])
        prev = self.service_script(old) if old else None
        sids = {s.get('id') for s in scripts}
        if prev is not None:
            sid = prev['id']
            self._drop_first_time_text(prev)
        else:
            sid = self._unique_id(f"{room['id']}_{kind}", sids)
        spec = {'kind': kind}
        if lines is not None:
            spec['lines'] = lines
        if first_time:
            flag = first_time.get('flag')
            if not flag:
                raise ValueError('the first visit needs a flag (it remembers the visit)')
            if not any(f.get('name') == flag for f in self.flags()):
                self.add_flag(flag, f'{SV.KINDS[kind]["name"]}: met')
            spec['first_time'] = {'text': self._talk_entry(sid, first_time['boxes']),
                                  'flag': flag}
        if prev is not None:
            prev['service'] = spec
        else:
            scripts.append({'id': sid, 'service': spec})
            table = room.setdefault('scripts', {})
            if '0' not in table:
                eid = self._unique_id(f"{room['id']}_entry", sids | {sid})
                scripts.append({'id': eid, 'ops': [['end']]})
                table['0'] = eid
            n = 1
            while str(n) in table:
                n += 1
            table[str(n)] = sid
            if e.get('kind') == 'raw':
                v = self.npc_view(room, e)
                v['script'] = sid
                lst[index] = self._npc_entry(v)
            else:
                e['script'] = sid
        if not e.get('actor') and e.get('kind') != 'raw':
            e['actor'] = SV.KINDS[kind]['name']
        self.touch()
        return sid

    def _drop_first_time_text(self, s):
        ft = (s.get('service') or {}).get('first_time')
        if isinstance(ft, dict) and ft.get('text'):
            self.custom['dialogue'] = [d for d in self.custom.get('dialogue', [])
                                       if d.get('id') != ft['text']]

    def add_service_lines(self, kind, name, speaker=None):
        """A new (empty) line set for `kind`; returns its id."""
        if kind not in SV.LINE_KINDS:
            raise ValueError(f'{kind!r} has no lines of its own')
        lst = self.custom.setdefault('service_lines', [])
        sid = self._unique_id(self._slug(name) or f'{kind}_lines', {s.get('id') for s in lst})
        ent = {'id': sid, 'kind': kind, 'name': str(name).strip() or sid, 'lines': {}}
        if speaker is not None:
            ent['speaker'] = speaker
        lst.append(ent)
        self.touch()
        return sid

    def set_service_line(self, sid, off, text):
        """Line `off` of set `sid` says `text`; None (or the game's words for
        this speaker) = the game's line again."""
        st = self._line_set(sid)
        vl = SV.vline(st['kind'], int(off), getattr(self, 'repo_root', None))
        lines = st.setdefault('lines', {})
        if text is None or text == SV.fit_text(vl, vl['text'], st.get('speaker')):
            lines.pop(str(int(off)), None)
        else:
            SV.encode_body(text)                   # raises on a glyph the font lacks
            lines[str(int(off))] = text
        self.touch()

    def set_service_lines_meta(self, sid, **kw):
        """name / speaker (None = the game's) / voice (None = the game's) /
        everywhere (bool)."""
        st = self._line_set(sid)
        for k in ('name', 'speaker', 'voice', 'everywhere'):
            if k not in kw:
                continue
            v = kw[k]
            if k == 'everywhere':
                if v:
                    st['everywhere'] = True
                else:
                    st.pop('everywhere', None)
            elif v is None or (k == 'name' and not str(v).strip()):
                st.pop(k, None)
            else:
                if k == 'voice' and v not in ('low', 'high'):
                    raise ValueError('voice: low or high')
                st[k] = str(v).strip() if k == 'name' else v
        self.touch()

    def delete_service_lines(self, sid):
        """Remove a line set; the NPCs that spoke it go back to the game's
        lines. Returns how many scripts used it."""
        st = self._line_set(sid)
        n = 0
        for s in self.custom.get('scripts', []):
            for spec in (s.get('service'), s.get('shop')):
                if isinstance(spec, dict) and spec.get('lines') == sid:
                    spec.pop('lines')
                    n += 1
        self.custom['service_lines'].remove(st)
        if not self.custom['service_lines']:
            self.custom.pop('service_lines')
        self.touch()
        return n

    def set_shop_lines(self, room, key, state_idx, index, sid):
        """The shopkeeper NPC speaks line set `sid` (kind "shop"; None = the
        game's lines)."""
        s = self.shop_script(self._npc_script_id(room, key, state_idx, index))
        if s is None:
            raise ValueError('that NPC is not a shopkeeper')
        if sid is None:
            s['shop'].pop('lines', None)
        else:
            if self._line_set(sid).get('kind') != 'shop':
                raise ValueError(f'{sid!r} is not a shop line set')
            s['shop']['lines'] = sid
        self.touch()

    def set_medal_rewards(self, rewards):
        """rewards = [{"medals", "enemy", "line"?}] (1-8, rising), or None = the
        game's 4 rewards and lines."""
        gd = self.data.setdefault('gamedata', {})
        if rewards is None:
            gd.pop('medals', None)
        else:
            if not 1 <= len(rewards) <= SV.MEDALS_MAX:
                raise ValueError(f'1-{SV.MEDALS_MAX} rewards (the eggs given set flags '
                                 '$0050-$0057)')
            last = 0
            rows = []
            for r in rewards:
                m = int(r['medals'])
                if not last < m <= SV.MEDAL_TOTAL_MAX:
                    raise ValueError(f'{m} medals: each reward needs more medals than the '
                                     f'one before, at most {SV.MEDAL_TOTAL_MAX}')
                last = m
                row = {'medals': m, 'enemy': r['enemy']}
                if r.get('line'):
                    SV.encode_body(r['line'])
                    row['line'] = r['line']
                rows.append(row)
            gd['medals'] = {'rewards': rows}
        if not gd:
            self.data.pop('gamedata')
        self.touch()
