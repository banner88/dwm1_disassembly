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
    mutates the sleep byte."""
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
    if b5:
        for bit, code in ONESHOT_ACTIONS:
            if b5 & (1 << bit):
                # one-shot consumed at the victim's turn (S88, measured:
                # Trip's +5 bit2 $04 -> $00 across the forced-$16 turn).
                # Clears the CONSUMED bit; multi-bit sample still open.
                b.set_stb(a, 5, b5 & ~(1 << bit))
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
        if b.valid(prot) and b.hp[prot] > 0:
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
    if mp_cost and b.mp[a] < mp_cost:
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
            return 'pass'
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
    v = [(s, 1) for s in range(base, base + 3) if b.valid(s)]
    own = caster & 4
    v += [(s, 3) for s in range(own, own + 3) if s != caster and b.valid(s)]
    return v


def side_victims(b, first_target, start=None):
    """Side sweep victim list. [S89] The sweep begins at the QUEUED
    target and walks FORWARD to the end of that side — not from the
    side base (measured: a $0A queued on slot 5 swept [5,6], never
    touching 4). When the queued target IS the side base the two
    readings coincide, which is why every pre-S89 corpus agreed."""
    base = first_target & 4
    s0 = base if start is None else max(base, min(start, base + 2))
    return [s for s in range(s0, base + 3) if b.valid(s)]


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
    the damage model needs."""
    if 0 <= attacker < 8 and (b.db42[attacker] & 0x40):
        return dmg + (dmg >> 1)
    return dmg


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
        return True
    b.hp[t] = hp
    return False


