"""encounters_doc.py — the Encounters tab's document model (ROADMAP P3.13a,
S114; EDITOR_DESIGN §5.5 "As built S114"; compiler side: editor2/core/
encounters.py, PROJECT_COMPILER §2.30).

Reads the project through the compiler's own model (encounters.Model) and
writes:
  * the game's 128 lists — gamedata.encounters.<n> (only what differs from
    the original game, as the Monsters tab's pool dialog already did);
  * the project's OWN lists — custom.encounter_lists[] (numbers 128+);
  * a custom room's battles — custom.rooms[].encounters (off / the gate's list
    at a gate + floor / the dive's list / its own list + flag variants; rate);
  * a gate's own plan — custom.gates[].encounters (the list of each floor +
    flag variants).
Every setter validates with the compiler's checks before it is kept
(MonstersMixin._commit_data -> encounters.check).
"""

import copy

from editor2.core import encounters as EN
from editor2.core import gamedata as G

RATE_HELP = ('How often battles come: the step drain is the base rate x this code\'s '
             'modifier / 64 (bank $16). Outside gates the base is 100; on gate floors it '
             'depends on the floor type (100-250).')


def _label_floors(a, b):
    return f'floor {a}' if a == b else f'floors {a}-{b}'


def when_text(terms, names):
    """[(flag index, must_clear)] -> 'when flag_x is set and …'."""
    parts = []
    for idx, clr in terms:
        parts.append(f"{names.get(idx, f'flag ${idx:04X}')} is {'clear' if clr else 'set'}")
    return 'when ' + ' and '.join(parts)


