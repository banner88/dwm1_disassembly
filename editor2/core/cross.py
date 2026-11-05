"""cross.py — the BABY of a cross (S169; the Breeding tab's "Try a cross" page).

ROADMAP P3.12 residual (a): "the offspring's skills / stats in Try a cross". The rules
were decoded and measured in S130 — `simulator/raising.py` (`breed` / `birth` /
`learn_scan` / `gains`) == the game's own routines (tools/census_raising.py: 400 breeds,
400 second-generation breeds, 400 births, 5,073 level-ups, 0 mismatches; MONSTER_DATA
"Raising a monster (S130)"). This module only ASKS that model and explains the answer:

  * the parents: a monster from a battery save (.sav — every byte the breeding reads is
    the save's own record) or a TYPICAL one (`typical_parent`: made from the species'
    lowest joinable enemy row the way a join makes it — bank $14 `CreateMonsterRecord` —
    and levelled the game's way; more than 8 skills -> it keeps the first 8);
  * the egg (bank $16 `BreedCreateOffspring`): max level = cap + 2 x plus; each stat =
    (pedigree + mate) / 4, + k x 2 % (k = `PedigreeForeignCount`: how many of the six
    pedigree names are not the player's, `pedigree_k_of_records` from a save); the AI
    weights = the parents' average with the game's dropped carry (a sum over 255 wraps:
    two 200s give 72); resistances = the species' own, raised by plus-gated rolls; it
    knows NOTHING — its LEARN QUEUE (<= 25) = its own natural 3, the pedigree's kind's 3,
    the mate's kind's 3, then everything the pedigree knew, then the mate — each skill
    turned into the bottom of its chain (`UnevolvedSkillMap`; $FF = never passed on);
  * the birth (bank $16 `BreedBirthFinalize`): the queue re-ordered (own 3, the father's
    kind's, the mother's, then the rest) — same skills;
  * the TIMELINE: the newborn raised from level 1 to its max level with the game's own
    level-up (`gains` -> `learn_scan` on the pre-gain stats -> `apply_gains`), every skill
    it is OFFERED (as if the player never forgot one: `max_known`), with the level.

Chances (gender, each resistance) are counted over many runs of the game's RNG
(`CHANCE_RUNS`), the stats / queue / max level are exact (no randomness in them). The
timeline's stats use one fixed seed for the plus-gated HP / ATK bonus rolls (level 14+).

Never imports Qt.
"""
from __future__ import annotations

import os
import random
import sys

_REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if _REPO not in sys.path:
    sys.path.insert(0, _REPO)

from simulator import raising as R            # noqa: E402

FF = 0xFF
CHANCE_RUNS = 2000
TIMELINE_SEED = 169
TYPICAL_SEED = 130
STAT_NAMES = ('HP', 'MP', 'ATK', 'DEF', 'AGL', 'INT')
AI_NAMES = ('Damage', 'Heal/support', 'Status', 'Obedience')   # gamedata.AI_WEIGHT_NAMES
# the record's AI bytes +$64..+$67 in the order the editor names them (raising.create:
# record order = row +17, +18, +20, +19 -> the names of row +17..+20 are G.AI_WEIGHT_NAMES)
AI_RECORD_TO_NAME = (0, 1, 3, 2)
PLAYER_NAME_OFF = 0x17C      # SRAM offset of wPlayerName $CA42 ($CA42 - $C8EA + $24)
NAME_LEN = 9                 # PedigreeNameDiffers compares 9 bytes

SRC_OWN = 'its own kind'
SRC_P1_KIND = "the pedigree's kind"
SRC_P2_KIND = "the mate's kind"
SRC_P1_KNEW = 'the pedigree knew'
SRC_P2_KNEW = 'the mate knew'

ST_ADDED = 'added'
ST_DUP = 'already in'
ST_NEVER = 'never passed on'
ST_CUT = 'queue full (25)'


# ---------------------------------------------------------------------------
# tables
# ---------------------------------------------------------------------------
def tables(project):
    """raising.Tables of a project (editor2.core.project.Project) — its edited
    species rows, curves, learn rows, custom skills, project enemies, new species."""
    return R.project_tables(project)


def skill_name(T, sid):
    return T.skill_names.get(sid, f'#{sid}')


