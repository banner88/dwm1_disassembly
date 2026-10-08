#!/usr/bin/env python3
"""S130 F7 (stat buffs/debuffs) capture rig — a copy of the S85 loop rig
(simulator/measure_battle.py) extended with the F7 handler waypoints and a
per-round forced-cast SCHEDULE, for simulator/validate_f7.py.

Every event carries the full board snapshot (stats, status area, res,
queue, RNG) plus `rec` = each party slot's record stats (the bank $57
entries 4-8 source for party/helper slots: record +$52 MaxHP, +$56 MaxMP,
+$58 ATK, +$5A DEF, +$5C AGL; ReadMonsterWord via $CA8E[slot]).

F7 waypoints (all addresses verified byte-identical in u22.gbc vs the clean
build, S130):
  $52:$434A SkillSap / $436D SkillUpper / $4385 SkillSlow / $43A8 SkillSpeed
  $52:$4BAB SkillSurge / $4BB6 SkillUltraDown / $4AE7 SkillLushLicks
  $52:$446C SkillTransform                         (handler entries: pre)
  $52:$6CDD the instruction after the handler call in
            SkillHandlerDispatch_6cc7                (handler return: post)
  $52:$4361/$437F/$439C/$43BA  'fail' (msg $BB: stat cannot move)
  $52:$4367/$43A2/$4BCA        'rollmiss' (msg $B8: the hit roll failed)
  $52:$4B2A / $4B30            LushLicks roll-miss / already-licked
  $52:$52B9 / $52CE            after rst $10 in GetBaseDEF_52b1 / _52c6:
            $DD72/73 = the bank $57 entry 7 (DEF) / 8 (AGL) base value
  $53:$601C Surge per-target body (entry 10)
  $53:$65BA/$661B/$667C/$66A6/$66BD  UltraDown state-3 machine (entry 12)
            subs 0 DEF / 1 AGL / 2 Surround / 3 marker / 4 end
  $52:$5F5E TransformCopyStats_5f5e (Transform copy) / $52:$6D37 after it and
            the own +3 bit5 set (jr_052_6d20)

Schedules: --sched SLOT:list (repeatable), list = comma-separated
`skill@target` entries; round k (0-based, = round_start events seen
at the command phase $D9EC==4) forces entry min(k, len-1) into $DCEC+2*SLOT. An entry `-`
leaves that round to the engine (AI / menu).
--keep N: re-poke HP of every live combatant to max (and MP of the
scheduled slots to max) during the command phases, so long cap/floor
sequences do not end the battle (stats are never poked by it).
--poke SLOT:field=val (repeatable): poke a battle stat array at init
(field in hp maxhp mp maxmp atk dfn agl int) — branch coverage only.
--res SLOT:rtype=lev (repeatable): poke a packed resistance level at init.
--st SLOT:off=val: status-block poke at init; --db42 SLOT=val: $DB42 |= val
in every command/order-phase frame
(ladder rows +5 bit6/bit7, sure-hit bit2, Surge cure inputs).

S130 corpus recipe (simulator/f7_events.json = this script with
--out simulator/f7_events.json, run in order; u22.gbc + field.state on the
user's real save, party Darkdrium L22 / BattleRex L23 / Healer L19):
  upper_p 7 --php 900 --pmp 250 --ehp 900 --sched 0:0x1e@1,0x1e@1,0x1e@1,0x1e@1,0x1e@1,0x1e@1,0x1e@1,0x1f@0,0x1f@0,0x1f@0 --rounds 10
  speed_p 7 --php 900 --pmp 250 --ehp 900 --sched 0:0x22@1,0x22@1,0x22@1,0x22@1,0x22@1,0x22@1,0x22@1,0x23@0,0x23@0,0x23@0 --rounds 10 --skip 7
  sap_p 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --sched 0:0x1c@4,0x1c@4,0x1c@4,0x1c@4,0x1d@4,0x1d@4,0x1d@4,0x1d@5 --rounds 8 --skip 3
  slow_p 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --poke 5:agl=3 --poke 6:agl=4 --sched 0:0x20@4,0x20@4,0x20@4,0x21@4,0x21@4,0x21@5 --rounds 7 --skip 5
  sap_res1 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --res 4:12=1 --res 5:12=2 --res 6:12=3 --res 4:13=1 --res 5:13=2 --res 6:13=3 --sched 0:0x1d@4,0x21@4,0x1d@4,0x21@4,0x1d@4,0x21@4 --rounds 6 --skip 11
  sap_res2 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --res 4:12=1 --res 5:12=2 --res 6:12=0 --st 4:5=0x40 --st 5:5=0x80 --st 6:5=0xC0 --res 4:13=1 --res 5:13=2 --sched 0:0x1d@4,0x21@4,0x1d@4,0x21@4,0x1d@4,0x21@4 --rounds 6 --skip 13
  sap_sure 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --res 4:12=2 --res 5:12=3 --res 4:13=2 --db42 0=0x04 --sched 0:0x1d@4,0x21@4,0x1d@4,0x21@4 --rounds 4 --skip 17
  e_sap 7 --php 900 --pmp 250 --emp 200 --ehp 900 --poke 2:dfn=20 --sched 4:0x1c@1,0x1c@1,0x1c@1,0x1d@0,0x1d@0,0x1d@0,0x1c@2,0x1c@2 --sched 0:-,-,-,-,-,-,-,-,0x81@0,0x81@1 --rounds 10 --skip 19
  e_slow 7 --php 900 --pmp 250 --emp 200 --ehp 900 --sched 4:0x20@1,0x20@1,0x20@1,0x20@1,0x21@0,0x21@0,0x21@0,0x20@2 --sched 0:-,-,-,-,-,-,-,-,0x81@0 --rounds 9 --skip 23
  e_upper 7 --ecount 3 --php 900 --pmp 250 --emp 200 --ehp 900 --sched 4:0x1e@4,0x1e@4,0x1e@4,0x1e@4,0x22@4,0x22@4,0x22@4,0x22@4,0x1f@5,0x23@4 --rounds 10 --skip 29
  e_big 213 --php 900 --pmp 250 --emp 200 --ehp 3000 --sched 4:0x1e@4,0x1e@4,0x1e@4,0x22@4,0x22@4,0x22@4,0x1c@0,0x20@1 --sched 0:-,-,-,-,-,-,0x1c@4,0x20@4,0x1c@4 --rounds 9 --skip 31
  quirk_def 421 --php 900 --pmp 250 --emp 200 --ehp 900 --poke 4:dfn=830 --sched 4:0x1e@4,0x1e@4,0x1e@4 --rounds 3 --skip 37
  quirk_agl 146 --php 900 --pmp 250 --emp 200 --ehp 900 --poke 4:agl=410 --sched 4:0x22@4,0x22@4,0x22@4 --rounds 3 --skip 41
  quirk_cap 146 --php 900 --pmp 250 --emp 200 --ehp 900 --poke 4:agl=400 --poke 4:dfn=200 --sched 4:0x22@4,0x1e@4,0x22@4,0x1e@4 --rounds 4 --skip 43
  ud_p 4 --ecount 3 --php 900 --pmp 250 --ehp 900 --sched 0:0x82@4,0x82@4,0x82@4,0x82@5,0x82@5,0x82@6,0x82@6,0x82@6 --rounds 8 --skip 47
  ud_res 7 --ecount 2 --php 900 --pmp 250 --ehp 900 --res 5:8=2 --sched 0:0x82@4,0x82@4,0x82@5,0x82@5,0x82@5,0x82@5 --rounds 6 --skip 53
  ud_e 7 --php 900 --pmp 250 --emp 200 --ehp 900 --sched 4:0x82@0,0x82@0,0x82@1,0x82@1,0x82@1,0x82@2,0x82@2,0x82@2 --sched 0:-,-,-,-,-,-,-,-,0x81@0 --rounds 9 --skip 59
  surge_st 7 --php 900 --pmp 250 --emp 200 --ehp 900 --sched 4:0x15@1,0x15@2,0x1c@1,0x20@2,0x18@1 --sched 0:-,-,0x81@1,-,-,0x81@0 --rounds 6 --skip 61
  lick_p 7 --ecount 2 --php 900 --pmp 250 --ehp 900 --sched 0:0x7a@4,0x7a@4,0x1e@0,0x7a@5,0x7a@5 --rounds 5 --skip 67
  lick_e 7 --php 900 --pmp 250 --emp 200 --ehp 900 --sched 4:0x7a@1,0x7a@2,0x7a@1,0x1c@1 --sched 0:-,-,0x1e@1,-,0x81@0 --rounds 5 --skip 71
  tf_p 7 --php 900 --pmp 250 --ehp 900 --sched 0:0x29@4,-,-,0x81@0 --sched 4:-,0x1c@0,0x1e@0 --rounds 4 --skip 73
  tf_e 7 --php 900 --pmp 250 --emp 200 --ehp 900 --sched 4:0x29@0,0x1c@4,0x22@4,0x1e@4 --rounds 4 --skip 79
  surge_cure 7 --php 900 --pmp 250 --ehp 900 --st 1:2=0x80 --st 2:2=0x10 --st 0:3=0xC3 --st 1:5=0x80 --st 2:7=0x03 --st 1:8=0x80 --sched 0:0x81@0,0x81@0 --rounds 2 --skip 83
  surge_cure2 7 --php 900 --pmp 250 --ehp 900 --st 1:2=0x8C --st 2:2=0x41 --st 1:3=0x02 --st 2:5=0x80 --sched 0:0x81@1 --rounds 1 --skip 89
  tf_buff 7 --php 900 --pmp 250 --emp 200 --ehp 900 --sched 4:0x1e@4,0x22@4,-,0x1c@0,0x20@0 --sched 0:-,-,0x29@4,-,-,0x81@0 --rounds 6 --skip 97
  sap_sure2 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --res 4:12=2 --res 5:12=3 --res 4:13=2 --res 4:8=2 --db42 0=0x04 --sched 0:0x1d@4,0x21@4,0x82@4,0x82@4 --rounds 4 --skip 101
  e_rows 7 --php 900 --pmp 250 --emp 200 --ehp 900 --st 1:5=0x40 --st 2:5=0x80 --db42 4=0x04 --sched 4:0x1d@0,0x21@0,0x1d@0,0x21@0,0x82@1,0x82@2 --rounds 6 --skip 103
  e_surge 7 --ecount 2 --php 900 --pmp 250 --emp 200 --ehp 900 --sched 0:0x1c@4,0x20@5,0x82@4,- --sched 4:-,-,-,0x81@4 --rounds 4 --skip 107
  # natural AI flow (no schedule): enemy commits of F7 skills
  nat_upper 19 --php 900 --pmp 250 --ehp 900 --emp 200 --rounds 8 --skip 5
  nat_slow 20 --php 900 --pmp 250 --ehp 900 --emp 200 --rounds 8 --skip 5
  nat_speedup 68 --php 900 --pmp 250 --ehp 900 --emp 200 --rounds 8 --skip 5
  nat_tf 104 --php 900 --pmp 250 --ehp 900 --emp 200 --rounds 8 --skip 5
  nat_slowall 122 --php 900 --pmp 250 --ehp 900 --emp 200 --rounds 8 --skip 5
  nat_upper3 19 --ecount 3 --php 900 --pmp 250 --ehp 900 --emp 200 --rounds 8 --skip 9
  nat_inc3 90 --ecount 3 --php 900 --pmp 250 --ehp 900 --emp 200 --rounds 8 --skip 9
  nat_slow3 20 --ecount 3 --php 900 --pmp 250 --ehp 900 --emp 200 --rounds 8 --skip 9
  tf_surge 7 --php 900 --pmp 250 --emp 200 --ehp 900 --sched 0:0x29@4,-,- --sched 4:-,0x1c@0,0x20@0,- --sched 1:-,-,-,0x81@0 --rounds 4 --skip 109

Hook-safety: dense 4-on/4-off A cadence (PYBOY_DEBUGGING S80).
"""
import sys, json, os, argparse
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import *

