#!/usr/bin/env python3
"""S130 F4 corpus RECIPE: runs simulator/measure_f4.py once per battle on the
user's save (u22 build), appending to OUT. The committed corpus
simulator/f4_events.json.gz is this plan's output, packed (unused waypoint
tags and snapshot fields dropped, gzipped):
  measure_f4_plan.py --pack simulator/f4_events.json.gz OUT [OUT2 ...]
Usage: measure_f4_plan.py OUT [name-substring-filter]

Party slots 0-2 = Darkdrium (species 214, party crit row 0) / BattleRex (42,
row 1) / Healer (9, row 2); enemy slots 4-6 per battle. Idle slots queue $9C
(a message-only meta action). HP/MP re-poked each command phase (--keep).
Groups:
  nat_*   every slot Attacks for many rounds (lean events): the natural crit
          rolls (exact per roll + the statistics) and the $DB42 commit rolls
  inj_*   the crit roll's RNG1 injected (--critrng) at 0..4 and party rows
          swapped (--dc3c) — every table value 0/1/2/3 at its boundary
  dmg_*   forced crits (RNG1 := 0) for the crit damage over many ATK values
          (incl. ATK < 10) and QuadHits / BiAttack / RainSlash
  tw_* ac_* ch_* sa_* hj_* ms_* fo_*  the F4 skills (setters + consumers)
  db42_*  the command-phase $DB42 rolls with the RNG injected (--db42rng)
          and AI bases poked (--aib) over every skill class
"""
import subprocess, sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = sys.argv[1]
FILT = sys.argv[2] if len(sys.argv) > 2 else ''
NOP = 0x9C
HP = ['--hp', '0=999,1=999,2=999,4=999,5=999,6=999']
MP = ['--mp', '0=255,1=255,2=255,4=255,5=255,6=255']
TOUGH = ['--dfn', '0=700,1=700,2=700,4=900,5=900,6=900']


def q(p, e):
    out = []
    for s, x in zip((0, 1, 2), p):
        sk, tg = x if x else (NOP, 4)
        out.append(f'{s}={sk:#x}:{tg}')
    for s, x in zip((4, 5, 6), e):
        sk, tg = x if x else (NOP, 0)
        out.append(f'{s}={sk:#x}:{tg}')
    return ','.join(out)


def QR(*rounds):
    return ['--qr', '/'.join(q(p, e) for p, e in rounds)]


ATT_P = [(0x3A, 4), (0x3A, 5), (0x3A, 6)]
ATT_E = [(0x3A, 0), (0x3A, 1), (0x3A, 2)]
RUNS = []


def R(name, eids, *extra, rounds=4, skip=0, maxev=3000, hp=HP, keep=True, frames=None):
    args = [name, '0', '--eids', ','.join(map(str, eids))] + list(hp) + MP
    args += ['--frames', str(frames or (rounds + 1) * 1100)]
    if keep:
        args.append('--keep')
    args += ['--rounds', str(rounds), '--skip', str(skip), '--maxev', str(maxev)] + list(extra)
    RUNS.append((name, args))


# ---- natural crit rolls (statistics + exact per roll) ------------------------
NAT = [(99, 100, 99), (37, 44, 45), (223, 99, 37), (100, 193, 223), (62, 64, 65),
       (66, 67, 69), (73, 74, 50), (99, 99, 100), (1, 13, 22), (438, 443, 479)]
for i, eids in enumerate(NAT):
    for k in range(3):
        R(f'nat{i}_{k}', eids, '--q', q(ATT_P, ATT_E), *TOUGH, '--lean',
          rounds=60, skip=7 * k + 3 * i, maxev=40000)

