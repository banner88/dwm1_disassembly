"""species.py — NEW monster species (ids 221-239) as project data: `custom.species`
(ROADMAP P3.9b + G3, S105; PROJECT_COMPILER §2.21; MONSTER_DATA "Species-indexed
table overshoot registry").

Until S105 the one new species (Gorbunok, 224) was HAND DATA in eleven patch
files + extracted/new_species.json, so it was in every project's build. The
FORKS that make a new species possible (info copy, 8 follower gfx-id
resolvers, follower attr / layout, battle palette, detail text, recipe
display, default-nickname redirect) stay hand-authored mechanism; the DATA
they read is emitted here from project.json into @BUILD_PROJECT regions.
An empty `custom.species` writes the ORIGINAL ROM bytes into every one of
those regions (test_compiler: "no species -> vanilla bytes at every ns_* site").

CAPACITY (S105 G3, user choice "19 monsters"): ids 221-239, any subset, any
order. Why exactly these: vanilla uses 0-220; the library seen-bit array
($CA94, 30 bytes) covers 0-239; $F0-$FA are the breeding family codes the
special-recipe scanner compares species bytes against; $FE / $FF are the
library "unseen" marker and the none/terminator; and the bank-$04 follower
router's species+$10 wraps at 240. So 240+ can never be a monster.

Schema (one entry per species; PROJECT_COMPILER §2.21):

  "species": [{
    "id": 224,                     # 221-239, each at most once
    "name": "Gorbunok",            # 1-9 letters A-Z / a-z (bank $41 text)
    "short_name": "Gorb",          # 1-4 letters; default = first 4 of name
                                   #   (default nickname + "take X with you")
    "info": {"clone_from": 78, "family": "Slime", ...}
                                   # the 43-byte MonsterInfoTable row: a VANILLA
                                   # species' row + gamedata.monsters field names
    "description_from": 78,        # encyclopedia line 2 = that species' text
                                   #   (0-214; the line-2 table has 215 rows)
    "battle":   {"art": "assets/species/x_battle.bin",   # LZ stream, 576 B decoded
                 "palette": ["$4D67", "$6BFF", "$7FFF", "$0000"]},
    "follower": {"art": "assets/species/x_follower.bin", # LZ stream, 256 B decoded
                 "walks_like": 128,                      # layout donor, 128-214
                 "palette": 2}                            # OBJ palette 0-7
  }]

Derived, never authored: the recipe the encyclopedia shows (bank $16 display
pair + the bank $4D "Parent1  Parent2" line) = the FIRST special breeding
entry whose result is the species (gamedata.breeding.special), so the page
always matches what really breeds it (coherence Set 1). No recipe -> the
vanilla "no recipe" pair $FF,$FF and the vanilla "?????" line ($4D:$53C4).
A species' ENEMY rows (wild / boss) are ordinary progression.enemies with
`species: <id>` (EID 519+, bank $6B) — the S30 EID-518 row is retired.

Where the data goes (all id-indexed, index = id - 221):
  * art: overflow bank $7E (compiler file `species7e`). Pointer table at $4001
    has 38 entries: index (id-221)*2 = follower stream, +1 = battle stream. The
    eight follower forks COMPUTE $7E00+(id-221)*2 into WRAM wNewSpeciesGid (no
    per-bank tables); the battle gfx-ID goes in the ROM0 table ($2B9F+id*2).
    Undeclared ids alias the first declared species' streams (never read).
    Budget: 16384 - 77 B of streams (19 near-raw species = 15,922 B fit).
  * names / nicknames: bank $41 has no room for fixed slots, so the strings are
    PACKED into seven free extents (TEXT_EXTENTS, 292 B, identical strings and
    suffixes shared). 19 eight-letter names + 19 four-letter nicknames fit;
    19 nine-letter names + 19 distinct four-letter nicknames do not (error).

Walking layout (S105 fix): a new species borrows a bank-$11 species' layout.
The pre-S105 patch WROTE the layout pointer at $11:$407f + (224-128)*2 =
$413F, which is inside the follower ATTR table ($412D-$4183, species
128-214): it overwrote ChopClown (146) / Grendal (147)'s attr bytes in every
build. Now NewAttrHandler (bank $11) rewrites HRAM $C7 to the DONOR's own
level-1 index, so the layout lookup reads the donor's untouched pointer.
"""

