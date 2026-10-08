"""S130 F7 — stat buffs and debuffs (BATTLE_SKILL_SYSTEM §15.11 F7).

Skills: Sap $1C / Defence $1D (DEF down), Upper $1E / Increase $1F (DEF up),
Slow $20 / SlowAll $21 (AGL down), Speed $22 / SpeedUp $23 (AGL up), Surge
$81 (cure + restore lowered stats), UltraDown $82 (DEF+AGL down + Surround),
plus the stat parts of Transform $29 and SickLick $7A (callable helpers for
the F9 / F1 integrators).

Byte sources (bank $52 unless noted; all decoded S130 and measured on the
real save, corpus simulator/f7_events.json, validator simulator/validate_f7.py):

* BASE = the bank $57 entries 4-8 (`GetBase{MaxHP,MaxMP,ATK,DEF,AGL}_5270/528d/529f/52b1/52c6` ->
  `$DD72/73`): a party slot (and a 4th/helper slot 3/7, or any slot in a
  link battle) reads its RECORD stat (ReadMonsterWord +$52 MaxHP, +$56
  MaxMP, +$58 ATK, +$5A DEF, +$5C AGL); an enemy slot 4-6 reads its
  enemy_stats ROW (bank $14 entry 1 -> $DA1D.. for wTempEnemyId[slot-4]).
  Measured: equal to the battle-start stat for every slot in the corpus, so
  Board.base (pacing.make_board -> snapshot_base) is the right source.
  NOTE the entry-5 MaxHP read (`GetBaseMaxHP_5270`) caps at 999.
* Cap multiplier (`UpperStatCapCheck_6a13`, `StatCapMul_6af5`): x4 for a
  party target (slot < 4) or any target in a link battle ($C86C != 0), x2
  for an enemy target. It keys on the TARGET slot, not the caster.
* No ATK buff exists: Upper/Increase write wBattleDEF ($DBF3), Speed/
  SpeedUp wBattleAGL ($DC03); ATK ($DBE3) is only rewritten by Transform.
* Markers: $DB08+8t bit7 (lowered: `SetStatLoweredMark_5377`) / bit6 (raised:
  `SetStatRaisedMark_536c`); Transform sets both (`SetStatBothMarks_5382`, |= $C0).
  Phase 9 masks that byte with $C0 (it is the next block's +0), so both
  survive; for t = 7 the byte is $DB40 (outside Board.st -> b.ext).
* Nothing decays: only Surge (lowered side) and DeMagic (F10) undo them.
"""
from .. import battle as B
from .. import damage as D

SAP, DEFENCE, UPPER, INCREASE = 0x1C, 0x1D, 0x1E, 0x1F
SLOW, SLOWALL, SPEED, SPEEDUP = 0x20, 0x21, 0x22, 0x23
TRANSFORM, SICKLICK, SURGE, ULTRADOWN = 0x29, 0x7A, 0x81, 0x82

RT_SAP, RT_SLOW, RT_DEATH = 12, 13, 8          # resistance types (damage.CORE_RTYPE)
LOWERED, RAISED = 0x80, 0x40


# --------------------------------------------------------------------------
# markers ($DB08+8t)
# --------------------------------------------------------------------------
def marker(b, t):
    """$DB08+8t: slot t's shifted +8 byte (= block t+1's +0; $DB40 for t=7)."""
    if t < 7:
        return b.st[8 + 8 * t]
    return b.ext.get('f7_db40', 0)


def set_marker(b, t, bits):
    if t < 7:
        b.st[8 + 8 * t] |= bits
    else:
        b.ext['f7_db40'] = b.ext.get('f7_db40', 0) | bits


def clear_marker(b, t, bits):
    if t < 7:
        b.st[8 + 8 * t] &= ~bits & 0xFF
    else:
        b.ext['f7_db40'] = b.ext.get('f7_db40', 0) & ~bits & 0xFF


