#!/usr/bin/env python3
"""census_cutscenes.py — play EVERY vanilla script scene in the real game and
check the editor's cutscene model against it (S118, ROADMAP P3.8 part A).

For each scene of editor2/core/cutscenes.Catalogue (every branch of every
vanilla room script that shows something) the Playback engine
(editor2/core/playback.Engine, PyBoy) sets the scene up from a new-game state
exactly as the Cutscenes tab's Playback window does — flags / RAM from the
path conditions, the room-entry script kept quiet, the warp, the trigger (room
entry / talk / examine / step-on) — and plays it with automatic text and D-pad
until the script ends. Recorded per scene:

  how      — how it started (entry on arrival, talk / examine / step-on from a
             side, armed directly) and whether the scene's own steps were
             REACHED or it had to be FORCED at its first step;
  ended    — the script ended (or changed room) within the frame budget;
  reset    — the game went back to its boot / title mode (wGameMode 0) during
             the scene: a crash-reset (S118c user report, the census had called
             it "ended");
  missing_npcs — NPCs a step acts on while their slot is EMPTY (a wrong room
             state; S118 user report: the wrong NPC acted);
  outcome  — 'battle' / 'menu': the scene handed over to a battle or a game
             screen (the player's part — the census does not fight or pick);
  stalled  — otherwise: the script counter stood still for 900 frames with
             nothing the script engine waits for (stall_at = [counter, the
             step, game mode $C88B]);
  model    — at every wait_movement / script end inside the scene, every
             actor's position, facing and shown flag in RAM vs the model
             (cutscenes.actor_frames from the RAM state at the scene's first
             step): checks / mismatches.

Every map is played in its own WORKER process (--worker): a scene set up from
a synthetic state can crash the game, and PyBoy then never returns from that
frame (measured S118). A worker that goes silent for --hang seconds is killed;
the scene it was on is recorded as `hung` and the map continues in a new
worker from the next scene.

Writes extracted/cutscene_census.json (the per-scene rows + totals). The
movement-program table (script_ops.PROGRAMS) is re-measured with --programs.

Usage:
  python3 tools/census_cutscenes.py [--rom data/DWM-original.gbc]
         [--maps 2F,01] [--max-frames 20000] [--out extracted/cutscene_census.json]
         [--jobs 2] [--hang 240]
  python3 tools/census_cutscenes.py --programs
  python3 tools/census_cutscenes.py --check      (verify the JSON's totals
                                                  shape; SKIP without PyBoy/ROM)
"""
import argparse
import json
import os
import sys
import tempfile
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)

OUT = os.path.join(ROOT, 'extracted', 'cutscene_census.json')
BATTLE_OPS = {0x05, 0x1F, 0x20, 0x36, 0x52, 0x5A, 0x5B}


def ram_actors(eng):
    """{n: (x, y, face, shown)} from RAM: 0 = the player, 1-8 the NPC slots."""
    m = eng.m
    out = {0: (m[0xFF92] | m[0xFF93] << 8, m[0xFF95] | m[0xFF96] << 8, m[0xFF8E],
               not (m[0xFF90] & 0x40))}
    for i in range(8):
        b = 0xD7D2 + 32 * i
        if m[b] == 0xFF:                       # an empty slot (type byte $FF; a big
            # sprite's extra parts keep sprite $FF in an OCCUPIED slot — S118)
            continue
        out[i + 1] = (m[b + 0x18] | m[b + 0x19] << 8, m[b + 0x1A] | m[b + 0x1B] << 8,
                      m[b + 6], not (m[b] & 0x40))
    return out


