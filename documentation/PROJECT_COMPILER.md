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
| `gd_family_icons` / `gd_family_icon_streams` / `gd_spirit_icon_stream` in `patches/bank_04f/02e/06d.asm` | the 11 family icons, from `gamedata.families.<f>.icon` (S107 P3.10 part 2c, §2.20) |
| `patches/bank_07e.asm` + the `ns_*` regions in `patches/bank_000/011/016/017/041/04d/06a.asm` | the project's NEW species (ids 221-239), from `custom.species` (S105, §2.21) |
| `patches/bank_07f.asm`, `bank_07c.asm`, `bank_07a.asm` + the `art_*` regions in `patches/bank_000/001/006/007/009/00b/010/011/012/017/018/059.asm` | new ART for the ORIGINAL monsters 0-214, from `gamedata.art` (S107, §2.23) |
| the `lay_copies_10` / `lay_copies_11` regions (the zero tails of `patches/bank_010.asm` / `bank_011.asm`) | walking layouts copied into the other follower bank, from `gamedata.art` + `custom.species` (S107 2b, §2.23 "Walking layouts") |
| `gd_monster_names` / `gd_monster_nicks` in `patches/bank_041.asm`, `gd_monster_desc` / `gd_monster_desc_extra` in `patches/bank_04d.asm` | the ORIGINAL monsters' names, default nicknames and library descriptions (+ new species' own descriptions), from `gamedata.monster_text` / `custom.species[].description` (S108 P3.10 part 3, §2.24) |
| `gd_arena_masters_04` / `gd_arena_masters_50` / `gd_arena_fees` / `gd_arena_team_sizes` in `patches/bank_004/050/009/06e.asm` | the arena: each match's master, the class entry fees, the team sizes, from `gamedata.arena` (S109 P3.10b, §2.25; the team members are `gamedata.enemies` rows) |
| `patches/bank_075.asm` + region `rom0_audio_master` in `patches/bank_000.asm` | S116: the second song bank and the `AudioMasterTableExt` rows (§2.9) |
| `patches/bank_076.asm` | whole file = template head (`EncResolve`, S115 + `NewGateRowCopy`) + the project's encounter lists, rooms' lists / variants / rates, gates' plans (S114 P3.13a, §2.30) + the new gates' rows / sources (S115 NG1, §2.31) + `GateClearTable` (S117 NG2, §2.32) |
| `patches/bank_ext.asm` | S134 (ROADMAP ARC CAP1): banks $80-$FF of the 4 MB ROM — a section + self-ID byte per bank (`emit_bank_ext`); a bank whose whole content another emitter writes (ARC CAP2 place banks, `emitters.ext_bank_files`) is INCLUDEd instead. `patches/game.asm` INCLUDEs it |
| `patches/bank_077.asm` + region `gd_item_info` in `patches/bank_003.asm` | S117: the shop lists (`ShopFill` / `ShopClose` template head) and the item buy prices, from `gamedata.shops` / `custom.shops` / `gamedata.items` (§2.32) |

**S120 — the committed overlay IS the compiler's example build.** `patches/*` must
assemble to the pin (`editor2/tests/test_compiler.py` `REFERENCE_MD5`) —
`verify_integrity.py` check 2 now FAILS otherwise. S119 re-pinned the bank $60 template
(entries 9 / 10) but never ran `--apply`: the committed `patches/bank_060.asm` stayed the
S117 file while `patches/bank_004.asm` already far-called `$6009` / `$600a`, so the
repo's own overlay built `0591928d…` (patched, historical, broken: a `$24` / `$61` op
would dispatch past the bank $60 table) and nothing failed. After an engine-template
change: `python3 tools/build_project.py --project editor2/example-project --apply`, then
keep only the files whose BYTES changed (`--apply` also rewrites the gd_* region comments
of banks $04 / $4D / $56 / $6E, dropping the address comments the committed copies carry
— S120 kept those).

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

**S134 — every build is 4 MB (ROADMAP ARC CAP1).** The `ext_banks` emitter writes
`patches/bank_ext.asm` (§1 table); the staging lists find it — and any later
`bank_0xx.asm` with no clean counterpart — by rule (`tools/verify_integrity.py`
`_NEW_FILE_RE`, the same rule in `builder._patch_lists`), and `builder.build_rom` now removes
every generated file it copied into `disassembly/` (before S134 a generated file absent from
`PATCH_NEW_FILES` would have stayed behind in the clean tree). Pin `807d9668…` (patched;
S129's `7d136455…` is historical: the two differ only in the header size byte + checksums).

**S133 — the map-id ceiling is enforced.** `Project._dense_rooms` raises `ProjectError`
for a custom mapID past `CUSTOM_MID_MAX` = `$EA` (128 rooms): bank $60 `CustomPtrChase` /
`CustomStateRules` / `CustomMonsterCast` and bank $17 `CustomAttrCheck` double `mapID −
$6B` in 8 bits, so `$EB` would read `$6B`'s tables — it built silently before S133
(test_compiler `test_s133`). More places = ROADMAP ARC CAP (EDITOR_DESIGN §6.4: place
banks, regions, 4 MB).

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
rejected, not guessed). ~~No DTE in v1~~ — **S120: there is no DTE in this game**
(TEXT_SYSTEM "One-cell contractions"); see below.

