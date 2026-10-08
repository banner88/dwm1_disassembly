#!/usr/bin/env python3
"""S130 F9 differential validator — combatant-changing and meta skills.

Replays the F9 corpus (simulator/f9_events.json.gz, captured by
simulator/measure_f9.py on the user's save) through simulator/skillfx/
f9_meta.py and the round core, with the ENGINE's RNG injected at each
waypoint (the S85 method: an oracle `idle` hands the model the engine state
at the next matching waypoint — KEY_LESSONS S85), from the engine's own
pre-action board, and diffs:

  summon_*     TatsuCall family: outcome (done / used / fail), the helper
               slot after summon_done (stats, level, $DD0B, $DB8B, WLD, AI
               bases, $DC64, $DD28, status, $DD1B, $DD13, $DC3C, side bit2)
  chance_*     the $4D7E picker: number of rolls, accepted id (boss /
               caster-side re-rolls), the outcome's target (bank $58 row)
  rewrite      BeDragon/CHGDRAGON TransformActionRewrite: queue skill and
               target at the re-run's skill_load
  driver       the whole F9 action through battle.ACTION_HANDLERS (the
               outcome of Chance through its own family handler) vs the
               engine's board at the next actor fetch / phase 9 / round
               start: HP, MP, MaxHP, MaxMP, ATK, DEF, AGL, INT, level,
               $DD1B, $DD13, the 64-byte status area, res, $DC64 options
  target       act-time target of the F9 skill (rows: self / Transform
               argmax / uniform) vs $DB89 at the first target fetch
  ko_revert    a KO'd transformed / dragon slot reloaded from its source
  order        $DB79 vs battle.round_order in rounds with a live helper
  victims      group sweeps (target mode 18) and the quake sweep reaching
               a live helper (battle.side_victims / quake_victims)
  p9_order     phase-9 slot walk incl. helpers
  rearm        a summoned helper is in the NEXT round's order
  helper_ai    a helper's decision: category cells (bases $FA, mod 10,
               no plan adjust), ranking, sums residuals, tag filter, pick
  side_wipe    a side whose slots 0-2 are down ends the battle even with
               its helper alive (BattleFunc_76c8 scans 3 slots)
  never_single no single-target pick ever lands on a helper slot

Usage: python3 simulator/validate_f9.py [simulator/f9_events.json.gz] [-v]
"""
import copy
import gzip
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import battle as B
from simulator import ai as A
from simulator.skillfx import f9_meta as F
from simulator.validate_battle import split_battles, split_rounds, group_actions, st16

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECORDS = {r['id']: r for r in json.load(open(os.path.join(ROOT, 'extracted', 'skill_records.json')))['records']}
VERBOSE = '-v' in sys.argv
stats, fails = {}, []

F9_ACT = set(F.SUMMONS) | {F.CHANCE, F.TRANSFORM, F.RUN, F.BEDRAGON, F.CHGDRAGON,
                           F.CALLHOROR, F.SMASHED}
SPECIAL_VICTIMS = {0x57, 0x50, 0x51, 0x52, 0x53, 0xA7, 0xA8, 0xAF, 0xA2, 0xA4, 0x40}
BOUNDARY = ('actor_fetch', 'p9_slot', 'round_start', 'side_wipe', 'round_end')
INV5 = 52429
OUTCOMES, SKIPPED = {}, {}
FORCED_HELPER = {'p_helper_tf': 0x29}
LAST = {}                                  # battle -> its last captured event     # battles whose helper queue the rig forced
NO_EFFECT = set()


def tally(kind, ok, detail=None):
    s = stats.setdefault(kind, [0, 0])
    s[0 if ok else 1] += 1
    if not ok:
        fails.append((kind, detail))
        if VERBOSE:
            print('FAIL', kind, detail)


def fields(sk):
    r = RECORDS.get(sk)
    return r['battle_record']['fields'] if r else {}


def unstep(state):
    return ((state - 0x1357) * INV5) & 0xFFFF


