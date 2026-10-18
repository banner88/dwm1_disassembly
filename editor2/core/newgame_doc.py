"""newgame_doc.py — editing where a new game starts (S152, ROADMAP E3 a2).

Headless Document mixin (no Qt): `custom.new_game` (editor2/core/newgame.py,
PROJECT_COMPILER §2.60). The dialog (editor2/app/newgame_dialog.py) reads and
writes only through these.
"""

import copy

from editor2.core import newgame as NG


class NewGameMixin:
    def new_game(self):
        """The settings as the dialog shows them (defaults filled in)."""
        ng = copy.deepcopy(self.custom.get('new_game') or {})
        ng.setdefault('start', 'intro')
        ng.setdefault('story', 'untouched')
        return ng

    def set_new_game(self, start=None, at=None, story=None):
        """Change the start. start = 'intro' | 'room'; at = {room, screen, x, y,
        face}; story = 'untouched' | 'opening_done'. Keys not given stay. The game's
        own start (intro + untouched) removes custom.new_game (the room picked is
        kept while the start is a room only)."""
        ng = self.custom.setdefault('new_game', {})
        if start is not None:
            if start not in NG.STARTS:
                raise ValueError(f"start {start!r}: 'intro' or 'room'")
            ng['start'] = start
        if story is not None:
            if story not in NG.STORIES:
                raise ValueError(f"story {story!r}: 'untouched' or 'opening_done'")
            ng['story'] = story
        if at is not None:
            a = {'room': str(at['room']), 'screen': int(at.get('screen', 0)),
                 'x': int(at['x']), 'y': int(at['y']), 'face': at.get('face', 'down')}
            if a['face'] not in NG.FACES:
                raise ValueError(f"face {a['face']!r}: down / left / up / right")
            r = self.room(a['room'])                    # KeyError when no such room
            if str(a['screen']) not in (r.get('screens') or {}):
                raise ValueError(f"{r.get('name') or a['room']} has no screen {a['screen']}")
            ng['at'] = a
        if ng.get('start', 'intro') == 'intro' and ng.get('story', 'untouched') == 'untouched':
            self.custom.pop('new_game', None)
        self.touch()
        return self.new_game()

    def new_game_problem(self):
        """A sentence when the start cannot build, else None."""
        ng = self.custom.get('new_game') or {}
        try:
            at = NG.start_at(self.custom)
        except NG.NewGameError as ex:
            return str(ex)
        if at is not None:
            try:
                r = self.room(at[0])
            except KeyError:
                return f'the start room {at[0]!r} was deleted — pick another'
            if str(at[1]) not in (r.get('screens') or {}):
                return f'{r.get("name") or at[0]} has no screen {at[1]}'
        if (ng.get('start', 'intro') == 'intro' and ng.get('story') == 'opening_done'
                and not (self.custom.get('milly_hook') or {}).get('enabled')):
            return ("'the original opening as done' with the game's own intro needs the Milly "
                    'hook — start in one of your rooms, or tick the Milly hook')
        return None

    def new_game_start_room(self):
        """The room id the game starts in, or None (the intro)."""
        try:
            at = NG.start_at(self.custom)
        except NG.NewGameError:
            return None
        return at[0] if at else None
