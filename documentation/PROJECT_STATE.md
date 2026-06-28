# PROJECT STATE — Single Source of Truth

> **This file is the entry point for every session.** It is the only document
> allowed to state project-wide status. Other docs are subject-specific
> references and must not duplicate status claims. If this file and another
> doc disagree, this file wins — and the session should fix the other doc.
>
> Last verified: 2026-06-28 (Session 46 — **Phase F / S2-arc: skill PRESENTATION
> foundation decoded + record-table round-trip keystone + re-section.** Integrity
> PASS 4/4, clean build byte-perfect `1ca6579…`. Byte-neutral (discovery +
> annotation + tooling); no functional ROM. NOT yet user-tested — handoff for a
> fresh instance to continue.)
> **S46 — S2 was NOT done; it is an ARC.** S45 shipped a single-caster,
> Blaze-shaped alias POC (correct but narrow). Audited S45 byte-for-byte: built
> correctly, no false claims; the error was marking S2 "done". This session
> decoded the skill **presentation** layer that the alias hack worked around.
> **Core architecture proven:** handler (`$52:$4011`) = effect TYPE (shared:
> Blaze/Blazemore/Blazemost → one handler `$41CD`); the per-skill **record**
> (`$54`) = parameters. **(a) Record table fully decoded + round-tripped:**
> `$54:$4013` pointer entries (dispatch entries 9–230) = `$41CF + id*19`, 222 × 19B
> data at `$41CF`. `build_skill_tables.py` now re-emits the pointer table + data
> **byte-identical** (`--selftest` 5/5 PASS); the 4218-byte block is **re-sectioned
> to clean `db` records** in `bank_054.asm` (editable in source). Field map (FAQ-
> validated PROVEN: +0 effect_class, +1 effect_category, +2 target_mode, +3
> **ai_weight** (per-skill AI score summed by enemy AI `$57`), +4 mp_cost, +5
> status_id, +6 damage_class, +11/+13/+15/+17 power min/range party/enemy — 31/32
> FAQ damage-heal ranges exact). **(b) Item-effect/meat system (#3):** the 37
> item_effect skills (ids 176–212) are the in-battle items; shared handler
> `$52:$4625` (record-driven); meat items (194–198) special-case via `$52:$4014`
> → recruitment handler `$58:$591E`. **(c) Animation dispatch (#2):** handler picks
> a descriptor-setter (`$52:$5460–$54f8`) → `$dd6f` (bit7=has-effect) + `$dd70`
> script pointer (Blaze=`$b882`) → bank `$4c` effect engine + `$55` sprite anim;
> pointer space `$b6xx–$bcxx` (`$b682` default). **OPEN:** effect-script bytecode
> FORMAT + `$b000` backing not reversed = the animation-authoring sub-item.
> **Tools:** `gen_skill_records.py` (+battle_record 7th source), `build_skill_tables.py`
> (+record round-trip, `--emit record/recordptr`). Annotation comment/label-only in
> `bank_052/053/054/058.asm` (clean build stays `1ca6579…`). Full RE + field tables
> + confidence: **`BATTLE_SKILL_SYSTEM.md` §7–§10.** **NEXT for the new instance:**
> either (1) reverse the effect-script bytecode (animation authoring, bank `$4c`),
> or (2) the real authoring step — proper per-id custom-skill records (own record +
> handler + name) that REPLACE the S45 alias hack, enabling heal/Tame/Anchor shapes.
>
 Integrity PASS 4/4, clean build byte-perfect
> `1ca6579…`. Functional change (rename) **user-confirmed in SameBoy: skill 215
> displays "BugCut".**)
> **S44 — the skill subsystem is now data-complete for an editor.** Audited the
> reshaped S1 and found it was already partly done (bank `$52` `SkillFunctionTable`
> was re-sectioned with named handlers); the real work was the *data* tables.
> **Two undocumented tables fully decoded and FAQ-validated:**
> **(a) `SkillMPCostTable` `$07:$570C`** — 222 × u16 LE = MP cost to cast (`999`=ALL,
> ids 50/102). The disassembly **mislabels this region `TilesetLookupTable`**; the
> indexing fn `$56E8` is effectively `GetSkillMPCost` (its id-`$70`/Ahhh special case,
> gated on `[$cacc]&1`, picks Ahhh's male/female MP 1/2). Renamed **only in comments**
> pending SameBoy confirmation of the fn's callers. **(b) `SkillLearnReqTable`
> `$06:$50E0`** — 222 × 18B: `+0` level u8; `+1` hp `+3` mp `+5` atk `+7` def `+9` agl
> `+11` int (u16 LE); `+13..17` up to 5 prereq skill ids (`$FF`=none). Validated vs the
> FAQ incl. MegaMagic's 5 prereqs. **BugCut finding:** id 215 (ROM name "Sheldodge", a
> placeholder) is the **Bug-family cut** — proven 3 ways: family sub `$6349` tests family
> code `$05`=Bug; StubBird's enemy list uses 215; its learn reqs match the FAQ's "BugBlow"
> row exactly. Renamed to **"BugCut"** in `patches/bank_041.asm` (10-byte slot preserved;
> **user-confirmed in SameBoy**). **Real skill count is 222 (`$00–$DD`), not 256:** the
> 222 entries classify as **155 skill / 37 item_effect (`$B0–$D4`) / 30 internal**, by
> cross-referencing monster natural sets + enemy lists. Corrected the bank `$52` header
> (`$4211`→`$6CC7` dispatch, `256`→`222`, `140`→`115` handlers). **Tools (NEW):**
> `gen_skill_records.py` → `extracted/skill_records.json` (222 records: name, kind, mp,
> handler+shared group, learn block, prereqs, family code, monster/enemy usage; `_generator`
> key, all 6 source addrs); `build_skill_tables.py --selftest` proves the JSON re-emits the
> function/MP/learn tables **byte-identical** (444+444+3996 B, PASS). Annotation is
> comment-only in `disassembly/bank_006/007/052.asm` (clean build stays `1ca6579…`).
> Test ROMs: `DWM-BugCut-test.gbc` (full stack + rename), `DWM-BugCut-vanillaVillager.gbc`
> (villager fork reverted so wild Picky is catchable — throwaway; project keeps the gate mod).
> **Follow-ups:** confirm the `TilesetLookupTable`/`$56E8` role in SameBoy, then rename +
> re-section both tables to real `dw`/`db` blocks; retire the old 256-entry `skills.json`
> (still read by `gen_name_tables_db.py`). Next item: **authoring NEW skills** (data side is
> ready; novel effects need a new handler in a free bank = the ASM frontier).
>
> Last verified: 2026-06-26 (Session 43 — **disassembly gap audit + Arc-1/T1 text
> re-section keystone (bank `$47`).** Integrity PASS 4/4, clean build byte-perfect
> `1ca6579…`; T1 is byte-neutral so there is no test ROM — acceptance is the MD5.)
> **S43 — two things.** (1) **Disassembly audit** (user-requested): characterized what is
> entirely un-understood or misassembled. Three gaps were *understated* in docs and are now
> first-class: **(a) audio** — engine partly in bank `$08` (`LoadAudP`, the SGB path; switches
> to `$78`) + scattered `Aud_`/`SoundEffect` routines, barely annotated; song/SFX **data**
> in banks `$61 $62 $63 $65 $66 $68 $78 $7b $7d` (~9 banks/144 KB) misassembled as
> instructions, reached only as DATA (nothing executes them) — format unreversed; **(b) battle
> engine** — bank `$52` holds the labeled `SkillFunctionTable`/dispatch but the 140 skill-effect
> handlers + `Battle*` funcs (banks `$52-$5f`) are auto-labeled only; the **damage formula, turn
> order, and enemy AI selection** are untraced (the `ai_weights` are extracted as DATA but the
> consuming algorithm is unlocated); **(c) vanilla text `$42-$4B,$4E`** — fully tool-extractable
> but **misassembled as fake instructions in source** (~12k bogus lines/bank), so vanilla text
> isn't editable in place. (Phase E's E1/E2 confirmed as genuine, already-flagged gaps.) The full
> attack plan is mapped in **ROADMAP Phase F** (Arc 1 text, Arc 2 skills+AI, Arc 3 music) —
> session-sized items, keystone-first methodology, with S3/M1 flagged as real RE.
> (2) **Arc-1/T1 DONE (byte-perfect):** new `tools/resection_text_bank.py` converts a corpus
> bank's contiguous DTE string run into `TextStr_<bank>_<addr>:` + `db` blocks (one label per
> text id, decoded text in a comment), labels/comments only. Region is data-driven (first string
> addr from `text_id_map.json`; end = bank trailing-fill scan) and snapped to real line
> boundaries via a probe-build line→address map (same machinery as `resection_library_tables.py`)
> so no fake instruction is split; exact ROM bytes are emitted as `db`, so a wrong split fails
> the build instantly. **Bank `$47`: 69 strings, run `$4174-$5b74`, 5607 fake lines replaced;
> clean build stays `1ca6579…`, integrity PASS 4/4.** Idempotent, re-runnable from clean tree.
> Docs updated in place: TEXT_SYSTEM.md "Source re-section" (method + per-bank bounds table),
> ROADMAP Phase F (Arc plan, T1 ticked), TOOLS_AND_DATA (tool). Files: `disassembly/bank_047.asm`
> (re-sectioned — clean tree, zero byte impact), `tools/resection_text_bank.py` (NEW).
> `APPLY_THESE_CHANGES.md` regenerated.
>
> Last verified: 2026-06-26 (Session 42 — **Phase 2 keystone: table-driven custom-room
> dispatch COMPLETE & user-confirmed in SameBoy.** Integrity PASS 4/4, clean build `1ca6579…`;
> test ROM `DWM-S42-custom-room-keystone-v3.gbc`, **user-confirmed: 3-room walk loop with
> visible staircase exits, amber `$70` renders past the old ceiling with working encounters +
> exit, green `$6D` gate rotation → boss still works.**)
> **S42 — the editor-backend keystone (EDITOR_DESIGN §2) is built.** All remaining hardcoded
> per-room intercepts are now table-driven, and the old `$6B-$6F` room ceiling is lifted to
> editor scale. **Architecture:** dispatch *logic + data* live in the previously-empty bank
> **`$71`** (reached via `rst $10`), so every in-bank edit is a **byte-neutral** stub — no
> scarce/fragmented ROM0 or bank-`$0B` free space consumed, and no risk to dense code/audio
> banks. (1) **Encounters #1 folded in:** `RoomEncTable` (bank `$71`, 3 B/room
> `[enabled,gate,floor]`, indexed `mapID−$6B`) via `CustomEncResolve` (bank `$71` e1) replaces
> the hardcoded `cp $6B` whitelist in `$0B`; `$6B` keeps gate-0/floor-1 exactly. (2) **`$26DD`
> ceiling lifted:** `Custom26DDTable` (bank `$71`, 8 B/room, indexed `mapID−$70`) via
> `CopyCustomRoomRecord` (bank `$71` e0) far-copies the tileset/dims/threshold record into
> `wRoomRecScratch` ($D47F). All three consumers (both `$0B` GFX loaders + the ROM0 collision
> threshold reader) read scratch; for `mapID<$70` the routine replicates the original
> `$26DD/$2A5D` index byte-for-byte (vanilla + `$6B-$6F` unchanged). Threshold site preserves
> `C` with `push bc`/`pop bc` around `rst $10`. This sidesteps the in-ROM0 `$70`↔`$2A5D`
> gate-table collision. (3) **Render tables** (`CustomRoomPalPtr`/`CustomRoomAttr`, `$17`)
> relocated to the bank tail + widened to 6 entries (`$6B-$70`; `$6E/$6F` vanilla-fallback).
> (4) **`MapIDClampForPalette`** (ROM0) made **uniform** (`$00` for all custom rooms) — already
> O(1); removed the dead `$6B→$16` special case. (5) **Room data** (`CustomSourceMapTable`/
> `CustomRoomPtrTable`, `$60`) widened to 6. **Proof:** room **`$70`** (amber) added *past* the
> ceiling by table rows alone; walkable loop `$6B→$6C→$70→$6B` with **staircase** exit markers
> (`$3C-$3F` placed on the exit metatiles via `tools/build_gate_room.py`); `$6D` (green) left
> as the gate-rotation-only proof. `$6B/$6C/$6D` behavior preserved. Files: `patches/bank_071`
> (NEW), `bank_000` (clamp + threshold site), `bank_00b` (2 GFX sites + encounter hook),
> `bank_017` (render tables relocated/widened + `$6D`/`$70` palettes), `bank_060` (tables + `$70`
> room + chained exits), `bank_064` (regenerated: exit staircases), `wram`
> (`wCustomStep_Room70_S0 $D47E`, `wRoomRecScratch $D47F`, `wRoomEncFlag $D487`), `game.asm`
> (`bank_071` include), `tools/build_gate_room.py`, `tools/verify_integrity.py`
> (`PATCH_NEW_FILES += bank_071`). Docs updated in place: EDITOR_DESIGN §2 (as-built),
> ROADMAP (Phase 2 keystone + Encounters #1 ticked, Pillar A ceiling-lift note), KEY_LESSONS
> (S42). `APPLY_THESE_CHANGES.md` regenerated for git.
>
> Last verified: 2026-06-26 (Session 41 — **Phase 2C: custom gate room INSERTION half ("Pillar B")
> complete & user-confirmed in SameBoy.** Integrity PASS 4/4, clean build `1ca6579…`; test ROM
> `DWM-gate-rotation-v3.gbc`, **user-confirmed: room appears every gate-1 floor, descends to boss,
> with whoosh + continuous BGM.**)
> **S41 — custom room `$6D` inserted into the Gate of Villager (gate 1) rotation, descending
> floor-to-floor.** This is the *insertion* half that Pillar A (S40, table-driven render) set up.
> (1) **Insertion via a byte-neutral fork**, NOT the planned `rst $00` slot: the 6-byte gate-0
> exclusion at `$16:$5BA9` (`ld a,[wGateID]/or a/jr z,jr_016_5bbf` — reads **`wGateID $C935`**,
> correcting an earlier `wCurrentFloor` cite) is replaced in place by `call GateDecisionFork`+3 nop.
> The fork (`$16:$7CB9`, end-of-bank padding) routes by `wGateID`: gate 0 → vanilla maze, gate 1 →
> `CustomGate1Setup` (`wMapID=$6D`, mirror of `$50` handler `$5D0D`), gates 2–31 → untouched RNG
> gating. A `pop hl` discards the call's return addr so gate 0/1 unwind to entry-5's caller (not back
> into the RNG path). (2) **Descent** via a `gate_flag=$80` exit on the room's PIT tile (mirror of
> special rooms `$50/$51`) → re-enters entry-5 floor setup, increments `wCurrentFloor`, re-runs the
> fork → `$6D` again until the boss floor. (3) **Descent-transition feel fixed.** Both the slow
> dissolve and the per-descent BGM restart trace to **one cause**: the custom room runs with
> `wInGateworld=0`, so the engine treats each descent as a *fresh hub→gate entry*. Making it a real
> in-gate floor (`wInGateworld=$01` during display) **freezes the game** — that flag gates every
> gate/maze branch and the un-intercepted ones read absent maze state. Fix is **transient**: set
> `wInGateworld=$01` **only during the transition window** (`CustomDescentInGate` @ `$0B`
> `jr_00b_466b`/`$45F9`, byte-neutral; resets to 0 before redraw via the fork) → whoosh + BGM
> continuous, render/descent unchanged. Dedicated room `$6D` keeps the `$6B`/`$6C` demos intact.
> Files: `patches/bank_016` (fork + setup), `bank_000` (`$26DD[$6D]` 1-screen gate record),
> `bank_017` (`CustomRoomPalPtr/Attr[2]` borrow `$6B`), `wram` (`wCustomStep_Room6D_S0 $D47D`),
> `bank_060` (`$6D` room data + descent exit), `bank_00b` (`CustomDescentInGate`). Docs updated in
> place: GATE_GENERATION §7.5 (+§6 `rst $00` table corrected: idx0=`$5C42`, idx2=`$5CCB`), ROADMAP
> (Phase 2C both halves ticked), KEY_LESSONS (S41: pop/jp fork control-flow; `wInGateworld=0` ⇒
> fresh-gate-entry transition; transient-flag-during-transition technique). `APPLY_THESE_CHANGES.md`
> regenerated for git.
>
> Last verified: 2026-06-25 (Session 39 — **Phase 2C: custom gate room (rendering half) +
> room-palette derivation fully solved & tooled.** Integrity PASS 4/4, clean build `1ca6579…`;
> gate-room test ROM `DWM-gate-room-v5.gbc` MD5 `2a008235…`, **user-confirmed in SameBoy**.)
> **S39 — two landed pieces.** (1) **Custom Room `$6B` now wears the Gate-of-Beginning maze
> tileset** (gfx-ID `$280D` = bank `$28` step `$0D`, floortype `$D`): a sandy island with an
> ocean-wall border (incl. top), 2×2 **tree** (`$34-$37`/pal3) and **dune** (`$38-$3B`/pal0)
> metatiles, and pit holes — all real gate tiles with the real gate floor palette (`$17:$629D`).
> Authored in new `tools/build_gate_room.py` → `patches/bank_064.asm`; gfx-ID/threshold in
> `bank_000.asm`; `CustomPaletteColors_6B` (slots 0–3 ONLY — widening clobbers system slots →
> monster-colour corruption) in `bank_017.asm`. Palette assigned **per position** (trees need
> pal3 yet share the `$30` collision-threshold side with ocean/floor). This is the *rendering*
> half of "custom room into the gate rotation"; the `rst $00` *insertion* half is still open.
> (2) **Room-palette derivation from ROM** (`tools/derive_room_palette.py`): a room's real BG
> colours are only indices 0 and 2 of slots 0–3 (from `$17:$476F`[mapID] normal / `$17:$51F5`
> [floortype] gate, scanning past empty screens); the engine **forces idx1=`$6bff`, idx3=`$0000`**
> in every BG palette; slots 4–7 are a shared system set; object palettes are one global block at
> `$17:$5615`. Validated **30/30** SameBoy dumps + the gate floor; refuses cleanly when a room has
> no resolvable pointer. Docs updated in place: GATE_GENERATION §7.1–7.3 + palette tables,
> TOOLS_AND_DATA (both tools), ROADMAP (Phase 2C rendering half ticked), KEY_LESSONS (S39: forced
> colours / screen-scan / decimal-label / metatile-palette lessons).
>
> Last verified: 2026-06-25 (Session 38 — **Phase D new-species data-table SEAMS annotated +
> Phase N lineage parent-name "?????" FIXED.** Integrity PASS 4/4, clean build `1ca6579…`;
> lineage test ROM `DWM-lineage-fix-v1.gbc` MD5 `2a09d94f…`, **user-confirmed in SameBoy**.)
> **S38 — two pieces, both landed.** (1) **Data-table fork SEAMS** now self-documenting at their
> clean anchors (labels/comments only, build byte-perfect; the S33 pass did the DISPLAY seams, this
> finishes the data-table set): `bank_003 label443f`/`SaveMon_4446` (single info indexer; id≥224 →
> bank `$6A` fork; also reached as `$03` entry 1 by breeding's `$0301` parent-family load),
> `bank_014 LoadEnemyStats` (16-bit EID → NO fork) + new label `EnemyStatsTrailingFree` @ `$7EAD`
> (append region; EIDs 487–517 are unusable CODE, first grid-aligned slot is EID 518 `$7EB3`),
> `bank_001 EncounterPool_000` (empty slot = in-place insertion point, Iron-Rule-2 safe),
> `bank_016 label16_485c` (entry-1 recipe lookup overshoots 222-entry `FamilyRecipeTable` →
> `FamilyRecipeResolve` display fork) + the `$0301` parent→family seam (new species resolves a real
> family as a breeding parent via the forked info loader). (2) **Lineage parent-name fix (N5 sub-item
> closed):** the library/encyclopedia lineage line-1 showed "?????    ?????" for Gorbunok. Verified the
> path from clean source (entry 2 `call SetB4d_43b9` → `HighDetailTextFork` → `HighModeTable4D` for
> id≥224), then wired `HighModeTable4D` mode-0 → new `HighMode0Ptrs` → `GorbunokRecipeLine`
> (`patches/bank_04d.asm`). Also **corrected a latent format bug** in the S32-staged string: real recipe
> lines use TWO 9-char fields (e.g. slot 200 "Servant  GreatDrak"), so rebuilt as `"Snaily   BattleRex"`
> (names sym-verified vs `MonsterNamePtrTable $41:$4339`). id≥224-gated → ids 0–223 byte-identical.
> Built-ROM check: `[mode0base+224*2] → GorbunokRecipeLine` → "Snaily   BattleRex". Docs updated in
> place: ROADMAP (Phase D seams ticked, N5 lineage sub-item done), MONSTER_DATA (overshoot registry
> lineage row → DONE, data-table seam annotations recorded).
>
> Last verified: 2026-06-24 (Session 36 — **Starter + force-join verification (audit of legacy
> editor knowledge).** Integrity PASS 4/4, clean build `1ca6579…`.)
> **S36 — starter mechanism PROVEN end-to-end and editor claim confirmed.** Starter = enemy-stats
> **EID 1** (`$14:$4C36`); granted by Castle intro `add_monster enemy=$0001` at `$0C:$42D6`, gated by
> flag `$0002` (fires once at new game), built via `LoadEnemyStats(EID 1)` → `label14_40b4`. Confirmed
> in-game (EID 1 → SkyDragon Lv25 swap). Stats transfer as base then take an 80–100% creation roll
> (`SaveEnem_4821`). Annotated the previously-raw-`db` grant block in `bank_00c.asm`
> (`Bank0C_ScriptAddr_4270:`, labels/comments only, byte-perfect). **Force-join hack verified** (hooks
> `$54:$55D5` NOP + `$54:$5604`→`$7FC8` resolver + `$7FE0` table all correct; logic sound) but **NOT
> ported** — brittle on `wGateID` (`$C935`) overload (arena/bank_055 zeroes it; gate-entry/bank_016 sets
> it to `wMapID`, not the editor's 0–31 ordering), table range, and tier-7 lacking a `join_eid` redirect.
> Crossbank left untouched per directive. Docs updated: MONSTER_DATA.md (Starter Monster, stat creation
> roll, force-join verification), EVENT_FLAGS.md (flag `$0002`).
> Last verified: 2026-06-24 (Session 35 — **Milestone G2: new-species BATTLE sprite + battle
> palette baked into `patches/`; user-confirmed OK.** Integrity PASS 4/4, clean build `1ca6579…`,
> patched build verified.)
> **S35 — battle-art half is now permanent too.** id 224 (blue-dragon proof art) now shows its real
> custom sprite IN BATTLE (royal-blue body / white belly / black outline), matching the G1 follower.
> What landed in `patches/`: the dragon battle pose packed as a **2nd overflow entry** in `bank_07e.asm`
> (`Battle_sp224` @ gid **`$7E01`**; the follower stays `$7E00`, byte-identical — the pointer table just
> grew to 2 entries); `bank_000.asm` repoints `MonsterBattleGfxTable[224]` at `$00:$2d5f` `$320f`→`$7e01`
> — a **same-size 2-byte edit, NO fork**, because the species-indexed battle gfx table `$2b9f` has a real
> (padding) slot for id 224 (contrast the follower tables, which overshoot and needed id-indexed forks);
> `bank_017.asm` forks the battle-palette reader `label17_41d0` byte-neutral (`call HighBattlePal` + 5 `nop`)
> to a resolver in the bank `$17` filler tail (`$6cea`) — id≥224 → custom palette `67 4d ff 6b ff 7f 00 00`,
> else vanilla `$62fd+species*8` (its slot `$69fd` overshoots into `PaletteColorData`). Tool
> `tools/bake_follower_overflow.py` extended with `--battle-art/--battle-spec` (emits both streams, prints
> the battle gfx-ID + palette); new spec `examples/follower_swap/gorbunok_battle.json`. No verify_integrity
> PATCH-list change (`bank_000/017` already in PATCH_FILES, `bank_07e` in PATCH_NEW_FILES). See
> KEY_LESSONS + MONSTER_DATA "NEW species battle sprite".
> **S34 — follower-art fork is now permanent + editor-shaped.** id 224 (blue-dragon proof art)
> walks the overworld / shows in menu+library with real custom art, built from the canonical
> `make` path. What landed in `patches/`: new overflow bank `bank_07e.asm` (blue-dragon 256B
> layout-0 payload, gid `$7E00`); all **8 follower-art gfx-ID copies** forked to a per-bank
> **id-indexed `NewFollowerGfxTableNN`** (`dw $7E00` at slot 0; resolver computes
> `table + (species-224)*2`, so adding species 225 = append a `dw` + rebuild — content-sized,
> grows on rebuild); `bank_011.asm` writes the layout level-1 slot `$413f = dw $4184` and forks
> the attr read (`HramUnk11_406e` → `NewAttrHandler @ $11:$792d`, id-indexed `NewFollowerAttrTable`);
> overworld clamp narrowed `cp $e0`→`cp $e1` so 224 passes (225–255 still clamp). New patch files:
> `bank_011/059/07e.asm`; new tool `tools/bake_follower_overflow.py` (emits the art bank).
> **Two orientation bugs found + fixed PROPERLY (root cause, not band-aid), both the same lesson —
> sanitise the base attr surgically:** (1) art is stored **un-flipped** (the `--flip-y` band-aid was
> removed from both tools); (2) the clean-attr mask is **`$B8` not `$98`** — `$98` also cleared the
> engine's bit5 X-flip, breaking the LEFT facing. See KEY_LESSONS + MONSTER_DATA. **G2 (battle sprite +
> battle palette for id 224) is now DONE (S35, above).** NOT yet done (next): `new_species.json` schema
> fold (G3).**

> **S33 — name/text/lineage/follower display fork seams now self-documenting at the clean anchors.**
> 11 files touched (`bank_000/001/006/007/009/00b/012/016/018/041/059`), comments+labels only.
> Covered: bank `$41` `$4007` mode→table config list, the corrective `FamilyCodePtrTable` block
> (it's the SPECIES-indexed 2-letter default-nick table, mode 7 — NOT a family table; label kept
> for ref-stability, flagged legacy), `Func_Bank41_GetText/GetPutText`; ROM0 `SaveBankAndSwitch
> $092F`/`TextHandler_0940 $0940` two-level `[mode][id]` lookup + per-mode-count overshoot hazard +
> `LoadModeBaseRedirect $00F0` fork cross-ref; bank `$12` lineage chain (`LoadItem_6456`→`$4d` entry
> 2 modes 0/1, `LoadItem_65a8`→recipe `$1601`→parent icons, `CmpItem_65cb`→`ItemSlotPtrTable`); the
> **8 follower gfx-ID copies** one-line-commented at their add-base sites (`$01/$06/$07/$09/$0b/$12/
> $18/$59`, all operands sym-confirmed to the tool's bases); + one optional cross-ref at bank `$16`
> `$0301` parent-family load. **Two corrections baked into source + MONSTER_DATA:** ItemNamePtrTable
> is **mode 8** of the `$4007` list (NOT mode 11 = `$49CD` MiscTextPtrTable); `$4739` overshoots at
> **id≥215** (fork covers **id≥224**; 215–223 phantom). Decisions (per user): keep the label + strong
> corrective comment (no rename), bank `$16` breeding-determination internals deferred to a
> breeding-mechanics pass. Docs updated in place: ROADMAP (Phase-D seam box → partial, display seams
> done, data-table seams `bank_003/014/001-encounter` + breeding internals still pending),
> MONSTER_DATA (overshoot registry + 8-copy add-base table + the two corrections). Changed source
> files are clean-disassembly only; no patches/tools/extracted touched.
>
> Last verified: 2026-06-22 (Session 30 — **Phase N audit + two reproducibility defects
> fixed; user-playtested OK**. Gorbunok (id 224) caught in Gate of Beginning, lists under
> Slime family, visualizable in library; custom rooms + encounters still good. Integrity
> PASS 4/4, clean build `1ca6579…`, test ROM `DWM-newspecies-repro-v1.gbc` MD5 `c17c2840…`.)
> **S30 — Phase N keystone verified; library + encounter made TOOL-OWNED (reproducible).**
> Forensic re-audit of the "add new monsters part 2" commits: clean disassembly net-zero
> change (the d84a43f/c4af28b comment add+remove cancel; nothing lost), N2 info-fork +
> N3 enemy-stats verified byte-correct (info table pinned at `$4461`, ids 0–220 byte-
> identical bar the 2 B6 reassigns; EID 518 @ `$14:$7EB3`). Two latent defects found and
> fixed, both "patch works but not reproducible from its tool": **(1)** the library Gorbunok
> entry + the unseen-marker move `$E0`→`$FE` (needed because `$E0` is now a real species)
> were hand-edited — `build_library_table.py` now reads `new_species.json` and owns all
> three marker sites (`ld [hl],$fe` + 2× `cp $fe`), count-validated, `--selftest` still
> proves vanilla parity. **(2)** the wild-encounter insertion (pool 0 slot 3 = EID 518) was
> hand-edited — `build_new_species.py` now emits it as a same-size in-place `EncounterPoolData`
> edit (validates the target slot was empty in vanilla first; Iron-Rule-2 safe). NOTE: an
> earlier audit claim that the encounter was "not applied" was MY error (searched the pool
> for species id `$E0` instead of EID `518`); the encounter was correct, only un-reproducible.
> Docs updated in place: BREEDING_SYSTEM (walker marker `$FE`), MONSTER_DATA (overshoot
> registry: encounters are a pool edit not a fork, follower 3/8 partial, library tool-owned),
> ROADMAP (N2/N3 ticked, N4/N5 partial, + a Phase-D follow-up to annotate the fork seams in
> clean disassembly). Changed files: `tools/build_library_table.py`, `tools/build_new_species.py`,
> `patches/bank_012.asm`, `patches/bank_001.asm`, `extracted/library_grouping.json` (+ docs).
>
> Last verified: 2026-06-22 (Session 29 — **encyclopedia DETAIL page FREEZE fixed**;
> Gorbunok (id 224) detail now opens clean, integrity PASS 4/4, ROM
> `DWM-Gorbunok-stage1ac-v16.gbc` MD5 `4d3d0d59…`. User-playtested: no freeze, no
> glitches; entry mirrors Dracky.)
> **S29 — detail-page freeze root-caused and fixed; recipe overshoot fixed.**
> Root cause: monster detail text uses a **mode×species double indirection** in
> `SaveBankAndSwitch` (`$00:$092F`) — source = `[ [$4007 + mode*2] + id*2 ]`. The
> line-2 **description** table (`$4D:$420B`) is only **215 entries** and ends at
> routine code, so id 224 read `[$43CB]=$0609` (ROM0 code) and the text VM rendered
> code as glyphs forever → `WaitScreenUpdateDone` spin. Fixed by a byte-neutral fork
> of `SetB4d_43b9` → `HighDetailTextFork` (custom mode-table; id≥224 line-2 →
> `$60BC`, Dracky's description as placeholder). Separately, the breeding-recipe
> lookup `label16_485c` indexed the **222-entry** `FamilyRecipeTable` unchecked
> (id 224 → bogus parents); forked via `FamilyRecipeResolve` → `$FF,$FF` (no recipe,
> correct for wild-only). New patch file `patches/bank_04d.asm` (registered in
> `PATCH_FILES`). The "material icon"/"stale Healer info" were render-abort artifacts
> and cleared with the freeze. New docs: `TEXT_SYSTEM.md`,
> `MONSTER_DATA.md` (Species ID geography) (species-indexed-table overshoot checklist); mechanism in
> `TEXT_SYSTEM.md`; recipe/new-breeding path in `BREEDING_SYSTEM.md`; lessons in
> `KEY_LESSONS.md`. **Deferred:** custom Gorbunok sprite/art and a custom (non-Dracky)
> description string. Vanilla 0–220 byte-identical; clean build still `1ca6579`.
>
> Last verified: 2026-06-21 (Session 28 — Phase N kickoff: add-NEW-species scoping/RE.
> No bytes changed, vanilla ROM untouched, integrity PASS 4/4. Pure RE + data tool —
> nothing to playtest yet; N2 is the first ROM.)
> **S28 — "add new monsters on top of the 221" scoped + slot map delivered.**
> User goal: brand-new species (not reskins). Species id is a single byte → hard 256
> ceiling; ids 215–219 are special (215 `TERRY?` one-off enemy; 216–219 Tatsu/Diago/
> Samsi/Bazoo = summon-skill byproducts, user-confirmed), 220–223 empty/phantom, so the
> **first free id is 224 (`$E0`), budget 32 (224–255)**. Architecture chosen: **high-table
> + single forked loader, vanilla 0–220 byte-identical** — each per-species table has ONE
> arithmetic indexer to fork (`if id < 224 → vanilla, else → free-bank high-table`).
> Verified single indexers: monster info `$03:SaveMon_4446` (×43; all 16 consumers read
> the `$DA33` copy), enemy stats `$14:LoadEnemyStats` (×25, **16-bit EID** → no 256 wall on
> the battle side). The ceiling is NOT one clean gate: ~40 `cp $dd`/`cp $de` hits are
> false positives (interrupt boilerplate + misassembled data); only 4 real top-range
> special-case gates (`$5f/$57/$58/$52`) need the N6 "treats ≥224 as normal" check.
> Deliverable: `tools/map_species_slots.py` + `extracted/species_slot_map.json` (256-slot
> map, self-aborts on drift). Plan: ROADMAP "Phase N" (N1 done; N2 info-table fork is the
> keystone next session); mechanics: MONSTER_DATA "Species ID geography".
>
> Last verified: 2026-06-21 (Session 27 — Phase D re-section: bank `$12` library/family
> data **COMPLETE**. Labels-only, byte-perfect — clean build still `1ca6579…`, integrity
> PASS 4/4. No behavioral change, nothing to playtest.)
> **S27 — bank `$12` window-layout run finished (whole bank now editor-addressable).**
> Extended `tools/resection_library_tables.py` to convert the **two remaining contiguous gaps**
> in the menu window-draw layout run: `$724e..$759a` (10 layouts) and `$75c0..$7b42` (13 layouts).
> Combined with S26, the entire contiguous run **`$710c..$7b9b` = 29 layouts** now reads as named
> `db`/`dw` (`LibWinLayout_<addr>`), all 13 remaining `ld de,$imm` reference sites labelized (44
> total across S26+S27). The 380-B `$79c6` full-screen library view (an 18×20 layout using a
> *different* window-border tileset, `$01 $02..$03`/`$04`/`$05`) is converted — its mgbdis fake `jr`
> labels (`$7a05`…`$7aca`) and their `jr` sources were all inside the data range and vanished
> together (no dangling refs). The 21 `ld hl,$XXXX; rst $10` far-call descriptors (`$5605`/`$6100`/
> `$6101`) correctly LEFT raw. New data deliverable `extracted/library_layouts.json` (29 layouts
> decoded to rows; `--dump-json`). Tool is now per-table idempotent and re-runnable from the clean
> tree (verified: clean-tree run reproduces byte-perfect build + identical 29-label set). Format +
> per-layout table: DATA_STRUCTURES "Library / family-tab menu data (bank `$12`)"; ROADMAP Phase D
> bank-`$12` item ticked complete. This closes the bank-`$12` re-section; the remaining Phase D work
> is the stale-box verify-ticks (`$03`/`$14`/`$16`) and editor-driven banks (`$01`/`$50`/`$51`).
> Also recorded (Session 27) a **"new campaign" gap analysis** — the campaign-scale subsystems
> beyond editor v1 (arena/gate-boss roster format, story-progression authoring + bank-`$50`,
> new-game init/save headroom, gate-network, intro/ending, text capacity) — in ROADMAP "Phase E",
> with the two story/arena keystones detailed in SIDEQUEST_MAP "Gaps for authoring a NEW campaign".
> The keystone RE gap is **E1 (arena/gate-boss roster format)** — the natural next Phase-D/E session.
>

> Last verified: 2026-06-21 (Session 26 — Phase D re-section: bank `$12` library/family
> data tables converted to labeled `db`/`dw`. Labels-only, byte-perfect — clean build still
> `1ca6579…`, integrity PASS 4/4. No behavioral change, nothing to playtest.)
> **S26 — bank `$12` library/family data tables re-sectioned (editor-addressable).**
> `tools/resection_library_tables.py` converts the misassembled library-menu data tables in
> `bank_012.asm` to named `db`/`dw` (labels/comments only, zero byte impact): `LibraryFamilyTabBounds`
> (`$6294`, 11 B family id-range bounds — the S18 case, "THE ONLY id-range family assumption in the
> ROM"), `LibTabColPos_564a`/`_5a8e` (tab-column cursor positions, `$ffff`-terminated, read by
> `FuncItem_43e2`), and `LibWinLayout_710c`/`_71aa`/`_71f4`/`_759a`/`_7b42`/`_7b6c` (menu window-draw
> layout streams: dest-position word + tile bytes, `$d8`=newline, `$d9`=terminator, via
> `ReadPtrFromDE` + draw loop `$40c3`). 31 raw-pointer reference sites labelized. `$5605` correctly
> LEFT — it's a far-call descriptor (`ld hl,$5605; rst $10` → bank `$56` entry `$05`), NOT `$12` data;
> the `$79c6` region conservatively skipped (mgbdis put `jr` labels in it; it is reached via `ld de`
> so likely a convertible layout — flagged for the bank-`$12` follow-up). The tool maps source
> line→address via a zero-byte probe-build read from the linker `.sym` (avoids the S22 opcode-size-
> summing trap) and is re-runnable from the clean tree. Format + addresses: DATA_STRUCTURES
> "Library / family-tab menu data (bank `$12`)"; remaining bank-`$12` tables + skip-list folded into
> ROADMAP Phase D "Re-section misassembled data tables". Supports the B8/B9 library/family work
> (the 11th-family tab + bounds are now named/editable rather than re-derived from raw bytes).
>
> Last verified: 2026-06-21 (Session 25 — GFX-4 DONE: monster→follower-layout auto-map +
> custom-art import + full multi-context consistency. Healer→Dragon clone and Dracky→custom
> blue-dragon both user-confirmed "everything is correct" in SameBoy, consistent across overworld
> + menu + library.)
> **GFX-4 DONE — monster → follower-layout map, custom-art import, all-context consistency.**
> (1) The level-1 layout dispatch tables are LOCATED at FIXED addresses **`$10:$407f` (species
> 0–127) / `$11:$407f` (species 128+)**, 128 `dw` each, indexed by species directly (`$ffc7 =
> species+$10`, routed `$10–$8F`→bank `$10`, `≥$90`→bank `$11` via bank-`$04` entry 2). A per-species
> **attr/palette table at `$10:$417f` (128 entries) / `$11:$412d` (87 entries)** (ORed into `$ffca`, low 3 bits = OBJ palette). **Two
> pre-GFX-4 doc errors corrected:** `[$caca]` is the SPECIES (party struct +$09), NOT a "sprite-class"
> byte; and bank `$05` is the ObjTest viewer path, NOT the follower path (S24 anchored to `$05`
> addresses — harmless because dedup ignored bank, but wrong). Both Healer (sp9, sharing) and DarkDrium
> (sp214, non-sharing) reproduced byte-for-byte through `$10`/`$11`. (2) `tools/extract_monster_follower_layouts.py`
> + `extracted/monster_follower_layouts.json` (every species → layout id + addresses + sharing); it
> REGENERATES & REPLACES `follower_layouts.json` with the COMPLETE **155 layouts** (old 118 dropped
> the 3-entry small/blob layouts the brute-force scan rejected). `--selftest` PASS (215/215
> collectible map; anchors verified). (3) **The follower-art gfx-ID table has EIGHT copies**
> (`$01 $06 $07 $09 $0b $12`-library `$18`-menu `$59`); a consistent swap must repoint all 8 (layout
> `$407f` + attr `$10:$417f`/`$11:$412d` are single/shared). GFX-3 repointed only `$01` → that's why swapped monsters
> kept old art in menus. (4) `tools/build_follower_reassign.py` — reassignment primitive: clone
> layout+art+attr from a same-bank monster, OR import custom 16-tile art (placed cross-bank via the
> GFX-2/3 overflow allocator, all-8-copies repointed) + set layout (default layout 0 `$10:$4e33`) +
> OBJ palette. Layout 0 packing: tiles 0–3=DOWN-a, 4–7=SIDE-a, 8–11=SIDE-b, 12–15=UP-a (down_B/up_B
> auto-mirror; LEFT = right X-flip). Clean build still `1ca6579…`; integrity PASS 4/4. Reassignments
> are reproducible EXAMPLES, not baked into the canonical ROM. **Reassignment is a level-1 repoint,
> NOT a `[$caca]`/species edit** (supersedes the GFX-3 plan's "same-size `[$caca]` edit"). Method:
> KEY_LESSONS "Session 25"; mechanics: MONSTER_DATA "Monster → layout dispatch".
>
> Last verified: 2026-06-21 (Session 24 — GFX-3 DONE: walking/follower sprite swap +
> follower metasprite engine fully reverse-engineered + 118-layout library extracted.
> Blue dragon → DarkDrium follower user-confirmed "absolutely perfect" all 4 directions.)
> **GFX-3 DONE — follower (walking-sprite) swap, end to end.**
> (1) `ScreenTransDataTable` @ `$01:$49DF` re-sectioned from mgbdis fake-instructions to a
> labeled `dw` block (`tools/resection_follower_gfx_table.py`; 231 entries indexed
> `species+$10`, + `FollowerFamilyGfxTable` 10 families @ `$4BAD`; build still `1ca6579…`,
> zero external refs into range). `build_sprite_swap.py --kind follower --payload F.bin`
> repoints the dw entry and DMAs a self-contained 16-tile (256 B) literal-encoded stream.
> (2) **Follower render = metasprite engine** — `SaveScr_40cd` @ `$04:$40cd` (GBC variant of
> ROM0 `$0d91`). A two-level pointer table (sprite-type `$ffc7` → frame/direction `$ffc8`)
> selects a metasprite list: 4-byte entries **(dy, dx, tile_offset, attr)**, `$80`-terminated.
> Final OAM tile = `tile_offset + [$ffc9]` (follower tile base `$20`/`$30`/`$40` per party
> slot 0/1/2); final OAM attr = `[$ffca] XOR attr` (X-flip = bit5 `$20`). `$ffc7 = [$ca91]`
> (= `GetActiveMonsterStatus` return: `$01` if bit7 of `[$cb0b]`, else `[$caca]+$10`).
> (3) **OBJ transparency rule (critical):** colour index 0 is HARDWARE-transparent for OBJ
> sprites (the battle path used a BG backdrop = index 1 — opposite). Follower empty/background
> pixels MUST map to idx0. 8 global OBJ palettes (4×RGB555) at `$17:$5615`.
> (4) **Per-monster layouts — there is NO single universal arrangement.** The tile→direction
> mapping is one of **118 distinct layouts** (`tools/extract_follower_layouts.py` →
> `extracted/follower_layouts.json`). **76 are non-sharing** (disjoint down/up/side tile sets
> → ANY distinct art renders perfectly; cover 202 sprite types) and **42 are sharing**
> (up/side reuse tiles — fine for radially-symmetric blobs, breaks directional art; 58 types).
> This resolved the multi-attempt mystery: a symmetric blob masks layout errors (the clam
> "worked" by luck); a directional dragon exposes them. Healer = a sharing layout, DarkDrium =
> a non-sharing one (both measured, both matched the extracted data exactly).
> (5) Tooling: interactive `tools/follower_frame_picker.html` (drag 6 boxes over a sprite
> sheet, live per-direction engine-accurate preview, export coords/payload). **Numbered-tile
> calibration method** (each VRAM tile renders its own hex index 0–F + a flip-foot →
> read the layout directly off-screen, no decoding) — `--palette` override forces black digit
> / red foot for legibility against terrain.
> USER-CONFIRMED in SameBoy: blue dragon (DWM2 art) → DarkDrium follower, all 4 directions
> correct, by matching the art to DarkDrium's non-sharing layout.
> **FOLLOW-UP — GFX-4 flagged (ROADMAP):** monster→layout auto-map. The type→layout level-1
> dispatch tables (banks `$05`/`$10`/`$11`, routed by `$ffc7` magnitude: `<$10` bank `$04`,
> `$10–$8F` bank `$10`, `≥$90` bank `$11`) and the per-monster sprite-class byte (`[$caca]`)
> are not yet located/extracted; the full engine structure IS known, so it's a clean pickup.
>
> Last verified: 2026-06-20 (Session 23 — GFX-2 DONE: cross-bank sprite backbone +
> monster battle palette SOLVED + recolour; clam→Dracky purple + full integration
> user-confirmed in SameBoy.)
> **GFX-2 DONE — cross-bank sprite swap backbone + monster palette recolour.**
> (1) `dwm/sprite_bank.py` — cross-bank OVERFLOW allocator: places encoded streams in
> the reserved sprite banks (`$7E–$7F`, then `$7C/$7A/$79`; EDITOR_DESIGN §8) with a
> `$4001` pointer table, and `tools/build_sprite_swap.py` (rewritten) repoints the
> species→gfx-ID entry — works for ANY of 221 monsters regardless of which bank their
> art lives in (resolver reads `$<bank>:$4001+index*2`, NO bank gating; verified). This
> is the bulk-DWM2-import enabler (the old tool was battle-only, bank `$36` only,
> ~40/221). `--relocate` = lossless cross-bank copy (proof: Slime relocated renders
> identically, user-confirmed). (2) **Monster battle palette SOLVED** (was the GFX-2
> "semi-speculative" gap): the enemy renders as BG tiles on **BG palette slot 4**; the
> per-species colours live in **`MonsterBattlePalettes` @ `$17:$62FD`** (mgbdis-misnamed
> `RoomAttrDataBlocks`), 8 B/species `[c0, c1=$6bff backdrop, c2, c3=$0000 black]`,
> loaded by bank `$17` **entry 6** (`$1706`: `$c81e`=species×8+base, `$c81f`=slot).
> Found via SameBoy BG-slot-4 dump (Dracky `007b 6bff 2a97 0000`) + ROM grep; annotated
> in `bank_017.asm` (label `MonsterBattlePalettes` + loader doc, byte-perfect). Recolour
> = same-size 8-byte edit of one species' entry (Iron-Rule-2 safe; per-species, no
> bleed) via `build_sprite_swap.py --palette`. (3) Data: `tools/extract_monster_palettes.py`
> + `extracted/monster_palettes.json` (all 221); `extracted/monster_sprites.json`
> REGENERATED (all 221 — the shipped copy was a 3-monster subset, a data defect now
> fixed). USER-CONFIRMED in SameBoy: DWM2 clam→Dracky battle + correct purple palette;
> and a full integration ROM (clam + Dracky→Spirit family + custom room with random
> encounters + breeding/library all coexisting, no glitches). The swap touches only
> bank `$7e` (art) + 2 B in `$00` (repoint) + 1 entry in `$17` (palette) — orthogonal to
> breeding/library/custom-rooms/Spirit-family. Integrity PASS 4/4. NEXT: GFX-3 (follower
> /walking swap) — rides this backbone via `$01:$49DF` (needs re-section first) + its own
> palette table + the family-shared `$4bad` block. Method: KEY_LESSONS "Session 23";
> mechanics: MONSTER_DATA "Monster battle palette system".
>
> Last verified: 2026-06-20 (Session 22 — GFX-1: graphics system annotated +
> sprite codec/extraction/swap tooling; Dracky→Anteater swap user-confirmed in
> SameBoy as a mostly-red Anteater, i.e. correct shape in Dracky's palette.)
> **GFX-1 DONE — editor graphics asset layer + correct disassembly.** Three
> foundations landed: (1) the battle gfx-ID table `$00:$2B9F` was misassembled
> (fake instructions, 23 hallucinated labels cross-referenced from other banks);
> re-sectioned into a real labeled block `MonsterBattleGfxTable` via
> `tools/resection_battle_gfx_table.py` — anchored between real symbol-map label
> boundaries, exact ROM bytes emitted, all 23 cross-refs preserved, build still
> `1ca6579…`. (2) `dwm/sprite_codec.py` — the SINGLE LZ codec for tiles+sprites
> (decode byte-exact = game + existing tile decompressor; encode valid/compact;
> tile↔image); `decode(encode(x))==x` verified on all 442 monster streams.
> Deliberately NOT byte-identical re-encode of vanilla (no editor value). (3)
> `tools/extract_monster_sprites.py` + `extracted/monster_sprites.json` — all 221
> monsters' battle+follower sprites → manifest (count-parameterised, no 221 wall).
> `tools/build_sprite_swap.py` generalised to species-agnostic (PNG/payload/probe →
> encode → place → repoint); builds valid ROM. INTEGRITY PASS. KNOWN: all 221
> battle streams use shared-VRAM-pool back-refs → new art must encode self-contained
> (`--literal`) or reconstruct pool; swap tool's free-space placement currently
> knows bank `$36` only (cross-bank allocator = editor-backend follow-up). PALETTE
> LEAD for GFX-2 (user VRAM data): battle uses ONE shared OBJ palette slot (4); the
> per-species COLOURS are loaded into it at battle-init via `FuncFld_6942`/
> `SetGBCPalette` (bank `$07`, note `ld h,$04`). So recolour = edit the per-species
> colour table, NOT a slot assignment. Full mechanics in MONSTER_DATA.md "Monster
> sprite graphics system"; lesson in KEY_LESSONS "Session 22". Next: GFX-2 (palette
> recolour) or GFX-3 (follower swap, rides the codec).
>
> Last verified: 2026-06-19 (Session 21 — Monster battle-sprite swap POC:
> Dracky sp.78 → DWM2 "clam", proven rendering in SameBoy; in Dracky's native
> palette pending recolour.)
> **Monster sprite graphics system reverse-engineered + swap proven.** Every
> graphic = gfx-ID `(bank<<8)|index` → resolver `DecompressTileLayout` `$00:$1627`
> → per-bank pointer table `$<bank>:$4001+index*2` → LZ stream (3-byte header,
> back-refs into a SHARED VRAM tile pool). Battle path VERIFIED: `SetFld_466d`
> (bank `$07`) → table `$00:$2B9F`[species*2] → VRAM `$8B00`; Dracky = gfx-ID
> `$3627` (bank `$36`, 36 tiles). Swap method: self-contained literal stream (no
> runmark byte) repointed in bank `$36` free space — `tools/build_sprite_swap.py`,
> `patches/bank_036.asm`. Build stays `1ca6579…`; INTEGRITY PASS. Full mechanics
> in MONSTER_DATA.md "Monster sprite graphics system"; next jobs queued as ROADMAP
> **GFX-1** (annotate tile system), **GFX-2** (palette + recolour, semi-speculative),
> **GFX-3** (follower swap). Palette is a separate subsystem (bank `$17`, not yet pinned).
>
> Last verified: 2026-06-19 (Spirit B9 — family-10 VRAM corruption FIXED + icon
> finalized; user-confirmed in SameBoy. Built ON TOP of the gate-entry-freeze fix.)
> **B9 — 11th family "Spirit": VRAM corruption FIXED; icon shipped.** Catching a
> family-10 (Spirit) monster (Dracky sp.78 / DarkDrium sp.214) → party → map corrupted
> ALL of VRAM. Root cause: `bank_01:$49C0` indexes a **10-entry family-indexed GFX
> pointer table at `01:$4BAD`**; family=10 reads OOB → garbage source + garbage copy
> length → runaway copy over all VRAM (SameBoy watchpoint: BC=$2196 runaway, source
> $55fc, into $9864). Fix: 8-byte `ClampFamIdx::` in ROM0 end-of-bank padding (replaced
> 8 `rst $38` filler at $3BCB: `call ReadActiveMonsterByte / cp $0a / ret c / dec a /
> ret`, family≥10→9); `patches/bank_001.asm` routes ONLY the `$4BAD` lookup ($49C0)
> through it as a same-size `call` (Iron-Rule-2 OK, zero shift). The nearby `$499D`
> lookup is SPECIES-indexed into the 215-entry follower table `$49DF` (NOT family) —
> clamping it broke all follower sprites, so it is left alone. **Icon:** the Spirit
> whip (user-selected "option 5") ships on font byte **$19 (`$4F:$41A0`)**, overwriting
> the vanilla ??? glyph (??? + Spirit share it) — NOT the S20-planned free slot $1A
> (`$41B0`), which the menu blanks at runtime (not fill-immune). `extracted/family_icons.json`
> + `tools/build_family_icon.py --selftest` reconciled to the $19 art (icon rederivable
> from tracked data, no PNG). This whole feature sits ON TOP of the committed gate-entry-
> freeze fix: `ClampFamIdx` and `CustomGFXMapID` coexist in ROM0. Clean build still
> `1ca6579…`; integrity PASS. User-confirmed: no corruption, correct followers, library
> grouping good, family attribution correct. Method: KEY_LESSONS "Spirit B9 Lessons".
> **Doc correction:** any S20 text below stating the Spirit icon is on $1A is superseded
> by the $19 placement recorded here.
>

> Last verified: 2026-06-18 (Session 20: family-icon trace (B8/B9 "name" path) +
> Spirit icon insert. NOTE: the S20 "$1A slot / pending sign-off" claims below are
> SUPERSEDED by the 2026-06-19 block above — Spirit icon ships on $19, B9 confirmed.)
> **B8/B9 family-icon path TRACED + Spirit icon half-built (S20).** The long-blocked
> "family-NAME render path" is solved: the family identity is an **ICON font tile**,
> not a string. 10 icons live at `$4F:$4110-$41A0`, addressed by **text bytes
> `$10-$19`** via `ComputeTileDataAddr` (`$00`: `addr = $4010 + byte*16`); the
> monster-detail screen prints `<$F0><icon $1x>"family"` (bank `$4D`) and the
> library tab strip blits the same tiles. `FamilyTextPtrTable` (`$04:$60F4`) is
> confirmed a red herring (per-family monster **dialogue**, opcode `$2D`). User
> confirmed the medium ("symbols, not text") and the icon order (by visual, glyph
> order `$10-$19`: slime, dragon, paw, feather, tree, insect, hammer/axe, black face,
> red face, "?"). The free slot for an 11th icon is **byte `$1A` → `$4F:$41B0`**
> (blank filler; charmap "20-23 are blank"). **Spirit icon inserted** as a same-size
> 16-byte 2bpp tile there (`patches/bank_04f.asm`, user "Fire Whip Spirit" art, zero
> shift; bank `$4F` otherwise byte-identical to vanilla). Tool
> `tools/build_family_icon.py` + data `extracted/family_icons.json` (Variant A = head
> on palette index 0 → yellow head if the menu palette allows; Variant B = head on
> index 2 fallback; `--selftest` proves the JSON grid == the patch bytes). Disassembly
> annotated (comments only, byte-perfect `1ca6579…`): `bank_04f.asm` family-icon block
> + free-slot map. Verifier PASS 4/4 (`bank_04f.asm` added to the patch set). Test ROM
> `ab59c842…`; clean build still `1ca6579…`. **STILL OPEN (rest of B9):** the "yellow
> head" is a SameBoy palette question (menu BG pal via `LoadGBCPalettes`→`rst $10`
> `$17:$03`); wiring Spirit as family 11 (the `$4D` detail line, tab-strip 11th cell
> `LoadItem_4241` `b=5,c=10`, the `$FA` family-code wildcard, `NUM_FAMILIES`→11,
> reshuffle) is not done. The icon isn't referenced by any family yet → view via
> SameBoy VRAM viewer until wired. Method: KEY_LESSONS "Session 20 — Family icons";
> reference: BREEDING_SYSTEM "Family icons (B8/B9)".
>

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
| Monster battle palette table | `MonsterBattlePalettes` @ `$17:$62FD`, 8 B/species, 4 RGB555 `[c0, c1=$6bff, c2, c3=$0000]`; loaded by bank $17 entry 6 (`$1706`). Was mislabeled `RoomAttrDataBlocks`. |
| Monster sprite overflow banks | `$7E,$7F` (then `$7C,$7A,$79`) — cross-bank sprite streams (`dwm/sprite_bank.py`); EDITOR_DESIGN §8. Resolver reads `$<bank>:$4001+index*2`, no bank gating. |
| Follower gfx-ID table | `ScreenTransDataTable` @ `$01:$49DF`, 231 `dw`, indexed `species+$10`; loader `GetActiveMonsterStatus` @ `$01:$4986`; family table `FollowerFamilyGfxTable` @ `$01:$4BAD` (10). 16 tiles / 256 B per follower, DMA'd to VRAM `$8200`/`$8300`/`$8400` (party slot 0/1/2). **8 parallel copies of this gfx-ID table exist** (`$01 $06 $07 $09 $0b $12 $18 $59`, one per UI context: `$18`=menu/`TextDataPtrLookup`@`$4123` indexed `species`, `$12`=library); a complete art swap repoints ALL 8. |
| Follower layout dispatch (GFX-4) | Level-1 tables at FIXED `$10:$407f` (species 0–127) / `$11:$407f` (species 128+), indexed by species; `$ffc7=species+$10` routed by bank-`$04` entry 2 (`$10–$8F`→bank `$10`, `≥$90`→bank `$11`). Per-species attr/palette byte at `$10:$417f` / `$11:$412d` (bit6=Y-flip, bit5=X-flip, low3=OBJ palette). `[$caca]` = SPECIES (party +$09), not a "sprite-class" byte. Bank `$05` `$407f`-style table is the ObjTest viewer, NOT the follower path. `extracted/monster_follower_layouts.json`. |
| Follower render engine | `SaveScr_40cd` @ `$04:$40cd` (GBC variant of ROM0 `$0d91`). Metasprite list = 4-byte entries **(dy, dx, tile_offset, attr)**, `$80`-terminated; OAM tile = `tile_offset + [$ffc9]` (base `$20/$30/$40`); OAM attr = `[$ffca] XOR attr` (X-flip bit5). 2-level table: sprite-type `$ffc7`(=`[$ca91]`) → frame/dir `$ffc8`. **OBJ idx0 = hardware-transparent** (battle BG used idx1). 8 OBJ palettes @ `$17:$5615`. |
| Follower layout library | **155 distinct layouts** (complete; regenerated by `tools/extract_monster_follower_layouts.py` from the real `$10/$11:$407f` tables — the old 118-count brute-force scan dropped 3-entry small/blob layouts). Layout is per-species. Reassignment = same-size 2-byte repoint of the species' `$407f` level-1 entry (same-bank only), NOT a `[$caca]` edit. `extracted/follower_layouts.json`. |
| Custom layout bank | $64 (layout ptr table + LZSS layout + attr data, 309 bytes used) |
| Empty banks available | 21 banks = 336 KB: $67,$69–$77,$79–$7A,$7C,$7E–$7F |
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
| Add NEW monster species (ids 224–255) | 🟡 working POC (S30): id 224 Gorbunok playable | ROADMAP "Phase N"; mechanics MONSTER_DATA "Species ID geography". N1 scope ✅, N2 info-fork ✅ (`build_new_species.py`→`bank_06a`, `SaveMon_4446` zero-shift, vanilla 0–220 byte-identical), N3 enemy-stats ✅ (16-bit EID → no fork, EID 518 @ `$14:$7EB3`) + wild encounter ✅ (pool 0 slot 3, same-size `EncounterPoolData` edit in `bank_001`), name ✅ ("Gorbunok"), library ✅ (`build_library_table.py --new-species`, unseen-marker `$E0`→`$FE`). All tool-owned/reproducible. **S32 (user-tested):** N5 breeding DONE — Snaily×BattleRex→Gorbunok (special append, `build_breeding.py` admits new-species results), parent-path free via Slime family, recipe icons via `FamilyRecipeResolve`. Hatch crash (bank `$0b` follower overshoot, pinned in SameBoy) fixed (`FollowerArtResolve0b`). Default-nickname+narration "SkyBell" overshoot fixed → "Gorb" first-4 via `LoadModeBaseRedirect` ($00F0 ROM0 padding) → new-species short-name at `$41:$7FF9`. N4 follower ART integrated via `build_new_species_follower.py` (real W.png art, gid `$7e00`, all 8 contexts) — **baked into `patches/` (G1, S34).** **S35 (user-confirmed):** G2 battle sprite DONE — `MonsterBattleGfxTable[224]` `$320f`→`$7e01` (same-size repoint, real slot, no fork), dragon battle pose = 2nd overflow entry `$7e01`, palette reader `label17_41d0` forked to `HighBattlePal` (custom blue palette). **S38 (user-confirmed):** lineage parent-name DONE — line-1 mode-0 wired (`HighModeTable4D`→`HighMode0Ptrs`→`GorbunokRecipeLine` "Snaily   BattleRex", `patches/bank_04d.asm`), so the library/encyclopedia lineage no longer shows "?????". **Open:** `new_species.json` schema fold (G3) — now the only remaining new-species item. |
| Custom rooms (mapID ≥ $6B), multi-screen, exits | ✅ working | patches/bank_060.asm + intercepts. Multi-screen scrolling proven (v28): vertical 2-screen Room $6B (screens 0+4). Room dimensions in $26DD bytes 2-5 control walkable area. **S39: Room $6B can render the gate maze tileset** (gfx-ID `$280D`) with the gate floor palette — sandy island, tree/dune/pit metatiles; `tools/build_gate_room.py` → `bank_064.asm`. (GATE_GENERATION.md §7.2–7.3.) **S40 (Pillar A, user-confirmed in-game): custom-room RENDER is now fully table-driven by `mapID-$6B`** — no hardcoded `cp $6B` render intercepts remain. Two bank-`$17` tables (`CustomRoomPalPtr` = `dw` per room, `CustomRoomAttr` = `db bank,base_entry` per room) drive palette + attr; `CustomGFXMapID` widened `cp $6C`→`cp $70` so each of `$6B-$6F` indexes its **own** `$26DD` tileset/threshold record. Proven by a **second custom room `$6C`**: same gate-island layout/tileset/attr as `$6B`, distinct **moonlit-night palette**, entirely from the tables, zero new render code. System scales to ~140 rooms (`$6B-$FF` minus reserved; `$70+` needs a `$26DD` intercept — Pillar B follow-up). See GATE_GENERATION.md §7.4 + KEY_LESSONS S40. |
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

| Custom battle skill EFFECTS (net-new ids) | 🟡 S2-ARC in progress (S45 alias POC ✅ user-confirmed; S46 presentation foundation, byte-neutral, not yet tested) | **S2 is an ARC, not done.** (1) **Alias framework (S45, POC):** net-new ids ($DE Scorch, $DF Smite) on starter EID 1, templatized to Blaze at the action-queue commit; real id stashed in `$db86`; custom effect via `FarSkillFork` (bank `$72`) → `CustomSkillTable52` (`$52:$7FED`); names via `SkillNamePtrTable`. Single-caster, Blaze-shaped only. (2) **Presentation foundation (S46):** the skill RECORD table (`$54:$4013`→`$41CF`, 222×19B) decoded + round-tripped byte-identical + re-sectioned to `db`; field map FAQ-validated (power/targeting/MP/status/ai_weight); item-effect+meat system (`$52:$4625`, meat→`$58:$591E`); animation dispatch (descriptor-setters `$52:$5460–$54f8` → `$dd6f`/`$dd70` → bank `$4c`/`$55`). Handler=effect TYPE (shared), record=per-skill params. **Full RE + field tables + confidence + known limitations: `BATTLE_SKILL_SYSTEM.md` (read §⚠️ + §7–§10 before extending).** OPEN: effect-script bytecode format (animation authoring); proper per-id custom records to replace the alias hack. |

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
    BATTLE_SKILL_SYSTEM.md   QUEST_OPCODES.md CUSTOM_CUTSCENES.md SCRIPT_TOOLS.md
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
