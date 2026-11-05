#!/usr/bin/env python3
"""audit_island_flags.py — S166 (ROADMAP Phase 2 "Preserved-systems flag-dependency audit", half
(a)): every event flag the original game's scripts of each PRESERVED ISLAND (EDITOR_DESIGN §1:
the Arena, the Starry Shrine, the Library, the Vault, the gate floor's Item Shop) test, and where
the game sets each one — inside the island, or only elsewhere in the original story (a new
campaign that stops playing that story never sets it: satisfy it, strip the test, or re-author;
the editor's Progression & Flags tab lists such checks as "waiting for the original game's
progress", S124).

Read from the ROM's own scripts through editor2/core/cutscenes.Catalogue (the S118 decoder, the
same one the Flags tab walks) — op $00 / $01 test, $02 / $03 clear / set — plus the engine-side
setters the S124 code-read lists (flag_index.ENGINE_SETTERS when present). Prints a markdown
table per island (SIDEQUEST_MAP "Preserved islands: the flags they read (S166)").

    python3 tools/audit_island_flags.py [--rom data/DWM-original.gbc]
"""
import argparse
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

ISLANDS = [('Arena', (0x06, 0x07, 0x5D, 0x5E)), ('Starry Shrine', (0x09, 0x08)),
           ('Library', (0x12, 0x13)), ('Vault', (0x0F,)), ('Item Shop (gate floor)', (0x50,))]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', default=os.path.join(REPO, 'data', 'DWM-original.gbc'))
    a = ap.parse_args()
    from editor2.core.cutscenes import Catalogue
    from editor2.core.flag_index import FLAG_OPS, GAME_ENGINE_ON
    cat = Catalogue(open(a.rom, 'rb').read())
    tests, sets = {}, {}                 # flag -> {map ids}
    for m in cat.map_types():
        for sc in cat.scripts(m):
            if sc is None:
                continue
            for st in sc.steps.values():
                if st.code in FLAG_OPS and st.params:
                    f = st.params[0]
                    if st.code in (0x00, 0x01):
                        tests.setdefault(f, set()).add(m)
                    elif st.code == 0x03:
                        sets.setdefault(f, set()).add(m)
    name = cat.rooms.name
    island_of = {m: isl for isl, ms in ISLANDS for m in ms}
    for isl, maps in ISLANDS:
        reads = sorted(f for f, ms in tests.items() if ms & set(maps))
        print(f'\n#### {isl} (map{"s" if len(maps) > 1 else ""} '
              + ' / '.join(f'${x:02X}' for x in maps) + f') — {len(reads)} flags tested\n')
        print('| flag | tested in | set by the game in | for a new campaign |')
        print('|---|---|---|---|')
        for f in reads:
            where_t = ', '.join(f'${x:02X}' for x in sorted(tests[f] & set(maps)))
            st = sorted(sets.get(f, ()))
            inside = [x for x in st if x in maps]
            outside = [x for x in st if x not in maps]
            other = sorted({island_of[x] for x in outside if x in island_of})
            story = [x for x in outside if x not in island_of]
            if f in GAME_ENGINE_ON:
                verdict = 'set by the game\'s code: ' + GAME_ENGINE_ON[f]
            elif not st:
                verdict = 'never set by a script (engine-set or never true — EVENT_FLAGS)'
            elif not story and not other:
                verdict = 'self-contained (the island sets it)'
            elif not story:
                verdict = 'set by another kept island: ' + ', '.join(other)
            elif inside or other:
                verdict = 'set by a kept island AND by the story'
            else:
                verdict = 'ORIGINAL STORY ONLY — satisfy, strip or re-author'
            setw = ', '.join(f'${x:02X} {name(x)}' for x in st[:4]) + (' …' if len(st) > 4 else '')
            print(f'| `${f:04X}` | {where_t} | {setw or "—"} | {verdict} |')


if __name__ == '__main__':
    try:
        main()
    except BrokenPipeError:
        pass
