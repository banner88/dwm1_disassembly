#!/usr/bin/env python3
"""
resection_battle_core.py — S83 annotation catch-up (Iron Rule 6, part 2):
banks $52/$53/$58 battle core. LABELS/COMMENTS/DATA-RESECTION ONLY — zero
byte impact; the probe build and the final build are both asserted against
the original MD5, per bank. Idempotent: a bank whose marker label is present
is skipped.

Knowledge source: BATTLE_SKILL_SYSTEM §15.1-15.10 (S78/S79/S81 traced +
differentially validated findings) plus S83 byte-reads verified in-session
(inline rst $00 tables, the bank-$58 per-skill dispatch table at $401D, the
boss-gate compare ladder, the $520C entry-8 far-call). Transcription of
validated findings, not re-derivation.

What it does, per bank:
  - Converts misassembled inline `rst $00` dw tables to commented dw lists:
      $52:$6C60 (28-state action machine), $53:$44CE (9 setup sub-states),
      $53:$51EC (16 act-phase states).
  - Re-emits the bank $58 head dw region $4001-$41E8 as TWO tables: the
    14 rst $10 service entries (semantic comments) + the 230-entry
    per-skill dispatch table BtlSkillTargetDispatch_401d (skill names from
    extracted/skill_records.json).
  - Converts the 4-byte confusion action table $52:$7AFF to db and
    labelizes its raw `ld hl, $7aff` reference (same-address label,
    byte-identical).
  - Renames stage/helper auto-labels to semantic names (address suffix
    retained) and updates every reference in disassembly/ AND patches/.
  - Inserts §15-provenance comments at the damage/turn-order/status/
    target-resolution sites.

Mechanism: zero-byte probe labels + one build per bank; line addresses and
the existing-label map are read from game.sym (KEY_LESSONS S82: census from
the linker, never from name patterns). Splice ops that re-emit their anchor
line span it (end=start+1 — KEY_LESSONS S82).

Usage:
    python3 tools/resection_battle_core.py --analyze     # report only
    python3 tools/resection_battle_core.py               # apply all banks
    python3 tools/resection_battle_core.py --bank 52     # one bank
"""
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIS = os.path.join(REPO, "disassembly")
ROM = os.path.join(REPO, "data", "DWM-original.gbc")
ORIGINAL_MD5 = "1ca6579359f21d8e27b446f865bf6b83"

# =========================================================================
# BANK $52 — damage pipeline + skill handlers + action machine
# =========================================================================

B52_RENAMES = {
    "LoadBattle_61ec": "DamageSlot2AdjustFloor_61ec",
    "LoadBattle_679c": "RecordDamageRoll_679c",
    "LoadBattle_653e": "MegaMagicDamage_653e",
    "BattleCall_6232": "KamikazeDamage_6232",
    "BitCheck_676c": "ResLadderBreath_676c",
    "BitCheck_6782": "ResLadderElemSlash_6782",
    "BitCheck_6749": "HitLadderBeat_6749",
    "BitCheck_6733": "HitLadderKamikaze_6733",
    "SaveBattle_69b7": "DamageMul8Tenths_69b7",
    "SaveBattle_69d2": "DamageMul6Tenths_69d2",
    "BattleCall_69e1": "DamageMul4Tenths_69e1",
    "BattleFunc_6a13": "UpperStatCapCheck_6a13",
    "BattleFunc_6a49": "AglUpStatCapCheck_6a49",
    "Jump_052_6d56": "BtlActState2Apply_6d56",
    "jr_052_6cc7": "SkillHandlerDispatch_6cc7",
    "LoadBattle_7ab5": "ConfusionActionRewrite_7ab5",
    "jr_052_4225": "BtlOutcomeMissPath_4225",
}

B52_NEW_LABELS = {
    0x6C4D: "BattleActionMachine_6c4d",
    0x6C98: "BtlActState0Setup_6c98",
    0x71B5: "GroupVictimLoopA_71b5",
    0x71ED: "GroupVictimLoopB_71ed",
    0x4200: "BtlOutcomeHitPath_4200",
    0x642B: "WindBeastDamage_642b",
}

# 28-state action table $6C60: semantic names for the S79-measured states.
B52_STATE_NOTES = {
    0: "state 0: per-actor setup — ticks BtlPerActorSetup_44ca (bank $53 entry 0)",
    1: "state 1: enemy-AI decision tick (bank $57 machine, §15.10)",
    2: "state 2: damage APPLY (id-exclusion ladder + HP subtract)",
    3: "state 3: routes Sacrifice to bank $53 entry $0D (§15.7)",
    18: "state $12: same handler as state 0 (byte-verified duplicate)",
    26: "state $1A: KO state — actor HP hit 0, $D9F1=0 (§15.7)",
}

