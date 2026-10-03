"""monsters.py — the Monsters tab's document model (ROADMAP P3.10 part 1, S106;
EDITOR_DESIGN §5.2).

ONE species source for the whole editor: the 221 original species with the
project's `gamedata.monsters` edits applied, plus the project's own new species
(`custom.species`, ids 221-239). Every species list and thumbnail in the editor
goes through `species_catalog()` / `editor2/core/sprite_render.py`.

What a species IS in DWM1 (MONSTER_DATA "Monster Info Table"): family, level
cap, exp curve, female ratio, flying, metal, three natural skills, six growth
curves, 27 resistances, tier — the 43-byte info row. It has NO stats and NO AI
of its own: HP / ATK / … / exp reward / joinability / AI weights / battle skills
live on each ENEMY ROW (EnemyStatsTable, 487 rows: wild pools, bosses, arena,
the starter …) and a monster that joins takes them from the row it joined from
(the creation roll, MONSTER_DATA "Party Monster Structure"). So the tab shows
the species row AND "where you meet it": every enemy row of that species.

Writes (all validated by the compiler's own models before they are kept):
  * original species -> `gamedata.monsters.<id>` — only the fields that differ
    from the original game (family as a name, growth / resist as dicts, skills
    as the three ids); a field set back to the original value disappears.
  * new species      -> `custom.species[k].info` — fields that differ from
    the `clone_from` row (PROJECT_COMPILER §2.21).
  * original enemy rows (EID 0-486) -> `gamedata.enemies.<eid>` (sparse, same rule).
  * project enemies  -> `progression.enemies[]` (EnemiesMixin.update_enemy).
"""

import copy
import json
import os
import re

from editor2.core import gamedata as G
from editor2.core import species as SP

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

FEMALE_LABELS = ['never (0 %)', 'rarely (≈ 10 %)', 'half (50 %)', 'mostly (≈ 84 %)']
# resistance LEVEL 0-3 = how much of the effect gets through (BATTLE_SKILL_SYSTEM
# §15 ladders, simulator-validated S78): spells 1.0 / 0.85 / 0.5 / 0, breaths
# 1.0 / 0.75 / 0.4 / 0, status hit chance always / 85 % / 50 % / never.
# (S106: MONSTER_DATA's old "0 = weak, 2 = normal" wording was wrong.)
RESIST_LABELS = ['none (full effect)', 'some (−15 %)', 'strong (−50 %)', 'immune']
STAT_LABELS = {'hp': 'HP', 'mp': 'MP', 'atk': 'ATK', 'def': 'DEF', 'agl': 'AGL', 'int': 'INT'}
JOIN_LABELS = {0: 'always joins (story / boss)', 7: 'never joins'}
TIER_MAX = 7
# the custom skills of the hand overlay (BATTLE_SKILL_SYSTEM §13-14): ids past the
# 222 vanilla records; a species may learn them naturally (natural-learn proven)
# the built-in custom skills' ORIGINAL names (a fallback only — the project's names
# come from SkillsMixin.skill_names_effective / custom_skills.names; S111: the retired
# $DE Scorch / $DF Smite are no longer offered)
CUSTOM_SKILL_NAMES = {0xE0: 'MagicBurn', 0xE1: 'Tame',
                      0xE2: 'TameMore', 0xE3: 'TameMost', 0xE4: 'Anchor', 0xE5: 'Tremor',
                      0xE6: 'Quake', 0xE7: 'QuakeMore', 0xE8: 'QuakeMost', 0xE9: 'Mourn'}


def decode_info(row):
    """43-byte MonsterInfoTable row -> named fields (gamedata.monsters names)."""
    return {
        'family': row[0], 'level_cap': row[1], 'exp_table': row[2],
        'female_ratio': row[3], 'can_fly': row[4], 'metal_body': row[5],
        'skills': list(row[6:9]),
        'growth': {s: row[9 + i] for i, s in enumerate(G.STATS)},
        'resist': {n: row[15 + i] for i, n in enumerate(G.RESIST_NAMES)},
        'tier': row[42],
    }


def info_diff(row, base):
    """The sparse gamedata.monsters-style dict turning `base` into `row`."""
    a, b = decode_info(row), decode_info(base)
    out = {}
    for k in ('family', 'level_cap', 'exp_table', 'female_ratio', 'can_fly',
              'metal_body', 'tier'):
        if a[k] != b[k]:
            out[k] = G.FAMILY_NAMES[a[k]] if k == 'family' else a[k]
    if a['skills'] != b['skills']:
        out['skills'] = a['skills']
    g = {s: a['growth'][s] for s in G.STATS if a['growth'][s] != b['growth'][s]}
    if g:
        out['growth'] = g
    r = {n: a['resist'][n] for n in G.RESIST_NAMES if a['resist'][n] != b['resist'][n]}
    if r:
        out['resist'] = r
    return out


