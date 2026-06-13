# ROADMAP — Verified DONE / NEEDS DOING

Two sections. Section 1 lists what is DONE, each row with the **evidence**
(how it was verified — most re-verified 2026-06-13, in-game items at ROM
v23). If you can't point at evidence, it doesn't go in Section 1.
Section 2 is what NEEDS doing, phased, each item with an acceptance test.
A session picks ONE item. Status legend: [ ] open · [~] partial · [!] blocked.

---

## 1. VERIFIED DONE

### Infrastructure
| Item | Evidence |
|------|----------|
| Byte-perfect clean build | `make` → MD5 `1ca6579…` == original ROM (re-verified after restoring bank_00b from the drift) |
| Patch system (clean repo + patches/ overlay) | `verify_integrity.py` check 2: patched build assembles, bank $60 populated |
| Integrity guardrail + doc-MD5 police | `tools/verify_integrity.py`, 4 checks, PASSING |
| RGBDS 0.6.1 build chain documented | README quick start, exercised this session from scratch |

### Reverse engineering (formats fully decoded, ROM-verified)
| Item | Evidence |
|------|----------|
| Monster info table $03:$4461, 221×43 B | family bytes 0–9 across all entries (DOC_AUDIT B) |
| Enemy stats $14:$4C1D, 487×25 B | 487/487 $FF delimiters at +$18 |
| Boss table $14:$4897 (32×4 B) + redirect $4893 | ROM bytes + bank_014 header (DOC_AUDIT A.5) |
| Breeding tables $16:$4B30 (825×5) + $4974 | terminator at base+4125; extracted JSON |
| Room system: ptr table $0B:$4B43, 107 rooms; step/interact/exit formats | 106 valid ptrs + $FFFF hole; interact/exit semantics SameBoy-confirmed (ROOM_DATA_FORMAT) |
| NPC RAM: $D7D2, 32 B/slot | parser `add $20` at $0B:~$4820 (DOC_AUDIT A.3) |
| Script engine: 100 opcodes, 518 scripts in $0C–$0F | label census 129+168+130+91; compile/decompile roundtrip; dump_all_scripts follows 9 branch opcodes via work-queue (810/866 WriteRAM = 93.5% coverage, was 55%) |
| Text system: charmap, DTE, control codes, 2,067 IDs, routing cascade | text_id_map.json count; control codes proven in-game (v23) |
| Event flags: fns $26A0/$26A6/$26AE, 311 used, 463 free | game.sym symbols; analyze_event_flags.py runs |
| Encounter pool format: 32 gates → pools 0–127 | encounters.json structure audit |
| Empty banks: 23 = 368 KB | full-ROM scan, exact match to list |
| Custom WRAM $D378–$D477 unclaimed by original code | repo-wide grep: refs stop at $D375/$D376–7 |

### Custom content primitives (proven in-game, v23)
| Item | Evidence |
|------|----------|
| Custom rooms (mapID ≥ $6B) in bank $60: multi-screen, scroll, exits (vanilla↔custom AND custom↔custom via exit entries) | v23 test rooms $6B/$6C reachable from GreatTree; $6B exits to $6C and back |
| Custom NPCs + scripts (bank $60 entry 4 dispatch) | BeefJerky NPC, room $6B |
| Custom text IDs $0A00+, two-level table, multi-page | v23 dialogue |
| YES/NO branching ($E7 $F0 + opcode $15 / $C83C) | room $6C NPC |
| Item give + inventory-full ($2A wrapped, $2C) | v23 |
| Event flag ops from custom scripts ($00/$01/$03) | v23 |
| All mapID-table intercepts (11 sites, 4 banks) | CROSSBANK_ROOMS table; 19 debug iterations documented in KEY_LESSONS |

