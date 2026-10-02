#!/usr/bin/env python3
"""
resection_battle_anims.py — S112 (ROADMAP P3.11e, Iron Rule 6): the battle
ANIMATION data as labelled tables in BOTH trees, zero byte change (clean build
stays 1ca6579…; the patched pin is unchanged). Owning prose BATTLE_SKILL_SYSTEM
§11 "as measured S112"; the data model editor2/core/battle_anims.py; the
measurement tools/census_battle_anims.py.

Regions (all mgbdis fake code / raw before; bounds = the decoder's extents —
each bank's animation data is contiguous):
  bank $02  SeqRowTable $40E3 (97 dw: the generic sequencer's rows) and
            AnimTimelineTable $46A1 (row $60, 45 dw) + the 45 timelines
            $46FB-$4E16 (frame / hold pairs, $FD sound, $FE op, $FF end)
  bank $50  AnimGfxTable $5E84 (45 dw gfx ids) — both trees
  bank $5F  AnimCmdTableFoe $56ED / AnimCmdTableOwn $57D5 (232 db),
            AnimRoutineTable $58BD (16 dw -> labelled routines),
            AnimRoutineIdxParty $58DD / Enemy $59C3 / Link $5AA9 (230 db),
            AnimGfxTableDebug $61EE (45 dw, the Effect debugger's copy) — both trees
  banks $5C/$5D/$5E  AnimFrameTable5x $4071 (14 / 33 / 45 dw), AnimTargetXTable5x
            (7 dw by [$db54]) and the animation data (per animation 32 dw frame
            pointers + the frames: 4-byte sprites, $80 end)
  bank $00  AnimObjShadeTable $3141 (45 db, the DMG OBP1 byte) — both trees
  bank $17  AnimObjPalettes $6B0D (45 x 4 RGB555) — both trees
  bank $5A  AnimGfxPtrs5A $4001 (32 dw) + the 32 tile streams $4041-$7E30
  bank $5B  GfxPtrs5B $4001 (34 dw) + the 13 animation tile streams $417F-$5BD9
plus labels on the code (routines, renderer entries, the Effect debugger)
and renames of the mgbdis names on the animation code (every reference in
both trees follows; the build checks the byte identity).

Method = the repo's probe-build splice (tools/resection_monster_art_tables.py:
zero-byte probe labels -> line addresses from game.sym -> the window [A, B)
around the region is emitted as exact bytes; fake-decode labels that anything
references are kept at their byte offsets). Idempotent.

Run:  python3 tools/resection_battle_anims.py
"""
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools import resection_monster_art_tables as RS  # noqa: E402
from editor2.core import battle_anims as BA  # noqa: E402

DIS, PAT = RS.DIS, RS.PAT

# fast `referenced`: one identifier census of both trees per file state (the
# original re-reads every file per label — minutes for the frame banks)
import collections
import glob as _glob
_CENSUS = {}
_IDENT = re.compile(r'[A-Za-z_][A-Za-z0-9_.]*')


def _census():
    files = sorted(_glob.glob(os.path.join(DIS, '*.asm')) + _glob.glob(os.path.join(PAT, '*.asm')))
    key = tuple((f, os.path.getmtime(f)) for f in files)
    if _CENSUS.get('key') != key:
        c = collections.Counter()
        for f in files:
            c.update(_IDENT.findall(open(f).read()))
        _CENSUS.update(key=key, c=c)
    return _CENSUS['c']


def _referenced(label, exclude_text):
    total = _census()[label]
    ex = collections.Counter(_IDENT.findall(exclude_text))[label]
    return total > ex


RS.referenced = _referenced
R = open(RS.ROM, 'rb').read()
D = BA.decode_rom(R)


def b(bank, a):
    return R[bank * 0x4000 + a - 0x4000 if bank else a]


def w(bank, a):
    return b(bank, a) | b(bank, a + 1) << 8


def rb(bank, a, n):
    return bytes(b(bank, a + k) for k in range(n))