def pairs(row):
    out = []
    for i in range(0, 16, 2):
        if row[i + 1] == 0xFF:
            break
        out.append((row[i], row[i + 1]))
    return out


# --------------------------------------------------------------------------
# boards
# --------------------------------------------------------------------------
class Battle:
    """Per-battle context: the source stats (battle_init = the unpoked
    record / enemy row values bank $57 reads), source skill lists and res."""

    def __init__(self, evs):
        self.init = next((e for e in evs if e['tag'] == 'battle_init'), evs[0])
        first = self.init
        self.src_skills = {}
        for s in range(7):
            if s == 3:
                continue
            self.src_skills[s] = [sk for _t, sk in pairs(first['dc64'][s * 16:s * 16 + 16])]
        self.src_res = {s: list(first['res'][s * 7:s * 7 + 7]) for s in range(8)}
        self.src_level = list(first['db9b'])

    def board(self, e):
        b = B.Board.from_event(e)
        b.level = list(e['db9b'])
        b.species = list(e['dc3c'])
        i = self.init
        for k, src in (('maxhp', 'maxhp'), ('maxmp', 'maxmp'), ('atk', 'atk'), ('dfn', 'dfn'),
                       ('agl', 'agl'), ('int', 'int')):
            b.base[k] = list(i[src])
        b.ext['f9_src_skills'] = {s: list(v) for s, v in self.src_skills.items()}
        b.ext['f7_db40'] = e['db40'][0] if 'db40' in e else 0
        for s in (3, 7):
            sp = e['dc3c'][s]
            if e['dd1b'][s] != 0xFF and 216 <= sp <= 219:
                sk = sp - 0x54
                b.ext.setdefault('f9_helper', {})[s] = sk
                b.ext.setdefault('f9_ai_bases', {})[s] = F.HELPER_AI_BASES
                hb = F.helper_source(sk)[0]
                for k in F.STATS:
                    b.base[k][s] = hb[k]
                b.ext.setdefault('f9_opts', {})[s] = pairs(e['dc64'][s * 16:s * 16 + 16])
        for s in range(8):
            if s in (3, 7):
                continue
            if e['st'][s * 8 + 3] & 0x30:
                b.ext.setdefault('f9_opts', {})[s] = pairs(e['dc64'][s * 16:s * 16 + 16])
                b.ext.setdefault('f9_src_res', {})[s] = list(self.src_res[s])
                b.ext.setdefault('f9_src_level', {})[s] = self.src_level[s]
        return b


def opts_view(b, s, e):
    """Model option list vs the engine's $DC64 row (pairs)."""
    m = F.opts_of(b, s)
    if m is None:
        return None
    return list(m)


def board_cmp(b, e, where, kind, after_p9=False, slots=range(8)):
    m = copy.deepcopy(b)
    if after_p9:
        B.phase9_decay(m)
    ok = True
    diffs = {}
    for k, ek in (('hp', 'hp'), ('mp', 'mp'), ('maxhp', 'maxhp'), ('maxmp', 'maxmp'), ('atk', 'atk'),
                  ('dfn', 'dfn'), ('agl', 'agl'), ('int', 'int'), ('level', 'db9b'),
                  ('dd1b', 'dd1b'), ('dd13', 'dd13')):
        mv = [getattr(m, k)[s] for s in slots]
        ev = [e[ek][s] for s in slots]
        if mv != ev:
            ok = False
            diffs[k] = (mv, ev)
    if m.st != list(e['st']):
        ok = False
        diffs['st'] = (m.st, e['st'])
    for s in slots:
        if m.res[s * 7:s * 7 + 7] != e['res'][s * 7:s * 7 + 7]:
            ok = False
            diffs['res%d' % s] = (m.res[s * 7:s * 7 + 7], e['res'][s * 7:s * 7 + 7])
        mo = opts_view(m, s, e)
        if mo is not None and mo != pairs(e['dc64'][s * 16:s * 16 + 16]):
            ok = False
            diffs['opts%d' % s] = (mo, pairs(e['dc64'][s * 16:s * 16 + 16]))
    tally(kind, ok, dict(w=where, diffs=diffs))
    return ok


