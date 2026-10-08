#!/usr/bin/env python3
"""S130 F1 corpus recipe: runs simulator/measure_f1.py once per battle below
(user's real save: u22.gbc + field.state, see measure_f1.py) and appends
every battle to ONE corpus (default simulator/f1_status_events.json).

Battle layout: 3 x eid 3 enemies (dup-conversion flag 0), party slots 0-2
and enemy slots 4-6 each FORCED to one F1 skill (party -> queued target 4,
enemies -> queued target 0), HP 999 / MP 250 everywhere so nobody dies or
runs dry; the victims' resistance types for the group are poked to one
level 0-3 (--eres/--pres); `rearm` round pokes clear the group's bits on
the victims each round so every round rolls again ('keep' battles leave
them, exercising the already-afflicted paths and the one-shot consumers);
row battles force the victims' +5 bit6 / bit7 ladder rows; sure battles
set $DB42 bit2 on every caster (Compare_6adc sure-hit); db73 0 = the wild
condition (BossProtectionGate open), the rig's default is 1 (boss).

Usage: measure_f1_campaign.py [--out FILE(.json|.json.gz)] [--only NAME_PREFIX]
"""
import argparse, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ap = argparse.ArgumentParser()
ap.add_argument('--out', default=os.path.join(HERE, 'f1_status_events.json.gz'))
ap.add_argument('--only')
ap.add_argument('--frames', type=int, default=6000)
a = ap.parse_args()

# group -> (party skills slot0..2, enemy skills slot4..6, rtypes, +off -> AND mask)
G = {
    'g1': ((0x16, 0x19, 0x6F), (0x16, 0x19, 0x6F), (7, 11, 20), {2: 0x43}),
    'g2': ((0x6A, 0x6E, 0x6C), (0x6A, 0x6E, 0x6C), (7, 11, 18), {2: 0x60}),
    'g3': ((0x6D, 0xDA, 0x6B), (0x6D, 0xDA, 0x6B), (18, 11, 19), {2: 0xAC}),
    'g4': ((0x70, 0x78, 0x79), (0x70, 0x78, 0x79), (21,), {5: 0xC0}),
    'g5': ((0x7A, 0x7B, 0x7C), (0x7A, 0x7B, 0x7C), (12, 21), {5: 0xC0}),
    'g6': ((0x7D, 0x72, 0x73), (0x7D, 0x72, 0x73), (21, 6), {5: 0xC0, 7: 0xFC}),
    'g7': ((0x74, 0x91, 0x92), (0x74, 0x91, 0x92), (8, 22, 23), {5: 0x7F, 3: 0x3F}),
    'g8': ((0x15, 0x17, 0x18), (0x15, 0x17, 0x18), (7, 10, 6), {2: 0x73, 3: 0xFC}),
}


def pokes(slots, masks, extra=()):
    out = []
    for s in slots:
        for off, m in masks.items():
            out.append('0x%04X&=0x%02X' % (0xDB00 + 8 * s + off, m))
        for off, v in extra:
            out.append('0x%04X|=0x%02X' % (0xDB00 + 8 * s + off, v))
    return ','.join(out)


def battle(name, g, lev, rearm=True, row=0, sure=False, db73=None, frames=None, flyer=False,
           eonly=False, skip=0):
    ps, es, rts, masks = G[g]
    if eonly:
        ps = (0x8D, 0x8D, 0x8D)   # party only Defends: the enemy casters stay able to act
    args = [name, '3', '--ecount', '3', '--php3', '999', '--ehp', '999', '--pmp3', '250',
            '--emp', '250', '--frames', str(frames or a.frames), '--maxev', '6000',
            '--out', a.out, '--skip', str(skip)]
    for i, sk in enumerate(ps):
        args += ['--force', '%d:0x%02X:%d' % (i, sk, i if eonly else 4)]
    for i, sk in enumerate(es):
        args += ['--force', '%d:0x%02X:0' % (4 + i, sk)]
    res = ','.join('%d=%d' % (rt, lev) for rt in rts)
    args += ['--eres', res, '--pres', res]
    rp = []
    if rearm:
        rp.append(pokes((0, 1, 2, 4, 5, 6), masks))
    if row:
        rp.append(pokes((0, 1, 2, 4, 5, 6), {}, [(5, row)]))
    if sure:
        rp.append(','.join('0x%04X|=0x04' % (0xDB42 + s) for s in (0, 1, 2, 4, 5, 6)))
    if flyer:
        rp.append('0xDB8F|=0x10,0xDB8C|=0x10')     # slot 4 and party slot 1 fly
    for r in rp:
        args += ['--rpoke', r]
    if db73 is not None:
        args += ['--db73', str(db73)]
    return name, args


