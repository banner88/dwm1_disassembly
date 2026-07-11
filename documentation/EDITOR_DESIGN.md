# EDITOR DESIGN — Native macOS App + Romhack Architecture

> **Status: PLAN LOCKED (Session 13, 2026-06-17).** This document is the
> single home for the editor architecture *and* the romhack it serves
> ("Milayou's Story"). Nothing in here is built yet — it is the agreed
> scope. The build sequence lives in ROADMAP.md Phase 2/2C/3; the canonical
> bank reservation lives in PROJECT_STATE.md. When an item here is
> implemented, update the owning reference doc + PROJECT_STATE status row,
> not this file (this file is the design, not the status).

---

## 0. What we are actually building

Two things, one informing the other:

1. **The romhack — "Milayou's Story."** The game keeps DWM1's *engine* and a
   handful of its *systems*, but tells a new story from a new point of view,
   starting at the moment Milayou is dragged into the dresser. From there the
   world is new content built on the old ROM.
2. **The editor** — a native macOS app whose job is to make (1) buildable by
   someone with zero ASM knowledge, and debuggable by an LLM when it breaks.

The editor's scope is therefore not "edit everything in DWM1." It is "build
Milayou's Story": custom tilesets, rooms, NPCs, text, cutscenes, plus the
specific mechanical edits the hack needs (breeding rules, monster family
reassignment + rename, monster *sprite* replacement, encounters). Full-game
editing (rerouting vanilla exits, retargeting vanilla triggers) is supported
because the bifurcation *requires* it — see §3.

---

## 1. The romhack: bifurcation point & "new world on the old one"

**Bifurcation.** Vanilla is Terry's story: his sister **Milayou** is dragged
into the dresser by Warubou; Watabou then recruits Terry to follow. The hack
flips POV to **Milayou** and starts at the drag-in. Concretely:

- The intro lives at **mapID `$2F`** (`Intro Bedroom`, scripts in bank `$14`
  at `$4336`; flagged "2-screen, crashes" in the room catalogue — treat with
  care, likely truncated/replaced wholesale rather than edited).
- The **dresser→world transition** (vanilla → GreatTree `$01`) is repointed to
  **Milayou's first custom room**. The Terry-recruitment cutscene after it is
  stripped.

**Build new on the old — by choice, not necessity.** We have the room: **20
unclaimed banks (320 KB)** and **149 free mapIDs (`$6B`–`$FF`)** against a story
that needs ~30–80 rooms. So the vanilla world becomes a parts bin: we keep six
systems as preserved "islands," wire exits to them from Milayou's world, and
ignore/strip the rest.

**S55 amendments (user decisions):**
- **Vanilla rooms are KEPT as postgame content** (lightly edited, entries/
  exits rewired), not stripped — so vanilla-owned WRAM (step-counter pool
  `$D92A-$D99A`) stays vanilla's, and the mapID ≥`$80` sign-test audit is a
  real blocker for custom room #22+ (ROADMAP Arc LAYER A′).
- **Parallel architecture.** The hand patch overlay is exploration scaffolding
  with a known, accepted WRAM limitation (buffers inside monster slots 14-15;
  ≤14 rule). Editor-era structural fixes are NEVER retrofitted onto it; they
  land in the compiler pipeline.
- **Cold Farm is the editor-era WRAM strategy** (ROADMAP Arc COLD FARM, full
  spec there): party hot (slots 0-2), farm/eggs SRAM-resident like the
  vanilla sleep pool (`$B124`), per-battle exp re-bound to party + an
  accumulator drained eagerly at the castle gate-exit chokepoint (all gate
  exits funnel there; GreatTree is battle-free, Arena awards no exp —
  user-confirmed). Frees ~2.5 KB WRAM (`$CBEB-$D664`) for everything the
  editor will ever need, and retires the S54 collision class structurally.
- Interim custom-state home: `$DE74-$DEDD` (S55-vetted; the ONLY clean block
  in banks 0-1 — see KEY_LESSONS S55 for why the S54 gap list lied). GBC WRAM
  banks 3-7 (16 KB, SVBK) are VIRGIN — reserved for future editor-emitted
  systems whose accessors we control (unusable for vanilla-read state).

**Preserved systems (must keep, isolable rooms):**

