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

- [x] **B4 — Family-defaults rewrite.** New family×family map compiled in-place
      (family table `$16:$4974`, same length = zero shift; result = slot index, so
      the compiler inverts `A×B→C` to slot order and rejects positional conflicts;
      preserve the `$FA` wildcard + two-pass search). *Accept:* 8–10 sample crosses
      give NEW results in SameBoy; untouched crosses unchanged. *Note:* family
      table is strictly 1:1 (one cross per result species, no many→one) — put
      flexible/many→one family×family in the SPECIAL table instead (works now).
      **DONE (Session 16, user-confirmed in SameBoy).** `build_breeding.py --emit-family`
      reads `extracted/breeding_family_defaults.json` (positional `result→{p1,p2}`
      overrides), applies them to the vanilla family decode, validates positional 1:1 +
      444-byte zero-shift + shadow classes, and rewrites only the `FamilyRecipeTable` db
      block in `patches/bank_016.asm`. Authored proof set (zero-collateral permutation of
      the three Dragon-mate matchers + one NEW recipe at empty separator slot 37):
      Bird×Dragon→DrakSlime, Slime×Dragon→Almiraj, Beast×Dragon→Wyvern,
      Dragon×Dragon→GreatDrak. **5 changed bytes total** in bank `$16` (focused diff vs the
      B3 ROM = those 5 + 1 checksum byte; the B3 baseline rebuilt as the recorded `f1cd94b1…`).
      User-confirmed: FunkyBird×BattleRex→DrakSlime, Snaily×BattleRex→Almiraj,
      Dragon×Dragon→GreatDrak (patched ROM `caa597d1…`; clean build still `1ca6579…`).
      Beast×Dragon→Wyvern is present but correctly shadowed for MadCat by SPECIAL entry 187
      (MadCat×BattleRex→Yeti) — precedence, not a bug. Untouched BattleRex×Healer→DragonKid
      (vanilla family slot 20) unchanged. Method + precedence: KEY_LESSONS "Session 16".
- [x] **B5 — Full special-table authoring + overhaul spec.** Extend
      `build_breeding.py` to own the WHOLE special table as authored data (base +
      overrides + appends) and emit it to bank `$69`, leaving bank `$16` fully
      dead; supports edit-in-place of any base entry (e.g. **replace Yeti** =
      change entry 187 result byte) and append. Includes a precedence/shadow
      validator (first-match-wins across the whole table). Author the complete
      `special` + `family_defaults` (incl. Spirit-as-a-breedable-family), build a
      test ROM. *Accept:* user playtest sign-off on the rewritten recipe set.
      **DONE (Session 17, user-confirmed in SameBoy).** `build_breeding.py
      --emit-special` decodes the 825 vanilla entries from the ROM as the base,
      applies `overrides` (edit any entry, by `index` or by parent `match`) and
      `appends` from `extracted/breeding_special.json`, runs a whole-table
      first-match-wins shadow validator (ERRORS on a shadowed append/override;
      WARNS on new collateral shadowing and on a result-species change that other
      entries still produce), and emits only `patches/bank_069.asm`. Bank `$16`'s
      special table stays byte-identical to the ROM (single source = JSON → bank
      `$69`). Self-checks: emitted == authored bytes + `$FF`; untouched base ==
      vanilla; overrides present at their indices; capacity ≤ 1650. Proof
      (confirmed): MadCat×BattleRex → **DracoLord** (in-place edit of entry 187,
      was Yeti), Darkdrium×BattleRex → **Armorpion** (unshadowed append),
      Anteater×BattleRex → GoldSlime both orders (S12 carried forward as overrides
      at dead entries 693/803). Patched ROM `c95f62ce…`; clean build still
      `1ca6579…`. **Supersedes B3's `--emit-relocation` + `breeding_extra_recipes.json`
      as the canonical bank `$69` emitter.** *Note:* the spec carries `base`,
      `overrides`, `appends`; this is the editor's emit backend — the actual recipe
      REWRITE (Spirit-as-breedable, new results across the board) is authored by hand
      in the editor UI later (B5 delivers the machinery, not the content).
      *Folded into `verify_integrity.py`? No — see B3 open follow-up; the tool
      self-asserts, the verifier does not yet run `--emit-special` self-checks.*
