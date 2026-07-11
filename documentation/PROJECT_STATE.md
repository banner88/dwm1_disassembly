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

> Last verified: 2026-07-10 (Session 55 — **WRAM relocation (reduced form) →
> $DE74 + the two init/restore fixes the first cut missed; Cold Farm +
> Layer A′ arcs scoped.** Integrity PASS 4/4, clean build byte-perfect
> `1ca6579…`; 18/18 compiler tests at the S55v2 reference.)
> **MID-SESSION CRASH POST-MORTEM (user test of the first S55 ROM): hard
> crash on room entry + on scroll after loading an in-room save.** Root
> cause: the old block was initialized by ADDRESS ACCIDENT (inside both the
> boot clear — ClearAllWRAM stops at $DDFF — and the SRAM save image); $DE74
> is inside neither → power-on garbage counters (the S53 crash mechanism,
> resurrected) + wCustomRoomFlag no longer restored on load. Fixes (v2):
> ClearAllWRAM `$1E00`→`$1EE0` (boot zeroes $C000-$DEDF; same-size operand
> edit, single early-boot call site) and flag DERIVED := (wMapID ≥ $6B) every
> movement frame at CopyCustomRoomRecord head (bank $71 template re-pinned
> per §5; TEMPLATE_SIZE 0x71: 103→116). Load-in-room now shows step-0 content
> — expected under transient semantics, not a bug. Full lesson: KEY_LESSONS
> S55 ("vetted-unclaimed is NOT initialized" + "one variable per test ROM" —
> the first S55 ROM wrongly stacked the never-user-tested S53 master-table
> fix under the relocation; v2 delivers COMPAT first).
> **What moved (patches/wram.asm; all refs were label-based → zero patch-bank
> edits; template sha256 pins UNCHANGED):** step counters $D478→**$DE74**
> (compiler region, STEP_COUNTER_BASE + example-project reserved hole
> →0xDE78), wRoomRecScratch→**$DE7B**, wRoomEncFlag $DE83, wTameDelay $DE84,
> wTameBGSave $DE85, wCustomRoomFlag→**$DE88**; $DE89-$DEDD reserved (85 B).
> Regression md5 re-pinned (v2): S55v2 reference patched build
> **`026970d361f6afe03f28e29fa6e631f6`** (compat) / fixed master-table build
> **`fb6a96abd2b045c68234d74fcfcc76b5`** — historical, superseded: S53 pair
> `3a5a514c…`/`f81d4ad8…`; mid-S55 pair `cc62b5…`/`8878ef…` (crashed, no
> init/flag fixes). Test ROMs delivered: **`DWM-S55v2-compat-TEST-FIRST.gbc`**
> (S53-user-tested table config + relocation/fixes — the isolating build)
> and `DWM-S55v2-fixed-master-table.gbc` (adds the S53 table fix) — **both
> user-confirmed working, 2026-07-10**.
> **USER-CONFIRMED 2026-07-10** ("everything now works without issues", both
> S55v2 deliverables): well entry, egg-give exit + scroll-up, save-in-room →
> reload → scroll all work. This ALSO clears the S53 master-table fix's
> test debt (first user run of the fixed-table config). Standing expected
> behaviors: load-in-room shows step-0 content (transient counters); stored
> monsters #15-16 still corrupt on custom-room transitions (≤14 rule). **NPC/exit buffers stayed at $D379-$D477** (inside monster slots
> 14-15): ACCEPTED legacy hazard of the exploration overlay (user decision —
> saves there are disposable); **≤14-occupied rule stands** for custom rooms
> on the hand overlay.
> **Why reduced (S55 vetting — full detail KEY_LESSONS S55 + wram_usage.json
> regen, 51→34 gaps):** the S54 candidates were FALSE gaps — $C200-$C2FF =
> attr decompression staging (every stream declares declen 256), $C300-$C4FF
> = 512-B screen staging unit (bank $06 bulk copy $C500→$C300 ×$0200; both
> blocks SRAM-save-copied — ARCHITECTURE's save table was right, the S54 read
> of it was partial); $DD80-$DE2B = **AUDIO engine** (6 chan × 26 B +
> scalars; known_RAM_map's "INFERRED battle structs" corrected); stack tops
> $DFFF. $DE74-$DEDD was the only vetted block. **Retired alternative:** cap
> monster slots 20→18 (reclaim $D53B-$D664 298 B; $00 in-use pads defuse all
> 44 read-walkers; give scanner `label4_5c14` + full-check `label4_5f67`
> located) — viable but retired as throwaway-path surgery; do NOT re-derive.
> **New canonical discoveries:** farm SLEEP pool = second 20×$95 monster
> array, SRAM-only at $B124-$BCC7 ($CA41 bit7; bank $07 scans it in place —
> vanilla's own cold-storage precedent); SVBK census: five writes total in
> the ROM → **WRAM banks 3-7 = 16 KB virgin** (docs: known_RAM_map); debug
> mode (banks $55/$56/$59) owns ~10 exclusive WRAM bytes (exclusivity scan).
> **Architecture decisions (user, S55):** vanilla rooms KEPT as postgame →
> mapID ≥$80 audit in scope (custom room #22+), vanilla counter pool not
> harvestable; parallel architecture (overlay = exploration, structural fixes
> = compiler pipeline only); **Cold Farm arc** = editor-era WRAM strategy
> (farm→SRAM, party-only exp + accumulator drained at the castle gate-exit
> chokepoint — user-confirmed: all gate exits funnel there, Arena awards no
> exp; ~2.5 KB freed; exp level-scan loop found at bank $50 `jr_050_6318`).
> Full specs: ROADMAP Arc COLD FARM / Arc LAYER A′; EDITOR_DESIGN §1 S55
> amendments.
> **NEXT:** CF1
> (party/farm boundary RE) or A′1 (mapID ≥$80 audit) — or resume S2f / T2 /
> the blink. The `--apply` decision from S53 remains open.
>
> Session 54 (2026-07-08 — **egg-give root cause: custom WRAM sits inside the
> monster array; audit_wram.py ships. Byte-neutral session** — no ROM delta,
> verifier PASS 4/4, clean build byte-perfect `1ca6579…`).
> S53 anomaly (a) CLOSED (user misread the gate; Pillar B works; the "hub exit
> data" suspect statically refuted — room $24 exits step-invariant). S53
> anomaly (b) **ROOT CAUSE (static, runtime probe pending)**: the party/storage
> monster array (party+farm+eggs, ONE 20-slot limit, user-confirmed) spans
> **$CAC1-$D664** via `GetMonsterDataPtr` indexed access — zero literal refs,
> so the Phase-0 grep audit falsely called $D378-$D477 "unclaimed", and ALL 14
> custom WRAM labels ($D378-$D48B: room flag, NPC/exit buffers, 7 step
> counters, wRoomRecScratch, wRoomEncFlag, Tame vars) sit inside monster slots
> 14-16 (third instance of this bug class after $D95E and $D9A0-2).
> Forward corruption (the user's crash): `$FF29` writes a 149-B record into the
> first empty slot; slot 16 lands the 27 resistance bytes on $D479-$D493 =
> bottom-screen step counter (garbage step-entry ptr → dead exit) +
> wRoomRecScratch (garbage tileset/collision record → scroll-up crash).
> Reverse corruption (silent, worse): `CopyCustomRoomRecord` rewrites scratch
> on EVERY room transition since S42; buffer copies spray slots 14-16 →
> stored monsters #15-17 corrupted by normal play, persisted by saving.
> **Interim play rule: keep the array ≤14 occupied around custom rooms; user
> should inspect stored monsters #15-17 for damaged stats/resistances.**
> Confirmation probe: **RUN AND CONFIRMED by user same session.** Recorded
> values for the fix session — before: $D478-$D47E = 00×7, scratch
> `0d 28 a0 00 00 01 30 00`, encFlag 01, $D488+ = 00. After the give:
> $da14=$10 (slot 16); $D478-$D47E = `c8 22 fa 8b c8 22 fa`;
> $D488-$D497 = `ea 8a c8 af ea 8b c8 21 8e c8 34 fa 42 c8 cb 5f`;
> scratch bytes unchanged (per-frame self-heal, see above). Slot 16 = first
> empty ⇒ the user's save has slots 0-15 OCCUPIED ⇒ **monsters #15-#16
> (slots 14-15) are being actively corrupted by every custom-room visit** —
> slot 15's in-use flag ($D37C) is NPC-buffer byte 3; user advised to inspect
> both. The given egg (slot 16) will itself be corrupted by future room
> transitions (scratch/Tame writes land at its +$6E..+$7A). Deliverables: `tools/audit_wram.py` (4 evidence sources;
> gaps reported UNVETTED, never "free"; `--selftest` pins this detection) +
> `extracted/wram_usage.json` (TOOLS_AND_DATA rows added). Relocation
> candidates from the gap list: $C20D-$C2C2 (182 B), $C42B-$C4C3 (153 B),
> $DE74-$DEDD (106 B) — each needs vetting (pointer-walk loops; SVBK bank-2
> windows exist in bank_051/052, so banked WRAM is NOT assumed free). Docs
> corrected in place: ROADMAP facts row (refuted claim + new Phase 0 item),
> known_RAM_map (array end $D664, not $D6B0; seen-bits $CA94-$CAB1 documented;
> collision warning), DOC_AUDIT addendum, KEY_LESSONS S54. Class-C finding:
> new species 224's library bit at $CAB0 is inside the vanilla-scanned extent
> (benign; counts toward the 100-monster library rewards).
>
>
> (S53 + S52 blocks moved verbatim to SESSION_HISTORY.md Part 1 — see Session Index.)

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
| 52 | Tame Stage 2: 3-tier evolve chain ($E1-$E3), learn/MP/announce forks, crank revert; enemy hit-blink mechanism solved (deferred) | BATTLE_SKILL_SYSTEM §13.6, §11.7; DOC_AUDIT S52; KEY_LESSONS S52 |
| 53 | Editor headless backend: project.json schema + build_project.py; byte-identity regression; master-table fix built (untested); script-routing documented | PROJECT_COMPILER.md; KEY_LESSONS S53 |
| 54 | Egg-give root cause: custom WRAM inside the monster array; audit_wram.py ships | known_RAM_map; KEY_LESSONS S54; ROADMAP Phase 0 |
| 55 | WRAM relocation (reduced): counters/scratch/flags → $DE74; false-gap vetting (staging buffers, audio array, sleep pool, SVBK census); Cold Farm + Layer A′ arcs scoped; cap-18 retired | ROADMAP arcs; KEY_LESSONS S55; known_RAM_map; EDITOR_DESIGN §1; PROJECT_COMPILER |

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
| NPC show/hide by step | ✅ working | step system; counters at $DE74+ (S55 relocation); opcode $12 advances (v25) |
| LZSS tile compressor | ✅ working | tools/compress_tiles.py, roundtrip verified |
| Custom tile layouts + tileset selection | ✅ working | bank $64 + tile_layout_compiler.py; MapIDClampForPalette ROM0 $3FE8 |
| Custom tile GRAPHICS (multi-tileset mashup) | ✅ working end-to-end (S6–S10): editor JSON → build_combined_tileset.py → bank $67/$17 patches. Remaining = editor multi-screen UI. | KEY_LESSONS S5–S8; TOOLS_AND_DATA |
| Attr map generator | ✅ working | tools/generate_attr_map.py (85 tilesets) |
| Script compiler/decompiler | ✅ working | tools/compile_script.py / decompile_script.py |
| Random encounters in custom rooms | ✅ generalized per-room (S42 `RoomEncTable`, bank $71). Remaining: custom monster POOLS (Encounters #2, ROADMAP). | CROSSBANK_ROOMS; KEY_LESSONS S11 |
| Custom breeding | ✅ full authoring stack B1–B7: round-trip encoder; bank $69 owns the special table (overrides+appends+shadow validator); family-defaults rewrite; family reassignment; production library grouping (zero lag). B9 11th-family icon shipped; tab wiring open. | BREEDING_SYSTEM; ROADMAP Phase 2B |
| Custom battle skills (net-new ids) | 🟢 FOUR custom skills live: MagicBurn $E0 (S49), Tame $E1 (S50), TameMore $E2 + TameMost $E3 (S52) — a 3-tier evolve chain on the full de-aliased stack incl. natural-learn (LearnLoopFork), real MP (MPPtrFromId, 10/30/50), announce (AnnounceIdxFork). Crank reverted S52; meter tiers 10/100/400. Learn/upgrade user-confirmed; MP charge + meter values built S52, NOT yet user-tested. | BATTLE_SKILL_SYSTEM §12–§13.6; ROADMAP Arc 2 |
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

- Tame per-enemy hit-blink NOT IMPLEMENTED (cosmetic; deferred by user S52 — "bank it").
  The MECHANISM IS SOLVED (S52, HW-confirmed): enemy is BG-drawn; blink = tilemap toggle
  in bank `$5f` entry 5 (`$da83` phase → `$da84` sub-dispatch `$4b99`). Full map +
  implementation plan: BATTLE_SKILL_SYSTEM §11.7.
- S52 items built but NOT yet user-tested: MP charging (10/30/50), meter tier values
  (10/100/400), the "!" page-split upgrade message. Marked in §13.6.
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
