"""balance.py — the Balance service (ROADMAP P3.15a, S130; EDITOR_DESIGN §5.9;
PROJECT_COMPILER §2.43): how hard every key fight is, as one number a person
can compare — the LEVEL a typical team of that point in the story needs to
win 90 % of the time — for the original game (read-only, precomputed:
extracted/balance_vanilla.json by tools/build_balance_anchor.py) and for a
project (computed from its own data, cached per fight).

The pieces, all headless (never imports Qt):

  BattleData   what the battle simulator reads, from the original game or a
               project's EFFECTIVE data (gamedata edits, project enemies, new
               species, custom skills: records, learn rows, the bases new
               skills run, Earthquake's power table).
  timeline()   the story as steps in the order the original game plays them
               (FULL_FAQ chapter order): every gate (its floor lists in runs,
               its boss fight(s)), every arena class, Starry Night, Monster
               Grandpa's match. A project keeps the order and the positions —
               gate n is still the n-th gate of the story, the G class still
               follows Gate 1 — and fills each position with ITS content.
               New gates (32+), worlds and rooms with their own battles get a
               number of their own (`extra_fights`).
  Roster       the monsters a player can have at a step: the joinable wild
               rows of every list met so far, the boss join rows of the gates
               already cleared, the starter; offspring once breeding has
               opened (`breeding_opens`, default after the F class).
  roll_team    a team a player might have assembled: members created, bred
               (+ birth), levelled and taught by simulator/raising.py (== the
               game, census_raising.py). 'casual' = what was at hand, the
               first skills kept; 'strong' = the best of several rolls, bred
               for skills, the best 8 kept. Progress is EXP: every member has
               the same exp (battle exp is split evenly), so a slow-curve
               monster is a few levels behind — the team level shown is the
               level that exp gives on the most common exp curve (11).
               'player' (S130, P3.15b) = the step's optimised skill KIT
               (editor2/core/kits.py: 3 monsters x <= 8 skills a skilled
               player brings, one general kit per step) raised to the team
               level, the skills learnable there; it battles under the
               player's ORDERS (simulator/planner.py, plan $81 Command), in
               the arena (db73 2: classes, Starry Night, Grandpa) on the best
               of the four tactics. 'casual' / 'strong' act on their AI
               (tactics), unchanged. The kit is computed once per step and
               cached (FightCache 'kit:<fp>', the anchor's steps[i]['kit']).
  evaluate     N rolled teams x M battles of one fight (real draws for
               lists) through simulator/pacing.py -> win %, rounds, HP left.
  level_needed the smallest team level that wins >= 90 % (and 50 %).
  dive         a gate's floors fought in a row without healing, then the
               boss: the chance to get through.

Every number states its corpus: skills the simulator does not model (a
"no-effect" action in the battle log) are counted per fight and reported.
"""
from __future__ import annotations

import copy
import hashlib
import json
import os
import random
import sys
import threading

_REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if _REPO not in sys.path:
    sys.path.insert(0, _REPO)

from simulator import raising as R            # noqa: E402
from simulator import pacing as P             # noqa: E402
from simulator import battle as B             # noqa: E402

REF_CURVE = 11               # the exp curve most species use (20 of 215)
WIN_TARGET = 0.90
WIN_HALF = 0.50
HEAL_VALUE_CAP = 30         # 'strong' picks: a heal never outscores a real attack
CAP_SWAP = 0.85             # members capped below 85 % of the team level are swapped
BREED_MIN_LEVEL = 10        # both parents (FULL_FAQ: "only breed Monsters at Level 10 or above")
ANCHOR_JSON = os.path.join('extracted', 'balance_vanilla.json')
ANCHOR_VERSION = 1
PROFILES = ('casual', 'strong', 'player')
SIM_VERSION = 'S131.2'       # bump when the simulator / raising model changes (S131: bred kits at
                             # any level, parents to 10 on their own curves, special-room dives)
                             # (invalidates project caches + the anchor)


def _seed(*parts):
    """A stable 32-bit seed (Python's hash() of str is salted per process)."""
    return int.from_bytes(hashlib.sha256(repr(parts).encode()).digest()[:4], 'little')

# ---------------------------------------------------------------------------
# the original game's story order (FULL_FAQ.txt chapter list)
# ---------------------------------------------------------------------------
# ('gate', gate id) / ('class', arena group 0-7) / ('starry', 8) / ('grandpa', 9)
VANILLA_STEPS = [
    ('gate', 0), ('class', 0), ('gate', 1), ('gate', 2), ('gate', 5), ('class', 1),
    ('gate', 3), ('gate', 4), ('class', 2), ('gate', 6), ('gate', 7), ('gate', 8),
    ('class', 3), ('gate', 10), ('gate', 9), ('gate', 11), ('gate', 14), ('gate', 17),
    ('class', 4), ('gate', 12), ('gate', 13), ('class', 5), ('gate', 15), ('gate', 16),
    ('class', 6), ('gate', 18), ('gate', 19), ('gate', 20), ('class', 7), ('gate', 21),
    ('starry', 8),
    ('gate', 22), ('gate', 23), ('gate', 24), ('gate', 25), ('gate', 26), ('gate', 27),
    ('gate', 28), ('gate', 29), ('gate', 30), ('grandpa', 9),
]
POSTGAME_FROM = VANILLA_STEPS.index(('gate', 22))
# FULL_FAQ chapter 6 (F class) ends at the Shrine of Starry Night: breeding opens
BREEDING_OPENS_AFTER = VANILLA_STEPS.index(('class', 1))

# The boss fights of each vanilla gate's boss room (keyed by the boss MAP, so a
# project that points a gate at another gate's boss room gets that room's
# fights). Source: extracted/arena_brackets.json gate_boss_triggers (the 53
# trigger sites, SIDEQUEST_MAP "ROSTER format — DECODED S67"); the side fights
# (Bewilder's 4 Stubsuck decoys, Anger's 7 DragonKid decoys) and the Medal
# Gate's two door variants that are not KingSlime are left out.
VANILLA_BOSS_FIGHTS = {
    0: [[11]], 1: [[31]], 2: [[32]], 3: [[51]], 4: [[53]], 5: [[55]], 6: [[75]],
    7: [[77]], 8: [[79]], 9: [[99]], 10: [[101]], 11: [[103]], 12: [[123]],
    13: [[125]], 14: [[127]], 15: [[147]], 16: [[151, 149, 152]], 17: [[153]],
    18: [[175]], 19: [[177]], 20: [[179]],
    21: [[342, 342], [343], [199]],          # Servants x2 -> TERRY? -> Durran
    22: [[201]], 23: [[203], [205]], 24: [[207]], 25: [[209]], 26: [[211]],
    27: [[213]], 28: [[215]], 29: [[217]], 30: [[219]],
}
CLASS_NAMES = ['G', 'F', 'E', 'D', 'C', 'B', 'A', 'S']
STARTER_EID = 1


# ---------------------------------------------------------------------------
# battle inputs
# ---------------------------------------------------------------------------
_RECORD_FIELDS = [('effect_class', 0, 1), ('effect_category', 1, 1), ('target_mode', 2, 1),
                  ('ai_weight', 3, 1), ('mp_cost_byte', 4, 1), ('status_id', 5, 1),
                  ('damage_class', 6, 1), ('flags7', 7, 1), ('flags8', 8, 1),
                  ('flags9', 9, 1), ('field10', 10, 1), ('power_party_min', 11, 2),
                  ('power_party_range', 13, 2), ('power_enemy_min', 15, 2),
                  ('power_enemy_range', 17, 2)]


