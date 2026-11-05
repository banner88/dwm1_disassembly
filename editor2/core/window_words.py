"""window_words.py — S165 / S166: the words drawn in the game's WINDOWS, editable (ROADMAP Phase F
T-follow (a) / (b); TEXT_SYSTEM "Window words (S165)" / "Text canvases (S166)"; DATA_STRUCTURES "Window layout
streams (S165)"; PROJECT_COMPILER §2.73 / §2.74).

The field menu's INFO ITEM / SKIL OPTN, the INFO page's ATK / DEF / AGL / INT / WLD, HP / MP,
MASTER, NEXT LV, ITEM's USE / DEL, SKIL's USE MP, OPTN's TEXT SPD / CH ORDER / CH PLAN / JOURNAL,
the tactics CHARGE / MIXED / CAUTIOUS / COMMAND, the title menu's CONTINUE / NEW GAME / VS MODE /
BREEDING are not texts (the Text tab cannot reach them, S150): they are cells of WINDOW LAYOUT
STREAMS (`dw position`, a TILE number per cell, `$D8` newline, `$D9` end) drawn by
`WinLayoutDraw…`. A cell shows whatever tile the screen has loaded there, so a word can only use
the letters of its screen's FONT, measured in PyBoy (tools/census_window_layouts.py ->
extracted/window_layouts.json):

  * field  — the field menus (bank $07): A-Y without Q (and no Z), upper case, the digits, ':' '/'
             (the field keeps only these letters in VRAM; tile $E0 = a blank cell);
  * text   — the title menu (bank $15 $647D): the text font (A-Z, a-z, 0-9);
  * screen — S166: every other measured window (the shop, the Vault, the farm, the library's farm
             menus, the namer, the egg appraiser, Grandpa, the battle): the letter tiles THAT screen
             holds (read by their 8 x 8 shape, the text font's typeface at screen-specific tile
             numbers) — the census's `map` (letter -> the tile an edit writes) / `tiles` (every
             letter tile, to read the words).

S166 also: words a window shows from a TEXT the engine drew into tiles (a "canvas": `PUT TAKEEXIT`
→ the Vault's PUT / TAKE / EXIT, `ITEMGOLDEXIT`, Grandpa's EXIT from `EXIT INFO`, the party-full
WHO from `WHOSTROK`): the window cuts the text at fixed cells, so each word is a slot of the TEXT
(key "T:<table>:<row>/<offset>") — edited through gamedata.text (the composed row, the other
cells kept), any letter of the text font.

project.json:  gamedata.window_words = {"<bank>:<addr>/<row>/<col>": "NEW", …}
  — one entry per word slot (the census's words of a MEASURED stream); the new word is at most
  the slot's length (a shorter word is padded with blank cells; the window frame never moves);
  absent = the original. Each re-sectioned run is a compiler region
  (`win_words_<bank>_<start>` in patches/bank_0xx.asm) holding the run's streams as `db`, the same
  size whatever the words. The text slots live in gamedata.text (editor2/core/gametext.py).
"""
import json
import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CENSUS = os.path.join('extracted', 'window_layouts.json')
BLANK = 0xE0

# the re-sectioned runs (tools/resection_window_layouts.py RUNS): (bank, start, end) — every run of
# code-referenced streams the census found (S165: banks $07 / $15; S166: $09 $0A $12 $18 $50 $51)
RUNS = [(0x07, 0x704D, 0x7D98),
        (0x09, 0x6CDE, 0x6E45), (0x09, 0x6EB0, 0x705E), (0x09, 0x7153, 0x7216),
        (0x09, 0x74A0, 0x7544), (0x09, 0x7838, 0x7872), (0x09, 0x7CA5, 0x7CCB),
        (0x09, 0x7DC9, 0x7EC7),
        (0x0A, 0x6F3C, 0x6F61), (0x0A, 0x6F86, 0x6FA3), (0x0A, 0x70C5, 0x70EA),
        (0x0A, 0x7409, 0x7507), (0x0A, 0x75AB, 0x770B), (0x0A, 0x7731, 0x789F),
        (0x0A, 0x79BE, 0x7A1C),
        (0x12, 0x6DCB, 0x6DF0), (0x12, 0x6F54, 0x6F79), (0x12, 0x710C, 0x7B9B),
        (0x15, 0x647D, 0x64F4), (0x15, 0x6716, 0x694E),
        (0x18, 0x547A, 0x54F9), (0x18, 0x5523, 0x5577), (0x18, 0x55F7, 0x561D),
        (0x50, 0x6ED2, 0x7177), (0x50, 0x7213, 0x7238), (0x50, 0x74BA, 0x756B),
        (0x51, 0x6E78, 0x6F98), (0x51, 0x6FE2, 0x717F)]
