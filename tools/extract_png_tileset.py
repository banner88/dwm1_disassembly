#!/usr/bin/env python3
"""Extract GBC-compatible tiles from a PNG map rip.

Takes a PNG image (e.g., a DWM2 map rip), extracts unique 8×8 tiles,
quantizes each to 4 colors (GBC 2bpp), clusters into palette groups,
and produces:
  1. A tileset PNG for the editor (16 tiles wide)
  2. Raw 2bpp tile data for build_combined_tileset.py
  3. Editor integration snippet (TILE_PAL, base64 image)

Usage:
  python3 tools/extract_png_tileset.py input.png --name NORDEN
  python3 tools/extract_png_tileset.py input.png --name NORDEN --crop 0,0,320,640
"""
import os, sys, json, argparse, base64, io
import numpy as np
from PIL import Image
from collections import Counter

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.join(SCRIPT_DIR, '..')


def snap_to_gbc(rgb):
    """Snap RGB values to GBC 5-bit color space (0-31 per channel)."""
    return tuple(int(round(c / 8)) for c in rgb[:3])

def gbc_to_rgb(gbc5):
    """Convert GBC 5-bit color to 8-bit RGB."""
    return tuple(min(255, c * 8) for c in gbc5)

def gbc_to_rgb15(gbc5):
    """Convert GBC 5-bit (r,g,b) to RGB15 LE bytes."""
    r, g, b = gbc5
    val = (r & 0x1F) | ((g & 0x1F) << 5) | ((b & 0x1F) << 10)
    return (val & 0xFF, (val >> 8) & 0xFF)


def quantize_tile_4colors(tile_8x8):
    """Quantize an 8×8 RGB tile to exactly 4 GBC colors.
    
    Returns: (quantized_tile, palette_4colors)
      quantized_tile: 8×8 array of palette indices (0-3)
      palette_4colors: list of 4 GBC 5-bit (r,g,b) tuples, sorted dark→light
    """
    # Snap to GBC color space first
    flat = tile_8x8.reshape(-1, 3)
    gbc_flat = np.array([[int(round(c / 8)) for c in px] for px in flat])
    
    unique_colors = np.unique(gbc_flat, axis=0)
    
    if len(unique_colors) <= 4:
        # Already ≤4 colors — just use them
        palette = [tuple(c) for c in unique_colors]
    else:
        # K-means to reduce to 4 colors
        from sklearn.cluster import KMeans
        km = KMeans(n_clusters=4, n_init=3, random_state=42)
        km.fit(gbc_flat)
        palette = [tuple(int(round(c)) for c in center) for center in km.cluster_centers_]
    
    # Sort palette by luminance (dark → light, matching GBC convention: 3=lightest, 0=darkest)
    palette.sort(key=lambda c: c[0]*0.299 + c[1]*0.587 + c[2]*0.114)
    # Reverse so index 0 = lightest (GBC convention: color 0 = bg/lightest)
    palette = list(reversed(palette))
    
    # Pad to exactly 4 if fewer
    while len(palette) < 4:
        palette.append(palette[-1])
    palette = palette[:4]
    
    # Map each pixel to nearest palette entry
    indices = np.zeros(64, dtype=np.uint8)
    for i, px_gbc in enumerate(gbc_flat):
        dists = [sum((a - b) ** 2 for a, b in zip(px_gbc, c)) for c in palette]
        indices[i] = np.argmin(dists)
    
    return indices.reshape(8, 8), palette


def tile_to_2bpp(indices_8x8):
    """Convert 8×8 palette index array to 16 bytes of GBC 2bpp data."""
    data = bytearray(16)
    for row in range(8):
        lo = 0
        hi = 0
        for col in range(8):
            idx = indices_8x8[row, col]
            bit = 7 - col
            lo |= ((idx & 1) << bit)
            hi |= (((idx >> 1) & 1) << bit)
        data[row * 2] = lo
        data[row * 2 + 1] = hi
    return bytes(data)


