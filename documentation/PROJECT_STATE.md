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

> Last verified: 2026-10-04 (Session 118 — **ROADMAP P3.8 PART A: THE CUTSCENES TAB —
> EVERY SCENE OF THE GAME AND OF THE PROJECT READ, SHOWN AS A STORYBOARD AND PLAYED IN THE
> REAL GAME INSIDE THE EDITOR (NO NAVIGATING), THE INTRO CHAIN, AUTO TEXT, SOUND** (user:
> "I want you to work next on the Cutscene tab … Reading in, displaying and playing back
> all existing cutscenes in all relevant rooms. This includes the more tough case of the
> intro … Cutscene playback window … Include skipping text boxes as an option · Cutscene
> editor …" → on the audit: "1) Sounds good. 2) If I dont have to navigate to cut-scene
> in-game, ok. 3) Ok but obviously might depend on cut scene. 4) a auto. You can turn off
> and on to press manually. 5) Good. Yes sound. 6) Probably always clone room")).
> **Built S118, NOT yet user-tested.** Part B (the editor) is next; part C (in-place
> vanilla override) dropped — vanilla scenes are changed in a cloned room (ROADMAP P3.8).
> **Byte-neutral:** no ROM byte changed — clean `1ca6579…` byte-perfect (labels /
> comments only, both trees), patched pin `110210b0…` (patched) unchanged, so no test ROM.
> Verifier PASS (6/6; check 5 += `census_cutscenes.py`); test_compiler --rom
> 947/947; test_app PASS. `EDITOR_REVISION` = 'S118' (S118b below). **Playback needs pyboy** on the user's
> Mac (`pip install pyboy`).
>
> **The script VM decoded (BANK04_SCRIPT_ENGINE "Script opcodes as measured (S118)"):** all
> 102 opcodes named (`editor2/core/script_ops.py`; bank $04 handlers `ScriptCmdNN_*`,
> `MoveProgNN_*` / `PlayerProgNN_*`, `MoveProgramsAll` … in both trees); `$D8D7` bits
> rewritten (3 = a waited walk, 4 = movement programs, 5 = lock facing, 6 = walk_fast),
> `$D8D8` (text box bottom / top, long delay), the movement buffers `$D8E9 + 8n`, the `$1C`
> programs measured (hop, jumps, leaps, fly in / off, appear / vanish …); wrong names
> fixed (`$22` walk_fast is not required, `$4C` waits for the D-pad, `$21` = sound, DOC_AUDIT
> S118); `$24` / `$61` read ONE param through the script bank (the S96 tracer stopped at
> `rst $10` — `script_param_counts.py` follows it now; every decode was already consistent).
> **Model / playback (EDITOR_DESIGN §5.1d):** `editor2/core/cutscenes.py` — 519 vanilla
> scenes (+ the project's, as the compiler lowers them), path conditions, triggers, the actor
> model, the RECIPE that sets a scene up (flags / RAM, the room-entry script kept quiet, the
> warp, the game's own talk / examine / step-on; scenes after a battle win start at their
> first step); `editor2/core/playback.py` — PyBoy from a cached new-game (or .sav) state;
> **`editor2/core/playback_server.py` — the game in a CHILD PROCESS** (a crashed game froze
> PyBoy's tick: KEY_LESSONS S118). The tab: Chains (the intro: bedtime → Warubou → the
> dresser → tree tunnel → Starry Shrine → the old man up GreatTree → Castle) / Your rooms /
> Game rooms, the storyboard, recorded pictures; the Playback window (auto text + read time
> + YES/NO, auto D-pad, sound at 1×, 2-8×, keys, the storyboard follows); help
> `63_cutscenes.md`.
> **Measured:** `tools/census_cutscenes.py` (every map in a worker process) — 519 scenes,
> 514 reached (442 by the game's own trigger), 417 ended, 86 handed to a battle, 0 hung;
> the position model 3,887 / 3,909 checks exact; the intro chain plays from the dresser to
> the Castle minister by itself (PyBoy screenshots). **Found:** text code `$F9 nn` prints
> the name at `$C180 + nn` — an unfilled slot runs the text engine through RAM and crashes
> the game (the egg scenes; TEXT_SYSTEM, KEY_LESSONS S118); never poke the player's HRAM
> position; a savestate made without sound plays back silent.
> **S118b (the user's first look, 2026-10-04 09:12; built, NOT yet user-tested):** "Oh boy
> this looks dangerous - the wrong NPC jumps down … 2) Some of the 'cutscenes' are just text
> boxes? Like egg evaluator? 3) Playing some cutscenes doesnt do anything? Like old man room
> script … 4) Are 'play' for per-script line or entire window? Unclear. 5) Can you edit any
> of this?" → the room state from the story's own counter writes + NPC-count rule (BANK04
> "Room state (S118b)", KEY_LESSONS S118b); the filter = someone moves (218 / 519); a
> walk-to that moves nobody is named (the Old Man Gate Room: he already stands there — the
> game too); ▶ Play scene / ▶ From this step; fly programs per `$D8E3`/`$D8E4` measured.
> Census: 516 reached, 0 hung, 1 empty-slot step, 3,989 / 3,998 exact. **Found: a CLONED
> room keeps its own state counters** — the vanilla scripts' writes never reach it, so the
> user's GreatTree clone shows the old man jumping (in their game too); whether clones
> should follow the vanilla counters is the user's call (ROADMAP P3.8). `EDITOR_REVISION`
> = 'S118b'. Delivered as `DWM-S118b-cutscenes-fixes-changed-files.zip` (on top of S118).
> **S118c (user 2026-10-04 10:10: "Yeah obviously" — the copied room must do what the game
> does; "I really would like to step through animation step by step"; built, NOT yet
> user-tested):** copies of game rooms follow the game's room state —
> `step_counter.vanilla` (the original's counter, EQU, saved; PROJECT_COMPILER §2.6
> "S118c"), Make editable writes it, existing copies migrated on open, Rooms → *Follow the
> game's room state*; PyBoy on the user's project: the copied GreatTree screen 0 follows
> `$D92D` and the cliff scene moves the cliff man. Playback **Step ▸▸ / ◂ Step back**, one
> recorded picture per step. The example project has no copies: pin `110210b0…` (patched)
> unchanged; the user's project builds differently once opened (the migration).
> `EDITOR_REVISION` = 'S118c'. Delivered as `DWM-S118c-copies-steps-changed-files.zip` + test
> ROM `DWM_S118c_test.gbc` (`5ef856d8…`, patched = the user's my-dwm-hack_9 opened in the
> S118c editor; was `c2db7f54…`, patched, historical).
> **S118d (user 2026-10-04 10:40: "Arena rooms - script 0 - … game resets and plays logo";
> scene clicks after a playback showed nothing — their traceback: `script_ops` without
> `FLY`, i.e. the S118b zip not applied; "Are you sure you tested this stuff?"):** entry
> scenes reached through another script's room change are set up as that script leaves the
> game (`Catalogue.entry_caller`, BANK04); resets detected in the census and the Playback
> log (KEY_LESSONS S118d: "ended" ≠ worked); test_app opens every 7th scene; one CUMULATIVE
> zip for the whole session (SESSION_PROTOCOL). Census 516 reached, 0 resets, 3,994 /
> 3,998. `EDITOR_REVISION` = 'S118d'. Delivered as `DWM-S118-all-changed-files.zip` (every
> file changed in S118-S118d; supersedes the three earlier zips).
> **S118e (user 2026-10-04 12:00: "Game intro where milayou and terry run around … both are
> in wrong positions"; "PLEASE … give ability to mute preview pyboy player GLOBALLY in the
> menu"):** the bedtime scene plays from a real new game (== an uninterrupted new game,
> PyBoy); 36 room-entry scenes that started the player at the screen centre now use the gate
> table's arrival (boss rooms) or walk in from the next screen (Warubou's east room); View →
> **Mute game playback** (⌘⇧M) overrides every Playback window (BANK04 "Where the player
> starts", KEY_LESSONS S118e). `EDITOR_REVISION` = 'S118e'. Delivered as
> `DWM-S118-all-changed-files.zip` (cumulative, S118-S118e).
> **S118f (user 2026-10-04 12:41: "I want everything interpretable please"):** every
> storyboard step in words — room states, the decoded script variables ($C8EC, $C8ED,
> $D951, $D9CB, the chests $D9CF-$D9D6, $D9E2/E4/E5/E8, $C8F2 …, BANK04 "Script variables
> (S118f)"), flags (known names, else where the game sets them; $0007 = Pulio's first
> pick-up), screen types, tile patches, NPC animation fields. `EDITOR_REVISION` = 'S118f'.
> **S118g (user 2026-10-04 14:05: "why are random things named Warubou? … ARE YOU NOT
> TAKING THIS INFO FROM GAME?"):** the storyboard's NPC names had come from a hand-made
> sprite table, room names are hand labels — now an NPC is named only by its own text's
> speaker, each room header shows how the game's exit tables / scripts enter it; the hero's
> name (was "TERRY0000"); `$C8F2` corrected to the hero's name. The arena-win scene the
> user spot-checked IS where the game puts it (arena battle script → map $06 tile (14, 4);
> played: messenger, warp, King). `EDITOR_REVISION` = 'S118g'.
> **Hand-off:** every S118 change = the diff against the S117b push, delivered as
> `DWM-S118-cutscenes-changed-files.zip`, the APPLY list pasted in the chat. **Next:** P3.8
> part B (the cutscene editor — the questions in ROADMAP P3.8) or the user's pick.


> Last verified: 2026-10-03 (Session 117 — **ROADMAP NG2 + P3.13c: 2,048 EXTENDED EVENT
> FLAGS, GATE SWIRLS THAT FOLLOW EACH GATE'S "CLEARED" FLAG (NEW GATES, NEW BOSSES,
> RE-ROUTED PORTALS), NPCs SHOWN BY FLAG, AND SHOPS — THE GAME'S FIVE AND THE PROJECT'S
> OWN, ITEM PRICES** (user on the audit: "rewritten preview player works. What is NG2? Is
> this literally just connecting swirly thing to gate, then setting a flag to stop swirtly
> thing from swirling? Sure we can seems like a tiny thing to do" → "1) I am going to need
> dozens if not hundreds of flags for new custom campaign. 2) Does each swirl-containing
> screen contain step variants then? 3) Make is as simple and straightforward in editor as
> possible. Boss cleared - no swirly. Boss cleared BUT we are inputting new boss or
> redirecting to new gate - swirly. However you do it its fine. 4) Do shops as well while
> you're there.")). **Test ROM `DWM_S117_swirls_shops_test.gbc` (`e208972a…`, patched,
> historical) USER-REPORTED 2026-10-03 21:57: "The rest works" + two bugs → S117b below.**
> S116b's player USER-REPORTED working (S116 block).
>
> **S117b (built, NOT yet user-tested; test ROMs `DWM_S117b_shopfix_test.gbc`
> (`fcb6bc4d…`, patched, historical) and `DWM_S117b_test.gbc` (`56d308bc…`, patched — the
> same engine, the demo hall re-laid out one NPC per row)):** (1) user: "when I walk over my follower monsters … the left-most NPC
> glitches out and is hidden … Same thing happens to newly appeared slime" → measured:
> the HARDWARE limit of 10 objects per screen line (the player + 3 monsters lined up on
> the NPCs' row use 8; PyBoy draws them all, so it never showed) — user: "Just warning is
> fine for now, and Ill build around it" → `formats.sprite_budget` build + Rooms-tab
> warnings (a row with > 1 NPC; > 6 NPCs on screen — 40 objects), the demo hall one NPC per
> row (ROOM_DATA_FORMAT "Sprite limits (S117b)"). (2) user: "New shop in custom room - menu
> glitches with background colours from custom tiles" → every bank $09 screen is pushed by
> `LoadFld9_40fa` (tiles only); SAME-SIZE → bank $77 entry 2 `ScreenPush` (palette 7 for
> menu tiles, `$C200` palettes for room tiles, free-colour custom rooms only); and a second
> bug found testing it: a shopkeeper talked to from the lower half put the dialog box at
> the top and the shop left its "Thank you" box on screen → `ShopClose` → `ShopBoxBottom`
> (DATA_STRUCTURES "Shops (S117)" → "The shop screens"). **Patched pin `110210b0…`
> (patched)**, was `31cc5b31…` (patched, historical); the user's project (my-dwm-hack_8)
> as-is builds `8cbebea1…` (patched; one sprite-limit warning: greattree screen 8 row 6).
> test_compiler --rom 947/947, test_app + --rom PASS, test_canvas --rom PASS, verifier
> PASS. `EDITOR_REVISION` = 'S117b'. Hand-off: S117 + S117b together = the diff against
> `b59c026`, `DWM-S117b-swirls-flags-shops-changed-files.zip`.
> Verifier PASS (6/6); clean `1ca6579…` byte-perfect (bank $03 `SpriteFrameDataTable` →
> `ItemInfoTable` 44 `db` rows, bank $09's shop machines / tables labelled + five renames, in
> both trees — labels / comments / db only); **patched pin `31cc5b31…` (patched,
> historical — S117b: `110210b0…`)**, was `7bab4921…` (patched, historical); the user's
> project (my-dwm-hack_8) as-is built `b020c1bf…` (patched, historical; the engine change only — on it, room $23's swirl now follows their
> custom gate-0 boss). test_compiler --rom 936/936, test_app + test_app --rom PASS (GUI
> build == pin), test_canvas --rom PASS. `EDITOR_REVISION` = 'S117'.
>
> **Flags (EVENT_FLAGS "Extended flags (S117)", ARCHITECTURE "SRAM bank 3 (S117)"):** ROM0
> `ComputeFlagAddress` (the one chokepoint of Set / Clear / Test) SAME-SIZE → bank $73 entry
> 21 `FlagAddr`: indices `$1000-$17FF` → **`wExtFlags` $D140** (256 B), the rest the vanilla
> formula; saved by bank $73 entries 5 / 6 to SRAM bank 3 ("X1"), zeroed by a new game. The
> editor's named pool = **1,968** (`$0158-$0167` + `$1000-$179F`); `$17A0-$17FF` = the gates'
> own cleared flags; `gate:N` = "gate N cleared" anywhere a flag is picked.
> **Swirls (GATE_GENERATION §7.9):** measured — the spinning swirl is NPC sprite `$4D`
> (script `$FF`) on the portal cell, dropped by the boss script's STEP advance (room $24
> `$D969`); the still swirl is BG art; the portal never tests either. Engine: bank $0B
> `GetRoomDataPtr` SAME-SIZE → bank $60 entry 1 for every non-gate room —
> `CopyNPCListToBuffer` reads **`$A0`/`$A1` flag-condition prefixes** (→ the hidden bit) and
> `VanillaNPCExtTable` (vanilla portal rooms of re-bossed / re-routed gates); bank $50's
> boss-win tail SAME-SIZE → bank $76 entry 2 **`GateBossWin`** (`GateClearTable`: own flag
> `$17A0 + gate`, + a re-bossed vanilla gate's vanilla flag). Schema `swirl_of`, `shown_when`,
> portal `entrance_redirects` with `gate:N` (PROJECT_COMPILER §2.32).
> **Shops (DATA_STRUCTURES "Shops (S117)"):** a shop = opcode `$FF04 $0000 $0680`; the list
> is chosen by the ROOM (map $50 gate shop, else wScreenIndex 0 / 2 / 4 / other); prices =
> `ItemInfoTable` +1/+2. Engine: bank $09's 64-byte choice + copy → NEW compiler bank
> **$77** entry 0 `ShopFill` (**`wShopID` $D240** set by a `shop` script, else the room rule);
> the close tail → entry 1 `ShopClose`. Schema `gamedata.items.<id>.price`,
> `gamedata.shops`, `custom.shops[]`, `shop` scripts.
> **Editor (EDITOR_DESIGN §5.1b / §5.6b "As built S117"):** "Gate entrance here…" adds the
> swirl object + paints the still swirl; "Lead this portal to another gate…"; `gate:N
> cleared` in every flag list; the Gates tab names each gate's cleared flag; **the Shops
> tab** (the five + your shops, items 1-20, Original list, prices with what shops pay) +
> Rooms NPC "Shopkeeper…"; help `62_shops.md`, `60_gates.md` "Swirls and cleared",
> `30_flags.md`, `20_npcs.md`, `00_start.md`, `90_limits.md`.
>
> **Measured on the user's save (demo = the user's project + "Portal Hall" $71 behind the
> GreatTree 2F Library door: a guide, a bell keeper (extended flag `$1100`) and the slime it
> calls (`shown_when`), a stall selling its own 12 items, entrances to the new gate 32
> "Swirl Gate" (copy of Beginning, 2 floors, boss room "Swirl Throne" $72) / Villager /
> Talisman; the room-$24 Villager portal re-routed to gate 32; Herb costs 12 — NOT in their
> project):** the hall's gate-32 and Talisman swirls spin, Villager's (cleared) is hidden;
> the bell sets `$1100`, the slime appears, survives save → reload; an unsaved flag rewinds;
> the stall's list (3 pages), Herb bought for 12G, page 3's last item bought; the Bazaar's
> vanilla list with Herb 12G; the shop closes with wShopID 0; gate 32 → boss conversation
> battle → `GateBossWin` once, `$17C0` set → the gate-32 swirls in the hall and room $24
> hidden. A/B over the user's project: 212 vanilla + 25 custom screens' NPC slots identical
> except $23 (by design); `ShopFill` census == the original's choice for every map × screen;
> the 1,934 script flags' addresses == the original.
> **Hand-off:** every S117 change = the diff against `b59c026` (origin/master, the S116
> push), delivered as `DWM-S117-swirls-flags-shops-changed-files.zip`, the APPLY list
> pasted in the chat. **Next:** NG3 (fully custom gates — the S114 questions) or the user's
> pick; residuals in ROADMAP NG2 / P3.13c.