B52_LABEL_COMMENTS = {
    "CalcSkillDefense": [
        "; ============ THE PHYSICAL DAMAGE ROLL (bank $52 entry 5) — §15.1 ============",
        "; Traced S78, differentially validated 698/698 (simulator/damage.py,",
        "; validate_damage.py, s78_master_events.json). One BattleRNG step at entry;",
        "; all later reads reuse it. Three regimes:",
        ";   A: ATK <= DEF/2            -> damage = RNG1 & 1",
        ";   B: base=(ATK-DEF/2)>>1 <= ATK>>4 -> RNG16d mod (ATK>>4)  (>>4==0 -> A)",
        ";   C: var=(RNG16d mod ((base>>3)+1))>>1; RNG2&$0F: 0 none/&8 +var/else -var;",
        ";      RNG1&3: 0 none/odd +1/even -1; damage = base",
        "; RNG16d is the LCG state read BYTE-SWAPPED: (RNG2<<8)|RNG1 (S78 rule).",
        "; The plain attack command IS skill id $3A through this core.",
        "; DEF does NOT reduce record spells — those roll in RecordDamageRoll_679c.",
    ],
    "DamageSlot2AdjustFloor_61ec": [
        "; Post-roll adjust (§15.1): the THIRD party slot (target idx 2; in LINK,",
        "; idx&3==2 of either side) takes x0.8 — MEASURED S79 (rig --party3:",
        "; 45 -> 36 = 45*8//10 at commit; ti=1 control unchanged). Then the zero",
        "; floor: damage==0 -> RNG2&1 (AFTER the slot-2 adjust). A hook here sees",
        "; the PRE-adjust value (measure_rig waypoint).",
    ],
    "StoreDamageResult": [
        "; Record-spell roll commit (§15.2): damage = record_min + (RNG1 mod",
        "; (range+1)) — NO RNG advance, no caster stat, DEF does not reduce.",
        "; Side selection: party caster record +$0B/+$0D, enemy +$0F/+$11",
        "; (validated both sides, 69 checks S78). Heals are the same roll",
        "; (Heal = 30+RNG1%11 both sides; HealAll = 999 -> clamp to max).",
    ],
    "RecordDamageRoll_679c": [
        "; The record min/range fetch + roll used by StoreDamageResult (§15.2).",
    ],
    "ResLadderBreath_676c": [
        "; Breath-class damage multiplier ladder (§15.3): breaths, BigBang,",
        "; RockThrow, MegaMagic. Keyed on target status $DB05+slot*8 bits 6/7:",
        ";   normal [1, .75, .4, 0]; bit6 [.75, .5, .25, 0];",
        ";   bit7 amplify [1.3125, 1.15625, .75, .30].",
    ],
    "ResLadderElemSlash_6782": [
        "; Elemental-slash multiplier ladder (§15.3), applied AFTER the phys roll:",
        "; bit6 -> the plain row, otherwise the AMPLIFY row — a 1.3125x bonus",
        "; vs res-0 targets.",
    ],
    "HitLadderBeat_6749": [
        "; Hit ladder for Beat/Defeat/K.O.Dance, ids < $72, and the status helpers",
        "; (§15.3): NO bit6 branch. bit7 clear -> [$BF, $7F, $3F, never] — an",
        "; unguarded Beat vs res-0 is a 74.6% roll, not a sure hit (measured S78).",
        "; (RNG1 < threshold after one step.)",
    ],
    "HitLadderKamikaze_6733": [
        "; Hit ladder, Kamikaze class (§15.3): normal [always, $BF, $66, never].",
    ],
    "DamageMul8Tenths_69b7": [
        "; Shared x8/10 damage multiplier (§15.1): RainSlash hit 1, SquallHit, ...",
    ],
    "DamageMul6Tenths_69d2": [
        "; Shared x6/10 damage multiplier (§15.1): RainSlash hit 2, ...",
    ],
    "DamageMul4Tenths_69e1": [
        "; Shared (x8/10)>>1 = x4/10 multiplier (§15.1): RainSlash hits 3-4, ...",
    ],
    "SkillRainSlash": [
        "; RainSlash $57 (§15.1): $DD69 = hit counter, 4-HIT CAP MEASURED S79",
        "; (handler stops at $DD69==5); per-hit x.8/.6/.4/.4 via the DamageMul",
        "; helpers; dead targets skipped by walking $DB89 within the side.",
    ],
    "MegaMagicDamage_653e": [
        "; MegaMagic (§15.5, validated): base = 2*MP + 2*level (level array",
        "; $DB9B+slot); variance = 0.1*base (((base*8/10)>>1)>>2); one RNG step,",
        "; RNG1&1 odd -> -(RNG16d mod var) else +. vs MegaMagic res (15) through",
        "; the breath ladder. (The §8-era \"(MP*2+level*2)/4\" note was WRONG — no /4.)",
    ],
    "KamikazeDamage_6232": [
        "; Kamikaze (§15.5, validated): hit via Sacrifice-res ladder; caster HP==1",
        "; -> 1. The fork at $6259 keys on $C86C (LINK) or $DB73==0 (wild) ->",
        "; damage = target current HP - 1 (floor 1); otherwise (boss db73==1 AND",
        "; arena db73==2) -> (caster HP - 1)/2. Measured: HP200 -> 249 wild,",
        "; 99 boss (S78), 99 arena (S79). \"Arena\" in damage-layer forks means",
        "; the LINK flag throughout — same finding in WindBeastDamage_642b.",
    ],
    "WindBeastDamage_642b": [
        "; WindBeast (§15.5, validated): 3L+10 party / 1.5L enemy, cap 180;",
        "; +/- half the (mod-)remainder, sign from the shifted-out bit (exact",
        "; polarity per skill: simulator/damage.py). Same LINK-flag fork finding",
        "; as KamikazeDamage_6232.",
    ],
    "BattleActionMachine_6c4d": [
        "; ================ BATTLE ACTION MACHINE (bank $52 entry 0) ================",
        "; Battle phase $07 far-calls here (§15.7, S79): waits on the anim done-flag",
        "; $DA82, ticks bank $5F entry 5 (ld hl,$5f05/rst $10), then dispatches",
        "; state $D9ED through the 28-entry inline table BtlActStateTable_6c60",
        "; (states $00-$1B; the old ROADMAP knew 8). $DB77/$DB78 = the pending",
        "; actor/action pair; action codes >= ~$BA are META-actions (items/flee/",
        "; shift — e.g. the AI queues $E9 as a flee-class action), not skill ids.",
    ],
    "SkillHandlerDispatch_6cc7": [
        "; Skill-handler dispatch (§15.7): reached when bank $53 entry 0's setup",
        "; sub-machine signals $D9EE==$0B; reads the queued skill id and calls",
        "; through SkillFunctionTable ($4011, 222 entries).",
    ],
    "BtlActState2Apply_6d56": [
        "; ============ DAMAGE APPLY (action state 2) — §15.7, S79 ============",
        "; The real apply gate is descriptor $DD6F bit5. The cp ladder at $6D83",
        "; (ld a,[$db8a]...) is the id-override list — these SKIP the HP subtract:",
        ";   $1A RobMagic, $75 OddDance, $76 RobDance, $71 K.O.Dance, $94 Hustle,",
        ";   $12 Beat, $13 Defeat, and the sub-$3A status region except $37/$38;",
        ";   transformation specials $29/$AA/$D5 branch to their own states.",
        "; HP subtract floors at 0; result 0 or borrow -> KO state $1A ($D9F1=0).",
        "; Rig hook pattern: hit path BtlOutcomeHitPath_4200, miss",
        "; BtlOutcomeMissPath_4225 (TOOLS_AND_DATA §2.10).",
    ],
    "UpperStatCapCheck_6a13": [
        "; Upper stat-CAP helper (S79): compares target DEF x2-or-x4 — the cap",
        "; check for the Upper class. (The old ROADMAP breadcrumb calling",
        "; BattleFunc_6a13/6a49 \"likely flee/order checks\" was FALSIFIED S79.)",
    ],
    "AglUpStatCapCheck_6a49": [
        "; AglUp stat-CAP helper (S79): compares wBattleAGL x4 capped $01FF.",
        "; See UpperStatCapCheck_6a13 note (falsified flee/order breadcrumb).",
    ],
    "GroupVictimLoopA_71b5": [
        "; Group-skill execution loop (§15.10.6, S81): group skills never SELECT",
        "; a target — this loop steps the queue target byte per victim.",
        "; (patches/bank_052.asm: the S74 Earthquake sweep fork QSweepAfter52",
        ";  lives in this area of the PATCHED bank.)",
    ],
    "GroupVictimLoopB_71ed": [
        "; Second per-victim stepping point of the group-skill loop (§15.10.6).",
    ],
    "BtlOutcomeHitPath_4200": [
        "; Beat-outcome HIT path — rig hook waypoint (TOOLS_AND_DATA §2.10).",
    ],
    "BtlOutcomeMissPath_4225": [
        "; Beat-outcome MISS path — rig hook waypoint (TOOLS_AND_DATA §2.10).",
    ],
    "ConfusionActionRewrite_7ab5": [
        "; Confusion action rewrite (§15.7, S79): at a confused actor's turn",
        "; (+2 bit4), RNG1&3 indexes ConfusionActionTable_7aff {$3A,$5E,$62,$80}",
        "; and overwrites the queued action. The attack pick chooses a random",
        "; target with a cross-side wrap quirk: candidate&3==0 continues at",
        "; absolute slot 2 (b = own side base XOR 4 = OPPOSING side).",
    ],
}

