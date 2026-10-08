"""S130 F1 — STATUS APPLIERS AND ONE-SHOT COMPULSIONS (BATTLE_SKILL_SYSTEM
§15.11 F1). Every handler below is a bank $52 skill handler (SkillFunctionTable
$52:$4011) run once per VICTIM by the act machine, AFTER that victim's MISS
machine ($53:$5747, one BattleRNG step — measured: the helper's waypoint
RNG equals the MISS machine's post-step RNG, same frame). Byte sources are
named per function; corpus simulator/f1_status_events.json, validator
simulator/validate_f1.py.

Shape shared by every applier (byte-read, measured):
  1. 'already' test on the victim's status byte -> no roll, no RNG step;
  2. a HIT HELPER: resistance level from the packed $DD28+7t table (one
     2-bit type, see RTYPE), optionally Compare_6adc ($52:$6ADC: level 3 ->
     never; $DB42[attacker] bit2 -> SURE HIT, no step), optionally the
     BossProtectionGate ($53:$51AA via $52:$6B21: non-link, ENEMY target,
     $DB73==1, skill in {$12,$13,$14,$3E,$69,$6B,$71} -> fail, no step), then
     ONE ladder: 'B' = CheckTargetGuardB $52:$6710, 'S' = HitLadderBeat
     $52:$6749 (the status ladder), 'K' = HitLadderKamikaze $52:$6733;
     one BattleRNG step inside when the entry is a threshold, hit iff
     RNG1 < T;
  3. on hit: set the bit(s).

The helpers ($52), their resistance type and ladder:
  $5C51 rt 8  (no 6adc; boss gate first; id<$72 -> S, id==$82 -> K, else B)
  $5C8F rt 7  (6adc; id==$15 -> B else S)        Sleep $15/SleepAll $16/SleepAir $6A
  $5CBC rt 10 (6adc; B)                          StopSpell $17
  $5CDA rt 6  (6adc; id==$72 -> S else B)        Surround $18, SandStorm $72, Radiant $73
  $5D05 rt 11 (6adc; S)                          PanicAll $19, PaniDance $6E, LIFE $DA
  $5DCC rt 12 (6adc; id==$7A -> S else B)        SickLick $7A
  $65B5 rt 19 (boss gate; S)                     PalsyAir $6B
  $65C9 rt 18 (S)                                PoisonGas $6C, PoisonAir $6D
  $65D5 rt 20 (S)                                Curse $6F
  $65E3 rt 21 (id>=$7C -> S else B)              Ahhh $70, LureDance $78, LushLicks $79,
                                                 LegSweep $7B, BigTrip $7C, WarCry $7D
  $65FF       flyer ($DB8B bit4) -> fail, else $65E3   LegSweep/BigTrip
  $6692 rt 22 (B)                                DanceShut $91
  $669E rt 23 (B)                                MouthShut $92
(The $65xx/$66xx helpers do NOT call Compare_6adc: no $DB42 sure-hit.)

NB the status ladder $6749 tests bit7 ONLY (bit6 never consulted): a target
with BOTH +5 bit6 (guard row) and bit7 (amplify) rolls the amplify row there,
while damage.hit_roll picks the bit6 row first — so this module carries its
own exact ladder walk (ladder()).

"GetAttackerBattleSlot" ($52:$5422) is a misnomer: it loads wBattleTargetIdx
and returns $DB05+8*TARGET — every +5 one-shot lands on the victim (measured).
"""
from .. import battle as B
from .. import damage as D

# --------------------------------------------------------------------------
# exact hit ladders (thresholds: None = always, 0 = never, else RNG1 < T)
# --------------------------------------------------------------------------
_B_PLAIN, _B_GUARD, _B_AMP = (None, 0xD8, 0x7F, 0), (None, 0xBF, 0x66, 0), (None, None, 0xBF, 0)
_S_PLAIN, _S_AMP = (0xBF, 0x7F, 0x3F, 0), (None, 0xD8, 0x7F, 0)
_K_PLAIN, _K_GUARD, _K_AMP = (None, 0xBF, 0x66, 0), (0xBF, 0x7F, 0x3F, 0), (None, None, 0xBF, 0)


def ladder(kind, st5, lev):
    """Threshold of one hit ladder for the victim's +5 byte and res level.
    'B' $52:$6710: bit6 -> 680f, elif bit7 -> 6802, else 67ec.
    'S' $52:$6749: bit7 -> 67ec, else 6825 (bit6 NOT tested).
    'K' $52:$6733: bit6 -> 6825, elif bit7 -> 6802, else 680f."""
    if kind == 'S':
        return (_S_AMP if st5 & 0x80 else _S_PLAIN)[lev]
    if kind == 'B':
        row = _B_GUARD if st5 & 0x40 else (_B_AMP if st5 & 0x80 else _B_PLAIN)
    else:
        row = _K_GUARD if st5 & 0x40 else (_K_AMP if st5 & 0x80 else _K_PLAIN)
    return row[lev]


