#!/usr/bin/env python3
"""walk_jumps.py — Rooms → jumping points in the game (S175, ROADMAP P3.3n).

On a COPY of a project: adds jumps with the editor's own code (Document.add_jump — the
same data the Rooms tab writes), builds the ROM (tools/build_project.py --build), CONTINUEs
a real save, and for each jump stands the player `--approach` cells above it on its
screen, walks DOWN onto it and checks (PyBoy):

  * adding the jumps changed nothing in the project but those npcs[] entries;
  * the generated script is the game's own (GreatTree_Script19's words, the fall in px);
  * stepping on the jump cell runs a script with the player input locked ($D9E8 = 1);
  * the player walks straight down 2 px a frame (walk_fast) to the landing cell;
  * the screen scrolls to the screen below (wScreenIndex = jump screen + 4) and $D9E8 is
    cleared at the scroll's end;
  * the player stands on (x, land_y) of the screen below, and can walk away (a step in
    some direction changes the tile — not the S175 same-screen soft lock).
  --negative: the jumps are planned but NOT added — the landing checks must FAIL.

    python3 tools/walk_jumps.py --project DIR --sav FILE --room NAME
        --jump SCREEN X Y LAND_Y [--jump …] [--approach N] [--keep DIR] [--rom-out FILE]
        [--negative]
"""
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import (adv, SCREEN_IDX, PLAYER_TX, PLAYER_TY,       # noqa: E402
                                 SCRIPT_FLAGS)
from tools.walk_regions import Walk, s_continue                             # noqa: E402
from editor2.core.document import Document, val                             # noqa: E402
from editor2.core import jumps as JU                                        # noqa: E402

INPUT_LOCK = 0xD9E8


def build(proj):
    out = os.path.join(proj, 'build')
    res = subprocess.run([sys.executable, os.path.join(REPO, 'tools/build_project.py'),
                          '--project', proj, '--out', out, '--build'], capture_output=True,
                         text=True)
    if res.returncode:
        print(res.stdout[-3000:], res.stderr[-3000:])
        raise SystemExit('build failed')
    for line in res.stdout.splitlines():
        if 'jump' in line and ('WARN' in line or 'ERROR' in line):
            print('  ' + line.strip())
    rom = os.path.join(out, 'build', 'rom.gbc')
    return os.path.join(out, 'build'), hashlib.md5(open(rom, 'rb').read()).hexdigest()


