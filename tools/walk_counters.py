#!/usr/bin/env python3
"""walk_counters.py — S146 (ROADMAP ARC CAP5, the first box): screens per group of 128 rooms.

Before S146 every screen of a custom room had a one-byte state counter of its own (one-state
screens too) and a region's counters share 640 bytes — 128 rooms × 6 screens stopped the build.
S146: a screen with ONE state whose counter no script names reads one shared always-zero byte
(`wCustomStepZero`, the original game's rule: 65 single-state screens of its gate / maze / arena
rooms read `$D998`, which nothing writes); and (b) the editor puts a new room into the next group
of 128 once a group's counters are 90 % used (`Document.next_free_mapid`). The acceptance:

  make   — THE COUNTER HALLS, a fresh project made through the editor's own Document (the calls
           the Rooms tab makes): 128 CALM HALLS of 6 screens (3 × 2), one state each, every
           screen with its own wall code (the hall and screen number in wall blocks), a guide on
           screen 0; then 100 LIT HALLS of 6 screens with TWO states each (state 1: its own
           layout with a lit row + a second NPC) and a state rule "state 1 while the flag
           `counter_halls_lit` is set" — the editor fills the second group until its counters
           are 90 % used and puts the rest in the third group; then the SWITCH HALL: screen 0 has
           two states and no rule (a LEVER NPC's script writes its counter: `write_ram`), screen 1
           has one state but a TESTER NPC's script tests its counter (`check_and_branch` → flag A
           when 0, flag B otherwise) — both keep a byte of their own. Built (compiler + builder,
           as the editor's Build does), with the Capacity report and the allocation printed.
  walk   — PyBoy on the user's .sav (CONTINUE): every screen of every hall entered through the
           warp mailbox with its region — map id, region, screen, the game's picture == the
           editor's preview, the NPC buffer == the state's list (count), the screen's counter
           byte (from the build manifest) == the expected state, and the shared zero byte == 0
           after every screen; the lit halls first with the flag clear (state 0), then set
           (state 1); the switch hall's tester (flag A) and lever (re-entry shows state 1);
           crossings between the groups; a JOURNAL save in a lit hall of the third group + CONTINUE
           (the counter is transient, the rule brings state 1 back); Play here's counter lookup
           for a room of the third group (the manifest, `cutscenes.counter_address`) — and that
           game.sym alone lacks it (the S145 lookup) — with the playback engine starting it in
           state 1.
           `--negative`: the shared zero byte poked to 1 before entering three calm halls — their
           checks must FAIL (a one-state screen then reads past its only state).

  python3 tools/walk_counters.py make --out DIR
  python3 tools/walk_counters.py walk --out DIR --sav USER.sav [--keep DIR2] [--negative]
                                      [--only calm,lit,switch,cross,journal,playhere]
  python3 tools/walk_counters.py ab --old OLD_PROJECT --out NEW_PROJECT --sav USER.sav
           (any project built by the S145 code into OLD/build and by this code into NEW/build:
            every screen of every room — place, picture, NPC + exit buffers, counter — identical)
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`. PYBOY_DEBUGGING "S146".
"""
import argparse
import json
import os
import shutil
import sys
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')

CALM, LIT = 128, 100
KEYS = (0, 1, 2, 4, 5, 6)                 # 3 × 2 screens
WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
GUIDE = (7, 5)                            # cell; talk from (7, 6) facing up
SECOND = (2, 5)                           # the lit state's second NPC
LIT_FLAG = 'counter_halls_lit'
LEVER_LABEL, TEST_LABEL = 'wCustomStep_SwitchLever', 'wCustomStep_SwitchTest'
FLAG_ZERO, FLAG_NONZERO, FLAG_LEVER = 'switch_saw_zero', 'switch_saw_nonzero', 'switch_lever_pulled'


def calm_name(n):
    return f'CALM HALL {n}'


def lit_name(n):
    return f'LIT HALL {n}'


