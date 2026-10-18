"""ending.py — THE TITLE SCREEN AND THE ENDING (S153, ROADMAP E5; PROJECT_COMPILER
§2.61, DATA_STRUCTURES "The title screen and the ending (S153)").

User (S153): "E5 + handover sounds good. If intro has 'Milayou's Journey' or
whatever text I want added to it that would be cool. The final cutscene before
credits also should be editable and you can send a given cutscene to credits.
Anything connected to this is also fine."

Headless (no Qt). Five things, all measured on the original ROM (PyBoy) and
annotated in bank $5F (tools/annotate_ending_5f.py):

THE TITLE SCREEN (game mode 0, sub-mode 0, stage 6 — bank $5F TitleInit): the
logo rows 6-11 and the copyright rows 15-16 of TitleTilemap ($5F:$6583) over the
logo's tiles ($5B20 / $5B21), palette set 1 (bank $17 PaletteColorData + 64),
every attribute palette 5 (dark red / cream / orange / black); rows 0-5, 12-14 and
17 are empty, VRAM bank 1's tiles unused, nothing changes while the title waits.
The title song $06 (TitleInit, and TitleTick when it ends).

    custom.title = {"lines": [{"text": "Milayou's Journey", "row": 13,
                               "align": "center" | "col": 3,
                               "colour": "black" | "orange" | "red"}],
                    "song": <a song: a number or a project song's name>}

Each line is drawn in the game's text font (textenc: letters, digits, the
contractions) with its ink in the chosen colour of palette 5 (the font's
backdrop = colour 1, cream = the title's own background). Bank $79 entry 3
TitleText draws them from VRAM bank 1 (region title_text in TitleInitDone).
Up to 128 different tiles; Game Boy Color only (no VRAM bank 1 on a DMG).

THE CREDITS (game mode 4, sub-mode 0 — bank $5F CreditsInit / CreditsTick):
pages of a ROLE (text mode 5 = credits_role, a 20 x 2 tile grid), NAMES (mode 6 =
credits_name, 11 x 12) and a MONSTER (CreditsMonsterTable), 5 s each; the LAST
page uses CreditsCopyrightLayout (the names grid two rows to a line); then the
field again — vanilla: the intro bedroom.

    custom.credits = {"pages": [{"role": markup, "names": markup, "monster": sid}, …],
                      "seconds": 5, "song": <song>, "continue_song": <song>}

`pages` absent = the game's 27. Up to 64 pages; the last one is the closing page
(the copyright layout). The texts are the S150 text slots of credits_role /
credits_name (rows past 26 are slots past the tables' ends, as S151's items);
with custom.credits the credits texts are edited here, not in gamedata.text.

THE STEPS (cutscenes; editor2/core/cutscene_build.py):

    {"credits": {"dest": "room:$xx", "screen": k, "x": x, "y": y}}
        Roll the credits: story command 6 credits_after (wCreditsAfter = the
        place), `write_ram $C88A 4 / write_ram $C88B 0 / op $3E` — mode 4, the
        credits; bank $5F CreditsDone (region credits_after) → bank $79 entry 4
        CreditsAfter: the field again in that place (its entry scenes run).
    {"to_be_continued": {}}
        "…TO BE CONTINUED" — `write_ram $C88A 4 / write_ram $C88B 1 / op $3E`:
        the game's screen (credits_end row 0), a button → "save?" (text $0256),
        YES = SaveGameState (+ $0257), NO = $0258; then it waits for a reset.
        CONTINUE comes back to the room the scene ran in — its ENTRY scenes do not
        run then (the game's load runs no entry script: measured S153), so a
        post-game starts from a talk / step-on / examine scene or a door.
    {"story_point": {"point": n, "arena": true}}
        The original game's saved story as at story point n (story_state.state_at
        from the original opening's state): story command 5 → bank $79 entry 5
        StoryPointApply — the event flags $0000-$017F / $0248-$0257 (the
        project's pool flags $0159-$0167 kept), the room states $D92A-$D99A, the
        King's speech $D9E3 and (arena) the arena classes won $CAB4.

Both "credits" and "to_be_continued" end the scene (the game leaves the field).
"""

import copy
import os

from . import formats as F

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM_PATH = os.path.join(REPO, 'data', 'DWM-original.gbc')
BANK5F = 0x5F

# ---- the title screen (measured S153) ----------------------------------------
TITLE_TILEMAP = 0x6583           # $5F: TitleTilemap (DrawTilemapStream format)
TITLE_TILES = (0x5B20, 0x5B21)   # → $9000 (ids $00-$7F) / $8800 (ids $80-$FF)
TITLE_PALETTE_SET = 1            # bank $17 PaletteColorData + 64 · set
TITLE_PALETTE = 5
PALETTE_DATA = (0x17, 0x69BD)    # bank $17 PaletteColorData
TITLE_EMPTY_ROWS = (0, 1, 2, 3, 4, 5, 12, 13, 14, 17)
TITLE_LOGO_ROWS = range(6, 12)
TITLE_COPYRIGHT_ROWS = (15, 16)
COLOURS = {'black': 3, 'orange': 2, 'red': 0}      # palette 5: $0012 / $6BFF / $01DE / $0000
TITLE_MAX_TILES = 128            # VRAM bank 1 ids $80-$FF
TITLE_MAX_LINES = 8
TITLE_SONG = 0x06