class EncountersMixin:
    # ------------------------------------------------------------ models
    def enc_model(self, data=None):
        """(encounters.Model, Project) of the current data (raises on bad data)."""
        prj = self._project(data)
        return EN.resolve(prj), prj

    def _flag_names(self, prj):
        return {v: k for k, v in prj.flag_map().items()}

    def _enemy_lookup(self, M):
        """eid -> (species id, level, name) for vanilla rows (edits included)
        and the project's enemies."""
        g = M.gd
        names = G.monster_names(EN._repo(M.prj))
        for s in (self.data.get('custom') or {}).get('species') or []:
            names[s.get('id')] = s.get('name')
        names.update(getattr(g, 'text_names', {}) or {})
        proj = {}
        for e in self.project_enemies():
            proj[self.project_eid(e)] = e

        def look(eid):
            if eid in proj:
                e = proj[eid]
                sp = e.get('species')
                return sp, e.get('level'), names.get(sp, f'#{sp}'), e.get('id')
            if 0 <= eid <= G.VANILLA_EID_MAX:
                r = g.enemy[eid]
                return r[0], r[4], names.get(r[0], f'#{r[0]}'), None
            return None, None, f'EID {eid}?', None
        return look

    def enemy_choices(self, M=None):
        """[(label, ref, eid, species)] for a list slot: the project's enemies
        first (ref = their id), then the game's rows 1-486 (ref = the EID;
        edits included; bosses / arena teams tagged)."""
        if M is None:
            M, _prj = self.enc_model()
        look = self._enemy_lookup(M)
        from editor2.core.conversation import vanilla_enemies
        boss = {r['eid']: r.get('boss') for r in vanilla_enemies() if r.get('boss')}
        out = []
        for e in self.project_enemies():
            eid = self.project_eid(e)
            sp, lv, name, pid = look(eid)
            out.append((f"{name} Lv {lv} — your enemy {pid} (EID {eid})", pid, eid, sp))
        for eid in range(1, G.VANILLA_EID_MAX + 1):
            sp, lv, name, _pid = look(eid)
            tag = f" — {boss[eid]}" if eid in boss else ''
            out.append((f"{name} Lv {lv} (EID {eid}){tag}", eid, eid, sp))
        return out

    # ------------------------------------------------------------ usage
    def enc_usage(self, M=None, prj=None):
        """{list number: [use]} — use = {'kind': 'gate'|'room', 'label', 'gate'|
        'room', 'floors' (a, b) for gates, 'variant' (None = the default), 'when'}."""
        if M is None:
            M, prj = self.enc_model()
        prj = prj or M.prj
        from editor2.core import gates as GT
        names = self._flag_names(prj)
        out = {}
        gates = {g['id']: g for g in GT.all_gates(prj.custom, EN._repo(prj))}
        for gid in sorted(set(gates) | set(M.gates)):
            n = GT.gate_floor_count(prj.custom, gid, EN._repo(prj)) or 0
            gname = gates.get(gid, {}).get('name', f'Gate {gid}')
            gv = M.gates.get(gid)
            plans = [(None, None, gv['default'] if gv else None)]
            if gv:
                plans += [(k, t, p) for k, (t, p) in enumerate(gv['variants'])]
            for k, terms, plan in plans:
                runs = []
                for f in range(1, max(n, 1)):
                    num = (plan or {}).get(f, M.vanilla(gid, f))
                    if runs and runs[-1][2] == num:
                        runs[-1][1] = f
                    else:
                        runs.append([f, f, num])
                for a, b, num in runs:
                    w = when_text(terms, names) if terms else ''
                    out.setdefault(num, []).append({
                        'kind': 'gate', 'gate': gid, 'floors': (a, b), 'variant': k,
                        'when': w, 'label': f"{gname} {_label_floors(a, b)}"
                        + (f' ({w})' if w else '')})
        for r in prj.rooms:
            if r.get('placeholder'):
                continue
            enc = r.get('encounters') or {}
            if not enc.get('enabled'):
                continue
            mid = G._int(r['mapID'], 'mapID')
            rm = M.rooms.get(mid)
            rid = r.get('id')
            if rm and rm['default'] is not None:
                out.setdefault(rm['default'], []).append(
                    {'kind': 'room', 'room': rid, 'variant': None, 'when': '',
                     'label': f'room {rid}'})
                for k, (terms, num) in enumerate(rm['variants']):
                    w = when_text(terms, names)
                    out.setdefault(num, []).append(
                        {'kind': 'room', 'room': rid, 'variant': k, 'when': w,
                         'label': f'room {rid} ({w})'})
            elif not enc.get('follow_gate'):
                gid = int(G._int(enc.get('gate_id', 0), 'gate'))
                fl = int(G._int(enc.get('floor', 0), 'floor'))
                num = M.gate_list(gid, fl + 1)
                out.setdefault(num, []).append(
                    {'kind': 'room', 'room': rid, 'variant': None, 'when': '',
                     'label': f"room {rid} (as {gates.get(gid, {}).get('name', gid)} "
                              f"floor {fl + 1})"})
        return out

    def list_places(self, M=None):
        """{list number: [short text]} for the Monsters tab ("wild: …")."""
        return {n: [u['label'] for u in uses] for n, uses in self.enc_usage(M).items()}

    # ------------------------------------------------------------ lists
    def enc_lists(self, M=None):
        """Every list: [{number, kind ('game'|'project'), id, name, edited,
        uses, levels (lo, hi) | None, who (names)}]."""
        if M is None:
            M, _prj = self.enc_model()
        look = self._enemy_lookup(M)
        usage = self.enc_usage(M)
        out = []
        nums = list(range(128)) + [e['number'] for e in M.lists]
        for n in nums:
            b = M.list_bytes(n)
            lv, who = [], []
            for k in range(5):
                eid = b[10 + 2 * k] | b[11 + 2 * k] << 8
                if b[5 + k] and eid:
                    sp, level, name, _pid = look(eid)
                    if level is not None:
                        lv.append(level)
                    if name not in who:
                        who.append(name)
            if n < EN.PROJECT_BASE:
                kind, lid, name, edited = 'game', None, f'List {n}', n in M.gd.edited['pool']
            else:
                e = M.lists[n - EN.PROJECT_BASE]
                kind, lid, name, edited = 'project', e['id'], e['name'], True
            out.append({'number': n, 'kind': kind, 'id': lid, 'name': name, 'edited': edited,
                        'uses': usage.get(n, []),
                        'levels': (min(lv), max(lv)) if lv else None, 'who': who})
        return out

    def enc_list_detail(self, n, M=None):
        """One list decoded for the editor: rate, group chances (+ real %),
        five slots {eid, ref, species, level, name, chance code, real %, max,
        empty}, maze size, the average steps between battles outside gates,
        and the commonest battles (encounters.group_odds)."""
        if M is None:
            M, _prj = self.enc_model()
        b = M.list_bytes(n)
        pct = M.pct
        look = self._enemy_lookup(M)
        real_slots = EN.real_chances(b[5:10], pct)
        slots = []
        for k in range(5):
            eid = b[10 + 2 * k] | b[11 + 2 * k] << 8
            empty = eid == 0 and b[5 + k] == 0
            sp, level, name, pid = look(eid) if eid else (None, None, '—', None)
            slots.append({'slot': k, 'eid': eid, 'ref': pid if pid is not None else eid,
                          'species': sp, 'level': level, 'name': name,
                          'chance': b[5 + k], 'real': real_slots[k], 'max': b[20 + k],
                          'empty': empty})
        odds = []
        try:
            for key, p in sorted(EN.group_odds(b, pct, samples=4000).items(),
                                 key=lambda kv: -kv[1])[:8]:
                odds.append((' + '.join(look(e)[2] for e in key), p))
        except ValueError as ex:
            odds = [(f'(cannot draw: {ex})', 0.0)]
        out = {'number': n, 'rate': b[0], 'unk1': b[1], 'size': list(b[2:5]),
               'size_real': EN.real_chances(b[2:5], pct), 'slots': slots, 'maze': b[25],
               'steps': EN.steps_between(EN._repo(M.prj), b[0]), 'odds': odds,
               'kind': 'game' if n < EN.PROJECT_BASE else 'project'}
        if n >= EN.PROJECT_BASE:
            e = M.lists[n - EN.PROJECT_BASE]
            out.update({'id': e['id'], 'name': e['name']})
        return out

    def enc_list_threat_rows(self, n, M=None):
        """The rows a fight-length estimate needs (ROADMAP P3.15, the Balance
        service): [{eid, species, level, chance (real %), max}] for the slots a
        battle can draw. The encounter list's chance is the +5..+9 code (NOT the
        +20 max count; DOC_AUDIT S114 — randomizer/romdata.Pool.slot_chances() and
        simulator/sweep_ttk.py read the codes too since S131)."""
        d = self.enc_list_detail(n, M)
        return [{'eid': s['eid'], 'species': s['species'], 'level': s['level'],
                 'chance': s['real'], 'max': s['max']} for s in d['slots']
                if s['chance'] and s['eid']]

    # ------------------------------------------------------------ writing
    def _enc_write(self, mutate):
        data = copy.deepcopy(self.data)
        mutate(data)
        self._commit_data(data)

    def set_enc_list(self, n, fields):
        """Change list n: fields ⊂ rate, unk1, size_chance, slot_chance, eids,
        max_count, maze_size (+ name for a project list). A game list stores
        only its differences in gamedata.encounters.<n>."""
        n = int(n)
        bad = set(fields) - set(G.LIST_KEYS) - {'name'}
        if bad:
            raise ValueError(f'unknown list fields {sorted(bad)}')

        def mut(data):
            if n < EN.PROJECT_BASE:
                if 'name' in fields:
                    raise ValueError("the game's lists have numbers, not names")
                vr = G._rows(G.vanilla(EN._repo(self._project(data))), 'encounter_pools')[n]
                van = {'rate': vr[0], 'unk1': vr[1], 'size_chance': list(vr[2:5]),
                       'slot_chance': list(vr[5:10]),
                       'eids': [vr[10 + 2 * k] | vr[11 + 2 * k] << 8 for k in range(5)],
                       'max_count': list(vr[20:25]), 'maze_size': vr[25]}
                gd = data.setdefault('gamedata', {})
                enc = gd.setdefault('encounters', {})
                cur = dict(enc.get(str(n)) or {})
                for k, v in fields.items():
                    if v == van[k]:
                        cur.pop(k, None)
                    else:
                        cur[k] = v
                if [k for k in cur if not str(k).startswith('_')]:
                    enc[str(n)] = cur
                else:
                    enc.pop(str(n), None)
                if not enc:
                    gd.pop('encounters', None)
                if not gd:
                    data.pop('gamedata', None)
            else:
                lst = data['custom']['encounter_lists']
                e = lst[n - EN.PROJECT_BASE]
                e.update(fields)
        self._enc_write(mut)

    def new_enc_list(self, copy_from=None, name=None):
        """A new project list (number 128 + its place), a copy of list
        `copy_from` (any number) or one Slime alone. -> (id, number)."""
        M, _p = self.enc_model()
        if len(M.lists) >= EN.MAX_PROJECT_LISTS:
            raise ValueError(f'at most {EN.MAX_PROJECT_LISTS} lists of your own')
        base = name or 'list'
        lid = self._slug(base) or 'list'
        ids = {e['id'] for e in M.lists}
        k, cand = 2, lid
        while cand in ids:
            cand = f'{lid}_{k}'
            k += 1
        entry = {'id': cand, 'name': name or cand}
        if copy_from is not None:
            b = M.list_bytes(int(copy_from))
            look = self._enemy_lookup(M)
            eids = []
            for j in range(5):
                eid = b[10 + 2 * j] | b[11 + 2 * j] << 8
                pid = look(eid)[3] if eid else None
                eids.append(pid if pid is not None else eid)
            entry.update({'rate': b[0], 'unk1': b[1], 'size_chance': list(b[2:5]),
                          'slot_chance': list(b[5:10]), 'eids': eids,
                          'max_count': list(b[20:25]), 'maze_size': b[25]})
        else:
            entry.update({'rate': 3, 'size_chance': [7, 0, 0],
                          'slot_chance': [7, 0, 0, 0, 0], 'eids': [2, 0, 0, 0, 0],
                          'max_count': [1, 0, 0, 0, 0]})

        def mut(data):
            data.setdefault('custom', {}).setdefault('encounter_lists', []).append(entry)
        self._enc_write(mut)
        return cand, EN.PROJECT_BASE + len(M.lists)

    def list_refs(self, lid):
        """Where project list `lid` (id) is named — by id or by number."""
        M, prj = self.enc_model()
        num = M.by_id[lid]['number']
        return [u['label'] for u in self.enc_usage(M, prj).get(num, [])]

    def delete_enc_list(self, lid):
        """Remove a project list. Refused while anything uses it; the lists
        after it move down one number (references by id follow; by number are
        refused)."""
        refs = self.list_refs(lid)
        if refs:
            raise ValueError(f'list {lid!r} is still used by: ' + '; '.join(refs))
        M, _p = self.enc_model()
        num = M.by_id[lid]['number']
        later = [e['number'] for e in M.lists if e['number'] > num]
        import json as _json
        txt = _json.dumps({'r': [r.get('encounters') for r in self.data.get('custom', {}).get('rooms', [])],
                           'g': [g.get('encounters') for g in self.data.get('custom', {}).get('gates', [])]})
        for n2 in later:
            if f'"list": {n2}' in txt:
                raise ValueError(f'list {n2} is named by its NUMBER somewhere — deleting '
                                 f'{lid!r} would renumber it; name it by its id first')

        def mut(data):
            lst = data['custom']['encounter_lists']
            data['custom']['encounter_lists'] = [e for e in lst if e.get('id') != lid]
            if not data['custom']['encounter_lists']:
                data['custom'].pop('encounter_lists')
        self._enc_write(mut)

    def list_ref_value(self, n):
        """How a setter stores list n: a project list by its id, a game list by number."""
        M, _p = self.enc_model()
        if n >= EN.PROJECT_BASE:
            return M.lists[n - EN.PROJECT_BASE]['id']
        return int(n)

    # ------------------------------------------------------------ rooms
    def room_battles(self, room_id):
        """{'mode': off|gate|follow|own, gate_id, floor, list, rate, variants
        [{when, list}]} of a custom room."""
        r = self.room(room_id)
        enc = (r or {}).get('encounters') or {}
        if not enc.get('enabled'):
            mode = 'off'
        elif enc.get('list') is not None:
            mode = 'own'
        elif enc.get('follow_gate'):
            mode = 'follow'
        else:
            mode = 'gate'
        return {'mode': mode, 'gate_id': enc.get('gate_id', 0), 'floor': enc.get('floor', 1),
                'list': enc.get('list'), 'rate': enc.get('rate'),
                'variants': copy.deepcopy(enc.get('variants') or [])}

    def set_room_battles(self, room_id, mode, gate_id=None, floor=None, list_ref=None,
                         rate=None, variants=None):
        """mode: 'off' | 'gate' (a gate + floor's list: wGateID / wCurrentFloor are
        pinned at each step, the S42 way) | 'follow' (inside a dive: the dive's
        own list) | 'own' (its own list + flag variants; never pins a gate).
        rate: None = the list's own, else a code 0-7. `floor` for 'gate' is the
        stored byte (wCurrentFloor; the game's floor number - 1)."""
        def mut(data):
            r = next(x for x in data['custom']['rooms'] if x.get('id') == room_id)
            old = r.get('encounters') or {}
            enc = {k: v for k, v in old.items() if k == 'comment' or str(k).startswith('_')}
            if mode == 'off':
                if enc:
                    r['encounters'] = enc
                else:
                    r.pop('encounters', None)
                return
            enc['enabled'] = True
            if mode == 'gate':
                enc['gate_id'] = int(gate_id if gate_id is not None else old.get('gate_id', 0))
                enc['floor'] = int(floor if floor is not None else old.get('floor', 1))
            elif mode == 'follow':
                enc['follow_gate'] = True
            elif mode == 'own':
                if list_ref is None:
                    raise ValueError('pick a list for the room')
                enc['list'] = list_ref
                if variants:
                    enc['variants'] = variants
            else:
                raise ValueError(mode)
            if rate is not None:
                enc['rate'] = int(rate)
            r['encounters'] = enc
        self._enc_write(mut)

    # ------------------------------------------------------------ gates
    def gate_plan_view(self, gid, variant=None, M=None, prj=None):
        """Per floor (1 .. floor count - 1): {floor, list, source ('game' |
        'plan' | 'variant'), vanilla}. variant = None (the default plan) or k."""
        if M is None:
            M, prj = self.enc_model()
        prj = prj or M.prj
        from editor2.core import gates as GT
        n = GT.gate_floor_count(prj.custom, gid, EN._repo(prj)) or 0
        gv = M.gates.get(gid)
        own = {}
        for run in (self._gate_enc(gid).get('floors') or []):
            a, b = GT.floor_range(run.get('floors', 'all'), n, 1)
            for f in range(a, b + 1):
                own[f] = M.ref(run.get('list'), 'run')
        var_own = {}
        if variant is not None:
            vs = self._gate_enc(gid).get('variants') or []
            for run in (vs[variant].get('floors') or []):
                a, b = GT.floor_range(run.get('floors', 'all'), n, 1)
                for f in range(a, b + 1):
                    var_own[f] = M.ref(run.get('list'), 'run')
        rows = []
        for f in range(1, max(n, 1)):
            van = M.vanilla(gid, f)
            if f in var_own:
                num, src = var_own[f], 'variant'
            elif f in own:
                num, src = own[f], 'plan'
            else:
                num, src = van, 'game'
            rows.append({'floor': f, 'list': num, 'source': src, 'vanilla': van})
        return rows

    def _gate_enc(self, gid):
        for g in self.custom.get('gates') or []:
            if int(G._int(g.get('gate', -1), 'gate')) == int(gid):
                return g.get('encounters') or {}
        return {}

    def gate_variants(self, gid):
        return copy.deepcopy(self._gate_enc(gid).get('variants') or [])

    @staticmethod
    def _runs_from_floors(floor_lists):
        """{floor: list ref} -> [{"floors": [a, b], "list": ref}] (merged runs)."""
        runs = []
        for f in sorted(floor_lists):
            ref = floor_lists[f]
            if runs and runs[-1]['list'] == ref and runs[-1]['floors'][1] == f - 1:
                runs[-1]['floors'][1] = f
            else:
                runs.append({'floors': [f, f], 'list': ref})
        for r in runs:
            if r['floors'][0] == r['floors'][1]:
                r['floors'] = r['floors'][0]
        return runs

    def set_gate_floor_list(self, gid, floor, list_ref, variant=None):
        """Give floor `floor` (the game's numbering) of gate `gid` the list
        `list_ref` (None = back to the game's rule; in a variant: back to the
        gate's own plan)."""
        gid, floor = int(gid), int(floor)
        from editor2.core import gates as GT

        def mut(data):
            prj = self._project(data)
            n = GT.gate_floor_count(prj.custom, gid, EN._repo(prj)) or 0
            gates = data.setdefault('custom', {}).setdefault('gates', [])
            g = next((x for x in gates if int(G._int(x.get('gate', -1), 'gate')) == gid), None)
            if g is None:
                g = {'gate': gid}
                gates.append(g)
            enc = g.setdefault('encounters', {})
            if variant is None:
                runs = enc.get('floors') or []
            else:
                runs = enc['variants'][variant].get('floors') or []
            cur = {}
            for run in runs:
                a, b = GT.floor_range(run.get('floors', 'all'), n, 1)
                for f in range(a, b + 1):
                    cur[f] = run.get('list')
            if list_ref is None:
                cur.pop(floor, None)
            else:
                cur[floor] = list_ref
            new_runs = self._runs_from_floors(cur)
            if variant is None:
                if new_runs:
                    enc['floors'] = new_runs
                else:
                    enc.pop('floors', None)
            else:
                enc['variants'][variant]['floors'] = new_runs
            self._prune_gate(data, gid)
        self._enc_write(mut)

    def set_gate_variants(self, gid, variants):
        """Replace gate `gid`'s variants: [{"when": [...], "floors": [...]}]."""
        gid = int(gid)

        def mut(data):
            gates = data.setdefault('custom', {}).setdefault('gates', [])
            g = next((x for x in gates if int(G._int(x.get('gate', -1), 'gate')) == gid), None)
            if g is None:
                g = {'gate': gid}
                gates.append(g)
            enc = g.setdefault('encounters', {})
            if variants:
                enc['variants'] = variants
            else:
                enc.pop('variants', None)
            self._prune_gate(data, gid)
        self._enc_write(mut)

    def reset_gate_plan(self, gid):
        """The gate goes back to the game's rule (its plan and variants removed)."""
        gid = int(gid)

        def mut(data):
            for g in data.get('custom', {}).get('gates') or []:
                if int(G._int(g.get('gate', -1), 'gate')) == gid:
                    g.pop('encounters', None)
            self._prune_gate(data, gid)
        self._enc_write(mut)

    @staticmethod
    def _prune_gate(data, gid):
        gates = data.get('custom', {}).get('gates')
        if gates is None:
            return
        for g in list(gates):
            if int(G._int(g.get('gate', -1), 'gate')) != gid:
                continue
            enc = g.get('encounters')
            if enc is not None and not [k for k in enc if not str(k).startswith('_')]:
                g.pop('encounters')
            if not [k for k in g if k != 'gate' and not str(k).startswith('_')]:
                gates.remove(g)
        if not gates:
            data['custom'].pop('gates')
