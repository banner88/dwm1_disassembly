"""document.py — the editable project.json model behind the GUI (P3.3, S93).

Pure Python, no Qt. Holds the project dict, loads/saves it WITHOUT
reformatting (json indent=1 reproduces the committed example project byte
for byte — verified S93), and exposes the mutations the Rooms tab needs.
Every mutation returns enough to be undone (the GUI wraps them in
QUndoCommands); nothing here re-derives a ROM format — the compiler
(editor2/core) stays the only place that knows how bytes are laid out.

Schema facts honoured (PROJECT_COMPILER §2.2 / §2.10):
  * screens keys "0".."15" on the 4x4 grid; record width/height in px MUST
    match the occupied columns/rows (KEY_LESSONS S10) — add/remove screen
    keeps them in step.
  * screens[].states[]: with `states` present, top-level npcs/exits are an
    ERROR — conversion moves them into states[0]; a state omitting `layout`
    inherits the screen's.
  * custom.layouts[] declaration order == bank $64 entry order (tiles then
    attr per item); CustomAttrCheck reads screen>0 attrs at base_entry+2.
  * the 8-NPC hard cap per screen-state (capacities.json, S91) is reported
    by `state_capacity`, never silently exceeded by an editor action.
"""

import copy
import importlib.util
import json
import re
import os

from editor2.core import layouts as L
from editor2.core.doors import DoorsMixin
from editor2.core.talk import TalkMixin

SCREEN_W, SCREEN_H = 20, 16
GRID_COLS, GRID_ROWS = 4, 4          # engine scroll grid (row*4+col), S94 schema
NPC_HARD_CAP = 8


def val(v):
    if isinstance(v, int):
        return v
    s = str(v).strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


def hexs(n, width=2):
    return f'0x{n:0{width}X}'


# ------------------------------------------------ metatile palettes (S96)
# A metatile's 'pal' is an int (all four subtiles on one BG palette slot) or
# a list of four [tl, tr, bl, br]: the attr grid is per 8x8 subtile and
# vanilla rooms really do mix slots inside one 16x16 cell (3,156 of 42,080
# vanilla cells, S96 census — tree tops over a trunk, shore edges), and
# imported art needs it too. Readers go through these two helpers.
def metatile_pals(mt):
    """-> [tl, tr, bl, br] palette slots, or None when the metatile carries
    no palette (paint tiles only)."""
    p = mt.get('pal')
    if p is None:
        return None
    if isinstance(p, (list, tuple)):
        return [int(x) & 7 for x in p]
    return [int(p) & 7] * 4


def pal_value(pals):
    """Canonical storage form: an int when uniform, else a list of 4."""
    if pals is None:
        return None
    pals = [int(x) & 7 for x in pals]
    return pals[0] if len(set(pals)) == 1 else pals


def metatile_key(mt):
    """Hashable identity (tiles + palettes) for de-duplication."""
    p = metatile_pals(mt)
    return (tuple(int(t) for t in mt['tiles']), tuple(p) if p else None)



class ThresholdShiftNeeded(RuntimeError):
    """S98 r2: the walkable side of the sheet is full but the wall side has
    room — moving the wall/walkable split DOWN one slot would make space.
    The GUI asks the author (user: "make that an option") and retries with
    shift_ok=True."""

