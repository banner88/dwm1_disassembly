"""custom_skills.py — the CUSTOM skills as project data (ROADMAP P3.11c + P3.11d,
S111; PROJECT_COMPILER §2.27; BATTLE_SKILL_SYSTEM §13-§14, §15.3).

Custom skill ids are $DE-$FE (222-254; $FF = "no skill" in every skill list):

  222-223  $DE/$DF   the retired S45 POCs (Scorch / Smite) — not editable
  224-233  $E0-$E9   the BUILT-IN custom skills: MagicBurn, Tame, TameMore,
                     TameMost, Anchor, Tremor, Quake, QuakeMore, QuakeMost,
                     Mourn. Their effect is bespoke code in bank $72 (mechanism);
                     every DATA byte is here: name, SKIL text, MP (both
                     copies), learn row, the 19-byte record, the battle
                     announce line, the look (proxy) and the sounds, the
                     element, Tame's meter per tier, Quake's power per tier,
                     the Quake / Mourn extra lines, Anchor's four dialogs.
                     Their built-in values = editor2/core/custom_skills.json
                     (read from the S110 pin by tools/extract_custom_skills.py).
  234-254  $EA-$FE   NEW custom skills a project adds (P3.11d): each runs the
                     effect code of a STOCK skill (`base`) with its own record
                     (power, targets, MP, AI fields), name, text, learn row,
                     announce, look, sounds and element. The working id stays
                     the new one, so every id-keyed table reads its own row.

Schema (sparse, in gamedata.skills — the same object the vanilla skills use):

  "skills": {
    "230": {"name": "Rumble", "mp": 12, "quake_power": {"min": 80, "max": 120},
            "element": "Explosion", "announce": ["{name} shakes", "the ground!"]},
    "234": {"base": 0, "name": "Spark", "description": ["A small spark"],
            "mp": 2, "record": {"party_min": 20, "party_range": 5},
            "looks_like": 16, "sounds_like": 16, "element": "Lightning",
            "learn": {"level": 5}, "announce_as": 35}}

Keys (all optional except `base` + `name` for a new skill):
  name, description          as for vanilla skills (skills.py encoders)
  mp                          0-255: CustomMPCostTable (field menu) + record +4
  learn                       {level, hp..int, prereqs}; null = not learnable
  record                      the 19-byte record fields (gamedata.RECORD_FIELDS);
                              built-in skills: their handlers own the damage and
                              targets, so the power words and target_mode are
                              refused there
  looks_like / sounds_like    a stock skill (0-221) whose animation + flash /
                              sounds the skill borrows
  element                     a resistance name / index 0-26, or "none"
  announce                    the battle line: 1-2 lines (or a list of pages of
                              1-2 lines); {name} = the caster, {skill} = this
                              skill's name; announce_as = a stock battle message
                              id instead ($23 "casts {skill}!", ...) or "none"
  tame_meter                  225-227: the meter increment (FeedMeat 10 ...)
  quake_power                 229-232: {"min", "max"} — both sides, allies 1/3
  allies_line / flew_line     229 (shared by the four Quake tiers)
  boost_line                  233 (Mourn's "Fallen allies / lend power!")
  dialogs                     228: {"gate_ask", "return_ask", "err_special",
                              "err_none"} = lines of Anchor's dialogs
  burn / damage_per_mp        224: MagicBurn's share of the current MP spent
                              ("1/2") and damage per MP spent ("1/1")
  damage_of_atk               225-227: Tame's damage as a share of ATK ("1/4")
  mp_charge                   228: Anchor's share of the current MP charged on
                              arrival ("3/4")
  ally_damage                 229-232: the allies' share of Quake's damage ("1/3")
  per_fallen                  233: Mourn's bonus per fallen ally, x the base
                              damage ("1/1")
                              (the RATIOS: "n/d", [n, d] or an integer; n 0-255,
                              d 1-255; bank $72 CustomRatioTable; results <= 999)
  base                        234-254 only: the stock skill whose effect runs

No edits = the built-in data (the S110 behaviour, plus the S111 fixes: custom
skills' sounds read CustomSfxTable instead of past the stock tables).
"""

import json
import os
import re

from . import monster_text as MT

FIRST, LAST = 0xDE, 0xFE              # custom ids (222-254)
N = LAST - FIRST + 1                  # 33
RETIRED = (0xDE, 0xDF)
BUILTIN = range(0xE0, 0xEA)           # 224-233
NEW = range(0xEA, 0xFF)               # 234-254
LEARN_FIRST = 0xE0                    # CustomLearnTable starts here (31 rows)
LEARN_ROWS = LAST - LEARN_FIRST + 1   # 31
ANNOUNCE_SPLIT = 0xE2                 # $DE-$E1 in AnnounceTemplateTable, $E2+ CustomAnnounceTable
STOCK = 222
NAME_REGION = 0x7FF6 - 0x7F98         # bank $41 gd_custom_skill_names (94 B)
DESC_REGION = 0x8000 - 0x7E42         # bank $56 gd_custom_skill_desc (446 B)
MSG_A = 56                            # bank $4C gd_custom_msg_a ($7326)
MSG_POOL = 0x7A9D - (0x741C + 2 * N)  # bank $4C gd_custom_msgs (to $7A9D)
NO_ELEMENT, ELEMENT_NONE = 0xFF, 0xFE
FIELD_ONLY = (0x37, 0x38)           # StepGuard, MapMagic (bank $50 FieldOnlySkillA)
TARGET_ROW_FOR_MODE = {0x11: 0x00, 0x12: 0x03, 0x21: 0x2B, 0x22: 0x2D, 0x41: 0x41}
HANDLER_LABEL = {'magicburn': 'MagicBurn (a share of the MP as damage to all foes)',
                 'tame': 'Tame (meat-meter recruit + a share of ATK as damage)',
                 'anchor': 'Anchor (field: warp to GreatTree and back)',
                 'quake': 'Quake (all foes, then a share to allies, not flyers)',
                 'mourn': 'Mourn (ATK-vs-DEF + a bonus per fallen ally)'}