def queued_moves(eng, finish_step=False):
    """Walks still in the movement buffers ($D8E9 + 8n: active, -, program,
    actor, dx, dy) — the part of a batch not yet walked."""
    m, out = eng.m, {}
    for n in range(8):
        b = 0xD8E9 + 8 * n
        if m[b] and m[b + 2] == 0:
            dx = m[b + 4] | m[b + 5] << 8
            dy = m[b + 6] | m[b + 7] << 8
            out[m[b + 3] if n else 0] = [dx - 0x10000 if dx & 0x8000 else dx,
                                         dy - 0x10000 if dy & 0x8000 else dy]
    if m[0xD8D7] & 0x08:                    # a walk the script waits for ($0A/$0B/$10/$11)
        dx = m[0xD8DD] | m[0xD8DE] << 8
        dy = m[0xD8DF] | m[0xD8E0] << 8
        q = out.setdefault(m[0xD8DC], [0, 0])
        q[0] += dx - 0x10000 if dx & 0x8000 else dx
        q[1] += dy - 0x10000 if dy & 0x8000 else dy
    # S118e: the player's own step in progress (he walked in from the next
    # screen): the field engine finishes it to the cell centre (16·k + 8)
    x, y = m[0xFF92] | m[0xFF93] << 8, m[0xFF95] | m[0xFF96] << 8
    face = m[0xFF8E] & 3
    if finish_step and ((x - 8) % 16 or (y - 8) % 16):
        rx, ry = (x - 8) % 16, (y - 8) % 16
        dx = (16 - rx if face == 3 else -rx if face == 1 else 0) if rx else 0
        dy = (16 - ry if face == 0 else -ry if face == 2 else 0) if ry else 0
        if dx or dy:
            q = out.setdefault(0, [0, 0])
            q[0] += dx
            q[1] += dy
    return out


def running_programs(eng):
    """Actors running a movement program other than a walk (their remaining
    motion is not readable — excluded from the model check)."""
    m, out = eng.m, set()
    for n in range(8):
        b = 0xD8E9 + 8 * n
        if m[b] and m[b + 2]:
            out.add(m[b + 3] if n else 0)
    return out


