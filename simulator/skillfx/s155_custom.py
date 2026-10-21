"""S155 — the built-in custom battle skills LoneWolf $DF, Punish $EB, Finish $EC,
Rupture $ED, Rust $EE (and Repel $DE / Plunder $EA: no battle effect)
(BATTLE_SKILL_SYSTEM §13.10; PROJECT_COMPILER §2.63).

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
* The AI (bank $57 CustomAI57 -> bank $72 CustomAIRule72) and the one-foe
  target pick (bank $58 DispatchBoundsStub row $F0 -> CustomTargetPick72) are
  modelled in ai_rules.CUSTOM_RULES / the pickers below.
Measured S155 in PyBoy on the user's save (tools/walk_skills.py).
"""
from .. import ai_rules as R
from .. import battle as B
from .. import damage as D
from . import f7_stats as F7
from . import f10_dispel as F10

REPEL, LONEWOLF, PLUNDER = 0xDE, 0xDF, 0xEA
PUNISH, FINISH, RUPTURE, RUST = 0xEB, 0xEC, 0xED, 0xEE
DAMAGE_IDS = (LONEWOLF, PUNISH, FINISH, RUPTURE)
PICK_IDS = (LONEWOLF, PUNISH, FINISH, RUPTURE, RUST)   # TARGET_CHOICE
PCT_MAX = 2000
DEFAULT_PCTS = {'duo': 200, 'alone': 400, 'per_buff': 50, 'at_full_hp': 20,
                'near_zero_hp': 200, 'burst': 300, 'atk_loss': 50}
TARGET_PICK = 0xF0

# BuffTable (bank $72): (offset in the slot's block, mask); +8/+9 = the shifted pair
BUFF_TABLE = ((3, 0x04), (3, 0x08), (4, 0x01), (4, 0x02), (4, 0x04), (4, 0x20),
              (4, 0x40), (5, 0x40), (6, 0x03), (6, 0x30), (6, 0xC0), (7, 0x0C),
              (8, 0x40), (8, 0x20), (8, 0x08), (8, 0x02), (9, 0x07))


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
    """Repel / Plunder in a battle: "But nothing happens" (CustomBattleRun .inert)."""
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
    if sk in (PUNISH, PLUNDER):
        return count_buffs(b, t)
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
    if skill in (REPEL, PLUNDER):
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
for _sk in (REPEL, PLUNDER):
    B.ACTION_HANDLERS[_sk] = inert_handler
    B.CORE_OVERRIDES[_sk] = 'none'
for _sk in PICK_IDS:
    B.RERESOLVE_PICKERS[_sk] = _mk_pick(_sk)
    B.COMMIT_TARGETS[_sk] = _mk_pick(_sk)
for _sk in (REPEL, PLUNDER, LONEWOLF, PUNISH, FINISH, RUPTURE, RUST):
    R.CUSTOM_RULES[_sk] = ai_rule
F10.DISPEL_HOOKS.append(_dispel_hook)
F7.PER_VICTIM[F7.SURGE] = surge_one