def record_dict(sid, row, name=''):
    """A 19-byte SkillRecordData row -> the shape simulator/ reads
    (extracted/skill_records.json 'battle_record')."""
    f = {}
    for k, o, n in _RECORD_FIELDS:
        f[k] = row[o] if n == 1 else row[o] | row[o + 1] << 8
    return {'id': sid, 'name': name, 'battle_record': {'raw': bytes(row).hex(), 'fields': f}}


class BattleData:
    """The simulator's inputs for the original game (project=None) or a
    project's effective data."""

    def __init__(self, project=None, repo=None):
        from . import gamedata as G
        self.repo = repo or (getattr(project, 'repo_root', None) if project else None) or _REPO
        self.project = project
        g = project.gamedata() if project is not None else G.Gamedata({}, self.repo)
        self.g = g
        self.T = R.Tables.from_gamedata(g, project)
        self.names = self.T.names
        self.skill_names = dict(self.T.skill_names)
        self.records = {sid: record_dict(sid, bytes(r), self.skill_names.get(sid, ''))
                        for sid, r in enumerate(g.record)}
        self.core_alias = {}
        self.quake_range = dict(B.QUAKE_RANGE)
        self.custom = {}
        if project is not None:
            self._custom_skills(project)
        else:
            self._custom_skills(None)
        self.species = {}
        for sp, info in self.T.info.items():
            self.species[sp] = {'resistances': list(info[15:42]), 'can_fly': bool(info[4]),
                                'metal': bool(info[5]), 'family': info[0]}
        self.dup = P.load_dup_flags()
        self.enemy_overrides = {}
        self.redirects = {f: j for f, j in g.redirects}
        if project is not None:
            for f, j, _n in project.enemy_redirects():
                self.redirects[f] = j

    def _custom_skills(self, project):
        from . import custom_skills as CS
        try:
            sk, extras, _w = CS.resolve(project if project is not None else
                                        {'gamedata': {}}, self.repo)
        except Exception:                                   # noqa: BLE001
            return
        for sid, e in sk.items():
            self.custom[sid] = e
            self.records[sid] = record_dict(sid, e['record'], self.skill_names.get(sid, ''))
            if e.get('base') is not None:
                self.core_alias[sid] = int(e['base'])
        q = (extras or {}).get('quake_power') or {}
        for k, v in q.items():
            try:
                sid = int(k)
                lo, hi = int(v[0]), int(v[1])
            except Exception:                               # noqa: BLE001
                continue
            if sid in self.quake_range:
                self.quake_range[sid] = (lo, hi)

    # -- enemies ----------------------------------------------------------
    def enemy_rec(self, eid):
        r = self.T.enemy(eid)
        u = lambda o: r[o] | r[o + 1] << 8                  # noqa: E731
        rec = {'enemy_stats_id': eid, 'species_id': r[0], 'level': r[4], 'exp': u(1),
               'joinability': r[3], 'hp': u(5), 'mp': u(7), 'atk': u(9), 'def': u(11),
               'agl': u(13), 'int': u(15), 'ai_weights': list(r[17:21]),
               'skills': [s for s in r[21:25] if s != 0xFF]}
        ov = self.enemy_overrides.get(eid)
        if ov:
            rec.update({k: (list(v) if isinstance(v, (list, tuple)) else v)
                        for k, v in ov.items() if k in rec})
        return rec

    def override_enemy(self, eid, **fields):
        """A what-if edit of enemy row `eid` for the simulator only (skills
        [<=4 ids], level, hp, mp, atk, def, agl, int, ai_weights): the
        Balance tab's "try this boss with other skills" — never saved to the
        project. No fields = drop the override."""
        if fields:
            self.enemy_overrides[eid] = dict(fields)
        else:
            self.enemy_overrides.pop(eid, None)

    def enemy_name(self, eid):
        r = self.T.enemy(eid)
        return self.names.get(r[0], f'#{r[0]}')

    def has_enemy(self, eid):
        return eid in self.T.enemies

    # -- skills -------------------------------------------------------------
    def skill_value(self, sid):
        """A rough worth for 'strong' rolls (which 8 to keep): the record's
        party power (x2 when it hits a whole side), heals at 3/4."""
        rec = self.records.get(self.core_alias.get(sid, sid)) or self.records.get(sid)
        if not rec:
            return 1
        f = rec['battle_record']['fields']
        p = f['power_party_min'] + f['power_party_range'] / 2
        if B.damage_core(self.core_alias.get(sid, sid), rec) == 'heal':
            return min(0.5 * p + 5, HEAL_VALUE_CAP)        # a heal is worth a modest hit
        if f['target_mode'] == 18:
            p *= 2
        return p + 3


# ---------------------------------------------------------------------------
# the timeline
# ---------------------------------------------------------------------------
class Fight(dict):
    """{key, step, kind ('list' | 'boss' | 'arena'), label, groups:
    [(weight, [eid...])], db73, eids (every row), floors (lists)}"""


def _list_groups(enc_bytes, pct, samples=6000, seed=130):
    """The battles a list gives: [(probability, [eid ...])] from the measured
    draw (editor2/core/encounters.py group_odds == the game, census S114)."""
    from . import encounters as EN
    odds = EN.group_odds(enc_bytes, pct, samples=samples, seed=seed)
    return sorted(((p, list(k)) for k, p in odds.items()), key=lambda x: -x[0])


