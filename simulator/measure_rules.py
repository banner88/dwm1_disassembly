#!/usr/bin/env python3
"""S81 rule-chain measurement rig: instruments the bank $57 state-7 evaluator
walker so every RULE INVOCATION is captured with its ($DD26,$DD27) delta.

Decoded S81 (falsifies the S80 "indexed by effect_class" hypothesis):
  - $57:$4302 = 3 dw -> chain bases $4308 (cat1) / $4358 (cat2) / $4404 (cat3)
  - each chain is a $0000-terminated dw list of rule routines; the WHOLE
    category chain runs for every tag-matched skill; rules self-select
    (typically on $DD6B = record field +7 usability bits, statuses, HP).
  - state-7 walker $57:$7865: per rule, call [chain]; $DD27==$FF -> VETO
    (zero the option's $DCE4 cell, back to state 4). At chain end $78A2:
    delta = $DD26 - $DD27 (borrow -> zero cell), dce4[i] += delta (8-bit).
  - ClearBattleAction ($57:$45E5) = the veto writer ($DD27:=$FF).

Hooks (state-7 only; never per-frame-polled):
  $7865 skill-entry ctx | $7874 rule call (HL=chain cursor, pre 26/27)
  $7877 rule ret (post 26/27) | $78A2 chain end | $788B veto path

Usage:
  python3 simulator/measure_rules.py --rom R --state S --eid N
      [--ecount N] [--frames N] [--ehp N] [--php N] [--pstatus 0xNN]
      [--estatus 0xNN] [--out FILE]
Hook-safety: dense 4-on/4-off cadence (PYBOY_DEBUGGING S80).
"""
import sys, json, argparse, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import boot

ap = argparse.ArgumentParser()
ap.add_argument('--rom', required=True)
ap.add_argument('--state', required=True)
ap.add_argument('--eid', type=int, required=True)
ap.add_argument('--ecount', type=int, default=1)
ap.add_argument('--frames', type=int, default=1800)
ap.add_argument('--max-events', type=int, default=1200)
ap.add_argument('--ehp', type=int)      # force enemy slot-4 HP AND MaxHP
ap.add_argument('--ehp-cur', type=int)  # force enemy slot-4 CURRENT HP only
ap.add_argument('--php', type=int)      # force party slot-0 HP AND MaxHP
ap.add_argument('--php-cur', type=int)  # force party slot-0 CURRENT HP only
ap.add_argument('--ebase', type=str)    # force enemy cat bases 'c1,c2,c3'
ap.add_argument('--elist', type=str)    # force enemy option list 'tag:skill,..'
                                        # (poked per-frame once battle is live)
ap.add_argument('--pmp', type=int)      # force party slot-0 MP/MaxMP
ap.add_argument('--emp', type=int)      # force enemy slot-4 MP/MaxMP
ap.add_argument('--pstatus', type=str)  # party slot0: 'off:val[,off:val]' hex ok
ap.add_argument('--estatus', type=str)  # enemy slot4: same format
ap.add_argument('--out', default=None)
a = ap.parse_args()

p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)

ev = []
HP, MHP, MP, MMP = 0xDBA3, 0xDBB3, 0xDBC3, 0xDBD3


def board():
    m = p.memory
    return dict(
        hp=[m[HP + i * 2] | (m[HP + 1 + i * 2] << 8) for i in range(8)],
        mhp=[m[MHP + i * 2] | (m[MHP + 1 + i * 2] << 8) for i in range(8)],
        mp=[m[MP + i * 2] | (m[MP + 1 + i * 2] << 8) for i in range(8)],
        st=[[m[0xDB00 + s * 8 + k] for k in range(8)] for s in range(8)],
        alive=[m[0xDD13 + i] for i in range(8)])


def cap(tag, extra=None):
    if len(ev) >= a.max_events:
        return
    m = p.memory
    e = dict(t=tag, ai=m[0xDB88], skill=m[0xDB8A], dd6a=m[0xDD6A],
             dd6b=m[0xDD6B], c1fc=m[0xC1FC],
             dd26=m[0xDD26], dd27=m[0xDD27],
             rng=[m[0xC899], m[0xC89A]], frame=p.frame_count)
    if extra:
        e.update(extra)
    ev.append(e)