# ---- injected crit rolls: every table value at its boundary ------------------
# party rows: species 5 (value 3 -> 4), 30 (0), 18 (1), 0 (2) and the real
# 214 (0) / 42 (1) / 9 (2); enemy rows StoneMan 197 (3 -> 4), SkulRider 136
# (1), Slime 8 (0)
for v in range(6):
    R(f'inj{v}a', (99, 37, 1), '--q', q(ATT_P, ATT_E), '--critrng', f'all={v}', *TOUGH, '--lean',
      rounds=4, skip=v)
    R(f'inj{v}b', (100, 223, 13), '--q', q(ATT_P, ATT_E), '--critrng', f'all={v}',
      '--dc3c', '0=5,1=30,2=18', *TOUGH, '--lean', rounds=4, skip=v + 11)
    R(f'inj{v}c', (37, 99, 22), '--q', q(ATT_P, ATT_E), '--critrng', f'all={v}',
      '--dc3c', '0=0,1=5,2=30', *TOUGH, '--lean', rounds=4, skip=v + 23)

# ---- forced crits: crit damage over ATK values + multi-hit skills ------------
for i, atk in enumerate((3, 9, 10, 19, 55, 101, 260, 511, 999)):
    R(f'dmg_atk{atk}', (99, 37, 223), '--q', q(ATT_P, ATT_E), '--critrng', 'all=0',
      '--atk', f'0={atk},1={atk + 7},2={atk * 2 + 1},4={atk},5={atk + 3},6={atk + 13}',
      '--dc3c', '0=5', *TOUGH, rounds=3, skip=i)
R('dmg_multi', (99, 99, 100), '--q', q([(0x51, 4), (0x50, 5), (0x57, 4)], [(0x51, 0), (0x50, 1), (0x57, 0)]),
  '--critrng', 'all=0', '--dc3c', '0=5', *TOUGH, rounds=4)
R('dmg_multi2', (99, 37, 100), '--q', q([(0x51, 4), (0x44, 5), (0x67, 6)], [(0x51, 0), (0x4A, 1), (0x55, 2)]),
  '--critrng', 'all=1', '--dc3c', '0=5', *TOUGH, rounds=4, skip=5)
R('dmg_db42b0', (99, 1, 13), '--q', q(ATT_P, ATT_E), '--db42', '0=1,1=0x41,2=0x01', *TOUGH, rounds=3)

# ---- TwinHits -----------------------------------------------------------------
R('tw1', (13, 13, 13), *QR(([(0x3A, 4), (0x25, 0), (0x25, 1)], [(0x25, 5), (0x25, 4), None]),
                           ([(0x3A, 4), (0x50, 5), (0x3F, 6)], [(0x3A, 0), (0x50, 1), (0x25, 4)]),
                           ([(0x51, 4), (0x3A, 5), (0x44, 6)], [(0x40, 0), (0x51, 1), (0x3A, 2)])),
  *TOUGH, rounds=4)
R('tw2', (99, 37, 99), *QR(([(0x25, 1), (0x25, 2), (0x25, 0)], [(0x25, 5), (0x25, 6), (0x25, 4)]),
                           (ATT_P, ATT_E), ([(0x57, 4), (0x41, 1), (0x3A, 6)], [(0x99, 4), (0x3A, 1), (0x3A, 2)]),
                           ([(0x3A, 4), (0x3A, 5), (0x3A, 6)], ATT_E)),
  '--critrng', 'all=0', '--dc3c', '0=5', *TOUGH, rounds=5, skip=3)
# ---- ALLCHANGE (sure crit) ------------------------------------------------------
R('ac1', (13, 99, 37), *QR(([(0x3A, 4), (0x3A, 5), (0xA6, 0)], [(0xA6, 4), (0x3A, 1), (0x3A, 2)]),
                           ([(0x51, 4), (0x50, 5), (0x3A, 6)], [(0x51, 0), (0x57, 1), (0x3F, 2)])),
  *TOUGH, rounds=4)
# ---- ChargeUP / SuckAir --------------------------------------------------------
R('ch1', (13, 13, 13), *QR(([(0x41, 0), (0x41, 1), (0x41, 2)], [(0x41, 4), (0x43, 5), (0x41, 6)]),
                           ([(0x3A, 4), (0x50, 5), (0x44, 6)], [(0x3A, 0), (0x5D, 0), (0x41, 6)]),
                           ([(0x3A, 4), (0x3A, 5), (0x3A, 6)], [(0x3A, 0), (0x3A, 1), (0x3A, 2)])),
  *TOUGH, rounds=4)