- [~] **B6 — Family reassignment + ??? → "Spirit".** Same-size family-byte edits
      (offset $00 of each 43-byte monster-info entry `$03:$4461`).
      **REASSIGNMENT DONE + reader-gate CLEARED (Session 18, user-confirmed in
      SameBoy).** `tools/build_family_reassign.py` (spec
      `extracted/breeding_family_reassign.json`, validated `from`==vanilla) emits
      `patches/bank_003.asm` as exact-line db edits (zero shift). Monsters move
      between ANY families incl. in/out of ??? (Boss=9). **Reader trace (the gate)
      cleared:** family-byte readers outside breeding are DISPLAY/struct-copy only
      (bank `$01` battle copy, `$04` FamilyTextPtrTable text dispatch, `$07`
      sprite/icon, `$09` VRAM index, `$14` recruit stamp); none gate scout/recruit/
      AI/resistance on family==9 — eligibility is the enemy-stats joinability byte
      (`$14 +$3`) + boss table (`$14:$4897`), independent. Annotated inline at bank
      `$03` `label443f`. **Three family representations found** (BREEDING_SYSTEM
      "B6"): breeding=live byte; status/menus=struct +$0A stamped at creation
      (snapshot — pre-existing monsters keep old value, correct for a fresh hack);
      library=id-range (see below). **Dynamic library PROOF OF CONCEPT done**
      (`patches/bank_012.asm`, `tools/build_dynamic_library.py`): `SetItem_6242`
      redirected to a family-byte scan; all 8 reassigned monsters group correctly
      in SameBoy. POC only (lags ~221 far-loads/render; bearable). *Still TODO,
      split out below:* the ??? → "Spirit" RENAME (the doc's old `FamilyTextPtrTable`
      entry-9 claim was WRONG — that's a per-family monster-text dispatch, not the
      family-name string; find the real string first); the production library table;
      the 11th-family feature.
