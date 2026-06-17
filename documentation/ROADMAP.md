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

### Phase 1 — Remaining primitives (1 session each; ordered by editor impact)
- [x] **Script-driven teleport** — exit-based room transitions already
      work in all directions (vanilla↔custom, custom↔custom — proven in
      v23). Opcode **$0F** (MapTransitionFull) **confirmed working** from
      custom scripts — tested vanilla (Castle) and custom ($6B) destinations.
      Note: $0E is BranchByScreen, NOT teleport (bank $04 inline comment
      at $59D2 was wrong, fixed). $0F writes gate_id → $C96D, flag → $C96E,
      spawn XY → $C96F-$C972, sets wIsPlayerChangingMaps=1.
      Format: `$FF0F <gate_id:flag> <spawnX> <spawnY>` (3 word params).
- [x] **NPC show/hide by flag** — mechanism IS the step system
      (ROOM_DATA_FORMAT.md "Room State System"): multiple step entries
      per screen with different NPC lists, step counter set by opcode
      $12 (WriteRAM $D9xx). **Implemented and confirmed in-game (v25)**:
      CustomPtrChase now reads RAM step counter and indexes by ×6
      (was always returning step 0). Room $6C screen 0 has 2 step
      entries — Gatekeeper NPC at step 0 (advances counter via opcode
      $12) replaced by Guard NPC at step 1. Verified: NPC changes on
      re-entry after WriteRAM sets counter. Step counter addresses
      moved from event-flag collision zone ($D9A0-$D9A2 = flags
      $0028-$003F) to safe range $D478-$D47B. Note: $D478+ not in
      SRAM save range — step progress resets on power cycle; for
      persistence, use event flags + room-entry flag checks.
      *Accept*: NPC appears only after custom flag/step is set; verified
      after room re-entry. ✅
- [x] **BGM change** — opcode $41 (SetBGM) **confirmed working**.
      Saves current BGM to $C8B6, plays new track from param.
      Track IDs in known_RAM_map ($C8B5). Tested: Arena ($1E) in
      custom room; reverts on room exit.
- [x] **Monster/egg give** — opcode $29 (AddMonster) **confirmed working**.
      Takes 1 param (enemy_stats_id). Opcode $28 (CheckStorageFull)
      branches when all 20 slots full. Egg give proven with SkyDragon
      (EID 350, same as Farm event) — egg appears at farm, hatches
      correctly (minor cosmetic glitch on hatch). Direct monster give
      (EID 1) creates a withdrawable monster but species/stats don't
      fully initialize without `$FF04 $000F` preamble. Egg path is
      the practical choice for custom content.
      AddMonsterWrapper needed in bank $04 padding (bare `ret` →
      wrapper + `jp ScriptExecContinue`, same fix as GiveItem $2A).
- [x] **Custom tile LAYOUTS** (compressor done): place compressed layouts
      in a free bank, point step_entry byte 1 at it.
      **Done.** `tools/tile_layout_compiler.py` compiles 20×16 visible
      tile grid → 32×16 padded → LZSS compressed → ASM db statements.
      Bank $64 holds custom layout data with pointer table at $4001.
      Room $6B step entry uses `db 0,$64`. Tileset switching via
      MapIDClampForPalette in ROM0 (currently $04=Farm). User-designed
      layout confirmed in-game. Standalone HTML editor with 170 rooms
      and 85 tilesets delivered (towards_editor/). Spawn position for
      Room $6B is in Exit_GreatTree_s8 (bank_00b.asm), currently (7,6).
      *Accept*: custom room renders a layout that exists nowhere in the
      original ROM. ✅ Confirmed in-game.
      **Known issue (FIXED v28)**: palette attributes were per-position,
      causing color mismatches. Fixed by CustomAttrCheck intercept in
      bank $17 free space ($6C75): for Room $6B, bypasses vanilla attr
      lookup and decompresses custom nibble-packed attr data from bank
      $64 entry 1. Attr data generated by `tools/generate_attr_map.py`
      which builds tile→palette maps from ROM for any of the 85 tilesets.
      Collision threshold table at ROM0 $26E3 uses ×8 stride (not ×1).
      Multi-tileset HTML editor delivered (towards_editor/) with
      walkability overlay, variable-size stamps, marker management,
      tileset names, and full source-mapping export.
