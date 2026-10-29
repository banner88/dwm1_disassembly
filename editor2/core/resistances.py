"""resistances.py — S159 (ROADMAP E16): the 27 resistances as the editor shows them.

What a resistance does is the game's (BATTLE_SKILL_SYSTEM §15.3 / §15.11): every
monster (party AND enemy — enemies use their SPECIES row, gamedata.monsters) has a
level 0-3 per resistance (0 = none, 3 = immune); a skill's damage or hit roll reads
ONE resistance of its target through one ladder. This module is the single place
that says, for the project as it stands:

  * GROUPS — the 27 types in the editor's order (elemental spells, breaths, status
    ailments, stat down / drain, seals, special attacks);
  * TYPES[i] — a type's stored name (gamedata.RESIST_NAMES — the community FAQ's
    names; project.json keys), a short subtitle and what it protects against;
  * LADDERS — what a level does through each ladder (measured, simulator-validated);
  * skill_rows(doc) / by_type(doc) — which skill tests which resistance NOW: the
    stock damage skills from the measured census (extracted/skill_element_census.json)
    with the project's element edits, the stock status / hit skills from the
    simulator's helper tables (measured S130, not editable — the handler picks the
    resistance), the project's NEW skills (239-254: the element, or their base
    skill's), and the built-in custom skills (their element; none by default).

Earth (index 26) is new in S159: until then "Unused" (0 in every species). Patched
builds pack it into battle position 27 (bank $51 SaveBtlS_4404) — the same element
rule as every other type — and record +$82 shares it with the memorial's tag.
Nothing in the original game tests Earth; skills get it by their element.
"""
from . import gamedata as G

EARTH = G.EARTH

# (key, title, [resistance indices]) — the editor's grouping (user S159: "Grouping good")
GROUPS = [
    ('elemental', 'Elemental spells', [0, 1, 2, 3, 4, 5, 26]),
    ('breath', 'Breaths', [16, 17]),
    ('status', 'Status ailments', [7, 11, 18, 19, 20, 6, 21, 8]),
    ('stat', 'Stat down / drain', [12, 13, 9]),
    ('seal', 'Seals', [10, 22, 23]),
    ('special', 'Special attacks', [14, 15, 25, 24]),
]
ORDER = [t for _k, _t, ts in GROUPS for t in ts]
GROUP_OF = {t: k for k, _t, ts in GROUPS for t in ts}
GROUP_TITLE = {k: t for k, t, _ts in GROUPS}

# index -> (subtitle, what it protects against). The stored names stay the FAQ's.
TYPES = {
    0: ('Blaze line', 'Blaze / Blazemore / Blazemost (the "Gira" spells), FireSlash, BigBang. '
                      'Not the same as Heat: the game keeps fireballs apart.'),
    1: ('Firebal line', 'Firebal / Firebane / Firebolt (the "Mera" fireballs). A separate '
                        'resistance from Fire in the game.'),
    2: ('Bang line', 'Bang / Boom / Explodet — explosions.'),
    3: ('Infernos line', 'Infernos / Infermore / Infermost, Vacuum, WindBeast, VacuSlash, '
                         'MultiCut — wind blades.'),
    4: ('Bolt line', 'Bolt / Zap / Thordain, Lightning, Hellblast, BoltSlash — lightning.'),
    5: ('IceBolt line', 'IceBolt / SnowStorm / Blizzard, IceSlash — ice spells.'),
    6: ('blinding', 'Surround, SandStorm, Radiant — blinding (attacks miss more).'),
    7: ('sleep', 'Sleep, SleepAll, SleepAir, NapAttack (its rider).'),
    8: ('instant death', 'Beat, Defeat, K.O.Dance, EerieLite; UltraDown rolls it too.'),
    9: ('MP drain', 'RobMagic, RobDance, OddDance — MP stolen.'),
    10: ('spell seal', 'StopSpell — no spells.'),
    11: ('confusion', 'PanicAll, PaniDance — confusion.'),
    12: ('DEF down', 'Sap, Defence, SickLick — defence lowered.'),
    13: ('AGL down', 'Slow, SlowAll — agility lowered.'),
    14: ('self-sacrifice', 'Sacrifice, Kamikaze, Ramming.'),
    15: ('MegaMagic', 'MegaMagic only.'),
    16: ('fire breath', 'FireAir / BlazeAir / Scorching / WhiteFire.'),
    17: ('ice breath', 'FrigidAir / IceAir / IceStorm / WhiteAir.'),
    18: ('poison', 'PoisonGas, PoisonAir, PoisonHit (its rider).'),
    19: ('paralysis', 'PalsyAir, Paralyze (its rider).'),
    20: ('curse', 'Curse.'),
    21: ('lose a turn', 'LureDance, LushLicks, LegSweep, BigTrip, WarCry, Ahhh — the target '
                        'misses its turn.'),
    22: ('dance seal', 'DanceShut — no dances.'),
    23: ('breath seal', 'MouthShut — no breaths.'),
    24: ('helpers / rocks', 'RockThrow, and the helpers CallHelp / YellHelp bring.'),
    25: ('GigaSlash', 'GigaSlash only.'),
    26: ('quakes (new, S159)', 'Nothing in the original game tests it. Give a skill the '
                               'Earth element (Skills tab → Element) — Tremor / Quake / '
                               'QuakeMore / QuakeMost or a new skill — and it reads Earth.'),
}


