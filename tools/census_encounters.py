#!/usr/bin/env python3
"""census_encounters.py — the game's encounter-list choice and battle draw vs
editor2/core/encounters.py (ROADMAP P3.13a, S114; DATA_STRUCTURES "Encounter
list choice (S114)").

Boots a ROM in PyBoy to the title screen and stub-calls (the S109/S113 stub:
`di / ld hl,$01xx / rst $10 / jr $` at $DD40):

  * bank $01 entry $0D LoadNextDungeonFloor for every gate 0-31 (+ the
    project's NEW gates 32+, S115 — their value walks the gate they copy) and every floor
    1..floor count (the project's counts), for every flag state a gate's or a
    room's variants name, and for every custom room with encounters
    (wInGateworld 0, wMapID = the room) — and compares wEncounterPoolIndex
    ($CA38, the floor's VALUE), wC8A9 (the rate code) and the 26 bytes of the
    list in use (wEncListBuf in a patched build; EncounterPoolData + $CA38*26
    in the ORIGINAL ROM) with the model;
  * bank $01 entry $0B EncounterMonsterSelect (the battle draw) from pinned
    RNG states for each of those cases — $DA02 (monsters - 1) and the EIDs at
    $DA03/$DA05/$DA07 vs `encounters.simulate_battle`.

    python3 tools/census_encounters.py --project editor2/example-project
    python3 tools/census_encounters.py --original          # the ORIGINAL ROM vs the vanilla model
    python3 tools/census_encounters.py --project P --negative   # a perturbed model: must mismatch

Writes extracted/encounter_census.json (or --out) and exits 1 on any mismatch.
"""
import argparse
import copy
import hashlib
import json
import os
import random
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
OUT = os.path.join(REPO, 'extracted', 'encounter_census.json')
ORIGINAL = os.path.join(REPO, 'data', 'DWM-original.gbc')
STUB = 0xDD40
W_IN_GATE, W_MAP, W_GATE, W_FLOOR = 0xC969, 0xC968, 0xC935, 0xC939
W_POOL, W_RATE = 0xCA38, 0xC8A9
W_RNG1, W_RNG2 = 0xC899, 0xC89A
DA02 = 0xDA02
FLAG_BASE = 0xD99B
POOL_ADDR = 0x6AAE


def sym(path):
    out = {}
    for line in open(path):
        parts = line.split()
        if len(parts) == 2 and ':' in parts[0]:
            b, a = parts[0].split(':')
            out[parts[1]] = (int(b, 16), int(a, 16))
    return out


def build(project, outdir):
    subprocess.run([sys.executable, os.path.join(REPO, 'tools', 'build_project.py'),
                    '--project', project, '--build', '--out', outdir],
                   check=True, stdout=subprocess.DEVNULL)
    return os.path.join(outdir, 'build', 'rom.gbc'), os.path.join(outdir, 'build', 'game.sym')


