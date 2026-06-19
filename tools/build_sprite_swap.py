#!/usr/bin/env python3
"""
build_sprite_swap.py — POC monster battle-sprite swap (Dracky -> DWM2 clam).

Mechanism (verified this session, see GRAPHICS notes):
  Battle sprite gfx-ID for a species is read from the table at $00:$2B9F
  (species*2). Dracky (sp 78) -> gfx-ID $3627 (bank $36, idx $27), a 576-byte
  (36-tile / 48x48) stream resolved via the per-bank pointer table at
  $<bank>:$4001 + idx*2, then RLE/LZ-decompressed by $00:$1627 into VRAM $8B00.

  Streams use a 3-byte header [declen_lo, declen_hi, runmark] then a body where
  a byte == runmark introduces a back-reference (into shared VRAM), else literal.
  -> If the body contains NO runmark byte, it decodes as a pure LITERAL copy.
     This POC authors a self-contained literal 36-tile stream (clam + blanks),
     independent of the shared tile pool, and REPOINTS Dracky's pointer-table
     entry (bank $36, Entry 39 = idx $27) to it in bank $36 free space ($78B6+).

Deliverables: patches/bank_036.asm  + this tool.  Clean build stays 1ca6579.
"""
import sys, os
from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEET = sys.argv[1] if len(sys.argv) > 1 else '/tmp/dwm2_sprites/W.png'
OUT_ASM = os.path.join(REPO, 'patches', 'bank_036.asm')
CLEAN_ASM = os.path.join(REPO, 'disassembly', 'bank_036.asm')
PREVIEW = sys.argv[2] if len(sys.argv) > 2 else '/tmp/clam_inserted_field.png'

DECLEN = 576            # 36 tiles, must match what the loader expects
FIELD_COLS, FIELD_ROWS = 6, 6
ENTRY_LINE_MATCH = 'dw $77FC'   # Entry 39 (idx $27) pointer to repoint
BG = (255, 194, 14)

# ---- extract clam (row 1, first big block) ----
im = Image.open(SHEET).convert('RGB')
# tight crop of clam from measured block (x 10..36, y 7..63) -> bbox
import numpy as np
crop = im.crop((9, 7, 38, 64))
a = np.array(crop); mask = ~np.all(a == BG, axis=2)
ys, xs = np.where(mask.any(1))[0], np.where(mask.any(0))[0]
clam = crop.crop((xs.min(), ys.min(), xs.max()+1, ys.max()+1))   # tight clam

# paste into 32x32 (centered), background = BG (-> palette index 0)
canvas = Image.new('RGB', (32, 32), BG)
ox = (32 - clam.width)//2; oy = (32 - clam.height)//2
canvas.paste(clam, (ox, oy))

# quantize: BG -> backdrop index; body pixels -> BODY_INDICES (lightest..darkest)
# Dracky battle palette (probe-confirmed): 0=red 1=white/transparent 2=gold/brown 3=black
BG_INDEX = int(os.environ.get('BG_INDEX', '1'))          # white/transparent backdrop
BODY_INDICES = [int(x) for x in os.environ.get('BODY_INDICES', '2,3').split(',')]  # light..dark
ca = np.array(canvas)
lum = (0.299*ca[:,:,0] + 0.587*ca[:,:,1] + 0.114*ca[:,:,2])
isbg = np.all(ca == BG, axis=2)
idxmap = np.zeros((32,32), dtype=int)
fg = ~isbg
if fg.any():
    fl = lum[fg]
    lo, hi = fl.min(), fl.max()
    n = len(BODY_INDICES)
    for yy in range(32):
        for xx in range(32):
            if isbg[yy,xx]:
                idxmap[yy,xx] = BG_INDEX
            else:
                t = (lum[yy,xx]-lo)/(hi-lo+1e-6)   # 0=dark..1=light
                bucket = min(n-1, int((1.0-t)*n))  # 0=lightest bucket
                idxmap[yy,xx] = BODY_INDICES[bucket]

# build 48x48 index field, clam (32x32) placed at tile (1,1); whole field = backdrop
field = np.full((48,48), BG_INDEX, dtype=int)
field[8:40, 8:40] = idxmap

