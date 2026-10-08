"""S130 families F2 + F3 — single-hit physical variants, formula / HP-based
specials and the record-spell extras (BATTLE_SKILL_SYSTEM §15.11 F2/F3).

Every function names the engine routine it reproduces. Validated 10049/0
(86 rig battles, both sides, res 0-3, +5 rows, db73 0/1/2). Corpus:
simulator/f23_phys_events.json.gz (simulator/measure_f23_phys.py, real save, u22
build); validator: simulator/validate_f23_phys.py (per-victim RNG injection at the
core-entry waypoint, the S85 method).

F2 (bank $52 handlers -> CalcSkillDefense $60D7, then a multiplier):
  $44-$47 Fire/Bolt/Vacu/IceSlash  BattleCall_6298/62a9/62ba/62cb: the target's
        res 0 / 4 / 3 / 5 through ResLadderElemSlash_6782 (bit6 -> the plain
        row, otherwise the AMPLIFY row).
  $48 MetalCut  BattleCall_62dc: x1.5 + 1 iff $DB8B+t bit0 (metal).
  $49-$4E, $D6-$D8 family cuts  CheckIs* -> LookupTargetSpecies ($DC3C[t] ->
        bank $03 entry 1 -> $DA33 family): x1.5 (LoadDamageValue) on a match.
  $55 SquallHit x8/10 (DamageMul8Tenths_69b7); $DD Ahhh x1/2 (HLsrl1);
  $37/$38/$7E StepGuard/MapMagic/Whistle = the Attack handler $4625 (x1).
  $3D Beserker  sets its OWN guard-record mark $DB08+8a bit2, then x2. The
        mark's consumer is the bank $53 post-calc stage at $5A44: when the
        TARGET's defence-level nibble ($DB09+8t & 7) is 0 and its $DB08+8t
        bit2 is set, a flags7-bit7 (physical) skill other than $3C/$3E does
        x2 — contact hits on a Beserker user are doubled for the rest of the
        round (phase 9 clears +0 & $3F). Also read by the AI target score
        ($58:$43AA halves the marked target's DEF in the HP+DEF sum).
  $AB CALLEVIL  LoadBattle_66ba: CalcSkillDefense with the caster's ATK
        temporarily $0190 (400); sets own $DB08+8a bit0; a side sweep (tm 18).
F3:
  $14 Sacrifice  bank $53 entry 13 (state machine $670E): per target from the
        queued one to the end of its side (state 3 loop): InterceptGate (iron
        $BA / guard redirect), BossProtectionGate, ONE RNG step, res 14, RNG2
        kill test; then the CASTER's own resolution ($6971): one RNG step,
        RNG1 < $7F -> dies, else left at max(HP/100, 1).
  $3C Ramming  BattleTarget_6214 (target HP*8/10+1, ladder A res 14) + the
        state-4 tail $79B5 (caster HP -= HP*8/10+1, 0 -> KO).
  $3E Kamikaze KamikazeDamage_6232 (hit ladder $6733 res 14; LINK/wild ->
        target HP-1, boss/arena -> (caster HP-1)/2; caster HP 1 -> 1) + tail
        $78A3 (caster HP := 1, or KO when it was 1). NOT boss-gated: the
        gate routine's list names $3E but nothing on the Kamikaze path calls it.
  $3B TwinSlash tail $77E2: caster loses max(dmg>>2, 1); PsycheUp $56 shares
        the x1.5 handler and has no tail. Tails run only after an APPLIED hit
        the target SURVIVED (state 4 follows the apply; a KO goes to act
        state $1A; a dodge / miss / zero roll has no apply) — measured.
  $4F MultiCut LoadBattle_6381: record roll, x1.3125 (SetupBattle_6980) vs
        family 7 (Zombie), then the BREATH ladder res 3.
  $58/$59 WindBeast/Vacuum LoadBattle_641a/6491 + ladder A res 3 (BattleCall_5c2a).
        Vacuum's side test compares the LINK byte, not the attacker: ENEMY
        casters also take 2L+30 (measured; damage.vacuum's 1.5L branch is wrong).
  $5C-$63 FireAir/FrigidAir group: record roll + breath ladder (res 16/17,
        battle.core_damage) then BattleTarget_5539: halved when the target's
        +4 bit2 (Barrier) is set.
  $66 MegaMagic MegaMagicDamage_653e (2*MP + 2*level, +/-0.1, breath ladder
        res 15) on the MP left after the act-time spend; MP := 0 afterwards.
  $5B RockThrow, $65 BigBang, $D9 GigaSlash: battle.core_damage's record core
        + D.SPELL_LADDER (verified, nothing to add).
"""
from .. import battle as B
from .. import damage as D

