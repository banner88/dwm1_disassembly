#!/usr/bin/env python3
"""S130 F4 capture rig (charge, critical hits and the bank $53 post-calc
stage). A copy-and-extend of simulator/measure_f23_phys.py (itself the S85
loop rig simulator/measure_battle.py): ONE rig battle (S75 TriggerBattle
mimic) on the user's real save, every slot's queue forceable PER ROUND,
per-slot HP/MP/status/stat pokes, plus waypoints on

  bank $53  the crit stage ($58AF post-roll RNG, $58B4 crit, $58EA none),
            the post-calc stage ($5912 entry with the handler's $DB56,
            $592A TwinHits x2, $5966 crit ATK in HL before SaveBtlC_5d73,
            $5985 ChargeUP / $59B0 SuckAir multiplies, $5DB1 their step,
            $59C3 the $DB42 x1.5, $5A6F the end)
  bank $52  the F4 handlers (TwinHits, Massacre/EvilSlash, ChargeUP,
            HighJump take-off + landing, SuckAir, Focus, ALLCHANGE), the
            end-of-action follow-up check ($70A4 / $6F5B)
  bank $58  the command-phase $DB42 rolls (LoadBtlFX_5a40 / _5ba1 and
            the return at $547E)

and two RNG/table INJECTIONS for the crit roll:
  --critrng 0=0,4=3   at $58AF (after the roll's LoadBtlC_4e33 step, before
                      LoadBtlC_5ed9 reads RNG1) poke wRNG1 for that attacker
                      ('all=v' for every attacker)
  --dc3c 0=136        during the roll only, the attacker's $DC3C species byte
                      (restored at $58B4/$58EA) — reaches the table row of
                      any species from a party slot

Usage:
  measure_f4.py NAME EID [--eids a,b,c] [--q 0=0x3a:4,...]
      [--qr 'round1spec/round2spec/...'] [--hp ..] [--mp ..] [--keep]
      [--st 4:6=0x01] [--res ..] [--lvl ..] [--atk ..] [--dfn ..] [--agl ..]
      [--db42 0=0x40] [--db73 N] [--frames N] [--skip N] [--out FILE]

--q forces the same queue every round; --qr gives one spec per round
('/'-separated, the last repeats; an empty item = no forcing that round).
--db42 pokes $DB42+slot at each act phase start (a stand-in for the
command-phase roll). Hook-safety (S80): dense 4-on/4-off A cadence; only
once-per-action addresses are hooked.
"""
import sys, json, os, argparse
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
from tools.pyboy_harness import *

SP = '/tmp/claude-0/-home-claude/d8a05a84-786c-5fff-9af2-9cbfefa4475e/scratchpad/f4'

ap = argparse.ArgumentParser()
ap.add_argument('name'); ap.add_argument('eid', type=int)
ap.add_argument('--ecount', type=int, default=1)
ap.add_argument('--eids', help='per enemy slot EIDs a,b,c (overrides eid/ecount)')
ap.add_argument('--q', default='')
ap.add_argument('--qr', default='')
ap.add_argument('--hp', default=''); ap.add_argument('--mp', default='')
ap.add_argument('--keep', action='store_true')
ap.add_argument('--st', default=''); ap.add_argument('--res', default='')
ap.add_argument('--stinit', default='', help='status pokes at init only')
ap.add_argument('--lvl', default=''); ap.add_argument('--db8b', default='')
ap.add_argument('--atk', default=''); ap.add_argument('--dfn', default=''); ap.add_argument('--agl', default='')
ap.add_argument('--db42', default='')
ap.add_argument('--aib', default='', help='poke $DC44+idx (AI bases) at each command phase')
ap.add_argument('--db42rng', type=lambda x: int(x, 0), help='at the bank $58 $DB42 rolls (party slots) poke the RNG so the post-step RNG1 = v')
ap.add_argument('--lean', action='store_true', help='keep only the crit/post-calc/roll tags, drop heavy fields')
ap.add_argument('--critrng', default='')
ap.add_argument('--dc3c', default='')
ap.add_argument('--db73', type=int)
ap.add_argument('--frames', type=int, default=12000)
ap.add_argument('--rounds', type=int, default=99)
ap.add_argument('--skip', type=int, default=0)
ap.add_argument('--rom', default=SP + '/u22.gbc')
ap.add_argument('--state', default=SP + '/field.state')
ap.add_argument('--out', default=SP + '/f4_events.json')
ap.add_argument('--maxev', type=int, default=1500)
a = ap.parse_args()

RNG1, RNG2 = 0xC899, 0xC89A


def kv(spec):
    out = []
    for item in [x for x in spec.split(',') if x]:
        k, v = item.split('=')
        out.append((k, int(v, 0)))
    return out