R('ch2', (37, 99, 13), *QR(([(0x41, 0), (0x43, 1), (0xA6, 2)], [(0x41, 4), (0x43, 5), (0x25, 4)]),
                           ([(0x3A, 4), (0x5C, 4), (0x41, 2)], [(0x3A, 0), (0x60, 0), (0x43, 6)]),
                           ([(0x3F, 4), (0x62, 4), (0x3A, 6)], [(0x50, 0), (0x00, 0), (0x5E, 0)]),
                           ([(0x41, 0), (0x43, 1), (0x3A, 6)], [(0x41, 4), (0x43, 5), (0x63, 0)]),
                           ([(0x41, 0), (0x6D, 4), (0x3A, 6)], [(0x3A, 0), (0x5F, 0), (0x61, 0)]),
                           ([(0x55, 4), (0x5C, 4), (0x3A, 6)], [(0x3A, 0), (0x3A, 1), (0x3A, 2)])),
  *TOUGH, rounds=7, skip=5)
R('ch3', (13, 13, 13), *QR(([(0x41, 0), (0x41, 1), (0x41, 2)], [None, None, None]),
                           ([(0x57, 4), (0x51, 5), (0x3B, 6)], [None, None, None]),
                           ([(0x41, 0), (0x41, 1), (0x41, 2)], [None, None, None]),
                           ([(0x48, 4), (0x4D, 5), (0x67, 6)], [None, None, None])),
  *TOUGH, rounds=5, skip=9)
# ---- HighJump --------------------------------------------------------------------
R('hj1', (13, 13, 13), *QR(([(0x42, 4), None, None], [(0x3A, 0), (0x50, 0), None]),
                           ([(0x9C, 4), None, None], [(0x3A, 0), (0x50, 0), None])), rounds=3)
R('hj2', (13, 37, 99), *QR(([(0x42, 4), (0x3A, 4), (0x00, 4)], [(0x42, 1), (0x3A, 4), (0x00, 4)]),
                           ([(0x42, 4), (0x3A, 4), (0x3A, 4)], [(0x42, 1), (0x3A, 4), (0x5E, 0)]),
                           ([(0x42, 5), (0x42, 4), (0x3A, 4)], [(0x3A, 0), (0x42, 1), (0x6D, 0)]),
                           ([(0x42, 5), (0x42, 4), (0x3A, 4)], [(0x3A, 0), (0x42, 1), (0x6D, 0)])),
  *TOUGH, rounds=5, skip=4)
R('hj3', (13, 13, 13), *QR(([(0x42, 4), (0x42, 5), (0x42, 6)], [(0x42, 0), (0x42, 1), (0x42, 2)]),
                           ([(0x42, 4), (0x42, 5), (0x42, 6)], [(0x42, 0), (0x42, 1), (0x42, 2)])),
  '--agl', '4=511,5=40,6=511', rounds=5, skip=2)
# ---- Massacre / EvilSlash ----------------------------------------------------------
R('ms1', (13, 13, 13), '--q', q([(0x3F, 4), (0x40, 4), (0x40, 5)], [(0x40, 0), (0x3F, 1), (0x40, 2)]),
  '--st', '4:2=0x83', *TOUGH, rounds=4)
R('ms2', (37, 99, 223), '--q', q([(0x40, 4), (0x40, 5), (0x40, 6)], [(0x40, 0), (0x40, 1), (0x40, 2)]),
  '--st', '5:2=0x40,1:5=0x01,2:2=0x10', *TOUGH, rounds=6, skip=3)
R('ms3', (37, 99, 223), '--q', q([(0x40, 4), (0x3F, 5), (0x40, 6)], [(0x3F, 0), (0x40, 1), (0x40, 2)]),
  '--atk', '0=8,1=300,2=45', *TOUGH, rounds=6, skip=8)
R('ms4', (37, 99), '--q', q([(0x3F, 4), (0x3F, 5), (0x40, 4)], [(0x3F, 0), (0x3F, 1), None]),
  *TOUGH, rounds=8, skip=13)
R('ms5', (37, 99, 13), '--q', q([(0x3F, 0xFF), (0x3F, 6), (0x3A, 4)], [(0x3F, 0xFF), (0x3F, 2), (0x3F, 0)]),
  '--hp', '0=999,1=999,2=999,4=999,5=999,6=60', *TOUGH, rounds=8, skip=2, hp=[])