def roll(kind, st5, lev, state):
    """One ladder walk: (hit, state). One BattleRNG step only on a threshold."""
    t = ladder(kind, st5, lev)
    if t is None:
        return True, state
    if t == 0:
        return False, state
    state = B.rng_step(state)
    return B.rng1(state) < t, state


def res_lev(b, v, rtype):
    return D.res_level(bytes(b.res[v * 7:v * 7 + 7]), rtype)


def boss_gate(b, v, sk):
    """BossProtectionGate_51aa: True = BLOCKED (per victim; party targets,
    link battles and $DB73 != 1 pass)."""
    return (not b.link) and v >= 4 and b.db73 == 1 and sk in D.BOSS_PROTECTED_SKILLS | {0x69}


def sure_hit(b, a):
    """Compare_6adc: $DB42[attacker] bit2 (only reached for level != 3)."""
    return bool(b.db42[a] & 0x04)


# --------------------------------------------------------------------------
# helper table: sk -> (rtype, ladder kind, uses Compare_6adc, boss gate)
# --------------------------------------------------------------------------
def _helper(sk):
    if sk in (0x12, 0x13, 0x71, 0x74):            # $5C51
        return 8, ('S' if sk < 0x72 else 'K' if sk == 0x82 else 'B'), False, True
    if sk in (0x15, 0x16, 0x6A):                  # $5C8F
        return 7, ('B' if sk == 0x15 else 'S'), True, False
    if sk == 0x17:                                # $5CBC
        return 10, 'B', True, False
    if sk in (0x18, 0x72, 0x73):                  # $5CDA
        return 6, ('S' if sk == 0x72 else 'B'), True, False
    if sk in (0x19, 0x6E, 0xDA):                  # $5D05
        return 11, 'S', True, False
    if sk == 0x7A:                                # $5DCC
        return 12, 'S', True, False
    if sk == 0x6B:                                # $65B5
        return 19, 'S', False, True
    if sk in (0x6C, 0x6D):                        # $65C9
        return 18, 'S', False, False
    if sk == 0x6F:                                # $65D5
        return 20, 'S', False, False
    if sk in (0x70, 0x78, 0x79, 0x7B, 0x7C, 0x7D):  # $65E3
        return 21, ('S' if sk >= 0x7C else 'B'), False, False
    if sk == 0x91:                                # $6692
        return 22, 'B', False, False
    if sk == 0x92:                                # $669E
        return 23, 'B', False, False
    return None


HELPER_ADDR = {0x12: 0x5C51, 0x13: 0x5C51, 0x71: 0x5C51, 0x74: 0x5C51,
               0x15: 0x5C8F, 0x16: 0x5C8F, 0x6A: 0x5C8F, 0x17: 0x5CBC,
               0x18: 0x5CDA, 0x72: 0x5CDA, 0x73: 0x5CDA,
               0x19: 0x5D05, 0x6E: 0x5D05, 0xDA: 0x5D05, 0x7A: 0x5DCC,
               0x6B: 0x65B5, 0x6C: 0x65C9, 0x6D: 0x65C9, 0x6F: 0x65D5,
               0x70: 0x65E3, 0x78: 0x65E3, 0x79: 0x65E3, 0x7B: 0x65FF,
               0x7C: 0x65FF, 0x7D: 0x65E3, 0x91: 0x6692, 0x92: 0x669E}


def hit_helper(b, a, v, sk, state):
    """Run the skill's hit helper for victim v. Returns (outcome, state):
    'hit' | 'miss' | 'boss' (BossProtectionGate veto, no step)."""
    rtype, kind, cmp6adc, gated = _helper(sk)
    if gated and boss_gate(b, v, sk):
        return 'boss', state
    lev = res_lev(b, v, rtype)
    if cmp6adc and lev != 3 and sure_hit(b, a):
        return 'hit', state
    hit, state = roll(kind, b.stb(v, 5), lev, state)
    return ('hit' if hit else 'miss'), state


