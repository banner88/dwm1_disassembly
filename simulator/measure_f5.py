#!/usr/bin/env python3
"""S130 F5 (healing / revive / cures / MP economy) capture rig — the S85
loop-level rig (simulator/measure_battle.py: same snapshot, same waypoint
list, same hook-safety cadence) extended with:

  * generic per-slot pokes at battle INIT (phase <= 3, after the stat copy):
      --set SLOT:FIELD=VAL[,...]   FIELD in hp maxhp mp maxmp atk dfn agl int
                                   lvl dd0b dd03 dd1b dd13 db42 db8b, dead
                                   (HP 0 + $DD1B 1 + $DD13 $FF), or s<OFF>
                                   (status byte +OFF) — e.g. 1:hp=40,2:dead=1
  * per-frame queue forcing for ANY slot during phases 4-6 (command/order/
    fetch; never during act):  --q SLOT=SKILL[:TARGET]  (TARGET default =
    the slot's own side base; 'ff' = $FF re-resolve at act)
    --qrounds N  force only the first N rounds (then the AI commits)
  * F5 waypoints: the bank $52 handlers (SkillHeal $44C4, LoadBattle_607d,
    SkillVivify $44F8, Farewell $457E, the four cures, RobMagic $4308,
    OddDance $4A7B, the MP-drain roll SetHLBattle_5d25, Meditate $4D38,
    LifeSong $4D92, LifeDance $4DE9, HealUsAll $4F2C, MP0 $4F7F,
    RESTOREMP $4FFC) and the bank $53 entry-14 state-4 chain sub-states
    ($6AAD walk, $6ADD revive, $6B53 heal, $6B7E next, $696B caster roll,
    $6A04 caster apply, $6A79 caster MP:=0).
Every hook address was byte-compared clean ROM (1ca65793) vs u22.gbc.

Usage:
  measure_f5.py NAME EID [--ecount N] [--set ...] [--q ...] [--skip N]
      [--rom ROM] [--state STATE] [--out FILE] [--frames N] [--db73 N]
"""
import sys, json, os, argparse
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import *

S = '/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/f5meas'
ap = argparse.ArgumentParser()
ap.add_argument('name'); ap.add_argument('eid', type=int)
ap.add_argument('--ecount', type=int, default=1)
ap.add_argument('--set', action='append', default=[])
ap.add_argument('--q', action='append', default=[])
ap.add_argument('--qrounds', type=int, default=99)
ap.add_argument('--frames', type=int, default=9000)
ap.add_argument('--skip', type=int, default=0)
ap.add_argument('--rom', default=S + '/u22.gbc')
ap.add_argument('--state', default=S + '/field.state')
ap.add_argument('--out', default=S + '/f5_events.json')
ap.add_argument('--maxev', type=int, default=900)
ap.add_argument('--maxrounds', type=int, default=6)
ap.add_argument('--db73', type=int)
a = ap.parse_args()

RNG1, RNG2 = 0xC899, 0xC89A


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
        db56=m[0xDB56] | (m[0xDB57] << 8), dd6f=m[0xDD6F], dd69=m[0xDD69],
        dd72=m[0xDD72], dd73=m[0xDD73],
        dcfd=m[0xDCFD], dcfe=m[0xDCFE], db4c=m[0xDB4C], db4d=m[0xDB4D], db4e=m[0xDB4E],
        rng1=m[RNG1], rng2=m[RNG2], c86c=m[0xC86C], db73=m[0xDB73],
        db71=m[0xDB71] | (m[0xDB72] << 8), db54=m[0xDB54], da33=m[0xDA33],
        db79=arr(0xDB79, 9), dcec=arr(0xDCEC, 16),
        dd13=arr(0xDD13, 8), dd1b=arr(0xDD1B, 8), dd03=arr(0xDD03, 8),
        dd0b=arr(0xDD0B, 8), db8b=arr(0xDB8B, 8), db9b=arr(0xDB9B, 8),
        db42=arr(0xDB42, 8),
        hp=w16s(0xDBA3), maxhp=w16s(0xDBB3), mp=w16s(0xDBC3), maxmp=w16s(0xDBD3),
        ai_bases=[m[0xDC44 + i] for i in range(32)], wld=w16s(0xDC23),
        atk=w16s(0xDBE3), dfn=w16s(0xDBF3), agl=w16s(0xDC03), int=w16s(0xDC13),
        st=arr(0xDB00, 64), res=arr(0xDD28, 56),
        eid=[m[0xDA03] | (m[0xDA04] << 8), m[0xDA05] | (m[0xDA06] << 8),
             m[0xDA07] | (m[0xDA08] << 8)])


