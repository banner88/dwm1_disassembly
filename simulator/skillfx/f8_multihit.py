"""S130 F8 — THE MULTI-HIT LOOP (BATTLE_SKILL_SYSTEM §15.11 F8).

Skills: BiAttack $50, QuadHits $51, CallHelp $52, YellHelp $53, RainSlash $57
and the 8-slot walk $714C shared by METEOR $AF (F8) with the Chance outcomes
BIGSLEEP $A7 / MP0 $A8 (registered here only as a fallback — setdefault —
so an F1/F5 module that models them keeps its own handler).

Byte sources (bank $52 = driver + handlers, bank $53 = act states, bank $58
= target services) and what each model function stands for:

  multihit_action      the per-ACTION loop: act state 0 target fetch
                       ($53:$520C, $DD69 += 1, $DB89 := $DCED+2a) -> act
                       state 7 ($53:$5411, ONE LoadBtlC_4e33 RNG step; hits
                       >= 2 skip states 1-6 and reach it in the SAME frame as
                       the fetch, measured k=1) -> Cover/Guardian re-check
                       ($54D6, every fetch) -> state 9 ($56A8: a dead target
                       drops straight to the continuation; the iron gate
                       $56E1) -> the MISS machine ($5747, one step per hit)
                       -> the crit stage ($586A, one step for flags8 bits
                       4-6 skills = Bi/Quad/Rain) -> the skill handler ->
                       post-calc -> apply ($52:$6D56) -> snap-out ->
                       driver state 6, continuation dispatch $52:$7041.
  continuation         $52:$7041 dispatch + $6F83 / $6F71 / $6F9C / $6FA8 /
                       $6FD4 / $714C (byte-exact, see the function).
  repick               bank $58 entry 5 = LoadBtlFX_642c: the UNIFORM pick
                       over the attacker's opposing side (battle.
                       uniform_side_pick; measured 0-step offset from the
                       continuation = same frame).
  callhelp_first_pass  SkillCallHelp $52:$480C at $DD69 == 1.
  helper_damage        LoadBattle_63dc + CheckTargetGuardA on rtype 24.
  hit_damage           SkillBiAttack $4798 (ATK x0.75 / x0.625 via
                       damage.BIATTACK_ATK / QUADHITS_ATK), SkillRainSlash
                       $48B4 (x.8/.6/.4 by $DD69), SkillMETEOR $501F (HP-1,
                       1 at HP 1), SkillBIGSLEEP $4F54, SkillMP0 $4F7F.
  crit_stage           $53:$586A gate (step position exact; the crit TABLE
                       and crit damage are not modelled — open, see notes).

Measured S130 (simulator/measure_f8_multihit.py, corpus simulator/
f8_events.json, validator simulator/validate_f8_multihit.py, u22 build on
the user's real save), including: every hit runs its own MISS machine and
(Bi/Quad/Rain) crit step; a dodge/miss/iron fail on one hit does NOT end
the loop; BiAttack keeps a live target and re-picks only a dead one;
QuadHits re-picks before EVERY later hit; RainSlash walks forward from the
queued target skipping dead slots WITHOUT consuming $DD69 (so a dead slot
does not shift the x.8/.6/.4 ladder); a successful CallHelp/YellHelp first
pass ($DD69 := $0F, +1 enemy CallHelp, +2 enemy YellHelp) returns straight
to the target fetch (no continuation, no re-pick: the first helper hits the
queued target) and every later helper hit is gated by the continuation's
RNG2 early stop then re-picked; the $714C walk visits the caster's own side
too (METEOR / BIGSLEEP hit the caster) and, from a start slot > base, wraps
to the SAME side's base at $DD69 == 4 (slot 8 -> (8&4)^4 = 4).

RNG idle sites (classes for battle's idle policy; the pools measured on the
F8 corpus are in simulator/f8_idle_pools.json and are installed into an
IdlePolicy on first use when it lacks them):
  'pre_miss'     hit 1 only (the S86 class: announce + attack animation)
  'mh_post_hit'  any pass outcome (apply/KO, miss, dodge, iron, dead
                 target, CallHelp fail) -> the continuation $7041
  'mh_refetch'   continuation (after its RNG2 read / re-pick) -> the next
                 target fetch (one frame)
  'mh_call_msg'  CallHelp success message -> the first helper fetch
  'mh_pre_snap'  apply -> the on-hit sleep/confusion snap-out roll (only
                 when that roll runs: flags9 bit3 and victim +2 & $90)
Same-frame (deterministic) segments: fetch -> state-7 step -> MISS step ->
crit step -> handler (CallHelp roll / calcdef step); continuation RNG2 read
-> re-pick step.
"""
import json
import os