- [x] **Custom tile GRAPHICS**: palette attribute intercept DONE (v28).
      Single-tileset rooms fully working (tileset switch + correct palettes).
      **Multi-tileset mashup: WORKING (Session 7, refined Session 8).** Full pipeline:
      editor → JSON export → `build_combined_tileset.py` → ASM patches → ROM.
      **Session 8 critical discoveries and fixes:**
      - **4 palette groups max** (not 8). BG slots 4-7 reserved by game engine
        for monster display (4/5/6) and menu text (7). Verified: all 85 DWM1
        tilesets use max group 3. CustomPalCheck changed B=$08→$04.
      - **Gate detection in banks $06/$07**: mapID≥$50 whitelists treated custom
        rooms as gate-like (blocked saving, wrong menu state). Fixed with
        same-size `ld a,[wMapID]`→`call MapIDClampForPalette` patches.
      - **Ghost NPC**: spawn point script_id=$01 was talkable. Fixed to $00.
      - **Build automation**: `--build OUTPUT.gbc` flag added to
        `build_combined_tileset.py` (patches palette+threshold, builds ROM,
        restores tree). **Validated Session 9** — end-to-end pass with
        3-tileset test export (MedalMan+NORDEN+Farm).
      - **Editor**: PalGrp toggle shows palette group per tile (P0-P3 custom,
        S4-S9 system). Counter shows X/4. Export warns if >4.
      *Accept*: custom room shows tiles cherry-picked from 2+ source tilesets. ✅
      **Session 9 fixes:**
      - Editor tileset PNGs regenerated with runtime-correct palettes from
        `room_palettes.json` via new `regenerate_tileset_pngs.py` tool (86
        tilesets, all verified). ROM step-entry palette data is encoded (not
        raw RGB15) — was causing wrong colours for Starry Shrine and others.
      - Force-preview toggle ("Frc" button) added: swaps between runtime view
        ($6BFF at colour index 1) and marker-tint view (light cyan at index 1).
      - KEY_LESSONS corrected: "bit 15 set" palette claim was wrong — actual
        issue is that ROM palette bytes are always transformed at runtime.
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
- [x] **Random encounters in custom rooms** — ✅ PROVEN (Strategy A,
      Session 11; runtime-verified in SameBoy). The blocker assumption was
      wrong: encounters are NOT gated by `wInGateworld`. They are gated
      per-step by a hardcoded mapID whitelist in `$0B:Jump_00b_4674`
      (`$53`,`$54-$56`,`$57-$59`,`$61-$64`); non-whitelisted normal rooms
      `ret` before the encounter step. **Recipe:** (1) add the custom mapID
      to that whitelist → enables battles; (2) the pool is
      `GateBasePoolIndex[wGateID]+floor` resolved at battle time, so a
      non-gate room must pin `wGateID`/`wCurrentFloor` (done every step in
      ASM — they're read only when a battle fires) and (3) arm
      `wEncounterCounter` from the room-entry script (vanilla skips seeding
      when `wInGateworld=0`). Trigger chain: counter underflow → `rst $10`
      bank $01 entry $0b (`EncounterMonsterSelect`) → `set 6,[wGameState]`.
      *Verified*: Room $6B, gate 0/floor 1 → pool 0 (Slime/Anteater/Dracky);
      `$C935=00 $C939=01 $CA38=00`; win+flee return intact, saving works.
      Full docs: DATA_STRUCTURES "Encounter Runtime Flow", CROSSBANK_ROOMS
      "Random Encounters in Custom Rooms", KEY_LESSONS Session 11.
      **Remaining → moved to Phase 2 (editor):** #1 per-room on/off + gate/floor
      table; #2 fully custom monster pools in a free bank. Both specced in
      CROSSBANK_ROOMS.md.
- [ ] Custom music — parked; sound engine unexplored, BGM-change suffices
      for v1 stories.

### Phase 2 — Content format & compiler (the editor backend)
> **Plan LOCKED Session 13.** Full architecture, four-layer schema, the
> table-driven keystone, the debug manifest, the Milayou bifurcation, and the
> monster-sprite pipeline are all specced in **EDITOR_DESIGN.md**. Canonical
> bank reservation in PROJECT_STATE.md. Build order below; do the keystone (M0)
> first — it unblocks everything.
- [x] **Editor architecture & project schema (DESIGN)** — done S13 (docs only,
      no ROM). Four layers (world/custom/gamedata/build), table-driven dispatch
      keystone, manifest, bank map, sprite pipeline. See EDITOR_DESIGN.md.
- [ ] **M0 — Table-driven custom-room dispatch (keystone).** Add `CustomRoomTable`
      in bank `$6A`; convert hardcoded per-room sites (`MapIDClampForPalette`
      `cp $6C`; encounter `cp $6B`; `CustomAttrCheck` exact match) to same-size
      table lookups keyed by `wMapID−$6B`. *Accept:* Room $6B byte-identical in
      behavior (regression) AND a 2nd custom room reachable/walkable added **by
      table row alone** — zero new hardcoded patches. Test ROM. (EDITOR_DESIGN §2.)
- [ ] **`tools/extract_project.py`** — vanilla ROM → `world` layer (§5). Uses
      existing dumpers. *Accept:* extract→build round-trips byte-perfect
      `1ca6579…`; verifier PASS. This is the regression baseline.
- [ ] **`tools/build_project.py`** — project → bank_060.asm (+multi-bank spill
      per the reservation) → make → ROM, **deterministic**, emits
      `build/manifest.json` (symbols, mapID→row, free-space accounting, flag map,
      hash) + `.sym` + SameBoy warp helper. KEY_LESSONS rules become hard
      validations incl. **orphaned-trigger detection**. (EDITOR_DESIGN §3,§6.)
- [ ] **Regression baseline**: v23 content re-expressed as `example-project/`,
      diff behavior. *Accept*: same rooms/NPCs/dialogue/item-give from generated asm.
- [ ] **Bifurcation** — repoint the dresser exit (`$2F`) → Milayou's first custom
      room; strip the Terry-recruitment intro cutscene. *Accept:* new game starts
      in Milayou's room, walkable; no leftover Terry intro. (EDITOR_DESIGN §1.)
- [ ] **Preserved-systems flag audit** — for the six islands (give-first-monster,
      Arena `$06/$07/$5D/$5E`, Starry Shrine `$09/$08`, Library `$12/$13`, Vault
      `$0F`, Shops `$50`): trace flag dependencies, decouple from vanilla
      story/arena gating, satisfy-or-strip. *Accept:* each island reachable &
      functional from Milayou's world without the vanilla story spine. SameBoy.
- [ ] **Encounters #1 — per-room toggle** (proven Strategy A): folds into
      `CustomRoomTable` (enc_enable/gate/floor fields) — the hardcoded `cp $6B`
      seed becomes a row read. Project fields: `encounters`, `gate_id` (0-31),
      `floor`. Spec in CROSSBANK_ROOMS.md.
- [ ] **Encounters #2 — custom monster pools**: 26-byte pool in a free bank +
      intercept of `EncounterMonsterSelect`'s pool fetch for custom mapIDs (or
      reuse a verified-unreferenced pool slot). Project fields: up to 5
      `{enemy_stats_id, weight}` + header template. Spec in CROSSBANK_ROOMS.md.

