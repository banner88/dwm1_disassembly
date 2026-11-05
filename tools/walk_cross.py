#!/usr/bin/env python3
"""walk_cross.py — the Breeding tab's "Try a cross" baby (editor2/core/cross.py, S169)
against the game's own breeding routines, on the monsters of a REAL battery save.

For every ordered pair of the save's monsters (party + farm; eggs skipped) the two
149-byte records are staged as the game stages them (slot 20 = pedigree $D665, slot 21
= mate $D6FA), the player's name from the save is put at $CA42, the RNG is pinned, and
bank $16 entry 0 `BreedCreateOffspring` runs (`ld hl,$1600 / rst $10`, the stub of
tools/census_raising.py); then bank $16 entry 4 `BreedBirthFinalize` ($1604). Checked
against `cross.baby` (the editor's panel):

  egg      species + plus (the resolver, editor2/core/breeding.py), max level, the six
           stats (k from the records: `cross.pedigree_k_of_records`), the four AI
           bytes (the dropped carry), resistances + gender (raising.breed with the
           same pin — the panel's chances are counted over that model);
  birth    the learn queue as the hatched monster holds it (`cross.baby['queue']`);
  timeline (the first --timeline pairs) the newborn levelled in the game, level by
           level, with the RNG pinned to the panel's own trace (`cross.timeline`):
           every skill the game's learn pass offers == the panel's row for that level,
           until the monster would know more than 8 (the forget menu: the player's choice).

Variants: every pair again with the PEDIGREE's master name changed (k + 1) and with
the MATE given a pedigree whose two names are not the player's (k + 2) — the +2 % per
name. Negative control (--negative): the panel's k forced to 0 — the variants FAIL.

Usage: walk_cross.py --rom ROM --project DIR --sav SAV [--timeline N] [--negative]
Exit 0 = every check passed.
"""
import argparse
import os
import shutil
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

from tools import census_raising as CR          # noqa: E402
from tools.pyboy_harness import boot, adv       # noqa: E402
from simulator import raising as R              # noqa: E402
from editor2.core import cross as X             # noqa: E402
from editor2.core import savefile as SF         # noqa: E402
from editor2.core import breeding as BR         # noqa: E402

