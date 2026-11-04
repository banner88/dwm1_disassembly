#!/usr/bin/env python3
"""walk_actbase.py — S163 (ROADMAP E17 note "Act-time id lists") on the real game (PyBoy on
the user's .sav).

The demo (examples/s163_echo_demo/build_demo.py) = the user's project + THE ECHO HALL + one
NEW twin (high ids 239-252) of each of 14 stock skills whose effect the original game decides
partly by the acting id: Vivify / Revive, SickLick / LushLicks, TailWind / StormWind, Ahhh,
Sleep, LegSweep, Barrier, SquallHit, BeDragon, CallHelp, TakeMagic.

  twins    every pair cast by party slot 0 (the S110 forced-battle rig of walk_reclaim, the
           RNG pinned every frame — under three pinned values, so the hit rolls both land and
           miss — from ONE saved state; the board each skill needs: a dead
           ally for Vivify / Revive; TailWind / StormWind on the caster — TailWind has no WHO list, S163 r2): the battle
           messages (message, line, subject, number) AND the state after each message (the
           eight combatants' HP, MP and status bytes $DB00-$DB41, $DD1B) are the same for
           the stock skill and its new twin, the skill id aside;
  menu     (S163 r2 — the user's test: "EVivify cannot select [the] dead monster") the battle
           menu itself: PLAN -> COMMAND -> SKIL -> the skill -> WHO with party slot 1 fallen:
           Vivify and its twin both let the cursor onto the fallen ally (the target menu's copy
           $DD76 / $C1C2 of the id = the base), the act is queued on it and a Vivify line runs;
  sites    every act-time view call (ActBase / MenuBase / QueueBase / QueueBaseInc /
           CmpBase in banks $50 / $52 / $53 / $58, Entry1Base52) is in the ROM where the
           census put it (tools/census_act_id_lists.py: 47 + Entry1Base52, + the 2 target-menu copies of r2).

  python3 tools/walk_actbase.py --build DEMO/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative] [--steps twins,sites] [--set s165]

S165: --set s165 walks examples/s165_chorus_demo (the C… twins of the 17 bases the S163 census
never ran — the compiler refused them; patched S165: 23 more reads in banks $52 / $53 + the turn
order's defensive list in bank $58); the sites step counts the S165 calls too.

--negative: every view call put back to the original bytes in a ROM copy (`ld a, [$db8a]` /
`ld a, [$db4f]` / the queue tail / `call CmpBtlC_4b92` / SetHLBattle_7d77's far call): the
twins of the bases whose effect asks for its id must FAIL.
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import io
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.walk_regions import s_continue                                    # noqa: E402
from tools.walk_reclaim import ReclaimWalk, rom_off                          # noqa: E402
from tools.walk_skills import r16, w16, HP, MAXHP, MP, CURSE_ATTACK          # noqa: E402
from tools.pyboy_harness import adv, tap, GAME_MODE                          # noqa: E402

VIEW_PREFIX = ('ActBase', 'MenuBase', 'QueueBase', 'CmpBase')
# base: (target, board) — board(m) runs every frame of phases 4-6 after the rig's HP hold
TWINS = {
    48: (1, 'dead1'), 49: (1, 'dead1'),            # Vivify / Revive: a dead ally
    122: (4, None), 121: (4, None),                 # SickLick / LushLicks
    138: (0, None), 139: (0, None),                 # TailWind / StormWind: the caster (no WHO list)
    112: (4, None), 21: (4, None), 123: (4, None),  # Ahhh, Sleep, LegSweep
    36: (0, None), 85: (4, None), 213: (0, None), 82: (0, None), 27: (4, None),
}
SEEDS = [(0x5A, 0xA5), (0x08, 0x31), (0xE7, 0x6C)]   # the pinned RNG pairs: a roll that misses
                                                      # under one lands under another
# S165 (ROADMAP E13 note "the 17 bases a copy still cannot run"; examples/s165_chorus_demo, the
# twins named C…): the bases the S163 census never ran (the compiler refused them) — target = the
# record's (a foe for $1x modes, else the caster), Farewell with a fallen ally
TWINS_S165 = {
    20: (4, None), 40: (0, None), 50: (0, 'dead1'), 63: (4, None), 81: (4, None), 89: (4, None),
    109: (4, None), 114: (4, None), 128: (4, None), 130: (4, None), 131: (0, None),
    132: (0, None), 133: (0, None), 134: (0, None), 137: (0, None), 142: (0, None),
    144: (0, None),
}
NAMES_S165 = {20: 'Sacrifice', 40: 'Bounce', 50: 'Farewell', 63: 'Massacre', 81: 'QuadHits',
              89: 'Vacuum', 109: 'PoisonAir', 114: 'SandStorm', 128: 'DeMagic', 130: 'UltraDown',
              131: 'ThickFog', 132: 'TatsuCall', 133: 'DiagoCall', 134: 'SamsiCall',
              137: 'Guardian', 142: 'StrongD', 144: 'BladeD'}
NAMES = {48: 'Vivify', 49: 'Revive', 122: 'SickLick', 121: 'LushLicks', 138: 'TailWind',
         139: 'StormWind', 112: 'Ahhh', 21: 'Sleep', 123: 'LegSweep', 36: 'Barrier',
         85: 'SquallHit', 213: 'BeDragon', 82: 'CallHelp', 27: 'TakeMagic'}


def board_fn(kind):
    if kind == 'dead1':
        def f(m):
            m[HP + 2], m[HP + 3] = 0, 0                 # party slot 1 dead, processed
            m[0xDD1B + 1] = 1
        return f
    return None


def snapshot(m):
    return (tuple(r16(m, HP + 2 * j) for j in range(8)),
            tuple(r16(m, MP + 2 * j) for j in range(8)),
            tuple(m[0xDB00 + j] for j in range(0x42)),
            tuple(m[0xDD1B + j] for j in range(8)))


def s_twins(w):
    print('twins: each stock skill and its NEW twin cast by party slot 0 (RNG pinned)')
    st = io.BytesIO()
    w.p.save_state(st)

    def run(sk, target, board, seed):
        st.seek(0)
        w.p.load_state(st)
        states = []
        hooks = {(0x4C, 0x735E): lambda log: states.append(snapshot(w.m))}   # the jp target of $42D1
        # the RNG pinned at EVERY BattleRNG call too: it also steps while the CPU idles (S86),
        # so a new id's few extra cycles (its far calls) would move a later roll within a
        # frame (KEY_LESSONS S161) — the twins must see the same rolls to be compared
        b_, a_ = w.sym['BattleRNG']

        def pin(_log):
            w.m[0xC899], w.m[0xC89A] = seed
        hooks[(b_, a_)] = pin
        log = w.battle(3, 2600, party=CURSE_ATTACK, enemy=CURSE_ATTACK, caster=0, skill=sk,
                       target=target, board=board_fn(board), hooks=hooks, seed=seed)
        return log, states
    for (base, (target, board)), seed in [(x, sd) for x in TWINS.items() for sd in SEEDS]:
        new = w.E[base]
        a, sa = run(base, target, board, seed)
        b, sb = run(new, target, board, seed)
        ma = [t for t in a['msgs']]
        mb = [tuple(base if (j == 2 and x == new) else x for j, x in enumerate(t))
              for t in b['msgs']]
        ca = sum(1 for x in a['acts'] if x[0] == 0 and x[1] == base)
        cb = sum(1 for x in b['acts'] if x[0] == 0 and x[1] == new)
        # the fixed frame window may end one act apart (a few more CPU cycles on one side —
        # walk_mirror's S161 precedent): the common prefix is compared, and it must be long
        n_ = min(len(ma), len(mb))
        cut = n_ < max(len(ma), len(mb))
        ma, mb, sa, sb = ma[:n_], mb[:n_], sa[:n_], sb[:n_]
        k = next((i for i, (x, y) in enumerate(zip(ma, mb)) if x != y), None)
        ks = next((i for i, (x, y) in enumerate(zip(sa, sb)) if x != y), None)
        same = ma == mb and sa == sb
        if same:
            why = ''
        elif ma != mb:
            k = k if k is not None else min(len(ma), len(mb))
            why = f'messages differ at {k} (of {len(ma)} / {len(mb)}): {ma[k:k + 3]} vs {mb[k:k + 3]}'
        else:
            ks = ks if ks is not None else min(len(sa), len(sb))
            diff = []
            if ks < min(len(sa), len(sb)):
                for part, (x, y) in zip(('hp', 'mp', 'status', 'dd1b'), zip(sa[ks], sb[ks])):
                    if x != y:
                        diff.append((part, [(i, u, v) for i, (u, v) in enumerate(zip(x, y))
                                            if u != v][:4]))
            why = f'board differs after message {ks}: {diff}'
        w.check(f'{NAMES[base]} (${base:02X}) and its twin (${new:02X}), RNG ${seed[0]:02X}{seed[1]:02X}: '
                f'{ca} / {cb} casts, the '
                f'same {n_} battle messages and the same board after each'
                + (' (the window ended one message apart)' if cut else ''),
                ca > 0 and abs(ca - cb) <= int(cut) and n_ >= 5 and same, why)


def s_menu(w):
    """S163 r2: the target menu decides "may a fallen ally be chosen?" by a COPY of the id
    ($DD76 / $C1C2: bank $50 CheckBattlePhase / SaveBtl_5bc5 / LoadBtl_5bd7 compare it with
    Vivify $30 / Revive $31 / $BB) — taken when the menu opens, compared frames later, so the
    census's run from the read never reached the compare. Driven through the real menu."""
    print('menu: PLAN -> COMMAND -> SKIL -> the skill -> WHO, party slot 1 fallen')
    m, p = w.m, w.p
    st = io.BytesIO()
    p.save_state(st)
    for base in (48, 49, 138):
        res = {}
        for sk in (base, w.E[base]):
            st.seek(0)
            p.load_state(st)
            rec = 0xCAC1 + m[0xCA8E] * 0x95
            m[rec + 0x29] = sk                                   # the lead's first skill
            w16(m, rec + 0x54, 300)
            w16(m, rec + 0x56, 300)
            m[0xDA03], m[0xDA04] = 3, 0                          # the S110 forced battle, RNG free
            m[0xDA02], m[0xDA09], m[0xC905] = 0, 1, 0
            m[0xC8EB] |= 0x40
            for _ in range(400):
                adv(p, 10)
                if m[GAME_MODE] == 2 and m[0xD9EC] == 4 and m[0xD9F4] == 2:
                    break
            w16(m, HP + 2, 0)                                    # party slot 1 fallen
            m[0xDD1B + 1] = 1
            adv(p, 60)
            keys = 'down,a,down,down,down,down,a,down,a,a' + (',down,a' if base != 138 else '')
            for k in keys.split(','):
                tap(p, k, hold=4, wait=40)                       # PLAN, COMMAND, SKIL, it[, WHO v, A]
            res[sk] = (m[0xDD76], m[0xDCEC], m[0xDCED], m[0xD9F4])
        a, b = res[base], res[w.E[base]]
        if base == 138:
            # S163 r2 (the user: "ETailWind does NOT let you pick any monsters"): neither does the
            # stock TailWind — no WHO list; the act is queued on the caster (slot 0) at once
            w.check(f'TailWind (${base:02X}) and its twin (${w.E[base]:02X}) in the battle menu: no WHO '
                    f'list for either (the next monster\'s PLAN opens), the act queued on the caster',
                    a[1:] == (base, 0, 3) and b[1:] == (w.E[base], 0, 3),
                    f'stock {a}, twin {b} ($DD76, queued skill, target, $D9F4)')
            continue
        a, b = a[:3], b[:3]
        w.check(f'{NAMES[base]} (${base:02X}) and its twin (${w.E[base]:02X}) in the battle menu: the '
                f'WHO cursor reaches the fallen ally (slot 1) for both; the menu\'s copy $DD76 = '
                f'${base:02X} for both', a == (base, base, 1) and b == (base, w.E[base], 1),
                f'stock {a}, twin {b} ($DD76, queued skill, target)')


