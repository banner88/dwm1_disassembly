"""balance_tab.py — the Balance tab (ROADMAP P3.15a, S130; EDITOR_DESIGN §5.9;
service: editor2/core/balance.py, help: editor2/help/72_balance.md).

How hard every key fight of the story is, as ONE number: the team level a
team of that point in the story needs to win 90 % (l90) / 50 % (l50) of the
time. The original game's numbers are precomputed and read-only
(extracted/balance_vanilla.json, tools/build_balance_anchor.py); the
project's are computed on demand from its own data, cached per fight
(<project>/build/balance_cache.json), so only fights whose inputs changed
are recomputed.

Three pages:

  Story curve  every gate (floor runs, boss fights, the dive at both walk
               bounds), every arena class, Starry Night and Monster Grandpa's
               match in story order: original game casual l90 / l50, strong
               l90; the project's same numbers; the change (much harder /
               harder / similar / easier); the share of actions the simulator
               does not model; the project's fights outside the story
               (new gates, rooms) with the original fights they land like.
               A chart: the hardest fight of each step, original vs project.
               "Breeding opens after" (project setting, meta.balance).
  Team         a team a player might have at a story step (rolled: profile,
               step, level, team number — the same teams the numbers use),
               a party imported from a .sav, members picked by hand.
  Fight        any fight: its enemy groups; the current team's win %, rounds,
               HP left; the level rolled teams need; a what-if of an enemy's
               level / stats / skills (simulator only, never saved) shown
               side by side with the fight as it is.

Every computation runs in a background thread (Task) with progress and
Cancel (balance.set_cancel_check stops it at the next battle); results stream
into the table as they come. Nothing here writes the project except the
breeding setting (one undo step).
"""

import copy
import os
import time
import traceback

from PySide6.QtCore import QObject, QPointF, QSettings, Qt, QThread, QTimer, Signal, Slot
from PySide6.QtGui import QBrush, QColor, QFont, QPainter, QPen
from PySide6.QtWidgets import (QAbstractItemView, QApplication, QCheckBox, QComboBox,
                               QDialog, QDialogButtonBox, QFileDialog, QFormLayout,
                               QGridLayout, QGroupBox, QHBoxLayout, QHeaderView, QLabel,
                               QMessageBox, QProgressBar, QPushButton, QSpinBox,
                               QSplitter, QTableWidget, QTableWidgetItem, QTabWidget,
                               QTextBrowser,
                               QTreeWidget, QTreeWidgetItem, QVBoxLayout, QWidget)

from editor2.core import balance as BL

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROFILES = ('player', 'casual', 'strong')     # player = the main number (S130 P3.15b)
SECONDARY = ('casual', 'strong')
TACTICS = ('Charge', 'Mixed', 'Cautious', 'NO SP SK')   # evaluate()'s arena 'tactic' 0-3
VANILLA, PROJECT = 'vanilla', 'project'
SRC_LABEL = {VANILLA: 'Original game', PROJECT: 'Your project'}
TEAMS, BATTLES = 12, 8              # balance.fight_result's defaults (the anchor's)

HELP = ('The number is the team LEVEL a team of that point in the story needs to win 90 % '
        '(l90) or 50 % (l50) of its battles; "99+" = not even at 99. Player (the main number) = '
        'the step\'s best skill kit under your orders (the arena: its best tactic); casual = '
        'what a player had at hand, strong = the best of several rolls. The original '
        "game's numbers are precomputed (read-only); your project's are computed on demand "
        'and cached. Help → Balance explains the model.')

# story tree columns
(C_FIGHT, C_KIND, C_VP90, C_VP50, C_V90, C_V50, C_VS90, C_PP90, C_PP50, C_P90, C_P50, C_PS90,
 C_DELTA, C_UNM, C_NOTE) = range(15)
HEADERS = ['Fight', 'Kind', 'Original\nplayer l90', 'Original\nplayer l50',
           'Original\ncasual l90', 'Original\ncasual l50', 'Original\nstrong l90',
           'Project\nplayer l90', 'Project\nplayer l50', 'Project\ncasual l90',
           'Project\ncasual l50', 'Project\nstrong l90', 'Change', 'Unmodelled', 'Notes']
# (column, side, profile, field) of every level cell
LEVEL_CELLS = [(C_VP90, 'van', 'player', 'l90'), (C_VP50, 'van', 'player', 'l50'),
               (C_V90, 'van', 'casual', 'l90'), (C_V50, 'van', 'casual', 'l50'),
               (C_VS90, 'van', 'strong', 'l90'),
               (C_PP90, 'prj', 'player', 'l90'), (C_PP50, 'prj', 'player', 'l50'),
               (C_P90, 'prj', 'casual', 'l90'), (C_P50, 'prj', 'casual', 'l50'),
               (C_PS90, 'prj', 'strong', 'l90')]
PRJ_COLS = (C_PP90, C_PP50, C_P90, C_P50, C_PS90, C_DELTA)
MAIN_COLS = (C_VP90, C_VP50, C_PP90, C_PP50)
SECONDARY_COLS = (C_V90, C_V50, C_VS90, C_P90, C_P50, C_PS90)

DELTA_COLOURS = {'much harder': QColor(220, 60, 60, 120), 'harder': QColor(235, 150, 40, 120),
                 'similar': QColor(90, 170, 90, 80), 'easier': QColor(70, 130, 220, 110)}
GREY = QColor(140, 140, 140)
# level bands (user: "colour code levels"): cool -> warm, translucent like the
# Change colours so the palette's own text stays legible in light and dark
LEVEL_BANDS = [(10, '1-10', (40, 170, 90)), (20, '11-20', (110, 190, 70)),
               (30, '21-30', (175, 200, 55)), (40, '31-40', (230, 210, 50)),
               (50, '41-50', (240, 180, 45)), (60, '51-60', (240, 140, 40)),
               (75, '61-75', (230, 100, 40)), (98, '76-98', (215, 55, 45))]
BAND_ALPHA = 105
BEYOND_RGB = (120, 35, 150)          # 99+: deep purple, deeper the more is lost at 99
STAT_KEYS = ('hp', 'mp', 'atk', 'def', 'agl', 'int')


# ---------------------------------------------------------------------------
# pure helpers (tested headless-ish)
# ---------------------------------------------------------------------------
def beyond(r):
    """(win or clear rate at 99, enemies' HP left at 99 or None) of a result
    whose level is 'not even at 99' — its at90 is then the evaluation at 99."""
    a = (r or {}).get('at90') or {}
    x = a.get('clear') if r and r.get('dive') else a.get('win')
    return x, a.get('enemy_hp_left')


def lv_text(r, field='l90'):
    """A result's level as shown: '—' not computed; '99+ (17 %)' not even at
    99, with the win (dives: clear) rate teams of level 99 reach."""
    if r is None:
        return '—'
    v = r.get(field)
    if v is not None:
        return str(v)
    x, _e = beyond(r)
    return '99+' if x is None else f'99+ ({x * 100:.0f} %)'


def level_colour(level, lost=None):
    """The background of a level: its band's colour; 100 = '99+' (purple,
    alpha 90-170 by the share of battles lost at 99 when known)."""
    if level is None:
        return None
    if level >= 100:
        a = 130 if lost is None else int(90 + 80 * max(0.0, min(1.0, lost)))
        return QColor(*BEYOND_RGB, a)
    for top, _lab, rgb in LEVEL_BANDS:
        if level <= top:
            return QColor(*rgb, BAND_ALPHA)
    return QColor(*LEVEL_BANDS[-1][2], BAND_ALPHA)


def result_colour(r, field='l90'):
    """level_colour of a result's l90 / l50 (None when not computed)."""
    if r is None:
        return None
    v = r.get(field)
    if v is not None:
        return level_colour(int(v))
    x, _e = beyond(r)
    return level_colour(100, None if x is None else 1 - x)


def value_colour(v):
    """level_colour of a chart_value (step rows: 100-120 = beyond 99)."""
    if v is None:
        return None
    return level_colour(v) if v < 100 else level_colour(100, (v - 100) / 20.0)


def level_legend_html():
    parts = [f'<span style="background:rgba({rgb[0]},{rgb[1]},{rgb[2]},{BAND_ALPHA / 255:.2f});">'
             f'&nbsp;{lab}&nbsp;</span>' for _t, lab, rgb in LEVEL_BANDS]
    parts.append(f'<span style="background:rgba({BEYOND_RGB[0]},{BEYOND_RGB[1]},{BEYOND_RGB[2]},'
                 f'0.55);">&nbsp;99+&nbsp;</span>')
    return 'Levels: ' + ' '.join(parts)


def chart_value(r):
    """A result's l90 for the chart / a step's hardest fight: the level, or
    above 100 for 'not even at 99' — 100 + 10 x (share of battles lost at 99)
    + 10 x (enemies' HP left at 99; the loss share again when unknown), so
    100-120 reads 'unwinnable at 99, by how far'."""
    if r is None:
        return None
    if r.get('l90') is not None:
        return int(r['l90'])
    x, e = beyond(r)
    if x is None:
        return 100.0
    return 100 + 10 * (1 - x) + 10 * (e if e is not None else (1 - x))


def lv_num(r, field='l90'):
    """For comparisons: None = not computed; 'not even at 99' counts as 100."""
    if r is None:
        return None
    v = r.get(field)
    return 100 if v is None else int(v)


def delta_class(van, prj):
    """(text, class) of the project's level against the original's: the band
    widens with the level (3 levels at L5 are a lot, at L60 they are noise)."""
    if van is None or prj is None:
        return '', None
    d = prj - van
    t1 = max(3, round(0.12 * van))
    t2 = max(8, round(0.30 * van))
    txt = ('+' if d > 0 else '') + str(d)
    if van >= 100 and prj >= 100:
        return '=', 'similar'
    if d >= t2:
        return txt, 'much harder'
    if d >= t1:
        return txt, 'harder'
    if d <= -t1:
        return txt, 'easier'
    return txt, 'similar'


def delta_beyond(van_r, prj_r):
    """Both 'not even at 99': compare what level-99 teams reach (win / clear
    rate) -> (text, class)."""
    x, _e = beyond(van_r)
    y, _f = beyond(prj_r)
    if x is None or y is None:
        return '=', 'similar'
    d = round((y - x) * 100)
    txt = f'{d:+d} % at 99' if d else '= at 99'
    if d <= -25:
        return txt, 'much harder'
    if d <= -10:
        return txt, 'harder'
    if d >= 10:
        return txt, 'easier'
    return txt, 'similar'


SIMPLE_LINE = ('The number is the team level a well-built team needs to win 9 battles out of 10 — '
               'the best 3 monsters and 8 skills you could have at that point in the story, '
               'ordered every turn (best tactic in the arena). Lower = easier. Green = easy … '
               'red = hard, purple = can\'t win even at level 99.')
SIMPLE_CHANGE_COLOURS = dict(DELTA_COLOURS, **{'much easier': QColor(60, 100, 220, 150)})


def simple_text(r):
    """A player result in plain words: 'Lv 32' / "can't win (38 %)" / '—'."""
    if r is None:
        return '—'
    if r.get('l90') is not None:
        return f"Lv {r['l90']}"
    x, _e = beyond(r)
    return "can't win" if x is None else f"can't win ({x * 100:.0f} %)"


def simple_tip(r):
    """One sentence about a player result."""
    if r is None:
        return 'Not computed yet.'
    l90, l50 = r.get('l90'), r.get('l50')
    if l90 is not None:
        half = '' if l50 is None or l50 >= l90 else f'; at level {l50} it wins half'
        return f'A well-built team at level {l90} wins 9 of 10 battles here{half}.'
    x, e = beyond(r)
    keep = '' if e is None else f' (the enemies keep {e * 100:.0f} % of their HP on average)'
    return (f'Even a well-built team at level 99 wins only {(x or 0) * 100:.0f} % of the battles '
            f'here{keep}.')


def simple_change(van_r, prj_r):
    """(words, colour class) of the project's player level against the
    original's: the Change column's thresholds, said in plain words."""
    a, b = lv_num(van_r), lv_num(prj_r)
    if a is None or b is None:
        return '', None
    if a >= 100 and b >= 100:
        _t, cls = delta_beyond(van_r, prj_r)
        return {'much harder': 'much harder', 'harder': 'harder', 'easier': 'easier'}.get(
            cls, 'about the same') + ' (both unwinnable)', cls
    d = b - a
    t1 = max(3, round(0.12 * a))
    t2 = max(8, round(0.30 * a))
    if d >= t2:
        return f'much harder (+{d})', 'much harder'
    if d >= t1:
        return f'harder (+{d})', 'harder'
    if d <= -t2:
        return f'much easier (−{-d})', 'much easier'
    if d <= -t1:
        return f'easier (−{-d})', 'easier'
    return 'about the same', 'similar'


def dive_row_result(d, walk):
    """gate_dive_result / the anchor's dive entry -> a row result."""
    if not d or walk not in d:
        return None
    e = d[walk]
    return {'l90': e.get('level'), 'l50': None, 'at90': e.get('eval') or {}, 'dive': True}


def tactic_name(t):
    try:
        return TACTICS[int(t)]
    except (TypeError, ValueError, IndexError):
        return None


