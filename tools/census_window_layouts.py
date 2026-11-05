#!/usr/bin/env python3
"""census_window_layouts.py — the game's WINDOW LAYOUT streams: every window frame and the
words drawn inside it as TILES (S165, ROADMAP Phase F T-follow (a); TEXT_SYSTEM "Window words
(S165)", DATA_STRUCTURES "Window layout streams (S165)").

The words of the field menu (INFO ITEM / SKIL OPTN), the INFO page (ATK / DEF / AGL / INT / WLD,
HP: / MP:, MASTER:, NEXT LV), the ITEM / SKIL / OPTN windows, the title menu (CONTINUE / NEW
GAME …) are not texts: no SaveBankAndSwitch call draws them (S150). They are cells of a window
LAYOUT STREAM drawn by a small routine of which the game keeps 8 copies, two per bank (banks
$07 $09 $0A $12 $15 $18 $50 $51):

    stream = dw <position>          ; cell offset in the 32-wide map (row * 32 + column)
             db <cell>, …           ; a tile number each, written left to right
             db $D8                 ; NEWLINE: back to the row start, one row down
             …
             db $D9                 ; END
    drawer = ld de, <stream> / call <drawer>      (the entry reads the position word, turns it
             into a map address (entry A: the VRAM BG map $9800+, wrapping at row 32 — `and $03
             / or $98`; entry B: the WRAM screen buffer $C500+), then the cell loop)

A cell is a TILE NUMBER, not a text glyph: which letter it shows is whatever tile the screen has
loaded there. Measured (PyBoy, the example build + a real save): the field loads the FIELD FONT
(tiles $00-$0F A C D F H I K M N O R T U W J X, $11 B, $D4-$D6 Y E S, $DD-$DF G L V, $E1-$E3
H M P, $E4 ':', $E5 '/', $F0-$F9 0-9, $E0 blank; no Q, no Z, no lower case) — every bank $07
layout is drawn with it; the title menu (bank $15) shows the TEXT font (the text glyph numbers:
A = $24 … — TEXT_SYSTEM charmap). This tool:

  1. static: finds the 16 drawer entries (their byte pattern), every `ld de, <stream>` that
     reaches one (`call` / `jp` within 12 bytes), parses each stream, groups adjacent streams
     into RUNS (one stream's END is the next one's start);
  2. dynamic (--measure, PyBoy): tours the title menu and the field menus (INFO page, ITEM,
     SKIL, OPTN) with a hook on every drawer entry; at each draw the VRAM tile of every cell
     is compared, bitmap for bitmap, with the two fonts' reference tiles (taken from VRAM on
     the field menu and the title screen, where the decoded words are known) — the stream's
     FONT is the one every letter cell matches; the font's letters present in VRAM at that
     moment are the letters an edit may use;
  3. writes extracted/window_layouts.json: drawers, runs, layouts {bank, addr, pos, len,
     rows (cell bytes), refs (code sites), font (measured or null), words [{row, col, len,
     text}]}.

Used by editor2/core/window_words.py (the editable words: same length, the font's letters).

    python3 tools/census_window_layouts.py                       # static only
    python3 tools/census_window_layouts.py --measure --build <build dir> --sav <a real .sav>
"""
import argparse
import io
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
OUT = os.path.join(REPO, 'extracted', 'window_layouts.json')
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
BANKS = (0x07, 0x09, 0x0A, 0x12, 0x15, 0x18, 0x50, 0x51)
HEAD = bytes([0x1A, 0x6F, 0x13, 0x1A, 0x67, 0x13, 0xCD])      # ld a,[de] / ld l,a / inc de …
LOOP = bytes([0x1A, 0x13, 0xFE, 0xD9, 0xC8, 0xFE, 0xD8])       # ld a,[de] / inc de / cp $d9 …
NEWLINE, END, BLANK = 0xD8, 0xD9, 0xE0

# The two fonts (tile number -> character). FIELD measured S165 (the field menu's VRAM; every
# bank $07 word decodes to English with it — INFO, ATK, MASTER, JOURNAL, CAUTIOUS …).
FIELD = {0x00: 'A', 0x01: 'C', 0x02: 'D', 0x03: 'F', 0x04: 'H', 0x05: 'I', 0x06: 'K', 0x07: 'M',
         0x08: 'N', 0x09: 'O', 0x0A: 'R', 0x0B: 'T', 0x0C: 'U', 0x0D: 'W', 0x0E: 'J', 0x0F: 'X',
         0x11: 'B', 0xD4: 'Y', 0xD5: 'E', 0xD6: 'S', 0xDD: 'G', 0xDE: 'L', 0xDF: 'V',
         0xE1: 'H', 0xE2: 'M', 0xE3: 'P', 0xE4: ':', 0xE5: '/'}