def skill_names():
    import json
    return {r['id']: r['name'] for r in json.load(open(os.path.join(
        REPO, 'extracted', 'skill_records.json')))['records']}


NAMES = skill_names()


def tag(s):
    return re.sub(r'[^A-Za-z0-9]', '', s) or 'X'


def anim_users(c):
    out = []
    for row in D['skills']:
        if row['cmd_foe'] == c or row['cmd_own'] == c:
            out.append(NAMES.get(row['id'], str(row['id'])))
    return out


def anim_name(c):
    u = anim_users(c)
    return tag(u[0]) if u else 'Unused'


def users_text(c):
    u = anim_users(c)
    return ', '.join(u[:6]) + (f' (+{len(u) - 6})' if len(u) > 6 else '') if u else 'no skill'


def dbrow(bs):
    return '    db ' + ', '.join(f'${x:02x}' for x in bs)


# ---------------------------------------------------------------------------
# row generators: (segs, data) — segs = [(addr|None, size, text)]
# ---------------------------------------------------------------------------

def rows_seq_top():
    base, n = 0x40E3, 97
    segs = [(None, 0, 'SeqRowTable:'),
            (None, 0, '    ; The generic SEQUENCER\'s row table (bank $02 entry 0 steps a struct'),
            (None, 0, '    ; [$d7b4] -> +0 active, +1 ROW, +2 index, +3 step, +4 value, +5 hold:'),
            (None, 0, '    ; ReadSeqStep reads SeqRowTable[row][index] -> the pair list, step'),
            (None, 0, '    ; by step). Row $60 = AnimTimelineTable (the battle animations,'),
            (None, 0, '    ; index = animation number; BATTLE_SKILL_SYSTEM §11). Other rows: other'),
            (None, 0, '    ; sequences (not traced; left as words). Re-sectioned S112.')]
    for i in range(n):
        v = w(2, base + 2 * i)
        if i == 0x60:
            segs.append((base + 2 * i, 2, f'    dw ${v:04x}   ; row ${i:02x} = AnimTimelineTable, the battle animations'))
        else:
            segs.append((base + 2 * i, 2, f'    dw ${v:04x}   ; row ${i:02x}'))
    return segs, rb(2, base, 2 * n)


def rows_timelines():
    base = 0x46A1
    end = max(e for s, e in D['extents']['02'])
    segs = [(None, 0, 'AnimTimelineTable:'),
            (None, 0, '    ; SeqRowTable row $60: the TIMELINE of each battle animation (45, by'),
            (None, 0, '    ; animation number = [$dd64] = $da81). Pairs (first, second): first < $F8 ='),
            (None, 0, '    ; show frame `first` for `second`+1 frames ([$dd66] -> the renderer\'s'),
            (None, 0, '    ; [$c8]; $1F = the blank frame); $FD = play sound `second` (no time);'),
            (None, 0, '    ; $FE = control op `second` (4 = back to step 1: the projectile loop of'),
            (None, 0, '    ; $03 / $04, left by the renderer at the target); $FF,$FF = end'),
            (None, 0, '    ; ([$dd62] = 0). MEASURED S112 for all 45 (tools/census_battle_anims.py).'),
            (None, 0, '    ; S112: new animations ($2D+) are read through ReadSeqStepFork (patches).')]
    for c in range(BA.N_STOCK):
        segs.append((base + 2 * c, 2, f'    dw AnimTimeline_{c:02x}_{anim_name(c):<12}; [${c:02x}] {users_text(c)}'))
    for c in range(BA.N_STOCK):
        a = D['animations'][c]
        p = a['timeline_ptr']
        segs.append((None, 0, f'AnimTimeline_{c:02x}_{anim_name(c)}:   ; ${p:04x} — {users_text(c)}'))
        q = p
        for s in a['timeline']:
            if 'frame' in s:
                cm = f'frame {s["frame"]:2d} for {s["hold"] + 1} frames' if s['frame'] != 0x1F else \
                    f'blank for {s["hold"] + 1} frames'
            elif 'sound' in s:
                cm = f'sound ${s["sound"]:02x}'
            else:
                cm = f'op {s["op"]}' + (' (back to step 1)' if s['op'] == 4 else '')
            segs.append((q, 2, f'{dbrow(rb(2, q, 2))}   ; {cm}'))
            q += 2
        segs.append((q, 2, f'{dbrow(rb(2, q, 2))}   ; end'))
        q += 2
    assert q == end
    return segs, rb(2, base, end - base)


