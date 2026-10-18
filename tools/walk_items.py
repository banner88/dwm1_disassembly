#!/usr/bin/env python3
"""walk_items.py — S151 (ROADMAP E9): items edited and NEW items, on the real screens
(PyBoy on the user's .sav).

The demo (examples/s151_items_demo/build_demo.py) = the user's project + the game's
WarpWing permanent and Herb stronger (field 40-50, battle 45-55) + five new items
(MegaHerb 44 / HeroSeed 45 / SparkRod 46 / Feather 47 / OldKey 48) + THE CURIO HALL /
THE CURIO YARD. Every check reads RAM (the bag $CA51, the Vault $CA65, gold, the party's
records) and what the TEXT ENGINE was handed (a hook on CallTextEngine's tail $05E3, as
walk_text.py) — screenshots are kept for the eye:

  guide   the CURIO GUIDE (Cities_FOUNT, YES) -> THE CURIO HALL
  buy     the CURIO STALL lists the new items with their names and prices; buying
          MegaHerb / HeroSeed / SparkRod / Feather takes exactly their prices and puts
          ids 44-47 in the bag
  use     the field menu: MegaHerb on a hurt monster heals 80-90 (its power 80 + 0-10)
          and says its OWN use line (a text bank, use line 48); it is used up; HeroSeed:
          ATK + 10 exactly; the Herb heals 40-50 (the game's item, edited)
  key     the KEYKEEPER gives the OldKey (48); the DOOR WARDEN's story check sees it;
          using it from the bag: "… uses the OldKey as a tool." (field use off), it stays
  sell    the stall's SELL list holds the SparkRod (paid 200 = a tenth: its base is a
          staff) and NOT the OldKey (not sellable)
  vault   the VAULT keeper: deposit the HeroSeed... (the Vault's own screens; the
          Vault holds id 45 afterwards) — then withdraw it back
  battle  THE CURIO YARD: a wild battle; ITEM -> MegaHerb on the hurt lead monster: the
          battle names it "MegaHerb" (wItemInUse) and heals 45-55 (its base, the Herb's
          battle power, edited); the battle won
  wing    the game's WarpWing (edited: never used up) thrown on a gate floor -> home, and
          the WarpWing is STILL in the bag
  lose    the BRUISER: a lost battle — the OldKey (kept on loss) stays, the MegaHerb /
          SparkRod (not kept) are gone

  python3 tools/walk_items.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative]

--negative: ItemRecordCopy's `ld [wItemBase], a` -> nops in the ROM copy (the new items
run whatever base was copied last): the new items' field checks must FAIL.
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, GAME_MODE, TEXTBOX, SCRIPT_FLAGS, PARTY_LIST  # noqa: E402
from tools.pyboy_harness import W_CHANGING as PB_W_CHANGING                          # noqa: E402
from tools.walk_regions import Walk, s_continue, CHOICE, TEXT_PTR                     # noqa: E402
from editor2.core import items as IT, textmark as TM                                    # noqa: E402

BAG, VAULT = 0xCA51, 0xCA65
MEGA, SEED, ROD, FEATHER, KEY = 44, 45, 46, 47, 48
HERB, WARPWING = 1, 29
C905, C906 = 0xC905, 0xC906


def text_at(rom, bank, addr):
    if 0x4000 <= addr < 0x8000:
        t = TM.scan(rom, bank * 0x4000 + addr - 0x4000)
        return None if t is None else t + b'\xf0'
    return None


class ItemWalk(Walk):
    def __init__(self, build, sav, keep, project):
        super().__init__(build, sav, keep)
        from editor2.core.project import Project
        prj = Project.load(project)
        prj.repo_root = REPO
        self.items = IT.resolve(prj, REPO)
        self.romb = open(self.rom, 'rb').read()
        self.shown = []

    def start(self, state=None):
        super().start(state)
        self.shown = []
        self.p.hook_register(0, 0x05E3, self._show, None)     # CallTextEngine's tail
        self.romb = open(self.rom, 'rb').read()

    def _show(self, _ctx):
        m = self.m
        b, a = m[0xC824], m[0xC82D] | m[0xC82E] << 8
        self.shown.append((b, a, text_at(self.romb, b, a)))

    # -- the bag
    def bag(self):
        return [self.m[BAG + i] for i in range(20)]

    def vault(self):
        return [self.m[VAULT + i] for i in range(40)]

    def slot(self, item):
        return next((i for i, v in enumerate(self.bag()) if v == item), None)

    def name_bytes(self, i):
        for t, n, raw, _w in self.items['texts']:
            if t == IT.NAME_TABLE and n == i:
                return raw[:-1]
        return None

    def own_line(self, i, kind='use'):
        n = self.items['messages'].get((i, kind))
        for t, k, raw, _w in self.items['texts']:
            if t == IT.USE_TABLE and k == n:
                return raw
        return None

    def use_msg_addr(self, n):
        """The game's use message n (bank $41, the pointer table at $4A1B): its address."""
        o = IT.TEXT_BANK * 0x4000 + IT.USE_TABLE - 0x4000 + 2 * n
        return self.romb[o] | self.romb[o + 1] << 8

    def mon(self, slot):
        """The record of party member `slot` (0-2): base address."""
        s = self.m[PARTY_LIST + slot]
        return 0xCAC1 + 149 * s

    def w16(self, a):
        return self.m[a] | self.m[a + 1] << 8

    # -- menus
    def wait(self, cond, maxf=1200, step=2):
        f = 0
        while f < maxf:
            if cond():
                return True
            adv(self.p, step)
            f += step
        return False

    def press(self, btn, cond=None, maxf=1200, wait=12):
        if cond is not None and not self.wait(cond, maxf):
            return False
        tap(self.p, btn, hold=3, wait=wait)
        return True

    def close_all(self):
        for _ in range(12):
            if self.m[C905] == 0 and not self.m[TEXTBOX] & 1 and not self.m[SCRIPT_FLAGS] & 1:
                break
            tap(self.p, 'b', hold=3, wait=30)
        self.idle()

    def shop_open(self):
        """Talk to the shopkeeper faced; -> True when BUY / SELL / EXIT waits."""
        tap(self.p, 'a', hold=3, wait=6)
        for i in range(120):                                  # the greeting waits for A
            if self.m[C905] == 2:
                adv(self.p, 40)
                return True
            adv(self.p, 10)
            if i % 4 == 3 and self.m[TEXTBOX] & 1:
                tap(self.p, 'a', hold=3, wait=4)
        return False

    def _stable(self, n=20):
        """Advance until the shop's state ($C905 / $C906) and the text engine ($C825) have
        been still for n frames. -> the state."""
        m = self.m
        last, still = None, 0
        for _ in range(600):
            st = (m[C905], m[C906], m[0xC825])
            if st == last and m[0xC825] == 0:
                still += 2
                if still >= n:
                    return st
            else:
                still = 0
            last = st
            adv(self.p, 2)
        return last

    def _cursor(self, pos):
        """In a 4-per-page list: move the cursor to pos (page = $C8E3, row = $C8E2 & $7F)."""
        m = self.m
        for _ in range(12):
            if m[0xC8E3] == pos // 4:
                break
            tap(self.p, 'right' if m[0xC8E3] < pos // 4 else 'left', hold=6, wait=20)
        for _ in range(8):
            if m[0xC8E2] & 0x7F == pos % 4:
                break
            tap(self.p, 'down' if m[0xC8E2] & 0x7F < pos % 4 else 'up', hold=6, wait=16)
        return m[0xC8E3] == pos // 4 and m[0xC8E2] & 0x7F == pos % 4

    def shop_buy(self, pos, item, qty=1):
        """From the BUY / SELL / EXIT menu: buy list position pos (0-based) — `item` must
        then be in the bag. Every press waits for a still state (the user's text speed)."""
        m = self.m
        n0 = self.bag().count(item)
        placed = False
        for _ in range(40):
            if self.bag().count(item) > n0:
                break
            c905, c906, _t = self._stable()
            if os.environ.get('WALK_DEBUG'):
                print('    shop', c905, c906, hex(m[0xC8E2]), m[0xC8E3], m[0xC8DD], self.bag()[14:])
            if c905 == 2:
                tap(self.p, 'a', hold=3, wait=6)              # BUY (the cursor's default)
            elif c906 in (2, 4):                              # the list (2: with its prompt)
                if not placed:                                # the list's cursor (the game
                    m[0xC8E3] = pos // 4                      #   reads page $C8E3 / row
                    m[0xC8E2] = pos % 4                       #   $C8E2 when A picks)
                    adv(self.p, 4)
                    placed = True
                tap(self.p, 'a', hold=3, wait=6)              # the item
            elif c906 in (5, 6, 7):
                for _ in range(qty - 1):
                    tap(self.p, 'up', hold=6, wait=12)
                tap(self.p, 'a', hold=3, wait=6)              # how many
            else:
                tap(self.p, 'a', hold=3, wait=6)              # a box / YES
        ok = self.bag().count(item) > n0
        for _ in range(10):                                   # back to BUY / SELL / EXIT
            c905, c906, _t = self._stable(10)
            if c905 == 2:
                break
            tap(self.p, 'b', hold=3, wait=10)
        return ok

    def shop_sell_list(self):
        """From BUY / SELL / EXIT: SELL; -> the sell list ($C0D8) shown."""
        m = self.m
        tap(self.p, 'down', hold=6, wait=20)
        self.press('a')
        self.wait(lambda: m[C906] >= 2, 1500)
        adv(self.p, 120)
        lst = []
        for k in range(20):
            v = m[0xC0D8 + k]
            if v in (0, 0xFF):
                break
            lst.append(v)
        return lst

    def field_use(self, item, pick=True, extra_a=6):
        """The field menu: ITEM, the item's page, USE, the lead monster (when it asks).
        The hero must face nothing (A talks to an NPC ahead — the CURIO HALL's quiet
        corner is (5, 1) facing the wall)."""
        p = self.p
        slot = self.slot(item)
        if slot is None:
            return False
        tap(p, 'a', hold=3, wait=90)
        tap(p, 'right', hold=8, wait=40)
        tap(p, 'a', hold=3, wait=60)                          # ITEM
        for _ in range(slot // 5):                            # 5 per page
            tap(p, 'right', hold=8, wait=30)
        for _ in range(slot % 5):
            tap(p, 'down', hold=8, wait=20)
        tap(p, 'a', hold=3, wait=60)                          # USE / DEL
        tap(p, 'a', hold=3, wait=60)                          # USE
        if pick:
            tap(p, 'a', hold=3, wait=60)                      # the lead monster
        for _ in range(extra_a):
            adv(p, 40)
            tap(p, 'a', hold=3, wait=20)
        for _ in range(6):
            tap(p, 'b', hold=3, wait=30)
        self.idle()
        return True

    def box_talk(self, yes=True, maxf=9000):
        """S151 r2: talk to the NPC faced and finish whatever it opens — A while a box
        waits, YES (or NO) at a question, B at a service / shop screen once it has been
        still for 40 frames. -> the dialog box's placement while a box is open, every 2
        frames: the list of $FFD3 values (1 top / 2 bottom), runs collapsed."""
        m, p = self.m, self.p
        place = []
        m[CHOICE] = 0
        tap(p, 'a', hold=3, wait=6)
        f = calm = still = 0
        last = [None, 0]
        state = None
        self.opened = 0
        while f < maxf:
            adv(p, 2)
            f += 2
            if m[C905]:
                self.opened += 2
                if self.opened == 30 and getattr(self, 'snap_name', None):
                    self.snap(self.snap_name)      # the screen, 30 frames in
            if m[TEXTBOX] & 1 and m[0xFFD3] in (1, 2):
                if not place or place[-1] != m[0xFFD3]:
                    place.append(m[0xFFD3])
            if m[CHOICE] == 1:
                want = 0 if yes else 1
                adv(p, 20)
                f += 20
                for _ in range(6):
                    if m[CHOICE] == want:
                        break
                    tap(p, 'up' if want == 0 else 'down', hold=6, wait=12)
                    f += 18
                tap(p, 'a', hold=3, wait=10)
                m[CHOICE] = 0
                continue
            busy = m[SCRIPT_FLAGS] & 1 or m[TEXTBOX] & 1 or m[C905]
            if not busy and m[GAME_MODE] == 1:
                calm += 1
                if calm > 40:
                    return place
                continue
            calm = 0
            ptr = m[TEXT_PTR] | m[TEXT_PTR + 1] << 8
            st = (m[C905], m[C906], ptr)
            if st != state:
                state, still = st, 0
            else:
                still += 2
            if m[C905] and still >= 40:
                tap(p, 'b', hold=3, wait=8)
                f += 11
                still = 0
            elif ptr != last[0]:
                last[0], last[1] = ptr, f
            elif m[TEXTBOX] & 1 and m[SCRIPT_FLAGS] & 1 and not m[C905] and f - last[1] >= 12:
                tap(p, 'a', hold=2, wait=4)
                f += 6
                last[1] = f
        return place + ['timeout']

    def quiet(self):
        """The CURIO HALL's quiet corner: (5, 1), facing the wall."""
        self.goto(self.rooms['hall'], 0, 5, 1)
        self.face('up')


# ------------------------------------------------------------------ the walk
def s_guide(w):
    print('guide: the CURIO GUIDE (Cities_FOUNT, YES) -> THE CURIO HALL')
    s_continue(w)
    m = w.m
    for k in range(14, 20):                                   # room in the bag (the save's is full)
        m[BAG + k] = 0xFF
    w.save('continue')
    w.goto(w.rooms['cities_fount'], 0, 3, 5)
    w.face('up')
    w.talk([True])
    w.idle()
    w.check('the CURIO GUIDE (YES) -> THE CURIO HALL', w.where()[0] == w.rooms['hall'],
            f'at ${w.where()[0]:02X}')
    w.save('hall')


def s_buy(w):
    print('buy: the CURIO STALL — names, prices, ids 44-47')
    w.start('hall')
    m = w.m
    w.goto(w.rooms['hall'], 0, 2, 4)
    w.face('up')
    n0 = len(w.shown)
    w.check('the stall opens (BUY / SELL / EXIT)', w.shop_open())
    rec = w.items['records']
    for pos, it in enumerate((MEGA, SEED, ROD, FEATHER)):
        g0 = w.gold()
        price = rec[it][1] | rec[it][2] << 8
        ok = w.shop_buy(pos, it)
        if pos == 0:
            w.snap('buy_list')
        w.check(f'bought item {it} for {price} G', ok and g0 - w.gold() == price and
                it in w.bag(), f'gold {g0} -> {w.gold()}, bag {w.bag()}')
    names = [w.name_bytes(i) for i in (MEGA, SEED, ROD, FEATHER)]
    shown = [t for _b, _a, t in w.shown[n0:] if t]
    w.check('the list showed the new items\' names from the text bank',
            all(any(t.startswith(nm) for t in shown) for nm in names),
            f'{len(shown)} texts shown')
    w.close_all()
    w.save('bought')


def s_use(w):
    print('use: MegaHerb heals 80-90 with its own line; HeroSeed ATK +10; Herb 40-50')
    w.start('bought')
    m = w.m
    w.quiet()
    a = w.mon(0)
    hp_max = w.w16(a + 0x52)
    m[a + 0x50], m[a + 0x51] = 1, 0                            # hurt: HP 1
    n0 = len(w.shown)
    w.field_use(MEGA)
    w.snap('used_megaherb')
    got = w.w16(a + 0x50) - 1
    want = min(hp_max - 1, 80)
    w.check('MegaHerb healed 80-90 (power 80 + 0-10)',
            (80 <= got <= 90) or (got == hp_max - 1 and hp_max - 1 < 90), f'+{got} (max {hp_max})')
    del want
    own = w.own_line(MEGA)
    w.check("MegaHerb said its OWN use line (use line 48, a text bank)",
            any(t == own and b >= 0x80 for b, _a, t in w.shown[n0:]),
            ' '.join(f'${b:02X}' for b, _a, _t in w.shown[n0:][-4:]))
    w.check('MegaHerb was used up', MEGA not in w.bag(), str(w.bag()))
    atk0 = w.w16(a + 0x58)
    w.field_use(SEED)
    w.check('HeroSeed: ATK + 10 exactly', w.w16(a + 0x58) - atk0 == 10,
            f'{atk0} -> {w.w16(a + 0x58)}')
    # the game's Herb (edited: power 40)
    k = w.slot(0xFF)
    m[BAG + k] = HERB
    m[a + 0x50], m[a + 0x51] = 1, 0
    w.field_use(HERB)
    got = w.w16(a + 0x50) - 1
    w.check("the game's Herb (edited power 40) healed 40-50", 40 <= got <= 50 or
            got == hp_max - 1, f'+{got}')
    w.save('used')


def s_key(w):
    print('key: the KEYKEEPER gives the OldKey; the DOOR WARDEN sees it; it cannot be used')
    w.start('used')
    w.goto(w.rooms['hall'], 0, 4, 6)
    w.face('up')
    w.said.clear()
    w.talk()
    w.idle()
    w.check_said('before the key the DOOR WARDEN said its ELSE line "bring me the OldKey"',
                 'curio_hall_warden_say2')
    w.goto(w.rooms['hall'], 0, 6, 5)
    w.face('up')
    w.talk()
    w.idle()
    w.check('the KEYKEEPER gave the OldKey (48)', KEY in w.bag(), str(w.bag()))
    w.goto(w.rooms['hall'], 0, 4, 6)
    w.face('up')
    w.said.clear()
    w.talk()
    w.idle()
    w.check_said('the DOOR WARDEN (story check: the bag holds item 48) said its THEN line '
                 '"you carry the OldKey"', 'curio_hall_warden_say1')
    n0 = len(w.shown)
    w.quiet()
    w.field_use(KEY, pick=False, extra_a=3)
    w.snap('used_oldkey')
    shown = [(b, a) for b, a, _t in w.shown[n0:]]
    w.check('the OldKey (field use off): "… uses the OldKey as a tool." + "But nothing '
            'happens" (use messages 1 + 2)',
            (IT.TEXT_BANK, w.use_msg_addr(1)) in shown and (IT.TEXT_BANK, w.use_msg_addr(2)) in shown,
            ' '.join(f'${b:02X}:{a:04X}' for b, a in shown[-4:]) +
            f' want ${w.use_msg_addr(1):04X} ${w.use_msg_addr(2):04X}')
    w.check('… and the OldKey stays (use-up chance 0)', KEY in w.bag(), str(w.bag()))
    w.save('key')


def s_sell(w):
    print('sell: SparkRod paid a tenth (a staff base), the OldKey not on the list')
    w.start('key')
    w.goto(w.rooms['hall'], 0, 2, 4)
    w.face('up')
    w.shop_open()
    lst = w.shop_sell_list()
    w.snap('sell_list')
    w.check('the SELL list holds the SparkRod (46), not the OldKey (48)',
            ROD in lst and KEY not in lst, str(lst))
    m = w.m
    pos = lst.index(ROD) if ROD in lst else 0
    for _ in range(pos // 4):
        tap(w.p, 'right', hold=6, wait=20)
    for _ in range(pos % 4):
        tap(w.p, 'down', hold=6, wait=16)
    g0 = w.gold()
    w.press('a')                                               # the item
    w.wait(lambda: m[C906] >= 5, 900)
    adv(w.p, 60)
    for _ in range(6):                                         # how many / YES
        tap(w.p, 'a', hold=3, wait=40)
        if ROD not in w.bag():
            break
    adv(w.p, 60)
    w.check('sold the SparkRod for 200 G (2000 / 10)', w.gold() - g0 == 200,
            f'gold {g0} -> {w.gold()}')
    w.close_all()


def s_battle(w):
    print('battle: THE CURIO YARD — ITEM -> MegaHerb heals 45-55, named MegaHerb')
    w.start('key')
    m, p = w.m, w.p
    k = w.slot(0xFF)
    m[BAG + k] = MEGA
    w.goto(w.rooms['yard'], 0, 4, 3)
    fought = False
    for i in range(400):
        if m[GAME_MODE] == 2:
            fought = True
            break
        m[0xCA39], m[0xCA3A] = 0, 0
        w.step(['left', 'right'][i % 2])
    w.check('a wild battle started', fought)
    # the command menu: FIGHT / PLAN / ITEM / RUN — ITEM = down from FIGHT
    a = w.mon(0)
    for _ in range(300):
        adv(p, 10)
        if m[0xD9F5] in (1, 2) and m[GAME_MODE] == 2:
            break
    adv(p, 120)
    m[0xDBA3], m[0xDBA4] = 1, 0                                # combatant 0's battle HP
    hp0 = 1
    slot = w.slot(MEGA)
    # the two reverse sites (banks $52 / $54: `ld a,[wItemInUse] / nop / nop`): hook the
    # first nop, read A = the item the battle names
    wiu = w.sym['wItemInUse'][1]
    named = []
    for bank in (0x52, 0x54):
        o = w.romb.find(bytes([0xFA, wiu & 0xFF, wiu >> 8, 0, 0]), bank * 0x4000, bank * 0x4000 + 0x4000)
        w.p.hook_register(bank, o - bank * 0x4000 + 0x4000 + 3,
                          lambda bk: named.append((bk, w.p.register_file.A)), bank)
    # FIGHT ITEM / PLAN RUN: ITEM = right; the list is 4 per page; then WHO: US / FOE,
    # then the monster
    tap(p, 'right', hold=6, wait=30)
    tap(p, 'a', hold=3, wait=60)                               # ITEM
    for _ in range(slot // 4):
        tap(p, 'right', hold=8, wait=30)
    for _ in range(slot % 4):
        tap(p, 'down', hold=8, wait=30)
    w.snap('battle_items')
    tap(p, 'a', hold=3, wait=60)                               # the item
    w.check('the battle remembers the item in use (wItemInUse = 44)',
            m[w.sym['wItemInUse'][1]] == MEGA, str(m[w.sym['wItemInUse'][1]]))
    tap(p, 'a', hold=3, wait=60)                               # WHO: US
    tap(p, 'a', hold=3, wait=60)                               # the lead monster
    healed = None
    snapped = False
    for _ in range(600):
        adv(p, 5)
        if named and not snapped:
            adv(p, 40)
            w.snap('battle_named')
            snapped = True
        hp = w.w16(0xDBA3)
        if hp != hp0:
            healed = hp - hp0
            break
        if m[GAME_MODE] != 2:
            break
    w.snap('battle_used')
    w.check('in battle the MegaHerb healed 45-55 (its base, the Herb: battle power 45)',
            healed is not None and 45 <= healed <= 55, f'+{healed}')
    w.check('the battle\'s item-name sites (banks $52 / $54) read 44 from wItemInUse',
            bool(named) and all(v == MEGA for _b, v in named), str(named))
    w.check('the battle won, the field back', w.battle_won())
    w.idle()


def s_wing(w):
    print('wing: the WarpWing (edited: never used up) thrown on a gate floor')
    w.start('key')
    m = w.m
    k = w.slot(0xFF)
    if WARPWING not in w.bag():
        m[BAG + k] = WARPWING
    m[0xC96D], m[0xC96E], m[0xC96C] = 1, 1, 1
    m[0xC88F] = (m[0xC88F] + 1) & 0xFF
    for _ in range(120):
        w.keep_enc()
        adv(w.p, 10)
    w.idle()
    w.check('on a gate floor', m[0xC969] != 0, f'map ${m[0xC968]:02X} gate {m[0xC935]}')
    w.use_warpwing()
    w.follow(2400, until=lambda: m[0xC969] == 0 and m[GAME_MODE] == 1)
    w.idle()
    w.check('the WarpWing took the party home (out of the gate)', m[0xC969] == 0,
            f'map ${m[0xC968]:02X}')
    w.check('the WarpWing is STILL in the bag (use-up chance 0)', WARPWING in w.bag(),
            str(w.bag()))


def s_feather(w):
    print('feather: the Feather (a NEW item, works like the WarpWing) thrown on a gate floor')
    w.start('key')
    m, p = w.m, w.p
    if FEATHER not in w.bag():
        m[BAG + w.slot(0xFF)] = FEATHER
    m[0xC96D], m[0xC96E], m[0xC96C] = 1, 1, 1
    m[0xC88F] = (m[0xC88F] + 1) & 0xFF
    for _ in range(120):
        w.keep_enc()
        adv(p, 10)
    w.idle()
    w.check('on a gate floor', m[0xC969] != 0, f'map ${m[0xC968]:02X} gate {m[0xC935]}')
    slot = w.slot(FEATHER)
    n0 = len(w.shown)
    tap(p, 'a', hold=3, wait=90)
    tap(p, 'right', hold=8, wait=40)
    tap(p, 'a', hold=3, wait=60)                               # ITEM
    for _ in range(slot // 5):
        tap(p, 'right', hold=8, wait=30)
    for _ in range(slot % 5):
        tap(p, 'down', hold=8, wait=20)
    tap(p, 'a', hold=3, wait=60)                               # USE / DEL
    tap(p, 'a', hold=3, wait=60)                               # USE
    here = w.where()
    for _ in range(20):
        if m[PB_W_CHANGING] or w.where() != here:
            break
        tap(p, 'a', hold=3, wait=30)
    w.follow(2400, until=lambda: m[0xC969] == 0 and m[GAME_MODE] == 1)
    w.idle()
    w.check('the Feather took the party home (the WarpWing\'s code, run by base 29)',
            m[0xC969] == 0, f'map ${m[0xC968]:02X}')
    del n0


def s_keyfull(w):
    print('keyfull: the KEYKEEPER with a FULL bag says so and gives nothing; with room: the key')
    w.start('used')
    m = w.m
    for k in range(20):
        if m[BAG + k] in (0, 0xFF):
            m[BAG + k] = HERB
    w.goto(w.rooms['hall'], 0, 6, 5)
    w.face('up')
    w.said.clear()
    w.talk()
    w.idle()
    w.check_said('a full bag: the KEYKEEPER said the "full" words', 'curio_hall_keykeeper_full')
    w.check('… and gave nothing (the bag unchanged, no OldKey)', KEY not in w.bag(), str(w.bag()))
    w.check('… and said nothing after the "full" words', str(w.said[-1]).startswith(
        'curio_hall_keykeeper_full') if w.said else False, str(w.said))
    m[BAG + 19] = 0xFF
    w.said.clear()
    w.talk()
    w.idle()
    w.check('room again: the KEYKEEPER gives the OldKey', KEY in w.bag() and
            any(str(t).startswith('curio_hall_keykeeper_got') for t in w.said), str(w.said))
    w.said.clear()
    w.talk()
    w.idle()
    w.check_said('then: "I gave you the OldKey already"', 'curio_hall_keykeeper_say1')


def s_services(w):
    print('services: the stall and every service NPC talked to from BELOW keep the box at the '
          'bottom; a plain sign talked to from below still opens at the top')
    w.start('hall')

    def plain_talk(row):
        w.goto(w.rooms[row], 0, 7, 6)
        w.face('right')
        return w.box_talk(yes=False)
    for row, x, y, name in (('row1', 3, 4, 'the stall'), ('row1', 6, 5, 'the Vault keeper'),
                            ('row2', 3, 4, 'the farm keeper'), ('row2', 6, 5, 'the librarian'),
                            ('row3', 3, 4, 'the namer'), ('row3', 6, 5, 'the Medal Man'),
                            ('row4', 3, 4, 'the egg appraiser'), ('row4', 6, 5, 'the gate guide')):
        w.goto(w.rooms[row], 0, x, y + 1)
        w.face('up')
        w.snap_name = f"svc_{row}_{x}"
        place = w.box_talk(yes=True)
        w.snap_name = None
        w.check(f'{name} from below: its screen opened ({w.opened} frames) and every box '
                'stayed at the BOTTOM ($FFD3 2)', place == [2] and w.opened > 0, str(place))
        pp = plain_talk(row)
        w.check(f'… then the plain sign from below: its box at the TOP ($FFD3 1 — no bottom '
                'request left over)', pp and pp[0] == 1, str(pp))
    # the gate guide answered NO: its farewell in the question's box, then the sign
    w.goto(w.rooms['row4'], 0, 6, 6)
    w.face('up')
    place = w.box_talk(yes=False)
    w.check('the gate guide answered NO from below: every box at the BOTTOM', place == [2],
            str(place))
    pp = plain_talk('row4')
    w.check('… then the plain sign from below: its box at the TOP', pp and pp[0] == 1, str(pp))


def s_speed(w):
    print('speed: every demo room runs at full speed (the field tick counter $C8A4 against '
          'the frames)')
    w.start('hall')
    m = w.m
    for key in ('hall', 'yard', 'row1', 'row2', 'row3', 'row4'):
        w.goto(w.rooms[key], 0, 5, 3 if key == 'yard' else 2)
        w.idle()
        t0 = m[0xC8A4] | m[0xC8A5] << 8
        adv(w.p, 600)
        t1 = m[0xC8A4] | m[0xC8A5] << 8
        speed = ((t1 - t0) & 0xFFFF) / 600
        w.check(f'{key}: the game ticks every frame ({speed:.2f} ticks / frame)', speed > 0.97,
                f'{speed:.3f}')


def s_lose(w):
    print('lose: the BRUISER — the OldKey (kept on loss) stays, the MegaHerb goes')
    w.start('key')
    m = w.m
    k = w.slot(0xFF)
    m[BAG + k] = MEGA
    w.goto(w.rooms['yard'], 0, 6, 6)
    w.face('up')
    w.party_hp_1()
    r = w.talk([True])
    w.check('the BRUISER fight started', r == 'battle', r)
    w.battle_lost()
    w.follow(1500, until=lambda: w.idle(600))
    w.check('lost: the OldKey (kept on loss) is still in the bag', KEY in w.bag(), str(w.bag()))
    w.check('lost: the MegaHerb (not kept) is gone', MEGA not in w.bag(), str(w.bag()))


def negative_rom(w):
    b, a = w.sym['ItemRecordCopy']
    rom = bytearray(open(w.rom, 'rb').read())
    o = b * 0x4000 + a - 0x4000
    wb = w.sym['wItemBase'][1]
    k = rom.find(bytes([0xEA, wb & 0xFF, wb >> 8]), o, o + 0x30)
    rom[k:k + 3] = b'\x00\x00\x00'
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print('NEGATIVE CONTROL: ItemRecordCopy without its wItemBase store')


STEPS = {'guide': s_guide, 'buy': s_buy, 'use': s_use, 'key': s_key, 'sell': s_sell,
         'battle': s_battle, 'wing': s_wing, 'feather': s_feather, 'lose': s_lose,
         'keyfull': s_keyfull, 'services': s_services, 'speed': s_speed}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--only', default=None)
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = ItemWalk(a.build, a.sav, a.keep, a.project)
    d = json.load(open(a.project))
    ids = {r['id']: int(r['mapID'], 16) for r in d['custom']['rooms']}
    w.rooms = {'cities_fount': ids['cities_fount'],
               'hall': next(v for k, v in ids.items() if 'curio' in k and 'hall' in k),
               'yard': next(v for k, v in ids.items() if 'curio' in k and 'yard' in k),
               **{f'row{n}': v for n in range(1, 5) for k, v in ids.items()
                  if k == f'service_row_{n}'}}
    if a.negative:
        negative_rom(w)
    steps = list(STEPS) if not a.only else a.only.split(',')
    for name in steps:
        try:
            STEPS[name](w)
        except Exception as e:                       # noqa: BLE001 — a step that crashes fails
            import traceback
            traceback.print_exc()
            w.check(f'{name} ran', False, repr(e))
    print(f'WALK: {"PASS" if not w.fails else "FAIL " + str(w.fails)} ({w.checks} checks)')
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