def kit_html(kit, names=None, skill_names=None, title='', fight_key=None, result=None):
    """A step's kit as HTML (the Story page's kit view): members (monster, how
    it is had, plus, level reached, skills), the level it was optimised at,
    the planner's 'why' lines, the arena tactic of the selected fight."""
    if not kit:
        return f'<p><b>{title}</b>: no kit known yet.</p>'
    names = names or {}
    skill_names = skill_names or {}
    out = [f"<p><b>{title}</b> — optimised at team level <b>{kit.get('level', '?')}</b>"
           + (f", score {kit['score']:.2f}" if isinstance(kit.get('score'), (int, float)) else '')
           + (f", the wall: {kit['wall']}" if kit.get('wall') else '') + '</p>',
           '<table cellspacing="0" cellpadding="2" border="1">'
           '<tr><th>Monster</th><th>How</th><th>+</th><th>Lv</th><th>Skills</th></tr>']
    for m in kit.get('members') or []:
        nm = m.get('name') or names.get(m.get('species'), f"#{m.get('species')}")
        src = m.get('src') or []
        if src and src[0] == 'join':
            how = f'joins (EID {src[1]})' if len(src) > 1 else 'joins'
        elif src and src[0] == 'bred':
            how = 'bred ' + ' x '.join(names.get(x, f'#{x}') for x in src[1:3])
        else:
            how = ''
        sk = m.get('skill_names') or [skill_names.get(x, f'#{x}') for x in m.get('skills') or []]
        out.append(f"<tr><td>{nm}</td><td>{how}</td><td>{m.get('plus', 0)}</td>"
                   f"<td>{m.get('level', '')}</td><td>{', '.join(sk)}</td></tr>")
    out.append('</table>')
    if kit.get('why'):
        out.append('<p style="color:#888">' + '<br>'.join(kit['why']) + '</p>')
    if fight_key:
        tac = ((result or {}).get('at90') or {}).get('tactic')
        if tac is None:
            tac = ((kit.get('fights') or {}).get(fight_key) or {}).get('tactic')
        if tac is not None and fight_key.startswith('arena'):
            out.append(f'<p>{fight_key}: in the arena (no Command) the best tactic is '
                       f'<b>{tactic_name(tac)}</b>.</p>')
    return ''.join(out)


def fight_sort_key(key):
    """Floors first (by floor), then the boss fights, then arena matches."""
    try:
        tail = key.split('.', 1)[1]
    except IndexError:
        return (9, 0, key)
    for pre, rank in (('f', 0), ('boss', 1), ('m', 2), ('b', 3), ('list', 4)):
        if tail.startswith(pre) and tail[len(pre):].isdigit():
            return (rank, int(tail[len(pre):]), key)
    return (8, 0, key)


def kind_text(kind):
    return {'list': 'wild', 'boss': 'boss', 'arena': 'arena', 'dive': 'dive'}.get(kind, kind)


def anchor_problem(anchor):
    """None when the anchor can be shown, else why not (a sentence)."""
    if anchor is None:
        return ("The original game's numbers are not built yet (extracted/balance_vanilla.json "
                'is missing — tools/build_balance_anchor.py builds it, about an hour). The '
                'original columns stay empty until then; your project can be computed anyway.')
    if anchor.get('sim_version') != BL.SIM_VERSION:
        return (f"The original game's numbers were made by simulator {anchor.get('sim_version')}, "
                f'this editor runs {BL.SIM_VERSION}: they are shown but no longer comparable — '
                'rebuild them (tools/build_balance_anchor.py).')
    return None


def breeding_setting(doc_data):
    """The project's "breeding opens after step N" (meta.balance)."""
    try:
        v = ((doc_data.get('meta') or {}).get('balance') or {}).get('breeding_opens_after')
        return BL.BREEDING_OPENS_AFTER if v is None else int(v)
    except (TypeError, ValueError, AttributeError):
        return BL.BREEDING_OPENS_AFTER


def set_breeding_setting(doc, step):
    """SnapshotCommand op: store the setting (dropped when it is the default)."""
    meta = doc.data.setdefault('meta', {})
    bal = meta.get('balance') or {}
    if step is None or step == BL.BREEDING_OPENS_AFTER:
        bal.pop('breeding_opens_after', None)
    else:
        bal['breeding_opens_after'] = int(step)
    if bal:
        meta['balance'] = bal
    else:
        meta.pop('balance', None)
    doc.touch()


# ---------------------------------------------------------------------------
# data contexts + background tasks
# ---------------------------------------------------------------------------
class Ctx:
    """One data source: BattleData + Timeline (+ the project's fights outside
    the story, its cache) and a what-if copy of the data for the Fight page
    (its own enemy_overrides, so a what-if never reaches the story numbers)."""

    def __init__(self, src, data, tl, extras, cache, gen):
        self.src, self.data, self.tl, self.extras, self.cache, self.gen = \
            src, data, tl, extras, cache, gen
        self.whatif = copy.copy(data)
        self.whatif.enemy_overrides = {}

    def fight(self, key):
        return self.tl.fights.get(key)

    def all_fights(self):
        """[(fight, step label)] story order, then the extras."""
        out = []
        for st in self.tl.steps:
            for k in st['fights']:
                out.append((self.tl.fights[k], f"{st['index'] + 1}. {st['label']}"))
        for f in self.extras:
            out.append((f, 'outside the story'))
        return out

    def ids(self):
        return {id(self.data), id(self.tl), id(self.whatif)}


def load_ctx(src, payload, gen, caches=None):
    """(worker) -> Ctx. payload = (project data copy, project dir, breeding);
    caches = {path: FightCache} kept by the tab across re-reads."""
    if src == VANILLA:
        data = BL.BattleData(None)
        tl = BL.Timeline(data)
        return Ctx(src, data, tl, [], None, gen)
    from editor2.core.project import Project
    pdata, pdir, breeding = payload
    prj = Project(pdata, pdir)
    prj.repo_root = REPO
    data = BL.BattleData(prj)
    tl = BL.Timeline(data, breeding_opens=breeding)
    extras = BL.extra_fights(data, tl)
    for f in extras:                 # dives of new gates find their floors / boss
        tl.fights.setdefault(f['key'], f)
    path = BL.project_cache_path(prj) or ''
    cache = caches.get(path) if caches is not None and path else None
    if cache is None:
        cache = BL.FightCache(path)
        if caches is not None and path:
            caches[path] = cache       # one cache object per file (re-reads share it)
    return Ctx(src, data, tl, extras, cache, gen)


def purge_memo(ids):
    """Forget balance's per-object memos of dropped contexts (keys are id()s,
    which Python reuses once the objects are gone)."""
    for k in [k for k in list(BL._TEAMS) if k[0] in ids or k[1] in ids]:
        BL._TEAMS.pop(k, None)
    for k in [k for k in list(BL._KITS) if k[0] in ids or k[1] in ids]:
        BL._KITS.pop(k, None)
    for i in ids:
        BL._BR.pop(i, None)


class Task(QThread):
    """fn(task) in a background thread. task.emit_progress / emit_result
    stream to the GUI; Cancel stops at the next battle."""
    progress = Signal(int, int, str)
    result = Signal(object)
    done = Signal(object)            # {'value', 'error', 'cancelled'}

    def __init__(self, fn, parent=None):
        super().__init__(parent)
        self.fn = fn
        self._stop = False

    def cancel(self):
        self._stop = True

    def is_cancelled(self):
        return self._stop

    def emit_progress(self, i, n, text=''):
        self.progress.emit(int(i), int(n), str(text))

    def emit_result(self, r):
        self.result.emit(r)

    def run(self):
        BL.set_cancel_check(self.is_cancelled)
        out = {'value': None, 'error': None, 'cancelled': False}
        try:
            out['value'] = self.fn(self)
        except BL.Cancelled:
            out['cancelled'] = True
        except Exception as e:                              # noqa: BLE001
            out['error'] = f'{e}\n{traceback.format_exc(limit=4)}'
        finally:
            BL.set_cancel_check(None)
        out['cancelled'] = out['cancelled'] or self._stop
        self.done.emit(out)


class _Relay(QObject):
    """Lives in the GUI thread: a Task's signals arrive here queued and call
    the page's callbacks there."""

    def __init__(self, on_progress=None, on_result=None, on_done=None):
        super().__init__()
        self.p, self.r, self.d = on_progress, on_result, on_done

    @Slot(int, int, str)
    def progress(self, i, n, t):
        if self.p:
            self.p(i, n, t)

    @Slot(object)
    def result(self, r):
        if self.r:
            self.r(r)

    @Slot(object)
    def done(self, out):
        if self.d:
            self.d(out)


