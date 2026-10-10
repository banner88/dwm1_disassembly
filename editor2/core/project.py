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


_VANILLA_SCREENS = None


def vanilla_screens():
    """{mapID: [screen numbers]} of the game's rooms (extracted/map_table.json: the
    sub-rooms with room data — what render_project.vanilla_rooms lists); {} when
    the table is missing (S121 r3)."""
    global _VANILLA_SCREENS
    if _VANILLA_SCREENS is None:
        out = {}
        try:
            for e in json.load(open(os.path.join(REPO_ROOT, 'extracted', 'map_table.json'))):
                mid = e.get('map_type')
                if mid is None or mid >= 0x6B:
                    continue
                scr = sorted(sr['c925'] for sr in e.get('sub_rooms', []) if sr.get('steps'))
                if scr:
                    out[mid] = scr
        except (OSError, ValueError):
            out = {}
        _VANILLA_SCREENS = out
    return _VANILLA_SCREENS

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
# S117 (FLAG EXPANSION): + the EXTENDED flags $1000-$17FF (2,048; WRAM
# wExtFlags $D140, saved to SRAM bank 3 by the explicit save — bank $73
# FlagAddr / ExtFlagsCommit / ExtFlagsRestore; EVENT_FLAGS "Extended flags").
# The allocator takes the 16 vanilla-safe flags first (so pre-S117 projects
# keep their numbers), then $1000 up. The top 96 ($17A0-$17FF) are the gates'
# own "cleared" flags (gate n -> GATE_FLAG_BASE + n; NG2, gates.py) — never
# allocated to names, so a gate's flag never moves when names are added.
EXT_FLAG_FIRST, EXT_FLAG_LAST = 0x1000, 0x17FF
GATE_FLAG_BASE = 0x17A0                  # + gate number 0-95
# S121 (the Milly hook): $179E / $179F are the hook's own flags (milly.py
# RESERVED_FLAGS: "the arrival scene played" / "the player is Milly") — taken
# out of the named pool, so a name can never land on them.
MILLY_FLAGS_FIRST = 0x179E
FLAG_SAFE_RANGES = [(0x0158, 0x0167), (EXT_FLAG_FIRST, MILLY_FLAGS_FIRST - 1)]
# S124 (ROADMAP P3.14a): $0158 is NOT free — the original game's Arena Battle room
# ($5D, script 0, bank $0F $6890 / $6898) tests and sets it (Milayou's rematch: her
# first words, then "Are you challenging me again?"); the S8 audit's decoder never
# reached that branch (EVENT_FLAGS "Safe pool"). A NAMED flag may still carry it
# (projects numbered before S124 keep their numbers — old saves), but numbers are
# handed out from FLAG_AUTO_RANGES only. S128 r2 (user: "This should NOT be happening
# by default, not requiring manual curation"): the compiler's "auto" numbering uses
# FLAG_AUTO_RANGES too (number_flags), and opening a project moves a flag that sits
# on a GAME_SHARED number to a free one (Document._migrate_shared_flags).
GAME_SHARED_FLAGS = {0x0158: "the original game's Arena Battle room (Milayou's rematch: "
                             "her first words, or \"Are you challenging me again?\")"}
FLAG_AUTO_RANGES = [(0x0159, 0x0167), (EXT_FLAG_FIRST, MILLY_FLAGS_FIRST - 1)]
# S97 state rules may TEST any event flag (vanilla story flags included). The
# bitfield is $D99B + idx/8; vanilla references reach $02C1 (EVENT_FLAGS.md),
# and $0278+ is not in the save image — readable, but a rule on it resets on
# reload. The cap keeps a typo from reading unrelated WRAM: $0300-$0FFF (and
# above $17FF) would land past the vanilla bitfield in live WRAM — refused.
FLAG_INDEX_MAX = EXT_FLAG_LAST
FLAG_VANILLA_MAX = 0x02FF
FLAG_PERSIST_LIMIT = 0x0278


def flag_persistent(idx):
    """True when event flag `idx` is inside a save image (vanilla $0000-$0277
    or the S117 extended range)."""
    return idx < FLAG_PERSIST_LIMIT or EXT_FLAG_FIRST <= idx <= EXT_FLAG_LAST


def flag_index_ok(idx):
    return 0 <= idx <= FLAG_VANILLA_MAX or EXT_FLAG_FIRST <= idx <= EXT_FLAG_LAST


def flag_in_pool(idx):
    """True when `idx` may carry a NAMED project flag (FLAG_SAFE_RANGES)."""
    return any(lo <= idx <= hi for lo, hi in FLAG_SAFE_RANGES)


def number_flags(flags, check=None, ranges=None):
    """[event flag number] of each custom.flags entry, in list order — THE
    numbering of the compiler (Project._allocate_flags) and of the editor's
    pinning (S124, Document._migrate_pin_flags / add_flag): an explicit
    `index` keeps its number (`check(idx)` may refuse it); every `"auto"`
    entry takes the lowest free number of FLAG_SAFE_RANGES, in list order.
    Positional: deleting or moving an auto entry renumbers the later ones —
    which is why the editor pins every number once (old saves keep their
    meaning).
    S128 r2 (user: "This should NOT be happening by default, not requiring manual
    curation"): an "auto" entry that lands on a GAME_SHARED number ($0158 — the
    first auto flag of every project, the example's quest flag too) then moves to
    the lowest number of FLAG_AUTO_RANGES nobody has; every other number stays
    what it was (old saves keep their meaning). Document._migrate_shared_flags
    does the same on open, so the editor's pinned numbers == the compiler's.
    `ranges` given = plain numbering from those ranges, no move. Raises ValueError
    when the pool is exhausted."""
    out = [None] * len(flags)
    used = set()
    for i, fl in enumerate(flags):
        if str(fl.get('index', 'auto')) != 'auto':
            idx = F.val(fl['index'])
            if check is not None:
                check(idx)
            out[i] = idx
            used.add(idx)
    auto = [i for i in range(len(flags)) if out[i] is None]
    cursor = iter(i for lo, hi in (ranges or FLAG_SAFE_RANGES) for i in range(lo, hi + 1))
    for i in auto:
        for idx in cursor:
            if idx not in used:
                out[i] = idx
                used.add(idx)
                break
        else:
            raise ValueError("flag pool exhausted (EVENT_FLAGS.md safe ranges)")
    if ranges is None:
        free = (i for lo, hi in FLAG_AUTO_RANGES for i in range(lo, hi + 1) if i not in used)
        for i in auto:
            if out[i] in GAME_SHARED_FLAGS:
                new = next(free, None)
                if new is None:
                    raise ValueError("flag pool exhausted (EVENT_FLAGS.md safe ranges)")
                used.discard(out[i])
                out[i] = new
                used.add(new)
    return out


def quest_flag_entries(custom, progression):
    """The custom.flags entries the compiler adds for quest flag NAMES not
    declared (Project._register_progression_flags), in its order: the legacy
    progression.quests (S70), then the S129 custom.quests (started / done)."""
    have = {f.get('name') for f in (custom or {}).get('flags', [])}
    out = []
    for q in (progression or {}).get('quests', []):
        for role in ('done', 'cutscene_seen'):
            name = (q.get('flags') or {}).get(role)
            if name and name not in have:
                out.append({'name': name,
                            'comment': f"progression.quests[{q.get('id')}] {role}"})
                have.add(name)
    from . import story as _ST
    for e in _ST.quest_flag_entries(dict(custom or {}, flags=list((custom or {}).get('flags', []))
                                         + out)):
        if e['name'] not in have:
            out.append(e)
            have.add(e['name'])
    return out
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
# S133: the last custom map id the engine can tell apart — bank $60
# CustomPtrChase / CustomStateRules / CustomMonsterCast and bank $17
# CustomAttrCheck double `mapID - $6B` in 8 bits (CROSSBANK_ROOMS "Custom-side
# arithmetic ceilings"). 128 rooms $6B-$EA; ROADMAP ARC CAP lifts it.
CUSTOM_MID_MAX = 0xEA

# S135 (ROADMAP ARC CAP2a): the LZ STREAM banks. Layouts + attr maps (home bank
# $64), tilesets (home bank $67) and — when a home bank is full — the overflow
# banks of the 4 MB ROM ($80-$FF) are all read by ROM0 DecompressTileLayout
# ($1627): D = bank, E = entry, stream pointer = the word at $4001 + 2E of that
# bank (so <= 256 entries a bank), and a stream never crosses $7FFF. Any bank
# serves any of the three kinds (S135 trace: room step [step_id, bank], the
# bank $17 attr walk [attr_entry, attr_bank], the $26DD record [gfx_id,
# gfx_bank] all carry the bank). ARCHITECTURE "LZ stream banks (S135)".
LAYOUT_HOME_BANK = 0x64
TILESET_HOME_BANK = 0x67
STREAM_BANK_SIZE = 0x4000
STREAM_BANK_MAX_ENTRIES = 256
EXT_BANK_FIRST, EXT_BANK_LAST = 0x80, 0xFF
# Project enemy rows (S101; MONSTER_DATA "Project enemy rows"). EID 518 was
# the S30 Gorbunok row (retired S105: a new species' rows are project enemies
# like any other; bank $14 $7EB3 is free space again). EVERY EID >= 519 is a
# progression.enemies row in bank $6B (compiler-owned patches/bank_06b.asm,
# row = EID-519): the bank-$14 LoadEnemyStats head now diverts EIDs >= 519 to
# bank $6B entry 0 (S70-S100 kept 12 rows in the bank-$14 tail instead). The
# tail now holds the divert + BossRedirectTableExt (project fight->join rows,
# then the 34 vanilla rows).
PROJECT_EID_BASE = 519
PROJECT_EID_CAP = 640              # bank $6B: ~16 KB / 25 B, minus the head
REDIRECT_ROWS_MAX = 34             # bank $14 tail: 308 - 28 B code - 4*(34 vanilla + end) = 136 B
QUEST_EID_BASE = PROJECT_EID_BASE  # legacy names (S70)
QUEST_EID_CAP = PROJECT_EID_CAP



def _unlinked_door(e):
    """S98 r2: a door object placed but not connected yet — no destination,
    nothing to emit (validators warn)."""
    return bool(e.get('door') or e.get('twin_of')) and 'dest' not in e   # S128 r3: + a double door's 2nd cell

def _pv(v):
    """A script text param as an int when it is one (dialogue ids resolved)."""
    try:
        return F.val(v)
    except Exception:                                        # noqa: BLE001
        return v


class ProjectError(ValueError):
    pass


SKILL_SCRIPTS_JSON = os.path.join(os.path.dirname(__file__), 'skill_scripts.json')


def _skill_scripts():
    """(scripts, dialogue) — fresh copies of the custom skills' built-in dialog
    scripts (S105; the list ORDER is the id bank $72 arms, script type $FF)."""
    d = json.load(open(SKILL_SCRIPTS_JSON))
    return d['scripts'], d['dialogue']