from .. import battle as B
from .. import damage as D

BIATTACK, QUADHITS, CALLHELP, YELLHELP, RAINSLASH = 0x50, 0x51, 0x52, 0x53, 0x57
BIGSLEEP, MP0, METEOR = 0xA7, 0xA8, 0xAF
CALLHELP_IDS = (CALLHELP, YELLHELP)
WALK8_IDS = (BIGSLEEP, MP0, METEOR)
F8_IDS = (BIATTACK, QUADHITS, CALLHELP, YELLHELP, RAINSLASH, METEOR)
# bank $58 per-skill target dispatch rows that point at LoadBtlFX_642c
# (byte-read $58:$401D table; measured: every act-time re-resolve of
# $51/$52/$53 enters $642C)
REPICK_642C_IDS = (QUADHITS, CALLHELP, YELLHELP)
# $53:$56A8: skills that skip the state-9 dead-target check (none of F8's)
STATE9_NOCHECK = frozenset([0x30, 0x31, 0x32, 0x95, 0x96, 0xAD, 0x8F, 0x89, 0x8B])
# CallHelp/YellHelp: (terminal $DD69, early-stop mask) — $6F9C / $6FA8
CALL_LOOP = {CALLHELP: (0x13, 0x03), YELLHELP: (0x17, 0x07)}

_POOLS_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                           'f8_idle_pools.json')


def _ensure_pools(idle):
    """Install the F8 idle pools into an IdlePolicy-like object that has a
    `pools` dict without them (pacing.IdlePolicy('empirical')). Identity /
    uniform policies and plain functions are left alone."""
    pools = getattr(idle, 'pools', None)
    if not isinstance(pools, dict) or 'mh_refetch' in pools:
        return
    try:
        mine = json.load(open(_POOLS_PATH))['pools']
    except (OSError, ValueError, KeyError):
        return
    for k, v in mine.items():
        pools.setdefault(k, v)


def own8_bit0(b, a):
    """'own +8 bit0' = $DB08 + 8*a bit0 (physically slot a+1's +0; slot 7
    reads $DB40, outside the status blocks -> treated as clear)."""
    i = (a + 1) * 8
    return i < 64 and bool(b.st[i] & 1)


def set_own8_bit0(b, a):
    i = (a + 1) * 8
    if i < 64:
        b.st[i] |= 1


def repick(b, a, state):
    """$58 entry 5 = LoadBtlFX_642c: e = (attacker&4)^4, count the live
    slots there (UniformSideCount_63ec), ONE RNG step (UniformSidePick_63fd),
    the (RNG1 mod count + 1)-th live slot; also written to $DCED."""
    return B.uniform_side_pick(b, (a & 4) ^ 4, state)


def reresolve_pick(b, a, state):
    """RERESOLVE_PICKERS entry for $51/$52/$53: the act-time re-resolve
    (TargetReResolve_4799 -> $5808 -> per-skill row $642C) is the same
    uniform opposing-side pick, not the plain-attack front-weighted roll."""
    return repick(b, a, state)


