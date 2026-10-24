#!/usr/bin/env python3
"""walk_plunder.py — S156: Plunder (skill 234, $EA; BATTLE_SKILL_SYSTEM §13.11) on the
real game (PyBoy on the user's .sav).

The demo (examples/s156_plunder_demo/build_demo.py) = the user's project + THE ROGUE HALL
(the GIFT MASTER's PLUNDERER / SHIELDER, two sparring bosses: the BUFF KNIGHT buffs itself,
the BANDIT plunders).

  gift     the GIFT MASTER (YES) gives PLUNDERER (Plunder, Barrier, Upper, ChargeUP);
           (NO, YES) SHIELDER (Barrier, Increase, SpeedUp, TailWind);
  numbers  forced battles (tools/walk_skills.py's rig: the queue written each frame, the
           RNG pinned, the foe's HP held) — party slot 1 plunders the foe (slot 4), or the
           foe plunders party slot 0. At SkillPlunder's entry the board ($DB00-$DB4B, DEF
           / AGL, the RNG; the bases = the stats at the battle's first command frame) is
           handed to the simulator twin (simulator/skillfx/s155_custom.plunder_one) and at
           the result line's render (bank $4C LoadB4c_CustomLine) the ROM's board must be
           the twin's, byte for byte: every one of the 18 buffs alone on the foe; none ->
           "But nothing happens!" ($BB) with the MP spent; the caster's own buffs skipped
           (Barrier + TailWind on the foe, TailWind on the caster -> Barrier, 4 seeds);
           three buffs over 8 seeds (several different picks); DEF raised (the foe back
           to its base, one Upper on the caster, the raised marks), the caster at its DEF
           cap (the other buff taken); Bounce over the caster's MagicBack; SuckAll's side
           marks; the stance level 2 (StrongD) / 4 (BladeD); Focus $40 -> the caster's
           $80; a transformed foe's raised DEF is not taken; an iron foe's Barrier is
           taken, its iron stays; an enemy caster robs party slot 0. The line: [INS 00]
           the foe, [INS 20] the caster, [INS 30] the buff's stock-skill name; after the
           attack animation (the beats: announce -> animation -> the result);
  bosses   the BANDIT (INT 200): with no buff on the party it never casts Plunder (the AI
           veto); with Barrier + TailWind held on party slot 1 it plunders slot 1 only;
           the BUFF KNIGHT buffs itself.

  python3 tools/walk_plunder.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative] [--steps gift,numbers,bosses]

--negative: the ROM copy without Plunder's effect (SkillPlunder, StealApply72 and the AI's
ScoreSteal72 return at once — the AI then vetoes nothing / scores 0): the effect checks
must FAIL. Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import io
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import GAME_MODE                                # noqa: E402
from tools.walk_regions import s_continue                                # noqa: E402
from tools.walk_skills import SkillWalk, CURSE_ATTACK, WCUSTOMLINE, r16, w16, HP  # noqa: E402
from simulator import battle as SB                                        # noqa: E402
from simulator.skillfx import s155_custom as SC                           # noqa: E402
from simulator.skillfx import f6_defence as F6                            # noqa: E402
from editor2.core import monster_text as MT                               # noqa: E402
from editor2.core import skills as SK                                     # noqa: E402

PLUNDER, BARRIER, UPPER, CHARGEUP = 0xEA, 0x24, 0x1E, 0x41
INCREASE, SPEEDUP, TAILWIND = 0x1F, 0x23, 0x8A
DEF_, AGL_, MP_ = 0xDBF3, 0xDC03, 0xDBC3


def board_now(m, base):
    """A simulator Board of the live battle (the bytes Plunder reads / writes)."""
    b = SB.Board()
    b.st = [m[0xDB00 + i] for i in range(64)]
    b.ext['f7_db40'] = m[0xDB40]
    b.ext['f10_db41'] = m[0xDB41]
    b.ext['f6_db4a'] = [m[0xDB4A], m[0xDB4B]]
    b.dfn = [r16(m, DEF_ + 2 * s) for s in range(8)]
    b.agl = [r16(m, AGL_ + 2 * s) for s in range(8)]
    b.dd1b = [m[0xDD1B + s] for s in range(8)]
    b.link = bool(m[0xC86C])
    b.base['dfn'] = list(base['dfn'])
    b.base['agl'] = list(base['agl'])
    return b


def bytes_of(b):
    return (tuple(b.st), b.ext.get('f7_db40', 0), b.ext.get('f10_db41', 0),
            tuple(F6.db4a(b)), tuple(b.dfn), tuple(b.agl))


def tx(m, a):
    out = bytearray()
    for i in range(16):
        c = m[a + i]
        if c == 0xF0:
            break
        out.append(c)
    return bytes(out)


class PlunderWalk(SkillWalk):
    def plunder(self, caster, target, setup, seed=(0x5A, 0xA5), frames=2600, pin=True):
        """A forced Plunder (the rig) with setup(m) applied in the command phases. ->
        [{'exp': (outcome, got, after-bytes), 'rom': after-bytes, 'name', 'ins',
        'mp', 'msg', 'beats'}] per cast."""
        p, m = self.p, self.m
        base = {}
        runs = []
        cur = {}

        def setup_once(mm):
            if not base:
                base['dfn'] = [r16(mm, DEF_ + 2 * s) for s in range(8)]
                base['agl'] = [r16(mm, AGL_ + 2 * s) for s in range(8)]
            setup(mm, base)
            if not pin:                     # the seed in the command phases only (the
                mm[0xC899], mm[0xC89A] = seed   # rig's own pin would hold the act's RNG)

        def on_entry(_c):
            b = board_now(m, base)
            st = (m[0xC899] << 8) | m[0xC89A]
            a, t = m[0xDB88] & 7, m[0xDB89] & 7
            before_d, before_g = b.dfn[a], b.agl[a]
            out, got, _s = SC.plunder_one(b, a, t, st)
            cur.clear()
            cur.update({'exp': (out, got, bytes_of(b)), 'a': a, 't': t, 'f': p.frame_count,
                        'exp_before': before_d if got and SC.STEAL_TABLE[got[0]][4] == SC.S_DEF
                        else before_g})

        def on_line(_c):
            if not cur or m[0xDB8A] != PLUNDER:
                return
            cur['rom'] = bytes_of(board_now(m, base))
            cur['ins'] = [tx(m, 0xC180 + 16 * k) for k in range(4)]
            cur['mp'] = r16(m, MP_ + 2 * cur['a'])
            cur['msg'] = (m[0xC823], m[WCUSTOMLINE])
            cur['db56'] = r16(m, 0xDB56)
            cur['line_f'] = p.frame_count
            runs.append(dict(cur))
            cur.clear()

        b1, a1 = self.sym['SkillPlunder']
        b2, a2 = self.sym['LoadB4c_CustomLine']
        p.hook_register(b1, a1, on_entry, None)
        p.hook_register(b2, a2, on_line, None)
        # the $BB render: the rig hooks $4C:$42D1 itself; read the fail from its log
        lg = self.rig(caster, PLUNDER, target, frames=frames, board=setup_once, others=CURSE_ATTACK,
                      pin=pin)
        p.hook_deregister(b1, a1)
        p.hook_deregister(b2, a2)
        fails = [e for e in lg['msgs'] if e[0] == 0xBB and e[2] == PLUNDER]
        vis = [e[0] for e in lg['ev'] if e[1] == 'vis' and e[2] == PLUNDER and e[3] == 5]
        for rr in runs:
            rr['slash_f'] = next((f for f in vis if rr['f'] - 2 <= f <= rr['line_f']), None)
        return runs, fails, lg, cur


def name_of(sid):
    return MT.encode_name(SK.vanilla_name(sid, REPO), 'n')


def s_gift(w):
    print('gift: the GIFT MASTER')
    mid = w.rooms['hall']
    w.goto(mid, 0, 5, 6)
    before = w.records()
    w.face('up')
    r = w.talk([True])
    w.idle()
    after = w.records()
    new = [x for x in after if x not in before]
    w.check('the GIFT MASTER (YES) gives PLUNDERER with Plunder / Barrier / Upper / ChargeUP',
            any(x[2][:4] == [PLUNDER, BARRIER, UPPER, CHARGEUP] for x in new),
            f'{r}; new {[(k, f, [hex(s) for s in sk[:4]]) for k, f, sk in new]}')
    w.face('up')
    w.talk([False, True])
    w.idle()
    new2 = [x for x in w.records() if x not in after]
    w.check('(NO, YES) gives SHIELDER with Barrier / Increase / SpeedUp / TailWind',
            any(x[2][:4] == [BARRIER, INCREASE, SPEEDUP, TAILWIND] for x in new2),
            f'new {[(k, f, [hex(s) for s in sk[:4]]) for k, f, sk in new2]}')
    w.snap('gift')


def s_numbers(w):
    print('numbers: forced Plunder casts (the RNG pinned), the ROM against the simulator twin')
    st = io.BytesIO()
    w.p.save_state(st)
    m = w.m

    def run(setup, caster=1, target=4, seed=(0x5A, 0xA5), frames=2600, pin=True):
        st.seek(0)
        w.p.load_state(st)
        runs, fails, lg, cur = w.plunder(caster, target, setup, seed=seed, frames=frames, pin=pin)
        return runs, fails, lg

    def after(rr, t, k):
        """The ROM's byte +k of slot t at the result line."""
        i = 8 * t + k
        return rr['rom'][0][i] if i < 64 else rr['rom'][1 if k == 8 else 2]

    def same(rr):
        return rr.get('rom') is not None and rr['exp'][2] == rr['rom']

    def blk(t, k):
        return 0xDB00 + 8 * t + k

    # every one of the 18 buffs alone on the foe (DEF / AGL: raised twice, the mark on)
    for i, (off, mask, _c, val, kind, nm) in enumerate(SC.STEAL_TABLE):
        def setup(mm, base, off=off, mask=mask, kind=kind):
            if kind == SC.S_DEF:
                w16(mm, DEF_ + 8, base['dfn'][4] * 2)
                mm[blk(4, 8)] |= 0x40
            elif kind == SC.S_AGL:
                w16(mm, AGL_ + 8, base['agl'][4] * 2)
                mm[blk(4, 8)] |= 0x40
            elif kind == SC.S_SUCK:
                mm[blk(4, 8)] |= 0x02
                mm[0xDB01] |= 0x40
                mm[0xDB4B] = (mm[0xDB4B] & 3) | 0x04          # the user: slot 5 (&3 = 1)
            elif kind == SC.S_STANCE:
                mm[blk(4, 9)] = (mm[blk(4, 9)] & 0xF0) | 0x01
            elif off == 7:
                mm[blk(4, 7)] = (mm[blk(4, 7)] & 0xF3) | 0x08
            elif off == 6 and mask == 0xC0:
                mm[blk(4, 6)] = (mm[blk(4, 6)] & 0x3F) | 0x40   # Focus: this round's follow-up
            elif off == 6:
                mm[blk(4, 6)] |= mask & 0x11 or mask        # ChargeUP $01 / SuckAir $10
            else:
                mm[blk(4, off)] |= mask
        runs, fails, _lg = run(setup)
        rr = runs[0] if runs else {}
        exp = rr.get('exp', (None, None, None))
        name = name_of(exp[1][1]) if exp[1] else None
        good = (rr and exp[0] == 'ok' and exp[1][0] == i and same(rr)
                and rr['ins'][3] == name and rr['msg'] == (0xFD, exp[1][3])
                and rr['db56'] == exp[1][2] and (exp[1][3] == 6) == (kind not in (SC.S_DEF, SC.S_AGL))
                and rr['slash_f'] is not None and rr['line_f'] - rr['slash_f'] <= 2)
        w.check(f'{SK.vanilla_name(nm, REPO)} (row {i}) alone on the foe: stolen as the twin '
                'says, the line names it, with the cast\'s visual', good,
                f"exp {exp[:2]}, rom==twin {same(rr) if rr else None}, $C1B0 "
                f"{rr.get('ins', [b''] * 4)[3].hex() if rr.get('ins') else None} want "
                f"{name.hex() if name else None}, msg {rr.get('msg')}, $DB56 {rr.get('db56')}, the visual @"
                f"{rr.get('slash_f')} with the line @{rr.get('line_f')}")
        if kind in (SC.S_DEF, SC.S_AGL) and rr:
            digits = bytes(int(c) for c in str(exp[1][2]))
            w.check(f'… [S156 r2] the {"DEF" if kind == SC.S_DEF else "AGL"} rise page: line '
                    f'{exp[1][3]}, [INS 10] = the rise {exp[1][2]} (the caster\'s stat after '
                    '- before)', rr['ins'][1] == digits and exp[1][2] > 0
                    and rr['rom'][4 if kind == SC.S_DEF else 5][1] - rr['exp_before'] == exp[1][2],
                    f"[INS 10] {rr['ins'][1].hex()}, rise {exp[1][2]}")
        if kind == SC.S_SUCK and rr:
            w.check('… SuckAll: the foe side\'s mark gone ($DB01 bit 6, $DB4B bits 3:2), the '
                    'party side\'s set with the caster ($DB00 bit 6, $DB4A = 1 << 2)',
                    bool(not after(rr, 0, 1) & 0x40 and after(rr, 0, 0) & 0x40
                         and rr['rom'][3][0] & 0x0C == 0x04 and rr['rom'][3][1] & 0x0C == 0),
                    f"side bytes ${after(rr, 0, 0):02X} ${after(rr, 0, 1):02X}, $DB4A/B {rr['rom'][3]}")
        if i == 4 and rr:
            ins = rr['ins']
            w.check('… [INS 00] = the foe, [INS 20] = the caster (the game\'s own fills at the '
                    'result line)', ins[0] and ins[2] and ins[0] != ins[2],
                    f'{[x.hex() for x in ins]}')
            w.snap('plunder_line')
    # nothing on the foe -> "But nothing happens!", the MP spent
    runs, fails, lg = run(lambda mm, base: None, frames=2600)
    w.check('no buff on the foe: "But nothing happens!" ($BB), no line 6', fails and not runs,
            f'$BB {len(fails)}, lines {len(runs)}')
    # prefer what the caster lacks: Barrier + TailWind on the foe, TailWind on the caster
    picks = []
    for seed in ((0x00, 0x01), (0x40, 0x22), (0x99, 0x10), (0xF0, 0xEE)):
        def setup(mm, base):
            mm[blk(4, 4)] |= 0x44
            mm[blk(1, 4)] |= 0x40
        runs, _f, _l = run(setup, seed=seed, pin=False)
        picks.append((runs[0]['exp'][1][0] if runs and runs[0]['exp'][1] else None,
                      same(runs[0]) if runs else False))
    w.check('the caster\'s own buffs are skipped: Barrier + TailWind on the foe, TailWind on '
            'the caster -> Barrier (row 4) on 4 seeds', all(p == (4, True) for p in picks),
            f'{picks}')
    # three buffs, 8 seeds: the twin's pick each time, more than one row seen
    picks = []
    for k in range(8):
        def setup(mm, base):
            mm[blk(4, 4)] |= 0x05            # TakeMagic + Barrier
            mm[blk(4, 3)] |= 0x04            # TwinHits
        runs, _f, _l = run(setup, seed=(k * 37 & 0xFF, k * 91 & 0xFF), pin=False)
        picks.append((runs[0]['exp'][1][0] if runs and runs[0]['exp'][1] else None,
                      same(runs[0]) if runs else False))
    w.check('three buffs (TwinHits, TakeMagic, Barrier) over 8 seeds: the twin\'s pick each '
            'time, several rows', all(s for _p, s in picks) and len({p for p, _s in picks}) >= 2,
            f'{picks}')
    # DEF raised + AGL raised: one taken, the mark stays for the other
    def both(mm, base):
        w16(mm, DEF_ + 8, base['dfn'][4] * 2)
        w16(mm, AGL_ + 8, base['agl'][4] * 2)
        mm[blk(4, 8)] |= 0x40
    runs, _f, _l = run(both)
    rr = runs[0] if runs else {}
    w.check('DEF + AGL raised on the foe: one back to base, the raised mark kept for the other; '
            'one Upper / Speed on the caster (= the twin)', rr and same(rr)
            and after(rr, 4, 8) & 0x40 and after(rr, 1, 8) & 0x40, f"exp {rr.get('exp', (0, 0))[:2]}")
    # the caster at its DEF cap: DEF raised + Barrier on the foe -> Barrier taken
    def capped(mm, base):
        w16(mm, DEF_ + 8, base['dfn'][4] * 2)
        mm[blk(4, 8)] |= 0x40
        mm[blk(4, 4)] |= 0x04
        w16(mm, DEF_ + 2, min(999, base['dfn'][1] * 4))
    runs, _f, _l = run(capped)
    rr = runs[0] if runs else {}
    w.check('the caster at its DEF cap: the foe\'s raised DEF is skipped, its Barrier taken',
            rr and same(rr) and rr['exp'][1] and rr['exp'][1][0] == 4,
            f"exp {rr.get('exp', (0, 0))[:2]}")
    # Bounce on the foe, MagicBack on the caster -> the caster has Bounce only
    def bounce(mm, base):
        mm[blk(4, 4)] |= 0x02
        mm[blk(1, 4)] |= 0x20
    runs, _f, _l = run(bounce)
    rr = runs[0] if runs else {}
    w.check('Bounce over the caster\'s MagicBack: Bounce replaces it ($02, as cast)',
            rr and same(rr) and after(rr, 1, 4) & 0x22 == 0x02,
            f"caster +4 ${after(rr, 1, 4):02X}" if rr else '')
    # the stance by level: 2 -> StrongD, 4 -> BladeD
    for lvl, nm in ((2, 0x8E), (4, 0x90)):
        def stance(mm, base, lvl=lvl):
            mm[blk(4, 9)] = (mm[blk(4, 9)] & 0xF0) | lvl
        runs, _f, _l = run(stance)
        rr = runs[0] if runs else {}
        w.check(f'the Defence stance at level {lvl}: the caster at level {lvl}, the line says '
                f'{SK.vanilla_name(nm, REPO)}', rr and same(rr) and after(rr, 1, 9) & 0x07 == lvl
                and rr['ins'][3] == name_of(nm), f"$C1B0 {rr.get('ins', [b''] * 4)[3].hex() if rr else ''}")
    # Focus $40 on the foe -> the caster $80 (fresh: its follow-up next round)
    runs, _f, _l = run(lambda mm, base: mm.__setitem__(blk(4, 6), (mm[blk(4, 6)] & 0x3F) | 0x40))
    rr = runs[0] if runs else {}
    w.check('Focus ($40, this round\'s follow-up) on the foe -> the caster $80 (fresh), the foe '
            'none', rr and same(rr) and after(rr, 1, 6) & 0xC0 == 0x80
            and after(rr, 4, 6) & 0xC0 == 0, f"caster +6 {after(rr, 1, 6):02X}" if rr else '')
    # a transformed foe's raised DEF is not taken (fails)
    def transformed(mm, base):
        w16(mm, DEF_ + 8, base['dfn'][4] * 2)
        mm[blk(4, 8)] |= 0x40
        mm[blk(4, 3)] |= 0x20
    runs, fails, _l = run(transformed)
    w.check('a transformed foe\'s raised DEF is not a buff Plunder takes: "But nothing '
            'happens!"', fails and not runs, f'$BB {len(fails)}, lines {len(runs)}')
    # an iron foe: its Barrier is taken, the iron stays
    def iron(mm, base):
        mm[blk(4, 7)] |= 0xC0
        mm[blk(4, 4)] |= 0x04
    runs, _f, _l = run(iron)
    rr = runs[0] if runs else {}
    w.check('an iron foe: its Barrier is taken (Plunder always lands), its iron stays',
            rr and same(rr) and rr['exp'][1] and rr['exp'][1][0] == 4
            and after(rr, 4, 7) & 0xC0 == 0xC0, f"exp {rr.get('exp', (0, 0))[:2]}")
    # an enemy caster robs party slot 0
    def party_buff(mm, base):
        mm[blk(0, 4)] |= 0x04
    runs, _f, _l = run(party_buff, caster=4, target=0)
    rr = runs[0] if runs else {}
    w.check('the foe (slot 4) plunders party slot 0\'s Barrier (= the twin)',
            rr and same(rr) and rr['exp'][1] and rr['exp'][1][0] == 4 and rr['a'] == 4,
            f"exp {rr.get('exp', (0, 0))[:2]}")
    # [S156 r2] an enemy caster steals party slot 0's raised AGL: line 8, its own rise
    def party_agl(mm, base):
        w16(mm, AGL_, base['agl'][0] * 2)
        mm[blk(0, 8)] |= 0x40
    runs, _f, _l = run(party_agl, caster=4, target=0)
    rr = runs[0] if runs else {}
    exp = rr.get('exp', (None, None))
    w.check('[S156 r2] the foe (slot 4) steals party slot 0\'s raised AGL: line 8 (+ the rise '
            'page), [INS 20] = the foe, [INS 10] = its AGL rise (= the twin)',
            rr and same(rr) and exp[1] and exp[1][0] == 13 and rr['msg'] == (0xFD, 8)
            and exp[1][2] > 0 and rr['db56'] == exp[1][2]
            and rr['ins'][1] == bytes(int(c) for c in str(exp[1][2])),
            f"exp {exp[:2]}, msg {rr.get('msg')}, [INS 10] {rr.get('ins', [b'', b''])[1].hex()}")
    # [S156 r2] the caster cannot rise (at its cap) and has every other buff: the raised
    # DEF is taken anyway (any), nothing rises -> the plain line 6, no number
    def capped_only(mm, base):
        w16(mm, DEF_ + 8, base['dfn'][4] * 2)
        mm[blk(4, 8)] |= 0x40
        w16(mm, DEF_ + 2, min(999, base['dfn'][1] * 4))
    runs, _f, _l = run(capped_only)
    rr = runs[0] if runs else {}
    exp = rr.get('exp', (None, None))
    w.check('[S156 r2] a raised DEF taken by a caster at its DEF cap: nothing rises -> line 6 '
            '(no rise page)', rr and same(rr) and exp[1] and exp[1][0] == 12 and exp[1][2] == 0
            and rr['msg'] == (0xFD, 6), f"exp {exp[:2]}, msg {rr.get('msg')}")
    # the MP: one cast with the MP left alone after the command phase: 6 spent
    st.seek(0)
    w.p.load_state(st)
    mp = []
    b_, a_ = w.sym['SkillPlunder']
    w.p.hook_register(b_, a_, lambda _c: mp.append(r16(m, MP_ + 2)), None)
    lg = w.rig(1, PLUNDER, 4, frames=1400, others=CURSE_ATTACK)
    w.p.hook_deregister(b_, a_)
    w.check('the MP is spent even when nothing happens (200 -> 194 at the handler)',
            mp and mp[0] == 194, f'MP at the handler {mp[:3]}')


