"""foods.py — the FOODS tick (S172, `gamedata.foods`; PROJECT_COMPILER §2.78).

User S172: "I want to replace the meats and meat icons in the game with different
items … Toast, Apple, Biscuit, Honey … Make this a TICK on the editor that I can turn
on/off. When off its vanilla behaviour"; BadMeat -> "BadApple is good"; the field
sprite: "YES, and disambiguate so not everything is meat. Apple becomes an apple icon,
honey becomes a honey icon"; the story's words are left alone ("Dont care about story").

`gamedata.foods: true` (absent / false = the game as it is) does three things, each a
DEFAULT the project's own edits still win over:

  1. NAMES — the five meat items (DATA_STRUCTURES "Items (S151)"; what they do, cost and
     where they are sold never changes):
       19 BeefJerky -> Toast    (+10 in battle, 20 G, the Bazaar)
       20 PorkChop  -> Apple    (+30, 80 G, the Bazaar)
       21 Rib       -> Biscuit  (+100, 300 G, Starry Night)
       22 BadMeat   -> BadApple (poisons, +5; not sold)
       23 Sirloin   -> Honey    (+400, 1000 G, the rare-item shop)
     as `gamedata.text.item_name` defaults (gametext.edits — a row the project edited
     keeps its own words).
  2. FIELD SPRITES — every food its own 16x16 picture (editor2/assets/foods/*.png, one
     field OBJ palette each: colour 1 cream, 2 the accent, 3 black), as plain NPC sprite
     ids $58-$5C (the game's unused copies of $50 — ROOM_DATA_FORMAT "NPC sprite tables
     (S172)"), and the game's own meat $5F (the spring scene, the ending bedroom) shows
     the Apple. Regions: ROM0 `npc_food_sheets` (NpcSheetGfxTable ids $58-$5F) and bank
     $05 `npc_food_pals` (NpcSpritePalTable ids $58-$5F); the sheets are LZ streams in
     bank $77 reached as gfx-IDs $7717-$771B (the bank's $4001 table — its far-call
     entries 23-27 are data, never called).
  3. ONE FRAME — the objects' level-1 lists hold ONE frame (the second word is the
     frame's own bytes), and a standing NPC steps between frames 0 and 1 (PyBoy S172),
     so bank $77 `NpcDrawPlain` holds the ids in `NpcStaticIds` on frame 0. Off: the
     list is empty (the game's draw).

The battle shows no meat (the feeding shows the stock note animation $2C) — nothing
to change there (S172: the audit's "flying meat" was a mis-read of $2C's tiles).
"""

import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ART_DIR = os.path.join(REPO, 'editor2', 'assets', 'foods')

# item id, food name, the game's name, plain NPC sprite id, OBJ palette, picture
FOODS = [
    (19, 'Toast', 'BeefJerky', 0x58, 6, 'toast'),
    (20, 'Apple', 'PorkChop', 0x59, 0, 'apple'),
    (21, 'Biscuit', 'Rib', 0x5A, 7, 'biscuit'),
    (22, 'BadApple', 'BadMeat', 0x5B, 5, 'badapple'),
    (23, 'Honey', 'Sirloin', 0x5C, 3, 'honey'),
]
PROP_ID = 0x5F                       # the game's meat object -> the Apple
PROP_ART = 'apple'
FIRST_ID, LAST_ID = 0x58, 0x5F       # the regions' span (NpcSheetGfxTable / NpcSpritePalTable)
SHEET_ENTRY = 23                     # bank $77 $4001 table rows 23-27 = the sheets
SHEET_TILES = 16                     # a plain NPC sheet = 16 tiles (256 B DMA)

# The original bytes of the two regions (ROM: $2B8F-$2B9E, $05:$41AA-$41B1)
VANILLA_SHEETS = {0x58: 0x313A, 0x59: 0x313A, 0x5A: 0x313A, 0x5B: 0x313A, 0x5C: 0x313A,
                  0x5D: 0x313A, 0x5E: 0x2F00, 0x5F: 0x2E19}
VANILLA_PALS = {0x58: 2, 0x59: 2, 0x5A: 2, 0x5B: 2, 0x5C: 2, 0x5D: 2, 0x5E: 2, 0x5F: 0}
SPRITE_LABELS = {0x58: "unused: $50's sheet and frames", 0x59: "unused: $50's sheet and frames",
                 0x5A: "unused: $50's sheet and frames", 0x5B: "unused: $50's sheet and frames",
                 0x5C: "unused: $50's sheet and frames", 0x5D: "unused: $50's sheet and frames",
                 0x5E: 'Terry as an NPC', 0x5F: 'the meat (an object, one frame)'}

