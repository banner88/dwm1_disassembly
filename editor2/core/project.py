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

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

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
# S97 state rules may TEST any event flag (vanilla story flags included). The
# bitfield is $D99B + idx/8; vanilla references reach $02C1 (EVENT_FLAGS.md),
# and $0278+ is not in the save image — readable, but a rule on it resets on
# reload. The cap keeps a typo from reading unrelated WRAM.
FLAG_INDEX_MAX = 0x02FF
FLAG_PERSIST_LIMIT = 0x0278
STATE_RULE_MAX_TERMS = 8
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



def _unlinked_door(e):
    """S98 r2: a door object placed but not connected yet — no destination,
    nothing to emit (validators warn)."""
    return bool(e.get('door')) and 'dest' not in e

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
        self._lower_talk_scripts()
        self.vanilla_exit_exts = (list(self.custom.get('vanilla_exit_extensions', []))
                                  + self._lower_entrance_redirects())
        self.rooms = self._dense_rooms()
        self.palettes = self.custom.get('palettes', [])
        self._pal_by_id = {p['id']: p for p in self.palettes}
        self._dialogue = self.custom.get('dialogue', [])
        self._text_by_id = {}
        self._assign_text_ids()
        self._scripts = {s['id']: s for s in self.custom.get('scripts', [])}
        # S92: custom.script_preludes {script_id: [ops...]} — prepended to the
        # named script's op stream AFTER quest lowering, so generated
        # entry:/quest: scripts can be extended without touching the lowering.
        # Motivating use: a hub room arms a destination room's step counter by
        # rank BEFORE the player transitions (state selection happens at the
        # destination's LOAD, before its own entry script runs — PyBoy-measured
        # S92, so the destination cannot arm itself for the current load).
        # Prelude labels share the script's namespace; use unique names.
        for psid, pre in (self.custom.get('script_preludes') or {}).items():
            if psid.startswith('_'):
                continue                   # _doc / annotation keys
            if psid not in self._scripts:
                raise ProjectError(
                    f"custom.script_preludes: script id {psid!r} not defined "
                    "(hand scripts and generated quest:/entry: ids are both "
                    "valid targets)")
            tgt = self._scripts[psid]
            tgt['ops'] = list(pre) + list(tgt['ops'])
            tgt['_prelude'] = f"{len(pre)} prelude ops (S92)"
        # P3.2 [G-A] (S92): banks $64/$67 fold behind project.json.
        # custom.layouts[] items each own 1-2 consecutive bank $64 entries in
        # DECLARATION order (tiles entry, then attr entry if present) — the
        # interleave the proven bank_064.asm uses (L0,A0,L1,A1) and the layout
        # CustomAttrCheck's hardwired stride expects (screen 0 -> base_entry,
        # any other screen -> base_entry+2; patches/bank_017.asm).
        self.layouts = self.custom.get('layouts', [])
        self._layout_by_id = {}
        self._layout_entry = {}       # id -> tiles entry index in bank $64
        self._attr_entry = {}         # id -> attr entry index in bank $64
        n64 = 0
        for lay in self.layouts:
            lid = lay.get('id')
            if not lid or lid in self._layout_by_id:
                raise ProjectError(f"custom.layouts: missing/duplicate id {lid!r}")
            self._layout_by_id[lid] = lay
            if 'tiles' in lay:
                self._layout_entry[lid] = n64
                n64 += 1
            if 'attr' in lay:
                self._attr_entry[lid] = n64
                n64 += 1
        # custom.tilesets[] items each own one bank $67 entry in declaration
        # order (128-tile 2bpp sheets: raw2bpp committed file, or the S6-S10
        # multi-tileset editor-export spec — see layouts.tileset_bytes).
        self.tilesets = self.custom.get('tilesets', [])
        self._tileset_entry = {}
        for i, ts in enumerate(self.tilesets):
            tid = ts.get('id')
            if not tid or tid in self._tileset_entry:
                raise ProjectError(f"custom.tilesets: missing/duplicate id {tid!r}")
            self._tileset_entry[tid] = i
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

    # ------------------------------------------------------ talk scripts (S98)
    # A script may be authored as `talk` instead of `ops` (PROJECT_COMPILER
    # §2.14): what an NPC / examine spot / step trigger does when it fires —
    # show a text, optionally ask YES/NO, then set/clear flags and optionally
    # move the player (which reloads a room, so state rules re-pick states).
    #   {"id": s, "talk": {"text": dlg, "question": false,
    #                      "then": {"set": [f], "clear": [f], "move": M}}}
    #   {"id": s, "talk": {"text": dlg, "question": true,
    #                      "yes": {"text": dlg?, "set": [], "clear": [], "move": M?},
    #                      "no":  {...}}}
    #   M = {"dest": "room:$6B" | "vanilla:$01", "screen": k, "x": cx, "y": cy}
    # Flags: project flag names or event flag numbers (resolve_flag_ref).
    # Lowered HERE into ordinary ops (before text ids resolve), so emitters
    # and validators see plain scripts. YES/NO: the question text must be a
    # `choice` dialogue ($E7 $F0); the engine leaves the answer in $C83C
    # (1 = NO — the proven check_and_branch form of every quest/teleport).
    TALK_BLOCK_KEYS = {'text', 'set', 'clear', 'move'}

    def _talk_block_ops(self, b, ctx):
        ops = []
        b = b or {}
        unknown = set(b) - self.TALK_BLOCK_KEYS - {'comment'}
        if unknown:
            raise ProjectError(f"{ctx}: unknown talk keys {sorted(unknown)}")
        if b.get('text'):
            ops.append(['text', b['text']])
        for f in b.get('set') or []:
            ops.append(['op', 'set_flag', self.resolve_flag_ref(f, ctx)])
        for f in b.get('clear') or []:
            ops.append(['op', 'clear_flag', self.resolve_flag_ref(f, ctx)])
        mv = b.get('move')
        if mv:
            dest = str(mv.get('dest', ''))
            if ':' not in dest:
                raise ProjectError(f"{ctx}: move.dest must be room:$xx or vanilla:$xx")
            mid = F.val(dest.split(':', 1)[1])
            k, x, y = int(mv.get('screen', 0)), int(mv['x']), int(mv['y'])
            if not (0 <= k <= 15 and 0 <= x <= 9 and 0 <= y <= 7):
                raise ProjectError(f"{ctx}: move to screen {k} cell ({x},{y}) outside "
                                   "the 4x4 grid / 10x8 cells")
            # MapTransitionFull ($0F, bank $04 label4_5a02): word 1 = mapID
            # (high byte = gate flag 0), words 2/3 = ABSOLUTE pixel x/y of the
            # cell centre (screen col*10 / row*8 cells + cell*16 + 8)
            px = ((k % 4) * 10 + x) * 16 + 8
            py = ((k // 4) * 8 + y) * 16 + 8
            ops.append(['op', 'map_transition', f'0x{mid:04X}', f'0x{px:04X}', f'0x{py:04X}'])
        return ops

    def _lower_talk_scripts(self):
        for s in self.custom.get('scripts', []):
            t = s.get('talk')
            if t is None or s.get('_talk_lowered'):
                continue
            ctx = f"scripts[{s.get('id')}].talk"
            if 'ops' in s:
                raise ProjectError(f"{ctx}: a script has either 'talk' or 'ops', not both")
            if not t.get('text'):
                raise ProjectError(f"{ctx}: 'text' (the dialogue shown first) is required")
            ops = [['text', t['text']]]
            if t.get('question'):
                if t.get('then'):
                    raise ProjectError(f"{ctx}: a question uses 'yes'/'no', not 'then'")
                ops.append(['op', 'check_and_branch', '0xC83C', '0x0001', '@no'])
                ops += self._talk_block_ops(t.get('yes'), ctx + '.yes') + [['end']]
                ops.append('label:no')
                ops += self._talk_block_ops(t.get('no'), ctx + '.no') + [['end']]
            else:
                if t.get('yes') or t.get('no'):
                    raise ProjectError(f"{ctx}: 'yes'/'no' need \"question\": true")
                ops += self._talk_block_ops(t.get('then'), ctx + '.then') + [['end']]
            s['ops'] = ops
            s['_talk_lowered'] = True

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

    # ------------------------------------------------ entrance redirects (S94b)
    def _lower_entrance_redirects(self):
        """custom.entrance_redirects[] -> vanilla_exit_extensions entries.

        A redirect re-points ONE vanilla door: {mapID, screen, x, y, dest,
        screen_byte, spawn_x, spawn_y}. The engine replaces a (room, screen)
        exit list WHOLESALE per step (VanillaExitResolve), so the compiler
        rebuilds every valid vanilla step's list from extracted/map_table.json
        with just the named row substituted — the other doors of that screen
        keep their vanilla rows in every state (KEY_LESSONS S92 trap). A
        redirect on a cell with no vanilla exit ADDS a door there."""
        reds = self.custom.get('entrance_redirects') or []
        if not reds:
            return []
        from .vanilla import VanillaTable
        vt = VanillaTable(getattr(self, "repo_root", None) or REPO_ROOT)
        groups = {}
        for i, r in enumerate(reds):
            ctx = f"entrance_redirects[{i}]"
            for k in ('mapID', 'screen', 'x', 'y', 'dest', 'screen_byte',
                      'spawn_x', 'spawn_y'):
                if k not in r:
                    raise ProjectError(f"{ctx}: missing '{k}' (screen_byte is "
                                       "NEVER guessed — KEY_LESSONS v14-v18/S40)")
            mid, scr = F.val(r['mapID']), F.val(r['screen'])
            if not (0 <= mid < 0x6B):
                raise ProjectError(f"{ctx}: mapID must be a vanilla room (< $6B)")
            try:
                vt.screen(mid, scr)
            except KeyError as ex:
                raise ProjectError(f"{ctx}: {ex}")
            groups.setdefault((mid, scr), []).append((ctx, r))
        out = []
        for (mid, scr), items in sorted(groups.items()):
            steps = []
            for si in range(len(vt.valid_steps(mid, scr))):
                rows = vt.step_exits(mid, scr, si)
                for ctx, r in items:
                    x, y = F.val(r['x']), F.val(r['y'])
                    new = {'x': x, 'y': y, 'dest': r['dest'],
                           'gate_flag': F.val(r.get('gate_flag', 0)),
                           'screen_byte': r['screen_byte'],
                           'spawn_x': F.val(r['spawn_x']),
                           'spawn_y': F.val(r['spawn_y']),
                           'comment': r.get('comment') or
                           f"redirect ({x},{y}) -> {r['dest']}"}
                    hit = [k for k, e in enumerate(rows)
                           if F.val(e['x']) == x and F.val(e['y']) == y]
                    if hit:
                        rows[hit[0]] = new
                    else:
                        rows.append(new)
                steps.append({'exits': rows})
            out.append({
                'mapID': f"0x{mid:02X}", 'screen': scr,
                'step_counter': f"0x{vt.counter(mid, scr):04X}",
                'steps': steps,
                'comment': f"entrance_redirects: vanilla ${mid:02X} screen {scr} "
                           + ", ".join(f"({F.val(r['x'])},{F.val(r['y'])})->{r['dest']}"
                                       for _, r in items),
                '_generated': True,
            })
        return out

    # ----------------------------------------------------------------- rooms
    def _dense_rooms(self):
        rooms = list(self.custom.get('rooms', []))
        if not rooms:
            # S94: a fresh editor project has no rooms yet — every table
            # still needs one row, so synthesize an unreachable placeholder
            # at $6B (ROM0 record row keeps the vanilla filler).
            self.warnings.append("custom.rooms is empty — emitting one "
                                 "placeholder at $6B so the tables exist")
            rooms = [{'mapID': 0x6B, 'id': 'placeholder_6b',
                      'placeholder': True, 'source_mapID': 0x04}]
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
        return (top // 4 + 1) * 4      # 4-wide rows of the 4x4 grid (ROOM_DATA_FORMAT)

    def screen_states(self, s):
        """A screen's step-entry list (P3.3 [G-G] backend half, S92).

        No 'states' key -> ONE state from the screen's own npcs/exits/layout
        (byte-identical to the pre-states emission). With 'states': each item
        {npcs?, exits?, layout?, comment?} becomes one 6-byte step entry;
        an item omitting 'layout' inherits the screen's. The engine indexes
        entries by [step counter]x6 with NO clamp (CustomPtrChase, template
        head) — entry scripts must keep the counter < len(states)."""
        states = s.get('states')
        if not states:
            if any(_unlinked_door(e) for e in s.get('exits') or []):
                s = dict(s, exits=[e for e in s['exits'] if not _unlinked_door(e)])
            return [s]
        out = []
        for st in states:
            merged = dict(st)
            if 'layout' not in merged:
                merged['layout'] = s['layout']
            merged.setdefault('npcs', st.get('npcs', []))
            merged['exits'] = [e for e in st.get('exits', []) if not _unlinked_door(e)]
            out.append(merged)
        return out

    def resolve_layout(self, ref, ctx=""):
        """Screen layout ref -> (bank, entry). Forms: {bank, entry} (any
        bank — vanilla tileset banks included) or {id} -> allocated $64."""
        if 'id' in ref:
            lid = ref['id']
            if lid not in self._layout_entry:
                raise ProjectError(
                    f"{ctx}: layout id {lid!r} not in custom.layouts "
                    "(or it has no 'tiles')")
            return 0x64, self._layout_entry[lid]
        return F.val(ref['bank']), F.val(ref['entry'])

    def screen_attr_entry(self, r, k, ctx=""):
        """(bank, entry) of the attr grid the engine loads for screen k, or
        None (= $FF, vanilla path). S94 per-screen rule: screens[k].attr
        {id}|{bank,entry} > the screen's layout item's own attr grid >
        the room-level render.attr > none."""
        scr = (r.get('screens') or {}).get(str(k)) or {}
        at = scr.get('attr')
        if at:
            if 'id' in at:
                return self.resolve_attr(at, ctx)
            return F.val(at['bank']), F.val(at['entry'])
        lay = scr.get('layout') or {}
        if 'id' in lay and lay['id'] in self._attr_entry:
            return 0x64, self._attr_entry[lay['id']]
        rat = (r.get('render') or {}).get('attr')
        if rat:
            return self.resolve_attr(rat, ctx)
        return None

    def resolve_attr(self, at, ctx=""):
        """render.attr ref -> (bank, base_entry). Forms: {bank, base_entry}
        or {id} -> the layout id's allocated $64 attr entry."""
        if 'id' in at:
            lid = at['id']
            if lid not in self._attr_entry:
                raise ProjectError(
                    f"{ctx}: attr id {lid!r} not in custom.layouts "
                    "(or it has no 'attr' grid)")
            return 0x64, self._attr_entry[lid]
        return F.val(at['bank']), F.val(at['base_entry'])

    def resolve_gfx(self, rec, ctx=""):
        """record gfx ref -> (gfx_bank, gfx_id). Forms: gfx_bank+gfx_id
        (vanilla tileset), or {"tileset": id} -> bank $67 allocated entry."""
        if 'tileset' in rec:
            tid = rec['tileset']
            if tid not in self._tileset_entry:
                raise ProjectError(
                    f"{ctx}: tileset id {tid!r} not in custom.tilesets")
            return 0x67, self._tileset_entry[tid]
        return F.val(rec['gfx_bank']), F.val(rec['gfx_id'])

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

    # ------------------------------------------------------ state rules (S97)
    def resolve_flag_ref(self, ref, ctx=""):
        """A flag reference in authored data -> event flag index. Names are
        custom.flags entries (auto-allocated from the safe pool); numbers
        ("0x0030", 48) are ANY event flag — vanilla story flags included
        (EVENT_FLAGS.md). Indices >= $0278 are readable but not saved."""
        if isinstance(ref, str) and ref in self._flags:
            return self._flags[ref]
        try:
            idx = F.val(ref)
        except Exception:
            idx = None
        if not isinstance(idx, int):
            raise ProjectError(f"{ctx}: flag {ref!r} is neither a named flag "
                               "(custom.flags) nor a flag number")
        if not 0 <= idx <= FLAG_INDEX_MAX:
            raise ProjectError(f"{ctx}: flag {F.hexw(idx)} outside the event "
                               f"flag bitfield ($0000-{F.hexw(FLAG_INDEX_MAX)})")
        return idx

    def state_rules(self, r):
        """custom.rooms[].state_rules (S97, ROADMAP P3.5a) resolved per screen.

        Authored (room level, ordered, first match wins):
            {"state": 1, "when": [{"flag": "boss_beaten"},
                                  {"flag": "0x0030", "is": "clear"}],
             "screens": [0, 1],       # optional; default = every screen
             "comment": "..."}
        A rule applies to a screen only if that screen HAS the state (a
        one-state screen never changes). Returns
        [(screen, [(state, [(flag_idx, must_be_clear), ...]), ...]), ...]
        for screens with at least one applicable rule, in screen order."""
        rules = r.get('state_rules') or []
        if not rules:
            return []
        ctx = f"room {r.get('id')} state_rules"
        resolved = []
        for i, ru in enumerate(rules):
            c = f"{ctx}[{i}]"
            unknown = set(ru) - {'state', 'when', 'screens', 'comment'}
            if unknown:
                raise ProjectError(f"{c}: unknown keys {sorted(unknown)}")
            if 'state' not in ru:
                raise ProjectError(f"{c}: 'state' is required")
            st = int(F.val(ru['state']))
            terms = []
            for t in ru.get('when') or []:
                is_ = t.get('is', 'set')
                if is_ not in ('set', 'clear'):
                    raise ProjectError(f"{c}: term 'is' must be set/clear, got {is_!r}")
                terms.append((self.resolve_flag_ref(t.get('flag'), c),
                              is_ == 'clear'))
            if len(terms) > STATE_RULE_MAX_TERMS:
                raise ProjectError(f"{c}: {len(terms)} terms (max "
                                   f"{STATE_RULE_MAX_TERMS})")
            scr_filter = ru.get('screens')
            resolved.append((st, terms,
                             None if scr_filter is None
                             else {int(x) for x in scr_filter}))
        out = []
        screens = self.room_screens(r)
        used = [False] * len(resolved)
        for k in sorted(screens):
            n = len(self.screen_states(screens[k]))
            lst = []
            for i, (st, terms, flt) in enumerate(resolved):
                if flt is not None and k not in flt:
                    continue
                if st < n:
                    lst.append((st, terms))
                    used[i] = True
            if lst:
                out.append((k, lst))
        for i, u in enumerate(used):
            if not u:
                raise ProjectError(
                    f"{ctx}[{i}]: state {resolved[i][0]} exists on none of the "
                    "screens it names — the rule could never apply")
        return out

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
            if 'addr' not in sc:
                # S92: label-only form — auto-allocate the address but pin
                # the NAME (scripts reference counters by RGBDS symbol, e.g.
                # the arena_clone rank prelude's write_ram2 target)
                auto.append((r, i, s))
                s['_ctr_name_override'] = sc['label']
                continue
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
            lbl = s.pop('_ctr_name_override', None) or \
                self._def_step_label(r, i)
            used[nxt] = (lbl, self._def_step_comment(r, i))
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
    def state_attr_entry(self, r, k, n, ctx=""):
        """(bank, entry) of the attr grid for screen k, state n (S94b):
        states[n].attr > the state's own layout item's attr > the screen rule
        (screen_attr_entry). None when nothing resolves."""
        scr = (r.get('screens') or {}).get(str(k)) or {}
        sts = scr.get('states') or []
        if n < len(sts):
            st = sts[n]
            at = st.get('attr')
            if at:
                if 'id' in at:
                    return self.resolve_attr(at, ctx)
                return F.val(at['bank']), F.val(at['entry'])
            lay = st.get('layout') or {}
            if 'id' in lay and lay['id'] in self._attr_entry:
                return 0x64, self._attr_entry[lay['id']]
        return self.screen_attr_entry(r, k, ctx)

    def state_palette_ref(self, r, k, n):
        """Palette for screen k, state n: ('label', asm label) for a project
        palette (states[n].palette > render.palette) or ('addr', ptr) = the
        vanilla source room's own palette block in bank $17 (borrow)."""
        scr = (r.get('screens') or {}).get(str(k)) or {}
        sts = scr.get('states') or []
        pid = None
        if n < len(sts):
            pid = sts[n].get('palette')
        # S95: screens[k].palette sits between the state and the room default
        pid = pid or scr.get('palette') or (r.get('render') or {}).get('palette')
        if pid:
            if pid not in self._pal_by_id:
                raise ProjectError(f"room {r.get('id')} references palette "
                                   f"{pid!r} which is not defined")
            return 'label', self._pal_by_id[pid]['label']
        src = F.val(r.get('source_mapID', 0))
        return 'addr', self.vanilla_palette_ptr(src)

    def vanilla_palette_ptr(self, mid):
        """Bank $17 pointer of a vanilla room's environment palette block
        (derive_room_palette.normal_room_pal_ptr — the same derivation the
        renderer's 'borrow' path uses). Needs data/DWM-original.gbc."""
        cache = getattr(self, '_vpal_cache', None)
        if cache is None:
            cache = self._vpal_cache = {}
        if mid not in cache:
            import importlib.util
            path = os.path.join(self.repo_root or '.', 'tools', 'derive_room_palette.py')
            spec = importlib.util.spec_from_file_location('_drp', path)
            drp = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(drp)
            rom_path = os.path.join(self.repo_root or '.', 'data', 'DWM-original.gbc')
            if not os.path.exists(rom_path):
                raise ProjectError("borrowing a vanilla palette needs data/DWM-original.gbc "
                                   "at compile time (or give the room a project palette)")
            rom = open(rom_path, 'rb').read()
            ptr = drp.normal_room_pal_ptr(rom, mid)
            if ptr is None:
                raise ProjectError(f"vanilla map ${mid:02X} has no attr palette to borrow")
            cache[mid] = ptr
        return cache[mid]

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
