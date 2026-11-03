#!/usr/bin/env python3
"""walk_names.py — S164 (ROADMAP E14 "the built-in custom skill names out of bank $41") on the
real game (PyBoy on the user's .sav).

Since S155 / S156 the 17 built-in custom skills' names (+ a project's new skills') overflowed
bank $41's 94-byte gd_custom_skill_names region into the ns_text_* extents the new species'
names use. S164: the names past the region are served from the S150 text banks instead
(editor2/core/custom_skills.text_slots -> gametext -> bank $60 entry 14 TextOverride, keyed by
bank $41 / SkillNamePtrTable / the id); their pointer rows in bank $41 point at the empty
placeholder. Every reader of a skill name goes through ROM0 SaveBankAndSwitch (text mode 6 of
bank $41): this walk hooks it right after its level-2 read ($094F, `pop af`: DE = the text,
[$C824] its bank — or a WRAM buffer for a COPY of an edited text) and records every mode-6
lookup of a custom id, with the bytes the game then reads.

The demo (examples/s164_conflux_demo/build_demo.py): Finish ($EC) evolves from Firebal at 10.
  battle   party slot 0 casts each built-in whose name is in the text banks (Punish, Finish,
           Rupture, Blunt, Plunder) and one whose name stayed in bank $41 (Tame) in the S110
           rig: the announce's lookup of its name reads exactly the name (from a text bank /
           the WRAM copy buffer for the routed ones, bank $41 for Tame), and the name the
           announce puts in $C190 is that name;
  menu     the lead monster's first skill := Finish; the field menu -> SKIL -> the monster:
           the skill list's lookup of Finish's name reads "Finish";
  learn    party slot 2 = Firebal at level 9: beat the TRAINING DUMMY -> the level up's line
           for Finish (learned beside Firebane — two children of one skill, S161) looks the name
           up and reads "Finish".

  python3 tools/walk_names.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative]

--negative: the S150 lookup off in the ROM copy (TextLevel1Hook's `rst $10` -> `nop`): the
routed names read the empty placeholder — every routed check must FAIL, Tame's passes.
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, PARTY_LIST                          # noqa: E402
from tools.walk_regions import s_continue                                    # noqa: E402
from tools.walk_reclaim import ReclaimWalk                                   # noqa: E402
from tools.walk_combo import ComboWalk                                       # noqa: E402
from tools.walk_skills import CURSE_ATTACK                                   # noqa: E402
from editor2.core import custom_skills as CS                                 # noqa: E402

AFTER_L2 = 0x094F            # SaveBankAndSwitch's `pop af` after the level-2 read (DE = text)
TAME, PUNISH, FINISH, RUPTURE, BLUNT, PLUNDER, FIREBAL = 0xE1, 0xEB, 0xEC, 0xED, 0xEE, 0xEA, 3
REC, RECSZ = 0xCAC1, 149


class NamesWalk(ComboWalk, ReclaimWalk):
    def start(self, state=None):
        super().start(state)
        self.looks = []
        self.p.hook_register(0, AFTER_L2, self._lookup, None)

    def _lookup(self, _ctx):
        m, rf = self.m, self.p.register_file
        if m[0x4000] != 0x41 or m[0xC822] != 6 or m[0xC823] < 0xDE:
            return
        de, bank = rf.D << 8 | rf.E, m[0xC824]
        raw = bytearray()
        for i in range(12):
            a = de + i
            v = self.p.memory[bank, a] if 0x4000 <= a < 0x8000 else m[a]
            raw.append(v)
            if v == 0xF0:
                break
        self.looks.append((m[0xC823], bank, de, bytes(raw)))

    def name_checks(self, what, sid, since=0):
        want = self.names[sid]
        hits = [x for x in self.looks[since:] if x[0] == sid]
        routed = sid in self.routed
        ok = bool(hits) and all(x[3] == want for x in hits) and all(
            ((x[1] >= 0x80 and 0x4000 <= x[2] < 0x8000) or x[2] >= 0xC000) == routed for x in hits)
        where = ', '.join(f'${b:02X}:${a:04X} {r.hex()}' for _s, b, a, r in hits[:3]) or 'no lookup'
        self.check(f'{what}: the lookup of ${sid:02X}\'s name reads "{self.decode(want)}" '
                   f'({"a text bank / the copy buffer" if routed else "bank $41"})', ok, where)
        return ok

    def decode(self, raw):
        from editor2.core import monster_text as MT
        return MT.decode(raw[:-1])


def s_battle(w):
    print('battle: party slot 0 casts the built-ins (routed names) and Tame (bank $41)')
    for sid in (PUNISH, FINISH, RUPTURE, BLUNT, PLUNDER, TAME):
        w.start('start')
        seen = []

        def at_msg(_log, sid=sid):
            if w.m[0xDB8A] == sid and w.m[0xDB88] == 0:
                seen.append(bytes(w.m[0xC190 + i] for i in range(10)))
        log = w.battle(3, 1400, party=CURSE_ATTACK, caster=0, skill=sid, target=4,
                       hooks={(0x4C, 0x735E): at_msg})       # the jp target of $42D1
        w.name_checks(f'{w.decode(w.names[sid])} cast in battle', sid)
        want = w.names[sid]
        w.check(f'… the announce\'s $C190 = "{w.decode(want)}"',
                any(x[:len(want)] == want for x in seen),
                ' / '.join(x.hex() for x in seen[:2]) or f'no message ({len(log["msgs"])})')


def s_menu(w):
    print('menu: the field SKIL list with Finish')
    w.start('start')
    m, p = w.m, w.p
    rec = REC + RECSZ * m[0xCA8E]
    m[rec + 0x29] = FINISH
    n0 = len(w.looks)
    tap(p, 'a', hold=3, wait=90)                  # the field menu
    tap(p, 'down', hold=8, wait=40)               # SKIL
    tap(p, 'a', hold=3, wait=60)
    tap(p, 'a', hold=3, wait=90)                  # the lead monster -> its skill list
    w.snap('menu_skil')
    w.name_checks('the field SKIL list', FINISH, n0)
    for _ in range(5):
        tap(p, 'b', wait=30)
    w.idle()


def s_learn(w):
    print('learn: Firebal at level 9 -> Finish (from Firebal) in the level up\'s lines')
    w.start('start')
    m = w.m
    k = m[PARTY_LIST + 2]
    w.setup(k, 9, [FIREBAL], edge=True)
    n0 = len(w.looks)
    r, back, lines = w.fight_dummy()
    sk = w.skills(k)
    w.check('the battle ends and Finish is learned', r == 'battle' and back and FINISH in sk,
            f'{r}, back {back}, {[hex(s) for s in sk]}, lines {lines}')
    w.name_checks('the level up\'s line', FINISH, n0)


def negative_rom(w):
    b, a = w.sym['TextLevel1Hook']
    rom = bytearray(open(w.rom, 'rb').read())
    assert rom[a + 6] == 0xD7, rom[a:a + 8].hex()
    rom[a + 6] = 0x00
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print('NEGATIVE CONTROL: ROM0 TextLevel1Hook without its far call (no edited text found)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--steps', default='battle,menu,learn')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = NamesWalk(a.build, a.sav, a.keep)
    d = json.load(open(a.project))
    ids = {r['id']: int(r['mapID'], 16) for r in d['custom']['rooms']}
    w.rooms = {'hall': ids['conflux_hall']}
    from editor2.core.project import Project
    from simulator import raising as RS
    prj = Project(d, os.path.dirname(os.path.abspath(a.project)))
    prj.repo_root = REPO
    w.T = RS.Tables.from_gamedata(prj.gamedata(), prj)
    lay = CS.layout(prj, REPO)
    w.names = {s: v['name'] + b'\xf0' for s, v in lay['skills'].items() if s >= CS.FIRST}
    w.routed = {sid for _b, _t, sid, _r, _w in CS.text_slots(prj, REPO)}
    print('names in the text banks:', ', '.join(w.decode(w.names[s]) for s in sorted(w.routed)))
    if a.negative:
        negative_rom(w)
    s_continue(w)
    w.save('start')
    steps = {'battle': s_battle, 'menu': s_menu, 'learn': s_learn}
    for name in [x for x in a.steps.split(',') if x]:
        try:
            steps[name](w)
        except Exception as e:                       # noqa: BLE001 — a step that crashes fails
            import traceback
            traceback.print_exc()
            w.check(f'{name} ran', False, repr(e))
    print(f'WALK: {"PASS" if not w.fails else "FAIL " + str(w.fails)} ({w.checks} checks)')
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