# ============================================================== make
def make(out):
    from editor2.core.document import Document
    from editor2.core.render_project import ProjectRenderer
    from editor2.core.project import Project, STEP_GROUP_FULL
    from editor2.core import compiler as C, builder as B, capacity as CAP, formats as F
    if os.path.exists(out):
        shutil.rmtree(out)
    os.makedirs(os.path.join(out, 'assets'))
    shutil.copy(os.path.join(REPO, 'editor2/templates/blank-project/project.json'), out)
    d = Document(os.path.join(out, 'project.json'))
    r = ProjectRenderer(REPO, d.project_dir, d.data)

    def paint(lid, cx, cy, mt, pal):
        lay = d.layout(lid)
        for i, (dy, dx) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
            lay['tiles'][2 * cy + dy][2 * cx + dx] = mt[i]
            if 'attr' in lay:                 # a state's own layout: the screen's colours
                lay['attr'][2 * cy + dy][2 * cx + dx] = pal

    def floor_pal(lid):
        lay = d.layout(lid)
        for rr in range(16):
            for cc in range(20):
                if 0x30 <= lay['tiles'][rr][cc] <= 0x33:
                    return lay['attr'][rr][cc], lay['tiles'][rr][cc]
        return 0, 0x33

    def code(lid, value, pal, row0=1):
        """The value's bits as wall blocks on rows row0..row0+2, columns 1-8."""
        for b in range(24):
            if (value >> b) & 1:
                paint(lid, 1 + b % 8, row0 + b // 8, WALL, pal)

    def hall(name, n, theme):
        rid = d.new_room(name, 0, r, gate_theme=theme)
        room = d.room(rid)
        lid0 = room['screens']['0']['layout']['id']
        pal, floor = floor_pal(lid0)
        lids = {}
        for k in KEYS:
            if k == 0:
                lid = lid0
            else:
                lid = d.unique_layout_id(f'{rid}_s{k}')
                d.add_layout(lid, tiles=d.blank_grid(floor), attr=d.blank_grid(pal))
                d.add_screen(room, str(k), {'id': lid})
            c, rr = k % 4, k // 4
            for cx in range(10):
                if rr == 0:
                    paint(lid, cx, 0, WALL, pal)
                if rr == 1:
                    paint(lid, cx, 7, WALL, pal)
            for cy in range(8):
                if c == 0:
                    paint(lid, 0, cy, WALL, pal)
                if c == 2:
                    paint(lid, 9, cy, WALL, pal)
            code(lid, n * 16 + k + 1, pal)
            lids[k] = lid
        return rid, room, lids, pal

    t0 = time.perf_counter()
    info = {'calm': {}, 'lit': {}}
    for n in range(1, CALM + 1):
        rid, room, _l, _p = hall(calm_name(n), n, (n - 1) % 16)
        d.add_npc(room, '0', 0, *GUIDE, 0x0B, 'down')
        d.set_room_area(rid, 'Calm halls')
        info['calm'][n] = rid
    d.add_flag(LIT_FLAG, 'S146 acceptance: the lit halls show state 1 while set')
    full_at = None
    for n in range(1, LIT + 1):
        before = d.full_counter_groups()
        rid, room, lids, pal = hall(lit_name(n), 300 + n, (n + 7) % 16)
        d.add_npc(room, '0', 0, *GUIDE, 0x0B, 'down')
        for k in KEYS:
            _i, nl = d.add_state(room, str(k), copy_from=0, own_layout=True)
            for cx in range(1, 9):
                if cx != 5:
                    paint(nl, cx, 4, STAIRS, pal)        # state 1: a lit row
            d.add_npc(room, str(k), 1, *SECOND, 0x0C, 'down')
        d.set_state_rules(room, [{'state': 1, 'when': [{'flag': LIT_FLAG}]}])
        d.set_room_area(rid, 'Lit halls')
        info['lit'][n] = rid
        if before and full_at is None:
            full_at = n
    # the switch hall: a lever (writes a two-state screen's counter) and a tester (tests a
    # one-state screen's counter) — both keep a byte of their own
    rid, room, lids, pal = hall('SWITCH HALL', 999, 3)
    room['screens']['0']['step_counter'] = {'label': LEVER_LABEL}
    room['screens']['1']['step_counter'] = {'label': TEST_LABEL}
    _i, nl = d.add_state(room, '0', copy_from=0, own_layout=True)
    for cx in range(1, 9):
        if cx != 5:
            paint(nl, cx, 4, STAIRS, pal)
    for nm in (FLAG_ZERO, FLAG_NONZERO, FLAG_LEVER):
        d.add_flag(nm, 'S146 acceptance (the switch hall)')
    num = {k: f'0x{v:04X}' for k, v in d.flag_numbers().items()}   # raw ops take numbers
    scripts = d.custom.setdefault('scripts', [])
    scripts.append({'id': 'switch_lever', 'ops': [
        ['op', 'write_ram', LEVER_LABEL, '0x0001'], ['op', 'set_flag', num[FLAG_LEVER]], ['end']]})
    scripts.append({'id': 'switch_test', 'ops': [
        ['op', 'check_and_branch', TEST_LABEL, '0x0000', '@zero'],
        ['op', 'set_flag', num[FLAG_NONZERO]], ['end'],
        'label:zero', ['op', 'set_flag', num[FLAG_ZERO]], ['end']]})
    tbl = room.setdefault('scripts', {})
    if '0' not in tbl:
        scripts.append({'id': 'switch_entry', 'ops': [['end']]})
        tbl['0'] = 'switch_entry'
    tbl['1'], tbl['2'] = 'switch_lever', 'switch_test'
    d.add_npc(room, '0', 0, *GUIDE, 0x0B, 'down', script='switch_lever')
    d.add_npc(room, '1', 0, *GUIDE, 0x0C, 'down', script='switch_test')
    d.set_room_area(rid, 'Switch')
    info['switch'] = rid
    d.save()
    t_make = time.perf_counter() - t0
    use = d.counter_use()
    print(f'{CALM} calm + {LIT} lit halls + the switch hall made: {t_make:.1f} s; the editor\'s '
          f'counter use per group {use}; group full from lit hall {full_at} '
          f'({int(STEP_GROUP_FULL * 100)} % of 640)')
    # ---- the compiler's view
    prj = Project.load(out)
    prj.repo_root = REPO
    alloc = prj.step_counter_allocation()
    overlay, base = prj.step_counter_overlay()
    shared, zero = prj.step_counter_shared()
    print(f'compiler: {len(alloc)} counter bytes in region 0\'s layout (+ {len(overlay)} other-region '
          f'EQUs), {len(shared)} one-state screens share ${zero:04X}; regional base ${base:04X}; '
          f'use {prj.step_counter_use()}')
    rep = CAP.measure(d.data, out, REPO)
    for x in rep['rows']:
        if x['key'] in ('rooms', 'screens_group', 'screens_room'):
            print(f"   {x['what'][:70]:70} {x['shown']}  {x['where']}")
    print(f'   capacity errors: {rep["errors"][:2]}')
    # ---- build (the editor's Build: compile, write, build_rom, manifest)
    t0 = time.perf_counter()
    bout = os.path.join(out, 'build')
    outputs, prj2, warnings = C.compile_project(os.path.join(out, 'project.json'), REPO)
    C.write_outputs(outputs, bout)
    rom, sym, md5 = B.build_rom(REPO, bout, os.path.join(bout, 'build'))
    B.write_manifest(os.path.join(bout, 'build'), prj2, os.path.join(out, 'project.json'),
                     rom, sym, md5, warnings)
    print(f'built in {time.perf_counter() - t0:.0f} s: {rom} md5 {md5}')
    rooms = {}
    for kind in ('calm', 'lit'):
        rooms[kind] = {str(n): {'id': rid, 'mid': d.room(rid)['mapID']}
                       for n, rid in info[kind].items()}
    rooms['switch'] = {'id': info['switch'], 'mid': d.room(info['switch'])['mapID']}
    regs = {}
    for n, v in rooms['lit'].items():
        regs.setdefault(F.mid_region(int(v['mid'], 16)), []).append(int(n))
    print('lit halls by group: ' + ', '.join(f'region {g}: {min(v)}-{max(v)} ({len(v)})'
                                              for g, v in sorted(regs.items())))
    json.dump({'rooms': rooms, 'rom': rom, 'md5': md5, 'full_at': full_at,
               'use': {str(k): v for k, v in use.items()}},
              open(os.path.join(out, 'acceptance.json'), 'w'), indent=1)


# ============================================================== walk
def walk(out, sav, keep, negative, only):
    from tools.walk_regions import Walk, s_continue
    from tools.census_stream_banks import bg_tiles, sprite_tiles, _pad144
    from tools.pyboy_harness import adv, tap, SCREEN_IDX
    from editor2.core.document import Document
    from editor2.core.render_project import ProjectRenderer
    from editor2.core.project import Project, STEP_ZERO_LABEL
    from editor2.core import formats as F
    from editor2.core import cutscenes as CS
    info = json.load(open(os.path.join(out, 'acceptance.json')))
    os.makedirs(keep, exist_ok=True)
    build = os.path.join(out, 'build', 'build')
    man = json.load(open(os.path.join(build, 'manifest.json')))
    ctr = {k: int(v.lstrip('$'), 16) for k, v in man['step_counters'].items()}
    w = Walk(build, sav, keep)
    zero = w.sym[STEP_ZERO_LABEL][1]
    doc = Document(os.path.join(out, 'project.json'))
    ren = ProjectRenderer(REPO, out, doc.data, rom_path=ROM)
    prj = Project(json.load(open(os.path.join(out, 'project.json'))), out)
    prj.repo_root = REPO
    flags = prj.flag_map()
    R = info['rooms']

    def where_of(v):
        m = int(v['mid'], 16)
        return F.mid_real(m), F.mid_region(m)

    def set_flag(name, on):
        f = flags[name]
        if f >= 0x1000:
            a, b = 0xD140 + ((f - 0x1000) >> 3), 7 - ((f - 0x1000) & 7)
        else:
            a, b = 0xD99B + (f >> 3), 7 - (f & 7)
        w.m[a] = (w.m[a] | (1 << b)) if on else (w.m[a] & ~(1 << b) & 0xFF)

    def flag(name):
        f = flags[name]
        if f >= 0x1000:
            return w.ext_flag(f)
        return (w.m[0xD99B + (f >> 3)] >> (7 - (f & 7))) & 1

    def into(v, k, x=None, y=None):
        mid, reg = where_of(v)
        c, rr = k % 4, k // 4
        w.goto(mid, reg, 10 * c + 5 if x is None else x, 8 * rr + 5 if y is None else y)
        return mid, reg

    def picture(room, k, state):
        img = w.p.screen.image.copy()
        prev = ren.render_screen(room, str(k), state_idx=state)
        g = bg_tiles(img)
        e = bg_tiles(prev.crop((0, 0, 160, 144)) if prev.height >= 144 else _pad144(prev))
        cov = sprite_tiles(w.p)
        diff = [(tx, ty) for ty in range(16) for tx in range(20)
                if (tx, ty) not in cov and g[(tx, ty)] != e[(tx, ty)]]
        return diff, 320 - len([c for c in cov if c[1] < 16])

    def npcs_loaded():
        """bank $0B's copy wCustomNPCBuffer ($CC80): 5-byte entries until a TYPE byte $FF."""
        n, a = 0, 0xCC80
        for _ in range(24):                       # bounded: a garbage list has no $FF
            if w.m[a] == 0xFF:
                return n
            n += w.m[a] < 0x80
            a += 5
        return -1

    def screen_check(kind, n, v, k, state, expect_fail=False):
        room = doc.room(v['id'])
        mid, reg = into(v, k)
        got = (w.m[0xC968], w.m[0xD536], w.m[SCREEN_IDX])
        diff, seen = picture(room, k, state)
        lbl = prj._def_step_label(room, k) if 'step_counter' not in room['screens'][str(k)] \
            or not isinstance(room['screens'][str(k)]['step_counter'], dict) \
            else room['screens'][str(k)]['step_counter']['label']
        a = ctr.get(lbl)
        want_npcs = len(doc.npc_entries(room, str(k), state))
        have = npcs_loaded()
        cv = w.m[a] if a is not None else None
        ok = (got == (mid, reg, k) and not diff and seen > 200 and cv == state
              and have == want_npcs and w.m[zero] == 0)
        if expect_fail:
            ok = not ok
        if not ok:
            w.snap(f'{kind}{n}_s{k}_st{state}')
        w.check(f'{kind} {n} screen {k} state {state}: map ${mid:02X} r{reg} s{k}, picture, '
                f'{want_npcs} NPC(s), counter {lbl} @ ${a or 0:04X} = {state}, zero byte 0'
                + (' (must FAIL: zero byte poked)' if expect_fail else ''), ok,
                f'at ${got[0]:02X} r{got[1]} s{got[2]}; {len(diff)}/{seen} tiles differ; '
                f'NPCs {have}; counter {cv}; zero {w.m[zero]}')
        return ok

    s_continue(w)
    w.save('base')
    steps = (only or 'calm,lit,switch,cross,journal,playhere').split(',')
    calm, lit = R['calm'], R['lit']
    if negative:
        # the zero byte non-zero makes a one-state screen read past its only state: the game
        # reads garbage and may HANG the emulator (measured S146: map / mode bytes trashed, then
        # PyBoy's tick never returns) — so each case runs in its own process with a time limit;
        # the same case without the poke must PASS (the harness is not what fails)
        import subprocess
        print('NEGATIVE CONTROL: the shared zero byte poked to 1 before entering calm halls 1, 64 '
              'and 128 — each must FAIL or hang; the same entry without the poke must pass')
        for n in ('1', '64', '128'):
            for poke in (False, True):
                cmd = [sys.executable, '-u', os.path.abspath(__file__), 'walk', '--out', out,
                       '--sav', sav, '--keep', os.path.join(keep, f'case{n}{"p" if poke else ""}'),
                       '--only', f'one:{n}:{"poke" if poke else "plain"}']
                try:
                    r = subprocess.run(cmd, capture_output=True, text=True, timeout=240)
                    res, tail = r.returncode, (r.stdout.strip().splitlines() or [''])[-2]
                except subprocess.TimeoutExpired:
                    res, tail = 'hung', 'no answer in 240 s'
                w.check(f'calm hall {n} screen 0 ' + ('with the zero byte poked to 1: FAILS / hangs'
                                                      if poke else 'without the poke: passes'),
                        (res != 0) if poke else (res == 0), f'{res}: {tail[:160]}')
        steps = []
    for st in steps:
        if st.startswith('one:'):
            _o, n, how = st.split(':')
            into(calm[n], 1)                          # the hall's other screen first
            if how == 'poke':
                w.m[zero] = 1
            screen_check('calm', n, calm[n], 0, 0)
    if 'calm' in steps:
        print(f'calm: every screen of the {CALM} calm halls (one state, the shared zero byte)')
        for n in sorted(calm, key=int):
            for k in KEYS:
                screen_check('calm', n, calm[n], k, 0)
    if 'lit' in steps:
        print(f'lit: every screen of the {LIT} lit halls — flag clear (state 0), then set (state 1)')
        for state in (0, 1):
            set_flag(LIT_FLAG, state)
            for n in sorted(lit, key=int):
                for k in KEYS:
                    screen_check('lit', n, lit[n], k, state)
        set_flag(LIT_FLAG, 0)
    if 'switch' in steps:
        print('switch: the tester tests its one-state screen\'s own byte; the lever writes a '
              'two-state screen\'s counter')
        sw = R['switch']
        room = doc.room(sw['id'])
        w.check(f'the tester\'s counter {TEST_LABEL} has a byte of its own (not the zero byte)',
                ctr.get(TEST_LABEL) not in (None, zero), f'${ctr.get(TEST_LABEL, 0):04X}')
        w.check(f'the lever\'s counter {LEVER_LABEL} has a byte of its own',
                ctr.get(LEVER_LABEL) not in (None, zero), f'${ctr.get(LEVER_LABEL, 0):04X}')
        screen_check('switch', 'hall', sw, 1, 0)
        into(sw, 1, 10 + GUIDE[0], GUIDE[1] + 1)
        w.face('up')
        res = w.talk()
        w.idle()
        w.check(f'the tester: [{TEST_LABEL}] == 0 → flag {FLAG_ZERO} ({res})',
                flag(FLAG_ZERO) == 1 and flag(FLAG_NONZERO) == 0,
                f'zero {flag(FLAG_ZERO)} nonzero {flag(FLAG_NONZERO)}')
        # (harness trap, S146: the FIRST mailbox warp after a talk into another screen of the
        # SAME room leaves tile column 0 rows 2-9 stale — measured in calm and lit halls alike,
        # one-state or own counter; leave through another room first. PYBOY_DEBUGGING S146.)
        into(calm['1'], 0)
        screen_check('switch', 'hall', sw, 0, 0)
        into(sw, 0, GUIDE[0], GUIDE[1] + 1)
        w.face('up')
        res = w.talk()
        w.idle()
        w.check(f'the lever ran ({res}): flag {FLAG_LEVER}, [{LEVER_LABEL}] = 1, zero byte 0',
                flag(FLAG_LEVER) == 1 and w.m[ctr[LEVER_LABEL]] == 1 and w.m[zero] == 0,
                f'flag {flag(FLAG_LEVER)} counter {w.m[ctr[LEVER_LABEL]]} zero {w.m[zero]}')
        into(sw, 1)                                    # scroll away and back: the state stays
        screen_check('switch', 'hall', sw, 0, 1)
    if 'cross' in steps:
        print('cross: between the groups — region changes zero the regional counters, never '
              'the shared byte; the rule brings state 1 back')
        set_flag(LIT_FLAG, 1)
        last = max(lit, key=int)
        first2 = next(n for n in sorted(lit, key=int) if where_of(lit[n])[1] == 2)
        for kind, n, v, st in (('lit', '1', lit['1'], 1), ('calm', '5', calm['5'], 0),
                               ('lit', last, lit[last], 1), ('lit', '2', lit['2'], 1),
                               ('calm', '128', calm['128'], 0), ('lit', first2, lit[first2], 1)):
            screen_check(kind, n, v, 4, st)
        set_flag(LIT_FLAG, 0)
    if 'journal' in steps:
        last = max(lit, key=int)
        v = lit[last]
        mid, reg = where_of(v)
        print(f'journal: the flag set, save in lit hall {last} (region {reg}), CONTINUE → state 1')
        set_flag(LIT_FLAG, 1)
        into(v, 0, 5, 5)
        w.face('down')
        p = w.p
        b, a = w.sym['SaveGameState']
        saved = []
        p.hook_register(b, a, lambda _c: saved.append(1), None)
        tap(p, 'a', hold=3, wait=90)                  # the field menu
        tap(p, 'down', hold=6, wait=20)
        tap(p, 'right', hold=6, wait=20)
        tap(p, 'a', hold=3, wait=60)                  # OPTN
        for _ in range(3):
            tap(p, 'down', hold=6, wait=20)
        tap(p, 'a', hold=3, wait=90)                  # JOURNAL
        tap(p, 'a', hold=3, wait=200)                 # YES
        for _ in range(10):
            if saved:
                break
            tap(p, 'a', hold=3, wait=60)
        adv(p, 300)
        w.check('the JOURNAL saved', bool(saved))
        p.hook_deregister(b, a)
        p.stop(save=True)
        ram = os.path.join(keep, 'journal.sav')
        shutil.copy(w.rom + '.ram', ram)
        w2 = Walk(build, ram, keep)
        w2.rom = w.rom
        s_continue(w2)
        w2.check_at(f'CONTINUE → lit hall {last}', mid, reg)
        room = doc.room(v['id'])
        a = ctr[prj._def_step_label(room, w2.m[SCREEN_IDX])]
        w2.check(f'… its screen in state 1 again (the counter is transient: the rule set it), '
                 f'zero byte 0', w2.m[a] == 1 and w2.m[zero] == 0,
                 f'counter {w2.m[a]} zero {w2.m[zero]}')
        w.checks += w2.checks
        w.fails += w2.fails
        w.p = w2.p
        w.m = w2.m
    if 'playhere' in steps:
        print('playhere: a room of the third group in a chosen state (the counter from the manifest)')
        last = max(lit, key=int)
        v = lit[last]
        room = doc.room(v['id'])
        lbl = prj._def_step_label(room, 0)
        rom = os.path.join(build, 'rom.gbc')
        old = CS.read_symbols(os.path.join(build, 'game.sym')).get(lbl)
        a = CS.counter_address(rom, lbl)
        w.check(f'Play here finds {lbl} (region {where_of(v)[1]}): ${a or 0:04X}; game.sym alone '
                f'(the S145 lookup) does not', a == ctr[lbl] and old is None, f'sym {old}')
        if w.p is not None:
            w.p.stop(save=False)
            w.p = None
        from editor2.core import playback as PB
        eng = PB.Engine(rom, cache_dir=os.path.join(keep, 'playback'), sav_path=sav, sound=False)
        eng.base_state()
        mid = int(v['mid'], 16)
        rec = CS.room_recipe(mid, 0, 5, 5, facing=0)
        rec = rec._replace(flags_clear=(flags[LIT_FLAG],))
        eng.start(rec, repoke=False, state_ram={a: 1})
        eng.tick(60)
        m = eng.m
        n, ad = 0, 0xCC80
        for _ in range(24):
            if m[ad] == 0xFF:
                break
            n += m[ad] < 0x80
            ad += 5
        want = len(doc.npc_entries(room, '0', 1))
        w.check(f'Play here starts lit hall {last} in state 1 with the flag clear: counter 1, '
                f'{want} NPCs', m[a] == 1 and n == want and (m[0xC968], m[0xD536]) == where_of(v),
                f'counter {m[a]} NPCs {n} at ${m[0xC968]:02X} r{m[0xD536]}')
        eng.p.stop(save=False)
    print(f'WALK: {"PASS" if not w.fails else "FAIL"}' + (f' {w.fails}' if w.fails else '')
          + f'  ({w.checks} checks)')
    if w.p is not None:
        w.p.stop(save=False)
    return w.fails == 0


# ============================================================== ab
def ab(old, new, sav, keep):
    """The same project built by the S145 code (`old`, a project dir with build/build) and the
    S146 code (`new`): every screen of every room entered on the user's save in both ROMs — the
    place, the game's picture (BG tiles as an image), bank $0B's NPC + exit buffers, the screen's
    counter (from each build's manifest) — must be identical; the new build's zero byte reads 0."""
    from tools.walk_regions import Walk, s_continue
    from tools.census_stream_banks import bg_tiles, sprite_tiles
    from tools.pyboy_harness import SCREEN_IDX
    from editor2.core.project import Project, STEP_ZERO_LABEL
    from editor2.core import formats as F
    prj = Project.load(new)
    rows = {}
    for tag, root in (('old', old), ('new', new)):
        build = os.path.join(root, 'build', 'build')
        man = json.load(open(os.path.join(build, 'manifest.json')))
        ctr = {k: int(v.lstrip('$'), 16) for k, v in man['step_counters'].items()}
        os.makedirs(os.path.join(keep, tag), exist_ok=True)
        w = Walk(build, sav, os.path.join(keep, tag))
        s_continue(w)
        zero = w.sym.get(STEP_ZERO_LABEL, (0, None))[1]
        for room in prj.rooms:
            mid = F.val(room['mapID'])
            for k, scr in sorted(prj.room_screens(room).items()):
                w.goto(F.mid_real(mid), F.mid_region(mid), 10 * (k % 4) + 5, 8 * (k // 4) + 5)
                cov = sprite_tiles(w.p)
                g = bg_tiles(w.p.screen.image.copy())
                pic = tuple(g[(x, y)] if (x, y) not in cov else None
                            for y in range(16) for x in range(20))
                lbl = prj.step_counter_label(room, k, scr)
                a = ctr.get(lbl)
                rows.setdefault((room['id'], k), {})[tag] = (
                    (w.m[0xC968], w.m[0xD536], w.m[SCREEN_IDX]), pic,
                    bytes(w.m[0xCC80 + i] for i in range(40)),
                    bytes(w.m[0xCD00 + i] for i in range(40)),
                    w.m[a] if a is not None else None,
                    w.m[zero] if zero is not None else 0)
        w.p.stop(save=False)
    fails = 0
    for (rid, k), v in rows.items():
        o, n = v['old'], v['new']
        same = o[:5] == n[:5] and n[5] == 0
        fails += not same
        what = [nm for i, nm in enumerate(('place', 'picture', 'NPC buffer', 'exit buffer',
                                           'counter')) if o[i] != n[i]]
        print(f"  {'ok  ' if same else 'FAIL'} {rid} screen {k}: place, picture, NPC + exit "
              f"buffers, counter {n[4]} — S145 build == S146 build"
              + (f'  [differs: {what}; zero {n[5]}]' if not same else ''))
    print(f'AB: {"PASS" if not fails else "FAIL"} ({len(rows)} screens)')
    return fails == 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', choices=('make', 'walk', 'ab'))
    ap.add_argument('--old', help='ab: the project built by the S145 code')
    ap.add_argument('--out', required=True)
    ap.add_argument('--sav')
    ap.add_argument('--keep')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--only')
    a = ap.parse_args()
    if a.what == 'make':
        make(os.path.abspath(a.out))
    elif a.what == 'ab':
        keep = a.keep or os.path.join(os.path.abspath(a.out), 'ab')
        sys.exit(0 if ab(os.path.abspath(a.old), os.path.abspath(a.out), a.sav, keep) else 1)
    else:
        keep = a.keep or os.path.join(os.path.abspath(a.out), 'walk')
        sys.exit(0 if walk(os.path.abspath(a.out), a.sav, keep, a.negative, a.only) else 1)


if __name__ == '__main__':
    main()