# --------------------------------------------------------------------------
# the oracle idle
# --------------------------------------------------------------------------
class Oracle:
    """idle(state, cls) -> the engine's state at the next matching waypoint
    of the action (pre_miss -> miss_in; pre_target -> the next chance_roll /
    tf_rewrite / target_fetch; F8 classes as validate_f8_multihit)."""
    MAP = {'pre_miss': ('miss_in',),
           'pre_target': ('chance_roll', 'tf_rewrite', 'target_fetch'),
           'mh_post_hit': ('mh_cont',), 'mh_pre_snap': ('snap_roll',),
           'mh_refetch': ('target_fetch',), 'mh_call_msg': ('target_fetch',)}

    def __init__(self, evs):
        self.evs, self.i = evs, 0
        self.calls = []

    def __call__(self, state, cls):
        self.calls.append(cls)
        tags = self.MAP.get(cls)
        if not tags:
            return state
        for j in range(self.i, len(self.evs)):
            if self.evs[j]['tag'] in tags:
                self.i = j + 1
                return st16(self.evs[j])
        return state


# --------------------------------------------------------------------------
# per-action replays
# --------------------------------------------------------------------------
def act_target(b, a, sk, qt, f, g):
    """simulate_round's act-time target for the F9 skill; RNG-dependent
    picks take the engine's state at the 'repick' waypoint when present.
    Returns (pred, deterministic)."""
    if sk in B.TARGET_RESOLVERS:
        t, _ = B.TARGET_RESOLVERS[sk](b, a, sk, qt, f, 0)
        return t, True
    if qt != 0xFF and b.valid(qt):
        if not B.reresolves(b, a, sk):
            return qt, True
        if sk in B.RERESOLVE_PICKERS:
            rp = next((e for e in g if e['tag'] == 'repick'), None)
            if b.dd0b[a] == 0:
                if rp is None:
                    return None, False
                t, _ = B.uniform_side_pick(b, (a & 4) ^ 4, st16(rp))
                return t, True
            t, _ = B.RERESOLVE_PICKERS[sk](b, a, 0)
            return t, True
        return None, False
    if qt == 0xFF and sk in B.RERESOLVE_PICKERS and b.dd0b[a] != 0:
        t, _ = B.RERESOLVE_PICKERS[sk](b, a, 0)
        return t, True
    if (f.get('target_mode', 0) & 1) and b.dd0b[a] == 0:
        return None, True
    return B.dead_redirect(b, qt), True


def after_event(evs, j):
    for k in range(j, len(evs)):
        if evs[k]['tag'] in BOUNDARY:
            return evs[k]
    return None


