#!/usr/bin/env python3
"""S130 F2/F3 corpus RECIPE: runs simulator/measure_f23_phys.py once per
battle (86 rig battles on the user's save, u22 build), appending to OUT.
The committed corpus simulator/f23_phys_events.json.gz is this plan's
output, gzipped (`gzip -9 -c OUT > simulator/f23_phys_events.json.gz`).
Usage: measure_f23_phys_plan.py OUT [name-substring-filter]
Every battle: party slots 0-2 (Darkdrium/BattleRex/Healer) and enemy slots
4-6 forced per q() (None = $9C, a message-only meta action), HP/MP re-poked
each command phase (--keep), resistance levels / +5 rows / +4 Barrier /
levels / db73 poked per battle as listed."""
import subprocess, sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = sys.argv[1]
FILT = sys.argv[2] if len(sys.argv) > 2 else ''
NOP = 0x9C
HP = '--hp', '0=999,1=999,2=999,4=999,5=999,6=999'
MP = '--mp', '0=255,1=255,2=255,4=255,5=255,6=255'
ATK = '--atk', '4=400,5=330,6=260'
DFN = '--dfn', '0=200,1=150,2=120'


def q(p, e):
    """p: 3 (skill, target) for party 0-2; e: 3 for enemies 4-6 (None = $9C)."""
    out = []
    for s, x in zip((0, 1, 2), p):
        sk, tg = x if x else (NOP, 4)
        out.append(f'{s}={sk:#x}:{tg}')
    for s, x in zip((4, 5, 6), e):
        sk, tg = x if x else (NOP, 0)
        out.append(f'{s}={sk:#x}:{tg}')
    return ['--q', ','.join(out)]


def res(pairs):
    return ['--res', ','.join(f'{s}:{rt}={lv}' for s, rt, lv in pairs)]


RUNS = []


def R(name, eids, qq, *extra, rounds=4, keep=True, hp=HP, skip=0, maxev=900):
    args = [name, '0', '--eids', ','.join(map(str, eids))] + qq + list(hp) + list(MP) + list(ATK) + list(DFN)
    if keep:
        args.append('--keep')
    args += ['--rounds', str(rounds), '--skip', str(skip), '--maxev', str(maxev)] + list(extra)
    RUNS.append((name, args))


ROWS_A = ['--st', '4:5=0x40,5:5=0x80,1:5=0x40,2:5=0x80']
# ---- F2: elemental slashes -------------------------------------------------
for sk, rt in ((0x44, 0), (0x45, 4), (0x46, 3), (0x47, 5)):
    P = [(sk, 4), (sk, 5), (sk, 6)]; E = [(sk, 0), (sk, 1), (sk, 2)]
    R(f'slash{sk:x}a', (1, 13, 22), q(P, E), *res([(4, rt, 0), (5, rt, 1), (6, rt, 2), (0, rt, 3), (1, rt, 1), (2, rt, 0)]))
    R(f'slash{sk:x}b', (1, 13, 22), q(P, E), *res([(4, rt, 3), (5, rt, 2), (6, rt, 1), (0, rt, 0), (1, rt, 2), (2, rt, 3)]), *ROWS_A)
# ---- MetalCut ----------------------------------------------------------------
R('metal', (181, 1, 13), q([(0x48, 4), (0x48, 5), (0x48, 6)], [(0x48, 0), (0x48, 1), (0x48, 2)]), '--db8b', '1=1')
R('metal2', (181, 181, 9), q([(0x48, 4), (0x48, 5), (0x48, 6)], [(0x48, 1), None, None]), '--db8b', '1=1', skip=7)
# ---- family cuts -------------------------------------------------------------
MATCH = {0x49: 13, 0x4A: 3, 0x4B: 4, 0x4C: 22, 0x4D: 8, 0x4E: 9, 0xD6: 1, 0xD7: 6, 0xD8: 5}
OTHERS = [1, 13, 3, 4, 5, 6, 22, 8, 9]
for i, (sk, eid) in enumerate(MATCH.items()):
    o = [x for x in OTHERS if x != eid]
    R(f'fam{sk:x}', (eid, o[i % 8], o[(i + 3) % 8]), q([(sk, 4), (sk, 5), (sk, 6)], [(sk, 0), (sk, 1), (sk, 2)]), rounds=3)