class SceneWatch:
    """Per-frame observer of one scene (registered on the engine BEFORE the
    set-up, so a room-entry scene that starts on arrival is seen from its
    first step): reach, the model check after every wait, stalls."""

    def __init__(self, CS, SO, scene, r):
        self.CS, self.SO, self.scene, self.r = CS, SO, scene, r
        self.in_scene = {st.pos for st in scene.steps}
        self.waits = {st.pos for st in scene.steps
                      if st.code in (0x19, 0x100, 0x0A, 0x0B, 0x10, 0x11)}
        self.by_pos = {st.pos: k for k, st in enumerate(scene.steps)}
        self.model_at, self.live, self.pending = {}, False, None
        self.checks, self.bad, self.busy = 0, [], set()
        self.still, self.last_ctr, self.stalled = 0, None, False
        self.stall_at = None                   # [counter, step name, game mode $C88B]
        self.outcome = None                    # 'battle' / 'menu': handed to the player
        self.missing = []                      # NPCs the scene acts on whose slot is empty
        self.reached_at, self.terminal_at, self.f = None, 0, 0

    def __call__(self, eng):
        CS, SO, r = self.CS, self.SO, self.r
        self.f += 1
        w = eng.where()
        mine = (w['active'] and w['script'] == r.script_idx and w['type'] == (r.script_type & 0xFF))
        st = CS.step_at_counter(self.scene.script, w['pos']) if mine else None
        cur = st.pos if st is not None else None
        if st is not None and st.code in SO.TERMINAL:
            self.live, self.pending = False, None
            if not self.terminal_at:
                self.terminal_at = self.f
        ex = getattr(eng, 'executed', None)
        if ex:
            hit = [p for (t, sid, p) in ex
                   if t == (r.script_type & 0xFF) and sid == r.script_idx and p in self.in_scene]
            del ex[:]
            for p in hit:                      # an NPC acted on must be in its slot
                s2 = self.scene.script.steps.get(p)
                if s2 is not None and s2.code in CS.ACTOR_OPS and s2.params:
                    n = s2.params[0] & 0xFF
                    if n >= 1 and eng.m[0xD7D2 + 32 * (n - 1)] == 0xFF and \
                            n not in self.missing:
                        self.missing.append(n)
            if hit and self.reached_at is None and cur not in self.in_scene:
                self.reached_at = (self.f, hit[0])     # ran through it inside one tick
        if self.reached_at is None and cur in self.in_scene:
            self.reached_at = (self.f, cur)
            snap = ram_actors(eng)
            model0 = {n: CS.ActorState(x, y, fc, sh, None, '') for n, (x, y, fc, sh) in snap.items()}
            k = self.by_pos[cur]
            if self.scene.steps[k].code in (0x0A, 0x0B, 0x10, 0x11):
                k += 1
            self.busy = running_programs(eng)
            self.model_at = {s2.pos: acts for s2, acts in
                             CS.actor_frames(model0, self.scene.steps[k:],
                                             pending=queued_moves(
                                                 eng, finish_step=(r.action == 'walkin')))}
            self.live = True
        if self.pending is not None and cur != self.pending and self.live:
            acts = self.model_at.get(self.pending)
            if acts:
                snap = ram_actors(eng)
                for n, a in acts.items():
                    if n not in snap or n in self.busy:
                        continue
                    got = snap[n]
                    self.checks += 1
                    want = (a.x & 0xFFFF, a.y & 0xFFFF)
                    if (got[0], got[1]) != want:
                        self.bad.append({'pos': self.pending, 'actor': n, 'want': list(want),
                                         'got': [got[0], got[1]]})
            self.pending = None
        if cur in self.waits and self.live and cur != self.reached_at[1]:
            self.pending = cur
        if mine:
            if (w['pos'] == self.last_ctr and not w['dialog'] and not (eng.m[0xD8D7] & 0x5E)
                    and not (eng.m[0xD8D8] & 4) and eng.m[0xC850] == 0
                    and not (st is not None and st.code in CS.SELF_REPEAT)):
                self.still += 1
            else:
                self.still = 0
            self.last_ctr = w['pos']
            if self.still > 900 and not self.stalled and not self.outcome:
                kind = SO.OPS[st.code].kind if st is not None and st.code < 0x100 else None
                if kind in ('battle', 'screen'):
                    # the scene handed over to a battle / a menu screen: the
                    # player's part (the census does not fight or pick)
                    self.outcome = 'battle' if kind == 'battle' else 'menu'
                    return
                self.stalled = True
                self.stall_at = [w['pos'], SO.OPS[st.code].name if st is not None and
                                 st.code < 0x100 else (None if st is None else 'text'),
                                 eng.m[0xC88B]]


def play_scene(eng, CS, cat, mid, scene, max_frames):
    from editor2.core import script_ops as SO
    r = cat.recipe(scene, mid)
    party = any(st.code in BATTLE_OPS for st in scene.steps)
    row = {'map': mid, 'script': scene.script.key[2], 'entry': scene.entry,
           'title': cat.title(scene), 'action': r.action, 'notes': list(r.notes)}
    watch = SceneWatch(CS, SO, scene, r)
    eng.watchers = [watch]
    import time as _t
    eng.deadline = _t.monotonic() + 150
    try:
        eng.start(r, party=party)
        for f in range(max_frames):
            eng.frame()
            if watch.stalled or watch.outcome or getattr(eng, 'reset', False):
                break
            if watch.terminal_at and watch.f - watch.terminal_at > 240:
                break
            if eng.ended:
                if watch.reached_at is None and not eng.forced:
                    eng.force_scene()
                    continue
                for _ in range(90):
                    eng.frame()
                break
    except Exception as ex:                            # noqa: BLE001
        row.update(error=f'{type(ex).__name__}: {ex}')
    finally:
        eng.watchers = []
        eng.deadline = None
    row.update(how=eng.log, reached=watch.reached_at is not None, forced=eng.forced,
               ended=eng.ended or bool(watch.terminal_at), stalled=watch.stalled,
               stall_at=watch.stall_at, outcome=watch.outcome, missing_npcs=watch.missing,
               reset=bool(getattr(eng, 'reset', False)),
               frames=eng.frames,
               model={'checks': watch.checks, 'mismatches': len(watch.bad),
                      'examples': watch.bad[:6]})
    return row


