#!/usr/bin/env python3
"""S130 F2/F3 capture rig (single-hit physical variants + formula/HP-based
specials + record-spell extras). A copy-and-extend of the S85 loop rig
simulator/measure_battle.py: ONE rig battle (S75 TriggerBattle mimic) on the
user's real save, with every slot's queue forceable, per-slot HP/MP/status/
resistance/level pokes, and extra waypoints on the bank $52 helpers, the
state-4 caster tails, the bank $53 Sacrifice machine and the end of the
bank $53 post-calc stage. Every event carries the full board snapshot
(measure_battle.snap + $DC3C species ids + $DA33). Feeds
simulator/validate_f23_phys.py; corpus simulator/f23_phys_events.json.gz.

Usage:
  measure_f23_phys.py NAME EID [--ecount N] [--q 0=0x44:4,4=0x5c:0,...]
      [--hp 0=300,4=999] [--mp 0=250] [--keep] [--st 4:5=0x40,0:4=0x04]
      [--res 4:0=2,4:14=1] [--lvl 0=40] [--db73 N] [--db8b 4=1]
      [--frames N] [--skip N] [--out FILE] [--maxev N] [--rounds N]

--q forces queue entries (skill:target, target default = first enemy /
first party slot) during the command/order/fetch phases (4-6), like
measure_battle's --skill/--eskill. --hp/--mp poke current+max at battle init
and, with --keep, again at every command phase (so a long coverage battle
keeps everyone alive; the act phase is never touched). --st pokes status
bytes at init (and with --keep each command phase); --res pokes 2-bit
resistance levels into $DD28+7*slot at init; --lvl pokes $DB9B+slot.
Hook-safety (S80): dense 4-on/4-off A cadence; only once-per-action
addresses are hooked.
"""
import sys, json, os, argparse
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
from tools.pyboy_harness import *

SP = '/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/f23'

ap = argparse.ArgumentParser()
ap.add_argument('name'); ap.add_argument('eid', type=int)
ap.add_argument('--ecount', type=int, default=1)
ap.add_argument('--eids', help='per enemy slot EIDs a,b,c (overrides eid/ecount)')
ap.add_argument('--q', default='')
ap.add_argument('--hp', default=''); ap.add_argument('--mp', default='')
ap.add_argument('--keep', action='store_true')
ap.add_argument('--st', default=''); ap.add_argument('--res', default='')
ap.add_argument('--lvl', default=''); ap.add_argument('--db8b', default='')
ap.add_argument('--atk', default=''); ap.add_argument('--dfn', default=''); ap.add_argument('--agl', default='')
ap.add_argument('--db73', type=int)
ap.add_argument('--frames', type=int, default=9000)
ap.add_argument('--rounds', type=int, default=99)
ap.add_argument('--skip', type=int, default=0)
ap.add_argument('--rom', default=SP + '/u22.gbc')
ap.add_argument('--state', default=SP + '/field.state')
ap.add_argument('--out', default=SP + '/f23_events.json')
ap.add_argument('--maxev', type=int, default=900)
a = ap.parse_args()

RNG1, RNG2 = 0xC899, 0xC89A


def kv(spec):
    out = []
    for item in [x for x in spec.split(',') if x]:
        k, v = item.split('=')
        out.append((k, int(v, 0)))
    return out


QUEUE = {}
for item in [x for x in a.q.split(',') if x]:
    s, rest = item.split('=')
    sk, _, tg = rest.partition(':')
    s = int(s)
    QUEUE[s] = (int(sk, 0), int(tg, 0) if tg else (4 if s < 4 else 0))
HP = {int(k): v for k, v in kv(a.hp)}
MP = {int(k): v for k, v in kv(a.mp)}
LVL = {int(k): v for k, v in kv(a.lvl)}
DB8B = {int(k): v for k, v in kv(a.db8b)}
STATS = [(0xDBE3, {int(k): v for k, v in kv(a.atk)}), (0xDBF3, {int(k): v for k, v in kv(a.dfn)}),
         (0xDC03, {int(k): v for k, v in kv(a.agl)})]
ST = []
for k, v in kv(a.st):
    s, off = k.split(':')
    ST.append((int(s), int(off), v))
RES = []
for k, v in kv(a.res):
    s, rt = k.split(':')
    RES.append((int(s), int(rt), v))