# ---- simple multipliers / aliases -------------------------------------------
for sk in (0x55, 0xDD, 0x37, 0x38, 0x7E, 0xAB):
    R(f'simple{sk:x}', (1, 13, 22), q([(sk, 4), (sk, 5), (sk, 6)], [(sk, 0), (sk, 1), (sk, 2)]), rounds=3)
# ---- Beserker and its consumer ----------------------------------------------
# Beserker user acts FIRST (AGL 999), the others hit it afterwards in the round
R('bes_p', (1, 13, 22), q([None, None, (0x3D, 4)], [(0x3A, 2), (0x3A, 2), (0x5C, 2)]), '--agl', '2=999,4=1,5=1,6=1',
  '--dfn', '4=900,0=200,1=150,2=120', rounds=6)
R('bes_p2', (13, 1, 22), q([None, (0x3D, 5), None], [(0x3C, 1), (0x3A, 1), (0x45, 1)]), '--agl', '1=999,4=1,5=1,6=1',
  '--dfn', '5=900,0=200,1=150,2=120', rounds=6, skip=5)
R('bes_e', (1, 13, 22), q([(0x3A, 6), (0x3E, 6), (0x3B, 6)], [None, None, (0x3D, 2)]), '--agl', '6=999,0=1,1=1,2=1',
  '--dfn', '6=700,0=200,1=150,2=900', '--db73', '0', rounds=6)
R('bes_e2', (13, 1, 22), q([(0x3A, 5), (0x55, 5), (0x5D, 4)], [None, (0x3D, 0), None]), '--agl', '5=999,0=1,1=1,2=1',
  '--dfn', '5=700,0=900,1=150,2=120', rounds=6, skip=3)
# ---- TwinSlash / PsycheUp tails ---------------------------------------------
R('twin', (1, 13, 22), q([(0x3B, 4), (0x3B, 5), (0x56, 6)], [(0x3B, 0), (0x56, 1), (0x3B, 2)]), rounds=4)
R('twin_ko', (1, 13, 22), q([(0x3B, 4), None, None], [(0x3B, 0), None, None]),
  '--hp', '0=30,1=999,2=999,4=40,5=999,6=999', rounds=3)
R('twin_zero', (181, 181, 181), q([None, (0x3B, 4), (0x3B, 5)], [None, None, None]), '--atk', '1=20,2=20', rounds=5)
R('twin_zero2', (181, 181, 181), q([(0x3B, 4), (0x3B, 5), (0x56, 6)], [None, None, None]), '--atk', '0=20,1=20,2=20', rounds=14, skip=9)
# ---- Ramming -----------------------------------------------------------------
R('ram', (1, 13, 22), q([(0x3C, 4), (0x3C, 5), (0x3C, 6)], [(0x3C, 0), (0x3C, 1), (0x3C, 2)]),
  *res([(4, 14, 0), (5, 14, 1), (6, 14, 2), (0, 14, 3), (1, 14, 1), (2, 14, 0)]), rounds=3)
R('ram_b', (1, 13, 22), q([(0x3C, 4), (0x3C, 5), (0x3C, 6)], [(0x3C, 0), (0x3C, 1), (0x3C, 2)]),
  *res([(4, 14, 3), (5, 14, 2), (6, 14, 1), (0, 14, 0), (1, 14, 2), (2, 14, 3)]), *ROWS_A, rounds=3)
R('ram_ko', (1, 13, 22), q([(0x3C, 4), (0x3C, 5), None], [(0x3C, 0), (0x3C, 2), None]),
  '--hp', '0=5,1=10,2=999,4=4,5=999,6=999', rounds=2)
