"""talk.py — what an NPC / examine spot / step trigger DOES (S98).

A Document mixin (no Qt) over the `talk` script form (PROJECT_COMPILER
§2.14, lowered by project.Project._lower_talk_scripts): show text boxes,
optionally ask YES/NO, then set / clear flags and optionally move the
player (a warp — which reloads a room, so state rules re-pick its state
straight away). The GUI edits a SPEC:

    {'boxes': [[line, line], ...],          # the text (box 1 = "*:" line)
     'question': bool,                      # last box ends in YES/NO
     'then': BLOCK,                          # no question
     'yes': BLOCK, 'no': BLOCK}              # question
    BLOCK = {'boxes': [...] | [],            # optional reply text
             'set': [flag], 'clear': [flag],  # project flag names or numbers
             'move': None | {'dest': 'room:$6B'|'vanilla:$01', 'screen': k,
                             'x': cx, 'y': cy}}

A spec with no question and an empty `then` is written in the classic
[text][end] ops form (byte-identical to S97 talk scripts); anything more
becomes a `talk` script.
"""

import copy

EMPTY_BLOCK = {'boxes': [], 'set': [], 'clear': [], 'move': None}


def empty_block():
    return copy.deepcopy(EMPTY_BLOCK)


def block_is_empty(b):
    b = b or {}
    return not (b.get('boxes') or b.get('set') or b.get('clear') or b.get('move'))


