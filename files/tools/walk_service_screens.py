#!/usr/bin/env python3
"""walk_service_screens.py — a service menu keeps its sheet slots free on ITS OWN screen only
(S177), walked on a real save.

The user (S177): "If grandpa or other services require tiles … can we not have this drag down
multi screen rooms but push this into their own subroutines on that screen only, ideally?"
Since S177 the editor keeps the slots of `services.BORROWED_SLOTS` free only on the screens
whose NPCs / spots open the menu (services.screen_reservations); the other screens of the room
may draw with them. This walk measures why that is safe, on the project's breeding NPC:

  * another screen of the room draws cells with those slots (the case is exercised);
  * on the NPC's screen, the menu opened and run (BREED / HATCH / EXIT, back out), sampled every
    2 frames: it writes slots of the kept range (it really draws there) and NO visible room cell
    shows a slot it wrote (walk_page2.room_art_damage);
  * after it: VRAM bank 0's room slots == before the talk (the room's animated slots aside) —
    the other screens' tiles in those slots are back before the player can scroll to them;
  * the player walks on to the neighbouring screen by the scroll (no reload) when a way exists
    and that screen shows its cells with their own tiles.
  --negative: a visible room cell of the NPC's screen is pointed at a kept slot before the talk
  (what the editor now forbids there) — the damage check MUST fail.

    python3 tools/walk_service_screens.py --build <dir> --project <dir> --sav <.sav>
        [--keep DIR] [--negative]
"""
import argparse
import json
import os
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, PLAYER_TX, PLAYER_TY, SCREEN_IDX, MAP_ID   # noqa: E402
from tools.walk_regions import Walk, s_continue                                      # noqa: E402
from tools.walk_page2 import visible_cells, room_ref, room_art_damage                # noqa: E402
from editor2.core import services as SV                                              # noqa: E402

# S177 r2: through the first-time lines, BREED, WHO, a monster, "That one?" (the info box
# with its name — the user: "visual glitches when selecting monsters"), INFO, back out
KEYS = [('a', 70)] * 16 + [('down', 40), ('up', 40)] + [('b', 70)] * 14
DIRS = {'down': (0, 1), 'up': (0, -1), 'left': (-1, 0), 'right': (1, 0)}


def find_breeder(pj):
    """(room, screen key, npc, kept slots on that screen) of the first NPC whose menu keeps
    slots (Grandpa / a breeder)."""
    c = pj['custom']
    by_id = {s.get('id'): s for s in c.get('scripts', [])}
    for r in c['rooms']:
        screens = [(k, s.get('states') or [s]) for k, s in (r.get('screens') or {}).items()]
        wide, per = SV.screen_reservations(r, screens, by_id)
        for k, slots in sorted(per.items()):
            for st in (r['screens'][str(k)].get('states') or [r['screens'][str(k)]]):
                for e in st.get('npcs') or []:
                    if e.get('kind') == 'npc' and SV.borrowing_screens(
                            [by_id.get(e.get('script'), {})]):
                        return r, k, e, slots, wide
    raise SystemExit('no breeding / farm / egg NPC in the project')


def animated(w):
    a = room_ref(w.m)[1]
    seen = set()
    for _ in range(8):
        adv(w.p, 16)
        b = room_ref(w.m)[1]
        seen |= {k * 128 + s for k in (0, 1) for s in range(128)
                 if a[k][s * 16:s * 16 + 16] != b[k][s * 16:s * 16 + 16]}
    return seen