def boss_battle(w, x, y, frames, hooks, board=None, above=False):
    mid = w.rooms['hall']
    w.goto(mid, 0, 10 + x, y - 1 if above else y + 1)
    w.face('down' if above else 'up')
    r = w.talk([True])
    if r != 'battle':
        return r
    p, m = w.p, w.m
    for lab, fn in hooks.items():
        b, a = w.sym[lab]
        p.hook_register(b, a, fn, None)
    for i in range(frames):
        if m[GAME_MODE] == 2 and 4 <= m[0xD9EC] <= 6:
            for k in range(3):
                if m[0xDD1B + k] == 0:
                    w16(m, HP + 2 * k, 400)
                    w16(m, 0xDBB3 + 2 * k, 999)
            for s in range(3):
                if m[0xDD1B + 4 + s] == 0 and r16(m, HP + 8 + 2 * s) < 150:
                    w16(m, HP + 8 + 2 * s, 300)
            if board:
                board(m)
        if i % 8 < 4:
            p.button_press('a')
        else:
            p.button_release('a')
        p.tick()
    p.button_release('a')
    for lab in hooks:
        b, a = w.sym[lab]
        p.hook_deregister(b, a)
    w.battle_won()
    w.idle()
    return 'battle'


def s_bosses(w):
    print('bosses: the BANDIT (the AI: veto / target), the BUFF KNIGHT (it buffs itself)')
    m = w.m
    casts, acts = [], []

    def pl(_c):
        casts.append((m[0xDB88], m[0xDB89]))

    def act(_c):
        if m[0xDB88] == 4:
            acts.append(m[0xDB8A])
    hooks = {'SkillPlunder': pl, 'FarSkillFork': act}
    r = boss_battle(w, 6, 5, 7000, hooks)
    w.check('the BANDIT battle starts (YES)', r == 'battle', r)
    w.check('… no buff on the party: the BANDIT never casts Plunder (the AI veto) but acts',
            not any(a == 4 for a, _t in casts) and len(acts) >= 3,
            f'plunders {casts[:4]}, its acts {[hex(a) for a in acts[:8]]}')
    casts.clear()
    acts.clear()

    def buffs(mm):
        mm[0xDB00 + 8 + 4] |= 0x44           # Barrier + TailWind on party slot 1
    r = boss_battle(w, 6, 5, 9000, hooks, board=buffs)
    mine = [(a, t) for a, t in casts if a == 4]
    w.check('… Barrier + TailWind held on party slot 1: the BANDIT plunders, always slot 1',
            mine and all(t == 1 for _a, t in mine), f'plunders {mine[:6]}')
    seen = []

    def kn(_c):
        if m[0xDB88] == 4:
            seen.append(m[0xDB8A])
    r = boss_battle(w, 3, 2, 7000, {'FarSkillFork': kn}, above=False)
    w.check('the BUFF KNIGHT battle starts', r == 'battle', r)
    w.check('… the BUFF KNIGHT buffs itself (Upper / Barrier / ChargeUP / TailWind)',
            any(s in (UPPER, BARRIER, CHARGEUP, TAILWIND) for s in seen),
            f'its acts {[hex(s) for s in seen[:10]]}')


