"""S130 F6 — defence levels, interception, reflect and absorb
(BATTLE_SKILL_SYSTEM §15.11 F6).

Skills: Defence $8D / StrongD $8E / BladeD $90 (defence levels + the BladeD
counter), Dodge $8C, Cover $88 / Guardian $89 (guard marks), Barrier $24,
MagicWall $26, MagicBack $27 / Bounce $28, TailWind $8A / StormWind $8B,
SuckAll $8F, TakeMagic $1B, Imitate $7F.

Corpus simulator/f6_events.json (simulator/measure_f6.py, the user's real
save on the u22 build, both sides); validator simulator/validate_f6.py
(engine RNG + board injected at each waypoint, the S85 method).

Byte sources (bank $52 handlers unless noted; every claim measured S130):

SETTERS (handler body, after the act-time MISS step like any skill)
  SkillBladeD_Defense $4C81  own $DB09+8a := (hi nibble) | level, level =
        id-$8C for $8D/$8E (1/2), 4 for $90. A REPLACE, not an OR.
  SkillDodge $4C72           own $DB08+8a |= $20.
  SkillCover $4C31           d9ed := 3 -> $53 entry 4 ($4F4C) =
        battle.set_guard_mark (S89): Cover marks the target ally, Guardian
        both other allies.
  SkillBarrier $43C0         the 4 slots of the TARGET's side (incl. 3/7):
        a live slot gets +4 |= 4 (counted when newly set), a dead one
        +4 &= ~4; nothing new -> "no effect" (SetSkillAnimFlag).
  SkillMagicWall $4415       the 3 live slots of the CASTER's side: +5 |= $40
        (the guard row of every resistance ladder; persists, phase 9 never
        clears +5).
  SkillMagicBack $4434       $27: fails (msg $BB) on own +4 bit5, else
        +4 := (+4 & $DD) | $20; $28 Bounce: fails on bit1, else
        +4 := (+4 & $DD) | $02 — each REPLACES the other.
  SkillTailWind $4C3B        +4 |= $40 on the target; StormWind ($8B)
        walks the target forward to slot&3 == 2 (no life check) and sets
        the side byte $DB00/01 bit5 (message-only: $52:$7D7C).
  SkillSuckAll $4CA5         side byte bit6 already set -> nothing; else set
        it, $DB4A+side |= (slot&3)<<2, own $DB08+8a |= 2.
  SkillTakeMagic $4330       own +4 bit0 (already -> "no effect").
  SkillImitate $4B92         own $DB08+8a |= 8.
  Lifetimes: $DB08+8t/$DB09+8t are block t+1's +0/+1 -> phase 9 keeps
  only +8 & $C0 (F7 markers) and zeroes +9: guard marks, defence levels,
  Dodge, SuckAll, Imitate are ONE round; the side byte loses bits 6/4
  (SuckAll) but keeps bit5 (StormWind); $DB4A/4B &= 3. +4 bits 0/1/2/5/6
  (TakeMagic, Bounce, Barrier, MagicBack, TailWind) and +5 bit6 (MagicWall)
  persist until consumed / DeMagic.

POST-CALC ($53:$59EC, after the $DB42 x1.5 at $59C3; registered at order 80)
  n = $DB09+8t & 7 (the TARGET's level). n == 0 -> the Beserker stage
  ($5A44, F23 order 70). n & 3 == 0 (BladeD): flags7 bit7 (physical) ->
  >> 1, else unchanged; n & 3 != 0: flags7 bit0 (every spell, breath and
  physical skill) -> n odd (Defence): >> 1, else (StrongD) // 10
  (Div16x8To16); then target $DB42 bit1 -> >> 1 again (only on these
  paths). Mutually exclusive with Beserker, so order 70 vs 80 is exact.

BLADED COUNTER ($52:$6ECF -> $7BEC, act state 4 after an APPLIED hit the
  target survived): $DD6E == 0 (no Cover / dodge / reflect redirect on
  this victim), $DD6C & 8 == 0 (not an Imitate re-cast), target +9 bit2,
  flags7 bit7. Target incapacitated (GetMonsterSlotInfo) -> no counter, no
  RNG. Else one BattleRNG step; $DB42[t] bit3 -> RNG1 &= $FE; dmg>>1 == 0
  -> RNG1 := 1 (both WRITE the RNG state); RNG1 even -> counter: the
  attacker takes dmg>>1 (HP floor 0, KO).

INTERCEPTION (act state 7 $53:$5411, per victim fetch, before the iron
  gate and the MISS machine; $DD6C = reflect/re-cast code, 0 normally):
  1 SuckAll ($5458): breath (flags7 bit4) at a side with bit6: if $DD6C
    or the skill is $8F -> skip every check below; else the SuckAll user
    ((side) | $DB4A>>2 & 3) if capable takes this victim's place
    ($DD6C := 2) and the sweep ENDS after it; when the action is a group
    one and the user is still capable it then breathes the same skill
    back at the other side ($52:$71F8 -> $53 entry 9, $DD6C := $40):
    a full side sweep from the first live slot (bank $58 entry 8).
  2 Cover ($54D6): flags8 bit1 -> battle.guard_redirect ($DD6E := 4, the
    checks below are skipped; the protector must be CAPABLE — the S130 F6
    fix in guard_redirect). simulate_round does it for the first victim;
    later sweep victims here.
  3 Dodge ($554D, $DD6C == 0): flags7 bit7 vs a capable target whose
    $DB42 bit5 or (flags8 bit1 ? $DB08+8t : $DB06+8t) bit5 is set (every
    stock physical skill has flags8 bit1, so the +6 leg is unreachable) ->
    ClrBtlC_5091 (dodge_machine: RNG steps, maybe a new target, msg
    $7E/$7F), $DD6E := 2, then the Cover check on the result ($5678).
  4 TailWind ($5594): flags7 bit4 (not $43/$8F) vs target +4 bit6 ->
    the bit is CONSUMED and the breath reflected (code 1).
  5 MagicBack/Bounce ($55CA): flags8 bit0 vs target +4 & $22 -> Bounce
    (bit1) persists, else MagicBack bit5 is consumed; reflected (code 4).
  A reflection (CallBtlC_5e38) re-runs the skill with the REFLECTOR as
  attacker on the original caster only (single victim, its own target
  fetch: Cover applies, steps 1/3/4/5 do not), power by the reflector's
  side, no MP; then the original sweep continues with its next victim.

POST-VICTIM
  TakeMagic ($53:LoadBtlC_5cbc at the effect player, applied by entry 7
  in act state 5): a landed effect (damage > 0 or a status that took) of
  a flags9-bit0 skill on a capable-or-not live +4 bit0 target with
  $DD6C == 0 and $DD6E == 0 -> MP += min(record MP cost, MaxMP - MP).
  Imitate ($52:$7DD7, after every victim — also after a miss / dodge /
  block, the fail route $53:$583A; measured 58): not $7F itself, $DD6E == 0,
  $DD6C == 0, attacker not airborne (+6&$0C == $0C), target mode bit4,
  victim $DB08+8t bit3 and capable -> flags9 bit2 ? re-cast (msg $D3,
  $DD6C := 8, the imitator PAYS the MP through setup sub-state 2) :
  msg $D4.

NOT modelled (open items, S130_F6_NOTES.md): the F8 multi-hit loop and the
F5 handlers with their own MISS step (RobMagic) do not run the interception /
counter / Imitate hooks; $DB42 bit5 (the "shield grab" with the same dodge
machine at act state 6) has no known setter; the stale $D9F2 TakeMagic gain
on a later MISS route in the same round; the Imitate check after an iron
($BA) fail is presumed, not measured (the hook does not run there); a breath
at a SuckAll side whose first victim simulate_round already Cover-redirected
(the engine tests the absorb first).
"""
from .. import battle as B

