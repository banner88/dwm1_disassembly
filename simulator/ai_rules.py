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
MULTICUT = 79                  # S164: $4C41 row 7 (family 7), no $6848 veto
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
                                      # S130 F10: traced — f10_rules() below
                                      # when the view carries skills/dd0b.


# ---- S163 (ROADMAP E17 note "the S81 rule model on 3-opponent boards") ----------------
# The three chains as the ROM lists them ($57:$4302 -> $4308 / $4358 / $4404; S81 byte-read,
# re-extracted S163): a rule runs only for an option of a category whose chain holds it.
CHAINS = {
    1: (0x6784, 0x45F2, 0x4702, 0x4725, 0x4745, 0x4785, 0x4AF6, 0x4B3D, 0x4C13, 0x5D4D, 0x5EE5,
        0x5F1F, 0x5F91, 0x6267, 0x6444, 0x64FB, 0x6848, 0x6A0D, 0x6A67, 0x6C62, 0x5D8E, 0x4B8C,
        0x6596, 0x6619, 0x4BCC, 0x4C41, 0x4D56, 0x4DF9, 0x4E18, 0x4E36, 0x4E76, 0x5454, 0x5BAE,
        0x5FFD, 0x6180, 0x66FB, 0x6810, 0x6B89, 0x6C8C),
    2: (0x6784, 0x45F2, 0x4685, 0x4702, 0x4725, 0x4745, 0x4785, 0x47D9, 0x47F5, 0x4821, 0x4843,
        0x4865, 0x4890, 0x4902, 0x4A94, 0x4ACC, 0x4AF6, 0x4B3D, 0x4C13, 0x5493, 0x5B34, 0x5B4A,
        0x5BCD, 0x5BF5, 0x5C25, 0x5C5D, 0x5CC8, 0x5D4D, 0x5DE0, 0x5DFA, 0x5E10, 0x5E3E, 0x5E7E,
        0x5EA4, 0x5EBB, 0x5EE5, 0x5F1F, 0x5F91, 0x6267, 0x62A8, 0x6382, 0x63B0, 0x63E3, 0x6414,
        0x6444, 0x6474, 0x649D, 0x64CC, 0x667B, 0x6757, 0x695E, 0x6975, 0x6A0D, 0x6AB4, 0x6AF5,
        0x6BCB, 0x6C0F, 0x55C4, 0x55D6, 0x6C62, 0x6CC0, 0x6596, 0x6619, 0x69CB, 0x4BCC, 0x54BE,
        0x54E4, 0x551B, 0x55F6, 0x5660, 0x5739, 0x57FC, 0x5842, 0x593D, 0x59F7, 0x5FFD, 0x604A,
        0x608E, 0x60C8, 0x6107, 0x6144, 0x6180, 0x61BC, 0x61F1, 0x622C),
    3: (0x6784, 0x45F2, 0x4969, 0x4983, 0x499D, 0x49B7, 0x4A5C, 0x4A94, 0x5C25, 0x5D16, 0x5D4D,
        0x5F1F, 0x5F91, 0x64FB, 0x667B, 0x66D4, 0x67B1, 0x4785, 0x4EB9, 0x4EE4, 0x4F2E, 0x4F61,
        0x4F94, 0x4FB3, 0x4FD2, 0x502C, 0x50BC, 0x5113, 0x5149, 0x51DA, 0x52DC, 0x536A, 0x53B6,
        0x53DD, 0x5411, 0x5434, 0x55F6, 0x5A4C, 0x5AEF, 0x67D5),
}
# id ladders read from the rule heads (S163; the S81 sets were the ids SEEN firing on one
# board — a rule whose condition failed there looked like "not a member")
PHYS_7C7E = {59, 61, 66, *range(68, 79), 80, 81, 85, 86, 87, 103, 104, 105, 214, 215, 216}
IDS_5FFD = {21, 22, 25, 104, 105, 106, 107, 110, 112, 120, 121, 123, 124, 125, 218}
IDS_604A = {24, 114, 115}
IDS_60C8 = {23, 117, 118}
IDS_6107 = {28, 29, 122}
IDS_6144 = {32, 33}
IDS_6180 = {103, 108, 109}
IDS_61BC = {111}
IDS_6444 = {103, 108, 109}
IDS_4E36 = {*range(3, 20), 79, 87, *range(89, 103)}
IDS_551B = {0x18, 0x1E, 0x1F, 0x72, 0x73, 0x77}     # S164: AIRule_551b's id ladder (byte-read)
IDS_5D8E = {*range(3, 18), 19, 20, 79, 87, *range(89, 103), 113}
IDS_6C8C = {*range(0, 21), *(set(range(59, 106)) - {65, 67, 84}), 214, 215, 216, 217}
IDS_66FB = {60, 62}


def _in(category, rule):
    return rule in CHAINS.get(category, ())


def _lvl(view, s, element):
    return view.resist_score(s, element) & 3


def _count_rule(view, actor, element, eligible, fixed=False):
    """The status-class rules' count (bank $57 CallBtlAI_7d4d + SetBtlAI_7d54, S163): the
    FIRST opposing slot is counted once before the loop whatever it is (CallBtlAI_7d4d falls
    into SetBtlAI_7d54), then every eligible slot of the three (the first again too): count =
    1 + n, sum = its level + theirs; the bonus when count >= sum (and count != 0 — never 0 in
    the original). [S164] fixed (gamedata.ai_fixes.class_count, region gd_ai_fix_count):
    CallBtlAI_7d4d returns before SetBtlAI_7d54 — count = n, sum = theirs."""
    opp = 0 if actor >= 4 else 4
    cnt, tot = (0, 0) if fixed else (1, _lvl(view, opp, element))
    for s in range(opp, opp + 3):
        if eligible(s):
            cnt += 1
            tot += _lvl(view, s, element)
    return cnt != 0 and cnt >= tot