# ---------------------------------------------------------------------------
# the chart
# ---------------------------------------------------------------------------
class CurveChart(QWidget):
    """The hardest fight's l90 of every story step: original (dashed) and
    project (solid); '99+' sits on the top line. Grey band = postgame."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.van, self.prj = {}, {}
        self.n = 0
        self.post = None
        self.breed = []
        self.labels = {}
        self.setMinimumHeight(170)

    def set_data(self, n, van, prj, post=None, breed=(), labels=None):
        self.n, self.van, self.prj = n, dict(van), dict(prj)
        self.post, self.breed, self.labels = post, list(breed), dict(labels or {})
        self.update()

    def paintEvent(self, _ev):
        p = QPainter(self)
        p.setRenderHint(QPainter.Antialiasing)
        pal = self.palette()
        txt = pal.text().color()
        w, h = self.width(), self.height()
        l, r, t, b = 36, 10, 10, 22
        if self.n < 2:
            p.setPen(txt)
            p.drawText(self.rect(), Qt.AlignCenter, 'The curve appears once there are numbers.')
            return

        def X(i):
            return l + (w - l - r) * i / (self.n - 1)

        def Y(v):
            return t + (h - t - b) * (1 - min(v, 120) / 120.0)
        if self.post is not None:
            p.fillRect(int(X(self.post - 0.5)), t, int(X(self.n - 1) - X(self.post - 0.5)) + 1,
                       h - t - b, QColor(128, 128, 128, 40))
        p.fillRect(l, int(Y(120)), w - r - l, int(Y(100) - Y(120)), QColor(220, 60, 60, 28))
        p.setPen(QPen(QColor(128, 128, 128, 90), 1))
        for lv in (20, 40, 60, 80, 100):
            p.drawLine(l, int(Y(lv)), w - r, int(Y(lv)))
        p.setPen(txt)
        for lv in (0, 20, 40, 60, 80, 100):
            p.drawText(0, int(Y(lv)) - 7, l - 4, 14, Qt.AlignRight | Qt.AlignVCenter,
                       '99' if lv == 100 else str(lv))
        p.drawText(0, int(Y(118)) - 7, l - 4, 14, Qt.AlignRight | Qt.AlignVCenter, '99+')
        p.drawText(l + 6, int(Y(120)), max(50, w - r - l - 12), int(Y(100) - Y(120)),
                   Qt.AlignLeft | Qt.AlignVCenter,
                   'above 99: not won even at 99 — higher = further (fewer wins, more enemy HP left)')
        for i in range(0, self.n, 5):
            p.drawText(int(X(i)) - 12, h - b + 4, 24, 14, Qt.AlignHCenter, str(i + 1))
        for i, col in self.breed:
            p.setPen(QPen(col, 1, Qt.DotLine))
            p.drawLine(int(X(i + 0.5)), t, int(X(i + 0.5)), h - b)
        for series, col, style in ((self.van, QColor(130, 130, 130), Qt.DashLine),
                                   (self.prj, QColor(50, 120, 220), Qt.SolidLine)):
            pts = [(i, v) for i, v in sorted(series.items()) if v is not None]
            p.setPen(QPen(col, 2, style))
            for (i0, v0), (i1, v1) in zip(pts, pts[1:]):
                p.drawLine(QPointF(X(i0), Y(v0)), QPointF(X(i1), Y(v1)))
            p.setBrush(QBrush(col))
            for i, v in pts:
                if v > 100:          # beyond 99: a hollow square
                    p.setBrush(Qt.NoBrush)
                    p.drawRect(int(X(i)) - 3, int(Y(v)) - 3, 6, 6)
                    p.setBrush(QBrush(col))
                else:
                    p.drawEllipse(QPointF(X(i), Y(v)), 2.5, 2.5)
            p.setBrush(Qt.NoBrush)
        ly = int(Y(100)) + 4                # the legend: under the beyond-99 band
        p.setPen(QPen(QColor(130, 130, 130), 2, Qt.DashLine))
        p.drawLine(w - 190, ly + 6, w - 170, ly + 6)
        p.setPen(txt)
        p.drawText(w - 166, ly, 60, 14, Qt.AlignLeft, 'original')
        p.setPen(QPen(QColor(50, 120, 220), 2))
        p.drawLine(w - 100, ly + 6, w - 80, ly + 6)
        p.setPen(txt)
        p.drawText(w - 76, ly, 70, 14, Qt.AlignLeft, 'project')


# ---------------------------------------------------------------------------
# page 1: the story curve
# ---------------------------------------------------------------------------
class StoryPage(QWidget):
    def __init__(self, tab):
        super().__init__()
        self.tab = tab
        self.items = {}           # row key -> item ('gate0.f1', 'dive0.direct', ...)
        self.res = {}             # (side 'van'|'prj', profile, row key) -> result
        self.row_kind = {}        # row key -> 'list'|'boss'|'arena'|'dive'
        self.extra_keys = []
        self.task = None
        v = QVBoxLayout(self)
        self.banner = QLabel()
        self.banner.setWordWrap(True)
        self.banner.setStyleSheet('color:#b06000;')
        v.addWidget(self.banner)
        # S130: build the original game's numbers on THIS computer (all cores)
        abar = QHBoxLayout()
        self.b_anchor = QPushButton('Build original-game numbers')
        self.b_anchor.setToolTip(
            'Runs tools/build_balance_anchor.py on this computer with every CPU core '
            f'({os.cpu_count() or "?"} here). It can take an hour or more. Finished parts are '
            'saved as they finish, so Stop / closing the editor loses nothing — press the '
            'button again to continue.')
        self.b_anchor.clicked.connect(self.build_anchor)
        self.b_anchor_stop = QPushButton('Stop')
        self.b_anchor_stop.clicked.connect(self.stop_anchor)
        self.b_anchor_stop.setVisible(False)
        self.anchor_status = QLabel()
        abar.addWidget(self.b_anchor)
        abar.addWidget(self.b_anchor_stop)
        abar.addWidget(self.anchor_status, 1)
        v.addLayout(abar)
        self.proc = None
        bar = QHBoxLayout()
        self.b_player = QPushButton('Compute player')
        self.b_player.setToolTip('Your project\'s player numbers for every fight: each step\'s '
                                 'skill kit is optimised first (minutes per step), then its '
                                 'fights. Cached kits and fights are instant.')
        self.b_player.clicked.connect(lambda: self.compute(('player',)))
        self.b_casual = QPushButton('Compute casual')
        self.b_casual.setToolTip('Your project\'s casual numbers for every fight (cached ones '
                                 'are instant; about 2-8 s per changed fight).')
        self.b_casual.clicked.connect(lambda: self.compute(('casual',)))
        self.b_strong = QPushButton('Compute strong')
        self.b_strong.setToolTip('Your project\'s strong numbers for every fight (about 40 s '
                                 'per changed fight — the whole story takes a while).')
        self.b_strong.clicked.connect(lambda: self.compute(('strong',)))
        self.b_sel = QPushButton('Compute selected')
        self.b_sel.setToolTip('Player (and casual / strong when shown) for the selected rows '
                              '(a step row = all its fights).')
        self.b_sel.clicked.connect(self.compute_selected)
        self.dives = QCheckBox('with gate dives')
        self.dives.setChecked(True)
        self.dives.setToolTip('Also each gate\'s dive: all floors without healing, then the '
                              'boss (both walk bounds).')
        self.b_cancel = QPushButton('Cancel')
        self.b_cancel.setEnabled(False)
        self.b_cancel.clicked.connect(self.cancel)
        self.b_simple = QPushButton('Compute your project')
        self.b_simple.setToolTip('Works out your project\'s number for every fight (each story '
                                 'step\'s best team first — minutes per step; anything already '
                                 'worked out and unchanged is instant).')
        self.b_simple.clicked.connect(lambda: self.compute(('player',)))
        for wdg in (self.b_simple, self.b_player, self.b_casual, self.b_strong, self.b_sel,
                    self.dives, self.b_cancel):
            bar.addWidget(wdg)
        self.prog = QProgressBar()
        self.prog.setTextVisible(True)
        self.prog.setRange(0, 1)
        self.prog.setValue(0)
        self.prog.setFormat('idle')
        bar.addWidget(self.prog, 1)
        v.addLayout(bar)
        bar2 = QHBoxLayout()
        self.breed_label = QLabel('Breeding opens after:')
        bar2.addWidget(self.breed_label)
        self.breed = QComboBox()
        self.breed.setToolTip('Your project: the story step after which rolled teams may hold '
                              'bred monsters (the original game: after the F class). Saved in '
                              'the project (one undo step); only the Balance tab reads it.')
        self.breed.activated.connect(self._breed_changed)
        bar2.addWidget(self.breed)
        bar2.addSpacing(12)
        self.show_sec = QCheckBox('show casual / strong')
        self.show_sec.setChecked(True)
        self.show_sec.setToolTip('The secondary profiles\' columns (the player columns are the '
                                 'main number).')
        self.show_sec.toggled.connect(lambda _on: self._apply_columns())
        bar2.addWidget(self.show_sec)
        bar2.addSpacing(12)
        self.delta_label = QLabel('Change compares:')
        bar2.addWidget(self.delta_label)
        self.delta_prof = QComboBox()
        self.delta_prof.addItems(PROFILES)
        self.delta_prof.currentIndexChanged.connect(lambda _i: self.refresh_rows())
        bar2.addWidget(self.delta_prof)
        bar2.addSpacing(12)
        self.chart_label = QLabel('Chart:')
        bar2.addWidget(self.chart_label)
        self.chart_prof = QComboBox()
        self.chart_prof.addItems(PROFILES)
        self.chart_prof.currentIndexChanged.connect(lambda _i: self.update_chart())
        bar2.addWidget(self.chart_prof)
        bar2.addStretch(1)
        self.legend = QLabel(' '.join(
            f'<span style="background:rgba({c.red()},{c.green()},{c.blue()},{c.alpha() / 255:.2f});">'
            f'&nbsp;{k}&nbsp;</span>' for k, c in DELTA_COLOURS.items()))
        bar2.addWidget(self.legend)
        v.addLayout(bar2)
        split = QSplitter(Qt.Vertical)
        self.tree = QTreeWidget()
        self.tree.setColumnCount(len(HEADERS))
        self.tree.setHeaderLabels(HEADERS)
        hfont = QFont(self.tree.font())
        hfont.setBold(True)
        for c in MAIN_COLS:
            self.tree.headerItem().setFont(c, hfont)
        self.tree.setSelectionMode(QAbstractItemView.ExtendedSelection)
        self.tree.setAlternatingRowColors(True)
        self.tree.setUniformRowHeights(True)
        hd = self.tree.header()
        hd.setSectionResizeMode(QHeaderView.Interactive)
        self.tree.setColumnWidth(C_FIGHT, 320)
        self.tree.setColumnWidth(C_KIND, 50)
        for c, _sd, _p, _f in LEVEL_CELLS:
            self.tree.setColumnWidth(c, 72)
        self.tree.setColumnWidth(C_DELTA, 70)
        self.tree.setColumnWidth(C_UNM, 74)
        hd.setStretchLastSection(True)
        self.tree.itemDoubleClicked.connect(self._open_fight)
        self.tree.currentItemChanged.connect(lambda cur, _prev: self.show_kit(cur))
        tw = QWidget()
        tv = QVBoxLayout(tw)
        tv.setContentsMargins(0, 0, 0, 0)
        tv.setSpacing(2)
        self.level_legend = QLabel(level_legend_html())
        self.level_legend.setToolTip('Every level cell is coloured by its band. 99+ (not won even '
                                     'at 99) is purple, deeper the more battles teams of level '
                                     '99 still lose.')
        self.simple_line = QLabel(SIMPLE_LINE)
        self.simple_line.setWordWrap(True)
        tv.addWidget(self.simple_line)
        lrow = QHBoxLayout()
        lrow.addWidget(self.level_legend)
        lrow.addStretch(1)
        self.b_show_team = QPushButton('Show the team')
        self.b_show_team.setCheckable(True)
        self.b_show_team.setToolTip('The best team (3 monsters, their skills) for the selected '
                                    'step or fight.')
        self.b_show_team.toggled.connect(lambda _on: self.apply_mode())
        lrow.addWidget(self.b_show_team)
        tv.addLayout(lrow)
        hsplit = QSplitter(Qt.Horizontal)
        hsplit.addWidget(self.tree)
        kv = QWidget()
        self.kit_panel = kv
        kvl = QVBoxLayout(kv)
        kvl.setContentsMargins(0, 0, 0, 0)
        kh = QLabel('<b>The step\'s kit</b> (player profile)')
        kvl.addWidget(kh)
        self.kit_view = QTextBrowser()
        self.kit_view.setOpenExternalLinks(False)
        self.kit_view.setHtml('<p style="color:#888">Select a step or a fight to see the '
                              'skill kit a skilled player brings there.</p>')
        kvl.addWidget(self.kit_view, 1)
        self.b_use_kit = QPushButton('Use this kit as the current team')
        self.b_use_kit.setToolTip('The kit raised to the level shown (the selected fight\'s player '
                                  'l90, else the level the kit was optimised at) becomes the Team '
                                  'page\'s team — the Fight page fights with it.')
        self.b_use_kit.setEnabled(False)
        self.b_use_kit.clicked.connect(self.use_kit)
        kvl.addWidget(self.b_use_kit)
        hsplit.addWidget(kv)
        hsplit.setStretchFactor(0, 3)
        hsplit.setStretchFactor(1, 1)
        hsplit.setSizes([1000, 340])
        tv.addWidget(hsplit, 1)
        split.addWidget(tw)
        self.chart = CurveChart()
        split.addWidget(self.chart)
        split.setStretchFactor(0, 4)
        split.setStretchFactor(1, 1)
        split.setSizes([560, 180])
        v.addWidget(split, 1)
        hl = QLabel(HELP + ' Double-click a fight to open it on the Fight page.')
        self.help_line = hl
        hl.setWordWrap(True)
        hl.setStyleSheet('color:#888;')
        v.addWidget(hl)
        self.kits_prj = {}            # step -> the project's kit (computed / cached)
        self._kit_shown = None        # (src, step, kit, level)
        self._project_widgets(self.tab.s is not None)

    # ------------------------------------------------------------ the anchor build
    def anchor_parts_done(self):
        p = os.path.join(REPO, BL.ANCHOR_JSON) + '.partial'
        try:
            with open(p) as f:
                return sum(1 for line in f if line.strip())
        except OSError:
            return 0

    def build_anchor(self):
        from PySide6.QtCore import QProcess
        import sys as _sys
        if self.proc is not None:
            return
        self.proc = QProcess(self)
        self.proc.setWorkingDirectory(REPO)
        self.proc.setProcessChannelMode(QProcess.MergedChannels)
        self.proc.readyReadStandardOutput.connect(self._anchor_output)
        self.proc.finished.connect(self._anchor_finished)
        self.proc.start(_sys.executable, ['-u', os.path.join(REPO, 'tools', 'build_balance_anchor.py')])
        self.b_anchor.setEnabled(False)
        self.b_anchor_stop.setVisible(True)
        self.anchor_status.setText(f'starting… ({self.anchor_parts_done()} parts already saved)')

    def _anchor_output(self):
        txt = bytes(self.proc.readAllStandardOutput()).decode('utf-8', 'replace')
        for line in txt.splitlines():
            line = line.strip()
            if line.startswith('[') and '/' in line.split(']')[0]:
                self.anchor_status.setText('building: ' + line[:120])
            elif line.startswith(('resuming', 'building with', 'wrote', 'Traceback')) \
                    or 'Error' in line:
                self.anchor_status.setText(line[:160])

    def _anchor_finished(self, code, _status=None):
        self.proc = None
        self.b_anchor.setEnabled(True)
        self.b_anchor_stop.setVisible(False)
        if code == 0:
            self.anchor_status.setText('Done — the original-game numbers are up to date.')
            self.tab.anchor = BL.load_anchor(REPO)
            self.populate()
        else:
            self.anchor_status.setText(f'Stopped ({self.anchor_parts_done()} parts saved; '
                                       'press the button again to continue).')

    def stop_anchor(self):
        if self.proc is not None:
            self.proc.terminate()
            if not self.proc.waitForFinished(5000):
                self.proc.kill()

    def _project_widgets(self, on):
        self.apply_mode()

    def details(self):
        return bool(getattr(self.tab, 'details', True))

    def _apply_columns(self):
        prj = self.tab.s is not None
        sec = self.show_sec.isChecked()
        det = self.details()
        simple_cols = {C_FIGHT, C_VP90} | ({C_PP90, C_DELTA} if prj else set())
        for c in range(len(HEADERS)):
            if det:
                hide = (c in PRJ_COLS and not prj) or (c in SECONDARY_COLS and not sec)
            else:
                hide = c not in simple_cols
            self.tree.setColumnHidden(c, hide)
        hi = self.tree.headerItem()
        for c, t in enumerate(HEADERS):
            hi.setText(c, t)
        self.tree.header().setStretchLastSection(det)
        self.tree.setColumnWidth(C_FIGHT, 320 if det else 420)
        if not det:
            hi.setText(C_VP90, 'Original game' if prj else 'Level needed')
            hi.setText(C_PP90, 'Your project')
            hi.setText(C_DELTA, 'Change')
            self.tree.setColumnWidth(C_DELTA, 170)
            self.tree.setColumnWidth(C_VP90, 120)
            self.tree.setColumnWidth(C_PP90, 120)
        else:
            self.tree.setColumnWidth(C_DELTA, 70)
            for c in (C_VP90, C_PP90):
                self.tree.setColumnWidth(c, 72)
        for b in (self.b_casual, self.b_strong):
            b.setVisible(prj and sec and det)
        for b in (self.b_player, self.b_sel, self.dives, self.breed, self.breed_label):
            b.setVisible(prj and det)
        self.b_simple.setVisible(prj and not det)

    def apply_mode(self):
        """Simple view (default) / details: columns, rows, controls."""
        det = self.details()
        self._apply_columns()
        for w_ in (self.show_sec, self.delta_label, self.delta_prof, self.chart_label,
                   self.chart_prof, self.legend, self.help_line):
            w_.setVisible(det)
        self.simple_line.setVisible(not det)
        self.b_show_team.setVisible(not det)
        self.kit_panel.setVisible(det or self.b_show_team.isChecked())
        for k, it in self.items.items():
            if self.row_kind.get(k) == 'dive':
                it.setHidden(not det)
        self.refresh_rows()

    # ------------------------------------------------------------ rows
    def populate(self):
        """(Re)build the rows from the project's timeline (or the anchor's
        steps, or the original game's timeline) + the anchor's numbers +
        what the project's cache already knows."""
        tab = self.tab
        an = tab.anchor
        pc = tab.ctx.get(PROJECT)
        vc = tab.ctx.get(VANILLA)
        prob = anchor_problem(an)
        msgs = [prob] if prob else []
        if tab.s is not None and pc is None:
            msgs.append('Reading your project…' if PROJECT in tab.loading else
                        'Your project\'s data will be read when needed.')
        self.banner.setText(' '.join(msgs))
        self.banner.setVisible(bool(msgs))
        if self.proc is None:
            self.b_anchor.setVisible(bool(prob))
            done = self.anchor_parts_done()
            self.anchor_status.setText(f'{done} parts already saved — the build continues from '
                                       'there.' if (prob and done) else '')
        self.tree.clear()
        self.items.clear()
        self.row_kind.clear()
        self.extra_keys = []
        if pc is not None:
            self.kits_prj = {}
        if pc is not None:
            steps = [dict(s) for s in pc.tl.steps]
        elif an is not None:
            steps = [dict(s) for s in an['steps']]
        elif vc is not None:
            steps = [dict(s) for s in vc.tl.steps]
        else:
            self.update_chart()
            return
        van_steps = {s['index']: s for s in (an or {}).get('steps', [])}
        van_breed = (an or {}).get('breeding_opens', BL.BREEDING_OPENS_AFTER)
        prj_breed = pc.tl.breeding_opens if pc is not None else None
        bold = QFont(self.tree.font())
        bold.setBold(True)
        for st in steps:
            i = st['index']
            keys = list(st['fights'])
            for k in (van_steps.get(i) or {}).get('fights', []):
                if k not in keys:
                    keys.append(k)
            keys.sort(key=fight_sort_key)
            lab = f"{i + 1}. {st['label']}" + ('   (postgame)' if st.get('postgame') else '')
            top = QTreeWidgetItem([lab, st['kind']])
            top.setData(0, Qt.UserRole, ('step', i))
            top.setFont(0, bold)
            self.tree.addTopLevelItem(top)
            for k in keys:
                self._fight_row(top, k, pc, an)
            if st['kind'] == 'gate':
                for walk in BL.WALKS:
                    self._dive_row(top, st['id'], walk)
            for side, b, txt in (('van', van_breed, 'original game'),
                                 ('prj', prj_breed, 'your project')):
                if b == i and (side == 'van' or pc is not None):
                    same = pc is not None and van_breed == prj_breed
                    if side == 'prj' and same:
                        continue
                    mk = QTreeWidgetItem([f'── breeding opens here ({"both" if same else txt}) ──'])
                    mk.setData(0, Qt.UserRole, ('marker', side))
                    mk.setForeground(0, QBrush(QColor(60, 150, 60)))
                    mk.setFlags(Qt.ItemIsEnabled)
                    self.tree.addTopLevelItem(mk)
        if pc is not None and pc.extras:
            top = QTreeWidgetItem(['Outside the story (your project)', ''])
            top.setData(0, Qt.UserRole, ('extras', None))
            top.setFont(0, bold)
            self.tree.addTopLevelItem(top)
            gids = []
            for f in pc.extras:
                self._fight_row(top, f['key'], pc, None, label=f['label'])
                self.extra_keys.append(f['key'])
                if f['key'].startswith('gate') and '.f' in f['key']:
                    g = int(f['key'][4:].split('.')[0])
                    if g not in gids:
                        gids.append(g)
            for g in gids:
                for walk in BL.WALKS:
                    self._dive_row(top, g, walk)
        # what is known: the anchor + the project's cache
        if an is not None:
            for k, f in an.get('fights', {}).items():
                for prof in PROFILES:
                    if prof in f:
                        self.res[('van', prof, k)] = f[prof]
            for g, dv in an.get('dives', {}).items():
                for prof in PROFILES:
                    for walk in BL.WALKS:
                        r = dive_row_result((dv or {}).get(prof), walk)
                        if r is not None:
                            self.res[('van', prof, f'dive{g}.{walk}')] = r
        if pc is not None:
            self._peek_cache(pc)
        self.tree.expandAll()
        for k, it in self.items.items():
            if self.row_kind.get(k) == 'dive':
                it.setHidden(not self.details())
        self.refresh_rows()
        self._fill_breed(pc)

    def _fight_row(self, parent, k, pc, an, label=None):
        f = pc.fight(k) if pc is not None else None
        af = (an or {}).get('fights', {}).get(k) if an else None
        if f is None and af is None and self.tab.ctx.get(VANILLA) is not None:
            f = self.tab.ctx[VANILLA].fight(k)
        lab = label or (f['label'] if f else af['label'] if af else k)
        kind = (f or af or {}).get('kind', '')
        it = QTreeWidgetItem(parent, [lab, kind_text(kind)])
        it.setData(0, Qt.UserRole, ('fight', k))
        tip = lab
        if f is not None and af is not None and af['label'] != f['label']:
            tip += f"\noriginal game: {af['label']}"
        if pc is not None and f is None:
            tip += '\n(not in your project — the original game\'s only)'
            it.setForeground(0, QBrush(GREY))
        it.setToolTip(0, tip)
        self.items[k] = it
        self.row_kind[k] = kind
        return it

    def _dive_row(self, parent, gid, walk):
        k = f'dive{gid}.{walk}'
        lab = ('dive — straight to the stairs (lower bound)' if walk == 'direct'
               else 'dive — whole floors (upper bound)')
        it = QTreeWidgetItem(parent, [lab, 'dive'])
        it.setData(0, Qt.UserRole, ('dive', gid, walk))
        it.setToolTip(0, 'All maze floors in a row without healing (HP and MP carry), then the '
                         'boss: the team level at which 90 % of dives clear. "direct" walks '
                         'straight to the stairs (fewest battles), "sweep" walks every floor '
                         'whole (most battles): the truth lies between.')
        it.setForeground(0, QBrush(QColor(110, 110, 160)))
        self.items[k] = it
        self.row_kind[k] = 'dive'

    def _peek_cache(self, pc):
        for k in self.items:
            if k.startswith('dive'):
                g = int(k[4:].split('.')[0])
                if k.endswith('.direct'):
                    for prof in PROFILES:
                        try:
                            d = BL.cached_dive_result(pc.data, pc.tl, g, prof, pc.cache)
                        except Exception:                   # noqa: BLE001
                            d = None
                        for walk in BL.WALKS:
                            r = dive_row_result(d, walk)
                            if r is not None:
                                self.res[('prj', prof, f'dive{g}.{walk}')] = r
                continue
            f = pc.fight(k)
            if f is None:
                continue
            for prof in PROFILES:
                r = BL.cached_fight_result(pc.data, pc.tl, f, prof, pc.cache, self.tab.teams,
                                           self.tab.battles)
                if r is not None:
                    self.res[('prj', prof, k)] = r
        for st in pc.tl.steps:
            try:
                kit = BL.get_kit(pc.data, pc.tl, st['index'], pc.cache, compute=False,
                                 **self.tab.kit_budget)
            except Exception:                               # noqa: BLE001
                kit = None
            if kit:
                self.kits_prj[st['index']] = kit

    def _fill_breed(self, pc):
        self.breed.blockSignals(True)
        self.breed.clear()
        if pc is not None:
            for st in pc.tl.steps:
                self.breed.addItem(f"{st['index'] + 1}. {st['label']}", st['index'])
            i = self.breed.findData(pc.tl.breeding_opens)
            self.breed.setCurrentIndex(max(0, i))
        self.breed.blockSignals(False)

    def _breed_changed(self, _i):
        step = self.breed.currentData()
        s = self.tab.s
        if s is None or step is None or step == breeding_setting(s.doc.data):
            return
        from editor2.app.rooms import commands as C
        s.undo.push(C.SnapshotCommand(s, 'Balance: breeding opens after step',
                                      lambda doc: set_breeding_setting(doc, step)))
        self.tab.project_changed(now=True)

    # ------------------------------------------------------------ cells
    def refresh_rows(self, keys=None):
        for k in (keys if keys is not None else list(self.items)):
            it = self.items.get(k)
            if it is not None:
                self._fill(it, k)
        for i in range(self.tree.topLevelItemCount()):
            self._fill_step(self.tree.topLevelItem(i))
        self.update_chart()

    def _fill(self, it, k):
        g = self.res.get
        dive = self.row_kind.get(k) == 'dive'
        for c, side, prof, fld in LEVEL_CELLS:
            r = g((side, prof, k))
            if dive and fld == 'l50':
                it.setText(c, '')
                it.setBackground(c, QBrush())
                continue
            it.setText(c, lv_text(r, fld))
            it.setTextAlignment(c, Qt.AlignCenter)
            col = result_colour(r, fld)
            it.setBackground(c, QBrush(col) if col is not None else QBrush())
            if fld == 'l90':
                it.setToolTip(c, self._tip(r, dive, prof))
        # change: the chosen profile, project − original
        prof = self.delta_prof.currentText()
        ra, rb = g(('van', prof, k)), g(('prj', prof, k))
        a, b = lv_num(ra), lv_num(rb)
        txt, cls = '', None
        if a is not None and b is not None:
            txt, cls = delta_class(a, b)
            if a >= 100 and b >= 100:
                txt, cls = delta_beyond(ra, rb)
        it.setText(C_DELTA, txt)
        it.setTextAlignment(C_DELTA, Qt.AlignCenter)
        it.setBackground(C_DELTA, QBrush(DELTA_COLOURS[cls]) if cls else QBrush())
        it.setToolTip(C_DELTA, (f'{cls} ({prof} l90, project − original'
                                + ('; both beyond 99: the win rate at 99 compared)'
                                   if '99' in txt else ')')) if cls else
                      f'needs {prof} numbers on both sides')
        if not self.details() and not dive:
            # the simple view: the player number in words, the change in words
            for c, side in ((C_VP90, 'van'), (C_PP90, 'prj')):
                r = g((side, 'player', k))
                it.setText(c, simple_text(r))
                it.setToolTip(c, simple_tip(r))
            ra, rb = g(('van', 'player', k)), g(('prj', 'player', k))
            txt, cls = simple_change(ra, rb)
            it.setText(C_DELTA, txt)
            it.setBackground(C_DELTA, QBrush(SIMPLE_CHANGE_COLOURS[cls]) if cls else QBrush())
            it.setToolTip(C_DELTA, 'Your project against the original game (the level a '
                                   'well-built team needs).' if cls else
                          'Needs the number on both sides.')
        # unmodelled share: the project's when known, the worst profile shown
        side = 'prj' if any(g(('prj', p_, k)) for p_ in PROFILES) else 'van'
        per = {p_: ((g((side, p_, k)) or {}).get('at90') or {}).get('unmodelled') for p_ in PROFILES}
        vals = [x for x in per.values() if x is not None]
        unm = max(vals) if vals else None
        it.setText(C_UNM, '' if unm is None else f'{unm * 100:.0f} %')
        it.setTextAlignment(C_UNM, Qt.AlignCenter)
        it.setForeground(C_UNM, QBrush(QColor(200, 110, 0)) if (unm or 0) >= 0.2 else QBrush())
        it.setToolTip(C_UNM, ('project' if side == 'prj' else 'original game') + ': ' + ', '.join(
            f'{p_} {x * 100:.0f} %' for p_, x in per.items() if x is not None) +
            '\nShare of the actions at l90 that the simulator does not model (they do nothing '
            'in the simulation): the higher, the less the number can be trusted.')
        ref = None
        for p_ in PROFILES:
            ref = ref or g(('prj', p_, k))
        for p_ in PROFILES:
            ref = ref or g(('van', p_, k))
        it.setText(C_NOTE, self._note(k, ref, dive))

    def _tip(self, r, dive, prof=''):
        if r is None:
            return 'not computed'
        a = r.get('at90') or {}
        how = ''
        if prof == 'player' and not dive:
            tac = tactic_name(a.get('tactic'))
            how = (f'\narena: the best of the four tactics was {tac}' if tac else
                   '\nfought under your orders (Command) every turn')
        lv = '99' if r.get('l90') is None else r.get('l90')
        head = 'not even at 99 — ' if r.get('l90') is None else ''
        if dive:
            return (f"{head}at L{lv}: {a.get('clear', 0) * 100:.0f} % of dives clear, "
                    f"{a.get('reach_boss', 0) * 100:.0f} % reach the boss, "
                    f"~{a.get('battles', 0):.1f} battles per dive")
        ehp = a.get('enemy_hp_left')
        return (f"{head}at L{lv}: wins {a.get('win', 0) * 100:.0f} %, {a.get('rounds', 0):.1f} rounds, "
                f"{a.get('hp_left', 0) * 100:.0f} % HP left"
                + ('' if ehp is None else f", enemies left with {ehp * 100:.0f} % HP")
                + f", members reach L{a.get('team_level', 0):.1f} on average; l50 "
                f"{'99+' if r.get('l50', 0) is None else r.get('l50', '—')}" + how)

    def _note(self, k, ref, dive):
        notes = []
        a = (ref or {}).get('at90') or {}
        lv = (ref or {}).get('l90')
        if not dive:
            side = 'prj' if any(self.res.get(('prj', p_, k)) for p_ in PROFILES) else 'van'
            for p_ in PROFILES:
                r_ = self.res.get((side, p_, k)) or {}
                a_, l_ = r_.get('at90') or {}, r_.get('l90')
                if l_ and a_.get('team_level') and a_['team_level'] < l_ - 1.5:
                    notes.append(f"{p_}: members reach only L{a_['team_level']:.0f} (level caps)")
        if dive and a:
            notes.append(f"~{a.get('battles', 0):.0f} battles per dive")
        if not dive:
            for side in ('prj', 'van'):
                pr = self.res.get((side, 'player', k))
                tac = tactic_name(((pr or {}).get('at90') or {}).get('tactic'))
                if tac:
                    notes.append(f"player's best tactic: {tac}"
                                 + (' (project)' if side == 'prj' else ''))
                    break
        if k in self.extra_keys:
            prof = next((p_ for p_ in PROFILES if ('prj', p_, k) in self.res), None)
            if prof is not None:
                near = BL.nearest_vanilla(self.tab.anchor, lv_num(self.res[('prj', prof, k)]),
                                          prof, n=2)
                if near:
                    notes.append('lands like: ' + '; '.join(f'{lab} (L{v})' for _k, lab, v, _s in near))
                elif self.tab.anchor is None:
                    notes.append('(no original numbers to compare yet)')
        return ' · '.join(notes)

    def _fill_step(self, top):
        d = top.data(0, Qt.UserRole)
        if not d or d[0] not in ('step', 'extras'):
            return
        if d[0] == 'extras':
            return
        for c, side, prof, fld in LEVEL_CELLS:
            if fld != 'l90':
                continue
            vals = self._step_vals(top, side, prof)
            if not self.details():
                top.setText(c, '' if not vals else ("can't win" if max(vals) >= 100
                                                    else f'Lv {max(vals)}'))
            else:
                top.setText(c, '' if not vals else ('99+' if max(vals) >= 100 else str(max(vals))))
            top.setData(c, Qt.UserRole, max(vals) if vals else None)
            col = value_colour(max(vals)) if vals else None
            top.setBackground(c, QBrush(col) if col is not None else QBrush())
            top.setForeground(c, QBrush(GREY))
            top.setTextAlignment(c, Qt.AlignCenter)
            top.setToolTip(c, 'the hardest fight of this step (dives not counted)')

    def _step_vals(self, top, side, prof):
        out = []
        for j in range(top.childCount()):
            ch = top.child(j)
            dd = ch.data(0, Qt.UserRole)
            if dd and dd[0] == 'fight':
                n = chart_value(self.res.get((side, prof, dd[1])))
                if n is not None:
                    out.append(n)
        return out

    def update_chart(self):
        prof = self.chart_prof.currentText() if self.details() else 'player'
        van, prj, labels = {}, {}, {}
        n = 0
        post = None
        breed = []
        for i in range(self.tree.topLevelItemCount()):
            top = self.tree.topLevelItem(i)
            d = top.data(0, Qt.UserRole)
            if not d or d[0] != 'step':
                if d and d[0] == 'marker':
                    breed.append((n - 1, QColor(60, 150, 60) if d[1] == 'van' else QColor(50, 120, 220)))
                continue
            si = d[1]
            n = max(n, si + 1)
            labels[si] = top.text(0)
            if post is None and '(postgame)' in top.text(0):
                post = si
            v = self._step_vals(top, 'van', prof)
            p_ = self._step_vals(top, 'prj', prof)
            if v:
                van[si] = max(v)
            if p_:
                prj[si] = max(p_)
        self.chart.set_data(n, van, prj, post, breed, labels)

    # ------------------------------------------------------------ compute
    def selected_keys(self):
        keys = []
        for it in self.tree.selectedItems():
            d = it.data(0, Qt.UserRole)
            if not d:
                continue
            if d[0] in ('step', 'extras'):
                for j in range(it.childCount()):
                    dd = it.child(j).data(0, Qt.UserRole)
                    if dd and dd[0] == 'fight':
                        keys.append(dd[1])
                    elif dd and dd[0] == 'dive':
                        keys.append(f'dive{dd[1]}')
            elif d[0] == 'fight':
                keys.append(d[1])
            elif d[0] == 'dive':
                keys.append(f'dive{d[1]}')
        return list(dict.fromkeys(keys))

    def compute_selected(self):
        keys = self.selected_keys()
        if not keys:
            self.prog.setFormat('select rows first')
            return
        self.compute(PROFILES if self.show_sec.isChecked() else ('player',), keys)

    def compute(self, profiles, keys=None, dives=None):
        """Compute the project's numbers (profiles x fights [+ dives]) in the
        background; cached ones come back at once."""
        if self.tab.s is None or (self.task is not None and self.task.isRunning()):
            return
        dives = self.dives.isChecked() if dives is None else dives
        self._set_busy(True, 'reading your project…')
        self.tab.with_ctx(PROJECT, lambda pc: self._start(pc, profiles, keys, dives),
                          on_fail=lambda e: self._set_busy(False, 'could not read the project'))

    def _work_list(self, pc, profiles, keys, dives):
        """[(kind 'kit' | 'fight' | 'dive', key, profile)] — 'player' needs the
        step's kit first (it is optimised once per step, then cached)."""
        items = []
        last = len(pc.tl.steps) - 1
        for prof in profiles:
            kits = set()
            for st in pc.tl.steps:
                mine = []
                for k in st['fights']:
                    if keys is None or k in keys:
                        mine.append(('fight', k, prof))
                if st['kind'] == 'gate' and (keys is None and dives or
                                             keys is not None and f"dive{st['id']}" in keys):
                    mine.append(('dive', st['id'], prof))
                if mine and prof == 'player':
                    items.append(('kit', st['index'], prof))
                    kits.add(st['index'])
                items += mine
            gids = []
            for f in pc.extras:
                k = f['key']
                if keys is None or k in keys:
                    if prof == 'player' and last not in kits:
                        items.append(('kit', last, prof))
                        kits.add(last)
                    items.append(('fight', k, prof))
                if k.startswith('gate') and '.f' in k:
                    g = int(k[4:].split('.')[0])
                    if g not in gids and (keys is None and dives or
                                          keys is not None and f'dive{g}' in keys):
                        gids.append(g)
                        if prof == 'player' and last not in kits:
                            items.append(('kit', last, prof))
                            kits.add(last)
                        items.append(('dive', g, prof))
        return items

    def _start(self, pc, profiles, keys, dives):
        items = self._work_list(pc, profiles, keys, dives)
        teams, battles = self.tab.teams, self.tab.battles
        budget = dict(self.tab.kit_budget)

        def job(task):
            n = len(items)
            for i, (kind, k, prof) in enumerate(items):
                if task.is_cancelled():
                    break
                if kind == 'kit':
                    lab = f"{k + 1}. {pc.tl.steps[k]['label']}"
                    task.emit_progress(i, n, f'optimising kit for {lab}…')

                    def prog(a, b, cur, i=i, lab=lab):
                        task.emit_progress(i, n, f'optimising kit for {lab}… eval {a}/{b}, '
                                                 f'score {cur:.2f}')
                    kit = BL.get_kit(pc.data, pc.tl, k, pc.cache, progress=prog, **budget)
                    pc.cache.save()
                    task.emit_result((pc.gen, 'kit', k, prof, kit))
                    continue
                lab = (pc.tl.fights[k]['label'] if kind == 'fight' else
                       f'{pc.tl.gate_name(k)} — dive')
                task.emit_progress(i, n, f'{prof}: {lab}')
                if kind == 'fight':
                    r = BL.fight_result(pc.data, pc.tl, pc.tl.fights[k], prof, pc.cache,
                                        teams, battles)
                else:
                    r = BL.gate_dive_result(pc.data, pc.tl, k, prof, pc.cache)
                pc.cache.save()
                task.emit_result((pc.gen, kind, k, prof, r))
            return len(items)
        self.task = self.tab.run_task(job, on_progress=self._progress, on_result=self._result,
                                      on_done=self._done, uses=pc)

    def _progress(self, i, n, text):
        self.prog.setMaximum(max(1, n))
        self.prog.setValue(i)
        self.prog.setFormat(f'{i}/{n}  {text}')

    def _result(self, r):
        gen, kind, k, prof, res = r
        pc = self.tab.ctx.get(PROJECT)
        if pc is None:
            return
        if kind == 'kit':
            if pc.gen == gen:
                self.kits_prj[k] = res
                if self._kit_shown and self._kit_shown[1] == k:
                    self.show_kit(self.tree.currentItem())
            return
        if pc.gen != gen:
            # computed for data edited since: it is in the cache under its own
            # fingerprint — shown only when the current inputs are the same
            if kind == 'fight' and pc.fight(k) is not None:
                res = BL.cached_fight_result(pc.data, pc.tl, pc.fight(k), prof, pc.cache,
                                             self.tab.teams, self.tab.battles)
            elif kind == 'dive':
                res = BL.cached_dive_result(pc.data, pc.tl, k, prof, pc.cache)
            else:
                res = None
            if res is None:
                return
        if kind == 'fight':
            self.res[('prj', prof, k)] = res
            self.refresh_rows([k])
        else:
            for walk in BL.WALKS:
                rr = dive_row_result(res, walk)
                if rr is not None:
                    self.res[('prj', prof, f'dive{k}.{walk}')] = rr
            self.refresh_rows([f'dive{k}.{w}' for w in BL.WALKS])

    def _done(self, out):
        self.task = None
        if out.get('error'):
            self._set_busy(False, 'failed — see the tooltip')
            self.prog.setToolTip(out['error'])
            return
        self._set_busy(False, 'cancelled' if out.get('cancelled') else
                       f"done ({out.get('value') or 0} computed or from the cache)")
        self.prog.setValue(self.prog.maximum())

    def _set_busy(self, busy, text=''):
        for b in (self.b_player, self.b_casual, self.b_strong, self.b_sel):
            b.setEnabled(not busy)
        self.b_cancel.setEnabled(busy)
        self.prog.setFormat(text or ('working…' if busy else 'idle'))
        if not busy:
            self.prog.setToolTip('')

    def cancel(self):
        if self.task is not None:
            self.task.cancel()

    # ------------------------------------------------------------ kit view
    def show_kit(self, it):
        """The selected step's (or fight's step's) kit: the original game's
        (anchor) and the project's (computed / cached)."""
        d = it.data(0, Qt.UserRole) if it is not None else None
        step, key = None, None
        if d and d[0] == 'step':
            step = d[1]
        elif d and d[0] in ('fight', 'dive'):
            p = it.parent()
            pd = p.data(0, Qt.UserRole) if p is not None else None
            step = pd[1] if pd and pd[0] == 'step' else None
            key = d[1] if d[0] == 'fight' else None
            if pd and pd[0] == 'extras':
                step = len(BL.VANILLA_STEPS) - 1
        if step is None:
            return
        an = self.tab.anchor or {}
        vk = None
        try:
            vk = (an.get('steps') or [])[step].get('kit')
        except (IndexError, AttributeError):
            vk = None
        pk = self.kits_prj.get(step)
        ctx = self.tab.ctx.get(PROJECT) or self.tab.ctx.get(VANILLA)
        names = ctx.data.names if ctx else {}
        sk = ctx.data.skill_names if ctx else {}
        parts = []
        if self.tab.s is not None:
            parts.append(kit_html(pk, names, sk, 'Your project', key,
                                  self.res.get(('prj', 'player', key)) if key else None))
        parts.append(kit_html(vk, names, sk, 'Original game', key,
                              self.res.get(('van', 'player', key)) if key else None))
        self.kit_view.setHtml(''.join(parts))
        kit, src = (pk, PROJECT) if pk else (vk, VANILLA)
        level = None
        if key:
            side = 'prj' if src == PROJECT else 'van'
            level = (self.res.get((side, 'player', key)) or {}).get('l90')
        level = level or (kit or {}).get('level')
        self._kit_shown = (src, step, kit, level) if kit else (None, step, None, None)
        self.b_use_kit.setEnabled(bool(kit) and bool(level))
        if kit and level:
            self.b_use_kit.setText(f'Use this kit as the current team (L{level})')

    def use_kit(self):
        src, step, kit, level = self._kit_shown or (None, None, None, None)
        if kit and level:
            self.tab.team.use_kit(src, step, kit, int(level))
            self.tab.pages.setCurrentWidget(self.tab.team)

    def _open_fight(self, it, _col):
        d = it.data(0, Qt.UserRole)
        if not d:
            return
        if d[0] == 'fight':
            src = PROJECT if self.tab.s is not None else VANILLA
            self.tab.fight.show_fight(src, d[1])
            self.tab.pages.setCurrentWidget(self.tab.fight)