def label(t):
    """'Fire (Blaze line)' — the stored name with its subtitle."""
    return f'{G.RESIST_NAMES[t]} ({TYPES[t][0]})'


# ---------------------------------------------------------------------------
# ladders: what levels 0 / 1 / 2 / 3 do (target without guard / amplify marks)
# ---------------------------------------------------------------------------
# damage ladders (x the damage) — BATTLE_SKILL_SYSTEM §15.3 (simulator/damage.py)
# hit ladders (the chance to land) — §15.3 / §15.11.F1 (RNG1 < T after one step)
LADDERS = {
    'spell': ('damage', ['×1', '×0.85', '×0.5', '×0 (immune)']),
    'breath': ('damage', ['×1', '×0.75', '×0.4', '×0 (immune)']),
    'slash': ('damage', ['×1.31', '×1.16', '×0.75', '×0.3']),      # the amplify row (no guard)
    'hit': ('chance', ['always', '84 %', '50 %', 'never']),        # CheckTargetGuardB $52:$6710
    'status': ('chance', ['75 %', '50 %', '25 %', 'never']),       # HitLadderBeat $52:$6749
    'kamikaze': ('chance', ['always', '75 %', '40 %', 'never']),   # HitLadderKamikaze $52:$6733
    'sacrifice': ('chance', ['works', 'works', '75 % (then the kill roll)', 'never']),
}
LADDER_TITLE = {'spell': 'spell damage', 'breath': 'breath damage',
                'slash': 'elemental slash (a physical hit)', 'hit': 'hit chance',
                'status': 'hit chance (status ladder)', 'kamikaze': 'hit chance (Kamikaze '
                'ladder)', 'sacrifice': 'Sacrifice\'s own rule'}
_CENSUS_LADDER = {'spell': 'spell', 'breath': 'breath', 'slash': 'slash'}


def _status_table():
    """{stock skill id: (resistance, ladder)} for the skills whose HANDLER picks the
    resistance of a hit roll (measured S130; the simulator's tables are the source)."""
    out = {}
    try:
        from simulator.skillfx import f1_status as F1
        for sk in range(222):
            h = F1._helper(sk)
            if h:
                rt, kind, _c, _g = h
                out[sk] = (rt, {'S': 'status', 'B': 'hit', 'K': 'kamikaze'}[kind])
    except Exception:                                   # noqa: BLE001 — a bare checkout
        pass
    try:
        from simulator import battle as SB
        for sk, rt in SB.RIDER_RTYPE.items():          # PoisonHit / NapAttack / Paralyze
            out.setdefault(sk, (rt, 'status'))
    except Exception:                                   # noqa: BLE001
        pass
    out.update({0x1C: (12, 'hit'), 0x1D: (12, 'hit'),               # Sap / Defence (F7)
                0x20: (13, 'hit'), 0x21: (13, 'hit'),               # Slow / SlowAll
                0x82: (8, 'kamikaze'),                              # UltraDown (Death)
                0x1A: (9, 'hit'), 0x75: (9, 'hit'), 0x76: (9, 'hit'),   # MP drain (F5)
                0x14: (14, 'sacrifice'), 0x3E: (14, 'kamikaze'),    # Sacrifice / Kamikaze
                0x52: (24, 'spell'), 0x53: (24, 'spell')})          # CallHelp / YellHelp helpers
    out.pop(0xDA, None)                                 # LIFE: an internal row
    return out


