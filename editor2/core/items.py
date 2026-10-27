"""items.py — ITEMS as project data (S151, ROADMAP E9; PROJECT_COMPILER §2.59,
DATA_STRUCTURES "Items (S151)").

Headless (no Qt).

WHAT THE GAME STORES (ROM-verified + PyBoy-measured S151):
  * every item is one byte id in the bag (wInventory $CA51, 20 slots) and the Vault
    (wBankSlots $CA65, 40); $00 / $FF = an empty slot. The game's items are 1-43.
  * its 12-byte record ItemInfoTable ($03:$71DA, 44 records), copied by bank $03
    entry 2 to $DA62-$DA6D before anything uses the item. The readers (a byte scan of
    the whole ROM for every load of $DA62-$DA6D + the disassembly agree):
      +0       group (0 restore, 1 cure, 2 seed / book, 3 meat, 4 staff, 5 WarpWing,
               6 TinyMedal, 7 key item) — NOT READ by the game
      +1/+2    the BUY price (bank $09: the shop lists, the sell price)
      +3       the chance (%) the item is USED UP when used: bank $03 entry 8
               (RNG16 mod 100 < +3 -> the bag slot is emptied); 100 = always (Herb),
               20 = a staff / the SageStone breaks 1 time in 5, 0 = never (BeastTail,
               ShinyHarp). An item that is used up with +3 < 100 says "The … falls
               apart!" (use message 0) — bank $07 / bank $54.
      +4       FIELD use: 0 / 1 = can be used from the field menu, 2 / 3 = not ("…
               uses the … as a tool." + "But nothing happens.") — bank $07 $4F3B; and
               2 / 3 also skip the "on which monster?" window ($4D51)
      +5       pick a monster in the field: 0 / 2 / 4 = the "on which monster?" window
               opens, anything else not (bank $07 $4D5C)
      +6       NOT READ
      +7       the USE message (bank $41 mode 13 — the 48 item_use_message lines)
      +8       the RESULT message (mode 13; 0 = none; the SageStone / WorldDew handler
               writes 39-41 itself)
      +9       POWER: the amount of the field effect (Herb heals +9 + RNG mod 11 HP; a
               seed adds +9; meat lowers the wildness by +9; …) — bank $03's handlers
      +10      NOT READ (the vanilla rows hold the effect's top end: Herb 30 / 40)
      +11      bit 0 = the shops will not buy it (bank $09 SELL list), bit 2 = it is
               KEPT when the party loses a battle (banks $06 / $50); other bits unread.
  * what an item DOES is code chosen by its id: bank $03 entry 3 (may it be used now?)
    and entry 4 (the field effect) are jump tables over the 44 ids; bank $07 picks the
    target window's numbers by id and sends the WarpWing ($1D) / WarpStaff ($27) down
    their own paths; bank $09 pays a tenth for a staff; in battle the item is the skill
    id + $AF (items 1-37 = the item_effect skills 176-212; their power / targets /
    "usable in battle" (+10) are the SKILL record — gamedata.skills, BATTLE_SKILL_SYSTEM
    §8); bank $12 counts the TinyMedal ($1E) and bank $19 draws the BeastTail's ($26)
    compass on the gate map — by the real id.

PATCHED (S151): the records of every item live in bank $77 (ItemTable, generated —
ItemInfoTable in bank $03 is no longer read): the copy is bank $77 entry 16
ItemRecordCopy, which also sets wItemBase = the item's BEHAVIOUR id. A NEW item (ids
44-127, custom.items) = its own record (name, description, price, use-up chance,
power, messages, flags) + a BASE (one of the game's items 1-43) whose code it runs:
bank $03's two tables, bank $07's choices and bank $09's staff rule read wItemBase;
in battle (bank $50 -> bank $77 entries 17 / 18) it is its base's battle skill — the
same effect and power as the base — and banks $52 / $54 name it from wItemInUse. The
item-count scratch of the SELL list / the Vault ($D665 + id) covers ids 1-127 (bank
$09, was 1-47). Its name / description / own use lines are texts in the S150 text
banks (keys past the game's rows: item_name / item_description 44+, item_use_message
48+).

SCHEMA:
  "gamedata": {"items": {"29": {"price": 100, "consume": 0, "keep_on_loss": true}}}
      edits of the game's items 1-43 (sparse; every field optional):
        price 0-65535, consume 0-100, field_use bool, pick_monster bool,
        use_message 0-255, result_message 0-255, power 0-255,
        sellable bool, keep_on_loss bool, raw {"0": n, "6": n, "10": n, "11": n}
  "custom": {"items": [{"id": 44, "name": "MegaHerb", "base": 1,
        "description": "Restores between\\n80 to 90 HP", "price": 300, "power": 80,
        "use_message": 3 | "use_text": "…", "result_message": 4 | "result_text": "…",
        "consume": 100, "field_use": true, "pick_monster": true,
        "sellable": true, "keep_on_loss": false}]}
      a new item: a fixed id 44-127 (scripts, shops and saves refer to the number), a
      name (1-9 letters), its base (1-43; the fields it does not set are its base's),
      a description (markup, 2 lines); an own use / result line = `use_text` /
      `result_text` (markup; the compiler numbers them 48+).
"""