# ---- the credits (measured S153) ---------------------------------------------
PAGE_TILEMAP = 0x66B3            # $5F: CreditsPageTilemap, 20 x 18 tiles
CLOSING_TILEMAP = 0x681B         # $5F: CreditsCopyrightTilemap, 20 x 11 over rows 0-10
MONSTER_TABLE = 0x43F4           # $5F: CreditsMonsterTable, 27 B
VANILLA_PAGES = 27
MAX_PAGES = 64                   # region credits_monsters (64 B from bank $5F's pad)
ROLE_FIRST, ROLE_W, ROLE_H = 0x00, 20, 2      # CreditsDrawRole: $8000, 2 rows x 20
NAMES_FIRST, NAMES_W, NAMES_H = 0x26, 11, 12  # CreditsDrawNames: $8260, 12 rows x 11
MONSTER_FIRST = 0xAA             # the 6 x 6 battle pose at $8AA0, BG palette 4
CREDITS_SONG = 0x21
CONTINUE_SONG = 0x31
SECONDS = 5
TEXT_BANK = 0x4C
ROLE_TABLE, NAME_TABLE, END_TABLE = 0x4263, 0x4299, 0x42CF
CREDITS_TEXT = ('credits_role', 'credits_name')
PROTECTED_SPECIES = range(215, 221)   # Iron Rule 8: not monsters

# ---- the steps ------------------------------------------------------------------
GAME_MODE, SUB_MODE = 0xC88A, 0xC88B
ENDING_MODE = 4
SUB_CREDITS, SUB_CONTINUE = 0, 1

# ---- the story points ---------------------------------------------------------
FLAG_BYTES = (0xD99B, 0xD9CA)          # flags $0000-$017F
FLAG_BYTES_2 = (0xD9E4, 0xD9E5)        # flags $0248-$0257
ROOM_BYTES = (0xD92A, 0xD99A)          # the step counters (story_state.STATE_RAM)
ARENA_TIER = 0xCAB4
KING_CODE = 0xD9E3
POOL_FLAGS = range(0x0159, 0x0168)     # the editor's own flags inside the game's range
MAX_POINTS = 32


class EndingError(ValueError):
    pass


_ROM = {}


def rom(path=None):
    p = path or ROM_PATH
    if p not in _ROM:
        _ROM[p] = open(p, 'rb').read()
    return _ROM[p]


def _rd(r, bank, a, n=1):
    o = bank * 0x4000 + a - 0x4000
    return r[o:o + n]


# ================================================================== the title
def title(custom):
    """custom.title normalized ({'lines': [...], 'song': x}) or None."""
    t = (custom or {}).get('title')
    if not isinstance(t, dict):
        return None
    lines = [dict(ln) for ln in (t.get('lines') or []) if isinstance(ln, dict)]
    if not lines and t.get('song') is None:
        return None
    return {'lines': lines, 'song': t.get('song')}


def line_codes(text):
    """A title line -> the glyph codes it shows (textenc; no inserts)."""
    from . import textenc as TE
    s = str(text or '')
    if '{' in s:
        raise EndingError(f'title line {s!r}: no inserts ({{hero}} …) on the title')
    try:
        return TE.codes(s)
    except TE.TextError as ex:
        raise EndingError(f'title line {s!r}: {ex}')


def line_cells(ln):
    """(row, col, codes) of a title line; EndingError when it does not fit."""
    codes = line_codes(ln.get('text'))
    try:
        row = int(ln.get('row', 13))
    except (TypeError, ValueError):
        raise EndingError(f"title line {ln.get('text')!r}: row must be a number 0-17")
    if not 0 <= row <= 17:
        raise EndingError(f"title line {ln.get('text')!r}: row {row} — rows 0-17")
    if len(codes) > 20:
        raise EndingError(f"title line {ln.get('text')!r}: {len(codes)} letters — a row "
                          "holds 20")
    if 'col' in ln and ln.get('col') is not None and ln.get('align') != 'center':
        try:
            col = int(ln['col'])
        except (TypeError, ValueError):
            raise EndingError(f"title line {ln.get('text')!r}: col must be a number 0-19")
        if col < 0 or col + len(codes) > 20:
            raise EndingError(f"title line {ln.get('text')!r}: column {col} + {len(codes)} "
                              "letters runs past the right edge (20 columns)")
    else:
        col = (20 - len(codes)) // 2
    return row, col, codes


def ink(ln):
    c = ln.get('colour', 'black')
    if c not in COLOURS:
        raise EndingError(f"title line {ln.get('text')!r}: colour {c!r} — "
                          f"{', '.join(COLOURS)}")
    return COLOURS[c]


