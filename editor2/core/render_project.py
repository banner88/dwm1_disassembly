"""render_project.py — LIVE room renderer straight from project.json (P3.3, S93).

The S72 renderer (render.py) draws from the LAST BUILT ROM, so it can never
show an unbuilt paint stroke. This module renders the same pixels from the
project's own data — `custom.layouts[]` tile/attr grids, `custom.tilesets[]`
sheets, `custom.palettes[]` — plus the ORIGINAL ROM for anything a room
still borrows from vanilla (tileset banks, vanilla layout/attr references,
derived palettes). No Qt. No build needed.

Fidelity rule (EDITOR_DESIGN §7 Tier 1): this renderer is validated
pixel-identical against render.py (which is validated against PyBoy) on the
example project — editor2/tests/test_render_parity.py. Every rule below is
the same rule the engine applies, cited:

  * tile ids >= 128 draw tile 0 (render_rooms.render_screen)
  * attr nibble & 7 selects the BG palette (KEY_LESSONS S5 nibble packing)
  * palette idx1 = $6BFF, idx3 = $0000 are FORCED (KEY_LESSONS S7/S39)
  * attr per screen: screens[k].attr > the screen's layout item's own attr
    grid > render.attr (S94 per-screen attr maps, CustomAttrCheck)
  * vanilla palette borrow = derive_room_palette.derive (30/30 vs SameBoy)
  * bank $64/$67 entries are project-owned: resolved from declaration order
    (project.py), never from a ROM image
  * rooms below $70 have NO record in project.json (their $26DD rows are the
    legacy hand-patched bank_000 rows) — the gfx row is read from the last
    build when one exists, else approximated from the vanilla source_mapID
    row and flagged via `RoomGfx.note`

Speed: a screen is composed as a 32-colour 'P' image (palette p, colour c ->
index p*4+c) from 128 pre-decoded tile blocks, then converted to RGB —
~1 ms per screen, so painting previews live.
"""

import os
from dataclasses import dataclass

from PIL import Image

import json

from tools.decompress_tiles import decompress_lz
from tools.derive_room_palette import derive as derive_vanilla_palette
from tools.render_rooms import get_attr_data as vanilla_attr_data
from editor2.core import layouts as L

try:
    from dwm.map_names import MAP_NAMES
except Exception:                                  # pragma: no cover
    MAP_NAMES = {}
ANIMATED_INDICES = {77, 78}     # KEY_LESSONS S7: VRAM $94D0-$94FF rotates

SCREEN_W, SCREEN_H = 20, 16           # tiles
WALK_W, WALK_H = 10, 8                # 16-px walk cells
FORCED_IDX1, FORCED_IDX3 = 0x6BFF, 0x0000
SYSTEM_PAL = [(96, 96, 96), (248, 248, 208), (176, 176, 176), (0, 0, 0)]
BLANK_TILE_RGB = (255, 0, 255)


def val(v):
    if isinstance(v, int):
        return v
    s = str(v).strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


def rgb555(v):
    return ((v & 31) * 8, ((v >> 5) & 31) * 8, ((v >> 10) & 31) * 8)


def decode_tiles(sheet2048):
    """2bpp sheet -> 128 x 64-byte colour-index blocks (row-major 8x8)."""
    out = []
    for t in range(128):
        base = t * 16
        blk = bytearray(64)
        for py in range(8):
            lo, hi = sheet2048[base + py * 2], sheet2048[base + py * 2 + 1]
            for px in range(8):
                bit = 7 - px
                blk[py * 8 + px] = (((hi >> bit) & 1) << 1) | ((lo >> bit) & 1)
        out.append(bytes(blk))
    return out


@dataclass
class RoomGfx:
    sheet: bytes            # 2048-byte 2bpp
    gfx_bank: int
    gfx_id: int
    threshold: int          # collision threshold (tile < thr = WALL)
    note: str = ''          # provenance / approximation warning


