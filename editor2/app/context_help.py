"""context_help.py — "?" buttons and F1 that open the help AT the thing you are
looking at (S167, ROADMAP P3.H — user: "a glossary, a '?' button per section,
screenshots").

Where the "?" buttons are (all made here, so the tabs' own code stays as it was):

  * the main tab bar's right corner — the help topic of the tab shown;
  * every sub-tab bar inside a tab (Text, Music, Monsters, Breeding, Services …) —
    the tab's topic, scrolled to the heading that names the sub-tab shown (or the
    topic of SUBTAB_TOPICS);
  * the Rooms tab's page column (Tiles / Palettes / Object / Room / Screen / Gates) —
    a "?" under the page buttons, for the page shown (RAIL_TOPICS);
  * dialogs: a dialog of DIALOG_TOPICS gets a "?" (in its button row, or its top
    right corner) the moment it opens, and F1 inside it;
  * F1 anywhere in the main window = the "?" of the tab shown.

Every "?" calls `open_help(topic, heading)`: the window switches to the Help tab at
that topic (MainWindow.help_tab.open_topic) and the Help tab offers "◀ Back to <tab>".
Topics are help FILE names (editor2/help/NN_name.md); test_app (s167_context_help)
checks that every topic named here exists and every heading is found.
"""

from PySide6.QtCore import QEvent, QObject, Qt
from PySide6.QtGui import QKeySequence, QShortcut
from PySide6.QtWidgets import (QApplication, QBoxLayout, QDialog, QDialogButtonBox,
                               QGridLayout, QHBoxLayout, QTabWidget, QToolButton)

# main tab title (as in MainWindow.addTab, '&&' = '&') -> (topic file, heading or None)
TAB_TOPICS = {
    'Rooms': ('10_rooms.md', None),
    'Import art': ('14_import_art.md', None),
    'Cutscenes': ('63_cutscenes.md', None),
    'Gates': ('60_gates.md', None),
    'Families': ('51_families.md', None),
    'Monsters': ('52_monsters.md', None),
    'Resistances': ('79_resistances.md', None),
    'Text': ('56_text.md', None),
    'Arena': ('53_arena.md', None),
    'Skills': ('54_skills.md', None),
    'Animations': ('57_animations.md', None),
    'Encounters': ('59_encounters.md', None),
    'Music': ('61_music.md', None),
    'Items': ('74_items.md', None),
    'Shops': ('62_shops.md', None),
    'Services': ('67_services.md', None),
    'Breeding': ('58_breeding.md', None),
    'Progression & Flags': ('30_flags.md', None),
    'World': ('11_doors.md', 'The World tab'),
    'Balance': ('72_balance.md', None),
    'Capacity': ('81_capacity.md', None),
    'Build & Play': ('80_build.md', None),
    'Help': ('95_glossary.md', None),
}

# (main tab, sub-tab title) -> (topic, heading); sub-tabs not listed look for a
# heading of the tab's topic that contains the sub-tab's title
SUBTAB_TOPICS = {
    ('Rooms', 'Tiles'): ('13_tilesets.md', 'The Tiles page'),
    ('Rooms', 'Borrow'): ('13_tilesets.md', 'The Tiles page'),
    ('Rooms', 'Tileset'): ('13_tilesets.md', 'The Tileset tab'),
    ('Rooms', 'Animate'): ('15_animated_tiles.md', None),
    ('Rooms', 'Draw'): ('13_tilesets.md', 'The metatile editor'),
    ('Services', 'Breeding pools'): ('68_breeding_npcs.md', 'Breeding pools'),
    ('Services', 'Medal Man'): ('67_services.md', 'Medal Man'),
    ('Breeding', 'Hints'): ('78_hints.md', None),
    ('Breeding', 'Try a cross'): ('58_breeding.md', 'Try a cross: the baby'),   # S169
    ('Arena', 'Your arena'): ('69_your_arena.md', None),
    ('Progression & Flags', 'Story'): ('71_story_quests.md', 'The story spine'),
    ('Progression & Flags', 'Story checks'): ('71_story_quests.md', 'Story checks'),
    ('Progression & Flags', 'Quests'): ('71_story_quests.md', 'Quests'),
    ('Text', 'Window words'): ('56_text.md', 'Window words'),
}

# the Rooms tab's side-rail page key -> (topic, heading)
RAIL_TOPICS = {
    'tiles': ('13_tilesets.md', 'The Tiles page'),
    'palettes': ('13_tilesets.md', 'BG palettes'),
    'object': ('20_npcs.md', None),
    'room': ('10_rooms.md', None),
    'screen': ('10_rooms.md', None),
    'gates': ('70_boss_floors.md', None),
}

