#!/usr/bin/env python3
"""S86 TTK sweep — time-to-kill statistics over gate encounter pools,
driven by the aggregate-validated pacing layer (simulator/pacing.py,
simulator/validate_pacing.py).

Reads any ROM build (vanilla / romhack / randomized) through
randomizer.romdata.Rom, so the same sweep serves both profiles the user
named for acceptance. Per pool: every live encounter row is fought 1-vs-1
by a reference party monster `--trials` times; the pool metric is the
weight-averaged median rounds-to-outcome. Both party policies are
reported ('attack' = pessimistic floor; 'tactics' = the commit machine
under Charge with the party movepool).

The 1-vs-1 row metric is deliberate: it is a stable per-row scalar for
regression/gating. Wild group sizes (1-3) scale threat, not row
identity; sweep with --ecount to study a fixed group size.

Party spec: --party HP,MP,ATK,DEF,AGL,INT[,LEVEL] (level gates the
tactics obedience path), --skills id,id,.. movepool for the tactics
policy. Presets: --preset early (lv5-ish), mid (lv20-ish).

Usage:
  python3 simulator/sweep_ttk.py ROM [--gates 0,1,2 | --pools 0,5]
      [--party ...] [--skills 0x3,0x2b] [--preset early|mid]
      [--trials 300] [--ecount 1] [--policies attack,tactics]
      [--out sweep.json] [--seed 7]
Gate ids/names come from extracted/encounters.json (vanilla pool map;
custom-room pools live in bank $71 RoomEncTable and are out of scope
here — see CROSSBANK_ROOMS).
"""
import json, os, sys, argparse, random

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from randomizer.romdata import Rom
from simulator import pacing as P

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PRESETS = {
    'early': dict(hp=40, mp=18, atk=22, dfn=18, agl=16, int=14, level=5),
    'mid':   dict(hp=120, mp=60, atk=70, dfn=60, agl=55, int=50, level=20),
}


def party_for_level(lv):
    """Reference party stats scaled to a target level: linear through the
    'early' (L5) and 'mid' (L20) anchors, extrapolated on the same slope
    and floored at the early preset. Keeps pool-TTK comparisons
    meaningful across the whole game (an L5 party vs an L40 pool measures
    nothing but the zero-damage floor)."""
    e, m = PRESETS['early'], PRESETS['mid']
    t = (lv - e['level']) / (m['level'] - e['level'])
    out = {}
    for k in ('hp', 'mp', 'atk', 'dfn', 'agl', 'int'):
        out[k] = max(e[k], round(e[k] + (m[k] - e[k]) * t))
    out['level'] = max(1, min(int(lv), 99))
    out['wld'] = 5 * out['level']    # creation-time WLD at arena tier 0
    return out


def rom_enemy_rec(rom, eid):
    e = rom.enemies[eid]
    return dict(enemy_stats_id=e.id, species_id=e.species,
                level=e.level, hp=e.stats[0], mp=e.stats[1],
                atk=e.stats[2], **{'def': e.stats[3]},
                agl=e.stats[4], int=e.stats[5],
                ai_weights=list(e.ai), skills=list(e.skills))


def rom_species_view(rom):
    """monsters_full-shaped species dict from the ROM itself, so a
    randomized build's resist/fly data (unchanged by the randomizer,
    but read from the ROM under test on principle) feeds the boards."""
    out = {}
    for i, m in enumerate(rom.monsters):
        out[i] = dict(resistances=list(m.resist), can_fly=bool(m.can_fly))
    return out


def gate_pools(gates_filter=None):
    enc = json.load(open(os.path.join(ROOT, 'extracted', 'encounters.json')))
    out = []
    for gid, g in enc.items():
        if gates_filter is not None and int(gid) not in gates_filter:
            continue
        for fg in g['floor_groups']:
            out.append((int(gid), g['name'], fg['floor_range'],
                        fg['pool_index']))
    return out


def sweep_pool(rom, species, pool, party, skills, policies, trials, seed,
               ecount, records, dup, idle=None):
    idle = idle or P.IdlePolicy('empirical', seed=seed)
    res = {}
    for pol in policies:
        rows = []
        for i in pool.live_slots():
            eid = pool.eids[i]
            w = pool.weights[i]
            er_rec = rom_enemy_rec(rom, eid)
            enemies = [er_rec] * ecount
            er = {4 + j: er_rec for j in range(ecount)}

            def mk(er_rec=er_rec, enemies=enemies):
                p = dict(party); p['skills'] = skills
                p['species'] = None; p['tactic'] = 0
                return P.make_board([p], enemies, species=species, db73=0)

            s = P.ttk(mk, records, dup, trials=trials, seed=seed,
                      party_policy=pol, enemy_recs=er, idle=idle)
            rows.append(dict(eid=eid, species=er_rec['species_id'],
                             weight=w, **{k: v for k, v in s.items()
                                          if k != 'trials'}))
        wsum = sum(r['weight'] for r in rows) or 1
        res[pol] = dict(
            rows=rows,
            pool_ttk_med=sum(r['rounds_med'] * r['weight']
                             for r in rows) / wsum,
            pool_win_party=sum(r['wins']['party'] * r['weight']
                               for r in rows) / (wsum * trials),
        )
    return res


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('rom')
    ap.add_argument('--gates'); ap.add_argument('--pools')
    ap.add_argument('--party'); ap.add_argument('--skills')
    ap.add_argument('--preset', default='early', choices=sorted(PRESETS))
    ap.add_argument('--trials', type=int, default=300)
    ap.add_argument('--ecount', type=int, default=1)
    ap.add_argument('--policies', default='attack,tactics')
    ap.add_argument('--seed', type=int, default=7)
    ap.add_argument('--out')
    a = ap.parse_args(argv)

    rom = Rom.load(a.rom)
    species = rom_species_view(rom)
    records = P.load_records()
    dup = P.load_dup_flags()
    party = dict(PRESETS[a.preset])
    if a.party:
        v = [int(x, 0) for x in a.party.split(',')]
        party = dict(hp=v[0], mp=v[1], atk=v[2], dfn=v[3], agl=v[4],
                     int=v[5], level=(v[6] if len(v) > 6 else 5))
    else:
        party['dfn'] = party.pop('dfn', party.get('dfn', 0))
    skills = ([int(x, 0) for x in a.skills.split(',')]
              if a.skills else [])
    policies = a.policies.split(',')

    if a.pools:
        targets = [(-1, f'pool {p}', '-', int(p))
                   for p in a.pools.split(',')]
    else:
        gf = ([int(x) for x in a.gates.split(',')] if a.gates else None)
        targets = gate_pools(gf)

    out = []
    for gid, name, floors, pidx in targets:
        pool = rom.pools[pidx]
        if not pool.live_slots():
            continue
        r = sweep_pool(rom, species, pool, party, skills, policies,
                       a.trials, a.seed, a.ecount, records, dup)
        out.append(dict(gate=gid, name=name, floors=floors, pool=pidx,
                        results=r))
        line = f"{name:<22} [{floors:>10}] pool {pidx:3d}:"
        for pol in policies:
            line += (f"  {pol}: TTK {r[pol]['pool_ttk_med']:.1f} "
                     f"win {r[pol]['pool_win_party']:.0%}")
        print(line)
    if a.out:
        json.dump(dict(_generator='simulator/sweep_ttk.py', rom=a.rom,
                       party=party, skills=skills, ecount=a.ecount,
                       trials=a.trials, sweep=out), open(a.out, 'w'),
                  indent=1)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
