# PROJECT COMPILER — `project.json` → patch overlay (headless editor backend)

> **Status:** built Session 53. Regression **machine-verified byte-identical**
> to the S53 reference patched build; the master-table fix build passed the
> user's demo loop same-day (rooms/scroll/encounters/teleports/step-demo/
> save). Two runtime anomalies surfaced in testing are classified NOT-fix /
> NOT-compiler by byte evidence — see PROJECT_STATE S53 block. Owning doc for: the `project.json` schema, the compile
> pipeline, the emitter registry, the `@BUILD_PROJECT` regions, template
> pinning, the manifest, and the compiler-related findings of S53.
> Architecture context: `EDITOR_DESIGN.md`. Format ground truth stays in the
> per-subject docs (ROOM_DATA_FORMAT, TEXT_SYSTEM, CROSSBANK_ROOMS,
> EVENT_FLAGS, GATE_GENERATION); this doc cites them rather than restating.

---

## 1. What it is

`tools/build_project.py` + the `editor2/` Python package compile a semantic
**`project.json`** into the same patch overlay the project already builds
with. **project.json is the source of truth; the generated `.asm` files are
build artifacts** (EDITOR_DESIGN "Hard rules"). The compiler only ever ADDS
to the proven overlay:

| It owns | As |
|---|---|
| `patches/bank_060.asm` | whole file = verbatim engine template head + generated data |
| `patches/bank_071.asm` | whole file = verbatim engine template head + generated tables |
| `patches/bank_017.asm` | two marked regions (`room_palettes_a`, `room_render_tables`) |
| `patches/wram.asm` | one marked region (`wram_step_counters`) |
| `patches/bank_000.asm` | one marked region (`rom0_room_records` — the `$26DD` rows `$6B-$6F`, S94) |
| `patches/bank_064.asm`, `bank_067.asm`, `bank_074.asm`, `bank_014.asm` region | layouts / tilesets / songs / quest enemies (S64, S70, S92) |
| `patches/bank_06c.asm` | whole file = template head (`CustomTileAnimate`) + the rooms' own tile animations (S102, §2.19) |
| `gd_*` regions in `patches/bank_001/003/006/007/012/013/014/016/04d/054/069.asm` | the vanilla data tables, from `gamedata` (S103, §2.20) |

Everything else — engine intercepts in banks `$00/$01/$04/$06/$07/$0B/$16`,
layouts (`bank_064.asm` via `tools/build_gate_room.py` /
`tile_layout_compiler.py`), tilesets (`bank_067.asm` via
`build_combined_tileset.py`), breeding/library/skills banks — stays exactly
as hand-authored/tool-owned. Rooms **reference** layouts by
`{bank, entry}`; the compiler never re-derives a format another proven tool
owns.

### Quick start

```bash
# regression check (compat project must equal the S65 reference patched md5)
python3 tools/build_project.py --project editor2/example-project \
    --build --expect-md5 de0c5a672e7e7e1fb834dd7afe70b9e7

# author→test loop: ROM lands at <out>/build/rom.gbc (+ game.sym + manifest.json)
python3 tools/build_project.py --project my-project --build

# commit generated files into patches/ (after the ROM is verified)
python3 tools/build_project.py --project my-project --apply

# tests (18: validators, determinism; --rom adds the two ROM builds)
python3 editor2/tests/test_compiler.py [--rom]
```

### The two S53 proofs

