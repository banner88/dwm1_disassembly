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
- [ ] **Encounters #1 — per-room toggle** (from the proven Strategy A): emit a
      `RoomEncTable` (mapID → enabled/gateID/floor) the whitelist hook scans,
      replacing the hardcoded `cp $6B`. Project fields per room: `encounters`,
      `gate_id` (0-31), `floor`. Spec in CROSSBANK_ROOMS.md.
- [ ] **Encounters #2 — custom monster pools**: 26-byte pool in a free bank +
      intercept of `EncounterMonsterSelect`'s pool fetch for custom mapIDs (or
      reuse a verified-unreferenced pool slot). Project fields: up to 5
      `{enemy_stats_id, weight}` + header template. Spec in CROSSBANK_ROOMS.md.

### Phase 2B — Breeding overhaul & extension (specced Session 12; see BREEDING_SYSTEM.md)
Keep 10 families. Defaults rewritten; special recipes extended to 1×–2× (→~1650).
Mechanism ROM-verified: relocate special table + scanner to free bank `$69`,
call via `rst $10`; rewrite family table in place (result = slot index, so the
compiler inverts `A×B→C` to slot order and rejects positional conflicts); bank
$16 edits same-size only (leave vanilla tables dead-in-place).
- [x] **B1 — Round-trip encoder (keystone).** `tools/build_breeding.py` decodes
      + re-emits BOTH vanilla tables. *Accept:* `$4974`+`$4B30` byte-identical to
      ROM; clean build still `1ca6579…`; verifier PASS. (Decoder half done S12.)
      **DONE (Session 13):** `tools/build_breeding.py --selftest` proves both
      tables round-trip byte-identical to the ROM slices (special $4B30 4126 B
      incl $FF; family $4974 444 B incl $0000), the `db`-text emission re-parses
      to the same bytes, and the disassembly `db` bytes equal the ROM
      (`--check-disasm`). Decode independently reconciles with the hand-authored
      `breeding_complete.json` (825/825 special, 197/197 family slots, 0 diffs).
      Data deliverable: `extracted/breeding_tables.json` (Tier A, `_generator`
      stamped). Verifier PASS 4/4; clean build unchanged. Family encoding
      confirmed positional (result species == slot index; 197 recipes + 24
      separators + 1 terminator = 222 pairs).
- [x] **B2 — Relocation harness.** Bank `$69` scanner + special table mirrored
      there; bank $16 redirected via `rst $10`; vanilla tables left in place.
      *Accept:* breeding identical to vanilla (regression) in SameBoy; saving OK.
      **DONE (Session 13):** special-table scan ($46F2–$470F, 30 B) replaced
      in-place with `ld hl,$6900` + `rst $10` + 26-byte NOP pad (zero shift);
      faithful port of the scan loop + per-entry check in `patches/bank_069.asm`
      (`db $69`, jump table, scanner, then the table). `rst $10` ABI decoded
      from ROM bytes (H=bank, L=entry<$80; far func ends `ret` → returns to the
      bank-$16 plus-clamp at $4710). Relocated table sourced from the **patched**
      `bank_016.asm` (via `build_breeding.py --emit-relocation`), so it carries
      existing custom recipes. Verifier PASS 4/4; full-ROM diff shows bank $16
      changed only in the 30-byte window. User-confirmed in SameBoy: Anteater×
      BattleRex→GoldSlime (both orders) + vanilla crosses unchanged; saving OK.
      *Note:* rev 1 wrongly sourced the table from vanilla and silently reverted
      the Session-12 recipe (parents fell through to the family table); fixed by
      sourcing from patched bank_016. The `--emit-relocation` self-check now
      asserts relocated == patched table.
