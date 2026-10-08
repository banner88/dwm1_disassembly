"""DWM1 combat-simulator ROUND CORE — the LOOP GLUE, differentially
validated S85 (simulator/validate_battle.py over the S85 corpus captured
by simulator/measure_battle.py on the real save + rig battles).

Components it assembles (each engine-exact from earlier sessions):
  turn_order.round_order   (S79, 143/143)
  damage.*                 (S78/S79, 698/698 + specials)
  status.*                 (sleep wake exact; DoT formulas CORRECTED S85)

What THIS module models, and the byte source for each rule:

  Round start ($58:$54D1 TurnOrderBuild): ready = slots with $DD13==2 and
    $DD1B==0; order = turn_order.round_order (keys from the RNG at build
    entry; the 9th sort pair is $DB71/72 + $DB54 as found).
  Per-actor fetch ($53:$4546): walks $DB79; invalid/$FF entries and
    $DD13!=2 entries are skipped ($463B); the walk runs to cursor 9 only
    on the forced-action path ($4640), otherwise phase 6 ends the round at
    the first $FF (both end in phase 8 -> 9).
  Status gates (PerActorStatusGates_4558, in this order): +7&$C0 -> $11;
    +2 bit6 -> $13 (paralysed); +2 bit7 -> SleepWakeRoll_4aeb (RNG1 as
    found, NO step: $0F still asleep / $DB wakes, turn consumed either
    way); +5 one-shots bit2->$16, bit0->$12, bit1->$14, bit3->$15,
    bit4->$17, bit5->$18. Then ONE RNG step (LoadBtlC_4e33) and the curse
    roll (+2 bit5, RNG1<$40 -> CurseSelfHit_4c50; a non-fatal hit RE-ENTERS
    sub-state 0 next frame = the gates re-run, byte-read S85, not in
    corpus). Then confusion (+2 bit4 -> ConfusionActionRewrite, bank $52,
    status.confusion_action; not in corpus).
  Duplicate-group-cast conversion (LoadBtlC_4e63, CLOSES the S84 open
    "2nd group cast -> $3A" item; measured S85 8/8): ENEMY actors only,
    when the per-EID flag table $53:$41DF[eid] != 0 and an EARLIER enemy
    entry of this round's $DB79 has the SAME queued skill and the skill is
    in the 77-id list $53:$4EE4 (GROUP_DUP_SKILLS): the actor converts to
    plain Attack $3A (target byte -> $FF, TargetReResolve) — unless its AI
    mode $DD0B==2, which keeps the cast.
  Act-time re-resolve (SetupSub_4692 -> TargetReResolve_4799): actors with
    $DD0B!=0, not confused, tactic!=3, a VALID queued target and a skill
    not in {$32,$96,$95,$AD} (Sacrifice keeps its target only with +3
    bit0) reset the target byte to $FF and re-target through the bank $58
    per-skill dispatch at act (RNG-driven when >1 candidate: NOT modelled
    beyond the 1-candidate case; the validator takes the engine's pick).
  Act-time MP/seal veto (SetupSub_480e): record MP cost (+4) > current MP
    -> the turn is wasted (msg $F7/$F9/$F8) — or, for $DD0B==2 actors, a
    RE-DECIDE (state $16, $DD13:=1); flags7 bit6 spells: side seal
    ($DB00/01 bit3) -> $1F, attacker +3 bit0 StopSpell -> $1E; bit5 dances
    vs +3 bit6 -> $21; bit4 breath vs +3 bit7 -> $20.
  MISS/dodge machine ($53:$5747, §15.10.9): per VICTIM (the act-state
    machine cycles per target); one RNG step then correlated reads.
  Damage: per victim through damage.* with the RNG at the core's entry.
  Apply ($52:$6D56): HP -= dmg floor 0; KO -> $DD1B:=1, $DD13:=$FF.
  Phase 9 (bank $50 $6ABC.., measured S85): sub 0 status DECAY for all
    8 blocks — +4 bit7 cleared, +6 = ((v>>>1)&$55) (four 2-bit round
    timers halve), +7 bit5 -> bit4 (only when +7&$30 != 0), then every
    block's +0 &= $C0 and +1 := 0, $DB42..49 := 0, $DB4A/4B &= 3; sub 1/2
    per LIVE combatant in slot order: +7&$C0 counter -> decrement by $40
    ("returned to normal" msg $DD when it hits 0), NO DoT that round;
    else +2 bit0 poison -> MaxHP/16, bit1 heavy -> MaxHP/6, floor 1, then
    the CAP: if base >= 10 (poison) / 30 (heavy): dmg = 10 + RNG16 mod 6 /
    30 + RNG16 mod 11 (Div16x8To16 leaves the REMAINDER in A — the S79
    "RNG16/6+10" reading was wrong; measured S85); HP -= dmg, KO at 0.
"""
from . import damage as D
from . import turn_order as T
from . import status as S

ATTACK = 0x3A
MASK = 0xFFFF

# $53:$4EE4 — 77 ids (FF-terminated) that the duplicate-cast conversion
# checks (byte-read S85 from the original ROM).
GROUP_DUP_SKILLS = frozenset([
    0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E,
    0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x16, 0x17, 0x18, 0x1D, 0x1F, 0x21,
    0x23, 0x2E, 0x2F, 0x30, 0x31, 0x32, 0x3B, 0x3C, 0x3E, 0x3F, 0x40, 0x48,
    0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x51, 0x52, 0x53, 0x57, 0x59,
    0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65,
    0x66, 0x69, 0x6A, 0x6B, 0x6D, 0x6E, 0x71, 0x78, 0x7C, 0x7D, 0xD6, 0xD7,
    0xD8, 0xD9, 0xDA, 0xDB, 0xDC])

# forced action codes written by the gate machine ($53:$462C)
FORCED_STUN = 0x11      # +7 & $C0
FORCED_PARALYSED = 0x13 # +2 bit6
FORCED_ASLEEP = 0x0F    # SleepWakeRoll: still asleep
FORCED_WAKES = 0xDB     # SleepWakeRoll: wakes (turn consumed)
ONESHOT_ACTIONS = ((2, 0x16), (0, 0x12), (1, 0x14), (3, 0x15), (4, 0x17), (5, 0x18))

# act-time re-resolve exemptions (jr_053_475e)
NO_RERESOLVE = frozenset([0x32, 0x96, 0x95, 0xAD])

# Quake chain (patched ROM, bank $72 QuakePowerTable): tier -> (min, max)
QUAKE_RANGE = {0xE5: (40, 60), 0xE6: (90, 120), 0xE7: (150, 190), 0xE8: (240, 270)}

# --------------------------------------------------------------------------
# S130 SKILL-EFFECT REGISTRY. The skill families (simulator/skillfx/*.py)
# plug the engine's remaining handlers in here, so the round core below stays
# one loop. Empty registries = the pre-S130 behaviour (every validator green).
#   ACTION_HANDLERS[id](ctx) -> state   takes over the whole action of skill
#        `id` after the act-time gates (veto, target, guard, unreachable, boss
#        gate). ctx = ActionCtx (b, a, sk, rec, f, core, t, qt, state, records,
#        log, idle). Use `default_victims(ctx, damage_fn)` for the usual
#        per-victim MISS machine + apply.
#   CORE_OVERRIDES[id] = core name      what damage_core reports (planning,
#        AI commit, coverage: anything not 'none' counts as modelled).
#   POST_CALC: [(order, fn)]  fn(b, a, v, sk, f, core, dmg, state) ->
#        (dmg, state) — the bank $53 post-calc stage ($53:$5880-$5A6F) in
#        the engine's order (crit, TwinHits, ChargeUP, SuckAir, $DB42 x1.5
#        = order 60, defence levels ...).
#   ACTOR_HOOKS: [fn(b, a, state, log) -> (handled, state)]  before the
#        actor's gates (airborne landings, follow-ups).
#   PHASE9_HOOKS: [fn(b, state, log) -> state]  after the phase-9 decay.
#   VICTIM_HOOKS: [fn(b, a, v, sk, f) -> v]  re-targeting at a victim
#        (reflect, absorb routing).
# --------------------------------------------------------------------------
ACTION_HANDLERS = {}
CORE_OVERRIDES = {}
# S130 F1: skills whose handler runs the BossProtectionGate itself, per
# victim after that victim's MISS step ($53:$51AA called from the $52 hit
# helpers) — simulate_round skips its whole-action pre-block for them.
BOSS_GATE_IN_HANDLER = set()
POST_CALC = []
ACTOR_HOOKS = []
PHASE9_HOOKS = []
VICTIM_HOOKS = []
# S130 F23: skills whose handler runs the engine's OWN per-target boss gate
# (Sacrifice $67A9) or none at all (Kamikaze: $3E is listed in
# BossProtectionGate_51aa but nothing on its path calls the gate) — the
# driver's whole-action boss gate below is skipped for them.
SELF_GATED = set()
# S130 F5: per-skill targets (the bank $58 row BtlSkillTargetDispatch_401d).
#   COMMIT_TARGETS[id](b, s, state) -> (slot, state)   the commit-time write
#        (pacing._commit_target).
#   TARGET_RESOLVERS[id](b, a, sk, qt, f, state) -> (slot, state)   the
#        act-time target (queue byte / re-resolve / dead redirect) in
#        simulate_round, replacing the generic resolution for that id.
COMMIT_TARGETS = {}
TARGET_RESOLVERS = {}
# S130 F8: skills whose ACTION_HANDLER runs the act-state-9 iron gate per
# hit itself (a multi-hit loop re-targets after a failed pass), so the
# whole-action target_unreachable pre-check is skipped for them.
OWN_TARGET_GATES = set()
# S130 F8: RERESOLVE_PICKERS[id](b, a, state) -> (slot|None, state) = the
# skill's own bank $58 per-skill resolver row, used by the act-time
# re-resolve / $FF-target branches instead of the plain-attack
# front-weighted pick (e.g. $51/$52/$53 -> $642C uniform, measured S130).
RERESOLVE_PICKERS = {}
# S130 F4: CRIT_STAGE(b, a, f, state) -> (None|'twin'|False|True, state) =
# act state $A ($53:$586A) between the MISS machine and the $52 handler (a
# crit skips the handler; the post-calc stage builds the damage from ATK).
# POST_ACTION_HOOKS: [fn(b, a, sk, f, state, log) -> state] at the end of
# an action ($52:$70A4); a hook may set b.ext['f4_again'] = a to make the
# same actor act again (Focus follow-up, d9ed $12).
CRIT_STAGE = None
POST_ACTION_HOOKS = []
# S130 F4: COMMIT_ROLL(b, s, bases, state) -> state = the bank $58 command-
# phase $DB42 roll after a party actor's commit (pacing.commit_round).
COMMIT_ROLL = None
# S130 F6: per-victim interception and after-effects inside default_victims
# (act state 7 $53:$5411 / act state 4 $52:$6ECF / $52:$7DD7 / $52:$71F8).
#   INTERCEPT_HOOKS: [fn(ctx, vi, v, state) -> (v, state, verdict)]  before
#        the iron gate and the MISS step; verdict None = act on v, 'skip' =
#        the hook resolved the victim (reflection), 'last' = act on v then
#        end the sweep (SuckAll absorb).
#   POST_HIT_HOOKS: [fn(ctx, v, dmg, state) -> state]  after an applied
#        non-KO hit and its rider, before the snap-out (BladeD counter).
#   POST_VICTIM_HOOKS: [fn(ctx, v, kind, dmg, ko, state) -> state]  after a
#        resolved victim ('dmg' / 'done') or a MISS-machine fail ('miss' /
#        'dodge' / 'block') (TakeMagic gain, Imitate).
#   POST_SWEEP_HOOKS: [fn(ctx, state) -> state]  after the victim loop
#        (SuckAll breath-back).
INTERCEPT_HOOKS = []
POST_HIT_HOOKS = []
POST_VICTIM_HOOKS = []
POST_SWEEP_HOOKS = []   # (S130 merge: F6's 'POST_ACTION_HOOKS', renamed — F4 owns that name)
# S130 F9: KO_HOOKS: [fn(b, t)] run at a KO before the status wipe — the KO
# state's slot reload (bank $51 entry 15 -> LoadBtlS_44a9: source stats /
# res / skills, also the transform & dragon revert) and the helper-slot
# branch ($DD1B := $FF, side summon bit2 cleared): skillfx/f9_meta.ko_revert.
KO_HOOKS = []


