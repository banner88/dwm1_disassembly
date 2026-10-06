# EDITOR DESIGN v2 — Cross-Platform Desktop App (PySide6) + Romhack Architecture

> **Status: PLAN LOCKED (S13) · AMENDED S72 (cross-platform, macOS primary)
> · REVISED v2 S90, **v2.1 same session** (user workflow decisions:
> fork-don't-fiddle / clone-to-custom, canvas-first, capacity meters,
> Gates tab, Triggers-as-sentences, arena/shops promoted, AI ban-list
> optional, family icons + follower visualizer, bg defect logged).**
> This document is the single home for the editor architecture *and* the
> romhack it serves ("Milayou's Story"). The build sequence lives in
> ROADMAP.md Phase 3 (re-sequenced S90); the canonical bank allocation
> lives in PROJECT_STATE.md. When an item here is implemented, update the
> owning reference doc + PROJECT_STATE status row, not this file.
>
> **What v2 changed (S90):** (1) a full tabbed UI specification (§5) written
> from the author's workflow, not from the ROM's file layout — every proven
> subsystem now has a named surface; (2) the **Layer A-lite decision** (§6):
> vanilla *data-table* editing (monsters/skills/breeding/encounters) ships
> through same-size compiler-emitted patches long before full vanilla-room
> extraction; (3) the **simulator becomes an in-editor service** (§5.9
> Balance tab) — the S78–S89 arc is a product feature, not just a dev tool;
> (4) a **backend gap register** (§9): every backend item a UI surface
> forces, so UI sessions never discover missing plumbing mid-build;
> (5) milestones M4–M6 re-cut into one-session ROADMAP boxes (§10);
> (6) stale v1 content retired (§11 ledger): the v1 §8 bank-reservation
> table (superseded by PROJECT_STATE's real allocation) and the v1 §7
> sprite-pipeline sketch (superseded by the built GFX-1..4 stack).

---

## 0. What we are actually building (unchanged)

Two things, one informing the other:

1. **The romhack — "Milayou's Story."** DWM1's engine, a new story from a
   new POV, starting at the moment Milayou is dragged into the dresser.
2. **The editor** — a cross-platform PySide6 desktop app (primary target
   macOS) whose job is to make (1) buildable by someone with zero ASM
   knowledge, and debuggable by an LLM when it breaks. Native Qt widgets,
   NOT a web/HTML UI (user requirement, reaffirmed S72).

Scope (user-reconfirmed S90): the editor builds Milayou's Story. It is not
"edit everything in DWM1" — but vanilla *game data* (monsters, skills,
breeding, encounters, items, shops) IS in scope because the hack tunes it,
and vanilla *world* editing is in scope exactly as far as the bifurcation
requires (§6). "We want to make a game here."

**Design principle (user decision S90, v2.1): FORK, DON'T FIDDLE.** As
long as capacity lasts, adapted vanilla content is produced by **cloning
it into custom objects and repointing** (rooms via clone-to-custom §6;
data rows via Layer A-lite same-size emitters). In-place edits to vanilla
structures are a *capacity-pressure fallback*, not the default. Corollary
(§5.C): capacity must always be visible — no invisible ceilings.

**Interaction principle (user decision S90, v2.1): CANVAS-FIRST.** The
canvas is the primary interface; tabs are secondary views of the same
project.json objects. Click an NPC → its inspector. Click a shopkeeper →
stock/prices. Click an exit → connection picker. Click an encounter
badge → pool editor. Toggle a room state → click things to see what that
state changes. Every object is editable from where the author SEES it.

## 1. The romhack: bifurcation & "new world on the old one" (unchanged)

Unchanged from v1 — summary + pointers (full v1 reasoning preserved in git
history; operative facts live in the owning docs):

- **Bifurcation**: intro at mapID `$2F`; the dresser→GreatTree transition
  repoints to Milayou's first custom room; Terry recruitment stripped.
  (Milestone M2R — still open, deliberately re-slotted after the canvas
  exists, §10.)
- **Vanilla rooms KEPT as postgame** (user decision S55), lightly rewired.
- **Preserved islands** (must keep, flag-dependency audited): Arena
  (`$06/$07/$5D/$5E`), Starry Shrine (`$09`/`$08`), Library (`$12/$13`),
  Vault (`$0F`), Item Shop (`$50`), first-monster give (scripted `$29`).
  Orphaned-trigger detection (§8) is the safety net.
- **Cold Farm is the editor-era WRAM strategy** (built: CF2/CF3/CF4 —
  MONSTER_DATA, patches/wram.asm banner). The hand overlay's ≤14 rule is
  exploration scaffolding only; editor-emitted systems never inherit it.
- Capacity: ~30–80 rooms needed vs 149 free mapIDs (`$6B`+; ≥`$80`
  cleared S66) and 11 unallocated banks + reserves (PROJECT_STATE "Bank
  allocation" — the single source of truth).

## 2. Architectural keystone — table-driven dispatch (BUILT)

v1's "build it first" item is **built and proven** (S42 keystone: bank
`$71` `Custom26DDTable`/`RoomEncTable`, +BGM resolver S64; hardcoded
`cp` chains retired). Historical rationale in git history; as-built
reference: PROJECT_COMPILER §1, CROSSBANK_ROOMS.

## 3. project.json — four layers (v1 designed → largely built)

`project.json` is the source of truth; ASM/ROM is a build artifact.
As built (PROJECT_COMPILER §2, the canonical schema reference):

- **`custom`** — BUILT: `rooms[]` (screens/render/encounters/scripts/
  music), `dialogue[]`, `scripts[]`, `palettes[]`, `music`, `wram`,
  `flags[]`, `vanilla_exit_extensions`.
- **`progression`** — BUILT (E2, S70): `quests[]`, `enemies[]`.
- **`gamedata`** — STUB today. v2 defines its build-out (§6 Layer A-lite):
  `monsters`, `skills`, `breeding`, `encounters`, `families`, later
  `items`/`shops` (E8/E9).
- **`world`** — STUB today (Layer A). v2 re-scopes it (§6): transitions/
  strip/retarget arrive with the bifurcation milestone; full vanilla-room
  round-trip (`extract.py`) stays future.
- **`build`** — BUILT: bank map enforcement, validators, manifest.

Named flags auto-allocate from the audited safe pool (EVENT_FLAGS;
32 truly-safe flags S57 + E3 SRAM banks 1-3 for campaign-scale state once
a schema exists — E3 b2).

## 4. App platform — PySide6 (decision unchanged; S72 text carried)

Chosen: **PySide6 (Qt 6)** — all project logic is already Python and
imports in-process (zero IPC); QGraphicsScene is purpose-built for
tile/map editors; packaged per-OS. Rejected: Swift (rewrites the core),
Tauri/Electron (IPC + web UI ruled out), Tkinter (proven insufficient).

Three layers, GUI on top — as built S72:

```
editor2/app  (PySide6 GUI)          ← tabs of §5
editor2/core (pure Python, NO Qt)   ← project/compiler/validators/builder/
                                      emulator/render (+ future: gamedata
                                      emitters, extract)
existing assets                     ← dwm/, tools/, simulator/, randomizer/
```

Hard rules (unchanged): project.json is truth · `core/` never imports Qt
(headless build is CI-able and Claude-workable) · deterministic compiler
(same project → byte-identical ROM) · validators cite their KEY_LESSONS/
PROJECT_COMPILER rule.

Platform/packaging — **carried from S72, still binding**: RGBDS
**v0.6.1 pinned permanently** (user decision S72), bundled per-OS;
`builder.check_toolchain()` preflight + File → "Set RGBDS folder…";
emulator launch via `core/emulator.py` (SameBoy on macOS, OS default
fallback, user command with `{rom}` override); PyInstaller `--windowed`
(`.app` codesigned/notarized on macOS); app never bundles the ROM (File →
Locate original ROM, MD5-gated `1ca6579…`); QUndoStack ⌘Z, ⌘B build,
⌘R run, autosave, recent projects.

---

## 5. THE UI — shell + tabs (NEW in v2; the product spec)

Design stance: the author thinks in **game objects** (this room, this
monster, this quest), not in banks. Every tab edits project.json objects;
the compiler owns the ROM mapping; the manifest (§8) closes the loop when
something breaks. Nothing in this section invents engine behavior — every
surface is backed by a decoded format or a built pipeline, cited inline.
Where a surface needs backend work that doesn't exist yet, it carries a
gap tag **[G-x]** resolved in §9.

### 5.0 Shell

*(As built S93: `editor2/app/main.py` — the tab strip below with Rooms
live and every other tab a stub naming its ROADMAP box; toolbar Open /
Save ⌘S / Undo / Redo / Build ⌘B (saves first) / Play ⌘R / Validate;
Build-log + History docks; `editor2/app/session.py` = one Session per
project: Document + live renderer + QUndoStack + change signals.)*

- **Project window**: top-level tab strip (Rooms · Gates · Monsters ·
  Skills · Breeding · Encounters · Music · Progression & Flags · World ·
  Balance · Build & Play). Global toolbar: Build (⌘B), Play (⌘R →
  SameBoy), Preview (embedded PyBoy [G-E]), Validate.
- **Build-log dock** (built S72) + **Validator panel**: every failure is a
  clickable item that navigates to the offending object/field (rule
  catalog: PROJECT_COMPILER §10 + S76 coherence sets + S77 validations +
  S74 skill invariants).
- **Manifest viewer**: symbol→addr, per-bank budget bars (used/free vs
  the PROJECT_STATE allocation), flag map, content hash (§8).
- **Search everywhere** (⌘K): rooms, NPCs, dialogue text, flags,
  monsters, skills, songs by name/id.
- Cross-navigation is a first-class rule: anywhere an id appears (a flag
  in a script, a monster in a pool, a song in a room) it is a link.

### 5.C Capacity meters (v2.1 principle — user spec S90 #4)

**No invisible ceilings.** Every panel shows its meter, sourced from the
machine-readable **CAPACITIES reference** [G-M] (every known ceiling
with its evidence; every unknown one as a measurement box):
- Rooms: free mapIDs (~128 practical, `$6B..$EA`); per-room screens
  (engine 16 = 4×4, custom schema currently 8 — measured S91); per
  screen-state NPCs (hard 8 + the distinct-sprite-sheet VRAM budget —
  measured S91; capacities.json).
- Palettes: 4 BG groups per room; the tile picker GREYS OUT tiles whose
  colours don't fit the remaining groups, and BADGES animated tiles
  (S99: the teal corner on metatiles using a slot the room's animation
  changes — per room, from the census; the old fixed 77/78 registry of
  build_combined_tileset is legacy).
- Banks: manifest budget bars per bank (built); bank-$60 spill state.
- Flags: safe-pool remaining; SRAM banks 1-3 once b2 lands.
- Species: custom slots used / 32. Quest EIDs used / tail. Songs / 95.
- Text/scripts: per-bank budget (numbers = E6, a G-M measurement box).

### 5.1 Rooms tab (the centerpiece)

Left: room browser (custom rooms; vanilla rooms read-only until Layer A
items land — vanilla render already proven, `render_rooms.py`, all 107).
Center: **canvas**. Right: inspector sub-tabs.

**Canvas (user spec, S90):**
- Displays **one screen at native GBC size** (20×18 tiles, 160×144) at
  zoom 1-3× (zoom built S72). Multi-screen rooms scroll/page between
  screens, with **explicit screen boundaries** and a **mini-map strip**
  (the room's screen grid, current screen highlighted) so it is always
  obvious what constitutes THE room vs the screen in view. Backing:
  screens-per-room from project.json; scroll-boundary system decoded
  (ROOM_DATA_FORMAT "Scroll Boundary System"); custom multi-screen scroll
  proven in-game (v28).
- **Room-state switcher** (user spec: "room state switching"): a state
  dropdown/stepper bound to the room's **step counter** — the engine's
  primary room-variant mechanism (ROOM_DATA_FORMAT §"Room State System":
  per-state tile layout + NPC set + exit set, counter×6 indexing; script
  control via opcode $12 + WriteRAM; custom-room counters live in the
  compiler region, base `$DE74`). The canvas renders the SELECTED state;
  NPC/exit overlays follow it. Authoring: rooms gain a first-class
  `states[]` list in the schema [G-G]; state 0 is the default.
- **Layers/overlays** (toggleable): tiles · attrs/palette-slots · NPC
  markers (thumbnails once the sprite catalog lands [G-B]) · door/exit/
  examine/step markers (S98) · encounter badge · walkability (seeded from the decoded tile
  behavior classes, GATE_GENERATION §5.1).
- **Tile paint**: pick from the room's tileset strip; rectangle/fill;
  undo via QUndoStack. Requires layout emission behind project.json
  [G-A] (today bank $64 is tool-owned).

**As built S93 (P3.3, canvas v1):** everything in the canvas spec above
except NPC drag (P3.5) exists: `editor2/app/rooms/` = `tab.py` (browser +
mini-map | tools / state bar / banner / canvas / status | picker /
palettes / inspector), `canvas.py` (QGraphicsView, pixel-exact, tools
pencil/rect/fill/eyedrop/select, tile OR palette-slot brush, layers
grid/palette-slots/walkability/markers with the S91 sprite crops, one
QUndoCommand per stroke), `tile_picker.py` (flat 16/row, threshold =
wall boundary), `palette_panel.py` (idx1/idx3 locked), `minimap.py`
(4×2, thumbnails, add/remove screen), `inspector.py`, `commands.py`
(PaintCells / AddState / RemoveState / LocalizeLayout / SetStateLayout /
AddScreen / RemoveScreen / SetPaletteColor / SetRoomField). The canvas
renders from `editor2/core/render_project.py` (live, no build; validated
pixel-identical to `render.py` on the example project — the §7 Tier-1
rule) over `editor2/core/document.py` (byte-exact load/save + the
mutations). Zoom is 1-6×. Two engine facts the UI surfaces rather than
hides: palette-slot (attr) grids are per SCREEN, not per state
(CustomAttrCheck keys on mapID + screen; KEY_LESSONS S93), and screen>0
attrs come from the per-screen attr map (S94; the S93 `base_entry+2`
stride is gone) — the inspector names the grid in effect. Acceptance:
`editor2/tests/test_canvas.py --rom` (ROADMAP P3.3).

**As built S94 (canvas v2 — user direction "not POC, real romhacking"):**
the room model is now two columns — **Vanilla rooms** (98, named via
`dwm/map_names.py`, all 211 screens rendered live, read-only; **Make
editable** clones one into the project after a confirmation: extract_room +
every screen's layout localized, so it is paintable at once) and **Custom
rooms** (New = blank room on a vanilla tileset; Copy = own layout copies;
Rename (`name` field, `id` stable); Delete). File → New project starts from
`editor2/templates/blank-project`. The unit of editing is the **player-sized
cell**: a METATILE = 4 subtiles + palette slot; the picker offers the
metatiles *found in this room* plus the author's own (`custom._editor.
metatiles`, built in the metatile editor — the only subtile-level surface).
**Select (V) is the default tool** (cell or marker, yellow selection
outline); paint/rect/fill/eyedrop work on cells; **Walkability mode (W)**
shows red/green cells and a click flips one cell by swapping its
bottom-right subtile (the one the engine samples — ROOM_DATA_FORMAT S94) for
a cross-threshold twin, copying the vanilla tileset into the project first
(`assets/<id>.2bpp`, bank $67). Mini-map is the engine's 4×4 grid. Structural
edits are whole-document SnapshotCommands (exact undo incl. asset files).
Engine/compiler foundation for this (same session): per-(screen, STATE)
attr + palette tables in the vanilla format (`CustomAttrCheck`/`CustomPalCheck`
rewrite — clones render every screen's and every state's own attr and
palette), compiler-owned ROM0 `$26DD` rows for `$6B-$6F` (records for every
room), 4×4 schema.

**S94b additions (same session — user: "next logical step = functional gate
redirects so you can test a room by hooking into an existing entrance";
"rooms have multiple versions, e.g. the servant boss room on fire or clear —
the editor must display that"):**
- **Room states are first-class for vanilla rooms too.** The state bar
  browses every VALID vanilla step ("vanilla state i of n", valid = the S91
  prefix filter now in `editor2/core/vanilla.py`); a clone carries ALL of
  them as `states[]` with per-state layout / attr / palette items and the
  cloned scripts rewired to the room's own `wCustomStep_<rid>_S<k>` counters.
  A vanilla room's variants are one mapID with N steps (flag → script →
  counter), NOT duplicate rooms; the only by-name duplicates in the table
  are the five "Castle: Chest Room (variant)" ids.
- **Entrances.** Inspector group "Entrances — how the player gets here"
  lists the vanilla doors routed into the room and offers **"Route a vanilla
  door here…"** (`rooms/redirect_dialog.py`: room → screen → door with a
  preview of both ends, wall warning on the arrival cell). In the vanilla
  view, selecting an exit marker offers "Route this door into a custom
  room…". Data: `custom.entrance_redirects[]` (PROJECT_COMPILER §2.12); the
  compiler re-points that one door in every vanilla state and leaves the
  other doors of the screen alone. Markers: magenta `R` = redirected vanilla
  door, green `IN` = arrival cell. This is the in-game test route for any
  custom room: route the GreatTree 2F Library door (the dialog's default)
  to it, Build, walk through.
- User-reported fixes: palette double-click on a borrowed palette now
  offers to copy it into the project (or clone the vanilla room) and opens
  the colour picker; labels no longer grow the window off-screen; NPC
  thumbnails have the throne-room floor knocked out.

**S95 additions (user feedback on S94b):**
- **The picker's first section is the room's VOCABULARY, and it never
  shrinks**: every metatile on any screen/state of the room plus everything
  its vanilla source room uses. Painting over a tile does not remove it
  (user: "otherwise I cannot use them again"). The vocabulary's sheet slots
  are protected from reuse by twins/imports.
- **Borrow tiles from another room** ("Borrow tiles from:" combo): that
  room's vocabulary drawn with THIS room's palettes. Same tileset → click =
  brush; different tileset → click imports the 4 subtiles into the room's
  project-owned tileset (free slots; bottom-right subtile keeps its
  wall/walkable side) and the result joins "My metatiles". The import
  reports the free-slot budget when it cannot fit.
- Old projects (no `record` on `$6B-$6D`) migrate on open, logged.
- **Palettes per screen/state**: "palette here" combo in Screen & state
  (`states[n].palette` / new `screens[k].palette`); both palette combos
  offer "copy from vanilla $xx <room>" (the room's derived palette becomes
  an editable project palette). A new screen inherits the palette on
  display — the servant-clone "second screen went back to burning" bug.
- **Exits from custom rooms (minimal P3.7 seed)**: Select a cell → "Add
  exit at this cell…" (destination custom/vanilla room → screen → arrival
  cell, previews, wall warning; edge cells are push exits) / select an exit
  marker → "Delete this exit". PyBoy-verified. What is still missing for a
  real routing system: one door object showing BOTH ends (and generating
  the return exit), drag-to-place, and the world graph — P3.7.
- The borrowed-tiles section lives in its own "Borrow" tab.

**S96 additions (user: "finish out the rooms stuff" — group A, tiles &
tilesets; built S96, USER-CONFIRMED 2026-09-25 ("Everything works")):**
- **Tileset tab (P3.3c)** beside "This room" / "Borrow": the room sheet's 128
  slots with status colours (placed / my metatiles / vocabulary / released /
  animated / free), a red dot where the graphic differs from the sheet it was
  copied from, the collision threshold as a step line, hover = users, click =
  highlight on the canvas; per-side free counts in the tab title, the picker
  header and every import error; **"Release unused vocabulary"** (persisted,
  undoable) lets imports/twins take the source room's unplaced slots, and
  "This room" marks affected metatiles (orange = may change, red = changed).
  The vocabulary is now DERIVED (source room tiles when the room still draws
  with that room's sheet), not registered by the GUI.
- **Change tileset** (inspector "Change…"): another vanilla room's sheet, a
  project sheet, or a new blank sheet; New room can start with a blank
  sheet. Screens keep tile numbers.
- **Import art tab** (top level, user spec: "import PNG, move the grid until
  I am happy, block out what I don't want"): panels detected per rip with
  their own grid offsets, nudge / Auto-align, Mask, Wall (same tile
  everywhere), Panel and Key-colour tools, palette fit under the engine rule
  (4 slots × 2 free colours; "keep" per slot), "Show as GBC" overlay, budget
  line, Add to My metatiles / Stamp onto the room with spill onto new
  screens. A whole DWM2 town (Pei) = one import, 87 slots, 6 screens.
- **Metatile palettes per subtile** (`pal` int or list of 4): painting a
  vanilla cell that mixes slots no longer flattens it.
- **Space meters** for banks $60/$64/$67/$71 in the status bar (§5.C).
- **Make editable works on every vanilla room** (98/98, all screens and
  states pixel-identical, clones compile) after fixing the extractor's script
  bank, the opcode arity table (BANK04_SCRIPT_ENGINE "Parameter counts"), the
  4×4 attr lookup and per-screen palettes.
- **Own colour 1 (user S96, second round: "can definitely feel the colour
  loss … extra colour would be good"):** `FreeColor1Hook` (engine, bank $17)
  lets a custom room's palette keep its own colour 1 in slots 0-3 — three
  colours of the author's own per slot (colour 3 stays black). Opt-in per
  palette (`free_color1`): the Import art tab ticks "Own colour 1" by default
  (Pei fits 1417/1440 subtiles exactly vs 632 with the cream fold); the
  palette panel has an "own colour 1" checkbox and unlocks colour 1.
  Round 4 (USER-CONFIRMED 2026-09-25 ("Everything works"), SameBoy): survives the field menu and battles
  (per-slot marker kept in the buffer; menu-open wipe forced cream in
  hardware by bank $73 `MenuOpenFreePal`).
- **Right panel QOL (user S96):** Metatiles / BG palettes / Room inspector
  are foldable sections (▼/▶, state remembered) in a vertical splitter;
  palettes show slots 0-3 unless "show system 4-7" is ticked.
- **Walkability is the author's (user S96 round 3: "let me do the
  walkability, there are many tricks to make a non-wall inaccessible to
  thin out budget"):** the import only binds cells marked with the Wall tool
  (bottom-right subtile below the threshold); every other graphic takes any
  free slot, walkable side first — no twins spent. "Unmarked cells must be
  walkable" restores the strict placement. "New room…" next to the target
  combo creates a blank-tileset room for the art when a room's sheet is full.
- **Editor revision** (`editor2.EDITOR_REVISION`) in the window title and the
  build log on open — a stale or half-applied checkout shows at a glance.
- **Import list:** every PNG opened stays in the project with its panels,
  masks and walls; "Open PNG…" adds another, the image combo switches,
  "Remove" drops one from the list (undoable).

**S97 additions (user: "all of group B" — P3.5a state rules + P3.5 NPC
inspector; USER-CONFIRMED 2026-09-26):**
- **State rules** (inspector group "State rules — which state shows when",
  `rooms/rules_panel.py`): an ordered room-level list "state n ← flag A set
  AND flag B clear […]" with Add / Edit / Remove / ▲▼, an **Otherwise**
  combo (keep what scripts set | force a state), and a rule dialog with a
  flag picker (project flags, well-known vanilla story flags, any number)
  and **New named flag…** (auto-allocated, pool meter). Engine-backed
  (bank $60 entry 8, run at every custom (re)load — PROJECT_COMPILER
  §2.13), so a custom room's version survives save/reload. The canvas shows
  "State shown when: …" under the state bar for the state on screen.
- **NPC inspector** (`rooms/npc_panel.py`; select an NPC marker): sprite
  picker over the S91 catalog (normal ids; "show all" for fragments/empty),
  facing, **behaviour** (the 13 measured routines, named, with the measured
  description; ROOM_DATA_FORMAT "NPC behaviour types"), **hidden** (type bit
  6), talk script (any script of the room, or **New talk text…** /
  **Edit text…** for plain talk scripts — pages auto-wrapped at 18 cells,
  charmap-checked preview; the WYSIWYG editor is P3.6), **in states**
  checkboxes (the same NPC across the screen's states), Delete. **Add NPC
  here…** on a selected cell (8-per-state cap enforced). **Drag an NPC** on
  the canvas to move it. The selected NPC's walk path is drawn (dots red on
  walls / off-screen — walkers never test tiles); every NPC shows a facing
  tick. Vanilla NPCs show the same form read-only (learn what a vanilla NPC
  does by clicking it). Cloned raw entries become typed entries with the
  same bytes on the first edit.
- Selection/NPC panels reset on every room/screen/state change (they used
  to keep a stale selection).

**S97 round 2 (user test of r1; USER-CONFIRMED 2026-09-26):**
- **Talk text per box** (`rooms/talk_editor.py`, replaces the r1 page box):
  one editor per text box (Enter = the box's second line), ▲▼ / ✕ / **Fit**
  per box, **+ Add box**, **Fit all**. Beside each box: the box exactly as
  the game draws it — frame, "*:" on box 1, the ROM font (bank $4F $4010) —
  with the word that crosses an edge in red, the lost cells / a scrolled
  third line in a red strip under the box, and "line n: used/max cells".
  OK is disabled until every box fits. Limits are the measured ones
  (TEXT_SYSTEM "Text boxes": 16 on box 1 line 1, 18 elsewhere, 2 lines).
  Saved as one `boxes` dialogue entry; older `text`/`lines` talk pages open
  converted into boxes.
- **Right panel**: NPC is its own foldable section under Room / screen /
  selection (hint text when nothing is selected). Every launch opens with
  **only Metatiles expanded** (BG palettes, Room / screen / selection and
  NPC folded — not remembered between launches); selecting an NPC marker
  opens the NPC section.
- **Rule dialog**: "New named flag…" puts the flag into the selected
  condition (or a new one) as a real list item in every flag list.
  (S97: nothing in the editor set a flag — S98 talk scripts do.)

**S98 additions (user: "Let's finish room work" = group C, P3.7; built
S98 — doors USER-CONFIRMED 2026-09-26 after rounds 2/3 below; talk / flags /
spots in game NOT yet user-tested):**
- **Doors — r1, SUPERSEDED by "S98 r2" below** (`rooms/door_dialog.py`, `rooms/object_panels.py`,
  `core/doors.py`): select a cell → **Add door here…** → pick the other
  room (any custom or vanilla room), screen and cell on a clickable preview
  (vanilla doors listed; warnings for edge-vs-scroll, occupied cells and
  unwalkable arrivals block OK). The editor writes BOTH ends (exit rows /
  an entrance redirect sharing a `door` id; vanilla double doors get
  `twin_of` rows) with the MEASURED arrivals — vanilla partner bytes, else
  on the cell (S98 r2: always on the door cell — the user's choice; r1 stepped
  out below interior doors) (ROOM_DATA_FORMAT
  "Arrival and edge rules"). Canvas: teal **D** markers, the arrival cell
  drawn as a dashed green box; drag either end to move it (the partner's
  arrival follows). Door panel: this end / leads to / arrive there / arrive
  here, **in states** checkboxes, **Go to the other end**, **Re-aim
  arrivals**, **Delete door (both ends)**. Deleting a room removes its
  doors.
- **One-way teleport** (rare, under **More ▾**): an exit row with no
  partner; red **→** marker, panel with destination, states, go, delete.
  The inspector's "Doors & entrances" group lists doors and one-way
  redirects (One-way from a vanilla door… / Show / Remove).
- **Examine spots / step-on triggers** (**Add examine spot here…**, More ▾
  → **Step-on trigger here…**): yellow **X** / pink **T** markers, spot
  panel with facing (any / down / left / up / right; examine only), script
  (New talk… / Edit talk…) and states. The legacy "spawn" shows as **X!**
  with a note (script 0 = the entry script). New rooms no longer get a
  spawn marker.
- **Talk editor with actions** (`rooms/talk_editor.py` TalkDialog): the
  per-box text, an **Ask YES/NO** checkbox, and tabs **Afterwards** or
  **If YES / If NO**, each with *Say something* (boxes), *Turn flags ON*,
  *Turn flags OFF* (project flags, vanilla story flags, New named flag…)
  and *Then move the player* (room / screen / x / y). Saved as a `talk`
  script (PROJECT_COMPILER §2.14). Used by NPCs and spots alike — this is
  how an NPC sets a flag for a state rule.
- **World tab** (§5.8 v0).
- Canvas letter markers have dark backgrounds for contrast.
- **S98 r2 — doors are OBJECTS (user: "click on a cell, then click 'add
  door', then obviously the door should appear on that cell. Then you
  doubleclick on the door to set its params … it should NOT need coordinate
  adjustment in the room you placed it … namable and connected to another
  door object"):** select a cell → **+ Door (D)** on the tool bar (next to
  Select) or "Add door here" → the door appears on the cell, **unconnected**
  (orange **D?**, its name drawn above it). **Double-click** it → door
  dialog: **Name**, **Connected to** = a searchable list of door objects —
  your doors in every room (with what each is connected to now) and every
  vanilla door by room (double doors folded) — with a preview of the chosen
  door and both arrivals; the door's own cell is never asked for (drag it
  to move). Links are two-way; connecting to a door that is already linked
  frees its old partner (the dialog says so); **Delete door** removes only
  this door (the partner stays, unconnected); **Disconnect**. In a vanilla
  room, double-clicking a vanilla door opens the same dialog (connect it
  to one of your doors). Rect / Fill are off the tool bar (R / F keys still
  work). The S98 r1 "Door tool" and pick-the-other-end-by-coordinates dialog
  are gone; `DoorDialog` remains only for one-way teleports.
- **S98 r2 — Walk button = walkability mode** (user: "Why can I no longer
  change walkability by clicking walk button and click on a tile?"): the
  tool-bar **Walk** toggle was only the overlay; it now switches to the
  Walkability tool (W) and back to Select, and the two stay in step. A
  refused flip (e.g. no free tileset slot for the twin subtile) now says
  why — it failed SILENTLY since S95 (the op's error is caught inside
  SnapshotCommand; `_flip_walk`'s `except RuntimeError` was dead code).
- **S98 r2 — tilesets are not shared by default** (user: "when I make a
  custom room it should STOP sharing tilesets by default, no?"): **Copy**
  of a room with a project tileset gives the copy its OWN sheet
  (`ts_<room>`, same bytes, metatiles carried). A room that still shares a
  project sheet (older projects, or "A tileset in this project" chosen on
  purpose) is flagged in the Tileset tab ("SHARED with: …") with **Give
  this room its own copy**; Change tileset gains **Own copy of the current
  tileset** (its metatiles filtered to the ones this room uses). Borrowing
  a VANILLA sheet shares nothing (read-only; copied on the first edit, one
  copy per room as before).
- **S98 r2 — walkable side full → "move the split down" (user: "make that
  an option")**: flipping a wall cell walkable when every walkable slot is
  used but the wall side has room asks first; Yes = slot thr−1 becomes the
  first walkable slot (its wall graphic, if placed, moves to a free wall
  slot; layouts and metatiles are remapped; the screen looks identical),
  every room on the sheet gets the new threshold; No = nothing changes. The
  refusal message names the rooms a shared sheet is shared with.
- **S98 r2 — Purge buttons** (user: "there needs to be a good way to purge
  unused tiles, like a button … purge unused own and purge unused
  borrowed"): Tileset tab **Purge unused borrowed (n) — frees x walkable /
  y wall** and **Purge unused own (n) — …**. A metatile is UNUSED when its
  four subtiles are placed in no cell of any screen/state of the rooms on
  the sheet; BORROWED = brought in through Borrow (`src: borrowed`, older
  ones recognised by their '<Room> [a, b, c, d]' name), OWN = everything
  else (made here, PNG imports). One undo step each. (User project: 15
  unplaced borrowed metatiles held 30 walkable + 13 wall slots of $6B's
  sheet — deleting tiles from the canvas never removed them.)
- **S98 r2 — dead edge doors refused** (user: "I walk onto door but nothing
  happens"): a door (or a dragged door / exit) on an x=0/9 or y=0 cell whose
  edge borders another screen of the room is REFUSED with the reason and the
  cell one step in (the r1 dialog refused these; the place-first flow had
  lost the check). Existing ones draw as a red **D!** ("NEVER FIRES"). The
  user's DoorToVillage at Cities_FOUNT (9,3) (screen 1 to the right) was one;
  moved to (8,3) it works both ways in PyBoy.
- **S98 r2 — arrive ON the door** (user: "arriving on the other side puts you
  half a tile down, instead of ON TOP OF the door"): custom doors arrive on
  the partner door cell; existing rows migrate on open. PyBoy on the user's
  project: Cities (8,3) → $6B on (7,2); step off, back on → Cities on (8,3).
  **S98 r3** (user: "I still arrive half a tile below the door … You arrive on
  tile fully always"): vanilla-door arrivals too (no vanilla $88 bytes);
  PyBoy now checks the PIXEL position (y mod 16 = 8), not only the cell —
  r2 only checked the cell, which hides a half-cell offset.
  `EDITOR_REVISION` = 'S98r3'.
- **S98 r2 — + Examine (X)** on the tool bar next to + Door (user: "Why is
  examine spot not a button?"); double-clicking an NPC or a spot opens its
  talk editor.

**S99 additions — animated tiles (P3.3e; user: "indicate currently animated
tiles (in vanilla)", "Can preview animation (maybe button or something so it
doesnt take up right hand side room unless used)", "Clones SHOULD get source
animation … Also yes migrate", borrowing "fine as long as it's clear whats
happening"; built S99, NOT yet user-tested):**
- **Canvas "Anim" layer** (tool-bar toggle, on by default): the border of
  every area of tiles the room's animation changes in game is drawn as a
  bright dashed line on a dark underlay (reads on water / lava / any art) —
  vanilla rooms show their OWN animation (the census; inert handlers such as
  Secret Passage show none), custom rooms their `animation` setting.
- **▶ Play** on the screen/state row (always visible; takes no panel space):
  replays the census schedule (`editor2/core/animation.py` `Player`) on the
  canvas at game speed (59.73 frames/s); ■ Stop restores the still screen.
  The schedule is the measured game behaviour — test_canvas v6 --rom asserts
  PyBoy VRAM == the schedule's prediction after 300 frames.
- **Inspector "animated tiles"** row: None / Same as source room ($XX name:
  what it does) / Borrow $XX name — effect (every vanilla room with a visible
  animation), plus one line saying which slots change, and — when the chosen
  room's sheet is not this room's — that whatever graphic sits in those slots
  HERE moves instead. Vanilla view: read-only "animates: …" + where the
  hidden second frames are. One undo step (SnapshotCommand).
- **Tileset tab**: animated slots teal (dashed = a hidden second frame: never
  place it), summary "animated here: N slot(s) — …" + slots protected for
  OTHER rooms sharing the sheet; the picker marks metatiles containing an
  animated slot with a teal corner ("ANIMATED in game" on hover).
- **Slot protection follows the animation**: imports, borrowed metatiles and
  walkability twins avoid exactly the slots animated by the rooms on that
  sheet (`Document.animated_slots`) — 77/78 are ordinary free slots in a room
  set to None (before S99 they were always reserved).
- **S99 r2 — borrowing an animated tile keeps it animated** (user: "I
  borrowed the moving water from castle and put it into my custom room but
  it doesnt move" — the S99 import copied the GRAPHIC into a free slot and
  the room animated nothing): Borrow-tab import of a metatile whose slots
  its source room animates (`Document.import_metatile(anim_src=)`) puts
  those subtiles into the SAME slot indices (+ a swap's hidden partner
  frame), moves tiles already in use there to a free slot on the same side
  (layouts remapped), and switches the room to that room's animation — if
  the room already plays a different animation with tiles of its own, a
  dialog asks: switch / import it still (static) / cancel. The status line
  says what happened, incl. the walkability of the fixed slot in THIS sheet
  (an animated slot cannot move to the other side of the threshold). The
  same-sheet brush from the Borrow tab offers the animation switch too.
- **S99 r3 — "Make animated" tab** (user: "please make the 'make
  animatable' tab. Bonus points if you can make a little tab/edit doodad
  that lets me re-paint a second tile in a paint-like manner"; and "how do I
  change animation of e.g. the water? Double clicking on the tile doesnt
  bring up any animation info"): a 4th Metatiles tab
  (`rooms/animate_tab.py`). **Double-click a plain cell** (or "Use the
  brush" / "Use the selected cell") loads that metatile: the head says
  whether and how it animates now and how many cells of the room draw it
  (all change). **Slide sideways** or **Two-frame flip**; the **Animation**
  list = every vanilla animation that can host it (`Document.
  animate_candidates`): free slots / pairs (the room's CURRENT animation's
  slots already drawn by other tiles are taken; any other source's slots can
  be emptied), tiles it must move and whether the sheet has room for them
  ("no room to move tiles" otherwise), walkability kept or not, and how many
  animated subtiles a switch would stop — best first. **Frame A / frame B**
  16×16 paint pads in the tile's own palettes (left paint, Shift fill,
  right pick; colour swatches; Copy A→B, Flip ↔/↕, shift ◀▶▲▼, Clear) +
  a live preview at game timing. **Make animated** (one undo step,
  `Document.make_animated`): frames into the chosen slots (B into the
  partner slots), tiles in the way — and on a SWITCH every tile in use in
  any slot of the new animation — move to a free slot on the same side
  (unrelated tiles must never start moving), this room's cells of the
  metatile remapped, the new metatile added to My metatiles, the room's
  animation set, ▶ Play started. The Selection panel shows "animated: yes —
  slots … move with $XX's animation" per cell.
- **S99 r4 — unintended animation found + fixed; Make still** (user: "Why
  is the mirror in $6b moving? I never wanted it to move. It also didnt move
  in earlier editor versions."): the S99 migration gave clones their source
  animation, but pre-S99 imports had used the source's HIDDEN-FRAME slots
  as free slots (the user's Servant clone: an Arena-Rooms mirror in slots
  62-63 = the flames' second frames). On open the editor lists every tile a
  `source` room places in its animated slots that is NOT the source room's
  own art there (`Document.stray_report`) and offers the fix
  (`repair_animation`, one undo step): the tile moves to a free still slot
  on the same side (all placements follow) and the source's own art goes
  back into the animated slot, so the room's real animation keeps working.
  Make animated now always stores the explicit id (`0x3F`, never
  `source`), so deliberate art is never taken for a stray. **Make still**
  (Make animated tab, `Document.make_still`): copies the tile's current
  graphics into still slots and remaps this room's cells of it — other
  animated tiles keep moving.
- **S99 r5 — part tools on the frame pads** (user: "allow copy of
  quadrants separately not just a -> B. Make it easier to edit"): every
  tool acts on the EDITED frame (yellow border; click a pad to switch) and
  the selected PART — Whole tile or one 8×8 quarter (the ◤◥◣◢ buttons, or
  Ctrl+click a quarter; dashed outline on both pads). Copy / Paste (a
  copied quarter pasted on Whole fills all four; a copied whole pasted on a
  quarter gives that quarter; the status line says when the target quarter
  has a different palette, since pixels are colour numbers), A → B, B → A,
  A ⇄ B, Flip ↔/↕, Shift ◀▶▲▼ (wraps inside the part), Clear, and a local
  **Undo** (100 steps) / **Revert** (frames as loaded) — the room is
  untouched until Make animated, which stays one project undo step.
- **S99 r6 — take-over + the count** (user: "Make animated is greyed out
  … Surely it should allow me to shift animation to tile I'm editing??"
  + "Would be good to have a count"): a box at the top of the Make
  animated tab (and a line in the Selection panel) counts the room's
  animation — "slide **2 of 2** slots used — FULL", "flip 1 of 4 pairs
  (3 free)" — lists the tiles moving here, and states the rule (one
  animation per room; one slot/pair per different 8×8 quarter). When the
  room's animation is full the tile **takes over** a slot (listed first
  when it stops fewer moving cells than a switch; asked first): the tile
  moving there keeps its look — its quarters in the taken slot move to a
  still copy, its other quarters keep moving (Make still stops a tile
  completely). Slots the tile itself gives up (placed only by its cells
  here, not in My metatiles) count as free for tiles in the way. A grey
  button's note now names the limit: too small ("moves N in all, this
  tile needs M"), or the tileset lacks "N more free wall/walkable
  slot(s)". The tab drops a tile loaded from another room when the room
  changes, and "Use the brush / selected cell" work before a tile is
  loaded.
- **S99 r7 — the palm case** (user: "button is GREYED OUT … Not sure what
  'use the brush' or 'use the selected cell' does … no idea what selecting
  the animation drop down button does"): the tab is numbered — ① the tile
  ("Load the selected cell" / "Load the brush tile", or double-click),
  ② how it moves (with a one-line explanation), ③ paint the frames, ④
  borrow the motion from (the list, explained in its tooltip) — and a bold
  orange line above the button says why it is grey. Frame B starts as a
  copy of A; **quarters left the same in B do not move** (no pair, same
  slot, same walkability). When the tileset lacks free slots on one side
  but has them on the other, Make animated **moves the wall/walkable split**
  (`_shift_split`: tiles at it move to free slots on their own side; every
  room on the tileset gets the new threshold; nothing changes on screen or
  in walkability). The check counts every slot a switch sets moving (both
  kinds of the handler) and treats the old animation's slots as ordinary.
- **Defaults + migration**: clones get `source`; New room on a vanilla
  tileset `source`, on a blank sheet `none`; Copy keeps the original's value;
  projects without the field migrate on open (`source` when the room still
  draws with its source room's sheet, else `none`) — "MIGRATED … Save to keep
  it" in the build log.

**As built S102 — own animated tiles: the Animate tab (P3.3f; built S102,
NOT yet user-tested).** User S102: "This is NOT UI friendly. I dont …
understand the budget, how it works … I just want animated tiles and for
the UI to tell me wtf is happening … I have NO understanding why you built
in a drop down list for importing animations when I want to mostly make
them myself". Design rule taken from it: **fix the engine limit instead of
exposing it** — the S99 tab made the author pick a vanilla room's animation
(slots, pairs, take-overs, split moves) because the engine could only replay
those; S102's bank $6C engine animates any slot at any speed from authored
frames, so the UI can be about the art. The S99 "Make animated" tab (and its
take-over / split / candidate UI) is gone from the GUI; `core/animate.py`
stays (Borrow tab import of animated vanilla tiles, Make still, stray repair).
- **Animate tab** (Metatiles section, replaces "Make animated";
  `app/rooms/animate_tab.py`): a dark box of plain numbers — *This room: N
  animations, M tiles changing · Load: X % of what the game can change per
  frame (fine / busy but fine / TOO MUCH) · Free tiles on this tileset (only
  "only the selected cells" uses them; frames never do) · Frame storage
  (whole project): a KB of 15.7 KB · animation groups: g of 32* and, while
  editing, *With this new animation: load, free tiles used, + KB*; "How does
  this work?" expands one paragraph. **Animations in this room** list (name
  — motion, speed words, tiles, "(everywhere)") with **Edit** (switches to
  its screen/state, selects its cells, loads it) and **Remove**.
  **New animation / Editing:** *Use the selected cells* (or double-click a
  cell) → name → **How it moves** (Flip through frames / Drift right / Drift
  left / Sway (back and forth), one help line each; drift/sway: "the
  selection moves as one picture" = strip, sway: pixels each way 1-3; flip:
  loop / back and forth) → **Speed** (presets very fast 4 … very slow 128 +
  "exactly N game frames per step" + "One frame every N frames (≈ x per
  second)") → **Frames** (flip: every frame has its own painter `FramePad`,
  **side by side**, wrapping to the panel width — S102 r2, user: "I cant
  have frames side by side anymore?? How can I paint them?" — frame 1 = the
  map, dimmed and fixed; paint straight on any other (paint / Shift fill /
  right pick, each 8×8 tile in its own palette); the clicked frame turns
  yellow and is the one + Add (copies it) / − Remove / Shift ◀▶▲▼ / Mirror /
  Copy previous act on; Undo; Size − + zooms all frames; S102 r3, user: "Can
  I still copy or shift individual quadrants?" — the tools act on a PART:
  whole frame, one 8×8 tile (Ctrl+click) or one 16×16 cell
  (Ctrl+Shift+click), outlined dashed on every frame; Copy (any frame, the
  map included) / Paste (a smaller piece repeats to fill the part, a bigger
  one is cut from its top-left) / Clear) → live
  **Preview** at game speed → **What moves**
  ("only the selected cells (uses N free tiles)" / "every place in this room
  drawn with these tiles (M more places move)") → result line + a bold
  orange reason when Create is impossible → **Create animation** / **Save
  changes** (+ Cancel editing). Every action is one SnapshotCommand;
  Edit replaces the animation in place (same list position).
- **Copy a vanilla room's animation…** (bottom of the tab, collapsed): the
  S99 inspector combo + note, moved here (user: "Keep button"), plus **Make
  the selected cell still** for cells the copied vanilla animation moves.
  The inspector keeps one summary line ("2 animations (8 tiles), copied
  vanilla $47 — Animate tab").
- **Canvas**: Select tool drag / Shift+click selects a rectangle of cells
  (`sel_rect`, `cellsSelected`), drawn dashed; ▶ Play runs the vanilla
  `Player` and `tileanim.Player` together (own frames written over their
  slots); the Anim outline and the cell panel ("animated: yes — Cloud;
  moves with the copied vanilla animation $47") include own animations.
- Document ops (`core/tileanim_doc.py` `TileAnimMixin`): `anim_selection`
  (the facts shown before acting: which tiles change, own copies needed,
  other places that would move, free tiles, the problem text — the same
  code the operation runs), `add_tile_anim` (own copies for "only these
  cells" — the bottom-right quarter keeps its wall/walkable side; refuses a
  layout the room does not draw), `update_tile_anim`, `remove_tile_anim`,
  `tile_anim_budget`, `tile_anim_player`; `animated_slots` now includes own
  slots (imports / twins leave them alone).
- Help topic `editor2/help/15_animated_tiles.md` (step by step + the numbers).


Acceptance `editor2/tests/test_canvas.py --rom`: fresh project → Farm clone
at `$6B` → metatiles painted → a lone metatile painted over stays in the
picker → a Castle brick metatile imported (sheet bytes copied, threshold side
kept, exact undo/redo) and placed → one grass cell walled, one fence opened →
Library door routed to the clone → PyBoy: VRAM == canvas (incl. the imported
cell), the player is blocked / walks through accordingly, AND walks through
the Library door into the clone at the authored cell while the neighbouring
door is still vanilla.

**Inspector sub-tabs (per room):**
1. **Tileset & Graphics** — select an existing vanilla tileset, a
   combined mashup, or **upload PNG** → the proven
   `build_combined_tileset.py` pipeline (≤4-colour palette groups,
   forced-index rules, LZSS, animated-tile avoidance). [G-A folds
   emission behind project.json.]
2. **Palette** — user spec "select from existing or upload": pick a
   derived vanilla palette by source room (`derive_room_palette.py`,
   validated 30/30 vs SameBoy) or edit the 4 BG slots directly. The
   editor SHOWS the engine's forced rule (idx1=`$6BFF`, idx3=`$0000` —
   rendered as locked cells) instead of letting the author fight it.
   Backed: `custom.palettes[]` (built).
3. **NPCs** — placement (drag on canvas), facing, sprite picker
   (catalog [G-B]), per-state presence, step show/hide vs runtime
   show/hide (opcodes $48/$49) — the editor picks the right mechanism
   per ROOM_DATA_FORMAT §"which mechanism to use" — flag-gated
   visibility, script binding.
4. **Dialogue** — per NPC/script: page-accurate WYSIWYG with the real
   ROM font tiles, live 18-cell wrap, ~~auto-DTE~~ (S120: no DTE exists — one-cell
   contractions instead, TEXT_SYSTEM), auto page-split, YES/NO
   choice wiring with branch preview (built: `core/textenc.py` +
   `dwm/text.py`; preview rendering = Tier-1, §7).
   **As built S120 (ROADMAP P3.6; built, PyBoy-verified, NOT yet user-tested; help
   `20_npcs.md` "Text: speakers, voices, names"):** the shared box editor (`talk_editor.
   BoxList`, used by talks, conversations and cutscene texts) has a header **Speaker**
   ("*:" / a name… / the hero's name / nobody — line 1's cell limit follows it) and
   **Voice** (low $EA / high $EB / silent), and each box an **Insert ▾** (the hero's name
   `{hero}`, the lead monster's kind `{lead}`, `…`, `"`); every glyph of the font that
   dialogue uses is typed as itself and contractions are one cell, as in the game. The
   preview == the game, pixel for pixel (measured on 4 boxes; the hero's name previews
   as the new-game "TERRY" tiles). Nested questions are the conversation / cutscene trees
   (S101 / S119). Not offered: `$E8` positions, `$E9` sounds and `$F9` slots other than
   the lead monster (their contents are filled by game code).
5. **Triggers** — interact entries (examine spots / step-on triggers — the
   "spawn point" was a misnomer, S98), doors and exits (custom↔custom
   and custom↔vanilla incl. `vanilla_exit_extensions`), step-counter
   advance rules. Formats fully decoded (ROOM_DATA_FORMAT).
6. **Cutscenes** — user spec: authoring + playback, per room.
   *Authoring*: the **storyboard editor** — a symbolic stepper over
   script ops (all 100 opcodes; CUSTOM_CUTSCENES holds the verified
   movement/visibility/timing opcode reference): dialogue pages, choice
   branches, flag effects, gives, warps, BGM changes as a navigable
   flow; NPC blocking (moves/show/hide) animates on the canvas as
   positional keyframes, with a virtual flag/inventory panel to walk
   each branch. Strictly control-flow visualization over decoded
   semantics — never timing emulation (§7). [G-H]
   *Playback*: one click → embedded PyBoy [G-E] boots the cached
   savestate, warps to the room, arms the script — full engine fidelity.
7. **Encounters** — this room's pool + rate (per-room `RoomEncTable`
   row, built S42); pool CONTENTS need custom pools [G-C]. Threat
   preview inline from the Balance service (§5.9).
8. **Music** — room-default song (built S64: vanilla ids, DWM2 31-song
   catalog, imported MIDI), one-click audition [G-I].

**Room actions (v2.1):** **Clone room** (custom→custom AND
vanilla→custom via the §6.1 extractor [G-J]) with automatic mapID
allocation; **Delete/retire**; **New room** from blank or from a
template. Clicking a vanilla room in the browser offers "Clone to
custom to edit" — the fork-don't-fiddle principle made concrete.

**Shopkeeper NPCs (v2.1, [G-K]):** an NPC bound to a shop is clicked
like any other; its inspector adds the stock/price editor
(`gamedata.shops`). Requires the E8 decode (opcode `$04` sub 0 → bank
`$09`; user testimony S72: community hex editors already edit
stock/prices, so a shallow table is expected).

**Gate themes (S122 — ROADMAP P3.7b part 2; as built S122, NOT yet user-tested).** User:
"can I currently use gate themes for custom room build? … I would love to use them for
custom rooms as an option for tileset, properly coloured" + "with the option of starting
with gate tiles/palettes then borrowing additional tiles elsewhere". The 16 maze floor
types (bank $28 sheets 0-15) are tilesets like any other — no schema change (PROJECT_COMPILER
§2.35):
- **New room** dialog: *Or a gate theme* combo (`THEME_KEY` `0x100 + t` in the source list)
  → `Document.new_room(gate_theme=t)`: the theme sheet, a new project palette from
  `$17:$51F5[t]`, one screen of the theme's floor.
- **Change tileset** dialog: *A gate theme* radio + theme combo + *and the theme's colours*
  (ticked) → `set_room_tileset(rid, 'gate', t)` (+ `use_theme_palette`).
- **Metatiles picker**: a theme room lists the maze's own 15 metatiles + the stairs
  (`ProjectRenderer.maze_vocab`) before anything borrowed; the vanilla source vocab only
  when `room_sources_vocab` is non-empty.
- **Maze screen…** (screen / state row): `MazeScreenDialog` (`editor2/app/rooms/maze_dialog.py`)
  — theme combo (defaults to the room's), ↑ ↓ ← → toggles + *exactly these sides*, a
  *Pattern floors* group, a picture list of the 254 screens (`ProjectRenderer.render_maze_piece`)
  → `stamp_maze_screen` (tiles + attr, one undo step).
- **Borrow**: the foreign-room box lists *Gate theme N: …* (16) after the game rooms;
  borrowing INTO a theme room fills `$40-$7F`. When the needed side is full of unused
  vocabulary the import raises `VocabReleaseWouldHelp` and the tab asks "release unused
  vocabulary and borrow?" — yes = release + borrow in one undo step (a failed command is
  already off the undo stack; nothing to undo).
- **Stairs down here** in a theme room paints the theme's own stairs (`$3C-$3F`).
- Help `12_gate_themes.md`. Verified: test_app `s122_gate_themes`; PyBoy theme screens ==
  the preview (PROJECT_STATE S122).
Not built (by design): animated / damaging theme floors (the game does neither outside its
maze floors); a preview of a gate's random floors (the user: "are they not random?") — the
model (`editor2/core/maze.py`) backs validation instead.

**Worlds (S123 — ROADMAP NG3; as built S123, NOT yet user-tested).** User: "a world that
can have encounters, encounter-free rooms (where you can also save), mini-bosses,
endbosses, flags and triggers. Enter via swirling portal, portal stops when boss beaten,
OR portal is different colour" + "Entering should be JUST like entering a gate". Schema
PROJECT_COMPILER §2.36, engine GATE_GENERATION §7.11.
- **World tab → Worlds panel** (`world_tab.WorldsPanel`, left of the graph): list +
  New world… (`NewWorldDialog`: name, a NEW start room in a gate look or an existing room,
  the landing cell) / Rename… / Delete; *start* (Change… = `StartDialog`), *portals*,
  *after clearing, the swirl*, *saving (JOURNAL)*, *cleared*; *Its rooms* table (battles,
  save, bosses, doors to) with Add room… / New room… / Remove / Open / Music for every
  room…; *Still needs* (the report); *only this world* filters the graph (green frames).
- **Rooms tab:** More ▾ → *World entrance here…*; NPC panel *colour* (8 swatches, canvas
  preview via `SpriteCache.get_coloured`) and **Make boss…** (`boss_dialog.MakeBossDialog`
  → `Document.make_boss`); the section *Inside gates and worlds* (world-aware texts).
- **Conversation dialog:** the *Vanish (this NPC leaves)* step (flicker / at once).
- **Gates tab:** a world is listed as WORLD with its settings locked (edited on the World
  tab); every other gate gets *after clearing, the swirl* (stop / 8 colours).
- Help `65_worlds.md`. Verified: test_app `s123_worlds`; PyBoy, the Verdant Rift demo
  walked end to end (PROJECT_STATE S123).
- **S123 r3 (user: "SHOW VISUALLY"):** every world cell is picked on the room's picture
  (`cell_picker.CellPicker`: 2x screen, grid, click; LAND green / PORTAL blue; walls
  refused; doors / exits / portals drawn) — New world… (a NEW theme room previewed as its
  plain floor), *Change…* (the landing), **Add portal…** (`PortalDialog`). The Worlds
  panel opens with **The way in**: ① the portal's room picture (◀ ▶ through several, Add
  portal… / Go to / Remove) ➜ ② the landing picture (Change… / Go to). Rooms canvas: **P**
  (a world portal; tooltip = where it lands) and **W↓** (the landing; drag = move).
Not built: random floors inside a world, a Gates-tab graph, clearing by a battle alone.

### 5.1b Gates tab (v2.1 — user spec S90)

The gate system as an authorable object; every element decoded
(GATE_GENERATION; S41 insertion proven in-game):
- **Gate list** → per-gate config row (`GateFloorDataTable` `$16:$70A6`:
  floor count, floor-type weighting via the selection tables, encounter
  pool 0-127 binding), the world entrance that leads to it, unlock
  trigger (a Trigger, §5.1c).
- **Per-floor plan**: procedural floors as-is; **insert a custom room at
  depth N** (the built S41 gate-rotation insertion + descent) — the room
  itself is edited in the Rooms tab (cross-link).
- **Boss floor**: boss room template choice, boss EID (script-param
  authoring per the S67 53-site census; join/redirect pair kept coherent
  — Set 2), boss stats/skills → Monsters tab row (Layer A-lite).
- Editing a VANILLA gate's row = Layer A-lite same-size edit; new gate
  slots beyond 32 = a measured capacity question (G-M box).

**As built S100 (P3.7b part 1 — custom rooms on gate floors; built,
PyBoy-verified, NOT yet user-tested).** User decisions S100: most custom gate
rooms are special-function or boss rooms without battles (fully hand-authored
"pseudo-gates" are ordinary rooms + doors — not this feature); "at most once per
dive" wanted; saving replicates vanilla (can save in special rooms inside gates,
not on random floors, not in boss rooms); the first floor stays the gate's own;
music: the gate's OR the room's own; the example project serves `gate_rotation`
on Villager floors 2-3 at 50 %.
- **Gates tab** (`editor2/app/gates_tab.py`): left, the 32 gates with ROM names
  and floor counts (★n = rules); right, the gate line (floors, boss room, depth
  tier, floor-type rows), **Custom rooms in this gate — tried top-down** (room,
  floors, chance, once / flag conditions, "room ready?" with the readiness notes;
  Add… / Edit… / Remove / ▲ ▼ / Open room), and the **Floor plan**: every floor
  with what the game serves in ONE dive — each custom room's chance of being the
  one served, computed floor by floor through the dive (an exact walk over which
  once-per-dive rooms were already served, like the engine's mask), then the
  vanilla remainder ("maze", or on floors 3, 6, 9 … "maze, or a special room
  (~50 %)"; "boss floor"); a tick box switches between "flag conditions hold" and
  "do not hold" (flags changing mid-dive are not modelled). The rule dialog: room
  (with its readiness), any floor / floors a-b (range limited to 2 .. floors-1),
  chance 1-100 %, "at most once per dive" (ON for a new rule — S100 r2), flag conditions (+ New named flag…).
- **Rooms tab**: inspector group **"Inside gates — served as a gate floor"**
  (`rooms/gate_panel.py`): where the room is served, the **arrival** cell
  (Selected cell / Clear; the canvas shows a draggable teal **G**), the Stairs down
  count, **saving allowed here**, **battles** (off / follow the gate — the dive's
  own monsters / fixed pool, refused for gate rooms), **music** (no song = the
  gate's music keeps playing; a project song; or a raw id), readiness, and
  "Gates tab…" (opens the gate serving it). **Stairs down** is placed from
  Selection → More ▾ → "Stairs down here" (purple **S↓** marker, draggable; the
  object panel explains it); the World graph skips stairs rows.
- Every edit is one undo step (SnapshotCommand); `EDITOR_REVISION` 'S100' (r3: 'S100r3').

**As built S101 (P3.7b part 2, first half — custom boss floors; built,
PyBoy-verified, NOT yet user-tested):**
- **Gates tab → "Gate settings"** per gate: *floors* spin 2-99 (incl. the
  boss floor; "Vanilla" resets), *boss floor* combo = vanilla / another
  gate's vanilla boss room (`vanilla:$xx`) / any custom room (⚠ no arrival
  cell) + *Open room* + a readiness line (arrival, saving, song); *hand-made
  gate* checkbox (rules may take floor 1); *Project enemies…*. The list
  shows the project's floor count, ♛ (boss set) and ✎ (hand-made); floor
  plan and rule dialog use the project's floors / first floor.
- **Enemies dialog** (`app/enemies_dialog.py`): project enemies (EID 519+)
  added from a vanilla row (bosses first); name, species, level, exp, six
  stats, joins? = always / sometimes (tier 1-6) / never, join version,
  skills ×4, AI weights; *Make join version* (stats halved, always joins).
  Edits a scratch copy → one undo step on OK.
- **NPC sprite picker → Monsters tab**: every safe species with its
  captured thumbnail (filter by name); picks `('monster', species)` → NPC
  `monster` field ($F0). Canvas and NPC panel draw the species
  (`MonsterCache`, key $1000 + species).
- **Conversation dialog** (`app/rooms/conversation_dialog.py`): a tree of
  steps (Ask → If YES / If NO, If flags… → Then / Otherwise), + Add step ▾,
  ▲▼, Remove; per-kind editors — text boxes with the in-game preview, flag
  lists (+ New flag…), Battle (1-3 enemy pickers: your enemies ★, vanilla
  bosses, all vanilla rows; *Enemies…*), Helper (destination room: Castle
  throne or a custom room + screen / cell; landing cell; sprite, default
  $21 Watabou; optional text), Move, Stop; a problems line gates OK. Opened
  from the NPC panel (*New conversation…*, *Edit talk…* on a conversation)
  and the "Inside gates" group (*Arrival conversation…* = the room's entry
  script, all screens or one; warns that it runs on every arrival).
- "Inside gates" shows *Boss floor of: …*; boss rooms default to no saving
  and need a way out (a helper / move step or an exit), not Stairs down.
- `EDITOR_REVISION` 'S101'. Test: test_canvas v8 (`--only-v8 [--rom]`).
- **r3 ('S101r3') — Help tab** (`app/help_tab.py`, topics `editor2/help/NN_*.md`,
  first `# ` line = title, search filters by text, Help → Editor help = F1;
  `_revision.md` must equal `EDITOR_REVISION` — test_app enforces it;
  ROADMAP P3.H: build out + keep current, SESSION_PROTOCOL wrap-up item 7).
- **r2 ('S101r2'):** the helper editor's landing = "lands next to the player —
  on their left, turned to them" (default) or a fixed cell; default sprite
  $39 Warubou (the button says so; $21 = Watabou (vanilla)).
- **S100 r3 (user 15:11; built, NOT yet user-tested).** "Stairs down here" also
  PAINTS the cell with the vanilla next-floor well (`gates.WELL_SRC_MAP` $51,
  slots $2C-$2F; its plain surround replaced by the floor already on the cell,
  so it sits on any floor in the cell's palette), brought into the room's
  tileset once and listed in its metatiles as "Next floor down (well)"; if the
  tileset is full the stairs still work and the status line says why. The
  gate group moved OUT of Room / screen / selection into its own foldable
  section **"Inside gates (gate floor)"** (hidden for vanilla rooms; the
  splitter state key is now `ui/rooms_right_split5`). Every inspector combo is
  sized to a short minimum (`inspector.narrow_combo`, popups keep full texts):
  the animation combo alone had made the inspector ~1,500 px wide.
- Acceptance (machine half MET): test_canvas v7 `--rom` (GUI authoring on a
  fresh project → PyBoy from a scripted new game) + test_compiler S100 cases;
  the demo ROM on the user's save (GATE_GENERATION §7.6 "Measured end to end").
- Part 2 (open, ROADMAP P3.7b part 2): per-gate settings (floor count, floor
  weighting rows, depth tier, monster-pool binding), a custom boss floor
  (template + boss fight/join + no saving), gate entrances / unlock triggers.

**As built S115 (ARC NG / NG1 — new gates; built, PyBoy-verified, test ROM USER-CONFIRMED 2026-10-03 12:39 ("Excellent, confirm works");
help `60_gates.md` "New gates"):**
- Gates tab: the list = the 32 vanilla gates + the project's new gates (NEW, orange,
  tooltip "a copy of gate n"); **New gate…** (dialog: copy of [vanilla gate], name,
  floors — default the source's) → the next free number 32-95, selected; **Rename…** /
  **Delete** (new gates only; Delete confirms and removes the gate's custom-room rules and
  entrances; one undo step). The head line names the source; the sub line lists the
  entrances ("⚠ no entrance yet — Rooms tab: …" for a new gate without one). Gate
  settings work unchanged on new gates; the boss combo's "Vanilla — …" item is the
  source's boss room, marked "(⚠ runs that gate's story scripts)"; other gates' vanilla
  boss rooms stay offered.
- Rooms tab: Room / screen / selection → More ▾ → **"Gate entrance here…"** (pick a gate,
  new gates first) writes the vanilla portal exit row (`gate:N`, gate_flag 1) and paints
  the next-floor hole (`paint_well`, like Stairs down); the object panel shows **Gate
  entrance** ("gate N — name, floor 1"); the canvas tooltip says "gate entrance → gate N".
  The World graph does not draw gate entrances as map links.
- Encounters tab → Gates: new gates at the end of the list ("NEW (copy of gate n)"); their
  floors start on the source's rule. Rooms tab "Inside gates": served-in / boss-of names
  include new gates.
- Not yet: a new gate's own floor types / depth tier (the source's), entrance conditions
  (NG2), fully custom gates (NG3).

**As built S117 (ROADMAP NG2 — swirls / cleared; built, PyBoy-verified, NOT yet
user-tested; help `60_gates.md` "Swirls and cleared").** User: "Make is as simple and
straightforward in editor as possible. Boss cleared - no swirly. Boss cleared BUT we are
inputting new boss or redirecting to new gate - swirly."
- Nothing to set by hand: **"Gate entrance here…"** now also adds the spinning swirl
  object (an NPC entry with `swirl_of: N`, shown while gate N is not cleared) and paints
  the still swirl (`paint_swirl`, room $24's swirl metatile borrowed into the room — the
  S115 hole picture is gone); the status line says when the screen had no room for the
  object (8 NPCs) or the tileset no room for the picture. Delete either freely; removing
  the exit removes its swirl.
- A vanilla gate given a custom boss floor: its vanilla portals' swirls spin again until
  the new boss is beaten (automatic — `VanillaNPCExtTable`, PROJECT_COMPILER §2.32).
- **"Lead this portal to another gate…"** (Rooms tab, a vanilla room, a portal exit
  selected; inspector button) → pick a gate, or "(back to the gate the game gives it)"
  to undo; the swirl follows the new gate.
- Gates tab: the sub line names the gate's cleared flag ("cleared flag $0011 (the game's
  own) — its swirls stop when its boss is beaten" / "cleared flag $17C0 — its own (a new
  gate) …", and for a re-bossed gate that its vanilla flag is set too) and lists re-routed
  portals among the entrances.