_STATUS = None


def status_table():
    global _STATUS
    if _STATUS is None:
        _STATUS = _status_table()
    return _STATUS


def _census(repo):
    """{stock id: [(ladder, element)]} for the skills whose damage reaches a ladder
    (the census lists every skill; an empty list = no ladder)."""
    from . import custom_skills as CS
    return {k: v for k, v in CS.element_census(repo).items() if v}


def skill_rows(doc):
    """Every skill of the project that tests a resistance, or could (damage skills
    without one too): [{'sid', 'name', 'type' (0-26 | None = tests none),
    'ladder', 'origin' ('game' | 'changed' | 'new' | 'built-in'), 'editable',
    'native' (the game's own type or None), 'via' (a new skill's base name)}]."""
    from . import custom_skills as CS
    repo = getattr(doc, 'repo_root', None)
    names = doc.skill_names_effective()
    census = _census(repo)
    status = status_table()
    data = doc.data
    try:
        stock_el = CS.stock_elements(data)
    except Exception:                                   # noqa: BLE001
        stock_el = [CS.NO_ELEMENT] * CS.STOCK
    rows = []
    for sid in range(CS.STOCK):
        if sid in census:
            lad, nat = census[sid][0]
            el = stock_el[sid]
            if el == CS.NO_ELEMENT:
                t, origin = nat, 'game'
            else:
                t, origin = (None if el == CS.ELEMENT_NONE else el), 'changed'
            rows.append({'sid': sid, 'name': names.get(sid, f'#{sid}'), 'type': t,
                         'ladder': _CENSUS_LADDER.get(lad, 'spell'), 'origin': origin,
                         'editable': True, 'native': nat, 'via': None})
        elif sid in status:
            rt, lad = status[sid]
            rows.append({'sid': sid, 'name': names.get(sid, f'#{sid}'), 'type': rt,
                         'ladder': lad, 'origin': 'game', 'editable': False, 'native': rt,
                         'via': None})
    try:
        sk, _x, _w = CS.resolve(data, repo)
    except Exception:                                   # noqa: BLE001 — the compiler reports it
        sk = {}
    for sid in sorted(sk):
        e = sk[sid]
        el = e.get('element', CS.NO_ELEMENT)
        nm = names.get(sid, f'#{sid}')
        b = e.get('base')
        if b is not None:                               # a NEW skill on a stock base
            b = int(b)
            via = names.get(b, f'#{b}')
            if b in census:
                lad, nat = census[b][0]
                t = nat if el == CS.NO_ELEMENT else (None if el == CS.ELEMENT_NONE else el)
                rows.append({'sid': sid, 'name': nm, 'type': t,
                             'ladder': _CENSUS_LADDER.get(lad, 'spell'), 'origin': 'new',
                             'editable': True, 'native': nat, 'via': via})
            elif b in status:
                rt, lad = status[b]
                rows.append({'sid': sid, 'name': nm, 'type': rt, 'ladder': lad,
                             'origin': 'new', 'editable': False, 'native': rt, 'via': via})
        elif e.get('handler') in CS.DAMAGE_HANDLERS:     # a built-in that deals damage
            t = None if el in (CS.NO_ELEMENT, CS.ELEMENT_NONE) else el
            rows.append({'sid': sid, 'name': nm, 'type': t, 'ladder': 'spell',
                         'origin': 'built-in', 'editable': True, 'native': None, 'via': None})
    return rows


def by_type(doc):
    """{0-26 | None: [skill rows]} (None = damage skills that test no resistance)."""
    out = {t: [] for t in ORDER}
    out[None] = []
    for r in skill_rows(doc):
        out.setdefault(r['type'], []).append(r)
    return out


def level_counts(rows_by_species, t):
    """[n at level 0, 1, 2, 3] over {sid: info row}."""
    c = [0, 0, 0, 0]
    for row in rows_by_species.values():
        c[row[15 + t] & 3] += 1
    return c