### Tooling (re-verified this session)
| Item | Evidence |
|------|----------|
| LZSS compressor/decompressor | roundtrip: 512→141 B, decompress == original |
| Script compiler + decompiler (all 100 opcodes) | `compile_script.py --test` passes |
| Dumpers: bosses, encounters, monsters, NPCs, text, exits, rooms | smoke-tested dump_boss_table, decompile_script, analyze_event_flags |
| Room renderer | ALL_ROOMS_FINAL.png exists (not re-run) |

---

## 2. NEEDS DOING

### Phase 0 — Foundation (finish before feature work)
- [~] **SRAM save audit** — SRAM layout fully traced and documented in
      ARCHITECTURE.md + known_RAM_map.md. Custom flags $0158-$0277 in save
      range. Flag byte collisions mapped (D9CB/D9CD/D9CF-D9D6/D9E3/D9E6/D9E9).
      Safe contiguous block: $0158-$017F (40 flags).
      *Remaining*: in-game save/load test of a custom flag in SameBoy.
      *Accept*: v24 save → reload → custom flag still set.
- [x] **Fix `dump_all_scripts.py` branch-following** — linear decoder missed
      ~45% of WriteRAM operations. Fixed: work-queue follows 9 branch opcodes
      ($00/$01/$0E/$14/$15/$27/$28/$2C/$37). 810 unique WriteRAM found (was
      482; ROM ground truth 866 = 93.5% coverage). 56 remaining are in
      alternate dispatch paths (entry 1/2 tables). Canonical room names from
      editor/editor.py (96 entries). New `branch_targets` field per script.
      Castle script_id=0 now shows 69 branch targets, WriteRAM for D92B/D92C/
      D92D/D92F/D93C. all_scripts.json regenerated.
- [x] **Fix `dump_map_table.py` swapped interact/exit labels**, regenerate
      map_table.json. *Accept*: JSON field names match ROOM_DATA_FORMAT;
      spot-check 3 rooms against bank_00b labels.
- [x] **Commit CI workflow** (`.github/workflows/verify.yml`, provided).
      *Accept*: green run on GitHub on next push.
- [x] **Reconcile dump_enemy_stats.py with its richer committed JSON**
      (port exp_reward/ai_weights/skills/joinability decode back into the
      tool). *Accept*: regen == committed byte-identical → Tier A.
- [x] **Recover/write generators for frozen-source JSONs** — dump_skills.py,
      dump_text_id_map.py, dump_all_scripts.py written and verified.
      breeding_complete, resistance_*, tile_registry reclassified as
      hand-authored reference (not frozen-source). See TOOLS_AND_DATA.md.
- [~] Move one-off investigation tools to tools/archive/ and delete
      superseded data (monsters.json, event_flags.json, edits.json) per
      TOOLS_AND_DATA.md. *(Postponed — low priority.)*
- [~] Housekeeping deletions/moves per PROJECT_STATE. *(Postponed.)*

### Phase 1 — Remaining primitives (1 session each; ordered by editor impact)
- [ ] **Script-driven teleport** — exit-based room transitions already
      work in all directions (vanilla↔custom, custom↔custom — proven in
      v23). Remaining: opcode $0E from a custom script for cutscene-
      style teleports (NPC talks, then warps player). Fallback: opcode
      $12 writes to $C96D/$C96E/$C925 (transition executor $0B:$45AB
      consumes these).
      *Accept*: v2x ROM script-triggers a warp without the player
      stepping on an exit tile.
- [ ] **NPC show/hide by flag** — mechanism IS the step system
      (ROOM_DATA_FORMAT.md "Room State System"): multiple step entries
      per screen with different NPC lists, step counter set by opcode
      $12 (WriteRAM $D9xx). Opcodes $48/$49 are runtime movement-based
      show/hide (cutscene use only, not persistent). Remaining work:
      test a custom room with ≥2 step entries where an NPC script
      advances the step counter, then re-entering shows different NPCs.
      *Accept*: NPC appears only after custom flag/step is set; verified
      after room re-entry and after scroll.
