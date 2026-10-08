#!/usr/bin/env python3
"""S130 RAISING MODEL — how the game makes and grows the player's monsters.

A line-for-line model of the four engine paths a player's monster goes
through (MONSTER_DATA "Raising a monster (S130)"; code-read S130, measured
by tools/census_raising.py against the real routines in PyBoy):

  create   bank $14 entry 2 `CreateMonsterRecord` ($40B4) — a monster that
           JOINS (wild, boss join row, gift): species / level copied, every
           stat word but AGL and the four AI bytes get the one-time creation
           roll v*m>>8, m = $CD + RNG mod $34; known skills = the row's four;
           learn queue (+$31, 25 B) = the species' three natural skills minus
           the bases of the known ones; max level = info cap + RNG mod 5 - 2;
           WLD = 5*level - 10*arena tier; exp snapped to the level.
  level up bank $50 / $51 post-battle: gains are computed at the OLD level
           (bank $13 `LevelUpGains` $40AE: growth curve[level]; HP and ATK get
           `PlusGrowthBonus` $4163 from level 14 on — four plus-gated rolls),
           then the learn scan runs with the OLD stats against the NEW level
           (bank $06 `SkillLearnScan` $4F9A), then the forget menu when more
           than 8, and only then `ApplyLevelUp` ($51:$5B31) adds the gains
           (caps 999 / 999 / 999 / 999 / 511 / 255) and level += 1. At or
           past the monster's max level the gains are SUBTRACTED
           (raw*level/100 + 1) — the exp walker stops paying at max level.
  learn    the scan: for each skill id 0..$D9 (then the project's custom ids):
           not already in the working list, NEW level >= row level, the six
           stats >= the row; then (a) in the learn queue -> learned (queue
           entry cleared), else (b) exactly one prereq known -> UPGRADE
           (replaces it), (c) several prereqs all known -> learned beside them.
  breed    bank $16 `BreedCreateOffspring` ($4015): level 1, plus, max level
           = cap + 2*plus (2..99); each stat = (both parents)/4 * (1 + k/50),
           k = pedigree members owned by another master; AI = the parents'
           average; resistances = the species' own, raised by plus-gated rolls
           on the parents' sum (`BreedResistRolls`); knows nothing; learn queue
           = own natural 3, parent species' natural 3 + 3, then both parents'
           known skills, each mapped through `UnevolvedSkillMap` ($FF = never
           inherited), first 25 distinct.

The data come from a `Tables` object (vanilla: extracted/gamedata_vanilla.json
through editor2/core/gamedata.py; a project: its resolved gamedata + custom
skills + project enemies). Never imports Qt. Every random draw goes through
the caller's `random.Random`.
"""
from __future__ import annotations

import os
import random
import sys
from dataclasses import dataclass, field

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

STATS = ('hp', 'mp', 'atk', 'def', 'agl', 'int')
STAT_CAP = (999, 999, 999, 999, 511, 255)       # AddMonsterHP..AddMonsterINT
PLUS_ROLLS = ((1, 19, 6), (10, 20, 8), (20, 30, 6), (50, 100, 5))   # (b, c, d)
PLUS_FROM_LEVEL = 14
LEVEL_MAX = 99
SKILLS_MAX = 8
QUEUE_LEN = 25
FF = 0xFF
VANILLA_LEARN_ROWS = 0xDA     # ids $00-$D9
# Rows the creator gives ANOTHER master's name (+$0C) — bank $14 Jump_014_4413:
# EIDs $131-$13C (the rival-species teams 305-316).
FOREIGN_MASTER_EIDS = frozenset(range(0x131, 0x13D))
GENDER_THRESHOLD = bytes([0x00, 0x1A, 0x80, 0xD6])   # BreedGenderThreshold $16:$44CC = $14:$459E


