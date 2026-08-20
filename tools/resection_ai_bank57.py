#!/usr/bin/env python3
"""
resection_ai_bank57.py — S82 annotation catch-up for the bank-$57 enemy-AI
decision machine (Iron Rule 6). LABELS/COMMENTS/DATA-RESECTION ONLY — zero
byte impact; both the probe build and the final build are asserted against
the original MD5. Idempotent: exits cleanly if already applied.

What it does (knowledge source: BATTLE_SKILL_SYSTEM §15.10 + S80/S81
corpora — transcription of validated findings, not re-derivation):

  1. Converts the two misassembled data regions to commented dw lists:
     - AIStateDispatchTable_6e12: 8 dw inline after the `rst $00` dispatch
       on $D9EE (states 0-7).
     - AIRuleChainIndex_4302 (3 dw) + the three $0000-terminated
       per-category rule chains: $4308 cat1/dmg 39 rules, $4358 cat2/status
       85 rules (S81 docs said 61 — miscount, byte-verified S82),
       $4404 cat3/heal 40 rules. 131 unique routines, 27 shared.
  2. Labels all 131 rule entry points (semantic names + provenance comments
     for the S81-measured rules; neutral AIRule_<addr> otherwise).
  3. Renames stage/helper auto-labels to semantic names (address suffix
     retained) and updates every reference in disassembly/ + patches/.
  4. Adds the $4E36 vanilla-bug comment, the walker/veto/adder comments,
     and corrects the inverted CF comment on CheckMonsterSlot ($00:$2FA5):
     CF SET = NOT a live monster (byte-verified S82; old comment said
     CF=valid).

Mechanism: zero-byte probe labels + one build; line addresses read from
game.sym (the resection_library_tables.py technique — no opcode-size
summing, which bit Session 22).

NOTE ON RULE BODIES: rule *internals* frequently embed inline `rst $00`
jump tables; mgbdis desynced inside many bodies and re-synced by the next
rule head (all 131 heads land on source-line boundaries — probe-verified).
Body re-emission is out of S82 scope and tracked in ROADMAP.

Usage:
    python3 tools/resection_ai_bank57.py --analyze   # report only
    python3 tools/resection_ai_bank57.py             # apply (idempotent)
"""
import hashlib
import os
import re
import shutil
import struct
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIS = os.path.join(REPO, "disassembly")
ASM = os.path.join(DIS, "bank_057.asm")
ASM0 = os.path.join(DIS, "bank_000.asm")
ROM = os.path.join(REPO, "data", "DWM-original.gbc")
BANK = 0x57
ORIGINAL_MD5 = "1ca6579359f21d8e27b446f865bf6b83"

CHAIN_INDEX = 0x4302
CHAIN_BASES = (0x4308, 0x4358, 0x4404)
STATE_HANDLERS = (0x6E2A, 0x7129, 0x73B9, 0x7529, 0x7439, 0x75A2, 0x7859, 0x7865)
APPLIED_MARKER = "AIRuleChainIndex_4302:"

