#!/usr/bin/env python3
"""S130 (P3.15b) PLAYER-ORDER capture rig: runs one rig battle on the real
save and gives the party its orders THROUGH THE REAL BATTLE MENU (joypad
input: FIGHT/PLAN -> per-monster tactic list -> COMMAND -> ATK / SKIL /
DEF -> skill list -> target cursor), the way the project owner plays.
Nothing is poked into the action queue; enemies run their natural AI.

It records (a) the menu's own writes (skill, target, the $DD03 := 3 /
$DD13 := 1 marks, refusal messages), (b) the bank $57 commit of every
actor (state-0 preamble, obedience gate, the plan-$81 personality drift,
the $714E keep-the-order divert, the SetBtlAI_7f5f direct pick, the post,
the bank $58 queue service) and (c) the whole S85 round-loop waypoint set
(measure_battle.py) so simulator/validate_command.py can replay both the
commit and the round through the simulator.

Usage:
  measure_command.py NAME EID [--ecount N] [--order R:SPEC ...]
      [--wld SLOT=V] [--bases SLOT=c1,c2,c3,w3] [--tactic SLOT=T]
      [--php N] [--pmp SLOT=N] [--ehp N] [--emp N] [--db73 N]
      [--rounds N] [--skip N] [--out FILE]

--order R:SPEC (repeatable; R = 0-based command phase, the last given R
applies to every later round). SPEC = `FIGHT` (top menu FIGHT: no orders)
or a '/'-separated list of per-monster entries in menu order (party slots
0,1,2 that the menu visits):
   atk[@T]       COMMAND -> ATK (target T when the menu asks)
   def           COMMAND -> DEF
   sk:ID[@T]     COMMAND -> SKIL -> skill ID (its index in the slot's
                 $DC64 list) [-> target T]
   tac:N         tactic N (0 Charge / 1 Mixed / 2 Cautious) instead of
                 COMMAND (the +45 PLAN bias path)
   X|Y           try X; if the menu refuses it (message: no MP / field-
                 only / no target) fall back to Y
--wld/--bases/--tactic poke the party record BEFORE the battle (record
+$60 WLD; +$64/$65/$66/$67 = c1/c3/w3/c2 personality; +$0B high nibble
tactic) so battle init copies them like any real monster.
--pskills SLOT=id,id,.. rewrites that party record's skill list (+41..)
before the battle (single-target spells etc. the save's party lacks).
--st SLOT:off=val pokes a status byte at init (asleep / confused party).
--pmp SLOT=N pokes that slot's battle MP (cur) at init (low-MP orders).

Every event = full board snapshot (S85 field set + wld, ai_bases, the menu
cursor bytes, registers A/B/C/HL). Tags: the S85 set, plus
  m_skill $50:$4F86 (queue skill write, B=skill)  m_target $50:$4F95 (C)
  m_mark  $50:$4F45 GetBattleModeData ($DD13:=1, $DD03:=3)
  m_msg   $50:$4CA4 (menu refusal, HL = message)  m_round (rig: menu done)
  ai_s0 $57:$6E2A  band_in $57:$7A16  decide_in $57:$7A5D  carry $57:$6EF4
  nocarry $57:$6F8C  pers $57:$6FE0 (plan-$81 drift entry)  cmd_keep
  $57:$718C  direct $57:$6F64  ai_post $57:$7859  qfetch $58:$5498
  daze $52:$4E0A (SkillDaze)
Addresses verified byte-identical in u22.gbc vs the clean build (bank $57
fully identical; bank $50 differs only in the S73 field-only patch).

S130 corpus recipe (simulator/command_events.json.gz, 56 battles: u22.gbc +
field.state on the user's save — party Slib Darkdrium L22 WLD 0 INT 255 /
Wrex BattleRex L23 WLD 48 / Hale Healer L19 WLD 17): each line = this script
`NAME EID ARGS --out b_NAME.json`, then the per-battle files concatenated in
this order and gzipped (quote the `|` alternatives for the shell):
  base7 7 --ecount 3 --php 900 --ehp 400 --rounds 5 --order 0:sk:0x10/atk@5/sk:0x2c@1
  base19 19 --ecount 2 --php 900 --ehp 300 --rounds 5 --skip 3 --order 0:sk:0x62/atk@4/sk:0x1f
  base40 40 --ecount 2 --php 900 --ehp 400 --rounds 6 --skip 5 --order 0:sk:0x5e/def/sk:0x2c@0
  base90 90 --php 900 --ehp 600 --rounds 5 --skip 7 --order 0:atk/atk/def
  base20 20 --ecount 3 --php 900 --ehp 300 --rounds 5 --skip 9 --order 0:sk:0x5e/atk@6/sk:0x2c@2 --order 2:atk@5/def/sk:0x1f
  base60 60 --ecount 2 --php 900 --ehp 400 --rounds 6 --skip 11 --order 0:sk:0x62/sk:0x40@5/sk:0x2c@1
  base80 80 --ecount 2 --php 900 --ehp 400 --rounds 5 --skip 13 --order 0:sk:0x10/sk:0x48@4/def
  base122 122 --php 900 --ehp 500 --rounds 5 --skip 15 --order 0:atk/atk/sk:0x2c@1
  wld_w20a 7 --ecount 2 --wld 1=0x20 --php 900 --ehp 400 --rounds 6 --skip 17 --order 0:sk:0x10/atk@5/sk:0x2c@0
  wld_w20b 19 --ecount 2 --wld 1=0x20 --php 900 --ehp 400 --rounds 6 --skip 19 --order 0:atk@4/atk@5/sk:0x1f
  wld_w15 7 --ecount 2 --wld 1=0x15 --php 900 --ehp 400 --rounds 5 --skip 21 --order 0:sk:0x62/atk@4/def
  wld_w14 7 --ecount 2 --wld 1=0x14 --php 900 --ehp 400 --rounds 4 --skip 23 --order 0:def/atk@5/def
  wld_wF0 7 --ecount 2 --wld 1=0xF0 --php 900 --ehp 400 --rounds 4 --skip 25 --order 0:sk:0x10/atk@4/def
  wld_wEF 7 --ecount 2 --wld 1=0xEF --php 900 --ehp 400 --rounds 4 --skip 27 --order 0:sk:0x10/atk@4/def
  wld_sA8 20 --ecount 2 --wld 0=0xA8 --php 900 --ehp 400 --rounds 6 --skip 29 --order 0:sk:0x10/atk@4/sk:0x2c@1
  wld_sB8 19 --ecount 2 --wld 0=0xB8 --php 900 --ehp 400 --rounds 6 --skip 31 --order 0:sk:0x5e/def/sk:0x1f
  wld_hC8 7 --ecount 2 --wld 2=0xC8 --php 900 --ehp 400 --rounds 6 --skip 33 --order 0:sk:0x10/atk@5/sk:0x2c@0
  wld_hB0 40 --ecount 2 --wld 2=0xB0 --php 900 --ehp 400 --rounds 6 --skip 35 --order 0:sk:0x62/def/sk:0x2c@1
  wld_all48 7 --ecount 3 --wld 0=0x48 --wld 1=0x48 --wld 2=0x48 --php 900 --ehp 400 --rounds 6 --skip 37 --order 0:sk:0x10/atk@6/sk:0x2c@1
  wld_all90 60 --ecount 2 --wld 0=0x90 --wld 1=0x90 --wld 2=0x90 --php 900 --ehp 400 --rounds 6 --skip 39 --order 0:sk:0x62/atk@5/sk:0x1f
  loaf_w 7 --ecount 2 --bases 1=30,30,30,56 --php 900 --ehp 300 --rounds 4 --skip 41 --order 0:sk:0x10/atk@5/def
  loaf_h 19 --ecount 2 --wld 2=0xF0 --bases 2=20,40,62,100 --php 900 --ehp 300 --rounds 4 --skip 43 --order 0:sk:0x5e/atk@4/sk:0x2c@1
  loaf_s 7 --ecount 2 --wld 0=0xFF --bases 0=0,0,0,0 --php 900 --ehp 300 --rounds 4 --skip 45 --order 0:sk:0x10/def/sk:0x1f
  def_w 7 --ecount 2 --bases 1=100,150,50,56 --php 900 --ehp 300 --rounds 4 --skip 47 --order 0:sk:0x62/atk@4/sk:0x2c@0
  def_w3 20 --ecount 2 --bases 1=63,40,63,56 --php 900 --ehp 300 --rounds 4 --skip 49 --order 0:sk:0x5e/atk@5/def
  atk_tie 7 --ecount 2 --bases 1=63,63,63,56 --php 900 --ehp 300 --rounds 4 --skip 51 --order 0:sk:0x5e/atk@5/def
  atk_s2 7 --ecount 3 --wld 0=0xFF --bases 0=200,50,50,100 --php 900 --ehp 400 --rounds 5 --skip 53 --order 0:sk:0x10/def/sk:0x2c@1
  atk_s2b 80 --ecount 2 --wld 0=0xFF --bases 0=200,50,50,100 --php 900 --ehp 400 --rounds 5 --skip 55 --order 0:sk:0x5e/sk:0x48@4/def
  row_low 7 --ecount 2 --bases 0=65,88,171,120 --bases 2=89,186,243,100 --php 900 --ehp 400 --rounds 6 --skip 57 --order 0:sk:0x62/atk@5/sk:0x2c@1
  row_floor 7 --ecount 2 --bases 0=65,88,171,1 --wld 2=0x30 --bases 2=89,186,243,3 --php 900 --ehp 400 --rounds 5 --skip 59 --order 0:sk:0x10/atk@4/sk:0x1f
  single1 7 --ecount 3 --pskills 0=0x00,0x15,0x1c,0x1e,0x2b,0x24,0x22,0x06 --php 900 --ehp 400 --rounds 6 --skip 61 --order 0:sk:0x00@5/atk@4/sk:0x2c@1 --order 1:sk:0x15@6/def/sk:0x2c@0 --order 2:sk:0x1c@4/atk@5/def --order 3:sk:0x1e@2/atk@6/sk:0x1f --order 4:sk:0x22@1/atk@4/sk:0x2c@2 --order 5:sk:0x24/def/sk:0x2c@1
  single2 19 --ecount 2 --pskills 0=0x00,0x15,0x1c,0x1e,0x2b,0x24,0x22,0x06 --wld 1=0 --php 900 --ehp 400 --rounds 6 --skip 63 --order 0:sk:0x06/sk:0x40@5/sk:0x2c@1 --order 1:sk:0x2b@1/sk:0x48@4/sk:0x2c@0 --order 2:sk:0x00@4/atk@5/sk:0x1f --order 3:sk:0x15@5/def/def
  single3 60 --ecount 3 --pskills 2=0x2b,0x2c,0x1e,0x22,0x1f,0x24 --wld 1=0 --php 900 --ehp 400 --rounds 6 --skip 65 --order 0:sk:0x62/atk@6/sk:0x1e@0 --order 1:sk:0x10/atk@5/sk:0x22@1 --order 2:sk:0x5e/sk:0x40@4/sk:0x24 --order 3:def/atk@4/sk:0x2b@2
  mass 7 --ecount 3 --wld 1=0 --pskills 1=0x3f,0x48 --php 900 --ehp 400 --rounds 4 --skip 67 --order 0:sk:0x5e/sk:0x3f/def
  dead1 3 --ecount 3 --wld 1=0 --php 900 --ehp 30 --rounds 4 --skip 69 --order 0:atk@4/atk@4/atk@4
  dead2 7 --ecount 3 --wld 1=0 --pskills 2=0x00,0x2c --php 900 --ehp 40 --rounds 4 --skip 71 --order 0:atk@5/sk:0x48@5/sk:0x00@5
  dead3 7 --ecount 3 --wld 1=0 --php 900 --ehp 40 --rounds 4 --skip 73 --order 0:atk@4/sk:0x5e/atk@4
  dead4 3 --ecount 2 --wld 1=0 --pskills 0=0x00,0x10 --php 900 --ehp 25 --rounds 3 --skip 75 --order 0:sk:0x00@4/atk@4/atk@5
  sleep_h 7 --ecount 2 --st 2:2=0x82 --php 900 --ehp 300 --rounds 5 --skip 77 --order 0:sk:0x5e/atk@4/sk:0x2c@0
  conf_w 7 --ecount 2 --st 1:2=0x10 --php 900 --ehp 400 --rounds 4 --skip 79 --order 0:sk:0x10/atk@4/sk:0x2c@1
  para_s 7 --ecount 2 --st 0:2=0x40 --php 900 --ehp 400 --rounds 4 --skip 81 --order 0:sk:0x10/atk@4/sk:0x2c@1
  nat40 40 --ecount 3 --php 900 --ehp 500 --rounds 7 --skip 83 --order 0:sk:0x10/def/sk:0x2c@0
  lowmp_h 7 --ecount 2 --pmp 2=3 --pskills 2=0x2c,0x00,0x1f --php 900 --ehp 300 --rounds 4 --skip 85 --order 0:atk@5/atk@5/sk:0x2c@0|sk:0x00@4|def
  lowmp_s 19 --ecount 2 --pmp 0=9 --php 900 --ehp 400 --rounds 4 --skip 87 --order 0:sk:0x10|sk:0x5e|atk@5/atk@4/sk:0x1f
  arena1 7 --ecount 2 --db73 2 --php 900 --ehp 300 --rounds 4 --skip 89 --order 0:sk:0x5e/atk@4/sk:0x2c@0
  arena2 19 --ecount 2 --db73 2 --wld 1=0x20 --php 900 --ehp 300 --rounds 4 --skip 91 --order 0:sk:0x5e/atk@4/sk:0x2c@0
  fight1 7 --ecount 2 --php 900 --ehp 400 --rounds 5 --skip 93 --order 0:sk:0x10/atk@4/sk:0x2c@1 --order 1:FIGHT --order 3:sk:0x5e/atk@5/def
  fight2 19 --ecount 2 --wld 0=0xFF --bases 0=200,50,50,100 --php 900 --ehp 400 --rounds 5 --skip 95 --order 0:sk:0x10/def/sk:0x1f --order 1:FIGHT --order 2:sk:0x10/def/sk:0x2c@0 --order 3:FIGHT
  long7 7 --ecount 3 --wld 1=0x22 --php 999 --ehp 900 --rounds 9 --skip 97 --order 0:sk:0x10/atk@6/sk:0x2c@1 --order 3:sk:0x62/atk@4/sk:0x1f --order 6:sk:0x5e/atk@5/def
  long20 20 --ecount 3 --wld 0=0x7C --php 999 --ehp 900 --rounds 9 --skip 99 --order 0:sk:0x10/atk@6/sk:0x2c@2 --order 4:def/atk@4/sk:0x2c@1
  fight3 20 --ecount 3 --wld 1=0x20 --php 900 --ehp 500 --rounds 7 --skip 101 --order 0:sk:0x10/atk@5/sk:0x2c@1 --order 1:FIGHT --order 2:sk:0x5e/atk@6/def --order 3:FIGHT --order 4:sk:0x62/atk@4/sk:0x1f --order 5:FIGHT
  fight4 60 --ecount 2 --wld 2=0xC8 --php 900 --ehp 500 --rounds 6 --skip 103 --order 0:FIGHT --order 1:sk:0x10/atk@5/sk:0x2c@0 --order 2:FIGHT --order 3:def/atk@4/sk:0x1f
  healus 19 --ecount 3 --pskills 2=0x2e,0x2c,0x1f,0x2b --php 900 --ehp 400 --rounds 6 --skip 105 --order 0:sk:0x10/atk@6/sk:0x2e --order 2:sk:0x62/atk@5/sk:0x2b@0 --order 4:sk:0x5e/def/sk:0x2e
  arena3 20 --ecount 2 --db73 2 --wld 0=0xFF --bases 0=200,50,50,100 --php 900 --ehp 300 --rounds 4 --skip 107 --order 0:sk:0x5e/atk@4/sk:0x2c@0
  wld_w30long 7 --ecount 3 --wld 1=0x24 --php 999 --ehp 900 --rounds 9 --skip 109 --order 0:sk:0x62/atk@4/sk:0x2c@1 --order 4:sk:0x10/atk@6/def
  mixed80 80 --ecount 3 --wld 0=0x9C --wld 2=0xA0 --php 999 --ehp 600 --rounds 8 --skip 111 --order 0:sk:0x10/atk@5/sk:0x2c@1 --order 3:atk@4/sk:0x48@6/sk:0x1f --order 5:FIGHT --order 6:sk:0x5e/def/sk:0x2c@0

Hook-safety: A is mashed (4 on / 4 off) only OUTSIDE the command phase;
inside it the driver presses one button, waits 20 frames, re-reads.
"""
import sys, json, os, argparse, gzip
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import *