DAMAGE_HANDLERS = ('magicburn', 'tame', 'quake', 'mourn')
KEYS_COMMON = ('name', 'description', 'mp', 'learn', 'record', 'looks_like',
               'sounds_like', 'element', 'announce', 'announce_as', 'presentation', 'comment')
LINE_KEYS = {'allies_line': (0xE5, 'quake_allies', False),   # (owner id, banner, $ED prefix)
             'flew_line': (0xE5, 'quake_flew', True),
             'boost_line': (0xE9, 'mourn_boost', False)}
# [S111] the built-ins' fixed ratios as data (bank $72 CustomRatioTable, region
# gd_custom_ratios): key -> (owner ids, table offset of the first owner, default,
# largest value allowed, what it is). Per-tier keys sit 2 bytes apart.
RATIO_KEYS = {
    'burn': ((0xE0,), 0, (1, 2), 1, "share of the current MP spent"),
    'damage_per_mp': ((0xE0,), 2, (1, 1), 4, "damage per MP spent"),
    'damage_of_atk': ((0xE1, 0xE2, 0xE3), 4, (1, 4), 4, "damage as a share of ATK"),
    'mp_charge': ((0xE4,), 10, (3, 4), 1, "share of the current MP charged on arrival"),
    'ally_damage': ((0xE5, 0xE6, 0xE7, 0xE8), 12, (1, 3), 2, "allies' share of the damage"),
    'per_fallen': ((0xE9,), 20, (1, 1), 4, "bonus per fallen ally, x the base damage"),
}
RATIO_TABLE = 22


def ratio_slots():
    """[(offset, key, sid)] in table order."""
    out = []
    for key, (owners, off, _d, _m, _w) in RATIO_KEYS.items():
        for k, sid in enumerate(owners):
            out.append((off + 2 * k, key, sid))
    return sorted(out)


def ratio_value(v, what, most):
    """'n/d' | [n, d] | int -> (n, d)."""
    if isinstance(v, bool):
        raise CustomSkillError(f"{what}: a fraction like \"1/3\"")
    if isinstance(v, int):
        n, d = v, 1
    elif isinstance(v, str) and re.fullmatch(r'\s*\d+\s*(/\s*\d+\s*)?', v):
        a = [int(x) for x in v.split('/')]
        n, d = (a[0], a[1]) if len(a) == 2 else (a[0], 1)
    elif isinstance(v, (list, tuple)) and len(v) == 2 and all(
            isinstance(x, int) and not isinstance(x, bool) for x in v):
        n, d = v
    else:
        raise CustomSkillError(f"{what}: a fraction like \"1/3\" (or [1, 3], or a whole number)")
    if not (0 <= n <= 255 and 1 <= d <= 255):
        raise CustomSkillError(f"{what} {n}/{d}: numerator 0-255, denominator 1-255")
    if n > most * d:
        raise CustomSkillError(f"{what} {n}/{d}: at most {most}" + (" (all of it)" if most == 1 else ""))
    return n, d


def ratio_text(nd):
    n, d = nd
    return f"{n}" if d == 1 else f"{n}/{d}"


DIALOG_IDS = {'gate_ask': 'skill:anchor_gate_ask', 'return_ask': 'skill:anchor_return_ask',
              'err_special': 'skill:anchor_err_special', 'err_none': 'skill:anchor_err_none'}

BASE_JSON = os.path.join(os.path.dirname(__file__), 'custom_skills.json')


class CustomSkillError(ValueError):
    pass


def _repo():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


_BASE = {}


def baseline():
    """The built-in data (editor2/core/custom_skills.json), ids as ints."""
    if 'b' not in _BASE:
        d = json.load(open(BASE_JSON))
        sk = {int(k): v for k, v in d['skills'].items()}
        _BASE['b'] = {'skills': sk, 'banners': d['banners'],
                      'tame_meter': {int(k): v for k, v in d['tame_meter'].items()},
                      'quake_power': {int(k): v for k, v in d['quake_power'].items()}}
    return _BASE['b']


_VAN = {}


def _vanilla(repo):
    repo = repo or _repo()
    if repo not in _VAN:
        v = json.load(open(os.path.join(repo, 'extracted', 'gamedata_vanilla.json')))
        t = v['tables']
        recs = [bytes.fromhex(r) for r in t['skill_records']['rows']]
        mp = [int.from_bytes(bytes.fromhex(r), 'little') for r in t['skill_mp']['rows']]
        ann = [bytes.fromhex(r)[0] for r in t['skill_announce']['rows']]
        names = [bytes.fromhex(h) for h in v['skill_text']['names']]
        _VAN[repo] = {'records': recs, 'mp': mp, 'announce': ann, 'names': names}
    return _VAN[repo]


def element_census(repo=None):
    """{stock id: [(ladder, element)]} from extracted/skill_element_census.json
    (tools/census_skill_element.py, measured S111) — which stock skills' damage
    tests a resistance, through which ladder; {} when absent."""
    try:
        d = json.load(open(os.path.join(repo or _repo(), 'extracted',
                                        'skill_element_census.json')))
    except (OSError, ValueError):
        return {}
    return {int(k): [(x['ladder'], x['element']) for x in v.get('ladders', [])]
            for k, v in d.get('results', {}).items()}


def native_element(sid, repo=None):
    """The element a stock skill's damage tests (None = none)."""
    c = element_census(repo).get(sid) or []
    return c[0][1] if c else None


# ---------------------------------------------------------------------------
# battle-text lines (announce / extra lines)
# ---------------------------------------------------------------------------

LINE_CELLS = 18
TOKENS = {'{name}': bytes([0xF9, 0x00]), '{user}': bytes([0xF9, 0x00]),
          '{target}': bytes([0xF9, 0x00]), '{skill}': bytes([0xF9, 0x10])}
TOKEN_CELLS = 9
PAGE = bytes([0xFC, 0x10, 0xEC, 0xF2])
END = bytes([0xEC, 0xF0])


def _pages(v, what):
    if isinstance(v, str):
        v = [v]
    if not isinstance(v, list) or not v:
        raise CustomSkillError(f"{what}: 1-2 lines of text (or a list of pages)")
    if all(isinstance(x, str) for x in v):
        v = [v]
    if not all(isinstance(p, list) and 1 <= len(p) <= 2 and all(isinstance(x, str) for x in p)
               for p in v) or len(v) > 3:
        raise CustomSkillError(f"{what}: 1-3 pages of 1-2 lines")
    return v


