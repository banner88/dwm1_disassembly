"""gametext.py — editing the GAME'S OWN texts (S150, ROADMAP P3.6 / Phase F
T-author; PROJECT_COMPILER §2.58, TEXT_SYSTEM "Edited game text (S150)").

Headless (no Qt).

THE ENGINE (patches/bank_000.asm + templates/bank_060_head.asm entry 14 +
templates/text_home.asm / text_bank.asm): every text the game shows or copies
is found by ROM0 SaveBankAndSwitch — level 1 reads a mode's per-id TABLE in the
current bank, level 2 the text's address at table + 2 * id (TEXT_SYSTEM). Its
level-1 read now far-calls bank $60 entry 14, which forwards to the text HOME
bank (the first text bank $80+) when the build has edited texts: an edited
text is keyed by its POINTER SLOT (the table's bank, the table, the id) and
can be ANY length in ANY bank — the text engine reads every byte from bank
[$C824], which the hook sets; a COPY (RunTextHandler, e.g. names copied into a
buffer) is copied by the text's own bank. Unedited texts read exactly as
before; a project without edits builds bank $60 entry 14 = the S105 nickname
redirect + `TEXT_OVR_HOME EQU 0`.

THE TEXTS (extracted/dialogue.json, tools/dump_dialogue.py — measured):
  * 'dialogue' — the 2,560 text ids $0000-$09FF (people, story, signs,
    questions), each with the slot the game reads it through (measured in
    PyBoy: SaveBankAndSwitch hooked during TextBankDispatch);
  * the tables (`TABLES` there): battle messages + treats / veils / commands /
    the BeastTail, level-up and spell lines, the battle tutorial; item names /
    descriptions / use lines; field messages + menu words, personalities, the
    families' default names, Watabou; the credits and "TO BE CONTINUED".
    The monster / skill descriptions are listed but OWNED by the Monsters /
    Skills tabs (gamedata.monster_text / gamedata.skills).

SCHEMA (sparse; keys = text id "$0123" for dialogue, the row number for a
table; values = textmark markup — editor2/core/textmark.py):

  "gamedata": {"text": {
      "dialogue":   {"$0000": "{high}Milayou:Milly!\\nWake up!▼\\n…"},
      "item_name":  {"1": "Herb"},
      "credits_end": {"0": "{ED}…THE END"}}}

Ids that showed the SAME string in the original game are edited as one by the
editor (it writes the same markup to each); the compiler stores one copy.

LAYOUT: text banks are taken from Project._take_ext_bank('texts') after the
stream / place / animation / song / battle banks. The home bank holds the
lookup (text_home.asm), its copier (text_bank.asm), TextOvrBanks (32 B),
TextOvrDir (6 B per edited table + 1), the lists (4 B per edited slot), then
texts first fit; further text banks hold their copier + texts.
"""

import json
import os

from . import textmark as TM

BANK_SIZE = 0x4000
DIALOGUE = 'dialogue'
GROUPS = [('dialogue', 'Dialogue'), ('battle', 'Battle'), ('items', 'Items'),
          ('menus', 'Menus & field'), ('credits', 'Credits')]
# a bank's fixed part = addr(TextOvrData_T<bank>) - $4000, measured from the S150
# test build's game.sym (self-ID + 2 entry words + the pinned block(s))
TEXT_HOME_FIXED = 178
TEXT_BANK_FIXED = 21
MARKER = 'TEXT DATA (generated'
# names the game copies into fixed fields / buffers: at most this many glyphs
# (the longest original of the table — the bag list, the INFO page and the
# naming screen draw them in fixed columns)
MAX_GLYPHS = {'item_name': 9, 'personality': 9, 'family_name': 4}


class GameTextError(ValueError):
    pass


def _repo(repo_root=None):
    return repo_root or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


_INDEX = {}


