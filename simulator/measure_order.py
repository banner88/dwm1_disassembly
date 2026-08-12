#!/usr/bin/env python3
"""S79 turn-order measurement rig.

Runs a rig battle (S75 TriggerBattle-mimic) and captures, per round:
  - 'order_in'  at $58:$54D1 (TurnOrderBuild entry): RNG state, AGL16 x8,
    $DD13 ready-map, $DCEC action queue, presence bytes
  - 'order_keys' at $58:$55C2 (sort entry): unsorted key array $DB61 (9 u16
    incl. the out-of-range 9th pair at $DB71) + id array $DB4C[9]
  - 'order_out' at $58:$5707: final $DB79[9] acted-order list
for simulator/validate_order.py to replay through simulator/turn_order.py.

Party slot AGL/action forcing mirrors measure_rig.py. --party3 pokes two
extra party combatants (slots 1,2) alive at battle time so multi-actor
ordering can be exercised (rig-level stat forcing only; no roster edits).

Usage: measure_order.py NAME EID [--skill N] [--target N] [--agl 'a0,a1,..a7']
       [--rounds N] [--frames N] [--party3] [--out FILE] [--rom R] [--state S]
"""
import sys, json, os, argparse
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import *

HP_A, MP_A, AGL_A = 0xDBA3, 0xDBC3, 0xDC03
RNG1, RNG2 = 0xC899, 0xC89A
DD13, DCEC, DB79, DB61, DB4C = 0xDD13, 0xDCEC, 0xDB79, 0xDB61, 0xDB4C
PRES = 0xDD1B

ap = argparse.ArgumentParser()
ap.add_argument('name'); ap.add_argument('eid', type=int)
ap.add_argument('--skill', type=int)
ap.add_argument('--target', type=int, default=4)
ap.add_argument('--agl', default=None, help='comma list of AGL16 per combatant 0-7')
ap.add_argument('--frames', type=int, default=4000)
ap.add_argument('--party3', action='store_true')
ap.add_argument('--out', default='/home/claude/trace/order_events.json')
ap.add_argument('--rom', default='/home/claude/trace/patched.gbc')
ap.add_argument('--state', default='/home/claude/trace/boot.state')
a = ap.parse_args()

agl = [int(x) for x in a.agl.split(',')] if a.agl else None
events = []

def w16(p, ad): return p.memory[ad] | (p.memory[ad+1] << 8)

def snap(tag):
    def cb(ctx):
        events.append(dict(
            tag=tag, sc=a.name, frame=p.frame_count,
            rng1=p.memory[RNG1], rng2=p.memory[RNG2],
            agl=[w16(p, AGL_A + i*2) for i in range(8)],
            dd13=[p.memory[DD13 + i] for i in range(9)],
            q=[p.memory[DCEC + i] for i in range(16)],
            pres=[p.memory[PRES + i] for i in range(8)],
            keys=[w16(p, DB61 + i*2) for i in range(9)],
            ids=[p.memory[DB4C + i] for i in range(9)],
            order=[p.memory[DB79 + i] for i in range(9)],
            db54=p.memory[0xDB54], db73=p.memory[0xDB73],
            db77=p.memory[0xDB77]))
    return cb

p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)

if a.party3:
    # Duplicate the save's real slot-0 record into slots 1,2 and register the
    # party list BEFORE the battle trigger (canonicalizer-safe: no transition
    # happens between here and the rig battle). 149 B/record.
    base = PARTY_SLOT0 = 0xCAC1
    rec = bytes(p.memory[base:base + 149])
    for s in (1, 2):
        for i, b in enumerate(rec):
            p.memory[base + 149 * s + i] = b
    p.memory[0xCA8D] = 3
    p.memory[0xCA8E] = 0; p.memory[0xCA8F] = 1; p.memory[0xCA90] = 2

p.hook_register(0x58, 0x54D1, snap('order_in'), None)
p.hook_register(0x58, 0x5662, snap('key_roll'), None)   # SaveBtlFX_5662 entry (pre-RNG-step)
p.hook_register(0x58, 0x55C2, snap('order_keys'), None)
p.hook_register(0x58, 0x5707, snap('order_out'), None)

p.memory[0xDA03] = a.eid & 0xFF
p.memory[0xDA04] = (a.eid >> 8) & 0xFF
p.memory[0xDA02] = 0
p.memory[0xDA09] = 1
p.memory[0xC905] = 0
p.memory[0xC8EB] |= 0x40

for i in range(a.frames):
    if p.memory[GAME_MODE] == 2:
        if a.skill is not None:
            p.memory[DCEC] = a.skill
            p.memory[DCEC + 1] = a.target
        if agl:
            for k, v in enumerate(agl):
                p.memory[AGL_A + k*2] = v & 0xFF
                p.memory[AGL_A + k*2 + 1] = v >> 8
        if a.party3:
            for s in (1, 2):
                p.memory[HP_A + s*2] = 150; p.memory[HP_A + s*2 + 1] = 0
                p.memory[MP_A + s*2] = 99
        # keep slot0 + enemy alive so rounds keep coming (MaxHP forced too —
        # HP > MaxHP can push the enemy AI into flee loops)
        p.memory[HP_A] = 200; p.memory[HP_A + 1] = 0
        p.memory[0xDBB3] = 200; p.memory[0xDBB4] = 0
        p.memory[HP_A + 8] = 250; p.memory[HP_A + 9] = 0
        p.memory[0xDBB3 + 8] = 250; p.memory[0xDBB3 + 9] = 0
        p.memory[MP_A] = 200
    if i % 24 < 3:
        p.button_press('a')
    else:
        p.button_release('a')
    p.tick()

old = []
if os.path.exists(a.out):
    old = json.load(open(a.out))
json.dump(old + events, open(a.out, 'w'))
print(f'{a.name}: +{len(events)} events (total {len(old) + len(events)})')
