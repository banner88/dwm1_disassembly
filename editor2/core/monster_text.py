"""monster_text.py — the ORIGINAL monsters' names, default nicknames and
descriptions as project data: `gamedata.monster_text` (ROADMAP P3.10 part 3,
S108; PROJECT_COMPILER §2.24; TEXT_SYSTEM "Monster text blocks").

What the game stores per species (ROM-verified S108, extract_gamedata
--selftest re-proves the block shapes):
  * NAME — bank $41, text mode 5 (MonsterNamePtrTable $4339, 256 words). One
    $F0-terminated string per species 0-219, then the empty string of 220
    (also 221-224) and "?????" (225-255), back to back in id order at
    $5B1F-$628D (1,903 B; no gaps, no sharing). 3-9 letters in vanilla.
    Every screen that prints a species name (battle, menus, INFO, library,
    breeding, joins) reads it through that table.
  * DEFAULT NICKNAME — bank $41, text mode 7 (MonsterNickPtrTable $4739, 215
    words; the old mgbdis name was FamilyCodePtrTable). Two letters per
    species ("SL" for Slime) at $69F2-$6C76 (645 B). MEASURED S108: the JOIN
    naming screen pre-fills the 4-letter nickname field with it. New species
    already have 1-4 letters here (custom.species short_name), so originals
    get the same range.
  * DESCRIPTION — bank $4D, text mode 1 (dispatch entries 261-475). The
    library detail page's line 2: up to 3 lines of 18 cells ($F1 = next
    line), $53D3-$7719 (9,031 B), id order. Glyphs beyond the letters: $9C '-',
    $B6 '&', and the one-cell ligatures $67 "'t" / $68 "'s" (font bank $4F).

Species 0-214 only: 215-220 (TERRY? and the summons) are not monsters
(PROJECT_STATE Iron Rule 8); 221-239 keep their text in custom.species
(name / short_name / description).

Schema (sparse; keys = species ids as strings; every field optional):

  "monster_text": {
    "8":  {"name": "Goo", "nickname": "GOO",
           "description": ["A blob that", "jiggles when it", "is happy"]},
    "28": {"description": ["The oldest living", "species of dragon"]}
  }

Layout (no edits = the original bytes in every region):
  * gd_monster_names (bank $41 $5B1F, 1,903 B): the 222 strings in id order,
    first-fit — a string that no longer fits the block is placed in the
    new-species text extents (species.TEXT_EXTENTS, shared with custom.species,
    suffix-shared where possible) under the SAME label, so the pointer table
    never changes. Unused block bytes are $00.
  * gd_monster_nicks (bank $41 $69F2, 645 B): the same for the 215 nicknames.
  * gd_monster_desc (bank $4D $53D3, 9,031 B): the 215 descriptions; overflow
    + the new species' own descriptions go to gd_monster_desc_extra at the end
    of bank $4D (after ns_detail_text; room = the bank's zero tail).

Coherence: the library recipe line of every species whose recipe NAMES a
renamed monster is regenerated (gamedata.library_text_edits; vanilla's own
typos in those lines, e.g. Akubar's "Grenadal", disappear with it), and the
new species' recipe lines use the project names too.
"""

import json
import os
import re

IDS = range(0, 215)
PROTECTED = range(215, 221)
NAME_MAX, NICK_MAX = 9, 4
DESC_LINES, DESC_CELLS = 3, 18
NAME_BLOCK = (0x5B1F, 0x628E)     # bank $41 [lo, hi)
NICK_BLOCK = (0x69F2, 0x6C77)     # bank $41
DESC_BLOCK = (0x53D3, 0x771A)     # bank $4D
NAME_ORDER = list(range(220)) + [220, 225]
NEWLINE = 0xF1

# names / nicknames: single glyphs only (no ligatures — the naming screen
# and every name field draw one glyph per letter)
_NAME_CHARS = {str(d): d for d in range(10)}
_NAME_CHARS.update({chr(0x41 + i): 0x24 + i for i in range(26)})
_NAME_CHARS.update({chr(0x61 + i): 0x3E + i for i in range(26)})
_NAME_CHARS.update({"'": 0x5C, ',': 0x5E, '.': 0x5F, ' ': 0x62, '!': 0x63,
                    '?': 0x64, '-': 0x9C, '&': 0xB6})
NAME_CHARS = ''.join(sorted(_NAME_CHARS))
# descriptions: + the one-cell ligatures vanilla uses (longest match first)
_DESC_MULTI = {"'t": 0x67, "'s": 0x68, '..': 0x61}
_DESC_CHARS = dict(_NAME_CHARS, **{';': 0x60})
_DECODE = {v: k for k, v in _DESC_CHARS.items()}
_DECODE.update({v: k for k, v in _DESC_MULTI.items()})
_DECODE[0x5D] = '>'                                     # never authored