# ---------------- semantic rule names + one-line comments ----------------
# Provenance: (S81 sweep) = measured in the 160-skill sweep corpus
# (simulator/ai_rules.py, validate_rules.py 240/240); (S82 bytes) =
# byte-verified this session via sm83dis; (S80) = §15.10 trace.
RULE_NAMES = {
    0x45F2: ("AIRuleVetoUsability_45f2",
        ["; Universal usability veto: MP cost > CurMP, or record flags7 bit6/5/4",
         "; vs caster status+3 seal bits $01/$40/$80. (S81 sweep)"]),
    0x4702: ("AIRuleVetoHeavyDotRedundant_4702",
        ["; Veto when ALL live opposing targets already have status+2 & $02 —",
         "; heavy-DoT trio PoisonHit/PoisonGas/PoisonAir $67/$6C/$6D. (S81 sweep)"]),
    0x4725: ("AIRuleVetoPoisonRedundant_4725",
        ["; Veto when all live opposing targets have status+2 & $03 — PoisonHit $67 /",
         "; PoisonGas $6C (self-selects, S82 bytes). (S81 sweep)"]),
    0x4745: ("AIRuleVetoSleepRedundant_4745",
        ["; Veto when all live opposing targets have status+2 & $8C — the sleep/",
         "; incap class (Sleep/SleepAll/Ironize/NapAttack/dances/...). (S81 sweep)"]),
    0x6267: ("AIRuleVetoIncapRedundant_6267",
        ["; Veto when all live opposing targets have status+2 & $CC — don't",
         "; incapacitate the incapacitated. (S81 sweep)"]),
    0x5D4D: ("AIRuleVetoSupportNeedsAlly_5d4d",
        ["; Support class (Sacrifice/Vivify/Revive/Farewell/NumbOff/DeChaos/Cover/",
         "; Guardian/LifeSong/LifeDance): veto when own valid slots ($DD1B != $FF)",
         "; < 2 — the whole class is dead for a solo actor. (S81 sweep)"]),
    0x67B1: ("AIRuleVetoReviveNeedsDead_67b1",
        ["; Vivify/Revive/LifeSong: veto unless an own-side PROCESSED-dead ally",
         "; exists ($DD1B==1; silent HP=0 pokes don't count). (S81 sweep)"]),
    0x4F2E: ("AIRuleCureAntidote_4f2e",
        ["; Antidote $33: +15 if any live own-side status+2 & $01, veto otherwise.",
         "; Symmetric cure rule family (S81 sweep; skill select S82 bytes)."]),
    0x4F61: ("AIRuleCureNumbOff_4f61",
        ["; NumbOff $34: +15 if any live own-side status+2 & $40, veto otherwise. (S81 sweep)"]),
    0x4F94: ("AIRuleCureDeChaos_4f94",
        ["; DeChaos $35: +15 if any live own-side status+2 & $10, veto otherwise. (S81 sweep)"]),
    0x4FB3: ("AIRuleCureCurseOff_4fb3",
        ["; CurseOff $36: +15 if any live own-side status+2 & $20, veto otherwise. (S81 sweep)"]),
    0x49B7: ("AIRuleVetoHealUnhurt_49b7",
        ["; Heal class: veto when no live own-side member has CurHP < MaxHP. (S81 sweep)"]),
    0x4FD2: ("AIRuleHealSelfBonus_4fd2",
        ["; +5 single-target self heal. Heal incentives cap at +20 total = the",
         "; cat3 weak-heal threshold $14 (§15.10.6). (S81 sweep)"]),
    0x5149: ("AIRuleHealAllyBonus_5149",
        ["; +5 single-target ally heal. (S81 sweep)"]),
    0x502C: ("AIRuleHealBroadBonusA_502c",
        ["; +15 broad heal. (S81 sweep)"]),
    0x51DA: ("AIRuleHealBroadBonusB_51da",
        ["; +15 broad heal. (S81 sweep)"]),
    0x5D16: ("AIRuleSurgeCleanseA_5d16",
        ["; Surge $81: veto unless own side carries any status (+2 nonzero or",
         "; +3 & $C3); +15 otherwise (veto measured; +15 presumed, §15.9).",
         "; Near-identical twin: AIRuleSurgeCleanseB_67d5. (S81)"]),
    0x67D5: ("AIRuleSurgeCleanseB_67d5",
        ["; Surge $81 twin of AIRuleSurgeCleanseA_5d16 (identical prologue,",
         "; S82 bytes) — one per chain placement. (S81)"]),
    0x6AB4: ("AIRuleVetoRobMpFull_6ab4",
        ["; Rob class (RobMagic/TakeMagic/RobDance): veto when caster MP full. (S81 sweep)"]),
    0x4ACC: ("AIRuleSuckAir_4acc",
        ["; SuckAir $43 rule — clean-board veto measured in aggregate; semantics",
         "; presumed to follow the Rob class (§15.9 residual). (S81)"]),
    0x6848: ("AIRuleVetoFamilyCutNoTarget_6848",
        ["; Family cuts (MetalCut..CleanCut $48-$4E, Smashlime/Sheldodge/Branching",
         "; $D6-$D8): veto when no live opposing target of the matching family;",
         "; MetalCut keys on $DB8B bit0 (metal body). Per-skill handlers via an",
         "; inline rst $00 table (decode trap: KEY_LESSONS S81 off-by-one).",
         "; Bonus twin: AIRuleFamilyCutBonus_4c41. (S81 sweep)"]),
    0x4C41: ("AIRuleFamilyCutBonus_4c41",
        ["; +20 when a live opposing target matches the cut's family (DrakSlash 1,",
         "; BeastCut 2, BirdBlow 3, DevilCut 6, ZombieCut 7, CleanCut 8=MATERIAL,",
         "; Smashlime 0=Slime, Sheldodge 5, Branching 4; MetalCut $DB8B bit0).",
         "; Also routes skills $3F/$40 to a $4D29 sub-branch (untraced, S82 bytes).",
         "; Inline rst $00 handler table. (S81 sweep)"]),
    0x4BCC: ("AIRuleElementBonus_4bcc",
        ["; Element-aware +20: record field +5 element vs each live opposing",
         "; target's 2-bit resistance (far-call bank $52 entry 6 via rst $10);",
         "; withheld iff the resist sum > live target count. (S81 sweep)"]),
    0x4D56: ("AIRulePhysSpecialBonus_4d56",
        ["; +15 physical-special class (TwinSlash/Beserker/HighJump/elemental",
         "; slashes/BiAttack/QuadHits/SquallHit/...); no off-condition observed on",
         "; any swept board. (S81 sweep)"]),
    0x4DF9: ("AIRulePsycheUpCond_4df9",
        ["; +5 PsycheUp — fired for FloraMan (EID 35) but not forced-Gremlin;",
         "; condition untraced (§15.9 residual). (S81)"]),
    0x4E18: ("AIRuleCasterProfile_4e18",
        ["; Spell bonus from caster profile: +10 iff CurMP < MaxMP/2, +10 iff",
         "; MaxMP >= MaxHP — pinned by the S81 4-point MP matrix.",
         "; (The S81 wrong-bank sm83dis trap was caught decoding THIS rule's",
         ";  helper — KEY_LESSONS S81.)"]),
    0x4E36: ("AIRuleAoeBonusBugged_4e36",
        ["; VANILLA BUG (S81, instruction-trace verified; entry hook fires, scan",
         "; cursor provably static): intended \"+20 AoE bonus when facing 2+ live",
         "; targets\" but the slot-scan cursor is NEVER incremented — it tests the",
         "; FIRST opposing slot three times, i.e. effectively \"+20 iff first",
         "; opposing slot alive\" (~always). Correct twin: AIRuleAoeLoneTargetMalus_5d8e.",
         "; Net effect: on lone-target boards AoE spells score +0 instead of the",
         "; intended ~-40 discouragement. Romhack enemy-AI fix candidate",
         "; (user-flagged S81) — any fix is a PATCH decision; bytes here stay vanilla."]),
    0x5D8E: ("AIRuleAoeLoneTargetMalus_5d8e",
        ["; Correct twin of AIRuleAoeBonusBugged_4e36: -20 when exactly 1 live",
         "; opposing target; RainSlash $57 hard-vetoes instead. (S81 sweep)"]),
    0x5FFD: ("AIRuleIncapBonus_5ffd",
        ["; +20 incapacitate class (Paralyze/Ahhh/LureDance/LushLicks/LegSweep/",
         "; BigTrip/WarCry/...). (S81 sweep)"]),
    0x6180: ("AIRulePoisonBonus_6180",
        ["; +10 poison class PoisonHit/PoisonGas/PoisonAir. (S81 sweep)"]),
    0x61BC: ("AIRuleCurseBonus_61bc",
        ["; +10 Curse $6F. (S81 sweep)"]),
    0x5A4C: ("AIRuleCoverDownedAlly_5a4c",
        ["; Cover/Guardian +20 when an own-side ally is down (HP 0 or processed-",
         "; dead $DD1B==1). (S81 sweep)"]),
    0x6C8C: ("AIRuleEnemySideBroad_6c8c",
        ["; ENEMY-SIDE-ONLY +20 on a broad damage/status skill set — party slots",
         "; (<4) and the hero slot never receive it (side gate byte-verified). (S81 sweep)"]),
    0x6784: ("AIRuleIronizePriority_6784",
        ["; First rule in all three chains; self-selects Ironize $2A / SquallHit $55 /",
         "; PsycheUp $56 (S82 bytes); per-rule effect not individually pinned (§15.9)."]),
}