def rows_gfx50():
    base = BA.GFX_TABLE
    segs = [(None, 0, 'AnimGfxTable:'),
            (None, 0, '    ; gfx id of each battle animation\'s TILES (45, by animation number):'),
            (None, 0, '    ; the frame after an animation starts ([$da80] = 1) this bank decodes'),
            (None, 0, '    ; the stream (WaitDMATransfer) to $8000 (128 tiles) and loads its OBJ'),
            (None, 0, '    ; palette (bank $17 entries 13 + 8, [$c81e] = number); [$da80] = 2.'),
            (None, 0, '    ; Bank $5F AnimGfxTableDebug is the Effect debugger\'s identical copy.'),
            (None, 0, '    ; Re-sectioned S112 (BATTLE_SKILL_SYSTEM §11).')]
    for c in range(BA.N_STOCK):
        segs.append((base + 2 * c, 2, f'    dw ${w(0x50, base + 2 * c):04x}   ; [${c:02x}] {users_text(c)}'))
    return segs, rb(0x50, base, 90)


ROUTINE_LABELS = {
    0: 'AnimRoutine_AtTarget', 1: 'AnimRoutine_Middle', 2: 'AnimRoutine_EachTarget',
    3: 'AnimRoutine_FlyAcross', 13: 'AnimRoutine_None'}


def routine_label(k):
    if k in ROUTINE_LABELS:
        return ROUTINE_LABELS[k]
    return f'AnimRoutine_Screen{k:02d}'


def rows_5f_tables():
    base, end = BA.CMD_FOE, 0x5B8F
    segs = [(None, 0, 'AnimCmdTableFoe:'),
            (None, 0, '    ; ANIMATION NUMBER per skill id when a PARTY monster acts on the ENEMY'),
            (None, 0, '    ; side (AnimSelectCmd, through GetPresentId in the patched build);'),
            (None, 0, '    ; $FF = no animation. 232 rows (ids $00-$E7; only < $DE are skills).'),
            (None, 0, '    ; Re-sectioned S112 (was mgbdis fake code; BATTLE_SKILL_SYSTEM §11).')]
    for i in range(BA.CMD_ROWS):
        v = b(0x5F, base + i)
        segs.append((base + i, 1, f'    db ${v:02x}   ; [{i:3d}] {NAMES.get(i, "")}'))
    b2 = BA.CMD_OWN
    segs += [(None, 0, 'AnimCmdTableOwn:'),
             (None, 0, '    ; ANIMATION NUMBER per skill id when an ENEMY acts on its OWN side'),
             (None, 0, '    ; (heals, buffs) — and for $1A/$1B/$29/$80/$AA/$D5 whoever acts'),
             (None, 0, '    ; (AnimSelectCmd); a target on the party side never gets sprites.')]
    for i in range(BA.CMD_ROWS):
        v = b(0x5F, b2 + i)
        segs.append((b2 + i, 1, f'    db ${v:02x}   ; [{i:3d}] {NAMES.get(i, "")}'))
    r = BA.ROUTINES
    segs += [(None, 0, 'AnimRoutineTable:'),
             (None, 0, '    ; the 16 per-skill presentation ROUTINES (AnimRunRoutine; index from'),
             (None, 0, '    ; the AnimRoutineIdx tables): 0-3 start the skill\'s animation with a'),
             (None, 0, '    ; MOTION, 4-12 / 14 / 15 run a SCREEN EFFECT (bank $5F entry 5 phase'),
             (None, 0, '    ; [$da83]) instead, 13 = nothing (MEASURED S112, PyBoy).')]
    for k in range(16):
        segs.append((r + 2 * k, 2, f'    dw {routine_label(k):<26}; [{k:2d}] {BA.ROUTINE_INFO[k][0]}'))
    for lab, t, what in (('AnimRoutineIdxParty', BA.RIDX_PARTY, 'a PARTY monster acts'),
                         ('AnimRoutineIdxEnemy', BA.RIDX_ENEMY, 'an ENEMY acts'),
                         ('AnimRoutineIdxLink', BA.RIDX_LINK,
                          'the link battle\'s second side (d9ee = 5)')):
        segs += [(None, 0, f'{lab}:'),
                 (None, 0, f'    ; ROUTINE index per skill id when {what} (230 rows; AnimSkillVisual).')]
        for i in range(BA.SKILL_ROWS):
            v = b(0x5F, t + i)
            segs.append((t + i, 1, f'    db ${v:02x}   ; [{i:3d}] {NAMES.get(i, "")}'))
    assert BA.RIDX_LINK + BA.SKILL_ROWS == end
    return segs, rb(0x5F, base, end - base)