class MonsterTextError(ValueError):
    pass


def _repo():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


_VAN = {}


def vanilla(repo_root=None):
    """{'names': [256 bytes], 'nicks': [215], 'descs': [215], ...} from
    extracted/gamedata_vanilla.json (no ROM needed)."""
    repo = repo_root or _repo()
    if repo not in _VAN:
        v = json.load(open(os.path.join(repo, 'extracted', 'gamedata_vanilla.json')))
        mt = v['monster_text']
        _VAN[repo] = {'names': [bytes.fromhex(h) for h in v['monster_name_bytes']],
                      'nicks': [bytes.fromhex(h) for h in mt['nicks']],
                      'descs': [bytes.fromhex(h) for h in mt['descs']]}
    return _VAN[repo]


def decode(bs):
    """Bytes (no $F0) -> text; $F1 -> newline."""
    return ''.join('\n' if b == NEWLINE else _DECODE.get(b, '{%02X}' % b)
                   for b in bs if b != 0xF0)


def desc_lines(bs):
    return decode(bs).split('\n')


def encode_name(s, what, lo=1, hi=NAME_MAX):
    if not isinstance(s, str):
        raise MonsterTextError(f"{what}: must be text")
    bad = sorted({c for c in s if c not in _NAME_CHARS})
    if bad:
        raise MonsterTextError(f"{what}: {s!r} — characters {''.join(bad)!r} are not in the "
                               f"game font for names (letters, digits, space and ' , . ! ? - &)")
    if not lo <= len(s) <= hi:
        raise MonsterTextError(f"{what}: {s!r} must be {lo}-{hi} characters")
    if s != s.strip():
        raise MonsterTextError(f"{what}: {s!r} starts or ends with a space")
    return bytes(_NAME_CHARS[c] for c in s)


def desc_codes(line):
    """One description line -> glyph codes (longest match: 't 's .. are one
    cell each); raises MonsterTextError for a character the font lacks."""
    out, i = [], 0
    while i < len(line):
        two = line[i:i + 2]
        if two in _DESC_MULTI:
            out.append(_DESC_MULTI[two])
            i += 2
        elif line[i] in _DESC_CHARS:
            out.append(_DESC_CHARS[line[i]])
            i += 1
        else:
            raise MonsterTextError(f"character {line[i]!r} is not in the game font "
                                   "(letters, digits, space and ' , . ; ! ? - &)")
    return out


def encode_desc(lines, what):
    if isinstance(lines, str):
        lines = lines.split('\n')
    if not isinstance(lines, list) or not 1 <= len(lines) <= DESC_LINES or \
            not all(isinstance(x, str) for x in lines):
        raise MonsterTextError(f"{what}: 1-{DESC_LINES} lines of text")
    out = []
    for k, line in enumerate(lines):
        try:
            c = desc_codes(line)
        except MonsterTextError as e:
            raise MonsterTextError(f"{what}[{k}] {line!r}: {e}")
        if len(c) > DESC_CELLS:
            raise MonsterTextError(f"{what}[{k}] {line!r}: {len(c)} cells — a line holds "
                                   f"{DESC_CELLS} (the library page cuts the rest)")
        if k:
            out.append(NEWLINE)
        out += c
    if not any(x.strip() for x in lines):
        raise MonsterTextError(f"{what}: empty")
    return bytes(out)


def _gd(prj_or_data):
    data = getattr(prj_or_data, 'data', prj_or_data) or {}
    return (data.get('gamedata') or {}).get('monster_text') or {}