def encode_line(v, what, ed, allow_skill=True):
    """Battle text -> bytes ($F0-terminated) + warnings. `ed` = start with $ED
    (the shape the original line had)."""
    warns = []
    out = bytearray([0xED] if ed else [])
    for pi, page in enumerate(_pages(v, what)):
        if pi:
            out += PAGE
        for li, line in enumerate(page):
            if li:
                out.append(0xF1)
            cells, i, fixed = 0, 0, 0
            while i < len(line):
                tok = next((t for t in TOKENS if line.startswith(t, i)), None)
                if tok:
                    if tok == '{skill}' and not allow_skill:
                        raise CustomSkillError(f"{what}: {{skill}} works in the announce "
                                               "line only")
                    out += TOKENS[tok]
                    cells += TOKEN_CELLS
                    i += len(tok)
                    continue
                two = line[i:i + 2]
                try:
                    if two in ("'t", "'s", '..'):
                        out += bytes(MT.desc_codes(two)); i += 2
                    else:
                        out += bytes(MT.desc_codes(line[i])); i += 1
                except MT.MonsterTextError as e:
                    raise CustomSkillError(f"{what} {line!r}: {e}")
                cells += 1
                fixed += 1
            if fixed > LINE_CELLS:
                raise CustomSkillError(f"{what} {line!r}: {fixed} cells — a battle line holds "
                                       f"{LINE_CELLS}")
            if cells > LINE_CELLS:
                warns.append(f"{what} {line!r}: with a long name the line may pass "
                             f"{LINE_CELLS} cells and wrap on its own")
    out += END
    return bytes(out), warns


_DEC = {v: k for k, v in MT._DESC_CHARS.items()}
_DEC.update({v: k for k, v in MT._DESC_MULTI.items()})


def decode_line(bs):
    """Battle-text bytes -> a list of pages of lines (best effort; shows the
    built-in lines in the editor)."""
    pages, lines, cur = [], [], ''
    i = 0
    bs = bytes(bs)
    while i < len(bs):
        b = bs[i]
        if b == 0xED:
            i += 1
        elif b == 0xF9 and i + 1 < len(bs):
            cur += '{skill}' if bs[i + 1] == 0x10 else '{name}'
            i += 2
        elif bs[i:i + 4] == PAGE:
            lines.append(cur); pages.append(lines); lines, cur = [], ''
            i += 4
        elif b == 0xF1:
            lines.append(cur); cur = ''
            i += 1
        elif b in (0xEC, 0xF0):
            i += 1
        else:
            cur += _DEC.get(b, '{%02X}' % b)
            i += 1
    lines.append(cur)
    pages.append(lines)
    return pages if len(pages) > 1 else pages[0]


# ---------------------------------------------------------------------------
# resolve
# ---------------------------------------------------------------------------

def _int(v, what, lo=0, hi=255):
    try:
        if isinstance(v, bool):
            raise ValueError
        if isinstance(v, str):
            s = v.strip()
            x = int(s[1:], 16) if s.startswith('$') else int(s, 0)
        else:
            x = int(v)
    except (TypeError, ValueError):
        raise CustomSkillError(f"{what}: {v!r} is not a number")
    if not lo <= x <= hi:
        raise CustomSkillError(f"{what} = {x} outside {lo}-{hi}")
    return x


def _gd(prj_or_data):
    data = getattr(prj_or_data, 'data', prj_or_data) or {}
    return (data.get('gamedata') or {}).get('skills') or {}


def element_value(v, what):
    """'Fire' / 0-26 / 'none' -> 0-26 / ELEMENT_NONE."""
    from . import gamedata as G
    if v is None:
        return NO_ELEMENT
    if isinstance(v, str) and v.strip().lower() in ('none', 'no element'):
        return ELEMENT_NONE
    if isinstance(v, str) and not v.strip()[:1].isdigit() and not v.strip().startswith('$'):
        low = {n.lower(): i for i, n in enumerate(G.RESIST_NAMES)}
        if v.strip().lower() not in low:
            raise CustomSkillError(f"{what}: unknown resistance {v!r} "
                                   f"({', '.join(G.RESIST_NAMES)}, or none)")
        return low[v.strip().lower()]
    return _int(v, what, 0, 26)


def _record_from(rec, R, what):
    from . import gamedata as G
    r = bytearray(rec)
    if not isinstance(R, dict):
        raise CustomSkillError(f"{what}: must be an object")
    names = [n for n, _o, _s in G.RECORD_FIELDS]
    bad = [k for k in R if k not in names and not str(k).startswith('_')]
    if bad:
        raise CustomSkillError(f"{what}: unknown field(s) {bad}")
    for n, off, size in G.RECORD_FIELDS:
        if n in R:
            v = _int(R[n], f"{what}.{n}", 0, 0xFF if size == 1 else 0xFFFF)
            if size == 1:
                r[off] = v
            else:
                r[off] = v & 0xFF
                r[off + 1] = v >> 8
    return r


def _learn_from(row, L, what, valid_ids):
    from . import gamedata as G
    if L is None:
        return bytearray([0xFF] + [0] * 12 + [0xFF] * 5)
    if not isinstance(L, dict):
        raise CustomSkillError(f"{what}: an object (level, hp ... int, prereqs) or null")
    bad = [k for k in L if k not in ('level',) + G.STATS + ('prereqs',) and not str(k).startswith('_')]
    if bad:
        raise CustomSkillError(f"{what}: unknown key(s) {bad}")
    r = bytearray(row) if row else bytearray([0] * 13 + [0xFF] * 5)
    if r[0] == 0xFF:
        r[0] = 1
    if 'level' in L:
        r[0] = _int(L['level'], what + '.level', 1, 99)
    for i, s in enumerate(G.STATS):
        if s in L:
            v = _int(L[s], f"{what}.{s}", 0, 0xFFFF)
            r[1 + 2 * i] = v & 0xFF
            r[2 + 2 * i] = v >> 8
    if 'prereqs' in L:
        p = L['prereqs']
        if not isinstance(p, list) or len(p) > 5:
            raise CustomSkillError(f"{what}.prereqs: up to 5 skill ids")
        ids = [_int(x, f"{what}.prereqs", 0, 254) for x in p]
        for x in ids:
            if x not in valid_ids:
                raise CustomSkillError(f"{what}.prereqs: {x} is not a skill this project has")
        r[13:18] = bytes(ids + [0xFF] * (5 - len(ids)))
    return r


