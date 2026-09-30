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

> Last verified: 2026-09-30 (Session 104 — **ROADMAP P3.10a: SPIRIT AS THE
> 11TH FAMILY** (user 13:07: "1) Custom skills absolutely stay!! … All data
> related to them must also be in editor. 2) Yeah please fix ??? and make
> spirit separate. Wisp is fine just make it look nicer. 3) Breeding table will
> utilize spirit extensively … Plan for it. 4) Of course spirit is in library.
> Given all this, please proceed. Make your own mockups for spirit and Ill
> pick"). S103 USER-CONFIRMED at session start. **Built S104 (r1-r5);
> r5 USER-CONFIRMED 2026-09-30 15:51 ("perfect. Hand off.").** Verifier PASS 6/6 (check 5 now also runs
> `build_family_icon.py --selftest`; `bank_06d.asm` in PATCH_NEW_FILES); clean
> `1ca6579…` byte-perfect (bank $41 `$4000-$4338` re-sectioned into the mode
> list + mode 0-4 tables, bank $0A `FamilyIconGfxTable0A` + `LoadFldA_46c9`,
> bank $09 default-name and bank $07 pedigree annotations — both trees);
> **patched pin MOVED `5d1dbc5f…` → `eee9f5b0…` (patched)**; test_compiler
> --rom 233/233; test_app --rom + test_canvas --rom PASS. `EDITOR_REVISION` =
> 'S104'.
>
> **Engine (BREEDING_SYSTEM "Spirit — the 11th family (S104)"):** new
> hand-authored bank **$6D FAMILY SYSTEMS** — entry 0/1 family-icon gfx id
> (families 0-9 = `$2E03+fam`, Spirit = `SpiritIconStream`, gfx id `$6D04`),
> entry 2 farm-dialogue text group (11 entries; Spirit = group D),
> entry 3 naming-screen default name (Spirit → mode-3 ids `$A0-$A7`) — behind
> same-size forks in banks $01 (was ClampFamIdx → ??? tile), $0A (the
> UNCLAMPED twin table: family 10 read code as a gfx id), $04 (opcode $2D read
> garbage) and $09 (names ran into the next table); bank $16 family scan `$FA`
> wildcard `jr z` → 2 nops (`$FA` = Spirit); bank $4F ??? glyph restored at
> `$41A0`, Spirit glyph at `$41B0` (byte `$1A`); bank $41 mode-4 Spirit string
> `"$1A"`, 8 Spirit names in the dead `$4323` words + tail fill; bank $07
> pedigree "unknown parent" icon id 10 → 11 (**found S104: vanilla id 10 is
> the empty "no family" string; since B9 every unknown parent drew the Spirit
> icon**). The B9 "$1A is not fill-immune" note did not reproduce (DOC_AUDIT
> S104). Editor: `"Spirit"` family / matcher everywhere, library token
> `<$1A>family`, `"AnyFamily"` refused, help topic updated.
>
> **PyBoy (stub-calls from WRAM + real screens; old build vs new):** INFO page
> `$1A` glyph for family 10, "?" for 9; HUD tiles `$8DA0-$8DCF` = Spirit stream,
> identical to S103 for 0-9; bank $0A list (stub `LoadFldA_4610`) Spirit tile
> at `$88B0`, identical for 0-9; default names identical 0-9, Spirit WISP /
> NOVA / ECHO; dialogue ids identical 0-9, Spirit `$7C` (group D; was `$EA3C`);
> breeding (`$16` entry 3) identical over every pair of non-Spirit species,
> `[Spirit × Dragon]` → MadSpirit and `[Dragon × Spirit]` → Spooky fire;
> pedigree unknown parents blank again; library tab strip page 3 = Spirit
> icon, page 2 ??? = "?". Test ROM **`DWM_S104_spirit_test.gbc`** (patched, md5
> `a7cf5159…`) = the user's project + a demo overlay (NOT in their project):
> Healer / Spooky / Shadow / MadSpirit in Spirit + those two recipes; the
> user's project as-is built `d17633de…` (patched, r1).
>
> **S104 r2 (user 14:35: "1) Ghost whisp is the best BY FAR, use that. 2)
> Doesnt matter. Just make option in editor. 3) Huh wtf is this? What eight
> placeholders? ALSO: I cant enter library on your map because it leads to
> custom room. The rest works fine.")** — r1 test ROM passed except the
> Library door, which the USER'S project redirects to its own room
> (`entrance_redirects` GreatTree scr 8 (5,3) → cities_fount; test overlay r2
> drops that redirect only). Icon = mock-up B ghost wisp; new
> `gamedata.families` (per-family dialogue voice A-D, Spirit's 8 default
> names = the naming screen's random pre-filled name) as compiler regions in
> banks $6D / $41; the editor's new **Families** tab (members, move / add,
> voice, Spirit names). Pin **`eb153510…` (patched)**; test_compiler --rom
> 241/241; test ROM **`DWM_S104r2_spirit_test.gbc`** (patched, md5
> `008435d6…`; PyBoy: the Library door enters `$12`, INFO / HUD / library tab
> show the ghost wisp); the user's project as-is builds `48edddfc…` (patched).
> `EDITOR_REVISION` = 'S104r2'. Built, NOT yet user-tested.
>
> **S104 r3 (user 14:56: "Nope when looking up spirit family in library it
> freezes"):** reproduced in PyBoy — and it was not Spirit-specific: since FX1
> (S71) the B7 library writer `LibScanByFamily` filled `$C0D8` while FX1 had
> moved every bank-$12 reader to `wMonList`, so every tab showed the roster
> list (DrakSlime… on every tab) and a lookup opened species = the list index;
> on the Spirit tab that index was an unseen species → text id `$FF` → the
> text engine never finished. Fix: the writer targets `wMonList` (same size,
> `patches/bank_012.asm`). PyBoy: Spirit tab lists Healer (the other demo
> members are unseen on this save = blank, as vanilla), its page opens; the
> Dragon tab lists its own (unseen = blank). Pin **`d7b762db…` (patched)**;
> test ROM **`DWM_S104r3_spirit_test.gbc`** (patched, md5 `acfd4ea9…`); the
> user's project as-is builds `ec4df754…` (patched). Verifier PASS,
> test_compiler --rom 241/241, test_app / test_canvas --rom PASS.
>
> **S104 r4 (user 15:13: "It wiped my sav file … when I reload it 1) make top
> row of screen glitchy, and b) wipes sav file again if I press reset"; sent
> `rom.s1` + `rom.sav`):** NOT an S104 regression — an FX1 (S71) bug,
> PyBoy-reproduced on the S103 test ROM too, and from a clean save: save at
> the farm, save again in the castle, CONTINUE, reset → new game. The R4
> snapshot's 94th chunk carries 28 bytes of the tile image `$BCC8-$BCE3`,
> committed BEFORE SaveGameState writes that block, so it is the PREVIOUS
> save's top row; CONTINUE restored it (the glitchy top row) without a new
> checksum (segment 3 covers `$BCC8`) → the next boot found no save. Fix:
> bank $73 R4 restore = 93 chunks + `CF3SnapTail4` (`$B124-$BCC7`). PyBoy on
> r4: the user's sent `.sav` CONTINUEs in the castle with the right top row
> and survives a reset; farm → castle save → CONTINUE → reset keeps the save
> (r3: lost); unsaved farm edits still rewind (incl. the 4 tail bytes);
> library visit + save + reload keeps party and farm identical. Pin
> **`e994173e…` (patched)**; test ROM **`DWM_S104r4_spirit_test.gbc`**
> (patched, md5 `5e25799e…`); the user's project as-is builds `52e13c28…`
> (patched). **USER-CONFIRMED 2026-09-30 15:34 ("Great that fixed it!").**
>
> **S104 r5 (user 15:42: "Just a display reorder. Feel free to do it now if
> small"):** Spirit shown BEFORE ??? — bank $12 `LibTabToFamily` +
> `LibTabOrder` (tab position → family) for the tab-strip icons
> (`SaveItem_6184`, same-size call) and `LibScanByFamily`; 39 tail fill nops
> consumed; editor `gamedata.DISPLAY_ORDER` drives the Families tab. No
> family byte / code changes. PyBoy: page 2 = Bug, Devil, Zombie, Material,
> Spirit (its list = Healer, page opens), page 3 = ???. Pin **`15f21834…`
> (patched)**; test ROM **`DWM_S104r5_spirit_test.gbc`** (patched, md5
> `67d32535…`); the user's project as-is builds `53338a16…` (patched).
> Verifier PASS, test_compiler --rom 242/242, test_app / test_canvas --rom
> PASS. **USER-CONFIRMED 2026-09-30 15:51 ("perfect. Hand off. Everything
> that has been changed since last repo push.").**
>
> ROADMAP revised this session: P3.9b (custom skills are NOT content to
> purge), new **P3.11c** (custom skills as project data), **P3.12** planning
> for the Spirit-heavy breeding redesign (11-family randomizer / optimizer as
> a proposer writing `gamedata.breeding`, depth read-out). **Next:** the user
> picks the next editor item. **Hand-off: all S103 + S104 work = the diff
> against `f2d9ece` (origin/master), delivered as
> `DWM-S103-S104-changed-files.zip`.**

> Last verified: 2026-09-29 (Session 103 — **ROADMAP P3.9: LAYER A-LITE —
> THE VANILLA DATA TABLES BEHIND project.json `gamedata`** (user: P3.3g "No
> fuck this. Bank and come back later if tiles become a problem … Move on to
> next editor item" → P3.3g BANKED with its S103 static audit in ROADMAP;
> then "Sure lets do 3.9 and if its ends up very fast lets do P3.7b part 2
> also" — P3.9 was not fast, P3.7b part 2 not started). S102 not re-confirmed
> this session. **Built S103; USER-CONFIRMED 2026-09-30 (test ROM: "Rom - all
> correct").** Verifier PASS 6/6 (check
> 5 also runs `extract_gamedata.py --selftest`; PATCH_FILES + the new hand
> patch `bank_013.asm`); clean `1ca6579…` byte-perfect (bank $04D recipe-string
> block and bank $01 `EncounterChancePercent` re-sectioned, bank $01 encounter
> code annotated — both trees); **patched pin MOVED `0d60486e…` → `5d1dbc5f…`
> (patched)**; test_compiler --rom 227/227; test_app --rom PASS (GUI build ==
> pin); test_canvas --rom PASS. `EDITOR_REVISION` = 'S103'.
>
> **What changed (PROJECT_COMPILER §2.20):** `gamedata` is implemented as
> SPARSE overrides — `monsters`, `enemies` (EIDs 0-486), `encounters`,
> `skills` (mp / learn / record), `exp_curves`, `growth_curves`,
> `breeding.family` / `.special`, `boss_joins` — emitted into twelve same-size
> compiler regions in banks $01/$03/$06/$07/$12/$13/$14/$16/$4D/$54/$69 from
> the committed vanilla base `extracted/gamedata_vanilla.json`
> (`tools/extract_gamedata.py`); an empty `gamedata` == the ROM, table by
> table (test_compiler; `--rom` against the original ROM). The compiler keeps
> coherence: library recipe TEXT regenerated **in place** (the bank $4D mode
> table overlaps the recipe pointers — TEXT_SYSTEM correction), library tabs
> regrouped from the family bytes, Set 2 / Set 3 warnings, the B5 shadow
> validator ported. The pre-S103 hand edits (Spirit Dracky / Darkdrium, starter
> EID 1 harness, Gorbunok pool 0, B4 recipes, B5 overrides + appends) are now
> the **example project's `gamedata`** — byte-identical, except that its 4 B4
> recipe strings now match (17 B in bank $4D). Tool emit paths that wrote these
> bytes are retired (KEY_LESSONS S103).
>
> **Decoded (DATA_STRUCTURES "Encounter pool entry"; annotated bank $01):**
> pool +0 rate code → wC8A9, +2..+4 chance of 1/2/3 monsters, +5..+9 slot
> chances (codes → `EncounterChancePercent` $01:$69C0 = 0-100 %), +20..+24
> **max count** per slot (1 = only alone; NOT a weight), +25 maze size → $C93D.
> **Measured freeze:** a pool that can draw 2 monsters whose first draw has max
> 0 and no slot allowed twice re-draws forever (28,257 passes, no battle) — the
> compiler refuses it.
>
> **PyBoy on the user's save** (their project + the example's gamedata + demo
> edits = `DWM_S103_gamedata_test.gbc`, patched, md5 `1dbae0a5…`): Gate of
> Beginning = always one Slime; its battle row `$DA18` = the edited EID 2
> (HP 250, ATK 1, 500 exp, always joins) → 167 exp to each of 3, the Slime
> joins; HealMore USE MP 1 (5 on the same project without the demo edits);
> Snaily's encyclopedia page reads "Zombie family / Zombie family"; the Dragon
> tab lists 26 (Slime moved in), the Slime tab 20. The user's project WITHOUT
> gamedata now builds the vanilla tables (the POC edits are no longer
> inherited).
>
> **User sign-off 2026-09-30 12:53: "Rom - all correct"** (test ROM passed).
> Decisions: "Start off hack with original table. patches are POC trash" (the
> user's project keeps NO gamedata = vanilla tables); "Please do not include any
> patches in the editor, they are all trash (in terms of custom monsters, custom
> rooms, etc. The mechanisms are obviously vital)" → ROADMAP **P3.9b** (purge
> POC content from the hand overlay, keep the mechanisms); "I still want the
> FAMILY [Spirit], but for now no monsters assigned … assign to families …
> propagates to breeding … a new sprite for the spirit family" → ROADMAP
> **P3.10a** (Spirit as a first-class 11th family). Both audited (read-only)
> S103; not started. **Hand-off: all S103 work = the diff against `f2d9ece`
> (origin/master), delivered as `DWM-S103-gamedata-changed-files.zip`.**

## Session Index (finding aid — verbatim blocks in SESSION_HISTORY.md; owning docs are canonical)
- **S104** (2026-09-30): P3.10a Spirit as the 11th family (bank $6D family systems + forks, `$FA` = Spirit, icon on $1A, ??? restored, unknown-parent icon fix, `gamedata.families`, Families tab, display order) + two FX1 bugs fixed (library list buffer; R4 snapshot restore losing saves). USER-CONFIRMED. Verbose block in this file. Owning: BREEDING_SYSTEM "Spirit — the 11th family (S104)", PROJECT_COMPILER §2.20, EDITOR_DESIGN §5.2a, KEY_LESSONS S104.
- **S102** (2026-09-28): P3.3f own animated tiles — compiler-owned bank $6C (`CustomTileAnimate`, GDMA frame copies in HBlank, ≤ 8 tiles/frame, line 127 skipped), the Animate tab (flip / drift / sway, any speed, plain budget; r2 frames side by side, r3 per-tile / per-cell tools), `LCDCStateTable` decoded, VRAM bank 1 found empty in the field (→ P3.3g). Owning: PROJECT_COMPILER §2.19, ROOM_DATA_FORMAT "Own tile animations (S102)", EDITOR_DESIGN §5.1, KEY_LESSONS S102.
- **S101** (2026-09-27): P3.7b part 2 first half — custom boss floors (`custom.gates`: floor count, boss = custom / vanilla room, hand-made gates), monster NPCs $F0-$F3, conversation trees (`talk.steps`: flags, YES/NO, 1-3 enemy battles, helper exit, arrival fights), project enemies in bank $6B + join versions; r2 Warubou helper landing beside the player; r3 Help tab; r4 castle arrival (priest heal / King speech), World zoom; pins `7cd7257b…` → `9c813041…` (patched, historical). USER-CONFIRMED 2026-09-27 except the helper (r2-r4 NOT yet user-tested). Owning: GATE_GENERATION §7.7, PROJECT_COMPILER §2.17/§2.18, ROOM_DATA_FORMAT "Monster NPCs", MONSTER_DATA "Project enemy rows", EDITOR_DESIGN §5.1b, DOC_AUDIT S101.
- **S100** (2026-09-27): P3.7b part 1 — custom rooms served on gate floors (rules: gate / floors / chance / flag terms / once per dive; `GateDecisionFork` → bank $71 entry 4; saving via entry 5 + bank $07 `SaveAllowCheck`; gate-room music / battles), Gates tab v1, r3 cream descent wipe (bank $73 entries 19/20) + compressor MAX_COPY fix; special rooms only on floors 3/6/9 (DOC_AUDIT S100); pins `d072eb51…` → `7cd7257b…` (patched, historical). User-passed at S101 start. Owning: GATE_GENERATION §7.6, PROJECT_COMPILER §2.16, EDITOR_DESIGN §5.1b, KEY_LESSONS S100, DOC_AUDIT S100.
- **S99** (2026-09-27): P3.3e animated tiles — measured animation census, per-room animation source (bank $71 entry 3 + bank $01 PerRoomVRAMDispatch same-size rewrite), canvas outline + ▶ Play, clones = source; Make animated tab (r3-r7) + stray repair / Make still; pin `ce24de8b…` → `d072eb51…` (patched, historical). Signed off 2026-09-27 (r7 not re-tested in-game). Owning: PROJECT_COMPILER, EDITOR_DESIGN §5.1, TOOLS_AND_DATA (census_room_animation), KEY_LESSONS S99.
- **S98** (2026-09-26): rooms group C = P3.7 — door OBJECTS linked two-way (+ Door, double-click to connect, arrive ON the door), one-way teleports, EXAMINE spots ($80-$83/$8F — the "$8F spawn" misnomer retired) + STEP-ON triggers ($90), talk scripts (YES/NO, set/clear flags, move), World graph v0; tileset tools (own copies, split move, purge); pin unchanged `ce24de8b…` (patched, historical). Doors USER-CONFIRMED 2026-09-26. Owning: PROJECT_COMPILER §2.14, ROOM_DATA_FORMAT "Interact entries ≥$80" + "Arrival and edge rules", EDITOR_DESIGN §5.1 S98, DOC_AUDIT S98.
- **S97** (2026-09-25): rooms group B — P3.5a flag state rules (bank $60 entry 8 + bank $17 hook) + P3.5 NPC inspector with the NPC behaviour engine decoded (13 measured behaviours, hidden bit); r2: cream text / YES-NO boxes in free-colour rooms (bank $73 entries 14-18), per-box talk editor; pins `6e97fd37…` → `ce24de8b…` (patched, historical). USER-CONFIRMED 2026-09-26. Owning: PROJECT_COMPILER §2.13, ROOM_DATA_FORMAT "NPC behaviour types", TEXT_SYSTEM "Text boxes", EDITOR_DESIGN §5.1 S97, KEY_LESSONS S97, DOC_AUDIT S97.
- **S96** (2026-09-25): rooms group A — P3.3c tileset slot map + vocabulary release, tileset switching / blank sheets, the Import Art tab (DWM2 PNG rips), per-subtile metatile palettes, bank space meters, "Make editable" fixed for all 98 vanilla rooms (extract_room bank/attr/arity fixes; `script_param_counts.py`, 102 opcodes); round 2/4 engine: FreeColor1Hook own colour 1 + MenuOpenFreePal; pin `5db25d15…` (patched, historical). USER-CONFIRMED 2026-09-25. Owning: EDITOR_DESIGN §5.1 S96, PROJECT_COMPILER §2.11 + §11, GATE_GENERATION §7.1, TOOLS_AND_DATA S96, KEY_LESSONS S96, DOC_AUDIT S96.
- **S95** (2026-09-24): user feedback round on S94b — metatile VOCABULARY (never shrinks, protected slots), borrow tiles from any vanilla room (import across tilesets), on-open migration of pre-S94 projects, `screens[k].palette` + per-screen/state palette selector + copy-from-vanilla palettes, minimal GUI exits, Borrow tab; editor-only (pin `fc1caa98…` held, historical patched pin). Owning: EDITOR_DESIGN §5.1 as built S95, PROJECT_COMPILER §2.11 + §11, TOOLS_AND_DATA S95, KEY_LESSONS S95, ROADMAP P3.3b residual + P3.3c + P3.5a + P3.7.
- **S94** (2026-09-20): P3.3b canvas v2 + the room model (vanilla/custom columns, clone-with-confirm, metatiles, walkability BR-subtile twins, 4×4 grid, per-(screen,state) attr+palette engine tables, compiler-owned ROM0 records) + S94b entrance redirects & per-state rooms; pin `fc1caa98…`. Owning: EDITOR_DESIGN §5.1 as built S94, PROJECT_COMPILER §2.11/§2.12/§11, ROOM_DATA_FORMAT (walkability, states), GATE_GENERATION §7, TOOLS_AND_DATA S94, KEY_LESSONS S94, ROADMAP P3.3b.
- **S93** (2026-09-19): P3.3 room canvas v1 + the editor shell (live renderer render_project.py pixel-identical to render.py; byte-exact Document model; Session/QUndoStack; Rooms tab v1; test_canvas.py --rom acceptance). Byte-neutral. Owning: EDITOR_DESIGN §5.0/§5.1, PROJECT_COMPILER §11, TOOLS_AND_DATA S93, KEY_LESSONS S93.
- **S92** (2026-09-19): P3.2 [G-A] $64/$67 fold + P3.2b [G-J] clone extractor + states[] backend; Arena Lobby cloned ($72), Library door repointed (testing stance); $27 = MonsterPartyOp2 0 params; load-order rule for state selection. Owning: PROJECT_COMPILER §2.10, TOOLS_AND_DATA (extract_room), KEY_LESSONS S92, DOC_AUDIT S92, ROADMAP P3.2/P3.2b.
- **S91** (2026-09-18): P3.0 CAPACITIES reference + P3.1 NPC sprite catalog (8-NPC hard cap measured, sprite-sheet VRAM budget, 137-id catalog, zero crashes; npc_catalog.json phantom-step contamination found). Byte-neutral. Owning: ROOM_DATA_FORMAT "NPC capacity & sprite-sheet budget (S91)", capacities.json, npc_sprite_catalog.json, EDITOR_DESIGN §9 G-B/G-M, TOOLS_AND_DATA S91, DOC_AUDIT S91, KEY_LESSONS S91, ROADMAP P3.0/P3.1.
- **S90** (2026-09-18): EDITOR_DESIGN v2/v2.1 — full tabbed UI spec, Layer A-lite, Balance tab, gap register G-A..G-P, fork-don't-fiddle + canvas-first principles, Phase 3 re-cut into P3.0-P3.17; simulator arc adjudicated done-for-purpose. Docs only. Owning: EDITOR_DESIGN v2; ROADMAP Phase 3 + S90; DOC_AUDIT S90.
- **S89** (2026-09-17): simulator wrap-up part 2 — Group-B residuals closed ($DB07 = IRONIZE counter; Cover/Guardian guard-redirect table validated 14/14; WLD level-up writer = none; board_from_event real ai_bases/WLD; $DB42 ×1.5 boost writer found, suites 426/0 + 3422/0; $670E re-sectioned). Owning: BATTLE_SKILL_SYSTEM §15.6/§15.9, battle.py guard_redirect/target_unreachable, MONSTER_DATA "Party Monster Structure", known_RAM_map [S89], TOOLS_AND_DATA S89 rows, ROADMAP S89, DOC_AUDIT S89.
- **S87** (2026-09-15): commit-model close-out — party category bases from the instance record (creation-roll decoded), obedience gate EXACT 889/889 on the WLD stat (wBattleLVL = WLD, not level), $7997 closed, TRUE-loaf sighted, pacing.py upgraded. Owning: BATTLE_SKILL_SYSTEM §15.10.1/.7a, MONSTER_DATA "Party Monster Structure", known_RAM_map [S87], KEY_LESSONS S87, ROADMAP S87, DOC_AUDIT S88.
- **S86** (2026-09-15): pacing layer done — measured RNG idle model (`measure_idle.py`→`s86_idle_model.json`), full-battle driver `pacing.py`, aggregate-validated (`validate_pacing.py` round-level PIT uniform + 5 fresh real-save battles in envelope), `sweep_ttk.py`, `profile_check --ttk`. Owning: BATTLE_SKILL_SYSTEM §15.8c, TOOLS_AND_DATA §2.10, KEY_LESSONS S86, ROADMAP S80/S86.
- **S85** (2026-09-05): loop-level differential validation of the round core (measure_battle 31 waypoints, 25 battles, validate_battle 6614/0) + the AI-commit Tremor/Quake party-sweep and Anchor-MegaMagic patches (S85b $E4→$3A rewrite; pin `a17bff8e…`, USER-CONFIRMED S86). Owning: BATTLE_SKILL_SYSTEM §15.8b + §15.7-15.9, KEY_LESSONS S85, TOOLS_AND_DATA §2.10, DOC_AUDIT S85.
- **S84** (2026-09-03): S81-remainder measurements + the AI-commit dispatch-table overrun CRASH found and fixed (DispatchBoundsStub, ids > $E5; Mourn WRAM jump reproduced live) — commit-time target write site, $dd0b INT ladders, tactics mechanism, MISS/dodge machine, plain-attack targeting all decoded; patched pin `b99455d6…` (superseded by S85b `a17bff8e…`). Owning: BATTLE_SKILL_SYSTEM §15.10.6-10, KEY_LESSONS S84, known_RAM_map [S84], DOC_AUDIT S84.
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
| Follower gfx-ID table | `ScreenTransDataTable` @ `$01:$49DF`, 231 `dw`, indexed `species+$10`; loader `GetActiveMonsterStatus` @ `$01:$4986`; family table `FollowerFamilyGfxTable` @ `$01:$4BAD` (10; twin `FamilyIconGfxTable0A` @ `$0A:$46B5`; both dead in the patched build since S104 — bank $6D entries 0/1). 16 tiles / 256 B per follower, DMA'd to VRAM `$8200`/`$8300`/`$8400` (party slot 0/1/2). **8 parallel copies of this gfx-ID table exist** (`$01 $06 $07 $09 $0b $12 $18 $59`, one per UI context: `$18`=menu/`TextDataPtrLookup`@`$4123` indexed `species`, `$12`=library); a complete art swap repoints ALL 8. |
| Follower layout dispatch (GFX-4) | Level-1 tables at FIXED `$10:$407f` (species 0–127) / `$11:$407f` (species 128+), indexed by species; `$ffc7=species+$10` routed by bank-`$04` entry 2 (`$10–$8F`→bank `$10`, `≥$90`→bank `$11`). Per-species attr/palette byte at `$10:$417f` / `$11:$412d` (bit6=Y-flip, bit5=X-flip, low3=OBJ palette). `[$caca]` = SPECIES (party +$09), not a "sprite-class" byte. Bank `$05` `$407f`-style table is the ObjTest viewer, NOT the follower path. `extracted/monster_follower_layouts.json`. |
| Follower render engine | `SaveScr_40cd` @ `$04:$40cd` (GBC variant of ROM0 `$0d91`). Metasprite list = 4-byte entries **(dy, dx, tile_offset, attr)**, `$80`-terminated; OAM tile = `tile_offset + [$ffc9]` (base `$20/$30/$40`); OAM attr = `[$ffca] XOR attr` (X-flip bit5). 2-level table: sprite-type `$ffc7`(=`[$ca91]`) → frame/dir `$ffc8`. **OBJ idx0 = hardware-transparent** (battle BG used idx1). 8 OBJ palettes @ `$17:$5615`. |
| Follower layout library | **155 distinct layouts** (complete; regenerated by `tools/extract_monster_follower_layouts.py` from the real `$10/$11:$407f` tables — the old 118-count brute-force scan dropped 3-entry small/blob layouts). Layout is per-species. Reassignment = same-size 2-byte repoint of the species' `$407f` level-1 entry (same-bank only), NOT a `[$caca]` edit. `extracted/follower_layouts.json`. |
| Custom layout bank | $64 (layout ptr table + LZSS layout + attr data, 309 bytes used) |
| Vanilla-empty banks | 23 = 368 KB: $60,$64,$67,$69–$77,$79–$7A,$7C,$7E–$7F (full-ROM scan, DOC_AUDIT B). Current allocation: see Bank Allocation table below. |
| Gate floor generation | Standard floors are procedurally generated (4×4 screen grid `$C940`, `(piece<<4)\|variant`); special/boss rooms are fixed templates substituted in. Per-gate config `GateFloorDataTable` `$16:$70A6` (32×8; byte 3 = floor count incl. the boss = FAQ "Levels"); weighting via `SelectFloorType` `$16:$5FC0` + `FloorTypeSelectionTable`1/2/3. Special rooms: only floors 3, 6, 9 … (wRNG1 bit 4 AND `wCurrentFloor` mod 3 == 2 — S100 correction), `rst $00` dispatch at `$16:$5C1C` (sets `wMapID` + `wInGateworld=0`). Custom rooms: `GateDecisionFork` → bank $71 entry 4 (S100). Gate names: `extracted/gate_names.json` (ROM-derived S100). **Full pipeline: GATE_GENERATION.md.** |
| Gate damage tiles | Standing-tile id → HRAM `$AA` (`$00:$1E96`); behavior class `$AA>>2`: `$0E` (ids `$38–$3B`) = damage, `$0F` (`$3C–$3F`) = staircase. Amount = `FloorDamageTable` `$01:$5E7D` (16 B by floor type): type 3→5, type 6→10, types $0C/$0E→2, else 0. Applier `ApplyFloorDamage` `$01:$5E23`. (GATE_GENERATION.md §5.1.) |
| Room palette derivation | A room's runtime BG palette is ROM-derivable: real colours are only indices 0 & 2 of slots 0–3 (`$17:$476F`[mapID] normal / `$17:$51F5`[floortype] gate, scanning past empty screens); engine FORCES idx1=`$6bff`, idx3=`$0000` in every BG palette; slots 4–7 shared system; object palettes global at `$17:$5615`. `tools/derive_room_palette.py`, validated 30/30 dumps + gate. (GATE_GENERATION.md §7.1.) |
| Script opcodes | **102** (`$00-$65`, rst $00 table after MarkScriptActive `$04:$5613`); arity + branch kind per opcode from the HANDLER code: `extracted/script_param_counts.json` (`tools/script_param_counts.py`, verify check 5). Script data bank by map type: <$06 `$0C`, <$20 `$0D`, <$40 `$0E`, else `$0F` (master table `$41BA` in each). decompile_script's old PARAM_COUNTS is wrong for 36 opcodes (DOC_AUDIT S96). |
| Room tile animation | bank $01 `PerRoomVRAMDispatch` $60E7 → `rst $00` table `$01:$6119`, **112** entries ($00-$6F), per field frame; clock `$C8A6/$C8A7`; the ONLY BG tile animation (none in gates). Custom rooms: bank $71 entry 3 `CustomAnimSource` (S99), which first runs bank $6C `CustomTileAnimate` — the room's OWN animations (S102, `tile_anims`, GDMA frame copies, any slot / speed). Census `extracted/room_animations.json`; ROOM_DATA_FORMAT "Animated tiles". |
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
| $60 | Custom rooms / NPCs / scripts / text (+ `CustomMonsterCast` monster-NPC cast tables, S101) | hand-authored `patches/bank_060.asm` (→ `build_project.py` later) |
| $64 | Custom tile layouts + attr data (`custom.layouts[]`, S92; per-screen attr maps S94) | compiler-generated `patches/bank_064.asm` (`layouts64`) |
| $67 | Custom tileset sheets (`custom.tilesets[]`: raw2bpp incl. editor-copied vanilla sheets, or mashup spec) | compiler-generated `patches/bank_067.asm` (`tilesets67`) |
| $69 | Breeding special scanner (B2) + the live special table | hand-kept `patches/bank_069.asm` (scanner) + compiler region `gd_special_recipes` (`gamedata.breeding.special`, S103; `build_breeding.py --emit-special` retired) |
| $6A | New-species info high table (ids 224+) | `build_new_species.py` |
| $6B | Project enemy rows (`progression.enemies[]`, EID 519 + index, 25 B each, ≤640; entry 0 `CopyEnemyRowExt` called by bank $14 `LoadEnemyStatsExt`; S101) | compiler-generated `patches/bank_06b.asm` (template `bank_06b_head.asm` + rows) |
| $6C | Own tile animations (`custom.rooms[].tile_anims`: `CustomTileAnimate` entry 0 + `TileAnimRoomTable`, group records, 16-aligned frame blocks; S102) | compiler-generated `patches/bank_06c.asm` (template `bank_06c_head.asm` + data; `tileanim6c`) |
| $6D | Family systems (S104: Spirit = family 10 — entries 0/1 icon gfx id, 2 dialogue text group, 3 default-name id, gfx index 4 `SpiritIconStream`; callers = same-size forks in banks $01/$0A/$04/$09) | hand-authored `patches/bank_06d.asm` (the Spirit icon bytes checked by `build_family_icon.py --selftest`) |
| $71 | Custom-room dispatch tables (S42 keystone: `Custom26DDTable`, `RoomEncTable`; + `CustomRoomBGMTable` + resolver entry 2, S64; `CustomAnimSrcTable` + entry 3, S99 — S102: entry 3 far-calls bank $6C first; `GateInsertTable` + entry 4 `CustomGateInsert`, `CustomRoomFlagsTable` + entry 5, S100) | compiler-generated `patches/bank_071.asm` (template head + tables; S63 `--apply` route) |
| $72 | Custom-skill system (de-aliased S2d/S2e code + tables) | hand-authored `patches/bank_072.asm` |
| $73 | Cold Farm systems (CF2 drain, entry 0; CF3 party-first sort, entry 1) | hand-authored `patches/bank_073.asm` |
| $74 | Custom song bank (M3a: records $4001-$417C fixed 95-slot, streams $4180+; resolved by AudioMasterTableExt row $9E) | compiler-generated `patches/bank_074.asm` (`music74` emitter → `song_codec.song_bank_asm` ← project.json `custom.music` + `extracted/*_song_library.json`; S64 — `custom_songs.json` retired) |
| $7E | Sprite overflow streams (battle + follower art) | `dwm/sprite_bank.py`, `bake_follower_overflow.py` |
| $7F | RESERVED next sprite-overflow bank (then $7C, $7A, $79) | `dwm/sprite_bank.py` order |
| **Unallocated** | **$6E–$70, $75–$77, $79–$7A, $7C** (8 banks = 128 KB; S104: $6D taken; $75 is the documented next song bank) + reserved $7F. (S102 correction: this row still listed $6B, patch-owned since S101.) | — |

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
7. **Test ROM content must be VISIBLE (user rule S100: "STOP USING
   INVISIBLE LEVERS OR OTHER INVISIBLE SHIT").** Never put an invisible
   trigger in a demo / test ROM: no examine spot on a plain floor cell, no
   step-on trigger, no exit or stairs on an ordinary tile, no "stand here and
   press A" instructions. Every interactive thing the user must find is an
   NPC or sits on art that looks like what it is (a pit for stairs, a door for
   a door); every demo room SAYS what it is (a talking NPC: "This is the
   VAULT …") and looks different from the others (palette / tileset). Test
   instructions name what the user SEES, never coordinates alone.
   Demo rooms are BRAND-NEW rooms (user S100 r2: "make brand new rooms so
   they are visually distinctive") — never an existing project room or a
   copy of one — and their names never reuse a name the project or the game
   already has ("vault" = the project's medal vault).


## Status Dashboard

### Custom content primitives (proven in-game)

| Primitive | Status | Where |
|-----------|--------|-------|
| Add NEW monster species (ids 224–255) | 🟢 Gorbunok (id 224) fully integrated & baked: info/stats/wild-encounter/name/library/breeding(3 paths)/lineage/follower art/battle art (S28–S38, user-confirmed). Open: **G3** schema fold (ROADMAP). | ROADMAP Phase N; MONSTER_DATA "Species ID geography" + "NEW species followers/battle sprite" |
| Custom rooms (mapID ≥ $6B) | ✅ table-driven to editor scale: render/palette/attr/$26DD records + per-room encounters via bank $71 tables (S40/S42); multi-screen scroll (v28); gate-rotation insertion + descent (S41; data-driven S100 — next row). | EDITOR_DESIGN §2; GATE_GENERATION §7; CROSSBANK_ROOMS |
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
| NPC show/hide by step | ✅ working | step system; counters at $CD80+ (S65; transient); opcode $12 advances (v25) |
| Flag-driven room states (persistent) | ✅ built S97, USER-CONFIRMED 2026-09-26 | `custom.rooms[].state_rules` → bank $60 entry 8 (+ bank $17 hook); PROJECT_COMPILER §2.13 |
| NPC behaviours (movement types) | ✅ decoded + authorable S97, USER-CONFIRMED 2026-09-26 | type byte low nibble, bank $06 NPCBehaviourTable; ROOM_DATA_FORMAT "NPC behaviour types" |
| NPC talk text as boxes (2 lines, waits per box) + text boxes cream in free-colour rooms | ✅ built S97 r2, USER-CONFIRMED 2026-09-26 | `boxes` dialogue form (TEXT_SYSTEM "Text boxes"); bank $73 entries 14-18 + same-size calls in banks $00/$06/$56 |
| Doors (two-way, auto return + measured arrival), one-way teleports, examine spots ($8x) + step-on triggers ($90), talk scripts that set/clear flags + YES/NO + move | 🟢 built S98; doors USER-CONFIRMED 2026-09-26 (user project, both ways, on-door arrival); talk / flags / spots in game NOT yet user-tested (PyBoy test_canvas v5) | `door` ids on exit/redirect rows, `talk` scripts; PROJECT_COMPILER §2.14; ROOM_DATA_FORMAT "Interact entries ≥$80" + "Arrival and edge rules" |
| Room tile animation (vanilla census + per-custom-room source) | 🟢 built S99 (signed off 2026-09-27; borrowed water user-seen moving in r2; r3-r7 editor-only): 112-entry bank-$01 dispatch measured (65 handlers, 33 animated maps); custom rooms pick `none` / `source` / borrow via bank $71 entry 3; editor outline + ▶ Play preview + inspector choice; **Make animated** tab (slide / two-frame flip, paint pads with per-quarter tools, still quarters keep their slot, take-over of a full animation, automatic wall/walkable split move, per-room count), stray-animation repair on open, Make still | ROOM_DATA_FORMAT "Animated tiles"; PROJECT_COMPILER §2.15; extracted/room_animations.json |
| Own animated tiles (any slot; flip through drawn frames / drift / sway; any speed; plain budget) | 🟢 built S102 (P3.3f; r2 frames side by side, r3 per-tile / per-cell tools), signed off 2026-09-29 (in-game ROM test not separately reported); PyBoy + SameBoy frame-exact on the user's save | `custom.rooms[].tile_anims` → bank $6C; PROJECT_COMPILER §2.19; ROOM_DATA_FORMAT "Own tile animations (S102)"; EDITOR_DESIGN §5.1 "As built S102" |
| Custom rooms on gate floors (rules: gate, floors, chance %, flag conditions, once per dive; room: arrival, Stairs down, saving, battles following the gate, gate/own music) | 🟢 built S100 (P3.7b part 1); user-passed S101 session start | GATE_GENERATION §7.6; PROJECT_COMPILER §2.16; EDITOR_DESIGN §5.1b; bank $71 entries 4/5, bank $16 GateDecisionFork, bank $07 SaveAllowCheck |
| Custom boss floors (custom.gates: floor count, boss = custom room / vanilla boss room, hand-made gates), monster NPCs ($F0-$F3), conversation trees (talk.steps: flags, YES/NO, 1-3 enemy battles, helper exit, arrival fights), project enemies (bank $6B) + join versions | 🟢 built S101 (P3.7b part 2, first half), USER-CONFIRMED 2026-09-27 except the helper; r2 (Warubou, lands left of the player facing them) built, NOT yet user-tested | GATE_GENERATION §7.7; PROJECT_COMPILER §2.17/§2.18; ROOM_DATA_FORMAT "Monster NPCs"; MONSTER_DATA "Project enemy rows"; EDITOR_DESIGN §5.1b |
| Vanilla data tables from project.json (`gamedata`: monsters, enemy rows, encounter pools, skills MP / learn / record, exp + growth curves, family + special recipes, boss joins; library text + tabs kept coherent) | 🟢 built S103 (P3.9, backend — the GUI tabs are P3.10-P3.13), USER-CONFIRMED 2026-09-30 (demo ROM on the user's save) | PROJECT_COMPILER §2.20; DATA_STRUCTURES "Encounter pool entry"; editor2/core/gamedata.py |
| LZSS tile compressor | ✅ working | tools/compress_tiles.py, roundtrip verified |
| Custom tile layouts + tileset selection | ✅ working | bank $64 + tile_layout_compiler.py; MapIDClampForPalette ROM0 $3FE8 |
| Custom tile GRAPHICS (multi-tileset mashup) | ✅ working end-to-end (S6–S10): editor JSON → build_combined_tileset.py → bank $67/$17 patches. Remaining = editor multi-screen UI. | KEY_LESSONS S5–S8; TOOLS_AND_DATA |
| Attr map generator | ✅ working | tools/generate_attr_map.py (85 tilesets) |
| Script compiler/decompiler | ✅ working | tools/compile_script.py / decompile_script.py |
| Random encounters in custom rooms | ✅ generalized per-room (S42 `RoomEncTable`, bank $71). Remaining: custom monster POOLS (Encounters #2, ROADMAP). | CROSSBANK_ROOMS; KEY_LESSONS S11 |
| Custom breeding | ✅ full authoring stack B1–B7: round-trip encoder; bank $69 owns the special table (overrides+appends+shadow validator); family-defaults rewrite; family reassignment; production library grouping (zero lag). **Spirit = a first-class 11th family (S104, USER-CONFIRMED 2026-09-30):** bank $6D family systems, `$FA` = Spirit, ghost-wisp icon, ??? restored, shown before ???, editor Families tab. | BREEDING_SYSTEM; ROADMAP Phase 2B |
| Custom battle skills (net-new ids) | 🟢 NINE custom skills live: MagicBurn $E0 (S49), Tame $E1 (S50), TameMore $E2 + TameMost $E3 (S52), Anchor $E4 field-cast (S73, user-confirmed), Earthquake chain $E5-$E8 (S74; **S84: AI-commit of $E6-$E8 was CRASH-CAPABLE on all pre-S84 builds** — dispatch-table overrun, fixed by DispatchBoundsStub; PyBoy re-verified S84, awaiting user test), **Mourn $E9 (S75: ATK-vs-DEF × (dead allies+1), 2nd dispatch trampoline = per-skill vanilla damage machine; **S84: AI-commit was CRASH-CAPABLE (wild jump to WRAM) on all pre-S84 builds** — fixed S84; AI-commit activation USER-CONFIRMED on the real save (Charge tactics))** — all on the full de-aliased stack incl. natural-learn, real MP, announce, descriptions. | BATTLE_SKILL_SYSTEM §12–§13.8, §14; ROADMAP Arc 2 |
| SRAM save layout | ✅ audited S8: custom flags persist (truly-safe pool = 32 flags, S57); collisions mapped; free SRAM tail $BFC8-$BFFF (56 B, reserved). **32 KB expansion BUILT S69 (RAMB pin + CF3SRAMBankedCopy; NOT yet user-tested)** — +24 KB persistent in banks 1-3, uninitialized until a schema exists (E3 residual) | ARCHITECTURE "SRAM banking as built S69"; known_RAM_map |
| Custom-room WRAM state | ✅ migrated S65 into the CF3-freed window (buffers $CC80/$CD00, counter region $CD80×640, wCustomPool $D001-$D664; TRANSIENT permanently, init-guaranteed zeroed). v7 USER-CONFIRMED S66 | patches/wram.asm banner; PROJECT_COMPILER §2.6; ROADMAP CF4 |

### Not yet implemented

| System | State |
|--------|-------|
| Custom monster pools (Encounters #2) | Specced in CROSSBANK_ROOMS; not built |
| Custom music | 🟢 **M1-M3c COMPLETE (S61-S64, all user-confirmed)**: engine map, round-trip codec, general slots (bank $74), room-default assignment for any mapID, `custom.music` schema, 31-song DWM2 catalog, MIDI import. Open boxes: InitBGM channel-count ext (4/5ch sources), gate/event music, CI compiler-test |
| Arena/boss roster AUTHORING (E1→E2 wiring) | RE ✅ DECODED S67 (arena path HW-verified); authoring spec in SIDEQUEST_MAP + arena_brackets.json. project.json schema wiring = E2, not built |
| Combat simulator (arc S78-S88) | 🟢 **COMPLETE through the pacing layer (S86) + commit-model close-out (S87: party bases from the instance record, obedience EXACT 889/889 on the WLD stat, $7997 + TRUE-loaf closed)**: `simulator/damage.py` 698/698 (S78) + specials (S79); `turn_order.py` 143/143 (S79); AI `ai.py` 26/26 + rule chains `ai_rules.py` 240/240 (S80/S81); `battle.py` loop glue 6614/6614 (S85) + 802/802 on fresh S86 captures; **S86: measured RNG idle model (`measure_idle.py` → `s86_idle_model.json`), full-battle driver `pacing.py` (commit + rounds + TTK), aggregate-validated (`validate_pacing.py`: round-level PIT uniform over 197 rounds; 5 fresh real-save battles inside sim envelopes), `sweep_ttk.py` gate-pool sweeps, `profile_check --ttk` gating**. **S88 (built, NOT yet user-tested): confusion end-to-end + snap-out (2824/0), riders 40/40 ($69 boss veto = application-only), curse MP MaxMP//6, poison cap 15/15, PsycheUp closed empty, $DB06/$DB07 writer map, dodge incapacity exemption; 3 new corpora; the S79 $7AB5 confusion attribution corrected to Transform (DOC_AUDIT S88).** Residuals (§15.9 + ROADMAP S89): the low-stat calcdef edge (2 deterministic SameBoy repros), meta-actions (hero-slot MENU verbs — PARTIAL, named box), and +8/+9 defensive-flag consumers. **S89 (built, NOT yet user-tested): Group-B residuals CLOSED — $DB07 = IRONIZE counter (not stun); interception = Cover/Guardian guard table (`guard_redirect`, 14/14); WLD level-up writer = none; `board_from_event` consumes real ai_bases/WLD; defensive-set sweep folded into status.py. New corpora s89_fresh (426/1 flagged) + s89_guard (14/14). Annotation: $670E re-sectioned, guard/iron handlers commented.** **S90: arc adjudicated DONE FOR PURPOSE (user-conferred); residuals banked as non-blocking boxes ($DB42 setter, +8/+9 consumers, meta-actions menu drive, guard-validator polish).** | BATTLE_SKILL_SYSTEM §15, §15.6, §15.9; TOOLS_AND_DATA §2.10 + S89 rows; ROADMAP S89/S90 |
| Randomizer (standalone; English + German builds) | ✅ **SHIPPED, USER-TESTED, part 2 S77** — `randomizer/`, data tables only plus ONE code change (`plusgrowth.py`, opt-out). Breeding tree regenerated to a target depth profile (3-6) with deeper = better; bosses/arena/wild stratified against vanilla's measured correlations; skills dealt from vanilla's usage bag and never below vanilla's minimum placement level; growth shuffled within vanilla-ordering bands; paralysis + full heals banned on boss/arena rows; pools de-duplicated. Gate: `randomizer/profile_check.py` (per-entity envelopes) + `randomizer/audit_threat.py` (per-row damage parity). | randomizer/README.md; BATTLE_SKILL_SYSTEM §record power field is BLIND; BREEDING_SYSTEM §Depth is a function of matcher SPECIFICITY; MONSTER_DATA §Growth randomization needs a per-species envelope; PROJECT_COMPILER §Validation the editor must run |
| Editor app (Phase 3) | 🟢 Skeleton S72 → design v2 S90 → P3.0-P3.2b S91/S92 → **P3.3 canvas v1 + shell S93** → **S94 canvas v2 + real room model + S94b entrance redirects & per-state rooms (built, NOT yet user-tested):** vanilla/custom room columns (every vanilla state browsable), clone-with-confirm carrying ALL vanilla states (paintable at once), New/Copy/Rename/Delete, File→New project (blank template), metatiles (4 subtiles + palette) as the editing unit, Select-first with real selection, Walkability mode (BR-subtile twin swap, tileset copied into the project), 4×4 grid, vanilla-format per-(screen,state) attr+palette tables (engine), records for every room (ROM0 region), **"Route a vanilla door here" = `custom.entrance_redirects` → per-(map,screen) exit overrides (Entry 6 + Entry 9)** — the in-game test route for any custom room; **S95:** picker = the room's whole vocabulary (never shrinks) + borrow tiles from any vanilla room under this room's palettes (import across tilesets, PyBoy-verified) + on-open migration of pre-S94 projects. Acceptance PyBoy-verified incl. walking and the door walk-through. **S96 (USER-CONFIRMED 2026-09-25 ("Everything works")): P3.3c Tileset tab (slot map + release) + P3.3d (change tileset / blank sheets, Import art tab for PNG rips, per-subtile metatile palettes, bank space meters) + Make editable works on all 98 vanilla rooms (opcode arity from the handlers).** **S97 (USER-CONFIRMED 2026-09-26): rooms group B — P3.5a flag state rules (engine entry 8 + bank $17 hook; persistent custom-room versions) + P3.5 NPC inspector (13 measured behaviours, hidden bit, talk text, presence, drag; **r2**: per-box talk editor with ROM-font preview, cream dialog/YES-NO boxes in free-colour rooms, NPC section, sections start folded).** **S98 (doors USER-CONFIRMED 2026-09-26; the rest built, NOT yet user-tested): rooms group C = P3.7 — named door objects linked two-way (+ Door, double-click to connect, arrive ON the door), one-way teleports, examine / step-on spots (the "$8F spawn" misnomer retired), talk scripts with YES/NO + set/clear flags + move, edge-vs-scroll guards, World tab v0; tileset tools (own copies, split move, purge).** **S99 (built; signed off 2026-09-27, r7 not yet re-tested in-game): P3.3e animated tiles — measured census, per-room animation source (engine), canvas outline + ▶ Play preview, inspector choice, clones = source, migration; Make animated tab (r3-r7: paint pads + part tools, still quarters, take-over, split move, count) + stray repair / Make still (r4).** **S100 (built, NOT yet user-tested): P3.7b part 1 — Gates tab v1 (32 gates, rules per gate, floor plan, rule dialog) + Rooms-tab "Inside gates" (arrival, Stairs down, saving, battles, music) → custom rooms served on gate floors.** Next: P3.7b part 2 (gate settings, custom boss floor, entrances — ≈3-4 sessions) or the user's choice (P3.4 PyBoy preview deferred by the user; P3.6 dialogue, P3.8 storyboard open), plus P3.3b residuals (bank-$64 spill; transparent NPC census crops). | EDITOR_DESIGN §5.1 as built S94; ROADMAP P3.3b |

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

- ~~POC state in the hand overlay affects every project (S94)~~ **RESOLVED
  S94b:** `Exit_GreatTree_s8` is back to vanilla bytes; the Library-door
  repoint and the `(4,5)→$6B` entrance are example-project
  `custom.entrance_redirects` data, so a fresh project's GreatTree is
  vanilla until the author routes a door.
- Custom-sprite BACKGROUND colour is pure white vs vanilla's slightly
  creamy white (user-reported S90, subtle but real). Suspect: import
  quantization to $7FFF instead of vanilla's exact background RGB555;
  prime suspect path = MonsterBattlePalettes (follower OBJ idx0 is
  hardware-transparent). Measurement + one-constant fix = G-P half of
  ROADMAP P3.10.
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
- `extracted/npc_catalog.json` is contaminated by phantom-step rows (dumper walks
  past each screen's real step list — DOC_AUDIT S91); filter per
  `dump_npc_sprite_catalog.py --census` rules until the dumper is regenerated
  (ROADMAP residual). The S91 sprite catalog + max-8-NPC census already use the
  filtered path.
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