def glyph_tile(r, code, ink_index):
    """The font glyph (colour 1 backdrop, colour 3 ink) with its ink in ink_index."""
    from . import textenc as TE
    g = TE.glyph_2bpp(r, code)
    out = bytearray()
    for y in range(8):
        hi = g[2 * y + 1]            # the font: low plane all 1, high plane = the ink
        lo_ink = hi if ink_index & 1 else 0
        hi_ink = hi if ink_index & 2 else 0
        out.append(((~hi) & 0xFF) | lo_ink)
        out.append(hi_ink)
    return bytes(out)


def title_layout(custom, r=None):
    """-> (tiles [16-byte], lines [(row, col, [tile ids])]) for TitleTextData.
    Tile ids $80+ (VRAM bank 1 $8800+). EndingError on a problem."""
    t = title(custom)
    if t is None:
        return [], []
    r = r or rom()
    if len(t['lines']) > TITLE_MAX_LINES:
        raise EndingError(f'custom.title: {len(t["lines"])} lines — at most {TITLE_MAX_LINES}')
    tiles, index, out = [], {}, []
    taken = {}
    for ln in t['lines']:
        row, col, codes = line_cells(ln)
        k = ink(ln)
        ids = []
        for i, c in enumerate(codes):
            cell = (row, col + i)
            if cell in taken:
                raise EndingError(f"title lines {taken[cell]!r} and {ln.get('text')!r} "
                                  f"overlap at row {row}, column {col + i}")
            taken[cell] = ln.get('text')
            b = glyph_tile(r, c, k)
            if b not in index:
                index[b] = len(tiles)
                tiles.append(b)
            ids.append(0x80 + index[b])
        if ids:
            out.append((row, col, ids))
    if len(tiles) > TITLE_MAX_TILES:
        raise EndingError(f'custom.title: {len(tiles)} different letters / colours — the '
                          f'title has room for {TITLE_MAX_TILES}')
    return tiles, out


def title_warnings(custom):
    out = []
    t = title(custom)
    if t is None:
        return out
    for ln in t['lines']:
        try:
            row, col, codes = line_cells(ln)
        except EndingError:
            continue
        if row in TITLE_LOGO_ROWS:
            out.append(f"title line {ln.get('text')!r}: row {row} covers part of the logo "
                       "(rows 6-11)")
        elif row in TITLE_COPYRIGHT_ROWS:
            out.append(f"title line {ln.get('text')!r}: row {row} covers part of the "
                       "copyright lines (rows 15-16)")
    return out


# ------------------------------------------------------------ the title picture
def _decode_gfx(r, gid):
    from dwm import sprite_codec as SC
    _b, _i, _a, off = SC.gfxid_stream_offset(r, gid)
    return SC.decode(SC.read_stream(r, off))


