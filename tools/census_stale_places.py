#!/usr/bin/env python3
"""census_stale_places.py — S138 (ROADMAP ARC CAP2e): every per-room reader of the
patched engine, asked about a map id this build has NO place for, returns its
defined fallback — and asked about a vanilla id or a real place, returns what it
did before S138.

A "stale" id is a custom map id ($6B-$FE) the build has no place for: a
PLACEHOLDER (a deleted room's id inside the dense range — CustomRoomFlagsTable
bit 7) or an id PAST the last room. A save standing in one used to hang at
CONTINUE (S137: bank $71 entry 0 read Custom26DDTable past its end).

Stub calls on the built ROM (PYBOY_DEBUGGING "S130 / S136 techniques", the
census_place_banks Stub): the ROM boots to the title screen; the inputs are
poked, `di / ld hl,$bbee / rst $10 / <store BC DE HL> / marker / jr $` runs at
$DD40. Expected values come from the SAME ROM (game.sym labels, ROM0 rows) or
from a reference call with map id 0 (the Castle), so the census proves the
routing, not a copy of the compiler's arithmetic:

  * bank $71 entry 0 CopyCustomRoomRecord: vanilla ids $00-$6A == the ROM0
    $26DD row (gate ids $00-$1F with wInGateworld 1: the $2A5D row); real places
    == their ROM0 row ($6B-$6F) / Custom26DDTable row ($70+); stale ids == the
    Castle's row (map 0) — the S137 hang;
  * entry 1 CustomEncResolve: stale -> wRoomEncFlag 0;
  * entries 2 / 7 (room / battle song): == editor2/core/music.py's models for
    every id $00-$FE (the 256-row tables, no `cp $80` since S138);
  * entry 3 CustomAnimSource (+ bank $6C entry 0): stale -> E = $6B (none);
  * entry 5 CustomRoomFlags: real places == their table byte (bit 7 clear),
    stale == $81 (no such place, no saving), vanilla == 0;
  * entry 10 ContinueCheck: vanilla ids / real places / any id with
    wInGateworld 1 -> E = 0 and the warp mailbox untouched; stale -> E = 1,
    the mailbox == the hub (the first HubTable rule that holds with no flag
    set; else the Castle at ($E8, $58)), wIsPlayerChangingMaps 1, $C8EA 1,
    wHubReason 7 for a project room (0 for the Castle), $D92B untouched;
  * bank $60 entries 0 / 1 / 2 / 13: stale -> the dummy step $2A01, an empty NPC
    list, DummyExits, HL 0 (the render fallback);
  * bank $17 entries 0 / 1 (palette / attr walk): stale == map 0's result for
    the same screen (the Castle fallback);
  * bank $76 entry 0 EncResolve, bank $6C entry 0: return (no hang).

  python3 tools/census_stale_places.py --project DIR            # builds it
  python3 tools/census_stale_places.py --project DIR --rom R --sym S
  --hole N: first copy the project to OUT and delete its N-th room (a
  placeholder appears there); --negative: one expected record is corrupted and
  the census must fail.
"""
import argparse
import copy
import json
import os
import random
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.census_place_banks import Stub, Rom, sym_table     # noqa: E402

SCR = 0xC925