class Entry:
    """One text of the original game."""
    __slots__ = ('source', 'key', 'bank', 'table', 'index', 'addr', 'raw', 'style',
                 'group', 'owner', 'title', 'same', 'inside', 'first', '_markup')

    @property
    def slot(self):
        return (self.bank, self.table + 2 * self.index)

    def markup(self):
        """The original text as markup (cached)."""
        if self._markup is None:
            self._markup = TM.decode(self.raw, self.style)
        return self._markup


class Index:
    """Every editable text of the original game (dialogue.json), by
    (source, key); key = '$0123' (dialogue) or the row number as a string."""

    def __init__(self, path):
        d = json.load(open(path, encoding='utf-8'))
        self.tables = {t['source']: t for t in d['tables']}
        self.entries = {}
        self.order = []
        style = d.get('id_style', 'box')
        for e in d['text_ids']:
            if e.get('suspect') or e.get('raw') is None or 'table' not in e:
                continue
            self._add(DIALOGUE, e['id'], e, style, 'dialogue', None, 'text ids')
        for e in d['table_entries']:
            if e.get('raw') is None:
                continue
            t = self.tables[e['source']]
            self._add(e['source'], str(e['index']), e, t.get('style', 'rows'),
                      t.get('group', 'menus'), t.get('owner'), t['title'])
        by_addr = {}
        for k in self.order:
            x = self.entries[k]
            by_addr.setdefault((x.source == DIALOGUE, x.bank, x.addr), []).append(k)
        for ks in by_addr.values():
            for k in ks:
                self.entries[k].same = [j for j in ks if j != k]
                self.entries[k].first = k == ks[0]     # the copy a list shows

    def _add(self, source, key, e, style, group, owner, title):
        x = Entry()
        x.source, x.key = source, key
        x.bank = int(e['bank'][1:], 16)
        x.table = int(e['table'][1:], 16)
        x.index = int(e['index'])
        x.addr = int(e['addr'][1:], 16)
        x.raw = bytes.fromhex(e['raw'])
        x.style, x.group, x.owner, x.title = style, group, owner, title
        x.same = []
        x.first = True
        x._markup = None
        x.inside = e.get('inside')
        self.entries[(source, key)] = x
        self.order.append((source, key))

    def get(self, source, key):
        return self.entries.get((source, str(key)))

    def in_group(self, group):
        return [self.entries[k] for k in self.order if self.entries[k].group == group]


def index(repo_root=None):
    path = os.path.join(_repo(repo_root), 'extracted', 'dialogue.json')
    if path not in _INDEX:
        _INDEX[path] = Index(path)
    return _INDEX[path]


def _gd(prj_or_data):
    data = getattr(prj_or_data, 'data', prj_or_data) or {}
    return data.get('gamedata') or {}


def edits(prj_or_data):
    """{(source, key): markup} of the project (gamedata.text)."""
    t = _gd(prj_or_data).get('text') or {}
    out = {}
    if not isinstance(t, dict):
        raise GameTextError("gamedata.text: an object {source: {key: text}}")
    for src, rows in t.items():
        if str(src).startswith('_'):
            continue
        if not isinstance(rows, dict):
            raise GameTextError(f"gamedata.text.{src}: an object {{key: text}}")
        for k, v in rows.items():
            if str(k).startswith('_'):
                continue
            out[(src, _norm_key(src, k))] = v
    return out


def _norm_key(src, k):
    if src == DIALOGUE:
        s = str(k).strip().upper().lstrip('$')
        try:
            return '$%04X' % int(s, 16)
        except ValueError:
            raise GameTextError(f"gamedata.text.dialogue: {k!r} is not a text id ($0000-$09FF)") from None
    try:
        return str(int(k))
    except (TypeError, ValueError):
        raise GameTextError(f"gamedata.text.{src}: {k!r} is not a row number") from None


def glyph_count(raw):
    return sum(1 for kind, _b in TM._units(raw) if kind == 'g')


