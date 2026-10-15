#!/usr/bin/env python3
"""walk_songs.py — S147 (ROADMAP ARC CAP5, songs at campaign scale): the JUKEBOX HALLS in the game.

Since S147 a project song takes ONE sound id (95 songs) and its streams sit in bank $74,
$75 or a bank $80+ of the 4 MB ROM; the rewritten InitBGM starts it through bank $71
entry 6 -> bank $74 SongStart (the song directory; templates/bank_074_head.asm). The
demo (examples/s147_jukebox_demo/build_demo.py) puts the user's song + the 31 DWM2 songs
into the user's project: eleven halls, each with a room song and two bards whose talk
cutscene plays a song by name.

  walk — PyBoy on the user's .sav (CONTINUE): the JUKEBOX GUIDE in Cities_FOUNT sends us to
         hall 1; then for every hall: entering it requests the hall's song (ROM0 `SetBGM`
         hook, A = the id the plan gave it); each bard's talk requests his; after every
         request the game's channel states are the song's: exactly its state slots live,
         each channel's stream pointer (+2/+3) = its stream label in game.sym and its DATA
         BANK (+4) = the song's bank ($74 / $75 / $80+); then 600 frames later every live
         channel's position is still inside its own stream and has moved (the song plays,
         from the right bank). Hall 1 -> 2 by the real stairs; hall 11's Bard B brings the
         hall song back ("music back"); hall 11's monster: the battle requests the hall's
         battle song (a bank $80+ song) and the hall song comes back after the win; a
         JOURNAL save in hall 11 + CONTINUE: the load requests the hall song, from its bank.
  --negative: in the ROM copy SongStart's `ld [hl], c` (the bank byte) -> nop: every song
         placed outside bank $74 must FAIL its bank / position checks, every bank $74 song
         must still pass.

  python3 tools/walk_songs.py walk --build DIR/build/build --project DIR/project.json \
      --sav USER.sav --keep KEEP [--negative] [--only enter,halls,battle,journal]

Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`. PYBOY_DEBUGGING "S147".
"""
import argparse
import json
import os
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, GAME_MODE        # noqa: E402

from tools.walk_regions import Walk, s_continue             # noqa: E402

SLOTS = (0x00, 0x1A, 0x34, 0x4E, 0x68, 0x82)
SET_BGM = (0, 0x1AE1)
GUIDE = (5, 4)                 # build_demo.py: the JUKEBOX GUIDE in Cities_FOUNT
BARDS = {'Bard A': (3, 3), 'Bard B': (6, 3)}
MONSTER = (5, 5)


def plan(project_path, build):
    """{song: (sid, bank, [(slot, label, stream bytes)])} from the project's music plan
    (the same Project the build ran) — the walk compares the game with it."""
    from editor2.core.project import Project
    from editor2.core import music as M
    d = json.load(open(project_path))
    prj = Project(d, os.path.dirname(os.path.abspath(project_path)))
    prj.repo_root = REPO
    out = {}
    for L in M.song_layout(prj):
        out[L['id']] = (L['sid'], L['bank'], [(c[0], c[3], len(c[4])) for c in L['channels']])
    halls = sorted((r for r in prj.rooms if str(r.get('name', '')).startswith('JUKEBOX HALL')),
                   key=lambda r: int(r['name'].split()[-1]))
    room_song = {int(str(r['mapID']), 16): r.get('music') for r in halls}
    P = prj.music_plan()
    battle = {mid: P.room_battle[mid] for mid in room_song}
    bards = {}
    for r in halls:
        mid = int(str(r['mapID']), 16)
        for sc in r.get('cutscenes') or []:
            actor = (sc.get('trigger') or {}).get('actor')
            mus = next((st['music'] for st in sc['steps'] if 'music' in st), None)
            bards[(mid, actor)] = mus['song'] if isinstance(mus, dict) else mus
    cities = next(int(str(r['mapID']), 16) for r in prj.rooms if r.get('id') == 'cities_fount')
    return out, [int(str(r['mapID']), 16) for r in halls], room_song, battle, bards, cities


def _sound_boot(rom):
    """The harness boot with the APU on: the engine reads NR52 bit 2 at every wave note
    (SOUND_SYSTEM §9; KEY_LESSONS S116) — a walk that checks the music runs the sound."""
    from pyboy import PyBoy
    p = PyBoy(rom, window='null', cgb=True, sound_emulated=True)
    p.set_emulation_speed(0)
    return p


