"""page2.py — PAGE 2: the second 128 tiles of a room's tileset (S168, ROADMAP P3.3g).

User (S168): "more tiles per room"; "Different rooms will have mostly different tilesets …
having access to diverse tiles in a given room is the most important thing"; "GBC only yes
absolutely"; "Include animation".

The hardware (ROOM_DATA_FORMAT "Page 2: the second 128 tiles (S168)"): a room's sheet is
128 tiles in VRAM bank 0 $9000-$97FF (map ids $00-$7F). VRAM BANK 1's $9000-$97FF holds
128 more, drawn by every background cell whose GBC attribute has bit 3. The original game
never writes VRAM bank 1's tile area nor sets attribute bit 3 (tools/census_vram_bank1.py).

The data (PROJECT_COMPILER §2.76):
  * a tileset's raw2bpp file is 2048 bytes (page 1) or 4096 (page 1 + page 2);
  * a layout's tile grid holds a TILE VALUE per cell: $00-$7F page-1 tile, $80-$FF the
    shared font / HUD tiles (VRAM bank 0 $8800-$8FFF, as before), $100-$17F page-2 tile
    0-127. The attr grid keeps the palette (0-7). The page is a property of the TILE, so a
    state shares its attr grid with other states exactly as before: the compiler writes
    attribute bit 3 into a DERIVED attr stream for each (attr grid, tile grid) pair that
    has page-2 cells (`derived_attr_items`) — a project without page 2 compiles to the
    same bytes as before S168;
  * the editor's SLOT index of a sheet: 0-127 page 1, 128-255 page 2 (slot s's bytes at
    s * 16 of the 4096-byte sheet); `slot_of` / `value_of` convert;
  * walkability is decided by the cell's bottom-right tile NUMBER (map byte < threshold =
    wall, S94): page-2 tile n walks like page-1 tile n — `is_wall`.

The engine: page-2 BANKS ($80+, after every other kind — `plan`): the first one (the HOME)
holds `Page2Room` (templates/page2_home.asm: the directory lookup at every room sheet load,
bank $0B regions memorial_tiles_0 / _1) + the directory; every page-2 bank holds the
copier `Page2Copy_P<bank>` (templates/page2_copy.asm) and its sheets, RAW (2048 B each,
ALIGN[8]) — the copy is General-Purpose DMA into VRAM bank 1, which the LZ decoder cannot
target. `wPage2On` (patches/wram.asm) = the room draws page 2: bank $73 BoxAttrActive and
bank $77 PushAttrActive then give the text boxes / windows bank 0 + palette 7 under their
letters, as in a free-colour room. Own tile animations reach page-2 slots (tileanim.py:
bit 0 of the destination word = VRAM bank 1).
Pure data + text; no Qt.
"""
from . import formats as F

PAGE2 = 0x100                 # tile value of page-2 tile 0
PAGE2_END = 0x180
SLOTS = 256                   # slots of a tileset with page 2
SHEET_BYTES = 2048
BANK_BYTES = 0x4000
SHEETS_PER_BANK = 7           # 7 x 2048 B + the copier + ALIGN[8] padding <= 16 KB
COPY_CODE_BYTES = 200         # page2_copy.asm assembled (generous)
HOME_CODE_BYTES = 110         # page2_home.asm assembled (generous)
DIR_ROW = 4                   # db region, map id, bank, index


class Page2Error(ValueError):
    pass


# ---------------------------------------------------------------- tile values
def is_page2(v):
    return PAGE2 <= int(v) < PAGE2_END


def is_common(v):
    """A shared font / HUD tile ($80-$FF): the same in every room, not a sheet slot."""
    return 0x80 <= int(v) < 0x100


def slot_of(v):
    """Tile value -> sheet slot (0-127 page 1, 128-255 page 2); None for a shared tile."""
    v = int(v)
    if v < 0x80:
        return v
    if PAGE2 <= v < PAGE2_END:
        return 0x80 + (v - PAGE2)
    return None


def value_of(slot):
    """Sheet slot (0-255) -> tile value ($00-$7F, $100-$17F)."""
    slot = int(slot)
    return slot if slot < 0x80 else PAGE2 + (slot - 0x80)


def byte_of(v):
    """The map byte the game stores for a tile value."""
    return int(v) & 0xFF


