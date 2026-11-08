#!/usr/bin/env python3
"""walk_foods.py — S172 (gamedata.foods, "Foods instead of meats"): the foods in the game
(PyBoy on the user's .sav; PROJECT_COMPILER §2.78, ROOM_DATA_FORMAT "NPC sprite tables
(S172)").

The demo (examples/s172_foods_demo/build_demo.py) = the user's project + the tick ON +
THE PANTRY / THE LARDER / THE CELLAR (the five foods as NPC props, the game's meat prop
$5F, a stall selling the five, the HUNGRY SLIME to feed). Checks read RAM / VRAM / OAM and
what the text engine was handed (CallTextEngine's tail $05E3 — walk_items.py):

  guide   the PANTRY GUIDE (Cities_FOUNT, YES) -> THE PANTRY
  sheets  in each room every food prop's VRAM sheet (tiles 0-3) == its picture
          (editor2/core/foods.py sheet(): editor2/assets/foods/*.png), its four OAM
          pieces in its OBJ palette, at the 2 x 2 places; the meat prop $5F = the Apple
  frame   300 frames in each room: every food prop drawn with tiles 0-3 only (a standing
          NPC steps between frames 0 and 1 — the objects have ONE frame; bank $77
          NpcDrawPlain holds NpcStaticIds on frame 0)
  turn    talk to TOAST from its side: its words shown, and through the talk (the NPC
          turns to the player) it stays its picture
  names   the PANTRY STALL: the list = Toast / Apple / Biscuit / Honey / BadApple (ids
          19 20 21 23 22) and the names it drew are the foods'; a Toast bought for 20 G
  battle  the HUNGRY SLIME: ITEM -> Toast: the battle names item 19 (wItemInUse) and its
          name buffer holds "Toast"; the feeding line ("eats the treat" kind) is shown;
          the battle won

  python3 tools/walk_foods.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative]

--negative: NpcStaticIds emptied in the ROM copy (the game's draw): the frame / turn checks
must FAIL. Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, GAME_MODE                       # noqa: E402
from tools.walk_regions import s_continue                                 # noqa: E402
from tools.walk_items import ItemWalk, BAG                                # noqa: E402
from editor2.core import foods as FD, textmark as TM                      # noqa: E402

SLOTS = 0xD7D2
TOAST = 19


class FoodWalk(ItemWalk):
    def slots(self):
        m = self.m
        out = []
        for i in range(8):
            b = SLOTS + 32 * i
            if m[b] == 0xFF:
                break
            out.append({'i': i, 'type': m[b], 'sprite': m[b + 0x11], 'frame': m[b + 0x14],
                        'base': m[b + 0x16]})
        return out

    def pieces(self, base):
        """The real OAM pieces whose tile is in the 16-tile sheet at `base`."""
        m = self.m
        out = []
        for k in range(40):
            y, x, t, a = (m[0xFE00 + 4 * k + j] for j in range(4))
            if 0 < y < 160 and base <= t < base + 16:
                out.append((y, x, t, a))
        return out

    def drawn_ok(self, s):
        ps = self.pieces(s['base'])
        if sorted(p[2] - s['base'] for p in ps) != [0, 1, 2, 3]:
            return False
        ys = sorted({p[0] for p in ps})
        xs = sorted({p[1] for p in ps})
        return len(ys) == 2 and len(xs) == 2 and ys[1] - ys[0] == 8 and xs[1] - xs[0] == 8


def s_guide(w):
    print('guide: the PANTRY GUIDE (Cities_FOUNT, YES) -> THE PANTRY')
    s_continue(w)
    m = w.m
    for k in range(14, 20):                                   # room in the bag
        m[BAG + k] = 0xFF
    m[0xCA4B], m[0xCA4C], m[0xCA4D] = 0x10, 0x27, 0x00        # 10,000 G (wGold, 3 B LE)
    w.save('continue')
    w.goto(w.rooms['cities_fount'], 0, 3, 5)
    w.face('up')
    w.talk([True])
    w.idle()
    w.check('the PANTRY GUIDE (YES) -> THE PANTRY', w.where()[0] == w.rooms['pantry'],
            f"at ${w.where()[0]:02X}")
    w.save('pantry')


def s_sheets(w):
    print('sheets: every food prop = its picture, its colours, 2 x 2')
    sp = FD.sprites()
    for room, stand in (('pantry', (4, 6)), ('larder', (7, 6)), ('cellar', (6, 6))):
        w.start('pantry')
        w.goto(w.rooms[room], 0, *stand)
        adv(w.p, 60)
        w.snap(f'sheets_{room}')
        for s in w.slots():
            if s['sprite'] not in sp:
                continue
            name, pal, food = sp[s['sprite']]
            want = FD.sheet(name, pal, w.prj_data)[:64]
            got = bytes(w.p.memory[0, 0x8000 + 16 * s['base']:0x8000 + 16 * s['base'] + 64])
            w.check(f"{room}: sprite ${s['sprite']:02X} ({food}) — its sheet in VRAM is the "
                    f"{name} picture", got == want)
            ps = w.pieces(s['base'])
            w.check(f"{room}: sprite ${s['sprite']:02X} drawn as 4 pieces in OBJ palette {pal} "
                    f"({FD.PALETTE_NAMES[pal]})", len(ps) == 4 and all(p[3] & 7 == pal for p in ps)
                    and w.drawn_ok(s), str(ps))


def s_frame(w):
    print('frame: 300 frames each room — every food prop shows its one frame')
    sp = FD.sprites()
    for room, stand in (('pantry', (4, 6)), ('larder', (7, 6)), ('cellar', (6, 6))):
        w.start('pantry')
        w.goto(w.rooms[room], 0, *stand)
        bad = n = 0
        frames = set()
        for _ in range(300):
            adv(w.p, 1)
            for s in w.slots():
                if s['sprite'] in sp:
                    n += 1
                    frames.add(s['frame'])
                    if not w.drawn_ok(s):
                        bad += 1
        w.check(f'{room}: the props drawn with their one frame on every frame '
                f'(slot frames seen {sorted(frames)})', n > 0 and bad == 0, f'{bad} / {n} wrong')


def s_turn(w):
    print('turn: talk to TOAST from its side — it turns, it stays toast')
    w.start('pantry')
    m = w.m
    w.goto(w.rooms['pantry'], 0, 3, 4)                       # left of Toast (4, 4)
    w.face('right')
    toast = next(s for s in w.slots() if s['sprite'] == 0x58)
    bad = n = 0
    said0 = len(w.said)
    tap(w.p, 'a', hold=3, wait=2)
    for f in range(240):
        adv(w.p, 2)
        s = w.slots()[toast['i']]
        n += 1
        if not w.drawn_ok(s):
            bad += 1
        if m[0xC8EB] & 1 and f % 15 == 14:
            tap(w.p, 'a', hold=2, wait=2)
    w.idle()
    w.check('TOAST said its words', any('toast' in str(t) for t in w.said[said0:]),
            ', '.join(map(str, w.said[said0:])))
    w.check('through the talk TOAST stays its picture (tiles 0-3, 2 x 2)', bad == 0,
            f'{bad} / {n} wrong')


def s_names(w):
    print('names: the PANTRY STALL — the foods, a Toast for 20 G')
    w.start('pantry')
    m = w.m
    w.goto(w.rooms['pantry'], 0, 2, 3)
    w.face('up')
    n0 = len(w.shown)
    w.check('the stall opens (BUY / SELL / EXIT)', w.shop_open())
    g0 = w.gold()
    ok = w.shop_buy(0, TOAST)
    w.snap('names_list')
    lst = [m[0xC0D8 + k] for k in range(5)]
    w.check('the list = 19 20 21 23 22', lst == [19, 20, 21, 23, 22], str(lst))
    w.check('a Toast (item 19) bought for 20 G', ok and g0 - w.gold() == 20,
            f'gold {g0} -> {w.gold()}')
    shown = [t for _b, _a, t in w.shown[n0:] if t]
    for i, nm, old, *_r in FD.FOODS:
        if i == 22:
            continue                                          # 5th row: the list's 2nd page
        enc = TM.encode(nm, 'rows')
        w.check(f'the list drew "{nm}" (not {old})', any(t.startswith(enc) for t in shown),
                f'{len(shown)} texts')
    w.close_all()
    w.save('bought')


def s_descs(w):
    """S172 r3: the bag's INFO box — each food its own description (the strength)."""
    print('descs: the bag (field menu -> ITEM) — each food\'s own description')
    w.start('continue')
    m, p = w.m, w.p
    for k, f in enumerate(FD.FOODS):                          # slots 0-4 = the five foods
        m[BAG + k] = f[0]
    n0 = len(w.shown)
    tap(p, 'a', hold=3, wait=90)                              # the field menu
    tap(p, 'right', hold=8, wait=40)
    tap(p, 'a', hold=3, wait=60)                              # ITEM
    adv(p, 30)
    seen = {}
    for k, f in enumerate(FD.FOODS):
        if k:
            tap(p, 'down', hold=8, wait=20)
        adv(p, 30)
        w.snap(f'desc_{f[5]}')
        seen[f[0]] = [t for _b, _a, t in w.shown[n0:] if t]
        n0 = len(w.shown)
    for i, nm, old, *_r in FD.FOODS:
        want = TM.encode(FD.DESCRIPTIONS[i], 'rows')
        w.check(f'{nm}: "{FD.DESCRIPTIONS[i].replace(chr(10), " / ")}"',
                any(t.startswith(want) for t in seen[i]), f'{len(seen[i])} texts')
    for _ in range(6):
        tap(p, 'b', hold=3, wait=30)
    w.idle()