* **Byte-identity regression** — `editor2/example-project/project.json`
  re-expresses the entire user-confirmed hand-authored content (6 rooms, 21
  dialogue entries, 10 scripts, 4 palettes, 7 step counters, enc/record
  tables). With `build.compat.master_table_rooms` present, the generated
  patched ROM md5 is **`de0c5a672e7e7e1fb834dd7afe70b9e7`** (patched build,
  re-pinned S65 after the WRAM migration: buffers → `$CC80`/`$CD00`,
  step-counter region → `$CD80` (640 B) in the CF3-freed window, static
  `ds 7` pad keeps `wRoomRecScratch` at `$DE7B`, bank `$71` templates
  UNCHANGED (label-only relink), + bank `$73` entry 6 tail zeroes the
  window after the main-image restore copy. Built S65, NOT yet
  user-tested. Historical, superseded:
  `7cc0857faad8a950573e865e93f791eb` (S64, patched,
  re-pinned S64 after M3b/M3c: LoadNewBGMIdIntoA rewrite + bank $71 entry
  2/BGM table + music emitter owning bank $74 + dq6_town1; user-confirmed
  v6. NOTE: this doc's copy had gone stale at S63v4's `c23beed7…` while the
  test pin moved to S63v5's `3009b75e…` — the same doc-vs-test drift class
  as the S63 finding below; both now carry S64's value. Historical,
  superseded: `3009b75ee1e3bd58bc315a39b7324e17` (S63v5, room $6C NPC +
  BGM #07), `c23beed7aadee80a061c0f6c24d7c1f4` (S63v4, M3a:
  AudioMasterTableExt + song bank $74 + bank $1E reverted, AND S62's hand
  edits to compiler-owned bank_060.asm — BGM NPC,
  `set_bgm 0x9E`, dialogue — folded into the example project. **S62 had
  silently broken compat==hand byte-identity** (pin left at S60's
  `168c5f1b5b4b3b2568a6d6e2f3f1ab45`, historical patched reference; this
  doc's quick-start had ALSO gone
  stale at S57's value — CI runs only verify_integrity, so neither failed
  in public; DOC_AUDIT/KEY_LESSONS S63, CI box in ROADMAP). Property
  restored: compat build == hand-staged tree, both `c23beed7…`; the
  property held through S64's re-pin as well.
  Historical, superseded: `168c5f1b…` (S60), `6c41f0d8…` (S57 patched,
  re-pinned after the CF2 patches: wPendingFarmExp in wram.asm, bank $50
  farm-share divert, bank $0B commit stub, new bank $73 — the compat project
  build stayed md5-EQUAL to the hand-staged patched tree, proving the
  byte-identity property across the change; historical, superseded:
  `026970d361f6afe03f28e29fa6e631f6`, the S55v2 patched reference — WRAM
  relocation + init/flag fixes —
  ClearAllWRAM `$1E00`->`$1EE0`, flag derivation at CopyCustomRoomRecord head;
  bank $71 template re-pinned per §5, TEMPLATE_SIZE 0x71: 103->116). (This
  md5 moves whenever ANY patch changes; re-derive via verify_integrity-style
  staging. Historical, superseded values: S53 pair
  `3a5a514c65b330e2788170c5d409b960` / `f81d4ad84ee52f4c3342cc1f7e261e58`;
  the mid-S55 pair `cc62b5…`/`8878ef…` never passed user test — it lacked
  the init/flag fixes and crashed on entry, see KEY_LESSONS S55.)
* **Fix build** — deleting `build.compat` emits the full-width script master
  table (+ shared no-op). S55v2 fixed patched ROM md5
  `fb6a96abd2b045c68234d74fcfcc76b5` (patched build, **user-confirmed
  working 2026-07-10** — this run also cleared the master-table fix's test
  debt from S53, whose user loop had only run the COMPAT config; see
  KEY_LESSONS S55 "one variable per test ROM").
  S53-measured delta vs the reference: bank `$60` `$4010–$45B8` only (the
  +10 table bytes, downstream labels shifted, template operands re-resolved
  by the linker) + the 2 header checksum bytes `$014E/$014F`. Bank `$60`
  usage 1455 → 1465 B.

---

## 2. Schema reference (v1)

Top level: `meta`, `world` (stub), `custom`, `gamedata` (S103, §2.20), `progression`, `build`.
Values accept `"0x6B"`, `"$6B"`, decimal ints, or (where noted) RGBDS
symbols passed through to the assembler.

### 2.1 Layers (EDITOR_DESIGN §3)

v1 implements **Layer B (`custom`)** and **Layer D (`build`)**; **Layer C
(`gamedata`) since S103** (§2.20). `world` (Layer A, vanilla-room edits) is
declared but unimplemented: **any non-`_`-prefixed content in it is a hard
error** — the compiler never silently ignores authored data (unknown
`gamedata` sections / fields are errors too). Same for `custom.music`
(needs ROADMAP Arc 3 M1–M3) and `custom.skills` (see §6).

### 2.2 `custom.rooms[]`

```jsonc
{ "id": "gate_island",            // human name (labels/comments/manifest)
  "mapID": "0x6B",                // dense from $6B; gaps auto-fill as placeholders (warn)
  "placeholder": true,            // optional: never-entered slot; shares one dummy subtable
  "source_mapID": "0x04",         // CustomSourceMapTable byte (wCustomRoomFlag source)
  "scripts_placement": "inline",  // optional: emit script table next to room data
                                  // (default: in the script area; $6D uses inline)
  "record": {                     // REQUIRED for mapID >= $70, ignored (warn) below:
    "gfx_id": "0x0D", "gfx_bank": "0x28",      // Custom26DDTable row (bank $71),
    "width_px": 160, "height_px": 128,          // width=cols*160, height=rows*128
    "collision_threshold": "0x30" },            // (ROOM_DATA_FORMAT / KEY_LESSONS S10)
  "render": {                     // bank $17 tables, indexed mapID-$6B
    "palette": "pal_6b",          // palette asset id, or null/omit = dw $0000 (borrow vanilla)
    "attr": { "bank": "0x64", "base_entry": 1 } },  // or null = db $00,$00 fallback
  "encounters": { "enabled": true, "gate_id": 0, "floor": 1 },  // RoomEncTable row
  "scripts": { "0": "arm_encounters", "1": "give_jerky" },      // index -> script id;
                                  // index 0 = room-entry, RESERVED (KEY_LESSONS S2)
  "screens": {                    // sparse map, keys = 4x2 grid indices "0".."7"
    "0": {
      "layout": { "bank": "0x64", "entry": 0 },   // step_id + tileset_bank
      "step_counter": "auto",     // or {"label": "...", "addr": "0xDE78"}
      "npcs": [
        { "kind": "spawn", "x": 7, "y": 6 },              // legacy = $8F examine spot (S98, §2.14)
        { "kind": "npc", "facing": "down", "sprite": "0x0B",
          "x": 2, "y": 7, "script": "give_jerky",       // or "none" -> $FF, or an int
          "behaviour": "pace_x1",                       // S97, optional (default stand)
          "hidden": false } ],                          // S97, optional (type bit 6)
      "exits": [
        { "x": 3, "y": 1, "dest": "room:$6C",   // or "vanilla:$01" or plain value
          "gate_flag": 0, "screen_byte": "0x00",// REQUIRED — never guessed
          "spawn_x": 7, "spawn_y": 6, "comment": "..." } ] } } }
```

Emission formats: NPC 5-byte / exit 7-byte entries, `$FF` first-byte
terminators, screen sub-tables (width 4 or 8 by top screen index, override
`subtable_width`) — all per ROOM_DATA_FORMAT / CROSSBANK_ROOMS, encoded
once in `editor2/core/formats.py` with doc citations.

### 2.3 `custom.dialogue[]`

Four authoring forms; ids `$0A00+` (auto-assigned in order, or explicit
`text_id`; ids must be dense per 256-id section — section = hi-byte−`$0A`,
routed by the bank-`$04` `TextQueueCheck_Ext` intercept):

```jsonc
{ "id": "jerky_offer", "text_id": "0x0A00",
  "lines": ["Want a", "Beef Jerky?"], "choice": true }   // explicit lines
{ "id": "long_text", "text": "one long string …" }        // flowed into boxes (S97 r2)
{ "id": "talk", "boxes": [["Type 3. I walk a", "square, 2 by 2."],
                          ["Each box waits", "for A now."]] }  // S97 r2: per box
{ "id": "exotic", "raw": [["box"], "Hi", ["br"], ["bytes","0xF7","0xF0"]] }
```

**`boxes` (S97 r2, what the editor writes)**: each box = 1-2 lines; box 1
line 1 ≤ 16 cells (after "*:"), every other line ≤ 18 (cells = charmap
glyphs, ".." = one); boxes join with `$FA $F7 $EF $EE` (wait for A, clear);
end `$F7 $F0`, or `$E7 $F0` right after the question (vanilla choice form).
Violations are errors — TEXT_SYSTEM "Text boxes" (lost cells, scrolling).
The auto `text` form now flows into boxes (`textenc.flow_boxes`) instead of
one scrolling page. `lines` is unchanged (regression-grade; the example
uses it) and warns when it has > 2 lines or a first line > 16 cells.
`lines` form opens with the standard box (`$EA $9F $A3`), join lines
with `$EF $EE`, and terminate `$F7 $F0` (plain; trailing break dropped) or
`$E7 $F0` (`choice: true`; trailing break kept) — the proven byte shapes
(TEXT_SYSTEM). `raw` is the escape hatch: tokens `box`, `br`, any control
name from TEXT_SYSTEM (`choice`, `wait`, `hero`…), `["bytes", …]`.
Strings emit as `db "…"` and rely on the **global charmap**
(`disassembly/charmap.asm`, included by `game.asm` line 86). The safe
character set excludes anything the charmap doesn't define (`-` is
rejected, not guessed). **No DTE in v1** — matches the proven hand-authored
custom text; a space-optimising DTE pass is a future flag.

### 2.4 `custom.scripts[]`

```jsonc
{ "id": "give_jerky", "ops": [
    ["text", "jerky_offer"],                       // dialogue id or "$0A00"
    ["op", "check_and_branch", "0xC83C", 1, "@declined"],
    ["op", "give_item", "ITEM_BEEF_JERKY"],        // symbols pass through
    ["end"],                                       // dw $FFFF
    "label:declined",
    ["text", "jerky_declined"], ["end"] ] }
```

Serialisation = 1 word per opcode (`$FFxx`) + 1 word per param — identical
to the proven hand-authored scripts. Params: ints, hex strings, `@label`
(local branch, resolved per-script), or RGBDS symbols
(`wCustomStep_Room6C_S0`, `ITEM_BEEF_JERKY`). Param counts in
`editor2/core/scriptgen.py:OPS` are verified against the **handler code /
per-opcode reference block in `patches/bank_004.asm`** — NOT against
`tools/compile_script.py` (see §8 defect). Unknown opcodes: use a hex name
(`["op", "0x2E", …]`) with explicit params (count-warned only).

### 2.5 `custom.palettes[]`

`{id, label, placement: "a"|"b", colors_rgb555: 8×[4 words], comment[],
row_comments[]}`. `placement` pins the block to region A (between the
`ds 12` reserve and `HighBattlePal` — where the proven `_6B/_6C` blocks
live) or region B (after the tables — `_6D/_70`); it exists purely for
layout stability of the as-built file; new palettes default to `b`.
Validators: exactly 8×4 (the S6 dropped-8th-line bug corrupted dialog
rendering); **warn** when idx1≠`$6BFF` / idx3≠`$0000` (engine forces both
at runtime — KEY_LESSONS S7/S39). Loader code (`CustomPalCheck`) only ever
loads slots 0–3 (KEY_LESSONS S8).

### 2.6 `custom.wram` + step counters

```jsonc
"wram": { "region_size": 640,
          "reserved": [ { "label": "wCustomStep_Room6C_S5",
                          "addr": "0xCD84", "comment": "legacy hole" } ] }
```

Step counters allocate from **`$CD80`** (S65 migration into the CF3-freed
window `$CC80-$D664`; history: `$D478` S53 → refuted S54 → `$DE74` S55 →
`$CD80` S65 — the `$DE74` reserve capped at ~106 B, far short of one counter
per authored screen at campaign scale). Region default/max = **640 B**
(`$CD80-$CFFF`; the hard cap is the `$D000` wram0 section boundary,
validated at load). The window is **TRANSIENT, permanently**: its SRAM
image (`$A3BA-$AD9E`) is CF3's live farm storage, so the save copy skips it
in both directions — persistent room state stays event flags + entry
scripts (user decision S55, reaffirmed S65). Deterministic init is
GUARANTEED: ClearAllWRAM at power-on, `CF3NewGameClear` at new game, and
the S65 bank `$73` entry 6 tail-clear after the main-image restore copy —
gameplay always starts with the window zeroed (reload-in-room shows step-0
content BY DESIGN). Allocation order: reserved entries claim first, then
explicit `step_counter` dicts, then `auto` in room/screen order, skipping
used addresses; the emitted region is `ds`-padded to `region_size` for
layout stability. `wRoomRecScratch` stays pinned at `$DE7B` by a static
`ds 7` pad in `patches/wram.asm` (no longer coupled to this region). The
relocated `wCustomNPCBuffer`/`wCustomExitBuffer` (`$CC80`/`$CD00`) and the
`wCustomPool` reserve (S65 `$D001-$D664`; now `$D0C5-$D5E4` after the FX1 and
S97 r2 carves — see `patches/wram.asm`) are hand-declared in
`patches/wram.asm`, not compiler-emitted. The example project's auto
allocation reproduces the proven relative layout at the new base (legacy
hole `0xCD84`, was `0xDE78`/`0xD47C`).

### 2.7 `custom.flags[]`

`{name, index: "auto"|"0x0158"}` → allocated from the EVENT_FLAGS.md
safe+persistent pool (**`$0158–$0167` = 16 flags** — the S57 per-byte
audit; `$01E0–$01EF` was retired S73 to `wAnchorGate`/`wAnchorFloor`, so the
"32 flags" this line said until S100 was stale — DOC_AUDIT S100; the
previously listed "broader" ranges were refuted, see EVENT_FLAGS "Free Flag
Slots"), never the collision zones or the
non-SRAM `$0278+` range. Resolved indices appear in the manifest; scripts
reference flags by the resolved value (a name→`set_flag` sugar is a v1.1
nicety). The example project uses none (the proven content predates named
flags).

### 2.8 `build`

```jsonc
"build": {
  "compat": { "master_table_rooms": ["0x6B","0x6C","0x6D"] },  // see §7
  "bank_map": { "0x60": "…", "0x71": "…", "0x17": "…", "0x64": "…" } }
```

`bank_map` is documentation-grade today (ownership is enforced by the
emitter registry); it exists so multi-bank spill has a declared home when
content outgrows `$60`.

### 2.9 `custom.music` (M3b/M3c, S64)

```jsonc
"music": {
  "libraries": [ "extracted/dwm2_song_library.json",     // repo-relative
                 "extracted/midi_song_library.json" ],
  "songs": [
    { "id": "dwm2_bgm07",                 // project-local song id
      "source": { "library": "dwm2_bgm07" },   // or {"inline":{"channels":[…]}}
      "first_id": "0xA1" },               // or "auto": allocates from $9E
    …
  ],
  "room_defaults": {
    "0x12": "dq6_town1",                  // ANY mapID $00-$7F: vanilla too
    "0x30": "0x09" }                      // raw value = INBUILT vanilla BGM id
}
```

plus per-room sugar `custom.rooms[].music: "<song id>"` (merged into
`room_defaults`; a conflicting explicit `room_defaults` entry for the same
mapID is an ERROR, not last-wins).

Resolution (`editor2/core/music.py`): library refs pull channels from the
repo-committed catalog JSONs (`song_codec.py extract-gbs-library` for the
full 31-song DWM2 set; `tools/midi_to_song.py` for MIDI conversions).
`first_id` allocation: explicit claims first, then `auto` fills upward from
`$9E`; each song reserves consecutive ids per channel; overlap/out-of-range
($9E–$FC) = error. Every BGM is normalized to the exact pulse1/pulse2/wave
trio (slots $34/$4E/$68): missing slots pad with a 6-byte silent stream
(InitBGM starts 3 CONSECUTIVE ids — an unpadded 2ch song would start its
neighbor's first channel as its own third); channels outside the trio drop
with a warning (SOUND_SYSTEM §8; InitBGM channel-count extension = ROADMAP
box). `room_defaults` values: song id → its `first_id`; raw number = used
verbatim (vanilla music assignment); id 0 = the no-assignment sentinel and
is rejected. Output: the 128-entry `CustomRoomBGMTable` in bank $71 (read
by template entry 2 `CustomRoomBGMResolve` for the rewritten
`LoadNewBGMIdIntoA`, patches/bank_001.asm — SOUND_SYSTEM §8) + the whole
generated `patches/bank_074.asm` via `song_codec.song_bank_asm` (fixed
95-slot record area: adding songs never moves existing streams — the S63
byte-identity property, re-verified S64 when `custom_songs.json` retired).
Capacity is validated up front: stream total ≤ 16,000 B ($4180–$7FFF).

---

## 3. Pipeline

```
Project.load ──► content validate ──► emit ×2 (determinism) ──► accounting
   (schema,        (errors abort;        (identical or abort)     validate
    hard-errors     warnings shown)                                (bank space)
    on stubs)                                     │
                                                  ▼
                              splice @BUILD_PROJECT regions into copies of
                              patches/bank_017.asm + patches/wram.asm
                                                  │
                write <out>/patches/… ────────────┘
                     │ --build
                     ▼
   stage patches/ over disassembly/ (same PATCH_FILES/PATCH_NEW_FILES lists
   as verify_integrity.py check 2 — parsed from that script, one source of
   truth), overlay <out>/patches/, `make`, capture rom.gbc + game.sym into
   <out>/build/, ALWAYS restore the tree, write manifest.json
```

Content validation runs **before** emit so schema errors surface as
validator messages, not emitter crashes; bank accounting runs **after**
emit (it measures the generated text) and before rgbasm (which reports
only the first excess byte — KEY_LESSONS S52 #3). Determinism is enforced
per compile (emit twice, byte-compare) and is what makes ROM bisection
meaningful.

### `@BUILD_PROJECT` regions

Marker syntax inside a hand-maintained patch file (byte-neutral comments,
added S53 — integrity PASS proves neutrality):

```
; @BUILD_PROJECT BEGIN <name>
…generated content…
; @BUILD_PROJECT END <name>
```

| Region | File | Content |
|---|---|---|
| `wram_step_counters` | `patches/wram.asm` | step-counter labels `$DE74+` (S55 relocation), `ds`-padded to `region_size` |
| `room_palettes_a` | `patches/bank_017.asm` | placement-`a` palette blocks (`_6B`,`_6C`) |
| `room_render_tables` | `patches/bank_017.asm` | `CustomRoomPalPtr` + `CustomRoomAttr` (one row/room) + placement-`b` palettes |

The splicer keeps the markers (idempotent re-runs) and errors on a missing
or duplicated pair. If a marker is ever lost, restore it around the same
content — the compiler refuses to guess boundaries.

---

## 4. Emitter registry

`editor2/core/emitters.py:REGISTRY` — each emitter declares its schema
section, its output target, and its owned banks. Adding a subsystem =
registering an emitter; nothing existing changes.

| Emitter | Consumes | Target | Banks |
|---|---|---|---|
| `rooms60` | `custom.rooms/scripts/dialogue` | `file:patches/bank_060.asm` | `$60` |
| `dispatch71` | `custom.rooms` (records, encounters, animation S99) + `custom.music` (room BGM table, S64) | `file:patches/bank_071.asm` | `$71` |
| `palettes_a` | `custom.palettes` (placement a) | `region:…#room_palettes_a` | `$17` |
| `render17` | `custom.rooms` (+ placement-b palettes) | `region:…#room_render_tables` | `$17` |
| `wram_steps` | `custom.rooms` + `custom.wram` | `region:…#wram_step_counters` | — |
| `music74` | `custom.music` (+ `rooms[].music`) | `file:patches/bank_074.asm` | `$74` |
| `tileanim6c` (S102) | `custom.rooms[].tile_anims` | `file:patches/bank_06c.asm` | `$6C` |
| `gd_monsters` `gd_enemies` `gd_encounters` `gd_family` `gd_special` `gd_exp_curves` `gd_growth_curves` `gd_skill_learn` `gd_skill_mp` `gd_skill_records` `gd_library` `gd_library_text` (S103) | `gamedata` (§2.20) | `region:` in banks $03 / $14 / $01 / $16 / $69 / $13 / $13 / $06 / $07 / $54 / $12 / $4D | those banks |

`bank_060` generated layout order (fixed, deterministic): script master
table → shared no-op (if needed) → per-room script tables+bodies (script
area) → two-level text tables → text bodies → `CustomSourceMapTable` →
`CustomRoomPtrTable` → per-room data (inline-placement rooms emit their
scripts just before their subtable; the shared dummy subtable is emitted at
the first placeholder's position) — matching the proven file's layout.

---

## 5. Engine templates + pinning

The engine halves of the two owned banks are **verbatim snapshots** of the
user-confirmed hand-authored code:

* `editor2/core/templates/bank_060_head.asm` — bank byte, 7-entry `rst $10`
  table, `CustomPtrChase`, `DummyStepEntry/NPCs/Exits`, entries 0–6
  (readers, `GateAwareDispatch`, `CustomScriptRead`, `CustomTextDisplay`).
* `editor2/core/templates/bank_06b_head.asm` (S101) — bank byte, 1-entry
  table, `CopyEnemyRowExt` (project enemy rows, §2.18).
* `editor2/core/templates/bank_06c_head.asm` (S102) — bank byte, 1-entry
  table, `CustomTileAnimate` / `TileAnimRestart` / `TileAnimCopy` (the rooms'
  own tile animations, §2.19).
* `editor2/core/templates/bank_071_head.asm` — bank byte, 6-entry table
  (S100; 4 S99, 3 S64), `CopyCustomRoomRecord`, `CustomEncResolve` (S100:
  gate byte $FF = follow the dive, no pin), `CustomRoomBGMResolve` (entry 2:
  E := `CustomRoomBGMTable[wMapID]` or 0; gate floors return 0 — SOUND_SYSTEM
  §8), `CustomAnimSource` (entry 3, S99: E := the room's animation source —
  §2.15), `CustomGateInsert` (entry 4, S100 — §2.16), `CustomRoomFlags`
  (entry 5, S100 — §2.16).

Two pins, both enforced at compile time:

1. **sha256** in `editor2/core/templates/PINNED_SHA256` — a drifted
   template refuses to compile. Re-pin (`--pin-templates`) ONLY after a
   deliberate engine session changes the head. Re-pinned S64 (bank $71
   entry 2 added: `64cb43ee…be23`; bank $60 unchanged `63969b1a…33d9`); re-pinned S99 (bank $71 entry 3 added: `99b8eb7b…a708`, historical
   S64 value `64cb43ee…be23`); re-pinned S100 (bank $71 entries 4/5 +
   entry-1 follow test: `4c36c4ca…0d6e`; S99 value `99b8eb7b…a708` historical). Re-pinned S101: bank $60 `d90b9761…4dfd` (`CustomMonsterCast`),
   bank $71 `dff1234a…ccd2` (`CustomRoomBGMResolve` custom-boss path), new
   bank $6B `cff4507a…a2c5`; the S100 values are historical. Re-pinned
   S102: bank $71 (entry 3 `CustomAnimSource` far-calls bank $6C first) and
   the new bank $6C head; the S101 bank $71 value `dff1234a…ccd2` is
   historical (current values: `templates/PINNED_SHA256`).
2. **TEMPLATE_SIZE** in `editor2/core/validators.py` — measured from the
   reference `game.sym` (S102: `$71` = **444 B**, new `$6C` = **285 B** —
   `TileAnimRoomTable @ $411D`; S101: bank `$60` = **549 B**, `$71` = 440 B,
   new `$6B` = **53 B** — `ProjectEnemyRows @ $4035`; the older figures
   below are history): bank `$60` head = **283 B**
   (`CustomScriptMasterTable @ $411B`, S53), bank `$71` head = **395 B**
   (`Custom26DDTable @ $418B`, S100; history 103 S53 → 116 S55 flag fix →
   142 S64 entry-2 dw + resolver → 164 S99 entry-3 dw + CustomAnimSource,
   §2.15 → **395 S100** entries 4/5 + CustomGateInsert + CustomRoomFlags,
   §2.16). Used by the pre-build overflow check
   (template + counted generated payload ≤ `$4000`). Re-measure from the
   new `.sym` whenever a template is re-pinned.

Template operands that reference generated labels
(`CustomSourceMapTable`, `CustomScriptMasterTable`, …) re-resolve at link
time — that is why the fix build's bank-`$60` diff starts at `$4010`
(inside `CustomPtrChase`'s `ld hl` operand) although the template TEXT is
untouched.

---

## 6. Adding a future emitter (insertion recipes)

* **Custom skills (data half).** When authoring skills lands
  (BATTLE_SKILL_SYSTEM §13 framework), `custom.skills` stops hard-erroring
  and a `skills` emitter registers: it appends the per-skill DATA rows the
  S52 forks already read — `CustomLearnReqTable` (bank `$06` free run,
  vanilla 18-B format), `CustomMPCostTable` (bank `$07`),
  `CustomAnnounceTable` (bank `$58`), `CustomMsgPtrTable` + pool string
  (bank `$4C`), record-table high rows — via new `@BUILD_PROJECT` regions
  around those blocks, exactly like the bank-`$17` regions. Effect
  HANDLERS (bank `$72` code) stay hand/tool-authored; the schema references
  them by symbol, mirroring how rooms reference layouts.
* **Custom music.** Blocked on ROADMAP Arc 3 M1–M3 (sound engine RE). Once
  a song format exists, a `music` emitter owns a song bank the same way
  `rooms60` owns `$60`. Until then `custom.music` hard-errors.
* Pattern for any subsystem: (1) formats into `formats.py` with doc
  citations, (2) rules into `validators.py` with KEY_LESSONS citations,
  (3) an emitter with a declared target (whole free bank, or marked region
  in a hand bank), (4) regression = byte-identity of the no-op case.

---

## 7. The script master table: legacy compat vs the fix  (S53 findings #1–2)

**Routing (documented S53; grep-verified, engine unmodified).** The
room-entry script (index 0) has TWO trigger paths that set
`wScriptMapType` differently:

* **Scroll / post-battle reload** — bank `$06` `$66e3` path
  (`patches/bank_006.asm` ~line 4931): `wScriptMapType = raw wMapID` →
  bank `$04` `MapTypeDispatch` (≥`$40`) → `DispatchBank0F_Ext` → bank `$60`
  entry 6 `GateAwareDispatch` (routes by `wMapID`) → `CustomScriptRead`
  indexes `CustomScriptMasterTable[wScriptMapType − $6B]`. **This is the
  path that reaches the custom scripts.**
* **Initial room entry** — bank `$01` `$4C3E` site (`patches/bank_001.asm`
  ~line 2478): `call MapIDClampForPalette` → post-S42 that returns **`$00`
  for ALL custom rooms** → `wScriptMapType = $00` → bank `$0C` → **Castle's
  script 0** runs (benign: its actions are flag/var-guarded). The inline
  comment "`$16` for custom rooms" at that site is stale (pre-S42). This is
  the concrete mechanism behind KEY_LESSONS S11's "script 0 runs on scroll
  and reload but not dependably at initial entry".

**The latent defect.** The hand-authored master table had **3 entries**
(`$6B/$6C/$6D`) while rooms extend to `$70` (index 5). On the scroll path a
room past the table overshoots into following data and executes a garbage
"script". It never fired only because `$6E/$6F` are unreachable and `$70`
is single-screen (cannot scroll). **Compiler default = fixed:** master
width = ALL rooms; scriptless/placeholder rooms point at a shared
`CustomScriptNoop_PtrTable → dw $FFFF` (+10 bytes total).
`build.compat.master_table_rooms` reproduces the legacy narrow table for
byte-identity regression and is warned about at compile time. The fix build
(`DWM-S53-compiler-fixed-master-table.gbc`, a patched test ROM) passed the
S53 user demo loop; its only behavioral surface (scroll in rooms past the
legacy table) is unreachable in the demo content by construction, so the
loop proves non-regression rather than exercising the new no-op path.

---

## 8. Known tool defect: `compile_script.py` `set_bgm` param count  (S53 finding #3)

`tools/compile_script.py` declares `set_bgm` (opcode `$41`) with **2**
params. The handler (`$04:$669D`, `label4_669d`) advances the script
counter once and consumes **one** word (`ld a, c / call SetBGM`) — and the
user-confirmed hand-authored script uses one param. The compiler's own
table uses 1. `compile_script.py` is NOT fixed this session (out of scope;
its decompiler twin has an independent PARAM_COUNTS copy — fix both
together and re-run their round-trip tests when touched). Do not "correct"
the compiler from that tool. **S96: fixed at the source for all three
readers** — compile_script, decompile_script and extract_room take arity +
branch set from `extracted/script_param_counts.json` (the bank-$04 handler
analysis, BANK04_SCRIPT_ENGINE "Parameter counts"); scriptgen's OPS rows are
cross-checked against it (extract_room refuses a disagreement) and hex ops
in project scripts get an arity warning from it.

---

## 9. Manifest + debugging loop

`<out>/build/manifest.json` (written next to `rom.gbc` + `game.sym`):

| Field | Content |
|---|---|
| `project`, `project_sha256` | provenance of the exact input |
| `rom_md5` | the built patched ROM |
| `bank_usage` | `$60`/`$71` last-nonzero+1 (regression: 1455/129) |
| `texts` | `$0A00…` → label → `bank:addr` → dialogue id |
| `scripts` | every `*_ScrNN` body label → `bank:addr` |
| `step_counters`, `flags` | resolved WRAM addrs / flag indices |
| `symbols` | all owned-bank + region labels from `game.sym` |
| `warnings` | the compile's warning list, frozen with the build |

Debug loop: SameBoy break/watch address → look it up in `symbols`/`texts`/
`scripts` → the label names the room/script/text id → fix that field in
`project.json` → rebuild. This replaces grepping generated `.asm`.

---

## 10. Validator catalog (rule → source)

Errors: missing `screen_byte`
(KL v14-v18/S40); NPC references script index 0 or an undefined/absent
script id (KL S2); script table without index 0; text terminator not
`$F7$F0`/`$E7$F0`, bare `$EE`, non-charmap char, >18-cell line
(KL S2/TEXT_SYSTEM); coords outside 10×8; missing `record` ≥`$70`; dims
not 160/128-multiples or screens beyond dims (KL S10); non-dense mapIDs /
compat list; duplicate text ids / non-dense sections; flag outside safe
ranges (EVENT_FLAGS); step counters over region size; palette ≠ 8×4
(KL S6); bank overflow (template+payload) (KL S52); non-deterministic
emit; unresolved script labels; layer/music/skills content (§2.1).
Warnings: compat overshoot exposure (§7);
palette idx1/idx3 vs forced values (KL S7/S39); record on `<$70`;
op param-count mismatch vs the bank-004 table; auto-placeholder fill.
**S98 changes:** the "spawn script ≠ 0" error and the "missing spawn"
warning are REMOVED (the "spawn" is an examine spot — §2.14); a legacy spawn
with script 0 warns; the single-width nibble warning became the ERROR "exit
arrives on a screen the destination room does not have" (KL S40); new: edge
exits bordering a neighbour screen (warning — replaces the blanket
"boundary exit y=0/7 cannot coexist with a scroll" warning, which fired on
every edge exit even with no screen beyond; KL S10), talk-script and door
checks (§2.14).
**S100 additions:** gate insertion + gate-room checks (§2.16 "Validators") —
floor range 2..floors−1, chance 1-100, ≤ 8 once rules per gate, a served
room needs `gate_arrival` + a Stairs down and may not pin a FIXED encounter
pool (errors); ordinary exits in a served room, shadowed rules, unsaved
flags (warnings).

---

## 11. Files

```
editor2/
  core/ project.py formats.py textenc.py scriptgen.py validators.py
        animation.py         # S99 room tile animation: census access + preview Player
        emitters.py compiler.py builder.py layouts.py music.py
        render.py            # ROM-built renderer (S72; PyBoy-validated)
        render_project.py    # LIVE renderer from project.json (S93; == render.py, tested)
        document.py          # editable model: byte-exact load/save + mutations (S93)
        vanilla.py           # PIL-free vanilla room-table reader: valid steps / exits / counters (S94b)
        png_import.py        # PNG -> tiles/palettes/metatiles planning (S96)
        doors.py talk.py     # S98 door/teleport/spot mutations (DoorsMixin), talk specs (TalkMixin)
        world.py             # S98 room/warp graph + deterministic layout (World tab)
        gates.py             # S100 gate model: vanilla gates, floors, arrival px, GatesMixin
        gamedata.py          # S103 Layer A-lite: vanilla tables + gamedata overrides (§2.20)
        emulator.py
        templates/{bank_060_head.asm, bank_071_head.asm, PINNED_SHA256}
  app/  main.py session.py build_worker.py     # shell (S93), one Session per project
        rooms/ tab.py canvas.py tile_picker.py palette_panel.py minimap.py
               inspector.py commands.py       # the Rooms tab (S93)
               metatile_picker.py metatile_editor.py   # S94 metatiles
               redirect_dialog.py                      # S94b "Route a vanilla door here"
               tileset_map.py tileset_dialog.py        # S96 slot map, change tileset
               npc_panel.py rules_panel.py             # S97 NPC inspector, state rules
               talk_editor.py                          # S97 r2 per-box talk text, ROM-font preview
               door_dialog.py object_panels.py         # S98 door / teleport dialog, door/teleport/spot panels
        import_tab.py space_meter.py                   # S96 Import art tab, bank meters
        world_tab.py                                   # S98 World tab (read-only graph)
        gates_tab.py                                   # S100 Gates tab (custom rooms on gate floors)
        rooms/gate_panel.py                            # S100 inspector "Inside gates" group
  templates/blank-project/project.json   # File > New project (S94)
  example-project/project.json      # regression baseline (build/ is regenerable output)
  tests/test_compiler.py            # 121 tests (124 with --rom: the ROM builds; S100)
  tests/test_app.py                 # shell smoke test; --rom = GUI build == pin
  tests/test_canvas.py              # P3.3 acceptance; --rom = build + PyBoy both states;
                                    # v4 (S97) = state rules + NPC panel, PyBoy-verified
                                    # v5 (S98) = doors/teleport/spots/talk, PyBoy-verified
                                    # (--only-v5 runs just v5)
                                    # v6 (S99) = animated tiles; v7 (S100) = gate rooms
                                    # (--only-v6 / --only-v7)
tools/build_project.py              # CLI
```

**GUI save format (S93):** `document.py` writes `json.dumps(indent=<detected>)`
plus the file's own trailing-newline convention — the committed example
project round-trips byte-for-byte, so an editor session that changes nothing
produces no diff. The GUI never hand-edits the generated `.asm`; Build saves
project.json and runs the same `compile_project`/`build_rom` as the CLI.

**Attr grids and palettes are per (screen, state) (S94b; corrects the S93/S94
"per screen only" claim):** the vanilla attr walk indexes the screen's step
counter, so each state may carry its own `attr` item and `palette`
(§2.11). The canvas paints the grid/palette in effect for the state shown
and says which item that is.

## §2.11 S94 schema additions (editor canvas v2)

**`record` is REQUIRED for every non-placeholder room** (any mapID). Rows
`$6B-$6F` are emitted into the ROM0 `$26DD` table by the `rom0_records`
emitter (`@BUILD_PROJECT rom0_room_records` in patches/bank_000.asm, 40 B,
labels preserved — GATE_GENERATION §7); `$70+` into `Custom26DDTable` as
before. Placeholder / undeclared `$6B-$6F` rows keep the vanilla filler.

**4×4 screen grid**: `screens` keys `"0".."15"` (index = row×4 + col, the
engine's scroll grid — capacities.json); the sub-table width is
`(top_row+1)×4`; `record.width_px/height_px` must cover the occupied
columns/rows (validator) and may not exceed 4×4.

**Per-(screen, STATE) attr + palette tables in the VANILLA format** (S94b;
engine change, template-free — patches/bank_017.asm `CustomAttrCheck` +
`CustomPalCheck`; supersedes the S94 interim 17-byte per-screen map). Bank
$17's `room_render_tables` region emits `CustomAttrPtrTable` (one `dw` per
custom room; `$0000` = no custom attr → the vanilla `AttrPtrTable` walk) →
`RoomAttr_<mid>` (16 `dw`, one per screen slot) → `ScrAttr_<mid>_<k>` =
`dw <step counter label>` then per state `db attr_entry, attr_bank` /
`dw pal_ptr`. That is exactly the vanilla row shape (`AttrPtrTable[map] →
screen table → [counter] + [attr_entry, bank, pal_ptr] per step`), so the
engine code only substitutes the table base (`A = mapID-$6B`) and the
palette path keeps slot 7 for custom rooms. Attr for (k, n) resolves as
**`states[n].attr` › the state's layout item's own `attr` › `screens[k].attr`
› the screen's layout item's own `attr` › `render.attr` › vanilla**
(`project.state_attr_entry`); palette as **`states[n].palette` ›
`render.palette` › the vanilla source palette pointer**
(`project.state_palette_ref` → project label or
`derive_room_palette.normal_room_pal_ptr`). Vanilla varies attr AND palette
per step (Servant room `$3F` burning → cleared), so a faithful clone needs
both per state. The S92 `base_entry+2` stride and its declaration-order
coupling are gone; `render.attr {bank, base_entry}` is still accepted as the
room default. All entries of one room must live in one bank. The extractor
emits `screens[k].attr = {id: <room>_attr_s<k>}` per screen; the editor's
clone adds `<rid>_s<k>_st<n>` layout/attr items and `pal_<rid>_s<k>_st<n>`
palettes only for steps that differ from step 0.

**Empty projects compile**: with no `custom.rooms`, one unreachable placeholder
at `$6B` is synthesized (warning) so every table has a row — the blank
template `editor2/templates/blank-project/project.json` builds as-is.

**`custom._editor`** (underscore = ignored by the compiler): editor-only data —
`metatiles: {<tileset key>: [{name, tiles:[tl,tr,bl,br], pal}]}` where the key
is the custom tileset id or `"<bank>:<id>"` for a vanilla tileset.

**`custom.rooms[].name`**: display name (free text); `id` stays the stable
reference. **`custom.tilesets[]` `raw2bpp` sheets may be created by the
editor** (`Document.localize_tileset` copies a room's vanilla sheet into
`assets/<id>.2bpp`; walkability flips edit that sheet — `ensure_twin`; S95
`import_metatile` copies 8×8 graphics from another room's sheet into free
slots — free = 128 − tiles placed in any layout on the tileset − author
metatiles − the slots the rooms on that sheet ANIMATE (S99: their `animation`
handlers; pre-S99 always 77/78) − the protected vocabulary of the rooms'
vanilla sources).

**`screens[k].palette` (S95):** a project palette id for one screen; resolution
`states[n].palette › screens[k].palette › render.palette › vanilla source`
(`project.state_palette_ref`, `render_project.state_palette_id`). The GUI
writes it when a screen has no `states[]` ("palette here" combo) and when a
new screen is added (it inherits the palette shown). **GUI exits (S95):**
`Document.add_exit` writes ordinary `exits[]` rows (`dest room:/vanilla:`,
`screen_byte` = destination screen, `spawn_x/y`, `gate_flag 0`) on the
current state — nothing new for the compiler.

**S96 editor-only data (`custom._editor`, ignored by the compiler):**
`metatiles[...]` entries may carry `pal` as a list of 4 slots (per subtile);
**`custom.palettes[].free_color1: true` (S96, engine-backed):** in a custom
room the palette keeps its OWN colour 1 in slots 0-3 (bank $17
FreeColor1Hook); the emitter ORs bit 15 into colour 3 of EACH of slots 0-3 as
the marker (S96 round 4; round 2 marked slot 0 only — hardware-ignored,
colour 3 is still forced black, the hook restores the bit in the buffer so
the menu's standalone reload keeps the colours); the idx1 validator
warning is skipped for slots 0-3 of such palettes; the live renderer and the
palette panel honour it. Reference patched pin moved to `07a71f20…`
(hook code only — the example project has no free palette), then to
`5db25d15…` (patched, S96 round 4: per-slot marker + bank $06 menu-open
far call to bank $73 entry 13 `MenuOpenFreePal`; code only again).
`imports: [{file, keys, regions[{rect, offset, name}], masked, walls}]` (the
Import-art tab's per-image settings; the PNG is copied to
`assets/imports/`); `tileset_origin: {tid: [bank, id] | null}` (where a sheet
came from — blank sheets have none); `released_vocab: [tid]` (P3.3c).
**Validator change S96:** screens outside the record's scroll area are a
WARNING (vanilla sub-room screens: Labyrinth, Forest Mazes), not an error.
**`compiler.measure_banks(data, dir, repo)`** returns `{bank: (used, cap)}`
for $60/$64/$67/$71 from an in-memory project (the editor's space meters;
`validators.bank_usage` is shared with the pre-build overflow check).
**Script arity:** scriptgen warns when a hex op's param count disagrees with
`extracted/script_param_counts.json`; `scriptgen.regroup_ops` re-splits a
pre-S96 clone's word stream by the handler arity (identical words — the S96
on-open migration applied it to the example project's arena clone; pin
`fc1caa98…` unchanged at the time — historical patched pin, superseded by the S96 hook pin `07a71f20…`).

**Migration on open (S95, `Document._migrate`)**: a project saved before
S94 whose rooms `$6B-$6D` lack a `record` gets the legacy hand-patched
`$26DD` rows filled in (logged "MIGRATED … Save to keep it"). The CLI
compiler stays strict (`record` required).

## §2.13 S97 — room state rules (P3.5a) + the NPC type byte (P3.5)

**`custom.rooms[].state_rules`** — ordered, room level:

```json
"state_rules": [
  {"state": 1, "when": [{"flag": "servant_beaten"},
                        {"flag": "0x0031", "is": "clear"}],
   "screens": [0], "comment": "optional"},
  {"state": 0, "when": []}
]
```

Each time a screen of the room (re)loads — entry, scroll, return from a
battle or menu — the FIRST rule whose terms ALL hold writes its `state` into
that screen's step counter; no match leaves the counter alone (scripts may
drive it; after a reload the transient $CD80 counter is 0). A term's `flag`
is a `custom.flags` name or any event flag number (vanilla story flags
included — EVENT_FLAGS.md; ≥ `$0278` warns: not saved); `is` = `set`
(default) / `clear`. `screens` limits a rule; default = every screen. A rule
applies only to screens that HAVE that state (a 1-state screen never
changes); a rule whose state exists on none of its screens is an error. An
unconditional last rule (`when: []`, no `screens`) is the editor's
"Otherwise". ≤ 8 terms per rule.

Why it exists: custom step counters are transient (§2.6) — a state reached
by a script is lost on reload; flags are saved. Rules make custom-room
versions persistent, and replace hub-side arming (`script_preludes`) for
the common case (the example project's S92 rank demo moved to a rule).

**Lowering** (`project.state_rules`, emitter `_state_rule_tables` in
`rooms60`): `CustomStateRulePtrTable` (bank $60, one `dw` per custom room,
`$0000` = none — emitted always, the template references it) → per room
`{db screen / dw step_counter / dw rules}… db $FF` → per screen
`{db state / db n_terms / n_terms × dw flag}… db $FF`, flag word bit 15 =
must be CLEAR.

**Engine** (template entry 8 `CustomStateRules`, re-pinned S97; head 383 →
**492 B**): evaluated with ROM0 `TestEventFlag` ($00:$26AE). Called from
(1) bank $17 `CustomAttrCheck`'s custom path via `StateRulesHook17`
(patches/bank_017.asm, `call` taken from the `ds 12` reserve → `ds 9`;
rst $10 to `$6008`, BC/DE/HL preserved) — this is the FIRST reader of the
counter at a room load (PyBoy hook order S97: attr/palette walk before bank
$0B Entry 0), so the state's own attr AND palette load; and (2)
`CustomReadStep` (Entry 0) before `CustomPtrChase`. Idempotent.
PyBoy (test_canvas v4 --rom): flag clear → state 0, set → state 1 with its
own palette, counter wiped → re-selected on the next load, flag cleared +
otherwise-0 → back to state 0. Reference patched pin → `6e97fd37…`
(patched; the example project's rule). (S97 round 1; round 2 → `ce24de8b…`, patched: text-box attrs, see
§2.13 "Round 2").

**NPC type byte** (`formats.npc_type_byte`; ROOM_DATA_FORMAT "NPC behaviour
types"): `facing` (bits 4-5) | `hidden` (bit 6) | `behaviour` (bits 0-3:
`stand` 0, `spin` 1, `pace_x2` 2, `square` 3, `figure8` 4, `pace_right3` 5,
`stand_fixed` 6, `stand_return` 7, `pace_x1` 8, `pace_x2_left` 9, `sway` A,
`gate_wander_meet` E, `gate_wander` F, or a number). Defaults reproduce the
pre-S97 bytes. `script` may be an int = a raw index into the room's script
table (a cloned raw entry edited in the GUI keeps its index when the table
has no id for it). Validators: unknown behaviour = error; gate-only
behaviours in a room warn; a walker whose measured path
(`formats.BEHAVIOUR_PATHS`) leaves the 10×8 screen warns.

**Editor data**: NPC edits convert a cloned `raw` entry to the typed form
with the same bytes (`Document.update_npc`); `Document.new_talk_script`
creates one `dialogue` entry (`boxes` since S97 r2; legacy `text`/`lines`
pages are read back as boxes by `talk_boxes`) + a `[text…][end]` script
registered at the next free index ≥ 1 (and a no-op index-0 entry script
when the room had none); named flags from the rules dialog are plain
`custom.flags` entries (`index: "auto"`).

**Round 2 (S97 r2) — text boxes in free-colour rooms (code only, no
schema).** The dialog box and the YES/NO box never set GBC attributes
(TEXT_SYSTEM "Text boxes"), so in a room with its own colour 1 they showed
the room's colours. Same-size far calls, all into bank $73:
`LoadMapS_6939` (bank $06, middle rows) → entry 14 `BoxRowDraw`; dialog
state 9 body → entry 15 `BoxFrameDraw` (frames + the vanilla SGB packet);
`LoadMapS_6b3d` (close) → entry 16 `BoxRowRestore`; bank $00
`ClearTextBitsRedraw` head → entry 17 `ChoiceBoxClose`; bank $56
`SetB56_48a1` head → entry 18 `ChoiceBoxOpen`. Active only when
`wIsGBC`, `wMapID ≥ CUSTOM_ROOM_START` and a slot 0-3 free-colour marker
(bit 7 of colour 3's high byte, S96) is set: the covered attrs go to
`wBoxAttrSave` (5×20) / `wChoiceAttrSave` (6×5), become 7, and are put back
cell by cell on close (`wBoxAttrMask` bits 0-4 rows, bit 5 choice). VRAM
bank-1 writes wait mode 3 → not-3 inside `di`. Other rooms: the same tiles
in the same order, attrs untouched (PyBoy: vanilla + non-free frames
pixel-identical). WRAM: 132 B carved from `wCustomPool` (now $D0C5-$D5E4).

**Round 3 (S100 r3) — the stairs / special-room descent in free-colour
rooms** (same principle, GATE_GENERATION §7.6): bank $06 `MapTrans_S10_InGate`
→ entry 19 `GateWipeAttr` (the blank rows' attrs → 7) and `MapTrans_S12`'s
end → entry 20 `GateLeaveFreePal` (buffer + HW colour 1 := cream for marked
slots, since the load fade targets the buffer's colour 1).

**LZSS limit (S100 r3).** `tools/compress_tiles.py` emits no back-reference
longer than **256** bytes (`MAX_COPY`): the game's decoder
(`$00:HandleCompressedRun`) adds 19 to the extended-length byte in 8 bits
and counts down with `dec/jr nz` (0 = 256), so 257-274 wrap to 1-18 and
everything after lands 256 bytes early. `decompress_tiles.py` decodes the
same way, so a round trip catches it (test_compiler "LZSS" cases).

## §2.14 S98 — doors, one-way teleports, examine / step-on spots, talk scripts (P3.7)

No engine or template change; the pin held (`ce24de8b…`, patched). All of
this is schema + lowering + validators over formats already in the ROM.

**Interact entries** (screen/state `npcs[]`; ROOM_DATA_FORMAT "Interact
entries ≥$80"):

```json
{"kind": "examine", "x": 1, "y": 1, "script": "read_book", "facing": "up"},
{"kind": "step",    "x": 6, "y": 5, "script": "squish"}
```

`examine` → `db $80|f, $FF, x, y, idx` (`facing` = `any` (F, default) /
`down` 0 / `left` 1 / `up` 2 / `right` 3; `formats.examine_entry`);
`step` → `db $90, $FF, x, y, idx` (`formats.step_trigger_entry`). `script`
= a script id of the room's table (or an int index). **The emitter writes
every ≥$80 entry BEFORE the NPCs** (stable partition in `_room_data`) —
both engine scans stop at the first NPC entry (measured). The legacy
`{"kind": "spawn"}` still emits `$8F` (= an examine spot, any facing) — with
script 0 it warns (A there re-runs the entry script); the old "missing
spawn" warning and the "spawn script must be 0" error are gone. Raw `$8x` /
`$9x` entries from clones are shown as examine / step spots in the editor.

**Doors** (S98 r2 — door OBJECTS; r1's "two rows sharing one id" is migrated
on open with identical bytes). A custom door = the exit rows on ONE cell (one
per state that carries it) with `"door": "<id>"`, `"name"` and, once
connected, `"link": "<partner id>"` + the ordinary dest / gate_flag /
screen_byte / spawn bytes leading to the partner's arrival. An UNCONNECTED
door (no `dest`) is dropped by `Project.screen_states` — nothing is emitted —
and warns. A vanilla door is the object `vdoor_MM_k_x_y`; connecting it
writes an `entrance_redirects` row tagged `"door": "vdoor_…"`, `"link"`
(+ `twin_of` rows for the other cell of a vanilla double door). Links are
two-way; validators warn on a one-sided or dangling link and on a door
object spanning several cells. Arrival bytes (`Document.default_arrival`,
all measured S98): the vanilla partner's own exit bytes when the door is a
vanilla door (Library → GreatTree `$88` (5,3)) in S98 r1/r2 — S98 r3: ALSO
on the door cell (user: "You arrive on tile fully always"; vanilla's own $88
lands at pixel y=320, half a cell below the door, measured on the original
ROM); every custom door → arrive ON the partner door cell (S98 r2, user: "ON TOP OF the door" — arrival never
re-fires an exit; step off and back on to go through again; PyBoy both ways).
S98 r1 rows with the old "step out" arrival (bit 7 on the partner's own
cell) are rewritten on open. **One-way teleport** = an exit row with no
`door` (the "rare object" — More ▾ → One-way teleport here…).

**Talk scripts** — a `custom.scripts[]` entry with `talk` instead of `ops`:

```json
{"id": "lab_talk", "talk": {
   "text": "lab_q", "question": true,
   "yes": {"text": "lab_yes", "set": ["lab_flag"],
           "move": {"dest": "room:$6B", "screen": 0, "x": 3, "y": 4}},
   "no":  {"text": "lab_no"}}}
```

Without `question`, one `then` block follows the text. A block may carry
`text` (dialogue id), `set` / `clear` (flag names or event-flag numbers —
`resolve_flag_ref`), `move` (`dest` room:/vanilla:, `screen`, `x`, `y`).
`Project._lower_talk_scripts` (after `_lower_quests`, idempotent) turns it
into ordinary ops: `[text]`, then for a question `check_and_branch $C83C
1 @no` (the engine leaves 0 = YES / 1 = NO in `$C83C`) + the yes block +
`end` + `label:no` + the no block + `end`; `set`/`clear` → `set_flag` /
`clear_flag`; `move` → `map_transition mid, px, py` with ABSOLUTE pixel
coordinates `((col·10 + x)·16 + 8, (row·8 + y)·16 + 8)` of the 4×4 grid
(MapTransitionFull `$0F`). PyBoy S98: the reply is shown and waited for
before the warp; a YES that sets a rule's flag and moves the player into
the same room reloads it in the rule's state. Errors: `talk` + `ops`
together, missing `text`, `then` with a question, `yes`/`no` without one,
unknown block keys, a move outside the grid. Validators: a question's text
must be a `choice` dialogue (`$E7 $F0`) — error; a choice text without a
question, or a reply that opens another YES/NO box — warning; undefined
dialogue ids and a move to a screen the destination room lacks — error.
The editor writes the `boxes` dialogue form (`<script>_text`, `_yes`,
`_no`, `_then`); a plain talk (no flags/move/question) stays in the classic
`[text][end]` ops form.

**Exit validators (S98):** an exit whose screen_byte low nibble names a
screen the destination custom room does not have = ERROR (replaces the
single-width warning; the nibble IS the 4×4 index). Edge exits: x=0/9 or
y=0 bordering another screen of the room inside the record = WARNING
"never fires" (pushing scrolls); y=7 above a neighbour screen = WARNING
(walk-on blocks walking down).

**Editor data** (`core/doors.py` DoorsMixin, `core/talk.py` TalkMixin, both
mixed into `Document`): `add_door` (unconnected) / `link_doors` /
`unlink_door` / `rename_door` / `move_door` / `set_door_states` /
`remove_door` (partner stays) / `refresh_door`, `add_teleport`, `set_exit_presence`,
`add_spot` / `update_spot`, `talk_spec` / `set_talk` / `new_talk`. Every
mutation is one undo step. `core/world.py` builds the World tab's graph
from the same data (no bytes re-derived).

## §2.15 S99 — room tile animation (`custom.rooms[].animation`, ROADMAP P3.3e)

```json
"animation": "source"      // the room's source_mapID's own animation
"animation": "none"        // no tile animation
"animation": "0x3D"        // borrow any vanilla room's animation ($00-$6A)
```

Resolved by `formats.anim_source(room)` → one byte per room in the generated
**`CustomAnimSrcTable`** (bank $71, after `RoomEncTable`, indexed
`mapID-$6B`, `ANIM_TABLE_LEN EQU <room count>`; placeholders and `none` =
**$6B**, the dispatch table's own bare-`ret` row). Read every field frame by
the new template **entry 3 `CustomAnimSource`** (E := table byte, or $6B out
of range) from the rewritten bank-$01 `PerRoomVRAMDispatch` (custom rooms
only; vanilla rooms index by `wMapID` as before). What each source animates:
ROOM_DATA_FORMAT "Animated tiles" (census `extracted/room_animations.json`).

**Absent = legacy**: the pre-S99 behaviour (Castle's handler, `$00` — tiles
77-78 roll) plus a warning. The editor migrates on open (`Document.
_migrate_animation`, user decision S99): `source` when the room still draws
with its source room's sheet (every clone; a new room made on a vanilla
tileset), else `none`. New clones get `source`, new rooms `source` (vanilla
tileset) or `none` (blank sheet).

**Validators**: a value that is not `none` / `source` / a map ID
$00-$6A is an ERROR; map `$08` (the breeding cutscene's DMG-palette pulse,
no tile effect) is an ERROR; a `spec` tileset slot that a room on the sheet
animates is a warning (replaces the fixed "77/78 no-go" warning).

**Template + pin (S99)**: `bank_071_head.asm` entry 3 + `CustomAnimSource`
(20 B) — head 142 → **164 B** (`TEMPLATE_SIZE[0x71]`), sha256 re-pinned
(`99b8eb7b…`). Reference patched md5 **`d072eb516dabc4799d830c170bbc9d9f`**
(patched; built S99, NOT yet user-tested): the bank-$01 rewrite + template +
table, and the example project's explicit `animation` values (arena_clone
`source` = $06, a bare `ret`; the rest `none`) — so slots 77/78 no longer roll
in the example rooms. Prev `ce24de8b…` (patched, historical).

## §2.16 S100 — custom rooms served on gate floors (`custom.gate_inserts[]`, ROADMAP P3.7b part 1)

```json
"gate_inserts": [                                  // tried in LIST order
  {"room": "gate_rotation",                        // a custom room id
   "gate": 1,                                      // 0-31 (extracted/gate_names.json)
   "floors": [2, 3],                               // [first, last] | [n] | n | "all"
   "chance": 50,                                   // 1-100 %
   "when": [{"flag": "demo_vault"},                // optional, AND-ed, like state rules
            {"flag": "0x0030", "is": "clear"}],
   "once_per_dive": true,                          // optional
   "comment": "..."}
]
```

plus, on the ROOM served:

```json
"gate_arrival": {"screen": 0, "x": 4, "y": 6},    // REQUIRED for a served room
"can_save": false,                                 // optional; default true
"encounters": {"enabled": true, "follow_gate": true},  // optional
"music": "<song id>"                               // optional; none = the gate's
```

and at least one **Stairs down** exit row: `{"x", "y", "stairs": "down"}` —
the compiler fills `dest 0x00 / gate_flag 0x80 / screen_byte 0x00 / spawn
0,0` (the vanilla special-room descent, GATE_GENERATION §7.5); explicit bytes
must equal those (error otherwise). The editor writes the full row + tag.

**Floor numbering** = the game's: the first floor of a gate is 1, the boss
floor is the gate's floor count (`wCurrentFloor` = floor − 1). A rule may
cover floors **2 .. floors−1**: floor 1 stays the gate's own (user scope
S100) and the boss floor is decided before the fork. `"all"` = that range.

**Lowering** (`Project.gate_insert_rows`, emitter `_gate_insert_table`):
**`GateInsertTable`** in bank $71, records `[gate, floor_lo, floor_hi
(0-based), chance, once_bit, mapID, spawn_x lo/hi, spawn_y lo/hi, n_terms]`
+ `n_terms × dw flag` (bit 15 = must be CLEAR), `$FF`-terminated. Spawn =
`16·(col·10 + x) + 8`, `16·(row·8 + y) + 8` from `gate_arrival` (screen k:
col = k mod 4, row = k div 4 — standing positions are 8 mod 16). Once bits
are allocated per gate in list order (max 8 per gate: one bit each in
`wGateDiveMask`). **`CustomRoomFlagsTable`** (1 B/room, `ROOMFLAGS_TABLE_LEN`,
bit 0 = `can_save` false). `encounters.follow_gate` → `RoomEncTable` gate
byte **$FF** (entry 1 then never pins `wGateID`/`wCurrentFloor`).

**Engine** (template entries 4 + 5, GATE_GENERATION §7.6 for the measured
behaviour): bank $16 `GateDecisionFork` (hand patch, rewritten S100) calls
**entry 4 `CustomGateInsert`** on every non-boss floor after the Anchor
check: the first record whose gate, floor range, once bit and flag terms
hold rolls `RNG16 mod 100 < chance` (100 = no roll) — so a gate without
applicable rules draws no RNG and behaves byte-for-byte vanilla; a hit
writes `wMapID`, `wInGateworld = 0`, the spawn pixels and the once bit (E=1),
a miss tries the next record, no hit → E=0 and the vanilla gating runs.
`wGateDiveGate`/`wGateDiveMask` ($DEBC/$DEBD, transient) reset on floor 0 or
a different gate and ride the explicit save through SRAM `$BFCA/$BFCB`
(bank $73 entries 5/6). **Entry 5 `CustomRoomFlags`** (E := flags byte) is
read by the bank $07 `SaveAllowCheck` same-size rewrite.

**Validators** (`_validate_gates`): unknown keys / missing room / gate out of
0-31 / floor < 2 / floor ≥ the boss floor / backwards range / chance outside
1-100 / > 8 terms / > 8 once rules on one gate = ERROR; a served room with
no `gate_arrival`, no Stairs down, or a FIXED encounter pool (pinning would
switch the dive to that gate) = ERROR; ordinary exits in a served room
(they leave the dive) = warning; a rule shadowed by an earlier 100 % /
no-terms / not-once rule covering its floors = warning; flags ≥ $0278 =
warning (not saved); `follow_gate` without `enabled` = warning; a served
room that is also a door / redirect destination = warning (entered outside a
dive, its Stairs down drops the player into a floor of the last gate dived).

**Template + pin (S100)**: `bank_071_head.asm` + entries 4/5 (dw),
`CustomGateInsert`, `CustomRoomFlags`, entry 1's `$FF` test — head 164 →
**395 B** (`TEMPLATE_SIZE[0x71]`), sha256 re-pinned (`4c36c4ca…`). Reference
patched md5 **`7cd7257b94004fdf8b406138dc7122e1`** (patched; built S100 r3, NOT
yet user-tested — r3: the free-colour descent-transition fix, bank $06 +
bank $73 entries 19/20, and the LZSS MAX_COPY 256 re-encode of the example
sheet; r2 `91202c74…` patched, historical): the engine above + the bank $07/$16/$73/wram hand patches
+ the example project's `gate_rotation` served on Villager floors 2-3 at
50 %, at most once per dive (was: every non-boss Villager floor, hard-coded
S41). Prev `4f13d2af…` (patched, historical — the same rule without
`once_per_dive`, so it could land on both floors), `d072eb51…` (patched,
historical).

## §2.17 S101 — gate settings + custom boss floors (`custom.gates[]`, ROADMAP P3.7b part 2)

```json
"gates": [
  {"gate": 1, "floors": 4, "boss": "ember_court"},          // a custom room id
  {"gate": 0, "floors": 3, "boss": "thorn_arena", "hand_made": true},
  {"gate": 2, "boss": "vanilla:$31"}                         // another gate's vanilla boss room
]
```

`floors` 2-99 = the gate's floor count INCLUDING the boss floor (byte 3);
`boss` = a custom room (byte 4 = its mapID, bytes 5/6 = its `gate_arrival`
cell as absolute tiles, `col·10 + x` / `row·8 + y` — REQUIRED) or
`vanilla:$xx` (a vanilla boss map; bytes 5/6 = the owning vanilla gate's
spawn, `extracted/gate_names.json` `boss_spawn`); `hand_made` = rules may
take floor 1 (`gate_min_floor` 1). Omitted keys keep the vanilla bytes; a
gate without an entry is emitted verbatim. Lowering: `Project.gate_configs()`
→ emitter **`gates16`** = region `bank_016#gate_floor_table`
(`GateFloorDataTable`, 32 rows × 8 B; bytes 0-2 and 7 vanilla — private
floor-type rows are open). `floors` also bounds `gate_inserts` (§2.16: 2 ..
N−1, or 1 .. N−1 when hand-made) and the Gates-tab floor plan.

A custom boss room gets `room_flags` no-saving by DEFAULT (explicit
`can_save: true` wins, with a warning). Music: `CustomRoomBGMResolve`
(bank $71 entry 2) plays the boss room's song on the floor before it (or $34
without one — warning "no song"). **Validators:** unknown keys / gate outside
0-31 / duplicate gate / floors outside 2-99 / missing boss room / boss room
without `gate_arrival` / `vanilla:$xx` that is not a vanilla boss map =
ERROR; boss room with a fixed encounter pool = ERROR; boss room also served
by a rule, boss mapID > $7F, no song, `can_save: true` = warning; a
hand-made gate floor with no room always served = warning.

## §2.18 S101 — conversations (`talk.steps`), monster NPCs, project enemies

**Conversation** — a script whose `talk` holds `steps` (the editor's
Conversation dialog writes it; texts are `dialogue` ids, the dialog stores
them as `<script>_sayN` / `_askN` (`choice: true`) / `_helperN`):

```json
{"id": "ember_court_lord", "talk": {"steps": [
  {"if": [{"flag": "ember_won", "is": "set"}],
   "then": [{"say": "…"}, {"helper": {…}}],
   "else": [
     {"ask": "ember_court_lord_ask5", "yes": [{"battle": {"enemies": ["ember_lord", 327, 327]}}],
                                       "no":  [{"say": "…"}, {"end": true}]},
     {"set": ["ember_won"]},
     {"helper": {"dest": "room:$75", "screen": 0, "x": 4, "y": 4,
                 "land": {"x": 5, "y": 3}, "say": "…", "sprite": "0x21"}}]}],
  "on_arrival": false, "screen": 0}}
```

Step kinds (exactly one key each): `say` · `ask` (+ `yes` / `no`; both
branches rejoin) · `if` (terms `{flag, is: set|clear}` AND-ed; + `then` /
`else`) · `set` / `clear` (flag list) · `battle` `{enemies: [1-3 refs]}` (a
project enemy id or a vanilla EID 0-486 / 518) · `helper` · `move` `{dest,
screen, x, y}` · `end`. Lowering (`Project._lower_steps`): text outside an
NPC interaction gets its `init_dialog` (S70 protocol); `ask` = `text` +
`check_and_branch $C83C 1 @no`; `if` = `if_flag_clear/set … @else`; battle 1
enemy = `trigger_battle3 EID` ($5A), 2-3 = `write_ram2 $DA03/05/07`,
`write_ram $DA02 n−1`, `boss_battle` ($5B) — the steps after a battle run
only on a WIN; `move` = `map_transition`; **helper** = the vanilla boss exit:
`close_text` (when a box is open), `delay 8`, `npc_write H,0,0` (reveal),
(S101 r2) the helper's START pixels (slot +$18/+$1A, 16-bit absolute) = the
landing cell − (48, 43) px, `write_ram2 $D8E3 = $0303` (3 tiles, curve 3 —
the fly-in moves +48 / +43 px), `trigger_anim $16H` + `wait_movement`, spin
(`long_delay` + `face_up/left/down H`, then face the player), optional text,
`trigger_anim $04H` (hop), spin, `warp_fade dest,px,py` ($3B). LANDING: default = beside the PLAYER at run time — the lowering
byte-compares `$FF97` / `$FF98` (player tile, absolute) against every column
/ row of the screens that run the script and writes the start pixels for the
cell on the player's LEFT (facing right), or on their RIGHT when they stand in
a screen's column 0 (facing left); `land: {x, y}` = a fixed screen-local cell
(faces right). **At the Castle** (S101 r3): `castle: "heal"` → `write_ram
$D92B 6` (the priest's blessing + heal), `castle: "king", king_speech: $31` →
`write_ram $D9E3 code` + `write_ram $D92B 7` (that gate's King speech), just
before the `$3B` warp; both require `dest vanilla:$00`, screen 1 (validator);
speeches $30 / $3C warn (a castle NPC reads `$D9E3` too — GATE_GENERATION
§7.7). The helper NPC (sprite `helper.sprite`, default **$39
Warubou** — S101 r2, user; vanilla exits use $21 Watabou) is placed by the
compiler (`_place_helpers`): a HIDDEN NPC at one fixed slot H per script on
every screen / state that can run it (padded with hidden dummies; H = 1 +
the most real NPCs there; > 8 = error). `on_arrival: true` = the room's entry
script (index 0) — the fight-on-arrival option; `screen: k` wraps it in
`branch_screen k` (runs only on that screen). **Validators:** dialogue
exists, `ask` text has `choice`, `if` has terms, landing cell inside 10×8,
steps after a helper / move never run = warning, battle EIDs 487-517 do not
exist, ≥ 519 must be a project enemy.

**Monster NPCs** — an `npc` entry with `"monster": <species>` (sprite
emitted as $F0-$F3): `Project.monster_cast(room, screen)` collects ≤ 4
species per screen (in NPC order; > 4 or species 217-223 = error, 216 draws
blank) → `CustomMonsterCastPtrTable` (bank $60, per room `[db screen, 8 B
display list] … $FF`) read by `CustomMonsterCast` at the head of entry 8
`CustomStateRules` (writes `$D7CA` before the NPC parse; ROOM_DATA_FORMAT
"Monster NPCs").

**Project enemies** — `progression.enemies[]` (S70 rows, now in bank $6B):
`{id, eid: "auto", name?, species, level 1-99, exp, joinability 0-7 (0 =
always joins, 1-6 = sometimes by tier, 7 = never), hp, mp, atk, def, agl,
int, ai_weights[4], skills[≤4], join_as?}`. EIDs are dense from **519** in
list order (cap **640**); emitter **`enemies6b`** writes `patches/bank_06b.asm`
= template `bank_06b_head.asm` (`CopyEnemyRowExt`, pinned) + `PROJECT_EID_BASE
EQU 519`, `PROJECT_ENEMY_ROWS EQU n` + `ProjectEnemyRows` (25 B rows,
MONSTER_DATA "Enemy Stats Table" format; an empty project keeps one zero
row). `join_as` = the JOIN VERSION: emitter **`redirects14`** writes region
`bank_014#boss_redirects` = `BossRedirectTableExt` (project `[fight EID,
join EID]` pairs FIRST, then the vanilla 34, `$FFFF`; ≤ 34 project rows).
Bank $14 hand patch: `LoadEnemyStats` head → `LoadEnemyStatsExt` (EID ≥ 519
→ `ld hl, $6B00 / rst $10`, else the vanilla copy); `LookupBossRedirect`
reads `BossRedirectTableExt`. **Validators:** dense-from-519, cap, redirect
cap, `join_as` must exist, field ranges, joinable with hp > 1023 and no
join version = warning.

**Template + pin (S101)**: templates re-pinned (§5); reference patched md5
**`9c81304176bd069ec77cd4c0d2211900`** (patched; built S101, NOT yet
user-tested): the bank $14 enemy-row divert + `BossRedirectTableExt`, bank
$6B (the example's quest enemy row EID 519 moved here from the bank-$14
tail), `CustomMonsterCast` (empty cast table), the $71 BGM custom-boss path,
the `gate_floor_table` region (vanilla bytes — the example has no
`custom.gates`). The example's raw script ops were renamed to the new
opcode names (`branch_screen`, `npc_write`, …) — bytes identical. The S100
r3 pin `7cd7257b…` (below) is historical.

## §2.19 S102 — a room's OWN animated tiles (`custom.rooms[].tile_anims`)

User S102: "I just want animated tiles and for the UI to tell me wtf is
happening … I want to mostly make them myself"; "from-scratch animations with
clearly explained budget. Also if I can set speed". Lifts the S99 limits
(one vanilla animation per room, its fixed 2-16 slots, fixed rhythms). The
vanilla source (`animation`, §2.15) still runs; these run next to it.

```json
"tile_anims": [
 {"id": "cloud", "name": "Cloud",
  "motion": "flip" | "drift_right" | "drift_left" | "sway",
  "speed": 32,                    // game frames per step, 1-255
  "rows": [[112, 111, 76, 78]],   // sheet slots, row-major (left -> right)
  "frames": [["<32 hex>", ...]],  // flip: frames 2..N, one 16-byte tile per
                                  //   slot in `rows` order; frame 1 = the sheet
  "order": "loop" | "pingpong",   // flip (default loop)
  "strip": true,                  // drift/sway: pixels flow across each row
  "amplitude": 1,                 // sway: 1-3 px each way
  "where": {"layout": "…", "x": 0, "y": 0, "w": 2, "h": 1},  // editor only
  "scope": "here" | "everywhere"}]                          // editor only
```

**Engine** (`templates/bank_06c_head.asm`, compiler-owned bank **$6C**):
bank $71 entry 3 `CustomAnimSource` first far-calls bank $6C entry 0
`CustomTileAnimate` (so: custom rooms only, only when the vanilla
`PerRoomVRAMDispatch` guards pass — no animation during menus / text /
transitions, never on gate maze floors). Data: `TileAnimRoomTable` (dw per
room, index mapID-$6B, `TILEANIM_ROOMS` entries, $0000 = none) → per room a
list of GROUP records `[period, phase, seqlen, nslots, dw seq, nslots × dw
VRAM dest ($9000+slot*16)]`, `db 0` ends it; `seq` = seqlen × dw frame-block
address; frame blocks (nslots × 16 B) live in a floating `ALIGN[4]` section of
the same bank (the GDMA source must be 16-aligned and mapped). State (WRAM,
`patches/wram.asm`, carved from wCustomPool): `wTileAnimRoom` $D0C5,
`wTileAnimLeft`, `wTileAnimVBK`, `wTileAnimSrc`, `wTileAnimState` $D0CA =
2 × `TILEANIM_MAX_GROUPS` (32) bytes (timer, step). A different custom room
restarts the timers (timer := phase, step 0 = the sheet's own art).

**Every step copies a WHOLE frame** (never a relative roll / swap), so the
slot index — and the tile's walkability — never changes, and a sheet reload
mid-loop (leaving and re-entering, a battle, a menu that reloads tiles)
heals at the next step (PyBoy S102: warp to GreatTree and back → every frame
still an authored frame). Drift / sway are pre-rendered: a strip W tiles wide
= 8W one-pixel frames (hence `strip` ≤ 4 tiles); sway amplitude a = 2a+1
frames played 0,1..a..0,-1..-a..
**Timing**: at most `TILEANIM_CAP` = 8 tiles per field frame; a due group
that does not fit waits (timer 0) for the next frame. Each tile = one
General-Purpose DMA of 16 bytes started as HBlank begins (mode 3 → 0 polled
with interrupts off, like the vanilla WaitVRAM) or at once in VBlank lines
144-151; line 127 is skipped (the LYC=127 STAT job hides sprites under the
status bar — bank $00 `LCDCStateTable`). The game never uses HDMA/GDMA
(S102 audit: every `rHDMAx` operand in the disassembly is data decoded as
code). Measured on the user's save: 4-13 tiles → at most 7-8 scanlines of
the frame in bank $6C, ~1.5 lines per tile (the vanilla `$47` 2-tile swap
costs ~13); vanilla GreatTree's sway (65 lines) and Zoma (50) drop one frame
per 32, 34 lines did not. SameBoy (VRAM blocked in mode 3, like hardware):
0 mismatching tile-frames in 600 frames; negative control (HBlank wait
removed): 631 — `tools/sameboy_anim_check.py`.

**Compiler** (`editor2/core/tileanim.py`, shared with the editor): `steps`
(frames + sequence; frame 1 read from the room's sheet at build time, so
repainting the tile updates the animation), `groups` (≤ 8 slots per group,
same timing), `schedule` (greedy phases: biggest first, each takes the phase
that keeps the busiest frame lowest over the LCM horizon ≤ 4096 f), `load`
(avg tiles per frame vs 8 → the editor's "Load %"), `rom_bytes`, `problems`
(validators: own tileset copy required; motion; speed 1-255; ≤ 32 slots per
animation; a slot in one animation only, never one the room's vanilla
animation moves; flip 2-8 frames of the right size; strips equal rows ≤ 4
tiles; ≤ 32 groups per room), `Player` (the editor preview = the engine's
timers + cap). Load > 100 % is a warning. Bank accounting: `TEMPLATE_SIZE
[$6C]` 285 + payload after the `TILEANIM DATA (generated` marker + 15 pad.

**Pin (S102)**: reference **`0d60486e57edc2ad31fa28079d4fc9f8`** (patched;
built S102, NOT yet user-tested) — the example has no `tile_anims`, so bank
$6C = template + an empty table; bank $71 +4 B; wram carve. Prev
`9c813041…` (patched, historical).

## §2.20 S103 — `gamedata`: the vanilla data tables (Layer A-lite, ROADMAP P3.9)

EDITOR_DESIGN §6.2. `gamedata` is **sparse**: it holds only what the project
changes; every table is emitted as "vanilla rows + these overrides" into a
compiler-owned `@BUILD_PROJECT` region of the SAME size, in place — no code
or pointer moves. **An empty `gamedata` reproduces the ROM bytes exactly**
(test_compiler: per-table region == ROM, and `--rom` compares the built ROM
with the original at every table's address). The vanilla rows come from
`extracted/gamedata_vanilla.json` (`tools/extract_gamedata.py`, verify check
5 `--selftest`), so compiling needs no ROM. Module: `editor2/core/gamedata.py`
(`Gamedata` = the resolved tables; `Project.gamedata()` caches it;
`validators.validate` reports its errors / warnings before any emitter runs).

```jsonc
"gamedata": {
  "monsters":   {"78": {"family": 10, "growth": {"hp": 12}, "resist": {"Fire": 3},
                        "skills": [1, 2, 3], "level_cap": 50, "exp_table": 4,
                        "female_ratio": 2, "can_fly": 0, "metal_body": 0, "tier": 5}},
  "enemies":    {"1": {"species": 8, "exp": 3, "joinability": 0, "level": 1,
                       "hp": 30, "mp": 100, "atk": 10, "def": 6, "agl": 5, "int": 1,
                       "ai_weights": [100, 200, 100, 200], "skills": [233, 229]}},
  "encounters": {"0": {"rate": 3, "unk1": 1, "size_chance": [7, 0, 0],
                       "slot_chance": [3, 5, 2, 0, 0], "eids": [2, 4, 3, 0, 0],
                       "max_count": [1, 1, 1, 0, 0], "maze_size": 8}},
  "skills":     {"44": {"mp": 1, "learn": {"level": 5, "int": 30, "prereqs": [43]},
                        "record": {"party_min": 75, "party_range": 15}}},
  "exp_curves":    {"3": [99 cumulative values] | {"2": 5}},
  "growth_curves": {"5": [99 increments]       | {"10": 3}},
  "breeding":   {"family": {"37": {"p1": "Dragon", "p2": "Dragon"}, "12": null},
                 "special": {"overrides": [{"index": 187, "result": 200}],
                             "appends": [{"p1": "Snaily", "p2": "BattleRex",
                                          "min_plus": 0, "result": 224, "plus_mod": 0}]}},
  "boss_joins": {"11": 13}
}
```

| Section | Table (region) | Notes |
|---|---|---|
| `monsters` (ids 0-220) | `MonsterInfoTable` $03:$4461, 221 × 43 (`bank_003#gd_monster_info`) | MONSTER_DATA field map; growth / exp indices 0-31 (higher = code); resist by name (MONSTER_DATA order) or a list of 27; family 0-10 or its name (`"Spirit"` = 10, S104; `"Bird"`/`"Flying"`, `"Boss"`/`"???"`); ids 215-220 (combat-only) may not change family |
| `enemies` (EIDs 0-486) | `EnemyStatsTable` $14:$4C1D, 487 × 25 (`bank_014#gd_enemy_stats`) | same field names as `progression.enemies`; skills padded with $FF |
| `encounters` (pools 0-127) | `EncounterPoolData` $01:$6AAE, 128 × 26 (`bank_001#gd_encounter_pools`) | format decoded S103 (DATA_STRUCTURES "Encounter pool entry"); EIDs 0-486, a declared new species' EID (518) or a project enemy |
| `skills` (ids 0-221) | `SkillMPCostTable` $07:$570C (`bank_007#gd_skill_mp`), `SkillLearnReqTable` $06:$50E0 218 rows (`bank_006#gd_skill_learn`), `SkillRecordData` $54:$41CF (`bank_054#gd_skill_records`) | record field names = BATTLE_SKILL_SYSTEM §7; `learn` for ids $DA-$DD is an ERROR (FieldStateDispatch code) |
| `exp_curves` / `growth_curves` | $13:$41E6 / $13:$6706 (`bank_013#gd_exp_curves` / `#gd_growth_curves`) | new hand patch `patches/bank_013.asm` (the clean bank + two markers) |
| `breeding.family` (slots 0-214) | `FamilyRecipeTable` $16:$4974 (`bank_016#gd_family_recipes`) | `null` = no recipe ($FF,$FF); matchers as `build_breeding.py` (family / species name, id, $hex). S104: `"Spirit"` = `$FA` on either side; `"AnyFamily"` / `"any"` are an ERROR (the patched family scan no longer has the wildcard) |
| `breeding.special` | the LIVE table in bank $69 (`bank_069#gd_special_recipes`; the $16 copy is runtime-dead, B2) | B5 semantics ported: overrides by `index` or `match`, appends past 824; the whole-table shadow check (ERROR: a dead append / a shadowed override) |
| `families` (S104 r2) | `FamilyTextPtrTable11` bank $6D (`bank_06d#gd_family_voices`, 11 dw) + the Spirit name pool in bank $41's dead fill (`bank_041#gd_spirit_names`, fixed 55 B) | `<family>.dialogue` = voice `A`-`D` or a family name ("talks like"); `spirit.names` = 8 names, 1-4 letters A-Z / a-z (`A` = $24, `a` = $3E); names only for Spirit (the other pools stay vanilla). Editor: the Families tab |
| `boss_joins` | the vanilla 34 rows inside `BossRedirectTableExt` (`redirects14`) | only for the 34 vanilla fight EIDs; new pairs = `progression.enemies[].join_as` |
| (derived) | `LibFamilyPtrTable` bank $12 (`bank_012#gd_library_grouping`) | library tabs from the effective family bytes (+ new species) — B7/B9 format |
| (derived) | bank $4D recipe TEXT (`bank_04d#gd_library_text`) | coherence Set 1: every family slot the project changed gets its encyclopedia string regenerated **in place** (EN strings are 18 chars + $F0 = the slot; the dispatch pointer never moves because entries 5-10 double as the $4007 mode 2-7 bases — TEXT_SYSTEM) |

**Anchors.** Six mgbdis labels inside `MonsterInfoTable` and three inside
`EncounterPoolData` are referenced by other code in those banks (bytes that
are mostly data decoded as code). `gamedata.ANCHORS` re-emits each at its byte
offset (a row an anchor falls into is written as split `db` chunks), so the
overlay still links; `EncounterPool_NNN` / `EnemyStats_NNN` /
`MonsterInfo_NNN_<Name>` / `ExpCurve_NN` / `GrowthCurve_NN` row labels are kept.

**Validators** (ERROR): unknown sections / fields, every range above, a
protected species' family, a learn row past $D9, an encounter list whose
1/2/3-monster or slot chances sum under 100 % (CalcEncounterPoolIdx would walk
off the list), a slot with a chance but no EID, a pool that can draw 2-3
monsters with no slot allowed twice (measured freeze, DATA_STRUCTURES), a
3-monster pool whose max counts allow fewer than 3 copies, an EID that does
not exist, a shadowed special append / override, `boss_joins` outside the 34,
more than 1650 special entries, > 32 members in one library family.
(WARN): combat-only species edits; an enemy row's species change (Set 3:
resistances follow the species) and, on a boss fight row, its join row (Set 2);
joinable with HP > 1023; the same EID twice in a pool (S77); a skill's MP
changed while record +4 (`mp_byte`, reader untraced — 218/222 vanilla rows
equal the MP cost's low byte) keeps the old value; decreasing cumulative exp;
the family / special shadow reports ported from build_breeding.py.

**Retired tool paths (S103)** — they wrote the same bytes and would overwrite
the regions: `build_breeding.py --emit-family / --emit-special /
--emit-relocation`, `build_family_reassign.py --emit`,
`build_library_table.py --emit`, and `build_new_species.py`'s bank $14 / bank
$01 writes (bank_06a stays). Their `--selftest`s still run (verify check 5).
Their JSON specs (`breeding_family_defaults.json`, `breeding_special.json`,
`spirit_family.json`, `breeding_family_reassign.json`) are HISTORICAL inputs:
the example project's `gamedata` re-expresses what they produced.

**Pin (S103)**: reference **`5d1dbc5f50aa46717d662bdc83b3cad4`** (patched;
built S103, NOT yet user-tested). The example's `gamedata` re-expresses the
pre-S103 hand edits (Spirit Dracky / Darkdrium, starter EID 1 test harness,
Gorbunok pool 0, B4 family recipes, B5 special overrides + appends) — byte-
identical — EXCEPT the library text, which now matches the 4 B4 recipes
(DrakSlime / GreatDrak / Almiraj / Wyvern): 17 B in bank $4D + header. Prev
`0d60486e…` (patched, historical).

**S104 (P3.10a Spirit).** No new section: Spirit is family 10 everywhere the
tables take a family (`monsters.N.family`, matchers `$FA`), the library
recipe token for `$FA` is `<glyph $1A>family` (`gamedata.SPIRIT_TOKEN`), and
the special-table shadow check no longer treats a `$FA` mate matcher as a
wildcard. The engine half (bank `$6D` family systems, the five same-size
forks, `$FA` exact in bank `$16`) is hand-authored (`patches/bank_06d.asm`;
BREEDING_SYSTEM "Spirit — the 11th family (S104)"). **Pin (S104):**
**`eee9f5b08b2f847291103961385099d9`** (patched; built S104, NOT yet
user-tested) — no example `project.json` change; the delta is the engine
bytes. Prev `5d1dbc5f…` (patched, historical; S103 user-confirmed).
**S104 r2:** `gamedata.families` (voices + Spirit names, two new regions;
empty == the r1 bytes) and the user-picked ghost-wisp icon → pin
**`eb1535108cdbc9ac24d64dce3db5591e`** (patched; built S104 r2, NOT yet
user-tested). Prev `eee9f5b0…` (patched, historical). **S104 r3:** the
library-list buffer fix (bank $12 `LibScanByFamily` → wMonList) → pin
**`d7b762db217656f4432f115c25b39418`** (patched; built S104 r3, NOT yet
user-tested). Prev `eb153510…` (patched, historical). **S104 r4:** bank $73
R4 restore fix (save lost after a reset) → pin
**`e994173e6086fd9f3cfe5095e3f9ba65`** (patched; built S104 r4, NOT yet
user-tested; USER-CONFIRMED 2026-09-30). Prev `d7b762db…` (patched, historical).
**S104 r5:** library tab display order (Spirit before ???) → pin
**`15f21834385eb38e3650d434c622eda2`** (patched; built S104 r5,
USER-CONFIRMED 2026-09-30). Prev `e994173e…` (patched, historical).

## §2.12 S94b `custom.entrance_redirects[]` — route a vanilla door into a custom room

The user's "fastest way to test": hook a custom room onto a door the player
already walks through. One row per door:

```json
{"mapID": "0x01", "screen": 8, "x": 5, "y": 3,
 "dest": "room:$72", "screen_byte": "0x01", "spawn_x": 4, "spawn_y": 7,
 "comment": "GreatTree 2F Library door -> arena_clone screen 1"}
```

`mapID`/`screen` = the vanilla room and screen index (row×4+col) that owns
the door; `x`,`y` = its walk cell; `dest` = `room:$xx` (custom) or
`vanilla:$xx`; `screen_byte` = destination screen (bit 7 = spawn y+8 as in
every exit row — never guessed); `spawn_x/y` = arrival cell; `gate_flag`
defaults 0 (custom destinations must be 0).

**Lowering** (`project.py _lower_entrance_redirects`, before validation): rows
are grouped by (mapID, screen); for each group the compiler reads the
screen's VALID vanilla steps from `extracted/map_table.json`
(`editor2/core/vanilla.py`, the same prefix filter the renderer uses:
tileset bank ∈ $23-$31/$37/$38, pointers in $4000-$7FFF, NPC coords < 16 —
the dump's step lists run past the real block into phantom rows, DOC_AUDIT
S91), rebuilds EVERY step's full exit list (all 7-byte rows up to `$FF`,
including the x=0/x=9 edge rows the dump labels "arrival_point"/
"special_marker") and substitutes only the matching (x, y) row — a redirect
on a cell with no vanilla exit APPENDS a door. The result is an ordinary
`vanilla_exit_extensions` entry with `screen` and `step_counter` = the
screen's vanilla counter, so everything downstream (emitter, validator,
`VanillaExitResolve`) is the S70 machinery. Manual `vanilla_exit_extensions`
entries and redirects may not overlap: one override per (room, screen), and an
`'any'`-screen row may not coexist with per-screen rows of the same map
(validator — the engine takes the first matching row).

**Engine (S94b):** `VanillaExitExtTable` rows are `db mapID, screen` (`$FF` =
any screen, the S70 semantics) / `dw step_counter` / `db n_steps` / `dw`
variants; template `VanillaExitResolve` compares `wScreenIndex` against the
screen byte (head 358 → **383 B**, `TEMPLATE_SIZE[0x60]=383`, re-pinned).
**bank $0B `RoomEntry9`** (boundary push exits, y=0/7) now calls `$6007` too
(same-size in-place rewrite: `rst $10` divert + `SharedPtrChase` fallback +
5 `nop`), so extension rows on the boundary are LIVE — the S70 "y=0/7 rows
are inert" caveat is gone. `Exit_GreatTree_s8` in patches/bank_00b.asm holds
VANILLA bytes again; the S92 Library-door repoint and the S1-era `(4,5)→$6B`
entrance live in the example project as redirects.

**Editor:** inspector "Entrances — how the player gets here" lists the
redirects into the room (`Document.redirects_to`), "Route a vanilla door
here…" opens `rooms/redirect_dialog.py` (room → screen → door, previews with
E/R/IN boxes, wall warning on the arrival cell); in the vanilla view an exit
marker's Selection panel offers "Route this door into a custom room…".
`Document.add_redirect / remove_redirect`; deleting a room drops redirects
into it. Canvas markers: magenta `R` on the vanilla door, green `IN` on the
arrival cell.

## §progression (S70) — quests + quest enemies

`progression.quests[]` / `progression.enemies[]` (unknown keys hard-error).
Enemies: dense EIDs from **519** (`auto` allocates), ≤**12** rows (308-byte
`@BUILD_PROJECT quest_enemy_stats` region in patches/bank_014.asm, 25 B/row,
zero-padded — the no-quest build regenerates the vanilla `ds 308` tail
byte-identically; suite-enforced). Fields = the 25-byte enemy-stats layout
(MONSTER_DATA); `join 0` = always joins; hp>1023 with join warns.
Quests lower to two generated scripts referenced from `rooms[].scripts`:
`quest:<id>` (done-check → requires check_ram ladder → offer choice text
($C83C: 1 = NO) → prebattle → trigger_battle3 EID → **init_dialog-prefixed**
win tail: set done flag + on_win actions) and `entry:<id>` (done → entry_done
ops; seen-flag-gated entry_cutscene; sets seen). `flags.done`/`flags.seen`
auto-register from the safe pool ($0158+). **Every text action lowered into
a non-interaction context gets its own preceding `init_dialog`**
(`_lower_actions(dialog_prefix=True)`) — field mode never services the text
queue (KEY_LESSONS S70). emit_script hard-errors unless the item stream ends
on `end`/goto/warp_castle (the S70 freeze class).

## §vanilla_exit_extensions (S70)

Adds exits to VANILLA rooms (mapID < $6B) without touching bank $0B's packed
lists: compiler emits `VanillaExitExtTable` (row: db mapID, screen [S94b:
`$FF` = any] / dw step_counter / db n_steps / dw variant ptrs,
$FF-terminated; variants deduped) consumed by template **entry 7
`VanillaExitResolve`** — Entry 6's unified divert calls $6007 every step in
every non-gate room, and since S94b Entry 9 (boundary push) does too;
vanilla rooms scan the ext table for (mapID, wScreenIndex) (variant =
min([counter], n−1), copy via CopyExitListToBuffer, HL=0 → the original
SharedPtrChase path), custom rooms `jp CustomExitCheck`. A matching variant
REPLACES the (room, screen)'s list wholesale for that step, so it must carry
the vanilla rows too — `entrance_redirects` (§2.12) generates that for you.
Validator: step_counter required, 1-16 steps, ≤17 rows/step, x=$FF error,
custom-dest rows need gate_flag 0, screen_byte required, `screen` 0-15 or
'any', one override per (room, screen). `build.compat` retired: a narrow master
table is now an **ERROR** with uncovered rooms (S70 entry-path routes first
entry through CustomScriptRead); full-coverage compat = byte-identical +
legacy-only warning.

## §5 template pin (S70v3)

bank_060_head.asm re-pinned twice this session: entry-7 dw +
VanillaExitResolve + factored CopyExitListToBuffer (348 B), then the
**wCustomY7Cmp arming** (+5 B in each of VanillaExitResolve /
CustomExitCheck → head **358 B**, `TEMPLATE_SIZE[0x60]=358`, sha
`ce595c61…` in PINNED_SHA256 — format: `<sha256>  <filename>`). The arming
makes Entry 6's y=7 skip data-driven: $07 vanilla (original semantics), $FE
custom (walk-on boundary exits). bank_071 unchanged (142 B).

**S94b re-pin:** `VanillaExitResolve` keys rows by (mapID, screen) — head
**383 B** (`TEMPLATE_SIZE[0x60]=383`; sha in PINNED_SHA256 re-pinned via
`tools/build_project.py --project <p> --pin-templates`).

**S97 re-pin:** entry 8 `CustomStateRules` (+ the `CustomReadStep` call) —
head **492 B** (`TEMPLATE_SIZE[0x60]=492`, sha re-pinned). §2.13. Measure the size
from `CustomScriptMasterTable - $4000` in the fresh `game.sym` after any
head change; the validator compares the emitted head against it.

## New verified opcodes (S70, handler-byte-verified)

`init_dialog` $07/0 (the "1 param" decompiler row is a set_bgm-class table
defect), `write_ram2` $13/2 (addr, value16 LE), plus the S70 movement set:
delay $09/1, wait_movement $19/0, npc_walk_x/y $1A/$1B/2, trigger_anim
$1C/1, lock/unlock $1D/$1E/0, begin_walk $22/0, trigger_battle3 $5A/1.
Field-mode script cadence is 1/8 frames; dialog mode per-frame — author
delays accordingly.

## S73 amendments — Anchor field-cast content + template re-pin

* **`bank_060_head.asm` template re-pinned** (`PINNED_SHA256` updated):
  `GateAwareDispatch` (entry 6) gains a SCRIPT-TYPE branch —
  `wScriptMapType >= $6B && != $70` routes straight to `CustomScriptRead`,
  so menu-armed scripts (the Anchor protocol: `$D8D3=$71`, counter `$FFFF`,
  `$D8D7=1`) run in ANY physical room, town and maze floors included. The
  `$70` guard preserves the original B-bug fix verbatim (gate-world scripts
  keep the wMapID route). Deliberate engine change per §5; the compat==hand
  byte-identity property re-verified (patched pin `8fa605d795…`, S73).
* **Reference patched pin**: `224b11766b28de88cdb206c31145e286` (S73b,
  SHIPPED USER-CONFIRMED; full description in test_compiler.py; superseded
  interim S73 pin `8fa605d795…` — historical).
* **Anchor content in the example project**: medal_vault (`$71`) hosts
  script ids 2-5 (`anchor_gate_confirm` / `anchor_return_confirm` /
  `anchor_err_special` / `anchor_err_none`) + 4 AUTO-id dialogue entries
  (explicit `text_id`s above the auto block break the no-quest fixture's
  density check — KEY_LESSONS S73). The engine side (bank $72
  `AnchorField14Tail`) hardcodes map `$71` + these script INDICES: if
  medal_vault's script table is reordered or the room renumbered, that
  constant must follow. A dedicated script-container room is the cleaner
  v2 home for menu-armed scripts.
* **Flag allocator**: `FLAG_SAFE_RANGES` shrank to `$0158-$0167` —
  `$01E0-$01EF` retired to `wAnchorGate/wAnchorFloor` (EVENT_FLAGS).

---

## Coherence sets the editor must maintain (S76)

Data in this ROM is duplicated in places that do not reference each other. If an
editor lets a user change one member of a set and not the others, the game does
not crash — it quietly displays or does the wrong thing, which is worse. Each set
below is a hard requirement for editor v1 content editing.

### Set 1 — breeding recipes ↔ library text

Three artefacts, ONE user-facing concept:

| Artefact | Address | Role |
|---|---|---|
| `FamilyRecipeTable` | `$16:$4974`, 222×2 | the family default; **result species = slot index** |
| `SpecialRecipeTable` | `$16:$4B30`, 825×5 | exceptions; scanned FIRST, first match wins |
| Library recipe strings | bank `$4D`, dispatch **entry = species + 5** | hand-authored TEXT, reads nothing |

- Changing a family recipe **must** regenerate the bank `$4D` string, or the
  library shows the old parents next to the new sprites. Use
  `randomizer/librarytext.py`; format and region differences in
  BREEDING_SYSTEM.md §"Library recipe TEXT".
- Because family results are slot-indexed, a general×general pairing can only be
  RE-POINTED (move the pair to another slot), never re-targeted in place.
- The library cannot show special recipes at all. Vanilla already has 18 of 197
  displayed defaults (9%) overridden by a special recipe at plus 0. An editor
  should either surface that as a warning or accept the display is advisory.
- **Obtainability is a graph property.** Adding or moving recipes can strand a
  species. Compute the fixpoint closure (wild recruits + boss joins + starter,
  closed under both recipe tables, with `$F0`-`$F9` matching any obtainable
  member of that family) and compare against the vanilla closure — 214 of 221
  species are reachable in vanilla. `randomizer/logic.py::obtainable_species`.

### Set 2 — boss fight row ↔ boss join row

`BossRedirectTable` (`$14:$4893` EN / `$14:$4903` DE, 34×4) maps fight EID →
join EID. Change a boss's species and the join row must follow, or the player
beats one monster and recruits a different one. Joinability lives at enemy-row
`+3` (`$07` = never joins; anything else takes the RNG path).

### Set 3 — species identity ↔ everything derived from it

Enemy resistances are NOT stored on the enemy row: bank `$51` loads the SPECIES
info block per combatant. So changing an enemy row's species silently changes its
resistance profile too. Same for the metal-body flag and level cap.

### Power calibration the editor should enforce

Full data in BATTLE_SKILL_SYSTEM.md §"Power calibration"; the editor-relevant
invariants:

1. **Species-swap preserves pacing exactly.** Level, six stat words and exp
   reward define a row's place in the curve. An editor changing only `species`
   and the skill bytes cannot break progression.
2. **Enemy skills must be banded on the ENEMY-side power pair** (record `+15`/
   `+17` at `$54:$41CF`), matching kind, target breadth AND damage — never on
   learn requirements, which are a "can this species ever learn it" gate and
   admit flat 10–16 all-foes breath onto level-2 enemies.
3. **Full heals (skills 45, 47, 163 — power 999) are banned on boss/arena rows**,
   plus a cap of one row's own max HP on any heal, which catches flat-value heals
   like Meditate (500).
4. **Encounter-pool edits must preserve level**, grouped by exact level, not by
   quantile rank.
5. **Resistances move difficulty; growth curves do not.** Growth (`$13:$6706`)
   affects only player-raised monsters. Resistances feed enemies too — scramble
   within a tier bucket to hold the curve (vanilla per-tier immunity means: 0.00
   / 1.24 / 1.53 / 2.62 / 8.21 / 4.57 for tiers 0/3/4/5/6/7).
6. **Exp curve tiers** (`$13:$41E6`): the level-2 requirement sorts the 32 curves
   into 2 / 5 / 10 / 100 tiers. Tier rank ≠ lifetime total; curve 19 is in the
   "slow" tier but is the second-hardest curve to 99.

`randomizer/audit_threat.py` is the regression harness for 1–4 and can be run
against any edited ROM, not just randomized ones:

    python3 randomizer/audit_threat.py <vanilla.gbc> <edited.gbc>

It fails if any of the 487 enemy rows deals more skill damage than vanilla.

### Region portability

The randomizer runs on the English and German builds unmodified. Everything the
editor needs about that — which tables move, the `+$70` bank-`$14` shift, the
name-pointer bases, the German charmap deltas — is in DATA_STRUCTURES.md
§"Region portability". The pattern to copy: locate by content signature with an
MD5 fast path, and fail loudly on an unrecognised image rather than writing
garbage.

---

## Validation the editor must run — S77

The randomizer shipped several builds that passed every check it had and still
played wrong. Root cause: **every check was an AGGREGATE** — "0 rows harder than
vanilla", correlations, depth profiles, multiset equality. Aggregates are
structurally blind to individual outliers: a species at 23x vanilla MP growth and
a skill on 44 rows instead of 1 both preserve every distribution being measured.

Any editor that lets a user author content needs **per-entity envelope checks**,
comparing each entity against the range vanilla assigns to comparable entities.
`randomizer/profile_check.py` implements these and exits non-zero, so it can gate
a build. It runs against ANY edited ROM, not just randomized ones:

    python3 randomizer/profile_check.py <vanilla.gbc> <edited.gbc>

| Check | Invariant |
|---|---|
| growth | no species-stat exceeds 2.5x vanilla AND +60 absolute |
| skill frequency | no skill drifts more than 8 rows in usage; none appears that vanilla never arms |
| skill placement | no row carries a skill below vanilla's minimum level for it |
| base monsters | no species met at L<=6 needs a specific x specific recipe |
| threat | no row deals more skill damage than its vanilla counterpart |
| pools | no duplicate EID in a pool; encounter level drift 0 |

Two further coherence rules for content editing, on top of the three sets above:

* **Enemy row skills should match the species' natural set.** Vanilla authors
  them that way — boss EID 32's three row skills are exactly species 196's three
  naturals — so a boss fights with the moves it will join with. Ranking any other
  constraint above this produces bosses using skills they do not have on
  recruitment, which players notice immediately.
* **Encounter pools must not contain a duplicate EID.** Vanilla: 0 of 128. A
  duplicate doubles that monster's encounter rate inside its pool, which reads as
  a difficulty spike with no stat change to explain it.

### Still missing: a combat model — damage layer DONE (S78)

A battle simulator would catch what these static checks cannot — time-to-kill,
resource drain, pacing across a gate. The S77 blocker is cleared: S78 traced
the entire damage layer (physical roll, record spells, resistances/ladders,
boss-protection gate, all 43 handler-computed specials) and validated the
Python model differentially against the running engine — 698 exact checks, 0
mismatches (`simulator/damage.py`, BATTLE_SKILL_SYSTEM §15). DEF does NOT
reduce spell damage. What still stands between the model and a usable
simulator: turn order, the damage-apply exclusions, status durations, and
both AI variants (per-monster commands vs arena tactics) — the S79/S80 boxes
on the ROADMAP.

## §2.10 S92 schema additions (P3.2 [G-A] + states [G-G half] + preludes)

**custom.layouts[]** — bank $64 content. Item: `{id, tiles?, attr?, comment?}`;
`tiles` = 16 rows × 20 cols of tile ids (visible grid; the 12 VRAM pad cols are
added at compile), `attr` = 16×20 palette codes 0-15 (packed per
GATE_GENERATION §7.2, HIGH nibble = LEFT tile). Entries allocate in DECLARATION
order, tiles entry then attr entry per item (S94: the S92 `base_entry+2`
stride is retired — attrs are resolved per screen, §2.11). References:
screens[].layout `{id}` (or `{bank, entry}` — any bank, vanilla tileset banks
included); screens[].attr `{id}` / render.attr `{id}` (or `{bank, base_entry}`). Emitter `layouts64` owns patches/bank_064.asm
(whole file). tools/build_gate_room.py is RETIRED (its grids live in the
example project; regen==committed was verified before the move).

**custom.tilesets[]** — bank $67 content. Item: `{id, raw2bpp | spec,
comment?}`. `spec` = a multi-tileset editor-export JSON (the S6-S10 import
pipeline; resolved through build_combined_tileset's cherry-pick core; EXT:
sources must be committed as raw2bpp instead). `raw2bpp` = a committed
2048-byte sheet (compress_lz is deterministic, so recompression is
byte-identical — proven S92 against the committed S6 sheet). Rooms may write
`record: {"tileset": id, ...}` instead of gfx_bank/gfx_id. Emitter
`tilesets67` owns patches/bank_067.asm.

**screens[].states[]** — N step entries per screen ([G-G] backend half). Item:
`{npcs, exits, layout?, comment?}`; omitted layout inherits the screen's. With
`states` present, top-level npcs/exits are an ERROR. Emission = contiguous
6-byte step entries after the counter; the head template's CustomPtrChase
already indexes counter×6 with NO clamp (no engine change, no re-pin) — keep
the counter < len(states) via scripts. Byte-identical to pre-S92 emission when
absent. NPC entries also accept `{kind: "raw", bytes: [5]}` verbatim
pass-through (clone fidelity: $8x examine spots, $90 step-on triggers — S98
names; their byte 4 is a room script index).
S92 MEASURED load-order rule: state selection reads the counter at the
destination room's LOAD, BEFORE its entry script runs — a room cannot arm its
own current load; the HUB room arms the destination (see script_preludes).
Step counters SURVIVE room transitions (zeroed at save-restore only, S65
window-clear), so hub-side arming holds across the transition.

**custom.script_preludes** — `{script_id: [ops...]}` prepended to the named
script AFTER quest lowering (generated `entry:`/`quest:` ids are valid
targets; `_`-prefixed keys are doc annotations). Labels share the target
script's namespace. Motivating use: entry:medal_vault's rank ladder arming
wCustomStep_ArenaClone_S1. Dangling target ids hard-error.

**Placeholder rooms ≥ $70** (synthesized for mapID density) emit an all-zero
Custom26DDTable row (the slot must exist; the room is unreachable).

**Explicit step_counter label-only form** — `step_counter: {label: NAME}`
auto-allocates the address but pins the RGBDS symbol (scripts reference
counters by name).
