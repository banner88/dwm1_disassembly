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
    find_words: runs of 2+ letter / digit cells, one blank joins two words)."""
    from editor2.core.window_words import find_words
    return find_words([list(r) for r in rows], FONTS[font])


def static(rom):
    dr = drawers(rom)
    lays = {}
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--measure', action='store_true')
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
    old = json.load(open(a.out)) if os.path.exists(a.out) and not a.measure else {}
    oldfont = {k: v.get('font') for k, v in old.get('layouts', {}).items()}
    out_l = {}
    for (b, a_), L in sorted(lays.items()):
        key = f'{b:02X}:{a_:04X}'
        mv = measured.get((b, a_))
        font = mv if a.measure else oldfont.get(key)
        ent = {'bank': b, 'addr': a_, 'pos': L['pos'], 'len': L['len'],
               'refs': [f'${r:04X}' for r in L['refs']],
               'rows': [bytes(r).hex() for r in L['rows']],
               'font': font, 'drawn': (b, a_) in set(drawn) if a.measure else
               old.get('layouts', {}).get(key, {}).get('drawn', False)}
        if font:
            ent['words'] = words(L['rows'], font['font'])
        out_l[key] = ent
    out = {'_generator': 'tools/census_window_layouts.py (S165) on data/DWM-original.gbc'
                         + (f' + the PyBoy tour of {os.path.basename(os.path.normpath(a.build))} '
                            '(the title + field menus)' if a.measure else ''),
           'format': 'dw position (row*32+col); cells (tile numbers); $D8 newline; $D9 end',
           'fonts': {k: {f'{t:02X}': c for t, c in sorted(v.items())} for k, v in FONTS.items()},
           # the font tiles as the screens hold them (VRAM bank 0, 16 bytes each; measured on the
           # field menu and the title menu): the walks read an edited cell through these
           'glyphs': glyphs if a.measure else old.get('glyphs'),
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


if __name__ == '__main__':
    main()
