"""states_dialog.py — which room states a room keeps (S144, ROADMAP ARC CAP4c).

User S144: "I want to be able to select states and play with states, vanilla and
custom"; a boss room's beaten state "should stay"; a copy talks as it did at the
chosen moment. Two uses:

  * Make editable (a game room): every screen's states as pictures, a moment in the
    original story that proposes which to keep (`room_states.default_spec`: after
    Starry Night, or "about to do its gate" for a gate's boss floor) — or "Every
    state, following the original game's story" (the S118c copy, nothing chosen);
  * Keep states… (any project room with states): the same picker, no moment for a
    room that is not a copy still following the game.

The result (`spec`) is a room_states keep spec, or None = every state, following the
game. The lowering is `room_states.apply` (Document.clone_vanilla / keep_states).
"""

from PIL import ImageQt
from PySide6.QtCore import Qt
from PySide6.QtGui import QPixmap
from PySide6.QtWidgets import (QButtonGroup, QCheckBox, QComboBox, QDialog,
                               QDialogButtonBox, QGridLayout, QGroupBox, QHBoxLayout,
                               QLabel, QRadioButton, QScrollArea, QVBoxLayout, QWidget)

from editor2.core import room_states as RS
from editor2.core import place_names as PN

FOLLOW = 'follow'
THUMB_SCALE = 0.75


def _pix(img, entries=(), exits=()):
    """The state's picture with its PEOPLE drawn on (the canvas's NPC sprites) and its
    exits outlined — states of one screen often share their tiles and differ only in
    who stands there and where you can leave."""
    from PySide6.QtGui import QColor, QPainter, QPen
    from editor2.app.rooms.canvas import SpriteCache, classify_npc
    if img is None:
        return QPixmap()
    pm = QPixmap.fromImage(ImageQt.ImageQt(img.convert('RGB')))
    qp = QPainter(pm)
    for e in entries:
        try:
            kind, x, y, spr, _label = classify_npc(e)
        except Exception:                                    # noqa: BLE001
            continue
        if kind == 'npc' and spr is not None:
            sp = SpriteCache.get(spr)
            hidden = e.get('kind') == 'raw' and int(str(e['bytes'][0]), 0) & 0x40
            if sp is not None and not sp.isNull() and not hidden:
                qp.drawPixmap(x * 16, y * 16, sp)
            else:
                qp.setPen(QPen(QColor(255, 255, 255, 160), 1))
                qp.drawRect(x * 16 + 2, y * 16 + 2, 11, 11)
        elif kind in ('examine', 'step'):
            qp.setPen(QPen(QColor(255, 220, 0), 1))
            qp.drawRect(x * 16 + 4, y * 16 + 4, 7, 7)
    qp.setPen(QPen(QColor(0, 230, 255), 2))
    for e in exits:
        try:
            qp.drawRect(int(e['x']) * 16 + 1, int(e['y']) * 16 + 1, 14, 14)
        except (KeyError, TypeError, ValueError):
            pass
    qp.end()
    w, h = int(img.width * THUMB_SCALE), int(img.height * THUMB_SCALE)
    return pm.scaled(w, h, Qt.KeepAspectRatio, Qt.SmoothTransformation)


def _counts(entries, exits):
    people = sum(1 for e in entries if (e.get('kind') == 'npc') or (
        e.get('kind') == 'raw' and int(str(e['bytes'][0]), 0) < 0x80
        and not int(str(e['bytes'][0]), 0) & 0x40))
    return f'{people} people, {len(exits)} exit{"s" if len(exits) != 1 else ""}'