def strip_jumps(data):
    for r in data['custom'].get('rooms') or []:
        for scr in (r.get('screens') or {}).values():
            for st in JU._states(scr):
                if st.get('npcs'):
                    st['npcs'] = [e for e in st['npcs'] if not JU.is_jump(e)]
    return data


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--room', required=True)
    ap.add_argument('--jump', nargs=4, type=int, action='append', required=True,
                    metavar=('SCREEN', 'X', 'Y', 'LAND_Y'))
    ap.add_argument('--approach', type=int, default=2)
    ap.add_argument('--keep')
    ap.add_argument('--rom-out')
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args()
    keep = a.keep or tempfile.mkdtemp(prefix='walk_jumps_')
    os.makedirs(keep, exist_ok=True)
    proj = os.path.join(keep, 'project')
    shutil.rmtree(proj, ignore_errors=True)
    shutil.copytree(a.project, proj, ignore=shutil.ignore_patterns('build'))
    before = json.load(open(os.path.join(proj, 'project.json')))
    d = Document(os.path.join(proj, 'project.json'))
    room = next(x for x in d.rooms if d.room_name(x) == a.room)
    mid = val(room['mapID'])
    region = mid >> 8
    for k, x, y, ly in a.jump:
        if not a.negative:
            d.add_jump(room, k, 0, x, y, ly)
    d.save()
    after = json.load(open(os.path.join(proj, 'project.json')))
    build_dir, md5 = build(proj)
    print(f"{'NEGATIVE CONTROL (no jumps added) ' if a.negative else ''}build: {md5} (patched)")
    if a.rom_out:
        shutil.copy(os.path.join(build_dir, 'rom.gbc'), a.rom_out)
    w = Walk(build_dir, a.sav, keep)
    w.check('adding the jumps changed nothing but those npcs[] entries',
            strip_jumps(after) == strip_jumps(json.loads(json.dumps(before))))
    asm = open(os.path.join(proj, 'build', 'patches', 'bank_060.asm')).read() \
        if os.path.exists(os.path.join(proj, 'build', 'patches', 'bank_060.asm')) else ''
    for k, x, y, ly in a.jump:
        fall = JU.fall_px(y, ly)
        want = ('dw $FF12', 'dw $D9E8', 'dw $0001', 'dw $FF21', 'dw $0055', 'dw $FF22',
                'dw $FF1B', 'dw $0000', f'dw ${fall:04X}', 'dw $FF19', 'dw $FFFF')
        lab = f'_jump_{room["id"]}_{fall}'
        body = []
        lines = asm.splitlines()
        name = next((ln.split()[1] for ln in lines
                     if ln.strip().startswith('dw ') and ln.rstrip().endswith(f'] {lab}')), None)
        if name:
            i = lines.index(f'{name}:')
            for ln in lines[i + 1:]:
                if not ln.strip():
                    break
                body.append(ln.split(';')[0].strip())
        if not a.negative:
            w.check(f'screen {k} ({x},{y}): the script is the game\'s own recipe (fall {fall} px)',
                    tuple(body) == want, ' '.join(body))
    s_continue(w)
    for k, x, y, ly in a.jump:
        col, row = k % 4, k // 4
        ax, ay = col * 10 + x, row * 8 + y
        below = k + 4
        print(f'jump: screen {k} ({x},{y}) -> screen {below} ({x},{ly})')
        w.start('continue')
        if not w.goto(mid & 0xFF, region, ax, ay - a.approach):
            w.check(f'warp to screen {k} ({x},{y - a.approach})', False)
            continue
        m = w.m
        w.keep_enc()
        x0, y0 = m[PLAYER_TX], m[PLAYER_TY]
        locked = ran = False
        t_fire = t_land = None
        ys = []
        w.p.button_press('down')
        f = 0
        while f < 1200:
            adv(w.p, 1)
            f += 1
            w.keep_enc()
            if m[SCRIPT_FLAGS] & 1 and m[PLAYER_TY] >= ay - 1:
                ran = True
                if t_fire is None:
                    t_fire = f
                    w.p.button_release('down')
            if m[INPUT_LOCK]:
                locked = True
            if ran:
                ys.append(m[0xFF95] | (m[0xFF96] << 8))
            if ran and not m[INPUT_LOCK] and not m[SCRIPT_FLAGS] & 1 and m[SCREEN_IDX] == below:
                t_land = f
                break
            if not ran and f > 400:
                break
        w.p.button_release('down')
        adv(w.p, 30)
        w.snap(f'jump_{k}_{x}_{y}')
        land = (m[SCREEN_IDX], m[PLAYER_TX], m[PLAYER_TY])
        exp = (below, (below % 4) * 10 + x, (below // 4) * 8 + ly)
        w.check(f'start ({x0},{y0}) on screen {k}', (x0, y0) == (ax, ay - a.approach))
        w.check('stepping on the jump ran a script with the input locked ($D9E8 = 1)',
                ran and locked, f'script {ran}, lock {locked}')
        steps = [b - a_ for a_, b in zip(ys, ys[1:]) if b != a_]
        w.check('the player walked straight down 2 px a frame (walk_fast)',
                bool(steps) and all(s == 2 for s in steps), f'steps {sorted(set(steps))}')
        w.check(f'the screen scrolled to screen {below} and $D9E8 was cleared',
                t_land is not None, f'fired at frame {t_fire}, free at {t_land}')
        w.check(f'the player stands on screen {below} ({x},{ly}) = tile {exp[1:]}',
                land == exp, f'got screen {land[0]} tile {land[1:]}')
        moved = False
        for dname in ('left', 'right', 'down', 'up'):
            px, py = m[PLAYER_TX], m[PLAYER_TY]
            w.p.button_press(dname)
            adv(w.p, 24)
            w.p.button_release(dname)
            adv(w.p, 20)
            if (m[PLAYER_TX], m[PLAYER_TY]) != (px, py):
                moved = True
                break
        w.check('the player can walk away after landing (no soft lock)', moved,
                f'$D9E8 = {m[INPUT_LOCK]}')
    print(f'{w.checks - w.fails} / {w.checks} checks passed'
          + (' (NEGATIVE CONTROL: failures expected)' if a.negative else ''))
    sys.exit(0 if (w.fails == 0) != a.negative else 1)


if __name__ == '__main__':
    main()