def _keep_spelling(diff, old):
    """An unchanged family keeps the project's own spelling (10 / "Spirit")."""
    if 'family' in diff and 'family' in old:
        try:
            if G.family_index(old['family'], 'family') == G.family_index(diff['family'], 'family'):
                diff = dict(diff, family=old['family'])
        except G.GamedataError:
            pass
    return diff


def decode_enemy(row):
    """25-byte EnemyStatsTable row -> named fields (gamedata.enemies names)."""
    u16 = lambda o: row[o] | row[o + 1] << 8                 # noqa: E731
    d = {'species': row[0], 'exp': u16(1), 'joinability': row[3], 'level': row[4]}
    for i, s in enumerate(G.STATS):
        d[s] = u16(5 + 2 * i)
    d['ai_weights'] = list(row[17:21])
    d['skills'] = [x for x in row[21:25] if x != 0xFF]
    return d


ENEMY_KEYS = ('species', 'exp', 'joinability', 'level') + G.STATS + ('ai_weights', 'skills')


def enemy_diff(fields, base_row):
    b = decode_enemy(base_row)
    return {k: fields[k] for k in ENEMY_KEYS if k in fields and fields[k] != b[k]}


# ---------------------------------------------------------------------------
# where an enemy row is met (vanilla references, from the decoded data files)
# ---------------------------------------------------------------------------

_WHERE = {}


def _vanilla_where():
    """{eid: [text]} for the references that are NOT editable tables:
    gate bosses + their join rows, the arena / coliseum / mimic / random
    battles, script battles (extracted/boss_table.json, arena_brackets.json —
    both ROM-derived) and the starter (EID 1, MONSTER_DATA)."""
    if 'v' in _WHERE:
        return _WHERE['v']
    out = {}

    def add(eid, text):
        out.setdefault(int(eid), [])
        if text not in out[int(eid)]:
            out[int(eid)].append(text)
    add(1, 'the starter monster (the first monster you get)')
    try:
        for b in json.load(open(os.path.join(REPO, 'extracted', 'boss_table.json'))):
            add(b['fight_eid'], f"boss of {b['gate_name']}")
            add(b['join_eid'], f"joins after the {b['gate_name']} boss (join version)")
    except (OSError, ValueError, KeyError):
        pass
    try:
        ab = json.load(open(os.path.join(REPO, 'extracted', 'arena_brackets.json')))
        for g in ab['arena']['groups']:
            for m in g['matches']:
                for e in m['eids']:
                    add(e, f"arena class {g['class']}, match {m['match'] + 1}")
        for t in ab.get('gate_boss_triggers', []):
            add(t['eid'], f"script battle ({t['script']})")
        for e in ab.get('mimic_battles', {}).get('eids', []):
            add(e, 'mimic battle (arena progress)')
        rs = ab.get('random_scaled_battles', {})
        for tier, base in enumerate(rs.get('base_eids', [])):
            for k in range(16):
                add(base + k, f'random battle tier {tier} (script op $52)')
        for band in ab.get('coliseum', {}).get('level_bands', []):
            base = band.get('base_eid')
            rng = band.get('range') or band.get('rand_range') or 0
            if isinstance(base, int):
                for k in range(max(1, int(rng))):
                    add(base + k, 'coliseum (random party)')
        for r in ab.get('boss_redirect_table', []):
            if r['fight_eid'] not in out:
                add(r['fight_eid'], f"story fight ({r.get('fight', '')})")
            add(r['join_eid'], 'join version of a story fight')
    except (OSError, ValueError, KeyError):
        pass
    _WHERE['v'] = out
    return out


def _pool_places():
    """{pool index: [gate name + floors]} from extracted/encounters.json."""
    if 'pools' in _WHERE:
        return _WHERE['pools']
    out = {}
    try:
        d = json.load(open(os.path.join(REPO, 'extracted', 'encounters.json')))
        for _g, gate in d.items():
            if not isinstance(gate, dict):
                continue
            for fg in gate.get('floor_groups', []):
                out.setdefault(fg['pool_index'], []).append(
                    f"{gate['name']} ({fg['floor_range'].lower()})")
    except (OSError, ValueError, KeyError):
        pass
    _WHERE['pools'] = out
    return out