class ActionCtx:
    __slots__ = ('b', 'a', 'sk', 'rec', 'f', 'core', 't', 'qt', 'state', 'records',
                 'log', 'idle', 'real_sk')

    def __init__(self, **kw):
        for k, v in kw.items():
            setattr(self, k, v)


def rng_step(state):
    return (state * 5 + 0x1357) & MASK


def rng1(state):
    return (state >> 8) & 0xFF


def rng2(state):
    return state & 0xFF


# --------------------------------------------------------------------------
# Board — one battle snapshot, index = combatant slot 0-7
# --------------------------------------------------------------------------
class Board:
    """Mutable board. Built from a measure_battle.py event (from_event) or
    by hand. Arrays are per slot 0-7; st is 64 bytes ($DB00 layout, 8 per
    slot); res is 56 bytes (7 per slot)."""

    def __init__(self):
        self.hp = [0] * 8; self.maxhp = [0] * 8; self.mp = [0] * 8
        self.maxmp = [0] * 8
        self.atk = [0] * 8; self.dfn = [0] * 8; self.agl = [0] * 8
        self.int = [0] * 8; self.level = [0] * 8
        self.st = [0] * 64; self.res = [0] * 56
        self.dd13 = [0xFF] * 8; self.dd1b = [0xFF] * 8
        self.dd03 = [0] * 8; self.dd0b = [0] * 8; self.db8b = [0] * 8
        self.db42 = [0] * 8               # per-combatant flags; bit6 = x1.5 boost (S89)
        self.queue = [0xFF] * 16
        self.eid = [0, 0, 0]
        self.db73 = 1; self.link = False
        self.side_seal = [0, 0]           # $DB00/$DB01 bit3
        # S130 (skill coverage): per-slot facts the skill families read.
        self.species = [0xFF] * 8         # $DC3C[slot] -> species (LookupTargetSpecies)
        self.family = [0xFF] * 8          # that species' family (0 Slime .. 8 Material, 9 ???/Boss, 10 Spirit)
        self.base = {k: [0] * 8 for k in ('maxhp', 'maxmp', 'atk', 'dfn', 'agl', 'int')}
                                          # the source stats before any buff (bank $57 entries 4-8)
        self.ext = {}                     # family modules' own state (simulator/skillfx/)

    def snapshot_base(self):
        """Record the current stats as the battle-start base (bank $57
        entries 4-8 read the source row / record, which equals the stats the
        battle starts with)."""
        for k in self.base:
            self.base[k] = list(getattr(self, k))

    @classmethod
    def from_event(cls, e):
        b = cls()
        for k in ('hp', 'maxhp', 'mp', 'atk', 'dfn', 'agl', 'int', 'st', 'res',
                  'dd13', 'dd1b', 'dd03', 'dd0b', 'db8b'):
            setattr(b, k, list(e[k]))
        if 'db42' in e:                   # S89: $DB42 per-combatant flags
            b.db42 = list(e['db42'])
        if 'maxmp' in e:
            b.maxmp = list(e['maxmp'])
        b.level = list(e['db9b']); b.queue = list(e['dcec']); b.eid = list(e['eid'])
        b.db73 = e['db73']; b.link = bool(e['c86c'])
        b.side_seal = [(e['st'][0] >> 3) & 1, (e['st'][1] >> 3) & 1]
        return b

    def stb(self, slot, off):
        return self.st[slot * 8 + off]

    def set_stb(self, slot, off, v):
        self.st[slot * 8 + off] = v & 0xFF

    def valid(self, slot):
        """CheckMonsterSlot: 0 <= slot < 8 and $DD1B[slot] == 0 (alive)."""
        return 0 <= slot < 8 and self.dd1b[slot] == 0

    def live_side(self, base):
        return [s for s in range(base, base + 3) if self.valid(s)]

    def flying(self, slot):
        return bool(self.db8b[slot] & 0x10)

    def q_skill(self, slot):
        return self.queue[slot * 2]

    def q_target(self, slot):
        return self.queue[slot * 2 + 1]


# --------------------------------------------------------------------------
# Round start: turn order
# --------------------------------------------------------------------------
def ready_slots(b):
    return [s for s in range(8) if b.dd13[s] == 2 and b.dd1b[s] == 0]


def round_order(b, state, ninth_key=0, ninth_id=0xFF):
    slots = [(s, b.agl[s], b.q_skill(s)) for s in ready_slots(b)]
    order, entries, state = T.round_order(slots, state, ninth_key, ninth_id)
    return order, state


# --------------------------------------------------------------------------
# Per-actor: status gates ($4558), curse, dup-conversion, MP/seal veto
# --------------------------------------------------------------------------
def status_forced_action(b, a, state):
    """Gates BEFORE the RNG step. `state` = RNG as found at gate entry (the
    sleep roll reads RNG1 without stepping). Returns forced code or None;
    mutates the sleep byte.

    S130 F1 (byte-read $53:$462C + measured 2 battles, multi-bit +5): EVERY
    forced code — iron $11, paralysis $13, sleep $0F/$DB and the one-shots —
    goes through Jump_053_462c -> SaveBtlC_4b39, which does actor +5 &= $C0:
    ALL pending one-shot bits are dropped at once (not only the consumed
    one), and a sleeping / paralysed / iron actor loses its pending
    one-shots without ever performing them."""
    code = _forced_code(b, a, state)
    if code is not None:
        b.set_stb(a, 5, b.stb(a, 5) & 0xC0)    # S130 F1: SaveBtlC_4b39
    return code


def _forced_code(b, a, state):
    if b.stb(a, 7) & 0xC0:
        return FORCED_STUN
    b2 = b.stb(a, 2)
    if b2 & 0x40:
        return FORCED_PARALYSED
    if b2 & 0x80:
        nb, awake = S.sleep_wake(b2, state)
        b.set_stb(a, 2, nb)
        return FORCED_WAKES if awake else FORCED_ASLEEP
    b5 = b.stb(a, 5)
    if b5 & 0x3F:
        for bit, code in ONESHOT_ACTIONS:
            if b5 & (1 << bit):
                # priority bit2 > 0 > 1 > 3 > 4 > 5 ($53:$4594-$45C8)
                return code
    return None


def curse_fires(b, a, state_post_step):
    """+2 bit5 and RNG1 < $40 after the LoadBtlC_4e33 step."""
    return bool(b.stb(a, 2) & 0x20) and rng1(state_post_step) < 0x40


