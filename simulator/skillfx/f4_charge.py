"""S130 F4 — CHARGE, CRITICAL HITS AND THE POST-CALC DAMAGE STAGE
(BATTLE_SKILL_SYSTEM §15.11 F4).

Skills: ChargeUP $41, Focus $54, SuckAir $43, HighJump $42, Massacre $3F,
EvilSlash $40, TwinHits $25, ALLCHANGE $A6 — and the GENERAL critical hit of
every flags8-bit4 skill (Attack, the slashes/cuts, PoisonHit..., BiAttack,
QuadHits, RainSlash, HitEnemy), plus the command-phase $DB42 "tension" roll
that sets the S89 x1.5 bit (and the sure-crit bit0).

Byte sources and what each model function stands for:

  crit_threshold   LoadBtlC_5ed9 ($53:$5ED9, now CritChanceRoll_5ed9): the
                   per-SPECIES byte at $53:$4025 + $DC3C[a] (party slots or a
                   link battle) / $53:$4102 + $DC3C[a] (non-link enemies);
                   values 0/1/2 kept, anything else (3) -> 4. Crit iff
                   RNG1 < threshold (out of 256). The tables are CRIT_PARTY /
                   CRIT_ENEMY below (221 bytes each, read from the ROM).
  crit_stage       act state $A ($53:$586A, before the $52 handler): flags8
                   & $70 == 0 -> nothing (+4 bit7 untouched); bit5 with the
                   attacker's +3 bit2 (TwinHits armed) -> no roll, no step;
                   bit4 clear -> +4 bit7 := 0; $DB42[a] bit0 or +3 bit3
                   (ALLCHANGE) -> SURE crit, no step; else ONE LoadBtlC_4e33
                   step + the threshold. A crit sets +4 bit7, prints $79/$7A
                   and SKIPS the $52 handler (d9ee B -> C).
  postcalc_f4      the bank $53 post-calc stage $53:$5912-$59C2 (POST_CALC
                   order 10, before the $DB42 x1.5 at 60): attacker +3 bit2
                   and flags8 bit5 -> $DB56 x2 and straight to $59C3
                   (TwinHits); else +4 bit7 -> cleared, damage := crit_damage
                   of the attacker's ATK (QuadHits $51: ATK>>1) — the
                   handler's value is discarded; else own +6 bit0 (ChargeUP)
                   and flags8 bit6 -> charge_mult; else own +6 bit4 (SuckAir)
                   and flags7 bit4 and id $5C-$63 -> charge_mult.
  crit_damage      SaveBtlC_5d73: q = ATK/10; q == 0 -> ATK; else r =
                   ((RNG2&3)<<8 | RNG1) reduced by q while > q (no step);
                   r even -> ATK + r/2, r odd -> ATK - r/2 (borrow -> ATK).
  charge_mult      SaveBtlC_5db1: ONE LoadBtlC_4e33 step; dmg*2 +
                   ((RNG2<<8|RNG1) mod max(dmg>>1, 1)) = x2 .. x2.5.
  setters          SkillChargeUP $46BE own +6 |= $03; SkillSuckAir $470F
                   |= $30; SkillFocus $4888 bit7; SkillTwinHits $43FB target
                   +3 bit2 (already set -> fail msg); SkillALLCHANGE $4F35
                   every live slot of the caster's side +3 bit3. The phase-9
                   rotate of +6 (battle.phase9_decay) makes ChargeUP/SuckAir
                   last exactly the NEXT round ($03 -> $01 -> 0, $30 -> $10
                   -> 0) and Focus's bit7 the next round's bit6.
  massacre         SkillMassacre $4683 (shared by EvilSlash): dead target ->
                   fail; Massacre -> own +4 bit7 (a forced crit, built by
                   postcalc_f4 from ATK with the RNG as found — no step);
                   EvilSlash: an incapacitated target (GetMonsterSlotInfo:
                   +2&$D0 / +5&$3F / +7&$C0) or RNG1 >= $A0 (no step, the
                   MISS step's state) -> the same crit, else msg $78 (no
                   damage, no apply).
  highjump         SkillHighJump $46CF: take-off (own +6 & $0C == 0) is
                   reached through the act-state-3 shortcut $53:$52F4 (d9ee
                   := $0B: no state-7 / MISS / crit step), sets +6 |= $0C and
                   ends the turn (d9ed 6); the landing turn (+6 & $0C, the
                   command loop keeps the queued $42 — pacing.commit_round)
                   runs the normal MISS machine, clears +6 &= $F3 inside the
                   handler, CalcSkillDefense x1.5 (SetupBattle_6979: d + d>>1).
                   While airborne the act-state-7 check ($53:$5411: target
                   +6&$0C vs flags9 bit5, msg $C1) and the MISS gate 1
                   (flags7 bit7 vs +6 bit2) fail every hit on the jumper with
                   no RNG step (battle.default_victims).
  followup         Focus's consumer, $52:$70A4 -> Jump_052_6f5b at the end of
                   every action: own +6 bit6 -> cleared; flags9 bit4 skill and
                   a live opposing slot (LoadBattle_7fd8) -> d9ed := $12 = the
                   per-actor setup again: the SAME actor acts its queued
                   action a second time (POST_ACTION_HOOKS).
  db42_commit_roll $58:LoadBtlFX_5a40 + LoadBtlFX_5ba1 (bank $58 commit path
                   jr_058_5478, every actor; only PARTY slots 0-2 of a non-link
                   battle roll): each is ONE GenerateRNG step then a ladder on
                   one of the four AI base arrays ($DC44 cat1 / $DC4C cat2 /
                   $DC54 cat3 / $DC5C w3) -> $DB42[a] |= bit. 5a40 picks the
                   bit by the queued skill (bit0 sure-crit for attacks, bit1,
                   bit2 sure-hit for status spells, bit4 free MP for heals,
                   bit5, bit7 dodge for +7&$0C); 5ba1 sets bit6 = the S89
                   x1.5 damage boost for attacks/spells (w3 >= $81: 1/2/4/8 in
                   256) and bit3 for $90. THE S89 "UNLOCATED SETTER".

Measured S130 on the user's save (u22 build): corpus simulator/
f4_events.json.gz (simulator/measure_f4.py, recipe simulator/measure_f4_plan.py),
validator simulator/validate_f4.py.
"""
from .. import battle as B
from .. import damage as D