FIELD.update({0xF0 + d: str(d) for d in range(10)})
TEXT = {d: str(d) for d in range(10)}
TEXT.update({0x24 + i: chr(0x41 + i) for i in range(26)})
TEXT.update({0x3E + i: chr(0x61 + i) for i in range(26)})
FONTS = {'field': FIELD, 'text': TEXT}


def bank_bytes(rom, b):
    return rom[b * 0x4000:(b + 1) * 0x4000]


def drawers(rom):
    """{bank: [(entry, kind)]}: kind 'vram' (A: the BG map, wraps at row 32) / 'buffer' (B)."""
    out = {}
    for b in BANKS:
        d = bank_bytes(rom, b)
        ents = []
        for m in re.finditer(re.escape(LOOP), d):
            k = d.rfind(HEAD, 0, m.start())
            if k < 0 or m.start() - k > 24:
                continue
            body = d[m.start():m.start() + 40]
            kind = 'vram' if bytes([0xE6, 0x03, 0xF6, 0x98]) in body else 'buffer'
            ents.append((0x4000 + k, kind))
        out[b] = ents
    return out


def parse(rom, b, a, maxlen=1024):
    o = b * 0x4000 + a - 0x4000
    pos = rom[o] | rom[o + 1] << 8
    if pos >= 0x400:
        return None
    i, rows = o + 2, [[]]
    while i < o + maxlen:
        x = rom[i]
        i += 1
        if x == END:
            return {'pos': pos, 'len': i - o, 'rows': rows}
        if x == NEWLINE:
            rows.append([])
        else:
            rows[-1].append(x)
    return None


def refs_of(rom, b, ents):
    d = bank_bytes(rom, b)
    targets = {e for e, _k in ents}
    refs = {}
    for i in range(0x4000 - 2):
        if d[i] in (0xCD, 0xC3) and (d[i + 1] | d[i + 2] << 8) in targets:
            for k in range(1, 12):
                if i - k >= 0 and d[i - k] == 0x11:
                    t = d[i - k + 1] | d[i - k + 2] << 8
                    refs.setdefault(t, []).append(0x4000 + i - k)
                    break
    return refs


def words(rows, font):
    """[{row, col, len, text}] — the words of a stream in `font` (editor2/core/window_words.py
    find_words: runs of 2+ letter / digit cells, one blank joins two words). `font` = the
    measured verdict: 'field' / 'text' (S165) or 'screen' with its own {char: tile} map (S166)."""
    from editor2.core.window_words import find_words
    if isinstance(font, dict) and font.get('font') == 'screen':
        fm = {int(t, 16): c for t, c in font['tiles'].items()}
    else:
        fm = FONTS[font['font'] if isinstance(font, dict) else font]
    return find_words([list(r) for r in rows], fm)


# runs whose streams are reached through tables, not `ld de, <stream>` (all streams, in order):
# bank $12's library / farm run (S26 / S27 `LibWinLayout_*`, DATA_STRUCTURES "Library / family-tab
# menu data (bank $12)") — S166
PACKED_RUNS = [(0x12, 0x710C, 0x7B9B)]


def static(rom):
    dr = drawers(rom)
    lays = {}
    for b, s0, e0 in PACKED_RUNS:
        a, refs = s0, refs_of(rom, b, dr[b])
        while a < e0:
            L = parse(rom, b, a)
            lays[(b, a)] = dict(L, bank=b, addr=a, refs=sorted(refs.get(a, [])))
            a += L['len']
    for b in BANKS:
        for a, sites in refs_of(rom, b, dr[b]).items():
            if a < 0x4000:
                continue                              # a ROM0 stream ($2E07: the blank box)
            L = parse(rom, b, a)
            if L is None:
                continue
            lays[(b, a)] = dict(L, bank=b, addr=a, refs=sorted(sites))
    runs = []
    for (b, a) in sorted(lays):
        L = lays[(b, a)]
        if runs and runs[-1]['bank'] == b and runs[-1]['end'] == a:
            runs[-1]['end'] = a + L['len']
            runs[-1]['layouts'].append(a)
        else:
            runs.append({'bank': b, 'start': a, 'end': a + L['len'], 'layouts': [a]})
    return dr, lays, runs


# ------------------------------------------------------------------ the measured tour
def tile_bitmap(m, t):
    """16 bytes of VRAM bank 0 tile `t` in the BG's signed addressing ($9000 + 16 t, $8800 +)."""
    a = 0x9000 + 16 * t if t < 0x80 else 0x8800 + 16 * (t - 0x80)
    return bytes(m[0, a + i] for i in range(16))