def rows_5f_debug_gfx():
    base = BA.GFX_TABLE_DEBUG
    segs = [(None, 0, 'AnimGfxTableDebug:'),
            (None, 0, '    ; the Effect debugger\'s copy of AnimGfxTable (45 dw; game mode 5,'),
            (None, 0, '    ; EffectDebuggerFrame: A on row 0 plays animation [wOPTN_and_Item_selection]).')]
    for c in range(BA.N_STOCK):
        segs.append((base + 2 * c, 2, f'    dw ${w(0x5F, base + 2 * c):04x}   ; [${c:02x}] {users_text(c)}'))
    return segs, rb(0x5F, base, 90)


def rows_frame_table(bank):
    n = {0x5C: 14, 0x5D: 33, 0x5E: 45}[bank]
    base = BA.FRAME_BASE
    segs = [(None, 0, f'AnimFrameTable{bank:02X}:'),
            (None, 0, f'    ; ANIMATION -> its 32 frame pointers, index [$c7] = animation number'),
            (None, 0, f'    ; ($00-$0D bank $5C, $0E-$20 $5D, $21-$2C $5E — ROM0 AnimTickSelectAndDraw'),
            (None, 0, f'    ; picks the bank). Re-sectioned S112.')]
    for c in range(n):
        tab = w(bank, base + 2 * c)
        if BA.frame_bank(c) == bank:
            lab = f'Anim_{c:02x}_{anim_name(c)}'
            segs.append((base + 2 * c, 2, f'    dw {lab:<22}; [${c:02x}] {users_text(c)}'))
        else:
            segs.append((base + 2 * c, 2, f'    dw ${tab:04x}   ; [${c:02x}] (another bank\'s number: an unused default)'))
    return segs, rb(bank, base, 2 * n)


TARGET_X = {0x5C: 0x40EE, 0x5D: 0x4114, 0x5E: 0x412C}


def rows_target_x(bank):
    base = TARGET_X[bank]
    segs = [(None, 0, f'AnimTargetXTable{bank:02X}:'),
            (None, 0, '    ; X of the animation by [$db54] (AnimTargetSlot: 0 = off-screen left'),
            (None, 0, '    ; = the fly-in start, 1 = the middle, 2/3 = two foes, 4/5/6 = three'),
            (None, 0, '    ; foes); low byte read, the high byte unused. Used when [$dd68] != 0.')]
    for k in range(7):
        segs.append((base + 2 * k, 2, f'    dw ${w(bank, base + 2 * k):04x}   ; slot {k}'))
    return segs, rb(bank, base, 14)


