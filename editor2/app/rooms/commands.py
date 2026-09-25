"""commands.py — QUndoCommands for the Rooms tab (S93).

Each command mutates the Document through its public API and emits the
Session signal that tells views what to refresh. Undo is exact: commands
carry the inverse data returned by the Document.
"""

import copy
import os

from PySide6.QtGui import QUndoCommand


class SnapshotCommand(QUndoCommand):
    """Structural edit as a whole-document snapshot (S94): `op(doc)` runs
    once; undo/redo swap the complete project dict (deep copies — ~ms for
    a 130 KB project) plus any tileset asset files the op touched. Used for
    clone / copy / new / delete / rename / localize / walkability, so they
    need no hand-written inverse and can never drift from the document."""

    def __init__(self, session, label, op, assets=()):
        super().__init__(label)
        self.s = session
        self.op = op
        self.assets = list(assets)          # project-relative paths
        self.before = self.after = None
        self.files_before = self.files_after = None
        self.result = None
        self.error = None

    def _read_files(self):
        out = {}
        for rel in self.assets:
            path = os.path.join(self.s.doc.project_dir, rel)
            out[rel] = open(path, 'rb').read() if os.path.exists(path) else None
        return out

    def _write_files(self, snap):
        for rel, data in snap.items():
            path = os.path.join(self.s.doc.project_dir, rel)
            if data is None:
                if os.path.exists(path):
                    os.remove(path)
            else:
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, 'wb') as f:
                    f.write(data)

    def redo(self):
        if self.before is None:
            self.before = self.s.doc.snapshot()
            # snapshot EVERY existing asset before the op (an op may rewrite
            # a sheet another command created — its 'before' bytes matter)
            self.assets = sorted(set(self.assets) | set(self._new_assets()))
            self.files_before = self._read_files()
            try:
                self.result = self.op(self.s.doc)
            except Exception as ex:          # S95: a failed op leaves no trace
                self.s.doc.restore(self.before)
                self._write_files(self.files_before)
                self.error = ex
                self.setObsolete(True)       # the stack drops it after this redo
                self.s.renderer.invalidate()
                self.s.renderer._sheet_cache.clear()
                self.s.structureChanged.emit()
                return
            # assets may have been created by the op — record them now
            self.assets = sorted(set(self.assets) | set(self._new_assets()))
            self.files_after = self._read_files()
            self.after = self.s.doc.snapshot()
        else:
            self.s.doc.restore(self.after)
            self._write_files(self.files_after)
        self.s.renderer.invalidate()
        self.s.renderer._sheet_cache.clear()
        self.s.structureChanged.emit()

    def _new_assets(self):
        return [t.get('raw2bpp') for t in self.s.doc.custom.get('tilesets', [])
                if t.get('raw2bpp')]

    def undo(self):
        self.s.doc.restore(self.before)
        self._write_files({k: self.files_before.get(k) for k in self.assets})
        self.s.renderer.invalidate()
        self.s.renderer._sheet_cache.clear()
        self.s.structureChanged.emit()


class PaintCells(QUndoCommand):
    """A stroke (pencil drag / rect / fill) on one layout grid."""
    ID = 1001

    def __init__(self, session, lid, kind, changes, label='Paint'):
        super().__init__(f'{label} {len(changes)} cell(s)')
        self.s, self.lid, self.kind = session, lid, kind
        self.changes = list(changes)          # (r, c, new)
        self.inverse = None

    def redo(self):
        self.inverse = self.s.doc.set_cells(self.lid, self.kind, self.changes)
        self.s.layoutChanged.emit(self.lid)

    def undo(self):
        self.s.doc.set_cells(self.lid, self.kind, self.inverse)
        self.s.layoutChanged.emit(self.lid)


class AddState(QUndoCommand):
    def __init__(self, session, room_id, key, copy_from=None,
                 own_layout=False, renderer_grid=None):
        super().__init__(f'Add state (screen {key})')
        self.s, self.room_id, self.key = session, room_id, key
        self.copy_from, self.own, self.grid = copy_from, own_layout, renderer_grid
        self.index = self.new_lid = None
        self.converted = False

    def redo(self):
        room = self.s.doc.room(self.room_id)
        self.converted = self.s.doc.ensure_states(room, self.key)
        self.index, self.new_lid = self.s.doc.add_state(
            room, self.key, copy_from=self.copy_from, own_layout=self.own,
            renderer_grid=self.grid)
        self.s.renderer.invalidate()
        self.s.structureChanged.emit()

    def undo(self):
        room = self.s.doc.room(self.room_id)
        self.s.doc.remove_state(room, self.key, self.index)
        if self.new_lid:
            self.s.doc.remove_layout(self.new_lid)
        if self.converted:
            self.s.doc.collapse_states(room, self.key)
        self.s.renderer.invalidate()
        self.s.structureChanged.emit()


class RemoveState(QUndoCommand):
    def __init__(self, session, room_id, key, index):
        super().__init__(f'Remove state {index} (screen {key})')
        self.s, self.room_id, self.key, self.index = session, room_id, key, index
        self.removed = None

    def redo(self):
        room = self.s.doc.room(self.room_id)
        self.removed = self.s.doc.remove_state(room, self.key, self.index)
        self.s.structureChanged.emit()

    def undo(self):
        room = self.s.doc.room(self.room_id)
        self.s.doc.restore_state(room, self.key, self.index, self.removed)
        self.s.structureChanged.emit()


