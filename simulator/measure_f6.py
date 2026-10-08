#!/usr/bin/env python3
"""S130 F6 (defence / interception / reflect / absorb) capture rig — a copy of
the F7 schedule rig (simulator/measure_f7.py, itself the S85 loop rig) with
the F6 handler, post-calc and act-state-7 interception waypoints, for
simulator/validate_f6.py. Corpus recipe: see S130_F6_NOTES.md (d).

Schedules: --sched SLOT:list (repeatable), entries `skill@target` per round
(the last one repeats), `-` = leave the round to the engine.
--keep N: refill HP of every live combatant (and MP of scheduled slots)
each command phase. --poke SLOT:field=val, --res SLOT:rtype=lev,
--st SLOT:off=val (init), --db42 SLOT=val ($DB42 |= val each command frame).
All hook addresses verified against u22.gbc's game.sym and the clean
disassembly labels (S130 F6).

Hook-safety: dense 4-on/4-off A cadence (PYBOY_DEBUGGING S80). TRAP (S130 F6):
a hook on $52:$7C18 (the instruction right after BladeDCounter_7bec's
`call BattleRNG`) stalls the emulator (frames crawl, nothing fires) — use
$7C47 (after the RNG1 writes) instead. F6_TRACE=1 prints frame progress,
F6_NOHOOK=tag,tag skips hooks (bisecting a stall), and a runaway hook guard
aborts after maxev+2000 events.

S130 corpus recipe (simulator/f6_events.json.gz = these runs into one JSON,
then calcdef_in/miss_in/miss_pass/tm_check/dead_redirect/rf_site2 events and
the rec/pk/species/db71/db54/db79/c1c0/db82/d9ec/dd72/db61/db4c fields
dropped, gzipped). P3 = --php 900 --pmp 250 --ehp 900 --emp 250 --poke
1:hp=900 --poke 1:maxhp=900 --poke 2:hp=900 --poke 2:maxhp=900; E = --poke
1:mp=250 --poke 1:maxmp=250 --poke 2:mp=250 --poke 2:maxmp=250 (u22.gbc +
field.state on the user's real save):
  p_def 7 --ecount 3 P3 --poke 0:dfn=40 --poke 1:dfn=40 --poke 2:dfn=40 --poke 4:atk=400 --poke 5:atk=400 --poke 6:atk=400 --sched 0:0x90@0 --sched 1:0x8e@1 --sched 2:0x8d@2 --sched 4:0x3a@0,0x3a@1,0x3a@2 --sched 5:0x00@1,0x00@2,0x00@0,0x0c@0 --sched 6:0x5c@0,0x3a@0,0x60@0,0x3b@1 --rounds 7 --skip 3
  p_def42 7 --ecount 3 P3 --poke 0:dfn=40 --poke 1:dfn=40 --poke 2:dfn=40 --poke 4:atk=400 --poke 5:atk=400 --poke 6:atk=400 --db42 0=0x08 --db42 1=0x02 --db42 2=0x02 --sched 0:0x8d@0,0x90@0,0x8e@0 --sched 1:0x8e@1,0x8d@1,0x90@1 --sched 2:0x90@2,0x8e@2,0x8d@2 --sched 4:0x3a@0 --sched 5:0x00@1,0x3a@1 --sched 6:0x5c@0,0x3a@2 --rounds 7 --skip 5
  p_blade 7 --ecount 3 P3 --poke 0:dfn=30 --poke 1:dfn=30 --poke 2:dfn=30 --poke 4:atk=350 --poke 5:atk=350 --poke 6:atk=60 --db42 1=0x08 --sched 0:0x90@0 --sched 1:0x90@1 --sched 2:0x90@2 --sched 4:0x3a@0 --sched 5:0x3a@1 --sched 6:0x3a@2 --rounds 8 --skip 7
  p_bladeko 7 --ecount 3 P3 --ehp 40 --poke 0:dfn=30 --poke 1:dfn=30 --poke 2:dfn=30 --poke 4:atk=400 --poke 5:atk=400 --poke 6:atk=400 --db42 0=0x08 --db42 1=0x08 --db42 2=0x08 --sched 0:0x90@0 --sched 1:0x90@1 --sched 2:0x90@2 --sched 4:0x3a@0 --sched 5:0x3a@1 --sched 6:0x3a@2 --rounds 3 --keep 0 --skip 9
  p_cover 7 --ecount 3 P3 --poke 4:atk=300 --poke 5:atk=300 --poke 6:atk=300 --sched 0:0x88@1,0x89@0,0x88@2 --sched 2:0x89@2,0x8d@2 --sched 1:0x8e@1 --sched 4:0x3a@1,0x3a@2,0x3a@0 --sched 5:0x03@1,0x3a@0 --sched 6:0x3a@2,0x5c@0 --rounds 6 --skip 11
  p_dodge 7 --ecount 3 P3 --poke 4:atk=300 --poke 5:atk=300 --poke 6:atk=300 --sched 0:0x8c@0 --sched 1:0x8c@1 --sched 2:0x3a@4,0x8c@2 --sched 4:0x3a@0 --sched 5:0x3a@1,0x00@0 --sched 6:0x3a@0,0x3b@1 --rounds 8 --skip 13
  p_dodge1 7 P3 --poke 4:atk=300 --sched 0:0x8c@0 --sched 1:0x8c@1 --sched 2:0x8c@2 --sched 4:0x3a@0,0x3a@1,0x3a@2 --rounds 8 --skip 15
  p_dodge2 7 --ecount 2 P3 --poke 4:atk=300 --poke 5:atk=300 --sched 0:0x8c@0 --sched 1:0x8c@1 --sched 2:0x8c@2 --sched 4:0x3a@0,0x3a@2 --sched 5:0x3a@1 --rounds 8 --skip 17
  p_dodgeslp 7 --ecount 2 P3 --poke 4:atk=300 --poke 5:atk=300 --st 0:2=0x83 --st 1:0=0x20 --st 2:0=0x20 --sched 0:-,0x8c@0 --sched 1:0x8d@1 --sched 4:0x3a@0 --sched 5:0x3a@1 --rounds 3 --skip 19
  p_wall 7 --ecount 3 P3 --poke 2:hp=1 --poke 4:atk=300 --sched 0:0x8d@0,0x24@0,0x8d@0,0x24@1 --sched 1:0x26@1,0x8d@1 --sched 4:0x3a@2,0x5c@0,0x60@1,0x15@0 --sched 5:0x00@0,0x18@0,0x00@1 --sched 6:0x60@0,0x00@1,0x5c@0 --rounds 6 --skip 21
  p_mb 7 --ecount 3 P3 --sched 0:0x27@0,0x8d@0,0x8d@0,0x27@0,0x8d@0 --sched 1:0x28@1,0x8d@1 --sched 2:0x27@2,0x28@2,0x8d@2 --sched 4:0x00@0,0x15@1,0x1c@2,0x20@0,0x00@1,0x3a@0 --sched 5:0x03@0,0x18@0,0x1d@0,0x00@2 --sched 6:0x15@2,0x00@0,0x16@0,0x5c@0 --rounds 7 --skip 23
  p_wind 7 --ecount 3 P3 --sched 0:0x8a@0,0x8d@0,0x8d@0,0x8a@0,0x8d@0 --sched 1:0x8b@1,0x8d@1 --sched 2:0x8d@2 --sched 4:0x5c@0,0x60@1,0x6a@0,0x6d@0,0x3a@0 --sched 5:0x43@5,0x03@0,0x5c@2 --sched 6:0x60@0,0x00@0,0x43@6,0x60@1 --rounds 7 --skip 25
  p_suck 7 --ecount 3 P3 --sched 0:0x8f@0,0x8f@0,0x8d@0,0x8f@0 --sched 1:0x8d@1,0x8f@1,0x8d@1 --sched 2:0x8d@2 --sched 4:0x5c@0,0x60@1,0x6a@2,0x5c@0,0x3a@0 --sched 5:0x00@0,0x3a@1 --sched 6:0x60@2,0x5c@1 --rounds 6 --skip 27
  p_suckslp 7 --ecount 3 P3 --st 0:0=0x40 --ram 0xDB4A=0x04 --st 1:2=0x80 --sched 0:0x8d@0 --sched 1:-,0x8d@1 --sched 2:0x8d@2 --sched 4:0x5c@0 --rounds 2 --skip 29
  p_tm 7 P3 --keep 0 --poke 0:mp=10 --poke 1:mp=5 --poke 2:mp=82 --sched 0:0x1b@0,0x8d@0 --sched 1:0x1b@1,0x8d@1 --sched 2:0x1b@2,0x8d@2 --sched 4:0x00@0,0x15@0,0x18@0,0x3b@0,0x5c@0,0x1c@1,0x3a@2,0x17@0,0x03@0,0x20@1 --rounds 10 --skip 31
  p_tm2 7 --ecount 2 P3 --keep 0 --poke 0:mp=10 --poke 1:mp=5 --poke 2:mp=81 --sched 0:0x1b@0,0x1b@0,0x8d@0 --sched 1:0x1b@1,0x8d@1 --sched 2:0x1b@2,0x8d@2 --sched 4:0x03@0,0x15@1,0x00@2,0x18@0,0x03@1 --sched 5:0x3a@0,0x00@0,0x15@2,0x00@1 --rounds 7 --skip 33
  p_im 7 P3 --sched 0:0x7f@0 --sched 1:0x7f@1 --sched 2:0x7f@2 --sched 4:0x3a@0,0x00@1,0x03@0,0x5c@0,0x15@2,0x3b@1,0x3a@2,0x00@0 --rounds 9 --skip 35
  p_im2 7 --ecount 2 P3 --poke 2:mp=0 --keep 0 --sched 0:0x7f@0 --sched 1:0x7f@1 --sched 2:0x7f@2 --sched 4:0x00@2,0x03@0,0x3a@1,0x5c@0 --sched 5:0x3a@0,0x00@1,0x00@2 --rounds 6 --skip 37
  e_def 7 --ecount 3 P3 E --sched 4:0x90@4 --sched 5:0x8e@5 --sched 6:0x8d@6 --sched 0:0x3a@4,0x3a@5,0x3a@6 --sched 1:0x00@5,0x5c@4,0x00@6,0x3a@4 --sched 2:0x00@6,0x03@4,0x3a@5 --rounds 7 --skip 39
  e_blade 7 --ecount 3 P3 E --db42 5=0x08 --db42 6=0x02 --sched 4:0x90@4,0x8e@4 --sched 5:0x90@5 --sched 6:0x90@6,0x8d@6 --sched 0:0x3a@4,0x3a@5,0x3a@6 --sched 1:0x3a@5 --sched 2:0x3a@6,0x3a@4 --rounds 8 --skip 41
  e_cover 7 --ecount 3 P3 E --sched 4:0x88@5,0x89@4,0x88@6 --sched 6:0x89@6,0x8d@6 --sched 0:0x3a@5,0x3a@6,0x3a@4 --sched 1:0x03@4,0x00@5 --sched 2:0x3a@4,0x5c@4 --rounds 6 --skip 43
  e_dodge 7 --ecount 3 P3 E --sched 4:0x8c@4 --sched 5:0x8c@5 --sched 6:0x8c@6,0x3a@0 --sched 0:0x3a@4,0x3a@5,0x3a@6 --sched 1:0x3a@5,0x00@4 --sched 2:0x3a@6,0x3a@4 --rounds 8 --skip 45
  e_wall 7 --ecount 3 P3 E --sched 4:0x24@4,0x8d@4,0x24@5 --sched 5:0x26@5,0x8d@5 --sched 0:0x5c@4,0x60@4,0x00@5,0x15@6 --sched 1:0x00@4,0x18@4,0x5c@4 --sched 2:0x60@4,0x00@6 --rounds 6 --skip 47
  e_mb 7 --ecount 3 P3 E --sched 4:0x27@4,0x8d@4,0x27@4,0x8d@4 --sched 5:0x28@5,0x8d@5 --sched 6:0x27@6,0x8d@6 --sched 0:0x00@4,0x03@4,0x15@5,0x1c@6,0x00@5 --sched 1:0x03@4,0x00@6,0x18@4 --sched 2:0x00@5,0x20@4,0x16@4 --rounds 7 --skip 49
  e_wind 7 --ecount 3 P3 E --sched 4:0x8a@4,0x8d@4,0x8a@4 --sched 5:0x8b@5,0x8d@5 --sched 6:0x8d@6 --sched 0:0x5c@4,0x60@5,0x6a@4,0x5c@4 --sched 1:0x60@4,0x00@4,0x43@1 --sched 2:0x5c@5,0x6d@4 --rounds 6 --skip 51
  e_suck 7 --ecount 3 P3 E --sched 4:0x8f@4,0x8d@4,0x8f@4 --sched 5:0x8d@5,0x8f@5 --sched 6:0x8d@6 --sched 0:0x5c@4,0x60@5,0x5c@6,0x3a@4 --sched 1:0x60@4,0x5c@4 --sched 2:0x6a@4,0x00@4 --rounds 6 --skip 53
  e_tm 7 --ecount 3 P3 E --keep 0 --poke 4:mp=3 --poke 5:mp=248 --poke 6:mp=0 --sched 4:0x1b@4,0x8d@4 --sched 5:0x1b@5,0x8d@5 --sched 6:0x1b@6,0x8d@6 --sched 0:0x00@4,0x03@4,0x15@5,0x18@4,0x00@6 --sched 1:0x00@5,0x5c@4,0x3a@4 --sched 2:0x03@5,0x00@4 --rounds 7 --skip 55
  e_im 7 --ecount 3 P3 E --sched 4:0x7f@4 --sched 5:0x7f@5 --sched 6:0x7f@6 --sched 0:0x3a@4,0x00@5,0x03@4,0x5c@4,0x3a@6 --sched 1:0x00@4,0x3a@5 --sched 2:0x15@6,0x00@5 --rounds 7 --skip 57
  n_dodge 17 --ecount 3 P3 --rounds 6 --skip 59
  n_strongd 32 --ecount 3 P3 --rounds 6 --skip 61
  n_mback 63 --ecount 3 P3 --rounds 6 --skip 63
  n_tail 50 --ecount 3 P3 --rounds 6 --skip 65
  n_cover 100 --ecount 3 P3 --rounds 6 --skip 67
  n_imit 104 --ecount 3 P3 --rounds 6 --skip 69
  n_barrier 116 --ecount 3 P3 --rounds 6 --skip 71
  n_bladed 141 --ecount 3 P3 --rounds 6 --skip 73
  n_storm 146 --ecount 3 P3 --rounds 6 --skip 75
  n_guard 164 --ecount 3 P3 --rounds 6 --skip 77
  n_bounce 133 --ecount 3 P3 --rounds 6 --skip 79
  n_takem 392 --ecount 3 P3 --rounds 6 --skip 81
  n_suck 128 --ecount 3 P3 --rounds 6 --skip 83
  p_wall2 7 --ecount 3 P3 --poke 2:hp=1 --poke 4:atk=300 --sched 1:0x24@1,0x8d@1,0x24@1,0x24@0 --sched 2:0x26@2,0x8d@2 --sched 0:0x26@0,0x8d@0 --sched 4:0x3a@2,0x5c@0,0x60@1,0x15@0 --sched 5:0x00@0,0x18@0,0x00@1 --sched 6:0x60@0,0x00@1,0x5c@0 --rounds 6 --skip 85
  p_wind2 7 --ecount 3 P3 --sched 1:0x8a@1,0x43@1,0x8a@1,0x8d@1 --sched 2:0x8a@2,0x8d@2,0x8b@2 --sched 0:0x8d@0 --sched 4:0x5c@0,0x60@1,0x6a@0,0x5c@0,0x6c@1 --sched 5:0x3a@1,0x43@5 --sched 6:0x60@2,0x5c@1,0x00@1 --rounds 6 --skip 87
  p_mb2 7 --ecount 3 P3 --sched 1:0x27@1,0x8d@1,0x28@1,0x8d@1 --sched 2:0x28@2,0x27@2,0x8d@2 --sched 0:0x8d@0 --sched 4:0x00@1,0x15@2,0x1c@1,0x20@2,0x00@1 --sched 5:0x03@1,0x18@1,0x1d@1,0x00@2 --sched 6:0x17@2,0x00@2,0x16@1,0x21@1 --rounds 6 --skip 89
  p_imiss 7 --ecount 2 P3 --st 4:3=0x02 --st 5:7=0x03 --sched 0:0x7f@0 --sched 1:0x7f@1 --sched 2:0x7f@2 --sched 4:0x3a@0,0x00@1,0x3a@2 --sched 5:0x3a@1,0x3a@2,0x3a@0 --rounds 6 --skip 91
  p_imdodge 7 --ecount 2 P3 --st 1:0=0x28 --st 2:0=0x28 --st 3:0=0x28 --poke 4:atk=300 --poke 5:atk=300 --sched 0:0x8d@0 --sched 1:0x8d@1 --sched 2:0x8d@2 --sched 4:0x3a@0 --sched 5:0x3a@1 --rounds 2 --skip 93
  p_bladesm 7 --ecount 3 P3 --poke 0:dfn=100 --poke 1:dfn=100 --poke 2:dfn=100 --poke 4:atk=54 --poke 5:atk=55 --poke 6:atk=57 --sched 0:0x90@0 --sched 1:0x90@1 --sched 2:0x90@2 --sched 4:0x3a@0 --sched 5:0x3a@1 --sched 6:0x3a@2 --rounds 8 --skip 95
  p_cover2 7 --ecount 3 P3 --sched 2:0x27@2,0x89@2,0x89@2,0x88@1 --sched 1:0x8d@1 --sched 0:0x8d@0 --sched 4:0x00@0,0x00@0,0x03@0,0x3a@1 --sched 5:0x3a@0,0x03@0,0x00@1 --sched 6:0x5c@0,0x3a@1 --rounds 5 --skip 97
  e_wind2 7 --ecount 3 P3 E --sched 5:0x8a@5,0x43@5,0x8a@5 --sched 6:0x8a@6,0x8d@6 --sched 4:0x8d@4 --sched 1:0x5c@4,0x60@4,0x5c@5 --sched 2:0x60@5,0x6a@4,0x5c@4 --sched 0:0x3a@4 --rounds 5 --skip 99
  e_mb2 7 --ecount 3 P3 E --sched 5:0x27@5,0x28@5,0x8d@5 --sched 6:0x28@6,0x8d@6 --sched 4:0x8d@4 --sched 1:0x00@5,0x03@4,0x18@4,0x1c@5 --sched 2:0x15@6,0x00@6,0x21@4,0x00@5 --sched 0:0x3a@4 --rounds 6 --skip 101
  p_coverslp 7 --ecount 3 P3 --st 2:0=0x10 --st 2:1=0x20 --st 2:2=0x40 --st 1:0=0x10 --st 1:1=0x20 --sched 0:0x8d@0 --sched 1:0x8d@1 --sched 4:0x3a@1 --sched 5:0x3a@0 --sched 6:0x00@1 --rounds 1 --skip 103
  p_imveto 7 --ecount 3 P3 --keep 0 --poke 0:mp=1 --st 1:0=0x08 --sched 0:0x8d@0 --sched 1:0x8d@1 --sched 2:0x8d@2 --sched 4:0x00@0 --sched 5:0x00@0 --sched 6:0x00@0 --rounds 1 --skip 105
  p_imveto2 7 --ecount 3 P3 --keep 0 --poke 0:mp=1 --st 1:0=0x08 --sched 0:0x8d@0 --sched 1:0x8d@1 --sched 2:0x8d@2 --sched 4:0x00@0 --sched 5:0x00@0 --sched 6:0x00@0 --rounds 1 --skip 107
  p_imseal 7 --ecount 3 P3 --keep 0 --st 0:3=0x01 --st 1:0=0x08 --sched 0:0x8d@0 --sched 1:0x8d@1 --sched 2:0x8d@2 --sched 4:0x00@0 --sched 5:0x00@0 --sched 6:0x00@0 --rounds 1 --skip 109
"""
import sys, json, os, argparse
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import *

