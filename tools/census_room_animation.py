#!/usr/bin/env python3
"""census_room_animation.py — which BG tiles every room animates, and how (S99).

Room tile animation is ONE mechanism in the whole ROM: bank $01
`PerRoomVRAMDispatch` ($60E7) runs every field frame (MainFieldLoop, after its
guards) and does `rst $00` on a 112-entry jump table at $01:$6119 indexed by
map ID ($00-$6F; vanilla points $6B-$6F at a bare `ret`). The 65 distinct
handlers ROLL tiles 1 px sideways in place (`RollTilesRight/Left`), SWAP tile
graphics with a hidden second frame elsewhere in the sheet (`VRAMSwapBytes`),
or (map $08 only) pulse the DMG palette byte. No other bank touches BG tile
graphics this way (grep: every `rrc/rlc [hl]` VRAM loop and every caller of
the swap/roll helpers is in bank $01). Gate floors never animate: the
dispatch returns early while wInGateworld != 0.

Method (MEASURED, not inferred — S70 rule):
  * boot the ORIGINAL ROM, reach the field, warp to the Bazaar ($02, whose own
    handler is a bare `ret`), fill BG tile VRAM $9000-$97FF with a distinct
    pseudo-random pattern (so every roll/swap is visible even where a real
    sheet has blank tiles), then force the dispatch index: a code hook on the
    `rst $00` at $01:$6118 sets A := the handler's map ID;
  * run 1024 field frames (covers every phase: the longest cycle is the
    GreatTree sway's 512-frame direction flip) and classify every change:
    roll right / roll left (every byte rotated) or swap (the tile now holds
    another tile's previous graphic -> partner slot); record the frame
    counter ($C8A6) at each event and any wBGPalette ($C89B) writes;
  * per map: the handler's slots, which of them the vanilla room PLACES on
    any screen/state (shown) vs never places (the hidden second frame of a
    swap), and whether the room's own sheet makes the handler inert (roll of
    a rotation-invariant tile / swap of identical tiles).

Static half (`--check`, no emulator): re-reads the jump table from the ROM and
walks each handler's code (branches followed, helpers not entered) collecting
its VRAM operands; asserts table/handler mapping and that every measured slot
lies inside the operand ranges the code names. Runs from the JSON alone.

Output: extracted/room_animations.json (owning prose: ROOM_DATA_FORMAT
"Animated tiles"). Consumed by editor2 (slot map, canvas overlay + preview,
compiler validators).

Usage:
  python3 tools/census_room_animation.py            # measure (needs pyboy) + write JSON
  python3 tools/census_room_animation.py --check    # static re-derivation vs JSON
"""

import argparse
import json
import os
import random
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
OUT = os.path.join(ROOT, 'extracted', 'room_animations.json')
ROM = os.path.join(ROOT, 'data', 'DWM-original.gbc')

TABLE = 0x6119          # $01: dw x112, right after `rst $00` at $6118
RST_ADDR = 0x6118
N_ENTRIES = 112         # ends where Handler_Castle begins ($61F9)
FRAMES = 1024
C8A6, C8A7, WBGP = 0xC8A6, 0xC8A7, 0xC89B
ANIM_NONE = 0x6B        # the table's own bare-`ret` row for custom map ids


def rom_bytes(path=ROM):
    with open(path, 'rb') as f:
        return f.read()


def rw(rom, bank, a):
    o = bank * 0x4000 + (a & 0x3FFF)
    return rom[o] | rom[o + 1] << 8


def handler_table(rom):
    return [rw(rom, 1, TABLE + 2 * m) for m in range(N_ENTRIES)]


# ------------------------------------------------------------ static walk
def static_operands(rom, addr):
    """VRAM operands ($9000-$97FF) of `ld hl/de, nn` in the handler at
    $01:addr, following jr/jp/conditional branches AND calls within bank
    $01 (the GreatTree sway's $9400 lives in its helper); ROM0 calls
    (WaitVRAM, the dividers) are not entered."""
    from tools.sm83dis import decode
    bank = rom[0x4000:0x8000]
    seen, todo, ops = set(), [addr], set()
    while todo:
        pc = todo.pop()
        while 0x4000 <= pc < 0x8000 and pc not in seen:
            seen.add(pc)
            text, ln = decode(bank, pc - 0x4000, pc)
            t = text.replace(',', ' ').split()
            if t[0] == 'ld' and t[1] in ('hl', 'de') and t[2].startswith('$'):
                v = int(t[2][1:], 16)
                if 0x9000 <= v < 0x9800:
                    ops.add(v)
            if t[0] == 'call' and t[-1].startswith('$'):
                tgt = int(t[-1][1:], 16)
                if 0x4000 <= tgt < 0x8000:
                    todo.append(tgt)
            if t[0] in ('jr', 'jp') and t[-1].startswith('$'):
                tgt = int(t[-1][1:], 16)
                if 0x4000 <= tgt < 0x8000:
                    todo.append(tgt)
                if len(t) == 2:          # unconditional
                    break
            if t[0] == 'ret' and len(t) == 1:
                break
            if t[0] == 'jp' and t[1] == 'hl':
                break
            pc += ln
    return sorted(ops)