def stream_tilemap(r, bank, addr):
    """DrawTilemapStream ($5F:$4263) -> {(row, col): tile}."""
    out = {}
    a = addr
    off = _rd(r, bank, a)[0] | _rd(r, bank, a + 1)[0] << 8
    a += 2
    pos = start = off
    while True:
        c = _rd(r, bank, a)[0]
        a += 1
        if c == 0xD9:
            break
        if c == 0xD8:
            start += 32
            pos = start
            continue
        out[(pos // 32, pos % 32)] = c
        pos += 1
    return out


def palette(r, set_no, pal):
    b, a = PALETTE_DATA
    raw = _rd(r, b, a + 64 * set_no + 8 * pal, 8)
    return [raw[2 * i] | raw[2 * i + 1] << 8 for i in range(4)]


def rgb555(v):
    return ((v & 31) * 255 // 31, ((v >> 5) & 31) * 255 // 31, ((v >> 10) & 31) * 255 // 31)


def _tile_pixels(t):
    rows = []
    for y in range(8):
        lo, hi = t[2 * y], t[2 * y + 1]
        rows.append([((lo >> (7 - x)) & 1) | (((hi >> (7 - x)) & 1) << 1) for x in range(8)])
    return rows


def title_picture(custom=None, r=None):
    """The title screen as the game draws it (160 x 144 rows of RGB tuples) with
    the project's lines — == PyBoy pixel for pixel (RGB555; test_compiler)."""
    r = r or rom()
    t9000 = _decode_gfx(r, TITLE_TILES[0])
    t8800 = _decode_gfx(r, TITLE_TILES[1])
    tm = stream_tilemap(r, BANK5F, TITLE_TILEMAP)
    pal = [rgb555(c) for c in palette(r, TITLE_PALETTE_SET, TITLE_PALETTE)]
    own_tiles, lines = title_layout(custom or {}, r) if custom else ([], [])
    own = {}
    for row, col, ids in lines:
        for i, tid in enumerate(ids):
            own[(row, col + i)] = own_tiles[tid - 0x80]
    img = [[pal[1]] * 160 for _ in range(144)]
    for row in range(18):
        for col in range(20):
            if (row, col) in own:
                data = own[(row, col)]
            else:
                tid = tm.get((row, col), 0)
                data = (t9000[tid * 16:tid * 16 + 16] if tid < 0x80
                        else t8800[(tid - 0x80) * 16:(tid - 0x80) * 16 + 16])
                if len(data) < 16:
                    data = bytes(16)
            for y, px in enumerate(_tile_pixels(data)):
                for x, v in enumerate(px):
                    img[row * 8 + y][col * 8 + x] = pal[v]
    return img


# ================================================================== the credits
def credits(custom):
    """custom.credits or None."""
    c = (custom or {}).get('credits')
    return c if isinstance(c, dict) else None


def vanilla_pages(repo_root=None, r=None):
    """The game's 27 pages: {'role', 'names', 'monster'} (markup, species)."""
    from . import gametext as GT
    ix = GT.index(repo_root)
    r = r or rom()
    mons = _rd(r, BANK5F, MONSTER_TABLE, VANILLA_PAGES)
    out = []
    for i in range(VANILLA_PAGES):
        role = ix.get('credits_role', str(i))
        names = ix.get('credits_name', str(i))
        out.append({'role': role.markup() if role else '',
                    'names': names.markup() if names else '',
                    'monster': mons[i]})
    return out


def pages(custom, repo_root=None):
    c = credits(custom)
    if c is None or not isinstance(c.get('pages'), list):
        return vanilla_pages(repo_root)
    return [dict(p) for p in c['pages']]


def song_ref(prj, v, what, default):
    """A song setting -> its sound id (a number, or a project song by name)."""
    if v is None or v == '':
        return default
    if isinstance(v, str) and v and not v[:1].isdigit() and not v.startswith(('$', '0x', '0X')):
        ids = prj.music_song_ids() if hasattr(prj, 'music_song_ids') else {}
        if v not in ids:
            raise EndingError(f'{what}: {v!r} is not one of the project\'s songs')
        return ids[v]
    try:
        n = F.val(v)
    except (TypeError, ValueError):
        raise EndingError(f'{what}: {v!r} is not a song')
    if not 0 <= n <= 0xFE:
        raise EndingError(f'{what}: {v!r} is not a song number')
    return n


def encode_text(markup, what):
    from . import textmark as TM
    try:
        return TM.encode(markup or '', 'rows')
    except TM.MarkupError as ex:
        raise EndingError(f'{what}: {ex}')


def layout_text(raw, first, width):
    """The copy-mode text engine's tile writes (bank $56: a glyph = the next tile, $F1
    = the line's start + one row; no wrap) -> {tile: glyph code}."""
    from . import textmark as TM
    out = {}
    start = pos = first
    for kind, bs in TM._units(raw):
        if kind == 'g':
            out[pos] = bs[0]
            pos += 1
        elif bs[:1] == b'\xf1':
            start += width
            pos = start
        elif bs[:1] == b'\xf0':
            break
    return out


_MAPS = {}


def page_maps(r=None):
    """(normal {(row, col): tile}, closing {(row, col): tile}) from the ROM."""
    r = r or rom()
    if id(r) not in _MAPS:
        base = {}
        raw = _rd(r, BANK5F, PAGE_TILEMAP, 20 * 18)
        for row in range(18):
            for col in range(20):
                base[(row, col)] = raw[row * 20 + col]
        close = dict(base)
        raw2 = _rd(r, BANK5F, CLOSING_TILEMAP, 20 * 11)
        for row in range(11):
            for col in range(20):
                close[(row, col)] = raw2[row * 20 + col]
        _MAPS[id(r)] = (base, close)
    return _MAPS[id(r)]


def page_tiles(page, r=None):
    """The page's text tiles as the game leaves them: {tile: code} after the role
    (its grid cleared) and the names (its grid cleared over the role's)."""
    role = encode_text(page.get('role'), 'role')
    names = encode_text(page.get('names'), 'names')
    tiles = {}
    for t, c in layout_text(role, ROLE_FIRST, ROLE_W).items():
        tiles[t] = c
    for t in range(NAMES_FIRST, NAMES_FIRST + NAMES_W * NAMES_H):
        tiles.pop(t, None)
    for t, c in layout_text(names, NAMES_FIRST, NAMES_W).items():
        tiles[t] = c
    return tiles, role, names


def page_problems(page, last, r=None):
    """(errors, warnings) of one page (its texts, its monster, what shows)."""
    errs, warns = [], []
    try:
        tiles, role, names = page_tiles(page, r)
    except EndingError as ex:
        return [str(ex)], warns
    rl = layout_text(role, ROLE_FIRST, ROLE_W)
    nl = layout_text(names, NAMES_FIRST, NAMES_W)
    if rl and max(rl) >= ROLE_FIRST + ROLE_W * ROLE_H:
        errs.append('the role is longer than its 2 rows of 20')
    if nl and max(nl) >= NAMES_FIRST + NAMES_W * NAMES_H:
        errs.append('the names are longer than their 12 rows of 11 (they would write over '
                    'the monster and the letters of the font)')
    base, close = page_maps(r)
    shown = set((close if last else base).values())
    hidden = sorted(t for t in tiles if t not in shown and tiles[t] != 0x62)
    if hidden:
        warns.append(f'{len(hidden)} letter(s) fall outside the picture (a line longer than its '
                     'row, or a role line past 19 / 18 letters) — see the preview')
    m = page.get('monster')
    try:
        m = int(m)
    except (TypeError, ValueError):
        errs.append('pick the page\'s monster')
        return errs, warns
    if m in PROTECTED_SPECIES:
        errs.append(f'monster {m} is TERRY? / a summon — not a monster (Iron Rule 8)')
    elif not (0 <= m <= 214 or 221 <= m <= 239):
        errs.append(f'monster {m}: 0-214 or the project\'s new species 221-239')
    return errs, warns


def page_picture(page, last, r=None, monster_rows=None, text_pal=None):
    """The credits page as drawn (160 x 144 RGB rows). monster_rows = (576-byte battle
    tiles, 4 RGB555 words) — monster_art() — or 48 x 48 RGB rows; None = none drawn."""
    from . import textenc as TE
    r = r or rom()
    tiles, _role, _names = page_tiles(page, r)
    base, close = page_maps(r)
    tm = close if last else base
    cream, black = rgb555(0x6BFF), rgb555(0x0000)
    pal = text_pal or [cream, cream, rgb555(0x5294), black]
    img = [[cream] * 160 for _ in range(144)]
    if isinstance(monster_rows, tuple):   # (576-byte battle tiles, 4 RGB555 words)
        from . import sprite_render as SR
        tl, pw = monster_rows
        # the engine forces colour 1 = $6BFF and colour 3 = $0000 in the BG palettes it
        # loads (KEY_LESSONS S7 / S39) — species 164's table row ends in $1800, the game
        # shows black (measured S153, credits page 7)
        cols = [rgb555(w) for w in (pw[0], 0x6BFF, pw[2], 0x0000)]
        monster_rows = [[cols[v] for v in row] for row in SR.tiles_to_grid(tl, 6, 6)]
    for (row, col), tid in tm.items():
        if MONSTER_FIRST <= tid < MONSTER_FIRST + 36:
            if monster_rows is None:
                continue
            k = tid - MONSTER_FIRST
            mx, my = (k % 6) * 8, (k // 6) * 8
            for y in range(8):
                for x in range(8):
                    img[row * 8 + y][col * 8 + x] = monster_rows[my + y][mx + x]
            continue
        code = tiles.get(tid)
        if code is None:
            continue
        for y, px in enumerate(_tile_pixels(TE.glyph_2bpp(r, code))):
            for x, v in enumerate(px):
                img[row * 8 + y][col * 8 + x] = pal[v]
    return img


def monster_art(data, project_dir, sid):
    """(576-byte battle tiles, 4 RGB555 words) of species `sid` as the project draws it
    (gamedata.art for an original, custom.species for a new one), or None."""
    from . import sprite_render as SR
    from dwm.sprite_codec import decode
    sid = int(sid)

    def words(p):
        return [int(str(x).replace('$', '0x'), 0) if isinstance(x, str) else int(x) for x in p]
    try:
        if sid <= 214:
            ms, pal = SR._load('monster_sprites.json'), SR._load('monster_palettes.json')
            e = (((data or {}).get('gamedata') or {}).get('art') or {}).get(str(sid)) or {}
            b = e.get('battle') or {}
            tiles = (decode(open(os.path.join(project_dir, b['art']), 'rb').read()) if 'art' in b
                     else bytes.fromhex(ms['monsters'][str(sid)]['battle']['tile_bytes_hex']))
            pw = words(b['palette']) if 'palette' in b else pal['monsters'][str(sid)]['colors']
        else:
            sp = next(s for s in ((data or {}).get('custom') or {}).get('species') or []
                      if isinstance(s, dict) and s.get('id') == sid)
            b = sp.get('battle') or {}
            tiles = decode(open(os.path.join(project_dir, b['art']), 'rb').read())
            pw = words(b['palette'])
        return (tiles, pw) if len(tiles) == 576 and len(pw) == 4 else None
    except (OSError, KeyError, ValueError, TypeError, StopIteration):
        return None


def validate_credits(prj):
    errs, warns = [], []
    c = credits(prj.custom)
    if c is None:
        return errs, warns
    unknown = set(c) - {'pages', 'seconds', 'song', 'continue_song', 'comment'}
    if unknown:
        errs.append(f'custom.credits: unknown keys {sorted(unknown)}')
    gt = ((prj.data.get('gamedata') or {}).get('text') or {}) if hasattr(prj, 'data') else {}
    for src in CREDITS_TEXT:
        if gt.get(src):
            errs.append(f'gamedata.text.{src}: with custom.credits the credits are edited on '
                        'the Title & ending page (Cutscenes tab) — move these edits there')
    ps = pages(prj.custom, getattr(prj, 'repo_root', None))
    if not 1 <= len(ps) <= MAX_PAGES:
        errs.append(f'custom.credits.pages: {len(ps)} pages — 1-{MAX_PAGES}')
    for i, p in enumerate(ps):
        e, w = page_problems(p, i == len(ps) - 1)
        errs += [f'credits page {i + 1}: {x}' for x in e]
        warns += [f'credits page {i + 1}: {x}' for x in w]
    try:
        s = int(c.get('seconds', SECONDS))
        if not 1 <= s <= 60:
            raise ValueError
    except (TypeError, ValueError):
        errs.append('custom.credits.seconds: 1-60')
    for k, d in (('song', CREDITS_SONG), ('continue_song', CONTINUE_SONG)):
        try:
            song_ref(prj, c.get(k), f'custom.credits.{k}', d)
        except EndingError as ex:
            errs.append(str(ex))
    return errs, warns


def text_slots(prj_or_data, repo_root=None):
    """[(bank, table, index, raw incl. $F0, what)] — the credits' role / names texts
    that differ from the game's (and every row past 26), for the S150 text banks
    (gametext.resolve appends them)."""
    data = getattr(prj_or_data, 'data', prj_or_data) or {}
    custom = data.get('custom') or {}
    c = credits(custom)
    if c is None or not isinstance(c.get('pages'), list):
        return []
    try:
        ps = pages(custom, repo_root)
        van = vanilla_pages(repo_root)
    except Exception:                                    # noqa: BLE001
        return []
    from . import gametext as GT
    ix = GT.index(repo_root)
    out = []
    last = len(ps) - 1
    for i, p in enumerate(ps):
        for src, table, key in (('credits_role', ROLE_TABLE, 'role'),
                                ('credits_name', NAME_TABLE, 'names')):
            try:
                raw = encode_text(p.get(key), f'credits page {i + 1} {key}')
            except EndingError:
                continue
            if i < VANILLA_PAGES:
                e = ix.get(src, str(i))
                if e is not None and e.raw == raw:
                    continue
            out.append((TEXT_BANK, table, i, raw + b'\xf0',
                        f'credits page {i + 1}' + (' (the closing page)' if i == last else '')
                        + f': the {key}'))
    return out


def credits_active(custom):
    return credits(custom) is not None


# ================================================================== story points
def opening_state():
    """The original opening's measured state (newgame.py, S152): flags + bytes."""
    from . import newgame as NG
    flags = set(NG.ROOM_START_FLAGS + NG.OPENING_FLAGS + [0x0002])
    ram = dict(NG.OPENING_BYTES + NG.ROOM_START_BYTES)
    return flags, ram


def point_count():
    from .balance import VANILLA_STEPS
    return len(VANILLA_STEPS) + 1


def point_label(n):
    """'about to do <step>' / the very end."""
    from .balance import VANILLA_STEPS
    from . import balance as B
    if n >= len(VANILLA_STEPS):
        return 'everything done (after Monster Grandpa\'s match)'
    try:
        tl = B.vanilla_timeline() if hasattr(B, 'vanilla_timeline') else None
    except Exception:                                    # noqa: BLE001
        tl = None
    if tl is not None:
        for s in tl.steps:
            if s['index'] == n:
                return 'about to do ' + s['label'] + ('  (post-game)' if s['postgame'] else '')
    kind, k = VANILLA_STEPS[n]
    return f'about to do {kind} {k}'


_POINT_CACHE = {}


def point_state(n, repo_root=None):
    """story_state at point n, from the original opening's state."""
    key = (n, repo_root)
    if key not in _POINT_CACHE:
        from . import story_state as SS
        fl, ram = opening_state()
        _POINT_CACHE[key] = SS.state_at(n, repo_root or SS.REPO, start=(fl, ram))
    return _POINT_CACHE[key]


def point_rows(n, arena=True, repo_root=None):
    """[(address, keep, value)] StoryPointApply writes for point n."""
    st = point_state(n, repo_root)
    flags = set(st['flags_on'])
    ram = st['ram']
    rows = []

    def flag_byte(a, first_flag):
        v = keep = 0
        for b in range(8):
            f = first_flag + b
            mask = 0x80 >> b
            if f in POOL_FLAGS:
                keep |= mask
            elif f in flags:
                v |= mask
        return (a, keep, v)
    for a in range(ROOM_BYTES[0], ROOM_BYTES[1] + 1):
        rows.append((a, 0, ram.get(a, 0) & 0xFF))
    for a in range(FLAG_BYTES[0], FLAG_BYTES[1] + 1):
        rows.append(flag_byte(a, (a - 0xD99B) * 8))
    for a in range(FLAG_BYTES_2[0], FLAG_BYTES_2[1] + 1):
        rows.append(flag_byte(a, (a - 0xD99B) * 8))
    rows.append((KING_CODE, 0, ram.get(KING_CODE, 0) & 0xFF))
    if arena:
        rows.append((ARENA_TIER, 0, st.get('arena_tier', ram.get(ARENA_TIER, 0)) & 0xFF))
    return rows


def point_index(prj, point, arena):
    """The project's story point table index of (point, arena) (allocated on use)."""
    try:
        n = int(point)
    except (TypeError, ValueError):
        raise EndingError(f'story point {point!r}: a number 0-{point_count() - 1}')
    if not 0 <= n < point_count():
        raise EndingError(f'story point {n}: 0-{point_count() - 1}')
    key = (n, bool(arena))
    pts = prj.__dict__.setdefault('_story_points', [])
    if key not in pts:
        if len(pts) >= MAX_POINTS:
            raise EndingError(f'more than {MAX_POINTS} different story points')
        pts.append(key)
    return pts.index(key)


def credits_after_record(prj, dest, ctx):
    """{"dest": "room:$xx", "screen", "x", "y"} -> the 6 bytes of story command 6."""
    if not isinstance(dest, dict):
        raise EndingError(f'{ctx}: the credits need the place the game goes on in')
    mid_w, px_w, py_w = prj._move_words(dest, ctx)
    mid, px, py = int(mid_w, 16), int(px_w, 16), int(py_w, 16)
    reg = F.mid_region(mid)
    return [mid & 0xFF, (reg + 1) if reg else 0, px & 0xFF, px >> 8, py & 0xFF, py >> 8]


# ================================================================== emitters
def active(prj):
    """Does bank $79 need this module's code / data?"""
    c = prj.custom
    return bool(title(c) and title(c)['lines']) or bool(getattr(prj, '_story_points', None)) \
        or bool(getattr(prj, '_credits_steps', 0))


def data_lines(prj):
    """Bank $79: TitleTextData, STORY_POINT_COUNT, StoryPointPtrs + records."""
    tiles, lines = title_layout(prj.custom)
    out = ['; ' + '=' * 77,
           '; THE TITLE SCREEN + THE ORIGINAL STORY AT A POINT (generated by editor2/core/',
           '; ending.py from custom.title and the story-point steps, S153)',
           '; ' + '=' * 77,
           'TitleTextData:',
           f'    db {len(tiles)}   ; tiles (VRAM bank 1 $8800+, ids $80+)']
    for i, t in enumerate(tiles):
        out.append('    db ' + ', '.join(f'${b:02x}' for b in t) + f'   ; ${0x80 + i:02X}')
    for row, col, ids in lines:
        out.append(f'    dw ${0x9800 + row * 32 + col:04X}   ; row {row}, column {col}')
        out.append(f'    db {len(ids)}, ' + ', '.join(f'${x:02x}' for x in ids))
    out.append('    dw $0000')
    pts = getattr(prj, '_story_points', None) or []
    out.append(f'STORY_POINT_COUNT EQU {len(pts)}')
    out.append('StoryPointPtrs:')
    for i, (n, arena) in enumerate(pts):
        out.append(f'    dw StoryPoint_{i}   ; {point_label(n)}'
                   + ('' if arena else ' (arena classes kept)'))
    for i, (n, arena) in enumerate(pts):
        out.append(f'StoryPoint_{i}:')
        rows = point_rows(n, arena, getattr(prj, 'repo_root', None))
        for a, keep, v in rows:
            out.append(f'    dw ${a:04X}\n    db ${keep:02x}, ${v:02x}')
        out.append('    dw $0000')
    return out


def _r(fn):
    fn.__name__ = 'emit_' + fn.__name__
    return fn


def emit_title_text(prj, warnings):
    t = title(prj.custom)
    if not t or not t['lines']:
        return ('    ld a, $00\n'
                '    ldh [rVBK], a\n'
                '    ret\n')
    return ('    ld hl, $7903                   ; S153 custom.title: bank $79 entry 3 TitleText\n'
            '    rst $10                        ;   (was ld a, $00 / ldh [rVBK], a / ret)\n'
            '    ret\n')


def _song_line(prj, v, what, default, comment):
    try:
        n = song_ref(prj, v, what, default)
    except EndingError:
        n = default
    return f'    ld a, ${n:02x}                       ; {comment}\n'


def emit_title_song(prj, warnings):
    t = title(prj.custom) or {}
    return _song_line(prj, t.get('song'), 'custom.title.song', TITLE_SONG,
                      'the title song (S153)')


def emit_title_song_again(prj, warnings):
    t = title(prj.custom) or {}
    return _song_line(prj, t.get('song'), 'custom.title.song', TITLE_SONG,
                      'the title song again (S153)')


def emit_credits_song(prj, warnings):
    c = credits(prj.custom) or {}
    return _song_line(prj, c.get('song'), 'custom.credits.song', CREDITS_SONG,
                      "the credits' song (S153)")


def emit_continue_song(prj, warnings):
    c = credits(prj.custom) or {}
    return _song_line(prj, c.get('continue_song'), 'custom.credits.continue_song',
                      CONTINUE_SONG, '"TO BE CONTINUED"\'s song (S153)')


def emit_credits_seconds(prj, warnings):
    c = credits(prj.custom) or {}
    try:
        s = int(c.get('seconds', SECONDS))
    except (TypeError, ValueError):
        s = SECONDS
    return f'    cp ${s:02x}                          ; the seconds a page shows (S153)\n'


def _last(prj):
    c = credits(prj.custom)
    if c is None or not isinstance(c.get('pages'), list):
        return VANILLA_PAGES - 1
    return max(0, len(c['pages']) - 1)


def emit_credits_last_a(prj, warnings):
    return f'    cp ${_last(prj):02x}                          ; the last page\'s number (S153)\n'


def emit_credits_last_b(prj, warnings):
    return f'    cp ${_last(prj):02x}                          ; the last page\'s number (S153)\n'


def _own_monsters(prj):
    c = credits(prj.custom)
    return c is not None and isinstance(c.get('pages'), list)


def emit_credits_monster_ptr(prj, warnings):
    if not _own_monsters(prj):
        return '    ld hl, CreditsMonsterTable\n'
    return '    ld hl, CreditsProjectMonsters  ; S153 custom.credits: the project\'s pages\n'


def emit_credits_monsters(prj, warnings):
    if not _own_monsters(prj):
        return '    nop\n' * MAX_PAGES
    ps = pages(prj.custom, getattr(prj, 'repo_root', None))
    ms = []
    for p in ps:
        try:
            ms.append(int(p.get('monster')) & 0xFF)
        except (TypeError, ValueError):
            ms.append(0)
    ms += [0xFF] * (MAX_PAGES - len(ms))
    out = ['CreditsProjectMonsters:   ; S153: the monster of each credits page (custom.credits)']
    for k in range(0, MAX_PAGES, 16):
        out.append('    db ' + ', '.join(f'${x:02x}' for x in ms[k:k + 16]))
    return '\n'.join(out) + '\n'


VANILLA_AFTER = """    ld hl, $002f
    ld a, l
    ld [wWarpGateId], a
    ld a, h
    ld [wWarpFlag], a
    ld hl, $0038
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $00c8
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ld a, $01
    ld [wIsPlayerChangingMaps], a
"""


def emit_credits_after(prj, warnings):
    if not getattr(prj, '_credits_steps', 0):
        return VANILLA_AFTER
    return ('    ld hl, $7904                   ; S153: bank $79 entry 4 CreditsAfter — the mailbox\n'
            '    rst $10                        ;   from wCreditsAfter (a "Roll the credits" step)\n'
            '    jr CreditsDoneWarpEnd\n' + '    nop\n' * 32)


REGIONS = [
    ('title_text', 'patches/bank_05f.asm', emit_title_text, BANK5F),
    ('title_song', 'patches/bank_05f.asm', emit_title_song, BANK5F),
    ('title_song_again', 'patches/bank_05f.asm', emit_title_song_again, BANK5F),
    ('credits_song', 'patches/bank_05f.asm', emit_credits_song, BANK5F),
    ('continue_song', 'patches/bank_05f.asm', emit_continue_song, BANK5F),
    ('credits_seconds', 'patches/bank_05f.asm', emit_credits_seconds, BANK5F),
    ('credits_last_a', 'patches/bank_05f.asm', emit_credits_last_a, BANK5F),
    ('credits_last_b', 'patches/bank_05f.asm', emit_credits_last_b, BANK5F),
    ('credits_monster_ptr', 'patches/bank_05f.asm', emit_credits_monster_ptr, BANK5F),
    ('credits_monsters', 'patches/bank_05f.asm', emit_credits_monsters, BANK5F),
    ('credits_after', 'patches/bank_05f.asm', emit_credits_after, BANK5F),
]


# ================================================================== validation
def validate(prj):
    """(errors, warnings) of custom.title / custom.credits."""
    errs, warns = [], []
    t = (prj.custom or {}).get('title')
    if t is not None:
        if not isinstance(t, dict):
            errs.append('custom.title: an object {lines, song}')
        else:
            unknown = set(t) - {'lines', 'song', 'comment'}
            if unknown:
                errs.append(f'custom.title: unknown keys {sorted(unknown)}')
            for ln in t.get('lines') or []:
                unknown = set(ln) - {'text', 'row', 'col', 'align', 'colour', 'comment'}
                if unknown:
                    errs.append(f"custom.title line {ln.get('text')!r}: unknown keys "
                                f"{sorted(unknown)}")
            try:
                title_layout(prj.custom)
            except EndingError as ex:
                errs.append(str(ex))
            try:
                song_ref(prj, t.get('song'), 'custom.title.song', TITLE_SONG)
            except EndingError as ex:
                errs.append(str(ex))
            warns += title_warnings(prj.custom)
    e, w = validate_credits(prj)
    return errs + e, warns + w


def copy_title(custom):
    return copy.deepcopy((custom or {}).get('title'))