def resolve(prj_or_data, repo_root=None):
    """-> (skills, extras, warnings). skills = {id: effective dict} for every
    custom id that exists (built-in + the project's new ones); extras = the
    shared tables (tame_meter, quake_power, banners bytes, dialogs). Raises
    CustomSkillError."""
    from . import gamedata as G
    repo = repo_root or getattr(prj_or_data, 'repo_root', None) or _repo()
    B = baseline()
    van = _vanilla(repo)
    sk = _gd(prj_or_data)
    warns = []
    edits = {}
    for k, e in (sk or {}).items():
        if str(k).startswith('_'):
            continue
        try:
            sid = int(k)
        except ValueError:
            continue
        if sid < STOCK:
            continue
        what = f"gamedata.skills.{sid}"
        if not FIRST <= sid <= LAST:
            raise CustomSkillError(f"{what}: custom skill ids are 222-254 ($FF = no skill)")
        if sid in RETIRED:
            raise CustomSkillError(f"{what}: ids 222-223 are the retired S45 test skills "
                                   "(Scorch / Smite) — use 234-254 for a new skill")
        if not isinstance(e, dict):
            raise CustomSkillError(f"{what}: must be an object")
        edits[sid] = e
    valid_ids = set(range(STOCK)) | set(BUILTIN) | {s for s in edits if s in NEW}
    out = {}
    for sid in list(BUILTIN) + sorted(s for s in edits if s in NEW):
        e = edits.get(sid, {})
        what = f"gamedata.skills.{sid}"
        b = B['skills'].get(sid)
        if sid in BUILTIN:
            handler = b['handler']
            allowed = KEYS_COMMON + tuple(k for k, (o, _b, _e) in LINE_KEYS.items() if o == sid)
            allowed += {'tame': ('tame_meter',), 'quake': ('quake_power',),
                        'anchor': ('dialogs',)}.get(handler, ())
            allowed += tuple(k for k, r in RATIO_KEYS.items() if sid in r[0])
            if 'base' in e:
                raise CustomSkillError(f"{what}.base: the built-in custom skills run their "
                                       "own code; `base` is for new skills (234-254)")
            base = None
            name = MT.encode_name(b['name'], what) if b['name'] else b''
            desc = MT.encode_desc(b['description'], what) if b['description'] else None
            mp = b['mp']
            rec = bytearray.fromhex(b['record'])
            learn = bytearray.fromhex(b['learn']) if b['learn'] else None
            tpl = b['announce_template']
            msg = bytes.fromhex(b['message']) if b['message'] else None
            proxy = b['proxy']
            sfx = 0x09
            element = NO_ELEMENT
        else:
            allowed = KEYS_COMMON + ('base',)
            if 'base' not in e:
                raise CustomSkillError(f"{what}: a new custom skill needs `base` — the stock "
                                       "skill (0-221) whose effect it runs")
            base = _int(e['base'], what + '.base', 0, STOCK - 1)
            from . import skills as SK
            if SK.kind(base, repo) != 'skill':
                raise CustomSkillError(f"{what}.base {base}: "
                                       f"{SK.vanilla_name(base, repo)} is not a skill "
                                       "(battle action / item) — pick a stock skill")
            prob = clone_problem(base, repo)
            if prob:
                raise CustomSkillError(f"{what}.base {base}: {prob}")
            handler = 'clone'
            if 'name' not in e:
                raise CustomSkillError(f"{what}: a new custom skill needs a name")
            name = b''
            desc = None
            mp = van['mp'][base] if van['mp'][base] <= 255 else 0
            rec = bytearray(van['records'][base])
            learn = None
            tpl = van['announce'][base]
            msg = None
            proxy = base
            sfx = base
            element = NO_ELEMENT
        bad = [k for k in e if k not in allowed and not str(k).startswith('_')]
        if bad:
            raise CustomSkillError(f"{what}: unknown key(s) {bad} for "
                                   f"{'this built-in skill' if sid in BUILTIN else 'a new skill'} "
                                   f"(allowed: {', '.join(a for a in allowed if a != 'comment')})")
        if 'name' in e:
            try:
                name = MT.encode_name(e['name'], what + '.name', 1, 9)
            except MT.MonsterTextError as x:
                raise CustomSkillError(str(x))
        if 'description' in e:
            d = e['description']
            if d in (None, '', []):
                desc = None
            else:
                try:
                    desc = MT.encode_desc(d, what + '.description')
                except MT.MonsterTextError as x:
                    raise CustomSkillError(str(x).replace('library page', 'SKIL box'))
        if 'record' in e:
            R = e['record']
            if sid in BUILTIN and isinstance(R, dict):
                if any(k in R for k in ('party_min', 'party_range', 'enemy_min', 'enemy_range')):
                    raise CustomSkillError(
                        f"{what}.record: the power fields are not used — "
                        f"{HANDLER_LABEL[handler].split(' (')[0]}'s code sets the damage"
                        + (" (quake_power holds Quake's numbers)" if handler == 'quake' else "")
                        + "; S74: nonzero power words looped the presentation")
                if 'target_mode' in R and _int(R['target_mode'], what) != rec[2]:
                    raise CustomSkillError(f"{what}.record.target_mode: this skill's code is "
                                           "written for its own targets")
            rec = _record_from(rec, R, what + '.record')
            if sid in NEW and rec[2] not in G.TARGET_MODES_OK:
                raise CustomSkillError(f"{what}.record.target_mode ${rec[2]:02X}: one of $11 one "
                                       "foe, $12 all foes, $21 one ally, $22 all allies, $41 the user")
        if 'mp' in e:
            if handler in ('magicburn', 'anchor'):
                raise CustomSkillError(
                    f"{what}.mp: " + ("MagicBurn spends a share of its current MP — set `burn`"
                                      if handler == 'magicburn' else
                                      "Anchor charges a share of the current MP on arrival — "
                                      "set `mp_charge`"))
            mp = _int(e['mp'], what + '.mp', 0, 255)
            if not (isinstance(e.get('record'), dict) and 'mp_byte' in e['record']):
                rec[4] = mp
        if 'learn' in e:
            learn = _learn_from(learn, e['learn'], what + '.learn', valid_ids)
        if 'looks_like' in e:
            proxy = _int(e['looks_like'], what + '.looks_like', 0, STOCK - 1)
            if 'sounds_like' not in e and sid in NEW:
                sfx = proxy
        if 'sounds_like' in e:
            sfx = _int(e['sounds_like'], what + '.sounds_like', 0, STOCK - 1)
        if 'element' in e:
            element = element_value(e['element'], what + '.element')
            if sid in BUILTIN and handler not in DAMAGE_HANDLERS:
                raise CustomSkillError(f"{what}.element: {b['name']} deals no damage")
            if sid in NEW and native_element(base, repo) is None and element != NO_ELEMENT:
                from . import skills as SK
                raise CustomSkillError(
                    f"{what}.element: the effect of {SK.vanilla_name(base, repo)} (its base) "
                    "does not test a resistance — pick an elemental base")
            if not (isinstance(e.get('record'), dict) and 'status_id' in e['record']):
                rec[5] = 0 if element in (ELEMENT_NONE, NO_ELEMENT) else element + 1
                if element == NO_ELEMENT and sid in NEW:
                    ne = native_element(base, repo)
                    rec[5] = van['records'][base][5] if ne is None else ne + 1
        if 'announce' in e and 'announce_as' in e:
            raise CustomSkillError(f"{what}: announce (own line) OR announce_as (a stock "
                                   "battle message), not both")
        if 'announce' in e:
            if e['announce'] in (None, [], ''):
                tpl, msg = 0xFF, None
            else:
                msg, w = encode_line(e['announce'], what + '.announce', True)
                warns += w
                tpl = 0xFD
        if 'announce_as' in e:
            a = e['announce_as']
            if a is None or (isinstance(a, str) and a.strip().lower() == 'none'):
                tpl = 0xFF
            else:
                tpl = _int(a, what + '.announce_as', 0, 0xFC)
            msg = None
        if tpl == 0xFD and msg is None:
            raise CustomSkillError(f"{what}: announce_as $FD is this skill's own line — "
                                   "write it in `announce`")
        if mp > 255:
            raise CustomSkillError(f"{what}.mp = {mp}: 0-255")
        target_row = None
        if sid in NEW:
            target_row = base if rec[2] == van['records'][base][2] else \
                TARGET_ROW_FOR_MODE.get(rec[2], base)
        out[sid] = {'id': sid, 'handler': handler, 'base': base, 'name': name, 'desc': desc,
                    'mp': mp, 'record': bytes(rec), 'learn': bytes(learn) if learn else None,
                    'template': tpl, 'message': msg, 'proxy': proxy, 'sfx': sfx,
                    'element': element, 'target_row': target_row,
                    'edited': bool(e)}
    # shared per-handler data
    tame = dict(B['tame_meter'])
    quake = {k: list(v) for k, v in B['quake_power'].items()}
    banners = {k: bytes.fromhex(v) for k, v in B['banners'].items()}
    dialogs = {}
    ratios = {}
    for off, key, sid in ratio_slots():
        ratios[off] = RATIO_KEYS[key][2]
    for sid, e in edits.items():
        what = f"gamedata.skills.{sid}"
        for key, (owners, off, _d, most, _w) in RATIO_KEYS.items():
            if key in e and sid in owners:
                if e[key] is not None:
                    ratios[off + 2 * owners.index(sid)] = ratio_value(e[key], f"{what}.{key}", most)
        if 'tame_meter' in e:
            tame[sid] = _int(e['tame_meter'], what + '.tame_meter', 0, 1600)
        if 'quake_power' in e:
            q = e['quake_power']
            if not isinstance(q, dict) or set(q) - {'min', 'max'} or 'min' not in q or 'max' not in q:
                raise CustomSkillError(f"{what}.quake_power: {{\"min\": ..., \"max\": ...}}")
            lo = _int(q['min'], what + '.quake_power.min', 0, 255)
            hi = _int(q['max'], what + '.quake_power.max', 0, 510)
            if hi < lo or hi - lo > 255:
                raise CustomSkillError(f"{what}.quake_power: max {hi} must be min..min+255")
            quake[sid] = [lo, hi - lo]
        for key, (owner, banner, ed) in LINE_KEYS.items():
            if key in e:
                if not e[key]:
                    raise CustomSkillError(f"{what}.{key}: the line cannot be empty")
                bs, w = encode_line(e[key], f"{what}.{key}", ed, allow_skill=False)
                banners[banner] = bs
                warns += w
        if 'dialogs' in e:
            D = e['dialogs']
            if not isinstance(D, dict) or set(D) - set(DIALOG_IDS):
                raise CustomSkillError(f"{what}.dialogs: keys {', '.join(DIALOG_IDS)}")
            for k, lines in D.items():
                if not isinstance(lines, list) or not 1 <= len(lines) <= 3 or \
                        not all(isinstance(x, str) and len(x) <= 18 for x in lines):
                    raise CustomSkillError(f"{what}.dialogs.{k}: 1-3 lines of up to 18 "
                                           "characters (the dialog box)")
                dialogs[DIALOG_IDS[k]] = list(lines)
    return out, {'tame': tame, 'quake': quake, 'banners': banners, 'dialogs': dialogs,
                 'ratios': ratios}, warns