def measure(build, sav, lays, keep):
    """Tour the title + field menus; per drawn layout the font every letter cell matches."""
    from tools.walk_regions import Walk
    from tools.pyboy_harness import tap, GAME_MODE
    w = Walk(build, sav, keep)
    w.start()
    p, m = w.p, w.m
    dr = drawers(open(w.rom, 'rb').read())
    log = []

    def hook(b, e):
        def cb(_c):
            log.append((b, p.register_file.D << 8 | p.register_file.E, p.frame_count))
        return cb
    for b, ents in dr.items():
        for e, _k in ents:
            p.hook_register(b, e, hook(b, e), None)
    snaps = {}          # (bank, addr) -> {tile: bitmap} a few frames after the draw

    def adv(n):
        for _ in range(n):
            p.tick()
            for (b, a, f) in list(log):
                if (b, a) not in snaps and p.frame_count >= f + 2:
                    snaps[(b, a)] = {t: tile_bitmap(m, t) for t in range(256)}

    def press(k, n=40):
        tap(p, k, hold=6)
        adv(n)
    adv(400)                                    # the title (S100 recipe: title, CONTINUE)
    press('start', 120)
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
    # the field menu: INFO (-> WHO -> the INFO page), ITEM, SKIL, OPTN
    # one walk per menu entry from the field: START, the cursor keys, A's, then B until the
    # field is back (the menu's open / close animations eat a key pressed too early)
    tours = [('INFO', ['a', 'a', 'a']), ('ITEM', ['right', 'a', 'a']),
             ('SKIL', ['down', 'a', 'a', 'a']), ('OPTN', ['down', 'right', 'a', 'down', 'a']),
             ('OPTN2', ['down', 'right', 'a', 'down', 'down', 'a']),
             ('OPTN3', ['down', 'right', 'a', 'down', 'down', 'down', 'a'])]
    shot = 0

    def open_menu():
        # A (on the field, facing nothing: measured — START does not open it) until the field
        # menu's window (bank $07 $704D) is drawn; a key pressed while the previous menu still
        # closes is ignored
        for _try in range(6):
            n0 = len(log)
            press('a', 10)
            for _f in range(150):
                adv(1)
                if any((b, a) == (0x07, 0x704D) for b, a, _x in log[n0:]):
                    adv(40)
                    return True
            press('b', 60)
        return False
    for name, keys in tours:
        if not open_menu():
            print(f'  the field menu did not open for {name}')
            continue
        for k in keys:
            press(k, 70)
            if os.environ.get('WL_DEBUG'):
                p.screen.image.save(os.path.join(keep, f'tour{shot:02d}_{name}_{k}.png'))
                shot += 1
        for _ in range(8):
            press('b', 50)
        adv(120)
    for b, ents in dr.items():
        for e, _k in ents:
            p.hook_deregister(b, e)
    # reference bitmaps: the field font from a bank $07 draw (the menu), the text font from the
    # title menu (bank $15 $647D) — their words are known
    ref = {'field': {}, 'text': {}}
    for (b, a), tiles in snaps.items():
        font = 'field' if b == 0x07 else 'text' if (b, a) == (0x15, 0x647D) else None
        if font:
            for t, ch in FONTS[font].items():
                ref[font].setdefault(ch, set()).add(tiles[t])
    res = {}
    for (b, a), tiles in snaps.items():
        L = lays.get((b, a))
        if not L:
            continue
        cells = {x for row in L['rows'] for x in row}
        verdict = None
        for font in ('field', 'text'):
            fm = FONTS[font]
            letters = [x for x in cells if x in fm and fm[x].isalnum()]
            if letters and all(tiles[x] in ref[font].get(fm[x], ()) for x in letters):
                avail = sorted({fm[t] for t in fm if fm[t].isalnum()
                                and tiles[t] in ref[font].get(fm[t], ())})
                verdict = {'font': font, 'letters': ''.join(avail), 'cells': len(letters)}
                break
        res[(b, a)] = verdict
    glyphs = {f: {ch: sorted(x.hex() for x in v) for ch, v in sorted(d.items())}
              for f, d in ref.items()}
    return res, sorted(set((b, a) for b, a, _f in log)), glyphs


