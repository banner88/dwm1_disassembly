"""gamedata.py — Layer A-lite: project.json `gamedata` → the vanilla data tables
(ROADMAP P3.9, S103; PROJECT_COMPILER §2.20; EDITOR_DESIGN §6.2).

`gamedata` is SPARSE: it holds only what the project changes. Every table is
emitted as "vanilla rows + these overrides" into a compiler-owned
@BUILD_PROJECT region (same size, in place — no code moves), so an empty
`gamedata` reproduces the ROM bytes exactly (the per-table regression). The
vanilla rows come from `extracted/gamedata_vanilla.json`
(tools/extract_gamedata.py, verify check 5), so compiling needs no ROM.

Sections (all keys are ids as strings; `_`-prefixed keys are comments):

  monsters     {"78": {"family": 10, "growth": {"hp": 12}, "resist": {"Fire": 3}}}
               MonsterInfoTable $03:$4461 (MONSTER_DATA "Monster Info Table")
  enemies      {"1": {"mp": 100, "skills": [233, 229, 228, 9]}}
               EnemyStatsTable $14:$4C1D, EIDs 0-486 (MONSTER_DATA "Enemy Stats")
  encounters   {"0": {"slot_chance": [1,1,1,6,0], "eids": [2,4,3,"gorbunok_wild",0]}}
               (an EID number, or a progression.enemies id — S105)
               EncounterPoolData $01:$6AAE (DATA_STRUCTURES "Encounter pool entry")
  skills       {"43": {"mp": 3, "learn": {"level": 2}, "record": {"party_min": 40}}}
               SkillMPCostTable $07:$570C / SkillLearnReqTable $06:$50E0 (ids
               $00-$D9 only) / SkillRecordData $54:$41CF (BATTLE_SKILL_SYSTEM §7)
  exp_curves   {"3": [99 cumulative values] | {"2": 5, ...}}   $13:$41E6
  growth_curves{"5": [99 increments]      | {"10": 3, ...}}  $13:$6706
  breeding     {"family": {"37": {"p1": "Dragon", "p2": "Dragon"} | null},
                "special": {"overrides": [...], "appends": [...]}}
               FamilyRecipeTable $16:$4974 (slot = offspring) and the live
               special table in bank $69 (BREEDING_SYSTEM B4/B5 semantics,
               ported from tools/build_breeding.py). A changed family slot also
               regenerates that species' library recipe TEXT (bank $4D,
               coherence Set 1) and a changed monster family regroups the
               library tabs (bank $12 LibFamilyPtrTable).
  boss_joins   {"11": 12}   fight EID -> join EID for the 34 vanilla pairs
               (coherence Set 2; project pairs stay progression.enemies.join_as)
"""

import json
import os
import re

from . import formats as F

VANILLA_JSON = os.path.join('extracted', 'gamedata_vanilla.json')
SECTIONS = ('monsters', 'enemies', 'encounters', 'skills', 'exp_curves',
            'growth_curves', 'breeding', 'boss_joins', 'families', 'art',
            'monster_text',   # S108: names / nicknames / descriptions (monster_text.py)
            'arena',          # S109: arena fees / masters / team sizes (arena.py)
            'items', 'shops')  # S117: item prices / the vanilla shop lists (shops.py)

# S104 (P3.10a): per-family settings. Arena-lobby party dialogue comes in four
# VOICES (bank $04 FamilyTextGroup_A-D, 8 lines each); vanilla gives every
# family one of them. `families.<name>.dialogue` picks the voice by letter or
# by "talks like <family>". Spirit's own default-name pool (the naming screen
# pre-fills a random one when a monster joins or hatches; the other families'
# 16-name pools are vanilla) = `families.spirit.names`.
VOICES = {'A': 'FamilyTextGroup_A', 'B': 'FamilyTextGroup_B',
          'C': 'FamilyTextGroup_C', 'D': 'FamilyTextGroup_D'}
VOICE_OF = ['A', 'B', 'C', 'B', 'A', 'C', 'C', 'A', 'B', 'D', 'D']   # vanilla + Spirit default
VOICE_LABEL = {'A': 'Slime / Plant / Zombie lines', 'B': 'Dragon / Bird / Material lines',
               'C': 'Beast / Bug / Devil lines', 'D': '??? lines'}
SPIRIT_NAMES_DEFAULT = ['WISP', 'SOUL', 'AURA', 'MIST', 'HALO', 'ECHO', 'GLOW', 'NOVA']
# S107 (P3.10 part 2c): `families.<name>.icon` = the family's 8 x 8 icon, 8
# strings of 8 digits 0-3 (the menu font's shades: 0 lightest, 1 = the menu
# background, 2 / 3 ink). ONE picture, written to every copy the game has
# (BREEDING_SYSTEM "Family icons"): the font glyph ($4F:$4110 + 16*family;
# Spirit $41B0 = text byte $1A — INFO page, library tab strip, pedigree, recipe
# text) and the 16-byte gfx stream the HUD / list / JOURNAL / continue-box
# DMAs load (families 0-9 = bank $2E streams 3-12 = gfx ids $2E03 + family,
# Spirit = bank $6D SpiritIconStream $6D04).
ICON_STREAM_LABELS = [f'TileData_2E_{3 + f:02X}' for f in range(10)]
SHADES = '0123'
SPIRIT_NAMES_BYTES = 40      # bank $41 $7E4F-$7E76 the pool lives in (8 x <= 5 B; S105 G3: was the 55-B fill $7E4F-$7E85, its last 15 B are now ns_text_f)
NAME_MAX = 4                 # the nickname field is 4 characters

FAMILY_NAMES = ["Slime", "Dragon", "Beast", "Bird", "Plant", "Bug", "Devil",
                "Zombie", "Material", "Boss", "Spirit"]
NUM_FAMILIES = 11            # library tabs (B9: family 10 = Spirit)
# S104 r5 (user: "put the spirit family BEFORE the ??? family … Just a display
# reorder"): the order families are SHOWN (library tab strip, editor lists).
# Family bytes / codes are unchanged; bank $12 LibTabOrder is this list.
DISPLAY_ORDER = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 9]
PROTECTED_SPECIES = range(215, 221)   # TERRY?, Tatsu, Diago, Samsi, Bazoo, #220
COLLECTIBLE_MAX = 214
RESIST_NAMES = [
    "Fire", "Heat", "Explosion", "Wind", "Lightning", "Ice", "Accuracy", "Sleep",
    "Death", "MP", "SpellBlock", "Confusion", "DefDown", "AglDown", "Sacrifice",
    "MegaMagic", "FireBreath", "IceBreath", "Poison", "Paralyze", "Curse",
    "MissATurn", "DanceBlock", "BreathBlock", "Aid", "GigaSlash", "Unused",
]
STATS = ('hp', 'mp', 'atk', 'def', 'agl', 'int')
LEARN_ROWS = 218             # $00-$D9; $DA-$DD are bank-$06 code (S100)
SKILL_COUNT = 222
ALL_MP = 999                 # SkillMPCostTable value of Farewell / MegaMagic
TARGET_MODES_OK = (0x11, 0x12, 0x21, 0x22, 0x41)   # skills.TARGET_MODES (S110)
VANILLA_EID_MAX = 486
# S105 (P3.9b): EID 518 (the S30 Gorbunok row in the bank-$14 free tail) is gone;
# a new species' enemy rows are ordinary project enemies (EID 519+, bank $6B).

# 19-byte skill record (BATTLE_SKILL_SYSTEM §7 "19-byte record field map")
RECORD_FIELDS = [            # (name, offset, size)
    ('effect_class', 0, 1), ('category', 1, 1), ('target_mode', 2, 1),
    ('ai_weight', 3, 1), ('mp_byte', 4, 1), ('status_id', 5, 1),
    ('damage_class', 6, 1), ('flags7', 7, 1), ('flags8', 8, 1),
    ('flags9', 9, 1), ('field10', 10, 1), ('party_min', 11, 2),
    ('party_range', 13, 2), ('enemy_min', 15, 2), ('enemy_range', 17, 2),
]

_FAMILY_MATCH = {
    "slime": 0xF0, "dragon": 0xF1, "beast": 0xF2, "bird": 0xF3, "flying": 0xF3,
    "plant": 0xF4, "bug": 0xF5, "devil": 0xF6, "zombie": 0xF7, "material": 0xF8,
    "boss": 0xF9, "???": 0xF9, "spirit": 0xFA,
}
# S104: $FA is SPIRIT (family 10's code $F0+10). Vanilla used it as a mate-side
# "any family" wildcard in the bank-$16 family scan (no vanilla row used it);
# the patched scan compares it exactly (patches/bank_016.asm), so the old
# spellings are refused with a pointer instead of silently meaning Spirit.
_RETIRED_MATCH = ("anyfamily", "any")
FAMILY_CODES = {0xF0 + i: n for i, n in enumerate(FAMILY_NAMES)}   # $F0-$FA
SPECIAL_CAPACITY_MAX = 1650  # 2x vanilla (build_breeding.py B3/B5 ceiling)