# ---------------- renames: auto/legacy label -> semantic ----------------
RENAMES = {
    "Jump_057_7129": "AIState1CategoryScores_7129",
    "Jump_057_73b9": "AIState2CategorySelect_73b9",
    "Jump_057_7529": "AIState3SkillSums_7529",
    "Jump_057_7439": "AIState4FilterEval_7439",
    "Jump_057_75a2": "AIState5Pick_75a2",
    "Jump_057_7859": "AIState6Post_7859",
    "Jump_057_76a9": "AIRetryAllZero_76a9",
    "Jump_057_76df": "AILightweightPick_76df",
    "Jump_057_6f8c": "AIState0AltOutcome_6f8c",
    "FuncBtlAI_71b9": "AICategoryScoreCalc_71b9",
    "SaveBtlAI_72ce": "AICategoryScoreStore_72ce",
    "LoadBtlAI_7322": "AICategoryRank_7322",
    "LoadBtlAI_73a5": "AICat1RunnerUpCheck_73a5",
    "SetBtlAI_73b1": "AICat1RunnerUpBump_73b1",
    "LoadBtlAI_719b": "AIHealCatNerf_719b",
    "LoadBtlAI_77a4": "AICat3WeakHealCheckA_77a4",
    "LoadBtlAI_77b4": "AICat3WeakHealCheckB_77b4",
    "CalcBtlAI_45ea": "AIIndexWordTable_45ea",
    "LoadBtlAI_4456": "AIScanSlots_4456",
    "jr_057_788b": "AIChainZeroCell_788b",
    "jr_057_78a2": "AIChainApplyDelta_78a2",
    "LoadBtlAI_7905": "AIPreambleW3_7905",
    "FuncBtlAI_791a": "AIPreambleLadder_791a",
    "LoadBtlAI_7a5d": "AIPreambleDecide_7a5d",
    "AddBToHL16": "AISatAdd_455f",
    "ReadBtlAI_78ca": "AICallRuleAtHL_78ca",
}