def make_hole(src_dir, out_dir, n):
    """A copy of the project with its n-th room (by map id) deleted — the editor's
    delete_room leaves its map id to the compiler's placeholder."""
    if os.path.abspath(src_dir) != os.path.abspath(out_dir):
        if os.path.exists(out_dir):
            shutil.rmtree(out_dir)
        shutil.copytree(src_dir, out_dir, ignore=shutil.ignore_patterns('build'))
    from editor2.core.document import Document
    d = Document(os.path.join(out_dir, 'project.json'))
    rooms = sorted(d.rooms, key=lambda r: int(str(r['mapID']), 0))
    if not 0 < n < len(rooms) - 1:
        raise SystemExit(f"--hole {n}: pick a room between the first and the last "
                         f"(1-{len(rooms) - 2})")
    victim = rooms[n]
    d.delete_room(victim['id'])
    d.save()
    return victim['id'], int(str(victim['mapID']), 0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--project', required=True)
    ap.add_argument('--rom')
    ap.add_argument('--sym')
    ap.add_argument('--hole', type=int, default=0, metavar='N')
    ap.add_argument('--out', help='with --hole: where the holed copy goes')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--seed', type=int, default=138)
    a = ap.parse_args()
    if a.hole:
        out = a.out or a.project.rstrip('/') + '_hole'
        rid, mid = make_hole(a.project, out, a.hole)
        print(f"hole: room {rid} (${mid:02X}) deleted in {out}")
        a.project = out
        a.rom = a.sym = None
    from editor2.core import compiler as C
    from editor2.core import formats as F
    from editor2.core import music as M
    if a.rom is None:
        from editor2.core import builder as B
        outd = os.path.join(a.project, 'build')
        outputs, prj, _w = C.compile_project(a.project, REPO)
        C.write_outputs(outputs, outd)
        a.rom, a.sym, _md5 = B.build_rom(REPO, outd, os.path.join(outd, 'build'))
    else:
        _o, prj, _w = C.compile_project(a.project, REPO)
    sym = sym_table(a.sym)
    rom = Rom(a.rom)
    w = {k: sym[k][1] for k in (
        'wMapID', 'wInGateworld', 'wRoomRecScratch', 'wRoomEncFlag', 'wHubReason',
        'wWarpGateId', 'wWarpFlag', 'wWarpSpawnXLo', 'wIsPlayerChangingMaps',
        'wCustomNPCBuffer', 'wCustomExitBuffer', 'wScriptStateFlags', 'wGateID',
        'wCurrentFloor', 'wLastFloor', 'wBossMapType', 'wArenaStarryBattle')}
    places = {F.val(r['mapID']): r for r in prj.rooms}
    real = sorted(m for m, r in places.items() if not r.get('placeholder'))
    holes = sorted(m for m, r in places.items() if r.get('placeholder'))
    past = list(range(0x6B + len(prj.rooms), 0xFF))
    stale = holes + past
    S = Stub(a.rom)
    m = S.m
    bad, n, first = {}, {}, []

    def check(kind, got, want, ctx):
        if a.negative and kind == 'rec_stale' and n.get(kind, 0) == 0:
            want = [want[0] ^ 1] + list(want[1:])
        n[kind] = n.get(kind, 0) + 1
        if got != want:
            bad[kind] = bad.get(kind, 0) + 1
            if len(first) < 12:
                first.append((kind, ctx, got, want))

    def rec(mid, gate=0):
        S.reload()
        for i in range(8):
            m[w['wRoomRecScratch'] + i] = 0xEE
        S.call(0x00, [(w['wMapID'], mid), (w['wInGateworld'], gate)], bank=0x71)
        return [m[w['wRoomRecScratch'] + i] for i in range(8)]

    rom0 = lambda base, i: list(rom.b[base + 8 * i: base + 8 * i + 8])
    castle = rom0(0x26DD, 0)
    # ---- entry 0: the room record ------------------------------------------------
    for mid in range(0x00, 0x6B):
        check('rec_vanilla', rec(mid), rom0(0x26DD, mid), F.hexb(mid))
    for mid in range(0x00, 0x20):
        check('rec_gate', rec(mid, 1), rom0(0x2A5D, mid), F.hexb(mid))
    cb, ca = sym['Custom26DDTable']
    for mid in real:
        want = rom0(0x26DD, mid) if mid < 0x70 else list(rom.at(cb, ca + 8 * (mid - 0x70), 8))
        check('rec_place', rec(mid), want, F.hexb(mid))
    for mid in stale:
        check('rec_stale', rec(mid), castle, F.hexb(mid))

    # ---- entries 1 / 3 / 5 ---------------------------------------------------------
    fb, fa = sym['CustomRoomFlagsTable']
    for mid in list(range(0x00, 0x6B, 9)) + real + stale:
        S.reload()
        got = S.call(0x05, [(w['wMapID'], mid)], bank=0x71)
        e = got['DE'] & 0xFF
        if mid < 0x6B:
            want = 0
        elif mid in stale:
            want = 0x81
        else:
            want = rom.u8(fb, fa + mid - 0x6B)
            check('flags_place_bit7', want & 0x80, 0, F.hexb(mid))
        check('flags', e, want, F.hexb(mid))
    for mid in stale:
        S.reload()
        m[w['wRoomEncFlag']] = 0xEE
        S.call(0x01, [(w['wMapID'], mid), (w['wInGateworld'], 0)], bank=0x71)
        check('enc_stale', m[w['wRoomEncFlag']], 0, F.hexb(mid))
        S.reload()
        got = S.call(0x03, [(w['wMapID'], mid), (w['wInGateworld'], 0)], bank=0x71)
        check('anim_stale', got['DE'] & 0xFF, 0x6B, F.hexb(mid))
        S.reload()
        S.call(0x00, [(w['wMapID'], mid), (w['wInGateworld'], 0)], bank=0x6C)
        check('tileanim_stale_returns', True, True, F.hexb(mid))
        S.reload()
        S.call(0x00, [(w['wMapID'], mid), (w['wInGateworld'], 0)], bank=0x76)
        check('enc76_stale_returns', True, True, F.hexb(mid))

    # ---- entries 2 / 7: the 256-row music tables ----------------------------------
    P = prj.music_plan()
    rnd = random.Random(a.seed)
    for mid in range(0x00, 0xFF):
        ctx = {'in_gate': 0, 'map': mid, 'gate': rnd.choice([0, 1, 5, 40]), 'floor': 0,
               'last': 5, 'boss_map': 0x30, 'link': 0, 'starry': 0, 'eid': 1, 'mode': 0}
        pokes = [(w['wInGateworld'], 0), (w['wMapID'], mid), (w['wGateID'], ctx['gate']),
                 (w['wCurrentFloor'], 0), (w['wLastFloor'], 5), (w['wBossMapType'], 0x30),
                 (w['wArenaStarryBattle'], 0), (0xC86C, 0), (0xDA03, 1), (0xDA04, 0),
                 (0xDA09, 0)]
        S.reload()
        got = S.call(0x02, pokes, bank=0x71)
        check('bgm_room', got['DE'] & 0xFF, M.model_room_bgm(P, ctx), F.hexb(mid))
        S.reload()
        got = S.call(0x07, pokes, bank=0x71)
        check('bgm_battle', got['DE'] & 0xFF, M.model_battle_bgm(P, ctx), F.hexb(mid))
    # a custom boss room past $7F on the floor before the boss floor
    for bm in [x for x in real if x >= 0x80][:4]:
        ctx = {'in_gate': 1, 'map': 3, 'gate': 1, 'floor': 3, 'last': 5, 'boss_map': bm}
        S.reload()
        got = S.call(0x02, [(w['wInGateworld'], 1), (w['wMapID'], 3), (w['wGateID'], 1),
                            (w['wCurrentFloor'], 3), (w['wLastFloor'], 5),
                            (w['wBossMapType'], bm)], bank=0x71)
        check('bgm_boss80', got['DE'] & 0xFF, M.model_room_bgm(P, ctx), F.hexb(bm))

    # ---- entry 10: ContinueCheck ---------------------------------------------------
    hub = None
    for ru in prj.hub_rules():
        if all(must_clear for _f, must_clear in ru['terms']):
            hub = ru
            break
    if hub is None or hub.get('castle'):
        want_box = [0x00, 0x00, 0xE8, 0x00, 0x58, 0x00]
        want_reason = 0
    else:
        want_box = [hub['mapID'], 0x00, hub['px'] & 0xFF, hub['px'] >> 8,
                    hub['py'] & 0xFF, hub['py'] >> 8]
        want_reason = 7
    BOX = [w['wWarpGateId'], w['wWarpFlag'], w['wWarpSpawnXLo'], w['wWarpSpawnXLo'] + 1,
           w['wWarpSpawnXLo'] + 2, w['wWarpSpawnXLo'] + 3]

    def cont(mid, gate=0):
        S.reload()
        pokes = [(w['wMapID'], mid), (w['wInGateworld'], gate), (0xD92B, 0x5A),
                 (w['wIsPlayerChangingMaps'], 0), (0xC8EA, 0x80), (w['wHubReason'], 0)]
        pokes += [(x, 0xEE) for x in BOX]
        # every flag clear: the vanilla flags ($D99B-$D9E9 in the save image) and the
        # extended ones (wExtFlags, 256 B); a hub term on a story check ($18xx) is
        # judged by the game, not here
        pokes += [(x, 0) for x in range(0xD99B, 0xD9EA)]
        pokes += [(sym['wExtFlags'][1] + i, 0) for i in range(256)]
        got = S.call(0x0A, pokes, bank=0x71)
        return (got['DE'] & 0xFF, [m[x] for x in BOX], m[w['wIsPlayerChangingMaps']],
                m[0xC8EA], m[w['wHubReason']], m[0xD92B])
    has_cont = 'ContinueCheck' in sym          # a pre-S138 build has no entry 10
    for mid in (list(range(0x00, 0x6B, 5)) + real) if has_cont else []:
        e, box, ch, f, hr, d9 = cont(mid)
        check('cont_keep', (e, box, ch, f, d9), (0, [0xEE] * 6, 0, 0x80, 0x5A), F.hexb(mid))
    for mid in (stale[:6] + stale[-3:]) if has_cont else []:
        e, box, ch, f, hr, d9 = cont(mid, gate=1)
        check('cont_gate_keep', (e, ch), (0, 0), F.hexb(mid))
    for mid in stale if has_cont else []:
        e, box, ch, f, hr, d9 = cont(mid)
        check('cont_stale', (e, box, ch, f, hr, d9),
              (1, want_box, 1, 1, want_reason, 0x5A), F.hexb(mid))

    # ---- bank $60 entries 0 / 1 / 2 / 13 + bank $17 entries 0 / 1 ---------------------
    db, da = sym['DummyExits']
    dummy_exits = list(rom.at(db, da, 36))

    def b17(mid, entry, scr=0):
        S.reload()
        if entry == 1:
            for i in range(0x100):
                m[0xC200 + i] = 0xEE
        else:
            for i in range(32):
                m[0xC797 + i] = 0xEE
        S.call(entry, [(w['wMapID'], mid), (SCR, scr), (w['wInGateworld'], 0)], bank=0x17)
        return [m[(0xC200 if entry == 1 else 0xC797) + i] for i in range(0x100 if entry == 1 else 32)]
    castle_attr = {k: b17(0x00, 1, k) for k in (0, 1)}
    castle_pal = {k: b17(0x00, 0, k) for k in (0, 1)}
    for mid in stale:
        S.reload()
        got = S.call(0x00, [(w['wMapID'], mid), (SCR, 0)])
        check('step_stale', got['DE'], 0x2A01, F.hexb(mid))
        S.reload()
        m[w['wCustomNPCBuffer']] = 0xEE
        S.call(0x01, [(w['wMapID'], mid), (SCR, 0)])
        check('npc_stale', m[w['wCustomNPCBuffer']], 0xFF, F.hexb(mid))
        S.reload()
        S.call(0x02, [(w['wMapID'], mid), (SCR, 0)])
        check('exit_stale', [m[w['wCustomExitBuffer'] + i] for i in range(36)],
              dummy_exits, F.hexb(mid))
        S.reload()
        got = S.call(0x0D, [(w['wMapID'], mid), (SCR, 0)])
        check('render_stale', got['HL'], 0, F.hexb(mid))
        for k in (0, 1):
            check('b17_attr_stale', b17(mid, 1, k), castle_attr[k], (F.hexb(mid), k))
            # a custom id loads slots 0-3 with the engine's custom-room forcing:
            # colour 1 := slot 7's colour 1, colour 3 := slot 7's colour 3 (S137
            # census) — the Castle's REAL colours are 0 and 2
            got = b17(mid, 0, k)
            c1, c3 = [m[0xC7D1], m[0xC7D2]], [m[0xC7D5], m[0xC7D6]]
            want = []
            for sl in range(4):
                row = castle_pal[k][8 * sl:8 * sl + 8]
                want += row[0:2] + c1 + row[4:6] + c3
            check('b17_pal_stale', got, want, (F.hexb(mid), k))
    S.p.stop(save=False)
    for f in first:
        print('MISMATCH', f)
    tot = sum(bad.values())
    print(f"{sum(n.values())} checks (vanilla ids, {len(real)} places, {len(holes)} "
          f"placeholders, {len(past)} ids past the last room): "
          f"{sum(n.values()) - tot} identical, {tot} mismatched "
          f"{ {k: (n[k], bad.get(k, 0)) for k in sorted(n)} }"
          + (' (negative control)' if a.negative else ''))
    return 0 if (tot == 0) != a.negative else 1


if __name__ == '__main__':
    sys.exit(main())
