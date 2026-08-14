#!/usr/bin/env python3
"""Evaluator rule chains — bank $57 state-7 walker model (S81 v2).

Architecture (measured + byte-verified):
  $57:$4302 -> chain bases $4308 (cat1) / $4358 (cat2) / $4404 (cat3);
  whole chain runs per tag-matched skill; rules self-select on skill id.
  $DD26 bonus / $DD27 penalty accumulators via saturating adder $455F;
  veto = ClearBattleAction $45E4 ($DD27:=$FF) aborting the walk, or
  borrow at chain end $78A2 (bonus<penalty) -> cell zeroed ($788B).
  Writeback: dce4[cell] += (bonus-penalty), 8-bit add, no carry check.

Membership sets below are AUTHORITATIVE: derived from the S81 full sweep
of all 160 cat-1/2/3 skills through the real chains (clean board), plus
condition sweeps (self/ally hurt, own statuses, ally dead, low MP).
Mid-chain vetoes abort walks, so early-vetoed skills list under their
veto rule; their later-bonus membership is irrelevant to the cell value.

Slot validity $DD1B+slot: 0 alive / 1 processed-dead / $FF invalid.
$DB8B trait byte = info+5 | swap(info+4): bit0 metal, bit4 flying.
Families (info+0): 0 Slime 1 Dragon 2 Beast 3 Bird 4 Plant 5 Bug
6 Devil 7 Zombie 8 Material 9 Boss.

VANILLA BUG (verified): $4E36 "+20 AoE bonus when 2+ opposing targets"
never increments its slot cursor -- effectively "+20 iff FIRST opposing
slot alive". Modelled verbatim. Its twin $5D8E (-20 when exactly 1 live
opposing target; RainSlash $57: hard veto) works correctly.

NOT a bug (S81 correction): family-cut veto $6848 / bonus $4C41 pair is
correct; CleanCut is anti-MATERIAL (family 8), Smashlime anti-Slime (0).

$4E18 (caster-profile spell bonus, pinned by 4-point MP matrix + decode):
  +10 iff CurMP < MaxMP/2, plus +10 iff MaxMP >= MaxHP.
"""

# ---- authoritative membership (decimal skill ids) ----
R_4BCC = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 68, 69, 70, 71, 79, 82, 83, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 103, 105, 107, 108, 109, 111, 112, 120, 121, 123, 124, 125, 217}   # element-aware +20
R_4C41_SMASH = {214}          # family-cut bonus (Smashlime seen)
R_4D56 = {59, 61, 66, 68, 69, 70, 71, 80, 81, 85, 86, 103, 104, 105, 214}   # +15 physical specials
R_4E18 = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 79, 82, 83, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101}   # caster-profile +10/+10
R_4E36 = {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 79, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102}   # bugged AoE +20
R_5D8E = {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19, 79, 87, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 113}   # AoE-vs-lone-target -20 (87 RainSlash: veto)
R_5FFD = {105, 107, 112, 120, 121, 123, 124, 125}   # +20 incapacitate class
R_6180 = {103, 108, 109}   # +10 poison class
R_61BC = {111}   # +10 curse
R_6C8C = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 59, 60, 61, 62, 63, 64, 66, 68, 69, 70, 71, 79, 80, 81, 82, 83, 85, 86, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 214, 217}   # enemy-side-only +20

CUT_FAMILY = {73: 1, 74: 2, 75: 3, 76: 6, 77: 7, 78: 8,
              214: 0, 215: 5, 216: 4}   # skill -> family id ($4C41/$6848)
METALCUT = 72
HEAL_SINGLE = {43, 44, 46, 147, 148}
HEAL_ALL_SET = {43, 44, 45, 46, 47, 147, 148}   # $49B7 veto set
SLEEP_CLASS = {21, 22, 42, 104, 106, 112, 114, 115, 120, 121, 122,
               123, 124, 125, 220}
POISON_PAIR = {103, 108}
HEAVY_TRIO = {103, 108, 109}
SUPPORT_5D4D = {20, 48, 49, 50, 52, 53, 136, 137, 149, 150}
REVIVE_67B1 = {48, 49, 149}
CURE_RULES = {51: 0x01, 52: 0x40, 53: 0x10, 54: 0x20}
ROB_CLASS = {26, 27, 67, 118}       # $6AB4 + $4ACC (SuckAir: static-presumed)
SHUT_RULES = {145: 0x40, 146: 0x80} # DanceShut/MouthShut: presumed
                                      # "opponent uses class" checks; the
                                      # clean-board veto is measured, the
                                      # pass condition is NOT yet traced.
UTIL_VETO_UNTRACED = {128, 131}     # DeMagic/ThickFog: veto measured
                                      # clean; pass condition untraced.


class BattleView:
    def __init__(self, hp, maxhp, mp, maxmp, status, dd1b, traits,
                 families, resist_score):
        self.hp, self.maxhp, self.mp, self.maxmp = hp, maxhp, mp, maxmp
        self.status, self.dd1b = status, dd1b
        self.traits, self.families = traits, families
        self.resist_score = resist_score

    def opposing(self, actor):
        base = 0 if actor >= 4 else 4
        return range(base, base + 3)

    def own(self, actor):
        base = 4 if actor >= 4 else 0
        return range(base, base + 3)

    def alive(self, slot):
        return self.dd1b[slot] == 0

    def live_opposing(self, actor):
        return [s for s in self.opposing(actor) if self.alive(s)]

    def live_own(self, actor):
        return [s for s in self.own(actor) if self.alive(s)]