def qspec(spec):
    q = {}
    for item in [x for x in spec.split(',') if x]:
        s, rest = item.split('=')
        sk, _, tg = rest.partition(':')
        s = int(s)
        q[s] = (int(sk, 0), int(tg, 0) if tg else (4 if s < 4 else 0))
    return q


QUEUE = qspec(a.q)
QROUNDS = [qspec(x) for x in a.qr.split('/')] if a.qr else []
HP = {int(k): v for k, v in kv(a.hp)}
MP = {int(k): v for k, v in kv(a.mp)}
LVL = {int(k): v for k, v in kv(a.lvl)}
DB8B = {int(k): v for k, v in kv(a.db8b)}
DB42 = {int(k): v for k, v in kv(a.db42)}
AIB = {int(k): v for k, v in kv(a.aib)}
CRITRNG = {(-1 if k == 'all' else int(k)): v for k, v in kv(a.critrng)}
DC3C = {int(k): v for k, v in kv(a.dc3c)}
STATS = [(0xDBE3, {int(k): v for k, v in kv(a.atk)}), (0xDBF3, {int(k): v for k, v in kv(a.dfn)}),
         (0xDC03, {int(k): v for k, v in kv(a.agl)})]


def stspec(spec):
    out = []
    for k, v in kv(spec):
        s, off = k.split(':')
        out.append((int(s), int(off), v))
    return out


ST = stspec(a.st)
STINIT = stspec(a.stinit)
RES = []
for k, v in kv(a.res):
    s, rt = k.split(':')
    RES.append((int(s), int(rt), v))


def snap(p, tag):
    m = p.memory
    rf = p.register_file
    def arr(ad, n): return list(m[ad:ad + n])
    def w16s(ad): return [m[ad + 2 * i] | (m[ad + 2 * i + 1] << 8) for i in range(8)]
    return dict(
        tag=tag, sc=a.name, frame=p.frame_count,
        A=rf.A, HL=rf.HL,
        d9ec=m[0xD9EC], d9ed=m[0xD9ED], d9ee=m[0xD9EE],
        db82=m[0xDB82], db88=m[0xDB88], db89=m[0xDB89], db8a=m[0xDB8A],
        db56=m[0xDB56] | (m[0xDB57] << 8), dd6f=m[0xDD6F],
        dcfc=m[0xDCFC], dcfd=m[0xDCFD], dcfe=m[0xDCFE], dcff=m[0xDCFF],
        rng1=m[RNG1], rng2=m[RNG2], c86c=m[0xC86C], db73=m[0xDB73],
        db79=arr(0xDB79, 9), dcec=arr(0xDCEC, 16),
        dd13=arr(0xDD13, 8), dd1b=arr(0xDD1B, 8), dd03=arr(0xDD03, 8),
        dd0b=arr(0xDD0B, 8), db8b=arr(0xDB8B, 8), db9b=arr(0xDB9B, 8),
        db42=arr(0xDB42, 8), dc3c=arr(0xDC3C, 8), dd69=m[0xDD69],
        ai_bases=arr(0xDC44, 32),
        hp=w16s(0xDBA3), maxhp=w16s(0xDBB3), mp=w16s(0xDBC3), maxmp=w16s(0xDBD3),
        atk=w16s(0xDBE3), dfn=w16s(0xDBF3), agl=w16s(0xDC03), int=w16s(0xDC13),
        st=arr(0xDB00, 66), res=arr(0xDD28, 56),
        eid=[m[0xDA03] | (m[0xDA04] << 8), m[0xDA05] | (m[0xDA06] << 8),
             m[0xDA07] | (m[0xDA08] << 8)])


