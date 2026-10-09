#!/usr/bin/env python3
"""census_place_banks.py — S136 (ROADMAP ARC CAP2b): every read bank $60's
forwarders make lands on the right bytes, in the place's home bank.

Stub calls on the built ROM (PYBOY_DEBUGGING "S115 / S130 techniques"): the ROM
boots to the title screen; the inputs a bank $60 entry reads are poked, a stub
`di / ld hl,$60xx / rst $10 / <store BC, DE, HL> / ld a,$A5 / ld [MARK],a /
jr $` is written at $DD40 and run until the marker appears. The expected values
come from the SAME ROM through game.sym (the label of every place's screens,
step entries, lists and scripts, wherever the plan put them — bank $60 or a
place bank) — so the census proves the routing (directory, wPlaceIdx, the home
bank's tables), not a copy of the compiler's arithmetic:

  * entry 0 (step) / 8 (state rules + cast): for every place, every screen it
    defines, every state: DE == the step entry [step_id, bank] at the screen's
    counter value AFTER the rules ran; $D7CA-$D7D1 == the screen's cast;
  * entry 1 (NPC list) / 2 + 7 (exit list): wCustomNPCBuffer == the step
    entry's NPC list as CopyNPCListToBuffer copies it (prefix entries dropped;
    the hidden bit of a conditioned NPC is not judged — it depends on flags) /
    wCustomExitBuffer == its exit list;
  * entry 4 (+ entry 6): every word of every script of every place (and the
    custom skills' scripts, type $FF): BC == the word at the script's label;
  * entry 5: every text id: the text engine's bank ($C824) and string pointer
    ($C82D/E) == the text's label;
  * entry 9 (op $24): every tile patch of every place's scripts: the counter
    steps over the patch word and the patch's first row is staged at $C300 + its
    offset (the patch read from the place's home bank);
  * out of range: script types $6B + PLACE_COUNT … and $70 when there are
    fewer places -> BC = $FFFF, an op $24's word stepped over; map ids past the
    last place -> the dummy step $2A01, an empty NPC list, the dummy exits.
  * S137 (ARC CAP2c) — the render row, END TO END through bank $17: for every
    place, screen and state, bank $17 entry 1 (the attr walk) must leave at
    $C200 the attr grid the PROJECT names for that state (decoded from the
    ROM at the plan's (bank, entry)), and bank $17 entry 0 (the palette walk)
    must leave slots 0-3 of the palette buffer $C797 = the project palette's
    slots 0-3 (or the borrowed vanilla palette, read from the ORIGINAL ROM)
    under the engine's forcing (colour 1 := slot 7's unless the slot carries
    the free-colour-1 marker, colour 3 := slot 7's | the marker); bank $60
    entry 13 must hand back wRenderTable. Placeholders / map ids past the last
    place: entry 13 -> HL = 0 (the Castle fallback).

  python3 tools/census_place_banks.py --project DIR            # builds it
  python3 tools/census_place_banks.py --project OUT --make-spill 40
                                     # the example + 40 script/text-heavy rooms
  python3 tools/census_place_banks.py --project DIR --rom R --sym S
  --words N: words per script (default all); --negative: one expected value
  is corrupted and the census must fail.
"""
import argparse
import io
import os
import random
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

STUB = 0xDD40
MARK = 0xDD7F
OUT = 0xDD70           # C, B, E, D, L, H


def sym_table(path):
    out = {}
    for line in open(path):
        if line.startswith(';') or ':' not in line:
            continue
        ba, name = line.split()
        b, a = ba.split(':')
        out[name] = (int(b, 16), int(a, 16))
    return out


class Rom:
    def __init__(self, path):
        self.b = open(path, 'rb').read()

    def at(self, bank, addr, n=1):
        off = bank * 0x4000 + (addr - 0x4000) if addr >= 0x4000 else addr
        return self.b[off:off + n]

    def u8(self, bank, addr):
        return self.at(bank, addr)[0]

    def u16(self, bank, addr):
        lo, hi = self.at(bank, addr, 2)
        return lo | hi << 8