# bank $12's library run keeps its S26 / S27 labels (LibWinLayout_<addr>, referenced by name)
LIB_RUN = (0x12, 0x710C, 0x7B9B)

# measured windows whose letters are NOT editable (S166): the naming keyboard (a grid of the
# letters the cursor types — the cells are the keyboard, not words), the eggs page's pedigree
# picture (its tiles $00-$0F hold the field font only for the frames before the picture loads),
# the battle's join / party-full windows (bank $51: their YES / NO / INFO / OK letters arrive in
# tiles $85-$8A / $9C-$9E between draws from a writer that is not the text engine — measured,
# not decoded; ROADMAP T-follow S166 note)
EXCLUDE = {'09:7DC9': 'the naming keyboard', '07:765B': 'the pedigree picture',
           '51:6EEF': 'the join question (letters of an undecoded writer)',
           '51:6F6E': 'the party-full INFO / OK (letters of an undecoded writer)',
           # the party-full WHO: misc_message 10 "WHOSTROK" IS drawn into tiles $82-$8B (measured,
           # the level-2 read at $094F) — then the same writer re-letters $83-$8A (an edited "Who"
           # shows "WHO"): not editable either
           '51:6F14': 'the party-full WHO (re-lettered by an undecoded writer)'}
WHAT = {
    (0x07, 0x704D): 'the field menu', (0x07, 0x7090): 'the gold box', (0x07, 0x70AD): 'INFO: who',
    (0x07, 0x70F7): 'the INFO page: stats', (0x07, 0x71AF): 'the INFO page: HP / MP',
    (0x07, 0x727B): 'the INFO page 2: name / family / master',
    (0x07, 0x7333): 'the INFO page 2: next level',
    (0x07, 0x755B): 'the egg page: the father', (0x07, 0x75DB): 'the egg page: the mother',
    (0x07, 0x7687): 'SKIL: who', (0x07, 0x78D9): 'SKIL: the MP box',
    (0x07, 0x798B): 'ITEM: the item window', (0x07, 0x7A61): 'OPTN', (0x07, 0x7C44): 'OPTN: yes / no',
    (0x07, 0x7C69): 'OPTN: CH PLAN (the tactics)', (0x07, 0x7BCA): 'OPTN: JOURNAL (the save box)',
    (0x09, 0x6CDE): 'the gate guide: the gate list', (0x09, 0x6EB0): 'the naming screen: yes / no',
    (0x09, 0x6EFA): 'the shop: yes / no', (0x09, 0x6F1F): 'the shop: the gold box',
    (0x09, 0x6F3C): 'the shop: BUY / SELL / EXIT', (0x09, 0x6F7D): 'the shop: the list',
    (0x09, 0x7033): 'the shop: how many', (0x09, 0x7044): 'the Vault: how many',
    (0x09, 0x7153): 'the Vault: the list', (0x09, 0x71CA): 'the Vault: the gold box',
    (0x09, 0x71E7): 'the Vault: ITEM / G', (0x09, 0x7838): 'the Vault: PUT / TAKE / EXIT',
    (0x09, 0x7CA5): 'the naming screen: the name', (0x09, 0x7DC9): 'the naming keyboard',
    (0x0A, 0x6F86): 'Grandpa / the eggs: the gold box', (0x0A, 0x7463): 'Grandpa: INFO / OK',
    (0x0A, 0x75AB): 'Grandpa: BREED / HATCH / EXIT', (0x0A, 0x75F3): 'Grandpa: who',
    (0x0A, 0x764D): 'Grandpa: the mate', (0x0A, 0x76A7): 'Grandpa: the pair',
    (0x0A, 0x77D7): 'the egg appraiser: EVAL / BLESS / EXIT', (0x0A, 0x781F): 'the egg appraiser: the eggs',
    (0x0A, 0x79ED): 'the egg appraiser: INFO / OK',
    (0x12, 0x6DCB): 'the Monster Namer: yes / no', (0x12, 0x710C): 'the farm menu',
    (0x12, 0x71AA): 'the farm: who', (0x12, 0x724E): 'the Monster Namer: who',
    (0x12, 0x759A): 'the farm: the monster', (0x12, 0x78D0): 'the library: the families',
    (0x12, 0x7935): 'the library: the monsters', (0x12, 0x7B42): 'the farm: INFO / OK',
    (0x15, 0x647D): 'the title menu',
    (0x50, 0x6ED2): 'the battle: FIGHT / ITEM / PLAN / RUN', (0x50, 0x6F49): 'the battle: who',
    (0x50, 0x6F60): 'the battle: the tactics', (0x50, 0x6FCE): 'the battle: the items',
    (0x50, 0x74BA): 'the battle: ATK / SKIL / DEF',
    (0x51, 0x6EEF): 'after the battle: yes / no', (0x51, 0x6F14): 'the party is full: who',
    (0x51, 0x6F6E): 'the party is full: INFO / OK',
}