# =========================================================================
# BANK $53 — per-actor setup gates + act-phase machine + status resolution
# =========================================================================

B53_RENAMES = {
    "LoadBtlC_4799": "TargetReResolve_4799",
    "jr_053_47e8": "DeadTargetRedirectScan_47e8",
    "ReadBtlC_4aeb": "SleepWakeRoll_4aeb",
    "LoadBtlC_4c50": "CurseSelfHit_4c50",
    "LoadBtlC_51aa": "BossProtectionGate_51aa",
}

B53_NEW_LABELS = {
    0x44CA: "BtlPerActorSetup_44ca",
    0x4558: "PerActorStatusGates_4558",
    0x51E8: "ActPhaseDispatch_51e8",
    0x670E: "SacrificeEntry_670e",
    0x67A9: "SacrificeResolve_67a9",
}

B53_LABEL_COMMENTS = {
    "BtlPerActorSetup_44ca": [
        "; ============ PER-ACTOR SETUP (bank $53 entry 0) — §15.7, S79 ============",
        "; Ticked by action state 0 (BtlActState0Setup_6c98); consumes the round",
        "; order list $DB79 with cursor $DB82 (skips dead actors). Own sub-machine",
        "; on $D9EE via the inline table SetupSubStateTable_44ce below.",
    ],
    "PerActorStatusGates_4558": [
        "; Per-actor gate order ($4558-$45C8, §15.7 S79): $DB07&$C0 -> forced",
        "; action $11; status +2 bit6 -> $13 (paralyzed); +2 bit7 -> the sleep",
        "; wake roll (SleepWakeRoll_4aeb); +5 bits0-5 one-shots -> actions",
        "; $12/$14/$15/$16/$17/$18; +2 bit5 curse roll (25%: RNG1<$40 ->",
        "; CurseSelfHit_4c50, can KO); +2 bit4 confusion ->",
        "; ConfusionActionRewrite_7ab5 (bank $52) rewrites the queued action.",
    ],
    "ActPhaseDispatch_51e8": [
        "; ========= ACT-PHASE DISPATCHER (bank $53 entry 5) — §15.10.6, S81 =========",
        "; 16-state machine on $D9EE via the inline table ActPhaseStateTable_51ec.",
        "; Sub-state 0 (ActPhaseState0TargetFetch_520c) performs act-time target",
        "; resolution; TargetReResolve_4799 resets the queue target byte to $FF",
        "; (phase $19) — the observed act-time \"$FF flip\".",
    ],
    "ActPhaseState0TargetFetch_520c": [
        "; Act-time target fetch (§15.10.6, S81; call path corrected S83):",
        "; increments $DD69, clears $DD6E, copies the queue target byte",
        "; $DCED+2*[$db88] -> $DB89; iff $FF, far-calls BANK $58 ENTRY 8",
        "; (ld hl,$5808 — BtlQueueFetchService_5498, which dispatches per-skill",
        "; via BtlSkillTargetDispatch_401d) and re-reads until != $FF.",
        "; The concrete-slot RNG resolver itself is TargetSlotResolver_6379",
        "; (bank $58 dw slot 4). §15.10.6's \"far-calls entry 4\" was the doc",
        "; error corrected S83 (DOC_AUDIT).",
    ],
    "TargetReResolve_4799": [
        "; Re-resolve trigger (§15.10.6, S81): resets the queue target byte to",
        "; $FF and re-enters resolution (phase $19).",
    ],
    "DeadTargetRedirectScan_47e8": [
        "; Dead-target redirect at act time (§15.10.6, S81): first-valid-on-side",
        "; scan ($47E8 -> $47FB). Path conditional; NOT exercised in the S81",
        "; probes. ($53:$47D1 just above far-calls bank $58 entry 8 — the same",
        "; per-skill resolution service as sub-state 0.)",
    ],
    "SleepWakeRoll_4aeb": [
        "; Sleep wake roll (§15.8, S79 — EXACT; simulator/status.py ports this",
        "; routine): at the sleeper's own turn, wake iff RNG1 <= threshold by",
        "; 2-bit counter {3:$60=37.9%, 2:$A0=62.9%, 1:$E0=88.0%, 0:always}; else",
        "; the counter decrements (floor 0) and the turn becomes the \"asleep\"",
        "; action $0F. No RNG step consumed.",
    ],
    "CurseSelfHit_4c50": [
        "; Curse self-hit (bank $53 entry 2; §15.7): reached on the 25% curse",
        "; roll (RNG1<$40) at the actor's turn; can KO. Magnitude NOT yet",
        "; traced (§15.9 residual).",
    ],
    "BossProtectionGate_51aa": [
        "; ======== BOSS PROTECTION GATE (bank $53 entry $10) — §15.4, S78 ========",
        "; Byte-verified ladder (S83): skip iff LINK ($C86C != 0); skip iff the",
        "; target side is party ($DB89 < 4); skip iff $DB73 != 1 (battle type:",
        "; wild 0 / boss+scripted 1 / arena+wScriptMapType-$5D 2, set by",
        "; LoadBtlS_43c9 in bank $51; $FF = loss freeze). Then the skill ladder",
        "; {$12 Beat, $13 Defeat, $14 Sacrifice, $3E Kamikaze, $69 Paralyze,",
        ";  $6B, $71 K.O.Dance} AUTO-FAILS vs enemy targets — instant death and",
        "; paralysis never work on bosses, and DO work on wild monsters",
        "; (validated both ways S78; the rig's $DA09=1 makes rig battles \"boss\" —",
        ";  poke db73=0 to reproduce the wild condition).",
    ],
    "SacrificeEntry_670e": [
        "; Sacrifice entry (bank $53 entry $0D): action state 3 routes Sacrifice",
        "; here (§15.7, S79).",
    ],
    "SacrificeResolve_67a9": [
        "; Sacrifice resolution (§15.5, S78/S79 — validated 4/4 branches): boss",
        "; gate; res 14 (packed low pair of $DD2B+slot*7): 3=immune, 2=works only",
        "; if RNG1<$C0; then RNG2<$7F (49.6%) -> damage = target CURRENT HP",
        "; (kill, msg $E9) else HP - max(HP/100,1) (~1% survivor, msg $82).",
        "; $2FE8 returns CURRENT HP, not max (measured S79: 180/250 -> kill 180,",
        "; survivor 179). Consumes NO RNG steps (reads the ambient state).",
        "; Caster dies in the state chain. Rig hooks: roll $67DB, out $684E.",
    ],
}