# Library recipe-text token for Spirit: font glyph $1A (the Spirit icon,
# $4F:$41B0) + "family" — the shape of the vanilla tokens $10-$18 + "family".
SPIRIT_TOKEN = bytes([0x1A]) + bytes.fromhex('433e4a464956')


class GamedataError(ValueError):
    pass


_VANILLA_CACHE = {}
_VCACHE = {}


def vanilla(repo_root):
    path = os.path.join(repo_root, VANILLA_JSON)
    if path not in _VANILLA_CACHE:
        with open(path) as f:
            _VANILLA_CACHE[path] = json.load(f)
    return _VANILLA_CACHE[path]


def _rows(v, name):
    return [bytearray.fromhex(r) for r in v['tables'][name]['rows']]


def _u16(b, o):
    return b[o] | b[o + 1] << 8


def _put16(b, o, v):
    b[o] = v & 0xFF
    b[o + 1] = (v >> 8) & 0xFF


def _int(v, what):
    try:
        x = F.val(v)
    except Exception:
        x = None
    if not isinstance(x, int) or isinstance(v, bool):
        raise GamedataError(f"{what}: not a number: {v!r}")
    return x


def _mp_value(v, what):
    """An MP cost: a number, or "ALL" / "All MP" (= 999)."""
    if isinstance(v, str) and v.strip().lower() in ('all', 'all mp'):
        return ALL_MP
    return _range(v, 0, ALL_MP, what)


def _key_ids(sec, what, lo, hi):
    """{"12": {...}} -> [(12, {...})] sorted; `_` keys skipped."""
    out = []
    for k, v in (sec or {}).items():
        if str(k).startswith('_'):
            continue
        i = _int(k, what)
        if not lo <= i <= hi:
            raise GamedataError(f"gamedata.{what}: id {k} outside {lo}-{hi}")
        out.append((i, v))
    return sorted(out, key=lambda t: t[0])


def _check_keys(d, allowed, what):
    if not isinstance(d, dict):
        raise GamedataError(f"{what}: must be an object")
    bad = [k for k in d if k not in allowed and not str(k).startswith('_')]
    if bad:
        raise GamedataError(f"{what}: unknown key(s) {bad} (allowed: "
                            f"{', '.join(allowed)}) — refusing to ignore authored data")


def _range(v, lo, hi, what):
    v = _int(v, what)
    if not lo <= v <= hi:
        raise GamedataError(f"{what} = {v} outside {lo}-{hi}")
    return v


def family_index(v, what):
    """A family as 0-10 or its name ("Spirit", "Bird"/"Flying", "Boss"/"???")."""
    if isinstance(v, str) and not v.strip().startswith(('$', '0x')) \
            and not v.strip().isdigit():
        code = _FAMILY_MATCH.get(v.strip().lower())
        if code is None:
            raise GamedataError(f"{what}: unknown family {v!r} "
                                f"({', '.join(FAMILY_NAMES)})")
        return code - 0xF0
    return _range(v, 0, NUM_FAMILIES - 1, what)


def _list(v, n, lo, hi, what):
    if not isinstance(v, list) or len(v) != n:
        raise GamedataError(f"{what}: must be a list of {n}")
    return [_range(x, lo, hi, f"{what}[{i}]") for i, x in enumerate(v)]


# ---------------------------------------------------------------------------
# names (comments + breeding matcher names)
# ---------------------------------------------------------------------------

def monster_names(repo_root):
    try:
        data = json.load(open(os.path.join(repo_root, 'extracted', 'monsters_full.json')))
        names = {m['id']: m['name'] for m in data}
    except Exception:
        names = {}
    return names


def skill_names(repo_root):
    try:
        data = json.load(open(os.path.join(repo_root, 'extracted', 'skill_records.json')))
        return {r['id']: r.get('name', '') for r in data['records']}
    except Exception:
        return {}


def _label_name(name, i):
    s = re.sub(r'[^A-Za-z0-9_]', '', name or '')
    return s or f'Unused_{i}'


# ---------------------------------------------------------------------------
# breeding matchers (port of tools/build_breeding.py resolve_matcher & co.)
# ---------------------------------------------------------------------------

def _name_to_id(names):
    return {v.lower(): k for k, v in names.items()}


def resolve_matcher(token, names, *, mate_side, what):
    if isinstance(token, int):
        b = token
    else:
        s = str(token).strip()
        key = s.lower()
        if key in _RETIRED_MATCH:
            raise GamedataError(f"{what}: {token!r} is retired (S104) — $FA is the "
                                "Spirit family now; there is no any-family wildcard")
        if key in _FAMILY_MATCH:
            b = _FAMILY_MATCH[key]
        elif s.startswith('$') or s.lower().startswith('0x'):
            b = F.val(s)
        elif key in _name_to_id(names):
            b = _name_to_id(names)[key]
        else:
            raise GamedataError(f"{what}: cannot resolve breeding matcher {token!r} "
                                "(family name, species name, id or $hex code)")
    if not 0 <= b <= 0xFA:
        raise GamedataError(f"{what}: matcher {token!r} -> ${b:02X} out of range")
    if 220 < b < 0xF0 and b not in names:
        raise GamedataError(f"{what}: matcher ${b:02X} is not a species or family")
    return b


def matcher_name(code, names):
    if code in FAMILY_CODES:
        return f"[{FAMILY_CODES[code]}]"
    return names.get(code, f"species_${code:02X}")


# ---------------------------------------------------------------------------
# the effective tables
# ---------------------------------------------------------------------------

MONSTER_KEYS = ('family', 'level_cap', 'exp_table', 'female_ratio', 'can_fly',
                'metal_body', 'skills', 'growth', 'resist', 'tier')


def apply_monster_fields(r, o, what, extra_keys=()):
    """Write the named fields of `o` into a 43-byte MonsterInfoTable row `r`
    (bytearray; MONSTER_DATA "Monster Info Table"). Shared by gamedata.monsters
    and custom.species[].info (S105). Raises GamedataError."""
    _check_keys(o, MONSTER_KEYS + tuple(extra_keys), what)
    if 'family' in o:
        r[0] = family_index(o['family'], what + '.family')
    if 'level_cap' in o:
        r[1] = _range(o['level_cap'], 0, 99, what + '.level_cap')
    if 'exp_table' in o:
        r[2] = _range(o['exp_table'], 0, 31, what + '.exp_table')
    if 'female_ratio' in o:
        r[3] = _range(o['female_ratio'], 0, 3, what + '.female_ratio')
    if 'can_fly' in o:
        r[4] = _range(o['can_fly'], 0, 1, what + '.can_fly')
    if 'metal_body' in o:
        r[5] = _range(o['metal_body'], 0, 1, what + '.metal_body')
    if 'skills' in o:
        r[6:9] = bytes(_list(o['skills'], 3, 0, 255, what + '.skills'))
    if 'growth' in o:
        g = o['growth']
        _check_keys(g, STATS, what + '.growth')
        for i, s in enumerate(STATS):
            if s in g:
                # indices > 31 index bank-$13 code (MONSTER_DATA "Growth curves")
                r[9 + i] = _range(g[s], 0, 31, f"{what}.growth.{s}")
    if 'resist' in o:
        rs = o['resist']
        if isinstance(rs, list):
            r[15:42] = bytes(_list(rs, 27, 0, 3, what + '.resist'))
        else:
            _check_keys(rs, RESIST_NAMES, what + '.resist')
            for i, n in enumerate(RESIST_NAMES):
                if n in rs:
                    r[15 + i] = _range(rs[n], 0, 3, f"{what}.resist.{n}")
    if 'tier' in o:
        r[42] = _range(o['tier'], 0, 7, what + '.tier')


# ---------------------------------------------------------------------------
# Encounter lists (S103; S114: shared with the project's OWN lists,
# editor2/core/encounters.py). 26 B — DATA_STRUCTURES "Encounter pool entry".
# ---------------------------------------------------------------------------
LIST_KEYS = ('rate', 'unk1', 'size_chance', 'slot_chance', 'eids', 'max_count',
             'maze_size')


def apply_list_fields(r, o, what, eid_of):
    """Write the fields of `o` (gamedata.encounters.<n> / a custom.encounter_lists
    entry) into the 26-byte list `r`. eid_of(ref, what) -> EID."""
    if 'rate' in o:
        r[0] = _range(o['rate'], 0, 7, what + '.rate')
    if 'unk1' in o:
        r[1] = _range(o['unk1'], 0, 255, what + '.unk1')
    if 'size_chance' in o:
        r[2:5] = bytes(_list(o['size_chance'], 3, 0, 7, what + '.size_chance'))
    if 'slot_chance' in o:
        r[5:10] = bytes(_list(o['slot_chance'], 5, 0, 7, what + '.slot_chance'))
    if 'eids' in o:
        raw = o['eids']
        if not isinstance(raw, list) or len(raw) != 5:
            raise GamedataError(f"{what}.eids: must be a list of 5")
        for i, x in enumerate(raw):
            _put16(r, 10 + 2 * i, eid_of(x, f"{what}.eids[{i}]"))
    if 'max_count' in o:
        r[20:25] = bytes(_list(o['max_count'], 5, 0, 3, what + '.max_count'))
    if 'maze_size' in o:
        r[25] = _range(o['maze_size'], 0, 255, what + '.maze_size')


