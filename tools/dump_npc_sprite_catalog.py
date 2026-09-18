#!/usr/bin/env python3
"""dump_npc_sprite_catalog.py — empirical NPC field-sprite catalog (S91, ROADMAP P3.1).

Renders every candidate NPC sprite id SOLO in the Castle throne room (screen 1,
step 4) by binary-poking that step's interact block in a TEMP COPY of the clean
ROM, booting PyBoy through the scripted intro, warping in, and cropping the
16x16 cell at walk position (1,2). Solo rendering is mandatory: the per-screen
VRAM sprite-sheet budget blanks later ids when several distinct sheets load
(see ROOM_DATA_FORMAT "NPC capacity & sprite-sheet budget", S91).

Outputs (all under extracted/):
  npc_sprite_catalog.json        one record per id (see schema in _meta)
  npc_sprite_catalog_sheet.png   labeled contact sheet
  npc_field_sprites/id_XX.png    per-id 16x16 crop (throne-room background)

Usage:
  python3 tools/dump_npc_sprite_catalog.py --render [--ids 00-3F]   # emulator pass (chunkable)
  python3 tools/dump_npc_sprite_catalog.py --finalize               # JSON + sheet from crops

The render pass caches a post-intro savestate at /tmp/npccat_state.pkl and the
empty-room baseline, so chunked runs stay fast (~3.5 s/id). Names are merged
from extracted/npc_names.json (hand-curated; GUI-owned) at --finalize time.
Category assignments are the user's visual classification from S91 and are
embedded below — they are DATA (user testimony), not measurement.

Measured S91 on both the clean ROM (this tool's path) and the S85b patched ROM
with the user's real .sav: renders are deterministic and independent of prior
VRAM contents (same-cell hash equality under castle- vs arena-primed VRAM).
"""
import argparse, hashlib, json, os, sys, shutil

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
OUTDIR = os.path.join(REPO, 'extracted')
CROPDIR = os.path.join(OUTDIR, 'npc_field_sprites')
TMPROM = '/tmp/npccat_rom.gbc'
STATE = '/tmp/npccat_state.pkl'
EMPTY = '/tmp/npccat_empty.png'

# Castle screen 1 ($4C3D block, counter $D92B) step 4 interact block: 8 NPC
# entries of 5 bytes at flat 183595 (bank $0B, $4D2B), terminator at 183635.
# Derivation: $0B:$4B43[mt*2] -> sub_table $4C13; sub[1] -> $4C3D; step entry
# 4 -> interact $4D2B. Verified against ROOM_DATA_FORMAT pointer chain.
ENTS = 183595
CTR = 0xD92B
CELL = (1, 2)          # screen-local walk cell for the solo NPC
WARP_TO = (0x00, 14, 7)  # castle, abs tile x/y inside screen 1

CANDIDATE_IDS = list(range(0x00, 0x80)) + [0xE0, 0xE1, 0xE2, 0xE3,
                                           0xF0, 0xF1, 0xF2, 0xF3, 0xFF]

# Hand classifications live in extracted/npc_names.json ("sprite_classes",
# user visual classification S91) and are merged at --finalize time — ONE
# home, user-editable, GUI-owned. Only MEASURED facts are embedded here:
# Measured S91: pixel-identical to id $00's render (deterministic fallback).
ALIAS_OF_00 = [0x4E, 0x4F, 0xF0, 0xF1, 0xF2, 0xF3]


def write_batch_rom(sid):
    rom = bytearray(open(ROM, 'rb').read())
    x, y = CELL
    rom[ENTS:ENTS + 5] = bytes([0x00, sid, x, y, 0xFF])
    rom[ENTS + 5] = 0xFF
    open(TMPROM, 'wb').write(rom)


SAV = os.environ.get('NPCCAT_SAV')  # or set by --sav; canonical mode (matches the S91 user-validated crops)


def get_state():
    from tools.pyboy_harness import boot, boot_with_sav, to_bedroom, adv, tap
    if os.path.exists(STATE):
        return
    shutil.copy(ROM, TMPROM)
    if SAV:
        # Canonical: boot the user's real battery save (CONTINUE), back out of
        # any menu the A-mash opened. This is the state the S91 crops were
        # user-validated in; the intro-skip state below renders with a
        # different scroll/HUD layout (crops differ cosmetically).
        p = boot_with_sav(TMPROM, SAV)
        adv(p, 280); tap(p, 'start'); adv(p, 60)
        for _ in range(60):
            tap(p, 'a', wait=10)
            if p.memory[0xC968] != 0 or p.memory[0xC88A] == 1:
                break
        adv(p, 300)
        for _ in range(8):
            tap(p, 'b', wait=20)
        adv(p, 60)
    else:
        p = boot(TMPROM)
        assert to_bedroom(p), 'scripted intro failed'
    with open(STATE, 'wb') as f:
        p.save_state(f)
    p.stop(save=False)


