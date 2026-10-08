#!/usr/bin/env python3
"""S130 (ROADMAP P3.15b) — the PLAYER's battle planner: the orders a competent
player gives each round (battle menu plan $81 "Command").

    planner = make_planner(records)            # one per team (it caches)
    b.ext['planner'] = planner
    simulate_battle(b, ..., party_policy='command')
        -> pacing.give_orders (the menu phase) -> planner(b, s)
           -> (skill id, target slot | None)

The target is the player's cursor choice (pacing.menu_order: a single enemy /
ally / dead ally for a revive); None = the menu's own: a group / self target,
or for a single target the cursor's default (the first live slot — NOT the
engine's commit pick). Single-target orders are tried on every candidate
target, so the planner names them. (pacing also accepts a list of (skill,
target) alternatives; this planner returns one pair — its trials already
drop orders the menu refuses.) Every obeyed order drifts the monster's
personality bases (pacing.personality_drift, in command_commit); the planner
does not plan around it.

GREEDY EXPECTED VALUE, measured with the simulator's own code. For actor s the
options are plain Attack $3A, Defence $8D and every known skill it has the MP
for. Each option is TRIED on a copy of the board (never the real one): only s
acts (every other slot's $DD13 := 3 for the trial round), the order goes
through the menu model (pacing.menu_order: refusals, $DD03 := 3 so the target
stands) and battle.simulate_round runs it — veto, MISS machine, damage cores, resistance
ladders, metal, boss gates, the skill families' handlers, everything — over a
few RNG draws (common to every option: a fair comparison), and a post-action
hook (battle.POST_ACTION_HOOKS, active only while a trial runs) snapshots the
board right after the action, before phase 9 clears one-round marks.

The value of an option, in "log progress" units (a fraction of what is left on
either side — the race model: the party wins when it removes the enemies' HP
before the enemies remove the party's; W = rounds-to-lose / rounds-to-win,
an option is worth its change of log W):
  damage    E[min(dmg, hp)] / enemy HP left, + P(kill) x that enemy's share of
            the enemies' threat (a dead enemy stops hitting)
  friendly  - HP lost / party HP, - P(an ally dies) x its worth
  heal      HP restored (capped at the missing HP) / party HP, + the drop of
            that ally's chance to die this round x its worth (worth = its
            share of the party's damage + 0.3) — so a heal on a healthy ally
            is worth ~nothing and a heal on an ally about to die a lot
  revive    the revived ally's worth + its HP / party HP
  status / buff / debuff / guard  measured by its EFFECT: the enemies'
            expected damage this round is re-measured (enemy trials) on the
            board after the option, x a duration (1 round for marks/stances,
            ~2 for sleep/confusion, the fight's expected length for stat
            changes, seals, paralysis, poison); DEF lowered on an enemy adds
            the extra physical damage over the fight. A one-round stance or
            guard (Defence $8D, StrongD, Cover, …) counts only the damage it
            saves that round (no survival bonus — re-earned every round it
            would stall the fight) and is only considered when the actor is
            in danger of dying this round
  MP        a tiny cost per MP (ties go to the free option), an ineffective
            spell is never cast, and an actor that knows a heal keeps the MP
            for it in a long fight (a reserve rule) unless the option is a heal
            or clearly worth it.
The allies already ordered this round (the menu asks slot 0, 1, 2 in turn and
writes each order to the queue at once) are taken into account: their expected damage / heals are applied to a virtual board
first (no double heals, no overkill).

Threat (the enemies' expected damage per ally this round) comes from enemy
trials: each live enemy's options (plain Attack + its $DC64 list, MP
permitting) tried against each ally, averaged with the engine's front-weighted
target odds.

Speed: every trial result is cached by a signature of the board WITHOUT HP and
MP (stats, status bytes, who is alive) — a battle's boards repeat (round 1 is
the same in every battle of a team, most later rounds share statuses), damage
is stored raw and capped by the HP of the moment. One planner per team.
Deterministic: the trial RNG states come from a hash of the signature.

Arena fights (db73 == 2) never call the planner (the menu offers "NO SP SK"
instead of COMMAND): the player picks a tactic — editor2/core/balance.py tries
Charge / Mixed / Cautious and NO SP SK (tactic 3, no order) and keeps the best.
"""
import copy
import os
import sys
import time
import zlib

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import battle as B           # noqa: E402
from simulator import pacing as P           # noqa: E402