# ---------------------------------------------------------------------------
# parents
# ---------------------------------------------------------------------------
def joinable_rows(T, species):
    """The enemy rows of `species` that can join (joinability < 7), lowest level
    first; else any row of it (vanilla EIDs first, then project rows). Rows of level 0
    are skipped (EID 0, the empty row)."""
    # EID 0 is the empty row (all zero: species 0 = DrakSlime at level 0) — never a monster
    rows = [(T.enemy(e)[4], e) for e in sorted(T.enemies)
            if T.enemy(e)[0] == species and T.enemy(e)[4] > 0]
    van = [r for r in rows if r[1] <= 0x1FF]
    rows = van or rows
    join = [r for r in rows if T.enemy(r[1])[3] != 7]
    return [e for _l, e in sorted(join or rows)]


def typical_parent(T, species, level, plus=0, seed=TYPICAL_SEED):
    """A parent the way the game makes one: created from its lowest joinable enemy
    row (`raising.create`, the join path) and levelled to `level` (never past its max
    level); more than 8 skills -> it keeps the first 8 (no forget-menu choices).
    A species with no enemy row at all (only breeding makes it) is grown from level 1
    with its growth curves — `how` says so."""
    rng = random.Random(seed)
    rows = joinable_rows(T, species)
    if rows:
        m = R.create(T, rows[0], rng)
        how = f'joined from enemy row {rows[0]} (level {m.level}), raised to level {level}'
        if m.level > level:
            how = f'joined from enemy row {rows[0]} at level {m.level} (its lowest)'
    else:
        info = T.info[species]
        m = R.Monster(species, 1, max(2, info[1]), 0, [1] * 6, [], [s for s in info[6:9]
                      if s != FF], list(info[15:42]), [100, 100, 100, 100],
                      name=T.names.get(species, f'#{species}'))
        how = f'no enemy row of it — grown from level 1 to level {level} with its curves'
    m.plus = plus
    R.grow_to(T, m, level, rng)
    m.origin = 'typical'
    return m, how


def player_name(sav):
    return bytes(sav[PLAYER_NAME_OFF:PLAYER_NAME_OFF + NAME_LEN])


def save_record(sav, slot):
    from editor2.core import savefile as SF
    o = SF.record_offset(slot)
    return bytes(sav[o:o + SF.REC])


def pedigree_k_of_records(r1, r2, player):
    """bank $16 `PedigreeForeignCount` on two 149-byte records: each parent's master
    name (+$0C) and, when it has a pedigree (+$15 / +$16 != $FF), the two names it keeps
    of ITS parents (+$83 / +$8C), 9 bytes each against the player's name."""
    return names_not_yours(r1, player) + names_not_yours(r2, player)


def names_not_yours(r, player):
    """One parent's share of k (0-3): its master's name, and its own parents' two
    names when it has a pedigree, that differ from the player's (9 bytes each)."""
    k = 0
    if bytes(r[0x0C:0x0C + NAME_LEN]) != player:
        k += 1
    if r[0x15] != FF and bytes(r[0x83:0x83 + NAME_LEN]) != player:
        k += 1
    if r[0x16] != FF and bytes(r[0x8C:0x8C + NAME_LEN]) != player:
        k += 1
    return k


def default_k(p1, p2):
    """k for parents that are not from a save: `raising.pedigree_k` (a typical parent
    is the player's own joined monster: 0)."""
    return R.pedigree_k(p1, p2)


# ---------------------------------------------------------------------------
# the baby
# ---------------------------------------------------------------------------
def queue_sources(T, egg_species, p1, p2):
    """The learn-queue pass of `BreedCreateOffspring`, explained: [(source, skill id,
    base id or None, status)] in the order the game reads them. status: ST_ADDED /
    ST_DUP / ST_NEVER / ST_CUT."""
    out, queue = [], []

    def run(src, ids):
        for s in ids:
            if s == FF:
                continue
            b = T.unevolved[s]
            if b == FF:
                out.append((src, s, None, ST_NEVER))
            elif b in queue:
                out.append((src, s, b, ST_DUP))
            elif len(queue) >= R.QUEUE_LEN:
                out.append((src, s, b, ST_CUT))
            else:
                queue.append(b)
                out.append((src, s, b, ST_ADDED))
    run(SRC_OWN, T.info[egg_species][6:9])
    run(SRC_P1_KIND, T.info[p1.species][6:9])
    run(SRC_P2_KIND, T.info[p2.species][6:9])
    run(SRC_P1_KNEW, p1.skills)
    run(SRC_P2_KNEW, p2.skills)
    return out