# --------------------------------------------------------------------------
# per-skill appliers: (already-test, apply) on the victim's status block
# --------------------------------------------------------------------------
# sk -> (offset, already-mask, or-mask, and-mask applied before the or)
SIMPLE = {
    # SkillSleep $52:$4235 (+2 & $8C already -> msg $BD), SleepApply_4262 |= $8C
    0x15: (2, 0x8C, 0x8C, 0xFF), 0x16: (2, 0x8C, 0x8C, 0xFF), 0x6A: (2, 0x8C, 0x8C, 0xFF),
    # SkillStopSpell $427C (+3 bit0), SkillSurround $42AA (+3 bit1)
    0x17: (3, 0x01, 0x01, 0xFF), 0x18: (3, 0x02, 0x02, 0xFF),
    # SkillPanicAll $42D8 (+2 bit4 already -> msg $BE)
    0x19: (2, 0x10, 0x10, 0xFF), 0x6E: (2, 0x10, 0x10, 0xFF), 0xDA: (2, 0x10, 0x10, 0xFF),
    # SkillPalsyAir $4954 (+2 bit6; fail msg $C3)
    0x6B: (2, 0x40, 0x40, 0xFF),
    # SkillPoisonGas $497B: $6C already on +2&3, sets bit0 clears bit1;
    #                       $6D already on bit1,  sets bit1 clears bit0
    0x6C: (2, 0x03, 0x01, 0xFD), 0x6D: (2, 0x02, 0x02, 0xFE),
    # SkillCurse $49D2 (+2 bit5)
    0x6F: (2, 0x20, 0x20, 0xFF),
    # one-shots on the VICTIM's +5 (the $5422 misnomer): Ahhh $4A00 bit5,
    # LureDance $4AC5 bit1, LushLicks/SickLick $4AE7 bit3, LegSweep/BigTrip
    # $4B34 bit2, WarCry $4B68 bit4
    0x70: (5, 0x20, 0x20, 0xFF), 0x78: (5, 0x02, 0x02, 0xFF), 0x79: (5, 0x08, 0x08, 0xFF),
    0x7A: (5, 0x08, 0x08, 0xFF), 0x7B: (5, 0x04, 0x04, 0xFF), 0x7C: (5, 0x04, 0x04, 0xFF),
    0x7D: (5, 0x10, 0x10, 0xFF),
    # SkillSandStorm $4A22 (victim +7 & 3 already; sets bits1:0)
    0x72: (7, 0x03, 0x03, 0xFF), 0x73: (7, 0x03, 0x03, 0xFF),
    # SkillEerieLite $4A57 (victim +5 bit7 already -> msg $BB): AMPLIFY row
    0x74: (5, 0x80, 0x80, 0xFF),
    # SkillDanceShut $4CDC (+3 bit6), SkillMouthShut $4D0A (+3 bit7)
    0x91: (3, 0x40, 0x40, 0xFF), 0x92: (3, 0x80, 0x80, 0xFF),
}
BEAT_IDS = (0x12, 0x13, 0x71)          # SkillBeat $41F7 (no 'already' test)
IRON_IDS = (0x2A, 0xDC)                # SkillIronize $447F / SkillIRONIZE $4479
SIDESTEP, BIGSLEEP, FREEZY = 0x77, 0xA7, 0xAC
F1_IDS = tuple(SIMPLE) + BEAT_IDS + IRON_IDS + (SIDESTEP, BIGSLEEP, FREEZY)


def ironize(b, a, t):
    """SkillIronize $52:$447F (IRONIZE $DC = $4479: target := attacker
    first). Non-link and an ENEMY-side target (bit2) -> only that slot;
    otherwise (party target, or link) the 4-slot loop over the target's
    side ($DB07+8s, slots base..base+3), CheckMonsterSlot-live only:
    +7 |= $C0 (iron counter 3). No roll, no RNG step. Returns the list of
    slots written."""
    if not b.link and (t & 4):
        slots = [t]
    else:
        base = t & 4
        slots = [s for s in range(base, base + 4) if b.valid(s)]
    for s in slots:
        if b.valid(s):
            b.set_stb(s, 7, b.stb(s, 7) | 0xC0)
    return slots