import os

from . import formats as F
from . import walk_layouts as WL

FIRST_ID, LAST_ID = 221, 239
CAPACITY_IDS = tuple(range(FIRST_ID, LAST_ID + 1))   # 19 ids
N_IDS = len(CAPACITY_IDS)
NAME_MAX = 9                 # the longest vanilla name (DrakSlime, 9 letters)
SHORT_MAX = 4                # the nickname field is 4 characters
FOLLOWER_DECODED = 256       # 16 tiles (every vanilla follower stream)
BATTLE_DECODED = 576         # 36 tiles, 48x48 (every vanilla battle stream)
DONOR_MIN, DONOR_MAX = 128, 214   # bank-$11 layout owners (level-1 index 0-86)
LAYOUT0_L2_11 = 0x4184           # Armorpion's level-2 table = layout 0 in bank $11
DESC_MAX = 214               # bank $4D mode-1 (line 2) table: 215 rows
OVERFLOW_BANK = 0x7E
NO_RECIPE_LINE = 0x53C4      # vanilla "?????    ?????" (mode-0 slots 220-225)
VANILLA_BATTLE_GFX = 0x320F  # $00:$2B9F+id*2 of ids 216-255 = Darkdrium's (214) art (S107; once mis-called a "Durran" placeholder)
# MonsterNamePtrTable [221]-[239] in the original ROM
VANILLA_NAME_PTR = {sid: ('MonsterName_220_Unused_220' if sid <= 224 else
                          'MonsterName_225_Unused_225') for sid in CAPACITY_IDS}
# bank $41 free extents for the packed name / nickname strings, in fill order:
# (region, address, size, original bytes). $7E38 / $7E86 / $7F19 / $7FF6 /
# $7E77 are the bank's zero tail (S105 re-sectioned around the 38-byte nickname
# pointer table at $7EF3; $7E77 = the Spirit-name fill's unused last 15 B);
# $581F is two unreferenced vanilla default names; $728B is the vanilla
# MiscText_03, dead since Stage 2 (MiscTextPtrTable[3] -> MiscText_03_Paged).
# The only bank-$41 free bytes (full-bank scan S105). Worst case 19 x (9+1) +
# 19 x (4+1) = 285 B does NOT pack (the extents waste >= 12 B for 10/5-B
# strings); 19 x (8+1) + 19 x (4+1) = 266 B does.
MISC_TEXT_03 = bytes.fromhex('edf9006862f930f13f42404c4a425062f92063faf7f0')
DEAD_NAMES_581F = bytes.fromhex('362f2426f030282f37f0')   # "SLAC" "MELT", unreferenced
TEXT_EXTENTS = [('ns_text_a', 0x7E38, 23, bytes(23)),
                ('ns_text_b', 0x7E86, 109, bytes(109)),
                ('ns_text_c', 0x7F19, 103, bytes(103)),
                ('ns_text_d', 0x7FF6, 10, bytes(10)),
                ('ns_text_f', 0x7E77, 15, bytes(15)),   # Spirit-name fill slack
                ('ns_text_g', 0x581F, 10, DEAD_NAMES_581F),
                ('ns_text_e', 0x728B, 22, MISC_TEXT_03)]
TEXT_BUDGET = sum(e[2] for e in TEXT_EXTENTS)        # 292


class SpeciesError(ValueError):
    pass


def _db(bs):
    return "    db " + ", ".join(f"${b:02X}" for b in bs)


def name_bytes(n, what, lo, hi):
    """S108: the one name encoder for every monster name / nickname (bank $41,
    literal glyphs, no DTE): letters, digits, space and ' , . ! ? - &
    (monster_text.encode_name; S105-S107 allowed letters only)."""
    from . import monster_text as MT
    try:
        return MT.encode_name(n, what, lo, hi)
    except MT.MonsterTextError as e:
        raise SpeciesError(str(e))


