#!/usr/bin/env python3
"""build_balance_anchor.py — the original game's difficulty curve, read-only
(S130, ROADMAP P3.15a; EDITOR_DESIGN §5.9, PROJECT_COMPILER §2.43).

Writes extracted/balance_vanilla.json, read by the editor's Balance tab
(editor2/core/balance.py load_anchor): for every key fight of the story —
each gate's floor lists (in runs), each boss fight, every arena match, Starry
Night, Monster Grandpa — and for the three team profiles ('casual', 'strong'
on their AI; 'player' = the step's optimised skill kit under the player's
orders / the best tactic in the arena, S130 P3.15b — the kit of every step is
stored under steps[i]['kit'], editor2/core/kits.py):

  l90 / l50  the smallest team level whose rolled teams win >= 90 % / >= 50 %
             (None = not even at 99), with the evaluation at l90 (win,
             rounds, HP left, team level actually reached, the share of
             actions the simulator does not model);

and for every gate, the dive (its floors in a row without healing, then the
boss) at both walk bounds ('direct' = straight to the stairs, 'sweep' = the
whole floor): the level for 90 % clears.

Everything comes from editor2/core/balance.py on the ORIGINAL game data
(BattleData(None)), deterministic (stable seeds), so:

  python3 tools/build_balance_anchor.py              # build (every CPU core; hours on 2 cores,
          # resumable: finished units go to balance_vanilla.json.partial — re-run to continue;
          # the editor's Balance tab has a button for it)
  python3 tools/build_balance_anchor.py --jobs N
  python3 tools/build_balance_anchor.py --only casual
  python3 tools/build_balance_anchor.py --only player   # just the kits + 'player'
  (every run appends to extracted/balance_vanilla.build.log: platform, progress, each
   failed unit's traceback — a failed unit no longer stops the others, S131)
  python3 tools/build_balance_anchor.py --selftest   # JSON well-formed, every
          # story fight present, the simulator version + raising digest match,
          # every step has its kit, three cheap fights + one dive re-derived
          # == the JSON, and one cheap step's 'player' numbers re-derived from
          # its stored kit (verifier check 5)
"""
import json
import os
import sys
import time
from multiprocessing import Pool

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
OUT = os.path.join(REPO, 'extracted', 'balance_vanilla.json')
PARTIAL = OUT + '.partial'      # finished units of an interrupted build (removed when done)
LOG = os.path.join(REPO, 'extracted', 'balance_vanilla.build.log')   # S131: every build's log
#   (appended: platform, every line printed, every failed unit's traceback, worker crashes)
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'
PROFILES = ('casual', 'strong', 'player')
SELFTEST_PLAYER = ('gate0.boss0', 'arena0.m0')     # cheap steps: the kit from the JSON
SELFTEST_FIGHTS = ('gate0.f1', 'gate0.boss0', 'arena0.m0')
SELFTEST_DIVE = 0

_D = _TL = None


def _ctx():
    global _D, _TL
    if _D is None:
        from editor2.core import balance as BL
        _D = BL.BattleData(None)
        _TL = BL.Timeline(_D)
    return _D, _TL


def _slim(ev):
    return {k: (round(v, 4) if isinstance(v, float) else v) for k, v in ev.items()}


def log(msg):
    """Print and append to LOG (S131: the Balance tab's button showed only
    "Stopped" — the log keeps what happened)."""
    print(msg, flush=True)
    try:
        with open(LOG, 'a') as f:
            f.write(time.strftime('%H:%M:%S ') + msg + '\n')
    except OSError:
        pass


def _worker_init():
    """Each worker: a hard crash (segfault, abort) dumps its Python stack into LOG."""
    import faulthandler
    try:
        f = open(LOG, 'a')
        f.write(f'{time.strftime("%H:%M:%S")} worker {os.getpid()} started\n')
        f.flush()
        faulthandler.enable(file=f, all_threads=True)
        globals()['_FH'] = f                     # keep the file open
    except OSError:
        pass


def safe_work(unit):
    """work(unit), with an exception returned as text instead of killing the
    pool (S131): the other units keep building; the failure is logged."""
    import traceback
    t = time.time()
    try:
        return work(unit) + (None,)
    except Exception:                                       # noqa: BLE001
        return unit[0], unit[1], None, time.time() - t, traceback.format_exc()


def work(unit):
    """unit = (step index, profile) -> results of that step's fights + dive."""
    from editor2.core import balance as BL
    si, prof = unit
    D, TL = _ctx()
    st = TL.steps[si]
    t = time.time()
    out = {'fights': {}, 'dive': None, 'kit': None}
    if prof == 'player':
        out['kit'] = BL.get_kit(D, TL, si, log=lambda m: print(f'  [{st["label"]}] {m}',
                                                                flush=True))
    for k in st['fights']:
        r = BL.fight_levels(D, TL, TL.fights[k], prof)
        out['fights'][k] = {'l90': r['l90'], 'l50': r['l50'], 'at90': _slim(r['at90'])}
    if st['kind'] == 'gate':
        dv = {}
        for walk in BL.WALKS:
            lv, ev = BL.dive_level_needed(D, TL, st['id'], prof, walk=walk)
            dv[walk] = {'level': lv, 'eval': _slim(ev)}
        out['dive'] = dv
    BL._TEAMS.clear()
    BL._KITS.clear()
    return si, prof, out, time.time() - t