class MonstersMixin:
    # ------------------------------------------------------------ models
    def _project(self, data=None):
        from editor2.core.project import Project
        return Project(copy.deepcopy(data if data is not None else self.data),
                       self.project_dir)

    def monsters_model(self):
        """(gamedata model, resolved new species list) of the current data."""
        prj = self._project()
        return prj.gamedata(), SP.resolve(prj, with_art=False)

    # ------------------------------------------------------------ species
    def species_catalog(self):
        """[{id, name, kind, family}] — 'monster' (0-214), 'combat' (215-220:
        TERRY? and the summons, never in the library), 'new' (custom.species).
        Families are the project's (gamedata edits applied)."""
        g, new = self.monsters_model()
        names = self.monster_names_effective()
        out = []
        for sid in range(221):
            out.append({'id': sid, 'name': names.get(sid, f'#{sid}'),
                        'kind': 'combat' if sid in G.PROTECTED_SPECIES else 'monster',
                        'family': g.monster[sid][0]})
        for s in new:
            out.append({'id': s['id'], 'name': s['name'], 'kind': 'new',
                        'family': s['info'][0]})
        return out

    def species_row(self, sid, model=None):
        g, new = model or self.monsters_model()
        if sid <= 220:
            return bytes(g.monster[sid])
        for s in new:
            if s['id'] == sid:
                return s['info']
        raise KeyError(sid)

    def species_base_row(self, sid):
        """The row edits are measured against: the original game's (0-220) or
        the clone_from row (new species)."""
        rows = G._rows(G.vanilla(REPO), 'monster_info')
        if sid <= 220:
            return bytes(rows[sid])
        s = self.new_species(sid)
        return bytes(rows[int((s.get('info') or {}).get('clone_from', 0))])

    def new_species(self, sid):
        for s in (self.data.get('custom') or {}).get('species') or []:
            if isinstance(s, dict) and s.get('id') == sid:
                return s
        raise KeyError(sid)

    def set_species_fields(self, sid, changes):
        """Apply {field: value} to species `sid` (fields: family, level_cap,
        exp_table, female_ratio, can_fly, metal_body, tier, skills (3 ids),
        growth.<stat>, resist.<name>) and store only the difference from the
        base row. Validated by the compiler's models (raises on bad data)."""
        sid = int(sid)
        row = bytearray(self.species_row(sid))
        fields = {}
        for k, v in changes.items():
            if k.startswith('growth.'):
                fields.setdefault('growth', {})[k[7:]] = v
            elif k.startswith('resist.'):
                fields.setdefault('resist', {})[k[7:]] = v
            else:
                fields[k] = v
        G.apply_monster_fields(row, fields, f'species {sid}')
        base = self.species_base_row(sid)
        diff = info_diff(bytes(row), base)
        data = copy.deepcopy(self.data)
        if sid <= 220:
            gd = data.setdefault('gamedata', {})
            mons = gd.setdefault('monsters', {})
            old = mons.get(str(sid)) or {}
            keep = {k: v for k, v in old.items() if str(k).startswith('_')}
            diff = _keep_spelling(diff, old)
            if diff or keep:
                mons[str(sid)] = dict(keep, **diff)
            else:
                mons.pop(str(sid), None)
            if not mons:
                gd.pop('monsters', None)
        else:
            for s in data['custom']['species']:
                if s.get('id') == sid:
                    info = s.setdefault('info', {})
                    cf = info.get('clone_from', 0)
                    keep = {k: v for k, v in info.items() if str(k).startswith('_')}
                    s['info'] = dict({'clone_from': cf}, **keep, **_keep_spelling(diff, info))
        self._commit_data(data)

    def _commit_data(self, data):
        """Validate `data` with the compiler's models, then make it current."""
        prj = self._project(data)
        prj.gamedata()
        SP.resolve(prj, with_art=False)
        from editor2.core import monster_text as MT
        try:                               # S108: names / nicknames / descriptions fit
            MT.check(prj)
        except MT.MonsterTextError as ex:
            raise SP.SpeciesError(str(ex))
        from editor2.core import walk_layouts as WL
        try:                               # S107 2b: layouts copied into a bank's tail
            WL.copies(WL.needed(prj), getattr(prj, 'repo_root', None))
        except WL.LayoutError as ex:
            raise SP.SpeciesError(str(ex))
        from editor2.core import arena as AR
        try:                               # S109: arena fees / masters / sizes, and
            AR.check(prj)                  # no summon in a fighting arena team
        except AR.ArenaError as ex:
            raise SP.SpeciesError(str(ex))
        from editor2.core import skills as SK
        try:                               # S110: skill names / descriptions / looks
            SK.check(prj)
        except SK.SkillError as ex:
            raise SP.SpeciesError(str(ex))
        from editor2.core import custom_skills as CS
        try:                               # S111: custom + new skills, elements
            CS.check(prj)
        except (CS.CustomSkillError, MT.MonsterTextError) as ex:
            raise SP.SpeciesError(str(ex))
        from editor2.core import battle_anims as BA
        try:                               # S112: new animations + skill presentations
            BA.check(prj)
        except BA.AnimError as ex:
            raise SP.SpeciesError(str(ex))
        from editor2.core import encounters as EN
        try:                               # S114: lists, room battles, gate plans
            EN.check(prj)
        except EN.EncounterError as ex:
            raise SP.SpeciesError(str(ex))
        self.data.clear()
        self.data.update(data)
        self.touch()

    # ------------------------------------------------------------ curves
    def exp_curve(self, idx, model=None):
        """Cumulative exp needed for levels 2..100 (99 values) of curve idx."""
        g, _ = model or self.monsters_model()
        r = g.exp[idx]
        return [r[3 * i] | r[3 * i + 1] << 8 | r[3 * i + 2] << 16 for i in range(99)]

    def growth_curve(self, idx, model=None):
        """Per-level stat increments (99 values) of growth curve idx."""
        g, _ = model or self.monsters_model()
        return list(g.growth[idx])

    def curve_users(self, kind, idx, model=None):
        """Species ids using exp curve / growth curve `idx` (kind 'exp' |
        'growth'); growth counts a species once per stat it uses it for."""
        g, new = model or self.monsters_model()
        rows = [(sid, g.monster[sid]) for sid in range(221)] + \
               [(s['id'], s['info']) for s in new]
        out = []
        for sid, r in rows:
            if kind == 'exp':
                if r[2] == idx:
                    out.append(sid)
            else:
                out += [sid] * sum(1 for b in r[9:15] if b == idx)
        return out

    # ------------------------------------------------------------ enemy rows
    def species_enemies(self, sid, model=None):
        """Every enemy row of species `sid`: [{eid, kind ('original' |
        'project'), id (project enemy id or None), fields, edited, where}]."""
        g, _new = model or self.monsters_model()
        vrows = G._rows(G.vanilla(REPO), 'enemy_stats')
        where = self.enemy_places(g)
        out = []
        for eid, r in enumerate(g.enemy):
            if r[0] == sid:
                out.append({'eid': eid, 'kind': 'original', 'id': None,
                            'fields': decode_enemy(r),
                            'edited': bytes(r) != bytes(vrows[eid]),
                            'where': where.get(eid, [])})
        for e in self.project_enemies():
            if int(e.get('species', -1)) == sid:
                eid = self.project_eid(e)
                f = {k: e.get(k) for k in ENEMY_KEYS}
                f['skills'] = list(e.get('skills') or [])
                out.append({'eid': eid, 'kind': 'project', 'id': e.get('id'),
                            'fields': f, 'edited': True,
                            'where': where.get(eid, []) or where.get(e.get('id'), [])})
        return out

    def enemy_places(self, g=None):
        """{eid: [text]}: encounter pools (the project's effective pools), the
        vanilla bosses / arena / scripted battles, the project's own uses
        (gate boss conversations, monster NPC battles, quests)."""
        g = g or self.monsters_model()[0]
        out = {k: list(v) for k, v in _vanilla_where().items()}
        # S114: where each list is used, live (the project's floor counts, gate
        # plans, rooms, its own lists — editor2/core/encounters_doc.py)
        try:
            M, _prj = self.enc_model()
            places = self.list_places(M)
            lists = [(n, M.list_bytes(n)) for n in places]
        except Exception:                  # noqa: BLE001 — a project mid-edit
            places = _pool_places()
            lists = list(enumerate(g.pool))
        for pi, row in lists:
            for k in range(5):
                eid = row[10 + 2 * k] | row[11 + 2 * k] << 8
                if eid == 0 or row[5 + k] == 0:
                    continue
                for pl in places.get(pi, [f'encounter list {pi}']):
                    t = f'wild: {pl}'
                    lst = out.setdefault(eid, [])
                    if t not in lst:
                        lst.append(t)
        # the project's references by id (talk battles, quests)
        txt = json.dumps(self.data.get('custom') or {}) + json.dumps(
            (self.data.get('progression') or {}).get('quests') or [])
        for e in self.project_enemies():
            eid = self.project_eid(e)
            n = len(re.findall(r'"%s"' % re.escape(str(e.get('id'))), txt))
            if n:
                out.setdefault(eid, []).append(
                    f"your project ({n} reference{'s' if n > 1 else ''}: battles / quests)")
        return out

    def set_enemy_fields(self, eid, changes, project_id=None):
        """Edit an enemy row. An original row (EID 0-486) stores only its
        difference from the original game in gamedata.enemies; a project enemy
        (project_id) is edited in progression.enemies."""
        if project_id is not None:
            data_before = copy.deepcopy(self.data)
            try:
                self.update_enemy(project_id, **changes)
                self._commit_data(copy.deepcopy(self.data))
            except Exception:
                self.data.clear()
                self.data.update(data_before)
                raise
            return
        eid = int(eid)
        if not 0 <= eid <= G.VANILLA_EID_MAX:
            raise G.GamedataError(f'EID {eid} is not an original enemy row')
        g, _ = self.monsters_model()
        cur = decode_enemy(g.enemy[eid])
        cur.update(changes)
        base = G._rows(G.vanilla(REPO), 'enemy_stats')[eid]
        diff = enemy_diff(cur, base)
        data = copy.deepcopy(self.data)
        gd = data.setdefault('gamedata', {})
        ens = gd.setdefault('enemies', {})
        keep = {k: v for k, v in (ens.get(str(eid)) or {}).items() if str(k).startswith('_')}
        if diff or keep:
            ens[str(eid)] = dict(keep, **diff)
        else:
            ens.pop(str(eid), None)
        if not ens:
            gd.pop('enemies', None)
        self._commit_data(data)

    # ------------------------------------------------------------ new species
    def free_species_ids(self):
        used = {s.get('id') for s in (self.data.get('custom') or {}).get('species') or []
                if isinstance(s, dict)}
        return [i for i in SP.CAPACITY_IDS if i not in used]

    def species_capacity(self):
        """Plain numbers for the meters: slots, bank-$41 name bytes, bank-$7E
        art bytes (S105 limits, species.py)."""
        prj = self._project()
        lst = SP.resolve(prj, with_art=True)
        regions, _ = SP.text_layout(lst, SP._spills(prj))
        name_used = sum(len(b) for items in regions.values() for _l, b in items)
        art = sum(len(s['battle_art']) + len(s['follower_art']) for s in lst)
        return {'slots': (len(lst), SP.N_IDS), 'names': (name_used, SP.TEXT_BUDGET),
                'art': (art, SP.BANK_7E_BUDGET)}

    def _asset_paths(self, sid, name):
        slug = re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_') or f'species{sid}'
        return (f'assets/species/{sid}_{slug}_battle.bin',
                f'assets/species/{sid}_{slug}_follower.bin')

    def species_asset_paths(self, sid, name):
        """Where add_species / set_species_art write a species' art (for the
        undo command's asset snapshot)."""
        return list(self._asset_paths(sid, name))

    def _write_asset(self, rel, data):
        path = os.path.join(self.project_dir, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'wb') as f:
            f.write(data)

    def add_species(self, sid, name, short_name, clone_from, family, art, source=None):
        """A new species: `art` = {'battle': stream, 'battle_palette': [4 RGB555],
        'follower': stream, 'follower_palette': 0-7, and 'layout': 0-154 (S107
        2b: the walk style the stream is packed for) or 'walks_like': 128-214}.
        Writes the two streams into assets/species/ and the custom.species
        entry. Returns the asset paths written."""
        sid = int(sid)
        if sid not in self.free_species_ids():
            raise SP.SpeciesError(f'species id {sid} is not free (221-239)')
        bp, fp = self._asset_paths(sid, name)
        entry = {'id': sid, 'name': name}
        if short_name and short_name != name[:SP.SHORT_MAX]:
            entry['short_name'] = short_name
        info = {'clone_from': int(clone_from)}
        base = G._rows(G.vanilla(REPO), 'monster_info')[int(clone_from)]
        if family is not None and int(family) != base[0]:
            info['family'] = G.FAMILY_NAMES[int(family)]
        entry['info'] = info
        entry['description_from'] = int(clone_from) if int(clone_from) <= SP.DESC_MAX else 0
        entry['battle'] = {'art': bp, 'palette': [f'${w:04X}' for w in art['battle_palette']]}
        entry['follower'] = {'art': fp, 'palette': int(art['follower_palette'])}
        if art.get('layout') is not None:
            entry['follower']['layout'] = int(art['layout'])
        else:
            entry['follower']['walks_like'] = int(art.get('walks_like', SP.DONOR_MIN))
        if source:
            entry['source'] = source
        data = copy.deepcopy(self.data)
        lst = data.setdefault('custom', {}).setdefault('species', [])
        lst.append(entry)
        lst.sort(key=lambda s: s.get('id', 0))
        self._write_asset(bp, art['battle'])
        self._write_asset(fp, art['follower'])
        self._commit_data(data)
        return [bp, fp]

    def set_species_art(self, sid, art, source=None):
        """Replace a new species' art (same files) + palettes / donor."""
        s = self.new_species(sid)
        data = copy.deepcopy(self.data)
        for e in data['custom']['species']:
            if e.get('id') == sid:
                bp = (e.get('battle') or {}).get('art') or self._asset_paths(sid, s['name'])[0]
                fp = (e.get('follower') or {}).get('art') or self._asset_paths(sid, s['name'])[1]
                e.setdefault('battle', {}).update(
                    {'art': bp, 'palette': [f'${w:04X}' for w in art['battle_palette']]})
                fo = e.setdefault('follower', {})
                fo.update({'art': fp, 'palette': int(art['follower_palette'])})
                if art.get('layout') is not None:        # S107 2b
                    fo['layout'] = int(art['layout'])
                    fo.pop('walks_like', None)
                elif 'layout' not in fo:
                    fo['walks_like'] = int(art.get('walks_like', fo.get('walks_like', SP.DONOR_MIN)))
                if source:
                    e['source'] = source
                self._write_asset(bp, art['battle'])
                self._write_asset(fp, art['follower'])
        self._commit_data(data)

    def set_species_props(self, sid, **props):
        """name, short_name, description_from, walks_like, follower_palette,
        battle_palette (4 RGB555), clone_from."""
        data = copy.deepcopy(self.data)
        for e in data['custom']['species']:
            if e.get('id') != sid:
                continue
            for k, v in props.items():
                if k == 'name':
                    e['name'] = v
                elif k == 'short_name':
                    if v and v != e['name'][:SP.SHORT_MAX]:
                        e['short_name'] = v
                    else:
                        e.pop('short_name', None)
                elif k == 'description_from':
                    e['description_from'] = int(v)
                    e.pop('description', None)
                elif k == 'description':              # S108: its own text (1-3 lines)
                    if v:
                        e['description'] = [str(x) for x in v]
                        e.pop('description_from', None)
                    else:
                        e.pop('description', None)
                elif k == 'walks_like':
                    e.setdefault('follower', {})['walks_like'] = int(v)
                    e['follower'].pop('layout', None)
                elif k == 'follower_palette':
                    e.setdefault('follower', {})['palette'] = int(v)
                elif k == 'battle_palette':
                    e.setdefault('battle', {})['palette'] = [f'${int(w):04X}' for w in v]
                elif k == 'clone_from':
                    info = e.setdefault('info', {})
                    # keep the EFFECTIVE row: re-base the diff on the new clone row
                    row = self.species_row(sid)
                    base = G._rows(G.vanilla(REPO), 'monster_info')[int(v)]
                    e['info'] = dict({'clone_from': int(v)},
                                     **{kk: vv for kk, vv in info.items() if str(kk).startswith('_')},
                                     **info_diff(row, bytes(base)))
                else:
                    raise KeyError(k)
        self._commit_data(data)

    # ------------------------------------------------------------ names / text
    # S108 (P3.10 part 3): the ORIGINAL monsters' name, default nickname and
    # library description = gamedata.monster_text (editor2/core/monster_text.py,
    # PROJECT_COMPILER §2.24); 215-220 are not monsters (Iron Rule 8).
    def monster_names_effective(self):
        """{species id: name the player sees} — originals with the project's
        renames, plus the new species. The one name source for every list."""
        from editor2.core import monster_text as MT
        try:
            e = MT.effective(self.data, REPO)
        except MT.MonsterTextError:
            e = MT.vanilla(REPO)
        out = {sid: MT.decode(e['names'][sid]) for sid in range(221)}
        out[220] = out[220] or '(empty)'
        for sp in (self.data.get('custom') or {}).get('species') or []:
            if isinstance(sp, dict) and sp.get('id') is not None:
                out[sp['id']] = sp.get('name', f"#{sp['id']}")
        return out

    def monster_text(self, sid):
        """{'name', 'nickname', 'description': [lines], 'original': {same},
        'edited': {field: bool}} of original monster `sid` (0-214)."""
        from editor2.core import monster_text as MT
        sid = int(sid)
        van = MT.vanilla(REPO)
        orig = {'name': MT.decode(van['names'][sid]), 'nickname': MT.decode(van['nicks'][sid]),
                'description': MT.desc_lines(van['descs'][sid])}
        e = ((self.data.get('gamedata') or {}).get('monster_text') or {}).get(str(sid)) or {}
        cur = {'name': e.get('name', orig['name']), 'nickname': e.get('nickname', orig['nickname']),
               'description': list(e['description']) if 'description' in e else list(orig['description'])}
        if isinstance(cur['description'], str):
            cur['description'] = cur['description'].split('\n')
        cur['original'] = orig
        cur['edited'] = {k: cur[k] != orig[k] for k in ('name', 'nickname', 'description')}
        return cur

    def set_monster_text(self, sid, **fields):
        """name / nickname / description (list of 1-3 lines) of original monster
        `sid`; a field set back to the original disappears. Validated (font,
        lengths, room in the banks) before it is kept."""
        from editor2.core import monster_text as MT
        sid = int(sid)
        if sid not in MT.IDS:
            raise SP.SpeciesError(f'species {sid}: only the original monsters 0-214 are renamed '
                                  'here (215-220 are not monsters — PROJECT_STATE Iron Rule 8; '
                                  'new species keep their name in their own page)')
        orig = self.monster_text(sid)['original']
        data = copy.deepcopy(self.data)
        mt = data.setdefault('gamedata', {}).setdefault('monster_text', {})
        e = dict(mt.get(str(sid)) or {})
        for k, v in fields.items():
            if k not in ('name', 'nickname', 'description'):
                raise KeyError(k)
            if k == 'description':
                v = [str(x) for x in (v.split('\n') if isinstance(v, str) else v)]
                while len(v) > 1 and not v[-1].strip():
                    v.pop()
            else:
                v = str(v).strip()
            if v == orig[k]:
                e.pop(k, None)
            else:
                e[k] = v
        if e:
            mt[str(sid)] = e
        else:
            mt.pop(str(sid), None)
        if not mt:
            data['gamedata'].pop('monster_text', None)
            if not data['gamedata']:
                data.pop('gamedata', None)
        self._commit_data(data)

    def reset_monster_text(self, sid):
        o = self.monster_text(sid)['original']
        self.set_monster_text(sid, **o)

    def text_capacity(self):
        """{'names' | 'nicks' | 'descs': (bytes used, block size)} — the meters."""
        from editor2.core import monster_text as MT
        return MT.usage(self._project())

    # ------------------------------------------------------------ original art
    # S107 (P3.10 part 2a): new art for the ORIGINAL monsters 0-214 =
    # gamedata.art (editor2/core/art.py, PROJECT_COMPILER §2.23). 215-220 are
    # TERRY? and the summons — never re-arted (PROJECT_STATE Iron Rule 8).
    def original_art(self, sid):
        """The project's gamedata.art entry of original species `sid` ({} = the
        original art and colours)."""
        return dict(((self.data.get('gamedata') or {}).get('art') or {}).get(str(int(sid))) or {})

    def can_reart(self, sid):
        from editor2.core import art as A
        return int(sid) in A.ART_IDS

    def original_palettes(self, sid):
        """The original game's ([4 RGB555] battle colours, OBJ palette 0-7)."""
        from editor2.core import art as A
        v = A._vanilla(self._project())
        p = v['battle_pal'][sid]
        bank, i = A.follower_bank(sid)
        return [p[2 * k] | p[2 * k + 1] << 8 for k in range(4)], v['attr'][bank][i] & 7

    def _art_paths(self, sid):
        from editor2.core.gamedata import monster_names
        name = monster_names(REPO).get(sid, f'species{sid}')
        slug = re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_') or f'species{sid}'
        return (f'assets/art/{sid:03d}_{slug}_battle.bin',
                f'assets/art/{sid:03d}_{slug}_follower.bin')

    def original_art_paths(self, sid):
        """Where set_original_art writes (the undo command's asset snapshot)."""
        return list(self._art_paths(int(sid)))

    def _put_art(self, sid, entry):
        from editor2.core import art as A
        sid = int(sid)
        if sid not in A.ART_IDS:
            raise A.ArtError(f'species {sid}: only the original monsters 0-214 get new art '
                             '(215-220 = TERRY? and the summons; 221+ = your new species)')
        data = copy.deepcopy(self.data)
        gd = data.setdefault('gamedata', {})
        sec = gd.setdefault('art', {})
        clean = {k: v for k, v in entry.items() if v}
        if clean:
            sec[str(sid)] = clean
        else:
            sec.pop(str(sid), None)
        if not sec:
            gd.pop('art', None)
        prj = self._project(data)
        A.place(prj)                       # validates: files, ids, the art banks' room
        from editor2.core import walk_layouts as WL
        try:                               # S107 2b: the layout copies' room
            WL.copies(WL.needed(prj), getattr(prj, 'repo_root', None))
        except WL.LayoutError as ex:
            raise A.ArtError(str(ex))
        self._commit_data(data)

    def set_original_art(self, sid, art, source=None):
        """Re-art original monster `sid` from a sheet cut: `art` = {'battle':
        stream, 'battle_palette': [4 RGB555], 'follower': stream,
        'follower_palette': 0-7, 'layout': 0-154} (the sheet dialog's result;
        `layout` = the walk style the walking stream is packed for, S107 2b —
        absent = layout 0, the 2a packing). Writes
        assets/art/<sid>_<name>_{battle,follower}.bin."""
        sid = int(sid)
        bp, fp = self._art_paths(sid)
        e = self.original_art(sid)
        e['battle'] = {'art': bp, 'palette': [f'${int(w):04X}' for w in art['battle_palette']]}
        e['follower'] = {'art': fp, 'palette': int(art['follower_palette'])}
        if art.get('layout') is not None:
            e['follower']['layout'] = int(art['layout'])
        if source:
            e['source'] = source
        self._write_asset(bp, art['battle'])
        self._write_asset(fp, art['follower'])
        self._put_art(sid, e)

    def set_original_art_props(self, sid, battle_palette=None, follower_palette=None):
        """Colours only (keeps whichever art the species has). A value equal
        to the original game's, on original art, is dropped."""
        sid = int(sid)
        e = self.original_art(sid)
        vb, vf = self.original_palettes(sid)
        if battle_palette is not None:
            b = dict(e.get('battle') or {})
            if 'art' not in b and [int(x) for x in battle_palette] == vb:
                b.pop('palette', None)
            else:
                b['palette'] = [f'${int(w):04X}' for w in battle_palette]
            e['battle'] = b
        if follower_palette is not None:
            f = dict(e.get('follower') or {})
            if 'art' not in f and int(follower_palette) == vf:
                f.pop('palette', None)
            else:
                f['palette'] = int(follower_palette)
            e['follower'] = f
        self._put_art(sid, e)

    def reset_original_art(self, sid):
        """Back to the original game's art and colours (the asset files stay
        in the project folder)."""
        self._put_art(sid, {})

    def art_capacity(self):
        """(bytes used, capacity) of the art banks $7F/$7C/$7A."""
        from editor2.core import art as A
        return A.usage(self._project())

    def species_references(self, sid):
        """Where the project uses species `sid` (so removing it is safe only
        when this is empty): enemy rows, monster NPCs, breeding."""
        refs = []
        for e in self.project_enemies():
            if int(e.get('species', -1)) == sid:
                refs.append(f"enemy “{e.get('id')}”")
        for r in (self.data.get('custom') or {}).get('rooms') or []:
            if re.search(r'"(species|monster)":\s*%d\b' % sid, json.dumps(r)):
                refs.append(f"monster NPC in room “{r.get('id')}”")
        br = json.dumps(((self.data.get('gamedata') or {}).get('breeding')) or {})
        if re.search(r'"result":\s*%d\b' % sid, br) or re.search(r'"p[12]":\s*%d\b' % sid, br):
            refs.append('a breeding recipe')
        return refs


    # ------------------------------------------------------------ gate wild lists
    def gate_pools(self):
        """[(pool index, "Gate name (floors)")] for every gate encounter list
        (extracted/encounters.json: 32 gates -> pools; a pool can serve several
        gates / floor ranges)."""
        out = []
        try:                               # S114: live usage (encounters_doc)
            places = self.list_places()
        except Exception:                  # noqa: BLE001
            places = _pool_places()
        for pi, pl in sorted(places.items()):
            if pi < 128:
                out.append((pi, ' / '.join(pl)))
        return out

    def chance_percent(self):
        return list(G.vanilla(REPO)['chance_percent'])

    def pool_slots(self, pi, model=None):
        """The effective encounter list `pi` (DATA_STRUCTURES "Encounter pool
        entry"): {'size': [3 group codes], 'slots': [5 x {ref, eid, chance (code),
        max, name}]}; ref = the project enemy id for a project row (what
        gamedata.encounters stores), else the EID."""
        g = model[0] if model else self.monsters_model()[0]
        r = g.pool[pi]
        by_eid = {self.project_eid(e): e for e in self.project_enemies()}
        names = G.monster_names(REPO)
        for s in (self.data.get('custom') or {}).get('species') or []:
            names[s.get('id')] = s.get('name')
        slots = []
        for k in range(5):
            eid = r[10 + 2 * k] | r[11 + 2 * k] << 8
            pe = by_eid.get(eid)
            if pe is not None:
                ref, sp, lv = pe.get('id'), pe.get('species'), pe.get('level')
            else:
                ref = eid
                row = g.enemy[eid] if eid <= G.VANILLA_EID_MAX else None
                sp, lv = (row[0], row[4]) if row else (None, None)
            empty = eid == 0 and r[5 + k] == 0
            slots.append({'ref': ref, 'eid': eid, 'chance': r[5 + k], 'max': r[20 + k],
                          'empty': empty,
                          'name': '—' if empty else f"{names.get(sp, '?')} Lv {lv} (EID {eid})"})
        return {'size': list(r[2:5]), 'slots': slots}

    def set_pool_slots(self, pi, slots):
        """Write list `pi`'s five slots [(ref, chance code, max)] — only the
        fields that differ from the original game go into
        gamedata.encounters.<pi>; the compiler's checks run first (chances
        that add up to 100 %, no freezing 2-3 monster draw, real EIDs)."""
        pi = int(pi)
        vr = G._rows(G.vanilla(REPO), 'encounter_pools')[pi]
        van = {'slot_chance': list(vr[5:10]),
               'eids': [vr[10 + 2 * k] | vr[11 + 2 * k] << 8 for k in range(5)],
               'max_count': list(vr[20:25])}
        new = {'slot_chance': [int(c) for _r, c, _m in slots],
               'eids': [r if isinstance(r, str) else int(r) for r, _c, _m in slots],
               'max_count': [int(m) for _r, _c, m in slots]}
        data = copy.deepcopy(self.data)
        gd = data.setdefault('gamedata', {})
        enc = gd.setdefault('encounters', {})
        old = dict(enc.get(str(pi)) or {})
        for k in ('slot_chance', 'eids', 'max_count'):
            if new[k] == van[k]:
                old.pop(k, None)
            else:
                old[k] = new[k]
        if [k for k in old if not str(k).startswith('_')]:
            enc[str(pi)] = old
        else:
            enc.pop(str(pi), None)
        if not enc:
            gd.pop('encounters', None)
        self._commit_data(data)

    def new_enemy_for_species(self, sid):
        """A project enemy of species `sid` to put in gates / fights: a copy of
        the species' first original row if it has one, else of the wild Slime
        (EID 2: Lv 1, the gentlest row) with the species changed. -> its id."""
        g = self.monsters_model()[0]
        src = next((eid for eid, r in enumerate(g.enemy) if r[0] == sid), 2)
        before = copy.deepcopy(self.data)
        try:
            eid_name = self.add_enemy(copy_eid=src, species=int(sid))
            self._commit_data(copy.deepcopy(self.data))
        except Exception:
            self.data.clear()
            self.data.update(before)
            raise
        return eid_name

    def remove_species(self, sid):
        refs = self.species_references(sid)
        if refs:
            raise SP.SpeciesError('still used by ' + ', '.join(refs))
        data = copy.deepcopy(self.data)
        lst = data['custom']['species']
        data['custom']['species'] = [s for s in lst if s.get('id') != sid]
        if not data['custom']['species']:
            data['custom'].pop('species')
        self._commit_data(data)
