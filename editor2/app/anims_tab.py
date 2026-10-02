"""anims_tab.py — the Animations tab (ROADMAP P3.11e, S112; EDITOR_DESIGN §5.3
"As built S112"; model editor2/core/anims_doc.py; compiler editor2/core/
battle_anims.py, PROJECT_COMPILER §2.28).

The project's NEW battle animations, made from the frames of the game's 45:
a list on the left (New… / Duplicate / Delete / Rename / Up / Down), and for
the picked one a preview that plays it at the game's speed with its sounds,
and its steps — each a frame of a stock animation shown for some frames, a
sound cue, or a blank. "Add frames…" opens any stock animation (playable) and
inserts the steps you pick, with their timing and sounds. A skill shows an
animation through the Skills tab ("Animation" section). Every edit is one undo
step.

AnimPreview is also used by the Skills tab and the Add frames dialog.
"""

import os

from PySide6.QtCore import QSize, Qt, QTimer, QUrl, Signal
from PySide6.QtGui import QColor, QIcon, QImage, QPainter, QPixmap
from PySide6.QtWidgets import (QAbstractItemView, QCheckBox, QComboBox, QDialog,
                               QDialogButtonBox, QHBoxLayout, QInputDialog, QLabel,
                               QListWidget, QListWidgetItem, QMessageBox,
                               QPushButton, QSpinBox, QSplitter, QTableWidget,
                               QTableWidgetItem, QVBoxLayout, QWidget)

from editor2.app.rooms import commands as C
from editor2.core import battle_anims as BA

BACKDROP = (248, 248, 208)            # the battle screen's cream ($6BFF)
HELP = ('New battle animations made from the frames of the game\'s 45 (a "mashup"). '
        'Each step shows one frame of a stock animation for a number of screen frames '
        '(60 per second), plays a sound, or shows nothing. Frames keep their own colours '
        '(up to 4 source animations per animation). A skill shows one through the Skills '
        'tab → Animation. Numbers $2D and up; the game\'s own 45 are never changed.')
FRAMES_HINT = 'How long this step shows, in screen frames (60 per second). The game stores frames - 1.'


# ---------------------------------------------------------------------------
# sound
# ---------------------------------------------------------------------------
class _Sounds:
    """The animation sound cues (extracted/anim_sounds, the game's engine
    recorded by tools/render_anim_sounds.py). Silent where QtMultimedia or a
    file is missing."""
    def __init__(self):
        self.fx = {}
        try:
            from PySide6.QtMultimedia import QSoundEffect   # noqa: F401
            self.ok = True
        except ImportError:
            self.ok = False

    def play(self, sid):
        if not self.ok:
            return False
        path = BA.sound_file(sid)
        if not path:
            return False
        from PySide6.QtMultimedia import QSoundEffect
        e = self.fx.get(sid)
        if e is None:
            e = QSoundEffect()
            e.setSource(QUrl.fromLocalFile(os.path.abspath(path)))
            self.fx[sid] = e
        e.play()
        return True


SOUNDS = None


def sounds():
    global SOUNDS
    if SOUNDS is None:
        SOUNDS = _Sounds()
    return SOUNDS


def sound_label(sid):
    users = BA.sound_ids().get(sid, [])
    who = ', '.join(BA.stock_name(c) for c in users[:3])
    return f'sound ${sid:02X}' + (f' ({who})' if who else '')


def frame_image(frames, tile_fn, palettes, idx, w=BA.SCREEN_W, h=BA.SCREEN_H, crop=None):
    """One frame on the cream backdrop as a QImage (crop = (x, y, w, h))."""
    img = QImage(w, h, QImage.Format_RGB32)
    img.fill(QColor(*BACKDROP))
    if 0 <= idx < len(frames):
        for (x, y), rgb in BA.draw_frame(frames[idx], tile_fn, palettes).items():
            img.setPixelColor(x, y, QColor(*rgb))
    if crop:
        img = img.copy(*crop)
    return img