def window_cells(m, ref):
    """S177 r2, by the font's frame glyphs (independent of the engine's rule): on each
    visible row above the HUD, a cell between a left edge `$FE` / corner and the next right
    edge `$FF` is a window cell — its attribute must be palette 7, VRAM bank 0; a cell
    outside every window with a tile < $80 equal to the room's (ref) must keep the room's
    attribute. -> [(row, col, tile, attr, 'window' | 'room')] that do not."""
    mp = ref[0]
    bad = []
    rows = {}
    for a, r, c, t, at in visible_cells(m):
        if r < 16:
            rows.setdefault(r, []).append((c, a, t, at))
    for r, cells in rows.items():
        inside = False
        for c, a, t, at in sorted(cells):
            if t in (0xFE, 0xFA, 0xFC):
                inside = True
                continue
            if t in (0xFF, 0xFB, 0xFD):
                inside = False
                continue
            if t >= 0x80:
                continue
            if inside and at != 0x07:
                bad.append((r, c, t, at, 'window'))
            elif not inside and mp.get(a, (None,))[0] == t and mp[a][1] != at:
                bad.append((r, c, t, at, 'room'))
    return bad


def kept_cells(m, kept):
    return [(r, c, t) for _a, r, c, t, at in visible_cells(m) if r < 100 and r < 16
            and not at & 0x08 and t in kept]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--negative-run', action='store_true')
    args = ap.parse_args()
    keep = args.keep or tempfile.mkdtemp(prefix='walk_svc_')
    os.makedirs(keep, exist_ok=True)
    w = Walk(args.build, args.sav, keep)
    pj = json.load(open(os.path.join(args.project, 'project.json')))
    room, key, npc, kept, wide = find_breeder(pj)
    mid = int(str(room['mapID']), 16)
    print(f"the menu NPC: {room.get('name')} screen {key} ({npc['x']},{npc['y']}); kept there: "
          f"${min(kept):02X}-${max(kept):02X} ({len(kept)} slots); room-wide: {len(wide)}")
    s_continue(w)
    m = w.m

    # 1. another screen draws with kept slots
    others = []
    for k in sorted(int(x) for x in room['screens']):
        if k == key:
            continue
        col, row = k % 4, k // 4
        if w.goto(mid, 0, col * 10 + 4, row * 8 + 4) and m[SCREEN_IDX] == k:
            n = kept_cells(m, kept)
            if n:
                others.append((k, len(n)))
    w.check('other screens of the room draw cells with the menu\'s slots (the case is exercised)',
            bool(others), ', '.join(f'screen {k}: {n} cells' for k, n in others))

    # 2. the menu on its own screen
    col, row = key % 4, key // 4
    stood = None
    for d in ('up', 'down', 'left', 'right'):
        dx, dy = DIRS[d]
        x, y = npc['x'] - dx, npc['y'] - dy
        if not (0 <= x < 10 and 0 <= y < 8):
            continue
        if w.goto(mid, 0, col * 10 + x, row * 8 + y) and (m[PLAYER_TX], m[PLAYER_TY]) == (
                col * 10 + x, row * 8 + y):
            w.face(d)
            w.idle()
            stood = (x, y, d)
            break
    w.check('standing beside the menu NPC', stood is not None, str(stood))
    if stood is None:
        return 1
    anim = animated(w)
    if args.negative_run:
        # S177 r2: PushRunIsMenu answers "room" always (`and a / ret`) in a ROM copy
        b, a = w.sym['PushRunIsMenu']
        rom = bytearray(open(w.rom, 'rb').read())
        o = b * 0x4000 + a - 0x4000
        rom[o:o + 2] = bytes([0xA7, 0xC9])
        open(w.rom, 'wb').write(rom)
        w.start('continue')
        m = w.m
        w.goto(mid, 0, col * 10 + stood[0], row * 8 + stood[1])
        w.face(stood[2])
        w.idle()
        print('NEGATIVE CONTROL (--negative-run): PushRunIsMenu always answers "room"')
    if args.negative:
        # what the editor forbids on this screen: a room cell drawn with a kept slot
        cells = [(a, r, c) for a, r, c, t, at in visible_cells(m) if r < 100 and r < 15
                 and not at & 0x08]
        a, r, c = next((x for x in cells if (x[1], x[2]) == (8, 1)), cells[len(cells) // 2])
        t = 0x44 if 0x44 in kept else sorted(kept)[len(kept) // 2]   # Grandpa writes $40-$48 (S168 r2)
        m[0, a] = t
        m[0xC300 + r * 32 + c] = t        # the room map buffer the menus' pushes copy from
        print(f'NEGATIVE CONTROL: the visible cell ({r},{c}) pointed at kept slot ${t:02X}')
    ref = room_ref(m)
    before = ref[1][0]
    written, damage, frames = set(), set(), 0
    wins, wframes = [], 0
    tap(w.p, 'a', hold=3, wait=6)
    for btn, wait in KEYS:
        tap(w.p, btn, hold=3, wait=2)
        for _ in range(0, wait, 2):
            adv(w.p, 2)
            now = bytes(m[0, 0x9000:0x97FF]) + bytes([m[0, 0x97FF]])
            written |= {s for s in range(128) if s not in anim
                        and now[s * 16:s * 16 + 16] != before[s * 16:s * 16 + 16]}
            hit, nroom = room_art_damage(m, ref, skip=anim)
            if nroom >= 60:
                frames += 1
                damage |= hit
            if m[0xC8EB] & 0x10:                        # a menu screen is up
                wframes += 1
                wins += window_cells(m, ref)
    w.idle(maxf=4000)
    inside = sorted(s for s in written if s in kept)
    w.check(f'the menu wrote slots of its kept range while the room showed ({len(inside)} of them)',
            len(inside) >= 8, f"${min(inside):02X}-${max(inside):02X}" if inside else 'none')
    w.check(f'no visible room cell showed a slot the menu wrote ({frames} frames sampled)',
            not damage, f"slots {sorted(hex(s) for s in damage)[:8]}")
    kinds = sorted({x[4] for x in wins})
    w.check(f'inside the windows every cell palette 7 / VRAM bank 0, outside them every room '
            f'cell its own attribute ({wframes} frames)', not wins,
            f"{len(wins)} cell-frames ({', '.join(kinds)}), e.g. "
            f"{[(r, c, hex(t), hex(at), k) for r, c, t, at, k in wins[:4]]}")
    after = bytes(m[0, 0x9000:0x97FF]) + bytes([m[0, 0x97FF]])
    back = [s for s in range(128) if s not in anim and after[s * 16:s * 16 + 16] != before[s * 16:s * 16 + 16]]
    w.check('after the close every room slot holds its tile again (VRAM bank 0)', not back,
            f'{len(back)} differ: {[hex(s) for s in back[:8]]}')

    # 3. on to a neighbouring screen by the scroll (no reload), when a way exists
    scrolled = False
    for d, dk in (('left', -1), ('right', 1), ('up', -4), ('down', 4)):
        nk = key + dk
        if str(nk) not in room['screens'] or (d in ('left', 'right') and nk // 4 != key // 4):
            continue
        maps0 = m[MAP_ID]
        w.p.button_press(d)
        for _ in range(240):
            adv(w.p, 1)
            if m[SCREEN_IDX] == nk:
                break
        w.p.button_release(d)
        adv(w.p, 60)
        if m[SCREEN_IDX] == nk and m[MAP_ID] == maps0:
            now = bytes(m[0, 0x9000:0x97FF]) + bytes([m[0, 0x97FF]])
            n = kept_cells(m, kept)
            same = [s for s in range(128) if s not in anim and now[s * 16:s * 16 + 16] != before[s * 16:s * 16 + 16]]
            w.check(f'scrolled to screen {nk} (no reload): its {len(n)} cells in kept slots show '
                    'their own tiles', not same, f'{len(same)} slots differ')
            scrolled = True
            break
    if not scrolled:
        print('  (no scroll from this cell to a neighbouring screen within 4 s — the VRAM check '
              'above is the proof)')
    print(f"\n{w.checks - w.fails} / {w.checks} checks passed" + ('  (NEGATIVE CONTROL)' if args.negative else ''))
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
