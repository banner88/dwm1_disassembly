"""project.py — load + resolve project.json (schema owner: PROJECT_COMPILER.md).

project.json is the source of truth; ASM is a build artifact (EDITOR_DESIGN
"Hard rules"). Layers per EDITOR_DESIGN §3: v1 implements Layer B (custom)
+ Layer D (build). Layers A (world) and C (gamedata) are declared-but-
unimplemented: any non-stub content in them is a HARD ERROR (design
commitment S53: reserved sections error, never silently ignore).
"""

import json
import os

from . import formats as F

# EVENT_FLAGS.md "Free Flag Slots" — safe+persistent ranges the allocator may
# use, and the collision zones it must skip (script-written named variables).
FLAG_SAFE_RANGES = [(0x0158, 0x017F), (0x0188, 0x018F), (0x01E0, 0x023F),
                    (0x0248, 0x0257), (0x0260, 0x026F)]
STEP_COUNTER_BASE = 0xDE74          # S55 relocation: vetted block past the audio ceiling ($DE2B)
WRAM_REGION_SIZE_DEFAULT = 7        # keeps wRoomRecScratch pinned at $DE7B


class ProjectError(ValueError):
    pass


class Project:
    def __init__(self, data, root):
        self.data = data
        self.root = root
        self.warnings = []
        self._check_layers()
        self.custom = data.get('custom', {})
        self.build = data.get('build', {})
        self.rooms = self._dense_rooms()
        self.palettes = self.custom.get('palettes', [])
        self._pal_by_id = {p['id']: p for p in self.palettes}
        self._dialogue = self.custom.get('dialogue', [])
        self._text_by_id = {}
        self._assign_text_ids()
        self._scripts = {s['id']: s for s in self.custom.get('scripts', [])}
        self._flags = {}
        self._allocate_flags()
        self.wram_region_size = (self.custom.get('wram', {})
                                 .get('region_size', WRAM_REGION_SIZE_DEFAULT))
        self._step_alloc = None

    # ------------------------------------------------------------------ load
    @classmethod
    def load(cls, path):
        path = os.path.abspath(path)
        if os.path.isdir(path):
            path = os.path.join(path, 'project.json')
        with open(path) as f:
            data = json.load(f)
        return cls(data, os.path.dirname(path))

    def _check_layers(self):
        for layer in ('world', 'gamedata'):
            sec = self.data.get(layer)
            if sec and any(k for k in sec if not k.startswith('_')):
                raise ProjectError(
                    f"layer '{layer}' is NOT_IMPLEMENTED in compiler v1 — "
                    "content found; refusing to silently ignore it "
                    "(PROJECT_COMPILER.md §layers)")
        music = (self.data.get('custom') or {}).get('music')
        if music:
            raise ProjectError(
                "custom.music is NOT_IMPLEMENTED (ROADMAP Arc 3 M1-M3 must "
                "land first) — refusing to silently ignore it")
        skills = (self.data.get('custom') or {}).get('skills')
        if skills:
            raise ProjectError(
                "custom.skills is NOT_IMPLEMENTED in v1 (data-half emitter "
                "is a scoped follow-up; BATTLE_SKILL_SYSTEM §13) — refusing "
                "to silently ignore it")

    # ----------------------------------------------------------------- rooms
    def _dense_rooms(self):
        rooms = list(self.custom.get('rooms', []))
        if not rooms:
            raise ProjectError("custom.rooms is empty")
        by_mid = {}
        for r in rooms:
            mid = F.val(r['mapID'])
            if mid in by_mid:
                raise ProjectError(f"duplicate mapID {F.hexb(mid)}")
            by_mid[mid] = r
        lo, hi = min(by_mid), max(by_mid)
        if lo != 0x6B:
            raise ProjectError("first custom mapID must be $6B "
                               "(tables are indexed mapID-$6B)")
        dense = []
        for mid in range(lo, hi + 1):
            r = by_mid.get(mid)
            if r is None:
                r = {'mapID': mid, 'id': f'placeholder_{mid:02x}',
                     'placeholder': True, 'source_mapID': 0x04}
                self.warnings.append(
                    f"mapID {F.hexb(mid)} not declared — auto placeholder "
                    "(dense tables require every index)")
            dense.append(r)
        return dense

    def room_by_mid(self, mid):
        return self.rooms[mid - 0x6B]

    def master_rooms(self):
        compat = (self.build.get('compat') or {}).get('master_table_rooms')
        if compat:
            return [self.room_by_mid(F.val(m)) for m in compat]
        return list(self.rooms)

    def room_screens(self, r):
        return {int(k): v for k, v in (r.get('screens') or {}).items()}

    def subtable_width(self, r):
        scr = self.room_screens(r)
        w = r.get('subtable_width')
        if w:
            return int(w)
        top = max(scr) if scr else 0
        return 8 if top >= 4 else 4     # 4x2 grid halves (ROOM_DATA_FORMAT)

    # --------------------------------------------------------------- scripts
    def room_script_table(self, r):
        tbl = r.get('scripts') or {}
        idxs = sorted(int(k) for k in tbl)
        return [(i, tbl[str(i)]) for i in idxs]

    def script(self, sid):
        if sid not in self._scripts:
            raise ProjectError(f"script id {sid!r} not defined")
        return self._scripts[sid]

    def script_index(self, r, sid):
        for i, s in self.room_script_table(r):
            if s == sid:
                return i
        raise ProjectError(
            f"room {r.get('id')} NPC references script {sid!r} which is not "
            "in the room's script table (KEY_LESSONS S2: NPC byte 4 must "
            "match a table index >= 1)")

    # ------------------------------------------------------------------ text
    def _assign_text_ids(self):
        next_id = 0x0A00
        for e in self._dialogue:
            if 'text_id' in e:
                tid = F.val(e['text_id'])
            else:
                tid = next_id
            e['_tid'] = tid
            if tid in self._text_by_id:
                raise ProjectError(f"duplicate text id {F.hexw(tid)}")
            self._text_by_id[tid] = e
            next_id = max(next_id, tid + 1)
        # resolve script "text" ops given as dialogue ids
        by_name = {e['id']: e['_tid'] for e in self._dialogue if 'id' in e}
        for s in self.custom.get('scripts', []):
            for it in s['ops']:
                if isinstance(it, list) and it and it[0] == 'text' \
                        and isinstance(it[1], str) \
                        and it[1] in by_name:
                    it[1] = by_name[it[1]]

    def text_sections(self):
        secs = {}
        for tid in sorted(self._text_by_id):
            secs.setdefault((tid >> 8) - 0x0A, []).append(
                (tid, self._text_by_id[tid]))
        if not secs:
            return []
        if min(secs) != 0 or sorted(secs) != list(range(len(secs))):
            raise ProjectError("text sections must be dense from $0A00 "
                               "(two-level table is index-addressed)")
        for si, entries in secs.items():
            ids = [t for t, _ in entries]
            if ids != list(range(ids[0], ids[0] + len(ids))) or \
                    (ids and (ids[0] & 0xFF) != 0):
                raise ProjectError(
                    f"text ids in section {si} must be contiguous from "
                    f"{F.hexw(0x0A00 + (si << 8))} (section table is dense)")
        return [secs[i] for i in sorted(secs)]

    def text_label(self, tid):
        return f"CustomText_{tid & 0xFF:02X}" if (tid >> 8) == 0x0A \
            else f"CustomText_{tid:04X}"

    def text_comments(self):
        return {e['_tid']: e.get('comment', e.get('id', ''))
                for e in self._dialogue}

    # ----------------------------------------------------------------- flags
    def _allocate_flags(self):
        used = set()
        for fl in self.custom.get('flags', []):
            if str(fl.get('index', 'auto')) != 'auto':
                idx = F.val(fl['index'])
                self._check_flag(idx)
                fl['_index'] = idx
                used.add(idx)
        cursor = iter(i for lo, hi in FLAG_SAFE_RANGES
                      for i in range(lo, hi + 1))
        for fl in self.custom.get('flags', []):
            if '_index' in fl:
                continue
            for idx in cursor:
                if idx not in used:
                    fl['_index'] = idx
                    used.add(idx)
                    break
            else:
                raise ProjectError("flag pool exhausted (EVENT_FLAGS.md safe "
                                   "ranges)")
        self._flags = {fl['name']: fl['_index']
                       for fl in self.custom.get('flags', [])}

    def _check_flag(self, idx):
        if not any(lo <= idx <= hi for lo, hi in FLAG_SAFE_RANGES):
            raise ProjectError(
                f"flag index {F.hexw(idx)} outside EVENT_FLAGS.md safe+"
                "persistent ranges (collision zones corrupt live variables; "
                "$0278+ does not persist)")

    def flag_map(self):
        return dict(self._flags)

    # ---------------------------------------------------------- step counters
    def step_counter_allocation(self):
        if self._step_alloc is not None:
            return self._step_alloc
        alloc, used = [], {}
        explicit = []
        auto = []
        for r in self.rooms:
            for i, s in sorted(self.room_screens(r).items()):
                sc = s.get('step_counter', 'auto')
                if isinstance(sc, dict):
                    explicit.append((r, i, s, sc))
                else:
                    auto.append((r, i, s))
        for lbl, addr, cm in [(x['label'], F.val(x['addr']),
                               x.get('comment', 'reserved'))
                              for x in (self.custom.get('wram', {})
                                        .get('reserved', []))]:
            used[addr] = (lbl, cm)
        for r, i, s, sc in explicit:
            addr = F.val(sc['addr'])
            if addr in used:
                raise ProjectError(f"step counter addr {F.hexw(addr)} claimed "
                                   "twice")
            used[addr] = (sc.get('label',
                                 self._def_step_label(r, i)),
                          sc.get('comment',
                                 self._def_step_comment(r, i)))
            s['_ctr_label'] = used[addr][0]
        nxt = STEP_COUNTER_BASE
        for r, i, s in auto:
            while nxt in used:
                nxt += 1
            used[nxt] = (self._def_step_label(r, i),
                         self._def_step_comment(r, i))
            s['_ctr_label'] = used[nxt][0]
            nxt += 1
        if used and (max(used) - STEP_COUNTER_BASE + 1) > self.wram_region_size:
            raise ProjectError(
                "step counters exceed the fixed wram region size "
                f"({self.wram_region_size}) — wRoomRecScratch must stay at "
                "$DE7B; grow the region only in a deliberate engine session "
                "(PROJECT_COMPILER.md §wram)")
        self._step_alloc = [(lbl, addr, cm)
                            for addr, (lbl, cm) in sorted(used.items())]
        return self._step_alloc

    @staticmethod
    def _def_step_label(r, i):
        return f"wCustomStep_Room{F.val(r['mapID']):02X}_S{i}"

    @staticmethod
    def _def_step_comment(r, i):
        return (f"Room {F.hexb(F.val(r['mapID']))} screen {i} step counter"
                f" ({r.get('id','')})")

    def step_counter_label(self, r, i, s):
        self.step_counter_allocation()
        return s['_ctr_label']

    # --------------------------------------------------------------- renders
    def room_palette(self, r):
        pid = (r.get('render') or {}).get('palette')
        if not pid:
            return None
        if pid not in self._pal_by_id:
            raise ProjectError(f"room {r.get('id')} references palette "
                               f"{pid!r} which is not defined")
        return self._pal_by_id[pid]

    # ----------------------------------------------------------------- dests
    def resolve_dest(self, dest):
        if isinstance(dest, str) and ':' in dest:
            kind, v = dest.split(':', 1)
            mid = F.val(v)
            if kind == 'room':
                self.room_by_mid(mid)   # must exist
            return mid
        return F.val(dest)
