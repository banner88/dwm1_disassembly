# PROJECT STATE — Single Source of Truth

> **This file is the entry point for every session.** It is the only document
> allowed to state project-wide status. Other docs are subject-specific
> references and must not duplicate status claims. If this file and another
> doc disagree, this file wins — and the session should fix the other doc.
>
> Last verified: 2026-06-18 (Session 19: breeding B7 — production library grouping
> table, user-confirmed in SameBoy: zero lag, reassigned monsters under correct tabs.)
> **B7 — production library grouping (SameBoy-confirmed).** The S18 dynamic-library
> POC (runtime per-species far-load scan, ~221 loads/tab → lag + scratch RAM) is
> REPLACED by a build-time precomputed **family→members** table. `tools/build_library_table.py`
> emits the table into bank `$12` trailing free space (`$7B9B+`) and rewrites
> `SetItem_6242` zero-shift (`jp LibScanByFamily`; 82-byte body → `jp`+79 `nop`); the
> walker reads the table directly — **zero far-loads, zero scratch RAM**, and restores
> the vanilla blank-slot-for-undiscovered semantics the POC had dropped (`$E0` unseen /
> id seen; `$C8E9`=member count, `$C8E8`=seen count). Format: pointer table + length-
> prefixed member lists (additive for an 11th family). Family assignment sourced from
> the vanilla family byte (`$03:$4461+$00`, raw 0..9) + `breeding_family_reassign.json`
> (the SAME spec `bank_003`/B6 consumes — library and family bytes stay in lock-step).
> Build-time self-checks: `--selftest` proves no-reassign grouping == vanilla bounds
> table exactly (ids 0..214 → parity); each family ≤ buffer cap (32); ids ≤ 255;
> free-space fit. **COLLECTIBLE vs SPECIAL clarified (user, do not re-derive from
> "looks empty"):** ids 0..214 are collectible (library-listed); ids 215..220 are REAL
> but non-collectible combat-only entities — 215 `TERRY?` (Durran story enemy), 216–219
> the four summon-skill tiers (Tatsu/Diago/Samsi/Bazoo), 220 reserved/blank — enumerated
> and PROTECTED (excluded, never a reassignment target). **Extension-aware (no hardcoded
> 221):** species id is 1 byte → 256 ceiling; `COLLECTIBLE_MAX`(→255) and `NUM_FAMILIES`
> (→11, B9) are the only knobs. **User decision (S19): Spirit will be ADDED as an 11th
> family (B9), then families reshuffled** — not a 10-family rename. Data deliverable
> `extracted/library_grouping.json`. Test ROM `065943f6…`; canonical clean build still
> `1ca6579…`. Method: KEY_LESSONS "Session 19 — Breeding B7".
>
> Last verified: 2026-06-18 (Session 18: breeding B6 — family reassignment +
> dynamic-library proof-of-concept, user-confirmed in SameBoy.)
> **B6 — family reassignment (SameBoy-confirmed) + dynamic-library POC.** Monsters
> can be moved between ANY families (incl. in/out of ??? / Boss=9) via same-size
> family-byte edits at `$03:$4461+$00`. `tools/build_family_reassign.py` (spec
> `extracted/breeding_family_reassign.json`, `from` validated == vanilla) emits
> `patches/bank_003.asm` (exact-line db edits, zero shift). **Reader gate CLEARED:**
> family-byte readers outside breeding are display/struct-copy only (banks
> `$01/$04/$07/$09/$14`); none gate scout/recruit/AI/resistance on family==9 —
> eligibility is the enemy-stats joinability byte (`$14 +$3`) + boss table
> (`$14:$4897`). **Three family representations** (BREEDING_SYSTEM "B6"): breeding =
> live byte; status/menus = struct `+$0A` stamped at creation (snapshot — correct
> for a fresh hack); library = id-range via `SetItem_6242`/`$12:$6294` (the ONLY
> id-range family assumption in the ROM). **Dynamic library = PROOF OF CONCEPT**
> (`patches/bank_012.asm`, `tools/build_dynamic_library.py`): `SetItem_6242`
> redirected (zero-shift) to a family-byte scan in bank `$12` free space; 8
> reassigned monsters group correctly in SameBoy. POC only — lags ~221 far-loads/
> render (bearable), no RAM claim beyond one scratch byte. **Production plan (B7):
> editor emits a precomputed family→members table at build time; do NOT optimize the
> runtime POC.** Rename (B8) + 11th family (B9) split out in ROADMAP. Disassembly
> annotated (comments only, byte-perfect `1ca6579…`): `SetItem_6242`, the family-byte
> reader trace at bank `$03 label443f`. Patched test ROMs only; canonical clean build
> still `1ca6579…`. Method: KEY_LESSONS "Session 18 — Breeding B6".
>
> Last verified: 2026-06-18 (Session 17: breeding B5 — full special-table
> authoring DONE, user-confirmed in SameBoy.)
> **B5 — full special-table authoring (SameBoy-confirmed).** `build_breeding.py
> --emit-special` now OWNS the whole SPECIAL recipe table as authored data and emits
> it to bank `$69`. The base is the 825 vanilla entries decoded from the **ROM**;
> `extracted/breeding_special.json` supplies in-place `overrides` (edit any base
> entry — addressed by `{"index":N}` or by `{"match":{p1,p2}}` = first base entry that
> fires for that cross; absent fields inherit the base) and `appends` (new entries
> past 824, the B3 mechanism). A **whole-table first-match-wins shadow validator**
> replaces B3's append-only check: build-failing ERRORS on a shadowed append or a
> shadowed override; WARNINGS on an edit newly preceding a later different-result
> entry and on an override that changes a result species **other entries still
> produce** (so "edit a cross" ≠ "remove a monster"). **Single source of truth:**
> bank `$16`'s special table stays byte-identical to the ROM forever (already
> runtime-dead via the B2 `rst $10` redirect), so nothing in the shift-sensitive bank
> moves and there is one authored source + one emit target. Self-checks: emitted ==
> authored bytes + `$FF`; every non-overridden base entry == vanilla; each override
> present at its index; capacity ≤ 1650. User-confirmed in SameBoy: MadCat×BattleRex →
> DracoLord (in-place edit of entry 187, was Yeti; DracoLord id 200 used explicitly —
> two species share the name), Darkdrium×BattleRex → Armorpion (unshadowed append),
> Anteater×BattleRex → GoldSlime both orders (S12 carried forward as overrides at dead
> entries 693/803). Patched ROM `c95f62ce…`; canonical clean build still `1ca6579…`.
> **B5 supersedes the B3 `--emit-relocation` + `breeding_extra_recipes.json` path** as
> the canonical bank `$69` emitter (the old index-825 DracoLord append is replaced by
> the cleaner entry-187 edit; DracoLord still reachable, no capability lost). Method +
> rules: KEY_LESSONS "Session 17 — Breeding B5" and BREEDING_SYSTEM "Planned". The
> actual recipe REWRITE (Spirit-as-breedable, new results) is authored by hand in the
> editor UI later — B5 is the machinery, not the content.
>
> **B4 — family-defaults rewrite (SameBoy-confirmed).** The FAMILY recipe table
> (`$16:$4974`, positional: offspring species == slot index) can now be authored
> in place via `tools/build_breeding.py --emit-family`, sourced from
> `extracted/breeding_family_defaults.json` (a `result→{p1,p2}` override list). The
> tool starts from the vanilla family decode, applies only the overrides, validates
> positional 1:1 (one cross per result species) + 444-byte zero-shift + shadow classes
> (special-table family-code shadow and duplicate family matchers), and rewrites only
> the `FamilyRecipeTable` db block in `patches/bank_016.asm`. Authored proof set is a
> zero-collateral permutation of the three Dragon-mate matchers plus one NEW recipe at a
> previously-empty separator slot: Bird×Dragon→DrakSlime, Slime×Dragon→Almiraj,
> Beast×Dragon→Wyvern, Dragon×Dragon→GreatDrak (slot 37). Whole-ROM impact: **5 bytes**
> in bank `$16` + header/global checksum (focused diff vs the B3 ROM; B3 baseline rebuilt
> as the recorded `f1cd94b1…`). User-confirmed in SameBoy: FunkyBird×BattleRex→DrakSlime,
> Snaily×BattleRex→Almiraj, Dragon×Dragon→GreatDrak (patched ROM `caa597d1…`; canonical
> clean build still `1ca6579…`). Beast×Dragon→Wyvern is in the table but correctly
> shadowed for MadCat by SPECIAL entry 187 (MadCat×BattleRex→Yeti) — special > family
> precedence, not a bug. Untouched cross BattleRex×Healer→DragonKid (vanilla family slot
> 20) unchanged. Confirmed mechanics (grepped, do not re-trust): family scan does
> exact-species-immediate / family-code-last-wins with a two-pass (parent2 specific, then
> as family); `$FA` "AnyFamily" wildcard is scanner-supported but used ZERO times in vanilla
> data. Method + rules: KEY_LESSONS "Session 16 — Breeding B4" and BREEDING_SYSTEM "Planned".
>
> **B3 — special-recipe capacity extension (SameBoy-confirmed).** The relocated
> bank `$69` special table (B2) now grows past the 825 vanilla entries: its
> scanner walks to the `$FF` terminator with no hardcoded count, so
> `build_breeding.py` appends recipes from `extracted/breeding_extra_recipes.json`
> after the 825 base entries and re-terminates. Capacity ceiling `SPECIAL_CAPACITY_MAX
> = 1650` (2× vanilla); bank `$69` (16 KB) fits it with headroom. Proof recipe at
> index 825: **BattleRex(Pedigree) × MadCat(Mate) → DracoLord** — chosen because
> it is UNSHADOWED by all 825 base entries (the forward order MadCat×BattleRex is
> the vanilla → Yeti recipe at index 187, so it would win first); user-confirmed
> DracoLord in SameBoy (patched ROM `f1cd94b1…`; canonical clean build still
> `1ca6579…`). Tool self-checks: base 825 == patched bank_016 table, S12 recipe
> intact, appended bytes placed + `$FF`-terminated, and an emit-time SHADOW CHECK
> that FAILS the build on a dead (already-matched) appended recipe. Focused diff:
> 4 bank-`$69` bytes + header checksum, nothing else. Method + rule: KEY_LESSONS
> "Session 15 — Breeding B3" and BREEDING_SYSTEM "Planned: Overhaul & Extension".
> Forward plan signposted there + ROADMAP Phase 2B (B4/B5/B6) after a ??? mechanic
> audit (see below).
>
> Session 14: bank $0B repointing — breeding-cutscene glitch FIXED.
> **Bank $0B dynamic-repointing completed.** The breeding-cutscene parent-sprite
> glitch (wrong monster, correct palette) and a parallel gate-table glitch were
> caused by three un-labelized raw pointer refs into bank $0B's shift region
> (`$4974` sprite table; `$42c8`/`$4308` gate table with raw `dw` entries). Labelized
> in the disassembly first (clean build still `1ca6579…`), then ported to
> `patches/bank_00b.asm` — where the sprite ref was additionally found **mislabeled**
> to `RoomScreenPtrTable` (`$49b5`) instead of the real `$4974` data (`$4911`), and
> repointed. User-confirmed in SameBoy: breeding cutscene clean; custom rooms
> `$6B`/`$6C` + custom→custom transitions working (patched ROM `b43a04fe…`; canonical
> clean build still `1ca6579…`). No trampolines — pure dynamic repointing. Custom
> banks are 100% label-based (repointable by construction). Remaining hardcoded
> repointing refs: `$08:$7751`, `$32:$5A5F` (latent — banks not patched). Method
> + rule: KEY_LESSONS "Session 14 — Bank $0B repointing" and SESSION_PROTOCOL §4.
>
> Session 13: breeding B1 + B2 DONE.
> **B2 — special-table relocation harness (SameBoy-confirmed).** The special
> scan moved from bank $16 to free bank `$69`, called via `rst $10`
> (`ld hl,$6900`); the 30-byte scan at $16:$46F2–$470F replaced in-place with
> `ld hl,$6900`+`rst $10`+26-byte NOP pad (zero shift), falling into the
> unchanged plus-clamp at $4710. `patches/bank_069.asm` (faithful scanner port
> + special table) is generated by `build_breeding.py --emit-relocation`,
> sourcing the table from the **patched** `bank_016.asm` so existing custom
> recipes survive. Verifier PASS 4/4; full-ROM diff: bank $16 changed only in
> the 30-byte window. User-confirmed: Anteater×BattleRex→GoldSlime both orders,
> vanilla crosses unchanged, saving OK (patched ROM 868f9276…, patched-build
> artifact only — canonical clean build is still 1ca6579…). Open follow-up:
> breeding-cutscene parent sprites glitch — NOT from B2 (graphics path; B2 only
> writes result RAM), suspected pre-existing earlier-patch regression; logged in
> ROADMAP with a bisect plan. **RESOLVED in Session 14** — see top entry (it was an
> incomplete bank $0B labelization, not a breeding-path regression).
> **B1 — breeding round-trip encoder (keystone).** `tools/build_breeding.py --selftest` decodes BOTH vanilla tables
> and re-emits them byte-identical to the ROM (special $4B30 4126 B incl $FF;
> family $4974 444 B incl $0000); db-text emission re-parses to the same bytes;
> disassembly db == ROM (--check-disasm). Decode independently reconciles with
> hand-authored breeding_complete.json (825/825 special, 197/197 family slots, 0
> diffs). Data deliverable extracted/breeding_tables.json (Tier A, _generator).
> Pure tooling — no ROM change; clean build still 1ca6579…; verifier PASS 4/4.
> Unblocks B2-B6. NOTE: B1 is a tool+data keystone, not a content patch — nothing
> to playtest; acceptance is fully machine-checkable.
> Prior — Session 12: custom breeding PROVEN — special-recipe
> override Anteater × BattleRex → GoldSlime via same-size, in-place edit of two
> provably-dead table entries; confirmed in-game in SameBoy. Tool
> `patch_breeding_recipe.py` + `patches/bank_016.asm` (bank $16 added to the
> verifier patch set). Romhack-scale breeding overhaul + extension specced
> (BREEDING_SYSTEM "Planned: Overhaul & Extension" + ROADMAP Phase 2B): defaults
> rewritten in place, special table relocated to free bank $69 via rst $10 and
> extended to 1×–2× (~1650). Family table is positional (result = slot index) —
> documented. The keystone round-trip encoder B1 is now built (above).
> Prior — Session 11: random encounters PROVEN in a custom
> non-gate room (Strategy A) — whitelist mapID in $0B:Jump_00b_4674 + pin
> wGateID/wCurrentFloor in ASM + arm wEncounterCounter from the room-entry
> script. Pool fully controllable via gate/floor; win+flee return clean.)