CHARGEUP, HIGHJUMP, SUCKAIR, FOCUS = 0x41, 0x42, 0x43, 0x54
MASSACRE, EVILSLASH, TWINHITS, ALLCHANGE = 0x3F, 0x40, 0x25, 0xA6
QUADHITS = 0x51
MASK = 0xFFFF

# $53:$4025 (party slots / link) and $53:$4102 (enemies), one byte per
# species id 0-220 ($DC3C) — byte-read from the clean ROM (md5 1ca65793...).
CRIT_PARTY = bytes.fromhex(
    '0202020202030202030203020302020202020101010101010102010202020001'
    '0101010201010202010101010001020102020102010101010101010101010101'
    '0101000101010202030202020202030202020202020202010201020202020303'
    '0202020203020202030203010103020102020202010102030201010202010101'
    '0101010101010101010101010101010101010101000100000100000201020202'
    '0101020202020101010101020100020201020202020201020201010202010202'
    '0101020201010200010001000100000001000101000000000202010102')
CRIT_ENEMY = bytes.fromhex(
    '0000010000000100000000000001010100000000000101010001000100000001'
    '0101010101010001000000000001000000000100010001010001010101000101'
    '0101000000000001000001000101000001010101010101010000010100000101'
    '0001000100000001000001010103000000000100000000000100010101000101'
    '0100000101000100010100000001010101010101000000000000000001010101'
    '0101010000010100010101000100000101000000000100000100010001000101'
    '0101000000030300000000000000000000000000000000000000000000')