def label(bank, addr):
    """The stream's label in both trees (bank $12's library run keeps its S26 / S27 names)."""
    b, s0, e0 = LIB_RUN
    if bank == b and s0 <= addr < e0:
        return f'LibWinLayout_{addr:04x}'
    return f'WinLayout_{bank:02X}_{addr:04X}'


class WindowWordsError(ValueError):
    pass


_CACHE = {}


def census(repo=None):
    repo = repo or REPO
    if repo not in _CACHE:
        _CACHE[repo] = json.load(open(os.path.join(repo, CENSUS)))
    return _CACHE[repo]


def fonts(repo=None):
    """{font: {tile: char}} of the named fonts (S165: field / text)"""
    return {k: {int(t, 16): c for t, c in v.items()} for k, v in census(repo)['fonts'].items()}


def layout_font(L, repo=None):
    """(decode {tile: char}, encode {char: tile}) of a measured layout, or None."""
    f = L.get('font')
    if not f:
        return None
    if f.get('font') == 'screen':
        dec = {int(t, 16): c for t, c in f['tiles'].items()}
        enc = {c: int(t, 16) for c, t in f['map'].items()}
        return dec, enc
    dec = fonts(repo)[f['font']]
    enc = {}
    for t, c in sorted(dec.items()):
        enc.setdefault(c, t)
    return dec, enc


def _in_runs(bank, addr):
    return any(b == bank and s <= addr < e for b, s, e in RUNS)


def slots(repo=None):
    """{key: {kind, bank, addr, row, col, len, text, font, letters, screen, …}} — every editable
    word. kind 'tile' (a measured stream inside a re-sectioned run; key "BB:AAAA/row/col") or
    'text' (S166: a word a window cuts out of a text; key "T:<source>:<row>/<offset>", with
    source / index / offset / canvas)."""
    out = {}
    texts = {}
    for k, L in census(repo)['layouts'].items():
        for t in L.get('texts', []):
            if k not in EXCLUDE:
                texts.setdefault((t['source'], t['index']), []).append(dict(t, layout=k))
        f = L.get('font')
        if not f or not _in_runs(L['bank'], L['addr']) or k in EXCLUDE:
            continue
        for w in L.get('words', []):
            key = f"{k}/{w['row']}/{w['col']}"
            out[key] = dict(kind='tile', bank=L['bank'], addr=L['addr'], row=w['row'],
                            col=w['col'], len=w['len'], text=w['text'], font=f['font'],
                            letters=f['letters'], screen=WHAT.get((L['bank'], L['addr']), ''))
    for (src, idx), ts in sorted(texts.items()):
        # one slot per distinct (offset, len); a slot two windows cut differently is skipped
        by_off = {}
        for t in ts:
            by_off.setdefault(t['offset'], []).append(t)
        spans = sorted((o, min(x['len'] for x in v), v) for o, v in by_off.items())
        for i, (o, n, v) in enumerate(spans):
            if i + 1 < len(spans) and o + n > spans[i + 1][0]:
                continue
            L = census(repo)['layouts'][v[0]['layout']]
            key = f'T:{src}:{idx}/{o}'
            out[key] = dict(kind='text', bank=L['bank'], addr=L['addr'], row=v[0]['row'],
                            col=v[0]['col'], len=n, text=v[0]['text'], font='text',
                            letters=TEXT_LETTERS, source=src, index=idx, offset=o,
                            canvas=max(x.get('canvas') or 0 for x in v),
                            screen=WHAT.get((L['bank'], L['addr']), ''))
    return out


TEXT_LETTERS = ''.join(chr(0x41 + i) for i in range(26)) + ''.join(chr(0x61 + i) for i in range(26)) \
    + '0123456789'


