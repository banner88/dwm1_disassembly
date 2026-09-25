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
import os

from editor2.core import layouts as L

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


class Document:
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

    def new_room(self, name, source_mid, renderer):
        """Blank single-screen room using a VANILLA room's tileset, palette
        and collision threshold (source_mid). Floor = first walkable tile."""
        rid = self.unique_room_id(self._slug(name))
        rec = renderer.vanilla_record(source_mid)
        rec['width_px'], rec['height_px'] = 160, 128
        thr = val(rec['collision_threshold'])
        lid = self.unique_layout_id(f'{rid}_s0')
        self.add_layout(lid, tiles=self.blank_grid(min(thr, 127)),
                        attr=self.blank_grid(0))
        room = {'id': rid, 'name': name, 'mapID': hexs(self.next_free_mapid()),
                'source_mapID': hexs(source_mid), 'record': rec,
                'render': {'attr': {'id': lid}},
                'screens': {'0': {'layout': {'id': lid}, 'step_counter': 'auto',
                                  'npcs': [{'kind': 'spawn', 'x': 5, 'y': 4}],
                                  'exits': []}}}
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

    def add_metatile(self, tileset_key, name, tiles, pal):
        lst = self._metatiles_mut(tileset_key)
        lst.append({'name': name, 'tiles': [int(t) for t in tiles],
                    'pal': int(pal)})
        self.touch()
        return len(lst) - 1

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
        return [r for r in self.rooms
                if (r.get('record') or {}).get('tileset') == tid]

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
        rec['tileset'] = tid
        rec.pop('gfx_bank', None)
        rec.pop('gfx_id', None)
        self.touch()
        return tid

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

    def used_tiles(self, tid):
        """Indices a free-slot search must NOT overwrite: every tile placed
        in any layout on this tileset, every author metatile for it, the
        animated pair 77/78, and the PROTECTED VOCABULARY (S95: tiles of the
        rooms' vanilla source screens — 'this room's tiles' never shrinks, so
        the graphics behind them must never change either)."""
        used = {77, 78}
        for lid in self.layouts_using_tileset(tid):
            for row in self.layout(lid)['tiles']:
                used.update(t & 0x7F for t in row)
        for mt in self.metatiles(tid):
            used.update(t & 0x7F for t in mt['tiles'])
        used.update(self._protected.get(tid, ()))
        return used

    def protect_tiles(self, tid, indices):
        """Register vocabulary indices for `used_tiles` (session-scoped;
        the GUI registers the vanilla source room's tiles when it harvests)."""
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
                    raise RuntimeError(
                        f"tileset {tid!r} has no free "
                        f"{'wall' if want_wall else 'walkable'} slot "
                        f"({len(free)} free in total) — delete unused author "
                        "metatiles or pick a room with a roomier tileset")
                cand = pool[-1] if want_wall else pool[0]
                free.remove(cand)
                sheet[cand * 16:cand * 16 + 16] = gfx
            out.append(cand)
        self.write_sheet(tid, sheet)
        new = {'name': name or mt.get('name') or 'imported',
               'tiles': out, 'pal': mt.get('pal', 0)}
        self.add_metatile(tid, new['name'], out, new['pal'])
        self.touch()
        return new

    def ensure_twin(self, tid, t, want_wall):
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
        free = [i for i in range(128) if i not in (77, 78)
                and not self.tile_used(tid, i)]
        on_side = [i for i in free if (i < thr) == want_wall]
        if on_side:
            i = on_side[-1] if want_wall else on_side[0]
            sheet[i * 16:i * 16 + 16] = gfx
            self.write_sheet(tid, sheet)
            return i, thr
        if not want_wall:
            raise RuntimeError('tileset has no free walkable slot for a twin')
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
        for lid in self.layouts_using_tileset(tid):
            grid = self.layout(lid)['tiles']
            for row in grid:
                for c, v in enumerate(row):
                    if v == thr:
                        row[c] = f
        for r in rooms:
            r['record']['collision_threshold'] = hexs(thr + 1)
        self.touch()
        return thr, thr + 1

    def set_cell_walkable(self, lid, tid, cx, cy, walkable):
        """Flip one placed cell: only its BOTTOM-RIGHT subtile decides
        (PyBoy-measured S94, 16/16 trials from all four approach
        directions), so swap that subtile for its cross-threshold twin."""
        grid = self.layout(lid)['tiles']
        r, c = cy * 2 + 1, cx * 2 + 1
        t = grid[r][c]
        twin, _thr = self.ensure_twin(tid, t, want_wall=not walkable)
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

