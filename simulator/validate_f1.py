#!/usr/bin/env python3
"""S130 F1 validator — status appliers and one-shot compulsions
(simulator/skillfx/f1_status.py) over simulator/f1_status_events.json.gz
(captured by simulator/measure_f1.py on the user's real save).

A COPY of the S85 loop-level validator (validate_battle.py, kept intact
below so every actor / gate / MISS / damage / decay / DoT / round-board
check still runs on the F1 battles) extended with:
  f1_victims  the F1 victim walk (side sweep from the queued target,
              BIGSLEEP's $714C 8-step walk, single target) vs the engine's
              target_fetch sequence;
  f1_helper   which hit helper the handler entered (none for 'already' /
              dead / no-roll skills, $65FF only for a flyer, the boss-gated
              helper entry with no roll) — proves the no-roll paths;
  f1_outcome  the victim's status block after the handler (apply_in when
              the engine reached it, else the next waypoint) vs
              f1_status.apply_victim() fed the MISS machine's post-step RNG
              (the helper runs in the same frame — the S85 waypoint
              injection); Beat-class also HP/$DD1B, SickLick DEF + the
              $DB08+8t marker, Ironize the whole side's +7, SideStep the
              caster's +7;
  rpoke       the measurement's round-start pokes (recorded in round_start
              events) are applied to the model board before the next
              round's board comparison.
The one-shot CONSUMERS are the copied gate checks (status_forced_action vs
the engine's forced code at $53:$462C) and the next-round board check.

Usage: python3 simulator/validate_f1.py [simulator/f1_status_events.json.gz] [-v] [-c coverage]

--- original S85 docstring ---
Loop-level differential validator for simulator/battle.py (S85).

Replays each battle captured by simulator/measure_battle.py — round by
round, actor by actor, victim by victim — through the round-core model,
injecting the engine's RNG at each waypoint (the live RNG is idle-stepped
between frames, so a seed-to-end replay is impossible; see KEY_LESSONS S85)
and diffing the model's prediction against what the engine did next:

  order     $DB79 vs round_order() from the RNG at $54D1 entry
  fetch     the actor sequence (invalid / not-ready entries skipped)
  gate      forced action code (sleep/paralysis/stun/one-shots) or none
  dupconv   the enemy duplicate-group-cast -> $3A conversion
  veto      act-time MP/seal veto -> the turn produces no act events
  target    $DB89 at the MISS machine (queue byte / re-resolve /
            dead-redirect; multi-candidate RNG picks = engine's choice)
  miss      block/miss/dodge/pass from the RNG after the machine's step
  core      the damage core the engine entered (calcdef/record/quake)
  damage    $DB56 at apply vs damage.* from the core-entry RNG (+ ladder)
  hp        HP after apply (next event) vs floor-0 subtraction
  ko        KO -> $DD1B=1 / $DD13=$FF
  victims   group-cast victim sequence (side / quake sweep)
  decay     the 64-byte status block after phase-9 sub 0
  dot       DoT amount + HP, KO
  wipe      side wipe -> battle end

Usage: python3 simulator/validate_battle.py <events.json> [-v]
Exit 1 on any mismatch.
"""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import battle as B
from simulator import damage as D
from simulator.validate_damage import SPELL_LADDER
from simulator.skillfx import f1_status as F1

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECORDS = {r['id']: r for r in json.load(open(os.path.join(ROOT, 'extracted', 'skill_records.json')))['records']}
DUP = json.load(open(os.path.join(ROOT, 'extracted', 'enemy_dupconv_flags.json')))
# custom skills (patched ROM records, bank $54 patches): flags7/flags8/mp
# custom skills (patched ROM records, patches/bank_054.asm): +4 mp, +7 flags7, +8 flags8
CUSTOM = {0xE4: dict(mp=0, f7=0x41, f8=0x07), 0xE5: dict(mp=5, f7=0x01, f8=0x06),
          0xE6: dict(mp=10, f7=0x01, f8=0x06), 0xE7: dict(mp=16, f7=0x01, f8=0x06),
          0xE8: dict(mp=24, f7=0x01, f8=0x06), 0xE9: dict(mp=10, f7=0x41, f8=0x07)}

VERBOSE = '-v' in sys.argv
stats = {}
fails = []


def tally(kind, ok, detail=None):
    s = stats.setdefault(kind, [0, 0])
    s[0 if ok else 1] += 1
    if not ok:
        fails.append((kind, detail))
        if VERBOSE:
            print('FAIL', kind, detail)


def st16(e):
    return (e['rng1'] << 8) | e['rng2']


def mp_cost(skill):
    if skill in CUSTOM:
        return CUSTOM[skill]['mp']
    r = RECORDS.get(skill)
    return r['battle_record']['fields']['mp_cost_byte'] if r else 0


def split_battles(events):
    out = {}
    for e in events:
        out.setdefault(e['sc'], []).append(e)
    return out


def split_rounds(evs):
    rounds, cur = [], None
    for e in evs:
        if e['tag'] == 'round_start':
            if cur:
                rounds.append(cur)
            cur = [e]
        elif cur is not None:
            cur.append(e)
    if cur:
        rounds.append(cur)
    return rounds


def group_actions(rev):
    """Split a round's events (after round_start) into per-actor groups
    keyed at actor_fetch, and the trailing phase-9 group."""
    actors, p9, cur = [], [], None
    for e in rev[1:]:
        t = e['tag']
        if e.get('d9ec') == 5:
            continue        # F1: the NEXT round's AI evaluation (CalcSkillDefense calls in phase 5)
        if t == 'actor_fetch':
            cur = [e]; actors.append(cur)
        elif t in ('p9_slot', 'p9_dot_apply', 'p9_dot_ko', 'side_wipe', 'round_end'):
            p9.append(e)
        elif cur is not None:
            cur.append(e)
    return actors, p9


def victim_groups(acts):
    """Inside one actor's events: per-victim groups start at target_fetch."""
    groups, cur = [], None
    for e in acts:
        if e['tag'] == 'target_fetch':
            cur = [e]; groups.append(cur)
        elif cur is not None:
            cur.append(e)
    return groups