def check_list(r, what, pct):
    """The engine rules for one 26-byte list: raises GamedataError for a list
    the game would walk off or freeze on; returns warnings."""
    warnings = []
    # CalcEncounterPoolIdx walks cumulative percentages until one exceeds
    # a 0-99 draw: a list that never reaches 100 runs off its end.
    if sum(pct[c] for c in r[2:5]) < 100:
        raise GamedataError(f"{what}.size_chance: the 1/2/3-monster chances "
                            "add up to less than 100 %")
    if sum(pct[c] for c in r[5:10]) < 100:
        raise GamedataError(f"{what}.slot_chance: the slot chances add up "
                            "to less than 100 %")
    if sum(pct[c] for c in r[5:10]) > 100:
        # S106 r3: every original list is exactly 100; above it the
        # running sums pass 100 early and the last slots are never drawn
        warnings.append(f"{what}.slot_chance: the slot chances add up to "
                        f"{sum(pct[c] for c in r[5:10])} % — the last slots "
                        "are cut (every original list is exactly 100 %)")
    eids = [_u16(r, 10 + 2 * i) for i in range(5)]
    for i in range(5):
        if r[5 + i] and not eids[i]:
            raise GamedataError(f"{what}: slot {i} has a chance but no EID")
    # Group size: the 2nd/3rd monster is re-drawn until a slot passes
    # SetupEncounterCalc (max_count >= copies so far incl. itself, and
    # != 1). A first pick with max 1 ends the group at one monster; a
    # first pick with max 0 or >= 2 and no slot able to follow re-draws
    # FOREVER — measured S103 (PyBoy: 28,257 passes, no battle).
    maxes = [r[20 + i] for i in range(5) if r[5 + i] and eids[i]]
    cap = sum(x for x in maxes if x >= 2)
    if any(x != 1 for x in maxes):
        if pct[r[3]] + pct[r[4]] and cap < 2:
            raise GamedataError(
                f"{what}: 2-3 monsters can be drawn, but no slot may appear "
                "twice (max_count >= 2) — the game would re-draw the second "
                "monster forever (freeze)")
        if pct[r[4]] and cap < 3:
            raise GamedataError(
                f"{what}: 3 monsters can be drawn, but the slots allow only "
                f"{cap} copies in all (max_count) — the third draw never ends")
    live = [e for i, e in enumerate(eids) if e and r[5 + i]]
    if len(live) != len(set(live)):
        warnings.append(f"{what}: the same EID sits in two slots "
                        "(vanilla never does — S77)")
    return warnings


