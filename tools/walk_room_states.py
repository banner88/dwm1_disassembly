#!/usr/bin/env python3
"""walk_room_states.py — kept room states in the game (S144, ROADMAP ARC CAP4c; PyBoy).

Takes the two scratch projects `tools/census_room_states.py --keep DIR` leaves
(`every_state/` = every game room copied with all its states, following the
game's counters; `kept/` = the same rooms with the editor's DEFAULT keep spec),
builds both, and on the user's `.sav` (CONTINUE once, then a savestate):

  loads   for every kept state of every copied room (or --rooms): the KEPT build
          with every original-game counter $D92A-$D99A zeroed (a new romhack: the
          original story never ran) and the copy's own counter / remembered-state
          flag poked to the new state number, warped into that screen; the
          EVERY-STATE build with the original counter of that screen poked to the
          ORIGINAL number, warped the same way. What the engine loaded (bank $0B's
          copies `wCustomNPCBuffer` $CC80 / `wCustomExitBuffer` $CD00, and the
          screen's step counter) must be the same bytes; then the kept copy is
          let run (A on boxes): no reset (game mode 0), no hang;
  boss    (--boss) the kept Boss: Villager copy: its boss fought and won (the
          entry spots' script, flag `$00B6` poked as the talk would set it), the
          room's remembered-state flag set and its counter 1; a JOURNAL save; the
          save CONTINUEd; the copy entered again → state 1 (the beaten room: one
          NPC, the exit) by the state rule.

  python3 tools/walk_room_states.py --dir DIR --sav SAV [--rooms 0x01,0x31] [--boss]
  python3 tools/walk_room_states.py ... --negative   # the kept build's state rules
                                                     # dropped: the boss check must FAIL
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

from tools.pyboy_harness import adv, tap, MAP_ID, GAME_MODE, SCREEN_IDX  # noqa: E402
from tools.walk_regions import Walk, read_sym, s_continue                 # noqa: E402
from editor2.core.formats import val                                      # noqa: E402
from editor2.core import room_states as RS                                # noqa: E402

NPC_BUF, EXIT_BUF = 0xCC80, 0xCD00
VANILLA_CTRS = range(0xD92A, 0xD99B)


def build(project):
    r = subprocess.run([sys.executable, os.path.join(REPO, 'tools', 'build_project.py'),
                        '--project', project, '--build'], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit('build failed: ' + (r.stdout + r.stderr)[-800:])
    return os.path.join(project, 'build', 'build')


def buf(m, base, size):
    out = []
    for i in range(size):
        b = m[base + i]
        out.append(b)
        if b == 0xFF and (i % 5 == 0 if base == NPC_BUF else i % 7 == 0):
            break
    return bytes(out)


def ext_set(m, idx, on=True):
    """Any saved event flag: < $1000 at $D99B, $1000-$17FF at wExtFlags $D140 (both
    MSB-first; EVENT_FLAGS "Extended flags (S117)"). The project's new flags come
    from $0159-$0167 first, then $1000+ (Document.add_flag)."""
    base, o = (0xD99B, idx) if idx < 0x1000 else (0xD140, idx - 0x1000)
    bit = 1 << (7 - (o & 7))
    if on:
        m[base + (o >> 3)] |= bit
    else:
        m[base + (o >> 3)] &= ~bit & 0xFF


def flag_on(m, idx):
    base, o = (0xD99B, idx) if idx < 0x1000 else (0xD140, idx - 0x1000)
    return (m[base + (o >> 3)] >> (7 - (o & 7))) & 1


def tile_of(k):
    k = int(k)
    return (k % 4) * 10 + 5, (k // 4) * 8 + 4


def enter(w, mid, k, settle=True):
    """The warp mailbox into screen k (region 0); the loaded bytes right after."""
    m = w.m
    x, y = tile_of(k)
    from tools.walk_regions import W_REGION, W_DEST, W_FLAG, W_XLO, W_XHI, W_YLO, W_YHI, \
        W_CHANGING, W_KICK, SCRIPT_FLAGS
    m[SCRIPT_FLAGS] = 0
    m[W_REGION] = 1
    m[W_DEST], m[W_FLAG] = mid, 0
    px, py = x * 16 + 8, y * 16 + 8
    m[W_XLO], m[W_XHI], m[W_YLO], m[W_YHI] = px & 0xFF, px >> 8, py & 0xFF, py >> 8
    m[W_CHANGING] = 1
    m[W_KICK] = 1
    for _ in range(400):
        adv(w.p, 1)
        if m[MAP_ID] == mid and m[W_CHANGING] == 0 and m[SCREEN_IDX] == int(k):
            break
    adv(w.p, 4)
    return buf(m, NPC_BUF, 128), buf(m, EXIT_BUF, 127), m[SCREEN_IDX]


def rooms_of(project):
    d = json.load(open(os.path.join(project, 'project.json')))
    return {r['name']: r for r in d['custom']['rooms']}, d


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--dir', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--rooms')
    ap.add_argument('--boss', action='store_true')
    ap.add_argument('--no-loads', action='store_true')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--no-build', action='store_true', help='reuse the two builds (a batch '
                    'run per room: a game that hangs in PyBoy stops only its own process)')
    a = ap.parse_args()
    pa, pb = os.path.join(a.dir, 'every_state'), os.path.join(a.dir, 'kept')
    if a.negative:
        d = json.load(open(os.path.join(pb, 'project.json')))
        for r in d['custom']['rooms']:
            r.pop('state_rules', None)
        open(os.path.join(pb, 'project.json'), 'w').write(json.dumps(d, indent=1))
        print('NEGATIVE CONTROL: every state rule of the kept build dropped')
    if a.no_build:
        ba, bb = (os.path.join(x, 'build', 'build') for x in (pa, pb))
    else:
        ba, bb = build(pa), build(pb)
    keep = os.path.join(a.dir, 'walk')
    os.makedirs(keep, exist_ok=True)
    for sub in ('a', 'b', 'b2'):
        os.makedirs(os.path.join(keep, sub), exist_ok=True)
    wa = Walk(ba, os.path.abspath(a.sav), os.path.join(keep, 'a'))
    wb = Walk(bb, os.path.abspath(a.sav), os.path.join(keep, 'b'))
    s_continue(wa)
    s_continue(wb)
    RA, _da = rooms_of(pa)
    RB, db = rooms_of(pb)
    flag_num = {f['name']: val(f['index']) for f in db['custom'].get('flags') or []}
    want = None
    if a.rooms:
        want = {int(x, 16) for x in a.rooms.split(',')}
    fails = checks = 0
    notes = []

    def check(what, ok, detail=''):
        nonlocal fails, checks
        checks += 1
        fails += not ok
        if not ok:
            print(f'  FAIL {what}  [{detail}]')
        return ok

    if not a.no_loads:
        for name, B in RB.items():
            src = val(B['source_mapID'])
            if want is not None and src not in want:
                continue
            A = RA[name]
            spec = RS.default_spec(_StubDoc(_da), A, RS.default_point(src))
            mid_a, mid_b = val(A['mapID']), val(B['mapID'])
            rules = {}
            for ru in B.get('state_rules') or []:
                for k in ru.get('screens') or []:
                    rules[(str(k), int(ru['state']))] = flag_num[ru['when'][0]['flag']]
            row = []
            for k in sorted(B['screens'], key=int):
                s = spec['screens'][k]
                if s.get('follow'):
                    continue
                order = [s['start']] + [i for i in s['keep'] if i != s['start']]
                lab = (B['screens'][k].get('step_counter') or {}).get('label')
                for new, old in enumerate(order):
                    # A: the original counter = the original state
                    wa.start('continue')
                    vc = val(A['screens'][k]['step_counter']['vanilla'])
                    wa.m[vc] = old
                    la, ea, sa = enter(wa, mid_a, k)
                    # B: a new romhack — every original counter 0; the copy's own
                    wb.start('continue')
                    for c in VANILLA_CTRS:
                        wb.m[c] = 0
                    for f in rules.values():
                        ext_set(wb.m, f, False)
                    if (k, new) in rules:
                        ext_set(wb.m, rules[(k, new)])
                    if lab and lab in wb.sym and new:
                        wb.m[wb.sym[lab][1]] = new
                    lb, eb, sb = enter(wb, mid_b, k)
                    ctr = wb.m[wb.sym[lab][1]] if lab in wb.sym else None
                    ok = check(f'{name} screen {k} state {old}->{new}: the same people / exits '
                               'loaded', (la, ea) == (lb, eb) and sa == sb == int(k),
                               f'A {la.hex()} {ea.hex()} s{sa} / B {lb.hex()} {eb.hex()} s{sb}')
                    check(f'{name} screen {k}: counter {ctr} == {new}', ctr in (None, new),
                          f'{ctr}')
                    # let the kept copy run: no reset, no hang
                    calm = wb.idle(maxf=2500)
                    mode = wb.m[GAME_MODE]
                    check(f'{name} screen {k} state {new}: runs on (no reset)', mode != 0,
                          f'game mode {mode}')
                    row.append(f's{k}:{old}->{new}{"" if ok else "!"}'
                               f'{"" if calm else "(busy)"}'
                               f'{"" if wb.m[MAP_ID] == mid_b else "(moved $%02X)" % wb.m[MAP_ID]}')
            print(f'${src:02X} {name[:30]:30s} ' + ' '.join(row))
    if a.boss:
        fails_before = fails
        name = next(n for n, r in RB.items() if val(r['source_mapID']) == 0x31)
        B = RB[name]
        mid = val(B['mapID'])
        ru = (B.get('state_rules') or [{}])[0]
        fl = flag_num.get((ru.get('when') or [{}])[0].get('flag')) if ru else \
            next(v for k, v in flag_num.items() if k.startswith('boss_villager'))
        lab = B['screens']['0']['step_counter']['label']
        w = wb
        w.start('continue')
        for c in VANILLA_CTRS:
            w.m[c] = 0
        enter(w, mid, 0)
        w.idle()
        for _ in range(3):
            tap(w.p, 'b', wait=20)
        n0 = buf(w.m, NPC_BUF, 128)
        check('Villager copy: enters in state 0 (boss here: 6 entries)', n0.count(b'\xff') >= 1
              and len(n0) == 31, n0.hex())
        # the boss conversation's last answer sets $00B6; the arrival spots run script 2
        from tools.pyboy_harness import set_flag
        set_flag(w.p, 0x00B6)
        w.goto(mid, 0, 4, 2)
        w.face('up')
        r = w.talk([True])
        check('Villager copy: the spot starts the boss battle', r == 'battle', r)
        won = w.battle_won()
        check('Villager copy: the battle won', won)
        w.follow(1500, until=lambda: w.m[MAP_ID] != mid and w.m[GAME_MODE] == 1
                 and not w.m[0xC96C])
        w.idle()
        check('Villager copy: its remembered-state flag is ON', fl is not None and flag_on(w.m, fl),
              f'flag {fl}')
        check('Villager copy: its counter is 1', w.m[w.sym[lab][1]] == 1,
              f'{w.m[w.sym[lab][1]]}')
        # JOURNAL save where we are (the boss tail warps to the Castle)
        hits = []
        sb, sa = w.sym.get('SaveGameState', (0, 0x2128))
        w.p.hook_register(sb, sa, lambda _c: hits.append(1), None)
        w.goto(0x00, 0, 4, 6)
        for _ in range(3):
            tap(w.p, 'b', wait=20)
        tap(w.p, 'a', hold=3, wait=90)
        tap(w.p, 'down', hold=8, wait=30)
        tap(w.p, 'right', hold=8, wait=30)
        tap(w.p, 'a', hold=3, wait=60)
        for _ in range(3):
            tap(w.p, 'down', hold=8, wait=30)
        tap(w.p, 'a', hold=3, wait=90)
        tap(w.p, 'a', hold=3, wait=200)
        for _ in range(4):
            tap(w.p, 'b', wait=30)
        check('JOURNAL: the game saved', bool(hits), f'{len(hits)} call(s)')
        w.p.stop(save=True)
        w.p = None
        sav2 = os.path.join(keep, 'beaten.sav')
        shutil.copy(w.rom + '.ram', sav2)
        w2 = Walk(bb, sav2, os.path.join(keep, 'b2'))
        s_continue(w2)
        check('after CONTINUE: the flag is still ON', flag_on(w2.m, fl), f'flag {fl}')
        check('after CONTINUE: the copy\'s own counter is 0 (transient)', w2.m[w2.sym[lab][1]] == 0)
        nb, _e, _s = enter(w2, mid, 0)
        w2.idle()
        check('after CONTINUE: the Villager copy shows its beaten state (state rule)',
              w2.m[w2.sym[lab][1]] == 1 and len(nb) == 6, f'ctr {w2.m[w2.sym[lab][1]]} {nb.hex()}')
        w2.snap('villager_beaten')
        w2.p.stop(save=False)
        print(f'boss: {"PASS" if fails == fails_before else "FAIL"}')
    for wk in (wa, wb):
        if wk.p is not None:
            wk.p.stop(save=False)
    print(f'WALK: {"PASS" if fails == 0 else "FAIL " + str(fails)} ({checks} checks)')
    return 1 if fails else 0


class _StubDoc:
    """The bits of Document room_states.default_spec reads, over raw project data."""

    def __init__(self, data):
        self.data = data

    @property
    def custom(self):
        return self.data['custom']


if __name__ == '__main__':
    sys.exit(main())