class Document(DoorsMixin, TalkMixin):
    def __init__(self, path):
        self.path = path if path.endswith('.json') else \
            os.path.join(path, 'project.json')
        self.project_dir = os.path.dirname(self.path)
        src = open(self.path, encoding='utf-8').read()
        self.data = json.loads(src)
        # keep the file's own indentation (the example project uses 1)
        self.indent = self._detect_indent(src)
        self.trailing_newline = src.endswith('\n')
        self.dirty = False
        self._saved_text = src
        self._protected = {}          # tileset id -> vocabulary indices (session)
        # S96: the live renderer (vanilla_gfx / vanilla_tiles_used / rom_sheet)
        # — set by the GUI Session; tileset-usage queries degrade gracefully
        # (no vanilla vocabulary, no 'changed' flags) without it.
        self.vanilla = None
        self.migrations = self._migrate()

    # ---------------------------------------------------------- migration
    # S94 made `record` REQUIRED for every room (ROM0 $26DD rows $6B-$6F are
    # compiler-owned now). Projects saved before that (or an old
    # example-project.json next to new editor code — user S95 build failure)
    # get the hand-patched legacy rows filled in on open, so Build works.
    LEGACY_RECORDS = {
        0x6B: ('0x0D', '0x28', 160, 256, '0x30'),
        0x6C: ('0x0D', '0x28', 160, 256, '0x30'),
        0x6D: ('0x0D', '0x28', 160, 128, '0x30'),
    }

    def _migrate(self):
        notes = []
        for r in self.custom.get('rooms', []):
            if r.get('placeholder') or r.get('record'):
                continue
            mid = val(r.get('mapID', 0))
            if mid in self.LEGACY_RECORDS:
                g, b, w, h, thr = self.LEGACY_RECORDS[mid]
                r['record'] = {'gfx_id': g, 'gfx_bank': b, 'width_px': w,
                               'height_px': h, 'collision_threshold': thr}
                notes.append(f"room {r.get('id')} (${mid:02X}): added the legacy "
                             "hand-patched $26DD record (S94 schema: record required)")
        # S96: scripts cloned before the handler-arity table (S92 extract_room
        # on decompile_script's counts) are regrouped — identical words, so the
        # ROM does not change; the arity warnings go away
        from editor2.core import scriptgen as SG
        for sc in self.custom.get('scripts', []):
            new, changed = SG.regroup_ops(sc.get('ops', []))
            if changed:
                sc['ops'] = new
                notes.append(f"script {sc.get('id')}: regrouped by the handler "
                             "arity table (same bytes)")
        # S98 r2: door pairs -> linked door objects
        self._migrate_doors(notes)
        self._migrate_door_arrivals(notes)
        if notes:
            self.dirty = True
        return notes

    @staticmethod
    def _detect_indent(src):
        for line in src.splitlines()[1:]:
            stripped = line.lstrip(' ')
            if stripped and stripped != line:
                return len(line) - len(stripped)
        return 1

    # ------------------------------------------------------------ persist
    def dumps(self):
        return (json.dumps(self.data, indent=self.indent)
                + ('\n' if self.trailing_newline else ''))

    def save(self, path=None):
        path = path or self.path
        text = self.dumps()
        tmp = path + '.tmp'
        with open(tmp, 'w', encoding='utf-8') as f:
            f.write(text)
        os.replace(tmp, path)
        if path == self.path:
            self._saved_text = text
            self.dirty = False

    def is_modified(self):
        return self.dumps() != self._saved_text

    def touch(self):
        self.dirty = True

    # ------------------------------------------------------------ lookups
    @property
    def custom(self):
        return self.data.setdefault('custom', {})

    @property
    def rooms(self):
        return self.custom.setdefault('rooms', [])

    @property
    def layouts(self):
        return self.custom.setdefault('layouts', [])

    @property
    def palettes(self):
        return self.custom.setdefault('palettes', [])

    def room(self, room_id):
        for r in self.rooms:
            if r.get('id') == room_id:
                return r
        raise KeyError(room_id)

    def room_index(self, room_id):
        for i, r in enumerate(self.rooms):
            if r.get('id') == room_id:
                return i
        raise KeyError(room_id)

    def layout(self, lid):
        for l in self.layouts:
            if l.get('id') == lid:
                return l
        raise KeyError(lid)

    def has_layout(self, lid):
        return any(l.get('id') == lid for l in self.layouts)

    def palette(self, pid):
        for p in self.palettes:
            if p.get('id') == pid:
                return p
        raise KeyError(pid)

    def screen(self, room, key):
        return room['screens'][str(key)]

    def screen_keys(self, room):
        return sorted((int(k) for k in room.get('screens', {})), key=int)

    def states(self, room, key):
        """List of state dicts (always >= 1 entry; the implicit single state
        is the screen itself)."""
        scr = self.screen(room, key)
        return scr['states'] if scr.get('states') else [scr]

    def state_layout_ref(self, room, key, idx):
        scr = self.screen(room, key)
        if scr.get('states'):
            st = scr['states'][idx]
            return st.get('layout', scr.get('layout'))
        return scr.get('layout')

    def state_capacity(self, room, key, idx):
        st = self.states(room, key)[idx]
        n = sum(1 for e in st.get('npcs', [])
                if e.get('kind') == 'npc'
                or (e.get('kind') == 'raw' and val(e['bytes'][0]) < 0x80))
        return n, NPC_HARD_CAP

    # ------------------------------------------------------- tile editing
    def set_cells(self, lid, kind, changes):
        """changes: [(row, col, new)] on the layout's 'tiles' or 'attr'
        grid. Returns the inverse change list."""
        grid = self.layout(lid)[kind]
        inverse = []
        for r, c, new in changes:
            inverse.append((r, c, grid[r][c]))
            grid[r][c] = int(new)
        self.touch()
        return inverse

    def get_cell(self, lid, kind, r, c):
        return self.layout(lid)[kind][r][c]

    # -------------------------------------------------------- new layouts
    def unique_layout_id(self, base):
        cand, n = base, 2
        while self.has_layout(cand):
            cand = f'{base}_{n}'
            n += 1
        return cand

    def add_layout(self, lid, tiles=None, attr=None, comment=None,
                   index=None):
        """Append a custom.layouts item (index= only for undo restore —
        declaration order == bank $64 entry order, and the attr stride
        base_entry+2 of EXISTING rooms depends on it, so new items append)."""
        item = {'id': lid}
        if comment:
            item['comment'] = comment
        if tiles is not None:
            item['tiles'] = [list(r) for r in tiles]
        if attr is not None:
            item['attr'] = [list(r) for r in attr]
        if index is None:
            self.layouts.append(item)
        else:
            self.layouts.insert(index, item)
        self.touch()
        return item

    def remove_layout(self, lid):
        for i, l in enumerate(self.layouts):
            if l.get('id') == lid:
                self.touch()
                return i, self.layouts.pop(i)
        raise KeyError(lid)

    def layout_users(self, lid):
        """[(room_id, screen_key, state_idx|None, 'layout'|'attr')]"""
        out = []
        for r in self.rooms:
            at = (r.get('render') or {}).get('attr') or {}
            if at.get('id') == lid:
                out.append((r['id'], None, None, 'attr'))
            for k, scr in (r.get('screens') or {}).items():
                if (scr.get('layout') or {}).get('id') == lid:
                    out.append((r['id'], int(k), None, 'layout'))
                for i, st in enumerate(scr.get('states') or []):
                    if (st.get('layout') or {}).get('id') == lid:
                        out.append((r['id'], int(k), i, 'layout'))
        return out

    # ------------------------------------------------------------- states
    def ensure_states(self, room, key):
        """Convert a single-state screen into the states[] form (schema:
        with states present, top-level npcs/exits must go). Idempotent.
        Returns True if a conversion happened."""
        scr = self.screen(room, key)
        if scr.get('states'):
            return False
        st = {'npcs': scr.pop('npcs', []), 'exits': scr.pop('exits', []),
              'comment': 'state 0'}
        scr['states'] = [st]
        self.touch()
        return True

    def collapse_states(self, room, key):
        """Inverse of ensure_states when exactly one state remains."""
        scr = self.screen(room, key)
        sts = scr.get('states')
        if not sts or len(sts) != 1:
            return False
        st = sts[0]
        scr.pop('states')
        if 'layout' in st:
            scr['layout'] = st['layout']
        scr['npcs'] = st.get('npcs', [])
        scr['exits'] = st.get('exits', [])
        self.touch()
        return True

    def add_state(self, room, key, index=None, copy_from=None,
                  own_layout=False, renderer_grid=None):
        """Insert a new state (duplicate of `copy_from` or empty). With
        own_layout, the new state gets its own copy of the source layout
        (a new custom.layouts item placed right after the source so the
        $64 order stays readable). Returns (index, new_layout_id|None)."""
        self.ensure_states(room, key)
        scr = self.screen(room, key)
        sts = scr['states']
        if copy_from is not None:
            src = sts[copy_from]
            st = copy.deepcopy(src)
            st['comment'] = f"state {len(sts)} (copy of {copy_from})"
        else:
            st = {'npcs': [], 'exits': [], 'comment': f'state {len(sts)}'}
        new_lid = None
        if own_layout:
            ref = st.get('layout', scr.get('layout'))
            grid = None
            src_index = None
            if ref and 'id' in ref:
                grid = self.layout(ref['id'])['tiles']
                base = ref['id']
            else:
                grid = renderer_grid
                base = f"{room['id']}_s{key}"
            if grid is None:
                raise ValueError('own_layout needs a source grid')
            # ALWAYS append: inserting mid-list shifts later $64 entries and
            # breaks the base_entry+2 attr stride of existing rooms.
            new_lid = self.unique_layout_id(f'{base}_st')
            self.add_layout(new_lid, tiles=grid,
                            comment=f"{room['id']} screen {key} state layout")
            st['layout'] = {'id': new_lid}
        if index is None:
            index = len(sts)
        sts.insert(index, st)
        self.touch()
        return index, new_lid

    def remove_state(self, room, key, index):
        scr = self.screen(room, key)
        sts = scr['states']
        if len(sts) <= 1:
            raise ValueError('a screen always keeps at least one state')
        removed = sts.pop(index)
        self.touch()
        return removed

    def restore_state(self, room, key, index, state):
        self.screen(room, key)['states'].insert(index, state)
        self.touch()

    def set_state_layout(self, room, key, idx, ref):
        scr = self.screen(room, key)
        if scr.get('states'):
            old = scr['states'][idx].get('layout')
            if ref is None:
                scr['states'][idx].pop('layout', None)
            else:
                scr['states'][idx]['layout'] = ref
        else:
            old = scr.get('layout')
            scr['layout'] = ref
        self.touch()
        return old

    # ------------------------------------------------------- localization
    def localize_layout(self, room, key, state_idx, grid, attr_grid=None):
        """Turn a vanilla {bank, entry} layout reference into an editable
        custom.layouts item carrying the decompressed grid. Returns
        (new_layout_id, old_ref)."""
        ref = self.state_layout_ref(room, key, state_idx)
        if ref is None or 'id' in ref:
            raise ValueError('layout is already project-owned')
        lid = self.unique_layout_id(f"{room['id']}_s{key}")
        self.add_layout(
            lid, tiles=grid, attr=attr_grid,
            comment=f"localized from bank {ref['bank']} entry {ref['entry']} "
                    f"({room['id']} screen {key})")
        old = self.set_state_layout(room, key, state_idx, {'id': lid})
        # the screen-level ref stays as the inherited default when the
        # state had none; make the edit stick on the screen itself then
        scr = self.screen(room, key)
        if scr.get('states') and 'layout' not in scr['states'][state_idx]:
            scr['states'][state_idx]['layout'] = {'id': lid}
        return lid, old

    # ------------------------------------------------------------ screens
    def add_screen(self, room, key, layout_ref, palette=None):
        """palette= (S95): the palette id the new screen should show — the
        GUI passes the palette in effect on the screen the author is
        looking at, so a new screen never falls back to a room default the
        author has already moved away from (user S95: servant room went
        back to 'burning' colours on the second screen)."""
        scr = room.setdefault('screens', {})
        if str(key) in scr:
            raise ValueError(f'screen {key} exists')
        scr[str(key)] = {'layout': layout_ref, 'step_counter': 'auto',
                         'npcs': [], 'exits': []}
        if palette and palette != (room.get('render') or {}).get('palette'):
            scr[str(key)]['palette'] = palette
        # keep declaration order sorted for readable JSON
        room['screens'] = {k: scr[k] for k in sorted(scr, key=int)}
        self.sync_record_dims(room)
        self.touch()

    def remove_screen(self, room, key):
        removed = room['screens'].pop(str(key))
        self.sync_record_dims(room)
        self.touch()
        return removed

    def restore_screen(self, room, key, scr):
        room['screens'][str(key)] = scr
        room['screens'] = {k: room['screens'][k]
                           for k in sorted(room['screens'], key=int)}
        self.sync_record_dims(room)
        self.touch()

    def sync_record_dims(self, room):
        """record.width_px/height_px follow the occupied grid (KL S10).
        Rooms without a record (legacy < $70) are left alone."""
        rec = room.get('record')
        if not rec:
            return None
        keys = self.screen_keys(room)
        if not keys:
            return None
        cols = max(k % GRID_COLS for k in keys) + 1
        rows = max(k // GRID_COLS for k in keys) + 1
        old = (rec.get('width_px'), rec.get('height_px'))
        rec['width_px'] = cols * 160
        rec['height_px'] = rows * 128
        return old

    def blank_grid(self, fill=0):
        return [[fill] * SCREEN_W for _ in range(SCREEN_H)]

    # ----------------------------------------------------------- palettes
    def effective_palette(self, room, key, state_idx):
        """states[n].palette › screens[k].palette › render.palette › None."""
        scr = self.screen(room, key)
        sts = scr.get('states') or []
        pid = sts[state_idx].get('palette') if state_idx < len(sts) else None
        return pid or scr.get('palette') or (room.get('render') or {}).get('palette')

    def set_state_palette(self, room, key, state_idx, pid):
        """Assign a project palette to ONE screen/state (None = inherit).
        With states[] present the state carries it, else the screen."""
        scr = self.screen(room, key)
        target = scr['states'][state_idx] if scr.get('states') else scr
        old = target.get('palette')
        if pid:
            target['palette'] = pid
        else:
            target.pop('palette', None)
        self.touch()
        return old

    def add_palette_from_words(self, base_id, words, comment):
        """New custom.palettes item from 8x4 RGB555 words; returns its id."""
        pid, n = base_id, 2
        while any(p.get('id') == pid for p in self.palettes):
            pid = f'{base_id}_{n}'
            n += 1
        rows = [[hexs(int(c), 4) for c in row] for row in words[:8]]
        while len(rows) < 8:
            rows.append(['0x0000', '0x6BFF', '0x7FFF', '0x0000'])
        self.palettes.append({'id': pid, 'label': f'CustomPaletteColors_{pid}',
                              'placement': 'b', 'colors_rgb555': rows,
                              'comment': [comment]})
        self.touch()
        return pid

    def set_palette_free1(self, pid, on):
        """S96: mark a palette `free_color1` — in a custom room its slots 0-3
        keep their own colour 1 (FreeColor1Hook) instead of the engine's
        cream. Turning it on leaves the authored colour 1 values as they
        are (a localized vanilla palette already holds $6BFF there, so the
        room looks the same until colour 1 is edited). Returns old state."""
        pal = self.palette(pid)
        old = bool(pal.get('free_color1'))
        if on:
            pal['free_color1'] = True
        else:
            pal.pop('free_color1', None)
        self.touch()
        return old

    def set_palette_color(self, pid, slot, idx, rgb555):
        row = self.palette(pid)['colors_rgb555'][slot]
        old = row[idx]
        row[idx] = hexs(rgb555, 4)
        self.touch()
        return old

    # ------------------------------------------------------------- rooms
    def next_free_mapid(self):
        used = {val(r['mapID']) for r in self.rooms}
        m = 0x6B
        while m in used:
            m += 1
        return m

    def unique_room_id(self, base):
        ids = {r.get('id') for r in self.rooms}
        cand, n = base, 2
        while cand in ids:
            cand = f'{base}_{n}'
            n += 1
        return cand

    # ============================================================ S94 ====
    # Room model: vanilla -> custom clone, copy, new, rename, delete.
    # Structural ops are wrapped by the GUI in a SNAPSHOT command (whole
    # `data` deep copy before/after + any asset files touched), so they
    # need no inverse of their own.
    # =====================================================================

    def snapshot(self):
        return copy.deepcopy(self.data)

    def restore(self, snap):
        self.data.clear()
        self.data.update(copy.deepcopy(snap))
        self.touch()

    def room_name(self, room):
        return room.get('name') or room.get('id', '?')

    def rename_room(self, room_id, name):
        r = self.room(room_id)
        old = r.get('name')
        r['name'] = name
        self.touch()
        return old

    def _slug(self, name):
        out = ''.join(ch.lower() if ch.isalnum() else '_' for ch in name).strip('_')
        while '__' in out:
            out = out.replace('__', '_')
        return out or 'room'

    def clone_vanilla(self, source_mid, name, repo_root, renderer=None):
        """Vanilla room -> full custom clone via tools/extract_room.extract
        (P3.2b). Returns the new room id. Appends room/layouts/palette/
        scripts/music exactly like extract_room --apply."""
        path = os.path.join(repo_root, 'tools', 'extract_room.py')
        spec = importlib.util.spec_from_file_location('_extract_room', path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        rid = self.unique_room_id(self._slug(name))
        target = self.next_free_mapid()
        room, layouts, palette, scripts, music, _rep = mod.extract(
            source_mid, rid, target, 0, self.project_dir)
        room['name'] = name
        for k in list(room):
            if k.startswith('_'):
                room.pop(k)
        for lay in layouts:
            for k in list(lay):
                if k.startswith('_') or k == 'comment':
                    lay.pop(k)
        for sc in scripts:
            sc.pop('_source', None)
        # S94: make the clone PAINTABLE at once — decompress each screen's
        # vanilla layout into the item that already carries that screen's
        # attr grid (tiles+attr per item, screen order = the L0,A0,L1,A1
        # interleave CustomAttrCheck's base/base+2 stride expects).
        if renderer is not None:
            by_id = {l['id']: l for l in layouts}
            for k in sorted(room['screens'], key=int):
                scr = room['screens'][k]
                ref = scr.get('layout')
                if not ref or 'id' in ref:
                    continue
                item = by_id.get(f'{rid}_attr_s{k}')
                grid = renderer.vanilla_layout_grid(val(ref['bank']), val(ref['entry']))
                if item is None:
                    item = {'id': f'{rid}_attr_s{k}'}
                    layouts.append(item)
                    by_id[item['id']] = item
                item['tiles'] = [list(r) for r in grid]
                nid = f'{rid}_s{k}'
                old_id = item['id']
                item['id'] = nid
                scr['layout'] = {'id': nid}
                if (scr.get('attr') or {}).get('id') == old_id:
                    scr['attr'] = {'id': nid}
                for st in scr.get('states') or []:
                    if st.get('layout') == ref:
                        st['layout'] = {'id': nid}
                at = (room.get('render') or {}).get('attr') or {}
                if at.get('id') == old_id:
                    at['id'] = nid
        # S94: EVERY vanilla state (valid step entry) becomes a states[] entry
        # with its own tile layout (the servant boss room: burning / cleared),
        # and the room's own step counters get project labels so the cloned
        # scripts that write/test them (write_ram / check_and_branch) keep
        # working inside the clone. Attr stays per screen (custom engine).
        counters = {}
        if renderer is not None:
            for k in sorted(room['screens'], key=int):
                scr = room['screens'][k]
                steps = renderer.vanilla_steps(source_mid, int(k))
                label = f"wCustomStep_{rid}_S{k}".replace('-', '_')
                scr['step_counter'] = {'label': label}
                counters[renderer.vanilla_counter(source_mid, int(k))] = label
                # S96: a screen whose step-0 palette is not the room's (e.g.
                # Labyrinth $42 screen 1) gets its own screens[k].palette — the
                # all-rooms clone parity sweep caught it
                pal_k = renderer.vanilla_step_palette_words(source_mid, int(k), 0)
                if pal_k and palette and \
                        [[val(c) for c in row] for row in palette['colors_rgb555'][:4]] != \
                        [list(r) for r in pal_k]:
                    pid = f"{palette['id']}_s{k}"
                    rows = [[hexs(c, 4) for c in r] for r in pal_k] + \
                        [list(r) for r in palette['colors_rgb555'][4:]]
                    self.palettes.append({'id': pid, 'label': f'CustomPaletteColors_{pid}',
                                          'placement': 'b', 'colors_rgb555': rows,
                                          'comment': [f'vanilla ${source_mid:02X} screen {k} '
                                                      'step 0 palette']})
                    scr['palette'] = pid
                if len(steps) <= 1:
                    continue
                base_lid = scr['layout']['id']
                st0 = {'npcs': scr.pop('npcs', []), 'exits': scr.pop('exits', []),
                       'comment': 'vanilla step 0'}
                states = [st0]
                base_item = self.layout_by_id_in(layouts, base_lid)
                pal0 = renderer.vanilla_step_palette_words(source_mid, int(k), 0)
                for n, st in enumerate(steps[1:], 1):
                    b01 = int(st['bytes_0_1'], 16)
                    grid = renderer.vanilla_layout_grid(b01 >> 8, b01 & 0xFF)
                    lid = f'{base_lid}_st{n}'
                    entry = {'npcs': [], 'exits': [], 'comment': f'vanilla step {n}'}
                    attr_n = renderer.vanilla_attr_grid(source_mid, int(k), n)
                    own = {}
                    if grid != base_item['tiles']:
                        own['tiles'] = [list(r) for r in grid]
                    if attr_n and attr_n != base_item.get('attr'):
                        own['attr'] = [list(r) for r in attr_n]
                    if own:
                        item = {'id': lid}
                        item.update(own)
                        if 'tiles' not in item:
                            item['tiles'] = [list(r) for r in base_item['tiles']]
                        layouts.append(item)
                        entry['layout'] = {'id': lid}
                        if 'attr' in item:
                            entry['attr'] = {'id': lid}
                    # per-step PALETTE (vanilla varies it per step, e.g. the
                    # servant boss room burning -> cleared)
                    pal_n = renderer.vanilla_step_palette_words(source_mid, int(k), n)
                    if pal_n and pal_n != pal0 and palette:
                        pid = f"{palette['id']}_s{k}_st{n}"
                        rows = [list(r) for r in pal_n] + [list(r) for r in palette['colors_rgb555'][4:]]
                        self.palettes.append({'id': pid, 'label': f'CustomPaletteColors_{pid}',
                                              'placement': 'b', 'colors_rgb555': rows,
                                              'comment': [f'vanilla ${source_mid:02X} screen {k} step {n} palette']})
                        entry['palette'] = pid
                    for it in st.get('interact_data', []):
                        raw = [int(x, 16) for x in it['raw'].split()]
                        entry['npcs'].append({'kind': 'raw',
                                              'bytes': [f'0x{b:02X}' for b in raw]})
                    for ex in st.get('exit_data', []):
                        raw = [int(x, 16) for x in ex['raw'].split()]
                        entry['exits'].append({
                            'x': raw[0], 'y': raw[1], 'dest': f'vanilla:${raw[2]:02X}',
                            'gate_flag': raw[3], 'screen_byte': f'0x{raw[4]:02X}',
                            'spawn_x': raw[5], 'spawn_y': raw[6]})
                    states.append(entry)
                scr['states'] = states
            # rewire the cloned scripts' references to this room's own counters
            addr_names = {a: lab for a, lab in counters.items()}
            for sc in scripts:
                for op in sc.get('ops', []):
                    if (isinstance(op, list) and len(op) >= 3 and op[0] == 'op'
                            and op[1] in ('write_ram', 'write_ram2', 'check_and_branch')):
                        try:
                            a = val(op[2])
                        except Exception:
                            continue
                        if a in addr_names:
                            op[2] = addr_names[a]
        self.rooms.append(room)
        self.layouts.extend(layouts)
        if palette:
            self.palettes.append(palette)
        self.custom.setdefault('scripts', []).extend(scripts)
        if music:
            self.custom.setdefault('music', {}).setdefault(
                'room_defaults', {}).update(music)
        self.touch()
        return rid

    @staticmethod
    def layout_by_id_in(layouts, lid):
        return next(l for l in layouts if l.get('id') == lid)

    def copy_room(self, room_id, name):
        """custom -> custom copy with its OWN layout items (tiles + attr) so
        painting the copy never touches the original. Layout copies are
        appended in the source's declaration order (keeps the base+2 attr
        stride when the source's items were consecutive)."""
        src = self.room(room_id)
        rid = self.unique_room_id(self._slug(name))
        room = copy.deepcopy(src)
        room['id'] = rid
        room['name'] = name
        room['mapID'] = hexs(self.next_free_mapid())
        # S98 r2 (user: "when I make a custom room it should STOP sharing
        # tilesets by default"): a copy of a room with a project tileset
        # gets its OWN copy of that sheet (+ its metatiles), so imports and
        # walkability twins in one never eat the other's slots
        rec = room.get('record') or {}
        if rec.get('tileset'):
            rec['tileset'] = self.duplicate_tileset(rec['tileset'], f'ts_{rid}')
        for k in list(room):
            if k.startswith('_'):
                room.pop(k)
        # collect layout ids used, in declaration order
        used = []
        for lid in [l['id'] for l in self.layouts]:
            for rr, k, i, kind in self.layout_users(lid):
                if rr == room_id and lid not in used:
                    used.append(lid)
        remap = {}
        for lid in used:
            item = copy.deepcopy(self.layout(lid))
            nid = self.unique_layout_id(f'{rid}_{lid}')
            item['id'] = nid
            item.pop('comment', None)
            self.layouts.append(item)
            remap[lid] = nid

        def fix(ref):
            if ref and 'id' in ref and ref['id'] in remap:
                ref['id'] = remap[ref['id']]
        at = (room.get('render') or {}).get('attr')
        fix(at)
        for scr in (room.get('screens') or {}).values():
            fix(scr.get('layout'))
            for st in scr.get('states') or []:
                fix(st.get('layout'))
            # step counters are auto for the copy
            scr['step_counter'] = 'auto'
        # music sugar copies; room_defaults entry keyed by old mapID is not ours
        self.rooms.append(room)
        self.touch()
        return rid

    def new_room(self, name, source_mid, renderer, blank_tileset=False):
        """Blank single-screen room using a VANILLA room's tileset, palette
        and collision threshold (source_mid). Floor = first walkable tile.
        blank_tileset (S96): the room gets its own EMPTY project sheet
        (threshold $40) for imported art instead of the vanilla sheet."""
        rid = self.unique_room_id(self._slug(name))
        rec = renderer.vanilla_record(source_mid)
        rec['width_px'], rec['height_px'] = 160, 128
        if blank_tileset:
            tid = self.new_blank_tileset(f'ts_{rid}')
            rec.pop('gfx_id')
            rec.pop('gfx_bank')
            rec = {'tileset': tid, **rec}
            rec['collision_threshold'] = '0x40'
        thr = val(rec['collision_threshold'])
        lid = self.unique_layout_id(f'{rid}_s0')
        self.add_layout(lid, tiles=self.blank_grid(min(thr, 127)),
                        attr=self.blank_grid(0))
        room = {'id': rid, 'name': name, 'mapID': hexs(self.next_free_mapid()),
                'source_mapID': hexs(source_mid), 'record': rec,
                'render': {'attr': {'id': lid}},
                # S98: no 'spawn' marker — the $8F entry is an EXAMINE SPOT
                # (PyBoy-measured); arrival comes from the door / warp
                'screens': {'0': {'layout': {'id': lid}, 'step_counter': 'auto',
                                  'npcs': [], 'exits': []}}}
        self.rooms.append(room)
        self.touch()
        return rid

    def delete_room(self, room_id):
        """Remove a room (the compiler fills mapID gaps with placeholders).
        Layout items it owned exclusively are removed too."""
        r = self.room(room_id)
        owned = [lid for lid in [l['id'] for l in self.layouts]
                 if self.layout_users(lid)
                 and all(u[0] == room_id for u in self.layout_users(lid))]
        # S98 r2: this room's doors go; their partners stay, unconnected
        for d in self.doors_touching(room_id):
            self.remove_door(d['id'])
        # S94b: redirects into the room would dangle (compiler: unknown dest)
        for i, _ in sorted(self.redirects_to(room_id), reverse=True):
            self.remove_redirect(i)
        self.rooms.remove(r)
        for lid in owned:
            self.remove_layout(lid)
        mid = hexs(val(r['mapID']))
        rd = (self.custom.get('music') or {}).get('room_defaults') or {}
        rd.pop(mid, None)
        self.touch()

    # ------------------------------------------------------ metatiles
    def metatiles(self, tileset_key):
        """User-defined metatiles for a tileset key ('bank:id' or the custom
        tileset id): [{name, tiles:[tl,tr,bl,br], pal}] — editor-only data
        under custom._editor (underscore = ignored by the compiler)."""
        return ((self.custom.get('_editor') or {}).get('metatiles') or {}).get(
            tileset_key, [])

    def _metatiles_mut(self, tileset_key):
        ed = self.custom.setdefault('_editor', {})
        return ed.setdefault('metatiles', {}).setdefault(tileset_key, [])

    def add_metatile(self, tileset_key, name, tiles, pal, src=None):
        lst = self._metatiles_mut(tileset_key)
        item = {'name': name, 'tiles': [int(t) for t in tiles],
                'pal': pal_value(metatile_pals({'pal': pal})
                                 if pal is not None else [0] * 4)}
        if src:
            item['src'] = src        # S98 r2: 'borrowed' (from another room's sheet)
        lst.append(item)
        self.touch()
        return len(lst) - 1

    # ---- S98 r2: purge unused metatiles (user: "a good way to purge unused
    # tiles, like a button … purge unused own and purge unused borrowed")
    _BORROWED_NAME = re.compile(r'\[\d+, \d+, \d+, \d+\]$')

    def metatile_kind(self, mt):
        """'borrowed' (imported from another room's tileset via Borrow) or
        'own' (made here, incl. PNG imports). Pre-S98r2 borrowed items are
        recognised by their '<Room> [a, b, c, d]' name."""
        if mt.get('src') == 'borrowed' or self._BORROWED_NAME.search(str(mt.get('name', ''))):
            return 'borrowed'
        return 'own'

    def placed_metatile_keys(self, tid):
        """The (tl, tr, bl, br) subtile tuples placed in any cell of any
        screen/state of the rooms drawing with this tileset."""
        out = set()
        for lid in self.layouts_using_tileset(tid):
            g = self.layout(lid)['tiles']
            for r in range(0, len(g) - 1, 2):
                for c in range(0, len(g[r]) - 1, 2):
                    out.add((g[r][c] & 0x7F, g[r][c + 1] & 0x7F,
                             g[r + 1][c] & 0x7F, g[r + 1][c + 1] & 0x7F))
        return out

    def unused_metatiles(self, tid, kind):
        """Indices (into metatiles(tid)) of `kind` metatiles placed nowhere."""
        placed = self.placed_metatile_keys(tid)
        return [i for i, mt in enumerate(self.metatiles(tid))
                if self.metatile_kind(mt) == kind
                and tuple(t & 0x7F for t in mt['tiles']) not in placed]

    def purge_preview(self, tid, kind, threshold):
        """(n metatiles, slots freed {'wall', 'walkable'}) — without changing
        anything."""
        idx = set(self.unused_metatiles(tid, kind))
        if not idx:
            return 0, {'wall': 0, 'walkable': 0}
        before = self.free_counts(tid, threshold)
        lst = self._metatiles_mut(tid)
        keep = list(lst)
        lst[:] = [m for i, m in enumerate(keep) if i not in idx]
        try:
            after = self.free_counts(tid, threshold)
        finally:
            lst[:] = keep
        return len(idx), {'wall': after['wall'] - before['wall'],
                          'walkable': after['walkable'] - before['walkable']}

    def purge_unused_metatiles(self, tid, kind):
        """Remove every unused `kind` metatile of this tileset. Their sheet
        slots become free unless something else still uses them. Returns the
        number removed."""
        idx = set(self.unused_metatiles(tid, kind))
        if idx:
            lst = self._metatiles_mut(tid)
            lst[:] = [m for i, m in enumerate(lst) if i not in idx]
            self.touch()
        return len(idx)

    def remove_metatile(self, tileset_key, index):
        lst = self._metatiles_mut(tileset_key)
        item = lst.pop(index)
        self.touch()
        return item

    # ---------------------------------------------------- tileset ops
    def tileset_key(self, room):
        rec = room.get('record') or {}
        if 'tileset' in rec:
            return rec['tileset']
        return f"{val(rec.get('gfx_bank', 0)):02X}:{val(rec.get('gfx_id', 0)):02X}"

    def tileset_item(self, tid):
        for t in self.custom.get('tilesets', []):
            if t.get('id') == tid:
                return t
        raise KeyError(tid)

    def rooms_using_tileset(self, tid):
        """Rooms drawing with tileset `tid` (a project tileset id, or a
        vanilla 'BB:II' key for rooms still borrowing a ROM sheet)."""
        return [r for r in self.rooms
                if r.get('record') and not r.get('placeholder')
                and self.tileset_key(r) == tid]

    def localize_tileset(self, room, sheet, name=None):
        """Copy the room's VANILLA tileset into the project (assets/<id>.2bpp
        + custom.tilesets item) and point the record at it. Returns the
        tileset id. Other rooms sharing the same vanilla sheet keep it."""
        rec = room['record']
        if 'tileset' in rec:
            return rec['tileset']
        base = name or f"ts_{val(rec['gfx_bank']):02X}_{val(rec['gfx_id']):02X}"
        ids = {t.get('id') for t in self.custom.get('tilesets', [])}
        tid, n = base, 2
        while tid in ids:
            tid = f'{base}_{n}'
            n += 1
        assets = os.path.join(self.project_dir, 'assets')
        os.makedirs(assets, exist_ok=True)
        rel = os.path.join('assets', f'{tid}.2bpp')
        with open(os.path.join(self.project_dir, rel), 'wb') as f:
            f.write(bytes(sheet[:2048]))
        self.custom.setdefault('tilesets', []).append(
            {'id': tid, 'raw2bpp': rel,
             'comment': f"copied from vanilla bank ${val(rec['gfx_bank']):02X} "
                        f"id ${val(rec['gfx_id']):02X}"})
        old_key = self.tileset_key(room)
        rec['tileset'] = tid
        rec.pop('gfx_bank', None)
        rec.pop('gfx_id', None)
        # S96: author metatiles made while the room borrowed the vanilla
        # sheet belong to the copy too (they were keyed 'BB:II')
        mts = self.metatiles(old_key)
        if mts:
            self._metatiles_mut(tid).extend(copy.deepcopy(mts))
        if self.released(old_key):
            self.set_released(tid, True)
        self.touch()
        return tid

    def new_blank_tileset(self, base='ts_blank', origin=None, sheet=None):
        """A project tileset with an all-colour-0 sheet (S96: rooms built
        from imported PNG art start empty; every slot but 77/78 is free).
        Returns the tileset id."""
        ids = {t.get('id') for t in self.custom.get('tilesets', [])}
        tid, n = base, 2
        while tid in ids:
            tid = f'{base}_{n}'
            n += 1
        assets = os.path.join(self.project_dir, 'assets')
        os.makedirs(assets, exist_ok=True)
        rel = os.path.join('assets', f'{tid}.2bpp')
        with open(os.path.join(self.project_dir, rel), 'wb') as f:
            f.write(bytes(sheet[:2048]) if sheet else bytes(2048))
        self.custom.setdefault('tilesets', []).append(
            {'id': tid, 'raw2bpp': rel,
             'comment': 'blank sheet (editor)' if not sheet else 'copy (editor)'})
        self.set_tileset_origin(tid, origin)
        self.touch()
        return tid

    def set_room_tileset(self, room_id, kind, value=None, threshold=None):
        """Point a room at another tileset (S96). kind:
          'vanilla' — value = vanilla mapID: that room's ROM sheet + its
                      collision threshold (record gfx_bank/gfx_id);
          'project' — value = a custom.tilesets id (threshold = the given one,
                      else that of another room on the sheet, else kept);
          'blank'   — a new all-empty project sheet (threshold given or $40).
        Layout grids keep their tile NUMBERS — they draw with the new sheet's
        graphics. Returns the tileset key now in effect."""
        room = self.room(room_id)
        rec = room.setdefault('record', {})
        if kind == 'vanilla':
            if self.vanilla is None:
                raise RuntimeError('no renderer bound — cannot read the vanilla record')
            vr = self.vanilla.vanilla_record(int(value))
            rec.pop('tileset', None)
            rec['gfx_id'], rec['gfx_bank'] = vr['gfx_id'], vr['gfx_bank']
            rec['collision_threshold'] = hexs(threshold) if threshold is not None \
                else vr['collision_threshold']
        elif kind == 'project':
            self.tileset_item(value)                       # KeyError if unknown
            if threshold is None:
                others = [r for r in self.rooms_using_tileset(value) if r is not room]
                if others:
                    threshold = val(others[0]['record']['collision_threshold'])
            rec.pop('gfx_id', None)
            rec.pop('gfx_bank', None)
            rec['tileset'] = value
            if threshold is not None:
                rec['collision_threshold'] = hexs(threshold)
        elif kind == 'own':
            # S98 r2: stop sharing — this room gets a private copy of the
            # sheet it draws with now (other rooms keep the original)
            if 'tileset' in rec:
                old = rec['tileset']
                keep = self._room_tiles(room)
                rec['tileset'] = self.duplicate_tileset(
                    old, f'ts_{room_id}',
                    metatile_filter=lambda mt: all((t & 0x7F) in keep for t in mt['tiles']))
            else:
                if self.vanilla is None:
                    raise RuntimeError('no renderer bound — cannot read the vanilla sheet')
                sheet = self.vanilla.rom_sheet(val(rec['gfx_bank']), val(rec['gfx_id']))
                self.localize_tileset(room, sheet, name=f'ts_{room_id}')
        elif kind == 'blank':
            tid = self.new_blank_tileset(f"ts_{room_id}")
            rec.pop('gfx_id', None)
            rec.pop('gfx_bank', None)
            rec['tileset'] = tid
            rec['collision_threshold'] = hexs(0x40 if threshold is None else threshold)
        else:
            raise ValueError(kind)
        self.touch()
        return self.tileset_key(room)

    def tileset_sharers(self, room):
        """Other custom rooms drawing with the same PROJECT tileset (a
        vanilla 'BB:II' sheet is read-only, so borrowing it shares nothing)."""
        rec = room.get('record') or {}
        if not rec.get('tileset'):
            return []
        return [r for r in self.rooms_using_tileset(rec['tileset']) if r is not room]

    def _room_tiles(self, room):
        out = set()
        for scr in (room.get('screens') or {}).values():
            refs = [scr.get('layout')] + [st.get('layout') for st in scr.get('states') or []]
            for ref in refs:
                if ref and 'id' in ref and self.has_layout(ref['id']):
                    for row in self.layout(ref['id'])['tiles']:
                        out.update(t & 0x7F for t in row)
        return out

    def duplicate_tileset(self, tid, base, metatile_filter=None):
        """A new project tileset with the same sheet bytes as `tid` (its
        origin, released flag and — filtered — metatiles carried over).
        Returns the new id."""
        item = self.tileset_item(tid)
        ids = {t.get('id') for t in self.custom.get('tilesets', [])}
        new, n = base, 2
        while new in ids:
            new = f'{base}_{n}'
            n += 1
        rel = os.path.join('assets', f'{new}.2bpp')
        os.makedirs(os.path.join(self.project_dir, 'assets'), exist_ok=True)
        with open(os.path.join(self.project_dir, rel), 'wb') as f:
            f.write(bytes(self.read_sheet(tid)))
        cp = {k: copy.deepcopy(v) for k, v in item.items() if k not in ('id', 'raw2bpp')}
        cp.update(id=new, raw2bpp=rel)
        cp['comment'] = (str(item.get('comment', '')) + f' — own copy of {tid}').strip(' —')
        self.custom.setdefault('tilesets', []).append(cp)
        o = (((self.custom.get('_editor') or {}).get('tileset_origin')) or {})
        if tid in o:
            self.set_tileset_origin(new, o[tid])
        mts = [copy.deepcopy(m) for m in self.metatiles(tid)
               if metatile_filter is None or metatile_filter(m)]
        if mts:
            self._metatiles_mut(new).extend(mts)
        if self.released(tid):
            self.set_released(new, True)
        self.touch()
        return new

    def sheet_path(self, tid):
        return os.path.join(self.project_dir, self.tileset_item(tid)['raw2bpp'])

    def read_sheet(self, tid):
        return bytearray(open(self.sheet_path(tid), 'rb').read())

    def write_sheet(self, tid, sheet):
        with open(self.sheet_path(tid), 'wb') as f:
            f.write(bytes(sheet))
        self.touch()

    def layouts_using_tileset(self, tid):
        """Layout ids referenced (tiles) by rooms on this tileset."""
        out = []
        for r in self.rooms_using_tileset(tid):
            for k, scr in (r.get('screens') or {}).items():
                for ref in [scr.get('layout')] + [st.get('layout')
                                                  for st in scr.get('states') or []]:
                    if ref and 'id' in ref and ref['id'] not in out:
                        out.append(ref['id'])
        return out

    # ---------------------------------------------- tileset usage (S96 P3.3c)
    # One room tileset = one 2 KB sheet = 128 slots (ids >= 128 are the
    # font/HUD half of VRAM — engine limit, per ROOM). A slot is:
    #   PLACED      on some screen/state of a room drawing with this sheet
    #   MINE        in an author metatile for this sheet
    #   VOCABULARY  used by the vanilla room the sheet came from (the picker
    #               keeps offering those metatiles, so their graphics are
    #               protected — unless the author RELEASES the vocabulary)
    #   ANIMATED    77/78 (Castle dispatch source rotates VRAM $94D0, KL S7)
    #   FREE        none of the above — imports and walkability twins use it
    TILESET_ORIGIN_RE = r'bank \$([0-9A-Fa-f]{2}) id \$([0-9A-Fa-f]{2})'

    def tileset_origin(self, tid):
        """(bank, id) of the vanilla sheet a project tileset was copied from
        (or the key itself for a vanilla 'BB:II' key); None when unknown
        (a blank or imported sheet)."""
        import re
        if ':' in str(tid) and len(str(tid)) == 5:
            b, g = str(tid).split(':')
            return int(b, 16), int(g, 16)
        ed = (self.custom.get('_editor') or {}).get('tileset_origin') or {}
        if tid in ed:
            o = ed[tid]
            return None if o is None else (val(o[0]), val(o[1]))
        try:
            item = self.tileset_item(tid)
        except KeyError:
            return None
        m = re.search(self.TILESET_ORIGIN_RE, str(item.get('comment', '')))
        return (int(m.group(1), 16), int(m.group(2), 16)) if m else None

    def set_tileset_origin(self, tid, origin):
        ed = self.custom.setdefault('_editor', {}).setdefault('tileset_origin', {})
        ed[tid] = None if origin is None else [hexs(origin[0]), hexs(origin[1])]
        self.touch()

    def room_sources_vocab(self, room):
        """Vanilla tile vocabulary that belongs to this room's sheet: the
        source room's tiles, when the room still draws with (a copy of) the
        source room's sheet. Empty without a renderer."""
        if self.vanilla is None or room.get('source_mapID') is None:
            return set()
        src = val(room['source_mapID'])
        if src >= 0x6B:
            return set()
        try:
            g = self.vanilla.vanilla_gfx(src)
        except Exception:
            return set()
        if self.tileset_origin(self.tileset_key(room)) != (g.gfx_bank, g.gfx_id):
            return set()
        return set(self.vanilla.vanilla_tiles_used(src))

    def released(self, tid):
        return tid in ((self.custom.get('_editor') or {}).get('released_vocab') or [])

    def set_released(self, tid, on):
        """'Release unused vocabulary' (P3.3c): the vanilla source room's
        tiles stop being protected, so imports/twins may take their slots
        (the picker then flags those metatiles 'graphic may change').
        Returns the previous state."""
        ed = self.custom.setdefault('_editor', {})
        lst = ed.setdefault('released_vocab', [])
        old = tid in lst
        if on and not old:
            lst.append(tid)
        elif not on and old:
            lst.remove(tid)
        if not lst:
            ed.pop('released_vocab')
        self.touch()
        return old

    def tile_usage(self, tid):
        """128 dicts: placed [(room_id, screen, state)], mine [names],
        vocab bool, animated bool, changed bool (graphic differs from the
        origin sheet), status (animated/placed/mine/vocab/free)."""
        out = [{'placed': [], 'mine': [], 'vocab': False, 'animated': i in (77, 78),
                'changed': False} for i in range(128)]
        for r in self.rooms_using_tileset(tid):
            for k, scr in (r.get('screens') or {}).items():
                refs = [(None, scr.get('layout'))] + [
                    (i, st.get('layout') or scr.get('layout'))
                    for i, st in enumerate(scr.get('states') or [])]
                for i, ref in refs:
                    if not ref or 'id' not in ref or not self.has_layout(ref['id']):
                        continue
                    if i is None and scr.get('states'):
                        continue
                    for row in self.layout(ref['id'])['tiles']:
                        for t in row:
                            u = out[t & 0x7F]['placed']
                            w = (r['id'], int(k), i or 0)
                            if w not in u:
                                u.append(w)
            for t in self.room_sources_vocab(r):
                out[t]['vocab'] = True
        for mt in self.metatiles(tid):
            for t in mt['tiles']:
                out[t & 0x7F]['mine'].append(mt.get('name', 'metatile'))
        for t in self._protected.get(tid, ()):
            out[t]['vocab'] = True
        origin = self.tileset_origin(tid)
        if origin is not None and self.vanilla is not None and ':' not in str(tid):
            try:
                ref = self.vanilla.rom_sheet(*origin)
                cur = self.read_sheet(tid)
                for i in range(128):
                    out[i]['changed'] = cur[i * 16:i * 16 + 16] != ref[i * 16:i * 16 + 16]
            except Exception:
                pass
        rel = self.released(tid)
        for i, u in enumerate(out):
            u['released'] = rel and u['vocab']
            u['status'] = ('animated' if u['animated'] else 'placed' if u['placed']
                           else 'mine' if u['mine']
                           else 'vocab' if (u['vocab'] and not rel) else 'free')
        return out

    def used_tiles(self, tid):
        """Indices a free-slot search must NOT overwrite: every tile placed
        in any layout on this tileset, every author metatile for it, the
        animated pair 77/78, and — unless released — the VOCABULARY (S95: the
        tiles of the rooms' vanilla source; 'this room's tiles' never shrinks,
        so the graphics behind them must never change either)."""
        return {i for i, u in enumerate(self.tile_usage(tid)) if u['status'] != 'free'}

    def free_counts(self, tid, threshold):
        """{'wall': n, 'walkable': n, 'total': n} free slots per side of the
        collision threshold (tile < thr = WALL)."""
        used = self.used_tiles(tid)
        w = sum(1 for i in range(min(threshold, 128)) if i not in used)
        k = sum(1 for i in range(min(threshold, 128), 128) if i not in used)
        return {'wall': w, 'walkable': k, 'total': w + k}

    def protect_tiles(self, tid, indices):
        """Register extra vocabulary indices (session-scoped). S96: the
        vocabulary is derived by `tile_usage` from the source room; this
        stays for callers without a renderer."""
        self._protected.setdefault(tid, set()).update(t & 0x7F for t in indices)

    def tile_used(self, tid, t):
        return t in self.used_tiles(tid)

    def import_metatile(self, room, mt, src_sheet, src_threshold, own_sheet=None,
                        name=None):
        """Bring a metatile from ANOTHER tileset into this room's tileset
        (S95, "tiles from other rooms displayed using the room's palette"):
        the room's tileset is copied into the project first when it still
        borrows vanilla (`own_sheet` = that vanilla sheet), then each of the
        4 subtiles is either matched to an identical graphic already in the
        sheet or copied into a free slot. The bottom-right subtile lands on
        the same side of the collision threshold it had in its source room
        (it decides walkability — S94); the other three take any free slot,
        preferring the same side. Returns the new metatile (also appended to
        the author's metatiles so it persists). Raises RuntimeError when the
        sheet has no free slot."""
        rec = room['record']
        tid = rec.get('tileset')
        if tid is None:
            if own_sheet is None:
                raise RuntimeError('room borrows a vanilla tileset — pass own_sheet')
            tid = self.localize_tileset(room, own_sheet)
        sheet = self.read_sheet(tid)
        thr = val(rec['collision_threshold'])
        used = self.used_tiles(tid)
        free = [i for i in range(128) if i not in used]
        out = []
        for pos, t in enumerate(mt['tiles']):
            t &= 0x7F
            gfx = bytes(src_sheet[t * 16:t * 16 + 16])
            want_wall = t < src_threshold
            strict = pos == 3                       # bottom-right decides
            cand = None
            for i in range(128):
                if i in (77, 78) or bytes(sheet[i * 16:i * 16 + 16]) != gfx:
                    continue
                if not strict or (i < thr) == want_wall:
                    cand = i
                    break
            if cand is None:
                side = [i for i in free if (i < thr) == want_wall]
                pool = side or ([] if strict else free)
                if not pool:
                    nw = sum(1 for i in free if i < thr)
                    raise RuntimeError(
                        f"tileset {tid!r} has no free "
                        f"{'wall' if want_wall else 'walkable'} slot — "
                        f"{nw} wall / {len(free) - nw} walkable free. Open the "
                        "Tileset tab: release unused vocabulary, delete unused "
                        "author metatiles, or pick a room with a roomier tileset")
                cand = pool[-1] if want_wall else pool[0]
                free.remove(cand)
                sheet[cand * 16:cand * 16 + 16] = gfx
            out.append(cand)
        self.write_sheet(tid, sheet)
        new = {'name': name or mt.get('name') or 'imported',
               'tiles': out, 'pal': mt.get('pal', 0), 'src': 'borrowed'}
        self.add_metatile(tid, new['name'], out, new['pal'], src='borrowed')
        self.touch()
        return new

    # ------------------------------------------------ PNG import (S96)
    def import_png_cells(self, room_id, plans, palettes, define_slots,
                         key=0, state_idx=0, own_sheet=None, stamp=None,
                         name_prefix='art', free_color1=False, strict_walk=False):
        """Place imported art (editor2/core/png_import CellPlans) into a room.

        * tileset — the room's sheet is copied into the project first if it
          still borrows a vanilla one (`own_sheet`); every distinct 8x8
          graphic reuses an identical slot when one exists, else takes a
          FREE slot (`used_tiles`: placed / mine / vocabulary / 77-78 are
          never touched). The bottom-right subtile of a cell marked WALL
          must sit below the collision threshold (it decides walkability —
          S94). Unmarked cells: with `strict_walk` their bottom-right
          subtile must sit at/above it (a graphic used both ways costs two
          slots); WITHOUT (the default since S96 round 3 — user: "let me do
          the walkability") it goes wherever a slot is free, walkable side
          first, and the author settles walkability afterwards (Walkability
          mode, or cheaper tricks). Other subtiles take any free slot.
        * palette — the palette in effect on (key, state_idx) gets the
          fitted colours in `define_slots` (colour 0 and 2; 1 and 3 are the
          engine-forced cream/black). A borrowed vanilla palette is copied
          into the project first.
        * metatiles — every distinct imported cell joins My metatiles.
        * stamp — {(cx, cy): plan index}: those cells of screen `key` /
          state `state_idx` are painted with the imported metatiles (the
          layout is made editable first when it is a vanilla reference).
        Raises RuntimeError (before anything is written) when the sheet has
        too few free slots. Returns a summary dict."""
        from editor2.core import png_import as PI
        room = self.room(room_id)
        rec = room['record']
        if 'tileset' not in rec:
            if own_sheet is None:
                raise RuntimeError('room borrows a vanilla tileset — pass own_sheet')
            self.localize_tileset(room, own_sheet)
        tid = rec['tileset']
        thr = val(rec['collision_threshold'])
        sheet = self.read_sheet(tid)
        used = self.used_tiles(tid)
        free = [i for i in range(128) if i not in used and i not in (77, 78)]

        def existing(g, side):
            for i in range(128):
                if i in (77, 78) or bytes(sheet[i * 16:i * 16 + 16]) != g:
                    continue
                if side == 'any' or (i < thr) == (side == 'wall'):
                    return i
            return None

        # plan the allocation first (no writes) so failure leaves no trace:
        # side-bound graphics (bottom-right subtiles) first, then the rest,
        # which reuse any identical graphic on either side
        want = []                                     # (gfx, side) in order
        for p in plans:
            for i, g in enumerate(p.gfx):
                side = self._import_side(p, i, strict_walk)
                if (g, side) not in want:
                    want.append((g, side))
        want.sort(key=lambda gs: gs[1] == 'any')
        alloc = {}
        free_w = [i for i in free if i < thr]
        free_k = [i for i in free if i >= thr]
        new_w = new_k = new_a = 0
        pending = []
        planned = {}                                  # gfx -> [(side, 'new'|index)]
        for g, side in want:
            hit = existing(g, side)
            if hit is not None:
                alloc[(g, side)] = hit
                continue
            prior = planned.get(g, [])
            if side in ('any', 'any_br') and prior:
                alloc[(g, side)] = ('same', prior[0])
                continue
            pending.append((g, side))
            planned.setdefault(g, []).append(side)
        need_w = sum(1 for _g, sd in pending if sd == 'wall')
        need_k = sum(1 for _g, sd in pending if sd == 'walk')
        need_a = sum(1 for _g, sd in pending if sd in ('any', 'any_br'))
        if need_w > len(free_w) or need_k > len(free_k) or \
                need_w + need_k + need_a > len(free_w) + len(free_k):
            raise RuntimeError(
                f'not enough free tileset slots in {tid!r}: the selection needs '
                f'{need_w} wall + {need_k} walkable + {need_a} either-side new '
                f'graphics; free: {len(free_w)} wall / {len(free_k)} walkable. '
                'Select fewer cells, release unused vocabulary (Rooms tab → '
                'Tileset tab), or give the room a blank tileset (inspector → '
                'tileset → Change… → New blank tileset).')
        for g, side in pending:
            if side == 'wall':
                i = free_w.pop()                       # walls from the top down
            elif side == 'walk':
                i = free_k.pop(0)
            elif side == 'any_br':                     # walkable side first
                i = free_k.pop(0) if free_k else free_w.pop()
            elif len(free_k) >= len(free_w):
                i = free_k.pop(0)
            else:
                i = free_w.pop()
            sheet[i * 16:i * 16 + 16] = g
            alloc[(g, side)] = i
        for k, v in list(alloc.items()):
            if isinstance(v, tuple):
                alloc[k] = alloc[(k[0], v[1])]
        self.write_sheet(tid, sheet)

        # palettes
        pid = self.effective_palette(room, key, state_idx)
        if define_slots:
            if not pid:
                cur = self.vanilla.room_palettes(room, key, state_idx) if self.vanilla else \
                    [[PI.CREAM, PI.CREAM, PI.BLACK, PI.BLACK]] * 8
                words = [[PI.to555(c) for c in row] for row in cur[:8]]
                pid = self.localize_palette(room, key, state_idx, words)
            rows = self.palette(pid)['colors_rgb555']
            if free_color1:
                # S96: colour 1 is the palette's own (FreeColor1Hook) — slots
                # not written here keep their current colour 1 (normally the
                # $6BFF a localized palette already holds: no visible change)
                self.palette(pid)['free_color1'] = True
            for sl in define_slots:
                pal = palettes[sl]
                c1 = hexs(PI.to555(pal[1]), 4) if free_color1 else '0x6BFF'
                rows[sl] = [hexs(PI.to555(pal[0]), 4), c1,
                            hexs(PI.to555(pal[2]), 4), '0x0000']

        # metatiles
        mts = []
        existing_keys = {metatile_key(m) for m in self.metatiles(tid)}
        for n, p in enumerate(plans):
            tiles = [alloc[(g, self._import_side(p, i, strict_walk))]
                     for i, g in enumerate(p.gfx)]
            mt = {'name': f'{name_prefix} {p.origin[0]},{p.origin[1]}',
                  'tiles': tiles, 'pal': pal_value(p.pals)}
            mts.append(mt)
            if metatile_key(mt) not in existing_keys:
                existing_keys.add(metatile_key(mt))
                self.add_metatile(tid, mt['name'], tiles, mt['pal'])

        # stamp onto the screen(s): keys (cx, cy) = screen `key`; keys
        # (screen, cx, cy) may name other screens — missing ones are created
        # (blank layout, the import's palette) and record dims follow
        stamped, created, repaletted = 0, [], []
        if stamp:
            by_screen = {}
            for k_, pi in stamp.items():
                sk, cx, cy = (key,) + tuple(k_) if len(k_) == 2 else tuple(k_)
                by_screen.setdefault(int(sk), {})[(cx, cy)] = pi
            for sk in sorted(by_screen):
                if not (0 <= sk < 16):
                    continue
                st_idx = state_idx if sk == key else 0
                if str(sk) not in room.get('screens', {}):
                    lid = self.unique_layout_id(f"{room['id']}_s{sk}")
                    fill = min(thr, 127)
                    self.add_layout(lid, tiles=self.blank_grid(fill),
                                    attr=self.blank_grid(0),
                                    comment=f"{room['id']} screen {sk} (PNG import)")
                    self.add_screen(room, sk, {'id': lid}, palette=pid)
                    self.screen(room, sk)['attr'] = {'id': lid}
                    created.append(sk)
                elif pid and self.effective_palette(room, sk, st_idx) != pid:
                    self.set_state_palette(room, sk, st_idx, pid)
                    repaletted.append(sk)
                ref = self.state_layout_ref(room, sk, st_idx)
                if ref is None:
                    raise RuntimeError(f'screen {sk} has no layout')
                if 'id' not in ref:
                    grid = [list(r) for r in self.vanilla.layout_grid(ref)[0]]
                    self.localize_layout(room, sk, st_idx, grid)
                    ref = self.state_layout_ref(room, sk, st_idx)
                tiles = self.layout(ref['id'])['tiles']
                attr = self.layout(self.writable_attr_id(room, sk, st_idx))['attr']
                for (cx, cy), pi in by_screen[sk].items():
                    mt = mts[pi]
                    pals = metatile_pals(mt)
                    for j, (dr, dc) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
                        tiles[cy * 2 + dr][cx * 2 + dc] = mt['tiles'][j]
                        attr[cy * 2 + dr][cx * 2 + dc] = pals[j]
                    stamped += 1
        self.touch()
        return {'tileset': tid, 'new_slots': len(pending), 'palette': pid,
                'metatiles': mts, 'stamped': stamped, 'screens_created': created,
                'screens_repaletted': repaletted}

    @staticmethod
    def _import_side(plan, i, strict_walk):
        """Threshold side a subtile of an imported cell must land on."""
        if i != 3:
            return 'any'
        if plan.wall:
            return 'wall'
        return 'walk' if strict_walk else 'any_br'

    def writable_attr_id(self, room, key, state_idx):
        """The custom.layouts item whose 'attr' grid is IN EFFECT for (key,
        state) (same precedence as render_project.attr_grid), creating one
        on the state's own layout item from the grid currently shown when
        the effective attr is not a project item. Returns its layout id."""
        scr = self.screen(room, key)
        sts = scr.get('states') or []
        cands = []                       # (ref, is_attr_ref)
        if state_idx < len(sts):
            st = sts[state_idx]
            cands += [(st.get('attr'), True), (st.get('layout'), False)]
        cands += [(scr.get('attr'), True), (scr.get('layout'), False),
                  ((room.get('render') or {}).get('attr'), True)]
        for c, is_attr in cands:
            if not c:
                continue
            if 'id' in c and self.has_layout(c['id']) and 'attr' in self.layout(c['id']):
                return c['id']
            if is_attr:
                break            # an attr reference that is not a project grid
        # none writable: put a copy of the shown grid on the state's layout item
        ref = self.state_layout_ref(room, key, state_idx)
        grid = None
        if self.vanilla is not None:
            grid, _n = self.vanilla.attr_grid(room, key, state_idx)
        grid = [list(r) for r in (grid or self.blank_grid(0))]
        item = self.layout(ref['id'])
        item['attr'] = grid
        if sts:
            sts[state_idx]['attr'] = {'id': ref['id']}
        else:
            scr['attr'] = {'id': ref['id']}
        self.touch()
        return ref['id']

    def _remap_tile(self, tid, old, new):
        """Every placed use of subtile `old` on this tileset (layouts and
        author metatiles) now points at `new` (same graphic, moved slot)."""
        for lid in self.layouts_using_tileset(tid):
            for row in self.layout(lid)['tiles']:
                for c, v in enumerate(row):
                    if (v & 0x7F) == old:
                        row[c] = (v & 0x80) | new
        for mt in self.metatiles(tid):
            mt['tiles'] = [((x & 0x80) | new) if (x & 0x7F) == old else x for x in mt['tiles']]

    def ensure_twin(self, tid, t, want_wall, shift_ok=False):
        """Return an index whose graphic equals subtile `t` on the wanted
        side of the collision threshold (tile < thr = WALL, KEY_LESSONS S6),
        creating one if needed. Never touches animated indices 77/78
        (KEY_LESSONS S7). Falls back to moving the threshold by one (the
        first walkable tile is relocated to a free slot and every layout on
        this tileset is remapped) when no free slot exists on the wall side.
        Raises RuntimeError when the sheet has no free slot at all."""
        sheet = self.read_sheet(tid)
        rooms = self.rooms_using_tileset(tid)
        thr = val(rooms[0]['record']['collision_threshold']) if rooms else 0
        gfx = bytes(sheet[t * 16:t * 16 + 16])
        side = range(0, thr) if want_wall else range(thr, 128)
        for i in side:
            if i in (77, 78):
                continue
            if bytes(sheet[i * 16:i * 16 + 16]) == gfx:
                return i, thr
        used = self.used_tiles(tid)
        free = [i for i in range(128) if i not in (77, 78) and i not in used]
        on_side = [i for i in free if (i < thr) == want_wall]
        if on_side:
            i = on_side[-1] if want_wall else on_side[0]
            sheet[i * 16:i * 16 + 16] = gfx
            self.write_sheet(tid, sheet)
            return i, thr
        if not want_wall:
            # S98 r2 (user option): walkable side full -> move the split DOWN
            # one slot: the last wall slot (thr-1) becomes the first walkable
            # one; its graphic (if in use) moves to a free wall slot below
            s_idx = thr - 1
            below = [i for i in free if i < s_idx]
            if s_idx < 1 or s_idx in (77, 78) or (s_idx in used and not below):
                raise RuntimeError(
                    f'tileset {tid} is full on both sides (walkable side: no free slot; '
                    'wall side: none to move a tile into) — release unused vocabulary '
                    '(Tileset tab), give this room its own tileset copy, or reuse an '
                    'existing walkable metatile')
            if not shift_ok:
                raise ThresholdShiftNeeded(
                    f'The walkable side of {tid} is full, but the wall side has '
                    f'{len(below) + (0 if s_idx in used else 1)} free slot(s). Move the '
                    f'wall/walkable split down one slot (${thr:02X} -> ${s_idx:02X})? '
                    f'Slot ${s_idx:02X} becomes walkable'
                    + (f'; the wall tile there moves to free slot ${below[-1]:02X} (every '
                       'room on this tileset is updated, nothing changes on screen)'
                       if s_idx in used else ' (it is free)') + '.')
            if s_idx in used:
                f = below[-1]
                sheet[f * 16:f * 16 + 16] = bytes(sheet[s_idx * 16:s_idx * 16 + 16])
                self._remap_tile(tid, s_idx, f)
            sheet[s_idx * 16:s_idx * 16 + 16] = gfx
            self.write_sheet(tid, sheet)
            for r in rooms:
                r['record']['collision_threshold'] = hexs(s_idx)
            self.touch()
            return s_idx, s_idx
        # wall side full: relocate the first walkable tile (index thr) to a
        # free slot above, put the twin at thr, threshold += 1
        above = [i for i in free if i > thr]
        if not above or thr in (77, 78):
            raise RuntimeError('tileset has no free slot for a wall twin')
        f = above[0]
        moved = bytes(sheet[thr * 16:thr * 16 + 16])
        sheet[f * 16:f * 16 + 16] = moved
        sheet[thr * 16:thr * 16 + 16] = gfx
        self.write_sheet(tid, sheet)
        self._remap_tile(tid, thr, f)
        for r in rooms:
            r['record']['collision_threshold'] = hexs(thr + 1)
        self.touch()
        return thr, thr + 1

    def set_cell_walkable(self, lid, tid, cx, cy, walkable, shift_ok=False):
        """Flip one placed cell: only its BOTTOM-RIGHT subtile decides
        (PyBoy-measured S94, 16/16 trials from all four approach
        directions), so swap that subtile for its cross-threshold twin."""
        grid = self.layout(lid)['tiles']
        r, c = cy * 2 + 1, cx * 2 + 1
        t = grid[r][c]
        twin, _thr = self.ensure_twin(tid, t, want_wall=not walkable, shift_ok=shift_ok)
        grid[r][c] = twin
        self.touch()
        return t, twin


    # ------------------------------------------- entrance redirects (S94b)
    def redirects(self):
        """custom.entrance_redirects (non-mutating read)."""
        return list(self.custom.get('entrance_redirects') or [])

    def redirects_to(self, room_id):
        """Redirects whose destination is this custom room."""
        mid = val(self.room(room_id)['mapID'])
        out = []
        for i, r in enumerate(self.redirects()):
            d = str(r.get('dest', ''))
            if r.get('twin_of'):
                continue          # S98: second cell of a door's vanilla double door
            if d.startswith('room:') and val(d[5:]) == mid:
                out.append((i, r))
        return out

    def add_redirect(self, source_mid, screen, x, y, room_id,
                     dest_screen=0, spawn_x=0, spawn_y=0, comment=None):
        """Route a VANILLA door (source_mid, screen, x, y) into custom room
        `room_id` at (dest_screen, spawn_x, spawn_y). Replaces an existing
        redirect of the same door. screen_byte is the destination screen
        index (bit7 = spawn y+8 is never needed: spawn_y is absolute within
        the screen). Returns the index."""
        mid = val(self.room(room_id)['mapID'])
        entry = {'mapID': hexs(source_mid), 'screen': int(screen),
                 'x': int(x), 'y': int(y),
                 'dest': f"room:${mid:02X}",
                 'screen_byte': hexs(int(dest_screen) & 0x0F),
                 'spawn_x': int(spawn_x), 'spawn_y': int(spawn_y)}
        if comment:
            entry['comment'] = comment
        lst = self.custom.setdefault('entrance_redirects', [])
        for i, r in enumerate(lst):
            if (val(r['mapID']), val(r['screen']), val(r['x']), val(r['y'])) \
                    == (source_mid, int(screen), int(x), int(y)):
                lst[i] = entry
                self.touch()
                return i
        lst.append(entry)
        self.touch()
        return len(lst) - 1

    def remove_redirect(self, index):
        lst = self.custom.get('entrance_redirects') or []
        gone = lst.pop(index)
        if not lst:
            self.custom.pop('entrance_redirects', None)
        self.touch()
        return gone

    # ------------------------------------------------- palettes (S94b UI)
    def localize_palette(self, room, key, state_idx, words, pid_base=None):
        """Give a room that borrows a vanilla palette its OWN project palette
        (custom.palettes item) so colours become editable. `words` = the 8x4
        RGB555 words currently displayed (renderer). Assigned to the state
        when the screen has states[], else to render.palette. Returns pid."""
        pid = pid_base or f"pal_{room['id']}"
        cand, n = pid, 2
        while any(p.get('id') == cand for p in self.palettes):
            cand = f'{pid}_{n}'
            n += 1
        pid = cand
        rows = [[hexs(int(c), 4) for c in row] for row in words[:8]]
        while len(rows) < 8:
            rows.append(['0x0000', '0x6BFF', '0x7FFF', '0x0000'])
        self.palettes.append({'id': pid, 'label': f'CustomPaletteColors_{pid}',
                              'placement': 'b', 'colors_rgb555': rows,
                              'comment': [f"copied from vanilla ${val(room.get('source_mapID', 0)):02X} "
                                          f"for editing (screen {key} state {state_idx})"]})
        scr = self.screen(room, key)
        if scr.get('states'):
            scr['states'][state_idx]['palette'] = pid
        else:
            room.setdefault('render', {})['palette'] = pid
        self.touch()
        return pid

    # --------------------------------------------------------- exits (S95)
    def add_exit(self, room, key, state_idx, x, y, dest, dest_screen,
                 spawn_x, spawn_y, comment=None):
        """Append an exit row to the screen's state (or the screen when it
        has no states[]). Replaces an existing row at the same (x, y)."""
        scr = self.screen(room, key)
        target = scr['states'][state_idx] if scr.get('states') else scr
        rows = target.setdefault('exits', [])
        row = {'x': int(x), 'y': int(y), 'dest': dest, 'gate_flag': 0,
               'screen_byte': hexs(int(dest_screen) & 0x0F),
               'spawn_x': int(spawn_x), 'spawn_y': int(spawn_y)}
        if comment:
            row['comment'] = comment
        for i, e in enumerate(rows):
            if val(e.get('x', -1)) == int(x) and val(e.get('y', -1)) == int(y):
                rows[i] = row
                self.touch()
                return i
        rows.append(row)
        self.touch()
        return len(rows) - 1

    def remove_exit(self, room, key, state_idx, index):
        scr = self.screen(room, key)
        target = scr['states'][state_idx] if scr.get('states') else scr
        gone = target['exits'].pop(index)
        self.touch()
        return gone


    # ================================================================ NPCs
    # S97 (ROADMAP P3.5). An NPC entry is `{kind: 'npc', x, y, sprite,
    # facing, behaviour, hidden, script}` (PROJECT_COMPILER §2.2 + S97): the
    # type byte = facing (bits 4-5) | hidden (bit 6) | behaviour (0-3,
    # ROOM_DATA_FORMAT "NPC behaviour types"). Cloned rooms carry `raw`
    # 5-byte entries; editing one converts it to the typed form with the
    # SAME bytes (script index -> the room's script id when the table has
    # it, else the index is kept as an int).
    NPC_FIELDS = ('x', 'y', 'sprite', 'facing', 'behaviour', 'hidden', 'script')

    def _state_target(self, room, key, state_idx):
        scr = self.screen(room, key)
        return scr['states'][state_idx] if scr.get('states') else scr

    def npc_entries(self, room, key, state_idx):
        return self._state_target(room, key, state_idx).setdefault('npcs', [])

    def npc_view(self, room, entry):
        """Normalized view of an npcs[] entry: dict with kind ('npc',
        'spawn', 'walkon', 'special'), x, y and — for NPCs — sprite, facing,
        behaviour (0-15), hidden, script (id, None, or a raw int index),
        raw (bool)."""
        from editor2.core import formats as F
        k = entry.get('kind')
        if k == 'spawn':
            # S98: legacy name of an $8F examine spot (any facing)
            return {'kind': 'spawn', 'x': int(entry['x']), 'y': int(entry['y']),
                    'facing': 'any', 'script': val(entry.get('script', 0)) or 0,
                    'raw': False}
        if k in ('examine', 'step'):
            v = {'kind': k, 'x': int(entry['x']), 'y': int(entry['y']),
                 'script': entry.get('script'), 'raw': False}
            if k == 'examine':
                v['facing'] = entry.get('facing', 'any')
            return v
        if k == 'npc':
            fac = entry.get('facing', 'down')
            t = F.FACING[fac] if isinstance(fac, str) else val(fac)
            return {'kind': 'npc', 'x': int(entry['x']), 'y': int(entry['y']),
                    'sprite': val(entry.get('sprite', 0)),
                    'facing': F.FACING_NAMES[(t >> 4) & 3],
                    'behaviour': F.behaviour_value(entry.get('behaviour', 0)),
                    'hidden': bool(entry.get('hidden')) or bool(t & 0x40),
                    'script': entry.get('script'), 'raw': False}
        if k == 'raw':
            b = [val(x) for x in entry['bytes']]
            table = {int(i): sid for i, sid in (room.get('scripts') or {}).items()}
            if b[0] >= 0x80:
                # S98 (PyBoy-measured): $80-$8F = examine spot (low nibble =
                # required facing, F = any), $90-$9F = step-on trigger
                script = table.get(b[4], b[4])
                if b[0] & 0xF0 == 0x80:
                    nib = b[0] & 0x0F
                    fac = F.EXAMINE_FACING_NAMES.get(nib, nib)
                    return {'kind': 'examine', 'x': b[2], 'y': b[3], 'facing': fac,
                            'script': script, 'raw': True, 'bytes': b}
                if b[0] & 0xF0 == 0x90:
                    return {'kind': 'step', 'x': b[2], 'y': b[3], 'script': script,
                            'raw': True, 'bytes': b}
                return {'kind': 'special', 'x': b[2], 'y': b[3], 'bytes': b}
            script = None if b[4] == 0xFF else table.get(b[4], b[4])
            return {'kind': 'npc', 'x': b[2], 'y': b[3], 'sprite': b[1],
                    'facing': F.FACING_NAMES[(b[0] >> 4) & 3],
                    'behaviour': b[0] & 0x0F, 'hidden': bool(b[0] & 0x40),
                    'script': script, 'raw': True}
        return {'kind': 'special', 'x': int(entry.get('x', 0)), 'y': int(entry.get('y', 0))}

    @staticmethod
    def _npc_entry(v):
        from editor2.core import formats as F
        e = {'kind': 'npc', 'x': int(v['x']), 'y': int(v['y']),
             'sprite': hexs(int(v['sprite'])), 'facing': v.get('facing', 'down')}
        beh = int(v.get('behaviour', 0))
        if beh:
            e['behaviour'] = F.BEHAVIOUR_NAMES.get(beh, beh)
        if v.get('hidden'):
            e['hidden'] = True
        sc = v.get('script')
        e['script'] = 'none' if sc in (None, 'none') else sc
        if v.get('comment'):
            e['comment'] = v['comment']
        return e

    def add_npc(self, room, key, state_idx, x, y, sprite, facing='down',
                behaviour=0, hidden=False, script=None):
        """Append an NPC to the screen/state; refuses past the 8-NPC hard
        cap (S91). Returns its index in npcs[]."""
        n, cap = self.state_capacity(room, key, state_idx)
        if n >= cap:
            raise ValueError(f'this screen/state already has {n} NPCs — the engine '
                             f'hard cap is {cap} (S91: a 9th silently corrupts script '
                             'state)')
        lst = self.npc_entries(room, key, state_idx)
        lst.append(self._npc_entry({'x': x, 'y': y, 'sprite': sprite, 'facing': facing,
                                    'behaviour': behaviour, 'hidden': hidden,
                                    'script': script}))
        self.touch()
        return len(lst) - 1

    def update_npc(self, room, key, state_idx, index, **fields):
        """Change NPC fields (any of NPC_FIELDS). A raw entry becomes the
        typed form carrying the same bytes plus the change."""
        lst = self.npc_entries(room, key, state_idx)
        old = lst[index]
        v = self.npc_view(room, old)
        if v['kind'] != 'npc':
            if set(fields) - {'x', 'y'}:
                raise ValueError('only NPC entries have sprite/facing/behaviour/script')
            new = copy.deepcopy(old)
            if old.get('kind') == 'raw':
                b = [val(x) for x in old['bytes']]
                b[2], b[3] = int(fields.get('x', b[2])), int(fields.get('y', b[3]))
                new['bytes'] = [hexs(x) for x in b]
            else:
                new.update({k: int(fields[k]) for k in ('x', 'y') if k in fields})
            lst[index] = new
            self.touch()
            return old
        unknown = set(fields) - set(self.NPC_FIELDS)
        if unknown:
            raise ValueError(f'unknown NPC fields {sorted(unknown)}')
        v.update(fields)
        if old.get('comment') and not old.get('kind') == 'raw':
            v['comment'] = old['comment']
        lst[index] = self._npc_entry(v)
        self.touch()
        return old

    def remove_npc(self, room, key, state_idx, index):
        gone = self.npc_entries(room, key, state_idx).pop(index)
        self.touch()
        return gone

    def npc_signature(self, room, entry):
        """What 'the same NPC' means across a screen's states: same sprite,
        home cell and script (states are copies; the author then edits)."""
        v = self.npc_view(room, entry)
        return (v['kind'], v.get('sprite'), v['x'], v['y'], str(v.get('script')))

    def npc_presence(self, room, key, state_idx, index):
        """[bool per state]: does each state of the screen carry this NPC?"""
        sig = self.npc_signature(room, self.npc_entries(room, key, state_idx)[index])
        out = []
        for n in range(len(self.states(room, key))):
            out.append(any(self.npc_signature(room, e) == sig
                           for e in self.npc_entries(room, key, n)))
        return out

    def set_npc_presence(self, room, key, state_idx, index, target_state, present):
        """Add (a copy) / remove this NPC in another state of the screen."""
        src = self.npc_entries(room, key, state_idx)[index]
        sig = self.npc_signature(room, src)
        lst = self.npc_entries(room, key, target_state)
        hit = [i for i, e in enumerate(lst) if self.npc_signature(room, e) == sig]
        if present and not hit:
            n, cap = self.state_capacity(room, key, target_state)
            if n >= cap:
                raise ValueError(f'state {target_state} already has {n} NPCs (hard cap {cap})')
            lst.append(copy.deepcopy(src))
        elif not present:
            for i in reversed(hit):
                lst.pop(i)
        self.touch()

    # --------------------------------------------------- scripts for NPCs
    def room_script_ids(self, room):
        """[(index, script id)] of the room's script table, index order."""
        return sorted(((int(i), sid) for i, sid in (room.get('scripts') or {}).items()),
                      key=lambda t: t[0])

    def script(self, sid):
        for s in self.custom.get('scripts', []):
            if s.get('id') == sid:
                return s
        raise KeyError(sid)

    def dialogue(self, did):
        for d in self.custom.get('dialogue', []):
            if d.get('id') == did:
                return d
        raise KeyError(did)

    def _unique_id(self, base, taken):
        base = self._slug(base) or 'x'
        n, cand = 1, base
        while cand in taken:
            n += 1
            cand = f'{base}_{n}'
        return cand

    def talk_boxes(self, sid):
        """The text boxes (lists of 1-2 lines) of a SIMPLE talk script
        ([text d]... [end]), or None when the script does more than show
        text (then it is edited as a script, P3.6/P3.8). Legacy entries are
        converted: auto `text` flows into boxes, `lines` pair up (S97 r2)."""
        from editor2.core import textenc as T
        try:
            ops = self.script(sid).get('ops', [])
        except KeyError:
            return None
        boxes = []
        for op in ops:
            if isinstance(op, list) and op and op[0] == 'text' and len(op) == 2:
                try:
                    d = self.dialogue(op[1])
                except KeyError:
                    return None
                if d.get('choice') or 'raw' in d:
                    return None
                try:
                    b = T.entry_boxes(d)
                except T.TextError:
                    b = None
                if b is None and 'lines' in d:
                    ls = list(d['lines'])
                    b = [ls[k:k + T.BOX_LINES] for k in range(0, len(ls), T.BOX_LINES)]
                elif b is None and 'text' in d:
                    b = [[d['text']]]
                if b is None:
                    return None
                boxes += b
            elif op == ['end']:
                break
            else:
                return None
        return boxes if boxes else None

    def _talk_entry(self, sid, boxes):
        dlg = self.custom.setdefault('dialogue', [])
        did = self._unique_id(f'{sid}_text', {d.get('id') for d in dlg})
        dlg.append({'id': did, 'boxes': [list(b) for b in boxes],
                    'comment': f'{sid} ({len(boxes)} box{"es" if len(boxes) != 1 else ""})'})
        return did

    def new_talk_script(self, room, boxes, name='talk'):
        """An NPC script that shows `boxes` (one dialogue entry; each box
        waits for A, S97 r2) and ends. Registers it in the room's script
        table at the next free index >= 1 (index 0 = the room-entry script,
        created as a no-op when missing — KEY_LESSONS S2). Returns the id."""
        scripts = self.custom.setdefault('scripts', [])
        sids = {s.get('id') for s in scripts}
        sid = self._unique_id(f"{room['id']}_{name}", sids)
        scripts.append({'id': sid, 'ops': [['text', self._talk_entry(sid, boxes)], ['end']]})
        table = room.setdefault('scripts', {})
        if '0' not in table:
            eid = self._unique_id(f"{room['id']}_entry", sids | {sid})
            scripts.append({'id': eid, 'ops': [['end']]})
            table['0'] = eid
        idx = 1
        while str(idx) in table:
            idx += 1
        table[str(idx)] = sid
        self.touch()
        return sid

    def set_talk_boxes(self, sid, boxes):
        """Rewrite a simple talk script's text (keeps the script id, so every
        NPC bound to it follows). Entries only this script shows are dropped."""
        if self.talk_boxes(sid) is None:
            raise ValueError(f'script {sid!r} is not a plain talk script')
        sc = self.script(sid)
        dlg = self.custom.setdefault('dialogue', [])
        old = [op[1] for op in sc['ops'] if isinstance(op, list) and op and op[0] == 'text']
        users = self._dialogue_users()          # S98: talk-form aware
        for did in old:
            if users.get(did) == 1:
                dlg[:] = [d for d in dlg if d.get('id') != did]
        sc['ops'] = [['text', self._talk_entry(sid, boxes)], ['end']]
        self.touch()

    # ====================================================== flags (S97 UI)
    def flags(self):
        return self.custom.get('flags', [])

    def add_flag(self, name):
        """A named project flag, auto-allocated by the compiler from the
        EVENT_FLAGS safe pool (PROJECT_COMPILER §2.7)."""
        name = self._slug(name)
        if not name:
            raise ValueError('flag name is empty')
        if any(f.get('name') == name for f in self.flags()):
            raise ValueError(f'flag {name!r} already exists')
        self.custom.setdefault('flags', []).append({'name': name, 'index': 'auto'})
        self.touch()
        return name

    def flag_pool(self):
        """(used, capacity) of the named-flag safe pool."""
        from editor2.core.project import FLAG_SAFE_RANGES
        cap = sum(hi - lo + 1 for lo, hi in FLAG_SAFE_RANGES)
        return len(self.flags()), cap

    # ================================================= state rules (P3.5a)
    def state_rules(self, room):
        return room.get('state_rules') or []

    def set_state_rules(self, room, rules):
        if rules:
            room['state_rules'] = rules
        else:
            room.pop('state_rules', None)
        self.touch()

    def rules_for_state(self, room, key, state_idx):
        """[(rule index, rule)] of rules that select this state on this
        screen (the canvas state bar's 'shown when')."""
        out = []
        for i, ru in enumerate(self.state_rules(room)):
            if int(ru.get('state', -1)) != int(state_idx):
                continue
            scr = ru.get('screens')
            if scr is not None and int(key) not in [int(x) for x in scr]:
                continue
            out.append((i, ru))
        return out

    @staticmethod
    def describe_rule(ru):
        terms = ru.get('when') or []
        if not terms:
            return 'always'
        return ' AND '.join(f"{t.get('flag')} {'is clear' if t.get('is') == 'clear' else 'is set'}"
                            for t in terms)
