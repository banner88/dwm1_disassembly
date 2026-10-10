#!/usr/bin/env python3
"""census_tile_anims.py — S139 (ROADMAP ARC CAP2d): every room's OWN animated tiles,
read back from the built ROM through the engine's own route, == the editor's model.

Since S139 a room's own animations (custom.rooms[].tile_anims) live in bank $6C or
in an ANIMATION BANK $80+ (editor2/core/tileanim.py plan). Bank $6C entry 0
CustomTileAnimate looks the room up in TileAnimDirectory (bank, index) and runs
TileAnimPlay{A} of that bank. Three parts:

  A. ROM tables (no emulator): for every map id of the directory, the (bank, index)
     row leads — through that bank's TileAnimRoomTable{A} — to the group list
     labelled TileAnimRoom_<n> IN THAT BANK (game.sym), and every group record
     equals the model (editor2/core/tileanim.py groups + schedule, built from the
     room's sheet): period = speed, phase, seqlen, nslots, the VRAM slots, and every
     step's frame block (16-aligned, in the same bank) == the model's bytes; a
     room without animations has bank 0. The plan's byte count == the assembled
     bank (labels: main section end + the frame section's extent).
  B. Stub calls (PyBoy, title screen): bank $6C entry 0 for every map id $00-$FE
     with wTileAnimRoom poked to $FF: a hook on every bank's TileAnimPlay{A} sees
     exactly the rooms of that bank with E = their index (and nothing for a room
     without animations, a vanilla id or an id past the directory); after the call
     wTileAnimRoom == the room and each group's timer == its phase (minus the frame
     the call itself ran) — the restart ran in the right bank.
  C. (--play SAV) the game: CONTINUE the save, warp into every animated room, and for
     --frames frames every animated slot of VRAM bank 0 shows one of ITS authored
     frames, no other slot of the sheet changes, and every frame of every group is
     seen at least once in a full loop (the S102 check, now across banks); slots the
     room's vanilla `animation` moves (bank $01) are allowed to change too.

  python3 tools/census_tile_anims.py --project DIR [--rom R --sym S] [--play SAV]
  --negative: one expected frame byte is flipped; the census must fail.
"""
import argparse
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.census_place_banks import Stub, Rom, sym_table     # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--project', required=True)
    ap.add_argument('--rom')
    ap.add_argument('--sym')
    ap.add_argument('--play', metavar='SAV', help='part C on this battery save')
    ap.add_argument('--frames', type=int, default=0,
                    help='part C: frames per room (default: one full loop + 60)')
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args()
    from editor2.core import compiler as C
    from editor2.core import formats as F
    from editor2.core import tileanim as TA
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
    plan = TA.plan(prj)
    bad, n, first = {}, {}, []

    def check(kind, got, want, ctx):
        n[kind] = n.get(kind, 0) + 1
        if got != want:
            bad[kind] = bad.get(kind, 0) + 1
            if len(first) < 12:
                first.append((kind, ctx, got, want))

    # ---- the model ---------------------------------------------------------------
    model = {}
    for r in TA.anim_rooms(prj):
        mid = F.val(r['mapID'])
        items = prj.tile_anims(r)
        sheet = prj.room_sheet(r) or bytes(2048)
        ph = TA.schedule(items)
        gl = []
        for i, it in enumerate(items):
            for part, blocks, seq in TA.groups(it, sheet):
                gl.append({'period': TA._val(it['speed']), 'phase': ph[i], 'slots': part,
                           'blocks': [bytes(b) for b in blocks], 'seq': list(seq)})
        model[mid] = gl
    if a.negative and model:
        g0 = model[min(model)][0]
        b = bytearray(g0['blocks'][-1])
        b[0] ^= 0xFF
        g0['blocks'][-1] = bytes(b)

    # ---- A: the ROM tables -------------------------------------------------------
    db, da = sym['TileAnimDirectory']
    check('dir_bank_6C', db, 0x6C, 'TileAnimDirectory')
    rows = plan['dir_rows']
    for i in range(rows):
        mid = 0x6B + i
        bank, idx = rom.u8(db, da + 2 * i), rom.u8(db, da + 2 * i + 1)
        if mid not in model:
            check('dir_none', (bank, idx), (0, 0), f'${mid:02X}')
            continue
        check('dir_bank_is_anim_bank', bank == 0x6C or bank >= 0x80, True, f'${mid:02X}')
        sfx = '' if bank == 0x6C else f'_A{bank:02X}'
        tb, ta = sym[f'TileAnimRoomTable{sfx}']
        check('table_bank', tb, bank, f'${mid:02X}')
        ptr = rom.u16(bank, ta + 2 * idx)
        lb, la = sym[f'TileAnimRoom_{mid - 0x6B}']
        check('group_list_label', (bank, ptr), (lb, la), f'${mid:02X}')
        p = ptr
        for gi, g in enumerate(model[mid]):
            ctx = f'${mid:02X} group {gi}'
            period, phase, seqlen, ns = (rom.u8(bank, p + k) for k in range(4))
            check('period', period, g['period'], ctx)
            check('phase', phase, g['phase'], ctx)
            check('seqlen', seqlen, len(g['seq']), ctx)
            check('nslots', ns, len(g['slots']), ctx)
            seq_ptr = rom.u16(bank, p + 4)
            dests = [rom.u16(bank, p + 6 + 2 * k) for k in range(ns)]
            check('dest', dests, [0x9000 + 16 * s for s in g['slots']], ctx)
            for st in range(seqlen):
                fp = rom.u16(bank, seq_ptr + 2 * st)
                check('frame_aligned', fp & 15, 0, f'{ctx} step {st}')
                check('frame_in_bank', 0x4000 <= fp <= 0x8000 - 16 * ns, True, f'{ctx} step {st}')
                got = bytes(rom.at(bank, fp, 16 * ns))
                want = g['blocks'][g['seq'][st]] if st < len(g['seq']) else b''
                check('frame_bytes', got, want, f'{ctx} step {st}')
            p += 6 + 2 * ns
        check('list_end', rom.u8(bank, p), 0, f'${mid:02X}')
    # the plan's byte count == the assembled bank (main section + frame section)
    for bank, used in plan['used'].items():
        sfx = '' if bank == 0x6C else f'_A{bank:02X}'
        labs = {k: v for k, v in sym.items() if v[0] == bank}
        rooms_here = [r for r, _l, _f in plan['banks'][bank]]
        if not rooms_here:
            continue
        main_end = sym[f'TileAnimRoomTable{sfx}'][1] + 2 * len(rooms_here)
        f_lo, f_hi = 0x8000, 0x4000
        for r in rooms_here:
            mid = F.val(r['mapID'])
            ri = mid - 0x6B
            main_end = max(main_end, sym[f'TileAnimRoom_{ri}'][1] + 1 + sum(
                6 + 2 * len(g['slots']) for g in model[mid]))
            gi = 0
            for i, it in enumerate(prj.tile_anims(r)):
                for g in range(len(TA.groups(it, prj.room_sheet(r) or bytes(2048)))):
                    tag = f'{ri}_{i}_{g}'
                    s = sym[f'TileAnimSeq_{tag}'][1]
                    main_end = max(main_end, s + 2 * len(model[mid][gi]['seq']))
                    for k in range(len(model[mid][gi]['blocks'])):
                        fa = labs[f'TileAnimFrame_{tag}_{k}'][1]
                        f_lo = min(f_lo, fa)
                        f_hi = max(f_hi, fa + 16 * len(model[mid][gi]['slots']))
                    gi += 1
        assembled = (main_end - 0x4000) + max(0, f_hi - f_lo)
        check('plan_bytes', used - TA.ALIGN_PAD, assembled, f'bank ${bank:02X}')
        check('bank_self_id', rom.u8(bank, 0x4000), bank, f'bank ${bank:02X}')
        if bank != 0x6C:
            check('entry0', rom.u16(bank, 0x4001), sym[f'TileAnimPlay{sfx}'][1],
                  f'bank ${bank:02X}')

    # ---- B: stub calls through the forwarder --------------------------------------
    S = Stub(a.rom)
    m = S.m
    wroom, wstate = sym['wTileAnimRoom'][1], sym['wTileAnimState'][1]
    wmap = sym['wMapID'][1]
    hits = []
    play = {}
    for bank in plan['used']:
        sfx = '' if bank == 0x6C else f'_A{bank:02X}'
        play[bank] = sym[f'TileAnimPlay{sfx}'][1]

    def on_play(bank):
        hits.append((bank, S.p.register_file.E))

    for bank, addr in play.items():
        S.p.hook_register(bank, addr, on_play, bank)
    S.p.save_state(S.st)                    # hooks are not part of the state
    for mid in range(0x00, 0xFF):
        S.reload()
        hits.clear()
        m[wroom] = 0xFF
        for k in range(64):
            m[wstate + k] = 0xEE
        S.call(0x00, [(wmap, mid)], bank=0x6C)
        want = [plan['home'][mid]] if mid in model else []
        check('forward', hits, want, f'${mid:02X}')
        if mid in model:
            check('restart_room', m[wroom], mid, f'${mid:02X}')
            for gi, g in enumerate(model[mid]):
                t = m[wstate + 2 * gi]
                # the restart wrote phase; the same call then counted one frame
                # (due at 1 -> copied -> timer := period)
                want_t = g['phase'] - 1 if g['phase'] > 1 else (g['period'], 0)
                if isinstance(want_t, tuple):
                    check('timer', t in want_t, True, f'${mid:02X} group {gi}')
                else:
                    check('timer', t, want_t, f'${mid:02X} group {gi}')
        else:
            check('untouched', m[wroom], 0xFF, f'${mid:02X}')
    S.p.stop(save=False)

    # ---- C: the game -------------------------------------------------------------
    played = []
    if a.play:
        from tools.pyboy_harness import boot_with_sav, warp, MAP_ID
        from editor2.core import animation as A
        rooms = {F.val(r['mapID']): r for r in prj.rooms}
        p = boot_with_sav(a.rom, a.play)
        _continue(p)
        for mid in sorted(model):
            gl = model[mid]
            want = {}
            for g in gl:
                for k, sl in enumerate(g['slots']):
                    want[sl] = [b[16 * k:16 * k + 16] for b in g['blocks']]
            loop = max(g['period'] * len(g['seq']) for g in gl)
            nfr = a.frames or loop + 60
            for _ in range(4):
                warp(p, mid, 5, 3, settle=200)
                if p.memory[MAP_ID] == mid:
                    break
            check('play_warp', p.memory[MAP_ID], mid, f'${mid:02X}')
            prev = bytes(p.memory[0, 0x9000:0x9800])
            seen = {sl: set() for sl in want}
            moved = set()
            for _ in range(nfr):
                p.tick()
                cur = bytes(p.memory[0, 0x9000:0x9800])
                moved |= {i // 16 for i in range(0x800) if cur[i] != prev[i]}
                for sl, frs in want.items():
                    t = cur[sl * 16:sl * 16 + 16]
                    if t in frs:
                        seen[sl].add(frs.index(t))
                    else:
                        check('play_frame', 'not authored', 'authored', f'${mid:02X} slot {sl}')
                prev = cur
            # the room's VANILLA animation (`animation`, bank $01) moves its own slots
            van = set(A.room_slots(rooms[mid]))
            check('play_only_own_slots', sorted(moved - set(want) - van), [], f'${mid:02X}')
            for g in gl:
                for sl in g['slots']:
                    check('play_all_frames', len(seen[sl]),
                          len({b[16 * g['slots'].index(sl):16 * g['slots'].index(sl) + 16]
                               for b in g['blocks']}), f'${mid:02X} slot {sl}')
            played.append(f'${mid:02X}:{nfr}f')
        p.stop(save=False)

    total = sum(n.values())
    print(f"census_tile_anims: {len(model)} animated rooms over banks "
          + ', '.join(f'${b:02X}' for b in plan['used'])
          + f"; {total} checks, {sum(bad.values())} mismatched")
    for k in sorted(n):
        print(f"  {k:24s} {n[k]:6d}" + (f"   BAD {bad[k]}" if k in bad else ''))
    if played:
        print("  played:", ' '.join(played))
    for f in first:
        print("  FIRST:", f)
    sys.exit(1 if bad else 0)


def _continue(p):
    """CONTINUE a real save (PYBOY_DEBUGGING S100 / S133)."""
    from tools.pyboy_harness import adv, tap, GAME_MODE
    adv(p, 400)
    tap(p, 'start'); adv(p, 120)
    tap(p, 'a'); adv(p, 120)
    tap(p, 'a'); adv(p, 200)
    tap(p, 'a')
    for _ in range(60):
        adv(p, 20)
        if p.memory[GAME_MODE] == 1 and p.memory[0xC8EB] == 0:
            break
        tap(p, 'a')
    for _ in range(6):
        tap(p, 'b'); adv(p, 20)


if __name__ == '__main__':
    main()