SP = '/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/f7meas'
ap = argparse.ArgumentParser()
ap.add_argument('name'); ap.add_argument('eid', type=int)
ap.add_argument('--ecount', type=int, default=1)
ap.add_argument('--php', type=int); ap.add_argument('--pmp', type=int)
ap.add_argument('--emp', type=int); ap.add_argument('--ehp', type=int)
ap.add_argument('--sched', action='append', default=[])
ap.add_argument('--poke', action='append', default=[])
ap.add_argument('--res', action='append', default=[])
ap.add_argument('--st', action='append', default=[], help='SLOT:off=val status-block poke at init')
ap.add_argument('--db42', action='append', default=[], help='SLOT=val $DB42 |= val during every command/order phase')
ap.add_argument('--keep', type=int, default=1)
ap.add_argument('--rounds', type=int, default=12, help='stop at the (N+1)-th round_start')
ap.add_argument('--frames', type=int, default=30000)
ap.add_argument('--skip', type=int, default=0)
ap.add_argument('--db73', type=int)
ap.add_argument('--rom', default=SP + '/u22.gbc')
ap.add_argument('--state', default=SP + '/field.state')
ap.add_argument('--out', default=SP + '/f7_events.json')
ap.add_argument('--maxev', type=int, default=3000)
a = ap.parse_args()

