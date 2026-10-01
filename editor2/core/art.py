"""art.py — new ART for the ORIGINAL monsters as project data: `gamedata.art`
(ROADMAP P3.10 part 2a, S107; PROJECT_COMPILER §2.23; MONSTER_DATA "Monster
sprite graphics system" + "Follower / walking-sprite render system").

What the game reads for a monster's looks (all ROM-measured S107):
  * battle pose: ONE table, ROM0 MonsterBattleGfxTable ($2B9F, word per
    species = gfx-ID bank<<8|index). All 13 readers (battle, library, menus,
    breeding …) read it; no copy exists anywhere in the ROM.
  * battle colours: ONE table, $17 MonsterBattlePalettes ($62FD, 8 B per
    species [c0, c1 = cream $6BFF, c2, c3 = black]), one reader (bank $17
    entry 6). Rows 0-215 exist.
  * walking art: the follower gfx-ID table has EIGHT per-screen copies
    (banks $01 $06 $07 $09 $0B $12 $18 $59), identical for species 0-214
    (extract_gamedata --selftest). A new art stream = the same new gfx-ID in
    all eight.
  * walking layout + palette: bank $10 (species 0-127) / bank $11 (128-214)
    level-1 layout pointer + attr byte (low 3 bits = OBJ palette). A level-2
    pointer is dereferenced with ITS bank mapped, so a species can only use a
    layout of its own bank. New walking art is packed in "layout 0" order
    (tiles 0-3 down, 4-7 side a, 8-11 side b, 12-15 up — the sheet reader's
    packing, S106) and layout 0 exists in BOTH banks: Dragon's level-2 table
    $10:$4E33 and Armorpion's $11:$4184. So a re-art repoints the species'
    level-1 entry to its bank's layout 0 — no engine code.

Species 0-214 only. 215-220 (TERRY? and the four summon tiers) are NOT monsters
(PROJECT_STATE Iron Rule 8): never re-arted. 221-239 = custom.species.

Schema (sparse, like every gamedata section; keys = species ids as strings):

  "art": {
    "8": {"battle":   {"art": "assets/art/8_slime_battle.bin",      # LZ stream, 576 B decoded
                       "palette": ["$5C0F", "$6BFF", "$7EA0", "$0000"]},
          "follower": {"art": "assets/art/8_slime_follower.bin",    # LZ stream, 256 B decoded
                       "palette": 3},                               # OBJ palette 0-7
          "source":   {"sheet": "assets/sheets/x.png", "battle": box, "frames": {...}}}
  }

Every field is optional: a palette alone recolours the original art; an art
file alone keeps the original colours (battle) / OBJ palette (walking). The
`source` block (sheet + boxes, editor metadata for "Re-cut") is never read by
the compiler.

Where the streams go: overflow banks ART_BANKS ($7F, $7C, $7A — user S107:
"I probably WONT edit more than 50 monsters"; 50 fully re-arted monsters as
literal streams = ~42 KB, the three banks hold 49 KB). Each bank =
self-ID byte, pointer table at $4001, streams (dwm/sprite_bank.py layout);
placement is first-fit in species order, battle before walking, so a project
always builds the same bytes. An empty `art` writes the ORIGINAL ROM bytes into
every region and all-zero banks (test_compiler "no art -> vanilla bytes").
"""

import os

from . import formats as F
from . import walk_layouts as WL

ART_IDS = range(0, 215)                 # the original MONSTERS (Iron Rule 8)
PROTECTED = range(215, 221)
ART_BANKS = (0x7F, 0x7C, 0x7A)
BATTLE_DECODED = 576
FOLLOWER_DECODED = 256
CREAM, BLACK = 0x6BFF, 0x0000
LAYOUT0_L2 = {0x10: 0x4E33, 0x11: 0x4184}   # Dragon (28) / Armorpion (128): layout 0
BANK_SIZE = 0x4000