class Timeline:
    """The story's fights for the original game (data.project None) or a
    project — same steps, the project's content at each position."""

    def __init__(self, data, breeding_opens=None):
        from . import encounters as EN
        from . import gates as GT
        from .project import Project
        self.data = data
        prj = data.project
        if prj is None:
            prj = Project({'meta': {'name': 'vanilla'}, 'custom': {}, 'gamedata': {}}, data.repo)
            prj.repo_root = data.repo
        self.prj = prj
        self.enc = EN.resolve(prj)
        self.gate_cfg = prj.gate_configs()
        self.van_gates = {g['id']: g for g in GT.vanilla_gates(data.repo)}
        self.breeding_opens = BREEDING_OPENS_AFTER if breeding_opens is None else breeding_opens
        self.steps = []
        self.fights = {}
        self._build()

    # ------------------------------------------------------------------
    def _list_fight(self, key, label, lists, step):
        pct = self.enc.pct
        groups = {}
        for n in lists:
            lb = self.enc.list_bytes(n)
            for p, eids in _list_groups(lb, pct):
                k = tuple(eids)
                groups[k] = groups.get(k, 0) + p / len(lists)
        gl = sorted(((p, list(k)) for k, p in groups.items() if all(self.data.has_enemy(e) for e in k)),
                    key=lambda x: -x[0])
        eids = sorted({e for _p, k in gl for e in k})
        return Fight(key=key, step=step, kind='list', label=label, groups=gl, db73=0,
                     eids=eids, lists=sorted(set(lists)))

    def _boss_fights(self, gid, step):
        cfg = self.gate_cfg.get(gid) or {}
        out = []
        if cfg.get('boss_room'):
            fights = room_battles(self.prj, cfg['boss_room'])
        else:
            bm = cfg.get('boss_map')
            src = None
            for vg, v in self.van_gates.items():
                if int(str(v.get('boss_map', '0')), 16) == bm:
                    src = vg
                    break
            fights = VANILLA_BOSS_FIGHTS.get(src if src is not None else gid, [])
        name = self.gate_name(gid)
        for k, eids in enumerate(fights):
            eids = [e for e in eids if self.data.has_enemy(e)]
            if not eids:
                continue
            lab = ' + '.join(self.data.enemy_name(e) for e in eids)
            out.append(Fight(key=f'gate{gid}.boss{k}', step=step, kind='boss',
                             label=f'{name} — boss: {lab}', groups=[(1.0, eids)],
                             db73=1, eids=list(eids)))
        return out

    def gate_name(self, gid):
        c = self.gate_cfg.get(gid) or {}
        return c.get('name') or (self.van_gates.get(gid) or {}).get('name') or f'Gate {gid}'

    def gate_runs(self, gid):
        """[(first floor, last floor, list)] — consecutive floors that use the
        same list (the boss floor has no maze)."""
        cfg = self.gate_cfg.get(gid) or {}
        n = cfg.get('floors') or (self.van_gates.get(gid) or {}).get('floors') or 1
        runs = []
        for f in range(1, max(1, n - 1) + 1):
            lst = self.enc.gate_list(gid, f)
            if runs and runs[-1][2] == lst:
                runs[-1][1] = f
            else:
                runs.append([f, f, lst])
        return [tuple(r) for r in runs]

    def _build(self):
        from . import arena as AR
        try:
            sizes = AR.resolve(self.prj)['sizes']
        except Exception:                                   # noqa: BLE001
            sizes = [3] * AR.ROWS
        for i, (kind, n) in enumerate(VANILLA_STEPS):
            fights = []
            if kind == 'gate':
                name = self.gate_name(n)
                label = name
                for a, b, lst in self.gate_runs(n):
                    fl = f'floor {a}' if a == b else f'floors {a}-{b}'
                    fights.append(self._list_fight(f'gate{n}.f{a}', f'{name} — {fl}', [lst], i))
                fights += self._boss_fights(n, i)
            else:
                gi = n
                label = (f'{CLASS_NAMES[gi]} class' if kind == 'class' else
                         'Starry Night' if kind == 'starry' else "Monster Grandpa's match")
                for m in range(AR.matches(gi)):
                    size = sizes[AR.index(gi, m)]
                    eids = [AR.eid(gi, m, s) for s in range(size)]
                    eids = [e for e in eids if self.data.has_enemy(e)]
                    lab = ' + '.join(self.data.enemy_name(e) for e in eids)
                    mname = (f'match {m + 1}' if gi != AR.KING else 'match')
                    if gi == AR.STARRY and m == 2:
                        mname = 'final'
                    fights.append(Fight(key=f'arena{gi}.m{m}', step=i, kind='arena',
                                        label=f'{label} — {mname}: {lab}',
                                        groups=[(1.0, eids)], db73=2, eids=eids))
            st = {'index': i, 'kind': kind, 'id': n, 'label': label,
                  'postgame': i >= POSTGAME_FROM, 'fights': [f['key'] for f in fights],
                  'breeding': i > self.breeding_opens}
            self.steps.append(st)
            for f in fights:
                self.fights[f['key']] = f

    # ------------------------------------------------------------------
    def roster(self, step_index):
        """Monsters a player can have when step `step_index` starts:
        {'joins': [eid ...] (wild rows that may join, boss join rows of the
        gates already cleared, the starter), 'breeding': bool}."""
        joins = {STARTER_EID}
        for st in self.steps[:step_index + 1]:
            for fk in st['fights']:
                f = self.fights[fk]
                if f['kind'] == 'list':
                    for e in f['eids']:
                        rec = self.data.enemy_rec(e)
                        if rec['joinability'] != 7 and rec['species_id'] <= 214 or \
                                (rec['joinability'] != 7 and rec['species_id'] >= 221):
                            joins.add(e)
                elif f['kind'] == 'boss' and st['index'] < step_index:
                    for e in f['eids']:
                        j = self.data.redirects.get(e)
                        if j is not None and self.data.has_enemy(j):
                            joins.add(j)
        joins = {e for e in joins if self.data.T.enemy(e)[0] not in range(215, 221)}
        return {'joins': sorted(joins), 'breeding': step_index > self.breeding_opens}

    def arena_tier(self, step_index):
        """$CAB4 at that point: class + 1 of the last class won before it."""
        t = 0
        for st in self.steps[:step_index]:
            if st['kind'] == 'class':
                t = st['id'] + 1
        return t


def room_battles(prj, room_id):
    """Every battle a custom room can start ({"battle": {"enemies": [...]}} in
    its talk steps, cutscenes and quests) -> [[eid ...]]."""
    room = prj.room_by_id(room_id)
    out = []

    def walk(o):
        if isinstance(o, dict):
            b = o.get('battle')
            if isinstance(b, dict) and isinstance(b.get('enemies'), list):
                try:
                    out.append([prj.enemy_ref(r, 'balance') for r in b['enemies']])
                except Exception:                           # noqa: BLE001
                    pass
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)
    if room is not None:
        walk(room)
        # S130 (Balance tab): a room's NPCs / room scripts name their script by
        # id ("script": "sboss_conv"); the talk steps with the battle live in
        # custom.scripts, not in the room
        refs = []

        def ref_walk(o):
            if isinstance(o, dict):
                for k, v in o.items():
                    if k == 'script' and isinstance(v, str):
                        refs.append(v)
                    elif k == 'scripts' and isinstance(v, dict):
                        refs.extend(x for _k, x in sorted(v.items(), key=lambda kv: str(kv[0]))
                                    if isinstance(x, str))
                    else:
                        ref_walk(v)
            elif isinstance(o, list):
                for v in o:
                    ref_walk(v)
        ref_walk(room)
        by_id = {sc.get('id'): sc for sc in (prj.custom.get('scripts') or [])
                 if isinstance(sc, dict)}
        for sid in dict.fromkeys(refs):
            if sid in by_id:
                walk(by_id[sid])
    seen, uniq = set(), []
    for f in out:
        k = tuple(f)
        if k not in seen:
            seen.add(k)
            uniq.append(f)
    return uniq


def extra_fights(data, tl):
    """The project's fights outside the story's positions: new gates / worlds
    (32+), rooms with their own lists, battles in rooms that are no gate's boss
    room. [Fight] with step None."""
    out = []
    prj = data.project
    if prj is None:
        return out
    for gid, cfg in sorted(tl.gate_cfg.items()):
        if gid < 32:
            continue
        name = tl.gate_name(gid)
        for a, b, lst in tl.gate_runs(gid):
            fl = f'floor {a}' if a == b else f'floors {a}-{b}'
            out.append(tl._list_fight(f'gate{gid}.f{a}', f'{name} — {fl}', [lst], None))
        out += [dict(f, step=None) for f in tl._boss_fights(gid, None)]
    boss_rooms = prj.boss_room_ids()
    for mid, rm in sorted(tl.enc.rooms.items()):
        if rm.get('default') is not None:
            rid = rm['room_id']
            lists = [rm['default']] + [n for _t, n in rm.get('variants', [])]
            out.append(tl._list_fight(f'room.{rid}.list', f'{rid} — its own battles', lists, None))
    for r in prj.rooms:
        rid = r.get('id')
        if rid in boss_rooms:
            continue
        for k, eids in enumerate(room_battles(prj, rid)):
            eids = [e for e in eids if data.has_enemy(e)]
            if eids:
                out.append(Fight(key=f'room.{rid}.b{k}', step=None, kind='boss',
                                 label=f'{rid} — battle: ' + ' + '.join(data.enemy_name(e) for e in eids),
                                 groups=[(1.0, eids)], db73=1, eids=eids))
    return [Fight(f) for f in out]