def _art(prj, spec, what, decoded):
    rel = spec.get('art')
    if not isinstance(rel, str):
        raise SpeciesError(f"{what}.art: a path to an LZ stream file in the project")
    path = os.path.join(prj.root, rel)
    try:
        data = open(path, 'rb').read()
    except OSError:
        raise SpeciesError(f"{what}.art: cannot read {rel!r}")
    from dwm.sprite_codec import decode
    try:
        n = len(decode(data))
    except Exception as ex:                       # noqa: BLE001
        raise SpeciesError(f"{what}.art: {rel!r} does not decode ({ex})")
    if n != decoded:
        # S75: a stream that decodes short / long over- or under-reads in some
        # consumer context (tools/validate_custom_data.py)
        raise SpeciesError(f"{what}.art: {rel!r} decodes to {n} bytes; this art "
                           f"slot needs exactly {decoded}")
    return data


def _vanilla_rows(prj):
    from . import gamedata as G
    repo = getattr(prj, 'repo_root', None) or _repo()
    return G._rows(G.vanilla(repo), 'monster_info')


def _repo():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def _vanilla_l1_11(prj):
    """FollowerLayoutL1Table11 as the original ROM has it (87 level-2
    addresses, species 128-214)."""
    from . import gamedata as G
    repo = getattr(prj, 'repo_root', None) or _repo()
    return [int(r[2:4] + r[0:2], 16) for r in G.vanilla(repo)['tables']['follower_layout_11']['rows']]


def basics(prj):
    """{id: {'name', 'family'}} for the gamedata model (library tabs, breeding
    names / family codes) — cheap, no art is read."""
    out = {}
    for s in resolve(prj, with_art=False):
        out[s['id']] = {'name': s['name'], 'family': s['info'][0]}
    return out