def measure_programs(rom_path, fly=False):
    """Re-measure the opcode-$1C movement programs (see script_ops.PROGRAMS);
    fly=True: the fly programs $15-$18 for every $D8E3 1-9 x $D8E4 0-5
    (script_ops.FLY)."""
    from editor2.core import playback as PB
    eng = PB.Engine(rom_path, cache_dir=os.path.join(tempfile.gettempdir(), 'dwm_census'),
                    sound=False)
    eng.base_state()
    m = eng.m
    eng._stop_scripts()
    m[0xC96D] = 0x01
    m[0xC96E] = 0
    m[0xC96F], m[0xC970], m[0xC971], m[0xC972] = 72, 0, 88, 0
    m[0xC96C] = 1
    m[0xC88F] = 1
    eng.tick(400)
    import io
    base = io.BytesIO()
    eng.p.save_state(base)
    res = {}
    runs = [(2, prog, 3, 3) for prog in range(0, 0x1A)] + \
        [(0, prog, 3, 3) for prog in (1, 3, 4, 6, 7, 0x1A)]
    if fly:
        runs = [(2, prog, e3, e4) for prog in range(0x15, 0x19) for e3 in range(1, 10)
                for e4 in range(0, 6)]
    for actor, prog, e3, e4 in runs:
        if True:
            base.seek(0)
            eng.p.load_state(base)
            m[0xD8E3], m[0xD8E4] = e3, e4
            b = 0xD8E9 + 8 * actor
            for k, v in enumerate([1, 0, prog, actor, 0, 0, 0, 0]):
                m[b + k] = v
            m[0xD8DB] = 250
            m[0xD8D7] = 0x15
            s0 = ram_actors(eng)[actor]
            n = 0
            for n in range(1, 500):
                eng.tick()
                if m[b] == 0:
                    break
            s1 = ram_actors(eng)[actor]
            res[f'{actor}_{prog:02X}' + (f'_{e3}_{e4}' if fly else '')] = {'dx': (s1[0] - s0[0] + 0x8000) % 0x10000 - 0x8000,
                                          'dy': (s1[1] - s0[1] + 0x8000) % 0x10000 - 0x8000,
                                          'frames': n, 'shown': s1[3]}
    eng.stop()
    return res


def _flag(row):
    if row.get('hung'):
        return 'HUNG (the game crashed)'
    if row.get('reset'):
        return 'RESET (the game went back to the title) ' + _flag({**row, 'reset': False})
    if row.get('missing_npcs'):
        return f"NPC {row['missing_npcs']} MISSING " + _flag({**row, 'missing_npcs': None})
    if row.get('outcome'):
        return (('REACHED' if row.get('reached') else 'not reached')
                + (' (forced)' if row.get('forced') else '') + f" → {row['outcome']}")
    return (('REACHED' if row.get('reached') else 'not reached')
            + (' (forced)' if row.get('forced') else '')
            + (f" STALL@{row['stall_at'][0]} {row['stall_at'][1]} mode {row['stall_at'][2]}"
               if row.get('stalled') and row.get('stall_at') else
               ' STALL' if row.get('stalled') else '')
            + ('' if row.get('ended') else ' (no end)'))


def worker(a, CS, PB, cat, rom):
    """--worker MAP --first K: play scenes K.. of one map; one JSON line per
    scene on stdout ('B k' before a scene starts, 'R {...}' after)."""
    mid = int(a.worker, 16)
    eng = PB.Engine(a.rom, cache_dir=os.path.join(tempfile.gettempdir(), 'dwm_census'),
                    sound=False, rom_bytes=rom)
    eng.trace_ops()
    for k, scene in enumerate(cat.scenes(mid)):
        if k < a.first:
            continue
        print(f'B {k}', flush=True)
        row = play_scene(eng, CS, cat, mid, scene, a.max_frames)
        print('R ' + json.dumps(row), flush=True)
    eng.stop()
    return 0