def page_bit(v):
    """The attribute bit a tile value needs (8 = VRAM bank 1)."""
    return 8 if is_page2(v) else 0


def is_wall(slot, threshold):
    """The engine compares the map BYTE with the threshold (S94): page-2 tile n walks
    like page-1 tile n."""
    return (int(slot) & 0x7F) < int(threshold)


def label(v):
    """A tile value for people: '$1A' (page 1 / a shared tile) or 'p2 $1A'."""
    v = int(v)
    return f'p2 ${v - PAGE2:02X}' if is_page2(v) else f'${v:02X}'


def walkable(v, threshold):
    """Is a cell whose bottom-right tile VALUE is v walkable? The engine compares the
    MAP BYTE with the threshold (S94): page-2 tile n like page-1 tile n."""
    return (int(v) & 0xFF) >= int(threshold)


def slot_key(v):
    """The sheet slot a tile value stands for in the editor's usage / remap bookkeeping:
    a page-2 value -> 128 + n; any other value -> v & 0x7F (the pre-S168 rule, kept so a
    project without page 2 counts exactly as before)."""
    v = int(v)
    return 0x80 + (v - PAGE2) if v >= PAGE2 else v & 0x7F


def remap_value(v, old, new):
    """Tile value v with sheet slot `old` moved to slot `new` (0-255)."""
    v = int(v)
    if slot_key(v) != old:
        return v
    if v < PAGE2 and v & 0x80:            # a shared tile matched by the old & 0x7F rule
        return (v & 0x80) | new if new < 0x80 else v
    return value_of(new)


def wall_first(free, thr):
    """Free WALL slots in the order the editor takes them: page 1 from the top of the
    wall side down, then page 2 the same way."""
    w = [s for s in free if is_wall(s, thr)]
    return sorted(w, key=lambda s: (s >= 0x80, -s))


def walk_first(free, thr):
    """Free WALKABLE slots in the order the editor takes them: page 1 upward, then page 2."""
    k = [s for s in free if not is_wall(s, thr)]
    return sorted(k, key=lambda s: (s >= 0x80, s))


def pick_order(free, thr, want_wall, strict, walls_down=True):
    """Free slots in the order an import takes them (S168). The bottom-right subtile
    (strict) must sit on its side: page 1, then page 2. Any other subtile prefers its
    side on page 1, then page 1's other side, then page 2 — page 2 opens only when page
    1 is full. walls_down=False: wall slots upward (the Draw tab's pre-S168 order)."""
    def walls(f):
        return wall_first(f, thr) if walls_down else sorted(
            [x for x in f if is_wall(x, thr)], key=lambda x: (x >= 0x80, x))
    same = walls(free) if want_wall else walk_first(free, thr)
    if strict:
        return same
    other = walk_first(free, thr) if want_wall else walls(free)
    p1 = [s for s in same if s < 0x80] + [s for s in other if s < 0x80]
    p2 = [s for s in same if s >= 0x80] + [s for s in other if s >= 0x80]
    return p1 + p2


def pad_sheet(sheet):
    """A sheet as 4096 bytes (page 2 blank when the file has page 1 only)."""
    sheet = bytes(sheet)
    return sheet + bytes(max(0, 2 * SHEET_BYTES - len(sheet)))


def trim_sheet(sheet):
    """The bytes a tileset file keeps: page 1 only while page 2 is blank."""
    sheet = bytes(sheet)
    if len(sheet) > SHEET_BYTES and not any(sheet[SHEET_BYTES:]):
        return sheet[:SHEET_BYTES]
    return sheet[:2 * SHEET_BYTES]


def grid_uses_page2(grid):
    return any(is_page2(v) for row in grid or [] for v in row)


def attr_with_pages(tiles, attr):
    """The attr grid the game needs: attribute bit 3 on every page-2 cell, cleared on
    the others (bit 3 is never authored — the tile carries the page)."""
    out = []
    for r in range(16):
        out.append([(int(attr[r][c]) & 0x7) | page_bit(tiles[r][c]) for c in range(20)])
    return out


# ---------------------------------------------------------------- the project
def _tileset_of(prj, tid):
    for ts in prj.tilesets:
        if ts.get('id') == tid:
            return ts
    return None