# dialog class name -> (topic, heading)
DIALOG_TOPICS = {
    'NewRoomDialog': ('10_rooms.md', None),
    'KeepStatesDialog': ('10_rooms.md', None),
    'RuleDialog': ('10_rooms.md', None),
    'BorrowPaletteDialog': ('10_rooms.md', None),
    'DoorDialog': ('11_doors.md', 'Add and connect a door'),
    'DoorPropsDialog': ('11_doors.md', 'Add and connect a door'),
    'RedirectDialog': ('11_doors.md', 'Game doors into your rooms'),
    'ExitDialog': ('11_doors.md', 'One-way teleports'),
    'LockDialog': ('11_doors.md', 'Locked doors'),
    'MazeScreenDialog': ('12_gate_themes.md', None),
    'TilesetDialog': ('13_tilesets.md', 'Change tileset'),
    'MetatileEditor': ('13_tilesets.md', 'The metatile editor'),
    'PlayDialog': ('16_play_here.md', None),
    'TalkDialog': ('20_npcs.md', 'Text'),
    'SpritePicker': ('20_npcs.md', None),
    'ShownWhenDialog': ('20_npcs.md', None),
    'ConversationDialog': ('40_conversations.md', None),
    'EnemiesDialog': ('50_enemies.md', None),
    'SheetImportDialog': ('52_monsters.md', 'New species from a sprite sheet'),
    'AddFramesDialog': ('57_animations.md', 'Steps'),
    'RecipeDialog': ('58_breeding.md', 'Special recipes'),
    'GenerateDialog': ('58_breeding.md', 'Generate a tree'),
    'VariantDialog': ('59_encounters.md', None),
    'EnemyPick': ('59_encounters.md', 'Lists'),
    'NewGateDialog': ('60_gates.md', 'New gates'),
    'GateRuleDialog': ('60_gates.md', None),
    'OpDialog': ('63_cutscenes.md', 'Changing a game scene in a copied room'),
    'MillyHookDialog': ('64_milly_hook.md', None),
    'NewWorldDialog': ('65_worlds.md', 'Make one, step by step'),
    'PortalDialog': ('65_worlds.md', 'Make one, step by step'),
    'StartDialog': ('65_worlds.md', 'Make one, step by step'),
    'HubRuleDialog': ('66_hub.md', 'Set it, step by step'),
    'ServiceDialog': ('67_services.md', None),
    'PoolDialog': ('68_breeding_npcs.md', 'Breeding pools'),
    'MakeBossDialog': ('70_boss_floors.md', None),
    'CheckDialog': ('71_story_quests.md', 'Story checks'),
    'QuestDialog': ('71_story_quests.md', 'Quests'),
    'MusicRulesDialog': ('71_story_quests.md', 'Music by flag'),
    'ItemSetsDialog': ('71_story_quests.md', 'Shop item sets'),
    'MemberDialog': ('72_balance.md', 'Team'),
    'NewGameDialog': ('75_opening.md', None),
    'EndingDialog': ('76_ending.md', None),
    'MemorialDialog': ('77_memorial.md', None),
    'StatueWordsDialog': ('77_memorial.md', None),
    'HintWordsDialog': ('78_hints.md', None),
    'FamilyWordsDialog': ('78_hints.md', None),
    'RiddleDialog': ('78_hints.md', None),
}

STYLE = ('QToolButton { font-weight: bold; border: 1px solid #7a8; border-radius: 9px;'
         ' min-width: 18px; max-width: 18px; min-height: 18px; max-height: 18px;'
         ' color: #2a6; background: transparent; }'
         ' QToolButton:hover { background: #2a6; color: white; }')


def _main_window(widget=None):
    """The MainWindow a widget belongs to (its window, or that window's parents — a
    dialog's parent is the main window); else the active / first one."""
    w = widget.window() if widget is not None else None
    while w is not None:
        if hasattr(w, 'help_tab') and hasattr(w, 'tabs'):
            return w
        w = w.parentWidget()
    cands = [x for x in QApplication.topLevelWidgets() if hasattr(x, 'help_tab') and hasattr(x, 'tabs')]
    act = QApplication.activeWindow()
    for x in cands:
        if x is act:
            return x
    vis = [x for x in cands if x.isVisible()]
    return (vis or cands or [None])[0]


def open_help(topic, heading=None, from_widget=None, mw=None):
    """Switch the main window to the Help tab at `topic` / `heading`."""
    mw = mw or _main_window(from_widget)
    if mw is None:
        return False
    tabs = mw.tabs
    came = tabs.currentWidget()
    label = tabs.tabText(tabs.currentIndex()).replace('&&', '&')
    ok = mw.help_tab.open_topic(topic, heading)
    if came is not mw.help_tab:
        mw.help_tab.set_return(tabs, came, label)
    # a modal dialog stays open over the window; the help is behind it — raise it
    if from_widget is not None:
        dlg = from_widget.window()
        if isinstance(dlg, QDialog) and dlg.isModal():
            dlg.setModal(False)
    tabs.setCurrentWidget(mw.help_tab)
    mw.raise_()
    mw.activateWindow()
    return ok


def help_button(topic, heading=None, tip=None, parent=None, resolve=None):
    """A round "?" button. `resolve()` (optional) returns (topic, heading) at click time."""
    b = QToolButton(parent)
    b.setText('?')
    b.setStyleSheet(STYLE)
    b.setCursor(Qt.PointingHandCursor)
    b.setToolTip(tip or 'Help about this (F1)')
    b.setFocusPolicy(Qt.NoFocus)

    def go():
        t, h = resolve() if resolve else (topic, heading)
        open_help(t, h, b)
    b.clicked.connect(go)
    b._help_target = resolve or (lambda: (topic, heading))
    return b