RNG1, RNG2 = 0xC899, 0xC89A
STAT = dict(hp=0xDBA3, maxhp=0xDBB3, mp=0xDBC3, maxmp=0xDBD3, atk=0xDBE3,
            dfn=0xDBF3, agl=0xDC03, int=0xDC13)


def w16(m, ad):
    return m[ad] | (m[ad + 1] << 8)


def rec_stats(m):
    out = []
    for s in range(3):
        idx = m[0xCA8E + s]
        if idx == 0xFF:
            out.append(None); continue
        r = 0xCAC1 + (idx & 0x7F) * 0x95
        out.append(dict(maxhp=w16(m, r + 0x52), maxmp=w16(m, r + 0x56), atk=w16(m, r + 0x58),
                        dfn=w16(m, r + 0x5A), agl=w16(m, r + 0x5C), int=w16(m, r + 0x5E)))
    return out


def snap(p, tag):
    m = p.memory
    def arr(ad, n): return list(m[ad:ad + n])
    def w16s(ad): return [m[ad + 2 * i] | (m[ad + 2 * i + 1] << 8) for i in range(8)]
    return dict(
        tag=tag, sc=a.name, frame=p.frame_count, A=p.register_file.A,
        d9ec=m[0xD9EC], d9ed=m[0xD9ED], d9ee=m[0xD9EE],
        db82=m[0xDB82], db88=m[0xDB88], db89=m[0xDB89], db8a=m[0xDB8A],
        db56=m[0xDB56] | (m[0xDB57] << 8), dd72=m[0xDD72] | (m[0xDD73] << 8),
        db4c=m[0xDB4C], db71=m[0xDB71] | (m[0xDB72] << 8), db54=m[0xDB54], rng1=m[RNG1], rng2=m[RNG2], c86c=m[0xC86C], db73=m[0xDB73],
        db79=arr(0xDB79, 9), dcec=arr(0xDCEC, 16),
        dd13=arr(0xDD13, 8), dd1b=arr(0xDD1B, 8), dd03=arr(0xDD03, 8),
        dd0b=arr(0xDD0B, 8), db8b=arr(0xDB8B, 8), db9b=arr(0xDB9B, 8),
        db42=arr(0xDB42, 8), db40=arr(0xDB40, 2),
        hp=w16s(0xDBA3), maxhp=w16s(0xDBB3), mp=w16s(0xDBC3), maxmp=w16s(0xDBD3),
        atk=w16s(0xDBE3), dfn=w16s(0xDBF3), agl=w16s(0xDC03), int=w16s(0xDC13),
        st=arr(0xDB00, 64), res=arr(0xDD28, 56), species=arr(0xDC3C, 8),
        pk=PK, eid=[w16(m, 0xDA03), w16(m, 0xDA05), w16(m, 0xDA07)], rec=rec_stats(m))


