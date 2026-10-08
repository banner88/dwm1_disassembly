#!/usr/bin/env python3
"""S130 F5 corpus recipe: runs simulator/measure_f5.py once per scenario
(one emulator process at a time) and collects simulator/f5_events.json.

  python3 simulator/f5_corpus_recipe.py [--only PREFIX] [--out FILE]

Common pokes: party ATK 1 and enemy ATK 1 (nobody dies by accident),
enemies 900 HP unless the scenario wounds them. Each scenario forces one
caster's queue (or none = the engine's own AI commit) and varies --skip
(frames idled before the trigger) to vary the RNG.
"""
import argparse
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PATK = '0:atk=1,1:atk=1,2:atk=1'
EATK = '4:atk=1,5:atk=1,6:atk=1'
E900 = '4:hp=900,4:maxhp=900,5:hp=900,5:maxhp=900,6:hp=900,6:maxhp=900'
EMP = '4:mp=60,4:maxmp=60,5:mp=40,5:maxmp=90,6:mp=0,6:maxmp=50'
CMP = '2:mp=250,2:maxmp=250'
EMPF = '4:mp=250,4:maxmp=250,5:mp=250,5:maxmp=250,6:mp=250,6:maxmp=250'
PHEAL = ['0=0x2b:0', '1=0x2b:0', '2=0x2b:0']   # party busy with (mostly $BB) self-heals
BASE = [PATK, EATK, E900]

S = []        # (name, eid, ecount, [sets], [queues], skip, maxrounds)


def sc(name, sets, qs, skips=(0,), eid=3, ec=3, rounds=2, base=True):
    for k in skips:
        S.append((f'{name}_{k}', eid, ec, (BASE if base else []) + sets, qs, k, rounds))


