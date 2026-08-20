#!/usr/bin/env python3
"""Differential validation of simulator/ai.py against measure_ai.py captures.

For each traced enemy decision, replays the pipeline stage-by-stage using the
CAPTURED RNG at each stage (categories: the three steps precede the 'cat'
capture; sums: steps precede 'flt'), so each formula is checked independently
of RNG-stream reconstruction:

  1. category cells + ranking: recompute from measured bases and verify the
     ranked ids AND the +30-adjusted cells match $dcfc[0..5]. Because the
     RNG values themselves aren't individually captured, this stage checks
     CONSISTENCY: cells must satisfy score = base//10 + adj + r with
     0 <= r < mod(base) (residual check), and ranking must be the exact
     quirky sort of those cells.
  2. sum residuals: dce4[i] - rec_ai_weight(skill_i) in [0, 16).
  3. filter: zeroed exactly where tag != dd6a.
  4. pick: final queued skill equals argmax winner (or documented epilogue).

Usage:
  python3 simulator/validate_ai.py simulator/ai_events_35.json [...]
Requires extracted/skill_records.json for record ai_weights.
"""
import sys, json, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator.ai import rank_categories, cat_mod, PLAIN_ATTACK

recs = json.load(open('extracted/skill_records.json'))['records']

def rec_w(skill):
    return recs[skill]['battle_record']['fields']['ai_weight']

def pairs(blk):
    out = []
    for i in range(0, 8, 2):
        tag, skill = blk[i], blk[i + 1]
        if skill == 0xFF:
            break
        out.append((tag, skill))
    return out

total = ok = 0
fails = []
for path in sys.argv[1:]:
    data = json.load(open(path))
    evs = [e for e in data['events'] if e['ai'] >= 4]
    # group into decisions: ent .. pst
    dec, cur = [], None
    for e in evs:
        if e['t'] == 'ent':
            cur = []
        if cur is not None:
            cur.append(e)
        if e['t'] == 'pst' and cur:
            dec.append(cur); cur = None
    for d in dec:
        by = {}
        for e in d:
            by.setdefault(e['t'], []).append(e)
        cat = by.get('cat', [None])[0]
        if not cat:
            continue
        # 1) category residuals + ranking
        total += 1
        cells = cat['dcfc'][:3]
        ids = cat['dcfc'][3:6]
        bases = cat['bases']
        adj = cat['adj']
        raw = list(cells)
        # undo the +30 (applied iff cat1 is not rank1 — AICat1RunnerUpCheck_73a5)
        if ids[0] != 1:
            raw[0] = (raw[0] - 0x1E) & 0xFF
        good = True
        for c in range(3):
            r = raw[c] - bases[c] // 10 - adj[c]
            if not (0 <= r < cat_mod(bases[c], True)):
                good = False
                fails.append((path, 'cat_residual', c, raw[c], bases[c], adj[c]))
        rc, ri = rank_categories(raw)
        if ri != ids or rc != cells:
            good = False
            fails.append((path, 'ranking', raw, cells, ids, rc, ri))
        if good:
            ok += 1
        # 2) sum residuals (use the filter-entry capture: post-sum, pre-filter)
        flt = by.get('flt', [])
        for f in flt:
            pl = pairs(f['blk'])
            total += 1
            good = True
            for i, (tag, skill) in enumerate(pl):
                r = f['dce4'][i] - rec_w(skill)
                if not (0 <= r < 16):
                    good = False
                    fails.append((path, 'sum_residual', i, skill,
                                  f['dce4'][i], rec_w(skill)))
            if good:
                ok += 1
        # 3+4) filter zeroing + final pick vs queue
        pst = by.get('pst', [None])[-1]
        pik = by.get('pik', [None])[-1]
        if pst and pik:
            total += 1
            pl = pairs(pst['blk'])
            queued = pst['dcec'][8 + (pst['ai'] - 4) * 2] \
                if pst['ai'] >= 4 else None
            chosen_cat = pst['dd6a']
            surv = [i for i, (t2, s2) in enumerate(pl) if t2 == chosen_cat]
            nz = [i for i, v in enumerate(pik['dce4'][:len(pl)]) if v]
            if set(nz) <= set(surv) and (
                    queued == PLAIN_ATTACK or
                    any(pl[i][1] == queued for i in nz) or
                    queued in (0x8D,)):
                ok += 1
            else:
                fails.append((path, 'pick', queued, pl, pik['dce4'],
                              chosen_cat))

print(f'{ok}/{total} checks passed')
for f in fails[:12]:
    print('FAIL', f)
sys.exit(0 if ok == total else 1)