# ---------------------------------------------------------------------------
# teams
# ---------------------------------------------------------------------------
def exp_for_level(T, level):
    """Exp that makes a monster on the reference curve reach `level`."""
    return 0 if level <= 1 else T.exp[REF_CURVE][min(level, 99) - 1]


def level_for_exp_ref(T, exp):
    c = T.exp[REF_CURVE]
    lv = 1
    while lv < 99 and exp >= c[lv]:
        lv += 1
    return lv


def raise_to(T, m, exp, rng, policy, score):
    """Give m exp until it has `exp` in all (its own curve; joined monsters
    keep their arrival exp if it is more)."""
    if exp > m.exp:
        R.grow_by_exp(T, m, exp - m.exp, rng, policy, score)
    return m


def _member_joined(data, eid, exp, rng, tier, policy, score):
    m = R.create(data.T, eid, rng, arena_tier=tier)
    return raise_to(data.T, m, exp, rng, policy, score)


# ---------------------------------------------------------------------------
# S131 — breeding costs grinding (ROADMAP P3.15b (1), user: "I need to capture the
# total time investment needed"; PROJECT_COMPILER §2.43 "Breeding costs grinding")
# ---------------------------------------------------------------------------
# The level axis is TIME: team level L = each of the 3 party slots has had exp(L)
# (the reference curve) of grinding in it. A joined member arrives with its row's
# exp for free and is raised to exp(L). A bred member's ANCESTORS were ground to
# breeding level (both parents level 10+, the game's rule; a higher grind gives a
# level-sum plus bonus) and left the party at the cross: that exp is charged to the
# slot — the kid hatches at level 1 and is raised with exp(L) minus its lineage's
# grind. A lineage the slot cannot afford is not available at that level, so deep
# chains appear as the budget grows.
MAX_GENERATIONS = 6


def join_ancestor_cost(T, eid, grind=BREED_MIN_LEVEL):
    """Exp to grind the monster that joins from enemy row `eid` to level
    `grind` on its own curve (its arrival exp is free)."""
    row = T.enemy(eid)
    sp, lv = row[0], row[4]
    return max(0, T.exp_to_reach(sp, grind) - (T.exp_to_reach(sp, lv) if lv else 0))


def lineage_cost(m):
    """Exp a monster represents as an ANCESTOR: the exp it was ground (beyond
    what it arrived with) + its own ancestors' grind."""
    return max(0, m.exp - m.free_exp) + m.grind


def is_capped(T, m, frac=None):
    """m stuck at its level cap: below `frac` (CAP_SWAP) of the level its exp
    gives on its own curve without a cap (S131: S130 compared with the team
    level, which a bred member under the time axis is below by design)."""
    frac = CAP_SWAP if frac is None else frac
    return m.level < frac * T.level_for_exp(m.species, m.exp, cap=99)


def ensure_breedable(T, m, rng, policy, score):
    """Raise m to level BREED_MIN_LEVEL on its own curve if it is below (the
    game breeds only monsters of level 10+; S131). Returns m."""
    if m.level < BREED_MIN_LEVEL:
        raise_to(T, m, T.exp_to_reach(m.species, BREED_MIN_LEVEL), rng, policy, score)
    return m


def _member_bred(data, br, joins, exp, rng, tier, policy, score, picks=1, gens=1,
                 ancestor=False):
    """A bred member on the time axis (S131): two parents from the roster
    ground to level 10 on their own curves (a joined parent's arrival exp is
    free; gens > 1: a parent is itself bred (gens-1) half the time — plus,
    and with it the level cap (+2 per plus), builds up over generations),
    crossed by the resolver; the kid is born and raised with `exp` minus its
    lineage's grind (`grind`); None when the slot cannot afford the lineage.
    ancestor=True: the kid is itself a parent — raised to level 10, not
    charged. picks > 1: keep the offspring with the best score (strong
    players choose their crosses)."""
    best = None
    T = data.T
    for _ in range(picks):
        ps = []
        for _k in range(2):
            p = None
            if gens > 1 and rng.random() < 0.5:
                p = _member_bred(data, br, joins, exp, rng, tier, policy, score, 1, gens - 1,
                                 ancestor=True)
            if p is None:
                eid = rng.choice(joins)
                p = R.create(data.T, eid, rng, arena_tier=tier)
            ps.append(ensure_breedable(T, p, rng, policy, score))
        p1, p2 = ps
        if p1.level < BREED_MIN_LEVEL or p2.level < BREED_MIN_LEVEL:
            continue                    # capped below 10 (none in the original game)
        try:
            c = br.resolve(p1.species, p2.species, p1.plus, p2.plus, p1.level, p2.level)
        except Exception:                                   # noqa: BLE001
            continue
        if c.species in range(215, 221):
            continue
        grind = lineage_cost(p1) + lineage_cost(p2)
        if not ancestor and grind > exp:
            continue                    # the slot cannot afford this lineage yet
        kid = R.breed_and_birth(data.T, p1, p2, c.species, c.plus, rng)
        kid.grind = grind
        kid.origin = f'bred: {data.names.get(p1.species)} x {data.names.get(p2.species)}'
        if ancestor:
            ensure_breedable(T, kid, rng, policy, score)
        else:
            raise_to(data.T, kid, exp - grind, rng, policy, score)
        if best is None or member_power(data, kid) > member_power(data, best):
            best = kid
    return best


def member_power(data, m):
    """How a strong player rates a monster: bulk + offence (its ATK or its
    best damaging skills, whichever is more) + at most one heal's worth."""
    s = m.stats
    vals = [(data.skill_value(x), _is_heal(data, x)) for x in m.skills]
    dmg = sorted((v for v, h in vals if not h), reverse=True)[:3]
    heal = max((v for v, h in vals if h), default=0)
    offence = max(1.5 * s[2], 1.5 * s[2] * 0.5 + sum(dmg) * 2.0)
    return s[0] + s[3] + 0.5 * s[4] + 0.3 * s[1] + offence + heal


def _is_heal(data, sid):
    rec = data.records.get(data.core_alias.get(sid, sid)) or data.records.get(sid)
    return bool(rec) and B.damage_core(data.core_alias.get(sid, sid), rec) == 'heal'