def continuation(b, a, sk, dd69, tgt, state):
    """Driver state 6, $52:$7041 dispatch on $DB8A, after a pass. Returns
    (go, tgt, dd69, state, why). `tgt` = $DCED+2a (the remembered target).
      $50 $6F83: $DD69 == 2 -> end; d9ed:=1; target live -> same target,
                 else re-pick ($5805).
      $51 $6F71: $DD69 == 4 -> end; else re-pick every time.
      $52 $6F9C / $53 $6FA8: $DD69 == $13 / $17 -> end; RNG2 & 3 (& 7) ==
                 $DD69 & 3 (& 7) -> end (RNG2 AS FOUND, no step); own +8
                 bit0 clear -> end; else re-pick.
      $57 $6FD4: $DD69 >= 4 -> end; else $DCED += 1 until a live slot; a
                 slot with &3 == 3 ends it ($DD69 is NOT touched).
      $A7/$A8/$AF $714C: $DD69 >= 8 -> end; $DD69 == 4 -> $DCED :=
                 ($DCED & 4) ^ 4 (no validity check); else $DCED += 1 and a
                 dead slot costs $DD69 += 1 then re-loops.
      other: end (Jump_052_706c)."""
    if sk == BIATTACK:
        if dd69 == 2:
            return False, tgt, dd69, state, 'count'
        if b.valid(tgt):
            return True, tgt, dd69, state, 'same'
        t, state = repick(b, a, state)
        return t is not None, t, dd69, state, 'repick'
    if sk == QUADHITS:
        if dd69 == 4:
            return False, tgt, dd69, state, 'count'
        t, state = repick(b, a, state)
        return t is not None, t, dd69, state, 'repick'
    if sk in CALL_LOOP:
        top, m = CALL_LOOP[sk]
        if dd69 == top:
            return False, tgt, dd69, state, 'count'
        if (B.rng2(state) & m) == (dd69 & m):
            return False, tgt, dd69, state, 'early'
        if not own8_bit0(b, a):
            return False, tgt, dd69, state, 'nobit'
        t, state = repick(b, a, state)
        return t is not None, t, dd69, state, 'repick'
    if sk == RAINSLASH:
        if dd69 >= 4:
            return False, tgt, dd69, state, 'count'
        while True:
            tgt = (tgt + 1) & 0xFF
            if (tgt & 3) == 3:
                return False, tgt, dd69, state, 'side'
            if b.valid(tgt):
                return True, tgt, dd69, state, 'walk'
    if sk in WALK8_IDS:
        while True:
            if dd69 >= 8:
                return False, tgt, dd69, state, 'count'
            if dd69 == 4:
                return True, (tgt & 4) ^ 4, dd69, state, 'wrap'
            tgt = (tgt + 1) & 0xFF
            if b.valid(tgt):
                return True, tgt, dd69, state, 'walk'
            dd69 = (dd69 + 1) & 0xFF
    return False, tgt, dd69, state, 'single'


def callhelp_first_pass(b, a, sk, state):
    """SkillCallHelp at $DD69 == 1: one BattleRNG step; RNG1 bit0 clear ->
    fail ($DD69 := $FF, msg $C2, no damage, goes to the continuation);
    set -> msg $A1, own +8 bit0 set, $DD69 := $0F (+1 for a non-link enemy
    caster, +1 more for YellHelp), d9ef := 3 / d9ee := 0 = straight back to
    the target fetch. Returns (ok, dd69, state)."""
    state = B.rng_step(state)
    if not (B.rng1(state) & 1):
        return False, 0xFF, state
    dd69 = 0x0F
    set_own8_bit0(b, a)
    if not b.link and a >= 4:
        dd69 += 1 if sk == CALLHELP else 2
    return True, dd69, state


def helper_damage(b, a, v):
    """LoadBattle_63dc: level*2 (party or link caster) or level + level>>1
    (enemy caster), then CheckTargetGuardA with the rtype-24 level
    ($DD2E+7t bits 5:4 = damage.res_level(.., 24)) on the target +5 row."""
    lv = b.level[a] & 0xFF
    dmg = lv * 2 if (b.link or a < 4) else lv + (lv >> 1)
    lev = D.res_level(bytes(b.res[v * 7:v * 7 + 7]), 24)
    return D.apply_ladder(dmg, D.LADDER_A, b.stb(v, 5), lev)


def hit_damage(b, a, v, sk, dd69, state):
    """The skill handler for one pass at a live target `v`. Returns (kind,
    value, state): ('dmg', n) for the apply, ('done', None) when the
    handler resolved the target itself (BIGSLEEP/MP0), ('none', None)
    when it did nothing (SetSkillAnimFlag)."""
    if sk in (BIATTACK, QUADHITS):
        atk = (D.QUADHITS_ATK if sk == QUADHITS else D.BIATTACK_ATK)(b.atk[a])
        dmg, state = D.calc_skill_defense(atk, b.dfn[v], state, target_idx=v,
                                          arena=b.link, attacker_idx=a)
        return 'dmg', dmg, state
    if sk == RAINSLASH:
        if dd69 >= 5:
            return 'none', None, state
        dmg, state = D.calc_skill_defense(b.atk[a], b.dfn[v], state, target_idx=v,
                                          arena=b.link, attacker_idx=a)
        key = 'RainSlash1' if dd69 == 1 else ('RainSlash2' if dd69 == 2 else 'RainSlash3+')
        return 'dmg', D.PHYS_MULT[key](dmg), state
    if sk in CALLHELP_IDS:
        return 'dmg', helper_damage(b, a, v), state
    if sk == METEOR:
        if not 1 <= dd69 <= 8:
            return 'none', None, state
        hp = b.hp[v]
        return 'dmg', (1 if hp == 1 else max(hp - 1, 0)), state
    if sk == BIGSLEEP:
        if b.stb(v, 2) & 0x80:
            return 'done', 'already', state          # msg $BD
        b.set_stb(v, 2, (b.stb(v, 2) & 0x73) | 0x8C)
        return 'done', 'sleep', state
    if sk == MP0:
        if b.mp[v]:
            b.mp[v] = 0
            return 'done', 'mp0', state
        return 'done', 'mp-already-0', state
    return 'none', None, state


