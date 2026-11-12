#!/usr/bin/env python3
"""walk_screen_palette.py — a screen's OWN colours in the game (S176).

On a COPY of a project: one screen of a multi-screen room gets its own palette with the
editor's own code (editor2/core/screen_palettes.give), some of its rows are changed, some of
its cells are put on a changed row; the ROM is built, a real save CONTINUEd, and the player
walks from a neighbour screen onto it and back while the REAL BG palette RAM (BCPS / BCPD) is
read every frame:

  * the model: which rows differ, which each screen draws with, the game's rule
    (screen_palettes.scroll_rule): rows switched when the scroll STARTS / when it ENDS;
  * arriving: at the first frame the view moves the "now" rows are the screen's own; the
    "late" rows keep the neighbour's colours on every frame the view moves; when the scroll is
    over the hardware == the palette buffer == the screen's palette;
  * leaving: the same, the other way;
  * the field menu opened and closed changes no colour (the buffer was already shown);
  * warping straight onto the screen shows its colours;
  * a scroll between two screens with the SAME colours pushes nothing (hook on bank $73
    ScreenPalPushRows: 0 runs) and starts moving after as many frames as on the original
    scroll code;
  --negative: the five bank $06 call sites put back to the original's (`$0b03` / `$010a`) in a
    ROM copy — the arriving / leaving checks must FAIL (the colours of the screen left stay).

    python3 tools/walk_screen_palette.py --project DIR --sav FILE --room NAME --screen K
        --from N --stand X Y --row R C0 C1 C2 [--row …] [--paint R X Y [--paint …]]
        [--same A B X Y] [--keep DIR] [--rom-out FILE] [--negative]
    (--stand: the cell of screen N to start from, one step short of the edge towards K;
     colours as RGB555 words; --paint: a cell of screen K put on row R;
     --same: two side-by-side screens with the same colours and a cell of A next to B)
"""
import argparse
import os
import shutil
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, SCREEN_IDX, PLAYER_TX, PLAYER_TY          # noqa: E402
from tools.walk_regions import Walk, s_continue                                     # noqa: E402
from tools.walk_stamps import build                                                 # noqa: E402
from editor2.core.document import Document, val                                     # noqa: E402
from editor2.core.render_project import ProjectRenderer                             # noqa: E402
from editor2.core import screen_palettes as SP                                      # noqa: E402

DIRS = {1: 'right', -1: 'left', 4: 'down', -4: 'up'}


def hw_rows(p):
    """The real BG palette RAM, rows 0-3 (4 x 4 RGB555 words)."""
    m = p.memory
    out = []
    for rw in range(4):
        row = []
        for c in range(4):
            m[0xFF68] = rw * 8 + c * 2
            lo = m[0xFF69]
            m[0xFF68] = rw * 8 + c * 2 + 1
            row.append((lo | (m[0xFF69] << 8)) & 0x7FFF)
        out.append(tuple(row))
    return out


def buf_rows(m):
    return [tuple((m[0xC797 + r * 8 + c * 2] | (m[0xC798 + r * 8 + c * 2] << 8)) & 0x7FFF
                  for c in range(4)) for r in range(4)]


def want_rows(doc, room, key):
    pal = doc.palette(doc.effective_palette(room, key, 0))
    rows = []
    for r in range(4):
        w = [val(c) & 0x7FFF for c in pal['colors_rgb555'][r]]
        if not pal.get('free_color1'):
            w[1] = 0x6BFF
        w[3] = 0
        rows.append(tuple(w))
    return rows