class Gamedata:
    """Vanilla tables + a project's `gamedata` overrides, resolved once.

    Attributes after __init__: rows per table (bytearrays), `edited` sets per
    table, `warnings`. Raises GamedataError on invalid data."""

    def __init__(self, gd, repo_root, project_enemy_eids=(), new_species=None,
                 enemy_ids=None):
        """new_species: the project's custom.species, {id: {'name', 'family'}}
        (S105 — was extracted/new_species.json). enemy_ids: {progression.enemies
        id: EID}, so encounter pools may name a project enemy instead of its
        number."""
        self.repo = repo_root
        self.v = vanilla(repo_root)
        self.gd = gd or {}
        self.warnings = []
        self.names = monster_names(repo_root)
        self.snames = skill_names(repo_root)
        # S108 (P3.10 part 3): renamed originals (gamedata.monster_text) — the
        # library recipe lines naming them follow (coherence Set 1)
        from . import monster_text as MT
        self.text_names = MT.name_overrides({'gamedata': self.gd}, repo_root)
        self.new_species = dict(new_species or {})
        for sid, s in self.new_species.items():
            self.names.setdefault(sid, s['name'])
        self.enemy_ids = dict(enemy_ids or {})
        self.valid_eids = set(range(0, VANILLA_EID_MAX + 1)) | set(project_enemy_eids)
        _check_keys(self.gd, SECTIONS, 'gamedata')
        self.monster = _rows(self.v, 'monster_info')
        self.enemy = _rows(self.v, 'enemy_stats')
        self.pool = _rows(self.v, 'encounter_pools')
        self.family = _rows(self.v, 'family_recipes')
        self.special = [list(r) for r in _rows(self.v, 'special_recipes')]
        self.exp = _rows(self.v, 'exp_curves')
        self.growth = _rows(self.v, 'growth_curves')
        self.learn = _rows(self.v, 'skill_learn')
        self.mp = _rows(self.v, 'skill_mp')
        self.record = _rows(self.v, 'skill_records')
        self.v_mp = _rows(self.v, 'skill_mp')            # S110: vanilla copies
        self.v_record = _rows(self.v, 'skill_records')
        self.redirects = [(_u16(r, 0), _u16(r, 2)) for r in _rows(self.v, 'boss_redirects')]
        self.edited = {k: set() for k in ('monster', 'enemy', 'pool', 'family',
                                          'exp', 'growth', 'learn', 'mp',
                                          'record', 'redirect')}
        self.special_overrides = []
        self.special_appends = []
        self._monsters()
        self._enemies()
        self._encounters()
        self._skills()
        self._curves()
        self._breeding()
        self._boss_joins()
        self._families()

    # -- monsters -------------------------------------------------------
    def _monsters(self):
        for sid, o in _key_ids(self.gd.get('monsters'), 'monsters', 0, 220):
            what = f"gamedata.monsters.{sid}"
            r = self.monster[sid]
            before = bytes(r)
            if 'family' in o and sid in PROTECTED_SPECIES and \
                    family_index(o['family'], what + '.family') != r[0]:
                raise GamedataError(f"{what}.family: species {sid} is a protected "
                                    "combat-only entry (never in the library)")
            apply_monster_fields(r, o, what)
            if bytes(r) != before:
                self.edited['monster'].add(sid)
            if sid in PROTECTED_SPECIES:
                self.warnings.append(f"{what}: species {sid} is combat-only "
                                     "(rival / summon) — edits reach battles only")
            for s in r[6:9]:
                if s >= SKILL_COUNT:
                    self.warnings.append(f"{what}.skills: id {s} is not a vanilla "
                                         "skill — it must be a custom skill (bank $72)")

    # -- enemies --------------------------------------------------------
    def _enemies(self):
        keys = ('species', 'exp', 'joinability', 'level') + STATS + ('ai_weights', 'skills')
        boss_fights = {f: j for f, j in self.redirects}
        for eid, o in _key_ids(self.gd.get('enemies'), 'enemies', 0, VANILLA_EID_MAX):
            what = f"gamedata.enemies.{eid}"
            _check_keys(o, keys, what)
            r = self.enemy[eid]
            before = bytes(r)
            if 'species' in o:
                sp = _int(o['species'], what + '.species')
                if not (0 <= sp <= 220 or sp in self.new_species):
                    raise GamedataError(f"{what}.species {sp}: not a vanilla species "
                                        "0-220 or a declared new species")
                r[0] = sp
            if 'exp' in o:
                _put16(r, 1, _range(o['exp'], 0, 0xFFFF, what + '.exp'))
            if 'joinability' in o:
                r[3] = _range(o['joinability'], 0, 7, what + '.joinability')
            if 'level' in o:
                r[4] = _range(o['level'], 0, 99, what + '.level')
            for i, s in enumerate(STATS):
                if s in o:
                    _put16(r, 5 + 2 * i, _range(o[s], 0, 0xFFFF, f"{what}.{s}"))
            if 'ai_weights' in o:
                r[17:21] = bytes(_list(o['ai_weights'], 4, 0, 255, what + '.ai_weights'))
            if 'skills' in o:
                sk = o['skills']
                if not isinstance(sk, list) or len(sk) > 4:
                    raise GamedataError(f"{what}.skills: a list of up to 4 skill ids")
                ids = [_range(x, 0, 255, f"{what}.skills[{i}]") for i, x in enumerate(sk)]
                r[21:25] = bytes(ids + [0xFF] * (4 - len(ids)))
            if bytes(r) != before:
                self.edited['enemy'].add(eid)
            if r[0] != before[0]:
                self.warnings.append(
                    f"{what}: species changed — resistances, flying and metal come "
                    "from the SPECIES, not the row (coherence Set 3)")
                if eid in boss_fights:
                    j = boss_fights[eid]
                    self.warnings.append(
                        f"{what}: this is a boss FIGHT row; its join row EID {j} still "
                        "has its own species — change both or set boss_joins (Set 2)")
            if r[0] != before[0] or r[3] != before[3]:
                if r[3] != 7 and r[5] | r[6] << 8 > 1023:
                    self.warnings.append(f"{what}: joinable with HP > 1023")

    # -- encounters -----------------------------------------------------
    def _encounters(self):
        pct = self.v['chance_percent']
        for pid, o in _key_ids(self.gd.get('encounters'), 'encounters', 0, 127):
            what = f"gamedata.encounters.{pid}"
            _check_keys(o, LIST_KEYS, what)
            r = self.pool[pid]
            before = bytes(r)
            apply_list_fields(r, o, what, self.list_eid)
            if bytes(r) == before:
                continue
            self.edited['pool'].add(pid)
            self.warnings += check_list(r, what, pct)

    def list_eid(self, x, what):
        """An encounter-list slot's enemy: an EID number (0-486 or a project
        EID) or, S105, a progression.enemies id -> the EID."""
        if isinstance(x, str) and x not in self.enemy_ids and \
                not re.match(r'^(\$|0x)?[0-9A-Fa-f]+$', x):
            raise GamedataError(f"{what} = {x!r}: no such enemy row — not a "
                                "progression.enemies id of this project")
        e = self.enemy_ids[x] if isinstance(x, str) and x in self.enemy_ids else x
        e = _range(e, 0, 0xFFFF, what)
        if e and e not in self.valid_eids:
            raise GamedataError(
                f"{what} = {x!r}: no such enemy row (0-486, or a project enemy — "
                "its progression.enemies id or EID >= 519; 487-518 are code / "
                "free space)")
        return e

    # -- skills ---------------------------------------------------------
    def _skills(self):
        # S110 (P3.11): `name` / `description` / `looks_like` are validated and
        # emitted by editor2/core/skills.py (their own regions); here: mp, learn,
        # record. MP (BATTLE_SKILL_SYSTEM §7 "Field map — S110 reader census"):
        # the BATTLE reads record +4 (8-bit: menu afford, act-time afford and
        # deduct, the AI veto, TakeMagic) and the FIELD menu reads the $07
        # SkillMPCostTable word — `mp` writes BOTH, except where vanilla keeps them
        # apart on purpose: the two "All MP" skills (Farewell $32, MegaMagic $66:
        # table 999, record 1 — the zeroing is code) and the field-only StepGuard /
        # MapMagic (record 0 — never charged in battle). `record.mp_byte` still
        # overrides the battle byte (expert).
        # S111: ids 222-254 are the CUSTOM skills (editor2/core/custom_skills.py
        # validates and emits them); only the 222 stock skills are handled here.
        stock = {k: v for k, v in (self.gd.get('skills') or {}).items()
                 if str(k).startswith('_') or not str(k).strip().isdigit()
                 or int(k) < SKILL_COUNT}
        for sid, o in _key_ids(stock, 'skills', 0, SKILL_COUNT - 1):
            what = f"gamedata.skills.{sid}"
            _check_keys(o, ('mp', 'learn', 'record', 'name', 'description', 'looks_like',
                            'sounds_like', 'element', 'presentation', 'comment'), what)
            if 'mp' in o:
                van_mp = _u16(self.v_mp[sid], 0)
                mp = _mp_value(o['mp'], what + '.mp')
                if mp == ALL_MP and van_mp != ALL_MP:
                    raise GamedataError(
                        f"{what}.mp: \"All MP\" exists only for Farewell / MegaMagic — "
                        "the game empties the MP in their own code")
                if mp != ALL_MP and mp > 255:
                    raise GamedataError(f"{what}.mp = {mp}: 0-255 (the battle keeps the cost "
                                        "in one byte)")
                if van_mp == ALL_MP and mp != ALL_MP:
                    raise GamedataError(f"{what}.mp: this skill always takes all MP (code); "
                                        "its cost cannot be a number")
                before = bytes(self.mp[sid])
                _put16(self.mp[sid], 0, mp)
                if bytes(self.mp[sid]) != before:
                    self.edited['mp'].add(sid)
                vr = self.v_record[sid]
                if van_mp != ALL_MP and vr[4] == (van_mp & 0xFF) and mp <= 255:
                    if self.record[sid][4] != mp:
                        self.record[sid][4] = mp           # the battle copy
                        self.edited['record'].add(sid)
            if o.get('element') is not None and not ('record' in o and 'status_id' in
                                                     (o.get('record') or {})):
                # S111: the AI's assumed element (record +5, 1-based) follows the
                # damage element (custom_skills.py emits the override tables)
                from . import custom_skills as CS
                ev = CS.element_value(o['element'], what + '.element')
                nv = 0 if ev == CS.ELEMENT_NONE else ev + 1
                if self.record[sid][5] != nv:
                    self.record[sid][5] = nv
                    self.edited['record'].add(sid)
            if 'learn' in o:
                if sid >= LEARN_ROWS:
                    raise GamedataError(
                        f"{what}.learn: skill ids $DA-$DD have no learn row — those "
                        "bytes are bank $06 FieldStateDispatch code (DOC_AUDIT S100)")
                L = o['learn']
                _check_keys(L, ('level',) + STATS + ('prereqs',), what + '.learn')
                r = self.learn[sid]
                before = bytes(r)
                if 'level' in L:
                    r[0] = _range(L['level'], 0, 255, what + '.learn.level')
                for i, s in enumerate(STATS):
                    if s in L:
                        _put16(r, 1 + 2 * i, _range(L[s], 0, 0xFFFF, f"{what}.learn.{s}"))
                if 'prereqs' in L:
                    p = L['prereqs']
                    if not isinstance(p, list) or len(p) > 5:
                        raise GamedataError(f"{what}.learn.prereqs: up to 5 skill ids")
                    ids = [_range(x, 0, SKILL_COUNT - 1, f"{what}.learn.prereqs")
                           for x in p]
                    r[13:18] = bytes(ids + [0xFF] * (5 - len(ids)))
                if bytes(r) != before:
                    self.edited['learn'].add(sid)
            if 'record' in o:
                R = o['record']
                _check_keys(R, [n for n, _, _ in RECORD_FIELDS], what + '.record')
                r = self.record[sid]
                before = bytes(self.v_record[sid])
                for n, off, size in RECORD_FIELDS:
                    if n in R:
                        v = _range(R[n], 0, 0xFF if size == 1 else 0xFFFF,
                                   f"{what}.record.{n}")
                        if size == 1:
                            r[off] = v
                        else:
                            _put16(r, off, v)
                if 'target_mode' in R and r[2] not in TARGET_MODES_OK and \
                        r[2] != self.v_record[sid][2]:
                    raise GamedataError(
                        f"{what}.record.target_mode ${r[2]:02X}: one of $11 one foe, $12 all "
                        "foes, $21 one ally, $22 all allies, $41 the user (or the original)")
                if bytes(r) != before:
                    self.edited['record'].add(sid)

    # -- curves ---------------------------------------------------------
    def _curves(self):
        for name, table, width, maxv, key in (
                ('exp_curves', self.exp, 3, 0xFFFFFF, 'exp'),
                ('growth_curves', self.growth, 1, 255, 'growth')):
            for cid, o in _key_ids(self.gd.get(name), name, 0, 31):
                what = f"gamedata.{name}.{cid}"
                r = table[cid]
                before = bytes(r)
                cur = [int.from_bytes(r[i * width:(i + 1) * width], 'little')
                       for i in range(99)]
                if isinstance(o, list):
                    cur = _list(o, 99, 0, maxv, what)
                elif isinstance(o, dict):
                    for k, v in o.items():
                        if str(k).startswith('_'):
                            continue
                        lv = _range(k, 1, 99, what + ' level')
                        cur[lv - 1] = _range(v, 0, maxv, f"{what}.{k}")
                else:
                    raise GamedataError(f"{what}: a list of 99 values or {{level: value}}")
                table[cid] = bytearray(b''.join(x.to_bytes(width, 'little') for x in cur))
                if bytes(table[cid]) != before:
                    self.edited[key].add(cid)
                if key == 'exp' and any(cur[i] > cur[i + 1] for i in range(98)):
                    self.warnings.append(f"{what}: cumulative exp decreases somewhere "
                                         "— a level would be reached before the one below it")

    # -- breeding -------------------------------------------------------
    def fam_code(self, sp):
        """Family code $F0-$FA of a concrete species (effective family byte)."""
        if sp is None or sp >= 0xF0:
            return None
        if sp <= 220:
            f = self.monster[sp][0]
        elif sp in self.new_species:
            f = self.new_species[sp]['family']
        else:
            return None
        # S105: family 10 (Spirit) is code $FA — the breeding scanners convert a
        # parent to $F0 + family (BREEDING_SYSTEM), so a Spirit parent matches a
        # $FA matcher; S104 stopped at 9 and the shadow checks missed Spirit.
        return 0xF0 + f if f is not None and f <= 10 else None

    def _breeding(self):
        b = self.gd.get('breeding') or {}
        _check_keys(b, ('family', 'special'), 'gamedata.breeding')
        names = dict(self.names)
        # slots 215-220 breed the protected combat-only species: never offered
        for sid, o in _key_ids(b.get('family'), 'breeding.family', 0, COLLECTIBLE_MAX):
            what = f"gamedata.breeding.family.{sid}"
            r = self.family[sid]
            before = bytes(r)
            if o is None:
                r[0] = r[1] = 0xFF           # separator: no recipe for this offspring
            else:
                _check_keys(o, ('p1', 'p2'), what)
                if 'p1' not in o or 'p2' not in o:
                    raise GamedataError(f"{what}: needs p1 and p2 (or null = no recipe)")
                r[0] = resolve_matcher(o['p1'], names, mate_side=False, what=what + '.p1')
                r[1] = resolve_matcher(o['p2'], names, mate_side=True, what=what + '.p2')
            if bytes(r) != before:
                self.edited['family'].add(sid)
        self._special(b.get('special') or {}, names)
        # family shadow warnings (ported): a special entry with the same family
        # pair fires first; an identical family pair at a higher slot wins.
        # S113: a regenerated tree edits every slot — past 8 the rest are
        # summarised (the Breeding tab shows each slot's real reach)
        n_before = len(self.warnings)
        for sid in sorted(self.edited['family']):
            p1, p2 = self.family[sid]
            if p1 == 0xFF:
                continue
            for i, e in enumerate(self.special):
                if e[0] == p1 and e[1] == p2:
                    self.warnings.append(
                        f"breeding.family.{sid}: [{matcher_name(p1, names)} x "
                        f"{matcher_name(p2, names)}] is SHADOWED by special entry {i} "
                        f"(-> {matcher_name(e[3], names)})")
                    break
            if 0xF0 <= p1 <= 0xFA and 0xF0 <= p2 <= 0xFA:
                higher = [s for s in range(sid + 1, 221)
                          if tuple(self.family[s]) == (p1, p2)]
                if higher:
                    self.warnings.append(
                        f"breeding.family.{sid}: out-ranked by the identical matcher "
                        f"at slot(s) {higher} (last family match wins)")
        extra = self.warnings[n_before:]
        if len(extra) > 8:
            self.warnings[n_before:] = extra[:5] + [
                f"breeding.family: {len(extra) - 5} more family recipes are partly or "
                "wholly beaten by special rows / later slots (see the Breeding tab)"]

    def _recipe(self, spec, names, *, base, what):
        out = list(base) if base is not None else [None] * 5
        if spec.get('p1') is not None:
            out[0] = resolve_matcher(spec['p1'], names, mate_side=False, what=what + '.p1')
        if spec.get('p2') is not None:
            out[1] = resolve_matcher(spec['p2'], names, mate_side=True, what=what + '.p2')
        if spec.get('min_plus') is not None:
            out[2] = _range(spec['min_plus'], 0, 255, what + '.min_plus')
        if spec.get('result') is not None:
            res = spec['result']
            if isinstance(res, str) and not res.startswith(('$', '0x')):
                nid = _name_to_id(names)
                if res.strip().lower() not in nid:
                    raise GamedataError(f"{what}.result {res!r}: unknown species")
                res = nid[res.strip().lower()]
            out[3] = _int(res, what + '.result')
        if spec.get('plus_mod') is not None:
            out[4] = _range(spec['plus_mod'], 0, 255, what + '.plus_mod')
        if any(x is None for x in out):
            raise GamedataError(f"{what}: an append needs p1, p2, min_plus, result, plus_mod")
        if not (0 <= out[3] <= 220 or out[3] in self.new_species):
            raise GamedataError(f"{what}.result ${out[3]:02X}: not a species 0-220 or "
                                "a new species of the project (custom.species)")
        return out

    @staticmethod
    def _matches(e, p1, p2, f1, f2):
        m0 = e[0] == p1 or (f1 is not None and e[0] == f1)
        m1 = e[1] == p2 or (f2 is not None and e[1] == f2)   # S104: no $FA wildcard (Spirit)
        return m0 and m1

    def _first(self, entries, p1, p2, f1, f2, upto=None):
        for i in range(len(entries) if upto is None else upto):
            if self._matches(entries[i], p1, p2, f1, f2):
                return i
        return None

    def _special(self, spec, names):
        """The special table (S113 — ROADMAP P3.12, BREEDING_SYSTEM "Auto-ordered
        special table (S113)").

        Base = the 825 vanilla rows, or `table` (a whole replacement list).
        Edits on the vanilla base: `overrides` (a row by vanilla `index`, or the
        first row a `match` cross fires, in vanilla order), `removes` (same
        addressing) and `appends` (new rows). With ANY of these the emitted table
        is stably SORTED most specific first — species x species, species x
        family, family x species, family x family, and within each a higher min
        plus first — so a new recipe beats the general rows it overlaps and
        loses to the more specific ones, wherever it was written. Measured S113:
        this order gives vanilla's exact results for every pair and plus (the
        vanilla FS / FF interleave never overlaps). No edits = vanilla bytes.

        `self.special_src[i]` says where emitted row i came from: ('vanilla', n),
        ('edited', n), ('added', k) or ('table', k)."""
        _check_keys(spec, ('overrides', 'appends', 'removes', 'table'), 'gamedata.breeding.special')
        for sp in self.new_species:
            names.setdefault(sp, self.new_species[sp]['name'])
        self.special_removed = []
        if spec.get('table') is not None:
            for k in ('overrides', 'appends', 'removes'):
                if spec.get(k):
                    raise GamedataError(f"gamedata.breeding.special: `table` replaces the "
                                        f"whole table — it cannot be combined with `{k}`")
            rows = spec['table']
            if not isinstance(rows, list):
                raise GamedataError("gamedata.breeding.special.table: a list of recipes")
            entries, src = [], []
            for k, r in enumerate(rows):
                what = f"gamedata.breeding.special.table[{k}]"
                if not isinstance(r, dict):
                    raise GamedataError(f"{what}: an object {{p1, p2, min_plus, result, plus_mod}}")
                _check_keys(r, ('p1', 'p2', 'min_plus', 'result', 'plus_mod'), what)
                e = self._recipe(dict({'min_plus': 0, 'plus_mod': 0}, **r), names,
                                 base=None, what=what)
                entries.append(e)
                src.append(('table', k))
                self.special_appends.append(e)
            self._finish_special(entries, src, names, sort=True)
            return
        entries = self.special
        src = [('vanilla', n) for n in range(len(entries))]

        def address(o, what):
            if o.get('index') is not None:
                return _range(o['index'], 0, 824, what + '.index')
            if o.get('match'):
                m = o['match']
                p1 = resolve_matcher(m['p1'], names, mate_side=False, what=what)
                p2 = resolve_matcher(m['p2'], names, mate_side=True, what=what)
                idx = self._first(entries, p1, p2, self.fam_code(p1), self.fam_code(p2))
                if idx is None:
                    raise GamedataError(f"{what}.match: no special entry fires for "
                                        "that cross — use an append")
                return idx
            raise GamedataError(f"{what}: needs index or match")
        seen = {}
        for k, o in enumerate(spec.get('overrides') or []):
            what = f"gamedata.breeding.special.overrides[{k}]"
            _check_keys(o, ('index', 'match', 'p1', 'p2', 'min_plus', 'result',
                            'plus_mod'), what)
            idx = address(o, what)
            if idx in seen:
                raise GamedataError(f"{what}: entry {idx} is already overridden")
            seen[idx] = k
            before = list(entries[idx])
            after = self._recipe(o, names, base=before, what=what)
            entries[idx] = after
            src[idx] = ('edited', idx)
            self.special_overrides.append((idx, before, after))
        drop = set()
        for k, o in enumerate(spec.get('removes') or []):
            what = f"gamedata.breeding.special.removes[{k}]"
            _check_keys(o, ('index', 'match'), what)
            idx = address(o, what)
            if idx in seen:
                raise GamedataError(f"{what}: entry {idx} is also overridden — "
                                    "remove or change it, not both")
            if idx in drop:
                raise GamedataError(f"{what}: entry {idx} is already removed")
            drop.add(idx)
            self.special_removed.append((idx, list(entries[idx])))
        for k, a in enumerate(spec.get('appends') or []):
            what = f"gamedata.breeding.special.appends[{k}]"
            _check_keys(a, ('p1', 'p2', 'min_plus', 'result', 'plus_mod'), what)
            e = self._recipe(dict({'min_plus': 0, 'plus_mod': 0}, **a), names,
                             base=None, what=what)
            entries.append(e)
            src.append(('added', k))
            self.special_appends.append(e)
        keep = [i for i in range(len(entries)) if i not in drop]
        entries = [entries[i] for i in keep]
        src = [src[i] for i in keep]
        edited = bool(seen or drop or spec.get('appends'))
        self._finish_special(entries, src, names, sort=edited)
        # an override that changed a result: say if other rows still give it
        for idx, before, e in self.special_overrides:
            if before[3] != e[3]:
                others = [i for i, x in enumerate(self.special) if x[3] == before[3]]
                if others:
                    self.warnings.append(
                        f"breeding.special entry {idx} no longer yields "
                        f"{matcher_name(before[3], names)}, but {len(others)} other "
                        "entries still do — editing one cross does not remove it")

    @staticmethod
    def special_key(e):
        """Sort key of the auto-ordered special table (most specific first)."""
        rank = (0xF0 <= e[0] <= 0xFA) * 2 + (0xF0 <= e[1] <= 0xFA)   # SS 0, SF 1, FS 2, FF 3
        return (rank, -e[2])

    def _finish_special(self, entries, src, names, *, sort):
        if sort:
            order = sorted(range(len(entries)), key=lambda i: self.special_key(entries[i]))
            entries = [entries[i] for i in order]
            src = [src[i] for i in order]
        if len(entries) > SPECIAL_CAPACITY_MAX:
            raise GamedataError(f"breeding.special: {len(entries)} entries > "
                                f"{SPECIAL_CAPACITY_MAX}")
        # two rows with the SAME parents and min plus: the later one can never
        # fire. Vanilla has two such pairs (entries 682/693, 802/803) — reported
        # by the editor, refused only when a project row is involved.
        first = {}
        for i, e in enumerate(entries):
            key = (e[0], e[1], e[2])
            if key in first:
                j = first[key]
                if src[i][0] != 'vanilla' or src[j][0] != 'vanilla':
                    where = {'vanilla': 'vanilla entry', 'edited': 'edited vanilla entry',
                             'added': 'appends', 'table': 'table'}
                    def tag(s):
                        return (f"{where[s[0]]} {s[1]}" if s[0] in ('vanilla', 'edited')
                                else f"{where[s[0]]}[{s[1]}]")
                    raise GamedataError(
                        f"breeding.special: {tag(src[i])} [{matcher_name(e[0], names)} x "
                        f"{matcher_name(e[1], names)}"
                        f"{f' +{e[2]}' if e[2] else ''}] has the same parents as "
                        f"{tag(src[j])} (-> {matcher_name(entries[j][3], names)}) and "
                        "would never fire — change or remove that one instead")
            else:
                first[key] = i
        self.special = entries
        self.special_src = src

    # -- boss joins -----------------------------------------------------
    def _families(self):
        self.voice = list(VOICE_OF)
        self.spirit_names = list(SPIRIT_NAMES_DEFAULT)
        self.edited['voice'] = set()
        self.edited['spirit_names'] = False
        self.icons = vanilla_icons(self.repo)
        self.edited['icons'] = set()
        sec = self.gd.get('families') or {}
        for k, o in sec.items():
            if str(k).startswith('_'):
                continue
            what = f"gamedata.families.{k}"
            f = family_index(k, what)
            if not isinstance(o, dict):
                raise GamedataError(f"{what}: must be an object")
            _check_keys(o, ('dialogue', 'names', 'icon'), what)
            if 'icon' in o:
                grid = icon_grid(o['icon'], what + '.icon')
                if grid != self.icons[f]:
                    self.icons[f] = grid
                    self.edited['icons'].add(f)
            if 'dialogue' in o:
                v = str(o['dialogue']).strip()
                if v.upper() in VOICES:
                    voice = v.upper()
                else:
                    voice = VOICE_OF[family_index(v, what + '.dialogue')]
                if voice != self.voice[f]:
                    self.voice[f] = voice
                    self.edited['voice'].add(f)
            if 'names' in o:
                if f != 10:
                    raise GamedataError(f"{what}.names: only Spirit has an editable "
                                        "name pool (the other families keep their "
                                        "vanilla 16 names)")
                ns = o['names']
                if not isinstance(ns, list) or len(ns) != 8:
                    raise GamedataError(f"{what}.names: a list of 8 names")
                for i, n in enumerate(ns):
                    if not isinstance(n, str) or not 1 <= len(n) <= NAME_MAX \
                            or not all(c.isascii() and c.isalpha() for c in n):
                        raise GamedataError(f"{what}.names[{i}] {n!r}: 1-{NAME_MAX} "
                                            "letters A-Z / a-z")
                if list(ns) != self.spirit_names:
                    self.spirit_names = list(ns)
                    self.edited['spirit_names'] = True

    def _boss_joins(self):
        sec = self.gd.get('boss_joins') or {}
        fights = [f for f, _ in self.redirects]
        for k, v in sec.items():
            if str(k).startswith('_'):
                continue
            f = _int(k, 'gamedata.boss_joins')
            if f not in fights:
                raise GamedataError(
                    f"gamedata.boss_joins.{k}: EID {f} is not one of the 34 vanilla "
                    "fight rows (new pairs: progression.enemies[].join_as)")
            j = _int(v, f'gamedata.boss_joins.{k}')
            if j not in self.valid_eids:
                raise GamedataError(f"gamedata.boss_joins.{k}: join EID {j} does not exist")
            i = fights.index(f)
            if self.redirects[i][1] != j:
                self.redirects[i] = (f, j)
                self.edited['redirect'].add(f)

    # -- derived --------------------------------------------------------
    def library_families(self):
        """species -> effective family for the library (0..214 + new species)."""
        fam = {i: self.monster[i][0] for i in range(COLLECTIBLE_MAX + 1)}
        for sid, s in self.new_species.items():
            if s['family'] is not None:
                fam[sid] = s['family']
        return fam

    def library_text_edits(self):
        """{species: bytes} for every encyclopedia recipe line that must follow
        the project (coherence Set 1): a family slot that differs from vanilla,
        and (S108) every slot whose pair names a RENAMED monster
        (gamedata.monster_text) — regenerated with the project names, which
        also drops vanilla's own typos in those lines (Akubar "Grenadal")."""
        lib = self.v['library']
        pad = lib['pad']
        tok = {int(k): bytes.fromhex(v) for k, v in lib['family_tokens'].items()}
        names = self.v['monster_name_bytes']
        van = _rows(self.v, 'family_recipes')
        renamed = self.text_names

        def token(m):
            if m == 0xFF:
                return b'\x64' * 5                     # "?????" (no recipe)
            if 0xF0 <= m <= 0xF9:
                return tok[m - 0xF0]
            if m == 0xFA:
                return SPIRIT_TOKEN                    # <Spirit icon>family
            if m in renamed:
                return renamed[m]
            return bytes.fromhex(names[m])
        out = {}
        for s in range(len(self.family)):
            if s >= len(lib['strings']) or s > 214:
                continue
            a, b = self.family[s][0], self.family[s][1]
            fam_changed = s in self.edited['family'] and bytes(self.family[s]) != bytes(van[s])
            if not fam_changed and a not in renamed and b not in renamed:
                continue
            t1 = token(a)[:9].ljust(9, bytes([pad]))
            t2 = token(b)
            if lib['pad_token2']:
                t2 = t2.ljust(9, bytes([pad]))
            line = t1 + t2 + b'\xf0'
            if fam_changed or line[:-1] != bytes.fromhex(lib['strings'][s]):
                out[s] = line
        return out