- [x] **B7 — Production library grouping table (replaces the B6 POC).**
      **DONE (Session 19, user-confirmed in SameBoy — zero lag, reassigned monsters
      under correct tabs).** `tools/build_library_table.py` emits a precomputed
      **family→members** table into bank `$12` trailing free space (`$7B9B+`) at build
      time and rewrites `SetItem_6242` zero-shift (`jp LibScanByFamily`, 82-byte body →
      `jp` + 79 `nop`). The walker reads the table directly — **zero far-loads, zero
      scratch RAM** (the POC's two costs eliminated), and restores vanilla blank-slot
      semantics ($E0 for unseen / id for seen) the POC had dropped. Table format is a
      pointer table + length-prefixed member lists (additive for an 11th family);
      family assignment sourced from the vanilla family byte + `breeding_family_reassign.json`
      (the SAME spec `bank_003`/B6 consumes, kept in lock-step). Build-time validation:
      `--selftest` proves no-reassign grouping reproduces the vanilla bounds table
      exactly (parity); every family ≤ buffer capacity (32); free-space fit; ids ≤ 255.
      Data deliverable `extracted/library_grouping.json`. **Extension-aware (no hardcoded
      221):** species ids are 1 byte (256-ceiling); `COLLECTIBLE_MAX` (→255) and
      `NUM_FAMILIES` (→11, B9) are the only knobs — table + walker are already count/id
      agnostic. The 6 special non-collectible entries (215–220: TERRY? story enemy +
      4 summon tiers + 1 blank) are enumerated and PROTECTED (excluded, never a
      reassignment target). Test ROM `065943f6…`; clean build still `1ca6579…`. Method:
      KEY_LESSONS "Session 19 — Breeding B7"; format: BREEDING_SYSTEM "Dynamic library
      → PRODUCTION (B7, done)". *Open follow-up:* tool not yet folded into
      `verify_integrity.py` (self-asserts via `--selftest`; the verifier does not run it).
- [~] **B8 — ??? → "Spirit" rename (10 families, no insert).** **PREREQ SOLVED
      (S20):** the "family name" is an ICON font tile, not a string — there is no name
      string to edit (`FamilyTextPtrTable` confirmed a red herring). 10 icons at
      `$4F:$4110-$41A0`, text bytes `$10-$19`, addr = `$4010 + byte*16`; detail line is
      `<$F0><icon>"family"` (bank `$4D`), tab strip blits the same tiles. So a
      rename-only is "swap the `$19` (???) icon tile." **NOT the chosen route** — per
      the S19/S20 user decision Spirit is ADDED (B9), not a 10-family replace; this row
      stays as the solved-trace record. *Accept (if ever taken):* the ??? tab shows the
      new icon; clean build still `1ca6579…`.
- [~] **B9 — Add an 11th family (keep ??? AND add Spirit).** **VRAM CORRUPTION FIXED +
      ICON SHIPPED (2026-06-19, user-confirmed in SameBoy; built ON TOP of the gate fix).**
      The family-10 catch→map VRAM wipe is fixed (`ClampFamIdx` in ROM0 clamps the
      10-entry family-indexed GFX table `01:$4BAD` so family 10 can't read OOB; the
      species-indexed `$499D`/`$49DF` follower lookup is left alone). The Spirit whip
      (option 5) ships on font byte **$19 (`$4F:$41A0`)**, overwriting vanilla ??? — NOT
      the free $1A slot, which the menu blanks at runtime. Followers, library grouping,
      and family attribution confirmed correct; clean build `1ca6579…`; integrity PASS.
      See KEY_LESSONS "Spirit B9 Lessons" + PROJECT_STATE (2026-06-19 block). *Remaining
      polish (not blocking play):* the "$1A vs $19" line in the S20 notes below is stale;
      tab-strip/nav-grid layout for an 11th visible tab is the only open UI nicety.
      ~~**ICON HALF DONE (S20,~~
      pending SameBoy sign-off).** The family-icon path is traced (see B8) and the 11th
      icon's free slot is found: **byte `$1A` → `$4F:$41B0`** (blank filler; charmap
      "20-23 are blank"). `patches/bank_04f.asm` inserts the user's "Fire Whip Spirit"
      art there as a same-size 16-byte 2bpp tile (zero shift; bank `$4F` otherwise
      byte-identical to vanilla). Tool `tools/build_family_icon.py` + data
      `extracted/family_icons.json` (Variants A/B: head on palette index 0 for a yellow
      head if the menu palette allows, else index 2). Verifier PASS 4/4 (bank_04f added
      to patch set). Test ROM `ab59c842…`; clean build still `1ca6579…`. **STILL OPEN
      (rest of B9, next session):** (1) confirm the "yellow head" palette in SameBoy
      (menu BG pal via `LoadGBCPalettes`→`rst $10` `$17:$03`); (2) wire Spirit as
      family 11 — the `$4D` detail line (`$F0 $1A "family"`), the tab-strip 11th cell
      (`LoadItem_4241` `b=5,c=10` grid + tab graphics), the family-code (`$FA` wildcard
      question), `NUM_FAMILIES`→11 in `build_library_table.py`, family reshuffle. Icon
      is not yet referenced by any family, so view it via SameBoy's VRAM viewer until
      wired. Scope (full): BREEDING_SYSTEM "Family icons (B8/B9)" + "Future — 11th family".
      *Decision (user, S19/S20):* Spirit is ADDED as the 11th family, then families
      reshuffled.
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
- [~] **Re-section misassembled data tables → labeled `db`/`dw`.** mgbdis decoded
      many in-bank DATA tables as fake instructions (`rst $38`, `db $fc`,
      `ld hl,sp+$nn`, stray `stop`, etc. appearing mid-routine). These pass the build
      (bytes are identical) but READ as garbage code, so a future session can't edit
      the table in source and wastes time re-deriving it from raw bytes — it bit S18
      (the library bounds table) and earlier ($0B sprite/gate tables, fixed S14).
      Convert each to a labeled `db`/`dw` block; **the build MUST stay `1ca6579…`**
      after each (a wrong split changes bytes → fails instantly — same guard as the
      S14 labelization rule, KEY_LESSONS). Drive this by what the editor must EDIT,
      not completionism. *Accept:* targeted tables read as `db`/`dw` with names; MD5
      unchanged; the editor can address them by label.
      **DONE (Session 26 + Session 27): bank `$12` library/family data — COMPLETE.**
      `tools/resection_library_tables.py` converted `LibraryFamilyTabBounds` (`$6294`,
      the S18 case), the two tab-column cursor-position tables (`$564a`/`$5a8e`), and
      the **entire contiguous window-draw layout run `$710c..$7b9b` (29 layouts)**.
      Session 26 did the directly-referenced subset (`$710c/$71aa/$71f4`/`$759a`/`$7b42`/`$7b6c`);
      **Session 27 finished the two remaining contiguous gaps** (`$724e..$759a` = 10
      layouts, `$75c0..$7b42` = 13 layouts), including the 380-B `$79c6` full-screen
      view whose fake `jr` labels (`$7a05`…`$7aca`) vanished cleanly with their
      in-range `jr` sources. 44 raw-pointer reference sites labelized in total; the 21
      `ld hl,$XXXX; rst $10` far-call descriptors (`$5605`/`$6100`/`$6101`) correctly
      LEFT raw. Clean build still `1ca6579…`, integrity PASS 4/4. All 29 layouts also
      decoded to `extracted/library_layouts.json` (`--dump-json`). Format + addresses
      in DATA_STRUCTURES "Library / family-tab menu data (bank `$12`)". The tool uses a
      zero-byte probe-build to map source line → address (no opcode-size summing — the
      S22 trap), is per-table idempotent, and is re-runnable from the clean tree
      (verified: clean-tree run reproduces the byte-perfect build + identical 29-label set).
      **NEXT (per-session, one each):**
      (1) ✅ **Finish bank `$12`** — DONE (Session 27, above). The whole `$710c..$7b9b`
          run now reads as labeled `db`/`dw`; `$79c6` converted; far-call descriptors left.
      (2) **Tick the STALE BOXES below** — bank `$03`/`$14`/`$16` look already
          `db`-converted (`$14`/`$16` clean; `$03` has 23 `rst $38` runs to confirm as
          padding vs data). Cheap verify-and-check-off.
      (3) **Editor-driven only:** bank `$01` encounter pools → `db` (Encounters #2 needs
          to edit pools), bank `$51` transitions, bank `$50` event state machine — do
          these when the feature is built, not for completionism.
      (4) **Checked, SKIP (no editor value, mis-split risk):** the `$ff`-padding banks
          `$08/$15/$2c/$33/$55/$66` from the old seed list — verified mostly filler
          (`$08`: 2061, `$55`: 2112 `rst $38`). Not discrete tables.