# The eight follower gfx-ID copies: (region, file, bank, label of species 0's row)
WALK_COPIES = [
    ('art_walk_01', 'patches/bank_001.asm', 0x01),
    ('art_walk_06', 'patches/bank_006.asm', 0x06),
    ('art_walk_07', 'patches/bank_007.asm', 0x07),
    ('art_walk_09', 'patches/bank_009.asm', 0x09),
    ('art_walk_0b', 'patches/bank_00b.asm', 0x0B),
    ('art_walk_12', 'patches/bank_012.asm', 0x12),
    ('art_walk_18', 'patches/bank_018.asm', 0x18),
    ('art_walk_59', 'patches/bank_059.asm', 0x59),
]

# Labels that live INSIDE a region: mgbdis put them there because bytes
# elsewhere (data decoded as code) branch / point to those addresses. They are
# not code, but the overlay must still define them at the same byte offset or
# it does not link (KEY_LESSONS S22 / S103). {region: {offset: [labels]}} —
# offsets from the region start, read from the clean build's game.sym S107
# (test_compiler re-checks them against the clean disassembly).
ANCHORS = {
    'art_battle_gfx': {0x1D: ['Data_2BBC'], 0x25: ['TilemapScrollCalc'],
                       0x2D: ['BitComplementAndBranch'], 0x3E: ['TilemapDrawRegion'],
                       0x4F: ['TilemapFillBorder01'], 0x5F: ['WriteTileBorderMid'],
                       0x6F: ['WriteTileBorderBot'], 0xC8: ['TileSequenceMid'],
                       0x105: ['TileSeqIncrementC'], 0x115: ['TileSeqIncrementD'],
                       0x14D: ['TileDataBlock2'], 0x154: ['TileDataContinue'],
                       0x15C: ['TilemapWriteByte'], 0x15D: ['TilemapWriteByte2'],
                       0x160: ['TilemapNextTile'], 0x164: ['TileNextInSeq'],
                       0x170: ['TileAddDE'], 0x196: ['TileStoreReverse'],
                       0x1A3: ['TileStoreReverseLoop']},
    # bank $0B: the table starts 32 bytes before the species rows
    'art_walk_0b': {a - 0x4994: [f'jr_00b_{a:04x}'] for a in (
        0x49bb, 0x49c1, 0x49c7, 0x49cd, 0x49d3, 0x49d9, 0x49df, 0x49e5, 0x49eb,
        0x49f1, 0x49f7, 0x49fd, 0x4a03, 0x4a09, 0x4a0f, 0x4a15, 0x4a1b, 0x4a21,
        0x4a27, 0x4a2d, 0x4a33, 0x4a39, 0x4a3f, 0x4a45, 0x4a4b, 0x4a4e, 0x4a54,
        0x4a57, 0x4a5a, 0x4a5d, 0x4a60, 0x4a63, 0x4a66, 0x4a69, 0x4a6c, 0x4a6f,
        0x4a72, 0x4a78, 0x4a7b, 0x4a7e, 0x4a84, 0x4a8a, 0x4aaf, 0x4abf, 0x4acf,
        0x4adf, 0x4aef, 0x4b40)},
    'art_attr_10': {0x72: ['jr_010_41f1']},
    'art_attr_11': {0x05: ['jr_011_4132'], 0x49: ['jr_011_4176']},
}


class ArtError(ValueError):
    pass


def l2_for(lid, bank, repo=None):
    """The level-1 entry for new walking art packed for layout `lid`: layout
    0 = the proven tables of 2a (Dragon $10:$4E33 / Armorpion $11:$4184 —
    layout 0 has 10 / 4 byte-variants per bank, differing only in the DMG
    palette bit $10), any other = its table in this bank, else the copy's
    label (walk_layouts.copies, the bank's free tail)."""
    if lid == WL.LAYOUT0:
        return LAYOUT0_L2[bank]
    return WL.l2_ref(lid, bank, repo)


def _repo():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def _vanilla(prj):
    from . import gamedata as G
    v = G.vanilla(getattr(prj, 'repo_root', None) or _repo())
    t = v['tables']

    def rows(n):
        return [bytes.fromhex(r) for r in t[n]['rows']]
    return {
        'battle_gfx': [r[0] | r[1] << 8 for r in rows('battle_gfx')],
        'battle_pal': rows('battle_palettes'),
        'walk_gfx': [r[0] | r[1] << 8 for r in rows('follower_gfx')],
        'layout': {0x10: [r[0] | r[1] << 8 for r in rows('follower_layout_10')],
                   0x11: [r[0] | r[1] << 8 for r in rows('follower_layout_11')]},
        'attr': {0x10: [r[0] for r in rows('follower_attr_10')],
                 0x11: [r[0] for r in rows('follower_attr_11')]},
    }


