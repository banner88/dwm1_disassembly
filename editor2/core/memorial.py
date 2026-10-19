"""memorial.py — S154: THE MEMORIAL (statues of the monsters that won and have left).

A room may hold MEMORIAL STATUES. Each statue shows one monster that was in the party
when the player WON a boss battle, an arena class or Starry Night's final, and that
is no longer with the player (bred away, released, traded). Every statue of a room
shows a DIFFERENT monster, picked at random each time the player comes into the room;
statues with no monster left to show keep their own (empty-statue) picture. Examining
a statue says its words: "In memory of {fallen}, a level {fallen_level}
{fallen_species}." — or, empty, the empty words.

Owning docs: PROJECT_COMPILER §2.62 (schema + lowering), DATA_STRUCTURES "The
memorial (S154)" (the engine, the list, the tag), help 77_memorial.md.

Schema
------
  custom.memorial = {"cap": 120,               # monsters remembered (8-120; the
                                               #   oldest is forgotten when full)
                     "text": "<dialogue id>",  # the default statue words
                     "empty": "<dialogue id>"} # the default empty-statue words
     (optional; without "text" / "empty" the compiler uses DEFAULT_TEXT /
     DEFAULT_EMPTY — two dialogue entries it adds)
  custom.rooms[].statues = [{"id": "statue_1", "tiles": [tl, tr, bl, br],
                             "shades": [i1, i2, i3]?, "pedestal": [tl, tr, bl, br]?,
                             "palette": slot?,
                             "text": "<dialogue id>"?, "empty": "<dialogue id>"?}]
     the room's statues in FILL ORDER (statue 0 gets a monster first); tiles = 4 of
     the room sheet's own tile ids ($00-$7F): the MONSTER CELL — its background (the
     editor copies the floor / wall that was there), over which the game draws the
     monster (its colour-0 pixels let the background show: "transparent");
     shades (S154 r2) = the palette index the monster's colours 1 / 2 / 3 are drawn
     in (default [1, 2, 3]; the editor maps the middle shade onto an index the
     background does not use, which its statue palette holds grey); pedestal /
     palette = the editor's own record (the pedestal metatile's 4 tiles — ordinary,
     editable tiles — and the palette slot of both cells); the compiler reads
     neither
  a screen state's npcs[] entry {"kind": "statue", "x", "y", "statue": "statue_1"}
     = that statue's PEDESTAL stands on cell (x, y) in this state (an examine spot,
     any facing) and its monster cell on (x, y - 1) above it (S154 r2, the user: "The
     whole thing then takes up 2 tiles. Then monster sits on top")

Lowering (Project.__init__, before the talks): each statue gets a script
`_mem_<room>_<statue>` in its room's table — a talk with one `memorial` step
(story command 7: the monster into the inserts, $D8E1 = found) — and each
statue entry becomes an examine spot running it.

Engine (templates/bank_079_head.asm entries 6-9, memorial_pics.asm, bank $73
MemorialCommit / MemorialRestore): regions memorial_battle_start /
memorial_battle_end (bank $50) and memorial_tiles_0 / _1 (bank $0B) — vanilla
bytes in a project without statues.
"""

from . import formats as F

STATUES_MAX = 8            # bank $79 MEM_STATUES (wMemPicks)
CAP_DEFAULT = 120
CAP_MIN, CAP_MAX = 8, 120  # wMemGone holds 128 bits
RING_SLACK = 9             # MEM_RING = MEM_CAP + 9: nine entries after a save never
                           # overwrite the saved window (KEY_LESSONS S154)
TAG_STEP = 8               # a tag is a multiple of 8 (8 … 248): see DATA_STRUCTURES
SPECIES_IDS = 240          # the picture bank: one 64-byte picture per species id
PIC_BYTES = 64
# Bosses the game fights with a PLAIN battle op ($DA09 = 1, so not "a boss battle"):
# extracted/arena_brackets.json gate_boss_triggers (S154 research): Digster at the
# Arena's left door, the Durran chain's Terry and Durran (the post-game rematch with
# Terry uses the same row). Every other boss is op $5A / $5B ($DA09 = 3).
BOSS_EIDS = ((127, 'Digster'), (199, 'Durran'), (343, 'Terry'))