def snap(p, tag):
    m = p.memory
    def arr(ad, n): return list(m[ad:ad + n])
    def w16s(ad): return [m[ad + 2 * i] | (m[ad + 2 * i + 1] << 8) for i in range(8)]
    return dict(
        tag=tag, sc=a.name, frame=p.frame_count,
        A=p.register_file.A,
        d9ec=m[0xD9EC], d9ed=m[0xD9ED], d9ee=m[0xD9EE],
        db77=m[0xDB77], db78=m[0xDB78], db82=m[0xDB82],
        db88=m[0xDB88], db89=m[0xDB89], db8a=m[0xDB8A],
        db56=m[0xDB56] | (m[0xDB57] << 8), dd6f=m[0xDD6F],
        db5a=m[0xDB5A] | (m[0xDB5B] << 8),
        dcfd=m[0xDCFD], dcfe=m[0xDCFE], db4c=m[0xDB4C], db4d=m[0xDB4D], db4e=m[0xDB4E],
        rng1=m[RNG1], rng2=m[RNG2], c86c=m[0xC86C], db73=m[0xDB73],
        db71=m[0xDB71] | (m[0xDB72] << 8), db54=m[0xDB54], da33=m[0xDA33], db86=m[0xDB86],
        db79=arr(0xDB79, 9), dcec=arr(0xDCEC, 16),
        dd13=arr(0xDD13, 8), dd1b=arr(0xDD1B, 8), dd03=arr(0xDD03, 8),
        dd0b=arr(0xDD0B, 8), db8b=arr(0xDB8B, 8), db9b=arr(0xDB9B, 8),
        db42=arr(0xDB42, 8), dc3c=arr(0xDC3C, 8), dd69=m[0xDD69],
        hp=w16s(0xDBA3), maxhp=w16s(0xDBB3), mp=w16s(0xDBC3), maxmp=w16s(0xDBD3),
        atk=w16s(0xDBE3), dfn=w16s(0xDBF3), agl=w16s(0xDC03), int=w16s(0xDC13),
        st=arr(0xDB00, 66), res=arr(0xDD28, 56),
        eid=[m[0xDA03] | (m[0xDA04] << 8), m[0xDA05] | (m[0xDA06] << 8),
             m[0xDA07] | (m[0xDA08] << 8)])


HOOKS = [
    # --- the S85 loop waypoints (measure_battle.py) ---
    (0x58, 0x54D1, 'round_start'), (0x53, 0x4546, 'actor_fetch'),
    (0x53, 0x454F, 'gates_in'), (0x53, 0x462C, 'forced'),
    (0x53, 0x45CD, 'curse_stage'), (0x53, 0x4657, 'dupconv'),
    (0x53, 0x467C, 'skill_load'), (0x53, 0x520C, 'target_fetch'),
    (0x53, 0x4799, 'reresolve'), (0x53, 0x47E8, 'dead_redirect'),
    (0x53, 0x5747, 'miss_in'), (0x53, 0x5766, 'miss_rng'),
    (0x53, 0x5810, 'miss'), (0x53, 0x57F7, 'dodge'), (0x53, 0x582A, 'block'),
    (0x53, 0x586A, 'miss_pass'),
    (0x52, 0x60D7, 'calcdef_in'), (0x52, 0x61EC, 'calcdef_out'),
    (0x52, 0x679C, 'roll_in'),
    (0x52, 0x54E7, 'final_54e7'), (0x52, 0x54EA, 'final_54ea'),
    (0x52, 0x5C51, 'status_in'),
    (0x52, 0x6D56, 'apply_in'), (0x52, 0x7EE3, 'ko'),
    (0x50, 0x6B25, 'p9_slot'), (0x50, 0x6C14, 'p9_dot_apply'),
    (0x53, 0x4640, 'round_end'), (0x50, 0x6CBE, 'side_wipe'),
    (0x53, 0x5544, 'guard_redir'),
    # --- S130 F2/F3 additions ---
    (0x52, 0x6ACB, 'species_fam'),   # LookupTargetSpecies after the bank $03 call: $DA33 = family
    (0x52, 0x62DC, 'metalcut_in'),
    (0x52, 0x6381, 'multicut_in'),
    (0x52, 0x641A, 'windbeast_in'), (0x52, 0x6491, 'vacuum_in'),
    (0x52, 0x653E, 'megamagic_in'), (0x52, 0x6232, 'kamikaze_in'),
    (0x52, 0x6214, 'ramming_in'), (0x52, 0x66BA, 'callevil_in'),
    (0x52, 0x5539, 'barrier_in'),
    (0x52, 0x77C8, 'twin_tail0'), (0x52, 0x77E2, 'twin_tail'),
    (0x52, 0x7892, 'kami_tail0'), (0x52, 0x78A3, 'kami_tail'),
    (0x52, 0x79A4, 'ram_tail0'), (0x52, 0x79B5, 'ram_tail'),
    (0x52, 0x7840, 'tail_out'), (0x52, 0x78EA, 'tail_out'),
    (0x53, 0x5A6F, 'postcalc_out'),  # end of the bank $53 post-calc stage
    (0x53, 0x5888, 'crit_gate'),     # flags8 bit4 crit decision entry
    (0x53, 0x67A9, 'sacr_in'), (0x53, 0x67DB, 'sacrifice_roll'),
    (0x53, 0x6866, 'sacr_apply'), (0x53, 0x68B4, 'sacr_next'),
    (0x53, 0x6971, 'sacr_self'), (0x53, 0x6A04, 'sacr_self_apply'),
    (0x52, 0x6E89, 'state4'),        # state-4 tail dispatcher
]