- Flag pickers everywhere (state rules, talks, conversations, encounter variants) list
  **`gate:N cleared — name`** (`rules_panel.well_known(doc)`).
- NPC entries accept `shown_when` (flag terms) in project.json — S120: authored in the
  NPC panel (*shown when* → **Flags…**: lists of flags that must be ON / OFF,
  `ShownWhenDialog`, `Document.set_npc_shown_when`) — the swirl uses the same mechanism.

**As built S120 (ROADMAP P3.7b part 2 — maze floors; built, PyBoy-verified, NOT yet
user-tested; help `60_gates.md` "Maze floors").** Gates tab → **Maze floors** group:
*maze look* / *special rooms* / *contents* — 16 rows each, every row named by the gates
that use it and what it rolls (`gates.row_summary`), the maze look with the row's floor
types as the game draws them beside the picker (`extracted/gate_floor_types/ft_NN.png`,
measured); *item tier* 1-3; **Vanilla** = the gate's own rows. One undo step each
(`set_gate_setting` maze_row / special_row / contents_row / depth). The right-hand panel
now scrolls (the groups no longer squeeze each other on a laptop screen).
**Rooms tab (S120, ROADMAP P3.4):** More ▾ → **▶ Play the game here (last build)** opens
the cutscene Playback window on the selected cell of this room (`cutscenes.room_recipe` +
`RoomOnly`; a new game, or the save picked on the Cutscenes tab).