def _avg16(vals):
    """[S164 averages] the fixed FuncBtlAI_7dc5: the sum of the live monsters' values / their
    count (Div16x8To16, integer); none -> 0, one -> its value."""
    if len(vals) < 2:
        return sum(vals) & 0xFFFF
    return (sum(vals) & 0xFFFF) // len(vals)


def _avg16_vanilla(n):
    """The original FuncBtlAI_7dc5 (S163): the running sum is never summed (0); one or two live
    -> 0; any other count -> Div16x8To16 of 0 by the sum's high byte 0 -> $FFFF."""
    return 0 if n in (1, 2) else 0xFFFF


def _div16x8(hl, a):
    """bank $00 Div16x8To16: HL // A over 16 shift steps; A = 0 -> $FFFF (each step subtracts
    0 and sets the bit)."""
    hl &= 0xFFFF
    if a == 0:
        return 0xFFFF
    return hl // a


def _w16(xs, s):
    return xs[s] if xs is not None else None


# S155: CUSTOM_RULES[id](skill, actor, view) -> (veto, bonus, penalty) = bank $57
# CustomAI57 -> bank $72 CustomAIRule72 at the chain end ($78A2), for the
# romhack's built-in custom ids (simulator/skillfx/s155_custom.py registers;
# view.board = the Board when the adapter has one). Empty = the original game.
CUSTOM_RULES = {}


class BattleView:
    def __init__(self, hp, maxhp, mp, maxmp, status, dd1b, traits,
                 families, resist_score, skills=None, dd0b=None, db40=(0, 0),
                 atk=None, dfn=None, agl=None):
        self.hp, self.maxhp, self.mp, self.maxmp = hp, maxhp, mp, maxmp
        # S163: the battle stats per slot ($DBE3 / $DBF3 / $DC03); None = not known (the old
        # fixtures) -> the rules that compare them keep their S81 approximation
        self.atk, self.dfn, self.agl = atk, dfn, agl
        self.status, self.dd1b = status, dd1b
        self.traits, self.families = traits, families
        self.resist_score = resist_score
        # S130 F10: optional — the $DC64 option lists (8 (tag, skill) pairs
        # per slot), $DD0B and $DB40/41 (the slot-7 shifted pair). Rules
        # that need them fall back to the old conservative veto when absent.
        self.skills, self.dd0b, self.db40 = skills, dd0b, db40
        # S165: $DB58 / $DB59 as the board left them (AIRule_5660 compares the own side's
        # average AGL with this stale word — a vanilla bug); None = not known (the Balance
        # battles), the rule's second half then left out
        self.db58 = None
        # S165: each slot's BASE DEF as bank $57 entry 7 (BaseStatDEF_424a) reads it — a party
        # monster's record DEF (+$5A), an enemy's row DEF (bank $14 entry 1: row +11, the EID
        # $DA03 + 2 (s - 4); a helper slot (s & 3 == 3) the row $100 + its species); None = not
        # known -> AIRule_4890 left out
        self.base_def = None

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


# ---- S165 (ROADMAP E17 note "the rule model on arbitrary boards") ------------------------
# Rules the S163 model left out because the captured boards never made them fire; byte-read
# from bank $57 and validated on the mutated boards (simulator/rule_gaps.py, validate_ai_fixes)
IDS_4AF6 = (set(range(0x03, 0x1A)) - {0x12, 0x15}) | {0x1D, 0x21, 0xDA}  # veto: a foe reflects
IDS_5EE5 = set(range(0x00, 0x1A)) | {0x1C, 0x1D, 0x20, 0x21, 0xDA}       # veto: every foe does
IDS_4B3D = set(range(0x5C, 0x64)) | set(range(0x6A, 0x6E))                # the breaths
IDS_5F1F = (set(range(0x00, 0x1A)) | {0x1C, 0x1D, 0x20, 0x21, 0x2A} | set(range(0x3B, 0x41))
            | {0x44, 0x53} | set(range(0x55, 0x80)) | {0x82, 0x88, 0x89}
            | set(range(0x8C, 0x93)) | set(range(0xD6, 0xDC)) | {0xDD})
IDS_4A94 = {0x24, 0x8A, 0x8B, 0x8F, 0x92}
BREATHS_7B7D = IDS_4B3D
IDS_59F7 = {0x26, 0x7F}
LIST_59F7 = {0x4F, 0x59, 0x5B, 0x64, 0x65, 0xD9}
IDS_5B4A = {0x27, 0x28}
LIST_5B4A = set(range(0x00, 0x1B)) | {0x1C, 0x1D, 0x20, 0x21, 0xDA}
IDS_54E4 = {0x7A, 0x82, 0x25, 0x1C, 0x1D}
IDS_4E76 = {0x3F, 0x40}
IDS_5660 = {0x20, 0x21, 0x22, 0x23}
IDS_4890 = {0x1E, 0x1F}                                                  # Upper / Increase
IDS_54BE = {0x25, 0x7A, 0x41}
IDS_63E3 = {0x1C, 0x1D, 0x7A}                                            # Defence / SickLick
IDS_62A8 = {0x18, 0x72, 0x73}                                            # Surround / SandStorm / Radiant
IDS_5F91 = ({0x15, 0x16, 0x19, 0x2A, 0x6A, 0x6B, 0x6E, 0x70, 0x72, 0x73, 0x77, 0x78}
            | set(range(0x7A, 0x7E)) | {0x80, 0x81, 0x82, 0x88, 0x89, 0x8C}
            | set(range(0x8E, 0x91)) | {0xDA, 0xDC})
_DCLASS = {}