def apply_victim(b, a, v, sk, state):
    """One victim of an F1 skill, from the RNG after the victim's MISS
    machine step (same frame). Mutates the board. Returns (outcome, state):
    'already' | 'hit' | 'miss' | 'boss' | 'flyer' | 'dead' | 'set' | 'iron'
    | 'step'."""
    if sk in IRON_IDS:
        t = a if sk == 0xDC else v
        ironize(b, a, t)
        return 'iron', state
    if sk == SIDESTEP:
        # SkillSideStep $4AA3: BattleRNG FIRST (always), then the ATTACKER's
        # +7: bits3:2 empty -> +7 = (+7 & $F3) | ((RNG1 & 4) + 4).
        state = B.rng_step(state)
        v7 = b.stb(a, 7)
        if v7 & 0x0C:
            return 'already', state
        b.set_stb(a, 7, (v7 & 0xF3) | ((B.rng1(state) & 4) + 4))
        return 'step', state
    if sk == BIGSLEEP:
        # SkillBIGSLEEP $4F54: dead/invalid -> nothing; +2 bit7 -> msg $BD;
        # else +2 = (+2 & $73) | $8C. No roll.
        if not b.valid(v):
            return 'dead', state
        if b.stb(v, 2) & 0x80:
            return 'already', state
        b.set_stb(v, 2, (b.stb(v, 2) & 0x73) | 0x8C)
        return 'set', state
    if sk == FREEZY:
        # SkillFREEZY $4FCC: victim +5 bit0 one-shot (forced $12), no roll.
        if b.stb(v, 5) & 0x01:
            return 'already', state
        b.set_stb(v, 5, b.stb(v, 5) | 0x01)
        return 'set', state
    if sk in BEAT_IDS:
        # SkillBeat $41F7: $5C51 then BtlOutcomeHitPath_4200: $DD1B := 1,
        # HP := 0 (the KO state follows: $DD13 := $FF and the $DB02+8v..
        # +9 status wipe); miss -> msg $B8.
        o, state = hit_helper(b, a, v, sk, state)
        if o == 'hit':
            b.hp[v] = 0
            b.dd1b[v] = 1
            b.dd13[v] = 0xFF
            B.ko_wipe(b, v)             # the KO state's LoadBtlS_4c26 status wipe
        return o, state
    if sk == 0x7D and not b.valid(v):
        return 'dead', state                # SkillWarCry: CheckMonsterSlot first
    off, already, orm, andm = SIMPLE[sk]
    if b.stb(v, off) & already:
        return 'already', state
    if sk in (0x7B, 0x7C) and b.flying(v):
        return 'flyer', state               # BattleTarget_65ff: msg $C1, no roll
    o, state = hit_helper(b, a, v, sk, state)
    if o == 'hit':
        b.set_stb(v, off, (b.stb(v, off) & andm) | orm)
        if sk == 0x7A:
            # SickLick tail ($4B0D): victim DEF := 1 and SaveBattle_5377
            # sets $DB08+8v bit7 (the shifted record: slot v+1's +0) — the
            # F7 "DEF lowered" marker, which survives phase 9 (+0 &= $C0).
            b.dfn[v] = 1
            if v < 7:
                b.st[(v + 1) * 8] |= 0x80
    return o, state


# --------------------------------------------------------------------------
# victims
# --------------------------------------------------------------------------
def bigsleep_walk(b, t0):
    """$52:$714C, the 8-step walk BIGSLEEP's target_mode 1 runs: $DD69
    counts visited+skipped slots; at count 4 the walk jumps to the OTHER
    side's base (target & 4) ^ 4 without a validity test; otherwise target+1
    with CheckMonsterSlot (invalid -> count+1, keep walking); count 8 ends.
    Measured: queued 4 -> victims 4,5,6,0,1,2 (the caster's own side too)."""
    out = [t0]
    t, n = t0, 1
    while n < 8:
        if n == 4:
            t = (t & 4) ^ 4
            out.append(t); n += 1
            continue
        t += 1
        if 0 <= t < 8 and b.valid(t):
            out.append(t); n += 1
        else:
            n += 1
    return out


def victims(b, a, sk, f, t, guard=True):
    """Victim list of an F1 action. target_mode 18 = side sweep from the
    queued target forward (battle.side_victims, S89), each victim passing
    the Cover/Guardian table on its own (flags8 bit1 — every F1 sweep has
    it; S89 guard_redirect, not de-duplicated); BIGSLEEP = the $714C walk;
    everything else = the one (queued / resolved / guarded) target."""
    if sk == BIGSLEEP:
        return [(v, 1) for v in bigsleep_walk(b, t)]
    if f.get('target_mode') == 18:
        vs = B.side_victims(b, t)
        if guard:
            vs = [B.guard_redirect(b, v, f.get('flags8', 0)) for v in vs]
        return [(v, 1) for v in vs]
    return [(t, 1)]


# --------------------------------------------------------------------------
# registry glue (simulate_round)
# --------------------------------------------------------------------------
def _damage_fn(ctx, v, div, state):
    o, state = apply_victim(ctx.b, ctx.a, v, ctx.sk, state)
    ctx.log.append((ctx.a, 'f1', (v, ctx.sk, o)))
    return 'done', None, state


def _handler(ctx):
    vs = victims(ctx.b, ctx.a, ctx.sk, ctx.f, ctx.t)
    if ctx.sk == BIGSLEEP:
        # the walk's count-4 jump visits the other side's base unchecked;
        # an invalid slot there does nothing in the handler (CheckMonsterSlot)
        # — whether the MISS machine still steps for it is NOT measured.
        vs = [(v, d) for v, d in vs if ctx.b.valid(v)]
    return B.default_victims(ctx, damage_fn=_damage_fn, victims=vs)


for _sk in F1_IDS:
    B.CORE_OVERRIDES[_sk] = 'status'
    B.ACTION_HANDLERS[_sk] = _handler
    # S130 F1: the boss gate runs PER VICTIM inside the helper (after that
    # victim's MISS step) — simulate_round must not pre-block these.
    B.BOSS_GATE_IN_HANDLER.add(_sk)