SP = '/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/meas'
ap = argparse.ArgumentParser()
ap.add_argument('name'); ap.add_argument('eid', type=int)
ap.add_argument('--ecount', type=int, default=1)
ap.add_argument('--order', action='append', default=[])
ap.add_argument('--wld', action='append', default=[])
ap.add_argument('--bases', action='append', default=[])
ap.add_argument('--tactic', action='append', default=[])
ap.add_argument('--pskills', action='append', default=[])
ap.add_argument('--php', type=int); ap.add_argument('--ehp', type=int)
ap.add_argument('--emp', type=int)
ap.add_argument('--pmp', action='append', default=[])
ap.add_argument('--db73', type=int)
ap.add_argument('--st', action='append', default=[], help='SLOT:off=val status-block poke at init')
ap.add_argument('--rounds', type=int, default=6)
ap.add_argument('--frames', type=int, default=40000)
ap.add_argument('--skip', type=int, default=0)
ap.add_argument('--rom', default=SP + '/u22.gbc')
ap.add_argument('--state', default=SP + '/field.state')
ap.add_argument('--out', default=SP + '/command_events.json')
ap.add_argument('--maxev', type=int, default=6000)
ap.add_argument('--shot')
a = ap.parse_args()

RNG1, RNG2 = 0xC899, 0xC89A


