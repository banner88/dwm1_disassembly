"""playback_server.py — the game for the Playback window, in its OWN process (S118).

Why a process: a scene set up from a synthetic state can crash the game (measured
S118: the Starry Shrine scene at step 20 jumped into VRAM with interrupts off), and
PyBoy then never returns from that frame — inside the editor that would freeze the
whole app. The editor talks to this server through pipes with a timeout
(PlaybackClient below); a hung game is killed and reported, the editor stays up.

    python3 -m editor2.core.playback_server        (started by PlaybackClient)

Protocol: the parent writes one JSON command per line on stdin; the server answers
each command with ONE message on stdout: 4-byte big-endian length + JSON header
line (utf-8, ends with \\n) + optional binary payload (the header says its size).
Commands:
  open   {rom, cache_dir, sav, sound}      -> {ok}
  start  {recipe: {...}, party}            -> {ok, log}
  run    {frames, buttons, opts}           -> {status} + payload: RGBA frame
                                              (160*144*4) + int16 stereo audio
  step   {script_type, script_idx, opts, back, reset, max_frames}
                                           -> {status, ran: [step pos …]} + RGBA frame
  record {recipe, party, script_type, script_idx, max_frames}
                                           -> {frames: {step pos: n bytes}, by: 'pos'}
                                              + PNGs (one per step, S118b)
  quit
"""

import io
import json
import os
import struct
import sys


def _send(header, payload=b''):
    head = (json.dumps(header) + '\n').encode('utf-8')
    out = sys.stdout.buffer
    out.write(struct.pack('>I', len(head) + len(payload)))
    out.write(head)
    out.write(payload)
    out.flush()


def _recipe(d):
    from .cutscenes import Recipe
    d = dict(d)
    d['player'] = tuple(d['player'])
    d['stands'] = [tuple(s) for s in d.get('stands') or []]
    d['ram'] = {int(k): v for k, v in (d.get('ram') or {}).items()}
    d['names'] = tuple(d.get('names') or ())
    d['stands'] = [tuple(x) for x in d.get('stands') or []]
    return Recipe(**{f: d.get(f) for f in Recipe._fields})


def serve():
    from . import playback as PB
    eng = None
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            cmd = json.loads(line)
        except ValueError:
            _send({'error': 'bad command'})
            continue
        c = cmd.get('cmd')
        try:
            if c == 'quit':
                break
            if c == 'open':
                eng = PB.Engine(cmd['rom'], cache_dir=cmd.get('cache_dir'),
                                sav_path=cmd.get('sav'), sound=bool(cmd.get('sound', True)))
                made = eng.base_state()
                _send({'ok': True, 'made_base': made})
            elif c == 'start':
                r = _recipe(cmd['recipe'])
                eng.start(r, party=bool(cmd.get('party')))
                eng._step_stack, eng._step_last = [], set()
                _send({'ok': True, 'log': list(eng.log)})
            elif c == 'run':
                o = cmd.get('opts') or {}
                eng.auto_text = o.get('auto_text', eng.auto_text)
                eng.text_pause = o.get('text_pause', eng.text_pause)
                eng.answer = o.get('answer', eng.answer)
                eng.auto_dpad = o.get('auto_dpad', eng.auto_dpad)
                eng.buttons = set(cmd.get('buttons') or [])
                n = max(0, int(cmd.get('frames', 1)))
                audio = []
                n_log = len(eng.log)
                for _ in range(n):
                    eng.frame()
                    if hasattr(eng, 'executed'):
                        del eng.executed[:]           # only Step reads the hook
                    if eng.sound and cmd.get('audio'):
                        audio.append(eng.audio().tobytes())
                w = eng.where()
                w.update(ended=eng.ended, reached=eng.reached, forced=eng.forced,
                         log=eng.log[n_log:])
                scr = eng.screen().tobytes()
                aud = b''.join(audio)
                _send({'status': w, 'frame': len(scr), 'audio': len(aud)}, scr + aud)
            elif c == 'step':
                # S118b (user: "I really would like to step through animation step
                # by step"): run until the scene's script dispatches its NEXT step
                # (the dispatch hook sees every step, also the ones that take no
                # time) and stop at the end of that frame; 'back' restores the
                # state before the last step.
                import io as _io
                if not hasattr(eng, 'executed'):
                    eng.trace_ops()
                stack = getattr(eng, '_step_stack', None)
                if stack is None:
                    stack = eng._step_stack = []
                if cmd.get('reset'):
                    stack.clear()
                    eng._step_last = set()
                ran, n = [], 0
                if cmd.get('back'):
                    if stack:
                        buf, eng._step_last, eng.frames = stack.pop()
                        buf.seek(0)
                        eng.p.load_state(buf)
                else:
                    o = cmd.get('opts') or {}
                    eng.auto_text = o.get('auto_text', eng.auto_text)
                    eng.text_pause = o.get('text_pause', eng.text_pause)
                    eng.answer = o.get('answer', eng.answer)
                    eng.auto_dpad = o.get('auto_dpad', eng.auto_dpad)
                    eng.buttons = set()
                    buf = _io.BytesIO()
                    eng.p.save_state(buf)
                    stack.append((buf, set(getattr(eng, '_step_last', set())), eng.frames))
                    del stack[:-400]
                    want = (cmd['script_type'] & 0xFF, cmd['script_idx'])
                    last = getattr(eng, '_step_last', set())
                    del eng.executed[:]
                    for n in range(1, int(cmd.get('max_frames', 3000)) + 1):
                        eng.frame()
                        here = [p_ for (t, sid, p_) in eng.executed if (t, sid) == want]
                        del eng.executed[:]
                        new = [p_ for p_ in here if p_ not in last]
                        if new:
                            ran = sorted(set(here))
                            eng._step_last = set(here)
                            break
                        last = set(here) or last      # a wait re-runs its own step
                        if eng.ended:
                            break
                w = eng.where()
                w.update(ended=eng.ended, reached=eng.reached, forced=eng.forced, log=[])
                scr = eng.screen().tobytes()
                _send({'status': w, 'frame': len(scr), 'audio': 0, 'ran': ran,
                       'frames_run': n, 'depth': len(stack)}, scr)
            elif c == 'record':
                r = _recipe(cmd['recipe'])
                want = (cmd['script_type'] & 0xFF, cmd['script_idx'])
                eng.text_pause = 6
                eng.auto_text = True
                frames, state = {}, {'last': None, 'img': None}
                if not hasattr(eng, 'executed'):
                    eng.trace_ops()

                def watch(e):
                    # S118b: one picture per STEP — the frame in which the game ran
                    # it (a wait / walk: the frame it finished), turns included
                    here = [p_ for (t, sid, p_) in e.executed if (t, sid) == want]
                    del e.executed[:]
                    if here:
                        img = e.screen().copy()
                        for p_ in here:
                            frames[p_] = img
                eng.watchers = [watch]
                try:
                    eng.start(r, party=bool(cmd.get('party')))
                    for _ in range(int(cmd.get('max_frames', 15000))):
                        eng.frame()
                        if eng.ended:
                            if not eng.reached and not eng.forced:
                                eng.force_scene()
                                continue
                            break
                finally:
                    eng.watchers = []
                from PIL import Image
                blobs, sizes = [], {}
                for ctr, arr in frames.items():
                    b = io.BytesIO()
                    Image.fromarray(arr[:, :, :3]).save(b, 'PNG')
                    blobs.append(b.getvalue())
                    sizes[str(ctr)] = len(blobs[-1])
                _send({'frames': sizes, 'order': list(sizes), 'by': 'pos',
                       'log': list(eng.log)},
                      b''.join(blobs))
            else:
                _send({'error': f'unknown command {c!r}'})
        except Exception as ex:                          # noqa: BLE001
            _send({'error': f'{type(ex).__name__}: {ex}'})
    if eng is not None:
        eng.stop()