# ------------------------------------------------------------------ S166: the other screens
# (ROADMAP Phase F T-follow (a) rest + (b) + (c)): every service screen, the battle and the field
# ITEM page toured in a build of examples/s166_glossary_demo (THE GLOSSARY HALL — one NPC of each
# service kind) on a real save. Per drawn window: which cells show a letter of a TEXT CANVAS (a text
# the engine rendered into tiles — `ld hl, <tile address> / ld de, <rows, cols>`, [$C827] / [$C829]
# / [$C82A], measured at CallTextEngine $05B6) and which show a STATIC letter tile (a sheet the
# screen loaded); a letter = the tile's 8 x 8 SHAPE equal to a text-font glyph (bank $4F) — the
# same typeface on every screen, at screen-specific tile numbers.

GLYPH_BANK, GLYPH_BASE = 0x4F, 0x4010


def shape(t16):
    """The 64 pixels of a 2bpp tile as 1 (not the tile's most common colour) / 0."""
    px = []
    for r in range(8):
        lo, hi = t16[2 * r], t16[2 * r + 1]
        px += [((lo >> (7 - i)) & 1) | (((hi >> (7 - i)) & 1) << 1) for i in range(8)]
    bg = max(set(px), key=px.count)
    return tuple(1 if x != bg else 0 for x in px)


def glyph_shapes(rom):
    """{shape: char} of the text font's letters, digits and the window punctuation."""
    out = {}
    chars = {d: str(d) for d in range(10)}
    chars.update({0x24 + i: chr(0x41 + i) for i in range(26)})
    chars.update({0x3E + i: chr(0x61 + i) for i in range(26)})
    for c, ch in chars.items():
        o = GLYPH_BANK * 0x4000 + (GLYPH_BASE - 0x4000) + 16 * c
        s = shape(rom[o:o + 16])
        if sum(s):
            out.setdefault(s, ch)
    return out


def _tile_addr(lcdc, t):
    return 16 * t if lcdc & 0x10 else (0x1000 + 16 * t if t < 0x80 else 0x0800 + 16 * (t - 0x80))


def _canvas_tile(dest):
    """The BG tile number of a text canvas address ($8800-$97FF, the signed addressing every menu
    screen uses — LCDC $E3, measured), else None."""
    if 0x9000 <= dest < 0x9800:
        return (dest - 0x9000) // 16
    if 0x8800 <= dest < 0x9000:
        return 0x80 + (dest - 0x8800) // 16
    return None


def _vram(p, bank):
    return bytes(p.memory[bank, 0x8000:0x9FFF]) + bytes([p.memory[bank, 0x9FFF]])


def table_of(rom, bank, de, mode):
    """The text TABLE a CallTextEngine call reads: the bank's mode list (DE) + 2 · mode."""
    if bank >= 0x80 or not (0x4000 <= de < 0x8000):
        return None
    o = bank * 0x4000 + de - 0x4000 + 2 * mode
    return rom[o] | rom[o + 1] << 8