def w16(m, ad):
    return m[ad] | (m[ad + 1] << 8)


def snap(p, tag):
    m = p.memory
    rf = p.register_file
    def arr(ad, n): return list(m[ad:ad + n])
    def w16s(ad): return [m[ad + 2 * i] | (m[ad + 2 * i + 1] << 8) for i in range(8)]
    return dict(
        tag=tag, sc=a.name, frame=p.frame_count, A=rf.A, B=rf.B, C=rf.C, HL=rf.HL,
        d9ec=m[0xD9EC], d9ed=m[0xD9ED], d9ee=m[0xD9EE], d9ef=m[0xD9EF],
        d9f4=m[0xD9F4], d9f5=m[0xD9F5], d9f7=m[0xD9F7],
        c8da=m[0xC8DA], c8dc=m[0xC8DC], c8dd=m[0xC8DD], c8de=m[0xC8DE],
        c1cd=arr(0xC1CD, 8), c876=arr(0xC876, 4), c88b=m[0xC88B],
        db77=m[0xDB77], db78=m[0xDB78], db82=m[0xDB82],
        db88=m[0xDB88], db89=m[0xDB89], db8a=m[0xDB8A],
        db56=m[0xDB56] | (m[0xDB57] << 8), dd6f=m[0xDD6F], dd69=m[0xDD69],
        dcfd=m[0xDCFD], dcfe=m[0xDCFE], db4c=m[0xDB4C], db4d=m[0xDB4D], db4e=m[0xDB4E],
        db4f=m[0xDB4F], db53=m[0xDB53], db50=arr(0xDB50, 3), dd72=m[0xDD72],
        rng1=m[RNG1], rng2=m[RNG2], c86c=m[0xC86C], db73=m[0xDB73],
        db71=m[0xDB71] | (m[0xDB72] << 8), db54=m[0xDB54], da33=m[0xDA33],
        db79=arr(0xDB79, 9), dcec=arr(0xDCEC, 16),
        dd13=arr(0xDD13, 8), dd1b=arr(0xDD1B, 8), dd03=arr(0xDD03, 8),
        dd0b=arr(0xDD0B, 8), db8b=arr(0xDB8B, 8), db9b=arr(0xDB9B, 8),
        db42=arr(0xDB42, 8), db40=arr(0xDB40, 2),
        hp=w16s(0xDBA3), maxhp=w16s(0xDBB3), mp=w16s(0xDBC3), maxmp=w16s(0xDBD3),
        ai_bases=[m[0xDC44 + i] for i in range(32)], wld=w16s(0xDC23),
        atk=w16s(0xDBE3), dfn=w16s(0xDBF3), agl=w16s(0xDC03), int=w16s(0xDC13),
        st=arr(0xDB00, 64), res=arr(0xDD28, 56), dc3c=arr(0xDC3C, 8),
        dc64=arr(0xDC64, 128),
        eid=[w16(m, 0xDA03), w16(m, 0xDA05), w16(m, 0xDA07)])