# ---- party HP heals -------------------------------------------------------
W1 = '0:hp=500,1:hp=40,2:hp=30'
sc('p_heal_m1', [W1, CMP], ['2=0x2b:2'], (0, 9, 17))
sc('p_heal_m1b', ['0:hp=400,1:hp=150,2:hp=20', CMP], ['2=0x2b:0'], (3, 11))
sc('p_heal_m2', [W1, CMP, '2:dd0b=2'], ['2=0x2b:2'], (0, 5, 21))
sc('p_heal_m2b', ['0:hp=120,1:hp=100,2:hp=66', CMP, '2:dd0b=2'], ['2=0x2b:1'], (2, 8))
sc('p_heal_m2tie', ['0:hp=135,1:hp=135,2:hp=67', CMP, '2:dd0b=2,0:maxhp=999'], ['2=0x2b:1'], (4, 6, 12))
sc('p_heal_m0', [W1, CMP, '2:dd0b=0'], ['2=0x2b:ff'], (0, 7, 15, 23))
sc('p_heal_m0q', [W1, CMP, '2:dd0b=0'], ['2=0x2b:1'], (1,))
sc('p_healmore', [W1, CMP], ['2=0x2c:2'], (0, 13))
sc('p_healall', [W1, CMP], ['2=0x2d:2'], (0, 19))
sc('p_healfull', [CMP], ['2=0x2b:2'], (0,))
sc('p_healus', ['0:hp=300,1:hp=30,2:hp=20', CMP], ['2=0x2e:0'], (0, 5, 29))
sc('p_healus_dead', ['0:dead=1,1:hp=50', CMP], ['2=0x2e:0'], (0, 3))
sc('p_healusall', ['0:hp=300,1:hp=30', CMP], ['2=0x2f:0'], (0,))
sc('p_hustle', ['0:hp=300,1:hp=30,2:hp=20', CMP], ['2=0x94:0'], (0, 31))
sc('p_hua3', ['0:hp=300,1:hp=30,2:hp=20', CMP], ['2=0xa3:0'], (0,))
sc('p_meditate', ['2:hp=10', CMP], ['2=0x93:2'], (0, 2))
sc('p_meditate_b', ['0:hp=300,0:mp=100', CMP], ['0=0x93:0'], (0,))
# ---- enemy HP heals (enemy side fields; AI modes poked) ------------------
EW = '4:hp=200,5:hp=100,6:hp=850'
sc('e_heal_m0', [EW, EMPF], ['4=0x2b:ff'], (0, 6, 14))
sc('e_heal_m0q', [EW, EMPF], ['4=0x2b:5'], (2,))
sc('e_heal_m1', [EW, EMPF, '4:dd0b=1'], ['4=0x2b:4'], (0, 10, 18))
sc('e_heal_m2', [EW, EMPF, '4:dd0b=2'], ['4=0x2b:4'], (0, 10))
sc('e_healmore', [EW, EMPF, '4:dd0b=1'], ['4=0x2c:4'], (3, 9))
sc('e_healall', [EW, EMPF, '5:dd0b=1'], ['5=0x2d:4'], (0,))
sc('e_healus', [EW, EMPF], ['4=0x2e:4'], (0, 12, 25))
sc('e_hustle', [EW, EMPF], ['5=0x94:4'], (0, 7))
sc('e_healusall', [EW, EMPF], ['6=0x2f:4'], (0,))
sc('e_hua3', [EW, EMPF], ['6=0xa3:4'], (0,))
sc('e_meditate', ['4:hp=100', EMPF], ['4=0x93:4'], (0, 1))
# ---- revive -------------------------------------------------------------
sc('p_vivify', ['1:dead=1', CMP], ['2=0x30:1'], (0, 1, 2, 3, 4, 5, 6, 8))
sc('p_vivify_live', [CMP], ['2=0x30:1'], (0,))
sc('p_revive', ['1:dead=1', CMP], ['2=0x31:1'], (0, 7))
sc('p_revive_scan', ['0:dead=1', CMP], ['2=0x31:1'], (0, 4))
sc('p_revive_two', ['0:dead=1,1:dead=1', CMP], ['2=0x31:2'], (0,))
sc('p_allrevive', ['0:dead=1,1:dead=1', CMP], ['2=0xad:0'], (0, 3))
sc('p_allrevive1', ['1:dead=1', CMP], ['2=0xad:0'], (0,))
sc('e_vivify', ['5:dead=1', EMPF], ['4=0x30:5'], (0, 1, 2, 3, 9))
sc('e_revive', ['5:dead=1,6:dead=1', EMPF], ['4=0x31:4'], (0, 2))
sc('e_allrevive', ['4:dead=1,6:dead=1', EMPF], ['5=0xad:4'], (0,))
# ---- the state-4 chain --------------------------------------------------
sc('p_farewell', ['1:dead=1,0:hp=500', CMP], ['2=0x32:0'], (0, 1, 2, 3, 4, 5))
sc('p_farewell_b', ['0:dead=1,1:hp=20,2:hp=600,2:maxhp=900', CMP], ['2=0x32:0'], (0, 1, 2, 5, 9, 13))
sc('p_farewell_s1', ['0:hp=400', CMP, '1:mp=50,1:maxmp=90'], ['1=0x32:0'], (0,))
sc('p_lifedance', ['1:dead=1,0:hp=500', CMP], ['2=0x96:0'], (0, 1, 2, 3, 4, 5, 6))
sc('p_lifesong', ['1:dead=1,0:hp=500', CMP], ['2=0x95:0'], (0, 1, 2, 3, 4, 5), rounds=3)
sc('p_lifesong_nodead', ['0:hp=500', CMP], ['2=0x95:0'], (0, 1), rounds=3)
sc('e_farewell', ['5:dead=1,6:hp=100,4:mp=50'], ['4=0x32:4'], (0, 1, 2, 3))
sc('e_lifedance', ['5:dead=1,6:hp=100', EMPF], ['4=0x96:4'], (0, 1, 2, 3))
sc('e_lifesong', ['5:dead=1,6:hp=100,4:mp=60'], ['4=0x95:4'], (0, 1, 2), rounds=3)
sc('e_lifesong_b', ['5:dead=1,6:dead=1', EMPF], ['4=0x95:4'], (3, 4), rounds=3)
# ---- cures --------------------------------------------------------------
sc('p_antidote', ['1:s2=1,0:s2=2', CMP], ['2=0x33:2'], (0, 3))
sc('p_antidote1', ['1:s2=1', CMP], ['2=0x33:2'], (0,))
sc('p_antidote0', ['0:s2=1', CMP], ['2=0x33:2'], (0,))
sc('p_antidote_m0', ['1:s2=1', CMP, '2:dd0b=0'], ['2=0x33:ff'], (0, 5))
sc('p_numboff', ['1:s2=0x40,0:s2=0x8c', CMP], ['2=0x34:0'], (0, 3))
sc('p_dechaos', ['1:s2=0x10', CMP], ['2=0x35:0'], (0, 3))
sc('p_curseoff', ['1:s2=0x20,0:s2=0x21', CMP], ['2=0x36:0'], (0, 3))
sc('e_cures', ['5:s2=0x40,6:s2=0x30', EMPF], ['4=0x34:4'], (0,))
sc('e_curse2', ['5:s2=0x20,6:s2=0x10', EMPF], ['4=0x36:4'], (0,))
sc('e_dechaos', ['5:s2=0x10,6:s2=0x41', EMPF], ['4=0x35:4'], (0,))
sc('e_antidote', ['5:s2=0x02,6:s2=0x01', EMPF, '4:dd0b=1'], ['4=0x33:4'], (0, 1))
# ---- MP economy ---------------------------------------------------------
sc('p_robmagic', [EMP, '2:mp=10,2:maxmp=100'], ['2=0x1a:4'], (0, 1, 2, 3, 4, 5))
sc('p_robmagic_cap', [EMP, '2:mp=95,2:maxmp=100'], ['2=0x1a:4'], (0, 1))
sc('p_robdance', [EMP, '2:mp=10,2:maxmp=100'], ['2=0x76:5'], (0, 1, 2))
sc('p_odddance', [EMP, '2:mp=10,2:maxmp=100'], ['2=0x75:4'], (0, 1, 2, 3))
sc('p_robmagic_m0', [EMP, '2:mp=10,2:maxmp=100,2:dd0b=0'], ['2=0x1a:ff'], (0, 6))
sc('p_robmagic_nomp', ['2:mp=10,2:maxmp=100'], ['2=0x1a:6'], (0,))
sc('e_robmagic', ['4:mp=0,4:maxmp=60', '0:mp=900,1:mp=50,2:mp=20'], ['4=0x1a:1'], (0, 1, 2, 3))
sc('e_odddance', ['0:mp=900,1:mp=50,2:mp=20'], ['4=0x75:2'], (0, 1, 2))
sc('p_mp0', [EMP], ['2=0xa8:4'], (0, 3))
sc('p_restoremp', ['0:mp=0,1:mp=10,1:maxmp=99,2:mp=257,2:maxmp=300'], ['2=0xae:0'], (0,))
sc('p_restoremp_b', ['0:mp=300,0:maxmp=916,1:mp=93,2:mp=1,2:maxmp=300'], ['2=0xae:0'], (0,))
sc('e_restoremp', ['4:mp=5,4:maxmp=60,5:mp=0,6:mp=3'], ['5=0xae:4'], (0,))
sc('e_mp0', ['4:mp=5,4:maxmp=60,5:mp=40,6:mp=3'], ['5=0xa8:0'], (0,))
sc('e_farewell2', ['5:dead=1,6:hp=100', EMPF], ['6=0x32:4'], (5, 6, 7))
# ---- natural AI commits (no forced queue) -------------------------------
sc('ai_heal263', ['4:hp=30,5:hp=60', '4:maxhp=80,5:maxhp=90,6:maxhp=90,6:hp=90'], PHEAL, (0, 4, 9), eid=263,
   rounds=4, base=False)
