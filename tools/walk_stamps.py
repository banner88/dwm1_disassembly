#!/usr/bin/env python3
"""walk_stamps.py — Rooms → Stamps in the game (S174, ROADMAP P3.3m).

On a COPY of a project: adds stamp PNGs to the library and places them on one screen with the
editor's own code (editor2/core/stamps — the same data the Rooms tab writes), builds the ROM
(tools/build_project.py --build: the compiler bakes the stamps into a copy), CONTINUEs a real
save, warps onto the screen and checks:

  * placing stamps changed none of the project's tiles / layouts / colour grids / animations /
    tileset files (a stamp is not paint) — only the palette: the rows the stamps own (S174 r2:
    written there when placed, recorded on the placement), on rows no tile drew;
  * the editor's picture of every stamp (stamps.simulate) == the baked screen, every frame;
  * the palette rows the bake planned are in the game's BG palette RAM;
  * the cells show the baked tiles, each piece on its baked palette row;
  * every moving piece shows only the baked frames, each of them, over 4 loops; a step every
    `speed` frames;
  * every cell keeps its wall / walkable side;
  * REMOVED again, the project is what it was but for those palette rows (kept for tiles) —
    nothing else left behind.
  --negative: nothing placed (only planned) — the tile / frame checks must FAIL.

    python3 tools/walk_stamps.py --project DIR --sav FILE --room NAME --screen K
        --stamp PNG W H [--stamp …] --put N X Y [--light #rrggbb] [--unlit] [--put …]
        [--stand X Y] [--keep DIR] [--rom-out FILE] [--gif FILE] [--negative] [--no-remove]
"""
import argparse
import copy
import hashlib
import json
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
from editor2.core import stamps as ST                                   # noqa: E402
from editor2.core import tileanim as TA                                 # noqa: E402
from editor2.core import page2 as P2                                    # noqa: E402


def parse_puts(argv):
    """--put N X Y [--light C] [--unlit] — the options belong to the --put before them."""
    puts = []
    i = 0
    rest = []
    while i < len(argv):
        a = argv[i]
        if a == '--put':
            puts.append({'n': int(argv[i + 1]), 'x': int(argv[i + 2]), 'y': int(argv[i + 3])})
            i += 4
        elif a == '--light' and puts:
            puts[-1]['light'] = argv[i + 1]
            i += 2
        elif a == '--unlit' and puts:
            puts[-1]['lit'] = False
            i += 1
        else:
            rest.append(a)
            i += 1
    return puts, rest


def build(proj):
    out = os.path.join(proj, 'build')
    res = subprocess.run([sys.executable, os.path.join(REPO, 'tools/build_project.py'),
                          '--project', proj, '--out', out, '--build'], capture_output=True, text=True)
    if res.returncode:
        print(res.stdout[-3000:], res.stderr[-3000:])
        raise SystemExit('build failed')
    for line in res.stdout.splitlines():
        if 'WARN' in line and 'stamp' in line:
            print('  ' + line.strip())
    rom = os.path.join(out, 'build', 'rom.gbc')
    return os.path.join(out, 'build'), hashlib.md5(open(rom, 'rb').read()).hexdigest()


def snapshot(proj):
    """Everything a stamp must never change: project.json minus the stamps and the palettes
    (+ which palette a room / screen / state uses — a stamp on a borrowed palette makes it the
    room's own, S174 r2), every asset."""
    d = json.load(open(os.path.join(proj, 'project.json')))
    d.get('custom', {}).pop('stamps', None)
    d.get('custom', {}).pop('palettes', None)
    for r in d.get('custom', {}).get('rooms') or []:
        r.pop('stamps', None)
        (r.get('render') or {}).pop('palette', None)
        for sc in (r.get('screens') or {}).values():
            for st_ in sc.get('states') or []:
                st_.pop('palette', None)
    files = {}
    for root, _ds, fs in os.walk(os.path.join(proj, 'assets')):
        for f in fs:
            p = os.path.join(root, f)
            if os.sep + 'stamps' + os.sep in p:
                continue
            files[os.path.relpath(p, proj)] = hashlib.md5(open(p, 'rb').read()).hexdigest()
    return json.dumps(d, sort_keys=True), files


