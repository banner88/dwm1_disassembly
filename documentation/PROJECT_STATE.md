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

> Last verified: 2026-07-14 (Session 58 v2 — **CF3 step 1 (party-first sort)
> USER-CONFIRMED: farm multi pick/drop, breeding, full gate run + boss,
> party shuffles, save/reset (battle JOIN not explicitly exercised).
> Phantom-monster mystery RESOLVED (buffer-overlay flag spray, hazard
> re-accepted by user). Verifier PASS 4/4** — clean build byte-perfect
> `1ca6579…`; patched build md5 `d31c9300e13b98f516c6bee8b446069d`
> (**patched**, the compiler-regression reference; v1 `79dd32c5…` (patched)
> and S57 `6c41f0d8…` (patched) are historical).)
>
> Session 58 (2026-07-13 — **CF3 step 1: party-first sort. The invariant
> "party at slots 0-2 in list order, farm contiguous after" now holds after
> every canonicalize** — the CF1-flagged precondition for farm→SRAM.
> Owning section: MONSTER_DATA "CF3 step 1 as built".)
> **User decisions settled at session start (recorded in ROADMAP CF3):**
> (1) party-first SORT over index remapping; (2) freed-range save semantics
> = **EXPLOIT** (keep the vanilla block copy — the range persists across
> save/load; layout rule: transient scratch stays $DE74, relocated buffers
> take a corner, the bulk is the editor's persistent-state pool, usable
> only AFTER the walker redirects land).
> **Implementation (1 operand edit + 1 new bank entry):** canonicalizer
> tail `ld hl,$0106 / rst $10` at $01:$4808 retargeted **$0106→$7301**
> (2 operand bytes $4809-$480A; pattern `79 EA 8D CA 21 06 01 D7 C9` unique
> in ROM). Bank $73 entry 1 `CF3PartyFirstSort` (patches/bank_073.asm):
> selection sort over ≤3 party-list positions (entry state per vanilla:
> occupied contiguous, list compacted/unique ⇒ t=list[i]>i), 149-B record
> swap i↔t + fixups of every WRAM cell holding raw slot indices across a
> canonicalize — later party-list entries (==i→t), battle-position cache
> $DA15-$DA17 (exchange i↔t; vanilla compaction is provably no-op at the
> mid-battle join canonicalize, the sort is not), $CA40 breeding-offspring
> persist (exchange; vanilla compaction happens to preserve it, the sort
> would not). Deliberately NOT remapped: $CAC0 (vanilla "indices unstable
> across canonicalize" contract; positional uses exist), $DA14 (consumed
> pre-canonicalize, verified). $C0D8 map: no caller consumes it after
> return (20-line scan below all 22 sites). Then nest-calls the displaced
> $0106 (rst $10 stack-nests; depth 3).
> **Validation:** emitted bytes decoded (sm83dis) + byte-executed in a mini
> SM83 interp: identity, scattered party [4,0,2], displaced-member fixup
> [1,0], post-breeding $CA40 tracking, empty party, mid-battle-join shape
> (pre-join cache untouched) — 21/21. Patched-build byte-diff vs S57
> reference: header checksum + 2 operand bytes + bank $73 only. Compiler
> regression re-pinned `79dd32c5…` (patched), 18/18 `--rom` green.
> **Two doc errors fixed in place (DOC_AUDIT S58):** the canonicalizer tail
> $0106 is `ScanPartySlotTable` (+$29/+$31 sanitizer), NOT "follower art"
> (MONSTER_DATA CF1 + bank_001 comment block, both corrected, byte-perfect);
> canonicalizer call-site count re-verified with generator: 22 sites /
> **7** banks ($04 $0A $12 $15 $18 $50 $51), S56's "8 banks" off by one.
> **Semantic delta (user to veto in test):** farm-menu display order can
> change when the party changes (sort displaces farm records that sat
> below a party member) — cosmetic, order-only.
> **NEW OPEN (ROADMAP CF3 (a2)):** pre-sort saves load a vanilla-layout
> roster; the invariant only appears at the first canonicalize after load —
> force a canonicalize/sort on the load path BEFORE any walker redirect
> assumes slots 3-19 == farm. Harmless in the sort-only build.
> **v2 (2026-07-14) — phantom-monster incident + $CA40 fixup removal:**
> user's first v1 session showed phantom farm monsters (garbage species,
> 0 HP/MP, PAIRED junk names "0012/0095", levels 1→cap) — ONLY in the S57
> in-gate save; unreproducible from any clean save on S57 OR S58 builds
> (user ran full gate loops both ways). SHELVED with hypothesis (recorded as
> hypothesis, KEY_LESSONS S58): fossils of the pre-S55 slot-14/16 collision
> bug class in that save's lineage, surfaced by CF2's drain leveling any
> flag-$01 garbage into visibility (level spread = garbage exp; 0 HP =
> level-ups don't heal). User advised to archive the .sav as evidence, then
> release the phantoms in-game. The investigation DID surface a real v1
> defect: the sort's $CA40 exchange-fixup rewrites the farm drop/pick flow's
> live candidate register ($CA40 is dual-role — S56's "breeding persist" was
> one flow's view; farm UI writes it per selection at $0A:~$5CC4 and feeds
> it to unguarded flag-marking paths). REMOVED in v2; $DA15-17 fixup kept
> (verified battle-only, 2 refs). Drain's nested calls exonerated by
> reading: $13 entry 2 + $51:$5B31 are context-free record math off [$CAC0].
> Interp re-run vs v2 bytes 21/21; compiler re-pinned `d31c9300…` (patched)
> 18/18; PASS 4/4. Breeding window + stale-$C0D8 state-machine reads are
> WATCH ITEMS in the as-built section.
> **v2 RESOLUTION (2026-07-14):** phantom mystery SOLVED — user found the
> repro (enter/exit well custom room = +2 Drakslimes "0095", level 0, all
> zeros) and the byte trace confirmed the S55 accepted hazard's undocumented
> facet: room $6B S1 NPC table byte 3 ($03, the spawn Y) is copied to
> wCustomNPCBuffer+3 = $D37C = SLOT 15's IN-USE FLAG (slot 16's = $D411 =
> exit buffer byte 24); the next canonicalize normalizes the spray into a
> real farm record. The <=14 rule protects real monsters, NOT empty 15/16.
> The S57 gate save's 4 fossils = two rooms' visits + CF2 drain leveling.
> SORT EXONERATED (predicted to repro on S57). USER RULING: hazard
> re-accepted, no interim patch, CF3 relocation retires it (ROADMAP CF3 (d);
> hazard note sharpened in patches/wram.asm). v2 then USER-CONFIRMED: farm
> multi pick/drop, breeding (the $CA40 watch item passes), full gate run +
> boss, party shuffles, save/reset. Battle JOIN not explicitly exercised —
> carry as a residual test item.
> **NEXT:** user test of the S58 **v2** ROM (party swaps at the farm —
> multiple picks/drops in one visit, battle join, breeding, save/load,
> farm-menu order sanity) → then CF3 (a2) + the two redirected walker
> helpers (b), or A′1.
>
> Session 57 (2026-07-13 — **CF2: per-battle exp re-bound to party; farm exp
> banked into a persistent accumulator, paid at the map-change commit.**)
> **Implementation (3 patch sites + 1 new bank; MONSTER_DATA "CF2 as built"
> is the owning section):** (1) `wPendingFarmExp` **$D9C8-$D9CA** (24-bit LE,
> clamp $98967F) — carved from the S8-verified clean event-flag block, INSIDE
> the save image ON PURPOSE: in-gate save rooms exist (FAQ), so pending must
> survive save+reload; boot-cleared, new-game-zeroed, pre-CF2 saves load as 0.
> Flag indices **$0168-$017F retired** from the allocator pool in exchange.
> (2) Bank $50 same-size 14-B window at the exp walker head ($61FA):
> `CF2FarmShareDivert` (67 B, tail nops) still runs the vanilla Div24x8To16
> but banks total/16 into pending and ZEROES the per-monster farm share HRAM
> $DB-$DD — the walker's farm branch and the post-battle all-20 level scan
> become farm-inert with zero loop edits. (3) Bank $0B same-size 6-B window at
> RoomEntry0's map-change commit ($4020): `ld hl,$7300 / rst $10` + 2 nop →
> NEW **bank $73** entry 0 `CF2WarpCommitDrain` does the displaced
> wWarpFlag→wInGateworld store, then, when the DESTINATION is non-gate
> (wWarpFlag=0) and pending≠0, pays each eligible farm monster (flag $01, not
> egg +$63, level≠99, level<cap) the full pending and levels it with the
> IDENTICAL silent vanilla pair the post-battle farm scan uses
> ($1300 threshold / $1302 gains / $510d apply — all context-free, only
> [$CAC0]; nested rst $10 = vanilla precedent, bank $50 does it). [$CAC0]
> saved/restored. **Semantic deltas (user to veto in test):** farm
> exp/levels land at the first non-gate transition, not per battle (invisible
> — farm UI is town-only, and vanilla farm level-ups are SILENT: the
> party-list pass gets the display state, the all-20 scan is the $1302+$510d
> pair with no message — code-verified); mid-run storage recruits get the
> FULL run's pending (slightly generous); drain also fires entering in-gate
> special rooms (wWarpFlag=0) — an early payout, semantically safe (vanilla
> paid farm mid-gate every battle).
> **Validation:** emitted bytes decoded at all 3 sites (sm83dis);
> divert+drain byte-executed in a mini SM83 interp (accumulate ×2, clamp at
> 9,999,999, multi-level drain, egg/99/cap/party/empty skips, gate-dest
> passthrough, zero-pending early-out — all pass). Compiler regression
> re-pinned: compat build == the S57 hand-staged patched build md5-equal
> (`6c41f0d8…`, **patched**), 18/18 `--rom` tests green; old reference
> `026970d3…` (patched) historical.
> **⚠ FLAG-POOL DEFECT found + fixed in passing:** EVENT_FLAGS' "broader safe
> ranges" (and `editor2/core/project.py FLAG_SAFE_RANGES`) were script-only
> analysis — per-byte audit vs engine literals + all_scripts.json shows
> $D9CC, $D9D9-$D9E2, $D9E4-$D9E5, $D9E7-$D9E8 are LIVE (engine named vars
> and/or script-referenced). Truly clean persistent flag bytes: **$D9C6-$D9C7
> + $D9D7-$D9D8** (32 flags after the CF2 retirement, not "~200").
> EVENT_FLAGS rewritten in place; FLAG_SAFE_RANGES now
> [(0x0158,0x0167),(0x01E0,0x01EF)]; DOC_AUDIT addendum + KEY_LESSONS S57.
> **USER-CONFIRMED 2026-07-13 (`DWM-S57-CF2-TEST.gbc`):** farm exp up at the
> farm UI after a multi-battle gate run; save in an in-gate save room →
> reload → exit gives the FULL run's exp (persistence proven); party
> level-ups/display unchanged; town walk clean. Semantic deltas above stand
> un-vetoed.
> **NEXT:** CF3 (order: party-first sort first; the open user decisions in
> ROADMAP CF3 must be settled before it starts) or A′1 (mapID ≥$80 audit).
>
> (S56 + earlier blocks moved verbatim to SESSION_HISTORY.md Part 1 — see Session Index.)

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
| 56 | CF1: party/farm boundary + monster-array access map (tri-state flag, party list $CA8D/$CA8E, canonicalizer+compaction, exp shares, egg/KO fields, staging slots $D665/$D6FA, 44 writers + 60 walkers classified) | MONSTER_DATA "Party/farm boundary"; extracted/monster_walkers.json; known_RAM_map; KEY_LESSONS S56 |
| 57 | CF2 built + USER-CONFIRMED: wPendingFarmExp $D9C8 (persistent), bank $50 farm-share divert, bank $73 drain at the bank-$0B map-change commit; flag-pool audit fix (safe = $D9C6-7 + $D9D7-8) | MONSTER_DATA "CF2 as built"; EVENT_FLAGS; known_RAM_map; KEY_LESSONS S57; ROADMAP CF2 |
| 58 | CF3 step 1 built (NOT user-tested): party-first sort in the canonicalizer ($01:$4809 operand hook → bank $73 entry 1); user decisions settled (sort; freed range = EXPLOIT/persistent); entry-6 = ScanPartySlotTable doc fix; call-site count re-verified 22/7 banks | MONSTER_DATA "CF3 step 1 as built"; ROADMAP CF3; DOC_AUDIT S58 |

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
| $73 | Cold Farm systems (CF2 drain, entry 0; CF3 party-first sort, entry 1) | hand-authored `patches/bank_073.asm` |
| $7E | Sprite overflow streams (battle + follower art) | `dwm/sprite_bank.py`, `bake_follower_overflow.py` |
| $7F | RESERVED next sprite-overflow bank (then $7C, $7A, $79) | `dwm/sprite_bank.py` order |
| **Unallocated** | **$6B–$70, $74–$77, $79–$7A, $7C** (12 banks = 192 KB) + reserved $7F | — |

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