# =========================================================================
# BANK $58 — turn order + queue fetch / per-skill target dispatch
# =========================================================================

B58_RENAMES = {
    "SaveBtlFX_5662": "TurnOrderKeyRoll_5662",
    "jr_058_55c2": "TurnOrderSort_55c2",
    "Jump_058_5707": "TurnOrderCompact_5707",
    "SetBtlFX_56cf": "TurnOrderDefensiveBoost_56cf",
    "LoadBtlFX_5498": "BtlQueueFetchService_5498",
}

B58_NEW_LABELS = {
    0x54CE: "QueuePlainAttack_54ce",
    0x54D1: "TurnOrderBuild_54d1",
    0x6367: "TargetSelfWrite_6367",
    0x6379: "TargetSlotResolver_6379",
    0x67BA: "AICat1AttackScore_67ba",
    0x57C5: "AnnounceTemplateLookup_57c5",
}

B58_LABEL_COMMENTS = {
    "QueuePlainAttack_54ce": [
        "; Tiny helper: [hl] := $3A (queue plain Attack). Byte-read S83.",
    ],
    "TurnOrderBuild_54d1": [
        "; ================= TURN ORDER BUILD — §15.6, S79 =================",
        "; Built each round by battle phase $05 after the enemy-AI queue fill;",
        "; validated 143/143 over 47 rounds (simulator/turn_order.py,",
        "; validate_order.py, s79_order_events.json; rig measure_order.py hooks",
        "; $54D1/$5662/$55C2/$5707). Init (byte-verified S83): $DB79 and $DB4C",
        "; filled 9x$FF, $DB61 16x0, $DB82/$DB55 zeroed. For each combatant with",
        "; $DD13[slot]==2 (command queued; 1 = no-action marker, set by the bank",
        "; $50 committers), in slot order: one GenerateRNG step ($00:$12D0), then",
        "; TurnOrderKeyRoll_5662. Keys land in $DB61 (8xu16) with ids in $DB4C,",
        "; sorted by TurnOrderSort_55c2, compacted into $DB79 by",
        "; TurnOrderCompact_5707 — the round order list, consumed by bank $53",
        "; entry 0 with cursor $DB82 (skips dead actors).",
        "; Link peer sentinel: id $10, key $0200, appended when $DB77 != $FF.",
    ],
    "TurnOrderKeyRoll_5662": [
        "; Per-combatant AGL key roll (§15.6, exact):",
        ";   agl  = max(AGL16, 1)",
        ";   span = 1 + agl/4 + agl/16          (~31% of AGL)",
        ";   rand = ((RNG2 & 3) << 8) | RNG1    (10-bit, post-step)",
        ";   key  = agl - span + (rand mod' span)",
        "; mod' = repeated subtraction with an exit-on-EQUAL quirk (result range",
        "; INCLUSIVE [0, span]). Floor: key < 2 -> 2. $55 SquallHit gets +$0200",
        "; here (+$0200 more in the main loop = +$0400 total, \"strikes first\");",
        "; $56 PsycheUp forces key $0001 (always last); defensive interceptions",
        "; get +$0600 via TurnOrderDefensiveBoost_56cf.",
    ],
    "TurnOrderDefensiveBoost_56cf": [
        "; +$0600 for queued actions in {$2A Ironize, $7F Imitate, $88 Cover,",
        "; $89 Guardian, $8C Dodge, $8D Defence, $8E StrongD, $8F SuckAll,",
        "; $90 BladeD, $DC IRONIZE} — defensive interceptions always resolve",
        "; first (§15.6).",
    ],
    "TurnOrderSort_55c2": [
        "; Descending shrinking-bound bubble sort over $DB61 keys / $DB4C ids",
        "; (§15.6): TIES SWAP, and pass 1 literally compares a 9th out-of-bounds",
        "; pair $DB71/$DB72+$DB54 — modelled verbatim in turn_order.py. Ties net",
        "; to slot order in practice (party before enemy at equal keys, measured).",
    ],
    "TurnOrderCompact_5707": [
        "; Compacts sorted ids into $DB79 — the round order list (§15.6).",
    ],
    "BtlQueueFetchService_5498": [
        "; ========= QUEUE FETCH / PER-SKILL DISPATCH (bank $58 entry 8) =========",
        "; Byte-verified S83 (corrects §15.10.6's \"entry 4\" call-path claim —",
        "; DOC_AUDIT S83): act states >= $16 fetch the queue TARGET byte",
        "; ($DCED+2*idx) and invalidate it to $FF; earlier states fetch the",
        "; queued SKILL ($DCEC+2*idx) into $DB8A, then dispatch",
        "; BtlSkillTargetDispatch_401d[skill] — the per-skill target-resolution",
        "; service table. Called from bank $53 sub-state 0",
        "; (ActPhaseState0TargetFetch_520c) and from $53:$47D1.",
    ],
    "TargetSelfWrite_6367": [
        "; Per-skill target service: queue target := the actor's own index",
        "; ($DCED+2*[$db88] := [$db88]; byte-read S83) — the self-target writer",
        "; (23 skills dispatch here via BtlSkillTargetDispatch_401d).",
    ],
    "TargetSlotResolver_6379": [
        "; ========== CONCRETE-SLOT TARGET RESOLVER (dw slot 4) — §15.10.6 ==========",
        "; S81, measured: RNG-slot fishing over CheckMonsterSlot ($00:$2FA5,",
        "; CF SET = NOT live) validity — try RNG1&7, then RNG2&7, then",
        "; (RNG1|RNG2)&7, then further mixes, then a decrementing scan from RNG2",
        "; until a valid slot answers; the slot is written to $DCED+idx*2.",
        "; OPEN (§15.10.6): NO side filter in this code — either $DD1B is",
        "; side-masked around resolution or another constraint applies; one",
        "; probe outstanding. BREADCRUMB (byte-verified S83): $50:$4C87 far-calls",
        "; bank $58 entry 4 directly (ld hl,$5804/rst $10) — candidate for the",
        "; OPEN post-commit target write site; NOT yet measured.",
    ],
    "AICat1AttackScore_67ba": [
        "; Cat-1 plain-attack comparison service (bank $58 entry 11; §15.10.6,",
        "; S80/S81): called by the bank-$57 pick epilogue when category 1 wins;",
        "; returns a plain-attack score via $DD26 — if >= the best skill score,",
        "; the AI queues plain Attack $3A. (S79's \"bank $58\" attribution for the",
        "; whole AI machine was imprecise — only THIS service lives here.)",
    ],
    "AnnounceTemplateLookup_57c5": [
        "; [S2d] Announce-template lookup (bank $58 entry 6): $db4c := announce",
        "; msgid for the queued skill (a = [AnnounceTemplateTable + skill_id]),",
        "; rendered by bank $50 entry 7. See the S2d arc notes in this bank.",
    ],
}