def s_sites(w):
    print('sites: the act-time view calls in the ROM')
    rom = open(w.rom, 'rb').read()
    targets = {(b, a): nm for nm, (b, a) in w.sym.items()
               if nm.startswith(VIEW_PREFIX + ('Entry1Base',)) and '.' not in nm}
    starts = {}
    for (b, a) in targets:
        starts.setdefault(b, []).append(a)
    per = {}
    for b in (0x50, 0x52, 0x53, 0x58):
        base = b * 0x4000
        lo = min(starts.get(b, [0x8000]))
        for i in range(0x4000 - 2):
            pc = 0x4000 + i
            if lo <= pc < lo + 0x60:                # the helpers' own block
                continue
            op = rom[base + i]
            if op in (0xCD, 0xC3):
                t = rom[base + i + 1] | rom[base + i + 2] << 8
                if (b, t) in targets:
                    per[b] = per.get(b, 0) + 1
    want = {0x50: 6, 0x52: 36, 0x53: 27, 0x58: 6}
    w.check(f'the act-time view calls are where the census put them ({per}: banks $50 4 + 2 menu copies, $52 '
            '22 + Entry1Base52 + 13 (S165), $53 17 + 10 (S165), $58 5 + 1 (S165: '
            'TurnOrderDefensiveBoost_56cf))', per == want, str(per))