# poked (slot, stat) pairs: the validator's base_src check skips them
PK = [[int(x.split(':')[0]), x.split(':')[1].split('=')[0]] for x in a.poke]
events = []
p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)
for _ in range(a.skip):
    p.tick()

HOOKS = [
    (0x58, 0x54D1, 'round_start'), (0x53, 0x4546, 'actor_fetch'),
    (0x53, 0x462C, 'forced'),
    (0x53, 0x520C, 'target_fetch'),
    (0x53, 0x5766, 'miss_rng'),
    (0x53, 0x5810, 'miss'), (0x53, 0x57F7, 'dodge'), (0x53, 0x582A, 'block'),
    (0x53, 0x586A, 'miss_pass'),
    (0x52, 0x7EE3, 'ko'), (0x53, 0x4640, 'round_end'),
    # F7 handlers
    (0x52, 0x434A, 'h_sap'), (0x52, 0x436D, 'h_upper'), (0x52, 0x4385, 'h_slow'),
    (0x52, 0x43A8, 'h_speed'), (0x52, 0x4BAB, 'h_surge'), (0x52, 0x4BB6, 'h_ultra'),
    (0x52, 0x4AE7, 'h_lick'), (0x52, 0x446C, 'h_transform'),
    (0x52, 0x6CDD, 'h_ret'),
    (0x52, 0x4361, 'fail'), (0x52, 0x437F, 'fail'), (0x52, 0x439C, 'fail'),
    (0x52, 0x43BA, 'fail'), (0x52, 0x4367, 'rollmiss'), (0x52, 0x43A2, 'rollmiss'),
    (0x52, 0x4BCA, 'rollmiss'), (0x52, 0x4B2A, 'rollmiss'), (0x52, 0x4B30, 'already'),
    (0x52, 0x52B9, 'base_def'), (0x52, 0x52CE, 'base_agl'),
    (0x53, 0x601C, 'surge_in'),
    (0x53, 0x65BA, 'ud_def'), (0x53, 0x661B, 'ud_agl'), (0x53, 0x667C, 'ud_sur'),
    (0x53, 0x66A6, 'ud_mark'), (0x53, 0x66BD, 'ud_end'),
    (0x52, 0x5F5E, 'tf_copy'), (0x52, 0x6D37, 'tf_done'),
]
for bank, addr, tag in HOOKS:
    p.hook_register(bank, addr, (lambda ctx, t=tag: events.append(snap(p, t))), None)