# the services of the hall: (kind, path from the hall's arrival (4, 5), face, [key sequences]);
# a key = (button, frames after) — a sequence starts from the hall each time (save state)
_A, _B, _D, _U, _R, _L = ('a', 90), ('b', 60), ('down', 30), ('up', 30), ('right', 30), ('left', 30)
SERVICE_TOUR = [
    ('shop', ['right'], 'down', [[_A, _A, _A, _A, _D, _A, _B, _B, _D, _A, _A, _A, _A] + [_B] * 6]),
    ('vault', ['up', 'right', 'right', 'right'], 'up',
     [[_A] * 5 + [_B, _B, _D, _A, _A, _A, _B, _B, _R, _A, _A, _A] + [_B] * 8,
      [_A, _A, _D, _A, _A, _A, _B, _D, _A, _A, _A] + [_B] * 8]),
    ('farm', ['up'] + ['right'] * 8 + ['up'], 'up',
     [[_A] * 6 + [_B, _B, _D, _A, _A, _A, _B, _B, _D, _A, _A, _A, _B, _B, _D, _A, _A, _A] + [_B] * 8]),
    ('library', ['up'] + ['right'] * 11 + ['down'], 'down',
     [[_A] * 7 + [_B, _D, _A, _A, _B, _R, _A, _A] + [_B] * 8]),
    ('namer', ['up'] + ['right'] * 13, 'up', [[_A] * 8 + [_B] * 9]),
    ('eggs', ['up'] + ['right'] * 21 + ['down'], 'down', [[_A] * 7 + [_B] * 7]),
    ('gates', ['up'] + ['right'] * 23, 'up', [[_A, _A, _A, _A, _D, _D, _A] + [_B] * 6]),
    ('grandpa', ['up'] + ['right'] * 28 + ['up'], 'up',
     [[_A] * 7 + [_B, _B, _D, _A, _A, _A, _A] + [_B] * 9,
      [_A, _A, _A, _A, _A, _A, _D, _A, _A, _A, _A, _A, _D, _A, _A] + [_B] * 9]),
    # the sparring slime (always joins): PLAN / the tactics / COMMAND, ITEM, FIGHT, the join,
    # the naming screen, the party-full choice (WHO, INFO / OK)
    # the sparring slime (always joins). 1: PLAN / the tactics, FIGHT, the join (YES), the naming
    # screen, the party-full choice (WHO, INFO / OK); 2: ITEM, PLAN, COMMAND (ATK / SKIL / DEF)
    ('battle', ['up'] + ['right'] * 31 + ['down'], 'down',
     [[('w', 60), ('down', 30), ('a', 60), ('down', 30), ('down', 30), ('down', 30), ('a', 60), ('a', 60), ('down', 30), ('a', 60), ('a', 60), ('b', 60), ('b', 60), ('b', 60), ('b', 60), ('b', 60), ('b', 60), ('up', 30), ('a', 60), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('down', 40), ('a', 90), ('a', 90), ('a', 90), ('down', 40), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90), ('a', 90)],
      [('w', 60), ('right', 30), ('a', 60), ('a', 60), ('a', 60), ('b', 60), ('b', 60), ('b', 60), ('left', 30), ('down', 30), ('a', 60), ('a', 60), ('a', 60), ('b', 60), ('down', 30), ('a', 60), ('a', 60), ('down', 30), ('a', 60), ('b', 60), ('b', 60), ('b', 60), ('b', 60), ('b', 60), ('a', 60), ('a', 60), ('down', 30), ('a', 60), ('a', 60), ('a', 60), ('a', 60), ('a', 60), ('a', 60), ('a', 60), ('a', 60), ('a', 60), ('a', 60), ('a', 60), ('a', 60), ('a', 60)]]),
    # the field menu's ITEM page (an item's description, its use line)
    ('item', [], 'down', [[('a', 60), ('right', 30)] + [('a', 80)] * 6 + [('b', 60)] * 6]),
]


def measure_services(build, sav, keep, hall):
    """Tour the GLOSSARY HALL's services (S166). -> {(bank, addr): [draw records]}, table widths
    {(bank, table): {(rows, cols)}}, the drawn set. A draw record = {cells: [[(tile, kind, info,
    char)]]} with kind 'canvas' (info = (bank, table, row, offset)) / 'static' / None, and the
    screen's static letters {char: [tiles]} at that moment."""
    from tools.walk_regions import Walk, s_continue
    rom0 = open(ROM, 'rb').read()
    shapes = glyph_shapes(rom0)
    w = Walk(build, sav, keep)
    s_continue(w)
    w.goto(hall, 0, 4, 5)
    w.save('glossary')
    dr = drawers(open(w.rom, 'rb').read())
    lays_static = static(rom0)[1]
    draws, widths, drawn = {}, {}, set()

    for kind, path, face, seqs in SERVICE_TOUR:
        for seq in seqs:
            w.start('glossary')
            p, m = w.p, w.m
            log, canv, vbk = [], [], []   # log: ('draw', b, a, f) / ('text', b, mode, id, dest, rows, cols, de, f)

            def hk(b):
                def cb(_c):
                    r = p.register_file
                    log.append(('draw', b, r.D << 8 | r.E, p.frame_count))
                return cb

            def tx(_c):
                r = p.register_file
                log.append(('text', m[0x4000], m[0xC822], m[0xC823], m[0xC827] | m[0xC828] << 8,
                            m[0xC829], m[0xC82A], r.D << 8 | r.E, p.frame_count))
                vbk.append(m[0xFF4F] & 1)      # the VRAM bank the engine writes the canvas to
            for b, ents in dr.items():
                for e, _k in ents:
                    p.hook_register(b, e, hk(b), None)
            p.hook_register(0, 0x05B6, tx, None)
            for d in path:
                w.step(d)
            w.face(face)
            done = [0]
            pend = []                 # (log index, kind) awaiting their snapshot
            late = []                 # (frame, draw) for _late (the walks: 30 frames after)

            def tick(n):
                # a text canvas is read 10 frames after its call (the engine draws over a few
                # frames) or at the next window draw, whichever comes first; a window 3 frames
                # after its draw
                for _ in range(n):
                    p.tick()
                    while done[0] < len(log):
                        pend.append(done[0])
                        done[0] += 1
                    keepp = []
                    for i in pend:
                        e = log[i]
                        if e[0] == 'text':
                            due = p.frame_count >= e[8] + 10 or any(
                                log[j][0] == 'draw' and p.frame_count >= log[j][3] + 3
                                for j in pend if j > i)
                            if not due:
                                keepp.append(i)
                                continue
                            t0 = _canvas_tile(e[4])
                            if t0 is not None and e[5] * e[6] <= 64:
                                v0, v1 = _vram(p, 0), _vram(p, 1)
                                lc = m[0xFF40]
                                tiles = {}
                                for o in range(e[5] * e[6]):
                                    t = (t0 + o) & 0xFF
                                    a = _tile_addr(lc, t)
                                    tiles[t] = (o, v0[a:a + 16], v1[a:a + 16])
                                k = sum(1 for x in log[:i] if x[0] == 'text')
                                canv.append((i, e, tiles, vbk[k] if k < len(vbk) else 0))
                            continue
                        if p.frame_count < e[3] + 3 or any(log[j][0] == 'text' for j in keepp):
                            keepp.append(i)
                            continue
                        _record(p, m, e, canv, draws, rom0, shapes, lays_static)
                        drawn.add((e[1], e[2]))
                        if _late is not None:
                            late.append((p.frame_count + 27, e))
                    pend[:] = keepp
                    while late and late[0][0] <= p.frame_count:
                        _late(p, m, late.pop(0)[1], canv)
            if kind == 'battle':
                _talk_yes(w, tick)
                tick(240)
            for j, (k, n) in enumerate(seq):
                if k == 'w':
                    tick(n)
                else:
                    p.button_press(k)
                    tick(6)
                    p.button_release(k)
                    tick(n)
                if os.environ.get('WL_DEBUG'):
                    p.screen.image.save(os.path.join(keep, f'svc_{kind}{seqs.index(seq)}_{j:02d}_{k}.png'))
            tick(10)
            for e in log:
                if e[0] == 'text' and _canvas_tile(e[4]) is not None and not (e[2] == 2 and e[3] == 0):
                    tb = table_of(rom0, e[1], e[7], e[2])
                    if tb is not None:
                        widths.setdefault((e[1], tb), set()).add((e[5], e[6]))
            print(f'  {kind}: {sum(1 for e in log if e[0] == "draw")} draws, '
                  f'{sum(1 for e in log if e[0] == "text")} texts')
    w.p.stop(save=False)
    return draws, widths, drawn