def text_word(markup, s):
    """The word a text slot shows in `markup` (the row as plain cells; the slot's cells, right
    spaces dropped)."""
    cells = _plain_cells(markup)
    return ''.join(cells[s['offset']:s['offset'] + s['len']]).rstrip(' ')


def _plain_cells(markup):
    """A packed row's cells — one character a cell; None when the row holds codes / tokens (then
    the slot cannot be composed: the Text tab edits it as a whole line)."""
    if any(c in markup for c in '{}\n▼‥'):
        raise WindowWordsError('this text holds codes — edit it on its Text sub-tab')
    return list(markup)


def compose_text(markup, s, word):
    """The row with `word` in the slot's cells (padded with spaces to the slot's length; the
    other cells kept, the row at least as long as it was). Refused: longer than the slot, a
    character the text font lacks, a row longer than the window's canvas."""
    if len(word) > s['len']:
        raise WindowWordsError(f'"{word}" is {len(word)} letters; the window has room for '
                               f'{s["len"]} ("{s["text"]}")')
    bad = sorted({c for c in word if c != ' ' and c not in s['letters']})
    if bad:
        raise WindowWordsError(f'"{"".join(bad)}" is not a letter of the text font '
                               '(A-Z, a-z, 0-9 and space)')
    cells = _plain_cells(markup)
    end = s['offset'] + s['len']
    if len(cells) < end:
        cells += [' '] * (end - len(cells))
    cells[s['offset']:end] = list(word.ljust(s['len']))
    out = ''.join(cells)
    n = len(out.rstrip(' '))
    keep = max(n, len(markup.rstrip(' ')), len(markup) if markup.startswith(' ') else 0)
    out = out[:max(keep, n)]
    if s.get('canvas') and len(out) > max(s['canvas'], len(markup)):
        raise WindowWordsError(f'the row would be {len(out)} cells; the window draws {s["canvas"]}')
    return out


def _words(gd):
    v = (gd or {}).get('window_words')
    return v if isinstance(v, dict) else {}


def validate(gd, errors, repo=None):
    v = (gd or {}).get('window_words')
    if v is None:
        return
    if not isinstance(v, dict):
        errors.append('gamedata.window_words: must be an object {"<bank>:<addr>/<row>/<col>": "WORD"}')
        return
    sl = slots(repo)
    for key, txt in v.items():
        s = sl.get(key)
        if s is not None and s['kind'] == 'text':
            errors.append(f'gamedata.window_words.{key}: a word of a text — it is stored in '
                          f'gamedata.text.{s["source"]} (the Text tab composes the row)')
            continue
        if s is None:
            errors.append(f'gamedata.window_words.{key}: not a word the editor knows '
                          f'(extracted/window_layouts.json, a measured window)')
            continue
        if not isinstance(txt, str):
            errors.append(f'gamedata.window_words.{key}: must be a string')
            continue
        if len(txt) > s['len']:
            errors.append(f'gamedata.window_words.{key}: "{txt}" is {len(txt)} letters; the window '
                          f'has room for {s["len"]} ("{s["text"]}")')
        bad = sorted({c for c in txt if c != ' ' and c not in s['letters']})
        if bad:
            errors.append(f'gamedata.window_words.{key}: "{"".join(bad)}" is not in this screen\'s '
                          f'font (it has {s["letters"]} and space)')


def find_words(rows, fm):
    """[{row, col, len, text}] — runs of 2+ cells that are letters / digits of the font map `fm`
    ({tile: char}); a blank cell ends a word — each word is its own slot (NEW / GAME, INFO /
    ITEM: a menu's cursor arrow is drawn on the blank cell before an entry, so a word never
    grows into it); a trailing ':' / '/' is not part of the word."""
    out = []
    for r, row in enumerate(rows):
        c = 0
        while c < len(row):
            if row[c] in fm and fm[row[c]].isalnum():
                e = c
                while e < len(row) and row[e] in fm and row[e] != BLANK:
                    e += 1
                txt = ''.join(fm.get(x, ' ') for x in row[c:e]).rstrip(' :/')
                if sum(ch.isalpha() for ch in txt) >= 2:
                    out.append({'row': r, 'col': c, 'len': len(txt), 'text': txt})
                c = e
            else:
                c += 1
    return out


def _encode(txt, enc):
    return [BLANK if c == ' ' else enc[c] for c in txt]


