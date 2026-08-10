#!/usr/bin/env python3
"""DWM1 battle DAMAGE model (S78) — exact reimplementation of the bank-$52
damage pipeline, traced from the disassembly and differentially validated
against PyBoy captures of the real engine (see simulator/validate_damage.py).

Everything here mirrors named routines in disassembly/bank_052.asm:

  CalcSkillDefense  ($52:$60D7)  physical ATK-vs-DEF roll
  StoreDamageResult ($52:$66D6) + LoadBattle_679c  record power roll
  CheckTargetGuardA/B + BattleFunc_67EC..6879      resistance/guard outcome
  BattleFunc_67BB..67D9 (jr_052_67DC)              packed resistance fetch
  LoadBattle_653e / 641a / 6491 / BattleCall_6232 / BattleTarget_6214 ...
                                                   handler-computed specials

RNG: GenerateRNG is `state16 = state16*5 + $1357`, state = (RNG1<<8)|RNG2.
NOTE the asymmetry: the 16-bit dividend the damage code builds is
(RNG2<<8)|RNG1 (L=RNG1, H=RNG2) — low/high SWAPPED relative to the state.

Scope: DAMAGE + hit/miss magnitudes only. Turn order, AI move selection,
status-effect durations and the action pipeline are the next arc (S79+),
per documentation/PROJECT_COMPILER.md "Still missing: a combat model".
"""

MASK = 0xFFFF


def rng_step(state):
    """GenerateRNG (ROM0): state = state*5 + $1357 (16-bit).
    state = (RNG1<<8) | RNG2."""
    return (state * 5 + 0x1357) & MASK


def rng1(state):
    return (state >> 8) & 0xFF


def rng2(state):
    return state & 0xFF


def rng16_dividend(state):
    """The damage code's 16-bit RNG value: (RNG2<<8)|RNG1 (swapped)."""
    return ((state & 0xFF) << 8) | ((state >> 8) & 0xFF)


# --------------------------------------------------------------------------
# Resistance model
# --------------------------------------------------------------------------
# Species info bytes +$0F..+$29 hold 27 resistance LEVELS (0..3).  At battle
# init they are packed 2-bit MSB-first into 7 bytes per combatant at
# $DD28+slot*7, with bit-position 0 (byte0 bits7-6) unused: resistance type
# t sits at packed position t+1, i.e. byte (t+1)//4, bit-pair 3-((t+1)%4)
# counting from bits7-6.  Verified 15/15 against the FAQ element mapping
# (Blaze->Fire, Beat->Death, Kamikaze->Sacrifice, RockThrow->Aid, ...).

def res_level(res7, rtype):
    """res7: the 7 packed bytes for the combatant; rtype: 0..26."""
    pos = rtype + 1
    byte = res7[pos >> 2]
    shift = (3 - (pos & 3)) * 2
    return (byte >> shift) & 3


# Damage-multiplier ladders (CheckTargetGuardA family).  Keyed on target's
# battle status byte $DB05+slot*8: bit6 and bit7 modify the ladder.
# Each entry: function damage -> damage for res level 0..3.
def _x(hl, mul_num, den):        # helper: integer ops exactly as the ROM does
    return hl


def m_none(d):
    return d


def m_85(d):                     # SaveBattle_69a8: *$55(85) / $64(100)
    return (d * 85) // 100


def m_half(d):                   # HLsrl1
    return d >> 1


def m_zero(d):
    return 0


def m_75(d):                     # SaveBattle_69c6: d/2 + d/4
    return (d >> 1) + (d >> 2)