sc('ai_heal11', ['4:hp=10,5:hp=25,6:hp=40'], PHEAL, (0, 3, 8), eid=11, rounds=4, base=False)
sc('ai_195', ['5:dead=1,4:hp=60'], PHEAL, (0, 2, 5), eid=195, rounds=4, base=False)
sc('ai_123', ['5:dead=1,4:hp=60,4:maxhp=120,6:hp=30,6:maxhp=120'], PHEAL, (0, 2, 7), eid=124, rounds=4,
   base=False)
sc('ai_314', ['5:hp=60,6:hp=50'], PHEAL, (0, 3), eid=314, rounds=4, base=False)
sc('ai_29', ['5:s2=0x40,6:s2=0x10'], PHEAL, (0, 3), eid=29, rounds=4, base=False)
sc('ai_58', ['5:dead=1'], PHEAL, (0, 3), eid=58, rounds=5, base=False)
sc('ai_193', ['5:hp=60,4:hp=100'], PHEAL, (0, 3), eid=193, rounds=4, base=False)
sc('ai_162', ['5:hp=60,4:hp=100,6:hp=40'], PHEAL, (0, 3), eid=162, rounds=4, base=False)
sc('ai_88', ['5:hp=30,4:hp=50,6:s2=0x20'], PHEAL, (0, 3), eid=88, rounds=4, base=False)
sc('ai_116', ['0:mp=200,1:mp=90'], PHEAL, (0, 3), eid=116, rounds=4, base=False)
sc('ai_120', ['0:mp=200,1:mp=90'], PHEAL, (0, 3), eid=120, rounds=4, base=False)


