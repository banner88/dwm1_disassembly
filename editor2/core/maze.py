"""maze.py — the gate MAZE floors: how the game carves and draws them (S122,
ROADMAP P3.7b part 2 + Phase 2C; GATE_GENERATION §4 / §7 "As traced S122").

Headless (no Qt, PIL only in the render helpers). Everything is read from the
ORIGINAL ROM's tables; nothing here is guessed:

THE PIECES (what a screen of a maze floor looks like)
  A floor is a 4x4 grid of screens (`wFloorGrid` $C940). Each cell byte is
  piece·16 + variant. The PIECE (0-15) is a set of openings — bit 8 up,
  4 down, 2 left, 1 right (`MazePieceTable` $16:$7055: [openings, piece,
  weight class, 0] × 16, $FF) — piece 15 = no openings = an empty (wall)
  screen. The VARIANT (0-11 rolled, 12 = the plain shape of shape mode 1)
  picks one of 13 drawings of that piece. The drawing is an ordinary screen
  layout stream (`MazeScreenTable` $16:$7896, 256 × [layout id, bank] — the
  same [step id, tileset bank] pair a normal room's step entry holds, read by
  bank $16 entry 9 `LoadFloorDataPointer` = bank $0B ReadStepBlock's gate
  path) plus an attribute stream (`GateAttrTable_A` $17:$5215, 256 ×
  [attr id, bank]). Shape mode 2 floors are copied whole from one of 21
  hand-made 4x4 patterns (`MazePatterns` $16:$7736) and draw their cells
  from the second pair of tables ($16:$7A96 / `GateAttrTable_B` $17:$5415).
  The screens are SHARED by all 16 floor types ("themes"): a theme only
  changes the tile sheet (gate tileset table ROM0 $2A5D: bank $28 id = the
  type, collision threshold $30) and the four BG palettes
  (`FloorPalettePtrTable` $17:$51F5[type]). Piece attributes use palettes
  0-3 only (census of all 275 attr streams, S122) — so a custom room, which
  loads slots 0-3, shows a theme in its exact colours.

THE CARVE (label16_605b, bank $16 entry 6) — modelled exactly below:
  shape mode = [0,0,0,1,2][RNG1 mod 5]; mode 2 = a pattern; else cells are
  visited in `MazeCellOrder` ($16:$7096) order: the first gets a random piece
  that opens down and/or right (sizes < 8) or any piece but 15; the next
  `maze size` cells each get a random piece whose openings agree with the
  neighbours already placed (a neighbour opening toward the cell is
  REQUIRED, a placed neighbour not opening toward it / the grid edge is
  FORBIDDEN, an empty neighbour is free — SetBrd_6744), weighted by class
  (SetBrd_6800: class w gets 20·w / count-of-class-w); then EVERY cell is
  re-assigned the one piece that opens exactly toward its opening
  neighbours (or 15) — which closes every dead opening and keeps the floor
  connected; then each cell gets its variant (RNG mod 12; 12 in mode 1).
  Then the down-stairs (a metatile at x 2-7 / y 2-5 whose bottom-right
  tile is $30-$3B and whose 3x3 surroundings stay passable), the wandering
  NPC, the player's arrival and the floor items (`FloorTypeSelectionTable3`
  row of the gate) are placed by random tries on random screens; 64 failed
  tries regenerate the whole floor. `generate()` reproduces all of it from
  the RNG state at entry; tools/census_maze.py proves it against the game.

The RNG is the game's own 16-bit LCG (GenerateRNG $00:$3795: s·5 + $1357).
"""

from tools.decompress_tiles import decompress_lz