def rows_anim_data(bank):
    ext = sorted(D['extents'][f'{bank:02X}'])
    lo, hi = ext[0][0], max(e for s, e in ext)
    items = {}
    for a in D['animations']:
        if a['frame_bank'] != bank:
            continue
        c = a['id']
        items[a['frame_table']] = ('table', c)
        for k, p in enumerate(a['frame_ptrs']):
            if p not in items:
                items[p] = ('frame', c, k)
    labels = {}
    for addr, it in items.items():
        if it[0] == 'table':
            labels[addr] = f'Anim_{it[1]:02x}_{anim_name(it[1])}'
        else:
            labels[addr] = f'Anim_{it[1]:02x}_F{it[2]:02d}' if it[2] != BA.BLANK_FRAME else f'Anim_{it[1]:02x}_Blank'
    segs = [(None, 0, f'; ' + '=' * 76),
            (None, 0, f'; BATTLE ANIMATION DATA (bank ${bank:02X}): per animation 32 dw frame pointers'),
            (None, 0, f'; (unused slots point at an empty frame; slot $1F = the blank) and the'),
            (None, 0, f'; frames: 4-byte sprites (dy, dx, tile, attr) — X = dx + [$c3] + 8,'),
            (None, 0, f'; Y = dy + [$c5] + 16, tile + [$c9], attr XOR [$ca] — $80 end; the builder'),
            (None, 0, f'; draws at most 40. MEASURED S112 (tools/census_battle_anims.py: all 45'),
            (None, 0, f'; animations, every frame == the shadow OAM). Re-sectioned S112.'),
            (None, 0, f'; ' + '=' * 76)]
    a = lo
    for addr in sorted(items):
        it = items[addr]
        if addr < a:
            # an EMPTY frame that is the previous frame's own $80 end (they share it)
            k = next(k for k, sg in enumerate(segs) if sg[0] == addr and sg[2] == '    db $80')
            assert it[0] == 'frame' and b(bank, addr) == 0x80
            segs.insert(k, (None, 0, f'{labels[addr]}:   ; ${addr:04x} empty frame = the $80 end above (shared)'))
            continue
        assert addr == a, (hex(bank), hex(addr), hex(a))
        if it[0] == 'table':
            c = it[1]
            segs.append((None, 0, f'{labels[addr]}:   ; ${addr:04x} animation ${c:02x} — {users_text(c)}'))
            for k in range(32):
                p = w(bank, addr + 2 * k)
                segs.append((addr + 2 * k, 2, f'    dw {labels[p]}'))
            a = addr + 64
        else:
            n = 0
            while b(bank, addr + 4 * n) != 0x80:
                n += 1
            segs.append((None, 0, f'{labels[addr]}:   ; ${addr:04x} {n} sprites'))
            for k in range(n):
                q = addr + 4 * k
                dy, dx, t, at = rb(bank, q, 4)
                sdy, sdx = dy - 256 if dy > 127 else dy, dx - 256 if dx > 127 else dx
                segs.append((q, 4, f'{dbrow(rb(bank, q, 4))}   ; dy {sdy:+d} dx {sdx:+d} tile {t} attr ${at:02x}'))
            segs.append((addr + 4 * n, 1, '    db $80'))
            a = addr + 4 * n + 1
    assert a == hi
    return segs, rb(bank, lo, hi - lo)


def rows_shade():
    base = BA.SHADE_TABLE
    segs = [(None, 0, 'AnimObjShadeTable:'),
            (None, 0, '    ; DMG OBP1 shade byte per battle animation (45; AnimStartRenderer writes'),
            (None, 0, '    ; it to wObj1Palette; on GBC the colours are AnimObjPalettes). S112.')]
    for c in range(BA.N_STOCK):
        segs.append((base + c, 1, f'    db ${b(0, base + c):02x}   ; [${c:02x}] {users_text(c)}'))
    return segs, rb(0, base, 45)


def rows_palettes():
    base = BA.PAL_TABLE
    segs = [(None, 0, 'AnimObjPalettes:'),
            (None, 0, '    ; OBJ palette 0 of each battle animation (45 x 4 RGB555): entry 13'),
            (None, 0, '    ; loads row [$c81e] into $C7D7 (slot 0), entry 8 commits. S112.')]
    for c in range(BA.N_STOCK):
        q = base + 8 * c
        ws = [w(0x17, q + 2 * k) for k in range(4)]
        segs.append((q, 8, '    dw ' + ', '.join(f'${x:04x}' for x in ws) + f'   ; [${c:02x}] {users_text(c)}'))
    return segs, rb(0x17, base, 360)