---

## Canonical Facts (verified, do not trust other copies)

| Fact | Value |
|------|-------|
| Original ROM MD5 | `1ca6579359f21d8e27b446f865bf6b83` |
| Clean build target | MUST equal the MD5 above, byte-perfect |
| Assembler | RGBDS v0.6.1 exactly |
| ROM size | 2 MB, 128 banks ($00–$7F) |
| Custom content bank | $60 (~14.9 KB free as of v25 content, 1322 bytes used) |
| Custom layout bank | $64 (layout ptr table + LZSS layout + attr data, 309 bytes used) |
| Empty banks available | 21 banks = 336 KB: $67,$69–$77,$79–$7A,$7C,$7E–$7F |
| Verifier | `python3 tools/verify_integrity.py` — run at session start AND end |

**The MD5 `b90957482011c8083a068781033715b7` is WRONG.** It was a drifted
build produced when commits `2000e99`/`036dc06` refactored bank $0B code
(inline pointer chases → `call SharedPtrChase`), shifting ~2,282 bytes. A
session then rewrote the handoff doc to "bless" the drifted hash. Restored
to byte-perfect on 2026-06-13 by reverting bank_00b.asm to the e78eb1d
version (+1 symbol rename). Any doc still citing `b909...` is stale.

## Iron Rules