DEFAULT_TEXT_ID = 'memorial_default_text'
DEFAULT_EMPTY_ID = 'memorial_default_empty'
DEFAULT_TEXT = [['In memory of', '{fallen},'], ['a level {fallen_level}', '{fallen_species}.']]
DEFAULT_EMPTY = [['A blank statue,', 'quiet and cold.']]
SCRIPT_PREFIX = '_mem_'

REGION_NAMES = ('memorial_battle_start', 'memorial_battle_end',
                'memorial_tiles_0', 'memorial_tiles_1')


class MemorialError(ValueError):
    pass


# ---------------------------------------------------------------------------
# the schema
# ---------------------------------------------------------------------------

def room_statues(room):
    v = room.get('statues') or []
    return v if isinstance(v, list) else []


def active(custom):
    """Does the project have any memorial statue?"""
    return any(room_statues(r) for r in (custom.get('rooms') or [])
               if isinstance(r, dict))


def settings(custom):
    """custom.memorial validated -> {'cap', 'text', 'empty'} (dialogue ids or None)."""
    m = custom.get('memorial') or {}
    if not isinstance(m, dict):
        raise MemorialError('custom.memorial: must be an object {cap, text, empty}')
    bad = [k for k in m if k not in ('cap', 'text', 'empty', 'comment')
           and not str(k).startswith('_')]
    if bad:
        raise MemorialError(f'custom.memorial: unknown key(s) {bad} (cap, text, empty)')
    cap = m.get('cap', CAP_DEFAULT)
    if isinstance(cap, bool) or not isinstance(cap, int) or not CAP_MIN <= cap <= CAP_MAX:
        raise MemorialError(f'custom.memorial.cap: {cap!r} — how many monsters the memorial '
                            f'remembers, {CAP_MIN}-{CAP_MAX}')
    for k in ('text', 'empty'):
        if m.get(k) is not None and not isinstance(m[k], str):
            raise MemorialError(f'custom.memorial.{k}: a dialogue id')
    return {'cap': cap, 'text': m.get('text'), 'empty': m.get('empty')}


def _room_name(r):
    return f"room {r.get('name') or r.get('id')!r}"


def check_room(r, anim_slots=()):
    """A room's statues -> [statue dict] (validated; raises MemorialError)."""
    sts = r.get('statues')
    if sts is None:
        return []
    what = f"{_room_name(r)} statues"
    if not isinstance(sts, list):
        raise MemorialError(f'{what}: a list')
    if len(sts) > STATUES_MAX:
        raise MemorialError(f'{what}: {len(sts)} statues — a room holds at most {STATUES_MAX}')
    seen_ids, seen_tiles = set(), {}
    for k, s in enumerate(sts):
        w = f'{what}[{k}]'
        if not isinstance(s, dict):
            raise MemorialError(f'{w}: an object {{id, tiles}}')
        bad = [x for x in s if x not in ('id', 'tiles', 'text', 'empty', 'name', 'comment',
                                         'shades', 'pedestal', 'palette')
               and not str(x).startswith('_')]
        if bad:
            raise MemorialError(f'{w}: unknown key(s) {bad} (id, tiles, shades, pedestal, '
                                'palette, text, empty, name)')
        sid = s.get('id')
        if not isinstance(sid, str) or not sid:
            raise MemorialError(f'{w}.id: a name')
        if sid in seen_ids:
            raise MemorialError(f'{w}.id: {sid!r} twice in the room')
        seen_ids.add(sid)
        t = s.get('tiles')
        if not isinstance(t, list) or len(t) != 4:
            raise MemorialError(f"{w} '{sid}'.tiles: 4 tile ids (top-left, top-right, "
                                "bottom-left, bottom-right)")
        for j, v in enumerate(t):
            try:
                n = F.val(v)
            except (TypeError, ValueError):
                raise MemorialError(f"{w} '{sid}'.tiles[{j}]: {v!r} is not a tile id")
            if not 0 <= n <= 0x7F:
                raise MemorialError(f"{w} '{sid}'.tiles[{j}]: ${n:02X} — a statue uses the "
                                    "room's OWN tiles $00-$7F")
            if n in seen_tiles:
                raise MemorialError(f"{w} '{sid}': tile ${n:02X} is also "
                                    f"{seen_tiles[n]!r}'s — each statue needs 4 tiles of "
                                    "its own (they get a different monster)")
            if n in anim_slots:
                raise MemorialError(f"{w} '{sid}': tile ${n:02X} is animated in this room — "
                                    "a statue's tiles must not move")
            seen_tiles[n] = sid
        for k2 in ('text', 'empty'):
            if s.get(k2) is not None and not isinstance(s[k2], str):
                raise MemorialError(f"{w} '{sid}'.{k2}: a dialogue id")
        sh = s.get('shades')
        if sh is not None and (not isinstance(sh, list) or len(sh) != 3 or any(
                isinstance(v, bool) or not isinstance(v, int) or not 0 <= v <= 3 for v in sh)):
            raise MemorialError(f"{w} '{sid}'.shades: {sh!r} — 3 palette indices 0-3 (the "
                                "monster's colours 1 / 2 / 3)")
        pd = s.get('pedestal')
        if pd is not None:
            try:
                ok = isinstance(pd, list) and len(pd) == 4 and all(
                    0 <= F.val(v) <= 0xFF for v in pd)
            except (TypeError, ValueError):
                ok = False
            if not ok:
                raise MemorialError(f"{w} '{sid}'.pedestal: 4 tile ids")
        pl = s.get('palette')
        if pl is not None and (isinstance(pl, bool) or not isinstance(pl, int)
                               or not 0 <= pl <= 7):
            raise MemorialError(f"{w} '{sid}'.palette: a palette slot 0-7")
    return sts