def render_one(sid_or_none, out_png):
    from tools.pyboy_harness import boot, adv, warp, snap
    if sid_or_none is None:
        rom = bytearray(open(ROM, 'rb').read())
        rom[ENTS] = 0xFF
        open(TMPROM, 'wb').write(rom)
    else:
        write_batch_rom(sid_or_none)
    p = boot(TMPROM)
    with open(STATE, 'rb') as f:
        p.load_state(f)
    adv(p, 10)
    p.memory[CTR] = 4
    warp(p, *WARP_TO, settle=400)
    ok = (p.memory[0xC968] == WARP_TO[0])
    snap(p, out_png)
    p.stop(save=False)
    return ok


def get_crop_box():
    """The playfield's on-screen origin depends on game state (HUD layout),
    so derive the cell's pixel origin by diffing a known-rendering id ($10,
    the castle guard) against the empty render, snapping to the 16x16 cell
    containing the diff bounding box. Cached at /tmp/npccat_box.json."""
    from PIL import Image
    import numpy as np
    cache = '/tmp/npccat_box.json'
    if os.path.exists(cache):
        return tuple(json.load(open(cache)))
    calib = '/tmp/npccat_calib.png'
    render_one(0x10, calib)
    a = np.array(Image.open(calib).convert('RGB')).astype(int)
    b = np.array(Image.open(EMPTY).convert('RGB')).astype(int)
    d = (np.abs(a - b).sum(axis=2) > 30).astype(int)
    assert d.sum(), 'calibration render produced no diff'
    # Animated BG tiles (torches/curtain) flicker between any two screenshots,
    # so the bbox corner is unreliable; take the 16x16 window with the highest
    # diff mass (the sprite itself) instead.
    ii = d.cumsum(0).cumsum(1)
    best, box = -1, None
    H, W = d.shape
    for y0 in range(H - 16):
        for x0 in range(W - 16):
            s = ii[y0+15, x0+15] - (ii[y0-1, x0+15] if y0 else 0) \
                - (ii[y0+15, x0-1] if x0 else 0) \
                + (ii[y0-1, x0-1] if y0 and x0 else 0)
            if s > best:
                best, box = s, (x0, y0, x0 + 16, y0 + 16)
    # Snap to the walk-cell grid: sprites are drawn cell-aligned, and an
    # unsnapped max-diff window mis-crops (S91: committed crops were re-cut
    # from the sav-mode canonical run after this bug shifted the first set).
    x0 = (box[0] + 8) // 16 * 16
    y0 = (box[1] + 8) // 16 * 16
    box = (x0, y0, x0 + 16, y0 + 16)
    json.dump(box, open(cache, 'w'))
    return box


def cmd_render(ids):
    from PIL import Image
    os.makedirs(CROPDIR, exist_ok=True)
    get_state()
    if not os.path.exists(EMPTY):
        render_one(None, EMPTY)
    box = get_crop_box()
    for sid in ids:
        shot = f'/tmp/npccat_{sid:02X}.png'
        ok = render_one(sid, shot)
        Image.open(shot).crop(box).save(os.path.join(CROPDIR, f'id_{sid:02X}.png'))
        print(f'{sid:02X}: {"ok" if ok else "WARP FAILED"}')