# ---------------- new labels at previously unlabeled addresses ----------------
NEW_LABELS = {
    0x6E0E: "AIDecisionStateDispatch_6e0e",
    0x6E2A: "AIState0Preamble_6e2a",
    0x7865: "AIState7ChainWalker_7865",
    0x714E: "AIPlanCommandDivert_714e",
}

# ---------------- comments inserted above labels (post-rename names) ----------------
LABEL_COMMENTS = {
    "AIDecisionStateDispatch_6e0e": [
        "; ================= ENEMY/TACTICS AI DECISION MACHINE (bank $57) =================",
        "; Phase 5 ($d9ed==1) runs this per actor: dispatch on sub-state $D9EE via the",
        "; inline rst $00 table below. Traced+validated S80 (26/26, simulator/ai.py) and",
        "; S81 (rule chains 240/240, simulator/ai_rules.py). BATTLE_SKILL_SYSTEM §15.10."],
    "AIState0Preamble_6e2a": [
        "; State 0: act/flee preamble — plan read -> $DD72, w[3]-derived $db4d +",
        "; threshold ladders (AIPreambleW3_7905 / AIPreambleLadder_791a /",
        "; AIPreambleDecide_7a5d); carry -> clear $DCEC pair + run the machine,",
        "; no-carry -> AIState0AltOutcome_6f8c (flee/loaf, untraced). §15.10.7."],
    "AIState1CategoryScores_7129": [
        "; State 1: category scores — score[c] = base[c]//10 + plan_adj[c] +",
        "; swapped-r16 % ladder-mod (AICategoryScoreCalc_71b9 -> AICategoryScoreStore_72ce,",
        "; one GenerateRNG step each), then ranking AICategoryRank_7322. §15.10.2-3 (S80)."],
    "AIState2CategorySelect_73b9": [
        "; State 2: category-attempt stage between ranking and the per-skill sums",
        "; ($DD6A = [$DCFC + $DD02]); re-entry point for AIRetryAllZero_76a9. (S80)"],
    "AIState3SkillSums_7529": [
        "; State 3: per-skill sums — for EVERY option-list pair {tag, skill} at",
        "; $DC64+idx*16: $DCE4[i] = record ai_weight + r16'%16, saturating $FF;",
        "; one RNG step per skill. §15.10.4 (S80)."],
    "AIState4FilterEval_7439": [
        "; State 4: zero $DCE4 entries whose tag != $DD6A; each surviving skill",
        "; loads record flags7 -> $DD6B + its CATEGORY chain pointer",
        "; (AIRuleChainIndex_4302) and switches to state 7. §15.10.5 (S80/S81)."],
    "AIState5Pick_75a2": [
        "; State 5: pick — status overrides first (confusion -> $3A, +6 bit2 -> $42,",
        "; +7 bit4 -> $95); $dd0b==0 -> AILightweightPick_76df; else argmax over",
        "; $DCE4 with RNG-bit0 ties; all-zero -> AIRetryAllZero_76a9. Epilogues:",
        "; cat1 far-calls bank $58 entry 11 (plain-attack compare -> $3A if >= best);",
        "; cat3 best<$14 -> AICat3WeakHealCheckA/B. §15.10.6 (S80)."],
    "AIState6Post_7859": [
        "; State 6: post/commit — winning skill id -> $DCEC+idx*2; the target byte",
        "; stays $FF (resolved at ACT time by bank $58 entry 4, the RNG-slot fishing",
        "; resolver — §15.10.6 target-resolution note, S81). §15.10.6 (S80)."],
    "AIState7ChainWalker_7865": [
        "; State 7: LIVE rule-chain walker — cursor $C1FA/B walks the dw chain; per",
        "; rule: AICallRuleAtHL_78ca, then $DD27==$FF -> AIChainZeroCell_788b (veto",
        "; abort). dw $0000 terminator -> AIChainApplyDelta_78a2. (S81; the inline",
        "; walker path at ReadBtlAI_750c appears dead — §15.10.5)"],
    "AIChainApplyDelta_78a2": [
        "; Chain end: delta = $DD26 bonus - $DD27 penalty; borrow (net-negative)",
        "; ALSO jumps to AIChainZeroCell_788b; else dce4[cell] += delta (8-bit add,",
        "; no carry check). (S81)"],
    "AIChainZeroCell_788b": [
        "; Veto exit: zero the option's $DCE4 cell. Entered from BOTH the mid-chain",
        "; $DD27==$FF check and the end-of-chain borrow (KEY_LESSONS S81). (S81)"],
    "AIRetryAllZero_76a9": [
        "; All-options-zero retry: $dd02++ UNBOUNDED, rerun from the category stage",
        "; — ROOT CAUSE of the S79 AI stall (KEY_LESSONS S80). Romhack fix candidate."],
    "AILightweightPick_76df": [
        "; $dd0b==0 lightweight picker — no per-skill RNG; observed choosing by",
        "; top-category tag match (EID 37); tail untraced (§15.9)."],
    "AICat3WeakHealCheckA_77a4": [
        "; cat3 epilogue when best skill score < $14: extra checks (internals",
        "; untraced) that can retry, fall back to Attack $3A, or queue Defence $8D. (S80)"],
    "AICat3WeakHealCheckB_77b4": [
        "; Second cat3 weak-heal check — see AICat3WeakHealCheckA_77a4. (S80)"],
    "AIState0AltOutcome_6f8c": [
        "; State-0 no-carry outcome (flee/loaf class) — untraced (§15.10.7)."],
    "AIPlanCommandDivert_714e": [
        "; Plan $81 \"Command\": $DD03[idx]==3 diverts to the direct-command path",
        "; (S81 behavior anchor: post-command GO = physical only)."],
    "AISatAdd_455f": [
        "; Saturating [hl] += b, cap $FF. ALL rule bonus/penalty writes to the",
        "; $DD26/$DD27 accumulator pair go through here (64 call sites). The old",
        "; auto-name AddBToHL16 was misleading — this is an 8-bit add. (S81)"],
    "ClearBattleAction": [
        "; AI rule VETO: $DD27 := $FF. The walker aborts at the next rule boundary",
        "; and zeroes the option cell (AIChainZeroCell_788b). (S81)"],
    "AIIndexWordTable_45ea": [
        "; hl += a*2 word-table indexer (used to fetch the chain base from",
        "; AIRuleChainIndex_4302). The S81 wrong-bank sm83dis trap produced garbage",
        "; for THIS routine — KEY_LESSONS S81."],
    "AIScanSlots_4456": [
        "; Slot-scan family head: walk slots via CheckMonsterSlot ($00:$2FA5 —",
        "; CF SET means NOT a live monster; see the ROM0 contract comment),",
        "; testing [slot rec] & e. $DD1B+slot: 0 alive / 1 processed-dead /",
        "; $FF invalid. (S81)"],
    "AICallRuleAtHL_78ca": [
        "; Trampoline: jump to the rule routine pointed to by [hl] (the walker's",
        "; call makes the rule's ret return into the walk loop). (S81)"],
    "AICategoryScoreCalc_71b9": [
        "; One category score roll: GenerateRNG step, byte-swapped 16-bit r16 %",
        "; ladder-mod (mod=10 for player slots <3 and link; else base ladder",
        "; <50->30 <100->25 <150->20 else 10). §15.10.2 (S80)."],
    "AICategoryScoreStore_72ce": [
        "; Store the rolled category score. §15.10.2 (S80)."],
    "AICategoryRank_7322": [
        "; Quirky partial sort of cells $DCFC/D/E with ids $DCFF-$DD01 (seeded",
        "; 1,2,3): cat1-vs-cat2 swap; winner-vs-cat3 rank1<->rank3 ONLY (rank2",
        "; untouched — ranking can be non-sorted); runner-up bump; rank2-vs-rank3.",
        "; $DD02=3 on exit (cursor at rank1). §15.10.3 (S80)."],
    "AICat1RunnerUpCheck_73a5": [
        "; iff cat1 is NOT rank1: +$1E to cat1's CELL (\"attack as perennial",
        "; runner-up\"). NOTE the second check at $73AB after the blank line — the",
        "; S80 sed trap (KEY_LESSONS S80). §15.10.3."],
    "AICat1RunnerUpBump_73b1": [
        "; Apply the +$1E runner-up bump to cat1's cell. (S80)"],
    "AIHealCatNerf_719b": [
        "; $dcfe -= $1E floor 0 when $db76==0 — heal-category nerf. (S80)"],
    "AIPreambleW3_7905": [
        "; State-0: $db4d = w[3]/10 (the $DC5C weight, consumed here — not by the",
        "; category machine). §15.10.7 (S80)."],
    "AIPreambleLadder_791a": [
        "; State-0 threshold ladders on the category bases (b=0/9/18 rows — the",
        "; personality-table row-group offsets). §15.10.7 (S80)."],
    "AIPreambleDecide_7a5d": [
        "; State-0 decision: carry -> clear the $DCEC pair to $FFFF, set bit6 of",
        "; $DD03[idx], run the machine (plan $81 diverts at AIPlanCommandDivert_714e);",
        "; no-carry -> AIState0AltOutcome_6f8c. §15.10.7 (S80)."],
    "ReadBtlAI_750c": [
        "; Apparently-DEAD inline chain-walk path — the live walker is state 7",
        "; (AIState7ChainWalker_7865). §15.10.5 (S81)."],
}