def cap_mult(b, t):
    """StatCapMul_6af5 / UpperStatCapCheck_6a13: x4 party target or link, x2 enemy."""
    return 4 if (b.link or t < 4) else 2


# --------------------------------------------------------------------------
# the four stat movers (exact 16-bit arithmetic as the ROM does it)
# --------------------------------------------------------------------------
def def_down(b, t):
    """StatDefDown_5dfc: needs DEF > 1 (CmpHLvsBC 1 vs DEF) and DEF != 0;
    DEF -= baseDEF>>1, floor 0. Returns the $DB56 amount, or None = fail
    (msg $BB). A base/2 of 0 still 'succeeds' (marker set, DEF unchanged)."""
    d = b.dfn[t]
    if d <= 1:
        return None
    amt = b.base['dfn'][t] >> 1
    b.dfn[t] = d - amt if d >= amt else 0
    return amt


def upper_cap_check(b, t):
    """UpperStatCapCheck_6a13 -> (carry, zero, bc). DEF >= 999 -> bc = 999;
    else bc = baseDEF * cap_mult; carry = DEF < bc, or DEF == bc (scf with
    Z set: the 'exactly at the cap' exit)."""
    d = b.dfn[t]
    if d >= 999:
        return d == 999, d == 999, 999
    cap = (b.base['dfn'][t] * cap_mult(b, t)) & 0xFFFF
    if d < cap:
        return True, False, cap
    return d == cap, d == cap, cap


def def_up(b, t):
    """StatDefUp_5e3e: fail (msg $BB) unless the pre-check returns carry
    with Z clear (DEF strictly below both 999 and the cap); then DEF +=
    baseDEF>>1 and, if the post-check has no carry (strictly above 999 or
    the cap), DEF := the check's BC (999 when DEF >= 999 — which can exceed
    a x2 cap below 999 — else the cap). DEF exactly AT 999 / the cap after
    the add stays. Returns the $DB56 amount actually added, or None."""
    c, z, _ = upper_cap_check(b, t)
    if not c or z:
        return None
    amt = b.base['dfn'][t] >> 1
    b.dfn[t] = (b.dfn[t] + amt) & 0xFFFF
    c, _z, bc = upper_cap_check(b, t)
    if not c:
        amt -= b.dfn[t] - bc
        b.dfn[t] = bc
    return amt & 0xFFFF


def agl_down(b, t):
    """StatAglDown_5eb4: needs AGL >= 2; amt = baseAGL>>1, minus 1 when
    AGL == amt; AGL -= amt, and on a borrow AGL := 1 ($DB56 = old AGL-1).
    Net: floor 1. Returns the $DB56 amount or None (msg $BB)."""
    g = b.agl[t]
    amt = b.base['agl'][t] >> 1
    dec = 1 if g == amt else 0
    if g < 2:
        return None
    amt = (amt - dec) & 0xFFFF
    if g >= amt:
        b.agl[t] = g - amt
        return amt
    b.agl[t] = 1
    return (g - 1) & 0xFFFF


def agl_cap_check(b, t):
    """AglUpStatCapCheck_6a49 -> (carry, bc): AGL >= 511 -> (False, 511);
    else bc = baseAGL * cap_mult, carry = AGL < bc."""
    g = b.agl[t]
    if g >= 0x1FF:
        return False, 0x1FF
    cap = (b.base['agl'][t] * cap_mult(b, t)) & 0xFFFF
    return g < cap, cap


def agl_up(b, t):
    """StatAglUp_5f08: fail unless AGL < 511 and < cap; AGL += baseAGL>>1;
    if the post-check fails (AGL >= 511 or >= cap), AGL := its BC (511, or
    the cap). Returns the $DB56 amount or None."""
    c, _ = agl_cap_check(b, t)
    if not c:
        return None
    amt = b.base['agl'][t] >> 1
    b.agl[t] = (b.agl[t] + amt) & 0xFFFF
    c, bc = agl_cap_check(b, t)
    if not c:
        amt -= b.agl[t] - bc
        b.agl[t] = bc
    return amt & 0xFFFF