# ---------------------------------------------------------------------------
# page 2: the team
# ---------------------------------------------------------------------------
TEAM_COLS = ['Name', 'Monster', 'Lv / cap', 'HP', 'MP', 'ATK', 'DEF', 'AGL', 'INT', '+',
             'Skills', 'Where from']


class MemberDialog(QDialog):
    """Pick a member by hand: monster, level, plus, up to 8 skills (pre-filled
    with what the game would have taught it by that level)."""

    def __init__(self, parent, data):
        super().__init__(parent)
        self.setWindowTitle('Pick a member')
        self.data = data
        f = QFormLayout(self)
        self.sp = QComboBox()
        self.sp.setMaxVisibleItems(25)
        for sp, nm in sorted(data.names.items(), key=lambda x: x[1]):
            if sp in range(215, 221) or not BL.species_rows(data, sp):
                continue
            self.sp.addItem(f'{nm}  (#{sp})', sp)
        f.addRow('Monster', self.sp)
        self.lv = QSpinBox()
        self.lv.setRange(1, 99)
        self.lv.setValue(20)
        f.addRow('Level', self.lv)
        self.plus = QSpinBox()
        self.plus.setRange(0, 99)
        f.addRow('Plus', self.plus)
        grid = QGridLayout()
        self.sk = []
        names = sorted(((n, s) for s, n in data.skill_names.items() if n), key=lambda x: x[0])
        for i in range(8):
            c = QComboBox()
            c.setMaxVisibleItems(25)
            c.addItem('(none)', None)
            for n, s in names:
                c.addItem(n, s)
            self.sk.append(c)
            grid.addWidget(c, i // 2, i % 2)
        f.addRow('Skills', grid)
        note = QLabel('The skills start as the ones the game teaches it by that level; change '
                      'any of them.')
        note.setWordWrap(True)
        f.addRow(note)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        f.addRow(bb)
        self.sp.currentIndexChanged.connect(self._learned)
        self.lv.valueChanged.connect(self._learned)
        self._learned()

    def _learned(self, *_a):
        sp = self.sp.currentData()
        if sp is None:
            return
        try:
            m = BL.custom_member(self.data, sp, self.lv.value())
            sk = list(m.skills)
        except Exception:                                   # noqa: BLE001
            sk = []
        for i, c in enumerate(self.sk):
            c.setCurrentIndex(max(0, c.findData(sk[i])) if i < len(sk) else 0)

    def member(self):
        skills = [c.currentData() for c in self.sk if c.currentData() is not None]
        return BL.custom_member(self.data, self.sp.currentData(), self.lv.value(),
                                list(dict.fromkeys(skills)), self.plus.value())


class TeamPage(QWidget):
    def __init__(self, tab):
        super().__init__()
        self.tab = tab
        self.team = []
        self.team_src = None
        self.team_note = ''
        self._roll_task = None
        v = QVBoxLayout(self)
        box = QGroupBox('Roll a team a player might have')
        g = QGridLayout(box)
        self.src = QComboBox()
        self.src.addItem(SRC_LABEL[VANILLA], VANILLA)
        if tab.s is not None:
            self.src.addItem(SRC_LABEL[PROJECT], PROJECT)
            self.src.setCurrentIndex(1)
        self.src.currentIndexChanged.connect(lambda _i: self._load_steps())
        self.prof = QComboBox()
        self.prof.addItems(PROFILES)
        self.step = QComboBox()
        self.step.setMinimumWidth(260)
        self.level = QSpinBox()
        self.level.setRange(1, 99)
        self.level.setValue(15)
        self.tno = QSpinBox()
        self.tno.setRange(0, 9999)
        self.tno.setToolTip(f'Team number: 0-{TEAMS - 1} are the very teams the numbers use '
                            '(each fight: those teams, several battles each).')
        self.b_roll = QPushButton('Roll')
        self.b_roll.clicked.connect(self.roll)
        self.b_reroll = QPushButton('Reroll')
        self.b_reroll.setToolTip('The next team number.')
        self.b_reroll.clicked.connect(self.reroll)
        self.grid_labels = {}
        for c, (lab, w) in enumerate((('Data', self.src), ('Profile', self.prof),
                                      ('Story step', self.step), ('Team level', self.level),
                                      ('Team #', self.tno))):
            self.grid_labels[lab] = QLabel(lab)
            g.addWidget(self.grid_labels[lab], 0, c)
            g.addWidget(w, 1, c)
        g.addWidget(self.b_roll, 1, 5)
        g.addWidget(self.b_reroll, 1, 6)
        v.addWidget(box)
        row = QHBoxLayout()
        self.b_sav = QPushButton('Import party from .sav…')
        self.b_sav.setToolTip('The party (up to 3) of a battery save (.sav) of the game or of '
                              'a build of your project.')
        self.b_sav.clicked.connect(self._import_dialog)
        self.b_pick = QPushButton('Pick member…')
        self.b_pick.setToolTip('Add a member (or replace the selected one): monster, level, '
                               'plus, skills.')
        self.b_pick.clicked.connect(self._pick_dialog)
        self.b_remove = QPushButton('Remove member')
        self.b_remove.clicked.connect(self.remove_selected)
        for b in (self.b_sav, self.b_pick, self.b_remove):
            row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)
        self.summary = QLabel('No team yet: roll one, import a party or pick members.')
        self.summary.setWordWrap(True)
        v.addWidget(self.summary)
        self.table = QTableWidget(0, len(TEAM_COLS))
        self.table.setHorizontalHeaderLabels(TEAM_COLS)
        self.table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.table.horizontalHeader().setStretchLastSection(True)
        self.table.horizontalHeader().setSectionResizeMode(10, QHeaderView.Stretch)
        v.addWidget(self.table, 1)
        hl = QLabel('Rolled teams follow the model the numbers use: every member has the same '
                    'exp (on the most common exp curve the team level is that exp; slower '
                    'monsters are a few levels behind), members stuck at their level cap well '
                    'below the team are swapped, and bred members appear once breeding has '
                    'opened. The Fight page fights with this team.')
        hl.setWordWrap(True)
        hl.setStyleSheet('color:#888;')
        v.addWidget(hl)

    def source(self):
        return self.src.currentData()

    def apply_mode(self):
        """Simple view: the player profile only (the step's best team)."""
        det = self.tab.details
        if not det:
            self.prof.setCurrentText('player')
        self.prof.setVisible(det)
        self.grid_labels['Profile'].setVisible(det)

    def activate(self):
        if self.step.count() == 0:
            self._load_steps()

    def _load_steps(self):
        src = self.source()

        def fill(ctx):
            cur = self.step.currentData()
            self.step.clear()
            for st in ctx.tl.steps:
                self.step.addItem(f"{st['index'] + 1}. {st['label']}"
                                  + ('  (breeding open)' if st['breeding'] else ''), st['index'])
            i = self.step.findData(cur)
            self.step.setCurrentIndex(i if i >= 0 else 0)
        self.tab.with_ctx(src, fill)

    # -------------------------------------------------------------- roll
    def reroll(self):
        self.tno.setValue(self.tno.value() + 1)
        self.roll()

    def roll(self):
        src, prof = self.source(), self.prof.currentText()
        lvl, t = self.level.value(), self.tno.value()

        def go(ctx):
            si = self.step.currentData()
            if si is None:
                si = 0
            label = self.step.currentText()

            budget = dict(self.tab.kit_budget)

            def job(task):
                kit = None
                if prof == 'player':          # the step's kit first (cached / anchor / search)
                    task.emit_progress(0, 1, f'optimising kit for {label}…')
                    kit = BL.get_kit(ctx.data, ctx.tl, si, ctx.cache, progress=lambda a, b, c:
                                     task.emit_progress(a, b, f'optimising kit for {label}… '
                                                              f'eval {a}/{b}'), **budget)
                    if ctx.cache is not None:
                        ctx.cache.save()
                return BL.team_for(ctx.data, ctx.tl, si, lvl, prof, t), kit

            def done(out):
                self._roll_task = None
                if out.get('error'):
                    self.summary.setText('Rolling failed: ' + out['error'].splitlines()[0])
                    return
                if out.get('value'):
                    team, kit = out['value']
                    what = (f"the player kit of {label} (optimised at L{kit.get('level', '?')})"
                            if kit else f'{prof} team #{t} at {label}')
                    self.set_team([m.copy() for m in team], src,
                                  f'Rolled {what}, team level {lvl} ({SRC_LABEL[src].lower()}).')
                    if kit and src == PROJECT:
                        self.tab.story.kits_prj[si] = kit
            self.summary.setText('Optimising the step\'s kit (minutes unless cached)…'
                                 if prof == 'player' else 'Rolling…')
            self._roll_task = self.tab.run_task(
                job, on_progress=lambda a, b, txt: self.summary.setText(txt), on_done=done,
                uses=ctx)
        self.tab.with_ctx(src, go)

    def use_kit(self, src, step, kit, level):
        """A kit (the Story page's kit view) at `level` becomes the team."""
        def go(ctx):
            def job(_task):
                BL.set_kit(ctx.data, ctx.tl, step, kit)
                from editor2.core import kits as KT
                return KT.kit_team(ctx.data, ctx.tl, step, kit, level, 0)

            def done(out):
                if out.get('error'):
                    self.summary.setText('Could not raise the kit: ' + out['error'].splitlines()[0])
                    return
                lab = ctx.tl.steps[step]['label'] if 0 <= step < len(ctx.tl.steps) else step
                self.set_team([m.copy() for m in out['value']], src,
                              f'The player kit of {step + 1}. {lab} at team level {level} '
                              f'({SRC_LABEL[src].lower()}).')
            self.summary.setText('Raising the kit…')
            self.tab.run_task(job, on_done=done, uses=ctx)
        self.tab.with_ctx(src, go)

    # -------------------------------------------------------------- edit
    def set_team(self, team, src, note):
        self.team = list(team)[:3]
        self.team_src = src
        self.team_note = note
        self.refresh()

    def refresh(self):
        ctx = self.tab.ctx.get(self.team_src if self.team_src in (VANILLA, PROJECT) else None) \
            or self.tab.ctx.get(PROJECT) or self.tab.ctx.get(VANILLA)
        sk_names = ctx.data.skill_names if ctx else {}
        self.table.setRowCount(len(self.team))
        for r, m in enumerate(self.team):
            name = m.nickname or ''
            vals = [name, m.name or f'#{m.species}', f'{m.level} / {m.cap}'] + \
                [str(x) for x in m.stats] + [str(m.plus),
                                             ', '.join(sk_names.get(s, f'#{s}') for s in m.skills),
                                             m.origin]
            for c, val in enumerate(vals):
                it = QTableWidgetItem(val)
                if 2 <= c <= 9:
                    it.setTextAlignment(Qt.AlignCenter)
                self.table.setItem(r, c, it)
        self.table.resizeColumnsToContents()
        if self.team:
            lv = sum(m.level for m in self.team) / len(self.team)
            self.summary.setText(f'{self.team_note}  Members average L{lv:.1f}.')
        else:
            self.summary.setText('No team yet: roll one, import a party or pick members.')
        self.tab.fight.team_changed()

    def remove_selected(self):
        rows = sorted({i.row() for i in self.table.selectedIndexes()}, reverse=True)
        for r in rows:
            if r < len(self.team):
                self.team.pop(r)
        if rows:
            self.team_note = 'Edited team.'
            self.refresh()

    def add_member(self, m):
        rows = sorted({i.row() for i in self.table.selectedIndexes()})
        if rows and rows[0] < len(self.team):
            self.team[rows[0]] = m
        elif len(self.team) < 3:
            self.team.append(m)
        else:
            self.team[-1] = m
        if not self.team_note.startswith('Edited'):
            self.team_note = 'Edited team (members picked by hand).'
        self.refresh()

    def _pick_dialog(self):
        def go(ctx):
            dlg = MemberDialog(self, ctx.data)
            if dlg.exec() == QDialog.Accepted:
                try:
                    self.add_member(dlg.member())
                except Exception as e:                      # noqa: BLE001
                    QMessageBox.warning(self, 'Pick member', str(e))
        self.tab.with_ctx(self.source(), go)

    def import_sav(self, path, ctx=None):
        """Load the save's party as the team -> None, or the problem."""
        from editor2.core import savefile as SF
        ctx = ctx or self.tab.ctx.get(self.source()) or self.tab.ctx.get(PROJECT) \
            or self.tab.ctx.get(VANILLA)
        names = ctx.data.names if ctx else None
        try:
            team = SF.party_team(path, names)
        except Exception as e:                              # noqa: BLE001
            return f'Could not read {os.path.basename(path)}: {e}'
        if not team:
            return f'{os.path.basename(path)} has no party.'
        self.set_team(team, self.source(), f'Party of {os.path.basename(path)}.')
        return None

    def _import_dialog(self):
        path, _f = QFileDialog.getOpenFileName(self, 'Import the party of a save', '',
                                               'Battery saves (*.sav *.srm);;All files (*)')
        if not path:
            return

        def go(ctx):
            err = self.import_sav(path, ctx)
            if err:
                QMessageBox.warning(self, 'Import party', err)
        self.tab.with_ctx(self.source(), go)


