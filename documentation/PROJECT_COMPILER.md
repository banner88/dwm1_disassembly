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

Everything else — engine intercepts in banks `$00/$01/$04/$06/$07/$0B/$16`,
layouts (`bank_064.asm` via `tools/build_gate_room.py` /
`tile_layout_compiler.py`), tilesets (`bank_067.asm` via
`build_combined_tileset.py`), breeding/library/skills banks — stays exactly
as hand-authored/tool-owned. Rooms **reference** layouts by
`{bank, entry}`; the compiler never re-derives a format another proven tool
owns.

### Quick start

```bash
# regression check (compat project must equal the S53 reference patched md5)
python3 tools/build_project.py --project editor2/example-project \
    --build --expect-md5 3a5a514c65b330e2788170c5d409b960

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
  patched ROM md5 is **`3a5a514c65b330e2788170c5d409b960`** — byte-identical
  to the reference patched build of S53. (This md5 moves whenever ANY patch
  changes; re-derive it via verify_integrity-style staging when needed.)
* **Fix build** — deleting `build.compat` emits the full-width script master
  table (+ shared no-op). Patched ROM md5 `f81d4ad84ee52f4c3342cc1f7e261e58`
  (**built S53, NOT yet user-tested**). Measured delta vs the reference:
  bank `$60` `$4010–$45B8` only (the +10 table bytes, downstream labels
  shifted, template operands re-resolved by the linker) + the 2 header
  checksum bytes `$014E/$014F`. Bank `$60` usage 1455 → 1465 B.

---

## 2. Schema reference (v1)

Top level: `meta`, `world` (stub), `custom`, `gamedata` (stub), `build`.
Values accept `"0x6B"`, `"$6B"`, decimal ints, or (where noted) RGBDS
symbols passed through to the assembler.

### 2.1 Layers (EDITOR_DESIGN §3)

v1 implements **Layer B (`custom`)** and **Layer D (`build`)**. `world`
(Layer A, vanilla-room edits) and `gamedata` (Layer C) are declared but
unimplemented: **any non-`_`-prefixed content in them is a hard error** —
the compiler never silently ignores authored data. Same for `custom.music`
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
      "step_counter": "auto",     // or {"label": "...", "addr": "0xD478"}
      "npcs": [
        { "kind": "spawn", "x": 7, "y": 6 },              // script forced 0
        { "kind": "npc", "facing": "down", "sprite": "0x0B",
          "x": 2, "y": 7, "script": "give_jerky" } ],     // or "none" -> $FF
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

Three authoring forms; ids `$0A00+` (auto-assigned in order, or explicit
`text_id`; ids must be dense per 256-id section — section = hi-byte−`$0A`,
routed by the bank-`$04` `TextQueueCheck_Ext` intercept):

```jsonc
{ "id": "jerky_offer", "text_id": "0x0A00",
  "lines": ["Want a", "Beef Jerky?"], "choice": true }   // explicit lines
{ "id": "long_text", "text": "one long string …" }        // auto-wrap 18 cells
{ "id": "exotic", "raw": [["box"], "Hi", ["br"], ["bytes","0xF7","0xF0"]] }
```

`lines`/`text` forms open with the standard box (`$EA $9F $A3`), join lines
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
"wram": { "region_size": 7,
          "reserved": [ { "label": "wCustomStep_Room6C_S5",
                          "addr": "0xD47C", "comment": "legacy hole" } ] }
```

Step counters allocate from `$D478` (ROOM_DATA_FORMAT verified-unused gap;
NOT SRAM-persistent): reserved entries claim first, then explicit
`step_counter` dicts, then `auto` in room/screen order, skipping used
addresses. The emitted region is padded to `region_size` so
**`wRoomRecScratch` stays pinned at `$D47F`** (read by engine code in banks
`$00/$0B/$71`). Exceeding the region is an error; growing it is a
deliberate engine change (move `wRoomRecScratch`+`wRoomEncFlag`), not a
knob. The example project's auto allocation reproduces the proven hand
addresses exactly (labels are index-accurate `_S4` where the hand file said
`_S1`; addresses — the bytes — are identical).