# ---------------------------------------------------------------------------
# region text
# ---------------------------------------------------------------------------

def _db(bs):
    return "    db " + ", ".join(f"${b:02X}" for b in bs)


# Labels INSIDE a table that other code in the bank refers to (mgbdis names;
# the referencing bytes are mostly data decoded as code, but the overlay must
# still link). Each is re-emitted at its byte offset in the generated region.
# Measured S103 over the patched tree (label -> offset from the table start).
ANCHORS = {
    'monster_info': [('DataMon_59d0', 5487), ('DataMon_624e', 7661),
                     ('Jump_003_6473', 8210), ('Jump_003_648e', 8237),
                     ('Jump_003_6719', 8888), ('Jump_003_68ab', 9290)],
    'encounter_pools': [('EncounterDataTable_1', 2393),
                        ('EncounterDataTable_2', 2418),
                        ('EncounterWeightTable', 2509)],
}


def _rows_text(rows, anchors=()):
    """rows = [(head_lines, bytes, body_lines)]; body_lines render the bytes.
    A row that an anchor falls INSIDE is rendered as plain db chunks split at
    the anchor(s); an anchor at a row start goes before the row."""
    out, off = [], 0
    pending = sorted(anchors, key=lambda a: a[1])
    for head, data, body in rows:
        end = off + len(data)
        at_start = [n for n, o in pending if o == off]
        inside = [(n, o) for n, o in pending if off < o < end]
        out += [f"{n}:  ; (referenced from elsewhere in the bank)" for n in at_start]
        out += head
        if inside:
            cut = off
            for n, o in inside + [(None, end)]:
                if o > cut:
                    out.append(_db(data[cut - off:o - off]))
                if n:
                    out.append(f"{n}:  ; (referenced from elsewhere in the bank)")
                cut = o
        else:
            out += body
        off = end
    return out