MODE = sys.argv[3] if len(sys.argv) > 3 else 'clam'
if MODE == 'probe':
    # 4 vertical bars of palette index 0,1,2,3 (each 12px wide) to read the palette
    field = np.zeros((48,48), dtype=int)
    for x in range(48):
        field[:, x] = min(3, x // 12)

# encode 48x48 index field -> 36 tiles (row-major 6x6), each 16 bytes 2bpp
def tile_bytes(ti, tj):
    out = bytearray()
    for r in range(8):
        lo = hi = 0
        for c in range(8):
            v = field[tj*8 + r, ti*8 + c]
            lo |= ((v & 1) << (7-c))
            hi |= (((v>>1) & 1) << (7-c))
        out.append(lo); out.append(hi)
    return out

data = bytearray()
for tj in range(FIELD_ROWS):
    for ti in range(FIELD_COLS):
        data += tile_bytes(ti, tj)
assert len(data) == DECLEN, len(data)

# choose runmark absent from data
present = set(data)
runmark = next(b for b in range(256) if b not in present)
stream = bytes([DECLEN & 0xFF, (DECLEN>>8)&0xFF, runmark]) + bytes(data)

# ---- save preview PNG (real Dracky battle palette: 0=red 1=white 2=gold/brown 3=black) ----
PAL = [(200,44,44),(248,248,248),(176,128,48),(24,24,24)]
pv = Image.new('RGB',(48,48))
for y in range(48):
    for x in range(48):
        pv.putpixel((x,y), PAL[field[y,x]])
pv.resize((48*6,48*6), Image.NEAREST).save(PREVIEW)

# ---- emit patches/bank_036.asm ----
lines = open(CLEAN_ASM).read().split('\n')
# 1) repoint Entry 39
for i,l in enumerate(lines):
    if ENTRY_LINE_MATCH in l and 'Entry 39' in l:
        lines[i] = '    dw ClamBattleSprite                ; Entry 39 (idx $27) POC: Dracky->Clam (was $77FC)'
        break
else:
    sys.exit('ERROR: Entry 39 line not found')

# 2) place stream in the label-free zero block that ENDS at Jump_036_7c0d ($7C0D).
#    That block ($78B6-$7C0C) is 855 contiguous zero bytes with no labels.
ANCHOR = 'Jump_036_7c0d:'
def db_zero_bytes(s):
    # returns byte count if line is 'db $00[, $00]*' (all zero), else None
    s = s.strip()
    if not s.startswith('db '): return None
    toks = [t.strip() for t in s[3:].split(',')]
    if all(t == '$00' for t in toks): return len(toks)
    return None
def line_zero_bytes(l):
    s = l.strip()
    if s == 'nop': return 1
    if s == '': return 0
    z = db_zero_bytes(l)
    return z   # int or None
J = next(i for i,l in enumerate(lines) if l.strip() == ANCHOR)
# walk backward collecting contiguous zero-emitting lines
Z = J
byte_count = 0
i = J-1
while i >= 0:
    zb = line_zero_bytes(lines[i])
    if zb is None: break
    byte_count += zb
    Z = i
    i -= 1
assert ':' not in ''.join(lines[Z:J]), 'label inside target zero block'
assert byte_count >= len(stream), f'zero block {byte_count} < stream {len(stream)}'
db_lines = ['ClamBattleSprite:  ; POC self-contained literal 36-tile clam stream (Dracky->Clam)']
for o in range(0, len(stream), 16):
    db_lines.append('    db ' + ', '.join('$%02x'%b for b in stream[o:o+16]))
fill = byte_count - len(stream)
db_lines.append(f'    ds {fill}   ; zero fill (preserve {ANCHOR} @ $7C0D, bank size)')
new_lines = lines[:Z] + db_lines + lines[J:]
open(OUT_ASM,'w').write('\n'.join(new_lines) + '\n')
print(f'runmark=${runmark:02x} stream={len(stream)}B zero_block={byte_count}B fill={fill}')
print(f'wrote {OUT_ASM}')
print(f'preview {PREVIEW}')