def next_hp(evs, i, slot):
    """HP of `slot` at the next event after index i (post-apply state)."""
    for e in evs[i + 1:]:
        return e['hp'][slot]
    return None


def check_snap(b, a, vg, evs, sc, where, f9):
    """Replay an on-hit snap-out roll ($53:$5F15, S88) when the corpus
    carries the snap_roll waypoint. Mutates the board on a snap."""
    se = next((e for e in vg if e['tag'] == 'snap_roll'), None)
    if se is None:
        return
    t = se['db89']
    rolled, snapped, _ = B.snap_out(b, t, f9, st16(se))
    tally('snap_gate', rolled, dict(w=where, a=a, t=t, f9=f9, st=se['st'][t*8+2]))
    idx = evs.index(se)
    nxt = evs[idx + 1] if idx + 1 < len(evs) and evs[idx + 1]['sc'] == sc else None
    if nxt is not None:
        got_clear = not (nxt['st'][t*8+2] & 0x90)
        tally('snap_roll', snapped == got_clear,
              dict(w=where, a=a, t=t, rng=(se['rng1'], se['rng2']), pred=snapped, got=got_clear))
        tally('snap_byte', nxt['st'][t*8+2] == b.stb(t, 2),
              dict(w=where, a=a, t=t, got=nxt['st'][t*8+2], pred=b.stb(t, 2)))


def validate_conf(b, a, g, evs, sc, where):
    """Model-driven confusion-turn validation (S88): pick, target, whiff,
    damage, snap-out. Requires the conf_pick waypoint in the group."""
    tags = [e['tag'] for e in g]
    cp = g[tags.index('conf_pick')]
    b.db73 = cp['db73']; b.link = bool(cp['c86c'])
    mid, s_after = B.confusion_pick(b, a, st16(cp))
    tf = next((e for e in g if e['tag'] == 'target_fetch'), None)
    got_mid = tf['dcec'][a*2] if tf else None
    tally('conf_pick', got_mid is None or mid == got_mid,
          dict(w=where, a=a, pred=hex(mid), got=None if got_mid is None else hex(got_mid),
               rng=(cp['rng1'], cp['rng2'])))
    if got_mid is not None and got_mid != mid:
        mid = got_mid                       # keep walking with the engine's pick
    if mid == B.CONF_HITALLY:
        pt, s_after = B.uniform_side_pick(b, a & 4, s_after)
    elif mid in (B.CONF_HITENEMY, B.CONF_TRIP):
        pt, s_after = B.uniform_side_pick(b, (a & 4) ^ 4, s_after)
    else:
        pt = a
    if tf is not None:
        tally('conf_target', pt == tf['dcec'][a*2+1],
              dict(w=where, a=a, mid=hex(mid), pred=pt, got=tf['dcec'][a*2+1]))
    if mid == B.CONF_RUN:
        tally('conf_act', 'meta_run' in tags, dict(w=where, a=a, tags=tags))
        b.dd1b[a] = 0xFF; b.dd13[a] = 0xFF
        return
    if mid in (B.CONF_SCARED, B.CONF_DANCE):
        tally('conf_act', 'meta_msg' in tags, dict(w=where, a=a, tags=tags))
        return
    if mid == B.CONF_TRIP:
        tally('conf_act', 'meta_trip' in tags, dict(w=where, a=a, tags=tags))
        b.set_stb(a, 5, b.stb(a, 5) | 0x04)
        return
    if mid in (B.CONF_PARA, B.CONF_CANTMOVE):
        tally('conf_act', 'meta_selfpara' in tags, dict(w=where, a=a, tags=tags))
        b.set_stb(a, 2, b.stb(a, 2) | 0x40)
        return
    # $99/$9A/$9B: physical
    want_tag = {B.CONF_HITALLY: 'meta_hitally', B.CONF_HITENEMY: 'meta_hitenemy',
                B.CONF_HITRANDOM: 'meta_hitrandom'}[mid]
    _pre = any(x in tags for x in ('miss', 'dodge', 'block'))   # F1: MISS machine first
    tally('conf_act', want_tag in tags or _pre, dict(w=where, a=a, mid=hex(mid), tags=tags))
    t = tf['dcec'][a*2+1] if tf else pt
    mr = next((e for e in g if e['tag'] == 'miss_rng'), None)
    fld = (RECORDS.get(mid) or {}).get('battle_record', {}).get('fields', {})
    if mr:
        pm = B.miss_gate(b, a, t, fld.get('flags7', 0), fld.get('flags8', 0), st16(mr))
        outcome = next((x for x in tags if x in ('miss', 'dodge', 'block')), 'pass')
        tally('miss', pm == outcome, dict(w=where, a=a, t=t, sk=hex(mid), pred=pm, got=outcome))
        if outcome != 'pass':
            return
    cd = next((e for e in g if e['tag'] == 'calcdef_in'), None)
    if mid in (B.CONF_HITALLY, B.CONF_HITENEMY):
        me = next((e for e in g if e['tag'] == want_tag), None)
        s2 = B.rng_step(st16(me))
        thr = 0x40 if mid == B.CONF_HITALLY else 0xC0
        pred_hit = B.rng1(s2) >= thr
        tally('conf_whiff', pred_hit == (cd is not None),
              dict(w=where, a=a, mid=hex(mid), r1=B.rng1(s2), pred=pred_hit, got=cd is not None))
        if cd is None:
            return
    if cd is None:
        return
    ap = next((e for e in g if e['tag'] == 'apply_in'), None)
    pd, _ = D.calc_skill_defense(b.atk[a], b.dfn[t], st16(cd), target_idx=t,
                                 arena=b.link, attacker_idx=a)
    dmg = ap['db56'] if ap else pd
    tally('conf_dmg', pd == dmg, dict(w=where, a=a, t=t, mid=hex(mid), pred=pd, got=dmg))
    ko = B.apply_damage(b, t, dmg)
    if ap:
        idx = evs.index(ap)
        j = idx + 1
        while j < len(evs) and evs[j]['tag'] == 'ko':
            j += 1
        if j < len(evs) and evs[j]['sc'] == sc:
            tally('hp', evs[j]['hp'][t] == b.hp[t],
                  dict(w=where, a=a, t=t, dmg=dmg, got=evs[j]['hp'][t], pred=b.hp[t]))
    got_ko = 'ko' in tags
    tally('ko', ko == got_ko, dict(w=where, a=a, t=t, dmg=dmg, pred=ko))
    if not ko:
        check_snap(b, a, g, evs, sc, where, fld.get('flags9', 0))