def statue_tiles(s):
    return [F.val(v) for v in s['tiles']]


SHADES_DEFAULT = (1, 2, 3)


def statue_shades(s):
    """The palette index of the monster's colours 1 / 2 / 3 on this statue."""
    sh = s.get('shades')
    return tuple(sh) if isinstance(sh, list) and len(sh) == 3 else SHADES_DEFAULT


def shade_map(shades):
    """(i1, i2, i3) -> the engine's shade map byte (2 bits each, colour 1 lowest)."""
    return (shades[0] & 3) | ((shades[1] & 3) << 2) | ((shades[2] & 3) << 4)


def composite(bg16, pic16, shades=SHADES_DEFAULT):
    """The engine's MemPicDraw as a model: 16 rows x 16 colour indices of the statue's
    background + the monster's picture (0 = see-through) -> what VRAM holds."""
    return [[(shades[p - 1] if p else b) for b, p in zip(br, pr)]
            for br, pr in zip(bg16, pic16)]


# ---------------------------------------------------------------------------
# lowering (Project.__init__)
# ---------------------------------------------------------------------------

def script_id(room, statue):
    return f"{SCRIPT_PREFIX}{room.get('id')}_{statue.get('id')}"


def _ensure_dialogue(custom, did, boxes, comment):
    dl = custom.setdefault('dialogue', [])
    if not any(isinstance(d, dict) and d.get('id') == did for d in dl):
        dl.append({'id': did, 'boxes': [list(b) for b in boxes], 'comment': comment})


