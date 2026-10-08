#!/usr/bin/env python3
"""S130 F10 AI-chain rig: the bank $57 state-7 rule walker (hooks of the S81
simulator/measure_rules.py: $7865 skill entry, $7874 rule call, $7877 rule
return, $78A2 chain end, $788B veto) on boards prepared PER ROUND, for the
DeMagic $80 / ThickFog $83 pass conditions (simulator/validate_f10_rules.py).

Every 'skl' event carries the board the chain reads: HP/MaxHP/MP/MaxMP, the
64-byte status area + $DB40/41, $DD1B, $DD0B, the option lists $DC64 (8
(tag, skill) pairs per slot) and $C86C/$DB73.

Options:
  NAME EID [--ecount N] [--rounds N] [--skip N]
  --elist SLOT:tag:skill,...  force that enemy slot's option list ($DC64+16*SLOT)
                              every pre-act frame
  --poke ROUND:ADDR=VAL       set the byte at ADDR (hex) in every pre-act frame of
                              round ROUND ('all' = every round)
  --php/--pmp/--ehp/--emp     as measure_f10.py (HP/MP kept at max)
  --sched SLOT:skill@target,...  party queue forcing (as measure_f10.py)
Pre-act frames = $D9EC != 7 (the command/order phases), so the poked board
is the one the enemy AI decides on; the act phase runs unpoked.
Hook-safety: dense 4-on/4-off A cadence (PYBOY_DEBUGGING S80).
"""
import sys, json, os, argparse
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import *

SP = '/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/f10meas'
ap = argparse.ArgumentParser()
ap.add_argument('name'); ap.add_argument('eid', type=int)
ap.add_argument('--ecount', type=int, default=1)
ap.add_argument('--php', type=int); ap.add_argument('--pmp', type=int)
ap.add_argument('--emp', type=int); ap.add_argument('--ehp', type=int)
ap.add_argument('--elist', action='append', default=[])
ap.add_argument('--poke', action='append', default=[])
ap.add_argument('--sched', action='append', default=[])
ap.add_argument('--rounds', type=int, default=6)
ap.add_argument('--frames', type=int, default=40000)
ap.add_argument('--skip', type=int, default=0)
ap.add_argument('--rom', default=SP + '/u22.gbc')
ap.add_argument('--state', default=SP + '/field.state')
ap.add_argument('--out', default=SP + '/f10_rules.json')
ap.add_argument('--maxev', type=int, default=20000)
a = ap.parse_args()

HP, MHP, MP, MMP = 0xDBA3, 0xDBB3, 0xDBC3, 0xDBD3
events = []
p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)
for _ in range(a.skip):
    p.tick()
nrs = [0]


def w16s(m, ad):
    return [m[ad + 2 * i] | (m[ad + 2 * i + 1] << 8) for i in range(8)]


def board():
    m = p.memory
    return dict(hp=w16s(m, HP), mhp=w16s(m, MHP), mp=w16s(m, MP), mmp=w16s(m, MMP),
                st=list(m[0xDB00:0xDB42]), dd1b=list(m[0xDD1B:0xDD23]), dd0b=list(m[0xDD0B:0xDD13]),
                dd13=list(m[0xDD13:0xDD1B]), dc64=list(m[0xDC64:0xDCE4]), c86c=m[0xC86C],
                db73=m[0xDB73], res=list(m[0xDD28:0xDD60]), species=list(m[0xDC3C:0xDC44]))


def cap(tag, extra=None):
    if len(events) >= a.maxev:
        return
    m = p.memory
    e = dict(t=tag, sc=a.name, rnd=nrs[0], ai=m[0xDB88], skill=m[0xDB8A], dd6b=m[0xDD6B],
             dd26=m[0xDD26], dd27=m[0xDD27], d9ec=m[0xD9EC], frame=p.frame_count)
    if extra:
        e.update(extra)
    events.append(e)


def h_skill(_):
    cap('skl', dict(board=board()))


def h_call(_):
    hl = p.register_file.HL
    cap('rul', dict(rule=p.memory[hl] | (p.memory[hl + 1] << 8)))


def h_round(_):
    nrs[0] += 1


