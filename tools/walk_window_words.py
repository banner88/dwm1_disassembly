#!/usr/bin/env python3
"""walk_window_words.py — S165 (ROADMAP Phase F T-follow (a)): the edited WINDOW WORDS on screen.

A project with `gamedata.window_words` (editor2/core/window_words.py) is built; this walk boots
it with a real save in PyBoy and reads what the screen SHOWS — the BG map cells ($9800+) and the
VRAM tile behind each cell, compared bitmap for bitmap with the screen font's reference tiles
(tools/census_window_layouts.py) — at:

  title   the title menu (bank $15 WinLayout_15_647D): the edited word, the text font;
  menu    the field menu (bank $07 WinLayout_07_704D);
  info    the INFO page (WinLayout_07_70F7) and the WHO list's header beside it (_70AD);
  optn    OPTN (WinLayout_07_7A61);
  frame   every window frame around an edited word unchanged (the same cells as the original
          stream on both sides of the word);
and every other word of those windows unchanged.

--negative: the same checks against the ORIGINAL words' build (--build of a project without the
edits, e.g. the example project): the edited words must NOT be found (FAIL expected).

    python3 tools/walk_window_words.py --build <built project dir/build> --project <its dir>
        --sav <a real .sav> [--keep DIR] [--negative --expect <the edited project dir>]

S166 (--services, ROADMAP T-follow (a) rest / (b)): a build of examples/s166_glossary_demo — the
GLOSSARY HALL's services toured as tools/census_window_layouts.py --services does (the shop, the
Vault, the farm, Grandpa, the egg appraiser, a battle with the join and the full party); at every
draw of a window that holds an edited word (gamedata.window_words, and the text slots "T:…" whose
row gamedata.text rewrote) the screen's cells there are read by their 8 x 8 SHAPE (the original
ROM's text font, bank $4F): the edited word must show, every other word of the window unchanged.

    python3 tools/walk_window_words.py --services --build <demo build> --project <demo dir>
        --sav <a real .sav> [--negative --expect <the edited demo dir>] [--hall 0x77]
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.census_window_layouts import FONTS, tile_bitmap        # noqa: E402
from editor2.core import window_words as WW                        # noqa: E402

TITLE, MENU, INFO, OPTN = (0x15, 0x647D), (0x07, 0x704D), (0x07, 0x70F7), (0x07, 0x7A61)
WHO = (0x07, 0x70AD)                     # the WHO list's header (INFO)


class Checks:
    def __init__(self):
        self.n = self.bad = 0

    def __call__(self, what, ok, detail=''):
        self.n += 1
        self.bad += not ok
        print(f"  {'ok  ' if ok else 'FAIL'} {what}" + (f'  [{detail}]' if detail else ''))


def screen_text(m, font, ref, row, col, n):
    """What the BG map shows at (row, col), n cells: a cell is a letter when the tile behind it
    equals the font's reference bitmap for that letter (else '?'); the blank tile -> ' '."""
    out = ''
    fm = FONTS[font]
    for c in range(n):
        t = m[0, 0x9800 + 32 * row + col + c]
        if t == 0xE0:
            out += ' '
            continue
        ch = fm.get(t)
        out += ch if ch and tile_bitmap(m, t) in ref[font].get(ch, ()) else '?'
    return out


