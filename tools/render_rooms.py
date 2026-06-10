#!/usr/bin/env python3
"""Render DWM1 room screens as color PNG images."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from tools.decompress_tiles import decompress_lz
from PIL import Image

ROM_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data', 'DWM-original.gbc')
TILESET_BANKS = {0x23, 0x24, 0x25, 0x26, 0x29, 0x2A, 0x2D, 0x30, 0x37}

# Default palette (Castle) — can be overridden per room
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
    """Get attribute data for a normal room screen+step."""
    base17 = 0x17 * 0x4000
    room_tbl_off = base17 + (0x476F - 0x4000) + mt * 2
    room_tbl = u16(rom, room_tbl_off)
    if room_tbl < 0x4000: return None
    
    scr_off = base17 + (room_tbl - 0x4000) + scr * 2
    scr_entry = u16(rom, scr_off)
    if scr_entry < 0x4000 or scr_entry > 0x7FFF: return None
    
    entry_off = base17 + (scr_entry - 0x4000)
    ram_addr = u16(rom, entry_off)
    
    # Each step has 4 bytes: [attr_idx, attr_bank, pal_lo, pal_hi]
    step_off = entry_off + 2 + step * 4
    attr_e = rom[step_off]
    attr_d = rom[step_off + 1]
    if attr_d == 0 or attr_d >= 0x80: return None
    
    result = decompress_lz(rom, attr_d, attr_e)
    return result[0] if result else None

def render_screen(rom, gfx, layout, attr_data, palettes, scale=3):
    """Render a 20×16 tile screen to an RGB image."""
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

def render_room(rom, mt, out_dir, palettes=None):
    """Render all screens of a room."""
    if palettes is None: palettes = DEFAULT_PALETTES
    
    base_0b = 0x0B * 0x4000
    # Tileset graphics from $26DD
    gfx_off = 0x26DD + mt * 8
    gfx_id, gfx_bank = rom[gfx_off], rom[gfx_off+1]
    gfx_result = decompress_lz(rom, gfx_bank, gfx_id)
    if not gfx_result: return []
    gfx = gfx_result[0]
    
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
        
        attr_data = get_attr_data(rom, mt, scr, 0)
        
        img = render_screen(rom, gfx, layout, attr_data, palettes)
        fname = f"mt{mt:02d}_scr{scr}.png"
        path = os.path.join(out_dir, fname)
        img.save(path)
        rendered.append((scr, fname))
    
    return rendered

if __name__ == '__main__':
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    
    out_dir = '/mnt/user-data/outputs/rooms'
    os.makedirs(out_dir, exist_ok=True)
    
    targets = [int(a) for a in sys.argv[1:]] if len(sys.argv) > 1 else range(25)
    
    for mt in targets:
        rendered = render_room(rom, mt, out_dir)
        if rendered:
            screens = ', '.join(f'scr{s}' for s, _ in rendered)
            print(f'mt={mt:2d}: {screens}')
