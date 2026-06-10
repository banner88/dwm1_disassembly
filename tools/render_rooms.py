#!/usr/bin/env python3
"""Render DWM1 room screens as color PNG images.

Supports both normal and gate-world rendering modes:
  Normal: tileset from $26DD, attributes from $476F lookup chain
  Gate:   tileset from $2A5D, attributes from $5215/$5415 tables

Usage:
  python -m tools.render_rooms                     # render mt 0-24 (normal mode)
  python -m tools.render_rooms 8 12 35             # render specific rooms
  python -m tools.render_rooms --gate 35 36 37     # render as gate-world rooms
  python -m tools.render_rooms --gate --gate-idx 5 35  # use attr index 5
"""
import sys, os, json, argparse
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.decompress_tiles import decompress_lz
from PIL import Image

ROM_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data', 'DWM-original.gbc')
TILESET_BANKS = {0x23, 0x24, 0x25, 0x26, 0x28, 0x29, 0x2A, 0x2D, 0x2E, 0x2F, 0x30, 0x31, 0x37, 0x38}

# Default palette (Castle)
DEFAULT_PALETTES = [
    [(224,24,16),(248,248,208),(224,24,16),(0,0,0)],
    [(168,0,0),(248,248,208),(248,160,0),(0,0,0)],
    [(112,104,80),(248,248,208),(176,176,144),(0,0,0)],
    [(0,64,248),(248,248,208),(16,208,248),(0,0,0)],
    [(120,56,0),(248,248,208),(192,112,0),(0,0,0)],
    [(216,32,0),(248,248,208),(248,152,0),(0,0,0)],
    [(8,56,248),(248,248,208),(248,168,0),(0,0,0)],
    [(200,72,0),(248,248,208),(248,200,0),(0,0,0)],
]

def u16(rom, off):
    return rom[off] | (rom[off+1] << 8)

def get_attr_data(rom, mt, scr, step):
    """Get attribute data for a normal room screen+step via $476F lookup."""
    base17 = 0x17 * 0x4000
    room_tbl_off = base17 + (0x476F - 0x4000) + mt * 2
    room_tbl = u16(rom, room_tbl_off)
    if room_tbl < 0x4000: return None
    
    scr_off = base17 + (room_tbl - 0x4000) + scr * 2
    scr_entry = u16(rom, scr_off)
    if scr_entry < 0x4000 or scr_entry > 0x7FFF: return None
    
    entry_off = base17 + (scr_entry - 0x4000)
    
    # Each step has 4 bytes: [attr_idx, attr_bank, pal_lo, pal_hi]
    step_off = entry_off + 2 + step * 4
    attr_e = rom[step_off]
    attr_d = rom[step_off + 1]
    if attr_d == 0 or attr_d >= 0x80: return None
    
    result = decompress_lz(rom, attr_d, attr_e)
    return result[0] if result else None

def get_gate_attr_data(rom, gate_idx, table_sel=0):
    """Get attribute data for a gate room via $5215/$5415 lookup.
    
    Args:
        gate_idx: index into the gate attribute table (from $C940[screen])
        table_sel: 0 = $5215 table (default), 1 = $5415 table
    """
    base17 = 0x17 * 0x4000
    table_addr = 0x5215 if table_sel == 0 else 0x5415
    entry_off = base17 + (table_addr - 0x4000) + gate_idx * 2
    
    attr_idx = rom[entry_off]
    attr_bank = rom[entry_off + 1]
    if attr_bank == 0 or attr_bank >= 0x80: return None
    
    result = decompress_lz(rom, attr_bank, attr_idx)
    return result[0] if result else None