def lower(prj):
    """The statues -> scripts + examine spots (mutates prj.custom like the other
    lowerings). Raises MemorialError."""
    custom = prj.custom
    if not active(custom):
        # a stray statue entry without a statue list is still an error
        for r in custom.get('rooms') or []:
            for _k, scr in (r.get('screens') or {}).items():
                for st in _states(scr):
                    for n in st.get('npcs') or []:
                        if isinstance(n, dict) and n.get('kind') == 'statue':
                            raise MemorialError(f"{_room_name(r)}: a statue on ({n.get('x')}, "
                                                f"{n.get('y')}) but the room has no statues")
        return
    cfg = settings(custom)
    text = cfg['text'] or DEFAULT_TEXT_ID
    empty = cfg['empty'] or DEFAULT_EMPTY_ID
    if cfg['text'] is None:
        _ensure_dialogue(custom, DEFAULT_TEXT_ID, DEFAULT_TEXT,
                         'S154: the memorial statues\' words (memorial.py default)')
    if cfg['empty'] is None:
        _ensure_dialogue(custom, DEFAULT_EMPTY_ID, DEFAULT_EMPTY,
                         'S154: an empty memorial statue\'s words (memorial.py default)')
    scripts = custom.setdefault('scripts', [])
    have = {s.get('id') for s in scripts}
    for r in custom.get('rooms') or []:
        sts = check_room(r)
        if not sts:
            for _k, scr in (r.get('screens') or {}).items():
                for st in _states(scr):
                    for n in st.get('npcs') or []:
                        if isinstance(n, dict) and n.get('kind') == 'statue':
                            raise MemorialError(f"{_room_name(r)}: a statue on ({n.get('x')}, "
                                                f"{n.get('y')}) but the room has no statues")
            continue
        if r.get('mapID') is None:
            raise MemorialError(f'{_room_name(r)}: statues only stand in the project\'s rooms')
        index = {s['id']: k for k, s in enumerate(sts)}
        table = r.setdefault('scripts', {})
        sid_of = {}
        for k, s in enumerate(sts):
            sid = script_id(r, s)
            sid_of[s['id']] = sid
            if sid not in have:
                scripts.append({'id': sid, 'talk': {'steps': [{'memorial': {
                    'statue': k,
                    'found': [{'say': s.get('text') or text}],
                    'empty': [{'say': s.get('empty') or empty}]}}]},
                    'comment': f"S154: memorial statue '{s['id']}' (memorial.py)"})
                have.add(sid)
            if sid not in table.values():
                if '0' not in table:
                    eid = f"{SCRIPT_PREFIX}{r.get('id')}_entry"
                    if eid not in have:
                        scripts.append({'id': eid, 'ops': [['end']]})
                        have.add(eid)
                    table['0'] = eid
                i = 1
                while str(i) in table:
                    i += 1
                table[str(i)] = sid
        for _k, scr in (r.get('screens') or {}).items():
            for st in _states(scr):
                for n in st.get('npcs') or []:
                    if not isinstance(n, dict) or n.get('kind') != 'statue':
                        continue
                    which = n.get('statue')
                    if which not in index:
                        raise MemorialError(f"{_room_name(r)}: the statue on ({n.get('x')}, "
                                            f"{n.get('y')}) names {which!r} — not one of the "
                                            f"room's statues {sorted(index)}")
                    n['kind'] = 'examine'
                    n['script'] = sid_of[which]
                    n['facing'] = n.get('facing', 'any')
                    n['_statue'] = which


def _states(scr):
    """A screen's states as the compiler reads them (Project.screen_states)."""
    sts = scr.get('states')
    if isinstance(sts, list) and sts:
        return sts
    return [scr]


# ---------------------------------------------------------------------------
# the pictures (compile time: every species' standing frame, 64 bytes)
# ---------------------------------------------------------------------------

def _grids(tiles256):
    from .sprite_render import tiles_to_grid
    return [tiles_to_grid(tiles256[i * 16:(i + 1) * 16], 1, 1) for i in range(16)]


def frame_pixels(tiles256, lid, repo=None):
    """The walking frame "down A" as the game draws it -> 16 rows of 16 colour
    indices (0 = nothing), fitted into the statue's 16 x 16: the layout's own
    16 x 16 box when the frame lies inside it (194 of the 215 monsters), else
    moved — centred across, standing on the bottom row (none is cut)."""
    from . import walk_layouts as WL
    d = WL.render(_grids(tiles256), lid, repo)[0]
    out = [[0] * 16 for _ in range(16)]
    if not d:
        return out
    ys = [k[0] for k in d]
    xs = [k[1] for k in d]
    y0, y1, x0, x1 = min(ys), max(ys), min(xs), max(xs)
    bx, by = WL.BOX
    if x0 >= bx and x1 < bx + 16 and y0 >= by and y1 < by + 16:
        ox, oy = bx, by
    else:
        w = x1 - x0 + 1
        ox = x0 - (16 - w) // 2 if w <= 16 else x0 + (w - 16) // 2
        oy = y1 - 15
    for (cy, cx), v in d.items():
        y, x = cy - oy, cx - ox
        if 0 <= x < 16 and 0 <= y < 16:
            out[y][x] = v
    return out