class GameRNG:
    """ROM0 `GenerateRNG`: the 16-bit state (wRNG1 = high, wRNG2 = low) steps
    x' = 5x + $1357. The raising routines step it once per draw and read
    RNG1 (`mod1`) or the word RNG2:RNG1 (`mod16`, Div16x8To16's remainder).
    Seeded per event from a random.Random by `rng_for`; pinned to the game's
    state by tools/census_raising.py, which makes the model exact."""

    def __init__(self, state=0):
        self.state = state & 0xFFFF

    def step(self):
        self.state = (self.state * 5 + 0x1357) & 0xFFFF

    @property
    def rng1(self):
        return self.state >> 8

    @property
    def rng2(self):
        return self.state & 0xFF

    def mod1(self, n):
        self.step()
        return self.rng1 % n

    def byte1(self):
        self.step()
        return self.rng1

    def mod16(self, n):
        self.step()
        return ((self.rng2 << 8) | self.rng1) % n


def rng_for(r):
    """A GameRNG for one event, seeded from random.Random `r` (or a GameRNG
    passed through unchanged)."""
    if isinstance(r, GameRNG):
        return r
    return GameRNG(r.getrandbits(16))


def creation_roll(v, rng):
    """SaveEnem_4821 / _47fd: v * m >> 8, m = $CD + RNG1 mod $34 (m = $100 keeps v)."""
    m = 0xCD + rng.mod1(0x34)
    return v if m == 0x100 else (v * m) >> 8


@dataclass
class Monster:
    species: int
    level: int
    cap: int
    exp: int
    stats: list            # [maxhp, maxmp, atk, def, agl, int]
    skills: list           # known, <= 8
    queue: list            # learn queue, <= 25 (no $FF holes kept)
    res: list              # 27 resistance levels 0-3
    ai: list               # 4 AI bytes in record order +$64..+$67
    plus: int = 0
    wld: int = 0
    female: int = 0
    origin: str = ''       # 'eid 123' / 'bred' / 'save slot n'
    name: str = ''
    foreign: int = 0       # 1 = its master (+$0C) is not the player (rival rows)
    bred: int = 0          # 1 = has a pedigree (+$15/+$16 set): its two parent
                           # NICKNAME slots (+$83 / +$8C) count in a child's k
    nickname: str = ''     # +$01 (a save's monster; editor display only)
    # S131 (the Balance service's time axis, editor2/core/balance.py — not game state):
    free_exp: int = 0      # the exp it arrived with (a joined monster: its row level's)
    grind: int = 0         # exp spent raising its ancestors to breeding level (bred)

    def copy(self):
        return Monster(self.species, self.level, self.cap, self.exp, list(self.stats),
                       list(self.skills), list(self.queue), list(self.res), list(self.ai),
                       self.plus, self.wld, self.female, self.origin, self.name,
                       self.foreign, self.bred, self.nickname, self.free_exp, self.grind)

    def as_dict(self):
        d = dict(species=self.species, level=self.level, cap=self.cap, exp=self.exp,
                 skills=list(self.skills), queue=list(self.queue), plus=self.plus,
                 wld=self.wld, ai=list(self.ai), origin=self.origin, name=self.name)
        d.update({s: v for s, v in zip(STATS, self.stats)})
        return d