def validate_action(bt, evs, i, j, where):
    """evs[i] = skill_load of actor a; evs[i:j] its action events."""
    g = evs[i:j]
    sl = g[0]
    a = sl['db88']
    b = bt.board(sl)
    sk = b.q_skill(a)
    qt = b.q_target(a)
    tags = [e['tag'] for e in g]
    if 'conf_pick' in tags or sk not in F9_ACT:
        return
    if g[-1] is LAST.get(sl['sc']) and g[-1]['tag'] not in ('apply_in', 'run_tail', 'mh_cont'):
        return                      # the capture stopped (--maxev) inside this action
    tf0 = next((e for e in g if e['tag'] == 'target_fetch'), None)
    if tf0 is not None and tf0['dcec'][a * 2] != sk:
        return                  # a $DD0B==2 act-time re-decide replaced the queue (F5 open item)
    f = fields(sk)
    veto = B.act_mp_veto(b, a, sk, f.get('mp_cost_byte', 0), f.get('flags7', 0))
    acted = 'target_fetch' in tags
    tally('veto', (veto is None) == acted, dict(w=where, a=a, sk=hex(sk), veto=veto))
    if veto is not None or not acted:
        return
    B.act_mp_spend(b, a, sk, f.get('mp_cost_byte', 0), f.get('flags7', 0))
    tf = g[tags.index('target_fetch')]
    tally('mp_spend', b.mp[a] == tf['mp'][a], dict(w=where, a=a, sk=hex(sk), pred=b.mp[a], got=tf['mp'][a]))
    b.mp[a] = tf['mp'][a]
    pt, det = act_target(b, a, sk, qt, f, g)
    mi = next((e for e in g if e['tag'] == 'miss_in'), None)
    t = mi['db89'] if mi is not None else tf['dcec'][a * 2 + 1]
    if det:
        tally('target', pt == t, dict(w=where, a=a, sk=hex(sk), qt=qt, pred=pt, got=t))
    after = after_event(evs, j)
    # ---- specific waypoint checks --------------------------------------
    if sk in F.SUMMONS:
        check_summon(b, a, sk, g, where)
    if sk == F.CHANCE:
        check_chance(b, a, g, where)
    # ---- the driver ----------------------------------------------------
    if sk == F.CHANCE:
        pk = next((e for e in g if e['tag'] == 'chance_pick'), None)
        if pk is not None:
            OUTCOMES[pk['db8a']] = OUTCOMES.get(pk['db8a'], 0) + 1
            if pk['db8a'] not in B.ACTION_HANDLERS and pk['db8a'] not in NO_EFFECT:
                SKIPPED[pk['db8a']] = SKIPPED.get(pk['db8a'], 0) + 1
                return              # outcome owned by an unmerged family (F10 FILTHZONE)
    oracle = Oracle(g + ([after] if after else []))
    log = []
    ctx = B.ActionCtx(b=b, a=a, sk=sk, rec=RECORDS.get(sk), f=f, core=B.damage_core(sk, RECORDS.get(sk)),
                      t=t, qt=qt, state=st16(tf), records=RECORDS, log=log, idle=oracle, real_sk=sk)
    B.ACTION_HANDLERS[sk](ctx)
    rerun = b.ext.pop('f9_rerun', None)
    b.dd13[a] = 2 if rerun == a else 3
    if 'tf_rewrite' in tags:
        check_rewrite(b, a, evs, j, where)
    if after is None and g[-1]['tag'] in ('apply_in', 'run_tail', 'mh_cont'):
        # the action ended the battle (every enemy removed): the last
        # waypoint of the action carries the final HP / $DD1B
        last = g[-1]
        tally('driver_end', b.hp == list(last['hp']) and b.dd1b == list(last['dd1b']),
              dict(w=where, a=a, sk=hex(sk), log=log, pred=(b.hp, b.dd1b), got=(last['hp'], last['dd1b'])))
    if after is not None:
        if after['tag'] == 'round_start' and after['sc'] == sl['sc']:
            for s in range(8):
                if b.dd13[s] == 3:
                    b.dd13[s] = 2
                if b.dd1b[s] == 0 and b.dd13[s] == 0xFF:
                    b.dd13[s] = 2
            B.phase9_decay(b)
            # end-of-round DoT etc. would not be modelled here: compare the
            # deterministic fields only
            tally('driver_r', b.hp == list(after['hp']) and b.dd1b == list(after['dd1b']),
                  dict(w=where, a=a, sk=hex(sk), log=log, pred=(b.hp, b.dd1b), got=(after['hp'], after['dd1b'])))
            return
        board_cmp(b, after, where + ' a%d %s' % (a, hex(sk)), 'driver', after_p9=after['tag'] == 'p9_slot')
    if sk in (F.SMASHED, F.CALLHOROR):
        got = [e['db88'] for e in g if e['tag'] in ('meta_run',)]
        pred = [x for x in log if x[1] == 'removed']
        tally('removed', bool(pred) and pred[0][2] == got, dict(w=where, a=a, pred=pred, got=got))