RUNS = []
for g in G:
    for lev in range(4):
        RUNS.append(battle(f'{g}_L{lev}', g, lev, db73=0 if g == 'g3' else None))
    RUNS.append(battle(f'{g}_keep', g, 1, rearm=False, frames=8000,
                       db73=0 if g == 'g3' else None))
RUNS.append(battle('g3_boss', 'g3', 0))                        # PalsyAir gated (db73 1)
for g in ('g1', 'g4', 'g5', 'g6', 'g7'):
    for row in (0x40, 0x80, 0xC0):
        RUNS.append(battle(f'{g}_row{row:02x}_L1', g, 1, row=row))
for g in ('g1', 'g4'):
    for row in (0x40, 0xC0):
        RUNS.append(battle(f'{g}_row{row:02x}_L2', g, 2, row=row))
for g in ('g1', 'g2', 'g3', 'g5', 'g6', 'g8'):
    RUNS.append(battle(f'{g}_sure_L2', g, 2, sure=True, db73=0 if g == 'g3' else None))
    RUNS.append(battle(f'{g}_sure_L3', g, 3, sure=True, db73=0 if g == 'g3' else None))
for g in G:                                                    # enemy-caster coverage
    for lev in range(3):
        RUNS.append(battle(f'{g}_E_L{lev}', g, lev, eonly=True, db73=0 if g == 'g3' else None,
                           skip=3 + lev))
RUNS.append(battle('g5_fly', 'g5', 0, flyer=True))
RUNS.append(battle('g5_fly_keep', 'g5', 0, rearm=False, flyer=True))


def beat(name, lev, db73, row=0, side='p'):
    base = [name, '3', '--ecount', '3', '--php3', '999', '--ehp', '999', '--pmp3', '250',
            '--emp', '250', '--frames', str(a.frames), '--maxev', '6000', '--out', a.out,
            '--eres', f'8={lev}', '--pres', f'8={lev}']
    if side == 'p':
        base += ['--force', '0:0x12:4', '--force', '1:0x13:4', '--force', '2:0x71:4']
    else:
        base += ['--force', '4:0x12:0', '--force', '5:0x13:0', '--force', '6:0x71:0']
    if db73 is not None:
        base += ['--db73', str(db73)]
    if row:
        base += ['--rpoke', pokes((0, 1, 2, 4, 5, 6), {}, [(5, row)])]
    return name, base


for lev in range(4):
    RUNS.append(beat(f'beat_w_L{lev}', lev, 0))
RUNS.append(beat('beat_boss_L0', 0, None))
RUNS.append(beat('beat_w_row80_L2', 2, 0, row=0x80))
RUNS.append(beat('beat_w_row40_L1', 1, 0, row=0x40))
RUNS.append(beat('beat_e_L1', 1, None, side='e'))
# the KO status wipe: victims carry +2/+3/+5/+7 and their shifted +8 marker
_ko = beat('beat_ko', 1, 0)
RUNS.append((_ko[0], _ko[1] + ['--rpoke', ','.join(
    '0x%04X|=0x%02X' % (0xDB00 + 8 * s + o, v) for s in (4, 5, 6)
    for o, v in ((2, 0x20), (3, 0xC0), (5, 0x40), (7, 0x03), (8, 0x80)))]))