# ---------------------------------------------------------------- addresses
SHAPE_TABLE = 0x6056         # bank $16: 5 shape modes rolled by RNG1 mod 5
PIECE_TABLE = 0x7055         # bank $16: MazePieceTable (was "FloorTypeSortData")
CELL_ORDER = 0x7096          # bank $16: MazeCellOrder (was "FloorTypeOrderTable")
PATTERNS = 0x7736            # bank $16: MazePatterns, 21 × 16 cell bytes
N_PATTERNS = 21
NPC_CHANCE = 0x7886          # bank $16: wandering-NPC threshold by wFloorType3
ITEM_SUBTYPE = 0x7426        # bank $16: item kind -> 1 = roll a sub-kind
CONTENTS_TABLE = 0x7326      # bank $16: FloorTypeSelectionTable3 (16 B rows)
CONTENTS_ROWS = 0x7436       # bank $16: FloorLayoutData (48 B row per wFloorType3)
SCREENS_A = 0x7896           # bank $16: MazeScreenTable (shape modes 0/1)
SCREENS_B = 0x7A96           # bank $16: MazeScreenTableB (shape mode 2)
ATTR_A = 0x5215              # bank $17: GateAttrTable_A (modes 0/1)
ATTR_B = 0x5415              # bank $17: GateAttrTable_B (mode 2)
FLOOR_PAL = 0x51F5           # bank $17: FloorPalettePtrTable [type] -> 4 palettes
THEME_RECORDS = 0x2A5D       # ROM0: gate tileset records, 8 B per type
SCREEN_ORIGIN = 0x2DA7       # ROM0: per screen [x lo, x hi, y lo, y hi] pixels
THEME_BANK = 0x28            # every theme's sheet lives in bank $28 (id = type)
THEME_THRESHOLD = 0x30       # collision threshold of every theme (ROM0 $2A5D +6)
STAIR_TILES = (0x3C, 0x3D, 0x3E, 0x3F)   # bank $0B Call_00b_4309 stamps these
N_THEMES = 16
EMPTY_PIECE = 15

OPEN_UP, OPEN_DOWN, OPEN_LEFT, OPEN_RIGHT = 8, 4, 2, 1

# names of the 16 floor types — S120 pictures (extracted/gate_floor_types/)
THEME_NAMES = [
    'Grassland', 'Grey rock', 'Sand', 'Red rock (damage floor)', 'Ice blocks',
    'Purple brick', 'Purple brick (damage floor)', 'Yellow brick', 'Boulders',
    'Forest', 'Yellow brick and tiles', 'Green mountains',
    'Green mountains (damage floor)', 'Sea islands', 'Sea islands (damage floor)',
    'Snowy mountains',
]

SYSTEM_ROWS = [[0x0000, 0x6BFF, 0x7FFF, 0x0000]] * 4   # rows 4-7 of a project palette


def _b(rom, bank, addr, n):
    o = bank * 0x4000 + addr - 0x4000 if bank else addr
    return rom[o:o + n]


def rng_step(s):
    """GenerateRNG: s = wRNG1·256 + wRNG2 -> s·5 + $1357 (16 bit)."""
    return (s * 5 + 0x1357) & 0xFFFF


def div8(b, a):
    """Div8x8 bit for bit: (B quotient, A remainder); A = 0 divides by zero
    the way the loop does (quotient 255, remainder = b)."""
    acc = 0
    for _ in range(8):
        carry = b >> 7
        b = (b << 1) & 0xFF
        top = acc >> 7
        acc = ((acc << 1) | carry) & 0xFF
        if top or acc >= a:
            acc = (acc - a) & 0xFF
            b = (b + 1) & 0xFF
    return b, acc


def div16(hl, a):
    """Div16x8To16 bit for bit: (HL quotient, A remainder)."""
    acc = 0
    for _ in range(16):
        carry = hl >> 15
        hl = (hl << 1) & 0xFFFF
        top = acc >> 7
        acc = ((acc << 1) | carry) & 0xFF
        if top or acc >= a:
            acc = (acc - a) & 0xFF
            hl = (hl & 0xFF00) | ((hl + 1) & 0xFF)
    return hl, acc


