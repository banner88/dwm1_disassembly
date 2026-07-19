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

> Last verified: 2026-07-19 (Session 68 — **E2 RE half + AUTHORING SPEC: battle↔story engine decoded, byte-neutral. wGameMode $C88A mode tables; bank $50 = BATTLE mode manager; $D9EC = 18-phase battle machine; win→script-resume guarantee ($C8EA.7) + loss path (Castle warp, gold/2, keep-on-defeat item bit) decoded; evaluation opcodes resolved ($CA8D party count / $FF92 hPlayerX / $D8E1 evaluator family); flee=neutral-2/caught=win-0/1-in-32 intro events HW-pinned by user; authoring spec + campaign recommendation in SIDEQUEST_MAP; bank_050 header rewritten + phase labels in both trees (sym-verified). Clean build `1ca6579…` unchanged; verifier PASS 5/5; editor2 untouched.**)
>
>
> Session 68 (2026-07-19 — **E2 RE half + AUTHORING SPEC: the battle↔story
> engine decoded (byte-neutral). Owning section: SIDEQUEST_MAP "Story
> progression ENGINE + AUTHORING SPEC — DECODED S68".**
> Headline: **"win → subsequent script commands run" is an engine
> guarantee** — wGameMode $C88A (ROM0 tables $00:$030F init / $00:$050F
> tick; mode 1 = field bank $01, mode 2 = battle bank $50); battle request
> = wGameState.6 latch → bank $13 $C905 transition ($13:$73F5 = the ROM's
> only res 6) → mode 2; script VM state $D8D5-7 survives in WRAM;
> BattleExitHandler ($50:$640A) restores mode 1 + $C8EA.7 → bank $01
> ClearAnimationState SKIPS its reset → script resumes after the battle
> opcode (= the on-win rewards). LOSS ($DB55==1): $D92B=8, engine warp to
> Castle via the opcode-$0F cells, gold $CA4B-4D halved, items dropped
> unless info byte +$0B bit 2 (keep-on-defeat = TinyMedal/BeastTail/
> WarpStaff/ShinyHarp/BookMark — user FAQ list VERIFIED +BookMark), $D8D7
> cleared. **$D9EC = 18-phase battle machine** (BattlePhaseTable $50:$5F3A;
> not 15; intro 0-3 / main 4-8 / sequencer 9 on $D9ED / post $0A-$0D /
> exit $0E-$11), outcome set by bank $52 KO scans (~$76E0 loss / ~$7727
> win; XOR'd for link peer; $DB73=$FF loss freeze). **$D9F4 = nested
> battle sub-machine** (bank $50 header's "main game state" framing + the
> "$C86C = gate world" claim were WRONG — $C86C is the LINK flag, bank $03
> serial setters; state variants are LOCAL/LINK; wInGateworld=$C969).
> **Evaluation opcodes resolved**: $CA8D = party count (Well/Bazaar-Edge
> "==1" = can't-forfeit-last-monster refusal, NOT skill check); $FF92 =
> hPlayerX low (Bazaar 215/216/217 = position gate); $D8E1 = result cell
> of the 10-opcode evaluator family $23/$30/$32/$34/$38/$51(library-seen
> tiers)/$55(item count)/$56(gold÷10)/$59/$5F (census in
> BANK04_SCRIPT_ENGINE); opcode $45 = restore party from $CAB9 7-byte
> snapshot. Deliverables: bank_050 header rewrite + BattlePhaseTable/
> BattlePhase09SubTable re-sections + 18 phase labels in BOTH trees
> (sym-verified addresses; renames Jump_050_640a→BattleExitHandler,
> Jump_050_6aac→BattlePhase09_TurnSequencer); wram.asm wBattlePostFlag
> comment (0=win/1=loss/2=undecided); ARCHITECTURE mode table +
> bank/$D9F4 rows; known_RAM_map (10 rows); MONSTER_DATA fixes;
> SIDEQUEST_MAP spec + 3 corrections; DOC_AUDIT ×3; KEY_LESSONS S68;
> ROADMAP E2 → [~] (RE+spec done, schema wiring open). **Campaign
> recommendation recorded (user Q): new-world spine in custom rooms via
> generated scripts; vanilla intact as postgame; arena gating = re-authored
> Arena Lobby scr0; capacity = 32 flags → E3 or audited vanilla-flag
> reuse.** **HW-pinned same session (user SameBoy): FLEE → $DB55=2
> neutral (resolver $50:$5808 jumps phase $0A + masks exp targets
> $DD1F-22; no penalty; $DB73-armed edge → 1); CAUGHT monster → plain win
> ($52:$7729 = 0 via the phase-7 chain, backtrace-verified); $C899/$C89A
> proven the LIVE RNG pair (adjacent examines differ) → LoadBtl_5d29's
> &$1F==$1F = 1/32-per-side random battle-intro event ($DB55 doubles as
> its marker until the KO scans).** Residuals: $CAB9 snapshot writer;
> intro-event message text (3-14). Byte-neutral: clean build `1ca6579…`
> unchanged; verifier PASS 5/5.
>
>
> Session 67 (2026-07-19 — **E1: arena / gate-boss opponent-roster format
> DECODED (byte-neutral). Arena path USER-VERIFIED on HW same session.**
> Headline: there is NO arena roster table — opcode $1F `ArenaBattleSetup`
> ($04:$5D5B; between-matches clone `LoadArenaEnemyStats` bank $50) computes
> **EID = $E0 + 9*wArenaGroup + 3*wColiseumBattle + slot** → 90 consecutive
> enemy-stats rows ARE the brackets (groups 0-7 = G..S, 8 = Starry Night
> 296-304, 9 = King, overridden to $01E1-$01E3; formula rows 305-313 =
> unreachable rival-team cut data). Group source: bank $09 lobby menu
> (4*[$C8E3]+([$C8E2]&$7F); gold table $09:$5D23; availability $C0D8) or
> Arena Lobby scr6 write_ram (group 8/9 + $D999 = 1/4). $D999 = map-$5D step
> counter (0 arena / 1-3 Starry phases / 4 King). Master lobby sprites:
> `ArenaMasterSpriteTable` $04:$5E22 (30×[gfx,is_monster]; dup $50:$6778) —
> both re-sectioned from fake instructions (byte-perfect). Gate bosses:
> EVERY boss fight is the opcode $5A/$05 EID param in the boss ROOM script
> (53-site census, all script-attributed): Medal Gate has THREE variants
> (156/153/155); Durran gate = 3-fight chain (write_ram2 Servant 342 ×2 +
> op $20 → op $05 Terry 343 @ $0F:$4D46 → op $05 Durran 199 @ $0F:$4DB8;
> post-game Terry rematch $0F:$500E); Bewilder/Anger decoys (341×4/349×7);
> Digster = op $05 127; NEW: undocumented MadGopher L21 event battle
> (EID 255, Castle scr13 + Farm scr26); Tatsu EID 344 unused. **$14:$4893 is
> the fight→join RECRUITMENT redirect, NOT a boss-selection table** —
> boss_table.json semantics corrected (data unchanged; DOC_AUDIT S67).
> Coliseum (map $52): RNG level-banded parties (op $5C `ColiseumInitPrize`
> keys MAX level, bank $16 twin keys AVERAGE; bands 2×9 then 18-wide at
> 13/33/57/81/105/129/157/181; parties 2/3 staged $D9D1-6/$D9D9-DE, chained
> by $50:SetBtl_67ae; prizes $04:$6F44/$6F54, visit counter $D9CF). Mimic
> (op $36, $04:$63EF) tiered by **$CAB4 = arena progress** (Arena Lobby scr0
> writes class+1 per victory — the scr0 per-class victory cascade of rank +
> catch-up flags + world step counters is now fully tabled in SIDEQUEST_MAP).
> Op $52 = random scaled battles ($04:$6A3C). Battle-slot RAM: $DA03/05/07
> 16-bit EIDs, **$DA02 = count−1**, $DA09 mode 0/1/2/3. **HW verification
> (user, SameBoy write-watchpoints, Class D)**: $DA02=$02 written at
> $04:$5D8E with EIDs 251/252/253 (= $E0+27, exact formula), caller DE=$47AA
> (scr6); regen fired at the $50 clone; $DA09=$01 by op $20 at $04:$5E69
> from map $5D scr0 (DE=$61E4). Deliverables: `tools/dump_arena_brackets.py`
> → `extracted/arena_brackets.json` (Tier A, self-checking anchors); owning
> prose SIDEQUEST_MAP "Arena / gate-boss ROSTER format — DECODED S67" incl.
> AUTHORING SPEC for E2; annotation both trees (2 table re-sections, 3 label
> renames incl. the wrong `ArenaGenerateBattles`→`ScriptWriteRAM`, 7 opcode
> header fixes); corrections in QUEST_OPCODES / known_RAM_map / DOC_AUDIT
> (2 rows) / KEY_LESSONS (2: script words are op|$FF00; synonym-grep before
> "not documented"). Residuals banked in SIDEQUEST_MAP ($DA09 modes 0/2/3
> code-derived; intro Dracky EID 4 engine-side; match-2/3 loop not stepped).
> ROADMAP E1 ✅ — E2 unblocked. Verifier PASS 5/5; clean build `1ca6579…`
> unchanged; editor2 untouched.
>
>


## Session Index (finding aid — verbatim blocks in SESSION_HISTORY.md; owning docs are canonical)
- **S66** (2026-07-18): A′1 — mapID ≥$80 readiness audit: engine ≥$80-READY as patched (58/56 wMapID sites adjudicated; "sign-test" fear impossible on SM83; ceilings $FE hard/$EA practical; music cap $7F); audit_mapid_range.py → mapid_range_audit.json; CF4 v7 user-confirmed. Owning: CROSSBANK_ROOMS §mapID-audit, DOC_AUDIT S66, KEY_LESSONS S66.
- **S65** (2026-07-18): CF4 — custom-room WRAM migration into the CF3-freed window (buffers $CC80/$CD00, counters $CD80×640, wCustomPool; TRANSIENT permanently) + SRAM-expansion audit (BLOCKED on RAMB discipline → E3); S58 EXPLOIT decision annotated foreclosed; audit_wram.py FREED_WINDOWS model. v7 USER-CONFIRMED S66. Owning: patches/wram.asm banner, PROJECT_COMPILER §2.6, ARCHITECTURE, DOC_AUDIT S65 (3 rows).
- **S64** (2026-07-18): Arc 3 M3b+M3c — room-default music (LoadNewBGMIdIntoA same-size rewrite + bank $71 resolver + 128-entry table; custom.music compiler section) + MIDI import (midi_to_song.py); DWM2 31-subsong catalog; note-length FRAMES + $A3 groove corrections; v6 user-confirmed. Owning: SOUND_SYSTEM, PROJECT_COMPILER §2.9, CROSSBANK_ROOMS, DOC_AUDIT S64.
- **S63** (2026-07-18): Arc 3 M3a — general song slots (bank $74, AudioMasterTableExt in ROM0 $3FE8 from merged-twin+dead-code bytes); v4+v5 user-confirmed; S62 compat-break fixed. Owning: SOUND_SYSTEM, PROJECT_COMPILER §1, KEY_LESSONS S63, DOC_AUDIT S63.
- **S62** (2026-07-17): Arc 3 M2 — song round-trip codec (157 streams byte-identical); DWM2 grammar corrections ($AC call/$FD slots/loop forms); BGM #06 POC user-confirmed. Owning: SOUND_SYSTEM §5/§7, KEY_LESSONS S62, DOC_AUDIT S62.
- **S61** (2026-07-17): Arc 3 M1 — sound engine + song data fully mapped (byte-neutral); ROADMAP bank-list claim falsified; DWM2 GBS same-engine-family finding. Owning: SOUND_SYSTEM.md, DOC_AUDIT S61, ROADMAP M1.
- **S60** (2026-07-16/17): CF3 complete — farm slots 3-19 to SRAM (v2 eager-roster architecture), 48 walker sites, save-state invalidation across migration. Owning: MONSTER_DATA "CF3 as built", ARCHITECTURE SRAM, KEY_LESSONS S60.
- **S59** (2026-07-16): Phase 0 close-out — verifier check 5 (tool selftests, ROM-tolerant), skills.json retired, 222-entry skill-table root cause. Owning: TOOLS_AND_DATA, BATTLE_SKILL_SYSTEM, DOC_AUDIT S59.
- **S58** (2026-07-13): CF3 step 1 — party-first sort in the canonicalizer (bank $73 entry 1), v2 fixups, phantom-monster forensics. Owning: MONSTER_DATA, ROADMAP CF3.

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
| 58 | CF3 step 1 built, v2 USER-CONFIRMED 2026-07-14 (battle JOIN not exercised — residual): party-first sort in the canonicalizer ($01:$4809 operand hook → bank $73 entry 1); user decisions settled (sort; freed range = EXPLOIT/persistent); phantom-monster mystery resolved (buffer-overlay spray into empty slots 15/16; hazard re-accepted); entry-6 = ScanPartySlotTable doc fix; call-site count re-verified 22/7 banks | MONSTER_DATA "CF3 step 1 as built"; ROADMAP CF3; DOC_AUDIT S58; KEY_LESSONS S58 |
| 59 | **Phase 0 CLOSED** (byte-neutral): verifier check 5 = tool selftests (ROM-tolerant — SKIPs without a ROM so CI stays green); `extracted/skills.json` retired/deleted, 3 real readers ported to `skill_records.json`, `dump_skills.py` → tombstone. Root cause: the 222-entry skill function table (`$52:$4011..$41CC`, unterminated, bounded by `SkillBlaze` @ `$41CD`) was read as 256 → 34 phantom records. Doc fixes: inverted "sole reader" claim (2 files), `$41BC`→`$41CC` header arithmetic, tool's `256`/`$4211` → `222`/`$6CC7` | TOOLS_AND_DATA "Guardrail"; BATTLE_SKILL_SYSTEM "Extent"; KEY_LESSONS S59; DOC_AUDIT S59; ROADMAP Phase 0 |

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
| $71 | Custom-room dispatch tables (S42 keystone: `Custom26DDTable`, `RoomEncTable`; + `CustomRoomBGMTable` + resolver entry 2, S64) | compiler-generated `patches/bank_071.asm` (template head + tables; S63 `--apply` route) |
| $72 | Custom-skill system (de-aliased S2d/S2e code + tables) | hand-authored `patches/bank_072.asm` |
| $73 | Cold Farm systems (CF2 drain, entry 0; CF3 party-first sort, entry 1) | hand-authored `patches/bank_073.asm` |
| $74 | Custom song bank (M3a: records $4001-$417C fixed 95-slot, streams $4180+; resolved by AudioMasterTableExt row $9E) | compiler-generated `patches/bank_074.asm` (`music74` emitter → `song_codec.song_bank_asm` ← project.json `custom.music` + `extracted/*_song_library.json`; S64 — `custom_songs.json` retired) |
| $7E | Sprite overflow streams (battle + follower art) | `dwm/sprite_bank.py`, `bake_follower_overflow.py` |
| $7F | RESERVED next sprite-overflow bank (then $7C, $7A, $79) | `dwm/sprite_bank.py` order |
| **Unallocated** | **$6B–$70, $75–$77, $79–$7A, $7C** (11 banks = 176 KB) + reserved $7F | — |

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
| BGM change | ✅ working | opcode $41 (SetBGM); reverts to the ROOM DEFAULT on exit/reload |
| Room-default music (vanilla + custom rooms) | ✅ working (S64, user-confirmed v6): `music.room_defaults`/`rooms[].music` → `CustomRoomBGMTable` (bank $71 entry 2) consulted first by the rewritten `LoadNewBGMIdIntoA`; survives save/reload by construction; sources = inbuilt ids, DWM2 catalog (all 31), MIDI conversions | SOUND_SYSTEM §8; PROJECT_COMPILER §2.9 |
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
| SRAM save layout | ✅ audited S8: custom flags persist (truly-safe pool = 32 flags, S57); collisions mapped; free SRAM tail $BFC8-$BFFF (56 B, reserved). 32 KB expansion audited S65: BLOCKED on RAMB discipline (E3) | ARCHITECTURE (incl. "SRAM banking" S65); known_RAM_map |
| Custom-room WRAM state | ✅ migrated S65 into the CF3-freed window (buffers $CC80/$CD00, counter region $CD80×640, wCustomPool $D001-$D664; TRANSIENT permanently, init-guaranteed zeroed). v7 USER-CONFIRMED S66 | patches/wram.asm banner; PROJECT_COMPILER §2.6; ROADMAP CF4 |

### Not yet implemented

| System | State |
|--------|-------|
| Custom monster pools (Encounters #2) | Specced in CROSSBANK_ROOMS; not built |
| Custom music | 🟢 **M1-M3c COMPLETE (S61-S64, all user-confirmed)**: engine map, round-trip codec, general slots (bank $74), room-default assignment for any mapID, `custom.music` schema, 31-song DWM2 catalog, MIDI import. Open boxes: InitBGM channel-count ext (4/5ch sources), gate/event music, CI compiler-test |
| Arena/boss roster AUTHORING (E1→E2 wiring) | RE ✅ DECODED S67 (arena path HW-verified); authoring spec in SIDEQUEST_MAP + arena_brackets.json. project.json schema wiring = E2, not built |
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
- ~~`extracted/skills.json` is superseded by `skill_records.json` but still read by
  `gen_name_tables_db.py` — retire (ROADMAP box).~~ **RESOLVED S59 — and the claim was
  inverted:** `gen_name_tables_db.py` declared the path but never opened it; the real
  readers were `gen_skill_table_db.py`, `gen_enemy_stats_db.py`, `gen_monster_db.py`.
  All ported to `skill_records.json`; `skills.json` DELETED; `dump_skills.py` is an
  inert tombstone. Root cause of its 34 junk records: the 222-entry skill function
  table (`$52:$4011..$41CC`) read as 256, overrunning into `SkillBlaze` (`$52:$41CD`).
  (DOC_AUDIT S59; KEY_LESSONS S59.)
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
                               BATTLE_SKILL_SYSTEM, GATE_GENERATION, SOUND_SYSTEM, QUEST_OPCODES,
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
