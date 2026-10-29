#!/usr/bin/env python3
"""walk_earth.py — S159 (ROADMAP E16): EARTH, the 27th resistance, on the real game (PyBoy
on the user's .sav).

Resistance 26 ("Unused" until S159) = EARTH: species info +$29 -> the monster record +$82
bits 0-1 (the memorial's tag in bits 3-7) -> the battle's packed resistances, POSITION 27
(patched bank $51 SaveBtlS_4404; the original game put it in position 0) -> every skill
whose element (gamedata.skills.<id>.element) is Earth (bank $72 ElemLevelOfA: resistance t
at position t + 1) and the AI's element 27 (record +5).

The demo (examples/s159_earth_demo/build_demo.py) = the user's project + THE FAULT HALL:
Quake (230) and Boom (7) moved to Earth, a NEW skill Rockfall (Bang's effect, Earth), the
species Golem Earth 3 / MudDoll Earth 1 / StoneMan Earth 2 (the GIFT MASON's TREMORER) /
MadGopher 0, the SEISMIC SAGE (INT 200, Boom + Rockfall) and the BLAST IMP (Bang) on screen 2.

  gift     the GIFT MASON (YES) gives TREMORER: its record +$82 = 2 (StoneMan's Earth) and
           its skills Quake / Rockfall / Boom / Blaze;
  pack     a battle (the forced-battle rig: the queue written each frame, RNG pinned) with
           party records +$82 poked to tag | Earth (8 | 3, 1, 16 | 2) and an enemy row of
           each demo species: every combatant's 7 packed bytes ($DD28 + 7k) ==
           simulator/pacing.pack_res of its 27 levels (party: record +$68..+$82, the tag
           dropped; enemy: its species row), position 27 = the Earth level, position 0 = 0
           (what element 0 reads in the original game);
  damage   forced casts by party slot 0 at the foe (RNG pinned, the foe's Earth level
           poked 0-3 in its packed byte): Quake (a built-in: CustomElemTail52), Rockfall
           (a new skill on Bang), Boom (a stock skill moved to Earth) take ×1 / ×0.85 /
           ×0.5 / 0 — the ROM's damage == simulator damage.LADDER_A of the level-0 roll;
           Bang (still Explosion) and Blaze (Fire) ignore the Earth level; Boom ignores
           Explosion now (Explosion 3 poked, Earth 0: full damage);
  ai       the SEISMIC SAGE (INT 200; Boom + Rockfall, AI element 27): with the party's Earth
           0 it casts Boom; with every party monster at Earth 3 (records +$82 poked) it casts
           no Earth skill (bank $57 AIRule_4c13's all-immune veto reads position 27); with
           Explosion 3 it still casts Boom; the control: the BLAST IMP (Bang, Explosion)
           casts Bang at Explosion 0, never at Explosion 3 (the game's own veto). Counted at
           bank $72 FarSkillFork (every acting skill). [Found S159: an enemy with ONLY a new
           skill on Bang never casts it — the S158 build too; ROADMAP E16 note.]
  memorial (needs the S154 MEMORIAL HALL in the same project: --memorial) the party's
           records +$82 = tag | Earth: the CHAMPION won -> the Earth bits kept beside the
           tag, the list's tags = the record & $F8, the hall shows no monster (all still
           here) — bank $79 MemUpsert / MemRecMatch / MemRecTag mask the tag with $F8.

  python3 tools/walk_earth.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative | --negative-memorial] [--memorial] [--steps …]

--negative: bank $51 SaveBtlS_4404 back to the original game's bytes in the ROM copy
(Earth into position 0): the pack / damage / ai Earth checks must FAIL.
--negative-memorial: bank $79's `and $F8` tag masks made `and $FF` in the ROM copy: a
monster with Earth bits is "not ours" — the memorial checks must FAIL.
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import io
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import GAME_MODE                                 # noqa: E402
from tools.walk_regions import s_continue                                 # noqa: E402
from tools.walk_skills import SkillWalk, r16, w16, HP, MAXHP, MP, CURSE_ATTACK  # noqa: E402
from simulator import damage as D                                         # noqa: E402
from simulator import pacing as P                                         # noqa: E402

DCEC = 0xDCEC
REC, RECSZ = 0xCAC1, 149
QUAKE, BOOM, BANG, BLAZE = 230, 7, 6, 0
GOLEM, MUDDOLL, STONEMAN, GOPHER = 196, 195, 197, 60
EARTH, EXPLOSION, FIRE = 26, 2, 0
PACKER_LEN = 78                           # $51:$4404-$4451 (the same size in both)


def orig_packer():
    """The original game's SaveBtlS_4404 bytes (data/DWM-original.gbc)."""
    rom = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    o = 0x51 * 0x4000 + 0x0404
    return rom[o:o + PACKER_LEN]