**STALE BOXES (verify + tick):** the first three boxes above (bank $03 monster
table, $14 enemy stats/boss, $16 breeding) appear ALREADY `db`-converted on disk
(bank_003/014/016 are heavily `db`/`dw` with labeled loaders). Confirm against
disassembly and check them off.

- [x] **GFX-1 — Graphics system: gfx-ID indirection + sprite decompressor → annotate + tool.** ✅ DONE (Session 22)
  *DONE Session 22 — see PROJECT_STATE "Session 22" + KEY_LESSONS "Session 22" +
  MONSTER_DATA "Monster sprite graphics system". Delivered: (a) battle gfx-ID table
  `$00:$2B9F` re-sectioned to `MonsterBattleGfxTable` (`tools/resection_battle_gfx_table.py`,
  build still `1ca6579…`, 23 cross-refs preserved); (b) `dwm/sprite_codec.py` — shared
  LZ codec, decode byte-exact, `decode(encode(x))==x` on all 442 streams; (c)
  `tools/extract_monster_sprites.py` + `extracted/monster_sprites.json` (all 221,
  count-parameterised); (d) `tools/build_sprite_swap.py` generalised species-agnostic.
  ACCEPT criterion adjusted: round-trip is SEMANTIC (`decode(encode)==x`), NOT vanilla
  byte-identical re-encode (no editor value — documented). Dracky→Anteater swap
  user-confirmed in SameBoy. Doc errors below FIXED in the re-section comments.
  REMAINING (moved to editor-backend / GFX-3): cross-bank free-space allocator (swap
  tool knows bank `$36` only); follower-sprite extraction + animation-frame layout.*
  *Original verified facts (kept for reference):*
  - **gfx-ID = `(bank<<8)|index`.** High byte = ROM bank, low byte = index.
  - **Resolver `DecompressTileLayout` @ `$00:$1627`:** switches to `bank` (`ld[$2100],a`
    low bits; `swap a/rra/and 3 → ld[$4100],a` high bits — also twiddles SRAM bank,
    restored after, harmless). Reads per-bank pointer table at **`$<bank>:$4001 + index*2`**
    → stream addr in `$4000–$7FFF`.
  - **Stream header (3 bytes):** `[declen_lo, declen_hi, runmark]`, then LZ body.
    Decompressor path `WaitDMATransfer $00:$1577` → `TextScrollWindow` → writes to VRAM dest HL.
  - **LZ body:** byte≠runmark → literal; byte==runmark → back-ref: next 2 bytes `b0,b1`,
    offset = `b0 | ((b1>>4)&0xF)<<8` (**ABSOLUTE** index into output base `$ac/$ad` = VRAM dest),
    count = `(b1&0xF)+4`, extension if low-nibble=`$F` (count = next_byte + `$13`).
  - **KEY ARCHITECTURE:** back-refs point into a **SHARED VRAM tile pool pre-loaded before
    the per-monster stream**, so one monster stream does NOT decode standalone (Dracky's
    battle stream is ~9 on-disk bytes → 576 decompressed). **POC lever:** a stream with NO
    runmark byte in its body = pure literal copy = self-contained (ignores the shared pool).
    `tools/build_sprite_swap.py` (added this session) uses exactly this to repoint Dracky.
    *(Gotcha: fill the WHOLE tile field with the backdrop index, not just the sprite
    footprint — else the surround renders as palette index 0. For Dracky's battle palette
    that index 0 is red; backdrop is index 1. Fixed in the tool via `BG_INDEX`/`BODY_INDICES`.)*
  - **Battle path (VERIFIED):** `SetFld_466d` (bank `$07`, ~line 1008) reads species (`$caca`),
    indexes table at **`$00:$2B9F`** by `species*2`, DMAs to VRAM **`$8B00`**. Dracky (sp 78)
    → gfx-ID **`$3627`** (bank `$36` idx `$27`; 576 B / 36 tiles / 48×48; runmark `$02`).
    Word lives at ROM0 `$2C3B` = `27 36`.
  - **Follower path (VERIFIED):** table `ScreenTransDataTable` @ `$01:$49DF`, loader
    `GetActiveMonsterStatus` @ `$01:$4986`, index `(species+$10)*2`; plus a family-shared
    2nd load via `$01:$4BAD`. Dracky follower = gfx-ID **`$383E`** (bank `$38` idx `$3E`; 256 B / 16 tiles).
  - **DOC ERRORS to fix while annotating:** `bank_038.asm` header says "gate dungeon tileset J"
    but it ALSO holds monster follower sprites; `bank_036.asm` pointer table is labeled
    "Cross-bank dispatch table (40 entries)" but is actually the **gfx pointer table**.
  - **DISCARD (bogus):** an earlier `$382E` battle guess came from scan-tables at
    `$07:$6E14`/`$09:$6B10` that have **NO code references**; `$382E` is a dungeon tile, not Dracky.
  - **Deliverables:** labels/comments on the resolver, decompressor, pointer tables, and both
    species→gfx-ID tables; fold a proper decode/encode into the tool; extract the gfx-ID
    tables to JSON (tool ships with data). **Accept:** clean build still `1ca6579…`; tool
    round-trips a sprite byte-identically; Dracky→clam swap reproducible.