# Semantic comments for the 14 rst $10 service slots of bank $58.
B58_SERVICE_NOTES = {
    2: "ClrBtlFX_5955",
    4: "TargetSlotResolver_6379 — concrete-slot RNG resolver (see label)",
    5: "LoadBtlFX_642c",
    6: "AnnounceTemplateLookup_57c5 — announce msgid for queued skill (S2d)",
    8: "BtlQueueFetchService_5498 — queue fetch + per-skill dispatch (S83)",
    9: "MeatFeedHandler ($591E): the meat-item ($C2-$C6) recruitment-boost "
       "effect (call $5c0b -> result; msg table $5937). Routed here from "
       "$52:$4014. (S2 arc)",
    10: "$41E9 — also the per-skill service for plain Attack $3A (byte-read S83)",
    11: "AICat1AttackScore_67ba — cat-1 plain-attack score service (§15.10.6)",
}

# =========================================================================
# Bank configs
# =========================================================================

BANKS = {
    0x52: dict(renames=B52_RENAMES, new_labels=B52_NEW_LABELS,
               comments=B52_LABEL_COMMENTS, marker="BtlActStateTable_6c60:"),
    0x53: dict(renames=B53_RENAMES, new_labels=B53_NEW_LABELS,
               comments=B53_LABEL_COMMENTS, marker="ActPhaseStateTable_51ec:"),
    0x58: dict(renames=B58_RENAMES, new_labels=B58_NEW_LABELS,
               comments=B58_LABEL_COMMENTS, marker="BtlSkillTargetDispatch_401d:"),
}