def _mark(edited):
    return "  ; EDITED (project gamedata)" if edited else ""


def emit_monster_info(g):
    out = ["; (generated by editor2 `gd_monsters` from gamedata.monsters — vanilla",
           ";  rows + project overrides; 43 B: family, cap, exp curve, female ratio,",
           ";  fly, metal, 3 skills, 6 growth curves, 27 resistances, tier)",
           "MonsterInfoTable:"]
    rows = []
    for i, r in enumerate(g.monster):
        nm = g.names.get(i, '')
        fam = FAMILY_NAMES[r[0]] if r[0] < len(FAMILY_NAMES) else f"family {r[0]}"
        rows.append(([f"MonsterInfo_{i:03d}_{_label_name(nm, i)}:  ; {nm or '(unused)'} — "
                      f"{fam}{_mark(i in g.edited['monster'])}"],
                     r, [_db(r[0:15]), _db(r[15:43])]))
    out += _rows_text(rows, ANCHORS['monster_info'])
    return "\n".join(out) + "\n"


def emit_enemy_stats(g):
    out = ["; (generated by editor2 `gd_enemies` from gamedata.enemies — 25 B: species,",
           ";  exp, joinability, level, HP MP ATK DEF AGL INT, 4 AI weights, 4 skills)",
           "EnemyStatsTable:"]
    for i, r in enumerate(g.enemy):
        st = [_u16(r, 5 + 2 * k) for k in range(6)]
        sk = [g.snames.get(s, f"${s:02X}") if s != 0xFF else '-' for s in r[21:25]]
        out.append(f"EnemyStats_{i:03d}:  ; {g.names.get(r[0], r[0])} Lv{r[4]} "
                   f"join {r[3]}{_mark(i in g.edited['enemy'])}")
        out.append(f"    db {r[0]}")
        out.append(f"    dw {_u16(r, 1)}")
        out.append(f"    db {r[3]}, {r[4]}")
        out.append(f"    dw {', '.join(str(x) for x in st)}  ; HP MP ATK DEF AGL INT")
        out.append(f"    db {', '.join(str(x) for x in r[17:21])}  ; AI weights")
        out.append(f"    db {', '.join(f'${x:02X}' for x in r[21:25])}  ; {', '.join(sk)}")
    return "\n".join(out) + "\n"