class SongWalk(Walk):
    def __init__(self, build, sav, keep, songs):
        super().__init__(build, sav, keep)
        self.songs = songs
        self.by_sid = {v[0]: k for k, v in songs.items()}
        self.req = []
        self.starts = []

    def start(self, state=None):
        import tools.pyboy_harness as H
        import tools.walk_regions as WR
        H.boot = WR.boot = _sound_boot
        super().start(state)
        b, a = SET_BGM
        self.p.hook_register(b, a, lambda _c: self.req.append(self.p.register_file.A), None)
        # the `ret` of bank $74 SongStart (after its channel loop): the song just started —
        # its channel states as the game set them (S147, templates/bank_074_head.asm)
        b, a = self.sym['SongStart.channel']
        rom = open(self.rom, 'rb').read()
        o = b * 0x4000 + a - 0x4000
        k = rom.find(bytes([0x05, 0x20]), o, o + 0x40)           # dec b / jr nz, .channel
        self.p.hook_register(b, 0x4000 + (k + 3) % 0x4000, self._started, None)

    def _started(self, _c):
        self.starts.append((self.m[0xC8B5], self.chans()))

    def break_bank_byte(self):
        """NEGATIVE CONTROL: SongStart's `ld [hl], c` (the channel's data bank) -> nop in
        the ROM copy: a song keeps bank $74 as its data bank."""
        b, a = self.sym['SongStart.channel']
        rom = bytearray(open(self.rom, 'rb').read())
        base = b * 0x4000 + a - 0x4000
        k = rom.find(bytes([0x22, 0x71, 0x62, 0x6B]), base, base + 0x40)   # ld [hl+],a / ld [hl],c / ld h,d / ld l,e
        if k < 0:
            raise SystemExit('SongStart: `ld [hl], c` not found')
        rom[k + 1] = 0x00
        open(self.rom, 'wb').write(rom)
        self.negative = True
        print(f'NEGATIVE CONTROL: SongStart\'s bank store at ${b:02X}:{0x4000 + (k + 1) % 0x4000:04X} '
              'removed')

    # -- the song now playing
    def chans(self):
        m = self.m
        out = {}
        for s in SLOTS:
            b = 0xDD80 + s
            pos = m[b] | m[b + 0x19] << 8
            if pos != 0xFFFF:
                out[s] = (m[b + 2] | m[b + 3] << 8, m[b + 4], pos)
        return out

    def check_song(self, what, song):
        """The game requested `song` and started it (bank $74 SongStart's own `ret`):
        exactly its state slots, each channel's stream pointer = its stream label and its
        data bank = the song's bank; then for 600 frames every live channel keeps that
        bank and stays inside its own stream (a channel may end; a rest may last long —
        BGM #04's noise rests 1,228 frames)."""
        sid, bank, chans = self.songs[song]
        self.check(f'{what}: the game requested {song} (${sid:02X})', sid in self.req,
                   ' '.join(f'${x:02X}' for x in self.req[-6:]))
        st = [c for i, c in self.starts if i == sid]
        got = st[-1] if st else {}
        want = {s: (self.sym[lab][1], bank) for s, lab, _n in chans}
        self.check(f'{what}: started with {len(chans)} channels from bank ${bank:02X}, each '
                   'at its stream', {s: g[:2] for s, g in got.items()} == want,
                   ' '.join(f'${s:02X}=${g[0]:04X}@${g[1]:02X}' for s, g in sorted(got.items()))
                   or 'no start seen')
        lens = {s: n for s, _lab, n in chans}
        ok, bad = True, ''
        for _ in range(60):
            adv(self.p, 10)
            for s, (ptr, bk, pos) in self.chans().items():
                if s not in lens or bk != bank or 2 * pos >= lens[s] + 2 or \
                        ptr != want[s][0]:
                    ok, bad = False, f'slot ${s:02X}: ${ptr:04X}@${bk:02X} pos {pos}'
        self.check(f'{what}: 600 frames on, every channel still in its own stream', ok, bad)