def resolve(prj_or_data, repo_root=None):
    """[(entry, bytes incl. the closing $F0)] in a stable order; raises
    GameTextError on the first text the game cannot take."""
    ix = index(repo_root)
    out = []
    for (src, key), markup in sorted(edits(prj_or_data).items(), key=_order(ix)):
        x = ix.get(src, key)
        what = f"gamedata.text.{src}[{key}]"
        if x is None:
            if src not in ix.tables and src != DIALOGUE:
                raise GameTextError(f"{what}: no such text kind (kinds: dialogue, "
                                    f"{', '.join(s for s in ix.tables if not ix.tables[s].get('owner'))})")
            raise GameTextError(f"{what}: no such text in the game")
        if x.owner:
            raise GameTextError(f"{what}: edit this text on the {x.owner} tab "
                                f"(gamedata.{'skills' if x.owner == 'Skills' else 'monster_text'})")
        try:
            raw = TM.encode(markup, x.style)
        except TM.MarkupError as e:
            raise GameTextError(f"{what}: {e}") from None
        cap = MAX_GLYPHS.get(src)
        if cap is not None and glyph_count(raw) > cap:
            raise GameTextError(f"{what}: {glyph_count(raw)} letters — at most {cap} "
                                f"(the game draws it in a {cap}-cell field)")
        if cap is not None and any(k == 'c' for k, _b in TM._units(raw)):
            raise GameTextError(f"{what}: a name takes letters only (no codes)")
        out.append((x, raw + bytes([TM.END])))
    # S151 (ROADMAP E9): the project's NEW items' names / descriptions (rows 44+) and
    # their own use lines (item_use_message 48+) — slots past the game's tables, served
    # by the same lookup (editor2/core/items.py validates them; errors are its own)
    from . import items as IT
    src_of = {IT.NAME_TABLE: 'item_name', IT.DESC_TABLE: 'item_description',
              IT.USE_TABLE: 'item_use_message'}
    for bank, table, idx, raw, what in IT.text_slots(prj_or_data, repo_root):
        x = Entry()
        x.source, x.key = src_of[table], str(idx)
        x.bank, x.table, x.index, x.addr = bank, table, idx, 0
        x.raw, x.style, x.group, x.owner, x.title = raw[:-1], 'rows', 'items', 'Items', what
        x.same, x.first, x._markup, x.inside = [], True, None, None
        out.append((x, raw))
    # S153 (ROADMAP E5): the credits' pages (custom.credits, editor2/core/ending.py) —
    # every role / names text that differs from the game's, and the rows past 26
    from . import ending as EN
    src_of = {EN.ROLE_TABLE: 'credits_role', EN.NAME_TABLE: 'credits_name'}
    for bank, table, idx, raw, what in EN.text_slots(prj_or_data, repo_root):
        x = Entry()
        x.source, x.key = src_of[table], str(idx)
        x.bank, x.table, x.index, x.addr = bank, table, idx, 0
        x.raw, x.style, x.group, x.owner, x.title = raw[:-1], 'rows', 'credits', 'Credits', what
        x.same, x.first, x._markup, x.inside = [], True, None, None
        out.append((x, raw))
    return out


def _order(ix):
    pos = {k: i for i, k in enumerate(ix.order)}
    return lambda kv: (pos.get(kv[0], 1 << 30), kv[0])


def warnings_for(x, raw):
    """Soft warnings (the editor shows them; the build too): a box line past
    18 cells. (Tables: no fixed width is known for every window yet.)"""
    out = []
    if x.style == 'box':
        cs = TM.cells_per_line(raw[:-1] if raw.endswith(b'\xf0') else raw, 'box')
        if cs and max(cs) > 18:
            out.append(f"{x.source} {x.key}: a line of {max(cs)} cells — a box line holds 18 "
                       "(the rest is lost or scrolls; TEXT_SYSTEM \"Text boxes\")")
    return out


