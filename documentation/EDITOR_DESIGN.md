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
  (the mashup pipeline's animated-tile registry, already avoided by
  build_combined_tileset).
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
  markers (thumbnails once the sprite catalog lands [G-B]) · spawn/exit
  markers · encounter badge · walkability (seeded from the decoded tile
  behavior classes, GATE_GENERATION §5.1).
- **Tile paint**: pick from the room's tileset strip; rectangle/fill;
  undo via QUndoStack. Requires layout emission behind project.json
  [G-A] (today bank $64 is tool-owned).

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
   ROM font tiles, live 18-cell wrap, auto-DTE, auto page-split, YES/NO
   choice wiring with branch preview (built: `core/textenc.py` +
   `dwm/text.py`; preview rendering = Tier-1, §7).
5. **Triggers** — interact entries, spawn points, exits (custom↔custom
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

### 5.2 Monsters tab

Species list: 221 vanilla + custom (224+; Gorbunok proven end-to-end).
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
- **KNOWN DEFECT (v2.1, user-reported S90)**: custom sprite BACKGROUND
  renders pure white where vanilla's is slightly creamy — near-certainly
  the import pipeline quantizing to `$7FFF` instead of vanilla's exact
  background RGB555. Measurement task in [G-P]: sample vanilla's value,
  identify whether the battle-palette path, follower path, or both are
  affected (follower OBJ idx0 is hardware-transparent, so the battle
  `MonsterBattlePalettes` path is the prime suspect), fix the constant.
  Logged in PROJECT_STATE Open defects.
- Custom-species creation = the Phase N pipeline behind a "New species"
  wizard (ids 224+; G3 schema fold is the open box). Capacity meter:
  slots used / 32.

### 5.2b Arena tab-section (v2.1 — user spec S90; lives under Gates or Monsters, final placement at build time)

Rosters are FORMULA-addressed enemy-stats rows (E1 decoded,
HW-verified: `EID = $E0 + 9*group + 3*match + slot`, rows 224-304 +
King 481-483) — so the editor surface is a **tiers × matches × slots
grid** editing those rows directly (stats, skills, `ai_weights` per
enemy) through Layer A-lite [G-D], plus the victory cascade / `$CAB4`
tier flags surfaced read-only from the decoded Arena Lobby scr0.
Bracket SHAPE changes (more tiers/matches) = patching the formula
constants — an expert-mode knob, flagged, not v1 UI. [G-L wires the
authoring schema.]

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

### 5.5 Encounters tab

Cross-room/gate view of pools: which species at which levels where, per
gate/floor; per-row threat parity vs the author's stat edits
(`audit_threat.py` logic as a service); jump to any room's Encounters
sub-tab. Needs custom pools [G-C]; per-room enable/rate already built.

### 5.6 Music tab

Song library manager: vanilla songs, the DWM2 31-subsong catalog, **MIDI
import** (`midi_to_song.py`, built S64) with conversion warnings; the
95-slot bank `$74` budget bar; the room-assignment matrix
(`music.room_defaults` + per-room overrides); audition in PyBoy [G-I].
Open engine boxes stay listed in ROADMAP (InitBGM channel-count ext).

### 5.7 Progression & Flags tab

- **Flag manager**: named flags, auto-allocation from the safe pool,
  usage cross-ref (who sets/reads — `all_scripts.json` branch
  following), vanilla flag map read-only with SIDEQUEST_MAP annotations.
- **Quest editor**: `progression.quests[]`/`enemies[]` (E2, built +
  user-confirmed S70) as forms: condition ladder, YES/NO offer, battle,
  on-win rewards, entry-cutscene gating; quest-EID capacity meter
  (12-row tail).
- **Orphaned-trigger report** (§8) rendered as a checklist per preserved
  island.

### 5.8 World tab

Room/warp graph (custom + vanilla islands): nodes = rooms (thumbnail
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
the E3 b2 schema before first use); **32 custom species slots**
(224-255); **quest EIDs** 519+ (12-row tail, extendable by table move);
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
| G-A | Bank `$64` (layouts/attr) + `$67` (combined tilesets) emission folded behind project.json (today tool-owned, referenced by {bank,entry}) | ROADMAP P3.2 — the canvas prerequisite; flagged since S72 |
| G-B | NPC sprite-id catalog | ✅ CLOSED S91: `extracted/npc_sprite_catalog.json` + sheet + per-id crops (`npc_field_sprites/`), tools/dump_npc_sprite_catalog.py; classes/names hand-curated in npc_names.json. No id crashes ($11-crash was custom-room context); $23 = boss-composite fragment; aliases $4E/$4F/$F0-$F3 → $00. ROOM_DATA_FORMAT S91 section owns the facts |
| G-C | Encounters #2 — custom monster pools in a free bank | ROADMAP P3.13a (pre-existing Phase-2 box, re-slotted) |
| G-D | Layer A-lite `gamedata` emitters + readers (monsters/skills/breeding/encounters; port randomizer `romdata.py`) | ROADMAP P3.9 (new) |
| G-E | Embedded PyBoy preview widget (cached savestate → warp → Qt blit + input) | ROADMAP P3.4 (pre-existing box, re-slotted) |
| G-F | E4 gate-network / world-hub schema | ROADMAP Phase E (design item; World tab ships without it) |
| G-G | First-class `states[]` (step-counter variants) in the custom-room schema | ROADMAP P3.3 backend half (new) |
| G-H | Cutscene storyboard model over compile/decompile_script | ROADMAP P3.8 (new) |
| G-I | Music audition harness (PyBoy play-song) | ROADMAP P3.13b sub-item (new) |
| G-J | Clone-to-custom room extractor (vanilla room → full project.json custom clone + entrance repoint; per-island literal-mapID audit) | ROADMAP P3.2b (v2.1) — the fork mechanism |
| G-K | E8 shops: stock/price table decode + `gamedata.shops` + shopkeeper NPC surface | ROADMAP P3.13c (v2.1; promoted from Phase E) |
| G-L | E1→E2 arena authoring wiring (tiers×matches×slots grid over rows 224-304) | ROADMAP P3.10b (v2.1; promoted from Phase E) |
| G-M | CAPACITIES reference | ✅ CLOSED S91 (core): `extracted/capacities.json` (hand-compiled, evidence per entry); NPCs/screen = 8 hard (9th corrupts script state, measured) + a distinct-sprite-sheet VRAM budget (order-filled, blanks on overflow); screens/room engine=16, vanilla max 12-declared/9-valid, custom schema=8. Residual boxes live in the file's `_deferred_measurement_boxes` (E6 text budget, gate slots, per-sheet tile counts, 4x4 schema extension) |
| G-N | AI ban-list mechanism (knows-it-never-casts-it option-list filter) — OPTIONAL | ROADMAP P3.11b (v2.1, optional) |
| G-O | Flag-keyed encounter-pool variants (bank-$71 RoomEncTable resolver extension) | ROADMAP P3.13a acceptance (v2.1) |
| G-P | Family-icon editor slot pipeline + the custom-sprite background white-vs-cream fix (sample vanilla RGB555, locate affected path) | ROADMAP P3.10 additions (v2.1); defect in PROJECT_STATE |

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
