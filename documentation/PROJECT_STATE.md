# PROJECT STATE — Single Source of Truth

> **This file is the entry point for every session.** It is the only document
> allowed to state project-wide status. Other docs are subject-specific
> references and must not duplicate status claims. If this file and another
> doc disagree, this file wins — and the session should fix the other doc.
>
> **Size discipline (S51):** this file keeps only the latest TWO session
> blocks verbose. Older blocks move VERBATIM to `SESSION_HISTORY.md` (a cold
> archive — do NOT read it at session start; every fact in it already lives
> in the owning reference doc). The Session Index below is the finding aid.

> Last verified: 2026-07-02 (Session 51 — **Repo/doc consolidation audit + skill-table
> rename.** Integrity PASS 4/4, clean build byte-perfect `1ca6579…`. Doc-layer session:
> no functional ROM change.)
> **S51 — the status layer is restructured for context cost; contradictions fixed.**
> (1) **PROJECT_STATE compressed** (~1,071 → ~330 lines): session blocks S11–S48 moved
> verbatim to the new cold archive `SESSION_HISTORY.md`; a one-line Session Index (below)
> replaces them; resolved doc-defects moved there too. Aging rule added to
> SESSION_PROTOCOL §3 (keep latest 2 blocks; move the oldest on each new session).
> (2) **ROADMAP compressed** (~1,176 → ~490 lines): every [x] item reduced to
> evidence + owning-doc pointer; cut narratives preserved verbatim in SESSION_HISTORY
> Part 3. New boxes added: **Tame Stage 2 / skill evolve** (⚠️ the S50 TEST CRANK
> `$0640` is LIVE in `patches/bank_072.asm`+`bank_052.asm` — one Tame cast maxes the
> meat meter; revert to `$000A` is part of that box), G3 schema fold (was prose-only),
> MP/learn-table `dw`/`db` re-section, §13.4 skill follow-ups, skills.json retirement,
> TOOLS_AND_DATA upkeep. (3) **Contradictions fixed in place:** empty-bank counts
> unified (canonical Bank Allocation table below); script-count bases reconciled
> (518 = bank $0C–$0F label census; 732 = (map_type, script) entries in
> all_scripts.json — map types share banks); ROADMAP flag counts updated to the
> branch-following numbers (328/298); SESSION_PROTOCOL stale `documentation/reference/`
> path fixed (layout stays FLAT — the old "target structure" is dropped, user decision);
> DATA_STRUCTURES related-docs table fixed (FIRST_5MIN_TRACE → ROUTING appendix;
> known_ROM_map.md removed); BREEDING_SYSTEM "NOT yet built" header fixed (B1–B7 built);
> TOOLS_AND_DATA refreshed (103 tools / 56 JSONs; ~13 tools + ~10 JSONs added to the
> manifest; header counts fixed); README patched-build cleanup line fixed (8 new-bank
> files, not just bank_060). (4) **Rename executed (was deferred S44):**
> `TilesetLookupTable` → **`SkillMPCostTable`** and `LoadFld_56e8` → **`GetSkillMPCost`**
> in `disassembly/bank_007.asm` + `patches/bank_007.asm` (labels/comments only; clean
> build byte-perfect; role confirmed live by S48's 3-reader map + S49 MagicBurn MP path).
> (5) **Same session, user-approved follow-on:** housekeeping deletions EXECUTED —
> actually deleted: `__pycache__/`, 8× `.DS_Store`, `breeding_extra_recipes.json`
> (all tracked at HEAD → git-recoverable; the recipes file was a B3 capacity TEST
> fixture, facts archived in SESSION_HISTORY). THREE queue rows were stale:
> `monsters.json`, `event_flags.json`, `edits.json` were already absent
> (untracked at HEAD — never in a fresh clone). `--emit-relocation` marked
> legacy/absence-tolerant. (6) **Both skill tables
> RE-SECTIONED to real data** in BOTH trees via the new
> `tools/resection_skill_tables.py` (probe-build method): `SkillMPCostTable` →
> 222×`dw` with per-skill name/MP comments; `SkillLearnReqTable` → 222×18B `db`
> with decoded stat/prereq comments; 4,293 fake-instruction lines → 676 real ones;
> two fake-decode artifact labels kept at exact offsets (`DispMapS_566b`,
> `label6_6034` — referenced from not-yet-re-sectioned bank-$06 regions). Clean
> build byte-perfect; verifier PASS 4/4. (7) Phase-D STALE BOXES verified + ticked:
> banks $03/$14/$16 were already labeled `db`. Toolchain incident, honestly
> recorded: S51 **violated the pre-existing four-doc "never `make clean`" rule**
> (README ×2, PROJECT_STATE Iron Rule 3, SESSION_PROTOCOL, KEY_LESSONS — the
> SECOND recorded violation; the KEY_LESSONS canonical entry now logs both) and
> initially misreported the rule as nonexistent until the user pushed back —
> grep the docs before making claims about the docs. Sibling hazard also hit:
> **broad `git checkout -- disassembly/`** reverts uncommitted label work.
> STRUCTURALLY FIXED: Makefile `clean` no longer
> deletes gfx, the `%.2bpp: %.png` trap rules are removed (17/18 committed .2bpp
> are NOT PNG-regenerable — measured), `disassembly/gfx/README.md` added.
> (8) `--check` caught a tool defect (the SkillLearnReqTable label line was
> emitted missing — a silent str.replace no-op in the tool build); label inserted
> in both trees + the `ld hl, $50e0` loader relabeled to `ld hl,
> SkillLearnReqTable` (byte-identical), tool fixed with an assert.
> **NEXT:** Tame Stage 2 (crank revert + 3 tiers + natural-to-Slime) as its own session,
> or S2f (field-cast skill), or T2 text roll-out. Housekeeping deletions (`__pycache__/`,
> 8× `.DS_Store`, Tier-L JSONs, `breeding_extra_recipes.json`) queued pending user OK.
>
> Last verified: 2026-06-30 (Session 50 — **S2e: custom skill #2 (Tame) ships; the
> custom-message + presentation-timing infra generalizes.** Integrity PASS 4/4, clean build
> byte-perfect `1ca6579…`. **Tame (`$E1`)** — recruit (meat-meter) + anti-abuse damage
> (ATK/4), single-target — is user-confirmed in SameBoy: announce "used Tame!", heart
> animation, damage sound + "takes X damage" text correctly SEQUENCED after the heart, damage,
> and recruitment all correct. New infra this session: (1) **custom-message render fork** —
> `$FD` is now a general escape resolving a per-skill pool string by `[$db8a]-$DE`
> (`LoadB4c_Fork`), so bespoke text no longer needs a scarce free id (MagicBurn migrated onto
> it); (2) **presentation timing** — the effect state machine's per-id animation-wait gate
> (`$53:$5b07`) + a fixed frame delay (`wTameDelay`) sequences a note-then-hit skill, and the
> damage sound is moved off the note onto the text. Full RE: `BATTLE_SKILL_SYSTEM.md` §13.5 +
> §11.7; TEXT_SYSTEM.md (fork); KEY_LESSONS.md (Session 50). KNOWN DEFECT (deferred, minor
> cosmetic): the per-enemy-sprite blink is unsolved (not `wBGPalette`/whole-screen, not
> OBP-only — an OAM visibility toggle not yet found; §11.7). Meter is TEST-cranked (`$0640`);
> revert to `$000A` for Stage 2.
>
> [S49 context] Session 49 — **S2d: custom skill #1 ships end-to-end.**
> Integrity PASS 4/4, clean build byte-perfect `1ca6579…`. **MagicBurn (`$E0`)** is a
> non-aliased custom skill, user-confirmed working in SameBoy: own record (½ current MP →
> all foes) + result text + **announcement** + **animation** + **hit-flash** + **cast
> sound**, all via clean dynamic indirection, zero per-aspect hacks. New this session:
> (1) **announce** — `AnnounceTemplateTable` (`$58:$5806`, lookup `$58` e6 `$57C5`, render
> `$50:$5A42`; `$FF`=silent) re-disassembled to a clean `db` table in patches with `$E0`'s
> slot filled; (2) **custom message pool** — the 256-id battle-message table is FULL (one
> free slot `$FD`), so bespoke text lives at `$4c:$7326` (`CustomMsg_E0_MagicBurn`, `$FD`
> repointed); (3) **presentation proxy** — `GetPresentId` in `$5f` free space (identity for
> stock ids, per-skill PROXY for custom ids via `CustomProxyTable`) forked into the 12 `$5f`
> reads of `$db8a` (byte-neutral); renderers `$5c/$5d/$5e` read the id zero times, so a custom
> skill borrows a real skill's whole anim script → no hang, flash + SFX restored (MagicBurn
> proxies Infernos `$09`). Full RE + per-skill recipe: **`BATTLE_SKILL_SYSTEM.md` §13**;
> TEXT_SYSTEM.md (pool); KEY_LESSONS.md (3 lessons). The standalone presentation-groundwork
> doc was folded into §13 and deleted.
> **NEXT:** Tame Stage 2 — revert meter crank `$0640`→`$000A`; 3 upgrade tiers (learn-chain
> fork, bank $06); make Tame natural to Slime (a `$03:$4461` slot). Then S2f (field-cast skill,
> e.g. teleport) / more custom skills via the §13.4 recipe. Optional polish: the per-enemy
> blink (§11.7).

---

## Session Index (finding aid — verbatim blocks in SESSION_HISTORY.md; owning docs are canonical)

| S | What landed | Knowledge lives in |
|---|-------------|--------------------|
| 1–2 | Cross-bank custom rooms (v1–v23 arc); custom NPCs/text/items | CROSSBANK_ROOMS; KEY_LESSONS S1–2 |
| 3 | Monster/egg give ($29/$28), teleport ($0F), BGM ($41) | ROADMAP Phase 1; KEY_LESSONS S3 |
| 4–7 | Custom tile layouts; palette attrs; multi-tileset mashup + HTML editor | ROOM_DATA_FORMAT; KEY_LESSONS S4–S7 |
| 8 | Palette budget (4 groups); gate detection; SRAM save audit | ARCHITECTURE (SRAM); KEY_LESSONS S8 |
| 9–10 | Runtime-correct tileset PNGs; multi-screen room patches | TOOLS_AND_DATA; ROOM_DATA_FORMAT |
| 11 | Random encounters in custom rooms (Strategy A) | CROSSBANK_ROOMS; KEY_LESSONS S11 |
| 12–13 | Custom breeding proven; B1 round-trip encoder + B2 relocation | BREEDING_SYSTEM; KEY_LESSONS S12 |
| 14 | Breeding-cutscene sprite glitch fixed (bank $0B labelization) | KEY_LESSONS S14 |
| 15–17 | B3 capacity ext; B4 family defaults; B5 full special-table authoring | BREEDING_SYSTEM; KEY_LESSONS S15–S17 |
| 18–19 | B6 family reassignment + library POC; B7 production library grouping | BREEDING_SYSTEM; KEY_LESSONS S18–S19 |
| 20 | Family-icon trace (B8/B9); Spirit B9 VRAM fix + icon shipped | BREEDING_SYSTEM; KEY_LESSONS S20 + "Spirit B9" |
| 21–22 | Battle-sprite swap POC; GFX-1 sprite codec + gfx-table re-section | MONSTER_DATA "sprite graphics"; KEY_LESSONS S22 |
| 23 | GFX-2 cross-bank sprite backbone + battle palettes solved | MONSTER_DATA "battle palette"; KEY_LESSONS S23 |
| 24 | GFX-3 follower swap + metasprite render engine | MONSTER_DATA "follower system"; KEY_LESSONS S24 |
| 25 | GFX-4 species→layout auto-map + custom-art import | MONSTER_DATA "layout dispatch"; KEY_LESSONS S25 |
| 26–27 | Bank $12 library-table re-section (complete); Phase E gap analysis | DATA_STRUCTURES "bank $12"; ROADMAP Phase E; SIDEQUEST_MAP |
| 28 | Phase N scope + 256-slot species map | MONSTER_DATA "Species ID geography" |
| 29 | Encyclopedia detail-page freeze fixed (mode×species overshoot) | TEXT_SYSTEM; KEY_LESSONS "Gorbunok" |
| 30–32 | N2/N3 tool-owned; N6 gates cleared; N5 breeding wiring + hatch/nickname fixes | ROADMAP Phase N; MONSTER_DATA |
| 33 | Display/name/lineage seams annotated in clean disassembly | ROADMAP Phase D (S33 note) |
| 34–35 | G1 follower + G2 battle art baked into patches/ | ROADMAP N4; KEY_LESSONS S35 |
| 36 | Starter (EID 1) proven end-to-end; force-join hack verified, not ported | MONSTER_DATA "Starter Monster"; EVENT_FLAGS $0002 |
| 37 | Gate floor generation traced end-to-end | GATE_GENERATION.md |
| 38 | Data-table seams annotated; lineage parent-name fix | ROADMAP Phase D (S38); ROADMAP N5 |
| 39–41 | Custom gate room render; Pillar A table-driven render; Pillar B rotation insertion | GATE_GENERATION §7.1–7.5; KEY_LESSONS S39–S41 |
| 42 | Table-driven dispatch keystone (bank $71; $26DD ceiling lifted) | EDITOR_DESIGN §2; KEY_LESSONS S42 |
| 43 | Disassembly gap audit (audio/battle/text); Arc-1 T1 text re-section (bank $47) | TEXT_SYSTEM "Source re-section"; ROADMAP Phase F |
| 44 | S1 skill data foundation (MP/learn tables decoded; BugCut id 215) | BATTLE_SKILL_SYSTEM; DOC_AUDIT #12–14 |
| 45 | S2a alias-skills POC (Scorch $DE / Smite $DF) | BATTLE_SKILL_SYSTEM §1–6; KEY_LESSONS S45 |
| 46 | S2b record table round-trip + presentation foundation | BATTLE_SKILL_SYSTEM §7–10 |
| 47 | S2c effect messages + S2c-anim renderer reversed | BATTLE_SKILL_SYSTEM §9, §11 |
| 48 | S2d-audit: skill-id bucketing map (254 reads / 9 banks) | BATTLE_SKILL_SYSTEM §12; KEY_LESSONS S48 |
| 49 | S2d: MagicBurn ($E0) ships non-aliased end-to-end | BATTLE_SKILL_SYSTEM §13; KEY_LESSONS S49 |
| 50 | S2e: Tame ($E1) ships; custom-message + timing infra generalizes | BATTLE_SKILL_SYSTEM §13.5, §11.7; TEXT_SYSTEM $FD; KEY_LESSONS S50 |
| 51 | Doc consolidation; SkillMPCostTable/GetSkillMPCost rename | this file; SESSION_HISTORY.md |

---

## Canonical Facts (verified, do not trust other copies)

| Fact | Value |
|------|-------|
| Original ROM MD5 | `1ca6579359f21d8e27b446f865bf6b83` |
| Clean build target | MUST equal the MD5 above, byte-perfect |
| Assembler | RGBDS v0.6.1 exactly |
| ROM size | 2 MB, 128 banks ($00–$7F) |
| Custom content bank | $60 (verifier check 2 prints current usage — 1,393 B as of S51) |
| Monster battle palette table | `MonsterBattlePalettes` @ `$17:$62FD`, 8 B/species, 4 RGB555 `[c0, c1=$6bff, c2, c3=$0000]`; loaded by bank $17 entry 6 (`$1706`). Was mislabeled `RoomAttrDataBlocks`. |
| Monster sprite overflow banks | `$7E,$7F` (then `$7C,$7A,$79`) — cross-bank sprite streams (`dwm/sprite_bank.py`); EDITOR_DESIGN §8. Resolver reads `$<bank>:$4001+index*2`, no bank gating. |
| Follower gfx-ID table | `ScreenTransDataTable` @ `$01:$49DF`, 231 `dw`, indexed `species+$10`; loader `GetActiveMonsterStatus` @ `$01:$4986`; family table `FollowerFamilyGfxTable` @ `$01:$4BAD` (10). 16 tiles / 256 B per follower, DMA'd to VRAM `$8200`/`$8300`/`$8400` (party slot 0/1/2). **8 parallel copies of this gfx-ID table exist** (`$01 $06 $07 $09 $0b $12 $18 $59`, one per UI context: `$18`=menu/`TextDataPtrLookup`@`$4123` indexed `species`, `$12`=library); a complete art swap repoints ALL 8. |
| Follower layout dispatch (GFX-4) | Level-1 tables at FIXED `$10:$407f` (species 0–127) / `$11:$407f` (species 128+), indexed by species; `$ffc7=species+$10` routed by bank-`$04` entry 2 (`$10–$8F`→bank `$10`, `≥$90`→bank `$11`). Per-species attr/palette byte at `$10:$417f` / `$11:$412d` (bit6=Y-flip, bit5=X-flip, low3=OBJ palette). `[$caca]` = SPECIES (party +$09), not a "sprite-class" byte. Bank `$05` `$407f`-style table is the ObjTest viewer, NOT the follower path. `extracted/monster_follower_layouts.json`. |
| Follower render engine | `SaveScr_40cd` @ `$04:$40cd` (GBC variant of ROM0 `$0d91`). Metasprite list = 4-byte entries **(dy, dx, tile_offset, attr)**, `$80`-terminated; OAM tile = `tile_offset + [$ffc9]` (base `$20/$30/$40`); OAM attr = `[$ffca] XOR attr` (X-flip bit5). 2-level table: sprite-type `$ffc7`(=`[$ca91]`) → frame/dir `$ffc8`. **OBJ idx0 = hardware-transparent** (battle BG used idx1). 8 OBJ palettes @ `$17:$5615`. |
| Follower layout library | **155 distinct layouts** (complete; regenerated by `tools/extract_monster_follower_layouts.py` from the real `$10/$11:$407f` tables — the old 118-count brute-force scan dropped 3-entry small/blob layouts). Layout is per-species. Reassignment = same-size 2-byte repoint of the species' `$407f` level-1 entry (same-bank only), NOT a `[$caca]` edit. `extracted/follower_layouts.json`. |
| Custom layout bank | $64 (layout ptr table + LZSS layout + attr data, 309 bytes used) |
| Vanilla-empty banks | 23 = 368 KB: $60,$64,$67,$69–$77,$79–$7A,$7C,$7E–$7F (full-ROM scan, DOC_AUDIT B). Current allocation: see Bank Allocation table below. |
| Gate floor generation | Standard floors are procedurally generated (4×4 screen grid `$C940`, `(piece<<4)\|variant`); special/boss rooms are fixed templates substituted in. Per-gate config `GateFloorDataTable` `$16:$70A6` (32×8); weighting via `SelectFloorType` `$16:$5FC0` + `FloorTypeSelectionTable`1/2/3. Special-room insertion = `rst $00` dispatch at `$16:$5C1C` (sets `wMapID` + `wInGateworld=0`). **Full pipeline: GATE_GENERATION.md.** |
| Gate damage tiles | Standing-tile id → HRAM `$AA` (`$00:$1E96`); behavior class `$AA>>2`: `$0E` (ids `$38–$3B`) = damage, `$0F` (`$3C–$3F`) = staircase. Amount = `FloorDamageTable` `$01:$5E7D` (16 B by floor type): type 3→5, type 6→10, types $0C/$0E→2, else 0. Applier `ApplyFloorDamage` `$01:$5E23`. (GATE_GENERATION.md §5.1.) |
| Room palette derivation | A room's runtime BG palette is ROM-derivable: real colours are only indices 0 & 2 of slots 0–3 (`$17:$476F`[mapID] normal / `$17:$51F5`[floortype] gate, scanning past empty screens); engine FORCES idx1=`$6bff`, idx3=`$0000` in every BG palette; slots 4–7 shared system; object palettes global at `$17:$5615`. `tools/derive_room_palette.py`, validated 30/30 dumps + gate. (GATE_GENERATION.md §7.1.) |
| Verifier | `python3 tools/verify_integrity.py` — run at session start AND end |

**The MD5 `b90957482011c8083a068781033715b7` is WRONG.** It was a drifted
build produced when commits `2000e99`/`036dc06` refactored bank $0B code
(inline pointer chases → `call SharedPtrChase`), shifting ~2,282 bytes. A
session then rewrote the handoff doc to "bless" the drifted hash. Restored
to byte-perfect on 2026-06-13 by reverting bank_00b.asm to the e78eb1d
version (+1 symbol rename). Any doc still citing `b909...` is stale.


### Bank allocation (custom-content banks; single source of truth)

| Bank | Owner | Emitted by |
|------|-------|-----------|
| $60 | Custom rooms / NPCs / scripts / text | hand-authored `patches/bank_060.asm` (→ `build_project.py` later) |
| $64 | Custom tile layouts + attr data | `tile_layout_compiler.py`, `build_gate_room.py`, `generate_attr_map.py` |
| $67 | Combined-tileset GFX (multi-tileset mashup) | `build_combined_tileset.py` |
| $69 | Breeding special table + scanner (B5 owns the whole table) | `build_breeding.py --emit-special` |
| $6A | New-species info high table (ids 224+) | `build_new_species.py` |
| $71 | Custom-room dispatch tables (S42 keystone: `Custom26DDTable`, `RoomEncTable`) | hand-authored `patches/bank_071.asm` |
| $72 | Custom-skill system (de-aliased S2d/S2e code + tables) | hand-authored `patches/bank_072.asm` |
| $7E | Sprite overflow streams (battle + follower art) | `dwm/sprite_bank.py`, `bake_follower_overflow.py` |
| $7F | RESERVED next sprite-overflow bank (then $7C, $7A, $79) | `dwm/sprite_bank.py` order |
| **Unallocated** | **$6B–$70, $73–$77, $79–$7A, $7C** (13 banks = 208 KB) + reserved $7F | — |

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


## Status Dashboard

### Custom content primitives (proven in-game)

| Primitive | Status | Where |
|-----------|--------|-------|
| Add NEW monster species (ids 224–255) | 🟢 Gorbunok (id 224) fully integrated & baked: info/stats/wild-encounter/name/library/breeding(3 paths)/lineage/follower art/battle art (S28–S38, user-confirmed). Open: **G3** schema fold (ROADMAP). | ROADMAP Phase N; MONSTER_DATA "Species ID geography" + "NEW species followers/battle sprite" |
| Custom rooms (mapID ≥ $6B) | ✅ table-driven to editor scale: render/palette/attr/$26DD records + per-room encounters via bank $71 tables (S40/S42); multi-screen scroll (v28); gate-rotation insertion + descent (S41). | EDITOR_DESIGN §2; GATE_GENERATION §7; CROSSBANK_ROOMS |
| Custom NPCs with scripts | ✅ working | bank $60 entry 4 dispatch |
| Custom text, multi-page, line breaks | ✅ working | IDs $0A00+, two-level ptr table |
| YES/NO choices with branching | ✅ working | $E7 $F0 + opcode $15 on $C83C |
| Item give + inventory-full check | ✅ working | opcodes $2A (wrapped) / $2C |
| Monster/egg give + storage-full check | ✅ working | opcodes $29 (wrapped) / $28; egg path is the practical choice |
| Script-driven teleport | ✅ working | opcode $0F (MapTransitionFull); vanilla + custom destinations |
| BGM change | ✅ working | opcode $41 (SetBGM); track reverts on room exit |
| Event flags set/clear/check | ✅ working | opcodes $00/$01/$03; 328 referenced, 298 with sets (branch-following) |
| NPC show/hide by step | ✅ working | step system; counters at $D478+; opcode $12 advances (v25) |
| LZSS tile compressor | ✅ working | tools/compress_tiles.py, roundtrip verified |
| Custom tile layouts + tileset selection | ✅ working | bank $64 + tile_layout_compiler.py; MapIDClampForPalette ROM0 $3FE8 |
| Custom tile GRAPHICS (multi-tileset mashup) | ✅ working end-to-end (S6–S10): editor JSON → build_combined_tileset.py → bank $67/$17 patches. Remaining = editor multi-screen UI. | KEY_LESSONS S5–S8; TOOLS_AND_DATA |
| Attr map generator | ✅ working | tools/generate_attr_map.py (85 tilesets) |
| Script compiler/decompiler | ✅ working | tools/compile_script.py / decompile_script.py |
| Random encounters in custom rooms | ✅ generalized per-room (S42 `RoomEncTable`, bank $71). Remaining: custom monster POOLS (Encounters #2, ROADMAP). | CROSSBANK_ROOMS; KEY_LESSONS S11 |
| Custom breeding | ✅ full authoring stack B1–B7: round-trip encoder; bank $69 owns the special table (overrides+appends+shadow validator); family-defaults rewrite; family reassignment; production library grouping (zero lag). B9 11th-family icon shipped; tab wiring open. | BREEDING_SYSTEM; ROADMAP Phase 2B |
| Custom battle skills (net-new ids) | 🟢 TWO custom skills live: MagicBurn $E0 (S49), Tame $E1 (S50), on the full de-aliased stack (record/handler/name/announce/anim/flash/SFX/messages). ⚠️ **Tame TEST CRANK `$0640` live in patches** — see Open defects + ROADMAP "Tame Stage 2". | BATTLE_SKILL_SYSTEM §12–§13; ROADMAP Arc 2 |
| SRAM save layout | ✅ audited S8: custom flags $0158–$0277 persist; collisions mapped | ARCHITECTURE; known_RAM_map |

### Not yet implemented

| System | State |
|--------|-------|
| Custom monster pools (Encounters #2) | Specced in CROSSBANK_ROOMS; not built |
| Custom music | Sound engine unreversed (ROADMAP Arc 3, M1 first) |
| Editor app (Phase 3) | Not started; backend keystone (S42) done |

### Disassembly annotation (measured 2026-06-13, not estimated)

Objective metric: meaningful (non-auto) labels + comment density per bank.

| Tier | Banks | Notes |
|------|-------|-------|
| Fully annotated (11) | $00 $03 $04 $0B $0C $0D $0E $0F $13 $14 $41 | Core engine + script data banks |
| Useful partial (≈14) | $01 (36%) $16 (30%) $17 (75%) $50 (21%) $51 (27%) $52 (36%) and tileset banks $23–$31/$37/$38 (data-only, trivially "done") | Post-S43 arcs also deepened $47 $54 $5f (not re-measured) |
| Effectively raw (~80) | everything else | mgbdis output, auto labels |

All 2,404 function entry points are named repo-wide, but most bank
*internals* are raw. **Data tables inside raw banks are still misassembled as
fake instructions**, which blocks direct editing in source (ROADMAP Phase D/F
re-section items).

### Open defects

- ⚠️ **Tame TEST CRANK is live in the canonical patched build**: `patches/bank_072.asm`
  (+ mirrors in `bank_052.asm`) set the meat meter to `$0640` per cast (one cast =
  recruit). Revert to `$000A` is part of ROADMAP "Tame Stage 2 / skill evolve".
- Tame per-enemy-sprite blink unsolved (cosmetic; not `wBGPalette`, not OBP-only —
  likely an OAM visibility toggle). BATTLE_SKILL_SYSTEM §11.7.
- `extracted/skills.json` is superseded by `skill_records.json` but still read by
  `gen_name_tables_db.py` — retire (ROADMAP box).
- DOC_AUDIT.md's full-corpus audit is dated 2026-06-13; later findings are dated
  addenda inside it, not a re-audit.
- `dump_monsters.py` WRITES the legacy `monsters.json` schema (43-byte parse) while
  READING `monsters_full.json` for names — TOOLS_AND_DATA's Tier-A attribution
  "monsters_full.json ← dump_monsters.py" is suspect (the legacy note says
  `randomize.py` writes monsters_full). Verify the real generator before relying on
  regen; don't re-run dump_monsters casually (it recreates the deleted legacy file).

---

## Repository Layout (actual; docs stay FLAT — user decision S51)

```
README.md                      Quick start + pointers (no status claims)
documentation/                 FLAT — all docs at this level:
  PROJECT_STATE.md             ← YOU ARE HERE. Status + canonical facts.
  SESSION_PROTOCOL.md          How every session starts, works, ends.
  ROADMAP.md                   Phased plan to the editor + open roadblocks.
  SESSION_HISTORY.md           Cold archive (do NOT read at session start).
  EDITOR_DESIGN.md             Architecture of the new editor.
  DOC_AUDIT.md                 Claim-by-claim audit (2026-06-13 + addenda).
  TOOLS_AND_DATA.md            Tool + extracted/ manifest.
  <subject references>         ARCHITECTURE, DATA_STRUCTURES, BANK04_SCRIPT_ENGINE,
                               TEXT_SYSTEM, ROOM_DATA_FORMAT, CROSSBANK_ROOMS,
                               EVENT_FLAGS, ROUTING, MONSTER_DATA, BREEDING_SYSTEM,
                               BATTLE_SKILL_SYSTEM, GATE_GENERATION, QUEST_OPCODES,
                               CUSTOM_CUTSCENES, SCRIPT_TOOLS, SIDEQUEST_MAP,
                               KEY_LESSONS, SAMEBOY_GUIDE, known_RAM_map, known_NOTES
disassembly/                   Byte-perfect source. NEVER refactored.
patches/                       All custom-content modifications.
extracted/                     Generated JSON (generator noted in _generator key)
tools/                         Python tools incl. verify_integrity.py
dwm/                           Python support package (rom, text, map_names, sprite_bank, sprite_codec)
editor/  (legacy)              Frozen Streamlit editor — do not extend
examples/                      Reproducible swap/species examples (not baked)
towards_editor/                DWM1_Tile_Editor.html — standalone room-design prototype
data/                          DWM-original.gbc (gitignored, user-provided)
FULL_FAQ.txt                   Full game guide (root; game structure/quests reference)
ALL_ROOMS_FINAL.png            Rendered room atlas (root)
```