RUNS.append(beat('beat_e_L2', 2, None, side='e'))

# specials: SideStep / FREEZY / BIGSLEEP / Ironize / IRONIZE
SP = ['3', '--ecount', '3', '--php3', '999', '--ehp', '999', '--pmp3', '250', '--emp', '250',
      '--maxev', '6000', '--out', a.out]
# SideStep on party slot 1 (slot 0 is a $DD0B=2 'tactics' member whose
# act-time re-decide, $53:$46A8, replaces a forced SideStep with Attack)
RUNS.append(('sp_step', ['sp_step'] + SP + ['--frames', '12000', '--force', '1:0x77:1', '--force', '2:0xAC:4',
             '--force', '4:0x77:4', '--force', '5:0xAC:0',
             '--rpoke', '0xDC05=0xF4,0xDC06=0x01,0xDC0B=0xF4,0xDC0C=0x01']))   # AGL 500 on slots 1/4
# SideStep CONSUMER: the stepped slots 1 / 4 (AGL poked 500 -> threshold $2B)
# are attacked 2x per round; slot 4's HP is restored every round
for k in (1, 2):
    RUNS.append((f'sp_dodge{k}', [f'sp_dodge{k}'] + SP + ['--frames', '15000', '--skip', str(5 * k),
                 '--force', '1:0x77:1', '--force', '0:0x3A:4', '--force', '2:0x3A:4',
                 '--force', '4:0x77:4', '--force', '5:0x3A:1', '--force', '6:0x3A:1',
                 '--rpoke', '0xDC05=0xF4,0xDC06=0x01,0xDC0B=0xF4,0xDC0C=0x01,0xDBAB=0xE7,0xDBAC=0x03']))
# SideStep re-armed every round (+7 bits3:2 cleared on the casters) -> one
# (RNG1&4)+4 step per caster per round
for k in (1, 2):
    RUNS.append((f'sp_rearm{k}', [f'sp_rearm{k}'] + SP + ['--frames', '10000', '--skip', str(7 * k),
                 '--force', '1:0x77:1', '--force', '2:0x77:2', '--force', '4:0x77:4', '--force', '5:0x77:5',
                 '--rpoke', '0xDB0F&=0xF3,0xDB17&=0xF3,0xDB27&=0xF3,0xDB2F&=0xF3']))
RUNS.append(('sp_bigsleep', ['sp_bigsleep'] + SP + ['--frames', '6000', '--force', '0:0xA7:4',
             '--force', '4:0xA7:0']))
RUNS.append(('sp_iron', ['sp_iron'] + SP + ['--frames', '8000', '--force', '0:0x2A:0',
             '--force', '4:0xDC:4', '--force', '5:0x2A:5']))

if __name__ == '__main__':
    import json, tempfile
    tmp = tempfile.mkdtemp(prefix='f1camp_', dir=os.path.dirname(os.path.abspath(a.out)))
    parts = []
    for name, args in RUNS:
        if a.only and not name.startswith(a.only):
            continue
        part = os.path.join(tmp, name + '.json')
        args = list(args)
        args[args.index('--out') + 1] = part          # one file per battle, merged below
        r = subprocess.run([sys.executable, os.path.join(HERE, 'measure_f1.py')] + args,
                           capture_output=True, text=True)
        print((r.stdout.strip().splitlines() or ['?'])[-1][:160], flush=True)
        if r.returncode:
            print(r.stderr[-2000:], flush=True)
        if os.path.exists(part):
            parts.append(part)
    allev = []
    for p in parts:
        allev += json.load(open(p))
    import gzip
    op = gzip.open if a.out.endswith('.gz') else open
    with op(a.out, 'wt') as fh:          # gzip: the uncompressed corpus is ~40 MB
        json.dump(allev, fh, separators=(',', ':'))
    print(f'{len(parts)} battles, {len(allev)} events -> {a.out}')
