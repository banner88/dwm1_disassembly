#!/usr/bin/env python3
"""S130 F9 (combatant-changing and meta skills) capture rig = a copy of
measure_f8_multihit.py (the S85 rig + the F8 waypoints, unchanged
behaviour) with the F9 waypoints added:

  h_summon $52:$4BD0 (TatsuCall family entry, pre RNG step), summon_done
  $4C24 (helper loaded), summon_used $4C25 (side bit2 already set, $BB),
  summon_fail $4C2B (RNG1 >= $C0, $CB); h_chance $52:$4616, chance_roll
  $53:$4D7E (Chance picker entry, once per (re-)roll, pre-step),
  chance_pick $53:$4DCF (accepted id in $DB8A); h_bedragon $52:$4E0E,
  dragon_form $52:$6D0A (act state 4 entry, pre form change),
  dragon_formed $52:$6D12 (after bank $51 entry 9), tf_rewrite $52:$7AB5
  (TransformActionRewrite entry, RNG as read), tf_rewrite_done $7AF6;
  h_transform $52:$446C, tf_copy $52:$6D20, tf_copied $52:$6D28,
  tf_revert_dm $52:$7A5F (DeMagic state-4 self-revert),
  tf_revert_ko $51:$4CA7 (KO wipe revert, BitBtlS_4ca0);
  h_run $52:$4E3A (shared with the confusion $A1: also tagged meta_run),
  run_tail $52:$4E64, h_smashed $52:$4EF9; ai_cat $57:$73B9 and
  ai_post $57:$7859 (the AI decision for any actor, incl. helpers).
Snapshots add $DC3C (species per slot), the whole $DC64 option area
(16 bytes per slot), $C1CA..$C1CD (4) + $C1CD..(8), $DB74/$DB75.

Extra flags: --force-rounds N (force --skill/--eskill(s)/--hskill only in
the first N command phases, latched at $D9EC==4), --pslot k (slot forced
by --skill), --pskill1 X --ptarget1 T --force1-rounds N (party slot 1),
--sched / --esched R:SK:T[:SLOT],... (per command phase R, party default
slot 0 / enemy default slot 4), --hskill X --htarget T (helper slot 3),
--ehskill X --ehtarget T (helper slot 7), --pmpall N (party MP/MaxMP at
init), --prefill / --erefill N (MP := N at every command phase), --estat /
--pstat atk=..,dfn=..,agl=..,int=..,hp=.. (init pokes, --pmpall needed),
--poke 0xADDR=0xVAL,... (init). A 'battle_init' event (before any poke)
carries the unpoked source stats.
Corpus recipe: S130_F9_NOTES.md (every run with its flags).

---- F8 rig header ----
S130 F8 (multi-hit loop) capture rig = a copy of measure_battle.py (the S85
rig, unchanged behaviour) with the F8 waypoints added: the state-6
continuation dispatch $52:$7041 (mh_cont, RNG as found), the bank $58
uniform re-pick $642C (repick, pre-step), the multi-hit skill handlers
(h_biattack $4798, h_callhelp $480C, h_rainslash $48B4, h_meteor $501F,
h_bigsleep $4F54, h_mp0 $4F7F), the CallHelp helper damage LoadBattle_63dc
(helper_dmg), and $DD69/$D9EF/$C1C9/$DD6E in every snapshot. Extra flags:
--eskills a,b,c (force enemy slots 4-6 queues), --etargets, --ehps a,b,c
(per-enemy HP+MaxHP), --elvl N, --pdd0b N (party slot-0 $DD0B).

Corpus recipe: see simulator/f8_events.json's `sc` names and
S130_F8_NOTES.md (every run is listed with its flags).

---- original S85 header ----
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
ap.add_argument('--pmp', type=int)
ap.add_argument('--emp', type=int); ap.add_argument('--ehp', type=int)
ap.add_argument('--pst', help='poke party slot-0 status block: off=val,off=val (after init)')
ap.add_argument('--est', help='poke enemy slot-4 status block: off=val,...')
ap.add_argument('--skill', type=lambda x: int(x, 0)); ap.add_argument('--target', type=int, default=4)
ap.add_argument('--eskill', type=lambda x: int(x, 0)); ap.add_argument('--etarget', type=int, default=0)
ap.add_argument('--frames', type=int, default=6000)
ap.add_argument('--skip', type=int, default=0)
ap.add_argument('--rom', default='/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/f9/u22.gbc')
ap.add_argument('--state', default='/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/f9/field.state')
ap.add_argument('--out', default='/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/f9/raw.json')
ap.add_argument('--maxev', type=int, default=400)
ap.add_argument('--eskills', help='S130 F8: force enemy slots 4-6 queued skills a,b,c')
ap.add_argument('--etargets', help='S130 F8: targets for --eskills a,b,c')
ap.add_argument('--ehps', help='S130 F8: per-enemy HP (=MaxHP) a,b,c')
ap.add_argument('--elvl', type=int, help='S130 F8: enemy level (all)')
ap.add_argument('--pdd0b', type=int, help='S130 F8: party slot-0 $DD0B per frame (0 = keep queued target)')
ap.add_argument('--eres6', type=lambda x: int(x, 0), help='S130 F8: poke every enemy resistance byte 6 ($DD28+7k+6; rtype 24 = bits 5:4)')
ap.add_argument('--pres6', type=lambda x: int(x, 0), help='S130 F8: same for party slots 0-2')
ap.add_argument('--f8trim', action='store_true', help='S130 F8: keep only the multi-hit action windows (f8_trim)')
ap.add_argument('--force-rounds', type=int, default=99, help='S130 F9: force queues only in the first N command phases')
ap.add_argument('--pslot', type=int, default=0, help='S130 F9: party slot forced by --skill')
ap.add_argument('--hskill', type=lambda x: int(x, 0), help='S130 F9: force helper slot 3 queue')
ap.add_argument('--htarget', type=int, default=4)
ap.add_argument('--ehskill', type=lambda x: int(x, 0), help='S130 F9: force helper slot 7 queue')
ap.add_argument('--ehtarget', type=int, default=0)
ap.add_argument('--pmpall', type=int, help='S130 F9: all party MP=MaxMP')
ap.add_argument('--estat', help='S130 F9: enemy slots 4-6 stats at init: atk=N,dfn=N,agl=N,int=N')
ap.add_argument('--pstat', help='S130 F9: party slots 0-2 stats at init: atk=N,dfn=N,agl=N,int=N,hp=N (hp sets HP+MaxHP)')
ap.add_argument('--poke', help='S130 F9: raw byte pokes at init: 0xADDR=0xVAL,...')
ap.add_argument('--pskill1', type=lambda x: int(x, 0), help='S130 F9: force party slot 1 queue')
ap.add_argument('--ptarget1', type=int, default=4)
ap.add_argument('--sched', help='S130 F9: per-round party queue forcing: R:SK:T[:SLOT],... (R = command phase 1-based)')
ap.add_argument('--esched', help='S130 F9: per-round enemy queue forcing: R:SK:T[:SLOT],... (SLOT default 4)')
ap.add_argument('--prefill', type=int, help='S130 F9: party slots 0-2 MP := N at every command phase')
ap.add_argument('--erefill', type=int, help='S130 F9: enemy slots 4-6 MP := N at every command phase')
ap.add_argument('--force1-rounds', type=int, default=99, help='S130 F9: rounds for --pskill1')
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
        dd69=m[0xDD69], d9ef=m[0xD9EF], c1c9=m[0xC1C9], dd6e=m[0xDD6E], dd6b=m[0xDD6B],
        hp=w16s(0xDBA3), maxhp=w16s(0xDBB3), mp=w16s(0xDBC3), maxmp=w16s(0xDBD3),
        # S88 (per the S87 deferral): the four AI category base arrays
        # $DC44/$DC4C/$DC54/$DC5C (cat1/cat2/cat3/w3) + per-combatant WLD
        # words $DC23+2i (wBattleLVL misnomer; enemies $00FF).
        ai_bases=[m[0xDC44+i] for i in range(32)], wld=w16s(0xDC23),
        atk=w16s(0xDBE3), dfn=w16s(0xDBF3), agl=w16s(0xDC03), int=w16s(0xDC13),
        st=arr(0xDB00, 64), res=arr(0xDD28, 56),
        # S130 F9: helper / transform state
        dc3c=arr(0xDC3C, 8), dc64=arr(0xDC64, 128), c1ca=arr(0xC1CA, 3), c1cd=arr(0xC1CD, 8),
        db74=m[0xDB74], db75=m[0xDB75], db40=arr(0xDB40, 2),
        dcfc=arr(0xDCFC, 6), dce4=arr(0xDCE4, 8), dd6a=m[0xDD6A], dd02=m[0xDD02], db50=arr(0xDB50, 3), dd26=m[0xDD26] | (m[0xDD27] << 8),
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
    # S130 F8 multi-hit loop waypoints:
    (0x52, 0x7041, 'mh_cont'),       # state-6 continuation dispatch (ld a,[$db8a]); RNG as found
    (0x58, 0x642C, 'repick'),        # LoadBtlFX_642c uniform opposing pick (pre-step)
    (0x52, 0x4798, 'h_biattack'),    # SkillBiAttack ($50/$51)
    (0x52, 0x480C, 'h_callhelp'),    # SkillCallHelp ($52/$53), pre first-pass roll
    (0x52, 0x48B4, 'h_rainslash'),   # SkillRainSlash ($57)
    (0x52, 0x501F, 'h_meteor'),      # SkillMETEOR ($AF)
    (0x52, 0x4F54, 'h_bigsleep'),    # SkillBIGSLEEP ($A7)
    (0x52, 0x4F7F, 'h_mp0'),         # SkillMP0 ($A8)
    (0x52, 0x63DC, 'helper_dmg'),    # LoadBattle_63dc CallHelp helper damage
    # S130 F9 waypoints:
    (0x52, 0x4BD0, 'h_summon'),      # SkillTatsuCall entry (pre BattleRNG)
    (0x52, 0x4C24, 'summon_done'),   # helper loaded into slot (side|3)
    (0x52, 0x4C25, 'summon_used'),   # side byte bit2 already set -> $BB
    (0x52, 0x4C2B, 'summon_fail'),   # RNG1 >= $C0 -> $CB
    (0x52, 0x4616, 'h_chance'),      # SkillChance
    (0x53, 0x4D7E, 'chance_roll'),   # picker (re-)roll entry, pre step
    (0x53, 0x4DCF, 'chance_pick'),   # accepted outcome id in $DB8A
    (0x52, 0x4E0E, 'h_bedragon'),    # SkillBeDragon / CHGDRAGON
    (0x52, 0x6D0A, 'dragon_form'),   # act state 4 entry (pre bank $51 e9)
    (0x52, 0x6D12, 'dragon_formed'), # after the form change
    (0x52, 0x7AB5, 'tf_rewrite'),    # TransformActionRewrite_7ab5 entry
    (0x52, 0x7AF6, 'tf_rewrite_done'),
    (0x52, 0x446C, 'h_transform'),   # SkillTransform
    (0x52, 0x6D20, 'tf_copy'),       # act state 5 (pre TransformCopyStats_5f5e)
    (0x52, 0x6D28, 'tf_copied'),
    (0x52, 0x7A5F, 'tf_revert_dm'),  # DeMagic state-4 self revert (dragon caster)
    (0x52, 0x7A49, 'dm_tail'),       # DeMagic state-4 tail entry (+3 bit4 test)
    (0x52, 0x4BA1, 'h_demagic'),     # SkillDeMagic_ThickFog ($80/$83/$A5)
    (0x51, 0x4CA7, 'tf_revert_ko'),  # BitBtlS_4ca0 revert on KO wipe
    (0x52, 0x4E64, 'run_tail'),      # SkillRUN tail (after $DD1B := $FF)
    (0x52, 0x4EF9, 'h_smashed'),     # SkillSmashed ($A2 / $A4)
    (0x57, 0x73B9, 'ai_cat'),        # AI category stage (per decision)
    (0x57, 0x7859, 'ai_post'),       # AI post (commit)
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
in_cmd = False
cmd_round = 0
mp_done = False
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
            events.append(snap(p, 'battle_init'))   # S130 F9: unpoked source stats
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
            if a.ehps:
                for k, v in enumerate(int(x) for x in a.ehps.split(',')):
                    m[0xDBA3 + 8 + 2*k] = v & 0xFF; m[0xDBA4 + 8 + 2*k] = v >> 8
                    m[0xDBB3 + 8 + 2*k] = v & 0xFF; m[0xDBB4 + 8 + 2*k] = v >> 8
            if a.eres6 is not None:
                for k in range(4, 7):
                    m[0xDD28 + 7*k + 6] = a.eres6
            if a.pres6 is not None:
                for k in range(3):
                    m[0xDD28 + 7*k + 6] = a.pres6
            if a.elvl is not None:
                for k in range(3):
                    m[0xDB9B + 4 + k] = a.elvl
            for spec, base in ((a.pst, 0xDB00), (a.est, 0xDB20)):
                if spec:
                    for kv in spec.split(','):
                        off, val = kv.split('=')
                        m[base + int(off, 0)] = int(val, 0)
        if a.db73 is not None and m[0xD9EC] >= 1:
            m[0xDB73] = a.db73
        if m[0xD9EC] == 4 and not in_cmd:     # S130 F9: latch the command phase
            in_cmd = True; cmd_round += 1
        elif m[0xD9EC] != 4:
            in_cmd = False
        if a.pmpall is not None and not mp_done and m[0xD9EC] <= 3 and m[0xD9ED] >= 1:
            mp_done = True
            STATA = dict(atk=0xDBE3, dfn=0xDBF3, agl=0xDC03, int=0xDC13, hp=0xDBA3)
            for spec, slots in ((a.estat, (4, 5, 6)), (a.pstat, (0, 1, 2))):
                for kv in (spec.split(',') if spec else []):
                    k, v = kv.split('='); v = int(v, 0)
                    for sl in slots:
                        ad = STATA[k] + 2 * sl
                        m[ad] = v & 0xFF; m[ad + 1] = v >> 8
                        if k == 'hp':
                            m[ad + 0x10] = v & 0xFF; m[ad + 0x11] = v >> 8
            for kv in (a.poke.split(',') if a.poke else []):
                ad, v = kv.split('='); m[int(ad, 0)] = int(v, 0)
            for k in range(3):
                m[0xDBC3 + 2*k] = a.pmpall & 0xFF; m[0xDBC4 + 2*k] = a.pmpall >> 8
                m[0xDBD3 + 2*k] = a.pmpall & 0xFF; m[0xDBD4 + 2*k] = a.pmpall >> 8
        if m[0xD9EC] == 4:
            for fill, slots in ((a.prefill, (0, 1, 2)), (a.erefill, (4, 5, 6))):
                if fill is not None:
                    for sl in slots:
                        if m[0xDD1B + sl] == 0:
                            m[0xDBC3 + 2*sl] = fill & 0xFF; m[0xDBC4 + 2*sl] = fill >> 8
        if 4 <= m[0xD9EC] <= 6:
            for spec, dslot in ((a.sched, 0), (a.esched, 4)):
                for item in (spec.split(',') if spec else []):
                    f_ = item.split(':')
                    if int(f_[0]) == cmd_round:
                        sl = int(f_[3]) if len(f_) > 3 else dslot
                        if m[0xDD1B + sl] == 0:
                            m[0xDCEC + 2*sl] = int(f_[1], 0); m[0xDCED + 2*sl] = int(f_[2])
        if 4 <= m[0xD9EC] <= 6 and cmd_round <= a.force1_rounds and a.pskill1 is not None:
            m[0xDCEE] = a.pskill1; m[0xDCEF] = a.ptarget1
        if 4 <= m[0xD9EC] <= 6 and cmd_round <= a.force_rounds:       # command/order/fetch phases: force queues (not during act)
            if a.skill is not None:
                m[0xDCEC + 2*a.pslot] = a.skill; m[0xDCED + 2*a.pslot] = a.target
            if a.hskill is not None and m[0xDD1B + 3] == 0:
                m[0xDCF2] = a.hskill; m[0xDCF3] = a.htarget
            if a.ehskill is not None and m[0xDD1B + 7] == 0:
                m[0xDCFA] = a.ehskill; m[0xDCFB] = a.ehtarget
            if a.eskill is not None:
                m[0xDCF4] = a.eskill; m[0xDCF5] = a.etarget
            if a.eskills:
                ets = [int(x) for x in a.etargets.split(',')] if a.etargets else [0, 0, 0]
                for k, x in enumerate(a.eskills.split(',')):
                    if x:
                        m[0xDCF4 + 2*k] = int(x, 0); m[0xDCF5 + 2*k] = ets[k]
            if a.pdd0b is not None:
                m[0xDD0B] = a.pdd0b
    elif started:
        break
    if len(events) >= a.maxev:
        break
    if i % 8 < 4:
        p.button_press('a')
    else:
        p.button_release('a')
    p.tick()

F8_IDS = {0x50, 0x51, 0x52, 0x53, 0x57, 0xA7, 0xA8, 0xAF}
BOUNDARY = ('actor_fetch', 'round_end', 'p9_slot', 'round_start', 'side_wipe')


def f8_trim(evs):
    """Keep only the multi-hit actions: each window runs from the actor's
    skill_load to the next actor boundary (inclusive), kept iff a
    target_fetch inside it carries an F8 skill in $DB8A. Drops the AI
    planning arrays (ai_bases/wld) the F8 validator never reads."""
    out, i = [], 0
    while i < len(evs):
        if evs[i]['tag'] != 'skill_load':
            i += 1; continue
        j = i + 1
        while j < len(evs) and evs[j]['tag'] not in BOUNDARY:
            j += 1
        win = evs[i:j + 1]
        if any(e['tag'] == 'target_fetch' and e['db8a'] in F8_IDS for e in win):
            for e in win:
                out.append({k: v for k, v in e.items() if k not in ('ai_bases', 'wld')})
        i = j
    return out


ap2_trim = a.f8trim
if ap2_trim:
    events = f8_trim(events)
old = []
if os.path.exists(a.out):
    old = json.load(open(a.out))
json.dump(old + events, open(a.out, 'w'), separators=(',', ':'))
tags = {}
for e in events:
    tags[e['tag']] = tags.get(e['tag'], 0) + 1
print(f'{a.name}: +{len(events)} events (total {len(old)+len(events)}) frames={i} {tags}')
