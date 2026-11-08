#!/usr/bin/env python3
"""resection_npc_sprite_tables.py — S172 (Iron Rule 6): the plain-NPC sprite tables and
(S172 r2) the gate pickup-icon tables in their clean form, in BOTH trees (byte-neutral).

mgbdis decoded three per-sprite-id tables as instructions:

  * ROM0 `NpcSheetGfxTable` $2ADF (96 dw, ids $00-$5F): the gfx-ID of each plain NPC
    sprite's 16-tile sheet (bank $0B `Call_00b_4839` at the room load, bank $06
    `ReloadNPCSheets`) — `Data_2ADD` + the fake code up to `MonsterBattleGfxTable`;
  * bank $05 `NpcSpriteFrameTable` $407F (96 dw): the level-1 table — per id a list of
    6 frame pointers (down A/B, side A/B, up A/B) read by bank $05 entries 0 / 1 through
    ROM0 $0D91 with bank $05 mapped; ids with ONE frame (the objects: $50 / $51 heads in
    bed, $5F the meat, $58-$5D = $50's list) point at a list whose second word is the
    frame's own bytes;
  * bank $05 `NpcSpritePalTable` $4152 (96 db): the OBJ palette 0-7 each id ORs into
    its OAM attr (`NPCSpritePaletteOr`).

  * (S172 r2) bank $01 `PickupIconTiles` $6037 / `PickupIconAttr` $6077 (64 db each) and
    `PickupIconOfItem` $60B7 (48 db): a gate-floor pickup's icon (item id -> 0-7) and that
    icon's tile base / OBJ palette, read by `CheckDirectionBit7` (the code's `ld hl, $xxxx`
    now name them).

Between the two bank $05 tables sit $5F's level-1 list ($413F) and its one frame
($4141, four 8x8 pieces TL / TR / BL / BR, `$80`).

Labels other bytes point at (mgbdis fake code in banks $1D / $3A / ROM0 jumps into
the ROM0 range) are kept at their offsets; a label on an odd offset splits its word
into two `db`. Every other label inside a range is referenced only by the fake code
being replaced (checked: the tool refuses to drop a label referenced elsewhere).

Checks: the clean build stays 1ca6579…; run test_compiler for the patched tree.
Idempotent (skips a range whose head label already exists).

    python3 tools/resection_npc_sprite_tables.py
"""
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, 'tools'))
from sm83dis import decode                         # noqa: E402

ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_.]*):{1,2}')


def rom():
    return open(ROM, 'rb').read()


def off(bank, addr):
    return addr if bank == 0 else bank * 0x4000 + addr - 0x4000


def line_len(R, bank, addr, code):
    """Bytes one asm line emits (code = the line without comment / label)."""
    s = code.strip()
    if not s:
        return 0
    low = s.lower()
    if low.startswith('db '):
        return len([x for x in s[3:].split(',') if x.strip()])
    if low.startswith('dw '):
        return 2 * len([x for x in s[3:].split(',') if x.strip()])
    if low.startswith(('section', 'include', 'assert', 'def ', 'endc', 'if ')):
        return 0
    return decode(R, off(bank, addr), addr)[1]


def walk(lines, start_idx, start_addr, end_addr, R, bank):
    """-> (first line index, end line index (exclusive), end address reached, {label: addr})"""
    addr = start_addr
    labels = {}
    i = start_idx
    while addr < end_addr:
        raw = lines[i].split(';', 1)[0].rstrip('\n')
        m = LABEL_RE.match(raw)
        if m:
            labels[m.group(1)] = addr
            raw = raw[m.end():]
        addr += line_len(R, bank, addr, raw)
        i += 1
    # labels sitting exactly at the end belong to what follows
    return i, addr, labels