def h_skill(_):
    cap('skl', dict(chain=p.memory[0xC1FA] | (p.memory[0xC1FB] << 8),
                    board=board()))


def h_call(_):
    hl = p.register_file.HL
    lo, hi = p.memory[hl], p.memory[hl + 1]
    cap('rul', dict(cur=hl, rule=lo | (hi << 8)))


def h_ret(_):
    cap('ret')


def h_end(_):
    cap('end', dict(dce4=[p.memory[0xDCE4 + i] for i in range(8)]))


def h_veto(_):
    cap('vet')


for addr, cb in [(0x7865, h_skill), (0x7874, h_call), (0x7877, h_ret),
                 (0x78A2, h_end), (0x788B, h_veto)]:
    p.hook_register(0x57, addr, cb, None)

m = p.memory
m[0xDA03] = a.eid & 0xFF
m[0xDA04] = (a.eid >> 8) & 0xFF
m[0xDA02] = (a.ecount - 1) & 3
if a.ecount > 1:
    m[0xDA05], m[0xDA06] = m[0xDA03], m[0xDA04]
if a.ecount > 2:
    m[0xDA07], m[0xDA08] = m[0xDA03], m[0xDA04]
m[0xDA09] = 1
m[0xC905] = 0
m[0xC8EB] |= 0x40

forced = False
for i in range(a.frames):
    if len(ev) >= a.max_events:
        break
    if i % 8 < 4:
        p.button_press('a')
    else:
        p.button_release('a')
    p.tick()
    # apply stat forces once battle RAM is live (enemy slot filled)
    if not forced and m[HP + 8] | (m[HP + 9] << 8):
        def setw(base, slot, v):
            m[base + slot * 2] = v & 0xFF
            m[base + slot * 2 + 1] = v >> 8
        if a.ehp is not None:
            setw(HP, 4, a.ehp); setw(MHP, 4, a.ehp)
        if a.ehp_cur is not None:
            setw(HP, 4, a.ehp_cur)
        if a.php is not None:
            setw(HP, 0, a.php); setw(MHP, 0, a.php)
        if a.php_cur is not None:
            setw(HP, 0, a.php_cur)
        if a.ebase is not None:
            c1, c2, c3 = (int(x) for x in a.ebase.split(','))
            m[0xDC44 + 4] = c1; m[0xDC4C + 4] = c2; m[0xDC54 + 4] = c3
        if a.pmp is not None:
            setw(MP, 0, a.pmp); setw(MMP, 0, a.pmp)
        if a.emp is not None:
            setw(MP, 4, a.emp); setw(MMP, 4, a.emp)
        def stat(spec, slot):
            for pair in spec.split(','):
                off, val = pair.split(':')
                m[0xDB00 + slot * 8 + int(off, 0)] = int(val, 0)
        if a.pstatus is not None:
            stat(a.pstatus, 0)
        if a.estatus is not None:
            stat(a.estatus, 4)
        forced = True
    if forced and a.elist is not None:
        # option list slot 4: pairs at $DC64+4*16 (tag even, skill odd)
        base = 0xDC64 + 4 * 16
        pairs = [pr.split(':') for pr in a.elist.split(',')]
        for k in range(4):
            if k < len(pairs):
                m[base + k * 2] = int(pairs[k][0], 0)
                m[base + k * 2 + 1] = int(pairs[k][1], 0)
            else:
                m[base + k * 2] = 0
                m[base + k * 2 + 1] = 0xFF
    if forced and a.ebase is not None:
        c1, c2, c3 = (int(x) for x in a.ebase.split(','))
        m[0xDC44 + 4] = c1; m[0xDC4C + 4] = c2; m[0xDC54 + 4] = c3

out = a.out or f'/home/claude/trace/rules_{a.eid}.json'
json.dump(dict(eid=a.eid, args=vars(a), events=ev), open(out, 'w'))
print(f'EID {a.eid}: {len(ev)} events -> {out}')