HOOKS = [
    (0x58, 0x54D1, 'round_start'), (0x53, 0x4546, 'actor_fetch'),
    (0x53, 0x454F, 'gates_in'), (0x53, 0x462C, 'forced'),
    (0x53, 0x45CD, 'curse_stage'), (0x53, 0x4C50, 'curse_hit'),
    (0x53, 0x4657, 'dupconv'), (0x53, 0x467C, 'skill_load'),
    (0x53, 0x520C, 'target_fetch'), (0x53, 0x4799, 'reresolve'),
    (0x53, 0x47E8, 'dead_redirect'), (0x53, 0x5747, 'miss_in'),
    (0x53, 0x5766, 'miss_rng'), (0x53, 0x5810, 'miss'), (0x53, 0x57F7, 'dodge'),
    (0x53, 0x582A, 'block'), (0x53, 0x586A, 'miss_pass'),
    (0x52, 0x60D7, 'calcdef_in'), (0x52, 0x679C, 'roll_in'),
    (0x52, 0x54E7, 'final_54e7'),
    (0x52, 0x6D56, 'apply_in'), (0x52, 0x7EE3, 'ko'),
    (0x50, 0x6B25, 'p9_slot'), (0x50, 0x6C14, 'p9_dot_apply'),
    (0x50, 0x6C59, 'p9_dot_ko'), (0x53, 0x4640, 'round_end'),
    (0x50, 0x6CBE, 'side_wipe'), (0x53, 0x4BEB, 'conf_pick'),
    (0x53, 0x5F3E, 'snap_roll'),
    # ---- F5 ----
    (0x52, 0x44C4, 'heal_in'),       # SkillHeal (also HealUsAll's tail call)
    (0x52, 0x607D, 'heal_607d'),     # LoadBattle_607d (amount / full-heal ids)
    (0x52, 0x44F8, 'vivify_in'),     # SkillVivify (Vivify/Revive/ALLREVIVE)
    (0x52, 0x457E, 'farewell_in'),
    (0x52, 0x458F, 'cure_in'), (0x52, 0x45A7, 'cure_in'),
    (0x52, 0x45D8, 'cure_in'), (0x52, 0x45FE, 'cure_in'),
    (0x52, 0x4308, 'robmagic_in'), (0x52, 0x4A7B, 'odddance_in'),
    (0x52, 0x5D25, 'mpdrain_roll'),  # SetHLBattle_5d25 (pre BattleRNG)
    (0x52, 0x5D7A, 'mpdrain_amt'),   # BattleTarget_5d7a
    (0x52, 0x4D38, 'meditate_in'), (0x52, 0x4D92, 'lifesong_in'),
    (0x52, 0x4DE9, 'lifedance_in'), (0x52, 0x4F2C, 'healusall_in'),
    (0x52, 0x4F7F, 'mp0_in'), (0x52, 0x4FFC, 'restoremp_in'),
    (0x53, 0x6AAD, 'chain_walk'), (0x53, 0x6ADD, 'chain_revive'),
    (0x53, 0x6B53, 'chain_heal'), (0x53, 0x6B7E, 'chain_next'),
    (0x53, 0x696B, 'chain_caster'), (0x53, 0x6A04, 'chain_capply'),
    (0x53, 0x6A79, 'chain_mp0'),
    # bank $58 per-skill target rows (commit-time entry 8 AND act re-resolve)
    (0x58, 0x44F7, 'row_heal'), (0x58, 0x469E, 'row_vivify'),
    (0x58, 0x46C7, 'row_antidote'), (0x58, 0x52A9, 'row_drain'),
    (0x58, 0x4CD1, 'row_drain'),
]