def referenced_elsewhere(label, files, own_file, span):
    pat = re.compile(r'\b' + re.escape(label) + r'\b')
    for f in files:
        for n, ln in enumerate(open(f, encoding='utf-8')):
            code = ln.split(';', 1)[0]
            if not pat.search(code) or LABEL_RE.match(code.strip()) and code.strip().startswith(label + ':'):
                continue
            if f == own_file and span[0] <= n < span[1]:
                continue
            return True
    return False


def asm_files():
    out = []
    for d in ('disassembly', 'patches'):
        for fn in sorted(os.listdir(os.path.join(REPO, d))):
            if fn.endswith('.asm'):
                out.append(os.path.join(REPO, d, fn))
    tpl = os.path.join(REPO, 'editor2', 'core', 'templates')
    out += [os.path.join(tpl, f) for f in sorted(os.listdir(tpl)) if f.endswith('.asm')]
    return out


def tree_files(path):
    """The files of path's tree (references from the other tree do not count)."""
    d = os.path.dirname(path)
    fs = [os.path.join(d, f) for f in sorted(os.listdir(d)) if f.endswith('.asm')]
    if os.path.basename(d) == 'patches':          # the overlay = patches + the rest of disassembly
        names = {os.path.basename(f) for f in fs}
        dd = os.path.join(REPO, 'disassembly')
        fs += [os.path.join(dd, f) for f in sorted(os.listdir(dd))
               if f.endswith('.asm') and f not in names]
    return fs


def replace_range(path, bank, anchor, anchor_addr, end_addr, render, keep_first_label=True):
    """Replace the lines from `anchor`'s line (anchor_addr) up to end_addr with
    render(R, labels_to_keep) -> list of lines; labels referenced from outside kept."""
    R = rom()
    lines = open(path, encoding='utf-8').readlines()
    idx = next(n for n, ln in enumerate(lines) if ln.startswith(anchor + ':'))
    end_i, addr, labels = walk(lines, idx, anchor_addr, end_addr, R, bank)
    if addr != end_addr:
        raise SystemExit(f'{path}: {anchor}: the walk ends at ${addr:04X}, not ${end_addr:04X} '
                         '(an instruction crosses the boundary)')
    keep = {}
    files = tree_files(path)
    for lab, a in labels.items():
        if lab == anchor and keep_first_label:
            keep[lab] = a
        elif referenced_elsewhere(lab, files, path, (idx, end_i)):
            keep[lab] = a
    new = render(R, keep)
    lines[idx:end_i] = [x + '\n' for x in new]
    open(path, 'w', encoding='utf-8').write(''.join(lines))
    return keep


def data_rows(R, bank, start, end, kind, keep, name_of, per_line=1):
    """Lines for bytes [start, end): `dw` (kind 'w') or `db` rows, one entry per id, with
    a kept label on its own line (odd offset inside a word -> that word as two db)."""
    out = []
    a = start
    while a < end:
        if kind == 'w':
            lab_mid = [l for l, x in keep.items() if x == a + 1]
            for l, x in keep.items():
                if x == a:
                    out.append(f'{l}:')
            w = R[off(bank, a)] | R[off(bank, a) + 1] << 8
            if lab_mid:
                out.append(f'    db ${R[off(bank, a)]:02x}   ; {name_of(a)} (lo)')
                for l in lab_mid:
                    out.append(f'{l}:   ; (an anchor other bytes jump to)')
                out.append(f'    db ${R[off(bank, a) + 1]:02x}   ; {name_of(a)} (hi) = ${w:04X}')
            else:
                out.append(f'    dw ${w:04X}   ; {name_of(a)}')
            a += 2
        else:
            for l, x in keep.items():
                if x == a:
                    out.append(f'{l}:')
            out.append(f'    db ${R[off(bank, a)]:02x}   ; {name_of(a)}')
            a += 1
    return out


SPRITE_NAMES = None