class Tables:
    """What the raising model reads. info[sp] = the 43-byte MonsterInfoTable row;
    enemy(eid) = the 25-byte enemy row (vanilla, gamedata-edited or a project
    enemy); exp[c] / growth[c] = 99 values; learn[id] = the 18-byte learn row
    (only ids that have one; custom ids included); unevolved = 256 bytes."""

    def __init__(self, info, enemies, exp, growth, learn, unevolved, gender=(0, 0, 0, 0),
                 names=None, skill_names=None):
        self.info = info
        self.enemies = enemies
        self.exp = exp
        self.growth = growth
        self.learn = learn
        self.learn_ids = sorted(learn)
        self.unevolved = unevolved
        self.gender = gender
        self.names = names or {}
        self.skill_names = skill_names or {}

    def enemy(self, eid):
        return self.enemies[eid]

    def exp_to_reach(self, sp, level):
        """Cumulative exp at which `sp` reaches `level` (level 1 = 0)."""
        if level <= 1:
            return 0
        return self.exp[self.info[sp][2]][level - 1]

    def level_for_exp(self, sp, exp, cap=LEVEL_MAX):
        curve = self.exp[self.info[sp][2]]
        lv = 1
        while lv < min(cap, LEVEL_MAX) and exp >= curve[lv]:
            lv += 1
        return lv

    # ---- builders -----------------------------------------------------------
    @classmethod
    def from_gamedata(cls, g, project=None):
        """g = editor2.core.gamedata.Gamedata (vanilla when built from {}).
        project = an editor2 Project (custom skills' learn rows, project
        enemies, new species' info rows) or None."""
        info = {sp: bytes(r) for sp, r in enumerate(g.monster)}
        enemies = {eid: bytes(r) for eid, r in enumerate(g.enemy)}
        learn = {sid: bytes(r) for sid, r in enumerate(g.learn) if sid < VANILLA_LEARN_ROWS}
        names = dict(g.names)
        snames = dict(g.snames or {})
        if project is not None:
            from editor2.core import custom_skills as CS
            try:
                sk, _x, _w = CS.resolve(project)
                for sid, e in sk.items():
                    if e.get('learn') and e['learn'][0] != 0xFF:
                        learn[sid] = bytes(e['learn'])
                    try:
                        from editor2.core import monster_text as MT
                        snames[sid] = MT.decode(e['name']) if e.get('name') else snames.get(sid, f'#{sid}')
                    except Exception:
                        pass
            except Exception:
                pass
            for e in project.quest_enemy_rows():
                row = project_enemy_row(e, project)
                if row is not None:
                    enemies[e['_eid']] = row
            from editor2.core import species as SP
            for s in SP.resolve(project, with_art=False):
                info[s['id']] = bytes(s['info'])
                names[s['id']] = s['name']
        unevolved = unevolved_map()
        return cls(info, enemies, [list(c) for c in _curves(g.exp, 3)],
                   [list(c) for c in _curves(g.growth, 1)], learn, unevolved,
                   gender=GENDER_THRESHOLD, names=names, skill_names=snames)


def _curves(rows, width):
    out = []
    for r in rows:
        r = bytes(r)
        if width == 3:
            out.append([r[i] | r[i + 1] << 8 | r[i + 2] << 16 for i in range(0, 297, 3)])
        else:
            out.append(list(r[:99]))
    return out


_UNEV = None


def unevolved_map():
    """UnevolvedSkillMap ($16:$4496 area; same bytes at $14:$491D) — 256 B, from
    the clean disassembly source (never changed by patches)."""
    global _UNEV
    if _UNEV is None:
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        src = open(os.path.join(root, 'disassembly', 'bank_016.asm')).read()
        i = src.index('UnevolvedSkillMap:')
        vals = []
        for line in src[i:].split('\n')[1:]:
            s = line.strip()
            if not s.startswith('db'):
                break
            vals += [int(x.strip().lstrip('$'), 16) for x in s[2:].split(',')]
        assert len(vals) == 256
        _UNEV = bytes(vals)
    return _UNEV


_EGT = None


def enemy_gender_table():
    """EnemyGroupTable $14:$4A0F (526 B, index = EID): a fixed gender for a
    row ($00 male / $01 female), $FF = rolled at creation. Read from the
    clean source (never patched)."""
    global _EGT
    if _EGT is None:
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        src = open(os.path.join(root, 'disassembly', 'bank_014.asm')).read()
        i = src.index('\nEnemyGroupTable:')
        vals = []
        for line in src[i + 1:].split('\n')[1:]:
            t = line.split(';')[0].strip()
            if not t.startswith('db'):
                break
            vals += [int(x.strip().lstrip('$'), 16) for x in t[2:].split(',') if x.strip()]
        _EGT = bytes(vals)
    return _EGT