def _talk_yes(w, tick, maxf=3000):
    """A on the faced NPC, A while a box waits, YES to the question, until a battle starts."""
    m, p = w.m, w.p
    m[0xC83C] = 0
    p.button_press('a')
    tick(3)
    p.button_release('a')
    f, last = 0, [None, 0]
    while f < maxf:
        tick(2)
        f += 2
        if m[GAME_MODE_] == 2:
            return True
        if m[0xC83C] == 1:
            tick(20)
            for _ in range(6):
                if m[0xC83C] == 0:
                    break
                p.button_press('up')
                tick(6)
                p.button_release('up')
                tick(12)
            p.button_press('a')
            tick(3)
            p.button_release('a')
            tick(10)
            m[0xC83C] = 0
            continue
        ptr = m[0xC82D] | m[0xC82E] << 8
        if ptr != last[0]:
            last[0], last[1] = ptr, f
        elif f - last[1] >= 14:
            p.button_press('a')
            tick(2)
            p.button_release('a')
            last[1] = f
    return False


GAME_MODE_ = 0xC88A
# a walk's second look at every window, 30 frames after its draw (a window drawn into the screen
# buffer reaches the tile map a few frames later): _late(p, m, draw event, text canvases)
_late = None


def _record(p, m, e, canv, draws, rom0, shapes, lays):
    """One window draw, 3 frames later: every cell's tile read through the LCD's addressing."""
    b, a = e[1], e[2]
    L = lays.get((b, a))
    if not L:
        return
    lc = m[0xFF40]
    v0, v1 = _vram(p, 0), _vram(p, 1)
    # the canvas tiles still holding what their text drew
    live = {}
    for _i, ev, tiles, vb in canv:
        tb = table_of(rom0, ev[1], ev[7], ev[2])
        for t, (o, b0, b1) in tiles.items():
            ad = _tile_addr(lc, t)
            if (v1[ad:ad + 16] == b1) if vb else (v0[ad:ad + 16] == b0):
                live[t] = (ev[1], tb, ev[3], o, ev[2], ev[6])      # ev[6] = the canvas width
            else:
                live.pop(t, None)
    # the message window's canvases (2 x 18 at $8B00: the engine types them over many frames, so
    # their tiles never read as one fixed text) are no screen's letters
    msg = {t for _i, ev, tiles, _vb in canv if ev[5] >= 2 for t in tiles}
    statics = {}
    for t in range(256):
        if t in live or t in msg:
            continue
        ad = _tile_addr(lc, t)
        ch = shapes.get(shape(v0[ad:ad + 16]))
        if ch:
            statics.setdefault(ch, []).append(t)
    cells = []
    for row in L['rows']:
        rr = []
        for t in row:
            ad = _tile_addr(lc, t)
            ch = shapes.get(shape(v0[ad:ad + 16]))
            if t == BLANK:
                rr.append((t, None, None, None))
            elif t in live:
                rr.append((t, 'canvas', live[t], ch))
            elif ch and t not in msg:
                rr.append((t, 'static', None, ch))
            else:
                rr.append((t, None, None, None))
        cells.append(rr)
    draws.setdefault((b, a), []).append({'cells': cells, 'statics': statics})