def sprite_name(i):
    global SPRITE_NAMES
    if SPRITE_NAMES is None:
        import json
        try:
            SPRITE_NAMES = json.load(open(os.path.join(REPO, 'extracted', 'npc_names.json')))
        except OSError:
            SPRITE_NAMES = {}
    nm = SPRITE_NAMES.get('names', SPRITE_NAMES).get(f'0x{i:02X}', '') if isinstance(SPRITE_NAMES, dict) else ''
    extra = {0x5F: 'the meat (an object, one frame)', 0x14: 'Milayou', 0x5E: 'Terry as an NPC',
             0x4D: 'the gate swirl', 0x21: 'Watabou', 0x39: 'Warubou (grey)'}
    nm = extra.get(i, nm)
    if 0x58 <= i <= 0x5D:
        nm = "unused: $50's sheet and frames"
    return f'[${i:02X}]' + (f' {nm}' if isinstance(nm, str) and nm else '')


ROM0_HEAD = """\
; ---------------------------------------------------------------------------
; Data_2ADD: the last word of the table before (2 B), then NpcSheetGfxTable.
; NpcSheetGfxTable (ROM0 $2ADF, S172 re-section; was mgbdis fake code — S170 note):
; one gfx-ID per plain NPC sprite id $00-$5F (96 dw, up to MonsterBattleGfxTable):
; the 16-tile sheet the room load (bank $0B Call_00b_4839) and bank $06
; ReloadNPCSheets DMA to the NPC's VRAM page. gfx-ID = bank << 8 | index into that
; bank's pointer table at $4001 (ROM0 DecompressTileLayout). Ids $3A-$4C name the
; ORIGINAL walking streams of 19 monsters (the farm's decorative monster NPCs, kept
; by gamedata.art — S170); $58-$5D repeat $50's sheet (unused ids). Patched builds:
; ids $58-$5F are region npc_food_sheets (S172, gamedata.foods — the foods' own sheets).
; ---------------------------------------------------------------------------"""

B05_L1_HEAD = """\
; ---------------------------------------------------------------------------
; NpcSpriteFrameTable ($05:$407F, S172 re-section; was mgbdis fake code): per plain NPC
; sprite id $00-$5F the level-1 pointer = a list of 6 frame pointers (down A, down B,
; side A, side B, up A, up B; side faces right, the left side = the same with the
; X-flip) — entries 0 / 1 pick [list + 2 * $FFC8] through ROM0 $0D91 with bank $05
; mapped; a frame = 4-byte pieces (dy, dx, tile, attr) up to $80. The OBJECTS
; ($50 / $51 the heads in bed, $5F the meat, $58-$5D = $50's) have ONE frame: their
; list's second word is the frame itself, so a frame index 1-5 reads junk (standing
; NPCs step between frames 0 and 1 — PyBoy S172; the vanilla objects are shown by
; scripts only). Patched builds with gamedata.foods: bank $77 NpcDrawPlain holds the
; food props on frame 0 (NpcStaticIds).
; ---------------------------------------------------------------------------"""

B05_PAL_HEAD = """\
; ---------------------------------------------------------------------------
; NpcSpritePalTable ($05:$4152, S172 re-section): the OBJ palette (0-7) of each plain
; NPC sprite id $00-$5F, ORed into $FFCA by NPCSpritePaletteOr. The field OBJ
; palettes ($17:$5615) are colour 1 cream, 2 the accent, 3 black: 0 red, 1 green,
; 2 light blue, 3 amber, 4 purple, 5 grey, 6 orange, 7 brown. Patched builds: ids
; $58-$5F are region npc_food_pals (S172, gamedata.foods).
; ---------------------------------------------------------------------------"""


