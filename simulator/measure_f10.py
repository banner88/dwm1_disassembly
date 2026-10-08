#!/usr/bin/env python3
"""S130 F10 (DeMagic $80 / ThickFog $83 / FILTHZONE $A5) capture rig — a copy
of simulator/measure_f7.py (itself the S85 loop rig) with the F10 waypoints,
for simulator/validate_f10.py.

Every event carries the full board (stats, the 64-byte status area + $DB40/41,
res, queue, RNG, $C1CA/$C1CD, skills $DC64, AI weights $DC44/4C/54/5C) plus
`rec` = each party slot's record stats.

F10 waypoints (bytes verified identical in u22.gbc vs the clean build, S130):
  $52:$4BA1 SkillDeMagic_ThickFog (handler: d9ed := 3, d9ee := 0)
  $52:$6CDD the instruction after the handler call (handler return)
  $53 entry 11 machine DispelMachine_60b3 (dw table on $D9EE):
    $60C9 s0 slot check / $60DD strip / $6132 +4 clear / $6152 +3 revert test
    $617E revert tail / $61C2 next target / $61E3 helper dismiss /
    $620B side bytes (+ ThickFog seal and own-side pass) / $6252 end
  $53:$626B DispelRevertStats_626b / $647C DispelBaseDefAgl_647c /
  $53:$650C DispelDismissHelper_650c
  $52:$7A49 the act-state-4 tail row for $80 (reachability probe)

Options as measure_f7.py, plus
  --stp ROUND:SLOT:off=val  $DB00+8*SLOT+off |= val in every $D9EC 4/5 frame
                           of round ROUND (off 8/9 = the shifted pair, which
                           phase 9 clears every round)
  --side ROUND:SIDE=val     $DB00+SIDE |= val likewise

Corpus recipe: simulator/f10_corpus_recipe.md (output gzipped -> f10_events.json.gz)
Hook-safety: dense 4-on/4-off A cadence (PYBOY_DEBUGGING S80).
"""
import sys, json, os, argparse
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.pyboy_harness import *

SP = '/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/f10meas'
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
ap.add_argument('--stp', action='append', default=[], help='ROUND:SLOT:off=val status poke (|=) in every command/order frame of that round; off may be 8/9 (the shifted pair)')
ap.add_argument('--side', action='append', default=[], help='ROUND:SIDE=val $DB00+SIDE |= val in the command/order frames of that round')
ap.add_argument('--keep', type=int, default=1)
ap.add_argument('--rounds', type=int, default=12, help='stop at the (N+1)-th round_start')
ap.add_argument('--frames', type=int, default=30000)
ap.add_argument('--skip', type=int, default=0)
ap.add_argument('--db73', type=int)
ap.add_argument('--rom', default=SP + '/u22.gbc')
ap.add_argument('--state', default=SP + '/field.state')
ap.add_argument('--out', default=SP + '/f10_events.json')
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
                        dfn=w16(m, r + 0x5A), agl=w16(m, r + 0x5C), int=w16(m, r + 0x5E),
                        level=m[r + 0x4B], aiw=[m[r + 0x64], m[r + 0x67], m[r + 0x65], m[r + 0x66]]))
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
        db4c=m[0xDB4C], db71=m[0xDB71] | (m[0xDB72] << 8), db54=m[0xDB54], rng1=m[RNG1], rng2=m[RNG2], c86c=m[0xC86C], db73=m[0xDB73],
        db79=arr(0xDB79, 9), dcec=arr(0xDCEC, 16),
        dd13=arr(0xDD13, 8), dd1b=arr(0xDD1B, 8), dd03=arr(0xDD03, 8),
        dd0b=arr(0xDD0B, 8), db8b=arr(0xDB8B, 8), db9b=arr(0xDB9B, 8),
        db42=arr(0xDB42, 8), db40=arr(0xDB40, 2),
        hp=w16s(0xDBA3), maxhp=w16s(0xDBB3), mp=w16s(0xDBC3), maxmp=w16s(0xDBD3),
        atk=w16s(0xDBE3), dfn=w16s(0xDBF3), agl=w16s(0xDC03), int=w16s(0xDC13),
        st=arr(0xDB00, 64), res=arr(0xDD28, 56), species=arr(0xDC3C, 8),
        c1ca=arr(0xC1CA, 4), c1cd=arr(0xC1CD, 8), dc64=arr(0xDC64, 128),
        aiw=[arr(0xDC44, 8), arr(0xDC4C, 8), arr(0xDC54, 8), arr(0xDC5C, 8)],
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
    (0x53, 0x462C, 'forced'),
    (0x53, 0x520C, 'target_fetch'),
    (0x53, 0x5766, 'miss_rng'),
    (0x53, 0x5810, 'miss'), (0x53, 0x57F7, 'dodge'), (0x53, 0x582A, 'block'),
    (0x53, 0x586A, 'miss_pass'),
    (0x52, 0x7EE3, 'ko'), (0x53, 0x4640, 'round_end'),
    # F10: the handler (d9ed := 3) and its return
    (0x52, 0x4BA1, 'h_dispel'), (0x52, 0x6CDD, 'h_ret'),
    # F10: the bank $53 entry-11 machine ($60B3, dw table on $D9EE)
    (0x53, 0x60C9, 'dm_s0'), (0x53, 0x60DD, 'dm_strip'), (0x53, 0x6132, 'dm_s2'),
    (0x53, 0x6152, 'dm_s3'), (0x53, 0x617E, 'dm_s4'), (0x53, 0x61C2, 'dm_next'),
    (0x53, 0x61E3, 'dm_s6'), (0x53, 0x620B, 'dm_s7'), (0x53, 0x6252, 'dm_end'),
    (0x53, 0x626B, 'dm_revert'), (0x53, 0x647C, 'dm_basedef'), (0x53, 0x650C, 'dm_dismiss'),
    # the state-4 tail row of $80 ($52:$7A49) — reached by DeMagic?
    (0x52, 0x7A49, 't4_80'),
    # F7 handlers used to prepare boards (entries only)
    (0x52, 0x434A, 'h_sap'), (0x52, 0x436D, 'h_upper'), (0x52, 0x4385, 'h_slow'),
    (0x52, 0x43A8, 'h_speed'), (0x52, 0x446C, 'h_transform'), (0x52, 0x6D37, 'tf_done'),
]
for bank, addr, tag in HOOKS:
    p.hook_register(bank, addr, (lambda ctx, t=tag: events.append(snap(p, t))), None)

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
            for spec in a.stp:           # F10: per-round status pokes
                rr, slot, kv = spec.split(':'); off, val = kv.split('=')
                if int(rr) == cur_rnd and m[0xD9EC] in (4, 5):   # never between actors (d9ec 6)
                    ad = 0xDB00 + 8 * int(slot) + int(off, 0)
                    m[ad] |= int(val, 0)
            for spec in a.side:
                rr, kv = spec.split(':'); sd, val = kv.split('=')
                if int(rr) == cur_rnd and m[0xD9EC] in (4, 5):
                    m[0xDB00 + int(sd)] |= int(val, 0)
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
    p.tick(1, False)

old = []
if os.path.exists(a.out):
    old = [e for e in json.load(open(a.out)) if e['sc'] != a.name]
json.dump(old + events, open(a.out, 'w'), separators=(',', ':'))
tags = {}
for e in events:
    tags[e['tag']] = tags.get(e['tag'], 0) + 1
print(f'{a.name}: +{len(events)} events (total {len(old)+len(events)}) frames={i} {tags}')