SP = '/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/f6meas'
ap = argparse.ArgumentParser()
ap.add_argument('name'); ap.add_argument('eid', type=int)
ap.add_argument('--ecount', type=int, default=1)
ap.add_argument('--php', type=int); ap.add_argument('--pmp', type=int)
ap.add_argument('--emp', type=int); ap.add_argument('--ehp', type=int)
ap.add_argument('--sched', action='append', default=[])
ap.add_argument('--poke', action='append', default=[])
ap.add_argument('--res', action='append', default=[])
ap.add_argument('--st', action='append', default=[], help='SLOT:off=val status-block poke at init')
ap.add_argument('--db42', action='append', default=[], help='SLOT=val $DB42 |= val during every command/order phase')
ap.add_argument('--ram', action='append', default=[], help='ADDR=val raw RAM poke at init (e.g. $DB4A)')
ap.add_argument('--keep', type=int, default=1)
ap.add_argument('--rounds', type=int, default=12, help='stop at the (N+1)-th round_start')
ap.add_argument('--frames', type=int, default=30000)
ap.add_argument('--skip', type=int, default=0)
ap.add_argument('--db73', type=int)
ap.add_argument('--rom', default=SP + '/u22.gbc')
ap.add_argument('--state', default=SP + '/field.state')
ap.add_argument('--out', default=SP + '/f6_events.json')
ap.add_argument('--maxev', type=int, default=3000)
a = ap.parse_args()