**S120 (ROADMAP P3.6, `editor2/core/textenc.py`, measured in PyBoy on the user's save):**
* **Glyphs** in `boxes` / `lines` / auto `text`: letters, digits, `. , ; ! ? '`, `..` (one
  cell), and `" - & ( ) + : / ~ [ ] *` + `…` (`EXTRA`, hex-emitted); an apostrophe + one of
  `l t s r m y v d e c n T` is written as the font's ONE-cell contraction (`$66-$71`, as the
  game writes "don't" = `don` + `$67`). Runs of charmap characters stay quoted `db "…"`
  strings (old texts emit the same bytes; a text with a contraction is one byte and one
  cell shorter per contraction — the user's "Let's" becomes `Let` + `$68`).
* **Inserts:** `{hero}` = `$F6` (counts **4** cells), `{lead}` = `$F9 $00` (counts **9**:
  the lead monster's species name) — `Project._assign_text_ids` puts op **`$3F`
  `load_lead_name`** right before every `text` op whose entry uses `{lead}` (the cutscene
  lowering emits it itself, so the editor's step model stays exact).
* **`speaker`** (boxes / auto text): absent or `"*"` = "*:" (the S97 bytes), `""` = no
  label (18 cells on line 1), `"hero"` = `$F6 $A3`, any name ≤ 9 glyphs = the name +
  `$A3`; line 1's limit = 18 − the label's cells (`line_limit(b, l, speaker)`).
  **`voice`**: `"low"` (default) = `$EA`, `"high"` = `$EB`, `"none"` = no opener (silent).
  No speaker / voice = `$EA $9F $A3`, byte-identical to S97-S119. `talk` specs (`speaker` /
  `voice` beside `boxes`, per block too), conversation `say` / `ask` dicts and cutscene
  `say` / `ask` texts carry them into the dialogue entry.
* **`raw` strings** are validated: only charmap characters (a `:` in a raw string used to
  assemble as the ASCII byte `$3A` = "W", silently — S120 probe).
* **S120b — the hero's default name is "MILLY"** (user: "I just want to change TERRY to
  MILLY as default, but leave otherwise as 4 letters"): a hand patch in the overlay, not
  project data — `patches/bank_04f.asm` replaces the font's 4 "TERRY" tiles `$D3-$D6`
  (`$4F:$4D40`, 64 B, outside the `gd_family_icons` region) with "MILLY", so every
  project builds it. Names stay ≤ 4 letters; `{hero}` still counts 4 cells.
  `textenc.PATCHED_GLYPHS` = the same bytes for the previews (test_compiler checks both
  the source and the built ROM). Pin `97659a4a…` (patched, historical; built S120b, NOT yet
  user-tested), was `d19259a1…` (patched, historical) — 64 font bytes + the checksum.
  **S121: now under the Milly hook** (§2.34) — region `milly_name_tiles`: hook off = the
  original TERRY tiles (the example), on = MILLY; `textenc.MILLY_GLYPHS` holds the
  drawing, `PATCHED_GLYPHS` is filled only while the open project has the hook on
  (`textenc.use_hero_glyphs`).


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
`patches/wram.asm`, not compiler-emitted.

**S118c — a copy that follows the game's room state:** `screens[k].step_counter =
{"label": "wCustomStep_<id>_S<k>", "vanilla": "0xD92D"}` makes the screen's state the
ORIGINAL room's own counter (`$D92A-$D99A`, validated): the region emits `<label> EQU
$D92D` and allocates nothing, so the game's story scripts (the Castle's `$D92D := 2` with
flag `$0009`) change the copy's NPCs / layout exactly as the original's, and the save keeps
it (the vanilla counters are in the saved image). "Make editable" writes this form for
every screen (`Document.clone_vanilla`); projects with copies made earlier are
migrated on open (`_migrate_clone_state`: a room whose every screen carries the copy
label, no `state_rules`); the Rooms tab's *Follow the game's room state* toggles it
(`set_follow_game`). A room with `state_rules` keeps its own counter (the rules write it —
a warning names it). Why (user S118b): the copied GreatTree stayed in state 0 forever and
moved the old man where the game moves the man by the cliff. PyBoy on the user's project:
copy `$6D` screen 0 with `$D92D` = 2 loads only the cliff man (the original's state 2);
with 0, the old man + the cliff man; the old own-counter build shows the state-0 list
for both. The example project's auto
allocation reproduces the proven relative layout at the new base (legacy
hole `0xCD84`, was `0xDE78`/`0xD47C`).

### 2.7 `custom.flags[]`

`{name, index: "auto"|"0x1003", comment?}`. **Numbering** = `project.number_flags`
(one function for the compiler and the editor, S124): an explicit `index` keeps its
number (it must lie in `FLAG_SAFE_RANGES` = `$0158-$0167` + `$1000-$179D`, else a
hard error); each `"auto"` entry takes the lowest free number of `FLAG_SAFE_RANGES`
**in list order** — positional, so deleting or moving an auto entry renumbers every
later one (old saves then mean something else). Legacy quest flag names not declared
are appended after the list (`quest_flag_entries`). `$179E`/`$179F` = the Milly hook
(§2.34), `$17A0-$17FF` = the gates (§2.32).
**S124 (ROADMAP P3.14a): the editor writes numbers in.** `Document._migrate_pin_flags`
writes the compiler's own numbers of every declared `"auto"` flag into the project on
open (same numbers → same ROM, old saves keep their meaning); `Document.add_flag`
gives a new flag the lowest free number of **`FLAG_AUTO_RANGES`** = `$0159-$0167` +
`$1000-$179D` (1,965) — **`$0158` is the original game's** (Arena Battle `$5D`
script 0, Milayou's rematch, measured S124: EVENT_FLAGS "Safe pool"), listed in
`GAME_SHARED_FLAGS`; a named flag on it warns at build (`validators`) and on the
Problems page, and Renumber moves it. The compiler's `"auto"` numbering is unchanged
(hand-written JSON builds the same bytes as before). Rename (`Document.rename_flag`)
rewrites every authored use through `flag_index` JSON paths; Delete is refused while
used; the note = `comment`. The resolved indices appear in the manifest.

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
is rejected.

**S116 (ROADMAP P3.13b) — the schema grew and the trio rule is gone** (owning
module `editor2/core/music.py` `plan()`; engine: SOUND_SYSTEM §2 / §10):

```jsonc
"music": {
  "libraries": [...], "room_defaults": {...},
  "songs": [ {"id": "my_tune", "source": {"file": "assets/music/my_tune.json"},  // NEW source:
              "first_id": "auto", "name": "My Tune"} ],   // a project file (MIDI import)
  "names":  {"0x09": "Castle theme", "dwm2_bgm07": "Dusk"},   // editor-only labels
  "gates":  {"32": {"floors": "<song>", "battles": "<song>"}},   // gates 0-95
  "battle": {"normal": "<song>", "boss": "<song>", "arena": "<song>",
             "starry": "<song>",                       // the Starry Night final
             "rooms":  {"0x01": "<song>"},             // battles that start in a room
             "fights": {"521": "<song>"}}              // the battle's first enemy (EID)
}
```
`<song>` = a project song id or a raw sound id ($01-$FC); unset = the game's.
* **Channels:** a song keeps EXACTLY its channels — 1-6, any of the six state
  slots ($00/$1A sound-effect slots warn: an effect cuts them), each once. The
  S64 padding to the pulse1/pulse2/wave trio and the dropping of extra channels
  are gone; `CustomBGMChanTable` (bank $71, 95 B) holds each song's count at its
  first id, read by the rewritten InitBGM (bank $71 entry 6 `CustomBGMStart`).
* **Two song banks:** songs in first-id order fill bank $74 (streams $4180-$7FFF,
  16,000 B), the rest bank $75 from the first song that no longer fits (the
  split); region `rom0_audio_master` (bank $00 `AudioMasterTableExt`) gets row 5
  `[split, $4001, $75]`. Over 2 × 16,000 B or ids past $FC = error.
* **Gate rooms:** when any gate has a floors song, custom rooms with no song
  that a gate serves (gate_inserts) or ends in (custom boss rooms) get
  `CustomRoomBGMTable` byte **$FF** = play the dive's gate song; when any gate
  has a battle song, served rooms get $FF in `CustomRoomBattleBGMTable`.
* **Emitted tables (bank $71, after `CustomRoomBGMTable`):** `CustomBGMChanTable`,
  `GATE_BGM_LEN EQU 96`, `CustomGateBGMTable`, `CustomGateBattleBGMTable`,
  `CustomRoomBattleBGMTable` (128), `BattleBGMSettings` [normal, boss, arena,
  Starry final], `BattleFightBGMTable` ([EID lo, EID hi, song]…, `$FF $FF`).
* **Validators:** unknown keys in music / gates / battle; a gate outside 0-95 or
  not defined (vanilla 0-31 or a project new gate); a song value that is neither
  a song id nor a sound id $01-$FC; two channels on one slot; 0 or > 6 channels;
  a song file missing from the project; > 255 fights.
* **Models:** `music.model_room_bgm(plan, ctx)` / `model_battle_bgm(plan, ctx)`
  are the Python twins of entries 2 / 7 (`tools/census_music_resolve.py` proves
  them against a built ROM by stub calls — SOUND_SYSTEM §10). Output: the 128-entry `CustomRoomBGMTable` in bank $71 (read
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
| `ext_banks` (S134) | — (always; `ext_bank_files(prj)` names compiler place banks, none before ARC CAP2) | `file:patches/bank_ext.asm` | `$80-$FF` |
| `dispatch71` | `custom.rooms` (records, encounters, animation S99) + `custom.music` (room BGM table, S64) | `file:patches/bank_071.asm` | `$71` |
| `palettes_a` | `custom.palettes` (placement a) | `region:…#room_palettes_a` | `$17` |
| `render17` | `custom.rooms` (+ placement-b palettes) | `region:…#room_render_tables` | `$17` |
| `wram_steps` | `custom.rooms` + `custom.wram` | `region:…#wram_step_counters` | — |
| `music74` | `custom.music` (+ `rooms[].music`) | `file:patches/bank_074.asm` | `$74` |
| `music75` (S116) | `custom.music` (songs past bank $74's 16,000 B) | `file:patches/bank_075.asm` | `$75` |
| `audio_master` (S116) | `custom.music` (the bank $75 row) | `region:patches/bank_000.asm#rom0_audio_master` | `$00` |
| `tileanim6c` (S102) | `custom.rooms[].tile_anims` | `file:patches/bank_06c.asm` | `$6C` |
| `gd_monsters` `gd_enemies` `gd_encounters` `gd_family` `gd_special` `gd_exp_curves` `gd_growth_curves` `gd_skill_learn` `gd_skill_mp` `gd_skill_records` `gd_library` `gd_library_text` (S103) | `gamedata` (§2.20) | `region:` in banks $03 / $14 / $01 / $16 / $69 / $13 / $13 / $06 / $07 / $54 / $12 / $4D | those banks |
| `species7e` + `ns_battle_gfx` `ns_follower_attr` `ns_battle_pal` `ns_recipe_pair` `ns_name_ptr` `ns_short_ptr` `ns_text_a`…`ns_text_g` `ns_detail_text` `ns_info` (S105; G3 layout) | `custom.species` (§2.21; editor2/core/species.py) | `file:patches/bank_07e.asm` + `region:` in banks $00 / $11 / $17 / $16 / $41 ×9 / $4D / $6A | those banks |
| `art7f` `art7c` `art7a` + `art_battle_gfx` `art_battle_pal` `art_walk_01/06/07/09/0b/12/18/59` `art_layout_10/11` `art_attr_10/11` (S107) | `gamedata.art` (§2.23; editor2/core/art.py) | `file:patches/bank_07f/07c/07a.asm` + `region:` in banks $00 / $17 / $01 $06 $07 $09 $0B $12 $18 $59 / $10 / $11 | those banks |
| `gd_monster_names` `gd_monster_nicks` `gd_monster_desc` `gd_monster_desc_extra` (S108) | `gamedata.monster_text` (+ `custom.species[].description`) (§2.24; editor2/core/monster_text.py) | `region:` in banks $41 / $4D | those banks |
| `gd_arena_masters_04` `gd_arena_masters_50` `gd_arena_fees` `gd_arena_team_sizes` (S109) | `gamedata.arena` (§2.25; editor2/core/arena.py) | `region:` in banks $04 / $50 / $09 / $6E | those banks |
| `anims6f` `anims70` + `gd_anim_routine` `gd_anim_cmd` (S112) | `custom.animations` + `gamedata.skills.<id>.presentation` (§2.28; editor2/core/battle_anims.py) | `file:patches/bank_06f.asm` / `bank_070.asm` + `region:` in bank $5F | `$6F` `$70` $5F |
| `hooks79` (S121) + regions `milly_bedroom_script` `milly_shape_04a` `milly_shape_04b` `milly_player_sheet` `milly_naming_icon` `milly_name_tiles` | `custom.milly_hook` (§2.34; editor2/core/milly.py) | `file:patches/bank_079.asm` + `region:` in banks $0E / $04 / $01 / $09 / $4F | `$79` |
| `text_sprites06` (S121) | `custom.rooms[].text_keeps_sprites` (§2.34) | `region:patches/bank_006.asm#text_sprite_mode` | `$06` |
| `enc76` (S114) | `custom.encounter_lists` + `custom.rooms[].encounters` + `custom.gates[].encounters` (§2.30; editor2/core/encounters.py) | `file:patches/bank_076.asm` | `$76` |
| `lay_copies_10` `lay_copies_11` (S107 2b) + `ns_follower_layout` (in the species list) | `gamedata.art` + `custom.species` (§2.23 "Walking layouts"; editor2/core/walk_layouts.py) | `region:` in banks $10 / $11 | those banks |

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
* `editor2/core/templates/bank_06f_head.asm` (S112) — bank byte, 4-entry
  table, `CustomAnimTick` / `CustomAnimInit` / `CustomAnimLoad` /
  `CustomAnimStep` + `CustomAnimNone` (the project's new battle animations,
  §2.28); pinned `aec1d3b8…286e`; TEMPLATE_SIZE 391 B.
* `editor2/core/templates/bank_076_head.asm` (S114) — bank byte, 2-entry
  table (S115: entry 1 `NewGateRowCopy`, §2.31), `EncResolve` /
  `EncPickVariant` / `EncFloorRun` / `EncVanillaNumber` (which encounter list a
  battle uses, §2.30; S115: a new gate walks its source's rule); pinned
  `94cb8ece…5d90` (S115; was `2f0634f5…9f` S114); TEMPLATE_SIZE 296 B (241 S114).
* `editor2/core/templates/bank_077_head.asm` (S117) — bank byte, 2-entry table,
  `ShopFill` (entry 0) / `ShopClose` (entry 1) (§2.32, DATA_STRUCTURES "Shops (S117)");
  pinned `fb9aefd1…3da0`; TEMPLATE_SIZE 93 B. **S117b:** + entry 2 `ScreenPush` (bank $09's
  screen push with palette attributes in free-colour rooms) and `ShopClose` → `ShopBoxBottom`
  (re-seats a top dialog box at the bottom); re-pinned `b8af2c91…873a` (the S117 value
  `fb9aefd1…` is historical); TEMPLATE_SIZE 438 B (`ShopPtrTable` $41B6).
* S117 re-pins: `bank_060_head.asm` `364ee530…1604` (entry 1 `CustomReadInteract` for
  every non-gate room + `VanillaNPCExtTable` scan + `CopyNPCListToBuffer` with the
  `$A0`/`$A1` prefixes; TEMPLATE_SIZE 678 B; the S105 value `650278bb…` is historical);
  `bank_076_head.asm` `40972da2…2635` (entry 2 `GateBossWin`; TEMPLATE_SIZE 358 B; the
  S115 value `94cb8ece…5d90` is historical).
* `editor2/core/templates/bank_079_head.asm` (S121) — bank byte, 2-entry table, entry 0
  `MillyShapeTable` / entry 1 `MillyPlayerSheet` (§2.34); only emitted with the hook on;
  pinned `3d7cbdbe…ef95`; no TEMPLATE_SIZE (the bank holds a few hundred bytes).
* S129 re-pins (§2.42): `bank_071_head.asm` `cbd0cdec…d11c` (`MusicRulePick` + `TermsHold71`,
  the rule calls in `CustomRoomBGMResolve`; TEMPLATE_SIZE 1070 B; the S128 value `bb4151d2…`
  is historical); `bank_077_head.asm` `eb0f0997…7d88` (entry 11 `StoryCheck`, `StoryCommand`,
  `ShopSetPick`; TEMPLATE_SIZE 1788 B; the S127 r3 value `34f612a6…` is historical).
* S128 re-pin: `bank_071_head.asm` `bb4151d2…1868` (`BattleBGMResolve`'s two `ld a, [wMapID]` →
  `call ArenaMapID`, §2.41; TEMPLATE_SIZE unchanged; the S126 value `b3588b7a…` is historical).
* S126 re-pins: `bank_071_head.asm` `b3588b7a…28a2` (`CustomAnimSource` pauses during
  `AnimPauseTypes`, §2.39; TEMPLATE_SIZE 908 B; the S125 value `28d988db…` is historical);
  `bank_077_head.asm` `cfe0dba0…bb53` (S126 r2: + `$FFD4` := `$80` in `ServiceTilesBack`;
  TEMPLATE_SIZE 688 B; the first S126 value `4c9f5998…` (684 B: + entries 3 `SayText`, 4
  `ServiceCloseBox`, 5 `ServiceCloseTiles`, 6 `ServiceOpenTiles`, the `ScreenPush` palette-7
  rules, §2.39) and the S117b `b8af2c91…` are historical).
* S125 re-pin: `bank_071_head.asm` `28d988db…6cc4` (+ entry 9 `HubWarp`, §2.38;
  TEMPLATE_SIZE 865 B, `Custom26DDTable` `$4361` in the S125 game.sym; the S121 value is
  historical).
* S121 re-pin: `bank_071_head.asm` `27b5f30f…1b81` (+ entry 8 `TextSpriteMode`, §2.34;
  TEMPLATE_SIZE 727 B, `Custom26DDTable` `$42D7` in the S121 game.sym; the S116 value is
  historical).
* `editor2/core/templates/bank_071_head.asm` — bank byte, 8-entry table
  (S116: entry 6 `CustomBGMStart`, entry 7 `BattleBGMResolve`, entry 2 + the gate
  songs — SOUND_SYSTEM §10; TEMPLATE_SIZE 688 B, measured `Custom26DDTable` $42B0
  in the S116 game.sym; re-pinned S116 — current value in `templates/PINNED_SHA256`;
  S100: 6 entries; 4 S99, 3 S64), `CopyCustomRoomRecord`, `CustomEncResolve` (S100:
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
   historical (current values: `templates/PINNED_SHA256`). Re-pinned S105:
   bank $60 (`CustomScriptRead` SKILL_SCRIPT_TYPE branch, §2.22: `650278bb…`)
   and bank $6B (comment only — EID 518: `14c314e0…`); the S101 values
   `d90b9761…` / `cff4507a…` are historical.
2. **TEMPLATE_SIZE** in `editor2/core/validators.py` — measured from the
   reference `game.sym` (S105: bank `$60` = **558 B**, +9 for the skill-script
   branch; S102: `$71` = **444 B**, new `$6C` = **285 B** —
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
* **Custom music.** ~~Blocked on ROADMAP Arc 3 M1–M3 … Until then
  `custom.music` hard-errors.~~ Built S64 (§2.9, `music74`) and S116 (`music75`,
  `audio_master`, the bank $71 music tables) — DOC_AUDIT S116.
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
  and reload but not dependably at initial entry". **Superseded since S70v3**
  (CROSSBANK_ROOMS: the `$4C3E` site was reverted to `ld a,[wMapID]`): the
  room-entry script DOES run at initial entry — re-measured S119 (PyBoy: an
  entry cutscene plays on the first arrival through a door and through the
  warp mailbox; DOC_AUDIT S119).

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
params. The handler (`$04:$669D`, `ScriptCmd41_SetBGM`) advances the script
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
        species.py           # S105 custom.species: new species -> ns_* regions + bank $7E (§2.21)
        art.py               # S107 gamedata.art: original monsters' art -> art_* regions + banks $7F/$7C/$7A (§2.23)
        walk_layouts.py      # S107 2b: the 155 walking layouts — packer, ranking, copies into the other follower bank (§2.23)
        monster_text.py      # S108 gamedata.monster_text: names / nicknames / descriptions (§2.24)
        arena.py arena_doc.py  # S109 gamedata.arena: regions + validator (§2.25); the Arena tab's model (ArenaMixin)
        skill_scripts.json   # S105 the custom skills' built-in dialog scripts + texts (§2.22)
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
        arena_tab.py                                   # S109 Arena tab (fees, masters, team sizes, team rows)
        rooms/gate_panel.py                            # S100 inspector "Inside gates" group
  templates/blank-project/project.json   # File > New project (S94)
  example-project/project.json      # regression baseline (build/ is regenerable output;
                                    #   untracked + .gitignore'd since S108)
  example-project/assets/species/   # S105 Gorbunok's art streams (custom.species)
  tests/test_compiler.py            # 277 tests (315 with --rom: the ROM builds; S105)
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
is the custom tileset id or `"<bank>:<id>"` for a vanilla tileset. S124 r3:
`npc_names: {"MM:screen:state:n": name}` — your names for the original game's NPCs
(§2.37).

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
**`compiler.measure_banks(data, dir, repo, banks=None)`** (S132: `banks` = only the
emitters owning those banks run — the meter passes its four, 0.14 s instead of 2 s on a user
project; `layouts.compress` is memoised by input bytes, the compressor being deterministic)
returns `{bank: (used, cap)}`
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

**S120 (ROADMAP P3.7b part 2): the floor-type rows + depth tier** — `maze_row` (0-15 →
byte 0: the row of `FloorTypeSelectionTable` = which of the 16 maze floor types),
`special_row` (0-15 → byte 1: `FloorTypeSelectionTable2` = the special room of floors 3,
6, 9 …), `contents_row` (0-15 → byte 2: `FloorTypeSelectionTable3`), `depth` (1-3 →
byte 7: the ground-item tier). Any gate, vanilla (the `gate_floor_table` region) or new
(`NewGateRows`); absent = the gate's own / the source's byte; out of range = ERROR. The
rows are SHARED tables — the Gates tab names each row by the gates that use it and
shows the maze floor types as the game draws them
(`extracted/gate_floor_types/`, `tools/census_gate_floor_types.py`, GATE_GENERATION
§2 "S120"). Measured on the user's save: gate 5 with `maze_row` 0 / `special_row` 10 /
`contents_row` 12 / `depth` 3 → `wMapID` 13 (row 0's only type), `wFloorType2/3` 10 / 12,
`wBossTileset` 3 (unedited: type 12, 2 / 3, tier 1).

A custom boss room gets `room_flags` no-saving by DEFAULT (explicit
`can_save: true` wins, with a warning). Music: `CustomRoomBGMResolve`
(bank $71 entry 2) plays the boss room's song on the floor before it (or $34
without one — warning "no song"). **Validators:** unknown keys / gate outside
0-31 (S115: 0-95 — 32-95 are NEW gates, §2.31) / duplicate gate / floors outside 2-99 / missing boss room / boss room
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
project enemy id or a vanilla EID 0-486; S105: 518 is free space, not a row) · `helper` · `move` `{dest,
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
| `encounters` (pools 0-127) | `EncounterPoolData` $01:$6AAE, 128 × 26 (`bank_001#gd_encounter_pools`) | format decoded S103 (DATA_STRUCTURES "Encounter pool entry"); EIDs 0-486 or a project enemy (its EID or, S105, its `progression.enemies` id; the S30 EID 518 is gone) |
| `skills` (ids 0-221) | `SkillMPCostTable` $07:$570C (`bank_007#gd_skill_mp`), `SkillLearnReqTable` $06:$50E0 218 rows (`bank_006#gd_skill_learn`), `SkillRecordData` $54:$41CF (`bank_054#gd_skill_records`) | record field names = BATTLE_SKILL_SYSTEM §7; `learn` for ids $DA-$DD is an ERROR (FieldStateDispatch code) |
| `exp_curves` / `growth_curves` | $13:$41E6 / $13:$6706 (`bank_013#gd_exp_curves` / `#gd_growth_curves`) | new hand patch `patches/bank_013.asm` (the clean bank + two markers) |
| `breeding.family` (slots 0-214) | `FamilyRecipeTable` $16:$4974 (`bank_016#gd_family_recipes`) | `null` = no recipe ($FF,$FF); matchers as `build_breeding.py` (family / species name, id, $hex). S104: `"Spirit"` = `$FA` on either side; `"AnyFamily"` / `"any"` are an ERROR (the patched family scan no longer has the wildcard) |
| `breeding.special` | the LIVE table in bank $69 (`bank_069#gd_special_recipes`; the $16 copy is runtime-dead, B2) | overrides by `index` or `match`, appends; **S113: + `removes`, or a whole `table`; with any edit the table is AUTO-ORDERED most specific first (§2.29); ERROR = two rows with the same parents + min plus when a project row is involved** (was: B5's dead-append / shadowed-override errors) |
| `families` (S104 r2) | `FamilyTextPtrTable11` bank $6D (`bank_06d#gd_family_voices`, 11 dw) + the Spirit name pool in bank $41's dead fill (`bank_041#gd_spirit_names`, fixed 55 B) | `<family>.dialogue` = voice `A`-`D` or a family name ("talks like"); `spirit.names` = 8 names, 1-4 letters A-Z / a-z (`A` = $24, `a` = $3E); names only for Spirit (the other pools stay vanilla). Editor: the Families tab |
| `families.<f>.icon` (S107, ROADMAP P3.10 part 2c) | the font glyphs `bank_04f#gd_family_icons` ($4F:$4110-$41BF, 11 × 16 B, text bytes $10-$1A; families 0-9 were `INCBIN gfx/image_04f_4110.2bpp`), families 0-9's gfx streams `bank_02e#gd_family_icon_streams` ($2E:$424A-$42F7, 10 × 19 B, gfx ids $2E03-$2E0C; `patches/bank_02e.asm` = NEW hand patch, PATCH_FILES) and `bank_06d#gd_spirit_icon_stream` (SpiritIconStream, gfx id $6D04) | 8 strings of 8 digits 0-3 (0 dark, 1 the cream background, 2 light, 3 black); ONE picture → the glyph + the stream (19-B literal: `dw $0010`, run marker = the smallest byte the tile lacks, 16 B — the format of all 11 shipped streams, so empty == the same bytes). Original icon = key removed. Validators: 8 × 8, digits 0-3. Editor: the Families tab icon editor |
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
not exist, two special rows with the same parents + min plus (S113, §2.29; was: a shadowed special append / override), `boss_joins` outside the 34,
more than 1650 special entries, > 32 members in one library family (S113: the
special-table checks are §2.29's).
(WARN): an encounter list whose slot chances add up to MORE than 100 % (S106 r3:
the last slots are cut; all 128 original lists are exactly 100); combat-only species edits; an enemy row's species change (Set 3:
resistances follow the species) and, on a boss fight row, its join row (Set 2);
joinable with HP > 1023; the same EID twice in a pool (S77); ~~a skill's MP
changed while record +4 (`mp_byte`, reader untraced — 218/222 vanilla rows
equal the MP cost's low byte) keeps the old value~~ (S110: retired — record +4
IS the battle MP cost (menu afford $50, act-time afford + deduct $53, AI veto
$57; BATTLE_SKILL_SYSTEM §7), so `mp` now writes it too: `mp` 0-255 sets the
field table AND +4; `"ALL"` only for Farewell / MegaMagic (table 999, +4 = 1,
the MP emptied in their code); StepGuard / MapMagic (field-only, +4 = 0) keep
+4; an explicit `record.mp_byte` still wins; ERRORS: `mp` > 255, `"ALL"` on
another skill, a number on an all-MP skill, a `target_mode` other than
$11/$12/$21/$22/$41 — §2.26); decreasing cumulative exp;
the family / special shadow reports ported from build_breeding.py.

**Retired tool paths (S103)** — they wrote the same bytes and would overwrite
the regions: `build_breeding.py --emit-family / --emit-special /
--emit-relocation`, `build_family_reassign.py --emit`,
`build_library_table.py --emit`, and `build_new_species.py`'s bank $14 / bank
$01 writes (S105: its bank_06a write too — §2.21). Their `--selftest`s still run (verify check 5).
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
**S107 (P3.10 part 2c):** `gamedata.families.<f>.icon` → three regions (table
row above); and the two saved-party icon readers S104 missed (banks $07 / $0A,
BREEDING_SYSTEM "Family icons as project data") far-call `FamilyIconGfxFromE`
→ pin **`77ccdab8a746fdc25fcad8d1239c84e4`** (patched; built S107,
USER-CONFIRMED 2026-10-01; test_compiler `REFERENCE_MD5`). Prev `9740c1c9…` (patched,
historical; S107 2b). Tests: no edits == the ROM's glyphs / streams; a Slime +
a Spirit icon land in glyph + stream (other 9 untouched, every stream 19 B);
bad icons refused; `--rom`: glyphs and gfx ids $2E03 / $6D04 decode to the
authored tiles, the fork bytes once in $07 and twice in $0A, the blank
project's ROM == the original at $4F:$4110-$41AF and $2E:$424A-$42F7.
**S109 (P3.10b):** the arena regions + bank $6E `ArenaTeamFixup` (the two 6-byte
tails in banks $04 / $50 far-call it; §2.25) → pin **`482c949ffabbce1ec409c4c9fb7e5f2e`**
(patched; built S109, test ROM USER-CONFIRMED 2026-10-01 22:57). Prev
`77ccdab8…` (patched, historical; S108 left it unchanged).
**S110 (P3.11):** the skill text / looks regions + `GetPresentId` / `SfxPresentId`
(§2.26) and the example project's skill 215 rename (moved out of a hand edit) →
pin **`534bfb6245e825445f6d45764ed7305e`** (patched; built S110, test ROM USER-CONFIRMED
2026-10-02). Prev `482c949f…` (patched, historical).
**S111 (P3.11c/d):** the custom skills as project data — 19 regions over their bytes in
banks $07/$41/$4C/$54/$55/$56/$58/$5F/$72, new skills 234-254, the element override, the
learn row buffer, `CustomSfxTable`, the bank $50 name fix (§2.27) → pin
**`4a2860cfd148cafa6843221d8be1ad49`** (patched; built S111, test ROM USER-CONFIRMED 2026-10-02 15:08 ("Looks good"); historical
since S111b). Prev `534bfb62…` (patched, historical).
**S111b:** the built-in custom skills' RATIOS as data (`gd_custom_ratios`, `ScaleHL72`, bank
$72 entry 7 for Anchor) + the MagicBurn / Tame AI target rows (§2.27) → pin
**`5a1c540487f9043e9d6431685527f1ad`** (patched; built S111, test ROM USER-CONFIRMED 2026-10-03 00:19 ("Tested, works");
test_compiler `REFERENCE_MD5`). Prev `4a2860cf…` (patched, historical).
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

## §2.21 S105 — NEW species as project data (`custom.species`, ROADMAP P3.9b + G3)

Module `editor2/core/species.py` (validation + one emitter per region). Before
S105 the one new species (Gorbunok, 224) was hand data in eleven patch files +
`extracted/new_species.json` — present in EVERY project's build. The forks that
make new ids work stay hand-authored (MONSTER_DATA "Species-indexed table
overshoot registry"); the DATA they read is emitted from the project.

**Capacity (S105 G3, USER-CONFIRMED 2026-09-30 ("Confirm all three appear as expected")): 19 species, ids 221-239**,
any subset, any order (user decision "19 monsters it is"). The range is the
game's own: 0-220 are the vanilla monsters (MonsterInfoTable = 221 rows); the
library seen-bit array `$CA94` is 30 bytes (0-239); the special-recipe scanner
compares species bytes directly against the family codes `$F0-$FA`; `$FE` /
`$FF` are the library "unseen" marker / none; the bank-$04 follower router's
species+$10 wraps at 240. (The first P3.9b build held ONE species: the eight
follower forks kept a one-entry table in end-of-bank padding.)

```jsonc
"species": [{
  "id": 224,                          // 221-239, each at most once
  "name": "Gorbunok",                 // 1-9 characters (packed into bank $41, below; S108: the §2.24 name encoder)
  "short_name": "Gorb",               // 1-4 letters; default = first 4 of name
  "info": {"clone_from": 78, "family": "Slime"},   // a VANILLA row + gamedata.monsters fields
  "description_from": 78,             // encyclopedia line 2 = that species' text (0-214)
  // S108: OR "description": ["line 1", "line 2", "line 3"]  (its own; §2.24)
  "battle":   {"art": "assets/species/gorbunok_battle.bin",   // LZ stream, 576 B decoded
               "palette": ["$4D67", "$6BFF", "$7FFF", "$0000"]},
  "follower": {"art": "assets/species/gorbunok_follower.bin", // LZ stream, 256 B decoded
               "walks_like": 128, "palette": 2}               // layout donor 128-214, OBJ palette 0-7
               // S107 2b: OR "layout": 0-154 (any of the 155 walking layouts — §2.23
               // "Walking layouts"); `layout` and `walks_like` together = error
}]
```

Every table region is **id-indexed over 221-239 (19 rows)**; an undeclared id
keeps the original bytes (never read — every validator refuses an undeclared
id ≥ 221).

| Region | File | Content (no species = the ORIGINAL ROM's bytes) |
|---|---|---|
| `ns_battle_gfx` | bank_000 `$2D59-$2D7E` (MonsterBattleGfxTable tail, re-sectioned `$2D56-$2DA7`) | 19 words: `$7E00 + (id-221)*2 + 1` (else `$320F`) |
| `ns_follower_attr` | bank_011 `NewFollowerAttrTable` | 19 × 1 B: OBJ palette (S107 2b; S105-S107 2a: 2 B = palette + donor index) |
| `ns_follower_layout` | bank_011 `NewFollowerL1Table` (S107 2b) | 19 dw: the species' level-2 layout table — `walks_like` = the donor's own table, `layout` = that layout's bank-$11 table or its copy (`lay_copies_11`, §2.23); undeclared = `$0000` (the original zero padding; never read) |
| `ns_battle_pal` | bank_017 `NewBattlePalTable` | 19 × 8 B RGB555 |
| `ns_recipe_pair` | bank_016 `NewRecipePairs` | 19 × 2 B encyclopedia parent pair (`$FF,$FF` = none) |
| `ns_name_ptr` | bank_041 MonsterNamePtrTable `[221]-[239]` (`$44F3`) | `dw NsName_<id>` (else `Unused_220` / `Unused_225`, the vanilla words) |
| `ns_short_ptr` | bank_041 `NewSpeciesShortPtrs` `$7EF3` (= `$7D39 + 221*2`) | `dw NsShort_<id>` (else `$0000`) |
| `ns_text_a`…`ns_text_g` | bank_041 `$7E38` (23 B), `$7E86` (109), `$7F19` (103), `$7FF6` (10), `$7E77` (15, Spirit-name slack), `$581F` (10, two dead vanilla default names), `$728B` (22, dead vanilla MiscText_03) | the PACKED name + nickname strings (below); unused = original bytes |
| `ns_detail_text` | bank_04d `HighLine2Ptrs` / `HighMode0Ptrs` | 19 + 19 words (line 2 = vanilla mode-1 entry 261 + `description_from`, read from the clean disassembly; line 1 = the recipe line or `$53C4`) + the recipe lines; no species = labels only |
| `ns_info` | bank_06a slots 0-18 | 19 × 43-byte info rows |
| (file) `species7e` | bank_07e | `SpriteOverflowPtrs_7E` (38 words: index (id-221)*2 = follower, +1 = battle; an undeclared id aliases the first declared species) + the streams; no species = `ds $4000, $00` |

**`source` (S106, editor metadata).** `{sheet, battle: box, frames: {DOWN-a …
UP-b: box}}` — the sprite sheet (project-relative, `assets/sheets/`) and the boxes
the Monsters tab cut the art from, so "Re-cut" reopens them. Allowed by the
validator, never read by the compiler; the art files stay the source of the bytes.

**Follower art has no table.** The eight follower gfx-id forks
(`FollowerArtResolveXX`, banks $01/$06/$07/$09/$0B/$12/$18/$59) COMPUTE
`$7E00 + (id-221)*2` into WRAM `wNewSpeciesGid` (`$D10A`, carved from
wCustomPool) and return HL = its address — the callers read the word at HL
at once (DE is dead at all eight). Same fork size (`.normal` became
`ld de,Table / add hl,de`). The old `ns_follower_gfx_*` regions are gone,
so banks $09/$0B/$18/$59 are no longer compiler-touched.

**Names (bank $41).** No fixed slots fit: the strings are packed into the
seven extents above (292 B) by an exact bin-packer; equal strings and
suffixes share bytes. 19 eight-letter names + 19 four-letter nicknames
(266 B) fit; 19 nine-letter names each with its own nickname (285 B) do not
(the extents waste ≥ 12 B for 10/5-byte strings) → validation error. The
nickname lookup: `LoadModeBaseRedirect` (ROM0 `$00F0`) sends mode base
`$4739` with id ≥ 221 to `$7D39`.

**Derived, never authored:** the encyclopedia recipe = the FIRST special entry
(`gamedata.breeding.special`, live table) whose result is the species — pair
bytes as matchers, line in the vanilla two-9-char-field format (coherence
Set 1); none → `$FF,$FF` + the vanilla "?????" line `$4D:$53C4`. **Enemy rows**
of a new species are ordinary project enemies (`progression.enemies`,
`species: <id>`, EID 519+) — the S30 EID-518 row in the bank-$14 tail is free
space again; `gamedata.encounters[].eids` may name a project enemy by its id.
**Validators** (ERROR): more than 19 species, an id outside 221-239 or twice,
name / short name not 1-9 / 1-4 letters, names that do not pack, `walks_like`
outside 128-214, art that does not decode to exactly 576 / 256 bytes (the S75
over/under-read class), a missing art file, art streams over bank $7E's 16,307
B, an enemy or monster NPC of an undeclared species ≥ 221, a family library
tab over 32 members (was an emit-time exception), a `skill:` id in the project.
**Layout (S105 fix):** the pre-S105 patch wrote the layout pointer at
`$11:$413F`, inside the attr table (ChopClown / Grendal's bytes);
`NewAttrHandler` then wrote the donor's level-1 index to HRAM `$C7`
(MONSTER_DATA follower section). **S107 2b:** the handler leaves `$C7` alone;
both bank-$11 follower entries call `FollowerLayoutBase11` instead of
`ld de, FollowerLayoutL1Table11` (3 bytes for 3) — DE = `NewFollowerL1Table −
2·$5D` for ids 221+, so `[$C7]·2` (= species−$80) lands on the species' OWN
row: any of the 155 layouts, native or copied. Art files: the example's are reproduced
byte-for-byte by `tools/bake_follower_overflow.py --stream-dir` from
`examples/follower_swap/`. Editor: `conversation.species_names(data)` and the
NPC Monsters picker list the project's species (no thumbnail until P3.10); the
Families tab builds its model through `Project.gamedata()`.

**Stale generated files (S105 G3 fix).** `compiler.write_outputs` now deletes a
file in `<out>/patches` that this build no longer generates: `builder.build_rom`
layers everything there over `patches/`, so the pre-G3 `bank_009/00b/018/059.asm`
left in a project's build folder would have silently replaced the new forks.

**Tests.** `test_compiler --rom` runs every fork FROM THE BUILT ROM's bytes
(`MiniSM83`, a 40-opcode SM83 subset) over species 0-239 — the eight follower
forks, HighBattlePal, FamilyRecipeResolve, NewAttrHandler, LoadModeBaseRedirect
— for the example and for a 19-species project (which also proves every bank
still fits; bank $12's 714 trailing `nop`s became `ds $8000 - @` so the library
grouping region can grow).

**Pin (S107 2b):** **`9740c1c99f9eb11fd2d0edbf3d0a3066`** (patched; built S107,
USER-CONFIRMED 2026-10-01 on the demo ROM): the bank-$11 engine change above + `NewFollowerL1Table`
(Gorbunok `$4184` = walks like 128, as before) + the zero tails of banks
$10 / $11 as the regions `lay_copies_10` / `lay_copies_11` (empty = the same
zeros). Prev:
**Pin (S105 G3):** **`f22f56e116bc6b3f6b94e7d45a7e5f1e`** (patched, historical; built S105,
USER-CONFIRMED 2026-09-30 ("Confirm all three appear as expected"); S107 2a
changed no pinned byte). The example still declares only Gorbunok (now row 224-221
= 3; bank $7E index 6/7). Prev **`f8a714850b5318844e23b050a16f222e`** (patched,
historical — the capacity-1 P3.9b build, never user-tested): byte delta vs the
S104 r5 pin (`15f21834…`, patched, historical): pool 0 slot 3 EID 518 → 520;
`$11:$413F` vanilla + NewAttrHandler +5 B; bank $14 `$7EB3` row cleared; bank
$6B + Gorbunok's row; bank $16 entries 693/803; bank $36 vanilla (Clam gone);
bank $60 (template +9 B + skill table); bank $72 one byte (`$71` → `$FF`).

## §2.22 S105 — the custom skills' built-in scripts (script type `$FF`)

`editor2/core/skill_scripts.json` holds the dialog scripts + texts of the custom
skills (today Anchor's four: gate-side confirm, return confirm, "fails here",
"no anchor"). `Project` appends copies of them after the project's own
`custom.scripts` / `custom.dialogue` (never written back — the editor saves
`self.data`), so they take the first text ids after the project's; ids starting
`skill:` are reserved. `emit_bank_060` writes `SkillScriptPtrTable` right after
the master table: ids 0/1 → `SkillScrNoop` (id 0 = "the player" in bank $04
`CheckPendingNPC`'s `$D8DC` test), then the scripts from id 2 in file order —
Anchor = 2-5, the S73-measured values. Template `CustomScriptRead`: `cp
SKILL_SCRIPT_TYPE ($FF) / jr nz .room / ld de, SkillScriptPtrTable / jr
.byScript` (+9 B, re-pinned §5); `$FF` routes like any type ≥ `$6B` ≠ `$70`
everywhere else (the `$06/$20/$40` bank ladders, `GateAwareDispatch`, the `$5D`
battle tests). Bank $72 `AnchorField14Tail` arms `$D8D3 := $FF` (was `$71`).
The validator does not warn about the built-in texts' `lines` form (measured +
user-confirmed S73). PyBoy S105 on the user's save (a project WITHOUT room
`$71`): all four dialogs through the real SKIL menu; the S104 build soft-locked
there (BATTLE_SKILL_SYSTEM §14).

## §2.23 S107 — new ART for the ORIGINAL monsters (`gamedata.art`, ROADMAP P3.10 part 2a) + walking layouts (part 2b)

Module `editor2/core/art.py`. Species **0-214 only**: 215-220 (TERRY? and the four
summon tiers) are not monsters (PROJECT_STATE Iron Rule 8 — refused with that
reason), 221-239 keep their art in `custom.species`. Sparse like every
`gamedata` section; `art` is in `gamedata.SECTIONS`, the `Gamedata` model ignores
it, `art.resolve` / `art.place` validate it (called from `validators.validate`).

```jsonc
"gamedata": {"art": {
  "8":  {"battle":   {"art": "assets/art/008_slime_battle.bin",       // LZ stream, 576 B decoded
                      "palette": ["$015B", "$6BFF", "$02BF", "$0000"]},
         "follower": {"art": "assets/art/008_slime_follower.bin",     // LZ stream, 256 B decoded
                      "palette": 6,                                   // OBJ palette 0-7
                      "layout": 143},                                 // S107 2b: walk style 0-154 (default 0)
         "source":   {"sheet": "assets/sheets/bug.png", "battle": {…}, "frames": {…}}},
  "78": {"battle": {"palette": ["$03E0", "$6BFF", "$5FEF", "$0000"]}, "follower": {"palette": 1}}
}}
```

Every field optional: a palette alone recolours the original art; art alone keeps
the original battle colours / OBJ palette. `source` = editor metadata (sheet +
boxes for "New art from a sprite sheet…" to reopen the cut); never read here.

**What the game reads (measured S107, ROM search + PyBoy):**

| Looks | Table | Readers / copies |
|---|---|---|
| battle pose | ROM0 `MonsterBattleGfxTable` $2B9F (word = gfx-ID) | ONE table, 13 reader sites (banks $07 ×5, $12, $18, $51, $52, $53, $55, $59, $5F — all `add $9F / adc $2B`); no copy in the ROM |
| battle colours | $17 `MonsterBattlePalettes` $62FD, 8 B | ONE reader (bank $17 entry 6); rows 0-215 exist |
| walking art | follower gfx-ID table | EIGHT per-screen copies ($01 $06 $07 $09 $0B $12 $18 $59), identical for 0-214 (`extract_gamedata --selftest`) — the same new gfx-ID goes into all eight |
| walking layout + palette | $10:$407F / $417F (0-127), $11:$407F / $412D (128-214) | level-1 pointer + attr byte (low 3 = OBJ palette, bits 5/6 flips) |

| Region | File | Content (empty `art` = the original ROM bytes) |
|---|---|---|
| `art_battle_gfx` | bank_000 `MonsterBattleGfxTable` [0]-[214] (ported from the clean tree S107) | 215 words; 19 in-region fake-decode labels re-emitted at their offsets (`art.ANCHORS`) |
| `art_battle_pal` | bank_017 `MonsterBattlePalettes` [0]-[214] | 215 × 8 B ([215] TERRY? stays hand text) |
| `art_walk_01` … `art_walk_59` | the eight tables' species rows | 215 words each (bank $0B: 48 anchors; in the patched build its table sits at **$4914**, not $4974 — offsets are relative) |
| `art_layout_10` / `art_attr_10` | NEW hand patch `patches/bank_010.asm` (= the clean bank, re-sectioned) | 128 dw / 128 db (1 anchor) |
| `art_layout_11` / `art_attr_11` | bank_011 `FollowerLayoutL1Table11` / `FollowerAttrTable11` | 87 dw / 87 db (2 anchors) |
| (files) `art7f` `art7c` `art7a` | `patches/bank_07f/07c/07a.asm` (`patches/game.asm` includes them instead of the blank banks; verify_integrity PATCH_NEW_FILES) | self-ID byte, pointer table at $4001, the streams; no art = `ds $4000, $00` |

**Placement** (`art.place`, `dwm/sprite_bank.SpriteOverflowAllocator`): first fit
over $7F, $7C, $7A in species order, battle stream before walking stream —
deterministic. Capacity 3 × 16,383 = 49,149 B (user S107: "I probably WONT edit
more than 50 monsters"; a literal battle + walking pair costs 838 B + 4 B of
pointers → 58 fully re-arted monsters; test_compiler proves 50 fit and 60 are
refused with the byte count).

**Walking layout (2a).** New walking art without a `layout` is packed in layout-0
order (the S106 sheet reader; tiles 0-3 down, 4-7 side a, 8-11 side b, 12-15 up).
Layout 0 exists in BOTH follower banks — Dragon's level-2 table `$10:$4E33`,
Armorpion's `$11:$4184` (`art.LAYOUT0_L2`; layout 0 has 10 / 4 byte-variants per
bank that differ only in the DMG palette bit $10) — so a re-arted species'
level-1 entry is pointed at its own bank's layout 0 (a level-2 pointer is read
with its bank mapped). Its attr byte becomes the chosen OBJ palette with no flip
bits (vanilla collectible attrs are 0-7 anyway). A palette-only walking edit
keeps layout and flip bits: `(attr & $F8) | palette`. User 2026-10-01 on the 2a
ROM: a re-arted monster's library parent icon "is STILL. Vanilla behaviour is
MOVING" — layout 0's down_B / up_B are the A frame mirrored (no new tiles, no
bob), so a symmetric monster does not move; the sheets have real B frames.

**Walking layouts (S107 2b, ROADMAP P3.10 part 2b; `editor2/core/walk_layouts.py`).**
`follower.layout` (0-154; with new walking art only — a layout cannot re-order the
ORIGINAL art) / `custom.species[].follower.layout` (instead of `walks_like`) picks
any of the game's 155 layouts (`extracted/follower_layouts.json`, regenerated S107
with each layout's stored bytes, its Y-flip bits, the level-2 tables that already
hold it per follower bank and every frame each bank holds). The art stream must
be packed for that layout — the editor's sheet dialog does it:

- **Packer** (`walk_layouts.pack`): the sheet's 16×16 frame = the OAM box x −8..7,
  y −16..−1 around the anchor; each of the 16 tiles' pixels takes the value most
  of its placements (all six frames, with their flips) want — a placement hidden
  under a higher-priority entry counts ¼ — then the frames are re-drawn exactly
  as the engine does (entry 0 on top: it goes to the lowest OAM index, which wins
  on CGB) and the pixels that differ from the sheet are the error. Proof: all 44
  original monsters whose layout fits the 16×16 box are re-drawn pixel-exactly
  through their own layout (test_compiler).
- **Ranking** (`walk_layouts.fit_all`, ≈ 0.3 s): all 155 layouts by error; ties →
  the monster's own original layout, then one its follower bank already holds,
  then the lower id. Measured over whole sheets: bug.png 20 of 26 monsters fit
  some layout with 0 differing pixels (layout 0: only 6 — the rest are 170-252 px
  off because their B frames are not mirrors), the water sheet 16 of 31 (layout 0:
  13); the worst best fit is 100 px over six 16×16 frames.
- **Level-1 entry** (`art.l2_for`): layout 0 → `art.LAYOUT0_L2` (the 2a tables);
  any other → its first level-2 table in the species' own follower bank, else
  the label of its COPY.
- **Copies** (`walk_layouts.copies`, regions `lay_copies_10` = bank $10 `$7A83-$7FFF`
  (1,405 B) and `lay_copies_11` = bank $11 from `$799E` (after
  `FollowerLayoutBase11`, 1,634 B); test_compiler checks both starts against the
  built game.sym): per (bank, layout) ONE 12-byte level-2 table + only the frames
  the bank does not already hold byte-for-byte (the bank's own frames, then
  earlier copies) — 12-114 B, median 63 B into bank $10 / 80 B into $11. Over the
  room → validation error naming the bank. Empty = the original zero tails.
- **New species:** `NewFollowerL1Table` (§2.21) holds the species' own level-2
  pointer; the bank-$11 entries reach it through `FollowerLayoutBase11`.

**Validators** (ERROR, 2b): a `layout` outside 0-154, a `layout` without new
walking art, `layout` + `walks_like` on one species, layout copies over a bank's
free tail (also refused by the editor's model before anything is written).

**Validators** (ERROR): species outside 0-214 (215-220 with the Iron Rule 8
reason, 221+ → custom.species), unknown keys, art that does not decode to exactly
576 / 256 bytes or is missing, a palette that is not 4 RGB555 words, an OBJ palette
outside 0-7, streams over the three banks.

**Tests.** test_compiler: empty art == ROM rows for every region and zero banks;
anchors emitted and defined in the clean tree; the refusals; a fixture (9 full,
200 palette-only walking, 42 palette-only battle, 214 walking art in bank $11) →
region bytes; `--rom`: the built ROM's table words at sym addresses (all eight
copies), layout / attr bytes, each gfx-ID resolving to a stream of the right
decoded size, 215-220 untouched; the blank project's ROM == the original at every
art site. **Pin unchanged by 2a** `f22f56e1…` (patched, historical): the regions
reproduce the hand bytes exactly. **2b tests:** the catalogue, the packer proof
above, layout-0 packing == the S106 packing (Gorbunok), the ranking; a fixture
(9 → a bank-$11-only layout copied into $10, 10 → a native one, 200 → a
bank-$10-only layout copied into $11, 201 → layout 0, Gorbunok → 200's copy,
shared) → level-1 rows + one copy per bank; the refusals; `--rom`: every chosen
layout decoded back from the BUILT ROM through its level-1 entry /
`NewFollowerL1Table` row == the layout, `COPY_START` == the built sym,
both entries `call FollowerLayoutBase11`, `MiniSM83` runs `FollowerLayoutBase11`
and `NewAttrHandler` for species 128-239; the blank project's ROM == the original
at `NewFollowerAttrTable` / `NewFollowerL1Table` / both zero tails. **Pin S107 2b**
`9740c1c9…` (patched; §2.21).

## §2.24 S108 — names, default nicknames and descriptions of the ORIGINAL monsters (`gamedata.monster_text`, ROADMAP P3.10 part 3)

Module `editor2/core/monster_text.py` (`MT.check` called from `validators.validate`;
`monster_text` is in `gamedata.SECTIONS`, the `Gamedata` model reads only the renamed
names — for the recipe-line coherence). Species **0-214**; 215-220 refused with the
Iron Rule 8 reason; 221-239 keep their name / short name in `custom.species`.

```jsonc
"gamedata": {"monster_text": {
  "8":  {"name": "Goober", "nickname": "GOOB",
         "description": ["A wobbly blob", "that's always", "grinning - & glad"]},
  "147": {"name": "Grendel"}}}
```

Every field optional; a value equal to the original counts as unedited (the editor
removes it). **Encoding:** names / nicknames = single glyphs: letters, digits, space,
`' , . ! ? - &` (`-` = $9C, `&` = $B6; no DTE / ligatures — the naming screen and the
name fields draw one glyph per letter); no leading / trailing space. Descriptions add
`;` and the one-cell glyphs `'t` ($67), `'s` ($68), `..` ($61) by longest match,
lines joined with $F1, ≤ 3 lines of ≤ 18 cells (the vanilla maximum; every vanilla
description re-encodes byte-for-byte from its decoded lines — test_compiler).

**What the game reads (ROM-verified S108; `extract_gamedata --selftest` re-proves the
shapes):** names = text mode 5 (`MonsterNamePtrTable` $41:$4339, 256 words; strings
0-219 then "" (220, also 221-224) and "?????" (225-255) at $5B1F-$628D, 1,903 B);
default nicknames = mode 7 (`MonsterNickPtrTable` $41:$4739, 215 words; $69F2-$6C76,
645 B — the join naming screen PRE-FILLS the nickname with it, PyBoy S108; was the
mgbdis `FamilyCodePtrTable`); descriptions = bank $4D mode 1 (dispatch entries
261-475; $53D3-$7719, 9,031 B). Each block is contiguous, in id order, every string
once — and every reader goes through its pointer table (no raw address of a string in
the ROM besides the tables: bank-$41 scan + the labels' census).

| Region | File | Content (no edits = the original bytes) |
|---|---|---|
| `gd_monster_names` | bank_041 (`MonsterNameStrings`, 1,903 B) | the 222 strings, labels `MonsterName_NNN_<VanillaName>` (220 / 225: `…_Unused_220/225`) |
| `gd_monster_nicks` | bank_041 (`MonsterNickStrings`, 645 B) | 215 strings, labels `MonsterNick_NNN_<vanilla code>` |
| `gd_monster_desc` | bank_04d (9,031 B; S108 re-section, `tools/resection_monster_desc.py`) | 215 strings, labels `MonsterDesc_NNN_<VanillaName>` (the mode-1 pointer words reference them) |
| `gd_monster_desc_extra` | bank_04d, after `ns_detail_text` (before the `ds $8000 - @` pad) | descriptions that no longer fit their block + `NsDesc_<id>` of new species' own descriptions; empty = nothing |

**Layout:** each block is filled first-fit in id order with the effective strings; a
string that does not fit keeps its LABEL but is emitted elsewhere — names / nicknames
in the new-species text extents (`species.text_layout(lst, extra)`: they are packed
with the new species' names, never suffix-shared because the pointer table names them;
first-fit decreasing, the exact search when that fails and ≤ 40 strings), descriptions
in `gd_monster_desc_extra` (room = $8000 − (`HighLine2Ptrs` $773E + 2 × 19 words + 19 B
per new-species recipe line), checked by `MT.check`). Unused block bytes = $00. Labels
never change, so no pointer table moves and the unedited project is byte-identical.

**Coherence:** `Gamedata.library_text_edits` regenerates the encyclopedia recipe line
(gd_library_text, 19-B slots in place) of every species whose FamilyRecipeTable pair
names a renamed monster (also fixing vanilla's own misspelling in that line — Akubar
"Grenadal" — and, for the 4 vanilla lines that do not follow the generator, only when
a parent is renamed); new species' recipe lines (ns_detail_text) and the encyclopedia
use the project names. `custom.species[].description` (1-3 lines) instead of
`description_from` (both = error) → `NsDesc_<id>`; `description_from` now references
the label `MonsterDesc_NNN_…`, so a borrowed description follows an edit.

**Validators (ERROR):** unknown keys, species outside 0-214 (215-220 Iron Rule 8),
name not 1-9 / nickname not 1-4 characters, a character the font lacks, a description
line over 18 cells or more than 3 lines, names / nicknames that do not pack into the
free extents (message names both), descriptions over the bank-$4D room.

**Tests:** test_compiler — no edits == ROM per block, labels == the clean tree's,
encoder round trips (all 215 names / nicknames / descriptions), a rename fixture
(block bytes, Akubar's line), spill (lengthened names placed in the extents; too many
refused), refusals, a new species' own description; `--rom`: the built ROM's mode 5 /
7 / 1 tables lead to the authored text, `HighLine2Ptrs` == `HIGH_LINE2_PTRS`, the
blank project's ROM == the original at all three blocks. **Pin unchanged** `77ccdab8…`
(patched).

## §2.25 S109 — the ARENA (`gamedata.arena`, ROADMAP P3.10b)

Module `editor2/core/arena.py` (`AR.check` called from `validators.validate` and from
the Monsters tab's commit; `arena` is in `gamedata.SECTIONS`); editor model
`editor2/core/arena_doc.py` (`ArenaMixin`), tab `editor2/app/arena_tab.py`.

```jsonc
"gamedata": {
  "arena": {
    "G":    {"fee": 20,
             "matches": {"0": {"size": 1, "master": {"person": "0x0B"}},
                         "2": {"master": {"monster": 41}}}},
    "King": {"matches": {"0": {"size": 2}}}},
  "enemies": {"300": {"species": 40, "level": 30}}}     // a team member = its enemy row
```

Group keys `G F E D C B A S StarryNight King` (groups 0-9); match keys `"0"`-`"2"`, the
King `"0"` only (the King is ONE match — the Arena Battle room sets `$D9CD` = 3 before
it). Every field optional; a value equal to the original is removed by the editor.
`fee` (classes only) 0-65535; `size` 1-3 (3 = vanilla); `master` = `{"person": <NPC
sprite id>}` (the S91 catalog's 'normal' ids below `$E0` + the vanilla masters' ids) or
`{"monster": <species>}` (0-214 or a declared new species; drawn like its follower,
draw id = species + `$10`).

**The team members are not here:** the game has no team table — match *m* of group *g*
fights EID `$E0 + 9·g + 3·m + slot` (the King `$01E1-$01E3`), so they are
`gamedata.enemies` rows (§2.20), edited in place (the Arena tab writes them through the
Monsters model). SIDEQUEST_MAP "Arena authoring as built — S109" has the runtime path.

| Region | File | Content (no `arena` = the original bytes) |
|---|---|---|
| `gd_arena_masters_04` | bank_004 (`ArenaMasterSpriteTable`, `$04:$5E22`, 60 B) | 30 × [draw id, is_monster], index 3·group + match (read by `ArenaBattleSetup`, match 0) |
| `gd_arena_masters_50` | bank_050 (`ArenaMasterSpriteTable50`, `$50:$6778`, 54 B) | the same first 27 rows (no King; read by `LoadArenaEnemyStats`, matches 1-2) |
| `gd_arena_fees` | bank_009 (`ArenaClassFeeTable`, `$09:$5D23`, 16 B) | 8 words G..S (shown, checked, paid by the class menu) |
| `gd_arena_team_sizes` | bank_06e (`ArenaTeamSizeTable`, 30 B; hand patch `patches/bank_06e.asm`) | 1-3 per (group, match) |

**Engine (hand, patches/ only):** the last 6 bytes of `ArenaBattleSetup` ($04) and
`LoadArenaEnemyStats` ($50) — `ld a,$01 / ld [$d7d1],a / ret` — became `ld hl,$6E00 /
rst $10 / ret / nop`; bank $6E entry 0 `ArenaTeamFixup` writes `$D7D1` = 1, then for a
size < 3 writes `$DA02` = size − 1 and `[$FF, $00]` into the absent slots' display
entries (`$D7D0` for slot 2; + `$D7CC` for slot 1). Index ≥ 30 → returns (vanilla). The
two master tables are now addressed by label in BOTH trees (`ld hl, ArenaMasterSpriteTable`
was `ld hl, $5e22`), so the regions own their bytes.

**Validators:** ERROR — unknown groups / matches / fields, a fee outside 0-65535 or on
Starry Night / the King, a size outside 1-3, a master that is no catalog person / no
monster, species 215-220 as master (Iron Rule 8), species 239 as master (draw id
`$FF` = not drawn), a FIGHTING team member (slot < size) of species 215-220 (217-220
hang the room — ROOM_DATA_FORMAT "Monster NPCs"). WARN — a fighting member of species
239 (fights, not drawn before the fight). Unused slots may hold anything.

**Tests:** test_compiler `test_arena_s109` — no arena == ROM for all four tables, the EID
formula, the fixture's masters / bank-$50 copy / fees / sizes, the refusals, an unused
summon slot accepted; `--rom` `test_arena_rom` — tables at their addresses, both tails
far-call bank $6E, `ArenaTeamFixup` RUN from the built ROM (MiniSM83) for all 30 (group,
match) — `$DA02`, the hidden entries, `$D7D1` — and an index past the table leaves the
vanilla values. test_app — the Arena tab: team size, a row's species + level, a monster master,
a fee through the widgets; a summon in a fighting team refused; a bad number refused
without an undo step; undo restores project.json exactly. **Pin** `482c949f…` (patched, historical since S110), was `77ccdab8…` (patched,
historical): the tails + bank $6E.

## §2.26 S110 — the original SKILLS: names, SKIL texts, looks and sounds (`gamedata.skills`, ROADMAP P3.11)

Module `editor2/core/skills.py` (`SK.check` from `validators.validate` and the Monsters /
Skills commit; `_skill_regions()` in the emitter REGISTRY); `mp` / `learn` / `record`
stay in `gamedata.py` (§2.20, MP semantics rewritten S110 — see the Validators paragraph
there). Editor model `editor2/core/skills_doc.py` (`SkillsMixin`), tab
`editor2/app/skills_tab.py`, help `editor2/help/54_skills.md`.

```jsonc
"gamedata": {
  "skills": {
    "16": {"name": "Spark", "description": ["Sparks leap at", "every foe"],
           "mp": 1, "looks_like": 6,                       // plays Bang's animation + sounds
           "record": {"party_min": 150, "party_range": 9}},
    "72": {"record": {"target_mode": 18}},                 // $12 = all foes
    "215": {"name": "BugCut"}}}
```

Ids 0-221 (the custom skills $DE-$E9 = P3.11c; ids ≥ 222 refused for these keys).
`name` 1-9 cells (the monster-name encoder: letters, digits, space, `' , . ! ? - &`);
`description` 1-3 lines × 18 cells (`'s` `'t` `..` one cell; `[]` / `""` = no text);
`looks_like` a donor id 0-221 (its own id = none). A value equal to the original is
removed by the editor.

| Region | File | Content (no edits = the original bytes) |
|---|---|---|
| `gd_skill_names` | bank_041 (`SkillNameStrings` `$41:$628E-$69F1`, 1,892 B; pointers `SkillNamePtrTable` $4539 by label) | 222 names + the empty 222nd, first-fit in id order; overflow → the shared bank-$41 new-species text extents (`species.TEXT_EXTENTS`, joined by `SK.bank41_spills`) |
| `gd_skill_desc` | bank_056 (`SkillDescStrings` `$56:$502F-$664A`, 5,660 B) | the owned texts in vanilla order (0-150, `SkillDesc_Blank`, 213-218, `SkillDesc_None`); overflow → `gd_skill_desc_extra` |
| `gd_skill_desc_ptrs` | bank_056 (`SkillDescPtrTable` `$56:$6667`, rows 0-221) | `dw` labels; rows $E0-$E9 stay the hand [S73] rows |
| `gd_skill_desc_extra` | bank_056 (`$56:$7291-$7E41`, 2,993 B, was nop pad before the [S73] strings) | spilled texts + `SkillDescOwn_NNN` (a skill that shared Blank / None given its own text); fixed size |
| `gd_present_proxy_5f` | bank_05f (`StockPresentTable` `$5F:$7EDA`, 222 B — [S112] the S110 text said `$7EEB`: wrong, the S111 and S112 .sym both give $7EDA) | presentation id per skill (identity = vanilla) |
| `gd_present_proxy_55` | bank_055 (`StockSfxTable` `$55:$798D`, 222 B; NEW hand patch `patches/bank_055.asm`) | SFX-table index per skill (the same values) |

**Engine (hand, patches/ only).** *Looks:* every presentation read of the acting skill
goes through bank $5F `GetPresentId` (12 reads, S74 proxy) — now `ld a,[$db8a]`, ids <
$DE index `StockPresentTable`, ≥ $DE the S74 `CustomProxyTable` (27 B; 228 pad nops
consumed). The sounds are bank $55's per-skill tables (5 kinds × 2 sides × 222 B), read at
ONE site `$55:$4061` (BATTLE_SKILL_SYSTEM had `$4067`): `ld a,[$db8a]` → `call
SfxPresentId` (same size; ids < $DE → `StockSfxTable`, else unchanged; 19 B + table in the
bank tail, 241 nops consumed, `DataB55_7db1` stays at $7DB1). So a skill keeps its handler,
damage, targets and messages and plays the donor's animation, flash and sounds. *Text:*
bank $56 re-sectioned (`tools/resection_skill_desc.py`, both trees): `SkillDescModeTable`
$664B (mode 0 → `SkillDebugTextPtrs` $664F, 12 debug strings at $4E4C-$502E; mode 1 →
`SkillDescPtrTable`), the two `ld de, $664b` by label.

**Looks rules (MEASURED, `tools/census_skill_present.py` →
`extracted/skill_present_census.json`):** each of the 222 skills lent its look to 7
borrowers (party one foe Blaze / all foes Firebal vs 3 / one ally Heal / all allies HealUs /
self ChargeUP; an enemy's Blaze and Heal) on the user's save — 1,554 PyBoy battles, every
one acted 4-9 times, longest frozen action machine 157 frames, **no stall**. Nothing is
refused unless the census measured a stall (`lend_problem`); WARN (`lend_warning`) for a
summon donor ($84-$87: its "animation" is the summoned monster — only the blink shows)
and a donor aimed at the other side (measured: Heal with Bang's look shows no explosion).

**Validators:** ERROR — an id outside 0-221 with these keys, a bad name / text (cells,
characters, lines), a donor outside 0-221, all texts not fitting block + 2,993 B (names
never fail: the shared extents' own check), plus §2.20's `mp` / `target_mode` errors.
WARN — the two looks cases above.

**Tests:** test_compiler `test_skills_s110` — no edits == the ROM's names / texts /
pointers / tables; renames, a 3-line text, an own text for a Blank-sharing id, spills
(names into the extents, texts into the extra), looks, the MP rules (both copies, ALL,
field-only), the refusals; `--rom` `test_skills_rom` — through the game's pointer tables,
the $55 fork bytes, `GetPresentId` / `SfxPresentId` RUN from the built ROM (MiniSM83) for
every id; the blank project's skill bytes == the original. test_app — the Skills tab
(rename, text, MP, power, looks, target, a flag; a bad name refused without an undo step;
items read-only; the Monsters tab follows the rename; undo restores project.json
exactly; every behaviour box named in the help). **Pin** `534bfb62…` (patched), was
`482c949f…` (patched, historical): the proxies + the example's skill 215 = "BugCut" —
until S110 a HAND edit inside the names block (`SkillName_215_BugCut`, 3 `$F0` pad),
now example-project data; names 216-221 shift 3 B (DOC_AUDIT S110).

## §2.27 S111 — the CUSTOM skills as project data + NEW custom skills + elements (`gamedata.skills.<222-254>`, ROADMAP P3.11c / P3.11d)

Module `editor2/core/custom_skills.py` (`CS.resolve` / `CS.check`, from `validators.validate`
and the Monsters / Skills commit; 19 entries in `CS.REGIONS`, registered by
`emitters._custom_skill_regions()`); the built-in baseline `editor2/core/custom_skills.json`
(read ONCE from the S110 pin by `tools/extract_custom_skills.py`; `--check` reads it back out
of any build — the --rom test does, on the example build). Editor: `skills_doc.py`
(`new_custom_skill` / `delete_custom_skill` / the custom setters), the Skills tab (kinds
"custom" / "new", **New skill…**, **Delete**, Element, Sounds like, Announce, "Its own numbers
and lines"), help `54_skills.md`.

**Ids** (BATTLE_SKILL_SYSTEM §13.9): 222-223 ($DE/$DF) = the retired S45 POCs — refused;
224-233 ($E0-$E9) = the BUILT-IN custom skills (MagicBurn, Tame / TameMore / TameMost,
Anchor, Tremor / Quake / QuakeMore / QuakeMost, Mourn) — every build has them, a project
edits their DATA; 234-254 ($EA-$FE) = NEW custom skills a project adds (21 slots): each
runs the effect code of a stock skill (`base`, 0-221) under its own id.

```jsonc
"gamedata": {"skills": {
  "0":   {"element": "Ice"},                                  // a stock skill's element
  "229": {"name": "Rumble", "mp": 8, "element": "Explosion",
          "quake_power": {"min": 60, "max": 80},              // Tremor's own numbers
          "announce": ["{name} makes", "the ground rumble!"],
          "learn": {"level": 1, "prereqs": [72]}},
  "234": {"base": 16, "name": "Thunder", "mp": 6,             // runs Zap's effect
          "description": ["Calls thunder down", "on every foe"],
          "looks_like": 6, "sounds_like": 6,                  // Bang's animation + sounds
          "record": {"party_min": 60, "party_range": 15},
          "learn": {"level": 1, "prereqs": [16]}},
  "235": {"base": 94, "name": "FrostBite", "looks_like": 98, "element": "IceBreath"}}}
```

**Keys.** Every custom id: `name`, `description` (null / [] = empty), `mp` (0-255; one value
writes CustomMPCostTable AND record +4), `learn` (`{"level", "prereqs", ...}` as §2.20, or
null = not learnable), `record` (§2.20's dict), `looks_like` / `sounds_like` (a stock id;
a new skill's `sounds_like` follows `looks_like` unless set), `element` (below), `announce`
(1-3 lines, `{name}` = the user's name, 18 cells per line — the own battle line, template
$FD) OR `announce_as` (a stock battle message id 0-$FC, or "none"). Built-ins only:
`tame_meter` (225-227, 0-1600), `quake_power` `{min, max}` (229-232; max ≤ min+255),
`allies_line` / `flew_line` (229 — the Quake banners shared by the chain), `boost_line`
(233), `dialogs` (228 — Anchor's 4 dialog texts, 1-3 lines × 18), and (S111b) the RATIOS their code
used to fix: `burn` + `damage_per_mp` (224; 1/2, 1), `damage_of_atk` (225-227; 1/4),
`mp_charge` (228; 3/4), `ally_damage` (229-232; 1/3), `per_fallen` (233; 1) — each "n/d",
[n, d] or a whole number, n 0-255, d 1-255, at most 1 for the MP shares, 2 for Quake's own
side, 4 for the damage factors; bank $72 `CustomRatioTable` (region `gd_custom_ratios`, 22 B,
the RATIO_* offsets) read by `ScaleHL72` = min(999, floor(x·n/d)) (exact: q·n + (r·n)/d), and
by entry 7 `AnchorKeepMP72` from bank $73's arrival commit (MP kept = MP·(d−n)/d). No edits
= the old constants (`>> 1`, ×1, `>> 2` twice, `>> 2`, the /3 loop, ×(fallen+1)): PyBoy A/B
identical. New skills only: `base` (required, with `name`).

**Refusals (CustomSkillError → ProjectError):** ids 222-223 / > 254; `base` on a built-in;
a new skill without `base` or `name`; a `base` that is not a skill (`SK.kind`), the
field-only StepGuard / MapMagic ($37/$38), or one whose copy MEASURED different from the
original (`extracted/skill_clone_census.json`: 114 same, 41 differ, 67 not a skill — the
differing ones compare their own id with $DB8A, BATTLE_SKILL_SYSTEM §13.9); `mp` on MagicBurn
/ Anchor (their code spends the MP); power words or a different `target_mode` on a built-in
(the handler sets the damage; S74: nonzero powers looped the presentation); `element` on a
built-in that deals no damage (Anchor) or on a new skill whose base tests no resistance;
`announce` + `announce_as`; a learn prereq that is not a stock / built-in / defined new id;
(S111b) a ratio that is not a fraction, has d = 0 / n or d > 255, exceeds its maximum, or
sits on another skill.
Budgets: names = the 94-B bank $41 region then the shared `ns_text_*` extents (S110),
descriptions = the 446-B bank $56 region then `gd_skill_desc_extra`, battle lines = the
bank $4C pool (MagicBurn's 56-B slot + `gd_custom_msgs`); all 21 new skills with 9-letter
names and full texts fit (test).

**Element.** `element` = one of the 27 resistance names (gamedata.RESIST_NAMES), "none"
(every target takes full damage: level 0), or null = the skill's own. It is not a record
field: a damage handler reads ONE 2-bit resistance level of its target and passes it to a
damage ladder (BATTLE_SKILL_SYSTEM §15.3). Regions `gd_skill_elements` = `StockElemTable`
(222 B, stock ids) + `CustomElemTable` (33 B, $DE-$FE), $FF = no override, $FE = none.
Setting it also moves the AI's assumed element (record +5 = element+1, unless
`record.status_id` is explicit). Which skills have a native element:
`extracted/skill_element_census.json` (38 elemental; the editor offers the box only there).

**Regions** (all same-address, byte-identical to S110 with no edits — test):
`gd_custom_records` ($54, `CustomRecordPtrTable` 33 dw + one 19-B record per skill; unused
ids → Blaze's `$41CF`), `gd_custom_skill_mp` ($07, 33 dw at $7F59 — moved from the bank's
end), `gd_custom_learn` + `gd_custom_base` + `gd_skill_elements` + `gd_tame_meter` +
`gd_quake_power` ($72), `gd_custom_announce_lo` (`AnnounceTemplateTable` slots $DE-$E1) +
`gd_custom_announce` ($E2-$FE) + `gd_custom_target` (`CustomTargetBaseTable`) ($58),
`gd_custom_msg_ptrs` + `gd_custom_msg_a` + `gd_custom_msgs` ($4C), `gd_custom_present`
($5F), `gd_custom_sfx` ($55), `gd_custom_skill_name_ptrs` + `gd_custom_skill_names` ($41),
`gd_custom_skill_desc_ptrs` + `gd_custom_skill_desc` ($56), (S111b) `gd_custom_ratios` ($72) —
20 regions. `gd_custom_target` S111b: MagicBurn = Firebal's row ($03), Tame ×3 = Blaze's
($00) — the S84 self row $6367 made the act-time AI cast them at its own side (measured).

**Engine changes (hand patches, BATTLE_SKILL_SYSTEM §13.9 / §15.3):** bank $72
`FarSkillFork` reads `CustomBaseTable` (a non-$FF entry → the vanilla handler of the base),
`CustomBattleExec` returns the element for bank $52 `CustomElemTail52`, new entries 5
`ElemLevel72` and 6 `CustomLearnRow72`; bank $52's 24 ladder calls → `ElemLadderA` /
`ElemLadderBreath` / `ElemLadderSlash` in the dead $51B3 pocket; bank $06 `LearnLoopFork`
scans the custom ids through `wLearnRowBuf` ($D10C, 18 B carved from wCustomPool); bank $55
`SfxPresentId` reads `CustomSfxTable` for custom ids (default $09 — S110 builds read past
each 222-B SFX table: custom ids played the NEXT kind's sounds, the last kind's read code);
bank $58 `DispatchBoundsStub` reads `CustomTargetBaseTable`; bank $50 `SaveBtl_5ad2`
returns custom ids unchanged (the `{skill}` insert printed "CleanCut" for ids ≥ $DE).
Pinned behaviour: the example build's battles of the 10 built-ins = S110 (A/B in PyBoy;
same lines, acts, MP; damage only RNG drift).

**Tests:** test_compiler `test_custom_skills_s111` — the committed patches carry the
example's region text; the 10 built-ins == custom_skills.json; the empty tables (base $FF,
sfx $09, elements $FF); the CS_FIX fixture (Thunder / FrostBite / Rumble / Blaze→Ice:
base, sounds, looks, AI target row, element + record +5, MP, quake power, names, learn
rows, own announce); 15 refusals; 21 new skills compile. `--rom`
`test_custom_skills_rom` on the example, CS_FIX and 21-new builds — `Fork54_RecordIndex`,
`MPPtrFromId`, `AnnounceIdxFork`, `FarSkillFork`, `ElemLevel72`, `CustomLearnRow72` RUN
from the ROM bytes (MiniSM83, now with calls / push / 16-bit adds) for every custom id;
names / SKIL texts through the pointer tables; `extract_custom_skills` reads the baseline
back out of the example build. test_app S111 block (Quake MP / element / announce,
MagicBurn's MP box disabled, New skill… on Zap, looks / sounds / element / prereqs, the
Upper element box disabled, Blaze → Ice moves the AI element, delete, undo restores
project.json). S111b: + the ratio fixture (MagicBurn 1/4 + 3, TameMore 1/2, Anchor 1/2,
Quake 1/2, Mourn 1/2), 5 ratio refusals, `ScaleHL72` / `AnchorKeepMP72` RUN from the ROM, the
bank $73 call bytes; test_app: the burn edit, a refused 9, Mourn 1/2. **Pin** `5a1c5404…`
(patched), was `4a2860cf…` (patched, historical) ← `534bfb62…` (patched, historical).

## §2.28 S112 — NEW battle animations + a skill's own presentation (`custom.animations`, `gamedata.skills.<id>.presentation`, ROADMAP P3.11e)

Module `editor2/core/battle_anims.py` (decoder of the 45 stock animations — the same code
`tools/decode_battle_animations.py` writes `extracted/battle_animations.json` with —, the
model `compose()`, `check()` from `validators.validate` and the Monsters / Skills commit,
the emitters, the preview helpers); editor model `editor2/core/anims_doc.py`
(`AnimsMixin`); the **Animations** tab (`editor2/app/anims_tab.py`) and the Skills tab's
**Animation** section; help `57_animations.md` + `54_skills.md`. Engine: BATTLE_SKILL_SYSTEM
§11.9 (the system as measured, the forks, the measurements).

```jsonc
"custom": {"animations": [
  {"id": "spark_storm", "name": "Spark storm", "steps": [
     {"from": 16, "frame": 0, "hold": 4},     // stock $10 (Zap) frame 0, 5 screen frames
     {"sound": 130},                          // sound effect $82, takes no time
     {"from": 16, "frame": 3, "hold": 5},
     {"from": 6,  "frame": 1, "hold": 2},     // stock $06 (Bang)
     {"blank": true, "hold": 2}]}]},          // nothing, 3 frames
"gamedata": {"skills": {
  "16": {"presentation": {"kind": "animation", "animation": "spark_storm", "motion": 2}},
  "64": {"presentation": {"kind": "animation", "animation": 38, "motion": 0}},  // stock $26
  "94": {"presentation": {"kind": "effect", "effect": 4}},                       // blink
  "44": {"presentation": {"kind": "none"}}}}
```

**Numbers.** The i-th entry of `custom.animations` = animation **$2D + i** (at most 32:
the developers' viewer lists $00-$4C). The stock $00-$2C are never touched. A presentation
names a stock number (0-44) or a custom id (it follows the entry when the list is
reordered).

**Compose** (`BA.compose`, the bytes the engine reads): each distinct (source, frame) =
one frame (the stock sprites; tiles renumbered into ONE new sheet in first-use order;
attr bits 0-2 = the source's palette slot); a blank = one shared empty frame; timeline =
one pair per step (`(frame, hold)` / `($FD, sound)`) + `($FF, $FF)`; palettes = each
source's stock palette with its stock shade BAKED in (`display_palette`: hardware colour
i = buffer colour [1,2,0,3][(shade >> 2i) & 3], measured) — the engine then uses the
identity shade $D2. **Refusals (AnimError → ProjectError):** no frame step; a step that is
none of frame / sound / blank; `from` not 0-44; `frame` not 0-31; hold not 0-255; sound not
0-254; > 4 source animations; > 128 tiles; > 200 frames; > 120 steps; > 32 animations; ids
missing / twice; a presentation `kind` not animation / effect / none, `motion` not 0-3,
`effect` not 4-12 / 14 / 15, an animation that is neither 0-44 nor a custom id, an id >
254. Warning: a stock frame drawing a tile outside its sheet (drawn empty — none in the
45).

**Emitters** (`emitters._anim_entries()`):

| Emitter | Target | Content |
|---|---|---|
| `anims6f` | `file:patches/bank_06f.asm` | `CUSTOM_ANIM_COUNT EQU n` + template `bank_06f_head.asm` + `CustomAnimFrameTable` / `CustomAnimTimelines` / `CustomAnimPalettes` (db count + 4 dw each) / `CustomAnimGfxIds` ($70kk) — n + 1 rows, the last = `CustomAnimNone` — and per animation `CustomAnim{k}_Frames` / `_F{i}` / `_Timeline` / `_Palettes` |
| `anims70` | `file:patches/bank_070.asm` | bank byte, `CustomAnimSheetPtrs`, `CustomAnimSheet{k}` (the bank $50 gfx-stream format, `encode_safe`), the last an empty sheet |
| `gd_anim_routine` / `gd_anim_cmd` | `region:` in `patches/bank_05f.asm` | `SkillRoutineOverride` / `SkillAnimOverride` (256 B each, by real skill id; $FF = the look's) |

With no animations and no presentations the regions are all $FF and bank $6F holds the
engine + `CustomAnimNone` only: the user's project and the example behave exactly as S111
(PyBoy A/B, RNG pinned). `validators.bank_usage` counts banks $6F (generated part after
"NEW ANIMATION DATA (generated") and $70; `TEMPLATE_SIZE[$6F]` = **391 B**
(`CustomAnimFrameTable @ $4187`).

**Hand patches** (BATTLE_SKILL_SYSTEM §11.9.1): ROM0 two operands ($5E → $6F),
`patches/bank_002.asm` (new, `ReadSeqStepFork`), bank $50 `AnimLoadFork50`, bank $5F
forks + viewer, `game.asm` INCLUDEs `bank_06f.asm` / `bank_070.asm`.

**Tests:** test_compiler `test_anims_s112` (regions all $FF in the committed patches, the
presentation rows of a fixture, compose checks — frames, palette slots, tiles, timeline —,
the refusals, 32 animations compile) and `--rom` `test_anims_rom` (the tables read back
from the ROM == compose; the fork bytes; the override rows). test_app S112 block. **Pin**
`9ce03bd0…` (patched), was `5a1c5404…` (patched, historical).

## §2.29 S113 — breeding: the auto-ordered special table, `removes`, `table` (ROADMAP P3.12)

BREEDING_SYSTEM "Auto-ordered special table (S113)" + "The resolver as measured
(S113)"; EDITOR_DESIGN §5.4 "As built S113"; help `58_breeding.md`.

```jsonc
"breeding": {
  "family":  {"8": {"p1": "Slime", "p2": "Slime"}, "37": null},
  "special": {"overrides": [{"index": 0, "min_plus": 9}],
              "removes":   [{"index": 755}],
              "appends":   [{"p1": 9, "p2": 42, "result": 221}]}
}
// or, for heavy rework / the generator (no overrides / removes / appends with it):
"special": {"table": [{"p1": "Spirit", "p2": 42, "min_plus": 0, "result": 221, "plus_mod": 0}, …]}
```

* **Auto-order.** With any special edit the effective rows (vanilla with overrides,
  minus removes, plus appends — or the `table`) are emitted stably sorted: species ×
  species, species × family, family × species, family × family, higher `min_plus` first
  within each (`Gamedata.special_key`). No edits = the vanilla 825 in vanilla order (the
  regression). Measured: sorting vanilla changes no result (BREEDING_SYSTEM). The region
  comment marks EDITED / ADDED / TABLE rows; `Gamedata.special_src[i]` = where emitted
  row i came from (`('vanilla'|'edited', vanilla index)` / `('added'|'table', k)`),
  `special_removed` = the removed vanilla rows.
* **`removes`** = `{index}` or `{match: {p1, p2}}` (the first vanilla row that fires for
  that cross); a row may not be both removed and overridden.
* **`table`** replaces the whole special table (≤ 1650 rows); `min_plus` / `plus_mod`
  default 0 (also for appends since S113).
* **ERROR:** two rows with the same `p1`, `p2`, `min_plus` when either came from the
  project (the second could never fire) — the message names both. Vanilla's own two
  such pairs (682/693, 802/803) are allowed (the editor lists them as "never fires").
  The S103 dead-append / shadowed-override errors are gone (an appended row is never
  "after" the rows it should beat any more).
* **Matcher spelling.** A family NAME wins over a species name: `"Slime"` is the Slime
  FAMILY. The editor writes species as ids (ints) and families by name; two vanilla
  species share the name DracoLord (200 / 201) — use ids.
* **Family warnings** (a family slot beaten by a special row / out-ranked by a later
  identical slot) are summarised after 8 (a generated tree edits every slot).
* **Engine (same delivery):** bank $16 `BreedCreateOffspring` passes the FX1 staging
  indices `$28/$29` in `$DA75/$DA76` (was `$14/$15` = farm slots 20/21 — every egg +1,
  no "+N" row fired, S71 → S112; BREEDING_SYSTEM "The FX1 egg-plus bug").
* **Pin:** **`8cf0b93bbb7a91ac27ba4b8de5c40a66`** (patched; built S113, NOT yet
  user-tested): the example's 3 overrides + 2 appends move into the species × species
  block (bank $69 $4050-$5075) + the 2 bytes at $16:$4072 / $4077. Prev `9ce03bd0…`
  (patched, historical).
* **Model / GUI:** `editor2/core/breeding.py` (resolver model, `FastResolver`,
  `obtainable`, `Analysis`), `editor2/core/breed_gen.py` (`propose` — any `max_depth` up to
  `MAX_DEPTH_LIMIT` 40, `default_profile(max_depth)`, shares normalised, best of
  max(5, 2 × depth) attempts; `to_gamedata`, `apply_to`), `editor2/core/breeding_doc.py` (`BreedingMixin` on Document: setters
  `set_family_recipe`, `add_special`, `set_special`, `remove_special`,
  `restore_special`, `special_to_table`, `special_to_vanilla`, `apply_breeding`),
  `editor2/app/breeding_tab.py`.
* **Tests:** test_compiler `test_special_auto_order` (no edits = vanilla order; an
  append wins and the table stays sorted; every other cross unchanged; + rows first;
  removes; table; refusals) + `test_breeding_analysis` (indexed resolver == the model,
  vanilla tree, gifts, the example, the generator: seeded, compiles, pins kept);
  test_app "Breeding tab (S113)".

## §2.30 S114 — encounter lists: the project's own lists, room lists, gate plans, flag variants, rates (`custom.encounter_lists`, `custom.rooms[].encounters`, `custom.gates[].encounters`; ROADMAP P3.13a)

DATA_STRUCTURES "Encounter list choice (S114)" (the engine, measured); EDITOR_DESIGN §5.5
"As built S114"; help `59_encounters.md`. Module `editor2/core/encounters.py` (the model +
the emitter), `editor2/core/encounters_doc.py` (`EncountersMixin` on Document),
`editor2/app/encounters_tab.py`.

```jsonc
"custom": {
  "encounter_lists": [                    // numbers 128, 129, … in order (≤ 128 lists)
    {"id": "den_by_day", "name": "Den by day",
     "rate": 3, "unk1": 3, "size_chance": [5, 5, 0],           // the 26-byte pool format,
     "slot_chance": [5, 3, 2, 0, 0], "eids": [17, 32, "klamutra", 0, 0],   // same field
     "max_count": [2, 1, 2, 0, 0], "maze_size": 15}],          // names as gamedata.encounters
  "rooms": [{"id": "howling_den", …, "encounters": {
     "enabled": true, "list": "den_by_day",                   // its OWN list (no gate pin)
     "variants": [{"when": [{"flag": "den_night"}], "list": "den_at_night"}],
     "rate": 7}}],                                            // own rate code 0-7 (any mode)
  "gates": [{"gate": 0, "encounters": {
     "floors": [{"floors": [1, 2], "list": "beginning_dragons"}],   // game numbering
     "variants": [{"when": [{"flag": "den_night"}],
                   "floors": [{"floors": "all", "list": "den_at_night"}]}]}}]
}
```

* **List refs:** a number 0-127 (the game's lists, still edited through
  `gamedata.encounters`, §2.20), a number 128+ (a project list) or a project list id.
  A project list's omitted fields default to rate 3, unk1 3, size [7,0,0], slots
  [7,0,0,0,0], max [1,1,1,1,1], maze 15; the S103 list checks apply (`gamedata.
  apply_list_fields` / `check_list`, shared): chances ≥ 100 %, no freezing 2-3 draw, real
  EIDs (0-486 or a project enemy by id / EID).
* **Rooms:** `list` present = its own list — RoomEncTable (bank $71) row `[1, $FF, 0]`
  (never pins wGateID, so a room served inside a dive keeps the dive) and bank $76
  `EncRoomTable` names the variant list. Without `list`: `gate_id` / `floor` (pinned at each
  step, S42) or `follow_gate` (S100) as before; `rate` alone = the gate's list at the
  room's rate. `variants` need `list`; each needs ≥ 1 flag term (≤ 8; the gate-insert term
  form). WARN: list / rate on a room with encounters off; `gate_id` / `floor` ignored next
  to `list`.
* **Gates:** `custom.gates[]` may now carry only `encounters` (GATE_KEYS += `encounters`).
  `floors` runs (`[a, b]` / `n` / `"all"` = 1 .. floor count − 1) set a floor's list; a floor
  no run covers keeps the vanilla rule (`encounters.vanilla_number` — the bank $01 walk:
  sub-index = breakpoints ≤ floor) and follows the gate's floor count. A variant's
  uncovered floors take the gate's own plan. ERROR: a floor in two runs, a floor outside
  1 .. floor count. Gate numbers 0-255 are accepted by the engine table (`GATE_PLAN_LEN`
  = the highest planned gate + 1); custom.gates still validates 0-31 until the new-gates
  arc (ROADMAP NG1).
* **Emitter `enc76`** → `patches/bank_076.asm` (whole file): template
  `bank_076_head.asm` (`EncResolve` / `EncPickVariant` / `EncFloorRun` /
  `EncVanillaNumber`, TEMPLATE_SIZE 241 B, pinned `2f0634f5…9f`) + `ENC_ROOM_LEN` /
  `EncRoomTable` (3 B per room, index mapID − $6B: dw variant list, db rate $FF = none) +
  the variant lists (`[n_terms][terms][dw target]`, last n_terms 0) + `GATE_PLAN_LEN` /
  `GatePlanPtrs` + per gate `EncGatePlan_GG` / `EncGateRuns_GG_k|d` (`[last floor, list]`,
  the last `$FF`) + `ProjectEncLists` (26 B each) + `VanillaGateBase` /
  `VanillaGateBpPtrs` / `VanillaBreakpoints` (byte copies of bank $01's rule, from
  `extracted/gamedata_vanilla.json` tables `gate_base_pool` / `gate_bp_ptrs` /
  `floor_breakpoints`). No data = the vanilla rule. Accounting: template + payload ≤ $4000.
* **Engine (hand, same delivery):** `patches/bank_001.asm` — `LoadNextDungeonFloor`
  same-size (65 B) far-calls bank $76 entry 0 and copies the chosen list into
  `wEncListBuf` ($D11E, carved from wCustomPool, `patches/wram.asm`); the five list
  readers `ld hl, wEncListBuf + k / ld bc, $0000` + pad (same size; BC = 0 is what the old
  `Mul16x8To24` left — the slot sums start from B, KEY_LESSONS S114); `patches/game.asm`
  includes `bank_076.asm`; verify_integrity PATCH_NEW_FILES += `bank_076.asm`.
* **Pin:** **`dbc4dee947ccc3dbf1fb3092fdf9e143`** (patched; built S114, test ROM
  USER-CONFIRMED 2026-10-03 09:52 ("Looks good. Give editor files")) — the example has no encounter data; the delta is the bank $01 forks + bank
  $76. Prev `8cf0b93b…` (patched, historical; S113).
* **Measured (tools/census_encounters.py, PyBoy stub calls):** ORIGINAL ROM vs the
  vanilla model 633 list choices + 15,192 battle draws, 0 mismatches; the example build
  the same; the S114 fixture (lists, room + gate variants, rates) 641 + 15,384, 0; the
  user's project 633 + 15,192, 0; the demo 639 + 15,336, 0; negative control (draw rule
  `>` for `>=`) 1,417 mismatches. Field runs on the user's save: DATA_STRUCTURES.
* **Tests:** test_compiler `test_encounters_s114` (vanilla rule == the regenerated
  `encounters.json`, real chances, steps, the fixture's tables, the model, 12 refusals,
  128 lists compile, the doc API) + `test_encounters_rom` (the forks' bytes, $6A22-$6AAD
  unmoved, ProjectEncLists / VanillaGateBase read back) on the example and the fixture;
  test_app "Encounters tab (S114)".

## §2.31 S115 — NEW gates 32-95 (`custom.gates[]` with `copy_of`; gate-entrance exits; ROADMAP NG1)

GATE_GENERATION §7.8 (the engine, measured); EDITOR_DESIGN §5.1b "As built S115"; help
`60_gates.md` "New gates". Modules: `editor2/core/gates.py` (helpers + `GatesMixin`
`new_gate` / `delete_gate` / `add_gate_entrance` / `gate_entrances` / `all_gates`),
`project.gate_configs` (rows), `encounters.py` (`Model.vanilla`, the bank $76 data).

```jsonc
"custom": {
  "gates": [
    {"gate": 32,                 // 32-95: a NEW gate number
     "copy_of": 3,               // required: the vanilla gate (0-31) it starts as
     "name": "Ember Gate",       // required (editor only; not put into the game)
     "floors": 4,                // optional, 2-99 incl. the boss floor (default: the source's)
     "boss": "ember_throne",     // optional, as §2.17 (default: the source's vanilla boss room)
     "hand_made": false,         // optional, as §2.17
     "encounters": {…}}          // optional, as §2.30 (unplanned floors: the source's rule)
  ],
  "rooms": [{ … "screens": {"0": {"exits": [
    {"x": 5, "y": 2, "dest": "gate:32", "gate_flag": 1,     // a gate entrance (any gate 0-95)
     "screen_byte": "0x00", "spawn_x": 0, "spawn_y": 0}]}}}]
}
```

* **Emitted** (`enc76`, bank $76 data after the template): `NEW_GATE_LEN` = highest new
  gate − 31; `NewGateRows` 8 B per number 32 .. (the source's `GateFloorDataTable` row with
  byte 3 = floors, bytes 4-6 = boss map + arrival tile; a gap = gate 0's row — never
  entered, the validator refuses entrances to it); `NewGateSource` 1 B each.
  `gates16` still emits exactly the 32 vanilla rows (an example without new gates is
  byte-identical there). `custom.gate_inserts[].gate` and `custom.gates[].encounters`
  accept defined new gates (`GateInsertTable` gate byte = the number).
* **Hard errors:** a new gate without `copy_of` (0-31) or `name`; a gate number outside
  0-95; `copy_of` / `name` on a vanilla gate; a rule on an undefined gate; a gate
  entrance (gate_flag 1) to an undefined gate.
* **Warnings:** a new gate with no entrance in any room / entrance redirect; a new gate
  whose boss floor is a VANILLA boss room (its scripts run unchanged: the original
  gate's cleared flag, boss, King's speech).
* **S120:** a new gate's floor-type rows (bytes 0-2) and depth tier (byte 7) are
  editable like any gate's (§2.17 "S120") — without them, the source's. Entrance conditions (NG2) are plain exit rows / room states
  today (S117: the swirl + the cleared flag — §2.32; the portal itself stays a plain exit,
  like the game's).

## §2.32 S117 — extended flags, gate swirls / "cleared" (ROADMAP NG2), shops + item prices (ROADMAP P3.13c)

Engine: EVENT_FLAGS "Extended flags (S117)", GATE_GENERATION §7.9, DATA_STRUCTURES "Shops
(S117)", ROOM_DATA_FORMAT "Condition prefixes". Editor: EDITOR_DESIGN §5.1b / §5.7 "As
built S117"; help `30_flags.md`, `60_gates.md` "Swirls and cleared", `62_shops.md`.
Modules: `project.py` (flag pool, `npc_conditions`, `gate_clear_rows`,
`vanilla_swirl_overrides`, `_lower_shop_scripts`), `gates.py` (`gate_cleared`,
`swirl_npc`, `GatesMixin` swirls / portal redirects / `paint_swirl`), `shops.py` (resolve,
emitters), `shops_doc.py` (`ShopsMixin`).

```jsonc
"custom": {
  "flags": [{"name": "hall_bell", "index": "0x1100"}],   // 0x1000-0x179F now allowed
  "rooms": [{ … "screens": {"0": {"npcs": [
    {"kind": "npc", "x": 2, "y": 2, "sprite": "0x4d", "script": null,
     "swirl_of": 32},                                     // shown while gate 32 is NOT cleared
    {"kind": "npc", "x": 7, "y": 5, "sprite": "0x4c", "script": "slime",
     "shown_when": [{"flag": "hall_bell", "is": "set"}]}  // "set" | "clear"; ANDed
  ]}}}],
  "entrance_redirects": [                                 // a vanilla PORTAL led to another gate
    {"mapID": "0x24", "screen": 0, "x": 2, "y": 2, "dest": "gate:32", "gate_flag": 1}],
  "shops": [{"id": "hall_shop", "name": "Portal Hall stall", "items": [1, 5, 3, 29]}],
  "scripts": [{"id": "hall_keeper", "shop": {"shop": "hall_shop",       // or a vanilla key
                                            "text": "hall_shop_hi"}}]   // greeting (optional)
},
"gamedata": {
  "items": {"1": {"price": 12}},                          // buy price, every shop (0-65535)
  "shops": {"bazaar": [1, 2, 7, 40, 19, 20, 29, 38]}      // bazaar starry books rare gate
}
```

* **Flags.** `FLAG_SAFE_RANGES` = `$0158-$0167` + **`$1000-$179F`** (S124: `$179D` since S121, new flags from `FLAG_AUTO_RANGES` without `$0158` — 1,965 — §2.7; was 1,968 named
  flags); `$17A0-$17FF` = the gates' own cleared flags (`GATE_FLAG_BASE + gate`). Any
  flag reference may be **`gate:N`** = gate N's cleared flag (`resolve_flag_ref` →
  `gates.gate_cleared`): the vanilla flag of an unchanged vanilla gate
  (`extracted/gate_names.json`), the own flag of a new gate or a re-bossed vanilla gate.
  `flag_persistent()` covers the extended range (state-rule / variant persistence checks).
* **Swirls / conditions** (`Project.npc_conditions`): `swirl_of: N` → `(cleared flag,
  CLEAR)`; `shown_when` terms → `(flag, SET|CLEAR)`; ≤ 8 per NPC (S120: authored in the
  NPC panel's *shown when* → Flags… — `Document.set_npc_shown_when`; was JSON-only). Emitted (`_npc_cond_lines`)
  as `db $A0|$A1, lo, hi, $FF, $FF` before the NPC (typed and raw entries). Bank $60 data
  also gets **`VanillaNPCExtTable`** (always emitted; `$FF` = empty) from
  `vanilla_swirl_overrides()` — per vanilla portal room / screen whose portal enters a
  re-bossed gate or is re-routed (`entrance_redirects` with `dest gate:N`): rows `db mapID,
  screen / dw step counter / db n_steps / dw VNpcMM_k_Vn …`, each variant = the vanilla
  step list with the swirl at that cell conditioned on the entered gate's cleared flag
  (appended when the list has none there and < 8 NPCs).
* **Cleared mark** (`enc76`, bank $76 data): `GATE_CLEAR_LEN` + **`GateClearTable`**
  (`gate_clear_rows()`): per gate 0 .. highest gate needing one, `dw own, vanilla`
  (`$FFFF` = none; an unchanged vanilla gate = both `$FFFF`). Read by bank $76 entry 2
  `GateBossWin`.
* **Shops** (`shops77` → `patches/bank_077.asm`, the whole file = template head + data):
  `SHOP_COUNT`, `ShopPtrTable` (the five vanilla lists in the vanilla order, then
  `custom.shops`), `ShopList_n` (item ids, `$FF`). **Prices** = region `gd_item_info`
  (`patches/bank_003.asm`, `ItemInfoTable` 44 × 12 B; only +1/+2 change).
  A `shop` script is lowered (`_lower_shop_scripts`, before the talk lowering) to `text
  <greeting or $0680>`, `op write_ram wShopID n+1`, `op 0x04 0 $0680` (the shop opcode —
  deliberately left unnamed in `scriptgen.OPS`: a name there would make
  `Document._migrate`'s regrouping rewrite every raw `"0x04"` of existing projects),
  `text $0682`, `end`.
* **Hard errors:** a flag index outside the pool / the vanilla range; `swirl_of` an
  undefined gate; more than 8 conditions; an item id outside 1-43; a shop list empty or
  longer than 20; a price outside 0-65535; an unknown vanilla shop key / duplicate shop
  id; a `shop` script naming an unknown shop; more than 250 shop lists (wShopID is a
  byte); `entrance_redirects` with `gate:N` to an undefined gate.
* **Sprite-limit warnings (S117b; user: "Just warning is fine for now, and Ill build
  around it"):** `formats.sprite_budget(npcs)` per screen state (visible NPC entries;
  conditional ones count): a ROW with more than 1 NPC (10 objects per screen line, the
  player + 3 monsters in a line use 8) and more than 6 NPCs on screen (40 objects, the
  party 16) — build warnings (`_validate_state`) and the Rooms tab note
  (ROOM_DATA_FORMAT "Sprite limits (S117b)").
* **Bank accounting:** bank $77 = template (438 B since S117b; 93 B S117) + 2 B per list + the lists; bank $60 /
  $76 TEMPLATE_SIZE 678 / 358 B (validators.py).
* **Example project:** no swirls / conditions / shops / prices → `VanillaNPCExtTable` =
  `$FF`, `GateClearTable` rows `$FFFF`, the five vanilla lists, `ItemInfoTable` = the
  ROM's bytes. Pin `110210b0…` (patched, S117b; S117: `31cc5b31…`, patched, historical) —
  the engine change only.

## §2.33 S119 — the project's own CUTSCENES (`custom.rooms[].cutscenes[]`, ROADMAP P3.8 part B)

User direction (S119): "Should be specific NPCs. Design should be visual … operates by
tile … Custom cutscenes should be previewable. Everything should be in tiles." A
cutscene belongs to a room; actors are NAMED NPCs of its screen; every place is a cell
(0-9 x 0-7, a little outside allowed for walking off). Code: `editor2/core/cutscene_build.py`
(the lowering AND the editor's model — one pass, so the picture and the bytes cannot
drift), `editor2/core/cutscene_doc.py` (the editor's data edits), GUI
`editor2/app/cutscene_editor.py` (EDITOR_DESIGN §5.1d "As built S119").

```jsonc
"cutscenes": [{
  "id": "welcome", "name": "Welcome", "screen": 0,
  "trigger": {"on": "entry" | "talk" | "examine" | "stepon",
              "actor": "Host",                 // talk: the NPC talked to
              "x": 4, "y": 3, "facing": "any", // examine / step-on cell (the spot is
                                               // made when the screen has none there)
              "when_on": ["flag"], "when_off": ["flag"],
              "once": "welcome_seen"},         // a custom.flags name: tested + set first
  "player_start": {"x": 4, "y": 6, "face": "up"},   // entry scenes (optional)
  "disabled": false,
  "steps": [ … ]}]
```

**Actors.** `"actor": "<name>"` on an NPC entry (typed or `raw`; every state of the
screen); `"player"` = the player. `Cast(room, screen)` resolves a name to the slot
number the game uses (NPC n = the n-th NPC entry of the state's list, spots not
counted — the emitter puts spots first, so the number is the authored order of the
NPCs); a name at DIFFERENT numbers in different states is an ERROR (the game moves NPCs
by number); a name missing from a state = warning. A **cast member** = `"hidden": true,
"cast": true` (+ hidden pads `sprite $FF` so it has the same number in every state —
`cutscene_doc.add_cast`; 8 NPCs per screen).

**Steps** (exactly one kind key each — the list and the meanings: the module doc /
`STEP_NAMES`): say, ask (+ yes / no), if (+ then / else), set, clear, walk {actor, to,
first x|y, together, fast, keep_facing}, face {actor, dir | toward}, show / hide {actor,
how instant|flicker|spin, at}, anim {actor, move (`ANIMS`, the measured `$1C` programs)},
fly {actor, dir in_left|in_right|off_left|off_right, to (in), length 1-9, curve 0-5},
name_hero (S121, §2.34),
wait {frames}, wait_walks, music {song} | "back", sound <id>, shake {dir, frames, wait},
fade {to black|normal, step}, flash {frames}, followers hide|show, give_item {item, got,
full}, give_monster {enemy, got, full}, tiles {x, y, w, h, copy {screen, state}} or
{x, y, rows}, battle, move, end. TEXT = a dialogue id or `{"boxes": [[…]]}` (inline; the
lowering adds the dialogue entry `cs_<id>_sayN` …; checked like `boxes` dialogue).

**Lowering (`lower_project`, called by `Project.__init__` right after the helper
scripts are lowered, so every script it wraps is already ops).** Per room, the scenes
are grouped by trigger (`trigger_key`); each group becomes ONE script
`cut:<room>:<key>`: for each scene a guard (`branch_screen` on multi-screen rooms for
entry scenes, `if_flag_clear`/`if_flag_set` for when_on / when_off, `once` = test +
`set_flag` FIRST) then its body, then the trigger's ORIGINAL script inlined (labels
prefixed `o_`): an entry scene ends with `goto` to the room's own arrival script, a
talk / spot scene ends there (the NPC's own talk runs when no scene plays). Wiring:
entry → `scripts["0"]`; talk → every entry of the named NPC on that screen gets the
new script (raw entries: byte 4 = its index); examine / step-on → the spot at that cell
(made, all states, when missing). Rules from PyBoy (BANK04_SCRIPT_ENGINE "Writing
scenes (S119)"): `init_dialog` before every text after a yielding step (talk scripts
too), `close_text` before any other step and before the end; a walk of an actor whose
place the model KNOWS is a queued `$1A`/`$1B` in pixels (together = no `wait_movement`
until the next waited step), else the exact `$10`/`$11` (absolute pixels; the scene
waits); `face toward` needs both places known; `show` instant = `npc_write n,0,<the
entry's own type byte & ~$40>`; flicker / spin = programs `$08` / `$0D` / `$14`; fly in
= the start pixels written to the slot (`+$18`/`+$1A`) so it LANDS on the cell, `$D8E3`
= curve·256 + length, then `$15`-`$18`; shake = `$C8B1`/`$C8B2`; fade = the vanilla
`$C89B-$C89D` shade steps; give = `check_inv_full` / `check_storage_full` first.
**tiles** (part d): the cells (copied from another screen / state's layout + attr
grids — `layout_grid`: the BG bytes the loader writes ARE the layout bytes, measured
S119) → `room.patch_data["cs_<id>_<n>"]` / `…_attr` = `[offset lo, hi, bytes…, $D8 next
row, $D9]` (offset = 8-px row·32 + column from the visible top-left) and ops `$24` /
`$61` with the param `patch:<name>`.

**`patch_data` (S119 part d).** `custom.rooms[].patch_data = {name: [bytes]}`; a script
param `"patch:<name>"` is replaced by `CustomRoom<n>_Patch_<name>` (emitted after the
room's scripts in bank $60, `emitters._patch_data_lines`). Engine: bank $04
`ScriptCmd24` / `ScriptCmd61` call bank $60 entries 9 / 10 (`CustomDrawTiles` /
`CustomDrawAttrs`, template) instead of bank $0F's — same size (`ld hl,$0f01` →
`$6009`, `$0f02` → `$600a`); for a bank $60 script (GateAwareDispatch's rule) they read
the param through `CustomScriptRead` and draw the patch from bank $60 (bank $0C's
drawing, copied), else they far-call bank $0F as before. **Copies of game rooms:**
`Document._migrate_clone_patches` (on open and in Make editable) copies each `$24` /
`$61` patch of the copied scripts from the source's script bank in the ROM into
`patch_data["v<bank>_<addr>"]` and points the op at it (shared scripts: every room
running it gets the data). PyBoy S119: a copy of the Castle draws its chest patch at the
same BG cells as the original; without the redirect nothing is drawn.

**Validators / errors (S119b: recorded at load as `Project.cutscene_error`, reported by
`validators.validate` — the build stops; `Project()` itself no longer raises, because the
editor's Families / Breeding / Monsters models build one and a half-written scene crashed
the editor at open, KEY_LESSONS S119b):** a scene id twice; trigger problems
(`trigger_problems`: no such screen, talk to an unnamed / hidden NPC or the player, a
spot off the screen); every step problem the lowering finds (unknown actor, a name at
two slot numbers, a cell too far off the screen, a tile piece past the edge, a text that
does not fit, a fly for the player …). The editor shows the same list live (`analyse`).

**Pin:** the engine change (bank $04 redirect + the bank $60 template, re-pinned)
moves the example build: **`d19259a1…` (patched, historical since S120b → `97659a4a…`, §2.3)**,
was `110210b0…` (patched, historical). The example project has no cutscenes.

## §2.34 S121 — the MILLY HOOK (`custom.milly_hook`, ROADMAP P3.16 + E7)

User direction (S121): "In the intro, when Milayou disappears into dresser when Waroubou
drags her in, do NOT return control to player to play as terry. Instead, play the
disappearing (screen whirling) effect and sound (just like when Terry steps into dresser)!
But redirect to a new custom room. At THIS POINT, player sprite is no longer Terry, it is
MILLY … This whole thing can be switched off as a 'milly hook' patch." Code:
`editor2/core/milly.py` (lowering + emitters + the roots room), `milly_doc.py` (the
Document mixin), GUI `editor2/app/milly_dialog.py` (Cutscenes → Milly hook…).

```jsonc
"milly_hook": {
  "enabled": true,                       // false / absent = the game as before (Terry)
  "arrive": {"room": "roots_room_milly", // one of the project's rooms
             "screen": 0, "x": 5, "y": 4, "face": "down"},
  "spin": true                           // she spins in (the cast NPC's program) or appears
}
```

**What ON builds (every region same-size; OFF = each region's vanilla text, bank $79 the
empty bank):**

| Region / file | Vanilla | Hook on |
|---|---|---|
| `patches/bank_00e.asm#milly_bedroom_script` | bedroom ($2F) script 0 from pos 951 (`$0E:$4AA4`, 94 words: the glow, then Terry / Watabou) | glow sound `$60`, op `$17`, delay 8; `$03 $179F` (Terry stays drawn through the whirl: the flag acts at the next field load; S121 r2 removed a `$0D` hide here — the user: "terry NPC sprite vanishes abruptly");  four `$13` writes of `$D3 $D4 $D5 $D6 $F0×4` to `$CA42`; `$3B` warp_fade (map lo = the room's mapID, px, py of the arrival cell) — ends the script; `$FFFF` padding |
| `patches/bank_004.asm#milly_shape_04a` / `#milly_shape_04b` | `call HramScr_4126 / ld de, data_4137` (bank $04 entries 2 / 3, type < $10) | `ld hl, $7900 / rst $10 / nop / nop` → bank $79 entry 0 `MillyShapeTable` |
| `patches/bank_001.asm#milly_player_sheet` | `ld de, $2f00 / ld hl, $8000 / call WaitDMATransfer` (`LoadFieldTilesDMA`) | `ld hl, $7901 / rst $10` + 5 `nop` → entry 1 `MillyPlayerSheet` |
| `patches/bank_009.asm#milly_naming_icon` | `FollowerGfxTable09[0]` = `$2f00` (the naming screen's hero icon sheet) | `$3114` (Milayou's sheet) |
| `patches/bank_04f.asm#milly_name_tiles` | `INCBIN …4d40.2bpp ;TERRY` (tiles `$D3-$D6`) | the S120b MILLY drawing (§2.3) |
| `patches/bank_079.asm` (`hooks79`) | `ds $4000, $00` | template `bank_079_head.asm` + `MillyPlayerAttr` (`$03`) + `MillyPlayerGfx` (`$3114`) + the frame-table image |

**S128 r3 — the player drawn as an NPC** (hand patch `patches/bank_00b.asm`, every
project): sprite id `$E0` (the arena's stand-in beside the party) is drawn by
`CmpRoom_4839` with frame id `$5E` (Terry's NPC frames) over the player's VRAM sheet —
with the hook on that sheet is Milayou's, and the figure came out cut up (PyBoy, the
user's save, both arenas). `jr_00b_48ba` = `call MillyE0Type / ld a,b / ret` (same 5 B);
`MillyE0Type` (in room entry 0's 12 dead tileset-select bytes + 3 nops, S40) writes `$14`
(Milayou's NPC frames) when `$179F` is set, else `$5E`. No VRAM cost; hook off = the
vanilla behaviour. REFERENCE_MD5 `fe5fa80a…` (patched).

Bank $79 (template, pinned): entry 0 `MillyShapeTable` — flag `$179F` clear, type ≠ 0 or
the WRAM tables not built → exactly the replaced code (palette `$02`, DE = `data_4137`);
else palette `MillyPlayerAttr` and DE = `wMillyLayout`. Entry 1 `MillyPlayerSheet` — flag
clear → Terry's sheet; set → copies `MillyLayoutImage` (L1 → L2 of 21 words: frames 0-5 =
her six NPC frames (`$05:$407F[$14]`, side frames face right — the player's X-flip makes
left), 6-20 = an empty list) to `wMillyLayout` (WRAM, 160 B carved from wCustomPool, S121)
and DMAs her sheet. The tables live in WRAM because the metasprite builders (ROM0 `$0D91`,
bank $04 `SaveScr_40cd`) read them with bank $04 mapped. The load path's zero-fill of
`$CC80-$D664` clears them; entry 0 then falls back until the next room load rebuilds them
(CONTINUE: measured).

**The arrival (lowered before the cutscenes, `milly.lower`):** the arrival room gets a
hidden cast NPC `__milly_hook` (sprite `$14`, hidden pads so it has one number in every
state of the screen) at the arrival cell and an entry scene `__milly_arrival` first in its
list (trigger entry, once = `hook:milly_arrived` `$179E`, `player_start` = the arrival
cell / facing): hide the player (S121 r2: was done in the bedroom — PyBoy, every frame: no
player sprite before it in the roots room; without the spin she appears exactly when
shown), spin → show the cast spinning, face, hide it; then show the player and face. `_then_next: true` = the scene falls through to the room's next entry scene instead
of `goto` the room's own arrival script (cutscene_build: before S121 only the FIRST
matching entry scene of a room ever played — every scene ended with `goto @cut_orig`).

**Flags:** `$179F` (the player is Milly) and `$179E` (her arrival played) are reserved —
refs `hook:milly` / `hook:milly_arrived` (`Project.resolve_flag_ref`), the named pool is
`$1000-$179D` (`FLAG_SAFE_RANGES`), new games clear them, saves keep them (EVENT_FLAGS).

**The roots room** (`Document.create_roots_room`): `clone_vanilla($08)` named "Roots room
(Milly)", the copied `$08` scripts dropped, NPCs = grey Warubou (`$39`, actor `Warubou`,
below the screen), `animation: none` (map $08's handler pulses a DMG palette —
`formats.ANIM_EXCLUDED`), `text_keeps_sprites: true`, one cutscene `milly_roots` (entry,
once `milly_roots_seen`, player_start (5, 4)): wait 48, Warubou walks up, 4 boxes
(speaker `Warubou`), both walk out, `move` (default GreatTree `vanilla:$01` screen 12 (4,
6); the dialog edits it). When the hook has no arrival yet, it arrives there (5, 4).
**S121 r3 — the naming option** (user: "Waroubou text box, naming screen, then another box
so I can sandwich it between"): a new roots room's scene = Warubou's lines
(`ROOTS_TEXT_ASK`, ending "And who might / you be, girl?"), `name_hero`, a box after
(`ROOTS_TEXT_AFTER`: "{hero}, eh? / Heh heh!", "Come along. The / King wants you.");
`milly.set_naming` / `Document.set_roots_naming` (the dialog's "Warubou asks her name")
adds the naming step + that box right after his first text, or removes each `name_hero`
and the text right after it. PyBoy: boxes → the naming screen (MILLY, her icon) → "MILLY,
eh?" → the walk out.

**Move destinations must be real screens (S121 r3, user: "Redirect from ROOTS ROOM into
SBOSS" crashed):** the dialog kept GreatTree's screen 12 when SBOSS (screens 0 / 4) was
picked; PyBoy: the warp to a screen the room lacks crashes the game (PC in WRAM, map
garbage). `Project._move_words` (every `move` / helper / conversation warp) now raises
`move_screen_problem`: a project room's screens = its `screens` keys, a game room's =
`project.vanilla_screens()` (map_table.json sub-rooms with room data); the Milly dialog
and the cutscene editor's *Go to a room* list only the destination's screens.

**`text_keeps_sprites` (S121):** `custom.rooms[].text_keeps_sprites` → `CustomRoomFlags`
bit 1; bank $06's text-box opener (region `text_sprite_mode`, on when any room has it)
calls bank $71 entry 8 `TextSpriteMode` (maps $08 / $5D as vanilla + these rooms → `$FFD3
:= 0`, so sprites over BG tile ids ≥ `$80` stay drawn while a box is open — ROOM_DATA_FORMAT
"Text boxes and sprites (S121)"). `clone_vanilla` sets it for copies of $08 / $5D.

**The `name_hero` step** (`{"name_hero": true}`): `write_ram $C8F4 0`, `write_ram2 $C8F2
$CA42`, op `$04` 15 0 — the Castle's naming screen (Castle script 0 pos 107-113); it offers
the current name (MILLY with the hook).

**Validators:** hook on → an arrival room that exists, a screen it has, a cell on the
screen, a facing (`HookError` → the build stops; the dialog says it first via
`milly_arrival_problem`).

**Pin:** the example has the hook OFF; S121 moved its build to **`e43e5f58…` (patched; historical since S122, §2.35)**,
was `97659a4a…` (patched, historical): the hero tiles back to TERRY (§2.3) + the bank $71
template (entry 8). test_compiler `test_milly_hook_s121` / `test_milly_rom` (the constants
vs the original ROM, the hook-off bytes, a hook-on build: tiles, bedroom tail, bank $79
table + image resolving to her frames, no label moved in banks $01/$04/$09/$0E/$4F).

## §2.35 S122 — gate themes in custom rooms, maze screens, maze size, the win tails of re-bossed gates (ROADMAP P3.7b part 2, NG2 residual a)

Built S122, PyBoy-verified, NOT yet user-tested. Engine facts: GATE_GENERATION §4 / §7 /
§7.9 / §7.10.

**No new schema keys for themes.** A gate-theme room is an ordinary room whose `record`
draws with a maze floor type's sheet — `gfx_bank "0x28"`, `gfx_id` = the type (0-15),
`collision_threshold "0x30"` — or with a project copy of one (`custom.tilesets[]` whose
origin, `_editor.tileset_origin` / the "copied from vanilla bank $28 id $NN" comment, is
`$28:$0N`). `editor2/core/maze.py theme_of_origin` / `Document.gate_theme(room)` recognise
it (no ordinary room uses those sheets). The example project's S39 island rooms (`$28:$0D`)
are theme 13. Editor operations (`editor2/core/document.py`):

- `new_room(…, gate_theme=t)` → the record above, `render.palette` = a new project palette
  (`add_theme_palette`: the four palettes of `$17:$51F5[t]` with colours 1 / 3 as forced +
  the system rows), `animation 'none'`, `source_mapID "0x00"` (the byte is vestigial at run
  time: the patched `MapIDClampForPalette` sends every custom room to the Castle fallback and
  `wCustomRoomFlag` is re-derived per frame; the user's own project already has three such
  rooms), a floor of tile `$33` on the floor's palette slot.
- `set_room_tileset(rid, 'gate', t)` (+ `use_theme_palette(rid, t)`: a new palette as the
  room default; screens / states with a palette of their own keep it).
- `stamp_maze_screen(rid, key, state, cell, mode)` → a new layout item with the maze
  screen's tiles AND attr (`MazeRom.cell_grids`); the state's `layout` and `attr` both point at
  it; the replaced item goes when nothing else uses it.
- `room_sources_vocab` → `$00-$3F` for a theme room (protected); the Rooms tab picker lists
  the renderer's `maze_vocab()` (15 metatiles + the stairs). `import_metatile` raises
  **`VocabReleaseWouldHelp`** when the needed side is full of unused vocabulary (the GUI asks,
  then releases + borrows in one undo step). `well_metatile` (Stairs down here) returns the
  theme's own stairs `$3C-$3F` while the sheet still holds them.

**Validation:** `gamedata.check_list` — an encounter list's `maze_size` must be **3-15**
(error; GATE_GENERATION §4.2: 1-2 can freeze, 0 / 16+ write past the grid); applies to
`gamedata.encounters` overrides and `custom.encounter_lists`.

**Bank $76 (engine template re-pinned `65e12e5b…d706`; the S117 value `40972da2…` is
historical; TEMPLATE_SIZE 358 → 460):** `GateClearTable` rows are 6 B — `dw own flag,
vanilla flag, WinTail` (`$0000` = none); `GateBossWin` (x6 index) then `jp RunWinTail` for a
row with a tail. `Project.gate_clear_rows()` returns `(gate, own, vanilla, (extra flags,
tails))`; tails = `gates.vanilla_win_program(gate)` from `extracted/gate_names.json`
`win_tails` (tools/map_gate_names.py); `encounters.win_tail_programs` writes per re-bossed
VANILLA gate `WinTail_<gate>:` — `dw $FF03, flag` for the further cleared flags, each tail's
ops (`dw $FFxx, params`; jump targets → local labels `.t<k>_<addr>`; the op that ends the
game's tail → `dw $FF14, <next tail>`), `WinTail_<gate>_end: dw $FFFF`. New gates (32+)
have no tail. The example project re-bosses no vanilla gate: every row `$FFFF, $FFFF,
$0000` — **regression pin `bd0652da…` (patched)**, was `e43e5f58…` (patched, historical).

## §2.36 S123 — WORLDS, NPC colours, the swirl after clearing, the Vanish step (ROADMAP NG3)

Built S123, PyBoy-verified on the user's save, NOT yet user-tested. Engine facts:
GATE_GENERATION §7.11, ROOM_DATA_FORMAT (`$A2`), known_RAM_map (`wNpcColour`).

**`custom.gates[]` (GATE_KEYS += `world`, `cleared_swirl`):**

- `world: {start: {room, screen, x, y}, rooms: [room ids], saving: "calm" | "everywhere" |
  "nowhere", comment}` on a NEW gate (32-95). `Project.gate_configs` forces the gate's
  floor count to **2** (`WORLD_FLOORS`; floor 1 = the world, floor 2 is never reached) and
  `hand_made`, and `gate_insert_rows` appends the start row (`index None`, `world: gid`,
  floor 1, 100 %); a gate rule (`custom.gate_rules`) that targets a world is an ERROR. The
  start room's arrival cell = `start`. A room belongs to at most one world (error).
  `rooms` lists the other rooms (doors join them — ordinary §2.12 doors).
- **Saving:** `room_flags` → JOURNAL by `GateMixin.room_can_save`: a room's own `can_save`
  wins, else the world's rule (`calm` = rooms without battles, `room_has_battles`). The
  editor stores `can_save` only when it differs from that default (`set_can_save`).
- `cleared_swirl: "stop" | 0-7` on ANY gate: `stop` / absent = the S116 hide (`$A1` on the
  gate's `swirl_of` NPCs — custom entrances and `VanillaNPCExtTable` swirls); a palette =
  no hide, the swirl gets `colour {palette, when: gate:N}` instead (`npc_conditions` /
  `npc_colour`). Anything else is an error ("cleared_swirl must be …").
- The world's cleared flag is the gate's own `gate:N` = `$17A0 + N`. `GateBossWin` never
  fires in a world (floor 0+1 ≠ last floor 2); only a conversation step sets it.

**NPC `colour`** (typed and raw NPC entries): `0-7` (always) or `{palette, when: flag ref}`
(only while that flag is SET). Error on a monster NPC (they walk in their own palettes).
Emitted by `emitters._npc_colour_lines` as the prefix `db $A2, pal, flag lo, flag hi, $FF`
(`$FFFF` = always) before the entry.

**Conversation step `{"vanish": {"how": "flicker" | "instant"}}`** (STEP_KINDS += vanish):
for every place the conversation's NPC stands (`_vanish_places`, resolved after the rooms
— `_resolve_vanish_slots`, the scripts are lowered once `_rooms_resolved`): per screen a
`branch_screen`, then `trigger_anim $0Dnn` (the game's vanish-flicker program, slot nn) +
`wait_movement`, or `npc_write n, 0, $40` (hidden at once). Lasting absence = the NPC's
`shown_when` (load-time only — KEY_LESSONS S123).

**Editor (`editor2/core/worlds.py` WorldsMixin):** `new_world`, `set_world_start`,
`add_world_room` / `remove_world_room`, `new_world_room`, `set_world_saving`,
`set_cleared_swirl`, `add_world_entrance` (= `add_gate_entrance` + `paint_swirl`),
`set_world_music`, `world_portal_spot`, `world_report`, and **`make_boss(room, key, state,
index, enemies, flag_name, intro, outro, end_of_world, leave)`** = an ordinary conversation
say → battle → set [own flag (+ `gate:N`)] → vanish → [say] → [helper] + the NPC's
`shown_when` [own flag clear]. `Document.set_npc_colour`. Validators: `_validate_worlds`
(no portal, nothing sets the cleared flag, a room no door reaches, no way out, battles
without a list — warnings).

**Bank $60 (template re-pinned; `TEMPLATE_SIZE[0x60]` 1070 → 1273 (r2: 1293) — the table still said
678, stale since before S122):** `CopyNPCListToBuffer` handles `$A2` (TestEventFlag unless
`$FFFF`) and records `wNpcColour[slot] = $80|pal` via `NpcColourRecord`, tagged with
`wMapID` / `wScreenIndex`; **entry 11 `NpcColourDraw`** (called from bank $06
`NPCDrawSlot`, patched `ld hl, $600b`) draws through bank $05 entry 0, then rewrites
OAM-buffer attr bits 0-2 of the pieces just drawn. WRAM: `wNpcColour` (8 B, `$D2E3`) +
4 bytes of tags/scratch, carved from `wCustomPool` (now `$D2EF-$D5E4`).
**S123 r2 (user: the portal should run "a full start-of-gate effect … instead of
go-down-a-floor"):** + entry 12 **`CustomDescentFeel`** (TEMPLATE_SIZE 1293): the body of
bank $0B `CustomDescentInGate` (hand-kept `patches/bank_00b.asm`, now a far call) — the
in-gate transition feel only for a custom room's Stairs-down exit (gate flag `$80`), never
for a gate entrance (flag 1). GATE_GENERATION §7.5.1 / §7.11.
**Regression pin `6b0738c1…` (patched)**; was `e93b23b5…` (patched, historical — S123 r1),
`bd0652da…` (patched, historical).

## §2.37 S124 — the flag index (ROADMAP P3.14a, the Progression & Flags tab)

No schema change except fixed flag numbers (§2.7) and the `comment` (note) of a flag.
`editor2/core/flag_index.py` (headless) reads the project's JSON — what the author
wrote, so every use knows its place in words and its JSON path — and, given a
`cutscenes.Catalogue`, the original game's scripts:

* **Use** = one place that turns a flag ON / OFF or tests it: role, the wanted state
  of a test, `kind` (`KINDS`: talk, conversation, raw script ops, script preludes,
  cutscene start / steps, state rules, NPC shown / colour / swirl, room / gate battle
  variants, gate-floor rooms, legacy quests, the engine's GateBossWin + a re-bossed
  gate's win tails, the Milly hook, the game's scripts, the game's code), `where` /
  `what` sentences, a navigation target, `source` project / engine / game, `runs`
  (False = its script is bound to no NPC / spot / entry). A **Trigger** = one "When …
  → …" (its flag terms are test uses).
* The sites are the compiler's own (`Project.resolve_flag_ref` / `_flag_index` call
  sites). `compiler_coverage(project)` compiles while logging every resolved flag and
  every flag op of the lowered scripts and returns what the index does not know —
  test_compiler `test_flag_index_s124` runs it on the example, the S117 / encounter /
  Milly / world fixtures and `_flag_sites_fixture` (every site) and requires nothing
  missed and every `KINDS` site exercised: a new flag site in the compiler fails the
  suite until the index walks it.
* **Problems**: `undefined` (a name that resolves to nothing — the build stops),
  `never_on` (a check that wants ON, nothing in the project / engine turns it ON),
  `game_only` (only the original game turns it ON — e.g. a copied game room's
  people waiting for arena ranks), `game_shares` (a named flag on a number the game
  uses: `$0158`), `not_saved`, `never_read`, `unused`.
* The game's own code: bank $12 Pulio `$0007`, the medal man `$0050+[$D9E1]`, the
  gate keeper's list tables `$09:$607E` / `$609E` (EVENT_FLAGS "Engine-side flag
  setters and readers").
* **S124 r2 — who / where / when:** `Use.who` / `Use.when` / `Use.group`. The game's uses:
  who = `Rooms.triggers` of the script (the NPC / examine / step-on / entry, all its cells),
  named by the script's own speaker when it has exactly one ("Santi"); when = the last rung
  of the scene path (`_path_when`) for a set, the whole path to a check (`Script.path_to`,
  `_reach_when`: "once … is ON, before …"). Project uses: from their sentences (the place's
  event + the conversation context). `FlagIndex.groups(uses)` / `summary(flag)` /
  game-flag labels "set by …".
* **S124 r3 — places and your NPC names:** every use carries `Use.places` — every place its
  script runs at as a navigation dict: the game's `{'tab': 'game', map, screen, STATE, x, y,
  n, who}` (one per `Rooms.triggers` row: n = the NPC number, 1-based, spots not counted),
  a project script's `Place.nav()` (+ `n`), a cutscene's `{room, scene, screen}`; `Use.nav` =
  `places[0]`. (Before r3 a game use's nav was the map only and the Rooms tab opened its first
  screen in state 0 — user: "That's NOT where Santi is": she stands on GreatTree screen 12 from
  state 1.) Names: a project NPC = its `actor` (`Place.event`: "talking to Bard at (5, 6)"); a
  game room's NPC = `custom._editor.npc_names` (`editor2/core/npc_names.py`), else the one
  speaker of the script's own lines, else its sprite. **`custom._editor.npc_names`**
  `{"MM:screen:state:n": name}` — editor data, never compiled (test: naming changes no
  generated byte); `Document.name_npc(name, room= | mid=, screen, state, n)` names the same
  NPC (sprite + cell) in the screen's other states too, '' removes.
* CLI: `python3 -m editor2.core.flag_index <project> [--rom ROM]` prints every flag,
  trigger and problem.

Byte-neutral: the example project's build is unchanged (pin `6b0738c1…`, patched).

## §2.38 S125 — the HUB: where the game sends the player home (`custom.hub`, ROADMAP P3.14d part 1)

```json
"hub": {"rules": [
  {"when": [{"flag": "post_game", "is": "clear"}], "room": "hub_hall",
   "screen": 0, "x": 4, "y": 5, "comment": "the main game"},
  {"room": "castle", "comment": "after the ending"}]}
```

Rules in list order; the first whose flag terms all hold is the hub (max 16 rules, 8
terms each; a rule after one without conditions is refused — it could never apply). No
rule holds / no `hub` = the vanilla Castle. `room` = a custom room id, or `"castle"`
(map 0, pixel `$E8/$58`, the Castle's own `$D92B` arrival codes). Resolved by
`Project.hub_rules()` (reads `custom.rooms` directly — the talk scripts lower before
the rooms resolve).

**Engine (bank $71 template, entry 9 `HubWarp`, HL = `$7109`, E = the reason):** the
four engine Castle sends — bank $50 `BattleExitHandler` `$6559` (an ordinary lost
battle) and `$64AF` (the lost Starry Night / arena final, `wBattlePostFlag` = 1), bank
$06 `$6A39` (the party killed by damage floors, after message `$021A`), bank $07
`$5030` (the WarpWing item) — were 38 bytes each of `$D92B := code` + the warp mailbox;
now (same size, `patches/bank_050/006/007.asm`) `ld e, HUB_x / ld hl, $7109 / rst $10 /
jr +30 / ds 30`; the code after (`wIsPlayerChangingMaps := 1`, the gold halving, the
item loss) is unchanged, so the penalties stay. `HubWarp` stores E in `wHubReason`
(`$D2EF`, `patches/wram.asm`, carved from `wCustomPool`) and walks **`HubTable`**
(generated: `[n_terms] + n_terms × dw flag (bit 15 = must be CLEAR) + [mapID, px lo/hi,
py lo/hi]`, `$FF` ends). A custom room: the mailbox := that room / pixel, gate flag 0,
`wHubReason` kept. Map 0 / no match: exactly the vanilla writes (`$D92B` := 6 for the
WarpWing, else 8; map 0 at `$E8/$58`) and `wHubReason` := 0. Reasons (`HUB_*` EQUs,
`Project.HUB_REASONS`, `cutscene_build.ARRIVALS`): 1 `lost`, 2 `wiped`, 3 `warpwing`,
4 `final_lost`, 5 `home` (a script), 6 `arena_won` (reserved for the P3.14e arena).
`TEMPLATE_SIZE[0x71]` 865 (`Custom26DDTable` `$4361` in the S125 example game.sym).

**Scripts going home (`dest: "hub"`):** a talk block's `move`, a conversation's `move`
and `helper`, a cutscene's `move` → `Project.hub_warp_ops(reason)`: the rules as an
if-ladder (`if_flag_clear` / `if_flag_set` per term), each branch a terminal warp — a
custom room gets `write_ram $D2EF, reason` first; the Castle branch gets its `$D92B`
write (6 for `home` / `warpwing`, 8 for a loss) or, for the helper, the helper's own
Castle event (heal = 6, King = `$D9E3` + 7, none = nothing); `map_transition` (move) or
`warp_fade` (helper). No hub → the Castle alone: byte-identical to a hand-written Castle
warp. The Anchor skill's gate exit (`skill:anchor_gate_confirm`, the WarpWing recipe)
is rewritten the same way with reason `warpwing` (`Project._hub_anchor`); unchanged
without a hub.

**Arrival scenes (`custom.rooms[].cutscenes[].trigger.arrival`):** an entry scene with
`"arrival": ["lost", "wiped", …]` plays only when `wHubReason` is one of them: guard =
`check_and_branch $D2EF, n, @arr` per reason, else skip; once every guard has passed
(`once` included — a skipped scene leaves the reason to the default heal) the scene takes
the reason (`write_ram $D2EF, 0`) so a reload of the room (scrolling, after a battle) does
not replay it. A **hub room** (any rule's room) always gets a combined entry script
`cut:<room>:entry` (`cutscene_build.lower_project`): (1) `hub_reveal_ops` — for the
WarpWing reason `$C8EC := 0` (the item's exit sets `$C8EC` = 1, every field sprite
hidden, and leaves the clearing to the Castle; PyBoy S125: elsewhere the player, the
monsters and the NPCs stayed invisible), (2) the Milly hook's scene, then the arrival
scenes (sorted first), (3) `hub_default_ops` — a reason no scene took: `refresh_party`
(heal) + take it — BEFORE the room's other entry scenes (one of them may warp away;
S125 review), then those scenes and, after `cut_orig`, the room's own entry script. Validators warn: an arrival scene in a room no rule reaches /
on a screen no rule lands on (never plays), a loss arrival without a Heal step.

**Heal step** (`{"heal": {}}`, cutscenes and conversations): op `$27` `refresh_party`
(scriptgen alias of `monster_party_op2`) = bank $01 entry 9 `IteratePartySlots20`:
every monster record's status := 0, HP := max, MP := max (PyBoy S125: three KO'd party
monsters at 0 HP / 0 MP → full, status `$80` → 0), then entry 3.

**Flag index:** kind `hub` (`custom.hub.rules[].when`, navigation `{'tab': 'worlds',
'hub': n}`). **Editor:** World tab → **Hub** box (`HubBox`, `HubRuleDialog`),
`editor2/core/hub_doc.py` `HubMixin` (`hub_rules` / `set_hub_rules` / `add_hub_rule` /
`update_hub_rule` / `remove_hub_rule` / `move_hub_rule` / `hub_rule_text` /
`hub_problems` / `add_arrival_scenes`); the cutscene editor's **Arrival home… ▾**, Heal
step and "home — the hub" destination; the conversation dialog's Home destination and
Heal step; the Rooms canvas **H** marker (EDITOR_DESIGN §5.8 "Hub (S125)").

**Measured (PyBoy, the user's save + a demo hub room, PROJECT_STATE S125):** lost battle
→ the hub at its cell, the arrival scene, heal, 3800 → 1900 gold, items lost as in the
game; the WarpWing thrown on gate 0 floor 1 → the hub, its scene, sprites shown, the
wing used up; a script's "home" → reason 5, its scene; hub rule 2 (the Castle once the
flag is ON) → a loss lands in the throne room (screen 1, (14, 5)), `$D92B` 8, the priest
heals; the WarpWing with the Castle hub → the Castle; the hub room's door out works.
Not staged: the floor-damage wipe and the Starry final (the same call, MiniSM83-run in
test_compiler `test_hub_rom`).

## §2.39 S126 — SERVICE NPCs: the game's menus in any room, their lines, the Medal Man's rewards (ROADMAP P3.14e1)

```json
"scripts": [
  {"id": "hall_vault", "service": {"kind": "vault", "lines": "clerk"}},
  {"id": "hall_namer", "service": {"kind": "namer",
     "first_time": {"text": "namer_intro", "flag": "namer_met"}}},
  {"id": "hall_shop",  "shop": {"shop": "my_shop", "lines": "buk_lines"}}],
"service_lines": [
  {"id": "clerk", "kind": "vault", "name": "Clerk's lines", "speaker": "Clerk",
   "voice": "low", "everywhere": false,
   "lines": {"0": "Vault! What\ncan I keep?", "2": "Your things\nare safe with us!"}}]
```
`gamedata.medals = {"rewards": [{"medals": 3, "enemy": 336}, {"medals": 5, "enemy":
"klamutra", "line": "A strange egg\nfor you!"}, …]}`.

**Kinds** (`editor2/core/services.py` `KINDS`; the screen = script opcode `$04 <type>
<text base>`, dispatched by `$C8EF` through bank $09 `ScreenEffectTable09`):

| kind | screen | handler | text base | lines | the game's NPC |
|---|---|---|---|---|---|
| `vault` | 2 | `VaultScreen` `$09:$4EF9` | `$06A0` | 26 | map $0F script 1 |
| `farm` | 3 | `FarmScreen` `$12:$442D` | `$06C0` | 39 | Pulio, map $04 script 26 |
| `eggs` | 7 | `EggAppraiserScreen` `$0A:$6095` | `$0750` | 29 | |
| `library` | 8 | `LibraryScreen` `$12:$6061` | `$0740` | 5 | |
| `namer` | 9 | `NamerScreen` `$12:$6842` | `$0780` | 6 | (then type 15, the naming screen) |
| `medals` | 10 | `MedalScreen` `$12:$6AFE` | `$0720` | 18 | map $16 |
| `gates` | 13 | `GateListScreen` `$09:$5ECA` | — | — | the Gate Hub guide (`$0066` ask / `$047E` bye) |
| (`shop`) | 0 | `ShopOuterMachine` | `$0680` | 16 | (line sets only; §2.32) |

Block line +0 = the greeting, +2 = the farewell (the Medal Man has none; his reward
line n = +2+n); the others are spoken by the menu (`engine_offsets` in
`extracted/service_lines.json`, written by `tools/extract_service_lines.py`, selftested
in the verifier: JSON == ROM, every line re-encodes to its bytes). The state behind every
menu is global (one Vault, one farm, one medal count) — any number of NPCs of one kind.

**Lowering (`services.lower`, after the shop lowering, before the dialogue resolves):**
a `service` script → the vanilla NPC's own shape (`service_ops`): greeting (or, with
`first_time`, `if_flag_set flag @known` / the intro / `set_flag` instead of it), op `$04
<screen> <base>`, the farewell; the library adds `nop` + `init_dialog`; the egg appraiser
and the namer open their bottom box with op `$3C`; the namer = YES / NO →
`label:list` op `$04 9` → `check_and_branch $C8F4, 255, @bye` → `close_text` → op `$04
15 0` (naming screen) → `goto @list`; the gate guide = its ask, `check_and_branch $C83C,
1, @no`, op `$04 13 0`, `nop`, `init_dialog`, its bye. A script whose set is used (not
`everywhere`) gets `write_ram wServiceLines, n` before op `$04` and `0` after it; a shop
script's `lines` the same around its op `$04 0`.

**Line sets (`resolve`):** each changed line = a generated dialogue entry `svc:<set>:<off>`
(raw bytes, `_service`): the vanilla frame (voice `$EA`/`$EB`, the speaker label + `$A3`,
the tail `$F0` / `$F7 $F0` / `$FA $F7 $F0` / `$FF $F0` YES-NO …) around the new body
(`$EF $EE` line, `$FA $F7 $EF $EE` box, `{hero}` `$F6`, `{ins0..3}` `$F9 $00/$10/$20/$30`
— the menu's inserts). Text equal to the game's keeps the game's exact body (`..` vs two
`$5F`). A `speaker` / `voice` override re-frames every line that has a label / opener;
untouched lines too long under the new name are re-flowed (`fit_text`); typed lines that
do not fit are build ERRORS ("the game would wrap it in the middle of a word"). Set
numbers 1..n (≤ 250) for sets a script uses; `everywhere` sets and the medal reward lines
go to set 0. Bank $77 data (`set_table_lines`): `SERVICE_SET_COUNT`, `ServiceSetTable`
(dw per set), `ServicePairs_n` (`dw vanilla id, dw project text id`, `$FFFF` ends).

**Engine (bank $77 template entries 3-6; `TEMPLATE_SIZE[0x77]` 688 — 684 before r2):**
- **entry 3 `SayText`** (DE = text id): ≥ `$0A00` → `CustomTextDisplay` (bank $60 entry
  5, `$C822` = hi − `$0A`, `$C823` = lo); else `wServiceLines` 1..count → that set's pairs,
  then set 0; a hit speaks the project's text, else `jp TextBankDispatch`. The three menu
  say helpers call it: bank $09 `ScreenEffectSay` → `SayAny09` (in the `LoadFld9_40fa`
  NOP run: `ld d,h / ld e,l / ld hl,$7703 / rst $10 / ret`), bank $0A `ScreenEffectSay0A`
  → `SayAny0A`, bank $12 `ScreenEffectSay12` → `SayAny12` (in the old ScreenPush copies).
  Two farm lines were spoken by absolute id (`$06E1`, `$06CC`) → made base-relative
  (`ld hl,$0021` / `$000C` + `ScreenEffectSay12`, same size) so a set reaches them.
- **entry 6 `ServiceOpenTiles`** (`FarmScreenOpen` / `EggScreenOpen` wrap the table
  entries): in a custom room, once per screen, `$9600-$97FF` (room tile slots `$60-$7F`)
  → `wServiceTileSave` (`$D2F0`, 512 B, STAT-waited); `wServiceTileSaved` `$D4F0`.
- **entry 4 `ServiceCloseBox`** (the Vault's and the farm's close, 10 B replaced: `ld hl,
  $7704 / rst $10 / ret` + 5 nop): tiles back + `ShopClose` (the box re-seated at the
  bottom, wGameState bit 4 off, `$C905` := 0). **entry 5 `ServiceCloseTiles`** (the egg
  appraiser's close): tiles back + bit 4 off + `$C905` := 0. "Tiles back"
  (`ServiceTilesBack`) also sets `$FFD4` := `$80` (S126 r2): the farm leaves `$60`, the
  text-box sprite threshold (ROOM_DATA_FORMAT "Text boxes and sprites") — the next talk in
  a room drawn with tile ids ≥ `$60` hid every sprite. The game never restored the
  farm's icons (`$60-$6F`) / the egg icons (`$70-$78`) — vanilla rooms do not draw with
  those slots; custom rooms do.
- **entry 2 `ScreenPush`** (S117b) now also serves banks $0A / $12 (`ScreenPush0A` /
  `ScreenPush12` were identical 53-byte copies at `$40E5`; now `ld hl,$7702 / rst $10 /
  ret`). In a free-colour room a pushed row cell whose tile differs from the room map
  (`$C300` = DE − `$200`) gets palette 7 (the menus' cream); full screens type 13 (gate
  list) / 15 (naming) → every cell palette 7 (`wPushAttrOn` = `$81`).
- **bank $71 `CustomAnimSource`** (custom tile animation): returns at once while a
  screen effect of `AnimPauseTypes` (3, 5, 6, 7, 8, 11, 13, 15) is open — those draw into
  the room's tile slots (`TEMPLATE_SIZE[0x71]` 908). Vanilla pauses only type 15.

**Medal Man (`gd_medal_rewards`, `patches/bank_012.asm` free tail):** `MEDAL_REWARD_COUNT
EQU n` + `MedalRewardTable: dw medals, dw EID …, dw $FFFF, 0` — the readers (`$6B5D`,
`$6B92`, `$6CC0` `cp MEDAL_REWARD_COUNT`; four `ld hl, MedalRewardTable(+2)`) moved off
the old `$12:$6D29` table (left in place, dead). Index = eggs given `[$D9E1]`, flags
`$0050-$0057` (max 8 rewards), total `$C903/$C904` capped 999; rising, ≥ 1. The egg comes
from bank $14 entry 2 — a project enemy (EID ≥ 519) works via `LoadEnemyStatsExt`.
Reward line n (block +2+n) = the row's `line` or the game's wording with the egg's
species name (`reward_default`: re-flowed to the frame — +6 and the never-spoken
alternates +7..+10 that rewards 5-8 take end with `$EF $EE`, so their last box holds one
line); after the last reward the "no more rewards" boxes. The Services tab shows a typed
line that does not fit (a build error). Edited rewards apply
to every Medal Man (set 0).

**Validation:** unknown kind / keys, a set of another kind, `lines` on the gate guide,
first_time without text / flag, line glyphs, a speaker > 9 letters, line format
(errors); a set no script uses, two `everywhere` sets of one kind (warnings). **Flag
index:** kind `service` (`first_time.flag`: a TEST clear + an ON). **Editor:** Rooms tab
NPC → **Service…** (`app/rooms/service_dialog.py`), the Shopkeeper dialog's lines picker,
the **Services** tab (`app/services_tab.py`: service NPCs + Go to, line sets with the
box preview, Medal Man rewards); model `core/services_doc.py` `ServicesMixin`.

**Measured (PyBoy, the user's save, PROJECT_STATE S126):** all seven services in a
free-colour room (`$6E`) and an animated room (`$6C`): windows cream, the gate list /
naming screen palette 7, gate names intact, the room's map / attributes / tile data back
after each close (both screen halves); custom lines (the Clerk's Vault, Mira's farm with
`{hero}`, a shop set); medal rewards 3 / 5 / 8 → ZapBird, Klamutra (project EID 520),
Slime eggs (seen in the appraiser's list), the 4th visit "no more rewards"; the game's
own Medal Man (map $16) speaks the edited reward line; an item stored with a new Vault
keeper is in the game's Vault (map $0F).

## §2.40 S127 — BREEDING in the project's rooms: Grandpa, breeders, breeding pools, every-gate rooms by level (ROADMAP P3.14e2)

```json
"scripts": [
  {"id": "lodge_grandpa", "service": {"kind": "grandpa",
     "first_time": {"text": "gp_intro", "flag": "gp_met"}}},
  {"id": "lodge_rosa", "service": {"kind": "breeder", "mate": 309,
     "intro": "rosa_intro", "flag": "rosa_bred", "once": true, "after": "rosa_after"}},
  {"id": "porch_bram", "service": {"kind": "breeder", "mate": 311,
     "when": [{"flag": "porch_bell", "is": "set"}], "not_yet": "bram_wait"}},
  {"id": "porch_wren", "service": {"kind": "breeder", "pool": "wild", "after": "wren_done"}}],
"breeding_pools": [
  {"id": "wild", "name": "Wild mates", "measures": ["level", "arena", "seen", "story"],
   "milestones": ["porch_bell", "rosa_bred"],
   "bands": [{"name": "early", "level": 5, "arena": 0, "seen": 10, "story": 0,
              "mates": [{"enemy": 17, "weight": 2}, {"enemy": 25}]}, …]}],
"gate_inserts": [
  {"room": "wandering_nest", "gate": "any", "once_per_dive": true,
   "chance_by_level": {"from": [5, 50], "to": [40, 100]}}]
```

**How the game breeds (audit S127, code-read + PyBoy; BANK04_SCRIPT_ENGINE "Breeding").**
Three parts. (1) The MENUS are room-independent bank $0A screen effects (op `$04 <type>
<base>`): **6** = Grandpa's BREED / HATCH / EXIT (base `$06F0`, `label4bc3`), **5** = a
master offering their own monster (base `$0600`, `label442d`; line +1 "Why not breed with
my [INS 00]?" is spoken by the menu only on B-back — the master's script asks it first),
**11** = "Take … with you now?" (`label6966`), **15** = naming. (2) The CEREMONY is always
map $08 script 0, a stage machine on `$D951`: Grandpa's BREED confirm (`label573e`) warps
there with 0 → 1 → back through op `$4F` with `$F0`; after op `$3A` (the HATCH night) stage
2 → `$F1`; a master's confirm (`label4ad3`) 4 → 5 → back through op `$43` with `$F2`.
(3) The FOLLOW-UP runs from the ROOM's entry script, which sees `$D951` = `$F0` / `$F1` /
`$F2`. Op `$4E` saves the return point (`$C8FB` map, `$C8FC` gate flag, `$C8FD-$C900`
pixel X/Y, `$C901` facing); op `$42 <EID> <actor>` (the masters) = the MATE's enemy row →
`$C8F7/8` (param 1 was documented "text", DOC_AUDIT S127) + the same save + `$C902` =
the actor; `LoadFldA_4ba2` builds that row (bank $14 entry 0) and names its species into
insert slot 0. Ops `$50` / `$44` turn a FIXED NPC slot (`$D7F8`) / actor `[$C902]`. The
fee is the game's: op `$60` if_gold_short, (plus + 1) × 10 G.

**Kinds** (`services.KINDS`): `grandpa` (screen 6, greeting +0, farewell +2; lines +13 /
+22 are the ceremony's and refused in line sets — `FIXED_LINES`) and `breeder` (screen 5,
farewell +0). Both accept `lines` (line sets, §2.39) and Grandpa `first_time`.

**Lowering** (`breeders.lower_talk`, after the talk scripts; `lower_entries` after the
cutscenes):
- **Grandpa** (`grandpa_ops`): greeting (or first_time) / `write_ram wBreedLast n` / op
  `$4E` / lines on / op `$04 6 $06F0` / lines off / farewell +2.
- **Breeder** (`breeder_ops`): `when` → `if_flag_* @notyet`; `once` → `if_flag_set flag
  @after`; a pool breeder → `write_ram wBreedSlots+4k+1 <pool>` and `check_and_branch
  wBreedSlots+4k, 2, @after`; then `write_ram wBreedLast n`, op `$42 <mate> <actor>` (the
  mate = the enemy row, or `$0F00 + k` for slot k), op `$24 $FF00` (the mate's name →
  `$C180`), `init_dialog` (a yield ends the talk's dialog — KEY_LESSONS S127), op `$3C`,
  [intro], line +1, lines on, op `$04 5 $0600`, lines off, op `$3C`, line +0; `@notyet` /
  `@after` speak their texts.
- **Return script** (`return_ops`) in FRONT of each such room's entry script
  (`breed:<room>:entry`, the original after `label:br_orig` with its labels prefixed
  `o_`): `$D951` `$F0` / `$F1` / `$F2` → dispatch on `wBreedLast`, the player faces `$C901`
  and that NPC the opposite way (face ops `$47-$4A`), then the vanilla shrine's / master's
  follow-up (`$F0`: the HATCH offer with op `$60`; `$F1`: naming, type 11, "Take good
  care…", "Anything else?" → the menu again; `$F2`: `$D951` := 0, the player shown,
  `set_flag` / slot := 2 (done), `init_dialog`, line +9).
- Slots: a room holds at most `BREED_SLOTS` = 4 pool breeders (slot k = their order in the
  room); breeder numbers `n` (wBreedLast) 1-255 per project.

**Engine (S127):**
- **bank $77 template** (`TEMPLATE_SIZE[0x77]` 1107, re-pinned): entry 7 `BreedClose`
  (`$7707`; bank $0A's three close tails `label4516` / `label4ce2` / `label6a5a` call it
  instead of `$0103`, same size): the bank $01 call, then in a custom room `$FFD4` := `$80`
  and the room sheet back (bank $71 entry 0 → `wRoomRecScratch` → `WaitDMATransfer` to
  `$9000`) — the menus draw into room tile slots `$40-$7F`. Entry 8 `BreedSlotEID` (from
  bank $14 `LoadEnemyStatsExt` when `$DA13` = `$0F`): slot = id & 3; state 0 → `BreedRoll`
  (its pool) → state 1 + the rolled row; then that row → `wTempEnemyStatsId` / `$DA13`.
  Entry 9 `PartyAvgLevel` (A and E; the party list `$CA8E-$CA90`, record +`$4B`). Entry 10
  `ScriptCommand` (E = 0: the mate's species name → `$C180`, mode 5). `BreedRoll`: the
  pool's measures → `wBreedVals` (level; arena classes × 12 from flags; seen bits `$CA94`
  / 2; milestones ON × step), the band with the smallest Σ|v − t| over the masked scales
  (tie → the first), a mate by RNG16 mod total over the weights. Data (`emit_pool_lines`):
  `BREED_POOL_COUNT`, `BreedPoolPtrs`, per pool `db mask, step, n` + `dw flag × n` + `db
  bands` + per band `db level, arena, seen, story, mates, total` + per mate `dw row, db w`.
- **bank $71 template** (`TEMPLATE_SIZE[0x71]` 951): `CustomGateInsert` takes gate
  `GATE_ANY` (`$FE`) rows for every gate; a chance byte with bit 7 = row index into
  `ScaledChanceTable` (100 bytes per row, level 0-99; `ScaledChance` calls entry 9 and
  clamps 99).
- **bank $60 template** (`TEMPLATE_SIZE[0x60]` 1306): `CustomDrawTiles` routes op `$24`
  params `$FFxx` to bank $77 entry 10 (E = xx) — the first use of P3.14b's op-`$24`
  command range.
- **bank $14** `LoadEnemyStatsExt`: `[$DA13]` = `$0F` → `ld hl,$7708 / rst $10` then the
  normal path. **bank $73** entry 0 `CF2WarpCommitDrain`: every committed map change except
  into map $08 or with `$D951` ≥ `$F0` clears the four slots' state (a re-roll next time
  the room appears). **WRAM** (`patches/wram.asm`, from `wCustomPool`): `wBreedLast`
  `$D4F2`, `wBreedSlots` `$D4F3-$D502` (4 × state, pool, row lo, row hi; state 0 roll / 1
  rolled / 2 done), `wBreedVals` `$D503-$D506`, `wBreedMask` `$D507`, `wBreedStep` `$D508`.

**Gate rules (§2.31 rows):** `"gate": "any"` → every gate (the game's and new ones),
floors 2 to the last (never the boss floor); `once_per_dive` bits allocated from bit 7
down; `chance_by_level` {from: [level, %], to: [level, %]} (levels 1-99 rising, 0-100 %)
→ `chance_byte` = `$80` | row; rows deduplicated (`scaled_chance_rows`).

**Validation:** pool keys, measures, ranges (level 0-99, arena 0-8, seen 0-240, story 0 -
milestones), 1-16 bands, 1-16 mates, weights 1-255 summing ≤ 255, ≤ 16 milestones, ≤ 100
pools, mates = existing rows (errors); a breeder with both / neither of mate and pool,
`once` without `flag`, more than 4 pool breeders in a room, a breeding NPC in a vanilla
room (errors); an unplaced breeding script, `after` without `once` on a fixed breeder, an
unused pool, bands without a scale (warnings). **Flag index:** kinds `breeder` (`when` →
"the breeder offers to breed"; `flag` ON after the ceremony; `once` = a TEST clear) and
`breed_pool` (milestones = TEST). **Editor:** Service… → Grandpa / Breeder (one monster
or a pool, first words, offers only when, done flag, only once, afterwards); Services tab
→ **Breeding pools** (scales, milestones, the bands table, add mate, Try it); Gates tab
rule dialog → **every gate**, **the chance follows the party's average level**; model
`core/breeders_doc.py` `BreedersMixin`; help `68_breeding_npcs.md`.

**r2 (editor side; the compiler and engine unchanged):** a mate "at a level you choose" is
a project enemy (`progression.enemies`, `comment` "a breeding mate (Rooms tab → Service… →
Breeder)") made by `BreedersMixin.mate_for(species, level)`: the species' original row nearest
the level (boss fight rows last — Pizzaro's 6000-HP row is not the monster), stats + the
growth curves' increments above that row's level, or scaled by the curves' totals below it
(clamped 1-999, MP ≥ 0); the same pair is re-used. The mate's stats matter: bank $16
`BreedCreateOffspring` gives the baby a share of both parents' stats (`SaveBrd_41b8`) and
their skills. A breeder's words and the first-visit text are wrapped into the game's boxes
(`fit_boxes`; boxes that fit stay as typed), also on open (`_migrate_service_words`).

**r3 — the dialog box stays at the bottom:** the menus (types 5 / 6 / 11) draw their windows
for a BOTTOM box. A talk from the lower half of the screen opens the box at the TOP (bank $06:
player y − scroll ≥ `$50`); `$3C` placed after `init_dialog` does not reach the box
init_dialog opens. PyBoy (the user's $6B): intro at the top, the question at the bottom, and
after NO the farewell's scroll drawn in a second box at the top. Now `breeders._bottom` puts
op `$3C` before every text and init_dialog of Grandpa's, the breeders' and the return
scripts, and `BreedClose` calls `ShopBoxBottom` in custom rooms (TEMPLATE_SIZE[0x77] 1110).

**r4:** a breeder accepts `first_time` {text, flag} like the other services: `if_flag_set
flag @known` / its words / `set_flag` / `goto @asked`; `@known`: the first words; `@asked`:
the question.

**Measured (PyBoy, the user's save, the S127 demo — PROJECT_STATE S127):** Grandpa
first visit, BREED → ceremony → back in the room, HATCH (30 G) → naming → "Take DD with
you now?" in the room; a fixed breeder ("Why not breed with my Rayburn?") → `$F2` → "I
hope a strong monster will be born!" → its flag ON → `once` words; a flag-gated breeder
(not yet → the bell → offers FangSlime); a pool breeder rolls per visit (MetalDrak / Yeti /
Swordgon, stable within a visit), done → "done for this visit", re-rolls after leaving;
the every-gate room on floor 2 in 50 of 84 RNG samples at party level 10 (row value 57 %), never twice
in one dive; breeding inside it returns to the gate room, the stairs still lead on and the
slot is cleared. `BreedRoll` == the Python model on 120 random players (test_compiler).

## §2.41 S128 — YOUR ARENA: copies of the arena rooms the engine treats as the arena (ROADMAP P3.14e3)

```json
"arena": {
  "lobby": "arena_lobby", "battle": "arena_battle",
  "return": {"screen": 1, "x": 5, "y": 4},
  "words": {"lost": {"boxes": [["Too bad!"]]}, "no": {"boxes": [["Bye!"]]},
            "locked": "That class is\nnot open yet."},
  "lines": "desk_lines",
  "classes": {
    "G": {"won_flag": "g_won", "won_words": {"boxes": [["G class is yours!"]]}},
    "F": {"opens_when": [{"flag": "f_key"}],
          "then": {"to": "room", "room": "gatehouse", "screen": 0, "x": 4, "y": 5}},
    "E": {"then": {"to": "hub"}}},
  "starry": {"opens_when": [{"flag": "s_won"}], "won_flag": "starry_won",
             "offer": {"boxes": [["Starry Night?"]]}, "then": {"to": "ending"}}
}
```

**The rooms** — `lobby` / `battle` = rooms of the project that are COPIES of the Arena
Lobby (`$06`) and the Arena Battle room (`$5D`) (`source_mapID`; the Arena tab's Make
your arena clones both with every state — `vanilla_steps` accepts exit pointer `$FFFF`
since S128, so the `$5D` copy has its 5 states; `$D999` is that room's step counter:
0 the classes, 1-3 Starry Night, 4 Monster Grandpa's match). A copy made before S128 has
1 state → `resolve` refuses Starry Night ("made before S128"), the state index would
run past the copy's list (CustomPtrChase has no clamp → crash). S128 r2: `clone_vanilla`
gives steps that draw the same vanilla layout ONE layout item (the night arena `$2315`,
steps 1-4) — paint once.

**Engine (all hand patches; the region `arena_rooms` in bank $6E carries the EQUs):**
* ROM0 `ArenaMapID` (`ld a,[wMapID]` + `ArenaAlias`) / `ArenaAlias` (A = `ARENA_BATTLE_MID`
  → `$5D`, `ARENA_LOBBY_MID` → `$06`, else A) in the 22 bytes after `ComputeFlagAddress`
  (dead since S117; the mask table `$26D5` stays). `$FF` = no arena (the original).
* `call ArenaMapID` replaces `ld a,[wMapID]` at: bank $01 `CheckScriptBeforeAction`, $03 the
  escape skill, $07 the lobby monster refresh, $50 `BattleExitHandler`, $51 the arena music;
  bank $01 `SaveMapStateToHRAM`'s class block same-size through `ArenaAlias`; banks $50
  `$5730` / $51 `LoadBtlS_43c9` `ld a,[wScriptMapType]` → `ArenaScriptType50/51`; the
  bank $71 template `BattleBGMResolve` (both reads; re-pinned, TEMPLATE_SIZE unchanged).
* Bank $50 the lost-match mailbox (33 B) → `call ArenaLossWarp50` (the project's lobby +
  `ARENA_RET_X/Y` when the match was in `ARENA_BATTLE_MID`, else the old `$06` ($E8,$48)).
* Bank $09 `ArenaMenuMarkWon` → bank $6E entry 1 `ArenaMarkClasses` (the original marks, then
  in `ARENA_LOBBY_MID` only the locks: `ArenaLockTable` 8 × [n] + n × dw flag, bit 15 = must
  be clear; a locked class = `$9C` "-"); State2's refusal → `ArenaRefuse09` (a `$9C` mark
  says `ARENA_LOCKED_OFS` = the project's locked words − `$0710`).
* NOT aliased (by design): `CheckGateWorldMapType` (copies stay gate-like, S70) and the bank
  $06 text-sprite rule (the copies set `text_keeps_sprites`).

**Lowering (`editor2/core/your_arena.py`):** the lobby's script 6 (the desk: an `$8F`
examine spot across the counter) → `arena:desk` (the Starry offer + YES / NO when its terms
hold and its won flag is OFF → `$D9CE` = 8, `$D999` = 1; else the class menu `op $04 4
$0710` with the line set `lines` (kind `arena`, base `$0710`, 7 lines) on around it;
`$D9CD` = `$FF` → the no words; else the original walk-in). The lobby's entry script gets
`arena:<lobby>:entry` prefixed: `$D9CD` `$FE` (won: `$CAB4` := class + 1, the won flags of
the class and every lower class with one, the words, then lobby / room / hub `arena_won`) /
`$FF` (lost: the words, back at the desk) — then the copied original. The arena's entry
script: Starry won (`$D9CE` 8, `$D9CD` 3) → the won flag; `ending` → the copied original
(the Milayou scene → the night Farm → credits); else the words and a warp (8 frames' delay
first — a warp at the first entry tick left a white screen). Both rooms' copied
`map_transition $0006 / $005D` are retargeted to the copies.

**Checks:** the rooms exist and are copies of `$06` / `$5D`, the return cell is a floor cell
of the lobby, ≤ 8 terms per class, `then` rooms / cells exist, a `hub` with no hub rules
warns (→ the Castle), nothing in the lobby carrying script 6 warns.

**Limits:** one arena per project; `$CAB4` (classes won) is shared with the game's own arena;
Monster Grandpa's match (group 9) is not offered (it stays in the game's arena); the
walk-in / announcer / crowd are the copied scripts.

**Exits (S128 r3):** a door object may span a double exit: the second cell's rows carry
`twin_of` = the door id (no `door` key) — they get the same destination when linked and
lose it when unlinked; `_unlinked_door` skips a `twin_of` row without `dest` like an
unconnected door (no error). `Document.connect_ends` turns plain exits into doors first.

**Flags (S128 r2):** `number_flags` (the compiler) moves an "auto" flag that lands on a
`GAME_SHARED_FLAGS` number (`$0158`) to the lowest free `FLAG_AUTO_RANGES` number — the
others keep theirs; `Document._migrate_shared_flags` does the same for a pinned flag on open
(the quest flags written in first), so the editor's numbers == the compiler's. The example
project ships moved (`vault_guardian_beaten` `$015A`, `vault_cutscene_seen` `$0159`);
REFERENCE_MD5 `3a9c38fb…` (patched; prev `00221d54…`, the S128 engine, historical).


## §2.42 S129 — STORY CHECKS, STORY COMMANDS, THE STORY SPINE, QUESTS, MUSIC BY FLAG, SHOP ITEM SETS, LOCKED EXITS (ROADMAP P3.14b / c / d)

```json
"checks": [
  {"name": "has_3_medals", "kind": "item", "item": 30, "count": 3, "comment": "…"},
  {"name": "rich", "kind": "gold", "amount": 5000},
  {"name": "has_dragon", "kind": "family", "family": 1, "where": "party"},
  {"name": "strong", "kind": "level", "level": 20, "mode": "average"},
  {"name": "ch2", "kind": "story", "milestone": "met_king"},
  {"name": "ready", "kind": "all", "terms": [{"flag": "rich"}, {"flag": "ch2", "is": "clear"}]}],
"story": {"milestones": [{"flag": "hall_visited", "name": "Chapter 1"}, {"flag": "met_king", "name": "Chapter 2"}]},
"quests": [{"id": "medal_quest", "name": "Three TinyMedals", "giver": "<script id>",
            "requires": [{"flag": "hall_visited"}], "objective": [{"flag": "has_3_medals"}],
            "take": [{"item": 30, "count": 3}],
            "reward": {"gold": 300, "items": [{"item": 1, "count": 2}], "monster": "<enemy>",
                       "set": ["…"], "clear": ["…"], "refresh": true},
            "offer": {"boxes": […]}, "accept": …, "decline": …, "progress": …, "complete": …,
            "done": …, "not_yet": …, "bag_full": …,
            "flags": {"started": "medal_quest_started", "done": "medal_quest_done"}}],
"shop_sets": [{"shop": "bazaar", "name": "After the medals", "when": [{"flag": "medal_quest_done"}],
               "items": [5, 6, 3, 29]}],
"music": {"gates": {"0": {"rules": [{"when": [{"flag": "bard_tune"}], "song": "0x2E"}]}}},
"rooms": [{"id": "hall", "music_rules": [{"when": [{"flag": "medal_quest_done"}], "song": "0x1E"}], …}]
```

**Story checks (`editor2/core/story.py`).** A check is a named question that stands in
ANY flag term (`{"flag": name, "is": "set" | "clear"}`): conversation / cutscene If, state
rules, NPC `shown_when`, hub / gate / music / shop-set / arena / breeding terms, quests.
Check n (list order, then the compiler's internal ones) = **virtual flag `$1800 + n`**
(`Project._allocate_checks`, `resolve_flag_ref`): bank $73 `FlagAddr` sends `D == $18` to
bank $77 entry 11 `StoryCheck` → `wStoryFlag` `$D509` (EVENT_FLAGS "Story checks"). Kinds
(engine byte, record): `item` 0 [item 1-43, count 1-20]; `gold` 1 [lo, mid, hi] (≤
99,999); `species` 2 / `family` 3 [value, where 0 anywhere / 1 party] (species 215-220
refused — Iron Rule 8); `monsters` 4 [count 1-40, where]; `level` 5 [level, mode 0 any /
1 average / 2 all]; `seen` 6 [count 1-240] (Library bits `$CA94`, ids 0-`$EF`); `chance`
7 [percent 1-100] (`GenerateRNG`, RNG16 mod 100, rolled at each read); `arena` 8
[classes 1-8] (`$CAB4`); `all` 9 / `any` 10 [n, n × dw flag, bit 15 = must be OFF];
`bag_room` 11 [count 1-20]; `story` (compiler only) = an internal `any` over the
milestone's flag and every LATER milestone's. A check may read another (a cycle is
refused). Eggs (+`$63`) never count; monsters are scanned through ROM0
`GetMonsterDataPtr` slots 0-39 (+`$00` in use, +`$09` species, +`$0A` family, +`$4B`
level), the party list `$CA8E`. Internal refs: `story:bag_room:N`, `story:reached:<flag>`
(`Project.check_flag`). A Turn ON / OFF of a check is refused (`resolve_flag_write`,
every set / clear of talks, conversations, cutscenes, quests).

**Story commands.** Conversation / cutscene steps that change the game: `take_item`
`{item, count}` (up to count, the last ones first), `gold` `{give: n}` / `{take: n}`,
`give_item` with `count` > 1 (all or none — the answer in `$D8E1`, the `full` branch
when 0). Each → a record of `StoryCmdPtrs` (kinds 0 take / 1 give gold / 2 take gold / 3
give items; `Project.story_command` dedups) run by **op `$24 $FF00 + n`** (bank $60
`CustomDrawTiles` → bank $77 entry 10 `ScriptCommand`, E ≥ 1 → `StoryCommand`). Op `$24`
yields, so the next text gets `init_dialog`. `refresh` = op `$26` (the room reloads in
place, BANK04 "Op `$26`"; nothing after it — the step is terminal). Also new in
conversations (the cutscene steps since S119): `give_item` / `give_monster` (`got` /
`full` dialogue ids, the inventory / storage full tests) and **`by_progress`** —
`[{milestone, steps}]` + `else`: the latest milestone reached first (an
`if_flag_clear story:reached:<m>` ladder, the vanilla highest-milestone-first order).

**The story spine** — `custom.story.milestones[]` (strings or `{flag, name}`), in story
order; `by_progress` and `story` checks follow it.

**Quests** (`story.lower_quests`, before the talk lowering): each quest's texts (inline
`{"boxes"}` or a dialogue id) become dialogue entries `quest_<id>_<key>`; the GIVER script
(`giver` = a script id; the editor binds it to an NPC) gets `talk.steps` and `_quest`:
`done` → the done words (default: the complete words) / `started` → objective holds →
[a bag-room term `story:bag_room:N` when the reward items exceed the items taken] → take,
complete words, the reward items (silent), gold, monster, `done` + `reward.set` ON,
`reward.clear` OFF, refresh / else the bag-full words / else progress (default: the
offer) / not started → `requires` holds → the offer (YES: `started` ON + accept / NO:
decline) / else `not_yet`. Flags default to `<id>_started` / `<id>_done` (registered with
fixed numbers — `quest_flag_entries`). The legacy `progression.quests` (S70) stays
(§progression); its `npc_hide` / `npc_show` now emit `npc_write n, 0, $0040 / 0` (were the
face ops `$48` / `$49` — DOC_AUDIT S124; PyBoy S129: the example's vault guardian's slot
type `$40` on entry once beaten).

**Music by flag** — `rooms[].music_rules` (custom rooms) and `music.gates.N.rules`:
`[{when, song}]`, ≤ 8 terms each, the first rule that holds plays (none = the room's /
gate's song). → bank $71 `MusicRuleTable` (`editor2/core/music.py`; SOUND_SYSTEM §10).

**Shop item sets** — `custom.shop_sets[]` `{shop, name, when (≥ 1 term, ≤ 8), items
(1-20)}` → the set's list after the shop lists in `ShopPtrTable` + `ShopSetTable` (bank
$77 `ShopSetPick` from `ShopFill`; DATA_STRUCTURES "Shops").

**Locked exits** (editor only, `Document.lock_exit`; user S129: "make a new room state and
switch to that"): the screen (ONE state) gets a second state with its own layout — the
exit rows at the cell (and a door's `twin_of` cells) removed, the cell made a wall, an
examine spot with the locked words — and two state rules: state 0 while the terms hold,
else the new state. No engine part.

**Engine (templates re-pinned):** bank $77 head 1788 B (`TEMPLATE_SIZE[0x77]`, sha
`eb0f0997…`): entry 11 `StoryCheck` + `StoryKindTable` (12 kinds) and helpers, `StoryCommand`,
`ShopSetPick`; bank $71 head 1070 B (sha `cbd0cdec…`): `MusicRulePick` + `TermsHold71`, the
two calls in `CustomRoomBGMResolve`; hand patches `patches/bank_073.asm` `FlagAddr` (`cp
STORY_FLAG_HI`, `.story`) and `patches/wram.asm` (`wStoryFlag`, `wCustomPool` from
`$D50A`). Generated: `StoryCheckPtrs` / `StoryCheck_n`, `StoryCmdPtrs` / `StoryCmd_n`,
`ShopSetTable` (bank $77), `MusicRuleTable` (bank $71).

**Checks (`validators.validate`):** a check's shape / range (`check_error`, reported
first — a failed check list explains a "no such flag" later), a cycle, a name shared with a
flag, a story check written, `by_progress` milestones in the spine, ≤ 256 checks (authored
+ internal), ≤ 255 commands, quest keys / texts / reward keys. The flag index
(`flag_index.py`) lists checks (kind `check`), milestones, music rules and shop sets as
uses / triggers; problem `check_written` (✖).

**Proof:** test_compiler `test_story_s129` (records, numbering, dedup, lowering, errors,
the index), `test_quests_s129` (quest lowering, quest_for_npc, lock_exit, shop sets),
`test_story_rom` (an SM83 RUN of `TestEventFlag` on every check kind against prepared
RAM — the farm's slots where the game keeps them —, every command, `ShopSetPick`,
`MusicRulePick`); PyBoy on the user's save (PROJECT_STATE S129). REFERENCE_MD5
`7d136455…` (patched; prev `fe5fa80a…`, S128 r3, historical): the engine + the example's 2
checks and its mini medal quest (`$015B` / `$015C`; the legacy quest kept).


## §2.43 S130 — THE BALANCE SERVICE: how hard each key fight is, original game vs project (ROADMAP P3.15a) — built S130 (user: "balance tab looks good" 2026-10-08); S131 follow-ups (P3.15b) built, NOT yet user-tested

No ROM bytes: the service only READS the project (and one editor setting, below). The
number for every key fight is **the team level at which a team a player of that point in
the story might have assembled wins ≥ 90 % (l90) / ≥ 50 % (l50)** of the time, for three
team profiles (player — the main one —, casual, strong); the original game's numbers are precomputed and read-only
(`extracted/balance_vanilla.json`), the project's are computed from the project's own
effective data and cached per fight. User decisions (S130): progression is pinned to the
story order (gates, arena classes, Starry Night, Monster Grandpa — not the project's
flags); fully custom gates only need a number; real draws for lists; skills and stat
growth must count (a team is raised the way the game raises it); breeding opens after a
story step (the user plans one step earlier than the original game's).

```json
"meta": {"balance": {"breeding_opens_after": 4}}
```
`meta.balance.breeding_opens_after` = the story step index (0-40) after which rolled teams
may contain offspring; absent = the original game's (after the F class, step 5). Written
by the Balance tab as one undo step, dropped when equal to the default; read only by the
tab (the compiler ignores `meta`).

**Modules** (no Qt): `editor2/core/balance.py` (the service), `simulator/raising.py` (the
raising model, == the game: `tools/census_raising.py`, MONSTER_DATA "Raising a monster"),
`editor2/core/dive.py` (battles per maze floor, GATE_GENERATION §4.4),
`editor2/core/savefile.py` (a .sav's roster/party), the battle simulator
(`simulator/pacing.py` + `battle.py` + `skillfx/`, BATTLE_SKILL_SYSTEM §15.11).

- **BattleData(project | None)** — the simulator's inputs: the effective gamedata
  (records, enemy rows incl. project enemies, species rows, exp/growth curves, learn rows
  incl. custom skills, breeding tables), custom skills' records + the base skill each runs
  (`core_alias`), Earthquake power overrides, enemy redirects. `override_enemy(eid,
  skills=, level=, hp=, …)` = a what-if edit seen by the simulator only (never saved).
- **Timeline(data, breeding_opens)** — the story in the original game's order
  (`VANILLA_STEPS`, FULL_FAQ chapters: 31 gates, classes G-S, Starry Night, Grandpa; 41
  steps, postgame from Gate 22). A project keeps the positions and fills them with ITS
  content: a gate's floor lists by the game's rule in runs (encounters model), its boss
  fight(s) (the gate's boss room's battles — talk steps, cutscenes, quests and the scripts
  a room names — else the original boss rows), the project's arena matches.
  `extra_fights`: new gates (32+), worlds and rooms with their own
  battles get a number of their own, compared with the nearest original fights
  (`nearest_vanilla`). Roster per step = joinable rows of every list met so far + boss join
  rows of cleared gates + the starter; offspring once breeding is open.
- **Teams** (`roll_team`, `team_for` memo per step/level/profile/index) — every slot has
  the same EXP budget (battle exp is split evenly), the team level = the level that exp
  gives on the most common curve (11); S131: a bred member's slot pays its lineage's
  grind out of it ("Breeding costs grinding" below). Members are created, bred (+ birth), levelled and taught by
  raising.py. **casual**: what was at hand, the first skills kept, one-generation breeding
  35 %; **strong**: the best of 6 rolls by `member_power` (bulk + offence: ATK or the best
  damaging skills + at most one heal), 70 % bred, picks the best of 3 crosses, two
  generations (three postgame), the best 8 skills kept. A member capped below 85 % of the
  level its exp gives (S131 `is_capped`; S130 compared with the team level) is swapped
  (players replace monsters that stop growing). Heals are valued at
  most 30 (S130.3: uncapped heals made all-Healer "strong" teams that never attack).
- **player** (S130 r2, the MAIN number — user: "Always command unless arena (Arena forces you
  to use tactics)"; "Usually one general kit … I run into a wall … start experimenting with
  skills and monsters and I train them until I overcome wall"; "maybe around 30-40 level on
  average per mon" at the S class) — the step's optimised **kit** (`editor2/core/kits.py`):
  3 monsters × ≤ 8 skills a skilled player would assemble, ONE general kit per step, found by
  a local search (start = best of 3 strong rolls; mutate one member's species or one skill;
  score = 0.6 × the hardest fight ("the wall") + 0.4 × the mean, win % + 0.15 × enemy HP
  removed; an improvement must hold on a second battle set; budget `KIT_BUDGET` = 50
  evaluations × 2 teams × 6 battles, ×4 for arena steps), optimised at the level where a
  commanded strong roll wins ≥ 50 % of every boss / arena match, then re-optimised at the
  kit's own 50 % level (≤ 2 times). The pool at level L: join rows up to L + 2 (a monster must
  be beaten to join; it brings its row's 4 skills); bred forms once breeding is open
  (S131: every route the slot can afford — "Breeding costs grinding"; S130 wanted L ≥ 10
  and 2 generations, 3 postgame); skills = obtainable species' natural + join skills through
  `UnevolvedSkillMap`, each checked link by link against the member as raised by raising.py
  (level + stat thresholds; combination skills only beside their prerequisites).
  Outside the arena the party fights on the player's **orders** (`simulator/planner.py`:
  greedy expected value — every option tried on a copy of the board through the
  simulator's own round, 3 common RNG draws, valued in "log race" units: damage / kills by
  threat share, heals and revives when they matter, status / buffs by the re-measured enemy
  damage × duration, stances only in danger, MP reserve for heals; 0.3-9 ms per decision);
  orders go through the measured menu + obedience model (`pacing.give_orders` /
  `command_commit`, BATTLE_SKILL_SYSTEM §15.10.7b: bred monsters WLD 0 always obey, joined
  ones may refuse and Daze / Attack / Defend; every obeyed order drifts w3). In the arena
  (`db73 == 2`) the menu has no Command ("NO SP SK"): `evaluate` tries Charge / Mixed /
  Cautious / NO SP SK and keeps the best (`ev['tactic']`). Kits are cached per step
  (`get_kit` / `set_kit` / `kit_fingerprint`; FightCache `kit:<fp>`; the anchor's
  `steps[i]['kit']`); `fight_fingerprint('player')` includes the kit's.
- **evaluate** — N teams × M battles (default 12 × 8; lists draw a real group per battle by
  its odds) → win, rounds, HP left, `team_level` (levels actually reached — caps, and
  since S131 bred members' grind), `enemy_hp_left` (how far a lost fight got),
  `unmodelled` (share of actions with no model — `count_actions`; S131: a heal on a
  full-HP target, the game's own "no effect", is not counted). **fight_levels** searches the level FROM BELOW (1, 2, 4, … then bisect —
  `first_level`), one memo for both thresholds; None = not even at 99 (the tab shows
  "99+ (win % at 99)").
- **Dives** (`dive`, `dive_level_needed`, `gate_dive_result`) — a gate's maze floors in a row
  without healing (HP/MP carry), then its boss fight(s): integer battles per floor sampled
  from the expected value at two walk bounds — **direct** (shortest walk to the stairs,
  the lower bound) and **sweep** (every reachable cell, the upper bound). S131: floors
  3 / 6 / 9 mix in the special rooms' own measured walks (forest / mazes / conveyors,
  GATE_GENERATION §4.4 "Special rooms (S131)"; `floor_battle_means` takes each part's
  sweep); the Coliseum's fights stay out (user S131: "irrelevant for difficulty
  scaling").
- **Cache** — `FightCache(<project>/build/balance_cache.json)`, keyed by
  `fight_fingerprint` (the fight's enemy rows + skill records + what-if overrides, the
  roster at its step, `raising_digest` = species rows, curves, learn rows, breeding
  tables, records, aliases, `SIM_VERSION`). Only fights whose inputs changed recompute; a
  new `SIM_VERSION` drops the cache. Timings: casual ~2-8 s per fight, strong ~40-200 s,
  player: a step's kit 10 s-2 min + 25-70 s per fight (one core).
- **The anchor** — `tools/build_balance_anchor.py` writes `extracted/balance_vanilla.json`
  (`_generator`, `sim_version`, `raising_digest`, steps (+ each step's player `kit`), every
  fight's groups/enemies and per profile (casual / strong / player) l90/l50 + the evaluation
  at l90 (or 99; player arena results carry the tactic), every gate's dives per profile and
  walk). `--selftest` (verifier check 5): every story fight × profile, every step's kit and
  every gate dive present, version + digest match, 3 casual fights + 1 dive + 2 player
  fights (from the stored kits) re-derived equal; SKIP while a current-version rebuild is in
  progress. The build is resumable (`balance_vanilla.json.partial`, one JSON line per finished
  unit) and uses every core; the tab's **Build original-game numbers** runs it locally.

**Breeding costs grinding (S131, user 2026-10-08: option B — "I need to capture the
total time investment needed. Keep in mind breeding chains get deeper and deeper further
into the game … I need the best objective assessment of corresponding vanilla level").**
The level axis is TIME: team level L = each of the 3 party slots has had exp(L) (the
reference curve) of grinding in it. Per slot:
- a **joined** member arrives with its row level's exp for free (`Monster.free_exp`) and is
  raised to exp(L);
- a **bred** member's ancestors were ground to breeding level (both parents level 10+ on
  their OWN curves — FULL_FAQ "only breed Monsters at Level 10 or above", bank $0A
  checks record +$4B ≥ 10 at all three breeding menus) and left the party at the cross;
  that exp is the kid's `grind` (`balance.lineage_cost` per parent: exp ground beyond its
  arrival + its own grind) and is charged to the slot — the kid hatches at level 1 and is
  raised with exp(L) − grind; a lineage dearer than exp(L) is not available (`kits.
  Unaffordable`). A recruit that joins at level ≥ 10 is breedable for free
  (`join_ancestor_cost` 0); a bred parent costs its lineage + levels 1-10.
- the player's pool (`kits.StepPool`) is a cost-aware resolver closure: per species a
  Pareto set of routes (lineage cost, plus; the parents' plus kept so a route builds the
  parents it was costed with), generations as deep as the budget allows (≤
  `MAX_GENERATIONS` 6; S131 r4: each cross's plus uses the parents' REAL levels for the
  level-sum bonus — a recruit breeds at its own row level (≥ 10), a bred ancestor at 10 —
  so late-gate recruits at 40+ give +2..+4 per cross for free, as in the game; r3 assumed
  level 10 everywhere and saw no high-plus routes, so capped members never re-bred); the
  kit search can swap a member's route (deeper / dearer for
  more plus — growth and cap — or cheaper for more of the slot's exp); a capped bred
  member is bred again through a route with the plus it needs, its grind charged
  (`kits.team_member`). The rolled profiles (casual / strong) pay their crosses the same
  way. The kit view names each bred member's grind.
- measured at four formerly flat steps (S130 "no bred kit below 10" put most mid-game
  fights at exactly 10): Gate of Bravery floors 4 · 4 · 4, boss 10; D class 4 · 4 · 11;
  C class 10 · 12 · 12 — the curve now moves by fight around where breeding pays for
  itself (an "option A" that charged nothing read 3-8 there and was rejected: it hid the
  parents' grinding).

**The tab** (`editor2/app/balance_tab.py`, EDITOR_DESIGN §5.9 as built): Story curve
(original casual l90/l50 + strong l90 read-only, project columns computed on demand,
coloured change, dives, extra fights with "lands like", a chart), Team (roll / reroll /
import the party from a .sav / pick a member by species, level, plus, skills; original or
project data), Fight (any fight's groups; evaluate the current team; level needed; what-if
per enemy with As is / What-if / Change incl. enemy HP left). Work runs in background
threads with progress and Cancel (`balance.set_cancel_check`).

**Limits** (stated in the tab's help): casual / strong act on their AI (tactics); player
orders look one action ahead (no two-turn skills, summons or dive-long MP plans) and the
kit search is small (a better kit may exist; the skill pool ignores the 25-entry learn
queue); status locks (Sleep, LegSweep) are used on bosses whenever their resistances
allow, as the simulator models the game; postgame "99+" for casual / strong = beyond a
rolled team; recruiting is free (no meat / failed tries); items are not used (user S131:
"very early-mid game thing" — banked, ROADMAP P3.15b).

**Proof:** test_compiler `test_balance_s130` (savefile party, custom_member,
team_summary, FightCache round trip + version drop, room_battles script lookup,
override_enemy, cancel hook); test_app `s130_balance`; `census_raising.py`,
`census_dive.py`, `build_balance_anchor.py` selftests. REFERENCE_MD5 unchanged
(`7d136455…`, patched).

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
Enemies: dense EIDs from **519** (`auto` allocates); S70-S100 kept ≤ 12 rows in the
bank $14 tail — **since S101 every EID ≥ 519 is a row of compiler bank $6B**
(`enemies6b`, cap `PROJECT_EID_CAP` 640; §2.18; the "12 rows" here was stale until
S124, DOC_AUDIT S124). Fields = the 25-byte enemy-stats layout
(MONSTER_DATA); `join 0` = always joins; hp>1023 with join warns.
Quests lower to two generated scripts referenced from `rooms[].scripts`:
`quest:<id>` (done-check → requires check_ram ladder → offer choice text
($C83C: 1 = NO) → prebattle → trigger_battle3 EID → **init_dialog-prefixed**
win tail: set done flag + on_win actions) and `entry:<id>` (done → entry_done
ops; seen-flag-gated entry_cutscene; sets seen). `flags.done`/`flags.cutscene_seen`
(the code's key — this said `flags.seen` until S124) auto-register from the safe pool
($0158+; `quest_flag_entries`). **Known defect (S124, code-read, not run):** the
actions `npc_hide` / `npc_show` emit opcodes `$48` / `$49` = face_down / face_left
(S101) — they only turn the NPC; **fixed S129**: `npc_write n, 0, $0040` (hide) / `npc_write
n, 0, 0` (show) — the slot's type byte (BANK04 `$0D`; PyBoy S129). The legacy form stays
for old projects; new quests are `custom.quests` (§2.42). **Every text action lowered into
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

**S127 re-pin (§2.40):** bank $60 head 1306 B (`CustomDrawTiles` op `$24 $FFxx` → bank
$77 entry 10), bank $71 head 951 B (`GATE_ANY`, `ScaledChance`), bank $77 head 1107 B
(entries 7-10 + `BreedRoll`); sha256s in PINNED_SHA256 (`56a5321a…`, `7c371e82…`,
`b70c1cd6…`), `TEMPLATE_SIZE` in `editor2/core/validators.py`. S127 r3: bank $77 head 1110 B (`BreedClose` → `ShopBoxBottom`), re-pinned.

**S129 re-pin (§2.42):** bank $77 head 1788 B (`StoryCheck`, `StoryCommand`, `ShopSetPick`;
sha `eb0f0997…`), bank $71 head 1070 B (`MusicRulePick`; sha `cbd0cdec…`).

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
* **S105: SUPERSEDED** — Anchor's scripts + texts are no longer project
  content: they are the compiler's built-in skill scripts (§2.22, script type
  `$FF`), and bank $72 no longer names map `$71`. Historical S73 note follows.
* **Anchor content in the example project** (S73-S104): medal_vault (`$71`) hosts
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