DODGE, DEFENCE, STRONGD, BLADED = 0x8C, 0x8D, 0x8E, 0x90
COVER, GUARDIAN = 0x88, 0x89
BARRIER, MAGICWALL, MAGICBACK, BOUNCE = 0x24, 0x26, 0x27, 0x28
TAILWIND, STORMWIND, SUCKALL = 0x8A, 0x8B, 0x8F
TAKEMAGIC, IMITATE = 0x1B, 0x7F
SUCKAIR = 0x43
F6_IDS = (DODGE, DEFENCE, STRONGD, BLADED, COVER, GUARDIAN, BARRIER, MAGICWALL,
          MAGICBACK, BOUNCE, TAILWIND, STORMWIND, SUCKALL, TAKEMAGIC, IMITATE)

# reflect / re-cast codes ($DD6C)
RF_WIND, RF_ABSORB, RF_MAGIC, RF_IMITATE, RF_SUCKBACK = 0x01, 0x02, 0x04, 0x08, 0x40


# --------------------------------------------------------------------------
# board access: the shifted guard pair and the bytes outside the 64-byte st
# --------------------------------------------------------------------------
def g8(b, t):
    """$DB08+8t (= block t+1's +0; $DB40 for t = 7, kept in ext 'f7_db40'
    like F7's markers)."""
    return b.st[8 + 8 * t] if t < 7 else b.ext.get('f7_db40', 0)