def resolve(prj, with_art=True):
    """Validate custom.species -> list of dicts sorted by id (id, name, name_b,
    short, short_b, info (43 B), desc_species, battle_art, battle_pal (8 B),
    follower_art, donor, follower_pal). Raises SpeciesError."""
    from . import gamedata as G
    lst = (prj.data.get('custom') or {}).get('species') or []
    if not isinstance(lst, list):
        raise SpeciesError("custom.species: must be a list")
    if len(lst) > N_IDS:
        raise SpeciesError(f"custom.species: {len(lst)} species > capacity {N_IDS} "
                           f"(ids {FIRST_ID}-{LAST_ID})")
    rows = _vanilla_rows(prj)
    out, seen = [], {}
    for k, s in enumerate(lst):
        what = f"custom.species[{k}]"
        if not isinstance(s, dict):
            raise SpeciesError(f"{what}: must be an object")
        # `source` (S106): where the art came from (sheet + boxes), written
        # by the Monsters tab's sheet import so the art can be re-cut later;
        # the compiler never reads it
        G._check_keys(s, ('id', 'name', 'short_name', 'info', 'description_from',
                          'description', 'battle', 'follower', 'comment', 'source'), what)
        sid = s.get('id')
        if isinstance(sid, bool) or sid not in CAPACITY_IDS:
            raise SpeciesError(f"{what}.id: {sid!r} — new species ids are "
                               f"{FIRST_ID}-{LAST_ID} (0-220 are the original monsters; "
                               "240+ collide with the breeding family codes $F0-$FA "
                               "and the library / follower id limits)")
        if sid in seen:
            raise SpeciesError(f"{what}.id: {sid} is already custom.species[{seen[sid]}]")
        seen[sid] = k
        name = s.get('name')
        nb = name_bytes(name, what + '.name', 1, NAME_MAX)
        sn = s.get('short_name', name[:SHORT_MAX])
        sb = name_bytes(sn, what + '.short_name', 1, SHORT_MAX)
        info = s.get('info') or {}
        if not isinstance(info, dict) or 'clone_from' not in info:
            raise SpeciesError(f"{what}.info: needs clone_from (a vanilla species "
                               "0-220 whose row is the starting point)")
        cf = G._range(info['clone_from'], 0, 220, what + '.info.clone_from')
        row = bytearray(rows[cf])
        try:
            G.apply_monster_fields(row, {k2: v for k2, v in info.items()
                                         if k2 != 'clone_from'}, what + '.info')
        except G.GamedataError as ex:
            raise SpeciesError(str(ex))
        desc = G._range(s.get('description_from', cf if cf <= DESC_MAX else 0),
                        0, DESC_MAX, what + '.description_from')
        # S108 (P3.10 part 3): or its OWN description (1-3 lines of 18 cells)
        desc_b = None
        if 'description' in s:
            if 'description_from' in s:
                raise SpeciesError(f"{what}: give `description` OR `description_from`, not both")
            from . import monster_text as MT
            try:
                desc_b = MT.encode_desc(s['description'], what + '.description')
            except MT.MonsterTextError as ex:
                raise SpeciesError(str(ex))
        b = s.get('battle') or {}
        fo = s.get('follower') or {}
        G._check_keys(b, ('art', 'palette', 'comment'), what + '.battle')
        G._check_keys(fo, ('art', 'walks_like', 'layout', 'palette', 'comment'),
                      what + '.follower')
        pal = b.get('palette')
        if not isinstance(pal, list) or len(pal) != 4:
            raise SpeciesError(f"{what}.battle.palette: 4 RGB555 colours "
                               "[c0, c1 = $6BFF backdrop, c2, c3 = $0000] "
                               "(MONSTER_DATA 'battle palette')")
        pb = b''
        for i, c in enumerate(pal):
            v = G._range(c, 0, 0x7FFF, f"{what}.battle.palette[{i}]")
            pb += bytes((v & 0xFF, v >> 8))
        repo = getattr(prj, 'repo_root', None)
        if 'layout' in fo:
            # S107 (P3.10 part 2b): any of the 155 layouts (the art is packed
            # for it); one bank $11 lacks is copied into its free tail
            if 'walks_like' in fo:
                raise SpeciesError(f"{what}.follower: give `layout` OR `walks_like`, "
                                   "not both")
            try:
                lid = WL.layout(fo['layout'], repo)['id']
            except WL.LayoutError as ex:
                raise SpeciesError(f"{what}.follower.layout: {ex}")
            donor = None
            l2 = WL.l2_ref(lid, 0x11, repo) if lid != WL.LAYOUT0 else LAYOUT0_L2_11
        else:
            donor = G._range(fo.get('walks_like', DONOR_MIN), DONOR_MIN, DONOR_MAX,
                             what + '.follower.walks_like')
            lid = WL.species_layout(donor, repo)
            l2 = _vanilla_l1_11(prj)[donor - DONOR_MIN]     # the donor's own table
        fpal = G._range(fo.get('palette', 0), 0, 7, what + '.follower.palette')
        out.append({
            'id': sid, 'name': name, 'name_b': nb, 'short': sn, 'short_b': sb,
            'info': bytes(row), 'desc_species': desc, 'desc_b': desc_b,
            'battle_art': _art(prj, b, what + '.battle', BATTLE_DECODED) if with_art else None,
            'battle_pal': pb,
            'follower_art': _art(prj, fo, what + '.follower', FOLLOWER_DECODED) if with_art else None,
            'donor': donor, 'follower_pal': fpal, 'layout': lid, 'l2': l2,
        })
    out.sort(key=lambda d: d['id'])
    text_layout(out, _spills(prj))                # raises if the names do not fit
    return out


def _spills(prj):
    """S108: original monsters' names / nicknames that no longer fit their
    bank-$41 blocks (gamedata.monster_text) share the free extents."""
    from . import monster_text as MT
    try:
        return MT.bank41_spills(prj)
    except MT.MonsterTextError:
        return []                                 # reported by the validator


# ---------------------------------------------------------------------------
# derived: gfx ids in the overflow bank, the bank-$41 text layout, the recipe
# ---------------------------------------------------------------------------

def _gfx_ids(sid):
    """(follower, battle) gfx-IDs of species `sid`: bank $7E index (sid-221)*2
    and +1. The follower index is what the eight forks compute (patches:
    FollowerArtResolveXX .high -> wNewSpeciesGid)."""
    k = sid - FIRST_ID
    return (OVERFLOW_BANK << 8) | (2 * k), (OVERFLOW_BANK << 8) | (2 * k + 1)