STATE_NAMES = [
    "AIState0Preamble_6e2a", "AIState1CategoryScores_7129",
    "AIState2CategorySelect_73b9", "AIState3SkillSums_7529",
    "AIState4FilterEval_7439", "AIState5Pick_75a2",
    "AIState6Post_7859", "AIState7ChainWalker_7865",
]

CHECKMONSTERSLOT_OLD = ("; CheckMonsterSlot: Check if party/battle slot A (0-7) "
                        "has a valid monster. CF=valid")
CHECKMONSTERSLOT_NEW = [
    "; CheckMonsterSlot: validity of party/battle slot A (0-7).",
    "; CF SET = NOT a live monster (A>=8, $DD1B[slot]==$FF invalid, or ==1",
    "; processed-dead); CF CLEAR = live ($DD1B[slot]==0). The old comment here",
    "; said CF=valid — INVERTED (byte-verified S82). Heavily used by the",
    "; bank-$57 AI rule chains and scan family (AIScanSlots_4456); rules that",
    "; need the alive/processed-dead distinction read $DD1B directly.",
]


def rom_data():
    return open(ROM, "rb").read()


def rom_bytes(start, end):
    d = rom_data()
    off = BANK * 0x4000 + (start - 0x4000)
    return d[off:off + (end - start)]


