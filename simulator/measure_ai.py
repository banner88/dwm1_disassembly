#!/usr/bin/env python3
"""S80 AI measurement rig: rig battle vs a real EID with the ENEMY action
queue unforced, hooks on the bank $57 decision stages, dense input cadence.

Usage:
  python3 simulator/measure_ai.py --rom <patched.gbc> --state <boot.state> \
      --eid 35 [--frames 1500] [--out simulator/ai_events.json]

HOOK-SAFETY PROTOCOL (S80, see PYBOY_DEBUGGING.md):
- PyBoy hooks singlestep past each hit; this shifts joypad/interrupt
  alignment enough that sparse input cadences miss menu edges and the battle
  waits forever (looks like a wedge). Use the dense 4-on/4-off cadence.
- Do not hook per-frame-polled addresses (e.g. $57:$7129 during a player
  menu wait) in long runs: each hit costs 10-20ms wall clock.

Stage hooks (all bank $57): $7129 entry, $73b9 category, $7529 sum,
$7439 filter, $75a2 pick, $7859 post. One event captures the full AI RAM
context; see simulator/ai.py for the model these events validate.
"""
import sys, json, argparse, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import boot

STAGES = [(0x7129, 'ent'), (0x73b9, 'cat'), (0x7529, 'sum'),
          (0x7439, 'flt'), (0x75a2, 'pik'), (0x7859, 'pst')]

ap = argparse.ArgumentParser()
ap.add_argument('--rom', required=True)
ap.add_argument('--state', required=True)
ap.add_argument('--eid', type=int, required=True)
ap.add_argument('--ecount', type=int, default=1)
ap.add_argument('--frames', type=int, default=1500)
ap.add_argument('--max-events', type=int, default=400)
ap.add_argument('--out', default=None)
a = ap.parse_args()

p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)

ev = []

def mk(tag):
    def cb(_):
        if len(ev) >= a.max_events:
            return
        ai = p.memory[0xDB88]
        ev.append(dict(
            t=tag, ai=ai,
            rng=[p.memory[0xC899], p.memory[0xC89A]],
            d9=[p.memory[0xD9EC], p.memory[0xD9ED], p.memory[0xD9EE]],
            bases=[p.memory[0xDC44 + ai], p.memory[0xDC4C + ai],
                   p.memory[0xDC54 + ai]],
            base4=p.memory[0xDC5C + ai],
            adj=[p.memory[0xDB50 + i] for i in range(3)],
            dcfc=[p.memory[0xDCFC + i] for i in range(6)],
            dd02=p.memory[0xDD02],
            dd6a=p.memory[0xDD6A],
            dd26=p.memory[0xDD26] | (p.memory[0xDD27] << 8),
            dd0b=p.memory[0xDD0B + ai],
            dd03=p.memory[0xDD03 + ai],
            dce4=[p.memory[0xDCE4 + i] for i in range(8)],
            dcec=[p.memory[0xDCEC + i] for i in range(12)],
            blk=[p.memory[0xDC64 + (ai & 7) * 16 + i] for i in range(9)],
            hp=[p.memory[0xDBA3 + i * 2] | (p.memory[0xDBA4 + i * 2] << 8)
                for i in range(5)]))
    return cb

for addr, tag in STAGES:
    p.hook_register(0x57, addr, mk(tag), None)

p.memory[0xDA03] = a.eid & 0xFF
p.memory[0xDA04] = (a.eid >> 8) & 0xFF
p.memory[0xDA02] = (a.ecount - 1) & 3
if a.ecount > 1:
    p.memory[0xDA05] = p.memory[0xDA03]; p.memory[0xDA06] = p.memory[0xDA04]
if a.ecount > 2:
    p.memory[0xDA07] = p.memory[0xDA03]; p.memory[0xDA08] = p.memory[0xDA04]
p.memory[0xDA09] = 1
p.memory[0xC905] = 0
p.memory[0xC8EB] |= 0x40

for i in range(a.frames):
    # dense cadence: robust to hook-singlestep input-timing shifts (S80)
    if i % 8 < 4:
        p.button_press('a')
    else:
        p.button_release('a')
    p.tick()

out = a.out or f'simulator/ai_events_{a.eid}.json'
json.dump(dict(eid=a.eid, events=ev), open(out, 'w'))
print(f'EID {a.eid}: {len(ev)} events -> {out}')
for e in ev:
    if e['ai'] >= 4:
        print(f"{e['t']} ai={e['ai']} d9={e['d9']} dd02={e['dd02']} "
              f"dd6a={e['dd6a']:02x} dcfc={e['dcfc']} dce4={e['dce4'][:4]} "
              f"q={e['dcec'][8:10]}")
