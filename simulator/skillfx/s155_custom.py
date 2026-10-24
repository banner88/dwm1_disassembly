"""S155 — the built-in custom battle skills LoneWolf $DF, Punish $EB, Finish $EC,
Rupture $ED, Rust $EE (and Repel $DE: no battle effect) (BATTLE_SKILL_SYSTEM
§13.10; PROJECT_COMPILER §2.63); S156 Plunder $EA (§13.11, PROJECT_COMPILER §2.64).

Byte source: patches/bank_072.asm (romhack only — the original game has none of
these ids, so every vanilla validator is unchanged):
* LoneWolf / Punish / Finish / Rupture: NewDispatch72 -> MournDispatch52 =
  bank $52 CalcDefenseWrapper (the ATK-vs-DEF roll, D.calc_skill_defense)
  then the handler scales $DB56 (DamagePct72: min(999, dmg x P / 100), at
  least 1 when the roll was not 0). The bank $53 post-calc stage (crit — which
  skips the handler —, $DB42 x1.5, defence levels) runs after, as for Mourn.
* Rust (named Blunt since S155 r3): no damage machine; RustRoll72 = Sap's roll
  (resistance 12, ladder B, $DB42 bit 2 sure) then ATK -= max(1, baseATK x P /
  100), floor 1, the "lowered" mark (+8 bit 7). S155 r5: it does not stack —
  a slot already blunted (WRAM wBlunted bit, zeroed at the battle's start,
  cleared when DeMagic / Surge give the ATK back) fails before the roll.
* DeMagic (DispelBaseDefAgl_647c, non-revert path) and Surge (the lowered-mark
  branch) also put a lowered ATK back to base (bank $53 RestoreATK53, the
  helper slot 3/7 skipped).
* The percentages are project data (gd_custom_pcts): Board.custom_pcts =
  {key: value} (editor2/core/balance.py), else the defaults below.
* [S156] Plunder: no damage machine (CustomDispatch52_shared); SkillPlunder
  steals ONE StealTable buff of the target — among the ones the caster lacks
  (its stat can still rise for DEF / AGL), else any — picked by ONE BattleRNG
  step: row = the k-th eligible, k = (RNG1 x n) >> 8; the caster gets it as if
  cast this round (steal_apply); none -> "But nothing happens!", MP spent.
* The AI (bank $57 CustomAI57 -> bank $72 CustomAIRule72) and the one-foe
  target pick (bank $58 DispatchBoundsStub row $F0 -> CustomTargetPick72) are
  modelled in ai_rules.CUSTOM_RULES / the pickers below.
Measured S155 in PyBoy on the user's save (tools/walk_skills.py).
"""
from .. import ai_rules as R
from .. import battle as B
from .. import damage as D
from . import f6_defence as F6
from . import f7_stats as F7
from . import f10_dispel as F10

REPEL, LONEWOLF, PLUNDER = 0xDE, 0xDF, 0xEA
PUNISH, FINISH, RUPTURE, RUST = 0xEB, 0xEC, 0xED, 0xEE
DAMAGE_IDS = (LONEWOLF, PUNISH, FINISH, RUPTURE)
PICK_IDS = (LONEWOLF, PUNISH, FINISH, RUPTURE, RUST, PLUNDER)   # TARGET_CHOICE + S156
PCT_MAX = 2000
DEFAULT_PCTS = {'duo': 200, 'alone': 400, 'per_buff': 50, 'at_full_hp': 20,
                'near_zero_hp': 200, 'burst': 300, 'atk_loss': 50}
TARGET_PICK = 0xF0

# BuffTable (bank $72): (offset in the slot's block, mask); +8/+9 = the shifted pair
BUFF_TABLE = ((3, 0x04), (3, 0x08), (4, 0x01), (4, 0x02), (4, 0x04), (4, 0x20),
              (4, 0x40), (5, 0x40), (6, 0x03), (6, 0x30), (6, 0xC0), (7, 0x0C),
              (8, 0x40), (8, 0x20), (8, 0x08), (8, 0x02), (9, 0x07))