def set_g8(b, t, v):
    if t < 7:
        b.st[8 + 8 * t] = v & 0xFF
    else:
        b.ext['f7_db40'] = v & 0xFF


def g9(b, t):
    """$DB09+8t (= block t+1's +1; $DB41 for t = 7): hi nibble = guard
    protector, lo nibble = defence level."""
    return b.st[9 + 8 * t] if t < 7 else b.ext.get('f6_db41', 0)


def set_g9(b, t, v):
    if t < 7:
        b.st[9 + 8 * t] = v & 0xFF
    else:
        b.ext['f6_db41'] = v & 0xFF


def db4a(b):
    """$DB4A/$DB4B (per side): bits 3:2 = the SuckAll user's slot&3."""
    v = b.ext.get('f6_db4a')
    if v is None:
        v = b.ext['f6_db4a'] = [0, 0]
    return v


def side_of(s):
    return (s >> 2) & 1


def capable(b, s):
    """GetMonsterSlotInfo ($00): live, not +2&$D0 (asleep/paralysed/
    confused), no pending one-shot (+5&$3F), no iron (+7&$C0)."""
    return (b.valid(s) and not (b.stb(s, 2) & 0xD0) and not (b.stb(s, 5) & 0x3F)
            and not (b.stb(s, 7) & 0xC0))


# --------------------------------------------------------------------------
# setters (the handler bodies; t = wBattleTargetIdx, a = attacker)
# --------------------------------------------------------------------------
def set_defence(b, a, t, sk):
    lev = 4 if sk == BLADED else sk - 0x8C
    set_g9(b, a, (g9(b, a) & 0xF0) | lev)
    return 'ok'


def set_dodge(b, a, t, sk):
    set_g8(b, a, g8(b, a) | 0x20)
    return 'ok'


def set_cover(b, a, t, sk):
    B.set_guard_mark(b, a, t if sk == COVER else None)
    return 'ok'


def set_barrier(b, a, t, sk):
    n = 0
    base = t & 4
    for c in range(base, base + 4):
        o = c * 8 + 4
        if not b.valid(c):
            b.st[o] &= ~0x04 & 0xFF
        elif not (b.st[o] & 0x04):
            b.st[o] |= 0x04
            n += 1
    return 'ok' if n else 'fail'


def set_magicwall(b, a, t, sk):
    base = a & 4
    for c in range(base, base + 3):
        if b.valid(c):
            b.set_stb(c, 5, b.stb(c, 5) | 0x40)
    return 'ok'


def set_magicback(b, a, t, sk):
    v = b.stb(a, 4)
    bit = 0x02 if sk == BOUNCE else 0x20
    if v & bit:
        return 'fail'
    b.set_stb(a, 4, (v & 0xDD) | bit)
    return 'ok'


def set_tailwind(b, a, t, sk):
    for _ in range(8):
        if t > 7:
            break
        b.set_stb(t, 4, b.stb(t, 4) | 0x40)
        if sk == TAILWIND:
            break
        if (t & 3) == 2:
            b.st[side_of(t)] |= 0x20
            break
        t += 1
    return 'ok'


def set_suckall(b, a, t, sk):
    s = side_of(a)
    if b.st[s] & 0x40:
        return 'fail'
    b.st[s] |= 0x40
    db4a(b)[s] |= (a & 3) << 2
    set_g8(b, a, g8(b, a) | 0x02)
    return 'ok'


def set_takemagic(b, a, t, sk):
    if b.stb(a, 4) & 0x01:
        return 'fail'
    b.set_stb(a, 4, b.stb(a, 4) | 0x01)
    return 'ok'


def set_imitate(b, a, t, sk):
    set_g8(b, a, g8(b, a) | 0x08)
    return 'ok'