HOOKS = [
    # ---- the S85 round loop (measure_battle.py) ----
    (0x58, 0x54D1, 'round_start'), (0x53, 0x4546, 'actor_fetch'),
    (0x53, 0x454F, 'gates_in'), (0x53, 0x462C, 'forced'),
    (0x53, 0x45CD, 'curse_stage'), (0x53, 0x4C50, 'curse_hit'),
    (0x53, 0x4657, 'dupconv'), (0x53, 0x467C, 'skill_load'),
    (0x53, 0x520C, 'target_fetch'), (0x53, 0x4799, 'reresolve'),
    (0x53, 0x47E8, 'dead_redirect'), (0x53, 0x5747, 'miss_in'),
    (0x53, 0x5766, 'miss_rng'), (0x53, 0x5810, 'miss'), (0x53, 0x57F7, 'dodge'),
    (0x53, 0x582A, 'block'), (0x53, 0x586A, 'miss_pass'),
    (0x52, 0x60D7, 'calcdef_in'), (0x52, 0x679C, 'roll_in'),
    (0x52, 0x54E7, 'final_54e7'), (0x52, 0x5C51, 'status_in'),
    (0x52, 0x5C8F, 'status_roll'), (0x52, 0x5CBC, 'status_roll'),
    (0x52, 0x5CDA, 'status_roll'), (0x52, 0x65B5, 'statchance_in'),
    (0x52, 0x65C9, 'statchance_in'), (0x52, 0x4200, 'hit_path'),
    (0x52, 0x4225, 'miss_path'), (0x52, 0x6D56, 'apply_in'), (0x52, 0x7EE3, 'ko'),
    (0x50, 0x6B25, 'p9_slot'), (0x50, 0x6C14, 'p9_dot_apply'),
    (0x50, 0x6C59, 'p9_dot_ko'), (0x53, 0x4640, 'round_end'),
    (0x50, 0x6CBE, 'side_wipe'), (0x53, 0x4BEB, 'conf_pick'),
    (0x53, 0x5F3E, 'snap_roll'), (0x53, 0x5544, 'guard_redir'),
    (0x52, 0x6CDD, 'h_ret'),
    # ---- the menu's writes (bank $50) ----
    (0x50, 0x4F86, 'm_skill'), (0x50, 0x4F95, 'm_target'),
    (0x50, 0x4F45, 'm_mark'), (0x50, 0x4CA4, 'm_msg'),
    # ---- the commit (bank $57 / $58) ----
    (0x57, 0x6E2A, 'ai_s0'), (0x57, 0x7A16, 'band_in'), (0x57, 0x7A5D, 'decide_in'),
    (0x57, 0x6EF4, 'carry'), (0x57, 0x6F8C, 'nocarry'), (0x57, 0x6FE0, 'pers'),
    (0x57, 0x718C, 'cmd_keep'), (0x57, 0x6F64, 'direct'), (0x57, 0x7859, 'ai_post'),
    (0x58, 0x5498, 'qfetch'),
    (0x52, 0x4E0A, 'daze'),
    (0x58, 0x5478, 'tension_in'),          # commit sub-state: before LoadBtlFX_5a40/5ba1
    (0x52, 0x7041, 'mh_cont'),             # F8 multi-hit continuation (oracle class)
]

