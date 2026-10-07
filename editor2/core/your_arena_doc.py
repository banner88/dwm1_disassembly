"""your_arena_doc.py — the Arena tab's model of YOUR arena (ROADMAP P3.14e3, S128;
compiler: editor2/core/your_arena.py, PROJECT_COMPILER §2.41; EDITOR_DESIGN §5.2b
"Your arena (S128)").

custom.arena = the project's lobby + arena rooms (copies of the game's Arena Lobby
$06 and Arena Battle room $5D), where a lost match / a win puts you in the lobby,
the words the desk says, and per class: when it opens (flag terms), the flag a win
turns ON, the won words, where a win sends you; Starry Night likewise (+ "the game's
ending"). Every setter validates with the compiler's own code before it is kept.
"""
import copy

from editor2.core import your_arena as YA

THEN_LABELS = {'lobby': 'stay in the lobby', 'room': 'go to a room…',
               'hub': 'go to the hub (arrival reason "won an arena class")',
               'ending': "the game's ending (the original scene after the final)"}


class YourArenaMixin:
    # ------------------------------------------------------------ reading
    def your_arena(self):
        a = (self.data.get('custom') or {}).get('arena')
        return copy.deepcopy(a) if isinstance(a, dict) else None

    def arena_room_choices(self, source):
        """[(room id, name)] of the project's copies of map `source` ($06 / $5D)."""
        out = []
        for r in self.rooms:
            try:
                src = int(str(r.get('source_mapID')), 0)
            except (TypeError, ValueError):
                continue
            if src == source and not r.get('placeholder'):
                out.append((r['id'], self.room_name(r)))
        return out

    def your_arena_problems(self):
        """[sentence] — what the build would refuse or warn about (empty = fine)."""
        if self.your_arena() is None:
            return []
        prj = self._project(copy.deepcopy(self.data))
        if getattr(prj, 'arena_error', None):
            return [prj.arena_error]
        try:
            return YA.validate(prj)
        except YA.ArenaRoomError as ex:
            return [str(ex)]

    def your_arena_class(self, name):
        a = self.your_arena() or {}
        if name == 'StarryNight':
            return copy.deepcopy(a.get('starry'))
        return copy.deepcopy((a.get('classes') or {}).get(name) or {})

    # ------------------------------------------------------------ writing
    def _ya_write(self, mutate):
        data = copy.deepcopy(self.data)
        c = data.setdefault('custom', {})
        a = c.setdefault('arena', {})
        mutate(a)
        cls = a.get('classes')
        if isinstance(cls, dict):
            for k in list(cls):
                if not cls[k]:
                    cls.pop(k)
            if not cls:
                a.pop('classes')
        if isinstance(a.get('words'), dict) and not a['words']:
            a.pop('words')
        prj = self._project(copy.deepcopy(data))
        if getattr(prj, 'arena_error', None):
            raise YA.ArenaRoomError(prj.arena_error)
        YA.resolve(prj)
        self._commit_data(data)

    def make_your_arena(self, repo_root, renderer):
        """Copies of the Arena Lobby and the Arena Battle room (Make editable, every
        state) + custom.arena naming them. -> (lobby id, arena id)."""
        if self.your_arena() is not None:
            raise YA.ArenaRoomError('the project already has an arena (Remove it first)')
        lobby = self.clone_vanilla(YA.LOBBY_SOURCE, 'Arena Lobby', repo_root, renderer)
        if renderer is not None:
            renderer.invalidate()
        arena = self.clone_vanilla(YA.BATTLE_SOURCE, 'Arena Battle', repo_root, renderer)
        if renderer is not None:
            renderer.invalidate()
        self.custom['arena'] = {'lobby': lobby, 'battle': arena}
        self.touch()
        return lobby, arena

    def set_your_arena_rooms(self, lobby, battle):
        def mut(a):
            a['lobby'] = lobby
            a['battle'] = battle
        self._ya_write(mut)

    def set_your_arena_return(self, screen, x, y):
        def mut(a):
            r = {'screen': int(screen), 'x': int(x), 'y': int(y)}
            if r == YA.RETURN_DEFAULT:
                a.pop('return', None)
            else:
                a['return'] = r
        self._ya_write(mut)

    def set_your_arena_words(self, key, text):
        """key lost / no (boxes or None = the game's) or locked (a string)."""
        if key not in YA.WORD_KEYS:
            raise YA.ArenaRoomError(f'words: {key!r}')

        def mut(a):
            w = a.setdefault('words', {})
            if text in (None, '', []):
                w.pop(key, None)
            else:
                w[key] = text if key == 'locked' else {'boxes': [list(b) for b in text]}
        self._ya_write(mut)

    def set_your_arena_class(self, name, spec):
        """name G..S or StarryNight; spec = {opens_when, won_flag, won_words (boxes),
        then, offer / yes / no (boxes, Starry)} — None / empty values are left out.
        For Starry Night spec None = the desk never offers it."""
        def clean(sp):
            out = {}
            for k, v in (sp or {}).items():
                if v in (None, '', [], {}):
                    continue
                if k in ('won_words', 'offer', 'yes', 'no') and isinstance(v, list):
                    v = {'boxes': [list(b) for b in v]}
                out[k] = v
            if out.get('then') == {'to': 'lobby'} and name != 'StarryNight':
                out.pop('then')
            return out

        def mut(a):
            if name == 'StarryNight':
                if spec is None:
                    a.pop('starry', None)
                else:
                    a['starry'] = clean(spec)
                return
            if name not in YA.CLASSES:
                raise YA.ArenaRoomError(f'class {name!r}')
            a.setdefault('classes', {})[name] = clean(spec)
        self._ya_write(mut)

    def remove_your_arena(self):
        """custom.arena goes (the two rooms stay, as ordinary copies)."""
        data = copy.deepcopy(self.data)
        (data.get('custom') or {}).pop('arena', None)
        self._commit_data(data)
