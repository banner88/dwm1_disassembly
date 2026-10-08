# S130 F10 corpus recipe: simulator/f10_events.json.gz = simulator/measure_f10.py
# NAME EID options... --out simulator/f10_events.json, one line per battle, in order,
# then gzip -9 (validator: simulator/validate_f10.py, 30 battles, 1335 comparisons)
# (u22.gbc + field.state on the user's real save, party Darkdrium L22 / BattleRex
# L23 / Healer L19). Common: --php 900 --pmp 250 --ehp 900 (HP/MP kept topped up).
# --- byte-level strips from poked boards (party caster, queued target 4 / 5 / 6)
p_poke4 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --stp 0:4:3=0xCF --stp 0:4:4=0xFF --stp 0:4:5=0xC0 --stp 0:4:7=0xFF --stp 0:4:8=0xFF --stp 0:4:9=0xFF --stp 0:5:3=0x30 --stp 0:5:4=0x48 --stp 0:5:7=0x0C --stp 0:5:8=0xC2 --stp 0:5:9=0x07 --poke 6:dfn=500 --poke 6:agl=300 --poke 4:dfn=3 --side 0:1=0xFF --side 0:0=0x08 --sched 0:0x80@4,0x80@4 --rounds 2
p_poke5 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --stp 0:4:3=0xFF --stp 0:4:4=0xFF --stp 0:4:5=0xFF --stp 0:4:7=0xFF --stp 0:4:8=0xFF --stp 0:4:9=0xFF --stp 0:5:3=0xCF --stp 0:5:4=0x37 --stp 0:5:5=0x3F --stp 0:5:7=0x33 --stp 0:5:8=0xFF --stp 0:5:9=0x04 --stp 0:6:3=0x10 --stp 0:6:4=0x80 --stp 0:6:7=0x40 --stp 0:6:8=0x02 --side 0:0=0xFF --side 0:1=0x2C --poke 5:dfn=1 --poke 5:agl=1 --sched 0:0x80@5,0x80@5 --rounds 2 --skip 3
p_poke6 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --stp 0:4:3=0xC3 --stp 0:5:3=0x40 --stp 0:6:3=0xF3 --stp 0:6:4=0xFF --stp 0:6:5=0x7F --stp 0:6:7=0x8C --stp 0:6:8=0x7F --stp 0:6:9=0xFF --poke 6:dfn=40 --poke 6:agl=60 --side 0:1=0x77 --sched 0:0x80@6,0x80@4 --rounds 2 --skip 5
p_own 7 --ecount 2 --php 900 --pmp 250 --ehp 900 --stp 0:0:3=0x83 --stp 0:1:7=0xC3 --stp 0:1:3=0x10 --stp 0:1:4=0xC8 --stp 0:2:5=0x80 --stp 0:2:8=0xF0 --side 0:0=0x3F --poke 2:dfn=200 --poke 1:maxhp=999 --poke 1:hp=999 --sched 0:0x80@0 --rounds 1 --skip 9
p_dead 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --poke 5:maxhp=1 --poke 5:hp=1 --sched 0:0x3a@5,0x80@4 --sched 1:0x3a@5,- --stp 1:4:3=0xC3 --stp 1:6:3=0x20 --stp 1:6:8=0xC0 --rounds 2
# --- enemy caster on poked party boards (party revert: the doubled-index level/AI write)
e_poke 7 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 4:0x80@0,0x80@0,0x80@0 --stp 0:0:3=0xC3 --stp 0:0:4=0xC8 --stp 0:0:5=0x80 --stp 0:0:7=0x0F --stp 0:0:8=0xFF --stp 0:0:9=0xFF --stp 0:1:3=0x30 --stp 0:1:7=0xC0 --stp 0:2:4=0x40 --stp 0:2:8=0x3D --side 0:0=0x3C --side 0:1=0x08 --stp 1:1:3=0x10 --stp 1:2:3=0x20 --stp 2:0:3=0x20 --stp 2:2:7=0x80 --poke 1:maxhp=999 --poke 1:hp=999 --poke 2:dfn=300 --poke 2:agl=3 --rounds 3
e_poke2 7 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 4:0x80@2,0x80@2,0x80@1 --stp 0:2:3=0x20 --stp 0:1:3=0x10 --stp 1:2:3=0x10 --stp 1:0:3=0x30 --stp 2:1:3=0x20 --stp 2:2:3=0x20 --rounds 3 --skip 11
# --- natural buff/debuff/status build-up, then the dispel
buffs_p 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 0:0x1e@0,0x22@0,0x8c@0 --sched 1:0x1f@1,0x23@1,0x8e@1 --sched 2:0x2a@2,0x88@0,0x90@2 --sched 4:0x92@0,0x1c@1,0x80@0 --sched 5:0x91@0,0x20@0,- --sched 6:0x17@0,0x18@0,- --rounds 3
buffs_e 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 4:0x1e@4,0x22@4,0x2a@4 --sched 5:0x77@5,0x8d@5,- --sched 6:0x1f@4,0x23@4,- --sched 0:0x1c@4,0x74@4,0x80@4 --sched 1:0x20@4,0x72@4,- --sched 2:0x92@4,0x17@4,- --rounds 3
buffs_e3 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 4:0x1e@4,0x22@4,0x2a@4 --sched 5:0x77@5,0x8d@5,- --sched 6:0x1f@4,0x23@4,- --sched 0:0x1c@4,0x74@4,0x80@4,0x80@4 --sched 1:0x20@4,0x72@4,- --sched 2:0x92@4,0x17@4,- --rounds 4 --skip 19
buffs_e2 20 --ecount 3 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 4:0x1e@4,0x22@4,0x8c@4,- --sched 5:0x1f@4,0x23@4,0x8e@5,- --sched 6:0x2a@6,0x22@6,0x90@6,- --sched 0:0x20@4,0x1c@5,0x80@4,0x80@4 --sched 1:0x74@4,0x72@4,0x3a@4,- --rounds 4 --skip 13
# --- Transform reverts
tf_p1 7 --php 900 --pmp 250 --ehp 900 --sched 1:0x29@4,-,0x29@4 --sched 0:-,0x80@1,0x80@1 --rounds 3
tf_p2 7 --php 900 --pmp 250 --ehp 900 --sched 2:0x29@4,-,- --sched 0:-,0x80@2,0x80@4 --rounds 3
tf_p0 7 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 0:0x29@4,-,0x29@4,- --sched 4:-,0x80@0,-,0x80@0 --rounds 4
tf_e 7 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 4:0x29@0,-,0x29@1,- --sched 0:-,0x80@4,-,0x80@4 --rounds 4
tf_e3 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 5:0x29@0,- --sched 6:0x29@1,- --sched 0:-,0x80@4 --rounds 2
tf_e3b 7 --ecount 3 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 5:0x29@0,- --sched 6:0x29@1,- --sched 0:-,0x80@4,0x80@5 --rounds 3 --skip 17
# --- ThickFog / FILTHZONE: both sides, the seal, MP paid, re-decide, DeMagic lifts it
fog_p 7 --ecount 2 --php 900 --pmp 250 --ehp 900 --emp 200 --stp 0:0:3=0x0C --stp 0:4:4=0x40 --stp 0:5:3=0x20 --side 0:0=0x04 --sched 0:0x83@4,0x00@4,0x80@4,0x00@4 --sched 1:-,0x03@4,-,0x03@4 --sched 4:-,0x00@0,0x00@0,0x00@0 --sched 5:-,0x29@0,-,0x03@1 --rounds 4
fog_e 7 --ecount 2 --php 900 --pmp 250 --ehp 900 --emp 200 --stp 0:0:3=0x0C --stp 0:4:4=0x40 --stp 0:1:3=0x10 --sched 4:0x83@0,0x00@0,0x80@0,0x00@0 --sched 5:-,0x03@1,0x03@1,0x03@1 --sched 0:-,0x00@4,0x00@4,0x00@4 --sched 1:-,0x29@4,-,- --rounds 4 --skip 3
fog_own 7 --php 900 --pmp 250 --ehp 900 --emp 200 --stp 0:4:3=0x80 --stp 0:0:3=0x40 --sched 0:0x83@1,0x00@4 --sched 4:-,0x00@0 --rounds 2
fog_twice 7 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 0:0x83@4,0x83@4,0x80@4 --sched 4:-,0x83@0,- --rounds 3 --skip 5
filth_p 7 --ecount 2 --php 900 --pmp 250 --ehp 900 --emp 200 --stp 0:0:3=0x40 --stp 0:5:3=0x80 --sched 0:0xa5@4,0x00@4 --sched 4:-,0x00@0 --rounds 2
filth_e 7 --php 900 --pmp 250 --ehp 900 --emp 200 --stp 0:2:4=0xFF --sched 4:0xa5@0,0x03@0 --sched 0:-,0x03@4 --rounds 2 --skip 7
# --- the helper (4th) slot: TatsuCall, then the dispel (s6 dismissal)
tatsu_p 7 --php 900 --pmp 250 --ehp 900 --sched 0:0x84@0,0x80@1 --rounds 2 --skip 7
tatsu_e 7 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 4:0x84@4,- --sched 0:-,0x80@4 --rounds 2 --skip 7
tatsu_fog 7 --php 900 --pmp 250 --ehp 900 --emp 200 --sched 0:0x84@0,- --sched 4:0x84@4,0x83@0 --rounds 2 --skip 11
# --- natural AI casters (enemy commits / re-resolves of the F10 ids)
nat_esterk 213 --php 900 --pmp 250 --ehp 3000 --sched 0:0x1e@0,0x22@0,0x1f@0,- --sched 1:0x23@1,- --rounds 8
nat_madspirit 131 --php 900 --pmp 250 --ehp 900 --rounds 8
nat_droll 380 --php 900 --pmp 250 --ehp 900 --rounds 8
nat_copycat 406 --ecount 2 --php 900 --pmp 250 --ehp 900 --rounds 8