# --------------------------------------------------------------------------
# critical hits
# --------------------------------------------------------------------------
def crit_threshold(b, a):
    """LoadBtlC_5ed9: the attacker's species row (party table for slots 0-3
    or a link battle, enemy table otherwise); 0/1/2 kept, else 4. An
    unknown species (Board.species $FF) counts as 0."""
    tab = CRIT_PARTY if (b.link or a < 4) else CRIT_ENEMY
    sp = b.species[a]
    v = tab[sp] if 0 <= sp < len(tab) else 0
    return v if v in (0, 1, 2) else 4


def incapacitated(b, s):
    """GetMonsterSlotInfo carry on a live slot: +2&$D0, +5&$3F or +7&$C0."""
    return bool((b.stb(s, 2) & 0xD0) or (b.stb(s, 5) & 0x3F) or (b.stb(s, 7) & 0xC0))


def crit_stage(b, a, f, state):
    """Act state $A ($53:$586A). Returns (outcome, state): None = no crit
    stage (flags8 & $70 == 0), 'twin' = TwinHits armed (no roll), False /
    True = rolled or sure. Mutates the attacker's +4 bit7 like the engine."""
    f8 = f.get('flags8', 0)
    if not (f8 & 0x70):
        return None, state
    if (f8 & 0x20) and (b.stb(a, 3) & 0x04):
        return 'twin', state
    if f8 & 0x10:
        if (b.db42[a] & 0x01) or (b.stb(a, 3) & 0x08):
            b.set_stb(a, 4, b.stb(a, 4) | 0x80)
            return True, state
        state = B.rng_step(state)                       # LoadBtlC_4e33
        if B.rng1(state) < crit_threshold(b, a):
            b.set_stb(a, 4, b.stb(a, 4) | 0x80)
            return True, state
    b.set_stb(a, 4, b.stb(a, 4) & 0x7F)                 # jr_053_58ea
    return False, state


def crit_damage(atk, state):
    """SaveBtlC_5d73 (no RNG step): ATK +/- a remainder of the 10-bit
    ((RNG2&3)<<8)|RNG1 by ATK/10."""
    atk &= MASK
    q = atk // 10
    if q == 0:
        return atk
    bc = ((B.rng2(state) & 3) << 8) | B.rng1(state)
    while bc > q:                                       # CmpHLvsBC: q < bc
        bc -= q
    half = bc >> 1
    if not (bc & 1):
        return (atk + half) & MASK
    r = atk - half
    return atk if r < 0 else r


def charge_mult(dmg, state):
    """SaveBtlC_5db1: one RNG step, dmg*2 + (RNG2<<8|RNG1) mod max(dmg>>1,1)."""
    state = B.rng_step(state)
    bc = (dmg >> 1) or 1
    r = D.rng16_dividend(state) % bc
    return ((dmg << 1) + r) & MASK, state


def crit_atk(b, a, sk):
    """GetCombatantATK, halved for QuadHits ($53:$5961 cp $51)."""
    atk = b.atk[a]
    return atk >> 1 if sk == QUADHITS else atk


def postcalc_f4(b, a, v, sk, f, core, dmg, state):
    """$53:$5912-$59C2 (POST_CALC order 10): TwinHits x2 | crit from ATK |
    ChargeUP / SuckAir x2..2.5 — mutually exclusive, in this order."""
    f7, f8 = f.get('flags7', 0), f.get('flags8', 0)
    if (b.stb(a, 3) & 0x04) and (f8 & 0x20):
        return (dmg << 1) & MASK, state                 # TwinHits -> $59C3
    if b.stb(a, 4) & 0x80:
        b.set_stb(a, 4, b.stb(a, 4) & 0x7F)
        return crit_damage(crit_atk(b, a, sk), state), state
    v6 = b.stb(a, 6)
    if (v6 & 0x01) and (f8 & 0x40):
        return charge_mult(dmg, state)                  # ChargeUP
    if (v6 & 0x10) and (f7 & 0x10) and 0x5C <= sk < 0x64:
        return charge_mult(dmg, state)                  # SuckAir
    return dmg, state