# --------------------------------------------------------------------------
# hit rolls
# --------------------------------------------------------------------------
def debuff_roll(b, a, t, rtype, ladder, state):
    """SapHitRoll_5dcc (Sap class, res 12 = $DD2B bits 5:4) / _5e94 (Slow
    class, res 13 = bits 3:2): level 3 -> never (no RNG); $DB42[attacker]
    bit2 -> sure hit (Compare_6adc, no RNG); else the ladder on target +5
    (CheckTargetGuardB = LADDER_HIT_B; SickLick $7A uses HitLadderBeat_6749
    = LADDER_HIT_STATUS), one BattleRNG step inside a threshold."""
    lev = D.res_level(bytes(b.res[t * 7:t * 7 + 7]), rtype)
    if lev != 3 and (b.db42[a] & 0x04):
        return True, state
    return D.hit_roll(ladder, b.stb(t, 5), lev, state)


# --------------------------------------------------------------------------
# per-victim effects (one handler call = one victim; return (outcome, amt, state))
# --------------------------------------------------------------------------
def sap_one(b, a, t, state):
    """SkillSap $434A (Sap $1C / Defence $1D)."""
    hit, state = debuff_roll(b, a, t, RT_SAP, D.LADDER_HIT_B, state)
    if not hit:
        return 'rollmiss', None, state           # msg $B8
    amt = def_down(b, t)
    if amt is None:
        return 'fail', None, state               # msg $BB
    set_marker(b, t, LOWERED)
    return 'ok', amt, state


def upper_one(b, a, t, state):
    """SkillUpper $436D (Upper $1E / Increase $1F): no roll."""
    amt = def_up(b, t)
    if amt is None:
        return 'fail', None, state
    set_marker(b, t, RAISED)
    return 'ok', amt, state


def slow_one(b, a, t, state):
    """SkillSlow $4385 (Slow $20 / SlowAll $21)."""
    hit, state = debuff_roll(b, a, t, RT_SLOW, D.LADDER_HIT_B, state)
    if not hit:
        return 'rollmiss', None, state
    amt = agl_down(b, t)
    if amt is None:
        return 'fail', None, state
    set_marker(b, t, LOWERED)
    return 'ok', amt, state


def speed_one(b, a, t, state):
    """SkillSpeed $43A8 (Speed $22 / SpeedUp $23): no roll."""
    amt = agl_up(b, t)
    if amt is None:
        return 'fail', None, state
    set_marker(b, t, RAISED)
    return 'ok', amt, state


def surge_one(b, a, t, state):
    """SkillSurge $4BAB -> $53 entry 10 ($601C) on the target:
    +2 & $90 (sleep/confusion) -> $DD13[t] := 3 (SurgeSkipTurn_60a2: no action
    this round); +2 := 0; +3 &= $3C; +5 bit7 (EerieLite amp) cleared;
    +7 &= $FC (SandStorm/Radiant counter); then iff $DB08+8t bit7: clear it
    and raise AGL / DEF back to base when BELOW base (raised stats and the
    bit6 marker are untouched). No roll, no failure message."""
    s2 = b.stb(t, 2)
    if s2 & 0x90:
        b.dd13[t] = 3
    b.set_stb(t, 2, 0)
    b.set_stb(t, 3, b.stb(t, 3) & 0x3C)
    b.set_stb(t, 5, b.stb(t, 5) & 0x7F)
    b.set_stb(t, 7, b.stb(t, 7) & 0xFC)
    if marker(b, t) & LOWERED:
        clear_marker(b, t, LOWERED)
        if b.agl[t] < b.base['agl'][t]:
            b.agl[t] = b.base['agl'][t]
        if b.dfn[t] < b.base['dfn'][t]:
            b.dfn[t] = b.base['dfn'][t]
    return 'ok', None, state


