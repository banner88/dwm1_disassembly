"""inspector.py — the Rooms tab's right-hand inspector (S93).

Panels (top to bottom): Room · Screen & state · Selection (clicked
marker) · Layout. Every value shown is read straight from the Document;
editable fields push undo commands. Fields whose editing belongs to a
later ROADMAP box (NPC forms = P3.5, triggers/exits = P3.7) are shown
read-only rather than hidden, so the author always sees what the engine
will get.
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtWidgets import (QComboBox, QFormLayout, QGroupBox, QLabel,
                               QLineEdit, QListWidget, QPushButton,
                               QScrollArea, QSpinBox, QVBoxLayout, QWidget,
                               QTreeWidget, QTreeWidgetItem, QHBoxLayout)

from editor2.core.document import val

VANILLA_PAL = '(borrow vanilla source palette)'


def _lbl(text=''):
    l = QLabel(text)
    l.setWordWrap(True)
    l.setTextInteractionFlags(Qt.TextSelectableByMouse)
    return l


class Inspector(QWidget):
    thresholdEdited = Signal(int)
    paletteChosen = Signal(object)         # palette id or None
    localizeRequested = Signal()
    nameEdited = Signal(str)
    hoverInfo = Signal(str)
    statePaletteChosen = Signal(object)        # pid | None | ('vanilla', mid)
    addExitRequested = Signal(object)          # (cx, cy)
    removeExitRequested = Signal(int)          # exit index in the current state
    addRedirectRequested = Signal()
    removeRedirectRequested = Signal(int)      # index into custom.entrance_redirects
    routeDoorRequested = Signal(object)        # vanilla door preset dict
    tilesetChangeRequested = Signal()          # S96

    def __init__(self, parent=None):
        super().__init__(parent)
        self._building = False
        self._vanilla_view = None
        outer = QVBoxLayout(self)
        outer.setContentsMargins(0, 0, 0, 0)
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QScrollArea.NoFrame)
        body = QWidget()
        self.lay = QVBoxLayout(body)
        self.lay.setContentsMargins(6, 6, 6, 6)
        scroll.setWidget(body)
        outer.addWidget(scroll)

        # ---- Room
        g = QGroupBox('Room')
        f = QFormLayout(g)
        f.setLabelAlignment(Qt.AlignRight)
        self.r_name = QLineEdit()
        self.r_name.editingFinished.connect(self._name_done)
        self.r_id = _lbl()
        self.r_map = _lbl()
        self.r_src = _lbl()
        self.r_gfx = _lbl()
        self.r_dims = _lbl()
        self.r_thr = QSpinBox()
        self.r_thr.setRange(0, 255)
        self.r_thr.setPrefix('$')
        self.r_thr.setDisplayIntegerBase(16)
        self.r_thr.valueChanged.connect(self._thr_changed)
        self.r_thr.setToolTip('Tiles below this index are walls. Use Walkability '
                              'mode (W) on the canvas rather than editing this.')
        self.r_pal = QComboBox()
        self.r_pal.currentIndexChanged.connect(self._pal_changed)
        self.r_attr = _lbl()
        self.r_enc = _lbl()
        self.r_music = _lbl()
        self.r_scripts = _lbl()
        self.r_note = _lbl()
        self.r_note.setStyleSheet('color: #e0b040;')
        f.addRow('name', self.r_name)
        f.addRow('id', self.r_id)
        f.addRow('mapID', self.r_map)
        f.addRow('source map', self.r_src)
        trow = QHBoxLayout()
        trow.addWidget(self.r_gfx, 1)
        self.r_gfx_btn = QPushButton('Change…')
        self.r_gfx_btn.setToolTip("Draw this room with another room's tileset, a "
                                  'project tileset, or a new blank one for imported art.')
        self.r_gfx_btn.clicked.connect(self.tilesetChangeRequested.emit)
        trow.addWidget(self.r_gfx_btn)
        f.addRow('tileset', trow)
        f.addRow('size', self.r_dims)
        f.addRow('collision ≥', self.r_thr)
        f.addRow('palette', self.r_pal)
        f.addRow('attr base', self.r_attr)
        f.addRow('encounters', self.r_enc)
        f.addRow('music', self.r_music)
        f.addRow('scripts', self.r_scripts)
        f.addRow(self.r_note)
        self.lay.addWidget(g)

        # ---- Entrances (S94b redirects)
        g = QGroupBox('Entrances — how the player gets here')
        v = QVBoxLayout(g)
        self.redirect_list = QListWidget()
        self.redirect_list.setMaximumHeight(90)
        self.redirect_list.setToolTip(
            'Vanilla doors routed into this room (custom.entrance_redirects). '
            'Walk through that door in-game to test the room.')
        self.redirect_none = _lbl('No entrance yet — this room is reachable only by '
                                  'warp. Route a vanilla door here to test it in-game.')
        self.redirect_none.setStyleSheet('color: #e0b040;')
        row = QHBoxLayout()
        self.btn_add_redirect = QPushButton('Route a vanilla door here…')
        self.btn_add_redirect.clicked.connect(self.addRedirectRequested.emit)
        self.btn_del_redirect = QPushButton('Remove')
        self.btn_del_redirect.clicked.connect(self._remove_redirect)
        row.addWidget(self.btn_add_redirect)
        row.addWidget(self.btn_del_redirect)
        v.addWidget(self.redirect_none)
        v.addWidget(self.redirect_list)
        v.addLayout(row)
        self.entr_group = g
        self.lay.addWidget(g)

        # ---- Screen & state
        g = QGroupBox('Screen & state')
        f = QFormLayout(g)
        f.setLabelAlignment(Qt.AlignRight)
        self.s_key = _lbl()
        self.s_layout = _lbl()
        self.s_localize = QPushButton('Make editable (copy into project)')
        self.s_localize.clicked.connect(self.localizeRequested.emit)
        self.s_attr = _lbl()
        self.s_counter = _lbl()
        self.s_states = _lbl()
        self.s_npcs = _lbl()
        self.s_pal = QComboBox()
        self.s_pal.currentIndexChanged.connect(self._state_pal_changed)
        self.s_pal.setToolTip('Palette shown on THIS screen/state (states[n].palette or '
                              'screens[k].palette). "(room palette)" inherits the Room '
                              'setting; a vanilla entry copies that room\'s palette into '
                              'your project as an editable item.')
        f.addRow('screen', self.s_key)
        f.addRow('layout', self.s_layout)
        f.addRow('', self.s_localize)
        f.addRow('palette here', self.s_pal)
        f.addRow('attr grid', self.s_attr)
        f.addRow('step counter', self.s_counter)
        f.addRow('states', self.s_states)
        f.addRow('NPC slots', self.s_npcs)
        self.lay.addWidget(g)

        # ---- Selection
        g = QGroupBox('Selection')
        v = QVBoxLayout(g)
        self.sel_title = _lbl('Nothing selected — use the Select tool (V) and '
                              'click an NPC / spawn / exit marker.')
        self.sel_tree = QTreeWidget()
        self.sel_tree.setHeaderLabels(['field', 'value'])
        self.sel_tree.setRootIsDecorated(False)
        self.sel_tree.setMaximumHeight(170)
        self.sel_note = _lbl('NPC / exit fields become editable in P3.5 / P3.7.')
        self.sel_note.setStyleSheet('color: #888;')
        self.sel_route = QPushButton('Route this door into a custom room…')
        self.sel_route.clicked.connect(self._route_selected)
        self.sel_route.setVisible(False)
        self._sel_door = None
        self.sel_add_exit = QPushButton('Add exit at this cell…')
        self.sel_add_exit.clicked.connect(self._add_exit_here)
        self.sel_add_exit.setVisible(False)
        self._sel_cell = None
        self.sel_del_exit = QPushButton('Delete this exit')
        self.sel_del_exit.clicked.connect(self._del_exit)
        self.sel_del_exit.setVisible(False)
        self._sel_exit_idx = None
        v.addWidget(self.sel_title)
        v.addWidget(self.sel_tree)
        v.addWidget(self.sel_route)
        v.addWidget(self.sel_add_exit)
        v.addWidget(self.sel_del_exit)
        v.addWidget(self.sel_note)
        self.lay.addWidget(g)

        # ---- Layout
        g = QGroupBox('Layout')
        f = QFormLayout(g)
        f.setLabelAlignment(Qt.AlignRight)
        self.l_id = _lbl()
        self.l_users = _lbl()
        f.addRow('id', self.l_id)
        f.addRow('used by', self.l_users)
        self.lay.addWidget(g)
        self.lay.addStretch(1)

    # ------------------------------------------------------------ updates
    def show_vanilla(self, renderer, mid, key):
        """Read-only view of a vanilla room."""
        self._building = True
        self.r_name.setText(renderer.vanilla_name(mid))
        self.r_name.setEnabled(False)
        self.r_id.setText(f'vanilla ${mid:02X}')
        self.r_map.setText(f'${mid:02X}  (vanilla — read-only)')
        self.r_src.setText('—')
        gfx = renderer.vanilla_gfx(mid)
        self.r_gfx.setText(f'bank ${gfx.gfx_bank:02X} id ${gfx.gfx_id:02X}')
        self.r_gfx_btn.setEnabled(False)
        self.r_thr.setValue(gfx.threshold)
        self.r_thr.setEnabled(False)
        rec = renderer.vanilla_record(mid)
        self.r_dims.setText(f"{rec['width_px'] // 160}×{rec['height_px'] // 128} screens")
        self.r_pal.clear()
        self.r_pal.addItem('vanilla palette', None)
        self.r_pal.setEnabled(False)
        self.r_attr.setText('vanilla')
        self.r_enc.setText('vanilla')
        self.r_music.setText('vanilla')
        self.r_scripts.setText('vanilla')
        self.r_note.setText('Vanilla room. "Make editable" clones it into your '
                            'project (the original stays untouched).')
        self.r_note.setVisible(True)
        self.entr_group.setVisible(False)
        self._vanilla_view = (mid, key)
        self.s_key.setText(f'{key}')
        self.s_layout.setText('vanilla layout (read-only)')
        self.s_localize.setVisible(False)
        self.s_attr.setText('vanilla attr')
        self.s_attr.setStyleSheet('')
        self.s_counter.setText('vanilla')
        self.s_states.setText('showing vanilla step 0')
        self.s_npcs.setText('—')
        self.s_npcs.setStyleSheet('')
        self.l_id.setText('—')
        self.l_users.setText('—')
        self._building = False

    def show_room(self, doc, renderer, room, key, state_idx):
        self._building = True
        mid = val(room['mapID'])
        self.r_name.setText(doc.room_name(room))
        self.r_name.setEnabled(not room.get('placeholder'))
        self.r_pal.setEnabled(True)
        self.r_id.setText(room.get('id', '?'))
        self.r_map.setText(f'${mid:02X}' + (' (placeholder)' if room.get('placeholder') else ''))
        self.r_src.setText(f"${val(room.get('source_mapID', 0)):02X}")
        rec = room.get('record') or {}
        self.r_gfx_btn.setEnabled(bool(rec) and not room.get('placeholder'))
        note = ''
        try:
            gfx = renderer.room_gfx(room)
            if 'tileset' in rec:
                self.r_gfx.setText(f"custom tileset {rec['tileset']!r} (bank $67)")
            else:
                self.r_gfx.setText(f'bank ${gfx.gfx_bank:02X} id ${gfx.gfx_id:02X}')
            note = gfx.note
            self.r_thr.setValue(gfx.threshold)
            self.r_thr.setEnabled(bool(rec))
        except Exception as e:                    # pragma: no cover
            self.r_gfx.setText(f'unavailable: {e}')
        keys = doc.screen_keys(room)
        cols = (max(k % 4 for k in keys) + 1) if keys else 0
        rows = (max(k // 4 for k in keys) + 1) if keys else 0
        dims = f"{cols}×{rows} screens"
        if rec:
            dims += f"  (record {rec.get('width_px')}×{rec.get('height_px')} px)"
        else:
            note = note or 'legacy room (< $70): record hand-patched in bank_000'
        self.r_dims.setText(dims)
        # palette combo
        self.r_pal.clear()
        self.r_pal.addItem(VANILLA_PAL, None)
        cur = (room.get('render') or {}).get('palette')
        self._fill_palette_combo(self.r_pal, doc, renderer)
        idx = self.r_pal.findData(cur) if cur else 0
        self.r_pal.setCurrentIndex(max(idx, 0))
        at = (room.get('render') or {}).get('attr')
        self.r_attr.setText(str(at.get('id') if at and 'id' in at else at or 'none'))
        enc = room.get('encounters')
        self.r_enc.setText(
            f"gate {enc.get('gate_id')} floor {enc.get('floor')}"
            if enc and enc.get('enabled') else 'off')
        self.r_music.setText(str(room.get('music', 'default')))
        self.r_scripts.setText(str(len(room.get('scripts') or {})))
        self.r_note.setText(note)
        self.r_note.setVisible(bool(note))
        self._vanilla_view = None
        self.show_entrances(doc, renderer, room)
        self.show_screen(doc, renderer, room, key, state_idx)
        self._building = False

    def _fill_palette_combo(self, combo, doc, renderer):
        """Project palettes, then every vanilla room's palette as a
        'copy into project' entry (user S95: "use a pre-existing room's
        palette")."""
        for p in doc.palettes:
            combo.addItem(p['id'], p['id'])
        combo.insertSeparator(combo.count())
        for mid, name, _scr in renderer.vanilla_rooms():
            combo.addItem(f'copy from vanilla ${mid:02X} {name}', ('vanilla', mid))

    def show_entrances(self, doc, renderer, room):
        self.entr_group.setVisible(not room.get('placeholder'))
        self.redirect_list.clear()
        reds = doc.redirects_to(room['id'])
        for i, rd in reds:
            try:
                name = renderer.vanilla_name(val(rd['mapID']))
            except Exception:
                name = f"${val(rd['mapID']):02X}"
            it_text = (f"{name} screen {val(rd['screen'])} door "
                       f"({val(rd['x'])},{val(rd['y'])})  →  screen "
                       f"{val(rd['screen_byte']) & 0x0F} cell "
                       f"({val(rd['spawn_x'])},{val(rd['spawn_y'])})")
            from PySide6.QtWidgets import QListWidgetItem
            it = QListWidgetItem(it_text)
            it.setData(Qt.UserRole, i)
            self.redirect_list.addItem(it)
        self.redirect_none.setVisible(not reds)
        self.redirect_list.setVisible(bool(reds))
        self.btn_del_redirect.setEnabled(bool(reds))

    def show_screen(self, doc, renderer, room, key, state_idx):
        if str(key) not in room.get('screens', {}):
            self.s_key.setText('—')
            return
        self.s_key.setText(f'{key}  (col {key % 4}, row {key // 4})')
        ref = doc.state_layout_ref(room, key, state_idx)
        if ref and 'id' in ref:
            self.s_layout.setText(f"{ref['id']}  (project layout, editable)")
            self.s_localize.setVisible(False)
        elif ref:
            self.s_layout.setText(
                f"vanilla bank {ref.get('bank')} entry {ref.get('entry')} — "
                'read-only until copied into the project')
            self.s_localize.setVisible(True)
        else:
            self.s_layout.setText('none')
            self.s_localize.setVisible(False)
        self._building = True
        self.s_pal.clear()
        self.s_pal.addItem('(room palette)', None)
        self._fill_palette_combo(self.s_pal, doc, renderer)
        scr = doc.screen(room, key)
        own = (scr['states'][state_idx].get('palette') if scr.get('states')
               else scr.get('palette'))
        i = self.s_pal.findData(own) if own else 0
        self.s_pal.setCurrentIndex(max(i, 0))
        self._building = False
        _grid, note = renderer.attr_grid(room, int(key), state_idx)
        self.s_attr.setText(note)
        self.s_attr.setStyleSheet('color: #ff6060;' if note.startswith('WARNING')
                                  else '')
        scr = doc.screen(room, key)
        sc = scr.get('step_counter', 'auto')
        self.s_counter.setText(sc if isinstance(sc, str) else
                               str(sc.get('label') or sc.get('addr')))
        sts = doc.states(room, key)
        self.s_states.setText(f'{len(sts)}  (viewing state {state_idx})'
                              + ('' if scr.get('states') else '  — single implicit state'))
        n, cap = doc.state_capacity(room, key, state_idx)
        self.s_npcs.setText(f'{n} / {cap} (hard cap, S91)')
        self.s_npcs.setStyleSheet('color: #ff6060;' if n > cap else
                                  'color: #e0b040;' if n == cap else '')
        # layout panel
        lid = ref.get('id') if ref and 'id' in ref else None
        self.l_id.setText(lid or '—')
        if lid:
            users = doc.layout_users(lid)
            self.l_users.setText('\n'.join(
                f"{r} screen {k}" + (f" state {i}" if i is not None else '')
                + (' (attr)' if kind == 'attr' else '')
                for r, k, i, kind in users) or '—')
        else:
            self.l_users.setText('—')

    def show_cell(self, cell, mt, walkable, editable=False):
        self.sel_tree.clear()
        self.sel_route.setVisible(False)
        self.sel_del_exit.setVisible(False)
        self._sel_exit_idx = None
        if cell is None:
            self.show_selection(None)
            return
        cx, cy = cell
        self._sel_cell = cell
        self.sel_add_exit.setVisible(bool(editable))
        self.sel_title.setText(f'Cell ({cx},{cy})')
        for name, t in zip(('top-left', 'top-right', 'bottom-left', 'bottom-right'),
                           mt['tiles']):
            QTreeWidgetItem(self.sel_tree, [f'subtile {name}', f'${t:02X} ({t})'])
        QTreeWidgetItem(self.sel_tree, ['palette slot', str(mt.get('pal'))])
        QTreeWidgetItem(self.sel_tree, ['walkable', 'yes' if walkable else 'NO (wall)'])
        self.sel_note.setText('Walkability is decided by the bottom-right subtile '
                              '(engine, measured S94). Use Walkability mode (W) to flip it.')

    def show_selection(self, sel, editable=False):
        self.sel_tree.clear()
        self.sel_route.setVisible(False)
        self.sel_add_exit.setVisible(False)
        self.sel_del_exit.setVisible(False)
        self._sel_door = None
        self._sel_exit_idx = None
        if sel and sel['kind'] == 'exit' and editable and not self._vanilla_view:
            self._sel_exit_idx = sel['ref'][1]
            self.sel_del_exit.setVisible(True)
        if not sel:
            self.sel_title.setText('Nothing selected — click a cell or an NPC / '
                                   'spawn / exit marker with the Select tool (V).')
            self.sel_note.setText('')
            return
        if sel['kind'] in ('exit', 'redirect') and self._vanilla_view:
            mid, key = self._vanilla_view
            self._sel_door = {'mapID': mid, 'screen': key,
                              'x': sel['x'], 'y': sel['y']}
            self.sel_route.setVisible(True)
        self.sel_note.setText('NPC / exit fields become editable in P3.5 / P3.7.')
        self.sel_title.setText(f"{sel['label']}  at cell ({sel['x']},{sel['y']})")
        _kind, idx, entry = sel['ref']
        for k, v in entry.items():
            if isinstance(v, list):
                v = ' '.join(str(x) for x in v)
            QTreeWidgetItem(self.sel_tree, [str(k), str(v)])
        QTreeWidgetItem(self.sel_tree, ['entry #', str(idx)])

    # ------------------------------------------------------------- slots
    def _remove_redirect(self):
        it = self.redirect_list.currentItem() or (
            self.redirect_list.item(0) if self.redirect_list.count() else None)
        if it is not None:
            self.removeRedirectRequested.emit(it.data(Qt.UserRole))

    def _route_selected(self):
        if self._sel_door:
            self.routeDoorRequested.emit(dict(self._sel_door))

    def _add_exit_here(self):
        if self._sel_cell is not None:
            self.addExitRequested.emit(tuple(self._sel_cell))

    def _del_exit(self):
        if self._sel_exit_idx is not None:
            self.removeExitRequested.emit(int(self._sel_exit_idx))

    def _state_pal_changed(self, _i):
        if not self._building:
            self.statePaletteChosen.emit(self.s_pal.currentData())

    def _thr_changed(self, v):
        if not self._building:
            self.thresholdEdited.emit(v)

    def _pal_changed(self, _i):
        if not self._building:
            self.paletteChosen.emit(self.r_pal.currentData())

    def _name_done(self):
        if not self._building and self.r_name.isEnabled():
            self.nameEdited.emit(self.r_name.text().strip())