for bank, addr, cb in [(0x57, 0x7865, h_skill), (0x57, 0x7874, h_call),
                       (0x57, 0x7877, lambda _: cap('ret')), (0x57, 0x78A2, lambda _: cap('end')),
                       (0x57, 0x788B, lambda _: cap('vet')), (0x58, 0x54D1, h_round)]:
    p.hook_register(bank, addr, cb, None)

sched = {}
for s in a.sched:
    slot, lst = s.split(':', 1)
    sched[int(slot)] = [None if x == '-' else tuple(int(y, 0) for y in x.split('@')) for x in lst.split(',')]
elists = {}
for s in a.elist:
    slot, rest = s.split(':', 1)
    xs = rest.split(',')
    elists[int(slot)] = [tuple(int(y, 0) for y in x.split(':')) for x in xs]
pokes = []
for s in a.poke:
    rr, kv = s.split(':', 1); ad, v = kv.split('=')
    pokes.append((rr, int(ad, 16), int(v, 0)))

m = p.memory
m[0xDA03] = a.eid & 0xFF; m[0xDA04] = (a.eid >> 8) & 0xFF
m[0xDA02] = (a.ecount - 1) & 3
if a.ecount > 1:
    m[0xDA05] = m[0xDA03]; m[0xDA06] = m[0xDA04]
if a.ecount > 2:
    m[0xDA07] = m[0xDA03]; m[0xDA08] = m[0xDA04]
m[0xDA09] = 1; m[0xC905] = 0; m[0xC8EB] |= 0x40


def wr16(ad, v):
    m[ad] = v & 0xFF; m[ad + 1] = (v >> 8) & 0xFF


started = forced = False
cur = 0
for i in range(a.frames):
    if m[GAME_MODE] == 2:
        if not started:
            m[0xC8EB] &= ~0x40
        started = True
        if not forced and m[0xD9EC] <= 3 and m[0xD9ED] >= 1:
            forced = True
            if a.php is not None:
                wr16(HP, a.php); wr16(MHP, a.php)
            if a.pmp is not None:
                wr16(MP, a.pmp); wr16(MMP, a.pmp)
            for k in range(3):
                if a.emp is not None:
                    wr16(MP + 8 + 2 * k, a.emp); wr16(MMP + 8 + 2 * k, a.emp)
                if a.ehp is not None:
                    wr16(HP + 8 + 2 * k, a.ehp); wr16(MHP + 8 + 2 * k, a.ehp)
        if m[0xD9EC] == 4:
            cur = nrs[0]
        if forced and m[0xD9EC] != 7:
            for rr, ad, v in pokes:
                if rr in ('*', 'all') or int(rr) == cur:
                    m[ad] = v
            for slot, lst in elists.items():
                base = 0xDC64 + 16 * slot
                for k in range(8):
                    tg, sk = lst[k] if k < len(lst) else (0, 0xFF)
                    m[base + 2 * k] = tg; m[base + 2 * k + 1] = sk
            for s in range(8):                    # keep everyone alive and paid
                if m[0xDD1B + s] == 0:
                    wr16(HP + 2 * s, m[MHP + 2 * s] | (m[MHP + 2 * s + 1] << 8))
                    wr16(MP + 2 * s, m[MMP + 2 * s] | (m[MMP + 2 * s + 1] << 8))
        if 4 <= m[0xD9EC] <= 6:
            for slot, ent in sched.items():
                x = ent[min(cur, len(ent) - 1)]
                if x is not None and m[0xDD1B + slot] == 0:
                    m[0xDCEC + 2 * slot] = x[0]; m[0xDCED + 2 * slot] = x[1]
        if nrs[0] > a.rounds:
            break
    elif started:
        break
    if len(events) >= a.maxev:
        break
    if i % 8 < 4:
        p.button_press('a')
    else:
        p.button_release('a')
    p.tick(1, False)

old = []
if os.path.exists(a.out):
    old = [e for e in json.load(open(a.out)) if e['sc'] != a.name]
json.dump(old + events, open(a.out, 'w'), separators=(',', ':'))
sk = {}
for e in events:
    if e['t'] == 'skl':
        sk[e['skill']] = sk.get(e['skill'], 0) + 1
print(f'{a.name}: +{len(events)} events, chain runs per skill {sk}, rounds {nrs[0]}, frames {i}')
