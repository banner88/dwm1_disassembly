"""sprite_qt.py — pixel rows (editor2/core/sprite_render.py) -> Qt images, and the
small animated walking preview used by the Monsters tab, the sheet import and
the NPC picker (S106, ROADMAP P3.10)."""

from PySide6.QtCore import QSize, Qt, QTimer
from PySide6.QtGui import QColor, QImage, QPainter, QPixmap
from PySide6.QtWidgets import QLabel, QWidget

from editor2.core import sprite_render as R

CREAM = QColor(248, 248, 216)


def rows_to_image(rows, bg=None):
    """[[rgb | rgba | None]] -> QImage (ARGB32). None = transparent (or bg)."""
    h = len(rows)
    w = len(rows[0]) if h else 0
    img = QImage(w, h, QImage.Format_ARGB32)
    img.fill(bg if bg is not None else QColor(0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, p in enumerate(row):
            if p is None:
                continue
            img.setPixelColor(x, y, QColor(p[0], p[1], p[2], p[3] if len(p) > 3 else 255))
    return img


def pixmap(rows, scale=1, bg=None):
    if not rows:
        return QPixmap()
    img = rows_to_image(rows, bg)
    if scale != 1:
        img = img.scaled(img.width() * scale, img.height() * scale)
    return QPixmap.fromImage(img)


def crop_frame(rows):
    """Trim a 24x24 walking frame to its content's 16x16 neighbourhood for icons."""
    return [r[4:20] for r in rows[8:24]]


class _Cache:
    vanilla_battle = {}
    vanilla_follow = {}


def species_art(doc, sid):
    """(battle rows, follower frames) for any species of the project."""
    if doc is not None and sid <= 214:
        # S107: the project's own art for an original monster (gamedata.art)
        e = ((doc.data.get('gamedata') or {}).get('art') or {}).get(str(sid))
        if e:
            return R.original_art(doc.project_dir, sid, e)
    if sid <= 220:
        if sid not in _Cache.vanilla_battle:
            _Cache.vanilla_battle[sid] = R.vanilla_battle(sid)
            _Cache.vanilla_follow[sid] = R.vanilla_follower(sid)
        return _Cache.vanilla_battle[sid], _Cache.vanilla_follow[sid]
    try:
        entry = doc.new_species(sid)
    except KeyError:
        return None, None
    return R.project_species_art(doc.project_dir, entry)


def species_icon(doc, sid, scale=2):
    """Standing, facing down — like the monster in the field."""
    _b, fol = species_art(doc, sid)
    if not fol:
        return QPixmap()
    return pixmap(crop_frame(fol['down_A']), scale)


class WalkPreview(QWidget):
    """Four facings, walking (A/B every 16 frames ≈ 4 Hz), on the field cream."""

    ORDER = (('down_A', 'down_B'), ('left_A', 'left_B'),
             ('right_A', 'right_B'), ('up_A', 'up_B'))

    def __init__(self, scale=3, parent=None):
        super().__init__(parent)
        self.scale = scale
        self.frames = None
        self.phase = 0
        self.timer = QTimer(self)
        self.timer.timeout.connect(self._tick)
        self.timer.start(260)
        self.setMinimumSize(self.sizeHint())

    def sizeHint(self):
        return QSize(4 * 24 * self.scale + 12, 24 * self.scale)

    def set_frames(self, frames):
        self.frames = frames
        self.update()

    def _tick(self):
        if self.isVisible():
            self.phase ^= 1
            self.update()

    def paintEvent(self, _ev):
        p = QPainter(self)
        p.fillRect(self.rect(), CREAM)
        if not self.frames:
            p.drawText(self.rect(), Qt.AlignCenter, 'no walking art')
            return
        for k, pair in enumerate(self.ORDER):
            img = rows_to_image(self.frames[pair[self.phase]])
            img = img.scaled(img.width() * self.scale, img.height() * self.scale)
            p.drawImage(k * (24 * self.scale + 4), 0, img)


class BattleView(QLabel):
    def __init__(self, scale=2, parent=None):
        super().__init__(parent)
        self.scale = scale
        self.setFixedSize(48 * scale, 48 * scale)
        self.setAlignment(Qt.AlignCenter)

    def set_rows(self, rows):
        if rows:
            self.setPixmap(pixmap(rows, self.scale))
        else:
            self.setPixmap(QPixmap())
            self.setText('no battle art')