# --------------------------------------------------------------------------
# setters / handlers
# --------------------------------------------------------------------------
def _self_or(mask):
    def fn(ctx, v, div, state):
        b, a = ctx.b, ctx.a
        b.set_stb(a, 6, b.stb(a, 6) | mask)
        ctx.log.append((a, 'f4-set', (ctx.sk, b.stb(a, 6))))
        return 'done', None, state
    return fn


def dmg_twinhits(ctx, v, div, state):
    """SkillTwinHits $43FB: target +3 bit2 (already set -> fail anim)."""
    b = ctx.b
    if b.stb(v, 3) & 0x04:
        ctx.log.append((ctx.a, 'twinhits-already', v))
    else:
        b.set_stb(v, 3, b.stb(v, 3) | 0x04)
        ctx.log.append((ctx.a, 'twinhits', v))
    return 'done', None, state


def dmg_allchange(ctx, v, div, state):
    """SkillALLCHANGE $4F35: every live slot of the caster's side +3 bit3."""
    b, a = ctx.b, ctx.a
    for s in range(a & 4, (a & 4) + 3):
        if b.valid(s):
            b.set_stb(s, 3, b.stb(s, 3) | 0x08)
    ctx.log.append((a, 'allchange', None))
    return 'done', None, state


def dmg_massacre(ctx, v, div, state):
    """SkillMassacre $4683 (Massacre + EvilSlash)."""
    b, a = ctx.b, ctx.a
    if not b.valid(v):
        return 'done', None, state
    if ctx.sk == EVILSLASH and not incapacitated(b, v) and B.rng1(state) < 0xA0:
        ctx.log.append((a, 'evilslash-fail', v))       # msg $78, no apply
        return 'done', None, state
    b.set_stb(a, 4, b.stb(a, 4) | 0x80)                 # postcalc_f4 builds it
    return 'dmg', 0, state


def dmg_highjump_land(ctx, v, div, state):
    """SkillHighJump landing (jr_052_46ee): +6 &= $F3, calcdef x1.5."""
    b, a = ctx.b, ctx.a
    b.set_stb(a, 6, b.stb(a, 6) & 0xF3)
    dmg, state = D.calc_skill_defense(b.atk[a], b.dfn[v], state, target_idx=v,
                                      arena=b.link, attacker_idx=a)
    return 'dmg', dmg + (dmg >> 1), state


def act_highjump(ctx):
    b, a = ctx.b, ctx.a
    if not (b.stb(a, 6) & 0x0C):
        # take-off: act state 3 -> d9ee $0B straight to the handler (no
        # state-7 / MISS / crit step), +6 |= $0C, d9ed := 6 (turn over)
        b.set_stb(a, 6, b.stb(a, 6) | 0x0C)
        ctx.log.append((a, 'highjump-up', ctx.t))
        return ctx.state
    return B.default_victims(ctx, dmg_highjump_land)


def massacre_pick(b, a, state):
    """bank $58 row [$3F] Massacre = TargetSlotResolver_6379: SIDE-BLIND slot
    fishing over CheckMonsterSlot (slot < 8, $DD1B == 0), RNG as found (no
    step): c = RNG1, b = RNG2; try c&7, b&7, c' = ((b&7)|c)&7, (c'|b)&7,
    (b+c')&7, then b -= 1 until (b&7) is live. Massacre can hit an ally.
    (EvilSlash's row is the plain-attack $41E9.)"""
    c, bb = B.rng1(state), B.rng2(state)
    live = lambda s: 0 <= s < 8 and b.valid(s)
    if live(c & 7):
        return c & 7, state
    if live(bb & 7):
        return bb & 7, state
    c = ((bb & 7) | c) & 7
    if live(c):
        return c, state
    if live((c | bb) & 7):
        return (c | bb) & 7, state
    if live((bb + c) & 7):
        return (bb + c) & 7, state
    if not any(b.valid(s) for s in range(8)):
        return None, state
    while True:
        bb = (bb - 1) & 0xFF
        if live(bb & 7):
            return bb & 7, state