def picture_bytes(pix):
    """16 x 16 colour indices -> 64 bytes: tiles TL, TR, BL, BR (2bpp)."""
    out = bytearray()
    for ty, tx in ((0, 0), (0, 1), (1, 0), (1, 1)):
        for r in range(8):
            lo = hi = 0
            for c in range(8):
                v = pix[ty * 8 + r][tx * 8 + c]
                lo = (lo << 1) | (v & 1)
                hi = (hi << 1) | ((v >> 1) & 1)
            out += bytes((lo, hi))
    return bytes(out)


def species_art(prj):
    """{species: (16 walking tiles 256 B, layout id)} for every monster of the
    build: the original art (or gamedata.art's new art, its layout), the
    project's new species (custom.species)."""
    from dwm.sprite_codec import decode
    from .sprite_render import _load, species_layout_id
    from . import art as AR
    from . import species as SP
    from . import walk_layouts as WL
    ms = _load('monster_sprites.json') or {}
    out = {}
    for sid in range(215):
        m = (ms.get('monsters') or {}).get(str(sid))
        lid, _attr = species_layout_id(sid)
        if m is None or lid is None:
            continue
        out[sid] = (bytes.fromhex(m['follower']['tile_bytes_hex']), lid)
    try:
        arts = AR.resolve(prj)
    except Exception:                                  # noqa: BLE001 — reported elsewhere
        arts = {}
    for sid, a in arts.items():
        if a.get('follower_art'):
            out[sid] = (decode(a['follower_art']), a.get('layout') or WL.LAYOUT0)
    try:
        news = SP.resolve(prj)
    except Exception:                                  # noqa: BLE001 — reported elsewhere
        news = []
    for s in news:
        if s.get('follower_art'):
            out[s['id']] = (decode(s['follower_art']), s['layout'])
    return out


def pictures(prj):
    """The picture bank's MemPics: SPECIES_IDS x 64 bytes."""
    got = getattr(prj, '_mem_pics', None)
    if got is not None:
        return got
    repo = getattr(prj, 'repo_root', None)
    arts = species_art(prj)
    blob = bytearray(SPECIES_IDS * PIC_BYTES)
    for sid, (tiles, lid) in arts.items():
        if 0 <= sid < SPECIES_IDS and len(tiles) == 256:
            blob[sid * PIC_BYTES:(sid + 1) * PIC_BYTES] = picture_bytes(
                frame_pixels(tiles, lid, repo))
    prj._mem_pics = bytes(blob)
    return prj._mem_pics


# ---------------------------------------------------------------------------
# the picture bank (an ext bank $80+, after the text banks)
# ---------------------------------------------------------------------------

def plan(prj):
    """-> the picture bank, or 0 (no statues). Cached; stream_plan drops it."""
    got = getattr(prj, '_mem_plan', None)
    if got is not None:
        return got
    if not active(prj.custom):
        prj._mem_plan = 0
        return 0
    from . import gametext as GT
    try:
        GT.plan(prj)                    # the text banks number first
    except GT.GameTextError:
        pass
    prj._mem_plan = prj._take_ext_bank('memorial pictures')
    return prj._mem_plan


def bank_file(bank):
    return f"bank_{bank:03x}.asm"


def bank_files(prj):
    b = plan(prj)
    return {b: bank_file(b)} if b else {}


def emit_pic_bank(prj, bank):
    from .emitters import template
    pics = pictures(prj)
    out = [f'SECTION "ROM Bank ${bank:03X}", ROMX[$4000], BANK[${bank:02X}]',
           f'    db ${bank:02X}                          ; bank self-ID at $4000',
           template('memorial_pics.asm').rstrip('\n')]
    from . import gamedata as G
    from .project import REPO_ROOT
    names = G.monster_names(getattr(prj, 'repo_root', None) or REPO_ROOT)
    for sid in range(SPECIES_IDS):
        chunk = pics[sid * PIC_BYTES:(sid + 1) * PIC_BYTES]
        name = names.get(sid, '') if isinstance(names, dict) else ''
        out.append(f'; species {sid}' + (f' {name}' if name else '')
                   + ('' if any(chunk) else ' (no picture)'))
        for i in range(0, PIC_BYTES, 16):
            out.append('    db ' + ', '.join(f'${b:02X}' for b in chunk[i:i + 16]))
    return '\n'.join(out) + '\n'


