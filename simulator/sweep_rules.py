#!/usr/bin/env python3
"""S81 rule sweep: run every skill through its category's evaluator chain by
forcing the enemy option list, capturing per-rule ($DD26,$DD27) deltas.

One pyboy process; boot.state reloaded per batch of 4 skills. Only categories
1/2/3 are sweepable (the machine's dd6a never selects 4/5/6/8).

Usage:
  python3 simulator/sweep_rules.py --rom R --state S [--cats 1,2,3]
      [--skills 3,4,5] [--board clean|psleep|ppoison|ehurt|allydead|lowmp]
      [--out FILE] [--limit N]
"""
import sys, json, argparse, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import boot

ap = argparse.ArgumentParser()
ap.add_argument('--rom', required=True)
ap.add_argument('--state', required=True)
ap.add_argument('--cats', default='1,2,3')
ap.add_argument('--skills', default=None)  # explicit id list; else all
ap.add_argument('--board', default='clean')
ap.add_argument('--out', default=None)
ap.add_argument('--limit', type=int, default=0)
ap.add_argument('--eid', type=int, default=7)
ap.add_argument('--ecount', type=int, default=1)
ap.add_argument('--frames', type=int, default=700)
a = ap.parse_args()

recs = json.load(open(os.path.join(os.path.dirname(__file__), '..',
                                   'extracted', 'skill_records.json')))
recs = recs if isinstance(recs, list) else recs['records']
bymap = {}
for r in recs:
    if r.get('battle_record'):
        bymap[r['id']] = r['battle_record']['fields']['effect_category'] >> 4

want_cats = set(int(c) for c in a.cats.split(','))
if a.skills:
    todo = [(int(s), bymap[int(s)]) for s in a.skills.split(',')]
else:
    todo = sorted((sid, c) for sid, c in bymap.items() if c in want_cats)
if a.limit:
    todo = todo[:a.limit]

p = boot(a.rom)
state_bytes = open(a.state, 'rb').read()
import io

ev = []
HP, MHP, MP, MMP = 0xDBA3, 0xDBB3, 0xDBC3, 0xDBD3


def cap(tag, extra=None):
    m = p.memory
    e = dict(t=tag, ai=m[0xDB88], skill=m[0xDB8A], dd6a=m[0xDD6A],
             dd6b=m[0xDD6B], c1fc=m[0xC1FC], dd26=m[0xDD26], dd27=m[0xDD27])
    if extra:
        e.update(extra)
    ev.append(e)


def h_skill(_):
    m = p.memory
    cap('skl', dict(
        hp=[m[HP + i * 2] | (m[HP + 1 + i * 2] << 8) for i in range(8)],
        mhp=[m[MHP + i * 2] | (m[MHP + 1 + i * 2] << 8) for i in range(8)],
        mp=[m[MP + i * 2] | (m[MP + 1 + i * 2] << 8) for i in range(8)],
        st=[[m[0xDB00 + s * 8 + k] for k in range(8)] for s in range(8)]))


def h_call(_):
    hl = p.register_file.HL
    cap('rul', dict(rule=p.memory[hl] | (p.memory[hl + 1] << 8)))


def h_ret(_):
    cap('ret')


def h_end(_):
    cap('end')


def h_veto(_):
    cap('vet')


for addr, cb in [(0x7865, h_skill), (0x7874, h_call), (0x7877, h_ret),
                 (0x78A2, h_end), (0x788B, h_veto)]:
    p.hook_register(0x57, addr, cb, None)