def crit_stage(b, a, f8, state):
    """$53:$586A (act state A) before the handler: flags8 & $70 == 0 -> no
    roll. bit5 set and attacker +3 bit2 (TwinHits armed) -> no roll (the
    damage doubles later, post-calc). bit4: $DB42[a] bit0 or +3 bit3 ->
    forced crit, no roll; else ONE LoadBtlC_4e33 step + LoadBtlC_5ed9
    (RNG1 < per-species threshold from $53:$4001/$4102 + species, values
    0/1/2 else 4). The threshold table and the crit damage ($5941,
    SaveBtlC_5d73) are NOT modelled here (F4 / open): `b.ext['crit_thr']`
    (8 per-slot thresholds) may supply the table; default 0 = never.
    Returns (crit, state)."""
    if B.CRIT_STAGE is not None:      # S130 F4: the exact stage (skillfx/f4_charge.crit_stage:
        crit, state = B.CRIT_STAGE(b, a, {'flags8': f8}, state)   # species table, +4 bit7)
        return crit is True, state
    if not (f8 & 0x70):
        return False, state
    if (f8 & 0x20) and (b.stb(a, 3) & 0x04):
        return False, state
    if not (f8 & 0x10):
        return False, state
    if (b.db42[a] & 0x01) or (b.stb(a, 3) & 0x08):
        return True, state
    state = B.rng_step(state)
    thr = (b.ext.get('crit_thr') or [0] * 8)[a]
    return B.rng1(state) < thr, state


def _tr(b, *item):
    """Validation trace (simulator/validate_f8_multihit.py): appended only
    when the board carries ext['f8_trace'] (a list)."""
    t = b.ext.get('f8_trace')
    if t is not None:
        t.append(item)