RNG1, RNG2 = 0xC899, 0xC89A
STAT = dict(hp=0xDBA3, maxhp=0xDBB3, mp=0xDBC3, maxmp=0xDBD3, atk=0xDBE3,
            dfn=0xDBF3, agl=0xDC03, int=0xDC13)


def w16(m, ad):
    return m[ad] | (m[ad + 1] << 8)


def rec_stats(m):
    out = []
    for s in range(3):
        idx = m[0xCA8E + s]
        if idx == 0xFF:
            out.append(None); continue
        r = 0xCAC1 + (idx & 0x7F) * 0x95
        out.append(dict(maxhp=w16(m, r + 0x52), maxmp=w16(m, r + 0x56), atk=w16(m, r + 0x58),
                        dfn=w16(m, r + 0x5A), agl=w16(m, r + 0x5C), int=w16(m, r + 0x5E)))
    return out


def snap(p, tag):
    m = p.memory
    def arr(ad, n): return list(m[ad:ad + n])
    def w16s(ad): return [m[ad + 2 * i] | (m[ad + 2 * i + 1] << 8) for i in range(8)]
    return dict(
        tag=tag, sc=a.name, frame=p.frame_count, A=p.register_file.A,
        d9ec=m[0xD9EC], d9ed=m[0xD9ED], d9ee=m[0xD9EE],
        db82=m[0xDB82], db88=m[0xDB88], db89=m[0xDB89], db8a=m[0xDB8A],
        db56=m[0xDB56] | (m[0xDB57] << 8), dd72=m[0xDD72] | (m[0xDD73] << 8),
        db4c=m[0xDB4C], dd6c=m[0xDD6C], dd6d=m[0xDD6D], dd6e=m[0xDD6E], dd69=m[0xDD69],
        db4a=arr(0xDB4A, 2), c1c0=arr(0xC1C0, 10), d9f2=m[0xD9F2] | (m[0xD9F3] << 8), db61=m[0xDB61],
        dcfc=m[0xDCFC], dcfd=m[0xDCFD], dcfe=m[0xDCFE], dcff=m[0xDCFF], db71=m[0xDB71] | (m[0xDB72] << 8), db54=m[0xDB54], rng1=m[RNG1], rng2=m[RNG2], c86c=m[0xC86C], db73=m[0xDB73],
        db79=arr(0xDB79, 9), dcec=arr(0xDCEC, 16),
        dd13=arr(0xDD13, 8), dd1b=arr(0xDD1B, 8), dd03=arr(0xDD03, 8),
        dd0b=arr(0xDD0B, 8), db8b=arr(0xDB8B, 8), db9b=arr(0xDB9B, 8),
        db42=arr(0xDB42, 8), db40=arr(0xDB40, 2),
        hp=w16s(0xDBA3), maxhp=w16s(0xDBB3), mp=w16s(0xDBC3), maxmp=w16s(0xDBD3),
        atk=w16s(0xDBE3), dfn=w16s(0xDBF3), agl=w16s(0xDC03), int=w16s(0xDC13),
        st=arr(0xDB00, 64), res=arr(0xDD28, 56), species=arr(0xDC3C, 8),
        pk=PK, eid=[w16(m, 0xDA03), w16(m, 0xDA05), w16(m, 0xDA07)], rec=rec_stats(m))


