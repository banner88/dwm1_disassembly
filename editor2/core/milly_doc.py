"""milly_doc.py — editing the Milly hook (S121, ROADMAP P3.16 + E7).

Headless Document mixin (no Qt): the hook's settings live in
`custom.milly_hook` (PROJECT_COMPILER §2.34, editor2/core/milly.py); the
"Roots room (Milly)" is an ordinary custom room — a copy of the game's tree-root
chamber (map $08, where Terry spins in after his dresser) with grey Warubou in
place of the old man and an editable scene.
"""

import copy

from editor2.core import milly as MH
from editor2.core.formats import val


class MillyMixin:
    def milly_hook(self):
        """The hook's settings (a copy; {} = never set)."""
        return copy.deepcopy(self.custom.get('milly_hook') or {})

    def set_milly_hook(self, enabled=None, arrive=None, spin=None):
        """Change the hook. arrive = {room, screen, x, y, face}. Keys not given
        stay as they are. Turning it off keeps the arrival (tick it back on)."""
        h = self.custom.setdefault('milly_hook', {})
        if enabled is not None:
            h['enabled'] = bool(enabled)
        if arrive is not None:
            a = {'room': str(arrive['room']), 'screen': int(arrive.get('screen', 0)),
                 'x': int(arrive['x']), 'y': int(arrive['y']),
                 'face': arrive.get('face', 'down')}
            if a['face'] not in MH.FACES:
                raise ValueError(f"face {a['face']!r}: down / left / up / right")
            self.room(a['room'])                       # KeyError when no such room
            h['arrive'] = a
        if spin is not None:
            h['spin'] = bool(spin)
        h.setdefault('spin', True)
        self.touch()
        return copy.deepcopy(h)

    def milly_arrival_problem(self):
        """A sentence when the hook is on but cannot build, else None (the dialog
        and the Rooms tab say it before Build does)."""
        h = self.custom.get('milly_hook') or {}
        if not h.get('enabled'):
            return None
        try:
            rid, k, x, y, _f = MH.arrival(self.custom)
        except MH.HookError as ex:
            return str(ex)
        try:
            r = self.room(rid)
        except KeyError:
            return f'the arrival room {rid!r} was deleted — pick another'
        if str(k) not in (r.get('screens') or {}):
            return f'{r.get("name") or rid} has no screen {k}'
        return None

    def rooms_arriving_milly(self):
        """[(room id, screen, x, y, face)] — the arrival, when the hook is on."""
        if not (self.custom.get('milly_hook') or {}).get('enabled'):
            return []
        try:
            return [MH.arrival(self.custom)]
        except MH.HookError:
            return []

    def create_roots_room(self, repo_root, renderer=None, name=None):
        """Copy the game's roots room ($08) as "Roots room (Milly)" with Warubou
        and his scene; when the hook has no arrival yet, Milly arrives there.
        Returns the new room id."""
        before = {s.get('id') for s in self.custom.get('scripts') or []}
        rid = self.clone_vanilla(MH.ROOTS_SOURCE, name or MH.ROOTS_NAME, repo_root, renderer)
        r = self.room(rid)
        # the copied game scripts of $08 (the ceremony / Terry's arrival) go:
        # the roots room runs only its own scene
        self.custom['scripts'] = [s for s in self.custom.get('scripts') or []
                                  if s.get('id') in before]
        MH.make_roots_room(r)
        if not any(f.get('name') == 'milly_roots_seen' for f in self.flags()):
            self.custom.setdefault('flags', []).append({'name': 'milly_roots_seen',
                                                        'index': 'auto'})
        h = self.custom.setdefault('milly_hook', {})
        if not h.get('arrive'):
            k, x, y, face = MH.ROOTS_ARRIVAL
            h['arrive'] = {'room': rid, 'screen': k, 'x': x, 'y': y, 'face': face}
            h.setdefault('spin', True)
        self.touch()
        return rid

    def roots_scene_destination(self, rid):
        """The roots room's scene's last `move` step (where Milly is led), or None."""
        r = self.room(rid)
        for sc in r.get('cutscenes') or []:
            if sc.get('id') == MH.ROOTS_SCENE:
                for st in reversed(sc.get('steps') or []):
                    if 'move' in st:
                        return copy.deepcopy(st['move'])
        return None

    def set_roots_scene_destination(self, rid, dest):
        r = self.room(rid)
        for sc in r.get('cutscenes') or []:
            if sc.get('id') == MH.ROOTS_SCENE:
                for st in reversed(sc.get('steps') or []):
                    if 'move' in st:
                        st['move'] = {'dest': dest['dest'], 'screen': int(dest.get('screen', 0)),
                                      'x': int(dest['x']), 'y': int(dest['y'])}
                        self.touch()
                        return True
        return False

    def roots_naming(self, rid):
        """True when the roots room's scene opens the naming screen (S121 r3)."""
        for sc in self.room(rid).get('cutscenes') or []:
            if sc.get('id') == MH.ROOTS_SCENE:
                return MH.has_naming(sc)
        return False

    def set_roots_naming(self, rid, on):
        """Put the naming screen between Warubou's lines (with a text box after it)
        or take it out again (removes that box too)."""
        for sc in self.room(rid).get('cutscenes') or []:
            if sc.get('id') == MH.ROOTS_SCENE:
                MH.set_naming(sc, bool(on))
                self.touch()
                return True
        return False

    def milly_flag_names(self):
        """The hook's own flags for flag pickers ({ref: description})."""
        if not (self.custom.get('milly_hook') or {}).get('enabled'):
            return {}
        return {'hook:milly': 'the player is Milly (set at the dresser)',
                'hook:milly_arrived': 'Milly\'s arrival scene has played'}