def multihit_action(ctx):
    """ACTION_HANDLERS entry for the F8 ids: the whole multi-pass action
    (see the module docstring for the engine path). ctx.t = the resolved
    first target ($DCED at the first fetch). Returns the RNG state."""
    b, a, sk, f, log, idle = ctx.b, ctx.a, ctx.sk, ctx.f, ctx.log, ctx.idle
    _ensure_pools(idle)
    f7, f8, f9 = f.get('flags7', 0), f.get('flags8', 0), f.get('flags9', 0)
    state = ctx.state
    tgt = ctx.t
    b.queue[a * 2 + 1] = tgt & 0xFF
    dd69 = 0
    npass = 0
    while True:
        # ---- act state 0, $53:$520C: target fetch
        _tr(b, 'fetch', dd69, tgt, state)
        dd69 = (dd69 + 1) & 0xFF
        npass += 1
        v = tgt
        if npass == 1:
            state = idle(state, 'pre_miss')   # (hit 1's Cover check ran in simulate_round)
        else:
            state = B.rng_step(state)             # act state 7 $5411 LoadBtlC_4e33 (k=1)
        for hook in B.VICTIM_HOOKS:
            v = hook(b, a, v, sk, f)
        # ---- act state 7 ($5411, after its step): an airborne target (+6 &
        # $0C, HighJump) vs a flags9-bit5 skill -> "doesn't reach" ($C1),
        # d9ed:=5 -> the continuation (measured bi_block: no MISS entry)
        airborne = v is not None and 0 <= v < 8 and (b.stb(v, 6) & 0x0C) and (f9 & 0x20)
        if not airborne and npass > 1 and v is not None and 0 <= v < 8:
            gt = B.guard_redirect(b, v, f8)       # $54D6: Cover/Guardian, every fetch
            if gt != v:
                log.append((a, 'guarded', v, gt))
                v = tgt = gt
                b.queue[a * 2 + 1] = gt
        if airborne:
            log.append((a, 'airborne', v))
            _tr(b, 'outcome', 'airborne', v)
        # ---- act state 9 ($56A8 / $56E1)
        elif v is None or (sk not in STATE9_NOCHECK and not b.valid(v)):
            log.append((a, 'mh-skip', v))
            _tr(b, 'outcome', 'skip', v)
        elif (b.stb(v, 7) & 0xC0) and (f8 & 0x04) and sk != 0x14:
            if sk in CALLHELP_IDS and dd69 < 2:
                dd69 = 0x10                       # $5715: msg $C2, d9ed:=6
                log.append((a, 'callhelp-iron', v))
            else:
                log.append((a, 'unreachable', v))  # msg $BA, LoadBtlC_583a
            _tr(b, 'outcome', 'iron', v)
        else:
            # ---- MISS machine $53:$5747 (block check precedes the step)
            _tr(b, 'miss_pre', state)
            if (f7 & 0x80) and (b.stb(v, 6) & 0x04):
                g = 'block'
            else:
                state = B.rng_step(state)
                _tr(b, 'miss_post', state)
                g = B.miss_gate(b, a, v, f7, f8, state)
            _tr(b, 'outcome', g, v)
            if g != 'pass':
                log.append((a, g, v))
            else:
                crit, state = crit_stage(b, a, f8, state)
                if crit:
                    log.append((a, 'crit', v))   # S130 F4: handler skipped, post-calc builds it
                _tr(b, 'handler', state)
                if crit and B.CRIT_STAGE is not None:   # S130 F4
                    dmg, state = B.post_calc(b, a, v, sk, f, ctx.core, 0, state)
                    ko = B.apply_damage(b, v, dmg)
                    _tr(b, 'apply', v, dmg, ko)
                    log.append((a, 'hit', (v, dmg, ko)))
                    if not ko and (f9 & 0x08) and (b.stb(v, 2) & 0x90):
                        state = idle(state, 'mh_pre_snap')
                        rolled, snapped, state = B.snap_out(b, v, f9, state)
                        if rolled:
                            log.append((a, 'snap', (v, snapped)))
                elif sk in CALLHELP_IDS and dd69 == 1:
                    ok, dd69, state = callhelp_first_pass(b, a, sk, state)
                    log.append((a, 'callhelp', ok))
                    _tr(b, 'callhelp', ok, dd69)
                    if ok:
                        state = idle(state, 'mh_call_msg')
                        continue                   # straight back to the fetch
                else:
                    kind, val, state = hit_damage(b, a, v, sk, dd69, state)
                    if kind == 'dmg':
                        dmg, state = B.post_calc(b, a, v, sk, f, ctx.core, val, state)
                        ko = B.apply_damage(b, v, dmg)
                        _tr(b, 'apply', v, dmg, ko)
                        log.append((a, 'hit', (v, dmg, ko)))
                        if not ko and (f9 & 0x08) and (b.stb(v, 2) & 0x90):
                            # act state 5 $53:$5F15 runs after the damage
                            # animation (measured apply -> snap_roll cross-frame)
                            state = idle(state, 'mh_pre_snap')
                            rolled, snapped, state = B.snap_out(b, v, f9, state)
                            _tr(b, 'snap', v, snapped)
                            if rolled:
                                log.append((a, 'snap', (v, snapped)))
                    elif kind == 'done':
                        log.append((a, 'effect', (v, val)))
                    else:
                        log.append((a, 'no-effect', sk))
        # ---- driver state 6 (after the $DA33 wait): battle over?
        if B.side_wiped(b, 0) or B.side_wiped(b, 4):
            _tr(b, 'wiped')
            break
        state = idle(state, 'mh_post_hit')
        _tr(b, 'cont', state, dd69)
        go, tgt, dd69, state, why = continuation(b, a, sk, dd69, tgt, state)
        if tgt is not None:
            b.queue[a * 2 + 1] = tgt & 0xFF
        _tr(b, 'decision', go, why, tgt, dd69)
        if not go:
            log.append((a, 'mh-end', (why, npass)))
            break
        state = idle(state, 'mh_refetch')
    ctx.state = state
    return state


# ---- registration --------------------------------------------------------
for _id in F8_IDS:
    B.ACTION_HANDLERS[_id] = multihit_action
    B.OWN_TARGET_GATES.add(_id)
for _id, _core in ((BIGSLEEP, 'walk8-sleep'), (MP0, 'walk8-mp0')):   # F1 / F5 own the effect
    if _id not in B.ACTION_HANDLERS:
        B.ACTION_HANDLERS[_id] = multihit_action
        B.OWN_TARGET_GATES.add(_id)
        B.CORE_OVERRIDES.setdefault(_id, _core)
for _id in REPICK_642C_IDS:
    B.RERESOLVE_PICKERS[_id] = reresolve_pick
for _id, _core in ((BIATTACK, 'multihit'), (QUADHITS, 'multihit'), (CALLHELP, 'helper'),
                   (YELLHELP, 'helper'), (RAINSLASH, 'multihit'), (METEOR, 'meteor')):
    B.CORE_OVERRIDES[_id] = _core
