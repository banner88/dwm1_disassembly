#!/usr/bin/env python3
"""census_story_state.py — the story-point interpreter (editor2/core/story_state.py)
against the GAME running its own scripts (S132, ROADMAP P3.4 "Play here").

For each sampled story step, the game is started (PyBoy, the playback Engine on
the ORIGINAL ROM, a new game) with the interpreter's saved state BEFORE the step
poked in (flags + step counters + `$CAB4`), then the step itself is played by the
real scripts:

  a class   — `wColiseumBattle` ($D9CD) = $FE, `wArenaGroup` ($D9CE) = the class,
              warp into the Arena Lobby's screen 1: script 0 runs the victory
              cascade (text answered automatically);
  a gate    — warp into the boss room, `$D9E3` / `$D92B` as the boss script writes
              them right before its win tail, the boss script armed AT the tail
              (`win_tails` start); it plays on to the Castle and the King's speech.
  Starry Night (S144) — the game's own ENDING, every step played: the final's win
              tail (Arena Battle script 0, `wArenaGroup` 8, `wColiseumBattle` 3 —
              as the third match leaves it), the night Farm, the Farm NPC's talk
              (script 19, YES), the Starry Shrine / ceremony / white room, the
              bedroom (the dresser = script 10; the question, YES; the step-on
              trigger = script 13; the credits), "TO BE CONTINUED" → A + YES = the
              ending's only SAVE (hooked: ROM0 SaveGameState $2128) → the bedroom
              again as CONTINUE puts you there (screen 4), its screen 5, the dresser
              → the ceremony room → GreatTree → the Castle (the King's cascade).

When the field is idle again the saved bytes are read — every event flag $0000-
$02FF and the step counters $D92A-$D99A + `$CAB4` — and compared with the
interpreter's state AFTER the step: flags exactly, and every counter the step
changed in either. A mismatch is printed and saved.

Usage:
  census_story_state.py [--steps 0,1,2,…] [--out FILE]
  census_story_state.py --selftest   (verifier check 5: the saved census is clean
                                      and the interpreter still gives the saved
                                      states — no PyBoy needed)
Writes extracted/story_state_census.json.
"""
import argparse
import json
import os
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

OUT = os.path.join(REPO, 'extracted', 'story_state_census.json')
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
FLAG_BASE, N_FLAGS = 0xD99B, 0x300
RAM_LO, RAM_HI = 0xD92A, 0xD99A
EXTRA = (0xCAB4, 0xD9E3)
# the event flags proper: bytes $D99B-$D9CA and the script-referenced $D9E4-$D9E5;
# the other bytes of the bitfield are engine variables (EVENT_FLAGS "Free Flag
# Slots" audit — e.g. $D9CD wColiseumBattle = "flags" $0190-$0197, $D9E3 the
# King's speech = $0240-$0247), compared as RAM where the story touches them
REAL_FLAGS = set(range(0x0000, 0x0180)) | set(range(0x0248, 0x0258))
# the default sample: the first steps (intro speech, G), a pair gate, a mid
# class, the mandatory gates (Anger / Reflection); S144: + Starry Night (30, the
# ending played to the post-game) and the first post-game gate (31)
DEFAULT_STEPS = [0, 1, 2, 3, 5, 8, 12, 13, 18, 21, 24, 28, 29, 30, 31]


def game_state(m):
    flags = {i for i in sorted(REAL_FLAGS)
             if (m[FLAG_BASE + (i >> 3)] >> (7 - (i & 7))) & 1}
    ram = {a: m[a] for a in list(range(RAM_LO, RAM_HI + 1)) + list(EXTRA)}
    return flags, ram


def model(st):
    return set(f for f in st['flags_on'] if f in REAL_FLAGS), dict(st['ram'])


def compare(pre, post_model, game):
    """Flags exactly; counters: every byte the game or the model changed."""
    gf, gr = game
    mf, mr = post_model
    pf, pr = pre
    bad = []
    if gf != mf:
        bad.append({'flags_only_game': sorted(hex(f) for f in gf - mf),
                    'flags_only_model': sorted(hex(f) for f in mf - gf)})
    for a in sorted(set(gr)):
        before = pr.get(a, 0)
        g = gr[a]
        mv = mr.get(a, before)
        if g != mv:
            bad.append({'ram': hex(a), 'before': before, 'game': g, 'model': mv})
    return bad