def rows_gfx_bank(bank, n_ptrs, stream_ids):
    base = 0x4001
    ptrs = [w(bank, base + 2 * i) for i in range(n_ptrs)]
    anim_of = {}
    for a in D['animations']:
        if a['gfx_id'] >> 8 == bank:
            anim_of[a['gfx_id'] & 0xFF] = a['id']
    lab = f'GfxPtrs{bank:02X}' if bank == 0x5B else 'AnimGfxPtrs5A'

    def slab(i):
        c = anim_of.get(i)
        return f'AnimGfx_{c:02x}_{anim_name(c)}' if c is not None else None
    segs = [(None, 0, f'{lab}:'),
            (None, 0, f'    ; gfx stream pointers ($<bank>:$4001 + 2 * index; gfx id = ${bank:02X}<<8 |'),
            (None, 0, f'    ; index; WaitDMATransfer). ' + ('All 32 are battle-animation tile sheets'
                                                            if bank == 0x5A else
                                                            'Indexes $0A-$16 = battle-animation tiles')
             + '. S112.')]
    for i, p in enumerate(ptrs):
        sl = slab(i)
        segs.append((base + 2 * i, 2, f'    dw {sl or f"${p:04x}":<24}; [${i:02x}]'
                     + (f' animation ${anim_of[i]:02x}' if i in anim_of else '')))
    return segs, ptrs, slab


def rows_gfx_streams(bank, ptrs, slab, ids):
    from dwm.sprite_codec import read_stream
    start = ptrs[ids[0]]
    segs = []
    q = start
    for i in ids:
        p = ptrs[i]
        assert p == q, (hex(bank), i, hex(p), hex(q))
        s = read_stream(R, bank * 0x4000 + p - 0x4000)
        c = None
        for a in D['animations']:
            if a['gfx_id'] == (bank << 8 | i):
                c = a['id']
        segs.append((None, 0, f'{slab(i)}:   ; ${p:04x} LZ stream ({len(s)} B -> 2,048 B = 128 tiles) — '
                     f'animation ${c:02x}, {users_text(c)}'))
        for k in range(0, len(s), 16):
            segs.append((p + k, min(16, len(s) - k), dbrow(s[k:k + 16])))
        q = p + len(s)
    return segs, rb(bank, start, q - start), start, q


# ---------------------------------------------------------------------------
# code labels and renames
# ---------------------------------------------------------------------------

def rename(old, new):
    files = [os.path.join(d, f) for d in (DIS, PAT) for f in os.listdir(d) if f.endswith('.asm')]
    pat = re.compile(r'\b%s\b' % re.escape(old))
    newpat = re.compile(r'^%s:' % re.escape(new), re.M)
    hit = 0
    for f in files:
        t = open(f).read()
        if newpat.search(t):
            print(f'  rename {old} -> {new}: already done ({os.path.basename(f)})')
            return
    for f in files:
        t = open(f).read()
        if pat.search(t):
            open(f, 'w').write(pat.sub(new, t))
            hit += 1
    print(f'  renamed {old} -> {new} in {hit} files')