def negative_rom(w):
    """Every act-time view call back to the original game's bytes."""
    rom = bytearray(open(w.rom, 'rb').read())
    orig = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    targets = {(b, a): nm for nm, (b, a) in w.sym.items()
               if nm.startswith(VIEW_PREFIX) and '.' not in nm}
    k = 0
    for b in (0x50, 0x52, 0x53, 0x58):
        base = b * 0x4000
        for i in range(0x4000 - 2):
            if rom[base + i] == 0xCD:
                t = rom[base + i + 1] | rom[base + i + 2] << 8
                nm = targets.get((b, t))
                if nm and orig[base + i:base + i + 3] != rom[base + i:base + i + 3] \
                        and orig[base + i] in (0xFA, 0x3E, 0xCD):
                    ln = 5 if nm.startswith('QueueBase') else 3
                    rom[base + i:base + i + ln] = orig[base + i:base + i + ln]
                    k += 1
    o = rom_off(w.sym, 'SetHLBattle_7d77')
    rom[o:o + 5] = orig[o:o + 5]
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print(f'NEGATIVE CONTROL: {k} view calls + SetHLBattle_7d77 put back to the original bytes')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--steps', default=None)
    ap.add_argument('--set', default='s163', choices=('s163', 's165'),
                    help='s163: the ECHO demo\'s E… twins (14 bases); s165: the CHORUS demo\'s C… '
                         'twins (the 17 bases S165 opened; steps twins,sites)')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = ReclaimWalk(a.build, a.sav, a.keep)
    d = json.load(open(a.project))
    sk = d['gamedata']['skills']
    pre = 'E' if a.set == 's163' else 'C'
    w.E = {v['base']: int(k) for k, v in sk.items()
           if isinstance(v, dict) and str(v.get('name', '')).startswith(pre) and 'base' in v}
    if a.set == 's165':
        TWINS.clear()
        TWINS.update(TWINS_S165)
        NAMES.update(NAMES_S165)
    if a.steps is None:
        a.steps = 'twins,menu,sites' if a.set == 's163' else 'twins,sites'
    if a.negative:
        negative_rom(w)
    s_continue(w)
    w.save('start')
    steps = {'twins': s_twins, 'menu': s_menu, 'sites': s_sites}
    for name in [x for x in a.steps.split(',') if x]:
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
