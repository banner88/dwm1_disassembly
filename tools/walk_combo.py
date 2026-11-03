#!/usr/bin/env python3
"""walk_combo.py — S164 (ROADMAP E13 note "'Evolves from' two or more skills on a custom / new
skill is never learned") on the real game (PyBoy on the user's .sav).

The demo (examples/s164_conflux_demo/build_demo.py) = the user's project + THE CONFLUX HALL:
FUSION (a NEW skill on Firebal, id 239) evolves from Blaze AND Bang at level 10 (no stat
minimums). Until S164 bank $06 LearnFence06 closed code 2 (all of 2-5 prerequisites known) for
every custom id ($DA+, S75) and the 14 reclaimed ids (S160): Fusion was never learned. S164:
LearnFence06 = `ld a, c / and a / ret` (open for every id).

  combo      party slot 2 = Blaze + Bang, level 9 (one EXP short of 10): beat the TRAINING
             DUMMY -> the battle ends, the record knows Fusion AND Blaze AND Bang (beside them,
             the first free slot); the level up's line for Fusion is code 2's own "… by chance,
             recalls …" ($0B0F, C = $FF: no old skill replaced) — FireSlash's line —, once;
  one        (control) Blaze only, level 9: Fusion is NOT learned (a combination needs ALL);
  full       eight skills with Blaze and Bang, level 9: the level up offers Fusion -> the game's
             forget menu (A), the battle ends, eight skills — never a hang;
  vanilla    (control) the original combination FireSlash (ChargeUP + Blazemore, level 11,
             MaxHP 77 / MP 34 / ATK 66 / INT 42): learned beside both, "recalls" ($0B0F);
  universal  the S75 premise re-measured: Mourn ($E9) and Tremor ($E5) — rows with NO
             prerequisite and zero stat minimums (levels 3 / 2) — are never learned at the
             level ups above by a monster whose learn queue (+$31, 25 B) lacks them: the scanner
             skips a row whose first prerequisite is $FF before it tests any (code 2 never
             reached), fence or no fence.

  python3 tools/walk_combo.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative] [--steps combo,one,full,vanilla,universal]

--negative: LearnFence06 put back to its S160 bytes in the ROM copy (code 2 fenced for $DA+ and
the 14 reclaimed ids): `combo` / `full` must FAIL (Fusion never learned), the controls pass.
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import GAME_MODE, PARTY_LIST                          # noqa: E402
from tools.walk_regions import s_continue                                    # noqa: E402
from tools.walk_skills import w16                                            # noqa: E402
from tools.walk_mirror import MirrorWalk, lines_str, rom_off                 # noqa: E402

LINE_RECALLS = 0x0B0F      # code 2's own level-up line "… by chance, recalls …" (BATTLE_SKILL_SYSTEM §13.12)

BLAZE, BLAZEMORE, BANG, CHARGEUP, FIRESLASH = 0, 1, 6, 65, 68
MOURN, TREMOR = 0xE9, 0xE5
# LearnFence06 as S160 built it (ROADMAP E13): ld a, c / cp $da / ccf / ret c / cp $bc / jr c,
# .open / cp $c2 / ret c / cp $cc / jr c, .open / cp $d4 / ret / .open: and a / ret
S160_FENCE = bytes([0x79, 0xFE, 0xDA, 0x3F, 0xD8, 0xFE, 0xBC, 0x38, 0x0A, 0xFE, 0xC2, 0xD8,
                    0xFE, 0xCC, 0x38, 0x03, 0xFE, 0xD4, 0xC9, 0xA7, 0xC9])


class ComboWalk(MirrorWalk):
    def fight_dummy(self, maxf=20000):
        """Talk to the TRAINING DUMMY (screen 0 (8, 5), from below), fight, A until the field
        is back. -> (talk result, back to the field, the level-up lines [(HL, C, $FFD8)])."""
        lines = []
        b, a = self.sym['jr_051_5799']

        def on_place(_):
            rf = self.p.register_file
            if len(lines) < 64:
                lines.append((rf.HL, rf.C, self.m[0xFFD8]))
        self.p.hook_register(b, a, on_place, None)
        try:
            self.goto(self.rooms['hall'], 0, 8, 6)
            self.face('up')
            r = self.talk([True])
            back = self.battle_won(maxf=maxf) if r == 'battle' else False
            self.idle()
        finally:
            self.p.hook_deregister(b, a)
        return r, back, lines

    def queue(self, k):
        return [self.rec(k, 0x31 + i) for i in range(25)]

    def stats(self, k, hp=99, atk=99):
        w16(self.m, self.base(k) + 0x52, hp)                # MaxHP
        w16(self.m, self.base(k) + 0x50, hp)                # HP
        w16(self.m, self.base(k) + 0x58, atk)               # ATK


def hexs(sk):
    return [hex(s) for s in sk]


def s_combo(w):
    print('combo: Blaze + Bang at level 9 -> Fusion (from both) learned beside them at 10')
    m = w.m
    k = m[PARTY_LIST + 2]
    w.setup(k, 9, [BLAZE, BANG], edge=True)
    w.queues.append(w.queue(k))
    r, back, lines = w.fight_dummy()
    sk = w.skills(k)
    w.learned.append(sk)
    w.snap('combo')
    lv = w.rec(k, 0x4B)
    w.check('the TRAINING DUMMY beaten, the battle ENDS (back to the field), party slot 2 reached '
            'level 10+', r == 'battle' and back and lv >= 10 and m[GAME_MODE] == 1,
            f'{r}, back {back}, level 9->{lv}')
    w.check(f'it knows Fusion (${w.FUSION:02X}) AND still Blaze and Bang (a combination: learned '
            'beside its prerequisites)', w.FUSION in sk and BLAZE in sk and BANG in sk, hexs(sk))
    fu = [x for x in lines if x[2] == w.FUSION]
    w.check('the line: code 2\'s "… by chance, recalls Fusion" ($0B0F, C = $FF: the first free '
            'slot, nothing replaced) — once', len(fu) == 1 and fu[0][0] == LINE_RECALLS
            and fu[0][1] == 0xFF,
            str(lines_str(lines)))
    w.save('after_combo')


def s_one(w):
    print('one: Blaze alone at level 9 -> no Fusion (a combination needs ALL its prerequisites)')
    m = w.m
    k = m[PARTY_LIST + 2]
    w.setup(k, 9, [BLAZE], edge=True)
    w.queues.append(w.queue(k))
    r, back, lines = w.fight_dummy()
    sk = w.skills(k)
    w.learned.append(sk)
    w.check('Blaze alone, level 9 -> 10+: the battle ends and Fusion is NOT learned',
            r == 'battle' and back and w.rec(k, 0x4B) >= 10 and w.FUSION not in sk,
            f'{r}, back {back}, level {w.rec(k, 0x4B)}, {hexs(sk)}, lines {lines_str(lines)}')


def s_full(w):
    print('full: eight skills with Blaze and Bang -> Fusion offered -> the forget menu')
    m = w.m
    k = m[PARTY_LIST + 2]
    eight = [BLAZE, BANG, 0x15, 0x1C, 0x2B, 0x33, 0x3D, 0x40]
    w.setup(k, 9, eight, edge=True)
    w.queues.append(w.queue(k))
    r, back, lines = w.fight_dummy(maxf=40000)
    sk = w.skills(k)
    w.learned.append(sk)
    w.snap('full')
    fu = [x for x in lines if x[2] == w.FUSION]
    w.check('the battle ends (the forget menu answered by A), eight skills, Fusion offered once '
            '(learned, or the menu forgot it)',
            r == 'battle' and back and 0xFF not in sk and len(set(sk)) == 8 and len(fu) == 1,
            f'{r}, back {back}, level {w.rec(k, 0x4B)}, {hexs(sk)}, lines {lines_str(lines)}')


def s_vanilla(w):
    print('vanilla: the original combination FireSlash (ChargeUP + Blazemore, level 11)')
    m = w.m
    k = m[PARTY_LIST + 2]
    w.setup(k, 10, [CHARGEUP, BLAZEMORE], edge=True)
    w.stats(k)
    w.queues.append(w.queue(k))
    r, back, lines = w.fight_dummy()
    sk = w.skills(k)
    w.learned.append(sk)
    fs = [x for x in lines if x[2] == FIRESLASH]
    w.check('ChargeUP + Blazemore at level 10 -> 11: FireSlash "recalls" ($0B0F, C = $FF) beside '
            'both — the original code 2 unchanged',
            r == 'battle' and back and FIRESLASH in sk and CHARGEUP in sk and BLAZEMORE in sk
            and len(fs) == 1 and fs[0][0] == LINE_RECALLS and fs[0][1] == 0xFF,
            f'{r}, back {back}, level {w.rec(k, 0x4B)}, {hexs(sk)}, lines {lines_str(lines)}')


def s_universal(w):
    print('universal: Mourn / Tremor (no prerequisite, zero stats) never learned off the queue')
    runs = [(sk, q) for sk, q in zip(w.learned, w.queues)]
    off_queue = [(sk, q) for sk, q in runs if MOURN not in q and TREMOR not in q]
    hit = [hexs(sk) for sk, _q in off_queue if MOURN in sk or TREMOR in sk]
    w.check(f'in the {len(off_queue)} level ups above whose learn queue holds neither, Mourn ($E9, '
            'level 3) and Tremor ($E5, level 2) were never learned — the scanner skips a row with '
            'no prerequisite before code 2', len(off_queue) >= 3 and not hit,
            f'{len(runs)} runs, {len(off_queue)} off the queue, learned {hit}')


def negative_rom(w):
    rom = bytearray(open(w.rom, 'rb').read())
    o = rom_off(w.sym, 'LearnFence06')
    rom[o:o + len(S160_FENCE)] = S160_FENCE
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print('NEGATIVE CONTROL: LearnFence06 put back to its S160 bytes (code 2 fenced for $DA+ and '
          'the 14 reclaimed ids)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--steps', default='combo,one,full,vanilla,universal')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = ComboWalk(a.build, a.sav, a.keep)
    d = json.load(open(a.project))
    ids = {r['id']: int(r['mapID'], 16) for r in d['custom']['rooms']}
    w.rooms = {'hall': ids['conflux_hall']}
    from editor2.core.project import Project
    from simulator import raising as RS
    prj = Project(d, os.path.dirname(os.path.abspath(a.project)))
    prj.repo_root = REPO
    w.T = RS.Tables.from_gamedata(prj.gamedata(), prj)
    sk = d['gamedata']['skills']
    names = {v['name']: int(k) for k, v in sk.items() if isinstance(v, dict) and v.get('name')}
    w.FUSION = names['Fusion']
    w.learned, w.queues = [], []
    if a.negative:
        negative_rom(w)
    s_continue(w)
    w.save('start')
    steps = {'combo': s_combo, 'one': s_one, 'full': s_full, 'vanilla': s_vanilla,
             'universal': s_universal}
    for name in [x for x in a.steps.split(',') if x]:
        try:
            if name != 'universal':
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