def frame_icon(frames, tile_fn, palettes, idx, size=48):
    """A thumbnail around the frame's sprites."""
    px = BA.draw_frame(frames[idx], tile_fn, palettes) if 0 <= idx < len(frames) else {}
    if px:
        xs = [x for x, _y in px]
        ys = [y for _x, y in px]
        cx, cy = (min(xs) + max(xs)) // 2, (min(ys) + max(ys)) // 2
        half = max(24, (max(max(xs) - min(xs), max(ys) - min(ys)) + 9) // 2)
    else:
        cx, cy, half = BA.ORIGIN_X, BA.ORIGIN_Y, 24
    img = frame_image(frames, tile_fn, palettes, idx)
    img = img.copy(cx - half, cy - half, 2 * half, 2 * half)
    return QPixmap.fromImage(img.scaled(size, size, Qt.KeepAspectRatio, Qt.FastTransformation))


# ---------------------------------------------------------------------------
# the preview player
# ---------------------------------------------------------------------------
class AnimPreview(QWidget):
    """Plays an animation as the game does: 60 frames per second, each step's
    frame for its hold + 1 frames, sounds as their step starts; the sprites at
    the middle of the foes (the renderer's X $50 / Y $60), 2x."""
    frameShown = Signal(int)

    def __init__(self, parent=None, scale=2):
        super().__init__(parent)
        self.scale = scale
        self.view = None
        self.sched = []
        self.full = []
        self.pos = 0
        self.cache = {}
        self.loop = True
        self.sound_on = True
        self.timer = QTimer(self)
        self.timer.setInterval(17)
        self.timer.timeout.connect(self._tick)
        self.setFixedSize(BA.SCREEN_W * scale, 104 * scale)
        self.setToolTip('The animation as the game draws it (2x), at the middle of the foes')

    def set_view(self, view):
        """view = (frames, tile_fn, palettes, timeline pairs) or None."""
        self.stop()
        self.view = view
        self.cache = {}
        self.full = BA.schedule(view[3]) if view else []
        self.sched = self.full
        self.pos = 0
        self.update()

    def play(self):
        self.sched = getattr(self, 'full', [])
        if not self.sched:
            return
        self.pos = 0
        self.timer.start()

    def stop(self):
        self.timer.stop()

    def is_playing(self):
        return self.timer.isActive()

    def show_frame(self, idx):
        """Show one frame (no playback)."""
        self.stop()
        self.sched = [(idx, [])]
        self.pos = 0
        self.update()

    def _tick(self):
        if self.pos < len(self.sched):
            f, snd = self.sched[self.pos]
            if snd and self.sound_on:
                for s in snd:
                    sounds().play(s)
            self.frameShown.emit(self.pos)
            self.update()
            self.pos += 1
            return
        if self.loop:
            self.pos = 0
        else:
            self.timer.stop()

    def current(self):
        if not self.sched:
            return None
        return self.sched[min(self.pos, len(self.sched) - 1)][0]

    def paintEvent(self, _ev):
        p = QPainter(self)
        p.fillRect(self.rect(), QColor(*BACKDROP))
        idx = self.current()
        if self.view and idx is not None:
            if idx not in self.cache:
                img = frame_image(self.view[0], self.view[1], self.view[2], idx, crop=(0, 16, 160, 104))
                self.cache[idx] = QPixmap.fromImage(img.scaled(
                    img.width() * self.scale, img.height() * self.scale,
                    Qt.IgnoreAspectRatio, Qt.FastTransformation))
            p.drawPixmap(0, 0, self.cache[idx])
        p.setPen(QColor(200, 200, 160))
        p.drawRect(0, 0, self.width() - 1, self.height() - 1)
        p.end()


class PreviewBox(QWidget):
    """AnimPreview + Play / Stop + sound / loop toggles + a length label."""
    def __init__(self, parent=None, scale=2):
        super().__init__(parent)
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        self.preview = AnimPreview(scale=scale)
        v.addWidget(self.preview)
        h = QHBoxLayout()
        self.play_btn = QPushButton('▶ Play')
        self.play_btn.clicked.connect(self._toggle)
        h.addWidget(self.play_btn)
        self.snd = QCheckBox('Sound')
        self.snd.setChecked(True)
        self.snd.setToolTip('Play the sound cues (the game\'s own sound engine, recorded)')
        self.snd.toggled.connect(lambda on: setattr(self.preview, 'sound_on', on))
        h.addWidget(self.snd)
        self.loop = QCheckBox('Loop')
        self.loop.setChecked(True)
        self.loop.toggled.connect(lambda on: setattr(self.preview, 'loop', on))
        h.addWidget(self.loop)
        self.info = QLabel()
        h.addWidget(self.info, 1)
        v.addLayout(h)
        self.preview.timer.timeout.connect(self._label)

    def set_view(self, view, info=''):
        self.preview.set_view(view)
        self._info = info
        self._label()

    def _toggle(self):
        if self.preview.is_playing():
            self.preview.stop()
        else:
            self.preview.play()
        self._label()

    def _label(self):
        n = len(self.preview.full)
        self.play_btn.setText('■ Stop' if self.preview.is_playing() else '▶ Play')
        self.info.setText(f'{getattr(self, "_info", "")}  {n} frames = {n / 59.73:.2f} s'
                          if n else getattr(self, '_info', ''))


# ---------------------------------------------------------------------------
# the Add frames dialog
# ---------------------------------------------------------------------------
class AddFramesDialog(QDialog):
    """Pick a stock animation, play it, select its steps; OK inserts them."""
    def __init__(self, parent=None, start=0):
        super().__init__(parent)
        self.setWindowTitle('Add frames from a stock animation')
        v = QVBoxLayout(self)
        top = QHBoxLayout()
        top.addWidget(QLabel('Animation:'))
        self.which = QComboBox()
        for c in range(BA.N_STOCK):
            self.which.addItem(f'${c:02X} {", ".join(BA.stock_users(c)[:3]) or "unused"}', c)
        self.which.currentIndexChanged.connect(self._load)
        top.addWidget(self.which, 1)
        v.addLayout(top)
        self.box = PreviewBox()
        v.addWidget(self.box)
        v.addWidget(QLabel('Its steps (select the ones to add — Ctrl / Shift for several):'))
        self.steps = QListWidget()
        self.steps.setViewMode(QListWidget.IconMode)
        self.steps.setIconSize(QSize(48, 48))
        self.steps.setResizeMode(QListWidget.Adjust)
        self.steps.setSelectionMode(QAbstractItemView.ExtendedSelection)
        self.steps.setMinimumSize(560, 200)
        self.steps.itemSelectionChanged.connect(self._sel)
        v.addWidget(self.steps, 1)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        self.all_btn = bb.addButton('Select all', QDialogButtonBox.ActionRole)
        self.all_btn.clicked.connect(self.steps.selectAll)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self.which.setCurrentIndex(int(start))
        self._load()

    def _load(self, *_a):
        c = self.which.currentData()
        view = BA.stock_view(c)
        self.box.set_view(view, f'${c:02X}')
        self.src = BA.expand_source(c)
        self.steps.clear()
        frames, tf, pals, _p = view
        for s in self.src:
            if 'from' in s:
                it = QListWidgetItem(QIcon(frame_icon(frames, tf, pals, s['frame'])),
                                     f"frame {s['frame']}\n{s['hold'] + 1} f")
            elif s.get('blank'):
                it = QListWidgetItem(f"blank\n{s['hold'] + 1} f")
            else:
                it = QListWidgetItem(f"sound\n${s['sound']:02X}")
            self.steps.addItem(it)

    def _sel(self):
        rows = sorted(i.row() for i in self.steps.selectedIndexes())
        if rows and 'from' in self.src[rows[-1]]:
            self.box.preview.show_frame(self.src[rows[-1]]['frame'])

    def chosen(self):
        rows = sorted(i.row() for i in self.steps.selectedIndexes())
        return [dict(self.src[r]) for r in rows]


# ---------------------------------------------------------------------------
# the tab
# ---------------------------------------------------------------------------
class AnimationsTab(QWidget):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.aid = None
        self._busy = False
        self._stale = False
        root = QHBoxLayout(self)
        split = QSplitter()
        root.addWidget(split)
        # ---- left: the list ----
        left = QWidget()
        lv = QVBoxLayout(left)
        self.list = QListWidget()
        self.list.currentItemChanged.connect(self._picked)
        lv.addWidget(self.list, 1)
        g = QHBoxLayout()
        self.new_btn = QPushButton('New…')
        self.new_btn.setToolTip('A new animation — a copy of a stock one to start from')
        self.new_btn.clicked.connect(self._new)
        self.dup_btn = QPushButton('Duplicate')
        self.dup_btn.clicked.connect(self._dup)
        self.del_btn = QPushButton('Delete')
        self.del_btn.setToolTip('Refused while a skill shows it')
        self.del_btn.clicked.connect(self._delete)
        for b in (self.new_btn, self.dup_btn, self.del_btn):
            g.addWidget(b)
        lv.addLayout(g)
        g2 = QHBoxLayout()
        self.ren_btn = QPushButton('Rename…')
        self.ren_btn.clicked.connect(self._rename)
        self.up_btn = QPushButton('Up')
        self.up_btn.setToolTip('Move up (its number moves with it; skills follow by name)')
        self.up_btn.clicked.connect(lambda: self._move(-1))
        self.down_btn = QPushButton('Down')
        self.down_btn.clicked.connect(lambda: self._move(1))
        for b in (self.ren_btn, self.up_btn, self.down_btn):
            g2.addWidget(b)
        lv.addLayout(g2)
        h = QLabel(HELP)
        h.setWordWrap(True)
        lv.addWidget(h)
        split.addWidget(left)
        # ---- right ----
        right = QWidget()
        rv = QVBoxLayout(right)
        self.title = QLabel()
        f = self.title.font()
        f.setPointSize(f.pointSize() + 4)
        f.setBold(True)
        self.title.setFont(f)
        rv.addWidget(self.title)
        self.meter = QLabel()
        self.meter.setWordWrap(True)
        rv.addWidget(self.meter)
        self.box = PreviewBox()
        rv.addWidget(self.box)
        rv.addWidget(QLabel('Steps (the order the game plays them):'))
        self.table = QTableWidget(0, 3)
        self.table.setHorizontalHeaderLabels(['Step', 'Frames', 'From'])
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.table.setSelectionMode(QAbstractItemView.ExtendedSelection)
        self.table.setIconSize(QSize(40, 40))
        self.table.verticalHeader().setDefaultSectionSize(44)
        self.table.horizontalHeader().setStretchLastSection(True)
        self.table.itemSelectionChanged.connect(self._row_picked)
        rv.addWidget(self.table, 1)
        b = QHBoxLayout()
        self.add_btn = QPushButton('Add frames…')
        self.add_btn.setToolTip('Insert steps of any stock animation (with their timing and '
                                'sounds) after the selected step')
        self.add_btn.clicked.connect(self._add_frames)
        self.snd_btn = QPushButton('Add sound…')
        self.snd_btn.clicked.connect(self._add_sound)
        self.blank_btn = QPushButton('Add blank')
        self.blank_btn.setToolTip('A step that shows nothing (a pause)')
        self.blank_btn.clicked.connect(self._add_blank)
        self.rm_btn = QPushButton('Remove')
        self.rm_btn.clicked.connect(self._remove)
        self.sup_btn = QPushButton('Up')
        self.sup_btn.clicked.connect(lambda: self._shift(-1))
        self.sdown_btn = QPushButton('Down')
        self.sdown_btn.clicked.connect(lambda: self._shift(1))
        for w in (self.add_btn, self.snd_btn, self.blank_btn, self.rm_btn, self.sup_btn,
                  self.sdown_btn):
            b.addWidget(w)
        rv.addLayout(b)
        split.addWidget(right)
        split.setSizes([260, 900])
        self.s.undo.indexChanged.connect(self._undo_changed)
        self.refresh()

    # ------------------------------------------------------------ data
    def _undo_changed(self, _i):
        from shiboken6 import isValid
        if not isValid(self):
            return
        if self.isVisible():
            self.refresh()
        else:
            self._stale = True

    def showEvent(self, ev):
        if self._stale:
            self._stale = False
            self.refresh()
        super().showEvent(ev)

    def refresh(self):
        self._busy = True
        anims = self.s.doc.animations()
        self.list.clear()
        sel = None
        for e in anims:
            it = QListWidgetItem(f"${e['number']:02X}  {e['name']}" + ('  ⚠' if e['error'] else ''))
            it.setData(Qt.UserRole, e['id'])
            self.list.addItem(it)
            if e['id'] == self.aid:
                sel = it
        self._busy = False
        if sel is None and self.list.count():
            sel = self.list.item(0)
        if sel is not None:
            self.list.setCurrentItem(sel)
            self.aid = sel.data(Qt.UserRole)
        else:
            self.aid = None
        self.new_btn.setEnabled(len(anims) < BA.MAX_CUSTOM)
        self._show()

    def _picked(self, cur, _prev):
        if self._busy or cur is None:
            return
        self.aid = cur.data(Qt.UserRole)
        self._show()

    def _entry(self):
        if self.aid is None:
            return None
        try:
            return self.s.doc.animation(self.aid)
        except KeyError:
            return None

    def _show(self):
        e = self._entry()
        on = e is not None
        for w in (self.dup_btn, self.del_btn, self.ren_btn, self.up_btn, self.down_btn,
                  self.add_btn, self.snd_btn, self.blank_btn, self.rm_btn, self.sup_btn,
                  self.sdown_btn):
            w.setEnabled(on)
        if not on:
            self.title.setText('No new animations yet — New… makes one from a stock animation')
            self.meter.setText('')
            self.box.set_view(None)
            self.table.setRowCount(0)
            return
        self.title.setText(f"${e['number']:02X}  {e['name']}")
        names = self.s.doc.skill_names_effective()
        users = ', '.join(f'{u} {names.get(u, "")}' for u in e['users']) or 'no skill yet (Skills tab → Animation)'
        if e['error']:
            self.meter.setText(f"⚠ {e['error']}")
            self.box.set_view(None)
        else:
            src = ', '.join(f'${c:02X} {BA.stock_name(c)}' for c in e['sources'])
            self.meter.setText(
                f"{e['duration']} frames ({e['duration'] / 59.73:.2f} s) · frames from {src} "
                f"({len(e['sources'])} / {BA.MAX_SOURCES} colour sets) · {e['tiles']} / "
                f"{BA.MAX_TILES} tiles · shown by: {users}"
                + (''.join(f"\n⚠ {w}" for w in e['warnings'])))
            entry = {'id': e['id'], 'name': e['name'], 'steps': e['steps']}
            self.box.set_view(BA.custom_view(entry), f"${e['number']:02X}")
        self._fill_steps(e)

    def _fill_steps(self, e):
        self.table.blockSignals(True)
        self.table.setRowCount(0)                     # drops the old spin boxes
        self.table.setRowCount(len(e['steps']))
        views = {}
        for r, s in enumerate(e['steps']):
            if 'from' in s:
                c = s['from']
                if c not in views:
                    views[c] = BA.stock_view(c)
                fr, tf, pals, _p = views[c]
                it = QTableWidgetItem(QIcon(frame_icon(fr, tf, pals, s['frame'])), f"frame {s['frame']}")
                frm = f'${c:02X} {BA.stock_name(c)}'
            elif s.get('blank'):
                it = QTableWidgetItem('blank (nothing shown)')
                frm = ''
            else:
                it = QTableWidgetItem(sound_label(int(s['sound'])))
                frm = 'sound — no time'
            it.setFlags(it.flags() & ~Qt.ItemIsEditable)
            self.table.setItem(r, 0, it)
            if 'sound' in s:
                lab = QTableWidgetItem('')
                lab.setFlags(lab.flags() & ~Qt.ItemIsEditable)
                self.table.setItem(r, 1, lab)
                self.table.setCellWidget(r, 1, None)
            else:
                sp = QSpinBox()
                sp.setRange(1, 256)
                sp.setValue(int(s.get('hold', 0)) + 1)
                sp.setKeyboardTracking(False)
                sp.setToolTip(FRAMES_HINT)
                sp.valueChanged.connect(lambda v, r=r: self._hold(r, v))
                self.table.setCellWidget(r, 1, sp)
            fi = QTableWidgetItem(frm)
            fi.setFlags(fi.flags() & ~Qt.ItemIsEditable)
            self.table.setItem(r, 2, fi)
        self.table.resizeColumnToContents(0)
        self.table.blockSignals(False)

    def _row_picked(self):
        """Show the frame of the first selected step (stops playback)."""
        e = self._entry()
        rows = self._rows()
        if not e or not rows or e['error']:
            return
        comp = BA.compose({'steps': e['steps'], 'id': e['id']})
        a, _b = comp['timeline'][rows[0]]           # one pair per step
        if a != 0xFD:
            self.box.preview.show_frame(a)
            self.box._label()

    def _rows(self):
        return sorted({i.row() for i in self.table.selectedIndexes()})

    # ------------------------------------------------------------ edits
    def _push(self, label, op):
        cmd = C.SnapshotCommand(self.s, label, op)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            self.refresh()
            return False
        return True

    def _steps(self):
        return [dict(s) for s in self._entry()['steps']]

    def set_steps(self, steps, what):
        aid = self.aid
        return self._push(f'animation {aid}: {what}', lambda doc: doc.set_animation_steps(aid, steps))

    def _hold(self, r, v):
        st = self._steps()
        if int(st[r].get('hold', 0)) == v - 1:
            return
        st[r]['hold'] = v - 1
        self.set_steps(st, f'step {r + 1} shows {v} frames')

    def _insert_at(self):
        rows = self._rows()
        return (rows[-1] + 1) if rows else len(self._steps())

    def insert_steps(self, new, what):
        st = self._steps()
        at = self._insert_at()
        st[at:at] = new
        if self.set_steps(st, what):
            self.table.selectRow(min(at + len(new) - 1, self.table.rowCount() - 1))

    def _add_frames(self):
        st = self._steps()
        start = next((s['from'] for s in reversed(st) if 'from' in s), 0)
        dlg = AddFramesDialog(self, start)
        if dlg.exec() != QDialog.Accepted:
            return
        new = dlg.chosen()
        if new:
            self.insert_steps(new, f"{len(new)} step(s) of ${dlg.which.currentData():02X}")

    def _add_sound(self):
        ids = sorted(BA.sound_ids())
        labels = [sound_label(s) for s in ids]
        lab, ok = QInputDialog.getItem(self, 'Add sound', 'Sound (the game\'s sound effects the '
                                       'animations use):', labels, 0, False)
        if ok:
            sid = ids[labels.index(lab)]
            sounds().play(sid)
            self.insert_steps([{'sound': sid}], f'sound ${sid:02X}')

    def _add_blank(self):
        self.insert_steps([{'blank': True, 'hold': 2}], 'blank')

    def _remove(self):
        rows = self._rows()
        if not rows:
            return
        st = [s for i, s in enumerate(self._steps()) if i not in rows]
        self.set_steps(st, f'remove {len(rows)} step(s)')

    def _shift(self, d):
        rows = self._rows()
        if len(rows) != 1:
            return
        r = rows[0]
        st = self._steps()
        j = r + d
        if not 0 <= j < len(st):
            return
        st[r], st[j] = st[j], st[r]
        if self.set_steps(st, f'step {r + 1} {"up" if d < 0 else "down"}'):
            self.table.selectRow(j)

    def _new(self):
        labels = [f'${c:02X} {", ".join(BA.stock_users(c)[:3]) or "unused"}' for c in range(BA.N_STOCK)]
        lab, ok = QInputDialog.getItem(self, 'New animation', 'Start from (a copy of its steps):',
                                       labels, 0, False)
        if not ok:
            return
        name, ok = QInputDialog.getText(self, 'New animation', 'Name:')
        if not ok or not name.strip():
            return
        self.create(labels.index(lab), name.strip())

    def create(self, source, name):
        out = {}

        def op(doc):
            out['id'] = doc.new_animation(name, source)
        if self._push(f'new animation {name}', op):
            self.aid = out['id']
            self.refresh()
        return out.get('id')

    def _dup(self):
        out = {}
        aid = self.aid

        def op(doc):
            out['id'] = doc.duplicate_animation(aid)
        if self._push(f'duplicate animation {aid}', op):
            self.aid = out['id']
            self.refresh()

    def _delete(self):
        aid = self.aid
        if QMessageBox.question(self, 'Delete', f'Delete the animation {aid}?') != QMessageBox.Yes:
            return
        self.aid = None
        self._push(f'delete animation {aid}', lambda doc: doc.delete_animation(aid))
        self.refresh()

    def _rename(self):
        e = self._entry()
        name, ok = QInputDialog.getText(self, 'Rename', 'Name:', text=e['name'])
        if ok and name.strip() and name.strip() != e['name']:
            aid = self.aid
            self._push(f'rename animation {aid}', lambda doc: doc.rename_animation(aid, name.strip()))

    def _move(self, d):
        aid = self.aid
        self._push(f'move animation {aid}', lambda doc: doc.move_animation(aid, d))
