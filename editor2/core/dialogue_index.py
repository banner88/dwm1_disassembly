"""dialogue_index.py — every text the game can show, searchable (S108, ROADMAP
P3.10 part 3; the editor's read-only Dialogue tab — the seed of P3.6).

Source: extracted/dialogue.json (tools/dump_dialogue.py): all 2,560 text ids
(the id -> bank / address resolution MEASURED in PyBoy through the game's own
TextBankDispatch, incl. the overflow banks) + the text tables that are not ids
(battle messages, field / item / spell messages, skill and monster
descriptions). Read-only: renaming a monster changes every place the game
prints the name through the name table (battle, menus, library, breeding,
joins, recipe lines) but NOT words written into dialogue — this index is how
an author finds those lines (user S108: "pull all dialogue so I can inspect
to see if needs changes or not").

Mentions: a species is mentioned where its name appears as a word, also as a
plural ("DrakSlimes") or a possessive ("DrakSlime's"); case-sensitive (the
names are CamelCase, so the generic word "slime" is not a mention of Slime).
"""

import json
import os
import re

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH = os.path.join(REPO, 'extracted', 'dialogue.json')

_CACHE = {}


def load(path=PATH):
    """[{'key', 'kind', 'where', 'ref', 'text', 'raw', 'same_as'}] — text ids
    first (id order), then the tables in dialogue.json order."""
    if path in _CACHE:
        return _CACHE[path]
    d = json.load(open(path, encoding='utf-8'))
    titles = {t['source']: t['title'] for t in d.get('tables', [])}
    out = []
    for e in d['text_ids']:
        if e.get('suspect'):
            continue
        out.append({'key': e['id'], 'kind': 'text id', 'ref': e['id'],
                    'where': f"{e['bank']}:{e['addr']}", 'text': e['text'],
                    'raw': e.get('raw'), 'same_as': e.get('same_as')})
    for e in d['table_entries']:
        if not e.get('text'):
            continue
        out.append({'key': f"{e['source']}:{e['index']}",
                    'kind': titles.get(e['source'], e['source']),
                    'ref': f"#{e['index']}", 'where': f"{e['bank']}:{e['addr']}",
                    'text': e['text'], 'raw': e.get('raw'), 'same_as': None})
    _CACHE[path] = out
    return out


def kinds(entries=None):
    seen = []
    for e in entries or load():
        if e['kind'] not in seen:
            seen.append(e['kind'])
    return seen


def name_pattern(name):
    """Regex for a species name as a word (+ s / es / 's)."""
    return re.compile(r"(?<![A-Za-z0-9])" + re.escape(name) + r"(?:s|es|'s)?(?![A-Za-z0-9])")


def mentions(name, entries=None, unique=True):
    """Entries whose text mentions `name`. unique=True drops text ids that
    show the same string as an earlier id (they are listed as `same_as`)."""
    if not name:
        return []
    pat = name_pattern(name)
    return [e for e in (entries or load())
            if (not unique or not e['same_as']) and pat.search(e['text'])]


def flat(text):
    """The text on one line (line / box breaks -> spaces, no wait arrows) —
    what a search matches, so a phrase split over two lines is still found."""
    return re.sub(r'\s+', ' ', text.replace(' ▼', ' ')).strip()


def search(query, entries=None, kind=None, unique=True):
    """Case-insensitive substring search over text / id / address."""
    q = re.sub(r'\s+', ' ', (query or '').strip().lower())
    out = []
    for e in entries or load():
        if unique and e['same_as']:
            continue
        if kind and e['kind'] != kind:
            continue
        if not q or q in e.setdefault('_flat', flat(e['text']).lower()) or \
                q in e['key'].lower() or q in e['where'].lower():
            out.append(e)
    return out


def species_mentions(names, entries=None):
    """{name: [entries]} for a set of names (the editor's per-monster count)."""
    return {n: mentions(n, entries) for n in names if n}


def export_text(entries, path):
    """Write entries as a plain text file (one block per text) — returns count."""
    with open(path, 'w', encoding='utf-8') as f:
        for e in entries:
            f.write(f"=== {e['kind']} {e['ref']}   ({e['where']})"
                    + (f"   [same text as {e['same_as']}]" if e['same_as'] else '') + "\n")
            f.write(e['text'] + "\n\n")
    return len(entries)