### 2.7 `custom.flags[]`

`{name, index: "auto"|"0x0158"}` → allocated from the EVENT_FLAGS.md
safe+persistent pool (`$0158–$017F`, `$0188–$018F`, `$01E0–$023F`,
`$0248–$0257`, `$0260–$026F`), never the collision zones or the non-SRAM
`$0278+` range. Resolved indices appear in the manifest; scripts reference
flags by the resolved value (a name→`set_flag` sugar is a v1.1 nicety).
The example project uses none (the proven content predates named flags).

### 2.8 `build`

```jsonc
"build": {
  "compat": { "master_table_rooms": ["0x6B","0x6C","0x6D"] },  // see §7
  "bank_map": { "0x60": "…", "0x71": "…", "0x17": "…", "0x64": "…" } }
```

`bank_map` is documentation-grade today (ownership is enforced by the
emitter registry); it exists so multi-bank spill has a declared home when
content outgrows `$60`.

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
| `wram_step_counters` | `patches/wram.asm` | step-counter labels `$D478+`, `ds`-padded to `region_size` |
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
| `dispatch71` | `custom.rooms` (records, encounters) | `file:patches/bank_071.asm` | `$71` |
| `palettes_a` | `custom.palettes` (placement a) | `region:…#room_palettes_a` | `$17` |
| `render17` | `custom.rooms` (+ placement-b palettes) | `region:…#room_render_tables` | `$17` |
| `wram_steps` | `custom.rooms` + `custom.wram` | `region:…#wram_step_counters` | — |

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
* `editor2/core/templates/bank_071_head.asm` — bank byte, 2-entry table,
  `CopyCustomRoomRecord`, `CustomEncResolve`.

Two pins, both enforced at compile time:

1. **sha256** in `editor2/core/templates/PINNED_SHA256`
   (`63969b1a…33d9` / `1b5d0015…982c`) — a drifted template refuses to
   compile. Re-pin (`--pin-templates`) ONLY after a deliberate engine
   session changes the head.
2. **TEMPLATE_SIZE** in `editor2/core/validators.py` — measured from the
   S53 reference `game.sym`: bank `$60` head = **283 B**
   (`CustomScriptMasterTable @ $411B`), bank `$71` head = **103 B**
   (`Custom26DDTable @ $4067`). Used by the pre-build overflow check
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
the compiler from that tool.

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

Errors: spawn script ≠ 0 (KL "ghost NPC"); missing `screen_byte`
(KL v14-v18/S40); NPC references script index 0 or an undefined/absent
script id (KL S2); script table without index 0; text terminator not
`$F7$F0`/`$E7$F0`, bare `$EE`, non-charmap char, >18-cell line
(KL S2/TEXT_SYSTEM); coords outside 10×8; missing `record` ≥`$70`; dims
not 160/128-multiples or screens beyond dims (KL S10); non-dense mapIDs /
compat list; duplicate text ids / non-dense sections; flag outside safe
ranges (EVENT_FLAGS); step counters over region size; palette ≠ 8×4
(KL S6); bank overflow (template+payload) (KL S52); non-deterministic
emit; unresolved script labels; layer/music/skills content (§2.1).
Warnings: compat overshoot exposure (§7); single-width destination with
nonzero screen-byte nibble (KL S40); boundary-exit y=0/7 (KL S10);
palette idx1/idx3 vs forced values (KL S7/S39); record on `<$70`;
op param-count mismatch vs the bank-004 table; auto-placeholder fill;
missing spawn on the entry screen.

---

## 11. Files

```
editor2/
  core/ project.py formats.py textenc.py scriptgen.py validators.py
        emitters.py compiler.py builder.py
        templates/{bank_060_head.asm, bank_071_head.asm, PINNED_SHA256}
  example-project/project.json      # regression baseline (build/ is regenerable output)
  tests/test_compiler.py            # 18 tests; --rom adds the 2 ROM builds
tools/build_project.py              # CLI
```