ATTACK = 0x3A
DEFENCE = 0x8D
LOAF = 0x98
BIG = 1 << 20                     # an instant kill (death spell, KO without a hit)
FRONT_ODDS = {1: (1.0,), 2: (0.664, 0.336), 3: (0.5, 0.332, 0.168)}
NEVER = frozenset(range(0x97, 0xA2)) | frozenset(range(0xA2, 0xD5)) | {0xDA, 0xDB}
HEAL_CORES = ('heal',)
REVIVE_CORES = ('revive',)
MAX_TW = 5.0                      # duration cap (rounds) for lasting effects


# --------------------------------------------------------------------------
# board copies + the post-action snapshot
# --------------------------------------------------------------------------
_SHARED = ('core_alias', 'quake_range')
# ext entries a trial round never changes in place (rebuilt each commit, or
# only appended to by the menu phase, which a trial does not run)
_EXT_SHARED = frozenset(('planner', 'f10_optlists', 'command_refused', 'command_ordered'))


def clone(b, drop_cap=False):
    """A deep enough copy of a Board for a trial (lists / dicts copied; the
    read-only tables shared)."""
    c = B.Board.__new__(B.Board)
    d = c.__dict__
    for k, v in b.__dict__.items():
        t = type(v)
        if t is list:
            d[k] = [list(x) if type(x) is list else x for x in v]
        elif k == 'ext':
            e = {}
            for kk, vv in v.items():
                if kk == '_plan_cap':
                    continue
                tv = type(vv)
                if kk in _EXT_SHARED or tv in (int, str, bool, float, tuple) or vv is None:
                    e[kk] = vv
                else:
                    e[kk] = copy.deepcopy(vv)
            d[k] = e
        elif k == 'base':
            d[k] = {kk: list(vv) for kk, vv in v.items()}
        elif t is dict and k not in _SHARED:
            d[k] = copy.deepcopy(v)
        else:
            d[k] = v
    return c


def _cap_hook(b, a, sk, f, state, log):
    cap = b.ext.get('_plan_cap')
    if cap is not None and cap[0] == a and cap[1] is None:
        cap[1] = clone(b)
    return state


if _cap_hook not in B.POST_ACTION_HOOKS:
    B.POST_ACTION_HOOKS.append(_cap_hook)


def _st_sig(st, s):
    o = s * 8
    v6 = st[o + 6]
    v7 = st[o + 7]
    return (st[o], st[o + 1], st[o + 2] & 0xF3, st[o + 3], st[o + 4], st[o + 5],
            tuple(bool(v6 >> k & 3) for k in (0, 2, 4, 6)), (v7 & 0xF0) | bool(v7 & 0x0F))


def board_sig(b):
    """What an option's raw effect depends on: everything but HP / MP."""
    return (tuple(b.dd1b), tuple(b.atk), tuple(b.dfn), tuple(b.agl), tuple(b.int),
            tuple(_st_sig(b.st, s) for s in range(8)), tuple(b.db42), tuple(b.side_seal),
            tuple(b.res), tuple(b.maxhp))


def _states(sig, tag, k):
    h = zlib.crc32(repr((sig, tag)).encode())
    out = []
    for i in range(k):
        h = (h * 1103515245 + 12345) & 0x7FFFFFFF
        out.append((h >> 8) & 0xFFFF)
    return out


# --------------------------------------------------------------------------
# one trial
# --------------------------------------------------------------------------
def run_trial(b, s, sk, tgt, state, records, keep_target=False):
    """Copy b, let only slot s act sk -> tgt with the RNG at `state`. A party
    slot's order goes through the battle menu (pacing.menu_order: the
    player's target, $DD03 := 3, None = the cursor's default); an enemy's
    target is its commit pick (tgt None) or, keep_target, exactly tgt.
    Returns (log, post) — post = the board right after the action (None when
    the turn never reached a handler: vetoed, asleep, …) — or (None, None)
    when the menu refuses the order."""
    c = clone(b)
    for x in range(8):
        if x != s and c.dd13[x] == 2:
            c.dd13[x] = 3
    c.dd13[s] = 2
    menu = getattr(P, 'menu_order', None)
    if s < 3 and menu is not None:
        ref = [state]
        res, _why = menu(c, s, sk, tgt, records, ref)
        if res is None:
            return None, None
        state = ref[0]
        c.dd03[s] = 3
        sk, tgt = res
    else:
        if keep_target and tgt is not None:
            c.dd03[s] = 3             # aim exactly there (no act-time re-pick)
        if tgt is None:
            ref = [state]
            tgt = P._commit_target(c, s, sk, records, ref)
            state = ref[0]
    c.queue[2 * s] = sk
    c.queue[2 * s + 1] = tgt
    cap = [s, None]
    c.ext['_plan_cap'] = cap
    log, _st = B.simulate_round(c, state, records, (), None)
    post = cap[1]
    if post is not None:
        post.ext.pop('_plan_cap', None)
    return log, post