def extract_tileset(img, crop_rect=None, max_tiles=128):
    """Extract unique tiles from a PNG image.
    
    Returns: list of (tile_2bpp, palette_4colors, preview_8x8_rgb)
    """
    if crop_rect:
        img = img.crop(crop_rect)
    
    arr = np.array(img.convert('RGB'))
    h, w = arr.shape[:2]
    
    # Snap to tile grid
    tw = (w // 8) * 8
    th = (h // 8) * 8
    arr = arr[:th, :tw]
    
    print(f"Processing {tw}×{th} pixels ({tw//8}×{th//8} tile positions)", file=sys.stderr)
    
    tiles = {}  # 2bpp_bytes → (palette, preview, count)
    tile_order = []  # preserve first-seen order
    
    for ty in range(th // 8):
        for tx in range(tw // 8):
            block = arr[ty*8:(ty+1)*8, tx*8:(tx+1)*8]
            indices, palette = quantize_tile_4colors(block)
            bpp = tile_to_2bpp(indices)
            
            if bpp not in tiles:
                # Build RGB preview from quantized data
                preview = np.zeros((8, 8, 3), dtype=np.uint8)
                for r in range(8):
                    for c in range(8):
                        preview[r, c] = gbc_to_rgb(palette[indices[r, c]])
                
                tiles[bpp] = (palette, preview, 1)
                tile_order.append(bpp)
            else:
                pal, prev, cnt = tiles[bpp]
                tiles[bpp] = (pal, prev, cnt + 1)
    
    print(f"Found {len(tiles)} unique tiles", file=sys.stderr)
    
    # Sort by frequency (most used first) then take top max_tiles
    sorted_keys = sorted(tile_order, key=lambda k: -tiles[k][2])
    if len(sorted_keys) > max_tiles:
        print(f"Keeping top {max_tiles} most frequent tiles", file=sys.stderr)
        sorted_keys = sorted_keys[:max_tiles]
    
    result = []
    for bpp in sorted_keys:
        palette, preview, count = tiles[bpp]
        result.append((bpp, palette, preview, count))
    
    return result


def cluster_palettes(tiles, n_palettes=8):
    """Cluster tiles into palette groups based on color similarity.
    
    Returns: list of palette_index (0 to n_palettes-1) per tile
    """
    if len(tiles) <= n_palettes:
        return list(range(len(tiles)))
    
    # Build feature vector from each tile's 4 palette colors (12 dimensions)
    features = []
    for bpp, palette, preview, count in tiles:
        feat = []
        for r, g, b in palette:
            feat.extend([r, g, b])
        features.append(feat)
    
    features = np.array(features)
    
    from sklearn.cluster import KMeans
    km = KMeans(n_clusters=n_palettes, n_init=5, random_state=42)
    labels = km.fit_predict(features)
    
    return labels.tolist()


def build_tileset_png(tiles):
    """Build a 16-wide tileset PNG from extracted tiles."""
    n = len(tiles)
    rows = (n + 15) // 16
    img = Image.new('RGB', (16 * 8, rows * 8), (0, 0, 0))
    
    for i, (bpp, palette, preview, count) in enumerate(tiles):
        x = (i % 16) * 8
        y = (i // 16) * 8
        tile_img = Image.fromarray(preview)
        img.paste(tile_img, (x, y))
    
    return img


def main():
    parser = argparse.ArgumentParser(description='Extract GBC tiles from PNG')
    parser.add_argument('input_png', help='Input PNG image')
    parser.add_argument('--name', default='CUSTOM', help='Tileset name (e.g., NORDEN)')
    parser.add_argument('--crop', default=None, help='Crop rect: x,y,w,h')
    parser.add_argument('--max-tiles', type=int, default=128, help='Max tiles to keep')
    parser.add_argument('--out-dir', default=None, help='Output directory')
    args = parser.parse_args()
    
    img = Image.open(args.input_png).convert('RGB')
    print(f"Input: {img.size[0]}×{img.size[1]}", file=sys.stderr)
    
    crop_rect = None
    if args.crop:
        x, y, w, h = map(int, args.crop.split(','))
        crop_rect = (x, y, x + w, y + h)
    
    # Extract tiles
    tiles = extract_tileset(img, crop_rect, args.max_tiles)
    
    # Cluster into palette groups
    pal_labels = cluster_palettes(tiles)
    
    # Build merged palettes per group
    n_pals = max(pal_labels) + 1
    group_palettes = {}
    for i, (bpp, palette, preview, count) in enumerate(tiles):
        group = pal_labels[i]
        if group not in group_palettes:
            group_palettes[group] = []
        group_palettes[group].append(palette)
    
    # For each group, compute average palette
    merged_palettes = {}
    for group, palettes in group_palettes.items():
        avg = []
        for cidx in range(4):
            r = int(np.mean([p[cidx][0] for p in palettes]))
            g = int(np.mean([p[cidx][1] for p in palettes]))
            b = int(np.mean([p[cidx][2] for p in palettes]))
            avg.append((r, g, b))
        merged_palettes[group] = avg
    
    # Build tileset PNG
    ts_img = build_tileset_png(tiles)
    
    # Output directory
    out_dir = args.out_dir or os.path.join(ROOT_DIR, 'extracted', 'custom_tilesets')
    os.makedirs(out_dir, exist_ok=True)
    
    # Save tileset PNG
    png_path = os.path.join(out_dir, f'{args.name}_tileset.png')
    ts_img.save(png_path)
    print(f"Tileset PNG: {png_path} ({len(tiles)} tiles)", file=sys.stderr)
    
    # Save 2bpp raw data
    bpp_path = os.path.join(out_dir, f'{args.name}_tiles.2bpp')
    with open(bpp_path, 'wb') as f:
        for bpp, palette, preview, count in tiles:
            f.write(bpp)
    print(f"2bpp data: {bpp_path} ({len(tiles) * 16} bytes)", file=sys.stderr)
    
    # Save palette data (per-tile palette colors)
    pal_data = {
        'name': args.name,
        'tile_count': len(tiles),
        'tile_palettes': {},  # tile_idx → palette_group_idx
        'palette_colors': {},  # group_idx → [4 × (r,g,b)]
    }
    for i in range(len(tiles)):
        pal_data['tile_palettes'][str(i)] = pal_labels[i]
    for group, pal in merged_palettes.items():
        pal_data['palette_colors'][str(group)] = [list(c) for c in pal]
    
    pal_json_path = os.path.join(out_dir, f'{args.name}_palettes.json')
    with open(pal_json_path, 'w') as f:
        json.dump(pal_data, f, indent=2)
    print(f"Palette data: {pal_json_path}", file=sys.stderr)
    
    # Generate base64 PNG for editor embedding
    buf = io.BytesIO()
    ts_img.save(buf, format='PNG')
    b64 = base64.b64encode(buf.getvalue()).decode('ascii')
    
    # Build TILE_PAL entry
    tile_pal = {}
    for i in range(len(tiles)):
        tile_pal[str(i)] = pal_labels[i]
    
    # Generate editor snippet
    ts_key = f'EXT:{args.name}'
    snippet_path = os.path.join(out_dir, f'{args.name}_editor_snippet.js')
    with open(snippet_path, 'w') as f:
        f.write(f'// Add to TILE_PAL object in editor HTML:\n')
        f.write(f'"{ts_key}": {json.dumps(tile_pal)},\n\n')
        f.write(f'// Add to TILE_THRESH object:\n')
        f.write(f'"{ts_key}": 0,  // all tiles wall by default — use walkability editor to set\n\n')
        f.write(f'// Add to tileset select dropdown:\n')
        f.write(f'// <option value="{ts_key}">{args.name} (imported)</option>\n\n')
        f.write(f'// Add to tsDB object (base64 tileset image):\n')
        f.write(f'"{ts_key}": "data:image/png;base64,{b64}",\n')
    print(f"Editor snippet: {snippet_path}", file=sys.stderr)
    
    # Summary
    print(f"\n=== Summary ===", file=sys.stderr)
    print(f"Tileset: {ts_key}", file=sys.stderr)
    print(f"Tiles: {len(tiles)}", file=sys.stderr)
    print(f"Palette groups: {n_pals}", file=sys.stderr)
    for group in range(n_pals):
        count = pal_labels.count(group)
        pal = merged_palettes.get(group, [(0,0,0)]*4)
        pal_str = ' '.join(f'({r*8},{g*8},{b*8})' for r,g,b in pal)
        print(f"  Group {group}: {count} tiles  colors: {pal_str}", file=sys.stderr)


if __name__ == '__main__':
    main()
