#!/usr/bin/env python3
"""
census_battle_anims.py — S112 (ROADMAP P3.11e): every battle animation played
by the GAME'S OWN animation debugger and compared, frame by frame, with the
model in editor2/core/battle_anims.py (BATTLE_SKILL_SYSTEM §11, "as measured
S112"). The proof behind extracted/battle_animations.json schema 2.

THE INSTRUMENT. Game mode 5 is the developers' "Effect" debugger (ROM0 mode
tables $030F / $050F: init = bank $5F entry 8, per frame = entry 9; the
debug-menu name list above `GameModeDispatch`): row 0 picks an animation
number (wOPTN_and_Item_selection $C8DB, 0-$2C), A plays it — it loads the
tiles ($5F:$61EE, its own copy of the gfx table), the palette (bank $17
entries 13 + 8) and runs the same timeline + renderer as a battle, static at
the middle ($DD68 = 1, $DB54 = 1, X $50 / Y $60). Entered from a CONTINUE'd
save by writing wGameMode $C88A = 5, $C88B = 0 and bumping $C88E.

PER ANIMATION, every frame until the timeline ends (+ 8):
  * the sprites the builder wrote to the shadow OAM ($C000, [$cb] entries) ==
    the model's frame [$c8] (the frame drawn this frame) at (X, Y) = ($c3 + dx
    + 8, $c5 + dy + 16), tile + $c9, attr XOR $ca, cut at 40 — 'frames';
  * the shown-frame sequence ($DD66 per frame) == the timeline (frame f for
    hold + 1 frames; sounds take no time) — 'timing';
  * every PlaySoundEffect call (ROM0, hooked) == the timeline's sound cues, in
    order, at the step they belong to — 'sounds';
  * VRAM $8000-$87FF after the load == the decoded sheet; OBJ palette 0
    ($C7D7) == the animation's palette — 'tiles', 'palette'.
A deliberately wrong model (frames shifted by one) must FAIL (--negative).

USAGE
  python3 tools/census_battle_anims.py --rom <patched build>/rom.gbc --sav <a real .sav>
      [--only 0-44] [--negative] [--out extracted/battle_anim_census.json]
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.census_skill_present import continue_game, parse_sym  # noqa: E402

SEL, MENU, MODE = 0xC8DB, 0xC8DA, 0xC88A
START_LAGS = (4, 5)  # measured: the debugger draws nothing for 4 (5) frames after
                     # arming while the tiles + palette load; step 0 shows that longer


def enter_effect_debugger(p):
    m = p.memory
    m[MODE] = 5; m[0xC88B] = 0; m[0xC88E] = (m[0xC88E] + 1) & 0xFF
    for _ in range(120):
        p.tick()


def expect_frames(model, c):
    """[(frame, ticks)] and the sound ids in order, from the timeline."""
    seq, snd = [], []
    a = model['animations'][c] if c < len(model['animations']) else model['custom'][c]
    for s in a['timeline']:
        if 'frame' in s:
            seq.append((s['frame'], s['hold'] + 1))
        elif 'sound' in s:
            snd.append(s['sound'])
        else:
            seq.append(('op', s['op']))
    return seq, snd


def play(p, c, sym_play, frames_max=900):
    m = p.memory
    sounds = []

    def cb(_ctx):
        sounds.append((p.frame_count, p.register_file.A))
    p.hook_register(0, sym_play, cb, None)
    m[MENU] = 0; m[SEL] = c
    p.button_press('a')
    for _ in range(4):
        p.tick()
    p.button_release('a')
    log, started, ended = [], None, None
    for i in range(frames_max):
        pre = {'drawn': m[0xFFC8], 'x': m[0xFFC3], 'y': m[0xFFC5], 'tb': m[0xFFC9],
               'ab': m[0xFFCA], 'draw_on': m[0xDD60], 'pre_act': m[0xDD62]}
        p.tick()
        act = m[0xDD62]
        if started is None and act:
            started = i
        if started is not None:
            n = m[0xFFCB]
            oam = [[m[0xC000 + 4 * k + j] for j in range(4)] for k in range(n)]
            e = {'f': p.frame_count, 'act': act, 'step': m[0xDD65], 'shown': m[0xDD66], 'oam': oam}
            e.update(pre)              # the renderer draws with the HRAM it found
            log.append(e)
            if not act and ended is None:
                ended = i
            if ended is not None and i - ended > 8:
                break
    p.hook_deregister(0, sym_play)
    vram = bytes(m[0, 0x8000 + k] for k in range(0x800))
    pal = [m[0xC7D7 + 2 * k] | m[0xC7D8 + 2 * k] << 8 for k in range(32)]   # slots 0-7
    return log, sounds, vram, pal


def predict_oam(frame, x, y, tb, ab):
    out = []
    for dy, dx, t, at in frame[:40]:
        out.append([(y + dy + 16) & 0xFF, (x + dx + 8) & 0xFF, (t + tb) & 0xFF, at ^ ab])
    return out


def custom_model(project_dir):
    """The project's NEW animations ($2D+) in the census model's shape (compose)."""
    from editor2.core import battle_anims as BA
    prj = json.load(open(os.path.join(project_dir, 'project.json')))
    out = {}
    for k, a in enumerate(BA.custom_list(prj)):
        c = BA.compose(a)
        steps = []
        for x, y in c['timeline']:
            steps.append({'sound': y} if x == 0xFD else {'frame': x, 'hold': y})
        out[BA.FIRST_CUSTOM + k] = {
            'id': BA.FIRST_CUSTOM + k, 'frames': [[list(sp) for sp in fr] for fr in c['frames']],
            'timeline': steps,
            'tiles': {str(t): c['sheet'][16 * t:16 * t + 16].hex() for t in range(c['tiles'])},
            'palette': c['palettes'][0], 'palettes': c['palettes'], 'shade': 0xE4}
    return out


def check(model, c, log, sounds, vram, pal, negative=False):
    from dwm.sprite_codec import decode  # noqa: F401  (sheet compare uses model tiles)
    a = model['animations'][c] if c < len(model['animations']) else model['custom'][c]
    frames = a['frames']
    if negative:
        frames = frames[1:] + frames[:1]
    res = {'frames_checked': 0, 'frame_errors': 0, 'timing': 'ok', 'sounds': 'ok',
           'tiles': 'ok', 'palette': 'ok'}
    # the start lag: armed frames the host draws nothing while it loads the
    # tiles + palette (4, or 5 for the bigger sheets — measured); step 0 is shown
    # that much longer (timing below)
    lag = 0
    for e in log[1:]:
        if e['draw_on'] and not e['oam']:
            lag += 1
        else:
            break
    res['start_lag'] = lag
    for k, e in enumerate(log):
        if not e['draw_on'] or k <= lag or not e['pre_act']:
            continue                 # (the debugger calls the renderer only while the
                                     # sequencer runs: after the end nothing is drawn)
        want = predict_oam(frames[e['drawn']], e['x'], e['y'], e['tb'], e['ab'])
        res['frames_checked'] += 1
        if e['oam'] != want:
            res['frame_errors'] += 1
            res.setdefault('first_error', {'frame': e['drawn'], 'got': e['oam'][:4], 'want': want[:4]})
    # timing: run-length of the shown frame while active
    runs = []
    for e in log:
        if not e['act']:
            break
        if runs and runs[-1][0] == e['shown']:
            runs[-1][1] += 1
        else:
            runs.append([e['shown'], 1])
    seq, snd = expect_frames(model, c)
    if any(s[0] == 'op' for s in seq):
        res['timing'] = 'loop (op step; checked by frames only)'
    else:
        want = [[f, t] for f, t in seq]
        # merge equal consecutive frames in the expectation (a re-shown frame looks continuous)
        mw = []
        for f, t in want:
            if mw and mw[-1][0] == f:
                mw[-1][1] += t
            else:
                mw.append([f, t])
        got = [list(r) for r in runs]
        # the first frame's count includes the start frame — compare all but allow +-1 on the first
        if [r[0] for r in got] != [r[0] for r in mw] or any(
                (g[1] - w_[1] != lag if i == 0 else g[1] != w_[1])
                for i, (g, w_) in enumerate(zip(got, mw))):
            res['timing'] = {'got': got, 'want': mw}
    sids = [s for _f, s in sounds]
    if sids != snd:
        res['sounds'] = {'got': sids, 'want': snd}
    for t, h in a['tiles'].items():
        t = int(t)
        if vram[16 * t:16 * t + 16].hex() != h:
            res['tiles'] = f'tile {t} differs'
            break
    want_pal = [w for p_ in a.get('palettes', [a['palette']]) for w in p_]
    if pal[:len(want_pal)] != want_pal:
        res['palette'] = {'got': pal[:len(want_pal)], 'want': want_pal}
    if lag not in START_LAGS:
        res['timing'] = f'start lag {lag}'
    res['ok'] = (res['frame_errors'] == 0 and res['frames_checked'] > 0 and
                 res['timing'] in ('ok',) or str(res['timing']).startswith('loop')) and \
        res['sounds'] == 'ok' and res['tiles'] == 'ok' and res['palette'] == 'ok' and \
        res['frame_errors'] == 0 and res['frames_checked'] > 0
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--only', default='0-44')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--model', default=os.path.join(REPO, 'extracted', 'battle_animations.json'))
    ap.add_argument('--out', default=os.path.join(REPO, 'extracted', 'battle_anim_census.json'))
    ap.add_argument('--project', help='also check the project\'s NEW animations ($2D+; --only 45-..)')
    a = ap.parse_args()
    lo, hi = (int(x) for x in a.only.split('-'))
    model = json.load(open(a.model))
    model['custom'] = custom_model(a.project) if a.project else {}
    S = parse_sym(os.path.join(os.path.dirname(a.rom), 'game.sym'))
    play_addr = S['PlaySoundEffect'][1]
    p = continue_game(a.rom, a.sav)
    enter_effect_debugger(p)
    import io
    base = io.BytesIO(); p.save_state(base)
    out, bad = {}, 0
    for c in range(lo, hi + 1):
        base.seek(0); p.load_state(base)
        log, sounds, vram, pal = play(p, c, play_addr)
        r = check(model, c, log, sounds, vram, pal, a.negative)
        out[str(c)] = r
        bad += 0 if r['ok'] else 1
        print(f"${c:02X}: {'ok ' if r['ok'] else 'BAD'} frames {r['frames_checked']} "
              f"errors {r['frame_errors']} timing {r['timing'] if r['timing'] == 'ok' else '*'} "
              f"sounds {r['sounds'] if r['sounds'] == 'ok' else r['sounds']} tiles {r['tiles']} "
              f"palette {'ok' if r['palette'] == 'ok' else r['palette']}"
              + ('' if r['timing'] == 'ok' or str(r['timing']).startswith('loop') else f"\n   timing {r['timing']}")
              + (f"\n   first {r['first_error']}" if 'first_error' in r else ''), flush=True)
    if not a.negative:
        json.dump({'_generator': f'tools/census_battle_anims.py (S112) on {os.path.basename(a.rom)} '
                                 '+ a real .sav; the game\'s Effect debugger (mode 5), PyBoy',
                   'results': out}, open(a.out, 'w'), indent=1)
    print(f'{hi - lo + 1 - bad} ok, {bad} bad' + (' (NEGATIVE run: all should be bad)' if a.negative else ''))


if __name__ == '__main__':
    main()