| System | mapID(s) | Preservation note |
|--------|----------|-------------------|
| Give first monster | scripted `AddMonster` ($29, proven) | author as a custom give event |
| Arena | Lobby `$06`, Rooms `$07`, Battle `$5D`, Setup `$5E` | spine of *vanilla* story gating — must be **decoupled** from Anger/Durran story flags |
| Starry Shrine (breeding) | `$09` (+ breeding cutscene `$08`) | breeding NPCs have flag-gated "window" availability — audit |
| Library | `$12` (+ gate room `$13`) | self-contained |
| Vault | `$0F` | self-contained |
| Shops | Item Shop `$50`; new shops = scripted room type, replicable | can make new ones |

**The catch (honest):** vanilla progression is *arena-driven with mandatory
Anger/Durran gate interludes*. Any preserved island that **reads** a story flag
we stop setting will misbehave. This is exactly what the build pipeline's
**orphaned-trigger detection** (§6) catches. Preserved islands get a
flag-dependency audit (ROADMAP Phase 2: "preserved-systems audit") and we
satisfy-or-strip each dependency.

**World characterization is sufficient for this.** All 732 scripts across all
107 map-types are decoded (93.5% of branch paths), 328 flags mapped (298 with
sets). The gap is *narrative* labelling of vanilla sidequests — which we don't
need, because we're not preserving them.

---

## 2. Architectural keystone — table-driven custom-room dispatch

This is the foundation everything else stands on; **build it first.**

**Problem.** Custom rooms today are dispatched by *hardcoded per-room special
cases*, scattered across banks:
- `CustomPtrChase` (bank $60) — already table-driven, reads
  `CustomSourceMapTable[mapID−$6B]`. ✅ the good precedent.
- `MapIDClampForPalette` (ROM0) — **hardcoded**: `cp $6C / ld a,$16` (room $6B →
  MedalMan, else Castle).
- Encounter whitelist (bank $0B) — **hardcoded** `cp $6B`.
- `CustomAttrCheck` (bank $17) — **hardcoded** exact-mapID match.

Adding room #3 today means hand-editing 3–4 `cp` chains across 3 banks. That is
the "chasing pointers at every step" failure mode; it does not scale to 30–80
rooms.

**Solution — one master table.** A **`CustomRoomTable`** in reserved bank
**`$6A`**, indexed by `mapID − $6B`, that *every* intercept reads. One row per
custom room:

```
CustomRoomTable entry (proposed, ~10–12 bytes; finalize when built):
  +0  source_mapID      ; tileset/palette/attr source (what ClampForPalette returns)
  +1  dispatch_mapID    ; VRAM handler source (what ClampForDispatch returns; usually $00 Castle)
  +2  tileset_bank      ; GFX bank ($67-style)
  +3  layout_bank       ; layout+attr bank ($64-style)
  +4  attr_ptr (LE16)   ; custom attr data pointer (CustomAttrCheck)
  +6  dims_w, dims_h     ; room size (cols, rows) → $26DD-equivalent
  +8  enc_enable         ; encounters on/off
  +9  enc_gate, enc_floor ; pinned pool (Encounters #1 folds in here)
  ...                    ; spare for future per-room flags
```

Then the generalization is a set of **same-size** patches (no byte insertion):
each hardcoded `cp`/`ld a,$XX` becomes a `CustomRoomTable` lookup keyed by
`wMapID−$6B`, bounds-checked. After this, **adding a room = appending a row +
its data in a free bank** — deterministic, no ROM-internal pointer chasing.
This is the same move as Encounters #1, applied to the whole room system, and it
is what makes the editor's `build_project.py` possible.

**Proof-of-concept (deferred to the build session, not S13):** convert
`MapIDClampForPalette` to read `CustomRoomTable`, keep Room $6B byte-identical
in behavior (regression), and add a *second* custom room **by table row alone**
— zero new hardcoded patches. That is the green light for the whole backend.