def tab_title(tabs, i):
    return tabs.tabText(i).replace('&&', '&')


def current_tab_target(mw):
    """(topic, heading) for the tab shown in the main window (and its sub-tab)."""
    tabs = mw.tabs
    t = tab_title(tabs, tabs.currentIndex())
    page = tabs.currentWidget()
    base = TAB_TOPICS.get(t, ('00_start.md', None))
    sub = _shown_subtab(page)
    if sub:
        return subtab_target(t, sub)
    return base


def _shown_subtab(page):
    """The title of the visible sub-tab of the page's first visible QTabWidget."""
    if page is None:
        return None
    for tw in page.findChildren(QTabWidget):
        if tw.isVisible() and tw.count():
            return tw.tabText(tw.currentIndex()).replace('&&', '&')
    return None


def subtab_target(tab, sub):
    if (tab, sub) in SUBTAB_TOPICS:
        return SUBTAB_TOPICS[(tab, sub)]
    topic, heading = TAB_TOPICS.get(tab, ('00_start.md', None))
    return topic, (sub or heading)


class _DialogWatcher(QObject):
    """Gives every dialog of DIALOG_TOPICS a "?" (and F1) when it is first shown."""

    def eventFilter(self, obj, ev):                      # noqa: N802 (Qt API)
        if ev.type() == QEvent.Show and isinstance(obj, QDialog):
            name = type(obj).__name__
            if name in DIALOG_TOPICS and not getattr(obj, '_help_added', False):
                obj._help_added = True
                try:
                    add_dialog_help(obj, *DIALOG_TOPICS[name])
                except Exception:                        # noqa: BLE001
                    pass
        return False


def add_dialog_help(dlg, topic, heading=None):
    b = help_button(topic, heading, 'Help about this window (F1)', dlg)
    boxes = dlg.findChildren(QDialogButtonBox)
    if boxes:
        boxes[-1].addButton(b, QDialogButtonBox.HelpRole)
    else:
        lay = dlg.layout()
        row = QHBoxLayout()
        row.addStretch(1)
        row.addWidget(b)
        if isinstance(lay, QBoxLayout):
            lay.insertLayout(0, row)
        elif isinstance(lay, QGridLayout):
            b.setParent(dlg)
            b.move(dlg.width() - 26, 4)
            b.show()
        else:
            b.move(max(0, dlg.width() - 26), 4)
            b.show()
    sc = QShortcut(QKeySequence.HelpContents, dlg)
    sc.activated.connect(lambda: open_help(topic, heading, dlg))
    dlg._help_button = b
    return b


def _rail_button(rail):
    from editor2.app.side_rail import SideRail
    if not isinstance(rail, SideRail) or getattr(rail, '_help_btn', None):
        return None

    def target():
        return RAIL_TOPICS.get(rail.current_key() or '', ('10_rooms.md', None))
    b = help_button(None, None, 'Help about the page shown (F1)', None, resolve=target)
    rail.col.addWidget(b, 0, Qt.AlignHCenter)
    rail._help_btn = b
    return b


def install(mw):
    """Called once by MainWindow after its tabs exist (and again after a project
    opens: tabs made late get their "?" too — every install step is idempotent)."""
    tabs = mw.tabs
    if not getattr(mw, '_help_corner', None):
        b = help_button(None, None, 'Help about the tab shown (F1)', tabs,
                        resolve=lambda: current_tab_target(mw))
        tabs.setCornerWidget(b, Qt.TopRightCorner)
        b.show()
        mw._help_corner = b
    for i in range(tabs.count()):
        # S171: a tab not made yet (page_tabs.addLazyTab) gets its "?" when it is shown
        page = tabs.built(i) if hasattr(tabs, 'built') else tabs.widget(i)
        title = tab_title(tabs, i)
        if page is None or page is mw.help_tab:
            continue
        for tw in page.findChildren(QTabWidget):
            if tw.cornerWidget(Qt.TopRightCorner) is not None:
                continue
            b = help_button(None, None, 'Help about the page shown (F1)', tw,
                            resolve=lambda tw=tw, title=title: subtab_target(
                                title, tw.tabText(tw.currentIndex()).replace('&&', '&')))
            tw.setCornerWidget(b, Qt.TopRightCorner)
            b.show()
        from editor2.app.side_rail import SideRail
        for rail in page.findChildren(SideRail):
            _rail_button(rail)
    app = QApplication.instance()
    if app is not None and not getattr(app, '_help_watcher', None):
        app._help_watcher = _DialogWatcher(app)
        app.installEventFilter(app._help_watcher)


def f1(mw):
    """F1 in the main window: the help of what is shown."""
    if mw.tabs.currentWidget() is mw.help_tab:
        return
    t, h = current_tab_target(mw)
    open_help(t, h, mw=mw)