def _pack(sizes, caps):
    """Exact bin packing (small: <= 38 items, 5 bins): -> [bin index per
    item] or None. Items in the given order (largest first); bins with the
    same remaining capacity are interchangeable at each step (symmetry cut);
    failed states are memoised. Deterministic."""
    n = len(sizes)
    suffix = [0] * (n + 1)
    for k in range(n - 1, -1, -1):
        suffix[k] = suffix[k + 1] + sizes[k]
    dead = set()
    where = [None] * n

    def go(k, rem):
        if k == n:
            return True
        key = (k, rem)
        if key in dead or sum(rem) < suffix[k]:
            return False
        tried = set()
        for b, r in enumerate(rem):
            if r >= sizes[k] and r not in tried:
                tried.add(r)
                where[k] = b
                if go(k + 1, rem[:b] + (r - sizes[k],) + rem[b + 1:]):
                    return True
        dead.add(key)
        return False
    return list(where) if go(0, tuple(caps)) else None


def _ffd(sizes, caps):
    """First fit (items in the given order, bins in TEXT_EXTENTS order) — the
    exact search's first path, so whenever it succeeds the result is the one
    _pack would return; it keeps big inputs (S108 spills) fast."""
    rem, where = list(caps), []
    for n in sizes:
        for b, r in enumerate(rem):
            if r >= n:
                rem[b] -= n
                where.append(b)
                break
        else:
            return None
    return where


def text_layout(lst, extra=()):
    """Pack the names + nicknames into TEXT_EXTENTS (S108: + `extra`, the
    [(label, bytes incl. $F0)] original-monster strings that no longer fit
    their own blocks — monster_text.bank41_spills). Returns
    ({region: [(label, bytes)]}, {(sid, 'name'|'short'): label expression}).
    A string equal to / a suffix of a longer one points into it; the rest are
    packed exactly (fill order = TEXT_EXTENTS order, so a light project uses
    only the first extent). Raises SpeciesError when they do not fit."""
    strings = []                                  # (kind, sid, bytes)
    for s in lst:
        strings.append(('name', s['id'], s['name_b'] + b'\xf0'))
        strings.append(('short', s['id'], s['short_b'] + b'\xf0'))
    for label, b in extra:
        strings.append(('spill', label, b))
    order = sorted(range(len(strings)), key=lambda i: (-len(strings[i][2]), i))
    prim, ref = [], {}
    for i in order:
        kind, sid, b = strings[i]
        label = (f"NsName_{sid}" if kind == 'name' else
                 f"NsShort_{sid}" if kind == 'short' else sid)
        if kind == 'spill':
            # the pointer table names this label, so it is always DEFINED at
            # its own bytes (never a suffix pointer into another string)
            prim.append((label, b))
            ref[(sid, kind)] = label
            continue
        for plab, pb in prim:
            if pb.endswith(b):
                off = len(pb) - len(b)
                ref[(sid, kind)] = plab if off == 0 else f"{plab} + {off}"
                break
        else:
            prim.append((label, b))
            ref[(sid, kind)] = label
    sizes, caps = [len(b) for _l, b in prim], [e[2] for e in TEXT_EXTENTS]
    where = _ffd(sizes, caps)
    if where is None and len(sizes) <= 40:
        where = _pack(sizes, caps)
    if where is None:
        need = sum(len(b) for _l, b in prim)
        raise SpeciesError(
            f"monster names: the new species' names + nicknames"
            + (f" and {len(extra)} renamed original name(s) / nickname(s) that no longer "
               "fit their own blocks" if extra else "")
            + f" need {need} bytes of bank $41 text ({len(prim)} strings incl. $F0 ends; "
            f"equal ones are shared); the free extents hold {TEXT_BUDGET} "
            f"({', '.join(str(e[2]) for e in TEXT_EXTENTS)}) and these do not pack into "
            "them — shorten some names or nicknames")
    regions = {e[0]: [] for e in TEXT_EXTENTS}
    for (label, b), w in zip(prim, where):
        regions[TEXT_EXTENTS[w][0]].append((label, b))
    return regions, ref


def recipe(prj, sid):
    """(p1, p2) matcher bytes of the first special entry breeding `sid`, else
    None. The live table (overrides + appends) is the gamedata model's."""
    g = prj.gamedata()
    for e in g.special:
        if e[3] == sid:
            return e[0], e[1]
    return None