def check(prj):
    """(errors, warnings) of gamedata.text."""
    errors, warns = [], []
    try:
        for x, raw in resolve(prj, getattr(prj, 'repo_root', None)):
            warns += warnings_for(x, raw)
    except GameTextError as e:
        errors.append(str(e))
    return errors, warns


# ------------------------------------------------------------------ the plan
def suffix(bank):
    return f"_T{bank:02X}"


def text_bank_file(bank):
    return f"bank_{bank:03x}.asm"


def _label(x):
    k = x.key.lstrip('$')
    return f"TextOvr_{x.source}_{k}"


def plan(prj):
    """Where every edited text lives (cached on the Project; stream_plan drops it).
    {'home': bank or 0, 'banks': [bank, ...], 'rows': [(bank, table, [(index, label)])],
     'texts': {bank: [(label, bytes, [entries])]}, 'used': {bank: n}, 'count': slots}"""
    got = getattr(prj, '_text_plan', None)
    if got is not None:
        return got
    items = resolve(prj, getattr(prj, 'repo_root', None))
    out = {'home': 0, 'banks': [], 'rows': [], 'texts': {}, 'used': {}, 'count': len(items)}
    if not items:
        prj._text_plan = out
        return out
    # unique texts (identical bytes stored once)
    uniq, label_of = [], {}
    for x, raw in items:
        if raw not in label_of:
            label_of[raw] = _label(x)
            uniq.append((label_of[raw], raw, [x]))
        else:
            for u in uniq:
                if u[0] == label_of[raw]:
                    u[2].append(x)
    rows = {}
    for x, raw in items:
        rows.setdefault((x.bank, x.table), []).append((x.index, label_of[raw]))
    row_list = sorted((b, t, sorted(v)) for (b, t), v in rows.items())
    for b, t, v in row_list:
        if len({i for i, _l in v}) != len(v):
            raise GameTextError(f"bank ${b:02X} table ${t:04X}: two edits of one slot")
        if len(v) > 256:
            raise GameTextError(f"bank ${b:02X} table ${t:04X}: {len(v)} rows")
    dir_bytes = 32 + 6 * len(row_list) + 1 + 4 * len(items)
    # the banks: battles etc. number first
    from . import battles as BT
    BT.plan(prj)
    taken0 = list(getattr(prj, '_ext_taken', None) or [])
    try:
        home = prj._take_ext_bank('texts')
        banks = [home]
        used = {home: TEXT_HOME_FIXED + dir_bytes}
        if used[home] > BANK_SIZE:
            raise GameTextError(f"the text home bank: {used[home]} bytes of lookup tables")
        texts = {home: []}
        for label, raw, xs in uniq:
            if len(raw) > BANK_SIZE - TEXT_BANK_FIXED:
                raise GameTextError(f"{xs[0].source} {xs[0].key}: {len(raw)} bytes — one text "
                                    "must fit one bank")
            for b in banks:
                if used[b] + len(raw) <= BANK_SIZE:
                    break
            else:
                b = prj._take_ext_bank('texts')
                banks.append(b)
                used[b] = TEXT_BANK_FIXED
                texts[b] = []
            texts[b].append((label, raw, xs))
            used[b] += len(raw)
    except Exception:
        prj._ext_taken = taken0
        raise
    out.update({'home': home, 'banks': banks, 'rows': row_list, 'texts': texts, 'used': used})
    prj._text_plan = out
    return out


def text_bank_files(prj):
    return {b: text_bank_file(b) for b in plan(prj)['banks']}


def bank60_lines(prj):
    p = plan(prj)
    return [f"TEXT_OVR_HOME EQU ${p['home']:02X}   ; S150: the text home bank (0 = no edited "
            "game text in this build; editor2/core/gametext.py)"]


def _db_bytes(raw):
    out, line = [], []
    for b in raw:
        line.append(f"${b:02X}")
        if len(line) == 16:
            out.append("    db " + ", ".join(line))
            line = []
    if line:
        out.append("    db " + ", ".join(line))
    return out