def run_map(a, cat, mid, log):
    """All scenes of one map through worker processes (restarted after a hang)."""
    import queue
    import subprocess
    import threading
    scenes = cat.scenes(mid)
    rows, k = [], 0
    while k < len(scenes):
        cmd = [sys.executable, os.path.abspath(__file__), '--rom', a.rom, '--worker',
               f'{mid:02X}', '--first', str(k), '--max-frames', str(a.max_frames)]
        pr = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                              text=True, cwd=ROOT)
        q = queue.Queue()

        def rd(stream=pr.stdout, q=q):
            for line in stream:
                q.put(line)
            q.put(None)
        threading.Thread(target=rd, daemon=True).start()
        cur, done_upto = None, k
        while True:
            try:
                line = q.get(timeout=a.hang)
            except queue.Empty:
                pr.kill()
                sc = scenes[cur if cur is not None else k]
                row = {'map': mid, 'script': sc.script.key[2], 'entry': sc.entry,
                       'title': cat.title(sc), 'hung': True, 'reached': False,
                       'forced': False, 'ended': False, 'stalled': False,
                       'error': f'the game stopped answering for {a.hang} s (crashed)',
                       'model': {'checks': 0, 'mismatches': 0, 'examples': []}}
                rows.append(row)
                log(row)
                k = (cur if cur is not None else k) + 1
                break
            if line is None:                      # worker finished (or died)
                pr.wait()
                if cur is not None and done_upto <= cur:
                    sc = scenes[cur]
                    row = {'map': mid, 'script': sc.script.key[2], 'entry': sc.entry,
                           'title': cat.title(sc), 'hung': True, 'reached': False,
                           'forced': False, 'ended': False, 'stalled': False,
                           'error': 'the game process died',
                           'model': {'checks': 0, 'mismatches': 0, 'examples': []}}
                    rows.append(row)
                    log(row)
                    k = cur + 1
                else:
                    k = len(scenes)
                break
            if line.startswith('B '):
                cur = int(line[2:])
            elif line.startswith('R '):
                row = json.loads(line[2:])
                rows.append(row)
                log(row)
                k = done_upto = cur + 1
    return rows