class MazeHang(RuntimeError):
    """The model met a floor on which the game would spin forever (an item
    search on a screen with no free floor — never seen in the game's own
    floors; raised after a generous cap so a broken input cannot hang the
    editor or a census)."""


SPIN_CAP = 200000


def openings_text(mask):
    out = [n for b, n in ((OPEN_UP, 'up'), (OPEN_DOWN, 'down'),
                          (OPEN_LEFT, 'left'), (OPEN_RIGHT, 'right')) if mask & b]
    return ', '.join(out) if out else 'none (empty screen)'


class MazeRom:
    """The maze tables of one ROM + the exact floor generator."""

    def __init__(self, rom):
        self.rom = rom
        self.shape = list(_b(rom, 0x16, SHAPE_TABLE, 5))
        raw = _b(rom, 0x16, PIECE_TABLE, 65)
        self.piece_rows = [tuple(raw[4 * i:4 * i + 3]) for i in range(16)]
        self.piece_raw = raw
        self.order = list(_b(rom, 0x16, CELL_ORDER, 16))
        self.patterns = [list(_b(rom, 0x16, PATTERNS + 16 * i, 16))
                         for i in range(N_PATTERNS)]
        self.npc_chance = list(_b(rom, 0x16, NPC_CHANCE, 16))
        self.item_subtype = list(_b(rom, 0x16, ITEM_SUBTYPE, 16))
        self.origin = [tuple(_b(rom, 0, SCREEN_ORIGIN + 4 * i, 4)) for i in range(16)]
        self._lay = {}

    # ------------------------------------------------------------ tables
    def openings(self, piece):
        """MazePieceTable row `piece`, byte 0 (rows are in piece order)."""
        return self.piece_raw[4 * piece]

    def cell_streams(self, cell, mode=0):
        """(layout (bank, id), attr (bank, id)) of a grid cell byte."""
        st = SCREENS_B if mode == 2 else SCREENS_A
        at = ATTR_B if mode == 2 else ATTR_A
        lid, lb = _b(self.rom, 0x16, st + 2 * cell, 2)
        aid, ab = _b(self.rom, 0x17, at + 2 * cell, 2)
        return (lb, lid), (ab, aid)

    def layout_bytes(self, stream):
        if stream not in self._lay:
            res = decompress_lz(self.rom, stream[0], stream[1])
            if not res:
                raise ValueError(f'maze layout ${stream[0]:02X}:{stream[1]:02X} '
                                 'does not decompress')
            self._lay[stream] = bytes(res[0])
        return self._lay[stream]

    def cell_grids(self, cell, mode=0):
        """(tiles, attr) as 16 rows × 20 lists — the editor's layout form
        (tiles from the 32-wide layout stream, attr nibble per tile: palette
        slot + bit 3 = VRAM bank, here always 0-3)."""
        ls, as_ = self.cell_streams(cell, mode)
        lay = self.layout_bytes(ls)
        att = self.layout_bytes(as_)
        tiles = [[lay[r * 32 + c] for c in range(20)] for r in range(16)]
        attr = [[(att[r * 16 + c // 2] >> 4) & 0xF if c % 2 == 0 else att[r * 16 + c // 2] & 0xF
                 for c in range(20)] for r in range(16)]
        return tiles, attr

    def theme_record(self, t):
        r = _b(self.rom, 0, THEME_RECORDS + 8 * t, 8)
        return {'gfx_id': r[0], 'gfx_bank': r[1], 'width_px': r[2] | r[3] << 8,
                'height_px': r[4] | r[5] << 8, 'collision_threshold': r[6]}

    def theme_sheet(self, t):
        rec = self.theme_record(t)
        return bytes(decompress_lz(self.rom, rec['gfx_bank'], rec['gfx_id'])[0][:2048])

    def theme_palette_words(self, t):
        """The theme's 4 BG palettes as stored (RGB555), colours 1 and 3 as
        the engine forces them ($6BFF / $0000)."""
        p = _b(self.rom, 0x17, FLOOR_PAL + 2 * t, 2)
        ptr = p[0] | p[1] << 8
        raw = _b(self.rom, 0x17, ptr, 32)
        rows = []
        for s in range(4):
            w = [raw[8 * s + 2 * c] | raw[8 * s + 2 * c + 1] << 8 for c in range(4)]
            w[1], w[3] = 0x6BFF, 0x0000
            rows.append(w)
        return rows

    # ------------------------------------------------------- the catalogue
    def pieces(self):
        """Every screen a maze floor can show, once: [{cell, mode, piece,
        variant, openings, layout, attr}] — shape modes 0/1 (pieces 0-14 ×
        variants 0-12; piece 15 = empty) then the shape-mode-2 pattern cells.
        Duplicate drawings (same layout + attr streams) are listed once."""
        out, seen = [], set()
        for piece in range(15):
            for v in range(13):
                cell = piece * 16 + v
                ls, as_ = self.cell_streams(cell, 0)
                if (ls, as_) in seen:
                    continue
                seen.add((ls, as_))
                out.append({'cell': cell, 'mode': 0, 'piece': piece, 'variant': v,
                            'openings': self.openings(piece), 'layout': ls, 'attr': as_})
        cells_b = sorted({c for p in self.patterns for c in p if c & 0xF0 != 0xF0})
        for cell in cells_b:
            ls, as_ = self.cell_streams(cell, 2)
            if (ls, as_) in seen:
                continue
            seen.add((ls, as_))
            out.append({'cell': cell, 'mode': 2, 'piece': cell >> 4, 'variant': cell & 15,
                        'openings': None, 'layout': ls, 'attr': as_})
        return out

    # --------------------------------------------------------- the carve
    def _constraints(self, g, d):
        """SetBrd_6744: (required B, forbidden C) openings of cell d."""
        B = C = 0
        for cond, nd, nbit, want in ((d >= 4, d - 4, OPEN_DOWN, OPEN_UP),
                                     (d + 4 < 16, d + 4, OPEN_UP, OPEN_DOWN),
                                     (d & 3 != 0, d - 1, OPEN_RIGHT, OPEN_LEFT),
                                     (d & 3 != 3, d + 1, OPEN_LEFT, OPEN_RIGHT)):
            if not cond:
                C |= want
                continue
            v = g[nd]
            if v == 0xFF:
                continue
            if self.piece_raw[(4 * v) & 0xFF] & nbit:
                B |= want
            else:
                C |= want
        return B, C

    def _pick(self, s, B, C):
        """SetBrd_6800: a weighted random piece with every B opening and no
        C opening; $0F when none is left."""
        buf = []
        for (mask, pid, w) in self.piece_rows:
            if (mask & C) == 0 and (mask & B) == B:
                buf += [pid, w]
        buf += [0xFF, 0xFF]
        counts = [0] * 5
        i = 1
        while buf[i] != 0xFF:
            counts[buf[i]] = (counts[buf[i]] + 1) & 0xFF
            i += 2
        share = [0] + [div8(20 * w, counts[w])[0] for w in range(1, 5)]
        i, tot = 1, 0
        while buf[i] != 0xFF:
            tot = (share[buf[i]] + tot) & 0xFF
            buf[i] = tot
            i += 2
        s = rng_step(s)
        roll = div16(((s & 0xFF) << 8) | (s >> 8), tot)[1] if tot else 0
        i = 1
        while True:
            if buf[i] == 0xFF:
                return s, 0x0F
            if buf[i] >= roll:
                return s, buf[i - 1]
            i += 2

    def carve(self, s, size):
        """The grid only: (shape mode, 16 cell bytes, RNG state after)."""
        s = rng_step(s)
        mode = self.shape[div8(s >> 8, 5)[1]]
        if mode == 2:
            s = rng_step(s)
            return mode, list(self.patterns[div8(s >> 8, N_PATTERNS)[1]]), s
        g = [0xFF] * 16
        b = (size + 1) & 0xFF
        if b < 9:
            B = s >> 8
            while True:
                B = (B + 1) & 0xFF
                if B & 5:
                    break
            B, C = B & 5, 0
        else:
            B = C = 0
        while True:
            s, p = self._pick(s, B, C)
            if p != 0x0F:
                break
        g[self.order[0]] = p
        k, b = 1, (b - 1) & 0xFF
        while True:
            cell = self.order[k & 15]   # sizes 1-15 never pass the 16-byte table
            B, C = self._constraints(g, cell)
            if B == 0:
                g[cell] = 0xFF
            else:
                s, g[cell] = self._pick(s, B, C)
            k += 1
            b = (b - 1) & 0xFF
            if b == 0:
                break
        for cell in self.order:
            B, C = self._constraints(g, cell)
            if B == 0:
                g[cell] = 0x0F
            else:
                s, g[cell] = self._pick(s, B, B ^ 0x0F)
        for i in range(16):
            if mode == 1:
                v = 12
            else:
                s = rng_step(s)
                v = div8(s >> 8, 12)[1]
            g[i] = ((((g[i] << 4) | (g[i] >> 4)) & 0xFF) + v) & 0xFF
        return mode, g, s

    # ---------------------------------------------------------- placement
    def _tile(self, g, mode, scr, x, y):
        lay = self.layout_bytes(self.cell_streams(g[scr], mode)[0])
        return lay[(y >> 3) * 32 + ((x >> 3) & 0x1F)]

    @staticmethod
    def _walk_class(t, classes):
        return (t >> 2) in classes

    def _pick_screen(self, s, g):
        s = rng_step(s)
        b = s >> 8
        while True:
            b = (b + 1) & 0xFF
            if g[b & 15] & 0xF0 != 0xF0:
                return s, b & 15

    def _next_screen(self, g, scr):
        b = scr
        while True:
            b = (b + 1) & 0xFF
            if g[b & 15] & 0xF0 != 0xF0:
                return b & 15

    def _place(self, s, g, mode, xr, xa, yr, ya, classes, limit=True):
        """CallBrd_66ae / 6585 / 661b / 63af: a screen, then random metatile
        positions (x = (RNG1 mod xr + xa)·16 + 8 …) until the bottom-right
        tile's class is in `classes`; 64 failures move to the next screen
        (63af has no limit)."""
        s, scr = self._pick_screen(s, g)
        spins = 0
        while True:
            n = 0x40
            while True:
                spins += 1
                if spins > SPIN_CAP:
                    raise MazeHang(f'no spot on screen {scr}')
                s = rng_step(s)
                x = (div8(s >> 8, xr)[1] + xa) * 16 + 8
                s = rng_step(s)
                y = (div8(s >> 8, yr)[1] + ya) * 16 + 8
                if self._walk_class(self._tile(g, mode, scr, x, y), classes):
                    return s, scr, x, y
                if not limit:
                    continue
                n -= 1
                if n == 0:
                    break
            scr = self._next_screen(g, scr)

    def _passable(self, g, mode, scr, x, y):
        """Jump_016_6c96: False when an object at (x, y) would cut the
        walkable ring of its 3x3 surroundings (1 = blocked neighbour)."""
        def blk(dx, dy):
            return 0 if self._walk_class(self._tile(g, mode, scr, x + dx, y + dy),
                                         (0x0C, 0x0D, 0x0E)) else 1
        b0, b1, b2 = blk(-16, -16), blk(0, -16), blk(16, -16)
        b3, b5 = blk(-16, 0), blk(16, 0)
        b6, b7, b8 = blk(-16, 16), blk(0, 16), blk(16, 16)
        if b3 and (b2 or b5 or b8):
            return False
        if b7 and (b0 or b1 or b2):
            return False
        if b1 and (b6 or b7 or b8):
            return False
        if b5 and (b0 or b3 or b6):
            return False
        if b0 and ((not b1 and b2) or (not b3 and b6) or b8):
            return False
        if b2 and ((not b1 and b0) or (not b5 and b8) or b6):
            return False
        if b6 and ((not b3 and b0) or (not b7 and b8) or b2):
            return False
        if b8 and ((not b5 and b2) or (not b7 and b6) or b0):
            return False
        return True

    def _select(self, s, row):
        """SelectFloorType over a cumulative-percent row."""
        s = rng_step(s)
        c = div16(((s & 0xFF) << 8) | (s >> 8), 100)[1]
        i = -1
        while True:
            i += 1
            a = row[i]
            if a == 0:
                continue
            if a == 0x64 or a >= c:
                return s, i

    def generate(self, s, size, contents_row, progress=0, npc_state=0):
        """The whole floor as label16_605b builds it, from the RNG state at
        its entry. size = [$C93D] (1-15), contents_row = wFloorType3,
        progress = [$CAB4], npc_state = [$C92D] on entry. Returns a dict of
        everything the game writes (see tools/census_maze.py)."""
        row = list(_b(self.rom, 0x16, CONTENTS_TABLE + 16 * contents_row, 16))
        item_rows = list(_b(self.rom, 0x16, CONTENTS_ROWS + 48 * contents_row, 48))
        regen = 0
        while True:
            mode, g, s = self.carve(s, size)
            res = self._placements(s, g, mode, row, item_rows, contents_row,
                                   progress, npc_state)
            if res is not None:
                res.update(mode=mode, grid=g, regenerated=regen)
                return res
            regen += 1
            s = self._regen_state

    def _placements(self, s, g, mode, row, item_rows, ft3, progress, npc_state):
        tries = 0x40
        while True:                                   # Jump_016_616c: stairs
            tries -= 1
            if tries == 0:
                self._regen_state = s
                return None
            s, st_scr, sx, sy = self._place(s, g, mode, 6, 2, 4, 2, (0x0C, 0x0D, 0x0E))
            if self._passable(g, mode, st_scr, sx, sy):
                break
        tries = 0x40
        while True:                                   # jr_016_620a: the NPC
            tries -= 1
            if tries == 0:
                self._regen_state = s
                return None
            s, n_scr, nx, ny = self._place(s, g, mode, 8, 1, 6, 1, (0x0C, 0x0D, 0x0E))
            if n_scr != st_scr:
                break
        c92d = npc_state
        if progress in (0, 1):
            c92d = 0
        npc = {'screen': n_scr, 'x': nx, 'y': ny, 'kind': c92d, 'sub': 0}
        keep = False
        if c92d in (4, 5, 6, 7):
            s = rng_step(s)
            keep = not ((s >> 8) & 1)
        else:
            s = rng_step(s)
            if (s >> 8) < self.npc_chance[ft3]:
                s = rng_step(s)
                npc['sub'] = div8(s >> 8, 5)[1]
                s = rng_step(s)
                npc['kind'] = (s >> 8) & 3
                keep = True
        if not keep:
            npc = None
        npc_scr = npc['screen'] if npc else 0xFF
        tries = 0x40
        while True:                                   # Jump_016_62d8: arrival
            tries -= 1
            if tries == 0:
                self._regen_state = s
                return None
            s, p_scr, px, py = self._place(s, g, mode, 8, 1, 6, 1, (0x0C, 0x0D))
            if p_scr == st_scr:
                s, p_scr, px, py = self._place(s, g, mode, 8, 1, 6, 1, (0x0C, 0x0D))
            if p_scr == st_scr and (px, py) == (sx, sy):
                continue
            if p_scr == npc_scr:
                continue
            break
        # floor items (SaveBrd_6432 × count)
        count = (row[9] + div8(s >> 8, (row[10] + 1) & 0xFF)[1]) & 0xFF
        hit = row[11]
        if sum(1 for c in g if c & 0xF0 != 0xF0) < 6:
            count = (count >> 1) & 0x7F
        per = [0] * 16
        items = []
        for _ in range(count):
            s, it = self._item(s, g, mode, row, item_rows, hit, per, items,
                               st_scr, (sx, sy), p_scr, (px, py), npc_scr)
            if it is not None:
                items.append(it)
        return {'stairs': (st_scr, sx, sy), 'npc': npc, 'arrival': (p_scr, px, py),
                'items': items, 'rng': s}

    def _item(self, s, g, mode, row, item_rows, hit, per, items, st_scr, st_pos,
              p_scr, p_pos, npc_scr):
        s, kind = self._select(s, row)
        s = rng_step(s)
        if div16(((s & 0xFF) << 8) | (s >> 8), 100)[1] < hit:
            kind = (kind + 0x10) & 0xFF
        n = 0x10
        while True:
            n -= 1
            if n == 0:
                return s, None
            s, scr, x, y = self._place(s, g, mode, 8, 1, 6, 1, (0x0C, 0x0D), limit=False)
            if scr == st_scr:
                s, scr, x, y = self._place(s, g, mode, 8, 1, 6, 1, (0x0C, 0x0D), limit=False)
            if scr == p_scr:
                s, scr, x, y = self._place(s, g, mode, 8, 1, 6, 1, (0x0C, 0x0D), limit=False)
            if per[scr]:
                s, scr, x, y = self._place(s, g, mode, 8, 1, 6, 1, (0x0C, 0x0D), limit=False)
            if kind & 0xF0 and not self._passable(g, mode, scr, x, y):
                continue
            if scr == st_scr and (x, y) == st_pos:
                continue
            if scr == p_scr and (x, y) == p_pos:
                continue
            if any(it['screen'] == scr and it['y'] == y for it in items):
                continue                          # CalcBrd_6924: screen + Y only
            if scr == npc_scr:
                continue
            if per[scr] == 3:
                continue
            per[scr] += 1
            sub = self.item_subtype[kind & 0x0F]
            if sub == 1:
                s, sub = self._select(s, item_rows)
            return s, {'kind': kind, 'sub': sub, 'screen': scr, 'x': x, 'y': y}

    # ---------------------------------------------------------- metatiles
    def metatiles(self):
        """Every 2x2 metatile (tiles + per-subtile palette) the maze screens
        use, most used first: [{'tiles': [tl,tr,bl,br], 'pal': [..4], 'uses': n}]."""
        from collections import Counter
        cnt = Counter()
        for p in self.pieces():
            tiles, attr = self.cell_grids(p['cell'], p['mode'])
            for cy in range(8):
                for cx in range(10):
                    r, c = 2 * cy, 2 * cx
                    key = ((tiles[r][c], tiles[r][c + 1], tiles[r + 1][c], tiles[r + 1][c + 1]),
                           (attr[r][c] & 7, attr[r][c + 1] & 7,
                            attr[r + 1][c] & 7, attr[r + 1][c + 1] & 7))
                    cnt[key] += 1
        return [{'tiles': list(k[0]), 'pal': list(k[1]), 'uses': n}
                for k, n in cnt.most_common()]


def theme_of_origin(origin):
    """A sheet whose origin is (bank $28, id 0-15) is a gate theme (no
    ordinary room uses those sheets — S122 ROM check): -> the type, else None."""
    if not origin:
        return None
    b, g = origin
    return g if b == THEME_BANK and 0 <= g < N_THEMES else None


def theme_palette_rows(rom, t):
    """8 × 4 RGB555 words for a project palette that shows theme t: the
    theme's four palettes, then the system rows (custom rooms load 0-3)."""
    return MazeRom(rom).theme_palette_words(t) + [list(r) for r in SYSTEM_ROWS]
