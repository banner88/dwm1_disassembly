#!/usr/bin/env python3
"""census_gate_floor_types.py — what each of the 16 MAZE floor types looks like, and
which rows of the three floor-type tables every vanilla gate uses (S120, ROADMAP P3.7b
part 2: "private floor-type rows per gate … the maze look in the editor").

GATE_GENERATION §1-§3: a gate's GateFloorDataTable row ($16:$70A6) bytes 0-2 pick a ROW
of FloorTypeSelectionTable ($71A6, 16 x 16) / 2 ($72A6, 16 x 8) / 3 ($7326, 16 x 16);
each row is a cumulative-percent list ($00 = skip, $64 = guaranteed) that
SelectFloorType ($16:$5FC0) rolls into an INDEX: table 1 -> the maze floor type (= wMapID
inside the dive: the maze tileset $00:$2A5D + palette $17:$51F5), table 2 -> the special
room of floors 3, 6, 9 … (the `rst $00` list after $16:$5C31), table 3 -> the contents mix
(SaveBrd_6432 features; the treasure-room chests read FloorLayoutData + row * 48).

Measured: PyBoy, the ORIGINAL ROM, a new game, then the game's own gate entry (exit
mailbox $C96D = gate 1, $C96E = 1 -> floor 1, never special) with a code hook right after
the maze path's SelectFloorType call ($16:$5BD2) that sets A = the floor type; a picture
of the arrival screen per type -> extracted/gate_floor_types/ft_NN.png.

  python3 tools/census_gate_floor_types.py             # measure + write the JSON + PNGs
  python3 tools/census_gate_floor_types.py --selftest  # JSON tables / gate rows == ROM (no PyBoy)
"""
import hashlib
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
ROM_PATH = os.path.join(REPO, 'data', 'DWM-original.gbc')
OUT_DIR = os.path.join(REPO, 'extracted', 'gate_floor_types')
OUT = os.path.join(OUT_DIR, 'gate_floor_types.json')
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'
GATE_TABLE = 0x70A6
TABLES = {'maze': (0x71A6, 16, 16), 'special': (0x72A6, 16, 8), 'contents': (0x7326, 16, 16)}
HOOK = (0x16, 0x5BD2)             # ld [wFloorType1], a — right after SelectFloorType (maze path)
# the `rst $00` list after $16:$5C31 (read S120): what each special pick serves
SPECIALS = [
    'Treasure room ($5A / $5B / $5C at random) — the chests from the gate\'s contents row',
    'Treasure room ($5A / $5B / $5C at random) — one chest, one rare item',
    'Forest maze ($53)',
    'Priest ($51)',
    'Item shop ($50)',
    'Coliseum ($52) — battles',
    'Maze 1 / 2 / 3 ($57-$59 at random)',
    'Conveyor maze 1 / 2 / 3 ($54-$56 at random)',
]


def bank16(rom, a, n):
    o = 0x16 * 0x4000 + a - 0x4000
    return rom[o:o + n]


def odds(row):
    """A cumulative-percent row -> [(index, percent)] as SelectFloorType rolls it."""
    out, prev = [], 0
    for i, v in enumerate(row):
        if v == 0:
            continue
        out.append((i, v - prev))
        prev = v
        if v >= 0x64:
            break
    return out


def tables(rom):
    out = {}
    for k, (a, n, w) in TABLES.items():
        rows = [list(bank16(rom, a + w * r, w)) for r in range(n)]
        out[k] = [{'row': r, 'bytes': rows[r], 'odds': odds(rows[r])} for r in range(n)]
    gt = bank16(rom, GATE_TABLE, 32 * 8)
    gates = [{'gate': g, 'maze_row': gt[8 * g], 'special_row': gt[8 * g + 1],
              'contents_row': gt[8 * g + 2], 'depth': gt[8 * g + 7]} for g in range(32)]
    return out, gates


def measure(rom_path):
    from tools.pyboy_harness import adv, boot, tap, to_bedroom
    p = boot(rom_path)
    if not to_bedroom(p):
        raise SystemExit('the new game did not reach the bedroom')
    adv(p, 200)
    import io
    st = io.BytesIO()
    p.save_state(st)
    m = p.memory
    want = [None]

    def cb(_ctx):
        if want[0] is not None:
            p.register_file.A = want[0]
    p.hook_register(*HOOK, cb, None)
    shots = {}
    for t in range(16):
        st.seek(0)
        p.load_state(st)
        want[0] = t
        m[0xD8D7] = 0
        m[0xC96D], m[0xC96E] = 1, 1             # the portal exit's own bytes: gate 1, gate flag
        m[0xC96C] = 1
        m[0xC88F] = 1
        got = None
        for f in range(2400):
            m[0xCA39], m[0xCA3A] = 0xFF, 0x7F   # no random battle (no party in a new game)
            p.tick()
            if m[0xC969] and m[0xC968] == t and m[0xC88A] == 1 and m[0xC88F] == 0 and f > 30:
                got = f
                break
        for _ in range(300):
            m[0xCA39], m[0xCA3A] = 0xFF, 0x7F
            p.tick()
        path = os.path.join(OUT_DIR, f'ft_{t:02d}.png')
        p.screen.image.convert('RGB').save(path)
        shots[t] = {'png': os.path.relpath(path, REPO), 'frames': got,
                    'map': m[0xC968], 'in_gate': m[0xC969]}
    p.stop()
    return shots


def selftest():
    if not os.path.exists(ROM_PATH):
        print('SKIP: no ROM')
        return 0
    rom = open(ROM_PATH, 'rb').read()
    d = json.load(open(OUT))
    tb, gates = json.loads(json.dumps(tables(rom)))     # tuples -> lists, as stored
    ok = d['tables'] == tb and d['gates'] == gates and len(d['maze_types']) == 16 and \
        all(os.path.exists(os.path.join(REPO, x['png'])) for x in d['maze_types'])
    print(('OK' if ok else 'FAIL') + ': gate_floor_types.json == ROM (3 tables, 32 gate rows, '
          '16 floor-type pictures)')
    return 0 if ok else 1


def main():
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    rom = open(ROM_PATH, 'rb').read()
    if hashlib.md5(rom).hexdigest() != ORIGINAL_MD5:
        sys.exit('ERROR: data/DWM-original.gbc is not the original ROM')
    os.makedirs(OUT_DIR, exist_ok=True)
    tb, gates = tables(rom)
    shots = measure(ROM_PATH)
    uses = {k: {} for k in TABLES}
    for g in gates:
        for k in TABLES:
            uses[k].setdefault(g[k + '_row'], []).append(g['gate'])
    data = {
        '_generator': ('tools/census_gate_floor_types.py (S120) from data/DWM-original.gbc '
                       f'{ORIGINAL_MD5}: tables + gate rows read from bank $16; pictures = PyBoy, '
                       'a new game, gate 1 floor 1 with the maze floor type forced at $16:$5BD2'),
        'tables': tb,
        'gates': gates,
        'rows_used_by': {k: {str(r): v for r, v in sorted(u.items())} for k, u in uses.items()},
        'maze_types': [dict(type=t, **shots[t]) for t in range(16)],
        'specials': SPECIALS,
    }
    with open(OUT, 'w') as f:
        json.dump(data, f, indent=1)
        f.write('\n')
    bad = [t for t in range(16) if shots[t]['map'] != t or not shots[t]['in_gate']]
    print(f'wrote {OUT}: 16 floor types ({"all reached" if not bad else f"NOT reached: {bad}"})')


if __name__ == '__main__':
    main()