def follower_bank(sid):
    """(bank, level-1 index) of species sid's walking layout + attr rows."""
    return (0x10, sid) if sid < 0x80 else (0x11, sid - 0x80)


def _stream(prj, rel, what, decoded):
    if not isinstance(rel, str):
        raise ArtError(f"{what}: a path to an LZ stream file in the project")
    try:
        data = open(os.path.join(prj.root, rel), 'rb').read()
    except OSError:
        raise ArtError(f"{what}: cannot read {rel!r}")
    from dwm.sprite_codec import decode
    try:
        n = len(decode(data))
    except Exception as ex:                           # noqa: BLE001
        raise ArtError(f"{what}: {rel!r} does not decode ({ex})")
    if n != decoded:
        raise ArtError(f"{what}: {rel!r} decodes to {n} bytes; this art slot needs "
                       f"exactly {decoded} (S75: a short / long stream over- or "
                       "under-reads in some screen)")
    return data


def _palette(v, what):
    if not isinstance(v, list) or len(v) != 4:
        raise ArtError(f"{what}: 4 RGB555 colours [c0, c1 = $6BFF cream, c2, "
                       "c3 = $0000 black] (MONSTER_DATA 'battle palette')")
    out = b''
    for i, c in enumerate(v):
        try:
            x = F.val(c)
        except Exception:                             # noqa: BLE001
            x = None
        if not isinstance(x, int) or isinstance(c, bool) or not 0 <= x <= 0x7FFF:
            raise ArtError(f"{what}[{i}]: {c!r} is not an RGB555 colour ($0000-$7FFF)")
        out += bytes((x & 0xFF, x >> 8))
    return out


def entries(prj):
    """The raw `gamedata.art` dict (may be empty)."""
    gd = prj.data.get('gamedata') or {}
    sec = gd.get('art') or {}
    if not isinstance(sec, dict):
        raise ArtError("gamedata.art: must be an object keyed by species id")
    return sec


def resolve(prj, with_art=True):
    """Validate gamedata.art -> {sid: {'battle_art', 'battle_pal' (8 B),
    'follower_art', 'follower_pal' (0-7)}} (None = keep the original).
    Raises ArtError."""
    out = {}
    for k, e in sorted(entries(prj).items(), key=lambda t: str(t[0])):
        if str(k).startswith('_'):
            continue
        try:
            sid = F.val(k)
        except Exception:                             # noqa: BLE001
            sid = None
        what = f"gamedata.art.{k}"
        if not isinstance(sid, int):
            raise ArtError(f"{what}: the key must be a species id")
        if sid in PROTECTED:
            raise ArtError(f"{what}: species {sid} is TERRY? / a summon, not a monster "
                           "(PROJECT_STATE Iron Rule 8) — only its moves and stats can "
                           "change, never its art")
        if sid > 220:
            raise ArtError(f"{what}: species {sid} is a new species — its art lives in "
                           "custom.species")
        if sid not in ART_IDS:
            raise ArtError(f"{what}: species {sid} outside 0-214")
        if not isinstance(e, dict):
            raise ArtError(f"{what}: must be an object")
        bad = [x for x in e if x not in ('battle', 'follower', 'source', 'comment')
               and not str(x).startswith('_')]
        if bad:
            raise ArtError(f"{what}: unknown key(s) {bad} (battle, follower, source)")
        b = e.get('battle') or {}
        f = e.get('follower') or {}
        for name, d, keys in (('battle', b, ('art', 'palette')),
                              ('follower', f, ('art', 'palette', 'layout'))):
            if not isinstance(d, dict):
                raise ArtError(f"{what}.{name}: must be an object")
            bad = [x for x in d if x not in keys + ('comment',) and not str(x).startswith('_')]
            if bad:
                raise ArtError(f"{what}.{name}: unknown key(s) {bad} ({', '.join(keys)})")
        r = {'battle_art': None, 'battle_pal': None, 'follower_art': None,
             'follower_pal': None, 'layout': None, 'source': e.get('source')}
        if 'art' in b:
            r['battle_art'] = _stream(prj, b['art'], what + '.battle.art', BATTLE_DECODED) \
                if with_art else b['art']
        if 'palette' in b:
            r['battle_pal'] = _palette(b['palette'], what + '.battle.palette')
        if 'art' in f:
            r['follower_art'] = _stream(prj, f['art'], what + '.follower.art', FOLLOWER_DECODED) \
                if with_art else f['art']
        if 'palette' in f:
            p = f['palette']
            if isinstance(p, bool) or not isinstance(p, int) or not 0 <= p <= 7:
                raise ArtError(f"{what}.follower.palette: {p!r} — one of the 8 OBJ palettes 0-7")
            r['follower_pal'] = p
        if 'layout' in f:
            # S107 2b: the walking layout the new art is packed for
            if 'art' not in f:
                raise ArtError(f"{what}.follower.layout: a layout only goes with NEW "
                               "walking art (the original art is packed for the "
                               "monster's own layout)")
            try:
                WL.layout(f['layout'], getattr(prj, 'repo_root', None))
            except WL.LayoutError as ex:
                raise ArtError(f"{what}.follower.layout: {ex}")
            r['layout'] = f['layout']
        elif 'art' in f:
            r['layout'] = WL.LAYOUT0          # 2a projects: packed for layout 0
        out[sid] = r
    return out