def set_level(m, slot, t, lv):
    """Poke resistance t's level of battle slot `slot` in the packed bytes (position t+1)."""
    pos = t + 1
    a = 0xDD28 + 7 * slot + (pos >> 2)
    sh = (3 - (pos & 3)) * 2
    m[a] = (m[a] & ~(3 << sh) & 0xFF) | (lv << sh)


class EarthWalk(SkillWalk):
    def rec(self, k, off):
        return self.m[REC + RECSZ * k + off]

    def set_rec(self, k, off, v):
        self.m[REC + RECSZ * k + off] = v

    def fight(self, caster, skill, target, eid, frames=2600, board=None, at_start=None,
              others=CURSE_ATTACK, ehp=999, pin=True):
        """The S110 forced-battle rig (walk_skills.SkillWalk.rig) against enemy row `eid`:
        a wild battle, every actor's skill written each frame, the RNG pinned. at_start(m)
        runs at the first battle frame (the packer has run by then); board(m) in the
        command phases 4-6. -> {'msgs': [(msg, skill, subject, $DB56)], 'start': bool}."""
        p, m = self.p, self.m
        log = {'msgs': [], 'start': False}

        def on_msg(_):
            log['msgs'].append((m[0xC823], m[0xDB8A], m[0xDB89], r16(m, 0xDB56)))
        p.hook_register(0x4C, 0x42D1, on_msg, None)
        m[0xDA03], m[0xDA04] = eid & 0xFF, eid >> 8
        m[0xDA02] = 0
        m[0xDA09] = 1
        m[0xC905] = 0
        m[0xC8EB] |= 0x40
        for i in range(frames):
            if m[GAME_MODE] == 2:
                ph = m[0xD9EC]
                if not log['start'] and ph >= 1:
                    log['start'] = True
                    if at_start:
                        at_start(m)
                if pin:
                    m[0xC899], m[0xC89A] = 0x5A, 0xA5
                for k in range(3):
                    m[DCEC + 2 * k] = skill if k == caster else others
                m[DCEC + 8] = others
                if 4 <= ph <= 6:
                    for k in range(3):
                        m[DCEC + 2 * k + 1] = target if k == caster else k
                    m[DCEC + 9] = 4
                    if ehp is not None:
                        w16(m, HP + 8, ehp)
                        w16(m, MAXHP + 8, 999)
                    w16(m, MP + 2 * caster, 200)
                    for k in range(3):
                        if m[0xDD1B + k] != 0xFF:
                            w16(m, HP + 2 * k, 900)
                            w16(m, MAXHP + 2 * k, 999)
                    if board:
                        board(m)
            if i % 8 < 4:
                p.button_press('a')
            else:
                p.button_release('a')
            p.tick()
        p.button_release('a')
        p.hook_deregister(0x4C, 0x42D1)
        return log


def first_hit(log, skill, target=4):
    """$DB56 of the first message of `skill` on `target` that carries a number (the
    damage line), or None."""
    for msg, sk, subj, n in log['msgs']:
        if sk == skill and (subj & 7) == target and msg not in (0x5D, 0x23, 0xFD):
            return msg, n
    return None


# ------------------------------------------------------------------ steps
def s_gift(w):
    print('gift: the GIFT MASON')
    mid = w.rooms['hall']
    w.goto(mid, 0, 5, 6)
    before = [(k, w.rec_byte(k, 0), w.rec_byte(k, 9)) for k in range(20)]
    w.face('up')
    r = w.talk([True])
    w.idle()
    new = [k for k in range(20) if w.rec_byte(k, 0) in (1, 2)
           and (k, w.rec_byte(k, 0), w.rec_byte(k, 9)) not in before]
    got = [(k, w.rec_byte(k, 9), w.rec_byte(k, 0x82), [w.rec_byte(k, 0x29 + i) for i in range(4)])
           for k in new]
    w.check('the GIFT MASON (YES) gives TREMORER (a StoneMan) with Quake / Rockfall / Boom / Blaze',
            any(sp == STONEMAN and sk == [QUAKE, w.rockfall, BOOM, BLAZE] for _k, sp, _e, sk in got),
            f'{r}; new {got}')
    w.check("TREMORER's record +$82 = 2: its species' Earth level, copied at creation",
            any(sp == STONEMAN and e == 2 for _k, sp, e, _s in got), str(got))
    w.snap('gift')