SETTERS = {DEFENCE: set_defence, STRONGD: set_defence, BLADED: set_defence,
           DODGE: set_dodge, COVER: set_cover, GUARDIAN: set_cover,
           BARRIER: set_barrier, MAGICWALL: set_magicwall,
           MAGICBACK: set_magicback, BOUNCE: set_magicback,
           TAILWIND: set_tailwind, STORMWIND: set_tailwind,
           SUCKALL: set_suckall, TAKEMAGIC: set_takemagic, IMITATE: set_imitate}


# --------------------------------------------------------------------------
# post-calc: defence levels ($53:$59EC)
# --------------------------------------------------------------------------
def defence_divide(b, v, flags7, dmg):
    """$53:$59EC-$5A3A on $DB56 (see the module docstring)."""
    n = g9(b, v) & 7
    if n == 0:
        return dmg
    if (n & 3) == 0:
        if not (flags7 & 0x80):
            return dmg
        dmg >>= 1
    else:
        if not (flags7 & 0x01):
            return dmg
        dmg = dmg >> 1 if n & 1 else dmg // 10
    if b.db42[v] & 0x02:
        dmg >>= 1
    return dmg


def postcalc_defence(b, a, v, sk, f, core, dmg, state):
    return defence_divide(b, v, f.get('flags7', 0), dmg), state


# --------------------------------------------------------------------------
# BladeD counter ($52:$6ECF / $7BEC)
# --------------------------------------------------------------------------
def counter_gate(b, v, flags7, dd6e, dd6c):
    """LoadBattle_6ecf: NZ -> the counter routine runs."""
    return dd6e == 0 and not (dd6c & 0x08) and bool(g9(b, v) & 0x04) and bool(flags7 & 0x80)


def counter_roll(b, v, dmg, state):
    """LoadBattle_7bec after the gate. Returns (outcome, state) with outcome
    None (target incapacitated: no RNG), 'counter' or 'nocounter'; `state`
    is the RNG after the step AND the RNG1 writes."""
    if not capable(b, v):
        return None, state
    state = B.rng_step(state)
    r1 = B.rng1(state)
    if b.db42[v] & 0x08:
        r1 &= 0xFE
    if (dmg >> 1) == 0:
        r1 = 1
    state = (r1 << 8) | (state & 0xFF)
    return ('nocounter' if r1 & 1 else 'counter'), state


def counter_apply(b, a, dmg):
    """Sub-state 1 of act state $13: the attacker's HP -= dmg>>1 (borrow ->
    0 -> KO). Returns (amount, ko)."""
    amt = dmg >> 1
    if amt == 0 or not b.valid(a):
        return amt, False
    return amt, B.apply_damage(b, a, amt)


# --------------------------------------------------------------------------
# Dodge: ClrBtlC_5091 ($53:$5091-$51A8), a literal transcription
# --------------------------------------------------------------------------
def _ok5192(b, e):
    """CallBtlC_5192: NC iff slot e is live and not airborne (+6&$0C)."""
    return 0 <= e < 8 and b.valid(e) and not (b.stb(e, 6) & 0x0C)