## Session Index (finding aid — verbatim blocks in SESSION_HISTORY.md; owning docs are canonical)
- **S118** (2026-10-04): P3.8 part A — the Cutscenes tab: the 102 script opcodes named + measured (`script_ops.py`; bank $04 handlers labelled both trees; `$D8D7`/`$D8D8` bits; the `$1C` movement programs; `$24`/`$61` arity 1), 519 vanilla scenes + the project's as storyboards (`cutscenes.py`), played in the real game without navigating (`playback.py` recipes; PyBoy in a child process, `playback_server.py`), the intro chain, auto text / sound / keys; `census_cutscenes.py` 514 / 519 reached, 0 hung, model 3,887 / 3,909; byte-neutral (pin `110210b0…` patched, unchanged). Built, NOT yet user-tested. **S118b** (user's first look): room state from the story's counter writes (the wrong NPC jumped), filter = someone moves, ▶ From this step, `FLY` table; census 516 reached, 3,989 / 3,998; copies keep their own state counters → **S118c**: copies follow the game's room state (`step_counter.vanilla`), Step ▸▸ / back, a picture per step. **S118d**: entry scenes set up as the calling script leaves the game (the arena reset), resets detected, cumulative zip. **S118e**: the intro from a real new game, gate arrivals / walk-in instead of the screen centre, View → Mute game playback. **S118f**: every storyboard step in words (`ram_names.py`). **S118g**: names only from the game (speaker texts, exit tables). Verbose block in this file. Owning: BANK04_SCRIPT_ENGINE "Script opcodes as measured (S118)", EDITOR_DESIGN §5.1d, CUSTOM_CUTSCENES, TEXT_SYSTEM ($F9 slots), KEY_LESSONS S118, DOC_AUDIT S118, TOOLS_AND_DATA S118.
- **S117** (2026-10-03): NG2 + P3.13c — extended event flags `$1000-$17FF` (ROM0 `ComputeFlagAddress` same-size → bank $73 entry 21; `wExtFlags` $D140, SRAM bank 3 "X1"; editor pool 1,968); gate swirls follow each gate's cleared flag (bank $0B `GetRoomDataPtr` same-size → bank $60 entry 1 for every non-gate room: `$A0`/`$A1` NPC flag conditions + `VanillaNPCExtTable`; bank $50 boss win → bank $76 entry 2 `GateBossWin`, own flags `$17A0 + gate`); shops (bank $09 fill / close same-size → NEW compiler bank $77 `ShopFill` / `ShopClose`, `wShopID` $D240; `ItemInfoTable` $03:$71DA re-sectioned, prices editable; the Shops tab, NPC Shopkeeper…); pin `31cc5b31…` (patched). Test ROM `DWM_S117_swirls_shops_test.gbc` USER-REPORTED 2026-10-03 21:57 ("The rest works" + 2 bugs) → **S117b**: hardware sprite-limit warnings (`formats.sprite_budget`), bank $09 screen push → bank $77 `ScreenPush` (menu palettes in free-colour rooms), `ShopBoxBottom`; pin `110210b0…` (patched); test ROM `DWM_S117b_test.gbc` built, NOT yet user-tested. Verbose block in this file. Owning: EVENT_FLAGS "Extended flags (S117)", GATE_GENERATION §7.9, DATA_STRUCTURES "Shops (S117)", PROJECT_COMPILER §2.32, ARCHITECTURE "SRAM bank 3 (S117)", ROOM_DATA_FORMAT "Condition prefixes", EDITOR_DESIGN §5.1b / §5.6b, KEY_LESSONS S117, DOC_AUDIT S117, TOOLS_AND_DATA S117.
- **S116** (2026-10-03): P3.13b the Music tab — the game's own sound engine run in the editor (`dwm/sm83.py` SM83 interpreter + `core/sound_engine.py` + `core/apu_synth.py`; census == PyBoy for every vanilla id and every project song of 5 builds), `sound_catalog.json`; InitBGM same-size -> bank $71 entry 6 (a song's own 1-6 channels), second song bank $75 (`rom0_audio_master` row 5), gate songs (entry 2, `$FF` follow), battle songs (bank $51 same-size -> entry 7; `census_music_resolve.py` 4,000 == the models); the tab (Songs / Rooms / Gates / Battles, names, automatic MIDI import); pin `7bab4921…` (patched). Test ROM `DWM_S116_music_test.gbc` USER-REPORTED 2026-10-03 18:29 ("rom seems to work fine"); the S116b player fix USER-REPORTED working at the S117 start ("rewritten preview player works"). Verbose block in SESSION_HISTORY.md. Owning: SOUND_SYSTEM §1/§2/§9/§10, PROJECT_COMPILER §2.9 "S116", EDITOR_DESIGN §5.6, KEY_LESSONS S116, DOC_AUDIT S116, TOOLS_AND_DATA S116.
- **S115** (2026-10-03): ARC NG / NG1 new random gates — bank $16 entry 5's two GateFloorDataTable readers (8-bit, wrapped at 32) → same-size calls to `GateRowPtr` (free tail $7CFD): 0-31 = the table, 32-95 = bank $76 entry 1 `NewGateRowCopy` → `wGateRowBuf` $D138, else the old wrap; `EncVanillaNumber` walks a new gate's source; `custom.gates[]` 32-95 `copy_of` + `name`; gate-entrance exits (gate_flag 1, `gate:N`); Gates tab New gate / Rename / Delete, Rooms "Gate entrance here…"; PyBoy on the user's save: portal → gate 32 floors (own lists) → special room → custom boss → castle; pin `c8995d91…` (patched). Test ROM `DWM_S115_newgates_test.gbc` USER-CONFIRMED 2026-10-03 12:39 ("Excellent, confirm works"). Verbose block in SESSION_HISTORY.md. Owning: GATE_GENERATION §7.8, PROJECT_COMPILER §2.31, EDITOR_DESIGN §5.1b, KEY_LESSONS S115, DOC_AUDIT S115, TOOLS_AND_DATA S115.
- **S114** (2026-10-03): P3.13a the Encounters tab — bank $01 `LoadNextDungeonFloor` same-size fork → NEW compiler bank $76 `EncResolve` (vanilla rule copies, gate per-floor plans, rooms' own lists, flag variants, room rates) + `wEncListBuf` $D11E read by the five list readers; `custom.encounter_lists` (128-255), `rooms[].encounters.{list,variants,rate}`, `gates[].encounters`; the tab (Lists / Gates / Rooms); census (stub calls, RNG pinned) 0 mismatches on the ORIGINAL ROM + 4 builds; found: draw rule ≥ / RNG word order, encounters.json one floor late (rewritten), counter re-seeded at every room load (S11 corrected); pin `dbc4dee9…` (patched). Test ROM `DWM_S114_encounters_test.gbc` USER-CONFIRMED 2026-10-03 09:52 ("Looks good. Give editor files"). Verbose block in SESSION_HISTORY.md. Owning: PROJECT_COMPILER §2.30, DATA_STRUCTURES "Encounter list choice (S114)", EDITOR_DESIGN §5.5, KEY_LESSONS S114, DOC_AUDIT S114, TOOLS_AND_DATA S114.
- **S113** (2026-10-02): P3.12 the Breeding tab — `editor2/core/breeding.py` (the resolver model, == the game: `census_breeding.py` 53,156 calls + 300 eggs, 0 mismatches; no mutation — `$44DA` has no caller) + `Analysis` (roots incl. gifts / egg rewards, depth, never-firing rows) + `breed_gen.py` (depth-profile generator) + the Breeding tab; special table AUTO-ORDERED when edited, `special.removes` / `special.table`; bank $16 resolver annotated (Phase D item closed); FIXED the FX1 egg-plus bug (`$DA75/$DA76` = farm slots 20/21 since S71 → `$28/$29`); pin `8cf0b93b…` (patched). Test ROM `DWM_S113_breeding_test.gbc` USER-CONFIRMED 2026-10-03 00:19 ("Tested, works"). Verbose block in SESSION_HISTORY.md. Owning: BREEDING_SYSTEM "The resolver as measured (S113)" + "Auto-ordered special table (S113)", PROJECT_COMPILER §2.29, EDITOR_DESIGN §5.4, KEY_LESSONS S113, DOC_AUDIT S113, TOOLS_AND_DATA S113.
- **S112** (2026-10-02): P3.11e skill ANIMATION editing — `custom.animations` (new battle animations $2D-$4C from the stock 45's frames: steps = frame + hold / sound / blank; ≤ 4 sources, ≤ 128 tiles; banks $6F engine + frames, $70 sheets) + `gamedata.skills.<id>.presentation` (animation + motion / screen effect / nothing; regions `gd_anim_routine` / `gd_anim_cmd`); forks ROM0 / $02 `ReadSeqStepFork` / $50 `AnimLoadFork50` / $5F + the developers' viewer (mode 5); the animation system re-sectioned and measured (§11.9 corrects the layer model: the per-skill byte is the animation number; shade order [1,2,0,3]); Animations tab + Skills → Animation with a playing preview and the game's sounds; pin `9ce03bd0…` (patched). Test ROM `DWM_S112_animations_test.gbc` USER-CONFIRMED 2026-10-02 18:29 ("Fantastic, everything checks out"). Verbose block in SESSION_HISTORY.md. Owning: PROJECT_COMPILER §2.28, BATTLE_SKILL_SYSTEM §11.9, EDITOR_DESIGN §5.3, KEY_LESSONS S112, DOC_AUDIT S112, TOOLS_AND_DATA S112.
- **S111** (2026-10-02): P3.11c + P3.11d — the custom skills as project data: `gamedata.skills.<224-233>` (the ten built-ins' data: text, MP, learning, looks, sounds, element, announce, Tame meters, Quake power, banners, Anchor's dialogs) + NEW skills 234-254 on a stock skill's effect (`base`, bank $72 `CustomBaseTable`; 114 measured bases) + an element override for every skill (bank $52 ladder hooks in the dead $51B3 pocket, `CustomElemTail52` for the built-ins); 19 regions, baseline `custom_skills.json` = the S110 bytes; fixed the `{skill}` insert ("CleanCut") and the SFX-table overshoot; element + clone censuses (RNG pinned); pin `4a2860cf…`. Test ROM USER-CONFIRMED 2026-10-02 15:08 ("Looks good"); next = P3.11e animation editing (user). S111b: the built-ins' fixed ratios as data (`gd_custom_ratios`, `ScaleHL72`) + the MagicBurn / Tame AI target-row fix (they hit their own side under the act-time AI); pin `5a1c5404…` (patched); test ROM USER-CONFIRMED 2026-10-03 00:19 ("Tested, works"). Verbose block in SESSION_HISTORY.md. Owning: PROJECT_COMPILER §2.27, BATTLE_SKILL_SYSTEM §13.9 + §15.3, EDITOR_DESIGN §5.3, TEXT_SYSTEM, KEY_LESSONS S111, DOC_AUDIT S111, TOOLS_AND_DATA S111.
- **S110** (2026-10-02): P3.11 the Skills tab — the 222 original skills: `gamedata.skills` + `name` / `description` / `looks_like` → regions over the name block ($41), the SKIL texts + pointers + a 2,993-B spare ($56, re-sectioned), `StockPresentTable` ($5F, `GetPresentId`) and NEW hand patch bank $55 `SfxPresentId` + `StockSfxTable`; `mp` writes both MP copies; the record READER CENSUS (every byte / bit named or proven unread; entry 3/4/5 labels, $55:$4061, +4 = battle MP, +5 = AI element); looks census 1,554 PyBoy battles, no stall (first pass void — act-time AI); S44 hand rename of skill 215 moved to project data; pin `534bfb62…`. Test ROM USER-CONFIRMED 2026-10-02 09:09 ("Excellent work. Give me editor files"). Verbose block in SESSION_HISTORY.md. Owning: PROJECT_COMPILER §2.26, BATTLE_SKILL_SYSTEM §7 + §11.8, TEXT_SYSTEM "Skill text blocks", EDITOR_DESIGN §5.3, KEY_LESSONS S110, DOC_AUDIT S110, TOOLS_AND_DATA S110.
- **S109** (2026-10-01): P3.10b the Arena editor — `gamedata.arena` (class fees, the master of each match, team sizes 1-3) → regions over the two master-sprite tables ($04/$50), the class fee table ($09) and bank $6E `ArenaTeamSizeTable`; NEW engine bank $6E `ArenaTeamFixup` (same-size tails of `ArenaBattleSetup` / `LoadArenaEnemyStats`); team members = the enemy rows; new Arena tab; bank $09 class menu re-sectioned + decoded; found `AddGold` subtracts, display-list order, the King = one match; pin `482c949f…` (patched, historical). Test ROM USER-CONFIRMED 2026-10-01 22:57. Verbose block in SESSION_HISTORY.md. Owning: PROJECT_COMPILER §2.25, SIDEQUEST_MAP "Arena authoring as built — S109", EDITOR_DESIGN §5.2b, KEY_LESSONS S109, DOC_AUDIT S109, TOOLS_AND_DATA S109.
- **S108** (2026-10-01): P3.10 part 3 — renaming the original monsters: `gamedata.monster_text` (name / default nickname / description) → regions over the three text blocks (banks $41 / $4D; spill into the new-species extents / `gd_monster_desc_extra`), recipe lines follow renames, new species' own description; Monsters tab "Name and library text" + new Dialogue tab; found: the join naming prefill = mode 7 (`FamilyCodePtrTable` → `MonsterNickPtrTable`), text ids' overflow banks, `text_id_map.json` 62/2,061 right (now measured: `dump_dialogue.py`; 6,520 script previews refreshed); bank $4D descriptions re-sectioned; pin unchanged. Test ROM r2 USER-CONFIRMED 2026-10-01 (r1: the demo's Slime rate + the user's Library-door redirect, fixed in the demo); repo cleanup (.pyc + example build/ out of git). Verbose block in SESSION_HISTORY.md. Owning: PROJECT_COMPILER §2.24, TEXT_SYSTEM "Monster text blocks" + "Text id resolution", EDITOR_DESIGN §5.2, KEY_LESSONS S108, DOC_AUDIT S108, TOOLS_AND_DATA S108.
- **S107** (2026-10-01): P3.10 part 2a — new art for the ORIGINAL monsters (`gamedata.art` 0-214 → battle gfx / palettes / the 8 walking copies / bank $10-$11 layout + attr regions + art banks $7F/$7C/$7A; Name & art page for originals; Iron Rule 8: 215-220 are not monsters); 7 walking tables + bank $10 tables re-sectioned; pin unchanged — USER-CONFIRMED 2026-10-01 (but the library parent icon stood still). Part 2b — walking layouts: any of the 155 for originals + new species (packer + ranking, `walk_layouts.py`), cross-bank copies in the follower banks' zero tails, bank-$11 `FollowerLayoutBase11` + `NewFollowerL1Table` (donor write gone), Walk style picker; pin `9740c1c9…`. 2b USER-CONFIRMED 2026-10-01. Part 2c — family icons as project data (glyph + streams, Families tab pixel editor) + two missed Spirit icon readers forked (JOURNAL stall); pin `77ccdab8…`; USER-CONFIRMED 2026-10-01. Verbose block in SESSION_HISTORY.md. Owning: PROJECT_COMPILER §2.21/§2.23, MONSTER_DATA "New art for ORIGINAL species" + "Walking layouts as project data", EDITOR_DESIGN §5.2, KEY_LESSONS S107, DOC_AUDIT S107, TOOLS_AND_DATA S107.
- **S106** (2026-10-01): P3.10 part 1 — the Monsters tab (species data, enemy rows + where met, new species cut from sprite sheets with draggable boxes), one species source + sprite renderer; fixed: the LZ decoder (213 battle / 49 walking streams garbled since S22; `census_lz_decode.py` 442/442 == the game), bank-$11 follower attr extraction, resistance wording. USER-CONFIRMED 2026-10-01 (r2 test ROM; r3 tab + gate insertion on the Mac). Verbose block in SESSION_HISTORY.md. Owning: EDITOR_DESIGN §5.2, PROJECT_COMPILER §2.21, MONSTER_DATA (sprite graphics, resistances), KEY_LESSONS S106, DOC_AUDIT S106, TOOLS_AND_DATA S106.
- **S105** (2026-09-30): P3.9b purge of the POC content — new species = project data (`custom.species`, `ns_*` regions + bank $7E) + G3 capacity 19 (ids 221-239, computed follower gfx-ID, packed bank-$41 names), Dracky Clam + S12 mirror gone, Anchor's dialogs built into every build (skill scripts, type $FF); fixed: Anchor soft-lock in projects without room $71, ChopClown / Grendal follower attrs, Spirit parents in the shadow checks, SpellUseText_11 tail, stale build/patches files. USER-CONFIRMED 2026-09-30 ("Confirm all three appear as expected"). Verbose block in SESSION_HISTORY.md. Owning: PROJECT_COMPILER §2.21/§2.22, MONSTER_DATA overshoot registry + follower section, BATTLE_SKILL_SYSTEM §14, KEY_LESSONS S105, DOC_AUDIT S105.
- **S103** (2026-09-29): P3.9 Layer A-lite — `gamedata` sparse overrides into twelve same-size compiler regions (monsters, enemies, encounters, skills, curves, breeding, boss joins; library text + tabs coherent), encounter pool format decoded (+20..+24 = max counts; the measured freeze refused), P3.9b / P3.10a audited. USER-CONFIRMED 2026-09-30. Owning: PROJECT_COMPILER §2.20, DATA_STRUCTURES "Encounter pool entry", KEY_LESSONS S103.
- **S104** (2026-09-30): P3.10a Spirit as the 11th family (bank $6D family systems + forks, `$FA` = Spirit, icon on $1A, ??? restored, unknown-parent icon fix, `gamedata.families`, Families tab, display order) + two FX1 bugs fixed (library list buffer; R4 snapshot restore losing saves). USER-CONFIRMED. Verbose block in SESSION_HISTORY.md. Owning: BREEDING_SYSTEM "Spirit — the 11th family (S104)", PROJECT_COMPILER §2.20, EDITOR_DESIGN §5.2a, KEY_LESSONS S104.
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
| Follower layout library | **155 distinct layouts** (complete; regenerated by `tools/extract_monster_follower_layouts.py` from the real `$10/$11:$407f` tables — the old 118-count brute-force scan dropped 3-entry small/blob layouts). Layout is per-species. Reassignment = same-size 2-byte repoint of the species' `$407f` level-1 entry (same-bank only), NOT a `[$caca]` edit; S107 2b: a layout of the other bank is COPIED into this bank's zero tail (editor2/core/walk_layouts.py), new species have their own level-1 row (`NewFollowerL1Table`). `extracted/follower_layouts.json` (S107: + stored bytes, per-bank instances, bank frames, Y-flip; 155 as entry SETS — 175 by entry order, 188 by raw bytes). |
| Custom layout bank | $64 (layout ptr table + LZSS layout + attr data, 309 bytes used) |
| Vanilla-empty banks | 23 = 368 KB: $60,$64,$67,$69–$77,$79–$7A,$7C,$7E–$7F (full-ROM scan, DOC_AUDIT B). Current allocation: see Bank Allocation table below. |
| Gate floor generation | Standard floors are procedurally generated (4×4 screen grid `$C940`, `(piece<<4)\|variant`); special/boss rooms are fixed templates substituted in. Per-gate config `GateFloorDataTable` `$16:$70A6` (32×8; byte 3 = floor count incl. the boss = FAQ "Levels"); weighting via `SelectFloorType` `$16:$5FC0` + `FloorTypeSelectionTable`1/2/3. Special rooms: only floors 3, 6, 9 … (wRNG1 bit 4 AND `wCurrentFloor` mod 3 == 2 — S100 correction), `rst $00` dispatch at `$16:$5C1C` (sets `wMapID` + `wInGateworld=0`). Custom rooms: `GateDecisionFork` → bank $71 entry 4 (S100). New gates 32-95 (S115): the two row readers go through `GateRowPtr` → bank $76 `NewGateRows` / `wGateRowBuf` (GATE_GENERATION §7.8). Gate names: `extracted/gate_names.json` (ROM-derived S100). **Full pipeline: GATE_GENERATION.md.** |
| Gate damage tiles | Standing-tile id → HRAM `$AA` (`$00:$1E96`); behavior class `$AA>>2`: `$0E` (ids `$38–$3B`) = damage, `$0F` (`$3C–$3F`) = staircase. Amount = `FloorDamageTable` `$01:$5E7D` (16 B by floor type): type 3→5, type 6→10, types $0C/$0E→2, else 0. Applier `ApplyFloorDamage` `$01:$5E23`. (GATE_GENERATION.md §5.1.) |
| Room palette derivation | A room's runtime BG palette is ROM-derivable: real colours are only indices 0 & 2 of slots 0–3 (`$17:$476F`[mapID] normal / `$17:$51F5`[floortype] gate, scanning past empty screens); engine FORCES idx1=`$6bff`, idx3=`$0000` in every BG palette; slots 4–7 shared system; object palettes global at `$17:$5615`. `tools/derive_room_palette.py`, validated 30/30 dumps + gate. (GATE_GENERATION.md §7.1.) |
| Script opcodes | **102** (`$00-$65`, rst $00 table after MarkScriptActive `$04:$5613`); arity + branch kind per opcode from the HANDLER code: `extracted/script_param_counts.json` (`tools/script_param_counts.py`, verify check 5). Script data bank by map type: <$06 `$0C`, <$20 `$0D`, <$40 `$0E`, else `$0F` (master table `$41BA` in each). decompile_script's old PARAM_COUNTS is wrong for 36 opcodes (DOC_AUDIT S96). |
| Room tile animation | bank $01 `PerRoomVRAMDispatch` $60E7 → `rst $00` table `$01:$6119`, **112** entries ($00-$6F), per field frame; clock `$C8A6/$C8A7`; the ONLY BG tile animation (none in gates). Custom rooms: bank $71 entry 3 `CustomAnimSource` (S99), which first runs bank $6C `CustomTileAnimate` — the room's OWN animations (S102, `tile_anims`, GDMA frame copies, any slot / speed). Census `extracted/room_animations.json`; ROOM_DATA_FORMAT "Animated tiles". |
| LZ graphics streams | `WaitDMATransfer` `$00:$1577` (DE = gfx-ID, HL = dest): literal / `[marker, lo, hi4:len4]` copies from dest + 12-bit offset, count len4+4 or next byte + $13 (8-bit, 0 = 256); EVERY source byte re-wrapped 4 KB down when at/after the end, written 0 when that lands below dest. No shared pool. Python twin `dwm/sprite_codec.decode` (S106 fix) == the game for all 442 monster streams (`tools/census_lz_decode.py`). |
| Monster text blocks (S108) | Names `$41:$5B1F-$628D` (mode 5 `MonsterNamePtrTable` $4339; species 0-219 in id order, then "" (220-224) and "?????" (225-255); 1,903 B); default nicknames `$41:$69F2-$6C76` (mode 7 `MonsterNickPtrTable` $4739 — was `FamilyCodePtrTable`; 2 letters; the JOIN naming screen pre-fills the nickname with it, measured S108); descriptions `$4D:$53D3-$7719` (mode 1 = dispatch entries 261-475, ≤ 3 × 18 cells, `$F1` newline, `$67` 't / `$68` 's one cell). Contiguous, id-ordered, unshared (extract_gamedata --selftest). Compiler regions `gd_monster_names` / `gd_monster_nicks` / `gd_monster_desc` (PROJECT_COMPILER §2.24). |
| Skill text + looks (S110) | Names `$41:$628E-$69F1` (mode 6 `SkillNamePtrTable` $4539; 1,892 B); SKIL texts `$56:$502F-$664A` (`SkillDescModeTable` $664B → `SkillDescPtrTable` $6667; ids 151-212 share `SkillDesc_Blank`, 219-255 `SkillDesc_None`) + the spare `$56:$7291-$7E41` (2,993 B). The look of the acting skill = bank $5F `GetPresentId` (12 reads) + bank $55's SFX tables (ONE reader `$55:$4061`); patched build: `StockPresentTable` / `StockSfxTable` (identity = vanilla). Record field map = BATTLE_SKILL_SYSTEM §7 (S110 reader census). **S111:** custom ids ($DE-$FE) read `CustomProxyTable` / `CustomSfxTable` (S110 builds: past the SFX tables); their names / texts = regions `gd_custom_skill_name_ptrs` / `_names` ($41 $7F98, 94 B) and `gd_custom_skill_desc_ptrs` / `_desc` ($56 $7E42, 446 B). |
| Battle animations (S112) | 45 stock ($00-$2C): frames `AnimFrameTable5C/5D/5E` ($4071; < $0E / < $21 / rest), timelines bank $02 row $60 `AnimTimelineTable` $46A1 (pairs frame/hold+1, `$FD` sound, `$FE 4` loop, `$FF` end), tiles `AnimGfxTable` $50:$5E84 (streams $5A/$5B → $8000), palette `AnimObjPalettes` $17:$6B0D, shade `AnimObjShadeTable` $00:$3141 (GBC hw colour i = buffer [1,2,0,3][(shade>>2i)&3], identity $D2 — measured on screen). Per skill: number `AnimCmdTableFoe/Own` $5F:$56ED/$57D5, routine `AnimRoutineIdxParty/Enemy/Link` $58DD/$59C3/$5AA9 → `AnimRoutineTable` $58BD (16; 13 = nothing). Developers' viewer = game mode 5. New ones $2D+: banks $6F/$70 (patched builds). |
| Text id → bank (S108, measured) | ROM0 `TextBankDispatch` $0AD9 (HL = id) → corpus bank by range (TEXT_SYSTEM), whose entry 0 forwards the upper part of its index range to an OVERFLOW bank: $42/$43→$1A, $44/$46→$1B, $45/$48→$1F, $47→$21, $49→$18, $4A→$22, $4B→$3F, $4E→$4F (1,177 of 2,560 ids). `extracted/dialogue.json` = the PyBoy-measured map + every text table (`tools/dump_dialogue.py`); `text_id_map.json` is derived from it (the pre-S108 file matched 62 / 2,061). |
| Breeding resolver (S113) | bank $16 entry 0 `BreedCreateOffspring` (callers $0A:$4A8D / $0A:$56F8 / $15:$5B7D) → entry 2 `BreedResolveOffspring`: `BreedPlusAndSpecial` (plus = max(parents' plus) + 1 + level-sum bonus 40/60/76/100 → +1..+4, ≤ 99; then the special table, first row whose matchers fit and min plus ≤ plus; bank $69 in patched builds) → `BreedFamilySearch` (two passes: mate as species, then as family code; exact pedigree wins at once, family pedigree last match wins; result = row number) → parent 1. No mutation (`$44DA` unreferenced). Python model `editor2/core/breeding.py` == the game (`tools/census_breeding.py`). Patched builds: `$DA75/$DA76` = $28/$29 (S113 FX1 fix). BREEDING_SYSTEM "The resolver as measured (S113)". |
| Encounter list choice (S114) | Vanilla: bank $01 `LoadNextDungeonFloor` (entry $0D, run at every encounter step, floor setup and battle) — list = `GateBasePoolIndex[gate]` + breakpoints ≤ floor (floor = wCurrentFloor + 1), wC8A9 := list +0; the draw (`CalcEncounterPoolIdx`): (wRNG2:wRNG1) mod 100 vs the running sums, first ≥. Patched: a same-size fork far-calls bank $76 `EncResolve` (vanilla copies / gate plans / rooms' own lists / flag variants / room rate) and copies the list to `wEncListBuf` $D11E; the readers read it. Model `editor2/core/encounters.py` == the game (`tools/census_encounters.py`). DATA_STRUCTURES "Encounter list choice (S114)". |
| Music (S116) | Requests: wBGM $C8B7 (SetBGM) / wSoundEffect $C8B8 -> ProcessBGMQueue, AFTER the frame driver `SaveBankAndAudioState` ($3473; also run on lag frames). InitBGM: 3 ids, 4 for $27, 2 for 9 ids; patched: ids ≥ $9E -> bank $71 entry 6 (the song's own 1-6 channels, `CustomBGMChanTable`). Song banks $74 + $75 (AudioMasterTableExt row 5 when songs spill). Room song: bank $71 entry 2 (+ gate songs, `$FF` = follow the gate). Battle song: bank $51 LoadBattle -> entry 7 ($27; $2B = the Starry Night final, wArenaStarryBattle 2). The editor runs the ROM0 sequencer on `dwm/sm83.py` (`editor2/core/sound_engine.py`) == PyBoy (`tools/census_sound_engine.py`). SOUND_SYSTEM §1/§2/§9/§10. |
| Event flags (S117) | Vanilla: `$D99B + index/8`, mask `$26D5` table; Set / Clear / Test `$26A0/$26A6/$26AE` all through ROM0 `ComputeFlagAddress` ($26B3). Patched: that routine same-size → bank $73 entry 21 `FlagAddr` — **`$1000-$17FF` = `wExtFlags` $D140-$D23F** (2,048 flags, saved in SRAM bank 3 "X1" by bank $73 entries 5/6, zeroed by a new game). Editor pool `$0158-$0167` + `$1000-$179F`; `$17A0 + gate` = a gate's own cleared flag. EVENT_FLAGS "Extended flags (S117)". |
| Gate cleared + swirls (S117) | Cleared flag per vanilla gate = `extracted/gate_names.json` `cleared_flag` ($10+n except Anger $1D, Farm $1B, Joy $1C, Wisdom $1A; Demolition $27+$28; 31 none). The spinning swirl = NPC sprite `$4D` (script `$FF`) removed by the boss script's step advance (room $24 counter `$D969`); still swirl = BG art (room $24 sheet $20-$23, pal 3). Patched: every non-gate room's NPC list via bank $60 entry 1 (`$A0`/`$A1` flag prefixes → hidden bit; `VanillaNPCExtTable`); bank $76 entry 2 `GateBossWin` marks re-bossed / new gates cleared. GATE_GENERATION §7.9. |
| Shops (S117) | Shopkeeper = `text $0680 / $FF04 $0000 $0680 / text $0682 / end`; list by ROOM (map $50 → gate list $09:$478C, else wScreenIndex 0 Bazaar $476B / 2 Starry $4774 / 4 Bookstore $477D / other Rare $4784) → `$C0D8` (≤ 20); buy price = `ItemInfoTable` $03:$71DA (44 × 12 B) +1/+2; sell = bank $09 `ShopSellPrice` (gate shop full, staffs /10, else −1/4). Patched: bank $77 `ShopFill` (`wShopID` $D240) / `ShopClose`; S117b: every bank $09 screen push → bank $77 `ScreenPush` (attributes in free-colour rooms). DATA_STRUCTURES "Shops (S117)". |
| Sprite limits (S117b) | Hardware: ≤ 10 objects per screen line (lowest OAM index wins), 40 in all; the field draws 8×8 objects, player OAM 0-3 + 3 monsters 4-15 first, then NPCs in list order → with the party lined up on a row only 1 NPC of that row shows, ~6 NPCs per screen. PyBoy screenshots do not show the per-line drop. Editor: warnings (`formats.sprite_budget`). ROOM_DATA_FORMAT "Sprite limits (S117b)". |
| Script VM (S118) | 102 opcodes, names / params / kinds = `editor2/core/script_ops.py` (arity from the handlers, `extracted/script_param_counts.json`; `$24`/`$61` = 1 via the script bank). Actor 0 = the player (HRAM `$92`/`$95` X/Y, `$8E` facing, `$90` bit 6 hidden), n ≥ 1 = NPC slot n-1 (`$D7D2 + 32(n-1)`). `$0A/$0B/$10/$11` = waited walk (`$D8D7` bit 3); `$1A/$1B/$1C` = queued (buffers `$D8E9 + 8n`, `$19` waits); 1 px on 3 frames of 4; `$22` doubles. Counter rests only on yielding steps. BANK04_SCRIPT_ENGINE "Script opcodes as measured (S118)". |
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
| $60 | Custom rooms / NPCs / scripts / text (+ `CustomMonsterCast` monster-NPC cast tables, S101; S117: entry 1 serves EVERY non-gate room — `$A0`/`$A1` NPC flag conditions, `VanillaNPCExtTable`) | hand-authored `patches/bank_060.asm` (→ `build_project.py` later) |
| $64 | Custom tile layouts + attr data (`custom.layouts[]`, S92; per-screen attr maps S94) | compiler-generated `patches/bank_064.asm` (`layouts64`) |
| $67 | Custom tileset sheets (`custom.tilesets[]`: raw2bpp incl. editor-copied vanilla sheets, or mashup spec) | compiler-generated `patches/bank_067.asm` (`tilesets67`) |
| $69 | Breeding special scanner (B2) + the live special table | hand-kept `patches/bank_069.asm` (scanner) + compiler region `gd_special_recipes` (`gamedata.breeding.special`, S103; `build_breeding.py --emit-special` retired) |
| $6A | New-species info high table (ids 221-239; S105 G3, was 224+): hand `NewSpeciesInfoCopy` (`sub $dd`) + slots 0-18 = compiler region `ns_info` (S105) | hand-kept `patches/bank_06a.asm` + `custom.species` (editor2/core/species.py; `build_new_species.py` emit retired S105) |
| $6B | Project enemy rows (`progression.enemies[]`, EID 519 + index, 25 B each, ≤640; entry 0 `CopyEnemyRowExt` called by bank $14 `LoadEnemyStatsExt`; S101) | compiler-generated `patches/bank_06b.asm` (template `bank_06b_head.asm` + rows) |
| $6C | Own tile animations (`custom.rooms[].tile_anims`: `CustomTileAnimate` entry 0 + `TileAnimRoomTable`, group records, 16-aligned frame blocks; S102) | compiler-generated `patches/bank_06c.asm` (template `bank_06c_head.asm` + data; `tileanim6c`) |
| $6D | Family systems (S104: Spirit = family 10 — entries 0/1 icon gfx id, 2 dialogue text group, 3 default-name id, gfx index 4 `SpiritIconStream`; callers = same-size forks in banks $01/$0A/$04/$09; S107 2c: + the saved-party icon forks in $07 ($62AB JOURNAL) / $0A ($6013), and `SpiritIconStream` is the compiler region `gd_spirit_icon_stream`) | hand-authored `patches/bank_06d.asm` (the Spirit icon bytes checked by `build_family_icon.py --selftest`) |
| $6E | Arena systems (S109: entry 0 `ArenaTeamFixup`, far-called from the same-size tails of `ArenaBattleSetup` $04 / `LoadArenaEnemyStats` $50; `ArenaTeamSizeTable` = compiler region `gd_arena_team_sizes`) | hand-authored `patches/bank_06e.asm` (the table region from `gamedata.arena`, editor2/core/arena.py) |
| $6F | NEW battle animations (S112): engine entries 0-3 `CustomAnimTick` / `CustomAnimInit` / `CustomAnimLoad` / `CustomAnimStep` (template `bank_06f_head.asm`, 391 B) + per animation its frames, timeline, palettes, gfx id (`custom.animations`, ≤ 32) | compiler-generated `patches/bank_06f.asm` (`anims6f`, editor2/core/battle_anims.py) |
| $70 | NEW battle animations' tile sheets (S112; one per animation, the bank $50 stream format) | compiler-generated `patches/bank_070.asm` (`anims70`) |
| $71 | Custom-room dispatch tables (S42 keystone: `Custom26DDTable`, `RoomEncTable`; + `CustomRoomBGMTable` + resolver entry 2, S64; `CustomAnimSrcTable` + entry 3, S99 — S102: entry 3 far-calls bank $6C first; `GateInsertTable` + entry 4 `CustomGateInsert`, `CustomRoomFlagsTable` + entry 5, S100; S116: entry 6 `CustomBGMStart` + `CustomBGMChanTable`, entry 7 `BattleBGMResolve` + the battle tables, entry 2 + `CustomGateBGMTable`) | compiler-generated `patches/bank_071.asm` (template head + tables; S63 `--apply` route) |
| $72 | Custom-skill system (de-aliased S2d/S2e code + tables; S111: `FarSkillFork` → `CustomBaseTable` (new skills run a stock handler), entries 5 `ElemLevel72` / 6 `CustomLearnRow72`) | hand-authored `patches/bank_072.asm` + compiler regions `gd_tame_meter`, `gd_quake_power`, `gd_custom_base`, `gd_skill_elements`, `gd_custom_learn` (editor2/core/custom_skills.py, S111) |
| $73 | Cold Farm systems (CF2 drain, entry 0; CF3 party-first sort, entry 1; … S117: entry 21 `FlagAddr` (the extended flags) + `ExtFlagsCommit` / `ExtFlagsRestore` in entries 5 / 6) | hand-authored `patches/bank_073.asm` |
| $74 | Custom song bank (M3a: records $4001-$417C fixed 95-slot, streams $4180+; resolved by AudioMasterTableExt row $9E; S116: songs keep their own 1-6 channels — no trio padding) | compiler-generated `patches/bank_074.asm` (`music74` emitter → `song_codec.song_bank_asm` ← project.json `custom.music` + `extracted/*_song_library.json`; S64 — `custom_songs.json` retired) |
| $75 | Second custom song bank (S116, P3.13b): the songs past bank $74's 16,000 stream bytes, records indexed from the split id (AudioMasterTableExt row 5 = region `rom0_audio_master`); bank byte + zeros when nothing spills | compiler-generated `patches/bank_075.asm` (`music75`, editor2/core/music.py) |
| $76 | Encounter lists (S114): entry 0 `EncResolve` (+ `EncPickVariant` / `EncFloorRun` / `EncVanillaNumber`) + `EncRoomTable`, `GatePlanPtrs`, the variant lists / floor runs, `ProjectEncLists` (26 B each, numbers 128-255), the vanilla rule's byte copies; far-called by the bank $01 `LoadNextDungeonFloor` fork. S115 (NG1 new gates): entry 1 `NewGateRowCopy` (far-called by bank $16 `GateRowPtr`) + `NewGateRows` (8 B per gate 32+) / `NewGateSource`; template 296 B (S115); S117 (NG2): entry 2 `GateBossWin` (far-called by bank $50's boss-win tail) + `GateClearTable`; template 358 B | compiler-generated `patches/bank_076.asm` (`enc76`, editor2/core/encounters.py) |
| $77 | Shops (S117, P3.13c; S117b: entry 2 `ScreenPush` = bank $09's screen push with palette attributes in free-colour rooms, `ShopClose` → `ShopBoxBottom`): entry 0 `ShopFill` (far-called by bank $09 `ShopBuyStockFill`'s same-size stub; `wShopID` list or the vanilla room rule) / entry 1 `ShopClose` (the shop's close tail) + `SHOP_COUNT`, `ShopPtrTable`, `ShopList_n` (the five vanilla lists, then `custom.shops`); template 438 B (S117b; 93 B S117) | compiler-generated `patches/bank_077.asm` (`shops77`, editor2/core/shops.py) |
| $7E | The project's NEW-SPECIES art streams (38-word pointer table: index (id-221)*2 follower, +1 battle; S105: compiler-owned, all zero without `custom.species`) | compiler-generated `patches/bank_07e.asm` (`species7e`, editor2/core/species.py; streams from `bake_follower_overflow.py --stream-dir`) |
| $7F | RESERVED next sprite-overflow bank (then $7C, $7A, $79) | `dwm/sprite_bank.py` order |
| **Unallocated** | **$79** (1 bank = 16 KB; S117: $77 = shops; S116: $75 = the second song bank; S114: $76 taken; S107: $7A / $7C are art banks) + reserved $7F. | — |

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
8. **Species 215-220 are NOT monsters (user rule, restated S107: "Terry and
   216-220 ARE NOT MONSTERS. They are SPECIAL BOSS + Summons that the summon
   skill makes. I have told you this repeatedly. DO NOT MESS WITH THEM beyond
   giving the ability to change their moves and stats.").** 215 = TERRY? (the
   scripted rival boss), 216-219 = Tatsu / Diago / Samsi / Bazoo (the four
   tiers of the summon skill), 220 = the empty slot. No feature may treat them
   as monsters: no art, palette, name, family, breeding, library or
   new-species use. The only edits offered are their moves and stats (their
   info row's skills / growth / resistances and their enemy rows). Monster
   features cover **0-214** (vanilla) and 221-239 (new species).
   (`editor2/core/gamedata.py PROTECTED_SPECIES`; MONSTER_DATA "Species ID
   geography".)


## Status Dashboard

### Custom content primitives (proven in-game)

| Primitive | Status | Where |
|-----------|--------|-------|
| Add NEW monster species (ids 221–239) | 🟢 mechanism proven with Gorbunok (S28–S38, user-confirmed); **S105: project data** — `custom.species` (name, short name, info row, description, battle art + palette, follower art + walks_like + palette (S107 2b: or any of the 155 walk `layout`s — USER-CONFIRMED 2026-10-01); recipe display derived; enemy rows = project enemies) → `ns_*` regions + bank $7E; no species = the original ROM bytes; the example project carries Gorbunok. **Capacity 19** (ids 221-239 = the game's ceiling; G3 S105). USER-CONFIRMED 2026-09-30 ("Confirm all three appear as expected"). **S106: authored in the Monsters tab — cut from a sprite sheet (DWM2-style: pose + 2 × 3 walking frames) with draggable boxes and a live preview; species fields, enemy rows; USER-CONFIRMED 2026-10-01 (r2 ROM, r3 tab).** | PROJECT_COMPILER §2.21; MONSTER_DATA "Species ID geography" + overshoot registry; EDITOR_DESIGN §5.2 |
| New art for ORIGINAL monsters (0-214: battle pose + colours, walking art + palette + walk style) | 🟢 built S107 (P3.10 part 2a, USER-CONFIRMED 2026-10-01; part 2b walk styles USER-CONFIRMED 2026-10-01 — any of the 155 layouts, packed from the sheet, copied across follower banks): `gamedata.art` → the battle gfx / palette tables, the 8 walking copies, the bank $10/$11 layout + attr tables, art banks $7F/$7C/$7A (≈ 58 re-arted monsters fit); Monsters tab Name & art for originals; PyBoy on the user's save (field, menu, library, battle, join). TERRY? / summons excluded (Iron Rule 8) | PROJECT_COMPILER §2.23; MONSTER_DATA "New art for ORIGINAL species"; EDITOR_DESIGN §5.2 |
| Renaming the ORIGINAL monsters (0-214: name 1-9, default nickname 1-4, library description 3 × 18) + a new species' own description | 🟢 built S108 (P3.10 part 3), test ROM USER-CONFIRMED 2026-10-01 (editor half test_app-verified): `gamedata.monster_text` → regions over the name / nickname / description blocks (banks $41 / $4D; spill into the new-species extents / `gd_monster_desc_extra`), recipe lines follow renames; Monsters tab "Name and library text"; Dialogue tab (every text, measured id map, per-monster mentions); PyBoy on the user's save (INFO, battle messages, naming prefill, text-engine stub calls). TERRY? / summons excluded (Iron Rule 8). Dialogue keeps literal names (read-only list) | PROJECT_COMPILER §2.24; TEXT_SYSTEM "Monster text blocks (S108)"; EDITOR_DESIGN §5.2 |
| Arena authoring (class fees, the master of each match, teams of 1-3 monsters, the teams' enemy rows) | 🟢 built S109 (P3.10b), test ROM USER-CONFIRMED 2026-10-01 22:57 (PyBoy on the user's save: Starry Night 1 / 2 / 3, the King with 2, a monster master, fee 20 charged): `gamedata.arena` → `gd_arena_masters_04/_50`, `gd_arena_fees`, `gd_arena_team_sizes` + bank $6E `ArenaTeamFixup`; Arena tab | PROJECT_COMPILER §2.25; SIDEQUEST_MAP "Arena authoring as built — S109"; EDITOR_DESIGN §5.2b |
| Editing the ORIGINAL skills (0-221: name, SKIL text, MP — both copies, learning, power, targets, AI fields, behaviour bits, looks + sounds of another skill) | 🟢 built S110 (P3.11), test ROM `DWM_S110_skills_test.gbc` USER-CONFIRMED 2026-10-02 09:09 ("Excellent work. Give me editor files") (PyBoy on the user's save: a renamed Zap with its own text, 1 MP and Bang's look hitting 3 foes; MetalCut at all foes; HealMore → Cure 200 HP): `gamedata.skills` name / description / looks_like → `gd_skill_names`, `gd_skill_desc*`, `gd_present_proxy_5f/_55` (+ bank $55 `SfxPresentId`); Skills tab. Battle items read-only (Items tab later); custom skills = P3.11c (built S111, next row). **S111:** `element` for every skill (the resistance its damage tests, bank $52 ladder hooks) | PROJECT_COMPILER §2.26; BATTLE_SKILL_SYSTEM §7 / §11.8; EDITOR_DESIGN §5.3 |
| Skill ANIMATIONS (new battle animations $2D-$4C made from the 45 stock animations' frames + tiles, with sounds; per skill an animation + motion / a screen effect / nothing) | 🟢 built S112 (P3.11e), test ROM `DWM_S112_animations_test.gbc` USER-CONFIRMED 2026-10-02 18:29 ("Fantastic, everything checks out") (PyBoy on the user's save: Zap → Spark storm on each foe, MetalCut → Frost slash, Scorching → blink, EvilSlash → GigaSlash's; the developers' viewer census = the editor's model frame by frame): `custom.animations` → banks $6F / $70; `gamedata.skills.<id>.presentation` → `gd_anim_routine` / `gd_anim_cmd`; Animations tab + Skills → Animation (preview with the game's sounds). New tile art = later (user) | PROJECT_COMPILER §2.28; BATTLE_SKILL_SYSTEM §11.9; EDITOR_DESIGN §5.3 |
| Custom rooms (mapID ≥ $6B) | ✅ table-driven to editor scale: render/palette/attr/$26DD records + per-room encounters via bank $71 tables (S40/S42); multi-screen scroll (v28); gate-rotation insertion + descent (S41; data-driven S100 — next row). | EDITOR_DESIGN §2; GATE_GENERATION §7; CROSSBANK_ROOMS |
| Custom NPCs with scripts | ✅ working | bank $60 entry 4 dispatch |
| Custom text, multi-page, line breaks | ✅ working | IDs $0A00+, two-level ptr table |
| YES/NO choices with branching | ✅ working | $E7 $F0 + opcode $15 on $C83C |
| Item give + inventory-full check | ✅ working | opcodes $2A (wrapped) / $2C |
| Monster/egg give + storage-full check | ✅ working | opcodes $29 (wrapped) / $28; egg path is the practical choice |
| Script-driven teleport | ✅ working | opcode $0F (MapTransitionFull); vanilla + custom destinations |
| FIELD-cast custom skills (menu → context logic → dialog → effect) | ✅ SHIPPED, USER-CONFIRMED S73 (+S73b descriptions & battle rejection): skill $E4 "Anchor" (anchor gate floor → warp to GreatTree → return later for 3/4 current MP charged on arrival; persistent through save; single-use; forced-standard regenerated floor). Full field-cast pipeline RE'd: usability whitelist, $da5e, bank $14 entry 4/5, menu-shell states ($c90d 0-4), script arming from the menu. PyBoy-verified round trip via the real UI. | BATTLE_SKILL_SYSTEM §14; bank $72 AnchorField14Tail; patched pin `8fa605d7…` |
| Menu-armed dialog scripts in ANY room (incl. maze floors) | ✅ user-confirmed S73 (part of Anchor): ctr=$FFFF arming; GateAwareDispatch script-type branch. S105: script type **$FF** = the built-in skill scripts (bank $60 `SkillScriptPtrTable`, editor2/core/skill_scripts.json) — no custom room needed (was $71 = the example's medal_vault; a soft-lock in other projects), built S105, PyBoy on the user's save (≥$6B, ≠$70) | PROJECT_COMPILER §5 (template re-pin); KEY_LESSONS S73 |
| BGM change | ✅ working | opcode $41 (SetBGM); reverts to the ROOM DEFAULT on exit/reload |
| Room-default music (vanilla + custom rooms) | ✅ working (S64, user-confirmed v6): `music.room_defaults`/`rooms[].music` → `CustomRoomBGMTable` (bank $71 entry 2) consulted first by the rewritten `LoadNewBGMIdIntoA`; survives save/reload by construction; sources = inbuilt ids, DWM2 catalog (all 31), MIDI conversions | SOUND_SYSTEM §8; PROJECT_COMPILER §2.9 |
| Event flags set/clear/check | ✅ working | opcodes $00/$01/$03; 328 referenced, 298 with sets (branch-following) |
| Extended event flags (2,048, `$1000-$17FF`, saved) + NPCs shown by flag (`shown_when`) | 🟢 built S117, test ROM USER-REPORTED 2026-10-03 21:57 ("The rest works"); editor pool 1,968 named flags | EVENT_FLAGS "Extended flags (S117)"; PROJECT_COMPILER §2.32 |
| Gate swirls follow each gate's cleared flag (new gates, re-bossed vanilla gates, re-routed portals) + the cleared mark of custom bosses | 🟢 built S117 (ROADMAP NG2), test ROM USER-REPORTED 2026-10-03 21:57 ("The rest works") | GATE_GENERATION §7.9; PROJECT_COMPILER §2.32 |
| Shops — the game's five lists, the project's own shops (any NPC a shopkeeper), item buy prices | 🟢 built S117 (ROADMAP P3.13c), test ROM USER-REPORTED 2026-10-03 21:57 ("The rest works"; the menu colours in free-colour rooms + the leftover box fixed S117b, NOT yet user-tested) | DATA_STRUCTURES "Shops (S117)"; PROJECT_COMPILER §2.32; EDITOR_DESIGN §5.6b |
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
| Random encounters in custom rooms | ✅ generalized per-room (S42 `RoomEncTable`, bank $71). **S114 (test ROM USER-CONFIRMED 2026-10-03 09:52 ("Looks good. Give editor files")): a room may use a list of its OWN (no gate pin, inside or outside dives) with flag variants and its own battle rate; gates get per-floor lists + flag variants; the project's own lists 128-255 — the Encounters tab (next row).** | CROSSBANK_ROOMS; KEY_LESSONS S11 (S114 correction); DATA_STRUCTURES "Encounter list choice (S114)" |
| Custom breeding | ✅ **S113 (P3.12, test ROM `DWM_S113_breeding_test.gbc` USER-CONFIRMED 2026-10-03 00:19 ("Tested, works")): the Breeding tab (depth per monster, recipes, Try a cross, Problems, special / family tables, whole-table form, tree generator), the special table auto-ordered when edited (+ `removes` / `table`), the FX1 egg-plus bug fixed (every egg was +1 and no + recipe fired since S71)** — PROJECT_COMPILER §2.29, EDITOR_DESIGN §5.4. Earlier: full authoring stack B1–B7: round-trip encoder; bank $69 owns the special table (overrides+appends+shadow validator); family-defaults rewrite; family reassignment; production library grouping (zero lag). **Spirit = a first-class 11th family (S104, USER-CONFIRMED 2026-09-30):** bank $6D family systems, `$FA` = Spirit, ghost-wisp icon, ??? restored, shown before ???, editor Families tab. | BREEDING_SYSTEM; ROADMAP Phase 2B |
| Custom battle skills (net-new ids) | 🟢 NINE custom skills live: MagicBurn $E0 (S49), Tame $E1 (S50), TameMore $E2 + TameMost $E3 (S52), Anchor $E4 field-cast (S73, user-confirmed; S105: its dialogs are built into every build — no custom room needed), Earthquake chain $E5-$E8 (S74; **S84: AI-commit of $E6-$E8 was CRASH-CAPABLE on all pre-S84 builds** — dispatch-table overrun, fixed by DispatchBoundsStub; PyBoy re-verified S84, awaiting user test), **Mourn $E9 (S75: ATK-vs-DEF × (dead allies+1), 2nd dispatch trampoline = per-skill vanilla damage machine; **S84: AI-commit was CRASH-CAPABLE (wild jump to WRAM) on all pre-S84 builds** — fixed S84; AI-commit activation USER-CONFIRMED on the real save (Charge tactics))** — all on the full de-aliased stack incl. natural-learn, real MP, announce, descriptions. **S111 (test ROM USER-CONFIRMED 2026-10-02 15:08 ("Looks good")): their DATA is project data** (`gamedata.skills.<224-233>`, 19 compiler regions, baseline `editor2/core/custom_skills.json`; $DE/$DF retired) (S111b: their fixed ratios too — MagicBurn burn, Tame damage, Anchor charge, Quake allies' share, Mourn bonus — test ROM USER-CONFIRMED 2026-10-03 00:19 ("Tested, works")) **+ NEW custom skills 234-254** on a stock skill's effect (`base`; 114 measured bases; own name / text / MP / learning / power / targets / looks / sounds / element / announce) — Skills tab. | BATTLE_SKILL_SYSTEM §12–§13.9, §14; PROJECT_COMPILER §2.27; ROADMAP Arc 2, P3.11c/d |
| SRAM save layout | ✅ audited S8: custom flags persist (truly-safe pool = 32 flags, S57); collisions mapped; free SRAM tail $BFC8-$BFFF (56 B, reserved). **32 KB expansion BUILT S69 (RAMB pin + CF3SRAMBankedCopy; NOT yet user-tested)** — +24 KB persistent in banks 1-3, uninitialized until a schema exists (E3 residual); S117: bank 3 = the extended flags "X1" | ARCHITECTURE "SRAM banking as built S69"; known_RAM_map |
| Custom-room WRAM state | ✅ migrated S65 into the CF3-freed window (buffers $CC80/$CD00, counter region $CD80×640, wCustomPool $D001-$D664; TRANSIENT permanently, init-guaranteed zeroed). v7 USER-CONFIRMED S66 | patches/wram.asm banner; PROJECT_COMPILER §2.6; ROADMAP CF4 |

### Not yet implemented

| System | State |
|--------|-------|
| Custom monster pools (Encounters #2) | 🟢 **BUILT S114 (P3.13a), test ROM `DWM_S114_encounters_test.gbc` USER-CONFIRMED 2026-10-03 09:52 ("Looks good. Give editor files")** — bank $76 + the same-size bank $01 fork; the Encounters tab. PROJECT_COMPILER §2.30 |
| Custom music | 🟢 **M1-M3c COMPLETE (S61-S64, all user-confirmed)**: engine map, round-trip codec, general slots (bank $74), room-default assignment for any mapID, `custom.music` schema, 31-song DWM2 catalog, MIDI import. **S116 (P3.13b; test ROM `DWM_S116_music_test.gbc` USER-REPORTED 2026-10-03 18:29 "rom seems to work fine"; the editor's preview player rewritten S116b, NOT yet user-tested): the Music tab — preview on the game's own engine (no emulator), names, automatic MIDI import; a song's own 1-6 channels (InitBGM ext), a second song bank $75, gate songs, battle songs (fight / arena / Starry final / room / gate / boss / normal).** Open boxes: event jingles (victory / level-up) not editable, CI compiler-test |
| Arena/boss roster AUTHORING (E1→E2 wiring) | RE ✅ DECODED S67; **ARENA half built S109 (P3.10b, test ROM USER-CONFIRMED 2026-10-01 22:57)** — `gamedata.arena` + the enemy rows, Arena tab (the "Arena authoring" primitive row). Gate-boss rosters: their enemy rows are editable on the Monsters tab (S106); a boss editor is not built |
| Combat simulator (arc S78-S88) | 🟢 **COMPLETE through the pacing layer (S86) + commit-model close-out (S87: party bases from the instance record, obedience EXACT 889/889 on the WLD stat, $7997 + TRUE-loaf closed)**: `simulator/damage.py` 698/698 (S78) + specials (S79); `turn_order.py` 143/143 (S79); AI `ai.py` 26/26 + rule chains `ai_rules.py` 240/240 (S80/S81); `battle.py` loop glue 6614/6614 (S85) + 802/802 on fresh S86 captures; **S86: measured RNG idle model (`measure_idle.py` → `s86_idle_model.json`), full-battle driver `pacing.py` (commit + rounds + TTK), aggregate-validated (`validate_pacing.py`: round-level PIT uniform over 197 rounds; 5 fresh real-save battles inside sim envelopes), `sweep_ttk.py` gate-pool sweeps, `profile_check --ttk` gating**. **S88 (built, NOT yet user-tested): confusion end-to-end + snap-out (2824/0), riders 40/40 ($69 boss veto = application-only), curse MP MaxMP//6, poison cap 15/15, PsycheUp closed empty, $DB06/$DB07 writer map, dodge incapacity exemption; 3 new corpora; the S79 $7AB5 confusion attribution corrected to Transform (DOC_AUDIT S88).** Residuals (§15.9 + ROADMAP S89): the low-stat calcdef edge (2 deterministic SameBoy repros), meta-actions (hero-slot MENU verbs — PARTIAL, named box), and +8/+9 defensive-flag consumers. **S89 (built, NOT yet user-tested): Group-B residuals CLOSED — $DB07 = IRONIZE counter (not stun); interception = Cover/Guardian guard table (`guard_redirect`, 14/14); WLD level-up writer = none; `board_from_event` consumes real ai_bases/WLD; defensive-set sweep folded into status.py. New corpora s89_fresh (426/1 flagged) + s89_guard (14/14). Annotation: $670E re-sectioned, guard/iron handlers commented.** **S90: arc adjudicated DONE FOR PURPOSE (user-conferred); residuals banked as non-blocking boxes ($DB42 setter, +8/+9 consumers, meta-actions menu drive, guard-validator polish).** | BATTLE_SKILL_SYSTEM §15, §15.6, §15.9; TOOLS_AND_DATA §2.10 + S89 rows; ROADMAP S89/S90 |
| Randomizer (standalone; English + German builds) | ✅ **SHIPPED, USER-TESTED, part 2 S77** — `randomizer/`, data tables only plus ONE code change (`plusgrowth.py`, opt-out). Breeding tree regenerated to a target depth profile (3-6) with deeper = better; bosses/arena/wild stratified against vanilla's measured correlations; skills dealt from vanilla's usage bag and never below vanilla's minimum placement level; growth shuffled within vanilla-ordering bands; paralysis + full heals banned on boss/arena rows; pools de-duplicated. Gate: `randomizer/profile_check.py` (per-entity envelopes) + `randomizer/audit_threat.py` (per-row damage parity). | randomizer/README.md; BATTLE_SKILL_SYSTEM §record power field is BLIND; BREEDING_SYSTEM §Depth is a function of matcher SPECIFICITY; MONSTER_DATA §Growth randomization needs a per-species envelope; PROJECT_COMPILER §Validation the editor must run |
| Editor app (Phase 3) | 🟢 Skeleton S72 → design v2 S90 → P3.0-P3.2b S91/S92 → **P3.3 canvas v1 + shell S93** → **S94 canvas v2 + real room model + S94b entrance redirects & per-state rooms (built, NOT yet user-tested):** vanilla/custom room columns (every vanilla state browsable), clone-with-confirm carrying ALL vanilla states (paintable at once), New/Copy/Rename/Delete, File→New project (blank template), metatiles (4 subtiles + palette) as the editing unit, Select-first with real selection, Walkability mode (BR-subtile twin swap, tileset copied into the project), 4×4 grid, vanilla-format per-(screen,state) attr+palette tables (engine), records for every room (ROM0 region), **"Route a vanilla door here" = `custom.entrance_redirects` → per-(map,screen) exit overrides (Entry 6 + Entry 9)** — the in-game test route for any custom room; **S95:** picker = the room's whole vocabulary (never shrinks) + borrow tiles from any vanilla room under this room's palettes (import across tilesets, PyBoy-verified) + on-open migration of pre-S94 projects. Acceptance PyBoy-verified incl. walking and the door walk-through. **S96 (USER-CONFIRMED 2026-09-25 ("Everything works")): P3.3c Tileset tab (slot map + release) + P3.3d (change tileset / blank sheets, Import art tab for PNG rips, per-subtile metatile palettes, bank space meters) + Make editable works on all 98 vanilla rooms (opcode arity from the handlers).** **S97 (USER-CONFIRMED 2026-09-26): rooms group B — P3.5a flag state rules (engine entry 8 + bank $17 hook; persistent custom-room versions) + P3.5 NPC inspector (13 measured behaviours, hidden bit, talk text, presence, drag; **r2**: per-box talk editor with ROM-font preview, cream dialog/YES-NO boxes in free-colour rooms, NPC section, sections start folded).** **S98 (doors USER-CONFIRMED 2026-09-26; the rest built, NOT yet user-tested): rooms group C = P3.7 — named door objects linked two-way (+ Door, double-click to connect, arrive ON the door), one-way teleports, examine / step-on spots (the "$8F spawn" misnomer retired), talk scripts with YES/NO + set/clear flags + move, edge-vs-scroll guards, World tab v0; tileset tools (own copies, split move, purge).** **S99 (built; signed off 2026-09-27, r7 not yet re-tested in-game): P3.3e animated tiles — measured census, per-room animation source (engine), canvas outline + ▶ Play preview, inspector choice, clones = source, migration; Make animated tab (r3-r7: paint pads + part tools, still quarters, take-over, split move, count) + stray repair / Make still (r4).** **S100 (built, NOT yet user-tested): P3.7b part 1 — Gates tab v1 (32 gates, rules per gate, floor plan, rule dialog) + Rooms-tab "Inside gates" (arrival, Stairs down, saving, battles, music) → custom rooms served on gate floors.** Later rows: S101-S105 (boss floors, own animated tiles, gamedata, Spirit / Families tab, new species as project data — dashboard rows above). **S106 (USER-CONFIRMED 2026-10-01): P3.10 part 1 — the Monsters tab (species data, enemy rows + where met, new species from sprite sheets).** **S107: P3.10 part 2a — new art for the original monsters (USER-CONFIRMED 2026-10-01); part 2b — walk styles (any of the 155 layouts; USER-CONFIRMED 2026-10-01); part 2c — family icon editor (Families tab; USER-CONFIRMED 2026-10-01).** **S108 (test ROM USER-CONFIRMED 2026-10-01): P3.10 part 3 — renames / default nicknames / descriptions (Monsters tab) + the read-only Dialogue tab.** **S109 (test ROM USER-CONFIRMED 2026-10-01 22:57): P3.10b — the Arena tab (fees, masters, teams of 1-3, the team rows).** **S110 (test ROM USER-CONFIRMED 2026-10-02): P3.11 — the Skills tab (the 222 original skills).** S111-S112: custom skills, animations (rows above). **S113 (test ROM USER-CONFIRMED 2026-10-03 00:19 ("Tested, works")): P3.12 — the Breeding tab.** **S114 (test ROM USER-CONFIRMED 2026-10-03 09:52 ("Looks good. Give editor files")): P3.13a — the Encounters tab.** **S115 (USER-CONFIRMED 2026-10-03 12:39): NG1 new gates.** **S116 (test ROM USER-REPORTED 2026-10-03 18:29 "rom seems to work fine"; editor preview fixed S116b, USER-REPORTED working at the S117 start): P3.13b — the Music tab.** **S117 (built, NOT yet user-tested): NG2 swirls / cleared + the Shops tab (P3.13c).** **S118 (built, NOT yet user-tested): P3.8 part A — the Cutscenes tab (every scene read, shown, played in the game: EDITOR_DESIGN §5.1d).** Earlier note: Next: P3.11c (custom skills as project data) or the user's choice (P3.7b part 2, P3.4 PyBoy preview deferred by the user, P3.6 dialogue, P3.8 storyboard). | EDITOR_DESIGN §5.1 as built S94; ROADMAP P3.3b |

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
- ~~Custom-sprite BACKGROUND colour is pure white vs vanilla's slightly
  creamy white (user-reported S90)~~ **RESOLVED** — user on the S106 r2 ROM
  (2026-10-01 13:17): "background colour is perfect" (the S106 sheet import puts
  the cream $6BFF behind every pose; the S90 sprite was most likely the S21 Clam
  POC, purged S105). EDITOR_DESIGN §5.2, DOC_AUDIT S107.
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
- (S108) Bank $47's T1 re-section (S43) started its string region at the pre-S108
  `text_id_map.json` address $4174: the bank's FIRST string `$47:$40C1` (text id
  $03C8, measured) is still mgbdis fake code. Re-run the T1 region bounds from the
  measured `extracted/dialogue.json` when Phase F T2… resumes (ROADMAP Arc 1 note).
  The tool `gen_script_banks.py` / `decompile_script.py` read `text_id_map.json`,
  which is correct again (derived from dialogue.json).
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