1. **Clean disassembly is never refactored.** No `jp`→`jr`, no shared-helper
   extraction, no "optimization" in `disassembly/`. All such changes go in
   `patches/`. Annotation = labels and comments ONLY (zero byte impact).
2. **Never insert bytes into banks $01, $04, $17** (raw embedded pointers).
   Same-size replacements or wrappers in end-of-bank padding only.
3. **Never `make clean`** — it deletes committed `.2bpp` binaries that cannot
   be regenerated identically. Remove only `game.o game.gbc game.sym game.map`.
4. **`verify_integrity.py` must PASS before any commit.**
5. **When in doubt, grep the ROM/disassembly for how the original does it.**
   Documentation has been wrong before ($E7 ≠ END; opcode $04 ≠ give item).

---

## Status Dashboard

### Custom content primitives (proven in-game: v23 base, v25 step system)

| Primitive | Status | Where |
|-----------|--------|-------|
| Custom rooms (mapID ≥ $6B), multi-screen, exits | ✅ working | patches/bank_060.asm + intercepts. Multi-screen scrolling proven (v28): vertical 2-screen Room $6B (screens 0+4). Room dimensions in $26DD bytes 2-5 control walkable area. |
| Custom NPCs with scripts | ✅ working | bank $60 entry 4 dispatch |
| Custom text, multi-page, line breaks | ✅ working | IDs $0A00+, two-level ptr table |
| YES/NO choices with branching | ✅ working | $E7 $F0 + opcode $15 on $C83C |
| Item give + inventory-full check | ✅ working | opcodes $2A (wrapped) / $2C |
| Monster/egg give + storage-full check | ✅ working | opcodes $29 (wrapped) / $28; egg give proven with SkyDragon (EID 350) |
| Script-driven teleport | ✅ working | opcode $0F (MapTransitionFull); vanilla + custom destinations |
| BGM change | ✅ working | opcode $41 (SetBGM); track reverts on room exit |
| Event flags set/clear/check | ✅ working | opcodes $00/$01/$03; 328 used, 298 with sets, ~200 safe+persistent free |
| NPC show/hide by step | ✅ working | CustomPtrChase reads RAM step counter × 6; 2+ step entries per screen; opcode $12 advances counter. Verified in-game v25. |
| LZSS tile compressor | ✅ working | tools/compress_tiles.py, roundtrip verified |
| Custom tile layouts | ✅ working | bank $64 pointer table + LZSS data; tile_layout_compiler.py; MedalMan-tileset room confirmed in-game (v28). Tileset switching via MapIDClampForPalette in ROM0 (hardcoded per-room). Palette attributes fixed: CustomAttrCheck intercept in bank $17 free space ($6C75) decompresses custom nibble-packed attr data from bank $64 entry 1. |
| Custom tileset selection | ✅ working | MapIDClampForPalette at ROM0 $3FE8; Room $6B currently $16 (MedalMan). |
| Attr map generator | ✅ working | tools/generate_attr_map.py; builds tile→palette maps from all 85 tilesets, generates LZSS-compressed attr data. |
| Script compiler/decompiler | ✅ working | tools/compile_script.py / decompile_script.py |
| Random encounters in custom rooms | ✅ working (single room, Strategy A) | Whitelist mapID in $0B:Jump_00b_4674 + pin wGateID/wCurrentFloor (ASM) + arm wEncounterCounter (room-entry script). Pool selectable via gate/floor. v30, runtime-verified. Editor generalization specced (CROSSBANK_ROOMS.md). |
| Custom breeding recipes (special table) | ✅ working (same-size edit + capacity extension) | v31/S12: special-recipe override (Anteater×BattleRex→GoldSlime) via two provably-dead entries; in-game confirmed. Tool `patch_breeding_recipe.py`, `patches/bank_016.asm`. Family table is positional (result=slot index). **S13: round-trip encoder B1 built** (`tools/build_breeding.py`, `extracted/breeding_tables.json`) — both vanilla tables decode/re-emit byte-identical. **S13: B2 relocation** (special scan → free bank `$69` via `rst $10`). **S15: B3 capacity 1×–2×** — `build_breeding.py` appends recipes from `extracted/breeding_extra_recipes.json` past index 824 (cap 1650); BattleRex×MadCat→DracoLord confirmed in-game. **S16: B4 family-defaults rewrite** — `build_breeding.py --emit-family` authors the positional family table in place from `extracted/breeding_family_defaults.json`; Bird/Slime/Beast×Dragon + new Dragon×Dragon→GreatDrak confirmed in-game (5 bytes, zero-collateral). **S17: B5 full special-table authoring** — `build_breeding.py --emit-special` owns the WHOLE special table as authored data (825 ROM base + in-place `overrides` by index/parents + `appends`) from `extracted/breeding_special.json`, with a whole-table first-match-wins shadow validator; bank `$16` stays vanilla (single source = JSON → bank `$69`). Confirmed in-game: MadCat×BattleRex→DracoLord (entry-187 in-place edit), Darkdrium×BattleRex→Armorpion (append), S12 GoldSlime preserved. Supersedes the B3 `--emit-relocation` path. **S18: B6 family reassignment** — `build_family_reassign.py` moves monsters between ANY families (incl. ???/Boss=9) via same-size family-byte edits (`patches/bank_003.asm`); reader gate cleared (display/copy only, eligibility is joinability+boss table, not family). **S18: dynamic-library POC** — `build_dynamic_library.py` redirects `SetItem_6242` ($12) to a family-byte scan so the library groups by reassigned family (`patches/bank_012.asm`); user-confirmed, POC only (lags). **S19: B7 production library grouping (DONE, replaces the POC)** — `build_library_table.py` emits a build-time precomputed family→members table into bank `$12` free space + a zero-shift `SetItem_6242` walker; **zero far-loads, zero scratch RAM**, vanilla blank-slot semantics restored; generic-N (`NUM_FAMILIES`) + 256-id-ceiling extension-aware; special entries 215–220 protected; `extracted/library_grouping.json` data deliverable; user-confirmed in SameBoy (zero lag). Production library now done; 11th family (B9) data side unblocked. Rename (B8) folded into B9 per user decision. |