def resolve(prj_or_data, repo_root=None):
    """Validate gamedata.monster_text -> {sid: {'name': bytes|None, 'nick':
    bytes|None, 'desc': bytes|None}} (only what differs from the original game
    counts as edited). Raises MonsterTextError."""
    mt = _gd(prj_or_data)
    if not isinstance(mt, dict):
        raise MonsterTextError("gamedata.monster_text: must be an object keyed by species id")
    repo = repo_root or getattr(prj_or_data, 'repo_root', None)
    van = vanilla(repo)
    out = {}
    for k, e in mt.items():
        if str(k).startswith('_'):
            continue
        what = f"gamedata.monster_text.{k}"
        try:
            sid = int(k)
        except (TypeError, ValueError):
            raise MonsterTextError(f"{what}: keys are species ids 0-214")
        if sid in PROTECTED:
            raise MonsterTextError(
                f"{what}: species {sid} is TERRY? / a summon tier / the empty slot — "
                "not a monster; only its moves and stats can change (PROJECT_STATE "
                "Iron Rule 8)")
        if sid not in IDS:
            raise MonsterTextError(f"{what}: species 0-214 (new species keep their "
                                   "name / short_name / description in custom.species)")
        if not isinstance(e, dict):
            raise MonsterTextError(f"{what}: must be an object")
        extra = set(e) - {'name', 'nickname', 'description', 'comment'}
        if extra:
            raise MonsterTextError(f"{what}: unknown field(s) {sorted(extra)} "
                                   "(name, nickname, description)")
        r = {'name': None, 'nick': None, 'desc': None}
        if 'name' in e:
            b = encode_name(e['name'], what + '.name', 1, NAME_MAX)
            r['name'] = b if b != van['names'][sid] else None
        if 'nickname' in e:
            b = encode_name(e['nickname'], what + '.nickname', 1, NICK_MAX)
            r['nick'] = b if b != van['nicks'][sid] else None
        if 'description' in e:
            b = encode_desc(e['description'], what + '.description')
            r['desc'] = b if b != van['descs'][sid] else None
        if any(r.values()):
            out[sid] = r
    return out


def name_overrides(prj_or_data, repo_root=None):
    """{sid: name bytes} of renamed originals; {} on invalid data (the
    validator reports it) — for the library-text coherence."""
    try:
        return {s: r['name'] for s, r in resolve(prj_or_data, repo_root).items() if r['name']}
    except MonsterTextError:
        return {}


def effective(prj_or_data, repo_root=None):
    """{'names': [256 bytes], 'nicks': [215], 'descs': [215]} = vanilla with
    the project's edits."""
    van = vanilla(repo_root or getattr(prj_or_data, 'repo_root', None))
    names, nicks, descs = list(van['names']), list(van['nicks']), list(van['descs'])
    for sid, r in resolve(prj_or_data, repo_root).items():
        if r['name']:
            names[sid] = r['name']
        if r['nick']:
            nicks[sid] = r['nick']
        if r['desc']:
            descs[sid] = r['desc']
    return {'names': names, 'nicks': nicks, 'descs': descs}


def name_text(prj_or_data, sid, repo_root=None):
    """The species name a player sees (project rename or the original)."""
    try:
        e = effective(prj_or_data, repo_root)
    except MonsterTextError:
        e = vanilla(repo_root or getattr(prj_or_data, 'repo_root', None))
    return decode(e['names'][sid]) if 0 <= sid < 256 else ''


# ---------------------------------------------------------------------------
# labels (= the clean disassembly's; stable whatever the text says)
# ---------------------------------------------------------------------------

def _tag(bs):
    return re.sub(r'[^A-Za-z0-9]', '', decode(bs))


def name_label(sid, repo_root=None):
    if sid in (220, 225):
        return f"MonsterName_{sid}_Unused_{sid}"
    return f"MonsterName_{sid:03d}_{_tag(vanilla(repo_root)['names'][sid])}"


def nick_label(sid, repo_root=None):
    return f"MonsterNick_{sid:03d}_{_tag(vanilla(repo_root)['nicks'][sid])}"


def desc_label(sid, repo_root=None):
    return f"MonsterDesc_{sid:03d}_{_tag(vanilla(repo_root)['names'][sid]) or 'X'}"


def ns_desc_label(sid):
    return f"NsDesc_{sid}"


# ---------------------------------------------------------------------------
# block layout
# ---------------------------------------------------------------------------

def _fill(items, size):
    """First-fit in order: -> (placed [(label, bytes)], spilled [(label, bytes)],
    used). Unedited projects place everything (the original block)."""
    placed, spilled, used = [], [], 0
    for label, b in items:
        if used + len(b) <= size:
            placed.append((label, b))
            used += len(b)
        else:
            spilled.append((label, b))
    return placed, spilled, used


def layout(prj_or_data, repo_root=None):
    """-> {'names': (placed, spilled, used), 'nicks': (...), 'descs': (...)}
    with every string $F0-terminated."""
    repo = repo_root or getattr(prj_or_data, 'repo_root', None)
    e = effective(prj_or_data, repo)
    names = [(name_label(s, repo), e['names'][s] + b'\xf0') for s in NAME_ORDER]
    nicks = [(nick_label(s, repo), e['nicks'][s] + b'\xf0') for s in IDS]
    descs = [(desc_label(s, repo), e['descs'][s] + b'\xf0') for s in IDS]
    return {'names': _fill(names, NAME_BLOCK[1] - NAME_BLOCK[0]),
            'nicks': _fill(nicks, NICK_BLOCK[1] - NICK_BLOCK[0]),
            'descs': _fill(descs, DESC_BLOCK[1] - DESC_BLOCK[0])}


