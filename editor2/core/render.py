"""render.py — headless room renderer for the editor (EDITOR_DESIGN §11 Tier 1).

Renders a project room's screens as PIL images from the LAST BUILT patched
ROM + its game.sym. Design rules honored:
  * No Qt imports (core stays headless).
  * ZERO format re-derivation: reuses the proven pixel path
    (tools/render_rooms.render_screen + tools/decompress_tiles.decompress_lz,
    validated across all 107 vanilla rooms in ALL_ROOMS_FINAL.png) and the
    proven palette derivation (tools/derive_room_palette.derive, validated
    30/30 vs SameBoy dumps) for vanilla-borrow palettes.
  * Reads CUSTOM rooms through the same tables the GAME reads, located by
    game.sym symbols (drift-proof — addresses move, symbols don't):
      screens : CustomRoomPtrTable (bank $60) — vanilla bank-$0B sub-table
                format (ROOM_DATA_FORMAT); screen record +2/+3 = layout
                entry + layout bank ($64).
      tileset : mapID < $70 → ROM0 $26DD + mapID*8 (patched ROM carries the
                $6B-$6F rows); mapID ≥ $70 → Custom26DDTable (bank $71,
                (mapID-$70)*8) — mirrors CopyCustomRoomRecord (S42).
      attrs   : CustomRoomAttr[mapID-$6B] = {bank, base_entry}; screen 0 →
                base_entry, other screens → base_entry+2 (the vertical-pair
                stride documented at CustomAttrCheck, patches/bank_017.asm
                Pillar A); bank $00 → no custom attr.
      palette : CustomRoomPalPtr[mapID-$6B] → 8×4 RGB555 rows in bank $17
                with the FORCED idx1=$6BFF / idx3=$0000 rule (KEY_LESSONS
                S7/S39); dw $0000 → borrow the vanilla source_mapID palette
                via derive().
  * Screens are bounded by project.json's `screens` keys (the source of
    truth) — never by walking the sub-table blind.

Marker overlay (optional): NPC / spawn / exit positions from project.json,
drawn as outlined tiles with a letter — display aid only, not game data.
"""

import os

from PIL import Image, ImageDraw

from tools.decompress_tiles import decompress_lz
from tools.render_rooms import render_screen
from tools.derive_room_palette import derive as derive_vanilla_palette
from editor2.core.builder import parse_sym

SCREEN_W_TILES, SCREEN_H_TILES = 20, 16
GRID_COLS = 4                       # screen index → (idx % 4, idx // 4)

MARKER_COLORS = {                   # display-only
    'npc':   (0, 200, 255),
    'spawn': (0, 220, 80),
    'exit':  (255, 60, 60),
}


def _val(v):
    """'0x6B' / '$6B' / int → int (PROJECT_COMPILER §2 value forms)."""
    if isinstance(v, int):
        return v
    s = str(v).strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


def _rgb555(v):
    return ((v & 31) * 8, ((v >> 5) & 31) * 8, ((v >> 10) & 31) * 8)