def highjump_pick(b, a, state):
    """bank $58 row [$42] = LoadBtlFX_642c (uniform over the opposing side)."""
    return B.uniform_side_pick(b, (a & 4) ^ 4, state)


def followup(b, a, sk, f, state, log):
    """$52:$70A4 -> Jump_052_6f5b (POST_ACTION_HOOKS): Focus's +6 bit6."""
    if not (b.stb(a, 6) & 0x40):
        return state
    b.set_stb(a, 6, b.stb(a, 6) & 0xBF)
    if not (f.get('flags9', 0) & 0x10):
        log.append((a, 'focus-spent', sk))
        return state
    opp = (a & 4) ^ 4
    if not any(b.valid(s) for s in range(opp, opp + 3)) or not b.valid(a):
        return state
    b.dd13[a] = 2                                       # state $12 = state 0 again
    b.ext['f4_again'] = a
    log.append((a, 'focus-again', sk))
    return state


# --------------------------------------------------------------------------
# command phase: the $DB42 tension roll (bank $58)
# --------------------------------------------------------------------------
def _ladder_a(v, rng1):
    """jr_058_5b25: base >= $81 -> 1/2/4/8 (by $A2/$C3/$E4) vs RNG1."""
    if v < 0x81:
        return False
    b = 1 if v < 0xA2 else 2 if v < 0xC3 else 4 if v < 0xE4 else 8
    return rng1 < b


def _ladder_b(v, rng1):
    """jr_058_5b63: base < $80 -> 2/4/8/$10 (>= $60/$3F/$1E/else) vs RNG1."""
    if v >= 0x80:
        return False
    b = 2 if v >= 0x60 else 4 if v >= 0x3F else 8 if v >= 0x1E else 0x10
    return rng1 < b


def roll1_class(x):
    """LoadBtlFX_5a40's skill switch: (base index, bit, ladder) or None.
    base index 0 cat1 $DC44 / 1 cat2 $DC4C / 2 cat3 $DC54 / 3 w3 $DC5C."""
    if x < 0x12 or x in (0x14, 0x1B):
        return None
    if x < 0x1E or x in (0x20, 0x21):
        return (1, 0x04, 'A')
    if x < 0x2B or x == 0x32:
        return None
    if x < 0x37:
        return (2, 0x10, 'A')
    if x == 0x3A:
        return (0, 0x01, 'A')
    if x < 0x44 or x == 0x4F:
        return None
    if x < 0x52 or x == 0x55:
        return (0, 0x01, 'A')
    if x < 0x67:
        return None
    if x < 0x6A:
        return (0, 0x01, 'A')
    if x == 0x77:
        return (3, 0x80, 'B')
    if x < 0x7E:
        return (1, 0x04, 'A')
    if x == 0x81:
        return (2, 0x10, 'A')
    if x == 0x82:
        return (1, 0x04, 'A')
    if x == 0x8C:
        return (2, 0x20, 'B')
    if x in (0x8D, 0x8E, 0x90):
        return (0, 0x02, 'B')
    if x < 0x90:
        return None
    if x < 0x93:
        return (1, 0x04, 'A')
    if x < 0x96:
        return (2, 0x10, 'A')
    if x < 0xD6:
        return None
    if x < 0xD9:
        return (0, 0x01, 'A')
    return None


def roll2_class(x):
    """LoadBtlFX_5ba1's switch: $90 -> cat2 bit3 ladder B; attacks and
    spells (< $12, $3A, $44-$51, $55-$69, $D6-$D9) -> w3 bit6 ladder A."""
    if x == 0x90:
        return (1, 0x08, 'B')
    if x < 0x12 or x == 0x3A or 0x44 <= x < 0x52 or 0x55 <= x < 0x6A or 0xD6 <= x < 0xDA:
        return (3, 0x40, 'A')
    return None