def rows_of(gd, bank, addr, repo=None):
    """The stream's rows (lists of cells) with the project's words in place."""
    L = census(repo)['layouts'][f'{bank:02X}:{addr:04X}']
    rows = [list(bytes.fromhex(r)) for r in L['rows']]
    sl = None
    for key, txt in _words(gd).items():
        b_a, r, c = key.split('/')
        if b_a != f'{bank:02X}:{addr:04X}':
            continue
        sl = sl or slots(repo)
        s = sl[key]
        cells = _encode(txt.ljust(s['len']), layout_font(L, repo)[1])
        r, c = int(r), int(c)
        rows[r][c:c + s['len']] = cells
    return rows


def _fmt(bs):
    return ', '.join(f'${b:02x}' for b in bs)


def stream_lines(pos, rows, fm):
    """The `dw` / `db` lines of one stream (tools/resection_window_layouts.py writes the same);
    fm = {tile: char} to comment the rows with (empty: no comment)."""
    fm = fm or {}
    out = [f'    dw ${pos:04x}                 ; position: row {pos // 32}, column {pos % 32}']
    for i, row in enumerate(rows):
        if i:
            out.append('    db $d8                  ; NEWLINE')
        if row:
            txt = ''.join(fm.get(x, '.') if x != BLANK else ' ' for x in row) if fm else ''
            for k in range(0, len(row), 16):
                c = f'  ; {txt}' if txt.strip(' .') and k == 0 else ''
                out.append(f'    db {_fmt(row[k:k + 16])}{c}')
    out.append('    db $d9                  ; END')
    return out


def run_block(gd, bank, start, end, repo=None):
    """The text of one re-sectioned run (the compiler region's body)."""
    cen = census(repo)
    fmaps = fonts(repo)
    if bank in (0x07, 0x15):
        out = [f'; [S165] window layout streams ${start:04X}-${end - 1:04X} (tools/resection_window_layouts.py;',
               '; DATA_STRUCTURES "Window layout streams (S165)"): dw position, cells = TILE numbers (the',
               '; screen\'s font: bank $07 = the FIELD font, the title menu = the TEXT font), $D8 newline,',
               '; $D9 end; drawn by `ld de, <stream> / call WinLayoutDraw…`. The words are editable',
               '; (editor2/core/window_words.py).']
    else:
        out = [f'; [S166] window layout streams ${start:04X}-${end - 1:04X} (tools/resection_window_layouts.py;',
               '; DATA_STRUCTURES "Window layout streams (S165)"): dw position, cells = TILE numbers (the',
               '; letters = the tiles THIS screen holds, measured — "font not measured" where no tour drew',
               '; it), $D8 newline, $D9 end; drawn by `ld de, <stream> / call WinLayoutDraw…`. The',
               '; measured words are editable (editor2/core/window_words.py).']
    a = start
    while a < end:
        key = f'{bank:02X}:{a:04X}'
        L = cen['layouts'][key]
        lf = layout_font(L, repo)
        dec = lf[0] if lf else (fmaps['field'] if bank == 0x07 else {})
        rows = rows_of(gd, bank, a, repo)
        ws = ' / '.join(w['text'] for w in find_words(rows, dec)) if dec else ''
        tw = ' / '.join(f"{t['text']} ({t['source']} {t['index']} +{t['offset']})"
                        for t in L.get('texts', []))
        what = WHAT.get((bank, a), '')
        meas = '' if L.get('font') else (' (font not measured)' if ws else '')
        tag = '; '.join(x for x in (what, ws, (f'from a text: {tw}' if tw else '')) if x)
        out.append(f'{label(bank, a)}:' + (f'  ; {tag}{meas}' if tag else ''))
        out += stream_lines(L['pos'], rows, dec if (L.get('font') or bank == 0x07) else {})
        a += L['len']
    if a != end:
        raise WindowWordsError(f'run ${bank:02X}:{start:04X}: streams end at ${a:04X}, not ${end:04X}')
    return '\n'.join(out) + '\n'


def _emitter(bank, start, end):
    def emit(prj, warnings):
        data = prj if isinstance(prj, dict) else getattr(prj, 'data', None) or {}
        repo = getattr(prj, 'repo_root', None) or REPO
        return run_block(data.get('gamedata') or {}, bank, start, end, repo)
    emit.__name__ = f'emit_win_words_{bank:02x}_{start:04x}'
    return emit


REGIONS = [(f'win_words_{b:02x}_{s:04x}', f'patches/bank_{b:03x}.asm', _emitter(b, s, e), b)
           for b, s, e in RUNS]
