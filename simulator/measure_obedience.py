#!/usr/bin/env python3
"""S87 obedience-gate capture rig: measures the state-0 preamble decide
chain (bank $57) for PARTY slot 0 on the real save, across forced
wBattleLVL values, tactics, and category-base sets.

Waypoints per decision:
  band_in   $57:$7A16  LoadBtlAI_7a16 entry (PRE-RNG state; $db4c/4d/4e set)
  decide_in $57:$7A5D  AIPreambleDecide_7a5d entry (all inputs + $db4f final)
  carry     $57:$6EF4  the instruction after `jp nc,$6f8c` (obey/unbiased)
  nocarry   $57:$6F8C  AIState0AltOutcome_6f8c (tactic-bias path)

Level forcing writes the wBattleLVL word ($DC23+2*slot) every battle frame
after init (the array is stable, but per-frame is cheap and safe); the
tactic goes into the party record's +2 HIGH nibble pre-battle so the real
init copy distributes it ($DD03). Base forcing pokes $DC44/4C/54/5C[0]
once at init (phase<=3, $D9ED>=1 — the S85 rule).

Usage: measure_obedience.py [--rom R] [--state S] [--out FILE]
Runs the standard S87 case matrix; --quick runs a 3-case smoke.
"""
import sys, json, os, argparse
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import *

WLVL = 0xDC23

ap = argparse.ArgumentParser()
ap.add_argument('--rom', default='/home/claude/trace/patched.gbc')
ap.add_argument('--state', default='/home/claude/trace/boot.state')
ap.add_argument('--out', default='simulator/s87_obedience_events.json')
ap.add_argument('--quick', action='store_true')
a = ap.parse_args()


def run_case(level, tactic, bases=None, rounds=8, frames=9000):
    p = boot(a.rom)
    with open(a.state, 'rb') as f:
        p.load_state(f)
    ev = []

    def cap(tag):
        def f(ctx):
            m = p.memory
            ev.append(dict(
                tag=tag, f=p.frame_count, case_lvl=level, case_tac=tactic,
                lvl=m[WLVL] | (m[WLVL + 1] << 8),
                db4c=m[0xDB4C], db4d=m[0xDB4D], db4e=m[0xDB4E],
                db4f=m[0xDB4F], db53=m[0xDB53],
                dd03=m[0xDD03], dd72=m[0xDD72],
                rng1=m[0xC899], rng2=m[0xC89A],
                dc44=m[0xDC44], dc4c=m[0xDC4C],
                dc54=m[0xDC54], dc5c=m[0xDC5C]))
        return f
    p.hook_register(0x57, 0x7A16, cap('band_in'), None)
    p.hook_register(0x57, 0x7A5D, cap('decide_in'), None)
    p.hook_register(0x57, 0x6F8C, cap('nocarry'), None)
    p.hook_register(0x57, 0x6EF4, cap('carry'), None)

    p.memory[0xCACC] = (tactic << 4) | (p.memory[0xCACC] & 0x0F)
    p.memory[0xDA03] = 7; p.memory[0xDA04] = 0; p.memory[0xDA02] = 0
    p.memory[0xDA09] = 1; p.memory[0xC905] = 0; p.memory[0xC8EB] |= 0x40

    started = forced = False
    for i in range(frames):
        m = p.memory
        if m[GAME_MODE] == 2:
            started = True
            if not forced and m[0xD9EC] <= 3 and m[0xD9ED] >= 1:
                forced = True
                m[0xDBA3] = 200; m[0xDBA4] = 0; m[0xDBB3] = 200; m[0xDBB4] = 0
                m[0xDBAB] = 250; m[0xDBAC] = 0; m[0xDBBB] = 250; m[0xDBBC] = 0
                if bases:
                    (m[0xDC44], m[0xDC4C],
                     m[0xDC54], m[0xDC5C]) = bases
            if forced:
                m[WLVL] = level & 0xFF; m[WLVL + 1] = 0
        elif started:
            break
        if sum(1 for e in ev if e['tag'] in ('carry', 'nocarry')) >= rounds:
            break
        if i % 8 < 4:
            p.button_press('a')
        else:
            p.button_release('a')
        p.tick()
    p.stop(save=False)
    return ev


CASES = [  # (level, tactic, bases(dc44,dc4c,dc54,dc5c) or None, rounds)
    # boundaries
    (0x00, 0, None, 3), (0x14, 0, None, 3), (0x15, 0, None, 6),
    (0xEF, 0, None, 6), (0xF0, 0, None, 3),
    # mid-band, stock Slib bases (80/85/186/189), all tactics
    (0x20, 0, None, 6), (0x48, 0, None, 6), (0x90, 0, None, 6),
    (0xC0, 0, None, 6),
    (0x20, 1, None, 6), (0x48, 1, None, 6), (0x90, 1, None, 6),
    (0x20, 2, None, 6), (0x48, 2, None, 6), (0x90, 2, None, 6),
    (0x48, 3, None, 6),
    # carry-seeking / other table rows
    (0x2C, 0, (30, 200, 200, 30), 8),
    (0x48, 0, (30, 200, 200, 30), 8),
    (0x90, 0, (30, 200, 200, 30), 8),
    (0x48, 1, (200, 30, 30, 200), 8),
    (0x48, 2, (200, 200, 30, 100), 8),
]
if a.quick:
    CASES = CASES[5:8]

all_ev = []
for lvl, tac, bases, rounds in CASES:
    ev = run_case(lvl, tac, bases, rounds)
    n = sum(1 for e in ev if e['tag'] in ('carry', 'nocarry'))
    print('lvl=%02x tac=%d bases=%s: %d decisions, %d events'
          % (lvl, tac, bases, n, len(ev)))
    all_ev += ev

json.dump({'_generator': 'simulator/measure_obedience.py (S87, patched '
                         'a17bff8e + hacked .sav boot.state)',
           'events': all_ev}, open(a.out, 'w'))
print('wrote', a.out, len(all_ev), 'events')