### Not yet implemented (the roadblocks — see ROADMAP.md)

| System | Blocker |
|--------|---------|
| Random encounters in custom rooms | ✅ PROVEN (Strategy A, Session 11). Mechanism: encounters are gated per-step by a mapID whitelist in `$0B:Jump_00b_4674` (NOT by `wInGateworld`); whitelisting a custom mapID enables them. The battle pool is `GateBasePoolIndex[wGateID]+floor` resolved at battle time, so a non-gate room must pin `wGateID`/`wCurrentFloor` (done in ASM every step) and arm `wEncounterCounter` (room-entry script, since vanilla skips seeding when `wInGateworld=0`). Win+flee return clean; saving still works (no gate mode). **Remaining (editor):** #1 per-room on/off + gate/floor table, #2 custom pools — both specced in CROSSBANK_ROOMS.md, not yet generalized. |
| Custom tile GRAPHICS | Palette attributes fixed (v28). Multi-tileset mashup pipeline working end-to-end (Session 7): editor exports JSON → `build_combined_tileset.py` → ROM patches → playable room with tiles from 4 source tilesets (80 tiles). K-means palette grouping replaced with exact-color matching (10 groups for NORDEN). Game engine forces BG palette color index 1 to shared value ($6BFF) at runtime — build tool swaps EXT palette indices 0↔1 to work around this. Castle VRAM animation at tile indices 77-78 avoided by inserting blanks. Editor has live palette slot counter (X/8) with export validation. **Session 9**: editor tileset PNGs regenerated with runtime-correct palettes via `regenerate_tileset_pngs.py` (all 86 tilesets, using `room_palettes.json`). Force-preview toggle shows colour index 1 marker tint. `--build` flag validated end-to-end (editor export → patched ROM → clean restore). **Session 10**: multi-screen ROM patches working — per-screen layout+attr in bank $64, screen-aware CustomAttrCheck in bank $17, room height in $26DD table. **Remaining**: editor multi-screen UI (screen selector, per-screen canvas, exit/NPC placement); `build_combined_tileset.py` multi-screen export. |
| Custom music | Sound engine unexplored |
| Save-data audit | ✅ Completed Session 8. SRAM save layout fully traced and documented in ARCHITECTURE.md + known_RAM_map.md. Custom flags $0158-$0277 are in save range. Flag byte collisions mapped. Flag $0158 tested in SameBoy: set via NPC script, persisted through save+reload. |