# ---------------------------------------------------------------------------
# placement + effective tables
# ---------------------------------------------------------------------------

def place(prj):
    """-> (resolved, {sid: (battle gid | None, follower gid | None)},
    {bank: [(label, stream)]}). First fit over ART_BANKS in species order,
    battle before walking (deterministic)."""
    from dwm.sprite_bank import SpriteOverflowAllocator
    res = resolve(prj)
    alloc = SpriteOverflowAllocator(list(ART_BANKS))
    gids = {}
    for sid in sorted(res):
        r = res[sid]
        bg = fg = None
        try:
            if r['battle_art'] is not None:
                bg = alloc.add(r['battle_art'], f'ArtBattle_{sid}')
            if r['follower_art'] is not None:
                fg = alloc.add(r['follower_art'], f'ArtWalk_{sid}')
        except RuntimeError:
            used = sum(len(x['battle_art'] or b'') + len(x['follower_art'] or b'')
                       for x in res.values())
            raise ArtError(f"gamedata.art: the art streams ({used} bytes) do not fit the "
                           f"{len(ART_BANKS)} art banks (${', $'.join(f'{b:02X}' for b in ART_BANKS)}"
                           f", {capacity()} bytes) — fewer re-arted monsters, or a "
                           "compressed re-encode (dwm/sprite_codec.encode)")
        gids[sid] = (bg, fg)
    banks = {b: list(alloc.placed[b]) for b in ART_BANKS}
    return res, gids, banks


def capacity():
    """Stream bytes the art banks hold (each: 1 self-ID byte; every stream
    also costs a 2-byte pointer)."""
    return len(ART_BANKS) * (BANK_SIZE - 1)


def usage(prj):
    """(bytes used incl. pointers, capacity) for the editor's meter."""
    res = resolve(prj)
    used = 0
    for r in res.values():
        for k in ('battle_art', 'follower_art'):
            if r[k] is not None:
                used += len(r[k]) + 2
    return used, capacity()