def _apply(b, s, cls, bases, rng1):
    if cls is None:
        return
    idx, bit, lad = cls
    v = bases[idx]
    if (_ladder_a if lad == 'A' else _ladder_b)(v, rng1):
        b.db42[s] |= bit


def db42_commit_roll(b, s, bases, state):
    """LoadBtlFX_5a40 + LoadBtlFX_5ba1 for slot s after its commit (queued
    skill = b.queue[2s]); bases = (cat1, cat2, cat3, w3). Party slots 0-2
    of a non-link battle only (a link battle runs the private $C1ED RNG —
    not modelled). Incapacitated / dead -> nothing, no step. Returns state."""
    state = roll_5a40(b, s, bases, state)
    return roll_5ba1(b, s, bases, state)


def _rolls(b, s):
    return not (b.link or s >= 3 or not b.valid(s) or incapacitated(b, s))


def roll_5a40(b, s, bases, state):
    """LoadBtlFX_5a40: step; +6&$0C -> nothing; +7&$0C -> bit7 (w3, B);
    else roll1_class of the queued skill."""
    if not _rolls(b, s):
        return state
    state = B.rng_step(state)                           # LoadBtlFX_5c3e
    st6, st7 = b.stb(s, 6), b.stb(s, 7)
    if not (st6 & 0x0C):
        cls = (3, 0x80, 'B') if (st7 & 0x0C) else roll1_class(b.queue[2 * s])
        _apply(b, s, cls, bases, B.rng1(state))
    return state


def roll_5ba1(b, s, bases, state):
    """LoadBtlFX_5ba1: step; +6&$0C or +7&$0C -> nothing; else roll2_class."""
    if not _rolls(b, s):
        return state
    state = B.rng_step(state)                           # LoadBtlFX_5c3e
    if not (b.stb(s, 6) & 0x0C) and not (b.stb(s, 7) & 0x0C):
        _apply(b, s, roll2_class(b.queue[2 * s]), bases, B.rng1(state))
    return state


def phase9_clear_db42(b, state, log):
    """Phase 9 sub 0 ($50:$6ABC, S85 decay list): $DB42..$DB49 := 0 — the
    tension bits last one round (PHASE9_HOOKS; battle.phase9_decay leaves
    b.db42 alone)."""
    b.db42 = [0] * 8
    return state


# --------------------------------------------------------------------------
# registration
# --------------------------------------------------------------------------
def _register():
    reg, core = B.ACTION_HANDLERS, B.CORE_OVERRIDES
    for sk, mask, name in ((CHARGEUP, 0x03, 'charge'), (SUCKAIR, 0x30, 'suckair'),
                           (FOCUS, 0x80, 'focus')):
        reg[sk] = (lambda fn: (lambda ctx: B.default_victims(ctx, fn)))(_self_or(mask))
        core[sk] = name
    reg[TWINHITS] = lambda ctx: B.default_victims(ctx, dmg_twinhits); core[TWINHITS] = 'twinhits'
    reg[ALLCHANGE] = lambda ctx: B.default_victims(ctx, dmg_allchange); core[ALLCHANGE] = 'allchange'
    for sk in (MASSACRE, EVILSLASH):
        reg[sk] = lambda ctx: B.default_victims(ctx, dmg_massacre); core[sk] = 'crit'
    reg[HIGHJUMP] = act_highjump; core[HIGHJUMP] = 'calcdef'
    B.RERESOLVE_PICKERS[HIGHJUMP] = highjump_pick
    B.RERESOLVE_PICKERS[MASSACRE] = massacre_pick
    B.COMMIT_TARGETS.setdefault(MASSACRE, lambda b, s, state: massacre_pick(b, s, state))
    B.CRIT_STAGE = crit_stage
    B.POST_CALC.append((10, postcalc_f4))
    B.POST_CALC.sort(key=lambda x: x[0])
    B.POST_ACTION_HOOKS.append(followup)
    B.COMMIT_ROLL = db42_commit_roll
    B.PHASE9_HOOKS.append(phase9_clear_db42)


_register()