REC = CR.REC
SLOT0 = CR.SLOT0


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--timeline', type=int, default=12)
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args(argv)

    from editor2.core.project import Project
    prj = Project.load(a.project)
    T = X.tables(prj)
    an = BR.Analysis(prj)
    sav = open(a.sav, 'rb').read()
    ro = SF.read_roster(sav, T.names)
    slots = sorted(ro['monsters'])
    player = X.player_name(sav)

    tmp = tempfile.mkdtemp()
    rom = os.path.join(tmp, 'cross.gbc')
    shutil.copy(a.rom, rom)
    sym = os.path.join(os.path.dirname(a.rom), 'game.sym')
    tail = 0x5C23
    if os.path.exists(sym):
        for line in open(sym):
            if line.strip().endswith(' jr_051_5c23'):
                tail = int(line.split()[0].split(':')[1], 16)
    p = boot(rom)
    adv(p, 600)
    m = p.memory
    CR.arm_tail_hook(p, tail)
    for i, b in enumerate(player):
        m[CR.PLAYER_NAME + i] = b

    ok = fail = 0
    tl_levels = tl_offers = 0
    fails = []

    def check(label, cond, detail=''):
        nonlocal ok, fail
        if cond:
            ok += 1
        else:
            fail += 1
            fails.append(f'{label}: {detail}')

    def variant_records(r1, r2, kind):
        r1, r2 = bytearray(r1), bytearray(r2)
        if kind == 'master':                      # the pedigree came from another master
            r1[0x0C] = (r1[0x0C] + 1) & 0xFF
        elif kind == 'pedigree':                  # the mate has a pedigree of strangers
            r2[0x15] = 0                          #   (+$15 / +$16 != $FF)
            r2[0x16] = 1
            for o in (0x83, 0x8C):
                for i in range(X.NAME_LEN):
                    r2[o + i] = (player[i] + 1) & 0xFF
        return bytes(r1), bytes(r2)

    seed = 0x4A1D
    n_pair = 0
    for kind in ('save', 'master', 'pedigree'):
        for s1 in slots:
            for s2 in slots:
                if s1 == s2:
                    continue
                r1 = X.save_record(sav, s1)
                r2 = X.save_record(sav, s2)
                r1, r2 = variant_records(r1, r2, kind)
                p1 = SF.monster_from_record(r1, T.names, s1)
                p2 = SF.monster_from_record(r2, T.names, s2)
                p1.foreign = int(r1[0x0C:0x0C + X.NAME_LEN] != player)
                p2.foreign = int(r2[0x0C:0x0C + X.NAME_LEN] != player)
                k = X.pedigree_k_of_records(r1, r2, player)
                k_panel = 0 if a.negative else k
                c = an.br.resolve(p1.species, p2.species, p1.plus, p2.plus, p1.level, p2.level)
                b = X.baby(T, p1, p2, c.species, c.plus, k_panel)
                # --- the game
                for i in range(REC):
                    m[CR.STAGE20 + i] = r1[i]
                    m[CR.STAGE21 + i] = r2[i]
                for s in range(3):
                    for i in range(REC):
                        m[SLOT0 + s * REC + i] = 0
                seed = (seed * 5 + 0x1357) & 0xFFFF
                st = seed
                CR.pin(m, st)
                CR.stub_rst(m, p, 0x1600)
                g = CR.read_rec(m, 0)
                tag = f'{kind} {T.names.get(p1.species)}#{s1} x {T.names.get(p2.species)}#{s2}'
                check(tag + ' species/plus', (g['species'], g['plus']) == (c.species, c.plus),
                      f"game {(g['species'], g['plus'])} panel {(c.species, c.plus)}")
                check(tag + ' max level', g['cap'] == b['cap'], f"game {g['cap']} panel {b['cap']}")
                check(tag + ' stats', g['stats'] == [r[4] for r in b['stats']],
                      f"game {g['stats']} panel {[r[4] for r in b['stats']]} (k {k_panel}, true {k})")
                ai_panel = [0] * 4
                for j, row in enumerate(b['ai']):
                    ai_panel[X.AI_RECORD_TO_NAME[j]] = row[3]
                check(tag + ' AI', g['ai'] == ai_panel, f"game {g['ai']} panel {ai_panel}")
                mod = R.breed(T, p1, p2, g['species'], g['plus'], R.GameRNG(st), foreign=k_panel)
                check(tag + ' resist+gender', (g['res'], g['female']) == (mod.res, mod.female),
                      'rolls differ')
                check(tag + ' knows nothing', g['skills'] == [], str(g['skills']))
                # birth
                m[CR.CAC0] = 0
                m[0xCA40] = 0
                CR.stub_rst(m, p, 0x1604)
                gb = CR.read_rec(m, 0)
                check(tag + ' queue after birth', gb['queue'] == b['queue'],
                      f"game {gb['queue']} panel {b['queue']}")
                # timeline
                if kind == 'save' and n_pair < a.timeline:
                    trace = []
                    tl, _grown = X.timeline(T, b['born'], trace=trace)
                    by_level = {}
                    for lv, sid, _how, _old in tl:
                        by_level.setdefault(lv, []).append(sid)
                    for lv, state in trace:
                        known_before = [m[SLOT0 + 0x29 + i] for i in range(8) if m[SLOT0 + 0x29 + i] != 0xFF]
                        m[CR.CAC0] = 0
                        CR.pin(m, state)
                        CR.stub_rst(m, p, 0x1302)
                        for i in range(40):
                            m[CR.C0D8 + i] = 0xFF
                        for i in range(8):
                            m[CR.C0D8 + i] = m[SLOT0 + 0x29 + i]
                        CR.run_learn(m, p)
                        work = [m[CR.C0D8 + i] for i in range(40) if m[CR.C0D8 + i] != 0xFF]
                        # new ids this level (an upgrade replaces its old id in place)
                        offered = [s for s in work if s not in known_before]
                        if len(work) > 8:
                            break                     # the forget menu: the player's choice
                        check(f'{tag} timeline Lv{lv + 1}', sorted(offered) == sorted(by_level.get(lv + 1, [])),
                              f'game {offered} panel {by_level.get(lv + 1, [])}')
                        tl_levels += 1
                        tl_offers += len(offered)
                        for i in range(8):
                            m[SLOT0 + 0x29 + i] = work[i] if i < len(work) else 0xFF
                        CR.TAIL_HOOK['armed'] = True
                        CR.stub_rst(m, p, 0x510D)
                        CR.TAIL_HOOK['armed'] = False
                n_pair += 1
    print(f'walk_cross: {n_pair} breeds ({len(slots)} save monsters, 3 kinds), timeline '
          f'{tl_levels} level-ups / {tl_offers} skills offered: {ok} OK, {fail} FAIL')
    for f in fails[:25]:
        print('  FAIL', f)
    return 0 if fail == 0 else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