def roll_team(data, tl, step_index, level, rng, profile='casual', breeding=None):
    """A team of 3 a player might have at `step_index` with exp for `level`
    on the reference curve. profile 'casual' | 'strong'. Returns [Monster]."""
    T = data.T
    ro = tl.roster(step_index)
    joins = ro['joins']
    can_breed = ro['breeding'] if breeding is None else breeding
    exp = exp_for_level(T, level)
    tier = tl.arena_tier(step_index)
    br = _breeder(data)
    policy = 'strong' if profile == 'strong' else 'casual'
    score = data.skill_value
    team = []
    tries = 3 if profile == 'casual' else 6
    for _slot in range(3):
        cands = []
        for _t in range(1 if profile == 'casual' else tries):
            bred = can_breed and br is not None and rng.random() < (0.35 if profile == 'casual' else 0.7)
            m = None
            if bred:
                m = _member_bred(data, br, joins, exp, rng, tier, policy, score,
                                 picks=1 if profile == 'casual' else 3,
                                 gens=1 if profile == 'casual' else
                                 (3 if step_index >= POSTGAME_FROM_INDEX(tl) else 2))
            if m is None:
                m = _member_joined(data, rng.choice(joins), exp, rng, tier, policy, score)
            # a monster stuck at its level cap well below the team gets
            # swapped: players replace members that stop growing
            swaps = 0
            while is_capped(data.T, m) and swaps < 3:
                swaps += 1
                if can_breed and br is not None and rng.random() < 0.5:
                    m2 = _member_bred(data, br, joins, exp, rng, tier, policy, score)
                else:
                    m2 = _member_joined(data, rng.choice(joins), exp, rng, tier, policy, score)
                if m2 is not None and (not is_capped(data.T, m2) or m2.level > m.level):
                    m = m2
            cands.append(m)
        team.append(max(cands, key=lambda m: member_power(data, m)) if profile == 'strong'
                    else cands[0])
    return team


_BR = {}
_TEAMS = {}


def POSTGAME_FROM_INDEX(tl):           # noqa: N802
    """First postgame step of tl (strong players breed one generation deeper
    from there)."""
    return next((s['index'] for s in tl.steps if s['postgame']), len(tl.steps))


def team_for(data, tl, step, level, profile, t, seed=130):
    """Rolled team number t at (step, level, profile) — memoised, so every
    fight of one step (a gate's floors and its boss) meets the same teams."""
    k = (id(data), id(tl), step, level, profile, t, seed)
    if k not in _TEAMS:
        if len(_TEAMS) > 20000:
            _TEAMS.clear()
        if profile == 'player':
            from . import kits as KT
            _TEAMS[k] = KT.kit_team(data, tl, step, get_kit(data, tl, step), level, t, seed)
        else:
            _TEAMS[k] = roll_team(data, tl, step, level, random.Random(_seed(seed, step, level,
                                                                              profile, t)), profile)
    return _TEAMS[k]


# ---------------------------------------------------------------------------
# the 'player' profile's kit per step (editor2/core/kits.py)
# ---------------------------------------------------------------------------
_KITS = {}
KIT_BUDGET = {'evals': 50, 'teams': 2, 'battles': 6}     # kits.step_kit defaults


def kit_fingerprint(data, tl, step, budget=None):
    """What a step's kit depends on: the roster, every fight of the step,
    the raising digest (SIM_VERSION), the kit version and the budget."""
    from . import kits as KT
    h = hashlib.sha256(raising_digest(data).encode())
    h.update(json.dumps([KT.KIT_VERSION, sorted((budget or KIT_BUDGET).items()),
                         tl.roster(step), tl.breeding_opens]).encode())
    for k in tl.steps[step]['fights']:
        h.update(fight_fingerprint(data, tl, tl.fights[k], 'kit', step).encode())
    return 'kit:' + h.hexdigest()[:20]


def set_kit(data, tl, step, kit):
    """Register a step's kit (from a cache / the anchor / a hand edit)."""
    _KITS[(id(data), id(tl), step)] = kit
    for k in [k for k in _TEAMS if k[:3] == (id(data), id(tl), step) and k[4] == 'player']:
        del _TEAMS[k]


def get_kit(data, tl, step, cache=None, compute=True, log=None, progress=None, **budget):
    """The step's kit: registered, else from the cache, else (the original
    game) from the anchor, else optimised now (kits.step_kit — minutes) and
    stored in the cache. compute=False -> None when not known."""
    k = (id(data), id(tl), step)
    if k in _KITS:
        return _KITS[k]
    bud = dict(KIT_BUDGET, **budget)
    fp = None
    if cache is not None:
        fp = kit_fingerprint(data, tl, step, bud)
        v = cache.get(fp)
        if v is not None:
            _KITS[k] = v
            return v
    if data.project is None and bud == KIT_BUDGET:
        a = load_anchor(data.repo)
        if a and a.get('sim_version') == SIM_VERSION and a.get('raising_digest') == raising_digest(data):
            try:
                kit = a['steps'][step].get('kit')
            except (IndexError, KeyError, AttributeError):
                kit = None
            if kit:
                _KITS[k] = kit
                return kit
    if not compute:
        return None
    from . import kits as KT
    kit = KT.step_kit(data, tl, step, log=log, progress=progress, **bud)
    _KITS[k] = kit
    if cache is not None:
        cache.put(fp, kit)
    return kit


def _breeder(data):
    k = id(data)
    if k not in _BR:
        try:
            from . import breeding as BRm
            _BR[k] = BRm.Breeding(data.g)
        except Exception:                                   # noqa: BLE001
            _BR[k] = None
    return _BR[k]


def party_dict(m, tactic=0):
    return dict(hp=m.stats[0], mp=m.stats[1], atk=m.stats[2], dfn=m.stats[3], agl=m.stats[4],
                int=m.stats[5], level=m.level, wld=m.wld, skills=list(m.skills),
                species=m.species, tactic=tactic,
                ai_weights=(m.ai[0], m.ai[3], m.ai[1], m.ai[2]), res=list(m.res))


# ---------------------------------------------------------------------------
# fights
# ---------------------------------------------------------------------------
def _board(data, party, enemies, db73):
    b = P.make_board(party, enemies, species=data.species, db73=db73)
    for i, m in enumerate(party):
        if m.get('res'):
            b.res[i * 7:(i + 1) * 7] = P.pack_res(m['res'])
    b.core_alias = data.core_alias
    b.quake_range = data.quake_range
    return b


class Cancelled(Exception):
    """Raised inside a computation when the thread's cancel check says stop
    (the Balance tab's Cancel; never set by scripts / the anchor build)."""


_CANCEL = threading.local()


def set_cancel_check(fn):
    """`fn()` -> True stops this thread's running evaluation / dive at its
    next battle (raises Cancelled). None = no check. Per thread; results are
    unchanged when it never fires (nothing partial is cached)."""
    _CANCEL.fn = fn


def NO_ORDER(b, s):                     # noqa: N802 — the arena's "NO SP SK" (never called)
    return (B.ATTACK, None)


ACTION_TAGS = ('hit', 'no-effect', 'heal', 'status', 'miss', 'dodge', 'fly-dodge')


def count_actions(log):
    """(unmodelled, actions) over a battle log (pacing.simulate_battle's
    'log': rounds of entries (actor, tag, payload)). An action the model has
    no core for is logged 'no-effect' with the skill id; S131: a heal on a
    full-HP / fallen target is the GAME's own "no effect" (f5_heal logs it
    'no-effect' with a (target, amount) payload) and is not counted as
    unmodelled (S130 counted it: up to 13 % on heal-heavy teams)."""
    noeff = acts = 0
    for rl in log:
        for e in rl:
            if len(e) >= 2 and e[1] in ACTION_TAGS:
                acts += 1
                if e[1] == 'no-effect' and not isinstance(e[2] if len(e) > 2 else None, tuple):
                    noeff += 1
    return noeff, acts