# ---------------------------------------------------------------------------
# which stock skills a new skill may run (P3.11d, MEASURED)
# ---------------------------------------------------------------------------

def _clone_census(repo):
    try:
        d = json.load(open(os.path.join(repo or _repo(), 'extracted',
                                        'skill_clone_census.json')))
        return {int(k): v for k, v in d.get('results', {}).items()}
    except (OSError, ValueError):
        return {}


def clone_problem(base, repo=None):
    """Why a new custom skill cannot run `base`'s effect (None = it can):
    tools/census_skill_clone.py measured the clone against the stock skill."""
    if base in FIELD_ONLY:
        return "a field skill: a copy could not be used outside battle (the field menu " \
               "knows the stock ids only) and does nothing in battle"
    c = _clone_census(repo).get(base)
    if c is None:
        return "not measured as a base yet (extracted/skill_clone_census.json)"
    if c.get('result') != 'same':
        return f"a copy does not behave like the original (measured: {c.get('why', c.get('result'))})"
    return None


def clone_bases(repo=None):
    """[(id, note)] — the stock skills a new skill may be based on."""
    return sorted((k, v.get('note', '')) for k, v in _clone_census(repo).items()
                  if v.get('result') == 'same' and k not in FIELD_ONLY)


# ---------------------------------------------------------------------------
# effective values for the editor / other modules
# ---------------------------------------------------------------------------