# ---- Kamikaze ----------------------------------------------------------------
for db73 in (0, 1, 2):
    R(f'kami{db73}', (1, 13, 22), q([(0x3E, 4), (0x3E, 5), (0x3E, 6)], [(0x3E, 0), (0x3E, 1), (0x3E, 2)]),
      *res([(4, 14, 0), (5, 14, 1), (6, 14, 2), (0, 14, 1), (1, 14, 2), (2, 14, 0)]), '--db73', str(db73), rounds=2)
    R(f'kami{db73}b', (1, 13, 22), q([(0x3E, 4), (0x3E, 5), (0x3E, 6)], [(0x3E, 0), (0x3E, 1), (0x3E, 2)]),
      *res([(4, 14, 2), (5, 14, 1), (6, 14, 3), (0, 14, 2), (1, 14, 0), (2, 14, 1)]), *ROWS_A, '--db73', str(db73), rounds=2, skip=5)
R('kami_hp1', (1, 13, 22), q([(0x3E, 4), None, None], [(0x3E, 0), None, None]),
  '--hp', '0=1,1=999,2=999,4=1,5=999,6=999', *res([(4, 14, 0), (0, 14, 0)]), '--db73', '1', rounds=2)
# ---- Sacrifice -----------------------------------------------------------------
for k, db73 in enumerate((0, 1, 2, 0, 2, 0)):
    R(f'sac_p{k}', (1, 13, 22), q([(0x14, 4), None, None], [None, None, None]),
      *res([(4, 14, k % 3), (5, 14, (k + 1) % 3), (6, 14, 2)]), '--db73', str(db73), rounds=2, skip=k * 7)
for k in range(5):
    R(f'sac_e{k}', (1, 13, 22), q([None, None, None], [(0x14, 0), None, None]),
      *res([(0, 14, k % 3), (1, 14, 2), (2, 14, (k + 2) % 4)]), '--db73', str(k % 3), rounds=2, skip=k * 11)
R('sac_mid', (1, 13, 22), q([(0x14, 5), None, None], [None, None, None]), *res([(4, 14, 0), (5, 14, 0), (6, 14, 1)]),
  '--hp', '0=150,1=999,2=999,4=999,5=999,6=1', '--db73', '0', rounds=2)
R('sac_iron', (1, 13, 22), q([(0x14, 4), None, None], [None, None, None]), *res([(4, 14, 0), (5, 14, 0), (6, 14, 0)]),
  '--st', '5:7=0x40', '--db73', '0', rounds=2, skip=3)
# ---- MultiCut -----------------------------------------------------------------
R('multi_p', (8, 103, 22), q([(0x4F, 4), None, None], [(0x4F, 0), None, None]),
  *res([(4, 3, 0), (5, 3, 1), (6, 3, 2), (0, 3, 3), (1, 3, 0), (2, 3, 1)]), rounds=4)
R('multi_b', (13, 8, 1), q([(0x4F, 4), None, None], [(0x4F, 0), None, None]),
  *res([(4, 3, 3), (5, 3, 0), (6, 3, 1), (0, 3, 2), (1, 3, 1), (2, 3, 0)]), *ROWS_A, rounds=4)
# ---- WindBeast / Vacuum ---------------------------------------------------------
for sk in (0x58, 0x59):
    R(f'wind{sk:x}a', (1, 13, 22), q([(sk, 4), (sk, 5), (sk, 6)], [(sk, 0), (sk, 1), (sk, 2)]),
      *res([(4, 3, 0), (5, 3, 1), (6, 3, 2), (0, 3, 3), (1, 3, 1), (2, 3, 0)]), '--lvl', '0=10,1=30,2=60,4=10,5=40,6=99', rounds=3)
    R(f'wind{sk:x}b', (1, 13, 22), q([(sk, 4), (sk, 5), (sk, 6)], [(sk, 0), (sk, 1), (sk, 2)]),
      *res([(4, 3, 3), (5, 3, 2), (6, 3, 0), (0, 3, 0), (1, 3, 2), (2, 3, 1)]), *ROWS_A, '--lvl', '0=1,1=22,2=45,4=3,5=70,6=150', rounds=3)