def project_enemy_row(e, project):
    """progression.enemies[] entry -> the 25-byte row bank $6B holds."""
    from editor2.core import emitters as EM
    try:
        return bytes(EM.enemy_row_bytes(e))
    except Exception:
        pass
    try:
        u = lambda v: int(v, 0) if isinstance(v, str) else int(v)        # noqa: E731
        sp = e.get('species')
        if isinstance(sp, str) and not sp.strip().lstrip('-').isdigit():
            return None
        row = bytearray(25)
        row[0] = u(sp)
        row[1:3] = u(e.get('exp', 0)).to_bytes(2, 'little')
        row[3] = u(e.get('joinability', 7))
        row[4] = u(e.get('level', 1))
        for i, s in enumerate(STATS):
            row[5 + 2 * i:7 + 2 * i] = u(e.get(s, 1)).to_bytes(2, 'little')
        ai = list(e.get('ai_weights', [100, 100, 100, 100]))[:4]
        row[17:21] = bytes(u(x) for x in ai)
        sk = [u(x) for x in (e.get('skills') or [])][:4]
        row[21:25] = bytes(sk + [FF] * (4 - len(sk)))
        return bytes(row)
    except Exception:
        return None


# ---------------------------------------------------------------------------
# create (bank $14 entry 2)
# ---------------------------------------------------------------------------
def create(T, eid, rng, arena_tier=0, origin=None):
    rng = rng_for(rng)
    row = T.enemy(eid)
    sp = row[0]
    info = T.info[sp]
    level = row[4]
    u = lambda o: row[o] | row[o + 1] << 8                       # noqa: E731
    stats = [creation_roll(u(5), rng), creation_roll(u(7), rng), creation_roll(u(9), rng),
             creation_roll(u(11), rng), u(13), creation_roll(u(15), rng)]
    # AI record order +$64..+$67 <- row +17, +18, +20, +19, each rolled
    ai = [creation_roll(row[17], rng), creation_roll(row[18], rng),
          creation_roll(row[20], rng), creation_roll(row[19], rng)]
    wld = max(0, min(255, 5 * level - 10 * arena_tier))
    cap = (info[1] + rng.mod1(5) - 2) & 0xFF
    skills = [s for s in row[21:25] if s != FF]
    queue = [s for s in info[6:9]]
    # SetEnem_47ad: a known $DB is dropped; a known skill's base leaves the queue
    known = []
    for s in row[21:25]:
        if s == FF:
            continue
        if s == 0xDB:
            continue
        known.append(s)
        b = T.unevolved[s]
        if b != FF:
            for i, q in enumerate(queue):
                if q != FF and q == b:
                    queue[i] = FF
                    break
    skills = known
    queue = [q for q in queue if q != FF]
    exp = T.exp_to_reach(sp, level) if level else 0
    egt = enemy_gender_table()
    fixed = egt[eid] if eid < len(egt) else FF
    if fixed != FF:
        female = fixed
    else:
        female = 1 if rng.byte1() < T.gender[info[3] & 3] else 0
    return Monster(sp, level, cap, exp, stats, skills, queue, list(info[15:42]), ai,
                   female=female,
                   plus=0, wld=wld, origin=origin or f'eid {eid}',
                   name=T.names.get(sp, f'#{sp}'),
                   foreign=int(eid in FOREIGN_MASTER_EIDS), free_exp=exp)