def walk_chain(base):
    ptrs, a = [], base
    while True:
        v = struct.unpack("<H", rom_bytes(a, a + 2))[0]
        if v == 0:
            return ptrs, a + 2
        ptrs.append(v)
        a += 2


def find_state_table():
    seq = struct.pack("<8H", *STATE_HANDLERS)
    d = rom_data()
    off = d.find(seq, BANK * 0x4000, (BANK + 1) * 0x4000)
    if off < 0:
        sys.exit("state dispatch table not found in bank $57")
    return 0x4000 + (off - BANK * 0x4000)


def build_line_addr_map(lines):
    """Insert zero-byte probe labels, build once, return {line_idx0: addr}."""
    probed, probe_of = [], {}
    for i, l in enumerate(lines):
        s = l.strip()
        if s and not s.startswith(";") and not (s.endswith(":") and " " not in s):
            probed.append(f"Lprobe_{i}:")
            probe_of[f"Lprobe_{i}"] = i
        probed.append(l)
    backup = ASM + ".probebak"
    shutil.copy(ASM, backup)
    try:
        open(ASM, "w").write("\n".join(probed) + "\n")
        _clean_build_artifacts()
        r = subprocess.run("make", cwd=DIS, shell=True, capture_output=True, text=True)
        if not os.path.exists(os.path.join(DIS, "game.gbc")):
            sys.exit("probe build failed:\n" + r.stdout + r.stderr)
        md5 = hashlib.md5(open(os.path.join(DIS, "game.gbc"), "rb").read()).hexdigest()
        if md5 != ORIGINAL_MD5:
            sys.exit(f"probe build not byte-perfect ({md5}); aborting.")
        sym = open(os.path.join(DIS, "game.sym")).read()
    finally:
        shutil.move(backup, ASM)
    addr_of = {}
    for line in sym.splitlines():
        m = re.match(r"^57:([0-9a-fA-F]{4}) (Lprobe_\d+)", line)
        if m:
            addr_of[m.group(2)] = int(m.group(1), 16)
    return {ln: addr_of[name] for name, ln in probe_of.items() if name in addr_of}


def _clean_build_artifacts():
    for f in ("game.o", "game.gbc", "game.sym", "game.map"):
        p = os.path.join(DIS, f)
        if os.path.exists(p):
            os.remove(p)