def skeleton():
    from editor2.core import balance as BL
    D, TL = _ctx()
    steps = [{'index': s['index'], 'kind': s['kind'], 'id': s['id'], 'label': s['label'],
              'postgame': s['postgame'], 'breeding': s['breeding'], 'fights': s['fights']}
             for s in TL.steps]
    fights = {}
    for k, f in TL.fights.items():
        st = TL.steps[f['step']] if f['step'] is not None else None
        fights[k] = {'step': f['step'], 'step_label': st['label'] if st else '',
                     'kind': f['kind'], 'label': f['label'], 'db73': f['db73'],
                     'groups': [[round(p, 4), list(e)] for p, e in f['groups']],
                     'enemies': {str(e): [D.enemy_name(e), D.T.enemy(e)[4]]
                                 for e in f['eids']}}
    return {
        '_generator': (f'tools/build_balance_anchor.py (S130) from the original game data '
                       f'(disassembly of data/DWM-original.gbc {ORIGINAL_MD5}) through '
                       f'editor2/core/balance.py + simulator/ (raising.py, pacing.py, battle.py)'),
        'version': BL.ANCHOR_VERSION, 'sim_version': BL.SIM_VERSION,
        'raising_digest': BL.raising_digest(D),
        'targets': [BL.WIN_TARGET, BL.WIN_HALF], 'ref_curve': BL.REF_CURVE,
        'breeding_opens': TL.breeding_opens, 'steps': steps, 'fights': fights, 'dives': {}}


def build(jobs=2, only=None):
    doc = skeleton()
    D, TL = _ctx()
    profs = [only] if only else list(PROFILES)
    if only and os.path.exists(OUT):
        old = json.load(open(OUT))
        for k, f in old.get('fights', {}).items():
            for p in PROFILES:
                if p != only and p in f and k in doc['fights']:
                    doc['fights'][k][p] = f[p]
        for g, dv in old.get('dives', {}).items():
            for p in PROFILES:
                if p != only and p in dv:
                    doc['dives'].setdefault(g, {})[p] = dv[p]
        if only != 'player':
            for st, ost in zip(doc['steps'], old.get('steps', [])):
                if ost.get('kit') and ost.get('index') == st['index']:
                    st['kit'] = ost['kit']
    units = [(s['index'], p) for p in profs for s in TL.steps]
    units.sort(key=lambda u: (-(u[1] == 'player'), -(u[1] == 'strong'), -u[0]))   # heaviest first

    def apply(si, prof, out):
        for k, v in out['fights'].items():
            doc['fights'][k][prof] = v
        if out['dive'] is not None:
            doc['dives'].setdefault(str(TL.steps[si]['id']), {})[prof] = out['dive']
        if out.get('kit') is not None:
            doc['steps'][si]['kit'] = out['kit']
    # resumable: every finished unit is appended to PARTIAL (one JSON line,
    # tagged with the simulator version + raising digest); a re-run skips them
    tag = [doc['sim_version'], doc['raising_digest']]
    done = set()
    if os.path.exists(PARTIAL):
        for line in open(PARTIAL):
            try:
                r = json.loads(line)
            except ValueError:
                continue
            if r.get('tag') == tag and (r['si'], r['prof']) in set(units):
                apply(r['si'], r['prof'], r['out'])
                done.add((r['si'], r['prof']))
    todo = [u for u in units if u not in done]
    if done:
        log(f'resuming: {len(done)} units from {PARTIAL}')
    t0 = time.time()
    failed = []
    with Pool(jobs, initializer=_worker_init) as pool, open(PARTIAL, 'a') as part:
        for n, (si, prof, out, dt, err) in enumerate(pool.imap_unordered(safe_work, todo), 1):
            if err is not None:
                failed.append((si, prof))
                log(f'[{n + len(done)}/{len(units)}] FAILED {TL.steps[si]["label"]} {prof} '
                    f'after {dt:.0f}s:\n{err}')
                continue
            apply(si, prof, out)
            part.write(json.dumps({'tag': tag, 'si': si, 'prof': prof, 'out': out}) + '\n')
            part.flush()
            log(f'[{n + len(done)}/{len(units)}] {TL.steps[si]["label"]} {prof} {dt:.0f}s '
                f'(total {time.time() - t0:.0f}s)')
    if failed:
        log(f'NOT FINISHED: {len(failed)} unit(s) failed (tracebacks above, in {LOG}); the '
            f'{len(units) - len(failed)} finished units are kept in {PARTIAL} — send the log')
        return 2
    tmp = OUT + '.tmp'
    json.dump(doc, open(tmp, 'w'), indent=1)
    os.replace(tmp, OUT)
    os.remove(PARTIAL)
    log(f'wrote {OUT}')
    return 0