### Disassembly annotation (measured 2026-06-13, not estimated)

Objective metric: meaningful (non-auto) labels + comment density per bank.

| Tier | Banks | Notes |
|------|-------|-------|
| Fully annotated (11) | $00 $03 $04 $0B $0C $0D $0E $0F $13 $14 $41 | Core engine + script data banks |
| Useful partial (≈14) | $01 (36%) $16 (30%) $17 (75%) $50 (21%) $51 (27%) $52 (36%) and tileset banks $23–$31/$37/$38 (data-only, trivially "done") | |
| Effectively raw (~80) | everything else | mgbdis output, auto labels |

All 2,404 function entry points are named repo-wide, but most bank
*internals* are raw. "~45% disassembled" overstates editability: **data
tables inside raw banks are still misassembled as fake instructions**, which
blocks direct editing of monsters/enemies/encounters/breeding in source.

### Known documentation defects (to fix as encountered)

- ~~Two contradictory MD5s across docs~~ → fixed; verifier now polices this.
- README inventory range `$CA21–$CA50` was wrong; **correct: `wInventory` =
  `$CA51`, 20 slots** (ARCHITECTURE.md + patches/wram.asm agree, verified in
  GiveItem handler).
- ~~`extracted/map_table.json` interact/exit labels swapped~~ → fixed;
  `dump_map_table.py` rewritten with verified semantics + $FFFF hole-
  skipping bug also fixed (was dropping a third of rooms).
