#!/usr/bin/env python3
"""S130 F6 differential validator — defence levels, interception, reflect
and absorb (simulator/skillfx/f6_defence.py) against the engine captures of
simulator/measure_f6.py (corpus simulator/f6_events.json).

The S85 method: every check injects the engine's own board and RNG at a
waypoint and diffs the model's prediction with a later waypoint.

  setter        F6 handler entry -> $52:$6CDD return: the 64-byte status
                area + $DB40/41 + $DB4A/4B (Cover/Guardian: the guard bytes
                at the next actor/round waypoint — the writer is act state 3)
  postcalc      $53:$59EC ($DB56 in) -> $5A6F ($DB56 out): the defence
                levels + the F23 Beserker stage (tallied apart when the
                target's level is 0)
  counter_gate  $52:$6ECF: LoadBattle_6ecf's verdict (does $7BEC run)
  counter       $7BEC entry -> $7C47 (after BattleRNG and the RNG1 writes):
                RNG, outcome (the act-state-$13 swap follows) and the
                attacker's HP / KO afterwards
  dodge_gate    act state 7 at $54D6: does ClrBtlC_5091 run ($557A)
  dodge         ClrBtlC_5091 chain: passes (re-runs), the RNG after the
                last pass, the target at act state 8 ($5622)
  absorb        $5458: SuckAll absorb / skip / none; the redirected target
  suckback      the $DD6C=$40 breath-back: attacker, target
  wind / magic  $5594 / $55CA: reflect or not ($5E38 with A = 1 / 4), the
                +4 byte after (consumption)
  reflect_tgt   the reflected fetch: attacker = reflector, target = caster
                (or its protector)
  reflect_dmg   the reflected hit's record roll + ladder with the
                REFLECTOR as attacker (power by its side)
  takemagic     LoadBtlC_5ffa -> the MP after; tm_occur: a landed damage
                hit of a flags9-bit0 skill on a +4 bit0 target applies it
  imitate       $52:$7DD7: re-cast (A=8 at $5DE7) or not; imitate_tgt /
                imitate_mp: the re-cast's attacker, target, MP spend
  act_target    F6 skills: skill_load queue byte (+ the re-resolve RNG) ->
                the target at $53:$520C
  phase9        the last waypoint before phase 9 -> the first $50:$6B25:
                battle.phase9_decay + f6 phase9 hook on st/$DB4A/$DB40-41
  dd6e          $DD6E at $52:$6ECF is nonzero iff this victim was Cover-
                or dodge-redirected (the model's counter/Imitate/TakeMagic
                suppression flag)

Usage: python3 simulator/validate_f6.py [corpus.json] [-v]
"""
import json, os, sys, gzip
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import battle as B
from simulator.skillfx import f6_defence as F
from simulator.skillfx import f23_phys as F23

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECORDS = {r['id']: r for r in json.load(open(os.path.join(ROOT, 'extracted', 'skill_records.json')))['records']}
VERBOSE = '-v' in sys.argv
args = [x for x in sys.argv[1:] if not x.startswith('-')]
CORPUS = args[0] if args else os.path.join(ROOT, 'simulator', 'f6_events.json.gz')

H_TAGS = {'h_takemagic', 'h_barrier', 'h_magicwall', 'h_magicback', 'h_imitate', 'h_cover',
          'h_tailwind', 'h_dodge', 'h_defence', 'h_suckall'}
stats, fails = {}, []
cover = {}


def tally(kind, ok, detail=None):
    s = stats.setdefault(kind, [0, 0])
    s[0 if ok else 1] += 1
    if not ok:
        fails.append((kind, detail))
        if VERBOSE:
            print('FAIL', kind, detail)


def note(key):
    cover[key] = cover.get(key, 0) + 1


def st16(e):
    return (e['rng1'] << 8) | e['rng2']


def fields(sk):
    r = RECORDS.get(sk)
    return dict(r['battle_record']['fields']) if r else {}


def rt_fields(e):
    """The skill's cached record bytes at run time ($DCFC-$DCFF)."""
    f = fields(e['db8a'])
    f.update(target_mode=e['dcfc'], flags7=e['dcfd'], flags8=e['dcfe'], flags9=e['dcff'])
    return f


def board(e):
    b = B.Board.from_event(e)
    b.maxmp = list(e['maxmp'])
    b.ext['f7_db40'] = e['db40'][0]
    b.ext['f6_db41'] = e['db40'][1]
    b.ext['f6_db4a'] = list(e['db4a'])
    return b


