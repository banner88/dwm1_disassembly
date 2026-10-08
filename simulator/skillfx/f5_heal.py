"""S130 F5 — healing, revive, cures and the MP economy (BATTLE_SKILL_SYSTEM
§15.11 F5). Every function names the engine routine it models; the corpus
is simulator/f5_events.json (simulator/measure_f5.py on the user's save,
u22.gbc) and the replay is simulator/validate_f5.py.

Skills (id: bank $52 handler; bank $58 target row; effect):
  $2B Heal / $2C HealMore / $2D HealAll   SkillHeal $44C4 + LoadBattle_607d;
        row $44F7 (HP-need scan by AI mode); one ally, record roll (side
        fields by StoreDamageResult) / FULL MaxHP for $2D.
  $2E HealUs / $2F HealUsAll / $94 Hustle / $A3 HealUsAll(Chance)
        the same handler per ally (target_mode 34 sweep from row $62CD =
        first live own slot); $2F/$A3 FULL MaxHP ($A3 rewrites $DB8A:=$2F).
  $93 Meditate   SkillMeditate $4D38: own HP += 500 capped (row $6367 self).
  $30 Vivify / $31 Revive / $AD ALLREVIVE   SkillVivify $44F8; row $469E
        (highest dead own slot, else self) / $635F (own base, ALLREVIVE:
        the group loop visits own slots base..3 with NO life check; a live
        visit re-targets to the first dead slot and the loop resumes there).
  $32 Farewell / $96 LifeDance   act state 4 -> the bank $53 entry-14
        chain $6A9B: revive + full-heal every other own slot, the caster
        pays all HP (RNG1 < $7F) or keeps HP/100, MP := 0 (row $635F own
        base; never re-resolved).  $95 LifeSong: turn 1 charges (+7 bit5),
        turn 2 (the command loop keeps the queue) rolls and runs its OWN
        tails $52:$7A69-$7A95: SkillVivify revives every dead own slot to
        full; no heal, no caster price.
  MP economy also covers the act-time MP SPEND (battle.act_mp_spend) and
        the LifeSong/HighJump veto waiver (battle.mp_veto_exempt).
  $33 Antidote (row $46C7) / $34 NumbOff / $35 DeChaos / $36 CurseOff
        (rows $62CD, tm 34): status-byte +2 clears; NumbOff/DeChaos also
        write $DD13[target] := 3 (the cured slot's turn is spent).
  $1A RobMagic / $76 RobDance (SkillRobMagic $4308), $75 OddDance ($4A7B):
        SetHLBattle_5d25 hit roll (res 9, ladder B) + BattleTarget_5d7a
        drain min(target MP, level/4+5); BattleCall_5d48 gives it to the
        caster capped at MaxMP (RobMagic/RobDance only). Target rows $52A9
        (lowest 4*res score) / $4CD1 (highest (3-res)<<12 word), decoded.
  $A8 MP0 ($4F7F): MP := 0 over the $52:$714C 8-slot walk (every live
        combatant, the caster too).  $AE RESTOREMP ($4FFC): MP := MaxMP unless
        MP's low byte == its high byte (byte-compare bug: MP 0 stays 0).
"""
from .. import battle as B
from .. import damage as D

rng_step, rng1 = B.rng_step, B.rng1

HEAL_HANDLER = {0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x94, 0xA3}      # SkillHeal
FULL_HEAL = {0x2D, 0x2F, 0x32, 0x96}                          # LoadBattle_607d full-MaxHP ids
VIVIFY = 0x30
REVIVE_IDS = {0x30, 0x31, 0xAD}                               # SkillVivify
CHAIN_IDS = {0x32, 0x95, 0x96}                                # act state 4 ($53 entry 14 / LifeSong tails)
CURES = {0x33: (0x03, 0xFC, False), 0x34: (0xCC, 0x33, True),
         0x35: (0x10, 0xEF, True), 0x36: (0x20, 0xDF, False)}  # test mask, keep mask, $DD13:=3
DRAIN_IDS = {0x1A, 0x75, 0x76}
MP0, RESTOREMP, MEDITATE = 0xA8, 0xAE, 0x93
LIFESONG, LIFEDANCE, FAREWELL = 0x95, 0x96, 0x32
MP_RES_TYPE = 9                                               # SetHLBattle_5d25: $DD2A bits 3:2


