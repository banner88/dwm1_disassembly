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
| Script engine: 100 opcodes; 518 `*_ScriptNN:` labels in $0C–$0F (census 129+168+130+91) = 551 unique script bodies = 732 (map_type, script_id) pointer-table entries in all_scripts.json (map types share banks/scripts — all three counts correct on different bases, verified S51) | compile/decompile roundtrip; branch-following work-queue (810/866 WriteRAM = 93.5%) |
| Text system: charmap, DTE, control codes, 2,067 IDs, routing cascade | text_id_map.json count; control codes proven in-game (v23) |
| Event flags: fns $26A0/$26A6/$26AE; 328 referenced, 298 with sets (branch-following) | EVENT_FLAGS.md statistics; analyze_event_flags.py |
| Encounter pool format: 32 gates → pools 0–127 | encounters.json structure audit |
| Gate floor GENERATION: procedural maze grid `$C940`, per-gate `GateFloorDataTable` `$16:$70A6`, `SelectFloorType`/`FloorTypeSelectionTable`1/2/3, special-room `rst $00` dispatch `$16:$5C1C`, damage tiles (class `$0E`/`FloorDamageTable` `$01:$5E7D`) | S37: pipeline traced end-to-end + damage tiles SameBoy-watchpoint-confirmed; **GATE_GENERATION.md** |
| Vanilla-empty banks: 23 = 368 KB | full-ROM scan; CURRENT allocation lives in PROJECT_STATE "Bank allocation" (8 banks now patch-owned) |
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
| Custom breeding recipes (special table, same-size edit) | v31/Session 12: Anteater×BattleRex→GoldSlime via two provably-dead entries (803 dup, 693 shadowed); focused build diffs original at exactly the intended bytes; confirmed in-game. Tool `patch_breeding_recipe.py`, `patches/bank_016.asm`. |

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
- [x] **SRAM save audit** — SRAM layout fully traced and documented in
      ARCHITECTURE.md + known_RAM_map.md. Custom flags $0158-$0277 in save
      range. Flag byte collisions mapped (D9CB/D9CD/D9CF-D9D6/D9E3/D9E6/D9E9).
      Safe contiguous block: $0158-$017F (40 flags).
      *Verified Session 8*: flag $0158 (byte $D9C6, bit 0) set via NPC script,
      persisted through save+reload in SameBoy. PASS.
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
- [ ] **Fold tool selftests into `verify_integrity.py`** (promoted S51 from *Open*
      notes buried in the B3/B7/S1 completed stubs): the byte-identity selftests of
      `build_breeding.py`, `build_library_table.py`, and `build_skill_tables.py`
      only run when someone remembers to invoke them — the verifier doesn't, so a
      table edit can silently diverge from its JSON. Add a check 5 that runs each
      `--selftest`. *Accept:* verifier FAILS on a deliberately mutated table; PASS
      5/5 on the clean tree.
- [ ] **Retire `extracted/skills.json`** — superseded by `skill_records.json` (S44);
      only `gen_name_tables_db.py` still reads it. Port the reader, then delete
      `skills.json` (+ mark `dump_skills.py` legacy). *Accept:* repo-wide grep shows
      zero readers; TOOLS_AND_DATA updated.