def span_for_range(line_addr, start, end):
    in_range = [ln for ln, a in line_addr.items() if start <= a < end]
    if not in_range:
        sys.exit(f"no source lines map into [${start:04x},${end:04x})")
    return min(in_range), max(in_range) + 1


def rule_label(addr):
    return RULE_NAMES[addr][0] if addr in RULE_NAMES else f"AIRule_{addr:04x}"


def chain_block(label, cat_desc, ptrs, extra=()):
    out = [f"; {cat_desc} — {len(ptrs)} rules, $0000-terminated dw list."]
    out += list(extra)
    out.append(f"{label}:")
    for p in ptrs:
        out.append(f"    dw {rule_label(p)}")
    out.append("    dw $0000 ; end of chain")
    return out


def analyze():
    lines = open(ASM).read().splitlines()
    line_addr = build_line_addr_map(lines)
    c1, _ = walk_chain(CHAIN_BASES[0])
    c2, _ = walk_chain(CHAIN_BASES[1])
    c3, e3 = walk_chain(CHAIN_BASES[2])
    rules = sorted(set(c1) | set(c2) | set(c3))
    addr_line = {}
    for ln, a in line_addr.items():
        addr_line.setdefault(a, ln)
    missing = [r for r in rules if r not in addr_line]
    print(f"chains {len(c1)}/{len(c2)}/{len(c3)}, unique {len(rules)}, "
          f"region A $4302..${e3 - 1:04x}, state table ${find_state_table():04x}")
    print(f"rule addrs without a line boundary: {len(missing)} "
          f"{[hex(m) for m in missing]}")
    for a in list(NEW_LABELS) + [CHAIN_INDEX]:
        print(f"  target ${a:04x}: {'OK' if a in addr_line else 'NO BOUNDARY'}")


