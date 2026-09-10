#!/usr/bin/env python3
"""S85 LOOP-LEVEL battle capture rig: runs ONE complete rig battle (S75
TriggerBattle mimic) on the real save and records a waypoint event stream
covering the whole round loop — round start (turn-order build entry, with the
full action queue the AI/menu committed), per-actor fetch + status gates +
forced actions + the duplicate-group-cast conversion, act-time target
resolution, the bank $53 MISS/dodge gate machine (with its post-step RNG),
the bank $52 APPLY step (per victim), KO, and the phase-9 end-of-round
processor (status decay, DoT roll + apply, DoT KO) — for
simulator/validate_battle.py.

Every event carries a FULL board snapshot (all 8 slots: stats, HP/MP,
status blocks, queue, order list, life/readiness marks, RNG) so the
validator can replay each step from the engine's own pre-state and diff the
model's post-state against the next event.

Usage:
  measure_battle.py NAME EID [--ecount N] [--pskills e5,e6,..] [--php N]
      [--skill N --target N] [--eskill N --etarget N] [--frames N]
      [--rom ROM] [--state BOOTSTATE] [--out FILE] [--skip N]

--pskills rewrites the save's slot-0 skill list BEFORE the battle (real
record, canonicalizer-safe: post-load, pre-battle). --skill/--eskill force
the queue per-frame (bypasses the AI commit — use only for coverage runs;
leave both unset to capture the engine's natural AI/tactics flow).

Hook-safety protocol (S80, PYBOY_DEBUGGING): dense 4-on/4-off A cadence; no
per-frame-polled addresses are hooked ($53:$44E0 is polled every frame and
is deliberately NOT a waypoint — $4546/$454F fire once per actor).

S85 corpus recipe (simulator/s85_battle_events.json; `R` = this script with
--out corpus.json, run in order, patched ROM 4c8de38a + boot.state from the
hacked .sav):
  grem_a 7 --php 200
  grem_b 7 --php 200 --skip 37
  slime_q 1 --pskills 0xe5,0xe6,0xe7,0xe8 --php 200 --skip 11
  ant3 3 --ecount 3 --php 300 --skip 5
  grem3 7 --ecount 3 --php 400 --pmp 250 --skip 23
  grem3b 7 --ecount 3 --php 400 --pmp 250 --skip 61
  die_a 3 --ecount 2 --skip 3
  beat 7 --skill 0x12 --php 200 --skip 9
  sleep_e 3 --skill 0x15 --php 200 --skip 13
  sleep_p 3 --eskill 0x15 --emp 50 --php 200 --skip 17
  surround_p 3 --eskill 0x18 --emp 50 --php 200 --ehp 150 --skip 19
  surround_e 3 --skill 0x18 --php 200 --ehp 150 --skip 21
  poison_p 3 --eskill 0x6d --emp 50 --php 200 --ehp 150 --skip 29
  poisonhit_p 3 --eskill 0x67 --emp 50 --php 50 --ehp 150 --skip 43
  sacrifice 7 --skill 0x14 --php 200 --skip 31
  kamikaze 7 --skill 0x3e --php 200 --skip 33
  stopspell 7 --skill 0x17 --php 200 --skip 41
  paralyze_p 3 --eskill 0x69 --emp 50 --php 200 --ehp 150 --skip 47
  curse_st 3 --pst 2=0x20 --php 200 --ehp 200 --skip 53
  heavy_st 3 --pst 2=0x02 --php 300 --ehp 200 --skip 59
  stun_st 3 --est 7=0x80 --php 200 --ehp 200 --skip 67
  nomp 3 --eskill 0x15 --php 200 --skip 71
  pko 3 --ecount 2 --phpcur 5 --skip 73
  heal_e 7 --ecount 2 --php 300 --pmp 250 --skip 79 --ehp 60
  sleep_e2 3 --skill 0x15 --php 200 --ehp 120 --skip 83
"""
import sys, json, os, argparse
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import *