# [S156] StealTable (bank $72): (offset, mask, the caster's bits cleared, the
# value set (None = the target's bits copied), kind, the stock skill whose name
# the line shows); kinds: bits / DEF raised / AGL raised / SuckAll / the stance
S_BIT, S_DEF, S_AGL, S_SUCK, S_STANCE = 0, 1, 2, 3, 4
STEAL_TABLE = (
    (3, 0x04, 0x04, 0x04, S_BIT, 0x25), (3, 0x08, 0x08, 0x08, S_BIT, 0xA6),
    (4, 0x01, 0x01, 0x01, S_BIT, 0x1B), (4, 0x02, 0x22, 0x02, S_BIT, 0x28),
    (4, 0x04, 0x04, 0x04, S_BIT, 0x24), (4, 0x20, 0x22, 0x20, S_BIT, 0x27),
    (4, 0x40, 0x40, 0x40, S_BIT, 0x8A), (5, 0x40, 0x40, 0x40, S_BIT, 0x26),
    (6, 0x03, 0x03, 0x03, S_BIT, 0x41), (6, 0x30, 0x30, 0x30, S_BIT, 0x43),
    (6, 0xC0, 0xC0, 0x80, S_BIT, 0x54), (7, 0x0C, 0x0C, None, S_BIT, 0x77),
    (8, 0x40, 0x00, 0x00, S_DEF, 0x1E), (8, 0x40, 0x00, 0x00, S_AGL, 0x22),
    (8, 0x20, 0x20, 0x20, S_BIT, 0x8C), (8, 0x08, 0x08, 0x08, S_BIT, 0x7F),
    (8, 0x02, 0x00, 0x00, S_SUCK, 0x8F), (9, 0x07, 0x0F, None, S_STANCE, 0x8D))
STANCE_NAME = {1: 0x8D, 2: 0x8E, 4: 0x90}       # Defence / StrongD / BladeD


def pct(b, key):
    v = getattr(b, 'custom_pcts', None) or {}
    return min(int(v.get(key, DEFAULT_PCTS[key])), PCT_MAX)


def mul_pct(h, d):
    """MulPct72: floor(h * d / 100) (exact in its range)."""
    return (h * d) // 100


def damage_pct(dmg, p):
    """DamagePct72."""
    r = min(999, mul_pct(dmg, p))
    if r == 0 and dmg:
        r = 1
    return r


def _byte(b, t, k):
    return F10.get8(b, t, k) if k >= 8 else b.stb(t, k)


def _set_byte(b, t, k, v):
    if k >= 8:
        F10.set8(b, t, k, v)
    else:
        b.set_stb(t, k, v)


# ---- [S156] Plunder ------------------------------------------------------------
def _stat(b, kind):
    return (b.dfn, 'dfn', 999) if kind == S_DEF else (b.agl, 'agl', 511)


def stat_room(b, s, kind, v):
    """StatRoom72 -> (can rise, the bound it met): below the limit (999 / 511)
    and below the cap (base x4 for a slot < 4 or a link battle, x2 an enemy)."""
    _arr, key, lim = _stat(b, kind)
    if v >= lim:
        return False, lim
    cap = (b.base[key][s] * F7.cap_mult(b, s)) & 0xFFFF
    return v < cap, cap


def stat_above_base(b, s, kind):
    arr, key, _lim = _stat(b, kind)
    return arr[s] > b.base[key][s]


def stat_rise(b, s, kind):
    """StatRise72: one Upper / Speed on s (StatDefUp_5e3e / StatAglUp_5f08)."""
    arr, key, _lim = _stat(b, kind)
    ok, _bd = stat_room(b, s, kind, arr[s])
    if not ok:
        return None
    new = arr[s] + (b.base[key][s] >> 1)
    ok, bd = stat_room(b, s, kind, new)
    if not ok:
        new = bd
    amt = new - arr[s]
    arr[s] = new
    F7.set_marker(b, s, F7.RAISED)
    return amt


def steal_has(b, t, row):
    """StealHas72: t has the row's buff (DEF / AGL: the raised mark, not
    transformed, the stat above its base)."""
    off, mask, _c, _v, kind, _n = row
    if kind in (S_DEF, S_AGL):
        if b.stb(t, 3) & 0x30 or not (_byte(b, t, 8) & 0x40):
            return False
        return stat_above_base(b, t, kind)
    return bool(_byte(b, t, off) & mask)