MASK = 0xFFFF

SLASH_RTYPE = {0x44: 0, 0x45: 4, 0x46: 3, 0x47: 5}
FAMILY_CUT = {0x49: 1, 0x4A: 2, 0x4B: 3, 0x4C: 6, 0x4D: 7, 0x4E: 8,
              0xD6: 0, 0xD7: 5, 0xD8: 4}
PHYS_SIMPLE = {0x37: lambda d: d, 0x38: lambda d: d, 0x7E: lambda d: d,   # Attack handler $4625
               0x55: D.PHYS_MULT['SquallHit'],                           # DamageMul8Tenths_69b7
               0xDD: D.PHYS_MULT['Ahhh']}                                # HLsrl1
BREATH_BARRIER = frozenset(range(0x5C, 0x64))                            # BattleTarget_5539 callers
SAC, RAMMING, KAMIKAZE, TWINSLASH, BESERKER = 0x14, 0x3C, 0x3E, 0x3B, 0x3D
MULTICUT, WINDBEAST, VACUUM, MEGAMAGIC, CALLEVIL = 0x4F, 0x58, 0x59, 0x66, 0xAB
BESERKER_EXEMPT = (RAMMING, KAMIKAZE)                                    # $53:$5A52-$5A58


def _res(b, v, rtype, real_sk):
    """2-bit level of the target for `rtype`; a project's element override
    (bank $72 ElemLevel72 via the patched ElemLadder* wrappers, Board.
    elem_override[real id] = (rtype|None, kind)) replaces the rtype."""
    ov = getattr(b, 'elem_override', {}).get(real_sk)
    if ov is not None:
        rtype = ov[0]
        if rtype is None:
            return 0
    return D.res_level(bytes(b.res[v * 7:v * 7 + 7]), rtype)


def _calcdef(b, a, v, state, atk=None):
    return D.calc_skill_defense(b.atk[a] if atk is None else atk, b.dfn[v], state,
                                target_idx=v, arena=b.link, attacker_idx=a)


def _rec_fields(ctx):
    return ctx.f or {}


def guard_rec(s):
    """Index of slot s's one-round guard record $DB08+8s (= slot s+1's +0;
    s == 7 lands on $DB40, outside the 64-byte area -> None)."""
    return (s + 1) * 8 if s < 7 else None


# --------------------------------------------------------------------------
# F2 damage functions: (ctx, v, div, state) -> ('dmg', dmg, state)
# --------------------------------------------------------------------------
def dmg_slash(ctx, v, div, state):
    """BattleCall_6298/62a9/62ba/62cb + ResLadderElemSlash_6782."""
    b, a = ctx.b, ctx.a
    d, state = _calcdef(b, a, v, state)
    lev = _res(b, v, SLASH_RTYPE[ctx.sk], ctx.real_sk)
    return 'dmg', D.elemental_slash(d, b.stb(v, 5), lev) & MASK, state


def dmg_metalcut(ctx, v, div, state):
    """BattleCall_62dc: x1.5+1 vs $DB8B+t bit0."""
    b, a = ctx.b, ctx.a
    d, state = _calcdef(b, a, v, state)
    return 'dmg', D.metal_cut(d, b.db8b[v] & 1) & MASK, state


def dmg_familycut(ctx, v, div, state):
    """CheckIsSlime..CheckIsMaterial ($6305-$637F) via LookupTargetSpecies."""
    b, a = ctx.b, ctx.a
    d, state = _calcdef(b, a, v, state)
    return 'dmg', D.family_cut(d, b.family[v], FAMILY_CUT[ctx.sk]) & MASK, state


def dmg_simple(ctx, v, div, state):
    """$4625 Attack handler (x1) / SkillSquallHit (x8/10) / SkillAhhh2 (x1/2)."""
    b, a = ctx.b, ctx.a
    d, state = _calcdef(b, a, v, state)
    return 'dmg', PHYS_SIMPLE[ctx.sk](d) & MASK, state


