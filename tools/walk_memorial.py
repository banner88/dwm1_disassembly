#!/usr/bin/env python3
"""walk_memorial.py — S154: THE MEMORIAL walked on the user's save (PyBoy).

The demo (examples/s154_memorial_demo/build_demo.py) = the user's project + THE MEMORIAL
HALL (screen 0: three statues in state 0, five in state 1 — the MASON's flag; the
CHAMPION, a conversation battle = a boss battle; screen 1: the FARM KEEPER, the EXIT
GUIDE, the BREEDER) + THE MEMORIAL CRYPT (two statues, served on gate 2's floor 2).
Every check reads RAM / VRAM / SRAM (the list in SRAM bank 3, the records' +$82 tags,
the statues' four VRAM tiles each, the text inserts $C180 / $C190 / $C1A0, the text the
script showed); screenshots are kept for the eye:

  empty      the hall with nothing remembered: every statue's tiles = the sheet's
             empty-statue picture; the list is empty
  champion   the CHAMPION won -> the three fighters on the list (tag 8, species,
             level, nickname), their records' +$82 = 8; the hall still shows no
             monster (none has left)
  again      the CHAMPION won again: during the battle each tagged fighter's packed
             resistance byte 0 bits 7-6 ($DD28 + 7k) = 0, as untagged; the list
             still holds 3 entries (no duplicate) with this win's levels
  breed      the BREEDER: the level 23 monster bred away (the ceremony, the naming
             screen) -> back in the hall: exactly one statue shows it — its 4 tiles
             == the empty picture with the species' standing picture laid over it
             (MemPics in the ROM == memorial.pictures in Python) — the rest empty
  words      examining that statue: the inserts = its nickname / level 23 / its
             species' name, the statue words shown; an empty statue: the empty words
  menu       the field menu opened and closed: the statue tiles are drawn again
  save       JOURNAL save -> reset -> CONTINUE: the list's live window back (count 3);
             a victory after the save is FORGOTTEN by a reset without saving
  grown      two more fighters gone (their tags cleared — the list's lazy check),
             the MASON's flag: five statues, three monsters, every one different,
             over ten visits all three shown and the order changing (random)
  battle     a won battle in the hall (CHAMPION) keeps the statues (no re-roll on the
             return from the battle)
  crypt      gate 2's dive, floor 2 = THE MEMORIAL CRYPT: its two statues drawn
  census     MemBattleEnd stub-called over the battle kinds: a boss ($DA09 3), the
             listed plain-op bosses (EID 127 / 199 / 343), an arena class's third
             match, Starry Night's final are remembered; a lost / fled battle, an
             ordinary or scripted battle, a class's first match, Starry's rounds,
             Monster Grandpa's match are not

  python3 tools/walk_memorial.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative]

--negative: the four memorial regions' hooks undone in the ROM copy (bank $50 / $0B
back to the vanilla bytes): nothing is remembered and no statue is drawn — the walk
must FAIL. Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import os
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, GAME_MODE, TEXTBOX, SCRIPT_FLAGS, MAP_ID   # noqa: E402
from tools.pyboy_harness import PARTY_LIST                                          # noqa: E402
from tools.walk_regions import (Walk, s_continue, CHOICE, TEXT_PTR, SERVICE_TYPE,    # noqa: E402
                                GAME_STATE_BIT4, BREED_STAGE)

HALL, CRYPT = 0x77, 0x78
CITY = 0x6E
STATUES0 = [(3, 2), (5, 2), (7, 2)]
STATUES1 = STATUES0 + [(2, 3), (8, 3)]
REC = 0xCAC1
RECSZ = 149


class MemWalk(Walk):
    def __init__(self, build, sav, keep, project):
        super().__init__(build, sav, keep)
        from editor2.core.project import Project
        from editor2.core import memorial as MM
        import json
        prj = Project(json.load(open(project)), os.path.dirname(os.path.abspath(project)))
        prj.repo_root = REPO
        self.MM = MM
        self.pics = MM.pictures(prj)
        self.rooms = {(F_region(r), F_map(r)): [MM.statue_tiles(s) for s in MM.room_statues(r)]
                      for r in prj.rooms if MM.room_statues(r)}
        # S154 r2: the palette index each statue draws the monster's colours 1 / 2 / 3 in
        self.shades = {(F_region(r), F_map(r)): [MM.statue_shades(s) for s in MM.room_statues(r)]
                       for r in prj.rooms if MM.room_statues(r)}
        self.romb = open(self.rom, 'rb').read()
        self.prj_rooms = prj.rooms
        self.project = project
        self.placeholder = {}

    def w(self, name):
        return self.sym[name][1]

    # -- the list
    def memlist(self):
        m = self.m
        c, h = m[self.w('wMemCount')], m[self.w('wMemHead')]
        ring = self.romb_val('MEM_RING')
        out = []
        for i in range(c):
            r = (h + i) % ring
            a = 0xA110 + 8 * r
            out.append(tuple(self.p.memory[3, a + k] for k in range(8)))
        return out

    def romb_val(self, name):
        # EQU constants are not in the .sym: MEM_RING = MEM_CAP + 9 (the demo's cap 120)
        return {'MEM_RING': 129, 'MEM_CAP': 120}[name]

    def rec(self, slot, off):
        return self.m[REC + RECSZ * slot + off]

    def party(self):
        return [self.m[PARTY_LIST + k] for k in range(3) if self.m[PARTY_LIST + k] != 0xFF]

    def picks(self):
        return [self.m[self.w('wMemPicks') + i] for i in range(8)]

    # -- the statues in VRAM
    def tiles_of(self, mid=HALL, region=0):
        return self.rooms[(region, mid)]

    def vram_tile(self, t):
        return bytes(self.p.memory[0, 0x9000 + 16 * t:0x9000 + 16 * t + 16])

    def statue_vram(self, k, mid=HALL):
        return b''.join(self.vram_tile(t) for t in self.tiles_of(mid)[k])

    def expected(self, k, species, mid=HALL):
        """The statue's background with species' picture laid over it (colour 0 =
        see-through; S154 r2: colours 1 / 2 / 3 in the statue's shade indices)."""
        base = self.placeholder[(mid, k)]
        pic = self.pics[species * 64:(species + 1) * 64]
        sh = self.shades[(0, mid)][k]
        out = bytearray(base)
        for i in range(0, 64, 2):
            lo, hi = pic[i], pic[i + 1]
            msk = lo | hi
            p = (lo & ~hi & 0xFF, hi & ~lo & 0xFF, lo & hi)
            nlo = nhi = 0
            for c in range(3):
                if sh[c] & 1:
                    nlo |= p[c]
                if sh[c] & 2:
                    nhi |= p[c]
            out[i] = (base[i] & ~msk & 0xFF) | nlo
            out[i + 1] = (base[i + 1] & ~msk & 0xFF) | nhi
        return bytes(out)

    def shown(self, mid=HALL):
        """Per statue: None = its empty picture, a species = that monster drawn, '?' = neither."""
        out = []
        for k in range(len(self.tiles_of(mid))):
            v = self.statue_vram(k, mid)
            if v == self.placeholder[(mid, k)]:
                out.append(None)
                continue
            hit = [s for s in range(240) if any(self.pics[s * 64:(s + 1) * 64])
                   and self.expected(k, s, mid) == v]
            out.append(hit[0] if hit else '?')
        return out

    def rom_pics_ok(self):
        b, a = self.sym['MemPics']
        o = b * 0x4000 + a - 0x4000
        return self.romb[o:o + 240 * 64] == self.pics

    # -- the field
    def calm_text(self, n=30, maxf=3000):
        m = self.m
        last, same = None, 0
        for _ in range(0, maxf, 2):
            adv(self.p, 2)
            ptr = m[TEXT_PTR] | m[TEXT_PTR + 1] << 8
            if ptr == last:
                same += 2
            else:
                same, last = 0, ptr
            if same >= n:
                return True
        return False

    def drive(self, until, maxf=60000):
        """A on boxes, YES on questions, START + A on a naming screen, until `until()`."""
        m, p = self.m, self.p
        for f in range(0, maxf, 10):
            adv(p, 10)
            if until():
                return True
            if m[CHOICE] == 1:
                adv(p, 20)
                for _ in range(4):
                    if m[CHOICE] == 0:
                        break
                    tap(p, 'up', hold=6, wait=12)
                tap(p, 'a', hold=3, wait=10)
                m[CHOICE] = 0
                continue
            if m[SERVICE_TYPE] == 15 and m[GAME_STATE_BIT4] & 0x10:
                tap(p, 'start', hold=3, wait=10)
                tap(p, 'a', hold=3, wait=10)
                continue
            if f % 40 == 0 and (m[TEXTBOX] & 1 or m[SCRIPT_FLAGS] & 1):
                tap(p, 'a', hold=2, wait=2)
        return False

    def field_calm(self):
        m = self.m
        return (m[GAME_MODE] == 1 and not m[SCRIPT_FLAGS] & 1 and not m[TEXTBOX] & 1
                and not m[GAME_STATE_BIT4] & 0x10 and not m[0xC96C])

    def examine(self, x, y, mid=HALL):
        """Stand below statue (x, y), face up, A — the words shown + the inserts."""
        self.goto(mid, 0, x, y + 1)
        self.face('up')
        self.said = []
        self.talk()
        m = self.m
        return (list(self.said), bytes(m[0xC180 + i] for i in range(6)),
                bytes(m[0xC190 + i] for i in range(3)), bytes(m[0xC1A0 + i] for i in range(10)),
                m[0xD8E1])

    def champion(self, during=None):
        """The CHAMPION (5, 4): YES, the battle won (its HP poked to 1)."""
        self.goto(HALL, 0, 5, 5)
        self.face('up')
        r = self.talk([True])
        if r != 'battle':
            return False
        m = self.m
        f, fought, seen = 0, False, False
        while f < 30000:
            adv(self.p, 10)
            f += 10
            if m[GAME_MODE] == 2:
                fought = True
                if during is not None and not seen and m[0xD9EC] >= 4:
                    seen = during() or seen
                m[0xDB85] = 7
                for a in (0xDBAB, 0xDBAD, 0xDBAF):
                    if m[a] | m[a + 1] << 8:
                        m[a], m[a + 1] = 1, 0
                if f % 50 == 0:
                    tap(self.p, 'a', hold=3, wait=2)
            elif fought and m[GAME_MODE] == 1:
                break
        self.idle()
        return fought

    def breed_first(self):
        """The BREEDER (screen 1 (2, 6)): YES, the first monster of the WHO list (the level
        23 one), OK, the ceremony, the naming screen — back in the hall."""
        p = self.p
        self.goto(HALL, 0, 12, 5)
        self.face('down')
        self.m[CHOICE] = 0
        tap(p, 'a', hold=3, wait=6)
        for cmd in 'c,a,c,a,c,a,c,a,c,a,c,a,c,down,w20,a'.split(','):
            if cmd == 'c':
                self.calm_text()
            elif cmd.startswith('w'):
                adv(p, int(cmd[1:]))
            else:
                tap(p, cmd, hold=3, wait=10)
        went = []

        def back():
            if self.m[MAP_ID] == 0x08:
                went.append(1)
            return bool(went) and self.m[MAP_ID] == HALL and self.field_calm()
        ok = self.drive(back)
        self.idle()
        return ok and bool(went)


def F_region(r):
    from editor2.core import formats as F
    return F.mid_region(F.val(r['mapID']))


def F_map(r):
    from editor2.core import formats as F
    return F.val(r['mapID']) & 0xFF


# ------------------------------------------------------------------ the walk
def s_empty(w):
    print('empty: the hall with nothing remembered')
    w.start('continue')
    w.goto(HALL, 0, 5, 5)
    adv(w.p, 30)
    for k in range(len(w.tiles_of())):
        w.placeholder[(HALL, k)] = w.statue_vram(k)
    w.check('the list is empty', w.memlist() == [], str(w.memlist()))
    w.check('no statue shows a monster (no picks)', all(x == 0xFF for x in w.picks()),
            str(w.picks()))
    w.check('the picture bank in the ROM == memorial.pictures', w.rom_pics_ok())
    w.snap('empty')
    w.save('hall')


def s_champion(w):
    print('champion: the CHAMPION won -> the fighters remembered')
    w.start('hall')
    team = [(s, w.rec(s, 9), w.rec(s, 0x4B), bytes(w.rec(s, 1 + i) for i in range(4)))
            for s in w.party()]
    ok = w.champion()
    w.check('the CHAMPION fought and won', ok)
    lst = w.memlist()
    w.check('three entries, one per fighter (tag 8, species, level, nickname)',
            sorted((e[1], e[2], bytes(e[3:7])) for e in lst)
            == sorted((sp, lv, nk) for _s, sp, lv, nk in team) and all(e[0] == 8 for e in lst),
            f'{lst} vs {team}')
    w.check("the fighters' records carry tag 8 at +$82",
            all(w.rec(s, 0x82) == 8 for s in w.party()), str([w.rec(s, 0x82) for s in w.party()]))
    w.goto(CITY, 0, 4, 5)
    w.goto(HALL, 0, 5, 5)
    w.check('back in the hall: no statue shows a monster (all are still here)',
            w.shown() == [None] * len(w.tiles_of()), str(w.shown()))
    w.save('won')
    w.team = team


def s_again(w):
    print('again: a second win — tags in battle, no duplicate entries')
    w.start('won')
    packed = {}

    def look():
        m = w.m
        for k in range(3):
            packed[k] = m[0xDD28 + 7 * k]
        return True
    ok = w.champion(during=look)
    w.check('won again', ok)
    w.check("in battle every tagged fighter's packed resistance byte 0 bits 7-6 = 0 "
            '(the tag reads as the vanilla 0)', packed and all((v & 0xC0) == 0 for v in packed.values()),
            str(packed))
    lst = w.memlist()
    w.check('still three entries (a monster is remembered once)', len(lst) == 3, str(lst))
    w.save('won2')


def s_breed(w):
    print('breed: the level 23 monster bred away -> its statue')
    w.start('won2')
    s0 = w.party()[0]
    sp, lv, nk = w.rec(s0, 9), w.rec(s0, 0x4B), bytes(w.rec(s0, 1 + i) for i in range(4))
    ok = w.breed_first()
    w.check('the breeding ceremony ran and the game came back to the hall', ok,
            f'map ${w.m[MAP_ID]:02X}')
    left = not any(w.rec(s, 9) == sp and w.rec(s, 0x82) == 8 for s in range(20))
    w.check(f'the parent (species {sp}) is no longer with the player', left)
    w.goto(CITY, 0, 4, 5)
    w.goto(HALL, 0, 5, 5)
    adv(w.p, 20)
    sh = w.shown()
    w.check(f'statue 1 (the first to fill) shows species {sp}, the other four empty',
            sh == [sp] + [None] * (len(sh) - 1), str(sh))
    w.snap('bred')
    if sp in sh:
        see_through(w, sh.index(sp), sp)
    w.save('bred')
    w.parent = (sp, lv, nk, sh.index(sp) if sp in sh else None)


def _pic16(w, sp):
    """The species' picture as 16 x 16 colour indices (TL, TR, BL, BR tiles)."""
    b = w.pics[sp * 64:(sp + 1) * 64]
    out = [[0] * 16 for _ in range(16)]
    for t, (ty, tx) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
        for r in range(8):
            lo, hi = b[t * 16 + 2 * r], b[t * 16 + 2 * r + 1]
            for c in range(8):
                out[ty * 8 + r][tx * 8 + c] = ((lo >> (7 - c)) & 1) | (((hi >> (7 - c)) & 1) << 1)
    return out


def see_through(w, k, sp):
    """S154 r2 (the user: "Monster should be grey but BACKGROUND should be transparent"):
    on the SCREEN, the monster cell above statue k's pedestal shows the floor wherever the
    monster has no pixel (== a plain floor cell, pixel for pixel), the monster's middle
    shade is one grey (r = g = b), and the pedestal cell below draws the room's pedestal."""
    import numpy as np
    scr = np.asarray(w.p.screen.ndarray)[:, :, :3]
    scx, scy = w.m[0xFF43], w.m[0xFF42]
    px, py = STATUES0[k]

    def cell(cx, cy):
        x0, y0 = cx * 16 - scx, cy * 16 - scy
        return scr[y0:y0 + 16, x0:x0 + 16]
    mon, ref = cell(px, py - 1), cell(4, 1)
    pic = _pic16(w, sp)
    bg = [(r, c) for r in range(16) for c in range(16) if pic[r][c] == 0]
    same = sum(1 for r, c in bg if tuple(mon[r, c]) == tuple(ref[r, c]))
    w.check('see-through: every pixel of the monster cell the monster leaves empty shows '
            'the floor (== the plain floor cell at (4, 1))', same == len(bg),
            f'{same} / {len(bg)}')
    mids = {tuple(int(v) for v in mon[r, c]) for r in range(16) for c in range(16)
            if pic[r][c] == 2}
    w.check("the monster's middle shade is one grey on screen (r = g = b)",
            len(mids) == 1 and len(set(next(iter(mids)))) == 1, str(mids))
    room = next(r for r in w.prj_rooms if w.MM.room_statues(r) and F_map(r) == HALL)
    ped = [w.MM.F.val(t) for t in w.MM.room_statues(room)[k]['pedestal']]
    # the BG map: room cell (cx, cy) = map rows cy*2.. / cols cx*2.. (the room is drawn
    # from map (0, 0); SCX / SCY scroll it — the same origin the screen crops use)
    def mapcell(cx, cy):
        return [w.p.memory[0, 0x9800 + ((cy * 2 + dr) % 32) * 32 + (cx * 2 + dc) % 32]
                for dr in (0, 1) for dc in (0, 1)]
    w.check("the pedestal cell draws the room's Pedestal metatile, the cell above it the "
            "statue's monster tiles",
            mapcell(px, py) == ped and mapcell(px, py - 1) == w.tiles_of()[k],
            f'{[hex(t) for t in mapcell(px, py)]} / {[hex(t) for t in mapcell(px, py - 1)]}')


def s_words(w):
    print('words: examining the statues')
    w.start('bred')
    sp, lv, nk, k = w.parent
    if k is None:
        w.check('a statue to examine', False)
        return
    x, y = STATUES0[k]
    said, name, level, spname, flag = w.examine(x, y)
    want_lv = bytes([lv // 10, lv % 10, 0xF0]) if lv >= 10 else bytes([lv, 0xF0])
    w.check('the statue words were shown', said == ['memorial_default_text'], str(said))
    w.check('{fallen} = its nickname', name[:4] == nk[:4] and name[4] == 0xF0,
            f'{name.hex()} vs {nk.hex()}')
    w.check(f'{{fallen_level}} = {lv}', level[:len(want_lv)] == want_lv, level.hex())
    from editor2.core import monster_text as MT
    w.check('{fallen_species} = a species name ($F0-ended), $D8E1 = 1',
            0xF0 in spname and flag == 1, f'{spname.hex()} flag {flag}')
    e = next(i for i in range(3) if i != k)
    x, y = STATUES0[e]
    said, *_r, flag = w.examine(x, y)
    w.check('an empty statue says the empty words ($D8E1 = 0)',
            said == ['memorial_default_empty'] and flag == 0, f'{said} {flag}')
    w.snap('words')


def s_menu(w):
    print('menu: the field menu over the hall (it loads its own tiles over the sheet)')
    w.start('bred')
    w.goto(HALL, 0, 4, 5)
    w.face('down')                                   # facing nothing: A opens the menu
    before = [w.statue_vram(k) for k in range(len(w.tiles_of()))]
    p, m = w.p, w.m
    tap(p, 'a', hold=3, wait=120)
    during = [w.statue_vram(k) for k in range(len(w.tiles_of()))]
    opened = bool(m[0xC8EB] & 0x02)
    w.snap('menu_open')
    for _ in range(6):
        tap(p, 'b', hold=3, wait=40)
    w.idle()
    after = [w.statue_vram(k) for k in range(len(w.tiles_of()))]
    w.check('the field menu opened over the statue tiles (they changed under it)',
            opened and during != before, f'opened {opened}')
    w.check('the menu closed: every statue is drawn again as before', after == before)


def s_save(w):
    print('save: JOURNAL save -> reset -> CONTINUE')
    w.start('bred')
    n0 = len(w.memlist())
    ok = save_game(w)
    w.check('the game was saved (JOURNAL: SaveGameState ran)', ok)
    p = w.p
    w.check('bank 3 holds magic "M1" + the live window',
            bytes(p.memory[3, 0xA003 + i] for i in range(2)) == b'M1' and p.memory[3, 0xA005] == n0,
            f'{bytes(p.memory[3, 0xA003 + i] for i in range(4)).hex()}')
    p.stop(save=True)
    w.p = None
    path = os.path.join(w.keep, 'saved.sav')
    shutil.copy(w.rom + '.ram', path)
    w.sav = path
    s_continue(w)
    w.check('after CONTINUE the list is back (the same live entries)', len(w.memlist()) == n0,
            f'{len(w.memlist())} vs {n0}')
    # a victory after the save (a fresh fighter), then a reset without saving: forgotten
    s1 = w.party()[-1]
    w.m[REC + RECSZ * s1 + 0x82] = 0
    w.champion()
    n1 = len(w.memlist())
    s_continue(w)
    w.check('a victory after the save is forgotten by a reset without saving',
            len(w.memlist()) == n0 and n1 > n0, f'{n1} before the reset, {len(w.memlist())} after')


def save_game(w):
    """The field menu -> OPTN -> JOURNAL -> YES (PYBOY_DEBUGGING S134), from a cell that
    faces nothing; True when SaveGameState ran."""
    p = w.p
    w.goto(HALL, 0, 4, 5)
    w.face('down')
    hits = []
    sb, sa = w.sym.get('SaveGameState', (0, 0x2128))
    p.hook_register(sb, sa, lambda _c: hits.append(1), None)
    for _ in range(3):
        tap(p, 'b', wait=20)
    tap(p, 'a', hold=3, wait=90)
    tap(p, 'down', hold=8, wait=30)
    tap(p, 'right', hold=8, wait=30)
    tap(p, 'a', hold=3, wait=60)
    for _ in range(3):
        tap(p, 'down', hold=8, wait=30)
    tap(p, 'a', hold=3, wait=90)
    tap(p, 'a', hold=3, wait=200)
    for _ in range(4):
        tap(p, 'b', wait=30)
    p.hook_deregister(sb, sa)
    w.idle()
    return bool(hits)


def s_grown(w):
    print('grown: five statues, three gone monsters, every one different, random')
    w.start('bred')
    for s in w.party():
        if w.rec(s, 0x82) == 8:
            w.m[REC + RECSZ * s + 0x82] = 0        # the lazy check: this monster "left"
    w.goto(HALL, 0, 7, 5)
    w.face('down')
    w.talk([True])                                # the MASON: YES -> the flag + refresh
    w.idle()
    seen, orders = set(), set()
    for v in range(10):
        w.goto(CITY, 0, 4, 5)
        adv(w.p, 17 + 29 * v)
        w.goto(HALL, 0, 5, 5)
        adv(w.p, 20)
        sh = w.shown()
        mons = [x for x in sh if x is not None]
        if v == 0:
            w.snap('grown')
            w.check('state 1: five statues on the screen (the layout draws them)', len(sh) == 5,
                    str(sh))
        w.check(f'visit {v + 1}: three monsters, all different, none unknown',
                len(mons) == 3 and len(set(mons)) == 3 and '?' not in sh, str(sh))
        seen |= set(mons)
        orders.add(tuple(sh))
    w.check('over ten visits the three are all shown and the statues change', len(seen) == 3
            and len(orders) > 1, f'{len(orders)} different arrangements')
    w.save('grown')


def s_battle(w):
    print('battle: a battle in the hall keeps the statues')
    w.start('grown')
    w.goto(HALL, 0, 5, 5)
    before = w.shown()
    w.champion()
    w.goto(HALL, 0, 5, 5)                          # (the same room: no re-roll)
    w.check('after the battle the statues show the same monsters', w.shown() == before,
            f'{before} -> {w.shown()}')


def s_crypt(w):
    print('crypt: gate 2 floor 2 serves THE MEMORIAL CRYPT')
    w.start('grown')
    m = w.m
    # the gate entrance: S115 recipe — the warp mailbox with gate_flag 1 (gate 2), then the
    # staircase kick to floor 2 (PYBOY_DEBUGGING S115)
    m[SCRIPT_FLAGS] = 0
    m[0xC96D], m[0xC96E] = 2, 1
    m[0xC96C] = 1
    m[0xC88F] = (m[0xC88F] + 1) & 0xFF
    for _ in range(120):
        w.keep_enc()
        adv(w.p, 10)
    w.idle()
    w.kick(2)
    for _ in range(30):
        w.keep_enc()
        adv(w.p, 10)
    w.check('floor 2 is THE MEMORIAL CRYPT', m[MAP_ID] == CRYPT, f'map ${m[MAP_ID]:02X}')
    if m[MAP_ID] != CRYPT:
        return
    sh = []
    for k in range(2):
        v = w.statue_vram(k, CRYPT)
        hit = [s for s in range(240) if any(w.pics[s * 64:(s + 1) * 64])
               and crypt_expected(w, k, s) == v]
        sh.append(hit[0] if hit else None)
    w.snap('crypt')
    w.check('the crypt\'s two statues show two different gone monsters', None not in sh
            and len(set(sh)) == 2, str(sh))


def crypt_expected(w, k, s):
    # the crypt statue's background = its 4 tiles as the project's sheet holds them (S154
    # r2: the floor that was there, copied by the editor)
    from editor2.core.document import Document
    doc = Document(w.project)
    room = next(r for r in doc.rooms if r.get('statues') and F_map(r) == CRYPT)
    sheet = doc.read_sheet(room['record']['tileset'])
    base = b''.join(bytes(sheet[t * 16:t * 16 + 16]) for t in w.tiles_of(CRYPT)[k])
    w.placeholder[(CRYPT, k)] = base
    return w.expected(k, s, CRYPT)


def s_census(w):
    print('census: MemBattleEnd over the battle kinds (stub calls)')
    w.start('grown')
    m, p = w.m, w.p
    b, a = w.sym['MemBattleEnd']
    STUB = 0xDEC0                       # the $DEBE-$DEDD reserve (zeroed at boot only)
    MARK = 0xDEDC
    code = [0xF3, 0x21, 0x07, 0x79, 0xD7, 0x3E, 0xA5, 0xEA, MARK & 0xFF, MARK >> 8, 0x18, 0xFE]
    lab = (w.sym['ArenaMapID'][1])
    cases = [
        ('a boss battle ($DA09 3)', dict(da09=3), True),
        ('Digster (plain op, EID 127)', dict(da09=1, eid=127), True),
        ('Durran (plain op, EID 199)', dict(da09=1, eid=199), True),
        ('Terry (plain op, EID 343)', dict(da09=1, eid=343), True),
        ('a scripted battle (plain op, EID 2)', dict(da09=1, eid=2), False),
        ('an ordinary battle ($DA09 0)', dict(da09=0), False),
        ('a party-scaled battle ($DA09 2)', dict(da09=2), False),
        ('a boss battle LOST', dict(da09=3, post=1), False),
        ('a boss battle fled', dict(da09=3, post=2), False),
        ('an arena class, third match', dict(arena=True, d999=0, d9ce=3, d9cd=3), True),
        ('an arena class, first match', dict(arena=True, d999=0, d9ce=3, d9cd=1), False),
        ('Starry Night, a round', dict(arena=True, d999=1, d9ce=8, d9cd=2), False),
        ('Starry Night, the final', dict(arena=True, d999=2, d9ce=8, d9cd=3), True),
        ("Monster Grandpa's match", dict(arena=True, d999=4, d9ce=9, d9cd=3), False),
    ]
    base = w.memlist()
    for what, c, want in cases:
        w.start('grown')
        m, p = w.m, w.p
        n0 = len(w.memlist())
        # a fresh fighter: party slot 1's monster untagged (+$82 = 0) so a recorded win adds it
        s1 = w.party()[1]
        m[REC + RECSZ * s1 + 0x82] = 0
        m[w.w('wMemPartyN')] = m[0xCA8D]
        m[0xDB55] = c.get('post', 0)
        m[0xDA09] = c.get('da09', 0)
        e = c.get('eid', 0)
        m[0xDA03], m[0xDA04] = e & 0xFF, e >> 8
        m[0xD999] = c.get('d999', 0)
        m[0xD9CE] = c.get('d9ce', 0)
        m[0xD9CD] = c.get('d9cd', 0)
        if c.get('arena'):
            m[MAP_ID] = 0x5D
        for i, v in enumerate(code):
            m[STUB + i] = v
        m[MARK] = 0
        pc = p.register_file.PC
        p.register_file.PC = STUB
        for _ in range(200):
            adv(p, 1)
            if m[MARK] == 0xA5:
                break
        got = len(w.memlist()) > n0
        w.check(f'{what}: {"remembered" if want else "not remembered"}',
                m[MARK] == 0xA5 and got == want, f'mark {m[MARK]:02X} entries {n0}->{len(w.memlist())}')
    _ = (base, lab, b, a, pc)


def negative_rom(w):
    """The memorial regions' hooks back to the vanilla bytes in the ROM copy."""
    rom = bytearray(open(w.rom, 'rb').read())
    swaps = [(bytes([0x21, 0x06, 0x79, 0xD7]), bytes([0x21, 0x02, 0x17, 0xD7])),
             (bytes([0x21, 0x07, 0x79, 0xD7]), bytes([0x21, 0x06, 0x01, 0xD7]))]
    n = 0
    for old, new in swaps:
        k = rom.find(old, 0x50 * 0x4000, 0x51 * 0x4000)
        if k >= 0:
            rom[k:k + 4] = new
            n += 1
    hook = bytes([0x21, 0x08, 0x79, 0xD7, 0x00, 0x00, 0x00])
    for _ in range(2):
        k = rom.find(hook, 0x0B * 0x4000, 0x0C * 0x4000)
        if k >= 0:
            rom[k:k + 7] = bytes([0xFA, 0x68, 0xC9, 0x3E, 0x08, 0x20, 0x00])
            n += 1
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print(f'NEGATIVE CONTROL: {n} memorial hooks back to the vanilla bytes')


def s_species(w):
    """S154 r2 (the user: "confirm this will work with a) monsters I swap sprites out and
    b) new custom monsters"): the project's re-arted species (gamedata.art) and its new
    species (custom.species) on the statues — the list's entries 1 / 2 re-pointed to them
    (their tag + species then match nobody: gone), the hall entered again: the statues
    show them, each == its NEW art's picture laid over the background (VRAM)."""
    print('species: a re-arted species and a new species on the statues')
    from editor2.core import art as AR, species as SP, memorial as MM
    from editor2.core.project import Project
    import json
    prj = Project(json.load(open(w.project)), os.path.dirname(os.path.abspath(w.project)))
    prj.repo_root = REPO
    rearted = sorted(sid for sid, a in AR.resolve(prj).items() if a.get('follower_art'))
    news = sorted(sp['id'] for sp in SP.resolve(prj) if sp.get('follower_art'))
    if not rearted and not news:
        print('  (the project has no re-arted or new species: skipped)')
        return
    want = (rearted[:1] + news[:1])[:2]
    from editor2.core.sprite_render import _load
    ms = (_load('monster_sprites.json') or {}).get('monsters') or {}
    for sid in rearted[:1]:
        orig = ms.get(str(sid))
        from editor2.core.sprite_render import species_layout_id
        lid, _a = species_layout_id(sid)
        old = MM.picture_bytes(MM.frame_pixels(bytes.fromhex(orig['follower']['tile_bytes_hex']),
                                               lid, REPO))
        w.check(f'species {sid} (re-arted): its picture in the ROM is the NEW art, not the '
                'original', w.pics[sid * 64:(sid + 1) * 64] != old and w.rom_pics_ok())
    w.start('bred')
    live = w.memlist()
    ring = w.romb_val('MEM_RING')
    c, h = w.m[w.w('wMemCount')], w.m[w.w('wMemHead')]
    for j, sp in enumerate(want):
        r = (h + 1 + j) % ring
        w.p.memory[3, 0xA110 + 8 * r + 1] = sp
    w.goto(CITY, 0, 4, 5)
    w.goto(HALL, 0, 5, 5)
    adv(w.p, 20)
    sh = w.shown()
    w.check(f'the statues show species {want} (with the bred-away one), each its own art '
            '(VRAM == the picture over the background)',
            all(sp in sh for sp in want) and '?' not in sh, f'{sh}; list {live} (count {c})')
    w.snap('species')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--only', default='')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = MemWalk(a.build, a.sav, a.keep, a.project)
    if a.negative:
        negative_rom(w)
    steps = [s_continue, s_empty, s_champion, s_again, s_breed, s_words, s_menu, s_species,
             s_grown, s_battle, s_crypt, s_census, s_save]
    only = [x for x in a.only.split(',') if x]
    for st in steps:
        name = st.__name__[2:]
        if only and name not in only:
            continue
        try:
            st(w)
        except Exception as ex:                      # noqa: BLE001 — a step that breaks fails
            w.check(f'{name}: ran to the end', False, repr(ex))
    print(f'WALK: {"PASS" if not w.fails else "FAIL " + str(w.fails)} ({w.checks} checks)')
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