def _all_live_opposing_have(view, actor, off, mask):
    live = view.live_opposing(actor)
    return bool(live) and all(view.status[s][off] & mask for s in live)


def evaluate_chain(category, skill, actor, view, mp_cost, element,
                   rec_flags7):
    """(delta, veto) for one tag-matched skill, mirroring $78A2/$788B."""
    bonus = penalty = 0

    # $45F2 universal usability [measured]
    if mp_cost > view.mp[actor]:
        return 0, True
    st3 = view.status[actor][3]
    if (rec_flags7 & 0x40) and (st3 & 0x01):
        return 0, True
    if (rec_flags7 & 0x20) and (st3 & 0x40):
        return 0, True
    if (rec_flags7 & 0x10) and (st3 & 0x80):
        return 0, True

    # status-already-present vetoes [measured]
    if skill in HEAVY_TRIO and _all_live_opposing_have(view, actor, 2, 0x02):
        return 0, True
    if skill in POISON_PAIR and _all_live_opposing_have(view, actor, 2, 0x03):
        return 0, True
    if skill in SLEEP_CLASS and _all_live_opposing_have(view, actor, 2, 0x8C):
        return 0, True
    if skill in R_5FFD and _all_live_opposing_have(view, actor, 2, 0xCC):
        return 0, True   # $6267 don't-incapacitate-the-incapacitated

    # $5D4D need->=1 ally (own valid slots >= 2) [measured+static]
    if skill in SUPPORT_5D4D:
        if sum(1 for s in view.own(actor) if view.dd1b[s] != 0xFF) < 2:
            return 0, True
    # $67B1 revive needs processed-dead ally [static+measured veto branch]
    if skill in REVIVE_67B1:
        if not any(view.dd1b[s] == 1 for s in view.own(actor)):
            return 0, True
    # cures [measured both branches]
    if skill in CURE_RULES:
        if any(view.status[s][2] & CURE_RULES[skill]
               for s in view.live_own(actor)):
            bonus += 15
        else:
            return 0, True
    # heals [measured]: veto $49B7 if own side unhurt; +5 single
    # ($4FD2/$5149) +15 broad ($502C/$51DA)
    if skill in HEAL_ALL_SET:
        if not any(view.hp[s] < view.maxhp[s]
                   for s in view.live_own(actor)):
            return 0, True
        if skill in HEAL_SINGLE:
            bonus += 5
        bonus += 15
    # $5D16/$67D5 Surge cleanse gate [veto measured; +15 presumed]
    if skill == 129:
        if not any(view.status[s][2] or (view.status[s][3] & 0xC3)
                   for s in view.live_own(actor)):
            return 0, True
        bonus += 15
    # Rob class: veto when own MP full [measured 26/27/118; 67 presumed]
    if skill in ROB_CLASS and view.mp[actor] >= view.maxmp[actor]:
        return 0, True
    # Shut/util rules: pass conditions untraced -> conservative veto
    # matching every measured board; loop validation will flag if a real
    # battle exercises the pass branch.
    if skill in SHUT_RULES or skill in UTIL_VETO_UNTRACED:
        return 0, True

    # family cuts [measured Smashlime bonus + all veto branches]
    if skill in CUT_FAMILY:
        fam = CUT_FAMILY[skill]
        if any(view.families[s] == fam
               for s in view.live_opposing(actor)):
            bonus += 20
        else:
            return 0, True
    if skill == METALCUT:
        if any(view.traits[s] & 0x01
               for s in view.live_opposing(actor)):
            bonus += 20
        else:
            return 0, True

    # $4BCC element-aware +20 [measured; resist condition static]
    if skill in R_4BCC:
        live = view.live_opposing(actor)
        rsum = sum(view.resist_score(s, element) & 3 for s in live)
        if rsum <= len(live):
            bonus += 20
    # $4D56 +15 [measured; no off-condition seen on any swept board]
    if skill in R_4D56:
        bonus += 15
    # $4DF9 +5 PsycheUp [conditional: fired for FloraMan (EID 35), not
    # for forced-Gremlin -- condition untraced, omitted; loop validation
    # will flag if it matters]
    # $4E18 caster-profile [pinned]
    if skill in R_4E18:
        if view.mp[actor] < view.maxmp[actor] // 2:
            bonus += 10
        if view.maxmp[actor] >= view.maxhp[actor]:
            bonus += 10
    # $4E36 bugged AoE +20 [instruction-trace verified]
    if skill in R_4E36:
        if view.alive(min(view.opposing(actor))):
            bonus += 20
    # $5D8E AoE-vs-lone -20 / RainSlash veto [decoded + measured]
    if skill in R_5D8E:
        if len(view.live_opposing(actor)) == 1:
            if skill == 87:
                return 0, True
            penalty += 20
    # class bonuses [measured]
    if skill in R_5FFD:
        bonus += 20
    if skill in R_6180:
        bonus += 10
    if skill in R_61BC:
        bonus += 10
    # $5A4C Cover/Guardian with downed ally [measured]
    if skill in (136, 137):
        if any(view.dd1b[s] != 0xFF and
               (view.hp[s] == 0 or view.dd1b[s] == 1)
               for s in view.own(actor)):
            bonus += 20
    # $6C8C enemy-side-only +20 [measured; side gate byte-verified]
    if skill in R_6C8C and actor >= 4 and actor != 7:
        bonus += 20

    bonus = min(bonus, 0xFF)
    penalty = min(penalty, 0xFF)
    if bonus < penalty:
        return 0, True
    return bonus - penalty, False