def dmg_beserker(ctx, v, div, state):
    """SkillBeserker ($52:$4653): own $DB08+8a |= 4 (set only when the
    handler runs = the MISS machine passed), then calcdef x2 (sla/rl)."""
    b, a = ctx.b, ctx.a
    gi = guard_rec(a)
    if gi is not None:
        b.st[gi] |= 0x04
    d, state = _calcdef(b, a, v, state)
    return 'dmg', (d << 1) & MASK, state


def dmg_callevil(ctx, v, div, state):
    """SkillCALLEVIL ($52:$4FA1) -> LoadBattle_66ba: calcdef with ATK $0190;
    own $DB08+8a bit0 set (the CallHelp/YellHelp continuation flag)."""
    b, a = ctx.b, ctx.a
    d, state = _calcdef(b, a, v, state, atk=D.CALLEVIL_ATK)
    gi = guard_rec(a)
    if gi is not None:
        b.st[gi] |= 0x01
    return 'dmg', d & MASK, state


# --------------------------------------------------------------------------
# F3 damage functions
# --------------------------------------------------------------------------
def dmg_ramming(ctx, v, div, state):
    """BattleTarget_6214: target current HP *8/10 + 1, ladder A res 14."""
    b = ctx.b
    d = D.ramming_damage(b.hp[v])
    lev = _res(b, v, 14, ctx.real_sk)
    return 'dmg', D.apply_ladder(d, D.LADDER_A, b.stb(v, 5), lev) & MASK, state


def dmg_kamikaze(ctx, v, div, state):
    """KamikazeDamage_6232: HitLadderKamikaze_6733 on res 14 (one RNG step
    when the row entry is a threshold); a miss stores 0 (no apply, no tail);
    a hit: caster HP 1 -> 1, LINK or wild ($DB73 0) -> target HP - 1 (floor
    1), boss/arena -> (caster HP - 1) >> 1 (floor 1)."""
    b, a = ctx.b, ctx.a
    lev = D.res_level(bytes(b.res[v * 7:v * 7 + 7]), 14)
    hit, state = D.hit_roll(D.LADDER_HIT_SACRIFICE, b.stb(v, 5), lev, state)
    if not hit:
        return 'dmg', 0, state
    if b.hp[a] == 1:
        return 'dmg', 1, state
    if b.link or b.db73 == 0:
        d = (b.hp[v] - 1) & MASK
    else:
        d = (b.hp[a] - 1) >> 1
    return 'dmg', d if d else 1, state


def dmg_multicut(ctx, v, div, state):
    """LoadBattle_6381: record roll (party +$0B / enemy +$0F by attacker <4,
    LINK -> party), x1.3125 vs family 7, ResLadderBreath_676c res 3."""
    b, a, f = ctx.b, ctx.a, _rec_fields(ctx)
    enemy = a >= 4 and not b.link
    pmin = f['power_enemy_min'] if enemy else f['power_party_min']
    prng = f['power_enemy_range'] if enemy else f['power_party_range']
    d, state = D.record_roll(pmin, prng, state)
    if b.family[v] == 7:
        d = D.m_13125(d)
    lev = _res(b, v, 3, ctx.real_sk)
    return 'dmg', D.apply_ladder(d, D.LADDER_BREATH, b.stb(v, 5), lev) & MASK, state


def dmg_windbeast(ctx, v, div, state):
    """LoadBattle_641a (WindBeastDamage_642b) + BattleCall_5c2a ladder A res 3."""
    b, a = ctx.b, ctx.a
    d, state = D.windbeast(b.level[a], state, enemy_side=a >= 4, link=b.link)
    lev = _res(b, v, 3, ctx.real_sk)
    return 'dmg', D.apply_ladder(d, D.LADDER_A, b.stb(v, 5), lev) & MASK, state