- [x] **GFX-2 — Monster palette system + recolour + cross-bank sprite backbone.** ✅ DONE (Session 23)
  *DONE Session 23 — see PROJECT_STATE "Session 23" + KEY_LESSONS "Session 23" +
  MONSTER_DATA "Monster battle palette system". Delivered: (a) `dwm/sprite_bank.py` —
  cross-bank overflow allocator (places streams in reserved `$7E–$7F`/`$7C/$7A/$79`
  with a `$4001` pointer table; resolver reads `$<bank>:$4001+index*2` with no bank
  gating, so ANY of 221 monsters repointable regardless of source bank); (b)
  `tools/build_sprite_swap.py` rewritten — cross-bank, `--relocate` (lossless proof) /
  `--png` / `--payload`, `--palette` recolour, `--build-rom` focused test ROM; (c) the
  monster battle palette SOLVED — per-species table `MonsterBattlePalettes @ $17:$62FD`
  (was mislabeled `RoomAttrDataBlocks`), 8 B/species, loaded by entry 6 (`$1706`); found
  via SameBoy BG-slot-4 dump + ROM grep; annotated in `bank_017.asm` (byte-perfect);
  (d) `tools/extract_monster_palettes.py` + `extracted/monster_palettes.json`;
  `extracted/monster_sprites.json` regenerated (all 221, was a 3-monster subset).
  Proofs (user-confirmed in SameBoy): Slime relocated cross-bank renders identically;
  DWM2 clam→Dracky battle + correct purple palette; and the full combined ROM (clam +
  Dracky→Spirit family + custom room with random encounters + breeding/library) clean.
  REMAINING (GFX-3): follower path needs `$01:$49DF` re-section + its own palette table
  (find the same way) + the family-shared `$4bad` block.*
  *Original verified facts (kept for reference):*
  - **Why needed:** the clam swap renders correctly but in Dracky's palette {red, white,
    gold/brown, black} — no purple available from tiles alone. Recolour = editing palette data.
  - **VERIFIED (probe ROM this session):** Dracky's battle palette indices are
    **0=red, 1=white/transparent (backdrop), 2=gold/brown, 3=black** (index 1 is the backdrop).
  - **Traced (speculative chain):** CGB upload routines live in **bank `$17`** (`rBCPS/rBCPD/rOCPS/rOCPD`
    writes); bank `$00` has buffers `wBGPalette/wObj1Palette/wObj2Palette` + loaders
    `SetGBCPalette`/`SetPaletteGBC`/`LoadGBCPalettes`. `SetGBCPalette(a=palID)` →(GBC)→
    `SetPaletteGBC` stores ID at `$c850`, then `ld hl,$1704; rst $10` (far-call into bank `$17`)
    does the upload from a palette table. **The per-monster/family palette SELECTION point is
    NOT yet pinned** — the battle display init (bank `$07` ~lines 1090–1180) reads family
    (`$cacb`) + species and calls `FuncFld_6942` etc.; start tracing there. NOTE the
    `SetGBCPalette` calls in bank `$07` at lines 2460/2609 are SCENE palettes (warp/gate id `$03`),
    **not** the monster's — don't be misled.
  - **NEW LEAD (Session 22, user SameBoy VRAM data):** the enemy monster's tiles use ONE
    **shared OBJ palette slot — slot 4** (confirmed: Dracky AND a blue slime both show OBJ
    attribute `04` in the VRAM viewer). So the SLOT is fixed; the per-species COLOURS are written
    into slot 4 at battle-init. This means recolour = edit the **per-species colour data loaded
    into slot 4**, NOT a slot/palette-ID assignment. Concrete entry point: `FuncFld_6942` (bank
    `$07` ~line 6567) and `SetGBCPalette` — note `FuncFld_6942` does `ld h,$04` (matches slot 4).
    Trace from there to the colour table that feeds the `$1704`/`rst $10` upload.
  - **Recolour approach (speculative):** find the palette DATA table in bank `$17` reached via the
    `rst $10`/`$1704` path, indexed by the monster/family palette ID; edit the 4 RGB555 colours,
    OR repoint selection to a custom palette. **First confirm scope** (per-family vs per-monster):
    a family palette edit recolours Dracky's whole family. **Accept:** clam renders in corrected
    (e.g. purple) colours in SameBoy.