COVER = {}     # (skill, caster side, res level, +5 row bits, sure-hit, db73, outcome) -> n
HELPER_PCS = {0x5C51, 0x5C8F, 0x5CBC, 0x5CDA, 0x5D05, 0x5DCC, 0x65B5, 0x65C9,
              0x65D5, 0x65E3, 0x65FF, 0x6692, 0x669E}


def apply_rpoke(b, spec):
    """The measurement's round-start pokes (measure_f1.py --rpoke), applied
    to the model board at the round boundary: status area $DB00-$DB3F,
    $DB42-$DB49, $DB8B-$DB92 and the packed resistances $DD28-$DD5F."""
    for item in spec:
        for kv in item.split(','):
            for op in ('|=', '&=', '='):
                if op in kv:
                    k, v = kv.split(op); k = int(k, 0); v = int(v, 0)
                    break
            if 0xDB00 <= k < 0xDB40:
                arr, i = b.st, k - 0xDB00
            elif 0xDB42 <= k < 0xDB4A:
                arr, i = b.db42, k - 0xDB42
            elif 0xDB8B <= k < 0xDB93:
                arr, i = b.db8b, k - 0xDB8B
            elif 0xDD28 <= k < 0xDD60:
                arr, i = b.res, k - 0xDD28
            elif 0xDBA3 <= k < 0xDBB3:          # HP words (lo/hi)
                i = (k - 0xDBA3) >> 1
                w = b.hp[i]
                lo, hi = w & 0xFF, w >> 8
                if (k - 0xDBA3) & 1:
                    hi = (hi | v) if op == '|=' else (hi & v) if op == '&=' else v
                else:
                    lo = (lo | v) if op == '|=' else (lo & v) if op == '&=' else v
                b.hp[i] = lo | (hi << 8)
                continue
            else:
                continue
            arr[i] = (arr[i] | v) if op == '|=' else (arr[i] & v) if op == '&=' else v


def check_f1(b, a, t, sk, vg, evs, sc, where, mr):
    """One F1 victim: model apply_victim from the MISS machine's post-step
    RNG (same frame as the handler) vs the engine. Returns True on a KO."""
    state = st16(mr) if mr else 0
    side_iron = (t & 4) if sk == 0x2A else (a & 4)
    hp0, dd1b0 = b.hp[t], b.dd1b[t]
    o, _ = F1.apply_victim(b, a, t, sk, state)
    legacy = 'pc' not in vg[0]          # a pre-S130 corpus (no handler/helper waypoints)
    fx = next((e for e in vg if e['tag'] == 'fx'), None)
    if not legacy:
        tally('f1_handler', fx is not None, dict(w=where, a=a, t=t, sk=hex(sk), tags=[e['tag'] for e in vg]))
    got_h = sorted({e.get('pc') for e in vg if e.get('pc') in HELPER_PCS})
    if o in ('hit', 'miss', 'boss'):
        want_h = sorted({F1.HELPER_ADDR[sk]} | ({0x65E3} if sk in (0x7B, 0x7C) and o != 'boss' else set()))
    elif o == 'flyer':
        want_h = [0x65FF]
    else:
        want_h = []
    if legacy:
        # the S85 rig hooked $5C51/$5C8F/$5CBC/$5CDA/$65B5/$65C9 as tags only
        got_h = sorted({F1.HELPER_ADDR[sk]} if any(e['tag'] in ('status_in', 'status_roll', 'statchance_in')
                                                    for e in vg) else set())
        want_h = [h for h in want_h if h in (0x5C51, 0x5C8F, 0x5CBC, 0x5CDA, 0x65B5, 0x65C9)]
    tally('f1_helper', got_h == want_h,
          dict(w=where, a=a, t=t, sk=hex(sk), o=o, got=[hex(x) for x in got_h], want=[hex(x) for x in want_h]))
    # engine state after the handler: apply_in (post-handler) when reached,
    # else the first later waypoint that is not a KO tick
    ap = next((e for e in vg if e['tag'] == 'apply_in'), None)
    if sk in F1.BEAT_IDS and o == 'hit':
        ap = None           # the KO state's status wipe comes after apply_in
    if ap is not None:
        post = ap
    else:
        idx = evs.index(vg[-1])
        post = next((e for e in evs[idx + 1:] if e['tag'] != 'ko'), None)
        if post is not None and post['sc'] != sc:
            post = None
    if post is None:
        return o == 'hit' and sk in F1.BEAT_IDS
    p9 = post['tag'].startswith('p9') or post['tag'] == 'round_end'
    offs = (2, 3, 5) if p9 else range(2, 8)   # +0/+1 hold the PREVIOUS slot's shifted guard record (F6)
    if sk in F1.IRON_IDS:
        slots = [s for s in range(side_iron, side_iron + 4)]
        ok = all(post['st'][s*8+7] == b.stb(s, 7) for s in slots) if not p9 else True
        tally('f1_outcome', ok, dict(w=where, a=a, t=t, sk=hex(sk), o=o,
                                     got=[post['st'][s*8+7] for s in slots], pred=[b.stb(s, 7) for s in slots]))
        return False
    who = a if sk == F1.SIDESTEP else t
    ok = all(post['st'][who*8+k] == b.st[who*8+k] for k in offs)
    if sk in F1.BEAT_IDS:
        ok = ok and post['dd1b'][t] == b.dd1b[t] and (post['hp'][t] == b.hp[t] or ap is not None)
    if sk == 0x7A and o == 'hit':
        ok = ok and post.get('dfn', [None]*8)[t] in (None, b.dfn[t]) and (t >= 7 or post['st'][(t+1)*8] & 0x80)
    tally('f1_outcome', ok, dict(w=where, a=a, t=t, sk=hex(sk), o=o, rng=(mr['rng1'], mr['rng2']) if mr else None,
                                 st5=b.stb(t, 5), lev=None,
                                 got=post['st'][who*8:who*8+8], pred=b.st[who*8:who*8+8],
                                 hp=(post['hp'][t], b.hp[t]), dd1b=(post['dd1b'][t], b.dd1b[t], dd1b0)))
    tally('f1_%s' % o, True)
    h = F1._helper(sk)
    lev = F1.res_lev(b, t, h[0]) if h else None
    COVER[(sk, 'P' if a < 4 else 'E', lev, b.stb(t, 5) & 0xC0, bool(b.db42[a] & 4), b.db73, o)] = \
        COVER.get((sk, 'P' if a < 4 else 'E', lev, b.stb(t, 5) & 0xC0, bool(b.db42[a] & 4), b.db73, o), 0) + 1
    return o == 'hit' and sk in F1.BEAT_IDS