def names(prj_or_data, repo_root=None):
    """{id: displayed name} for every custom skill that exists."""
    try:
        sk, _x, _w = resolve(prj_or_data, repo_root)
    except CustomSkillError:
        b = baseline()['skills']
        return {i: b[i]['name'] for i in BUILTIN}
    return {i: MT.decode(v['name']) for i, v in sk.items()}


def exists(prj_or_data, sid, repo_root=None):
    return sid in names(prj_or_data, repo_root)


def dialog_overrides(prj_or_data, repo_root=None):
    try:
        return resolve(prj_or_data, repo_root)[1]['dialogs']
    except CustomSkillError:
        return {}


# ---------------------------------------------------------------------------
# layout
# ---------------------------------------------------------------------------

def _tag(bs):
    return re.sub(r'[^A-Za-z0-9]', '', MT.decode(bs)) or 'X'


def name_label(sid, name):
    return f"SkillName_{sid}_{_tag(name)}"


def desc_label(sid):
    return f"SkillDescC_{sid}"


def msg_label(sid):
    return f"CustomMsgLine_{sid}"


def _fill(items, size):
    placed, spilled, used = [], [], 0
    for label, b in items:
        if used + len(b) <= size:
            placed.append((label, b)); used += len(b)
        else:
            spilled.append((label, b))
    return placed, spilled, used


def layout(prj_or_data, repo_root=None):
    sk, ex, _w = resolve(prj_or_data, repo_root)
    nm = [(name_label(s, v['name']), v['name'] + b'\xf0') for s, v in sorted(sk.items())]
    ds = [(desc_label(s), v['desc'] + b'\xf0') for s, v in sorted(sk.items()) if v['desc']]
    # battle lines: MagicBurn's first (it owned $7326), identical lines shared
    lines, owner = [], {}
    order = sorted(sk, key=lambda s: (s != 0xE0, s))
    for s in order:
        m = sk[s]['message']
        if m is None:
            continue
        if m in owner:
            continue
        owner[m] = msg_label(s)
        lines.append((msg_label(s), m))
    for lab, key in (('CustomMsg_QuakeAllies', 'quake_allies'), ('CustomMsg_QuakeFlew', 'quake_flew'),
                     ('CustomMsg_MournBoost', 'mourn_boost')):
        lines.append((lab, ex['banners'][key]))
    a_placed, rest, a_used = _fill(lines, MSG_A)
    return {'names': _fill(nm, NAME_REGION), 'descs': _fill(ds, DESC_REGION),
            'msg_a': (a_placed, a_used), 'msg_pool': rest, 'msg_owner': owner,
            'skills': sk, 'extra': ex}


def bank41_spills(prj_or_data, repo_root=None):
    """Custom skill names that must go to the shared bank-$41 extents."""
    try:
        return layout(prj_or_data, repo_root)['names'][1]
    except CustomSkillError:
        return []


def desc_spills(prj_or_data, repo_root=None):
    try:
        return layout(prj_or_data, repo_root)['descs'][1]
    except CustomSkillError:
        return []


def usage(prj_or_data, repo_root=None):
    lay = layout(prj_or_data, repo_root)
    pool = sum(len(b) for _l, b in lay['msg_pool'])
    return {'names': (lay['names'][2] + sum(len(b) for _l, b in lay['names'][1]), NAME_REGION),
            'descs': (lay['descs'][2] + sum(len(b) for _l, b in lay['descs'][1]), DESC_REGION),
            'lines': (lay['msg_a'][1] + pool, MSG_A + MSG_POOL)}


def check(prj):
    """Validator: resolves and fits (raises CustomSkillError); returns warnings."""
    sk, ex, warns = resolve(prj)
    lay = layout(prj)
    pool = sum(len(b) for _l, b in lay['msg_pool'])
    if pool > MSG_POOL:
        raise CustomSkillError(f"custom skill battle lines: {pool} B do not fit the {MSG_POOL} B "
                               "of bank $4C — shorten some announce lines")
    out = list(warns)
    for k, e in (_gd(prj) or {}).items():                   # stock skills' element
        try:
            sid = int(k)
        except ValueError:
            continue
        if 0 <= sid < STOCK and isinstance(e, dict) and e.get('element') is not None:
            element_value(e['element'], f"gamedata.skills.{sid}.element")
            if native_element(sid) is None:
                from . import skills as SK
                raise CustomSkillError(
                    f"gamedata.skills.{sid}.element: {SK.vanilla_name(sid)}'s damage does not "
                    "test a resistance (measured, extracted/skill_element_census.json) — "
                    "only elemental skills can change their element")
    for s, v in sk.items():
        if v['handler'] == 'clone' and v['learn'] is None:
            out.append(f"gamedata.skills.{s}: {MT.decode(v['name'])} has no learn row — only "
                       "an enemy row / a species' skill slot can give it")
    return out


# ---------------------------------------------------------------------------
# emitters
# ---------------------------------------------------------------------------

def _db(bs):
    return "    db " + ", ".join(f"${b:02X}" for b in bs)


def _cname(sk, s):
    v = sk.get(s)
    if v:
        return MT.decode(v['name'])
    return 'retired' if s in RETIRED else '-'