ap = argparse.ArgumentParser()
ap.add_argument('name'); ap.add_argument('eid', type=int)
ap.add_argument('--ecount', type=int, default=1)
ap.add_argument('--pskills')
ap.add_argument('--php', type=int)
ap.add_argument('--phpcur', type=int, help='force party slot-0 CURRENT HP only')
ap.add_argument('--pmp', type=int)
ap.add_argument('--emp', type=int); ap.add_argument('--ehp', type=int)
ap.add_argument('--pst', help='poke party slot-0 status block: off=val,off=val (after init)')
ap.add_argument('--est', help='poke enemy slot-4 status block: off=val,...')
ap.add_argument('--skill', type=lambda x: int(x, 0)); ap.add_argument('--target', type=int, default=4)
ap.add_argument('--eskill', type=lambda x: int(x, 0)); ap.add_argument('--etarget', type=int, default=0)
ap.add_argument('--frames', type=int, default=6000)
ap.add_argument('--skip', type=int, default=0)
ap.add_argument('--rom', default='/home/claude/trace/patched_s85.gbc')
ap.add_argument('--state', default='/home/claude/trace/boot.state')
ap.add_argument('--out', default='/home/claude/trace/battle_events.json')
ap.add_argument('--maxev', type=int, default=400)
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
        db56=m[0xDB56] | (m[0xDB57] << 8), dd6f=m[0xDD6F],
        dcfd=m[0xDCFD], dcfe=m[0xDCFE], db4c=m[0xDB4C], db4d=m[0xDB4D], db4e=m[0xDB4E],
        rng1=m[RNG1], rng2=m[RNG2], c86c=m[0xC86C], db73=m[0xDB73],
        db71=m[0xDB71] | (m[0xDB72] << 8), db54=m[0xDB54], da33=m[0xDA33],
        db79=arr(0xDB79, 9), dcec=arr(0xDCEC, 16),
        dd13=arr(0xDD13, 8), dd1b=arr(0xDD1B, 8), dd03=arr(0xDD03, 8),
        dd0b=arr(0xDD0B, 8), db8b=arr(0xDB8B, 8), db9b=arr(0xDB9B, 8),
        db42=arr(0xDB42, 8),
        hp=w16s(0xDBA3), maxhp=w16s(0xDBB3), mp=w16s(0xDBC3),
        atk=w16s(0xDBE3), dfn=w16s(0xDBF3), agl=w16s(0xDC03), int=w16s(0xDC13),
        st=arr(0xDB00, 64), res=arr(0xDD28, 56),
        eid=[m[0xDA03] | (m[0xDA04] << 8), m[0xDA05] | (m[0xDA06] << 8),
             m[0xDA07] | (m[0xDA08] << 8)])

events = []
p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)
for _ in range(a.skip):
    p.tick()

if a.pskills:
    sk = [int(x, 0) for x in a.pskills.split(',')] + [0xFF] * 8
    for i in range(8):
        p.memory[0xCAC1 + 41 + i] = sk[i]

HOOKS = [
    (0x58, 0x54D1, 'round_start'),   # TurnOrderBuild entry (queue complete)
    (0x53, 0x4546, 'actor_fetch'),   # A = actor idx from $DB79[$DB82]
    (0x53, 0x454F, 'gates_in'),      # $DD13[actor] readiness check
    (0x53, 0x462C, 'forced'),        # A = forced action code (status gate hit)
    (0x53, 0x45CD, 'curse_stage'),   # post LoadBtlC_4e33 RNG step
    (0x53, 0x4C50, 'curse_hit'),     # CurseSelfHit_4c50
    (0x53, 0x4657, 'dupconv'),       # duplicate group cast -> $3A
    (0x53, 0x467C, 'skill_load'),    # normal path: skill -> $DB8A
    (0x53, 0x520C, 'target_fetch'),  # act state 0: $DB89 <- queue (may be $FF)
    (0x53, 0x4799, 'reresolve'),     # TargetReResolve_4799
    (0x53, 0x47E8, 'dead_redirect'), # DeadTargetRedirectScan_47e8
    (0x53, 0x5747, 'miss_in'),       # MISS machine entry (target resolved)
    (0x53, 0x5766, 'miss_rng'),      # post RNG step inside the machine
    (0x53, 0x5810, 'miss'),          # surround / self-miss route
    (0x53, 0x57F7, 'dodge'),         # dodge route
    (0x53, 0x582A, 'block'),         # flags7b7 block route
    (0x53, 0x586A, 'miss_pass'),     # act state $A: proceed
    (0x52, 0x60D7, 'calcdef_in'),    # CalcSkillDefense entry (RNG pre-step)
    (0x52, 0x679C, 'roll_in'),       # record power roll (reads RNG1)
    (0x52, 0x54E7, 'final_54e7'),    # final $DB56 after multipliers/ladders
    (0x53, 0x67DB, 'sacrifice_roll'),
    (0x52, 0x5C51, 'status_in'),     # BattleCall_5c51: Beat-class hit ladder entry (RNG pre-step)
    (0x52, 0x5C8F, 'status_roll'),   # SetHLBattle_5c8f: Sleep hit ladder ($6710) entry
    (0x52, 0x5CBC, 'status_roll'),   # SetHLBattle_5cbc: StopSpell ladder ($6749) entry
    (0x52, 0x5CDA, 'status_roll'),   # SetHLBattle_5cda: Surround ladder entry
    (0x52, 0x65B5, 'statchance_in'), # BattleCall_65b5 status-chance helper (PoisonHit class)
    (0x52, 0x65C9, 'statchance_in'),
    (0x52, 0x4200, 'hit_path'),      # BtlOutcomeHitPath_4200
    (0x52, 0x4225, 'miss_path'),     # BtlOutcomeMissPath_4225
    (0x52, 0x6D56, 'apply_in'),      # BtlActState2Apply (per victim)
    (0x52, 0x7EE3, 'ko'),            # act state $1A
    (0x50, 0x6B25, 'p9_slot'),       # phase 9 sub 2 per-combatant entry
    (0x50, 0x6C14, 'p9_dot_apply'),  # sub 3: $DB56 = DoT, HP pre-subtract
    (0x50, 0x6C59, 'p9_dot_ko'),
    (0x53, 0x4640, 'round_end'),     # $DB82==9 -> next phase
    (0x50, 0x6CBE, 'side_wipe'),
]
for bank, addr, tag in HOOKS:
    p.hook_register(bank, addr, (lambda ctx, t=tag: events.append(snap(p, t))), None)

