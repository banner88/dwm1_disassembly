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

> Last verified: 2026-09-05 (Session 85 — **LOOP-LEVEL DIFFERENTIAL VALIDATION
> OF THE ROUND CORE: DONE — `simulator/battle.py` 6614 comparisons / 0
> mismatches** over 25 complete engine battles (real-save unforced
> tactics-AI fights vs 1/2/3 enemies + forced status/coverage runs, both-
> side KOs, heals, curse, stun, MP-veto): `simulator/measure_battle.py`
> (31 waypoint hooks, full 8-slot board per event) → corpus
> `simulator/s85_battle_events.json` → `simulator/validate_battle.py` (37
> check kinds: order, gates, dup-conversion, veto, target, MISS/dodge,
> damage cores, HP/KO, victims, decay, DoT, status rolls…). The live RNG is
> idle-stepped between waypoints (`MainWaitLoop`; `BattleRNG` uses the
> $C1ED chain only in LINK), so validation is by injection — a seed-to-end
> replay is impossible by construction (KEY_LESSONS S85). Owning:
> BATTLE_SKILL_SYSTEM **§15.8b** (new) + §15.7/15.8/15.9 updates.
>
> CLOSED with it (byte-read + measured): the S84 "2nd group cast → Attack"
> rule = `EnemyDupCastConversion_4e63` — per-EID flag table
> `EnemyDupConvFlagTable_41df` (181/487 set; ex-"BattleHPLookupTable",
> misnamed) + 77-id list `GroupDupSkillList_4ee4` (re-sectioned to db,
> byte-identical, extracted by `tools/dump_dupconv_table.py` →
> `extracted/enemy_dupconv_flags.json`); the scan self-matches, so an
> enemy converts iff ANY enemy precedes it in the order ($DD0B!=2 keeps);
> **DoT cap was documented WRONG** (Div16x8To16 leaves the remainder in A
> → 10+RNG16%6 / 30+RNG16%11; status.py corrected; heavy 13/13); +2 bit1
> applier = PoisonAir $6D; curse self-hit = 4 RNG2 branches (turn lost /
> HP−MaxHP/6 / MP−MaxMP/6 / confusion), actor still acts after HP/MP;
> act-time re-resolve + MP/seal veto rules; status-spell ladders (all
> $6710); KO transient full-HP; flying Quake victims are visited, not
> damaged (§13.7 corrected); LoadBtlC_5857 = skill-$41 exemption; phase-9
> sub 0 = byte-exact status decay. Annotated in source (bank $050/$052/
> $053 comments + the 5 dup-conv labels; clean `1ca6579…` unchanged).
>
> **PATCH (item #4 test): two AI-commit bugs found on the real save and
> fixed** — AI-committed Tremor/Quake swept the PARTY (S84 stub row $6367
> = own-side base; vanilla $E5 slack row too) → $E5-$E8 now route to
> `Jump_058_62bf` (the vanilla group-attack service); AI-committed Anchor
> was a self-inflicted MegaMagic (CustomDispatch52's damage setup precedes
> the "no-op" ret). **USER-TESTED S85 (ROM `4c8de38a…`): AI-committed
> Tremor, Mourn, Infernos work**; the no-op Anchor turn showed an orphan
> "Has no effect on Slib!" line → **S85b: AI-committed $E4 is rewritten in
> the queue to $3A by DispatchBoundsStub** = vanilla behaviour (vanilla's
> AI commits StepGuard/MapMagic and they run as Attack — measured), PyBoy-
> verified 5/5 turns "Slib attacks!". **Patched test ROM md5
> `a17bff8e67f3043fbff653c65128ea16` (S85b), NOT yet user-tested.** The
> player-menu path was never affected (why S74's test passed). editor2
> `test_compiler --rom` re-pinned to `a17bff8e…` (39/39; S84's move was
> never recorded there). Verifier PASS 6/6.)
>

> Last verified: 2026-09-03 (Session 84 — **S81-remainder measurements +
> CRASH FOUND AND FIXED in the S74/S75 custom-skill dispatch.**
> BtlSkillTargetDispatch_401d (230 rows, $00-$E5, abuts the $41E9
> service) has NO bounds check in BtlQueueFetchService_5498; AI-committed
> ids > $E5 far-jump through code bytes (E6→$5621, E7→$01DB, E8→$0008,
> E9→$CDAF = WRAM execution — reproduced live: tactics AI committing
> Mourn from the hacked save's starter). S74/S75 verification missed it
> because rigs FORCE queues, bypassing the commit-time dispatch.
> **Fix: DispatchBoundsStub** — same-size call-site replacement $54C2 →
> stub at $694F free space ($E6-$E8 → $6367 like E5's slack row; $E9 →
> $41E9 attack service; $EA+ → $6367). 40 changed bytes in bank $58 + 2
> header checksum bytes; byte-diff verified surgical. Emulator-verified
> (forced E9-only and E6-only movepools → clean AI commits, correct
> targets, full battles with damage). Patched test ROM (S84, "patched"
> md5 `b99455d67012e2f451cd5ed96a5020a1`) delivered. **USER-CONFIRMED
> S84: Mourn activates via tactics AI under Charge on the real save**
> (the pre-fix hard-freeze path). Quake ranks $E6-$E8: fix built +
> PyBoy-verified, NOT yet user-tested. Enemy-side uses the identical
> shared service (not reachable in normal play — no vanilla enemy
> movepool holds ids > $E5).
>
> S81-remainder decodes (measured + byte-verified; owning §15.9/15.10.7a-
> .10.10, KEY_LESSONS S84, known_RAM_map rows DD03/DD0B/DB50-53/DB61):
> commit-time target write site = entry 8 itself (frame-exact; the S83
> $50:$4C87 breadcrumb was the player Massacre path; $6379 side-blind BY
> DESIGN); $dd0b per-slot INT ladders both sides incl. the enemy lo-byte
> quirk (boundary-measured 20/21/65/185); the TACTICS mechanism ($DD03
> nibble = tactic 0-3, +20/+45 category bias via $6F8C, obedience level
> gate <21/≥$F0, score formula, $7997 4x27 table extracted); MISS/dodge
> act-time gate machine in bank $53 (Surround 62.5%, $db07&3 37.5%,
> Dodge-status 50%, AGI ladder 2/8/43 per 256; flags7/flags8 record bits;
> $52 twins DEAD CODE; $DA33 = presentation countdown only); plain-attack
> targeting $41E9/$441B full decode, rolls verified 4/4 (50/33/17
> front-weighted); lightweight picker full decode incl. self-healing
> empty-category cursor walk; 77a4 = "tactic==Cautious". Group-cast→$3A
> round-conversion rule observed, MP-gate hypothesis FALSIFIED, rule
> untraced. Loop-level battle.py validation still OPEN (ROADMAP).
> Verifier PASS 6/6; clean `1ca6579…` unchanged.)

## Session Index (finding aid — verbatim blocks in SESSION_HISTORY.md; owning docs are canonical)
- **S83** (2026-08-20): annotation catch-up part 2 (gate CLEARED) — banks $52/$53/$58 battle core annotated (28-state BtlActStateTable, ActPhaseStateTable, TurnOrder*, the 230-dw BtlSkillTargetDispatch_401d; §15.10.6 entry-8 correction). Byte-neutral. Owning: the three bank sources, BATTLE_SKILL_SYSTEM §15, DOC_AUDIT S83, KEY_LESSONS S83, ROADMAP S83.
- **S82** (2026-08-15): annotation catch-up part 1 (Iron Rule 6 gate) — bank $57 AI decision machine annotated in source (state dispatch + chain tables → dw, 131 rule routines labeled, CheckMonsterSlot CF-inverted comment fixed, cat2 count 85 not 61). Byte-neutral. Owning: bank_057.asm, BATTLE_SKILL_SYSTEM §15.10.5, DOC_AUDIT S82, KEY_LESSONS S82, ROADMAP S82.
- **S81** (2026-08-14): combat-simulator arc part 4 — evaluator rule chains decoded end-to-end + validated 240/240 (chain architecture $4302→$4308/$4358/$4404; $DD26/$DD27 accumulators; $4E36 vanilla AoE bug user-flagged as romhack fix candidate; family-cut pair; caster-profile matrix); target resolution ~2/3 ($51E8 act-phase machine, $6379 resolver, $4799 re-resolve; OPEN side-constraint + post-commit write). Iron Rule 6 + annotation gates decided. Owning: BATTLE_SKILL_SYSTEM §15.10.5-6, known_RAM_map [S81], KEY_LESSONS S81, ROADMAP S82/S83.
- **S80** (2026-08-13): combat-simulator arc part 3 — enemy AI decision machine traced + validated 26/26 over 10 EIDs (bank $57 correction; ai_weights→category-base mapping; score formula + mod ladder; quirky sort + hidden-$73AB not-rank1 bonus; option lists; sums; tag filter + $DD26 evaluators (stubbed); pick/tie/commit; $dd0b modes; S79 stall root cause = unbounded $dd02 retry); PyBoy hook input-timing trap + dense-cadence protocol. simulator/ai.py + measure_ai.py + validate_ai.py + ai_events corpus. Byte-neutral. Owning: BATTLE_SKILL_SYSTEM §15.9-15.10, known_RAM_map [S80], PYBOY_DEBUGGING, KEY_LESSONS S80 (3), ROADMAP S80/S81, TOOLS_AND_DATA §2.10.
- **S79** (2026-08-10): combat-simulator arc part 2 — turn order traced+validated 143/143 ($58:$54D1; $DB79/$DB82; defensive-class/SquallHit/PsycheUp priorities); 28-state action machine; apply-step ids; phase 9 = end-of-round DoT; status byte map + exact sleep wake; all four §15.6 items measured; link-vs-arena fork corrections; round core battle.py. Owning: BATTLE_SKILL_SYSTEM §15.6-15.9, TOOLS_AND_DATA §2.10, known_RAM_map, KEY_LESSONS S79, ROADMAP S79/S80.
- **S78** (2026-08-10): combat-simulator arc part 1 — damage layer traced + validated 698/698 (simulator/damage.py); $DB73 battle type + boss-protection gate; resistances/ladders/specials. Owning: BATTLE_SKILL_SYSTEM §15, TOOLS_AND_DATA §2.10, ROADMAP S78.
- **S77** (2026-08-06): randomizer part 2 — breeding tree regeneration (depth-targeted), stratification, skill assignment rebuilt onto vanilla placement; the BLIND power field finding (43 handler-computed skills); per-entity `profile_check.py`. Owning: BATTLE_SKILL_SYSTEM "power field is BLIND", ROADMAP S77, TOOLS_AND_DATA §2.9.
- **S76** (2026-08-06): standalone randomizer + German build in scope (`08bca718…`, bank-$14 tables +$70); two user-caught difficulty bugs (learn-gate≠damage-gate; quantile banding) → `audit_threat.py` per-row parity; library recipe TEXT decoded. USER-TESTED. Owning: ROADMAP S76, TOOLS_AND_DATA §2.9, KEY_LESSONS S76.
- **S75** (2026-08-02): custom skill $E9 "Mourn" (physical-base custom via MournDispatch52) + the battle RIG (TriggerBattle-mimic $DA03/04+$DA02+$DA09+$C905+$C8EB.6, per-frame $dcec forcing); .sav build-specificity lesson; v4 pin `ce1e7369…`. Owning: BATTLE_SKILL_SYSTEM 13.x, KEY_LESSONS S75/S75b.
- **S74** (2026-08-01, v2/v3/v4 2026-08-02): custom skill chain $E5-$E8 "Earthquake" — sweep fork + victory gate, tier-scaled shake bursts in the cast-anim slot, wind anim removed at the anim-index source, 2/3-line announce banners, fly-dodge beats (party-side only, keyed on $db89), SKIL descriptions, ROM0 back to vanilla. PyBoy-verified. Patched pin `d1f5eb49…`. Owning: BATTLE_SKILL_SYSTEM 13.7 (+13.7.9).
- **S73** (2026-07-31): custom skill $E4 "Anchor" — field-cast pipeline RE'd (menu shell $c90d 0-4, usability whitelist, bank $14 entries 4/5, menu-armed script protocol ctr=$FFFF); anchor gate floor → warp GreatTree → return for 3/4 current MP charged on arrival; persists through save; S73b descriptions (table $56:$6667) + battle rejection (LoadBtl_4b98/FieldOnlySkillA). SHIPPED, USER-CONFIRMED; pin `224b1176…`. Owning: BATTLE_SKILL_SYSTEM §14 + §14.1, GATE_GENERATION, EVENT_FLAGS, known_RAM_map (+$50/+$52/+$54/+$56 correction), KEY_LESSONS S73, PROJECT_COMPILER (template re-pin).
- **S71** (2026-07-26): FX1 — active farm 17→37 slots (array 40; sleep pool → SRAM bank 2 "P1"; "F2" reformat + checksum v3; snapshot "R4"; wMonList $D001). SHIPPED, USER-CONFIRMED; v2 exp-scale veto → pin `46ba6991…`. Owning: MONSTER_DATA (FX1 as built), ARCHITECTURE (checksum v3), KEY_LESSONS S71.
- **S70** (2026-07-25): E2 — data-driven side quests (progression.quests/enemies → generated scripts + bank $14 quest EIDs; vanilla_exit_extensions; walk-on y=7 Entry-6 skip) + the PyBoy measurement regime; 3 pins, a5a5e0d5 current that session; init_dialog protocol; 385-frame exit ceremony fixed. SHIPPED, user-confirmed. Owning: PROJECT_COMPILER §progression, PYBOY_DEBUGGING, SIDEQUEST_MAP, CROSSBANK_ROOMS, MONSTER_DATA, KEY_LESSONS ×9.
- **S69** (2026-07-19): E3 — 32 KB SRAM via the RAMB PIN (19 ROM0 quadrant writers → $6100; header $03) + bank $73 entry 9 CF3SRAMBankedCopy; S69v2 persistence v3 roster snapshot (bank-1 "R3", reset-rewind semantics restored) — user-confirmed 5/5 smoke. Owning: ARCHITECTURE "SRAM banking as built S69", MONSTER_DATA, bank_073 banner.
- **S67** (2026-07-19): E1 — arena/gate-boss roster format decoded (byte-neutral; NO roster table — op $1F EID formula $E0+9*group+3*match+slot over enemy-stats rows; 53-site boss-script census; $14:$4893 = fight→join redirect; Coliseum RNG bands; $DA02/03/05/07/09 battle-slot RAM; HW-verified same session). Owning: SIDEQUEST_MAP "Arena / gate-boss ROSTER format — DECODED S67", arena_brackets.json, DOC_AUDIT S67 (2), KEY_LESSONS S67 (2).
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
6. **Annotation is not optional and gates progress (user decision S81).**
   Every session that decodes engine behavior annotates the touched
   disassembly regions (labels + comments, zero byte impact, byte-perfect
   rebuild is the check) IN THE SAME SESSION. New decoding, features, or
   simulator/editor work may NOT begin while an annotation backlog exists —
   the backlog is tracked as ROADMAP items and burns down first. Rationale:
   the disassembly is the primary artifact; docs and simulator are views
   onto it. Knowledge parked only in docs has already cost repeated
   re-derivation (KEY_LESSONS S80 grep lesson, S81 $45EA wrong-bank detour).


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
| FIELD-cast custom skills (menu → context logic → dialog → effect) | ✅ SHIPPED, USER-CONFIRMED S73 (+S73b descriptions & battle rejection): skill $E4 "Anchor" (anchor gate floor → warp to GreatTree → return later for 3/4 current MP charged on arrival; persistent through save; single-use; forced-standard regenerated floor). Full field-cast pipeline RE'd: usability whitelist, $da5e, bank $14 entry 4/5, menu-shell states ($c90d 0-4), script arming from the menu. PyBoy-verified round trip via the real UI. | BATTLE_SKILL_SYSTEM §14; bank $72 AnchorField14Tail; patched pin `8fa605d7…` |
| Menu-armed dialog scripts in ANY room (incl. maze floors) | ✅ user-confirmed S73 (part of Anchor): $D8D3=$71 + ctr=$FFFF arming; GateAwareDispatch script-type branch (≥$6B, ≠$70) | PROJECT_COMPILER §5 (template re-pin); KEY_LESSONS S73 |
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
| Custom battle skills (net-new ids) | 🟢 NINE custom skills live: MagicBurn $E0 (S49), Tame $E1 (S50), TameMore $E2 + TameMost $E3 (S52), Anchor $E4 field-cast (S73, user-confirmed), Earthquake chain $E5-$E8 (S74; **S84: AI-commit of $E6-$E8 was CRASH-CAPABLE on all pre-S84 builds** — dispatch-table overrun, fixed by DispatchBoundsStub; PyBoy re-verified S84, awaiting user test), **Mourn $E9 (S75: ATK-vs-DEF × (dead allies+1), 2nd dispatch trampoline = per-skill vanilla damage machine; **S84: AI-commit was CRASH-CAPABLE (wild jump to WRAM) on all pre-S84 builds** — fixed S84; AI-commit activation USER-CONFIRMED on the real save (Charge tactics))** — all on the full de-aliased stack incl. natural-learn, real MP, announce, descriptions. | BATTLE_SKILL_SYSTEM §12–§13.8, §14; ROADMAP Arc 2 |
| SRAM save layout | ✅ audited S8: custom flags persist (truly-safe pool = 32 flags, S57); collisions mapped; free SRAM tail $BFC8-$BFFF (56 B, reserved). **32 KB expansion BUILT S69 (RAMB pin + CF3SRAMBankedCopy; NOT yet user-tested)** — +24 KB persistent in banks 1-3, uninitialized until a schema exists (E3 residual) | ARCHITECTURE "SRAM banking as built S69"; known_RAM_map |
| Custom-room WRAM state | ✅ migrated S65 into the CF3-freed window (buffers $CC80/$CD00, counter region $CD80×640, wCustomPool $D001-$D664; TRANSIENT permanently, init-guaranteed zeroed). v7 USER-CONFIRMED S66 | patches/wram.asm banner; PROJECT_COMPILER §2.6; ROADMAP CF4 |

### Not yet implemented

| System | State |
|--------|-------|
| Custom monster pools (Encounters #2) | Specced in CROSSBANK_ROOMS; not built |
| Custom music | 🟢 **M1-M3c COMPLETE (S61-S64, all user-confirmed)**: engine map, round-trip codec, general slots (bank $74), room-default assignment for any mapID, `custom.music` schema, 31-song DWM2 catalog, MIDI import. Open boxes: InitBGM channel-count ext (4/5ch sources), gate/event music, CI compiler-test |
| Arena/boss roster AUTHORING (E1→E2 wiring) | RE ✅ DECODED S67 (arena path HW-verified); authoring spec in SIDEQUEST_MAP + arena_brackets.json. project.json schema wiring = E2, not built |
| Combat simulator (arc S78-S85) | 🟢 **Round core VALIDATED (S85)**: `simulator/damage.py` 698/698 (S78) + specials (S79); `turn_order.py` 143/143 (S79); AI `ai.py` 26/26 + rule chains `ai_rules.py` 240/240 (S80/S81); **`battle.py` loop glue 6614/6614 over 25 engine battles (S85, `validate_battle.py` + `s85_battle_events.json`)**. Residuals (§15.9): multi-candidate target RNG pick, confusion action table, status-rider chances, `simulate_round` RNG idle policy (= the pacing layer's first question). Next: S80 pacing layer. | BATTLE_SKILL_SYSTEM §15; TOOLS_AND_DATA §2.10; ROADMAP S81/S80 |
| Randomizer (standalone; English + German builds) | ✅ **SHIPPED, USER-TESTED, part 2 S77** — `randomizer/`, data tables only plus ONE code change (`plusgrowth.py`, opt-out). Breeding tree regenerated to a target depth profile (3-6) with deeper = better; bosses/arena/wild stratified against vanilla's measured correlations; skills dealt from vanilla's usage bag and never below vanilla's minimum placement level; growth shuffled within vanilla-ordering bands; paralysis + full heals banned on boss/arena rows; pools de-duplicated. Gate: `randomizer/profile_check.py` (per-entity envelopes) + `randomizer/audit_threat.py` (per-row damage parity). | randomizer/README.md; BATTLE_SKILL_SYSTEM §record power field is BLIND; BREEDING_SYSTEM §Depth is a function of matcher SPECIFICITY; MONSTER_DATA §Growth randomization needs a per-species envelope; PROJECT_COMPILER §Validation the editor must run |
| Editor app (Phase 3) | 🟢 **Walking skeleton BUILT S72, NOT yet user-tested** (`editor2/app/`, PySide6, cross-platform — primary macOS; open/rooms/Build/Run; GUI build machine-verified byte-identical to the `46ba6991…` pin via `editor2/tests/test_app.py --rom`). Next boxes: NPC sprite-id catalog, embedded-PyBoy preview, room canvas (ROADMAP Phase 3). Backend keystone (S42) + compiler (S53+) done |

### Disassembly annotation (measured 2026-06-13, not estimated)

Objective metric: meaningful (non-auto) labels + comment density per bank.

| Tier | Banks | Notes |
|------|-------|-------|
| Fully annotated (11) | $00 $03 $04 $0B $0C $0D $0E $0F $13 $14 $41 | Core engine + script data banks |
| Useful partial (≈17) | $01 (36%) $16 (30%) $17 (75%) $50 (21%) $51 (27%) **$52/$53/$58 (S83: damage pipeline, action machine + state tables, per-actor gates, act-phase machine, turn order, queue/target dispatch all labeled+commented; remaining internals neutral)** **$57 (S82: machine + chains + all 131 rule heads labeled; bodies partly soup — see ROADMAP S82 residual)** and tileset banks $23–$31/$37/$38 (data-only, trivially "done") | Post-S43 arcs also deepened $47 $54 $5f (not re-measured) |
| Effectively raw (~79) | everything else | mgbdis output, auto labels |

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
editor2/                       THE editor: core/ (headless compiler/builder/
                               emulator — never imports Qt), app/ (PySide6 GUI,
                               S72 skeleton), example-project/ (regression
                               baseline), tests/ (test_compiler, test_app)
examples/                      Reproducible swap/species examples (not baked)
towards_editor/                DWM1_Tile_Editor.html — standalone room-design prototype
data/                          DWM-original.gbc (gitignored, user-provided)
FULL_FAQ.txt                   Full game guide (root; game structure/quests reference)
ALL_ROOMS_FINAL.png            Rendered room atlas (root)