def tables(prj):
    """The effective art tables (lists over the vanilla rows)."""
    v = _vanilla(prj)
    res, gids, banks = place(prj)
    bg = list(v['battle_gfx'])
    bp = [bytes(x) for x in v['battle_pal']]
    wg = list(v['walk_gfx'])
    lay = {b: list(x) for b, x in v['layout'].items()}
    att = {b: list(x) for b, x in v['attr'].items()}
    for sid, r in res.items():
        g_b, g_f = gids[sid]
        if g_b is not None:
            bg[sid] = g_b
        if r['battle_pal'] is not None:
            bp[sid] = r['battle_pal']
        bank, i = follower_bank(sid)
        if g_f is not None:
            wg[sid] = g_f
            lay[bank][i] = l2_for(r['layout'], bank, getattr(prj, 'repo_root', None))
            # imported art is drawn upright: no flips; palette = the chosen one
            # (else the species' original palette)
            att[bank][i] = r['follower_pal'] if r['follower_pal'] is not None \
                else att[bank][i] & 7
        elif r['follower_pal'] is not None:
            att[bank][i] = (att[bank][i] & 0xF8) | r['follower_pal']
    return {'battle_gfx': bg, 'battle_pal': bp, 'walk_gfx': wg, 'layout': lay,
            'attr': att, 'banks': banks, 'resolved': res, 'gids': gids}


# ---------------------------------------------------------------------------
# emitters (one per @BUILD_PROJECT region; names art_*)
# ---------------------------------------------------------------------------

def _names(prj):
    from . import gamedata as G
    return G.monster_names(getattr(prj, 'repo_root', None) or _repo())


def rows_text(rows, anchors=None):
    """rows = [(bytes, comment)] -> asm text. A row of 2 bytes is a `dw`, any
    other a `db`; a row an anchor falls into is split into db pieces with the
    label between them."""
    anchors = anchors or {}
    out, off = [], 0
    for data, comment in rows:
        if isinstance(data, str):         # S107 2b: a label (a layout copy) = one dw
            if any(off <= a < off + 2 for a in anchors):
                raise ArtError(f"rows_text: an anchor falls inside the dw {data}")
            out.append(f"    dw {data}   ; {comment}" if comment else f"    dw {data}")
            off += 2
            continue
        cuts = sorted(a - off for a in anchors if off <= a < off + len(data))
        pos = 0
        pieces = []
        for c in cuts:
            if c > pos:
                pieces.append((data[pos:c], None))
            pieces.append((None, anchors[off + c]))
            pos = c
        pieces.append((data[pos:], None))
        whole = len(cuts) == 0
        first = True
        for bs, labels in pieces:
            if labels is not None:
                for lb in labels:
                    out.append(f"{lb}:   ; kept at its byte offset (bytes elsewhere decoded "
                               "as code point here; NOT code)")
                continue
            if not bs:
                continue
            if whole and len(bs) == 2:
                body = f"    dw ${bs[0] | bs[1] << 8:04X}"
            else:
                body = "    db " + ", ".join(f"${x:02X}" for x in bs)
            note = comment if first else (comment and f"{comment} (cont.)")
            out.append(f"{body}   ; {note}" if note else body)
            first = False
        off += len(data)
    return "\n".join(out) + "\n"


def _w(x):
    """A word as 2 bytes; a label (str) stays a label (rows_text emits dw)."""
    if isinstance(x, str):
        return x
    return bytes((x & 0xFF, x >> 8))


def emit_battle_gfx(prj, warnings):
    t, nm = tables(prj), _names(prj)
    rows = []
    for sid in ART_IDS:
        tag = ' (gamedata.art)' if t['gids'].get(sid, (None,))[0] is not None else ''
        rows.append((_w(t['battle_gfx'][sid]), f"[{sid}] {nm.get(sid, '')}{tag}"))
    return rows_text(rows, ANCHORS['art_battle_gfx'])


def emit_battle_pal(prj, warnings):
    t, nm = tables(prj), _names(prj)
    rows = []
    for sid in ART_IDS:
        r = t['resolved'].get(sid)
        tag = ' (gamedata.art)' if r and r['battle_pal'] is not None else ''
        rows.append((t['battle_pal'][sid], f"[{sid}] {nm.get(sid, '')}{tag}"))
    return rows_text(rows)


def _emit_walk(region):
    def emit(prj, warnings):
        t, nm = tables(prj), _names(prj)
        rows = []
        for sid in ART_IDS:
            tag = ' (gamedata.art)' if t['gids'].get(sid, (None, None))[1] is not None else ''
            rows.append((_w(t['walk_gfx'][sid]), f"[{sid}] {nm.get(sid, '')}{tag}"))
        return rows_text(rows, ANCHORS.get(region))
    emit.__name__ = f"emit_{region}"
    return emit