### Phase 2C — Monster sprite replacement (DWM2 rips; designed S13, see EDITOR_DESIGN §7)
Replace (not add) DWM1 species' graphics with DWM2 rips — battle (large) +
overworld (walking) sprites. Sprites are LZSS-compressed in banks ~`$30`–`$3A`.
Reuses the `build_combined_tileset.py` 2bpp/≤4-palette pipeline + LZSS codec;
oversized sprites relocate to reserved overflow banks `$7E`–`$7F`.
- [ ] **C0 — Locate the monster→sprite pointer table** (confirm single-level /
      repointable). *Flagged S13.* *Accept:* table found, an entry's bank:addr
      verified to decompress to the expected sprite.
- [ ] **C1 — Per-monster sprite dimensions** (battle + overworld frame counts/
      sizes = the conversion target). *Flagged S13.* *Accept:* dimensions dumped
      for a sample monster, cross-checked by rendering.
- [ ] **C2 — Replacement spike**: swap ONE DWM1 monster's sprites for a DWM2 rip
      (Water/Material sheets supplied). *Accept:* the new sprite shows in-game
      (battle + overworld) in SameBoy; clean build still `1ca6579…` for the
      untouched tree; verifier PASS. Test ROM.
- [ ] **C3 — Editor SpritePanel**: "import sprite sheet → assign to monster slot"
      on the shared PNG-import flow (same as custom room tilesets).

### Phase 2B — Breeding overhaul & extension (specced Session 12; see BREEDING_SYSTEM.md)
Keep 10 families. Defaults rewritten; special recipes extended to 1×–2× (→~1650).
Mechanism ROM-verified: relocate special table + scanner to free bank `$69`,
call via `rst $10`; rewrite family table in place (result = slot index, so the
compiler inverts `A×B→C` to slot order and rejects positional conflicts); bank
$16 edits same-size only (leave vanilla tables dead-in-place).
- [ ] **B1 — Round-trip encoder (keystone).** `tools/build_breeding.py` decodes
      + re-emits BOTH vanilla tables. *Accept:* `$4974`+`$4B30` byte-identical to
      ROM; clean build still `1ca6579…`; verifier PASS. (Decoder half done S12.)
- [ ] **B2 — Relocation harness.** Bank `$69` scanner + special table mirrored
      there; bank $16 redirected via `rst $10`; vanilla tables left in place.
      *Accept:* breeding identical to vanilla (regression) in SameBoy; saving OK.
- [ ] **B3 — Capacity 1×–2×.** Raise special capacity to ≥1650; add recipes past
      index 825. *Accept:* a recipe at index >825 fires in-game.
- [ ] **B4 — Defaults rewrite.** New family×family map compiled in-place;
      positional-conflict validation. *Accept:* 8–10 sample crosses give NEW
      results in SameBoy; untouched crosses unchanged.
- [ ] **B5 — Full overhaul spec.** Complete `special`+`family_defaults` authored,
      compiled, test ROM for playtesting. *Accept:* user playtest sign-off.
- [ ] **B6 — (companion) family reassignment + ??? → "Mecha".** Same-size family
      byte edits (offset $00) + name/flavor text. *Gate:* SameBoy check that
      family 9 isn't special-cased outside breeding (boss-ness likely from boss
      table `$14:$4897`, not the family byte).

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