# ---------------------------------------------------------------------------
# page 3: one fight, what-if
# ---------------------------------------------------------------------------
ENEMY_COLS = ['Battle', 'EID', 'Monster', 'Lv', 'HP', 'MP', 'ATK', 'DEF', 'AGL', 'INT', 'Skills']
RES_ROWS = [('win', 'Win %'), ('rounds', 'Rounds'), ('hp_left', 'HP left'),
            ('enemy_hp_left', 'Enemy HP left'),
            ('unmodelled', 'Unmodelled'), ('team_level', 'Team level'), ('l90', 'Level for 90 %'),
            ('l50', 'Level for 50 %'), ('how', 'How it fought')]


def how_text(prof, fight, ev):
    """How a fight was fought, in words (the Fight page's last result row)."""
    if prof != 'player':
        return 'own AI tactics'
    if fight.get('db73') == 2:
        t = tactic_name((ev or {}).get('tactic'))
        return f'arena: best tactic {t}' if t else 'arena: best of the 4 tactics'
    return 'your orders (Command)'


class FightPage(QWidget):
    def __init__(self, tab):
        super().__init__()
        self.tab = tab
        self.cur = None                 # (src, key)
        self.before, self.after = {}, {}
        self._task = None
        v = QVBoxLayout(self)
        row = QHBoxLayout()
        self.src = QComboBox()
        self.src.addItem(SRC_LABEL[VANILLA], VANILLA)
        if tab.s is not None:
            self.src.addItem(SRC_LABEL[PROJECT], PROJECT)
            self.src.setCurrentIndex(1)
        self.src.currentIndexChanged.connect(lambda _i: self._load_fights())
        row.addWidget(QLabel('Data'))
        row.addWidget(self.src)
        self.fights = QComboBox()
        self.fights.setMaxVisibleItems(30)
        self.fights.setMinimumWidth(420)
        self.fights.currentIndexChanged.connect(self._picked)
        row.addWidget(QLabel('Fight'))
        row.addWidget(self.fights, 1)
        v.addLayout(row)
        split = QSplitter(Qt.Vertical)
        self.enemies = QTableWidget(0, len(ENEMY_COLS))
        self.enemies.setHorizontalHeaderLabels(ENEMY_COLS)
        self.enemies.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.enemies.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.enemies.horizontalHeader().setStretchLastSection(True)
        self.enemies.verticalHeader().setVisible(False)
        self.enemies.itemSelectionChanged.connect(self._enemy_row_picked)
        split.addWidget(self.enemies)
        low = QWidget()
        lh = QHBoxLayout(low)
        lh.setContentsMargins(0, 0, 0, 0)
        # what-if editor
        wb = QGroupBox('What-if (simulator only — never saved)')
        wg = QGridLayout(wb)
        self.w_enemy = QComboBox()
        self.w_enemy.currentIndexChanged.connect(self._load_enemy)
        wg.addWidget(QLabel('Enemy'), 0, 0)
        wg.addWidget(self.w_enemy, 0, 1, 1, 3)
        self.w_level = QSpinBox()
        self.w_level.setRange(1, 99)
        wg.addWidget(QLabel('Level'), 1, 0)
        wg.addWidget(self.w_level, 1, 1)
        self.w_stats = {}
        for i, k in enumerate(STAT_KEYS):
            sb = QSpinBox()
            sb.setRange(0, 9999)
            self.w_stats[k] = sb
            r, c = divmod(i, 2)
            wg.addWidget(QLabel(k.upper()), 2 + r, c * 2)
            wg.addWidget(sb, 2 + r, c * 2 + 1)
        self.w_skills = []
        for i in range(4):
            cb = QComboBox()
            cb.setMaxVisibleItems(25)
            self.w_skills.append(cb)
            wg.addWidget(QLabel(f'Skill {i + 1}'), 5 + i // 2, (i % 2) * 2)
            wg.addWidget(cb, 5 + i // 2, (i % 2) * 2 + 1)
        brow = QHBoxLayout()
        self.b_apply = QPushButton('Apply what-if')
        self.b_apply.clicked.connect(self.apply_whatif)
        self.b_reset1 = QPushButton('Reset this enemy')
        self.b_reset1.clicked.connect(lambda: self.reset_whatif(one=True))
        self.b_reset = QPushButton('Reset what-if')
        self.b_reset.clicked.connect(lambda: self.reset_whatif())
        for b in (self.b_apply, self.b_reset1, self.b_reset):
            brow.addWidget(b)
        wg.addLayout(brow, 7, 0, 1, 4)
        self.w_note = QLabel('')
        self.w_note.setWordWrap(True)
        wg.addWidget(self.w_note, 8, 0, 1, 4)
        tip = QLabel('An enemy row\'s stats are its own numbers, not made from its level: a '
                     'new level alone changes little — change the stats too.')
        tip.setWordWrap(True)
        tip.setStyleSheet('color:#888;')
        wg.addWidget(tip, 9, 0, 1, 4)
        wg.setRowStretch(10, 1)
        lh.addWidget(wb)
        # runs + results
        rb = QGroupBox('How it goes')
        rv = QVBoxLayout(rb)
        r1 = QHBoxLayout()
        self.b_team = QPushButton('Evaluate current team')
        self.b_team.setToolTip('The Team page\'s team at its own levels: many battles, as is '
                               'and with the what-if.')
        self.b_team.clicked.connect(self.eval_team)
        self.n_battles = QSpinBox()
        self.n_battles.setRange(4, 2000)
        self.n_battles.setValue(64)
        self.n_battles.setSuffix(' battles')
        self.orders = QComboBox()
        self.orders.addItem('under your orders (player)', 'player')
        self.orders.addItem('on its own AI tactics', 'ai')
        self.orders.setToolTip('Under your orders: every turn the battle menu\'s Command (the '
                               'planner); in the arena, where the menu has no Command, the best '
                               'of the four tactics. On its own AI: each member\'s tactic, as the '
                               'casual / strong numbers fight.')
        r1.addWidget(self.b_team)
        r1.addWidget(self.n_battles)
        r1.addWidget(self.orders)
        r1.addStretch(1)
        rv.addLayout(r1)
        r2 = QHBoxLayout()
        self.b_level = QPushButton('Level needed (rolled teams)')
        self.b_level.setToolTip('The smallest team level whose rolled teams win 90 % / 50 %, '
                                'as is and with the what-if (casual: seconds; strong: about '
                                'a minute per side).')
        self.b_level.clicked.connect(self.level_needed)
        self.prof = QComboBox()
        self.prof.addItems(PROFILES)
        self.b_stop = QPushButton('Cancel')
        self.b_stop.setEnabled(False)
        self.b_stop.clicked.connect(self.cancel)
        r2.addWidget(self.b_level)
        r2.addWidget(self.prof)
        r2.addWidget(self.b_stop)
        r2.addStretch(1)
        rv.addLayout(r2)
        self.status = QLabel('')
        self.status.setWordWrap(True)
        rv.addWidget(self.status)
        note = QLabel('After "Level needed" the rates are those at the level found — or at 99 '
                      'when even 99 falls short.')
        note.setWordWrap(True)
        note.setStyleSheet('color:#888;')
        rv.addWidget(note)
        self.results = QTableWidget(len(RES_ROWS), 3)
        self.results.setHorizontalHeaderLabels(['As is', 'What-if', 'Change'])
        self.results.setVerticalHeaderLabels([lab for _k, lab in RES_ROWS])
        tips = {'enemy_hp_left': 'The enemies\' HP left at the end of a battle (of their full '
                                 'HP, mean over the battles): the best reading for a fight the '
                                 'team cannot win — a what-if that takes it from 80 % to 30 % '
                                 'matters even at 0 % wins.',
                'hp_left': 'Your team\'s HP left (of its full HP).',
                'unmodelled': 'Actions the simulator does not model (they do nothing).'}
        for i, (k, _lab) in enumerate(RES_ROWS):
            if k in tips:
                self.results.verticalHeaderItem(i).setToolTip(tips[k])
        self.results.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.results.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        rv.addWidget(self.results, 1)
        lh.addWidget(rb, 1)
        split.addWidget(low)
        split.setStretchFactor(0, 1)
        split.setStretchFactor(1, 2)
        split.setSizes([200, 420])
        v.addWidget(split, 1)

    def source(self):
        return self.src.currentData()

    def ctx(self):
        return self.tab.ctx.get(self.source())

    SIMPLE_ROWS = {'win': 'Wins', 'rounds': 'Length', 'hp_left': 'Your HP',
                   'enemy_hp_left': 'Enemy HP', 'l90': 'Level needed', 'how': 'How it fought'}

    def apply_mode(self):
        """Simple view: player only (orders), results in words."""
        det = self.tab.details
        if not det:
            self.prof.setCurrentText('player')
            self.orders.setCurrentIndex(0)
        self.prof.setVisible(det)
        self.orders.setVisible(det)
        labels = [lab if det else self.SIMPLE_ROWS.get(k, lab) for k, lab in RES_ROWS]
        self.results.setVerticalHeaderLabels(labels)
        for i, (k, _lab) in enumerate(RES_ROWS):
            self.results.setRowHidden(i, not det and k not in self.SIMPLE_ROWS)
        self.show_results()

    def activate(self):
        if self.fights.count() == 0:
            self._load_fights()

    def _load_fights(self, select=None):
        src = self.source()

        def fill(ctx):
            want = select or (self.fights.currentData() if self.fights.count() else None)
            self.fights.blockSignals(True)
            self.fights.clear()
            for f, stl in ctx.all_fights():
                num = stl.split('. ', 1)[0]
                self.fights.addItem(f"{num}. {f['label']}" if num.isdigit()
                                    else f"(outside the story) {f['label']}", f['key'])
            for sb in self.w_skills:
                sb.blockSignals(True)
                sb.clear()
                sb.addItem('(none)', None)
                for s, n in sorted(ctx.data.skill_names.items(), key=lambda x: x[1]):
                    if n:
                        sb.addItem(n, s)
                sb.blockSignals(False)
            i = self.fights.findData(want) if want else -1
            self.fights.setCurrentIndex(i if i >= 0 else 0)
            self.fights.blockSignals(False)
            self._picked()
        self.tab.with_ctx(src, fill)

    def show_fight(self, src, key):
        i = self.src.findData(src)
        if i >= 0 and i != self.src.currentIndex():
            self.src.blockSignals(True)
            self.src.setCurrentIndex(i)
            self.src.blockSignals(False)
        self._load_fights(select=key)

    def fight(self):
        ctx = self.ctx()
        k = self.fights.currentData()
        return (ctx.fight(k) if ctx and k else None)

    def _picked(self, *_a):
        self.before, self.after = {}, {}
        self.show_results()
        self.refresh_enemies()
        f = self.fight()
        self.w_enemy.blockSignals(True)
        self.w_enemy.clear()
        ctx = self.ctx()
        if f is not None and ctx is not None:
            for e in f['eids']:
                self.w_enemy.addItem(f'{ctx.data.enemy_name(e)}  (EID {e})', e)
        self.w_enemy.blockSignals(False)
        self._load_enemy()

    def refresh_enemies(self):
        f, ctx = self.fight(), self.ctx()
        self.enemies.setRowCount(0)
        if f is None or ctx is None:
            return
        W = ctx.whatif
        rows = []
        for gi, (p, eids) in enumerate(f['groups']):
            for e in eids:
                rows.append((gi, p, e))
        self.enemies.setRowCount(len(rows))
        bold = QFont(self.enemies.font())
        bold.setBold(True)
        for r, (gi, p, e) in enumerate(rows):
            base = ctx.data.enemy_rec(e)
            rec = W.enemy_rec(e)
            sk = ', '.join(ctx.data.skill_names.get(s, f'#{s}') for s in rec['skills'])
            vals = [(f'#{gi + 1}  {p * 100:.0f} %', None), (str(e), None),
                    (ctx.data.enemy_name(e), None), (str(rec['level']), 'level')] + \
                [(str(rec[k]), k) for k in STAT_KEYS] + [(sk, 'skills')]
            for c, (val, k) in enumerate(vals):
                it = QTableWidgetItem(val)
                it.setData(Qt.UserRole, e)
                if k is not None and rec[k] != base[k]:
                    it.setFont(bold)
                    it.setForeground(QBrush(QColor(200, 90, 0)))
                    it.setToolTip(f'what-if; as is: {base[k]}' if k != 'skills' else
                                  'what-if; as is: ' + ', '.join(
                                      ctx.data.skill_names.get(s, f'#{s}') for s in base['skills']))
                self.enemies.setItem(r, c, it)
        self.enemies.resizeColumnsToContents()
        ov = [e for e in W.enemy_overrides]
        self.w_note.setText('What-if on: ' + ', '.join(f'{ctx.data.enemy_name(e)} (EID {e})'
                                                        for e in ov) if ov else 'No what-if.')

    def _enemy_row_picked(self):
        it = self.enemies.currentItem()
        if it is None:
            return
        i = self.w_enemy.findData(it.data(Qt.UserRole))
        if i >= 0:
            self.w_enemy.setCurrentIndex(i)

    def _load_enemy(self, *_a):
        ctx, e = self.ctx(), self.w_enemy.currentData()
        if ctx is None or e is None:
            return
        rec = ctx.whatif.enemy_rec(e)
        self.w_level.setValue(rec['level'])
        for k in STAT_KEYS:
            self.w_stats[k].setValue(rec[k])
        for i, cb in enumerate(self.w_skills):
            s = rec['skills'][i] if i < len(rec['skills']) else None
            j = cb.findData(s) if s is not None else 0
            if j < 0:
                cb.addItem(f'#{s}', s)
                j = cb.count() - 1
            cb.setCurrentIndex(j)

    def apply_whatif(self, eid=None, **fields):
        """Apply the what-if editor's values (or `fields`) to enemy `eid`."""
        ctx = self.ctx()
        e = self.w_enemy.currentData() if eid is None else eid
        if ctx is None or e is None:
            return
        if not fields:
            fields = {'level': self.w_level.value(),
                      'skills': [cb.currentData() for cb in self.w_skills
                                 if cb.currentData() is not None]}
            fields.update({k: sb.value() for k, sb in self.w_stats.items()})
        base = ctx.data.enemy_rec(e)
        changed = {k: v for k, v in fields.items() if base.get(k) != v}
        ctx.whatif.override_enemy(e, **changed)
        self.after = {}
        self.refresh_enemies()
        if self.w_enemy.currentData() == e:
            self._load_enemy()
        self.show_results()

    def reset_whatif(self, one=False):
        ctx = self.ctx()
        if ctx is None:
            return
        if one:
            e = self.w_enemy.currentData()
            if e is not None:
                ctx.whatif.override_enemy(e)
        else:
            ctx.whatif.enemy_overrides.clear()
        self.after = {}
        self.refresh_enemies()
        self._load_enemy()
        self.show_results()

    def team_changed(self):
        self.before, self.after = {}, {}
        self.show_results()

    # ---------------------------------------------------------------- runs
    def _busy(self, on, text=''):
        self.b_team.setEnabled(not on)
        self.b_level.setEnabled(not on)
        self.b_stop.setEnabled(on)
        self.status.setText(text)

    def cancel(self):
        if self._task is not None:
            self._task.cancel()

    def eval_team(self):
        team = list(self.tab.team.team)
        f, ctx = self.fight(), self.ctx()
        if f is None or ctx is None:
            return
        if not team:
            self.status.setText('No team: roll, import or pick one on the Team page first.')
            return
        n = self.n_battles.value()
        lv = round(sum(m.level for m in team) / len(team))
        W = ctx.whatif if ctx.whatif.enemy_overrides else None
        prof = 'player' if self.orders.currentData() == 'player' else 'casual'

        def job(_task):
            b = BL.evaluate(ctx.data, ctx.tl, f, lv, prof, team_list=[team], battles=n)
            a = BL.evaluate(W, ctx.tl, f, lv, prof, team_list=[team], battles=n) if W else None
            for d in (b, a):
                if d is not None:
                    d['how'] = how_text(prof, f, d)
            return b, a
        self._run(job, 'Fighting…', lambda v: self._got(v[0], v[1], keep_levels=True))

    def level_needed(self):
        f, ctx = self.fight(), self.ctx()
        if f is None or ctx is None:
            return
        prof = self.prof.currentText()
        W = ctx.whatif if ctx.whatif.enemy_overrides else None
        teams, battles = self.tab.teams, self.tab.battles
        known = None
        if ctx.src == VANILLA and self.tab.anchor and anchor_problem(self.tab.anchor) is None:
            known = ((self.tab.anchor.get('fights') or {}).get(f['key']) or {}).get(prof)
        elif ctx.cache is not None and prof != 'player':
            known = BL.cached_fight_result(ctx.data, ctx.tl, f, prof, ctx.cache, teams, battles)
        step = f['step'] if f['step'] is not None else len(ctx.tl.steps) - 1
        budget = dict(self.tab.kit_budget)
        label = f"{step + 1}. {ctx.tl.steps[step]['label']}"

        def job(task):
            b0 = known
            if prof == 'player':
                # the step's kit (cached / anchor / optimised now); the what-if
                # fights with the SAME kit — how much the change matters to it
                task.emit_progress(0, 1, f'optimising kit for {label}…')
                kit = BL.get_kit(ctx.data, ctx.tl, step, ctx.cache, progress=lambda a_, b_, c_:
                                 task.emit_progress(a_, b_, f'optimising kit for {label}… '
                                                            f'eval {a_}/{b_}'), **budget)
                if ctx.cache is not None:
                    ctx.cache.save()
                    b0 = b0 or BL.cached_fight_result(ctx.data, ctx.tl, f, prof, ctx.cache,
                                                      teams, battles)
                BL.set_kit(ctx.whatif, ctx.tl, step, kit)
                task.emit_progress(0, 1, f'Searching the level ({prof})…')
            b = b0 or BL.fight_levels(ctx.data, ctx.tl, f, prof, teams, battles)
            a = BL.fight_levels(W, ctx.tl, f, prof, teams, battles) if W else None
            for d in (b, a):
                if d is not None:
                    d['how'] = how_text(prof, f, d.get('at90') or {})
            return b, a
        self._run(job, f'Searching the level ({prof}{"" if W is None else ", both sides"})…',
                  lambda v: self._got(self._flat(v[0]), self._flat(v[1]) if v[1] else None))

    @staticmethod
    def _flat(r):
        d = dict((r or {}).get('at90') or {})
        d['l90'] = r.get('l90') if r else None
        d['l50'] = r.get('l50') if r else None
        if r and r.get('how'):
            d['how'] = r['how']
        d['_levels'] = True
        return d

    def _run(self, job, text, cb):
        if self._task is not None:
            return
        self._busy(True, text)

        def done(out):
            self._task = None
            if out.get('error'):
                self._busy(False, 'Failed: ' + out['error'].splitlines()[0])
                return
            if out.get('cancelled'):
                self._busy(False, 'Cancelled.')
                return
            self._busy(False, '')
            cb(out['value'])
        self._task = self.tab.run_task(job, on_progress=lambda _a, _b, t: self.status.setText(t),
                                       on_done=done, uses=self.ctx())

    def _got(self, before, after, keep_levels=False):
        if keep_levels:                 # a team run keeps the level search's rows
            for d in (self.before, self.after):
                for k in [k for k in d if k not in ('l90', 'l50', '_levels')]:
                    d.pop(k)
            self.before.update(before or {})
            if after:
                self.after.update(after)
        else:
            self.before = dict(before or {})
            self.after = dict(after or {})
        self.show_results()

    def show_results(self):
        simple = not self.tab.details

        def fmt(k, d):
            if not d or k not in d:
                return ''
            x = d[k]
            if k == 'how':
                return str(x)
            if simple:
                if k == 'win':
                    return f'wins {round(x * 10)} of 10'
                if k == 'rounds':
                    return f'about {round(x)} rounds'
                if k == 'hp_left':
                    return f'HP left {x * 100:.0f} %'
                if k == 'enemy_hp_left':
                    return f'enemies keep {x * 100:.0f} % HP'
                if k == 'l90':
                    return f'Lv {x}' if x is not None else "can't win at 99"
            if k in ('l90', 'l50'):
                return '99+' if x is None else str(x)
            if k in ('win', 'hp_left', 'unmodelled', 'enemy_hp_left'):
                return f'{x * 100:.0f} %'
            return f'{x:.1f}'
        for r, (k, _lab) in enumerate(RES_ROWS):
            b, a = fmt(k, self.before), fmt(k, self.after)
            ch = ''
            if b and a and k in self.before and k in self.after and k != 'how':
                x, y = self.before[k], self.after[k]
                if k in ('l90', 'l50'):
                    x, y = (100 if x is None else x), (100 if y is None else y)
                    ch = ('+' if y > x else '') + str(y - x) if y != x else '='
                else:
                    m = 100 if k in ('win', 'hp_left', 'unmodelled', 'enemy_hp_left') else 1
                    d = (y - x) * m
                    ch = f'{d:+.0f}' + (' %' if m == 100 else '') if m == 100 else f'{d:+.1f}'
            for c, val in enumerate((b, a if self.after else '—' if b else '', ch)):
                it = QTableWidgetItem(val)
                it.setTextAlignment(Qt.AlignCenter)
                d = (self.before, self.after)[c] if c < 2 else None
                if k in ('l90', 'l50') and d and k in d:
                    w = d.get('win')
                    col = level_colour(d[k]) if d[k] is not None else \
                        level_colour(100, None if w is None else 1 - w)
                    it.setBackground(QBrush(col))
                self.results.setItem(r, c, it)


# ---------------------------------------------------------------------------
# the tab
# ---------------------------------------------------------------------------
class BalanceTab(QWidget):
    def __init__(self, session=None, parent=None, anchor=None):
        super().__init__(parent)
        self.s = session
        self.anchor = anchor
        self._anchor_given = anchor is not None
        self.ctx = {}
        self.loading = set()
        self._waiters = {}
        self._gen = 0
        self.tasks = {}                  # Task -> (relay, ctx ids)
        self.retired = []                # dropped contexts whose memos await purging
        self._caches = {}                # project cache path -> FightCache
        self._whatif_keep = {}           # the project what-if across a re-read
        self.started = False
        self.teams, self.battles = TEAMS, BATTLES
        self.kit_budget = {}             # kits.step_kit knobs (tests: tiny); {} = KIT_BUDGET
        # S130 (user: "really crowded and I dont really understand all the numbers"):
        # a simple view by default; "Show details" = every profile, column and row
        try:
            self.details = QSettings('dwm1_disassembly', 'DWM1Editor').value(
                'balance/details', False, type=bool)
        except Exception:                                   # noqa: BLE001
            self.details = False
        v = QVBoxLayout(self)
        v.setContentsMargins(4, 4, 4, 4)
        top = QHBoxLayout()
        top.addStretch(1)
        self.cb_details = QCheckBox('Show details')
        self.cb_details.setToolTip('Every profile (player, casual, strong), both levels (90 % and '
                                   '50 %), gate dives, the unmodelled share and notes. Off = the '
                                   'simple view: one number per fight.')
        self.cb_details.setChecked(self.details)
        self.cb_details.toggled.connect(self.set_details)
        top.addWidget(self.cb_details)
        v.addLayout(top)
        self.pages = QTabWidget()
        self.story = StoryPage(self)
        self.team = TeamPage(self)
        self.fight = FightPage(self)
        self.pages.addTab(self.story, 'Story curve')
        self.pages.addTab(self.team, 'Team')
        self.pages.addTab(self.fight, 'Fight')
        self.pages.currentChanged.connect(self._page)
        v.addWidget(self.pages)
        self.team.apply_mode()
        self.fight.apply_mode()
        self._reload_timer = QTimer(self)
        self._reload_timer.setSingleShot(True)
        self._reload_timer.timeout.connect(self._reload_project)
        if session is not None:
            session.undo.indexChanged.connect(self._undo_moved)

    # ------------------------------------------------------------ lifecycle
    def showEvent(self, ev):
        super().showEvent(ev)
        self.start()
        if self.s is not None and PROJECT not in self.ctx and PROJECT not in self.loading \
                and self.started:
            self._reload_timer.start(300)

    def start(self):
        """Load the anchor, show the rows, read the data in the background."""
        if self.started:
            return
        self.started = True
        if not self._anchor_given:
            self.anchor = BL.load_anchor(REPO)
        self.story.populate()
        if self.s is not None:
            self.with_ctx(PROJECT, lambda _c: None)      # _project_loaded fills the rows
        elif self.anchor is None:
            self.with_ctx(VANILLA, lambda _c: self.story.populate())

    def _page(self, i):
        w = self.pages.widget(i)
        if w is self.team:
            self.team.activate()
        elif w is self.fight:
            self.fight.activate()

    def set_details(self, on):
        """Simple view (off) / details (on), remembered."""
        self.details = bool(on)
        try:
            QSettings('dwm1_disassembly', 'DWM1Editor').setValue('balance/details', self.details)
        except Exception:                                   # noqa: BLE001
            pass
        self.story.apply_mode()
        self.team.apply_mode()
        self.fight.apply_mode()

    def _undo_moved(self, _i):
        self.project_changed()

    def project_changed(self, now=False):
        """The project was edited: its data context is stale (re-read when the
        tab is visible, else the next time it is needed)."""
        if self.s is None:
            return
        old = self.ctx.pop(PROJECT, None)
        self._gen += 1
        if old is not None:
            self._whatif_keep = dict(old.whatif.enemy_overrides)
            self.retired.append(old)
            self._purge()
        if now or self.isVisible():
            self._reload_timer.start(50 if now else 800)

    def _reload_project(self):
        if PROJECT in self.ctx or PROJECT in self.loading or not self.started:
            return
        self.story.populate()
        self.with_ctx(PROJECT, lambda _c: None)

    def _project_loaded(self, ctx):
        """A (re-)read project context: the rows, the Team / Fight lists."""
        # carry the Fight page's what-if over (rows the project still has)
        for e, ov in self._whatif_keep.items():
            if ctx.data.has_enemy(e):
                ctx.whatif.enemy_overrides[e] = dict(ov)
        self._whatif_keep = {}
        self.story.populate()
        if self.team.source() == PROJECT and self.team.step.count():
            self.team._load_steps()
        if self.fight.source() == PROJECT and self.fight.fights.count():
            self.fight._load_fights()

    def with_ctx(self, src, cb, on_fail=None):
        """cb(ctx) now when loaded, else once loaded in the background."""
        c = self.ctx.get(src)
        if c is not None:
            cb(c)
            return
        if src == PROJECT and self.s is None:
            if on_fail:
                on_fail('no project')
            return
        self._waiters.setdefault(src, []).append((cb, on_fail))
        if src in self.loading:
            return
        self.loading.add(src)
        gen = self._gen
        payload = None
        if src == PROJECT:
            payload = (copy.deepcopy(self.s.doc.data), self.s.doc.project_dir,
                       breeding_setting(self.s.doc.data))

        def done(out):
            self.loading.discard(src)
            waiters = self._waiters.pop(src, [])
            if out.get('error') or out.get('value') is None:
                err = out.get('error') or 'cancelled'
                self.story.banner.setText(f'Could not read {SRC_LABEL[src].lower()}: '
                                          + err.splitlines()[0])
                self.story.banner.setVisible(True)
                for _cb, fail in waiters:
                    if fail:
                        fail(err)
                return
            ctx = out['value']
            if src == PROJECT and gen != self._gen:      # edited while reading: again
                self.retired.append(ctx)
                for w in waiters:
                    self._waiters.setdefault(src, []).append(w)
                self.with_ctx(src, lambda _c: None)
                return
            self.ctx[src] = ctx
            if src == VANILLA:
                self._anchor_kits(ctx)
            if src == PROJECT:
                self._project_loaded(ctx)
            for cb_, _f in waiters:
                cb_(ctx)
        self.run_task(lambda _t: load_ctx(src, payload, gen, self._caches), on_done=done)

    def _anchor_kits(self, ctx):
        """The original game's step kits come from the anchor (when it is the
        current simulator's): registered so 'player' teams use them."""
        an = self.anchor
        if not an or anchor_problem(an) is not None:
            return
        for st in an.get('steps') or []:
            if st.get('kit') and 0 <= st.get('index', -1) < len(ctx.tl.steps):
                BL.set_kit(ctx.data, ctx.tl, st['index'], st['kit'])
                BL.set_kit(ctx.whatif, ctx.tl, st['index'], st['kit'])

    def run_task(self, fn, on_progress=None, on_result=None, on_done=None, uses=None):
        task = Task(fn)
        relay = _Relay(on_progress, on_result, None)

        def fin(out):
            self.tasks.pop(task, None)
            task.wait(2000)
            try:
                if on_done:
                    on_done(out)
            finally:
                self._purge()
        relay.d = fin
        task.progress.connect(relay.progress, Qt.QueuedConnection)
        task.result.connect(relay.result, Qt.QueuedConnection)
        task.done.connect(relay.done, Qt.QueuedConnection)
        self.tasks[task] = (relay, uses.ids() if uses is not None else set())
        task.start()
        return task

    def _purge(self):
        busy = set()
        for _relay, ids in self.tasks.values():
            busy |= ids
        keep = []
        for c in self.retired:
            if c.ids() & busy:
                keep.append(c)
            else:
                purge_memo(c.ids())
        self.retired = keep

    def busy(self):
        return bool(self.tasks) or bool(self.loading) or self._reload_timer.isActive()

    def wait_idle(self, timeout=120.0):
        """Process events until no task runs (tests)."""
        app = QApplication.instance()
        t0 = time.time()
        while self.busy() and time.time() - t0 < timeout:
            app.processEvents()
            time.sleep(0.01)
        app.processEvents()
        return not self.busy()

    def shutdown(self):
        """Stop every background computation (the window closes / the project
        is re-opened): cancel, then wait — a battle is milliseconds."""
        self._reload_timer.stop()
        self.story.stop_anchor()           # a running original-game build: saved parts stay
        if self.s is not None:
            try:
                self.s.undo.indexChanged.disconnect(self._undo_moved)
            except (RuntimeError, TypeError):
                pass
        for t in list(self.tasks):
            t.cancel()
        for t in list(self.tasks):
            if not t.wait(15000):
                t.terminate()
                t.wait(1000)
        self.tasks.clear()