> **✅ BUILT — S42 (user-confirmed in SameBoy).** The keystone is done. All three
> remaining hardcoded intercepts are now table-driven, and the old `$6F` room
> ceiling is lifted to editor scale. Realized slightly differently from the
> single-`$6A`-table sketch above: the master table is **distributed per concern**
> (same "append a row to add a room" property), and the *logic* lives in the
> previously-empty **bank `$71`** (reached via `rst $10`) so every in-bank edit is
> a **byte-neutral** stub — no scarce/fragmented ROM0 or bank-`$0B` free space, and
> no risk to the dense code/audio banks. As-built map:
> - **Encounters** (Encounters #1 folded in): `RoomEncTable` (bank `$71`, 3 B/room
>   `[enabled, gate, floor]`, indexed `mapID−$6B`) via `CustomEncResolve` (bank `$71`
>   entry 1). Replaces the hardcoded `cp $6B` whitelist in bank `$0B`.
> - **`$26DD` tileset/dims/threshold records past `$6F`**: `Custom26DDTable` (bank
>   `$71`, 8 B/room, indexed `mapID−$70`) via `CopyCustomRoomRecord` (bank `$71`
>   entry 0), which far-copies the record into `wRoomRecScratch`. All three consumer
>   sites (both bank-`$0B` GFX loaders + the ROM0 collision-threshold reader) read it.
>   For `mapID < $70` the same routine replicates the original in-ROM0 `$26DD/$2A5D`
>   index byte-for-byte, so vanilla + `$6B-$6F` are unchanged. **This is the piece
>   that lifts the ceiling** (the in-ROM0 `$26DD` `$70` slot collides with the gate
>   table at `$2A5D`; the far table sidesteps it). Threshold site preserves `C` with
>   `push bc`/`pop bc` around the `rst $10` (the far-call clobbers `BC`).
> - **Render** (`CustomRoomPalPtr`/`CustomRoomAttr`, bank `$17`): relocated into the
>   bank tail and widened to 6 entries (`$6B-$70`); `$6E/$6F` are vanilla-fallback
>   placeholders. Editor appends one entry per room.
> - **Palette source** (`MapIDClampForPalette`, ROM0): made **uniform** (`$00` for all
>   custom rooms) — already O(1), the lone `$6B→$16` special case (dead, overridden by
>   the render tables) was removed; no per-room table needed here.
> - **Room data/exits** (`CustomSourceMapTable`/`CustomRoomPtrTable`, bank `$60`):
>   widened to 6 entries.
>
> **Proof:** room **`$70`** (amber) — the first room *past* the old `$6F` ceiling —
> was added by table rows alone (no new hardcoded patches). User-confirmed it renders,
> its encounters fire, and its exit works, plus a walkable 3-room loop
> `$6B → $6C → $70 → $6B` with visible **staircase** exit markers. `$6B/$6C/$6D`
> behavior preserved; gate-rotation `$6D` (Pillar B) untouched. Files:
> `bank_071.asm` (new), `bank_000/00b/017/060/064`, `wram`, `game.asm`,
> `tools/build_gate_room.py` (exit staircases), `tools/verify_integrity.py`.
> The remaining sketch above (single `$6A` table, dims fields, etc.) stands as the
> *project.json → table* shape `build_project.py` will emit.

---

## 3. project.json — the four-layer schema (v1, designed; not built)

`project.json` is the source of truth; ASM/ROM is a build artifact. It has four
layers so that "new custom content" and "edits to the existing game" are both
first-class (the bifurcation needs both).

### Layer A — `world` (the existing game, extracted & editable)
Built by `extract_project.py` (vanilla ROM → schema, see §5). Lets us reroute
exits, edit/strip vanilla NPC text, retarget or remove vanilla triggers, and
mark vanilla scripts keep/strip/replace. This is how the dresser gets repointed
and the Terry intro stripped.
```jsonc
"world": {
  "rooms":   { "<mapID>": { "exits": [...], "npcs": [...], "scripts": "keep|strip|replace", ... } },
  "transitions": [ { "from": "$2F:dresser", "to": "custom:milayou_room_0", ... } ],
  "preserved": ["$06","$07","$09","$0F","$12","$50", ...]   // the islands
}
```