def run_workers(a, cat, maps):
    import threading
    from concurrent.futures import ThreadPoolExecutor
    lock = threading.Lock()

    def log(row):
        with lock:
            print(f"${row['map']:02X} scr{row['script']:<2} @{row['entry']:<5} "
                  f"{_flag(row):28} model {row.get('model', {}).get('mismatches', '-')}/"
                  f"{row.get('model', {}).get('checks', '-')}  {row['title'][:40]}",
                  flush=True)
    with ThreadPoolExecutor(max(1, a.jobs)) as ex:
        per = list(ex.map(lambda m: run_map(a, cat, m, log), maps))
    return [r for rs in per for r in rs]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', default=os.path.join(ROOT, 'data', 'DWM-original.gbc'))
    ap.add_argument('--maps', default='')
    ap.add_argument('--max-frames', type=int, default=20000)
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--programs', action='store_true')
    ap.add_argument('--fly', action='store_true',
                    help='measure the fly programs $15-$18 for each $D8E3 / $D8E4 (prints FLY)')
    ap.add_argument('--check', '--selftest', dest='check', action='store_true')
    ap.add_argument('--jobs', type=int, default=2)
    ap.add_argument('--hang', type=int, default=240,
                    help='seconds without an answer before a worker counts as hung')
    ap.add_argument('--worker', default=None, help=argparse.SUPPRESS)
    ap.add_argument('--first', type=int, default=0, help=argparse.SUPPRESS)
    a = ap.parse_args()
    if a.check:
        if not os.path.exists(a.out):
            print('SKIP: no census file')
            return 0
        d = json.load(open(a.out))
        rows = d.get('scenes', [])
        t = d.get('totals', {})
        ok = (t.get('scenes') == len(rows)
              and t.get('reached') == sum(1 for r in rows if r.get('reached')))
        if not ok:
            print('FAIL: cutscene_census.json totals do not match its rows')
            return 1
        if not os.path.exists(a.rom):
            print('OK: cutscene_census.json totals consistent (SKIP the scene list: no ROM)')
            return 0
        # the scene list the census played == the catalogue the editor shows now
        from editor2.core import cutscenes as CS
        cat = CS.Catalogue(open(a.rom, 'rb').read())
        now = {(m, s.script.key[2], s.entry) for m in cat.map_types() for s in cat.scenes(m)}
        then = {(r['map'], r['script'], r['entry']) for r in rows}
        if now != then:
            print(f'FAIL: the catalogue has {len(now - then)} scene(s) the census did not play '
                  f'and lost {len(then - now)} — re-run tools/census_cutscenes.py')
            return 1
        print(f'OK: cutscene_census.json totals consistent; {len(now)} scenes == the catalogue')
        return 0
    try:
        from editor2.core import cutscenes as CS, playback as PB
        PB.available()
        import pyboy  # noqa: F401
    except Exception as ex:                            # noqa: BLE001
        print(f'SKIP: {ex}')
        return 0
    if not os.path.exists(a.rom):
        print('SKIP: no ROM')
        return 0
    if a.fly:
        res = measure_programs(a.rom, fly=True)
        print('FLY = {')
        for key, v in sorted(res.items()):
            _a, prog, e3, e4 = key.split('_')
            print(f"    (0x{prog}, {e3}, {e4}): ({v['dx']}, {v['dy']}, {v['frames']}),")
        print('}')
        return 0
    if a.programs:
        from editor2.core import script_ops as SO
        res = measure_programs(a.rom)
        bad = 0
        for key, v in sorted(res.items()):
            actor, prog = key.split('_')
            pr = SO.program(int(prog, 16), int(actor))
            ok = (pr.dx, pr.dy) == (v['dx'], v['dy']) or pr.frames == 0 or v['frames'] >= 400
            bad += not ok
            print(f"actor {actor} program ${prog}: measured ({v['dx']:+d},{v['dy']:+d}) "
                  f"{v['frames']} frames; table ({pr.dx:+d},{pr.dy:+d}) {pr.name}"
                  + ('' if ok else '   <-- DIFFERS'))
        print('programs: OK' if not bad else f'programs: {bad} differ')
        return 1 if bad else 0
    rom = open(a.rom, 'rb').read()
    cat = CS.Catalogue(rom)
    if a.worker is not None:
        return worker(a, CS, PB, cat, rom)
    maps = [int(x, 16) for x in a.maps.split(',') if x] or cat.map_types()
    t0 = time.time()
    rows = run_workers(a, cat, maps)
    tot = {'scenes': len(rows),
           'reached': sum(1 for r in rows if r.get('reached')),
           'reached_unforced': sum(1 for r in rows if r.get('reached') and not r.get('forced')),
           'ended': sum(1 for r in rows if r.get('ended')),
           'stalled': sum(1 for r in rows if r.get('stalled')),
           'battle': sum(1 for r in rows if r.get('outcome') == 'battle'),
           'menu': sum(1 for r in rows if r.get('outcome') == 'menu'),
           'errors': sum(1 for r in rows if r.get('error')),
           'hung': sum(1 for r in rows if r.get('hung')),
           'missing_npcs': sum(1 for r in rows if r.get('missing_npcs')),
           'reset': sum(1 for r in rows if r.get('reset')),
           'model_checks': sum(r.get('model', {}).get('checks', 0) for r in rows),
           'model_mismatches': sum(r.get('model', {}).get('mismatches', 0) for r in rows),
           'seconds': round(time.time() - t0)}
    doc = {'_generator': 'tools/census_cutscenes.py (S118) — PyBoy, a new-game base state, '
                         'the original ROM (md5 1ca6579359f21d8e27b446f865bf6b83)',
           'totals': tot, 'scenes': rows}
    if not a.maps:
        with open(a.out, 'w') as f:
            json.dump(doc, f, indent=1)
            f.write('\n')
    print(json.dumps(tot))
    return 0


if __name__ == '__main__':
    sys.exit(main())