def emit_records(prj, warnings):
    sk = layout(prj)['skills']
    out = []
    for s in range(FIRST, LAST + 1):
        lab = f"CustomRecord_{s:02X}" if s in sk else "$41CF"
        out.append(f"    dw {lab:<20}; [${s:02X}] {_cname(sk, s)}")
    for s in sorted(sk):
        v = sk[s]
        how = HANDLER_LABEL.get(v['handler'], f"runs {v['base']}'s effect")
        out.append(f"CustomRecord_{s:02X}:  ; [{s}] {MT.decode(v['name'])} — {how}")
        out.append(_db(v['record']))
    return "\n".join(out) + "\n"


def emit_mp(prj, warnings):
    sk = layout(prj)['skills']
    return "\n".join(f"    dw {sk[s]['mp'] if s in sk else 0:<5}; [${s:02X}] {_cname(sk, s)}"
                     for s in range(FIRST, LAST + 1)) + "\n"


def emit_learn(prj, warnings):
    sk = layout(prj)['skills']
    out = []
    for s in range(LEARN_FIRST, LAST + 1):
        row = sk[s]['learn'] if s in sk and sk[s]['learn'] else bytes([0xFF] + [0] * 12 + [0xFF] * 5)
        note = 'not learnable' if row[0] == 0xFF else f"level {row[0]}"
        out.append(_db(row) + f"   ; [${s:02X}] {_cname(sk, s)}: {note}")
    return "\n".join(out) + "\n"


def emit_base(prj, warnings):
    sk = layout(prj)['skills']
    out = []
    for s in range(FIRST, LAST + 1):
        v = sk.get(s)
        b = v['base'] if v and v['base'] is not None else 0xFF
        out.append(f"    db ${b:02X}   ; [${s:02X}] {_cname(sk, s)}"
                   + (f" runs stock skill {b}" if b != 0xFF else ""))
    return "\n".join(out) + "\n"


def stock_elements(prj):
    """[222] the StockElemTable bytes (gamedata.skills.<0-221>.element)."""
    out = [NO_ELEMENT] * STOCK
    for k, e in (_gd(prj) or {}).items():
        try:
            sid = int(k)
        except ValueError:
            continue
        if 0 <= sid < STOCK and isinstance(e, dict) and 'element' in e:
            out[sid] = element_value(e['element'], f"gamedata.skills.{sid}.element")
    return out


def emit_elements(prj, warnings):
    sk = layout(prj)['skills']
    st = stock_elements(prj)
    out = []
    for k in range(0, STOCK, 16):
        row = st[k:k + 16]
        out.append(_db(row) + f"   ; [{k:3d}-{k + len(row) - 1:3d}]")
    out.append("CustomElemTable:")
    cu = [sk[s]['element'] if s in sk else NO_ELEMENT for s in range(FIRST, LAST + 1)]
    for k in range(0, N, 16):
        row = cu[k:k + 16]
        out.append(_db(row) + f"   ; [${FIRST + k:02X}-${FIRST + k + len(row) - 1:02X}]")
    return "\n".join(out) + "\n"


def _tpl(sk, s, base_tpl):
    v = sk.get(s)
    return v['template'] if v else base_tpl


def emit_announce_lo(prj, warnings):
    sk = layout(prj)['skills']
    b = baseline()['skills']
    vals = [_tpl(sk, s, b[s]['announce_template'] if s in b else 0xFF)
            for s in range(FIRST, ANNOUNCE_SPLIT)]
    return _db(vals) + "   ; ids $DE-$E1\n"


def emit_announce(prj, warnings):
    sk = layout(prj)['skills']
    return "\n".join(f"    db ${_tpl(sk, s, 0xFF):02X}   ; [${s:02X}] {_cname(sk, s)}"
                     for s in range(ANNOUNCE_SPLIT, LAST + 1)) + "\n"


def emit_target(prj, warnings):
    sk = layout(prj)['skills']
    out = []
    for s in range(FIRST, LAST + 1):
        v = sk.get(s)
        if v and v['target_row'] is not None:
            r, why = v['target_row'], f"stock skill {v['target_row']}'s row"
        elif s in (0xE5, 0xE6, 0xE7, 0xE8):
            r, why = 0x03, "Firebal's row = Jump_058_62bf (opposite side, first live slot)"
        elif s == 0xE0:     # [S111] was $E5 ($6367): under the act-time AI the cast hit
            r, why = 0x03, "Firebal's row (all foes; S111 fix: the AI aimed it at its own side)"
        elif s in (0xE1, 0xE2, 0xE3):
            r, why = 0x00, "Blaze's row (one foe; S111 fix: the AI aimed it at its own side)"
        elif s == 0xE9:
            r, why = 0x3A, "Attack's row = $41E9"
        else:
            r, why = 0xE5, "the vanilla slack row $E5 = $6367 (a harmless target write)"
        out.append(f"    db ${r:02X}   ; [${s:02X}] {_cname(sk, s)}: {why}")
    return "\n".join(out) + "\n"


def emit_msg_ptrs(prj, warnings):
    lay = layout(prj)
    sk = lay['skills']
    out = []
    for s in range(FIRST, LAST + 1):
        v = sk.get(s)
        lab = lay['msg_owner'].get(v['message']) if v and v['message'] else 'CustomMsg_dummy'
        out.append(f"    dw {lab:<24}; [${s:02X}] {_cname(sk, s)}")
    return "\n".join(out) + "\n"


def _lines(items):
    out = []
    for lab, b in items:
        out.append(f"{lab}:  ; \"{decode_line(b)}\"")
        out.append(_db(b))
    return out


def emit_msg_a(prj, warnings):
    placed, used = layout(prj)['msg_a']
    out = ["CustomMsg_E0_MagicBurn::   ; (the dead $4019[$FD] row names this address)"]
    out += _lines(placed)
    if used < MSG_A:
        out.append(f"    ds {MSG_A - used}, $00")
    return "\n".join(out) + "\n"


def emit_msgs(prj, warnings):
    lay = layout(prj)
    out = ["CustomMsg_dummy:", "    db $F0"]
    out += _lines(lay['msg_pool'])
    return "\n".join(out) + "\n"