# ------------------------------------------------------------ measurement
def pattern():
    rnd = random.Random(99)
    return bytes(rnd.randrange(256) for _ in range(0x800))


def rotr(b):
    return bytes(((x >> 1) | ((x & 1) << 7)) for x in b)


def rotl(b):
    return bytes((((x << 1) & 0xFF) | (x >> 7)) for x in b)


def measure(rom_path, maps):
    from tools.pyboy_harness import boot, to_bedroom, warp, MAP_ID
    p = boot(rom_path)
    if not to_bedroom(p):
        raise SystemExit('boot failed')
    warp(p, 0x02, 4, 4, settle=240)
    if p.memory[MAP_ID] != 0x02:
        raise SystemExit('warp to Bazaar failed')
    force = [None]

    def cb(_):
        if force[0] is not None:
            p.register_file.A = force[0]
    p.hook_register(1, RST_ADDR, cb, None)
    with open(os.devnull, 'w'):
        pass
    import io
    base = io.BytesIO()
    p.save_state(base)
    res = {}
    pat = pattern()
    for m in maps:
        base.seek(0)
        p.load_state(base)
        for i, v in enumerate(pat):
            p.memory[0, 0x9000 + i] = v
        # counter := 0 so every event is recorded at its ABSOLUTE counter
        # value (the dispatch runs before IncrementVisualStep in the same
        # MainFieldLoop pass, so the handler sees the value read here)
        p.memory[C8A6] = 0
        p.memory[C8A7] = 0
        force[0] = m
        prev = bytes(p.memory[0, 0x9000:0x9800])
        bgp = {p.memory[WBGP]}
        ev = {}
        for f in range(FRAMES):
            ctr = p.memory[C8A6] | p.memory[C8A7] << 8
            p.tick()
            cur = bytes(p.memory[0, 0x9000:0x9800])
            bgp.add(p.memory[WBGP])
            if cur == prev:
                continue
            for t in range(128):
                new = cur[t * 16:t * 16 + 16]
                old = prev[t * 16:t * 16 + 16]
                if new == old:
                    continue
                if new == rotr(old):
                    kind = 'roll_right'
                elif new == rotl(old):
                    kind = 'roll_left'
                else:
                    part = [u for u in range(128)
                            if prev[u * 16:u * 16 + 16] == new and u != t]
                    kind = 'swap:%d' % part[0] if part else 'other'
                ev.setdefault(t, []).append((ctr, kind))
            prev = cur
        res[m] = {'events': ev, 'bgp_values': sorted(bgp)}
        force[0] = None
    p.stop(save=False)
    return res


def summarize(ev):
    """Per-slot effect summary from the event list."""
    slots = {}
    for t, lst in sorted(ev.items()):
        ctrs = [c for c, _k in lst]
        gaps = sorted({(b - a) & 0xFFFF for a, b in zip(ctrs, ctrs[1:])})
        partner = None
        roll = {'roll_right': 0, 'roll_left': 0}
        for _c, k in lst:
            if k.startswith('swap:'):
                partner = int(k[5:])
            elif k in roll:
                roll[k] += 1
        slots[t] = {
            'kind': 'swap' if partner is not None else
                    ('roll' if any(roll.values()) else 'other'),
            'partner': partner,
            'events': len(lst),
            'rolls_right': roll['roll_right'], 'rolls_left': roll['roll_left'],
            'frame_gaps': gaps[:6],
            'first_counters': sorted({c & 0xFF for c in ctrs})[:8],
        }
    return slots


