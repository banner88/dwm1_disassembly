#!/usr/bin/env python3
"""census_regions.py — S140 (ROADMAP ARC CAP3a): REGIONS — more than 128 places.

A custom place is (wMapRegion, wMapID): a project mapID carries its region in the
high byte ($6B-$EA = region 0, $16B-$1EA = region 1, ...). This census builds a
GENERATED project of hundreds of places in several regions — on top of a base
project (default: the example; the user's project brings its arena copies = the
GLOBAL ids) — and proves every region-specific path of the engine by stub calls
on the built ROM (PYBOY_DEBUGGING "S130 / S136 techniques"; the census_place_banks
Stub). Expected values come from the SAME ROM (game.sym, the ROM's own
RegionTable / GlobalPlaceIds read like the engine's PlaceNum, the emitted rows) or
from the project model, so the census proves the routing, not a copy of the
compiler's arithmetic:

  * the build: no rgbasm truncation (builder refuses one; a region's mapID put
    where a real map id belongs would be one);
  * place numbers: every bank's RegionTable / GlobalPlaceIds ($60 / $6C / $71 /
    $76) are the same bytes; RegionTable == the project's regions;
  * an exit row into another region (`$FD <region>` prefix): bank $60 entry 2
    copies it with a LINK id ($EB + n) and notes (region, real id) in
    wExitLinks; then the room commit (bank $73 entry 0, wMapID := that link id)
    leaves wMapID = the real id, wMapRegion = the region, the regional counter
    area (wCustomStepRegional .. $CFFF) zeroed and wNpcColourMap /
    wTileAnimRoom = $FF; an unprefixed row (same region) commits with the
    region and the counters untouched; and after the commit the destination's
    record (bank $71 entry 0) is Custom26DDTable[its place number];
  * wWarpRegion (region + 1): the commit enters it and clears it; 0 = keep;
  * a script warp into another region: the room's script words hold
    `$FF12 wWarpRegion region+1` right before `$FF0F <real id>` (op $12 then $0F),
    a same-region warp has no write; no warp word holds a region's mapID;
  * bank $71 entry 9 HubWarp: the hub room's real id in the mailbox and
    wWarpRegion = its region + 1; entry 4 (gate insert): wMapID = the served
    room's real id and wMapRegion = its region; entry 11 (the boss floor):
    wMapRegion = the gate's boss region, entry 12 E = it;
  * bank $76 entry 2 GateBossWin: the boss room in its own region marks the gate
    cleared; the same map id in another region does not;
  * a GLOBAL place (the arena copies) in any region reads region 0's place.
Then the place-bank and stale-place censuses run on the same build (both
region-aware since S140).

  python3 tools/census_regions.py                       # example + 4 regions
  python3 tools/census_regions.py --base DIR --out DIR --regions 4 --per-region 80
  --negative: one expected link region is corrupted and the census must fail.
"""
import argparse
import json
import os
import random
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.census_place_banks import (Stub, Rom, sym_table, rom_place_number,  # noqa: E402
                                      mid_pokes, exit_copy_model, EXAMPLE)

SCR = 0xC925


def _mid(r):
    return int(str(r['mapID']), 0)