def caster_has(b, a, row):
    """StealCasterHas72: the caster has it already (DEF / AGL: cannot rise;
    SuckAll: its side already has a SuckAll user)."""
    off, mask, _c, _v, kind, _n = row
    if kind in (S_DEF, S_AGL):
        arr, _k, _l = _stat(b, kind)
        return not stat_room(b, a, kind, arr[a])[0]
    if kind == S_SUCK:
        return bool(b.st[(a >> 2) & 1] & 0x40)
    return bool(_byte(b, a, off) & mask)


def steal_count(b, t):
    """ScoreSteal72: how many StealTable buffs t has."""
    return sum(1 for row in STEAL_TABLE if steal_has(b, t, row))


def steal_choices(b, a, t):
    """The rows SkillPlunder picks from: the ones a lacks, else all t has."""
    have = [i for i, row in enumerate(STEAL_TABLE) if steal_has(b, t, row)]
    lack = [i for i in have if not caster_has(b, a, STEAL_TABLE[i])]
    return lack or have


def steal_apply(b, a, t, i):
    """StealApply72: row i from t to a -> (the name's stock skill id, the caster's
    stat rise — $DB56, 0 for the bit buffs / no room)."""
    off, mask, clear, value, kind, name = STEAL_TABLE[i]
    if kind in (S_DEF, S_AGL):
        arr, key, _l = _stat(b, kind)
        arr[t] = b.base[key][t]
        rise = stat_rise(b, a, kind) or 0
        if not stat_above_base(b, t, S_AGL if kind == S_DEF else S_DEF):
            F7.clear_marker(b, t, F7.RAISED)
        return name, rise
    if kind == S_SUCK:
        F10.set8(b, t, 8, F10.get8(b, t, 8) & ~0x02)
        ts, cs = (t >> 2) & 1, (a >> 2) & 1
        b.st[ts] &= ~0x40 & 0xFF
        F6.db4a(b)[ts] &= 0x03
        if not b.st[cs] & 0x40:
            b.st[cs] |= 0x40
            F6.db4a(b)[cs] |= (a & 3) << 2
            F10.set8(b, a, 8, F10.get8(b, a, 8) | 0x02)
        return name, 0
    tv = _byte(b, t, off) & mask
    _set_byte(b, t, off, _byte(b, t, off) & ~mask & 0xFF)
    val = tv if value is None else value
    _set_byte(b, a, off, (_byte(b, a, off) & ~clear & 0xFF) | val)
    if kind == S_STANCE:
        return STANCE_NAME.get(tv, 0x8D), 0
    return name, 0


LINE_PLUNDER, LINE_PLUNDER_DEF, LINE_PLUNDER_AGL = 6, 7, 8


def plunder_line(i, rise):
    """[S156 r2] the line SkillPlunder shows: 7 / 8 (+ the rise page) when the stolen
    raised DEF / AGL rose on the caster ($DB56 = rise > 0), else 6."""
    kind = STEAL_TABLE[i][4]
    if rise and kind in (S_DEF, S_AGL):
        return LINE_PLUNDER_DEF if kind == S_DEF else LINE_PLUNDER_AGL
    return LINE_PLUNDER


def plunder_one(b, a, t, state):
    """SkillPlunder -> (outcome, (row, the name's skill id, the rise ($DB56), the line)
    | None, state)."""
    if t == a:
        return 'fail', None, state
    ch = steal_choices(b, a, t)
    if not ch:
        return 'fail', None, state          # $BB, MP spent
    state = B.rng_step(state)               # BattleRNG72 (the link RNG: not modelled)
    i = ch[(B.rng1(state) * len(ch)) >> 8]
    name, rise = steal_apply(b, a, t, i)
    return 'ok', (i, name, rise, plunder_line(i, rise)), state


def plunder_handler(ctx):
    def body(c, v, div, state):
        out, got, state = plunder_one(c.b, c.a, v, state)
        c.log.append((c.a, 's156', (c.sk, v, out, got)))
        return 'done', None, state
    return B.default_victims(ctx, body, victims=F7.victims(ctx))


def count_buffs(b, t):
    return sum(1 for k, m in BUFF_TABLE if _byte(b, t, k) & m)


def side_count(b, s):
    """SideCount72: slots 0-2 of s's side with $DD1B != $FF (alive or fallen)."""
    base = s & 4
    return sum(1 for x in range(base, base + 3) if b.dd1b[x] != 0xFF)