events = []
p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)
for _ in range(a.skip):
    p.tick()
m = p.memory


def rec_base(slot):
    return 0xCAC1 + (m[0xCA8E + slot] & 0x7F) * 0x95


for spec in a.wld:
    s, v = spec.split('='); m[rec_base(int(s)) + 0x60] = int(v, 0)
for spec in a.bases:
    s, v = spec.split('=')
    c1, c2, c3, w3 = (int(x, 0) for x in v.split(','))
    r = rec_base(int(s))
    m[r + 0x64], m[r + 0x65], m[r + 0x66], m[r + 0x67] = c1, c3, w3, c2
for spec in a.pskills:
    s, v = spec.split('='); r = rec_base(int(s))
    sk = [int(x, 0) for x in v.split(',')] + [0xFF] * 8
    for k in range(8):
        m[r + 41 + k] = sk[k]
for spec in a.tactic:
    s, v = spec.split('='); r = rec_base(int(s))
    m[r + 0x0B] = (int(v, 0) << 4) | (m[r + 0x0B] & 0x0F)

for bank, addr, tag in HOOKS:
    p.hook_register(bank, addr, (lambda ctx, t=tag: events.append(snap(p, t))), None)

orders = {}
for spec in a.order:
    r, s = spec.split(':', 1)
    orders[int(r)] = s