def rooms_on(prj, tid):
    return [r for r in prj.rooms if not r.get('placeholder')
            and (r.get('record') or {}).get('tileset') == tid]


def state_tile_lids(prj, r):
    """[(screen k, state n, tiles layout id)] of the room's project tile grids."""
    out = []
    for k, s_ in sorted(prj.room_screens(r).items()):
        for n, st in enumerate(prj.screen_states(s_)):
            lay = st.get('layout') or {}
            if 'id' in lay:
                out.append((k, n, lay['id']))
    return out


def _layout(prj, lid):
    idx = getattr(prj, '_page2_lays', None)
    if idx is None or idx[0] is not prj.layouts or idx[1] != len(prj.layouts):
        idx = (prj.layouts, len(prj.layouts), {la.get('id'): la for la in prj.layouts})
        prj._page2_lays = idx
    return idx[2].get(lid)


def room_uses_page2(prj, r):
    for _k, _n, lid in state_tile_lids(prj, r):
        lay = _layout(prj, lid)
        if lay and grid_uses_page2(lay.get('tiles')):
            return True
    from . import tileanim as TA
    if any(s >= 0x80 for it in (r.get('tile_anims') or []) for s in TA.slots_of(it)):
        return True
    for name, data in (r.get('patch_data') or {}).items():
        if str(name).endswith('_attr') and _patch_uses_page2(data):
            return True
    return False


def _patch_uses_page2(data):
    """S168: a cutscene colour patch (op $61, cutscene_build.patch_bytes) with attribute
    bit 3 in a cell byte: offset word, rows of cell bytes, $D8 between rows, $D9 at the
    end (the markers are never cell bytes — attributes are < $10)."""
    vals = [F.val(x) for x in data[2:]]
    return any(v < 0x10 and v & 8 for v in vals if v not in (0xD8, 0xD9))


def tileset_page2_bytes(prj, tid):
    from . import layouts as L
    ts = _tileset_of(prj, tid)
    if ts is None or 'raw2bpp' not in ts:
        return bytes(SHEET_BYTES)
    try:
        return L.tileset_page2(ts, prj.root)
    except (OSError, ValueError):
        return bytes(SHEET_BYTES)


def tileset_active(prj, tid):
    """Does the build load page 2 for rooms on this tileset? Yes when its page 2 holds
    any art or any room on it draws / animates a page-2 tile."""
    ts = _tileset_of(prj, tid)
    if ts is None or 'raw2bpp' not in ts:
        return False
    if any(tileset_page2_bytes(prj, tid)):
        return True
    return any(room_uses_page2(prj, r) for r in rooms_on(prj, tid))


def active_tilesets(prj):
    got = getattr(prj, '_page2_tids', None)
    if got is None:
        got = prj._page2_tids = [ts['id'] for ts in prj.tilesets
                                 if 'id' in ts and tileset_active(prj, ts['id'])]
    return got


def active(prj):
    return bool(active_tilesets(prj))


# ---------------------------------------------------------------- derived attr streams
def attr_source(prj, r, k, n):
    """Where the attr grid of screen k / state n comes from (the rule of
    Project.state_attr_entry): ('id', layout id) or ('raw', bank, entry) or None."""
    scr = (r.get('screens') or {}).get(str(k)) or {}
    sts = scr.get('states') or []

    def ref(at, key='entry'):
        if 'id' in at:
            return ('id', at['id'])
        b = F.val(at['bank'])
        e = F.val(at.get(key, at.get('entry', at.get('base_entry'))))
        return ('raw', b, e)
    if n < len(sts):
        st = sts[n]
        if st.get('attr'):
            return ref(st['attr'])
        lay = st.get('layout') or {}
        if 'id' in lay and lay['id'] in prj._attr_entry:
            return ('id', lay['id'])
    if scr.get('attr'):
        return ref(scr['attr'])
    lay = scr.get('layout') or {}
    if 'id' in lay and lay['id'] in prj._attr_entry:
        return ('id', lay['id'])
    rat = (r.get('render') or {}).get('attr')
    if rat:
        return ref(rat, 'base_entry')
    return None


def _rom(prj):
    import os
    got = getattr(prj, '_page2_rom', None)
    if got is None:
        path = os.path.join(prj.repo_root or '.', 'data', 'DWM-original.gbc')
        got = prj._page2_rom = open(path, 'rb').read()
    return got