events = []
p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)
for _ in range(a.skip):
    p.tick()
def _cb(t):
    def cb(ctx):
        # $52:$6D56 (and the KO state) are re-entered every frame while the
        # apply animation waits: keep the FIRST hit of each run only.
        if t in ('apply_in', 'ko') and events and events[-1]['tag'] == t:
            return
        events.append(snap(p, t))
    return cb


for bank, addr, tag in HOOKS:
    p.hook_register(bank, addr, _cb(tag), None)

m = p.memory
m[0xDA03] = a.eid & 0xFF; m[0xDA04] = (a.eid >> 8) & 0xFF
m[0xDA02] = (a.ecount - 1) & 3
if a.ecount > 1:
    m[0xDA05] = m[0xDA03]; m[0xDA06] = m[0xDA04]
if a.ecount > 2:
    m[0xDA07] = m[0xDA03]; m[0xDA08] = m[0xDA04]
m[0xDA09] = 1; m[0xC905] = 0; m[0xC8EB] |= 0x40

W16 = dict(hp=0xDBA3, maxhp=0xDBB3, mp=0xDBC3, maxmp=0xDBD3, atk=0xDBE3, dfn=0xDBF3,
           agl=0xDC03, int=0xDC13)
B8 = dict(lvl=0xDB9B, dd0b=0xDD0B, dd1b=0xDD1B, dd13=0xDD13, db42=0xDB42, db8b=0xDB8B,
          dd03=0xDD03)
pokes = []
for spec in a.set:
    for kv in spec.split(','):
        lhs, val = kv.split('=')
        slot, field = lhs.split(':')
        pokes.append((int(slot), field, int(val, 0)))
queues = {}
for spec in a.q:
    s, rest = spec.split('=')
    s = int(s)
    if ':' in rest:
        sk, t = rest.split(':')
        t = int(t, 16) if t.lower() == 'ff' else int(t, 0)
    else:
        sk, t = rest, s & 4
    queues[s] = (int(sk, 0), t)


def do_pokes():
    for slot, field, v in pokes:
        if field == 'dead':                     # KO'd at init: HP 0, $DD1B 1, $DD13 $FF
            m[W16['hp'] + 2 * slot] = 0; m[W16['hp'] + 2 * slot + 1] = 0
            m[0xDD1B + slot] = 1; m[0xDD13 + slot] = 0xFF
        elif field in W16:
            ad = W16[field] + 2 * slot
            m[ad] = v & 0xFF; m[ad + 1] = (v >> 8) & 0xFF
        elif field in B8:
            m[B8[field] + slot] = v & 0xFF
        elif field.startswith('s'):
            m[0xDB00 + 8 * slot + int(field[1:])] = v & 0xFF
        else:
            raise SystemExit('bad field ' + field)


started = forced = False
for i in range(a.frames):
    if m[GAME_MODE] == 2:
        if not started:
            m[0xC8EB] &= ~0x40
        started = True
        if not forced and m[0xD9EC] <= 3 and m[0xD9ED] >= 1:
            forced = True
            do_pokes()
        if a.db73 is not None and m[0xD9EC] >= 1:
            m[0xDB73] = a.db73
        nrounds = sum(1 for e in events if e['tag'] == 'round_start')
        if 4 <= m[0xD9EC] <= 6 and nrounds < a.qrounds + (1 if m[0xD9EC] == 6 else 0):
            for s, (sk, t) in queues.items():
                if m[0xDD1B + s] == 0:
                    m[0xDCEC + 2 * s] = sk; m[0xDCED + 2 * s] = t
        if nrounds > a.maxrounds:
            break
    elif started:
        break
    if len(events) >= a.maxev:
        break
    if i % 8 < 4:
        p.button_press('a')
    else:
        p.button_release('a')
    p.tick()

old = []
if os.path.exists(a.out):
    old = [e for e in json.load(open(a.out)) if e['sc'] != a.name]
json.dump(old + events, open(a.out, 'w'))
tags = {}
for e in events:
    tags[e['tag']] = tags.get(e['tag'], 0) + 1
print(f'{a.name}: +{len(events)} events (total {len(old)+len(events)}) frames={i} {tags}')