# poked (slot, stat) pairs: the validator's base_src check skips them
PK = [[int(x.split(':')[0]), x.split(':')[1].split('=')[0]] for x in a.poke]
events = []
p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)
for _ in range(a.skip):
    p.tick()

HOOKS = [
    (0x58, 0x54D1, 'round_start'), (0x53, 0x4546, 'actor_fetch'),
    (0x53, 0x462C, 'forced'), (0x53, 0x467C, 'skill_load'),
    (0x53, 0x520C, 'target_fetch'),
    (0x53, 0x5747, 'miss_in'), (0x53, 0x5766, 'miss_rng'),
    (0x53, 0x5810, 'miss'), (0x53, 0x57F7, 'dodge'), (0x53, 0x582A, 'block'),
    (0x53, 0x586A, 'miss_pass'),
    (0x52, 0x60D7, 'calcdef_in'), (0x52, 0x679C, 'roll_in'), (0x52, 0x54E7, 'final_54e7'),
    (0x52, 0x6D56, 'apply_in'), (0x52, 0x7EE3, 'ko'), (0x53, 0x4640, 'round_end'),
    (0x50, 0x6B25, 'p9_slot'),
    # F6 handlers (entry = pre) + the handler return (post)
    (0x52, 0x4330, 'h_takemagic'), (0x52, 0x43C0, 'h_barrier'), (0x52, 0x4415, 'h_magicwall'),
    (0x52, 0x4434, 'h_magicback'), (0x52, 0x4B92, 'h_imitate'), (0x52, 0x4C31, 'h_cover'),
    (0x52, 0x4C3B, 'h_tailwind'), (0x52, 0x4C72, 'h_dodge'), (0x52, 0x4C81, 'h_defence'),
    (0x52, 0x4CA5, 'h_suckall'), (0x52, 0x6CDD, 'h_ret'),
    # post-calc defence levels ($DB56 pre) / post-calc end ($DB56 post)
    (0x53, 0x59EC, 'pc_def'), (0x53, 0x5A6F, 'pc_end'),
    # act-state-7 interception chain
    (0x53, 0x5458, 'ic_absorb'), (0x53, 0x54D6, 'ic_cover'), (0x53, 0x5504, 'ic_guard'),
    (0x53, 0x557A, 'ic_dodge'), (0x53, 0x5594, 'ic_wind'), (0x53, 0x55CA, 'ic_magic'),
    (0x53, 0x5622, 'ic_end'),
    (0x53, 0x5091, 'dg_roll'), (0x53, 0x5112, 'dg_self'), (0x53, 0x5140, 'dg_pick'),
    (0x53, 0x5DE7, 'rf_save'), (0x53, 0x5E38, 'rf_swap'), (0x53, 0x5ECE, 'absorb'),
    (0x53, 0x5CBC, 'tm_check'), (0x53, 0x5FFA, 'tm_apply'),
    (0x52, 0x7EF1, 'rf_restore'), (0x52, 0x7DD7, 'im_check'), (0x52, 0x7D7C, 'sw_check'),
    (0x52, 0x6ECF, 'bd_check'), (0x52, 0x7BEC, 'bd_counter'), (0x52, 0x7C98, 'bd_swap'),
    (0x52, 0x7C47, 'bd_dec'),   # ($7C18, right after the BattleRNG call, STALLS the emulator when hooked)
    (0x53, 0x690E, 'rf_site2'),
    (0x53, 0x4799, 'reresolve'), (0x53, 0x47E8, 'dead_redirect'),
]
def _hit(t):
    events.append(snap(p, t))
    if len(events) > a.maxev + 2000:              # a hooked address in a runaway loop
        from collections import Counter
        raise SystemExit(f'runaway hooks: {Counter(e["tag"] for e in events[-2000:]).most_common(5)}'
                         f' last d9ed/d9ee={events[-1]["d9ed"]}/{events[-1]["d9ee"]}')