def s_pack(w):
    print('pack: the packed resistances at the battle start')
    m = w.m
    poke = {0: 8 | 3, 1: 1, 2: 16 | 2}
    for k, v in poke.items():
        w.set_rec(k, 0x82, v)
    levels = {k: [w.rec(k, 0x68 + i) for i in range(27)] for k in range(3)}
    for eid, sp, lv in ((w.eids['stone_golem'], GOLEM, 3), (w.eids['mud_doll'], MUDDOLL, 1),
                        (w.eids['gopher'], GOPHER, 0)):
        st = io.BytesIO()
        w.p.save_state(st)
        seen = {}

        def at_start(mm):
            for s in (0, 1, 2, 4):
                seen[s] = [mm[0xDD28 + 7 * s + i] for i in range(7)]
        w.fight(0, BLAZE, 4, eid, frames=900, at_start=at_start)
        w.check(f'EID {eid}: the battle started', bool(seen), '')
        if not seen:
            continue
        for k in range(3):
            exp = P.pack_res(levels[k])
            w.check(f'EID {eid}: party slot {k} (+$82 = {poke[k]}) packed == pack_res (Earth '
                    f'{poke[k] & 3} at position 27, the tag dropped)', seen[k] == exp,
                    f'{[hex(x) for x in seen[k]]} vs {[hex(x) for x in exp]}')
            w.check(f'EID {eid}: party slot {k} position 0 = 0 (element 0 as in the original)',
                    (seen[k][0] & 0xC0) == 0, hex(seen[k][0]))
        row = w.species_rows[sp]
        exp = P.pack_res(list(row[15:42]))
        w.check(f'EID {eid} (species {sp}, Earth {lv}): packed == pack_res of its species row',
                seen[4] == exp and (seen[4][6] & 3) == lv,
                f'{[hex(x) for x in seen[4]]} vs {[hex(x) for x in exp]}')
        st.seek(0)
        w.p.load_state(st)


def s_damage(w):
    print('damage: Earth skills through the spell ladder (RNG pinned)')
    eid = w.eids['gopher']
    st = io.BytesIO()
    w.p.save_state(st)

    def cast(sk, levels):
        st.seek(0)
        w.p.load_state(st)

        def board(m):
            for t, lv in levels.items():
                set_level(m, 4, t, lv)
            m[0xDB05 + 8 * 4] &= 0x3F               # no guard / amplify marks on the foe
        lg = w.fight(0, sk, 4, eid, frames=2600, board=board)
        return first_hit(lg, sk)

    for sk, name in ((QUAKE, 'Quake (built-in)'), (w.rockfall, 'Rockfall (new skill, Bang)'),
                     (BOOM, 'Boom (stock, moved to Earth)')):
        hits = [cast(sk, {EARTH: lv}) for lv in range(4)]
        d0 = hits[0][1] if hits[0] else None
        exp = [D.LADDER_A[0][lv](d0) for lv in range(4)] if d0 is not None else None
        got = [h[1] if h else None for h in hits]
        if 3 in range(4) and hits[3] is None:      # immune: the line may carry no number
            got[3] = 0
        w.check(f'{name}: Earth 0 / 1 / 2 / 3 -> ×1 / ×0.85 / ×0.5 / 0 (simulator ladder)',
                d0 and got == exp, f'{got} vs {exp}; {hits}')
    # controls: the Earth level does not touch Bang / Blaze; Boom no longer tests Explosion
    for sk, name in ((BANG, 'Bang (Explosion)'), (BLAZE, 'Blaze (Fire)')):
        a, b = cast(sk, {EARTH: 0}), cast(sk, {EARTH: 3})
        w.check(f'{name}: the same damage at Earth 0 and Earth 3', a and b and a[1] == b[1],
                f'{a} {b}')
    a, b = cast(BOOM, {EARTH: 0, EXPLOSION: 0}), cast(BOOM, {EARTH: 0, EXPLOSION: 3})
    w.check('Boom (moved to Earth): Explosion 3 no longer stops it', a and b and a[1] == b[1]
            and a[1] > 0, f'{a} {b}')
    a, b = cast(BANG, {EXPLOSION: 0}), cast(BANG, {EXPLOSION: 3})
    w.check('Bang (still Explosion): Explosion 3 = immune', a and a[1] > 0 and (b is None or b[1] == 0),
            f'{a} {b}')