def add_label(fname, addr, label, comment=None):
    """Insert `label:` before the line at `addr` — clean tree via the probe map;
    the patched copy at the same place, found by the clean lines just above it
    (a context grown until it is unique). Idempotent per tree."""
    path = os.path.join(DIS, fname)
    ins = ([f'; {comment}'] if comment else []) + [f'{label}:']
    lab_re = re.compile(r'^%s:' % re.escape(label), re.M)
    if not lab_re.search(open(path).read()):
        lines, addr_of = RS.probe_map(path)
        idx = [i for i, a in addr_of.items() if a == addr]
        if not idx:
            sys.exit(f'add_label {label}: no line at ${addr:04x} in {fname}')
        i = min(idx)
        while i > 0 and RS.LABEL_RE.match(lines[i - 1]):
            i -= 1                      # before the existing labels of that line
        open(path, 'w').write('\n'.join(lines[:i] + ins + lines[i:]) + '\n')
        RS.build()
        RS.clean_artifacts()
        print(f'  label {label} @ ${addr:04x} ({fname})')
    pp = os.path.join(PAT, fname)
    if not os.path.exists(pp) or lab_re.search(open(pp).read()):
        return
    cl = open(path).read().split('\n')
    j = next(k for k, l in enumerate(cl) if l.startswith(label + ':'))
    j0 = j - len(ins) + 1               # first inserted line in the clean tree
    pl = open(pp).read().split('\n')
    for n in range(4, 200):
        ctx = cl[max(0, j0 - n):j0]
        hits = [k for k in range(len(pl)) if pl[k:k + len(ctx)] == ctx]
        if len(hits) == 1:
            k = hits[0] + len(ctx)
            open(pp, 'w').write('\n'.join(pl[:k] + ins + pl[k:]))
            print(f'  label {label} -> patched {fname} (context {n})')
            return
        if not hits:
            break
    sys.exit(f'add_label {label}: no unique context in patched {fname}')