def battle_once(data, party, eids, db73, rnd, idle, carry=None, out=None, planner=None):
    """One battle. party = [party dicts]; carry = [(hp, mp)] to start from
    (dives). Returns (winner, rounds, [(hp, mp)] after, no_effect actions,
    actions). out (a dict) also gets 'enemy_hp_left': the enemies' HP left
    / their full HP (how far a lost fight got). planner (simulator/planner.py)
    = the party acts on the player's orders (party_policy 'command'); in the
    arena (db73 2) the menu offers "NO SP SK" instead of COMMAND — tactic 3
    with no order (plain Attack + the party attack pick), the planner is
    never asked (pass NO_ORDER). Without a planner the party dicts' tactic
    holds (party_policy 'tactics')."""
    fn = getattr(_CANCEL, 'fn', None)
    if fn is not None and fn():
        raise Cancelled()
    enemies = [data.enemy_rec(e) for e in eids]
    b = _board(data, party, enemies, db73)
    if carry:
        for i, (hp, mp) in enumerate(carry):
            if i < len(party):
                b.hp[i] = hp
                b.mp[i] = mp
                if hp <= 0:
                    b.dd1b[i] = 1
                    b.dd13[i] = 0
    er = {4 + j: enemies[j] for j in range(len(enemies))}
    pol = 'tactics' if any(p['skills'] for p in party) else 'attack'
    if planner is not None:
        pol = 'command'                   # (the arena: "NO SP SK", no order asked)
        b.ext['planner'] = planner
    r = P.simulate_battle(b, data.records, data.dup, idle, rnd, party_policy=pol,
                          enemy_recs=er, max_rounds=60)
    noeff, acts = count_actions(r['log'])
    after = [(max(0, b.hp[i]), b.mp[i]) for i in range(len(party))]
    if out is not None:
        full = sum(e['hp'] for e in enemies) or 1
        out['enemy_hp_left'] = sum(max(0, b.hp[4 + j]) for j in range(len(enemies))) / full
    return r['winner'], r['rounds'], after, noeff, acts


def _pick_group(fight, rnd):
    x = rnd.random() * sum(p for p, _ in fight['groups'])
    for p, eids in fight['groups']:
        x -= p
        if x <= 0:
            return eids
    return fight['groups'][-1][1]


def evaluate(data, tl, fight, level, profile='casual', teams=8, battles=16, seed=130,
             team_list=None, step_index=None):
    """Win rate etc. of `fight` for rolled teams at `level` (or the given
    team_list of [Monster] teams). 'player': every team fights under the
    player's orders (a simulator/planner.py planner per team), in the arena
    on each of the four tactics over the same battles — Charge / Mixed /
    Cautious on the AI, the fourth = "NO SP SK" (PLAN tactic 3 with no
    order: plain Attack, pacing.give_orders) — the best kept (the
    result then names the tactic most teams used: 'tactic')."""
    step = fight['step'] if step_index is None else step_index
    if step is None:
        step = len(tl.steps) - 1
    idle = P.IdlePolicy('empirical', seed=seed)
    wins = rounds = 0
    n = 0
    hp_left = 0.0
    noeff = acts = 0
    lv_sum = 0.0
    ehp = 0.0
    nteams = teams if team_list is None else len(team_list)
    player = profile == 'player'
    tac_count = {}
    for t in range(nteams):
        team = team_list[t] if team_list is not None else team_for(data, tl, step, level,
                                                                   profile, t, seed)
        lv_sum += sum(m.level for m in team) / max(1, len(team))
        # 'player': orders (a planner per team: it caches), or in the arena the
        # best of the four tactics (the same battles for each, the best kept)
        runs = [(0, None)]
        if player and fight['db73'] == 2:
            runs = [(tac, NO_ORDER if tac == 3 else None) for tac in range(4)]
        elif player:
            from simulator import planner as PL
            runs = [(0, PL.make_planner(data.records))]
        best = None
        for tac, pl in runs:
            party = [party_dict(m, tac) for m in team]
            maxhp = sum(p['hp'] for p in party) or 1
            rnd = random.Random(seed * 7919 + t)
            if len(runs) > 1:             # common random numbers for the four
                idle = P.IdlePolicy('empirical', seed=seed * 7919 + t)
            r = dict(wins=0, rounds=0, hp=[], ne=0, ac=0, ehp=[], tac=tac)
            for k in range(battles):
                eids = _pick_group(fight, rnd)
                o = {}
                w, rd, after, ne, ac = battle_once(data, party, eids, fight['db73'], rnd, idle,
                                                   out=o, planner=pl)
                r['ehp'].append(o['enemy_hp_left'])
                r['wins'] += (w == 'party')
                r['rounds'] += rd
                r['hp'].append(sum(h for h, _m in after) / maxhp)
                r['ne'] += ne
                r['ac'] += ac
            if best is None or (r['wins'], -sum(r['ehp'])) > (best['wins'], -sum(best['ehp'])):
                best = r
        n += battles
        wins += best['wins']
        rounds += best['rounds']
        for h in best['hp']:                  # summed battle by battle (the anchor's
            hp_left += h                      # numbers stay bit-identical)
        for h in best['ehp']:
            ehp += h
        noeff += best['ne']
        acts += best['ac']
        tac_count[best['tac']] = tac_count.get(best['tac'], 0) + 1
    out = {'win': wins / n if n else 0.0, 'rounds': rounds / n if n else 0.0,
           'hp_left': hp_left / n if n else 0.0, 'battles': n,
           'unmodelled': noeff / acts if acts else 0.0,
           'team_level': lv_sum / nteams if nteams else 0.0,
           'enemy_hp_left': ehp / n if n else 0.0}
    if player and fight['db73'] == 2:
        out['tactic'] = max(tac_count, key=lambda k: (tac_count[k], -k))
    return out


def level_needed(data, tl, fight, profile='casual', target=WIN_TARGET, teams=12, battles=8,
                 seed=130):
    """Smallest team level (reference curve) whose rolled teams win >= target
    (searched from below, first_level). Returns (level or None, evaluation
    at it / at 99). fight_levels gives both thresholds from one memo."""
    memo = {}

    def ev(L):
        if L not in memo:
            memo[L] = evaluate(data, tl, fight, L, profile, teams, battles, seed)
        return memo[L]
    lv = first_level(lambda L: ev(L)['win'] >= target)
    return lv, ev(lv if lv else 99)


WALKS = ('direct', 'sweep')


def floor_battle_means(data, tl, gid):
    """[(fight, direct mean, sweep mean)] per maze floor of gate `gid`:
    the expected random battles walking that floor straight to the stairs
    (editor2/core/dive.py, measured S130: the shortest walk — a LOWER bound)
    and walking the whole floor (every reachable cell once — the UPPER
    bound; the direct figure scaled by reachable cells / walk steps)."""
    from . import dive as DV
    cfg = tl.gate_cfg.get(gid) or {}
    row = cfg.get('row') or []
    maze_row = row[0] if len(row) > 0 else None
    special_row = row[1] if len(row) > 1 else None
    floors = cfg.get('floors')
    out = []
    for a, b2, lst in tl.gate_runs(gid):
        f = tl.fights.get(f'gate{gid}.f{a}')
        if f is None:
            continue
        lb = tl.enc.list_bytes(lst)
        for fl in range(a, b2 + 1):
            try:
                d = DV.battles_per_floor(data.repo, gid, fl, lb, maze_row=maze_row,
                                         special_row=special_row, floors=floors, detail=True)
                if d.get('boss_floor'):
                    sweep = 0.0
                elif 'battles_sweep' in d:
                    # S131: maze part and special rooms (their own walks) scaled each
                    sweep = d['battles_sweep']
                else:
                    steps = DV.floor_steps(data.repo, d['size'])
                    sweep = d['battles'] * (steps['reachable'] / max(1.0, steps['steps']))
                out.append((f, d['battles'], sweep))
            except Exception:                           # noqa: BLE001
                out.append((f, 0.5, 5.0))
    return out


