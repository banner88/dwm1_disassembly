#!/usr/bin/env python3
"""walk_still.py — the Still tool in the game (S173, EDITOR_DESIGN §5.1 "As built S173").

The Rooms tab's Still tool (editor2/core/animate.py `cell_frames` + `make_still_tile`)
makes a NEW metatile from one chosen frame of a moving cell; the claim is that it never
moves in the game while the tile it was taken from keeps moving. This tool measures that:

  1. copies the project, makes the still tile from frame N of the moving cell (the same
     code the editor runs), paints it on a second cell of the same screen, saves;
  2. builds the ROM (tools/build_project.py --build, the editor's own build);
  3. boots the build on a real save (CONTINUE), warps into the room / screen;
  4. checks, sampling VRAM every 4 frames for 1,200 frames:
     * the BG map shows the painted cell's 4 tiles and the moving cell's 4 tiles;
     * the painted cell's 4 graphics NEVER change and equal the chosen frame;
     * the moving cell's graphics DO change (the room's animation runs);
     * every picture the moving cell showed is one of the frames the editor offered, and
       the chosen frame is among them (the editor's frames are the game's).
  --negative: the ORIGINAL (moving) metatile is painted instead — the "never changes"
  check MUST fail.

    python3 tools/walk_still.py --project <dir> --sav <.sav> --room <name> --screen K
        --cell X Y --put X Y [--frame N] [--stand X Y] [--keep DIR] [--negative]
        [--rom-out FILE]          (a copy of the built ROM, e.g. a test ROM)
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv                                    # noqa: E402
from tools.walk_regions import Walk, s_continue                        # noqa: E402
from tools.walk_page2 import _tile16                                   # noqa: E402
from editor2.core import animate as AN                                 # noqa: E402
from editor2.core.document import Document, val                     # noqa: E402
from editor2.core.render_project import ProjectRenderer                # noqa: E402


def cell_mt(grid, attr, cx, cy):
    r, c = cy * 2, cx * 2
    t = [grid[r][c], grid[r][c + 1], grid[r + 1][c], grid[r + 1][c + 1]]
    p = [attr[r][c] & 7, attr[r][c + 1] & 7, attr[r + 1][c] & 7, attr[r + 1][c + 1] & 7] \
        if attr else [0] * 4
    return {'tiles': t, 'pal': p[0] if len(set(p)) == 1 else p}


def prepare(a, proj):
    """The editor's own steps on the copy: the frames, the still tile, the paint."""
    d = Document(os.path.join(proj, 'project.json'))
    r = ProjectRenderer(REPO, d.project_dir, d.data)
    d.vanilla = r
    room = next(x for x in d.rooms if d.room_name(x) == a.room)
    key = int(a.screen)
    st = r.screen_state(room, key, 0)
    grid, lid = r.layout_grid(st['layout'])
    attr, _n = r.attr_grid(room, key, 0)
    gfx = r.room_gfx(room)
    mt = cell_mt(grid, attr, *a.cell)
    anim = d.room_animation(room)['map']
    frames = AN.cell_frames(anim, d.tile_anims(room), gfx.sheet, mt['tiles'])
    print(f'{a.room} screen {key} cell {tuple(a.cell)}: tiles {mt["tiles"]}, '
          f'{len(frames)} frames offered')
    k = min(a.frame, len(frames) - 1)
    new = d.make_still_tile(room['id'], mt, list(frames[k]), own_sheet=bytes(gfx.sheet[:2048]),
                            frame=k)
    print('  ' + d.last_import_note)
    paint = mt if a.negative else new
    T = d.layout(lid)['tiles']
    cx, cy = a.put
    T[cy * 2][cx * 2], T[cy * 2][cx * 2 + 1], T[cy * 2 + 1][cx * 2], T[cy * 2 + 1][cx * 2 + 1] = \
        [int(t) for t in paint['tiles']]
    L = d.layout(lid)
    if L.get('attr') is not None and attr:
        pals = paint['pal'] if isinstance(paint['pal'], list) else [paint['pal']] * 4
        A_ = L['attr']
        A_[cy * 2][cx * 2], A_[cy * 2][cx * 2 + 1], A_[cy * 2 + 1][cx * 2], \
            A_[cy * 2 + 1][cx * 2 + 1] = [int(p) & 7 for p in pals]
    d.touch()
    d.save()
    return {'mid': val(room['mapID']), 'key': key, 'moving': mt, 'painted': paint,
            'frames': frames, 'k': k}