def ai_battle(w, x, y, res, lv, frames=12000):
    """A sparring boss of screen 2 (x, y), talked to from below; every party monster's
    resistance `res` poked to `lv` (Earth: record +$82 bits 0-1, the tag kept; else
    +$68 + res); the party only defends ($8D), HP held. -> ('battle', {skill: casts by an
    enemy}) — counted at bank $72 FarSkillFork (every acting skill passes there)."""
    m, p = w.m, w.p
    w.goto(w.rooms['hall'], 0, 20 + x, y + 1)
    for k in range(3):
        if w.rec(k, 0):
            if res == EARTH:
                w.set_rec(k, 0x82, (w.rec(k, 0x82) & 0xF8) | lv)
            else:
                w.set_rec(k, 0x68 + res, lv)
    w.face('up')
    r = w.talk([True])
    if r != 'battle':
        return r, {}
    casts = {}

    def fk(_c):
        if m[0xDB88] >= 4:
            casts[m[0xDB8A]] = casts.get(m[0xDB8A], 0) + 1
    b, a = w.sym['FarSkillFork']
    p.hook_register(b, a, fk, None)
    for i in range(frames):
        if m[GAME_MODE] == 2 and 4 <= m[0xD9EC] <= 6:
            for k in range(3):
                if m[0xDD1B + k] == 0:
                    w16(m, HP + 2 * k, 400)
                    w16(m, MAXHP + 2 * k, 999)
                m[DCEC + 2 * k] = 0x8D                  # the party only defends
            if r16(m, HP + 8) < 150:
                w16(m, HP + 8, 300)
        if i % 8 < 4:
            p.button_press('a')
        else:
            p.button_release('a')
        p.tick()
    p.button_release('a')
    p.hook_deregister(b, a)
    return 'battle', casts


def s_ai(w):
    print('ai: the enemy AI reads Earth (INT 200 bosses, the party defending)')
    st = io.BytesIO()
    w.p.save_state(st)

    def run(*a):
        st.seek(0)
        w.p.load_state(st)
        return ai_battle(w, *a)
    r, c0 = run(3, 2, EARTH, 0)
    w.check('the SEISMIC SAGE (Boom, Rockfall) battle starts', r == 'battle', r)
    w.check('party Earth 0: the SAGE casts Boom (an Earth skill)', c0.get(BOOM, 0) > 0, str(c0))
    r, c3 = run(3, 2, EARTH, 3)
    w.check('party Earth 3 (every monster): the SAGE casts no Earth skill — the all-immune '
            'veto (bank $57 AIRule_4c13) reads Earth at position 27',
            r == 'battle' and not c3.get(BOOM) and not c3.get(w.rockfall), str(c3))
    r, cx = run(3, 2, EXPLOSION, 3)
    w.check('party Explosion 3: the SAGE still casts Boom (Boom tests Earth now)',
            cx.get(BOOM, 0) > 0, str(cx))
    r, i0 = run(6, 5, EXPLOSION, 0)
    w.check('control — the BLAST IMP (Bang, the game\'s Explosion): party Explosion 0 -> Bang',
            i0.get(BANG, 0) > 0, str(i0))
    r, i3 = run(6, 5, EXPLOSION, 3)
    w.check('control — party Explosion 3: the BLAST IMP never casts Bang (the same veto, '
            'the game\'s own element)', r == 'battle' and not i3.get(BANG), str(i3))