def cmd_finalize():
    from PIL import Image, ImageDraw
    import numpy as np
    box = get_crop_box() if os.path.exists(EMPTY) else None
    base = np.array(Image.open(EMPTY).convert('RGB').crop(box)).astype(int) \
        if box else None
    names, classes = {}, {}
    np_path = os.path.join(OUTDIR, 'npc_names.json')
    if os.path.exists(np_path):
        nd = json.load(open(np_path))
        names = {int(k, 16): v for k, v in
                 nd.get('sprite_names', {}).items() if v}
        classes = {int(k, 16): v for k, v in
                   nd.get('sprite_classes', {}).items()
                   if k != '_comment'}
    recs = {}
    for sid in CANDIDATE_IDS:
        f = os.path.join(CROPDIR, f'id_{sid:02X}.png')
        if not os.path.exists(f):
            continue
        im = np.array(Image.open(f).convert('RGB')).astype(int)
        diff = int((np.abs(im - base).sum(axis=2) > 30).sum()) if base is not None else None
        if sid in classes:
            cat = classes[sid]
        elif sid in ALIAS_OF_00:
            cat = 'alias_of_00'
        else:
            cat = 'normal'
        rec = {'renders': diff is None or diff > 0, 'category': cat,
               'diff_px_vs_empty': diff}
        if sid in names:
            rec['name'] = names[sid]
        if sid in ALIAS_OF_00:
            rec['alias_of'] = '0x00'
        recs[f'0x{sid:02X}'] = rec
    out = {
        '_generator': 'tools/dump_npc_sprite_catalog.py (PyBoy render census, '
                      'clean data/DWM-original.gbc, S91)',
        '_meta': {
            'method': 'solo render per id, Castle throne room screen 1 step 4, '
                      'cell (1,2); crops on throne-room background; solo is '
                      'mandatory because of the per-screen VRAM sprite-sheet '
                      'budget (ROOM_DATA_FORMAT S91)',
            'valid_authorable_range': 'normal category ids; hard sprite-byte '
                                      'range with art: $00-$5F sparse + $E0/$E1; '
                                      'no id crashes the renderer in vanilla '
                                      'rooms (S70 $11-crash was custom-room '
                                      'context, DOC_AUDIT S91)',
            'categories': ['normal', 'boss_composite_fragment', 'alias_of_00',
                           'empty', 'glitch_invalid'],
            'names_source': 'extracted/npc_names.json (hand-curated, GUI-owned; '
                            'merged at finalize time — re-run --finalize after '
                            'naming)',
            'classification_source': 'npc_names.json sprite_classes '
                                     '(hand-curated, user visual '
                                     'classification S91)',
            'crops_provenance': 'committed crops = the S91 sav-mode canonical '
                                'run (user-validated sheet); clean-ROM '
                                '--render reproduces the same art on the '
                                'intro-skip state',
        },
        'sprites': recs,
    }
    with open(os.path.join(OUTDIR, 'npc_sprite_catalog.json'), 'w') as f:
        json.dump(out, f, indent=1)
    # contact sheet
    ids = [s for s in CANDIDATE_IDS
           if os.path.exists(os.path.join(CROPDIR, f'id_{s:02X}.png'))]
    cols, sz, pad, label = 12, 16, 6, 10
    rows = (len(ids) + cols - 1) // cols
    W, H = cols * (sz + pad) + pad, rows * (sz + pad + label) + pad
    sheet = Image.new('RGB', (W, H), (245, 245, 245))
    dr = ImageDraw.Draw(sheet)
    for k, sid in enumerate(ids):
        r, c = divmod(k, cols)
        x, y = pad + c * (sz + pad), pad + r * (sz + pad + label)
        sheet.paste(Image.open(os.path.join(CROPDIR, f'id_{sid:02X}.png')), (x, y))
        dr.text((x + 1, y + sz), f'{sid:02X}', fill=(0, 0, 0))
    sheet.resize((W * 3, H * 3), Image.NEAREST).save(
        os.path.join(OUTDIR, 'npc_sprite_catalog_sheet.png'))
    print(f'wrote npc_sprite_catalog.json ({len(recs)} ids) + sheet')


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--render', action='store_true')
    ap.add_argument('--finalize', action='store_true')
    ap.add_argument('--sav', default=None,
                    help='path to a raw battery .sav; canonical mode matching '
                         'the S91 user-validated crops')
    ap.add_argument('--ids', default=None,
                    help='hex range like 00-3F or comma list; default all')
    a = ap.parse_args()
    if a.sav:
        SAV = a.sav
    if a.render:
        if a.ids:
            if '-' in a.ids:
                lo, hi = (int(x, 16) for x in a.ids.split('-'))
                ids = [i for i in CANDIDATE_IDS if lo <= i <= hi]
            else:
                ids = [int(x, 16) for x in a.ids.split(',')]
        else:
            ids = CANDIDATE_IDS
        cmd_render(ids)
    if a.finalize:
        cmd_finalize()
    if not (a.render or a.finalize):
        ap.print_help()