def vacuum_base(level, state):
    """LoadBattle_6491 AS BYTES: the side test is `ld a,[$c86c] / or a /
    jr nz / cp $04 / jr c` — the cp compares the LINK byte (0), not the
    attacker index, so EVERY caster takes the party formula 2L+30 (cap 150);
    variance unit base/5, one RNG step, the shifted-out bit of rem>>1 picks
    subtract (a borrow leaves the base) / add."""
    base = min(2 * level + 30, 0x96)
    unit = base // 5
    d = base
    if unit:
        state = D.rng_step(state)
        rem = D.rng16_dividend(state) % unit
        half, carry = rem >> 1, rem & 1
        if carry:
            d = base - half if base >= half else base
        else:
            d = base + half
    return d, state


def dmg_vacuum(ctx, v, div, state):
    """Vacuum: vacuum_base + BattleCall_5c2a ladder A res 3."""
    b, a = ctx.b, ctx.a
    d, state = vacuum_base(b.level[a], state)
    lev = _res(b, v, 3, ctx.real_sk)
    return 'dmg', D.apply_ladder(d, D.LADDER_A, b.stb(v, 5), lev) & MASK, state


def megamagic_mp(ctx):
    """MP MegaMagic reads (GetCombatantMP at handler entry) = the MP left
    after the act-time spend (record +4 = 1). The round driver never spends
    MP (battle.act_mp_veto only checks), so the handler does it here."""
    return max(ctx.b.mp[ctx.a] - _rec_fields(ctx).get('mp_cost_byte', 0), 0)


def dmg_megamagic(ctx, v, div, state):
    """MegaMagicDamage_653e (breath ladder res 15 inside)."""
    b, a = ctx.b, ctx.a
    lev = _res(b, v, 15, ctx.real_sk)
    d, state = D.megamagic(megamagic_mp(ctx), b.level[a], state, b.stb(v, 5), lev)
    return 'dmg', d & MASK, state


def dmg_breath_barrier(ctx, v, div, state):
    """SkillFireAir/SkillFrigidAir: the record core (StoreDamageResult +
    breath ladder res 16/17) then BattleTarget_5539: target +4 bit2 ->
    damage >> 1."""
    kind, d, state = B.core_damage(ctx, v, div, state)
    if kind == 'dmg' and ctx.b.stb(v, 4) & 0x04:
        d >>= 1
    return kind, d, state


# --------------------------------------------------------------------------
# state-4 caster tails ($52:$6E89 dispatcher, sub 1 of each chain)
# --------------------------------------------------------------------------
def _caster_hp(b, a, hp):
    if hp <= 0:
        b.hp[a] = 0
        b.dd1b[a] = 1
        b.dd13[a] = 0xFF
        return True
    b.hp[a] = hp
    return False


def tail_twinslash(b, a, dmg):
    """$52:$77E2: recoil = dmg >> 2, min 1 (into $DB5A); caster HP <= recoil
    -> 0 (KO), else HP -= recoil. Returns (recoil, ko)."""
    r = (dmg >> 2) or 1
    return r, _caster_hp(b, a, b.hp[a] - r if b.hp[a] > r else 0)


def tail_kamikaze(b, a, dmg=None):
    """$52:$78A3: HP - 1 != 0 -> HP := 1; else HP := 0 (KO path)."""
    return 1, _caster_hp(b, a, 1 if b.hp[a] - 1 else 0)


def tail_ramming(b, a, dmg=None):
    """$52:$79B5: x = HP*8/10 + 1 (DamageMul8Tenths_69b7 + inc); HP - x,
    borrow or zero -> 0 (KO)."""
    x = (b.hp[a] * 8) // 10 + 1
    return x, _caster_hp(b, a, b.hp[a] - x)


TAILS = {TWINSLASH: tail_twinslash, KAMIKAZE: tail_kamikaze, RAMMING: tail_ramming}


# --------------------------------------------------------------------------
# post-calc: the Beserker mark consumer ($53:$5A44)
# --------------------------------------------------------------------------
def postcalc_beserker_taken(b, a, v, sk, f, core, dmg, state):
    """$53:$59EC/$5A44: target defence nibble ($DB09+8t & 7) == 0 and the
    target's $DB08+8t bit2 (Beserker) set and the acting skill physical
    (flags7 bit7) and not $3C/$3E -> dmg x2 (sla/rl, 16-bit)."""
    gi = guard_rec(v)
    if gi is None or (b.st[gi + 1] & 0x07):
        return dmg, state
    if not (b.st[gi] & 0x04) or not (f.get('flags7', 0) & 0x80) or sk in BESERKER_EXEMPT:
        return dmg, state
    return (dmg << 1) & MASK, state