def bank41_spills(prj_or_data, repo_root=None):
    """Name / nickname strings that must go to the shared bank-$41 extents."""
    lay = layout(prj_or_data, repo_root)
    return lay['names'][1] + lay['nicks'][1]


def usage(prj_or_data, repo_root=None):
    """Byte meters for the editor: {'names': (used incl. spill, block size),
    'nicks': ..., 'descs': ...}."""
    lay = layout(prj_or_data, repo_root)
    blocks = {'names': NAME_BLOCK, 'nicks': NICK_BLOCK, 'descs': DESC_BLOCK}
    return {k: (lay[k][2] + sum(len(b) for _l, b in lay[k][1]), v[1] - v[0])
            for k, v in blocks.items()}


# ---------------------------------------------------------------------------
# emitters
# ---------------------------------------------------------------------------

def _db(bs):
    return "    db " + ", ".join(f"${b:02X}" for b in bs)


def _block(placed, used, size, head, comment):
    out = list(head)
    for label, b in placed:
        out.append(f"{label}:  ; \"{comment(b)}\"")
        out.append(_db(b))
    if used < size:
        out.append(f"    ds {size - used}, $00   ; unused ({size - used} B)")
    return "\n".join(out) + "\n"


def emit_names(prj, warnings):
    placed, spilled, used = layout(prj)['names']
    head = ["MonsterNameStrings:"]
    if spilled:
        head.append(f"; ({len(spilled)} name(s) placed in the ns_text_* extents: "
                    + ", ".join(l for l, _b in spilled) + ")")
    return _block(placed, used, NAME_BLOCK[1] - NAME_BLOCK[0], head,
                  lambda b: decode(b))


def emit_nicks(prj, warnings):
    placed, spilled, used = layout(prj)['nicks']
    head = ["MonsterNickStrings:"]
    if spilled:
        head.append(f"; ({len(spilled)} nickname(s) placed in the ns_text_* extents: "
                    + ", ".join(l for l, _b in spilled) + ")")
    return _block(placed, used, NICK_BLOCK[1] - NICK_BLOCK[0], head,
                  lambda b: decode(b))


def emit_descs(prj, warnings):
    placed, spilled, used = layout(prj)['descs']
    head = []
    if spilled:
        head.append(f"; ({len(spilled)} description(s) placed in gd_monster_desc_extra)")
    return _block(placed, used, DESC_BLOCK[1] - DESC_BLOCK[0], head,
                  lambda b: decode(b).replace('\n', '/'))


def desc_extra_items(prj):
    """[(label, bytes)] for gd_monster_desc_extra: spilled original
    descriptions, then the new species' own descriptions (id order)."""
    from . import species as SP
    items = list(layout(prj)['descs'][1])
    for s in SP.resolve(prj, with_art=False):
        if s.get('desc_b') is not None:
            items.append((ns_desc_label(s['id']), s['desc_b'] + b'\xf0'))
    return items


def emit_desc_extra(prj, warnings):
    items = desc_extra_items(prj)
    if not items:
        return "; (none)\n"
    out = []
    for label, b in items:
        out.append(f"{label}:  ; \"{decode(b).replace(chr(10), '/')}\"")
        out.append(_db(b))
    return "\n".join(out) + "\n"


# Room for gd_monster_desc_extra: bank $4D from the end of ns_detail_text to
# $8000. ns_detail_text starts at HighLine2Ptrs (fixed: the HighDetailTextFork
# code before it never moves) and is 2 x 19 words + 19 B per recipe line.
HIGH_LINE2_PTRS = 0x773E          # patched game.sym (test_compiler --rom checks it)


def desc_extra_room(prj):
    from . import species as SP
    lines = sum(1 for s in SP.resolve(prj, with_art=False) if SP.recipe(prj, s['id']))
    return 0x8000 - (HIGH_LINE2_PTRS + 4 * SP.N_IDS + 19 * lines)


def check(prj):
    """Validator: everything resolves and fits. Raises MonsterTextError."""
    resolve(prj)
    room = desc_extra_room(prj)
    need = sum(len(b) for _l, b in desc_extra_items(prj))
    if need > room:
        raise MonsterTextError(
            f"descriptions: {need} B do not fit — the description block is full and the "
            f"end of bank $4D has {room} B left; shorten some descriptions")


REGIONS = [('gd_monster_names', 'patches/bank_041.asm', emit_names, 0x41),
           ('gd_monster_nicks', 'patches/bank_041.asm', emit_nicks, 0x41),
           ('gd_monster_desc', 'patches/bank_04d.asm', emit_descs, 0x4D),
           ('gd_monster_desc_extra', 'patches/bank_04d.asm', emit_desc_extra, 0x4D)]