sched = {}
for s in a.sched:
    slot, lst = s.split(':', 1)
    ent = []
    for x in lst.split(','):
        if x == '-':
            ent.append(None)
        else:
            sk, tg = x.split('@')
            ent.append((int(sk, 0), int(tg, 0)))
    sched[int(slot)] = ent

p.memory[0xDA03] = a.eid & 0xFF; p.memory[0xDA04] = (a.eid >> 8) & 0xFF
p.memory[0xDA02] = (a.ecount - 1) & 3
if a.ecount > 1:
    p.memory[0xDA05] = p.memory[0xDA03]; p.memory[0xDA06] = p.memory[0xDA04]
if a.ecount > 2:
    p.memory[0xDA07] = p.memory[0xDA03]; p.memory[0xDA08] = p.memory[0xDA04]
p.memory[0xDA09] = 1; p.memory[0xC905] = 0; p.memory[0xC8EB] |= 0x40


def wr16(m, ad, v):
    m[ad] = v & 0xFF; m[ad + 1] = (v >> 8) & 0xFF


started = False
forced = False
nrs, scanned, cur_rnd = 0, 0, 0
for i in range(a.frames):
    m = p.memory
    while scanned < len(events):
        nrs += events[scanned]['tag'] == 'round_start'; scanned += 1
    if m[GAME_MODE] == 2:
        if not started:
            m[0xC8EB] &= ~0x40           # disarm the rig trigger (S89)
        started = True
        if not forced and m[0xD9EC] <= 3 and m[0xD9ED] >= 1:
            forced = True
            if a.php is not None:
                wr16(m, 0xDBA3, a.php); wr16(m, 0xDBB3, a.php)
            if a.pmp is not None:
                wr16(m, 0xDBC3, a.pmp); wr16(m, 0xDBD3, a.pmp)
            for k in range(3):
                if a.emp is not None:
                    wr16(m, 0xDBC3 + 8 + 2 * k, a.emp); wr16(m, 0xDBD3 + 8 + 2 * k, a.emp)
                if a.ehp is not None:
                    wr16(m, 0xDBA3 + 8 + 2 * k, a.ehp); wr16(m, 0xDBB3 + 8 + 2 * k, a.ehp)
            for spec in a.poke:
                slot, kv = spec.split(':'); fld, val = kv.split('=')
                wr16(m, STAT[fld] + 2 * int(slot), int(val, 0))
            for spec in a.st:
                slot, kv = spec.split(':'); off, val = kv.split('=')
                m[0xDB00 + 8 * int(slot) + int(off, 0)] = int(val, 0)
            for spec in a.res:
                slot, kv = spec.split(':'); rt, lev = (int(x, 0) for x in kv.split('='))
                pos = rt + 1; ad = 0xDD28 + 7 * int(slot) + (pos >> 2)
                sh = (3 - (pos & 3)) * 2
                m[ad] = (m[ad] & ~(3 << sh) & 0xFF) | (lev << sh)
        if a.db73 is not None and m[0xD9EC] >= 1:
            m[0xDB73] = a.db73
        if m[0xD9EC] == 4:              # command phase of round nrs
            cur_rnd = nrs
        if 4 <= m[0xD9EC] <= 6:
            for spec in a.db42:          # re-poked each command/order frame
                slot, val = spec.split('=')
                m[0xDB42 + int(slot)] |= int(val, 0)
            rnd = cur_rnd
            for slot, ent in sched.items():
                x = ent[min(rnd, len(ent) - 1)]
                if x is not None and m[0xDD1B + slot] == 0:
                    m[0xDCEC + 2 * slot] = x[0]; m[0xDCED + 2 * slot] = x[1]
            if a.keep and m[0xD9EC] == 4:
                for s in range(8):
                    if m[0xDD1B + s] == 0:
                        wr16(m, 0xDBA3 + 2 * s, w16(m, 0xDBB3 + 2 * s))
                for s in sched:
                    wr16(m, 0xDBC3 + 2 * s, w16(m, 0xDBD3 + 2 * s))
        if nrs > a.rounds:
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
tags = {}
for e in events:
    tags[e['tag']] = tags.get(e['tag'], 0) + 1
print(f'{a.name}: +{len(events)} events (total {len(old)+len(events)}) frames={i} {tags}')
