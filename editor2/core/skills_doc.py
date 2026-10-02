"""skills_doc.py — the Skills tab's document model (ROADMAP P3.11, S110;
EDITOR_DESIGN §5.3 "As built S110"; compiler: editor2/core/gamedata.py `skills`
(mp / learn / record) + editor2/core/skills.py (name / description /
looks_like), PROJECT_COMPILER §2.26).

Reads and writes `gamedata.skills.<id>` for the 222 vanilla skills. The project
stores only differences from the original game: a field set back to its
original value removes its key (and the skill's object when it empties).
Every setter validates with the compiler's own models before it is kept
(MonstersMixin._commit_data).
"""

import copy
import json
import os

from editor2.core import gamedata as G
from editor2.core import monster_text as MT
from editor2.core import skills as SK

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
        """{id: name the player sees} for the 222 vanilla skills (renames
        applied) + the custom skills' hand names. The one skill-name source."""
        out = SK.names(self.data, REPO)
        from editor2.core.monsters import CUSTOM_SKILL_NAMES
        for k, v in CUSTOM_SKILL_NAMES.items():
            out.setdefault(k, v)
        return out

    def skills_list(self, model=None):
        """[{id, name, vanilla, kind, edited}] for ids 0-221."""
        g = model or self._project().gamedata()
        names = SK.names(self.data, REPO)
        out = []
        for sid in range(SK.N_IDS):
            out.append({'id': sid, 'name': names[sid], 'vanilla': SK.vanilla_name(sid, REPO),
                        'kind': SK.kind(sid, REPO), 'edited': self.skill_edited(sid)})
        return out

    def skill_edited(self, sid):
        e = ((self.data.get('gamedata') or {}).get('skills') or {}).get(str(sid)) or {}
        return any(not str(k).startswith('_') and k != 'comment' for k in e)

    def skill_detail(self, sid, model=None):
        """Everything the Skills tab shows for skill `sid` — effective values
        and the original game's next to them."""
        sid = int(sid)
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
        return {
            'id': sid, 'kind': meta.get('kind', 'skill'),
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

    def skill_lend_options(self, sid):
        """[(donor id, name, problem or None, warning or None)] for the
        looks-like picker (problem = refused, warning = allowed, shown)."""
        names = SK.names(self.data, REPO)
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
            if k in e and not e[k]:
                e.pop(k)
        if not [k for k in e if not str(k).startswith('_') and k != 'comment']:
            # nothing but a comment / private keys left: drop the object
            sk.pop(str(int(sid)))
        if not sk:
            gd.pop('skills')
        if not gd:
            data.pop('gamedata')
        self._commit_data(data)

    def set_skill_name(self, sid, name):
        van = SK.vanilla_name(sid, REPO)

        def mut(e):
            if name is None or name == van:
                e.pop('name', None)
            else:
                e['name'] = name
        self._skill_write(sid, mut)

    def set_skill_description(self, sid, lines):
        """lines: [str] (1-3), [] = no text, None = the original."""
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
        van = SK.vanilla(REPO)['mp'][sid]

        def mut(e):
            v = G._mp_value(mp, 'mp') if mp is not None else van
            if v == van:
                e.pop('mp', None)
            else:
                e['mp'] = 'ALL' if v == G.ALL_MP else v
        self._skill_write(sid, mut)

    def set_skill_learn(self, sid, changes):
        """changes: {level, hp … int, prereqs} (None value = original)."""
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

    def set_skill_record(self, sid, changes):
        """changes: {record field: value | None (= original)}; also the
        derived keys 'ai_tag' (high half of category) and 'flag.<key>'
        (one bit)."""
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
        def mut(e):
            if donor is None or int(donor) == int(sid):
                e.pop('looks_like', None)
            else:
                e['looks_like'] = int(donor)
        self._skill_write(sid, mut)

    def reset_skill(self, sid):
        """Everything of skill `sid` back to the original game (keeps a comment)."""
        def mut(e):
            for k in [k for k in e if not str(k).startswith('_') and k != 'comment']:
                e.pop(k)
        self._skill_write(sid, mut)