def run_idle(eng, limit=12000):
    """Run until the field is idle for a while (texts answered by the engine)."""
    m = eng.m
    idle, frames = 0, 0
    eng.auto_text, eng.text_pause = True, 12
    while frames < limit:
        eng.frame()
        frames += 1
        busy = (m[0xD8D7] & 1) or m[0xC8EB] not in (0, 4) or m[0xC850] or m[0xC88A] != 1 \
            or m[0xC96C]
        idle = 0 if busy else idle + 1
        if idle > 240 and frames > 300:
            break
    return frames


def warp_back(eng, mp, sx, sy):
    """The exit mailbox (PYBOY_DEBUGGING "The warp hijack") into map mp at the
    boss arrival cell, in the running game."""
    from editor2.core import playback as PB
    m = eng.m
    eng._stop_scripts()
    px, py = sx * 16 + 8, sy * 16 + 8
    m[PB.W_DEST], m[PB.W_FLAG] = mp & 0xFF, 0
    m[PB.W_X], m[PB.W_X + 1] = px & 0xFF, px >> 8
    m[PB.W_Y], m[PB.W_Y + 1] = py & 0xFF, py >> 8
    m[PB.W_CHANGING] = 1
    m[PB.W_KICK] = 1
    for _ in range(900):
        eng.tick()
        if m[PB.MAP_ID] == mp and m[PB.GAME_MODE] == 1 and m[PB.W_KICK] == 0 \
                and m[PB.W_CHANGING] == 0:
            break
    run_idle(eng, 2000)


def arm_tail(eng, rom, g, bm, bank, start, code, flag):
    """Arm the boss script AT the win tail (as if the battle was just won)."""
    from editor2.core import story_state as SS
    from editor2.core import cutscenes as CS
    m = eng.m
    idx = pos = None
    for i in range(64):
        try:
            sc = CS.decode_vanilla(rom, bm, i)
        except Exception:                                        # noqa: BLE001
            break
        for st in sc.steps.values():
            if st.addr == start:
                idx, pos = i, st.pos
        if idx is not None:
            break
    if idx is None:
        # the decode from pos 0 does not reach it (the Medal Gate's KingSlime
        # room): the script whose start is the nearest below the tail —
        # a position is the word offset from the script's start
        ptrs = CS.vanilla_script_ptrs(rom, bm)
        cands = [(st0, i) for i, st0 in enumerate(ptrs) if st0 <= start]
        if cands:
            st0, idx = max(cands)
            pos = (start - st0) // 2
    if idx is None:
        return f'tail ${bank:02X}:{start:04X} not in a script of map ${bm:02X}'
    eng.set_flag(flag, True)                     # the boss script sets it before its tail
    # what the boss script writes right before its tail: $D9E3 = the speech,
    # $D92B = 7 (Beginning: script 1 pos 69 / 74). The room's ENTRY script
    # wrote $D92B = 6 on arrival (script 0 pos 0 — a WarpWing out of the
    # gate then gets the priest's heal at the Castle), measured + decoded S132
    m[SS.KING_CODE] = code if code is not None else 0
    m[SS.CASTLE_EVENT] = 7
    eng._arm(bm, idx, pos, dialog=True)
    return None


def run_step(eng, step, kind, n, gates, rom, log):
    from editor2.core import story_state as SS
    from editor2.core import cutscenes as CS
    pre_st = SS.state_at(step)
    post_st = SS.state_at(step + 1)
    pre = model(pre_st)
    ram = {a: v for a, v in pre_st['ram'].items()}
    if kind == 'class':
        ram.update({SS.COLISEUM: 0xFE, SS.ARENA_GROUP: n})
        rec = CS.room_recipe(SS.ARENA_LOBBY, 1, 4, 5)
    else:
        g = gates[n]
        wt = g['win_tails'][0]
        bank, start = int(wt['bank'], 16), int(wt['start'], 16)
        code = SS.king_code(rom, bank, start)
        ram.update({SS.KING_CODE: code if code is not None else 0, SS.CASTLE_EVENT: 7})
        bm = int(g['boss_map'], 16)
        sx, sy = g['boss_spawn']
        rec = CS.room_recipe(bm, 0, sx, sy)
    rec = rec._replace(flags_set=tuple(pre_st['flags_on']), flags_clear=(), ram=ram)
    eng.start(rec, repoke=False)
    m = eng.m
    base_flags = game_state(m)[0]
    if kind == 'gate':
        # every win tail of the gate in order (the Gate of Demolition: Hargon,
        # then Sidoh): the first from the start state, the next ones after a
        # warp back into the boss room in the same game
        for k, wt in enumerate(g['win_tails']):
            bank, start = int(wt['bank'], 16), int(wt['start'], 16)
            code = SS.king_code(rom, bank, start)
            if k:
                warp_back(eng, bm, sx, sy)
            err = arm_tail(eng, rom, g, bm, bank, start, code, int(wt['flag'], 16))
            if err:
                return {'step': step, 'error': err}
            if k + 1 < len(g['win_tails']):
                run_idle(eng)
    frames = run_idle(eng)
    game = game_state(m)
    # flags the base game had before the step that the model does not know
    # (a new game's own) count on both sides
    extra = base_flags - pre[0]
    post_m = model(post_st)
    bad = compare(pre, (post_m[0] | extra, post_m[1]), game)
    res = {'step': step, 'kind': kind, 'id': n, 'frames': frames, 'map': m[0xC968],
           'mismatches': bad}
    log(f"step {step:2d} {kind} {n}: {frames} frames, map ${m[0xC968]:02X}, "
        f"{'OK' if not bad else f'{len(bad)} MISMATCH(ES)'}")
    for b in bad:
        log(f'    {b}')
    return res