def damage_class(sid):
    """A skill record's +6 (damage class: 0 none, 4 spell, 5 breath …) from
    extracted/skill_records.json; DAMAGE_CLASS_OVERRIDE (a project's new skills) first."""
    if sid in DAMAGE_CLASS_OVERRIDE:
        return DAMAGE_CLASS_OVERRIDE[sid]
    if not _DCLASS:
        import json
        import os
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'extracted',
                            'skill_records.json')
        for r in json.load(open(path))['records']:
            raw = (r.get('battle_record') or {}).get('raw')
            if raw:
                _DCLASS[r['id']] = bytes.fromhex(raw)[6]
    return _DCLASS.get(sid, 0)


DAMAGE_CLASS_OVERRIDE = {}


def _opt_skills(view, s):
    """Slot s's option list as bank $57 scans it: the skill byte of each of the 8 pairs
    ($DC65 + 16 s, every second byte); the caller stops at $FF."""
    return [sk for _tg, sk in (view.skills[s] or [])[:8]]


def _w16slot(xs, s):
    return xs[s] & 0xFFFF if xs is not None and s < len(xs) else 0


def _stbyte(view, addr):
    """The status byte at `addr` ($DB00-$DB41): status[s][k] = $DB00 + 8 s + k, $DB40/41 = db40."""
    i = addr - 0xDB00
    if i < 64:
        return view.status[i >> 3][i & 7]
    return (view.db40 or (0, 0))[i - 64] if i < 66 else 0


def _word_at(view, arr, i):
    """Word i of the battle arrays laid end to end (0 HP $DBA3, 1 MaxHP, 2 MP, 3 MaxMP, 4 ATK,
    5 DEF, 6 AGL — 8 words each): index 8+ runs into the next array, as the ROM's reads do."""
    arrs = (view.hp, view.maxhp, view.mp, view.maxmp, view.atk, view.dfn, view.agl)
    k, j = arr + i // 8, i % 8
    a = arrs[k] if k < len(arrs) else None
    return a[j] & 0xFFFF if a is not None else 0


def _min_def_62e0(view, opp):
    """LoadBtlAI_62e0: the lowest DEF of the live foes — the first foe slot counts as 0 when
    it is not alive."""
    lo = _w16slot(view.dfn, opp) if view.alive(opp) else 0
    for s_ in range(opp + 1, opp + 3):
        if view.alive(s_) and _w16slot(view.dfn, s_) < lo:
            lo = _w16slot(view.dfn, s_)
    return lo