import json
import os

from . import textmark as TM

GAME_ITEMS = 44                 # ids 0-43 (0 = no item)
FIRST_NEW = 44                  # ITEM_FIRST_NEW
ID_MAX = 127                    # the SELL / Vault count scratch ($D665 + id, 128 B)
RECORD = 12
USE_MESSAGES = 48               # bank $41 mode 13 rows of the game
MESSAGE_MAX = 255
NAME_MAX = 9                    # the bag / shop columns (gametext.MAX_GLYPHS)
DESC_LINES, DESC_CELLS = 2, 18  # the ITEM page's description window
NAME_TABLE, DESC_TABLE, USE_TABLE = 0x48E7, 0x493F, 0x4A1B   # bank $41 modes 8 / 9 / 13
TEXT_BANK = 0x41

# bases a new item may NOT take: their behaviour is the real id's elsewhere
#   30 TinyMedal — bank $12 counts only $1E (a new "medal" would be an inert key item:
#               allowed, but the Medal Man ignores it — see NOTES)
# none are refused; NOTES explains each special case.
FIELDS = ('price', 'consume', 'field_use', 'pick_monster', 'use_message',
          'result_message', 'power', 'sellable', 'keep_on_loss', 'raw')
NEW_FIELDS = FIELDS + ('id', 'name', 'base', 'description', 'use_text', 'result_text',
                       'comment', 'note')