# =========================================================================
# Mechanics (S82 technique: probe build, sym census, descending splices)
# =========================================================================

def bank_asm(bank):
    return os.path.join(DIS, f"bank_{bank:03x}.asm")


def rom_bytes(bank, start, end):
    d = open(ROM, "rb").read()
    off = bank * 0x4000 + (start - 0x4000)
    return d[off:off + (end - start)]


def dw_at(bank, addr, n):
    b = rom_bytes(bank, addr, addr + 2 * n)
    return list(struct.unpack(f"<{n}H", b))


def _clean_build_artifacts():
    for f in ("game.o", "game.gbc", "game.sym", "game.map"):
        p = os.path.join(DIS, f)
        if os.path.exists(p):
            os.remove(p)


def probe_build(bank, lines):
    """Insert zero-byte probe labels into this bank's file, build once,
    return (line->addr map, addr->existing-label map from game.sym)."""
    asm = bank_asm(bank)
    probed, probe_of = [], {}
    for i, l in enumerate(lines):
        s = l.strip()
        if s and not s.startswith(";") and not (s.endswith(":") and " " not in s):
            probed.append(f"Lprobe_{i}:")
            probe_of[f"Lprobe_{i}"] = i
        probed.append(l)
    backup = asm + ".probebak"
    shutil.copy(asm, backup)
    try:
        open(asm, "w").write("\n".join(probed) + "\n")
        _clean_build_artifacts()
        r = subprocess.run("make", cwd=DIS, shell=True, capture_output=True, text=True)
        if not os.path.exists(os.path.join(DIS, "game.gbc")):
            sys.exit(f"probe build failed (bank {bank:02x}):\n" + r.stdout + r.stderr)
        md5 = hashlib.md5(open(os.path.join(DIS, "game.gbc"), "rb").read()).hexdigest()
        if md5 != ORIGINAL_MD5:
            sys.exit(f"probe build not byte-perfect ({md5}); aborting.")
        sym = open(os.path.join(DIS, "game.sym")).read()
    finally:
        shutil.move(backup, asm)
    line_addr, existing = {}, {}
    for line in sym.splitlines():
        m = re.match(rf"^{bank:02x}:([0-9a-fA-F]{{4}}) (\S+)", line, re.I)
        if not m:
            continue
        a, name = int(m.group(1), 16), m.group(2)
        if name.startswith("Lprobe_"):
            line_addr[probe_of[name]] = a
        else:
            existing.setdefault(a, name)
    return line_addr, existing


def span_for_range(line_addr, start, end, what):
    in_range = [ln for ln, a in line_addr.items() if start <= a < end]
    if not in_range:
        sys.exit(f"no source lines map into [${start:04x},${end:04x}) for {what}")
    return min(in_range), max(in_range) + 1


def label_for(bank, addr, existing, renames, new_labels, neutral_prefix):
    """Best display for a dw target: renamed existing label, new label,
    or a raw $hex (byte-identical either way)."""
    if addr in new_labels:
        return new_labels[addr]
    if addr in existing:
        name = existing[addr]
        return renames.get(name, name)
    if neutral_prefix is None:
        return f"${addr:04X}"
    return None  # caller decides (may create a neutral label)


def skill_names():
    p = os.path.join(REPO, "extracted", "skill_records.json")
    recs = json.load(open(p))["records"]
    out = {}
    for r in recs:
        i = r.get("id")
        if i is not None:
            out[i] = r.get("name", "").strip() or f"skill_{i:02X}"
    return out


# ---------------- per-bank structural op builders ----------------

def ops_bank52(lines, line_addr, existing, cfg):
    ops, extra_labels = [], {}
    renames, new_labels = cfg["renames"], cfg["new_labels"]

    # A) action-state table $6C60 (28 dw), ends at state-0 code $6C98
    states = dw_at(0x52, 0x6C60, 28)
    assert states[0] == 0x6C98 and states[7] == 0x7227, "state table bytes moved?!"
    # give boundary-aligned unknown targets a neutral label
    addr_line = {}
    for ln, a in line_addr.items():
        addr_line.setdefault(a, ln)
    for t in sorted(set(states)):
        if t in new_labels or t in existing:
            continue
        if t in addr_line:
            extra_labels[t] = f"BtlActState_{t:04x}"
    def tgt52(a):
        return (new_labels.get(a) or extra_labels.get(a)
                or (renames.get(existing[a], existing[a]) if a in existing else f"${a:04X}"))
    s, e = span_for_range(line_addr, 0x6C60, 0x6C98, "action-state table")
    block = [
        "; 28-entry action-state dispatch table on $D9ED (states $00-$1B) — §15.7",
        "; (S79; converted from misassembled instructions S83, byte-verified).",
        "BtlActStateTable_6c60:",
    ]
    for i, t in enumerate(states):
        note = B52_STATE_NOTES.get(i)
        block.append(f"    dw {tgt52(t)} ; {note if note else f'state ${i:02X}'}")
    ops.append((s, e, block))

    # B) confusion action table $7AFF (4 db)
    tb = rom_bytes(0x52, 0x7AFF, 0x7B03)
    assert tb == bytes([0x3A, 0x5E, 0x62, 0x80]), "confusion table bytes moved?!"
    s, e = span_for_range(line_addr, 0x7AFF, 0x7B03, "confusion table")
    ops.append((s, e, [
        "; Confusion action table (§15.7): RNG1&3 -> {Attack $3A, $5E, $62, $80}.",
        "ConfusionActionTable_7aff:",
        "    db $3a, $5e, $62, $80",
    ]))
    return ops, extra_labels, [("$7aff", "ConfusionActionTable_7aff")]