def recipe_line(prj, pair, lst=None):
    """The bank-$4D line-1 string: the vanilla recipe format (two 9-char
    fields + $F0; TEXT_SYSTEM / gamedata.library_text_edits)."""
    from . import gamedata as G
    g = prj.gamedata()
    lib = g.v['library']
    pad = lib['pad']
    tok = {int(k): bytes.fromhex(v) for k, v in lib['family_tokens'].items()}
    from . import monster_text as MT
    names = [b.hex() for b in MT.effective(prj)['names']]     # S108: project names
    if lst is None:
        lst = resolve(prj, with_art=False)
    own = {s['id']: s['name_b'] for s in lst}

    def token(m):
        if 0xF0 <= m <= 0xF9:
            return tok[m - 0xF0]
        if m == 0xFA:
            return G.SPIRIT_TOKEN
        if m in own:
            return own[m]
        return bytes.fromhex(names[m])
    t1 = token(pair[0])[:9].ljust(9, bytes([pad]))
    t2 = token(pair[1])
    if lib['pad_token2']:
        t2 = t2.ljust(9, bytes([pad]))
    return t1 + t2 + b'\xf0'


def desc_pointer(sid, repo_root=None):
    """Line-2 (description) label of ORIGINAL species `sid` (0-214): the
    `MonsterDesc_NNN_<Name>` rows of bank $4D (S108 re-section; in the patched
    tree they are the compiler region gd_monster_desc, so an edited description
    is followed automatically). Label = mode-1 pointer-table entry 261 + sid."""
    from . import monster_text as MT
    return MT.desc_label(sid)


# ---------------------------------------------------------------------------
# emitters (one per @BUILD_PROJECT region; names ns_*). Every table region is
# id-indexed over 221-239 (19 rows); an undeclared id gets the original bytes
# (or, where the original is a pad, zeros — never read: nothing can hold an
# undeclared id, the validators refuse it everywhere).
# ---------------------------------------------------------------------------

def _by_id(prj, with_art=False):
    return {s['id']: s for s in resolve(prj, with_art=with_art)}


def _rows(prj, fn, with_art=False):
    sp = _by_id(prj, with_art)
    return "".join(fn(sid, sp.get(sid)) for sid in CAPACITY_IDS)


def emit_battle_gfx(prj, warnings):
    def row(sid, s):
        gid = _gfx_ids(sid)[1] if s else VANILLA_BATTLE_GFX
        what = s['name'] if s else 'vanilla placeholder'
        return f"    db ${gid & 0xFF:02X}, ${gid >> 8:02X}   ; [{sid}] battle gfx-ID ({what})\n"
    return _rows(prj, row)


def emit_follower_attr(prj, warnings):
    """bank $11 NewFollowerAttrTable: 1 B per id = the clean OBJ attr
    (palette) NewAttrHandler ORs into [$CA] (S105; S107 2b: the layout moved
    to NewFollowerL1Table)."""
    def row(sid, s):
        if s:
            return (_db([s['follower_pal']])
                    + f"   ; [{sid}] {s['name']}: OBJ palette {s['follower_pal']}\n")
        return _db([0]) + f"   ; [{sid}] (none)\n"
    return _rows(prj, row)


def emit_follower_layout(prj, warnings):
    """bank $11 NewFollowerL1Table (S107 P3.10 part 2b): 1 dw per id = the
    species' level-2 layout table — FollowerLayoutBase11 points both bank-$11
    follower entries' lookup here for species 221+ (index [$C7] = id-$80).
    `walks_like` = the donor's own table; `layout` = that layout's table in
    bank $11 or its copy (walk_layouts). Undeclared ids: $0000 (never read;
    = the original ROM's zero padding, so a project without species builds
    the original bytes there)."""
    def row(sid, s):
        if not s:
            return "    dw $0000   ; [{}] (none — never read)\n".format(sid)
        l2 = s['l2'] if isinstance(s['l2'], str) else f"${s['l2']:04X}"
        how = (f"walks like species {s['donor']}" if s['donor'] is not None
               else f"layout {s['layout']}")
        return f"    dw {l2}   ; [{sid}] {s['name']}: {how}\n"
    return _rows(prj, row)


def emit_battle_pal(prj, warnings):
    def row(sid, s):
        if s:
            return _db(s['battle_pal']) + f"   ; [{sid}] {s['name']} battle palette (RGB555 LE)\n"
        return _db([0] * 8) + f"   ; [{sid}] (none)\n"
    return _rows(prj, row)