- [x] **GFX-3 — Walking/follower sprite swap.** ✅ DONE (Session 24)
  *DONE Session 24 — see PROJECT_STATE "Session 24" + MONSTER_DATA "Follower /
  walking-sprite system" + KEY_LESSONS "Session 24" + TOOLS_AND_DATA. User-confirmed in
  SameBoy: blue dragon → DarkDrium follower, all 4 directions perfect.*
  **Delivered:**
  - **Re-section:** `ScreenTransDataTable` @ `$01:$49DF` → labeled `dw` block
    (`tools/resection_follower_gfx_table.py`; 231 entries `species+$10` + `FollowerFamilyGfxTable`
    @ `$4BAD`; build still `1ca6579…`). `build_sprite_swap.py --kind follower --payload F.bin`
    repoints + DMAs a 16-tile (256 B) self-contained literal stream.
  - **Render engine reverse-engineered:** `SaveScr_40cd` @ `$04:$40cd` (GBC variant of ROM0
    `$0d91`). Metasprite list of 4-byte **(dy, dx, tile_offset, attr)** entries, `$80`-term;
    OAM tile = `tile_offset + [$ffc9]` (follower base `$20/$30/$40` per party slot); OAM attr
    = `[$ffca] XOR attr` (X-flip bit5). 2-level table, sprite-type `$ffc7`(=`[$ca91]`) →
    frame/dir `$ffc8`. Head-mirror = two entries sharing a tile_offset, one X-flipped.
  - **OBJ transparency:** idx0 = HARDWARE-transparent for OBJ (battle BG used idx1 — opposite).
    8 OBJ palettes @ `$17:$5615`.
  - **118-layout library** (`tools/extract_follower_layouts.py` → `extracted/follower_layouts.json`):
    76 non-sharing (disjoint down/up/side → any distinct art renders clean; 202 types) + 42
    sharing (blob-only; 58 types). **Layout is per-monster, not universal** — this is why a
    symmetric blob (clam/Healer) hides layout errors and a directional dragon exposes them.
  - **Tooling:** `tools/follower_frame_picker.html` (drag 6 boxes, engine-accurate preview,
    export coords/payload) + numbered-tile calibration ROM method (each VRAM tile shows its hex
    index + flip-foot; `--palette` override = black digit / red foot for terrain legibility).
  *Original plan (for reference):*
  GFX-3 — Walking/follower sprite swap. Rides the Session-23 cross-bank backbone
  (`dwm/sprite_bank.py` + `build_sprite_swap.py`), but via the FOLLOWER path. Prereqs now
  known: (1) **re-section `ScreenTransDataTable` @ `$01:$49DF`** from mgbdis fake
  instructions to a labeled `dw` block (byte-perfect, same job as the S22 battle gfx
  table — preserve any cross-bank referenced labels), then `build_sprite_swap.py --kind
  follower` can repoint it (the tool already has the follower table wired, gated until the
  re-section lands); (2) the follower likely has its OWN palette table — find it the same
  way GFX-2 found the battle one (SameBoy dump of the follower's palette slot + ROM grep);
  (3) handle the **family-shared `$4bad` second DMA** (the B9-clamped 10-entry family GFX
  table) — verify in SameBoy whether it overlaps the swapped walk frames. Follower = 16
  tiles (`$383E` for Dracky); the 16-tile stream holds the full walk-animation frame set.

- [x] **GFX-4 — Monster → follower-layout auto-map (completes GFX-3 automation).** ✅ DONE (Session 25)
  *DONE Session 25 — see PROJECT_STATE "Session 25" + MONSTER_DATA "Monster → layout dispatch" +
  KEY_LESSONS "Session 25" + TOOLS_AND_DATA. User-confirmed in SameBoy: Healer→Dragon clone and
  Dracky→custom blue-dragon (imported art), correct all directions, consistent across overworld +
  menu + library.*
  **Delivered:**
  - Level-1 layout tables LOCATED at fixed `$10:$407f` (species 0–127) / `$11:$407f` (species 128+),
    indexed by species; per-species attr/palette table at `$10/$11:$417f`. (`[$caca]` is the SPECIES,
    not a "sprite-class" byte; bank `$05` is the ObjTest viewer path, not the follower path — both
    pre-GFX-4 doc errors, corrected.)
  - `tools/extract_monster_follower_layouts.py` + `extracted/monster_follower_layouts.json` (every
    species → layout id + addresses + sharing). `--selftest` reproduces Healer/DarkDrium anchors and
    confirms all 215 collectible species map.
  - `extracted/follower_layouts.json` REGENERATED & REPLACED — **155 complete layouts** (old 118 dropped
    the 3-entry small/blob layouts), canonical `$10/$11` addresses.
  - **8 follower-art table copies** discovered (`$01 $06 $07 $09 $0b $12 $18 $59`); a consistent swap
    must repoint all 8 (layout/attr are single/shared).
  - `tools/build_follower_reassign.py` — reassignment primitive: clone layout+art+attr from another
    same-bank monster, OR import custom 16-tile art (placed cross-bank, all-8-copies repointed) and set
    layout (default layout 0) + palette. Builds focused test ROMs; clean build stays `1ca6579…`.
  *Original plan (for reference):*
  layouts** (`extracted/follower_layouts.json`). The one remaining link is which layout each
  of the ~215 monsters uses, so the editor can (a) slice imported art into the correct tiles
  automatically, and (b) reassign a monster to a clean non-sharing layout on demand.
  **Known structure (from GFX-3):**
  - Render path: `AdjustGateFloorIndex` (`$01`) sets `$ffc7 = [$ca91]`, base `$ffc9 =
    $20/$30/$40`, calls `$0402` (`NPCSpriteLoadAlt`) → `SaveScr_40cd`.
  - `$ffc7 = [$ca91] = GetActiveMonsterStatus` return = `$01` (if bit7 of `[$cb0b]`) else
    `[$caca] + $10`. So a monster's layout is driven by its **sprite-class byte `[$caca]`**.
  - The 118 layouts are the **level-2** frame-pointer tables (6 ptrs each: down/right/up × 2),
    living in banks `$05`/`$10`/`$11`. A **level-1** table indexes them by `$ffc7`, with the
    BANK chosen by `$ffc7` magnitude (`NPCInteractDispatch` routing: `<$10`→`$04`,
    `$10–$8F`→`$10` (sub `$10`), `≥$90`→`$11` (sub `$90`)). Bank starts are code, so the
    level-1 tables are NOT at `$4000` — they must be located.
  - **TODO:** (1) locate the level-1 dispatch table(s) per bank; (2) extract each monster's
    `[$caca]` sprite-class from the monster data table; (3) compose monster → `$ffc7` → layout
    id; emit `extracted/monster_follower_layouts.json`; (4) wire into `follower_frame_picker.html`
    + `build_sprite_swap.py` so imports default to a non-sharing layout and reassignment is a
    same-size `[$caca]` edit. **Accept:** every monster maps to a layout; a distinct-art import
    on any monster renders clean (matching the DarkDrium-dragon result).

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

## Phase N — Add NEW monster species (ids 224–255, 32-slot budget)
User goal: add brand-new monsters *on top of* the existing 221 (not reskins of
existing slots). Scoped Session 28. Architecture: **high-table + single forked
loader, vanilla 0–220 byte-identical** (full detail in MONSTER_DATA "Species ID
geography"). Species id is a byte → first free id **224 (`$E0`)**, budget **32**.
Beyond 32 needs 16-bit ids everywhere (avoid).

- [x] **N1 — Scope / RE + slot map (DONE, Session 28).** `tools/map_species_slots.py`
      + `extracted/species_slot_map.json` (256-slot map, self-checking). Verified:
      single indexers (info `$03:SaveMon_4446` ×43, enemy-stats `$14:LoadEnemyStats`
      ×25 with 16-bit EID); slot geography (215–219 special, 220–223 empty, 224–255
      free); the 4 real top-range gates vs ~40 false-positive `cp $dd` hits. No bytes
      changed; integrity PASS 4/4.
- [ ] **N2 — Info-table fork (keystone).** Patch `SaveMon_4446`: id ≥ 224 → free-bank
      high-table (pick a free `rst $10` bank; breeding used `$69`, sprites `$7E–$7F`).
      Author one test species (43-B entry via a JSON tool). *Accept:* injected id 224
      loads correct 43 bytes; clean build still `1ca6579…`; verified in SameBoy.
- [ ] **N3 — Enemy-stats fork.** Fork `LoadEnemyStats` for new fight/join EIDs so the
      new species is fightable at chosen levels (append past 487; EID space is 16-bit).
- [ ] **N4 — Sprite + palette.** Repoint the **8** follower gfx-ID table copies
      (`$01 $06 $07 $09 $0b $12 $18 $59`), battle palette (`$17` free region, e.g.
      `$6C75`), follower layout/attr slot (256-wide, headroom). Reuse GFX-2/3/4 tooling.
- [ ] **N5 — Name + joinability + breeding/library wiring.** Real name ptr+string in
      `$41:$4339`; locate + mark joinable (joinability + boss table, per S18); breeding
      (`build_breeding.py`) + library (`build_library_table.py`, already 256-id-aware).
- [ ] **N6 — Verify top-range gates.** Confirm `bank_05f/057/058/052` treat ids ≥224
      as normal (the `$5f` ladder already routes ≥224 → keep). Patch any that don't.

> **S29 progress (stage1ac / Gorbunok id 224 track).** The **encyclopedia DETAIL page
> freeze** — the last blocker for the new-species *display* feature set — is FIXED
> (`TEXT_SYSTEM.md`): the text engine's mode×species double indirection
> (`SaveBankAndSwitch $092F`) overshot the 215-entry line-2 description table at
> `$4D:$420B`. Forked via `HighDetailTextFork` (`patches/bank_04d.asm`). Also fixed the
> independent 222-entry `FamilyRecipeTable` overshoot (`FamilyRecipeResolve`,
> `patches/bank_016.asm`). Detail page user-confirmed clean (mirrors Dracky), ROM
> `DWM-Gorbunok-stage1ac-v16.gbc`. Every species-indexed table and its overshoot status
> is now catalogued in `MONSTER_DATA.md` (Species ID geography).
>
> **Next steps / deferred (next session):**
> 1. **Custom Gorbunok sprite + palette** (the N4 work) — currently a DarkDrium
>    placeholder (`MonsterBattleGfxTable[224]=$320F`); follower sprite also deferred.
> 2. **Bespoke Gorbunok description string** — line 2 currently reuses Dracky's
>    (`$60BC`) as a valid placeholder; author a real string (needs font-glyph encoding
>    like the name) and point `HighLine2Ptrs[0]` at it.
> 3. **Optional: make Gorbunok breedable** — wild-only today (recipe = `$FF,$FF`); both
>    the result-path (`SpecialRecipeTable` append) and parent-path (extend
>    `FamilyRecipeResolve`) are documented in `BREEDING_SYSTEM.md`.
> 4. **Re-check N4/N5/N6 formal acceptance** against the stage1ac implementation and
>    tick the boxes whose acceptance tests are now met.