p.memory[0xDA03] = a.eid & 0xFF; p.memory[0xDA04] = (a.eid >> 8) & 0xFF
p.memory[0xDA02] = (a.ecount - 1) & 3
if a.ecount > 1:
    p.memory[0xDA05] = p.memory[0xDA03]; p.memory[0xDA06] = p.memory[0xDA04]
if a.ecount > 2:
    p.memory[0xDA07] = p.memory[0xDA03]; p.memory[0xDA08] = p.memory[0xDA04]
p.memory[0xDA09] = 1; p.memory[0xC905] = 0; p.memory[0xC8EB] |= 0x40

started = False
forced = False
for i in range(a.frames):
    if p.memory[GAME_MODE] == 2:
        started = True
        m = p.memory
        # stat forcing only during battle INIT (phase <= 3, after the stat
        # copy) so the engine's own HP bookkeeping is what we observe.
        if not forced and m[0xD9EC] <= 3 and m[0xD9ED] >= 1:
            forced = True
            if a.php is not None:
                m[0xDBA3] = a.php & 0xFF; m[0xDBA4] = a.php >> 8
                m[0xDBB3] = a.php & 0xFF; m[0xDBB4] = a.php >> 8
            if a.phpcur is not None:
                m[0xDBA3] = a.phpcur & 0xFF; m[0xDBA4] = a.phpcur >> 8
            if a.pmp is not None:
                m[0xDBC3] = a.pmp & 0xFF; m[0xDBC4] = a.pmp >> 8
                m[0xDBD3] = a.pmp & 0xFF; m[0xDBD4] = a.pmp >> 8
            for k in range(3):
                if a.emp is not None:
                    m[0xDBC3 + 8 + 2*k] = a.emp & 0xFF; m[0xDBC4 + 8 + 2*k] = a.emp >> 8
                    m[0xDBD3 + 8 + 2*k] = a.emp & 0xFF; m[0xDBD4 + 8 + 2*k] = a.emp >> 8
                if a.ehp is not None:
                    m[0xDBA3 + 8 + 2*k] = a.ehp & 0xFF; m[0xDBA4 + 8 + 2*k] = a.ehp >> 8
                    m[0xDBB3 + 8 + 2*k] = a.ehp & 0xFF; m[0xDBB4 + 8 + 2*k] = a.ehp >> 8
            for spec, base in ((a.pst, 0xDB00), (a.est, 0xDB20)):
                if spec:
                    for kv in spec.split(','):
                        off, val = kv.split('=')
                        m[base + int(off, 0)] = int(val, 0)
        if 4 <= m[0xD9EC] <= 6:       # command/order/fetch phases: force queues (not during act)
            if a.skill is not None:
                m[0xDCEC] = a.skill; m[0xDCED] = a.target
            if a.eskill is not None:
                m[0xDCF4] = a.eskill; m[0xDCF5] = a.etarget
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
    old = json.load(open(a.out))
json.dump(old + events, open(a.out, 'w'))
tags = {}
for e in events:
    tags[e['tag']] = tags.get(e['tag'], 0) + 1
print(f'{a.name}: +{len(events)} events (total {len(old)+len(events)}) frames={i} {tags}')