def emit_recipe_pair(prj, warnings):
    def row(sid, s):
        if not s:
            return _db([0, 0]) + f"   ; [{sid}] (none)\n"
        pair = recipe(prj, sid)
        if pair:
            return _db(pair) + f"   ; [{sid}] {s['name']}: encyclopedia parents (first special entry)\n"
        return _db([0xFF, 0xFF]) + f"   ; [{sid}] {s['name']}: no breeding recipe\n"
    return _rows(prj, row)


def emit_name_ptr(prj, warnings):
    lst = resolve(prj, with_art=False)
    _, ref = text_layout(lst, _spills(prj))
    sp = {s['id']: s for s in lst}
    out = []
    for sid in CAPACITY_IDS:
        if sid in sp:
            out.append(f"    dw {ref[(sid, 'name')]}  ; [{sid}] custom.species {sp[sid]['name']}")
        else:
            out.append(f"    dw {VANILLA_NAME_PTR[sid]}  ; [{sid}]")
    return "\n".join(out) + "\n"


def emit_short_ptr(prj, warnings):
    lst = resolve(prj, with_art=False)
    _, ref = text_layout(lst, _spills(prj))
    sp = {s['id']: s for s in lst}
    out = []
    for sid in CAPACITY_IDS:
        if sid in sp:
            out.append(f"    dw {ref[(sid, 'short')]}  ; [{sid}] default nickname \"{sp[sid]['short']}\"")
        else:
            out.append(f"    dw $0000  ; [{sid}] (none)")
    return "\n".join(out) + "\n"


def _text_emit(region):
    size, orig = next((e[2], e[3]) for e in TEXT_EXTENTS if e[0] == region)

    def emit(prj, warnings):
        regions, _ = text_layout(resolve(prj, with_art=False), _spills(prj))
        items = regions[region]
        if not items:
            return _db(orig) + "   ; unused: the original bytes\n"
        out, used = [], 0
        for label, b in items:
            out.append(f"{label}:")
            out.append(_db(b))
            used += len(b)
        if used < size:
            out.append(f"    ds {size - used}, $00")
        return "\n".join(out) + "\n"
    emit.__name__ = f"emit_{region}"
    return emit


def emit_detail_text(prj, warnings):
    """bank $4D: HighLine2Ptrs / HighMode0Ptrs (one word per id 221-239,
    indexed through HighModeTable4D's shifted bases) + the recipe lines."""
    lst = resolve(prj, with_art=False)
    if not lst:
        return ("; (no new species: labels only — the bank's zero pad follows; never read)\n"
                "HighLine2Ptrs:\nHighMode0Ptrs:\n")
    sp = {s['id']: s for s in lst}
    repo = getattr(prj, 'repo_root', None) or _repo()
    l2 = ["HighLine2Ptrs:                    ; line 2 (description) pointers, ids 221-239"]
    m0 = ["HighMode0Ptrs:                    ; line 1 (recipe) pointers, ids 221-239"]
    lines = []
    for sid in CAPACITY_IDS:
        s = sp.get(sid)
        if not s:
            l2.append(f"    dw ${NO_RECIPE_LINE:04X}   ; [{sid}] (none)")
            m0.append(f"    dw ${NO_RECIPE_LINE:04X}   ; [{sid}] (none)")
            continue
        if s.get('desc_b') is not None:
            from . import monster_text as MT
            l2.append(f"    dw {MT.ns_desc_label(sid)}   ; [{sid}] {s['name']}: its own description")
        else:
            dp = desc_pointer(s['desc_species'], repo)
            l2.append(f"    dw {dp}   ; [{sid}] {s['name']}: species {s['desc_species']}'s description")
        pair = recipe(prj, sid)
        if pair:
            m0.append(f"    dw NewSpeciesRecipeLine_{sid}")
            lines += [f"NewSpeciesRecipeLine_{sid}:   ; derived from the first special entry breeding {sid}",
                      _db(recipe_line(prj, pair, lst))]
        else:
            m0.append(f"    dw ${NO_RECIPE_LINE:04X}   ; [{sid}] {s['name']}: no recipe -> vanilla \"?????\"")
    return "\n".join(l2 + m0 + lines) + "\n"