def _ud_sub(cur, base):
    """$53 UltraDown sub 0/1 ($65BA/$661B): BC = max(base>>1, 1)
    (UltraDownMinOne_66e1); if cur - BC <= 0 then BC = cur - 1 (UltraDownClampAmt_66e8);
    cur -= BC with a borrow -> 0 (UltraDownSubFloor0_66d6). Returns (new, BC)."""
    bc = max(base >> 1, 1)
    if cur - bc <= 0:
        bc = (cur - 1) & 0xFFFF
    new = cur - bc
    if new < 0:
        new = 0
    return new & 0xFFFF, bc


def ultradown_one(b, a, t, state):
    """SkillUltraDown $4BB6: BattleCall_5c51 (BossProtectionGate passes $82;
    res 8 Death level, HitLadderKamikaze_6733 = LADDER_HIT_SACRIFICE; NO
    $DB42 sure-hit here), then UltraDownFloorCheck_6612 fails when DEF == 1 and
    AGL == 1 and +3 bit1 (Surround) all hold (msg $B8 for both failures).
    Success -> d9ed = 3, the $53 entry-12 machine ($65AC):
      sub 0 DEF: `_ud_sub` (floor 1); amount != 0 -> $DB08+8t bit7
      sub 1 AGL: same on AGL
      sub 2: +3 bit1 Surround set if clear (msg $98)
      sub 3: valid target -> $DB08+8t bit7 (unconditional marker)
      sub 4: d9ed += 3 (end)."""
    hit, state = D.hit_roll(D.LADDER_HIT_SACRIFICE, b.stb(t, 5),
                            D.res_level(bytes(b.res[t * 7:t * 7 + 7]), RT_DEATH), state)
    if not hit:
        return 'rollmiss', None, state
    if b.dfn[t] == 1 and b.agl[t] == 1 and (b.stb(t, 3) & 0x02):
        return 'rollmiss', None, state
    b.dfn[t], d_amt = _ud_sub(b.dfn[t], b.base['dfn'][t])
    if d_amt:
        set_marker(b, t, LOWERED)
    b.agl[t], g_amt = _ud_sub(b.agl[t], b.base['agl'][t])
    if g_amt:
        set_marker(b, t, LOWERED)
    if not (b.stb(t, 3) & 0x02):
        b.set_stb(t, 3, b.stb(t, 3) | 0x02)
    if b.valid(t):
        set_marker(b, t, LOWERED)
    return 'ok', (d_amt, g_amt), state


def sicklick_def(b, t):
    """SkillLushLicks $4AE7, SickLick $7A tail (after the F1 part: the
    target +5 bit3 already-licked check, the SapHitRoll_5dcc roll with res
    12 through HitLadderBeat_6749, and +5 bit3 := 1 on a hit): wBattleDEF[t]
    := 1 and $DB08+8t bit7 (SetStatLoweredMark_5377). LushLicks $79 skips this.
    For the F1 integrator: call after a SickLick hit."""
    b.dfn[t] = 1
    set_marker(b, t, LOWERED)


def sicklick_one(b, a, t, state):
    """The whole SkillLushLicks path for id $7A (so the F7 corpus can
    validate the DEF part in context): already (+5 bit3) -> no roll;
    roll = debuff_roll(res 12, LADDER_HIT_STATUS); hit -> +5 bit3 and
    sicklick_def. Owned by F1 for the status half."""
    if b.stb(t, 5) & 0x08:
        return 'already', None, state
    hit, state = debuff_roll(b, a, t, RT_SAP, D.LADDER_HIT_STATUS, state)
    if not hit:
        return 'rollmiss', None, state
    b.set_stb(t, 5, b.stb(t, 5) | 0x08)
    sicklick_def(b, t)
    return 'ok', None, state