def emit_pic_banks(prj, warnings):
    """{target: text} for the multi emitter (none without statues)."""
    b = plan(prj)
    if not b:
        return {}
    return {f'file:patches/{bank_file(b)}': emit_pic_bank(prj, b)}


# ---------------------------------------------------------------------------
# bank $79 data, bank $77 stub, the regions
# ---------------------------------------------------------------------------

def room_rows(prj):
    """[(region, map id, room, [statues])] of the rooms with statues, in project order."""
    out = []
    for r in prj.rooms:
        if r.get('placeholder'):
            continue
        sts = room_statues(r)
        if not sts:
            continue
        mid = F.val(r['mapID'])
        out.append((F.mid_region(mid), mid & 0xFF, r, sts))
    return out


def data_lines(prj):
    """Bank $79's generated memorial data (always emitted with the bank's head)."""
    on = active(prj.custom)
    cap = settings(prj.custom)['cap'] if on else 0
    out = ['; ' + '=' * 77,
           '; THE MEMORIAL (generated by editor2/core/memorial.py, S154): the list\'s size, the',
           '; picture bank, the bosses fought by a plain battle op, the statues of each room.',
           '; ' + '=' * 77,
           f'MEM_CAP EQU {cap}            ; monsters remembered (custom.memorial.cap)',
           f'MEM_RING EQU {cap + RING_SLACK if on else 0}           ; the ring (MEM_CAP + {RING_SLACK})',
           f'MemPicBank: db ${plan(prj):02X}     ; the picture bank (entry 0 MemPicDraw)',
           'MemBossEids:']
    for eid, name in BOSS_EIDS:
        out.append(f'    dw {eid}   ; {name}')
    out.append('    dw $FFFF')
    out.append('MemRoomTable:   ; db region, map id, n, n x [tile ids TL, TR, BL, BR, '
               'shade map]')
    for reg, mid, r, sts in (room_rows(prj) if on else []):
        out.append(f'    db {reg}, ${mid:02X}, {len(sts)}   ; {r.get("name") or r.get("id")}')
        for s in sts:
            sh = statue_shades(s)
            out.append('    db ' + ', '.join(f'${t:02X}' for t in statue_tiles(s))
                       + f', ${shade_map(sh):02X}'
                       + f"   ; statue '{s['id']}' (the monster's colours 1 / 2 / 3 -> "
                       f"{sh[0]} / {sh[1]} / {sh[2]})")
    out.append('    db $FF')
    return out


def bank77_lines(prj):
    """MemorialRedraw77 — BreedClose's tail (bank $77 template)."""
    if active(prj.custom):
        return ['; S154 (memorial.py): BreedClose\'s sheet reload -> the statues drawn again',
                'MemorialRedraw77:',
                '    ld hl, $7908                       ; bank $79 entry 8 MemRoomTiles',
                '    rst $10',
                '    ret']
    return ['; S154 (memorial.py): no memorial statues in this project',
            'MemorialRedraw77:',
            '    ret']


VANILLA = {
    'memorial_battle_start': ('    ld hl, $1702\n'
                              '    rst $10\n'),
    'memorial_battle_end': ('    ld hl, $0106\n'
                            '    rst $10\n'),
    'memorial_tiles_0': ('    ld a, [wMapID]\n'
                         '    ld a, $08                       ; S123 r3: NOT a compare (bytes 3E 08): Z still comes from WaitDMATransfer (ends xor a), so\n'
                         '                                    ; the jr nz never branches: sheet $29:$1D -> $8800 (BG tiles $80-$AF) in EVERY room (PyBoy)\n'
                         '    jr nz, jr_00b_4076\n'),
    'memorial_tiles_1': ('    ld a, [wMapID]\n'
                         '    ld a, $08                       ; S123 r3: NOT a compare (bytes 3E 08): Z still comes from WaitDMATransfer (ends xor a), so\n'
                         '                                    ; the jr nz never branches: sheet $29:$1D -> $8800 (BG tiles $80-$AF) in EVERY room (PyBoy)\n'
                         '    jr nz, jr_00b_40c0\n'),
}