class Stub:
    def __init__(self, rom_path):
        from pyboy import PyBoy
        self.p = PyBoy(rom_path, window='null', sound_emulated=False, cgb=True)
        self.p.set_emulation_speed(0)
        for _ in range(400):
            self.p.tick()
        self.st = io.BytesIO()
        self.p.save_state(self.st)
        self.m = self.p.memory

    def reload(self):
        self.st.seek(0)
        self.p.load_state(self.st)

    def call(self, entry, pokes=(), bank=0x60):
        m = self.m
        for a, v in pokes:
            m[a] = v
        m[MARK] = 0
        code = [0xF3, 0x21, entry, bank, 0xD7,            # di / ld hl,$bbee / rst $10
                0x79, 0xEA, OUT & 0xFF, OUT >> 8,           # ld a,c / ld [OUT],a
                0x78, 0xEA, (OUT + 1) & 0xFF, OUT >> 8,     # ld a,b
                0x7B, 0xEA, (OUT + 2) & 0xFF, OUT >> 8,     # ld a,e
                0x7A, 0xEA, (OUT + 3) & 0xFF, OUT >> 8,     # ld a,d
                0x7D, 0xEA, (OUT + 4) & 0xFF, OUT >> 8,     # ld a,l
                0x7C, 0xEA, (OUT + 5) & 0xFF, OUT >> 8,     # ld a,h
                0x3E, 0xA5, 0xEA, MARK & 0xFF, MARK >> 8,   # ld a,$A5 / ld [MARK],a
                0x18, 0xFE]                                 # jr $
        for i, b in enumerate(code):
            m[STUB + i] = b
        self.p.register_file.SP = 0xDD3E
        self.p.register_file.PC = STUB
        for _ in range(30):
            self.p.tick()
            if m[MARK] == 0xA5:
                break
        else:
            raise RuntimeError(f"stub entry {entry} never returned (PC "
                               f"${self.p.register_file.PC:04X})")
        o = [m[OUT + i] for i in range(6)]
        return {'BC': o[0] | o[1] << 8, 'DE': o[2] | o[3] << 8, 'HL': o[4] | o[5] << 8}


EXAMPLE = os.path.join(REPO, 'editor2', 'example-project')
WORDS = ('stone', 'echo', 'river', 'lantern', 'meadow', 'tower', 'whisper', 'ember',
         'harbor', 'thicket', 'glacier', 'orchard', 'canyon', 'mirror', 'beacon', 'willow')


def make_spill(out_dir, n_rooms, ops_per_room=150, texts_per_room=3, seed=136):
    """A SPILL project: the example + n rooms ($74 …), each one screen (the
    example's island_s0 layout and sheet) with an NPC whose script shows
    `texts_per_room` long texts and runs `ops_per_room` harmless RAM writes
    (bulk script words), a tile patch (op $24 'patch:'), every 3rd room a
    monster NPC (the cast table) and every 4th room two states + a state rule
    — enough script and text to fill bank $60 and spill into several place
    banks. Returns (data, rooms)."""
    import json
    import random
    import shutil
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)
    shutil.copytree(EXAMPLE, out_dir, ignore=shutil.ignore_patterns('build'))
    d = json.load(open(os.path.join(out_dir, 'project.json')))
    c = d['custom']
    from editor2.core import formats as F
    mid = max(F.val(r['mapID']) for r in c['rooms']) + 1
    rng = random.Random(seed)
    c.setdefault('flags', []).append({'name': 'spill_rule_flag', 'index': 'auto'})
    rooms = []
    for i in range(n_rooms):
        rid = f'spill_{i}'
        texts = []
        for t in range(texts_per_room):
            words = ' '.join(rng.choice(WORDS) for _ in range(40 + rng.randrange(40)))
            texts.append({'id': f'{rid}_t{t}', 'text': f'SPILL {i} TEXT {t}. ' + words + '.'})
        c['dialogue'] += texts
        ops = [['text', x['id']] for x in texts]
        ops += [['op', 'write_ram', '0xC8F0', (i * 7 + k) & 0xFF] for k in range(ops_per_room)]
        ops += [['op', '0x24', 'patch:p'], ['end']]
        c['scripts'] += [{'id': f'{rid}_entry', 'ops': [['end']]},
                         {'id': f'{rid}_talk', 'ops': ops}]
        npc = {'kind': 'npc', 'sprite': '0x0B', 'x': 2, 'y': 3, 'facing': 'down',
               'script': f'{rid}_talk'}
        scr = {'layout': {'id': 'island_s0'}, 'npcs': [npc], 'exits': []}
        if i % 3 == 0:
            scr['npcs'].append({'kind': 'npc', 'sprite': '0xF0', 'x': 6, 'y': 3,
                                'facing': 'down', 'script': 'none', 'monster': i % 200})
        room = {'id': rid, 'mapID': f'0x{mid:02X}', 'source_mapID': '0x04',
                'record': {'gfx_id': '0x0D', 'gfx_bank': '0x28', 'width_px': 160,
                           'height_px': 128, 'collision_threshold': '0x30'},
                'render': {'palette': 'pal_6b', 'attr': {'id': 'island_s0'}},
                'scripts': {'0': f'{rid}_entry', '1': f'{rid}_talk'},
                'patch_data': {'p': [0x00, 0x00, 0x10, 0x11, 0xD9]},
                'screens': {'0': scr}, 'animation': 'none'}
        if i % 4 == 0:
            scr['states'] = [{'npcs': list(scr['npcs']), 'exits': []},
                             {'npcs': [npc], 'exits': []}]
            del scr['npcs'], scr['exits']
            room['state_rules'] = [{'state': 1, 'when': [{'flag': 'spill_rule_flag'}]},
                                   {'state': 0, 'when': []}]
        c['rooms'].append(room)
        rooms.append(room)
        mid += 1
    json.dump(d, open(os.path.join(out_dir, 'project.json'), 'w'), indent=1)
    return d, rooms