# What each base does in the FIELD (bank $03 entry 3 = when it may be used, entry 4 =
# the effect; S151 trace) — the Items tab's words. {power} = record +9.
EFFECTS = {
    0: ('nothing', 'Nothing happens.'),
    1: ('heal HP', 'Heals one monster by {power} + 0-10 HP (it must be alive and hurt).'),
    2: ('heal HP', 'Heals one monster by {power} + 0-10 HP (it must be alive and hurt).'),
    3: ('heal the party', 'Heals every hurt monster of the party by {power} + 0-10 HP.'),
    4: ('heal the party fully', 'Fully heals the HP of every monster of the party.'),
    5: ('restore MP', "Restores one monster's MP by {power} + 0-10 (alive, MP not full)."),
    6: ('restore MP fully', "Fully restores one monster's MP (alive, MP not full)."),
    7: ('cure poison', 'Cures one monster of poison.'),
    8: ('cure paralysis', 'Cures one monster of paralysis.'),
    9: ('cure (SkyBell)', 'Cures one monster of what the SkyBell cures (status bit 4).'),
    10: ('break a curse', 'Breaks the curse on one monster.'),
    11: ('wake up', 'Wakes one monster up.'),
    12: ('revive', 'Revives a fallen monster with full HP.'),
    13: ('max HP up', "Raises one monster's max HP by {power} (up to 999)."),
    14: ('max MP up', "Raises one monster's max MP by {power} (up to 999)."),
    15: ('ATK up', "Raises one monster's ATK by {power} (up to 999)."),
    16: ('DEF up', "Raises one monster's DEF by {power} (up to 999)."),
    17: ('AGL up', "Raises one monster's AGL by {power} (up to 511)."),
    18: ('INT up', "Raises one monster's INT by {power} (up to 255)."),
    19: ('feed (meat)', "Feeds one monster: its wildness drops by {power}."),
    20: ('feed (meat)', "Feeds one monster: its wildness drops by {power}."),
    21: ('feed (meat)', "Feeds one monster: its wildness drops by {power}."),
    22: ('feed (bad meat)', "Feeds one monster: its wildness drops by {power} and it is poisoned."),
    23: ('feed (meat)', "Feeds one monster: its wildness drops by {power}."),
    24: ('staff', 'No field effect (in battle: the BoltStaff).'),
    25: ('staff', 'No field effect (in battle: the WindStaff).'),
    26: ('staff', 'No field effect (in battle: the MistStaff).'),
    27: ('staff', 'No field effect (in battle: the LavaStaff).'),
    28: ('staff', 'No field effect (in battle: the SnowStaff).'),
    29: ('warp home', 'Leaves the gate for home (the hub / the Castle), as the WarpWing.'),
    30: ('key item', 'Nothing (the Medal Man counts only the real TinyMedal).'),
    31: ('personality', 'Reads a story to one monster (QuestBK: braver).'),
    32: ('personality', 'Reads a story to one monster (HorrorBK: a coward).'),
    33: ('personality', 'Reads a story to one monster (BeNiceBK: kinder).'),
    34: ('personality', 'Reads a story to one monster (CheaterBK: shrewder).'),
    35: ('personality', 'Reads a story to one monster (SmartBK: smarter).'),
    36: ('personality', 'Reads a story to one monster (ComedyBK: naive).'),
    37: ('staff', 'No field effect (in battle: the FireStaff).'),
    38: ('point to the stairs', "In a gate: says which way the floor's hole is (the gate "
                                "map's compass is the real BeastTail's only)."),
    39: ('WarpStaff', 'In a gate: as the WarpStaff.'),
    40: ('repel monsters', 'In a gate: no more random battles on this floor.'),
    41: ('call a battle', 'In a gate: starts a battle with the floor\'s monsters.'),
    42: ('show the map', "In a gate: shows the whole floor's map."),
    43: ('save', 'In a gate (not in its special rooms): records to the Journal.'),
}


class ItemError(ValueError):
    pass


def _repo(repo_root=None):
    return repo_root or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


_VAN = {}


def vanilla_records(repo_root=None):
    """The game's 44 records (bytes) from extracted/gamedata_vanilla.json."""
    repo = _repo(repo_root)
    if repo not in _VAN:
        t = json.load(open(os.path.join(repo, 'extracted', 'gamedata_vanilla.json')))['tables']
        _VAN[repo] = [bytes.fromhex(r) for r in t['item_info']['rows']]
    return _VAN[repo]


def game_names(repo_root=None):
    """{id: the game's name} (items.inc spelling, e.g. BeefJerky)."""
    from .shops import item_names
    return item_names(repo_root)


def decode(rec):
    """A record -> the editor's fields."""
    return {'group': rec[0], 'price': rec[1] | rec[2] << 8, 'consume': rec[3],
            'field_use': rec[4] in (0, 1), 'pick_monster': rec[5] in (0, 2, 4),
            'use_message': rec[7], 'result_message': rec[8], 'power': rec[9],
            'sellable': not rec[11] & 1, 'keep_on_loss': bool(rec[11] & 4),
            'raw4': rec[4], 'raw5': rec[5], 'raw6': rec[6], 'raw10': rec[10],
            'raw11': rec[11]}


def _int(v, what, lo, hi):
    try:
        n = int(v, 0) if isinstance(v, str) else int(v)
    except (TypeError, ValueError):
        raise ItemError(f"{what}: {v!r} is not a number") from None
    if isinstance(v, bool) or not lo <= n <= hi:
        raise ItemError(f"{what}: {n} — {lo}-{hi}")
    return n


def _bool(v, what):
    if not isinstance(v, bool):
        raise ItemError(f"{what}: true or false")
    return v