# --------------------------------------------------------------------------
# small engine predicates
# --------------------------------------------------------------------------
def slot_kind(b, s):
    """CheckMonsterSlot ($00:$2FA5): 'live' (NC), 'dead' ($DD1B nonzero,
    not $FF: C+NZ), 'invalid' (index >= 8 or $DD1B == $FF: C+Z)."""
    if not (0 <= s < 8) or b.dd1b[s] == 0xFF:
        return 'invalid'
    return 'live' if b.dd1b[s] == 0 else 'dead'


def side_fields(b, a, f):
    """StoreDamageResult $52:$66D6: the ENEMY power fields (+$0F) only for
    a non-link enemy attacker, else the party fields (+$0B)."""
    if not b.link and (a & 4):
        return f['power_enemy_min'], f['power_enemy_range']
    return f['power_party_min'], f['power_party_range']


def revive_slot(b, t):
    """SaveBattle_51dd $52:$51DD (and the chain's inline copy at
    $53:$6AF7): $DD1B[t] := 0 and the 8 bytes $DB02+8t..$DB09+8t := 0
    (+2..+7 and the shifted guard pair = slot t+1's +0/+1). $DD13 is NOT
    written: the revived slot (still $FF from its KO) is skipped this
    round and re-armed by the next command phase (measured)."""
    b.dd1b[t] = 0
    for i in range(t * 8 + 2, min(t * 8 + 10, 64)):
        b.st[i] = 0


# --------------------------------------------------------------------------
# bank $58 per-skill target rows (BtlSkillTargetDispatch_401d) — used at
# commit (pacing._commit_target via battle.COMMIT_TARGETS) and at act when
# the target is re-resolved. row(b, a, state) -> (slot, state)
# --------------------------------------------------------------------------
def row_mode0_uniform_own(b, a, state):
    """CallBtlFX_6556 for $DD0B == 0: LoadBtlFX_6479 = the uniform own-side
    pick $63EC/$63FD (one RNG step)."""
    t, state = B.uniform_side_pick(b, a & 4, state)
    return (t if t is not None else a), state


def heal_need_mode1(b, a):
    """$58:$4515 + LoadBtlFX_665a (AI modes 1, and 2's fallback): per own
    slot (q, r) = divmod(MaxHP, HP) (Div16x16To16); a full slot scores
    (0, 1), a non-live slot (0, 0); pick the lexicographic max (q first,
    then r), ties keep the LOWER slot."""
    base = a & 4
    sc = []
    for s in range(base, base + 3):
        if slot_kind(b, s) != 'live':
            sc.append((0, 0))
        elif b.hp[s] == b.maxhp[s]:
            sc.append((0, 1))
        elif b.hp[s] == 0:
            sc.append((0, 0))
        else:
            sc.append(divmod(b.maxhp[s], b.hp[s]))
    best = 0
    for j in (1, 2):
        if sc[best][0] < sc[j][0] or (sc[best][0] == sc[j][0] and sc[best][1] < sc[j][1]):
            best = j
    return base + best