def ops_bank53(lines, line_addr, existing, cfg):
    ops, extra_labels = [], {}
    renames, new_labels = cfg["renames"], cfg["new_labels"]
    addr_line = {}
    for ln, a in line_addr.items():
        addr_line.setdefault(a, ln)

    # C) setup sub-state table $44CE (9 dw), ends at $44E0
    subs = dw_at(0x53, 0x44CE, 9)
    assert subs[0] == 0x44E0, "setup sub table bytes moved?!"
    for i, t in enumerate(sorted(set(subs))):
        if t not in existing and t not in new_labels and t in addr_line:
            extra_labels[t] = f"SetupSub_{t:04x}"
    def tgt(a):
        return (new_labels.get(a) or extra_labels.get(a)
                or (renames.get(existing[a], existing[a]) if a in existing else f"${a:04X}"))
    s, e = span_for_range(line_addr, 0x44CE, 0x44E0, "setup sub-state table")
    block = [
        "; 9-entry setup sub-state dispatch table on $D9EE — §15.7 (S79; converted",
        "; from misassembled instructions S83, byte-verified).",
        "SetupSubStateTable_44ce:",
    ]
    for i, t in enumerate(subs):
        block.append(f"    dw {tgt(t)} ; sub-state {i}")
    ops.append((s, e, block))

    # D) act-phase state table $51EC (16 dw), ends at $520C
    acts = dw_at(0x53, 0x51EC, 16)
    assert acts[0] == 0x520C and acts[15] == 0x5B07, "act-phase table bytes moved?!"
    new_labels[0x520C] = "ActPhaseState0TargetFetch_520c"
    for t in sorted(set(acts)):
        if t not in existing and t not in new_labels and t in addr_line:
            extra_labels[t] = f"ActPhaseState_{t:04x}"
    s, e = span_for_range(line_addr, 0x51EC, 0x520C, "act-phase state table")
    block = [
        "; 16-state act-phase dispatch table on $D9EE — §15.10.6 (S81; converted",
        "; from misassembled instructions S83, byte-verified).",
        "ActPhaseStateTable_51ec:",
    ]
    for i, t in enumerate(acts):
        block.append(f"    dw {tgt(t)} ; act state ${i:X}")
    ops.append((s, e, block))
    return ops, extra_labels, []


def ops_bank58(lines, line_addr, existing, cfg):
    ops, extra_labels = [], {}
    renames, new_labels = cfg["renames"], cfg["new_labels"]

    # E) head dw region $4001..$41E9: 14 service slots + 230 per-skill slots
    slots = dw_at(0x58, 0x4001, 244)
    assert slots[4] == 0x6379 and slots[8] == 0x5498 and slots[11] == 0x67BA, \
        "bank 58 service slots moved?!"
    names = skill_names()
    def tgt(a):
        if a in new_labels:
            return new_labels[a]
        if a in existing:
            name = existing[a]
            return renames.get(name, name)
        return f"${a:04X}"
    s, e = span_for_range(line_addr, 0x4001, 0x41E9, "bank 58 dispatch tables")
    block = [
        "; Cross-bank rst $10 service table (slots 0-13). Called via",
        "; ld hl,$58<entry>/rst $10 — the handler computes $4001 + 2*L, so L IS",
        "; the entry index (ARCHITECTURE.md; byte-verified S83 at $00:$0020).",
    ]
    for i in range(14):
        note = B58_SERVICE_NOTES.get(i)
        block.append(f"    dw {tgt(slots[i])} ; Entry {i}"
                     + (f" — {note}" if note and not note.startswith(tgt(slots[i])) else
                        (f" — {note.split(' — ',1)[1]}" if note and ' — ' in note else "")))
    block += [
        "",
        "; ====== PER-SKILL TARGET-RESOLUTION DISPATCH TABLE (230 dw) — S83 ======",
        "; Indexed by skill id ($00-$E5) from BtlQueueFetchService_5498",
        "; (hl = $401D + 2*skill; call $0008). Determines how each skill's queue",
        "; target byte gets resolved at act time: TargetSelfWrite_6367 = self,",
        "; TargetSlotResolver_6379 = concrete-slot RNG fishing, $62BF/$63D6/etc =",
        "; further services (semantics unlabeled — only byte-verified structure",
        "; here; behavioral claims stay measured-only per S70 rule).",
        "BtlSkillTargetDispatch_401d:",
    ]
    for i in range(14, 244):
        sid = i - 14
        nm = names.get(sid, "")
        block.append(f"    dw {tgt(slots[i])} ; [${sid:02X}] {nm}".rstrip())
    ops.append((s, e, block))
    return ops, extra_labels, [("$401d", "BtlSkillTargetDispatch_401d")]


OPS_BUILDERS = {0x52: ops_bank52, 0x53: ops_bank53, 0x58: ops_bank58}


# ---------------- generic apply ----------------