def order_for(rnd):
    ks = [k for k in orders if k <= rnd]
    return orders[max(ks)] if ks else 'FIGHT'


m[0xDA03] = a.eid & 0xFF; m[0xDA04] = (a.eid >> 8) & 0xFF
m[0xDA02] = (a.ecount - 1) & 3
if a.ecount > 1:
    m[0xDA05] = m[0xDA03]; m[0xDA06] = m[0xDA04]
if a.ecount > 2:
    m[0xDA07] = m[0xDA03]; m[0xDA08] = m[0xDA04]
m[0xDA09] = 1; m[0xC905] = 0; m[0xC8EB] |= 0x40


def wr16(ad, v):
    m[ad] = v & 0xFF; m[ad + 1] = (v >> 8) & 0xFF


class Driver:
    """One command phase: walks the real menu with joypad presses."""

    def __init__(self, rnd):
        self.rnd = rnd
        spec = order_for(rnd)
        self.fight = spec == 'FIGHT'
        self.entries = [] if self.fight else spec.split('/')
        self.alt = {}            # slot -> index into its '|' alternatives
        self.done = False
        self.log = []
        self.nmsg = sum(1 for e in events if e['tag'] == 'm_msg')
        self.msg_wait = 0
        self.tries = 0

    def _wait(self):
        self.msg_wait += 1
        return None

    def entry(self, slot):
        if slot >= len(self.entries):
            e = self.entries[-1] if self.entries else 'atk'
        else:
            e = self.entries[slot]
        alts = e.split('|')
        k = self.alt.get(slot, 0)
        return alts[k] if k < len(alts) else 'atk'   # every alternative refused

    def step(self):
        """-> button to press now, or None (wait)."""
        f4, f5, f7 = m[0xD9F4], m[0xD9F5], m[0xD9F7]
        nmsg = sum(1 for e in events if e['tag'] == 'm_msg')
        if nmsg > self.nmsg:                           # the menu refused the order
            self.nmsg = nmsg                           # (SaveBtl_4ca4): next alternative
            slot = m[0xC8DD] & 3
            self.alt[slot] = self.alt.get(slot, 0) + 1
            self.log.append(('refused', slot))
        if m[0xC825]:                                  # a message box is up
            return 'a' if self.msg_wait > 40 else self._wait()
        self.msg_wait = 0
        if f4 == 2:                                   # top menu
            want = 0 if self.fight else 1
            cur = m[0xC8DA] & 3
            if cur != want:
                return 'down' if cur < want else 'up'
            return 'a'
        if f4 != 3:
            return None
        sel = m[0xC8DA]
        slot = m[0xC8DD] & 3
        if sel == 0x81 and f5 == 4:                    # tactic list
            e = self.entry(slot)
            want = int(e.split(':')[1]) if e.startswith('tac:') else 3
            cur = m[0xC8DC] & 3
            if cur != want:
                return 'down' if cur < want else 'up'
            return 'a'
        if sel != 0x04:
            return None
        e = self.entry(slot)
        if f7 == 2:                                    # ATK / SKIL / DEF
            want = 0 if e.startswith('atk') else (1 if e.startswith('sk:') else 2)
            cur = m[0xC8DE] & 3
            if cur != want:
                return 'down' if cur < want else 'up'
            return 'a'
        if f7 == 4:                                    # skill list
            if not e.startswith('sk:'):
                return 'b'                             # back to ATK / SKIL / DEF
            sk = int(e.split(':')[1].split('@')[0], 0)
            lst = [m[0xDC65 + 16 * slot + 2 * j] for j in range(8)]
            want = lst.index(sk)                       # 4 rows per page: up/down wrap
            if (m[0xC8E0] & 1) != want // 4:           # in the page, left/right flip
                return 'right'
            cur = m[0xC8DF] & 3
            if cur != want % 4:
                return 'down' if cur < want % 4 else 'up'
            return 'a'
        if f7 in (6, 8):                               # target cursor
            if not (e.startswith('sk:') or e.startswith('atk')):
                return 'b'
            t = int(e.split('@')[1], 0) if '@' in e else None
            if t is not None and (m[0xDD1B + t] != 0 or self.tries > 8):
                # the cursor skips dead slots (BtlFunc_5b7a): the order can't
                # be given -> back out, next alternative (pacing.menu_order
                # 'target')
                self.alt[slot] = self.alt.get(slot, 0) + 1
                self.log.append(('dead-target', slot, t))
                self.tries = 0
                return 'b'
            cur = m[0xDD72] & 3
            if t is not None and cur != (t & 3):
                self.tries += 1
                return 'down' if cur < (t & 3) else 'up'
            self.tries = 0
            return 'a'
        return None