def curse_effect(b, a, state_post_step):
    """CurseSelfHit_4c50 (byte-read + measured S85 3/3 + S88 amounts): the SAME step's
    RNG2 picks the effect —
      < $40  'skip'    : msg $1A, the turn is lost (d9ee=4);
      < $80  'hp'      : msg $1B, HP -= MaxHP/6 (borrow -> 0 = death),
                         then the actor still acts;
      < $C0  'mp'      : msg $1C, MP -= MaxMP//6 (skipped when MaxMP==0;
                         amount measured S88 4/4), then the actor still acts;
      else   'confuse' : msg $19, +2 bit4 set and the turn becomes the
                         confusion rewrite path (d9ed=$11).
    Returns the effect name; mutates the board."""
    r2 = rng2(state_post_step)
    if r2 < 0x40:
        return 'skip'
    if r2 < 0x80:
        if b.hp[a]:
            d = b.maxhp[a] // 6
            b.hp[a] = max(b.hp[a] - (d & 0xFF), 0)
            if b.hp[a] == 0:
                b.dd1b[a] = 1; b.dd13[a] = 0xFF
        return 'hp'
    if r2 < 0xC0:
        # MaxMP//6 (S88, measured 4/4 on MaxMP 88 -> 14; skipped when
        # MaxMP == 0 per the byte-read guard)
        if b.maxmp[a]:
            b.mp[a] = max(b.mp[a] - b.maxmp[a] // 6, 0)
        return 'mp'
    b.set_stb(a, 2, b.stb(a, 2) | 0x10)
    return 'confuse'


# --------------------------------------------------------------------------
# Confusion (S88: byte-read $53:$4BEB + $52:$4E3A-$4EF8, measured 23/23)
# --------------------------------------------------------------------------
# Meta-action ids a confused actor's turn is rewritten to. The old
# "ConfusionActionTable_7aff {$3A,$5E,$62,$80}" attribution (S79) was WRONG
# — that table is the Transform/BeDragon ($AA/$D5) action picker.
CONF_HITALLY, CONF_HITENEMY, CONF_HITRANDOM = 0x99, 0x9A, 0x9B
CONF_SCARED, CONF_DANCE, CONF_TRIP = 0x9C, 0x9D, 0x9E
CONF_PARA, CONF_CANTMOVE, CONF_RUN = 0x9F, 0xA0, 0xA1
CONF_META_IDS = set(range(0x99, 0xA2))
SNAP_MASK = 0x63        # on-hit snap-out: clears sleep flag+counter AND confusion


def confusion_pick(b, a, state):
    """$53:$4BEB (act state $11): one RNG step per iteration, then
    RNG1 bit1 -> $99 HitAlly; else bit0 -> $9A HitEnemy; else the &3==0
    fork — non-link ENEMY attackers roll $9A+(RNG2&7) with the $A1 RUN
    result re-running the whole routine when $DB73!=0; party (or link)
    attackers roll RNG2<$55 -> $9E Trip else $9B/$9C by RNG2&1.
    Measured 10/10 incl. a live RUN and the blocked-$A1 re-roll guard."""
    while True:
        state = rng_step(state)
        r1, r2 = rng1(state), rng2(state)
        if r1 & 2:
            return CONF_HITALLY, state
        if r1 & 1:
            return CONF_HITENEMY, state
        if not b.link and a >= 4:
            x = 0x9A + (r2 & 7)
            if x != CONF_RUN or b.db73 == 0:
                return x, state
            continue                      # jr jr_053_4beb: full re-run
        return (CONF_TRIP, state) if r2 < 0x55 else (0x9B + (r2 & 1), state)


def uniform_side_pick(b, base, state):
    """$58:$63EC/$63FD (resolver $642C / $6479): one RNG step, then the
    (RNG1 mod live_count + 1)-th live slot scanning up from `base`.
    UNIFORM — unlike the front-weighted plain-attack pick (§15.10.10).
    Shared by HighJump/QuadHits/CallHelp/YellHelp/HitEnemy/Trip (opposing
    base) and HitAlly (own base). Returns (slot|None, state)."""
    live = [s for s in range(base, base + 3) if b.valid(s)]
    state = rng_step(state)
    if not live:
        return None, state
    return live[rng1(state) % len(live)], state


def snap_out(b, v, flags9, state):
    """$53:$5F15 act-state-5 on-hit snap-out (S88, measured 8/8): after a
    LANDED skill with flags9 bit3 (physical-contact family, 42 ids) on a
    victim whose +2 & $90 (asleep|confused): one RNG step; RNG1 < $AA
    (party/link victim) or < $40 (non-link enemy victim) -> +2 &= $63,
    clearing sleep flag+counter and confusion, keeping DoT/paralyze/curse.
    Whiffs, misses and non-bit3 skills (verified: Infernos) never roll.
    Returns (rolled, snapped, state)."""
    if not (flags9 & 0x08) or not (b.stb(v, 2) & 0x90):
        return False, False, state
    state = rng_step(state)
    thr = 0x40 if (not b.link and v >= 4) else 0xAA
    if rng1(state) < thr:
        if b.stb(v, 2) & 0x80:
            # S130 F1 ($53:$5F6E -> LoadBtlC_5fa7, measured g2_L1/g2_keep):
            # a SLEEPING victim that snaps awake loses its turn this round —
            # $DD13[victim] := 3 ("wakes up", msg $DB). The confusion-only
            # snap (next sub-state) does not touch $DD13.
            b.dd13[v] = 3
        b.set_stb(v, 2, b.stb(v, 2) & SNAP_MASK)
        return True, True, state
    return True, False, state


RIDER_RTYPE = {0x67: 18, 0x69: 19, 0x68: 7}


def rider_roll(b, v, sk, state):
    """PoisonHit/Paralyze status rider (S88, byte-read $52:$65B5/$65C9 +
    measured 34/34): runs after the damage apply. Skip (no roll, no step)
    when the target already carries a DoT (+2 & 3, poison rider) / bit6
    (paralyze). $69's $65B5 prologue runs BossProtectionGate first —
    vetoed = fail with NO RNG step (presumed step-free; per-event
    injection insulates). Else: level = res rtype 18 (poison, res+4
    bits1:0) / 19 (paralysis, res+5 bits7:6) through LADDER_HIT_STATUS
    (row by target +5 bit7 only), one BattleRNG step, hit = RNG1 < thr.
    Returns (hit|None, state); applies the bit on hit. Model order
    rider-then-snap is a presumption (no overlapping sample yet)."""
    off, mask = PHYS_STATUS_RIDER[sk]
    if b.stb(v, off) & (0x03 if sk == 0x67 else mask):
        return None, state
    if sk == 0x69 and not b.link and v >= 4 and b.db73 == 1:
        # $65B5 prologue = BossProtectionGate: rider-application veto ONLY
        # (the physical damage already landed) — the FULL-action block set
        # in damage.BOSS_PROTECTED_SKILLS no longer includes $69 (S88).
        return False, state
    lev = D.res_level(bytes(b.res[v*7:v*7+7]), RIDER_RTYPE[sk])
    # ALL riders roll the $6749 STATUS ladder — $5C8F routes only skill
    # $15 (Sleep proper) to the B-ladder $6710; $68 goes to $6749 like
    # the $65B5/$65C9 helpers (byte-read $5CAE-$5CBB, S88).
    thr = D.LADDER_HIT_STATUS[0x80 if (b.stb(v, 5) & 0x80) else 0][lev]
    state = rng_step(state)
    hit = True if thr is None else (False if thr == 0 else rng1(state) < thr)
    if hit:
        b.set_stb(v, off, b.stb(v, off) | mask)
    return hit, state


def guard_redirect(b, t, flags8=0x02):
    """[S89] Cover $88 / Guardian $89 act-time interception (the
    $53:$670E dispatcher region). The one-round guard record for slot t
    lives one slot shifted: $DB08+8t bit4 = protected, $DB09+8t high
    nibble = protector (physically slot t+1's +0/+1 — status.py map).
    A live mark rewrites BOTH wBattleTargetIdx and the attacker's queue
    target to the protector (msg $80). Differentially proven on the
    real save: every attack aimed at the protected slot landed on the
    protector. Marks are set at the defensive cast (which is why that
    class gets the +$0600 turn-order boost) and cleared at the round
    boundary. The main-path consumers are gated on the acting skill's
    cached flags8 bit1 ($DCFE checks at $53:~$552x/$567x) — pass flags8
    so non-interceptable classes pass through."""
    if t is None or t >= 7:
        return t
    if not (flags8 & 0x02):
        return t
    if b.stb(t + 1, 0) & 0x10:
        prot = (b.stb(t + 1, 1) >> 4) & 0x0F
        # S130 F6: the protector test is GetMonsterSlotInfo ($53:$54FA): an
        # asleep / paralysed / confused / one-shot-pending / iron protector
        # does not intercept (measured, p_coverslp).
        if (b.valid(prot) and b.hp[prot] > 0 and not (b.stb(prot, 2) & 0xD0)
                and not (b.stb(prot, 5) & 0x3F) and not (b.stb(prot, 7) & 0xC0)):
            return prot
    return t


def target_unreachable(b, t, flags8, skill):
    """Act state 9 pre-gate ($53:$56E1): a target whose +7 & $C0 counter
    is running — [S89] the counter is the IRONIZE state (Ironize $2A /
    IRONIZE $DC self-cast, 3 rounds; status.py) — and a skill with
    flags8 bit2 (near-universal on offense) -> the action fails with
    msg $BA: full physical AND magical immunity while iron, measured
    S89 under sustained Attack and Blaze. Skills $52/$53
    CallHelp/YellHelp and $14 Sacrifice are exempt. Measured S85
    (stun_st, 2/2)."""
    if not (b.stb(t, 7) & 0xC0):
        return False
    if not (flags8 & 0x04):
        return False
    return skill not in (0x52, 0x53, 0x14)


def dup_conversion(b, a, order, cursor, eid_flag):
    """LoadBtlC_4e63 (byte-read + measured S85, literal scan). eid_flag =
    $53:$41DF row of the actor's EID (extracted/enemy_dupconv_flags.json).

    The scan walks $DB79 from the START with b = cursor: a PARTY entry
    decrements b (b==0 -> no conversion); an ENEMY entry is compared
    (queued skill == the actor's AND in GROUP_DUP_SKILLS -> convert) and
    does NOT decrement b. The actor's OWN entry is never excluded, so it
    matches itself: an enemy converts iff at least one ENEMY entry
    precedes it in the round order (the earlier enemy's skill is
    irrelevant) — unless $DD0B==2 keeps the cast. Returns True when the
    queued skill is replaced by $3A (target byte -> $FF, re-resolved)."""
    if b.link or a < 4 or a == 7 or not eid_flag or cursor == 0:
        return False
    sk = b.q_skill(a)
    cnt = cursor
    for entry in order:
        if entry == 0xFF:
            return False
        if entry < 4:
            cnt -= 1
            if cnt == 0:
                return False
            continue
        if b.q_skill(entry) == sk and sk in GROUP_DUP_SKILLS:
            return b.dd0b[a] != 2
    return False


def act_mp_veto(b, a, skill, mp_cost, flags7):
    """SetupSub_480e. Returns None (proceed), 'mp' (turn wasted / re-decide
    for $DD0B==2) or a seal code $1F/$1E/$21/$20."""
    if mp_cost and b.mp[a] < mp_cost and not mp_veto_exempt(b, a, skill):   # S130 F5
        return 'mp'
    if flags7 & 0x40:
        if b.side_seal[(a >> 2) & 1]:
            return 0x1F
        if b.stb(a, 3) & 0x01:
            return 0x1E
    elif flags7 & 0x20:
        if b.stb(a, 3) & 0x40:
            return 0x21
    elif flags7 & 0x10:
        if b.stb(a, 3) & 0x80:
            return 0x20
    return None


def mp_veto_exempt(b, a, skill):
    """[S130 F5] LoadBtlC_493d ($53:$493D): the afford check is waived for
    the 2nd turn of a two-turn skill — own +6 bit2 set: only HighJump $42
    (else NOT exempt, +7 unread); else +7 bit4 set: only LifeSong $95."""
    if b.stb(a, 6) & 0x04:
        return skill == 0x42
    if b.stb(a, 7) & 0x10:
        return skill == 0x95
    return False


def act_mp_spend(b, a, skill, mp_cost, flags7):
    """[S130 F5] LoadBtlC_4a04 ($53:$4A04, after the veto passes; ALSO on
    the StopSpell/DanceShut/MouthShut veto paths) — the act-time MP
    DEDUCTION (measured: HealUs 200 -> 182 between skill load and target
    fetch). Skipped when $DB42[a] bit4, and by CmpBtlC_4b92 for HighJump
    $42 with +6&$0C (landing), LifeSong $95 with +7&$30 (2nd turn) and
    any flags7-bit6 spell while the caster's side seal ($DB00/01 bit3) is
    up ($32/$66/$96 always pay). MP -= record +4 (16-bit); Farewell $32
    then sets MP := 0 (the record's 'All MP', measured 200 -> 0)."""
    if b.db42[a] & 0x10:
        return
    if skill == 0x42 and (b.stb(a, 6) & 0x0C):
        return
    if skill == 0x95 and (b.stb(a, 7) & 0x30):
        return
    if (skill not in (0x32, 0x42, 0x66, 0x95, 0x96) and (flags7 & 0x40)
            and b.side_seal[(a >> 2) & 1]):
        return
    b.mp[a] = (b.mp[a] - mp_cost) & 0xFFFF
    if skill == 0x32:
        b.mp[a] = 0


def reresolves(b, a, skill):
    """SetupSub_4692 -> TargetReResolve_4799 predicate (valid target case).
    Order as in jr_053_4733: Sacrifice re-resolves whenever the caster's
    +3 bit0 is clear (BEFORE the $DD0B check); $32/$96/$95/$AD never;
    then $DD0B==0 keeps, confused keeps, tactic byte==3 keeps."""
    if skill == 0x14:
        return not (b.stb(a, 3) & 1)
    if skill in NO_RERESOLVE:
        return False
    if b.dd0b[a] == 0:
        return False
    if b.stb(a, 2) & 0x10:
        return False
    if b.dd03[a] == 3:          # full-byte compare (enemies hold $FF here)
        return False
    return True


def keeps_dead_target(b, a):
    """$53:$47B2 for a single-target skill whose queued target is dead:
    LoadBtlC_49dc ($DD0B == 0) or LoadBtlC_4e01 ($DD72 == 0 — always so in
    the act phase — and $DD03 == 3 (full byte: an obeyed order) and the
    round plan wMenu_selection == $81) -> `ret z`: no re-pick, the action
    fizzles. [S130 P3.15b, measured by simulator/validate_command.py; the
    plan byte is b.ext['plan'], set by pacing.commit_round.]"""
    if b.dd0b[a] == 0:
        return True
    return b.dd03[a] == 3 and b.ext.get('plan') == 0x81


def dead_redirect(b, target):
    """DeadTargetRedirectScan_47e8: first valid slot on the target's side."""
    base = target & 4
    for s in range(base, base + 3):
        if b.valid(s):
            return s
    return None


# --------------------------------------------------------------------------
# Act-time MISS / dodge machine ($53:$5747)
# --------------------------------------------------------------------------
def miss_gate(b, a, t, flags7, flags8, state_post_step):
    """Returns 'block' | 'miss' | 'dodge' | 'pass'. `state_post_step` = RNG
    after the machine's own LoadBtlC_4e33 step (all reads share it). The
    block check (gate 1) precedes the step and reads no RNG."""
    if (flags7 & 0x80) and (b.stb(t, 6) & 0x04):
        return 'block'
    r1, r2 = rng1(state_post_step), rng2(state_post_step)
    if flags7 & 0x02:
        if (b.stb(a, 3) & 0x02) and r1 < 0xA0:
            return 'miss'
        if (b.stb(a, 7) & 0x03) and r2 < 0x60:
            return 'miss'
    if flags8 & 0x80 and b.valid(t):
        # GetMonsterSlotInfo guard (S88, byte-read $00:$9763-area + measured
        # conf_e1): an INCAPACITATED target — +2 & $D0 (asleep/paralyzed/
        # confused), +5 & $3F (one-shot pending) or +7 & $C0 (stun) —
        # cannot dodge; the whole dodge section is skipped.
        if (b.stb(t, 2) & 0xD0) or (b.stb(t, 5) & 0x3F) or (b.stb(t, 7) & 0xC0):
            return 'pass'
        # LoadBtlC_5857: skill $41 with attacker +6&3 == 0 skips the dodge
        # (handled by the caller via skill; not in corpus)
        if b.stb(t, 7) & 0x0C:
            if (r1 & 1) == 0:
                return 'dodge'
            # S130 F1 + F8 (found independently, both measured: SideStep target AGL 511
            # RNG1 29 -> dodge; bi_dodge RNG1 $03 vs AGL 40 -> dodge): an odd RNG1
            # FALLS THROUGH to the AGL ladder ($53:$57C1 `jp z` / jr_053_57c8) — it used
            # to return 'pass' here.
        agl = b.agl[t]
        thr = 0x2B if agl >= 0x1C0 else (0x08 if agl >= 0x20 else 0x02)
        if r1 < thr:
            return 'dodge'
    return 'pass'


# --------------------------------------------------------------------------
# Victim enumeration for group casts
# --------------------------------------------------------------------------
def quake_victims(b, caster, first_target):
    """Earthquake chain sweep (patched, §13.7 v3): every LIVE slot of the
    committed side is VISITED (target fetch + gate machine), then the own
    side (caster skipped) at /3; flying victims are visited but take no
    damage (the v3 "fly-dodge beat" — measured S85: 3 flying Gremlins all
    visited, none damaged). Returns [(slot, divisor)]; damage applies iff
    not b.flying(slot)."""
    base = first_target & 4
    # S130 F9: the sweep ceiling is slot 3/7 (QuakeSweep72 keeps the vanilla
    # $52:$719C bound): a live helper is visited on both sides (measured).
    v = [(s, 1) for s in range(base, base + 4) if b.valid(s)]
    own = caster & 4
    v += [(s, 3) for s in range(own, own + 4) if s != caster and b.valid(s)]
    return v


def side_victims(b, first_target, start=None):
    """Side sweep victim list. [S89] The sweep begins at the QUEUED
    target and walks FORWARD to the end of that side — not from the
    side base (measured: a $0A queued on slot 5 swept [5,6], never
    touching 4). When the queued target IS the side base the two
    readings coincide, which is why every pre-S89 corpus agreed."""
    base = first_target & 4
    s0 = base if start is None else max(base, min(start, base + 2))
    # S130 F9: GroupVictimLoopA ($52:$719C) stops AT slot 3/7, so a live
    # helper is the last victim (measured both sides: [0,1,2,3], [4,5,6,7])
    return [s for s in range(s0, base + 4) if b.valid(s)]


# --------------------------------------------------------------------------
# Apply + KO
# --------------------------------------------------------------------------
GUARD_SKILLS = {0x88: 'one', 0x89: 'allies'}   # S89: Cover / Guardian


def set_guard_mark(b, caster, target):
    """[S89] Writer for the one-round guard table (bank $53 ~$4Fxx),
    measured: the record for a protected slot t lives ONE SLOT SHIFTED
    at $DB08+8t bit4 (= slot t+1's status +0 bit4) with the protector's
    index in the high nibble of $DB09+8t (slot t+1's +1).

    Cover $88 marks the single targeted ally; Guardian $89 marks BOTH
    other allies on the caster's side (never the caster itself). The
    engine's writer is first-protector-wins (it skips a slot that is
    already marked) and preserves the LOW nibble of the +1 byte, which
    is the separate $8D/$8E/$90 defence-level field."""
    own = caster & 4
    slots = ([target] if target is not None else
             [s for s in range(own, own + 3) if s != caster])
    for t in slots:
        if t is None or not (0 <= t < 7) or t == caster:
            continue
        gi = (t + 1) * 8
        if b.st[gi] & 0x10:            # first protector wins
            continue
        b.st[gi] |= 0x10
        b.st[gi + 1] = (b.st[gi + 1] & 0x0F) | ((caster & 0x0F) << 4)


def clear_guard_marks(b):
    """Marks are one-round: cleared at the round boundary (measured)."""
    for t in range(7):
        gi = (t + 1) * 8
        b.st[gi] &= ~0x10 & 0xFF
        b.st[gi + 1] &= 0x0F


def db42_boost(b, attacker, dmg):
    """[S89, byte-decoded at $53:$59CD + measured 8/8] A per-combatant
    damage boost the pre-S89 model missed entirely: the post-calc stage
    reads `$DB42 + attacker` and, if **bit 6** is set, replaces the
    damage with `dmg + (dmg >> 1)` = **x1.5** (the engine does it as
    16-bit `hl = dmg; bc = dmg; hl >>= 1; hl += bc`, i.e. srl h / rr l /
    add hl,bc — so the HALF is truncated, not the product).

    This runs AFTER CalcSkillDefense and after DamageSlot2AdjustFloor,
    on the value already stored in $DB56/57, so it stacks on top of the
    slot-2 x0.8 and the zero floor rather than replacing them. It is the
    writer that produced the long-standing "low-stat calcdef edge":
    fresh_c r3 rolled 4 and applied 6 (4 + 4>>1). Correlation over the
    whole battle was exact — every hit with db42 bit6 clear applied the
    rolled value 1:1, the single hit with it set applied x1.5 (8/8).

    Observed lifecycle: set during the command/order phase ($D9EC==5)
    and cleared in phase 9, i.e. it is a ONE-ROUND mark on the actor.
    The SETTER is not yet located (not a plain `set 6,[hl]` / `or $40` /
    `ld [hl],$40` on a $DB42 pointer anywhere in banks $50-$5F) — see
    ROADMAP; the consumer and its arithmetic are exact and that is what
    the damage model needs.
    [S130 F4] SETTER FOUND: $58:LoadBtlFX_5ba1 -> SetBtlFX_5b17 (`ld a,[hl]
    / or d / ld [hl],a`, d = $40), the command-phase tension roll for party
    slots 0-2 (w3 base $DC5C >= $81: 1/2/4/8 in 256) — modelled in
    skillfx/f4_charge.roll_5ba1 (pacing.commit_round via COMMIT_ROLL)."""
    if 0 <= attacker < 8 and (b.db42[attacker] & 0x40):
        return dmg + (dmg >> 1)
    return dmg


def ko_wipe(b, t):
    """S130 F1 (byte-read $51:LoadBtlS_4c26, run by the KO state $1A ->
    bank $51 entry 15 sub-state 2; measured beat_ko: +2/+3/+5/+7 and the
    shifted +8 all zeroed): a KO zeroes the dead slot's status bytes
    $DB02+8t..$DB09+8t — +2..+7 plus its shifted guard/marker pair (+3 via
    BitBtlS_4ca0, which first reverts a transform). Pending one-shots,
    seals, iron, SandStorm/SideStep, EerieLite rows all die with it."""
    for hook in KO_HOOKS:                  # S130 F9: KO reload (form revert)
        hook(b, t)
    for k in range(t * 8 + 2, min(t * 8 + 10, 64)):
        b.st[k] = 0
    b.side_seal = [(b.st[0] >> 3) & 1, (b.st[1] >> 3) & 1]


def apply_damage(b, t, dmg):
    """BtlActState2Apply: HP -= dmg floored at 0; on KO the engine marks
    $DD1B:=1 / $DD13:=$FF. (The KO state $1A shows a TRANSIENT full-HP
    value in the slot during its second tick — the source MaxHP, seen on
    both sides S85 — before the slot settles at 0; only a battle-ending
    KO leaves the transient in place.) Returns True on KO."""
    hp = b.hp[t] - dmg
    if hp <= 0:
        b.hp[t] = 0
        b.dd1b[t] = 1
        b.dd13[t] = 0xFF
        ko_wipe(b, t)                      # S130 F1
        return True
    b.hp[t] = hp
    return False


def side_wiped(b, base):
    """A side with no live combatant. S130 F1 (byte-read $52:BattleFunc_76c8,
    run after every action via BattleCall_710e, and the phase-9 twin
    $50:$6CD3; measured g3_E_L0: PalsyAir paralysing all three party members
    ended the battle mid-round): the PARTY side — and either side in a link
    battle — also counts as wiped when every live member is PARALYSED
    (+2 bit6), which no gate ever lifts. A non-link enemy side wipes on
    death only."""
    if base == 0 or b.link:
        return not any(b.valid(s) and not (b.stb(s, 2) & 0x40) for s in range(base, base + 3))
    return not any(b.valid(s) for s in range(base, base + 3))


# --------------------------------------------------------------------------
# Phase 9: end-of-round status decay + DoT
# --------------------------------------------------------------------------
def phase9_decay(b):
    """$50:$6ABC sub 0, all 8 status blocks (byte-exact)."""
    st = b.st
    for base in (0, 1):
        st[base] &= ~0x50 & 0xFF
    for s in range(8):
        o = s * 8
        st[o + 4] &= 0x7F
        v = st[o + 6]
        st[o + 6] = (((v >> 1) | ((v & 1) << 7)) & 0x55)
        v = st[o + 7]
        if v & 0x30:
            st[o + 7] = (v & 0xCF) | ((v >> 1) & 0x10)
        nxt = (o + 8) % 64 if s < 7 else 64   # the loop's +0/+1 of the NEXT block
        if nxt < 64:
            st[nxt] &= 0xC0
            st[nxt + 1] = 0
        else:
            # slot 7's successor is $DB40/$DB41 (outside the blocks): ignored
            pass
    b.side_seal = [(st[0] >> 3) & 1, (st[1] >> 3) & 1]


def dot_damage(b, s, state):
    """Sub 2 for one live combatant. `state` = RNG as found (no step).
    Returns (kind, dmg) with kind in {None, 'counter', 'poison', 'heavy'}."""
    v7 = b.stb(s, 7)
    if v7 & 0xC0:
        b.set_stb(s, 7, ((v7 & 0xC0) - 0x40) | (v7 & 0x3F))
        return 'counter', 0
    v2 = b.stb(s, 2) & 3
    if not v2:
        return None, 0
    if v2 & 1:
        return 'poison', S.poison_tick(b.maxhp[s], state)
    return 'heavy', S.heavy_dot_tick(b.maxhp[s], state)


# --------------------------------------------------------------------------
# Damage cores by skill id (the ids the S85 corpus exercised; extend as
# validated).  'calcdef' = CalcSkillDefense physical roll (+ multiplier),
# 'record' = record power roll (+ ladder), 'quake' = patched tier table,
# 'none' = no damage core (status / meta / vetoed).
# --------------------------------------------------------------------------
PHYSICAL_IDS = {0x3A: 1, 0x67: 1, 0x68: 1, 0x69: 1, 0x3B: 1.5, 0x56: 1.5, 0x99: 1, 0x9A: 1, 0x9B: 1, 0xE9: 'mourn'}
# $56 PsycheUp SHARES handler $462F with $3B TwinSlash (S88): an immediate
# x1.5 calcdef hit — there is NO charge/carry-over mechanism on PsycheUp.
HEAL_IDS = {0x2B, 0x2C}                       # SkillHeal: record roll, HP += roll capped
# Status spells: id -> (status byte offset, mask, hit ladder, rtype).
# Sleep ($5C8F), StopSpell ($5CBC) and Surround ($5CDA, every id but $72)
# all roll through CheckTargetGuardB = $52:$6710: rows [always, D8, 7F,
# never] / guard bit6 [always, BF, 66, never] / amp bit7 [always, always,
# BF, never] = damage.LADDER_HIT_B (one BattleRNG step inside the
# threshold). $DB42[attacker] bit2 = sure-hit (Compare_6adc; not in
# corpus); res level 3 = never. Already-afflicted targets get the
# "already" message and NO roll (byte-read + measured S85, 87 casts).
STATUS_SPELLS = {0x15: (2, 0x8C, 'B', 7), 0x17: (3, 0x01, 'B', 10),
                 0x18: (3, 0x02, 'B', 6)}
# physical hits with a status rider (S88, modelled: rider_roll, 41/41):
# $67 PoisonHit -> poison (statchance/$65C9, rtype 18), $69 Paralyze ->
# paralysis (statchance/$65B5, rtype 19, boss-vetoed), $68 SleepHit ->
# sleep $8C via $5C8F (status_roll waypoint) with rtype 7 — but through
# the $6749 STATUS ladder: only Sleep $15 itself gets the B-ladder $6710.
PHYS_STATUS_RIDER = {0x67: (2, 0x01), 0x69: (2, 0x40), 0x68: (2, 0x8C)}
# $6D PoisonAir sets +2 bit1 = the HEAVY DoT (MaxHP/6) — the applier the
# S79 status table left OPEN (measured S85).
AIR_STATUS = {0x6D: (2, 0x02)}


def damage_core(skill, record):
    if skill in CORE_OVERRIDES:
        return CORE_OVERRIDES[skill]
    if skill in QUAKE_RANGE:
        return 'quake'
    if skill in PHYSICAL_IDS:
        return 'calcdef'
    if skill in HEAL_IDS:
        return 'heal'
    if skill in STATUS_SPELLS or skill in AIR_STATUS:
        return 'status'
    if record:
        f = record['battle_record']['fields']
        if f['power_party_min'] or f['power_enemy_min'] or f['power_party_range']:
            return 'record'
    return 'none'


def status_spell_roll(b, a, t, skill, state):
    """SetHLBattle_5c8f/5cbc/5cda: returns (outcome, new_state) with outcome
    'already' (no roll), 'hit' or 'miss'. $DB42[a] bit2 = sure-hit (not in
    corpus); res level 3 = never."""
    off, mask, lad, rtype = STATUS_SPELLS[skill]
    if b.stb(t, off) & mask:
        return 'already', state
    lev = D.res_level(bytes(b.res[t*7:t*7+7]), rtype)
    ladder = D.LADDER_HIT_B if lad == 'B' else D.LADDER_HIT_STATUS
    hit, state = D.hit_roll(ladder, b.stb(t, 5), lev, state)
    return ('hit' if hit else 'miss'), state


def apply_status(b, t, skill):
    off, mask = (STATUS_SPELLS.get(skill) or PHYS_STATUS_RIDER.get(skill) or AIR_STATUS[skill])[:2]
    b.set_stb(t, off, b.stb(t, off) | mask)


def heal_target(b, caster):
    """Re-resolved heal target = the lowest-HP live ally (observed S85,
    1 sample; the bank $58 row for $2B is the HP-need scan $77B4)."""
    own = caster & 4
    live = [s for s in range(own, own + 3) if b.valid(s)]
    return min(live, key=lambda s: b.hp[s]) if live else None


def apply_heal(b, t, amount):
    b.hp[t] = min(b.hp[t] + amount, b.maxhp[t])


def mourn_multiplier(b, caster):
    """$E9 Mourn: x (dead allies + 1); dead = own side $DD1B == 1."""
    own = caster & 4
    dead = sum(1 for s in range(own, own + 3) if b.dd1b[s] == 1)
    return dead + 1


# --------------------------------------------------------------------------
# Round DRIVER for offline simulation (pacing sweeps). Strings the validated
# rules above together in the engine's order. NOT itself differentially
# validated as a whole: the engine's RNG is idle-stepped between waypoints
# by a frame-timing-dependent count (KEY_LESSONS S85), so a simulation must
# choose an RNG policy. `idle(state, cls)` is called at exactly the sites
# the S86 corpus measurement found the engine idling (simulator/
# measure_idle.py; class names match s86_idle_model.json):
#   round_gap        before the order build (between rounds)
#   post_order       after the order build, before the first actor
#   post_action /    at each subsequent actor boundary — post_action after
#   actor_skip       a completed action, actor_skip after a skipped one
#   pre_target       before target resolution, and again between victims
#   pre_miss         before each victim's MISS machine (attack animation)
#   p9_entry         entering phase 9
#   post_dot_apply   after a slot takes DoT damage (damage animation)
# Measured NON-sites (same-frame, deterministic — do NOT idle there): the
# whole gate/curse block after actor fetch; MISS machine -> damage/status
# core; consecutive phase-9 slot rolls (k == 0: un-damaged neighbours read
# an IDENTICAL RNG state — an engine quirk the model preserves).
# Default idle=None = identity (deterministic chain, the pre-S86
# behaviour). Remaining engine-owned stand-ins (status-rider chances,
# curse MP-drain amount) are marked at their sites; confusion turns and
# the on-hit sleep/confusion snap-out are fully modelled (S88, 23/23).
# The multi-candidate target pick for plain attack uses the decoded
# front-weighted roll (§15.10.10) via pick_front_weighted; the six
# $642C-resolver skills use uniform_side_pick.
# --------------------------------------------------------------------------
def pick_front_weighted(cands, state):
    """$58:$441B modes 0/1 (S84, roll-verified 4/4): 3 live -> RNG1>=$80
    step then RNG1>=$AA step (~50/33/17 front-weighted); 2 live -> one
    $AA roll (66/34); 1 -> it. `cands` = live slots in front order."""
    if len(cands) == 1:
        return cands[0], state
    if len(cands) == 2:
        state = rng_step(state)
        return (cands[1] if rng1(state) >= 0xAA else cands[0]), state
    state = rng_step(state)
    if rng1(state) < 0x80:
        return cands[0], state
    state = rng_step(state)
    return (cands[2] if rng1(state) >= 0xAA else cands[1]), state


# $41E9 row skills whose bank $52 entry-3 damage estimate is CalcSkillDefense
# ($52:$538F table $53E9 index -> $60D7): Attack and its plain variants.
PARTY_PICK_CALCDEF = frozenset([0x37, 0x38, 0x3A, 0x3B, 0x3D, 0x40])
# every skill whose bank $58 row is $41E9 (BtlSkillTargetDispatch_401d)
ATTACK_ROW_PICK = frozenset([0x37, 0x38, 0x3A, 0x3B, 0x3D, 0x40, 0x50, 0x55, 0xDD])


def _pick_min(vals, state):
    """LoadBtlFX_433e: argmin over the three $DB58 words (16-bit), slot order;
    a tie with the running best takes one RNG step (LoadBtlFX_5c3e) and the
    challenger wins iff RNG1 bit1 == 0. Returns (index, state)."""
    best, bi = vals[0], 0
    for e in (1, 2):
        v = vals[e]
        if v == best:
            state = rng_step(state)
            if not (rng1(state) & 0x02):
                best, bi = v, e
        elif v < best:
            best, bi = v, e
    return bi, state


def party_attack_pick(b, a, sk, state):
    """[S130 P3.15b] The PARTY side of the plain-attack target service $41E9
    ($58:$41E9 -> Jump_058_4206; byte-read S130, measured by
    simulator/validate_command.py on disobedient Attacks): used at commit
    for a $FF target byte and at the act-time re-resolve.
      $DD0B == 0 -> LoadBtlFX_642c (uniform_side_pick on the opposing side).
      else, over the 3 opposing slots c (values in $DB58+2(c&3), $FFFF =
      excluded), argmin with RNG tie-breaks (_pick_min):
      * no live slot outside +6&$0C (airborne) -> HP + DEF (dead $FFFF)
      * else no "clean" slot (SetBtlFX_43ea: +6 bit2 clear, the shifted
        bytes $DB08+8c bit5 clear and $DB09+8c & 7 == 0 — no defence level)
        -> $FFFF for +6 bit2, else HP + DEF (DEF halved if $DB08+8c bit2)
      * else ($DD0B == 1: every live clean slot; $DD0B == 2: every clean
        slot that is not incapacitated (GetMonsterSlotInfo), none -> the
        previous rule) -> max(HP - est, 0), est = the bank $52 entry-3
        damage ESTIMATE = CalcSkillDefense(attacker ATK, DEF of
        wBattleTargetIdx = the SIDE BASE slot for every c — a vanilla quirk:
        all three estimates use the first slot's DEF), one roll each in
        slot order; metal targets ($DB8B bit0) x50 (16-bit wrap).
    Skills whose estimate is not CalcSkillDefense fall back to the
    front-weighted stand-in. Returns (slot|None, state)."""
    base = (a & 4) ^ 4
    if b.dd0b[a] == 0:
        return uniform_side_pick(b, base, state)
    if sk not in PARTY_PICK_CALCDEF:
        live = b.live_side(base)
        return (pick_front_weighted(live, state) if live else (None, state))
    slots = [base, base + 1, base + 2]
    live = [c for c in slots if b.valid(c)]
    if not live:
        return None, state

    def clean(c):
        if b.stb(c, 6) & 0x04:
            return False
        return not (b.st[(c + 1) * 8] & 0x20) and not (b.st[(c + 1) * 8 + 1] & 0x07)

    def hp_def(c, halve):
        if not b.valid(c):
            return 0xFFFF
        d = b.dfn[c]
        if halve and b.st[(c + 1) * 8] & 0x04:
            d >>= 1
        return (b.hp[c] + d) & 0xFFFF

    if not any(not (b.stb(c, 6) & 0x0C) for c in live):
        vals = [hp_def(c, False) for c in slots]
    else:
        ok = [c for c in live if clean(c)]
        if b.dd0b[a] == 2:
            ok = [c for c in slots if b.valid(c) and clean(c) and not (
                (b.stb(c, 2) & 0xD0) or (b.stb(c, 5) & 0x3F) or (b.stb(c, 7) & 0xC0))]
        if not ok:
            vals = [0xFFFF if (b.stb(c, 6) & 0x04) else hp_def(c, True) for c in slots]
        else:
            vals = []
            for c in slots:
                if c in ok:
                    est, state = D.calc_skill_defense(b.atk[a], b.dfn[base], state,
                                                      target_idx=base, arena=b.link,
                                                      attacker_idx=a)
                    v = max(b.hp[c] - est, 0)
                else:
                    v = 0xFFFF
                if b.db8b[c] & 0x01:
                    v = (v * 50) & 0xFFFF
                vals.append(v)
    i, state = _pick_min(vals, state)
    return slots[i], state


def attack_pick(b, a, sk, state):
    """The act-time / commit-time pick for an Attack-row skill with no
    concrete target: party actors (non-link) -> party_attack_pick; others
    the front-weighted enemy path ($441B modes 0/1, the validated stand-in)."""
    if a < 4 and not b.link:
        return party_attack_pick(b, a, sk, state)
    opp = b.live_side((a & 4) ^ 4)
    if not opp:
        return None, state
    return pick_front_weighted(opp, state)


def confused_turn(b, a, state, records, log, idle):
    """One confused turn (act state $11 -> $10 -> act): pick the meta-action,
    resolve its target (uniform pickers step the RNG), then act it through
    the normal MISS machine. bit4 is NOT cleared here — only the on-hit
    snap-out clears it. Byte-read + measured S88 (23/23 replays)."""
    if idle is None:
        idle = lambda s, _k: s
    mid, state = confusion_pick(b, a, state)
    b.queue[a * 2] = mid
    log.append((a, 'confused-act', mid))
    # act-time target resolution (bank $58 e8 -> per-id dispatch):
    if mid == CONF_HITALLY:
        t, state = uniform_side_pick(b, a & 4, state)          # $6479 own side
    elif mid in (CONF_HITENEMY, CONF_TRIP):
        t, state = uniform_side_pick(b, (a & 4) ^ 4, state)    # $642C opposing
    else:
        t = a                                                  # $6367 self-write
    b.queue[a * 2 + 1] = t if t is not None else 0xFF
    if mid == CONF_RUN:
        b.dd1b[a] = 0xFF; b.dd13[a] = 0xFF
        log.append((a, 'flee', None))
        return state
    if mid in (CONF_SCARED, CONF_DANCE):
        log.append((a, 'conf-msg', mid))
        return state
    if mid == CONF_TRIP:
        b.set_stb(a, 5, b.stb(a, 5) | 0x04)   # one-shot -> forced $16 next turn
        log.append((a, 'trip', None))
        return state
    if mid in (CONF_PARA, CONF_CANTMOVE):
        b.set_stb(a, 2, b.stb(a, 2) | 0x40)   # self-paralyze
        log.append((a, 'self-para', None))
        return state
    # $99/$9A/$9B: physical act through the normal MISS machine
    if t is None or not b.valid(t):
        return state
    f = (records.get(mid) or {}).get('battle_record', {}).get('fields', {})
    state = idle(state, 'pre_target')
    state = idle(state, 'pre_miss')
    state = rng_step(state)
    g = miss_gate(b, a, t, f.get('flags7', 0), f.get('flags8', 0), state)
    if g != 'pass':
        log.append((a, g, t))
        return state
    crit = None
    if CRIT_STAGE is not None:                # S130 F4: act state $A ($9A rolls, $99 TwinHits)
        crit, state = CRIT_STAGE(b, a, f, state)
    if crit is not True and mid in (CONF_HITALLY, CONF_HITENEMY):   # S130 F4: a crit skips the handler
        state = rng_step(state)               # $52:$5559 inside the handler
        thr = 0x40 if mid == CONF_HITALLY else 0xC0
        if rng1(state) < thr:
            log.append((a, 'conf-whiff', mid))
            return state
    if crit is True:                          # S130 F4
        dmg = 0; log.append((a, 'crit', t))
    else:
        dmg, state = D.calc_skill_defense(b.atk[a], b.dfn[t], state,
                                          target_idx=t, arena=b.link, attacker_idx=a)
    dmg, state = post_calc(b, a, t, mid, f, 'calcdef', dmg, state)   # S130 F4: the $53 post-calc stage
    ko = apply_damage(b, t, dmg)
    log.append((a, 'hit', (t, dmg, ko)))
    if not ko:
        if (f.get('flags9', 0) & 0x08) and (b.stb(t, 2) & 0x90):
            state = idle(state, 'pre_snap')   # S130 P3.15b: the hit animation first
        rolled, snapped, state = snap_out(b, t, f.get('flags9', 0), state)
        if rolled:
            log.append((a, 'snap', (t, snapped)))
    return state


def victims_of(ctx):
    """The victim list of an action: the Quake sweep, a side sweep for
    target_mode 18 (from the queued target forward), else the one target."""
    b, a, sk, f, core, t = ctx.b, ctx.a, ctx.sk, ctx.f, ctx.core, ctx.t
    qr = getattr(b, 'quake_range', QUAKE_RANGE)
    if sk in qr:
        return quake_victims(b, a, t)
    if f.get('target_mode') == 18 and core != 'none':
        return [(v, 1) for v in side_victims(b, t)]
    return [(t, 1)]


def post_calc(b, a, v, sk, f, core, dmg, state):
    """The bank $53 post-calc stage ($53:$5880-$5A6F) in the engine's order:
    the registered families' modifiers (POST_CALC, sorted by order)."""
    for _o, fn in POST_CALC:
        dmg, state = fn(b, a, v, sk, f, core, dmg, state)
    return dmg, state


def core_damage(ctx, v, div, state):
    """The pre-S130 cores for one victim -> ('dmg', dmg, state) | ('done',
    None, state) when the core resolved the victim itself (heal, status,
    fly-dodge) | ('none', None, state) when nothing models it."""
    b, a, sk, f, core = ctx.b, ctx.a, ctx.sk, ctx.f, ctx.core
    if core == 'calcdef':
        dmg, state = D.calc_skill_defense(b.atk[a], b.dfn[v], state, target_idx=v,
                                          arena=b.link, attacker_idx=a)
        m = PHYSICAL_IDS.get(sk, 1)
        dmg = dmg * mourn_multiplier(b, a) if m == 'mourn' else int(dmg * m)
        return 'dmg', dmg, state
    if core == 'record':
        pmin = f['power_enemy_min'] if a & 4 else f['power_party_min']
        prng = f['power_enemy_range'] if a & 4 else f['power_party_range']
        dmg, state = D.record_roll(pmin, prng, state)
        lad = getattr(b, 'elem_override', {}).get(ctx.real_sk, D.SPELL_LADDER.get(sk))
        if lad is not None and lad[0] is not None:
            rt, kind = lad
            lev = D.res_level(bytes(b.res[v * 7:v * 7 + 7]), rt)
            dmg = D.apply_ladder(dmg, D.LADDER_BREATH if kind == 'BREATH' else D.LADDER_A,
                                 b.stb(v, 5), lev)
        return 'dmg', dmg, state
    if core == 'heal':
        dmg, state = D.record_roll(f['power_party_min'], f['power_party_range'], state)
        apply_heal(b, v, dmg)
        ctx.log.append((a, 'heal', (v, dmg)))
        return 'done', None, state
    if core == 'quake':
        if b.flying(v):
            ctx.log.append((a, 'fly-dodge', v))
            return 'done', None, state
        lo, hi = getattr(b, 'quake_range', QUAKE_RANGE)[sk]
        return 'dmg', (lo + rng1(state) % (hi - lo + 1)) // div, state  # stand-in for the bank $72 roll
    if core == 'status' and sk in STATUS_SPELLS:
        o, state = status_spell_roll(b, a, v, sk, state)
        if o == 'hit':
            apply_status(b, v, sk)
        ctx.log.append((a, 'status', (v, o)))
        return 'done', None, state
    return 'none', None, state


def default_victims(ctx, damage_fn=None, victims=None, miss=True):
    """The engine's per-victim path ($53 act states: target fetch, the MISS
    machine, the core, post-calc, apply, rider, snap-out). damage_fn(ctx, v,
    div, state) -> (kind, dmg, state) like core_damage. Returns the state."""
    b, a, sk, f, log, idle = ctx.b, ctx.a, ctx.sk, ctx.f, ctx.log, ctx.idle
    state = ctx.state
    damage_fn = damage_fn or core_damage
    stop = False
    for vi, (v, div) in enumerate(victims if victims is not None else victims_of(ctx)):
        if stop:                          # S130 F6: SuckAll ended the sweep
            break
        for hook in VICTIM_HOOKS:
            v = hook(b, a, v, sk, f)
        if v is None or not b.valid(v):
            continue
        if (b.stb(v, 6) & 0x0C) and (f.get('flags9', 0) & 0x20):
            # S130 F4: act state 7 ($53:$5411): an AIRBORNE target (HighJump
            # +6&$0C) vs a flags9-bit5 skill -> "doesn't reach" ($C1), no MISS step
            log.append((a, 'airborne', v)); continue
        verdict = None
        for hook in INTERCEPT_HOOKS:      # S130 F6: act state 7 interception
            v, state, verdict = hook(ctx, vi, v, state)
            if verdict:
                break
        if verdict == 'skip':
            continue
        stop = verdict == 'last'
        if target_unreachable(b, v, f.get('flags8', 0), sk):
            # S130 F1: the iron pre-gate is per VICTIM (act state 9 runs per
            # target): a side sweep skips an ironized victim — no MISS step —
            # and goes on to the next (measured: a $5E sweep over [4 iron,5,6]).
            log.append((a, 'unreachable', v)); continue
        if vi:
            state = idle(state, 'pre_target')
        state = idle(state, 'pre_miss')
        if miss:
            if (f.get('flags7', 0) & 0x80) and (b.stb(v, 6) & 0x04):   # S130 F4: gate 1
                log.append((a, 'block', v)); continue                  # precedes the step
            state = rng_step(state)
            g = miss_gate(b, a, v, f.get('flags7', 0), f.get('flags8', 0), state)
            if g != 'pass':
                log.append((a, g, v))
                for hook in POST_VICTIM_HOOKS:   # S130 F6: the fail route ($53:$583A) still
                    state = hook(ctx, v, g, None, False, state)   # runs the Imitate check
                continue
        # MISS machine -> damage/status core is SAME-FRAME (measured
        # S86: no idle steps between them) — correlated rolls kept.
        crit = None
        if CRIT_STAGE is not None:            # S130 F4: act state $A ($53:$586A)
            crit, state = CRIT_STAGE(b, a, f, state)
        if crit is True:                      # S130 F4: the $52 handler is skipped;
            kind, dmg = 'dmg', 0              # post-calc builds the crit from ATK
            log.append((a, 'crit', v))
        else:
            kind, dmg, state = damage_fn(ctx, v, div, state)
        if kind == 'none':
            log.append((a, 'no-effect', ctx.real_sk)); continue
        if kind == 'done':
            for hook in POST_VICTIM_HOOKS:    # S130 F6
                state = hook(ctx, v, kind, None, False, state)
            continue
        dmg, state = post_calc(b, a, v, sk, f, ctx.core, dmg, state)
        ko = apply_damage(b, v, dmg)
        log.append((a, 'hit', (v, dmg, ko)))
        if not ko:
            if sk in PHYS_STATUS_RIDER:
                rh, state = rider_roll(b, v, sk, state)
                if rh is not None:
                    log.append((a, 'rider', (v, sk, rh)))
            for hook in POST_HIT_HOOKS:       # S130 F6: BladeD counter
                state = hook(ctx, v, dmg, state)
            if (f.get('flags9', 0) & 0x08) and (b.stb(v, 2) & 0x90):
                state = idle(state, 'pre_snap')   # S130 P3.15b: the hit animation
            rolled, snapped, state = snap_out(b, v, f.get('flags9', 0), state)
            if rolled:
                log.append((a, 'snap', (v, snapped)))
        for hook in POST_VICTIM_HOOKS:        # S130 F6
            state = hook(ctx, v, 'dmg', dmg, ko, state)
    for hook in POST_SWEEP_HOOKS:             # S130 F6
        state = hook(ctx, state)
    ctx.state = state
    return state


# the $DB42 bit6 x1.5 (S89, validated) is the post-calc stage's step at
# $53:$59CD — after crit / TwinHits / ChargeUP / SuckAir, before the defence
# levels ($53:$59EC)
POST_CALC.append((60, lambda b, a, v, sk, f, core, dmg, st: (db42_boost(b, a, dmg), st)))


def actor_walk(b, order):
    """[S130 F4 + F9] The round's actor walk ($DB79 by cursor), re-running an
    actor at the same cursor when
      F4: a POST_ACTION hook set b.ext['f4_again'] = a (the Focus follow-up:
          d9ed := $12 re-runs the per-actor setup without advancing $DB82);
      F9: a handler set b.ext['f9_rerun'] = a (TransformActionRewrite_7ab5 sets
          $D9ED := 0: the whole per-actor pipeline again with the rewritten
          queue; $DD13 is still 2 at that point)."""
    for cursor, a in enumerate(order):
        yield cursor, a
        while True:
            if b.ext.get('f9_rerun') == a:
                del b.ext['f9_rerun']
                b.dd13[a] = 2
                yield cursor, a
            elif b.ext.pop('f4_again', None) == a:
                yield cursor, a
            else:
                break


_actor_seq = actor_walk          # S130 merge: F4's name


def simulate_round(b, state, records, dup_flags, idle=None):
    """b: Board with the action queue committed (b.queue); state: RNG16.
    `idle(state, cls) -> state` = RNG idle policy (None = identity).
    Returns (log, state). Mutates b (HP/status/$DD1B/$DD13)."""
    if idle is None:
        idle = lambda s, cls: s
    log = []
    state = idle(state, 'round_gap')
    order, state = round_order(b, state)
    first_actor = True
    prev_acted = False
    for cursor, a in actor_walk(b, order):     # S130 F4 Focus follow-up / F9 form-change re-run
        if side_wiped(b, 0) or side_wiped(b, 4):
            break
        if b.dd13[a] != 2 or not b.valid(a):
            continue
        if first_actor:
            state = idle(state, 'post_order'); first_actor = False
        else:
            state = idle(state, 'post_action' if prev_acted else 'actor_skip')
        prev_acted = False
        handled = False
        for hook in ACTOR_HOOKS:
            handled, state = hook(b, a, state, log)
            if handled:
                break
        if handled:
            b.dd13[a] = 3; prev_acted = True
            continue
        forced = status_forced_action(b, a, state)
        if forced is not None:
            log.append((a, 'forced', forced)); continue
        state = rng_step(state)
        cursed_on = False
        if curse_fires(b, a, state):
            eff = curse_effect(b, a, state)
            log.append((a, 'curse', eff))
            if eff == 'skip':
                continue
            if eff == 'confuse':
                # d9ed=$11 IMMEDIATELY: the curse-set confusion acts this turn
                state = idle(state, 'pre_conf')   # S130 P3.15b (frames before conf_pick)
                state = confused_turn(b, a, state, records, log, idle)
                b.dd13[a] = 3; prev_acted = True
                continue
            # S130 F1: 'hp'/'mp' set $D9EE := 5 (CurseSelfHit_4c50) ->
            # SetupSub_4a55 -> sub-state 1: the rest of sub-state 0 — the
            # confusion branch and its dup conversion — is SKIPPED: a
            # confused+cursed actor whose curse fires hp/mp acts its QUEUED
            # skill (measured: g1_keep r5, slot 5 PanicAll after curse 'mp')
            cursed_on = True
        if not cursed_on and b.stb(a, 2) & 0x10:
            b.db42[a] = 0                 # S130 F4: $53:$4612 confusion gate clears $DB42+a
            state = idle(state, 'pre_conf')   # S130 P3.15b: the "confused" message
            state = confused_turn(b, a, state, records, log, idle)
            b.dd13[a] = 3; prev_acted = True
            continue
        sk = b.q_skill(a)
        flag = dup_flags[b.eid[a - 4]] if 4 <= a < 7 and b.eid[a - 4] < len(dup_flags) else 0
        if not cursed_on and dup_conversion(b, a, order, cursor, flag):
            sk = ATTACK; b.queue[a*2] = sk; b.queue[a*2+1] = 0xFF
        rec = records.get(sk)
        f = rec['battle_record']['fields'] if rec else {}
        _veto = act_mp_veto(b, a, sk, f.get('mp_cost_byte', 0), f.get('flags7', 0))
        if _veto not in (None, 'mp', 0x1F):   # S130 F5: these veto paths still pay
            act_mp_spend(b, a, sk, f.get('mp_cost_byte', 0), f.get('flags7', 0))
        if _veto == 0x1F and b.dd0b[a] != 2:   # S130 F10: a sealed spell PAYS (SaveBtlC_4b4f, floor 0;
            b.mp[a] = max(0, b.mp[a] - f.get('mp_cost_byte', 0))   # $DD0B==2 re-decides first, LoadBtlC_490a)
        if _veto is not None:
            log.append((a, 'veto', sk)); b.dd13[a] = 3; continue
        act_mp_spend(b, a, sk, f.get('mp_cost_byte', 0), f.get('flags7', 0))   # S130 F5
        # S130: a project's NEW custom skill (234-254) runs a stock skill's
        # handler (bank $72 CustomBaseTable) with its OWN record — the id-keyed
        # rules below use that base (b.core_alias, set by editor2/core/
        # balance.py; empty for the original game, so validate_* unchanged)
        real_sk = sk
        sk = getattr(b, "core_alias", {}).get(sk, sk)
        core = damage_core(sk, rec)
        qt = b.q_target(a)
        state = idle(state, 'pre_target')
        if sk in TARGET_RESOLVERS:        # S130 F5: per-skill act-time target
            t, state = TARGET_RESOLVERS[sk](b, a, sk, qt, f, state)
        elif core == 'heal':
            t = heal_target(b, a)
        elif qt != 0xFF and b.valid(qt):
            if not reresolves(b, a, sk):
                t = qt
            elif sk in RERESOLVE_PICKERS:   # S130 F8: the skill's own $58 resolver
                t, state = RERESOLVE_PICKERS[sk](b, a, state)
            elif a < 4 and not b.link and sk in PARTY_PICK_CALCDEF:   # S130 P3.15b
                t, state = party_attack_pick(b, a, sk, state)
            else:
                t, state = pick_front_weighted(b.live_side(qt & 4), state)
        elif qt == 0xFF and sk in RERESOLVE_PICKERS:   # S130 F8
            t, state = RERESOLVE_PICKERS[sk](b, a, state)
        elif qt == 0xFF:
            opp = b.live_side((a & 4) ^ 4)
            if a < 4 and not b.link and sk in PARTY_PICK_CALCDEF:   # S130 P3.15b
                t, state = party_attack_pick(b, a, sk, state)
            elif opp:
                t, state = pick_front_weighted(opp, state)
            else:
                t = None
        elif (f.get('target_mode', 0) & 1) and sk not in (0x51, 0x52, 0x53) and keeps_dead_target(b, a):
            # S130 F1 ($53:$47B2, byte-read + measured beat_e_L2): a SINGLE-
            # target skill (target-mode bit0) whose queued target died, cast
            # by a $DD0B==0 actor, is NOT redirected (LoadBtlC_49dc `ret z`)
            # — the action fizzles on the dead slot (no MISS step).
            # S130 P3.15b: also an obeyed ORDER (LoadBtlC_4e01, measured).
            t = None
        elif (f.get('target_mode', 0) & 1) and sk in ATTACK_ROW_PICK:
            # S130 P3.15b ($53:$47D1 -> bank $58 entry 8 -> row $41E9, measured):
            # a dead single target of an Attack-row skill re-picks like a $FF
            # byte — the party estimate pick / the enemy front-weighted pick
            t, state = attack_pick(b, a, sk, state)
        else:
            t = dead_redirect(b, qt)   # group: first-valid scan; $DD0B!=0 single: bank $58 re-pick (stand-in)
        if t is None:
            b.dd13[a] = 3; continue
        gt = guard_redirect(b, t, f.get('flags8', 0))
        if gt != t:                       # Cover/Guardian interception:
            log.append((a, 'guarded', t, gt))   # resolve on the
            b.queue[2 * a + 1] = gt       # protector; the engine also
            t = gt                        # rewrites the queue target
        if (f.get('target_mode') != 18 and sk not in OWN_TARGET_GATES   # S130 F1: sweeps gate per victim;
                and target_unreachable(b, t, f.get('flags8', 0), sk)):   # S130 F8: multi-hit gates per hit
            log.append((a, 'unreachable', t)); b.dd13[a] = 3; continue
        if (sk not in BOSS_GATE_IN_HANDLER and sk not in SELF_GATED   # S130 F1 / F23: own gates
                and D.boss_gate_blocks(sk, t >= 4, b.db73, arena=b.link)):
            log.append((a, 'boss-gated', sk))
            if sk == 0x14:
                b.hp[a] = 1
            b.dd13[a] = 3; continue
        ctx = ActionCtx(b=b, a=a, sk=sk, rec=rec, f=f, core=core, t=t, qt=qt,
                        state=state, records=records, log=log, idle=idle, real_sk=real_sk)
        h = ACTION_HANDLERS.get(sk)
        state = h(ctx) if h is not None else default_victims(ctx)
        b.dd13[a] = 3
        prev_acted = True
        for hook in POST_ACTION_HOOKS:    # S130 F4: $52:$70A4 end-of-action
            state = hook(b, a, sk, f, state, log)
    phase9_decay(b)
    for hook in PHASE9_HOOKS:
        state = hook(b, state, log)
    state = idle(state, 'p9_entry')
    for s in range(8):
        if side_wiped(b, 0) or side_wiped(b, 4):
            break
        if b.valid(s):
            # NO idle between slot rolls (measured k == 0, S86): consecutive
            # un-damaged slots read an identical RNG state.
            kind, dmg = dot_damage(b, s, state)
            if kind in ('poison', 'heavy'):
                ko = apply_damage(b, s, dmg)
                log.append((s, kind, (dmg, ko)))
                state = idle(state, 'post_dot_apply')
    for s in range(8):
        if b.dd13[s] == 3:
            b.dd13[s] = 2
    return log, state


# S130: the skill families register their handlers (simulator/skillfx/)
from . import skillfx  # noqa: E402,F401