def run(events):
    battles = split_battles(events)
    for sc, evs in battles.items():
        rounds = split_rounds(evs)
        # a capture cut by --maxev leaves a half round: drop it
        if rounds and not any(e['tag'] in ('ko', 'side_wipe', 'p9_dot_ko') for e in rounds[-1]) and len(rounds) > 1:
            rounds = rounds[:-1]
        for rn, rev in enumerate(rounds):
            R = rev[0]
            b = B.Board.from_event(R)
            where = f'{sc} r{rn}'
            B.clear_guard_marks(b)          # S89: guard marks are one-round
            actors, p9 = group_actions(rev)
            # ---- turn order --------------------------------------------
            if actors:
                got = [x for x in actors[0][0]['db79'] if x != 0xFF]
                # the build's own $FF fill covers $DB4C..$DB54 -> the 9th sort id is
                # always $FF; the 9th key $DB71/72 is outside every fill.
                order, _ = B.round_order(b, st16(R), R['db71'], 0xFF)
                tally('order', order == got, dict(w=where, got=got, pred=order))
            else:
                order = []
            # ---- actors ------------------------------------------------
            seq = [g[0]['A'] for g in actors if g[0]['A'] != 0xFF]
            cursor = 0
            walked = []
            ended = False
            for g in actors:
                a = g[0]['A']
                if a == 0xFF:
                    continue
                if ended:
                    tally('fetch', False, dict(w=where, a=a, why='after side wipe'))
                    continue
                walked.append(a)
                fe = g[0]
                tags = [e['tag'] for e in g]
                if b.valid(a) and b.dd13[a] != 2:
                    # F1: alive but not ready (e.g. woken by a hit: $DD13=3) —
                    # $454F reads $DD13 (gates_in fires), $4558 `jp nz` skips
                    tally('fetch_skip', set(tags) <= {'actor_fetch', 'gates_in'}, dict(w=where, a=a, tags=tags))
                    cursor += 1
                    continue
                if b.dd13[a] != 2 or not b.valid(a):
                    tally('fetch_skip', 'gates_in' not in tags, dict(w=where, a=a, tags=tags))
                    cursor += 1
                    continue
                gates = next((e for e in g if e['tag'] == 'gates_in'), None)
                if gates is None:
                    tally('fetch_skip', False, dict(w=where, a=a, tags=tags))
                    cursor += 1
                    continue
                # ---- status gates ----------------------------------
                forced_e = next((e for e in g if e['tag'] == 'forced'), None)
                pred = B.status_forced_action(b, a, st16(gates))
                got = forced_e['A'] if forced_e else None
                tally('gate', pred == got, dict(w=where, a=a, pred=pred, got=got,
                                                st=gates['st'][a*8:a*8+8]))
                if got is not None:
                    if pred in (B.FORCED_ASLEEP, B.FORCED_WAKES):
                        tally('sleep_byte', forced_e['st'][a*8+2] == b.stb(a, 2),
                              dict(w=where, a=a, got=forced_e['st'][a*8+2], pred=b.stb(a, 2)))
                    cursor += 1
                    continue
                cursed_on = False
                cs = next((e for e in g if e['tag'] == 'curse_stage'), None)
                if cs:
                    pred_c = B.curse_fires(b, a, st16(cs))
                    tally('curse', pred_c == ('curse_hit' in tags), dict(w=where, a=a))
                    if pred_c and 'curse_hit' in tags:
                        eff = B.curse_effect(b, a, st16(cs))
                        cursed_on = eff in ('hp', 'mp')   # F1: $D9EE:=5 skips the confusion branch
                        ch = g[tags.index('curse_hit')]
                        nxt = g[tags.index('curse_hit') + 1] if tags.index('curse_hit') + 1 < len(g) else None
                        if nxt is not None:
                            # 'mp' modelled S88 (MaxMP//6, needs the maxmp
                            # field -> legacy corpora fall back to engine MP).
                            # Read at skill_load: MP there is PRE the cast's
                            # own $480E spend, which otherwise leaks into
                            # later events of the same group.
                            slv = next((e for e in g if e['tag'] == 'skill_load' and e['frame'] > ch['frame']), nxt)
                            _tf = next((e for e in g if e['tag'] == 'target_fetch'), None)
                            _qsk = _tf['dcec'][a*2] if _tf else b.q_skill(a)
                            _qc = (CUSTOM[_qsk]['mp'] if _qsk in CUSTOM else
                                   (RECORDS.get(_qsk) or {}).get('battle_record', {})
                                   .get('fields', {}).get('mp_cost_byte', 0))
                            mp_ok = (slv['mp'][a] in (b.mp[a], max(b.mp[a] - _qc, 0))) if 'maxmp' in ch else True
                            tally('curse_effect', dict(skip='target_fetch' not in tags, hp=nxt['hp'][a] == b.hp[a],
                                                       mp=mp_ok, confuse=bool(nxt['st'][a*8+2] & 0x10))[eff],
                                  dict(w=where, a=a, eff=eff, rng=(cs['rng1'], cs['rng2']), hp=nxt['hp'][a], pred=b.hp[a],
                                       mp=nxt['mp'][a], mp_pred=b.mp[a]))
                            if eff == 'mp':
                                b.mp[a] = nxt['mp'][a]
                        if eff == 'skip':
                            cursor += 1
                            continue
                        if eff == 'confuse':
                            if 'conf_pick' in tags:
                                validate_conf(b, a, g, evs, sc, where)
                            else:
                                # legacy corpus: engine-owned pass-through
                                for e in g:
                                    if e['tag'] == 'apply_in' and e['db56'] and b.valid(e['db89']):
                                        B.apply_damage(b, e['db89'], e['db56'])
                            b.dd13[a] = 3
                            cursor += 1
                            continue
                if not cursed_on and b.stb(a, 2) & 0x10:   # F1: curse roll FIRST ($45CA), then bit4 ($45F9)
                    if 'conf_pick' in tags:
                        validate_conf(b, a, g, evs, sc, where)
                        b.dd13[a] = 3
                        cursor += 1
                        continue
                    # legacy corpus (no conf waypoints): engine-owned pass-through.
                    # NOTE (S88): the bit does NOT clear when the actor's own
                    # action finishes — only the on-hit snap-out clears it; a
                    # legacy corpus can't validate that, so take engine bytes.
                    for e in g:
                        if e['tag'] == 'apply_in' and e['db56'] and b.valid(e['db89']):
                            B.apply_damage(b, e['db89'], e['db56'])
                    nxt = next((x for x in rev[rev.index(g[-1]) + 1:] if x['tag'] in ('actor_fetch', 'p9_slot')), None)
                    if nxt is not None:
                        b.set_stb(a, 2, nxt['st'][a*8+2])
                    b.dd13[a] = 3
                    cursor += 1
                    continue
                # ---- dup conversion --------------------------------
                sk = b.q_skill(a)
                flag = DUP['flags'][b.eid[a - 4]] if 4 <= a < 7 and b.eid[a - 4] < len(DUP['flags']) else 0
                pred_d = (not cursed_on) and B.dup_conversion(b, a, order, cursor, flag)
                tally('dupconv', pred_d == ('dupconv' in tags),
                      dict(w=where, a=a, sk=sk, pred=pred_d, order=order, cursor=cursor))
                if pred_d:
                    sk = B.ATTACK
                    b.queue[a*2] = sk; b.queue[a*2+1] = 0xFF
                # ---- MP / seal veto --------------------------------
                rec = RECORDS.get(sk)
                f7 = rec['battle_record']['fields']['flags7'] if rec else CUSTOM.get(sk, {}).get('f7', 0)
                f8 = rec['battle_record']['fields']['flags8'] if rec else CUSTOM.get(sk, {}).get('f8', 0)
                mi = next((e for e in g if e['tag'] == 'miss_in'), None)
                if mi:
                    f7, f8 = mi['dcfd'], mi['dcfe']
                veto = B.act_mp_veto(b, a, sk, mp_cost(sk), f7)
                acted = 'target_fetch' in tags
                tally('veto', (veto is None) == acted,
                      dict(w=where, a=a, sk=hex(sk), veto=veto, acted=acted, mp=b.mp[a]))
                if veto is not None or not acted:
                    cursor += 1
                    b.dd13[a] = 3
                    continue
                # ---- target + victims ------------------------------
                vgs = victim_groups(g)
                # F1: a $DD0B=2 party member's act-time RE-DECIDE ($53:$46A8 ->
                # d9ed=$18: the AI re-picks skill AND target; its CalcSkillDefense
                # evaluations show up before the first target_fetch) — the
                # re-decided action is the AI's (engine-owned here)
                _tf0 = next((i for i, e in enumerate(g) if e['tag'] == 'target_fetch'), None)
                redecide = (b.dd0b[a] == 2 and _tf0 is not None and
                            any(e['tag'] == 'calcdef_in' for e in g[:_tf0]))
                if redecide:
                    tally('redecide_engine', True)
                    sk = g[_tf0]['dcec'][a * 2]
                    b.queue[a * 2] = sk
                    rec = RECORDS.get(sk)
                core = B.damage_core(sk, rec)
                qt = b.q_target(a)
                mi0 = next((e for e in vgs[0] if e['tag'] == 'miss_in'), None) if vgs else None
                # F1: without a MISS machine (iron victim) the engine's victim is
                # the queue target byte at target_fetch (the hook fires before
                # $520C loads wBattleTargetIdx, so its db89 is stale)
                first_t = mi0['db89'] if mi0 else (vgs[0][0]['dcec'][a*2+1] if vgs else None)
                iron_side = first_t is not None and first_t < 8 and any(
                    b.stb(s, 7) & 0xC0 for s in b.live_side(first_t & 4))
                if core == 'heal':
                    pred_t = B.heal_target(b, a)
                elif qt != 0xFF and b.valid(qt):
                    if B.reresolves(b, a, sk):
                        cands = b.live_side(qt & 4)
                        pred_t = cands[0] if len(cands) == 1 else first_t   # RNG pick: engine's
                        tally('reresolve', 'reresolve' in tags, dict(w=where, a=a, sk=hex(sk)))
                    else:
                        pred_t = qt
                        tally('reresolve_no', 'reresolve' not in tags, dict(w=where, a=a, sk=hex(sk), dd0b=b.dd0b[a]))
                elif qt == 0xFF:
                    cands = b.live_side((a & 4) ^ 4)
                    pred_t = cands[0] if len(cands) == 1 else first_t
                elif (rec and rec['battle_record']['fields']['target_mode'] & 1 and sk not in (0x51, 0x52, 0x53)
                      and b.dd0b[a] == 0):
                    # F1: single-target, dead queued target, $DD0B==0 -> fizzle
                    tally('dead_fizzle', all(e['tag'] == 'target_fetch' for vg in vgs for e in vg),
                          dict(w=where, a=a, sk=hex(sk), qt=qt, tags=[[e['tag'] for e in vg] for vg in vgs]))
                    b.dd13[a] = 3
                    cursor += 1
                    continue
                elif rec and rec['battle_record']['fields']['target_mode'] & 1:
                    # F1: single-target, dead queued target, $DD0B!=0: the bank
                    # $58 entry-8 re-pick ($53:$47D1; no hooked waypoint) —
                    # deterministic with one live candidate, else engine's
                    cands = b.live_side(qt & 4)
                    pred_t = cands[0] if len(cands) == 1 else first_t
                    tally('dead_repick', pred_t == first_t, dict(w=where, a=a, sk=hex(sk), qt=qt))
                else:
                    pred_t = B.dead_redirect(b, qt)
                    if not iron_side:
                        tally('dead_redirect', 'dead_redirect' in tags or 'reresolve' in tags, dict(w=where, a=a))
                if redecide:
                    pred_t = first_t
                if iron_side and pred_t != first_t:
                    # F1: an ironized slot on the target side — the act-time
                    # re-decision (party $DD0B=2 re-decide / bank $58 picks)
                    # steers around it; that AI choice is not this family's
                    # model: engine-owned (open item, S130_F1_NOTES (d)).
                    tally('target_iron_engine', True)
                    pred_t = first_t
                if sk in B.GUARD_SKILLS:      # S89: Cover/Guardian cast
                    B.set_guard_mark(b, a, first_t if B.GUARD_SKILLS[sk] == 'one' else None)
                if pred_t is not None:            # S89: Cover/Guardian
                    pred_t = B.guard_redirect(b, pred_t, f8)   # interception
                tally('target', pred_t == first_t, dict(w=where, a=a, sk=hex(sk), qt=qt, pred=pred_t, got=first_t))
                tm18 = bool(rec) and rec['battle_record']['fields']['target_mode'] == 18
                if first_t is not None and not tm18 and B.target_unreachable(b, first_t, f8, sk):
                    tally('unreachable', all(e['tag'] in ('target_fetch',) for vg in vgs for e in vg),
                          dict(w=where, a=a, sk=hex(sk), t=first_t))
                    b.dd13[a] = 3
                    cursor += 1
                    continue
                boss_gated = (sk not in F1.F1_IDS and
                              D.boss_gate_blocks(sk, (first_t or 0) >= 4, b.db73, arena=b.link))
                core_by_victim = {}
                if sk in B.QUAKE_RANGE:
                    pred_v = B.quake_victims(b, a, first_t if first_t is not None else (a & 4) ^ 4)
                    core_by_victim = {s: ('quake' if not b.flying(s) else 'none') for s, _ in pred_v}
                elif rec and rec['battle_record']['fields']['target_mode'] == 18 and core != 'none':
                    pred_v = [(s, 1) for s in B.side_victims(b, first_t, qt if qt != 0xFF else None)]
                else:
                    pred_v = [(first_t, 1)]
                if sk in F1.F1_IDS and first_t is not None:
                    pred_v = F1.victims(b, a, sk, rec['battle_record']['fields'], first_t, guard=False)
                    if sk == F1.BIGSLEEP:
                        pred_v = [(s, d) for s, d in pred_v if b.valid(s)]
                if sk not in B.QUAKE_RANGE and len(pred_v) > 1:
                    # S89: each victim of a side sweep passes the guard
                    # table independently; a protected slot resolves on
                    # its protector, and the engine does NOT de-duplicate
                    # — a protector covering two allies is hit twice
                    # (measured: Guardian victims [4,4]).
                    pred_v = [(B.guard_redirect(b, _s, f8), _d) for _s, _d in pred_v]
                got_v = []
                for vg in vgs:
                    m = next((e for e in vg if e['tag'] == 'miss_in'), None)
                    got_v.append(m['db89'] if m else vg[0]['dcec'][a*2+1])
                if core != 'none' and not boss_gated:
                    if tm18 and pred_v and pred_v[0][0] != first_t and iron_side:
                        pred_v = [(s, 1) for s in B.side_victims(b, first_t)]
                    tally('victims', [s for s, _ in pred_v] == got_v,
                          dict(w=where, a=a, sk=hex(sk), pred=pred_v, got=got_v))
                # ---- per victim ------------------------------------
                dead_before = B.mourn_multiplier(b, a)
                for vi, vg in enumerate(vgs):
                    t = got_v[vi]
                    vt = [e['tag'] for e in vg]
                    mr = next((e for e in vg if e['tag'] == 'miss_rng'), None)
                    outcome = next((x for x in vt if x in ('miss', 'dodge', 'block')), 'pass')
                    if (f8 & 0x80) and b.valid(t) and (b.db42[t] & 0x80) and not (
                            (b.stb(t, 2) & 0xD0) or (b.stb(t, 5) & 0x3F) or (b.stb(t, 7) & 0xC0)):
                        # F1 (engine-owned consumer, $53:$563C): a target whose
                        # $DB42 bit7 is set "easily dodges" (msg $6E) every
                        # flags8-bit7 action before the MISS machine (no step);
                        # the per-round $DB42 setter is not modelled (S89 open)
                        tally('db42_easy_dodge', 'miss_in' not in vt, dict(w=where, a=a, t=t, tags=vt))
                        continue
                    if tm18 and B.target_unreachable(b, t, f8, sk):
                        # F1: per-victim iron pre-gate inside a sweep: no MISS
                        # machine, nothing applied, the sweep goes on
                        tally('unreachable_v', 'miss_in' not in vt and 'apply_in' not in vt,
                              dict(w=where, a=a, t=t, sk=hex(sk), tags=vt))
                        continue
                    if mr:
                        pm = B.miss_gate(b, a, t, f7, f8, st16(mr))
                        tally('miss', pm == outcome, dict(w=where, a=a, t=t, sk=hex(sk), pred=pm, got=outcome,
                                                        rng=(mr['rng1'], mr['rng2']), f7=f7, f8=f8, agl=b.agl[t]))
                    if outcome != 'pass':
                        continue
                    if sk in F1.F1_IDS:
                        ko = check_f1(b, a, t, sk, vg, evs, sc, where, mr)
                        if ko and (B.side_wiped(b, 4) or B.side_wiped(b, 0)):
                            ended = True
                        continue
                    ap = next((e for e in vg if e['tag'] == 'apply_in'), None)
                    cd = next((e for e in vg if e['tag'] == 'calcdef_in'), None)
                    ri = next((e for e in vg if e['tag'] == 'roll_in'), None)
                    sr = next((e for e in vg if e['tag'] == 'status_roll'), None)
                    sc_ = next((e for e in vg if e['tag'] == 'statchance_in'), None)
                    got_core = ('calcdef' if cd else 'record' if ri and sk not in B.HEAL_IDS and sk not in B.STATUS_SPELLS
                                else 'heal' if ri else 'status' if (sr or sc_) else
                                'quake' if sk in B.QUAKE_RANGE and ap else 'none')
                    if boss_gated:
                        tally('boss_gate', got_core == 'none' and ap is None,
                              dict(w=where, a=a, sk=hex(sk), t=t, tags=vt))
                        if sk == 0x14:
                            b.hp[a] = 1     # boss-gated Sacrifice: caster left at 1 HP (measured S85, 1/1)
                        continue
                    want_core = core_by_victim.get(t, core) if sk in B.QUAKE_RANGE else core
                    if want_core == 'f6-setter':   # S130 F6: Defence-family fillers have no damage core
                        want_core = 'none'
                    if sk in B.AIR_STATUS:
                        off, mask = B.AIR_STATUS[sk]
                        if b.stb(t, off) & mask:
                            tally('status_already', ap is None and sc_ is None, dict(w=where, a=a, sk=hex(sk), t=t, tags=vt))
                            continue
                    if sk in B.STATUS_SPELLS:
                        # 'already' -> no waypoints at all
                        o, _ = B.status_spell_roll(b, a, t, sk, st16(sr) if sr else 0)
                        if o == 'already':
                            tally('status_already', sr is None and ap is None, dict(w=where, a=a, sk=hex(sk), t=t, tags=vt))
                            continue
                        got_o = 'hit' if ap else 'miss'
                        tally('status_roll', sr is not None and o == got_o,
                              dict(w=where, a=a, sk=hex(sk), t=t, pred=o, got=got_o, tags=vt))
                        if got_o == 'hit':
                            B.apply_status(b, t, sk)
                            idx = evs.index(ap)
                            nxt = evs[idx + 1] if idx + 1 < len(evs) else ap
                            tally('status_byte', nxt['st'][t*8:t*8+8] == b.st[t*8:t*8+8],
                                  dict(w=where, a=a, sk=hex(sk), t=t, got=nxt['st'][t*8:t*8+8], pred=b.st[t*8:t*8+8]))
                        continue
                    if want_core == 'calcdef' and got_core == 'none' and ap and ap['db56']:
                        tally('core_unhooked', True, dict(w=where, a=a, sk=hex(sk)))   # damage landed, entry hook missed
                        got_core = 'calcdef'
                    tally('core', want_core == got_core,
                          dict(w=where, a=a, sk=hex(sk), pred=want_core, got=got_core, tags=vt))
                    if sk in B.AIR_STATUS:
                        # chance not modelled: apply on the engine's hit (byte change)
                        if ap:
                            B.apply_status(b, t, sk)
                        continue
                    if ap is None:
                        continue
                    dmg = ap['db56']
                    if got_core == 'calcdef' and not cd:
                        B.apply_damage(b, t, dmg)      # unhooked roll: apply the engine's number
                        continue
                    if got_core == 'calcdef' and cd:
                        pd, _ = D.calc_skill_defense(b.atk[a], b.dfn[t], st16(cd), target_idx=t,
                                                     arena=b.link, attacker_idx=a)
                        mult = B.PHYSICAL_IDS.get(sk, 1)
                        if mult == 'mourn':
                            pd = pd * dead_before
                        elif mult != 1:
                            pd = int(pd * mult)
                        pd = B.db42_boost(b, a, pd)   # S89: $DB42 bit6 x1.5
                        tally('damage_phys', pd == dmg, dict(w=where, a=a, t=t, sk=hex(sk), pred=pd, got=dmg,
                                                             atk=b.atk[a], dfn=b.dfn[t], rng=(cd['rng1'], cd['rng2'])))
                        if sk in B.PHYS_STATUS_RIDER and (sc_ or sr):
                            # S88: rider modelled (rider_roll, 41/41). The
                            # statchance_in hook fires at helper entry —
                            # BEFORE $69's BossProtectionGate veto. $68's
                            # sleep roll fires the status_roll hook instead.
                            re_ = sc_ or sr
                            off, mask = B.PHYS_STATUS_RIDER[sk]
                            rh, _ = B.rider_roll(b, t, sk, st16(re_))
                            # read the byte at the NEXT event after the roll:
                            # a p9 read is too late for $68 — the victim's
                            # own wake gate can clear the fresh sleep first.
                            ri_ = evs.index(re_)
                            ne = next((x for x in evs[ri_ + 1:]
                                       if x['sc'] == sc and x['frame'] > re_['frame']), None)
                            if ne is not None and rh is not None:
                                got_r = bool(ne['st'][t*8+off] & mask)
                                tally('rider', rh == got_r,
                                      dict(w=where, a=a, t=t, sk=hex(sk), pred=rh, got=got_r,
                                           rng=(re_['rng1'], re_['rng2']), db73=re_['db73']))
                    elif got_core in ('record', 'heal') and ri:
                        pmin = ri['db4c'] | (ri['db4d'] << 8); prng = ri['db4e']
                        pd, _ = D.record_roll(pmin, prng, st16(ri))
                        f = rec['battle_record']['fields']
                        want = (f['power_enemy_min'], f['power_enemy_range']) if a & 4 else (f['power_party_min'], f['power_party_range'])
                        tally('side_select', (pmin, prng) == want, dict(w=where, sk=hex(sk), got=(pmin, prng), want=want))
                        if got_core == 'heal':
                            hp0 = b.hp[t]
                            B.apply_heal(b, t, pd)
                            tally('heal', ap['db56'] == pd and ap['hp'][t] == b.hp[t],
                                  dict(w=where, a=a, t=t, roll=pd, got=ap['db56'], hp0=hp0, hp=ap['hp'][t], pred=b.hp[t]))
                            continue
                        if sk in SPELL_LADDER:
                            rt, lad = SPELL_LADDER[sk]
                            lev = D.res_level(bytes(b.res[t*7:t*7+7]), rt)
                            ladder = D.LADDER_A if lad == 'A' else D.LADDER_BREATH
                            pd = D.apply_ladder(pd, ladder, b.stb(t, 5), lev)
                        pd = B.db42_boost(b, a, pd)   # S89: $DB42 bit6 x1.5
                        tally('damage_record', pd == dmg, dict(w=where, a=a, t=t, sk=hex(sk), pred=pd, got=dmg))
                    elif got_core == 'quake':
                        lo, hi = B.QUAKE_RANGE[sk]
                        div = dict(pred_v).get(t, 1)
                        ok = (lo // div - 1) <= dmg <= hi // div
                        tally('damage_quake', ok, dict(w=where, a=a, t=t, sk=hex(sk), got=dmg, div=div))
                    # apply + KO
                    hp_before = b.hp[t]
                    ko = B.apply_damage(b, t, dmg)
                    idx = evs.index(ap)
                    # HP settles after the KO pair (the $1A state's 2nd tick
                    # shows a transient full-HP value); a battle-ending KO
                    # has no later event -> nothing to compare
                    j = idx + 1
                    while j < len(evs) and evs[j]['tag'] == 'ko':
                        j += 1
                    hp_after = evs[j]['hp'][t] if j < len(evs) and evs[j]['sc'] == sc else None
                    if hp_after is not None:
                        tally('hp', hp_after == b.hp[t], dict(w=where, a=a, t=t, before=hp_before, dmg=dmg, got=hp_after, pred=b.hp[t]))
                    # [S89] bound the slice at the NEXT victim's segment:
                    # an unbounded scan pairs a LATER victim's KO with an
                    # earlier surviving victim (die_a: Infernos killed
                    # victim 2 only, victim 1's check saw its ko events)
                    seg = g[g.index(ap):]
                    for k2, e2 in enumerate(seg[1:], 1):
                        if e2['tag'] in ('apply_in', 'target_fetch',
                                         'calcdef_in', 'final_54e7'):
                            seg = seg[:k2]
                            break
                    got_ko = any(e['tag'] == 'ko' for e in seg)
                    tally('ko', ko == got_ko, dict(w=where, a=a, t=t, hp=hp_before, dmg=dmg, pred=ko))
                    if not ko:
                        check_snap(b, a, vg, evs, sc, where,
                                   rec['battle_record']['fields'].get('flags9', 0) if rec else 0)
                    if ko and (B.side_wiped(b, 4) or B.side_wiped(b, 0)):
                        ended = True
                b.dd13[a] = 3
                cursor += 1
                if B.side_wiped(b, 0) or B.side_wiped(b, 4):
                    ended = True        # F1: incl. the all-paralysed party (BattleFunc_76c8)
            # [S89] an actor KO'd before its turn is silently skipped by
            # the engine (dd13 -> $FF at KO): missing walk entries are OK
            # iff they are dead on the model board (die_a: Infernos
            # killed the round's 3rd actor at the 1st actor's cast).
            tally('fetch', walked == [x for x in order if x in walked]
                  and (ended or all(b.hp[x] == 0
                                    for x in order if x not in walked)),
                  dict(w=where, got=walked, pred=order, ended=ended))
            # ---- phase 9 -------------------------------------------------
            if p9:
                slots = [e for e in p9 if e['tag'] == 'p9_slot']
                if slots:
                    B.phase9_decay(b)
                    tally('decay', slots[0]['st'] == b.st, dict(w=where, got=slots[0]['st'], pred=b.st))
                    pred_slots = [s for s in range(8) if b.valid(s)]
                    got_slots = [e['A'] for e in slots]
                    tally('p9_order', got_slots == pred_slots[:len(got_slots)] and
                          (len(got_slots) == len(pred_slots) or any(e['tag'] == 'p9_dot_ko' for e in p9)),
                          dict(w=where, got=got_slots, pred=pred_slots))
                    pred_slots = [s for s in range(8) if b.valid(s)]
                    for e in slots:
                        s = e['A']
                        if B.side_wiped(b, 0) or B.side_wiped(b, 4):
                            break
                        kind, dmg = B.dot_damage(b, s, st16(e))
                        da = next((x for x in p9 if x['tag'] == 'p9_dot_apply' and x['db88'] == s and x['frame'] > e['frame']), None)
                        tally('dot', (kind in ('poison', 'heavy')) == (da is not None), dict(w=where, s=s, kind=kind))
                        if da:
                            tally('dot_dmg', da['db56'] == dmg, dict(w=where, s=s, kind=kind, got=da['db56'], pred=dmg, maxhp=b.maxhp[s]))
                            B.apply_damage(b, s, da['db56'])
                            idx = evs.index(da)
                            tally('dot_hp', next_hp(evs, idx, s) == b.hp[s], dict(w=where, s=s))
                # next round's board vs model (HP/MP/dd1b) — the strongest check
                if rn + 1 < len(rounds):
                    N = rounds[rn + 1][0]
                    apply_rpoke(b, N.get('rpoke') or [])
                    tally('round_hp', N['hp'] == b.hp, dict(w=where, got=N['hp'], pred=b.hp))
                    tally('round_dd1b', N['dd1b'] == b.dd1b, dict(w=where, got=N['dd1b'], pred=b.dd1b))
                    tally('round_st', N['st'] == b.st, dict(w=where, got=N['st'], pred=b.st))


if __name__ == '__main__':
    args = [x for x in sys.argv[1:] if not x.startswith('-')]
    path = args[0] if args else os.path.join(ROOT, 'simulator', 'f1_status_events.json.gz')
    import gzip
    events = json.load((gzip.open if path.endswith('.gz') else open)(path, 'rt'))
    run(events)
    total = sum(v[0] + v[1] for v in stats.values())
    bad = sum(v[1] for v in stats.values())
    for k, (ok, no) in sorted(stats.items()):
        print(f'{k:16s} ok={ok:5d} fail={no}')
    if '-c' in sys.argv:
        for k in sorted(COVER, key=lambda k: tuple(-1 if x is None else (int(x) if not isinstance(x, str) else ord(x[0])) for x in k)):
            sk, side, lev, row, sure, db73, o = k
            print(f'  cover {sk:02X} {side} L{lev} row{row:02X} sure{int(sure)} db73={db73} {o:8s} {COVER[k]}')
    print(f'TOTAL {total} comparisons, {bad} mismatches')
    if not VERBOSE:
        for f in fails[:25]:
            print('  ', f)
    sys.exit(1 if bad else 0)