# ---- natural enemy AI with the F4 skills (enemies unforced; the party idles) -------------
PIDLE = '0=0x9c:4,1=0x9c:4,2=0x9c:4'
for nm, eids, sk in (('mk', (55, 55, 56), 0), ('ogre', (170, 170, 170), 3), ('raven', (50, 50, 50), 5),
                     ('gigas', (79, 80, 64), 1), ('hopper', (6, 32, 34), 2), ('drak', (46, 107, 125), 4),
                     ('servant', (149, 150, 177), 6), ('bean', (27, 70, 87), 7)):
    R(f'ai_{nm}', eids, '--q', PIDLE, *TOUGH, rounds=10, skip=sk)
# ---- Focus --------------------------------------------------------------------------
R('fo1', (13, 13, 13), *QR(([(0x54, 0), (0x54, 1), (0x54, 2)], [(0x54, 4), (0x54, 5), None]),
                           ([(0x3A, 4), (0x41, 1), (0x03, 4)], [(0x3A, 0), (0x50, 0), None]),
                           ([(0x3A, 4), (0x3A, 5), (0x3A, 6)], [None, None, None])),
  *TOUGH, rounds=4)
R('fo2', (37, 99, 13), *QR(([(0x54, 0), (0x54, 1), (0x54, 2)], [(0x54, 4), (0x54, 5), (0x54, 6)]),
                           ([(0x44, 4), (0x2B, 1), (0x40, 6)], [(0x5C, 0), (0x51, 1), (0x41, 6)]),
                           ([(0x54, 0), (0x9C, 4), (0x54, 2)], [(0x54, 4), None, None]),
                           ([(0x57, 4), (0x3A, 5), (0x42, 4)], [(0x3A, 0), (0x3A, 1), (0x3A, 2)]),
                           ([(0x3A, 4), (0x3A, 5), (0x9C, 4)], [(0x3A, 0), (0x3A, 1), (0x3A, 2)])),
  *TOUGH, rounds=6, skip=6)
# ---- confused actors: HitEnemy $9A rolls (and crits), HitAlly $99 does not ---------------
R('conf1', (99, 37, 13), '--q', q(ATT_P, ATT_E), '--st', '0:2=0x10,1:2=0x10,2:2=0x10,4:2=0x10,5:2=0x10',
  '--critrng', 'all=0', '--dc3c', '0=5,1=5,2=5', *TOUGH, rounds=6)
R('conf2', (99, 99, 13), '--q', q(ATT_P, ATT_E), '--st', '0:2=0x10,1:2=0x10,2:2=0x10,4:2=0x10,5:2=0x10',
  *TOUGH, rounds=8, skip=5)
# ---- $DB42 commit rolls with the RNG injected over the skill classes -----------------
# AI base pokes ($DC44+idx: 0-2 cat1, 8-10 cat2, 16-18 cat3, 24-26 w3) that walk
# both ladders' bands (A: <$81 / $A2 / $C3 / $E4 / else; B: >=$80 / $60 / $3F / $1E / else)
AIB_SETS = []
for _i, (_a, _b) in enumerate(((0x81, 0x7F), (0xA1, 0x60), (0xA2, 0x5F), (0xC2, 0x3F), (0xC3, 0x3E),
                               (0xE3, 0x1E), (0xE4, 0x1D))):
    _c = (0x80, 0xFF, 0x00)[_i % 3]
    AIB_SETS.append(f'0={_a:#x},1={_b:#x},2={_c:#x},8={_b:#x},9={_a:#x},10={_c:#x},'
                    f'16={_a:#x},17={_b:#x},18={_c:#x},24={_a:#x},25={_b:#x},26={_c:#x}')
CLASSES = [0x3A, 0x44, 0x00, 0x12, 0x2B, 0x8D, 0x90, 0x93, 0x91, 0x8C, 0x77, 0x81, 0x82, 0x55,
           0x67, 0xD6, 0x1E, 0x52, 0x14, 0x7E]