class Project:
    def __init__(self, data, root):
        # S123: set first — the lowering below resolves `gate:N` flag refs (a
        # conversation's If / Turn ON of a gate's cleared flag), which read it;
        # compiler.compile_project sets the real value after construction
        self.repo_root = None
        self._rooms_resolved = False   # S123: Vanish conversations wait for the rooms
        self._vanish_places = {}
        self._helper_screens = {}      # S101 r2: helper script -> screen keys
        self._lowering_sid = None
        self._hub = None               # S125: custom.hub resolved (hub_rules)
        self._hub_lab = 0
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
        # S129 (ROADMAP P3.14b / c): the story checks (virtual flags $1800+) are
        # named like flags; the quests become their givers' conversations
        self._allocate_checks()
        self._story_cmds = []
        self.quest_enemies = self._resolve_quest_enemies()
        self._lower_quests()
        self.story_error = None
        from . import story as _ST
        try:
            self.quest_scripts = _ST.lower_quests(self.custom)
        except _ST.StoryError as ex:
            self.story_error = str(ex)
            self.quest_scripts = []
        self._lower_talk_scripts()
        self._lower_shop_scripts()
        # S126 (ROADMAP P3.14e1): service NPCs (+ shop line sets) — the vanilla
        # NPC's shape, the project's lines (editor2/core/services.py). A bad
        # service is reported by validators.validate (service_error); its
        # script becomes a bare `end` so the editor still opens (S119b rule)
        from . import services as _SV
        self.service_error = None
        try:
            _SV.lower(self)
        except _SV.ServiceError as ex:
            self.service_error = str(ex)
            for _s in self.custom.get('scripts', []):
                if 'service' in _s and 'ops' not in _s:
                    _s['ops'] = [['end']]
        self.vanilla_exit_exts = (list(self.custom.get('vanilla_exit_extensions', []))
                                  + self._lower_entrance_redirects())
        self.rooms = self._dense_rooms()
        self._normalize_stairs()
        # S101: helper-exit conversations need their NPC slot, known only
        # once rooms resolve — place the helpers, then lower those scripts
        # (S123: Vanish steps need the talkers' slots too)
        self._rooms_resolved = True
        self._vanish_places = self._resolve_vanish_slots()
        self._lower_talk_scripts(self._place_helpers())
        # S127 (ROADMAP P3.14e2): Grandpa / breeder scripts need their NPC's slot —
        # lowered now (a cutscene may wrap their talk next); the rooms' return
        # scripts go in front of the entry scripts after the cutscenes (below)
        from . import breeders as _BR
        self.breed_error = None
        try:
            _BR.lower_talk(self)
        except (_BR.BreedError, ProjectError, _SV.ServiceError) as ex:
            self.breed_error = str(ex)
            self._breeding = {}
            for _s in self.custom.get('scripts', []):
                if isinstance(_s.get('service'), dict) and 'ops' not in _s:
                    _s['ops'] = [['end']]
        # S128 (ROADMAP P3.14e3): your arena — the receptionist's desk (the lobby
        # copy's script 6) is generated now, so a cutscene may still wrap its talk
        from . import your_arena as _YA
        self.arena_error = None
        try:
            _YA.lower_desk(self)
        except (_YA.ArenaRoomError, ProjectError, _SV.ServiceError) as ex:
            self.arena_error = str(ex)
        # S119 (ROADMAP P3.8 part B): the rooms' own cutscenes become ordinary
        # scripts wired to their triggers (entry / talk / examine / step-on) —
        # after the helpers, so every script they wrap is already ops
        from . import cutscene_build as CB
        # S119b (user's editor would not open: a scene's too-long text made every
        # Project() fail — the Families / Breeding / Monsters tabs build one for their
        # models): a cutscene problem is recorded here and reported by
        # validators.validate, so it stops a BUILD (with its message), never the editor
        self.cutscene_error = None
        # S121 (ROADMAP P3.16 + E7, the Milly hook): the arrival room's generated
        # spin-in scene goes in FIRST (milly.lower); its problems stop a build
        # the same way a cutscene's do
        from . import milly as _MH
        try:
            _MH.lower(self)
        except _MH.HookError as ex:
            self.cutscene_error = str(ex)
        try:
            self.cutscene_patches = CB.lower_project(self)
        except CB.CutsceneError as ex:
            self.cutscene_error = self.cutscene_error or str(ex)
            self.cutscene_patches = {}
        try:
            _BR.lower_entries(self)
        except (_BR.BreedError, ProjectError, _SV.ServiceError) as ex:
            self.breed_error = self.breed_error or str(ex)
        if self.arena_error is None:          # S128: back from the arena (entry scripts)
            try:
                _YA.lower_entries(self)
            except (_YA.ArenaRoomError, ProjectError, _SV.ServiceError) as ex:
                self.arena_error = str(ex)
        self._gate_rows = None
        self.palettes = self.custom.get('palettes', [])
        self._pal_by_id = {p['id']: p for p in self.palettes}
        # S105 (P3.9b): the custom skills' own dialog scripts + texts
        # (editor2/core/skill_scripts.json) are part of EVERY build — script
        # type $FF, bank $60 SkillScriptPtrTable — appended after the project's
        # dialogue so its text ids never move. Copies: never written back into
        # the project's data (the editor saves self.data).
        self.skill_scripts, skill_dialogue = _skill_scripts()
        try:
            self._hub_anchor()
        except ProjectError as ex:            # S125: reported by validate, the editor opens
            self.cutscene_error = self.cutscene_error or str(ex)
        # S111 (P3.11c): Anchor's dialog texts are editable project data
        # (gamedata.skills.228.dialogs -> the `lines` of the built-in texts)
        from . import custom_skills as CS
        over = CS.dialog_overrides(data)
        for d in skill_dialogue:
            if d['id'] in over:
                d['lines'] = list(over[d['id']])
        for sec, lst in (('scripts', self.custom.get('scripts', [])),
                         ('dialogue', self.custom.get('dialogue', []))):
            bad = [x.get('id') for x in lst if str(x.get('id', '')).startswith('skill:')]
            if bad:
                raise ProjectError(f"custom.{sec}: ids {bad} — 'skill:' ids are "
                                   "reserved for the custom skills' built-in scripts "
                                   "(editor2/core/skill_scripts.json)")
        self._dialogue = list(self.custom.get('dialogue', [])) + skill_dialogue
        # S126: the service lines a line set / the medal rewards replace
        # (raw bytes in the vanilla frame; services.resolve) — after the
        # skill texts, so no earlier id moves
        try:
            self._dialogue += [dict(e) for e in _SV.resolve(self)['dialogue']]
        except _SV.ServiceError as ex:
            self.service_error = self.service_error or str(ex)
        try:                                  # S128: your arena's "not open yet" words
            self._dialogue += _YA.locked_dialogue(self)
        except (_YA.ArenaRoomError, _SV.ServiceError) as ex:
            self.arena_error = self.arena_error or str(ex)
        self._text_by_id = {}
        self._assign_text_ids()
        self._scripts = {s['id']: s for s in
                         list(self.custom.get('scripts', [])) + self.skill_scripts}
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
        # custom.layouts[] items each own 1-2 stream ORDINALS in DECLARATION
        # order (tiles, then attr if present) — the S92 bank $64 entry order.
        # S135 (ARC CAP2a): where a stream really lives (bank $64 / $67 or an
        # overflow bank $80+, and its entry there) is stream_plan(); these
        # ordinals only give an authored {bank: $64, entry: N} its old meaning
        # (_explicit_stream_ref). (The "screen 0 -> base, other -> base+2"
        # stride this comment once cited was replaced by explicit per-state
        # render rows in S94b.)
        self.layouts = self.custom.get('layouts', [])
        self._layout_by_id = {}
        self._layout_entry = {}       # id -> tiles stream ordinal (S92 $64 entry)
        self._attr_entry = {}         # id -> attr stream ordinal (S92 $64 entry)
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
        # custom.tilesets[] items: declaration index (= the S92 bank $67 entry;
        # S135: the real place is stream_plan()) (128-tile 2bpp sheets:
        # raw2bpp committed file, or the S6-S10 multi-tileset editor-export
        # spec — see layouts.tileset_bytes).
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
        self._stream_plan = None       # S135 (ARC CAP2a): stream_plan(), lazy
        self._place_plan = None        # S136 (ARC CAP2b): places.plan(), lazy (after streams)
        self._anim_plan = None         # S139 (ARC CAP2d): tileanim.plan(), lazy (after places)
        self._music = None
        self._gamedata = None

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
        # S103 (P3.9): `gamedata` is implemented (Layer A-lite, gamedata.py);
        # its schema errors surface through validators (Project.gamedata()).
        for layer in ('world',):
            sec = self.data.get(layer)
            if sec and any(k for k in sec if not k.startswith('_')):
                raise ProjectError(
                    f"layer '{layer}' is NOT_IMPLEMENTED in compiler v1 — "
                    "content found; refusing to silently ignore it "
                    "(PROJECT_COMPILER.md §layers)")
        music = (self.data.get('custom') or {}).get('music')
        if music is not None and not isinstance(music, dict):
            raise ProjectError(
                "custom.music must be an object {libraries, songs, names, "
                "room_defaults, gates, battle} (PROJECT_COMPILER.md §2.9)")
        if music:
            from . import music as _M
            bad = [k for k in music
                   if k not in _M.MUSIC_KEYS
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
        flags.extend(quest_flag_entries(self.custom, self.progression))

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

    def gamedata(self):
        """The resolved Layer A-lite tables (editor2/core/gamedata.py; S103,
        PROJECT_COMPILER §2.20). Raises gamedata.GamedataError on bad data —
        validators.validate reports it as an error before any emitter runs."""
        if self._gamedata is None:
            from . import gamedata as G
            from . import species as SP
            repo = getattr(self, 'repo_root', None) or REPO_ROOT
            eids = [e['_eid'] for e in self.quest_enemy_rows()]
            # S105 (P3.9b): the project's new species (custom.species) and its
            # enemy ids by name (encounter pools may name a project enemy)
            self._gamedata = G.Gamedata(
                self.data.get('gamedata') or {}, repo, eids,
                new_species=SP.basics(self),
                enemy_ids={k: e['_eid'] for k, e in self.quest_enemies.items()})
        return self._gamedata

    def new_species_ids(self):
        """Ids of this project's custom.species (S105; species.py)."""
        return {s.get('id') for s in (self.custom.get('species') or [])
                if isinstance(s, dict)}

    def quest_enemy_rows(self):
        """Enemies in EID order for the bank $6B emitter."""
        return sorted(self.quest_enemies.values(), key=lambda e: e['_eid'])

    def enemy_ref(self, ref, ctx):
        """An enemy reference -> EID: a progression.enemies id, or a number
        (any vanilla / project EID)."""
        if isinstance(ref, str) and ref in self.quest_enemies:
            return self.quest_enemies[ref]['_eid']
        try:
            v = F.val(ref)
        except (TypeError, ValueError):
            v = None
        if not isinstance(v, int) or isinstance(v, bool):
            raise ProjectError(f"{ctx}: enemy {ref!r} is neither a "
                               "progression.enemies id nor an EID number")
        return v

    def enemy_redirects(self):
        """[(fight EID, join EID, name)] from progression.enemies[].join_as
        (S101: the boss's weaker 'join version'), in EID order."""
        out = []
        for e in self.quest_enemy_rows():
            ja = e.get('join_as')
            if ja is None or ja == e.get('id'):
                continue
            out.append((e['_eid'], self.enemy_ref(ja, f"progression.enemies[{e['id']}].join_as"),
                        f"{e['id']} joins as {ja}"))
        return out

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
                # S129 (ROADMAP P3.14c; DOC_AUDIT S124): the S70 names lowered to
                # ops $48 / $49 = face down / left (S101) — the NPC only turned.
                # Now the instant hide / show of the Vanish step (npc_write n, 0
                # type byte := $40 hidden / $00 shown; measured S123)
                ops.append(['op', 'npc_write', int(a['npc_hide']), 0, '0x0040'])
            elif 'npc_show' in a:
                ops.append(['op', 'npc_write', int(a['npc_show']), 0, 0])
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
            ops.append(['op', 'set_flag', self.resolve_flag_write(f, ctx)])
        for f in b.get('clear') or []:
            ops.append(['op', 'clear_flag', self.resolve_flag_write(f, ctx)])
        mv = b.get('move')
        if mv and mv.get('dest') == 'hub':
            # S125: home — the project's hub (custom.hub), or the Castle
            ops += self.hub_warp_ops('home', ctx + '.move')
        elif mv:
            dest = str(mv.get('dest', ''))
            if ':' not in dest:
                raise ProjectError(f"{ctx}: move.dest must be room:$xx or vanilla:$xx")
            mid = F.val(dest.split(':', 1)[1])
            k, x, y = int(mv.get('screen', 0)), int(mv['x']), int(mv['y'])
            if not (0 <= k <= 15 and 0 <= x <= 9 and 0 <= y <= 7):
                raise ProjectError(f"{ctx}: move to screen {k} cell ({x},{y}) outside "
                                   "the 4x4 grid / 10x8 cells")
            # MapTransitionFull ($0F, bank $04 ScriptCmd0F_MapTransition): word 1 = mapID
            # (high byte = gate flag 0), words 2/3 = ABSOLUTE pixel x/y of the
            # cell centre (screen col*10 / row*8 cells + cell*16 + 8)
            px = ((k % 4) * 10 + x) * 16 + 8
            py = ((k // 4) * 8 + y) * 16 + 8
            ops.append(['op', 'map_transition', f'0x{mid:04X}', f'0x{px:04X}', f'0x{py:04X}'])
        return ops

    # ------------------------------------------- conversation steps (S101)
    # talk: {"steps": [STEP...], "on_arrival": bool, "screen": k}
    # STEP (one kind per dict):
    #   {"say": dlg}
    #   {"ask": dlg (choice), "yes": [STEP..], "no": [STEP..]}   (branches rejoin)
    #   {"if": [{"flag": f, "is": "set"|"clear"}...], "then": [..], "else": [..]}
    #   {"set": [f..]} / {"clear": [f..]}
    #   {"battle": {"enemies": [ref, ref?, ref?]}}  — the steps AFTER it run
    #        only on a WIN (engine guarantee, SIDEQUEST_MAP S68); a loss sends
    #        the player to the castle (engine)
    #   {"move": {dest, screen, x, y}}              — $0F warp
    #   {"helper": {"dest", "screen", "x", "y", "say": dlg?, "land": {x, y},
    #               "sprite": id?}}                 — the vanilla boss exit:
    #        the helper NPC (Watabou's sprite $21 by default) flies in, spins,
    #        speaks, and fades the player to dest ($3B) — PROJECT_COMPILER §2.18
    #   {"end": true}
    # Text in FIELD context (a room-arrival script, or anything after a battle
    # or the helper's flight) gets its own init_dialog (the S70 protocol).
    STEP_KINDS = ('say', 'ask', 'if', 'set', 'clear', 'battle', 'move', 'helper', 'vanish',
                  'heal', 'end',
                  # S129 (ROADMAP P3.14b / c): story commands + the story spine
                  'give_item', 'give_monster', 'take_item', 'gold', 'refresh', 'by_progress')
    HELPER_SPRITE = 0x39                # Warubou — the darker Watabou (user S101 r2: the
                                        # romhack's helper; vanilla boss exits use $21 Watabou)
    HELPER_FLY = 0x16                   # $1C anim: fly to ($D8E3, $D8E4)
    HELPER_HOP = 0x04

    @staticmethod
    def step_kind(st):
        ks = [k for k in Project.STEP_KINDS if k in st]
        return ks[0] if len(ks) == 1 else None

    def _terms_ops(self, terms, fail_label, ctx):
        ops = []
        for t in terms or []:
            is_ = t.get('is', 'set')
            if is_ not in ('set', 'clear'):
                raise ProjectError(f"{ctx}: term 'is' must be set/clear")
            idx = self.resolve_flag_ref(t.get('flag'), ctx)
            ops.append(['op', 'if_flag_clear' if is_ == 'set' else 'if_flag_set',
                        idx, '@' + fail_label])
        return ops

    def _move_words(self, mv, ctx):
        dest = str(mv.get('dest', ''))
        if ':' not in dest:
            raise ProjectError(f"{ctx}: dest must be room:$xx or vanilla:$xx")
        mid = F.val(dest.split(':', 1)[1])
        k, x, y = int(mv.get('screen', 0)), int(mv['x']), int(mv['y'])
        if not (0 <= k <= 15 and 0 <= x <= 9 and 0 <= y <= 7):
            raise ProjectError(f"{ctx}: move to screen {k} cell ({x},{y}) outside "
                               "the 4x4 grid / 10x8 cells")
        problem = self.move_screen_problem(dest, mid, k)
        if problem:
            raise ProjectError(f"{ctx}: {problem}")
        px = ((k % 4) * 10 + x) * 16 + 8
        py = ((k // 4) * 8 + y) * 16 + 8
        return f'0x{mid:04X}', f'0x{px:04X}', f'0x{py:04X}'

    def move_screen_problem(self, dest, mid, k):
        """S121 r3 (user: "I tried redirecting to SBOSS and game crashes"): a move to a
        screen the room does not have warps into nothing — PyBoy: the roots scene sent
        to SBOSS ($70, screens 0 / 4) at GreatTree's screen 12 crashed the game (PC in
        WRAM). -> a sentence, or None."""
        kind = str(dest).split(':', 1)[0]
        if kind == 'room':
            room = next((r for r in self.custom.get('rooms') or []
                         if r.get('mapID') is not None and F.val(r['mapID']) == mid), None)
            if room is None:
                return f"move to room ${mid:02X}: no room of this project has that map id"
            keys = sorted(int(x) for x in (room.get('screens') or {}))
            if k not in keys:
                return (f"move to {room.get('name') or room['id']} screen {k}: that room has "
                        f"no screen {k} (its screens: {', '.join(map(str, keys)) or 'none'}) — "
                        "the game would crash there")
            return None
        if kind == 'vanilla':
            screens = vanilla_screens().get(mid)
            if screens is not None and k not in screens:
                return (f"move to game room ${mid:02X} screen {k}: the game has no screen {k} "
                        f"there (its screens: {', '.join(map(str, screens))}) — the game "
                        "would crash there")
        return None

    def _lower_steps(self, steps, ctx, lab, field, helper_idx=None):
        """-> (ops, field_after). lab = [counter] for unique local labels."""
        ops = []
        if not isinstance(steps, list):
            raise ProjectError(f"{ctx}: steps must be a list")
        for i, st in enumerate(steps):
            c = f"{ctx}[{i}]"
            if not isinstance(st, dict):
                raise ProjectError(f"{c}: a step is an object")
            kind = self.step_kind(st)
            if kind is None:
                raise ProjectError(f"{c}: a step needs exactly one of {self.STEP_KINDS}")
            if kind == 'say':
                if field:
                    ops.append(['op', 'init_dialog'])
                ops.append(['text', st['say']])
            elif kind == 'ask':
                lab[0] += 1
                n = lab[0]
                if field:
                    ops.append(['op', 'init_dialog'])
                ops.append(['text', st['ask']])
                ops.append(['op', 'check_and_branch', '0xC83C', '0x0001', f'@no{n}'])
                y_ops, fy = self._lower_steps(st.get('yes') or [], c + '.yes', lab, False, helper_idx)
                n_ops, fn = self._lower_steps(st.get('no') or [], c + '.no', lab, False, helper_idx)
                ops += y_ops + [['op', 'goto', f'@join{n}'], f'label:no{n}'] + n_ops \
                    + [f'label:join{n}']
                field = fy or fn
            elif kind == 'if':
                lab[0] += 1
                n = lab[0]
                ops += self._terms_ops(st['if'], f'else{n}', c)
                t_ops, ft = self._lower_steps(st.get('then') or [], c + '.then', lab, field, helper_idx)
                e_ops, fe = self._lower_steps(st.get('else') or [], c + '.else', lab, field, helper_idx)
                ops += t_ops + [['op', 'goto', f'@fi{n}'], f'label:else{n}'] + e_ops \
                    + [f'label:fi{n}']
                field = ft or fe
            elif kind in ('set', 'clear'):
                fl = st[kind] if isinstance(st[kind], list) else [st[kind]]
                for f in fl:
                    ops.append(['op', 'set_flag' if kind == 'set' else 'clear_flag',
                                self.resolve_flag_write(f, c)])
            elif kind in ('give_item', 'give_monster'):
                # S129: the cutscene's Give step in conversations — the bag / farm
                # full test first; `got` / `full` = dialogue ids (optional). An
                # item x n (n > 1) = story command 3 (all of them or none, the
                # answer in $D8E1 — op $24 yields: texts after it open the box)
                g = st[kind] or {}
                lab[0] += 1
                n = lab[0]
                cnt = int(g.get('count', 1) or 1)
                if kind == 'give_monster':
                    ops.append(['op', 'check_storage_full', f'@gfull{n}'])
                    ops.append(['op', 'add_monster', self.enemy_ref(g.get('enemy'), c)])
                elif cnt == 1:
                    item = F.val(g.get('item'))
                    if not isinstance(item, int) or not 1 <= item <= 43:
                        raise ProjectError(f"{c}: give_item needs an item 1-43")
                    ops.append(['op', 'check_inv_full', f'@gfull{n}'])
                    ops.append(['op', 'give_item', item])
                else:
                    w = self.story_command('give_item', {'item': g.get('item'), 'count': cnt}, c)
                    ops.append(['op', '0x24', f'0x{w:04X}'])
                    ops.append(['op', 'check_and_branch', '0xD8E1', '0x0000', f'@gfull{n}'])
                    field = True
                if g.get('got'):
                    if field:
                        ops.append(['op', 'init_dialog'])
                    ops.append(['text', g['got']])
                ops += [['op', 'goto', f'@gdone{n}'], f'label:gfull{n}']
                if g.get('full'):
                    if field:
                        ops.append(['op', 'init_dialog'])
                    ops.append(['text', g['full']])
                ops.append(f'label:gdone{n}')
            elif kind == 'take_item':
                g = st['take_item'] or {}
                w = self.story_command('take_item', {'item': g.get('item'),
                                                     'count': g.get('count', 1)}, c)
                ops.append(['op', '0x24', f'0x{w:04X}'])
                field = True                       # op $24 yields (BANK04 "Breeding")
            elif kind == 'gold':
                g = st['gold'] or {}
                if ('give' in g) == ('take' in g):
                    raise ProjectError(f"{c}: gold needs give OR take (an amount)")
                w = self.story_command('give_gold' if 'give' in g else 'take_gold',
                                       {'amount': g.get('give', g.get('take'))}, c)
                ops.append(['op', '0x24', f'0x{w:04X}'])
                field = True
            elif kind == 'refresh':
                # S129: op $26 reload_room — the room loads again where the player
                # stands (state rules re-picked: a door unlocked this moment opens);
                # PyBoy S129: $C88F++ = bank $0B room entry 0 + the state rules
                ops.append(['op', '0x26'])
                field = True
            elif kind == 'by_progress':
                # S129 (P3.14c): the words by the story's progress — the LATEST
                # milestone reached first (the vanilla highest-milestone-first
                # ladder); `else` = before the first one
                from . import story as _ST
                lad = st['by_progress'] or []
                if not isinstance(lad, list):
                    raise ProjectError(f"{c}: by_progress is a list of "
                                       "{milestone, steps}")
                order = [f for f, _n in _ST.milestones(self.custom)]
                try:
                    lad = sorted(lad, key=lambda e: -order.index(e.get('milestone')))
                except ValueError:
                    bad = [e.get('milestone') for e in lad if e.get('milestone') not in order]
                    raise ProjectError(f"{c}: {bad} not milestones of custom.story")
                lab[0] += 1
                n = lab[0]
                f_any = False
                for j, e in enumerate(lad):
                    ref = self.check_flag(f"story:reached:{e.get('milestone')}", c)
                    ops.append(['op', 'if_flag_clear', ref, f'@bp{n}_{j}'])
                    e_ops, fe = self._lower_steps(e.get('steps') or [], f"{c}[{j}]", lab,
                                                  field, helper_idx)
                    ops += e_ops + [['op', 'goto', f'@bpd{n}'], f'label:bp{n}_{j}']
                    f_any = f_any or fe
                e_ops, fe = self._lower_steps(st.get('else') or [], f"{c}.else", lab, field,
                                              helper_idx)
                ops += e_ops + [f'label:bpd{n}']
                field = field or f_any or fe
            elif kind == 'battle':
                b = st['battle'] or {}
                ens = b.get('enemies') or []
                if not 1 <= len(ens) <= 3:
                    raise ProjectError(f"{c}: a battle has 1-3 enemies")
                eids = [self.enemy_ref(e, c) for e in ens]
                if len(eids) == 1:
                    ops.append(['op', 'trigger_battle3', eids[0]])
                else:
                    for j, e in enumerate(eids):
                        ops.append(['op', 'write_ram2', f'0x{0xDA03 + 2 * j:04X}', e])
                    ops.append(['op', 'write_ram', '0xDA02', len(eids) - 1])
                    ops.append(['op', 'boss_battle'])
                field = True
            elif kind == 'move':
                if (st['move'] or {}).get('dest') == 'hub':      # S125: home
                    ops += self.hub_warp_ops('home', c)
                else:
                    ops.append(['op', 'map_transition'] + list(self._move_words(st['move'], c)))
            elif kind == 'heal':
                # S125: op $27 — every monster's HP / MP back to full, status
                # cleared (bank $01 IteratePartySlots20 over the 20 slots; measured)
                ops.append(['op', 'refresh_party'])
            elif kind == 'helper':
                h = st['helper'] or {}
                if helper_idx is None:
                    raise ProjectError(f"{c}: the helper exit needs the room context "
                                       "(the script is not bound to any room screen)")
                H = helper_idx
                land = h.get('land')
                lab[0] += 1
                n = lab[0]
                spin = [['op', 'long_delay', 4], ['op', 'face_up', H],
                        ['op', 'long_delay', 4], ['op', 'face_left', H],
                        ['op', 'long_delay', 4], ['op', 'face_down', H],
                        ['op', 'long_delay', 4]]
                if field is False:
                    ops.append(['op', 'close_text'])
                ops += [['op', 'delay', 8],
                        ['op', 'npc_write', H, 0, 0]]                 # reveal
                if isinstance(land, dict):
                    # a fixed landing cell (screen-local); faces right
                    lx, ly = int(land.get('x', 4)), int(land.get('y', 3))
                    ops += self._helper_fixed(H, n, lx, ly)
                    face = lambda tag: [['op', 'face_right', H]]   # noqa: E731
                else:
                    # S101 r2 (user: "lands left of player … ideally always"):
                    # beside the player at RUN time — the player's absolute
                    # tile ($FF97/$FF98) is matched against every value the
                    # screens that run this script allow; left of the player
                    # facing right, or right of them facing left on column 0
                    ld, face = self._helper_beside_player(H, n)
                    ops += ld
                ops += [['op', 'write_ram2', '0xD8E3',
                         f'0x{(self.HELPER_FLY_CURVE << 8) | self.HELPER_FLY_TILES:04X}'],
                        ['op', 'trigger_anim', f'0x{(self.HELPER_FLY << 8) | H:04X}'],
                        ['op', 'wait_movement']] + spin + face('a') + [['op', 'long_delay', 4]]
                if h.get('say'):
                    ops += [['op', 'init_dialog'], ['text', h['say']], ['op', 'close_text']]
                ops += [['op', 'trigger_anim', f'0x{(self.HELPER_HOP << 8) | H:04X}'],
                        ['op', 'wait_movement']] + spin + face('b') + [['op', 'long_delay', 6]]
                ev = h.get('castle') or 'none'
                cev = []
                if ev == 'heal':            # the priest's blessing + heal (S101 r3)
                    cev.append(['op', 'write_ram', '0xD92B', 6])
                elif ev == 'king':          # the King's speech for one gate's boss
                    cev += [['op', 'write_ram', '0xD9E3', int(F.val(h.get('king_speech', 0x31)))],
                            ['op', 'write_ram', '0xD92B', 7]]
                if h.get('dest') == 'hub':
                    # S125: home — the Castle branch keeps the chosen Castle event
                    ops += self.hub_warp_ops('home', c, op='warp_fade', castle_pre=cev)
                else:
                    ops += cev
                    ops.append(['op', 'warp_fade'] + list(self._move_words(h, c)))
                field = True
            elif kind == 'vanish':
                # S123: the NPCs that run this conversation on the current screen
                # leave at once — the game's own "vanish (flicker out)" program
                # ($1C $0Dnn, script_ops.PROGRAMS) or an instant hide (type bit 6).
                # Their slots are known once the rooms resolve (_vanish_slots).
                how = (st['vanish'] or {}).get('how', 'flicker')
                if how not in ('flicker', 'instant'):
                    raise ProjectError(f"{c}: vanish how must be flicker / instant")
                places = self._vanish_places.get(self._lowering_sid)
                if places is None:
                    raise ProjectError(f"{c}: Vanish needs the conversation to belong to "
                                       "an NPC (no NPC runs this script)")
                if field is False:
                    ops.append(['op', 'close_text'])
                lab[0] += 1
                n = lab[0]
                keys = sorted(places)
                for k in keys:
                    ops.append(['op', 'branch_screen', k, f'@vs{n}_{k}'])
                ops.append(['op', 'goto', f'@vsd{n}'])
                for k in keys:
                    ops.append(f'label:vs{n}_{k}')
                    for slot in places[k]:
                        if how == 'flicker':
                            ops.append(['op', 'trigger_anim', f'0x{(0x0D << 8) | slot:04X}'])
                        else:
                            ops.append(['op', 'npc_write', slot, 0, '0x0040'])
                    if how == 'flicker':
                        ops.append(['op', 'wait_movement'])
                    ops.append(['op', 'goto', f'@vsd{n}'])
                ops.append(f'label:vsd{n}')
                field = True
            elif kind == 'end':
                ops.append(['end'])
        return ops, field

    def _vanish_scripts(self):
        """Ids of steps-form scripts with a Vanish step (S123)."""
        out = set()

        def walk(steps):
            for st in steps or []:
                if not isinstance(st, dict):
                    continue
                if 'vanish' in st:
                    return True
                if any(walk(st.get(k)) for k in ('yes', 'no', 'then', 'else')):
                    return True
                if any(walk(e.get('steps')) for e in st.get('by_progress') or []
                       if isinstance(e, dict)):                       # S129
                    return True
            return False
        for sc in self.custom.get('scripts', []):
            t = sc.get('talk') or {}
            if t.get('steps') and walk(t['steps']):
                out.add(sc['id'])
        return out

    def _resolve_vanish_slots(self):
        """S123: {script id: {screen: [actor numbers]}} — the 1-based NPC slots
        (spots take none; the emitted order = the authored NPC order) of every
        NPC that runs a Vanish conversation. The same NPCs must sit in the same
        slots in every state of a screen (else the step could hide another NPC)."""
        want = self._vanish_scripts()
        out = {}
        if not want:
            return out
        for r in self.rooms:
            if r.get('placeholder'):
                continue
            by_idx = {int(k): v for k, v in (r.get('scripts') or {}).items()}
            for k, scr in self.room_screens(r).items():
                per_state = []
                for st in self.screen_states(scr):
                    slots = {}
                    n = 0
                    for e in st.get('npcs', []) or []:
                        if e.get('kind') == 'npc' or (e.get('kind') == 'raw' and
                                                      F.val(e['bytes'][0]) < 0x80):
                            n += 1
                            sid = e.get('script')
                            if isinstance(sid, int):
                                sid = by_idx.get(sid)
                            if sid in want:
                                slots.setdefault(sid, []).append(n)
                    per_state.append(slots)
                for sid in want:
                    seen = [tuple(ps.get(sid, ())) for ps in per_state]
                    used = [x for x in seen if x]
                    if not used:
                        continue
                    if len(set(used)) > 1:
                        raise ProjectError(
                            f"script {sid}: its NPCs sit in different NPC slots in the "
                            f"states of room {r.get('id')} screen {k} — Vanish would hide "
                            "another NPC; keep them in the same list position in every state")
                    out.setdefault(sid, {})[int(k)] = list(used[0])
        return out

    PLAYER_TX, PLAYER_TY = 0xFF97, 0xFF98     # HRAM: player tile, absolute
    # The fly program ($1C $16NN, measured S101 r2): each frame the NPC moves
    # +2 px right and down along a curve; it runs D8E3*8 frames and D8E4
    # (1-3, else 4) picks the curve. D8E3 = 3, D8E4 = 3: +48 px right,
    # +43 px down. So the compiler places the hidden helper at (land − 48,
    # land − 43) in PIXELS (slot +$18/+$1A, absolute 16-bit) and it lands on
    # the exact cell, coming in from the upper left.
    HELPER_FLY_DX, HELPER_FLY_DY, HELPER_FLY_TILES, HELPER_FLY_CURVE = 48, 43, 3, 3

    def _helper_start_ops(self, H, ax, ay):
        """ops placing helper NPC H so that it lands on absolute tile (ax, ay)."""
        base = 0xD7D2 + 32 * (H - 1)
        px = (ax * 16 + 8 - self.HELPER_FLY_DX) & 0xFFFF
        py = (ay * 16 + 8 - self.HELPER_FLY_DY) & 0xFFFF
        return [['op', 'write_ram2', f'0x{base + 0x18:04X}', f'0x{px:04X}'],
                ['op', 'write_ram2', f'0x{base + 0x1A:04X}', f'0x{py:04X}']]

    def _helper_screens_of(self):
        return self._helper_screens.get(self._lowering_sid) or list(range(16))

    def _helper_fixed(self, H, n, lx, ly):
        """A fixed screen-local landing cell on every screen running the script."""
        keys = self._helper_screens_of()
        ops = []
        for k in keys:
            ops.append(['op', 'branch_screen', k, f'@hs{n}_{k}'])
        ops.append(['op', 'goto', f'@hsd{n}'])
        for k in keys:
            ops.append(f'label:hs{n}_{k}')
            ops += self._helper_start_ops(H, (k % 4) * 10 + lx, (k // 4) * 8 + ly)
            ops.append(['op', 'goto', f'@hsd{n}'])
        ops.append(f'label:hsd{n}')
        return ops

    def _helper_beside_player(self, H, n):
        """-> (ops placing the helper so it lands LEFT of the player — or
        RIGHT on a screen's column 0 —, final-facing op factory). One byte
        compare per possible player column / row of the screens that run the
        script ($15 check_and_branch: `ld a,[hl] / cp c`)."""
        keys = self._helper_screens_of()
        cols = sorted({k % 4 for k in keys})
        rows = sorted({k // 4 for k in keys})
        base = 0xD7D2 + 32 * (H - 1)
        ops = []
        for c in cols:
            for lx in range(10):
                ops.append(['op', 'check_and_branch', f'0x{self.PLAYER_TX:04X}',
                            c * 10 + lx, f'@hx{n}_{c * 10 + lx}'])
        ops.append(['op', 'goto', f'@hxd{n}'])
        for c in cols:
            for lx in range(10):
                ax = c * 10 + lx
                land = ax - 1 if lx else ax + 1
                px = (land * 16 + 8 - self.HELPER_FLY_DX) & 0xFFFF
                ops += [f'label:hx{n}_{ax}',
                        ['op', 'write_ram2', f'0x{base + 0x18:04X}', f'0x{px:04X}'],
                        ['op', 'goto', f'@hxd{n}']]
        ops.append(f'label:hxd{n}')
        for r in rows:
            for ly in range(8):
                ops.append(['op', 'check_and_branch', f'0x{self.PLAYER_TY:04X}',
                            r * 8 + ly, f'@hy{n}_{r * 8 + ly}'])
        ops.append(['op', 'goto', f'@hyd{n}'])
        for r in rows:
            for ly in range(8):
                ay = r * 8 + ly
                py = (ay * 16 + 8 - self.HELPER_FLY_DY) & 0xFFFF
                ops += [f'label:hy{n}_{ay}',
                        ['op', 'write_ram2', f'0x{base + 0x1A:04X}', f'0x{py:04X}'],
                        ['op', 'goto', f'@hyd{n}']]
        ops.append(f'label:hyd{n}')

        def face(tag):
            out = []
            for c in cols:      # player on a screen's column 0: helper is on their RIGHT
                out.append(['op', 'check_and_branch', f'0x{self.PLAYER_TX:04X}', c * 10,
                            f'@hfl{n}{tag}'])
            return out + [['op', 'face_right', H], ['op', 'goto', f'@hfd{n}{tag}'],
                          f'label:hfl{n}{tag}', ['op', 'face_left', H], f'label:hfd{n}{tag}']
        return ops, face

    def _helper_scripts(self):
        """{script id: helper sprite} for talk scripts whose steps use the helper."""
        out = {}

        def walk(steps):
            for st in steps or []:
                if not isinstance(st, dict):
                    continue
                if 'helper' in st:
                    return (st['helper'] or {}).get('sprite', self.HELPER_SPRITE)
                for key in ('yes', 'no', 'then', 'else'):
                    got = walk(st.get(key))
                    if got is not None:
                        return got
                for e in st.get('by_progress') or []:                 # S129
                    got = walk(e.get('steps')) if isinstance(e, dict) else None
                    if got is not None:
                        return got
            return None
        for sc in self.custom.get('scripts', []):
            t = sc.get('talk') or {}
            if t.get('steps'):
                sp = walk(t['steps'])
                if sp is not None:
                    out[sc['id']] = F.val(sp)
        return out

    def _place_helpers(self):
        """S101: every screen that fires a helper-exit script gets a hidden
        helper NPC at one FIXED slot per script (the script names its NPC by
        index, so every state of every such screen puts it at the same slot:
        states with fewer NPCs are padded with hidden dummies). Returns
        {script id: npc index (1-based, spots not counted)}."""
        helpers = self._helper_scripts()
        if not helpers:
            return {}
        uses = {sid: [] for sid in helpers}          # sid -> [(room, k)]
        for r in self.rooms:
            if r.get('placeholder'):
                continue
            table = r.get('scripts') or {}
            by_idx = {int(k): v for k, v in table.items()}
            for k, scr in self.room_screens(r).items():
                for st in self.screen_states(scr):
                    for n in st.get('npcs', []) or []:
                        sid = n.get('script')
                        if isinstance(sid, int):
                            sid = by_idx.get(sid)
                        if sid in uses and (r, k) not in uses[sid]:
                            uses[sid].append((r, k))
            ent = table.get('0')
            if ent in uses:
                t = next((sc for sc in self.custom.get('scripts', [])
                          if sc.get('id') == ent), {}).get('talk') or {}
                ks = [int(t['screen'])] if t.get('screen') is not None \
                    else list(self.room_screens(r))
                for k in ks:
                    if (r, k) not in uses[ent]:
                        uses[ent].append((r, k))

        def real_npcs(st):
            return [n for n in st.get('npcs', []) or []
                    if n.get('kind') == 'npc' or (n.get('kind') == 'raw' and
                                                 F.val(n['bytes'][0]) < 0x80)]
        out = {}
        for sid, places in uses.items():
            if not places:
                continue
            H = 1 + max(len(real_npcs(st)) for r, k in places
                        for st in self.screen_states(self.room_screens(r)[k]))
            if H > 8:
                raise ProjectError(
                    f"script {sid}: the helper exit needs an NPC slot but a screen "
                    "using it already has 8 NPCs (the engine cap)")
            for r, k in places:
                scr = self.room_screens(r)[k]
                sts = scr.get('states')
                targets = sts if sts else [scr]
                for st in targets:
                    lst = st.setdefault('npcs', [])
                    while len(real_npcs(st)) < H - 1:
                        lst.append({'kind': 'npc', 'sprite': '0xFF', 'x': 0, 'y': 0,
                                    'hidden': True, 'script': 'none',
                                    'comment': 'hidden pad (keeps the helper slot fixed)'})
                    lst.append({'kind': 'npc', 'sprite': helpers[sid], 'x': 0, 'y': 0,
                                'hidden': True, 'facing': 'right', 'script': 'none',
                                'comment': f'helper for {sid} (revealed by its exit)'})
            out[sid] = H
            self._helper_screens[sid] = sorted({int(k) for _r, k in places})
        return out

    def _lower_talk_scripts(self, helper_idx=None):
        helper_idx = helper_idx or {}
        for s in self.custom.get('scripts', []):
            t = s.get('talk')
            if t is None or s.get('_talk_lowered'):
                continue
            ctx = f"scripts[{s.get('id')}].talk"
            if 'ops' in s:
                raise ProjectError(f"{ctx}: a script has either 'talk' or 'ops', not both")
            if 'steps' in t:
                unknown = set(t) - {'steps', 'on_arrival', 'screen', 'comment'}
                if unknown:
                    raise ProjectError(f"{ctx}: unknown keys {sorted(unknown)}")
                if s['id'] in self._helper_scripts() and s['id'] not in helper_idx:
                    continue                 # lowered after rooms resolve (_place_helpers)
                if s['id'] in self._vanish_scripts() and not self._rooms_resolved:
                    continue                 # S123: lowered after rooms resolve (slots)
                lab = [0]
                ops = []
                if t.get('screen') is not None:
                    ops += [['op', 'branch_screen', int(t['screen']), '@run'], ['end'],
                            'label:run']
                self._lowering_sid = s['id']
                body, _f = self._lower_steps(t['steps'], ctx + '.steps', lab,
                                             bool(t.get('on_arrival')),
                                             helper_idx.get(s['id']))
                self._lowering_sid = None
                s['ops'] = ops + body + [['end']]
                s['_talk_lowered'] = True
                continue
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

    def _lower_shop_scripts(self):
        """S117 (P3.13c, PROJECT_COMPILER §2.32): a shopkeeper's script
        {"shop": {"shop": <list id>, "text": <greeting dialogue, optional>}} ->
        the vanilla shopkeeper's four words (text $0680 / $FF04 $0000 $0680 /
        text $0682 / end) with its own greeting and `write_ram wShopID,
        list+1` right before the opcode (bank $77 ShopFill reads it)."""
        from . import shops as SH
        for s in self.custom.get('scripts', []):
            sp = s.get('shop')
            if sp is None or s.get('_shop_lowered'):
                continue
            ctx = f"scripts[{s.get('id')}].shop"
            if 'ops' in s or 'talk' in s:
                raise ProjectError(f"{ctx}: a shop script has no 'ops' / 'talk'")
            if not isinstance(sp, dict) or not sp.get('shop'):
                raise ProjectError(f"{ctx}: {{\"shop\": <shop id>, \"text\": <greeting>}}")
            unknown = set(sp) - {'shop', 'text', 'comment', 'lines'}   # S126: lines = a shop line set
            if unknown:
                raise ProjectError(f"{ctx}: unknown keys {sorted(unknown)}")
            try:
                n = SH.shop_id_byte(self, sp['shop'], ctx)
            except SH.ShopError as e:
                raise ProjectError(str(e))
            s['ops'] = [['text', sp.get('text') or SH.SHOP_TEXT_BASE],
                        ['op', 'write_ram', 'wShopID', n],
                        ['op', '0x04', 0, SH.SHOP_TEXT_BASE],   # the shop opcode
                        ['text', SH.SHOP_TEXT_BASE + 2],
                        ['end']]
            s['_shop_lowered'] = True

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
        if hi > CUSTOM_MID_MAX:
            # S133 capacity audit: bank $60 CustomPtrChase / CustomStateRules /
            # CustomMonsterCast and bank $17 CustomAttrCheck (+ its two callers)
            # index their per-room tables with `sub $6B / add a / add l` — an
            # 8-bit doubling that drops the carry, so a room past $EA reads
            # ANOTHER room's data (silently; nothing failed before S133).
            # Places beyond 128 = ROADMAP ARC CAP (regions + place banks).
            raise ProjectError(
                f"custom mapID {F.hexb(hi)} is past {F.hexb(CUSTOM_MID_MAX)}: "
                "the engine's per-room lookups double the index in 8 bits, so "
                f"at most {CUSTOM_MID_MAX - 0x6B + 1} custom rooms ($6B-$EA) "
                "work today (CROSSBANK_ROOMS 'Custom-side arithmetic "
                "ceilings'; more places = ROADMAP ARC CAP)")
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

    def room_by_id(self, rid):
        for r in self.rooms:
            if r.get('id') == rid:
                return r
        return None

    # ------------------------------------------------- gates (S100, P3.7b)
    def _normalize_stairs(self):
        """`{"x", "y", "stairs": "down"}` exit rows (the editor's Stairs
        down object) get the fixed descent bytes; explicit bytes must agree."""
        from . import gates as G
        for r in self.rooms:
            for k, scr in self.room_screens(r).items():
                for st in self.screen_states(scr):
                    for e in st.get('exits', []) or []:
                        if e.get('stairs') is None:
                            continue
                        if e['stairs'] != 'down':
                            raise ProjectError(
                                f"room {r.get('id')} screen {k}: stairs must be "
                                f"'down' (got {e['stairs']!r})")
                        for key, v in G.STAIRS_DOWN_FIELDS.items():
                            if key not in e:
                                e[key] = v
                            elif F.val(e[key]) != F.val(v):
                                raise ProjectError(
                                    f"room {r.get('id')} screen {k}: stairs-down "
                                    f"exit ({e.get('x')},{e.get('y')}) has {key}="
                                    f"{e[key]!r}; a stairs-down row is always "
                                    f"{G.STAIRS_DOWN_FIELDS}")

    def gate_insert_rows(self):
        """custom.gate_inserts[] (S100, ROADMAP P3.7b; PROJECT_COMPILER
        §2.16) resolved, in list order:
            {"room": "<custom room id>", "gate": 0-31,
             "floors": [first, last] | [n] | n | "all",   # game numbering
             "chance": 1-100, "when": [flag terms], "once_per_dive": bool,
             "comment": "..."}
        -> [{index, room_id, mapID, gate, first, last, chance, once_bit,
             px, py, terms[(idx, must_clear)], comment}]. Arrival pixels come
        from the room's `gate_arrival` {screen, x, y}."""
        if self._gate_rows is not None:
            return self._gate_rows
        from . import gates as G
        rows, once_next = [], {}
        for i, ru in enumerate(self.custom.get('gate_inserts') or []):
            c = f"custom.gate_inserts[{i}]"
            unknown = set(ru) - {'room', 'gate', 'floors', 'chance', 'when',
                                 'once_per_dive', 'comment', 'chance_by_level'}
            if unknown:
                raise ProjectError(f"{c}: unknown keys {sorted(unknown)}")
            room = self.room_by_id(ru.get('room'))
            if room is None or room.get('placeholder'):
                raise ProjectError(f"{c}: room {ru.get('room')!r} is not a "
                                   "custom room of this project")
            any_gate = ru.get('gate') == 'any'      # S127: every gate (GATE_ANY)
            gate = 0xFE if any_gate else int(F.val(ru.get('gate', -1)))
            if not any_gate and not G.gate_exists(self.custom, gate):
                raise ProjectError(f"{c}: gate must be 0-31, \"any\" or one of this "
                                   f"project's new gates (got {ru.get('gate')!r})")
            if any_gate:
                # S127: any gate — floor 2 (or the given first floor) up to the floor
                # before each gate's boss (the boss floor is decided before the rule)
                fl = ru.get('floors', 'all')
                first = 2 if fl == 'all' else int(F.val(fl[0] if isinstance(fl, list) else fl))
                last, floors, minf = 256, 0, 2
                if first < 2:
                    raise ProjectError(f"{c}: every gate: from floor 2 (the first floor "
                                       "stays the gate's own)")
            else:
                floors = G.gate_floor_count(self.custom, gate, self.repo_root or self.root)
                minf = G.gate_min_floor(self.custom, gate)
                try:
                    first, last = G.floor_range(ru.get('floors', 'all'), floors, minf)
                except ValueError as e:
                    raise ProjectError(f"{c}: {e}")
            if first < minf:
                raise ProjectError(f"{c}: floor {first} — custom rooms start at "
                                   f"floor {minf} (the first floor stays the gate's "
                                   "own unless the gate is marked hand-made)")
            if floors and last > floors - 1:
                raise ProjectError(
                    f"{c}: floor {last} — gate {gate} has {floors} floors and "
                    f"floor {floors} is its boss floor; the last floor a room "
                    f"can take is {floors - 1}")
            if last < first:
                raise ProjectError(f"{c}: floors run backwards ({first}-{last})")
            chance = int(F.val(ru.get('chance', 100)))
            if not 1 <= chance <= 100:
                raise ProjectError(f"{c}: chance must be 1-100 % (got {chance})")
            from . import breeders as _BR             # S127: the chance by level
            try:
                cbl = _BR.parse_chance_by_level(ru, c)
            except _BR.BreedError as ex:
                raise ProjectError(str(ex))
            chance_byte = chance
            if cbl is not None:
                chance_byte = 0x80 | _BR.scaled_chance_rows(self).index(cbl)
            terms = []
            for t in ru.get('when') or []:
                is_ = t.get('is', 'set')
                if is_ not in ('set', 'clear'):
                    raise ProjectError(f"{c}: term 'is' must be set/clear")
                terms.append((self.resolve_flag_ref(t.get('flag'), c),
                              is_ == 'clear'))
            if len(terms) > G.MAX_TERMS:
                raise ProjectError(f"{c}: {len(terms)} flag terms (max {G.MAX_TERMS})")
            once_bit = 0
            if ru.get('once_per_dive'):
                # S127: an every-gate rule takes a bit from the top (7, 6, …) in
                # every gate's dive mask; a gate's own rules take them from the
                # bottom — together at most 8 per gate
                if any_gate:
                    k = 7 - once_next.get('any', 0)
                    once_next['any'] = once_next.get('any', 0) + 1
                else:
                    k = once_next.get(gate, 0)
                    once_next[gate] = k + 1
                used = max([once_next.get(g, 0) for g in once_next if g != 'any'] + [0])
                if used + once_next.get('any', 0) > G.MAX_ONCE_PER_GATE or k < 0:
                    raise ProjectError(
                        f"{c}: more than {G.MAX_ONCE_PER_GATE} once-per-dive "
                        f"rules on one gate (every-gate rules count for each gate; "
                        "one bit each in wGateDiveMask)")
                once_bit = 1 << k
            arr = room.get('gate_arrival')
            if not arr:
                raise ProjectError(
                    f"{c}: room {room.get('id')!r} has no gate_arrival "
                    "{screen, x, y} — where the player appears when the room "
                    "is served as a gate floor")
            scr = int(arr.get('screen', 0))
            if scr not in self.room_screens(room):
                raise ProjectError(f"{c}: room {room.get('id')!r} gate_arrival "
                                   f"screen {scr} does not exist")
            if not (0 <= int(arr['x']) <= 9 and 0 <= int(arr['y']) <= 7):
                raise ProjectError(f"{c}: gate_arrival cell outside the 10x8 grid")
            px, py = G.arrival_px(scr, arr['x'], arr['y'])
            if not any_gate and G.world_settings(self.custom, gate) is not None:
                raise ProjectError(
                    f"{c}: gate {gate} is a WORLD — it has no random floors to serve "
                    "rooms on (its start room is served by the world itself; the "
                    "other rooms are reached by doors)")
            rows.append({'index': i, 'room_id': room.get('id'),
                         'mapID': F.val(room['mapID']), 'gate': gate,
                         'first': first, 'last': last, 'chance': chance,
                         'chance_byte': chance_byte, 'chance_by_level': cbl,
                         'once_bit': once_bit, 'px': px, 'py': py,
                         'terms': terms, 'comment': ru.get('comment', '')})
        # S123 (ROADMAP NG3): each world's start room = its floor 1, always
        for gid, w in sorted(self.worlds().items()):
            room = self.room_by_id(w['start_room'])
            px, py = G.arrival_px(w['start_screen'], w['start_x'], w['start_y'])
            rows.append({'index': None, 'room_id': room.get('id'),
                         'mapID': F.val(room['mapID']), 'gate': gid,
                         'first': 1, 'last': 1, 'chance': 100, 'chance_byte': 100,
                         'chance_by_level': None, 'once_bit': 0,
                         'px': px, 'py': py, 'terms': [],
                         'comment': f"world {w['name']}: the start room", 'world': gid})
        self._gate_rows = rows
        return rows

    # ------------------------------------------------ the hub (S125, P3.14d)
    # Where the game sends the player "home": after a lost battle, a party wiped
    # by floor damage, the WarpWing item / the Anchor skill's gate exit, the
    # Starry/arena final, and a script's `dest: "hub"`. custom.hub.rules[] are
    # tried in list order; the first whose flag terms all hold wins; none ->
    # the vanilla Castle. Engine side: bank $71 entry 9 HubWarp + HubTable
    # (template head), wHubReason (patches/wram.asm). PROJECT_COMPILER §2.38.
    HUB_REASONS = {'lost': 1, 'wiped': 2, 'warpwing': 3, 'final_lost': 4,
                   'home': 5, 'arena_won': 6,          # = HUB_* in patches/wram.asm
                   'continue': 7}                      # S138: bank $71 ContinueCheck
    HUB_REASON_NAMES = {
        'lost': 'lost a battle', 'wiped': 'the party fell (floor damage)',
        'warpwing': 'WarpWing / Anchor', 'final_lost': 'lost the Starry / arena final',
        'home': 'sent home by a script', 'arena_won': 'won an arena class',
        'continue': 'continued a save whose place is gone'}
    W_HUB_REASON = 0xD2EF                  # wHubReason (game.sym; test_compiler checks)
    HUB_MAX_RULES = 16
    HUB_MAX_TERMS = 8
    CASTLE_MID, CASTLE_PX, CASTLE_PY = 0x00, 0xE8, 0x58   # the vanilla warp mailbox

    @classmethod
    def hub_castle_code(cls, reason):
        """The $D92B arrival code the vanilla Castle runs: 8 = the priest after a
        loss (heal), 6 = the WarpWing blessing (heal)."""
        return 8 if reason in ('lost', 'wiped', 'final_lost') else 6

    def hub_rules(self):
        """custom.hub (S125, ROADMAP P3.14d; PROJECT_COMPILER §2.38):
            {"rules": [{"when": [flag terms], "room": "<custom room id>" | "castle",
                        "screen": k, "x": 0-9, "y": 0-7, "comment": "..."}],
             "comment": "..."}
        -> [{index, castle, room_id, mapID, screen, x, y, px, py,
             terms[(idx, must_clear)], comment}] (list order). Reads custom.rooms
        directly: the talk scripts lower before the rooms resolve."""
        if self._hub is not None:
            return self._hub
        hub = self.custom.get('hub')
        out = []
        if hub:
            if not isinstance(hub, dict):
                raise ProjectError("custom.hub: an object {\"rules\": [...]}")
            unknown = set(hub) - {'rules', 'comment', '_doc'}
            if unknown:
                raise ProjectError(f"custom.hub: unknown keys {sorted(unknown)}")
            rules = hub.get('rules') or []
            if len(rules) > self.HUB_MAX_RULES:
                raise ProjectError(f"custom.hub: {len(rules)} rules (max {self.HUB_MAX_RULES})")
            by_id = {r.get('id'): r for r in self.custom.get('rooms') or []}
            for i, ru in enumerate(rules):
                c = f"custom.hub.rules[{i}]"
                unknown = set(ru) - {'when', 'room', 'screen', 'x', 'y', 'comment'}
                if unknown:
                    raise ProjectError(f"{c}: unknown keys {sorted(unknown)}")
                terms = []
                for t in ru.get('when') or []:
                    is_ = t.get('is', 'set')
                    if is_ not in ('set', 'clear'):
                        raise ProjectError(f"{c}: term 'is' must be set/clear")
                    terms.append((self.resolve_flag_ref(t.get('flag'), c), is_ == 'clear'))
                if len(terms) > self.HUB_MAX_TERMS:
                    raise ProjectError(f"{c}: {len(terms)} flag terms (max {self.HUB_MAX_TERMS})")
                if out and not out[-1]['terms']:
                    raise ProjectError(
                        f"{c}: rule {i} has no conditions, so it always wins — "
                        "the rules after it can never be used (put the rule with no "
                        "conditions last)")
                if ru.get('room') == 'castle':
                    out.append({'index': i, 'castle': True, 'room_id': 'castle',
                                'mapID': self.CASTLE_MID, 'screen': None, 'x': None,
                                'y': None, 'px': self.CASTLE_PX, 'py': self.CASTLE_PY,
                                'terms': terms, 'comment': ru.get('comment', '')})
                    continue
                room = by_id.get(ru.get('room'))
                if room is None or room.get('placeholder') or room.get('mapID') is None:
                    raise ProjectError(f"{c}: room {ru.get('room')!r} is not a custom room "
                                       "of this project (or \"castle\")")
                k = int(ru.get('screen', 0))
                if str(k) not in {str(x) for x in (room.get('screens') or {})}:
                    raise ProjectError(f"{c}: room {room['id']!r} has no screen {k}")
                try:
                    x, y = int(ru['x']), int(ru['y'])
                except (KeyError, TypeError, ValueError):
                    raise ProjectError(f"{c}: the arrival cell x / y is required")
                if not (0 <= x <= 9 and 0 <= y <= 7):
                    raise ProjectError(f"{c}: arrival cell ({x},{y}) outside the 10x8 grid")
                px = ((k % 4) * 10 + x) * 16 + 8
                py = ((k // 4) * 8 + y) * 16 + 8
                out.append({'index': i, 'castle': False, 'room_id': room['id'],
                            'mapID': F.val(room['mapID']), 'screen': k, 'x': x, 'y': y,
                            'px': px, 'py': py, 'terms': terms,
                            'comment': ru.get('comment', '')})
        self._hub = out
        return out

    def _hub_anchor(self):
        """S125: the Anchor skill's gate exit (skill:anchor_gate_confirm, the
        WarpWing's Castle warp) goes to the hub. No hub -> the ops stay as they are."""
        if not self.hub_rules():
            return
        for sc in self.skill_scripts:
            if sc['id'] != 'skill:anchor_gate_confirm':
                continue
            ops = sc['ops']
            for i in range(len(ops) - 1):
                a, b = ops[i], ops[i + 1]
                if (isinstance(a, list) and a[:2] == ['op', 'write_ram']
                        and F.val(a[2]) == 0xD92B and isinstance(b, list)
                        and b[:2] == ['op', 'map_transition'] and F.val(b[2]) == 0):
                    sc['ops'] = ops[:i] + self.hub_warp_ops('warpwing', sc['id']) + ops[i + 2:]
                    return
            raise ProjectError("skill:anchor_gate_confirm: the Castle warp is not where "
                               "the hub expects it (editor2/core/skill_scripts.json)")

    def hub_room_ids(self):
        """The custom rooms some hub rule sends the player to."""
        return {r['room_id'] for r in self.hub_rules() if not r['castle']}

    def hub_warp_ops(self, reason, ctx, op='map_transition', castle_pre=None):
        """A script's way to the hub (S125): the rules as an if-ladder, each branch
        a terminal warp — a custom room gets wHubReason := reason first (its arrival
        scenes read it), the Castle gets its $D92B code (castle_pre replaces that
        write, e.g. the helper exit's King speech). No hub -> the Castle alone:
        byte-identical to a hand-written Castle warp."""
        if reason not in self.HUB_REASONS:
            raise ProjectError(f"{ctx}: hub reason {reason!r} — one of "
                               f"{sorted(self.HUB_REASONS)}")
        self._hub_lab += 1
        p = f'hub{self._hub_lab}'
        ops = []

        def castle():
            pre = (castle_pre if castle_pre is not None else
                   [['op', 'write_ram', '0xD92B', self.hub_castle_code(reason)]])
            return list(pre) + [['op', op, f'0x{self.CASTLE_MID:04X}',
                                 f'0x{self.CASTLE_PX:04X}', f'0x{self.CASTLE_PY:04X}']]
        rules = self.hub_rules()
        for i, ru in enumerate(rules):
            nxt = f'{p}_r{i}'
            for idx, clr in ru['terms']:
                ops.append(['op', 'if_flag_set' if clr else 'if_flag_clear', idx, '@' + nxt])
            if ru['castle']:
                ops += castle()
            else:
                ops += [['op', 'write_ram', f'0x{self.W_HUB_REASON:04X}',
                         self.HUB_REASONS[reason]],
                        ['op', op, f'0x{ru["mapID"]:04X}', f'0x{ru["px"]:04X}',
                         f'0x{ru["py"]:04X}']]
            if not ru['terms']:
                return ops                  # always taken: nothing after it runs
            ops.append(f'label:{nxt}')
        return ops + castle()

    # ------------------------------------------------ worlds (S123, NG3)
    def worlds(self):
        """custom.gates[].world resolved (PROJECT_COMPILER §2.36, gates.py
        "S123") -> {gate: {name, start_room, start_screen, start_x, start_y,
        rooms [ids, start first], saving}}. Raises ProjectError on a broken
        world (the validators report it)."""
        if getattr(self, '_worlds', None) is not None:
            return self._worlds
        from . import gates as G
        out, owner = {}, {}
        for g in self.custom.get('gates') or []:
            w = g.get('world')
            if w is None:
                continue
            gid = int(F.val(g.get('gate', -1)))
            c = f"custom.gates[gate {gid}].world"
            if not G.is_new_gate(gid):
                raise ProjectError(f"{c}: a world is a NEW gate ({G.NEW_GATE_FIRST}-"
                                   f"{G.NEW_GATE_LAST}); a game's gate keeps its mazes")
            if not isinstance(w, dict):
                raise ProjectError(f"{c}: must be an object")
            bad = set(w) - G.WORLD_KEYS
            if bad:
                raise ProjectError(f"{c}: unknown keys {sorted(bad)}")
            if g.get('floors') is not None and int(F.val(g['floors'])) != G.WORLD_FLOORS:
                raise ProjectError(f"{c}: a world has {G.WORLD_FLOORS} floors (floor 1 = "
                                   "the world; leave 'floors' out)")
            if g.get('boss') not in (None, '', 'vanilla'):
                raise ProjectError(f"{c}: a world has no boss FLOOR — its bosses are "
                                   "NPCs in its rooms (their conversations turn "
                                   f"gate:{gid} ON)")
            st = w.get('start') or {}
            sid = st.get('room')
            room = self.room_by_id(sid)
            if room is None or room.get('placeholder'):
                raise ProjectError(f"{c}: start room {sid!r} is not a custom room of "
                                   "this project")
            scr = int(F.val(st.get('screen', 0)))
            if scr not in self.room_screens(room):
                raise ProjectError(f"{c}: start screen {scr} — room {sid!r} has no such "
                                   "screen")
            x, y = int(F.val(st.get('x', -1))), int(F.val(st.get('y', -1)))
            if not (0 <= x <= 9 and 0 <= y <= 7):
                raise ProjectError(f"{c}: start cell ({x},{y}) is outside the 10x8 screen")
            rooms = [sid] + [r for r in (w.get('rooms') or []) if r != sid]
            for rid in rooms:
                rr = self.room_by_id(rid)
                if rr is None or rr.get('placeholder'):
                    raise ProjectError(f"{c}: room {rid!r} is not a custom room of this "
                                       "project")
                if rid in owner and owner[rid] != gid:
                    raise ProjectError(f"{c}: room {rid!r} is already in world "
                                       f"{owner[rid]} — a room belongs to one world")
                owner[rid] = gid
            saving = w.get('saving', 'calm')
            if saving not in G.WORLD_SAVING:
                raise ProjectError(f"{c}: saving must be one of {list(G.WORLD_SAVING)}")
            out[gid] = {'name': g.get('name') or f'World {gid}', 'start_room': sid,
                        'start_screen': scr, 'start_x': x, 'start_y': y,
                        'rooms': rooms, 'saving': saving}
        self._worlds = out
        self._world_of = owner
        return out

    def world_of(self, room_id):
        """The world (gate number) a room belongs to, or None."""
        try:
            self.worlds()
        except ProjectError:
            return None
        return self._world_of.get(room_id)

    @staticmethod
    def room_has_battles(r):
        enc = r.get('encounters') or {}
        return bool(enc.get('enabled'))

    # ------------------------------------------------ monster NPCs (S101)
    MONSTER_SPRITE_BASE = 0xF0      # display-list ids $F0-$F3 (bank $0B resolver)
    MONSTER_CAST_MAX = 4

    def monster_cast(self, r, k):
        """Distinct species of the `monster` NPCs on screen k (all states), in
        first-seen order — slot n is drawn by sprite id $F0+n."""
        scr = self.room_screens(r).get(k)
        if scr is None:
            return []
        cast = []
        for st in self.screen_states(scr):
            for n in st.get('npcs', []) or []:
                if n.get('kind') == 'npc' and n.get('monster') is not None:
                    sp = F.val(n['monster'])
                    if sp not in cast:
                        cast.append(sp)
        return cast

    def npc_sprite(self, r, k, n):
        """The NPC entry's sprite byte: a `monster` NPC draws through its
        screen's cast slot ($F0 + index); others use `sprite`."""
        if n.get('monster') is not None:
            sp = F.val(n['monster'])
            if not 0 <= sp <= 255 or 217 <= sp <= 220 or \
                    (sp >= 221 and sp not in self.new_species_ids()):
                raise ProjectError(
                    f"room {r.get('id')} screen {k}: monster NPC species {sp} — species "
                    "217-220 hang or crash the game as monster NPCs (no real follower "
                    "tables; PyBoy S101), and 221-239 must be one of this project's "
                    "custom.species (S105; 240+ do not exist)")
            cast = self.monster_cast(r, k)
            idx = cast.index(sp)
            if idx >= self.MONSTER_CAST_MAX:
                raise ProjectError(
                    f"room {r.get('id')} screen {k}: more than "
                    f"{self.MONSTER_CAST_MAX} different monster NPCs (the engine's "
                    "display list has 4 slots, $F0-$F3)")
            return self.MONSTER_SPRITE_BASE + idx
        return F.val(n['sprite'])

    # ------------------------------------------- S117 (ROADMAP NG2) swirls
    def npc_conditions(self, r, k, n):
        """[(flag index, must_be_clear)] an NPC entry is shown under —
        `shown_when` terms (state-rule shape) + `swirl_of: N` (shown while
        gate N is not cleared). Lowered to the $A0/$A1 prefix entries that
        bank $60 CopyNPCListToBuffer turns into the hidden bit."""
        c = f"room {r.get('id')} screen {k} NPC ({n.get('x')},{n.get('y')})"
        out = []
        if n.get('swirl_of') is not None:
            from . import gates as G
            gid = int(F.val(n['swirl_of']))
            # S123: a gate whose swirl takes a colour once cleared keeps it shown
            if G.cleared_swirl(self.custom, gid) is None:
                out.append((self.resolve_flag_ref(f"gate:{gid}", c), True))
        for t in n.get('shown_when') or []:
            is_ = t.get('is', 'set')
            if is_ not in ('set', 'clear'):
                raise ProjectError(f"{c}: shown_when 'is' must be set/clear, got {is_!r}")
            out.append((self.resolve_flag_ref(t.get('flag'), c), is_ == 'clear'))
        if len(out) > STATE_RULE_MAX_TERMS:
            raise ProjectError(f"{c}: {len(out)} conditions (max {STATE_RULE_MAX_TERMS})")
        return out

    def npc_colour(self, r, k, n):
        """S123: (OBJ palette 0-7, flag index or None) an NPC entry is drawn in
        — None = its sprite's own colours. `colour`: 0-7 (always) or {"palette":
        0-7, "when": flag ref} (only while that flag is SET); a `swirl_of` gate
        with cleared_swirl = a palette → that palette once the gate is cleared.
        Lowered to the $A2 prefix (bank $60 CopyNPCListToBuffer / entry 11)."""
        from . import gates as G
        c = f"room {r.get('id')} screen {k} NPC ({n.get('x')},{n.get('y')})"
        col = n.get('colour')
        if col is not None:
            if n.get('monster') is not None:
                raise ProjectError(f"{c}: a monster NPC is drawn in its own walking "
                                   "colours — 'colour' is for people and objects")
            if isinstance(col, dict):
                pal, when = col.get('palette'), col.get('when')
            else:
                pal, when = col, None
            try:
                pal = int(F.val(pal))
            except Exception:                                    # noqa: BLE001
                pal = -1
            if not 0 <= pal <= 7:
                raise ProjectError(f"{c}: colour must be an OBJ palette 0-7 (got {col!r})")
            flag = self.resolve_flag_ref(when, c) if when not in (None, '') else None
            return pal, flag
        if n.get('swirl_of') is not None:
            gid = int(F.val(n['swirl_of']))
            pal = G.cleared_swirl(self.custom, gid)
            if pal is not None:
                return pal, self.resolve_flag_ref(f"gate:{gid}", c)
        return None

    def gate_clear_rows(self):
        """GateClearTable (bank $76, GateBossWin): per gate 0 .. last defined
        gate, the two flags a won boss-floor battle sets ($FFFF = none):
        (the gate's own flag, the vanilla flag of a re-bossed vanilla gate,
        S122: + (extra flags, win tails) the win replays — RunWinTail).
        A vanilla gate with its own boss sets nothing here (its scripts do)."""
        from . import gates as G
        start = self.repo_root or self.root
        cfg = self.gate_configs()
        last = max(cfg) if cfg else 31
        rows = []
        for gid in range(max(32, last + 1)):
            info = G.gate_cleared(self.custom, gid, start) if gid in cfg else None
            if info and info['own']:
                vf = info['vanilla_flag'] if gid < 32 else None
                # S122: a re-bossed vanilla gate replays the game's own win
                # bookkeeping (G.vanilla_win_program); new gates have none
                prog = G.vanilla_win_program(gid, start) if gid < 32 else ([], [])
                rows.append((gid, info['flag'], vf, prog))
            else:
                rows.append((gid, None, None, ([], [])))
        return rows

    def vanilla_swirl_overrides(self):
        """VanillaNPCExtTable rows: the vanilla portal screens whose swirl
        objects must follow a PROJECT gate's cleared flag — a portal whose
        gate (after entrance redirects) is a new gate or a re-bossed vanilla
        gate, or a portal re-routed to another gate. Per valid step version of
        the screen: the vanilla interact list with each such portal's swirl
        object conditioned on that gate's flag (shown while clear), or a swirl
        appended in versions that have the portal but no swirl object.
        Returns [{mapID, screen, step_counter, steps: [[entry dicts]]}]."""
        from . import gates as G
        from .vanilla import VanillaTable
        start = self.repo_root or self.root
        vt = VanillaTable(start)
        redirects = {}
        for rr in self.custom.get('entrance_redirects') or []:
            try:
                key = (F.val(rr['mapID']), int(F.val(rr['screen'])),
                       int(F.val(rr['x'])), int(F.val(rr['y'])))
            except Exception:
                continue
            redirects[key] = rr
        out = []
        for mid in sorted(vt.entries):
            e = vt.entries[mid]
            for sr in e.get('sub_rooms', []):
                k = sr.get('c925')
                try:
                    steps = vt.valid_steps(mid, k)
                except Exception:
                    continue
                portals = {}
                for st in steps:
                    for ex in st.get('exit_data', []):
                        if ex.get('gate_flag') == 1:
                            portals[(ex['trigger_x'], ex['trigger_y'])] = ex['dest_map_type']
                if not portals:
                    continue
                affected = {}
                for (x, y), g in portals.items():
                    rr = redirects.get((mid, k, x, y))
                    tgt = g
                    if rr is not None:
                        if F.val(rr.get('gate_flag', 0)) != 1:
                            continue           # re-routed to a room: no gate
                        tgt = G.entrance_gate(rr)
                    info = G.gate_cleared(self.custom, tgt, start)
                    if info is None or info['flag'] is None:
                        continue
                    if tgt != g or info['own']:
                        affected[(x, y)] = (tgt, info['flag'])
                if not affected:
                    continue
                variants = []
                for st in steps:
                    ents = []
                    for it in st.get('interact_data', []):
                        ents.append({'bytes': [int(b, 16) for b in it['raw'].split()],
                                     'cond': None})
                    have = {(xx, yy) for xx, yy in
                            ((ex['trigger_x'], ex['trigger_y']) for ex in st.get('exit_data', [])
                             if ex.get('gate_flag') == 1)}
                    for (x, y), (tgt, flag) in sorted(affected.items()):
                        if (x, y) not in have:
                            continue
                        hit = [en for en in ents if en['bytes'][0] < 0x80
                               and en['bytes'][1] == G.SWIRL_SPRITE
                               and (en['bytes'][2], en['bytes'][3]) == (x, y)]
                        if hit:
                            for en in hit:
                                en['bytes'][0] &= ~0x40     # never hidden by itself
                                en['cond'] = (flag, tgt)
                        else:
                            n_npc = sum(1 for en in ents if en['bytes'][0] < 0x80)
                            if n_npc < 8:
                                ents.append({'bytes': [0x00, G.SWIRL_SPRITE, x, y, 0xFF],
                                             'cond': (flag, tgt)})
                    variants.append(ents)
                out.append({'mapID': mid, 'screen': k,
                            'step_counter': int(sr['ram_counter'], 16),
                            'steps': variants, 'name': e.get('name', '')})
        return out

    def gate_rooms(self):
        """{room id: [rule rows]} for rooms served inside gates."""
        out = {}
        for row in self.gate_insert_rows():
            out.setdefault(row['room_id'], []).append(row)
        return out

    def room_flags(self, r):
        """CustomRoomFlagsTable byte (bank $71 entry 5): bit 0 = saving
        NOT allowed (custom.rooms[].can_save false; default allowed — but a
        gate's BOSS room defaults to no saving, like vanilla boss rooms $30-$4F:
        user rule S100, S101). S138 (ARC CAP2e): bit 7 = NO SUCH PLACE (a
        placeholder: a deleted room's map id) — bank $71 StalePlace sends a save
        standing there home at CONTINUE and reads the Castle's record for it;
        saving is off there too."""
        if r.get('placeholder'):
            return 0x81
        default = r.get('id') not in self.boss_room_ids()
        # S123: a world's rooms follow its saving rule (calm = rooms without
        # battles; explicit can_save wins)
        wid = self.world_of(r.get('id'))
        if wid is not None:
            rule = self.worlds()[wid]['saving']
            default = (rule == 'everywhere' or
                       (rule == 'calm' and not self.room_has_battles(r)))
        fl = 0 if r.get('can_save', default) else 0x01
        # S121: bit 1 = sprites stay drawn while a text box is open (bank $71
        # entry 8 TextSpriteMode — vanilla does it for rooms $08 / $5D, whose
        # art uses tile ids >= $80; copies of them set text_keeps_sprites)
        if r.get('text_keeps_sprites'):
            fl |= 0x02
        return fl

    def text_sprite_rooms(self):
        """S121: the rooms that need bank $71 entry 8 (the bank $06 region
        text_sprite_mode is the vanilla code when there is none)."""
        return [r.get('id') for r in self.rooms
                if not r.get('placeholder') and r.get('text_keeps_sprites')]

    # ------------------------------------------ per-gate settings (S101)
    def gate_configs(self):
        """custom.gates[] resolved -> {gate: {floors, boss_map, spawn (tx, ty),
        boss_room (custom id or None), hand_made, row [8 bytes]}} for all 32
        gates (vanilla values where not edited). Owning doc: PROJECT_COMPILER
        §2.17; engine: GATE_GENERATION §1 / §7.7."""
        if getattr(self, '_gate_cfg', None) is not None:
            return self._gate_cfg
        from . import gates as G
        start = self.repo_root or self.root
        van = {g['id']: g for g in G.vanilla_gates(start)}
        seen = set()
        for i, g in enumerate(self.custom.get('gates') or []):
            c = f"custom.gates[{i}]"
            unknown = set(g) - G.GATE_KEYS
            if unknown:
                raise ProjectError(f"{c}: unknown keys {sorted(unknown)}")
            gid = int(F.val(g.get('gate', -1)))
            if not 0 <= gid <= G.NEW_GATE_LAST:
                raise ProjectError(f"{c}: gate must be 0-31 (a vanilla gate) or "
                                   f"{G.NEW_GATE_FIRST}-{G.NEW_GATE_LAST} (a new gate; "
                                   f"got {gid})")
            if gid in seen:
                raise ProjectError(f"{c}: gate {gid} has two entries")
            seen.add(gid)
            # S115 (ROADMAP NG1): a NEW gate copies a vanilla gate
            if G.is_new_gate(gid):
                try:
                    src = int(F.val(g.get('copy_of', -1)))
                except Exception:
                    src = -1
                if not 0 <= src <= 31:
                    raise ProjectError(f"{c}: new gate {gid} needs \"copy_of\": the "
                                       "vanilla gate (0-31) it starts as")
                nm = g.get('name')
                if not isinstance(nm, str) or not nm.strip():
                    raise ProjectError(f"{c}: new gate {gid} needs a \"name\"")
            else:
                bad = sorted(set(g) & G.NEW_GATE_ONLY_KEYS)
                if bad:
                    raise ProjectError(f"{c}: {bad} only apply to new gates "
                                       f"({G.NEW_GATE_FIRST}-{G.NEW_GATE_LAST})")
        out = {}
        new_ids = [int(F.val(g['gate'])) for g in G.new_gate_entries(self.custom)]
        for gid in list(range(32)) + new_ids:
            gs = G.gate_settings(self.custom, gid)
            src = gid if gid < 32 else int(F.val(gs['copy_of']))
            v = van[src]
            row = list(bytes.fromhex(v['row']))
            c = f"custom.gates[gate {gid}]"
            boss_room = None
            if gs.get('floors') is not None:
                n = int(F.val(gs['floors']))
                if not G.FLOORS_MIN <= n <= G.FLOORS_MAX:
                    raise ProjectError(f"{c}: floors must be {G.FLOORS_MIN}-"
                                       f"{G.FLOORS_MAX} (the count includes the "
                                       f"boss floor; got {n})")
                row[3] = n
            b = gs.get('boss')
            if b not in (None, '', 'vanilla'):
                if isinstance(b, str) and b.startswith('vanilla:'):
                    mid = F.val(b.split(':', 1)[1])
                    if not 0 <= mid < 0x6B:
                        raise ProjectError(f"{c}: boss {b!r} is not a vanilla map")
                    sp = G.vanilla_boss_spawn(mid, start)
                    if sp is None:
                        raise ProjectError(
                            f"{c}: vanilla map {F.hexb(mid)} is no gate's boss room "
                            "— its arrival cell is unknown (use a custom room)")
                    row[4], row[5], row[6] = mid, sp[0], sp[1]
                else:
                    room = self.room_by_id(b)
                    if room is None or room.get('placeholder'):
                        raise ProjectError(f"{c}: boss room {b!r} is not a custom "
                                           "room of this project")
                    mid = F.val(room['mapID'])
                    if mid > 0xFE:
                        raise ProjectError(f"{c}: boss room map id {F.hexb(mid)} > $FE")
                    arr = room.get('gate_arrival')
                    if not arr:
                        raise ProjectError(
                            f"{c}: boss room {b!r} has no gate_arrival {{screen, x, "
                            "y}} — where the player appears on the boss floor")
                    scr = int(arr.get('screen', 0))
                    if scr not in self.room_screens(room):
                        raise ProjectError(f"{c}: boss room {b!r} gate_arrival "
                                           f"screen {scr} does not exist")
                    tx, ty = G.arrival_tile(scr, arr['x'], arr['y'])
                    row[4], row[5], row[6] = mid, tx, ty
                    boss_room = b
            # S120: the floor-type rows + depth tier (bytes 0-2, 7) — GATE_GENERATION §1
            for k, (lo, hi, at) in G.ROW_KEYS.items():
                if gs.get(k) is None:
                    continue
                try:
                    n = int(F.val(gs[k]))
                except Exception:                                # noqa: BLE001
                    n = -1
                if not lo <= n <= hi:
                    raise ProjectError(f"{c}: {k} must be {lo}-{hi} (got {gs[k]!r})")
                row[at] = n
            new = gid >= 32
            world = isinstance(gs.get('world'), dict)
            if world:                       # S123: floor 1 = the world, floor 2 unused
                row[3] = G.WORLD_FLOORS
            # S123: what its swirl objects do once cleared (None = vanish, else a palette)
            cs = gs.get('cleared_swirl')
            if cs not in (None, '', 'stop'):
                try:
                    csn = int(F.val(cs))
                except Exception:                                # noqa: BLE001
                    csn = -1
                if not 0 <= csn <= 7:
                    raise ProjectError(f"{c}: cleared_swirl must be \"stop\" or an "
                                       f"OBJ palette 0-7 (got {cs!r})")
            out[gid] = {'floors': row[3], 'boss_map': row[4], 'spawn': (row[5], row[6]),
                        'boss_room': boss_room,
                        'hand_made': bool(gs.get('hand_made')) or world, 'world': world,
                        'edited': bool(gs), 'row': row,
                        'name': gs.get('name') if new else v['name'],
                        'comment': gs.get('comment', ''),
                        'new': new, 'source': src}
        self._gate_cfg = out
        return out

    def boss_room_ids(self):
        try:
            return {c['boss_room'] for c in self.gate_configs().values() if c['boss_room']}
        except ProjectError:
            return set()

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

    # ------------------------------------------------- LZ stream banks (S135)
    def stream_items(self):
        """Every LZ stream the project owns, in allocation order: the
        custom.layouts[] items (tiles, then attr, declaration order — the
        S92 bank $64 order), then custom.tilesets[]. Returns a list of
        (key, home_bank, label, raw_bytes_fn, comment) with key =
        ('tiles'|'attr', layout id) or ('tileset', tileset id)."""
        from . import layouts as L
        repo = self.repo_root or REPO_ROOT
        out = []
        for lay in self.layouts:
            lid = lay['id']
            if 'tiles' in lay:
                out.append((('tiles', lid), LAYOUT_HOME_BANK, f"Layout_{lid}",
                            (lambda lay=lay: L.compile_tiles(repo, lay['tiles'])),
                            lay.get('comment', f"layout {lid} (LZSS)")))
            if 'attr' in lay:
                out.append((('attr', lid), LAYOUT_HOME_BANK, f"Attr_{lid}",
                            (lambda lay=lay: L.compile_attr(repo, lay['attr'])),
                            f"attr map {lid} (LZSS)"))
        for ts in self.tilesets:
            tid = ts['id']

            def tsdata(ts=ts):
                return L.compress(repo, L.tileset_bytes(repo, ts, self.root))
            out.append((('tileset', tid), TILESET_HOME_BANK, f"TilesetGFX_{tid}",
                        tsdata, ts.get('comment')))
        return out

    def stream_plan(self):
        """S135 (ROADMAP ARC CAP2a): where every LZ stream lives. First fit in
        allocation order: a layout / attr map tries bank $64 first, a tileset
        bank $67, then the overflow banks already opened ($80, $81, … — any
        kind may share them), and opens the next free bank $80-$FF when none
        fits. A bank holds 1 self-ID byte + a 2-byte pointer per entry (<= 256)
        + the streams. A project that fits in $64 / $67 gets exactly the S92
        layout (same entries, same order) — the overflow banks only exist once
        a home bank is full. Returns {'where': {key: (bank, entry)},
        'banks': {bank: [(key, label, data, comment), …]}, 'overflow': [bank, …]}."""
        if self._stream_plan is not None:
            return self._stream_plan
        self._ext_taken = []           # a retry after an error starts at $80 again
        self._place_plan = None        # S136: the places take their banks after these
        self._anim_plan = None         # S139: the animation banks after the places
        banks = {LAYOUT_HOME_BANK: [], TILESET_HOME_BANK: []}
        used = {LAYOUT_HOME_BANK: 1, TILESET_HOME_BANK: 1}      # the self-ID byte
        overflow = []
        where = {}
        self._stream_errors = []
        for key, home, label, datafn, comment in self.stream_items():
            try:
                data = bytes(datafn())
            except (ValueError, OSError, KeyError, TypeError) as e:
                # reported as build ERRORS by validators._validate_layouts_tilesets
                # (stream_errors); an empty placeholder keeps every reference
                # resolvable meanwhile — never shipped (the build stops)
                self._stream_errors.append(f"{key[0]} {key[1]!r}: {e}")
                data = b''
            need = 2 + len(data)
            if 1 + need > STREAM_BANK_SIZE:
                raise ProjectError(f"{key[0]} {key[1]!r}: compressed stream of "
                                   f"{len(data)} bytes cannot fit any bank")
            for b in [home] + overflow:
                if (used[b] + need <= STREAM_BANK_SIZE
                        and len(banks[b]) < STREAM_BANK_MAX_ENTRIES):
                    break
            else:
                b = self._take_ext_bank('streams')
                overflow.append(b)
                banks[b], used[b] = [], 1
            where[key] = (b, len(banks[b]))
            banks[b].append((key, label, data, comment))
            used[b] += need
        self._stream_plan = {'where': where, 'banks': banks, 'overflow': overflow,
                             'used': used}
        return self._stream_plan

    def _take_ext_bank(self, purpose):
        """The next free bank of the 4 MB ROM's upper half ($80-$FF), in order.
        S135: the stream banks are the only tenant; ARC CAP2b's place banks take
        theirs from the same allocator."""
        taken = getattr(self, '_ext_taken', None)
        if taken is None:
            taken = self._ext_taken = []
        b = EXT_BANK_FIRST + len(taken)
        if b > EXT_BANK_LAST:
            raise ProjectError(
                "the ROM is full: all 128 banks $80-$FF of the 4 MB ROM are in use "
                f"(needed one more for {purpose})")
        taken.append((b, purpose))
        return b

    def ext_bank_owners(self):
        """{bank: purpose} for every bank $80-$FF the build fills (S135 streams,
        S136 places, S139 animations)."""
        from . import places as _PL
        from . import tileanim as _TA
        self.stream_plan()
        _PL.plan(self)
        _TA.plan(self)                     # S139 (ARC CAP2d): the animation banks
        return dict(getattr(self, '_ext_taken', None) or [])

    def place_plan(self):
        """S136 (ROADMAP ARC CAP2b): where every place and text section lives
        (editor2/core/places.py plan)."""
        from . import places as _PL
        return _PL.plan(self)

    def stream_ref(self, key, ctx=""):
        """(bank, entry) of one of the project's LZ streams (S135 plan)."""
        w = self.stream_plan()['where']
        if key not in w:
            raise ProjectError(f"{ctx}: no {key[0]} stream {key[1]!r}")
        return w[key]

    def _explicit_stream_ref(self, bank, entry):
        """S135: an authored {bank: $64 | $67, entry: N} reference means what it
        meant before the spill — the N-th declared layout-class stream ($64) /
        the N-th declared tileset ($67) — wherever the plan put it now."""
        if bank == LAYOUT_HOME_BANK:
            for lid, n in self._layout_entry.items():
                if n == entry:
                    return self.stream_ref(('tiles', lid))
            for lid, n in self._attr_entry.items():
                if n == entry:
                    return self.stream_ref(('attr', lid))
        elif bank == TILESET_HOME_BANK and 0 <= entry < len(self.tilesets):
            return self.stream_ref(('tileset', self.tilesets[entry]['id']))
        return bank, entry

    def resolve_layout(self, ref, ctx=""):
        """Screen layout ref -> (bank, entry). Forms: {bank, entry} (any
        bank — vanilla tileset banks included) or {id} -> the stream plan
        (bank $64 or an overflow bank, S135)."""
        if 'id' in ref:
            lid = ref['id']
            if lid not in self._layout_entry:
                raise ProjectError(
                    f"{ctx}: layout id {lid!r} not in custom.layouts "
                    "(or it has no 'tiles')")
            return self.stream_ref(('tiles', lid), ctx)
        return self._explicit_stream_ref(F.val(ref['bank']), F.val(ref['entry']))

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
            return self._explicit_stream_ref(F.val(at['bank']), F.val(at['entry']))
        lay = scr.get('layout') or {}
        if 'id' in lay and lay['id'] in self._attr_entry:
            return self.stream_ref(('attr', lay['id']), ctx)
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
            return self.stream_ref(('attr', lid), ctx)
        return self._explicit_stream_ref(F.val(at['bank']), F.val(at['base_entry']))

    def resolve_gfx(self, rec, ctx=""):
        """record gfx ref -> (gfx_bank, gfx_id). Forms: gfx_bank+gfx_id
        (vanilla tileset), or {"tileset": id} -> the stream plan (bank $67 or
        an overflow bank, S135)."""
        if 'tileset' in rec:
            tid = rec['tileset']
            if tid not in self._tileset_entry:
                raise ProjectError(
                    f"{ctx}: tileset id {tid!r} not in custom.tilesets")
            return self.stream_ref(('tileset', tid), ctx)
        return self._explicit_stream_ref(F.val(rec['gfx_bank']), F.val(rec['gfx_id']))

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
        # S136 (ROADMAP ARC CAP2b): a text SECTION (256 ids) is placed whole in
        # one bank (places.py), so an auto-numbered text that would take its
        # section past places.TEXT_SECTION_BUDGET bytes starts the next section
        # instead (a project whose sections stay small keeps every id)
        # (S136 review: never into ids an entry declares explicitly — a section
        # holding an explicit id is never broken past it, and the jump goes to
        # the first section no explicit id uses)
        from . import places as _PL
        next_id = 0x0A00
        sec_bytes = {}
        explicit = set()
        for e in self._dialogue:
            if 'text_id' in e:
                try:
                    explicit.add(F.val(e['text_id']))
                except Exception:                            # noqa: BLE001
                    pass
        exp_secs = {t >> 8 for t in explicit}
        for e in self._dialogue:
            if 'text_id' in e:
                tid = F.val(e['text_id'])
            else:
                tid = next_id
                size = _PL.text_entry_size(self, tid, e) + 2
                if (tid & 0xFF) and sec_bytes.get(tid >> 8, 0) + size \
                        > _PL.TEXT_SECTION_BUDGET \
                        and not any(t >> 8 == tid >> 8 and t >= tid for t in explicit):
                    sec = (tid >> 8) + 1
                    while sec in exp_secs:
                        sec += 1
                    tid = sec << 8
            sec_bytes[tid >> 8] = sec_bytes.get(tid >> 8, 0) + \
                _PL.text_entry_size(self, tid, e) + 2
            e['_tid'] = tid
            if tid in self._text_by_id:
                raise ProjectError(f"duplicate text id {F.hexw(tid)}")
            self._text_by_id[tid] = e
            next_id = max(next_id, tid + 1)
        # resolve script "text" ops given as dialogue ids
        by_name = {e['id']: e['_tid'] for e in self._dialogue if 'id' in e}
        for s in list(self.custom.get('scripts', [])) + self.skill_scripts:
            for it in s['ops']:
                if isinstance(it, list) and it and it[0] == 'text' \
                        and isinstance(it[1], str) \
                        and it[1] in by_name:
                    it[1] = by_name[it[1]]
        # S120 (P3.6): a text that prints {lead} ($F9 $00) needs op $3F
        # load_lead_name right before it — the name slot $C180 is shared, so
        # it is filled at the last moment (the cutscene lowering emits its
        # own, so its step model stays exact)
        from . import textenc as _T
        lead = {e['_tid'] for e in self._dialogue if _T.uses_lead(
            {k: v for k, v in e.items() if k in ('boxes', 'text', 'lines')})}
        if lead:
            for s in list(self.custom.get('scripts', [])) + self.skill_scripts:
                ops, out = s.get('ops') or [], []
                for it in ops:
                    if isinstance(it, list) and it and it[0] == 'text' \
                            and _pv(it[1]) in lead \
                            and not (out and out[-1] == ['op', 'load_lead_name']):
                        out.append(['op', 'load_lead_name'])
                    out.append(it)
                if len(out) != len(ops):
                    s['ops'] = out

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
        flags = self.custom.get('flags', [])
        try:
            nums = number_flags(flags, self._check_flag)
        except ValueError as ex:
            raise ProjectError(str(ex))
        for fl, idx in zip(flags, nums):
            fl['_index'] = idx
        self._flags = {fl['name']: fl['_index'] for fl in flags}

    def _check_flag(self, idx):
        if not any(lo <= idx <= hi for lo, hi in FLAG_SAFE_RANGES):
            raise ProjectError(
                f"flag index {F.hexw(idx)} outside EVENT_FLAGS.md safe+"
                "persistent ranges (collision zones corrupt live variables; "
                "$0278+ does not persist)")

    def flag_map(self):
        return dict(self._flags)

    # ------------------------------------------- story checks (S129, P3.14b)
    def _allocate_checks(self):
        """custom.checks -> the virtual flags $1800 + n (list order); internal
        checks (story:… refs: a quest's bag room, a milestone reached) follow
        on demand (check_flag). A bad check is reported by validators.validate
        (story_error) — the editor still opens."""
        from . import story as _ST
        self._checks = {}
        self._check_records = []        # [(name, record bytes, ctx)]
        self._check_defs = {}
        self.check_error = None
        try:
            lst = _ST.expand_story_checks(self.custom, _ST.check_list(self.custom))
            clash = [c['name'] for c in lst if c['name'] in self._flags]
            if clash:
                raise _ST.StoryError(f"custom.checks: {clash} — a check and a flag share "
                                     "a name (rename one)")
            _ST.check_order(lst)
        except _ST.StoryError as ex:
            self.check_error = str(ex)
            lst = []
        for i, c in enumerate(lst):
            self._checks[c['name']] = _ST.STORY_FLAG_BASE + i
            self._check_defs[c['name']] = c
            self._check_records.append(None)       # resolved lazily (terms name flags)

    def is_check(self, ref):
        return isinstance(ref, str) and (ref in self._checks or ref.startswith('story:'))

    def check_flag(self, ref, ctx=""):
        """A check name / an internal story:… ref -> its virtual flag number."""
        from . import story as _ST
        if ref in self._checks:
            return self._checks[ref]
        parts = ref.split(':')
        if len(parts) >= 3 and parts[1] == 'bag_room':
            chk = {'name': ref, 'kind': 'bag_room', 'count': int(parts[2])}
        elif len(parts) >= 3 and parts[1] == 'reached':
            chk = {'name': ref, 'kind': 'story', 'milestone': ':'.join(parts[2:])}
            try:
                chk = _ST.expand_story_checks(self.custom, [chk])[0]
            except _ST.StoryError as ex:
                raise ProjectError(f"{ctx}: {ex}")
        else:
            raise ProjectError(f"{ctx}: {ref!r} is no story check")
        n = len(self._check_records)
        if n >= _ST.STORY_CHECK_MAX:
            raise ProjectError(f"{ctx}: more than {_ST.STORY_CHECK_MAX} story checks")
        self._checks[ref] = _ST.STORY_FLAG_BASE + n
        self._check_defs[ref] = chk
        self._check_records.append(None)
        return self._checks[ref]

    def story_check_records(self):
        """[(name, record bytes)] in check order (bank $77 StoryCheckPtrs)."""
        from . import story as _ST
        out = []
        i = 0
        while i < len(self._check_records):        # resolving may add internal checks
            name = next(n for n, v in self._checks.items()
                        if v == _ST.STORY_FLAG_BASE + i)
            if self._check_records[i] is None:
                try:
                    self._check_records[i] = _ST.check_record(
                        self, self._check_defs[name], f"check {name}")
                except _ST.StoryError as ex:
                    raise ProjectError(str(ex))
            out.append((name, self._check_records[i]))
            i += 1
        if len(out) > _ST.STORY_CHECK_MAX:
            raise ProjectError(f"{len(out)} story checks — at most {_ST.STORY_CHECK_MAX}")
        return out

    def story_command(self, kind, params, ctx=""):
        """A story command step -> the op $24 word $FF00 + n (deduped; n >= 1)."""
        from . import story as _ST
        try:
            rec = _ST.cmd_record(kind, params, ctx)
        except _ST.StoryError as ex:
            raise ProjectError(str(ex))
        if rec not in self._story_cmds:
            if len(self._story_cmds) >= _ST.STORY_CMD_MAX:
                raise ProjectError(f"{ctx}: more than {_ST.STORY_CMD_MAX} different story "
                                   "commands")
            self._story_cmds.append(rec)
        return 0xFF00 + self._story_cmds.index(rec) + 1

    def story_commands(self):
        return list(self._story_cmds)

    def resolve_flag_write(self, ref, ctx=""):
        """A flag a step turns ON / OFF — never a story check (S129)."""
        if self.is_check(ref):
            raise ProjectError(f"{ctx}: {ref!r} is a story check — it is worked out from "
                               "the game, it cannot be turned ON or OFF")
        return self.resolve_flag_ref(ref, ctx)

    # ------------------------------------------------------ state rules (S97)
    def resolve_flag_ref(self, ref, ctx=""):
        """A flag reference in authored data -> event flag index. Names are
        custom.flags entries (auto-allocated from the safe pool); numbers
        ("0x0030", 48) are ANY event flag — vanilla story flags included
        (EVENT_FLAGS.md). Indices >= $0278 are readable but not saved."""
        if isinstance(ref, str) and ref in self._flags:
            return self._flags[ref]
        if isinstance(ref, str) and (ref in self._checks or ref.startswith('story:')):
            # S129: a story check = the virtual flag $1800 + n (bank $73 FlagAddr)
            return self.check_flag(ref, ctx)
        if isinstance(ref, str) and ref.startswith('hook:'):
            # S121: the Milly hook's own flags ("hook:milly" = the player is
            # Milly, "hook:milly_arrived" = her arrival scene has played)
            from . import milly as _MH
            if ref not in _MH.FLAG_REFS:
                raise ProjectError(f"{ctx}: {ref!r} — hook flags: "
                                   + ', '.join(sorted(_MH.FLAG_REFS)))
            return _MH.FLAG_REFS[ref]
        if isinstance(ref, str) and ref.startswith('gate:'):
            # S117 (NG2): "gate N cleared" — the gate's own flag when it has
            # one (new gates, re-bossed vanilla gates), else its vanilla flag
            from . import gates as G
            gid = G.parse_gate_ref(ref)
            info = (G.gate_cleared(self.custom, gid, self.repo_root or self.root)
                    if gid is not None else None)
            if info is None:
                raise ProjectError(f"{ctx}: {ref!r} — no such gate")
            if info['flag'] is None:
                raise ProjectError(f"{ctx}: {ref!r} — this gate has no cleared flag "
                                   "(the unused gate 31 with its own boss)")
            return info['flag']
        try:
            idx = F.val(ref)
        except Exception:
            idx = None
        if not isinstance(idx, int):
            if getattr(self, 'check_error', None):
                # S129: the story checks did not load — say why (not "no such flag")
                raise ProjectError(f"{self.check_error} (so {ref!r} is unknown — {ctx})")
            raise ProjectError(f"{ctx}: flag {ref!r} is neither a named flag "
                               "(custom.flags) nor a flag number")
        if not flag_index_ok(idx):
            raise ProjectError(f"{ctx}: flag {F.hexw(idx)} outside the event "
                               f"flags ($0000-{F.hexw(FLAG_VANILLA_MAX)} vanilla, "
                               f"{F.hexw(EXT_FLAG_FIRST)}-{F.hexw(EXT_FLAG_LAST)} extended)")
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
        self._step_game = []
        for r in self.rooms:
            for i, s in sorted(self.room_screens(r).items()):
                sc = s.get('step_counter', 'auto')
                if isinstance(sc, dict) and sc.get('vanilla') is not None and \
                        not r.get('state_rules'):
                    # S118c: a cloned room's screen that FOLLOWS THE GAME — its
                    # state is the original room's own counter (written by the
                    # game's story scripts, saved with the game): the label is
                    # an EQU of that address, nothing is allocated. (A room with
                    # state_rules keeps its own counter: the rules write it.)
                    lbl = sc.get('label') or self._def_step_label(r, i)
                    self._step_game.append((lbl, F.val(sc['vanilla']),
                                            f"Room {F.hexb(F.val(r['mapID']))} screen {i} "
                                            f"({r.get('id', '')}) follows the game's counter"))
                    s['_ctr_label'] = lbl
                    continue
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

    def step_counter_game(self):
        """[(label, vanilla addr, comment)] — screens whose state is the game's
        own counter (S118c, cloned rooms)."""
        self.step_counter_allocation()
        return list(self._step_game)

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
                return self._explicit_stream_ref(F.val(at['bank']), F.val(at['entry']))
            lay = st.get('layout') or {}
            if 'id' in lay and lay['id'] in self._attr_entry:
                return self.stream_ref(('attr', lay['id']), ctx)
        return self.screen_attr_entry(r, k, ctx)

    def state_palette_ref(self, r, k, n):
        """Palette for screen k, state n: ('palette', palette id) for a project
        palette (states[n].palette > render.palette) or ('addr', ptr) = the
        vanilla source room's own palette block in bank $17 (borrow). S137: the
        palette's bytes go into the room's home bank (emitters.render_lines)."""
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
            return 'palette', pid
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

    # ------------------------------------------------------------- animation
    def anim_source(self, room):
        """(byte, comment) for CustomAnimSrcTable (S99). Invalid values are
        reported by validators; here they fall back to none."""
        try:
            v, _kind, why = F.anim_source(room)
        except ValueError as e:
            return F.ANIM_NONE, f'INVALID ({e}) -> none'
        return v, why

    def room_sheet(self, room):
        """S102: the 2048-byte sheet a room draws with (its own tileset copy),
        or None for a room on a vanilla sheet."""
        tid = (room.get('record') or {}).get('tileset')
        if tid is None or tid not in self._tileset_entry:
            return None
        from . import layouts as L
        ts = self.tilesets[self._tileset_entry[tid]]
        return bytes(L.tileset_bytes(self.repo_root or '.', ts, self.root))

    def tile_anims(self, room):
        """S102: custom.rooms[].tile_anims (the room's own animated tiles)."""
        return list(room.get('tile_anims') or [])

    # ----------------------------------------------------------------- music
    def music_plan(self):
        """S116: the resolved music plan (editor2/core/music.Plan) — cached so
        the double-emit determinism check sees identical results."""
        if self._music is None:
            from . import music as M
            self._music = M.plan(self)
        return self._music

    def music_resolved(self):
        """(bank74_library, room_bgm[256], song_ids, warnings) — the S64 view (256 rows since S138)."""
        return self.music_plan().legacy()

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