# --------------------------------------------------------------------------
# action handlers
# --------------------------------------------------------------------------
def with_tail(damage_fn):
    """default_victims + the state-4 caster tail. The tail runs once, after
    an APPLIED hit that the target SURVIVED (a KO sends the act machine to
    state $1A instead of 4; a dodge / miss / zero roll has no apply — all
    measured), and only while the caster is alive (LoadBattle_7997)."""
    def act(ctx):
        n0 = len(ctx.log)
        dmg_fn = damage_fn
        if damage_fn is dmg_kamikaze:
            def dmg_fn(c, v, div, st):          # a Kamikaze miss stores 0: no apply
                k, d, st = dmg_kamikaze(c, v, div, st)
                return ('done', None, st) if d == 0 else (k, d, st)
        state = B.default_victims(ctx, dmg_fn)
        hits = [x[2] for x in ctx.log[n0:] if x[0] == ctx.a and x[1] == 'hit']
        hits = [h for h in hits if h[1] > 0 and not h[2]]   # a KO'd target goes to state $1A, not 4
        if hits and ctx.b.valid(ctx.a):
            r, ko = TAILS[ctx.sk](ctx.b, ctx.a, hits[-1][1])
            ctx.log.append((ctx.a, 'tail', (ctx.sk, r, ko)))
        return state
    return act


def act_megamagic(ctx):
    """MegaMagic: default per-victim sweep, then the caster's MP := 0."""
    state = B.default_victims(ctx, dmg_megamagic)
    ctx.b.mp[ctx.a] = 0
    return state