def missing_share(hp, maxhp):
    """MissingShare72: whole percent of MaxHP lost (both shifted below 256)."""
    loss = max(0, maxhp - hp)
    while maxhp >= 256:
        maxhp >>= 1
        loss >>= 1
    if not maxhp:
        return 0
    return (loss * 100) // maxhp


def has_ailment(b, t):
    return bool(b.stb(t, 2) | (b.stb(t, 3) & 0xC3))


def finish_pct(b, t):
    lo, hi = pct(b, 'at_full_hp'), pct(b, 'near_zero_hp')
    share = missing_share(b.hp[t], b.maxhp[t])
    if hi >= lo:
        return lo + mul_pct(hi - lo, share)
    return lo - mul_pct(lo - hi, share)


def multiplier(b, a, v, sk):
    """-> (P %, extra-line?) or None = Rupture's failure (no ailment)."""
    if sk == LONEWOLF:
        n = side_count(b, a)
        if n >= 3:
            return 100, False
        return pct(b, 'duo' if n == 2 else 'alone'), True
    if sk == PUNISH:
        n = count_buffs(b, v)
        if not n:
            return 100, False
        return min(100 + n * pct(b, 'per_buff'), PCT_MAX), True
    if sk == FINISH:
        p = finish_pct(b, v)
        return p, p > 100
    if sk == RUPTURE:
        if not has_ailment(b, v):
            return None
        b.set_stb(v, 3, b.stb(v, 3) & 0x3C)
        b.set_stb(v, 2, 0)
        return pct(b, 'burst'), True
    return 100, False


def damage_body(ctx, v, div, state):
    b, a = ctx.b, ctx.a
    dmg, state = D.calc_skill_defense(b.atk[a], b.dfn[v], state, target_idx=v,
                                      arena=b.link, attacker_idx=a)
    m = multiplier(b, a, v, ctx.sk)
    if m is None:
        ctx.log.append((a, 's155', (ctx.sk, v, 'fail', None)))   # $BB, MP spent
        return 'done', None, state
    p, _line = m
    return 'dmg', damage_pct(dmg, p), state


def damage_handler(ctx):
    return B.default_victims(ctx, damage_body, victims=F7.victims(ctx))


def blunted(b):
    """wBlunted: the set of blunted slots (a Board is one battle)."""
    v = getattr(b, 's155_blunted', None)
    if v is None:
        v = set()
        b.s155_blunted = v
    return v


def rust_one(b, a, t, state):
    """SkillRust: (outcome, ATK lost, state)."""
    if t in blunted(b):                     # [S155 r5] no stacking: fails, no roll
        return 'fail', None, state
    hit, state = F7.debuff_roll(b, a, t, F7.RT_SAP, D.LADDER_HIT_B, state)
    if not hit:
        return 'rollmiss', None, state
    atk = b.atk[t]
    if atk <= 1:
        return 'fail', None, state
    amt = max(1, mul_pct(b.base['atk'][t], pct(b, 'atk_loss')))
    new = max(1, atk - amt)
    b.atk[t] = new
    F7.set_marker(b, t, F7.LOWERED)
    blunted(b).add(t)
    return 'ok', atk - new, state


def rust_handler(ctx):
    def body(c, v, div, state):
        out, amt, state = rust_one(c.b, c.a, v, state)
        c.log.append((c.a, 's155', (c.sk, v, out, amt)))
        return 'done', None, state
    return B.default_victims(ctx, body, victims=F7.victims(ctx))


def inert_handler(ctx):
    """Repel in a battle: "But nothing happens" (CustomBattleRun .inert)."""
    ctx.log.append((ctx.a, 'no-effect', ctx.real_sk))
    return ctx.state


def restore_atk(b, t):
    """RestoreATK53: ATK := base when below it; the helper slot is skipped."""
    if (t & 3) == 3:
        return
    blunted(b).discard(t)                   # [S155 r5]
    if b.atk[t] < b.base['atk'][t]:
        b.atk[t] = b.base['atk'][t]


def _dispel_hook(b, event, t):
    if event == 'base':
        restore_atk(b, t)


_surge_one = F7.PER_VICTIM[F7.SURGE]