def side_wiped(b, base):
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
    if mid in (CONF_HITALLY, CONF_HITENEMY):
        state = rng_step(state)               # $52:$5559 inside the handler
        thr = 0x40 if mid == CONF_HITALLY else 0xC0
        if rng1(state) < thr:
            log.append((a, 'conf-whiff', mid))
            return state
    dmg, state = D.calc_skill_defense(b.atk[a], b.dfn[t], state,
                                      target_idx=t, arena=b.link, attacker_idx=a)
    ko = apply_damage(b, t, dmg)
    log.append((a, 'hit', (t, dmg, ko)))
    if not ko:
        rolled, snapped, state = snap_out(b, t, f.get('flags9', 0), state)
        if rolled:
            log.append((a, 'snap', (t, snapped)))
    return state


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
    for cursor, a in enumerate(order):
        if side_wiped(b, 0) or side_wiped(b, 4):
            break
        if b.dd13[a] != 2 or not b.valid(a):
            continue
        if first_actor:
            state = idle(state, 'post_order'); first_actor = False
        else:
            state = idle(state, 'post_action' if prev_acted else 'actor_skip')
        prev_acted = False
        forced = status_forced_action(b, a, state)
        if forced is not None:
            log.append((a, 'forced', forced)); continue
        state = rng_step(state)
        if curse_fires(b, a, state):
            eff = curse_effect(b, a, state)
            log.append((a, 'curse', eff))
            if eff == 'skip':
                continue
            if eff == 'confuse':
                # d9ed=$11 IMMEDIATELY: the curse-set confusion acts this turn
                state = confused_turn(b, a, state, records, log, idle)
                b.dd13[a] = 3; prev_acted = True
                continue
        if b.stb(a, 2) & 0x10:
            state = confused_turn(b, a, state, records, log, idle)
            b.dd13[a] = 3; prev_acted = True
            continue
        sk = b.q_skill(a)
        flag = dup_flags[b.eid[a - 4]] if 4 <= a < 7 and b.eid[a - 4] < len(dup_flags) else 0
        if dup_conversion(b, a, order, cursor, flag):
            sk = ATTACK; b.queue[a*2] = sk; b.queue[a*2+1] = 0xFF
        rec = records.get(sk)
        f = rec['battle_record']['fields'] if rec else {}
        if act_mp_veto(b, a, sk, f.get('mp_cost_byte', 0), f.get('flags7', 0)) is not None:
            log.append((a, 'veto', sk)); b.dd13[a] = 3; continue
        core = damage_core(sk, rec)
        qt = b.q_target(a)
        state = idle(state, 'pre_target')
        if core == 'heal':
            t = heal_target(b, a)
        elif qt != 0xFF and b.valid(qt):
            if not reresolves(b, a, sk):
                t = qt
            else:
                t, state = pick_front_weighted(b.live_side(qt & 4), state)
        elif qt == 0xFF:
            opp = b.live_side((a & 4) ^ 4)
            if opp:
                t, state = pick_front_weighted(opp, state)
            else:
                t = None
        else:
            t = dead_redirect(b, qt)
        if t is None:
            b.dd13[a] = 3; continue
        gt = guard_redirect(b, t, f.get('flags8', 0))
        if gt != t:                       # Cover/Guardian interception:
            log.append((a, 'guarded', t, gt))   # resolve on the
            b.queue[2 * a + 1] = gt       # protector; the engine also
            t = gt                        # rewrites the queue target
        if target_unreachable(b, t, f.get('flags8', 0), sk):
            log.append((a, 'unreachable', t)); b.dd13[a] = 3; continue
        if D.boss_gate_blocks(sk, t >= 4, b.db73, arena=b.link):
            log.append((a, 'boss-gated', sk))
            if sk == 0x14:
                b.hp[a] = 1
            b.dd13[a] = 3; continue
        if sk in QUAKE_RANGE:
            victims = quake_victims(b, a, t)
        elif f.get('target_mode') == 18 and core != 'none':
            victims = [(v, 1) for v in side_victims(b, t)]
        else:
            victims = [(t, 1)]
        for vi, (v, div) in enumerate(victims):
            if vi:
                state = idle(state, 'pre_target')
            state = idle(state, 'pre_miss')
            state = rng_step(state)
            g = miss_gate(b, a, v, f.get('flags7', 0), f.get('flags8', 0), state)
            if g != 'pass':
                log.append((a, g, v)); continue
            # MISS machine -> damage/status core is SAME-FRAME (measured
            # S86: no idle steps between them) — correlated rolls kept.
            if core == 'calcdef':
                dmg, state = D.calc_skill_defense(b.atk[a], b.dfn[v], state, target_idx=v, arena=b.link, attacker_idx=a)
                m = PHYSICAL_IDS.get(sk, 1)
                dmg = dmg * mourn_multiplier(b, a) if m == 'mourn' else int(dmg * m)
            elif core == 'record':
                pmin = f['power_enemy_min'] if a & 4 else f['power_party_min']
                prng = f['power_enemy_range'] if a & 4 else f['power_party_range']
                dmg, state = D.record_roll(pmin, prng, state)
            elif core == 'heal':
                dmg, state = D.record_roll(f['power_party_min'], f['power_party_range'], state)
                apply_heal(b, v, dmg); log.append((a, 'heal', (v, dmg))); continue
            elif core == 'quake':
                if b.flying(v):
                    log.append((a, 'fly-dodge', v)); continue
                lo, hi = QUAKE_RANGE[sk]
                dmg = (lo + rng1(state) % (hi - lo + 1)) // div     # stand-in for the bank $72 roll
            elif core == 'status' and sk in STATUS_SPELLS:
                o, state = status_spell_roll(b, a, v, sk, state)
                if o == 'hit':
                    apply_status(b, v, sk)
                log.append((a, 'status', (v, o))); continue
            else:
                log.append((a, 'no-effect', sk)); continue
            ko = apply_damage(b, v, dmg)
            log.append((a, 'hit', (v, dmg, ko)))
            if not ko:
                if sk in PHYS_STATUS_RIDER:
                    rh, state = rider_roll(b, v, sk, state)
                    if rh is not None:
                        log.append((a, 'rider', (v, sk, rh)))
                rolled, snapped, state = snap_out(b, v, f.get('flags9', 0), state)
                if rolled:
                    log.append((a, 'snap', (v, snapped)))
        b.dd13[a] = 3
        prev_acted = True
    phase9_decay(b)
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