def m_40(d):                     # BattleCall_69e1: (*8/10) >> 1
    return ((d * 8) // 10) >> 1


def m_30(d):                     # BattleCall_69e8: (*6/10) >> 1
    return ((d * 6) // 10) >> 1


def m_13125(d):                  # SetupBattle_6980: d + d/4 + d/16
    return d + (d >> 2) + (d >> 4)


def m_115625(d):                 # SetupBattle_698b: d + d/8 + d/32
    return d + (d >> 3) + (d >> 5)


def m_quarter(d):                # HLsrl2
    return d >> 2


# CheckTargetGuardA ($52:$6753): damage skills.
#   no bit:  BattleFunc_683c -> [1, 0.85, 0.5, 0]
#   bit6:    BattleFunc_684f -> [1, 0.75, 0.40, 0]
#   bit7:    BattleFunc_6862 -> [1.3125, 1.15625, 0.75, 0.30]
LADDER_A = {
    0:    [m_none, m_85, m_half, m_zero],
    0x40: [m_none, m_75, m_40, m_zero],
    0x80: [m_13125, m_115625, m_75, m_30],
}

# BitCheck_676c ($52:$676C): breath/BigBang/RockThrow/MegaMagic damage.
#   no bit:  BattleFunc_684f -> [1, 0.75, 0.40, 0]
#   bit6:    BattleFunc_6879 -> [0.75, 0.5, 0.25, 0]
#   bit7:    BattleFunc_6862 -> [1.3125, 1.15625, 0.75, 0.30]
LADDER_BREATH = {
    0:    [m_none, m_75, m_40, m_zero],
    0x40: [m_75, m_half, m_quarter, m_zero],
    0x80: [m_13125, m_115625, m_75, m_30],
}


def apply_ladder(damage, ladder, status_byte, level):
    if status_byte & 0x40:
        row = ladder[0x40]
    elif status_byte & 0x80:
        row = ladder[0x80]
    else:
        row = ladder[0]
    return row[level](damage)


# Hit-probability ladders (CheckTargetGuardB / BitCheck families) —
# thresholds are `RNG1 < T` after one BattleRNG step; None = auto-hit,
# 0 = never.  Expressed as numerator/256.
T_D8, T_BF, T_7F, T_66, T_3F = 0xD8, 0xBF, 0x7F, 0x66, 0x3F

# BitCheck_6782 ($52:$6782) — ELEMENTAL SLASH modifier (FireSlash/BoltSlash/
# VacuSlash/IceSlash after CalcSkillDefense): bit6 set -> the plain damage
# ladder 683c; otherwise (bit7 NOT consulted) -> the amplify ladder 6862,
# i.e. a 1.3125x bonus vs res-0 targets, 0.30x floor vs immune.
LADDER_SLASH = {
    0:    LADDER_A[0x80],       # 6862 amplify
    0x40: LADDER_A[0],          # 683c plain
    0x80: LADDER_A[0x80],
}


def elemental_slash(phys_damage, status_byte, level):
    row = LADDER_SLASH[0x40] if (status_byte & 0x40) else LADDER_SLASH[0]
    return row[level](phys_damage)


def family_cut(phys_damage, target_family, wanted_family):
    """CheckIsSlime/Dragon/Beast/Flying/Plant/... (DrakSlash-class):
    CalcSkillDefense, then x1.5 (SetupBattle_6979) iff target family
    matches; else the plain roll."""
    if target_family == wanted_family:
        return phys_damage + (phys_damage >> 1)
    return phys_damage


def metal_cut(phys_damage, target_is_metal):
    """BattleCall_62dc: x1.5 + 1 iff the per-combatant metal flag
    ($DB8B+slot, bit0) is set; else the plain roll."""
    if target_is_metal:
        return phys_damage + (phys_damage >> 1) + 1
    return phys_damage


# CheckTargetGuardB ($52:$6710) — e.g. Beat/Defeat (death class):
#   no bit:  BattleFunc_67ec -> [always, D8, 7F, never]
#   bit6:    BattleFunc_680f -> [always, BF, 66, never]
#   bit7:    Compare_6802    -> [always, always, BF, never]
LADDER_HIT_B = {
    0:    [None, T_D8, T_7F, 0],
    0x40: [None, T_BF, T_66, 0],
    0x80: [None, None, T_BF, 0],
}

# BitCheck_6749 ($52:$6749) — the Beat/Defeat/K.O.Dance class (skill ids
# < $72 through BattleCall_5c51) and the status-chance helpers
# BattleCall_65b5/65c9.  bit6 is NOT consulted here — only bit7 branches:
#   bit7 clear: BattleFunc_6825 -> [BF, 7F, 3F, never]
#   bit7 set:   BattleFunc_67ec -> [always, D8, 7F, never]
# So an unguarded Beat vs death-res 0 is a 74.6% roll, not a sure hit
# (measured S78: wild-battle misses observed at res 0).
LADDER_HIT_STATUS = {
    0:    [T_BF, T_7F, T_3F, 0],
    0x40: [T_BF, T_7F, T_3F, 0],
    0x80: [None, T_D8, T_7F, 0],
}

# BitCheck_6733 ($52:$6733) — Kamikaze/Sacrifice-class:
LADDER_HIT_SACRIFICE = {
    0:    [None, T_BF, T_66, 0],
    0x40: [T_BF, T_7F, T_3F, 0],
    0x80: [None, None, T_BF, 0],
}


def hit_roll(ladder, status_byte, level, state):
    """Returns (hit: bool, new_state). Consumes one BattleRNG step when the
    ladder entry is a threshold."""
    if status_byte & 0x40:
        row = ladder[0x40]
    elif status_byte & 0x80:
        row = ladder[0x80]
    else:
        row = ladder[0]
    t = row[level]
    if t is None:
        return True, state
    if t == 0:
        return False, state
    state = rng_step(state)
    return rng1(state) < t, state


# --------------------------------------------------------------------------
# Physical roll — CalcSkillDefense ($52:$60D7), exact
# --------------------------------------------------------------------------

def calc_skill_defense(atk, dfn, state, target_idx=None, arena=False,
                       attacker_idx=None, zero_floor=True):
    """Returns (damage, new_state).  `state` is the RNG state BEFORE the
    routine runs (it advances it once, then reads RNG1/RNG2 repeatedly
    without further stepping).  target_idx enables the slot-2 0.8x rule
    (LoadBattle_61ec): in normal battles only party targets 1/2 are eligible
    and only slot 2 gets it; in arena mode ($C86C != 0) it keys on
    target_idx & 3 == 2 (jr_052_61bd path keys on the TARGET there; the
    61a9 path keyed on attacker belongs to a different caller)."""
    state = rng_step(state)
    r1, r2 = rng1(state), rng2(state)
    half_def = dfn >> 1

    if atk <= half_def:
        dmg = r1 & 1
    else:
        base = (atk - half_def) >> 1
        if (atk >> 4) >= base:
            # low-damage regime: uniform 0 .. (atk>>4 - 1)
            div = atk >> 4
            if div == 0:
                dmg = r1 & 1
            else:
                dmg = rng16_dividend(state) % div
        else:
            var_unit = base >> 3
            dmg = base
            if var_unit:
                rem = rng16_dividend(state) % ((var_unit & 0xFF) + 1)
                var = rem >> 1
                n = r2 & 0x0F
                if n == 0:
                    pass
                elif n & 8:
                    dmg += var
                else:
                    dmg -= var
            t = r1 & 3
            if t:
                dmg += 1 if (t & 1) else -1
            dmg &= MASK
    # LoadBattle_61ec: 3rd-slot 0.8x
    if target_idx is not None:
        eligible = False
        if arena:
            eligible = (target_idx & 3) == 2
        else:
            eligible = target_idx == 2
        if eligible:
            dmg = (dmg * 8) // 10
    # zero-damage floor: RNG2 & 1 (runs AFTER the slot-2 adjust, at the
    # tail of Jump_052_6183; zero_floor=False reproduces the value visible
    # at the LoadBattle_61ec waypoint, which validation hooks capture)
    if zero_floor and dmg == 0:
        dmg = r2 & 1
    return dmg, state


# --------------------------------------------------------------------------
# Record power roll — StoreDamageResult + LoadBattle_679c, exact
# --------------------------------------------------------------------------

def record_roll(pmin, prange, state):
    """damage = pmin + (RNG1 mod (prange+1)).  Does NOT advance the RNG —
    LoadBattle_679c reads the current RNG1 without calling GenerateRNG."""
    if prange == 0:
        return pmin, state
    return pmin + (rng1(state) % (prange + 1)), state


# --------------------------------------------------------------------------
# Handler-computed specials (each names its bank-$52 routine)
# --------------------------------------------------------------------------

def megamagic(mp, level, state, target_status=0, res=0):
    """LoadBattle_653e: base = mp*2 + level*2 (level from $DB9B+slot);
    variance v = ((base*8/10) >> 1) >> 2 (= 0.1x base); if v: one BattleRNG
    step, r = RNG16d % v (16x16 div remainder); RNG1&1 odd -> base - r,
    even -> base + r.  Resistance: MegaMagic type (15) through the BREATH
    ladder (BitCheck_676c at jr_052_65a7).  Measured S78: mp30/lvl20 ->
    93..102 around base 100; the historical "(MP*2+level*2)/4" note in
    BATTLE_SKILL_SYSTEM was wrong on both the divisor and the variance."""
    base = mp * 2 + level * 2
    v = (((base * 8) // 10) >> 1) >> 2
    dmg = base
    if v:
        state = rng_step(state)
        r = rng16_dividend(state) % v
        if rng1(state) & 1:
            dmg = base - r
        else:
            dmg = base + r
    dmg = apply_ladder(dmg, LADDER_BREATH, target_status, res)
    return max(dmg, 0), state


def windbeast(level, state, enemy_side, arena=False):
    """LoadBattle_641a (WindBeast): party base = 3*level+10, enemy
    (non-arena) base = level + level//2; cap 180 ($B4).  Variance = base*0.3
    (BattleCall_69e8); one BattleRNG step; rem = RNG16d % var; the shift-out
    bit of rem>>1 decides subtract (carry set) vs add."""
    if enemy_side and not arena:
        base = level + (level >> 1)
    else:
        base = 3 * level + 10
    base = min(base, 0xB4)
    var = ((base * 6) // 10) >> 1
    dmg = base
    if var:
        state = rng_step(state)
        rem = rng16_dividend(state) % var
        half, carry = rem >> 1, rem & 1
        dmg = base - half if carry else base + half
    return dmg, state


def vacuum(level, state, enemy_side, arena=False):
    """LoadBattle_6491 (Vacuum): party base = 2*level+30, enemy (non-arena)
    base = level + level//2; cap 150 ($96); variance unit = base//5; rem =
    RNG16d % unit; shift-out bit of rem>>1: carry -> subtract, else add."""
    if enemy_side and not arena:
        base = level + (level >> 1)
    else:
        base = 2 * level + 30
    base = min(base, 0x96)
    unit = base // 5
    dmg = base
    if unit:
        state = rng_step(state)
        rem = rng16_dividend(state) % unit
        half, carry = rem >> 1, rem & 1
        dmg = base - half if carry else base + half
    return dmg, state


def kamikaze_damage(caster_hp, target_hp=None, arena=False, db73=1):
    """BattleCall_6232 (Kamikaze; also the Sacrifice sweep core).  Hit is
    gated by the Sacrifice resistance (type 14) via LADDER_HIT_SACRIFICE
    (miss -> damage 0).  On hit:
      caster HP == 1                -> damage 1
      arena ($C86C != 0) or $DB73 == 0 -> damage = target current HP - 1
                                          (floors at 1) -- near-lethal
      normal battle ($DB73 == 1)   -> damage = (caster current HP - 1) >> 1
    $DB73 is 1 throughout normal battle processing (bank $51 init; $FF is
    the loss freeze) -- measured S78; the (casterHP-1)/2 branch is the one
    real wild battles take (caster HP 200 -> observed 99)."""
    if caster_hp == 1:
        return 1
    if arena or db73 == 0:      # arena OR wild battle: near-kill the target
        d = (target_hp or 1) - 1
        return d if d else 1
    return (caster_hp - 1) >> 1  # boss battle (db73 == 1)


def ramming_damage(target_hp):
    """BattleTarget_6214: damage = target current HP * 8/10 + 1, then the
    Sacrifice-type (14) level through LADDER_A."""
    return (target_hp * 8) // 10 + 1


# Simple physical-multiplier handlers (all: CalcSkillDefense result * k)
PHYS_MULT = {
    'Attack':      lambda d: d,                       # id 58 ($4625 group)
    'PoisonHit':   lambda d: d,
    'NapAttack':   lambda d: d,
    'Paralyze':    lambda d: d,
    'TwinSlash':   lambda d: d + (d >> 1),            # SetupBattle_6979 1.5x
    'PsycheUp':    lambda d: d + (d >> 1),
    'Beserker':    lambda d: d << 1,                  # 2x (sla)
    'SquallHit':   lambda d: (d * 8) // 10,           # 0.8x
    'Ahhh':        lambda d: d >> 1,                  # 0.5x
    'RainSlash1':  lambda d: (d * 8) // 10,           # hit 1: 0.8x
    'RainSlash2':  lambda d: (d * 6) // 10,           # hit 2: 0.6x
    'RainSlash3+': lambda d: ((d * 8) // 10) >> 1,    # hits 3-5: 0.4x
}

# BiAttack/QuadHits rewrite the attacker's ATK for the roll:
#   BiAttack:  ATK' = ATK*0.75  (SaveBattle_69c6), 2 hits
#   QuadHits:  ATK' = ATK/2 + ATK/8 = 0.625x, 4 hits, target = remembered
BIATTACK_ATK = lambda atk: (atk >> 1) + (atk >> 2)
QUADHITS_ATK = lambda atk: (atk >> 1) + (atk >> 3)

# CALLEVIL (boss assist): physical roll with ATK forced to $0190 = 400
CALLEVIL_ATK = 0x190

# ------------------------------------------------------------------------
# Boss protection gate — LoadBtlC_51aa (bank $53 entry $10), called from
# BattleCall_5c51 / BattleCall_65b5 via SetHLBattle_6b21.
# $DB73 = BATTLE TYPE, set at init by LoadBtlS_43c9 (bank $51):
#   arena ($C86C != 0)                    -> 2
#   wild encounter ($DA09 == 0)           -> 0
#   scripted battle w/ wScriptMapType $5D -> 2
#   scripted/boss battle otherwise        -> 1
#   ($FF = the loss-freeze value, end-of-battle only)
# The gate: these skills AUTO-FAIL against an ENEMY target when db73 == 1
# (boss battles), regardless of resistance:
BOSS_PROTECTED_SKILLS = {0x12, 0x13, 0x14, 0x3E, 0x69, 0x6B, 0x71}
#   $12 Beat, $13 Defeat, $14 Sacrifice, $3E Kamikaze, $69 Paralyze,
#   $6B (Allähmer/107), $71 K.O.Dance


def boss_gate_blocks(skill_id, target_is_enemy, db73, arena=False):
    return (not arena and target_is_enemy and db73 == 1
            and skill_id in BOSS_PROTECTED_SKILLS)


# element -> resistance type for the record-driven cores
CORE_RTYPE = {
    'Blaze': 0, 'Firebal': 1, 'Bang': 2, 'Infernos': 3, 'Bolt': 4,
    'IceBolt': 5, 'Surround': 6, 'Sleep': 7, 'Beat': 8, 'RobMagic': 9,
    'StopSpell': 10, 'PanicAll': 11, 'Sap': 12, 'Slow': 13, 'Sacrifice': 14,
    'MegaMagic': 15, 'FireAir': 16, 'FrigidAir': 17, 'PoisonGas': 18,
    'PalsyAir': 19, 'Curse': 20, 'LureDance': 21, 'DanceShut': 22,
    'MouthShut': 23, 'RockThrow': 24, 'GigaSlash': 25,
}