def _emit_layout(bank):
    def emit(prj, warnings):
        t, nm = tables(prj), _names(prj)
        first = 0 if bank == 0x10 else 0x80
        rows = []
        for i, w in enumerate(t['layout'][bank]):
            sid = first + i
            r = t['resolved'].get(sid)
            tag = (f" (gamedata.art: layout {r['layout']})"
                   if t['gids'].get(sid, (None, None))[1] is not None else '')
            rows.append((_w(w), f"[{sid}] {nm.get(sid, '')}{tag}"))
        return rows_text(rows, ANCHORS.get(f'art_layout_{bank:02x}'))
    emit.__name__ = f"emit_layout_{bank:02x}"
    return emit


def _emit_attr(bank):
    def emit(prj, warnings):
        t, nm = tables(prj), _names(prj)
        first = 0 if bank == 0x10 else 0x80
        rows = []
        for i, a in enumerate(t['attr'][bank]):
            sid = first + i
            r = t['resolved'].get(sid)
            tag = ' (gamedata.art)' if r and (r['follower_pal'] is not None or
                                             r['follower_art'] is not None) else ''
            rows.append((bytes((a,)), f"[{sid}] {nm.get(sid, '')}: OBJ palette {a & 7}{tag}"))
        return rows_text(rows, ANCHORS.get(f'art_attr_{bank:02x}'))
    emit.__name__ = f"emit_attr_{bank:02x}"
    return emit


def _emit_bank(bank):
    def emit(prj, warnings):
        t = tables(prj)
        entries_ = t['banks'][bank]
        head = [f"; ART BANK ${bank:02X} — new art for ORIGINAL monsters (gamedata.art; generated",
                f"; by editor2 `art{bank:02x}`, S107 P3.10 part 2a — PROJECT_COMPILER §2.23).",
                "; Self-ID byte, pointer table at $4001 (the resolver reads",
                "; $<bank>:$4001 + index*2), the LZ streams. A re-arted species' gfx-ID",
                "; (bank<<8 | index) is written into ROM0 MonsterBattleGfxTable (battle) /",
                "; the eight follower gfx-ID tables (walking). No art = an all-zero bank,",
                "; exactly like the original ROM.", "",
                f'SECTION "Art Bank ${bank:02X}", ROMX[$4000], BANK[${bank:02X}]']
        if not entries_:
            return "\n".join(head + ["    ds $4000, $00", ""])
        out = head + [f"    db ${bank:02X}                          ; bank self-ID at $4000",
                      "", f"ArtPtrs_{bank:02X}:                  ; pointer table @ $4001"]
        for i, (label, _s) in enumerate(entries_):
            out.append(f"    dw {label:<20} ; index {i} (gfx-ID ${bank:02X}{i:02X})")
        out.append("")
        used = 1 + 2 * len(entries_)
        for label, s in entries_:
            out.append(f"{label}:   ; {len(s)} B")
            for o in range(0, len(s), 16):
                out.append("    db " + ", ".join(f"${x:02x}" for x in s[o:o + 16]))
            used += len(s)
        out += ["", f"    ds $8000 - @, $00   ; zero pad (used {used} of {BANK_SIZE})", ""]
        return "\n".join(out)
    emit.__name__ = f"emit_bank_{bank:02x}"
    return emit


REGIONS = ([('art_battle_gfx', 'patches/bank_000.asm', emit_battle_gfx, 0x00),
            ('art_battle_pal', 'patches/bank_017.asm', emit_battle_pal, 0x17)]
           + [(name, path, _emit_walk(name), bank) for name, path, bank in WALK_COPIES]
           + [('art_layout_10', 'patches/bank_010.asm', _emit_layout(0x10), 0x10),
              ('art_attr_10', 'patches/bank_010.asm', _emit_attr(0x10), 0x10),
              ('art_layout_11', 'patches/bank_011.asm', _emit_layout(0x11), 0x11),
              ('art_attr_11', 'patches/bank_011.asm', _emit_attr(0x11), 0x11)])
FILES = [(f'art{b:02x}', f'patches/bank_0{b:02x}.asm', _emit_bank(b), b) for b in ART_BANKS]