def _n_battles(mean, rnd):
    n = int(mean)
    return n + (1 if rnd.random() < mean - n else 0)


def dive(data, tl, gid, level, profile='casual', teams=12, seed=130, walk='direct',
         step_index=None, team_list=None, reps=2):
    """A gate's maze floors in a row WITHOUT healing (HP and MP carry), then
    its boss fight(s): {'reach_boss', 'clear', 'battles' (mean per dive)}.
    walk 'direct' = straight to the stairs (lower bound), 'sweep' = the whole
    floor (upper bound)."""
    st = next((s for s in tl.steps if s['kind'] == 'gate' and s['id'] == gid), None)
    si = st['index'] if (st and step_index is None) else (step_index or len(tl.steps) - 1)
    floors = floor_battle_means(data, tl, gid)
    bosses = [tl.fights[k] for k in (st['fights'] if st else []) if tl.fights[k]['kind'] == 'boss']
    if st is None:
        bosses = [f for f in tl.fights.values() if f['key'].startswith(f'gate{gid}.boss')]
    idle = P.IdlePolicy('empirical', seed=seed)
    reach = clear = trials = 0
    nb = 0
    for t in range(teams if team_list is None else len(team_list)):
        team = team_list[t] if team_list is not None else team_for(data, tl, si, level,
                                                                   profile, t, seed)
        party = [party_dict(m) for m in team]
        pl = None
        if profile == 'player':
            from simulator import planner as PL
            pl = PL.make_planner(data.records)
        for rep in range(reps):
            rnd = random.Random(seed * 31 + t * 7 + rep)
            carry = [(p['hp'], p['mp']) for p in party]
            alive = True
            for f, direct, sweep in floors:
                for _k in range(_n_battles(direct if walk == 'direct' else sweep, rnd)):
                    nb += 1
                    w, _r, carry, _ne, _ac = battle_once(data, party, _pick_group(f, rnd),
                                                         0, rnd, idle, carry, planner=pl)
                    if w != 'party':
                        alive = False
                        break
                if not alive:
                    break
            trials += 1
            if not alive:
                continue
            reach += 1
            ok = True
            for bf in bosses:
                nb += 1
                w, _r, carry, _ne, _ac = battle_once(data, party, _pick_group(bf, rnd),
                                                     bf['db73'], rnd, idle, carry, planner=pl)
                if w != 'party':
                    ok = False
                    break
            clear += ok
    return {'reach_boss': reach / trials if trials else 0.0,
            'clear': clear / trials if trials else 0.0,
            'battles': nb / trials if trials else 0.0, 'walk': walk,
            'floors': len(floors)}


def dive_level_needed(data, tl, gid, profile='casual', target=WIN_TARGET, walk='direct',
                      teams=12, seed=130):
    """Smallest team level whose rolled teams clear the dive >= target."""
    memo = {}

    def ev(L):
        if L not in memo:
            memo[L] = dive(data, tl, gid, L, profile, teams, seed, walk)
        return memo[L]
    lv = first_level(lambda L: ev(L)['clear'] >= target)
    return lv, ev(lv if lv else 99)


# ---------------------------------------------------------------------------
# one search, both thresholds
# ---------------------------------------------------------------------------
def fight_levels(data, tl, fight, profile='casual', teams=12, battles=8, seed=130):
    """{'l90', 'l50', 'at90': evaluation at l90 (or at 99), 'probes'} — the
    smallest team level winning >= 90 % and >= 50 % (None = not even at 99),
    from one memoised set of evaluations."""
    memo = {}

    def ev(L):
        if L not in memo:
            memo[L] = evaluate(data, tl, fight, L, profile, teams, battles, seed)
        return memo[L]

    def search(target):
        return first_level(lambda L: ev(L)['win'] >= target)
    l90 = search(WIN_TARGET)
    l50 = search(WIN_HALF)
    return {'l90': l90, 'l50': l50, 'at90': ev(l90 if l90 else 99), 'probes': len(memo)}


# ---------------------------------------------------------------------------
# hand-made members / teams
# ---------------------------------------------------------------------------
def species_rows(data, sp):
    """Enemy rows of species `sp` that can join (joinability < 7), lowest
    level first; else every row of it."""
    rows = [(data.T.enemy(e)[4], e) for e in sorted(data.T.enemies)
            if data.T.enemy(e)[0] == sp and e <= 0x1FF]
    joinable = [r for r in rows if data.T.enemy(r[1])[3] != 7]
    return [e for _l, e in sorted(joinable or rows)]


def custom_member(data, species, level, skills=None, plus=0, seed=130, tier=0, eid=None):
    """A monster of `species` raised to `level` the way the game raises it
    (created from its lowest joinable enemy row, or `eid`), optionally with
    `plus` and a hand-picked skill list (<= 8)."""
    rows = [eid] if eid is not None else species_rows(data, species)
    if not rows:
        raise ValueError(f'no enemy row of species {species}')
    rng = random.Random(seed)
    m = R.create(data.T, rows[0], rng, arena_tier=tier)
    m.plus = plus
    R.grow_to(data.T, m, level, rng, 'strong', data.skill_value)
    if skills is not None:
        m.skills = [int(s) for s in skills][:8]
    m.origin = 'picked'
    return m


def team_summary(data, team):
    """[{name, nickname, species, level, cap, stats{}, skills[(id, name)],
    origin, plus, wld}] for display."""
    out = []
    for m in team:
        out.append({'name': m.name, 'nickname': getattr(m, 'nickname', ''),
                    'species': m.species, 'level': m.level, 'cap': m.cap,
                    'stats': dict(zip(('hp', 'mp', 'atk', 'def', 'agl', 'int'), m.stats)),
                    'skills': [(s, data.skill_names.get(s, f'#{s}')) for s in m.skills],
                    'origin': m.origin, 'plus': m.plus, 'wld': m.wld})
    return out


# ---------------------------------------------------------------------------
# the vanilla anchor + comparisons
# ---------------------------------------------------------------------------
def load_anchor(repo=None):
    path = os.path.join(repo or _REPO, ANCHOR_JSON)
    try:
        return json.load(open(path))
    except (OSError, ValueError):
        return None


def nearest_vanilla(anchor, level, profile='casual', n=3):
    """The vanilla story fights whose level-needed is closest to `level`
    (for 'this lands like …'): [(key, label, l90, step label)]."""
    if not anchor or level is None:
        return []
    rows = []
    for k, f in anchor['fights'].items():
        v = (f.get(profile) or {}).get('l90')
        if v is None:
            continue
        rows.append((abs(v - level), f['step'], k, f['label'], v, f['step_label']))
    rows.sort()
    return [(k, lab, v, sl) for _d, _s, k, lab, v, sl in rows[:n]]