def transform_mark(b, caster):
    """SkillTransform $446C (handler call): own $DB08+8t |= $C0 (both
    markers); the copy itself runs later in act state 5."""
    set_marker(b, caster, LOWERED | RAISED)


def transform_stats(b, caster, target):
    """TransformCopyStats_5f5e (act state 5, jr_052_6d20) — the STAT part only:
    MaxHP := target base MaxHP (capped 999, GetBaseMaxHP_5270), HP := min(HP,
    new MaxHP); MaxMP := target base MaxMP, MP := min(MP, new MaxMP);
    ATK/DEF/AGL := the target's BASE (source row/record — not its current,
    possibly buffed values). INT is not copied. Then own +3 bit5. The
    resistance copy (SetupBattle_52d8 -> $DD28), the skill list ($DC64) and
    the enemy-side $C1CA/$C1CD bookkeeping are F9 (not modelled here).
    The caster's own base (bank $57) is unchanged, so later Sap/Upper caps
    and Surge restores still key on the caster's ORIGINAL source stats."""
    bs = b.base
    mh = min(bs['maxhp'][target], 999)
    if b.hp[caster] >= mh:
        b.hp[caster] = mh
    b.maxhp[caster] = mh
    mm = bs['maxmp'][target]
    if b.mp[caster] >= mm:
        b.mp[caster] = mm
    b.maxmp[caster] = mm
    b.atk[caster] = bs['atk'][target]
    b.dfn[caster] = bs['dfn'][target]
    b.agl[caster] = bs['agl'][target]
    b.set_stb(caster, 3, b.stb(caster, 3) | 0x20)


PER_VICTIM = {SAP: sap_one, DEFENCE: sap_one, UPPER: upper_one, INCREASE: upper_one,
              SLOW: slow_one, SLOWALL: slow_one, SPEED: speed_one, SPEEDUP: speed_one,
              SURGE: surge_one, ULTRADOWN: ultradown_one}


# --------------------------------------------------------------------------
# round-driver wiring
# --------------------------------------------------------------------------
def victims(ctx):
    """tm 17/33 -> the resolved target; tm 18 (side) and tm 34 (all allies)
    sweep FORWARD from the resolved target to the end of its side (measured
    S130: Surge queued on slot 1 hit [1, 2] (never 0), Defence on 5 hit [5, 6]; the S89 rule for
    tm 18)."""
    tm = ctx.f.get('target_mode')
    if tm in (18, 34):
        return [(v, 1) for v in B.side_victims(ctx.b, ctx.t, start=ctx.t)]
    return [(ctx.t, 1)]


def handler(ctx):
    """ACTION_HANDLERS entry for every F7 id: the usual per-victim MISS
    machine (one RNG step; these records never dodge/block), then the
    handler body on the post-machine RNG (same frame, measured)."""
    fn = PER_VICTIM[ctx.sk]

    def body(c, v, div, state):
        out, amt, state = fn(c.b, c.a, v, state)
        c.log.append((c.a, 'f7', (c.sk, v, out, amt)))
        return 'done', None, state
    return B.default_victims(ctx, body, victims=victims(ctx))


def transform_handler(ctx):
    """Transform $29: handler (markers) then the state-5 stat copy from the
    resolved target. F9 owns the rest (res/skills/AI rewrite)."""
    def body(c, v, div, state):
        transform_mark(c.b, c.a)
        transform_stats(c.b, c.a, v)
        c.log.append((c.a, 'f7', (c.sk, v, 'ok', None)))
        return 'done', None, state
    return B.default_victims(ctx, body, victims=[(ctx.t, 1)])


for _sk in PER_VICTIM:
    B.ACTION_HANDLERS[_sk] = handler
    B.CORE_OVERRIDES[_sk] = 'stat'
B.ACTION_HANDLERS[TRANSFORM] = transform_handler
B.CORE_OVERRIDES[TRANSFORM] = 'stat'
