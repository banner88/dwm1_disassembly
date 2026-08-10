#!/usr/bin/env python3
"""S78 damage-measurement rig: runs ONE rig battle (S75 TriggerBattle-mimic)
against a chosen enemy_stats row, forcing party slot 0 to cast a chosen
skill, and appends damage-pipeline waypoint captures to a JSON events file
for simulator/validate_damage.py.

Usage:
  measure_rig.py NAME EID [--skill N] [--atk N] [--dfn N] [--mp N] [--lvl N]
      [--target N] [--tstat 0xNN] [--db73 N] [--frames N] [--out FILE]
      [--rom ROM] [--state BOOTSTATE] [--noalive]

Prereqs: a patched-build ROM with a CONTINUE-able .sav loaded, and a
post-boot savestate (boot to field, close menus, p.save_state).  --db73 0
mid-battle reproduces the WILD-battle condition inside the (scripted) rig
battle: the rig sets $DA09=1 so battle init classifies it as scripted
(db73=1) and the boss-protection gate blocks death/paralysis-class skills.
"""
import sys, json, os, argparse
sys.path.insert(0, '/home/claude/dwm1_disassembly')
from tools.pyboy_harness import *

ROM = None  # via --rom
ATK_A, DEF_A, HP_A, MP_A = 0xDBE3, 0xDBF3, 0xDBA3, 0xDBC3
LVL_A, ATT_I, TGT_I = 0xDB9B, 0xDB88, 0xDB89
DB56, SKILL, STATUS_BASE, RES, C86C, DCEC = \
    0xDB56, 0xDB8A, 0xDB00, 0xDD28, 0xC86C, 0xDCEC
RNG1, RNG2 = 0xC899, 0xC89A   # wRNG1/wRNG2 (disassembly/wram.asm)

ap = argparse.ArgumentParser()
ap.add_argument('name'); ap.add_argument('eid', type=int)
ap.add_argument('--skill', type=int); ap.add_argument('--atk', type=int)
ap.add_argument('--dfn', type=int); ap.add_argument('--mp', type=int, default=200)
ap.add_argument('--lvl', type=int); ap.add_argument('--frames', type=int, default=2400)
ap.add_argument('--out', default='/home/claude/trace/events_all.json')
ap.add_argument('--noalive', action='store_true')
ap.add_argument('--tstat', type=lambda x:int(x,0))
ap.add_argument('--target', type=int, default=4)
ap.add_argument('--db73', type=int)
ap.add_argument('--rom', default='/home/claude/trace/patched.gbc')
ap.add_argument('--state', default='/home/claude/trace/boot.state')
a = ap.parse_args()

events = []

def w16(p, ad):
    return p.memory[ad] | (p.memory[ad + 1] << 8)

def snap(tag):
    def cb(ctx):
        ai, ti = p.memory[ATT_I], p.memory[TGT_I]
        events.append(dict(
            tag=tag, sc=a.name, ai=ai, ti=ti,
            rng1=p.memory[RNG1], rng2=p.memory[RNG2],
            skill=p.memory[SKILL], c86c=p.memory[C86C], db56=w16(p, DB56),
            db4c=p.memory[0xDB4C], db4d=p.memory[0xDB4D],
            db4e=p.memory[0xDB4E],
            atk=w16(p, ATK_A + (ai & 7) * 2), dfn=w16(p, DEF_A + (ti & 7) * 2),
            lvl_a=p.memory[LVL_A + (ai & 7)], mp_a=w16(p, MP_A + (ai & 7) * 2),
            hp_t=w16(p, HP_A + (ti & 7) * 2), hp_a=w16(p, HP_A + (ai & 7) * 2),
            st_t=p.memory[STATUS_BASE + 5 + (ti & 7) * 8],
            res_t=[p.memory[RES + (ti & 7) * 7 + k] for k in range(7)],
            dd69=p.memory[0xDD69], db73=p.memory[0xDB73], frame=p.frame_count))
    return cb

p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)

for addr, tag in [(0x60D7, 'calcdef_in'), (0x61EC, 'calcdef_out'),
                  (0x679C, 'roll_in'), (0x67BA, 'roll_out'),
                  (0x54E7, 'final_54e7'), (0x653E, 'megamagic_in'),
                  (0x641A, 'windbeast_in'), (0x6491, 'vacuum_in'),
                  (0x6232, 'kamikaze_in'), (0x6214, 'ramming_in'),
                  (0x54EA, 'final_54ea'),
                  (0x5C51, 'beat_in'), (0x4200, 'beat_hit'),
                  (0x4225, 'beat_miss')]:
    p.hook_register(0x52, addr, snap(tag), None)

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
        p.memory[MP_A] = a.mp & 0xFF; p.memory[MP_A + 1] = a.mp >> 8
        if a.atk is not None:
            p.memory[ATK_A] = a.atk & 0xFF; p.memory[ATK_A + 1] = a.atk >> 8
        if a.dfn is not None:
            p.memory[DEF_A + 8] = a.dfn & 0xFF
            p.memory[DEF_A + 9] = a.dfn >> 8
        if a.lvl is not None:
            p.memory[LVL_A] = a.lvl
        if a.db73 is not None:
            p.memory[0xDB73] = a.db73
        if a.tstat is not None:
            p.memory[STATUS_BASE + 5 + 4 * 8] |= a.tstat
        if not a.noalive:
            p.memory[HP_A] = 200; p.memory[HP_A + 1] = 0
            p.memory[HP_A + 8] = 250; p.memory[HP_A + 9] = 0
    if i % 24 < 3:
        p.button_press('a')
    else:
        p.button_release('a')
    p.tick()

old = []
if os.path.exists(a.out):
    old = json.load(open(a.out))
json.dump(old + events, open(a.out, 'w'))
print(f'{a.name}: +{len(events)} events (total {len(old)+len(events)})')