def apply_fields(rec, e, what, own_msgs=None):
    """Write the editor fields of `e` into the bytearray rec (12 B)."""
    if 'price' in e:
        p = _int(e['price'], what + '.price', 0, 0xFFFF)
        rec[1], rec[2] = p & 0xFF, p >> 8
    if 'consume' in e:
        rec[3] = _int(e['consume'], what + '.consume', 0, 100)
    if 'field_use' in e:
        if _bool(e['field_use'], what + '.field_use') != (rec[4] in (0, 1)):
            rec[4] = 1 if e['field_use'] else 2
    if 'pick_monster' in e:
        if _bool(e['pick_monster'], what + '.pick_monster') != (rec[5] in (0, 2, 4)):
            rec[5] = 4 if e['pick_monster'] else 7
    for k, off in (('use_message', 7), ('result_message', 8)):
        if k in e:
            rec[off] = _int(e[k], f"{what}.{k}", 0, MESSAGE_MAX)
    if own_msgs:
        for off, n in own_msgs.items():
            rec[off] = n
    if 'power' in e:
        rec[9] = _int(e['power'], what + '.power', 0, 255)
    if 'sellable' in e:
        rec[11] = (rec[11] & ~1) | (0 if _bool(e['sellable'], what + '.sellable') else 1)
    if 'keep_on_loss' in e:
        rec[11] = (rec[11] & ~4) | (4 if _bool(e['keep_on_loss'], what + '.keep_on_loss') else 0)
    raw = e.get('raw')
    if raw is not None:
        if not isinstance(raw, dict):
            raise ItemError(f"{what}.raw: {{\"offset\": byte}} (offsets 0, 6, 10, 11)")
        for k, v in raw.items():
            off = _int(k, f"{what}.raw key", 0, RECORD - 1)
            if off not in (0, 4, 5, 6, 10, 11):
                raise ItemError(f"{what}.raw: offset {off} has a field of its own — use it")
            rec[off] = _int(v, f"{what}.raw.{k}", 0, 255)
    return rec


def _data(prj_or_data):
    return getattr(prj_or_data, 'data', prj_or_data) or {}


def new_items(prj_or_data):
    return list(((_data(prj_or_data).get('custom') or {}).get('items')) or [])


def _encode(markup, style, what):
    try:
        return TM.encode(markup, style)
    except TM.MarkupError as e:
        raise ItemError(f"{what}: {e}") from None