def s_battle(w):
    print('battle: the HUNGRY SLIME — ITEM -> Toast')
    w.start('bought')
    m, p = w.m, w.p
    w.goto(w.rooms['cellar'], 0, 6, 5)                       # below the slime (6, 4)
    w.face('up')
    r = w.talk([True])
    w.check('the HUNGRY SLIME fight started', r == 'battle', r)
    for _ in range(300):
        adv(p, 10)
        if m[0xD9F5] in (1, 2) and m[GAME_MODE] == 2:
            break
    adv(p, 120)
    slot = w.slot(TOAST)
    wiu = w.sym['wItemInUse'][1]
    enc = TM.encode('Toast', 'rows')
    seen_name = []
    n0 = len(w.shown)
    tap(p, 'right', hold=6, wait=30)
    tap(p, 'a', hold=3, wait=60)                              # ITEM
    for _ in range(slot // 4):
        tap(p, 'right', hold=8, wait=30)
    for _ in range(slot % 4):
        tap(p, 'down', hold=8, wait=30)
    w.snap('battle_items')
    tap(p, 'a', hold=3, wait=60)                              # the Toast
    w.check('the battle remembers the item in use (wItemInUse = 19)', m[wiu] == TOAST,
            str(m[wiu]))
    for k in range(400):
        if k < 4:
            tap(p, 'a', hold=3, wait=40)                      # WHO / the target
        adv(p, 5)
        buf = bytes(m[a] for a in range(0xC100, 0xC200))
        if enc in buf:
            seen_name.append(k)
        if k == 40:
            w.snap('battle_toast')
        if TOAST not in w.bag() and k > 60:
            break
    shown = [t for _b, _a, t in w.shown[n0:] if t]
    w.check('the battle\'s name buffer held "Toast"', bool(seen_name))
    w.check('the Toast was used up (thrown)', TOAST not in w.bag(), str(w.bag()))
    treat = TM.encode('treat', 'rows')
    w.check('a feeding line was shown ("… the treat!")', any(treat in t for t in shown),
            f'{len(shown)} texts')
    w.check('the battle won, the field back', w.battle_won())
    w.idle()


PICK_CELLS = [(2, 2), (4, 2), (6, 2), (2, 5), (6, 5)]


def pickup_check(w, what):
    """Every forced food pickup: 4 pieces, tiles $50 + 4k .. +3, OAM attr bit 3 (VRAM bank 1)
    and its palette; the Herb: the game's icon (tiles $50-$53, bank 0, palette 1); VRAM bank
    1 $8500 + 64k == the food's icon."""
    m = w.m
    bad = []
    for k, (cx, cy) in enumerate(PICK_CELLS):
        f = FD.FOODS[k]
        ps = [(m[0xFE00 + 4 * i + 2], m[0xFE00 + 4 * i + 3]) for i in range(40)
              if cy * 16 <= m[0xFE00 + 4 * i] - 16 < cy * 16 + 16
              and cx * 16 <= m[0xFE00 + 4 * i + 1] - 8 < cx * 16 + 16]
        want_t = [0x50 + 4 * k + j for j in range(4)]
        if sorted(t for t, _a in ps) != want_t or not all(a & 0x0F == (f[4] | 8) for _t, a in ps):
            bad.append((f[1], ps))
    hx, hy = 8, 3
    hs = [(m[0xFE00 + 4 * i + 2], m[0xFE00 + 4 * i + 3]) for i in range(40)
          if hy * 16 <= m[0xFE00 + 4 * i] - 16 < hy * 16 + 16
          and hx * 16 <= m[0xFE00 + 4 * i + 1] - 8 < hx * 16 + 16]
    herb_ok = sorted(t for t, _a in hs) == [0x50, 0x51, 0x52, 0x53] and \
        all(a & 0x0F == 1 for _t, a in hs)
    vram = [bytes(w.p.memory[1, 0x8500 + 64 * k:0x8500 + 64 * k + 64]) ==
            FD.icon_bytes(f[5], f[4], w.prj_data) for k, f in enumerate(FD.FOODS)]
    w.check(f'{what}: every food pickup drawn with its own icon (VRAM bank 1, its palette)',
            not bad, str(bad[:2]))
    w.check(f'{what}: the Herb keeps the game\'s icon (bank 0, green)', herb_ok, str(hs))
    w.check(f'{what}: VRAM bank 1 $8500-$863F == the five pictures', all(vram), str(vram))


def force_foods(w):
    m = w.m
    scr = m[0xC925]
    o = 0xD793
    for k, (cx, cy) in enumerate(PICK_CELLS):
        m[o], m[o + 1], m[o + 2], m[o + 3] = 0, 19 + k, (scr % 4) * 10 + cx, (scr // 4) * 8 + cy
        o += 4
    m[o], m[o + 1], m[o + 2], m[o + 3] = 0, 1, (scr % 4) * 10 + 8, (scr // 4) * 8 + 3
    m[o + 4] = 0xFF


def s_pickups(w):
    print('pickups: a gate floor — each food its own pickup icon; after the menu; after a battle')
    w.start('continue')
    m, p = w.m, w.p
    t = []
    b, a = w.sym['FoodIconsLoad']
    b2, a2 = w.sym['FoodIconsLoad.orig']
    p.hook_register(b, a, lambda _: t.append(p.frame_count), None)
    p.hook_register(b2, a2, lambda _: t.append(p.frame_count), None)
    m[0xD8D7] = 0                                         # gate 0 by the exit mailbox
    m[0xC96D], m[0xC96E], m[0xC96C], m[0xC88F] = 0, 1, 1, (m[0xC88F] + 1) & 0xFF
    for _ in range(900):
        m[0xCA39], m[0xCA3A] = 0, 0x70
        p.tick()
    w.check('on gate 0 floor 1', m[0xC969] == 1 and m[0xC935] == 0, f'map ${m[0xC968]:02X}')
    w.check('FoodIconsLoad ran at the room load (≤ 3 frames)', len(t) >= 2 and t[1] - t[0] <= 3,
            str(t))
    force_foods(w)
    adv(p, 20)
    w.snap('pickups')
    pickup_check(w, 'on the floor')
    w.save('pickups')
    # the field menu (bank $07 reloads the 8 icons when it closes)
    tap(p, 'a', hold=3, wait=90)
    w.check('the field menu opened', bool(m[0xC8EB] & 2), hex(m[0xC8EB]))
    for _ in range(4):
        tap(p, 'b', hold=3, wait=40)
    adv(p, 60)
    pickup_check(w, 'after the field menu')
    # a battle on the floor (the room reloads after it: FoodIconsLoad again)
    n0 = len(t)
    m[0xCA39], m[0xCA3A] = 0, 0
    fought = False
    for i in range(200):
        if m[0xC88A] == 2:
            fought = True
            break
        w.step(['left', 'right'][i % 2])
        m[0xCA39], m[0xCA3A] = 0, 0
    w.check('a wild battle on the floor', fought)
    w.check('the battle won, the field back', w.battle_won())
    w.idle()
    force_foods(w)
    adv(p, 20)
    w.check('the room reload after the battle ran FoodIconsLoad again', len(t) > n0, str(t[n0:]))
    pickup_check(w, 'after the battle')


STEPS = {'guide': s_guide, 'descs': s_descs, 'sheets': s_sheets, 'frame': s_frame, 'turn': s_turn,
         'names': s_names, 'battle': s_battle, 'pickups': s_pickups}


def negative_rom(w):
    b, a = w.sym['NpcStaticIds']
    rom = bytearray(open(w.rom, 'rb').read())
    rom[b * 0x4000 + a - 0x4000] = 0xFF
    b, a = w.sym['FoodIconCount']                         # S172 r2: the game's pickup icons
    rom[b * 0x4000 + a - 0x4000] = 0
    open(w.rom, 'wb').write(rom)
    w.romb = bytes(rom)
    print('NEGATIVE CONTROL: NpcStaticIds emptied (the game\'s draw of the one-frame objects); '
          'FoodIconCount = 0 (the game\'s pickup icons)')


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
    w = FoodWalk(a.build, a.sav, a.keep, a.project)
    d = json.load(open(a.project))
    w.prj_data = d
    ids = {r['id']: int(r['mapID'], 16) for r in d['custom']['rooms']}
    w.rooms = {'cities_fount': ids['cities_fount'],
               **{k: next(v for rid, v in ids.items() if rid.startswith(k)) for k in
                  ('pantry', 'larder', 'cellar')}}
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