HOOKS = [
    # --- the S85 loop waypoints (measure_battle.py / measure_f23_phys.py) ---
    (0x58, 0x54D1, 'round_start'), (0x53, 0x4546, 'actor_fetch'),
    (0x53, 0x454F, 'gates_in'), (0x53, 0x462C, 'forced'),
    (0x53, 0x45CD, 'curse_stage'), (0x53, 0x4657, 'dupconv'),
    (0x53, 0x467C, 'skill_load'), (0x53, 0x520C, 'target_fetch'),
    (0x53, 0x4799, 'reresolve'), (0x53, 0x47E8, 'dead_redirect'),
    (0x53, 0x5747, 'miss_in'), (0x53, 0x5766, 'miss_rng'),
    (0x53, 0x5810, 'miss'), (0x53, 0x57F7, 'dodge'), (0x53, 0x582A, 'block'),
    (0x53, 0x586A, 'miss_pass'),
    (0x52, 0x60D7, 'calcdef_in'), (0x52, 0x61EC, 'calcdef_out'),
    (0x52, 0x679C, 'roll_in'),
    (0x52, 0x6D56, 'apply_in'), (0x52, 0x7EE3, 'ko'),
    (0x50, 0x6B25, 'p9_slot'), (0x50, 0x6C14, 'p9_dot_apply'),
    (0x53, 0x4640, 'round_end'), (0x50, 0x6CBE, 'side_wipe'),
    (0x53, 0x5544, 'guard_redir'),
    (0x53, 0x5411, 'state7'),
    # --- S130 F4: crit stage + post-calc stage (bank $53) ---
    (0x53, 0x58AF, 'crit_rng'),      # after the crit roll's LoadBtlC_4e33 step
    (0x53, 0x58B4, 'crit_yes'),      # crit: +4 bit7, msg $79/$7A
    (0x53, 0x58EA, 'crit_no'),       # no crit: +4 bit7 cleared
    (0x53, 0x5912, 'postcalc_in'),   # post-calc entry ($DB56 = handler result)
    (0x53, 0x592A, 'twin_x2'),       # TwinHits doubling
    (0x53, 0x5966, 'crit_atk'),      # HL = ATK (QuadHits halved) before SaveBtlC_5d73
    (0x53, 0x5985, 'charge_x'),      # ChargeUP multiply
    (0x53, 0x59B0, 'suck_x'),        # SuckAir multiply
    (0x53, 0x5DB1, 'x2_in'),         # SaveBtlC_5db1 (RNG pre-step)
    (0x53, 0x59C3, 'db42_stage'),    # before the $DB42 bit6 x1.5
    (0x53, 0x5A6F, 'postcalc_out'),  # end of the post-calc stage
    (0x53, 0x52F4, 'state3'),        # HighJump take-off shortcut check
    # --- S130 F4: the bank $52 handlers ---
    (0x52, 0x43FB, 'twinhits_in'), (0x52, 0x4683, 'massacre_in'),
    (0x52, 0x46A2, 'massacre_crit'), (0x52, 0x46B8, 'evil_fail'),
    (0x52, 0x46BE, 'chargeup_in'), (0x52, 0x46CF, 'highjump_in'),
    (0x52, 0x46EE, 'hj_land'), (0x52, 0x470F, 'suckair_in'),
    (0x52, 0x4888, 'focus_in'), (0x52, 0x4F35, 'allchange_in'),
    (0x52, 0x6F5B, 'followup'),      # own +6 bit6 consumed (Focus)
    (0x52, 0x70A4, 'act_end'),       # end-of-action +6 bit6 check
    # --- S130 F4: command-phase $DB42 rolls (bank $58) ---
    (0x58, 0x5A40, 'db42_roll1'), (0x58, 0x5BA1, 'db42_roll2'),
    (0x58, 0x547E, 'db42_done'),
    (0x58, 0x6379, 'slot_resolver'),  # TargetSlotResolver_6379 (Massacre's row)
]

# verify every hook site is byte-identical between the clean build and the ROM
_clean = os.path.join(ROOT, 'disassembly', 'game.gbc')
if os.path.exists(_clean):
    c = open(_clean, 'rb').read(); r = open(a.rom, 'rb').read()
    for bank, addr, tag in HOOKS:
        o = bank * 0x4000 + addr - 0x4000
        if c[o:o + 3] != r[o:o + 3]:
            print('WARNING hook site differs from clean build:', tag, hex(bank), hex(addr))

events = []
p = boot(a.rom)
with open(a.state, 'rb') as f:
    p.load_state(f)
for _ in range(a.skip):
    p.tick(1, False)

saved_dc3c = {}


def on_hook(tag):
    def cb(ctx):
        m = p.memory
        if tag in ('db42_roll1', 'db42_roll2') and a.db42rng is not None and m[0xDB88] < 3:
            # pre-state s with (5s + $1357) >> 8 == v (inverse LCG, 5^-1 = 52429)
            tgt = (a.db42rng << 8) | m[RNG2]
            pre = ((tgt - 0x1357) * 52429) & 0xFFFF
            events.append(snap(p, tag + '_raw'))
            m[RNG1] = pre >> 8; m[RNG2] = pre & 0xFF
        if tag == 'crit_rng':
            att = m[0xDB88]
            if att in DC3C:
                saved_dc3c[att] = m[0xDC3C + att]
                m[0xDC3C + att] = DC3C[att]
            v = CRITRNG.get(att, CRITRNG.get(-1))
            if v is not None:
                events.append(snap(p, 'crit_rng_raw'))
                m[RNG1] = v
        events.append(snap(p, tag))
        if tag in ('crit_yes', 'crit_no'):
            att = m[0xDB88]
            if att in saved_dc3c:
                m[0xDC3C + att] = saved_dc3c.pop(att)
    return cb


for bank, addr, tag in HOOKS:
    p.hook_register(bank, addr, on_hook(tag), None)