started = False
forced = False
drv = None
nrs, scanned = 0, 0
cmd_rounds = 0
press_until = 0
held = None
i = 0
for i in range(a.frames):
    while scanned < len(events):
        nrs += events[scanned]['tag'] == 'round_start'; scanned += 1
    if m[GAME_MODE] == 2:
        if not started:
            m[0xC8EB] &= ~0x40
        started = True
        if not forced and m[0xD9EC] <= 3 and m[0xD9ED] >= 1:
            forced = True
            events.append(snap(p, 'battle_init'))   # unpoked source stats
            if a.php is not None:
                for s in range(3):
                    if m[0xDD1B + s] == 0:
                        wr16(0xDBA3 + 2 * s, a.php); wr16(0xDBB3 + 2 * s, a.php)
            for spec in a.pmp:
                s, v = spec.split('='); wr16(0xDBC3 + 2 * int(s), int(v, 0))
            for spec in a.st:
                s, kv = spec.split(':'); off, v = kv.split('=')
                m[0xDB00 + 8 * int(s) + int(off, 0)] = int(v, 0)
            for k in range(3):
                if a.emp is not None:
                    wr16(0xDBC3 + 8 + 2 * k, a.emp); wr16(0xDBD3 + 8 + 2 * k, a.emp)
                if a.ehp is not None:
                    wr16(0xDBA3 + 8 + 2 * k, a.ehp); wr16(0xDBB3 + 8 + 2 * k, a.ehp)
        if a.db73 is not None and m[0xD9EC] >= 1:
            m[0xDB73] = a.db73
        if nrs > a.rounds:
            break
        if m[0xD9EC] >= 0x0A:                    # post-battle phases: the outcome
            events.append(snap(p, 'battle_end'))
            break
        if m[0xD9EC] == 4:
            if drv is None or drv.done:
                if drv is None:
                    drv = Driver(cmd_rounds)
            if held is not None:
                if i >= press_until:
                    p.button_release(held); held = None; press_until = i + 16
            elif i >= press_until:
                btn = drv.step()
                if btn:
                    p.button_press(btn); held = btn; press_until = i + 4
                    drv.log.append(btn)
        else:
            if drv is not None:
                events.append(dict(snap(p, 'm_round'), rnd=drv.rnd, keys=drv.log,
                                   spec=order_for(drv.rnd)))
                drv = None
                cmd_rounds += 1
            if held is not None:
                p.button_release(held); held = None
            if i % 8 < 4:
                p.button_press('a')
            else:
                p.button_release('a')
    elif started:
        break
    if len(events) >= a.maxev:
        break
    p.tick(1, False)