def negative_rom(w):
    rom = bytearray(open(w.rom, 'rb').read())
    for lab in ('SkillPlunder', 'ScoreSteal72'):
        b, a = w.sym[lab]
        o = b * 0x4000 + a - 0x4000
        rom[o] = 0xC9                                    # ret
    b, a = w.sym['ScoreSteal72']                         # ScoreSteal72: xor a / ret
    o = b * 0x4000 + a - 0x4000
    rom[o:o + 2] = bytes([0xAF, 0xC9])
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print('NEGATIVE CONTROL: SkillPlunder = ret, ScoreSteal72 = xor a / ret')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--steps', default='gift,numbers,bosses')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = PlunderWalk(a.build, a.sav, a.keep)
    d = json.load(open(a.project))
    ids = {r['id']: int(r['mapID'], 16) for r in d['custom']['rooms']}
    w.rooms = {'cities_fount': ids['cities_fount'], 'hall': ids['rogue_hall']}
    if a.negative:
        negative_rom(w)
    s_continue(w)
    w.save('start')
    steps = {'gift': s_gift, 'numbers': s_numbers, 'bosses': s_bosses}
    for name in a.steps.split(','):
        try:
            w.start('start')
            steps[name](w)
        except Exception as e:                       # noqa: BLE001 — a step that crashes fails
            import traceback
            traceback.print_exc()
            w.check(f'{name} ran', False, repr(e))
    print(f'WALK: {"PASS" if not w.fails else "FAIL " + str(w.fails)} ({w.checks} checks)')
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