def s_memorial(w):
    print('memorial: the tag and the Earth level share record +$82')
    from tools import walk_memorial as WM
    mw = WM.MemWalk.__new__(WM.MemWalk)
    mw.__dict__.update(w.__dict__)
    WM.MemWalk.__init__  # noqa: B018 — the hall's statue data:
    from editor2.core.project import Project
    from editor2.core import memorial as MM
    prj = Project(json.load(open(w.project)), os.path.dirname(os.path.abspath(w.project)))
    prj.repo_root = REPO
    mw.MM = MM
    mw.pics = MM.pictures(prj)
    mw.rooms = {(WM.F_region(r), WM.F_map(r)): [MM.statue_tiles(s) for s in MM.room_statues(r)]
                for r in prj.rooms if MM.room_statues(r)}
    mw.shade = {(WM.F_region(r), WM.F_map(r)): [MM.statue_shade(s, r, prj) for s in MM.room_statues(r)]
                for r in prj.rooms if MM.room_statues(r)} if hasattr(MM, 'statue_shade') else {}
    mw.placeholder = {}
    f0, c0 = mw.fails, mw.checks
    mw.goto(WM.HALL, 0, 5, 5)
    party = mw.party()
    before = {s: mw.rec(s, 0x82) for s in party}
    earth = {s: (k % 3) + 1 for k, s in enumerate(party)}
    for s in party:
        mw.m[REC + RECSZ * s + 0x82] = (before[s] & 0xF8) | earth[s]
    ok = mw.champion()
    mw.check('the CHAMPION fought and won', ok)
    after = {s: mw.rec(s, 0x82) for s in party}
    w.check('every fighter keeps its Earth level in bits 0-1 beside a tag in bits 3-7',
            all((after[s] & 7) == earth[s] and (after[s] & 0xF8) for s in party),
            f'before {before} earth {earth} after {after}')
    lst = mw.memlist()
    tags = {(e[0], e[1]) for e in lst}
    w.check("the list's entries carry the records' tags (record & $F8), not the Earth bits",
            all(((after[s] & 0xF8), mw.rec(s, 9)) in tags for s in party), f'{lst} vs {after}')
    mw.goto(WM.CITY, 0, 4, 5)
    mw.goto(WM.HALL, 0, 5, 5)
    lst = mw.memlist()
    mine = {i for i, e in enumerate(lst) for s in party
            if (e[0], e[1]) == (after[s] & 0xF8, mw.rec(s, 9))}
    picks = mw.picks()
    w.check('back in the hall: no statue picks a fighter (MemRecTag / MemRecMatch see them, '
            'Earth bits and all, still with the player)', mine and not (set(picks) & mine),
            f'picks {picks}, the fighters\' entries {sorted(mine)}')
    w.fails += mw.fails - f0                    # mw counted its own checks
    w.checks += mw.checks - c0


def negative_rom(w):
    b, a = w.sym['SaveBtlS_4404']
    rom = bytearray(open(w.rom, 'rb').read())
    o = b * 0x4000 + a - 0x4000
    rom[o:o + PACKER_LEN] = orig_packer()
    open(w.rom, 'wb').write(rom)
    print('NEGATIVE CONTROL: bank $51 SaveBtlS_4404 = the original game (Earth -> position 0)')


def negative_memorial_rom(w):
    rom = bytearray(open(w.rom, 'rb').read())
    n = 0
    for lab in ('MemUpsert', 'MemRecMatch', 'MemRecTag'):
        b, a = w.sym[lab]
        o = b * 0x4000 + a - 0x4000
        k = rom.find(bytes([0xE6, 0xF8]), o, o + 0x40)
        if k >= 0:
            rom[k + 1] = 0xFF
            n += 1
    open(w.rom, 'wb').write(rom)
    print(f'NEGATIVE CONTROL: bank $79 tag masks `and $F8` -> `and $FF` ({n} of 3)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--negative-memorial', action='store_true')
    ap.add_argument('--memorial', action='store_true')
    ap.add_argument('--steps', default='gift,pack,damage,ai')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = EarthWalk(a.build, a.sav, a.keep)
    w.project = a.project
    d = json.load(open(a.project))
    ids = {r['id']: int(r['mapID'], 16) for r in d['custom']['rooms']}
    w.rooms = {'hall': ids['fault_hall']}
    from editor2.core.project import Project
    prj = Project(d, os.path.dirname(os.path.abspath(a.project)))
    prj.repo_root = REPO
    w.eids = {e['id']: e['_eid'] for e in prj.quest_enemy_rows()}
    g = prj.gamedata()
    w.species_rows = {sp: bytes(g.monster[sp]) for sp in range(221)}
    sk = d['gamedata']['skills']
    w.rockfall = next(int(k) for k, v in sk.items() if isinstance(v, dict) and v.get('name') == 'Rockfall')
    if a.negative:
        negative_rom(w)
    if a.negative_memorial:
        negative_memorial_rom(w)
    s_continue(w)
    w.save('start')
    steps = {'gift': s_gift, 'pack': s_pack, 'damage': s_damage, 'ai': s_ai,
             'memorial': s_memorial}
    names = [x for x in a.steps.split(',') if x]
    if a.memorial and 'memorial' not in names:
        names.append('memorial')
    for name in names:
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