def emit_present(prj, warnings):
    sk = layout(prj)['skills']
    b = baseline()['skills']
    vals = []
    for s in range(FIRST, LAST + 1):
        vals.append(sk[s]['proxy'] if s in sk else (b[s]['proxy'] if s in b else 0x09))
    return "\n".join(_db(vals[k:k + 11]) + f"   ; [${FIRST + k:02X}-${FIRST + min(k + 10, N - 1):02X}]"
                     for k in range(0, N, 11)) + "\n"


def emit_sfx(prj, warnings):
    sk = layout(prj)['skills']
    vals = [sk[s]['sfx'] if s in sk else 0x09 for s in range(FIRST, LAST + 1)]
    return "\n".join(_db(vals[k:k + 11]) + f"   ; [${FIRST + k:02X}-${FIRST + min(k + 10, N - 1):02X}]"
                     for k in range(0, N, 11)) + "\n"


def emit_name_ptrs(prj, warnings):
    sk = layout(prj)['skills']
    out = []
    for s in range(FIRST, 256):
        lab = name_label(s, sk[s]['name']) if s in sk else 'SkillName_222_Unused_222'
        out.append(f"    dw {lab}  ; [{s}]")
    return "\n".join(out) + "\n"


def emit_names(prj, warnings):
    placed, spilled, used = layout(prj)['names']
    out = []
    if spilled:
        out.append(f"; ({len(spilled)} name(s) placed in the ns_text_* extents: "
                   + ", ".join(l for l, _b in spilled) + ")")
    for lab, b in placed:
        out.append(f"{lab}:  ; \"{MT.decode(b)}\"")
        out.append(_db(b))
    if used < NAME_REGION:
        out.append(f"    ds {NAME_REGION - used}, $00   ; free ({NAME_REGION - used} B)")
    return "\n".join(out) + "\n"


def emit_desc_ptrs(prj, warnings):
    sk = layout(prj)['skills']
    out = []
    for s in range(FIRST, 256):
        lab = desc_label(s) if s in sk and sk[s]['desc'] else 'SkillDesc_None'
        out.append(f"    dw {lab:<28}; [{s}] {_cname(sk, s)}")
    return "\n".join(out) + "\n"


def emit_descs(prj, warnings):
    placed, spilled, used = layout(prj)['descs']
    out = []
    if spilled:
        out.append(f"; ({len(spilled)} text(s) placed in gd_skill_desc_extra)")
    for lab, b in placed:
        out.append(f"{lab}:  ; \"{MT.decode(b).replace(chr(10), '/')}\"")
        out.append(_db(b))
    if used < DESC_REGION:
        out.append(f"    ds {DESC_REGION - used}, $00   ; free ({DESC_REGION - used} B)")
    return "\n".join(out) + "\n"


def emit_tame(prj, warnings):
    tame = layout(prj)['extra']['tame']
    return "\n".join(f"    dw {tame[s]:<5}; [${s:02X}] {['Tame', 'TameMore', 'TameMost'][s - 0xE1]}"
                     for s in (0xE1, 0xE2, 0xE3)) + "\n"


def emit_quake(prj, warnings):
    q = layout(prj)['extra']['quake']
    nm = ['Tremor', 'Quake', 'QuakeMore', 'QuakeMost']
    return "\n".join(f"    db {q[s][0]}, {q[s][1]}   ; [${s:02X}] {nm[s - 0xE5]} "
                     f"{q[s][0]}-{q[s][0] + q[s][1]}" for s in (0xE5, 0xE6, 0xE7, 0xE8)) + "\n"


def emit_ratios(prj, warnings):
    r = layout(prj)['extra']['ratios']
    B = baseline()['skills']
    out = []
    for off, key, sid in ratio_slots():
        n, d = r[off]
        what = {'burn': f"spends {n}/{d} of the current MP",
                'damage_per_mp': f"damage = {n}/{d} x the MP spent",
                'damage_of_atk': f"damage = {n}/{d} x ATK",
                'mp_charge': f"charges {n}/{d} of the current MP on arrival",
                'ally_damage': f"allies take {n}/{d}",
                'per_fallen': f"+ {n}/{d} x the base damage per fallen ally"}[key]
        out.append(f"    db {n}, {d}".ljust(16) + f"; [${sid:02X}] {B[sid]['label']}: {what}")
    return "\n".join(out) + "\n"


REGIONS = [
    ('gd_custom_records', 'patches/bank_054.asm', emit_records, 0x54),
    ('gd_custom_skill_mp', 'patches/bank_007.asm', emit_mp, 0x07),
    ('gd_custom_learn', 'patches/bank_072.asm', emit_learn, 0x72),
    ('gd_custom_base', 'patches/bank_072.asm', emit_base, 0x72),
    ('gd_skill_elements', 'patches/bank_072.asm', emit_elements, 0x72),
    ('gd_tame_meter', 'patches/bank_072.asm', emit_tame, 0x72),
    ('gd_quake_power', 'patches/bank_072.asm', emit_quake, 0x72),
    ('gd_custom_ratios', 'patches/bank_072.asm', emit_ratios, 0x72),
    ('gd_custom_announce_lo', 'patches/bank_058.asm', emit_announce_lo, 0x58),
    ('gd_custom_announce', 'patches/bank_058.asm', emit_announce, 0x58),
    ('gd_custom_target', 'patches/bank_058.asm', emit_target, 0x58),
    ('gd_custom_msg_ptrs', 'patches/bank_04c.asm', emit_msg_ptrs, 0x4C),
    ('gd_custom_msg_a', 'patches/bank_04c.asm', emit_msg_a, 0x4C),
    ('gd_custom_msgs', 'patches/bank_04c.asm', emit_msgs, 0x4C),
    ('gd_custom_present', 'patches/bank_05f.asm', emit_present, 0x5F),
    ('gd_custom_sfx', 'patches/bank_055.asm', emit_sfx, 0x55),
    ('gd_custom_skill_name_ptrs', 'patches/bank_041.asm', emit_name_ptrs, 0x41),
    ('gd_custom_skill_names', 'patches/bank_041.asm', emit_names, 0x41),
    ('gd_custom_skill_desc_ptrs', 'patches/bank_056.asm', emit_desc_ptrs, 0x56),
    ('gd_custom_skill_desc', 'patches/bank_056.asm', emit_descs, 0x56),
]
