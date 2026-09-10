#!/usr/bin/env python3
"""Loop-level differential validator for simulator/battle.py (S85).

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
                if b.stb(a, 2) & 0x10:
                    # confusion gate (+2 bit4): ConfusionActionRewrite picks the
                    # action (engine-owned here — status.confusion_action's
                    # table is NOT what the curse-induced case shows: $99
                    # HitAlly on itself, 2/2 S85); the bit clears when that
                    # action finishes (measured S85: act state 5 sub 3).
                    for e in g:
                        if e['tag'] == 'apply_in' and e['db56'] and b.valid(e['db89']):
                            B.apply_damage(b, e['db89'], e['db56'])
                    b.set_stb(a, 2, b.stb(a, 2) & ~0x10)
                    nxt = next((x for x in rev[rev.index(g[-1]) + 1:] if x['tag'] in ('actor_fetch', 'p9_slot')), None)
                    tally('confusion_clear', nxt is None or not (nxt['st'][a*8+2] & 0x10), dict(w=where, a=a))
                    b.dd13[a] = 3
                    cursor += 1
                    continue
                cs = next((e for e in g if e['tag'] == 'curse_stage'), None)
                if cs:
                    pred_c = B.curse_fires(b, a, st16(cs))
                    tally('curse', pred_c == ('curse_hit' in tags), dict(w=where, a=a))
                    if pred_c and 'curse_hit' in tags:
                        eff = B.curse_effect(b, a, st16(cs))
                        ch = g[tags.index('curse_hit')]
                        nxt = g[tags.index('curse_hit') + 1] if tags.index('curse_hit') + 1 < len(g) else None
                        if eff == 'mp':
                            b.mp[a] = max(b.mp[a] - (ch['mp'][a] and 0), 0)  # MaxMP not captured: take engine MP
                        if nxt is not None:
                            tally('curse_effect', dict(skip='target_fetch' not in tags, hp=nxt['hp'][a] == b.hp[a],
                                                       mp=True, confuse=bool(nxt['st'][a*8+2] & 0x10))[eff],
                                  dict(w=where, a=a, eff=eff, rng=(cs['rng1'], cs['rng2']), hp=nxt['hp'][a], pred=b.hp[a]))
                            if eff == 'mp':
                                b.mp[a] = nxt['mp'][a]
                        if eff == 'skip':
                            cursor += 1
                            continue
                        if eff == 'confuse':
                            # confusion rewrite path: action/target from the engine
                            for e in g:
                                if e['tag'] == 'apply_in' and e['db56'] and b.valid(e['db89']):
                                    B.apply_damage(b, e['db89'], e['db56'])
                            b.dd13[a] = 3
                            cursor += 1
                            continue
                # ---- dup conversion --------------------------------
                sk = b.q_skill(a)
                flag = DUP['flags'][b.eid[a - 4]] if 4 <= a < 7 and b.eid[a - 4] < len(DUP['flags']) else 0
                pred_d = B.dup_conversion(b, a, order, cursor, flag)
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
                core = B.damage_core(sk, rec)
                qt = b.q_target(a)
                mi0 = next((e for e in vgs[0] if e['tag'] == 'miss_in'), None) if vgs else None
                first_t = mi0['db89'] if mi0 else (vgs[0][-1]['db89'] if vgs else None)
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
                else:
                    pred_t = B.dead_redirect(b, qt)
                    tally('dead_redirect', 'dead_redirect' in tags or 'reresolve' in tags, dict(w=where, a=a))
                tally('target', pred_t == first_t, dict(w=where, a=a, sk=hex(sk), qt=qt, pred=pred_t, got=first_t))
                if first_t is not None and B.target_unreachable(b, first_t, f8, sk):
                    tally('unreachable', all(e['tag'] in ('target_fetch',) for vg in vgs for e in vg),
                          dict(w=where, a=a, sk=hex(sk), t=first_t))
                    b.dd13[a] = 3
                    cursor += 1
                    continue
                boss_gated = D.boss_gate_blocks(sk, (first_t or 0) >= 4, b.db73, arena=b.link)
                core_by_victim = {}
                if sk in B.QUAKE_RANGE:
                    pred_v = B.quake_victims(b, a, first_t if first_t is not None else (a & 4) ^ 4)
                    core_by_victim = {s: ('quake' if not b.flying(s) else 'none') for s, _ in pred_v}
                elif rec and rec['battle_record']['fields']['target_mode'] == 18 and core != 'none':
                    pred_v = [(s, 1) for s in B.side_victims(b, first_t)]
                else:
                    pred_v = [(first_t, 1)]
                got_v = []
                for vg in vgs:
                    m = next((e for e in vg if e['tag'] == 'miss_in'), None)
                    got_v.append(m['db89'] if m else vg[0]['db89'])
                if core != 'none' and not boss_gated:
                    tally('victims', [s for s, _ in pred_v] == got_v,
                          dict(w=where, a=a, sk=hex(sk), pred=pred_v, got=got_v))
                # ---- per victim ------------------------------------
                dead_before = B.mourn_multiplier(b, a)
                for vi, vg in enumerate(vgs):
                    t = got_v[vi]
                    vt = [e['tag'] for e in vg]
                    mr = next((e for e in vg if e['tag'] == 'miss_rng'), None)
                    outcome = next((x for x in vt if x in ('miss', 'dodge', 'block')), 'pass')
                    if mr:
                        pm = B.miss_gate(b, a, t, f7, f8, st16(mr))
                        tally('miss', pm == outcome, dict(w=where, a=a, t=t, sk=hex(sk), pred=pm, got=outcome,
                                                        rng=(mr['rng1'], mr['rng2']), f7=f7, f8=f8, agl=b.agl[t]))
                    if outcome != 'pass':
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
                        tally('damage_phys', pd == dmg, dict(w=where, a=a, t=t, sk=hex(sk), pred=pd, got=dmg,
                                                             atk=b.atk[a], dfn=b.dfn[t], rng=(cd['rng1'], cd['rng2'])))
                        if sk in B.PHYS_STATUS_RIDER and sc_:
                            # rider chance not modelled: take the engine's
                            # outcome from the round's first phase-9 event
                            off, mask = B.PHYS_STATUS_RIDER[sk]
                            p9e = next((e for e in p9 if e['tag'] == 'p9_slot'), None)
                            if p9e and p9e['st'][t*8+off] & mask:
                                B.apply_status(b, t, sk)
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
                    got_ko = any(e['tag'] == 'ko' for e in g[g.index(ap):])
                    tally('ko', ko == got_ko, dict(w=where, a=a, t=t, hp=hp_before, dmg=dmg, pred=ko))
                    if ko and (B.side_wiped(b, 4) or B.side_wiped(b, 0)):
                        ended = True
                b.dd13[a] = 3
                cursor += 1
            tally('fetch', walked == [x for x in order][:len(walked)] and (ended or len(walked) == len(order)),
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
                    tally('round_hp', N['hp'] == b.hp, dict(w=where, got=N['hp'], pred=b.hp))
                    tally('round_dd1b', N['dd1b'] == b.dd1b, dict(w=where, got=N['dd1b'], pred=b.dd1b))
                    tally('round_st', N['st'] == b.st, dict(w=where, got=N['st'], pred=b.st))


if __name__ == '__main__':
    events = json.load(open(sys.argv[1]))
    run(events)
    total = sum(v[0] + v[1] for v in stats.values())
    bad = sum(v[1] for v in stats.values())
    for k, (ok, no) in sorted(stats.items()):
        print(f'{k:16s} ok={ok:5d} fail={no}')
    print(f'TOTAL {total} comparisons, {bad} mismatches')
    if not VERBOSE:
        for f in fails[:25]:
            print('  ', f)
    sys.exit(1 if bad else 0)