### Layer B — `custom` (new Milayou content, compiled into reserved banks)
```jsonc
"custom": {
  "rooms":     [ { "id":"milayou_room_0", "mapID":"$6B", "screens":[...], "tileset":"...",
                   "layout":[...], "exits":[...], "npcs":[...], "encounters":{...} } ],
  "tilesets":  [ { "id":"...", "source_png":"...", "palette_groups":[...] } ],
  "npcs":      [ { "sprite":"...", "pos":[x,y], "facing":"...", "script":"...", "show_if":"flag" } ],
  "dialogue":  [ { "id":"...", "pages":[ "..." ] } ],   // auto-wrap 18ch, auto-DTE, auto page-split
  "scripts":   [ { "id":"...", "ops":[ ...decompiler pseudo-code... ] } ],  // cutscenes too
  "flags":     [ { "name":"milayou_has_key", "addr":"auto" } ]  // allocated from free pool
}
```

### Layer C — `gamedata` (the mechanical knobs)
```jsonc
"gamedata": {
  "monsters":  [ { "id":..., "family":"...", "sprite":"sheet.png#slot" } ], // family reassign + sprite replace
  "families":  { "9": "Mecha" },                 // family rename (family-name text table)
  "breeding":  { "special":[...], "family_defaults":{...} }, // → build_breeding.py
  "encounters":{ "<mapID>": { "enabled":true, "gate":0, "floor":1, "pool":[...] } }
}
```

### Layer D — `build` (reservation, budget, validation, manifest)
```jsonc
"build": {
  "bank_map": { ... },          // mirrors PROJECT_STATE reservation; compiler enforces
  "validate": "strict",          // KEY_LESSONS rules as hard errors
  "manifest": "build/manifest.json"
}
```

**Named flags** auto-allocate from the free pool (safe contiguous block
`$0158–$017F` = 40 flags verified in SRAM range; broader free pool documented in
EVENT_FLAGS.md). The compiler resolves names → addresses and writes the mapping
into the manifest.

---

## 4. Editor app — PySide6 (decision unchanged)

`editor/editor.py` (Streamlit, byte-patches a ROM copy) is **frozen / reference
only**: predates the patch system, edits bytes instead of generating buildable
source, wrong shape for a canvas editor.

**Chosen: PySide6 (Qt 6) desktop app, shipped as a Mac `.app`.**

| Option | Assessment |
|--------|------------|
| **PySide6/Qt — CHOSEN** | All project logic is already Python (`dwm/`, script compiler, LZ codec, 40+ tools) and imports directly — zero IPC. QGraphicsScene/QGraphicsView is purpose-built for tile/map editors. Native macOS menus/shortcuts/dialogs. Packaged via PyInstaller/Briefcase. Cross-platform later for free. |
| Swift/SwiftUI | Best Mac feel, but every ROM op rewritten or shelled to Python. Rejected. |
| Tauri/Electron | Adds an IPC boundary to the Python core; web UI ruled out. Rejected. |
| Tkinter | What the legacy editor proved insufficient. Rejected. |

### Three layers, GUI on top
```
┌─ editor2/app  (PySide6) ───────────────────────────────────┐
│  RoomCanvas  ScriptEditor  DialogueEditor  NPCInspector    │
│  FlagManager  WorldMap  TilesetPanel  SpritePanel  Build   │
└──────────────┬─────────────────────────────────────────────┘
               │ plain Python calls (same process)
┌─ editor2/core (pure Python, NO Qt imports) ────────────────┐
│  project.py    load/save/validate project.json             │
│  extract.py    vanilla ROM → world layer (§5)              │
│  compiler.py   project → bank_060.asm (+spill, multi-bank) │
│  validators.py every KEY_LESSONS rule as a check           │
│  romdata.py    read-only views over extracted/*.json       │
│  builder.py    stage patches → rgbasm/rgblink → ROM + manifest │
│  emulator.py   launch SameBoy with the built ROM           │
└──────────────┬─────────────────────────────────────────────┘
               │ imports
┌─ existing assets ──────────────────────────────────────────┐
│  dwm/ (ROM, text codec)  compile_script.py  compress_tiles │
│  build_combined_tileset.py (2bpp/palette pipeline)         │
└────────────────────────────────────────────────────────────┘
```

**Hard rules:** project.json is truth, ASM is artifact · `core/` never imports Qt
(headless `python3 -m editor2.core.builder myproject/` is CI-able and
Claude-workable) · compiler is **deterministic** (same project → byte-identical
ROM) · validators not folklore (every rule cites its KEY_LESSONS entry).

