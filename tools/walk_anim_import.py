#!/usr/bin/env python3
"""walk_anim_import.py — Animate → "Import frames from PNG…" in the game (S173 r3).

On a COPY of a project, imports PNG frame strips onto cells with the editor's own code
(editor2/core/anim_import: read_frames → plan → apply — what the Rooms tab runs), builds the
ROM (tools/build_project.py --build), CONTINUEs a real save, warps onto the screen and checks:

  * the palette rows the import planned are in the game's BG palette RAM (own colour 1 kept);
  * the cells show the imported tiles (BG map);
  * every moving 8x8 piece shows ONLY the imported frames, each of them, over 4 loops;
  * a step every `speed` frames (the median gap between changes of a piece);
  * the cells keep their wall / walkable side (bottom-right subtile vs the threshold).
  --negative: the cells are NOT imported (only the plan is made) — the frame checks must FAIL.

    python3 tools/walk_anim_import.py --project DIR --sav FILE --room NAME --screen K
        --put PNG X0 Y0 X1 Y1 [--put …] [--stand X Y] [--speed N] [--keep DIR]
        [--rom-out FILE] [--negative] [--gif FILE]   (the screen, animated, 4 seconds)
"""
import argparse
import os
import shutil
import statistics
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from PIL import Image                                                   # noqa: E402
from tools.pyboy_harness import adv                                     # noqa: E402
from tools.walk_regions import Walk, s_continue                         # noqa: E402
from tools.walk_page2 import _tile16                                    # noqa: E402
from editor2.core.document import Document, val                         # noqa: E402
from editor2.core.render_project import ProjectRenderer                 # noqa: E402
from editor2.core import anim_import as AI                              # noqa: E402
from editor2.core import page2 as P2                                    # noqa: E402