def dodge_machine(b, t, state, trace=None):
    """Returns (target, state, msg): msg $7E (the attack lands on the new
    target), $7F (stays on t) or None (t incapacitated: nothing). Each pass
    of the routine steps the RNG once; picking t itself re-runs it."""
    for _guard in range(64):
        if not capable(b, t):
            return t, state, None
        c = t
        state = B.rng_step(state)
        if trace is not None:
            trace.append(state)
        r1, r2 = B.rng1(state), B.rng2(state)
        if r1 < 0x33:
            lab = '5112'
        elif r1 < 0x66:
            lab = '5021'
        elif r1 < 0x99:
            lab = '5048'
        elif r1 < 0xCC:
            lab = '506b'
        else:
            lab = 'cc'
        e = None
        rerun = False
        for _step in range(64):
            if lab == '5112':
                if b.db42[t] & 0x20:
                    lab = '5021'; continue
                return t, state, 0x7F
            if lab == '5021':
                if (c & 4) == (t & 4):
                    c = (c & 4) ^ 4
                e = (c & 4) ^ 4
                if _ok5192(b, e):
                    lab = '5140'; continue
                e += 1
                if _ok5192(b, e):
                    lab = '5140'; continue
                e += 1
                lab = '5140'; continue
            if lab == '5048':
                d = (c & 4) ^ 4
                c = r2 & 2
                e = d | c
                if _ok5192(b, e):
                    lab = '5140'; continue
                e ^= 2
                if _ok5192(b, e):
                    lab = '5140'; continue
                e = d + 1
                lab = '5140'; continue
            if lab == '506b':
                d = (r2 & 1) + 1
                c = (c & 4) ^ 4
                e = (c + d) & 0xFF
                if _ok5192(b, e):
                    lab = '5140'; continue
                d ^= 3
                e = (c - d) & 0xFF
                if _ok5192(b, e):
                    lab = '5140'; continue
                e = c
                lab = '5140'; continue
            if lab == 'cc':
                bb = c & 4
                d = r2 & 1
                lo = c & 3
                if lo == 0:
                    d += 1
                    x = d
                elif lo == 1:
                    if d:
                        e = c + 1
                        if _ok5192(b, e):
                            lab = '5140'; continue
                        e = c - 1
                        if _ok5192(b, e):
                            lab = '5140'; continue
                        lab = '5130'; continue
                    e = c - 1
                    if _ok5192(b, e):
                        lab = '5140'; continue
                    e = c + 1
                    if _ok5192(b, e):
                        lab = '5140'; continue
                    lab = '5112'; continue
                else:
                    d += 1
                    x = (lo - d) & 0xFF
                # jr_053_50ce
                e = x | bb
                if _ok5192(b, e):
                    lab = '5140'; continue
                x = d ^ 3
                if x == 3:
                    x = 1
                e = x | bb
                if _ok5192(b, e):
                    lab = '5140'; continue
                e = c
                lab = '5130'; continue
            if lab == '5130':
                lab = '5021' if r1 < 0x55 else ('5048' if r1 < 0xAA else '506b')
                continue
            if lab == '5140':
                if not b.valid(e):
                    lab = '5112'; continue
                if e == t:
                    rerun = True
                    break
                return e, state, 0x7E
        if not rerun:
            return t, state, 0x7F
    return t, state, 0x7F


def dodge_gate(b, v, flags7, flags8, dd6c=0):
    """$53:$554D-$5578: the dodge machine runs."""
    if dd6c or not (flags7 & 0x80) or not capable(b, v):
        return False
    if b.db42[v] & 0x20:
        return True
    byte = g8(b, v) if (flags8 & 0x02) else b.stb(v, 6)
    return bool(byte & 0x20)


# --------------------------------------------------------------------------
# reflect checks ($53:$5594 TailWind, $55CA MagicBack/Bounce)
# --------------------------------------------------------------------------
def wind_reflects(b, v, sk, flags7):
    """LoadBtlC_5ca1 NZ."""
    return bool(flags7 & 0x10) and sk not in (SUCKAIR, SUCKALL) and bool(b.stb(v, 4) & 0x40)


def magic_reflects(b, v, flags8):
    return bool(flags8 & 0x01) and bool(b.stb(v, 4) & 0x22)


def consume_reflect(b, v, code):
    """TailWind: res 6. MagicBack/Bounce: Bounce (bit1) persists, else
    MagicBack bit5 is consumed ($DD6D = 7: the 'wall vanishes' message)."""
    if code == RF_WIND:
        b.set_stb(v, 4, b.stb(v, 4) & ~0x40 & 0xFF)
    elif not (b.stb(v, 4) & 0x02):
        b.set_stb(v, 4, b.stb(v, 4) & ~0x20 & 0xFF)


def absorber(b, v):
    """$53:$5458: the SuckAll user of v's side ((v&4) | $DB4A>>2&3)."""
    return (v & 4) | ((db4a(b)[side_of(v)] >> 2) & 3)


def intercept_check(b, a, v, sk, f, dd6c=0, guarded=False):
    """Pure decision of act state 7 for one victim (no RNG): returns one of
    ('absorb', user) | ('skip', None) [SuckAll side, checks skipped] |
    ('dodge', None) | ('wind', None) | ('magic', None) | (None, None).
    `guarded` = this victim was already Cover-redirected (simulate_round)."""
    f7, f8 = f.get('flags7', 0), f.get('flags8', 0)
    if (f7 & 0x10) and (b.st[side_of(v)] & 0x40):
        if dd6c or sk == SUCKALL:
            return 'skip', None
        u = absorber(b, v)
        if not capable(b, u):
            return 'skip', None
        return 'absorb', u
    if guarded or dd6c:
        return None, None
    if dodge_gate(b, v, f7, f8):
        return 'dodge', None
    if wind_reflects(b, v, sk, f7):
        return 'wind', None
    if magic_reflects(b, v, f8):
        return 'magic', None
    return None, None