def view(b):
    return (list(b.st), [b.ext.get('f7_db40', 0), b.ext.get('f6_db41', 0)], list(F.db4a(b)))


def eview(e):
    return (list(e['st']), list(e['db40']), list(e['db4a']))


def nxt(evs, i, tags, stop=()):
    for j in range(i + 1, len(evs)):
        t = evs[j]['tag']
        if t in tags:
            return j
        if t in stop:
            return None
    return None


def span(evs, i, stop):
    out = []
    for j in range(i + 1, len(evs)):
        if evs[j]['tag'] in stop:
            break
        out.append(j)
    return out


ACT_STOP = ('actor_fetch', 'round_start', 'p9_slot')


def check_battle(sc, evs):
    for i, e in enumerate(evs):
        tag = e['tag']
        a, t, sk = e['db88'], e['db89'], e['db8a']
        where = dict(sc=sc, i=i, tag=tag, a=a, t=t, sk=hex(sk))
        # ------------------------------------------------ setters
        if tag in H_TAGS:
            b = board(e)
            out = F.SETTERS[sk](b, a, t, sk) if sk in F.SETTERS else None
            note(('setter', hex(sk), 'enemy' if a >= 4 else 'party', out))
            if tag == 'h_cover':
                j = nxt(evs, i, ACT_STOP)
                if j is None:
                    continue
                post = evs[j]
                pg = [(b.st[8 + 8 * x] & 0x10, b.st[9 + 8 * x] & 0xF0) for x in range(7)]
                eg = [(post['st'][8 + 8 * x] & 0x10, post['st'][9 + 8 * x] & 0xF0) for x in range(7)]
                if post['tag'] == 'p9_slot':     # phase 9 already cleared them
                    continue
                tally('setter', pg == eg, dict(where, pred=pg, got=eg))
                continue
            j = nxt(evs, i, ('h_ret',), ACT_STOP)
            if j is None:
                continue
            tally('setter', view(b) == eview(evs[j]),
                  dict(where, out=out, diff=[(n, b.st[n], evs[j]['st'][n]) for n in range(64)
                                             if b.st[n] != evs[j]['st'][n]],
                       ext=(view(b)[1:], eview(evs[j])[1:])))
        # ------------------------------------------------ post-calc
        if tag == 'pc_def':
            j = nxt(evs, i, ('pc_end',), ('target_fetch',) + ACT_STOP)
            if j is None:
                continue
            b = board(e)
            f = rt_fields(e)
            d = F.defence_divide(b, t, e['dcfd'], e['db56'])
            n = F.g9(b, t) & 7
            if n == 0:
                d, _ = F23.postcalc_beserker_taken(b, a, t, sk, f, None, d, 0)
            kind = 'postcalc_def' if n else 'postcalc_other'
            tally(kind, d == evs[j]['db56'], dict(where, n=n, din=e['db56'], pred=d, got=evs[j]['db56'],
                                                   f7=hex(e['dcfd']), db42=e['db42'][t]))
            if n:
                note(('postcalc', n, 'phys' if e['dcfd'] & 0x80 else ('b0' if e['dcfd'] & 1 else 'none'),
                      'db42b1' if e['db42'][t] & 2 else '', 'enemy-def' if t >= 4 else 'party-def'))
        # ------------------------------------------------ counter
        if tag == 'bd_check':
            b = board(e)
            pred = F.counter_gate(b, t, e['dcfd'], e['dd6e'], e['dd6c'])
            j = nxt(evs, i, ('bd_counter',), ('bd_check', 'target_fetch', 'im_check') + ACT_STOP)
            tally('counter_gate', pred == (j is not None), dict(where, pred=pred, dd6e=e['dd6e'],
                                                                 dd6c=e['dd6c'], g9=F.g9(b, t)))
            # dd6e: nonzero iff this victim was Cover/dodge-redirected
            k = i
            while k > 0 and evs[k]['tag'] != 'target_fetch':
                k -= 1
            vs = [evs[x]['tag'] for x in range(k, i)]
            pred6e = ('ic_guard' in vs) or ('dg_roll' in vs)
            tally('dd6e', pred6e == bool(e['dd6e']), dict(where, dd6e=e['dd6e'], tags=vs))
        if tag == 'bd_counter':
            b = board(e)
            out, st2 = F.counter_roll(b, t, e['db56'], st16(e))
            jd = nxt(evs, i, ('bd_dec',), ('target_fetch',) + ACT_STOP)
            note(('counter', out, 'db42b3' if e['db42'][t] & 8 else '', 'half0' if e['db56'] >> 1 == 0 else '',
                  'enemy-bladed' if t >= 4 else 'party-bladed'))
            if out is None:
                tally('counter', jd is None, dict(where, pred='incapable'))
                continue
            if jd is None:
                tally('counter', False, dict(where, pred=out, got='no bd_dec'))
                continue
            if evs[jd]['frame'] == e['frame']:
                tally('counter_rng', st16(evs[jd]) == st2, dict(where, pred=hex(st2), got=hex(st16(evs[jd]))))
            js = nxt(evs, jd, ('bd_swap',), ('target_fetch', 'bd_check') + ACT_STOP)
            got = 'counter' if js is not None else 'nocounter'
            tally('counter', out == got, dict(where, pred=out, got=got))
            if out == 'counter' and got == 'counter':
                amt, ko = F.counter_apply(b, a, e['db56'])
                jn = nxt(evs, js, ('actor_fetch', 'round_start', 'p9_slot', 'target_fetch', 'round_end'))
                if jn is not None:
                    post = evs[jn]
                    tally('counter_hp', (post['hp'][a], post['dd1b'][a]) == (b.hp[a], b.dd1b[a]),
                          dict(where, pred=(b.hp[a], b.dd1b[a]), got=(post['hp'][a], post['dd1b'][a]), amt=amt))
                    note(('counter_ko', ko))
        # ------------------------------------------------ act state 7
        if tag == 'ic_absorb':
            b = board(e)
            f = rt_fields(e)
            kind, u = F.intercept_check(b, a, t, sk, f, e['dd6c'])
            if kind not in ('absorb', 'skip'):
                kind = None
            ja = nxt(evs, i, ('absorb',), ('ic_cover', 'ic_end', 'target_fetch') + ACT_STOP)
            jc = nxt(evs, i, ('ic_cover', 'ic_end'), ('target_fetch',) + ACT_STOP)
            got = 'absorb' if ja is not None else ('skip' if (jc is not None and evs[jc]['tag'] == 'ic_end')
                                                    else None)
            if (e['dcfd'] & 0x10) and (e['st'][F.side_of(t)] & 0x40):
                note(('absorb', got, 'enemy-side' if t >= 4 else 'party-side'))
            tally('absorb', kind == got, dict(where, pred=(kind, u), got=got))
            if kind == 'absorb' and got == 'absorb':
                je = nxt(evs, ja, ('ic_end', 'miss_in'), ('target_fetch',) + ACT_STOP)
                if je is not None:
                    tally('absorb_tgt', evs[je]['db89'] == u, dict(where, pred=u, got=evs[je]['db89']))
                # the sweep ends: every later fetch of this action is the breath-back's
                fs = [(evs[x]['db88'], evs[x]['db89']) for x in span(evs, ja, ACT_STOP)
                      if evs[x]['tag'] == 'target_fetch']
                tally('absorb_end', all(fa == u for fa, _ in fs), dict(where, fetches=fs, user=u))
        if tag == 'rf_save' and e['A'] == F.RF_SUCKBACK:
            b = board(e)
            # $53 entry 9 -> CallBtlC_5e38: attacker := the absorber, group
            # target via bank $58 entry 8 (first live of the other side)
            jt = nxt(evs, i, ('target_fetch',), ('actor_fetch', 'round_start'))
            if jt is not None:
                u = e['db89']
                pred = (u, F.first_live(b, (u & 4) ^ 4))
                got = (evs[jt]['db88'], evs[jt]['db89'])
                tally('suckback', pred == got, dict(where, pred=pred, got=got))
                note(('suckback', 'enemy-user' if u >= 4 else 'party-user'))
        if tag == 'ic_cover':
            b = board(e)
            f7, f8 = e['dcfd'], e['dcfe']
            sp = span(evs, i, ('ic_wind', 'ic_end', 'target_fetch') + ACT_STOP)
            tags = [evs[x]['tag'] for x in sp]
            if not e['dd6e']:
                gt = B.guard_redirect(b, t, f8)
                je = nxt(evs, i, ('ic_end',), ('target_fetch',) + ACT_STOP)
                got_t = evs[je]['db89'] if je is not None else None
                pred_g = gt != t
                tally('cover', (pred_g, gt if pred_g else None) == ('ic_guard' in tags, got_t if 'ic_guard' in tags else None),
                      dict(where, pred=gt, got=got_t, tags=tags))
                if F.g8(b, t) & 0x10:
                    prot = F.g9(b, t) >> 4
                    note(('cover', 'redirect' if pred_g else 'kept', 'f8b1' if f8 & 2 else 'no-f8b1',
                          'prot-capable' if F.capable(b, prot) else 'prot-incapable',
                          'reflected' if e['dd6c'] else ''))
            if 'ic_guard' in tags:
                continue
            pred = F.dodge_gate(b, t, f7, f8, e['dd6c'])
            got = 'ic_dodge' in tags
            tally('dodge_gate', pred == got, dict(where, pred=pred, got=got, g8=F.g8(b, t), db42=e['db42'][t]))
            if f7 & 0x80 and (F.g8(b, t) & 0x20):
                note(('dodge_gate', got, 'capable' if F.capable(b, t) else 'incapable'))
        if tag == 'dg_roll' and (i == 0 or evs[i - 1]['tag'] == 'ic_dodge'):
            b = board(e)
            trace = []
            nt, st2, msg = F.dodge_machine(b, t, st16(e), trace)
            sp = span(evs, i, ('ic_end', 'target_fetch') + ACT_STOP)
            rolls = sum(1 for x in sp if evs[x]['tag'] == 'dg_roll') + 1
            last = [x for x in sp if evs[x]['tag'] in ('dg_pick', 'dg_self')]
            je = nxt(evs, i, ('ic_end',), ('target_fetch',) + ACT_STOP)
            got_t = evs[je]['db89'] if je is not None else None
            tally('dodge', (len(trace), nt) == (rolls, got_t),
                  dict(where, pred=(len(trace), nt, msg), got=(rolls, got_t)))
            if last:
                tally('dodge_rng', st16(evs[last[-1]]) == st2, dict(where, pred=hex(st2), got=hex(st16(evs[last[-1]]))))
            r1 = trace[0] >> 8 if trace else None
            note(('dodge_branch', None if r1 is None else ('5112' if r1 < 0x33 else '5021' if r1 < 0x66 else
                                                           '5048' if r1 < 0x99 else '506b' if r1 < 0xCC else 'cc')))
            note(('dodge', 'moved' if nt != t else 'stays', 'reroll' if len(trace) > 1 else '',
                  'onto-attacker' if nt == a else '', 'enemy-dodger' if t >= 4 else 'party-dodger'))
        if tag in ('ic_wind', 'ic_magic'):
            b = board(e)
            f7, f8 = e['dcfd'], e['dcfe']
            if tag == 'ic_wind':
                pred = (not e['dd6c']) and F.wind_reflects(b, t, sk, f7)
                code = F.RF_WIND
                stop = ('ic_magic', 'ic_end', 'target_fetch') + ACT_STOP
            else:
                pred = (not e['dd6c']) and F.magic_reflects(b, t, f8)
                code = F.RF_MAGIC
                stop = ('ic_end', 'target_fetch') + ACT_STOP
            js = nxt(evs, i, ('rf_swap',), stop)
            got = js is not None and evs[js]['A'] == code
            kind = 'wind' if tag == 'ic_wind' else 'magic'
            tally(kind, pred == got, dict(where, pred=pred, got=got, s4=e['st'][t * 8 + 4]))
            if pred:
                note((kind, 'party-reflector' if t < 4 else 'enemy-reflector',
                      'bounce' if (kind == 'magic' and e['st'][t * 8 + 4] & 2) else '', hex(sk)))
            if pred and got:
                F.consume_reflect(b, t, code)
                tally(kind + '_consume', b.stb(t, 4) == evs[js]['st'][t * 8 + 4],
                      dict(where, pred=b.stb(t, 4), got=evs[js]['st'][t * 8 + 4]))
                jt = nxt(evs, js, ('target_fetch',), ('actor_fetch', 'round_start'))
                if jt is not None:
                    # the original sweep resumes after the reflected victim
                    jn = nxt(evs, jt, ('target_fetch',), ACT_STOP)
                    single = (e['dcfc'] & 3) == 1
                    later = [x for x in range(t + 1, (t & 4) + 3) if b.valid(x)]
                    pred_n = None if (single or not later) else (a, later[0])
                    got_n = None if jn is None else (evs[jn]['db88'], evs[jn]['db89'])
                    if not (got_n is not None and got_n[0] != a):    # (a nested re-cast: not this check)
                        tally('reflect_resume', pred_n == got_n, dict(where, pred=pred_n, got=got_n))
                    pt = B.guard_redirect(b, a, f8)
                    tally('reflect_tgt', (evs[jt]['db88'], evs[jt]['db89']) == (t, pt),
                          dict(where, pred=(t, pt), got=(evs[jt]['db88'], evs[jt]['db89'])))
                    # the reflected record roll, attacker = reflector
                    jr = nxt(evs, jt, ('roll_in',), ('target_fetch',) + ACT_STOP)
                    jf = nxt(evs, jr, ('final_54e7',), ('target_fetch',) + ACT_STOP) if jr else None
                    if jr is not None and jf is not None and B.damage_core(sk, RECORDS.get(sk)) == 'record':
                        br = board(evs[jr])
                        ctx = B.ActionCtx(b=br, a=evs[jr]['db88'], sk=sk, rec=RECORDS.get(sk), f=fields(sk),
                                          core='record', t=evs[jr]['db89'], qt=evs[jr]['db89'],
                                          state=st16(evs[jr]), records=RECORDS, log=[], idle=None, real_sk=sk)
                        kd, dm, _ = B.core_damage(ctx, evs[jr]['db89'], 1, st16(evs[jr]))
                        tally('reflect_dmg', dm == evs[jf]['db56'],
                              dict(where, pred=dm, got=evs[jf]['db56'], att=evs[jr]['db88']))
        # ------------------------------------------------ TakeMagic
        if tag == 'tm_apply':
            b = board(e)
            f = rt_fields(e)
            ok = (not e['dd6c'] and not e['dd6e'] and b.valid(t) and (b.stb(t, 4) & 1)
                  and (f.get('flags9', 0) & 1))
            g = F.takemagic_gain(b, t, f.get('mp_cost_byte', 0)) if ok else 0
            jn = nxt(evs, i, ('target_fetch', 'rf_restore', 'actor_fetch', 'im_check', 'round_start', 'p9_slot'))
            if jn is not None:
                tally('takemagic', evs[jn]['mp'][t] == b.mp[t] + g,
                      dict(where, pred=b.mp[t] + g, got=evs[jn]['mp'][t], gain=g))
                note(('takemagic', 'capped' if g < f.get('mp_cost_byte', 0) else 'full',
                      'enemy-tm' if t >= 4 else 'party-tm'))
        if tag == 'apply_in':
            b = board(e)
            if (b.stb(t, 4) & 1) and (e['dcff'] & 1) and not e['dd6c'] and not e['dd6e'] and e['db56'] > 0:
                jn = nxt(evs, i, ('tm_apply',), ('target_fetch', 'im_check') + ACT_STOP)
                hp_after = e['hp'][t] - e['db56']
                if hp_after > 0:
                    tally('tm_occur', jn is not None, dict(where, dmg=e['db56']))
        # ------------------------------------------------ Imitate
        if tag == 'im_check':
            b = board(e)
            f = rt_fields(e)
            pred = F.imitate_gate(b, a, t, sk, f, e['dd6e'], e['dd6c'])
            jr = nxt(evs, i, ('rf_save',), ('target_fetch', 'im_check', 'rf_restore') + ACT_STOP)
            got = jr is not None and evs[jr]['A'] == F.RF_IMITATE
            # was this victim a miss (no apply / handler)?
            k = i
            while k > 0 and evs[k]['tag'] != 'target_fetch':
                k -= 1
            vs = [evs[x]['tag'] for x in range(k, i)]
            missed = any(x in vs for x in ('miss', 'dodge', 'block')) or 'h_ret' not in vs
            kind = 'imitate_miss' if missed else 'imitate'
            if F.g8(b, t) & 0x08 and t != a:
                note((kind, pred, got, 'enemy-imitator' if t >= 4 else 'party-imitator', hex(sk)))
            tally(kind, (pred == 'recast') == got, dict(where, pred=pred, got=got, dd6e=e['dd6e'], dd6c=e['dd6c']))
            if got:
                cost = f.get('mp_cost_byte', 0)
                veto = B.act_mp_veto(b, t, sk, cost, e['dcfd'])
                if veto is not None:
                    # SetupSub_480e on the imitator: no re-cast ($DD6C := $20);
                    # the seal paths still pay (LoadBtlC_4a04)
                    jt = nxt(evs, jr, ('target_fetch', 'rf_restore'), ('actor_fetch', 'round_start'))
                    paid = veto not in ('mp', 0x1F)
                    pm = (b.mp[t] - cost) & 0xFFFF if paid else b.mp[t]
                    ok = jt is not None and evs[jt]['tag'] == 'rf_restore' and evs[jt]['mp'][t] == pm
                    tally('imitate_veto', ok, dict(where, veto=veto, pred=pm,
                                                   got=None if jt is None else (evs[jt]['tag'], evs[jt]['mp'][t])))
                    note(('imitate_veto', veto))
                    continue
                jt = nxt(evs, jr, ('target_fetch',), ('actor_fetch', 'round_start'))
                if jt is not None:
                    single = bool(e['dcfc'] & 1)
                    pt = a if single else F.first_live(b, (t & 4) ^ 4)
                    pt = B.guard_redirect(b, pt, e['dcfe'])
                    tally('imitate_tgt', (evs[jt]['db88'], evs[jt]['db89']) == (t, pt),
                          dict(where, pred=(t, pt), got=(evs[jt]['db88'], evs[jt]['db89'])))
                    fs = [x for x in span(evs, jt, ACT_STOP) if evs[x]['tag'] == 'target_fetch']
                    back = next(((evs[x]['db88'], evs[x]['db89']) for x in fs if evs[x]['db88'] != t), None)
                    later = [x for x in range(t + 1, (t & 4) + 3) if b.valid(x)]
                    pred_n = None if (single or not later) else (a, later[0])
                    tally('imitate_resume', back == pred_n, dict(where, pred=pred_n, got=back))
                    tally('imitate_mp', evs[jt]['mp'][t] == (b.mp[t] - cost) & 0xFFFF,
                          dict(where, pred=b.mp[t] - cost, got=evs[jt]['mp'][t]))
        # ------------------------------------------------ act-time target
        if tag == 'skill_load':
            jt = nxt(evs, i, ('target_fetch',), ACT_STOP)
            if jt is None:
                continue
            ft = evs[jt]
            fsk = ft['db8a']
            if fsk not in F.F6_IDS:
                continue
            b = board(e)
            aa = ft['db88']
            qt = e['dcec'][aa * 2 + 1]
            jr = nxt(evs, i, ('reresolve',), ('target_fetch',))
            state = st16(evs[jr]) if jr is not None else st16(ft)
            pt, _ = F.act_target(b, aa, fsk, qt, fields(fsk), state)
            tally('act_target', pt == ft['db89'], dict(where, sk=hex(fsk), a=aa, qt=qt, pred=pt, got=ft['db89']))
            note(('act_target', hex(fsk), 'reresolve' if jr is not None else 'kept'))
        # ------------------------------------------------ phase 9
        if tag == 'p9_slot' and i > 0 and evs[i - 1]['tag'] != 'p9_slot':
            pre = evs[i - 1]
            b = board(pre)
            B.phase9_decay(b)
            F.phase9_f6(b, 0, [])
            tally('phase9', view(b) == eview(e),
                  dict(where, diff=[(n, b.st[n], e['st'][n]) for n in range(64) if b.st[n] != e['st'][n]],
                       ext=(view(b)[1:], eview(e)[1:]), pre=pre['tag']))


def main():
    op = gzip.open if CORPUS.endswith('.gz') else open
    evs = json.load(op(CORPUS, 'rt'))
    by = {}
    for e in evs:
        by.setdefault(e['sc'], []).append(e)
    for sc, ev in by.items():
        check_battle(sc, ev)
    n = sum(v[0] + v[1] for v in stats.values()); m = sum(v[1] for v in stats.values())
    for k, (ok, bad) in sorted(stats.items()):
        print(f'  {k:14s} {ok:5d} ok {bad:4d} mismatch')
    if '-c' in sys.argv:
        for k, v in sorted(cover.items(), key=lambda kv: str(kv[0])):
            print('  cover', k, v)
    print(f'battles {len(by)}; TOTAL {n} comparisons, {m} mismatches')
    if not VERBOSE:
        for f in fails[:25]:
            print('FAIL', f)
    sys.exit(1 if m else 0)


if __name__ == '__main__':
    main()