# ---- breaths + Barrier ----------------------------------------------------------
BAR = ['--st', '5:4=0x04,1:4=0x04']
for sk in range(0x5C, 0x64):
    rt = 16 if sk < 0x60 else 17
    R(f'breath{sk:x}', (1, 13, 22), q([(sk, 4), None, None], [(sk, 0), None, None]),
      *res([(4, rt, sk & 3), (5, rt, (sk + 1) & 3), (6, rt, (sk + 2) & 3), (0, rt, (sk + 3) & 3), (1, rt, sk & 3), (2, rt, (sk + 1) & 3)]),
      *(BAR if sk & 1 else ['--st', '5:4=0x04,1:4=0x04,4:5=0x40,2:5=0x80']), rounds=3)
# ---- RockThrow / BigBang / MegaMagic / GigaSlash ----------------------------------
for sk, rt in ((0x5B, 24), (0x65, 0), (0x66, 15), (0xD9, 25)):
    P = [(sk, 4), None, None] if sk != 0xD9 else [(sk, 4), (sk, 5), (sk, 6)]
    E = [(sk, 0), None, None] if sk != 0xD9 else [(sk, 0), (sk, 1), (sk, 2)]
    R(f'f3_{sk:x}a', (1, 13, 22), q(P, E), *res([(4, rt, 0), (5, rt, 1), (6, rt, 2), (0, rt, 3), (1, rt, 1), (2, rt, 0)]),
      '--lvl', '0=30,4=20', rounds=3)
    R(f'f3_{sk:x}b', (1, 13, 22), q(P, E), *res([(4, rt, 3), (5, rt, 2), (6, rt, 1), (0, rt, 0), (1, rt, 2), (2, rt, 3)]),
      *ROWS_A, '--mp', '0=120,1=255,2=255,4=40,5=255,6=255', rounds=3)
# ---- record spells: the driver's ladder (SPELL_LADDER) ------------------------------
SP_GROUPS = [(0x00, 0x03, 0x06), (0x09, 0x0C, 0x0F), (0x02, 0x05, 0x08), (0x0B, 0x0E, 0x11), (0x5A, 0x64, 0x01), (0x04, 0x07, 0x0A, 0x0D, 0x10)]
import itertools
for gi, grp in enumerate(SP_GROUPS):
    g3 = (grp + grp)[:3]
    P = [(g3[0], 4), (g3[1], 5), (g3[2], 6)]; E = [(g3[2], 0), (g3[0], 1), (g3[1], 2)]
    rts = {0: 0, 1: 0, 2: 0, 3: 1, 4: 1, 5: 1, 6: 2, 7: 2, 8: 2, 9: 3, 10: 3, 11: 3, 12: 5, 13: 5, 14: 5, 15: 4, 16: 4, 17: 4, 0x5A: 4, 0x64: 4}
    rr = []
    for k, s in enumerate((4, 5, 6, 0, 1, 2)):
        for sk in set(g3):
            rr.append((s, rts[sk], (k + gi + sk) & 3))
    R(f'spell{gi}', (1, 13, 22), q(P, E), *res(rr), *(ROWS_A if gi & 1 else []), rounds=3)
R('blaze1', (13,), q([(0, 4), (0, 4), (0, 4)], [(0, 0), (0, 1), (0, 2)]),
  *res([(4, 0, 2), (4, 1, 0), (0, 0, 1), (0, 1, 3), (1, 0, 3), (1, 1, 0), (2, 0, 0), (2, 1, 2)]), rounds=4)
# ---- UltraDown: no damage part ---------------------------------------------------------
R('ultradown', (1, 13, 22), q([(0x82, 4), None, None], [(0x82, 0), None, None]), rounds=3)

if __name__ == '__main__':
    for name, args in RUNS:
        if FILT and FILT not in name:
            continue
        r = subprocess.run(['python3', os.path.join(ROOT, 'simulator', 'measure_f23_phys.py')] + args + ['--out', OUT],
                           capture_output=True, text=True)
        line = (r.stdout.strip().splitlines() or [''])[-1]
        print(line[:150] if r.returncode == 0 else f'{name}: ERROR {r.stderr[-400:]}', flush=True)