def emit_encounter_pools(g):
    pct = g.v['chance_percent']
    out = ["; (generated by editor2 `gd_encounters` from gamedata.encounters. 26 B:",
           ";  +0 rate code -> wC8A9 (EncounterRateModifierTable), +1 unread, +2..+4 chance",
           ";  codes for 1/2/3 monsters, +5..+9 chance codes per slot (code -> % via",
           ";  EncounterChancePercent $01:$69C0), +10 five EIDs, +20 per-slot max count",
           ";  (1 = only ever alone, 0 = never as the 2nd/3rd monster), +25 maze size",
           ";  -> $C93D (the bank-$16 maze carve count: vanilla 3 / 8 / 15) — S103",
           ";  static decode of bank $01 EncounterMonsterSelect / LoadFloorAndEncounterData)",
           "EncounterPoolData:"]
    rows = []
    for i, r in enumerate(g.pool):
        eids = [_u16(r, 10 + 2 * k) for k in range(5)]
        who = []
        for k, e in enumerate(eids):
            if e and r[5 + k]:
                who.append(f"EID {e} {pct[r[5 + k]]}%")
        rows.append(([f"EncounterPool_{i:03d}:  ; {', '.join(who) or '(unused)'}"
                      f"{_mark(i in g.edited['pool'])}"], r,
                     [_db(r[0:10]), f"    dw {', '.join(str(e) for e in eids)}",
                      _db(r[20:26])]))
    out += _rows_text(rows, ANCHORS['encounter_pools'])
    return "\n".join(out) + "\n"


def emit_family_recipes(g):
    out = ["; (generated by editor2 `gd_family` from gamedata.breeding.family —",
           ";  222 x [pedigree, mate]; slot = offspring species, $FF,$FF = none)",
           "FamilyRecipeTable:  ; $4974 — indexed species*2 by label16_485c (no bounds",
           ";  check; ids >= 221 go through FamilyRecipeResolve, S105 G3 — row 221 is never read). See BREEDING_SYSTEM.md."]
    for i, (a, b) in enumerate(g.family):
        if (a, b) == (0xFF, 0xFF):
            txt = "(no recipe)"
        elif (a, b) == (0, 0):
            txt = "(terminator)"
        else:
            txt = f"{matcher_name(a, g.names)} x {matcher_name(b, g.names)}"
        out.append(f"    db ${a:02X}, ${b:02X}  ; {i:3d} {g.names.get(i, '')}: {txt}"
                   f"{_mark(i in g.edited['family'])}")
    return "\n".join(out) + "\n"


def emit_special_recipes(g):
    src = getattr(g, 'special_src', None) or [('vanilla', i) for i in range(len(g.special))]
    moved = any(s[0] != 'vanilla' or s[1] != i for i, s in enumerate(src))
    out = ["; (generated by editor2 `gd_special` from gamedata.breeding.special —",
           ";  the 825 vanilla entries, or (S113) with ANY edit the effective table",
           ";  auto-ordered most specific first: species x species, species x family,",
           ";  family x species, family x family, higher min plus first within each.",
           ";  5 B: pedigree, mate, min plus, result, plus modifier; first match wins)",
           "RelocatedSpecialTable:"]
    tags = {'edited': 'EDITED vanilla', 'added': 'ADDED (appends', 'table': 'TABLE ('}
    for i, e in enumerate(g.special):
        kind, n = src[i]
        if kind == 'vanilla':
            tag = f"  ; vanilla {n}" if (moved and i % 25 == 0) else ""
        elif kind == 'edited':
            tag = f"  ; EDITED vanilla {n}"
        else:
            tag = f"  ; {'ADDED' if kind == 'added' else 'TABLE'} [{n}]"
        if tag or i % 25 == 0:
            tag = (tag or "  ;") + (f" [{i}] {matcher_name(e[0], g.names)} x "
                                    f"{matcher_name(e[1], g.names)} -> "
                                    f"{matcher_name(e[3], g.names)}")
        out.append(_db(e) + tag)
    out.append("    db $FF")
    return "\n".join(out) + "\n"


def emit_curves(g, which):
    if which == 'exp':
        out = ["; (generated by editor2 `gd_curves` from gamedata.exp_curves — 32 curves",
               ";  x 99 levels x 3 B LE cumulative exp; monster info +$02 picks one)",
               "ExpCurveTables:"]
        for c, r in enumerate(g.exp):
            out.append(f"ExpCurve_{c:02d}:{_mark(c in g.edited['exp'])}")
            for lv in range(0, 99, 11):
                out.append(_db(r[lv * 3:(lv + 11) * 3]) + f"  ; Lv {lv + 1}-{lv + 11}")
    else:
        out = ["; (generated by editor2 `gd_curves` from gamedata.growth_curves — 32",
               ";  curves x 99 per-level stat increments; monster info +$09-$0E pick)",
               "StatGrowthTables:"]
        for c, r in enumerate(g.growth):
            out.append(f"GrowthCurve_{c:02d}:{_mark(c in g.edited['growth'])}")
            for lv in range(0, 99, 33):
                out.append("    db " + ", ".join(str(x) for x in r[lv:lv + 33])
                           + f"  ; Lv {lv + 1}-{lv + 33}")
    return "\n".join(out) + "\n"


def emit_skill_learn(g):
    out = ["; (generated by editor2 `gd_skill_learn` from gamedata.skills[].learn —",
           ";  218 x 18 B: level, HP MP ATK DEF AGL INT (u16), 5 prereqs $FF-padded.",
           ";  NO rows $DA-$DD: FieldStateDispatch code follows — DOC_AUDIT S100)",
           "SkillLearnReqTable:"]
    for i, r in enumerate(g.learn):
        out.append(f"    ; --- ${i:02X} {g.snames.get(i, '')}{_mark(i in g.edited['learn'])}")
        out.append(_db(r))
    return "\n".join(out) + "\n"


def _name_bytes(n):
    # font: 'A'-'Z' = $24-$3D, 'a'-'z' = $3E-$57 (charmap; "Gorbunok" in bank $41)
    return bytes((0x24 + ord(c) - 65) if c.isupper() else (0x3E + ord(c) - 97)
                 for c in n) + b'\xf0'


def emit_family_voices(g):
    out = ["; (generated by editor2 `gd_family_voices` from gamedata.families[].dialogue —",
           ";  arena-lobby party dialogue voice per family, read by FamilyTextGroupFromE)",
           "FamilyTextPtrTable11:"]
    for f, v in enumerate(g.voice):
        out.append(f"    dw {VOICES[v]}  ; {f} {FAMILY_NAMES[f]}{_mark(f in g.edited['voice'])}")
    return "\n".join(out) + "\n"


def vanilla_icons(repo_root):
    """The 11 icons the game ships (families 0-9 = the ROM's font glyphs;
    Spirit = the S104 ghost wisp) as 8 x 8 grids of 0-3, from
    extracted/family_icons.json (tools/build_family_icon.py --selftest proves
    them against the ROM / the patch)."""
    key = ('icons', repo_root)
    if key not in _VCACHE:
        d = json.load(open(os.path.join(repo_root, 'extracted', 'family_icons.json')))
        _VCACHE[key] = [ic['grid'] for ic in d['icons']] + [d['spirit']['grid']]
    return [[list(r) for r in g] for g in _VCACHE[key]]


def icon_grid(v, what):
    """8 strings of 8 digits 0-3 -> 8 x 8 grid."""
    if not isinstance(v, list) or len(v) != 8 or \
            not all(isinstance(r, str) and len(r) == 8 and set(r) <= set(SHADES) for r in v):
        raise GamedataError(f"{what}: 8 rows of 8 digits 0-3 (0 lightest, 1 = the menu "
                            "background, 2 / 3 ink), e.g. \"11131111\"")
    return [[int(c) for c in r] for r in v]


def icon_rows(grid):
    """8 x 8 grid -> the project's 8 strings."""
    return [''.join(str(v) for v in r) for r in grid]


def icon_tile(grid):
    """8 x 8 grid of 0-3 -> 16 bytes 2bpp (low plane, high plane per row)."""
    out = bytearray()
    for r in grid:
        lo = hi = 0
        for v in r:
            lo = (lo << 1) | (v & 1)
            hi = (hi << 1) | ((v >> 1) & 1)
        out += bytes((lo, hi))
    return bytes(out)