def scroll(w, key_dir, pushes):
    """Hold a direction through one scroll: [(frame, screen, moving?, hardware rows)],
    the frames from the screen index changing to the first movement."""
    m = w.m
    pushes.clear()
    log = []
    s0, sc0 = m[SCREEN_IDX], (m[0xFF43], m[0xFF42])
    w.p.button_press(key_dir)
    t_idx = t_move = t_stop = None
    last = sc0
    for f in range(400):
        w.p.tick(1, True)
        sc = (m[0xFF43], m[0xFF42])
        moving = sc != last
        last = sc
        if t_idx is None and m[SCREEN_IDX] != s0:
            t_idx = f
        if moving and t_move is None:
            t_move = f
        if moving:
            t_stop = f
        log.append((f, m[SCREEN_IDX], moving, hw_rows(w.p)))
        if t_stop is not None and f - t_stop > 40:
            break
    w.p.button_release(key_dir)
    adv(w.p, 30)
    return log, t_idx, t_move, t_stop


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--room', required=True)
    ap.add_argument('--screen', type=int, required=True)
    ap.add_argument('--from', dest='frm', type=int, required=True)
    ap.add_argument('--stand', type=int, nargs=2, required=True)
    ap.add_argument('--row', nargs=4, action='append', default=[])
    ap.add_argument('--paint', type=int, nargs=3, action='append', default=[])
    ap.add_argument('--same', type=int, nargs=4)
    ap.add_argument('--keep')
    ap.add_argument('--rom-out')
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args()
    keep = a.keep or tempfile.mkdtemp(prefix='walk_spal_')
    os.makedirs(keep, exist_ok=True)
    proj = os.path.join(keep, 'project')
    shutil.rmtree(proj, ignore_errors=True)
    shutil.copytree(a.project, proj, ignore=shutil.ignore_patterns('build'))
    d = Document(os.path.join(proj, 'project.json'))
    room = next(r for r in d.rooms if isinstance(r, dict) and d.room_name(r) == a.room)
    K, N = a.screen, a.frm
    step = K - N
    assert step in DIRS, 'the two screens must be side by side'
    rr = ProjectRenderer(REPO, proj, d.data)
    d.vanilla = rr
    before = want_rows(d, room, N)
    pid = SP.give(d, room, K, rr.room_palettes(room, K, 0))
    pal = d.palette(pid)
    for r, c0, c1, c2 in a.row:
        pal['colors_rgb555'][int(r)] = [f'0x{int(c0, 0):04X}', f'0x{int(c1, 0):04X}',
                                        f'0x{int(c2, 0):04X}', '0x0000']
        pal['free_color1'] = True
    for r, x, y in a.paint:
        alid = d.writable_attr_id(room, K, 0)
        d.set_cells(alid, 'attr', [(y * 2 + j, x * 2 + i, r) for j in range(2) for i in range(2)])
    d.save()
    d = Document(os.path.join(proj, 'project.json'))
    room = next(r for r in d.rooms if isinstance(r, dict) and d.room_name(r) == a.room)
    rr = ProjectRenderer(REPO, proj, d.data)
    d.vanilla = rr
    own, base = want_rows(d, room, K), want_rows(d, room, N)
    print(f'screen {K} of {a.room}: its own palette {pid}; screen {N}: '
          f'{d.effective_palette(room, N, 0)}')
    changed = [r for r in range(4) if own[r] != base[r]]
    dk, dn = SP.rows_drawn(d, rr, room, K), SP.rows_drawn(d, rr, room, N)
    arr = SP.scroll_rule(changed, set(dn), set(dk))            # N -> K
    lea = SP.scroll_rule(changed, set(dk), set(dn))            # K -> N
    print(f'  rows that differ {changed}; screen {N} draws with {sorted(dn)}, screen {K} with '
          f'{sorted(dk)}')
    print(f'  the rule: arriving now {arr[0]} late {arr[1]} (both draw {arr[2]}); leaving now '
          f'{lea[0]} late {lea[1]} (both draw {lea[2]})')
    rep = SP.scroll_report(d, rr, room)
    for line in SP.report_text(d, room, rep):
        print('  editor warning: ' + line)
    bdir, md5 = build(proj)
    print(f'built {md5}')
    if a.negative:                       # the original's five call words back in a ROM copy
        rom = os.path.join(bdir, 'rom.gbc')
        data = bytearray(open(rom, 'rb').read())
        b6 = 0x06 * 0x4000
        n = 0
        for i in range(b6, b6 + 0x4000 - 3):
            if data[i] == 0x21 and data[i + 3] == 0xD7 and data[i + 2] == 0x73:
                if data[i + 1] == 0x17:
                    data[i + 1], data[i + 2] = 0x03, 0x0B
                    n += 1
                elif data[i + 1] == 0x18:
                    data[i + 1], data[i + 2] = 0x0A, 0x01
                    n += 1
        assert n == 5, n
        open(rom, 'wb').write(data)
        print('NEGATIVE: the five bank $06 call sites call the original\'s entries again')
    if a.rom_out:
        shutil.copy(os.path.join(bdir, 'rom.gbc'), a.rom_out)
    w = Walk(bdir, a.sav, keep)
    w.check('the model: some row differs between the two screens', bool(changed), str(changed))
    s_continue(w)
    mid = val(room['mapID']) & 0xFF
    pushes = []
    b, addr = w.sym['ScreenPalPushRows']

    def hook(_ctx):
        pushes.append(1)

    def start():
        w.start('continue')
        w.p.hook_register(b, addr, hook, None)

    sx, sy = (N % 4) * 10 + a.stand[0], (N // 4) * 8 + a.stand[1]
    start()
    w.goto(mid, 0, sx, sy)
    adv(w.p, 60)
    w.keep_enc()
    m = w.m
    w.check(f'on screen {N}, its colours shown', m[SCREEN_IDX] == N and hw_rows(w.p) == base,
            f'screen {m[SCREEN_IDX]}')

    def judge(what, log, t_move, t_stop, old, new, rule, want_screen):
        now, late, _clash = rule
        ok_idx = log[-1][1] == want_screen
        w.check(f'{what}: the view scrolled onto screen {want_screen}', ok_idx and t_move is not None)
        if not ok_idx or t_move is None:
            return
        first = next(h for f, _s, mv, h in log if f == t_move)
        w.check(f'{what}: when the view starts to move, rows {now} are the new screen\'s',
                all(first[r] == new[r] for r in now),
                ' '.join(f'row {r} {"%04X %04X %04X" % first[r][:3]}' for r in now))
        held = [h for f, _s, _mv, h in log if t_move <= f <= t_stop]
        w.check(f'{what}: rows {late} keep the colours of the screen leaving on every one of '
                f'the {len(held)} frames the view moves',
                all(h[r] == old[r] for h in held for r in late))
        end = hw_rows(w.p)
        w.check(f'{what}: after the scroll the hardware == the buffer == screen '
                f'{want_screen}\'s palette', end == new and buf_rows(w.m) == new,
                ' '.join('%04X' % c for r in range(4) for c in end[r][:3]))

    log, t_idx, t_move, t_stop = scroll(w, DIRS[step], pushes)
    judge(f'{N} -> {K}', log, t_move, t_stop, base, own, arr, K)
    print(f'    (screen index at frame {t_idx}, the view moves frames {t_move}-{t_stop}; '
          f'{len(pushes)} push call(s))')
    h0 = hw_rows(w.p)
    tap(w.p, 'a', hold=4, wait=60)
    opened = bool(m[0xC8EB] & 2)
    for _ in range(6):
        tap(w.p, 'b', wait=30)
    adv(w.p, 60)
    w.check('the field menu opened and closed changes no colour', opened and hw_rows(w.p) == h0)
    log, t_idx, t_move, t_stop = scroll(w, DIRS[-step], pushes)
    judge(f'{K} -> {N}', log, t_move, t_stop, own, base, lea, N)
    print(f'    (screen index at frame {t_idx}, the view moves frames {t_move}-{t_stop}; '
          f'{len(pushes)} push call(s))')
    start()
    kx, ky = (K % 4) * 10 + (a.paint[0][1] if a.paint else 5), (K // 4) * 8 + 6
    w.goto(mid, 0, kx, ky)
    adv(w.p, 60)
    w.check(f'warped straight onto screen {K}: its colours', w.m[SCREEN_IDX] == K
            and hw_rows(w.p) == own, f'screen {w.m[SCREEN_IDX]}')
    if a.same:
        A, B, x, y = a.same
        start()
        w.goto(mid, 0, (A % 4) * 10 + x, (A // 4) * 8 + y)
        adv(w.p, 60)
        w.keep_enc()
        h0 = hw_rows(w.p)
        log, t_idx, t_move, t_stop = scroll(w, DIRS[B - A], pushes)
        ok = w.m[SCREEN_IDX] == B and t_move is not None
        w.check(f'{A} -> {B} (the same colours): scrolled, nothing pushed, no colour changed',
                ok and not pushes and all(h == h0 for _f, _s, _mv, h in log),
                f'{len(pushes)} push call(s)')
        gap = (t_move - t_idx) if ok and t_idx is not None else None
        w.check(f'{A} -> {B}: the view starts to move 6 frames after the screen index changes '
                '(the original scroll code: 6)', gap == 6, f'{gap}')
    print(f'{w.checks - w.fails} / {w.checks}' + (f' — {w.fails} FAIL' if w.fails else ''))
    w.p.stop(save=False)
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
