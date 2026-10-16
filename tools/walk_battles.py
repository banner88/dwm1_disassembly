#!/usr/bin/env python3
"""walk_battles.py — S149 (ROADMAP ARC CAP5, battles at campaign scale): the project's
own enemy rows and battle lists past the old limits, in the game (PyBoy on the user's
.sav).

The demo (examples/s149_muster_demo/build_demo.py) = the user's project + 1,100 enemy
rows + 600 battle lists + THE MUSTER HALL / THE MUSTER FIELD. A monster that joins
after a battle is built by bank $14 entry 3 (`CreateJoinedMonster`, the JOIN constructor —
bank $51 calls it into staging slot $14) which runs entry 2's body: the gender read
(S149 `EnemyGenderCode`) and the foreign-name jump (S149 `ForeignNamesGate`).

  guide   CONTINUE; the MUSTER GUIDE in Cities_FOUNT (YES) -> the hall;
  joins   (each from the same saved state, a party of one) the DRACKY (row 43, EID 561,
          always male; S148: a rival tamer's master name), the HEALER (row 88, EID 606,
          rolled; S148: an egg), the PIXY (row 900, EID 1418 — a battle bank; always
          female): YES -> the battle fights THAT row (the battle's EID), won; it joins —
          the creation ran the S149 gender hook with that EID; the new party member is
          that species, its master is the player, it is no egg, its gender = the row's
          setting (rolled: == the game's own roll from the RNG state the hook saw); it
          joins healthy (HP = max HP > 0, MP = max MP — S149 r2);
  farm    the FARM KEEPER: the farm screen opens (op $04 type 3) and the hall comes back;
  field   the STAIRS (a real door) -> THE MUSTER FIELD; the FIELD GUIDE's words; walking
          until a wild battle: the list in use (wEncListBuf) == project list 700 (a
          battle bank), the enemy == the GOLEM row 1,000 (EID 1518, a battle bank), won;
          the stairs back up; the EXIT GUIDE (YES) -> Cities_FOUNT.

  python3 tools/walk_battles.py --build DEMO/build/build --project DEMO/project.json \
      --sav USER.sav --keep KEEP [--negative]

--negative: the S148 creation in the ROM copy (EnemyGenderCode's and ForeignNamesGate's
`cp $02` -> `cp $FF`): the gender / master / egg checks must FAIL.
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, GAME_MODE, TEXTBOX, SCRIPT_FLAGS, PARTY_LIST  # noqa: E402
from tools.walk_regions import Walk, s_continue, CHOICE                                   # noqa: E402
from simulator import raising as R                                                       # noqa: E402

RNG1, RNG2 = 0xC899, 0xC89A
EID_LO = 0xDA12
ENEMY1 = 0xDA03                    # the battle's enemy 1 EID (16-bit)
SERVICE_TYPE = 0xC8EF
PLAYER_NAME = 0xCA42
REC, SLOT0 = 149, 0xCAC1
ROWS = {'dracky': (43, 78, 'male'), 'healer': (88, 9, 'rolled'), 'pixy': (900, 130, 'female')}


def party_records(m):
    out = []
    for k in range(3):
        s = m[PARTY_LIST + k]
        if s != 0xFF:
            b = SLOT0 + REC * s
            out.append(bytes(m[b + i] for i in range(REC)))
    return out


def fight(w, enemy_hp_one=True, no_join=False, maxf=30000):
    """The battle to the end: enemy HP 1, A every 50 frames (joins + the naming screen
    advance by A; START + A on the naming screen). -> (fought, battle EIDs)."""
    m, p = w.m, w.p
    fought, eids = False, None
    for f in range(0, maxf, 10):
        adv(p, 10)
        if m[GAME_MODE] == 2:
            if not fought:
                fought = True
            if eids is None and m[ENEMY1] | m[ENEMY1 + 1]:
                eids = [m[ENEMY1 + 2 * k] | m[ENEMY1 + 2 * k + 1] << 8 for k in range(3)]
            if no_join:
                m[0xDB85] = 7
            if enemy_hp_one:
                for a in (0xDBAB, 0xDBAD, 0xDBAF):
                    if m[a] | m[a + 1] << 8:
                        m[a], m[a + 1] = 1, 0
        if m[SERVICE_TYPE] == 15 and f % 200 == 0:          # the naming screen
            tap(p, 'start', hold=3, wait=10)
        if f % 50 == 0:
            tap(p, 'a', hold=3, wait=2)
        if fought and m[GAME_MODE] == 1 and not m[TEXTBOX] & 1 and not m[SCRIPT_FLAGS] & 1 \
                and f > 2000:
            w.idle()
            for _ in range(12):            # an A may have opened the field menu (S115)
                if m[0xC8EB] == 0:
                    break
                tap(p, 'b', hold=3, wait=20)
            w.idle()
            return True, eids
    return fought, eids


def arena_match(w, lobby, battle):
    """The desk (lobby screen 1, (14, 7) -> up 3, left, A — PYBOY_DEBUGGING S143): classes
    won := 0 and gold for the fee, class G, YES (A only), its three matches won (enemy HP
    1, no join), until the lobby is back. -> (rooms seen, matches fought)."""
    m, p = w.m, w.p
    m[0xCAB4] = 0
    m[0xCA4B], m[0xCA4C], m[0xCA4D] = 0x10, 0x27, 0
    for d_ in ('up', 'up', 'up', 'left'):
        w.step(d_)
    adv(p, 10)
    tap(p, 'a', hold=3, wait=6)
    seen, fights, in_battle = [], 0, False
    for f in range(0, 30000, 10):
        adv(p, 10)
        if m[GAME_MODE] == 2:
            if not in_battle:
                fights += 1
                in_battle = True
            m[0xDB85] = 7
            for aa in (0xDBAB, 0xDBAD, 0xDBAF):
                if m[aa] | m[aa + 1] << 8:
                    m[aa], m[aa + 1] = 1, 0
        else:
            in_battle = False
        here = w.where()
        if not seen or seen[-1] != here:
            seen.append(here)
        if fights >= 3 and here[0] == lobby and m[GAME_MODE] == 1:
            break
        if f % 40 == 0:
            tap(p, 'a', hold=3, wait=2)
    w.idle()
    for _ in range(12):
        if m[0xC8EB] == 0:
            break
        tap(p, 'b', hold=3, wait=20)
    w.idle()
    return seen, fights


def far(w, rooms, a):
    """THE FAR WING (region 1): the S141 acceptance not walked then."""
    m = w.m
    land, grove, den, rest = (rooms[n] for n in ('FAR LANDING', 'FAR GROVE', 'FAR DEN', 'FAR REST'))
    lobby, battle = rooms['Arena Lobby'], rooms['Arena Battle']
    field = rooms['MUSTER FIELD']
    print('far: the FAR GUIDE in THE MUSTER FIELD -> FAR LANDING (region 1)')
    w.start('hall')
    m = w.m
    w.goto(field, 0, 7, 3)
    w.face('up')
    adv(w.p, 20)
    res = w.talk(answers=[True])
    w.idle()
    w.check_at('the FAR GUIDE (YES) -> FAR LANDING', land & 0xFF, land >> 8)
    swirls = [bool(m[0xD7D2 + 32 * n] & 0x40) for n in range(8) if m[0xD7D2 + 32 * n + 1] == 0x4D]
    w.check('FAR LANDING: both portal swirls are shown (Iron Rule 7: the portals look '
            'like portals)', swirls == [False, False], f'hidden bits {swirls}')
    w.save('far')
    w.snap('far_landing')

    print('far arena: from region 1 into the arena, a match, the lobby door out')
    w.goto(land & 0xFF, land >> 8, 2, 6)
    w.face('up')
    adv(w.p, 20)
    res = w.talk(answers=[True])
    w.idle()
    w.check_at('the arena guide (YES) -> the ARENA LOBBY (a global place: region 1 kept)',
               lobby, 1)
    seen, fights = arena_match(w, lobby, battle)
    w.check('class G from region 1: the Arena Battle room, 3 matches won, the lobby back',
            fights == 3 and (battle, 1) in seen and w.where() == (lobby, 1),
            f'{fights} fights, rooms {seen[:8]}, at {w.where()}')
    w.goto(lobby, 1, 14, 7)                         # screen 1 (4, 7) = (14, 7): the door
    w.step('down')                                  # (a bottom-edge exit: walk into it)
    w.idle()
    w.check('the lobby door (screen 1, bottom) -> GreatTree (the game\'s, $01)',
            w.where()[0] == 0x01, f'at {w.where()}')
    print('far arena: from region 0 (the GreatTree door, a vanilla redirect) — a match')
    w.goto(0x01, 0, 4, 12)                          # GreatTree screen 4 (4, 4): below
    w.face('up')                                    # the lobby door (4, 3) = (4, 11) —
    w.step('up')                                    # the project's entrance redirect
    w.idle()
    here = w.where()
    w.check('GreatTree\'s lobby door (a vanilla door redirect) -> the ARENA LOBBY in region 0',
            here == (lobby, 0), f'at {here}')
    seen, fights = arena_match(w, lobby, battle)
    w.check('class G from region 0: 3 matches won, the lobby back',
            fights == 3 and w.where() == (lobby, 0), f'{fights} fights, at {w.where()}')

    print('far world: the left portal -> the FAR WORLD (region 1), its door, a battle')
    w.start('far')
    m = w.m
    w.goto(land & 0xFF, land >> 8, 2, 3)
    w.keep_enc()
    w.step('up')
    w.follow(1500)
    w.idle()
    w.check_at('the left portal -> FAR GROVE (the world\'s start, region 1)', grove & 0xFF,
               grove >> 8)
    w.goto(grove & 0xFF, grove >> 8, 8, 2)
    w.face('up')
    w.step('up')
    w.idle()
    w.check_at('the grove STAIRS (a world door) -> FAR DEN', den & 0xFF, den >> 8)
    got = False
    for k in range(400):
        m[0xCA39], m[0xCA3A] = 0x00, 0x00
        w.step(('right', 'left')[k % 2])
        if m[GAME_MODE] == 2:
            got, eids = fight(w, no_join=True)
            break
    w.check('a wild battle in the FAR DEN (the world), back in the den, region 1',
            got and w.where() == (den & 0xFF, den >> 8), f'at {w.where()}')
    m[0xCA39], m[0xCA3A] = 0xFF, 0x7F
    w.goto(den & 0xFF, den >> 8, 1, 5)
    w.face('down')
    w.step('down')
    w.idle()
    w.check_at('the den STAIRS -> back to FAR GROVE', grove & 0xFF, grove >> 8)
    w.goto(grove & 0xFF, grove >> 8, 4, 4)
    w.face('up')
    adv(w.p, 20)
    w.talk(answers=[True])
    w.idle()
    w.check_at('the grove guide (YES) -> out of the world, FAR LANDING', land & 0xFF, land >> 8)

    print('far dive: the right portal -> the FAR GATE, floor 2 = FAR REST (region 1)')
    w.start('far')
    m = w.m
    w.goto(land & 0xFF, land >> 8, 7, 3)
    w.keep_enc()
    w.step('up')
    w.follow(1500)
    w.idle()
    w.check('the right portal -> the FAR GATE (45) floor 1',
            (m[0xC935], m[0xC939] + 1) == (45, 1), f'gate {m[0xC935]} floor {m[0xC939] + 1}')
    w.kick(2)
    w.check_at('floor 2 = FAR REST (a region-1 room served in a gate)', rest & 0xFF, rest >> 8)
    hits = []
    sb, sa = w.sym.get('SaveGameState', (0, 0x2128))
    w.p.hook_register(sb, sa, lambda _c: hits.append(1), None)
    for _ in range(3):
        tap(w.p, 'b', wait=20)
    tap(w.p, 'a', hold=3, wait=90)                  # the field menu -> JOURNAL (S144)
    tap(w.p, 'down', hold=8, wait=30)
    tap(w.p, 'right', hold=8, wait=30)
    tap(w.p, 'a', hold=3, wait=60)
    for _ in range(3):
        tap(w.p, 'down', hold=8, wait=30)
    tap(w.p, 'a', hold=3, wait=90)
    tap(w.p, 'a', hold=3, wait=200)
    for _ in range(4):
        tap(w.p, 'b', wait=30)
    w.check('JOURNAL in FAR REST: the game saved', bool(hits), f'{len(hits)} call(s)')
    w.p.stop(save=True)
    w.p = None
    sav2 = os.path.join(a.keep, 'far_rest.sav')
    shutil.copy(w.rom + '.ram', sav2)
    os.makedirs(os.path.join(a.keep, 'continue'), exist_ok=True)
    w2 = Walk(a.build, sav2, os.path.join(a.keep, 'continue'))
    s_continue(w2)
    w2.check_at('CONTINUE that save -> FAR REST, region 1', rest & 0xFF, rest >> 8)
    w2.check('... inside the dive again (the FAR GATE, floor 2)',
             (w2.m[0xC935], w2.m[0xC939] + 1) == (45, 2),
             f'gate {w2.m[0xC935]} floor {w2.m[0xC939] + 1}')
    w2.snap('far_rest_continue')
    w.checks += w2.checks
    w.fails += w2.fails
    w2.p.stop(save=False)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--no-far', action='store_true', help='skip THE FAR WING (region 1)')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    d = json.load(open(a.project))
    rooms = {r['name']: int(str(r['mapID']), 16) for r in d['custom']['rooms']}
    hall, field = rooms['MUSTER HALL'], rooms['MUSTER FIELD']
    cities = next(int(str(r['mapID']), 16) for r in d['custom']['rooms']
                  if r['id'] == 'cities_fount')
    from editor2.core.project import Project
    from editor2.core import encounters as EN
    prj = Project.load(os.path.dirname(os.path.abspath(a.project)))
    T = R.project_tables(prj)
    enc = EN.resolve(prj)
    w = Walk(a.build, a.sav, a.keep)
    if a.negative:
        rom = bytearray(open(w.rom, 'rb').read())
        for lab, k in (('EnemyGenderCode', 3), ('ForeignNamesGate', 1)):
            b, ad = w.sym[lab]
            o = b * 0x4000 + ad - 0x4000
            assert rom[o + k - 1:o + k + 1] == bytes([0xFE, 0x02]), lab
            rom[o + k] = 0xFF
        open(w.rom, 'wb').write(rom)
        print('NEGATIVE CONTROL: the S148 creation (EnemyGenderCode / ForeignNamesGate cp $FF)')
    s_continue(w)
    m = w.m

    print('guide: the MUSTER GUIDE in Cities_FOUNT')
    w.goto(cities, 0, 3, 5)
    w.face('up')
    adv(w.p, 20)
    res = w.talk(answers=[True])
    w.idle()
    w.check('the MUSTER GUIDE (YES) -> THE MUSTER HALL', w.where()[0] == hall,
            f'{res}, at ${w.where()[0]:02X}')
    w.snap('hall')
    w.save('hall')

    player = bytes(m[PLAYER_NAME + i] for i in range(9))
    for name, (row, species, gender) in ROWS.items():
        x = {'dracky': 2, 'healer': 5, 'pixy': 8}[name]
        eid = 519 + row - 1
        print(f'join: the {name.upper()} (row {row}, EID {eid}, {gender})')
        w.start('hall')
        m = w.m
        seen = []

        def hook(_c, m=m, seen=seen):
            seen.append((m[EID_LO] | m[EID_LO + 1] << 8, m[RNG1] << 8 | m[RNG2]))
        b, ad = w.sym['EnemyGenderCode']
        w.p.hook_register(b, ad, hook, None)
        n0 = len(party_records(m))
        w.goto(hall, 0, x, 4)
        w.face('up')
        adv(w.p, 20)
        res = w.talk(answers=[True])
        fought, eids = fight(w) if res == 'battle' else (False, None)
        w.check(f'{name}: YES -> a battle with row {row} (EID {eid})',
                fought and eids is not None and eids[0] == eid, f'{res}, battle EIDs {eids}')
        recs = party_records(m)
        w.check(f'{name}: it joined (the party grew by one)', len(recs) == n0 + 1,
                f'{n0} -> {len(recs)}')
        hits = [s for s in seen if s[0] == eid]
        w.check(f'{name}: the creation ran the S149 gender hook with EID {eid}', bool(hits),
                str(seen[:3]))
        if len(recs) != n0 + 1:
            continue
        rec = recs[-1]
        w.check(f'{name}: the new monster is species {species}', rec[9] == species,
                f'species {rec[9]}')
        w.check(f'{name}: its master is the player (no rival tamer\'s name)',
                rec[0x0C:0x15] == player, f'{rec[0x0C:0x15].hex()} vs {player.hex()}')
        w.check(f'{name}: it is no egg', rec[0x63] == 0, f'egg byte {rec[0x63]}')
        # S149 r2 (the user: "they FAINT AFTER JOINING"): HP +$50 / max +$52, MP +$54 /
        # max +$56 — a joined monster comes healthy (r1's demo rows had HP 1: x0.80-1.00
        # rounded down = 0 HP, a fainted monster)
        hp, hpm, mp, mpm = (rec[o] | rec[o + 1] << 8 for o in (0x50, 0x52, 0x54, 0x56))
        w.check(f'{name}: it joins healthy (HP = max HP > 0, MP = max MP)',
                0 < hp == hpm and mp == mpm, f'HP {hp}/{hpm} MP {mp}/{mpm}')
        if gender == 'rolled' and hits:
            info = T.info[species]
            want = 1 if R.GameRNG(hits[0][1]).byte1() < T.gender[info[3] & 3] else 0
        else:
            want = {'male': 0, 'female': 1}.get(gender)
        w.check(f'{name}: its gender is {gender} ({"female" if want else "male"})',
                rec[0x0B] == want, f'gender byte {rec[0x0B]}')
        w.snap(f'join_{name}')

    print('farm: the FARM KEEPER')
    w.start('hall')
    m = w.m
    w.goto(hall, 0, 2, 5)
    w.face('down')
    adv(w.p, 20)
    tap(w.p, 'a', hold=3, wait=6)
    opened = False
    for i in range(400):
        adv(w.p, 10)
        if m[SERVICE_TYPE] == 3 and m[0xC8EB] & 0x10:
            opened = True
            break
        if m[TEXTBOX] & 1 and i % 4 == 3:
            tap(w.p, 'a', hold=2, wait=2)
    adv(w.p, 120)
    w.snap('farm')
    for _ in range(30):
        tap(w.p, 'b', hold=3, wait=20)
        if not m[0xC8EB] & 0x10 and not m[TEXTBOX] & 1 and m[GAME_MODE] == 1:
            break
    w.idle()
    w.check('the FARM KEEPER: the farm screen opened and the hall came back',
            opened and w.where()[0] == hall, f'at ${w.where()[0]:02X}')

    print('field: the STAIRS -> THE MUSTER FIELD, a wild battle from list 700')
    w.goto(hall, 0, 8, 2)
    w.face('up')
    w.step('up')
    w.idle()
    w.check('the STAIRS (a real door) -> THE MUSTER FIELD', w.where()[0] == field,
            f'at ${w.where()[0]:02X}')
    w.goto(field, 0, 4, 3)
    w.face('up')
    adv(w.p, 20)
    w.said.clear()
    w.talk()
    w.idle()
    w.check_said('the FIELD GUIDE', 'muster_field')
    lst = bytes(enc.list_bytes(700))
    golem = 519 + 1000 - 1
    buf = w.sym['wEncListBuf'][1]
    got_battle, eids, listbuf = False, None, None
    for k in range(400):
        m[0xCA39], m[0xCA3A] = 0x00, 0x00                 # the next step draws a battle
        w.step(('left', 'right')[k % 2])
        if m[GAME_MODE] == 2:
            listbuf = bytes(m[buf + i] for i in range(26))
            fought, eids = fight(w, no_join=True)
            got_battle = fought
            break
    w.check('a wild battle came in THE MUSTER FIELD', got_battle)
    w.check('the list in use (wEncListBuf) == your battle list 700 (a battle bank)',
            listbuf == lst, f'{listbuf.hex() if listbuf else None} vs {lst.hex()}')
    w.check(f'the enemy == the GOLEM row 1,000 (EID {golem})',
            bool(eids) and eids[0] == golem, f'battle EIDs {eids}')
    w.check('back in THE MUSTER FIELD after the battle', w.where()[0] == field,
            f'at ${w.where()[0]:02X}')
    w.snap('field')
    m[0xCA39], m[0xCA3A] = 0xFF, 0x7F
    w.goto(field, 0, 1, 2)
    w.face('up')
    w.step('up')
    w.idle()
    w.check('the field STAIRS (a real door) -> back up to THE MUSTER HALL',
            w.where()[0] == hall, f'at ${w.where()[0]:02X}')
    w.goto(hall, 0, 7, 5)
    w.face('down')
    adv(w.p, 20)
    res = w.talk(answers=[True])
    w.idle()
    w.check('the EXIT GUIDE (YES) -> Cities_FOUNT', w.where()[0] == cities,
            f'{res}, at ${w.where()[0]:02X}')
    if not a.no_far:
        far(w, rooms, a)
    print(f'WALK: {"PASS" if not w.fails else "FAIL %d" % w.fails} ({w.checks} checks)')
    if a.negative:
        print('(negative control: FAILs expected)')
    return 1 if w.fails and not a.negative else 0


if __name__ == '__main__':
    sys.exit(main())