# --------------------------------------------------------------------------
# TakeMagic and Imitate
# --------------------------------------------------------------------------
def takemagic_gain(b, v, mp_cost):
    """LoadBtlC_5cbc: gain = cost, capped so MP + gain <= MaxMP, floor 0."""
    room = b.maxmp[v] - b.mp[v]
    return max(0, min(mp_cost, room))


def imitate_gate(b, a, v, sk, f, dd6e=0, dd6c=0):
    """LoadBattle_7dd7: None (no check), 'recast' or 'cant' (msg $D4)."""
    if sk == IMITATE or dd6e or dd6c:
        return None
    if (b.stb(a, 6) & 0x0C) == 0x0C:
        return None
    if not (f.get('target_mode', 0) & 0x10):
        return None
    if not (0 <= v < 8) or not (g8(b, v) & 0x08) or not capable(b, v):
        return None
    return 'recast' if f.get('flags9', 0) & 0x04 else 'cant'


def first_live(b, base):
    """bank $58 LoadBtlFX_62d9: the first live slot from `base` (none ->
    base). Rows $62BF (opposing base) / $62CD (own base)."""
    for s in range(base, base + 3):
        if b.valid(s):
            return s
    return base


# --------------------------------------------------------------------------
# act-time targets (bank $58 BtlSkillTargetDispatch_401d rows)
# --------------------------------------------------------------------------
def row_self(b, a, state):
    """TargetSelfWrite_6367."""
    return a, state


def row_first_live_own(b, a, state):
    """TargetRowFirstLiveOwn_62cd."""
    return first_live(b, a & 4), state


def row_cover(b, a, state):
    """$58:$4ABA: $DD0B == 0 -> the uniform own-side pick ($6479, one RNG
    step); else the lowest score among the OTHER live own slots, score = HP
    (+$200 when metal, $DB8B bit0), ties to the later slot
    (LoadBtlFX_6224); no candidate -> self."""
    if b.dd0b[a] == 0:
        t, state = B.uniform_side_pick(b, a & 4, state)
        return (t if t is not None else a), state
    base = a & 4
    sc = []
    for s in range(base, base + 3):
        if not b.valid(s) or s == a:
            sc.append(0xFFFF)
        else:
            sc.append((b.hp[s] + (0x200 if b.db8b[s] & 1 else 0)) & 0xFFFF)
    i, hl = 0, sc[0]
    if hl >= sc[1]:
        i, hl = 1, sc[1]
    if hl >= sc[2]:
        i = 2
    t = base + i
    return (t if b.valid(t) else a), state


ROWS = {TAKEMAGIC: row_self, MAGICBACK: row_self, BOUNCE: row_self, IMITATE: row_self,
        TAILWIND: row_self, DODGE: row_self, DEFENCE: row_self, STRONGD: row_self,
        BLADED: row_self, BARRIER: row_first_live_own, MAGICWALL: row_first_live_own,
        GUARDIAN: row_first_live_own, STORMWIND: row_first_live_own,
        SUCKALL: row_first_live_own, COVER: row_cover}


def act_target(b, a, sk, qt, f, state):
    """Act-time target, the F5 act_target pattern ($53:SetupSub_4692):
    $FF -> the row; a dead queued target -> group: dead_redirect / single:
    kept for $DD0B==0 or tactic 3, else the row; a live one is re-resolved
    through the row unless battle.reresolves() says keep."""
    row = ROWS[sk]
    if qt == 0xFF:
        return row(b, a, state)
    if not b.valid(qt):
        if not (f.get('target_mode', 0) & 1):
            return B.dead_redirect(b, qt), state
        if b.dd0b[a] == 0 or b.dd03[a] == 3:
            return qt, state
        return row(b, a, state)
    if B.reresolves(b, a, sk):
        return row(b, a, state)
    return qt, state


# --------------------------------------------------------------------------
# the round driver glue (battle.py hook points)
# --------------------------------------------------------------------------
def _ext(b):
    return b.ext