def _s165_rules(category, skill, actor, view, element=0, rec_flags7=None):
    """-> (veto, bonus, penalty) of the S165 rules (each only in the chains that hold it)."""
    opp = 0 if actor >= 4 else 4
    own = actor & 4
    bonus = penalty = 0
    tier2 = view.dd0b is not None and view.dd0b[actor] == 2       # LoadBtlAI_7c6e: `ret nz`
    st = view.status
    # $4AF6 (chains 1 / 2): a spell is vetoed when a LIVE foe reflects (+4 & $22: Bounce /
    # MagicBack's marks)
    if skill in IDS_4AF6 and _in(category, 0x4AF6):
        if any(view.alive(s_) and st[s_][4] & 0x22 for s_ in range(opp, opp + 3)):
            return True, 0, 0
    # $5EE5 (1 / 2): ... and when NO live foe is without the marks (every foe reflects, or none
    # is alive)
    if skill in IDS_5EE5 and _in(category, 0x5EE5):
        if not any(view.alive(s_) and not st[s_][4] & 0x22 for s_ in range(opp, opp + 3)):
            return True, 0, 0
    # $4B3D (1 / 2): a breath is vetoed when the foes' side byte ($DB00 + side) has $60, or a
    # live foe has +4 & $48 — or bit 1 of the byte 8 after its +0 … +4 read: `ld a, [hl+]` then
    # three `inc hl` land on +8 = the NEXT slot's +0 (slot 7: $DB40) — a vanilla slip
    if skill in IDS_4B3D and _in(category, 0x4B3D):
        if st[0][opp >> 2] & 0x60:
            return True, 0, 0
        for s_ in range(opp, opp + 3):
            if not view.alive(s_):
                continue
            nxt = st[s_ + 1][0] if s_ + 1 < 8 else (view.db40[0] if view.db40 else 0)
            if st[s_][4] & 0x48 or nxt & 0x02:
                return True, 0, 0
    # $5F1F (1 / 2 / 3): vetoed unless a live foe has +7 & $C0 clear
    if skill in IDS_5F1F and _in(category, 0x5F1F):
        if not any(view.alive(s_) and not st[s_][7] & 0xC0 for s_ in range(opp, opp + 3)):
            return True, 0, 0
    # $4A94 (2 / 3; the cleverest AI): vetoed unless a live foe KNOWS a breath (LoadBtlAI_7b7d:
    # its option list holds $5C-$63 / $6A-$6D before $FF)
    if skill in IDS_4A94 and _in(category, 0x4A94) and tier2 and view.skills is not None:
        def knows(s_):
            for sk in _opt_skills(view, s_):
                if sk == 0xFF:
                    return False
                if sk in BREATHS_7B7D:
                    return True
            return False
        if not any(view.alive(s_) and knows(s_) for s_ in range(opp, opp + 3)):
            return True, 0, 0
    # $5B4A (2; cleverest): vetoed unless a live, unsealed (+3 bit 0) foe knows a skill
    # < $1B or $1C / $1D / $20 / $21 / $DA before $FF
    if skill in IDS_5B4A and _in(category, 0x5B4A) and tier2 and view.skills is not None:
        def casts(s_):
            for sk in _opt_skills(view, s_):
                if sk == 0xFF:
                    return False
                if sk in LIST_5B4A:
                    return True
            return False
        if not any(view.alive(s_) and not st[s_][3] & 0x01 and casts(s_)
                   for s_ in range(opp, opp + 3)):
            return True, 0, 0
    # $6C0F (2; cleverest; $26): vetoed unless a foe's list (alive or not — no slot check) holds
    # a skill whose record +6 (damage class) is not 0 before $FF
    if skill == 0x26 and _in(category, 0x6C0F) and tier2 and view.skills is not None:
        def hurts(s_):
            for sk in _opt_skills(view, s_):
                if sk == 0xFF:
                    return False
                if damage_class(sk):
                    return True
            return False
        if not any(hurts(s_) for s_ in range(opp, opp + 3)):
            return True, 0, 0
    # $59F7 (2; cleverest; $26 / $7F): +10 when, scanning the foes' lists in slot order (no slot
    # check), an entry is $FF or one of $4F $59 $5B $64 $65 $D9 — a list of fewer than 8 options
    # ends in $FF, so nearly always
    if skill in IDS_59F7 and _in(category, 0x59F7) and tier2 and view.skills is not None:
        if any(sk == 0xFF or sk in LIST_59F7 for s_ in range(opp, opp + 3)
               for sk in _opt_skills(view, s_)[:8]):
            bonus += 10
    # $4E76 (1; $3F / $40): +10 when a live foe's DEF >= twice the ATK of the FIRST foe slot
    # (GetCombatantATK is called with A = the foes' base — not the caster; `add hl, hl` wraps)
    if skill in IDS_4E76 and _in(category, 0x4E76) and view.atk is not None \
            and view.dfn is not None:
        two = (_w16slot(view.atk, opp) * 2) & 0xFFFF
        if any(view.alive(s_) and _w16slot(view.dfn, s_) >= two for s_ in range(opp, opp + 3)):
            bonus += 10
    # $54E4 (2; cleverest): +10 when an own slot (any of the three — no slot check) has
    # min/2 <= ATK and ATK/2 < min, min = the lowest DEF of the live foes, the first foe slot
    # counting 0 when it is not alive (LoadBtlAI_62e0 / LoadBtlAI_6321)
    if skill in IDS_54E4 and _in(category, 0x54E4) and tier2 and view.atk is not None \
            and view.dfn is not None:
        lo = _min_def_62e0(view, opp)
        for s_ in range(own, own + 3):
            a = _w16slot(view.atk, s_)
            if a >= lo >> 1 and (a >> 1) < lo:
                bonus += 10
                break
    # $5660 (2; cleverest; $20-$23): +10 when a live own monster is slower than the live foes'
    # average AGL (sum / count; none -> $FFFF); then +10 when the own average AGL < the word
    # at $DB58 — never set by the rule (a vanilla bug: whatever an earlier routine left there)
    if skill in IDS_5660 and _in(category, 0x5660) and tier2 and view.agl is not None:
        def avg(base):
            live = [s_ for s_ in range(base, base + 3) if view.alive(s_)]
            return _div16x8(sum(_w16slot(view.agl, s_) for s_ in live) & 0xFFFF, len(live))
        a_opp = avg(opp)
        if any(view.alive(s_) and _w16slot(view.agl, s_) < a_opp for s_ in range(own, own + 3)):
            bonus += 10
        if view.db58 is not None and avg(own) < view.db58:
            bonus += 10
    # $5F91 (1 / 2 / 3): vetoed unless a foe is CAPABLE (GetMonsterSlotInfo NC: valid, alive,
    # +2 & $D0, +5 & $3F, +7 & $C0 all clear)
    if skill in IDS_5F91 and _in(category, 0x5F91):
        if not any(view.alive(s_) and not st[s_][2] & 0xD0 and not st[s_][5] & 0x3F
                   and not st[s_][7] & 0xC0 for s_ in range(opp, opp + 3)):
            return True, 0, 0
    # $47D9 (2; Surround $18): vetoed unless a live foe is not surrounded (+3 bit 1)
    if skill == 0x18 and _in(category, 0x47D9):
        if not any(view.alive(s_) and not st[s_][3] & 0x02 for s_ in range(opp, opp + 3)):
            return True, 0, 0
    # $62A8 (2; $18 / $72 / $73): vetoed unless a live foe is neither surrounded (+3 bit 1) nor
    # in a sandstorm (+7 & 3) and does not resist the record element fully (level 3)
    if skill in IDS_62A8 and _in(category, 0x62A8):
        if not any(view.alive(s_) and not st[s_][3] & 0x02 and not st[s_][7] & 0x03
                   and _lvl(view, s_, element) != 3 for s_ in range(opp, opp + 3)):
            return True, 0, 0
    # $63E3 (2; $1C / $1D / $7A — the DEF downs): vetoed unless a live foe has DEF >= 2 and
    # does not resist the record element fully (level 3)
    if skill in IDS_63E3 and _in(category, 0x63E3) and view.dfn is not None:
        if not any(view.alive(s_) and _w16slot(view.dfn, s_) >= 2 and _lvl(view, s_, element) != 3
                   for s_ in range(opp, opp + 3)):
            return True, 0, 0
    # $5BCD (2; Curse $6F): vetoed unless a live foe is not cursed (+2 bit 5)
    if skill == 0x6F and _in(category, 0x5BCD):
        if not any(view.alive(s_) and not st[s_][2] & 0x20 for s_ in range(opp, opp + 3)):
            return True, 0, 0
    # $4B8C (1; cleverest; the record's flags $DD6B bit 7): -20 when a live foe has bit 5 of the
    # byte at $DB08 + 8 s or bits 0 / 2 of $DB09 + 8 s (the 8 bytes past its $DB00 + 8 s row:
    # the next row's +0 / +1, $DB40 / $DB41 for slot 7)
    if _in(category, 0x4B8C) and tier2 and rec_flags7 is not None and rec_flags7 & 0x80:
        # the pointer walks 8 a live slot (`inc hl` + 7) but 7 a dead one (the skip jumps past
        # the `inc hl`) — after a dead foe it reads one byte early (a vanilla slip)
        ptr = 0xDB08 + 8 * opp
        for s_ in range(opp, opp + 3):
            if view.alive(s_):
                if _stbyte(view, ptr) & 0x20 or _stbyte(view, ptr + 1) & 0x05:
                    penalty += 20
                    break
                ptr += 8
            else:
                ptr += 7
    # $54BE (2; cleverest; $25 / $7A / $41): +20 when slot opp + 3 has min/2 <= ATK and
    # ATK/2 < min (min: as $54E4) — meant for the caster
    if skill in IDS_54BE and _in(category, 0x54BE) and tier2 and view.atk is not None \
            and view.dfn is not None:
        lo = _min_def_62e0(view, opp)
        # LoadBtlAI_62e0 leaves E = the foes' base + 3 (its loop counter), so LoadBtlAI_6321
        # reads the ATK of slot opp + 3 (a helper slot) — not the caster's (a vanilla slip)
        a = _w16slot(view.atk, opp + 3)
        if a >= lo >> 1 and (a >> 1) < lo:
            bonus += 20
    # $5739 (2; cleverest; Transform $29): +20 once the live foes, counted together (the count
    # is never reset per foe), reach 3 of: MaxHP >= the caster's, ATK >= its, DEF >= its — the
    # MaxMP compare's `jr` is unconditional, so MaxMP never counts (a vanilla slip)
    if skill == 0x29 and _in(category, 0x5739) and tier2 and view.atk is not None \
            and view.dfn is not None:
        # the caster's four values are read at word index 2 x actor (`add a` before
        # CalcBtlAI_4567 / the Get… helpers, which double again): for an enemy that lands in the
        # NEXT array (MaxHP -> MP, MaxMP -> ATK, ATK -> DEF, DEF -> AGL) — a vanilla slip
        i = 2 * actor
        c_hp, c_atk, c_def = (_word_at(view, 1, i), _word_at(view, 4, i), _word_at(view, 5, i))
        n = 0
        for s_ in range(opp, opp + 3):
            if not view.alive(s_):
                continue
            n += view.maxhp[s_] >= c_hp
            n += _w16slot(view.atk, s_) >= c_atk
            n += _w16slot(view.dfn, s_) >= c_def
            if n >= 3:
                bonus += 20
                break
    # $4890 (2; Upper $1E / Increase $1F): vetoed unless a live own monster's DEF is below its
    # cap and below 999 — the cap = the base DEF (BaseStatDEF_424a) x 4 for the party's three
    # (slots 0-2 outside a link battle) and x 2 for the enemies and the helper slot (16-bit,
    # `sla c / rl b` wraps)
    if skill in IDS_4890 and _in(category, 0x4890) and view.base_def is not None \
            and view.dfn is not None:
        ok = False
        for s_ in range(own, own + 3):
            if not view.alive(s_) or view.base_def[s_] is None:
                continue
            cap = view.base_def[s_] & 0xFFFF
            cap = (cap << (2 if s_ < 3 else 1)) & 0xFFFF
            d = _w16slot(view.dfn, s_)
            if d < cap and d < 999:
                ok = True
                break
        if not ok and any(view.alive(s_) and view.base_def[s_] is not None
                          for s_ in range(own, own + 3)):
            return True, 0, 0
        if not any(view.alive(s_) for s_ in range(own, own + 3)):
            return True, 0, 0
    return False, bonus, penalty