### 5.1c Triggers (v2.1 — first-class concept, user spec S90)

Authored as sentences: **"When [flag set / quest state / item owned] →
[NPC dialogue variant / room state advance / NPC appears/leaves /
encounter pool variant / exit opens]"** — created from the thing being
affected (click the NPC → "add triggered variant"), never by hand-
editing shared data. Compiles to proven mechanisms: flag-conditioned
script branches (built), step-counter state advances (decoded; states[]
[G-G]), NPC show/hide (both mechanisms decoded), auto-allocated named
flags (built) — plus ONE new backend piece: **flag-keyed encounter-pool
variants** [G-O], a small extension to our own bank-`$71`
`RoomEncTable` resolver (touches nothing vanilla). The Progression tab
lists all triggers globally; the room inspector lists the local ones.

### 5.1d Cutscenes tab (as built S118 — ROADMAP P3.8 part A; built, NOT yet user-tested)

User direction (S118): "Reading in, displaying and playing back all existing cutscenes
in all relevant rooms … the intro … Cutscene playback window, where you can playback
vanilla and custom cutscenes. Include skipping text boxes as an option" — then on the
audit: playback is the real game "if I don't have to navigate to cut-scene in-game";
start state "might depend on cut scene"; text auto with a manual toggle; sound yes;
vanilla cutscenes are edited by CLONING the room (no in-place override). The editor
half (authoring) is part B.