def sacrifice_target(b, v, state):
    """SacrificeResolve_67a9 for ONE target (the gate passed). Returns
    (outcome, dmg, state): 'boss' (no step), 'immune' / 'resist' (res 3 /
    res 2 with RNG1 >= $C0), 'kill' (RNG2 < $7F, or the survivor branch's
    HP - max(HP/100,1) is 0: dmg = full HP), 'survive' (dmg = HP - chip)."""
    if not b.link and v >= 4 and b.db73 == 1:
        return 'boss', 0, state
    state = D.rng_step(state)                       # LoadBtlC_4e33
    lev = D.res_level(bytes(b.res[v * 7:v * 7 + 7]), 14)
    if lev == 3:
        return 'immune', 0, state
    if lev == 2 and D.rng1(state) >= 0xC0:
        return 'resist', 0, state
    hp = b.hp[v]
    if D.rng2(state) < 0x7F:
        return 'kill', hp, state
    chip = (hp // 100) or 1
    if hp - chip <= 0:
        return 'kill', hp, state
    return 'survive', hp - chip, state


def sacrifice_self(b, a, state):
    """$53:$6971 (state 4) for the caster: one RNG step; RNG1 < $7F ->
    dmg = HP (dies), else HP - max(HP/100,1) (0 -> dies). Returns
    (outcome, dmg, state)."""
    state = D.rng_step(state)
    hp = b.hp[a]
    if D.rng1(state) < 0x7F:
        return 'dies', hp, state
    chip = (hp // 100) or 1
    if hp - chip <= 0:
        return 'dies', hp, state
    return 'survives', hp - chip, state


def act_sacrifice(ctx):
    """Bank $53 entry 13 for $14. The main MISS machine runs once (first
    victim; flags7 $40 / flags8 $07 always pass); then for each slot from
    the queued target to the end of its side: InterceptGate (dead/empty ->
    skip; iron +7&$C0 -> msg $BA skip; a guard mark redirects once per
    action), the resolution, the apply ($6866). Then the caster's own roll
    and apply ($6971/$6A04)."""
    b, a, log, idle = ctx.b, ctx.a, ctx.log, ctx.idle
    f = _rec_fields(ctx)
    state = idle(ctx.state, 'pre_miss')
    state = B.rng_step(state)
    g = B.miss_gate(b, a, ctx.t, f.get('flags7', 0), f.get('flags8', 0), state)
    if g != 'pass':
        log.append((a, g, ctx.t))
        ctx.state = state
        return state
    v = ctx.t
    first = True
    while True:
        if not first:
            state = idle(state, 'pre_target')
        if b.valid(v):
            if b.stb(v, 7) & 0xC0:
                log.append((a, 'unreachable', v))
            else:
                # InterceptGate: a guard mark resolves this target on its
                # protector; state 3 restores the original ($C1C8) so the
                # sweep continues from v (the first victim was already
                # redirected by the driver's main-path guard_redirect)
                tv = v if first else B.guard_redirect(b, v, 0x02)
                if tv != v:
                    log.append((a, 'guarded', v, tv))
                out, dmg, state = sacrifice_target(b, tv, state)
                if dmg:
                    ko = B.apply_damage(b, tv, dmg)
                    log.append((a, 'hit', (tv, dmg, ko)))
                else:
                    log.append((a, 'sacrifice-fail', (tv, out)))
        first = False
        if (v & 3) >= 2:
            break
        v += 1
    if b.valid(a):
        out, dmg, state = sacrifice_self(b, a, state)
        ko = B.apply_damage(b, a, dmg)
        log.append((a, 'sacrifice-self', (out, dmg, ko)))
    ctx.state = state
    return state


# --------------------------------------------------------------------------
# registration
# --------------------------------------------------------------------------
def _register():
    reg = B.ACTION_HANDLERS
    core = B.CORE_OVERRIDES
    for sk in SLASH_RTYPE:
        reg[sk] = lambda ctx: B.default_victims(ctx, dmg_slash); core[sk] = 'calcdef'
    reg[0x48] = lambda ctx: B.default_victims(ctx, dmg_metalcut); core[0x48] = 'calcdef'
    for sk in FAMILY_CUT:
        reg[sk] = lambda ctx: B.default_victims(ctx, dmg_familycut); core[sk] = 'calcdef'
    for sk in PHYS_SIMPLE:
        reg[sk] = lambda ctx: B.default_victims(ctx, dmg_simple); core[sk] = 'calcdef'
    reg[BESERKER] = lambda ctx: B.default_victims(ctx, dmg_beserker); core[BESERKER] = 'calcdef'
    reg[CALLEVIL] = lambda ctx: B.default_victims(ctx, dmg_callevil); core[CALLEVIL] = 'calcdef'
    reg[TWINSLASH] = with_tail(B.core_damage)                 # core stays 'calcdef' x1.5
    reg[RAMMING] = with_tail(dmg_ramming); core[RAMMING] = 'ramming'
    reg[KAMIKAZE] = with_tail(dmg_kamikaze); core[KAMIKAZE] = 'kamikaze'
    reg[SAC] = act_sacrifice; core[SAC] = 'sacrifice'
    B.SELF_GATED.update((SAC, KAMIKAZE))
    reg[MULTICUT] = lambda ctx: B.default_victims(ctx, dmg_multicut)   # core stays 'record'
    reg[WINDBEAST] = lambda ctx: B.default_victims(ctx, dmg_windbeast); core[WINDBEAST] = 'windbeast'
    reg[VACUUM] = lambda ctx: B.default_victims(ctx, dmg_vacuum); core[VACUUM] = 'vacuum'
    reg[MEGAMAGIC] = act_megamagic; core[MEGAMAGIC] = 'megamagic'
    for sk in BREATH_BARRIER:
        reg[sk] = lambda ctx: B.default_victims(ctx, dmg_breath_barrier)
    B.POST_CALC.append((70, postcalc_beserker_taken))
    B.POST_CALC.sort(key=lambda x: x[0])


DAMAGE_FN = {}
for _s in SLASH_RTYPE: DAMAGE_FN[_s] = dmg_slash
for _s in FAMILY_CUT: DAMAGE_FN[_s] = dmg_familycut
for _s in PHYS_SIMPLE: DAMAGE_FN[_s] = dmg_simple
for _s in BREATH_BARRIER: DAMAGE_FN[_s] = dmg_breath_barrier
DAMAGE_FN.update({0x48: dmg_metalcut, BESERKER: dmg_beserker, CALLEVIL: dmg_callevil,
                  RAMMING: dmg_ramming, KAMIKAZE: dmg_kamikaze, MULTICUT: dmg_multicut,
                  WINDBEAST: dmg_windbeast, VACUUM: dmg_vacuum, MEGAMAGIC: dmg_megamagic,
                  TWINSLASH: B.core_damage, 0x56: B.core_damage})

_register()