def walk(a):
    songs, halls, room_song, battle, bards, cities = plan(a.project, a.build)
    os.makedirs(a.keep, exist_ok=True)
    w = SongWalk(a.build, a.sav, a.keep, songs)
    if a.negative:
        w.break_bank_byte()
    steps = set(a.only.split(',')) if a.only else {'enter', 'halls', 'battle', 'journal'}
    s_continue(w)
    if 'enter' in steps:
        print('enter: the JUKEBOX GUIDE (Cities_FOUNT) -> hall 1; its song')
        w.start('continue')
        w.goto(cities, 0, GUIDE[0], GUIDE[1] + 1)
        w.face('up')
        w.req.clear()
        w.talk([True])
        w.idle()
        w.check_at('the guide sent us to JUKEBOX HALL 1', halls[0], 0)
        w.check_song('hall 1', room_song[halls[0]])
        w.save('hall1')
    if 'halls' in steps:
        for n, mid in enumerate(halls, 1):
            print(f'hall {n} (${mid:02X}): the hall song, Bard A, Bard B')
            if n == 1:
                w.start('hall1')
            elif n == 2:
                # the real stairs: hall 1's up stairs at (8, 1), from (8, 2) moving up
                w.req.clear()
                w.goto(halls[0], 0, 8, 2)
                w.req.clear()
                w.face('up')
                w.step('up')
                w.idle()
                w.check_at('hall 1 up stairs -> hall 2', mid, 0)
                w.check_song(f'hall {n} (by the stairs)', room_song[mid])
            else:
                w.req.clear()
                w.goto(mid, 0, 4, 5)
                w.check_song(f'hall {n}', room_song[mid])
            for actor, (x, y) in BARDS.items():
                song = bards[(mid, actor)]
                w.goto(mid, 0, x, y + 1)
                w.face('up')
                w.req.clear()
                r = w.talk()
                w.idle()
                if song == 'back':
                    w.check_song(f'hall {n} {actor} (the hall song back)', room_song[mid])
                else:
                    w.check_song(f'hall {n} {actor}', song)
        w.save('hall11')
    if 'battle' in steps:
        mid = halls[-1]
        bsong = w.by_sid.get(battle[mid])
        print(f'battle: hall 11\'s monster — the battle song {bsong}, then the hall song again')
        w.start('hall11')
        w.goto(mid, 0, MONSTER[0], MONSTER[1] + 1)
        w.face('up')
        w.req.clear()
        r = w.talk([True])
        w.check('the monster\'s talk started a battle', r == 'battle', r)
        seen_battle = []
        while w.m[GAME_MODE] == 2 and not seen_battle:
            adv(w.p, 4)
            if battle[mid] in w.req:
                seen_battle.append(1)
        if bsong:
            w.check_song('hall 11 battle', bsong)
        won = w.battle_won()
        w.check('battle won, back in the hall', won and w.where() == (mid, 0))
        w.req.clear()
        w.idle()
        adv(w.p, 120)
        w.idle()
        w.check_song('hall 11 after the battle', room_song[mid])
    if 'journal' in steps:
        mid = halls[-1]
        print('journal: save in hall 11 (its song in a bank $80+), CONTINUE -> its song')
        w.start('hall11')
        w.goto(mid, 0, 2, 5)
        w.face('down')
        p = w.p
        b, a2 = w.sym['SaveGameState']
        saved = []
        p.hook_register(b, a2, lambda _c: saved.append(1), None)
        tap(p, 'a', hold=3, wait=90)
        tap(p, 'down', hold=6, wait=20)
        tap(p, 'right', hold=6, wait=20)
        tap(p, 'a', hold=3, wait=60)
        for _ in range(3):
            tap(p, 'down', hold=6, wait=20)
        tap(p, 'a', hold=3, wait=90)
        tap(p, 'a', hold=3, wait=200)
        for _ in range(10):
            if saved:
                break
            tap(p, 'a', hold=3, wait=60)
        adv(p, 300)
        w.check('the JOURNAL saved', bool(saved))
        p.hook_deregister(b, a2)
        p.stop(save=True)
        ram = os.path.join(a.keep, 'journal.sav')
        shutil.copy(w.rom + '.ram', ram)
        w2 = SongWalk(a.build, ram, a.keep, songs)
        w2.rom = w.rom
        w2.req = []
        s_continue(w2)
        w2.check_at('CONTINUE -> JUKEBOX HALL 11', mid, 0)
        w2.check_song('hall 11 after CONTINUE', room_song[mid])
        w.checks += w2.checks
        w.fails += w2.fails
        w.p = w2.p
    print(f'WALK: {"PASS" if not w.fails else "FAIL"}' + (f' {w.fails}' if w.fails else '')
          + f'  ({w.checks} checks)')
    w.p.stop(save=False)
    return w.fails == 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', choices=('walk',))
    ap.add_argument('--build', required=True, help='the build dir (rom.gbc, game.sym, manifest.json)')
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--only')
    a = ap.parse_args()
    ok = walk(a)
    return 0 if ok != a.negative else 1


if __name__ == '__main__':
    sys.exit(main())