class TalkMixin:
    # ----------------------------------------------------------- dialogue
    def _dlg_boxes(self, did):
        from editor2.core import textenc as T
        d = self.dialogue(did)
        try:
            b = T.entry_boxes(d)
        except T.TextError:
            b = None
        if b is None and 'lines' in d:
            ls = list(d['lines'])
            b = [ls[k:k + T.BOX_LINES] for k in range(0, len(ls), T.BOX_LINES)]
        elif b is None and 'text' in d:
            b = [[d['text']]]
        return b

    def script_dialogue_ids(self, sc):
        out = []
        for op in sc.get('ops') or []:
            if isinstance(op, list) and op and op[0] == 'text' and len(op) == 2 \
                    and isinstance(op[1], str):
                out.append(op[1])
        t = sc.get('talk') or {}
        if t.get('text'):
            out.append(t['text'])
        for part in ('then', 'yes', 'no'):
            b = t.get(part) or {}
            if b.get('text'):
                out.append(b['text'])
        return out

    def _dialogue_users(self):
        users = {}
        for s in self.custom.get('scripts', []):
            for did in self.script_dialogue_ids(s):
                users[did] = users.get(did, 0) + 1
        return users

    # ----------------------------------------------------------------- read
    def talk_spec(self, sid):
        """The GUI spec of a talk script, or None when the script does more
        than the talk form can express (edited as a script, P3.6/P3.8)."""
        try:
            sc = self.script(sid)
        except KeyError:
            return None
        spec = {'boxes': [], 'question': False, 'then': empty_block(),
                'yes': empty_block(), 'no': empty_block()}
        t = sc.get('talk')
        if t is None:
            boxes = self.talk_boxes(sid)
            if boxes is None:
                return None
            spec['boxes'] = boxes
            return spec
        try:
            spec['boxes'] = self._dlg_boxes(t['text']) or []
        except KeyError:
            return None
        spec['question'] = bool(t.get('question'))
        for part in ('then', 'yes', 'no'):
            b = t.get(part) or {}
            blk = empty_block()
            if b.get('text'):
                try:
                    blk['boxes'] = self._dlg_boxes(b['text']) or []
                except KeyError:
                    return None
            blk['set'] = list(b.get('set') or [])
            blk['clear'] = list(b.get('clear') or [])
            blk['move'] = copy.deepcopy(b.get('move')) if b.get('move') else None
            spec[part] = blk
        return spec

    @staticmethod
    def describe_talk(spec):
        """One-line summary for the panels."""
        if not spec:
            return ''
        def say(boxes):
            return ' ▸ '.join('"' + ' '.join(ln for ln in b if ln) + '"' for b in boxes)

        def acts(b):
            out = []
            out += [f'set {f}' for f in b.get('set') or []]
            out += [f'clear {f}' for f in b.get('clear') or []]
            if b.get('move'):
                m = b['move']
                out.append(f"move player to {m.get('dest')} screen {m.get('screen')} "
                           f"({m.get('x')},{m.get('y')})")
            return out
        s = say(spec.get('boxes') or [])
        if spec.get('question'):
            for part, name in (('yes', 'YES'), ('no', 'NO')):
                b = spec.get(part) or {}
                bits = ([say(b['boxes'])] if b.get('boxes') else []) + acts(b)
                s += f'   {name}: ' + ('; '.join(bits) if bits else 'nothing')
        else:
            a = acts(spec.get('then') or {})
            if a:
                s += '   then: ' + '; '.join(a)
        return s

    # ---------------------------------------------------------------- write
    def _new_dialogue(self, sid, suffix, boxes, choice=False):
        dlg = self.custom.setdefault('dialogue', [])
        did = self._unique_id(f'{sid}_{suffix}', {d.get('id') for d in dlg})
        e = {'id': did, 'boxes': [list(b) for b in boxes]}
        if choice:
            e['choice'] = True
        e['comment'] = f'{sid} {suffix} ({len(boxes)} box{"es" if len(boxes) != 1 else ""})'
        dlg.append(e)
        return did

    def _drop_script_dialogues(self, sc):
        """Remove dialogue entries only this script shows."""
        users = self._dialogue_users()
        dlg = self.custom.setdefault('dialogue', [])
        mine = set(self.script_dialogue_ids(sc))
        dlg[:] = [d for d in dlg if not (d.get('id') in mine and users.get(d.get('id')) == 1)]

    def _talk_payload(self, sid, spec):
        """-> ('ops', ops) or ('talk', talk dict), creating dialogue entries."""
        q = bool(spec.get('question'))
        if not spec.get('boxes'):
            raise ValueError('the talk needs some text')
        if not q and block_is_empty(spec.get('then')):
            return 'ops', [['text', self._new_dialogue(sid, 'text', spec['boxes'])], ['end']]
        t = {'text': self._new_dialogue(sid, 'text', spec['boxes'], choice=q),
             'question': q}

        def blk(part):
            b = spec.get(part) or {}
            out = {}
            if b.get('boxes'):
                out['text'] = self._new_dialogue(sid, part, b['boxes'])
            if b.get('set'):
                out['set'] = list(b['set'])
            if b.get('clear'):
                out['clear'] = list(b['clear'])
            if b.get('move'):
                m = b['move']
                out['move'] = {'dest': m['dest'], 'screen': int(m.get('screen', 0)),
                               'x': int(m['x']), 'y': int(m['y'])}
            return out
        if q:
            t['yes'] = blk('yes')
            t['no'] = blk('no')
        else:
            t['then'] = blk('then')
        return 'talk', t

    def new_talk(self, room, spec, name='talk'):
        """A new talk script for `room` (registered at the next free script
        index >= 1; index 0 = the room-entry script, created as a no-op when
        missing — KEY_LESSONS S2). Returns the script id."""
        scripts = self.custom.setdefault('scripts', [])
        sids = {s.get('id') for s in scripts}
        sid = self._unique_id(f"{room['id']}_{name}", sids)
        kind, payload = self._talk_payload(sid, spec)
        scripts.append({'id': sid, kind: payload})
        table = room.setdefault('scripts', {})
        if '0' not in table:
            eid = self._unique_id(f"{room['id']}_entry", sids | {sid})
            scripts.append({'id': eid, 'ops': [['end']]})
            table['0'] = eid
        idx = 1
        while str(idx) in table:
            idx += 1
        table[str(idx)] = sid
        self.touch()
        return sid

    def set_talk(self, sid, spec):
        """Rewrite a talk script from a spec (keeps the id, so every NPC /
        spot bound to it follows)."""
        if self.talk_spec(sid) is None:
            raise ValueError(f'script {sid!r} does more than talk — not editable here')
        sc = self.script(sid)
        self._drop_script_dialogues(sc)
        kind, payload = self._talk_payload(sid, spec)
        sc.pop('ops', None)
        sc.pop('talk', None)
        sc[kind] = payload
        self.touch()

    def flags_referenced(self):
        """Flags named by any talk script (for the flag pickers)."""
        out = []
        for s in self.custom.get('scripts', []):
            t = s.get('talk') or {}
            for part in ('then', 'yes', 'no'):
                for key in ('set', 'clear'):
                    for f in (t.get(part) or {}).get(key) or []:
                        if f not in out:
                            out.append(f)
        return out
