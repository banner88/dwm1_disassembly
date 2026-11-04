"""window_words.py — S165: the words drawn in the game's WINDOWS as tiles, editable (ROADMAP
Phase F T-follow (a); TEXT_SYSTEM "Window words (S165)"; DATA_STRUCTURES "Window layout streams
(S165)"; PROJECT_COMPILER §2.73).

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
  * text   — the title menu (bank $15 $647D): the text font (A-Z, a-z, 0-9).

project.json:  gamedata.window_words = {"<bank>:<addr>/<row>/<col>": "NEW", …}
  — one entry per word slot (the census's words of a MEASURED stream); the new word is at most
  the slot's length (a shorter word is padded with blank cells; the window frame never moves);
  absent = the original. Each re-sectioned run is a compiler region
  (`win_words_<bank>_<start>` in patches/bank_007.asm / bank_015.asm) holding the run's streams
  as `db`, the same size whatever the words.
"""
import json
import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CENSUS = os.path.join('extracted', 'window_layouts.json')
BLANK = 0xE0

# the re-sectioned runs (tools/resection_window_layouts.py RUNS): (bank, start, end)
RUNS = [(0x07, 0x704D, 0x7D98), (0x15, 0x647D, 0x64F4), (0x15, 0x6716, 0x694E)]
WHAT = {
    (0x07, 0x704D): 'the field menu', (0x07, 0x7090): 'the gold box', (0x07, 0x70AD): 'INFO: who',
    (0x07, 0x70F7): 'the INFO page: stats', (0x07, 0x71AF): 'the INFO page: HP / MP',
    (0x07, 0x727B): 'the INFO page 2: name / family / master',
    (0x07, 0x7333): 'the INFO page 2: next level',
    (0x07, 0x7687): 'SKIL: who', (0x07, 0x78D9): 'SKIL: the MP box',
    (0x07, 0x798B): 'ITEM: the item window', (0x07, 0x7A61): 'OPTN', (0x07, 0x7C44): 'OPTN: yes / no',
    (0x07, 0x7C69): 'OPTN: CH PLAN (the tactics)', (0x07, 0x7BCA): 'OPTN: JOURNAL (the save box)',
    (0x15, 0x647D): 'the title menu',
}


class WindowWordsError(ValueError):
    pass


_CACHE = {}


def census(repo=None):
    repo = repo or REPO
    if repo not in _CACHE:
        _CACHE[repo] = json.load(open(os.path.join(repo, CENSUS)))
    return _CACHE[repo]


def fonts(repo=None):
    """{font: {tile: char}}"""
    return {k: {int(t, 16): c for t, c in v.items()} for k, v in census(repo)['fonts'].items()}


def _in_runs(bank, addr):
    return any(b == bank and s <= addr < e for b, s, e in RUNS)


def slots(repo=None):
    """{key: {bank, addr, row, col, len, text, font, letters, screen}} — every editable word
    (a measured stream inside a re-sectioned run). key = "BB:AAAA/row/col"."""
    out = {}
    for k, L in census(repo)['layouts'].items():
        f = L.get('font')
        if not f or not _in_runs(L['bank'], L['addr']):
            continue
        for w in L.get('words', []):
            key = f"{k}/{w['row']}/{w['col']}"
            out[key] = dict(bank=L['bank'], addr=L['addr'], row=w['row'], col=w['col'],
                            len=w['len'], text=w['text'], font=f['font'], letters=f['letters'],
                            screen=WHAT.get((L['bank'], L['addr']), ''))
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


def _encode(txt, font, repo=None):
    inv = {}
    for t, c in sorted(fonts(repo)[font].items()):
        inv.setdefault(c, t)
    return [BLANK if c == ' ' else inv[c] for c in txt]


def rows_of(gd, bank, addr, repo=None):
    """The stream's rows (lists of cells) with the project's words in place."""
    L = census(repo)['layouts'][f'{bank:02X}:{addr:04X}']
    rows = [list(bytes.fromhex(r)) for r in L['rows']]
    for key, txt in _words(gd).items():
        b_a, r, c = key.split('/')
        if b_a != f'{bank:02X}:{addr:04X}':
            continue
        s = slots(repo)[key]
        cells = _encode(txt.ljust(s['len']), s['font'], repo)
        r, c = int(r), int(c)
        rows[r][c:c + s['len']] = cells
    return rows


def _fmt(bs):
    return ', '.join(f'${b:02x}' for b in bs)


def stream_lines(pos, rows, font, repo=None):
    """The `dw` / `db` lines of one stream (tools/resection_window_layouts.py writes the same)."""
    fm = fonts(repo).get(font, {}) if font else {}
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
    out = [f'; [S165] window layout streams ${start:04X}-${end - 1:04X} (tools/resection_window_layouts.py;',
           '; DATA_STRUCTURES "Window layout streams (S165)"): dw position, cells = TILE numbers (the',
           '; screen\'s font: bank $07 = the FIELD font, the title menu = the TEXT font), $D8 newline,',
           '; $D9 end; drawn by `ld de, <stream> / call WinLayoutDraw…`. The words are editable',
           '; (editor2/core/window_words.py).']
    a = start
    while a < end:
        key = f'{bank:02X}:{a:04X}'
        L = cen['layouts'][key]
        font = (L.get('font') or {}).get('font') or ('field' if bank == 0x07 else None)
        rows = rows_of(gd, bank, a, repo)
        ws = ' / '.join(w['text'] for w in find_words(rows, fmaps[font])) if font else ''
        what = WHAT.get((bank, a), '')
        meas = '' if L.get('font') else (' (font not measured)' if ws else '')
        tag = '; '.join(x for x in (what, ws) if x)
        out.append(f'WinLayout_{bank:02X}_{a:04X}:' + (f'  ; {tag}{meas}' if tag else ''))
        out += stream_lines(L['pos'], rows, font, repo)
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