def main():
    RS.build()
    # --- routine labels first (the routine table names them) ---------------------------------------------------------
    rt = D['routines']
    for k in range(16):
        if k in (13,):
            continue
        add_label('bank_05f.asm', rt[k], routine_label(k),
                  f'AnimRoutineTable[{k}] — {BA.ROUTINE_INFO[k][0]} (S112)')
    add_label('bank_05f.asm', rt[13], routine_label(13),
              'AnimRoutineTable[13] — nothing (the bare ret; S112)')
    # --- data regions ----------------------------------------------------
    RS.splice('bank_002.asm', 0x02, 0x40E3, 194, rows_seq_top, 'SeqRowTable')
    end02 = max(e for s, e in D['extents']['02'])
    RS.splice('bank_002.asm', 0x02, 0x46A1, end02 - 0x46A1, rows_timelines, 'AnimTimelineTable')
    RS.splice('bank_050.asm', 0x50, BA.GFX_TABLE, 90, rows_gfx50, 'AnimGfxTable')
    RS.splice('bank_05f.asm', 0x5F, BA.CMD_FOE, 0x5B8F - BA.CMD_FOE, rows_5f_tables, 'AnimCmdTableFoe')
    RS.splice('bank_05f.asm', 0x5F, BA.GFX_TABLE_DEBUG, 90, rows_5f_debug_gfx, 'AnimGfxTableDebug')
    for bank in (0x5C, 0x5D, 0x5E):
        f = f'bank_{bank:03x}.asm'
        n = {0x5C: 14, 0x5D: 33, 0x5E: 45}[bank]
        ext = sorted(D['extents'][f'{bank:02X}'])
        lo, hi = ext[0][0], max(e for s, e in ext)
        RS.splice(f, bank, lo, hi - lo, lambda bank=bank: rows_anim_data(bank),
                  f'Anim_{[a["id"] for a in D["animations"] if a["frame_bank"] == bank][0]:02x}_'
                  f'{anim_name([a["id"] for a in D["animations"] if a["frame_bank"] == bank][0])}')
        RS.splice(f, bank, BA.FRAME_BASE, 2 * n, lambda bank=bank: rows_frame_table(bank),
                  f'AnimFrameTable{bank:02X}')
        RS.splice(f, bank, TARGET_X[bank], 14, lambda bank=bank: rows_target_x(bank),
                  f'AnimTargetXTable{bank:02X}')
    RS.splice('bank_000.asm', 0x00, BA.SHADE_TABLE, 45, rows_shade, 'AnimObjShadeTable')
    RS.splice('bank_017.asm', 0x17, BA.PAL_TABLE, 360, rows_palettes, 'AnimObjPalettes')
    # tile banks: the pointer table + the animation streams
    for bank, n_ptrs, ids in ((0x5A, 32, list(range(32))), (0x5B, 34, list(range(0x0A, 0x17)))):
        f = f'bank_{bank:03x}.asm'
        segs_p, ptrs, slab = rows_gfx_bank(bank, n_ptrs, ids)
        segs_s, data, lo, hi = rows_gfx_streams(bank, ptrs, slab, ids)
        RS.splice(f, bank, lo, hi - lo, lambda segs_s=segs_s, data=data: (segs_s, data), slab(ids[0]))
        RS.splice(f, bank, 0x4001, 2 * n_ptrs, lambda segs_p=segs_p, bank=bank, n_ptrs=n_ptrs:
                  (segs_p, rb(bank, 0x4001, 2 * n_ptrs)),
                  'AnimGfxPtrs5A' if bank == 0x5A else 'GfxPtrs5B')
    # --- code labels ---------------------------------------------------------
    add_label('bank_05f.asm', 0x55BB, 'AnimStartAnimation',
              'routines 0-3 end here: select the animation number, start its timeline + renderer, '
              '[$da80] = 1 (bank $50 loads tiles + palette next frame) — S112')
    add_label('bank_05f.asm', 0x52F0, 'AnimSkillVisual',
              'bank $5F entry 6: per skill-id range, WHEN (which action phase) the skill\'s routine '
              'runs; then the side\'s AnimRoutineIdx table -> AnimRunRoutine (S112)')
    add_label('bank_05f.asm', 0x5BB7, 'EffectDebuggerInit',
              'bank $5F entry 8 = game mode 5 init: the developers\' "Effect" animation debugger (S112)')
    add_label('bank_05f.asm', 0x5C8D, 'EffectDebuggerFrame',
              'bank $5F entry 9 = game mode 5 per frame: rows 0 animation (A plays it) / 1 / 2 / 3 '
              'screen effects; tools/census_battle_anims.py drives it (S112)')
    for bank, e1 in ((0x5C, 0x408D), (0x5D, 0x40B3), (0x5E, 0x40CB)):
        add_label(f'bank_{bank:03x}.asm', e1, f'AnimInit{bank:02X}',
                  f'bank ${bank:02X} entry 1: start an animation — X from AnimTargetXTable{bank:02X}[$db54] '
                  'when [$dd68] != 0 (else 0 = fly in from the left), Y $60, [$c7] = [$daa4], '
                  '[$c8] = its first frame (bank $02 entry 5) (S112)')
    # --- renames (mgbdis names on the animation code) ---------------------------
    for old, new in (('HramB5c_40fc', 'AnimBuildOAM5C'), ('HramB5d_4122', 'AnimBuildOAM5D'),
                     ('HramB5e_413a', 'AnimBuildOAM5E'),
                     ('DispatchEntry_5C_0', 'AnimTick5C'), ('DispatchEntry_5D_0', 'AnimTick5D'),
                     ('DispatchEntry_5E_0', 'AnimTick5E'),
                     ('LoadFldUI_5630', 'AnimSelectCmd'), ('CallFldUI_5696', 'AnimStartTimeline'),
                     ('LoadFldUI_56b9', 'AnimSelectCmdInit'), ('FuncFldUI_5441', 'AnimRunRoutine'),
                     ('LoadFldUI_544e', 'AnimTargetSlot'), ('LoadFldUI_5b8f', 'IsAttackerPartySide'),
                     ('LoadFldUI_5ba3', 'IsTargetPartySide'), ('LoadFldUI_4a60', 'HitReactionArm'),
                     ('ReadBattleStateDA80', 'AnimFrameTick'), ('CallBank5FEntry7', 'AnimTickSelectAndDraw'),
                     ('CallBank5FEntry7_3103', 'AnimStartRenderer'),
                     ('ReadDialogueState', 'ReadSeqStep'), ('ProcessDialogueStep', 'SeqApplyStep'),
                     ('AdvanceDialoguePtr', 'SeqTickHold'), ('label400d', 'SeqStepper')):
        rename(old, new)
    RS.build()
    RS.clean_artifacts()
    print('clean build byte-perfect')


if __name__ == '__main__':
    main()
