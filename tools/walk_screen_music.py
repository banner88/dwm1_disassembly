#!/usr/bin/env python3
"""walk_screen_music.py — a screen's own song in the game (S175, ROADMAP P3.3o).

On a COPY of a project: sets screen songs with the editor's own code
(Document.set_screen_music — what the Rooms tab writes), builds the ROM, CONTINUEs a real
save and, in the room (PyBoy, the ROM0 InitBGM hook = every song START):

  * setting the songs changed nothing in the project but those `music` keys;
  * ENTER: a warp onto the start cell — the song playing is the start screen's, and the
    only song started is that one (the room's own song never started: no blip);
  * each LEG of --route (walk in a direction until the screen changes): the song after
    the scroll is the new screen's (its own, else the room's — --room-song); a leg between
    two screens with the SAME song starts NO song (the "only switches if new");
  * SAVE on the start cell, reset, CONTINUE: the screen's song plays (the resolver part —
    measured S175: before it, a save CONTINUEd to the room's song).
  --negative: the songs are planned but NOT set — the song checks must FAIL.

    python3 tools/walk_screen_music.py --project DIR --sav FILE --room NAME
        --music SCREEN SONG [--music …] --room-song SONG --start SCREEN X Y
        --route "right,left|up,down|down,up"  (| = from the start cell again) [--keep DIR] [--rom-out FILE] [--negative]
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
from tools.pyboy_harness import adv, tap, SCREEN_IDX, MAP_ID                 # noqa: E402
from tools.walk_regions import Walk, s_continue                             # noqa: E402
from editor2.core.document import Document, val                             # noqa: E402

CURRENT, WBGM, SCROLLING = 0xC8B5, 0xC8B7, 0xC8EB


def build(proj):
    out = os.path.join(proj, 'build')
    res = subprocess.run([sys.executable, os.path.join(REPO, 'tools/build_project.py'),
                          '--project', proj, '--out', out, '--build'], capture_output=True,
                         text=True)
    if res.returncode:
        print(res.stdout[-3000:], res.stderr[-3000:])
        raise SystemExit('build failed')
    for line in res.stdout.splitlines():
        if 'screen music' in line or 'music rules' in line:
            print('  ' + line.strip())
    rom = os.path.join(out, 'build', 'rom.gbc')
    return os.path.join(out, 'build'), hashlib.md5(open(rom, 'rb').read()).hexdigest()


def strip(data):
    for r in data['custom'].get('rooms') or []:
        for scr in (r.get('screens') or {}).values():
            if isinstance(scr, dict):
                scr.pop('music', None)
    return data


class Starts:
    """Every InitBGM (a song START) — A = the song id."""

    def __init__(self, w):
        self.w = w
        self.got = []
        b, a = w.sym.get('InitBGM', (0, 0x1AE5))
        w.p.hook_register(b, a, self._hit, None)

    def _hit(self, _c):
        self.got.append(self.w.p.register_file.A)

    def take(self):
        g, self.got = self.got, []
        return g


def save_here(w):
    """The field menu -> OPTN -> JOURNAL -> YES (walk_memorial.save_game, in place)."""
    p = w.p
    hits = []
    sb, sa = w.sym.get('SaveGameState', (0, 0x2128))
    p.hook_register(sb, sa, lambda _c: hits.append(1), None)
    for _ in range(3):
        tap(p, 'b', wait=20)
    tap(p, 'a', hold=3, wait=90)
    tap(p, 'down', hold=8, wait=30)
    tap(p, 'right', hold=8, wait=30)
    tap(p, 'a', hold=3, wait=60)
    for _ in range(3):
        tap(p, 'down', hold=8, wait=30)
    tap(p, 'a', hold=3, wait=90)
    tap(p, 'a', hold=3, wait=200)
    for _ in range(4):
        tap(p, 'b', wait=30)
    p.hook_deregister(sb, sa)
    w.idle()
    return bool(hits)


def walk_leg(w, st, m, leg, want):
    k = m[SCREEN_IDX]
    st.take()
    w.p.button_press(leg)
    moved = False
    for _f in range(400):
        adv(w.p, 1)
        if m[SCREEN_IDX] != k:
            moved = True
        if moved and not m[SCROLLING] & 4:
            break
    w.p.button_release(leg)
    adv(w.p, 40)
    k2 = m[SCREEN_IDX]
    started = st.take()
    print(f'{leg}: screen {k} -> {k2}')
    w.check(f'scrolled from screen {k} {leg}', moved and k2 != k)
    w.check(f'screen {k2}: its song ${want(k2):02X} plays', m[CURRENT] == want(k2),
            f'playing ${m[CURRENT]:02X}')
    if want(k2) == want(k):
        w.check(f'the same song as screen {k}: NO song started (it plays on)',
                started == [], f'starts {[hex(s) for s in started]}')
    else:
        w.check(f'a new song: started once (${want(k2):02X})', started == [want(k2)],
                f'starts {[hex(s) for s in started]}')


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--room', required=True)
    ap.add_argument('--music', nargs=2, action='append', required=True,
                    metavar=('SCREEN', 'SONG'))
    ap.add_argument('--room-song', required=True)
    ap.add_argument('--start', nargs=3, type=int, required=True, metavar=('SCREEN', 'X', 'Y'))
    ap.add_argument('--route', required=True)
    ap.add_argument('--keep')
    ap.add_argument('--rom-out')
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args()
    keep = a.keep or tempfile.mkdtemp(prefix='walk_screen_music_')
    os.makedirs(keep, exist_ok=True)
    proj = os.path.join(keep, 'project')
    shutil.rmtree(proj, ignore_errors=True)
    shutil.copytree(a.project, proj, ignore=shutil.ignore_patterns('build'))
    before = json.load(open(os.path.join(proj, 'project.json')))
    d = Document(os.path.join(proj, 'project.json'))
    room = next(x for x in d.rooms if d.room_name(x) == a.room)
    mid = val(room['mapID'])
    region = mid >> 8
    songs = {int(k): val(s) for k, s in a.music}
    room_song = val(a.room_song)
    if not a.negative:
        for k, s in a.music:
            d.set_screen_music(room, int(k), s)
    d.save()
    after = json.load(open(os.path.join(proj, 'project.json')))
    build_dir, md5 = build(proj)
    print(f"{'NEGATIVE CONTROL (no songs set) ' if a.negative else ''}build: {md5} (patched)")
    if a.rom_out:
        shutil.copy(os.path.join(build_dir, 'rom.gbc'), a.rom_out)
    w = Walk(build_dir, a.sav, keep)
    w.check('setting the songs changed nothing but those music keys',
            strip(after) == strip(json.loads(json.dumps(before))))
    want = lambda k: songs.get(k, room_song)                                # noqa: E731
    s_continue(w)
    w.start('continue')
    st = Starts(w)
    k0, x0, y0 = a.start
    ax, ay = (k0 % 4) * 10 + x0, (k0 // 4) * 8 + y0
    st.take()
    ok = w.goto(mid & 0xFF, region, ax, ay)
    adv(w.p, 60)
    m = w.m
    started = st.take()
    print(f'enter: screen {m[SCREEN_IDX]} ({ax},{ay})')
    w.check(f'entering on screen {k0}: its song ${want(k0):02X} plays',
            ok and m[SCREEN_IDX] == k0 and m[CURRENT] == want(k0),
            f'playing ${m[CURRENT]:02X}')
    w.check('… the only song started is that one (the room\'s song never started)',
            set(started) <= {want(k0)} and started, f'starts {[hex(s) for s in started]}')
    w.save('start')
    for gi, group in enumerate(a.route.split('|')):
        if gi:
            w.start('start')
            st = Starts(w)
            m = w.m
            print('(from the start cell again)')
        for leg in [x.strip() for x in group.split(',') if x.strip()]:
            walk_leg(w, st, m, leg, want)
    # save on the start cell, reset, CONTINUE
    # save on the start cell, reset, CONTINUE
    w.start('start')
    st = Starts(w)
    w.face('up')
    saved = save_here(w)
    w.check(f'saved on screen {k0}', saved)
    w.p.stop(save=True)
    w.p = None
    shutil.copy(w.rom + '.ram', os.path.join(keep, 'here.sav'))
    os.makedirs(os.path.join(keep, 'k2'), exist_ok=True)
    w2 = Walk(build_dir, os.path.join(keep, 'here.sav'), os.path.join(keep, 'k2'))
    s_continue(w2)
    adv(w2.p, 60)
    m2 = w2.m
    w.check(f'CONTINUE on screen {k0}: its song ${want(k0):02X} plays',
            m2[MAP_ID] == (mid & 0xFF) and m2[SCREEN_IDX] == k0 and m2[CURRENT] == want(k0),
            f'map ${m2[MAP_ID]:02X} screen {m2[SCREEN_IDX]} playing ${m2[CURRENT]:02X}')
    w.checks += w2.checks
    w.fails += w2.fails
    print(f'{w.checks - w.fails} / {w.checks} checks passed'
          + (' (NEGATIVE CONTROL: failures expected)' if a.negative else ''))
    sys.exit(0 if (w.fails == 0) != a.negative else 1)


if __name__ == '__main__':
    main()