def _warp(eng, mp, x, y):
    from editor2.core import playback as PB
    m = eng.m
    eng._stop_scripts()
    px, py = x * 16 + 8, y * 16 + 8
    m[PB.W_DEST], m[PB.W_FLAG] = mp & 0xFF, 0
    m[PB.W_X], m[PB.W_X + 1] = px & 0xFF, px >> 8
    m[PB.W_Y], m[PB.W_Y + 1] = py & 0xFF, py >> 8
    m[PB.W_CHANGING] = 1
    m[PB.W_KICK] = 1
    for _ in range(900):
        eng.tick()
        if m[PB.MAP_ID] == mp and m[PB.W_KICK] == 0 and m[PB.W_CHANGING] == 0:
            break


def _run_frames(eng, n):
    for _ in range(n):
        eng.frame()


def run_starry(eng, step, log):
    """S144: the ending, played (module doc). Returns the run record."""
    from editor2.core import story_state as SS
    from editor2.core import cutscenes as CS
    pre_st, post_st = SS.state_at(step), SS.state_at(step + 1)
    pre = model(pre_st)
    ram = dict(pre_st['ram'])
    ram.update({SS.ARENA_GROUP: 8, SS.COLISEUM: 3})
    rec = CS.room_recipe(0x5D, 0, 4, 4)._replace(flags_set=tuple(pre_st['flags_on']),
                                                 flags_clear=(), ram=ram)
    eng.start(rec, repoke=False)
    m = eng.m
    base_flags = game_state(m)[0]
    eng.auto_text, eng.text_pause, eng.answer = True, 12, 'yes'
    saves = []
    eng.p.hook_register(0, 0x2128, lambda _c: saves.append(m[0xD974]), None)
    path = []

    def at(what):
        path.append(f'{what}: map ${m[0xC968]:02X} mode {m[0xC88A]}')
    _run_frames(eng, 9000)                              # the win tail, the night Farm
    at('night Farm')
    eng._arm(0x04, 19, 0, dialog=True)                  # the Farm NPC's talk, YES
    _run_frames(eng, 10000)
    at('the bedroom')
    eng._arm(0x2F, 10, 0, dialog=True)                  # the dresser
    _run_frames(eng, 2000)
    _warp(eng, 0x2F, 5, 12)                             # the bedroom again: the question
    _run_frames(eng, 3000)
    eng._arm(0x2F, 13, 0, dialog=True)                  # the step-on trigger: credits
    _run_frames(eng, 60000)
    at('TO BE CONTINUED')
    p = eng.p
    for i in range(400):                                # A + YES: the ending's save
        if i % 10 == 0:
            p.button_press('a')
        for _ in range(3):
            p.tick()
        if i % 10 == 0:
            p.button_release('a')
        for _ in range(12):
            p.tick()
        if saves:
            break
    at(f'saved {len(saves)}x')
    # a player resets here: the rest runs in a fresh game booted with that save
    import shutil
    from tools.pyboy_harness import boot_with_sav, adv, tap
    tmp = tempfile.mkdtemp(prefix='story_starry_')
    for _ in range(300):                                 # let the save finish
        eng.p.tick()
    sav = os.path.join(tmp, 'post.sav')
    open(sav, 'wb').write(bytes(eng.p.memory[0, 0xA000 + i] for i in range(0x2000)))
    rom2 = os.path.join(tmp, 'orig.gbc')
    shutil.copy(ROM, rom2)
    q = boot_with_sav(rom2, sav)
    m = q.memory
    adv(q, 400)
    tap(q, 'start')
    adv(q, 120)
    for _ in range(40):                                  # CONTINUE, its info box
        if m[0xC968] == 0x2F and m[0xC88A] == 1:
            break
        tap(q, 'a', hold=4, wait=60)
    path.append(f'CONTINUE: map ${m[0xC968]:02X} mode {m[0xC88A]}')

    def settle(n):
        for i in range(n):
            adv(q, 10)
            if m[0xC8EB] & 1 and i % 3 == 0:
                tap(q, 'a', hold=2, wait=2)
    settle(400)
    from tools.pyboy_harness import warp
    warp(q, 0x2F, 15, 12, settle=60)                     # the bedroom's other screen
    settle(400)
    warp(q, 0x2F, 18, 9, settle=200)                     # on the dresser (screen 5, 8, 1)
    for _ in range(3):
        tap(q, 'b', wait=20)
    tap(q, 'up', hold=6, wait=20)
    tap(q, 'a', hold=3, wait=10)
    settle(2500)
    path.append(f'post-game: map ${m[0xC968]:02X} mode {m[0xC88A]}')
    frames = 0
    game = game_state(m)
    extra = base_flags - pre[0]
    post_m = model(post_st)
    bad = compare(pre, (post_m[0] | extra, post_m[1]), game)
    if not saves:
        bad.append({'save': 'the ending did not save'})
    res = {'step': step, 'kind': 'starry', 'id': 8, 'frames': frames, 'map': m[0xC968],
           'path': path, 'mismatches': bad}
    q.stop(save=False)
    if os.environ.get('STORY_KEEP_SAV'):
        shutil.copy(sav, os.environ['STORY_KEEP_SAV'])
    shutil.rmtree(tmp, ignore_errors=True)
    log(f"step {step:2d} starry 8: {' → '.join(path)}; "
        f"{'OK' if not bad else f'{len(bad)} MISMATCH(ES)'}")
    for b in bad:
        log(f'    {b}')
    return res


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--steps', help='comma list of step indices (default: a sample)')
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args(argv)
    if a.selftest:
        return selftest()
    from editor2.core import playback as PB
    from editor2.core import story_state as SS
    from editor2.core.balance import VANILLA_STEPS
    steps = [int(x) for x in a.steps.split(',')] if a.steps else DEFAULT_STEPS
    rom = open(ROM, 'rb').read()
    gates = {g['id']: g for g in json.load(open(os.path.join(REPO, 'extracted',
                                                             'gate_names.json')))['gates']}
    cache = tempfile.mkdtemp(prefix='story_census_')
    eng = PB.Engine(ROM, cache_dir=cache, sound=False)
    out = []
    for s in steps:
        kind, n = VANILLA_STEPS[s]
        if kind == 'starry':
            out.append(run_starry(eng, s, print))
            continue
        if kind not in ('gate', 'class'):
            print(f'step {s}: {kind} — not played by this census (skipped)')
            continue
        out.append(run_step(eng, s, kind, n, gates, rom, print))
    states = {str(s): SS.state_at(s) for s in range(len(VANILLA_STEPS) + 1)}
    for v in states.values():
        v.pop('log', None)
        v['ram'] = {f'0x{a:04X}': b for a, b in sorted(v['ram'].items())}
    doc = {'_generator': 'tools/census_story_state.py (S132; S144: + the ending) on data/DWM-original.gbc '
                         '(md5 1ca6579359f21d8e27b446f865bf6b83)',
           'note': 'PyBoy runs of the game\'s own victory cascades / boss win tails vs '
                   'editor2/core/story_state.py; states = the interpreter per step',
           'runs': out,
           'clean': all(not r.get('mismatches') and not r.get('error') for r in out),
           'states': states}
    with open(a.out, 'w') as f:
        json.dump(doc, f, indent=1)
    print(f"{len(out)} steps run, {'all equal' if doc['clean'] else 'MISMATCHES'} -> {a.out}")
    return 0 if doc['clean'] else 1


def selftest():
    from editor2.core import story_state as SS
    if not os.path.exists(ROM):
        print('SKIP: no ROM')
        return 0
    doc = json.load(open(OUT))
    if not doc.get('clean'):
        print('FAIL: the saved census has mismatches')
        return 1
    for k, v in doc['states'].items():
        st = SS.state_at(int(k))
        ram = {f'0x{a:04X}': b for a, b in sorted(st['ram'].items())}
        if st['flags_on'] != v['flags_on'] or ram != v['ram']:
            print(f'FAIL: the interpreter no longer gives the saved state of step {k}')
            return 1
    print(f"OK: story_state census clean ({len(doc['runs'])} PyBoy runs), "
          f"{len(doc['states'])} story states re-derived equal")
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