class ProjectRenderer:
    """Bind to one project (dict) + the original ROM; render its rooms."""

    def __init__(self, repo_root, project_dir, data, rom_path=None,
                 build_rom_path=None):
        self.repo = repo_root
        self.project_dir = project_dir
        self.data = data
        rom_path = rom_path or os.path.join(repo_root, 'data',
                                            'DWM-original.gbc')
        self.rom = open(rom_path, 'rb').read() if os.path.exists(rom_path) \
            else None
        self.build_rom = (open(build_rom_path, 'rb').read()
                          if build_rom_path and os.path.exists(build_rom_path)
                          else None)
        self._tile_cache = {}       # sheet bytes -> decoded blocks
        self._sheet_cache = {}      # (bank, id) / tileset id -> bytes
        self._vanilla_pal_cache = {}
        self.invalidate()

    # ------------------------------------------------------------ indexing
    def invalidate(self):
        """Re-read the project's declaration-order tables after an edit."""
        c = self.data.get('custom', {})
        self.layouts = c.get('layouts', [])
        self.layout_by_id = {l['id']: l for l in self.layouts if 'id' in l}
        self.entry64 = []           # entry index -> (layout dict, 'tiles'|'attr')
        for l in self.layouts:
            if 'tiles' in l:
                self.entry64.append((l, 'tiles'))
            if 'attr' in l:
                self.entry64.append((l, 'attr'))
        self.tilesets = c.get('tilesets', [])
        self.tileset_by_id = {t['id']: t for t in self.tilesets if 'id' in t}
        self.palettes = {p['id']: p for p in c.get('palettes', []) if 'id' in p}
        self.rooms = c.get('rooms', [])
        self.room_by_mid = {val(r['mapID']): r for r in self.rooms}

    def entry64_of(self, lid, kind):
        for i, (l, k) in enumerate(self.entry64):
            if l.get('id') == lid and k == kind:
                return i
        return None

    # ------------------------------------------------------------- tileset
    def _sheet_from_rom(self, bank, gid):
        key = ('rom', bank, gid)
        if key not in self._sheet_cache:
            if bank == 0x67:
                if gid >= len(self.tilesets):
                    raise RuntimeError(
                        f"bank $67 entry {gid}: only {len(self.tilesets)} "
                        "custom.tilesets declared")
                data = L.tileset_bytes(self.repo, self.tilesets[gid],
                                       self.project_dir)
            else:
                if self.rom is None:
                    raise RuntimeError('original ROM not available')
                res = decompress_lz(self.rom, bank, gid)
                if not res:
                    raise RuntimeError(
                        f"tileset decompress failed (bank ${bank:02X} id {gid})")
                data = bytes(res[0][:2048])
            self._sheet_cache[key] = data
        return self._sheet_cache[key]

    def tileset_sheet(self, tileset_id):
        key = ('id', tileset_id)
        if key not in self._sheet_cache:
            self._sheet_cache[key] = L.tileset_bytes(
                self.repo, self.tileset_by_id[tileset_id], self.project_dir)
        return self._sheet_cache[key]

    def room_gfx(self, room):
        """RoomGfx for a room: record.tileset / record.gfx_* / legacy."""
        rec = room.get('record')
        mid = val(room['mapID'])
        if rec and 'tileset' in rec:
            return RoomGfx(self.tileset_sheet(rec['tileset']), 0x67,
                           list(self.tileset_by_id).index(rec['tileset']),
                           val(rec.get('collision_threshold', 0)))
        if rec and 'gfx_bank' in rec:
            b, g = val(rec['gfx_bank']), val(rec['gfx_id'])
            return RoomGfx(self._sheet_from_rom(b, g), b, g,
                           val(rec.get('collision_threshold', 0)))
        # legacy $6B-$6F: hand-patched bank_000 rows
        if self.build_rom is not None and mid < 0x70:
            o = 0x26DD + mid * 8
            b, g, thr = self.build_rom[o + 1], self.build_rom[o], \
                self.build_rom[o + 6]
            return RoomGfx(self._sheet_from_rom(b, g), b, g, thr,
                           'legacy room: record read from the last build')
        src = val(room.get('source_mapID', 0))
        o = 0x26DD + src * 8
        b, g, thr = self.rom[o + 1], self.rom[o], self.rom[o + 6]
        return RoomGfx(self._sheet_from_rom(b, g), b, g, thr,
                       f'legacy room without a build: showing vanilla '
                       f'${src:02X} tileset (approximation)')

    def tiles_of(self, sheet):
        if sheet not in self._tile_cache:
            self._tile_cache[sheet] = decode_tiles(sheet)
        return self._tile_cache[sheet]

    # ------------------------------------------------------------- palette
    def state_palette_id(self, room, screen_idx=0, state=0):
        scr = (room.get('screens') or {}).get(str(screen_idx)) or {}
        sts = scr.get('states') or []
        pid = sts[state].get('palette') if state < len(sts) else None
        return pid or scr.get('palette') or (room.get('render') or {}).get('palette')

    def room_palettes(self, room, screen_idx=0, state=0):
        """8 BG palettes x 4 RGB tuples for (screen, state), forced idx1/idx3
        applied (S94b: states[n].palette > render.palette > vanilla source)."""
        pid = self.state_palette_id(room, screen_idx, state)
        if pid and pid in self.palettes:
            rows = self.palettes[pid]['colors_rgb555']
            pals = []
            for row in rows[:8]:
                r = [val(c) for c in row]
                r[1], r[3] = FORCED_IDX1, FORCED_IDX3
                pals.append([rgb555(c) for c in r])
            while len(pals) < 8:
                pals.append(list(SYSTEM_PAL))
            return pals
        src = val(room.get('source_mapID', 0))
        if src not in self._vanilla_pal_cache:
            env, _ = derive_vanilla_palette(self.rom, mapid=src)
            pals = [[rgb555(c) for c in p] for p in env]
            while len(pals) < 8:
                pals.append(list(SYSTEM_PAL))
            self._vanilla_pal_cache[src] = pals
        return self._vanilla_pal_cache[src]

    def room_palettes_555(self, room, screen_idx=0, state=0):
        """(palette id, raw RGB555 words 8x4) as the palette panel edits
        them; (None, None) when the state borrows a vanilla palette."""
        pid = self.state_palette_id(room, screen_idx, state)
        if pid and pid in self.palettes:
            return pid, [[val(c) for c in row]
                         for row in self.palettes[pid]['colors_rgb555']]
        return None, None

    # -------------------------------------------------------------- layout
    def layout_grid(self, ref):
        """screens[].layout / states[].layout ref -> 16x20 tile grid.
        Returns (grid, editable_layout_id_or_None)."""
        if 'id' in ref:
            lay = self.layout_by_id.get(ref['id'])
            if lay is None or 'tiles' not in lay:
                raise RuntimeError(f"layout id {ref['id']!r} has no tiles")
            return lay['tiles'], ref['id']
        bank, entry = val(ref['bank']), val(ref['entry'])
        if bank == 0x64:
            if entry >= len(self.entry64):
                raise RuntimeError(f"bank $64 entry {entry} not declared")
            lay, kind = self.entry64[entry]
            if kind != 'tiles':
                raise RuntimeError(
                    f"bank $64 entry {entry} is an ATTR entry, not tiles")
            return lay['tiles'], lay['id']
        return self.vanilla_layout_grid(bank, entry), None

    def vanilla_layout_grid(self, bank, entry):
        res = decompress_lz(self.rom, bank, entry)
        if not res:
            raise RuntimeError(
                f"layout decompress failed (bank ${bank:02X} entry {entry})")
        return L.unpad_layout(res[0])

    def attr_grid(self, room, screen_idx, state=0):
        """(16x20 palette grid or None, description) for (screen, state) —
        S94b: states[n].attr > the state's own layout item's attr >
        screens[k].attr > the screen's layout item's own attr > render.attr."""
        scr = (room.get('screens') or {}).get(str(screen_idx)) or {}
        sts = scr.get('states') or []
        at, src = None, ''
        if state < len(sts):
            st = sts[state]
            if st.get('attr'):
                at, src = st['attr'], 'state attr'
            else:
                lay = st.get('layout') or {}
                if 'id' in lay and 'attr' in (self.layout_by_id.get(lay['id']) or {}):
                    at, src = {'id': lay['id']}, "state's layout item"
        if not at:
            at = scr.get('attr')
            src = 'screen attr'
        if not at:
            lay = scr.get('layout') or {}
            if 'id' in lay and 'attr' in (self.layout_by_id.get(lay['id']) or {}):
                at, src = {'id': lay['id']}, 'layout item'
        if not at:
            at = (room.get('render') or {}).get('attr')
            src = 'room default (render.attr)'
        if not at:
            return None, 'no custom attr (vanilla attr for this screen)'
        if 'id' in at:
            lay = self.layout_by_id.get(at['id'])
            if lay is None or 'attr' not in lay:
                return None, f"attr id {at['id']!r} has no attr grid"
            return lay['attr'], f"{at['id']} ({src})"
        bank, entry = val(at['bank']), val(at.get('entry', at.get('base_entry', 0)))
        if bank == 0x64:
            if entry >= len(self.entry64):
                return None, f"bank $64 entry {entry} NOT DECLARED"
            lay, kind = self.entry64[entry]
            if kind == 'attr':
                return lay['attr'], f"{lay['id']} ({src})"
            return L.unpack_attr(L.pad_layout(lay['tiles'])[:256]), \
                f"WARNING: entry {entry} is the TILES stream of {lay['id']!r}"
        res = decompress_lz(self.rom, bank, entry)
        if not res:
            return None, f"attr decompress failed (bank ${bank:02X} {entry})"
        return L.unpack_attr(res[0][:256]), f"vanilla bank ${bank:02X} entry {entry} ({src})"

    # -------------------------------------------------------------- render
    @staticmethod
    def _p_palette(pals):
        flat = []
        for p in pals[:8]:
            for c in p[:4]:
                flat.extend(c)
        flat.extend([0] * (768 - len(flat)))
        return flat

    def compose(self, sheet, tiles_grid, attr_grid, pals):
        """Compose a 160x128 RGB image (scale 1) from grids."""
        blocks = self.tiles_of(sheet)
        tables = [bytes([(p * 4 + (i if i < 4 else 0)) & 0xFF
                         for i in range(256)]) for p in range(8)]
        img = Image.new('P', (SCREEN_W * 8, SCREEN_H * 8), 0)
        for ty in range(SCREEN_H):
            row = tiles_grid[ty]
            arow = attr_grid[ty] if attr_grid else None
            for tx in range(SCREEN_W):
                t = row[tx]
                if t >= 128 or t < 0:
                    t = 0
                p = (arow[tx] & 7) if arow else 0
                blk = Image.frombytes('P', (8, 8), blocks[t].translate(tables[p]))
                img.paste(blk, (tx * 8, ty * 8))
        img.putpalette(self._p_palette(pals))
        return img.convert('RGB')

    def render_tile(self, sheet, tile, pals, pal_idx=0, scale=1):
        blocks = self.tiles_of(sheet)
        table = bytes([(pal_idx * 4 + (i if i < 4 else 0)) & 0xFF
                       for i in range(256)])
        img = Image.frombytes('P', (8, 8), blocks[tile].translate(table))
        img.putpalette(self._p_palette(pals))
        img = img.convert('RGB')
        if scale != 1:
            img = img.resize((8 * scale, 8 * scale), Image.NEAREST)
        return img

    def tile_sheet_image(self, sheet, pals, pal_idx=0, per_row=16, scale=2):
        """All 128 tiles, flat order (KEY_LESSONS S6), 16 per row."""
        rows = 128 // per_row
        img = Image.new('RGB', (per_row * 8, rows * 8))
        for t in range(128):
            img.paste(self.render_tile(sheet, t, pals, pal_idx),
                      ((t % per_row) * 8, (t // per_row) * 8))
        if scale != 1:
            img = img.resize((img.width * scale, img.height * scale),
                             Image.NEAREST)
        return img

    def screen_state(self, room, screen_key, state_idx=0):
        """The effective {layout, npcs, exits} for a screen+state
        (project.py screen_states semantics)."""
        scr = room['screens'][str(screen_key)]
        states = scr.get('states')
        if not states:
            return {'layout': scr.get('layout'), 'npcs': scr.get('npcs', []),
                    'exits': scr.get('exits', [])}
        st = states[min(state_idx, len(states) - 1)]
        return {'layout': st.get('layout', scr.get('layout')),
                'npcs': st.get('npcs', []), 'exits': st.get('exits', [])}

    def render_screen(self, room, screen_key, state_idx=0, scale=1):
        """PIL RGB image of one screen in one state (no markers)."""
        gfx = self.room_gfx(room)
        pals = self.room_palettes(room)
        st = self.screen_state(room, screen_key, state_idx)
        grid, _ = self.layout_grid(st['layout'])
        attr, _ = self.attr_grid(room, int(screen_key), state_idx)
        pals = self.room_palettes(room, int(screen_key), state_idx)
        img = self.compose(gfx.sheet, grid, attr, pals)
        if scale != 1:
            img = img.resize((img.width * scale, img.height * scale),
                             Image.NEAREST)
        return img

    def render_room_screens(self, room, state_idx=0, scale=1):
        out = {}
        for k in sorted(room.get('screens', {}), key=int):
            out[int(k)] = self.render_screen(room, k, state_idx, scale)
        return out

    # ------------------------------------------------------------ vanilla
    def vanilla_rooms(self):
        """[(mapID, name, [screen indices])] for every vanilla room that has
        room data (extracted/map_table.json — S91: only sub_rooms with a
        valid step 0 are listed; step counts there are contaminated by
        phantom rows, so the editor shows vanilla step 0 only)."""
        if getattr(self, '_vanilla', None) is None:
            path = os.path.join(self.repo, 'extracted', 'map_table.json')
            out = []
            try:
                mt = json.load(open(path))
            except Exception:
                mt = []
            for e in mt:
                mid = e.get('map_type')
                if mid is None or mid >= 0x6B:
                    continue
                screens = sorted(sr['c925'] for sr in e.get('sub_rooms', [])
                                 if sr.get('steps'))
                if not screens:
                    continue
                name = MAP_NAMES.get(mid) or e.get('name') or f'map ${mid:02X}'
                out.append((mid, name, screens))
            self._vanilla = out
            self._vanilla_mt = {e['map_type']: e for e in mt if 'map_type' in e}
        return self._vanilla

    def vanilla_name(self, mid):
        return MAP_NAMES.get(mid, f'map ${mid:02X}')

    def vanilla_gfx(self, mid):
        o = 0x26DD + mid * 8
        b, g, thr = self.rom[o + 1], self.rom[o], self.rom[o + 6]
        return RoomGfx(self._sheet_from_rom(b, g), b, g, thr)

    def vanilla_record(self, mid):
        o = 0x26DD + mid * 8
        r = self.rom[o:o + 8]
        return {'gfx_id': f'0x{r[0]:02X}', 'gfx_bank': f'0x{r[1]:02X}',
                'width_px': r[2] | (r[3] << 8), 'height_px': r[4] | (r[5] << 8),
                'collision_threshold': f'0x{r[6]:02X}'}

    VALID_TILESET_BANKS = set(range(0x23, 0x32)) | {0x37, 0x38}

    def vanilla_steps(self, mid, scr_idx):
        """The screen's VALID step entries (room states), in order. The
        engine only checks tileset_bank in (0,$80), so dumped lists can run
        past the real entries into the next block (DOC_AUDIT S91); a step
        is accepted only while tileset_bank / interact / exit pointers are
        sane — the first invalid entry ends the list."""
        self.vanilla_rooms()
        e = self._vanilla_mt[mid]
        sr = next(s for s in e['sub_rooms'] if s['c925'] == scr_idx)
        out = []
        for st in sr['steps']:
            b = int(st['bytes_0_1'], 16) >> 8
            ip, ep = int(st['interact_ptr'], 16), int(st['exit_ptr'], 16)
            ok = (b in self.VALID_TILESET_BANKS and 0x4000 <= ip < 0x8000
                  and 0x4000 <= ep < 0x8000
                  and all(it['x'] < 16 and it['y'] < 16
                          for it in st.get('interact_data', [])))
            if not ok:
                break
            out.append(st)
        return out or sr['steps'][:1]

    def vanilla_counter(self, mid, scr_idx):
        self.vanilla_rooms()
        e = self._vanilla_mt[mid]
        sr = next(s for s in e['sub_rooms'] if s['c925'] == scr_idx)
        return int(sr['ram_counter'], 16)

    def vanilla_screen_grid(self, mid, scr_idx, step=0):
        st = self.vanilla_steps(mid, scr_idx)[step]
        b01 = int(st['bytes_0_1'], 16)
        return self.vanilla_layout_grid(b01 >> 8, b01 & 0xFF)

    def vanilla_attr_grid(self, mid, scr_idx, step=0):
        data = vanilla_attr_data(self.rom, mid, scr_idx, step)
        if data is None and step:
            data = vanilla_attr_data(self.rom, mid, scr_idx, 0)
        return L.unpack_attr(data[:256]) if data else None

    def vanilla_palettes(self, mid):
        if mid not in self._vanilla_pal_cache:
            try:
                env, _ = derive_vanilla_palette(self.rom, mapid=mid)
                pals = [[rgb555(c) for c in p] for p in env]
            except Exception:
                pals = []
            while len(pals) < 8:
                pals.append(list(SYSTEM_PAL))
            self._vanilla_pal_cache[mid] = pals
        return self._vanilla_pal_cache[mid]

    def vanilla_step_palette_words(self, mid, scr_idx, step=0):
        """The 4 environment palettes (RGB555 words, forced idx1/idx3) of a
        vanilla (screen, step) — the pal_ptr in that step's attr-table row."""
        base17 = 0x17 * 0x4000
        room_tbl = self.rom[base17 + (0x476F - 0x4000) + mid * 2] | \
            (self.rom[base17 + (0x476F - 0x4000) + mid * 2 + 1] << 8)
        scr = base17 + (room_tbl - 0x4000) + scr_idx * 2
        scr_entry = self.rom[scr] | (self.rom[scr + 1] << 8)
        row = base17 + (scr_entry - 0x4000) + 2 + step * 4
        ptr = self.rom[row + 2] | (self.rom[row + 3] << 8)
        if not (0x4000 <= ptr < 0x8000):
            return None
        base = base17 + (ptr - 0x4000)
        out = []
        for p in range(4):
            r4 = [self.rom[base + p * 8 + c * 2] | (self.rom[base + p * 8 + c * 2 + 1] << 8)
                  for c in range(4)]
            r4[1], r4[3] = FORCED_IDX1, FORCED_IDX3
            out.append(r4)
        return out

    def vanilla_palettes_step(self, mid, scr_idx, step=0):
        words = self.vanilla_step_palette_words(mid, scr_idx, step)
        if not words:
            return self.vanilla_palettes(mid)
        pals = [[rgb555(c) for c in p] for p in words]
        while len(pals) < 8:
            pals.append(list(SYSTEM_PAL))
        return pals

    def render_vanilla_screen(self, mid, scr_idx, scale=1, step=0):
        gfx = self.vanilla_gfx(mid)
        img = self.compose(gfx.sheet, self.vanilla_screen_grid(mid, scr_idx, step),
                           self.vanilla_attr_grid(mid, scr_idx, step),
                           self.vanilla_palettes_step(mid, scr_idx, step))
        if scale != 1:
            img = img.resize((img.width * scale, img.height * scale),
                             Image.NEAREST)
        return img

    def vanilla_markers(self, mid, scr_idx, step=0):
        """npcs/exits of a vanilla step in project.json raw form (for the
        canvas markers; interact rows verbatim, exits from the ROM)."""
        st = self.vanilla_steps(mid, scr_idx)[step]
        npcs = [{'kind': 'raw',
                 'bytes': [f'0x{int(x, 16):02X}' for x in it['raw'].split()]}
                for it in st.get('interact_data', [])]
        exits = []
        ep = int(st.get('exit_ptr', '0'), 16)
        if 0x4000 <= ep < 0x8000:
            off = 0x0B * 0x4000 + (ep - 0x4000)
            while self.rom[off] != 0xFF and len(exits) < 32:
                x, y, dest = self.rom[off], self.rom[off + 1], self.rom[off + 2]
                exits.append({'x': x, 'y': y, 'dest': f'vanilla:${dest:02X}',
                              'gate_flag': self.rom[off + 3],
                              'screen_byte': f'0x{self.rom[off + 4]:02X}',
                              'spawn_x': self.rom[off + 5],
                              'spawn_y': self.rom[off + 6]})
                off += 7
        return npcs, exits