def cell_now(m, cx, cy):
    """(tile, VRAM bank) + graphic of the cell's 4 subtiles as the LCD draws it now."""
    lc, scx, scy = m[0xFF40], m[0xFF43], m[0xFF42]
    bg = 0x9C00 if lc & 0x08 else 0x9800
    out = []
    for dy in (0, 1):
        for dx in (0, 1):
            a = bg + ((scy // 8 + cy * 2 + dy) % 32) * 32 + ((scx // 8 + cx * 2 + dx) % 32)
            t, at = m[0, a], m[1, a]
            b = (at >> 3) & 1
            out.append(((t, b), _tile16(m, b, t)))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--room', required=True)
    ap.add_argument('--screen', type=int, required=True)
    ap.add_argument('--cell', type=int, nargs=2, required=True)
    ap.add_argument('--put', type=int, nargs=2, required=True)
    ap.add_argument('--stand', type=int, nargs=2, default=None)
    ap.add_argument('--frame', type=int, default=3)
    ap.add_argument('--keep')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--rom-out')
    a = ap.parse_args()
    keep = a.keep or tempfile.mkdtemp(prefix='walk_still_')
    os.makedirs(keep, exist_ok=True)
    proj = os.path.join(keep, 'project')
    shutil.rmtree(proj, ignore_errors=True)
    shutil.copytree(a.project, proj, ignore=shutil.ignore_patterns('build'))
    if a.negative:
        print('NEGATIVE CONTROL: the moving tile painted instead of the still one — '
              '"never changes" must FAIL')
    info = prepare(a, proj)
    out = os.path.join(proj, 'build')
    r = subprocess.run([sys.executable, os.path.join(REPO, 'tools/build_project.py'),
                        '--project', proj, '--out', out, '--build'],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout[-3000:], r.stderr[-3000:])
        raise SystemExit('build failed')
    build = os.path.join(out, 'build')
    if a.rom_out:
        shutil.copy(os.path.join(build, 'rom.gbc'), a.rom_out)
    w = Walk(build, a.sav, keep)
    s_continue(w)
    col, row = info['key'] % 4, info['key'] // 4
    sx, sy = a.stand or (a.put[0], min(7, a.put[1] + 2))
    w.goto(info['mid'], 0, col * 10 + sx, row * 8 + sy)
    m = w.m
    adv(w.p, 120)
    w.check('in the room', w.where()[0] == info['mid'], f'at ${w.where()[0]:02X}')
    w.snap('arrival')
    pt = [(int(t) & 0xFF, (int(t) >> 8) & 1) for t in info['painted']['tiles']]
    mv = [(int(t) & 0xFF, (int(t) >> 8) & 1) for t in info['moving']['tiles']]
    w.check('the painted cell shows its 4 tiles', [x[0] for x in cell_now(m, *a.put)] == pt,
            f"{[x[0] for x in cell_now(m, *a.put)]} vs {pt}")
    w.check('the moving cell shows its 4 tiles', [x[0] for x in cell_now(m, *a.cell)] == mv,
            f"{[x[0] for x in cell_now(m, *a.cell)]} vs {mv}")
    seen_put, seen_mov = set(), set()
    for _ in range(300):
        adv(w.p, 4)
        seen_put.add(tuple(g for _t, g in cell_now(m, *a.put)))
        seen_mov.add(tuple(g for _t, g in cell_now(m, *a.cell)))
    fr = info['frames']
    w.check('the painted cell NEVER changes (1,200 frames)', len(seen_put) == 1,
            f'{len(seen_put)} pictures')
    want = fr[info['k']]
    got = next(iter(seen_put))
    w.check(f"… and it shows frame {info['k'] + 1} of the moving cell", got == tuple(want))
    w.check('the moving cell DOES change (the room animates)', len(seen_mov) > 1,
            f'{len(seen_mov)} pictures')
    w.check("every picture of the moving cell is one the editor offered",
            seen_mov <= set(fr), f'{len(seen_mov - set(fr))} unknown')
    w.check('the chosen frame is shown by the moving cell in the game', tuple(want) in seen_mov)
    w.snap('after')
    print(f'{w.checks - w.fails} / {w.checks} checks passed'
          + (' (NEGATIVE: failures expected)' if a.negative else ''))
    w.p.stop(save=False)
    sys.exit(1 if w.fails else 0)


if __name__ == '__main__':
    main()