def _all_live_opposing_have(view, actor, off, mask):
    live = view.live_opposing(actor)
    return bool(live) and all(view.status[s][off] & mask for s in live)


def evaluate_chain(category, skill, actor, view, mp_cost, element,  # element = record status_id (res pos), S88
                   rec_flags7, pref=0, fixes=frozenset()):
    """(delta, veto) for one tag-matched skill, mirroring $78A2/$788B. [S161] `skill` = the id
    the rules see (a NEW skill's BASE, the caller maps it); mp_cost / element / rec_flags7 =
    the acting skill's own record; pref = a new skill's AI preference (-60 … +60), added at
    the chain end like one more rule (bank $72 AIPrefEnd72: > 0 to the bonus, < 0 to the
    penalty, capped below a veto). [S164] fixes = the project's switched-on fixes of the
    original rules' bugs (editor2/core/ai_fixes.AI_FIXES: aoe_count, class_count, family_cut,
    demagic_scan, averages); empty = the original game."""
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
    # S130 F10 ($45F2 tail, byte-read + measured): ThickFog $83, or any
    # flags7-bit6 spell, while the caster's OWN side byte has bit3 (sealed)
    if (skill == 131 or (rec_flags7 & 0x40)) and (view.status[0][(actor >> 2) & 1] & 0x08):
        return 0, True

    # S130 F9: AIRule_6757 (cat-2 chain): TatsuCall..BazooCall $84-$87 are
    # vetoed while the caster side's summon bit2 ($DB00/$DB01) is set AND
    # its helper slot (side|3) is live [byte-read; natural Hargon battle:
    # 2/4 rounds before the summon, 0/7 while the helper lived]
    if 0x84 <= skill <= 0x87:
        side = (actor >> 2) & 1
        if (view.status[0][side] & 0x04) and view.dd1b[(actor & 4) | 3] == 0:
            return 0, True

    # status-already-present vetoes [measured]
    # S163: $6444 (chains 1 / 2) exactly — PoisonHit / PoisonGas / PoisonAir are vetoed unless
    # a live opponent is unpoisoned (+2 & 3 clear) AND does not resist the record element
    # fully (level 3). The S81 HEAVY_TRIO / POISON_PAIR status-only vetoes were its shadow.
    if skill in IDS_6444 and _in(category, 0x6444):
        opp = 0 if actor >= 4 else 4
        if not any(view.alive(s_) and not (view.status[s_][2] & 0x03)
                   and _lvl(view, s_, element) != 3 for s_ in range(opp, opp + 3)):
            return 0, True
    # S163: $4C13 (chains 1 / 2) — every cat-1/2 skill is vetoed when every live opponent
    # resists its record element fully (level 3) — S159 measured it; element 0 = position 0,
    # level 0 for every species, so it never vetoes (unless no opponent is alive)
    if _in(category, 0x4C13):
        if all(_lvl(view, s_, element) == 3 for s_ in view.live_opposing(actor)):
            return 0, True
    # S163: $6382 (chain 2) — StopSpell is vetoed unless a live opponent knows a skill < $3A
    # (or $D5 / $DA / $DC) in its option list, is not sealed (+3 bit 0) and does not resist
    # fully; needs the option lists (view.skills)
    if skill == 23 and _in(category, 0x6382) and view.skills is not None:
        opp = 0 if actor >= 4 else 4

        def spells(s_):
            for _tg, sk in (view.skills[s_] or [])[:8]:
                if sk == 0xFF:
                    return False
                if sk < 0x3A or sk in (0xD5, 0xDA, 0xDC):
                    return True
            return False
        if not any(view.alive(s_) and spells(s_) and not (view.status[s_][3] & 0x01)
                   and _lvl(view, s_, element) != 3 for s_ in range(opp, opp + 3)):
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
    if skill in UTIL_VETO_UNTRACED and view.skills is not None and view.dd0b is not None:
        v, b_, p_ = f10_rules(skill, actor, view, fixes)  # S130 F10
        if v:
            return 0, True
        bonus += b_; penalty += p_
    elif skill in SHUT_RULES or skill in UTIL_VETO_UNTRACED:
        return 0, True

    # family cuts [measured Smashlime bonus + all veto branches]
    if skill in CUT_FAMILY:
        fam = CUT_FAMILY[skill]
        if any(view.families[s] == fam
               for s in view.live_opposing(actor)):
            # S163: the +20 ($4C41 -> LoadBtlAI_44a7) tests the FIRST opposing slot only — a
            # vanilla bug: its loop `inc c / dec b / jr nz` jumps back to itself, never to the
            # test (the $6848 veto's own scan walks all three correctly)
            first = 0 if actor >= 4 else 4
            if 'family_cut' in fixes:                     # [S164] all three slots
                bonus += 20
            elif view.alive(first) and view.families[first] == fam:
                bonus += 20
        else:
            return 0, True
    # S164: MultiCut ($4F) also takes $4C41's +20 — its dispatch row is family 7's (the same
    # block as $4D, table $57:$4C65 row 7), but the $6848 veto covers $48-$4E only: a bonus,
    # never a veto (byte-read S164; the S163 model lacked it — the captured boards never had a
    # family-7 opponent in the first slot)
    if skill == MULTICUT and _in(category, 0x4C41):
        first = 0 if actor >= 4 else 4
        if 'family_cut' in fixes:
            if any(view.families[s_] == 7 for s_ in view.live_opposing(actor)):
                bonus += 20
        elif view.alive(first) and view.families[first] == 7:
            bonus += 20
    if skill == METALCUT:
        if any(view.traits[s] & 0x01
               for s in view.live_opposing(actor)):
            bonus += 20
        else:
            return 0, True

    # $4BCC element-aware +20 (S88, mapping PINNED: `element` = record
    # field +5 status_id = a res-array POSITION 0-27; byte = elem>>2 via
    # the $67BB-$67D9 accessor table, bit-pair = elem&3 via the $7AA6
    # shift cases; level = (res7[elem>>2] >> ((3-(elem&3))*2)) & 3 =
    # species resistances[elem-1]. The rule SELF-GATES on element == 0
    # ($4BCC: ld a,[$db4c]; or a; ret z). Withheld iff rsum > live count.
    if element and (_in(category, 0x4BCC) if category in CHAINS else skill in R_4BCC):
        live = view.live_opposing(actor)
        rsum = sum(view.resist_score(s, element) & 3 for s in live)
        if rsum <= len(live):
            bonus += 20
    # $4D56 (chain 1) — S163 decoded: the physical class (LoadBtlAI_7c7e); +10 when the
    # caster's ATK >= the opponents' 'average' DEF — which the vanilla code never computes
    # (LoadBtlAI_7dbe adds 0 into each DEF entry, so the sum stays 0; 1 or 2 live opponents ->
    # 0, any other count divides 0 by its high byte 0 -> $FFFF), then +5 when the ATK >= the
    # lowest DEF of a live opponent. Without the stats: the S81 +15.
    if skill in PHYS_7C7E and (_in(category, 0x4D56) if category in CHAINS else skill in R_4D56):
        if view.atk is None or view.dfn is None:
            bonus += 15
        else:
            live = view.live_opposing(actor)
            avg = _avg16([view.dfn[s_] for s_ in live]) if 'averages' in fixes \
                else _avg16_vanilla(len(live))
            if view.atk[actor] >= avg:
                bonus += 10
            low = min((view.dfn[s_] for s_ in live), default=0xFFFF)
            if view.atk[actor] >= low:
                bonus += 5
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
    if (skill in IDS_4E36 and _in(category, 0x4E36)) if category in CHAINS else skill in R_4E36:
        if 'aoe_count' in fixes:                          # [S164] 2+ live opponents
            if len(view.live_opposing(actor)) >= 2:
                bonus += 20
        elif view.alive(min(view.opposing(actor))):
            bonus += 20
    # $5D8E AoE-vs-lone -20 / RainSlash veto [decoded + measured]
    if (skill in IDS_5D8E and _in(category, 0x5D8E)) if category in CHAINS else skill in R_5D8E:
        if len(view.live_opposing(actor)) == 1:
            if skill == 87:
                return 0, True
            penalty += 20
    # class bonuses — S163 decoded (the S81 sets were the ids seen on one board): each counts
    # the eligible live opponents against their resistance to the record element
    # (_count_rule: the first opposing slot counted once more, as the vanilla code does)
    def alive_and(fn):
        return lambda s_: view.alive(s_) and fn(s_)
    if skill in IDS_5FFD and _in(category, 0x5FFD):                       # +20 incapacitate
        if _count_rule(view, actor, element, lambda s_: not _incapacitated(view, s_),
                       'class_count' in fixes):
            bonus += 20
    if skill in IDS_6180 and _in(category, 0x6180):                       # +10 poison
        if _count_rule(view, actor, element, alive_and(lambda s_: not view.status[s_][2] & 0x03),
                       'class_count' in fixes):
            bonus += 10
    if skill in IDS_61BC and _in(category, 0x61BC):                       # +10 Curse
        if _count_rule(view, actor, element, alive_and(lambda s_: not view.status[s_][2] & 0x20),
                       'class_count' in fixes):
            bonus += 10
    if skill in IDS_604A and _in(category, 0x604A):                       # +10 Surround / SandStorm
        if _count_rule(view, actor, element, alive_and(
                lambda s_: not view.status[s_][3] & 0x02 and not view.status[s_][7] & 0x03),
                'class_count' in fixes):
            bonus += 10
    if skill in IDS_60C8 and _in(category, 0x60C8):                       # +10 MP-takers
        if _count_rule(view, actor, element, alive_and(lambda s_: view.mp[s_] != 0),
                       'class_count' in fixes):
            bonus += 10
    if skill in IDS_6107 and _in(category, 0x6107) and view.dfn is not None:   # +10 DEF-down
        if _count_rule(view, actor, element, alive_and(lambda s_: view.dfn[s_] >= 2),
                       'class_count' in fixes):
            bonus += 10
    if skill in IDS_6144 and _in(category, 0x6144) and view.agl is not None:   # +10 AGL-down
        if _count_rule(view, actor, element, alive_and(lambda s_: view.agl[s_] >= 2),
                       'class_count' in fixes):
            bonus += 10
    # S164: $551B (chain 2; the cleverest AI only — $DD0B[actor] == 2, LoadBtlAI_7c6e) — a
    # defensive buff (Surround $18, Upper $1E, Increase $1F, SandStorm $72, Radiant $73,
    # SideStep $77) +10 when the opponents that are surrounded (+3 bit 1) or in a sandstorm
    # (+7 & 3) hit harder on average than twice the own side's average DEF. The original
    # divides their ATK sum by the sum's own high byte (Div16x8To16 with A = [$DB57]) and the
    # own average is never computed (FuncBtlAI_7dc5, see $4D56); [S164 averages] both real.
    # Byte-read S164 (bank $57 AIRule_551b); validated on the fixed and the original ROM by
    # simulator/validate_ai_fixes.py.
    if skill in IDS_551B and _in(category, 0x551B) and view.dd0b is not None \
            and view.dd0b[actor] == 2 and view.atk is not None and view.dfn is not None:
        elig = [s_ for s_ in view.opposing(actor) if view.alive(s_)
                and (view.status[s_][3] & 0x02 or view.status[s_][7] & 0x03)]
        if elig:
            tot = sum(view.atk[s_] for s_ in elig) & 0xFFFF
            own = view.live_own(actor)
            if 'averages' in fixes:
                q, avg = tot // len(elig), _avg16([view.dfn[s_] for s_ in own])
            else:
                q, avg = _div16x8(tot, tot >> 8), _avg16_vanilla(len(own))
            if (avg * 2) & 0xFFFF < q:
                bonus += 10
    # S163: $66FB (chain 1) — Ramming / Kamikaze +20 when a live opponent's HP exceeds 1.5 x
    # the caster's (16-bit)
    if skill in IDS_66FB and _in(category, 0x66FB):
        thr = (view.hp[actor] + (view.hp[actor] >> 1)) & 0xFFFF
        if any(thr < view.hp[s_] for s_ in view.live_opposing(actor)):
            bonus += 20
    # $5A4C Cover/Guardian with downed ally [measured]
    if skill in (136, 137):
        if any(view.dd1b[s] != 0xFF and
               (view.hp[s] == 0 or view.dd1b[s] == 1)
               for s in view.own(actor)):
            bonus += 20
    # $6C8C enemy-side-only +20 [measured; side gate byte-verified] (S163: its id ladder read
    # from the rule — the cuts $48-$4E, $D7 / $D8 are members too; chain 1 only)
    if ((skill in IDS_6C8C and _in(category, 0x6C8C)) if category in CHAINS else skill in R_6C8C) \
            and actor >= 4 and actor != 7:
        bonus += 20

    v_, b_, p_ = _s165_rules(category, skill, actor, view, element, rec_flags7)   # S165
    if v_:
        return 0, True
    bonus += b_
    penalty += p_

    if skill in CUSTOM_RULES:                             # S155: CustomAI57
        v, b_, p_ = CUSTOM_RULES[skill](skill, actor, view)
        if v:
            return 0, True
        bonus += b_; penalty += p_

    bonus = min(bonus, 0xFF)
    penalty = min(penalty, 0xFF)
    if pref > 0:                                          # [S161] AIPrefEnd72
        bonus = min(bonus + pref, 0xFF)
    elif pref < 0 and penalty < 0xFF:
        penalty = min(penalty - pref, 0xFE)
    if bonus < penalty:
        return 0, True
    return bonus - penalty, False