def apply_board(m, name):
    def setw(base, slot, v):
        m[base + slot * 2] = v & 0xFF
        m[base + slot * 2 + 1] = v >> 8
    setw(MP, 4, 250); setw(MMP, 4, 250)   # never MP-veto by accident
    if name == 'psleep':
        m[0xDB02] = 0x8C
    elif name == 'ppoison':
        m[0xDB02] = 0x01
    elif name == 'epoison':
        m[0xDB00 + 4 * 8 + 2] = 0x01
    elif name == 'eparalyze':
        m[0xDB00 + 4 * 8 + 2] = 0x40
    elif name == 'econfusion':
        m[0xDB00 + 4 * 8 + 2] = 0x10
    elif name == 'ecurse':
        m[0xDB00 + 4 * 8 + 2] = 0x20
    elif name == 'ehurt':
        setw(MHP, 4, 200); setw(HP, 4, 30)
    elif name == 'phurt':
        setw(MHP, 0, 200); setw(HP, 0, 200)
        setw(HP, 0, 30)
    elif name == 'elowmp':
        setw(MP, 4, 10); setw(MMP, 4, 250)
    elif name == 'lowmp':
        setw(MP, 4, 0); setw(MMP, 4, 250)
    elif name == 'pguard':
        m[0xDB05] = 0x40
    elif name == 'allydead':
        # requires --ecount>=2; kill enemy slot 5
        setw(HP, 5, 0)
    elif name == 'allypara':
        m[0xDB00 + 5 * 8 + 2] = 0x40
    elif name == 'allyconf':
        m[0xDB00 + 5 * 8 + 2] = 0x10
    elif name == 'allyhurt':
        setw(MHP, 5, 200); setw(HP, 5, 30)
    elif name == 'pstopspell':
        m[0xDB03] = 0x01
    # 'clean': nothing extra


results = {}
for batch_start in range(0, len(todo), 4):
    batch = todo[batch_start:batch_start + 4]
    # all four must share a category so one forced base covers them; split
    by_cat = {}
    for sid, c in batch:
        by_cat.setdefault(c, []).append(sid)
    for cat, sids in by_cat.items():
        p.load_state(io.BytesIO(state_bytes))
        m = p.memory
        m[0xDA03], m[0xDA04] = a.eid & 0xFF, (a.eid >> 8) & 0xFF
        m[0xDA02] = (a.ecount - 1) & 3
        if a.ecount > 1:
            m[0xDA05], m[0xDA06] = m[0xDA03], m[0xDA04]
        if a.ecount > 2:
            m[0xDA07], m[0xDA08] = m[0xDA03], m[0xDA04]
        m[0xDA09] = 1
        m[0xC905] = 0
        m[0xC8EB] |= 0x40
        ev.clear()
        live = False
        target = len(sids)
        for i in range(a.frames):
            got = sum(1 for e in ev if e['t'] == 'skl')
            if got >= target and ev and ev[-1]['t'] in ('end', 'vet'):
                break
            if i % 8 < 4:
                p.button_press('a')
            else:
                p.button_release('a')
            p.tick()
            if not live and (m[HP + 8] | (m[HP + 9] << 8)):
                live = True
            if live:
                apply_board(m, a.board)
                for slot in range(4, 4 + a.ecount):
                    base = 0xDC64 + slot * 16
                    for k in range(4):
                        if k < len(sids):
                            m[base + k * 2] = cat
                            m[base + k * 2 + 1] = sids[k]
                        else:
                            m[base + k * 2] = 0
                            m[base + k * 2 + 1] = 0xFF
                    bases = [0, 0, 0]
                    bases[cat - 1] = 250
                    (m[0xDC44 + slot], m[0xDC4C + slot],
                     m[0xDC54 + slot]) = bases
        # decode traces
        i = 0
        while i < len(ev):
            e = ev[i]
            if e['t'] == 'skl':
                fir = []
                j = i + 1
                while j < len(ev) and ev[j]['t'] != 'skl':
                    x = ev[j]
                    if (x['t'] == 'rul' and j + 1 < len(ev)
                            and ev[j + 1]['t'] in ('ret', 'end', 'vet')):
                        pre = (x['dd26'], x['dd27'])
                        post = (ev[j + 1]['dd26'], ev[j + 1]['dd27'])
                        if post != pre:
                            fir.append([f"{x['rule']:04x}",
                                        post[0] - pre[0], post[1] - pre[1]])
                    elif x['t'] in ('end', 'vet'):
                        fir.append([x['t'], x['dd26'], x['dd27']])
                    j += 1
                key = str(e['skill'])
                if key not in results:
                    results[key] = dict(cat=e['dd6a'], dd6b=e['dd6b'],
                                        fired=fir)
                i = j
            else:
                i += 1
        done = [s for s in sids if str(s) in results]
        print(f'cat{cat} batch {sids}: captured {done}', flush=True)

out = a.out or f'/home/claude/trace/sweep_{a.board}.json'
json.dump(dict(board=a.board, results=results), open(out, 'w'))
print(f'{len(results)}/{len(todo)} skills -> {out}')