### macOS specifics
- **Toolchain bundled**: `rgbasm/rgblink/rgbfix/rgbgfx` as universal binaries in
  `…app/Contents/Resources/bin/` — users never install RGBDS.
- **Emulator**: `open -a SameBoy built.gbc`; stretch — drive SameBoy's debugger
  for breakpoint/warp smoke tests (§6).
- **Packaging**: PyInstaller `--windowed` → `.app`; codesign + notarize if
  distributing. Briefcase fallback.
- **ROM handling**: app never bundles the ROM; first launch asks for
  `DWM-original.gbc`, verifies MD5 `1ca6579…`, remembers path.
- Native niceties: QUndoStack ⌘Z, ⌘B build, ⌘R run, autosave, recent projects.

### Module → ROM primitive map
| GUI module | Edits | Backed by |
|------------|-------|-----------|
| RoomCanvas | screens grid, tile paint, collision overlay, exit placement | room format + LZ codec + render_rooms logic |
| TilesetPanel | import PNG → 2bpp, dedupe, ≤4-group palette mapping | build_combined_tileset.py pipeline |
| **SpritePanel** | **import DWM2 sprite sheet → assign to monster slot** (§7) | same 2bpp/palette pipeline + LZSS codec |
| NPCInspector | sprite, facing, position, script binding, flag visibility | interact block format, 32 B RAM slots |
| DialogueEditor | text with live 18-char wrap + page preview, YES/NO wiring | dwm/text.py + two-level table emitter |
| ScriptEditor | pseudo-code w/ opcode autocomplete + inline validation; visual blocks later | compile_script.py (100 opcodes) |
| FlagManager | named flags, auto-allocation, usage cross-ref | EVENT_FLAGS free-pool analysis |
| WorldMap | room graph + warp arrows (vanilla + custom) | exit/transition data |
| GameData | breeding rules, family reassign/rename, encounters | build_breeding.py, gen_monster_db.py |
| BuildPanel | compile → build → MD5/space report → manifest → Run | builder.py + verify_integrity discipline |

---

## 5. Full-world editability — `extract_project.py`

The bifurcation needs to edit the *existing* game, not just add to it. A
companion tool decompiles the vanilla ROM into the **same** schema (Layer A),
using the dumpers we already have (`dump_map_table`, `dump_all_npcs`,
`dump_all_scripts`, `dump_all_text`, `analyze_event_flags`). Round-trip target:
`extract_project.py` then `build_project.py` on the unmodified project reproduces
the **byte-perfect** ROM (`1ca6579…`) — the regression baseline.

The **unified flag/trigger catalogue** becomes a first-class `world.flags`
section, auto-built by merging the three fragments that exist today
(`event_flags_complete.json` = 328 flags, `SIDEQUEST_MAP.md` = game-knowledge↔
trigger mapping, `all_scripts.json` = 732 branch-followed scripts). This is what
operationalizes "what triggers are tied to what" into something editable.

---

## 6. LLM-debuggable builds — the manifest (point that makes iteration possible)

The editor *will* produce bugs. The build pipeline must make them traceable by
an LLM with no memory of the build. `build_project.py` emits, beside the ROM:

- **`build/manifest.json`** — every emitted symbol → `bank:addr`; every
  `mapID` → its `CustomRoomTable` row; every text ID → addr; every script →
  addr; **per-bank free-space accounting** (used / remaining vs the reservation);
  the named-flag → address map; and a content hash.
- **rgblink `.sym` passthrough** + a human-readable cross-reference, loadable by
  SameBoy so symbols show in the debugger.
- **Deterministic builds** — identical project ⇒ identical ROM bytes, so a diff
  between two builds is meaningful.
- **Validation-as-errors** — every KEY_LESSONS rule is a hard check that points
  at the offending *project.json field*, not a raw ASM line: script index 0
  reserved; text ends `$F7 $F0`; newline only `$EF $EE`; choice `$E7 $F0`; NPC
  entries 5 B / exits 7 B with `$FF` only entry-leading; exit screen-bytes copied
  from a verified existing exit; palette-group ≤4; **bank-space overflow before
  rgbasm ever runs**; mapID collision; positional breeding conflict; and
  **orphaned-trigger detection** (a flag a preserved island reads but nothing
  sets after stripping).