def model_for(project):
    from editor2.core.project import Project
    from editor2.core import encounters as EN
    if project is None:
        data = {'meta': {'name': 'vanilla'}, 'custom': {}, 'gamedata': {}}
        root = REPO
    else:
        data = json.load(open(os.path.join(project, 'project.json')))
        root = project
    pr = Project(data, root)
    return pr, EN.resolve(pr)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--project')
    ap.add_argument('--rom')
    ap.add_argument('--original', action='store_true',
                    help='the ORIGINAL ROM (data/DWM-original.gbc) vs the vanilla model')
    ap.add_argument('--seeds', type=int, default=24, help='battle draws per case')
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--label')
    ap.add_argument('--negative', action='store_true',
                    help='perturb the model (draw: sum > draw instead of >=) — '
                         'the census must then report mismatches')
    a = ap.parse_args()
    from editor2.core import encounters as EN
    from editor2.core import gates as G
    if a.original:
        rom, project, patched = ORIGINAL, None, False
    else:
        if not a.project:
            sys.exit('--project (or --original) is required')
        project = os.path.abspath(a.project)
        if a.rom:
            rom = a.rom
        else:
            rom, _s = build(project, '/tmp/census_encounters_build')
        patched = True
    pr, M = model_for(project)
    pct = M.pct
    if a.negative:
        def calc(sums, rng):
            rng = EN.rng_next(*rng)
            d = (rng[1] << 8 | rng[0]) % 100
            for i, s in enumerate(sums):
                if s and (s == 100 or s > d):
                    return i, rng
            return len(sums) - 1, rng
        EN._calc = calc

    from tools.pyboy_harness import adv, boot
    romcopy = '/tmp/census_encounters_rom.gbc'
    shutil.copy(rom, romcopy)
    if os.path.exists(romcopy + '.ram'):
        os.remove(romcopy + '.ram')
    romb = open(rom, 'rb').read()
    p = boot(romcopy)
    adv(p, 600)
    m = p.memory
    buf = None
    if patched:
        S = sym(os.path.join(os.path.dirname(rom), 'game.sym'))
        buf = S['wEncListBuf'][1]
    park = STUB + 5

    def stub(entry):
        for i, b in enumerate([0xF3, 0x21, entry, 0x01, 0xD7, 0x18, 0xFE]):
            m[STUB + i] = b
        p.register_file.PC = STUB
        for _ in range(40):
            p.tick(1, False)
            if p.register_file.PC == park:
                return
        raise SystemExit(f'bank $01 entry {entry:#x} did not return')

    def set_flags(state):
        for idx, on in state.items():
            byte, bit = FLAG_BASE + (idx >> 3), 7 - (idx & 7)
            m[byte] = (m[byte] | 1 << bit) if on else (m[byte] & ~(1 << bit) & 0xFF)

    def flag_states(variants):
        """None (all the named flags clear-or-default) + one state per variant
        that makes it hold (earlier variants' first terms forced to fail)."""
        idxs = sorted({i for terms, _x in variants for i, _c in terms})
        states = [{i: False for i in idxs}]
        for k, (terms, _x) in enumerate(variants):
            st = {i: False for i in idxs}
            for i, clr in terms:
                st[i] = not clr
            states.append(st)
        return states

    # ---- the cases ---------------------------------------------------------
    cases = []        # (label, setup dict, flags state, expected list number, value, rate)
    floors_of = {}
    for g in range(32):
        floors_of[g] = G.gate_floor_count(pr.custom, g, REPO) or 1
    for ge in G.new_gate_entries(pr.custom):          # S115: the project's NEW gates
        g = int(ge['gate'])
        floors_of[g] = G.gate_floor_count(pr.custom, g, REPO) or 1
    for g in sorted(M.gates):
        floors_of.setdefault(g, M.gates[g]['floors'])
    for g, n in sorted(floors_of.items()):
        gv = M.gates.get(g)
        states = flag_states(gv['variants']) if gv else [{}]
        for st in states:
            for f in range(1, max(1, n - 1) + 1):          # the boss floor has no maze
                lst = M.gate_list(g, f, st if gv else None)
                cases.append((f'gate {g} floor {f}' + (f' flags {st}' if st else ''),
                               {W_IN_GATE: 1, W_GATE: g, W_FLOOR: f - 1, W_MAP: 0x53},
                               st, lst, M.vanilla(g, f), None))
    for mid, rm in sorted(M.rooms.items()):
        room = pr.room_by_mid(mid) if hasattr(pr, 'room_by_mid') else None
        enc = (room or {}).get('encounters') or {}
        gid, fl = int(enc.get('gate_id', 0) or 0), int(enc.get('floor', 1) or 1)
        variants = [(t, n) for t, n in rm['variants']]
        for st in flag_states(variants):
            if rm['default'] is None:
                lst = M.gate_list(gid, fl + 1, st)
                val = M.vanilla(gid, fl + 1)
            else:
                lst = rm['default']
                for terms, n in variants:
                    if all(bool(st.get(i)) != clr for i, clr in terms):
                        lst = n
                        break
                val = lst
            cases.append((f'room {rm["room_id"]} ({mid:#04x})' + (f' flags {st}' if st else ''),
                          {W_IN_GATE: 0, W_MAP: mid, W_GATE: gid, W_FLOOR: fl},
                          st, lst, val, rm['rate']))

    bad, n_calls, n_draws = [], 0, 0
    rng = random.Random(114)
    for label, setup, st, lst, val, rate in cases:
        want = M.list_bytes(lst)
        want_rate = want[0] if rate is None else rate
        for addr, v in setup.items():
            m[addr] = v
        set_flags(st)
        stub(0x0D)
        n_calls += 1
        got_val, got_rate = m[W_POOL], m[W_RATE]
        if patched:
            got = bytes(m[buf + i] for i in range(26))
        else:
            got = romb[0x4000 + (POOL_ADDR - 0x4000) + got_val * 26:][:26]
        if (got, got_val, got_rate) != (want, val & 0xFF, want_rate):
            bad.append({'case': label, 'what': 'list choice',
                        'game': [got.hex(), got_val, got_rate],
                        'model': [want.hex(), val & 0xFF, want_rate, lst]})
            continue
        for _ in range(a.seeds):
            r1, r2 = rng.randrange(256), rng.randrange(256)
            for addr, v in setup.items():
                m[addr] = v
            m[W_RNG1], m[W_RNG2] = r1, r2
            for k in range(6):
                m[DA02 + 1 + k] = 0
            stub(0x0B)
            n_draws += 1
            cnt = m[DA02] + 1
            geids = [m[DA02 + 1 + 2 * k] | m[DA02 + 2 + 2 * k] << 8 for k in range(cnt)]
            try:
                wn, weids, _r = EN.simulate_battle(want, pct, r1, r2)
            except ValueError as e:
                wn, weids = -1, [str(e)]
            if (cnt, geids) != (wn, weids):
                bad.append({'case': label, 'what': 'battle draw', 'rng': [r1, r2],
                            'game': [cnt, geids], 'model': [wn, weids]})
    p.stop(save=False)
    md5 = hashlib.md5(romb).hexdigest()
    res = {
        '_generator': ('tools/census_encounters.py (S114, ROADMAP P3.13a; new gates S115) — PyBoy stub '
                       'calls of bank $01 LoadNextDungeonFloor / EncounterMonsterSelect vs '
                       f"editor2/core/encounters.py; ROM {md5} "
                       f"({'ORIGINAL' if not patched else a.label or project})"
                       + (' NEGATIVE CONTROL' if a.negative else '')),
        'list_choices': n_calls, 'battle_draws': n_draws, 'mismatches': len(bad),
        'first_mismatches': bad[:20]}
    if not a.negative:
        json.dump(res, open(a.out, 'w'), indent=1)
    print(f"{'ORIGINAL' if not patched else 'patched'} {md5[:8]}: {n_calls} list choices, "
          f"{n_draws} battle draws, {len(bad)} mismatches"
          + (' (negative control)' if a.negative else ''))
    for b in bad[:5]:
        print('  ', b)
    sys.exit(0 if (bad and a.negative) or (not bad and not a.negative) else 1)


if __name__ == '__main__':
    main()
