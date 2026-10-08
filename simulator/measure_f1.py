#!/usr/bin/env python3
"""S130 F1 (status appliers + one-shot compulsions) capture rig — a copy of
simulator/measure_battle.py (the S85 loop-level rig, unchanged waypoints)
EXTENDED with: the F1 handler entries + every F1 hit-helper entry as
waypoints (tag `fx` with `fx` = handler name / `hlp` = helper address),
resistance pokes for every slot of a side (--eres/--pres rtype=level),
one-time pokes after init (--poke ADDR=VAL,...), ROUND pokes applied
inside the round_start hook BEFORE its snapshot (--rpoke ADDR|=VAL /
ADDR&=VAL / ADDR=VAL — e.g. re-arm a status roll every round, set the
$DB42 bit2 sure-hit or the +5 bit6/bit7 ladder rows; recorded in the
round_start event as `rpoke` so the validator applies the same edit to
its model board at the round boundary), and --force SLOT:SKILL:TARGET
(repeatable) to force any queue entry (party or enemy) per frame in the
command phases, like --skill/--eskill.  Defaults: the user's real save (u22.gbc +
field.state copied into the F1 scratch folder).

Original S85 rig docstring follows.

S85 LOOP-LEVEL battle capture rig: runs ONE complete rig battle (S75
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
ap.add_argument('--php3', type=int, help='force party slots 0-2 HP+MaxHP')
ap.add_argument('--pmp3', type=int, help='force party slots 0-2 MP+MaxMP')
ap.add_argument('--pmp', type=int)
ap.add_argument('--emp', type=int); ap.add_argument('--ehp', type=int)
ap.add_argument('--pst', help='poke party slot-0 status block: off=val,off=val (after init)')
ap.add_argument('--est', help='poke enemy slot-4 status block: off=val,...')
ap.add_argument('--skill', type=lambda x: int(x, 0)); ap.add_argument('--target', type=int, default=4)
ap.add_argument('--eskill', type=lambda x: int(x, 0)); ap.add_argument('--etarget', type=int, default=0)
ap.add_argument('--frames', type=int, default=6000)
ap.add_argument('--skip', type=int, default=0)
F1M = '/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/f1meas'
ap.add_argument('--rom', default=F1M + '/u22.gbc')
ap.add_argument('--state', default=F1M + '/field.state')
ap.add_argument('--out', default=F1M + '/f1_events.json')
ap.add_argument('--eres', help='enemy slots 4-6 resistance pokes: rtype=level,...')
ap.add_argument('--pres', help='party slots 0-2 resistance pokes: rtype=level,...')
ap.add_argument('--poke', help='one-time pokes after init: ADDR=VAL,...')
ap.add_argument('--rpoke', action='append', default=[], help='round pokes at round_start (pre-snapshot): ADDR|=V / ADDR&=V / ADDR=V')
ap.add_argument('--force', action='append', default=[], help='SLOT:SKILL:TARGET forced per frame in phases 4-6')
ap.add_argument('--maxev', type=int, default=400)
ap.add_argument('--db73', type=int, help='force wBattleType per-frame during battle (0 = wild condition inside the rig battle)')
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
        hp=w16s(0xDBA3), maxhp=w16s(0xDBB3), mp=w16s(0xDBC3), maxmp=w16s(0xDBD3),
        # S88 (per the S87 deferral): the four AI category base arrays
        # $DC44/$DC4C/$DC54/$DC5C (cat1/cat2/cat3/w3) + per-combatant WLD
        # words $DC23+2i (wBattleLVL misnomer; enemies $00FF).
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
    # S88 confusion arc:
    (0x53, 0x4BEB, 'conf_pick'),     # confusion action generator entry (pre RNG step)
    (0x52, 0x4E8A, 'meta_hitally'),  # $99 handler entry (pre $5559 step)
    (0x52, 0x4EA4, 'meta_hitenemy'), # $9A handler entry (pre step)
    (0x52, 0x4EBE, 'meta_hitrandom'),# $9B handler: unconditional self-hit
    (0x52, 0x4ED8, 'meta_trip'),     # $9E: set own +5 bit2 + msg
    (0x52, 0x4EE3, 'meta_msg'),      # $9C Scared / $9D Dance: msg only
    (0x52, 0x4EE7, 'meta_selfpara'), # $9F/$A0: set own +2 bit6
    (0x52, 0x4E3A, 'meta_run'),      # $A1: dd1b[self]=$FF flee
    (0x53, 0x5F3E, 'snap_roll'),     # on-hit sleep/confusion snap-out roll (pre step)
    (0x53, 0x5544, 'guard_redir'),   # S89: Cover/Guardian interception —
    # target rewritten to protector ($DB08+8t bit4 -> $DB09+8t hi nibble)
]
# S130 F1: handler entries (bank $52, verified vs clean bank_052.asm + u22 sym)
FX = {0x41F7: 'Beat', 0x4235: 'Sleep', 0x427C: 'StopSpell', 0x42AA: 'Surround',
      0x42D8: 'PanicAll', 0x4479: 'IRONIZE', 0x447F: 'Ironize', 0x4954: 'PalsyAir',
      0x497B: 'PoisonGas', 0x49D2: 'Curse', 0x4A00: 'Ahhh', 0x4A22: 'SandStorm',
      0x4A57: 'EerieLite', 0x4AA3: 'SideStep', 0x4AC5: 'LureDance', 0x4AE7: 'LushLicks',
      0x4B34: 'LegSweep', 0x4B68: 'WarCry', 0x4CDC: 'DanceShut', 0x4D0A: 'MouthShut',
      0x4F54: 'BIGSLEEP', 0x4FCC: 'FREEZY'}
# hit helpers NOT already in HOOKS (5C51/5C8F/5CBC/5CDA/65B5/65C9 are)
HLP = [0x5D05, 0x5DCC, 0x65D5, 0x65E3, 0x65FF, 0x6692, 0x669E]
def _round_start_cb(ctx):
    if a.rpoke:
        poke_frame(p.memory, a.rpoke)
    events.append(dict(snap(p, 'round_start'), pc=0x54D1, rpoke=list(a.rpoke)))


for bank, addr, tag in HOOKS:
    if tag == 'round_start':
        p.hook_register(bank, addr, _round_start_cb, None)
        continue
    p.hook_register(bank, addr, (lambda ctx, t=tag, ad=addr: events.append(dict(snap(p, t), pc=ad))), None)
for addr, name in FX.items():
    p.hook_register(0x52, addr, (lambda ctx, n=name, ad=addr: events.append(dict(snap(p, 'fx'), fx=n, pc=ad))), None)
for addr in HLP:
    p.hook_register(0x52, addr, (lambda ctx, ad=addr: events.append(dict(snap(p, 'helper'), pc=ad))), None)


def _pairs(spec):
    out = []
    for kv in (spec or '').split(','):
        if kv:
            k, v = kv.split('=')
            out.append((int(k, 0), int(v, 0)))
    return out


def poke_res(m, slots, spec):
    """$DD28+slot*7: 27 2-bit levels, type t at packed position t+1
    (damage.res_level)."""
    for rt, lv in _pairs(spec):
        pos = rt + 1
        sh = (3 - (pos & 3)) * 2
        for s in slots:
            ad = 0xDD28 + s * 7 + (pos >> 2)
            m[ad] = (m[ad] & ~(3 << sh) & 0xFF) | ((lv & 3) << sh)


def poke_frame(m, spec):
    for item in spec:
        for kv in item.split(','):
            if '|=' in kv:
                k, v = kv.split('|='); m[int(k, 0)] |= int(v, 0)
            elif '&=' in kv:
                k, v = kv.split('&='); m[int(k, 0)] &= int(v, 0)
            else:
                k, v = kv.split('='); m[int(k, 0)] = int(v, 0)

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
        if not started:
            # [S89] disarm the rig trigger the moment the battle starts:
            # leaving $C8EB bit6 armed re-fires a SECOND identical battle
            # after teardown (same seeds), whose round_start then hands
            # the validator a bogus "next event" across the end-of-battle
            # HP refill (fresh_e artifact, S89).
            p.memory[0xC8EB] &= ~0x40
        started = True
        m = p.memory
        # stat forcing only during battle INIT (phase <= 3, after the stat
        # copy) so the engine's own HP bookkeeping is what we observe.
        if not forced and m[0xD9EC] <= 3 and m[0xD9ED] >= 1:
            forced = True
            if a.php is not None:
                m[0xDBA3] = a.php & 0xFF; m[0xDBA4] = a.php >> 8
                m[0xDBB3] = a.php & 0xFF; m[0xDBB4] = a.php >> 8
            if a.php3 is not None:
                for k in range(3):
                    m[0xDBA3 + 2*k] = a.php3 & 0xFF; m[0xDBA4 + 2*k] = a.php3 >> 8
                    m[0xDBB3 + 2*k] = a.php3 & 0xFF; m[0xDBB4 + 2*k] = a.php3 >> 8
            if a.pmp3 is not None:
                for k in range(3):
                    m[0xDBC3 + 2*k] = a.pmp3 & 0xFF; m[0xDBC4 + 2*k] = a.pmp3 >> 8
                    m[0xDBD3 + 2*k] = a.pmp3 & 0xFF; m[0xDBD4 + 2*k] = a.pmp3 >> 8
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
            poke_res(m, (4, 5, 6), a.eres)
            poke_res(m, (0, 1, 2), a.pres)
            for ad, v in _pairs(a.poke):
                m[ad] = v
            for spec, base in ((a.pst, 0xDB00), (a.est, 0xDB20)):
                if spec:
                    for kv in spec.split(','):
                        off, val = kv.split('=')
                        m[base + int(off, 0)] = int(val, 0)
        if a.db73 is not None and m[0xD9EC] >= 1:
            m[0xDB73] = a.db73
        if 4 <= m[0xD9EC] <= 6:       # command/order/fetch phases: force queues (not during act)
            if a.skill is not None:
                m[0xDCEC] = a.skill; m[0xDCED] = a.target
            if a.eskill is not None:
                m[0xDCF4] = a.eskill; m[0xDCF5] = a.etarget
            for fs in a.force:
                s_, k_, t_ = (int(x, 0) for x in fs.split(':'))
                m[0xDCEC + 2 * s_] = k_; m[0xDCED + 2 * s_] = t_
    elif started:
        break
    if len(events) >= a.maxev:
        break
    if i % 8 < 4:
        p.button_press('a')
    else:
        p.button_release('a')
    p.tick()

# S130 F1: compact corpus — the full board only on round_start (the
# validator builds its model board there); the other waypoints keep the
# fields any replay reads.
KEEP = {'tag', 'sc', 'frame', 'A', 'd9ec', 'd9ed', 'd9ee', 'db88', 'db89', 'db8a', 'db56',
        'dcfd', 'dcfe', 'db4c', 'db4d', 'db4e', 'rng1', 'rng2', 'c86c', 'db73', 'dcec',
        'dd13', 'dd1b', 'hp', 'mp', 'maxmp', 'st', 'db42', 'db8b', 'dfn', 'pc', 'fx', 'db79'}
events = [e if e['tag'] == 'round_start' else {k: v for k, v in e.items() if k in KEEP}
          for e in events]
old = []
if os.path.exists(a.out):
    old = json.load(open(a.out))
json.dump(old + events, open(a.out, 'w'), separators=(',', ':'))
tags = {}
for e in events:
    tags[e['tag']] = tags.get(e['tag'], 0) + 1
print(f'{a.name}: +{len(events)} events (total {len(old)+len(events)}) frames={i} {tags}')