# verify every hook site is byte-identical between the clean build and the ROM
_clean = os.path.join(ROOT, 'disassembly', 'game.gbc')
if os.path.exists(_clean):
    c = open(_clean, 'rb').read(); r = open(a.rom, 'rb').read()
    for bank, addr, tag in HOOKS:
        o = bank * 0x4000 + addr - 0x4000
        if c[o:o + 3] != r[o:o + 3]:
            print('WARNING hook site differs from clean build:', tag, hex(bank), hex(addr))

events = []
p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)
for _ in range(a.skip):
    p.tick(1, False)
for bank, addr, tag in HOOKS:
    p.hook_register(bank, addr, (lambda ctx, t=tag: events.append(snap(p, t))), None)

eids = [int(x, 0) for x in a.eids.split(',')] if a.eids else [a.eid] * a.ecount
p.memory[0xDA02] = (len(eids) - 1) & 3
for j, e in enumerate(eids):
    p.memory[0xDA03 + 2 * j] = e & 0xFF; p.memory[0xDA04 + 2 * j] = (e >> 8) & 0xFF
p.memory[0xDA09] = 1; p.memory[0xC905] = 0; p.memory[0xC8EB] |= 0x40


def poke_stats(m, init):
    for s, v in HP.items():
        if init or m[0xDD1B + s] == 0:
            m[0xDBA3 + 2*s] = v & 0xFF; m[0xDBA4 + 2*s] = v >> 8
            m[0xDBB3 + 2*s] = v & 0xFF; m[0xDBB4 + 2*s] = v >> 8
    for s, v in MP.items():
        m[0xDBC3 + 2*s] = v & 0xFF; m[0xDBC4 + 2*s] = v >> 8
        m[0xDBD3 + 2*s] = v & 0xFF; m[0xDBD4 + 2*s] = v >> 8
    for s, off, v in ST:
        m[0xDB00 + 8*s + off] = v
    for s, v in LVL.items():
        m[0xDB9B + s] = v
    for s, v in DB8B.items():
        m[0xDB8B + s] = v
    for base, d in STATS:
        for s, v in d.items():
            m[base + 2*s] = v & 0xFF; m[base + 2*s + 1] = v >> 8


started = False
forced = False
last_phase = None
rounds = 0
for i in range(a.frames):
    m = p.memory
    if m[GAME_MODE] == 2:
        if not started:
            m[0xC8EB] &= ~0x40 & 0xFF
        started = True
        if not forced and m[0xD9EC] <= 3 and m[0xD9ED] >= 1:
            forced = True
            poke_stats(m, True)
            for s, rt, lv in RES:
                pos = rt + 1
                ad = 0xDD28 + 7*s + (pos >> 2)
                sh = (3 - (pos & 3)) * 2
                m[ad] = (m[ad] & ~(3 << sh) & 0xFF) | ((lv & 3) << sh)
        ph = m[0xD9EC]
        if a.keep and ph == 4 and last_phase != 4:
            poke_stats(m, False)
            rounds += 1
        last_phase = ph
        if a.db73 is not None and ph >= 1:
            m[0xDB73] = a.db73
        if 4 <= ph <= 6:
            for s, (sk, tg) in QUEUE.items():
                m[0xDCEC + 2*s] = sk; m[0xDCED + 2*s] = tg
    elif started:
        break
    if len(events) >= a.maxev or rounds > a.rounds:
        break
    if i % 8 < 4:
        p.button_press('a')
    else:
        p.button_release('a')
    p.tick(1, False)

# keep only what simulator/validate_f23_phys.py reads (the gate / curse / AI
# waypoints exist for hook-cadence parity with measure_battle.py)
KEEP = {'round_start', 'actor_fetch', 'target_fetch', 'miss_in', 'miss_rng', 'miss', 'dodge',
        'block', 'miss_pass', 'crit_gate', 'calcdef_in', 'roll_in', 'windbeast_in', 'vacuum_in',
        'megamagic_in', 'kamikaze_in', 'ramming_in', 'postcalc_out', 'apply_in', 'ko',
        'species_fam', 'twin_tail', 'kami_tail', 'ram_tail', 'tail_out', 'sacr_in',
        'sacrifice_roll', 'sacr_apply', 'sacr_next', 'sacr_self', 'sacr_self_apply', 'p9_slot',
        'status_in'}
events = [e for e in events if e['tag'] in KEEP]
for e in events:
    e['rig_db8b'] = sorted(DB8B)       # slots whose $DB8B the rig poked
old = []
if os.path.exists(a.out):
    old = json.load(open(a.out))
json.dump(old + events, open(a.out, 'w'), separators=(',', ':'))
tags = {}
for e in events:
    tags[e['tag']] = tags.get(e['tag'], 0) + 1
print(f'{a.name}: +{len(events)} events (total {len(old)+len(events)}) frames={i} rounds={rounds} {tags}')