def render_rom0(R, keep):
    out = ['Data_2ADD:', ROM0_HEAD,
           f'    db ${R[0x2ADD]:02x}, ${R[0x2ADE]:02x}   ; the previous table\'s last word']
    out.append('NpcSheetGfxTable:')
    keep2 = {k: v for k, v in keep.items() if k != 'Data_2ADD'}
    out += data_rows(R, 0, 0x2ADF, 0x2B9F, 'w', keep2,
                     lambda a: sprite_name((a - 0x2ADF) // 2))
    return out


def render_b05(R, keep):
    out = []
    keep2 = dict(keep)
    out.append(B05_L1_HEAD)
    out.append('NpcSpriteFrameTable:')
    out += data_rows(R, 5, 0x407F, 0x413F, 'w', keep2, lambda a: sprite_name((a - 0x407F) // 2))
    out.append("NpcFramesMeat:   ; $413F — $5F's level-1 list: frame 0 only (the next word is the frame)")
    out += data_rows(R, 5, 0x413F, 0x4141, 'w', keep2, lambda a: 'down A')
    out.append('NpcFrameMeat0:   ; $4141 — the meat: 2x2 pieces (dy, dx, tile, attr), $80')
    for k in range(4):
        b = R[off(5, 0x4141 + 4 * k):off(5, 0x4141 + 4 * k) + 4]
        out.append('    db ' + ', '.join(f'${x:02x}' for x in b)
                   + f"   ; {['top-left', 'top-right', 'bottom-left', 'bottom-right'][k]}: tile {b[2]}")
    out.append(f'    db ${R[off(5, 0x4151)]:02x}   ; end')
    out.append(B05_PAL_HEAD)
    out.append('NpcSpritePalTable:')
    out += data_rows(R, 5, 0x4152, 0x41B2, 'b', keep2, lambda a: sprite_name(a - 0x4152))
    return out


ICON_NAMES = ['heal (Herb, the books)', 'cure / MP (bottle)', 'item 9 (bell)', 'nut / seed',
              'MEAT (the five meats)', 'staff', 'WarpWing', 'TinyMedal / none']


def item_names():
    try:
        sys.path.insert(0, REPO)
        from editor2.core.shops import item_names as _n
        return _n(REPO)
    except Exception:                                   # noqa: BLE001
        return {}


PICKUP_HEAD = """\
; ---------------------------------------------------------------------------
; The gate-floor PICKUP ICONS (S172 r2 re-section; was mgbdis fake code). A floor item
; ($D793: [kind, item, X, Y]) is drawn by CheckDirectionBit7 above with icon
; PickupIconOfItem[item] (kind < 8) or icon = kind (8+): tile base PickupIconTiles[icon]
; -> $FFC9, OAM attr PickupIconAttr[icon] -> $FFCA, then bank $04 entry 0 (a 2 x 2 of 8 x 8
; pieces). The 8 icons' tiles = gfx $2E15-$2E1C at $8500-$86FF (bank $16
; EncounterSeedOnRoomLoad, every gate room load): 0 heal $50 green, 1 cure / MP $54 light
; blue, 2 bell $58 orange, 3 nut / seed $5C brown, 4 MEAT $60 red (all five meats), 5 staff
; $64 brown, 6 WarpWing $68 amber, 7 TinyMedal $6C amber. Patched builds with
; gamedata.foods: the call below the table goes to bank $77 FoodIconDraw (each food its own
; icon from VRAM bank 1 — PROJECT_COMPILER §2.78).
; ---------------------------------------------------------------------------"""


def render_pickups(R, keep):
    nm = item_names()
    out = [PICKUP_HEAD, 'PickupIconTiles:   ; $6037 — per icon (0-63): its first OBJ tile']
    out += data_rows(R, 1, 0x6037, 0x6077, 'b', keep,
                     lambda a: f'[{a - 0x6037}]' + (f' {ICON_NAMES[a - 0x6037]}' if a - 0x6037 < 8 else ''))
    out.append('PickupIconAttr:   ; $6077 — per icon (0-63): its OBJ palette (OAM attr)')
    out += data_rows(R, 1, 0x6077, 0x60B7, 'b', keep,
                     lambda a: f'[{a - 0x6077}]' + (f' {ICON_NAMES[a - 0x6077]}' if a - 0x6077 < 8 else ''))
    out.append('PickupIconOfItem:   ; $60B7 — per item id 0-47: its icon 0-7')
    out += data_rows(R, 1, 0x60B7, 0x60E7, 'b', keep,
                     lambda a: f'[{a - 0x60B7}] {nm.get(a - 0x60B7, "")}'.rstrip())
    return out


def pickups(path):
    if 'PickupIconOfItem:' in open(path, encoding='utf-8').read():
        print(f'{path}: pickups done already')
        return
    lines = open(path, encoding='utf-8').readlines()
    i = next(n for n, ln in enumerate(lines) if ln.startswith('CheckDirectionBit7:'))
    j = next(n for n in range(i, len(lines)) if lines[n].strip().startswith('rst $10'))
    k = next(n for n in range(j, len(lines)) if lines[n].strip() == 'ret')
    lines.insert(k + 1, '_PickupTablesStart:\n')
    open(path, 'w', encoding='utf-8').writelines(lines)
    kept = replace_range(path, 1, '_PickupTablesStart', 0x6037, 0x60E7, render_pickups,
                         keep_first_label=False)
    s = open(path, encoding='utf-8').read()
    for a, lab in (('$60b7', 'PickupIconOfItem'), ('$6037', 'PickupIconTiles'),
                   ('$6077', 'PickupIconAttr')):
        s = s.replace(f'    ld hl, {a}\n', f'    ld hl, {lab}   ; {a.upper()}\n', 1)
    open(path, 'w', encoding='utf-8').write(s)
    print(f'{os.path.relpath(path, REPO)}: PickupIconTiles / PickupIconAttr / PickupIconOfItem; '
          f'kept {sorted(kept)}')


def clean_build_md5():
    d = os.path.join(REPO, 'disassembly')
    for f in ('game.o', 'game.gbc', 'game.sym', 'game.map'):
        try:
            os.remove(os.path.join(d, f))
        except OSError:
            pass
    subprocess.run(['make'], cwd=d, check=True, stdout=subprocess.DEVNULL)
    import hashlib
    return hashlib.md5(open(os.path.join(d, 'game.gbc'), 'rb').read()).hexdigest()


def main():
    dis0 = os.path.join(REPO, 'disassembly', 'bank_000.asm')
    pat0 = os.path.join(REPO, 'patches', 'bank_000.asm')
    dis5 = os.path.join(REPO, 'disassembly', 'bank_005.asm')
    for p in (dis0, pat0):
        if 'NpcSheetGfxTable:' in open(p, encoding='utf-8').read():
            print(f'{p}: done already')
            continue
        kept = replace_range(p, 0, 'Data_2ADD', 0x2ADD, 0x2B9F, render_rom0)
        print(f'{os.path.relpath(p, REPO)}: NpcSheetGfxTable; kept {sorted(kept)}')
    if 'NpcSpriteFrameTable:' not in open(dis5, encoding='utf-8').read():
        lines = open(dis5, encoding='utf-8').readlines()
        # the fake code starts right after NPCSpritePaletteOr's ret ($407F): give it an anchor
        i = next(n for n, ln in enumerate(lines) if ln.startswith('NPCSpritePaletteOr:'))
        j = next(n for n in range(i, len(lines)) if lines[n].strip() == 'ret')
        lines.insert(j + 1, '_NpcTablesStart:\n')
        open(dis5, 'w', encoding='utf-8').writelines(lines)
        kept = replace_range(dis5, 5, '_NpcTablesStart', 0x407F, 0x41B2, render_b05,
                             keep_first_label=False)
        print(f'disassembly/bank_005.asm: NpcSpriteFrameTable / NpcSpritePalTable; kept {sorted(kept)}')
    for p in (os.path.join(REPO, 'disassembly', 'bank_001.asm'),
              os.path.join(REPO, 'patches', 'bank_001.asm')):
        pickups(p)
    md5 = clean_build_md5()
    print('clean build', md5)
    if md5 != '1ca6579359f21d8e27b446f865bf6b83':
        raise SystemExit('FAIL: the clean build changed')


if __name__ == '__main__':
    main()