def heal_need_mode2(b, a, state):
    """$58:$4591 (AI mode 2): threshold T = (sum of live own MaxHP) // n // n
    (Div24x8To16 twice; a METAL slot adds the garbage (count<<8|slot)*30 —
    BC holds the loop registers at the Mul16x8To24, byte-read), then each
    live, wounded own slot with HP < T is taken (T := its HP); HP == T rolls
    one RNG step (LoadBtlFX_5c3e) and takes it on RNG1 >= $80. No pick ->
    the mode-1 scan."""
    base = a & 4
    tot, n = 0, 0
    for i, s in enumerate(range(base, base + 3)):
        if slot_kind(b, s) != 'live':
            continue
        n += 1
        if b.db8b[s] & 1:
            tot += (((3 - i) << 8) | s) * 30
        else:
            tot += b.maxhp[s]
    thr = ((tot // n) // n) & 0xFFFF if n else 0
    pick = None
    for s in range(base, base + 3):
        if slot_kind(b, s) != 'live' or b.hp[s] == b.maxhp[s]:
            continue
        if b.hp[s] < thr:
            thr, pick = b.hp[s], s
        elif b.hp[s] == thr:
            state = rng_step(state)
            if rng1(state) >= 0x80:
                pick = s
    if pick is None:
        pick = heal_need_mode1(b, a)
    return pick, state


def row_heal(b, a, state):
    """$58:$44F7 — Heal / HealMore / HealAll."""
    if b.dd0b[a] == 0:
        return row_mode0_uniform_own(b, a, state)
    if b.dd0b[a] == 2:
        return heal_need_mode2(b, a, state)
    return heal_need_mode1(b, a), state


def row_first_live_own(b, a, state):
    """$58:$62CD: first live own slot from the side base (none -> base)."""
    base = a & 4
    for s in range(base, base + 3):
        if slot_kind(b, s) == 'live':
            return s, state
    return base, state


def row_own_base(b, a, state):
    """$58:$635F: the own side base, unconditionally."""
    return a & 4, state


def row_self(b, a, state):
    """$58:$6367 TargetSelfWrite."""
    return a, state


def row_vivify(b, a, state):
    """$58:$469E: scan own base+2 DOWN to base for the first dead slot
    (CheckMonsterSlot C+NZ); none -> the attacker itself."""
    base = a & 4
    for s in (base + 2, base + 1, base):
        if slot_kind(b, s) == 'dead':
            return s, state
    return a, state


def row_antidote(b, a, state):
    """$58:$46C7: mode 0 -> uniform own; else own base+2 down to base for
    +2 bit1 (heavy DoT); else base+2, base+1 for bit0 (light poison — the
    loop runs only 2 slots); else base. No life check."""
    if b.dd0b[a] == 0:
        return row_mode0_uniform_own(b, a, state)
    base = a & 4
    for s in (base + 2, base + 1, base):
        if b.stb(s, 2) & 0x02:
            return s, state
    for s in (base + 2, base + 1):
        if b.stb(s, 2) & 0x01:
            return s, state
    return base, state


def row_first_live_opp(b, a, state):
    """$58:$62BF: first live opposing slot (none -> opposing base)."""
    base = (a & 4) ^ 4
    for s in range(base, base + 3):
        if slot_kind(b, s) == 'live':
            return s, state
    return base, state


def _uniform_opp(b, a, state):
    """CallBtlFX_654d for $DD0B == 0: LoadBtlFX_642c, the uniform
    opposing pick (one RNG step)."""
    t, state = B.uniform_side_pick(b, (a & 4) ^ 4, state)
    return (t if t is not None else (a & 4) ^ 4), state


def row_robmagic(b, a, state):
    """$58:$52A9 (RobMagic). Mode 0 -> uniform opposing. Else a score per
    opposing slot into $DB50: $FF non-live or MP 0; $FE when +4 & $22
    (MagicBack/Bounce up); else bank $52 entry 6 ($6A8A, row 2 = the raw
    $DD2A+7t res byte) & $0C = 4 x the MP-resistance level. LoadBtlFX_5f0c
    keeps the LOWEST score scanning from the side base (the base is
    compared with ITSELF first): a tie rolls one RNG step and moves on
    RNG1 >= $80."""
    if b.dd0b[a] == 0:
        return _uniform_opp(b, a, state)
    base = (a & 4) ^ 4
    sc = []
    for s in range(base, base + 3):
        if slot_kind(b, s) != 'live' or b.mp[s] == 0:
            sc.append(0xFF)
        elif b.stb(s, 4) & 0x22:
            sc.append(0xFE)
        else:
            sc.append(D.res_level(bytes(b.res[s * 7:s * 7 + 7]), MP_RES_TYPE) << 2)
    cur, best = base, sc[0]
    for i, d in enumerate(sc):
        if best < d:
            continue
        if best == d:
            state = rng_step(state)
            if rng1(state) < 0x80:
                continue
        cur, best = base + i, d
    return cur, state


def row_odddance(b, a, state):
    """$58:$4CD1 (OddDance, RobDance). Mode 0 -> uniform opposing. Else a
    word per opposing slot: 0 for non-live / MP 0, else
    ((3 - MP-res level) << 12) | 1 (the res byte rotated, XOR $30);
    SetBtlFX_619a keeps the HIGHEST, slots 1 and 2 compared against the
    best so far, a tie rolling one RNG step (RNG1 >= $80 moves)."""
    if b.dd0b[a] == 0:
        return _uniform_opp(b, a, state)
    base = (a & 4) ^ 4
    w = []
    for s in range(base, base + 3):
        if slot_kind(b, s) != 'live' or b.mp[s] == 0:
            w.append(0)
        else:
            w.append(((3 - D.res_level(bytes(b.res[s * 7:s * 7 + 7]), MP_RES_TYPE)) << 12) | 1)
    bi, best = 0, w[0]
    for i in (1, 2):
        if best > w[i]:
            continue
        if best == w[i]:
            state = rng_step(state)
            if rng1(state) < 0x80:
                continue
        bi, best = i, w[i]
    return base + bi, state


ROWS = {0x2B: row_heal, 0x2C: row_heal, 0x2D: row_heal,
        0x2E: row_first_live_own, 0x2F: row_first_live_own, 0x94: row_first_live_own,
        0xA3: row_first_live_own, 0x34: row_first_live_own, 0x35: row_first_live_own,
        0x36: row_first_live_own, 0xAE: row_first_live_own,
        0x32: row_own_base, 0x95: row_own_base, 0x96: row_own_base, 0xAD: row_own_base,
        0x30: row_vivify, 0x31: row_vivify, 0x33: row_antidote, 0x93: row_self,
        0x1A: row_robmagic, 0x75: row_odddance, 0x76: row_odddance, 0xA8: row_first_live_opp}


def act_target(b, a, sk, qt, f, state):
    """Act-time target ($53:SetupSub_4692 -> $4733/$475E/$47B2, then the
    target fetch $520C): the four chain/ALLREVIVE ids keep the queue byte
    as is; a dead/invalid queued target -> (group mode: tm bit0 clear)
    DeadTargetRedirectScan_47e8; (single) `call LoadBtlC_49dc / or a /
    ret z` KEEPS it for $DD0B == 0 (measured: a mode-0 Heal landed on a
    dead slot and failed), and LoadBtlC_4e01 keeps it for tactic byte 3
    (Command; the wMenu_selection leg is not decoded); else the per-skill
    row. A live one is re-resolved through the row unless $DD0B==0 /
    confused / tactic byte 3 (battle.reresolves). $FF -> row."""
    row = ROWS[sk]
    if sk in B.NO_RERESOLVE:
        return qt, state
    if qt == 0xFF:
        return row(b, a, state)
    if slot_kind(b, qt) != 'live':
        if not (f.get('target_mode', 0) & 1):
            return B.dead_redirect(b, qt), state
        if b.dd0b[a] == 0 or b.dd03[a] == 3:
            return qt, state
        return row(b, a, state)
    if B.reresolves(b, a, sk):
        return row(b, a, state)
    return qt, state


# --------------------------------------------------------------------------
# per-victim effects (each returns (outcome, value, state))
# --------------------------------------------------------------------------
def skill_heal(b, a, t, sk, f, state):
    """SkillHeal $52:$44C4: a non-live target or HP == MaxHP -> msg $BB
    (no roll). LoadBattle_607d: ids $2D/$2F/$32/$96 heal MaxHP, the rest
    roll the record (RecordDamageRoll_679c: RNG1 as found, no step) with
    the side fields; HP := min(HP + amount, MaxHP). $DB56 = the amount."""
    if slot_kind(b, t) != 'live' or b.hp[t] == b.maxhp[t]:
        return 'fail', 0, state
    if sk in FULL_HEAL:
        amt = b.maxhp[t]
    else:
        pmin, prng = side_fields(b, a, f)
        amt, state = D.record_roll(pmin, prng, state)
    b.hp[t] = min(b.hp[t] + amt, b.maxhp[t])
    return 'heal', amt, state


def skill_meditate(b, a):
    """SkillMeditate $52:$4D38: own HP == MaxHP -> $BB; else HP := min(HP +
    500, MaxHP)."""
    if b.hp[a] == b.maxhp[a]:
        return 'fail', 0
    b.hp[a] = min(b.hp[a] + 500, b.maxhp[a])
    return 'heal', 500


def skill_vivify(b, a, t, sk, state):
    """SkillVivify $52:$44F8. Returns (outcome, slot, state):
    target invalid -> 'none' (SetSkillAnimFlag); target LIVE -> Vivify
    'fail' ($BB), Revive/ALLREVIVE re-target to the FIRST dead own slot
    from the base (also written to the queue target byte) or 'fail';
    target dead: Vivify rolls one BattleRNG step, RNG1 >= $80 -> 'fail_c0'
    (msg $C0). Success: HP := MaxHP (MaxHP/2 for $30 Vivify), then
    SaveBattle_51dd (revive_slot)."""
    k = slot_kind(b, t)
    if k == 'invalid':
        return 'none', t, state
    if k == 'live':
        if sk == VIVIFY:
            return 'fail', t, state
        base = a & 4
        t = next((s for s in range(base, base + 3) if slot_kind(b, s) == 'dead'), None)
        if t is None:
            return 'fail', None, state
        b.queue[a * 2 + 1] = t
    elif sk == VIVIFY:
        state = rng_step(state)
        if rng1(state) >= 0x80:
            return 'fail_c0', t, state
    b.hp[t] = b.maxhp[t] >> 1 if sk == VIVIFY else b.maxhp[t]
    revive_slot(b, t)
    return 'revive', t, state


def skill_cure(b, t, sk):
    """LoadBattle_519e reads target +2 (no life check). Antidote $458F
    (&3 -> &$FC), NumbOff $45A7 (&$CC -> &$33, $DD13[t] := 3), DeChaos
    $45D8 (&$10 -> &$EF, $DD13[t] := 3), CurseOff $45FE (&$20 -> &$DF);
    nothing to cure -> $BB."""
    test, keep, spend = CURES[sk]
    v = b.stb(t, 2)
    if not (v & test):
        return 'fail'
    b.set_stb(t, 2, v & keep)
    if spend:
        b.dd13[t] = 3
    return 'cure'


def mp_drain(b, a, t, sk, state):
    """RobMagic/RobDance $52:$4308, OddDance $4A7B. Target MP 0 -> $BB (no
    roll). SetHLBattle_5d25: level = res type 9 (MP); Compare_6adc: level
    3 -> ladder B 'never' (no step); $DB42[attacker] bit2 -> sure hit (no
    step); else CheckTargetGuardB = ladder B on target +5 (one step).
    Hit: BattleTarget_5d7a drains min(MP, (level >> 2) + 5) ($DB56);
    BattleCall_5d48 (RobMagic/RobDance) adds it to the caster, capped at
    MaxMP by SaveBattle_6a01. OddDance's drained MP is lost."""
    if b.mp[t] == 0:
        return 'fail', 0, state
    lev = D.res_level(bytes(b.res[t * 7:t * 7 + 7]), MP_RES_TYPE)
    if lev != 3 and (b.db42[a] & 0x04):
        hit = True
    else:
        hit, state = D.hit_roll(D.LADDER_HIT_B, b.stb(t, 5), lev, state)
    if not hit:
        return 'miss', 0, state
    amt = min(b.mp[t], ((b.level[a] >> 2) + 5) & 0xFF)
    b.mp[t] -= amt
    if sk != 0x75:
        b.mp[a] = min(b.mp[a] + amt, b.maxmp[a])
    return 'drain', amt, state


def skill_mp0(b, t):
    """SkillMP0 $52:$4F7F: live target with MP != 0 -> MP := 0."""
    if slot_kind(b, t) != 'live' or b.mp[t] == 0:
        return 'none'
    b.mp[t] = 0
    return 'mp0'


def skill_restoremp(b, t):
    """SkillRESTOREMP $52:$4FFC: `ld a,[hl+] / cp [hl]` compares MP's LOW
    byte with its HIGH byte (a bug — meant MP vs MaxMP): equal -> no
    effect (so MP 0, 257, 514 ... are never restored); else MP := MaxMP.
    No life check."""
    if (b.mp[t] & 0xFF) == (b.mp[t] >> 8):
        return 'none'
    b.mp[t] = b.maxmp[t]
    return 'restore'


# ---- LifeSong (own tails) / LifeDance / Farewell (the $53 entry-14 chain) --
def lifesong_cast(b, a, state):
    """SkillLifeSong $52:$4D92: own +7 bit4 clear -> +7 := (+7 & $CF) | $20
    and 'charge' (phase 9 moves bit5 -> bit4); bit4 set -> clear bits 5:4,
    one BattleRNG step, RNG1 < $80 -> 'fail' (msg $CB); no dead own slot
    ($DD1B == 1) -> 'fail'; else 'chain'."""
    v7 = b.stb(a, 7)
    if not (v7 & 0x10):
        b.set_stb(a, 7, (v7 & 0xCF) | 0x20)
        return 'charge', state
    b.set_stb(a, 7, v7 & 0xCF)
    state = rng_step(state)
    if rng1(state) < 0x80:
        return 'fail', state
    base = a & 4
    if not any(b.dd1b[s] == 1 for s in range(base, base + 3)):
        return 'fail', state
    return 'chain', state


def lifedance_cast(b, a, state):
    """SkillLifeDance $52:$4DE9: one BattleRNG step; RNG1 < $7F -> 'chain'
    else 'fail' ($BB). No dead-ally requirement."""
    state = rng_step(state)
    return ('chain' if rng1(state) < 0x7F else 'fail'), state


def chain_walk(b, a, start):
    """$53 entry 14 ($6A9B) sub-states 0-3, from wBattleTargetIdx = start up
    to the side's slot 2: the caster and $DD1B==$FF slots are skipped
    ($6AD4); a dead slot ($DD1B==1) is revived ($6ADD: HP := MaxHP,
    $DD1B := 0, +2..+9 zeroed); a live one is healed to MaxHP ($6B53 ->
    LoadBtlC_6bc1). Returns [(slot, 'revive'|'heal'|'skip')]."""
    out = []
    t = start
    while True:
        if t == a or not (0 <= t < 8) or b.dd1b[t] == 0xFF:
            out.append((t, 'skip'))
        elif b.dd1b[t] == 1:
            b.hp[t] = b.maxhp[t]
            revive_slot(b, t)
            out.append((t, 'revive'))
        else:
            b.hp[t] = b.maxhp[t]
            out.append((t, 'heal'))
        if (t & 3) == 2 or t >= 7:
            break
        t += 1
    return out


def lifesong_walk(b, a, start):
    """LifeSong's own state-4 tails ($52:$6F42 -> [$7A69, $7A80, $7A95]):
    from wBattleTargetIdx = start, a DEAD slot is revived by SkillVivify
    with $DB8A = $95 (the Revive path: HP := MaxHP + SaveBattle_51dd);
    live and invalid slots are passed; $7A95 steps the index, stopping at
    side slot 3 and skipping $DD1B==$FF slots. No caster cost (unlike the
    entry-14 chain). Returns the revived slots."""
    out = []
    t = start
    while True:
        if slot_kind(b, t) == 'dead':
            b.hp[t] = b.maxhp[t]
            revive_slot(b, t)
            out.append(t)
        while True:
            t += 1
            if (t & 3) == 3:
                return out
            if slot_kind(b, t) != 'invalid':
                break


def chain_caster(b, a, state):
    """Sub 4 ($53:$696B) + sub 5 ($6A04) + sub 6 ($6A79). Caster not live ->
    no HP change. Else one step (LoadBtlC_4e33): RNG1 < $7F -> the caster
    pays ALL its HP; else it keeps max(HP // 100, 1) (pays HP - that; a
    zero payment is impossible). HP 0 -> $DD1B := 1. Then MP := 0.
    Returns (outcome 'dies'|'keeps'|'none', state)."""
    out = 'none'
    if slot_kind(b, a) == 'live':
        state = rng_step(state)
        hp = b.hp[a]
        if rng1(state) < 0x7F:
            cost = hp
        else:
            keep = (hp // 100) or 1
            cost = hp - keep if hp - keep else hp
        b.hp[a] = hp - cost
        if b.hp[a] == 0:
            b.dd1b[a] = 1
            out = 'dies'
        else:
            out = 'keeps'
    b.mp[a] = 0
    return out, state


# --------------------------------------------------------------------------
# the driver's action handlers (battle.ACTION_HANDLERS)
# --------------------------------------------------------------------------
GROUP_ANY = {0x95, 0x96, 0xAD}         # GroupVictimLoopA_71b5: visit without a life check
WALK8 = {MP0}                           # $52:$714C 8-slot walk ($A7/$A8/$AF; F5 owns $A8)


def is_group(f):
    """$52:$7075: record target mode & 3 != 1 -> the group victim loop."""
    return (f.get('target_mode', 0) & 3) != 1


def next_victim(b, sk, f, cur, n):
    """The next victim after one resolved on wBattleTargetIdx = `cur`
    (n = $DD69, the target-fetch counter, 1 after the first victim).
    $52:$714C (MP0): $DD69 >= 8 -> done; == 4 -> jump to the OTHER side
    base ((cur & 4) ^ 4, no life check); else cur+1, a non-live slot only
    bumps $DD69. GroupVictimLoopA_71b5 (group target modes): stop when
    cur is slot 3/7; else cur+1, visited when live (or ANY slot for
    $95/$96/$AD). Single target: None. Returns (slot|None, n)."""
    if sk in WALK8:
        while True:
            if n >= 8:
                return None, n
            if n == 4:
                return (cur & 4) ^ 4, n + 1
            cur += 1
            if slot_kind(b, cur) == 'live':
                return cur, n + 1
            n += 1
    if not is_group(f):
        return None, n
    while True:
        if cur in (3, 7):
            return None, n
        cur += 1
        if sk in GROUP_ANY or slot_kind(b, cur) == 'live':
            return cur, n + 1


def sweep(ctx, effect):
    """The act loop over victims: target fetch + MISS machine per victim
    (one step each), then effect(v, state) -> (state, cur) where cur is
    wBattleTargetIdx after the handler (Revive re-targets it to the slot
    it revived, and the group loop continues from THERE)."""
    b, a, sk, f = ctx.b, ctx.a, ctx.sk, ctx.f
    state, v, n, vi = ctx.state, ctx.t, 1, 0
    while v is not None:
        g, state = _miss(ctx, v, state, vi)
        cur = v
        if g == 'pass':
            state, cur = effect(v, state)
        else:
            ctx.log.append((a, g, v))
        vi += 1
        v, n = next_victim(b, sk, f, cur, n)
    ctx.state = state
    return state


def _miss(ctx, v, state, vi):
    """The act-state MISS machine ($53:$5747) runs for every victim of
    every action (one step); spells pass it (no f7 bit1 / f8 bit7)."""
    if vi:
        state = ctx.idle(state, 'pre_target')
    state = ctx.idle(state, 'pre_miss')
    state = rng_step(state)
    g = B.miss_gate(ctx.b, ctx.a, v, ctx.f.get('flags7', 0), ctx.f.get('flags8', 0), state)
    return g, state


def handle_heal(ctx):
    b, a, f, log = ctx.b, ctx.a, ctx.f, ctx.log
    eff = 0x2F if ctx.sk == 0xA3 else ctx.sk        # SkillHealUsAll: $DB8A := $2F

    def one(v, state):
        o, amt, state = skill_heal(b, a, v, eff, f, state)
        log.append((a, 'heal' if o == 'heal' else 'no-effect', (v, amt)))
        return state, v
    return sweep(ctx, one)


def handle_meditate(ctx):
    g, state = _miss(ctx, ctx.t, ctx.state, 0)
    if g == 'pass':
        o, amt = skill_meditate(ctx.b, ctx.a)
        ctx.log.append((ctx.a, 'heal' if o == 'heal' else 'no-effect', (ctx.a, amt)))
    ctx.state = state
    return state


def handle_vivify(ctx):
    b, a, sk, log = ctx.b, ctx.a, ctx.sk, ctx.log

    def one(v, state):
        o, t, state = skill_vivify(b, a, v, sk, state)
        log.append((a, o, t))
        return state, (t if t is not None else v)
    return sweep(ctx, one)


def handle_cure(ctx):
    b, a, sk, log = ctx.b, ctx.a, ctx.sk, ctx.log

    def one(v, state):
        log.append((a, skill_cure(b, v, sk), v))
        return state, v
    return sweep(ctx, one)


def handle_drain(ctx):
    b, a, sk, t = ctx.b, ctx.a, ctx.sk, ctx.t
    g, state = _miss(ctx, t, ctx.state, 0)
    if g == 'pass':
        o, amt, state = mp_drain(b, a, t, sk, state)
        ctx.log.append((a, o, (t, amt)))
    else:
        ctx.log.append((a, g, t))
    ctx.state = state
    return state


def handle_mp(ctx):
    b, a, sk = ctx.b, ctx.a, ctx.sk

    def one(v, state):
        ctx.log.append((a, skill_mp0(b, v) if sk == MP0 else skill_restoremp(b, v), v))
        return state, v
    return sweep(ctx, one)


def handle_chain(ctx):
    b, a, sk, log = ctx.b, ctx.a, ctx.sk, ctx.log
    g, state = _miss(ctx, ctx.t, ctx.state, 0)
    if g != 'pass':
        ctx.state = state
        return state
    if sk == LIFESONG:
        o, state = lifesong_cast(b, a, state)
    elif sk == LIFEDANCE:
        o, state = lifedance_cast(b, a, state)
    else:
        o = 'chain'
    if o != 'chain':
        log.append((a, 'life-' + o, sk))
        ctx.state = state
        return state
    if sk == LIFESONG:
        log.append((a, 'life-song', lifesong_walk(b, a, ctx.t)))
        ctx.state = state
        return state
    log.append((a, 'life-chain', chain_walk(b, a, ctx.t)))
    state = ctx.idle(state, 'pre_target')
    o, state = chain_caster(b, a, state)
    log.append((a, 'life-caster', o))
    ctx.state = state
    return state


def rearm_revived(b, state, log):
    """PHASE9 hook: a slot revived this round still holds $DD13 = $FF (the
    KO mark; SaveBattle_51dd never writes $DD13); the next command phase
    re-arms every live slot ($DD13 1 -> 2, measured), so it acts NEXT
    round."""
    for s in range(8):
        if b.dd1b[s] == 0 and b.dd13[s] == 0xFF:
            b.dd13[s] = 2
    return state


# --------------------------------------------------------------------------
# registration
# --------------------------------------------------------------------------
for _id in HEAL_HANDLER:
    B.ACTION_HANDLERS[_id] = handle_heal
B.ACTION_HANDLERS[MEDITATE] = handle_meditate
for _id in REVIVE_IDS:
    B.ACTION_HANDLERS[_id] = handle_vivify
for _id in CURES:
    B.ACTION_HANDLERS[_id] = handle_cure
for _id in DRAIN_IDS:
    B.ACTION_HANDLERS[_id] = handle_drain
B.ACTION_HANDLERS[MP0] = handle_mp
B.ACTION_HANDLERS[RESTOREMP] = handle_mp
for _id in CHAIN_IDS:
    B.ACTION_HANDLERS[_id] = handle_chain

# 'heal' keeps pacing/balance treating HP heals as heals (the AI-commit
# target now comes from COMMIT_TARGETS; the name is for coverage/value).
for _id in (0x2D, 0x2E, 0x2F, 0x94, 0xA3, MEDITATE):
    B.CORE_OVERRIDES[_id] = 'heal'
for _id in REVIVE_IDS | CHAIN_IDS:
    B.CORE_OVERRIDES[_id] = 'revive'
for _id in CURES:
    B.CORE_OVERRIDES[_id] = 'cure'
for _id in DRAIN_IDS:
    B.CORE_OVERRIDES[_id] = 'mpdrain'
B.CORE_OVERRIDES[MP0] = 'mp0'
B.CORE_OVERRIDES[RESTOREMP] = 'restoremp'

for _id, _row in ROWS.items():
    B.COMMIT_TARGETS[_id] = _row
    B.TARGET_RESOLVERS[_id] = act_target
B.PHASE9_HOOKS.append(rearm_revived)