def attr_grid_of(prj, src):
    """The 16 x 20 palette grid of an attr source."""
    from . import layouts as L
    if src[0] == 'id':
        lay = _layout(prj, src[1])
        return [list(row) for row in lay['attr']]
    _kind, b, e = src
    if b == 0x64:                                   # an authored {bank: $64, entry: N}
        for lid, nn in prj._attr_entry.items():
            if nn == e:
                return [list(row) for row in _layout(prj, lid)['attr']]
    dt = L._tool(prj.repo_root or '.', 'decompress_tiles')
    res = dt.decompress_lz(_rom(prj), b, e)
    if res is None:
        raise Page2Error(f"attr stream ${b:02X}:{e} does not decompress")
    return L.unpack_attr(bytes(res[0][:256]) + bytes(max(0, 256 - len(res[0]))))


def derived_attr_key(prj, r, k, n):
    """The stream key of screen k / state n's attr grid with the page bits, or None
    (no page-2 cell there: the ordinary attr stream)."""
    s_ = prj.room_screens(r).get(k)
    if s_ is None:
        return None
    states = prj.screen_states(s_)
    if n >= len(states):
        return None
    lay = states[n].get('layout') or {}
    if 'id' not in lay:
        return None
    t = _layout(prj, lay['id'])
    if not t or not grid_uses_page2(t.get('tiles')):
        return None
    src = attr_source(prj, r, k, n)
    if src is None:
        return None
    return ('attr2', src, lay['id'])


def derived_attr_items(prj):
    """S168: the derived attr streams, in project order (appended after every other
    stream — a project without page 2 keeps its stream plan). Same format as
    Project.stream_items rows."""
    from . import layouts as L
    repo = prj.repo_root or '.'
    out, seen = [], set()
    for r in prj.rooms:
        if r.get('placeholder'):
            continue
        for k, n, _lid in state_tile_lids(prj, r):
            key = derived_attr_key(prj, r, k, n)
            if key is None or key in seen:
                continue
            seen.add(key)
            src, tl = key[1], key[2]
            tag = '_'.join(str(x) for x in src[1:]).replace('-', '_')
            label = f"Attr2_{tag}__{tl}".replace('-', '_')

            def data(src=src, tl=tl):
                grid = attr_with_pages(_layout(prj, tl)['tiles'], attr_grid_of(prj, src))
                return L.compile_attr(repo, grid)
            out.append((key, 0x64, label, data,
                        f"attr map {src[1:]} + the page-2 bits of {tl} (S168)"))
    return out


# ---------------------------------------------------------------- the banks
def plan(prj):
    """-> {'home': bank or 0, 'banks': {bank: [tileset id …]}, 'where': {tid: (bank,
    index)}, 'rows': [(region, map id, bank, index, room)]}. Page-2 banks are taken
    LAST (after the memorial's picture bank): no other kind's bank moves."""
    got = getattr(prj, '_page2_plan', None)
    if got is not None:
        return got
    tids = active_tilesets(prj)
    res = {'home': 0, 'banks': {}, 'where': {}, 'rows': []}
    if not tids:
        prj._page2_plan = res
        return res
    from . import memorial as MM
    MM.plan(prj)                                   # numbers every earlier kind first
    rooms = [(r, t) for t in tids for r in rooms_on(prj, t)]
    rooms.sort(key=lambda rt: prj.rooms.index(rt[0]))
    dir_bytes = DIR_ROW * len(rooms) + 1
    home_cap = (BANK_BYTES - 5 - COPY_CODE_BYTES - HOME_CODE_BYTES - dir_bytes - 2 - 255 - 16
                - 16) // SHEET_BYTES
    if home_cap < 1:
        raise Page2Error(f"{len(rooms)} rooms use page 2 — the directory does not fit one bank")
    home_cap = min(home_cap, SHEETS_PER_BANK)
    home = prj._take_ext_bank('page 2')
    res['home'] = home
    bank, cap = home, home_cap
    res['banks'][home] = []
    for t in tids:
        if len(res['banks'][bank]) >= cap:
            bank = prj._take_ext_bank('page 2')
            cap = SHEETS_PER_BANK
            res['banks'][bank] = []
        res['where'][t] = (bank, len(res['banks'][bank]))
        res['banks'][bank].append(t)
    for r, t in rooms:
        mid = F.val(r['mapID'])
        b, i = res['where'][t]
        res['rows'].append((F.mid_region(mid), mid & 0xFF, b, i, r))
    prj._page2_plan = res
    return res