def npc_copy_model(raw):
    """CopyNPCListToBuffer: 5-byte entries until $FF; $A0/$A1/$A2 prefixes are
    not copied; returns [(bytes, conditioned)]."""
    out, i, cond = [], 0, False
    while raw[i] != 0xFF:
        if raw[i] in (0xA0, 0xA1):
            cond = True
            i += 5
            continue
        if raw[i] == 0xA2:
            i += 5
            continue
        e = list(raw[i:i + 5])
        out.append((e, cond and e[0] < 0x80))
        if e[0] < 0x80:
            cond = False
        i += 5
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--project', required=True,
                    help='a project dir (with --make-spill: where to write the spill project)')
    ap.add_argument('--make-spill', type=int, default=0, metavar='N',
                    help='first write a SPILL project of the example + N rooms there')
    ap.add_argument('--rom')
    ap.add_argument('--sym')
    ap.add_argument('--words', type=int, default=0)
    ap.add_argument('--seed', type=int, default=136)
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args()
    if a.make_spill:
        make_spill(a.project, a.make_spill)
    from editor2.core import compiler as C
    from editor2.core import formats as F
    from editor2.core import emitters as E
    if a.rom is None:
        from editor2.core import builder as B
        out = os.path.join(a.project, 'build')
        outputs, prj, _w = C.compile_project(a.project, REPO)
        C.write_outputs(outputs, out)
        a.rom, a.sym, _md5 = B.build_rom(REPO, out, os.path.join(out, 'build'))
    else:
        _o, prj, _w = C.compile_project(a.project, REPO)
    plan = prj.place_plan()
    sym = sym_table(a.sym)
    rom = Rom(a.rom)
    w = {k: sym[k][1] for k in ('wMapID', 'wScriptMapType', 'wScriptNPCId',
                                'wCustomNPCBuffer', 'wCustomExitBuffer', 'wPlaceIdx')}
    SCR = 0xC925
    S = Stub(a.rom)
    m = S.m
    rnd = random.Random(a.seed)
    bad, n, first = {}, {}, []

    def check(kind, got, want, ctx):
        if a.negative and kind == 'script' and n.get(kind, 0) == 3:
            want = want ^ 1
        if a.negative and kind == 'render_pal' and n.get(kind, 0) == 0:
            want = [want[0] ^ 1] + list(want[1:])        # S137: the render check can fail
        n[kind] = n.get(kind, 0) + 1
        if got != want:
            bad[kind] = bad.get(kind, 0) + 1
            if len(first) < 12:
                first.append((kind, ctx, got, want))

    banks_seen = set()
    # ---- places: screens / states (entries 0 / 8 / 1 / 2 / 7) -------------------
    for r in prj.rooms:
        mid = F.val(r['mapID'])
        hb, idx = plan['home'][mid]
        banks_seen.add(hb)
        tag = E.room_tag(r)
        if r.get('placeholder'):
            got = S.call(0x00, [(w['wMapID'], mid), (SCR, 0)])
            check('step', got['DE'], 0x2A01, (r['id'], 'placeholder'))
            continue
        for k, scr in sorted(prj.room_screens(r).items()):
            lb = f"{tag}_Screen{k}"
            sb, sa = sym[lb]
            check('home', sb, hb, (r['id'], lb))
            ctr = rom.u16(sb, sa)
            nstates = len(prj.screen_states(scr))
            for st in range(nstates):
                S.reload()
                pokes = [(w['wMapID'], mid), (SCR, k), (ctr, st)]
                for i in range(8):
                    pokes.append((0xD7CA + i, 0xEE))
                got = S.call(0x00, pokes)
                cur = m[ctr]                         # after the state rules
                ent = sa + 2 + 6 * cur
                check('step', got['DE'], rom.u16(sb, ent), (r['id'], k, st, cur))
                cast = prj.monster_cast(r, k)
                if cast:
                    want = []
                    for sp in (cast + [None] * 4)[:4]:
                        want += [0xFF, 0x00] if sp is None else [(sp + 0x10) & 0xFF, 1]
                    check('cast', [m[0xD7CA + i] for i in range(8)], want, (r['id'], k))
                npc_ptr, exit_ptr = rom.u16(sb, ent + 2), rom.u16(sb, ent + 4)
                got = S.call(0x01, [(w['wMapID'], mid), (SCR, k)])
                check('npc_hl', got['HL'], w['wCustomNPCBuffer'], (r['id'], k))
                raw = rom.at(sb, npc_ptr, 256)
                buf = [m[w['wCustomNPCBuffer'] + i] for i in range(128)]
                ok = True
                for j, (e, cond) in enumerate(npc_copy_model(raw)):
                    g = buf[5 * j:5 * j + 5]
                    if cond:
                        g = [g[0] & ~0x40] + g[1:]
                        e = [e[0] & ~0x40] + e[1:]
                    ok &= g == e
                ok &= buf[5 * len(npc_copy_model(raw))] == 0xFF
                check('npc', ok, True, (r['id'], k, cur))
                for entry in (0x02, 0x07):
                    got = S.call(entry, [(w['wMapID'], mid), (SCR, k)])
                    raw = rom.at(sb, exit_ptr, 7 * 18 + 1)
                    nex = 0
                    while raw[7 * nex] != 0xFF:
                        nex += 1
                    want = list(raw[:7 * nex + 1])
                    gotb = [m[w['wCustomExitBuffer'] + i] for i in range(7 * nex + 1)]
                    check('exit', (got['HL'], gotb),
                          (w['wCustomExitBuffer'], want), (r['id'], k, entry))
    # past the last place
    S.reload()
    past = 0x6B + len(prj.rooms)
    if past <= 0xFF:
        got = S.call(0x00, [(w['wMapID'], past), (SCR, 0)])
        check('step_past', got['DE'], 0x2A01, past)
        got = S.call(0x01, [(w['wMapID'], past), (SCR, 0)])
        check('npc_past', m[w['wCustomNPCBuffer']], 0xFF, past)
        got = S.call(0x02, [(w['wMapID'], past), (SCR, 0)])
        db, da = sym['DummyExits']
        want = list(rom.at(db, da, 36))
        check('exit_past', [m[w['wCustomExitBuffer'] + i] for i in range(36)], want, past)

    # ---- S137: render rows (bank $60 entry 13; bank $17 entries 0 / 1) ------------
    from tools.decompress_tiles import decompress_lz
    orig = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    wren = sym.get('wRenderTable', (0, 0))[1]

    def want_palette(r, k, st):
        kind, ref = prj.state_palette_ref(r, k, st)
        if kind == 'palette':
            pal = prj._pal_by_id[ref]
            rows = [list(x) for x in pal['colors_rgb555'][:4]]
            free = bool(pal.get('free_color1'))
            cols = [[F.val(c) for c in row] for row in rows]
        else:
            o = 0x17 * 0x4000 + (ref - 0x4000)
            raw = orig[o:o + 32]
            cols = [[raw[8 * sl + 2 * c] | raw[8 * sl + 2 * c + 1] << 8 for c in range(4)]
                    for sl in range(4)]
            free = False
        return cols, free

    for r in prj.rooms:
        mid = F.val(r['mapID'])
        if r.get('placeholder') or not prj.room_screens(r):
            S.reload()
            got = S.call(0x0D, [(w['wMapID'], mid), (SCR, 0)])
            check('render_none', got['HL'], 0, (r['id'], 'placeholder'))
            continue
        hb, _i = plan['home'][mid]
        for k, scr in sorted(prj.room_screens(r).items()):
            sb, sa = sym[f"{E.room_tag(r)}_Screen{k}"]
            ctr = rom.u16(sb, sa)                    # the screen's step counter (as entry 0)
            nstates = len(prj.screen_states(scr))
            # scenarios: every state by its counter, and — on a screen with state
            # rules — every rule's flags made true (the rules run first and may
            # overwrite the counter, so this is how a ruled state is reached)
            scen = [(st, []) for st in range(nstates)]
            for scr_k, rules in prj.state_rules(r):
                if scr_k != k:
                    continue
                for rst, terms in rules:
                    scen.append((rst, [(fi, not clr) for fi, clr in terms]))
            reached = set()
            for st, flags in scen:
                S.reload()
                base = [(w['wMapID'], mid), (SCR, k), (ctr, st), (sym['wInGateworld'][1], 0)]
                for fi, on in flags:
                    if fi >= 0x1000:
                        fa = sym['wExtFlags'][1] + ((fi - 0x1000) >> 3)
                    else:
                        fa = 0xD99B + (fi >> 3)
                    mask = 0x80 >> (fi & 7)
                    v = (m[fa] | mask) if on else (m[fa] & ~mask & 0xFF)
                    base.append((fa, v))
                got = S.call(0x0D, base)
                check('render_hl', got['HL'], wren, (r['id'], k, st))
                cur = m[ctr]                         # after the state rules
                ab_e = prj.state_attr_entry(r, k, cur)
                want_attr = list(decompress_lz(rom.b, ab_e[0], ab_e[1])[0])
                na = len(want_attr)
                S.reload()
                for i in range(na):
                    m[0xC200 + i] = 0xEE
                S.call(0x01, base, bank=0x17)
                check('render_attr', [m[0xC200 + i] for i in range(na)], want_attr,
                      (r['id'], k, st, cur))
                S.reload()
                for i in range(32):                  # slots 0-3 (slot 7 = the forcing source)
                    m[0xC797 + i] = 0xEE
                S.call(0x00, base, bank=0x17)
                cols, free = want_palette(r, k, cur)
                c1 = m[0xC7D1] | m[0xC7D2] << 8
                c3 = m[0xC7D5] | m[0xC7D6] << 8
                want, gotp = [], []
                for sl in range(4):
                    row = list(cols[sl])
                    mark = free and True
                    row[1] = row[1] if mark else c1
                    row[3] = c3 | (0x8000 if mark else 0)
                    want += row
                    gotp += [m[0xC797 + 8 * sl + 2 * c] | m[0xC797 + 8 * sl + 2 * c + 1] << 8
                             for c in range(4)]
                check('render_pal', gotp, want, (r['id'], k, st, cur))
                reached.add(cur)
                banks_seen.add(hb)
            check('render_states', sorted(reached), list(range(nstates)), (r['id'], k))
    S.reload()
    past = 0x6B + len(prj.rooms)
    if past <= 0xFF:
        got = S.call(0x0D, [(w['wMapID'], past), (SCR, 0)])
        check('render_past', got['HL'], 0, past)

    # ---- scripts (entries 4 / 6) -------------------------------------------------
    S.reload()
    m[w['wMapID']] = 0x6B if prj.rooms else 0x01

    def run_script(stype, npc, label, length, entry=0x04):
        lb, la = sym[label]
        idxs = list(range(length))
        if a.words and length > a.words:
            idxs = sorted({0, length - 1} | set(rnd.sample(range(length), a.words)))
        for wi in idxs:
            got = S.call(entry, [(w['wScriptMapType'], stype), (w['wScriptNPCId'], npc),
                                 (0xD8D5, wi & 0xFF), (0xD8D6, wi >> 8)])
            check('script', got['BC'], rom.u16(lb, la + 2 * wi), (label, wi))
        return lb

    def script_len(label):
        """words of a script: up to the next label in its bank (the emitter
        writes the bodies back to back)."""
        b, a0 = sym[label]
        nxt = min((ad for nm, (bb, ad) in sym.items() if bb == b and ad > a0
                   and '.' not in nm and not nm.startswith(label + '_')),
                  default=a0 + 2)
        return max(1, (nxt - a0) // 2)

    for r in prj.rooms:
        mid = F.val(r['mapID'])
        tag = E.room_tag(r)
        table = prj.room_script_table(r) if not r.get('placeholder') and r.get('scripts') \
            else [(0, None)]
        for idx, _sid in table:
            lb = f"{tag}_Scr{idx:02d}"
            m[w['wMapID']] = mid
            banks_seen.add(run_script(mid, idx, lb, script_len(lb),
                                      entry=0x06 if idx % 2 else 0x04))
    for i, sc in enumerate(prj.skill_scripts):
        lb = f"SkillScr{E.SKILL_SCRIPT_FIRST + i:02d}"
        run_script(0xFF, E.SKILL_SCRIPT_FIRST + i, lb, script_len(lb))
    for stype in ([0x6B + len(prj.rooms)] if len(prj.rooms) < 0x94 else []) + \
            ([0x70] if len(prj.rooms) <= 5 else []):
        m[w['wMapID']] = 0x6B
        got = S.call(0x04, [(w['wScriptMapType'], stype), (w['wScriptNPCId'], 0),
                            (0xD8D5, 0), (0xD8D6, 0)])
        check('script_past', got['BC'], 0xFFFF, stype)

    # ---- tile patches (entry 9): every op $24 of every place's scripts --------------
    for r in prj.rooms:
        if r.get('placeholder') or not r.get('scripts') or not r.get('patch_data'):
            continue
        mid = F.val(r['mapID'])
        tag = E.room_tag(r)
        for idx, _sid in prj.room_script_table(r):
            lb = f"{tag}_Scr{idx:02d}"
            sb, sa = sym[lb]
            for wi in range(script_len(lb)):
                if rom.u16(sb, sa + 2 * wi) != 0xFF24:
                    continue
                pa = rom.u16(sb, sa + 2 * wi + 2)
                if pa >= 0xFF00:
                    continue                      # a compiler command, not a patch
                off = rom.u16(sb, pa)
                row = []
                k = pa + 2
                while rom.u8(sb, k) not in (0xD8, 0xD9):
                    row.append(rom.u8(sb, k))
                    k += 1
                S.reload()
                for i in range(len(row)):
                    m[0xC300 + off + i] = 0xEE
                m[w['wMapID']] = mid
                S.call(0x09, [(w['wScriptMapType'], mid), (w['wScriptNPCId'], idx),
                              (0xD8D5, wi & 0xFF), (0xD8D6, wi >> 8)])
                got = ([m[0xC300 + off + i] for i in range(len(row))],
                       m[0xD8D5] | m[0xD8D6] << 8)
                check('patch', got, (row, wi + 1), (lb, wi))
                banks_seen.add(sb)
    if len(prj.rooms) < 0x94:                     # a type past the last place: the word skipped
        S.reload()
        m[w['wMapID']] = 0x6B if prj.rooms else 0x01
        stype = 0x6B + len(prj.rooms)
        S.call(0x09, [(w['wScriptMapType'], stype), (w['wScriptNPCId'], 0),
                      (0xD8D5, 7), (0xD8D6, 0)])
        check('patch_past', m[0xD8D5] | m[0xD8D6] << 8, 8, stype)

    # ---- texts (entry 5) -----------------------------------------------------------
    for si, sec in enumerate(prj.text_sections()):
        for tid, _e in sec:
            S.reload()
            S.call(0x05, [(0xC822, si), (0xC823, tid & 0xFF)])
            lb, la = sym[prj.text_label(tid)]
            banks_seen.add(lb)
            check('text', (m[0xC824], m[0xC82D] | m[0xC82E] << 8), (lb, la), F.hexw(tid))
            check('text_home', lb, plan['text_home'][si], F.hexw(tid))
    S.p.stop(save=False)
    for f in first:
        print('MISMATCH', f)
    tot = sum(bad.values())
    print(f"{sum(n.values())} checks over banks "
          f"{', '.join(f'${b:02X}' for b in sorted(banks_seen))}: "
          f"{sum(n.values()) - tot} identical, {tot} mismatched "
          f"{ {k: (n[k], bad.get(k, 0)) for k in sorted(n)} }"
          + (' (negative control)' if a.negative else ''))
    return 0 if (tot == 0) != a.negative else 1


if __name__ == '__main__':
    sys.exit(main())