def services(a):
    """S166: the GLOSSARY HALL tour; the edited words read on screen by shape."""
    import tools.census_window_layouts as CW
    from editor2.core.document import Document
    want_prj = a.expect if a.negative else a.project
    doc = Document(os.path.join(want_prj, 'project.json'))
    edits = doc.window_words()                     # tile words + the text slots' words
    gd = (doc.data.get('gamedata') or {})
    slots = WW.slots(REPO)
    cen = WW.census(REPO)
    if not edits:
        sys.exit('the project changes no window word')
    if a.negative:
        print("NEGATIVE CONTROL: the original words' build, the edited words expected")
    edits = {k: v for k, v in edits.items() if k in slots}
    layouts = {}
    for k, s_ in slots.items():
        if s_['kind'] == 'tile' and s_['bank'] in (0x07, 0x15):
            continue                               # the S165 walk reads these
        layouts.setdefault((s_['bank'], s_['addr']), []).append(k)
    ck = Checks()
    seen = {}                                      # slot -> [what was read each draw]
    rom0 = open(CW.ROM, 'rb').read()
    shp = CW.glyph_shapes(rom0)

    def visible(p, m):
        """Both tile maps, 32 x 32 each ($9800 then $9C00): the battle draws its menus into the
        map the WINDOW layer shows (LCDC bit 6), the field into the BG's — a window's cells are
        found wherever the game put them (the screenshots are kept: --keep)."""
        return [[m[0, base + 32 * r + c] for c in range(32)]
                for base in (0x9800, 0x9C00) for r in range(32)]

    def read(p, m, t):
        lc = m[0xFF40]
        ad = CW._tile_addr(lc, t)
        v0 = bytes(p.memory[0, 0x8000 + ad:0x8000 + ad + 16])
        sh = CW.shape(v0)
        return ' ' if t == WW.BLANK or not any(sh) else shp.get(sh, '?')

    dtab = json.load(open(os.path.join(REPO, 'extracted', 'dialogue.json')))['tables']
    tabs = {(int(t['bank'][1:], 16), int(t['table'][1:], 16)): t['source'] for t in dtab}

    def canvas_of(p, m, canv, t):
        """(source, row) of the text canvas the tile shows now (the latest whose captured bytes
        the tile still holds), else None."""
        lc = m[0xFF40]
        ad = CW._tile_addr(lc, t)
        for _i, ev, tiles, vb in reversed(canv):
            if t in tiles:
                b0 = tiles[t][1 + vb]
                if bytes(p.memory[vb, 0x8000 + ad:0x8000 + ad + 16]) == b0:
                    tb = CW.table_of(rom0, ev[1], ev[7], ev[2])
                    return tabs.get((ev[1], tb)), ev[3]
        return None

    def find(grid, cells):
        """(row, col) of `cells` in a map row — the row read around its end (a window that
        starts near column 31 continues at column 0: the map wraps)."""
        for r, row in enumerate(grid):
            rr = row + row[:len(cells)]
            for c in range(len(row)):
                if rr[c:c + len(cells)] == cells:
                    return r, c
        return None

    def rec(p, m, e, canv, draws=None, rom_=None, shapes=None, lays=None):
        lay = (e[1], e[2])
        if lay not in layouts:
            return
        grid = visible(p, m)
        want_rows = WW.rows_of(gd.get('window_words') and gd or {}, *lay, REPO)
        L = cen['layouts'][f'{lay[0]:02X}:{lay[1]:04X}']
        orig_rows = [list(bytes.fromhex(r)) for r in L['rows']]
        for k in layouts[lay]:
            s_ = slots[k]
            r, c, n = s_['row'], s_['col'], s_['len']
            row = want_rows[r] if s_['kind'] == 'tile' else orig_rows[r]
            # the word's cells and the cell after it (the cell before may hold the cursor)
            cells = row[c:c + n + 1]
            at = find(grid, cells)
            if at is None:
                continue
            rr, cc = at
            if s_['kind'] == 'text' and canvas_of(p, m, canv, row[c]) != (s_['source'], s_['index']):
                continue                       # the window shows another text's cells now
            g = grid[rr] + grid[rr]
            seen.setdefault(k, []).append(''.join(read(p, m, t) for t in g[cc:cc + n]))
    CW._record = rec
    CW._late = rec
    CW.measure_services(a.build, a.sav, a.keep, a.hall)
    for k in sorted(slots):
        if (slots[k]['bank'], slots[k]['addr']) not in layouts:
            continue
        s_ = slots[k]
        want = (edits.get(k) or s_['text']).ljust(s_['len'])
        got = seen.get(k)
        what = f"{s_['screen'] or k}: \"{s_['text']}\"" + (f' -> "{edits[k]}"' if k in edits else
                                                          ' unchanged')
        if not got:
            if k in edits:
                ck(what + ' — drawn on the tour', False, 'the window was not seen')
            continue
        ck(what + ' (read on screen by shape)', want in got, f'shown {sorted(set(got))[:3]}')
    print(f'{ck.n} checks, {ck.bad} failed' + (' (NEGATIVE: failures expected)' if a.negative else ''))
    return 1 if ck.bad else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', default='/tmp/walk_window_words')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--expect', help='--negative: the project whose words are expected')
    ap.add_argument('--services', action='store_true', help='S166: the GLOSSARY HALL tour')
    ap.add_argument('--hall', type=lambda x: int(x, 0), default=0x77)
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    if a.services:
        return services(a)
    from tools.walk_regions import Walk
    from tools.pyboy_harness import tap, GAME_MODE
    want_prj = a.expect if a.negative else a.project
    gd = json.load(open(os.path.join(want_prj, 'project.json'))).get('gamedata', {})
    edits = gd.get('window_words', {})
    if not edits:
        sys.exit('the project has no gamedata.window_words')
    slots = WW.slots(REPO)
    w = Walk(a.build, a.sav, a.keep)
    w.start()
    p, m = w.p, w.m
    if a.negative:
        print('NEGATIVE CONTROL: the original words\' build, the edited words expected')
    log = []
    dr = {0x07: [0x68DC], 0x15: [0x5D8F]}
    for b, es in dr.items():
        for e in es:
            p.hook_register(b, e, lambda _c, b=b: log.append((b, p.register_file.D << 8 |
                                                              p.register_file.E)), None)

    def adv(n):
        for _ in range(n):
            p.tick()

    def press(k, n=40):
        tap(p, k, hold=6)
        adv(n)
    ck = Checks()
    shots = {}
    ref = {'field': {}, 'text': {}}

    def look(key, frames=60):
        adv(frames)
        shots[key] = {(r, c): m[0, 0x9800 + 32 * r + c] for r in range(18) for c in range(32)}
        p.screen.image.save(os.path.join(a.keep, f'{key}.png'))
        return 'text' if key == 'title' else 'field'

    def visible():
        """The 18 x 20 cells on screen: the BG map ($9800 / $9C00 by LCDC bit 3) seen through
        SCX / SCY (the windows are drawn into the BG; the INFO page scrolls it)."""
        base = 0x9C00 if m[0xFF40] & 0x08 else 0x9800
        sx, sy = m[0xFF43] // 8, m[0xFF42] // 8
        return [[m[0, base + 32 * ((sy + r) % 32) + (sx + c) % 32] for c in range(20)]
                for r in range(18)]

    def find(grid, cells):
        for r, row in enumerate(grid):
            for c in range(len(row) - len(cells) + 1):
                if row[c:c + len(cells)] == cells:
                    return r, c
        return None

    def check_layout(key, lay):
        b, ad = lay
        L = WW.census(REPO)['layouts'][f'{b:02X}:{ad:04X}']
        font = 'text' if b == 0x15 else 'field'
        ck(f'{key}: the stream ${b:02X}:{ad:04X} was drawn', lay in log)
        want_rows = WW.rows_of(gd, b, ad, REPO)
        orig_rows = [list(bytes.fromhex(r)) for r in L['rows']]
        grid = visible()
        for k, s_ in sorted(slots.items()):
            if not k.startswith(f'{b:02X}:{ad:04X}/'):
                continue
            r, c, n = s_['row'], s_['col'], s_['len']
            # the word with the stream's cell before it (the frame / the blank the cursor uses)
            new = want_rows[r][c - 1:c + n]
            old = orig_rows[r][c - 1:c + n]
            at = find(grid, new[1:])
            txt = edits.get(k)
            if txt is None:
                ck(f'{key}: "{s_["text"]}" unchanged on screen', at is not None)
                continue
            if at is None:
                ck(f'{key}: "{s_["text"]}" -> "{txt}" shown', False, 'the cells are not on screen')
                continue
            rr, cc = at
            base = 0x9C00 if m[0xFF40] & 0x08 else 0x9800
            got = ''
            for j in range(n):
                t = grid[rr][cc + j]
                ch = FONTS[font].get(t)
                got += ' ' if t == 0xE0 else (ch if ch and tile_bitmap(m, t) in ref[font].get(ch, ())
                                              else '?')
            ck(f'{key}: "{s_["text"]}" -> "{txt}" shown (read through the font\'s measured tiles)',
               got == txt.ljust(n), f'shown "{got}"')
            ck(f'{key}: the original "{s_["text"]}" is gone', find(grid, old[1:]) is None or
               old == new)

    # reference bitmaps: the census's (extracted/window_layouts.json 'glyphs': the font tiles as
    # the original build's field menu / title menu hold them) — an edited cell is read through them
    glyphs = WW.census(REPO).get('glyphs') or {}

    def fill_ref(font):
        # the census's measured font tiles (the ORIGINAL build's screens): not this build's own
        for ch, bms in (glyphs.get(font) or {}).items():
            ref[font][ch] = {bytes.fromhex(x) for x in bms}

    adv(300)
    for _try in range(12):                       # the title: START until its menu is drawn
        press('start', 60)
        if TITLE in log:
            break
    adv(60)
    fill_ref('text')
    look('title')
    check_layout('title', TITLE)
    press('a', 120)
    press('a', 200)
    press('a', 60)
    for i in range(400):
        adv(10)
        if m[GAME_MODE] == 1 and not m[0xC8EB] & 1 and m[0xC96C] == 0:
            break
        if i % 3 == 0:
            tap(p, 'a')
    for _ in range(4):
        press('b', 20)
    adv(60)

    def open_menu():
        for _try in range(6):
            n0 = len(log)
            press('a', 10)
            for _f in range(150):
                adv(1)
                if MENU in log[n0:]:
                    adv(40)
                    return True
            press('b', 60)
        return False

    def close():
        for _ in range(8):
            press('b', 50)
        adv(120)
    ck('the field menu opened', open_menu())
    fill_ref('field')
    look('menu')
    check_layout('menu', MENU)
    press('a', 70)                     # INFO -> the WHO list: the cursor's monster's INFO page
    look('info', 30)                   #   (page 1: the stats) is drawn beside it (measured S165)
    check_layout('info', INFO)
    check_layout('who', WHO)
    close()
    ck('the field menu opened again', open_menu())
    press('down', 70)
    press('right', 70)
    press('a', 70)
    look('optn')
    check_layout('optn', OPTN)
    close()
    print(f'{ck.n} checks, {ck.bad} failed' + (' (NEGATIVE: failures expected)' if a.negative else ''))
    return 1 if ck.bad else 0


if __name__ == '__main__':
    sys.exit(main())