class KeepStatesDialog(QDialog):
    """mid = Make editable on game room `mid`; room_id = Keep states… on a project room."""

    def __init__(self, session, parent=None, mid=None, room_id=None, repo=None):
        super().__init__(parent)
        self.s = session
        self.mid = mid
        self.repo = repo or RS.REPO
        rend = session.renderer
        if mid is not None:
            self.sdoc, self.room = RS.preview_copy(session.doc, mid, rend, self.repo)
            self.copy_ = True
            title = f'Make editable: {PN.vanilla_name(mid)}'
            self.render = lambda k, i: rend.render_vanilla_screen(mid, int(k), 1, i)
        else:
            self.sdoc = session.doc
            self.room = session.doc.room(room_id)
            self.copy_ = RS.is_copy(self.room) and not self.room.get('states_kept')
            title = f'Keep states: {session.doc.room_name(self.room)}'
            self.render = lambda k, i: rend.render_screen(self.room, k, i)
        self.setWindowTitle(title)
        self.resize(980, 700)
        lay = QVBoxLayout(self)
        intro = QLabel(
            'A room state is one look of a screen: its tiles, its people, its exits. The '
            'game picks a screen\'s state from how far the story is. Tick the states your '
            'room keeps and the one it starts in. A state the room\'s own scripts switch to '
            '(a boss beaten …) is remembered by a flag of its own, so it stays after a save.')
        intro.setWordWrap(True)
        lay.addWidget(intro)
        top = QHBoxLayout()
        self.moment = QComboBox()
        self.talk = QCheckBox('People talk as they did at that moment')
        self.talk.setToolTip(
            'Checks of the original game\'s story flags that are ON at that moment get '
            'their answer now (your story never sets them). Flags the player sets — talked '
            'once, got an item — stay real checks.')
        self.talk.setChecked(True)
        if self.copy_:
            top.addWidget(QLabel('Moment in the original story:'))
            from editor2.core.balance import VANILLA_STEPS
            self.moment.addItem('Every state, following the original game\'s story', FOLLOW)
            for i in range(len(VANILLA_STEPS) + 1):
                self.moment.addItem(RS.point_label(i), i)
            want = RS.default_point(mid if mid is not None
                                    else int(str(self.room['source_mapID']), 16), self.repo)
            self.moment.setCurrentIndex(self.moment.findData(want))
            self.moment.currentIndexChanged.connect(self._moment_changed)
            top.addWidget(self.moment, 1)
            top.addWidget(self.talk)
        else:
            top.addWidget(QLabel('Choose the states to keep; the room\'s scripts follow '
                                 'the new numbers.'))
        lay.addLayout(top)
        self.summary = QLabel()
        lay.addWidget(self.summary)
        self.area = QScrollArea()
        self.area.setWidgetResizable(True)
        lay.addWidget(self.area, 1)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.button(QDialogButtonBox.Ok).setText('Make editable' if mid is not None else 'Keep')
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        lay.addWidget(bb)
        self.checks = {}           # key -> [QCheckBox per state]
        self.starts = {}           # key -> QButtonGroup
        self.follow_keys = set()
        self._build()
        self._moment_changed()

    # ------------------------------------------------------------ widgets
    def _build(self):
        body = QWidget()
        grid = QVBoxLayout(body)
        for k in RS.screen_keys(self.room):
            n = RS.n_states(self.room['screens'][k])
            box = QGroupBox(f'Screen {k}' + (f' — {n} states' if n > 1 else ' — one state'))
            row = QGridLayout(box)
            cbs = []
            grp = QButtonGroup(box)
            grp.setExclusive(True)
            scr = self.room['screens'][k]
            for i in range(n):
                st = (scr.get('states') or [scr])[i]
                ents, exs = st.get('npcs') or [], st.get('exits') or []
                pic = QLabel()
                try:
                    pic.setPixmap(_pix(self.render(k, i), ents, exs))
                except Exception:                                # noqa: BLE001
                    pic.setText('(no picture)')
                pic.setToolTip(st.get('comment') or f'state {i}')
                row.addWidget(pic, 0, i)
                cnt = QLabel(_counts(ents, exs))
                cnt.setStyleSheet('color: gray;')
                row.addWidget(cnt, 1, i)
                cb = QCheckBox(f'keep state {i}')
                cb.toggled.connect(self._changed)
                rb = QRadioButton('starts here')
                rb.toggled.connect(self._changed)
                grp.addButton(rb, i)
                row.addWidget(cb, 2, i)
                row.addWidget(rb, 3, i)
                if n == 1:
                    cb.setChecked(True)
                    cb.setEnabled(False)
                    rb.setChecked(True)
                    rb.setEnabled(False)
                cbs.append(cb)
            row.setColumnStretch(n, 1)
            self.checks[k] = cbs
            self.starts[k] = grp
            grid.addWidget(box)
        grid.addStretch(1)
        self.area.setWidget(body)

    def _point(self):
        if not self.copy_:
            return None
        return self.moment.currentData()

    def _moment_changed(self, _i=None):
        pt = self._point()
        follow = pt == FOLLOW
        self.talk.setEnabled(not follow)
        if follow:
            spec = {'screens': {k: {'follow': True} for k in RS.screen_keys(self.room)}}
        else:
            spec = RS.default_spec(self.sdoc, self.room, pt if self.copy_ else None,
                                   fold_talk=self.talk.isChecked(), repo=self.repo)
        self._set(spec)

    def _set(self, spec):
        self._busy = True
        self.follow_keys = set()
        for k, cbs in self.checks.items():
            s = spec['screens'].get(k) or {}
            if s.get('follow'):
                self.follow_keys.add(k)
            keep = set(range(len(cbs))) if s.get('follow') else set(s.get('keep') or [0])
            for i, cb in enumerate(cbs):
                cb.setChecked(i in keep)
                cb.setEnabled(len(cbs) > 1 and not s.get('follow'))
            st = 0 if s.get('follow') else s.get('start', 0)
            b = self.starts[k].button(st)
            if b is not None:
                b.setChecked(True)
            for b in self.starts[k].buttons():
                b.setEnabled(len(cbs) > 1 and not s.get('follow'))
        self._busy = False
        self._changed()

    def _changed(self, *_a):
        if getattr(self, '_busy', False):
            return
        kept = total = 0
        for k, cbs in self.checks.items():
            st = self.starts[k].checkedId()
            if 0 <= st < len(cbs) and not cbs[st].isChecked() and k not in self.follow_keys:
                cbs[st].setChecked(True)          # the start state is always kept
            total += len(cbs)
            kept += sum(cb.isChecked() for cb in cbs)
        note = ''
        if self.follow_keys and self._point() != FOLLOW:
            note = (' — screen(s) ' + ', '.join(sorted(self.follow_keys, key=int)) +
                    ' keep following the original game (its scripts use that counter for '
                    'more than states)')
        if self._point() == FOLLOW:
            self.summary.setText(f'Every state ({total}) — the copy follows the original '
                                 'game\'s story, which your romhack never plays: it shows '
                                 'the start-of-game states.')
        else:
            self.summary.setText(f'Keeping {kept} of {total} states{note}.')

    # ------------------------------------------------------------- result
    def spec(self):
        """The keep spec, or None = every state, following the original game."""
        pt = self._point()
        if pt == FOLLOW:
            return None
        screens = {}
        for k, cbs in self.checks.items():
            if k in self.follow_keys:
                screens[k] = {'follow': True}
                continue
            keep = [i for i, cb in enumerate(cbs) if cb.isChecked()]
            st = self.starts[k].checkedId()
            if st < 0:
                st = keep[0] if keep else 0
            screens[k] = {'keep': keep or [st], 'start': st}
        return {'point': pt if self.copy_ else None,
                'fold_talk': bool(self.copy_ and self.talk.isChecked()),
                'screens': screens}