# --------------------------------------------------------------------------
# S130 F10: the cat-2 rules that select DeMagic $80 / ThickFog $83 (byte-read
# bank $57, measured with simulator/measure_f10_rules.py, validator
# simulator/validate_f10_rules.py). In chain order; every other cat-2 rule
# returns on these ids (static scan of the chain's id compares).
# --------------------------------------------------------------------------
BIG_SPELLS = {0x02, 0x05, 0x08, 0x0B, 0x0E, 0x11, 0x12, 0x13}   # $6B19 / $59BE sets


def _flat_st(view):
    """$DB00..$DB41 as one byte list (status blocks + the slot-7 pair)."""
    out = [x for blk in view.status[:8] for x in blk[:8]]
    out += [0] * (64 - len(out))
    return out + list(view.db40)


def _incapacitated(view, s):
    """GetMonsterSlotInfo ($00): carry for an invalid slot or +2&$D0 /
    +5&$3F / +7&$C0."""
    if view.dd1b[s] != 0:
        return True
    st = view.status[s]
    return bool(st[2] & 0xD0 or st[5] & 0x3F or st[7] & 0xC0)


def f10_rules(skill, actor, view, fixes=frozenset()):
    """(veto, bonus, penalty) of the DeMagic/ThickFog rules.

    DeMagic $80:
      AIRule_4785  veto when no VALID opponent has +2 bit6 clear (all paralysed).
      AIRule_5f91  veto when every opponent is invalid or incapacitated.
      AIRuleDeMagicVetoNoBuff_6bcb  veto unless the opponents' side byte & $2C, or the opposing
                   side's FIRST slot (the loop never advances c: that slot is
                   tested three times, valid or not) has +3&$3C, +4&$6F,
                   +5&$40, +7&$CC or shifted +8&$40 (the 'raised' marker).
      AIRuleDeMagicDebuffMalus_69cb  penalty 20 when a valid opponent has +3&$C2, +4&$10,
                   +7&$03 or shifted +8&$80 (debuffs DeMagic would lift).
      AIRuleDeMagicBuffCount_5842  ($DD0B==2 only) +20 once a running count reaches 3,
                   checked after each valid opponent: its +3&$3F bits, +4&$7F
                   bits, +5 bits 6/7, +7&$C0 (1), +7&$0C (1), shifted +8 bit6,
                   plus the CASTER's own side byte bits 2/3/5 (re-counted for
                   every valid opponent).
    ThickFog $83:
      AIRuleVetoUsability_45f2  own side sealed -> veto (in evaluate_chain).
      AIRuleThickFogVetoNoBigSpell_6af5  veto unless a valid opponent's option list has a tag-1
                   entry whose skill is in BIG_SPELLS (its second loop compares
                   the TAG with $2B — dead code, never vetoes).
      AIRuleThickFogBonus_593d  ($DD0B==2 only) own side: n = valid slots, k = option-list
                   skills < $3A or in {$D5,$DA,$DC} (to the first $FF); if
                   n >= k: +20 when the valid opponents' lists hold >= 2
                   BIG_SPELLS entries (all 8 entries scanned, tags ignored).
    """
    opp = 0 if actor >= 4 else 4
    own = actor & 4
    dd0b2 = view.dd0b[actor] == 2
    bonus = penalty = 0
    if skill == 128:
        if all(view.dd1b[s] != 0 or (view.status[s][2] & 0x40) for s in range(opp, opp + 3)):
            return True, 0, 0                                   # 4785
        if all(_incapacitated(view, s) for s in range(opp, opp + 3)):
            return True, 0, 0                                   # 5f91
        flat = _flat_st(view)
        # [S164 demagic_scan] the fixed loop reads the three opposing slots; the original reads
        # the first one three times (its loop never advances c)
        scan = range(opp, opp + 3) if 'demagic_scan' in fixes else (opp,)
        if not (flat[opp >> 2] & 0x2C or any(
                flat[8 * x + 3] & 0x3C or flat[8 * x + 4] & 0x6F or flat[8 * x + 5] & 0x40
                or flat[8 * x + 7] & 0xCC or flat[8 * x + 8] & 0x40 for x in scan)):
            return True, 0, 0                                   # 6bcb
        for s in range(opp, opp + 3):                           # 69cb
            if view.dd1b[s] != 0:
                continue
            b = 8 * s
            if flat[b + 3] & 0xC2 or flat[b + 4] & 0x10 or flat[b + 7] & 0x03 or flat[b + 8] & 0x80:
                penalty += 20
                break
        if dd0b2:                                               # 5842
            cnt = 0
            side = (actor >> 2) & 1
            for s in range(opp, opp + 3):
                if view.dd1b[s] != 0:
                    continue
                p = 8 * s + 3
                cnt += bin(flat[p] & 0x3F).count('1')
                cnt += bin(flat[p + 1] & 0x7F).count('1')
                cnt += bin(flat[p + 2] & 0xC0).count('1')
                cnt += (1 if flat[p + 4] & 0xC0 else 0) + (1 if flat[p + 4] & 0x0C else 0)
                cnt += 1 if flat[p + 5] & 0x40 else 0
                cnt += bin(flat[side] & 0x2C).count('1')
                if cnt >= 3:
                    bonus += 20
                    break
        return False, bonus, penalty
    if skill == 131:
        def entries(s):
            lst = view.skills[s] or []
            return [tuple(x) for x in lst[:8]] + [(0, 0xFF)] * (8 - len(lst[:8]))
        hit = False
        for s in range(opp, opp + 3):                           # 6af5
            if view.dd1b[s] != 0:
                continue
            for tg, sk in entries(s):
                if tg == 0:
                    break
                if tg == 1 and sk in BIG_SPELLS:
                    hit = True
                    break
            if hit:
                break
        if not hit:
            return True, 0, 0
        if dd0b2:                                               # 593d
            n = k = 0
            for s in range(own, own + 3):
                if view.dd1b[s] != 0:
                    continue
                n += 1
                for tg, sk in entries(s):
                    if sk == 0xFF:
                        break
                    if sk < 0x3A or sk in (0xD5, 0xDA, 0xDC):
                        k += 1
            if n >= k:
                d = 0
                for s in range(opp, opp + 3):
                    if view.dd1b[s] != 0:
                        continue
                    for tg, sk in entries(s):
                        if sk in BIG_SPELLS:
                            d += 1
                    if d >= 2:
                        break
                if d >= 2:
                    bonus += 20
        return False, bonus, penalty
    return False, 0, 0