# ---------------------------------------------------------------------------
# level up (banks $13 / $06 / $51)
# ---------------------------------------------------------------------------
def gains(T, m, rng):
    """LevelUpGains at the monster's current level -> (gains[6], subtract)."""
    rng = rng_for(rng)
    info = T.info[m.species]
    lv = m.level
    at_cap = (m.cap - 1) & 0xFF < lv          # `ld a,cap / dec a / cp level / jr nc`
    out = []
    for i in range(6):
        raw = T.growth[info[9 + i]][min(lv, 98)]
        if at_cap:
            g = (raw * lv) // 100 + 1
        else:
            g = raw
            if i in (0, 2) and lv >= PLUS_FROM_LEVEL:
                for b, c, d in PLUS_ROLLS:
                    if m.plus >= rng.mod16(c) + b:
                        g = min(255, g + max(1, raw // d))
        out.append(g & 0xFF)
    return out, at_cap


def learn_scan(T, m, policy='casual', score=None, codes=None):
    """One level-up's learn pass (SkillLearnScan + the bank $51 caller) on
    the PRE-gain stats and NEW level. Mutates m.skills / m.queue. Returns the
    ids learned. More than 8 -> policy: 'casual' keeps the old 8 (the new
    ones are forgotten), 'strong' keeps the 8 with the best score."""
    work = list(m.skills)
    struct_known = set(m.skills)
    learned = []
    new_level = m.level + 1
    stats = m.stats
    while True:
        hit = None
        for c in T.learn_ids:
            if c in work:
                continue
            row = T.learn[c]
            if new_level < row[0]:
                continue
            ok = True
            for i in range(6):
                if stats[i] < (row[1 + 2 * i] | row[2 + 2 * i] << 8):
                    ok = False
                    break
            if not ok:
                continue
            if c in m.queue:
                m.queue[m.queue.index(c)] = FF
                hit = (c, 0, None)
                break
            pre = [x for x in row[13:18]]
            if pre[0] == FF:
                continue
            known_all = True
            n = 0
            for x in pre:
                if x == FF:
                    break
                n += 1
                if x not in struct_known:
                    known_all = False
                    break
            if not known_all:
                continue
            hit = (c, 1, pre[0]) if n == 1 else (c, 2, None)
            break
        if hit is None:
            break
        c, code, old = hit
        learned.append(c)
        if codes is not None:
            codes.append(code)
        if code == 1 and old in work:
            work[work.index(old)] = c
        else:
            work.append(c)
    m.queue = [q for q in m.queue if q != FF]
    if len(work) > SKILLS_MAX:
        if policy == 'strong' and score is not None:
            keep = sorted(work, key=lambda s: -score(s))[:SKILLS_MAX]
            work = [s for s in work if s in keep]
        else:
            work = work[:SKILLS_MAX]
    m.skills = work
    return learned


def apply_gains(m, g, subtract):
    for i in range(6):
        if subtract:
            m.stats[i] = max(1, m.stats[i] - g[i])
        else:
            m.stats[i] = min(STAT_CAP[i], m.stats[i] + g[i])
    if m.level < LEVEL_MAX:
        m.level += 1


def level_up(T, m, rng, policy='casual', score=None):
    g, sub = gains(T, m, rng)
    learn_scan(T, m, policy, score)
    apply_gains(m, g, sub)
    return g, sub


def grow_to(T, m, level, rng, policy='casual', score=None):
    """Level m up to `level` (never past its max level — the exp walker stops
    paying there). Exp follows the curve."""
    target = min(level, m.cap, LEVEL_MAX)
    while m.level < target:
        level_up(T, m, rng, policy, score)
    m.exp = max(m.exp, T.exp_to_reach(m.species, m.level))
    return m


def grow_by_exp(T, m, exp_gain, rng, policy='casual', score=None):
    """Give m `exp_gain` more exp (paid only below its max level), level it up."""
    m.exp += exp_gain
    curve = T.exp[T.info[m.species][2]]
    while m.level < min(m.cap, LEVEL_MAX) and m.exp >= curve[m.level]:
        level_up(T, m, rng, policy, score)
    return m


# ---------------------------------------------------------------------------
# breed (bank $16 entry 0)
# ---------------------------------------------------------------------------
RESIST_ROLLS_LOW = {3: [(100, 0)], 4: [(30, 0)], 5: [(10, 0), (30, 0)], 6: [(0, 1), (20, 0)]}
RESIST_ROLLS_TWO = {5: [(200, 0)], 6: [(40, 0)]}


def _roll_lt(rng, n, plus):
    return rng.mod16(n) < plus


def pedigree_k(p1, p2):
    """FuncBrd_4313: how many of the six pedigree names differ from the
    player's: each parent's master (+$0C), and for a bred parent the two
    names it keeps of ITS parents (+$83 / +$8C) — which LoadBrd_4238 fills
    with their NICKNAMES (+$01), so a bred parent counts 2 unless a parent
    was nicknamed exactly like the player (measured S130)."""
    return p1.foreign + 2 * p1.bred + p2.foreign + 2 * p2.bred


def breed(T, p1, p2, species, plus, rng, foreign=None):
    """Offspring of pedigree p1 x mate p2 (Monsters) as `species` + `plus`
    (the resolver's answer: editor2/core/breeding.py). foreign = the k of
    FuncBrd_4313 (default: pedigree_k); each stat gets +k/50."""
    if foreign is None:
        foreign = pedigree_k(p1, p2)
    rng = rng_for(rng)
    info = T.info[species]
    plus = min(plus, 99)
    cap = max(2, min(99, info[1] + 2 * plus))
    stats = []
    for i in range(6):
        s = (p1.stats[i] + p2.stats[i]) >> 2
        v = s + (s * foreign) // 50
        stats.append(v if v else 1)
    # SaveBrd_41ff: `add c / ld c,a / ld a,$00 / add b` drops the carry (a
    # vanilla bug, measured S130): the average of the low byte of the sum
    ai = [((a + b) & 0xFF) >> 1 for a, b in zip(p1.ai, p2.ai)]
    res = list(info[15:42])
    for i in range(27):
        own = res[i]
        if own == 3:
            continue
        s = (p1.res[i] + p2.res[i]) & 7
        if own == 2:
            for n, _f in RESIST_ROLLS_TWO.get(s, []):
                if _roll_lt(rng, n, plus) and res[i] != 3:
                    res[i] += 1
            continue
        for n, force in RESIST_ROLLS_LOW.get(s, []):
            if force or _roll_lt(rng, n, plus):
                if res[i] != 2:
                    res[i] += 1
    queue = []

    def inherit(ids):
        for s in ids:
            if s == FF:
                continue
            b = T.unevolved[s]
            if b == FF or b in queue or len(queue) >= QUEUE_LEN:
                continue
            queue.append(b)
    inherit(info[6:9])
    inherit(T.info[p1.species][6:9])
    inherit(T.info[p2.species][6:9])
    inherit(p1.skills)
    inherit(p2.skills)
    female = 1 if rng.byte1() < T.gender[info[3] & 3] else 0
    return Monster(species, 1, cap, 0, stats, [], queue, res, ai, plus=plus, wld=0,
                   female=female, origin='bred', name=T.names.get(species, f'#{species}'),
                   foreign=0, bred=1)


def birth(T, egg, p1, p2, rng=None):
    """Bank $16 entry 4 (BreedBirthFinalize, run by the ceremony's op $3A and
    the bank $0A hatch menu): master := the player, WLD := 0, egg flag off,
    and the learn queue rebuilt = own natural 3, the FATHER's species' natural
    3, the mother's (+$15 / +$16: the pedigree first unless it is female),
    then the old queue — each through UnevolvedSkillMap, first 25 distinct.
    Its plus-gated "keep" roll per queue entry is dead (an unconditional `jr`
    skips the compare) — it only steps the RNG 25 times."""
    m = egg
    father, mother = (p2, p1) if p1.female & 1 else (p1, p2)
    old = list(m.queue)
    q = []

    def add(ids):
        for s in ids:
            if s == FF:
                continue
            b = T.unevolved[s]
            if b == FF or b in q or len(q) >= QUEUE_LEN:
                continue
            q.append(b)
    add(T.info[m.species][6:9])
    add(T.info[father.species][6:9])
    add(T.info[mother.species][6:9])
    add(old)
    m.queue = q
    m.wld = 0
    m.foreign = 0
    return m


def breed_and_birth(T, p1, p2, species, plus, rng, foreign=None):
    egg = breed(T, p1, p2, species, plus, rng, foreign)
    return birth(T, egg, p1, p2)


# ---------------------------------------------------------------------------
# convenience
# ---------------------------------------------------------------------------
def vanilla_tables(repo=None):
    from editor2.core import gamedata as G
    root = repo or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return Tables.from_gamedata(G.Gamedata({}, root))


def project_tables(project):
    return Tables.from_gamedata(project.gamedata(), project)


if __name__ == '__main__':
    T = vanilla_tables()
    r = random.Random(1)
    m = create(T, 2, r)
    print(m)
    grow_to(T, m, 20, r)
    print(m)