def resolve(prj_or_data, repo_root=None):
    """{'records': [bytes] x count, 'base': [id] x count, 'count': n, 'names': {id: name},
    'edited': {ids}, 'new': {id: entry}, 'texts': [(table, index, raw incl. $F0, what)],
    'messages': {(id, 'use'|'result'): message id}} — raises ItemError."""
    d = _data(prj_or_data)
    repo = repo_root or getattr(prj_or_data, 'repo_root', None)
    van = vanilla_records(repo)
    names = dict(game_names(repo))
    recs = [bytearray(r) for r in van]
    base = list(range(GAME_ITEMS))
    edited = set()
    gd = (d.get('gamedata') or {}).get('items') or {}
    if not isinstance(gd, dict):
        raise ItemError('gamedata.items: an object keyed by item id ("1"-"43")')
    for k, e in gd.items():
        if str(k).startswith('_'):
            continue
        what = f"gamedata.items.{k}"
        i = _int(k, what, 1, GAME_ITEMS - 1)
        if not isinstance(e, dict):
            raise ItemError(f"{what}: an object of item fields")
        extra = {x for x in e if not str(x).startswith('_')} - set(FIELDS) - {'comment'}
        if extra:
            raise ItemError(f"{what}: unknown field(s) {sorted(extra)} ({', '.join(FIELDS)})")
        apply_fields(recs[i], e, what)
        if bytes(recs[i]) != van[i]:
            edited.add(i)
    news = {}
    texts = []
    messages = {}
    next_msg = USE_MESSAGES
    rows = new_items(d)
    if not isinstance(rows, list):
        raise ItemError('custom.items: a list of items')
    seen_names = {}
    for n, e in enumerate(rows):
        what = f"custom.items[{n}]"
        if not isinstance(e, dict):
            raise ItemError(f"{what}: an object {{id, name, base, …}}")
        extra = {x for x in e if not str(x).startswith('_')} - set(NEW_FIELDS)
        if extra:
            raise ItemError(f"{what}: unknown field(s) {sorted(extra)}")
        i = _int(e.get('id'), what + '.id', FIRST_NEW, ID_MAX)
        what = f"custom.items[{n}] (item {i})"
        if i in news:
            raise ItemError(f"{what}: id {i} is used twice")
        b = _int(e.get('base'), what + '.base', 1, GAME_ITEMS - 1)
        name = e.get('name')
        if not isinstance(name, str) or not name.strip():
            raise ItemError(f"{what}: needs a name")
        raw_name = _encode(name, 'rows', what + '.name')
        from .gametext import glyph_count
        if glyph_count(raw_name) > NAME_MAX or any(k == 'c' for k, _b in TM._units(raw_name)):
            raise ItemError(f"{what}.name {name!r}: 1-{NAME_MAX} letters (the bag's column)")
        if name in seen_names:
            raise ItemError(f"{what}: the name {name!r} is item {seen_names[name]}'s too")
        seen_names[name] = i
        rec = bytearray(van[b])
        own = {}
        for key, off, txt in (('use', 7, 'use_text'), ('result', 8, 'result_text')):
            if e.get(txt):
                if next_msg > MESSAGE_MAX:
                    raise ItemError(f"{what}.{txt}: more than {MESSAGE_MAX + 1 - USE_MESSAGES} "
                                    "own use lines in the project")
                raw = _encode(e[txt], 'rows', f"{what}.{txt}")
                texts.append((USE_TABLE, next_msg, raw + bytes([TM.END]), f"{what}.{txt}"))
                own[off] = next_msg
                messages[(i, key)] = next_msg
                next_msg += 1
        apply_fields(rec, e, what, own)
        recs_len = len(recs)
        if i >= recs_len:
            recs += [bytearray(RECORD) for _ in range(i + 1 - recs_len)]
            base += [0] * (i + 1 - len(base))
        recs[i] = rec
        base[i] = b
        names[i] = name
        news[i] = e
        texts.append((NAME_TABLE, i, raw_name + bytes([TM.END]), what + '.name'))
        desc = e.get('description')
        if desc:
            raw_desc = _encode(desc, 'rows', what + '.description')
        else:
            # no description: the base's (the game's text, so the page is not blank)
            from .gametext import index
            x = index(repo).get('item_description', str(b))
            raw_desc = x.raw if x is not None else b''
        texts.append((DESC_TABLE, i, raw_desc + bytes([TM.END]), what + '.description'))
    # S157 (ROADMAP E9, the user: "If I set an item to permanent … user should not be
    # allowed to have more than 1 AND that item should NOT appear as a pickup in random
    # gates" + "Kept after lost battles yes"): a PERMANENT item (used-up chance 0) is
    # ONE-ONLY — and always kept after a lost battle (+11 bit 2), whatever keep_on_loss says
    one_only = set()
    for i, rec in enumerate(recs):
        if i and base[i] and rec[3] == 0:
            one_only.add(i)
            if not rec[11] & 4:
                rec[11] |= 4
                if i < GAME_ITEMS:
                    edited.add(i)
    return {'records': [bytes(r) for r in recs], 'base': base, 'count': len(recs),
            'names': names, 'edited': edited, 'new': news, 'texts': texts,
            'messages': messages, 'one_only': one_only}


def one_only(prj_or_data, repo_root=None):
    """S157: the ids of the ONE-ONLY items (used-up chance 0 = permanent): the player holds
    at most one (bag + Vault), they never lie on random gate floors / in their chests /
    as a Coliseum prize (loot.py), a shop hides one while it is held, and they are kept
    after a lost battle. The game's own: BeastTail (38) and ShinyHarp (41)."""
    try:
        return set(resolve(prj_or_data, repo_root)['one_only'])
    except ItemError:
        return set()


# S157: the line a give of a one-only item the player already holds shows instead of the
# script's "full" words (bank $77 OneOnlyLine; {ins 00} = the item's name).
RULES_KEYS = ('already_has',)
DEFAULT_ALREADY_HAS = "{hero} already\nhas a {ins 00}."
ALREADY_LINES, ALREADY_CELLS = 2, 18


def item_rules(prj_or_data):
    r = ((_data(prj_or_data).get('gamedata') or {}).get('item_rules')) or {}
    return r if isinstance(r, dict) else {}


def already_has_markup(prj_or_data):
    v = item_rules(prj_or_data).get('already_has')
    return v if isinstance(v, str) and v.strip() else DEFAULT_ALREADY_HAS