def _subaction(ctx, attacker, target, code, single, state):
    """Run ctx.sk again with another attacker ($53 CallBtlC_5e38 /
    FuncBtlC_5de7: the reflector / SuckAll user / imitator acts; the
    original queue and attacker are restored afterwards, LoadBattle_7ef1)."""
    b = ctx.b
    prev = b.ext.get('f6_dd6c', 0)
    b.ext['f6_dd6c'] = code
    f = dict(ctx.f)
    if single:
        f['target_mode'] = 0x11            # one victim (the caster), not a sweep
    t = target
    f7, f8 = f.get('flags7', 0), f.get('flags8', 0)
    # the sub-action's own fetch: act state 7 with $DD6C != 0 -> Cover only
    # (a breath at a SuckAll side jumps past it; Imitate skips absorb)
    if not ((f7 & 0x10) and (b.st[side_of(t)] & 0x40) and code != RF_IMITATE):
        gt = B.guard_redirect(b, t, f8)
        if gt != t:
            ctx.log.append((attacker, 'guarded', t, gt))
            t = gt
    sub = B.ActionCtx(b=b, a=attacker, sk=ctx.sk, rec=ctx.rec, f=f, core=ctx.core, t=t,
                      qt=t, state=state, records=ctx.records, log=ctx.log, idle=ctx.idle,
                      real_sk=ctx.real_sk)
    saved_q = list(b.queue)
    b.queue[attacker * 2] = ctx.sk
    b.queue[attacker * 2 + 1] = t
    h = B.ACTION_HANDLERS.get(ctx.sk)
    state = h(sub) if h is not None else B.default_victims(sub)
    b.queue[:] = saved_q
    b.ext['f6_dd6c'] = prev
    return state


def hook_intercept(ctx, vi, v, state):
    """INTERCEPT_HOOKS entry (battle.default_victims): act state 7 for
    victim v. Returns (v, state, verdict) — verdict None (go on with v),
    'skip' (the hook resolved this victim: a reflection) or 'last' (act on
    v, then end the sweep: SuckAll)."""
    b, a, sk, f = ctx.b, ctx.a, ctx.sk, ctx.f
    dd6c = b.ext.get('f6_dd6c', 0)
    b.ext['f6_dd6e'] = 0
    guarded = False
    if vi == 0 and ctx.log and ctx.log[-1][0] == a and ctx.log[-1][1] == 'guarded' \
            and ctx.log[-1][3] == v:
        guarded = True                     # simulate_round's act-time Cover
        b.ext['f6_dd6e'] = 4
    kind, u = intercept_check(b, a, v, sk, f, dd6c, guarded)
    if kind == 'absorb':
        ctx.log.append((a, 'absorb', v, u))
        b.ext['f6_absorb'] = (u, dd6c)
        b.ext['f6_dd6c'] = RF_ABSORB       # SaveBtlC_5ece -> FuncBtlC_5de7(2)
        return u, state, 'last'
    if kind == 'skip' or guarded:
        return v, state, None
    f8 = f.get('flags8', 0)
    if vi > 0 and (f8 & 0x02) and sk not in B.BOSS_GATE_IN_HANDLER:
        gt = B.guard_redirect(b, v, f8)    # $54D6 on a later sweep victim
        if gt != v:                        # (F1 sweeps pre-guard their list)
            ctx.log.append((a, 'guarded', v, gt))
            b.ext['f6_dd6e'] = 4
            return gt, state, None
    if kind == 'dodge':
        nv, state, msg = dodge_machine(b, v, state)
        b.ext['f6_dd6e'] = 2
        ctx.log.append((a, 'dodge-move', v, nv, msg))
        gt = B.guard_redirect(b, nv, f8)   # $5678 on the new target
        if gt != nv:
            ctx.log.append((a, 'guarded', nv, gt))
            nv = gt
        return nv, state, None
    if kind in ('wind', 'magic'):
        code = RF_WIND if kind == 'wind' else RF_MAGIC
        consume_reflect(b, v, code)
        ctx.log.append((a, 'reflect', v, code))
        state = _subaction(ctx, v, a, code, True, state)
        return v, state, 'skip'
    return v, state, None


def hook_post_hit(ctx, v, dmg, state):
    """POST_HIT_HOOKS entry: after an applied non-KO hit and its rider,
    before the snap-out — the BladeD counter."""
    b, a = ctx.b, ctx.a
    if not counter_gate(b, v, ctx.f.get('flags7', 0), b.ext.get('f6_dd6e', 0),
                        b.ext.get('f6_dd6c', 0)):
        return state
    out, state = counter_roll(b, v, dmg, state)
    if out == 'counter':
        amt, ko = counter_apply(b, a, dmg)
        ctx.log.append((v, 'counter', (a, amt, ko)))
    elif out is not None:
        ctx.log.append((v, 'nocounter', a))
    return state