class LocalizeLayout(QUndoCommand):
    """vanilla {bank, entry} reference -> editable custom.layouts item."""

    def __init__(self, session, room_id, key, state_idx, grid, attr=None):
        super().__init__(f'Make layout editable (screen {key})')
        self.s, self.room_id, self.key, self.idx = session, room_id, key, state_idx
        self.grid, self.attr = grid, attr
        self.lid = self.old = None
        self.snapshot = None

    def redo(self):
        room = self.s.doc.room(self.room_id)
        self.snapshot = copy.deepcopy(room['screens'][str(self.key)])
        self.lid, self.old = self.s.doc.localize_layout(
            room, self.key, self.idx, self.grid, self.attr)
        self.s.renderer.invalidate()
        self.s.structureChanged.emit()

    def undo(self):
        room = self.s.doc.room(self.room_id)
        room['screens'][str(self.key)] = self.snapshot
        self.s.doc.remove_layout(self.lid)
        self.s.doc.touch()
        self.s.renderer.invalidate()
        self.s.structureChanged.emit()


class SetStateLayout(QUndoCommand):
    def __init__(self, session, room_id, key, idx, ref):
        super().__init__(f'Change layout (screen {key}, state {idx})')
        self.s, self.room_id, self.key, self.idx, self.ref = \
            session, room_id, key, idx, ref
        self.old = None

    def redo(self):
        room = self.s.doc.room(self.room_id)
        self.old = self.s.doc.set_state_layout(room, self.key, self.idx, self.ref)
        self.s.structureChanged.emit()

    def undo(self):
        room = self.s.doc.room(self.room_id)
        self.s.doc.set_state_layout(room, self.key, self.idx, self.old)
        self.s.structureChanged.emit()


class AddScreen(QUndoCommand):
    def __init__(self, session, room_id, key, grid, attr=None, lid=None, palette=None):
        super().__init__(f'Add screen {key}')
        self.s, self.room_id, self.key = session, room_id, key
        self.grid, self.attr, self.lid_want = grid, attr, lid
        self.palette = palette
        self.lid = None
        self.old_dims = None

    def redo(self):
        room = self.s.doc.room(self.room_id)
        self.lid = self.s.doc.unique_layout_id(
            self.lid_want or f"{self.room_id}_s{self.key}")
        self.s.doc.add_layout(self.lid, tiles=self.grid, attr=self.attr,
                              comment=f"{self.room_id} screen {self.key}")
        rec = room.get('record') or {}
        self.old_dims = (rec.get('width_px'), rec.get('height_px'))
        self.s.doc.add_screen(room, self.key, {'id': self.lid}, palette=self.palette)
        self.s.renderer.invalidate()
        self.s.structureChanged.emit()

    def undo(self):
        room = self.s.doc.room(self.room_id)
        self.s.doc.remove_screen(room, self.key)
        self.s.doc.remove_layout(self.lid)
        rec = room.get('record')
        if rec and self.old_dims[0] is not None:
            rec['width_px'], rec['height_px'] = self.old_dims
        self.s.renderer.invalidate()
        self.s.structureChanged.emit()


class RemoveScreen(QUndoCommand):
    def __init__(self, session, room_id, key):
        super().__init__(f'Remove screen {key}')
        self.s, self.room_id, self.key = session, room_id, key
        self.removed = self.old_dims = None

    def redo(self):
        room = self.s.doc.room(self.room_id)
        rec = room.get('record') or {}
        self.old_dims = (rec.get('width_px'), rec.get('height_px'))
        self.removed = self.s.doc.remove_screen(room, self.key)
        self.s.structureChanged.emit()

    def undo(self):
        room = self.s.doc.room(self.room_id)
        self.s.doc.restore_screen(room, self.key, self.removed)
        rec = room.get('record')
        if rec and self.old_dims[0] is not None:
            rec['width_px'], rec['height_px'] = self.old_dims
        self.s.structureChanged.emit()


class SetPaletteColor(QUndoCommand):
    ID = 1002

    def __init__(self, session, pid, slot, idx, rgb555):
        super().__init__(f'Palette {pid} slot {slot} colour {idx}')
        self.s, self.pid, self.slot, self.idx, self.new = \
            session, pid, slot, idx, rgb555
        self.old = None

    def redo(self):
        self.old = self.s.doc.set_palette_color(self.pid, self.slot,
                                                self.idx, self.new)
        self.s.paletteChanged.emit(self.pid)

    def undo(self):
        pal = self.s.doc.palette(self.pid)
        pal['colors_rgb555'][self.slot][self.idx] = self.old
        self.s.doc.touch()
        self.s.paletteChanged.emit(self.pid)


class SetRoomField(QUndoCommand):
    """Generic scalar edit on a room dict path, e.g. ('record',
    'collision_threshold') or ('render', 'palette')."""

    def __init__(self, session, room_id, path, value, label=None):
        super().__init__(label or f"Set {'.'.join(path)}")
        self.s, self.room_id, self.path, self.value = session, room_id, path, value
        self.old = self.existed = None

    def _node(self):
        node = self.s.doc.room(self.room_id)
        for p in self.path[:-1]:
            node = node.setdefault(p, {})
        return node

    def redo(self):
        node = self._node()
        k = self.path[-1]
        self.existed = k in node
        self.old = node.get(k)
        if self.value is None:
            node.pop(k, None)
        else:
            node[k] = self.value
        self.s.doc.touch()
        self.s.renderer.invalidate()
        self.s.structureChanged.emit()

    def undo(self):
        node = self._node()
        k = self.path[-1]
        if self.existed:
            node[k] = self.old
        else:
            node.pop(k, None)
        self.s.doc.touch()
        self.s.renderer.invalidate()
        self.s.structureChanged.emit()