def make_regions(base, out, regions=4, per_region=80, seed=140):
    """A copy of `base` + `per_region` new places in each region 1 .. regions-1
    and as many in region 0 as fit ($EA): one screen each (the base's first room
    with a layout), a door row to the next new place (crossing the regions at
    their edges), an NPC that warps to a place half the list away (another
    region), every 5th a room song, every 7th own encounters, every 9th two
    states + a state rule (a step counter); the hub = region 2's first place, a
    gate insert into region 1, gate 5's boss = a region 2 place, GreatTree 2F
    (6, 5) redirected into region 3. Returns (data, [new mapIDs])."""
    if os.path.exists(out):
        shutil.rmtree(out)
    shutil.copytree(base, out, ignore=shutil.ignore_patterns('build'))
    pj = os.path.join(out, 'project.json')
    d = json.load(open(pj))
    c = d['custom']
    tmpl = next(r for r in c['rooms'] if not r.get('placeholder') and r.get('record')
                and 'layout' in ((r.get('screens') or {}).get('0') or {})
                and isinstance(r['screens']['0']['layout'], dict)
                and 'width_px' in r['record'])
    ar = c.get('arena') or {}
    glob = {_mid(r) & 0xFF for r in c['rooms'] if r.get('id') in (ar.get('lobby'), ar.get('battle'))}
    used = {_mid(r) for r in c['rooms']}
    mids = []
    m = max(x for x in used if x <= 0xEA) + 1
    while m <= 0xEA and len(mids) < per_region:
        mids.append(m)
        m += 1
    for reg in range(1, regions):
        i = 0x6B
        while len([x for x in mids if x >> 8 == reg]) < per_region:
            if i not in glob:
                mids.append((reg << 8) | i)
            i += 1
    rng = random.Random(seed)
    c.setdefault('flags', []).append({'name': 'region_rule_flag', 'index': 'auto'})
    music = c.setdefault('music', {}).setdefault('room_defaults', {})
    rid = {mm: f"reg{mm >> 8}_{mm & 0xFF:02x}" for mm in mids}
    n = len(mids)
    for k, mm in enumerate(mids):
        reg = mm >> 8
        nxt = mids[(k + 1) % n]
        far = mids[(k + n // 2 + 7) % n]
        c['dialogue'].append({'id': f"{rid[mm]}_t",
                              'text': f"REGION {reg} ROOM {mm & 0xFF:02X}."})
        c['scripts'] += [{'id': f"{rid[mm]}_entry", 'ops': [['end']]},
                         {'id': f"{rid[mm]}_talk",
                          'talk': {'text': f"{rid[mm]}_t", 'question': False,
                                   'then': {'move': {'dest': f"room:${far:X}", 'screen': 0,
                                                     'x': 2, 'y': 2}}}}]
        npc = {'kind': 'npc', 'sprite': '0x0B', 'x': 2, 'y': 3, 'facing': 'down',
               'script': f"{rid[mm]}_talk"}
        door = {'x': 9, 'y': 3, 'dest': f"room:${nxt:X}", 'screen_byte': '0x00',
                'spawn_x': 1, 'spawn_y': 3}
        scr = {'layout': dict(tmpl['screens']['0']['layout']), 'npcs': [npc], 'exits': [door]}
        room = {'id': rid[mm], 'mapID': f"0x{mm:X}", 'source_mapID': tmpl.get('source_mapID', '0x04'),
                'record': dict(tmpl['record'], width_px=160, height_px=128),
                'render': dict(tmpl.get('render') or {}),
                'scripts': {'0': f"{rid[mm]}_entry", '1': f"{rid[mm]}_talk"},
                'screens': {'0': scr}, 'animation': 'none'}
        if k % 5 == 0:
            music[f"0x{mm:X}"] = rng.choice(['0x09', '0x1E', '0x31'])
        if k % 7 == 0:
            room['encounters'] = {'enabled': True, 'gate_id': 3, 'floor': 1}
        if k % 9 == 0:
            scr['states'] = [{'npcs': [npc], 'exits': [door]}, {'npcs': [npc], 'exits': [door]}]
            del scr['npcs'], scr['exits']
            room['state_rules'] = [{'state': 1, 'when': [{'flag': 'region_rule_flag'}]},
                                   {'state': 0, 'when': []}]
        c['rooms'].append(room)
    r2 = [mm for mm in mids if mm >> 8 == 2]
    r1 = [mm for mm in mids if mm >> 8 == 1]
    r3 = [mm for mm in mids if mm >> 8 == 3]
    if r2:
        c['hub'] = {'rules': [{'room': rid[r2[0]], 'screen': 0, 'x': 2, 'y': 2}]}
        boss = next(r for r in c['rooms'] if r['id'] == rid[r2[1]])
        boss['gate_arrival'] = {'screen': 0, 'x': 4, 'y': 4}
        boss.pop('encounters', None)
        c.setdefault('gates', []).append({'gate': 5, 'boss': rid[r2[1]]})
    if r1:
        ins = next(r for r in c['rooms'] if r['id'] == rid[r1[3]])
        ins['gate_arrival'] = {'screen': 0, 'x': 4, 'y': 4}
        ins.pop('encounters', None)
        sc0 = ins['screens']['0']
        for st in (sc0.get('states') or [sc0]):
            st['exits'] = st['exits'] + [{'x': 5, 'y': 5, 'stairs': 'down'}]
        c.setdefault('gate_inserts', []).append({'room': rid[r1[3]], 'gate': 4,
                                                 'floors': [2, 3], 'chance': 100})
    if r3:
        c.setdefault('entrance_redirects', []).append(
            {'mapID': '0x01', 'screen': 8, 'x': 6, 'y': 5, 'dest': f"room:${r3[0]:X}",
             'screen_byte': '0x00', 'spawn_x': 2, 'spawn_y': 2,
             'comment': 'S140 census: GreatTree 2F (6, 5) -> region 3'})
    json.dump(d, open(pj, 'w'), indent=1)
    return d, mids


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--base', default=EXAMPLE)
    ap.add_argument('--out', default=None)
    ap.add_argument('--regions', type=int, default=4)
    ap.add_argument('--per-region', type=int, default=80)
    ap.add_argument('--project', help='census an existing (multi-region) project instead')
    ap.add_argument('--rom')
    ap.add_argument('--sym')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--no-sub', action='store_true', help='skip the two sub-censuses')
    a = ap.parse_args()
    if a.project is None:
        out = a.out or os.path.join('/tmp', 'census_regions_project')
        _d, _mids = make_regions(a.base, out, a.regions, a.per_region)
        a.project = out
        a.rom = a.sym = None
    from editor2.core import compiler as C
    from editor2.core import formats as F
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
        'wMapID', 'wMapRegion', 'wWarpRegion', 'wExitLinks', 'wInGateworld', 'wWarpFlag',
        'wWarpGateId', 'wRoomRecScratch', 'wCustomExitBuffer', 'wNpcColourMap',
        'wTileAnimRoom', 'wGateID', 'wCurrentFloor', 'wLastFloor', 'wBossMapType',
        'wHubReason', 'wGateDiveGate', 'wGateDiveMask', 'wAnchorArm')}
    regional = prj.step_counter_overlay()[1]      # an EQU (not in game.sym): the model's
    bad, n, first = {}, {}, []

    def check(kind, got, want, ctx):
        if a.negative and kind == 'commit_link' and n.get(kind, 0) == 0:
            want = (want[0], want[1] ^ 1) + tuple(want[2:])
        n[kind] = n.get(kind, 0) + 1
        if got != want:
            bad[kind] = bad.get(kind, 0) + 1
            if len(first) < 14:
                first.append((kind, ctx, got, want))

    places = [r for r in prj.rooms if not r.get('placeholder')]
    regs = sorted({_mid(r) >> 8 for r in places})
    print(f"project: {len(prj.rooms)} places ({len(places)} rooms) in regions "
          f"{regs}, region table {prj.regions}, global ids "
          f"{[F.hexb(g) for g in prj.global_ids]}")
    # ---- the region tables: one set of bytes in every bank ----------------------
    def tbl(sfx):
        tb, ta = sym['RegionTable' + sfx]
        cnt = rom.u8(tb, ta)
        rows = [(rom.u8(tb, ta + 1 + 3 * i), rom.u16(tb, ta + 2 + 3 * i)) for i in range(cnt)]
        gb, ga = sym['GlobalPlaceIds' + sfx]
        g = []
        while rom.u8(gb, ga) != 0xFF:
            g.append(rom.u8(gb, ga))
            ga += 1
        return rows, g
    ref = tbl('60')
    for sfx in ('6C', '71', '76'):
        check('region_tables', tbl(sfx), ref, sfx)
    check('region_tables_model', ref, ([tuple(x) for x in prj.regions],
                                       [g - 0x6B for g in prj.global_ids]), '60')
    for r in prj.rooms:
        mm = _mid(r)
        check('place_number', rom_place_number(rom, sym, mm), prj.place_number(mm), F.hexb(mm))
        if r.get('global_alias'):                  # an arena id in region 1+: region 0's room
            check('global_alias', prj.place_number(mm), prj.place_number(mm & 0xFF), F.hexb(mm))
    for g in prj.global_ids:
        for reg in regs:
            check('global', rom_place_number(rom, sym, (reg << 8) | g),
                  prj.place_number(g), (reg, F.hexb(g)))

    S = Stub(a.rom)
    m = S.m
    cb, ca = sym['Custom26DDTable']

    def commit(link_or_id, region0, warp_region=0, preset_links=None):
        """bank $73 entry 0 with wMapID := link_or_id; returns (wMapID, wMapRegion,
        wWarpRegion, counters zero?, caches)."""
        pokes = [(w['wMapID'], link_or_id), (w['wMapRegion'], region0),
                 (w['wWarpRegion'], warp_region), (w['wWarpFlag'], 0),
                 (w['wNpcColourMap'], 0x6C), (w['wTileAnimRoom'], 0x6C), (w['wAnchorArm'], 0)]
        if regional is not None:
            pokes += [(x, 0x5A) for x in range(regional, 0xD000)]
        for i, v in enumerate(preset_links or []):
            pokes.append((w['wExitLinks'] + i, v))
        S.call(0x00, pokes, bank=0x73)
        zero = all(m[x] == 0 for x in range(regional, 0xD000)) if regional else None
        kept = all(m[x] == 0x5A for x in range(regional, 0xD000)) if regional else None
        return (m[w['wMapID']], m[w['wMapRegion']], m[w['wWarpRegion']],
                'zero' if zero else 'kept' if kept else 'mixed',
                (m[w['wNpcColourMap']], m[w['wTileAnimRoom']]))

    # ---- exits: copy (bank $60 entry 2) then commit (bank $73 entry 0) -----------
    rnd = random.Random(140)
    for r in places:
        mm = _mid(r)
        for k, scr in sorted(prj.room_screens(r).items()):
            from editor2.core import emitters as E
            sb, sa = sym[f"{E.room_tag(r)}_Screen{k}"]
            exit_ptr = rom.u16(sb, sa + 6)               # state 0's exit list
            raw = rom.at(sb, exit_ptr, 9 * 18 + 1)
            want, links = exit_copy_model(raw)
            S.reload()
            S.call(0x02, [*mid_pokes(sym, mm), (SCR, k), (sym['wInGateworld'][1], 0)])
            buf = [m[w['wCustomExitBuffer'] + i] for i in range(len(want))]
            check('exit_copy', buf, want, (r['id'], k))
            lk = [m[w['wExitLinks'] + i] for i in range(2 * len(links))]
            check('exit_links', lk, [x for p in links for x in p], (r['id'], k))
            # every row: its destination as the model says, then commit it
            for e in (prj.screen_states(scr)[0].get('exits') or []):
                dest_s = e['dest']
                if not str(dest_s).startswith('room:'):
                    continue
                dmid = prj.resolve_dest(dest_s)
                pre = prj.exit_prefix(r, dmid)
                if pre:
                    slot = 0xEB + [x for x in range(len(links))
                                   if links[x] == (pre[1], dmid & 0xFF)][0]
                    got = commit(slot, mm >> 8, 0, lk)
                    dreg = dmid >> 8
                    want_c = (dmid & 0xFF, dreg, 0, 'zero' if dreg != mm >> 8 else 'kept',
                              (0xFF, 0xFF) if dreg != mm >> 8 else (0x6C, 0x6C))
                    check('commit_link', got, want_c, (r['id'], F.hexb(dmid)))
                    # and the destination's record now (bank $71 entry 0)
                    for i in range(8):
                        m[w['wRoomRecScratch'] + i] = 0xEE
                    S.call(0x00, [(w['wInGateworld'], 0)], bank=0x71)
                    rec = [m[w['wRoomRecScratch'] + i] for i in range(8)]
                    check('commit_record', rec,
                          list(rom.at(cb, ca + 8 * prj.place_number(dmid), 8)), F.hexb(dmid))
                else:
                    S.reload()
                    got = commit(dmid & 0xFF, mm >> 8)
                    reg = 0 if prj.is_global(dmid) else mm >> 8
                    check('commit_same', got[:4], (dmid & 0xFF, mm >> 8, 0, 'kept'),
                          (r['id'], F.hexb(dmid)))
                    check('same_region_dest', reg == dmid >> 8 or prj.is_global(dmid), True,
                          (r['id'], F.hexb(dmid)))
    # ---- vanilla rooms' redirect rows (bank $60 entry 7 VanillaExitResolve) -------
    vt = sym['VanillaExitExtTable']
    a0 = vt[1]
    while rom.u8(vt[0], a0) != 0xFF:
        vmid, vscr = rom.u8(vt[0], a0), rom.u8(vt[0], a0 + 1)
        ctr = rom.u16(vt[0], a0 + 2)
        nst = rom.u8(vt[0], a0 + 4)
        lst = rom.u16(vt[0], a0 + 5)               # variant 0
        raw = rom.at(vt[0], lst, 9 * 18 + 1)
        want, links = exit_copy_model(raw)
        for reg0 in regs:
            S.reload()
            got = S.call(0x07, [(w['wMapID'], vmid), (w['wMapRegion'], reg0),
                                (SCR, vscr if vscr != 0xFF else 0), (ctr, 0),
                                (sym['wInGateworld'][1], 0)])
            buf = [m[w['wCustomExitBuffer'] + i] for i in range(len(want))]
            check('vexit_copy', (got['HL'], buf), (w['wCustomExitBuffer'], want), (F.hexb(vmid), reg0))
            lk = [m[w['wExitLinks'] + i] for i in range(2 * len(links))]
            for k2, (lreg, lid) in enumerate(links):
                got = commit(0xEB + k2, reg0, 0, lk)
                check('vexit_commit', got[:4],
                      (lid, lreg, 0, 'zero' if lreg != reg0 else 'kept'), (F.hexb(vmid), reg0, k2))
        a0 += 5 + 2 * nst
    # ---- wWarpRegion -------------------------------------------------------------
    for reg in regs:
        for start in regs[:2]:
            S.reload()
            got = commit(0x6B, start, reg + 1)
            check('commit_pending', got[:4],
                  (0x6B, reg, 0, 'zero' if reg != start else 'kept'), (start, reg))
    S.reload()
    check('commit_vanilla_keeps', commit(0x01, 2)[:4], (0x01, 2, 0, 'kept'), 'vanilla')

    # ---- script warps: the words in the ROM --------------------------------------
    from editor2.core import emitters as E
    for r in places:
        mm = _mid(r)
        for idx, sid in prj.room_script_table(r):
            lb = f"{E.room_tag(r)}_Scr{idx:02d}"
            sb, sa = sym[lb]
            ops = E._patch_params(r, prj.script(sid).get('ops') or [])
            tgts = [int(str(op[2]), 0) for op in ops
                    if isinstance(op, list) and len(op) > 2 and op[0] == 'op'
                    and str(op[1]) in E.WARP_OPS and not str(op[2]).startswith('@')]
            if not tgts:
                continue
            # walk the emitted words op by op (scriptgen: $FFnn + its params)
            from editor2.core import scriptgen as SG
            words, i, found = [], 0, []
            nwords = 4 * len(ops) + 8
            words = [rom.u16(sb, sa + 2 * j) for j in range(nwords)]
            j = 0
            while j < len(words) and len(found) < len(tgts):
                wd = words[j]
                if wd in (0xFF0F, 0xFF3B) and j + 1 < len(words):
                    found.append((j, words[j + 1]))
                    j += 4
                    continue
                j += 1
            for (j, dest), tgt in zip(found, tgts):
                if (tgt & 0xFF) < 0x6B:
                    check('warp_vanilla', dest, tgt, (lb, j))
                    continue
                check('warp_word_real', dest >> 8, 0, (lb, j))
                need = (not prj.is_global(tgt)) and (prj.is_global(mm) or tgt >> 8 != mm >> 8)
                pre = words[j - 3:j] if j >= 3 else []
                has = pre[:1] == [0xFF12] and pre[1:2] == [w['wWarpRegion']]
                check('warp_region_write', (has, pre[2] if has else None),
                      (need, (tgt >> 8) + 1 if need else None), (lb, F.hexb(tgt)))
                check('warp_real', dest, tgt & 0xFF, (lb, F.hexb(tgt)))
    # ---- hub / gate insert / boss ------------------------------------------------
    hub = next((ru for ru in prj.hub_rules() if not ru['castle']), None)
    if hub:
        S.reload()
        S.call(0x09, [(w['wWarpRegion'], 0)] + [(x, 0) for x in range(0xD99B, 0xD9EA)],
               bank=0x71)
        check('hub', (m[w['wWarpGateId']], m[w['wWarpRegion']]),
              (hub['mapID'] & 0xFF, (hub['mapID'] >> 8) + 1), F.hexb(hub['mapID']))
    for row in prj.gate_insert_rows():
        S.reload()
        S.call(0x04, [(w['wGateID'], row['gate'] if row['gate'] != 0xFE else 4),
                      (w['wCurrentFloor'], row['first'] - 1), (w['wGateDiveGate'], 0),
                      (w['wGateDiveMask'], 0), (w['wMapRegion'], 3 if len(regs) > 3 else 0)]
               + [(x, 0) for x in range(0xD99B, 0xD9EA)], bank=0x71)
        check('gate_insert', (m[w['wMapID']], m[w['wMapRegion']], m[w['wInGateworld']]),
              (row['mapID'] & 0xFF, row['mapID'] >> 8, 0), row['room_id'])
    cfg = prj.gate_configs()
    for gid in sorted(cfg):
        c = cfg[gid]
        S.reload()
        S.call(0x0B, [(w['wGateID'], gid), (w['wMapRegion'], 1 if len(regs) > 1 else 0)],
               bank=0x71)
        check('boss_region', m[w['wMapRegion']], c.get('boss_region', 0), gid)
        S.reload()
        got = S.call(0x0C, [(w['wGateID'], gid)], bank=0x71)
        check('boss_region_of', got['DE'] & 0xFF, c.get('boss_region', 0), gid)
        if c.get('boss_room') and c.get('boss_region'):
            bm = c['boss_map']
            ft = sym['GateClearTable']
            fl = rom.u16(ft[0], ft[1] + 6 * gid)
            if fl == 0xFFFF:
                continue
            for reg, want in ((bm >> 8, True), ((bm >> 8) ^ 1, False)):
                S.reload()
                fa = sym['wExtFlags'][1] + ((fl - 0x1000) >> 3) if fl >= 0x1000 else 0xD99B + (fl >> 3)
                msk = 0x80 >> (fl & 7)
                S.call(0x02, [(w['wInGateworld'], 0), (w['wBossMapType'], bm & 0xFF),
                              (w['wMapID'], bm & 0xFF), (w['wMapRegion'], reg),
                              (w['wGateID'], gid), (w['wCurrentFloor'], c['floors'] - 1),
                              (w['wLastFloor'], c['floors']), (fa, 0)], bank=0x76)
                check('boss_win', bool(m[fa] & msk), want, (gid, reg))
    S.p.stop(save=False)
    for f in first:
        print('MISMATCH', f)
    tot = sum(bad.values())
    print(f"census_regions: {sum(n.values())} checks over {len(prj.rooms)} places in "
          f"{len(prj.regions)} regions: {sum(n.values()) - tot} identical, {tot} mismatched "
          f"{ {k: (n[k], bad.get(k, 0)) for k in sorted(n)} }"
          + (' (negative control)' if a.negative else ''))
    rc = 0 if (tot == 0) != a.negative else 1
    if not a.no_sub and not a.negative:
        for tool in ('census_place_banks.py', 'census_stale_places.py'):
            r = subprocess.run([sys.executable, os.path.join(REPO, 'tools', tool),
                                '--project', a.project, '--rom', a.rom, '--sym', a.sym],
                               capture_output=True, text=True, cwd=REPO)
            last = [x for x in r.stdout.splitlines() if 'checks' in x]
            print(f"{tool}: rc {r.returncode} — {last[-1] if last else r.stdout[-400:] + r.stderr[-400:]}")
            rc |= r.returncode
    return rc


if __name__ == '__main__':
    sys.exit(main())