_skip = set(filter(None, os.environ.get('F6_NOHOOK', '').split(',')))
for bank, addr, tag in HOOKS:
    if tag in _skip:
        continue
    p.hook_register(bank, addr, (lambda ctx, t=tag: _hit(t)), None)

sched = {}
for s in a.sched:
    slot, lst = s.split(':', 1)
    ent = []
    for x in lst.split(','):
        if x == '-':
            ent.append(None)
        else:
            sk, tg = x.split('@')
            ent.append((int(sk, 0), int(tg, 0)))
    sched[int(slot)] = ent

p.memory[0xDA03] = a.eid & 0xFF; p.memory[0xDA04] = (a.eid >> 8) & 0xFF
p.memory[0xDA02] = (a.ecount - 1) & 3
if a.ecount > 1:
    p.memory[0xDA05] = p.memory[0xDA03]; p.memory[0xDA06] = p.memory[0xDA04]
if a.ecount > 2:
    p.memory[0xDA07] = p.memory[0xDA03]; p.memory[0xDA08] = p.memory[0xDA04]
p.memory[0xDA09] = 1; p.memory[0xC905] = 0; p.memory[0xC8EB] |= 0x40


def wr16(m, ad, v):
    m[ad] = v & 0xFF; m[ad + 1] = (v >> 8) & 0xFF