- NEXT_CLAUDE_MESSAGE.md and SESSION1_ARCHIVE.md are superseded — delete
  (replaced by this file + SESSION_PROTOCOL.md + ROADMAP.md).
- ~~Data layer: tool-behind-data and frozen-source JSONs~~ → ALL RESOLVED.
  `dump_enemy_stats.py` reconciled (full 25-byte decode, 487/487 match);
  new generators written for `skills.json`, `text_id_map.json`,
  `all_scripts.json`; `map_table.json`/`exit_table.json`/
  `room_connections.json` regenerated with fixed decoders; remaining
  JSONs reclassified (hand-authored reference or stable analysis, not
  frozen-source). See TOOLS_AND_DATA.md for the complete audit.
  `monsters.json`, `event_flags.json`, `edits.json` are legacy (deletable).
- KEY_LESSONS.md claims "Bank $0B is safe for insertions" — true for the
  *patched* tree, but this is exactly the loophole that caused the
  byte-perfect drift. Insertions in $0B are allowed **in patches/ only**.
- ~~ROADMAP "NPC show/hide" pointed at opcodes $48/$49 and claimed the
  mechanism was "untraced"~~ → Fixed. The mechanism is the **step
  system** (multiple step entries per screen, counter at $D92A–$D99A
  set by opcode $12). Opcodes $48/$49 are runtime movement-based
  show/hide for cutscenes. Full documentation added to
  ROOM_DATA_FORMAT.md "Room State System", ARCHITECTURE.md RAM map,
  known_RAM_map.md, and CUSTOM_CUTSCENES.md.