class Effect:
    """An option's measured raw effect over the draws (per draw lists)."""
    __slots__ = ('dmg', 'heal', 'revive', 'posts', 'n', 'changed', 'dur', 'dfn_drop',
                 'refused')

    def __init__(self, n):
        self.n = n
        self.refused = False
        self.dmg = {}            # slot -> [raw dmg per draw]
        self.heal = {}           # slot -> [raw heal per draw]
        self.revive = {}         # slot -> [hp fraction per draw]
        self.posts = []          # [(post board sig, post board)] with a state change
        self.changed = 0         # draws with a state change
        self.dur = 1.0
        self.dfn_drop = {}       # enemy slot -> mean DEF lost


def _dur_of(b, post, s):
    """Rounds an option's state change lasts (rough)."""
    dur = 1.0
    for v in range(8):
        if post.atk[v] != b.atk[v] or post.dfn[v] != b.dfn[v] or post.agl[v] != b.agl[v] \
                or post.int[v] != b.int[v]:
            return MAX_TW
        o = v * 8
        a2, p2 = b.st[o + 2], post.st[o + 2]
        new2 = p2 & ~a2
        if new2 & 0x63:                       # poison, heavy, curse, paralysis
            return MAX_TW
        if new2 & 0x90:                       # sleep / confusion
            dur = max(dur, 2.5)
        if (post.st[o + 3] & ~b.st[o + 3]) or (post.st[o + 4] & ~b.st[o + 4]) \
                or (post.st[o + 5] & 0xC0 & ~b.st[o + 5]):
            dur = max(dur, MAX_TW)            # seals, persistent marks
        if post.st[o + 5] & 0x3F & ~b.st[o + 5]:
            dur = max(dur, 1.5)               # a pending one-shot (trip / scare)
        if (post.st[o + 7] & 0xC0) and not (b.st[o + 7] & 0xC0):
            dur = max(dur, 2.0)               # iron
    return dur


def _measure(b, s, sk, tgt, states, records, keep_target=False):
    eff = Effect(len(states))
    for k, st in enumerate(states):
        log, post = run_trial(b, s, sk, tgt, st, records, keep_target)
        if log is None:
            eff.refused = True
            break
        hits = {}
        heals = {}
        kos = set()
        for e in log:
            if e[0] != s or len(e) < 3:
                continue
            if e[1] == 'hit':
                v, d, ko = e[2]
                hits[v] = hits.get(v, 0) + d
                if ko:
                    kos.add(v)
            elif e[1] == 'heal':
                v, d = e[2]
                heals[v] = heals.get(v, 0) + d
        if post is not None:
            for v in range(8):
                if b.dd1b[v] == 0 and post.dd1b[v] != 0 and v not in kos:
                    hits[v] = BIG                       # death spell / sacrifice
                elif b.dd1b[v] == 0 and post.hp[v] < b.hp[v]:
                    hits[v] = max(hits.get(v, 0), b.hp[v] - post.hp[v])
                if b.dd1b[v] == 1 and post.dd1b[v] == 0 and v < 4:
                    eff.revive.setdefault(v, [0.0] * eff.n)[k] = post.hp[v] / max(1, post.maxhp[v])
                if v < 4 and post.dd1b[v] == 0 and b.dd1b[v] == 0 and post.hp[v] > b.hp[v] \
                        and v not in heals:
                    heals[v] = post.hp[v] - b.hp[v]
            if any(post.st[i] != b.st[i] for i in range(64)) or post.atk != b.atk \
                    or post.dfn != b.dfn or post.agl != b.agl or post.int != b.int \
                    or post.db42 != b.db42 or post.side_seal != b.side_seal \
                    or post.res != b.res:
                eff.changed += 1
                eff.dur = max(eff.dur, _dur_of(b, post, s))
                eff.posts.append(post)
                for v in range(4, 7):
                    if post.dfn[v] < b.dfn[v]:
                        eff.dfn_drop[v] = eff.dfn_drop.get(v, 0) + (b.dfn[v] - post.dfn[v]) / eff.n
        for v, d in hits.items():
            eff.dmg.setdefault(v, [0] * eff.n)[k] = d
        for v, d in heals.items():
            eff.heal.setdefault(v, [0] * eff.n)[k] = d
    return eff