def check_rules(prj_or_data):
    """(errors, warnings) of gamedata.item_rules."""
    g = (_data(prj_or_data).get('gamedata') or {}).get('item_rules')
    if g is None:
        return [], []
    if not isinstance(g, dict):
        return ['gamedata.item_rules: an object ({"already_has": "<words>"})'], []
    extra = {k for k in g if not str(k).startswith('_')} - set(RULES_KEYS) - {'comment'}
    if extra:
        return [f"gamedata.item_rules: unknown field(s) {sorted(extra)} ({', '.join(RULES_KEYS)})"], []
    v = g.get('already_has')
    if v is not None and not isinstance(v, str):
        return ['gamedata.item_rules.already_has: words (markup)'], []
    try:
        raw = TM.encode(already_has_markup(prj_or_data), 'box')
    except TM.MarkupError as e:
        return [f"gamedata.item_rules.already_has: {e}"], []
    warn = []
    cs = TM.cells_per_line(raw, 'box')
    if cs and max(cs) > ALREADY_CELLS:
        warn.append(f"gamedata.item_rules.already_has: a line of {max(cs)} cells — the dialogue "
                    f"box is {ALREADY_CELLS} wide (with the longest item name)")
    return [], warn


def item_ids(prj_or_data, repo_root=None):
    """Every item id the project has (1-43 + its new items)."""
    try:
        r = resolve(prj_or_data, repo_root)
        return set(range(1, GAME_ITEMS)) | set(r['new'])
    except ItemError:
        return set(range(1, GAME_ITEMS)) | {e.get('id') for e in new_items(prj_or_data)
                                            if isinstance(e, dict) and isinstance(e.get('id'), int)}


def names(prj_or_data=None, repo_root=None):
    """{id: name} of every item of the project (the game's 43 + the new ones)."""
    out = {i: n for i, n in game_names(repo_root).items() if 1 <= i < GAME_ITEMS}
    if prj_or_data is not None:
        for e in new_items(prj_or_data):
            if isinstance(e, dict) and isinstance(e.get('id'), int):
                out[e['id']] = e.get('name') or f"item {e['id']}"
    return out


def check_id(prj_or_data, n, what):
    """Raise ItemError unless n is an item the project has."""
    if isinstance(n, bool) or not isinstance(n, int):
        raise ItemError(f"{what}: an item id")
    if 1 <= n < GAME_ITEMS:
        return n
    if n in {e.get('id') for e in new_items(prj_or_data) if isinstance(e, dict)}:
        return n
    raise ItemError(f"{what}: item {n} — the game's items are 1-{GAME_ITEMS - 1}; "
                    "project items are the ids in custom.items")


def warnings_for(prj_or_data, repo_root=None):
    out = []
    try:
        r = resolve(prj_or_data, repo_root)
    except ItemError:
        return out
    for table, idx, raw, what in r['texts']:
        if table == DESC_TABLE:
            cs = TM.cells_per_line(raw[:-1], 'rows')
            if cs and (len(cs) > DESC_LINES or max(cs) > DESC_CELLS):
                out.append(f"{what}: {len(cs)} line(s), the longest {max(cs)} cells — the item "
                           f"page shows {DESC_LINES} lines of {DESC_CELLS}")
    return out


def check(prj):
    """(errors, warnings)."""
    try:
        resolve(prj, getattr(prj, 'repo_root', None))
    except ItemError as e:
        return [str(e)], []
    errs, warn = check_rules(prj)
    if errs:
        return errs, []
    return [], warnings_for(prj, getattr(prj, 'repo_root', None)) + warn


def text_slots(prj_or_data, repo_root=None):
    """[(bank, table, index, raw incl. $F0, what)] — the new items' names / descriptions
    and own use lines, for the S150 text banks (gametext.resolve appends them)."""
    try:
        r = resolve(prj_or_data, repo_root)
    except ItemError:
        return []
    return [(TEXT_BANK, t, i, raw, what) for t, i, raw, what in r['texts']]