- [ ] **BGM change** — opcode $41; table in known_RAM_map ($C8B5).
      *Accept*: custom room plays a chosen track; reverts on exit.
- [ ] **Monster give** — opcode $29; test party non-full AND full paths.
      *Accept*: monster in party with correct species/level; defined
      behavior when party full.
- [ ] **Custom tile LAYOUTS** (compressor done): place compressed layouts
      in a free bank, point step_entry byte 1 at it.
      *Accept*: custom room renders a layout that exists nowhere in the
      original ROM.
- [ ] **Custom tile GRAPHICS**: intercept Entry 0/1 GFX load (currently
      clamped to source room via $00:$26DD) for mapID ≥ $6B → custom GFX
      ptr in bank $60. Needs PNG→2bpp pipeline (rgbgfx or PIL).
      *Accept*: custom room shows tiles drawn by us.
- [!] **Random encounters in custom rooms** — blocked on decoupling.
      `wInGateworld` ($C969) gates encounters AND script dispatch AND floor
      generator. Attack plans, in order:
      1. Find the battle-trigger call chain (step counter $CA39 → threshold
         → battle init) and invoke it from a per-step hook (RoomEntry6 runs
         every step) with a custom pool — bypass $C969 entirely.
      2. Else set $C969=1 in custom rooms and patch the two unwanted
         consumers to check mapID ≥ $6B.
      *Accept*: random battle fires in a custom room from a custom pool;
      win/lose/flee all return to the room intact.
- [ ] Custom music — parked; sound engine unexplored, BGM-change suffices
      for v1 stories.

### Phase 2 — Content format & compiler (the editor backend)
- [ ] `project.json` schema: rooms/screens/exits/NPCs, scripts
      (decompiler pseudo-code), dialogue (auto-wrap 18 ch, auto-DTE,
      auto page-split, two-level table emission), named flags
      auto-allocated from the free pool, items, encounters.
- [ ] `tools/build_project.py`: project → bank_060.asm (+spill to $64,
      $67… — multi-bank from day one) → make → ROM. Deterministic.
      KEY_LESSONS rules become compiler validations (script index 0
      reserved, text termination, exit byte copying, entry-sized data,
      bank space accounting).
- [ ] **Regression baseline**: re-express the v23 content as
      example-project/ and diff behavior. *Accept*: same rooms, NPCs,
      dialogue, item give work from generated asm.

### Phase 3 — Editor app (see EDITOR_DESIGN.md — native macOS)
- [ ] Walking skeleton: open project, room list, Build, Run-in-SameBoy
- [ ] Room canvas editor → NPC editor → dialogue editor → script editor
      → flag manager → world/warp map
- [ ] Game-data editors (monsters/encounters/breeding) after Phase D

### Phase D — Disassembly deepening (parallel; pick when blocked elsewhere)
Driven by what the editor must EDIT, not completionism:
- [ ] Bank $03 monster table → labeled `db` (gen_monster_db.py exists —
      verify generator, apply, MD5 must stay `1ca6579…`)
- [ ] Bank $14 enemy stats + boss tables → `db`
- [ ] Bank $01 encounter pools → `db`
- [ ] Bank $16 breeding tables → `db`
- [ ] Bank $51: annotate transitions + prove/disprove the 1,228 B
      free block is reference-free
- [ ] Bank $50 event state machine (story events)
- [ ] Save/SRAM code annotation (supports Phase 0 audit)
Raw graphics/audio banks ($32–$3A, $5A, $63…) stay LOW priority — they
block nothing.

---

## Definition of editor v1
A user with zero ASM knowledge builds: a custom room with their own layout,
NPCs with flag-gated branching dialogue, an item + monster reward, a warp
between two custom maps, a BGM change — clicks Build, plays it in SameBoy.
Everything except encounters/custom-art is already proven at ROM level;
the gap is formats and UI, not reverse engineering.
