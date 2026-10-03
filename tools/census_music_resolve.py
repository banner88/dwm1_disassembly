#!/usr/bin/env python3
"""census_music_resolve.py — S116 (ROADMAP P3.13b): the built ROM's music resolvers
== the editor's models (editor2/core/music.py model_room_bgm / model_battle_bgm).

Stub calls (PYBOY_DEBUGGING "S115 techniques"): the ROM boots to the title
screen; per sample one savestate is loaded, the game state the resolver reads is
poked, `di / ld hl,$71xx / rst $10 / jr $` is written at $DD40 and run (PC =
$DD40), and register E is read after two frames.
  * entry 2 CustomRoomBGMResolve reads wInGateworld, wMapID, wGateID,
    wCurrentFloor, wLastFloor, wBossMapType;
  * entry 7 BattleBGMResolve reads $C86C (link), wMapID, wArenaStarryBattle,
    $DA03/$DA04 (the first enemy's EID), wInGateworld, wGateID, $DA09 (mode).
The samples cover every map id class (vanilla < $50, the special rooms, the
coliseum, $5D-$60, custom rooms with / without / "follow the gate" bytes, ids
>= $80), every gate with a song + some without, the floor before the boss
floor (vanilla / custom / $80+ boss maps), every project fight + other EIDs,
link, Starry 0/1/2, modes 0-3.

  python3 tools/census_music_resolve.py --project PROJECT_DIR   # builds it
  python3 tools/census_music_resolve.py --rom ROM --sym SYM --project PROJECT_DIR
  --negative: the model is handed a wrong plan (one gate song changed) and must
  mismatch.
"""
import argparse
import io
import os
import random
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from editor2.core import music as M        # noqa: E402

STUB = 0xDD40


def sym_table(path):
    out = {}
    for line in open(path):
        if line.startswith(';') or ':' not in line:
            continue
        ba, name = line.split()
        b, a = ba.split(':')
        out[name] = (int(b, 16), int(a, 16))
    return out


def contexts(P, rnd, n):
    rooms_custom = [m for m in range(0x61, 0x80)]
    maps = (list(range(0x00, 0x50, 7)) + [0x50, 0x51, 0x52, 0x53, 0x58, 0x5C, 0x5D, 0x5E, 0x60]
            + rooms_custom + [0x80, 0x9A])
    gates = sorted(set([g for g in range(M.GATE_TABLE_LEN) if P.gate_bgm[g] or P.gate_battle[g]]
                       + [0, 1, 2, 5, 31, 32, 33, 95, 96, 200]))
    eids = [e for e, _ in P.fights] + [0, 1, 11, 251, 519, 700]
    boss = [0x30, 0x4F, 0x6B, 0x6C] + [m for m in rooms_custom if P.room_bgm[m]] + [0x7F, 0x85]
    for _ in range(n):
        last = rnd.choice([3, 4, 5, 10])
        floor = rnd.choice([last - 2, last - 1, 0, 1]) & 0xFF
        yield {'in_gate': rnd.choice([0, 0, 1]), 'map': rnd.choice(maps),
               'gate': rnd.choice(gates), 'floor': floor, 'last': last,
               'boss_map': rnd.choice(boss), 'link': rnd.choice([0] * 9 + [1]),
               'starry': rnd.choice([0, 1, 2, 2]), 'eid': rnd.choice(eids),
               'mode': rnd.choice([0, 1, 2, 3])}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--project', required=True)
    ap.add_argument('--rom')
    ap.add_argument('--sym')
    ap.add_argument('--samples', type=int, default=1500)
    ap.add_argument('--seed', type=int, default=116)
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args()
    from editor2.core import compiler as C
    if a.rom is None:
        from editor2.core import builder as B
        out = os.path.join(a.project, 'build')
        outputs, prj, _w = C.compile_project(a.project, REPO)
        C.write_outputs(outputs, out)
        rom, sym, _md5 = B.build_rom(REPO, out, os.path.join(out, 'build'))
        a.rom, a.sym = rom, sym
    else:
        _o, prj, _w = C.compile_project(a.project, REPO)
    P = prj.music_plan()
    if a.negative:
        g = next((g for g in range(M.GATE_TABLE_LEN) if P.gate_bgm[g]), 1)
        P.gate_bgm[g] = (P.gate_bgm[g] or 0x09) ^ 0x01
        P.fights = [(e, s ^ 1) for e, s in P.fights]
    sym = sym_table(a.sym)
    addr = {k: sym[k][1] for k in ('wInGateworld', 'wMapID', 'wGateID', 'wCurrentFloor',
                                   'wLastFloor', 'wBossMapType', 'wArenaStarryBattle')}
    from pyboy import PyBoy
    p = PyBoy(a.rom, window='null', sound_emulated=False, cgb=True)
    p.set_emulation_speed(0)
    for _ in range(400):
        p.tick()
    st = io.BytesIO()
    p.save_state(st)
    mm = p.memory
    rnd = random.Random(a.seed)
    bad = {'room': 0, 'battle': 0}
    n = 0
    first = []
    for ctx in contexts(P, rnd, a.samples):
        for kind, entry, model in (('room', 0x02, M.model_room_bgm),
                                   ('battle', 0x07, M.model_battle_bgm)):
            st.seek(0)
            p.load_state(st)
            mm[addr['wInGateworld']] = ctx['in_gate']
            mm[addr['wMapID']] = ctx['map']
            mm[addr['wGateID']] = ctx['gate'] & 0xFF
            mm[addr['wCurrentFloor']] = ctx['floor']
            mm[addr['wLastFloor']] = ctx['last']
            mm[addr['wBossMapType']] = ctx['boss_map']
            mm[addr['wArenaStarryBattle']] = ctx['starry']
            mm[0xC86C] = ctx['link']
            mm[0xDA03] = ctx['eid'] & 0xFF
            mm[0xDA04] = ctx['eid'] >> 8
            mm[0xDA09] = ctx['mode']
            code = [0xF3, 0x21, entry, 0x71, 0xD7, 0x18, 0xFE]
            for i, b in enumerate(code):
                mm[STUB + i] = b
            p.register_file.SP = 0xDD3E
            p.register_file.PC = STUB
            p.tick()
            p.tick()
            got = p.register_file.E
            c2 = dict(ctx, gate=ctx['gate'] & 0xFF)
            want = model(P, c2)
            n += 1
            if got != want:
                bad[kind] += 1
                if len(first) < 8:
                    first.append((kind, ctx, f'game ${got:02X} model ${want:02X}'))
    p.stop(save=False)
    for f in first:
        print('MISMATCH', f)
    tot = sum(bad.values())
    print(f'{n} stub calls ({a.samples} contexts x 2 resolvers): {n - tot} identical, '
          f'{tot} mismatched {bad}' + (' (negative control)' if a.negative else ''))
    return 0 if (tot == 0) != a.negative else 1


if __name__ == '__main__':
    sys.exit(main())