def emit_text_bank(prj, bank):
    from .emitters import template
    p = plan(prj)
    T = suffix(bank)
    home = bank == p['home']
    lines = ["; " + "=" * 77,
             f"; BANK ${bank:02X} — a TEXT bank (S150, ROADMAP P3.6; GENERATED by",
             "; editor2/core/gametext.py from gamedata.text — do not hand-edit): the",
             "; project's edits of the game's own texts" + (" + the lookup (the HOME bank)." if home else "."),
             "; TEXT_SYSTEM \"Edited game text (S150)\", PROJECT_COMPILER §2.58.",
             "; " + "=" * 77, "",
             f'SECTION "ROM Bank ${bank:03X}", ROMX[$4000], BANK[${bank:02X}]', "",
             f"    db ${bank:02X}                          ; bank self-ID at $4000 (load-bearing)",
             (f"    dw TextOvrFind{T}                 ; entry 0 — the lookup (bank $60 entry 14)"
              if home else f"    dw TextOvrCopy{T}                 ; entry 0 — (unused; keeps entry 1's number)"),
             f"    dw TextOvrCopy{T}                 ; entry 1 — copy an edited text here to [$C837]",
             ""]
    blocks = []
    if home:
        blocks.append(template('text_home.asm'))
    blocks.append(template('text_bank.asm'))
    for blk in blocks:
        text = blk.replace('{T}', T)
        if '{T}' in text:
            raise RuntimeError("text template: an unreplaced {T}")
        lines += [text.rstrip('\n'), ""]
    lines += ["; " + "-" * 77, f"; {MARKER} — bank ${bank:02X})", "; " + "-" * 77,
              f"TextOvrData{T}:"]
    if home:
        bits = [0] * 32
        for b, _t, _v in p['rows']:
            bits[b >> 3] |= 1 << (b & 7)
        lines.append(f"TextOvrBanks{T}:   ; bit (bank & 7) of byte (bank >> 3): a bank with an edited table")
        lines += _db_bytes(bytes(bits))
        lines.append(f"TextOvrDir{T}:   ; [db bank, dw table, dw list, db rows] per edited table, bank $00 ends")
        for k, (b, t, v) in enumerate(p['rows']):
            lines.append(f"    db ${b:02X}\n    dw ${t:04X}, TextOvrList{T}_{k}\n    db {len(v) & 0xFF}"
                         f"   ; {len(v)} edited")
        lines.append("    db $00")
        for k, (b, t, v) in enumerate(p['rows']):
            lines.append(f"TextOvrList{T}_{k}:   ; bank ${b:02X} table ${t:04X}: [db id, db bank, dw text]")
            for i, lab in v:
                lines.append(f"    db {i}, BANK({lab})\n    dw {lab}")
    for label, raw, xs in p['texts'].get(bank, []):
        who = ', '.join(f"{x.source} {x.key}" for x in xs[:6]) + (' …' if len(xs) > 6 else '')
        lines.append(f"{label}:   ; {who}")
        lines += _db_bytes(raw)
    return "\n".join(lines) + "\n"


def emit_text_banks(prj, warnings):
    """multi:text_banks — one whole file per text bank $80+ (none without edits)."""
    try:
        p = plan(prj)
    except GameTextError:
        return {}                     # reported by the validator
    return {f"file:patches/{text_bank_file(b)}": emit_text_bank(prj, b) for b in p['banks']}


# ------------------------------------------------------------------ editor helpers
def set_edit(data, source, key, markup):
    """Write (or with markup None remove) one edit into a project dict."""
    gd = data.setdefault('gamedata', {})
    t = gd.setdefault('text', {})
    rows = t.setdefault(source, {})
    k = _norm_key(source, key)
    if markup is None:
        rows.pop(k, None)
        if not rows:
            t.pop(source, None)
        if not t:
            gd.pop('text', None)
    else:
        rows[k] = markup
