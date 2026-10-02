"""skills_doc.py — the Skills tab's document model (ROADMAP P3.11, S110;
P3.11c/d, S111; EDITOR_DESIGN §5.3; compiler: editor2/core/gamedata.py `skills`
(mp / learn / record) + editor2/core/skills.py (name / description /
looks_like / sounds_like) + editor2/core/custom_skills.py (the custom skills
222-254 and every skill's element), PROJECT_COMPILER §2.26 / §2.27).

Reads and writes `gamedata.skills.<id>`: the 222 stock skills, the ten
built-in custom skills (224-233) and the project's NEW skills (234-254). The
project stores only differences: a field set back to its original value (for
a new skill: the value its base skill gives it) removes its key, and the
skill's object when it empties (a new skill keeps `base` + `name`). Every
setter validates with the compiler's own models before it is kept
(MonstersMixin._commit_data).
"""

import copy
import json
import os

from editor2.core import gamedata as G
from editor2.core import monster_text as MT
from editor2.core import skills as SK
from editor2.core import custom_skills as CS

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
STATS = G.STATS
RECORD = {n: (off, size) for n, off, size in G.RECORD_FIELDS}

_BATTLE_MSG = {}


def battle_messages():
    """{message id: text} of the bank $4C battle messages (dialogue.json)."""
    if not _BATTLE_MSG:
        try:
            d = json.load(open(os.path.join(REPO, 'extracted', 'dialogue.json')))
            for e in d['table_entries']:
                if e.get('source') == 'battle_message':
                    _BATTLE_MSG[e['index']] = e.get('text', '')
        except (OSError, ValueError, KeyError):
            pass
    return _BATTLE_MSG


def _u16(b, o):
    return b[o] | b[o + 1] << 8


def decode_record(r):
    """19 bytes -> the named fields (+ the derived ones the tab shows)."""
    out = {}
    for n, (off, size) in RECORD.items():
        out[n] = r[off] if size == 1 else _u16(r, off)
    out['ai_tag'] = r[1] >> 4
    out['flags'] = {key: bool((r[off] >> bit) & 1) for off, bit, key, _l, _h in SK.FLAG_BITS}
    return out


def decode_learn(r):
    if r is None:
        return None
    return {'level': r[0], **{s: _u16(r, 1 + 2 * i) for i, s in enumerate(STATS)},
            'prereqs': [x for x in r[13:18] if x != 0xFF]}