# The field OBJ palettes ($17:$5615): colour 1 cream, 2 the accent, 3 black
PALETTE_NAMES = ['red', 'green', 'light blue', 'amber', 'purple', 'grey', 'orange', 'brown']


class FoodsError(ValueError):
    pass


def _gd(prj_or_data):
    data = getattr(prj_or_data, 'data', prj_or_data) or {}
    return data.get('gamedata') or {}


def enabled(prj_or_data):
    """True when the project has the foods tick on (gamedata.foods)."""
    v = _gd(prj_or_data).get('foods', False)
    return v is True


def check(prj):
    """(errors, warnings): the value's type; a food sprite placed while the tick is off."""
    errors, warnings = [], []
    v = _gd(prj).get('foods', False)
    if not isinstance(v, bool):
        errors.append("gamedata.foods: true (the foods instead of the meats) or false")
        return errors, warnings
    fa = _gd(prj).get('food_art')
    if fa is not None:
        if not isinstance(fa, dict):
            errors.append("gamedata.food_art: an object {picture: 16 rows}")
        else:
            for k, rows in fa.items():
                if k not in ART_NAMES:
                    errors.append(f"gamedata.food_art: no food picture '{k}' "
                                  f"(pictures: {', '.join(ART_NAMES)})")
                    continue
                try:
                    grid_from_rows(rows, f'gamedata.food_art.{k}')
                except FoodsError as e:
                    errors.append(str(e))
    if not v:
        for where in food_sprite_uses(prj):
            warnings.append(f"{where}: sprite ${where.sprite:02X} is a FOOD sprite — with "
                            "\"Foods instead of meats\" off it shows Terry's head in bed "
                            "(the game's unused id); tick Foods on the Items tab or pick "
                            "another sprite")
    return errors, warnings


class _Use(str):
    sprite = 0


def _sid(v):
    if isinstance(v, bool):
        return None
    if isinstance(v, int):
        return v
    try:
        t = str(v).strip()
        return int(t[1:], 16) if t.startswith('$') else int(t, 0)
    except (TypeError, ValueError):
        return None


def food_sprite_uses(prj):
    """[_Use('room "x" screen s: NPC n')] of the project's NPCs drawn with $58-$5C."""
    out = []
    data = getattr(prj, 'data', prj) or {}
    ids = {f[3] for f in FOODS}
    for r in ((data.get('custom') or {}).get('rooms') or []):
        if not isinstance(r, dict):
            continue
        scrs = r.get('screens') or {}
        items = scrs.items() if isinstance(scrs, dict) else enumerate(scrs)
        for key, scr in items:
            if not isinstance(scr, dict):
                continue
            lists = [scr.get('npcs') or []]
            for st in scr.get('states') or []:
                if isinstance(st, dict):
                    lists.append(st.get('npcs') or [])
            for lst in lists:
                for k, n in enumerate(lst):
                    if not isinstance(n, dict) or n.get('kind', 'npc') != 'npc':
                        continue
                    sid = _sid(n.get('sprite'))
                    if sid in ids:
                        u = _Use(f"room \"{r.get('name') or r.get('id')}\" screen {key}: NPC {k}")
                        u.sprite = sid
                        out.append(u)
    return out


# ------------------------------------------------------------------ names
def item_names(prj_or_data):
    """{item id: food name} when the tick is on, else {}."""
    return {f[0]: f[1] for f in FOODS} if enabled(prj_or_data) else {}


# S172 r3 (user: "I want description to reflect strength (Tames monsters a little, tames
# monsters a moderate amount, tames monsters a lot, tames monsters greatly)"): each food its
# own bag description (the game's five meats share ItemDesc_19 "Tames monsters"); two rows of
# at most 18 letters, the strength in the order of the battle power (+10 / +30 / +100 / +400).
DESCRIPTIONS = {19: 'Tames monsters\na little',            # Toast   +10
                20: 'Tames monsters\na moderate amount',   # Apple   +30
                21: 'Tames monsters\na lot',               # Biscuit +100
                22: 'Tames monsters\nbut poisons them',    # BadApple +5, poison
                23: 'Tames monsters\ngreatly'}             # Honey   +400