- [x] **B3 — Capacity 1×–2×.** Raise special capacity to ≥1650; add recipes past
      index 824. *Accept:* a recipe at index >824 fires in-game.
      **DONE (Session 15):** the bank `$69` scanner walks to the `$FF` terminator
      with no hardcoded count, so `build_breeding.py` appends recipes from
      `extracted/breeding_extra_recipes.json` after the 825 base entries and
      re-terminates (`SPECIAL_CAPACITY_MAX = 1650`; bank `$69` fits 2× with
      headroom). Proof recipe at index 825: **BattleRex(Pedigree) × MadCat(Mate)
      → DracoLord** — user-confirmed DracoLord in SameBoy (patched ROM
      `f1cd94b1…`; clean build still `1ca6579…`). Picked because it is UNSHADOWED
      by all 825 base entries (the forward order MadCat×BattleRex is the vanilla
      → Yeti recipe at index 187, which would win first — see KEY_LESSONS S15).
      Self-checks: base 825 == patched bank_016 table; S12 recipe intact; appended
      bytes placed + `$FF`-terminated; emit-time SHADOW CHECK fails the build on a
      dead appended recipe. Focused diff: 4 bank-`$69` bytes + checksum.
      *Open follow-up:* fold "base 825 of relocated table == patched bank_016
      table" into `verify_integrity.py` so future table edits can't silently
      diverge (the tool asserts it; the verifier does not yet).

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

- [ ] **B4 — Family-defaults rewrite.** New family×family map compiled in-place
      (family table `$16:$4974`, same length = zero shift; result = slot index, so
      the compiler inverts `A×B→C` to slot order and rejects positional conflicts;
      preserve the `$FA` wildcard + two-pass search). *Accept:* 8–10 sample crosses
      give NEW results in SameBoy; untouched crosses unchanged. *Note:* family
      table is strictly 1:1 (one cross per result species, no many→one) — put
      flexible/many→one family×family in the SPECIAL table instead (works now).
- [ ] **B5 — Full special-table authoring + overhaul spec.** Extend
      `build_breeding.py` to own the WHOLE special table as authored data (base +
      overrides + appends) and emit it to bank `$69`, leaving bank `$16` fully
      dead; supports edit-in-place of any base entry (e.g. **replace Yeti** =
      change entry 187 result byte) and append. Includes a precedence/shadow
      validator (first-match-wins across the whole table). Author the complete
      `special` + `family_defaults` (incl. Spirit-as-a-breedable-family), build a
      test ROM. *Accept:* user playtest sign-off on the rewritten recipe set.
- [ ] **B6 — Family reassignment + ??? → "Spirit".** Same-size family-byte edits
      (offset $00 of each 43-byte monster-info entry `$03:$4461`) + family-name
      text (`FamilyTextPtrTable` at bank `$04:$60F4`, entry 9) + any flavor text
      (e.g. library "…and ???"). **GATE (partly audited S15):** the family byte is
      read OUTSIDE breeding — confirmed readers in bank `$01` (battle, loads both
      party monsters' family), bank `$04` (`$DA33`→FamilyTextPtrTable = family-name
      DISPLAY, intended), and skill/AI banks `$07/$09/$52–$58`. Before mass
      reassignment, trace those readers and confirm none gate **scout/breed
      eligibility or resistance/AI grouping** on family==9 (hypothesis: true
      boss-ness comes from boss table `$14:$4897`, not the family byte — consistent
      with S15 findings but NOT yet confirmed). Concrete risk: a former boss moved
      out of ??? could become breedable/scoutable, and vice-versa. *Accept:* a
      reassigned monster shows the new family name, breeds per the new rules, and
      no non-breeding system (battle/scout/resistance) regresses in SameBoy.
      *Suggested order:* B4+B5 first (proven/low-risk, independent of the family
      byte); B6 last, gated on the reader trace; the rename can ride with B6.
- [x] **BUG — breeding cutscene: parent sprites glitch.** **FIXED Session 14.**
      Observed Session 13 while playtesting B2; confirmed **not caused by B2**. Root
      cause was an incomplete bank `$0B` labelization: three raw pointer refs into the
      bank's shift region (`$4974` sprite-pointer table; `$42c8`/`$4308` gate table)
      were never converted to labels, so the custom dispatch's shift left them stale —
      and in `patches/bank_00b.asm` the sprite ref was additionally **mislabeled** to
      `RoomScreenPtrTable` (`$49b5`) instead of the real `$4974` data (`$4911`).
      Fixed by re-sectioning both tables into labeled `dw`/`db` (disassembly stays
      byte-identical to `1ca657…`) and repointing the sprite consumer. User-confirmed
      in SameBoy (clean build still `1ca657…`; patched ROM `b43a04fe…`). See
      KEY_LESSONS "Session 12 Lessons — Bank $0B repointing" and PROJECT_STATE.

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
