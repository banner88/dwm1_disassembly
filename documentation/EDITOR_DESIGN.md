# EDITOR DESIGN — Native macOS App

## Verdict on the legacy editor
`editor/editor.py` (Streamlit, 175 KB single file, byte-patches a ROM copy)
is frozen: predates the patch system, edits bytes instead of generating
buildable source, and a browser-rerun framework is the wrong shape for a
canvas-heavy tile editor. Reference only.

## Decision: PySide6 (Qt 6) desktop app, shipped as a Mac .app

Why this beats the alternatives for THIS project:

| Option | Assessment |
|--------|------------|
| **PySide6/Qt — CHOSEN** | All project logic already lives in Python (`dwm/`, script compiler, LZ codec, 40+ tools) and imports directly — zero IPC layer. QGraphicsScene/QGraphicsView is purpose-built for tile/map editors (zoom, layers, rubber-band select, drag); most serious ROM-hacking editors are Qt. Native menus/shortcuts/file dialogs on macOS. Packaged as a signed `.app` with PyInstaller or Briefcase. Cross-platform for free later. |
| Swift/SwiftUI native | Best Mac feel, but every ROM operation would shell out to Python or be rewritten — duplicating the project's most valuable, hardest-won code. Rejected. |
| Tauri/Electron + web UI | You said not web UI; also adds an IPC boundary to the Python core. Rejected. |
| Tkinter | What the legacy editor proved insufficient. Rejected. |

## Architecture: three layers, GUI on top

```
┌─ editor2/app  (PySide6)  ──────────────────────────────────┐
│  RoomCanvas (QGraphicsScene)  ScriptEditor  DialogueEditor │
│  NPCInspector  FlagManager  WorldMap  BuildPanel           │
└──────────────┬─────────────────────────────────────────────┘
               │ plain Python calls (same process)
┌─ editor2/core (pure Python, NO Qt imports) ────────────────┐
│  project.py     load/save/validate project.json            │
│  compiler.py    project → patches/bank_060.asm (+spill)    │
│  validators.py  every KEY_LESSONS rule as a check          │
│  romdata.py     read-only views over extracted/*.json      │
│  builder.py     stage patches → rgbasm/rgblink → ROM       │
│  emulator.py    launch SameBoy.app with the built ROM      │
└──────────────┬─────────────────────────────────────────────┘
               │ imports
┌─ existing assets ──────────────────────────────────────────┐
│  dwm/ (ROM, text codec)   tools/compile_script.py          │
│  tools/compress_tiles.py  tools/render_rooms.py logic      │
└────────────────────────────────────────────────────────────┘
```

Hard rules:
1. **project.json is the source of truth; ASM is a build artifact.**
   Hand-written bank_060.asm retires once the compiler reproduces v23.
2. **core/ never imports Qt** → `python3 -m editor2.core.builder
   myproject/` builds headlessly. CI-able, scriptable, Claude-workable.
   The GUI is a thin shell over the exact same calls.
3. **Compiler is deterministic**: same project → byte-identical ROM.
4. **Validators, not folklore**: script index 0 reserved; text ends
   `$F7 $F0`; newline only as `$EF $EE`; choice `$E7 $F0`; NPC entries 5 B
   / exits 7 B with $FF only entry-leading; exit screen-bytes copied from
   a verified existing exit to the same destination; per-bank space
   accounting with auto-spill across the 23 empty banks and hard error
   before rgbasm ever sees an overflow; flag names resolved against the
   free pool ($0158–$02C0). Every rule cites its KEY_LESSONS entry.

## macOS specifics

- **Toolchain bundling**: ship `rgbasm/rgblink/rgbfix` (universal arm64+
  x86_64 binaries, ~1 MB total) inside `Claude DWM Editor.app/Contents/
  Resources/bin/` — users never install RGBDS. Build them once via
  `make` on each arch + `lipo`.
- **Emulator**: SameBoy is a first-class native Mac app; `emulator.py`
  does `open -a SameBoy built.gbc` (configurable path). Stretch: drive
  SameBoy's debugger for breakpoint-on-custom-room smoke tests.
- **Packaging**: PyInstaller `--windowed` → `.app`; `codesign --deep` +
  `xcrun notarytool` if distributing outside your own machine. Briefcase
  is the fallback if PyInstaller fights PySide6 plugins.
- **ROM handling**: app never bundles the ROM. First launch asks for
  `DWM-original.gbc`, verifies MD5 `1ca6579…`, remembers the path
  (`~/Library/Application Support/DWMEditor/config.json`).
- Native niceties: QUndoStack for system-wide ⌘Z, ⌘B build, ⌘R run,
  autosave, recent-projects menu.

## Module → ROM primitive map (each backed by something already proven)

| GUI module | Edits | Backed by |
|------------|-------|-----------|
| RoomCanvas | screens (4×2+ grid), tile paint, collision overlay, exit placement | room format + LZ codec; preview via render_rooms logic |
| TilesetPanel | import PNG → 2bpp tiles, dedupe, palette mapping | rgbgfx/PIL + compress_tiles (Phase 1 custom-GFX item) |
| NPCInspector | sprite (from sprite_reference.json), facing, position, script binding, flag visibility | interact block format, 32 B RAM slots |
| DialogueEditor | text with LIVE 18-char wrap + page preview, YES/NO branch wiring | dwm/text.py codec + two-level table emitter |
| ScriptEditor | pseudo-code text w/ opcode autocomplete + inline validation; visual blocks LATER, not v1 | compile_script.py (all 100 opcodes test-passing) |
| FlagManager | named flags, auto-allocation, usage cross-ref | EVENT_FLAGS free-pool analysis |
| WorldMap | room graph + warp arrows | exit/transition data (Phase 1 warp item) |
| GameData (v2) | monsters, enemy stats, encounters, breeding | Phase D `db` conversions |
| BuildPanel | compile → build → MD5/space report → Run | builder.py + verify_integrity discipline |

## Milestones (maps to ROADMAP Phase 2→3)

1. **M1 — Headless compiler** (no GUI): schema + compiler + validators;
   regression test = v23 content as `example-project/` produces identical
   in-game behavior. This is the riskiest part; do it first.
2. **M2 — Walking skeleton .app**: open project, tree of rooms, Build
   button, Run in SameBoy. Ugly is fine.
3. **M3 — Room canvas + NPC inspector** (the visual core).
4. **M4 — Dialogue + script editors** with live validation.
5. **M5 — Flags + world map + polish**, packaged signed .app.
6. **M6 (v2) — Game-data editors** once Phase D lands.

## Repo addition

```
editor2/
  core/        project.py compiler.py validators.py romdata.py builder.py emulator.py
  app/         main.py + one file per GUI module
  example-project/   v23 content as project.json (regression baseline)
  tests/       compiler determinism + validator unit tests (pytest)
```