def compact(path):
    """Keep what simulator/validate_f5.py reads: round starts, every actor
    fetch, all events of actors whose queued skill is an F5 id, the bank
    $58 row calls + the event after each, the first phase-9 read of each
    round. Drops the bulky per-frame/AI-estimate noise of other actors."""
    import json
    sys.path.insert(0, os.path.dirname(HERE))
    from simulator.skillfx import f5_heal as F
    ev = json.load(open(path))
    keep = [False] * len(ev)
    cur_f5 = False
    p9_seen = False
    for i, e in enumerate(ev):
        t = e['tag']
        if t == 'round_start':
            p9_seen = False
            cur_f5 = False
        if t == 'actor_fetch':
            a = e['A']
            cur_f5 = a < 8 and (e['dcec'][a * 2] in F.ROWS)
        if t.startswith('p9_') and t != 'p9_slot':
            cur_f5 = False
        if t == 'p9_slot':
            cur_f5 = False
            if not p9_seen:
                keep[i] = True
                p9_seen = True
        if t in ('round_start', 'actor_fetch') or cur_f5:
            keep[i] = True
        if t.startswith('row_'):
            keep[i] = True
            if i + 1 < len(ev):
                keep[i + 1] = True
    out = [e for e, k in zip(ev, keep) if k]
    for e in out:
        e.pop('ai_bases', None); e.pop('wld', None)
    json.dump(out, open(path, 'w'), separators=(',', ':'))
    print(f'compacted {len(ev)} -> {len(out)} events')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--only', default='')
    ap.add_argument('--out', default=os.path.join(HERE, 'f5_events.json'))
    ap.add_argument('--compact', action='store_true', help='only compact --out')
    a = ap.parse_args()
    if a.compact:
        compact(a.out)
        return
    for name, eid, ec, sets, qs, skip, rounds in S:
        if not name.startswith(a.only):
            continue
        cmd = [sys.executable, os.path.join(HERE, 'measure_f5.py'), name, str(eid), '--ecount', str(ec),
               '--skip', str(skip), '--maxrounds', str(rounds), '--out', a.out]
        for s_ in sets:
            cmd += ['--set', s_]
        for q in qs:
            if q.split('=')[1].split(':')[0].startswith('0x'):
                cmd += ['--q', q]
            else:
                cmd += ['--set', q]
        r = subprocess.run(cmd, capture_output=True, text=True)
        print((r.stdout.strip().splitlines() or [r.stderr.strip()[-300:]])[-1][:160])


if __name__ == '__main__':
    main()