# ------------------------------------------------------------------ client

class GameHung(RuntimeError):
    pass


class PlaybackClient:
    """The editor's handle on a playback server process. Every call waits at
    most `timeout` seconds for the answer; a game that stops answering is
    killed (GameHung)."""

    def __init__(self, repo_root, timeout=8.0):
        import queue
        import subprocess
        import threading
        self.timeout = timeout
        env = dict(os.environ)
        env['PYTHONPATH'] = repo_root + os.pathsep + env.get('PYTHONPATH', '')
        env.setdefault('PYTHONUNBUFFERED', '1')
        self.proc = subprocess.Popen([sys.executable, '-m', 'editor2.core.playback_server'],
                                     stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                     stderr=subprocess.DEVNULL, cwd=repo_root, env=env)
        self.q = queue.Queue()
        self.alive = True

        def reader(stream, q):
            try:
                while True:
                    n = stream.read(4)
                    if len(n) < 4:
                        break
                    size = struct.unpack('>I', n)[0]
                    data = b''
                    while len(data) < size:
                        chunk = stream.read(size - len(data))
                        if not chunk:
                            break
                        data += chunk
                    nl = data.index(b'\n')
                    q.put((json.loads(data[:nl].decode('utf-8')), data[nl + 1:]))
            except Exception:                            # noqa: BLE001
                pass
            q.put(None)
        self.t = threading.Thread(target=reader, args=(self.proc.stdout, self.q), daemon=True)
        self.t.start()

    def call(self, cmd, timeout=None):
        import queue
        if not self.alive:
            raise GameHung('the game process is not running')
        try:
            self.proc.stdin.write((json.dumps(cmd) + '\n').encode('utf-8'))
            self.proc.stdin.flush()
            msg = self.q.get(timeout=timeout or self.timeout)
        except (queue.Empty, BrokenPipeError, OSError):
            self.kill()
            raise GameHung('the game stopped answering (it crashed in this scene) — '
                           'it was stopped; the editor is fine')
        if msg is None:
            self.alive = False
            raise GameHung('the game process ended')
        head, payload = msg
        if head.get('error'):
            raise RuntimeError(head['error'])
        return head, payload

    def kill(self):
        self.alive = False
        try:
            self.proc.kill()
        except Exception:                                # noqa: BLE001
            pass

    def close(self):
        if self.alive:
            try:
                self.proc.stdin.write(b'{"cmd": "quit"}\n')
                self.proc.stdin.flush()
                self.proc.wait(timeout=3)
            except Exception:                            # noqa: BLE001
                self.kill()
        self.alive = False


def recipe_dict(r):
    d = r._asdict()
    d['player'] = list(d['player'])
    d['stands'] = [list(s) for s in d['stands'] or []]
    d['ram'] = {str(k): v for k, v in (d['ram'] or {}).items()}
    d['flags_set'] = list(d['flags_set'])
    d['flags_clear'] = list(d['flags_clear'])
    d['notes'] = list(d['notes'])
    d['names'] = list(d.get('names') or ())
    return d


if __name__ == '__main__':
    serve()