def apply():
    text = open(ASM).read()
    if APPLIED_MARKER in text:
        print("already applied (marker present) — nothing to do.")
        return

    lines = text.splitlines()
    line_addr = build_line_addr_map(lines)
    addr_line = {}
    for ln, a in line_addr.items():
        addr_line.setdefault(a, ln)

    c1, _ = walk_chain(CHAIN_BASES[0])
    c2, _ = walk_chain(CHAIN_BASES[1])
    c3, e3 = walk_chain(CHAIN_BASES[2])
    rules = sorted(set(c1) | set(c2) | set(c3))
    tbl = find_state_table()

    # ---- safety: every insertion target must sit on a line boundary ----
    for a in rules + list(NEW_LABELS):
        if a not in addr_line:
            sys.exit(f"target ${a:04x} has no source-line boundary — aborting")

    # ---- safety: renamed labels must not be referenced outside bank_057/patches we scan ----
    scan_files = [os.path.join(DIS, f) for f in sorted(os.listdir(DIS)) if f.endswith(".asm")]
    pdir = os.path.join(REPO, "patches")
    if os.path.isdir(pdir):
        scan_files += [os.path.join(pdir, f) for f in sorted(os.listdir(pdir)) if f.endswith(".asm")]
    ext_refs = {}
    for old in RENAMES:
        for path in scan_files:
            if os.path.basename(path) == "bank_057.asm":
                continue
            t = open(path).read()
            n = len(re.findall(rf"\b{re.escape(old)}\b", t))
            if n:
                ext_refs.setdefault(old, []).append((path, n))
    # references outside bank_057 get renamed too (same label, same address)
    # — report them so the session log shows the touched files.
    for old, sites in ext_refs.items():
        for path, n in sites:
            print(f"note: {old} referenced in {os.path.relpath(path, REPO)} ({n}) — renaming there too")

    # ---- 1. renames (in-memory; identical line count) ----
    def do_renames(s):
        for old, new in RENAMES.items():
            s = re.sub(rf"\b{re.escape(old)}\b", new, s)
        return s
    lines = [do_renames(l) for l in lines]

    # ---- 2. structural ops (start, end, replacement) applied descending ----
    ops = []

    # region A: chain index + three chains
    a_start, a_end = span_for_range(line_addr, CHAIN_INDEX, e3)
    block = [
        "; ============== AI EVALUATOR RULE CHAINS (S81, byte-verified) ==============",
        "; Level-1 index: 3 dw chain bases, one per skill CATEGORY (1 dmg / 2 status /",
        "; 3 heal), fetched via AIIndexWordTable_45ea from AIState4FilterEval_7439.",
        "; The WHOLE category chain runs for every tag-matched skill; rules",
        "; self-select on skill id $DB8A + board state. Walker: AIState7ChainWalker_7865.",
        "; Accumulators: $DD26 bonus / $DD27 penalty (AISatAdd_455f; veto =",
        "; ClearBattleAction). 131 unique rules, 27 shared between chains.",
        "; (S81 falsified the S80 \"indexed by effect_class\" hypothesis; the S81",
        ";  write-up's \"61 rules\" for cat2 was a miscount — 85, byte-verified S82.)",
        "AIRuleChainIndex_4302:",
        "    dw AIRuleChainCat1_4308, AIRuleChainCat2_4358, AIRuleChainCat3_4404",
        "",
    ]
    block += chain_block("AIRuleChainCat1_4308", "Category 1 (DAMAGE) rule chain", c1)
    block.append("")
    block += chain_block("AIRuleChainCat2_4358", "Category 2 (STATUS) rule chain", c2)
    block.append("")
    block += chain_block("AIRuleChainCat3_4404", "Category 3 (HEAL) rule chain", c3)
    ops.append((a_start, a_end, block))

    # region B: inline state dispatch table
    b_start, b_end = span_for_range(line_addr, tbl, tbl + 0x10)
    bblock = [
        f"AIStateDispatchTable_{tbl:04x}:",
        "; Inline rst $00 jump table on sub-state $D9EE (states 0-7). §15.10 (S80)."]
    for i, n in enumerate(STATE_NAMES):
        bblock.append(f"    dw {n} ; state {i}")
    ops.append((b_start, b_end, bblock))

    # new labels (+ their comments if any)
    for a, name in NEW_LABELS.items():
        ln = addr_line[a]
        ins = list(LABEL_COMMENTS.get(name, [])) + [f"{name}:"]
        ops.append((ln, ln + 1, ins + [lines[ln]]))

    # rule labels + comments
    for a in rules:
        ln = addr_line[a]
        name = rule_label(a)
        ins = []
        if a in RULE_NAMES:
            ins += RULE_NAMES[a][1]
        ins.append(f"{name}:")
        ops.append((ln, ln + 1, ins + [lines[ln]]))

    # comments above existing (already-renamed) labels
    label_line = {}
    for i, l in enumerate(lines):
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", l)
        if m:
            label_line[m.group(1)] = i
    for name, comment in LABEL_COMMENTS.items():
        if name in [v for v in NEW_LABELS.values()]:
            continue  # handled with the label insertion
        if name == "ClearBattleAction" or name in RENAMES.values() or name == "ReadBtlAI_750c":
            if name not in label_line:
                sys.exit(f"comment target label {name} not found after rename")
            ln = label_line[name]
            ops.append((ln, ln + 1, comment + [lines[ln]]))

    # ---- overlap check + apply descending ----
    ops.sort(key=lambda o: o[0], reverse=True)
    prev_start = None
    for s, e, _ in ops:
        if prev_start is not None and e > prev_start:
            sys.exit(f"overlapping ops at lines {s}..{e} vs {prev_start}")
        prev_start = s
    for s, e, repl in ops:
        lines[s:e] = repl

    out = "\n".join(lines) + "\n"
    assert "jr_057_4390" not in out, "soup label jr_057_4390 survived (external ref?)"
    open(ASM, "w").write(out)

    # ---- bank 0: CheckMonsterSlot contract comment fix ----
    t0 = open(ASM0).read()
    if CHECKMONSTERSLOT_OLD in t0:
        t0 = t0.replace(CHECKMONSTERSLOT_OLD, "\n".join(CHECKMONSTERSLOT_NEW))
        open(ASM0, "w").write(t0)
        print("bank_000: CheckMonsterSlot CF comment corrected")
    elif CHECKMONSTERSLOT_NEW[0] in t0:
        print("bank_000: CheckMonsterSlot comment already corrected")
    else:
        sys.exit("bank_000: CheckMonsterSlot comment not found in either form")

    # ---- final build must be byte-perfect ----
    _clean_build_artifacts()
    r = subprocess.run("make", cwd=DIS, shell=True, capture_output=True, text=True)
    if not os.path.exists(os.path.join(DIS, "game.gbc")):
        sys.exit("final build failed:\n" + r.stdout + r.stderr)
    md5 = hashlib.md5(open(os.path.join(DIS, "game.gbc"), "rb").read()).hexdigest()
    if md5 != ORIGINAL_MD5:
        sys.exit(f"FINAL BUILD NOT BYTE-PERFECT ({md5}) — inspect before committing!")
    print(f"applied; final build byte-perfect ({md5})")


if __name__ == "__main__":
    if "--analyze" in sys.argv:
        analyze()
    else:
        apply()