def main():
    puts, rest = parse_puts(sys.argv[1:])
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--room', required=True)
    ap.add_argument('--screen', type=int, required=True)
    ap.add_argument('--stamp', nargs=3, action='append', required=True, metavar=('PNG', 'W', 'H'))
    ap.add_argument('--stand', type=int, nargs=2, default=(5, 4))
    ap.add_argument('--keep')
    ap.add_argument('--rom-out')
    ap.add_argument('--gif')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--no-remove', action='store_true')
    a = ap.parse_args(rest)
    keep = a.keep or tempfile.mkdtemp(prefix='walk_stamps_')
    os.makedirs(keep, exist_ok=True)
    proj = os.path.join(keep, 'project')
    shutil.rmtree(proj, ignore_errors=True)
    shutil.copytree(a.project, proj, ignore=shutil.ignore_patterns('build'))
    before = snapshot(proj)
    pal_before = json.load(open(os.path.join(proj, 'project.json')))['custom'].get('palettes')
    d = Document(os.path.join(proj, 'project.json'))
    room = next(x for x in d.rooms if d.room_name(x) == a.room)
    os.makedirs(os.path.join(proj, 'assets', 'stamps'), exist_ok=True)
    lib = []
    for i, (png, w, h) in enumerate(a.stamp):
        rel = os.path.join('assets', 'stamps', f'stamp{i}.png')
        shutil.copy(png, os.path.join(proj, rel))
        fr, _info = ST.read_png(os.path.join(proj, rel), int(w), int(h))
        lib.append({'id': f'stamp{i}', 'name': os.path.splitext(os.path.basename(png))[0][:24],
                    'png': rel, 'w': int(w), 'h': int(h), 'frames': len(fr), 'speed': 32})
    d.custom['stamps'] = lib
    pls = []
    for p in puts:
        pl = {'stamp': f"stamp{p['n']}", 'screen': a.screen, 'x': p['x'], 'y': p['y']}
        if 'light' in p:
            pl['light'] = p['light']
        if p.get('lit') is False:
            pl['lit'] = False
        pls.append(pl)
    room['stamps'] = [] if a.negative else pls
    claim_warn = []
    for i in range(len(room['stamps'])):            # S174 r2: as the editor does when placing
        wt = ST.claim(d, REPO, room['id'], i)
        if wt:
            claim_warn.append(wt)
    d.touch()
    d.save()
    after = snapshot(proj)
    # the bake (what the compiler does) — for the expected tiles / frames
    data = json.load(open(os.path.join(proj, 'project.json')))
    if a.negative:                                  # plan them anyway: what WOULD be there
        data['custom']['rooms'][d.room_index(room['id'])]['stamps'] = pls
    bdir, bwarn = ST.baked_dir(data, proj, REPO)
    bd = Document(os.path.join(bdir, 'project.json'))
    br = ProjectRenderer(REPO, bd.project_dir, bd.data)
    broom = bd.room(room['id'])
    key = a.screen
    # the editor's picture of the stamps (simulate on the UNBAKED document)
    r0 = ProjectRenderer(REPO, d.project_dir, d.data)
    d.vanilla = r0
    sim_doc = d
    if a.negative:
        sim_doc = Document(os.path.join(proj, 'project.json'))
        sim_doc.room(room['id'])['stamps'] = copy.deepcopy(pls)
        sim_doc.vanilla = r0 = ProjectRenderer(REPO, sim_doc.project_dir, sim_doc.data)
    sim = ST.simulate(sim_doc, r0)
    ok_sim = True
    items = bd.tile_anims(broom)
    sheet0 = bytes(P2.pad_sheet(bd.read_sheet(broom['record']['tileset'])))
    nmax = max([1] + [len(it.get('frames') or []) + 1 for it in items])
    for f in range(nmax):
        sh = bytearray(sheet0)
        for it in items:
            if it.get('motion') != 'flip' or not it.get('frames'):
                continue
            fr = it['frames'][(f - 1) % len(it['frames'])] if f % (len(it['frames']) + 1) else None
            if fr is None:
                continue
            for s_, hx in zip(TA.slots_of(it), fr):
                sh[s_ * 16:s_ * 16 + 16] = bytes.fromhex(hx)
        st = br.screen_state(broom, key, 0)
        grid, _l = br.layout_grid(st['layout'])
        at, _n = br.attr_grid(broom, key, 0)
        img = br.compose(bytes(sh), grid, at, br.room_palettes(broom, key, 0))
        for i, pl in enumerate(pls):
            info = sim.get((room['id'], i, 0))
            if not info or not info['frames']:
                ok_sim = False
                continue
            c0, rr0, c1, rr1 = info['rect']
            want = info['frames'][f % len(info['frames'])]
            got = img.crop((c0 * 16, rr0 * 16, (c1 + 1) * 16, (rr1 + 1) * 16))
            ok_sim &= got.tobytes() == want.tobytes()
    # build + the game
    build_dir, md5_stamped = build(proj)
    print(f'with the stamps: {md5_stamped}' + (f'; {len(bwarn)} warning(s)' if bwarn else ''))
    for wtxt in bwarn:
        print('  ! ' + wtxt)
    for wtxt in claim_warn:
        print('  placing: ' + wtxt)
    if a.rom_out:
        shutil.copy(os.path.join(build_dir, 'rom.gbc'), a.rom_out)
    w = Walk(build_dir, a.sav, keep)
    w.check('placing the stamps changed none of the project\'s tiles, layouts, colour grids, '
            'animations or tileset files', before == after)
    pid0 = d.effective_palette(d.room(room['id']), a.screen, 0)
    own = sorted({x for pl in (d.room(room['id']).get('stamps') or [])
                  for x in (pl.get('rows') or {}).get(pid0, [])})
    shown_rows = d.palette(pid0)['colors_rgb555'] if pid0 else []
    w.check('the rows the stamps own are written in the project\'s palette (Palettes page)',
            a.negative or (bool(own) and pid0 is not None), f'{pid0} rows {own}: '
            + '; '.join(f'{x} {shown_rows[x]}' for x in own))
    w.check('the editor\'s picture of every stamp == the baked screen, every frame', ok_sim)
    s_continue(w)
    w.goto(val(room['mapID']), 0, (key % 4) * 10 + a.stand[0], (key // 4) * 8 + a.stand[1])
    m = w.m
    adv(w.p, 90)
    w.check('in the room', w.where()[0] == val(room['mapID']), f'${w.where()[0]:02X}')
    pid = bd.effective_palette(broom, key, 0)
    pal = bd.palette(pid)
    ok = True
    got_txt = []
    for rw in range(4):
        got = []
        for c in range(4):
            w.p.memory[0xFF68] = rw * 8 + c * 2
            lo = w.p.memory[0xFF69]
            w.p.memory[0xFF68] = rw * 8 + c * 2 + 1
            got.append(lo | (w.p.memory[0xFF69] << 8))
        want = [int(v, 16) if isinstance(v, str) else int(v) for v in pal['colors_rgb555'][rw]]
        if not pal.get('free_color1'):
            want[1] = 0x6BFF
        ok &= [g & 0x7FFF for g in got] == [v & 0x7FFF for v in want]
        got_txt.append(f'row {rw} {[hex(g & 0x7FFF) for g in got]}')
    w.check('the baked palette rows are in the game\'s palette RAM', ok, '; '.join(got_txt))
    stb = br.screen_state(broom, key, 0)
    T, _l = br.layout_grid(stb['layout'])
    A, _n = br.attr_grid(broom, key, 0)
    pieces = set()
    for i, pl in enumerate(pls):
        stp = ST.stamp_of(bd.custom, pl['stamp']) or ST.stamp_of(d.custom, pl['stamp'])
        rect, _f = ST.visible(pl, stp)
        if rect:
            c0, rr0, c1, rr1 = rect
            pieces |= {(r_, c_) for r_ in range(rr0 * 2, rr1 * 2 + 2) for c_ in range(c0 * 2, c1 * 2 + 2)}

    def piece(qx, qy):
        lc, scx, scy = m[0xFF40], m[0xFF43], m[0xFF42]
        bg = 0x9C00 if lc & 0x08 else 0x9800
        ad = bg + ((scy // 8 + qy) % 32) * 32 + ((scx // 8 + qx) % 32)
        t, at = m[0, ad], m[1, ad]
        return t, _tile16(m, (at >> 3) & 1, t), at & 7
    w.check('the cells show the baked tiles',
            all(piece(c, r)[0] == T[r][c] & 0xFF for (r, c) in pieces))
    w.check('every piece is drawn on its baked palette row',
            all(piece(c, r)[2] == A[r][c] & 7 for (r, c) in pieces))
    want_fr = {}
    for (r, c) in pieces:
        s_ = P2.slot_key(T[r][c])
        fs = {bytes(sheet0[s_ * 16:s_ * 16 + 16])}
        for it in items:
            sl = TA.slots_of(it)
            if s_ in sl and it.get('motion') == 'flip':
                fs |= {bytes.fromhex(fr[sl.index(s_)]) for fr in it['frames']}
        want_fr[(r, c)] = fs
    moving = [p for p in pieces if len(want_fr[p]) > 1]
    speed = 32
    seen, last, gaps = {}, {}, []
    for t in range(speed * 2 * 4 + 20):
        adv(w.p, 1)
        for (r, c) in moving:
            g = piece(c, r)[1]
            seen.setdefault((r, c), set()).add(g)
            if (r, c) in last and last[(r, c)][0] != g:
                gaps.append(t - last[(r, c)][1])
                last[(r, c)] = (g, t)
            elif (r, c) not in last:
                last[(r, c)] = (g, t)
    w.check(f'{len(moving)} moving pieces show only the baked frames',
            bool(moving) and all(seen[p] <= want_fr[p] for p in moving))
    w.check('… and every one of them', bool(moving) and all(seen[p] >= want_fr[p] for p in moving))
    med = statistics.median(gaps) if gaps else 0
    w.check(f'a step every {speed} frames', abs(med - speed) <= 1, f'median gap {med}')
    thr = val(room['record']['collision_threshold'])
    st0 = r0.screen_state(room, key, 0)
    T0, _l = r0.layout_grid(st0['layout'])
    w.check('every cell keeps its wall / walkable side',
            all(P2.is_wall(P2.slot_key(T[r][c]), thr) == P2.is_wall(P2.slot_key(T0[r][c]), thr)
                for (r, c) in pieces if r % 2 and c % 2))
    w.snap('after')
    if a.gif:
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
    w.p.stop(save=False)
    if not a.no_remove:
        d2 = Document(os.path.join(proj, 'project.json'))
        r2 = d2.room(room['id'])
        r2.pop('stamps', None)
        d2.custom.pop('stamps', None)
        d2.touch()
        d2.save()
        pal_after = json.load(open(os.path.join(proj, 'project.json')))['custom'].get('palettes')
        w.check('the stamps removed: the project is what it was but for the palette rows they '
                'wrote (kept for tiles)', snapshot(proj) == before,
                'palette changed' if pal_after != pal_before else 'palette as before')
    print(f'{w.checks - w.fails} / {w.checks} checks passed'
          + (' (NEGATIVE: failures expected)' if a.negative else ''))
    sys.exit(1 if w.fails else 0)


if __name__ == '__main__':
    main()