class RoomRenderer:
    """Bind to one built ROM + sym; render project rooms from it."""

    def __init__(self, rom_path, sym_path):
        self.rom_path = rom_path
        self.rom = open(rom_path, 'rb').read()
        self.syms = parse_sym(sym_path)
        missing = [s for s in ('CustomRoomPtrTable', 'Custom26DDTable',
                               'CustomRoomAttr', 'CustomRoomPalPtr')
                   if s not in self.syms]
        if missing:
            raise RuntimeError(
                f"game.sym lacks {missing} — rebuild the project (the sym "
                "file must come from the same build as the ROM).")

    # -- low-level helpers -------------------------------------------------
    def _off(self, bank, addr):
        return bank * 0x4000 + (addr - 0x4000) if bank else addr

    def _u16(self, off):
        return self.rom[off] | (self.rom[off + 1] << 8)

    def _sym_off(self, name):
        bank, addr = self.syms[name]
        return self._off(bank, addr)

    # -- render pieces -----------------------------------------------------
    def _gfx(self, mapid):
        if mapid < 0x70:
            o = 0x26DD + mapid * 8
        else:
            o = self._sym_off('Custom26DDTable') + (mapid - 0x70) * 8
        gid, gbank = self.rom[o], self.rom[o + 1]
        res = decompress_lz(self.rom, gbank, gid)
        if not res:
            raise RuntimeError(
                f"tileset decompress failed (bank ${gbank:02X} id {gid}) "
                f"for mapID ${mapid:02X}")
        return res[0]

    def _palettes(self, mapid, source_mapid):
        po = self._sym_off('CustomRoomPalPtr') + (mapid - 0x6B) * 2
        ptr = self._u16(po)
        if ptr:
            base = self._off(0x17, ptr)
            pals = []
            for p in range(8):
                row = [self._u16(base + p * 8 + c * 2) for c in range(4)]
                row[1], row[3] = 0x6BFF, 0x0000      # forced (S7/S39)
                pals.append([_rgb555(c) for c in row])
            return pals
        # dw $0000 → borrow the vanilla source-map palette. derive() returns
        # (env_slots_0_3, obj_palettes) with the forced rule applied
        # (validated 30/30 vs SameBoy). BG slots 4-7 are the shared SYSTEM
        # set (HUD/menus — GATE_GENERATION "BG slots 4-7"); room tiles
        # rarely reference them, so a neutral grey stand-in is a display
        # approximation only (flagged for the canvas milestone).
        env, _obj = derive_vanilla_palette(self.rom, mapid=source_mapid)
        pals = [[_rgb555(c) for c in p] for p in env]
        system = [(96, 96, 96), (248, 248, 208), (176, 176, 176), (0, 0, 0)]
        while len(pals) < 8:
            pals.append(list(system))
        return pals

    def _attr(self, mapid, screen_index):
        ao = self._sym_off('CustomRoomAttr') + (mapid - 0x6B) * 2
        abank, abase = self.rom[ao], self.rom[ao + 1]
        if abank == 0:
            return None                              # vanilla fallback row
        entry = abase if screen_index == 0 else abase + 2
        res = decompress_lz(self.rom, abank, entry)
        return res[0] if res else None

    def _layout(self, mapid, screen_index):
        sub = self._u16(self._sym_off('CustomRoomPtrTable')
                        + (mapid - 0x6B) * 2)
        rd = self._u16(self._off(0x60, sub) + screen_index * 2)
        ro = self._off(0x60, rd)
        entry, lbank = self.rom[ro + 2], self.rom[ro + 3]
        res = decompress_lz(self.rom, lbank, entry)
        if not res:
            raise RuntimeError(
                f"layout decompress failed (bank ${lbank:02X} entry {entry})"
                f" for mapID ${mapid:02X} screen {screen_index}")
        return res[0]

    # -- public API --------------------------------------------------------
    def render_room(self, room, scale=2, markers=True):
        """room = a project.json custom.rooms[] dict. Returns
        {screen_index: PIL.Image} for the screens the PROJECT declares
        (placeholder rooms → {})."""
        if room.get('placeholder'):
            return {}
        mapid = _val(room['mapID'])
        source = _val(room.get('source_mapID', 0))
        gfx = self._gfx(mapid)
        pals = self._palettes(mapid, source)
        out = {}
        for key, scr in sorted(room.get('screens', {}).items(),
                               key=lambda kv: int(kv[0])):
            idx = int(key)
            layout = self._layout(mapid, idx)
            attr = self._attr(mapid, idx)
            img = render_screen(self.rom, gfx, layout, attr, pals,
                                scale=scale)
            if markers:
                self._draw_markers(img, scr, scale)
            out[idx] = img
        return out

    def _draw_markers(self, img, screen, scale):
        d = ImageDraw.Draw(img)
        t = 8 * scale

        def box(x, y, color, letter):
            d.rectangle([x * t, y * t, x * t + t - 1, y * t + t - 1],
                        outline=color, width=max(1, scale - 1))
            d.text((x * t + 2, y * t), letter, fill=color)

        for n in screen.get('npcs', []):
            kind = 'spawn' if n.get('kind') == 'spawn' else 'npc'
            box(int(n['x']), int(n['y']), MARKER_COLORS[kind],
                'S' if kind == 'spawn' else 'N')
        for e in screen.get('exits', []):
            box(int(e['x']), int(e['y']), MARKER_COLORS['exit'], 'E')

    def stitch(self, screens, scale=2, gap=8):
        """{idx: Image} → one image on the 4-wide screen grid (row=idx//4),
        cropped to the used bounding box. Empty grid cells stay dark."""
        if not screens:
            return None
        cells = {(i % GRID_COLS, i // GRID_COLS): im
                 for i, im in screens.items()}
        cols = sorted({c for c, _ in cells})
        rows = sorted({r for _, r in cells})
        w = SCREEN_W_TILES * 8 * scale
        h = SCREEN_H_TILES * 8 * scale
        canvas = Image.new(
            'RGB',
            ((max(cols) - min(cols) + 1) * (w + gap) - gap,
             (max(rows) - min(rows) + 1) * (h + gap) - gap),
            (24, 24, 28))
        for (c, r), im in cells.items():
            canvas.paste(im, ((c - min(cols)) * (w + gap),
                              (r - min(rows)) * (h + gap)))
        return canvas


def find_build(project_path):
    """Locate an existing build's (rom, sym) for a project dir, or None."""
    base = os.path.join(project_path, 'build', 'build')
    rom = os.path.join(base, 'rom.gbc')
    sym = os.path.join(base, 'game.sym')
    return (rom, sym) if (os.path.exists(rom) and os.path.exists(sym)) \
        else None