# ---------------------------------------------------------------------------
# caching / fingerprints
# ---------------------------------------------------------------------------
def fight_fingerprint(data, tl, fight, profile, step=None):
    """What a fight's number depends on: its enemies' rows + skills' records,
    the roster at its step (rows, species info, curves, learn rows) —
    hashed, so a project recomputes only fights whose inputs changed."""
    h = hashlib.sha256()
    h.update(raising_digest(data).encode())
    h.update(json.dumps([fight['key'], fight['kind'], fight['db73'], profile,
                         [(round(p, 4), e) for p, e in fight['groups']]]).encode())
    for e in fight['eids']:
        h.update(data.T.enemy(e))
        if e in data.enemy_overrides:
            h.update(json.dumps(sorted(data.enemy_overrides[e].items())).encode())
        for s in data.T.enemy(e)[21:25]:
            r = data.records.get(s)
            if r:
                h.update(r['battle_record']['raw'].encode())
    si = fight['step'] if step is None else step
    ro = tl.roster(si if si is not None else len(tl.steps) - 1)
    h.update(json.dumps(ro).encode())
    for e in ro['joins']:
        row = data.T.enemy(e)
        h.update(row)
        h.update(data.T.info[row[0]])
    h.update(json.dumps([data.T.exp[REF_CURVE]]).encode())
    if profile == 'player':
        h.update(kit_fingerprint(data, tl, si if si is not None else len(tl.steps) - 1).encode())
    return h.hexdigest()[:20]


def raising_digest(data):
    """Everything a rolled team depends on besides its step's roster: species
    rows, exp curves, growth, learn rows, the breeding table, skill records,
    the simulator version. Memoised on the BattleData."""
    d = getattr(data, '_raising_digest', None)
    if d:
        return d
    h = hashlib.sha256(SIM_VERSION.encode())
    T = data.T
    for sp in sorted(T.info):
        h.update(bytes([sp & 0xFF, sp >> 8]) + bytes(T.info[sp]))
    for tab in (T.exp, T.growth):
        rows = tab.items() if isinstance(tab, dict) else enumerate(tab)
        h.update(json.dumps([[k, list(v)] for k, v in sorted(rows)]).encode())
    for i in sorted(T.learn):
        h.update(bytes([i & 0xFF, i >> 8]) + bytes(T.learn[i]))
    for sid in sorted(data.records):
        h.update(data.records[sid]['battle_record']['raw'].encode())
    h.update(json.dumps(sorted(data.core_alias.items())).encode())
    h.update(json.dumps(sorted((k, list(v)) for k, v in data.quake_range.items())).encode())
    br = _breeder(data)
    if br is not None:
        h.update(repr((br.family, br.special,
                       [br.fam_code(sp) for sp in sorted(T.info)])).encode())
    data._raising_digest = d = h.hexdigest()[:20]
    return d


# ---------------------------------------------------------------------------
# per-fight cache (a project's numbers)
# ---------------------------------------------------------------------------
class FightCache:
    """{fingerprint: result} in <project>/build/balance_cache.json — only
    fights whose inputs changed are recomputed."""

    def __init__(self, path):
        self.path = path
        try:
            self.d = json.load(open(path))
            if self.d.get('_sim') != SIM_VERSION:
                self.d = {}
        except (OSError, ValueError):
            self.d = {}
        self.d['_sim'] = SIM_VERSION
        self.dirty = False

    def get(self, fp):
        return self.d.get(fp)

    def put(self, fp, v):
        self.d[fp] = v
        self.dirty = True

    def save(self):
        if not self.dirty or not self.path:
            return
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        tmp = self.path + '.tmp'
        json.dump(self.d, open(tmp, 'w'), separators=(',', ':'))
        os.replace(tmp, self.path)
        self.dirty = False


def project_cache_path(project):
    root = getattr(project, 'root', None) or getattr(project, 'path', None)
    if root and os.path.isfile(root):
        root = os.path.dirname(root)
    return os.path.join(root, 'build', 'balance_cache.json') if root else None


def fight_result(data, tl, fight, profile='casual', cache=None, teams=12, battles=8, seed=130):
    """fight_levels for one fight, through the cache: {'l90', 'l50', 'at90',
    'probes', 'fp'}."""
    fp = fight_fingerprint(data, tl, fight, profile) + f':{teams}:{battles}:{seed}'
    if cache is not None:
        v = cache.get(fp)
        if v is not None:
            return v
    if profile == 'player':
        get_kit(data, tl, fight['step'] if fight['step'] is not None else len(tl.steps) - 1,
                cache)
    v = fight_levels(data, tl, fight, profile, teams, battles, seed)
    v['fp'] = fp
    if cache is not None:
        cache.put(fp, v)
    return v


def dive_cache_key(data, tl, gid, profile='casual', seed=130):
    """The FightCache key of a gate's dive (its floors' and boss fights'
    fingerprints + the walk means)."""
    h = hashlib.sha256(raising_digest(data).encode())
    for f, a, b2 in floor_battle_means(data, tl, gid):
        h.update(fight_fingerprint(data, tl, f, profile).encode())
        h.update(f'{a:.4f},{b2:.4f}'.encode())
    st = next((s for s in tl.steps if s['kind'] == 'gate' and s['id'] == gid), None)
    for k in (st['fights'] if st else []):
        h.update(fight_fingerprint(data, tl, tl.fights[k], profile).encode())
    return f'dive{gid}:{profile}:{seed}:' + h.hexdigest()[:20]


def cached_fight_result(data, tl, fight, profile='casual', cache=None, teams=12, battles=8,
                        seed=130):
    """fight_result's cached value, or None — never computes (the Balance
    tab shows what is known before anything runs)."""
    if cache is None:
        return None
    return cache.get(fight_fingerprint(data, tl, fight, profile) + f':{teams}:{battles}:{seed}')


def cached_dive_result(data, tl, gid, profile='casual', cache=None, seed=130):
    """gate_dive_result's cached value, or None — never computes."""
    if cache is None:
        return None
    return cache.get(dive_cache_key(data, tl, gid, profile, seed))


def gate_dive_result(data, tl, gid, profile='casual', cache=None, seed=130):
    """Both walk bounds of a gate's dive: {'direct': {level, eval},
    'sweep': {...}} — the team level at which a dive (all floors without
    healing, then the boss) succeeds 90 % of the time."""
    key = None
    if cache is not None:
        key = dive_cache_key(data, tl, gid, profile, seed)
        v = cache.get(key)
        if v is not None:
            return v
    out = {}
    if profile == 'player':
        st = next((s for s in tl.steps if s['kind'] == 'gate' and s['id'] == gid), None)
        get_kit(data, tl, st['index'] if st else len(tl.steps) - 1, cache)
    for walk in WALKS:
        lv, ev = dive_level_needed(data, tl, gid, profile, walk=walk, seed=seed)
        out[walk] = {'level': lv, 'eval': ev}
    if cache is not None:
        cache.put(key, out)
    return out


def first_level(ok, lo=1, hi=99):
    """The smallest level in lo..hi where ok(level) holds, found from BELOW:
    probe lo, 2lo, 4lo, … (then hi) up to the first success, then bisect
    between the last failure and it. A win rate that dips again at very
    high levels (a roster that only reaches its caps with odd teams) does
    not hide an earlier success. None = no probe succeeded."""
    prev, L = None, lo
    while True:
        if ok(L):
            break
        prev = L
        if L >= hi:
            return None
        L = min(hi, L * 2)
    if prev is None:
        return L
    a, b = prev, L
    while b - a > 1:
        m = (a + b) // 2
        if ok(m):
            b = m
        else:
            a = m
    return b