for v in (0, 1, 3, 7, 15):
    for j in range(0, len(CLASSES), 3):
        ks = (CLASSES + CLASSES)[j:j + 3]
        R(f'db42_v{v}_{j}', (13, 13, 13), '--q', q([(ks[0], 4), (ks[1], 4), (ks[2], 4)], [None, None, None]),
          '--db42rng', str(v), '--aib', AIB_SETS[j // 3], '--lean',
          rounds=3, skip=v + j)
# per-table distinct bases so every class's base table + ladder is discriminated (HIGH:
# ladder A thresholds cat1 8 / cat2 1 / cat3 4 / w3 2; LOW: ladder B cat1 $10 / cat2 2 /
# cat3 4 / w3 8) at post-step RNG1 values straddling them
CLS2 = [0x12, 0x2B, 0x8D, 0x8C, 0x77, 0x81, 0x82, 0x90, 0x91, 0x93, 0x3A, 0x00, 0x55, 0xD6, 0x1E]
for band, (b1, b2, b3, bw), rngs in (('hi', (0xFF, 0x82, 0xC3, 0xA2), (0, 1, 2, 3)),
                                     ('lo', (0x10, 0x70, 0x40, 0x20), (1, 3, 7, 15))):
    aib = ','.join(f'{base + s}={v:#x}' for base, v in ((0, b1), (8, b2), (16, b3), (24, bw)) for s in range(3))
    for v in rngs:
        for j in range(0, len(CLS2), 3):
            ks = CLS2[j:j + 3]
            R(f'db42{band}_v{v}_{j}', (13, 13, 13), '--q', q([(ks[0], 4), (ks[1], 4), (ks[2], 4)], [None, None, None]),
              '--db42rng', str(v), '--aib', aib, '--lean', rounds=2, skip=v + j)
R('db42_sand', (13, 13, 13), '--q', q([(0x3A, 4), (0x3A, 4), (0x3A, 4)], [None, None, None]),
  '--st', '0:7=0x04,1:7=0x08', '--db42rng', '1', '--aib', '24=0x10,25=0x70,26=0x90', '--lean', rounds=3)

DROP_TAGS = {'state3', 'state7', 'miss_pass', 'skill_load', 'calcdef_out', 'gates_in', 'curse_stage',
             'dupconv', 'reresolve', 'dead_redirect', 'forced', 'round_end', 'side_wipe', 'guard_redir'}
KEEP = {'tag', 'sc', 'frame', 'db88', 'db89', 'db8a', 'dcfd', 'dcfe', 'dcff', 'rng1', 'rng2', 'st', 'dcec',
        'dc3c', 'c86c', 'db73', 'db42', 'HL', 'db56', 'd9ec', 'dd1b', 'dd13', 'hp', 'maxhp', 'atk', 'dfn',
        'agl', 'res', 'db8b', 'db9b'}
ROLL_TAGS = {'db42_roll1', 'db42_roll2', 'db42_done', 'db42_roll1_raw', 'db42_roll2_raw'}


def pack(dst, srcs):
    """The fields/tags simulator/validate_f4.py reads (+ ai_bases on the
    $DB42 roll waypoints), gzipped."""
    import gzip, json
    out = []
    for src in srcs:
        for e in json.load(open(src)):
            if e['tag'] in DROP_TAGS:
                continue
            k = KEEP | ({'ai_bases'} if e['tag'] in ROLL_TAGS else set())
            out.append({x: e[x] for x in e if x in k})
    with gzip.open(dst, 'wt', compresslevel=9) as g:
        g.write(json.dumps(out, separators=(',', ':')))
    print(f'{dst}: {len(out)} events')


if __name__ == '__main__' and OUT == '--pack':
    pack(sys.argv[2], sys.argv[3:])
elif __name__ == '__main__':
    for name, args in RUNS:
        if FILT and FILT not in name:
            continue
        r = subprocess.run([sys.executable, os.path.join(ROOT, 'simulator', 'measure_f4.py')] + args +
                           ['--out', OUT], capture_output=True, text=True)
        print((r.stdout.strip().splitlines() or ['?'])[-1][:200], r.stderr.strip().splitlines()[-1:] if r.returncode else '')