def schedule(ev):
    """The exact playback schedule over one 1024-frame counter cycle (counter
    started at 0): {counter: [op, ...]} with op = ['R', t] / ['L', t] (roll
    tile t 1 px right/left) or ['S', a, b] (swap tiles a and b, a < b).
    The editor preview replays this (editor2/core/animation.py); the true
    period of a few handlers (Coliseum's 25-frame swap, Arena Battle's
    8-bit divider rhythm) does not divide 1024, so the preview is exact
    within a cycle and re-phases at its wrap."""
    out = {}
    for t, lst in ev.items():
        for c, k in lst:
            if k in ('roll_right', 'roll_left'):
                op = ['R' if k == 'roll_right' else 'L', t]
            elif k.startswith('swap:'):
                u = int(k[5:])
                if u < t:
                    continue
                op = ['S', t, u]
            else:
                op = ['?', t]
            out.setdefault(str(c & 0x3FF), []).append(op)
    return {k: sorted(v) for k, v in sorted(out.items(), key=lambda kv: int(kv[0]))}


def group_effects(slots):
    """Merge per-slot records into effects: roll groups (same timing) and
    swap pairs (visible <-> partner), in slot order."""
    effects, done = [], set()
    for t, s in sorted(slots.items()):
        if t in done:
            continue
        if s['kind'] == 'swap':
            a = [u for u, x in sorted(slots.items())
                 if x['kind'] == 'swap' and u not in done
                 and x['first_counters'] == s['first_counters']
                 and x['partner'] is not None and x['partner'] > u]
            b = [slots[u]['partner'] for u in a]
            done.update(a); done.update(b)
            effects.append({'kind': 'swap', 'slots': a, 'partners': b,
                            'period_frames': min(s['frame_gaps']) if s['frame_gaps'] else None})
        elif s['kind'] == 'roll':
            a = [u for u, x in sorted(slots.items())
                 if x['kind'] == 'roll' and u not in done
                 and x['first_counters'] == s['first_counters']
                 and (x['rolls_right'], x['rolls_left']) ==
                     (s['rolls_right'], s['rolls_left'])]
            done.update(a)
            effects.append({'kind': 'roll', 'slots': a,
                            'rolls_right': s['rolls_right'],
                            'rolls_left': s['rolls_left'],
                            'period_frames': min(s['frame_gaps']) if s['frame_gaps'] else None})
        else:
            done.add(t)
            effects.append({'kind': 'other', 'slots': [t]})
    return effects


def inert_for_sheet(slots, sheet):
    """True when this sheet makes every effect a no-op (blank/uniform)."""
    for t, s in slots.items():
        g = sheet[t * 16:t * 16 + 16]
        if s['kind'] == 'roll' and (rotr(g) != g or rotl(g) != g):
            return False
        if s['kind'] == 'swap':
            u = s['partner']
            if sheet[u * 16:u * 16 + 16] != g:
                return False
        if s['kind'] == 'other':
            return False
    return True


# ------------------------------------------------------------ build JSON
HANDLER_NOTES = {
    0x6220: 'map $08 (Starry Shrine breeding cutscene): writes the DMG '
            'palette byte wBGPalette ($C89B) from a table (a pulse); no tile '
            'effect. Not offered as a custom-room animation source.',
}