if a.shot:
    from tools.pyboy_harness import snap as shot
    shot(p, a.shot)

for e in events:                     # the option lists only where read
    if e['tag'] not in ('battle_init', 'm_round', 'round_start'):
        e.pop('dc64', None)
old = []
if os.path.exists(a.out):
    op = gzip.open(a.out, 'rt') if a.out.endswith('.gz') else open(a.out)
    old = [e for e in json.load(op) if e['sc'] != a.name]
wp = gzip.open(a.out, 'wt') if a.out.endswith('.gz') else open(a.out, 'w')
json.dump(old + events, wp, separators=(',', ':'))
wp.close()
tags = {}
for e in events:
    tags[e['tag']] = tags.get(e['tag'], 0) + 1
if '-v' in sys.argv[1:] or os.environ.get('CMD_VERBOSE'):
    print('menu', m[0xD9EC], m[0xD9F4], m[0xD9F5], m[0xD9F7], hex(m[0xC8DA]), hex(m[0xC8DC]),
          hex(m[0xC8DE]), hex(m[0xC8DF]), hex(m[0xC8E0]), hex(m[0xDD72]), drv.log[-12:] if drv else None)
    for e in events:
        if e['tag'] == 'm_round':
            print(e['rnd'], e['keys'])
print(f'{a.name}: +{len(events)} events (total {len(old)+len(events)}) frames={i} rounds={nrs} {tags}')