def icon_stream(grid):
    """The 19-byte literal gfx stream of an icon (dw $0010, run marker =
    the smallest byte value the tile does not use, the 16 bytes) — exactly
    the format of the 11 shipped streams."""
    tile = icon_tile(grid)
    marker = next(v for v in range(256) if v not in tile)
    return bytes((0x10, 0x00, marker)) + tile


def emit_family_icon_glyphs(g):
    """bank $4F $4110-$41BF: the 11 font glyphs (text bytes $10-$1A)."""
    out = ["; (generated by editor2 `gd_family_icons` from gamedata.families[].icon —",
           ";  the family icon FONT glyphs, text bytes $10-$1A: INFO page, library tab",
           ";  strip, pedigree, recipe text. Families 0-9 = the vanilla tiles (they were",
           ";  INCBIN gfx/image_04f_4110.2bpp), Spirit = the S104 ghost wisp)"]
    for f in range(NUM_FAMILIES):
        if f == 10:
            out.append("SpiritFamilyIconGlyph:")
        tag = ' = SPIRIT icon' if f == 10 else ''
        out.append(_db(icon_tile(g.icons[f])) + f"  ; ${0x4110 + 16 * f:04X} byte ${0x10 + f:02X}"
                   f"{tag} — {FAMILY_NAMES[f]}{_mark(f in g.edited['icons'])}")
    return "\n".join(out) + "\n"


def emit_family_icon_streams(g):
    """bank $2E streams 3-12 (gfx ids $2E03-$2E0C): families 0-9's 16-byte
    icon streams (19 B each, same size always)."""
    out = ["; (generated by editor2 `gd_family_icon_streams` from gamedata.families[].icon —",
           ";  the HUD / list / JOURNAL / continue-box copy of families 0-9's icons; read",
           ";  through FollowerFamilyGfxTable ($01), FamilyIconGfxTable0A,",
           ";  SavedPartyFamilyIconTable07 / 0A and bank $6D FamilyIconGfxFromE)"]
    for f in range(10):
        b = icon_stream(g.icons[f])
        assert len(b) == 19
        out.append(f"{ICON_STREAM_LABELS[f]}:  ; gfx id ${0x2E03 + f:04X} — {FAMILY_NAMES[f]} icon"
                   f"{_mark(f in g.edited['icons'])}")
        out.append(_db(b[:16]))
        out.append(_db(b[16:]))
    return "\n".join(out) + "\n"


def emit_spirit_icon_stream(g):
    """bank $6D SpiritIconStream (gfx id $6D04)."""
    b = icon_stream(g.icons[10])
    return ("; (generated by editor2 `gd_spirit_icon_stream` from gamedata.families.spirit.icon)\n"
            f"SpiritIconStream:{_mark(10 in g.edited['icons'])}\n"
            "    dw $0010\n"
            f"    db ${b[2]:02X}                              ; run marker (absent from the tile bytes)\n"
            + _db(b[3:]) + "\n")


def emit_spirit_names(g):
    out = ["; (generated by editor2 `gd_spirit_names` from gamedata.families.spirit.names —",
           ";  the Spirit default-name pool, mode-3 ids $A0-$A7 via the dead $4323 words",
           ";  (bank $6D FamilyDefaultNameId). Fixed 40 B: names + zero pad; the old",
           ";  fill's last 15 B are new-species text extent ns_text_f since S105 G3)"]
    used = 0
    for i, n in enumerate(g.spirit_names):
        b = _name_bytes(n)
        used += len(b)
        out.append(f"SpiritName_{i}:  ; \"{n}\"")
        out.append(_db(b))
    if used < SPIRIT_NAMES_BYTES:
        out.append(_db(bytes(SPIRIT_NAMES_BYTES - used)) + "  ; zero pad")
    assert used <= SPIRIT_NAMES_BYTES
    return "\n".join(out) + "\n"


def emit_skill_mp(g):
    out = ["; (generated by editor2 `gd_skill_mp` from gamedata.skills[].mp — 222 x",
           ";  u16 LE; 999 = \"All MP\". Read by GetSkillMPCost)",
           "SkillMPCostTable:"]
    for i, r in enumerate(g.mp):
        out.append(f"    dw ${_u16(r, 0):04X}  ; ${i:02X} {g.snames.get(i, '')}"
                   f"{_mark(i in g.edited['mp'])}")
    return "\n".join(out) + "\n"


def emit_skill_records(g):
    out = ["; (generated by editor2 `gd_skill_records` from gamedata.skills[].record —",
           ";  222 x 19 B, BATTLE_SKILL_SYSTEM §7 field map)",
           "SkillRecordData:"]
    for i, r in enumerate(g.record):
        out.append(_db(r) + f"  ; [{i:3d}] {g.snames.get(i, '')}"
                   f"{_mark(i in g.edited['record'])}")
    return "\n".join(out) + "\n"


GRID_ROWS = 5


def emit_library_grouping(g):
    """bank $12 LibFamilyPtrTable (B7/B9 format, tools/build_library_table.py
    emit_table_asm): one list per family tab in species-id order."""
    import math
    fam = g.library_families()
    groups = {f: [] for f in range(NUM_FAMILIES)}
    for i in sorted(fam):
        if fam[i] < NUM_FAMILIES:
            groups[fam[i]].append(i)
    for f, m in groups.items():
        if len(m) > 32:
            raise GamedataError(f"library: family {FAMILY_NAMES[f]} has {len(m)} "
                                "members > 32 (the encyclopedia tab's display buffer "
                                "$C0D8) — give some species (gamedata.monsters / "
                                "custom.species info.family) another family")
    nav = GRID_ROWS * math.ceil(NUM_FAMILIES / GRID_ROWS)
    out = ["; (generated by editor2 `gd_library` from the effective family bytes:",
           ";  vanilla + gamedata.monsters[].family + new species — B7/B9 grouping)",
           "LibFamilyPtrTable:"]
    out += [f"    dw LibFamily_{f:02d}" for f in range(NUM_FAMILIES)]
    out += ["    dw LibFamilyEmpty"] * (nav - NUM_FAMILIES)
    out.append("")
    for f in range(NUM_FAMILIES):
        m = groups[f]
        out.append(f"LibFamily_{f:02d}:  ; {len(m)} members ({FAMILY_NAMES[f]})")
        out.append(f"    db {len(m)}" + ("".join(f", ${x:02x}" for x in m)))
    out.append("LibFamilyEmpty:  ; spare nav cells (>= NUM_FAMILIES) — blank, crash-safe")
    out.append("    db 0")
    return "\n".join(out) + "\n"


def _decode_text(bs):
    """Comment text for a recipe string (dwm/text.py charmap; repo root is on
    sys.path for every editor2 entry point, as render.py already requires)."""
    try:
        from dwm.text import decode
        return decode(bytes(bs))[0].replace('"', "'")
    except Exception:
        return ''


def library_slots(v):
    """[(first species, last species, slot bytes)] over the $43CE block:
    species 0-214 one slot each (19 B; one is 20), 215-220 share the last."""
    lib = v['library']
    blk = bytes.fromhex(lib['block'])
    base = lib['block_addr']
    ptrs = lib['ptrs']
    starts = sorted(set(ptrs))
    out = []
    for k, p in enumerate(starts):
        end = starts[k + 1] if k + 1 < len(starts) else base + len(blk)
        who = [s for s, q in enumerate(ptrs) if q == p]
        out.append((who[0], who[-1], blk[p - base:end - base]))
    return out


def library_block_text(v, edits=None, names=None, header=None):
    """The whole recipe-string block as labelled db rows (used both for the
    clean-tree re-section S103 and the compiler region). `edits` = {species:
    new string incl. $F0}; an edited string is written IN PLACE (its dispatch
    pointer never moves — entries 5-10 double as the $4007 mode 2-7 bases,
    TEXT_SYSTEM), the slot's remaining bytes keep their vanilla values."""
    edits = edits or {}
    names = names or {}
    out = list(header or [])
    out.append("LibRecipeTextBlock:")
    for s0, s1, slot in library_slots(v):
        blob = bytearray(slot)
        tag = ""
        if s0 in edits:
            new = edits[s0]
            if len(new) > len(slot):
                raise GamedataError(f"library text for species {s0} is {len(new)} B, "
                                    f"its slot {len(slot)} B")
            blob[:len(new)] = new
            tag = "  ; REGENERATED (project family recipe)"
        who = (f"{s0} {names.get(s0, '')}" if s0 == s1
               else f"{s0}-{s1} (shared: combat-only species)")
        out.append(f"LibRecipeText_{s0:03d}:  ; {who}: \"{_decode_text(blob)}\"{tag}")
        out.append(_db(blob))
    return "\n".join(out) + "\n"


def emit_library_strings(g):
    return library_block_text(
        g.v, g.library_text_edits(), g.names,
        ["; (generated by editor2 `gd_library_text`: the encyclopedia recipe line",
         ";  per species, dispatch entry = species + 5 → these slots. A family slot",
         ";  the project changed gets its string regenerated in place — coherence",
         ";  Set 1, BREEDING_SYSTEM \"Library recipe TEXT\")"])


def redirect_rows(g):
    return list(g.redirects)