# --------------------------------------------------------------------------
# the planner
# --------------------------------------------------------------------------
def _f(records, sk):
    r = records.get(sk)
    return r['battle_record']['fields'] if r else {}


def make_planner(records, species=None, draws=3, enemy_draws=1, stats=None):
    """-> planner(b, s) -> (skill id, target byte or None). One per team:
    the caches (trial effects by board signature) live in the closure.
    species is accepted for interface symmetry (the board carries the
    flags the simulator reads). stats (a dict) collects 'calls', 'trials',
    'seconds'."""
    eff_cache = {}           # (sig, s, sk, tgt) -> Effect
    thr_cache = {}           # sig -> threat
    core_cache = {}
    st = stats if stats is not None else {}
    st.setdefault('calls', 0)
    st.setdefault('trials', 0)
    st.setdefault('seconds', 0.0)

    def core(b, sk):
        k = (sk, id(getattr(b, 'core_alias', None)))
        c = core_cache.get(k)
        if c is None:
            real = getattr(b, 'core_alias', {}).get(sk, sk)
            c = B.damage_core(real, records.get(sk))
            core_cache[k] = c
        return c

    def effect(b, sig, s, sk, tgt, n=None, keep=False):
        k = (sig, s, sk, tgt)
        e = eff_cache.get(k)
        if e is None:
            if len(eff_cache) > 100000:
                eff_cache.clear()
                thr_cache.clear()
            n = n or draws
            e = _measure(b, s, sk, tgt, _states(sig, (s, sk, tgt), n), records, keep)
            st['trials'] += n
            eff_cache[k] = e
        return e

    def options(b, s):
        out = [ATTACK]
        skills = (getattr(b, 'party_skills', None) or [None] * 4)[s] if s < 3 else None
        if s >= 4:
            ol = (b.ext.get('f10_optlists') or [[]] * 8)[s] or []
            skills = [x for _t, x in ol]
        for sk in skills or []:
            if sk is None or sk == 0xFF or sk in NEVER or sk == ATTACK or sk in out:
                continue
            f = _f(records, sk)
            if not f:
                continue
            if f.get('mp_cost_byte', 0) > b.mp[s] and not B.mp_veto_exempt(b, s, sk):
                continue
            out.append(sk)
        if s < 3:
            out.append(DEFENCE)
        return out

    def threat(b, sig=None):
        """{'x': [expected dmg to slot 0..3], 'hi': [largest hit], 'by': {enemy: total}}"""
        sig = board_sig(b) if sig is None else sig
        t = thr_cache.get(sig)
        if t is not None:
            return t
        allies = b.live_side(0)
        x = [0.0] * 4
        hi = [0.0] * 4
        by = {}
        for j in b.live_side(4):
            opts = options(b, j)
            tot = 0.0
            for sk in opts:
                f = _f(records, sk)
                single = bool(f.get('target_mode', 17) & 1) or sk == ATTACK
                if f.get('target_mode') in (33, 34, 65) and sk != ATTACK:
                    continue                    # self / own-side skills: no damage to us
                if single:
                    odds = FRONT_ODDS.get(len(allies), ())
                    for i, p in zip(allies, odds):
                        e = effect(b, sig, j, sk, i, enemy_draws, True)
                        d = sum(min(v, 999) for v in e.dmg.get(i, [0])) / e.n
                        x[i] += p * d / len(opts)
                        tot += p * d / len(opts)
                        hi[i] = max(hi[i], max(min(v, 999) for v in e.dmg.get(i, [0])))
                else:
                    e = effect(b, sig, j, sk, None, enemy_draws)
                    for i in allies:
                        d = sum(min(v, 999) for v in e.dmg.get(i, [0])) / e.n
                        x[i] += d / len(opts)
                        tot += d / len(opts)
                        hi[i] = max(hi[i], max(min(v, 999) for v in e.dmg.get(i, [0])))
            by[j] = tot
        t = {'x': x, 'hi': hi, 'by': by}
        thr_cache[sig] = t
        return t

    def pdeath(hp, x, hi):
        if hp <= 0:
            return 0.0
        lo = x
        top = max(hi, x) * 1.15 + 1
        if hp <= lo:
            return 1.0
        if hp >= top:
            return 0.0
        return (top - hp) / (top - lo)

    def dmg_of(e, v, hp):
        """E[min(raw, hp)], P(raw >= hp) for one victim."""
        ds = e.dmg.get(v)
        if not ds:
            return 0.0, 0.0
        n = e.n
        return sum(min(d, hp) for d in ds) / n, sum(1 for d in ds if d >= hp) / n

    def targets(b, s, sk, f, alive_e, alive_a):
        """The targets worth trying for an order: every live enemy for a
        single-enemy order (Attack too), every live ally — or dead one for a
        revive — for a single-ally order, else the menu's own (None)."""
        if s >= 3:
            return [None]
        tm = f.get('target_mode', 0)
        if sk == ATTACK or (tm & 1 and tm & 0x10):
            return list(alive_e) or [None]
        if tm & 1 and not tm & 0x40 and tm & 0x20:
            if core(b, sk) in REVIVE_CORES:
                dead = [i for i in range(3) if b.dd1b[i] == 1]
                return dead or [None]
            if core(b, sk) in HEAL_CORES:
                hurt = sorted(alive_a, key=lambda a: b.hp[a] / max(1, b.maxhp[a]))
                return hurt[:2] or [None]
            return list(alive_a) or [None]
        return [None]

    def plan(b, s, every=None):
        sig = board_sig(b)
        alive_e = b.live_side(4)
        alive_a = [i for i in range(3) if b.valid(i)]
        hp = list(b.hp)
        dead = [b.dd1b[i] == 1 for i in range(8)]
        # the allies already ordered this round: their expected effect first
        for a in range(s):
            if not b.valid(a) or b.dd13[a] != 2:
                continue
            sk, tg = b.queue[2 * a], b.queue[2 * a + 1]
            e = eff_cache.get((sig, a, sk, tg)) or eff_cache.get((sig, a, sk, None))
            if e is None:
                continue
            for v in list(e.dmg):
                if v >= 4 and hp[v] > 0:
                    m, _p = dmg_of(e, v, hp[v])
                    hp[v] = max(0.0, hp[v] - m)
            for v, hs in e.heal.items():
                if v < 4 and not dead[v]:
                    hp[v] = min(b.maxhp[v], hp[v] + sum(hs) / e.n)
            for v in e.revive:
                dead[v] = False
                hp[v] = max(hp[v], 1)
        E = sum(hp[v] for v in alive_e) or 1.0
        Pt = sum(hp[i] for i in alive_a) or 1.0
        thr = threat(b, sig)
        TR = sum(thr['by'].values()) or 1e-9
        # the party's damage rate (best damaging option per live ally)
        dr = {}
        for i in alive_a:
            best = 0.0
            for sk in options(b, i):
                c = core(b, sk)
                if c in HEAL_CORES or c in REVIVE_CORES or sk == DEFENCE:
                    continue
                e = effect(b, sig, i, sk, None)
                best = max(best, sum(dmg_of(e, v, hp[v] if hp[v] > 0 else b.maxhp[v])[0]
                                     for v in alive_e))
            dr[i] = best
        DR = sum(dr.values()) or 1e-9
        Tw = min(MAX_TW, max(1.0, E / DR))
        worth = {i: dr.get(i, 0.0) / DR + 0.3 for i in range(3)}
        for i in range(3):
            if i not in dr:                   # a dead ally: what it would add
                worth[i] = 0.6
        x, hi = thr['x'], thr['hi']
        heals_known = [sk for sk in options(b, s) if core(b, sk) in HEAL_CORES + REVIVE_CORES]
        reserve = 0
        if heals_known:
            reserve = min(_f(records, sk).get('mp_cost_byte', 0) for sk in heals_known)
        best = None
        danger = s < 4 and (pdeath(hp[s], x[s], hi[s]) > 0.25 or every is not None)
        for sk in options(b, s):
            f = _f(records, sk)
            c = core(b, sk)
            if (sk == DEFENCE or c == 'f6-setter') and not danger:
                continue                 # stances / guards: only when in danger
            tgts = targets(b, s, sk, f, alive_e, alive_a)
            for tg in tgts:
                e = effect(b, sig, s, sk, tg)
                if e.refused:
                    continue
                v = 0.0
                for t in alive_e:
                    if hp[t] <= 0:
                        continue
                    m, pk = dmg_of(e, t, hp[t])
                    v += m / E + pk * thr['by'].get(t, 0.0) / TR
                for i in alive_a:
                    m, pk = dmg_of(e, i, hp[i])
                    if m:
                        v -= m / Pt + pk * worth[i]
                for i, hs in e.heal.items():
                    if i >= 3 or dead[i]:
                        continue
                    tgt_i = i
                    if tg is None and c in HEAL_CORES and f.get('target_mode') == 33:
                        tgt_i = min((a for a in alive_a), key=lambda a: hp[a], default=i)
                    h = min(sum(hs) / e.n, b.maxhp[tgt_i] - hp[tgt_i])
                    if h <= 0:
                        continue
                    v += h / Pt + (pdeath(hp[tgt_i], x[tgt_i], hi[tgt_i]) -
                                   pdeath(hp[tgt_i] + h, x[tgt_i], hi[tgt_i])) * worth[tgt_i]
                for i, fr in e.revive.items():
                    if dead[i]:
                        p = sum(1 for q in fr if q > 0) / e.n
                        v += p * (worth[i] + (sum(fr) / e.n) * b.maxhp[i] / Pt)
                if e.changed:
                    # the enemies' damage on the board after the option
                    xs = [0.0] * 4
                    for post in e.posts:
                        t2 = threat(post)
                        for i in range(4):
                            xs[i] += t2['x'][i] / e.n
                    for i in range(4):
                        xs[i] += x[i] * (e.n - e.changed) / e.n
                    gain = 0.0
                    for i in alive_a:
                        dx = x[i] - xs[i]
                        if e.dur <= 1.0:
                            # a one-round stance / guard: the damage it saves this
                            # round only (re-earned every round it would stall the
                            # fight: no survival bonus)
                            gain += 0.7 * dx / Pt
                            continue
                        gain += dx * e.dur / Pt
                        gain += (pdeath(hp[i], x[i], hi[i]) -
                                 pdeath(hp[i], max(0.0, xs[i]), hi[i] * (xs[i] / x[i] if x[i] else 1))) * worth[i]
                    v += gain
                    for t, dd in e.dfn_drop.items():
                        if t in alive_e and hp[t] > 0:
                            v += 0.25 * dd * 0.7 * len(alive_a) * Tw / E
                cost = f.get('mp_cost_byte', 0)
                if cost:
                    v -= 0.002 + 0.01 * cost / max(1, b.maxmp[s] or b.mp[s] or 1)
                    if v <= 0.003:
                        v -= 0.05            # an ineffective spell: never
                    if (reserve and c not in HEAL_CORES and c not in REVIVE_CORES
                            and b.mp[s] - cost < reserve and Tw > 2):
                        v -= 0.08            # keep the MP for a heal
                key = (v, -cost, sk == ATTACK)
                if every is not None:
                    every[(sk, tg)] = v
                if best is None or key > best[0]:
                    best = (key, sk, tg)
        if best is None:
            return ATTACK, None
        return best[1], best[2]

    def values(b, s, danger_too=True):
        """{(skill, target): value} of every option of slot s (the kit
        optimizer's skill ranking); stances included when danger_too."""
        every = {}
        plan(b, s, every)
        return every

    def planner(b, s):
        t0 = time.perf_counter()
        st['calls'] += 1
        try:
            return plan(b, s)
        finally:
            st['seconds'] += time.perf_counter() - t0

    planner.stats = st
    planner.values = values
    planner.effect = effect
    planner.threat = threat
    planner.caches = (eff_cache, thr_cache)
    return planner