def check_summon(b, a, sk, g, where):
    tags = [e['tag'] for e in g]
    hs = next((e for e in g if e['tag'] == 'h_summon'), None)
    if hs is None:
        tally('summon_reached', False, dict(w=where, tags=tags))
        return
    m = copy.deepcopy(b)
    m.hp = list(hs['hp']); m.st = list(hs['st'])
    out, s, _ = F.summon(m, a, sk, st16(hs))
    got = ('done' if 'summon_done' in tags else 'used' if 'summon_used' in tags
           else 'fail' if 'summon_fail' in tags else None)
    tally('summon_outcome', out == got, dict(w=where, a=a, pred=out, got=got, rng=hex(st16(hs))))
    if out == 'done' and got == 'done':
        e = g[tags.index('summon_done')]
        ok = True
        bad = {}
        for k, ek in (('hp', 'hp'), ('maxhp', 'maxhp'), ('mp', 'mp'), ('maxmp', 'maxmp'), ('atk', 'atk'),
                      ('dfn', 'dfn'), ('agl', 'agl'), ('int', 'int'), ('level', 'db9b'), ('dd0b', 'dd0b'),
                      ('db8b', 'db8b'), ('dd1b', 'dd1b'), ('dd13', 'dd13')):
            if getattr(m, k)[s] != e[ek][s]:
                ok = False; bad[k] = (getattr(m, k)[s], e[ek][s])
        if m.res[s * 7:s * 7 + 7] != e['res'][s * 7:s * 7 + 7]:
            ok = False; bad['res'] = (m.res[s * 7:s * 7 + 7], e['res'][s * 7:s * 7 + 7])
        if m.st != list(e['st']):
            ok = False; bad['st'] = 1
        if pairs(e['dc64'][s * 16:s * 16 + 16]) != F.HELPERS[sk]['opts']:
            ok = False; bad['opts'] = pairs(e['dc64'][s * 16:s * 16 + 16])
        if e['dc3c'][s] != F.HELPERS[sk]['species']:
            ok = False; bad['dc3c'] = e['dc3c'][s]
        if e['wld'][s] != 0xFF or [e['ai_bases'][s + 8 * k] for k in range(4)] != list(F.HELPER_AI_BASES):
            ok = False; bad['wld/ai'] = (e['wld'][s], [e['ai_bases'][s + 8 * k] for k in range(4)])
        tally('summon_slot', ok, dict(w=where, a=a, s=s, sk=hex(sk), bad=bad))


def check_chance(b, a, g, where):
    tags = [e['tag'] for e in g]
    if 'h_chance' not in tags:
        tally('chance_reached', False, dict(w=where, tags=tags))
        return
    rolls = [e for e in g if e['tag'] == 'chance_roll']
    pk = next((e for e in g if e['tag'] == 'chance_pick'), None)
    if not rolls or pk is None:
        tally('chance_reached', False, dict(w=where, tags=tags))
        return
    m = copy.deepcopy(b)
    m.db73 = rolls[0]['db73']
    mid, n, _ = F.chance_pick(m, a, st16(rolls[0]), RECORDS)
    tally('chance_pick', (mid, n) == (pk['db8a'], len(rolls)),
          dict(w=where, a=a, pred=(hex(mid), n), got=(hex(pk['db8a']), len(rolls)), db73=m.db73))
    # every individual roll is one LoadBtlC_4e33 step from the previous
    for r0, r1 in zip(rolls, rolls[1:]):
        tally('chance_step', B.rng_step(st16(r0)) == st16(r1), dict(w=where))
    k = tags.index('chance_pick')
    tf2 = next((e for e in g[k:] if e['tag'] == 'target_fetch'), None)
    if tf2 is not None:
        m2 = copy.deepcopy(b)
        m2.hp = list(tf2['hp']); m2.dd1b = list(tf2['dd1b'])
        t = F.chance_target(m2, a, pk['db8a'])
        got = tf2['dcec'][a * 2 + 1]
        tally('chance_target', t == got, dict(w=where, a=a, mid=hex(pk['db8a']), pred=t, got=got))