- [x] **Housekeeping deletions — EXECUTED S51 (user OK'd):** actually deleted:
      `__pycache__/`, 8× `.DS_Store`, `breeding_extra_recipes.json` — all three
      were TRACKED at HEAD, so recoverable from git history if ever needed
      (breeding_extra_recipes was a self-described B3 capacity TEST fixture; its
      facts are in SESSION_HISTORY's archived B3 narrative). THREE queue rows
      were stale: `monsters.json`, `event_flags.json`, `edits.json` were all
      already absent (untracked at HEAD — a fresh clone never contained them;
      verified S51 during the no-loss audit). `build_breeding.py
      --emit-relocation` help marked LEGACY (absence-tolerant). Verifier PASS 4/4.
      NEW defect found: `dump_monsters.py` WRITES the legacy `monsters.json`
      schema and READS `monsters_full.json` — the Tier-A generator attribution for
      `monsters_full.json` is suspect (see PROJECT_STATE Open defects).
- [x] **S51 — Doc consolidation + audit** (2026-07-02): PROJECT_STATE 1,071→~280 and
      ROADMAP 1,176→~640 lines with ZERO deletion (everything cut moved verbatim to
      the new cold archive `documentation/SESSION_HISTORY.md`); contradictions fixed
      in place (bank counts, script/flag counts, stale paths/headers);
      TOOLS_AND_DATA refreshed to 103 tools / 56 JSONs; `TilesetLookupTable` →
      `SkillMPCostTable` + `LoadFld_56e8` → `GetSkillMPCost` renamed (byte-perfect).
      → PROJECT_STATE "S51" block; SESSION_HISTORY.md.

### Phase 1 — Remaining primitives (1 session each; ordered by editor impact)
- [x] **Script-driven teleport** — exit-based room transitions already
      work in all directions (vanilla↔custom, custom↔custom — proven in
      v23). Opcode **$0F** (MapTransitionFull) **confirmed working** from
      custom scripts — tested vanilla (Castle) and custom ($6B) destinations.
      Note: $0E is BranchByScreen, NOT teleport (bank $04 inline comment
      at $59D2 was wrong, fixed). $0F writes gate_id → $C96D, flag → $C96E,
      spawn XY → $C96F-$C972, sets wIsPlayerChangingMaps=1.
      Format: `$FF0F <gate_id:flag> <spawnX> <spawnY>` (3 word params).
- [x] **NPC show/hide by flag/step** — mechanism is the step system (multiple step
      entries per screen; opcode $12 advances the counter; custom counters moved to
      safe $D478+, not SRAM-persistent). Confirmed in-game v25.
      → ROOM_DATA_FORMAT "Room State System"; archive: SESSION_HISTORY Part 3.
- [x] **BGM change** — opcode $41 (SetBGM) **confirmed working**.
      Saves current BGM to $C8B6, plays new track from param.
      Track IDs in known_RAM_map ($C8B5). Tested: Arena ($1E) in
      custom room; reverts on room exit.
- [x] **Monster/egg give** — opcode $29 (AddMonster, wrapped in bank $04 padding) +
      $28 storage-full. Egg path proven (SkyDragon EID 350) and is the practical
      choice; direct give needs the `$FF04 $000F` preamble.
      → DATA_STRUCTURES; KEY_LESSONS S3; archive: SESSION_HISTORY Part 3.
- [x] **Custom tile LAYOUTS** — tile_layout_compiler.py → bank $64 (ptr table +
      LZSS); a nowhere-in-ROM layout renders in-game; palette-attr fix v28
      (CustomAttrCheck, bank $17); collision thresholds ROM0 $26E3 ×8 stride.
      → ROOM_DATA_FORMAT "Tile Layout System"; KEY_LESSONS S4–S5; archive: SESSION_HISTORY.
- [x] **Custom tile GRAPHICS (multi-tileset mashup)** — full pipeline: editor JSON →
      build_combined_tileset.py → bank $67/$17 patches → playable room (4-palette-group
      budget; gate-detection fixes in $06/$07; --build automation; runtime-correct
      tileset PNGs S9). Confirmed in-game.
      → KEY_LESSONS S6–S9; TOOLS_AND_DATA; archive: SESSION_HISTORY Part 3.
- [~] **Multi-screen room editing** — ROM-side patches complete (v28):
      2-screen vertical room proven (Room $6B, screens 0+4). Key changes:
      room height in $26DD table ($2A39: $80→$00,$01 = 256px = 2 rows),
      sub-table indices 0+4, bank $64 entries 0-3 (per-screen layout+attr),
      CustomAttrCheck screen-aware (bank $17), wCustomStep_Room6B_S1 added.
      **Remaining**: editor UI for multi-screen (canvas, screen selector,
      per-screen NPC/exit placement); `build_combined_tileset.py` multi-screen
      export; extend to horizontal and larger grids.
      *Accept*: editor exports a 2+ screen room; `--build` produces a ROM
      where the player can scroll between screens.
- [x] **Random encounters in custom rooms** — PROVEN S11 (Strategy A: mapID whitelist
      in $0B:Jump_00b_4674 + pin wGateID/wCurrentFloor + arm wEncounterCounter);
      generalized per-room S42 (RoomEncTable, bank $71 — see Encounters #1).
      → CROSSBANK_ROOMS "Random Encounters"; KEY_LESSONS S11; archive: SESSION_HISTORY.
- [ ] Custom music — parked; sound engine unexplored, BGM-change suffices
      for v1 stories.

### Phase 2 — Content format & compiler (the editor backend)
- [x] **Architectural keystone — table-driven custom-room dispatch (DONE S42, user-confirmed).**
      All remaining hardcoded per-room intercepts are now table-driven and the old `$6F` room
      ceiling is lifted to editor scale. Dispatch *logic* lives in the previously-empty bank
      `$71` (reached via `rst $10`) so every in-bank edit is byte-neutral. `$70+` rooms get
      their `$26DD` tileset/dims/threshold record from `Custom26DDTable` (bank `$71`,
      far-copied to `wRoomRecScratch`), sidestepping the in-ROM0 `$70`↔`$2A5D` gate-table
      collision. Encounters folded in (see Encounters #1). Proven by room `$70` (amber) added
      *past* the ceiling by table rows alone — renders, encounters, exits all confirmed.
      Owning doc: **EDITOR_DESIGN.md §2** (as-built map). This is the green light for
      `build_project.py`.
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
- [x] **Encounters #1 — per-room toggle** (DONE S42, user-confirmed). `RoomEncTable`
      (bank `$71`, 3 B/room `[enabled, gateID, floor]`, indexed `mapID−$6B`) scanned by
      `CustomEncResolve` (bank `$71` entry 1) via the bank-`$0B` whitelist hook, replacing
      the hardcoded `cp $6B`. `$6B` reproduces its old gate-0/floor-1 behavior exactly;
      `$6C-$6F` silent; `$70` enabled (proof). Project fields per room: `encounters`,
      `gate_id` (0-31), `floor`. Spec in CROSSBANK_ROOMS.md.
- [ ] **Encounters #2 — custom monster pools**: 26-byte pool in a free bank +
      intercept of `EncounterMonsterSelect`'s pool fetch for custom mapIDs (or
      reuse a verified-unreferenced pool slot). Project fields: up to 5
      `{enemy_stats_id, weight}` + header template. Spec in CROSSBANK_ROOMS.md.

### Phase 2C — Gate generation (system mapped S37; see GATE_GENERATION.md)
- [x] **Custom room into the gate rotation** — BOTH halves done, user-confirmed:
      render (S39 gate-tileset room; S40 Pillar A — fully table-driven by mapID−$6B,
      no hardcoded cp $6B) + insertion (S41 Pillar B — GateDecisionFork at $16:$5BA9
      routes gate 1 → custom $6D; descent feel via transient wInGateworld=$01 during
      transition only). → GATE_GENERATION §7.1–7.5; archive: SESSION_HISTORY Part 3.
- [x] **Room-palette derivation from ROM** (S39) — derive_room_palette.py, validated
      30/30 SameBoy dumps + gate floor. → GATE_GENERATION §7.1.
- [ ] **`piece_id → screen layout` map** — decode the table turning a grid cell's
      high nibble into the rendered screen layout (needed to author NEW maze
      pieces vs. only reweighting existing ones). (GATE_GENERATION.md §12.2.)
- [ ] **Full `rst $00` dispatch enumeration** — list every special-floor handler
      slot so reusable slots are known precisely. (§12.3.)
- [ ] **`SetBrd_6744`/`SetBrd_6800` carve algorithm** — step-trace the maze
      connectivity guarantee. (§12.4.)

### Phase 2B — Breeding overhaul & extension (specced Session 12; see BREEDING_SYSTEM.md)
Keep 10 families. Defaults rewritten; special recipes extended to 1×–2× (→~1650).
Mechanism ROM-verified: relocate special table + scanner to free bank `$69`,
call via `rst $10`; rewrite family table in place (result = slot index, so the
compiler inverts `A×B→C` to slot order and rejects positional conflicts); bank
$16 edits same-size only (leave vanilla tables dead-in-place).
- [x] **B1 — Round-trip encoder (keystone)** — DONE S13: build_breeding.py --selftest
      re-emits BOTH vanilla tables byte-identical ($4B30 4126 B; $4974 444 B);
      reconciled 825/825 + 197/197 vs the hand-authored JSON.
      → BREEDING_SYSTEM; TOOLS_AND_DATA; archive: SESSION_HISTORY Part 3.
- [x] **B2 — Relocation harness** — DONE S13: bank $16 special scan replaced in place
      with `ld hl,$6900`+`rst $10` (zero shift); faithful scanner + table in
      patches/bank_069.asm sourced from the PATCHED bank_016 (rev-1 lesson: sourcing
      vanilla silently reverted S12's recipe). User-confirmed; saving OK.
      → BREEDING_SYSTEM; archive: SESSION_HISTORY Part 3.
- [x] **B3 — Capacity 1×–2×** — DONE S15: scanner walks to the $FF terminator, so
      appends past index 824 work (cap 1650); unshadowed proof recipe user-confirmed.
      SUPERSEDED as the bank-$69 emitter by B5. *Open follow-up:* fold the
      "base 825 == patched bank_016" assert into verify_integrity.py (tool
      self-asserts; the verifier does not run it — same note on B7).
      → BREEDING_SYSTEM; KEY_LESSONS S15; archive: SESSION_HISTORY Part 3.

### Breeding romhack plan (user goal — Session 15 signpost; test each part separately)
Target: rename the **??? family ($F9) → "Spirit"**, shuffle monsters out of ???
and Spirit-looking monsters in, and **fundamentally rewrite all recipes**. Monster
count stays 221 (shuffle + rename only → same-size byte edits, NO table expansion;
expansion would shift every species-ID-indexed table and is not needed). DWM2
sprite swaps are an independent same-size graphics job (does not touch this logic).
Verified mechanics (Session 15, grepped — do not re-trust): resolver is
special → family → **fallback = parent 1** (`$16` Step 4: `ld a,[$da6f]; ld
[$da71],a`). **??? has ZERO family-table defaults** and appears as a matcher in
only 2 of 825 specials (both as the *mate*: Slime×Boss→KingSlime,
Dragon×Boss→sp$29). So "??? × anything → itself" is the **universal fallback**
showing through, NOT a ???-specific rule — nothing special to dismantle; Spirit
recipes are pure authoring.

- [x] **B4 — Family-defaults rewrite** — DONE S16, user-confirmed: --emit-family
      authors the positional family table in place (1:1 + 444-byte zero-shift + shadow
      validation); 5-changed-byte proof set incl. Dragon×Dragon→GreatDrak.
      → BREEDING_SYSTEM; KEY_LESSONS S16; archive: SESSION_HISTORY Part 3.
- [x] **B5 — Full special-table authoring** — DONE S17, user-confirmed: --emit-special
      OWNS the whole special table (825 ROM base + in-place overrides + appends +
      whole-table first-match-wins shadow validator) → bank $69; bank $16 stays
      vanilla. Supersedes B3's emitter. Delivers the machinery; the recipe REWRITE is
      editor-authored content later.
      → BREEDING_SYSTEM; KEY_LESSONS S17; archive: SESSION_HISTORY Part 3.
- [~] **B6 — Family reassignment** — reassignment DONE S18, user-confirmed
      (build_family_reassign.py: same-size family-byte edits, ANY family incl. ???;
      reader gate cleared — eligibility is joinability + boss table, NOT family; three
      family representations documented). Dynamic-library POC superseded by B7.
      *Remaining, split out:* the rename / 11th-family work = B8/B9 below.
      → BREEDING_SYSTEM "B6"; KEY_LESSONS S18; archive: SESSION_HISTORY Part 3.
- [x] **B7 — Production library grouping** — DONE S19, user-confirmed zero-lag:
      build_library_table.py emits a build-time family→members table into bank $12
      free space + a zero-shift walker (zero far-loads/scratch RAM; vanilla blank-slot
      semantics; NUM_FAMILIES/256-id aware; specials 215–220 protected). *Open:* tool
      selftest not run by verify_integrity.py (see B3 note).
      → BREEDING_SYSTEM "B7"; KEY_LESSONS S19; archive: SESSION_HISTORY Part 3.
- [~] **B8 — ??? → "Spirit" rename** — trace SOLVED S20: the family "name" is an ICON
      font tile ($4F:$4110–$41A0, text bytes $10–$19, addr=$4010+byte*16), not a
      string. NOT taken — user decision: Spirit is ADDED (B9). Kept as the
      solved-trace record. → BREEDING_SYSTEM "Family icons"; archive: SESSION_HISTORY.
- [~] **B9 — Add an 11th family (Spirit)** — VRAM corruption FIXED (ClampFamIdx,
      ROM0) + Spirit whip icon SHIPPED on byte $19 / $4F:$41A0 (user-confirmed; the
      "free" $1A slot is runtime-blanked — not usable). *Open:* wire Spirit as family
      11 — $4D detail line, tab-strip 11th cell, $FA wildcard question,
      NUM_FAMILIES→11 in build_library_table.py, family reshuffle; tab-strip layout is
      the one UI nicety. → BREEDING_SYSTEM "Future — 11th family"; KEY_LESSONS
      "Spirit B9"; archive: SESSION_HISTORY Part 3.
- [x] **BUG — breeding-cutscene parent sprites** — FIXED S14: incomplete bank $0B
      labelization (3 raw pointer refs into the shift region) + one ref mislabeled to
      RoomScreenPtrTable; re-sectioned + repointed, user-confirmed.
      → KEY_LESSONS "Session 14 — Bank $0B repointing"; archive: SESSION_HISTORY.

### Phase 3 — Editor app (see EDITOR_DESIGN.md — native macOS)
- [ ] Walking skeleton: open project, room list, Build, Run-in-SameBoy
- [ ] Room canvas editor → NPC editor → dialogue editor → script editor
      → flag manager → world/warp map
- [ ] Game-data editors (monsters/encounters/breeding) after Phase D

### Phase D — Disassembly deepening (parallel; pick when blocked elsewhere)
Driven by what the editor must EDIT, not completionism:
- [x] **Annotate the new-species fork SEAMS in clean disassembly** — DONE across
      S30/S33/S38 (labels/comments only, build byte-perfect each time): info indexer
      ($03 label443f/SaveMon_4446), enemy stats ($14 LoadEnemyStats +
      EnemyStatsTrailingFree @ $7EAD — EIDs 487–517 unusable, first slot EID 518),
      encounter pool ($01), breeding sites ($16 label16_485c + the two $0301
      parent-family loads), the 8 follower gfx-ID copies, and the name/text/lineage
      chain ($41 / ROM0 $092F / $12 / $4d). Corrections recorded: ItemNamePtrTable =
      mode 8 (not 11); $4739 overshoots at id≥215 (fork covers ≥224).
      **STILL PENDING (own pass, general breeding mechanics — NOT a new-species
      seam):** bank $16 breeding-determination internals (LoadBrd_4653 plus/special,
      LoadBrd_45d5/45ff family scan, special→family→pedigree precedence).
      → MONSTER_DATA "Species ID geography"; archive: SESSION_HISTORY Part 3.
- [x] Bank $03 monster table → `db` ✅ VERIFIED S51: `MonsterInfoTable` +
      per-monster `MonsterInfo_NNN_Name:` labeled `db` blocks (stale box; the
      conversion had already landed in an earlier pass).
- [x] Bank $14 enemy stats + boss tables → `db` ✅ VERIFIED S51: `EnemyStatsTable`
      + per-EID `EnemyStats_NNN:` labeled field-commented `db`/`dw` blocks.
- [ ] Bank $01 encounter pools → `db` (editor-driven — Encounters #2)
- [x] Bank $16 breeding tables → `db` ✅ VERIFIED S51: `SpecialRecipeTable` +
      `FamilyRecipeTable` labeled `db` blocks.
- [ ] Bank $51: annotate transitions + prove/disprove the 1,228 B
      free block is reference-free
- [ ] Bank $50 event state machine (story events)
- [ ] Save/SRAM code annotation (supports Phase 0 audit)
- [~] **Re-section misassembled data tables → labeled `db`/`dw`.** mgbdis rendered
      many in-bank DATA tables as fake instructions — they build byte-identical but
      can't be edited in source; this bit S14 ($0B tables), S18 (library bounds), S22.
      Convert per table with the probe-build line→address method (no opcode-size
      summing — the S22 trap); **build MUST stay `1ca6579…` after each**.
      Bank `$12` COMPLETE (S26+S27: bounds table, tab-column tables, all 29 window
      layouts → library_layouts.json). → DATA_STRUCTURES "Library / family-tab menu
      data (bank $12)"; TOOLS_AND_DATA; archive: SESSION_HISTORY Part 3.
      **NEXT (per-session, one each):**
      (1) ✅ bank `$12` — DONE (S26/S27).
      (2) ✅ STALE BOXES verified + ticked (S51): bank `$03`/`$14`/`$16` were
          already `db`-converted.
      (2b) ✅ DONE (S51): `SkillMPCostTable` ($07:$570C, 222×`dw` with per-skill
          name/MP comments) + `SkillLearnReqTable` ($06:$50E0, 222×18B `db` with
          decoded stat/prereq comments) re-sectioned in BOTH trees via the new
          `tools/resection_skill_tables.py` (probe-build; clean build byte-perfect;
          verifier PASS 4/4). Two fake-decode artifact labels (`DispMapS_566b`,
          `label6_6034`) are kept at exact offsets — they're referenced by fake
          instructions in not-yet-re-sectioned regions of bank `$06`.
      (3) **Editor-driven only:** bank `$01` encounter pools (Encounters #2), bank
          `$51` transitions, bank `$50` event state machine — when the feature needs them.
      (4) **Checked, SKIP (no editor value, mis-split risk):** the `$ff`-padding banks
          `$08/$15/$2c/$33/$55/$66` — mostly filler, not discrete tables.
**STALE BOXES (verify + tick):** the first three boxes above (bank $03 monster
table, $14 enemy stats/boss, $16 breeding) appear ALREADY `db`-converted on disk
(bank_003/014/016 are heavily `db`/`dw` with labeled loaders). Confirm against
disassembly and check them off.

- [x] **GFX-1 — Sprite codec + gfx-table re-section** ✅ S22 — MonsterBattleGfxTable
      $00:$2B9F re-sectioned (23 cross-refs preserved); dwm/sprite_codec.py (decode
      byte-exact; decode(encode(x))==x on all 442 streams; round-trip is SEMANTIC by
      design, not vanilla re-encode); extract_monster_sprites.py (all 221);
      build_sprite_swap.py; Dracky→clam swap user-confirmed.
      → MONSTER_DATA "Monster sprite graphics system"; KEY_LESSONS S22; archive: SESSION_HISTORY.
- [x] **GFX-2 — Palettes + cross-bank sprite backbone** ✅ S23 — dwm/sprite_bank.py
      overflow allocator ($7E,$7F then $7C,$7A,$79; resolver has no bank gating →
      any of 221 monsters repointable); MonsterBattlePalettes @ $17:$62FD SOLVED
      (was mislabeled RoomAttrDataBlocks; 8 B/species, loaded by $17 entry 6);
      recolour = same-size 8-byte edit. User-confirmed (clam→Dracky purple + full
      integration ROM). → MONSTER_DATA "Monster battle palette system"; KEY_LESSONS
      S23; archive: SESSION_HISTORY Part 3.
- [x] **GFX-3 — Follower/walking sprite swap** ✅ S24 — ScreenTransDataTable
      $01:$49DF re-sectioned; metasprite render engine reversed (SaveScr_40cd:
      4-byte dy,dx,tile_offset,attr entries, $80-term; OAM tile += $ffc9 base
      $20/$30/$40; attr XOR $ffca; **OBJ idx0 = hardware-transparent** — opposite of
      the battle BG path); 118-layout library + follower_frame_picker.html +
      numbered-tile calibration method. User-confirmed all 4 directions.
      → MONSTER_DATA "Follower / walking-sprite system"; KEY_LESSONS S24; archive: SESSION_HISTORY.
- [x] **GFX-4 — Species→layout auto-map + custom-art import** ✅ S25 — level-1 layout
      tables LOCATED at $10/$11:$407f (+ per-species attr tables $10:$417f/$11:$412d);
      155 complete layouts (monster_follower_layouts.json); the **8 follower gfx-ID
      table copies** discovered ($01 $06 $07 $09 $0b $12 $18 $59 — a swap repoints
      ALL 8); build_follower_reassign.py (clone or custom-art import; reassignment =
      level-1 repoint, NOT a [$caca] edit). User-confirmed across overworld+menu+library.
      → MONSTER_DATA "Monster → layout dispatch"; KEY_LESSONS S25; archive: SESSION_HISTORY.

Raw audio banks ($5A, $63…) stay LOW priority. **Graphics banks ($32–$3A are NO LONGER
low-priority** — the monster sprite system there is editable and proven; see GFX-1/2/3 above.

---

## Definition of editor v1
A user with zero ASM knowledge builds: a custom room with their own layout,
NPCs with flag-gated branching dialogue, an item + monster reward, a warp
between two custom maps, a BGM change — clicks Build, plays it in SameBoy.
Everything except encounters/custom-art is already proven at ROM level;
the gap is formats and UI, not reverse engineering.

---

## Definition of a NEW CAMPAIGN (beyond editor v1) — Phase E gap analysis

Editor v1 (above) deliberately scopes to rooms / NPCs / dialogue / items / warps /
BGM — all proven at ROM level, so "the gap is formats and UI, not RE." **Fundamentally
writing a NEW CAMPAIGN** (a new questline, a new challenge progression, a new world —
not just editing the vanilla one) needs additional load-bearing subsystems that are
currently under-addressed. This section is the Session 27 gap analysis: each item gives
current state (grounded in the repo), why it is campaign-critical, where it is outlined
(if at all), a confidence level, and the owning doc / next step.

### Phase E — Campaign-scale subsystems (the "new campaign" gaps)
Priority: **E1 and E2 are the keystones** (E1 is the one true remaining RE gap; E2 is
the authoring-model backbone). E3/E4 are important; E5/E6 are lighter.

- [ ] **E1 — Arena / gate-boss ROSTER data format. (The biggest unreversed gap.)**
      DWM1's campaign *is* the arena-rank climb (G→S class) plus mandatory gate bosses;
      the opponents you fight ARE the campaign's challenge content. The progression
      *flags* are mapped (SIDEQUEST_MAP "Story Progression Overview"), but the **opponent
      rosters are NOT decoded** — which monster parties appear at each arena class and at
      each gate-boss fight, their levels/skills, and the bracket ordering. `boss_table.json`
      (`dump_boss_table.py`, the `$4897` table, 32 gates) covers gate bosses; whether it
      *also* encodes the arena-class tournament brackets is **unverified** (a roster-format
      search across docs returned zero hits). A new campaign cannot define its own challenge
      curve until this is reverse-engineered and made authorable (`project.json`: arena
      class → opponent party; gate → boss party). *Confidence: HIGH this is a real RE gap.
      Owning doc: SIDEQUEST_MAP (technical) + this item. Next step: trace the arena-lobby
      battle-setup path (how the lobby picks the opponent party for the current rank) and
      confirm/extend `boss_table.json` (or add `arena_brackets.json`).*

- [ ] **E2 — Story progression as an AUTHORABLE model (incl. bank `$50` annotation).**
      The mechanism is understood at flag level — story counter `$D9E3` (`$0240-$0247`,
      driven 48→78 by boss-defeat scripts), arena rank flags `$0030-$0037` (`$D9A1`, set by
      Arena Lobby script 0), and the mandatory gate interludes (BattleRex `$001D`, Durran
      `$0025`, Starry Night `$00F1`) checked in priority order. But this is NOT a first-class
      object in the Phase 2 `project.json` schema (which stops at scripts / dialogue / flags /
      items / encounters). Two concrete blockers: **bank `$50`** (the post-battle event state
      machine that advances story on a win — ARCHITECTURE: "$50 = Event state machine, 11
      states, post-battle states") is **largely unannotated — 43 named labels of 648**; and
      the engine **evaluation opcodes `$CA8D` / `$D8E1` / `$FF92`** still need per-opcode
      tracing (already flagged in SIDEQUEST_MAP). Authoring a *new* questline requires modeling
      "win condition → flag/counter set → unlock" as editable structure. *Confidence: HIGH
      (grounded). Partially outlined as Phase D one-liners (`bank $50 event state machine`),
      but never recognized as an editor subsystem. Owning doc: SIDEQUEST_MAP + Phase D bank-`$50` box.*

- [ ] **E3 — New-game initialization + save-schema headroom.**
      A new campaign sets its own starting party / items / flags / map position, and may add
      story variables. The opening is script-traced (ROUTING.md, FIRST_5MIN_TRACE.md; intro
      marker flag `$0000`), and Phase 0 audited the SRAM custom-flag range `$0158-$0277` as
      persistent across save+reload. But (a) new-game INIT data is not an authorable object,
      and (b) there is no headroom analysis for story state that would exceed the audited
      custom range (the story counter + any new arena/quest variables). *Confidence:
      MEDIUM-HIGH. Partially outlined (Phase 0 audit; Phase D save annotation), not
      editor-facing. Owning doc: ARCHITECTURE / known_RAM_map for the schema; this item for
      the editor-object + headroom work.*

- [ ] **E4 — Overworld / gate-network structure at campaign scale.**
      Custom rooms (mapID ≥ `$6B`, bank `$60`+) and individual warps are proven, but the
      **gate-selection / world-hub network** as an authorable graph — which gates exist, their
      unlock order, the gate-warp/selection menu, the GreatLog hub topology — is not specced
      beyond the Phase 3 "world/warp map" UI line. A *new world* (vs. editing the vanilla gate
      set) is the least-proven-at-scale piece. *Confidence: MEDIUM (rooms + warps proven; the
      gate-network DATA MODEL is the unknown). Owning doc: CROSSBANK_ROOMS / map docs; this
      item for the network-graph schema.*

- [ ] **E5 — Title screen + ending / credits sequences.**
      The opening cutscene is script-traced, but the title screen and the ending/credits
      sequences are not covered. A complete new campaign needs its own bookends; these are
      likely special-cased rendering paths that must be located. *Confidence: MEDIUM. Lower
      priority (cosmetic bookends). Owning doc: a new subsection of CUSTOM_CUTSCENES /
      DATA_STRUCTURES once found.*

- [ ] **E6 — Text / script capacity at full-campaign scale.**
      The dialogue compiler is specced (Phase 2: auto-wrap 18 ch, auto-DTE, page-split,
      two-level table emission, multi-bank spill). What is NOT validated is total capacity for
      a full new script across the four script banks (`$0C-$0F`) and the text banks — i.e. an
      allocation/budget strategy so a campaign-length script *provably* fits. *Confidence:
      MEDIUM. Mostly covered by Phase 2; flag capacity-planning as an explicit acceptance test.
      Owning doc: TEXT_SYSTEM + Phase 2 `build_project.py` validations.*

**Bottom line:** for editor v1 the RE is done and the gap is formats + UI. For a *new
campaign*, **E1 (arena / gate-boss roster format) is the one true remaining
reverse-engineering gap** and the natural next Phase-D/E session; **E2** is the authoring
backbone; E3-E6 are schema / UI / capacity questions on top of largely-known mechanics.

---

## Phase F — Authorable subsystems: text, custom skills + AI, custom music
Three subsystems promoted from "parked/under-stated" to first-class after the S43
disassembly audit (PROJECT_STATE "S43"). Methodology mirrors the proven arcs
(breeding B1→B6, GFX): **prove understanding with a byte-identical round-trip
keystone first, then relocate/redirect into a free bank, then author**. One item =
one session, each with a hard acceptance test. Honest risk: **S3 and M1 are real RE**
(could expand); their downstream authoring items can't be precisely scoped until they
land. Arc 1 (text) is fully predictable.

### Arc 1 — Text re-section + vanilla-text editing (lowest risk, useful now)
Extends the `[~]` "re-section misassembled tables" item to the dialogue corpus; the
text *format* is fully known (TEXT_SYSTEM.md) and the dumpers already locate every
string, so this is mechanical + byte-perfect. Unlocks Layer-A vanilla-text edits and
yields the E6 capacity numbers.
- [x] **T1 — Text re-section keystone (bank `$47`)** ✅ S43 — resection_text_bank.py:
      69 strings, run $4174–$5b74, 5607 fake lines → labeled `db` with decoded
      comments; byte-perfect, idempotent, data-driven bounds.
      → TEXT_SYSTEM "Source re-section"; TOOLS_AND_DATA; archive: SESSION_HISTORY.
- [ ] **T2…Tn — Roll-out across `$42-$46, $48-$4B, $4E`** (one or two banks/session, same
      tool). *Accept:* each bank re-sectioned; MD5 stays `1ca6579…` after each.
- [ ] **T-author — Edit/replace a vanilla string.** A tool that rewrites a vanilla text id's
      bytes (same-size in place, or relocate to a free bank via its pointer-table entry).
      *Accept:* a known vanilla line shows new text in SameBoy; clean MD5 unchanged. Byproduct:
      the E6 per-bank capacity/budget numbers.

### Arc 2 — Custom skills, then per-skill AI (high value; one real RE gate)
Skill *effects* are a known pattern (`SkillFunctionTable $52:$4011`, **222 entries** ($00–$DD)
→ 115 handlers, dispatch `$52:$6CC7`; names `$41:$4539`); plus the now-decoded
`SkillMPCostTable $07:$570C` (u16, 999=ALL) and `SkillLearnReqTable $06:$50E0` (18B/skill).
The editor data side is captured in `extracted/skill_records.json`; the **presentation**
layer (record params, item/meat, animation dispatch) is decoded (S46, `BATTLE_SKILL_SYSTEM.md`
§7–§10). Remaining RE: the full AI weighted-pick (S3). (S2c message format done + validated 2026-06-28; S2c-anim renderer reversed + emulator-verified 2026-06-28 — see §11.)
- [x] **S1 — Skill data foundation** ✅ S44 — SkillMPCostTable ($07:$570C, renamed
      S51) + SkillLearnReqTable ($06:$50E0) decoded + FAQ-validated;
      skill_records.json (222 = 155 skill / 37 item_effect / 30 internal);
      build_skill_tables.py --selftest byte-identical; BugCut (id 215 = the
      Bug-family cut) proven 3 ways + renamed, SameBoy-confirmed; bank $52 header
      corrected ($6CC7 / 222 / 115). → BATTLE_SKILL_SYSTEM; DOC_AUDIT #12–14;
      archive: SESSION_HISTORY Part 3.
- [~] **S2 — Custom skills (ARC, not a single item).** S45 marked this "done" off a
      narrow POC; corrected (S46). The arc:
  - [x] **S2a — Alias EFFECTS POC** (S45, SameBoy-confirmed): net-new ids $DE Scorch /
        $DF Smite via commit-time templatize-to-Blaze + $db86 stash + FarSkillFork.
        Narrow (single caster, Blaze-shaped). → §1–§6; KEY_LESSONS S45; archive: SESSION_HISTORY.
  - [x] **S2b — Record-table round-trip + presentation foundation** (S46,
        byte-neutral): record table $54:$4013→$41CF (222×19B) decoded, FAQ-validated
        field map, re-sectioned to `db` in bank_054; item-effect/meat system; animation
        dispatch located. → §7–§10; archive: SESSION_HISTORY Part 3.
  - [x] **S2c — Effect MESSAGE format** (S47): bank $4c is the shared text VM;
        $dd70/71 = a packed hit/miss message-id PAIR (mode-0 two-level table
        $4c:$4019); 67/67 statically-resolved skills FAQ-validated. Tool
        decode_effect_messages.py → effect_messages.json. → §9; archive: SESSION_HISTORY.
  - [ ] **S2c-anim-cleanup — convert the verified battle-anim DATA tables to `db`/`dw` in the
        disassembly (label-only, byte-neutral). [OPEN — blocked on `$5f` map-script RE]** The
        anim tables (`$5f:$56ed/$57d5/$58bd/$58dd/$59c3/$5aa9`; `$5c/$5d/$5e` frame tables at
        `$4071`+) currently mis-disassemble as instructions. `tools/emit_anim_data_sections.py`
        emits byte-exact directives, but the `$5f` span overlaps mgbdis `Map*_Script*` labels
        (some bogus, some maybe-real) — see DOC_AUDIT #15. **Must reverse the `$5f` map-cutscene
        script accessors first** to set correct boundaries, else risk mislabeling real scripts
        or absorbing them into anim tables (a silent error a passing MD5 won't catch). The
        `$5c/$5d/$5e` frame tables have the same code/data-interleave hazard.
  - [x] **S2c-anim — Animation renderer reversed** (S47, emulator-verified): $dd68 is
        a metasprite/OAM engine; full chain skill id → $5f:$52F0 → side tables
        $58dd/$59c3/$5aa9 → routine table $58bd ($0d = no visual) → builders
        $5c/$5d/$5e; 3 presentation layers (sprite anim, sound+flash, SCY shake).
        Tool decode_battle_animations.py → battle_animations.json (45 anims).
        → §11; archive: SESSION_HISTORY Part 3.
  - [x] **S2d-audit — Skill-id bucketing map** (S48, byte-neutral): $db8a, 254 reads /
        9 banks → reduces to a small verified fork set; keystone = the record indexer
        $54:$4013 (3 sites — one fork fixes magnitude/targeting/MP/status/ai_weight +
        the enemy AI). Tool map_skill_id_buckets.py (self-checking).
        → §12; KEY_LESSONS S48; archive: SESSION_HISTORY Part 3.
  - [x] **S2d — Skill #1 MagicBurn ($E0)** (S49, user-confirmed): non-aliased,
        end-to-end — own record/handler/name + announce + animation + hit-flash +
        cast sound via clean indirection (AnnounceTemplateTable slot, $4c:$7326
        message pool, GetPresentId proxy in $5f). Per-skill recipe: **§13**.
        → KEY_LESSONS S49; archive: SESSION_HISTORY Part 3.
  - [x] **S2e — Skill #2 Tame ($E1)** (S50, user-confirmed): recruit + anti-abuse
        damage (ATK/4), single-target. New reusable infra: custom-message render fork
        ($FD → per-skill pool string) + presentation timing (note→hit sequencing).
        → §13.5 + §11.7; TEXT_SYSTEM ($FD fork); KEY_LESSONS S50; archive:
        SESSION_HISTORY Part 3. **Follow-ups split out as the next three boxes.**
  - [x] **Tame Stage 2 / SKILL EVOLVE** (S52). Crank reverted (`TameMeterTable` dw
        10/100/400 = FeedMeat/PorkChop/Sirloin; the box's "$000A = Beef Jerky" was a
        mislabel and "mirrors in bank_052" was FALSE — the vanilla cap; DOC_AUDIT S52).
        3-tier chain $E1→$E2→$E3 via `LearnLoopFork` (bank $06 loop-bound splice +
        `CustomLearnReqTable`); vanilla EVOLVE/replace semantics (prereq path);
        real MP 10/30/50 via `MPPtrFromId` fork of ALL THREE `$570C` readers;
        `AnnounceIdxFork` (vanilla table tail overlaps code at `$58E8`); upgrade-msg
        "!"-orphan fixed by `MiscText_03_Paged` repoint. *Accept variance:* natural-to-
        Slime DE-SCOPED by user ("editor lays real data" — the fork makes any species
        slot work); harness KEPT per user. Learn/upgrade user-confirmed (v34); MP
        charge + meter values + msg page-split built, NOT yet user-tested.
        → §13.6 (systems), §11.7 (blink), KEY_LESSONS S52.
  - [ ] **§13.4 follow-ups** — (a) custom-id skill-NAME insert so name-inserting
        announce templates work for ids ≥ $DE; (b) a 2nd bespoke-message render path
        beyond the single `$FD` escape. *Accept:* a custom skill using a
        name-inserting stock announce template renders correctly. → §13.4.
  - [ ] **(optional polish) Per-enemy hit-blink** — mechanism SOLVED S52 (HW captures):
        enemy is BG-DRAWN; blink = tilemap toggle, bank `$5f` entry 5, `$da83` phase →
        `$da84` sub-dispatch `$4b99` (blank `$4ba5`/enemy `$4bcb`, copy `$4e1f`).
        Implementation deferred by user ("bank it"). Plan: drive the blink phase from
        `TameGateHook` via `$da82/$da83/$da84/$da34` state injection; expect 1-2
        SameBoy iterations. Full map: → §11.7.
  - [ ] **S2f — FIELD-cast custom skill (e.g. teleport/warp).** A different code path the
        battle foundation (§13) doesn't touch yet — genuinely new groundwork. *Accept:* a custom
        field skill (warp) fires from the field menu in SameBoy.
- [~] **S3 — AI selection RE (partly answered S46).** **Found:** the per-skill AI lever is
      **record +3 (`ai_weight`)** — the enemy AI (`$57 Jump_057_7529`) walks its skill list and
      SUMS record[+3] into the score table `$dce4`, then picks weighted (Sacrifice/MegaMagic=0).
      Distinct from per-monster enemy-stats `+17..20`. *Remaining:* trace the weighted pick + how
      per-monster weights combine; confirm with a SameBoy watchpoint on `$dce4`/record+3.
      *Accept:* selection algorithm documented (MONSTER_DATA battle-AI subsec).
- [ ] **S4 — Per-skill AI authoring.** Likely easy now: edit record +3 (`ai_weight`) per skill
      (round-trips via `build_skill_tables.py`). *Accept:* changing a skill's ai_weight measurably
      shifts enemy choice in SameBoy.

### Arc 3 — Custom music (discovery-gated; longest pole)
Unparks the "custom music" line. The main GBC sequence engine + song-data format are
unreversed (the located `$08:LoadAudP` is only the SGB-packet path; song data lives in
banks `$61 $62 $63 $65 $66 $68 $78 $7b $7d`, reached as DATA via the engine's bank-switch,
e.g. `$08` → `$78`). Fire M1 early so its unknowns surface before they block anything.
- [ ] **M1 — Audio engine + data discovery (RE, no patch).** Trace the per-frame channel
      driver (`rNRxx` writes), the song table (track id → data + bank), and the sequence
      command format; pin each song's data range. *Deliverable:* a `SOUND_SYSTEM.md` reference
      doc (precedent: GATE_GENERATION.md — confirm with user before adding) + a song enumerator.
      *Accept:* songs listed with addresses; format documented; one known track decodes to its bytes.
- [ ] **M2 — Song round-trip keystone.** Decode all songs to a spec; re-emit byte-identical.
      *Accept:* `--selftest` byte-identical; MD5 unchanged.
- [ ] **M3 — Custom song authoring.** Author/edit a track into a free bank; redirect the
      song-table entry. *Accept:* a custom track plays in SameBoy.

**Recommended order:** T1 ✅ → S1 ✅ → S2a–S2e ✅ → **Tame Stage 2 ✅ (S52 — four
custom skills live, evolve chain proven)** → S2f (field
skill) / S3 → S4 → M1 → M2 → M3 / T2 roll-out, slotting text roll-out into spare
sessions. Fire the two RE discovery sessions (M1, S3) before their authoring items
depend on them.

---

## Phase N — Add NEW monster species (ids 224–255, 32-slot budget)
User goal: add brand-new monsters *on top of* the existing 221 (not reskins of
existing slots). Scoped Session 28. Architecture: **high-table + single forked
loader, vanilla 0–220 byte-identical** (full detail in MONSTER_DATA "Species ID
geography"). Species id is a byte → first free id **224 (`$E0`)**, budget **32**.
Beyond 32 needs 16-bit ids everywhere (avoid).

- [x] **N1 — Scope + slot map** (S28): 256-slot species map (map_species_slots.py,
      self-checking); single indexers verified; slot geography 215–219 special /
      220–223 empty / 224–255 free. → MONSTER_DATA "Species ID geography"; archive: SESSION_HISTORY.
- [x] **N2 — Info-table fork (keystone)** (S29/S30, SameBoy-confirmed): SaveMon_4446
      forked zero-shift, id≥224 → bank $6A high table; ids 0–220 byte-identical;
      tool-owned (build_new_species.py ← new_species.json). → MONSTER_DATA; archive: SESSION_HISTORY.
- [x] **N3 — Enemy stats: NO fork needed** (16-bit EID; EID 518 @ $14:$7EB3, bank
      trailing free); wild-encounter wiring tool-owned (same-size EncounterPoolData
      edit, validates the slot was empty). SameBoy-confirmed. → MONSTER_DATA; archive: SESSION_HISTORY.
- [x] **N4 — Sprite + palette, BAKED** — follower half = **G1** (S34: all-8-copy
      gfx-ID fork, attr-overshoot fixed at root, clean-attr mask $B8, art stored
      un-flipped); battle half = **G2** (S35: $2b9f same-size repoint → $7e01;
      HighBattlePal fork in $17 filler tail). User-playtested OK.
      → MONSTER_DATA "NEW species followers" / "NEW species battle sprite";
      KEY_LESSONS S35; archive: SESSION_HISTORY Part 3.
- [x] **N5 — Name / joinability / breeding / library wiring** — DONE S32,
      user-tested: all 3 breeding paths (result append; parent via the forked $0301
      loader; display via FamilyRecipeResolve); hatch crash fixed
      (FollowerArtResolve0b, bank $0b); default-nickname/narration overshoot fixed
      (LoadModeBaseRedirect @ ROM0 $00F0 → short-name "Gorb" @ $41:$7FF9). Lineage
      parent-name line fixed S38 (HighModeTable4D mode-0 → "Snaily   BattleRex",
      two fixed 9-char fields). → BREEDING_SYSTEM; MONSTER_DATA; TEXT_SYSTEM;
      archive: SESSION_HISTORY Part 3.
- [x] **N6 — Top-range gates: NOT species gates** (S31): the 4 cp-ladder sites branch
      on $db8a (a skill/effect id, never a species byte) — false positives; no patch.
      → MONSTER_DATA "Species ID geography" N6; DOC_AUDIT; archive: SESSION_HISTORY.
- [ ] **G3 — new_species.json schema fold (the last open new-species item).** One
      JSON drives EVERY Gorbunok artifact (info, enemy stats, encounter, name,
      short-name, library, breeding, **the real description string** — line 2 still
      reuses Dracky's $60BC placeholder — and the art hooks) through
      build_new_species.py; reproducible from the clean tree. *Accept:* rebuilding
      from the JSON alone reproduces the current baked state byte-for-byte; the
      hand-staged pieces are deleted.