eids = [int(x, 0) for x in a.eids.split(',')] if a.eids else [a.eid] * a.ecount
p.memory[0xDA02] = (len(eids) - 1) & 3
for j, e in enumerate(eids):
    p.memory[0xDA03 + 2 * j] = e & 0xFF; p.memory[0xDA04 + 2 * j] = (e >> 8) & 0xFF
p.memory[0xDA09] = 1; p.memory[0xC905] = 0; p.memory[0xC8EB] |= 0x40


def poke_stats(m, init):
    for s, v in HP.items():
        if init or m[0xDD1B + s] == 0:
            m[0xDBA3 + 2*s] = v & 0xFF; m[0xDBA4 + 2*s] = v >> 8
            m[0xDBB3 + 2*s] = v & 0xFF; m[0xDBB4 + 2*s] = v >> 8
    for s, v in MP.items():
        m[0xDBC3 + 2*s] = v & 0xFF; m[0xDBC4 + 2*s] = v >> 8
        m[0xDBD3 + 2*s] = v & 0xFF; m[0xDBD4 + 2*s] = v >> 8
    for s, off, v in ST:
        m[0xDB00 + 8*s + off] = v
    if init:
        for s, off, v in STINIT:
            m[0xDB00 + 8*s + off] = v
    for s, v in LVL.items():
        m[0xDB9B + s] = v
    for s, v in DB8B.items():
        m[0xDB8B + s] = v
    for base, d in STATS:
        for s, v in d.items():
            m[base + 2*s] = v & 0xFF; m[base + 2*s + 1] = v >> 8


started = False
forced = False
last_phase = None
rounds = 0
for i in range(a.frames):
    m = p.memory
    if m[GAME_MODE] == 2:
        if not started:
            m[0xC8EB] &= ~0x40 & 0xFF
        started = True
        if not forced and m[0xD9EC] <= 3 and m[0xD9ED] >= 1:
            forced = True
            poke_stats(m, True)
            for s, rt, lv in RES:
                pos = rt + 1
                ad = 0xDD28 + 7*s + (pos >> 2)
                sh = (3 - (pos & 3)) * 2
                m[ad] = (m[ad] & ~(3 << sh) & 0xFF) | ((lv & 3) << sh)
        ph = m[0xD9EC]
        if ph == 4 and last_phase != 4:
            rounds += 1
            for k, v in AIB.items():
                m[0xDC44 + k] = v
            if a.keep:
                poke_stats(m, False)
        if ph == 7 and last_phase != 7:
            for s, v in DB42.items():
                m[0xDB42 + s] = v
        last_phase = ph
        if a.db73 is not None and ph >= 1:
            m[0xDB73] = a.db73
        if 4 <= ph <= 6:
            qq = QUEUE
            if QROUNDS:
                qq = QROUNDS[min(rounds, len(QROUNDS)) - 1] if rounds else QROUNDS[0]
            for s, (sk, tg) in qq.items():
                m[0xDCEC + 2*s] = sk; m[0xDCED + 2*s] = tg
    elif started:
        break
    if len(events) >= a.maxev or rounds > a.rounds:
        break
    if i % 8 < 4:
        p.button_press('a')
    else:
        p.button_release('a')
    p.tick(1, False)

DROP = {'gates_in', 'curse_stage', 'dupconv', 'reresolve', 'dead_redirect'}
events = [e for e in events if e['tag'] not in DROP]
LEAN_TAGS = {'round_start', 'target_fetch', 'miss_rng', 'miss', 'dodge', 'block', 'crit_rng', 'crit_rng_raw',
             'crit_yes', 'crit_no', 'calcdef_in', 'postcalc_in', 'twin_x2', 'crit_atk', 'charge_x',
             'suck_x', 'x2_in', 'db42_stage', 'postcalc_out', 'apply_in', 'act_end', 'followup',
             'db42_roll1', 'db42_roll2', 'db42_done', 'db42_roll1_raw', 'db42_roll2_raw', 'p9_slot',
             'slot_resolver'}
LEAN_DROP = ('dd03', 'db79', 'maxhp', 'maxmp', 'mp', 'int', 'db9b',
             'eid', 'dd6f', 'dcfc', 'd9ec', 'db82', 'A')
if a.lean:
    events = [e for e in events if e['tag'] in LEAN_TAGS]
    for e in events:
        if e['tag'] not in ('db42_roll1', 'db42_roll2', 'db42_done', 'db42_roll1_raw', 'db42_roll2_raw'):
            e.pop('ai_bases', None)
        for k in LEAN_DROP:
            e.pop(k, None)
old = []
if os.path.exists(a.out):
    old = json.load(open(a.out))
json.dump(old + events, open(a.out, 'w'), separators=(',', ':'))
tags = {}
for e in events:
    tags[e['tag']] = tags.get(e['tag'], 0) + 1
print(f'{a.name}: +{len(events)} events (total {len(old)+len(events)}) frames={i} rounds={rounds} {tags}')