- ~~Decompiler opcode names had systematic errors~~ → Fixed. Handler
  code verified against ROM bytes for all critical opcodes. Key fixes:
  $29 was "give_item" (actually AddMonster), $2A was "check_level"
  (actually GiveItem — PROVEN in v23), $41 was "save_map_return"
  (actually SetBGM). Compiler had same errors — "give_item" compiled
  to $29 (AddMonster) instead of $2A (GiveItem). All three tools
  reconciled: decompile_script.py, compile_script.py,
  dump_all_scripts.py. all_scripts.json regenerated.
- ~~Opcodes $00 and $01 names may be swapped~~ → **Confirmed correct
  (no swap).** Verified from assembly: $00 handler does `jp nz, skip`
  after `TestEventFlag`, so it branches when flag is CLEAR =
  "if_flag_clear". $01 handler does `jp z, skip`, so it branches when
  flag is SET = "if_flag_set". `TestEventFlag` returns Z=clear, NZ=set
  via `and [hl]`. Definitively resolved from code; no SameBoy test needed.
- ~~Room $6C step counter addresses $D9A0-$D9A2 collided with event flags~~
  → **Fixed.** $D9A0 = byte 5 of wEventFlags (boss defeat flags $0028-
  $002F: DracoLord, Zoma, Baramos, Pizzaro, Esterk, etc.), $D9A1 = byte 6
  (story flags $0030-$0037 with up to 62 uses each), $D9A2 = byte 7
  (MedalMan, Castle flags $0038-$003F). Writing step counter values there
  would clobber critical game state. Never triggered in practice because
  CustomPtrChase ignored step counters. Fixed by moving all custom step
  counters to $D478-$D47B (verified-unused WRAM gap). Room $6B's $D95E
  (shared with MedalMan original) also moved to $D478.