**Model (headless, `editor2/core/`):** `script_ops.py` — the 102 opcodes' names,
params, kinds, sentences and the measured movement programs (BANK04_SCRIPT_ENGINE
"Script opcodes as measured (S118)"); `cutscenes.py` — the vanilla scripts decoded
from the ROM (banks $0C-$0F; positions = the live script counter), the project's
scripts as the compiler lowers them (`ProjectCatalogue` runs `Project`'s own lowering:
talk / conversation / shop / quest scripts, cloned rooms' raw ops; RAM symbols from
the build's game.sym), SCENES (every branch that shows something; path conditions
from the script start; triggers from the room data: entry / NPC talk / examine /
step-on), the actor model (positions / facing / shown per step) and the RECIPE that
sets a scene up; `CHAINS` (the intro). `playback.py` — the game itself (PyBoy) from a
cached base state per ROM (new game, or the author's .sav via CONTINUE), the recipe
applied, auto text / YES-NO / naming screen / D-pad, the live script position.

**Tab (`editor2/app/cutscenes_tab.py`):** left — Chains / Your rooms / Game rooms,
"Only scenes where actors move", search (texts, names, steps); middle — the header
(room, script, trigger, Plays when, notes, chain), ▶ Play / Record frames / Play on
(your last build / the original game) / Start from (a new game / my save file), the
step list (colour = kind, tooltip = the opcode's meaning, double-click a branch = its
scene), the full text of a text step; right — the step's picture: recorded from the
game (a background QThread plays the scene silently and keeps the last frame of every
step; one recording at a time) or, without PyBoy, the room render + the model's actors.

**Playback window:** 480×432 game picture; Pause / Frame ▸ / Restart / Next scene /
speed 1× (sound, audio-clocked through music_tab.SongPlayer) 2× 4× 8× (no sound);
Auto text + read time (frames a printed box stays) + the YES/NO answer; Auto D-pad;
Sound; keys (arrows, Z/Space = A, X = B, Enter = Start, Backspace = Select) for manual
play; a set-up log; the storyboard follows the game's step. A chain plays its scenes
in order (2 s after a scene's script ends; a scene that changes room simply carries on).

**S118b (the user's first look: "the wrong NPC jumps down"; "some 'cutscenes' are just
text boxes … egg evaluator"; "playing some cutscenes doesnt do anything … old man room";
"are 'play' for per-script line or entire window? Unclear"; "can you edit any of
this?"):** the ROOM STATE is chosen from where the game writes it (BANK04_SCRIPT_ENGINE
"Room state (S118b)") and named in the header; "Only scenes where actors move" = a walk,
a movement program or an NPC shown / hidden (`cutscenes.moves` — turning and the player's
own "shown" no longer count: 218 of 519 game scenes); titles skip the housekeeping step;
a walk-to that moves nobody says so in the header (the Old Man Gate Room: he already
stands there); **▶ Play scene** (the whole scene) and **▶ From this step** (the steps
before the selected one run fast — 24 frames a tick, no sound, text skipped — then normal
play). Editing = part B (not built).

**S118c (user: "Yeah obviously" — the copied room must behave like the game; "I really
would like to step through animation step by step"):** copies of game rooms follow the
game's room state (PROJECT_COMPILER §2.6 "S118c"; Rooms → State rules → *Follow the game's
room state*); the Playback window's **Step ▸▸** runs until the scene's next step is
dispatched (the server registers the `$04:$5613` hook on the first Step; steps that take
no time share a frame and are logged together) and **◂ Step back** restores the state
before it (up to 400 kept in the game process); the recorder keeps ONE picture PER STEP
(the frame the game ran it in) so the storyboard steps picture by picture. PyBoy stays the
engine: the scenes are the game's own code (sprites, movement programs, text, palettes) —
a model can only approximate them (the census shows where it does).

**S118e:** View → **Mute game playback** (⌘⇧M; QSettings `playback/mute`; overrides
every Playback window's Sound box, applied live); the bedtime scene from a real new game,
gate arrivals, walk-in (BANK04 "Where the player starts").

**S118d:** entry scenes reached through another script's room change are set up the way
that script leaves the game (BANK04 "Entry scenes reached by another script's room
change"); a crash-RESET is reported in the Playback log; test_app clicks through the tree.

**The game runs in its own process** (`editor2/core/playback_server.py`): the Playback
window and the frame recorder talk to a child `python3 -m editor2.core.playback_server`
over pipes (one JSON command per line; answers = length + JSON header + payload: the
RGBA frame, int16 audio, or the recorded PNGs). Every call has a timeout (10 s for a
batch of frames); a game that stops answering is killed and reported in the window —
"the game stopped answering (it crashed in this scene) … the editor is fine" — and
Restart starts a new one. Measured S118: a scene set up from a synthetic state can
crash the game, and PyBoy then never returns from the frame (KEY_LESSONS S118). One
cached start state per ROM, save file and sound mode (a state saved without sound plays
back silent).

**Verification:** `tools/census_cutscenes.py` plays every vanilla scene through the
same recipe and checks the position model at every wait (`extracted/cutscene_census.json`;
S118b: 519 scenes, 516 reached, 0 hung, 1 step on an empty NPC slot, 3,989 / 3,998
model checks exact); test_app drives
the tab, plays the intro in the Playback window and kills a hung game.

**S121 — the Milly hook (ROADMAP P3.16 + E7; built, NOT yet user-tested).** Cutscenes tab
→ **Milly hook…** (`editor2/app/milly_dialog.py`): the tick "Apply the Milly patch",
where she arrives (one of the project's rooms, screen, tile on the screen's picture,
facing, "arrive spinning"); "Roots room (Milly)": **Create the roots room** (one undo
step; becomes the arrival when none is set), *Warubou leads her to* (the scene's last
`move` step: Castle, the project's rooms, every game room), **Edit the scene…** (opens it
in the cutscene editor — Warubou's four boxes, the walks). OK = one undo step; a problem
the build would stop on is said at once. The cutscene editor: **Name the hero** under
"Text and choices"; `move` offers every game room; `hook:milly` / `hook:milly_arrived` in
the flag lists. Text previews draw the default name as the build does (MILLY only with the
hook on — `textenc.use_hero_glyphs`, re-applied on every structural edit / undo). Help
`64_milly_hook.md`.

### 5.2 Monsters tab

Species list: 221 vanilla + custom (ids 221-239, S105 G3; Gorbunok proven end-to-end).
Per species — every knob is a decoded, proven surface:
- **Stats & growth** (info table `$03:$4461` 43 B rows; enemy-stats
  `$14:$4C1D` 25 B rows), family, joinability, exp — vanilla edits ship
  via Layer A-lite emitters [G-D]; the randomizer already reads AND
  rewrites these tables (`randomizer/romdata.py`, `randomize_rom.py`) —
  reuse, don't re-derive.
- **AI weights** (`ai_weights` → category bases through the creation
  roll, decoded exactly S87) — edited with a plain-language explainer
  and a live behavior preview from the simulator (§5.9), because a raw
  0-255 4-tuple is meaningless to an author.
- **Skills learnset** — learn level + stat reqs + prereq chain
  (`SkillLearnReqTable` decoded; natural-learn proven for custom ids).
- **Battle sprite** — select existing or **upload PNG** → `sprite_codec`
  (semantic round-trip proven on all 442 streams) + overflow banks +
  the 8-byte `MonsterBattlePalettes` editor (GFX-1/2, user-confirmed).
- **Follower sprite** — select one of the 155 layouts (reassignment =
  level-1 repoint) or custom art import; the 8 parallel gfx-ID tables
  repointed together by the built tool (GFX-3/4, user-confirmed).
- **Library/lineage/name** — name tables, library text, lineage chain
  (proven in the Gorbunok arc); coherence Set 3 enforced live.
- **Family assignment + family icons (v2.1)**: reassignment built (B6,
  user-confirmed); the **Spirit** 11th family exists with icon shipped
  (B9; tab wiring open). The family "name" IS an icon (B8 trace), so
  "new PNG for the Spirit family" = a **family-icon editor** (PNG →
  tile pipeline → the icon slot) [G-P].
- **Follower visualizer (v2.1)**: all-4-direction walk preview over the
  155-layout library (port of the existing follower_frame_picker tooling
  into Qt), used by both the picker and custom-art import.
- ~~**KNOWN DEFECT (v2.1, user-reported S90)**: custom sprite BACKGROUND
  renders pure white where vanilla's is slightly creamy~~ — **RESOLVED**: the
  S106 sheet import puts the cream ($6BFF, index 1) behind every pose; the user
  on the S106 r2 ROM (2026-10-01 13:17): "background colour is perfect"
  (the S90 sprite was most likely the S21 Clam POC, purged S105).
- Custom-species creation = the Phase N pipeline behind a "New species"
  wizard (ids 221-239). Capacity meter: slots used / 19, plus the
  bank-$41 name budget (292 B, `species.text_layout` says whether the
  names pack) and bank $7E (16,307 B of art streams).
- **Backend as built S105 (P3.9b):** `project.json custom.species`
  (PROJECT_COMPILER §2.21) — name, short name, info (`clone_from` + the
  `gamedata.monsters` fields), `description_from`, battle art + palette,
  follower art + `walks_like` (a bank-$11 layout donor 128-214; S107 2b: or a
  walk `layout`, any of the 155) + palette;
  the recipe display is derived from the breeding table; enemy rows are
  project enemies. The wizard writes this section. Capacity (S105 G3):
  **19**, ids 221-239 — the game's ceiling (followers never work past 239,
  240+ collide with the breeding family codes). The NPC
  Monsters picker / Enemies species list already include the project's
  species (no thumbnail yet: render it from the species' follower art).

- **As built S106 (ROADMAP P3.10 part 1; `editor2/app/monsters_tab.py`, model
  `editor2/core/monsters.py`).** Left: every species with its walking sprite —
  your new species (+ "New species from a sprite sheet…", meters: slots / 19,
  bank-$41 name bytes / 292, bank-$7E art bytes), the 215 originals, the 6
  combat-only. Right: battle pose + animated 4-direction walk, then three pages.
  **Species** = the 43-byte info row as forms (family via the same validation as
  the Families tab; exp curve with level-99 total + "used by N"; growth curves
  per stat with a 6-line chart; resistances labelled none / some / strong /
  immune; reset) — writes only differences (`gamedata.monsters`, or a new
  species' `info` against its `clone_from`). **Where you meet it** = the decision
  the audit made with the user: a species has no stats or AI, so the tab lists
  every ENEMY ROW of the species (effective pools from the project, bosses + join
  rows, arena, coliseum / random / mimic / script battles, starter, project
  references) with editable level / stats / exp / joins / AI weights / battle
  skills (`gamedata.enemies` sparse, project enemies in `progression.enemies`).
  **Name & art** (new species): name, nickname, description donor, walking
  palette, battle colours, re-cut, remove (refused while referenced).
  **Sprite-sheet import** (`app/sheet_import_dialog.py`, core
  `core/sheet_import.py`): the sheet zoomed with every monster outlined; click
  one → red pose box (move / resize), six cyan / blue frame squares (move),
  arrow-key nudge, "Add boxes here" for a missed monster; right side = what the
  game draws (48 × 48 pose standing 2 px above the floor on cream; 4 colours —
  black, the cream (backdrop AND light parts, as every original pose; S106 r2),
  2 fitted free colours — click to change; walking in the closest of
  the 8 OBJ palettes, pickable); stores art streams, copies the sheet into
  `assets/sheets/`, records `source` boxes so "Re-cut" reopens them. Previews
  come from `core/sprite_render.py` (original species from the extracted art —
  == the PyBoy census; new species from their streams), and the canvas / NPC
  picker thumbnails use the same renderer (one species source). **S106 r3:**
  "New enemy row for this monster" + "Put the selected row in a gate…" (one
  encounter list at a time: slots, chances with the real chance after the
  running-sum cut, exactly 100 %, max in a group for 2-3 monster lists) — the
  §5.5 Encounters tab remains the cross-view. Part 2 (art of the original
  species) and part 3 (renames) are ROADMAP boxes (both built: S107 / S108, below).

- **As built S107 (ROADMAP P3.10 part 2a — art of the ORIGINAL monsters;
  model `MonstersMixin.original_art / set_original_art / set_original_art_props /
  reset_original_art / art_capacity`, compiler `editor2/core/art.py`).** The
  **Name & art** page now opens for the 215 original monsters too (TERRY? and the
  summons have none — PROJECT_STATE Iron Rule 8): **New art from a sprite
  sheet…** = the S106 sheet dialog in mode `original` (same boxes / colours /
  walking palette; the cut is remembered in `gamedata.art.<id>.source` and
  reopened next time), **Battle colours** (c0 / c2) and **Walking palette** work
  on the original art too (colours-only edits), **Back to the original art and
  colours**. The name fields stayed hidden for originals until part 3 (S108, below). The
  species list, the battle / walking previews and the canvas thumbnails draw the
  project's art (`sprite_render.original_art`); the meter under the list shows
  the art banks' bytes (49,149 B, $7F/$7C/$7A). Writes only what differs from the
  original game; each action one undo step (the asset files are snapshotted).
  Walking art always uses layout 0 here (2a USER-CONFIRMED 2026-10-01, except
  the still library icon → 2b); the family-icon editor (G-P) is 2c.
- **As built S107 2b (ROADMAP P3.10 part 2b — walk styles; core
  `editor2/core/walk_layouts.py`, PROJECT_COMPILER §2.23 "Walking layouts";
  USER-CONFIRMED 2026-10-01).** The sheet dialog (all three modes) packs the walking
  art for a **Walk style** = one of the game's 155 layouts instead of always
  layout 0: the list ranks all 155 by the pixels the game would draw differently
  from the sheet's six frames ("· 0 px off" = exactly the sheet's animation) and
  names who walks that way ("layout 2 — walks like Pteranod, MistyWing …");
  tags "its own" (the monster's original layout) and "copied into bank $10 / $11"
  (the follower bank lacks it — the compiler copies it, PROJECT_COMPILER §2.23).
  The best is preselected; a manual pick sticks while boxes are nudged (the
  ranking is redone 0.35 s after a drag rests; a new monster resets to best).
  Two walk previews: **In the game** (the packed art through the chosen layout,
  4 facings, A/B at ≈ 4 Hz) and **On the sheet** (the six cut frames, left =
  mirrored side) — the S24 "4-direction visualizer over the 155" is this pair.
  Result: `follower.layout` in `gamedata.art.<id>` / `custom.species[]` (a new
  species' `walks_like` is dropped; re-cut preselects the stored style). The
  model refuses (before writing) layout copies over a follower bank's free tail.
  The walk previews everywhere draw entry 0 on top (CGB OAM priority) with the
  entries' own Y-flip (`sprite_render.follower_frames`, S107 fix). Picking a
  layout for the ORIGINAL walking art is not offered: that art is packed for the
  monster's own layout, another layout would scramble it.
- **As built S108 (ROADMAP P3.10 part 3 — names / default nicknames /
  descriptions; model `MonstersMixin.monster_names_effective / monster_text /
  set_monster_text / reset_monster_text / text_capacity`, compiler
  `editor2/core/monster_text.py`, PROJECT_COMPILER §2.24; built S108 — the
  test ROM USER-CONFIRMED 2026-10-01, the tab itself test_app-verified, not yet run
  on the user's Mac).** The Name & art page's **Name and library text** group is shown
  for every monster with a page (originals 0-214 and new species; TERRY? / the
  summons still have none — Iron Rule 8): **Name** (≤ 9), **Default nickname** (≤ 4;
  what the join naming screen pre-fills), **Description 1-3**, **In the game** (the
  three lines in the ROM font, bank $4F; cells past 18 red), a note with what
  changed, the cell counts and the three byte meters (names / nicknames /
  descriptions — spill beyond a block is allowed, the build says when it is full),
  **Back to the original name and text** (originals), **Texts that name it… (N)**
  (opens the Dialogue tab filtered on this monster, old + new name). New species: the
  three lines are its OWN description; left empty, "Library text of" picks another
  monster's. Every species list in the editor reads `monster_names_effective()`
  (renames included). Each edit one undo step, validated by the compiler's model.
- **Dialogue tab (as built S108; `editor2/app/dialogue_tab.py`, model
  `editor2/core/dialogue_index.py` over `extracted/dialogue.json`)** — the read-only
  seed of P3.6 (§5.6): every text the game can show (2,560 text ids — the id → bank
  map measured in PyBoy, TEXT_SYSTEM "Text id resolution" — and the text tables:
  battle / field / item / spell messages, item / skill / monster descriptions).
  Search (words across line breaks, `$id`, `$bank:$addr`), a kind filter, **Names a
  monster** (word match incl. plural / possessive, case-sensitive, under the old and
  the new name; the hits highlighted), the full text with "also shown as" ids, and
  **Save as text file…** (the current list). Renames do not touch these texts; the
  tab is where the author finds them (user S108).

### 5.2a Families tab (as built S104 r2, ROADMAP P3.10a)

A tab before Monsters (`editor2/app/families_tab.py`, model
`editor2/core/families.py`). Left: the 11 families with their font icons
(`extracted/family_icons.json`) and member counts. Middle: members of the
selected family ("moved here" marks a non-vanilla member); **Move selected
to** + **Add a monster to this family…** (lists every species with its
current family). Right: **Arena-lobby dialogue** — the four vanilla voices
(A Slime / Plant / Zombie, B Dragon / Bird / Material, C Beast / Bug / Devil,
D ???), per family; for Spirit, **8 default names** (4 letters max) with a
one-line explanation of what they are. Writes `gamedata.monsters.<id>.family`
and `gamedata.families.*` — only differences from the original game; each
edit is one undo step validated by the compiler's gamedata model. When the
Monsters tab (5.2) lands, the family combo there uses the same setters.

**As built S107 (ROADMAP P3.10 part 2c, G-P; USER-CONFIRMED 2026-10-01):**
an **Icon** group above Settings (the right column now scrolls): an 8 × 8
pixel canvas (left button paints the chosen shade, right button picks the
shade under the cursor; one stroke = one undo step), four shade buttons
(3 black, 0 dark, 2 light, 1 background) each showing the INFO-page and the
continue-box colour (PyBoy-measured), previews at 4× in both palettes and at
1×, **Import an 8 × 8 PNG…** (brightness order: darkest → 3, then 0, 2,
lightest → 1; transparent → 1; bigger pictures shrunk), **Back to the
original icon**. Writes `gamedata.families.<f>.icon` (model
`FamiliesMixin.family_icon / family_icon_grids / vanilla_family_icon /
set_family_icon`); the family list and the Move-to combo draw the project's
icons.

### 5.2b Arena tab (v2.1 — user spec S90; S109: its own tab)

Rosters are FORMULA-addressed enemy-stats rows (E1 decoded,
HW-verified: `EID = $E0 + 9*group + 3*match + slot`, rows 224-304 +
King 481-483) — so the editor surface is a **tiers × matches × slots
grid** editing those rows directly (stats, skills, `ai_weights` per
enemy) through Layer A-lite [G-D], plus the victory cascade / `$CAB4`
tier flags surfaced read-only from the decoded Arena Lobby scr0.
Bracket SHAPE changes (more tiers/matches) = patching the formula
constants — an expert-mode knob, flagged, not v1 UI. [G-L wires the
authoring schema.]

**As built S109 (ROADMAP P3.10b; test ROM USER-CONFIRMED 2026-10-01 22:57).** Its OWN tab
(user S109: "Its own tab"), after Dialogue — `editor2/app/arena_tab.py`, model
`editor2/core/arena_doc.py` (`ArenaMixin` on `Document`), compiler
`editor2/core/arena.py` (PROJECT_COMPILER §2.25). Left: the ten groups (G-S with
their fee, Starry Night, the King; bold = edited, team sizes ≠ 3 listed after the
name). Right: **Entry fee** (classes; spin box 0-65535 + Original fee), **Winning it**
(the per-class victory cascade, read-only — `arena_doc.VICTORY`; flags are P3.14's)
and one card per match (three; the King one): **Master** (button with the sprite →
the room-NPC sprite picker: catalog persons + every monster; Original master),
**Monsters 1 / 2 / 3** (team size), the **team table** — one row per slot = its enemy
row (EID shown): species combo + level / HP / MP / ATK / DEF / AGL / INT / exp / AI
weights / battle skills, edited through `MonstersMixin.set_enemy_fields` (the same
rows the Monsters tab's "Where you meet it" lists); slots the team does not use are
grey "(not fought)"; **Back to the original match** (master, size and the three rows).
Every edit = one SnapshotCommand; the model validates with the compiler's own code
(a summon / TERRY? in a fighting slot refused — Iron Rule 8 — also from the Monsters
tab). Not in scope (user S109): bracket shape (fixed), prizes (none — "Only flags
progression"), the arena text (read-only on the Dialogue tab), the victory flags.
Help page `editor2/help/53_arena.md`.

### 5.2c AI ban-list (v2.1 — OPTIONAL, user-flagged S90)

Goal: "this monster/boss knows HealAll but never casts it; never uses
map skills." The decision machine + option lists + rule chains are
decoded (S80/S81) and the per-skill AI lever at record +3 exists, but a
clean knows-it-won't-cast-it switch is NOT yet proven — most likely a
small option-list filter in the AI build path keyed on a per-actor or
per-skill ban table. Banked as an optional measurement+patch box
[G-N]; the UI (checkbox per skill per boss row) ships only behind it.
Field-only skills are already battle-rejected by the S73b mechanism —
that half is done.

### 5.3 Skills tab

The S74 "skill editing surface" (Appendix, kept verbatim) as forms:
name, SKIL description, announce/banner lines, MP cost (BOTH storage
locations edited as one field — the sync is a coherence validator),
learn requirements, damage/tier knobs, animation + SFX presentation ids
(from `battle_animations.json`), field-cast vs battle-only. Custom-skill
scaffolding covers the DATA knobs; net-new ASM handlers remain an expert
escape hatch (patches/), surfaced but not WYSIWYG. The S74 editor-safety
invariants are hard validators.

**As built S110 (ROADMAP P3.11 — the 222 ORIGINAL skills; test ROM
USER-CONFIRMED 2026-10-02, the tab test_app-verified; the custom skills are P3.11c).** `editor2/app/skills_tab.py` over
`editor2/core/skills_doc.py` (`SkillsMixin`); compiler §2.26 + §2.20. Left: the
list (number + name, "(was X)" after a rename, bold = edited, items grey), a filter,
a kind combo (all / skills / battle actions + boss moves / battle items), the block
meters (name bytes incl. spill, SKIL text bytes + the 2,993-B spare). Right, in
collapsible sections (remembered open/closed):
- **Name and SKIL text** — name (1-9), three 18-cell lines with the game-font
  preview (`monsters_tab.text_pixmap`); ids sharing Blank / None say so.
- **MP and learning** — ONE MP field writing both copies (field `$07` u16 + battle
  record +4); Farewell / MegaMagic shown as "All MP" (fixed), StepGuard / MapMagic
  "field-only"; learn level + six stat minimums + "Evolves from" (names or ids, ≤ 5);
  ids $DA-$DD greyed (no learn row — the S100 hazard).
- **Power** — party / enemy min-to-max (typing a min above the max moves the max,
  and vice versa — no popup); a note names the skills sharing this handler.
- **Targets** — one foe / all foes / one ally / all allies / the user.
- **Monster AI** — plan (tag), weight, element (resistance names), damage class.
- **Behaviour** — one checkbox per READ bit of flags7/8/9 (`skills.FLAG_BITS`,
  each with its hover hint), the unread bits / fields greyed (`skills.DEAD`).
- **Looks and sounds** — "its own look" or any of the 222 (other-side donors
  labelled "(other side)", summons "(summon)", tooltips with the warning); **Announced as** = the
  battle line (bank $58 template → dialogue.json), read-only.
- **Who has it** — natural learners, enemy rows, the evolve chain (read-only).
- **Back to the original skill**.
Battle items (176-212) are shown read-only (an Items tab will edit them, user S110).
Every edit is one `SnapshotCommand`; a refused edit (bad name / text / number)
shows the compiler's message and leaves no undo step. Other tabs' skill pickers use
`doc.skill_names_effective()` (renames follow). Help: `54_skills.md`.

**As built S111 (ROADMAP P3.11c / P3.11d — the custom skills; test ROM USER-CONFIRMED
2026-10-02 15:08; the tab test_app-verified).** Compiler §2.27. The list adds the ten
built-in custom skills (224-233) and the project's NEW skills (234-254) after the 222
(kind combo: + "custom skills" / "new skills"; the meters include the custom name / text
regions). **New skill…** asks for a name and a base — only the stock skills the clone
census measured "same" (`custom_skills.clone_bases`) — and takes the lowest free id;
**Delete** removes a new skill (refused while a monster learns it, an enemy row has
it or another skill evolves from it — the message names them). A note at the top
names a new skill's base ("runs Zap's effect"); "Back to the base skill's values".
Per skill:
- **MP and learning** — a **Learnable** box (off = no learn row); MagicBurn / Anchor's MP
  box disabled with the reason (their code spends the MP); prereqs may name custom ids.
- **Power** — for built-ins the min-max boxes, Targets and Behaviour are disabled
  (their handlers set the damage and targets); an **Element** combo (own / none / the 27
  resistances) for every skill that reaches a damage ladder (the element census; others
  greyed with a hint), and the AI's element (record +5) follows it.
- **Looks and sounds** — **Sounds like** next to Looks like (a new skill's sounds follow
  its looks until set); **Announced as**: the stock line (read-only, as S110) for stock
  skills; for custom skills a mode combo (own line / a stock line that names the skill
  — `announce_choices`, the templates vanilla uses with the `{skill}` insert / none) and
  three line edits with `{name}`.
- **Its own numbers and lines** (built-ins only) — (S111b) the ratio fields ("1/3", a
  whole number; original shown beside, bold when changed; a refused value shows the
  compiler's message and leaves no undo step): MagicBurn MP share + damage per MP, Tame
  damage of ATK, Anchor MP charge, Quake own-side share, Mourn bonus per fallen ally;
  Tame / TameMore / TameMost meter, Tremor … QuakeMost power min-max, the Quake banners (allies / flyers, shared by the
  chain), Mourn's boost line, Anchor's four dialogs.
The Monsters tab's skill pickers rebuild when skills are added / deleted / renamed.
Help `54_skills.md` (custom skills, Element, Sounds like, Announce, Its own numbers and
lines, New skills, the limits: 21 slots, names share the bank $41 budget, which bases
are offered and why).

**As built S112 (ROADMAP P3.11e — skill ANIMATIONS; test ROM USER-CONFIRMED 2026-10-02 18:29 ("Fantastic, everything checks out"); the
tabs test_app-verified).** Compiler §2.28, engine BATTLE_SKILL_SYSTEM §11.9. User choices
(S112): new animation slots only (the stock 45 untouched), mashups of stock frames and
tiles (new tile art later), per skill an animation + motion / a screen effect / nothing,
sides as vanilla, the in-editor preview with sound as the test bench.
- **Animations tab** (`editor2/app/anims_tab.py` over `anims_doc.AnimsMixin`; after
  Skills): the list ($2D… + name; ⚠ when it does not compose) with **New…** (a copy of
  a stock animation's steps), **Duplicate**, **Delete** (refused while a skill shows it,
  naming them), **Rename…**, **Up / Down**; the meter line (length in frames and
  seconds, source animations x / 4, tiles x / 128, the skills showing it, warnings); the
  **preview** (`AnimPreview`: 60 fps QTimer over `BA.schedule`, the sprites drawn by
  `BA.draw_frame` at the renderer's X $50 / Y $60 on the battle cream, 2x; sounds via
  QSoundEffect from `extracted/anim_sounds/sfx_XX.wav` — the game's own engine recorded
  by `tools/render_anim_sounds.py`, 16-bit; Play / Stop, Sound, Loop; selecting a step
  shows its frame); the **steps table** (thumbnail + frame / sound / blank, a Frames spin
  1-256 = hold + 1, From); **Add frames…** (`AddFramesDialog`: any stock animation,
  playable, its steps as thumbnails, multi-select, inserted after the selection with
  their timing and sounds), **Add sound…** (the 35 cue ids, labelled by the animations
  using them; plays it), **Add blank**, **Remove**, **Up / Down**.
- **Skills tab → Animation** section: **Shows** = what its look shows / an animation
  (the 45 + the project's) with **Moves** (at the target / middle of the foes / each
  target in turn / flies across) / a screen effect (11 labelled) / nothing; a note says
  what the look shows per caster side and where the choice applies; a preview
  (`PreviewBox`) of the chosen or the look's animation.
Every edit is one `SnapshotCommand`; refused edits show the compiler's message. Help
`57_animations.md` (new) + `54_skills.md` "Animation". Residuals: new tile art; the
projectile "go back" loop is not authorable (copy frames instead).

### 5.4 Breeding tab (edit + simulate — user spec "see randomizer")

- **Table editor**: special recipes (bank `$69` full authoring stack
  B1-B7: overrides + appends + shadow validator) + family defaults +
  family reassignment/rename (B6/B8/B9). Provably-dead vanilla slots
  surfaced as reusable.
- **Simulation panel**: the randomizer's breeding analytics as a live
  view (`randomizer/breeding.py` + `profile_check.py`): per-species
  breeding-tree explorer (what breeds into it / what it breeds into),
  **depth-from-base** per species + the depth-profile histogram vs
  vanilla's measured profile, reachability/orphan detection ("nothing
  can produce X"), and the matcher-specificity trap made visible
  (BREEDING_SYSTEM "Depth is a function of matcher SPECIFICITY"). Edits
  re-simulate live.
- Coherence Set 1 (recipes ↔ library text) enforced as you type.

**As built S113 (ROADMAP P3.12; test ROM USER-CONFIRMED 2026-10-03 00:19 ("Tested, works"); help `58_breeding.md`):**
`editor2/app/breeding_tab.py` over `editor2/core/breeding_doc.py` (`BreedingMixin`) and
the resolver model `editor2/core/breeding.py` (== the game for every pair, PyBoy census —
BREEDING_SYSTEM "The resolver as measured (S113)"). Top: a summary (how many monsters
you get without breeding, deepest depth, how many nobody can get, special rows, rows
that never fire) + **Generate a tree…**, **Work on the whole table** (→
`special.table`), **Original special recipes**. Pages:
- **By monster** — every collectible monster (0-214 + new species) with its depth and
  how you get it (wild / starter / boss join / story gift / project egg reward /
  breeding / nobody); for the selected one: **Made by** (its library recipe + every
  special row giving it, with the number of pedigree × mate pairs each really decides,
  "0 — never fires", hover = the pairs; Add a recipe for it… / Change… / Remove) and
  **Makes** (offspring as pedigree or mate, with whom; double-click navigates). Right:
  **Try a cross** (pedigree, mate, plus, levels → egg + plus + the deciding row), the
  **depth chart** (bars = project, dashed = the original recipes with this project's
  monsters), **Problems** (nobody can get X, rows that never fire, library recipes that
  never give their monster; double-click navigates).
- **Special recipes** — the whole table in scan order (#, pedigree, mate, needs +,
  makes, adds +, from, decides), filter, Add / Change / Remove, removed originals can be
  brought back; edited / added rows bold.
- **Family recipes** — 215 slots: pedigree, mate, "works for n of m", changed; Change /
  No family recipe / Original recipe.
The recipe dialog offers the 11 families (Spirit included) and every species; the
compiler sorts the special table (PROJECT_COMPILER §2.29), so the dialog needs no
position. The generator dialog: **Deepest** 2-40 (S113b, user: "Goes only to depth 6? What if I
want deeper..?" — no game limit; the ceiling is the number of monsters not obtainable
without breeding, shown in the dialog), one share box per depth (Default / Even shares),
seed, monsters to keep; Propose shows the depth chart + counts; Apply = one undo step. Not built: the
offspring's skills / stats in Try a cross (bank $16 entry 4), a gender rule (open
question), live coherence beyond the library text (the compiler regenerates it).

### 5.5 Encounters tab

Cross-room/gate view of pools: which species at which levels where, per
gate/floor; per-row threat parity vs the author's stat edits
(`audit_threat.py` logic as a service); jump to any room's Encounters
sub-tab. Needs custom pools [G-C]; per-room enable/rate already built.

**As built S114 (ROADMAP P3.13a; test ROM USER-CONFIRMED 2026-10-03 09:52 ("Looks good. Give editor files"); help `59_encounters.md`;
model `editor2/core/encounters_doc.py`, compiler `encounters.py` / PROJECT_COMPILER §2.30).**
User decisions S114: per-gate per-floor lists as an option ("especially if I want to insert
custom rooms with its own encounters"); flag variants for gates too ("great idea"); a
separate rate per room; level ranges now, fight-length numbers later (Balance) — the model
exposes `enc_list_threat_rows` for it; the 'unused gate' does not matter; the new-gates arc
(ROADMAP NG1-NG3) builds on this. The tab, three pages:
- **Lists** — every list (the game's 128 + the project's 128+): "number · first use (+n) ·
  Lv a-b · monsters", bold = edited, grey = nothing uses it; "hide lists nothing uses";
  **New list (copy)** (a byte copy of the selected, named) / **Delete** (refused while
  used). Editor: name (own lists), battle rate (codes 0-7 named very rare … relentless,
  with "≈ N steps between battles outside gates" = the counter-table mean / the drain),
  monsters per battle (1/2/3 codes + real %), maze size, five slots (Monster… picker over
  your enemies + the game's 486 rows, chance, real chance, most in one battle) — slot and
  size edits are STAGED and written by **Apply** as one undo step only when they add up
  (the compiler refuses a list under 100 %), **Revert**; "Battles it gives most often"
  (`group_odds`, the measured draw); "Used by"; a Balance placeholder line.
- **Gates** — the 32 gates (bold = own plan) with floor counts; per floor a list combo +
  where the list comes from (the game's rule / your plan / this variant); **Show** picks
  the default plan or a flag variant; + Flag variant… / Edit variant flags… / Remove
  variant / Back to the game's rule; a **Shared** warning when a list the gate uses is
  also used elsewhere (copy it to change only this gate).
- **Rooms** — every custom room: No battles / A gate floor's list (gate + floor, pinned) /
  The dive's own list / Its own list; own battle rate (+ steps estimate); flag variants
  table (own list). The Rooms tab's "Inside gates" combo gained "its own list" and the
  inspector line shows the list / variants / rate.
Monsters tab "where met" and the pool dialog read the same live usage (floor counts, plans,
rooms) instead of `extracted/encounters.json`.

### 5.6 Music tab

Song library manager: vanilla songs, the DWM2 31-subsong catalog, **MIDI
import** (`midi_to_song.py`, built S64) with conversion warnings; the
95-slot bank `$74` budget bar; the room-assignment matrix
(`music.room_defaults` + per-room overrides); audition in PyBoy [G-I].
Open engine boxes stay listed in ROADMAP (InitBGM channel-count ext).

**As built S116 (ROADMAP P3.13b; built, PyBoy-verified, NOT yet user-tested;
`app/music_tab.py`, `core/music_doc.py`; help `61_music.md`).** User decisions
(S116): names don't matter as long as every song can be previewed and named;
custom gates and custom rooms need music (random vanilla gates keep theirs);
battle music wanted ("Milayou starry tournament uses different battle music …
more variety"); include the channel-count extension; MIDI import automatic.
* **Audition = the game's own engine, no emulator** (user: "Can you not extract
  songs?"): the ROM0 sequencer runs on `dwm/sm83.py` (`core/sound_engine.py`),
  `core/apu_synth.py` synthesizes, `SongPlayer` streams through QAudioSink
  (push mode). **S116b rewrite** (user, macOS: "stopped early after a few
  seconds … replay froze completely"; built S116b, NOT yet user-tested): the
  sink runs at the device's OWN rate (32,768 Hz resampled in the editor — Qt
  6.10/6.11's CoreAudio sink switches the output device's hardware rate to the
  requested one, and a device reconfiguration stops the stream); the buffer
  (0.4 s) is topped up every 15 ms with exactly bytesFree() (partial writes
  kept) — the S116 player only wrote once a whole 0.25 s chunk fitted, which on
  a small buffer never happens again; stop / replay = `reset()` on ONE reused
  sink (Qt's `stop()` drains asynchronously and the S116 player deleted /
  recreated the sink meanwhile); a stream the system stops is restarted (state
  POLLED each tick — PySide cannot deliver `QAudioSink.stateChanged`, and Qt
  >= 6.10 returns `QtAudio` enums that never equal `QAudio`'s: compare by
  `.name`); audio errors print `[music] …` to the terminal. Census-proven == the game (SOUND_SYSTEM §9). This supersedes the
  "audition in PyBoy" plan above — still within §7's rule: the sequence is
  EMULATED (the game's code), only the analog synthesis is the editor's.
* **Songs page:** every vanilla start id (extracted/sound_catalog.json — kind,
  channels, where the game uses it, an automatic label), the 31 DWM2 songs, the
  MIDI library, the project's songs (bold); filter + search; ▶ / ■ / Save as
  WAV…; a name for any song (`music.names`); Add to the project / Remove from the
  project (clears its assignments); Import MIDI… (automatic; the song file goes
  to `assets/music/<id>.json`, `source.file`). Meters: 95 song ids, bank $74,
  bank $75 bytes.
* **Rooms page:** every custom + vanilla room: the game's song, your song,
  "battles here". **Gates page:** every gate (vanilla + new): floors song,
  battle song. **Battles page:** normal / boss / arena / Starry final + a song
  per fight (the first enemy; pick from `enemy_choices`).
* Every edit is one SnapshotCommand; the plan is re-validated after the push
  (a refused edit is undone with the compiler's message).
* Residuals: the rooms table rebuilds ~200 combo boxes per refresh (fast
  enough, could be lazy); no per-channel mute / tempo view; the synth's tone is
  documentation-accurate, not SameBoy-exact.

### 5.6b Shops tab (as built S117 — ROADMAP P3.13c; built, PyBoy-verified, NOT yet user-tested)

`app/shops_tab.py`, model `core/shops_doc.py`; help `62_shops.md`. User (S117): "Do shops
as well while you're there."
* **Shops** (left): the game's five (Bazaar item shop, Starry Night shop, Bookstore, Rare
  item shop, gate-floor shop — edited ones orange) + the project's own ("— yours");
  **New shop… / Rename… / Delete** (project shops; Delete unbinds its shopkeepers, one
  undo step).
* **Items for sale** (right): the list (number, name, price, page when > 4) with an item
  combo (items 1-43), **Add** (after the selected row) / **Remove** / **▲ ▼**, **Original
  list** (a game shop back to vanilla); a line saying where it sells — the game's room rule
  for the five, "Sold by: room (x,y)" for NPC shopkeepers, or "⚠ nobody sells this shop
  yet". Limits enforced: 1-20 items.
* **Item prices** (below): every item 1-43 — editable Buy price (orange when changed),
  "Shops pay" (the game's sell rule), the original price, the shops that sell it.
* **Rooms tab → NPC → "Shopkeeper…"**: pick the shop + an optional greeting (two-line
  boxes; empty = the game's "Item shop. May I help you?") → a `shop` script on that NPC
  (`make_shopkeeper`; re-running it edits the same script).
* Every edit = one SnapshotCommand; the tab refreshes on undo.
* **S117b (built, NOT yet user-tested):** the shop menus in free-colour custom rooms are
  drawn in the menu palette (engine, bank $77 `ScreenPush`); the Rooms tab note above the
  canvas carries **"Sprite limit: …"** lines (`formats.sprite_budget`: a row with > 1 NPC,
  > 6 NPCs on screen — the hardware hides the rest while your party is around; user: "Just
  warning is fine for now, and Ill build around it"); help `20_npcs.md` "Sprite limits".

### 5.6c Services tab (as built S126 — ROADMAP P3.14e1; built, PyBoy-verified, NOT yet user-tested)

`app/services_tab.py`, model `core/services_doc.py` (`ServicesMixin`), compiler
`core/services.py` (PROJECT_COMPILER §2.39); help `67_services.md`. User (S126): the
menus' own lines "editable", the medal rewards "editable!!", "multiple of same instance
is fine. keep in mind ill have multiple different shops with different inventories",
"romhack postgame lines will be totally different anyways".
* **Rooms tab → NPC → "Service…"** (`app/rooms/service_dialog.py`): pick one of the seven
  (each with what it does), its **menu lines** (the game's / a line set / a new line
  set…), optional **first visit** text + the flag that remembers it (made when new); the
  NPC panel shows "Service: …". `make_service_npc` re-uses the NPC's service script.
* **Shopkeeper…** gains *Shop menu lines* (a `shop` line set).
* **Service NPCs** page: every service NPC + every shopkeeper with its own lines (room,
  where, NPC, service, lines / first visit); **Go to** / double-click →
  `navigate_to {'tab': 'rooms', …}`.
* **Menu lines** page: the line sets (New… asks the service and a name; Delete returns
  their NPCs to the game's lines); name, for (the game's NPC), **speaker**, **voice**,
  **every NPC of this kind**; who speaks it; the block's lines (# / the game's words /
  yours, orange = changed, "(re-flowed)" = the game's words wrapped for a longer
  speaker); a line editor with **Apply** / **The game's words**, the problems (red — a
  build error) and the box(es) as the game draws them (`talk_editor.render_box`, the
  game's box rule `services.text_boxes`, inserts drawn `xxxx`).
* **Medal Man** page: rewards table (medals, egg — your enemies first, then every vanilla
  row —, the line; ⏎ / ▸ for line / box breaks), **Add reward** / **Remove** / **The
  game's rewards**; refusals (not rising, > 999, > 8) come back as the model's message.
* Every edit = one SnapshotCommand; the tab refreshes on undo.

### 5.7 Progression & Flags tab

- **Flag manager**: named flags, auto-allocation from the safe pool (S117: 1,968; S124: 1,965 fixed numbers, §5.7 "As built S124" —
  the 16 vanilla spares + the extended `$1000-$179F`; EVENT_FLAGS "Extended flags"),
  usage cross-ref (who sets/reads — `all_scripts.json` branch
  following), vanilla flag map read-only with SIDEQUEST_MAP annotations.
- **Quest editor**: `progression.quests[]`/`enemies[]` (E2, built +
  user-confirmed S70) as forms: condition ladder, YES/NO offer, battle,
  on-win rewards, entry-cutscene gating; quest-EID capacity meter
  (S124: the "12-row tail" is stale — project enemies live in bank $6B since
  S101, cap EID 640). S124 decision: quests become first-class objects compiled
  to conversations / flags (ROADMAP P3.14c), not this legacy lowering.
- **Orphaned-trigger report** (§8) rendered as a checklist per preserved
  island.

**As built S124 (ROADMAP P3.14a; built, NOT yet user-tested)** — `app/flags_tab.py`
over `core/flag_index.py` (PROJECT_COMPILER §2.37). User direction (S124): "Make the
whole thing sensible to work with from the point of view of designing basically a new
game in same engine"; vanilla flags read-only ("most new flags in romhack will be
novel"); "visual clear explanatory flags". Three pages:
* **Flags** — groups: your flags (legacy quest flags marked), gates / worlds cleared,
  the Milly hook, the original game's flags your rooms check, and (on demand) every
  game flag. Counts = places in YOUR game (brackets = the game's own). The details:
  number, saved or not, Problems, *Turned ON by* / *Turned OFF by* / *Checked by — and
  what it changes* as sentences with the place and **open** (Rooms tab on the
  room / screen / state / cell with the NPC selected — `RoomsTab.open_node` takes a
  6th item = the state; the cutscene in the cutscene editor; Encounters
  `show_room_battles` / `show_gate_battles`; the gate on the Gates tab; a game room),
  *In the original game* with the game's own words around each check. Your flags:
  a note (`comment`, commits on Enter / focus-out), Rename… (every use, via the index's
  JSON paths; the number stays), Renumber… (a free number; old saves read it OFF),
  Delete (refused while used), New flag….
* **Triggers** — every "When … → …" grouped by place, filter by kind / words, copied
  game scripts optional; a double-click opens the place.
* **Problems** — grouped: undefined names (the build stops), checks never true,
  checks waiting for the ORIGINAL game's progress (the orphaned-trigger report:
  a copied game room's people branch on arena ranks / Durran / the post-game, which a
  new game never sets), flags on a game number (`$0158`), not saved, never read,
  unused.
**r2 (user: game flag `$0080` "Looks like it just randomly turns on by a million things"):**
every use = WHO (`Use.who`: "talking to Santi at (1, 6)" — the room data's triggers of the
script, named by its own lines only), WHERE (room · screen), WHEN (`Use.when`: the branch's
deciding rung; for checks the path conditions to reach them); the details show ONE entry per
`Use.group` (a script / a place) with its branches folded ("in 9 of its branches: when …"),
and an **In short** line (`FlagIndex.summary`).
**r3 (user: "this should open a SIDE WINDOW PANEL on the RIGHT to show the specific NPC in
the specific room … Rather than moving to a totally different tab. It should also allow
naming all NPCs … and carry that through, both vanilla and in romhack"; "You dont actually
show the correct NPC"):** `app/place_panel.py` `PlacePanel` on the right of the tab (a
splitter; hidden until used, ✕ hides it). **show** (the details), a double-click (Triggers,
Problems) → the place: the room screen rendered at 2× IN THE PLACE'S STATE with every NPC's
sprite (hidden ones faded) and your names as tags, the place's cell outlined yellow, the
picked NPC dotted cyan; ◀ ▶ through `Use.places` of the entry's branches; a Room-state box
(the same NPC stays picked when it stands there in the other state); the NPC list (game
order, spots greyed); **Name this NPC…** (click on the picture or the list; one
SnapshotCommand, `Document.name_npc`); **Open in the Rooms tab** / Open the cutscene /
battles / gate (`navigate`). Fixed with it: `MainWindow.navigate_to` 'game' passes screen /
state / cell, `RoomsTab.open_node` takes them for a game room and `_go_end` keeps the state
(it forced state 0), the NPC there is selected. Names everywhere: the Rooms tab canvas draws
a name tag over a named NPC (`RoomCanvas._npc_names`, `npc_tags`) and its NPC section has a
**name** row with **Name…** (game rooms too — read-only otherwise); the Cutscenes tab's
storyboard actors take your name before the speaker's (`_actors`; `ProjectCatalogue.npcs`
returns `actor`); the index's sentences (`_game_who`, `Place.event`).
Fixed numbers (S124): every named flag carries its number in project.json (migration
on open = the compiler's own numbers, so nothing moves); new flags never get `$0158`.
**Design target (user S124: "the current project is purely POC I will start a new one for
actual romhack … It wont have any copies of vanilla rooms or random custom rooms with no
exits"):** the real project has only its own rooms, all connected to its hub. In it the
"original game's flags" group and the `game_only` problem stay empty unless the author
picks a game flag by mistake — they are a guard, not a workflow; every P3.14 part is
designed and tested on such a project (no copied rooms, no vanilla destinations).

### 5.8 World tab

**v0 as built S98 (`app/world_tab.py`, `core/world.py`; read-only):** nodes
= custom rooms (first-screen thumbnail) + the vanilla rooms they connect to;
edges = two-way doors (teal, both arrowheads), one-way exits (red), vanilla
doors re-pointed one-way (magenta), script warps from talk `move` /
`map_transition` ops (dashed yellow); **whole vanilla world** adds every
vanilla exit (98 rooms / 206 links, ~0.8 s). Deterministic spring layout
(seed 98), **Re-layout**, drag nodes (not saved), Ctrl+wheel zoom, hover =
what the link is, double-click = open the room in the Rooms tab. Rebuilt on
every structural change.

**Hub (S125, ROADMAP P3.14d1; user: "Make a single room be HUB but … transferrable upon
flag"; built S125, NOT yet user-tested):** the **Hub** box at the top of the World tab's
left panel (`world_tab.HubBox`): the rules as sentences ("while post_game is ON → the
Castle …", "otherwise → HUB HALL ($74), screen 0 (4,5)", a grey last line "otherwise →
the Castle" when nothing is unconditional), **Add rule… / Edit… / Remove / ▲ ▼**, **Open
room**, **Add the arrival scenes** (three entry scenes on the rule's screen: loss + heal,
WarpWing + heal, home), the problems in red (`Document.hub_problems`). `HubRuleDialog`:
the conditions (`encounters_tab.FlagTerms`, + New named flag…), the room (the Castle
first) and the arrival cell clicked on the room picture (`CellPicker`; walls refused).
A new conditional rule is inserted before a final unconditional one. Elsewhere: the
cutscene editor's **Arrival home… ▾** (entry scenes; the reasons, a note when the room
is not a hub), the **Heal the party** step, "home — the hub (World tab)" first in the
Warp destinations (the form then shows where home is now); the conversation dialog's
**Home — the hub** destination (screen / cell greyed) for Move and the helper (the "at
the Castle" event applies when home is the Castle) and the Heal step; the Rooms canvas
**H** marker (gold) at a rule's cell; the Progression & Flags tab's hub triggers open the
Hub box on that rule (`navigate_to {'tab': 'worlds', 'hub': n}`). Headless model:
`editor2/core/hub_doc.py` (`HubMixin`). Tests: test_compiler `test_hub_s125` (doc block),
test_app `s125_hub`.

*Target:* room/warp graph (custom + vanilla islands): nodes = rooms (thumbnail
renders), edges = exits/warps/`vanilla_exit_extensions`/script
teleports; the bifurcation edit (dresser repoint) is performed HERE
(M2R). Gate-network authoring (which gates exist, unlock order, hub topology)
lives in the **Gates tab** (§5.1b) once the E4 schema [G-F] lands —
until then World shows vanilla gates read-only and custom gate
entrances as ordinary exits.

### 5.9 Balance tab (NEW — the simulator as a product feature)

The S78-S89 simulator is exact where validated (damage 698/698, battle
loop 6614/0, AI 26/26 + rules 240/240, obedience 889/889, pacing
PIT-uniform). Surface it:
- **TTK/pacing sweeps** (`sweep_ttk.py`, `pacing.py`): expected
  rounds/TTK envelopes per encounter pool, per gate, against the
  author's current party assumptions; red/green vs target pacing bands
  (`profile_check --ttk`).
- **What-if preview**: select a monster/skill edit → re-run the affected
  sweeps before Build; show the delta.
- **Obedience curves**: WLD × tactic → obey% (the exact S87 model), so
  "why won't my monster listen" is a graph, not a mystery.
- **Guardrail**: every panel states its validation corpus; anything
  unvalidated (the §15.9 residuals) is greyed out, not guessed — the §7
  differential-validation rule applies to the UI too.

### 5.10 Build & Play

Build (deterministic, budget bars, validator gate), Play in SameBoy
(`.sym` loaded), embedded PyBoy "play this room/cutscene" [G-E], and the
verify_integrity discipline surfaced (the clean-build check stays a
first-class button).

---

**As built S119 — the cutscene EDITOR (ROADMAP P3.8 parts B / c / d; built, NOT yet
user-tested).** User (S119): "Should be specific NPCs. Design should be visual, ie you
should indicate which NPC faces where, moves where, and operates by tile, etc. Custom
cutscenes should be previewable. Everything should be in tiles." + on the audit: step
list plus room picture "of course", appear / disappear for NPCs that come out of nowhere,
"always in tiles", triggers = entering the room / talking / entering + a flag ON …, vanilla
scenes will not be reused ("all romhack scenes will be custom") but all four parts asked.
Data: `custom.rooms[].cutscenes[]` + `actor` names / `cast` NPCs (PROJECT_COMPILER §2.33);
model + compiler `core/cutscene_build.py` (one pass: ops + the per-step state + a frame
timeline); edits `core/cutscene_doc.py`; GUI `app/cutscene_editor.py` in the Cutscenes tab
(a QStackedWidget page; "Your cutscenes (edit)" tops the tree, ＋ New cutscene… dialog:
name / room / screen / trigger).

* **Header:** name, room · screen · id, Duplicate / Delete; *Plays when* (entering the
  room — this screen / talking to <named NPC> / examining / stepping on a tile + Pick
  tile), *Only when flags… ▾* (ON / OFF lists, New flag…), *Plays once* (makes the flag
  `<id>_seen`); *Player starts at* (entry; prefilled from a door / redirect that leads
  to the screen — `cutscene_doc.default_player_start`).
* **Left:** the step tree (branches as *If YES / If NO / Then / Otherwise* rows, colour =
  kind, the model's notes), ＋ Add step ▾ (grouped: Actors / Text / Time / Screen / Sound
  / Story), ▲ ▼ ⧉ ✕, ＋ Cast member… (sprite picker → name → the clicked tile), Name an
  NPC….
* **Middle — the stage:** the screen rendered live ×3 with a tile grid; every named
  actor drawn with its real sprite in its facing (`extracted/npc_facing_sprites`, NEW
  S119: every sprite id in four facings + step frames captured from the game, transparent
  — tools/extract_npc_facings.py), a facing wedge, a name tag (*?* = place not known),
  faded = hidden; unnamed NPCs drawn grey ("NPC n"); the selected step's movement as
  arrows (the walk's L path, an arc for hops / flights, a ring for appear / vanish), a
  dashed box for a tile piece, its text in a box. Drag an actor onto a tile = a walk (or
  moves the selected walk / landing); right-click an actor = face (a direction / toward
  someone), appear / disappear (instant / flicker), every program of its kind, fly,
  rename, move / remove a cast member; right-click a tile = name the NPC there, new cast
  member here, "<selected> walks here", change the tiles here; *Room state shown*.
  **▶ Preview** = the model animated (walk 3 px / 4 frames, programs / flights with their
  measured frames and an arc, texts per box, shake / fade / flash), a slider scrubs,
  *answer YES / NO* picks the branch; **▶ Play in the game** = save + build (when the build
  is older than the project) then the S118 Playback window with the scene's recipe
  (`CutscenesTab.scene_ref`: the combined script's head for this scene — `<prefix>_go` or
  the previous scene's `_skip` label —, path flags, `player_start` as the arrival).
  Problems (red errors / orange warnings) from the same model, live.
* **Right — the step form:** per kind (actor pickers, tile x / y + *Pick on the picture*,
  path order, together / run / backwards, facing or toward, how, programs filtered for
  player / NPC, flight + landing + length / curve, frames, songs / sounds from
  `sound_catalog.json` with ▶ Hear it (the game's own engine), shake / fade / flash, items /
  enemies, the tile piece's size + "Look like screen k, state n", battle enemies, warp).
  Text boxes typed with an empty line between boxes, checked as you type
  (`textenc.check_boxes`).
* **Part c — copied rooms' game scripts:** under *Your rooms*, the storyboard of a copy's
  own op script gets **Edit step… / Insert step before… / Delete step** (`OpDialog`: any of
  the 102 opcodes with its doc, parameters as numbers / symbols / `@label`, a live
  sentence of what it does); `_op_target` maps a storyboard step (word position) to its op
  (checked over every step of the user's GreatTree copy: 506 / 506).
* **Part d — tile patches:** the *Change tiles* step + copies' own patches
  (PROJECT_COMPILER §2.33 "patch_data"; BANK04 "Tile patches").

**S119b — picking an NPC that has no name (user 2026-10-04 19:23: "Why cant I select
npc in a custom room when creating new cutscene?"):** the actor lists held only named
NPCs, so a screen whose NPCs nobody had named offered nothing to talk to. Every actor
list (talk trigger, New cutscene → *Talking to*, the step forms' *Who* / *toward*) now
ends with the screen's unnamed NPCs ("NPC 1 at (7, 3) — no name yet"); the item holds a
token `#<state>:<n>` and `commit()` resolves tokens inside the SAME SnapshotCommand that
writes the scene (`cutscene_doc.resolve_tokens` → `ensure_named`: *Shopkeeper* for a
`shop` script, else *NPC n*, unique on the screen). One undo step undoes both.
**S119b crash fix (user's Mac: "Segmentation fault: 11"):** `StepForm._emit` no longer
emits synchronously — the edit `(path, step)` is queued and flushed by
`QTimer.singleShot(0)`, because the commit's reload rebuilds the form and deletes the very
widget whose signal is running; `_trigger_changed` / `_player_start_changed` use
`_later_commit`, the form's *New flag…* button is deferred too. `_form_changed` writes to
the queued path (skipped when the step there changed kind).
**S119b typing (user: "Why is text box so slow to type in?" — 1.1 s per key on their
project, the cursor reset per key):** text boxes store after a 0.7 s pause / on focus-out
(`StepForm._text`; pending stores are flushed before the form shows another step); a
commit whose step equals the shown one keeps the form when its list context
(`_form_context`: actors, unnamed NPCs, flags, rooms) is unchanged; spin boxes use
`setKeyboardTracking(False)`; the Cutscenes tab refreshes only "Your cutscenes" while the
editor page is shown (`_refresh_mine`, the catalogue re-read on returning to the viewer —
`_page_changed`); the Import tab skips its palette re-fit unless the rooms (cutscenes
excluded) changed. Measured: 4 ms per key, one ~0.4 s commit per pause (the undo snapshot
and the Rooms tab's refill remain).
**S119b — the user's four (2026-10-04 21:15):** (1) "Why cant I copy paste build log?" —
the read-only log was mouse-selectable only: + keyboard selection (⌘A / ⌘C), right-click
*Copy all* / *Clear*, and a failed build opens a dialog with the error (*Copy error*,
the traceback as details). (2) "Why not preview message using in-game boxes … already
implemented in NPC conversations??" — every cutscene text field (say, ask, give
got / full) is `talk_editor.BoxList(vertical=True)`: one editor per box with the game's
font / frame / red overflow, Fit / Fit all / + Add box (stored after a pause; flushed
before preview, Play, Save — `StepForm.flush`); the form column ≥ 440 px. (3) "Your help
tab is cut off for cutscenes" — a raw `<selected actor>` (KEY_LESSONS S119b). (4) "Can you
not hover or explain what is e.g. 'wait until everyone stops'?" — `STEP_HELP` (every step
kind: under the form title, on the Add step menu, on the step list rows), `FIELD_HELP` /
`CHECK_HELP` (every form row), header hover text (`_header_tips`, the trigger items).

Verification: test_compiler `test_cutscenes_s119` (ops, wiring, errors, patch bytes,
the model); test_app `s119_cutscene_editor` (name / cast / new scene, steps incl. a drag,
stage arrows, preview, op mapping, undo); PyBoy on the user's save — the demo "Stage Hall"
(PROJECT_STATE S119): four scenes through the real door, every end position == the model.

## 6. Vanilla editability — CLONE-TO-CUSTOM + Layer A-lite (v2.1, user decision S90)

Two mechanisms, matched to the two kinds of vanilla content. In-place
vanilla editing shrinks to almost nothing.

### 6.1 Rooms & scripts: clone-to-custom (the fork mechanism)

"Edit the arena" means: **extract the vanilla room into a custom-room
clone** (new mapID ≥`$6B`; layouts/attrs/NPCs/exits decompiled into a
full project.json object; scripts decompiled via the proven
decompiler), **repoint the entrances** to the clone
(`vanilla_exit_extensions` / exit edits — built), and edit the clone
freely in the custom pipeline where EVERYTHING is already authorable —
add screens (custom multi-screen proven v28), add states, add NPCs.
Vanilla stays byte-untouched underneath (postgame-safe, and the clean
build stays trivially byte-perfect). Clone custom→custom is the same
operation = **copy-paste rooms for free** (user spec: "clone arena and
fuff about, original still there").

Disentangling is explicit, not accidental: the clone's decompiled
scripts carry their vanilla story-flag reads into the open, where the
**orphaned-trigger validator** lists each one for satisfy-or-strip.
Per-island caveat: mode-manager code may key on literal mapIDs (arena
battle flow is the suspect); the first clone session for an island runs
that audit (= the preserved-systems audit, one island at a time).
Backend: [G-J] the clone extractor (`extract_room.py` → project.json;
formats fully decoded, all 107 rooms render, all 732 scripts
decompile).

### 6.2 Data tables: Layer A-lite (unchanged from v2)

Vanilla **data tables** (monsters, skills, breeding, encounters, arena
rows, items/shops once decoded) become editable via `gamedata.*` →
same-size compiler-emitted patches; readers ported from
`randomizer/romdata.py` (which already proves read+rewrite). Regression:
an unedited `gamedata` section emits ZERO byte diffs. [G-D]

**As built S103 (ROADMAP P3.9, backend only):** `gamedata` = sparse overrides
(`monsters`, `enemies`, `encounters`, `skills` (mp / learn / record),
`exp_curves`, `growth_curves`, `breeding.family` / `.special`, `boss_joins`) →
twelve same-size `@BUILD_PROJECT` regions (banks $01/$03/$06/$07/$12/$13/
$14/$16/$4D/$54/$69); vanilla rows from `extracted/gamedata_vanilla.json`, so
an empty section is the ROM (per-table regression in test_compiler, `--rom`
against the original ROM). Coherence handled by the compiler: library recipe
text (Set 1, rewritten in place) and library tabs follow the effective
family bytes; Set 2 / Set 3 are warnings. The GUI tabs (P3.10 Monsters, P3.11
Skills, P3.12 Breeding, P3.13 Encounters) sit on `Project.gamedata()` /
`editor2/core/gamedata.py`. PROJECT_COMPILER §2.20.

### 6.3 What remains of "Layer A proper" / full extraction

- In-place vanilla edits still needed: **exit repoints** (built) and the
  **M2R bifurcation** (dresser repoint + Terry-intro strip) — both tiny.
- **Full extraction** (`extract.py`, all-107-rooms byte-perfect
  round-trip) is DEMOTED to a contingency: clone-to-custom delivers
  editable vanilla content without it. Revisit only if a use case ever
  needs the whole vanilla world simultaneously editable in place.

### 6.4 Capacity headroom + the ROM-expansion contingency (S90 audit)

Current headroom vs the ~30-80-room campaign (all figures from
PROJECT_STATE/owning docs): **11 unallocated banks = 176 KB** (+
reserved sprite-overflow order + bank-$60 multi-bank spill A′3 when
needed); **~128 practical free mapIDs** (`$6B..$EA`, S66 audit) — clones
included, not a constraint; **flags** = 32 truly-safe vanilla-range +
**24 KB persistent SRAM banks 1-3** (S69 expansion, USER-TESTED; needs
the E3 b2 schema before first use); **19 custom species slots**
(221-239; S105 G3 — 240+ are impossible); **quest EIDs** 519+ (12-row tail, extendable by table move);
**95 song slots**. Verdict: fork-first is affordable for the whole
campaign at current scope.

**ROM expansion 2→4 MB — ASSESSED, NOT BUILT, and no prior session
claimed it** (S90 grep; the expanded thing is SRAM). Feasibility read:
MBC5 addresses 256+ banks through the same 8-bit ROMB0 register the ROM
already uses, so banks `$80-$FF` need the header size byte, link layout,
and an audit for any code that stores/compares bank numbers assuming
<`$80` (the S69 RAMB quadrant convention — the one known bank-derived
computation — is already pinned dead). One audit+flip session IF ever
needed; nothing in the current campaign scope forces it. Banked as a
contingency box (ROADMAP).

## 7. In-editor preview — simulate vs emulate (carried; still binding)

**Principle (v1, amended S78, unchanged in v2):** the editor SIMULATES
only what is table-derived and validated; EMULATES everything else.
- **Tier 1 (static simulation, trustworthy)**: room canvas WYSIWYG
  (renderer built S72, emulator-validated), dialogue preview, NPC
  placement, script/cutscene storyboard (symbolic control-flow only).
  Every Tier-1 renderer is validated once against emulator captures
  before being trusted (the `derive_room_palette.py` 30/30 pattern).
- **Tier 2 (embedded emulation)**: the PyBoy widget — Build → cached
  post-boot savestate → warp → play, full fidelity [G-E]; SameBoy
  remains external ground truth + debugger.
- **Combat is the amended exception (S78)**: simulation is allowed ONLY
  under differential validation; a subsystem without a passing corpus is
  forbidden in the Balance tab (greyed out, §5.9).
- **Never simulate** (unchanged): gate generation, audio timing,
  camera/scroll, mode transitions, save/SRAM behavior.

## 8. LLM-debuggable builds — the manifest (carried; largely built)

`build/manifest.json` (symbol→bank:addr, mapID→row, text/script addrs,
per-bank budget vs allocation, flag map, content hash) + `.sym`
passthrough + deterministic builds + validation-as-errors pointing at
the offending project.json FIELD (catalog: PROJECT_COMPILER §10, S76
coherence sets, S77 randomizer-derived validations, S74 skill
invariants) + **orphaned-trigger detection** (a flag a preserved island
reads but nothing sets after stripping) + the SameBoy warp helper. The
UI obligation added in v2: every validator failure and every manifest
row is click-navigable (§5.0).

## 9. Backend gap register (NEW — what the UI forces; each is/maps to a ROADMAP box)

| Gap | What | Status / where |
|-----|------|----------------|
| G-A | Bank `$64` (layouts/attr) + `$67` (combined tilesets) emission folded behind project.json (today tool-owned, referenced by {bank,entry}) | ✅ CLOSED S92 (`custom.layouts[]` / `custom.tilesets[]`, PROJECT_COMPILER §2.10); painted by the S93 canvas |
| G-B | NPC sprite-id catalog | ✅ CLOSED S91: `extracted/npc_sprite_catalog.json` + sheet + per-id crops (`npc_field_sprites/`), tools/dump_npc_sprite_catalog.py; classes/names hand-curated in npc_names.json. No id crashes ($11-crash was custom-room context); $23 = boss-composite fragment; aliases $4E/$4F/$F0-$F3 → $00. ROOM_DATA_FORMAT S91 section owns the facts |
| G-C | Encounters #2 — custom monster pools in a free bank | ✅ CLOSED S114 (test ROM USER-CONFIRMED 2026-10-03 09:52 ("Looks good. Give editor files")): the project's own lists 128-255 in bank $76, chosen by `EncResolve` behind a same-size bank $01 fork (PROJECT_COMPILER §2.30; DATA_STRUCTURES "Encounter list choice (S114)") |
| G-D | Layer A-lite `gamedata` emitters + readers (monsters/skills/breeding/encounters; port randomizer `romdata.py`) | ROADMAP P3.9 — **CLOSED S103** (backend; GUI = P3.10-P3.13) |
| G-E | Embedded PyBoy preview widget (cached savestate → warp → Qt blit + input) | ROADMAP P3.4 — the cutscene Playback window (S118, §5.1d) is this widget for scenes (cached base state, recipe, Qt blit, sound, keys); "play this room" from the Rooms tab is still open |
| G-F | E4 gate-network / world-hub schema | ROADMAP Phase E (design item; World tab ships without it). S115: gate NUMBERS beyond 32 exist (NG1 — `custom.gates[]` 32-95, gate-entrance exits); the network / unlock half stays open (ARC NG NG2 / NG3) |
| G-G | First-class `states[]` (step-counter variants) in the custom-room schema | ✅ CLOSED: schema/emitter S92 (PROJECT_COMPILER §2.10); GUI state switcher + add/duplicate/own-layout/remove S93 (ROADMAP P3.3) |
| G-H | Cutscene storyboard model over compile/decompile_script | 🟢 read + display + play BUILT S118 (§5.1d; `editor2/core/cutscenes.py` / `script_ops.py` / `playback.py`), NOT yet user-tested; authoring = ROADMAP P3.8 part B |
| G-I | Music audition harness (PyBoy play-song) | ✅ CLOSED S116 (built, NOT yet user-tested) — not PyBoy: the game's own sequencer on the editor's SM83 interpreter + a synth (SOUND_SYSTEM §9), streamed in the Music tab (§5.6 "As built S116") |
| G-J | Clone-to-custom room extractor (vanilla room → full project.json custom clone + entrance repoint; per-island literal-mapID audit) | ROADMAP P3.2b (v2.1) — the fork mechanism |
| G-K | E8 shops: stock/price table decode + `gamedata.shops` + shopkeeper NPC surface | ROADMAP P3.13c (v2.1; promoted from Phase E) |
| G-L | E1→E2 arena authoring wiring (tiers×matches×slots grid over rows 224-304) | ROADMAP P3.10b (v2.1; promoted from Phase E) |
| G-M | CAPACITIES reference | ✅ CLOSED S91 (core): `extracted/capacities.json` (hand-compiled, evidence per entry); NPCs/screen = 8 hard (9th corrupts script state, measured) + a distinct-sprite-sheet VRAM budget (order-filled, blanks on overflow); screens/room engine=16, vanilla max 12-declared/9-valid, custom schema=8. Residual boxes live in the file's `_deferred_measurement_boxes` (E6 text budget, gate slots, per-sheet tile counts, 4x4 schema extension) |
| G-N | AI ban-list mechanism (knows-it-never-casts-it option-list filter) — OPTIONAL | ROADMAP P3.11b (v2.1, optional) |
| G-O | Flag-keyed encounter-pool variants (bank-$71 RoomEncTable resolver extension) | ✅ CLOSED S114 (test ROM USER-CONFIRMED 2026-10-03 09:52 ("Looks good. Give editor files")) — in bank $76 rather than $71: rooms' and gates' variants (flag terms, first match wins) |
| G-P | Family-icon editor slot pipeline (+ the custom-sprite background white-vs-cream defect — RESOLVED, user S106 r2 "background colour is perfect") — **built S107** (§5.2a) | ROADMAP P3.10 part 2c |

## 10. Milestones v2 (→ ROADMAP Phase 3, re-sequenced S90)

M0 keystone ✅ S42 · M1 headless backend ✅ S53+ · M3 walking skeleton ✅
S72 (out of order, deliberately) · **M2 (bifurcation) re-slotted as
M2R** after the canvas exists — repointing the dresser is a World-tab
edit authored IN the editor; with clone-to-custom (§6.1) it is one of
the only in-place vanilla edits left (§6.3).

The one-session boxes (acceptance tests live in ROADMAP Phase 3 — that
list is canonical; summary, v2.1 insertions starred): **P3.0* capacities
reference** → P3.1 sprite catalog → P3.2 $64/$67 fold → **P3.2b* clone-
to-custom extractor (arena first)** → P3.3 room canvas v1 (paint +
states + screen paging) → P3.4 embedded PyBoy → P3.5 NPC inspector →
P3.6 dialogue editor → P3.7 triggers/exits + World graph v0 →
**P3.7b* Gates tab** → P3.8 cutscene storyboard + playback → P3.9 Layer
A-lite gamedata backend → P3.10 Monsters tab (+ family icons, follower
visualizer, bg-defect fix) → **P3.10b* Arena editor** → P3.11 Skills
tab → **P3.11b* AI ban-list (optional)** → P3.12 Breeding edit+sim →
P3.13 Encounters (+ flag-keyed variants) + Music tabs → **P3.13c*
Shops (E8)** → P3.14 Progression/Flags tab (+ Triggers-as-sentences) →
P3.15 Balance tab → P3.16 M2R bifurcation → P3.17 packaging. Order is
dependency-driven, not sacred; a session may pick any box whose gap
tags are closed.

## 11. Superseded v1 content ledger (what's gone and why)

- **v1 §8 reserved-bank table** — superseded by reality: PROJECT_STATE
  "Bank allocation" is the single source ($6A=new-species info,
  $69=breeding, $71=dispatch, $72=skills, $73=farm, $74=songs,
  $7E/$7F+=sprites; 11 banks unallocated). The v1 table predated all of
  it. (DOC_AUDIT S90 addendum.)
- **v1 §7 DWM2 sprite-pipeline sketch** — superseded by the BUILT
  GFX-1..4 stack (codec, palettes, overflow banks, follower layouts,
  8-table repoint — MONSTER_DATA). Its two "flagged confirmations" were
  both answered (pointer table repointable ✅; dimensions = the layout
  library ✅).
- **v1 §5 extract-first gating of vanilla edits** — replaced by §6's
  Layer A-lite split.
- **v1 milestone numbering M4-M6** — replaced by §10 / ROADMAP P3.x.
- v1 module→primitive table — subsumed by §5's per-tab backing citations.

---

## Appendix — Skill editing surface (S74; carried verbatim)

Everything an editor needs to tune existing custom skills or scaffold new
ones, with the source-of-truth location for each knob. Two addressing
modes: **source labels** (edit `patches/*.asm`, rebuild — addresses
resolve via `game.sym`) and **built-ROM offsets** (for direct-poke
tooling; regenerate via the named dump tools after any rebuild, never
hardcode).

| Knob | Where (label, bank) | Format / notes |
|---|---|---|
| Damage per tier | `QuakePowerTable` (bank `$72`) | `(min, range)` byte pairs indexed `(id-$E5)*2`; damage = min + RNG mod (range+1); caster's own side takes 1/3 (phase-keyed in `SkillQuake`) |
| MP cost | `CustomMPCostTable` (bank `$07`) AND record byte +4 (`CustomRecord_*`, bank `$54`) | MUST stay in sync — menu shows one, battle spends the other |
| Learn level + prereq chain | `CustomLearnReqTable2` (bank `$06`) | 18 B rows: +0 level, +1..+12 six u16 stat reqs, +13..+17 prereq ids ($FF pad). Prereq = vanilla EVOLVE (old tier replaced on learn). The level ALSO gates cast-time validity per actor (msg `$1D` below it) |
| Skill name | `SkillNamePtrTable` → `SkillName_*` (bank `$41`) | pooled, pointer-repointable |
| SKIL-menu description | desc table rows + `SkillDescPtr_*` (bank `$56`) | 3 lines ≤18 chars, `$F1` breaks, `$F0` end; strings funded from the bank's trailing nop pad |
| Announce line | `CustomMsgPtrTable[id-$DE]` → `CustomMsg_*` (bank `$4c`) | 2 lines max (18 chars each) for gate/`$FD` renders |
| Ally-crossover banner | `CustomMsg_QuakeAllies` (bank `$4c`) | same 2-line cap |
| Fly-dodge line | `CustomMsg_QuakeFlew` (bank `$4c`) | `F9 00` = the beat's subject name; party-side only by design (`LoadB4c_MaybeFlew` condition) |
| Shake burst count | `(id-$E5)+1` in `QuakeAnimHold72` (bank `$72`) | burst length `$10` frames, gap `$0C` — both literals in `QuakeShakeSeq` |
| Rumble SFX | `$68` literal in `QuakeAnimHold72` | any looping SE works; SFX `$00` is the universal stopper |
| Cast animation | `GetAnimPresentId` (bank `$5f`): quiet id `$12`; other presentation via `CustomProxyTable[id-$DE]` | quiet = routine `$0D` in all three tables `$58dd/$59c3/$5aa9` (see `extracted/battle_animations.json` for every skill's indices) |
| Flying flag (per species) | ROM offsets in `extracted/flying_flags.json` (`tools/dump_flying_flags.py`) | battle-side mirror: `$db8b[slot]` bit 4 — what the sweep/handler/fork actually test |
| Skill charmap (all strings above) | a-z=`$3E`+, A-Z=`$24`+, space=`$62`, `!`=`$63`, newline=`$F1`, close/end=`$EC $F0` | page-ender `FC 10 EC F2` is ENGINE-driven messages only |

**Editor-safety invariants** (violating any of these bricks the battle
loop — each is a hard validator): keep the MP pair in sync; descriptions
within the 3×18 + terminator budget; announce/banner within 2×18; prereq
ids must exist; animation ids must exist in all three presentation
tables; custom ids stay within the de-aliased range wired through
DispatchBoundsStub ($E6+ AI-commit guard, S84).

**S110 corrections to the table above (kept verbatim otherwise):** the bank-$5F
resolver is `GetPresentId` (not "GetAnimPresentId"); since S110 it also reads a
per-skill `StockPresentTable` for ids < $DE, and the cast SFX of the bank-$55 tables
has its own door `SfxPresentId` ($55:$4061) — BATTLE_SKILL_SYSTEM §11.8. "MP cost …
menu shows one, battle spends the other": the BATTLE menu also checks the record +4
copy (afford check, bank $50); only the FIELD SKIL menu shows / charges the `$07` table
(BATTLE_SKILL_SYSTEM §7 census).