def render_screen(rom, gfx, layout, attr_data, palettes, scale=3):
    """Render a 20x16 tile screen to an RGB image."""
    W, H, STRIDE = 20, 16, 32
    img = Image.new('RGB', (W*8*scale, H*8*scale))
    
    for ty in range(H):
        for tx in range(W):
            tile_idx = layout[ty * STRIDE + tx]
            if tile_idx >= 128: tile_idx = 0
            
            if attr_data:
                attr_off = ty * 16 + (tx // 2)
                ab = attr_data[attr_off] if attr_off < len(attr_data) else 0
                pal_idx = ((ab >> 4) & 0x07) if (tx % 2 == 0) else (ab & 0x07)
            else:
                pal_idx = 0
            pal = palettes[min(pal_idx, 7)]
            
            base = tile_idx * 16
            for py in range(8):
                if base + py*2+1 >= len(gfx): continue
                lo, hi = gfx[base+py*2], gfx[base+py*2+1]
                for px in range(8):
                    bit = 7 - px
                    ci = ((hi>>bit)&1)<<1 | ((lo>>bit)&1)
                    color = pal[ci]
                    for sy in range(scale):
                        for sx in range(scale):
                            img.putpixel(((tx*8+px)*scale+sx, (ty*8+py)*scale+sy), color)
    return img

def render_room(rom, mt, out_dir, palettes=None, gate=False, gate_idx=0, gate_table=0):
    """Render all screens of a room.
    
    Args:
        gate: if True, use gate-world tilesets ($2A5D) and attributes ($5215/$5415)
        gate_idx: attribute index for gate mode (from $C940, default 0)
        gate_table: 0 = $5215, 1 = $5415
    """
    if palettes is None: palettes = DEFAULT_PALETTES
    
    base_0b = 0x0B * 0x4000
    
    # Tileset graphics: $2A5D for gate mode, $26DD for normal
    gfx_table = 0x2A5D if gate else 0x26DD
    gfx_off = gfx_table + mt * 8
    gfx_id, gfx_bank = rom[gfx_off], rom[gfx_off+1]
    if gfx_bank == 0: return []
    gfx_result = decompress_lz(rom, gfx_bank, gfx_id)
    if not gfx_result: return []
    gfx = gfx_result[0]
    # Gate validation: tile graphics must be 2048 bytes (128 tiles × 16B)
    if gate and len(gfx) != 2048:
        return []  # not a valid gate room tileset
    
    sub_ptr = u16(rom, base_0b + (0x4B43 - 0x4000) + mt * 2)
    if sub_ptr < 0x4000: return []
    sub_off = base_0b + (sub_ptr - 0x4000)
    
    # Find sub-table size
    min_data = sub_ptr + 16
    for i in range(8):
        p = u16(rom, sub_off + i*2)
        if 0x4000 <= p < 0x7FFF and p != 0xFFFF and p > sub_ptr:
            min_data = min(min_data, p)
    num_entries = min((min_data - sub_ptr) // 2, 8)
    
    rendered = []
    for scr in range(num_entries):
        rd_ptr = u16(rom, sub_off + scr * 2)
        if rd_ptr == 0xFFFF or rd_ptr < 0x4000: continue
        rd = base_0b + (rd_ptr - 0x4000)
        ram = u16(rom, rd)
        if ram < 0xD900 or ram > 0xD9FF: continue
        
        se = rd + 2
        sid, tbank = rom[se], rom[se+1]
        if tbank not in TILESET_BANKS: continue
        
        layout_result = decompress_lz(rom, tbank, sid)
        if not layout_result: continue
        layout = layout_result[0]
        
        # Attribute data: gate path or normal path
        if gate:
            attr_data = get_gate_attr_data(rom, gate_idx, gate_table)
        else:
            attr_data = get_attr_data(rom, mt, scr, 0)
        
        img = render_screen(rom, gfx, layout, attr_data, palettes)
        suffix = "_gate" if gate else ""
        fname = f"mt{mt:02d}_scr{scr}{suffix}.png"
        path = os.path.join(out_dir, fname)
        img.save(path)
        rendered.append((scr, fname))
    
    return rendered

if __name__ == '__main__':
    ap = argparse.ArgumentParser(description="Render DWM1 room screens")
    ap.add_argument('rooms', nargs='*', type=int, help="Map types to render (default: 0-24)")
    ap.add_argument('--gate', action='store_true', help="Use gate-world tilesets and attributes")
    ap.add_argument('--gate-idx', type=int, default=0, help="Gate attribute index (from $C940, default 0)")
    ap.add_argument('--gate-table', type=int, default=0, choices=[0, 1],
                    help="Gate attribute table: 0=$5215 (default), 1=$5415")
    ap.add_argument('--out', default=None, help="Output directory")
    ap.add_argument('--palettes', default=None, help="Path to room_palettes.json")
    args = ap.parse_args()
    
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    
    out_dir = args.out or '/mnt/user-data/outputs/rooms'
    os.makedirs(out_dir, exist_ok=True)
    
    # Load palettes if available
    pal_data = None
    if args.palettes:
        with open(args.palettes) as f:
            pal_data = json.load(f)
    elif os.path.exists(os.path.join(os.path.dirname(ROM_PATH), '..', 'extracted', 'room_palettes.json')):
        with open(os.path.join(os.path.dirname(ROM_PATH), '..', 'extracted', 'room_palettes.json')) as f:
            pal_data = json.load(f)
    
    targets = args.rooms if args.rooms else list(range(25))
    mode = "gate" if args.gate else "normal"
    
    def gbc_to_rgb(val):
        """Convert 15-bit GBC color to (R, G, B) tuple."""
        r = (val & 0x1F) * 8
        g = ((val >> 5) & 0x1F) * 8
        b = ((val >> 10) & 0x1F) * 8
        return (r, g, b)
    
    def load_palette(pal_data, mt):
        """Load palette for a room from the palette JSON."""
        # Try numeric string key first, then mt## format
        for key in [str(mt), f"mt{mt:02d}", f"mt{mt}"]:
            if key in pal_data:
                raw = pal_data[key]
                # Convert: list of 8 palettes, each 4 GBC colors
                if isinstance(raw[0], list):
                    return [
                        [gbc_to_rgb(c) if isinstance(c, int) else tuple(c) for c in pal]
                        for pal in raw
                    ]
                return raw
        return None
    
    for mt in targets:
        palettes = DEFAULT_PALETTES
        if pal_data:
            loaded = load_palette(pal_data, mt)
            if loaded:
                palettes = loaded
        
        rendered = render_room(rom, mt, out_dir, palettes,
                              gate=args.gate, gate_idx=args.gate_idx,
                              gate_table=args.gate_table)
        if rendered:
            screens = ', '.join(f'scr{s}' for s, _ in rendered)
            print(f'mt={mt:2d} [{mode}]: {screens}')