def check_rewrite(b, a, evs, j, where):
    """The re-run's actor fetch carries the rewritten queue (before any
    duplicate-cast conversion of the re-run)."""
    for k in range(j, len(evs)):
        if evs[k]['tag'] == 'actor_fetch' and evs[k]['A'] == a:
            q = evs[k]['dcec'][a * 2:a * 2 + 2]
            tally('rewrite', [b.queue[a * 2], b.queue[a * 2 + 1]] == q,
                  dict(w=where, a=a, pred=b.queue[a * 2:a * 2 + 2], got=q))
            return
        if evs[k]['tag'] in ('round_start', 'p9_slot'):
            break
    tally('rewrite_rerun', False, dict(w=where, a=a))


# --------------------------------------------------------------------------
# round-level checks
# --------------------------------------------------------------------------
def helper_live(e, base=None):
    return [s for s in (3, 7) if e['dd1b'][s] == 0 and (base is None or s & 4 == base)]


def check_rounds(bt, sc, evs):
    rounds = split_rounds(evs)
    for rn, rev in enumerate(rounds):
        R = rev[0]
        where = f'{sc} r{rn}'
        actors, p9 = group_actions(rev)
        live_h = helper_live(R)
        b = bt.board(R)
        if actors and live_h:
            got = [x for x in actors[0][0]['db79'] if x != 0xFF]
            order, _ = B.round_order(b, st16(R), R['db71'], 0xFF)
            tally('order', order == got, dict(w=where, got=got, pred=order))
        # victims of sweeps that reach a live helper side
        for g in actors:
            vfs = [e for e in g if e['tag'] == 'target_fetch']
            if not vfs:
                continue
            sk = vfs[0]['db8a']
            a = g[0]['A']
            f = fields(sk)
            got_v = [e['db89'] for e in vfs]
            pre = next((e for e in g if e['tag'] == 'skill_load'), g[0])
            qt0 = pre['dcec'][a * 2 + 1] if a < 8 else 0xFF
            if (len(got_v) == 1 and f.get('target_mode') in (17, 33) and got_v[0] != qt0
                    and not (a in (3, 7) and got_v[0] == a)):
                # a PICKED single target (not the forced queue byte, not self)
                tally('never_single', got_v[0] not in (3, 7), dict(w=where, a=a, sk=hex(sk), t=got_v))
            if sk in SPECIAL_VICTIMS or 'conf_pick' in [e['tag'] for e in g]:
                continue
            side = vfs[0]['db89'] & 4
            if not helper_live(pre, side) and not (sk in B.QUAKE_RANGE and helper_live(pre)):
                continue
            bb = bt.board(vfs[0])
            if sk in B.QUAKE_RANGE:
                pred = [s for s, _ in B.quake_victims(bb, a, vfs[0]['db89'])]
                # victims KO'd mid-sweep are still visited (the walk precedes them)
                tally('victims_quake', pred == got_v, dict(w=where, a=a, sk=hex(sk), pred=pred, got=got_v))
            elif f.get('target_mode') == 18:
                bb2 = bt.board(pre)
                pred = B.side_victims(bb2, vfs[0]['db89'], vfs[0]['db89'])
                # the engine skips slots that died earlier in the same sweep
                # only when dead at their fetch: compare against live-at-fetch
                tally('victims', pred == got_v or [s for s in pred if s in got_v] == got_v and
                      all(vfs[k]['dd1b'][s] for k, s in enumerate(pred) if s not in got_v and k < len(vfs)),
                      dict(w=where, a=a, sk=hex(sk), pred=pred, got=got_v))
        # the actor walk with a form-change re-run (battle.actor_walk): the
        # engine's executed actors == $DB79 order with the dragon repeated
        if actors and any(e['tag'] == 'tf_rewrite' for g in actors for e in g):
            order = [x for x in actors[0][0]['db79'] if x != 0xFF]
            got, pred = [], []
            for g in actors:
                if any(e['tag'] == 'gates_in' for e in g):
                    got.append(g[0]['A'])
            bw = B.Board()
            reruns = [g[0]['A'] for g in actors if any(e['tag'] == 'tf_rewrite' for e in g)]
            for _c, x in B.actor_walk(bw, order):
                pred.append(x)
                if reruns and x == reruns[0]:
                    reruns.pop(0)
                    bw.ext['f9_rerun'] = x
            pred = [x for x in pred if x in got]
            tally('walk_rerun', got == pred[:len(got)], dict(w=where, got=got, pred=pred))
        # phase-9 walk includes live helpers
        slots = [e for e in p9 if e['tag'] == 'p9_slot']
        if slots and any(e['dd1b'][s] == 0 for e in slots[:1] for s in (3, 7)):
            first = slots[0]
            pred = [s for s in range(8) if first['dd1b'][s] == 0]
            got = [e['A'] for e in slots]
            tally('p9_order', got == pred[:len(got)], dict(w=where, got=got, pred=pred))
        # re-arm: a helper summoned this round is in the next round's order
        for g in actors:
            for e in g:
                if e['tag'] == 'summon_done' and rn + 1 < len(rounds):
                    s = e['db89']
                    nxt = rounds[rn + 1]
                    af = next((x for x in nxt if x['tag'] == 'actor_fetch'), None)
                    if af is None:
                        continue
                    tally('rearm', nxt[0]['dd13'][s] == 2 and s in af['db79'],
                          dict(w=where, s=s, dd13=nxt[0]['dd13'][s], db79=af['db79']))
        # side wipe with a live helper
        sw = next((e for e in rev if e['tag'] == 'side_wipe'), None)
        last = rev[-1]
        for base in (0, 4):
            if last['dd1b'][base | 3] == 0:
                bl = bt.board(last)
                if B.side_wiped(bl, base):
                    tally('side_wipe', sw is not None or rn == len(rounds) - 1,
                          dict(w=where, base=base, dd1b=last['dd1b']))