def bank_file(bank):
    return f"bank_{bank:03x}.asm"


def bank_files(prj):
    return {b: bank_file(b) for b in plan(prj)['banks']}


def suffix(bank):
    return f"_P{bank:02X}"


def emit_bank(prj, bank):
    from .emitters import template
    p = plan(prj)
    A = suffix(bank)
    home = bank == p['home']
    out = [f'SECTION "ROM Bank ${bank:03X}", ROMX[$4000], BANK[${bank:02X}]',
           f'    db ${bank:02X}                          ; bank self-ID at $4000',
           f'    dw Page2Copy{A}                     ; entry 0: copy sheet E to VRAM bank 1 (S168)']
    if home:
        out.append('    dw Page2Room                        ; entry 1: the room-load hook (home bank)')
    out.append(template('page2_copy.asm').replace('{A}', A).rstrip('\n'))
    if home:
        from . import memorial as MM
        from . import hints as HT
        chain = 1 if (MM.active(prj.custom) or HT.active(prj.custom)) else 0
        out.append(f'PAGE2_HOME EQU ${bank:02X}')
        out.append(template('page2_home.asm').replace('{A}', A).rstrip('\n'))
        out.append(f'Page2Chain: db {chain}   ; 1 = the project has memorial statues / hint '
                   'monuments: bank $79 entry 8 after the page')
        out.append('Page2Directory:   ; db region, map id, bank, index (generated, page2.py)')
        for reg, mid, b, i, r in p['rows']:
            tid = (r.get('record') or {}).get('tileset')
            out.append(f'    db {reg}, ${mid:02X}, ${b:02X}, {i}   ; '
                       f'{r.get("name") or r.get("id")} — tileset {tid}')
        out.append('    db $FF')
    out.append(f'SECTION "Bank ${bank:02X} page-2 sheets", ROMX, BANK[${bank:02X}], ALIGN[8]')
    out.append(f'Page2Sheets{A}:   ; 2048 B each, RAW 2bpp (the GDMA source)')
    for i, tid in enumerate(p['banks'][bank]):
        data = tileset_page2_bytes(prj, tid)
        out.append(f'; sheet {i}: page 2 of tileset {tid}')
        for o in range(0, SHEET_BYTES, 16):
            out.append('    db ' + ', '.join(f'${x:02X}' for x in data[o:o + 16]))
    return '\n'.join(out) + '\n'


def emit_banks(prj, warnings):
    """{target: text} for the multi emitter (none without page 2)."""
    return {f'file:patches/{bank_file(b)}': emit_bank(prj, b) for b in plan(prj)['banks']}


HOOK_TEXT = ('    ld hl, ${home:02X}01                   ; S168 page 2: Page2Room (the page-2 home bank\n'
             '    rst $10                        ;   ${home:02X}, entry 1) — the room\'s page 2 to VRAM bank 1,\n'
             '    nop                            ;   then (statues / monuments) bank $79 entry 8\n'
             '    nop\n'
             '    nop\n')


def region_hook(prj):
    """The bank $0B memorial_tiles_0 / _1 text when page 2 is on, else None."""
    p = plan(prj)
    if not p['home']:
        return None
    return HOOK_TEXT.format(home=p['home'])


# ---------------------------------------------------------------- checks
def problems(prj):
    """-> (errors, warnings) in words."""
    errs, warns = [], []
    for r in prj.rooms:
        if r.get('placeholder') or not room_uses_page2(prj, r):
            continue
        tid = (r.get('record') or {}).get('tileset')
        name = r.get('name') or r.get('id')
        ts = _tileset_of(prj, tid) if tid else None
        if ts is None or 'raw2bpp' not in ts:
            errs.append(f"room {name}: draws page-2 tiles but has no project tileset of its own "
                        "(page 2 belongs to a project tileset)")
    try:
        plan(prj)
    except Page2Error as ex:
        errs.append(str(ex))
    return errs, warns