def _landed(ctx, v, kind, dmg):
    if kind == 'dmg':
        return dmg > 0
    if kind == 'done' and ctx.log:
        last = ctx.log[-1]
        if last[0] == ctx.a and isinstance(last[2], tuple):
            if last[1] in ('status', 'f1'):
                return last[2][-1] in ('hit', 'set')
            if last[1] == 'f7':
                return last[2][2] == 'ok'
    return False


def hook_post_victim(ctx, v, kind, dmg, ko, state):
    """POST_VICTIM_HOOKS entry: TakeMagic MP gain, then the Imitate check."""
    b, a, sk, f = ctx.b, ctx.a, ctx.sk, ctx.f
    dd6c, dd6e = b.ext.get('f6_dd6c', 0), b.ext.get('f6_dd6e', 0)
    if (not dd6c and not dd6e and not ko and 0 <= v < 8 and b.valid(v)
            and (b.stb(v, 4) & 0x01) and (f.get('flags9', 0) & 0x01)
            and _landed(ctx, v, kind, dmg)):
        g = takemagic_gain(b, v, f.get('mp_cost_byte', 0))
        b.mp[v] += g
        ctx.log.append((v, 'takemagic', g))
    im = imitate_gate(b, a, v, sk, f, dd6e, dd6c)
    if im == 'recast':
        ctx.log.append((v, 'imitate', a))
        cost = f.get('mp_cost_byte', 0)
        veto = B.act_mp_veto(b, v, sk, cost, f.get('flags7', 0))
        if veto not in (None, 'mp', 0x1F):
            B.act_mp_spend(b, v, sk, cost, f.get('flags7', 0))
        if veto is not None:
            ctx.log.append((v, 'imitate-veto', veto))
            return state
        B.act_mp_spend(b, v, sk, cost, f.get('flags7', 0))
        single = bool(f.get('target_mode', 0) & 1)
        t = a if single else first_live(b, (v & 4) ^ 4)
        state = _subaction(ctx, v, t, RF_IMITATE, single, state)
    elif im == 'cant':
        ctx.log.append((v, 'imitate-cant', a))
    return state


def hook_post_action(ctx, state):
    """POST_SWEEP_HOOKS entry: the SuckAll breath-back ($52:$71F8)."""
    b = ctx.b
    ab = b.ext.pop('f6_absorb', None)
    if ab is None:
        return state
    u, prev = ab
    b.ext['f6_dd6c'] = prev                # LoadBattle_7ef1 restore
    if (ctx.f.get('target_mode', 0) & 3) == 1 or not capable(b, u):
        return state
    t = first_live(b, (u & 4) ^ 4)
    ctx.log.append((u, 'suckall-back', t))
    return _subaction(ctx, u, t, RF_SUCKBACK, False, state)


def phase9_f6(b, state, log):
    """$50:$6ABC sub 0, the bytes outside Board.st: $DB4A/4B &= 3; $DB40
    &= $C0, $DB41 := 0 (slot 7's shifted pair)."""
    v = db4a(b)
    v[0] &= 3; v[1] &= 3
    b.ext['f7_db40'] = b.ext.get('f7_db40', 0) & 0xC0
    b.ext['f6_db41'] = 0
    return state


def _damage_fn(ctx, v, div, state):
    out = SETTERS[ctx.sk](ctx.b, ctx.a, v, ctx.sk)
    ctx.log.append((ctx.a, 'f6', (v, ctx.sk, out)))
    return 'done', None, state


def handler(ctx):
    """ACTION_HANDLERS entry for every F6 id: the MISS step on the one
    (resolved) target, then the setter."""
    return B.default_victims(ctx, _damage_fn, victims=[(ctx.t, 1)])


# --------------------------------------------------------------------------
# registration
# --------------------------------------------------------------------------
for _sk in F6_IDS:
    B.ACTION_HANDLERS[_sk] = handler
    B.CORE_OVERRIDES[_sk] = 'f6-setter'
    B.TARGET_RESOLVERS[_sk] = act_target
B.POST_CALC.append((80, postcalc_defence))
B.POST_CALC.sort(key=lambda x: x[0])
B.INTERCEPT_HOOKS.append(hook_intercept)
B.POST_HIT_HOOKS.append(hook_post_hit)
B.POST_VICTIM_HOOKS.append(hook_post_victim)
B.POST_SWEEP_HOOKS.append(hook_post_action)   # S130 merge: renamed list
B.PHASE9_HOOKS.append(phase9_f6)