HOOK = {
    'memorial_battle_start': ('    ld hl, $7906                   ; S154 memorial: bank $79 entry 6 MemBattleStart (the party\n'
                              '    rst $10                        ;   count; it makes the replaced `ld hl, $1702 / rst $10`)\n'),
    'memorial_battle_end': ('    ld hl, $7907                   ; S154 memorial: bank $79 entry 7 MemBattleEnd (a won boss /\n'
                            '    rst $10                        ;   arena class / Starry Night; it makes the replaced $0106 call)\n'),
    'memorial_tiles_0': ('    ld hl, $7908                   ; S154 memorial: bank $79 entry 8 MemRoomTiles — the statues over\n'
                         '    rst $10                        ;   the room sheet just loaded (was the dead `ld a, [wMapID] /\n'
                         '    nop                            ;   ld a, $08 / jr nz`: the jr never branched, Z came from\n'
                         '    nop                            ;   WaitDMATransfer — S123 r3)\n'
                         '    nop\n'),
    'memorial_tiles_1': ('    ld hl, $7908                   ; S154 memorial: bank $79 entry 8 MemRoomTiles (the sheet reload\n'
                         '    rst $10                        ;   after a menu / a full-screen service)\n'
                         '    nop\n'
                         '    nop\n'
                         '    nop\n'),
}


def _region_fn(name):
    def fn(prj, warnings):
        return HOOK[name] if active(prj.custom) else VANILLA[name]
    fn.__name__ = f'emit_region_{name}'
    return fn


REGIONS = [('memorial_battle_start', 'patches/bank_050.asm', _region_fn('memorial_battle_start'), 0x50),
           ('memorial_battle_end', 'patches/bank_050.asm', _region_fn('memorial_battle_end'), 0x50),
           ('memorial_tiles_0', 'patches/bank_00b.asm', _region_fn('memorial_tiles_0'), 0x0B),
           ('memorial_tiles_1', 'patches/bank_00b.asm', _region_fn('memorial_tiles_1'), 0x0B)]


# ---------------------------------------------------------------------------
# checks (validators.validate)
# ---------------------------------------------------------------------------

def problems(prj):
    """-> (errors, warnings) about the memorial, in words."""
    errs, warns = [], []
    err = getattr(prj, 'memorial_error', None)
    if err:
        errs.append(f'memorial: {err}')
        return errs, warns
    if not active(prj.custom):
        return errs, warns
    try:
        settings(prj.custom)
    except MemorialError as ex:
        errs.append(str(ex))
    # the tag lives in record byte +$82 (resistance 26): a species whose info row
    # has a resistance 26 would hand every new monster a non-tag there
    rows = {}
    try:
        rows = {sid: bytes(r) for sid, r in enumerate(prj.gamedata().monster)}
        from . import species as SP
        for sp in SP.resolve(prj, with_art=False):
            rows[sp['id']] = sp['info']
    except Exception:                                  # noqa: BLE001 — reported elsewhere
        pass
    if rows:
        bad = [sid for sid, row in rows.items() if len(row) > 0x29 and row[0x29] != 0]
        if bad:
            errs.append('memorial: species ' + ', '.join(map(str, bad[:8]))
                        + ' have a resistance in the unused 27th slot — the memorial keeps its '
                        'mark there (it must stay 0)')
    for d in prj.custom.get('dialogue') or []:
        if not isinstance(d, dict):
            continue
        from . import textenc as T
        if T.uses_memorial(d.get('boxes') or d.get('text') or '') and not _statue_text(prj, d.get('id')):
            errs.append(f"dialogue {d.get('id')!r}: {{fallen}} / {{fallen_level}} / "
                        "{fallen_species} only work in a memorial statue's words (elsewhere "
                        "the game prints whatever is in memory and can crash)")
    return errs, warns


def _statue_text(prj, did):
    cfg = settings(prj.custom)
    if did in (cfg['text'] or DEFAULT_TEXT_ID, cfg['empty'] or DEFAULT_EMPTY_ID):
        return True
    for r in prj.custom.get('rooms') or []:
        for s in room_statues(r):
            if did in (s.get('text'), s.get('empty')):
                return True
    return False