def text_defaults(prj_or_data):
    """{(source, key): markup} the tick supplies (gametext.edits layers them under the
    project's own edits): the five names and (r3) the five descriptions."""
    if not enabled(prj_or_data):
        return {}
    out = {('item_name', str(i)): n for i, n in item_names(prj_or_data).items()}
    out.update({('item_description', str(i)): t for i, t in DESCRIPTIONS.items()})
    return out


# ------------------------------------------------------------------ pictures
def art_path(name):
    return os.path.join(ART_DIR, f'{name}.png')


def obj_palette(p, rom=None):
    """[(r, g, b) x 4] of field OBJ palette p ($17:$5615 + 8p)."""
    R = rom or _rom()
    o = 0x17 * 0x4000 + 0x5615 - 0x4000 + 8 * p
    out = []
    for c in range(4):
        w = R[o + 2 * c] | R[o + 2 * c + 1] << 8
        out.append(((w & 31) * 255 // 31, ((w >> 5) & 31) * 255 // 31,
                    ((w >> 10) & 31) * 255 // 31))
    return out


_ROM = None
# The field OBJ palettes as RGB555 ($17:$5615, 8 x 4 words) — so the module needs no ROM
OBJ_PALETTES_555 = [
    (0x35AD, 0x4B7F, 0x009F, 0x0042), (0x35AD, 0x4B7F, 0x1720, 0x0042),
    (0x7C00, 0x4B7F, 0x7DAB, 0x0042), (0x7C00, 0x4B7F, 0x02FF, 0x0042),
    (0x36B9, 0x4B7F, 0x58B6, 0x0042), (0x7C00, 0x4B7F, 0x420F, 0x0042),
    (0x7C00, 0x4B7F, 0x021F, 0x0042), (0x7C00, 0x4B7F, 0x2218, 0x0042),
]


def _rom():
    """The 8 field OBJ palettes as a fake ROM slice (no ROM file needed)."""
    global _ROM
    if _ROM is None:
        b = bytearray(0x17 * 0x4000 + 0x5615 - 0x4000 + 64)
        o = 0x17 * 0x4000 + 0x5615 - 0x4000
        for p, ws in enumerate(OBJ_PALETTES_555):
            for c, w in enumerate(ws):
                b[o + 8 * p + 2 * c] = w & 0xFF
                b[o + 8 * p + 2 * c + 1] = w >> 8
        _ROM = bytes(b)
    return _ROM


def rgb(p):
    return obj_palette(p)


def default_picture(name, pal):
    """16 x 16 colour indices (0 = transparent, 1 cream, 2 accent, 3 black) of the editor's
    default picture (editor2/assets/foods/<name>.png) — each opaque pixel matched to the
    nearest colour 1-3 of OBJ palette pal."""
    from PIL import Image
    path = art_path(name)
    try:
        im = Image.open(path).convert('RGBA')
    except OSError as e:
        raise FoodsError(f"the food picture {os.path.relpath(path, REPO)}: {e}") from None
    if im.size != (16, 16):
        raise FoodsError(f"{os.path.relpath(path, REPO)}: {im.size[0]} x {im.size[1]} — a "
                         "food picture is 16 x 16")
    cols = obj_palette(pal)[1:]
    px = im.load()
    out = []
    for y in range(16):
        row = []
        for x in range(16):
            r, g, b, a = px[x, y]
            if a < 128:
                row.append(0)
                continue
            row.append(1 + min(range(3), key=lambda i: sum((u - v) ** 2 for u, v in
                                                           zip((r, g, b), cols[i]))))
        out.append(row)
    return out


ART_NAMES = [f[5] for f in FOODS]


def art_rows(prj_or_data):
    """{picture name: [16 strings of 16 digits 0-3]} the project drew (gamedata.food_art)."""
    v = _gd(prj_or_data).get('food_art') or {}
    return v if isinstance(v, dict) else {}


def grid_from_rows(rows, what='gamedata.food_art'):
    if not isinstance(rows, list) or len(rows) != 16 or not all(
            isinstance(r, str) and len(r) == 16 and set(r) <= set('0123') for r in rows):
        raise FoodsError(f"{what}: 16 rows of 16 colour numbers 0-3 (0 = see-through, "
                         "1 cream, 2 the food's colour, 3 black)")
    return [[int(ch) for ch in r] for r in rows]


def rows_from_grid(grid):
    return [''.join(str(int(v)) for v in row) for row in grid]


def picture(name, pal, prj_or_data=None):
    """The food's picture as 16 x 16 colour indices: the project's own drawing
    (gamedata.food_art.<name>) or the editor's default."""
    own = art_rows(prj_or_data).get(name) if prj_or_data is not None else None
    if own is not None:
        return grid_from_rows(own, f'gamedata.food_art.{name}')
    return default_picture(name, pal)


def tile_bytes(grid, tx, ty):
    """The 16 bytes (2bpp) of the 8 x 8 tile at (tx, ty) of a 16 x 16 grid."""
    out = bytearray()
    for r in range(8):
        lo = hi = 0
        for c in range(8):
            v = grid[ty * 8 + r][tx * 8 + c]
            lo |= (v & 1) << (7 - c)
            hi |= (v >> 1) << (7 - c)
        out += bytes([lo, hi])
    return bytes(out)


def sheet(name, pal, prj_or_data=None):
    """The 256-byte NPC sheet: tiles 0-3 = top-left, top-right, bottom-left, bottom-right (the
    object frame's pieces, bank $05 $6E0B / $4141), tiles 4-15 empty."""
    return icon_bytes(name, pal, prj_or_data) + bytes(16 * (SHEET_TILES - 4))


def icon_bytes(name, pal, prj_or_data=None):
    """The 64-byte pickup icon (4 tiles: TL, TR, BL, BR — the floor item's 2 x 2)."""
    g = picture(name, pal, prj_or_data)
    return tile_bytes(g, 0, 0) + tile_bytes(g, 1, 0) + tile_bytes(g, 0, 1) + tile_bytes(g, 1, 1)


def _encode(data, what):
    from dwm.sprite_codec import decode, encode_safe
    best = None
    for lit in (False, True):
        try:
            s_ = encode_safe(data, literal_only=lit)
        except ValueError:
            continue
        if best is None or len(s_) < len(best):
            best = s_
    if best is None or decode(best) != data:
        raise FoodsError(f"internal: the {what} does not encode")
    return best


def stream(name, pal, prj_or_data=None):
    """The NPC sheet as a gfx stream (the ROM0 DecompressTileLayout format)."""
    return _encode(sheet(name, pal, prj_or_data), f'{name} sheet')


def icon_stream(name, pal, prj_or_data=None):
    """The pickup icon as a gfx stream (64 bytes decoded)."""
    return _encode(icon_bytes(name, pal, prj_or_data), f'{name} pickup icon')


ICON_ENTRY = 28                      # bank $77 $4001 rows 28-32 = the pickup icons


def icon_gfx_id(k):
    return 0x7700 | (ICON_ENTRY + k)


def gfx_id(k):
    """gfx-ID of the k-th food's sheet (bank $77, $4001 row 23 + k)."""
    return 0x7700 | (SHEET_ENTRY + k)


def sprites(prj_or_data=None):
    """{sprite id: (picture name, OBJ palette, food name)} the tick adds (on: $58-$5C + $5F)."""
    out = {f[3]: (f[5], f[4], f[1]) for f in FOODS}
    apple = next(f for f in FOODS if f[5] == PROP_ART)
    out[PROP_ID] = (PROP_ART, apple[4], f'{apple[1]} (the game\'s meat prop)')
    if prj_or_data is not None and not enabled(prj_or_data):
        return {}
    return out


def _sheet_word(i, on):
    if not on:
        return VANILLA_SHEETS[i]
    for k, f in enumerate(FOODS):
        if f[3] == i:
            return gfx_id(k)
    if i == PROP_ID:
        return gfx_id(next(k for k, f in enumerate(FOODS) if f[5] == PROP_ART))
    return VANILLA_SHEETS[i]


def _pal(i, on):
    if not on:
        return VANILLA_PALS[i]
    s = sprites()
    return s[i][1] if i in s else VANILLA_PALS[i]


# ------------------------------------------------------------------ emitters
def emit_sheets(prj, warnings):
    """Region npc_food_sheets (ROM0 NpcSheetGfxTable ids $58-$5F)."""
    on = enabled(prj)
    s = sprites()
    out = []
    for i in range(FIRST_ID, LAST_ID + 1):
        w = _sheet_word(i, on)
        tag = (f"S172 foods: {s[i][2]}" if on and i in s else SPRITE_LABELS[i])
        out.append(f"    dw ${w:04X}   ; [${i:02X}] {tag}")
    return "\n".join(out) + "\n"


def emit_pals(prj, warnings):
    """Region npc_food_pals (bank $05 NpcSpritePalTable ids $58-$5F)."""
    on = enabled(prj)
    s = sprites()
    out = []
    for i in range(FIRST_ID, LAST_ID + 1):
        p = _pal(i, on)
        tag = (f"S172 foods: {s[i][2]} ({PALETTE_NAMES[p]})" if on and i in s else SPRITE_LABELS[i])
        out.append(f"    db ${p:02x}   ; [${i:02X}] {tag}")
    return "\n".join(out) + "\n"


def bank77_lines(prj):
    """NpcStaticIds (entry 14 NpcDrawPlain holds these on frame 0), the five NPC sheets
    (FoodSheet0-4, rows 23-27) and (S172 r2) the gate pickup icons: FoodIconCount,
    FoodIconAttr, FoodIcon0-4 (rows 28-32; entries 33 FoodIconsLoad / 34 FoodIconDraw)."""
    on = enabled(prj)
    out = ["; " + "=" * 77,
           "; FOODS (S172, generated by editor2/core/foods.py from gamedata.foods /",
           "; gamedata.food_art, PROJECT_COMPILER §2.78): the ids NpcDrawPlain holds on frame 0,",
           "; the foods' NPC sheets (gfx-IDs $7717-$771B = rows 23-27) and gate pickup icons",
           "; (gfx-IDs $771C-$7720 = rows 28-32; FoodIconsLoad / FoodIconDraw).",
           "; " + "=" * 77,
           "NpcStaticIds:   ; plain NPC sprite ids drawn with frame 0 only ($FF ends)"]
    if on:
        ids = [f[3] for f in FOODS] + [PROP_ID]
        out.append("    db " + ", ".join(f"${i:02x}" for i in ids) + ", $ff")
        out.append(f"FoodIconCount:   ; the foods with their own pickup icon (0 = the game's)")
        out.append(f"    db {len(FOODS)}")
        out.append("FoodIconAttr:   ; per food: its OBJ palette | $08 (the icon is in VRAM bank 1)")
        out.append("    db " + ", ".join(f"${f[4] | 8:02x}" for f in FOODS)
                   + "   ; " + ", ".join(f"{f[1]} {PALETTE_NAMES[f[4]]}" for f in FOODS))
        own = art_rows(prj)
        for k, f in enumerate(FOODS):
            st = stream(f[5], f[4], prj)
            tag = 'drawn in the project' if f[5] in own else 'the default picture'
            out.append(f"FoodSheet{k}:   ; gfx-ID ${gfx_id(k):04X}: {f[1]} NPC sheet (sprite ${f[3]:02X}, "
                       f"OBJ palette {f[4]} {PALETTE_NAMES[f[4]]}; {tag}; {len(st)} B)")
            for j in range(0, len(st), 16):
                out.append("    db " + ", ".join(f"${x:02x}" for x in st[j:j + 16]))
        for k, f in enumerate(FOODS):
            st = icon_stream(f[5], f[4], prj)
            out.append(f"FoodIcon{k}:   ; gfx-ID ${icon_gfx_id(k):04X}: {f[1]} pickup icon "
                       f"(item {f[0]}; {len(st)} B)")
            for j in range(0, len(st), 16):
                out.append("    db " + ", ".join(f"${x:02x}" for x in st[j:j + 16]))
    else:
        out.append("    db $ff   ; gamedata.foods off: none (the game's draw)")
        out.append("FoodIconCount:   ; off: the game's pickup icons")
        out.append("    db 0")
        out.append("FoodIconAttr:")
        out.append("    db " + ", ".join("$00" for _ in FOODS))
        for k in range(len(FOODS)):
            out.append(f"FoodSheet{k} EQU $0000   ; off: never read (NpcSheetGfxTable is the game's)")
            out.append(f"FoodIcon{k} EQU $0000   ; off: never read (FoodIconCount = 0)")
    return out


REGIONS = [('npc_food_sheets', 'patches/bank_000.asm', emit_sheets, 0x00),
           ('npc_food_pals', 'patches/bank_005.asm', emit_pals, 0x05)]