def surge_one(b, a, t, state):
    lowered = F7.marker(b, t) & F7.LOWERED
    r = _surge_one(b, a, t, state)
    if lowered:
        restore_atk(b, t)
    return r


# --------------------------------------------------------------------------
# targets: bank $58 row $F0 -> CustomTargetPick72 (one-foe mode); the all-foes
# mode keeps row 3 (Firebal's: the first live opposing slot)
# --------------------------------------------------------------------------
def _score(b, sk, t):
    if sk == RUPTURE:
        return 1 if has_ailment(b, t) else 0
    if sk == PUNISH:
        return count_buffs(b, t)
    if sk == PLUNDER:                       # [S156] ScoreSteal72
        return steal_count(b, t)
    if sk == FINISH:
        return missing_share(b.hp[t], b.maxhp[t]) + 1
    if sk == RUST:
        if t in blunted(b):                 # [S155 r5]
            return 0
        return (b.atk[t] >> 2) + 1 if b.atk[t] > 1 else 0
    return 1


def opp_scan(b, s, sk):
    """OppScan72 -> (best score, its slot | None, the first live opponent | None)."""
    base = (s & 4) ^ 4
    best, slot, first = 0, None, None
    for t in range(base, base + 3):
        if b.dd1b[t] != 0:
            continue
        if first is None:
            first = t
        sc = min(_score(b, sk, t), 255)
        if sc and sc > best:
            best, slot = sc, t
    return best, slot, first


def target_pick(b, s, sk):
    base = (s & 4) ^ 4
    rows = getattr(b, 'custom_rows', None) or {}
    if rows.get(sk, TARGET_PICK) == TARGET_PICK:
        _best, slot, first = opp_scan(b, s, sk)
        if slot is not None:
            return slot
        return first if first is not None else base
    live = b.live_side(base)
    return live[0] if live else base


def _mk_pick(sk):
    def pick(b, s, state):
        return target_pick(b, s, sk), state
    return pick


# --------------------------------------------------------------------------
# AI: CustomAIRule72 at the chain end (ai_rules.evaluate_chain)
# -> (veto, bonus, penalty); view.board = the Board (pacing.ChainRules)
# --------------------------------------------------------------------------
def ai_rule(skill, actor, view):
    b = getattr(view, 'board', None)
    if skill == REPEL:
        return True, 0, 0
    if skill == PLUNDER and b is None:
        return True, 0, 0
    if b is None:
        return False, 0, 0
    if skill == LONEWOLF:
        n = side_count(b, actor)
        return False, (40 if n == 1 else 20 if n == 2 else 0), 0
    best, _slot, _first = opp_scan(b, actor, skill)
    if skill == RUPTURE:
        return (True, 0, 0) if not best else (False, 50, 0)
    if skill == RUST:
        return (not best), 0, 0
    if skill == PUNISH:
        return False, 20 * min(best, 3), 0
    if skill == PLUNDER:                    # [S156] veto without a buff to take
        return (True, 0, 0) if not best else (False, 20 * min(best, 3), 0)
    if skill == FINISH:
        if not best:
            return False, 0, 0
        if best >= 51:
            return False, 40, 0
        return False, 0, (20 if best < 26 else 0)
    return False, 0, 0


for _sk in DAMAGE_IDS:
    B.ACTION_HANDLERS[_sk] = damage_handler
    B.CORE_OVERRIDES[_sk] = 'calcdef'
B.ACTION_HANDLERS[RUST] = rust_handler
B.CORE_OVERRIDES[RUST] = 'stat'
B.ACTION_HANDLERS[PLUNDER] = plunder_handler     # [S156]
B.CORE_OVERRIDES[PLUNDER] = 'stat'
B.ACTION_HANDLERS[REPEL] = inert_handler
B.CORE_OVERRIDES[REPEL] = 'none'
for _sk in PICK_IDS:
    B.RERESOLVE_PICKERS[_sk] = _mk_pick(_sk)
    B.COMMIT_TARGETS[_sk] = _mk_pick(_sk)
for _sk in (REPEL, PLUNDER, LONEWOLF, PUNISH, FINISH, RUPTURE, RUST):
    R.CUSTOM_RULES[_sk] = ai_rule
F10.DISPEL_HOOKS.append(_dispel_hook)
F7.PER_VICTIM[F7.SURGE] = surge_one
