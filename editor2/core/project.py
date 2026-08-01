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
# use. CORRECTED S57: the previous ranges were derived from script analysis
# only and included bytes with live ENGINE literal refs ($D9CC, $D9D9-$D9E2,
# $D9E7-$D9E8) and script-referenced bytes ($D9DF/$D9E0/$D9E2/$D9E4/$D9E5/
# $D9E8) — allocating there corrupts named engine variables. Per-byte audit
# (engine literals + all_scripts.json) leaves exactly $D9C6-$D9C7 and
# $D9D7-$D9D8 clean. Flags $0168-$017F ($D9C8-$D9CA) are RETIRED: those bytes
# are wPendingFarmExp (CF2). Flags $01E0-$01EF ($D9D7-$D9D8) are RETIRED S73:
# those bytes are wAnchorGate/wAnchorFloor (custom skill $E4 Anchor persistent
# state). See EVENT_FLAGS.md "Free Flag Slots".
FLAG_SAFE_RANGES = [(0x0158, 0x0167)]
# S65 migration: step counters live in the CF3-freed window (WRAM $CC80-$D664,
# freed S60 — MONSTER_DATA "CF3 as built"). $CD80-$CFFF is the counter region;
# $CC80/$CD00 hold the relocated NPC/exit buffers; $D001-$D664 is the reserved
# transient pool (wCustomPool). The whole window is TRANSIENT: CF3's save copy
# skips its SRAM image window $A3BA-$AD9E in BOTH directions (live farm storage
# sits behind it), so nothing here survives save+reload. Persistent room state
# stays event flags + entry scripts (user decision S55, reaffirmed S65).
# wRoomRecScratch stays pinned at $DE7B by a static `ds 7` pad in wram.asm.
STEP_COUNTER_BASE = 0xCD80
WRAM_REGION_MAX = 0x280             # $CD80+$280 = $D000 = the wram0 section end
WRAM_REGION_SIZE_DEFAULT = 0x280    # 640 counters — campaign-scale default
# S70 (ROADMAP E2 wiring): progression.enemies rows append past the vanilla
# 487-row enemy-stats table. EID 518 = Gorbunok (build_new_species.py); the
# quest region (@BUILD_PROJECT quest_enemy_stats, patches/bank_014.asm) owns
# $7ECC+ = EIDs 519+ (row addr = $4C1D + EID*25 — MONSTER_DATA "Enemy Stats
# Table"; LoadEnemyStats has no bounds check, 16-bit EID). ds-308 tail = 12
# rows capacity.
QUEST_EID_BASE = 519
QUEST_EID_CAP = 12
QUEST_REGION_BYTES = 308


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
        # S70 (E2 wiring): progression is lowered into ordinary custom.scripts
        # BEFORE rooms/dialogue/scripts resolution, so every downstream
        # validator and emitter sees plain compiler content. Flags allocate
        # first (lowered ops embed resolved flag indices).
        self.progression = data.get('progression') or {}
        self._check_progression_shape()
        self._flags = {}
        self._register_progression_flags()
        self._allocate_flags()
        self.quest_enemies = self._resolve_quest_enemies()
        self._lower_quests()
        self.vanilla_exit_exts = self.custom.get('vanilla_exit_extensions', [])
        self.rooms = self._dense_rooms()
        self.palettes = self.custom.get('palettes', [])
        self._pal_by_id = {p['id']: p for p in self.palettes}
        self._dialogue = self.custom.get('dialogue', [])
        self._text_by_id = {}
        self._assign_text_ids()
        self._scripts = {s['id']: s for s in self.custom.get('scripts', [])}
        self.wram_region_size = (self.custom.get('wram', {})
                                 .get('region_size', WRAM_REGION_SIZE_DEFAULT))
        if self.wram_region_size > WRAM_REGION_MAX:
            raise ProjectError(
                f"wram.region_size {self.wram_region_size} exceeds "
                f"{WRAM_REGION_MAX} — the region ends at $D000 (wram0 section "
                "boundary; $D001+ is wCustomPool). Growing past it is a "
                "deliberate engine change (PROJECT_COMPILER.md §2.6)")
        self._step_alloc = None
        self.repo_root = None          # set by compiler.compile_project
        self._music = None

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
        if music is not None and not isinstance(music, dict):
            raise ProjectError(
                "custom.music must be an object {libraries, songs, "
                "room_defaults} (PROJECT_COMPILER.md §2.9; implemented S64)")
        if music:
            bad = [k for k in music
                   if k not in ('libraries', 'songs', 'room_defaults')
                   and not k.startswith('_')]
            if bad:
                raise ProjectError(
                    f"custom.music: unknown key(s) {bad} — refusing to "
                    "silently ignore authored data")
        skills = (self.data.get('custom') or {}).get('skills')
        if skills:
            raise ProjectError(
                "custom.skills is NOT_IMPLEMENTED in v1 (data-half emitter "
                "is a scoped follow-up; BATTLE_SKILL_SYSTEM §13) — refusing "
                "to silently ignore it")

    # ------------------------------------------------------------ progression
    # S70 — ROADMAP E2 wiring. Owning spec: SIDEQUEST_MAP "Story progression
    # ENGINE + AUTHORING SPEC — DECODED S68". A quest LOWERS to two ordinary
    # generated scripts (registered under ids "quest:<id>" / "entry:<id>",
    # referenced from rooms[].scripts like any hand script):
    #   quest:<id>  — done-gate -> requires ladder -> YES/NO offer ->
    #                 trigger_battle3 -> on-win tail (the vanilla boss shape:
    #                 win resumes the script after the battle opcode; loss/
    #                 flee clear $D8D7 -> script vanishes -> quest re-arms).
    #   entry:<id>  — room entry (index 0): done-branch (entry_done actions,
    #                 e.g. hide the beaten guardian) -> once-gated cutscene.
    def _check_progression_shape(self):
        bad = [k for k in self.progression
               if k not in ('quests', 'enemies') and not k.startswith('_')]
        if bad:
            raise ProjectError(
                f"progression: unknown key(s) {bad} — v1 implements "
                "quests + enemies only (PROJECT_COMPILER.md §progression); "
                "refusing to silently ignore authored data")

    def _register_progression_flags(self):
        """Quest flag NAMES become ordinary custom.flags entries (auto index
        from the EVENT_FLAGS safe pool) unless already declared."""
        flags = self.custom.setdefault('flags', [])
        have = {f['name'] for f in flags}
        for q in self.progression.get('quests', []):
            for role in ('done', 'cutscene_seen'):
                name = (q.get('flags') or {}).get(role)
                if name and name not in have:
                    flags.append({'name': name,
                                  'comment': f"progression.quests[{q.get('id')}] {role}"})
                    have.add(name)

    def _flag_index(self, name, ctx):
        if name not in self._flags:
            raise ProjectError(f"{ctx}: flag {name!r} is not defined")
        return self._flags[name]

    def _resolve_quest_enemies(self):
        out, nxt = {}, QUEST_EID_BASE
        for e in self.progression.get('enemies', []):
            eid = e.get('eid', 'auto')
            eid = nxt if str(eid) == 'auto' else F.val(eid)
            e['_eid'] = eid
            nxt = max(nxt, eid + 1)
            if e['id'] in out:
                raise ProjectError(f"progression.enemies: duplicate id {e['id']!r}")
            out[e['id']] = e
        return out

    def quest_enemy_rows(self):
        """Enemies in EID order for the bank $14 region emitter."""
        return sorted(self.quest_enemies.values(), key=lambda e: e['_eid'])

    def _lower_actions(self, acts, ctx, dialog_prefix=False):
        """dialog_prefix=True: the ops run OUTSIDE an NPC interaction (entry
        script / post-battle tail) where the text queue is only serviced in
        dialog mode — every text gets its own preceding init_dialog, exactly
        like the vanilla Healer post-battle words FF07/0059 and FF07/0146
        (S70 finding: dismissal tears script-initiated dialog mode down, so
        each say re-enters it)."""
        ops = []
        for a in acts:
            if isinstance(a, (list, str)):
                ops.append(a)                     # raw script item pass-through
            elif 'op' in a:
                ops.append(['op'] + list(a['op']))
            elif 'text' in a:
                if dialog_prefix:
                    ops.append(['op', 'init_dialog'])
                ops.append(['text', a['text']])
            elif 'set_flag' in a:
                ops.append(['op', 'set_flag', self._flag_index(a['set_flag'], ctx)])
            elif 'clear_flag' in a:
                ops.append(['op', 'clear_flag', self._flag_index(a['clear_flag'], ctx)])
            elif 'npc_hide' in a:
                ops.append(['op', 'npc_hide', int(a['npc_hide'])])
            elif 'npc_show' in a:
                ops.append(['op', 'npc_show', int(a['npc_show'])])
            elif 'give_item' in a:
                ops.append(['op', 'give_item', a['give_item']])
            elif 'write_ram' in a:
                addr, val = a['write_ram']
                ops.append(['op', 'write_ram', addr, val])
            else:
                raise ProjectError(f"{ctx}: unknown action {a!r}")
        return ops

    def quest_battle_eid(self, q):
        b = q.get('battle') or {}
        if 'eid' in b:
            return F.val(b['eid'])
        en = b.get('enemy')
        if en not in self.quest_enemies:
            raise ProjectError(
                f"progression.quests[{q.get('id')}]: battle.enemy {en!r} not "
                "in progression.enemies (and no explicit battle.eid)")
        return self.quest_enemies[en]['_eid']

    def _lower_quests(self):
        scripts = self.custom.setdefault('scripts', [])
        have = {s['id'] for s in scripts}
        for q in self.progression.get('quests', []):
            qid = q.get('id') or '?'
            ctx = f"progression.quests[{qid}]"
            done = self._flag_index((q.get('flags') or {}).get('done'), ctx) \
                if (q.get('flags') or {}).get('done') else None
            if done is None:
                raise ProjectError(f"{ctx}: flags.done is required (the quest "
                                   "completion gate must persist — safe pool)")
            # ---- quest:<id> — the NPC script (vanilla boss shape) ----
            ops = [['op', 'if_flag_set', done, '@qdone']]
            for i, req in enumerate(q.get('requires', [])):
                ops.append(['op', 'check_and_branch',
                            req['ram'], req['equals'], f'@req{i}'])
                ops.append(['text', req['else_text']])
                ops.append(['end'])
                ops.append(f'label:req{i}')
            offer = q.get('offer')
            if offer:
                ops.append(['text', offer['text']])
                ops.append(['op', 'check_and_branch', '0xC83C', 1, '@declined'])
                if offer.get('prebattle_text'):
                    ops.append(['text', offer['prebattle_text']])
            ops.append(['op', 'trigger_battle3', self.quest_battle_eid(q)])
            # WIN resumes here (S68 engine guarantee); loss/flee never reach
            # it. The resumed context is FIELD mode — dialog_prefix gives
            # every win text its own init_dialog (vanilla Healer protocol).
            ops += self._lower_actions(
                [{'set_flag': q['flags']['done']}] + list(q.get('on_win', [])),
                ctx, dialog_prefix=True)
            ops.append(['end'])
            if offer:
                ops.append('label:declined')
                if offer.get('decline_text'):
                    ops.append(['text', offer['decline_text']])
                ops.append(['end'])
            ops.append('label:qdone')
            if q.get('already_done_text'):
                ops.append(['text', q['already_done_text']])
            ops.append(['end'])
            sid = f'quest:{qid}'
            if sid in have:
                raise ProjectError(f"{ctx}: script id {sid!r} already exists")
            scripts.append({'id': sid, 'ops': ops,
                            '_generated': ctx})
            # ---- entry:<id> — room-entry script (index 0) ----
            cut = q.get('entry_cutscene')
            edone = q.get('entry_done')
            if cut or edone:
                e = []
                if edone:
                    e.append(['op', 'if_flag_set', done, '@edone'])
                if cut:
                    seen_name = (q.get('flags') or {}).get('cutscene_seen')
                    if not seen_name:
                        raise ProjectError(f"{ctx}: entry_cutscene requires "
                                           "flags.cutscene_seen (once-gate)")
                    seen = self._flag_index(seen_name, ctx)
                    e.append(['op', 'if_flag_set', seen, '@eseen'])
                    e += self._lower_actions(list(cut.get('ops', [])), ctx, dialog_prefix=True)
                    e.append(['op', 'set_flag', seen])
                e.append(['end'])
                if cut:
                    e.append('label:eseen')
                    e.append(['end'])
                if edone:
                    e.append('label:edone')
                    e += self._lower_actions(list(edone), ctx, dialog_prefix=True)
                    e.append(['end'])
                scripts.append({'id': f'entry:{qid}', 'ops': e,
                                '_generated': ctx})

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
                f"({self.wram_region_size}, max {WRAM_REGION_MAX} — region "
                "ends at the $D000 wram0 section boundary; see "
                "PROJECT_COMPILER.md §2.6)")
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

    # ----------------------------------------------------------------- music
    def music_resolved(self):
        """(bank74_library, room_bgm[128], song_ids, warnings) — cached so
        the double-emit determinism check sees identical results."""
        if self._music is None:
            from . import music as M
            self._music = M.resolve(self)
        return self._music

    def music_room_bgm(self, warnings=None):
        lib, room_bgm, ids, mw = self.music_resolved()
        if warnings is not None:
            for w in mw:
                if w not in warnings:
                    warnings.append(w)
        return room_bgm

    def music_song_ids(self):
        return dict(self.music_resolved()[2])

    # ----------------------------------------------------------------- dests
    def resolve_dest(self, dest):
        if isinstance(dest, str) and ':' in dest:
            kind, v = dest.split(':', 1)
            mid = F.val(v)
            if kind == 'room':
                self.room_by_mid(mid)   # must exist
            return mid
        return F.val(dest)
