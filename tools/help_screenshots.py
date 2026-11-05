#!/usr/bin/env python3
"""help_screenshots.py — the pictures of the editor's Help topics (S167, ROADMAP P3.H:
"screenshots").

Opens the REAL editor (editor2.app.main.MainWindow) offscreen on the example
project (or --project), shows each main tab at a fixed window size and saves it to
editor2/help/img/tab_<name>.png (scaled to --width). The topics show them with
`![The X tab](img/tab_x.png)` under their title (context_help.TAB_TOPICS names the
topic of each tab). Re-run after a UI change; the PNGs are committed with the help.

S169: + SUBTABS — a sub-tab shown with some content (`editor2/help/img/<file>`), e.g.
the Breeding tab's "Try a cross" page with two typical parents.

  QT_QPA_PLATFORM=offscreen QT_AUDIO_BACKEND=none \\
      python3 tools/help_screenshots.py [--project DIR] [--width 1000] [--only Rooms,Music]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
os.environ.setdefault('QT_AUDIO_BACKEND', 'none')
OUT = os.path.join(REPO, 'editor2', 'help', 'img')


def _cross_setup(w):
    """The Try a cross page with Healer x FunkyBird, typical, level 20."""
    bt = w.breeding_tab
    bt.t_p1.set_value(9)
    bt.t_p2.set_value(88)
    bt.t_lv1.setValue(20)
    bt.t_lv2.setValue(20)
    bt._baby_detail()


# S169: (main tab, sub-tab, picture, setup(window) or None)
SUBTABS = [('Breeding', 'Try a cross', 'sub_breeding_cross.png', _cross_setup)]


def slug(title):
    return 'tab_' + re.sub(r'[^a-z0-9]+', '_', title.lower().replace('&&', '&')).strip('_')


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--project', default=os.path.join(REPO, 'editor2', 'example-project'))
    ap.add_argument('--width', type=int, default=1000)
    ap.add_argument('--size', default='1400x860')
    ap.add_argument('--only', default='')
    a = ap.parse_args()
    from PySide6.QtCore import Qt
    from PySide6.QtGui import QImage
    from PySide6.QtWidgets import QApplication
    app = QApplication.instance() or QApplication(sys.argv)
    from PySide6.QtCore import QSettings
    from editor2.app.main import MainWindow
    st = QSettings('dwm1_disassembly', 'DWM1Editor')
    kept_sav = st.value('breeding/sav')          # S169: no save of the user's in a picture
    st.remove('breeding/sav')
    w = MainWindow()
    w.open_project(a.project)
    W, H = (int(x) for x in a.size.split('x'))
    w.resize(W, H)
    w.show()
    w.log.clear()                        # no machine paths in the pictures
    w.statusBar().clearMessage()
    for _ in range(20):
        app.processEvents()
    os.makedirs(OUT, exist_ok=True)
    only = {s.strip() for s in a.only.split(',') if s.strip()}
    done = []
    for i in range(w.tabs.count()):
        title = w.tabs.tabText(i).replace('&&', '&')
        if title == 'Help' or (only and title not in only):
            continue
        w.tabs.setCurrentIndex(i)
        for _ in range(30):
            app.processEvents()
        w.statusBar().clearMessage()
        pix = w.grab()
        if a.width and pix.width() > a.width:
            pix = pix.scaledToWidth(a.width, Qt.SmoothTransformation)
        img = pix.toImage().convertToFormat(QImage.Format_Indexed8)   # ~1/3 the size
        path = os.path.join(OUT, slug(title) + '.png')
        img.save(path, 'PNG')
        done.append((title, os.path.relpath(path, REPO), os.path.getsize(path)))
    for tab, sub, fname, setup in SUBTABS:
        if only and tab not in only:
            continue
        for i in range(w.tabs.count()):
            if w.tabs.tabText(i).replace('&&', '&') == tab:
                w.tabs.setCurrentIndex(i)
        if setup is not None:
            setup(w)
        for _ in range(30):
            app.processEvents()
        w.statusBar().clearMessage()
        pix = w.grab()
        if a.width and pix.width() > a.width:
            pix = pix.scaledToWidth(a.width, Qt.SmoothTransformation)
        img = pix.toImage().convertToFormat(QImage.Format_Indexed8)
        path = os.path.join(OUT, fname)
        img.save(path, 'PNG')
        done.append((f'{tab} / {sub}', os.path.relpath(path, REPO), os.path.getsize(path)))
    for t, p, n in done:
        print(f'{t:22s} {p}  {n // 1024} KB')
    if kept_sav:
        st.setValue('breeding/sav', kept_sav)
    return 0


if __name__ == '__main__':
    sys.exit(main())