def timeline(T, baby, seed=TIMELINE_SEED, trace=None):
    """Raise a copy of the newborn from level 1 to its max level the game's way and
    list every skill it is offered: [(level reached, skill id, how, old id)] — how:
    'queue' (from its learn queue), 'upgrade' (replaces `old`), 'combination' (2-5
    skills all known). The 9th+ known skill would open the forget menu in the game.
    trace (a list) receives (level, RNG state before the gains) per level-up — what
    tools/walk_cross.py pins in the game to replay the same level-ups."""
    m = baby.copy()
    rng = R.GameRNG(seed)
    out = []
    while m.level < min(m.cap, R.LEVEL_MAX):
        if trace is not None:
            trace.append((m.level, rng.state))
        g, sub = R.gains(T, m, rng)
        codes = []
        got = R.learn_scan(T, m, codes=codes, max_known=255)
        for c, code in zip(got, codes):
            old = T.learn[c][13] if code == 1 else None
            out.append((m.level + 1, c, ('queue', 'upgrade', 'combination')[code], old))
        R.apply_gains(m, g, sub)
    return out, m


def chances(T, p1, p2, species, plus, k, runs=CHANCE_RUNS, seed=TIMELINE_SEED):
    """Over `runs` eggs (the game's RNG from random states): P(female) and, per
    resistance type, the share of eggs at each level 0-3."""
    rnd = random.Random(seed)
    fem = 0
    res = [[0, 0, 0, 0] for _ in range(27)]
    for _ in range(runs):
        egg = R.breed(T, p1, p2, species, plus, R.GameRNG(rnd.getrandbits(16)), foreign=k)
        fem += egg.female & 1
        for i, v in enumerate(egg.res):
            res[i][min(3, v)] += 1
    return fem / runs, [[n / runs for n in r] for r in res]


def baby(T, p1, p2, species, plus, k=None):
    """Everything the game makes of pedigree p1 x mate p2 -> species +plus (the
    resolver's answer). -> dict (see the module doc)."""
    if k is None:
        k = default_k(p1, p2)
    egg = R.breed(T, p1, p2, species, plus, R.GameRNG(0), foreign=k)
    sources = queue_sources(T, species, p1, p2)
    born = R.birth(T, egg.copy(), p1, p2)
    first_src = {}
    for src, s, b, st in sources:
        if st == ST_ADDED:
            first_src[b] = (src, s)
    tl, grown = timeline(T, born)
    learned_at = {}
    for lv, c, how, _old in tl:
        learned_at.setdefault(c, lv)
    p_fem, res = chances(T, p1, p2, species, plus, k)
    # stats, explained: s = (p1 + p2) >> 2, + s*k // 50
    stats = []
    for i in range(6):
        s = (p1.stats[i] + p2.stats[i]) >> 2
        stats.append((STAT_NAMES[i], p1.stats[i], p2.stats[i], s, egg.stats[i]))
    ai = []
    for j, name in enumerate(AI_NAMES):
        i = AI_RECORD_TO_NAME[j]
        a, b = p1.ai[i], p2.ai[i]
        ai.append((name, a, b, egg.ai[i], (a + b) > 0xFF))
    own_res = list(T.info[species][15:42])
    rises = []
    for i in range(27):
        up = sum(res[i][v] for v in range(own_res[i] + 1, 4))
        if up > 0:
            rises.append((i, own_res[i], up, res[i]))
    return {
        'species': species, 'plus': plus, 'k': k,
        'cap': egg.cap, 'info_cap': T.info[species][1],
        'stats': stats, 'ai': ai, 'female': p_fem,
        'resist_rises': rises, 'resist_own': own_res,
        'sources': sources, 'queue': list(born.queue), 'queue_src': first_src,
        'timeline': tl, 'learned_at': learned_at, 'grown': grown,
        'egg': egg, 'born': born,
    }