# ------------------------------------------------------------------ emit (bank $77)
def emit_lines(prj):
    """ITEM_COUNT, ItemTable (count x 12 B), ItemBaseTable (count B) for bank $77."""
    r = resolve(prj, getattr(prj, 'repo_root', None))
    nm = r['names']
    out = ["; " + "=" * 77,
           "; ITEMS (S151, generated by editor2/core/items.py from gamedata.items + custom.items,",
           "; PROJECT_COMPILER §2.59): the record of every item (entry 16 ItemRecordCopy) and",
           "; the item each one works like (wItemBase; the battle skill = it + $AF).",
           "; " + "=" * 77,
           f"ITEM_COUNT EQU {r['count']}",
           "ItemTable:   ; 12 B per item: +0 group, +1/+2 price, +3 use-up %, +4 field use,",
           "             ; +5 target, +6 -, +7 use line, +8 result line, +9 power, +10 -, +11 flags"]
    for i, rec in enumerate(r['records']):
        tag = ('new, works like ' + nm.get(r['base'][i], str(r['base'][i]))) if i in r['new'] \
            else ('edited' if i in r['edited'] else '')
        label = nm.get(i, 'none' if i == 0 else '(no item)')
        out.append("    db " + ", ".join(f"${x:02x}" for x in rec)
                   + f"   ; [{i:3d}] {label}" + (f" ({tag})" if tag else ''))
    out.append("ItemBaseTable:   ; the behaviour id of every item (the game's: itself)")
    for k in range(0, r['count'], 16):
        out.append("    db " + ", ".join(f"${x:02x}" for x in r['base'][k:k + 16]))
    # S157: the one-only items' line + the script op arities the look-ahead walks
    oo = sorted(r['one_only'])
    out += ["; S157 (ROADMAP E9): ONE-ONLY items (used-up chance 0): "
            + (", ".join(f"{i} {nm.get(i, i)}" for i in oo) or "none"),
            "; OneOnlyLine — shown instead of a give's \"full\" words when the item is one-only",
            "; and already held (gamedata.item_rules.already_has; {ins 00} = the item's name)",
            "OneOnlyLine:"]
    raw = TM.encode(already_has_markup(prj), 'box') + bytes([TM.END])
    for k in range(0, len(raw), 16):
        out.append("    db " + ", ".join(f"${x:02x}" for x in raw[k:k + 16]))
    out += arity_lines()
    return out


def arity_lines():
    """SCRIPT_OPS + ScriptArity77: the parameter words of every script op ($00-$65, from
    the handlers — script_ops.OPS / extracted/script_param_counts.json), $FF = the op ends
    the script (script_ops.TERMINAL) — bank $77 NextGive77 walks a script with them."""
    from . import script_ops as SO
    n = max(SO.OPS) + 1
    ar = [0xFF if c in SO.TERMINAL else len(SO.OPS[c].params) if c in SO.OPS else 0xFF
          for c in range(n)]
    out = [f"SCRIPT_OPS EQU ${n:02X}",
           "ScriptArity77:   ; S157: parameter words per script op ($FF = ends the script)"]
    for k in range(0, n, 16):
        out.append("    db " + ", ".join(f"${x:02x}" for x in ar[k:k + 16])
                   + f"   ; ops ${k:02X}-${min(k + 15, n - 1):02X}")
    return out


def emit_item_info(prj, warnings):
    """Region gd_item_info (bank $03 ItemInfoTable): since S151 the ORIGINAL bytes — the
    game reads the records from bank $77 (entry 16); this table is no longer read."""
    van = vanilla_records(getattr(prj, 'repo_root', None))
    nm = game_names(getattr(prj, 'repo_root', None))
    out = ["ItemInfoTable:  ; 44 x 12 B — the ORIGINAL records, NOT READ since S151 (the game",
           "                ; copies every record from bank $77 ItemTable: entry 16 ItemRecordCopy)"]
    for i, rec in enumerate(van):
        out.append("    db " + ", ".join(f"${x:02x}" for x in rec) + f"   ; [{i:2d}] {nm.get(i, 'none')}")
    return "\n".join(out) + "\n"


# ------------------------------------------------------------------ editor helpers
def describe_effect(base, power):
    _k, txt = EFFECTS.get(base, ('?', '?'))
    return txt.format(power=power)


def battle_skill(base):
    """The battle skill a base item uses (bank $50: base + $AF)."""
    return (base + 0xAF) & 0xFF


def free_id(prj_or_data):
    used = {e.get('id') for e in new_items(prj_or_data) if isinstance(e, dict)}
    for i in range(FIRST_NEW, ID_MAX + 1):
        if i not in used:
            return i
    return None