def check_ai(sc, evs):
    """Helper decisions (actor 3 / 7): ai_cat .. ai_post groups."""
    cur = None
    for e in evs:
        if e['tag'] == 'ai_cat' and e['db88'] in (3, 7):
            if cur is None or cur['a'] != e['db88']:
                cur = dict(a=e['db88'], cats=[])
            cur['cats'].append(e)
        elif e['tag'] == 'ai_post' and cur is not None and e['db88'] == cur['a']:
            check_decision(sc, cur, e)
            cur = None
        elif e['tag'] in ('round_start',):
            cur = None


def check_decision(sc, cur, post):
    a = cur['a']
    cat = cur['cats'][0]
    where = f'{sc} ai a{a}'
    bases = [cat['ai_bases'][a], cat['ai_bases'][8 + a], cat['ai_bases'][16 + a]]
    tally('helper_bases', bases == [250, 250, 250] and cat['ai_bases'][24 + a] == 250,
          dict(w=where, bases=bases))
    cells = cat['dcfc'][:3]
    ids = cat['dcfc'][3:6]
    raw = list(cells)
    if ids[0] != 1:
        raw[0] = (raw[0] - 0x1E) & 0xFF
    # $57:$7206 seal/status bump (+$1E on cat1) — the helper's +3/+5 state
    bump = bool(cat['st'][a * 8 + 3] & 0x0C) or bool(cat['st'][a * 8 + 6] & 0x33)   # $57:$7206: +3 &$0C, +6 &$33
    if bump:
        raw[0] = (raw[0] - 0x1E) & 0xFF
    ok = all(0 <= raw[c] - bases[c] // 10 < A.cat_mod(bases[c], True) for c in range(3))
    tally('helper_cells', ok, dict(w=where, cells=cells, raw=raw))
    rc, ri = A.rank_categories([(raw[0] + (0x1E if bump else 0)) & 0xFF, raw[1], raw[2]])
    tally('helper_rank', ri == ids, dict(w=where, pred=ri, got=ids))
    opts = pairs(cat['dc64'][a * 16:a * 16 + 16])
    sk = post['dcec'][a * 2]
    if FORCED_HELPER.get(sc) == sk:
        return                      # the rig wrote this helper's queue (--sched ...:3)
    okp = sk in [s for _t, s in opts] or sk in (A.PLAIN_ATTACK, A.DEFENCE)
    tally('helper_pick', okp, dict(w=where, sk=hex(sk), opts=opts))
    if sk in [s for _t, s in opts]:
        tag = dict((s, t) for t, s in opts)[sk]
        tally('helper_tag', tag in ids, dict(w=where, sk=hex(sk), tag=tag, ids=ids))


def check_ko_revert(bt, sc, evs):
    for i, e in enumerate(evs):
        if e['tag'] != 'tf_revert_ko':
            continue
        t = e['db89']
        ap = next((x for x in reversed(evs[:i]) if x['tag'] == 'apply_in' and x['db89'] == t), None)
        if ap is None:
            continue
        b = bt.board(ap)
        if not (b.stb(t, 3) & 0x30):
            tally('ko_revert_flag', False, dict(w=sc, t=t))
            continue
        B.apply_damage(b, t, max(ap['db56'], b.hp[t]))
        bad = {}
        for k, ek in (('maxhp', 'maxhp'), ('maxmp', 'maxmp'), ('atk', 'atk'), ('dfn', 'dfn'),
                      ('agl', 'agl'), ('int', 'int'), ('level', 'db9b'), ('mp', 'mp')):
            if getattr(b, k)[t] != e[ek][t]:
                bad[k] = (getattr(b, k)[t], e[ek][t])
        if b.res[t * 7:t * 7 + 7] != e['res'][t * 7:t * 7 + 7]:
            bad['res'] = (b.res[t * 7:t * 7 + 7], e['res'][t * 7:t * 7 + 7])
        mo = F.opts_of(b, t)
        eo = pairs(e['dc64'][t * 16:t * 16 + 16])
        so = F.skills_to_opts(F.source_skills(b, t), RECORDS)
        if (mo if mo is not None else so) != eo:
            bad['opts'] = (mo, so, eo)
        tally('ko_revert', not bad, dict(w=sc, t=t, bad=bad))


def run(events):
    for sc, evs in split_battles(events).items():
        LAST[sc] = evs[-1]
        bt = Battle(evs)
        check_rounds(bt, sc, evs)
        check_ai(sc, evs)
        check_ko_revert(bt, sc, evs)
        rounds = split_rounds(evs)
        for rn, rev in enumerate(rounds):
            off = evs.index(rev[0])
            for k, e in enumerate(rev):
                if e['tag'] != 'skill_load':
                    continue
                i = off + k
                j = i + 1
                while j < len(evs) and evs[j]['tag'] not in BOUNDARY:
                    j += 1
                validate_action(bt, evs, i, j, f'{sc} r{rn}')


def load(path):
    if path.endswith('.gz'):
        return json.load(gzip.open(path, 'rt'))
    return json.load(open(path))


if __name__ == '__main__':
    path = next((x for x in sys.argv[1:] if not x.startswith('-')),
                os.path.join(ROOT, 'simulator', 'f9_events.json.gz'))
    run(load(path))
    total = sum(v[0] + v[1] for v in stats.values())
    bad = sum(v[1] for v in stats.values())
    for k, (ok, no) in sorted(stats.items()):
        print(f'{k:18s} ok={ok:5d} fail={no}')
    print('Chance outcomes replayed:', {hex(k): v for k, v in sorted(OUTCOMES.items())})
    if SKIPPED:
        print('  driver not compared (no handler registered):', {hex(k): v for k, v in SKIPPED.items()})
    print(f'TOTAL {total} comparisons, {bad} mismatches')
    if not VERBOSE:
        for x in fails[:30]:
            print('  ', x)
    sys.exit(1 if bad else 0)