def services_verdicts(draws, dialogue_tables):
    """Per layout: the screen font ({font: 'screen', letters, cells, map}) when every letter cell
    of every draw is static; the canvas words [{row, col, len, source, index, offset, text}]."""
    out = {}
    tabs = {(int(t['bank'][1:], 16), int(t['table'][1:], 16)): t['source'] for t in dialogue_tables}
    for (b, a), recs in draws.items():
        letters_ok = None
        font_map = {}
        stat_cells = canv_words = None
        n_static = 0
        all_static = True
        texts = []
        for rec in recs:
            for ri, row in enumerate(rec['cells']):
                for t, kind, info, ch in row:
                    if kind == 'static':
                        n_static += 1
                        font_map.setdefault(ch, t)
                    elif kind == 'canvas':
                        all_static = False
            # letters available in every draw: the static tiles reading the same letter
            av = {ch: set(ts) for ch, ts in rec['statics'].items()}
            letters_ok = av if letters_ok is None else {
                ch: letters_ok[ch] & av.get(ch, set()) for ch in letters_ok if letters_ok[ch] & av.get(ch, set())}
        verdict = {}
        if n_static and letters_ok:
            # map = the tile an edit writes for each letter (the one the window already uses, else
            # the lowest); tiles = every static letter tile of the screen (to read the words)
            mp = {}
            for ch, ts in sorted(letters_ok.items()):
                pref = font_map.get(ch)
                mp[ch] = pref if pref in ts else min(ts)
            verdict['font'] = {'font': 'screen', 'letters': ''.join(sorted(c for c in mp if c.isalnum())),
                               'cells': n_static, 'map': {c: f'{t:02X}' for c, t in sorted(mp.items())},
                               'tiles': {f'{t:02X}': c for c, ts in sorted(letters_ok.items())
                                         for t in sorted(ts)}}
        # canvas words: runs of consecutive offsets of one packed text (field / misc rows) in a row
        rec = recs[0]
        seen = set()
        for rec in recs:
            for ri, row in enumerate(rec['cells']):
                c = 0
                while c < len(row):
                    t, kind, info, ch = row[c]
                    if kind != 'canvas' or info[4] == 2 and info[2] == 0:
                        c += 1
                        continue
                    src = tabs.get((info[0], info[1]))
                    if src not in ('field_message', 'misc_message'):
                        c += 1
                        continue
                    e = c + 1
                    while (e < len(row) and row[e][1] == 'canvas' and row[e][2][:3] == info[:3]
                           and row[e][2][3] == info[3] + (e - c)):
                        e += 1
                    txt = ''.join(x[3] or ' ' for x in row[c:e]).rstrip()
                    key = (ri, c, src, info[2], info[3], e - c)
                    if key not in seen and sum(ch_.isalpha() for ch_ in txt) >= 2:
                        seen.add(key)
                        texts.append({'row': ri, 'col': c, 'len': e - c, 'source': src,
                                      'index': info[2], 'offset': info[3], 'text': txt,
                                      'canvas': info[5]})
                    c = e
        if texts:
            verdict['texts'] = texts
        out[(b, a)] = verdict
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--measure', action='store_true')
    ap.add_argument('--services', action='store_true',
                    help='S166: also tour the GLOSSARY HALL (--hall) — shops, Vault, farm, library, '
                         'namer, eggs, gate list, Grandpa, a battle, the ITEM page')
    ap.add_argument('--hall', type=lambda x: int(x, 0), default=0x77)
    ap.add_argument('--build')
    ap.add_argument('--sav')
    ap.add_argument('--keep', default='/tmp/census_window_layouts')
    ap.add_argument('--out', default=OUT)
    a = ap.parse_args()
    rom = open(ROM, 'rb').read()
    dr, lays, runs = static(rom)
    measured, drawn, glyphs = {}, [], None
    if a.measure:
        os.makedirs(a.keep, exist_ok=True)
        measured, drawn, glyphs = measure(a.build, a.sav, lays, a.keep)
    svc, widths, sdrawn = {}, {}, set()
    if a.services:
        os.makedirs(a.keep, exist_ok=True)
        dtab = json.load(open(os.path.join(REPO, 'extracted', 'dialogue.json')))['tables']
        draws, widths, sdrawn = measure_services(a.build, a.sav, a.keep, a.hall)
        svc = services_verdicts(draws, dtab)
    old = json.load(open(a.out)) if os.path.exists(a.out) else {}
    oldl = old.get('layouts', {})
    out_l = {}
    for (b, a_), L in sorted(lays.items()):
        key = f'{b:02X}:{a_:04X}'
        o = oldl.get(key, {})
        font = measured.get((b, a_)) if a.measure else o.get('font')
        if a.services:
            sv = svc.get((b, a_), {})
            if not font or (font.get('font') == 'screen'):
                font = sv.get('font')
            texts = sv.get('texts')
        else:
            texts = o.get('texts')
        was = set(drawn) if a.measure else ({(b, a_)} if o.get('drawn') else set())
        ent = {'bank': b, 'addr': a_, 'pos': L['pos'], 'len': L['len'],
               'refs': [f'${r:04X}' for r in L['refs']],
               'rows': [bytes(r).hex() for r in L['rows']],
               'font': font, 'drawn': (b, a_) in was or (b, a_) in sdrawn}
        if font:
            ent['words'] = words(L['rows'], font)
        if texts:
            ent['texts'] = texts
        out_l[key] = ent
    tw = old.get('text_widths', {})
    if a.services:
        dtab = json.load(open(os.path.join(REPO, 'extracted', 'dialogue.json')))['tables']
        tabs = {(int(t['bank'][1:], 16), int(t['table'][1:], 16)): t['source'] for t in dtab}
        tw = {}
        for (bk, tb), v in sorted(widths.items()):
            src = tabs.get((bk, tb))
            if src:
                tw.setdefault(src, sorted({tuple(x) for x in tw.get(src, [])} | v))
        tw = {k: [list(x) for x in v] for k, v in sorted(tw.items())}
    gen = 'tools/census_window_layouts.py (S165, S166) on data/DWM-original.gbc'
    if a.measure or a.services:
        gen += (f' + the PyBoy tour of {os.path.basename(os.path.normpath(os.path.dirname(a.build)))}'
                + (' (the title + field menus)' if a.measure else '')
                + (' (S166: the GLOSSARY HALL services, a battle, the ITEM page)' if a.services else ''))
    else:
        gen = old.get('_generator', gen)
    out = {'_generator': gen,
           'format': 'dw position (row*32+col); cells (tile numbers); $D8 newline; $D9 end',
           'fonts': {k: {f'{t:02X}': c for t, c in sorted(v.items())} for k, v in FONTS.items()},
           # the font tiles as the screens hold them (VRAM bank 0, 16 bytes each; measured on the
           # field menu and the title menu): the walks read an edited cell through these
           'glyphs': glyphs if a.measure else old.get('glyphs'),
           # S166: the text CANVASES each table is drawn into ([rows, cols]; measured, the
           # GLOSSARY HALL tour) — the Text tab's line widths (editor2/core/gametext.py)
           'text_widths': tw,
           'drawers': {f'{b:02X}': [{'entry': f'${e:04X}', 'kind': k} for e, k in v]
                       for b, v in dr.items()},
           'runs': [{'bank': r['bank'], 'start': f"${r['start']:04X}", 'end': f"${r['end']:04X}",
                     'layouts': len(r['layouts'])} for r in runs],
           'layouts': out_l}
    json.dump(out, open(a.out, 'w'), indent=1)
    n_meas = sum(1 for v in out_l.values() if v['font'])
    print(f"{sum(len(v) for v in dr.values())} drawer entries, {len(out_l)} layouts in "
          f"{len(runs)} runs, {n_meas} with a measured font -> {a.out}")
    for k, v in out_l.items():
        if v.get('words'):
            print(f"  {k} [{v['font']['font']}] " + ' / '.join(x['text'] for x in v['words']))
        for t in v.get('texts', []):
            print(f"  {k} text {t['source']} {t['index']} +{t['offset']} [{t['len']}] {t['text']}")
    for k, v in tw.items():
        print(f'  width {k}: {v}')


if __name__ == '__main__':
    main()