started = False
forced = False
nrs, scanned, cur_rnd = 0, 0, 0
for i in range(a.frames):
    m = p.memory
    while scanned < len(events):
        nrs += events[scanned]['tag'] == 'round_start'; scanned += 1
    if m[GAME_MODE] == 2:
        if not started:
            m[0xC8EB] &= ~0x40           # disarm the rig trigger (S89)
        started = True
        if not forced and m[0xD9EC] <= 3 and m[0xD9ED] >= 1:
            forced = True
            if a.php is not None:
                wr16(m, 0xDBA3, a.php); wr16(m, 0xDBB3, a.php)
            if a.pmp is not None:
                wr16(m, 0xDBC3, a.pmp); wr16(m, 0xDBD3, a.pmp)
            for k in range(3):
                if a.emp is not None:
                    wr16(m, 0xDBC3 + 8 + 2 * k, a.emp); wr16(m, 0xDBD3 + 8 + 2 * k, a.emp)
                if a.ehp is not None:
                    wr16(m, 0xDBA3 + 8 + 2 * k, a.ehp); wr16(m, 0xDBB3 + 8 + 2 * k, a.ehp)
            for spec in a.poke:
                slot, kv = spec.split(':'); fld, val = kv.split('=')
                wr16(m, STAT[fld] + 2 * int(slot), int(val, 0))
            for spec in a.st:
                slot, kv = spec.split(':'); off, val = kv.split('=')
                m[0xDB00 + 8 * int(slot) + int(off, 0)] = int(val, 0)
            for spec in a.ram:
                ad, val = (int(x, 0) for x in spec.split('='))
                m[ad] = val
            for spec in a.res:
                slot, kv = spec.split(':'); rt, lev = (int(x, 0) for x in kv.split('='))
                pos = rt + 1; ad = 0xDD28 + 7 * int(slot) + (pos >> 2)
                sh = (3 - (pos & 3)) * 2
                m[ad] = (m[ad] & ~(3 << sh) & 0xFF) | (lev << sh)
        if a.db73 is not None and m[0xD9EC] >= 1:
            m[0xDB73] = a.db73
        if m[0xD9EC] == 4:              # command phase of round nrs
            cur_rnd = nrs
        if 4 <= m[0xD9EC] <= 6:
            for spec in a.db42:          # re-poked each command/order frame
                slot, val = spec.split('=')
                m[0xDB42 + int(slot)] |= int(val, 0)
            rnd = cur_rnd
            for slot, ent in sched.items():
                x = ent[min(rnd, len(ent) - 1)]
                if x is not None and m[0xDD1B + slot] == 0:
                    m[0xDCEC + 2 * slot] = x[0]; m[0xDCED + 2 * slot] = x[1]
            if a.keep and m[0xD9EC] == 4:
                for s in range(8):
                    if m[0xDD1B + s] == 0:
                        wr16(m, 0xDBA3 + 2 * s, w16(m, 0xDBB3 + 2 * s))
                for s in sched:
                    wr16(m, 0xDBC3 + 2 * s, w16(m, 0xDBD3 + 2 * s))
        if nrs > a.rounds:
            break
    elif started:
        break
    if len(events) >= a.maxev:
        break
    if i % 8 < 4:
        p.button_press('a')
    else:
        p.button_release('a')
    if os.environ.get('F6_TRACE') and i % 50 == 0:
        print('frame', i, 'mode', p.memory[GAME_MODE], 'd9ec', p.memory[0xD9EC], 'ev', len(events), file=sys.stderr, flush=True)
    p.tick(1, False)

old = []
if os.path.exists(a.out):
    old = [e for e in json.load(open(a.out)) if e['sc'] != a.name]
json.dump(old + events, open(a.out, 'w'), separators=(',', ':'))
tags = {}
for e in events:
    tags[e['tag']] = tags.get(e['tag'], 0) + 1
print(f'{a.name}: +{len(events)} events (total {len(old)+len(events)}) frames={i} {tags}')