- **SameBoy warp helper** — emit a debug script that warps to a given mapID, so
  testing one room is one command.

---

## 7. Monster sprite replacement (DWM2 rips) — pipeline

**Goal:** *replace* (not add) DWM1 species' graphics with DWM2 rips — both the
**large battle sprite** and the **small overworld/walking frames** (the two
indexed sprite sets DWM1 stores per monster; the supplied Water/Material family
sheets contain exactly these).

**Findings (S13):** monster sprites are **compressed** graphics in banks
~`$30`–`$3A` (raw-2bpp render = noise; confirmed $32 & $38). We already own the
hard pieces: the **LZSS codec** (`compress/decompress_tiles.py`) and the full
2bpp + ≤4-colour-palette pipeline from `build_combined_tileset.py` (flat tile
ordering, palette-group ≤4, the forced-index-1 colour, animated-tile avoidance,
2bpp re-encode on palette merge).

**Pipeline:** zip-import PNG (avoids the upload JPEG-conversion gotcha) → slice
frames → quantize to GBC palettes (≤4 colours/sub-palette, index-1 constraint) →
encode 2bpp → recompress → write into the monster's sprite slot.

**Risk = slot size.** A DWM2 sprite may not recompress small enough to fit the
original slot. Because we *replace, not add*, and have 20 free banks, the fix is
cheap: relocate the oversized sprite to a reserved bank (**`$7E`–`$7F` =
monster-sprite overflow**) and repoint it. Editor surface: "import sprite sheet →
assign to monster slot" rides the same PNG-import flow as custom room tilesets
(the "ADD CUSTOM TILESET PNG" the prototype editor already substantially has).

**Flagged confirmations for the build session (NOT done in S13):**
1. exact **monster → sprite pointer table** (confirm single-level / repointable),
2. **per-monster sprite dimensions** (the conversion target).

---

## 8. Reserved bank map (canonical lives in PROJECT_STATE.md)

20 unclaimed banks reserved up front so we never chase pointers mid-build.
($60/$64/$67 already in use by current patches.)

| Bank(s) | Reserved for |
|---------|--------------|
| `$69` | Breeding extension (special recipes 826+, Phase 2B) |
| **`$6A`** | **`CustomRoomTable`** — master dispatch registry (§2 keystone) |
| `$6B`–`$6E` | Custom room layouts + attr maps |
| `$6F`–`$72` | Custom tileset GFX |
| `$73`–`$74` | Custom text (Milayou dialogue/cutscenes) |
| `$75`–`$76` | Custom scripts/cutscenes |
| `$77` | Custom NPC + exit + room-metadata tables |
| `$7E`–`$7F` | Monster-sprite overflow (§7) |
| `$79`–`$7A`, `$7C` | Expansion reserve (3 banks) |

(Bank number ≠ mapID; the `$6x` overlap is coincidental. Gap banks
`$78/$7B/$7D` hold original graphics — not free.)

---

## 9. Milestones (maps to ROADMAP Phase 2→3)

1. **M0 — Table-driven keystone (§2)** + proof ROM (2nd room by table-row). The
   architectural unblock; do first.
2. **M1 — Headless backend**: `project.json` schema + `extract_project.py` +
   `build_project.py` + validators + **manifest**. Regression = vanilla
   round-trips byte-perfect; v23 content re-expressed as `example-project/`.
3. **M2 — Bifurcation**: repoint dresser ($2F), strip Terry intro, first Milayou
   room reachable & walkable; preserved-systems flag audit.
4. **M3 — Walking-skeleton `.app`**: open project, room tree, Build, Run.
5. **M4 — Room canvas + NPC inspector** (visual core).
6. **M5 — Dialogue + script editors** with live validation.
7. **M6 — Flags + world map + Sprite/GameData panels**, packaged signed `.app`.

## 10. Repo addition (when building starts)
```
editor2/
  core/   project.py extract.py compiler.py validators.py romdata.py builder.py emulator.py
  app/    main.py + one file per GUI module
  example-project/   vanilla + v23 content as project.json (regression baseline)
  tests/  compiler determinism + validator unit tests (pytest)
```