def attr_lid_of(r, room, key, state):
    """The layout item holding this screen's colour grid (as the room canvas finds it)."""
    attr, note = r.attr_grid(room, key, state)
    if attr and note and not note.startswith(('WARNING', 'vanilla', 'no ')):
        cand = note.split(' ')[0]
        if cand in r.layout_by_id and 'attr' in r.layout_by_id[cand]:
            return cand
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--room', required=True)
    ap.add_argument('--screen', type=int, required=True)
    ap.add_argument('--put', nargs=5, action='append', required=True,
                    metavar=('PNG', 'X0', 'Y0', 'X1', 'Y1'))
    ap.add_argument('--stand', type=int, nargs=2, default=(5, 4))
    ap.add_argument('--speed', type=int, default=32)
    ap.add_argument('--keep')
    ap.add_argument('--rom-out')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--gif')
    a = ap.parse_args()
    keep = a.keep or tempfile.mkdtemp(prefix='walk_anim_import_')
    os.makedirs(keep, exist_ok=True)
    proj = os.path.join(keep, 'project')
    shutil.rmtree(proj, ignore_errors=True)
    shutil.copytree(a.project, proj, ignore=shutil.ignore_patterns('build'))
    d = Document(os.path.join(proj, 'project.json'))
    r = ProjectRenderer(REPO, d.project_dir, d.data)
    d.vanilla = r
    room = next(x for x in d.rooms if d.room_name(x) == a.room)
    key = a.screen
    plans = []
    thr0 = val(room['record']['collision_threshold'])
    side0 = {}                                     # the wall / walkable side before the import
    for png, x0, y0, x1, y1 in a.put:
        rect = tuple(int(v) for v in (x0, y0, x1, y1))
        st = r.screen_state(room, key, 0)
        _g, lid = r.layout_grid(st['layout'])
        frames, info = AI.read_frames(Image.open(png), rect[2] - rect[0] + 1, rect[3] - rect[1] + 1)
        pl = AI.plan(d, r, room, key, 0, lid, attr_lid_of(r, room, key, 0), rect, frames)
        T0 = d.layout(lid)['tiles']
        for (rr, c) in pl['pieces']:
            side0[(rr, c)] = P2.is_wall(P2.slot_key(T0[rr][c]), thr0)
        print(f'{os.path.basename(png)} → {rect}: {info["n"]} frames, new rows '
              f'{sorted(pl["new_rows"])}, own colour 1 {"on" if pl["free1"] else "-"}, '
              f'{len(pl["moving"])} moving pieces')
        if not a.negative:
            AI.apply(d, pl, speed=a.speed, name=os.path.basename(png)[:20])
            print('  ' + d.last_import_note)
            r = ProjectRenderer(REPO, d.project_dir, d.data)      # the new rows / tiles
            d.vanilla = r
        plans.append(pl)
    d.touch()
    d.save()
    out = os.path.join(proj, 'build')
    res = subprocess.run([sys.executable, os.path.join(REPO, 'tools/build_project.py'),
                          '--project', proj, '--out', out, '--build'], capture_output=True, text=True)
    if res.returncode:
        print(res.stdout[-3000:], res.stderr[-3000:])
        raise SystemExit('build failed')
    build = os.path.join(out, 'build')
    if a.rom_out:
        shutil.copy(os.path.join(build, 'rom.gbc'), a.rom_out)
    room = d.room(room['id'])
    pid = d.effective_palette(room, key, 0)
    pal = d.palette(pid)
    w = Walk(build, a.sav, keep)
    s_continue(w)
    w.goto(val(room['mapID']), 0, (key % 4) * 10 + a.stand[0], (key // 4) * 8 + a.stand[1])
    m = w.m
    adv(w.p, 90)
    w.check('in the room', w.where()[0] == val(room['mapID']), f'${w.where()[0]:02X}')
    # palette RAM
    want_rows = sorted({rw for pl in plans for rw in pl['new_rows']})
    ok = True
    got_txt = []
    for rw in want_rows:
        got = []
        for c in range(4):
            w.p.memory[0xFF68] = rw * 8 + c * 2
            lo = w.p.memory[0xFF69]
            w.p.memory[0xFF68] = rw * 8 + c * 2 + 1
            got.append(lo | (w.p.memory[0xFF69] << 8))
        want = [int(v, 16) if isinstance(v, str) else int(v) for v in pal['colors_rgb555'][rw]]
        ok &= [g & 0x7FFF for g in got] == [v & 0x7FFF for v in want]
        got_txt.append(f'row {rw} {[hex(g & 0x7FFF) for g in got]}')
    w.check('the palette rows the project holds are in the game\'s palette RAM', ok, '; '.join(got_txt))
    lid = plans[0]['lid']
    T = d.layout(lid)['tiles']
    thr = val(room['record']['collision_threshold'])

    def piece(qx, qy):
        lc, scx, scy = m[0xFF40], m[0xFF43], m[0xFF42]
        bg = 0x9C00 if lc & 0x08 else 0x9800
        ad = bg + ((scy // 8 + qy) % 32) * 32 + ((scx // 8 + qx) % 32)
        t, at = m[0, ad], m[1, ad]
        return t, _tile16(m, (at >> 3) & 1, t), at & 7
    shown = all(piece(c, rr)[0] == T[rr][c] & 0xFF for pl in plans for (rr, c) in pl['pieces'])
    w.check('the cells show the project\'s tiles (the imported ones)', shown)
    rows_ok = all(piece(c, rr)[2] == pl['assign'][(rr, c)] for pl in plans for (rr, c) in pl['pieces'])
    w.check('every piece is drawn with its planned palette row', rows_ok)
    span = a.speed * 2 * 4 + 20
    seen = {}
    last = {}
    gaps = []
    for t in range(span):
        adv(w.p, 1)
        for pl in plans:
            for (rr, c) in pl['moving']:
                g = piece(c, rr)[1]
                seen.setdefault((rr, c), set()).add(g)
                if (rr, c) in last and last[(rr, c)][0] != g:
                    gaps.append(t - last[(rr, c)][1])
                    last[(rr, c)] = (g, t)
                elif (rr, c) not in last:
                    last[(rr, c)] = (g, t)
    only = all(seen[p] <= {gx[p] for gx in pl['gfx']} for pl in plans for p in pl['moving'])
    every = all(seen[p] >= {gx[p] for gx in pl['gfx']} for pl in plans for p in pl['moving'])
    w.check('every moving piece shows only the imported frames', only)
    w.check('… and every one of them', every)
    med = statistics.median(gaps) if gaps else 0
    w.check(f'a step every {a.speed} frames', abs(med - a.speed) <= 1, f'median gap {med}')
    walls = all(P2.is_wall(P2.slot_key(T[rr][c]), thr) == side0[(rr, c)]
                for pl in plans for (rr, c) in pl['pieces'])
    w.check('the cells keep their wall / walkable side', walls)
    w.snap('after')
    if a.gif:
        # every frame recorded; each picture held for its TRUE time (runs of identical frames,
        # 1/59.73 s each, rounded to the GIF's 10 ms) — sampling every few frames and a fixed
        # delay made the swaps look uneven (user S173 r4: "It seems to wiggle slightly faster
        # ever x cycles?" — the game measured: every piece every 32 frames, exactly)
        runs = []
        for _t in range(300):
            adv(w.p, 1)
            im = w.p.screen.image.convert('RGB')
            if runs and runs[-1][0].tobytes() == im.tobytes():
                runs[-1][1] += 1
            else:
                runs.append([im, 1])
        frames_ = [r_[0].resize((480, 432), Image.NEAREST) for r_ in runs]
        durs = [max(20, int(round(n * 1000 / 59.73 / 10.0)) * 10) for _im, n in runs]
        frames_[0].save(a.gif, save_all=True, append_images=frames_[1:], duration=durs, loop=0,
                        optimize=False, disposal=1)
    print(f'{w.checks - w.fails} / {w.checks} checks passed'
          + (' (NEGATIVE: failures expected)' if a.negative else ''))
    w.p.stop(save=False)
    sys.exit(1 if w.fails else 0)


if __name__ == '__main__':
    main()