def emit_info(prj, warnings):
    sp = _by_id(prj)
    out = []
    for k, sid in enumerate(CAPACITY_IDS):
        s = sp.get(sid)
        if s:
            out += [f"; --- slot {k}: species {sid} ({s['name']}; custom.species) ---", _db(s['info'])]
        else:
            out += [f"; --- slot {k}: species {sid} (empty) ---", "    ds 43, $00"]
    return "\n".join(out) + "\n"


BANK_7E_BUDGET = 0x4000 - 1 - 2 * 2 * N_IDS      # stream bytes after self-ID + table


def emit_bank_07e(prj, warnings):
    lst = resolve(prj)
    head = ["; OVERFLOW BANK $7E holds the project's NEW-SPECIES art streams",
            "; (generated by editor2 `species7e` from custom.species, S105 P3.9b / G3).",
            "; Pointer table at $4001, 38 entries: index (id-221)*2 = follower stream",
            "; (16 tiles; the eight FollowerArtResolveXX forks compute $7E00+index),",
            "; +1 = battle stream (36 tiles; ROM0 MonsterBattleGfxTable[id] = $7E00+index).",
            "; An undeclared id's two entries alias the first declared species' streams",
            "; (never read). Empty project = an all-zero bank, exactly like the original ROM.",
            ""]
    if not lst:
        return "\n".join(head + ['SECTION "Sprite Overflow Bank $7E", ROMX[$4000], BANK[$7E]',
                                 "    ds $4000, $00", ""])
    used = sum(len(s['follower_art']) + len(s['battle_art']) for s in lst)
    if used > BANK_7E_BUDGET:
        raise SpeciesError(f"custom.species: the art streams total {used} bytes; overflow "
                           f"bank $7E holds {BANK_7E_BUDGET} (re-bake them with "
                           "tools/bake_follower_overflow.py — a literal stream is decoded+3)")
    sp = {s['id']: s for s in lst}
    first = lst[0]['id']
    out = head + ['SECTION "Sprite Overflow Bank $7E", ROMX[$4000], BANK[$7E]',
                  "    db $7E                          ; bank self-ID at $4000 (resolver ignores)",
                  "", "SpriteOverflowPtrs_7E:            ; pointer table @ $4001"]
    for sid in CAPACITY_IDS:
        src = sid if sid in sp else first
        note = "" if sid in sp else f"   ; (none: aliases {first})"
        k = sid - FIRST_ID
        out.append(f"    dw Follower_sp{src:<5}           ; index {2 * k} (${2 * k:02x}) [{sid}]{note}")
        out.append(f"    dw Battle_sp{src:<5}             ; index {2 * k + 1} (${2 * k + 1:02x}) [{sid}]{note}")
    out.append("")
    for s in lst:
        for kind, key in (('Follower', 'follower_art'), ('Battle', 'battle_art')):
            b = s[key]
            out.append(f"{kind}_sp{s['id']}:  ; {s['name']} ({len(b)} B)")
            for o in range(0, len(b), 16):
                out.append("    db " + ", ".join(f"${x:02x}" for x in b[o:o + 16]))
    out.append("")
    out.append(f"    ds $8000 - @, $00   ; zero-pad (streams {used} B of {BANK_7E_BUDGET})")
    out.append("")
    return "\n".join(out)


REGIONS = [
    ('ns_battle_gfx', 'patches/bank_000.asm', emit_battle_gfx, 0x00),
    ('ns_follower_attr', 'patches/bank_011.asm', emit_follower_attr, 0x11),
    ('ns_follower_layout', 'patches/bank_011.asm', emit_follower_layout, 0x11),
    ('ns_battle_pal', 'patches/bank_017.asm', emit_battle_pal, 0x17),
    ('ns_recipe_pair', 'patches/bank_016.asm', emit_recipe_pair, 0x16),
    ('ns_name_ptr', 'patches/bank_041.asm', emit_name_ptr, 0x41),
    ('ns_short_ptr', 'patches/bank_041.asm', emit_short_ptr, 0x41),
] + [(reg, 'patches/bank_041.asm', _text_emit(reg), 0x41) for reg, *_ in TEXT_EXTENTS] + [
    ('ns_detail_text', 'patches/bank_04d.asm', emit_detail_text, 0x4D),
    ('ns_info', 'patches/bank_06a.asm', emit_info, 0x6A),
]