def selftest():
    from editor2.core import balance as BL
    if not os.path.exists(OUT):
        print('FAIL: missing', OUT)
        return 1
    doc = json.load(open(OUT))
    D, TL = _ctx()
    bad = []
    if doc.get('sim_version') != BL.SIM_VERSION and os.path.exists(PARTIAL):
        # a rebuild for the current simulator is in progress (resumable): the
        # saved units must belong to it; the finished JSON is checked once built
        tag = [BL.SIM_VERSION, BL.raising_digest(D)]
        n = 0
        for line in open(PARTIAL):
            if line.strip():
                if json.loads(line).get('tag') != tag:
                    print('FAIL: balance_vanilla.json.partial holds units of another simulator version')
                    return 1
                n += 1
        print(f'SKIP: the anchor is being rebuilt for {BL.SIM_VERSION} ({n} units saved in '
              f'{os.path.basename(PARTIAL)}); run the build (or the Balance tab button) to finish')
        return 0
    if doc.get('sim_version') != BL.SIM_VERSION:
        bad.append(f"sim_version {doc.get('sim_version')} != {BL.SIM_VERSION} (rebuild the anchor)")
    if doc.get('raising_digest') != BL.raising_digest(D):
        bad.append('raising digest differs (vanilla tables changed? rebuild)')
    for k in TL.fights:
        f = doc['fights'].get(k)
        if f is None:
            bad.append(f'fight {k} missing')
            continue
        for p in PROFILES:
            if p not in f:
                bad.append(f'{k} has no {p} result')
    for s in TL.steps:
        if not (doc['steps'][s['index']] or {}).get('kit'):
            bad.append(f'step {s["index"]} ({s["label"]}) has no kit')
        if s['kind'] == 'gate':
            dv = doc['dives'].get(str(s['id']), {})
            for p in PROFILES:
                if p not in dv:
                    bad.append(f'gate {s["id"]} dive has no {p}')
    if not bad:
        for k in SELFTEST_FIGHTS:
            r = BL.fight_levels(D, TL, TL.fights[k], 'casual')
            j = doc['fights'][k]['casual']
            if (r['l90'], r['l50'], _slim(r['at90'])) != (j['l90'], j['l50'], j['at90']):
                bad.append(f'{k} casual re-derived {r["l90"]}/{r["l50"]} != JSON {j["l90"]}/{j["l50"]}')
        lv, ev = BL.dive_level_needed(D, TL, SELFTEST_DIVE, 'casual', walk='direct')
        j = doc['dives'][str(SELFTEST_DIVE)]['casual']['direct']
        if (lv, _slim(ev)) != (j['level'], j['eval']):
            bad.append(f'dive {SELFTEST_DIVE} re-derived {lv} != JSON {j["level"]}')
        for k in SELFTEST_PLAYER:
            si = TL.fights[k]['step']
            BL.set_kit(D, TL, si, doc['steps'][si]['kit'])
            r = BL.fight_levels(D, TL, TL.fights[k], 'player')
            j = doc['fights'][k]['player']
            if (r['l90'], r['l50'], _slim(r['at90'])) != (j['l90'], j['l50'], j['at90']):
                bad.append(f'{k} player re-derived {r["l90"]}/{r["l50"]} != JSON {j["l90"]}/{j["l50"]}')
    if bad:
        for b in bad[:20]:
            print('FAIL:', b)
        return 1
    print(f'selftest OK: {len(doc["fights"])} fights x {len(PROFILES)} profiles, '
          f'{len(doc["dives"])} gate dives, {len(doc["steps"])} kits; {len(SELFTEST_FIGHTS)} '
          f'fights + 1 dive + {len(SELFTEST_PLAYER)} player fights (stored kits) re-derived')
    return 0


def main(argv):
    if '--selftest' in argv:
        return selftest()
    jobs = int(argv[argv.index('--jobs') + 1]) if '--jobs' in argv else 0
    if jobs <= 0:
        jobs = os.cpu_count() or 2                      # default: every core
    # a stop request (the editor's Stop button, kill -TERM) ends the pool's
    # workers too; finished units are already in PARTIAL (resumable)
    import signal
    signal.signal(signal.SIGTERM, lambda *_a: sys.exit(1))
    import platform
    log(f'=== build {time.strftime("%Y-%m-%d")} — python {platform.python_version()} '
        f'({sys.executable}), {platform.platform()}, {os.cpu_count()} cores')
    log(f'building with {jobs} processes')
    only = argv[argv.index('--only') + 1] if '--only' in argv else None
    try:
        return build(jobs, only)
    except SystemExit:
        log('stopped (a stop request)')
        raise
    except BaseException:                                   # noqa: BLE001
        import traceback
        log('CRASHED:\n' + traceback.format_exc())
        return 3


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