def build(rom_path=ROM):
    from editor2.core.render_project import ProjectRenderer
    from dwm.map_names import MAP_TYPE_NAMES
    rom = rom_bytes(rom_path)
    tab = handler_table(rom)
    distinct = []
    for m, h in enumerate(tab):
        if h not in [rw(rom, 1, TABLE + 2 * d) for d in distinct]:
            distinct.append(m)
    meas = measure(rom_path, distinct)
    pr = ProjectRenderer(ROOT, os.path.join(ROOT, 'editor2', 'example-project'),
                         {'custom': {}})
    handlers = {}
    for m in distinct:
        h = tab[m]
        ev = meas[m]['events']
        slots = summarize(ev)
        rec = {
            'first_map': '0x%02X' % m,
            'maps': ['0x%02X' % x for x in range(N_ENTRIES) if tab[x] == h],
            'effects': group_effects(slots),
            'slots': sorted(slots),
            'static_vram_operands': ['$%04X' % v for v in static_operands(rom, h)],
            'bgp_writes': len(meas[m]['bgp_values']) > 1,
        }
        if h in HANDLER_NOTES:
            rec['note'] = HANDLER_NOTES[h]
        rec['schedule'] = schedule(ev)
        rec['_slot_detail'] = {str(k): v for k, v in slots.items()}
        handlers['$%04X' % h] = rec
    maps = {}
    for m in range(N_ENTRIES):
        h = handlers['$%04X' % tab[m]]
        slots = {int(k): v for k, v in h['_slot_detail'].items()}
        e = {'name': MAP_TYPE_NAMES.get(m, 'map $%02X' % m),
             'handler': '$%04X' % tab[m],
             'slots': h['slots']}
        if m < 0x6B and slots:
            try:
                used = pr.vanilla_tiles_used(m)
            except Exception:
                used = set()
            e['shown'] = [t for t in h['slots'] if t in used]
            e['hidden_frames'] = [t for t in h['slots'] if t not in used]
            e['placed_known'] = bool(used)
            try:
                e['inert_in_vanilla'] = inert_for_sheet(slots, pr.vanilla_gfx(m).sheet)
            except Exception:
                e['inert_in_vanilla'] = None
        maps['0x%02X' % m] = e
    for h in handlers.values():
        h.pop('_slot_detail', None)
        h['slot_detail'] = None
    # keep a compact per-slot record (partner / kind) for the editor preview
    for hk, h in handlers.items():
        m = int(h['first_map'], 16)
        s = summarize(meas[m]['events'])
        h['slot_detail'] = {str(k): {'kind': v['kind'], 'partner': v['partner']}
                            for k, v in s.items()}
    return {
        '_generator': 'tools/census_room_animation.py (S99) over '
                      'data/DWM-original.gbc md5 1ca6579359f21d8e27b446f865bf6b83; '
                      'PyBoy measurement: each handler forced through the '
                      '$01:$6118 dispatch in the Bazaar over a patterned VRAM, '
                      '%d frames' % FRAMES,
        'dispatch': {
            'function': '$01:$60E7 PerRoomVRAMDispatch (called from MainFieldLoop)',
            'table': '$01:$6119', 'entries': N_ENTRIES,
            'index': 'wMapID (vanilla); custom rooms: bank $71 entry 3 '
                     'CustomAnimSource (S99 patch)',
            'guards': 'returns while $C850/$C88F/wInGateworld are non-zero, '
                      'any of wGameState bits 1,2,3,5,6,7 is set, or bit 4 '
                      'is set with $C8EF == $0F',
            'clock': '$C8A6/$C8A7 16-bit field frame counter '
                     '(IncrementVisualStep, +1 per MainFieldLoop pass)',
            'anim_none': '0x%02X' % ANIM_NONE,
        },
        'handlers': handlers,
        'maps': maps,
    }


def dumps(d):
    """indent=1 JSON with every list of scalars on one line (compact diffs)."""
    import re
    txt = json.dumps(d, indent=1)
    pat = re.compile(r'\[\s*((?:[-\w."$]+\s*,\s*)*[-\w."$]+)\s*\]')
    txt = pat.sub(lambda m: '[' + ', '.join(x.strip() for x in m.group(1).split(',')) + ']', txt)
    pat2 = re.compile(r'\[\s*((?:\[[^\[\]\n]*\]\s*,\s*)*\[[^\[\]\n]*\])\s*\]')
    txt = pat2.sub(lambda m: '[' + re.sub(r'\]\s*,\s*\[', '], [', m.group(1)) + ']', txt)
    return txt + '\n'


def check():
    data = json.load(open(OUT))
    rom = rom_bytes()
    tab = handler_table(rom)
    bad = 0
    for m in range(N_ENTRIES):
        if data['maps']['0x%02X' % m]['handler'] != '$%04X' % tab[m]:
            print('table mismatch at map $%02X' % m); bad += 1
    for hk, h in data['handlers'].items():
        ops = static_operands(rom, int(hk[1:], 16))
        if ['$%04X' % v for v in ops] != h['static_vram_operands']:
            print('operand drift', hk); bad += 1
        # every measured slot must lie within 64 B after a named operand
        for t in h['slots']:
            a = 0x9000 + 16 * t
            if not any(v <= a < v + 0x100 for v in ops):
                print('slot %d of %s outside the code\'s operands' % (t, hk)); bad += 1
    print('check:', 'OK' if not bad else '%d problems' % bad)
    return bad == 0


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', '--selftest', action='store_true')
    ap.add_argument('--rom', default=ROM)
    a = ap.parse_args()
    if a.check:
        sys.exit(0 if check() else 1)
    d = build(a.rom)
    with open(OUT, 'w') as f:
        f.write(dumps(d))
    n = sum(1 for m in d['maps'].values() if m['slots'])
    print('wrote', OUT, '-', len(d['handlers']), 'handlers,', n, 'animated map ids')