- ~~Room $6B NPCs blocked exit to Room $6C~~ → **Fixed (v25).** Egg giver
  at (3,3) and BGM changer at (1,4) removed; a prior session had moved
  them into positions that blocked the walkable path to the (3,1) exit
  without updating docs. Item giver at (2,2) retained.
- ~~dump_all_scripts.py decoded linearly, missing ~45% of WriteRAM ops
  at branch targets~~ → Fixed. Work-queue follows 9 branch opcodes.
  810/866 unique WriteRAM ops found (93.5%); 56 in alternate dispatch
  paths remain. $D9E3 story progression counter documented.
- ~~14 separate room-name dictionaries across tools (30–97 entries each,
  all different)~~ → Fixed. Created `dwm/map_names.py` as single source
  of truth (97 entries from editor/editor.py). All 14 tools now import
  from it. Regenerated JSONs use canonical names.
- ~~`analyze_event_flags.py` scanned scripts linearly, missing 70% of
  set_flag operations behind branches~~ → Fixed. Tool now reads
  `all_scripts.json` (branch-following data). Result: 298 flags with
  sets (was 92); check-only anomalies dropped from 219 to 29.
  `event_flags_complete.json` and `EVENT_FLAGS.md` regenerated.
  The 29 remaining are in the 6.5% unreached script paths or engine-set
  (flag $00F1 confirmed in unreached Castle script 0 branch at $0C:$46C4).
  Story progression fully mapped: arena-driven with mandatory Anger/
  Durran gate interludes.
- ~~Bank $04 inline comment at $59D2 labeled opcode $0E as
  "SetMapTransition"~~ → Fixed. $0E is **BranchByScreen** (branches
  if `wScreenIndex == param`). The real map transition is opcode
  **$0F** at $5A02 (MapTransitionFull: writes gate_id → $C96D, flag
  → $C96E, spawn XY, sets wIsPlayerChangingMaps). ROADMAP also
  corrected ($0E → $0F).
- ~~KEY_LESSONS claimed ROM palette pointers had "bit 15 set" as encoding
  marker~~ → **Corrected (Session 9).** Zero step-0 palette pointers have
  bit 15 set (verified all 107 entries). The actual issue: ROM palette bytes
  at `pal_ptr` are in an engine-internal format for ALL rooms, not just some.
  The game engine always transforms them at runtime. Editor tileset PNGs now
  use `room_palettes.json` (runtime-dumped data) via `regenerate_tileset_pngs.py`.

---

## Repository Layout (target structure)

```
README.md                      Quick start + pointers (no status claims)
documentation/
  PROJECT_STATE.md             ← YOU ARE HERE. Status + canonical facts.
  SESSION_PROTOCOL.md          How every session starts, works, ends.
  ROADMAP.md                   Phased plan to the editor + open roadblocks.
  EDITOR_DESIGN.md             Architecture of the new editor.
  reference/                   Subject docs (stable knowledge):
    ARCHITECTURE.md  DATA_STRUCTURES.md  BANK04_SCRIPT_ENGINE.md
    TEXT_SYSTEM.md   ROOM_DATA_FORMAT.md CROSSBANK_ROOMS.md
    EVENT_FLAGS.md   ROUTING.md  MONSTER_DATA.md  BREEDING_SYSTEM.md
    QUEST_OPCODES.md CUSTOM_CUTSCENES.md SCRIPT_TOOLS.md
    KEY_LESSONS.md   SAMEBOY_GUIDE.md    known_RAM_map.md  known_NOTES.md
    SIDEQUEST_MAP.md
disassembly/                   Byte-perfect source. NEVER refactored.
patches/                       All custom-content modifications.
extracted/                     Generated JSON (regenerable; note generator in file header)
tools/                         Python tools incl. verify_integrity.py
dwm/                           Python support package (rom, text, map_names — single source of truth for room names)
editor/  (legacy)              Frozen Streamlit editor — do not extend
data/                          DWM-original.gbc (gitignored, user-provided)
```

Housekeeping queue (low priority, safe deletions): root-level `rom.py`,
`text.py`, `__init__.py`, `__pycache__/` (stale duplicates of `dwm/`;
nothing imports them), `.DS_Store` files, stray
`disassembly/18-5694-TEXT_DeathMore_Intro`, `ALL_ROOMS_FINAL.png` and
`FULL_FAQ.txt` → move under `documentation/reference/assets/`.