class SkillsMixin:
    # ------------------------------------------------------------ reading
    def skill_names_effective(self):
        """{id: name the player sees} for the 222 stock skills (renames applied)
        + the custom skills (built-in and new, S111). The one skill-name source."""
        out = SK.names(self.data, REPO)
        try:
            out.update(CS.names(self.data, REPO))
        except Exception:                                   # noqa: BLE001
            from editor2.core.monsters import CUSTOM_SKILL_NAMES
            for k, v in CUSTOM_SKILL_NAMES.items():
                out.setdefault(k, v)
        return out

    def skills_list(self, model=None):
        """[{id, name, vanilla, kind, edited}] for the stock skills 0-221, then
        the built-in custom skills (kind 'custom') and the new ones ('new')."""
        names = SK.names(self.data, REPO)
        out = []
        for sid in range(SK.N_IDS):
            out.append({'id': sid, 'name': names[sid], 'vanilla': SK.vanilla_name(sid, REPO),
                        'kind': SK.kind(sid, REPO), 'edited': self.skill_edited(sid)})
        cn = CS.names(self.data, REPO)
        base = CS.baseline()['skills']
        for sid in sorted(cn):
            new = sid in CS.NEW
            out.append({'id': sid, 'name': cn[sid],
                        'vanilla': cn[sid] if new else base[sid]['name'],
                        'kind': 'new' if new else 'custom', 'edited': self.skill_edited(sid)})
        return out

    def new_skill_ids(self):
        sk = (self.data.get('gamedata') or {}).get('skills') or {}
        return sorted(int(k) for k in sk if str(k).isdigit() and int(k) in CS.NEW)

    def clone_bases(self):
        """[(stock id, name)] a new skill may be based on (measured, S111)."""
        names = SK.names(self.data, REPO)
        return [(b, names[b]) for b, _n in CS.clone_bases(REPO)]

    def skill_edited(self, sid):
        e = ((self.data.get('gamedata') or {}).get('skills') or {}).get(str(sid)) or {}
        return any(not str(k).startswith('_') and k != 'comment' for k in e)

    def skill_detail(self, sid, model=None):
        """Everything the Skills tab shows for skill `sid` — effective values
        and the original game's next to them."""
        sid = int(sid)
        if sid >= SK.N_IDS:
            return self._custom_detail(sid, model)
        g = model or self._project().gamedata()
        van = SK.vanilla(REPO)
        rec = bytes(g.record[sid])
        vrec = bytes(van['raw'][sid])
        e = SK.effective(self.data, REPO)
        learn = decode_learn(g.learn[sid]) if sid < G.LEARN_ROWS else None
        vlearn = decode_learn(G._rows(G.vanilla(REPO), 'skill_learn')[sid]) \
            if sid < G.LEARN_ROWS else None
        meta = van['records'].get(sid) or {}
        names = SK.names(self.data, REPO)
        # who has it: natural (3 slots of the species info rows), enemy rows,
        # skills that evolve INTO it (learn prereqs) / OUT of it
        mnames = self.monster_names_effective()
        natural = [s for s in range(215) if sid in list(g.monster[s][6:9])]
        enemies = [i for i in range(len(g.enemy)) if sid in list(g.enemy[i][21:25])]
        evolves_from = learn['prereqs'] if learn else []
        evolves_to = [t for t in range(G.LEARN_ROWS)
                      if sid in decode_learn(g.learn[t])['prereqs']]
        ann = G.vanilla(REPO)['tables'].get('skill_announce', {}).get('rows')
        ann_id = int(ann[sid], 16) if ann else None
        el = self._stock_element(sid)
        return {
            'id': sid, 'kind': meta.get('kind', 'skill'),
            'sounds_like': e['sounds'][sid],
            'element': el, 'native_element': CS.native_element(sid, REPO),
            'element_editable': CS.native_element(sid, REPO) is not None,
            'name': names[sid], 'vanilla_name': SK.vanilla_name(sid, REPO),
            'description': MT.desc_lines(e['descs'][sid]) if e['descs'][sid] else [],
            'vanilla_description': MT.desc_lines(van['descs'][sid]) if van['descs'][sid] else [],
            'shares_empty': van['desc_shared'].get(sid),
            'mp': _u16(g.mp[sid], 0), 'vanilla_mp': van['mp'][sid],
            'battle_mp': rec[4], 'vanilla_battle_mp': vrec[4],
            'learn': learn, 'vanilla_learn': vlearn,
            'record': decode_record(rec), 'vanilla_record': decode_record(vrec),
            'looks_like': e['looks'][sid],
            'handler_shared_with': meta.get('handler_shared_with') or [],
            'natural': [(s, mnames.get(s, f'#{s}')) for s in natural],
            'enemies': enemies,
            'evolves_from': [(t, names.get(t, f'#{t}')) for t in evolves_from],
            'evolves_to': [(t, names.get(t, f'#{t}')) for t in evolves_to],
            'announce': (ann_id, battle_messages().get(ann_id, '') if ann_id is not None
                         and ann_id != 0xFF else ''),
            'edited': self.skill_edited(sid),
        }

    def _stock_element(self, sid):
        e = ((self.data.get('gamedata') or {}).get('skills') or {}).get(str(sid)) or {}
        if e.get('element') is None:
            return None
        return CS.element_value(e['element'], 'element')

    def _custom_effective(self, data, sid):
        sk, ex, _w = CS.resolve(data, REPO)
        return sk.get(sid), ex

    def _custom_default(self, sid):
        """The skill with no project edit (built-in: custom_skills.json; new:
        what its base gives it)."""
        e = ((self.data.get('gamedata') or {}).get('skills') or {}).get(str(sid)) or {}
        keep = {k: e[k] for k in ('base', 'name') if k in e} if sid in CS.NEW else {}
        d = {'gamedata': {'skills': {str(sid): keep}} if keep else {}}
        return self._custom_effective(d, sid)

    def _custom_detail(self, sid, model=None):
        g = model or self._project().gamedata()
        v, ex = self._custom_effective(self.data, sid)
        if v is None:
            raise KeyError(f'no custom skill {sid}')
        o, oex = self._custom_default(sid)
        names = self.skill_names_effective()
        mnames = self.monster_names_effective()
        e = ((self.data.get('gamedata') or {}).get('skills') or {}).get(str(sid)) or {}
        natural = [s for s in range(215) if sid in list(g.monster[s][6:9])]
        enemies = [i for i in range(len(g.enemy)) if sid in list(g.enemy[i][21:25])]
        learn = decode_learn(v['learn']) if v['learn'] and v['learn'][0] != 0xFF else None
        vlearn = decode_learn(o['learn']) if o['learn'] and o['learn'][0] != 0xFF else None
        sk_all, _x, _w = CS.resolve(self.data, REPO)
        evolves_to = [t for t, w in sk_all.items() if w['learn'] and w['learn'][0] != 0xFF
                      and sid in w['learn'][13:18]]
        for t in range(G.LEARN_ROWS):
            if sid in decode_learn(g.learn[t])['prereqs']:
                evolves_to.append(t)
        handler = v['handler']
        params = {}
        if handler == 'tame':
            params['tame_meter'] = (ex['tame'][sid], oex['tame'][sid])
        if handler == 'quake':
            params['quake_power'] = (ex['quake'][sid], oex['quake'][sid])
        for key, (owner, banner, _ed) in CS.LINE_KEYS.items():
            if owner == sid:
                params[key] = (CS.decode_line(ex['banners'][banner]),
                               CS.decode_line(oex['banners'][banner]))
        for key, (owners, off, dflt, most, what) in CS.RATIO_KEYS.items():   # [S111]
            if sid in owners:
                o_ = off + 2 * owners.index(sid)
                params['ratio:' + key] = (ex['ratios'][o_], dflt, most, what)
        if handler == 'anchor':
            base_d = {d['id']: d['lines'] for d in json.load(open(os.path.join(
                REPO, 'editor2', 'core', 'skill_scripts.json')))['dialogue']}
            params['dialogs'] = {k: (ex['dialogs'].get(i, base_d[i]), base_d[i])
                                 for k, i in CS.DIALOG_IDS.items()}
        tpl = v['template']
        msgs = battle_messages()
        return {
            'id': sid, 'kind': 'new' if sid in CS.NEW else 'custom', 'handler': handler,
            'handler_label': CS.HANDLER_LABEL.get(handler, ''),
            'base': v['base'], 'base_name': names.get(v['base'], '') if v['base'] is not None else '',
            'name': MT.decode(v['name']), 'vanilla_name': MT.decode(o['name']),
            'description': MT.desc_lines(v['desc']) if v['desc'] else [],
            'vanilla_description': MT.desc_lines(o['desc']) if o['desc'] else [],
            'shares_empty': None,
            'mp': v['mp'], 'vanilla_mp': o['mp'], 'battle_mp': v['record'][4],
            'vanilla_battle_mp': o['record'][4],
            'mp_code': handler in ('magicburn', 'anchor'),
            'learn': learn, 'vanilla_learn': vlearn, 'learnable': learn is not None,
            'record': decode_record(v['record']), 'vanilla_record': decode_record(o['record']),
            'looks_like': v['proxy'], 'vanilla_looks': o['proxy'],
            'sounds_like': v['sfx'], 'vanilla_sounds': o['sfx'],
            'element': None if v['element'] == CS.NO_ELEMENT else v['element'],
            'vanilla_element': None if o['element'] == CS.NO_ELEMENT else o['element'],
            'native_element': CS.native_element(v['base'], REPO) if v['base'] is not None else None,
            'element_editable': (handler in CS.DAMAGE_HANDLERS or
                                 (v['base'] is not None and
                                  CS.native_element(v['base'], REPO) is not None)),
            'announce_template': tpl, 'vanilla_announce_template': o['template'],
            'announce_lines': CS.decode_line(v['message']) if v['message'] else None,
            'announce_text': msgs.get(tpl, '') if tpl not in (0xFD, 0xFF) else '',
            'params': params,
            'handler_shared_with': [],
            'natural': [(s, mnames.get(s, f'#{s}')) for s in natural],
            'enemies': enemies,
            'evolves_from': [(t, names.get(t, f'#{t}')) for t in (learn or {}).get('prereqs', [])],
            'evolves_to': [(t, names.get(t, f'#{t}')) for t in sorted(set(evolves_to))],
            'announce': (tpl, ''),
            'edited': self.skill_edited(sid),
            'raw_edit': e,
        }

    def announce_choices(self):
        """[(message id, readable text)] — stock battle lines a custom skill can
        be announced with (the 'casts / spits / ... {skill}!' family)."""
        rows = G.vanilla(REPO)['tables']['skill_announce']['rows']
        used = sorted({int(r, 16) for r in rows} - {0xFF, 0xFD})
        msgs = battle_messages()
        return [(i, msgs.get(i, '')) for i in used if '[INS 10]' in msgs.get(i, '')]

    def skill_lend_options(self, sid):
        """[(donor id, name, problem or None, warning or None)] for the
        looks-like picker (problem = refused, warning = allowed, shown)."""
        names = SK.names(self.data, REPO)
        if sid >= SK.N_IDS:
            return [(d, names[d], None, None) for d in range(SK.N_IDS)]
        return [(d, names[d], SK.lend_problem(self.data, sid, d, REPO),
                 SK.lend_warning(self.data, sid, d, REPO)) for d in range(SK.N_IDS)]

    # ------------------------------------------------------------ writing
    def _skill_write(self, sid, mutate):
        data = copy.deepcopy(self.data)
        gd = data.setdefault('gamedata', {})
        sk = gd.setdefault('skills', {})
        e = sk.setdefault(str(int(sid)), {})
        mutate(e)
        for k in ('record', 'learn'):
            if k in e and e[k] == {}:
                e.pop(k)
        if int(sid) in CS.NEW:
            pass                         # a new skill always keeps base + name
        elif not [k for k in e if not str(k).startswith('_') and k != 'comment']:
            # nothing but a comment / private keys left: drop the object
            sk.pop(str(int(sid)))
        if not sk:
            gd.pop('skills')
        if not gd:
            data.pop('gamedata')
        self._commit_data(data)

    def _orig(self, sid):
        """(custom default dict, extras) for a custom id."""
        return self._custom_default(int(sid))

    def set_skill_name(self, sid, name):
        if sid >= SK.N_IDS:
            o, _x = self._orig(sid)
            van = MT.decode(o['name']) if sid in CS.BUILTIN else None
        else:
            van = SK.vanilla_name(sid, REPO)

        def mut(e):
            if name is None or name == van:
                e.pop('name', None)
            else:
                e['name'] = name
        self._skill_write(sid, mut)

    def set_skill_description(self, sid, lines):
        """lines: [str] (1-3), [] = no text, None = the original."""
        if sid >= SK.N_IDS:
            o, _x = self._orig(sid)
            van = o['desc'] or b''
        else:
            van = SK.vanilla(REPO)['descs'][sid]

        def mut(e):
            if lines is None:
                e.pop('description', None)
                return
            clean = [x for x in lines]
            while clean and not clean[-1].strip():
                clean.pop()
            b = MT.encode_desc(clean, f'skill {sid} description') if clean else b''
            if b == van:
                e.pop('description', None)
            else:
                e['description'] = clean
        self._skill_write(sid, mut)

    def set_skill_mp(self, sid, mp):
        """mp: 0-255, 'ALL' (only Farewell / MegaMagic) or None = original."""
        if sid >= SK.N_IDS:
            o, _x = self._orig(sid)
            van = o['mp']
        else:
            van = SK.vanilla(REPO)['mp'][sid]

        def mut(e):
            v = G._mp_value(mp, 'mp') if mp is not None else van
            if v == van:
                e.pop('mp', None)
            else:
                e['mp'] = 'ALL' if v == G.ALL_MP else v
        self._skill_write(sid, mut)

    def set_skill_learn(self, sid, changes):
        """changes: {level, hp … int, prereqs} (None value = original);
        custom skills also {'learnable': bool}."""
        if sid >= SK.N_IDS:
            return self._set_custom_learn(sid, changes)
        if sid >= G.LEARN_ROWS:
            raise G.GamedataError(f"skill {sid} has no learn row (ids $DA-$DD)")
        vl = decode_learn(G._rows(G.vanilla(REPO), 'skill_learn')[sid])

        def mut(e):
            L = dict(e.get('learn') or {})
            for k, v in changes.items():
                if v is None or v == vl[k]:
                    L.pop(k, None)
                else:
                    L[k] = v
            if L:
                e['learn'] = L
            else:
                e.pop('learn', None)
        self._skill_write(sid, mut)

    def _set_custom_learn(self, sid, changes):
        o, _x = self._orig(sid)
        vl = decode_learn(o['learn']) if o['learn'] and o['learn'][0] != 0xFF else None
        v, _x = self._custom_effective(self.data, sid)
        cur = decode_learn(v['learn']) if v['learn'] and v['learn'][0] != 0xFF else None

        def mut(e):
            if changes.get('learnable') is False:
                if vl is None:
                    e.pop('learn', None)
                else:
                    e['learn'] = None
                return
            L = dict(cur or {'level': 1, **{s_: 0 for s_ in STATS}, 'prereqs': []})
            for k, val in changes.items():
                if k == 'learnable':
                    continue
                L[k] = val if val is not None else (vl or {}).get(k, L.get(k))
            if vl is not None and L == vl:
                e.pop('learn', None)
            else:
                e['learn'] = L
        self._skill_write(sid, mut)

    def set_skill_record(self, sid, changes):
        """changes: {record field: value | None (= original)}; also the
        derived keys 'ai_tag' (high half of category) and 'flag.<key>'
        (one bit)."""
        if sid >= SK.N_IDS:
            o, _x = self._orig(sid)
            vr = bytes(o['record'])
            v, _x = self._custom_effective(self.data, sid)
            cur = bytearray(v['record'])
        else:
            vr = bytes(SK.vanilla(REPO)['raw'][sid])
            g = self._project().gamedata()
            cur = bytearray(g.record[sid])

        def mut(e):
            R = dict(e.get('record') or {})
            r = bytearray(cur)
            for k, v in changes.items():
                if k == 'ai_tag':
                    r[1] = ((v if v is not None else vr[1] >> 4) << 4) | (r[1] & 0x0F)
                elif k.startswith('flag.'):
                    key = k[5:]
                    off, bit = next((o, b) for o, b, kk, _l, _h in SK.FLAG_BITS if kk == key)
                    want = bool(v) if v is not None else bool((vr[off] >> bit) & 1)
                    r[off] = (r[off] | (1 << bit)) if want else (r[off] & ~(1 << bit))
                else:
                    off, size = RECORD[k]
                    if v is None:
                        r[off:off + size] = vr[off:off + size]
                    elif size == 1:
                        r[off] = int(v)
                    else:
                        r[off] = int(v) & 0xFF
                        r[off + 1] = int(v) >> 8
            for n, (off, size) in RECORD.items():
                if n == 'mp_byte' and n not in R and 'mp_byte' not in changes:
                    continue          # the battle MP byte follows `mp` (S110)
                if r[off:off + size] == vr[off:off + size]:
                    R.pop(n, None)
                else:
                    R[n] = r[off] if size == 1 else r[off] | r[off + 1] << 8
            if R:
                e['record'] = R
            else:
                e.pop('record', None)
        self._skill_write(sid, mut)

    def set_skill_looks(self, sid, donor):
        orig = self._orig(sid)[0]['proxy'] if sid >= SK.N_IDS else sid

        def mut(e):
            if donor is None or int(donor) == int(orig):
                e.pop('looks_like', None)
            else:
                e['looks_like'] = int(donor)
        self._skill_write(sid, mut)

    def set_skill_sounds(self, sid, donor):
        """S111: the sounds alone (default = the look's / the built-in's)."""
        if sid in CS.NEW:
            orig = self._custom_effective(self.data, sid)[0]['proxy']   # default = its look
        elif sid >= SK.N_IDS:
            orig = self._orig(sid)[0]['sfx']
        else:
            orig = SK.effective(self.data, REPO)['looks'][sid]

        def mut(e):
            if donor is None or int(donor) == int(orig):
                e.pop('sounds_like', None)
            else:
                e['sounds_like'] = int(donor)
        self._skill_write(sid, mut)

    def set_skill_element(self, sid, element):
        """element: a resistance index 0-26, 'none', or None = the original."""
        from editor2.core import gamedata as GG

        def mut(e):
            if element is None:
                e.pop('element', None)
            elif element == 'none':
                e['element'] = 'none'
            else:
                e['element'] = GG.RESIST_NAMES[int(element)]
        self._skill_write(sid, mut)

    def set_skill_announce(self, sid, lines=None, template=None):
        """A custom skill's battle announce: own `lines` (list of pages of 1-2
        lines, or 1-2 lines), a stock message id `template`, 'none' = silent,
        or both None = the original."""
        o, _x = self._orig(sid)

        def mut(e):
            e.pop('announce', None)
            e.pop('announce_as', None)
            if lines is not None:
                bs, _w = CS.encode_line(lines, 'announce', True)
                if not (o['template'] == 0xFD and o['message'] == bs):
                    e['announce'] = lines
            elif template is not None:
                t = 0xFF if template == 'none' else int(template)
                if t != o['template'] or o['template'] == 0xFD:
                    e['announce_as'] = 'none' if t == 0xFF else t
        self._skill_write(sid, mut)

    def set_skill_param(self, sid, key, value):
        """tame_meter / quake_power / allies_line / flew_line / boost_line /
        dialogs / the ratio keys (custom_skills.RATIO_KEYS) (None = the original)."""
        def mut(e):
            if value is None:
                e.pop(key, None)
            else:
                e[key] = value
        self._skill_write(sid, mut)

    def new_custom_skill(self, base, name):
        """Add a NEW custom skill (the first free id 234-254) running stock
        skill `base`'s effect. Returns its id."""
        used = set(self.new_skill_ids())
        free = [i for i in CS.NEW if i not in used]
        if not free:
            raise CS.CustomSkillError(f"all {len(CS.NEW)} new skill ids (234-254) are used")
        sid = free[0]
        data = copy.deepcopy(self.data)
        sk = data.setdefault('gamedata', {}).setdefault('skills', {})
        sk[str(sid)] = {'base': int(base), 'name': name}
        self._commit_data(data)
        return sid

    def delete_custom_skill(self, sid):
        """Remove a NEW skill (refused while a monster, enemy row or another
        skill's learn row still uses it)."""
        if sid not in CS.NEW:
            raise CS.CustomSkillError("only new skills (234-254) can be deleted")
        d = self.skill_detail(sid)
        users = []
        if d['natural']:
            users.append('natural skill of ' + ', '.join(n for _s, n in d['natural'][:3]))
        if d['enemies']:
            users.append(f"{len(d['enemies'])} enemy row(s)")
        if d['evolves_to']:
            users.append('evolves into ' + ', '.join(n for _t, n in d['evolves_to'][:3]))
        if users:
            raise CS.CustomSkillError(f"{d['name']} is still used: " + '; '.join(users))
        data = copy.deepcopy(self.data)
        sk = data['gamedata']['skills']
        sk.pop(str(sid))
        if not sk:
            data['gamedata'].pop('skills')
        if not data['gamedata']:
            data.pop('gamedata')
        self._commit_data(data)

    def reset_skill(self, sid):
        """Everything of skill `sid` back to the original game (keeps a comment;
        a new skill keeps its base and name)."""
        def mut(e):
            for k in [k for k in e if not str(k).startswith('_') and k != 'comment'
                      and not (int(sid) in CS.NEW and k in ('base', 'name'))]:
                e.pop(k)
        self._skill_write(sid, mut)