def scan_rename_targets(bank, renames):
    files = [os.path.join(DIS, f) for f in sorted(os.listdir(DIS)) if f.endswith(".asm")]
    pdir = os.path.join(REPO, "patches")
    files += [os.path.join(pdir, f) for f in sorted(os.listdir(pdir)) if f.endswith(".asm")]
    hits = []
    for path in files:
        if os.path.basename(path) == f"bank_{bank:03x}.asm" and path.startswith(DIS):
            continue
        t = open(path).read()
        for old, new in renames.items():
            if re.search(rf"^{re.escape(new)}:", t, re.M):
                sys.exit(f"rename collision: {new} already DEFINED in {path}")
            if re.search(rf"\b{re.escape(old)}\b", t):
                hits.append((path, old))
    return hits


def apply_bank(bank, analyze=False):
    cfg = BANKS[bank]
    asm = bank_asm(bank)
    text = open(asm).read()
    if cfg["marker"] in text:
        print(f"bank {bank:02x}: already applied (marker present) — skipping.")
        return []
    lines = text.splitlines()
    line_addr, existing = probe_build(bank, lines)
    addr_line = {}
    for ln, a in line_addr.items():
        addr_line.setdefault(a, ln)

    renames, new_labels = cfg["renames"], dict(cfg["new_labels"])
    cfg2 = dict(cfg); cfg2["new_labels"] = new_labels

    # sanity: every rename source must exist at its address-suffix addr
    for old in renames:
        if not re.search(rf"^{re.escape(old)}:", text, re.M):
            sys.exit(f"bank {bank:02x}: rename source {old} not found")

    struct_ops, extra_labels, ref_fixes = OPS_BUILDERS[bank](lines, line_addr, existing, cfg2)
    all_new = dict(new_labels); all_new.update(extra_labels)

    # every new label must sit on a line boundary
    missing = [a for a in all_new if a not in addr_line]
    if missing:
        sys.exit(f"bank {bank:02x}: no line boundary for " +
                 ", ".join(f"${a:04x}({all_new[a]})" for a in missing))
    # no existing label may collide with a new label's address... (co-labels
    # are fine — rgbasm allows two labels on one address as separate lines —
    # but identical NAMES are not; checked in scan_rename_targets + here)
    for a, n in all_new.items():
        if re.search(rf"^{re.escape(n)}:", text, re.M):
            sys.exit(f"bank {bank:02x}: new label {n} already present")

    if analyze:
        print(f"bank {bank:02x}: {len(renames)} renames, {len(all_new)} new labels, "
              f"{len(struct_ops)} table regions, refs OK; boundaries all OK")
        return []

    ext = scan_rename_targets(bank, renames)
    for path, old in ext:
        print(f"  note: {old} referenced in {os.path.relpath(path, REPO)} — renaming there too")

    # 1) renames in-memory
    def do_renames(s):
        for old, new in renames.items():
            s = re.sub(rf"\b{re.escape(old)}\b", new, s)
        return s
    lines = [do_renames(l) for l in lines]

    # 2) raw-pointer reference labelization (byte-identical)
    for raw, lab in ref_fixes:
        pat = re.compile(rf"(ld hl, ){re.escape(raw)}\b")
        lines = [pat.sub(rf"\g<1>{lab}", l) for l in lines]

    # 3) structural ops + label insertions + label comments (descending)
    ops = list(struct_ops)
    covered = set()
    for s, e, _ in struct_ops:
        covered.update(range(s, e))
    for a, name in sorted(all_new.items()):
        ln = addr_line[a]
        if ln in covered:
            continue  # label emitted by a table block
        ins = list(cfg["comments"].get(name, [])) + [f"{name}:"]
        ops.append((ln, ln + 1, ins + [lines[ln]]))

    label_line = {}
    for i, l in enumerate(lines):
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", l)
        if m:
            label_line[m.group(1)] = i
    for name, comment in cfg["comments"].items():
        if name in all_new.values():
            continue
        if name not in label_line:
            sys.exit(f"bank {bank:02x}: comment target {name} not found after rename")
        ln = label_line[name]
        ops.append((ln, ln + 1, comment + [lines[ln]]))

    ops.sort(key=lambda o: o[0], reverse=True)
    prev = None
    for s, e, _ in ops:
        if prev is not None and e > prev:
            sys.exit(f"bank {bank:02x}: overlapping ops at {s}..{e} vs {prev}")
        prev = s
    for s, e, repl in ops:
        lines[s:e] = repl
    open(asm, "w").write("\n".join(lines) + "\n")

    # 4) propagate renames to every other file that referenced them
    for path in sorted(set(p for p, _ in ext)):
        t = open(path).read()
        open(path, "w").write(do_renames(t))
    return [os.path.relpath(p, REPO) for p, _ in ext]


def final_build():
    _clean_build_artifacts()
    r = subprocess.run("make", cwd=DIS, shell=True, capture_output=True, text=True)
    if not os.path.exists(os.path.join(DIS, "game.gbc")):
        sys.exit("final build failed:\n" + r.stdout + r.stderr)
    md5 = hashlib.md5(open(os.path.join(DIS, "game.gbc"), "rb").read()).hexdigest()
    if md5 != ORIGINAL_MD5:
        sys.exit(f"FINAL BUILD NOT BYTE-PERFECT ({md5}) — inspect before committing!")
    print(f"final build byte-perfect ({md5})")


if __name__ == "__main__":
    analyze = "--analyze" in sys.argv
    banks = [0x52, 0x53, 0x58]
    if "--bank" in sys.argv:
        banks = [int(sys.argv[sys.argv.index("--bank") + 1], 16)]
    touched = []
    for b in banks:
        touched += apply_bank(b, analyze=analyze)
    if not analyze:
        final_build()
        if touched:
            print("also modified:", sorted(set(touched)))
