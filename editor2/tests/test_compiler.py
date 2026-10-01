#!/usr/bin/env python3
"""test_compiler.py — sanity suite for the editor2 headless backend.

Run:  python3 editor2/tests/test_compiler.py           (fast: no ROM builds)
      python3 editor2/tests/test_compiler.py --rom     (adds the two ROM builds)

Fast tests: deterministic emit, schema hard-errors (NOT_IMPLEMENTED layers),
validator rules (spawn script, screen_byte, terminators, master compat,
step-counter region size, palette shape), text encoder round-trip shape.
--rom adds: regression byte-identity (compat project == S53 reference md5)
and the fixed build (delta confined to bank $60 + header checksums).
"""
import copy
import json
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)

from editor2.core import compiler as C
from editor2.core import validators as V
from editor2.core.project import Project, ProjectError

EXAMPLE = os.path.join(REPO, 'editor2/example-project/project.json')
REFERENCE_MD5 = "482c949ffabbce1ec409c4c9fb7e5f2e"   # S109 (P3.10b arena editor; built S109, NOT yet user-tested): arena team sizes — the last 6 bytes of bank $04 ReadArenaGroup ($5E0A) and bank $50 LoadArenaEnemyStats ($6760), `ld a,$01 / ld [$d7d1],a / ret`, became `ld hl,$6E00 / rst $10 / ret / nop`: new hand patch bank $6E ArenaTeamFixup (writes $D7D1 = 1, then $DA02 and the absent slots' display entries from ArenaTeamSizeTable, region gd_arena_team_sizes; all 3 = vanilla). The arena master tables ($04 / $50) and class fees ($09) are compiler regions gd_arena_masters_04 / _50 / gd_arena_fees (empty gamedata.arena = the same bytes). Diff vs the S107 pin (built in a HEAD worktree): exactly those two 6-byte sites + bank $6E $4000-$4059 + the header checksum. Prev: 77ccdab8a746fdc25fcad8d1239c84e4   # S107 (P3.10 part 2c, USER-CONFIRMED 2026-10-01 "Great, can confirm works"): the JOURNAL party line ($07 jr_007_6271) and its bank-$0A twin (jr_00a_5fd9) read the SAVED party member's family icon through bank $6D FamilyIconGfxFromE (same-size forks, 7 B + 6 nops each) — their unclamped 10-entry tables gave a saved Spirit member gfx id $CDE5 / $0A11 and the screen stopped (PyBoy S107); tables re-sectioned SavedPartyFamilyIconTable07 / 0A (both trees). Family icons are compiler regions gd_family_icons ($4F) / gd_family_icon_streams ($2E, new hand patch) / gd_spirit_icon_stream ($6D), empty = the same bytes. Prev: 9740c1c99f9eb11fd2d0edbf3d0a3066   # S107 (P3.10 part 2b, USER-CONFIRMED 2026-10-01 "Can confirm everything works correctly"): walking layouts for new species — bank $11 both follower entries `ld de, FollowerLayoutL1Table11` -> same-size `call FollowerLayoutBase11` (DE = NewFollowerL1Table - 2*$5D for ids 221+); NewAttrHandler no longer rewrites HRAM $C7 (the S105 donor index), NewFollowerAttrTable 1 B per id, new NewFollowerL1Table (ns_follower_layout, 19 dw; Gorbunok = $4184 as before, undeclared $0000); bank $10 / $11 zero tails = compiler regions lay_copies_10 / lay_copies_11 (empty = the same zeros). S107 2a changed no pinned byte. Prev: f22f56e116bc6b3f6b94e7d45a7e5f1e   # S105 G3 (USER-CONFIRMED 2026-09-30 ("Confirm all three appear as expected")): new-species CAPACITY 1 -> 19 (ids 221-239, any subset). The eight follower forks COMPUTE the gfx-ID $7E00+(id-221)*2 into WRAM wNewSpeciesGid ($D10A, carved from wCustomPool) instead of reading per-bank one-entry tables (their ns_follower_gfx_* regions are gone); every other fork gates on id >= 221 (info $03/$6A, NewAttrHandler $11, HighBattlePal $17 (19 x 8 B table), FamilyRecipeResolve $16 (19 x 2 B), HighDetailTextFork $4D (bases -$1BA), LoadModeBaseRedirect $00 (base $7D39)); bank-$01 follower clamp 240+ only; ROM0 battle gfx table re-sectioned $2D56-$2DA7 (19-word region); bank $41 names / nicknames PACKED into 5 free extents (ns_text_a-e) + the nickname pointer table $7EF3 (ns_short_ptr), and SpellUseText_11's tail $7E06-$7E15 restored to vanilla (B9 S28 had zeroed it); bank $7E pointer table 38 entries (Gorbunok 224 = index 6 / 7). The example still declares only Gorbunok (224). Prev: f8a714850b5318844e23b050a16f222e   # S105 (built, never user-tested — superseded in-session by G3): ROADMAP P3.9b purge of the POC CONTENT from the hand overlay. New species are project data (custom.species, editor2/core/species.py): the example re-expresses Gorbunok byte-identically through 17 ns_* regions + the compiler-owned bank $7E, except (a) its wild row moved from the bank-$14 EID-518 slot to project enemy 520 (bank $6B; pool 0 names it) and (b) the walking layout now comes from the donor index NewAttrHandler writes to HRAM $C7 (bank $11) instead of a pointer written at $11:$413F, which had overwritten ChopClown/Grendal's attr bytes (restored $02,$02). Purged: the S21 Dracky->Clam battle sprite (patches/bank_036.asm deleted), the S12 dead-table mirror (entries 693/803). Anchor's 4 dialog scripts + texts moved from the example's medal_vault room to the built-in skill_scripts.json (bank $60 SkillScriptPtrTable, script type $FF; template CustomScriptRead +9 B, re-pinned; bank $72 arms $FF, ids 2-5 unchanged). Prev: 15f21834385eb38e3650d434c622eda2   # S104 r5 (USER-CONFIRMED 2026-09-30 "perfect. Hand off."): library tab DISPLAY order — bank $12 LibTabToFamily / LibTabOrder (Spirit before ???; == gamedata.DISPLAY_ORDER) used by the tab-strip icons (SaveItem_6184 same-size call) and LibScanByFamily; 39 tail fill nops consumed. Prev: e994173e6086fd9f3cfe5095e3f9ba65   # S104 r4 (USER-CONFIRMED 2026-09-30 "Great that fixed it!"): bank $73 CF3SnapRestore restores the extended farm to $BCC7 only (93 chunks + CF3SnapTail4) — the snapshot's 28 lazy tile-image bytes $BCC8-$BCE3 hold the PREVIOUS save's top tile row (commit runs before SaveGameState's tile block); restoring them broke checksum v3 segment 3 when the last two saves were on different screens (user: save wiped on reset, glitchy top row). Prev: d7b762db217656f4432f115c25b39418   # S104 r3 (built; user: save wiped): bank $12 LibScanByFamily writes the library list to wMonList (was $C0D8; FX1 S71 had moved every bank-$12 reader to wMonList, so each tab listed the roster list and a lookup opened species = list index — user S104: the Spirit lookup froze). Prev: eb1535108cdbc9ac24d64dce3db5591e   # S104 r2 (built; user: Spirit library lookup froze): the Spirit icon = mock-up B "ghost wisp" (user pick) in $4F:$41B0 + the bank $6D SpiritIconStream (run marker $00); new compiler regions gd_family_voices (bank $6D FamilyTextPtrTable11) and gd_spirit_names (bank $41 dead fill) — empty gamedata == the r1 bytes. Prev: eee9f5b08b2f847291103961385099d9   # S104 r1 (built; test ROM user-passed except the Library door, which the user project redirects): ROADMAP P3.10a Spirit as the 11th family — new hand-authored bank $6D FAMILY SYSTEMS (FamilyIconGfxActive/FromE, FamilyTextGroupFromE, FamilyDefaultNameId, SpiritIconStream) behind same-size forks in banks $01/$0A/$04/$09; bank $16 family-scan $FA wildcard jr -> 2 nops ($FA = Spirit); bank $4F ??? glyph restored at $41A0, Spirit glyph at $41B0 (byte $1A); bank $41 mode-4 Spirit string "$1A", Spirit default names in the dead $4323 words + tail fill; bank $07 unknown-parent pedigree icon id 10 -> 11 (id 10 = Spirit since B9 drew the Spirit icon for unknown parents). No example project.json change. Prev: 5d1dbc5f50aa46717d662bdc83b3cad4   # S103 (USER-CONFIRMED 2026-09-30 "Rom - all correct"): ROADMAP P3.9 Layer A-lite — the vanilla data tables (MonsterInfoTable, EnemyStatsTable, EncounterPoolData, FamilyRecipeTable, bank $69 special table, Exp/StatGrowth curves (new patches/bank_013.asm), SkillLearnReq/MPCost/RecordData, bank $12 LibFamilyPtrTable, bank $4D library recipe text re-sectioned) are compiler-owned regions fed by `gamedata`; the example re-expresses the pre-S103 hand edits as gamedata (byte-identical) EXCEPT the library recipe text: its 4 B4 family-recipe slots (DrakSlime / GreatDrak / Almiraj / Wyvern) now show the recipes the table really has (coherence Set 1) — the only byte delta, 17 B in bank $4D + header. Prev: 0d60486e57edc2ad31fa28079d4fc9f8   # S102 (built, NOT yet user-tested): own tile animations — new compiler-owned bank $6C (template bank_06c_head.asm: CustomTileAnimate / TileAnimRestart / TileAnimCopy, empty TileAnimRoomTable in the example), bank $71 CustomAnimSource far-calls it first (+4 B), wram.asm carves wTileAnim* from wCustomPool. Prev: 9c81304176bd069ec77cd4c0d2211900   # S101 (built, NOT yet user-tested): ROADMAP P3.7b part 2 custom boss floors — bank $16 GateFloorDataTable is a compiler-owned region (custom.gates: floors 2-99, boss = custom room / vanilla:$xx, hand_made; the example has no custom.gates so the 256 B are vanilla); bank $14 LoadEnemyStats head -> LoadEnemyStatsExt (EID >= 519 -> new compiler-owned bank $6B CopyEnemyRowExt / ProjectEnemyRows, template bank_06b_head.asm pinned) and LookupBossRedirect -> BossRedirectTableExt (project join_as rows, then the vanilla 34) — the old bank-$14 tail enemy row (quest EID 519) moved to bank $6B; bank $60 CustomStateRules calls CustomMonsterCast first (per-screen monster NPC cast -> $D7CA; empty table in the example); bank $71 CustomRoomBGMResolve: the floor before a CUSTOM boss map plays that room's song (or $34). Example project.json: raw script op hex normalised to the new names (branch_screen/npc_write/...; bytes identical). Prev: 7cd7257b94004fdf8b406138dc7122e1   # S100 r3 (built, NOT yet user-tested): (1) stairs/special-room descent from a FREE-COLOUR custom room faded through the room's own colour 1 (user: "background is not CREAM but room-tile coloured") — bank $06 MapTrans_S10_InGate + MapTrans_S12 same-size rewrites far-call bank $73 new entries 19 GateWipeAttr (the 20x14 $E0 fill rows -> attr 7) and 20 GateLeaveFreePal (buffer+HW colour 1 := cream once the room is squeezed; the load fade targets buffer colour 1); vanilla + unmarked rooms early-ret (PyBoy: vanilla $50 pit transition = same pictures, single-scanline timing jitter only); (2) tools/compress_tiles.py MAX_COPY 256 (the game adds 19 in 8 bits: a 257-274 byte copy wrapped and shifted the rest of a sheet 256 B — an imported blank sheet drew as flat colour blocks) + decompress_tiles.py 8-bit like the game; the example sheet re-encodes (its old stream happened to decode right); (3) editor: "Stairs down here" paints the vanilla next-floor well ($51 slots $2C-$2F over the cell's floor). Prev: 91202c74fc9fc80dffc0e397d9d5e083   # S100 r2 (built, NOT yet user-tested): the example gate rule gains once_per_dive (user 14:39: gate_rotation could be floor 2 AND floor 3 of one dive; PyBoy 40 dives: floor 2 19x, floor 3 12x, never both). Prev: 4f13d2af8411c0b4387094221e9c2382   # S100 (built, NOT yet user-tested): ROADMAP P3.7b part 1 gate room insertion — bank $16 GateDecisionFork rewritten (the S41 hardcoded gate-1 -> $6D POC + CustomGate1Setup removed; push/pop BC around the far call because the vanilla special-room test after the fork divides B = wCurrentFloor) -> bank $71 entry 4 CustomGateInsert over the generated GateInsertTable (custom.gate_inserts[]: gate, floors, chance, flag terms, once-per-dive); entry 5 CustomRoomFlags + CustomRoomFlagsTable (can_save) read by the bank $07 save ladder same-size rewrite SaveAllowCheck (vanilla verdicts identical over all 256 mapIDs); entry 1 gate byte $FF = follow the dive (no pin); dive state wGateDiveGate/Mask $DEBC-D persisted via SRAM $BFCA-B in bank $73 entries 5/6; template 164 -> 395 B re-pinned; example project: gate_rotation served on Villager floors 2-3 at 50 % (was every floor), gate_arrival (4,6), stairs tag. PyBoy on the user save: gate-21 decisions identical to the S99 build (no rule = no RNG), floor 2/3 hit 19/40 each, floor 4 0/40, once-per-dive + flag rule + follow-gate encounters + gate/own music + JOURNAL allowed/refused + save-in-room/reload/descend. Prev: d072eb516dabc4799d830c170bbc9d9f   # S99 (built, NOT yet user-tested): ROADMAP P3.3e room tile animation — bank $01 PerRoomVRAMDispatch same-size rewrite (the six wGameState bit/ret-nz guards collapsed into `and $fe / cp $10`, proven equivalent over all 65,536 (wGameState, $C8EF) pairs; freed bytes fund: custom rooms ask bank $71 entry 3 CustomAnimSource for their animation source instead of `call MapIDClampForDispatch` = Castle for all); template bank_071_head.asm + entry 3 (head 142 -> 164 B, re-pinned); generated CustomAnimSrcTable (1 B/room); example project gains explicit `animation` (arena_clone source = $06 bare ret; the rest none) — so tiles 77/78 no longer roll in the example rooms. PyBoy: vanilla rooms frame-converge with the S98 build (sub-frame tile-load timing only), clones animate their source (test_canvas v6 --rom: VRAM == census schedule). Prev: ce24de8b708fe453711075dd0a3e07f8   # S97 round 2 (USER-CONFIRMED 2026-09-26; S98 changed no example/compiler-owned bytes — pin held): text boxes keep palette 7 (cream) in free-colour custom rooms — bank $06 dialog LoadMapS_6939 / state 9 / LoadMapS_6b3d same-size far calls to bank $73 entries 14-16 (row attrs saved to wBoxAttrSave, set to 7, restored cell by cell on close), bank $56 SetB56_48a1 + bank $00 ClearTextBitsRedraw same-size far calls to entries 18/17 for the YES/NO box; wram carves 132 B from wCustomPool. Vanilla + non-free rooms: pixel-identical dialog/choice frames (PyBoy). No example bytes change from the S97 r2 boxes text form (the example uses `lines`). Prev: 6e97fd377f50de47c98dcd665f515da7   # S97 round 1 (USER-CONFIRMED 2026-09-26): ROADMAP P3.5a state rules — bank $60 template entry 8 CustomStateRules (+ CustomReadStep calls it; head 383 -> 492 B, re-pinned) and bank $17 CustomAttrCheck calls StateRulesHook17 first (3 B from the ds-12 reserve -> ds 9; PyBoy-measured: the attr/palette walk reads the step counter BEFORE bank $0B Entry 0, so a rule evaluated only in Entry 0 loads the previous state's palette — A/B proven on the servant clone); generated CustomStateRulePtrTable in bank $60; the example project's S92 rank demo moved from the entry:medal_vault prelude to arena_clone.state_rules (flag $0030 -> screen 1 state 1; PyBoy: identical NPC sets flag clear/set, survives a wiped counter; vault entry script unchanged in behaviour). Also S97: the NPC type byte fields (behaviour/object) in the compiler — no example bytes change from them. Prev: 5db25d15af6298ca8be9e717a4a95b41   # S96 round 4 (USER-CONFIRMED 2026-09-25 ("Everything works"), SameBoy menu/battle): field-menu fix for free-colour rooms (user SameBoy report: washed-out room after closing the menu + colour-1 squares during the open wipe). FreeColor1Hook now keys on a PER-SLOT marker (bit 15 of colour 3 in slots 0-3, compiler-set for free_color1 palettes) and puts it back after the colour-3 pass, so the menu's standalone LoadPal_4102 no longer re-forces cream; bank $06 A-press menu-open tail rewritten same-size (4x `ld [hl+],a`) to far-call bank $73 entry 13 MenuOpenFreePal (hardware colour 1 := cream for marked slots during the tile-$E0 wipe; buffer untouched, menu-close push restores). Vanilla rooms: 619/620 menu frames pixel-identical to the round-3 build (1 mid-redraw text frame shifted by the far call's cycles). Prev: 07a71f202f011530ba7bb7d312666a97   # S96 (built, NOT yet user-tested): bank $17 FreeColor1Hook — LoadPal_4102's colour-1 pass (`ld a, [$c7d1]`) same-size -> jp FreeColor1Hook (bank tail, before room_render_tables): custom rooms whose loaded palette has bit 15 in slot 0 colour 3 (compiler marker for `free_color1` palettes) keep their own colour 1 in slots 0-3; slots 4-6 and every vanilla room unchanged. Example project has no free_color1 palette, so only the hook code moves bytes (room_render_tables shift, label-resolved). PyBoy: Pei import room BG palette RAM slots 0-3 == project (own colour 1), slots 4-7 $6BFF, GreatTree unchanged, holds after screen scroll. Prev: fc1caa987f5d4be1ad86ef7d4e87db20   # S94b (built, NOT yet user-tested): (1) vanilla-format per-(screen, STATE) attr+palette tables — bank $17 CustomAttrPtrTable -> RoomAttr_<mid> (16 dw) -> ScrAttr_<mid>_<k> (dw step counter; per state db attr_entry, attr_bank / dw pal_ptr) read by CustomAttrCheck/CustomPalCheck exactly like the vanilla AttrPtrTable walk (vanilla varies attr AND palette per step: Servant room $3F; clones carry ALL valid vanilla steps as states[] with per-state layout/attr/palette); (2) entrance redirects — custom.entrance_redirects[] lowered to per-(mapID, screen) VanillaExitExtTable rows (db mapID, screen; $FF = any) with every valid vanilla step rebuilt from extracted/map_table.json and only the named door re-pointed; template head 358 -> 383 (VanillaExitResolve keys on wScreenIndex), re-pinned; (3) bank $0B RoomEntry9 (boundary push exits) diverted through bank $60 entry 7 too (same-size rewrite, 5 nops) so y=0/7 extension rows are LIVE; (4) Exit_GreatTree_s8 restored to VANILLA bytes — the S92 Library-door repoint ($72) and the S1-era (4,5)->$6B entrance are now example-project DATA (entrance_redirects). PyBoy: Library door -> $72 scr 1 (14,7); (4,5) -> $6B (7,6); untouched GreatTree screen-12 door -> $0D; MedalMan south edge and OldManGate south edge identical to the original ROM; fresh-project Farm clone + redirect walk-through (test_canvas --rom). Prev: cdadf8346e207c248b151491e3ca2774   # S94 (built, NOT yet user-tested): per-SCREEN attr maps — CustomAttrCheck (patches/bank_017.asm) now reads CustomRoomAttr as dw per room -> 17-byte [bank, entry x16] map emitted by render17 (screens[k].attr > layout item attr > render.attr > $FF vanilla); the S42 base_entry+2 stride is retired (a 6-screen Farm clone PyBoy-verified: each screen its own attr, old rule mismatched 100+ tiles on screens 2/4/5/6). Also S94: ROM0 $26DD rows $6B-$6F are a compiler-owned @BUILD_PROJECT region in patches/bank_000.asm (rom0_records emitter; record required for EVERY room), 4x4 screen grid schema (keys 0-15, subtable width per row), extract_room emits screens[].attr, arena_clone screens 1/2 now carry their OWN attr items (attr_s1/attr_s2 — the faithful clone; under the old stride both showed attr_s2). Prev: df3219623203cf5bc272cb6155f07a01   # S92v5 (USER-CONFIRMED): rank state re-authored as visible-by-removal — rank G+ (flag $0030) removes the (7,6) $12 attendant; user-confirmed vanishing in-game. The v4 swap target $54 renders empty in field contexts (S91) — and that is VANILLA-FAITHFUL: user confirms the real lobby shows only 2 bunnies + 2 desks (the $54 entry is the desk talk-point). USER-CONFIRMED this session: Library-door entrance teleports to the clone; all 3 clone screens accessible on a normal save; postgame right-screen "crash" was a savestate issue, not the ROM. Prev S92v4: rank trigger corrected to EVENT FLAG $0030 (rank G cleared) — the S92v3 $D9CE ladder keyed a transient coliseum variable, not persistent rank (user-reported: G cleared, no state change). Both preludes (entry:medal_vault + arena_clone scr0) now if_flag_set $0030. PyBoy-verified on BOTH user saves: normal (flag 0 -> ctr 0 -> clerk) and postgame (flag 1 -> ctr 1 -> slime in buffer after a screen-seam cross; first-load NPCs predate the entry-script arming per the measured load-order rule, and a seam cross re-reads the screen state mid-visit — no re-entry needed). Postgame right-screen crash NOT reproduced headless (marker tile, NPC talk, north door all clean on the user postgame sav) — handed to user SameBoy debugging. Prev S92v3 (user-directed): GreatTree Library door REPOINTED to arena_clone $72 — in-place same-size byte edit in patches/bank_00b.asm at $0B:$4FE6 (05 03 12 00 04 05 07 -> 05 03 72 00 01 04 07; restore note at the site). NO injected triggers: the $12/$13 vanilla_exit_extensions rows are REMOVED (the v2 gate-room door was behind the 100-monster gate; main-Library injection is blocked by the map-wide replacement-list hazard, KEY_LESSONS S92). PyBoy-verified with real transitions both directions (Library south exit regressed; door -> clone (14,7) scr1; clone south -> GreatTree scr 4). Library itself unreachable while the repoint stands (testing stance, user-approved). Prev S92 pins: d5e052081890dd24137c0738aa240794 (v2 gate-room door), + Library Gate Room ($13) vanilla_exit_extensions row — Arena-clone door at (8,6), bottom-right corner (user-directed entrance; the well/vault chain was not the user's topology). Single sub-room = no cross-screen exit-replacement hazard (Library $12 itself is 2 screens sharing one replacement list — rejected for that reason, KEY_LESSONS S92). Both vanilla steps mirrored verbatim; return door PyBoy-regressed. Prev S92 pins: 9e5b592fd4b1150e1504d1be6b0c7c17 (prelude arming), + custom.script_preludes (entry:medal_vault arms arena_clone S1 rank state pre-transition; PyBoy-measured: state selection reads the counter at destination LOAD before its entry script) + rank demo re-authored as an in-budget NPC SWAP + placeholder zero 26DD rows. Interim S92 pin c3513d85283cac54778d0629f4537d6e (clone content, pre-prelude). S92 base: P3.2 [G-A] banks $64/$67 fold behind project.json + states[] backend [G-G] + P3.2b [G-J] clone extractor. Example project GAINS arena_clone ($72, vanilla Arena Lobby $06 clone via tools/extract_room.py, single-version per user decision, BGM $1E), island_copy ($73, custom->custom clone of gate_island), an authored medal_vault staircase layout+exit, and a 2-state rank demo on arena_clone screen1. The $64/$67 EMISSION is byte-identical to the prior hand-generated banks (proven via --expect-md5 a17bff8e67f3043fbff653c65128ea16 before clone content; the fold itself is zero-delta). NOT yet user-tested (built S92). Prev: a17bff8e67f3043fbff653c65128ea16 S85b: AI-committed Anchor $E4 rewritten to Attack in DispatchBoundsStub (prev S85 4c8de38a758eda5eb256d0af6f3be5b1: DispatchBoundsStub re-route $E5-$E8 -> $62BF (bank $58; AI-committed Tremor/Quake swept the party) + Anchor $E4 true no-op in CustomBattleExec (bank $72). Also absorbs the S84 pin move that was never recorded here: b99455d67012e2f451cd5ed96a5020a1 (S84: DispatchBoundsStub bounds guard for AI-committed ids > $E5, bank $58 $694F). Neither session touched compiler-owned banks; the pin is the whole-ROM regression. Prev: ce1e7369eb3876866e897c278510c3ae (S75v4: + LearnCode2Guard06 (bank $06: custom ids can never stat-learn via the code-2 path) + SlotProbeGuard50 (bank $50: level probe bounds slot index < $28; the stale-$cac0 phantom-slot-40 echo-RAM hazard) + builder-integrated validate_custom_data.py. Prev: 762c0df0e23611bce6c931813e976d0c (S75v2: banner-before-animation (user feedback: MournCountDead shared counter evaluated in the anim fork; banner render + $FE hold state precede the two slash plays; handler keeps only the multiplier; bank $72 only). Prev: a914e4896c3380b061d9bff8cfe509f6 (S75: + custom skill $E9 Mourn (ATK-vs-DEF x (dead allies+1) via the 2nd dispatch trampoline MournDispatch52; double EvilSlash replay; boost banner; banks $06/$07/$14/$41/$4c/$52/$53/$54/$56/$58/$5f/$72/wram -- BATTLE_SKILL_SYSTEM 13.8). This pin supersedes the S73b reference DIRECTLY: the S74 Earthquake bytes were never pinned here (S74 did not touch compiler-owned banks and did not run this chain), so the S74+S75 patched deltas both land in this one pin move. Prev: 224b11766b28de88cdb206c31145e286 (S73b: + skill descriptions for $E0-$E4 (bank $56 table $6667 repoints + 226 string bytes from tail pad) and battle field-only rejection for $E4 (bank $50 FieldOnlySkillA shared predicate: menu $0302 message without consuming the turn + usable-count exclusion; 12-byte mid-pad consumption, shift audit clean). Prev: 8fa605d795a7591871d5ad02058addfb (S73 Anchor reference patched build (custom skill $E4 Anchor: field-cast system RE'd — bank $07 usability whitelist in-place rewrite + Anchor07Post state-4 menu close; bank $14 entry-4 tail -> bank $72 AnchorField14Tail context classifier; script arm protocol ctr=$FFFF; GateAwareDispatch script-type branch (template re-pinned); medal_vault scripts 2-5 + dialogue $0A20-$0A23; bank $73 commit-hook arm 1/2/3 (anchor store / install+3/4-current-MP charge on arrival / GateDecisionFork force-standard); persistent wAnchorGate/Floor $D9D7-8 (flags $01E0-$01EF retired), transient $DEB2-3; PyBoy-verified full round trip via real menu UI both directions, MP 98->24, anchor single-use, error dialogs 4/5, NO paths, Heal/WarpWing/NPC regressions). Prev: 46ba69918c7ddfdfcd8a441d967debb6 (S71v2 FX1 reference patched build (exp-scale veto: drain pays FULL pending per eligible farm monster — vanilla per-monster rate; v1 halved it. USER-CONFIRMED v1 mechanics 2026-07-26: farm menus >17, sleep whole-swap, save/reload, breeding + hatches at scale, "everything works"; v2 delta = drain payout only, PyBoy-verified full 512 payout in both farm regions). Prev: 9c3af0d434f3d5bcd617677a42129778 (S71 FX1 reference patched build (farm expansion 17->37 active slots: array 40 slots (0-2 party, 3-19 farm @$A1FB+s*$95, 20-39 farm @$B124+(s-20)*$95 = the evicted sleep pool's bank-0 home; staging pseudo-slot INDICES 20/21 -> 40/41, addresses unchanged $D665/$D6FA); sleep pool -> SRAM bank 2 ($A010+c*$95, 40 slots, "P1" magic) via bank $73 entries 10-12; one-time F2 reformat gate $BFC8-9 in entry 4 (order load-bearing: legacy sums BEFORE F2 stamp, v3 after); checksum v3 = $A002x$1C5 + $AD9Fx$385 + $BCC8x$338; snapshot R4 dual-region ($A1BF x95 + $B124 x94 chunks); roster lists + canonicalizer map -> wMonList $D001 (C0D8 overflow at 40 slots); exp payout halved at drain (aggregate 37/32~=vanilla 17/16); PyBoy-verified: reformat preserves save, R3->R4 upgrade, 25-farm canonicalize/list/rewind/dual-snapshot/drain/battle). Prev: a5a5e0d5d01949b30bbff9d3253d9748 (S70v3 reference patched build (walk-on boundary exits for custom rooms: Entry 6 scan y=7 skip is data-driven via wCustomY7Cmp $DE74 (carved from the S65 legacy pad), armed fresh by bank $60 entry 7 before every scan - vanilla branch writes $07 (original skip semantics preserved), CustomExitCheck writes $FE (custom-room y=7 rows fire on arrival, PyBoy: 36 frames tap-to-transition, vanilla MedalMan door regression-checked push-only); template head 348->358, re-pinned). Prev: 22d30b66827628b9c8d9d400c48568a4 (S70v2 reference patched build (bug-fix pass, PyBoy-verified: init_dialog $07 protocol - every text outside an NPC interaction gets its own preceding init_dialog, auto-injected by quest lowering (field mode never services the text queue; dismissal tears script dialog mode down); emit_script hard-errors on non-terminated scripts (S70 freeze class); encounter seed 1200 (drain measured 100/step); bank $0B custom-source fast transition (in-place 19-byte window rewrite: exits FROM custom rooms take the town path, 18 frames vs the 385-frame gateworld-return ceremony, a day-one defect, not a regression); write_ram2 $13 opcode; Medal Chamber display strings). Prev: 6a6f4f8791cad0a271d210c7f485569c (S70v1 reference patched build (E2 wiring: progression.quests/enemies lowering -> quest:/entry: scripts + bank $14 tail row EID 519; vanilla_exit_extensions -> VanillaExitExtTable + template entry 7 VanillaExitResolve (re-pinned, head 348 B); bank $0B Entry 6 unified divert (-5 B); bank $01 $4C3E reverted to vanilla ld a,[wMapID] (entry scripts fire at initial entry); legacy compat key retired from the example project; room $71 Medal Vault + dwm2_bgm10). Prev: 94731e601af28503060acf3884348015 (S69v2 reference patched build (roster snapshot: bank-1 magic-gated save-time roster copy restoring vanilla reset-rewind semantics; entries 5/6 tail hooks + CF3SnapXfer/Commit/Restore + wSnapBounce $DE92). Prev: e719d286db0ff66e80755ec3ef1203e0 (S69v1 E3 pin (E3 SRAM 32 KB: 19 ROM0 quadrant-convention RAMB writes retargeted $4100->$6100 (MBC5-ignored), HeaderRAMSize $02->$03, bank $73 entry 9 CF3SRAMBankedCopy + wSRAMXfer* mailbox $DE8B-$DE91). Prev: de0c5a672e7e7e1fb834dd7afe70b9e7 (S65 reference patched build (WRAM migration: NPC/exit buffers -> $CC80/$CD00, step-counter region -> $CD80 (640 B) inside the CF3-freed window; $DE74 region -> static ds 7 pad, wRoomRecScratch stays $DE7B; + bank $73 entry 6 tail zeroes the window after the main-image restore copy). Prev: 7cc0857faad8a950573e865e93f791eb (S64 reference patched build (M3b+M3c: LoadNewBGMIdIntoA same-size rewrite -> bank $71 entry 2 CustomRoomBGMResolve + CustomRoomBGMTable; music emitter owns bank $74; dq6_town1 ids $A4-$A6 from MIDI; Library $12 + gate_island $6B room defaults). Prev: 3009b75ee1e3bd58bc315a39b7324e17 (S63v5 reference patched build (M3a v4 + v5: BGM #07 ids $A1-$A3 in bank $74, room $6C NPC via project.json; bank_060 now compiler-generated via --apply). Prev: c23beed7aadee80a061c0f6c24d7c1f4 (S63 v4, M3a: AudioMasterTableExt + song bank $74 + bank $1E reverted; S62's BGM NPC/set_bgm $9E folded into the example project — S62 had hand-edited bank_060 without updating project/pin, breaking compat==hand byte-identity; restored S63). Prev pins: 168c5f1b5b4b3b2568a6d6e2f3f1ab45 (S60), d31c9300e13b98f516c6bee8b446069d (S58v2)))

PASS = 0


def ok(name, cond, detail=""):
    global PASS
    if not cond:
        print(f"FAIL: {name} {detail}")
        sys.exit(1)
    PASS += 1
    print(f"  ok: {name}")


def base():
    return json.load(open(EXAMPLE))


def compile_data(data):
    tmp = '/tmp/_t_proj'
    os.makedirs(tmp, exist_ok=True)
    json.dump(data, open(os.path.join(tmp, 'project.json'), 'w'))
    # S92: project-relative assets (custom.tilesets raw2bpp sheets) travel
    # with the project — mirror the example project's assets/ into the tmp
    # copy so mutated fixtures still resolve them.
    src_assets = os.path.join(os.path.dirname(EXAMPLE), 'assets')
    if os.path.isdir(src_assets):
        import shutil
        shutil.copytree(src_assets, os.path.join(tmp, 'assets'),
                        dirs_exist_ok=True)
    return C.compile_project(tmp, REPO)


def expect_error(name, data, needle):
    try:
        compile_data(data)
    except (ProjectError, C.CompileError) as e:
        ok(name, needle in str(e), f"(got: {e})")
        return
    print(f"FAIL: {name} — expected error containing {needle!r}")
    sys.exit(1)


def _anim_fixture(items, room_id='gate_island', animation='none'):
    """S102: the example with one room drawing from the project tileset
    combined_room6b and carrying `tile_anims`."""
    d = base()
    r = next(x for x in d['custom']['rooms'] if x['id'] == room_id)
    rec = r['record']
    rec.pop('gfx_id', None)
    rec.pop('gfx_bank', None)
    rec['tileset'] = 'combined_room6b'
    r['animation'] = animation
    r['tile_anims'] = items
    return d


def test_tile_anims():
    """S102 own tile animations (PROJECT_COMPILER §2.19): emission, the
    engine record format, frames from the sheet, validators."""
    from editor2.core import tileanim as TA
    sheet = open(os.path.join(os.path.dirname(EXAMPLE), 'assets',
                              'combined_room6b.2bpp'), 'rb').read()
    b = (sheet[20 * 16:21 * 16][::-1]).hex()
    flip = {'id': 'f', 'name': 'Flip', 'motion': 'flip', 'speed': 20,
            'rows': [[20, 21]], 'frames': [[b, b]]}
    drift = {'id': 'd', 'name': 'Drift', 'motion': 'drift_right', 'speed': 8,
             'rows': [[30, 31, 32]], 'strip': True}
    sway = {'id': 's', 'name': 'Sway', 'motion': 'sway', 'speed': 32,
            'rows': [[40], [41]], 'strip': False, 'amplitude': 2}
    out, prj, warns = compile_data(_anim_fixture([flip, drift, sway]))
    t = out['patches/bank_06c.asm']
    ok("tile_anims: bank $6C lists the room (index 0) and ends its group list",
       'TILEANIM_ROOMS EQU 1' in t and 'dw TileAnimRoom_0' in t and '    db 0   ; end' in t)
    ok("tile_anims: group records = [speed, phase, steps, tiles] + seq + VRAM dests",
       '    db 20, ' in t and ', 2, 2   ; Flip' in t and '$9140, $9150' in t
       and ', 24, 3   ; Drift' in t and ', 8, 2   ; Sway' in t, t[-3000:])
    ok("tile_anims: frames live in a 16-aligned section of bank $6C",
       'SECTION "Bank $6C tile animation frames", ROMX, BANK[$6C], ALIGN[4]' in t)
    fr, seq = TA.steps(drift, sheet)
    ok("tile_anims: a 3-tile strip drift = 24 one-pixel steps, step 0 = the sheet",
       len(seq) == 24 and fr[0] == [sheet[s * 16:s * 16 + 16] for s in (30, 31, 32)])
    ok("tile_anims: rolling the strip 24 px returns to the start",
       TA.roll(fr[5], 19) == fr[0])
    fr2, seq2 = TA.steps(sway, sheet)
    ok("tile_anims: sway amplitude 2 = 0,1,2,1,0,-1,-2,-1 over 5 frames",
       TA.offsets(sway) == [0, 1, 2, 1, 0, -1, -2, -1] and len(fr2) == 5)
    ok("tile_anims: the example without tile_anims emits an empty table",
       'TILEANIM_ROOMS EQU 0' in out1_ex[0]['patches/bank_06c.asm'])
    ok("tile_anims: load estimate (3 tiles/8 f + 2/20 + 2/32 of 8 per frame)",
       abs(TA.load([flip, drift, sway])['pct'] - 100 * (2 / 20 + 3 / 8 + 2 / 32) / 8) < 1e-9)
    bad = dict(flip, speed=0)
    expect_error("tile_anims: speed 0 refused", _anim_fixture([bad]), 'speed must be 1-255')
    expect_error("tile_anims: one slot in two animations refused",
                 _anim_fixture([flip, dict(drift, id='d2', rows=[[21, 33]])]),
                 'already animated by Flip')
    expect_error("tile_anims: a strip wider than 4 tiles refused",
                 _anim_fixture([dict(drift, rows=[[30, 31, 32, 33, 34]])]), 'at most 4 tiles')
    expect_error("tile_anims: a flip without a second frame refused",
                 _anim_fixture([dict(flip, frames=[])]), 'at least one more frame')
    d = _anim_fixture([flip])
    r = next(x for x in d['custom']['rooms'] if x['id'] == 'gate_island')
    r['record'] = {'gfx_id': '0x0D', 'gfx_bank': '0x28', 'width_px': 160,
                   'height_px': 256, 'collision_threshold': '0x30'}
    expect_error("tile_anims: a room without its own tileset copy refused", d,
                 'own tileset copy')
    expect_error("tile_anims: a slot the copied vanilla animation moves is refused",
                 _anim_fixture([dict(flip, rows=[[77, 78]])], animation='0x00'),
                 'fight over it')


def test_crash_config_validator():
    """validate_custom_data must PASS on the current build and FAIL on a
    fence-stripped ROM (the S75 crash-capable configuration)."""
    import subprocess, shutil, tempfile, os
    rom = os.path.join('/tmp/_t_regression', 'build', 'rom.gbc')
    r = subprocess.run(['python3', 'tools/validate_custom_data.py', '--rom', rom],
                       capture_output=True, text=True, cwd=REPO)
    assert r.returncode == 0, f"validator must PASS on the built ROM: {r.stdout}"
    # strip the code-2 fence (restore vanilla pops at $06:$50B5) -> must FAIL
    data = bytearray(open(rom, 'rb').read())
    b06 = 0x06 * 0x4000
    data[b06 + 0x10B5:b06 + 0x10B8] = bytes([0xC1, 0xE1, 0xD1])
    with tempfile.NamedTemporaryFile(suffix='.gbc', delete=False) as tf:
        tf.write(bytes(data)); bad = tf.name
    try:
        r2 = subprocess.run(['python3', 'tools/validate_custom_data.py', '--rom', bad],
                            capture_output=True, text=True, cwd=REPO)
        assert r2.returncode != 0, "validator must FAIL when the code-2 fence is stripped"
        assert 'code-2 fence' in r2.stdout
    finally:
        os.unlink(bad)


# ---------------------------------------------------------------------------
# S103 (P3.9) Layer A-lite gamedata — PROJECT_COMPILER §2.20
# ---------------------------------------------------------------------------

GD_REGIONS = {   # gamedata_vanilla table -> (patch file, region name)
    'monster_info': ('patches/bank_003.asm', 'gd_monster_info'),
    'enemy_stats': ('patches/bank_014.asm', 'gd_enemy_stats'),
    'encounter_pools': ('patches/bank_001.asm', 'gd_encounter_pools'),
    'family_recipes': ('patches/bank_016.asm', 'gd_family_recipes'),
    'exp_curves': ('patches/bank_013.asm', 'gd_exp_curves'),
    'growth_curves': ('patches/bank_013.asm', 'gd_growth_curves'),
    'skill_learn': ('patches/bank_006.asm', 'gd_skill_learn'),
    'skill_mp': ('patches/bank_007.asm', 'gd_skill_mp'),
    'skill_records': ('patches/bank_054.asm', 'gd_skill_records'),
}


def region_text(out, fname, name):
    L = out[fname].split('\n')
    b = L.index(f"; @BUILD_PROJECT BEGIN {name}")
    e = L.index(f"; @BUILD_PROJECT END {name}")
    return L[b + 1:e]


def asm_bytes(lines):
    import re
    out = []
    for l in lines:
        s = l.split(';', 1)[0].strip()
        m = re.match(r'^(db|dw)\s+(.*)$', s)
        if not m:
            continue
        for x in m.group(2).split(','):
            x = x.strip()
            v = int(x[1:], 16) if x.startswith('$') else int(x, 0)
            out += [v & 0xFF] if m.group(1) == 'db' else [v & 0xFF, v >> 8]
    return bytes(out)


def gd_fixture(gd):
    d = base()
    d['gamedata'] = gd
    return d


def test_gamedata():
    from editor2.core import gamedata as G
    V0 = G.vanilla(REPO)
    vt = lambda n: b''.join(bytes.fromhex(r) for r in V0['tables'][n]['rows'])

    # (1) per-table regression: an EMPTY gamedata emits every table == vanilla
    out, prj, w = compile_data(gd_fixture({}))
    for tname, (fname, rname) in GD_REGIONS.items():
        ok(f"gamedata empty: {tname} region == the ROM table", 
           asm_bytes(region_text(out, fname, rname)) == vt(tname))
    sp = asm_bytes(region_text(out, 'patches/bank_069.asm', 'gd_special_recipes'))
    ok("gamedata empty: bank $69 special table == the 825 vanilla entries + $FF",
       sp == vt('special_recipes') + b'\xff')
    lib = asm_bytes(region_text(out, 'patches/bank_04d.asm', 'gd_library_text'))
    ok("gamedata empty: library recipe text block == ROM $4D:$43CE-$53D2",
       lib == bytes.fromhex(V0['library']['block']))
    ok("gamedata empty: redirect tail carries the 34 vanilla pairs",
       '    dw 11, 12' in out['patches/bank_014.asm'])
    grp = '\n'.join(region_text(out, 'patches/bank_012.asm', 'gd_library_grouping'))
    ok("gamedata empty: library tabs = vanilla id ranges (Dracky $4e in Bird)",
       'LibFamily_10:  ; 0 members' in grp and ', $4d, $4e, $4f' in grp)

    # (2) edits land at the right bytes
    gd = {
        'monsters': {'8': {'growth': {'hp': 31}, 'resist': {'Fire': 3}, 'skills': [1, 2, 3],
                           'level_cap': 50}},
        'enemies': {'2': {'hp': 999, 'atk': 77, 'skills': [0], 'exp': 500}},
        'encounters': {'0': {'slot_chance': [7, 0, 0, 0, 0]}},
        'skills': {'0': {'mp': 9, 'learn': {'level': 5, 'int': 30, 'prereqs': [1]},
                         'record': {'party_min': 40, 'party_range': 10}}},
        'exp_curves': {'0': {'2': 3}},
        'growth_curves': {'1': {'5': 9}},
        'breeding': {'family': {'8': {'p1': 'Bird', 'p2': 'Slime'}}},
        'boss_joins': {'11': 13},
    }
    out, prj, w = compile_data(gd_fixture(gd))
    mon = asm_bytes(region_text(out, 'patches/bank_003.asm', 'gd_monster_info'))
    r8 = mon[8 * 43:9 * 43]
    ok("monsters.8: level cap / skills / HP growth / Fire resist at +1 / +6 / +9 / +15",
       r8[1] == 50 and list(r8[6:9]) == [1, 2, 3] and r8[9] == 31 and r8[15] == 3)
    ok("monsters: untouched rows stay vanilla",
       mon[:8 * 43] == vt('monster_info')[:8 * 43] and mon[9 * 43:] == vt('monster_info')[9 * 43:])
    en = asm_bytes(region_text(out, 'patches/bank_014.asm', 'gd_enemy_stats'))[2 * 25:3 * 25]
    ok("enemies.2: exp / HP / ATK / skills (padded $FF)",
       en[1:3] == (500).to_bytes(2, 'little') and en[5:7] == (999).to_bytes(2, 'little')
       and en[9:11] == (77).to_bytes(2, 'little') and list(en[21:25]) == [0, 255, 255, 255])
    pool = asm_bytes(region_text(out, 'patches/bank_001.asm', 'gd_encounter_pools'))[:26]
    ok("encounters.0: slot chances", list(pool[5:10]) == [7, 0, 0, 0, 0])
    mp = asm_bytes(region_text(out, 'patches/bank_007.asm', 'gd_skill_mp'))
    ok("skills.0.mp", mp[0:2] == b'\x09\x00')
    ln = asm_bytes(region_text(out, 'patches/bank_006.asm', 'gd_skill_learn'))[:18]
    ok("skills.0.learn: level / INT / prereqs",
       ln[0] == 5 and ln[11:13] == (30).to_bytes(2, 'little') and list(ln[13:18]) == [1, 255, 255, 255, 255])
    rec = asm_bytes(region_text(out, 'patches/bank_054.asm', 'gd_skill_records'))[:19]
    ok("skills.0.record: party power pair at +11/+13",
       rec[11:13] == (40).to_bytes(2, 'little') and rec[13:15] == (10).to_bytes(2, 'little'))
    ok("skills.0.mp without mp_byte: warns (record +4 keeps the old byte)",
       any('mp_byte' in x for x in w))
    ex = asm_bytes(region_text(out, 'patches/bank_013.asm', 'gd_exp_curves'))
    ok("exp_curves.0 level 2 = 3 (u24 at +3)", ex[3:6] == b'\x03\x00\x00')
    gr = asm_bytes(region_text(out, 'patches/bank_013.asm', 'gd_growth_curves'))
    ok("growth_curves.1 level 5 = 9", gr[99 + 4] == 9)
    fam = asm_bytes(region_text(out, 'patches/bank_016.asm', 'gd_family_recipes'))
    ok("breeding.family.8 = [Bird, Slime] = $F3,$F0", fam[16:18] == b'\xf3\xf0')
    lib = asm_bytes(region_text(out, 'patches/bank_04d.asm', 'gd_library_text'))
    blk = bytes.fromhex(V0['library']['block'])
    ok("library text: Slime's string regenerated IN PLACE (same length, pointer unchanged)",
       len(lib) == len(blk) and lib[8 * 19:8 * 19 + 19] != blk[8 * 19:8 * 19 + 19]
       and lib[8 * 19] == 0x13 and lib[:8 * 19] == blk[:8 * 19] and lib[9 * 19:] == blk[9 * 19:])
    ok("boss_joins.11 -> 13 in the redirect tail", '    dw 11, 13' in out['patches/bank_014.asm'])

    # family move regroups the library tabs
    out, _, _ = compile_data(gd_fixture({'monsters': {'4': {'family': 3}}}))
    grp = '\n'.join(region_text(out, 'patches/bank_012.asm', 'gd_library_grouping'))
    ok("monsters.4.family = Bird: Snaily leaves the Slime tab and joins Bird",
       'LibFamily_00:  ; 20 members' in grp and 'LibFamily_03:  ; 21 members' in grp
       and ', $04, $46' in grp)

    # (3) validators
    expect_error("gamedata: unknown section", gd_fixture({'items': {}}), 'unknown key')
    expect_error("gamedata: unknown monster field",
                 gd_fixture({'monsters': {'1': {'speed': 3}}}), 'unknown key')
    expect_error("gamedata: growth curve index > 31 (would index code)",
                 gd_fixture({'monsters': {'1': {'growth': {'hp': 40}}}}), 'outside 0-31')
    expect_error("gamedata: family of a protected combat-only species",
                 gd_fixture({'monsters': {'216': {'family': 2}}}), 'protected')
    expect_error("gamedata: learn row for $DA (FieldStateDispatch code)",
                 gd_fixture({'skills': {'218': {'learn': {'level': 1}}}}), 'FieldStateDispatch')
    expect_error("gamedata: pool chances under 100 %",
                 gd_fixture({'encounters': {'0': {'slot_chance': [1, 1, 0, 0, 0]}}}), 'less than 100')
    expect_error("gamedata: EID 500 does not exist (487-517 are code)",
                 gd_fixture({'encounters': {'0': {'eids': [2, 4, 500, 0, 0]}}}), 'no such enemy row')
    expect_error("gamedata: a chance with no EID",
                 gd_fixture({'encounters': {'0': {'slot_chance': [3, 5, 2, 1, 0]}}}), 'no EID')
    expect_error("gamedata: a 2-monster pool no slot can follow = freeze (measured S103)",
                 gd_fixture({'encounters': {'0': {'size_chance': [0, 7, 0],
                                                  'max_count': [0, 1, 1, 1, 0]}}}),
                 'forever')
    expect_error("gamedata: 3 monsters with only 2 copies allowed",
                 gd_fixture({'encounters': {'0': {'size_chance': [0, 0, 7],
                                                  'max_count': [2, 1, 1, 1, 0]}}}),
                 'third draw')
    _o, _p, w = compile_data(gd_fixture({'encounters': {'0': {
        'size_chance': [0, 7, 0], 'max_count': [1, 1, 1, 1, 0]}}}))
    ok("gamedata: every slot 'alone' + a 2-monster chance is legal (always one)", True)
    expect_error("gamedata: boss_joins only for the 34 vanilla fights",
                 gd_fixture({'boss_joins': {'2': 3}}), 'not one of the 34')
    expect_error("gamedata: shadowed special append refused",
                 gd_fixture({'breeding': {'special': {'appends': [
                     {'p1': 0, 'p2': 27, 'min_plus': 0, 'result': 5, 'plus_mod': 0}]}}}),
                 'SHADOWED')
    expect_error("gamedata: 'AnyFamily' retired (S104: $FA = Spirit)",
                 gd_fixture({'breeding': {'family': {'8': {'p1': 'Slime', 'p2': 'AnyFamily'}}}}),
                 'retired')
    # S104 (P3.10a): Spirit = family 10 = breeding code $FA, by name everywhere
    out, _, w = compile_data(gd_fixture({
        'monsters': {'4': {'family': 'Spirit'}},
        'breeding': {'family': {'8': {'p1': 'Spirit', 'p2': 'Slime'}},
                     'special': {'appends': [{'p1': 'Spirit', 'p2': 'Spirit', 'min_plus': 0,
                                              'result': 'Snaily', 'plus_mod': 0}]}}}))
    inf = asm_bytes(region_text(out, 'patches/bank_003.asm', 'gd_monster_info'))
    ok("monsters.4.family = 'Spirit' -> family byte 10", inf[4 * 43] == 10)
    fam = asm_bytes(region_text(out, 'patches/bank_016.asm', 'gd_family_recipes'))
    ok("breeding.family.8 = [Spirit, Slime] = $FA,$F0 (pedigree side allowed)",
       fam[16:18] == b'\xfa\xf0')
    sp = asm_bytes(region_text(out, 'patches/bank_069.asm', 'gd_special_recipes'))
    ok("special append [Spirit x Spirit] -> Snaily (not shadowed: no $FA wildcard)",
       sp[-6:-1] == bytes([0xFA, 0xFA, 0x00, 0x04, 0x00]))
    lib = asm_bytes(region_text(out, 'patches/bank_04d.asm', 'gd_library_text'))
    ok("library text: a Spirit matcher prints <glyph $1A>family (the Spirit icon)",
       lib[8 * 19:8 * 19 + 7] == bytes([0x1A]) + bytes.fromhex('433e4a464956'))
    grp = '\n'.join(region_text(out, 'patches/bank_012.asm', 'gd_library_grouping'))
    ok("monsters.4 in Spirit: Snaily joins library tab 10",
       'LibFamily_10:  ; 1 members' in grp or 'LibFamily_10:  ; 1 member' in grp, grp[-300:])
    # S104 r2: families.<name>.dialogue / families.spirit.names (compiler regions)
    out, _, _ = compile_data(gd_fixture({}))
    vo = '\n'.join(region_text(out, 'patches/bank_06d.asm', 'gd_family_voices'))
    ok("families empty: voices = vanilla A B C B A C C A B D + Spirit D",
       [l.split()[1][-1] for l in vo.split('\n') if l.strip().startswith('dw ')] == list('ABCBACCABDD'))
    nm = asm_bytes(region_text(out, 'patches/bank_041.asm', 'gd_spirit_names'))
    ok("families empty: Spirit names WISP.. = 40 B (S105 G3: was a 55-B fill; its last "
       "15 B are new-species text extent ns_text_f)",
       len(nm) == 40 and nm[:5] == bytes([0x3A, 0x2C, 0x36, 0x33, 0xF0]))
    out, _, _ = compile_data(gd_fixture({'families': {
        'Spirit': {'dialogue': 'Slime', 'names': ['Boo', 'Wisp', 'A', 'BB', 'CCCC', 'dd', 'Ee', 'F']},
        'Bug': {'dialogue': 'D'}}}))
    vo = [l.split()[1][-1] for l in '\n'.join(region_text(out, 'patches/bank_06d.asm', 'gd_family_voices')).split('\n')
          if l.strip().startswith('dw ')]
    ok("families: Spirit talks like Slime (A), Bug gets voice D", vo[10] == 'A' and vo[5] == 'D')
    nm = asm_bytes(region_text(out, 'patches/bank_041.asm', 'gd_spirit_names'))
    ok("families.spirit.names: 'Boo' = $25 $4C $4C $F0 (upper $24+, lower $3E+), still 40 B",
       len(nm) == 40 and nm[:4] == bytes([0x25, 0x4C, 0x4C, 0xF0]))
    expect_error("families.spirit.names: 5 letters refused",
                 gd_fixture({'families': {'spirit': {'names': ['ABCDE'] + ['A'] * 7}}}), '1-4 letters')
    expect_error("families.spirit.names: must be 8",
                 gd_fixture({'families': {'spirit': {'names': ['A'] * 7}}}), 'list of 8')
    expect_error("families.slime.names: only Spirit has a name pool",
                 gd_fixture({'families': {'slime': {'names': ['A'] * 8}}}), 'only Spirit')
    expect_error("families.X.dialogue: bad voice refused",
                 gd_fixture({'families': {'spirit': {'dialogue': 'Q'}}}), 'unknown family')
    b12 = open(os.path.join(REPO, 'patches', 'bank_012.asm')).read()
    m12 = re.search(r'LibTabOrder:\s*\n\s*db ([0-9, ]+)', b12)
    ok("S104 r5: bank $12 LibTabOrder == gamedata.DISPLAY_ORDER (+ blank tabs 11-15)",
       m12 is not None and [int(x) for x in m12.group(1).split(',')] == G.DISPLAY_ORDER + [11, 12, 13, 14, 15])
    expect_error("monsters.N.family: unknown family name refused",
                 gd_fixture({'monsters': {'4': {'family': 'Ghost'}}}), 'unknown family')
    _o, _p, w = compile_data(gd_fixture({'enemies': {'11': {'species': 5}}}))
    ok("gamedata: species change warns (Set 3) and names the join row (Set 2)",
       any('Set 3' in x for x in w) and any('join row EID 12' in x for x in w), f"{w[-3:]}")
    _o, _p, w = compile_data(gd_fixture({'encounters': {'1': {'eids': [5, 5, 3, 14, 0]}}}))
    ok("gamedata: duplicate EID in a pool warns (S77)", any('two slots' in x for x in w))
    # the example re-expresses the pre-S103 hand edits
    ex = asm_bytes(region_text(out1_ex[0], 'patches/bank_003.asm', 'gd_monster_info'))
    ok("example gamedata: Dracky + Darkdrium in Spirit (B9)", ex[78 * 43] == 10 and ex[214 * 43] == 10)
    sp = asm_bytes(region_text(out1_ex[0], 'patches/bank_069.asm', 'gd_special_recipes'))
    ok("example gamedata: special table = 825 + 2 appends (Gorbunok last) + $FF",
       len(sp) == 827 * 5 + 1 and sp[-6:-1] == bytes([0x04, 0x2A, 0x00, 0xE0, 0x00]))


out1_ex = [None]


# ---------------------------------------------------------------------------
# S105 (ROADMAP P3.9b): new species = project data; custom skills' scripts
# ---------------------------------------------------------------------------
BLANK = os.path.join(REPO, 'editor2/templates/blank-project/project.json')

# every id-indexed ns_* region (19 rows, ids 221-239): (patch file, row size,
# the example's row for its one species Gorbunok (224, row 3) — the pre-S105
# hand data, re-addressed by S105 G3 — , the empty row = the original ROM's)
NS_ROWS = {
    'ns_battle_gfx': ('patches/bank_000.asm', 2, '077e', '0f32'),   # $7E index 7
    'ns_follower_attr': ('patches/bank_011.asm', 1, '02', '00'),     # S107 2b: 1 B (attr)
    'ns_battle_pal': ('patches/bank_017.asm', 8, '674dff6bff7f0000', '00' * 8),
    'ns_recipe_pair': ('patches/bank_016.asm', 2, '042a', '0000'),
    'ns_short_ptr': ('patches/bank_041.asm', 2, None, '0000'),
    'ns_info': ('patches/bank_06a.asm', 43,
                '002802020100151a330b04080d110b00000002020000000000000000000000000000000002020202020000',
                '00' * 43),
}
GORB_ROW = 224 - 221


def _data_lines(lines):
    return [l for l in lines if re.match(r'\s+(d[bw]\s+[$0-9]|ds\s)', l)]


def region_bytes(out, f, name):
    """db / dw (numeric) / ds N[, v] lines of a region -> bytes."""
    b = b''
    for l in region_text(out, f, name):
        t = l.split(';', 1)[0].strip()
        m = re.match(r'^ds\s+([^,]+)(?:,\s*(\S+))?$', t)
        if m:
            n = int(eval(m.group(1).replace('$', '0x')))
            v = int(m.group(2).replace('$', '0x'), 16) if m.group(2) else 0
            b += bytes([v]) * n
        elif re.match(r'^d[bw]\s+[$0-9]', t):
            b += asm_bytes([t])
        elif re.match(r'^dw\s+[A-Za-z_.]', t):
            b += b'\xee\xee'                  # a label word (placeholder)
    return b


def _species_fixture(ids_names):
    """The example project + extra species cloned from Gorbunok."""
    d = base()
    g = d['custom']['species'][0]
    for sid, name, short in ids_names:
        e = json.loads(json.dumps(g))
        e['id'], e['name'] = sid, name
        if short:
            e['short_name'] = short
        else:
            e.pop('short_name', None)
        e['battle']['palette'] = ['$%04X' % (sid * 3), '$6BFF', '$7FFF', '$0000']
        e['follower']['palette'] = sid % 8
        d['custom']['species'].append(e)
    return d


def test_species_and_skills():
    from editor2.core import species as SP
    # -- the example project: Gorbunok = its pre-S105 bytes at row 224-221
    out, prj, warns = compile_data(base())
    for name, (f, n, want, empty) in NS_ROWS.items():
        got = region_bytes(out, f, name)
        rows = [got[k * n:(k + 1) * n].hex() for k in range(19)]
        ok(f"example {name}: 19 rows of {n} B", len(got) == 19 * n, f"(got {len(got)})")
        if want is not None:
            ok(f"example {name}[224] == Gorbunok's bytes", rows[GORB_ROW] == want,
               f"(got {rows[GORB_ROW]})")
        ok(f"example {name}: undeclared ids keep the original bytes",
           all(r == empty for k, r in enumerate(rows) if k != GORB_ROW))
    ok("SP.CAPACITY_IDS = 221-239 (19)", SP.CAPACITY_IDS == tuple(range(221, 240)))
    dt = region_text(out, 'patches/bank_04d.asm', 'ns_detail_text')
    dtb = asm_bytes(_data_lines(dt))
    ok("example ns_detail_text: 19 line-2 words ([224] = Dracky's description — S108: "
       "the label MonsterDesc_078_Dracky = $60BC — the rest $53C4), 19 line-1 words, then "
       "the derived \"Snaily   BattleRex\" line",
       dtb[:36].hex() == 'c453' * 3 + 'c453' * 15 and
       'dw MonsterDesc_078_Dracky' in '\n'.join(dt) and
       'dw NewSpeciesRecipeLine_224' in '\n'.join(dt) and
       dtb.hex().endswith('364b3e464956626262253e51514942354255f0'))
    np_ = '\n'.join(region_text(out, 'patches/bank_041.asm', 'ns_name_ptr'))
    ok("example ns_name_ptr: [224] -> NsName_224, 221-223 -> Unused_220, "
       "225-239 -> Unused_225 (the vanilla words)",
       np_.count('dw NsName_224') == 1 and np_.count('Unused_220') == 3 and
       np_.count('Unused_225') == 15)
    ta = region_text(out, 'patches/bank_041.asm', 'ns_text_a')
    ok("example ns_text_a ($7E38, 23 B) = NsName_224 \"Gorbunok\"$F0 + "
       "NsShort_224 \"Gorb\"$F0 + 9 zero bytes",
       region_bytes(out, 'patches/bank_041.asm', 'ns_text_a').hex() ==
       '2a4c4f3f524b4c48f0' + '2a4c4f3ff0' + '00' * 9 and
       'NsName_224:' in ta and 'NsShort_224:' in ta)
    for reg, _a, n, orig in SP.TEXT_EXTENTS[1:]:
        ok(f"example {reg}: unused -> the original {n} bytes",
           region_bytes(out, 'patches/bank_041.asm', reg) == orig)
    sp_ = '\n'.join(region_text(out, 'patches/bank_041.asm', 'ns_short_ptr'))
    ok("example ns_short_ptr [224] -> NsShort_224", 'dw NsShort_224' in sp_)
    b7e = out['patches/bank_07e.asm']
    ok("example bank $7E: 38 pointers, index 6/7 = Gorbunok's follower/battle "
       "streams (259 + 579 B), the rest alias them",
       b7e.count('dw Follower_sp224') == 19 and b7e.count('dw Battle_sp224') == 19 and
       re.search(r'dw Follower_sp224\s+; index 6 ', b7e) is not None and
       re.search(r'dw Battle_sp224\s+; index 7 ', b7e) is not None and
       '(259 B)' in b7e and '(579 B)' in b7e)
    ok("example: the S30 EID-518 row is gone — Gorbunok is project enemy 520 "
       "and pool 0 names it",
       'dw 2, 4, 3, 520, 0' in out['patches/bank_001.asm'] and
       'ProjectEnemy_520:' in out['patches/bank_06b.asm'])
    # custom skills' scripts: every build, after the project's own texts
    ok("example: skill texts keep the S73 ids $0A20-$0A23 (appended after the "
       "project's 32 texts)",
       [prj._text_by_id[t]['id'] for t in range(0x0A20, 0x0A24)] ==
       ['skill:anchor_gate_ask', 'skill:anchor_return_ask',
        'skill:anchor_err_special', 'skill:anchor_err_none'])
    b60 = out['patches/bank_060.asm']
    ok("bank $60 SkillScriptPtrTable: ids 0/1 no-op, 2-5 = Anchor's scripts "
       "(the values bank $72 arms)",
       re.search(r'SkillScriptPtrTable:[^\n]*\n\s+dw SkillScrNoop[^\n]*\n\s+dw SkillScrNoop'
                 r'[^\n]*\n\s+dw SkillScr02[^\n]*skill:anchor_gate_confirm', b60) is not None
       and 'SkillScr05:' in b60)
    # -- G3 capacity: species at both ends of the range + one in the middle
    d = _species_fixture([(221, 'DrakSlime', None), (239, 'Abcdefghi', 'Zz'),
                          (230, 'Gorb', 'Gorb')])
    o3, p3, _ = compile_data(d)
    gfx = region_bytes(o3, 'patches/bank_000.asm', 'ns_battle_gfx')
    ok("G3: battle gfx-IDs [221] = $7E01, [230] = $7E13, [239] = $7E25",
       gfx[0:2].hex() == '017e' and gfx[18:20].hex() == '137e' and gfx[36:38].hex() == '257e')
    b7 = o3['patches/bank_07e.asm']
    ok("G3: bank $7E index 0 = Follower_sp221, 37 = Battle_sp239, 18 = Follower_sp230",
       re.search(r'dw Follower_sp221\s+; index 0 ', b7) is not None and
       re.search(r'dw Battle_sp239\s+; index 37 ', b7) is not None and
       re.search(r'dw Follower_sp230\s+; index 18 ', b7) is not None and
       b7.count('\n    dw ') == 38)
    at = region_bytes(o3, 'patches/bank_011.asm', 'ns_follower_attr')
    ok("G3: follower attr rows [221] / [239] carry their palettes",
       at[0] == 221 % 8 and at[18] == 239 % 8 and at[3] == 2 and len(at) == 19)
    lay3 = region_bytes(o3, 'patches/bank_011.asm', 'ns_follower_layout')
    ok("S107 2b: ns_follower_layout: 221 / 224 / 230 / 239 walk like 128 ($4184), the rest $0000",
       [lay3[2 * k:2 * k + 2].hex() for k in range(19)] ==
       ['8441' if k in (0, 3, 9, 18) else '0000' for k in range(19)])
    ex_lay = region_bytes(out, 'patches/bank_011.asm', 'ns_follower_layout')
    ok("S107 2b: example ns_follower_layout: [224] Gorbunok = $4184 (walks like 128), "
       "the rest $0000", ex_lay.hex() == '0000' * 3 + '8441' + '0000' * 15)
    info = region_bytes(o3, 'patches/bank_06a.asm', 'ns_info')
    ok("G3: info slots 0 / 3 / 9 / 18 filled, the rest zero",
       all((info[k * 43:(k + 1) * 43] != bytes(43)) == (k in (0, 3, 9, 18))
           for k in range(19)))
    np3 = '\n'.join(region_text(o3, 'patches/bank_041.asm', 'ns_name_ptr'))
    sp3 = '\n'.join(region_text(o3, 'patches/bank_041.asm', 'ns_short_ptr'))
    ok("G3: [230] 'Gorb' (name == its short name) shares one string; "
       "\"Gorb\" is also Gorbunok's short name -> one placed string for all three",
       'dw NsShort_224  ; [230]' in np3 and 'dw NsShort_224  ; [230]' in sp3 and
       'NsName_230:' not in o3['patches/bank_041.asm'])
    txt = ''.join('\n'.join(region_text(o3, 'patches/bank_041.asm', r)) + '\n'
                  for r, *_ in SP.TEXT_EXTENTS)
    ok("G3: the 9-letter names are placed whole (\"DrakSlime\"$F0, \"Abcdefghi\"$F0)",
       'NsName_221:' in txt and 'NsName_239:' in txt)
    ok("G3: [239] short \"Zz\" -> NsShort_239, [221] default short \"Drak\"",
       'NsShort_239' in sp3 and 'NsShort_221' in sp3)
    ok("G3: recipe display pairs: 221/230/239 have no special entry -> $FF,$FF",
       region_bytes(o3, 'patches/bank_016.asm', 'ns_recipe_pair').hex() ==
       'ffff' + '0000' * 2 + '042a' + '0000' * 5 + 'ffff' + '0000' * 8 + 'ffff')
    # -- a BLANK project (File > New project): original bytes + Anchor's scripts
    blank = json.load(open(BLANK))
    outb, prjb, wb = compile_data(blank)
    for name, (f, n, _w, empty) in NS_ROWS.items():
        got = region_bytes(outb, f, name)
        ok(f"blank {name} == the original ROM bytes (19 x {empty[:8]}..)",
           got.hex() == empty * 19, f"(got {got.hex()[:40]}..)")
    for reg, _a, n, orig in SP.TEXT_EXTENTS:
        ok(f"blank {reg} == the original {n} bytes",
           region_bytes(outb, 'patches/bank_041.asm', reg) == orig)
    npb = '\n'.join(region_text(outb, 'patches/bank_041.asm', 'ns_name_ptr'))
    ok("blank ns_name_ptr -> the vanilla words (Unused_220 x4, Unused_225 x15)",
       npb.count('Unused_220') == 4 and npb.count('Unused_225') == 15)
    ok("blank ns_detail_text = no data (the bank's zero pad)",
       asm_bytes(_data_lines(region_text(outb, 'patches/bank_04d.asm',
                                         'ns_detail_text'))) == b'')
    ok("blank bank $7E = an all-zero bank", 'ds $4000, $00' in outb['patches/bank_07e.asm']
       and 'dw ' not in outb['patches/bank_07e.asm'])
    ok("blank project: Anchor's 4 scripts + texts are in bank $60 ($0A00-$0A03)",
       'SkillScr05:' in outb['patches/bank_060.asm'] and
       [prjb._text_by_id[t]['id'] for t in range(0x0A00, 0x0A04)] ==
       ['skill:anchor_gate_ask', 'skill:anchor_return_ask',
        'skill:anchor_err_special', 'skill:anchor_err_none'])
    ok("blank project: no warning about the built-in skill texts",
       not any('skill:' in w for w in wb), f"({[w for w in wb if 'skill:' in w]})")
    ok("Project data is not mutated by the skill scripts (never saved back)",
       blank['custom']['dialogue'] == [] and blank['custom']['scripts'] == [])
    # -- validators
    d = base(); d['custom']['species'].append(dict(d['custom']['species'][0]))
    expect_error("custom.species: an id declared twice is refused", d, "already")
    for bad in (220, 240, 255):
        d = base(); d['custom']['species'][0]['id'] = bad
        expect_error(f"custom.species: id {bad} is outside 221-239", d, "221-239")
    d = _species_fixture([(i, 'Mon' + 'abcdefghijklmnopqrstu'[i - 221], None)
                          for i in range(221, 240) if i != 224] + [(221, 'Extra', None)])
    expect_error("custom.species: 20 species > capacity 19", d, "capacity 19")
    d = base(); d['custom']['species'][0]['name'] = 'Gorbunokxx'
    expect_error("custom.species: name 1-9 characters (S108: the shared name encoder)", d, "1-9 characters")
    L = 'abcdefghijklmnopqrstuvwxyz'
    d = _species_fixture([(i, 'Q' + L[i - 221] * 8, 'W' + L[i - 221] * 3)
                          for i in range(221, 240) if i != 224])
    d['custom']['species'][0]['name'] = 'Gorbunokz'
    expect_error("custom.species: 19 nine-letter names + 19 four-letter nicknames "
                 "(285 B) exceed the 267 B of bank-$41 text", d, "bank $41 text")
    d = _species_fixture([(i, 'Q' + L[i - 221] * 6, None)
                          for i in range(221, 240) if i != 224])
    expect_error("19 new Slimes: the Slime library tab would hold 39 > 32 members "
                 "(a validation error, not an emit exception)", d, "members > 32")
    fams = ['Dragon', 'Beast', 'Bird', 'Plant', 'Bug', 'Devil', 'Zombie', 'Material']
    for k, e in enumerate(d['custom']['species'][1:]):
        e['info']['family'] = fams[k % len(fams)]
    o4, _, _ = compile_data(d)
    ok("custom.species: 19 species with 7-letter names fit (typical case)",
       'NsName_239' in ''.join('\n'.join(region_text(o4, 'patches/bank_041.asm', r))
                               for r, *_ in SP.TEXT_EXTENTS))
    d = base(); d['custom']['species'][0]['follower']['walks_like'] = 20
    expect_error("custom.species: walks_like is a bank-$11 species 128-214", d, "walks_like")
    d = base(); d['custom']['species'][0]['battle']['art'] = \
        'assets/species/gorbunok_follower.bin'
    expect_error("custom.species: battle art must decode to 576 B (S75 class)", d,
                 "decodes to 256 bytes")
    d = base(); d['custom']['species'][0]['battle']['art'] = 'assets/species/nope.bin'
    expect_error("custom.species: missing art file", d, "cannot read")
    for sp in (221, 224):
        d = json.load(open(BLANK))
        d['progression']['enemies'] = [{'id': 'x', 'species': sp, 'level': 1}]
        expect_error(f"an enemy of an undeclared new species ({sp}) is refused", d,
                     "custom.species")
    d = json.load(open(BLANK)); d['custom']['scripts'] = [{'id': 'skill:mine', 'ops': [['end']]}]
    expect_error("'skill:' script ids are reserved", d, "reserved")
    d = base(); d['gamedata']['encounters']['0']['eids'][3] = 'nobody'
    expect_error("a pool slot naming no project enemy is refused", d, "no such enemy row")
    # -- derived recipe: no special entry producing 224 -> no-recipe pair + "?????"
    d = base()
    d['gamedata']['breeding']['special']['appends'] = [
        a for a in d['gamedata']['breeding']['special']['appends'] if a['result'] != 224]
    o2, _, _ = compile_data(d)
    ok("species with no breeding recipe: display pair $FF,$FF + the vanilla "
       "\"?????\" line $53C4",
       region_bytes(o2, 'patches/bank_016.asm', 'ns_recipe_pair')[6:8].hex() == 'ffff' and
       'dw $53C4   ; [224]' in '\n'.join(region_text(o2, 'patches/bank_04d.asm',
                                                   'ns_detail_text')))
    # -- S105 gamedata fix: a Spirit parent is family code $FA in the shadow checks
    d = base()
    d['gamedata']['monsters']['0'] = {'family': 'Spirit'}      # DrakSlime -> Spirit
    d['gamedata']['breeding']['special']['appends'] = [
        {'p1': 'Spirit', 'p2': 'Dragon', 'min_plus': 0, 'result': 'Healer', 'plus_mod': 0},
        {'p1': 'DrakSlime', 'p2': 'Dragon', 'min_plus': 0, 'result': 'Snaily', 'plus_mod': 0}]
    expect_error("a Spirit species' recipe shadowed by an earlier [Spirit x ...] "
                 "entry is caught (fam_code includes $FA, S105)", d, "SHADOWED")


class MiniSM83:
    """S105 G3: just enough SM83 to RUN the new-species forks from real ROM
    bytes (straight-line code, no calls): the tests below feed every species
    id through each fork and compare HL / the WRAM gid / HRAM with what the
    fork must return. An opcode outside this set raises (the forks changed)."""
    def __init__(self, rom, bank):
        self.rom, self.bank = rom, bank
        self.a = self.b = self.d = self.e = self.h = self.l = 0
        self.z = self.c = False
        self.ram = {}
        self.stack = []

    def rd(self, addr):
        if addr < 0x4000:
            return self.rom[addr]
        if addr < 0x8000:
            return self.rom[self.bank * 0x4000 + addr - 0x4000]
        return self.ram.get(addr, 0)

    def _cmp(self, v):
        r = self.a - v
        self.z, self.c = (r & 0xFF) == 0, r < 0
        return r & 0xFF

    def _add(self, v, carry=0):
        r = self.a + v + carry
        self.c, self.a = r > 0xFF, r & 0xFF
        self.z = self.a == 0

    def run(self, pc, limit=200):
        for _ in range(limit):
            op = self.rd(pc)
            n = self.rd(pc + 1)
            nn = n | self.rd(pc + 2) << 8
            e = n - 256 if n > 127 else n
            hl = self.h << 8 | self.l
            pc += 1
            if op == 0xC9: return
            elif op in (0xC0, 0xC8, 0xD0, 0xD8):
                if {0xC0: not self.z, 0xC8: self.z, 0xD0: not self.c, 0xD8: self.c}[op]:
                    return
            elif op == 0x7C: self.a = self.h
            elif op == 0x7D: self.a = self.l
            elif op == 0x7A: self.a = self.d
            elif op == 0x78: self.a = self.b
            elif op == 0x6F: self.l = self.a
            elif op == 0x67: self.h = self.a
            elif op == 0x47: self.b = self.a
            elif op == 0x5E: self.e = self.rd(hl)
            elif op == 0x56: self.d = self.rd(hl)
            elif op == 0x7E: self.a = self.rd(hl)
            elif op == 0x46: self.b = self.rd(hl)                 # S107 2b
            elif op == 0x80: self._add(self.b)                    # S109 arena
            elif op == 0x3D:
                self.a = (self.a - 1) & 0xFF; self.z = self.a == 0
            elif op == 0x36: self.ram[hl] = n; pc += 1
            elif op == 0xF5: self.stack.append((self.a, self.z, self.c))
            elif op == 0xF1: self.a, self.z, self.c = self.stack.pop()
            elif op == 0x2A:
                self.a = self.rd(hl); hl = (hl + 1) & 0xFFFF
                self.h, self.l = hl >> 8, hl & 0xFF
            elif op == 0x23:
                hl = (hl + 1) & 0xFFFF; self.h, self.l = hl >> 8, hl & 0xFF
            elif op == 0xB7: self.z, self.c = self.a == 0, False
            elif op == 0xB0: self.a |= self.b; self.z, self.c = self.a == 0, False
            elif op == 0xB6: self.a |= self.rd(hl); self.z, self.c = self.a == 0, False
            elif op == 0x85: self._add(self.l)
            elif op == 0x87: self._add(self.a)
            elif op == 0x8C: self._add(self.h, int(self.c))
            elif op == 0x19:
                r = hl + (self.d << 8 | self.e); self.c = r > 0xFFFF
                self.h, self.l = (r >> 8) & 0xFF, r & 0xFF
            elif op == 0xFE: self._cmp(n); pc += 1
            elif op == 0xD6: self.a = self._cmp(n); pc += 1
            elif op == 0xC6: self._add(n); pc += 1
            elif op == 0xCE: self._add(n, int(self.c)); pc += 1
            elif op == 0xE6: self.a &= n; self.z, self.c = self.a == 0, False; pc += 1
            elif op == 0x3E: self.a = n; pc += 1
            elif op == 0x16: self.d = n; pc += 1
            elif op == 0xF0: self.a = self.ram.get(0xFF00 | n, 0); pc += 1
            elif op == 0xE0: self.ram[0xFF00 | n] = self.a; pc += 1
            elif op == 0xEA: self.ram[nn] = self.a; pc += 2
            elif op == 0xFA: self.a = self.rd(nn); pc += 2
            elif op == 0x21: self.h, self.l = nn >> 8, nn & 0xFF; pc += 2
            elif op == 0x11: self.d, self.e = nn >> 8, nn & 0xFF; pc += 2
            elif op in (0x18, 0x20, 0x28, 0x30, 0x38):
                pc += 1
                take = {0x18: True, 0x20: not self.z, 0x28: self.z,
                        0x30: not self.c, 0x38: self.c}[op]
                if take:
                    pc += e
            else:
                raise ValueError(f"MiniSM83: opcode ${op:02X} at ${pc - 1:04X}")
        raise ValueError("MiniSM83: no ret")


def test_species_forks_rom(tag, rom, sym, declared):
    """Run every new-species fork of a built ROM over species 0-239."""
    def a(name):
        return sym[name][1]
    gid_at = a('wNewSpeciesGid')
    forks = [('01', 'ScreenTransDataTable', 16), ('06', 'MapNPCPosDataTable', 16),
             ('07', 'TileRefLookupTable', 16), ('09', 'FieldPtrLookupTable', 16),
             ('0b', 'SpritePtrTable_4974', 16), ('12', 'ItemSlotPtrTable', 16),
             ('18', 'TextDataPtrLookup', 0), ('59', 'SaveSlotPtrTable', 0)]
    for suf, table, plus in forks:
        bank = int(suf, 16)
        bad = []
        for sp in range(240):
            if plus and sp + plus > 255:
                continue                        # wraps (the router never sends it)
            cpu = MiniSM83(rom, bank)
            hl = (sp + plus) * 2
            cpu.h, cpu.l = hl >> 8, hl & 0xFF
            cpu.run(a(f'FollowerArtResolve{suf}'))
            got = cpu.h << 8 | cpu.l
            if sp < 221:
                if got != a(table) + hl:
                    bad.append(sp)
            elif got != gid_at or (cpu.ram.get(gid_at), cpu.ram.get(gid_at + 1)) != \
                    ((sp - 221) * 2, 0x7E):
                bad.append(sp)
        ok(f"ROM {tag}: FollowerArtResolve{suf} — ids 0-220 = the vanilla add-base, "
           "221-239 -> wNewSpeciesGid = $7E00+(id-221)*2", not bad, f"(wrong for {bad[:8]})")
    # battle palette + recipe pair + attr forks
    bad = []
    for sp in range(240):
        cpu = MiniSM83(rom, 0x17)
        hl = sp * 8
        cpu.h, cpu.l = hl >> 8, hl & 0xFF
        cpu.run(a('HighBattlePal'))
        want = a('RoomAttrDataBlocks') + hl if sp < 221 else a('NewBattlePalTable') + (sp - 221) * 8
        if (cpu.h << 8 | cpu.l) != want:
            bad.append(sp)
    ok(f"ROM {tag}: HighBattlePal — vanilla $62FD+id*8 below 221, NewBattlePalTable row above",
       not bad, f"({bad[:8]})")
    bad = []
    for sp in range(240):
        cpu = MiniSM83(rom, 0x16)
        cpu.h, cpu.l = (sp * 2) >> 8, (sp * 2) & 0xFF
        cpu.run(a('FamilyRecipeResolve'))
        want = a('FamilyRecipeTable') + sp * 2 if sp < 221 else a('NewRecipePairs') + (sp - 221) * 2
        if (cpu.h << 8 | cpu.l) != want:
            bad.append(sp)
    ok(f"ROM {tag}: FamilyRecipeResolve — FamilyRecipeTable below 221, NewRecipePairs above",
       not bad, f"({bad[:8]})")
    bad = []
    t11 = a('NewFollowerAttrTable')
    for sp in range(128, 240):
        cpu = MiniSM83(rom, 0x11)
        cpu.ram[0xFFC7] = sp - 0x80
        cpu.ram[0xFFCA] = 0x61                   # Y-flip + X-flip + palette 1 set
        cpu.run(a('NewAttrHandler'))
        ca, c7 = cpu.ram[0xFFCA], cpu.ram[0xFFC7]
        if sp < 221:
            ok_ = ca == 0x61 | cpu.rd(a('FollowerAttrTable11') + sp - 0x80) and c7 == sp - 0x80
        else:
            ok_ = ca == (0x61 & 0xB8) | cpu.rd(t11 + sp - 221) and c7 == sp - 0x80
        if not ok_:
            bad.append(sp)
    ok(f"ROM {tag}: NewAttrHandler — vanilla attr OR below 221; 221-239 clean attr from "
       "NewFollowerAttrTable (1 B / id, S107 2b), HRAM $C7 left alone", not bad, f"({bad[:8]})")
    # S107 2b: FollowerLayoutBase11 — the level-1 table each id's lookup uses
    bad = []
    l1n = a('NewFollowerL1Table')
    for sp in range(128, 240):
        cpu = MiniSM83(rom, 0x11)
        cpu.ram[0xFFC7] = sp - 0x80
        cpu.a, cpu.z, cpu.c = 0x5A, True, True
        cpu.run(a('FollowerLayoutBase11'))
        de = cpu.d << 8 | cpu.e
        row = de + 2 * (sp - 0x80)
        want = a('FollowerLayoutL1Table11') + 2 * (sp - 0x80) if sp < 221 else l1n + 2 * (sp - 221)
        if row != want or (cpu.a, cpu.z, cpu.c) != (0x5A, True, True):
            bad.append(sp)
    ok(f"ROM {tag}: FollowerLayoutBase11 — ids 128-220 read FollowerLayoutL1Table11, 221-239 "
       "their NewFollowerL1Table row; AF kept", not bad, f"({bad[:8]})")
    # LoadModeBaseRedirect: the mode-7 base $4739 -> $7D39 for ids >= 221 only
    bad = []
    for sp in range(256):
        for base in (0x4739, 0x4339):
            cpu = MiniSM83(rom, 0x41)
            cpu.ram[0xC823] = sp
            cpu.ram[0xC000], cpu.ram[0xC001] = base & 0xFF, base >> 8
            cpu.h, cpu.l = 0xC0, 0x00
            cpu.run(0x00F0)
            want = 0x7D39 if base == 0x4739 and sp >= 221 else base
            if (cpu.d << 8 | cpu.e) != want:
                bad.append((sp, hex(base)))
    ok(f"ROM {tag}: LoadModeBaseRedirect — only mode base $4739 with id >= 221 -> $7D39",
       not bad, f"({bad[:6]})")
    # the pointer tables the redirected lookups land on
    bk = rom[0x41 * 0x4000:0x42 * 0x4000]
    w = lambda ad: bk[ad - 0x4000] | bk[ad - 0x3FFF] << 8
    ok(f"ROM {tag}: bank $41 [221] of base $7D39 is NewSpeciesShortPtrs ($7EF3)",
       a('NewSpeciesShortPtrs') == 0x7D39 + 221 * 2)
    for sid, name in declared.items():
        nm = rom[0x41 * 0x4000 + w(0x4339 + sid * 2) - 0x4000:][:len(name) + 1]
        sh = rom[0x41 * 0x4000 + w(0x7D39 + sid * 2) - 0x4000:][:6]
        from editor2.core import species as SPm
        ok(f"ROM {tag}: [{sid}] name pointer -> \"{name}\"$F0, nickname pointer -> a "
           "$F0-terminated string",
           nm == SPm.name_bytes(name, 'x', 1, 9) + b'\xf0' and b'\xf0' in sh)
        g = rom[0x2B9F + sid * 2] | rom[0x2BA0 + sid * 2] << 8
        b7 = rom[0x7E * 0x4000:0x7F * 0x4000]
        k = (sid - 221) * 2
        fptr = b7[1 + 2 * k] | b7[2 + 2 * k] << 8
        bptr = b7[3 + 2 * k] | b7[4 + 2 * k] << 8
        ok(f"ROM {tag}: [{sid}] battle gfx-ID $7E{k + 1:02X}; bank $7E index {k}/{k + 1} "
           "-> its Follower_/Battle_ streams",
           g == 0x7E00 + k + 1 and fptr == a(f'Follower_sp{sid}') and bptr == a(f'Battle_sp{sid}'))


def test_monsters_s106():
    """S106 (ROADMAP P3.10 part 1): the LZ decoder fix, the sprite-sheet reader,
    the Monsters tab's model (sparse writes, new species), the sprite renderer."""
    import shutil
    import tempfile
    from dwm import sprite_codec as SC
    from editor2.core import sheet_import as SI
    from editor2.core import monsters as MM
    from editor2.core import sprite_render as SR
    from editor2.core.document import Document

    # --- decoder: an offset past the payload reads the 4 KB-wrapped pool and
    # then walks into the output (the game's per-byte re-check, $00:$15C6);
    # vanilla streams open with "$FFF, 96" = repeat the previous 2 bytes
    st = bytes([8, 0, 0xAA, 0xFF, 0xAA, 0xFF, 0xF3])     # literal FF, copy 7 from $FFF
    ok("S106 LZ: an offset past the payload wraps 4 KB down (below the destination = 0, then the output)",
       SC.decode(st) == bytes([0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00]),
       SC.decode(st).hex())
    st = bytes([0, 1, 0xAA, 0x11, 0xAA, 0x00, 0x0F, 0xED])     # ext length $ED -> 256
    ok("S106 LZ: extended copy length is 8-bit (0 = 256, like the game)",
       len(SC.decode(st)) == 256 and set(SC.decode(st)) == {0x11}, SC.decode(st)[:4].hex())
    ok("S106 LZ: encoder never asks for a copy the game truncates", SC.MAX_COPY == 0x100)
    import random
    rnd = random.Random(106)
    for k in range(20):
        pay = bytes(rnd.choice((0, 0xFF, rnd.randrange(256))) for _ in range(rnd.randrange(16, 700)))
        if SC.decode(SC.encode_safe(pay)) != pay:
            ok("S106 LZ: encode/decode round trip", False, f"case {k}")
    ok("S106 LZ: encode/decode round trip (20 random payloads)", True)

    # --- the sheet reader finds the proven S34 Gorbunok boxes on its sheet
    # (examples/follower_swap/W_bluedragon.png = the DWM2 water-family sheet)
    sheet = SI.Sheet(os.path.join(REPO, 'examples/follower_swap/W_bluedragon.png'))
    ok("S106 sheet: background = the sheet's key colour", sheet.bg == (255, 194, 14), str(sheet.bg))
    ents = SI.find_entries(sheet)
    ref = json.load(open(os.path.join(REPO, 'examples/follower_swap/gorbunok_frames.json')))['frames']
    hit = [e for e in ents if e['frames'] and e['frames']['DOWN-a']['x'] == 232
           and e['frames']['DOWN-a']['y'] == 8]
    ok("S106 sheet: 31 complete monsters found on the water sheet",
       sum(1 for e in ents if e['battle'] and e['frames']) == 31,
       str(sum(1 for e in ents if e['battle'] and e['frames'])))
    ok("S106 sheet: the blue dragon's four stored frames == the hand-picked S34 boxes",
       len(hit) == 1 and all(hit[0]['frames'][k] == ref[k] for k in SI.LAYOUT0_ORDER))
    bspec = json.load(open(os.path.join(REPO, 'examples/follower_swap/gorbunok_battle.json')))
    ok("S106 sheet: its battle box == the hand-picked S35 bbox",
       hit[0]['battle'] == bspec['bbox'], str(hit[0]['battle']))
    gor = SC.decode(open(os.path.join(REPO, 'editor2/example-project/assets/species/'
                                      'gorbunok_follower.bin'), 'rb').read())
    ok("S106 sheet: follower payload == Gorbunok's committed (in-game proven) art",
       SI.follower_payload(sheet, hit[0]['frames']) == gor)
    _cm, pal = SI.follower_colors(sheet, hit[0]['frames'])
    ok("S106 sheet: auto object palette == Gorbunok's (2, blue)", pal == 2, str(pal))
    bp = SI.battle_payload(sheet, hit[0]['battle'])
    _bm, bpal = SI.battle_colors(sheet, hit[0]['battle'])
    grid = SR.tiles_to_grid(bp, 6, 6)
    ok("S106 sheet: battle payload 576 B, backdrop (idx 1) everywhere outside the pose, "
       "pose standing 2 px above the bottom like the original poses, c1 = $6BFF / c3 = $0000",
       len(bp) == 576 and all(v == 1 for v in grid[0]) and any(v != 1 for v in grid[45])
       and all(v == 1 for v in grid[46] + grid[47])
       and bpal[1] == 0x6BFF and bpal[3] == 0)
    bm, _ = SI.battle_colors(sheet, hit[0]['battle'])
    ok("S106 r2 sheet: a 4-colour pose (black, white, 2 blues) keeps all four — white "
       "on the cream (idx 1), the blues exact on c0 / c2 (user: Goldhorn lost its whites)",
       sorted(bm.values()) == [0, 1, 2, 3] and bm[(248, 248, 248)] == 1 and bm[(0, 0, 0)] == 3
       and {bpal[0], bpal[2]} == {SI.rgb555((56, 88, 152)), SI.rgb555((128, 136, 224))},
       f"{bm} {[hex(x) for x in bpal]}")
    ok("S106 sheet: a literal stream decodes back exactly",
       SC.decode(SI.literal_stream(bp)) == bp)

    # --- renderer: vanilla walking frames == the S101 PyBoy census crops
    cen = json.load(open(os.path.join(REPO, 'extracted', 'monster_npc_sprites.json')))
    from PIL import Image
    good, bad = 0, []
    for sid in range(215):
        if sid in cen.get('blank', []) or str(sid) not in cen['species']:
            continue
        fr = SR.vanilla_follower(sid)
        im = Image.open(os.path.join(REPO, 'extracted', 'monster_npc_sprites',
                                     cen['species'][str(sid)]['file'])).convert('RGBA')
        theirs = [(x, y, im.getpixel((x, y))[:3]) for y in range(16) for x in range(16)
                  if im.getpixel((x, y))[3]]
        match = False
        for name in ('down_A', 'down_B'):
            g = fr[name]
            mine = {(x, y, g[y][x][:3]) for y in range(24) for x in range(24) if g[y][x]}
            if mine and theirs:
                mx, my = min(p[0] for p in mine), min(p[1] for p in mine)
                tx, ty = min(p[0] for p in theirs), min(p[1] for p in theirs)
                if {(x - tx + mx, y - ty + my, c) for x, y, c in theirs} == mine:
                    match = True
        good += match
        if not match:
            bad.append(sid)
    ok("S106 render: walking frame == the PyBoy census for every species but ChopClown / "
       "Grendal (146 / 147: the census build had their attrs overwritten — S105)",
       bad == [146, 147], str(bad))

    # --- the model: sparse writes, spelling kept, refusals, new species
    tmp = tempfile.mkdtemp()
    shutil.copytree(os.path.dirname(EXAMPLE), os.path.join(tmp, 'p'))
    d = Document(os.path.join(tmp, 'p', 'project.json'))
    d.set_species_fields(8, {'level_cap': 60, 'resist.Fire': 3, 'growth.hp': 5})
    ok("S106 model: species edit -> only the changed fields in gamedata.monsters",
       d.data['gamedata']['monsters']['8'] == {'level_cap': 60, 'growth': {'hp': 5},
                                               'resist': {'Fire': 3}},
       str(d.data['gamedata']['monsters']['8']))
    b = d.species_base_row(8)
    d.set_species_fields(8, {'level_cap': b[1], 'resist.Fire': b[15], 'growth.hp': b[9]})
    ok("S106 model: setting the original values back removes the entry",
       '8' not in d.data['gamedata']['monsters'])
    d.set_species_fields(78, {'tier': 5})
    ok("S106 model: an unchanged family keeps the project's spelling (10, not 'Spirit')",
       d.data['gamedata']['monsters']['78'] == {'family': 10, 'tier': 5},
       str(d.data['gamedata']['monsters']['78']))
    try:
        d.set_species_fields(216, {'family': 0})
        ok("S106 model: a combat-only species' family is refused", False)
    except Exception as ex:                                       # noqa: BLE001
        ok("S106 model: a combat-only species' family is refused", 'protected' in str(ex))
    d.set_enemy_fields(2, {'hp': 99, 'ai_weights': [1, 2, 3, 4]})
    ok("S106 model: enemy row edit -> sparse gamedata.enemies",
       d.data['gamedata']['enemies']['2'] == {'hp': 99, 'ai_weights': [1, 2, 3, 4]})
    rows = {e['eid']: e for e in d.species_enemies(8)}
    ok("S106 model: Slime's rows include the starter, the edited wild row with its pools",
       1 in rows and rows[2]['edited'] and rows[2]['fields']['hp'] == 99
       and any('Gate of Beginning' in w for w in rows[2]['where']))
    from editor2.core import gamedata as GD
    v2 = MM.decode_enemy(GD._rows(GD.vanilla(REPO), 'enemy_stats')[2])
    d.set_enemy_fields(2, {'hp': v2['hp'], 'ai_weights': v2['ai_weights']})
    ok("S106 model: an enemy row set back disappears", '2' not in d.data['gamedata']['enemies'])
    pe = d.species_enemies(224)
    ok("S106 model: a new species' project enemy is listed with its pool",
       len(pe) == 1 and pe[0]['kind'] == 'project' and pe[0]['eid'] == 520
       and any('Gate of Beginning' in w for w in pe[0]['where']), str(pe))
    art = {'battle': SI.literal_stream(bp), 'battle_palette': bpal,
           'follower': SI.literal_stream(gor), 'follower_palette': 2, 'walks_like': 128}
    files = d.add_species(229, 'Tester', 'Tst', 28, 1, art,
                          source={'sheet': 'assets/sheets/x.png', 'battle': hit[0]['battle'],
                                  'frames': hit[0]['frames']})
    e = d.new_species(229)
    ok("S106 model: add_species writes the two streams + a valid custom.species entry",
       all(os.path.exists(os.path.join(d.project_dir, f)) for f in files)
       and e['info'] == {'clone_from': 28} and e['follower']['palette'] == 2
       and e['source']['sheet'] == 'assets/sheets/x.png')
    out, _p, _w = C.compile_project(_save_tmp(d), REPO)
    ok("S106 model: the project with the sheet species compiles (bank $7E holds it)",
       'Follower_sp229' in out['patches/bank_07e.asm'])
    d.set_species_fields(229, {'family': 'Bird', 'level_cap': 70})
    ok("S106 model: a new species' edits are stored against its clone_from row",
       d.new_species(229)['info'] == {'clone_from': 28, 'family': 'Bird', 'level_cap': 70},
       str(d.new_species(229)['info']))
    cat = {s['id']: s for s in d.species_catalog()}
    ok("S106 model: the catalog = 221 original + the project's species, families applied",
       len(cat) == 223 and cat[229]['family'] == 3 and cat[78]['family'] == 10)
    cap = d.species_capacity()
    ok("S106 model: capacity meters (2 / 19 slots, names and art counted)",
       cap['slots'] == (2, 19) and cap['art'][0] == 838 + len(art['battle']) + len(art['follower']))
    # S106 r3: the "Put in a gate" path (user: "either signpost or implement")
    nid = d.new_enemy_for_species(229)
    ne = d.project_enemy(nid)
    ok("S106 r3 model: a new enemy row of a new species (copy of the wild Slime, species set)",
       ne['species'] == 229 and ne['level'] == 1, str(ne))
    van = d.pool_slots(0)
    sl = [(x['ref'], x['chance'], x['max']) for x in van['slots']]
    sl[4] = (nid, 2, 1)                       # 20 %
    sl[3] = (sl[3][0], 5, 1)                  # Gorbunok 70 % -> 50 %: total 10+10+10+50+20
    d.set_pool_slots(0, sl)
    enc = d.data['gamedata']['encounters']['0']
    ok("S106 r3 model: set_pool_slots stores the project enemy by id, sparse vs the original",
       enc['eids'][4] == nid and enc['slot_chance'] == [1, 1, 1, 5, 2]
       and '_comment' in d.data['gamedata']['encounters'],
       str(enc))
    ok("S106 r3 model: the new row's 'where' names the gate",
       any('Gate of Beginning' in w for e in d.species_enemies(229) for w in e['where']))
    try:
        sl[4] = (nid, 0, 1)
        d.set_pool_slots(0, sl)
        ok("S106 r3 model: a list under 100 % is refused", False)
    except Exception as ex:                                       # noqa: BLE001
        ok("S106 r3 model: a list under 100 % is refused (the compiler's own check)",
           'less than 100' in str(ex) and d.data['gamedata']['encounters']['0']['eids'][4] == nid)
    from editor2.core import gamedata as GD2
    gw = GD2.Gamedata({'encounters': {'1': {'slot_chance': [4, 4, 3, 0, 0]}}}, REPO)
    ok("S106 r3 gamedata: a list over 100 % warns (the last slots are cut; every original "
       "list is exactly 100)", any('cut' in w for w in gw.warnings), str(gw.warnings))
    vr = [(x['ref'], x['chance'], x['max']) for x in van['slots']]
    d.set_pool_slots(0, vr)
    ok("S106 r3 model: putting the list back leaves only the project's own changes",
       'eids' in d.data['gamedata']['encounters']['0'])          # the example's Gorbunok edit stays
    d.data['progression']['enemies'] = [e for e in d.data['progression']['enemies'] if e['id'] != nid]
    ok("S106 model: removing a species used by an enemy is refused",
       d.species_references(224) != [])
    d.remove_species(229)
    ok("S106 model: removing an unused species frees its id",
       229 in d.free_species_ids() and all(s['id'] != 229 for s in d.data['custom']['species']))
    shutil.rmtree(tmp)


ART_TMP = '/tmp/_t_art_proj'


def _art_fixture(entries, files=None):
    """The example project + gamedata.art `entries`; `files` = {rel: bytes}
    written under the compile tmp dir (compile_data copies the example's
    assets/ there, so the art files go next to them)."""
    d = base()
    d.setdefault('gamedata', {})['art'] = entries
    for rel, b in (files or {}).items():
        p = os.path.join('/tmp/_t_proj', rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, 'wb').write(b)
    return d


def test_art_s107():
    """S107 (ROADMAP P3.10 part 2a): new art for the ORIGINAL monsters —
    gamedata.art -> the battle gfx / battle palette / 8 walking tables / bank
    $10-$11 layout + attr regions and the art banks $7F/$7C/$7A."""
    from editor2.core import art as A
    from editor2.core import gamedata as G
    from editor2.core import sheet_import as SI
    V0 = G.vanilla(REPO)
    vt = lambda n: [bytes.fromhex(r) for r in V0['tables'][n]['rows']]
    out, _, _ = compile_data(base())
    # -- empty art: every region == the original rows, every art bank zero
    ok("S107 art: empty -> battle gfx [0]-[214] == ROM",
       region_bytes(out, 'patches/bank_000.asm', 'art_battle_gfx') == b''.join(vt('battle_gfx')[:215]))
    ok("S107 art: empty -> battle palettes [0]-[214] == ROM",
       region_bytes(out, 'patches/bank_017.asm', 'art_battle_pal') == b''.join(vt('battle_palettes')[:215]))
    for name, path, bank in A.WALK_COPIES:
        ok(f"S107 art: empty -> walking gfx copy ${bank:02X} [0]-[214] == ROM",
           region_bytes(out, path, name) == b''.join(vt('follower_gfx')))
    for b in (0x10, 0x11):
        f = f'patches/bank_0{b:02x}.asm'
        ok(f"S107 art: empty -> bank ${b:02X} layout + attr tables == ROM",
           region_bytes(out, f, f'art_layout_{b:02x}') == b''.join(vt(f'follower_layout_{b:02x}'))
           and region_bytes(out, f, f'art_attr_{b:02x}') == b''.join(vt(f'follower_attr_{b:02x}')))
    for b in A.ART_BANKS:
        ok(f"S107 art: empty -> art bank ${b:02X} is `ds $4000, $00`",
           'ds $4000, $00' in out[f'patches/bank_0{b:02x}.asm'])
    # -- the in-region anchor labels are emitted and exist in the clean tree
    import glob as _g
    clean = {}
    for p in _g.glob(os.path.join(REPO, 'disassembly', 'bank_0*.asm')):
        for l in open(p):
            m = re.match(r'^(\w+):', l)
            if m:
                clean[m.group(1)] = True
    files = {name: path for name, path, _f, _b in A.REGIONS}
    miss = [(r, lb) for r, offs in A.ANCHORS.items() for v in offs.values() for lb in v
            if f'{lb}:' not in '\n'.join(region_text(out, files[r], r)) or lb not in clean]
    ok("S107 art: every in-region anchor label is emitted and defined in the clean tree",
       not miss, str(miss[:4]))
    # -- validation (Iron Rule 8 + ids + keys + art sizes + palettes)
    st576 = SI.literal_stream(bytes(i % 251 for i in range(576)))
    try:
        _st = SI.literal_stream(bytes(range(256)) * 2 + bytes(64))
        _r = len(__import__('dwm.sprite_codec', fromlist=['x']).decode(_st)) == 576
    except ValueError as _e:
        _r = 'all 256 byte patterns' in str(_e)
    ok("S107 sheet: a payload using all 256 byte values gets a stream or a plain error", _r)
    st256 = SI.literal_stream(bytes(i % 250 for i in range(256)))
    fx = {'assets/art/t_b.bin': st576, 'assets/art/t_f.bin': st256,
          'assets/art/t_short.bin': SI.literal_stream(bytes(100))}
    for sid in (215, 216, 220):
        expect_error(f"S107 art: species {sid} (TERRY? / summon) refused",
                     _art_fixture({str(sid): {'battle': {'palette': ['$0000', '$6BFF', '$0000', '$0000']}}}, fx),
                     'Iron Rule 8')
    expect_error("S107 art: a new-species id is refused (custom.species owns its art)",
                 _art_fixture({'224': {'follower': {'palette': 1}}}, fx), 'custom.species')
    expect_error("S107 art: unknown key refused", _art_fixture({'9': {'walk': {}}}, fx), 'unknown key')
    expect_error("S107 art: battle art must decode to 576 bytes",
                 _art_fixture({'9': {'battle': {'art': 'assets/art/t_short.bin'}}}, fx), 'exactly 576')
    expect_error("S107 art: walking art must decode to 256 bytes",
                 _art_fixture({'9': {'follower': {'art': 'assets/art/t_b.bin'}}}, fx), 'exactly 256')
    expect_error("S107 art: a missing art file is an error",
                 _art_fixture({'9': {'follower': {'art': 'assets/art/none.bin'}}}, fx), 'cannot read')
    expect_error("S107 art: OBJ palette outside 0-7 refused",
                 _art_fixture({'9': {'follower': {'palette': 8}}}, fx), 'OBJ palettes 0-7')
    expect_error("S107 art: battle palette needs 4 colours",
                 _art_fixture({'9': {'battle': {'palette': ['$0000']}}}, fx), '4 RGB555')
    # -- a project with art: the regions carry it
    ents = {'9': {'battle': {'art': 'assets/art/t_b.bin', 'palette': ['$1234', '$6BFF', '$4321', '$0000']},
                  'follower': {'art': 'assets/art/t_f.bin', 'palette': 5}},
            '200': {'follower': {'palette': 3}},
            '42': {'battle': {'palette': ['$0101', '$6BFF', '$0202', '$0000']}},
            '214': {'follower': {'art': 'assets/art/t_f.bin'}}}
    outa, _, _ = compile_data(_art_fixture(ents, fx))
    bg = region_bytes(outa, 'patches/bank_000.asm', 'art_battle_gfx')
    w = lambda b, i: b[2 * i] | b[2 * i + 1] << 8
    ok("S107 art: species 9 battle gfx -> $7F00 (art bank $7F, index 0)", w(bg, 9) == 0x7F00, hex(w(bg, 9)))
    ok("S107 art: species without battle art keep their gfx-ID",
       all(w(bg, i) == w(b''.join(vt('battle_gfx')), i) for i in range(215) if i != 9))
    for name, path, bank in A.WALK_COPIES:
        wg = region_bytes(outa, path, name)
        ok(f"S107 art: walking copy ${bank:02X}: 9 -> $7F01, 214 -> $7F02, the rest original",
           w(wg, 9) == 0x7F01 and w(wg, 214) == 0x7F02 and
           all(w(wg, i) == w(b''.join(vt('follower_gfx')), i) for i in range(215) if i not in (9, 214)))
    l10 = region_bytes(outa, 'patches/bank_010.asm', 'art_layout_10')
    a10 = region_bytes(outa, 'patches/bank_010.asm', 'art_attr_10')
    l11 = region_bytes(outa, 'patches/bank_011.asm', 'art_layout_11')
    a11 = region_bytes(outa, 'patches/bank_011.asm', 'art_attr_11')
    ok("S107 art: new walking art -> its bank's layout 0 (9 -> $10:$4E33, 214 -> $11:$4184)",
       w(l10, 9) == 0x4E33 and w(l11, 214 - 128) == 0x4184)
    ok("S107 art: walking palette written (9 -> 5 no flips; 214 keeps its original palette)",
       a10[9] == 5 and a11[214 - 128] == vt('follower_attr_11')[214 - 128][0] & 7)
    ok("S107 art: palette-only walking edit keeps the layout and the flip bits (200 -> 3)",
       a11[200 - 128] == (vt('follower_attr_11')[200 - 128][0] & 0xF8) | 3 and
       w(l11, 200 - 128) == w(b''.join(vt('follower_layout_11')), 200 - 128))
    bp = region_bytes(outa, 'patches/bank_017.asm', 'art_battle_pal')
    ok("S107 art: battle palettes 9 / 42 written, others original",
       bp[9 * 8:10 * 8] == bytes.fromhex('3412ff6b21430000') and bp[42 * 8:43 * 8] == bytes.fromhex('0101ff6b02020000')
       and all(bp[i * 8:i * 8 + 8] == vt('battle_palettes')[i] for i in range(215) if i not in (9, 42)))
    b7f = outa['patches/bank_07f.asm']
    ok("S107 art: bank $7F = self-ID, 3 pointers, the three streams in species order",
       'ArtBattle_9' in b7f and 'ArtWalk_9' in b7f and 'ArtWalk_214' in b7f
       and b7f.index('ArtBattle_9:') < b7f.index('ArtWalk_9:') < b7f.index('ArtWalk_214:')
       and 'ds $4000, $00' in outa['patches/bank_07c.asm'])
    # -- budget: more than the three banks hold
    many = {str(i): {'battle': {'art': 'assets/art/t_b.bin'}, 'follower': {'art': 'assets/art/t_f.bin'}}
            for i in range(60)}
    expect_error("S107 art: art over the three art banks is refused (with the byte count)",
                 _art_fixture(many, fx), 'do not fit')
    fifty = {k: v for k, v in many.items() if int(k) < 50}
    try:
        compile_data(_art_fixture(fifty, fx))
        fit = True
    except C.CompileError as e:
        fit = str(e)
    ok("S107 art: 50 fully re-arted monsters (literal streams) fit (user: 'no more than 50')",
       fit is True, str(fit)[:200])
    return outa


def _layout_sig_rom(rom, bank, l2):
    """The six frames of the level-2 table at bank:l2 of a built ROM, as
    sorted (dy, dx, tile, xflip, yflip) tuples (like walk_layouts.entries)."""
    out = []
    for j in range(6):
        o = bank * 0x4000 + l2 - 0x4000 + 2 * j
        fp = rom[o] | rom[o + 1] << 8
        q = bank * 0x4000 + fp - 0x4000
        fr = []
        while rom[q] != 0x80:
            dy, dx, t, at = rom[q:q + 4]
            fr.append((dy - 256 if dy > 127 else dy, dx - 256 if dx > 127 else dx, t,
                       bool(at & 0x20), bool(at & 0x40)))
            q += 4
        out.append(sorted(fr))
    return out


def test_walk_layouts_s107():
    """S107 (ROADMAP P3.10 part 2b): the 155 walking layouts — the packer,
    the ranking, a chosen layout for an original monster / a new species, the
    copies into the other follower bank."""
    from editor2.core import walk_layouts as WL
    from editor2.core import sheet_import as SI
    from editor2.core import sprite_render as SR
    ok("S107 2b: 155 layouts; layout 0 exists in both follower banks",
       WL.count() == 155 and WL.native_l2(0, 0x10) and WL.native_l2(0, 0x11))
    # -- the packer reproduces original monsters through their OWN layout
    ms = json.load(open(os.path.join(REPO, 'extracted', 'monster_sprites.json')))['monsters']
    n_in, bad = 0, []
    for sid in range(215):
        lid = WL.species_layout(sid)
        if not all(-8 <= dx and dx <= 0 and -16 <= dy and dy <= -8
                   for es in WL.entries(lid).values() for dy, dx, *_ in es):
            continue                      # the sheet frame is the 16x16 box
        n_in += 1
        tb = bytes.fromhex(ms[str(sid)]['follower']['tile_bytes_hex'])
        drawn = WL.render([SR.tiles_to_grid(tb[t * 16:t * 16 + 16], 1, 1) for t in range(16)], lid)
        fr = {f: [[d.get((WL.BOX[1] + y, WL.BOX[0] + x), 0) for x in range(16)] for y in range(16)]
              for f, d in zip(WL.FRAMES, drawn)}
        tiles, err, _e = WL.pack(fr, lid)
        if err or WL.render(tiles, lid) != drawn:
            bad.append(sid)
        if sid in (9, 21, 214) and WL.fit_all(fr, sid=sid)[0][0] != 0:
            bad.append(('rank', sid))
    ok(f"S107 2b: the packer redraws all {n_in} original monsters whose layout fits the "
       "16x16 frame exactly through their own layout; the ranking puts a 0-pixel layout first",
       n_in >= 40 and not bad, str(bad[:5]))
    # -- the sheet: the blue dragon (Gorbunok) packs for layout 0 exactly like S106
    sheet = SI.Sheet(os.path.join(REPO, 'examples/follower_swap/W_bluedragon.png'))
    hit = [e for e in SI.find_entries(sheet) if e['frames'] and e['frames']['DOWN-a']['x'] == 232
           and e['frames']['DOWN-a']['y'] == 8][0]
    pay0, _err0 = SI.follower_pack(sheet, hit['frames'], 0)
    ok("S107 2b: layout-0 packing == the S106 packing (Gorbunok's frames)",
       pay0 == SI.follower_payload(sheet, hit['frames']))
    rank = SI.follower_fit(sheet, hit['frames'], sid=224)
    ok("S107 2b: the ranking covers all 155 layouts, best first",
       len(rank) == 155 and rank == sorted(rank, key=lambda r: r[0]) and
       SI.follower_pack(sheet, hit['frames'], rank[0][1])[1] == rank[0][0])
    # -- layouts of one bank only (a copy is needed in the other)
    only10 = [L['id'] for L in WL.data()['layouts'] if list(L['instances']) == ['10']]
    only11 = [L['id'] for L in WL.data()['layouts'] if list(L['instances']) == ['11']]
    both = [L['id'] for L in WL.data()['layouts'] if len(L['instances']) == 2 and L['id']]
    l11, l10, lb = only11[0], only10[0], both[0]
    st256 = SI.literal_stream(bytes(i % 250 for i in range(256)))
    fx = {'assets/art/t_f.bin': st256}
    ents = {'9': {'follower': {'art': 'assets/art/t_f.bin', 'layout': l11}},       # copy -> $10
            '10': {'follower': {'art': 'assets/art/t_f.bin', 'layout': lb}},       # native $10
            '200': {'follower': {'art': 'assets/art/t_f.bin', 'layout': l10}},     # copy -> $11
            '201': {'follower': {'art': 'assets/art/t_f.bin'}}}                    # 2a: layout 0
    d = _art_fixture(ents, fx)
    g = d['custom']['species'][0]
    g['follower'].pop('walks_like', None)
    g['follower']['layout'] = l10                                    # shares 200's copy
    out, prj, _w = compile_data(d)
    l10r = '\n'.join(region_text(out, 'patches/bank_010.asm', 'art_layout_10'))
    l11r = '\n'.join(region_text(out, 'patches/bank_011.asm', 'art_layout_11'))
    c10 = '\n'.join(region_text(out, 'patches/bank_010.asm', 'lay_copies_10'))
    c11 = '\n'.join(region_text(out, 'patches/bank_011.asm', 'lay_copies_11'))
    nl = '\n'.join(region_text(out, 'patches/bank_011.asm', 'ns_follower_layout'))
    ok("S107 2b: level-1 rows: 9 -> the bank-$10 copy, 10 -> its native table, 200 -> the "
       "bank-$11 copy, 201 -> layout 0 ($4184)",
       f'dw FollowerLayoutCopy10_L{l11}' in l10r and f'dw FollowerLayoutCopy11_L{l10}' in l11r
       and f'${WL.native_l2(lb, 0x10):04X}' in l10r and 'dw $4184   ; [201]' in l11r)
    ok("S107 2b: one copy per bank, the new species shares 200's",
       c10.count('FollowerLayoutCopy10_L') >= 1 and f'FollowerLayoutCopy11_L{l10}:' in c11
       and c11.count(f'FollowerLayoutCopy11_L{l10}:') == 1
       and f'dw FollowerLayoutCopy11_L{l10}   ; [224] Gorbunok: layout {l10}' in nl)
    # -- refusals
    expect_error("S107 2b: a layout without new walking art is refused",
                 _art_fixture({'9': {'follower': {'layout': 3}}}, fx), 'only goes with NEW')
    expect_error("S107 2b: layout outside 0-154 refused",
                 _art_fixture({'9': {'follower': {'art': 'assets/art/t_f.bin', 'layout': 155}}}, fx),
                 'walking layouts')
    d2 = base()
    d2['custom']['species'][0]['follower']['layout'] = 3
    expect_error("S107 2b: a new species with layout AND walks_like refused", d2, 'not both')
    many = {str(i): {'follower': {'art': 'assets/art/t_f.bin', 'layout': only11[i]}}
            for i in range(min(60, len(only11)))}
    expect_error("S107 2b: more layout copies than bank $10's free tail holds are refused",
                 _art_fixture(many, fx), 'free tail holds')
    return out


ICON_A = ['33333333', '30000003', '30222203', '30211203', '30211203', '30222203', '30000003', '33333333']
ICON_S = ['11111111', '13333331', '13000031', '13022031', '13022031', '13000031', '13333331', '11111111']


def test_family_icons_s107():
    """S107 (ROADMAP P3.10 part 2c): the family icons — gamedata.families.<f>.icon
    -> the font glyph (bank $4F), the gfx stream (bank $2E / bank $6D)."""
    from editor2.core import gamedata as G
    rom = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    out, _, _ = compile_data(base())
    f4 = region_bytes(out, 'patches/bank_04f.asm', 'gd_family_icons')
    ok("S107 2c: no icon edits -> the 10 font glyphs == ROM $4F:$4110-$41AF, + the Spirit glyph",
       f4[:160] == rom[0x4F * 0x4000 + 0x110:][:160] and
       f4[160:] == G.icon_tile(G.vanilla_icons(REPO)[10]))
    st = region_bytes(out, 'patches/bank_02e.asm', 'gd_family_icon_streams')
    ok("S107 2c: no icon edits -> the 10 icon streams == ROM $2E:$424A-$42F7 (190 B)",
       st == rom[0x2E * 0x4000 + 0x24A:][:190])
    sp = region_bytes(out, 'patches/bank_06d.asm', 'gd_spirit_icon_stream')
    ok("S107 2c: no icon edits -> SpiritIconStream = dw $0010, marker $00, the wisp",
       sp == bytes((0x10, 0, 0)) + G.icon_tile(G.vanilla_icons(REPO)[10]))
    d = base()
    d.setdefault('gamedata', {}).setdefault('families', {})['slime'] = {'icon': ICON_A}
    d['gamedata']['families']['spirit'] = dict(d['gamedata']['families'].get('spirit') or {},
                                               icon=ICON_S)
    o2, _, _ = compile_data(d)
    ta, ts = G.icon_tile(G.icon_grid(ICON_A, 'a')), G.icon_tile(G.icon_grid(ICON_S, 's'))
    f4 = region_bytes(o2, 'patches/bank_04f.asm', 'gd_family_icons')
    st = region_bytes(o2, 'patches/bank_02e.asm', 'gd_family_icon_streams')
    sp = region_bytes(o2, 'patches/bank_06d.asm', 'gd_spirit_icon_stream')
    ok("S107 2c: a Slime + a Spirit icon -> glyph $10 / $1A, stream $2E03, SpiritIconStream; "
       "the other 9 untouched, every stream still 19 B",
       f4[:16] == ta and f4[160:] == ts and f4[16:160] == rom[0x4F * 0x4000 + 0x120:][:144]
       and st[3:19] == ta and st[19:] == rom[0x2E * 0x4000 + 0x24A + 19:][:171]
       and sp[3:] == ts and len(st) == 190)
    for bad, why in ((['1111111'] * 8, '8 rows of 8 digits'), (['11111114'] * 8, '8 rows of 8 digits'),
                     (['11111111'] * 7, '8 rows of 8 digits')):
        d = base()
        d.setdefault('gamedata', {}).setdefault('families', {})['bird'] = {'icon': bad}
        expect_error(f"S107 2c: a bad icon is refused ({bad[0]!r} x {len(bad)})", d, why)
    return o2


def _mt_fixture(mt, species_desc=None):
    d = base()
    d.setdefault('gamedata', {})['monster_text'] = mt
    if species_desc is not None:
        g = d['custom']['species'][0]
        g.pop('description_from', None)
        g['description'] = species_desc
    return d


def _rom_str(rom, bank, ptr_addr):
    o = bank * 0x4000 + ptr_addr - 0x4000
    p = rom[o] | rom[o + 1] << 8
    q = bank * 0x4000 + p - 0x4000
    return rom[q:rom.index(b'\xf0', q)]


def test_monster_text_s108():
    """S108 (ROADMAP P3.10 part 3): gamedata.monster_text — the ORIGINAL monsters'
    names / default nicknames / descriptions (+ a new species' own description)."""
    from editor2.core import monster_text as MT
    rom = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    out, _, _ = compile_data(base())
    nb = region_bytes(out, 'patches/bank_041.asm', 'gd_monster_names')
    kb = region_bytes(out, 'patches/bank_041.asm', 'gd_monster_nicks')
    db_ = region_bytes(out, 'patches/bank_04d.asm', 'gd_monster_desc')
    ok("S108: no edits -> the name block == ROM $41:$5B1F-$628D (1,903 B)",
       nb == rom[0x41 * 0x4000 + 0x1B1F:][:1903])
    ok("S108: no edits -> the nickname block == ROM $41:$69F2-$6C76 (645 B)",
       kb == rom[0x41 * 0x4000 + 0x29F2:][:645])
    ok("S108: no edits -> the description block == ROM $4D:$53D3-$7719 (9,031 B)",
       db_ == rom[0x4D * 0x4000 + 0x13D3:][:9031])
    ok("S108: no edits -> gd_monster_desc_extra empty",
       region_bytes(out, 'patches/bank_04d.asm', 'gd_monster_desc_extra') == b'')
    # labels == the clean disassembly's (the pointer tables name them)
    dis41 = open(os.path.join(REPO, 'disassembly', 'bank_041.asm')).read()
    dis4d = open(os.path.join(REPO, 'disassembly', 'bank_04d.asm')).read()
    ok("S108: every name / nickname / description label is the clean tree's",
       all(f"{MT.name_label(s)}:" in dis41 for s in MT.NAME_ORDER)
       and all(f"{MT.nick_label(s)}:" in dis41 for s in MT.IDS)
       and all(f"{MT.desc_label(s)}:" in dis4d for s in MT.IDS))
    # encoders
    ok("S108: encode_name 'Goo-Bob' = glyphs, '-' = $9C",
       MT.encode_name('Goo-Bob', 'x') == bytes([0x2A, 0x4C, 0x4C, 0x9C, 0x25, 0x4C, 0x3F]))
    ok("S108: encode_desc: \"'s\" / \"'t\" are one cell ($68 / $67), lines split by $F1",
       MT.encode_desc(["It's", "can't"], 'x') ==
       bytes([0x2C, 0x51, 0x68, 0xF1, 0x40, 0x3E, 0x4B, 0x67]))
    van = MT.vanilla(REPO)
    ok("S108: every vanilla description re-encodes from its decoded lines (round trip)",
       all(MT.encode_desc(MT.desc_lines(van['descs'][s]), 'x') == van['descs'][s] for s in MT.IDS))
    ok("S108: every vanilla name / nickname re-encodes (round trip)",
       all(MT.encode_name(MT.decode(van['names'][s]), 'x') == van['names'][s] for s in range(215))
       and all(MT.encode_name(MT.decode(van['nicks'][s]), 'x', 1, 4) == van['nicks'][s] for s in MT.IDS))
    # edits
    mt = {"8": {"name": "Goober", "nickname": "GOOB",
                "description": ["A wobbly blob", "that's always", "grinning - & glad"]},
          "147": {"name": "Grendel"}, "28": {"nickname": "D"}}
    o2, _, _ = compile_data(_mt_fixture(mt))
    nb = region_bytes(o2, 'patches/bank_041.asm', 'gd_monster_names')
    pre = b''.join(van['names'][s] + b'\xf0' for s in range(8))
    ok("S108: renames -> the name block keeps its 1,903 B; species 0-7 unchanged, then "
       "Goober in Slime's place",
       len(nb) == 1903 and nb.startswith(pre + MT.encode_name('Goober', 'x') + b'\xf0'
                                         + van['names'][9] + b'\xf0'))
    lt = "\n".join(region_text(o2, 'patches/bank_04d.asm', 'gd_library_text'))
    ok("S108: Akubar's recipe line follows Grendal -> Grendel (vanilla typo 'Grenadal' gone)",
       'Grendel  Grendel' in lt)
    # spill: every name of 0-214 nine letters long -> some go to the extents
    big = {str(s): {"name": ("Q" + "abcdefghijklmnopqrstuvwxyz"[s % 26] * 8)} for s in range(0, 215)
           if MT.decode(van['names'][s]) and len(van['names'][s]) < 9}
    spill = MT.bank41_spills(_mt_fixture(big), REPO)
    ok("S108: lengthened names that overflow the block are spilled (not lost)",
       len(spill) > 0)
    expect_error("S108: more spill than the free extents hold is refused (names)",
                 _mt_fixture(big), "bank $41 text")
    small = dict(list(big.items())[:12])
    o3, _, _ = compile_data(_mt_fixture(small))
    allx = "\n".join(o3['patches/bank_041.asm'].split('\n'))
    ok("S108: a few lengthened names fit (block slack + extents); labels defined once",
       all(allx.count(f"{MT.name_label(int(k))}:") == 1 for k in small))
    # refusals
    expect_error("S108: TERRY? cannot be renamed (Iron Rule 8)",
                 _mt_fixture({"215": {"name": "Rival"}}), "Iron Rule 8")
    expect_error("S108: a 10-character name is refused",
                 _mt_fixture({"8": {"name": "Abcdefghij"}}), "1-9 characters")
    expect_error("S108: a 5-letter nickname is refused",
                 _mt_fixture({"8": {"nickname": "ABCDE"}}), "1-4 characters")
    expect_error("S108: a character the font lacks is refused",
                 _mt_fixture({"8": {"name": "Sl@me"}}), "not in the game font")
    expect_error("S108: a 19-cell description line is refused",
                 _mt_fixture({"8": {"description": ["a" * 19]}}), "19 cells")
    expect_error("S108: four description lines are refused",
                 _mt_fixture({"8": {"description": ["a", "b", "c", "d"]}}), "1-3 lines")
    expect_error("S108: unknown field refused",
                 _mt_fixture({"8": {"title": "x"}}), "unknown field")
    # new species: own description
    o4, _, _ = compile_data(_mt_fixture({}, ["A blue dragon", "from the deep"]))
    ns = "\n".join(region_text(o4, 'patches/bank_04d.asm', 'ns_detail_text'))
    ex = "\n".join(region_text(o4, 'patches/bank_04d.asm', 'gd_monster_desc_extra'))
    ok("S108: a new species' own description -> NsDesc_224 in gd_monster_desc_extra, "
       "HighLine2Ptrs[224] points at it", 'dw NsDesc_224' in ns and 'NsDesc_224:' in ex)
    d5 = _mt_fixture({}, ["x"])
    d5['custom']['species'][0]['description_from'] = 3
    expect_error("S108: description + description_from together are refused", d5, "not both")
    ok("S108: Gorbunok's borrowed description is a label (follows an edit of species 78)",
       f"dw {MT.desc_label(78)}" in "\n".join(region_text(out, 'patches/bank_04d.asm', 'ns_detail_text')))
    return o2


def test_monster_text_rom(rom_bytes, sym):
    """--rom: the built ROM's mode 5 / 7 / 1 tables lead to the authored text."""
    from editor2.core import monster_text as MT
    ok("ROM S108: names 8 / 147 = Goober / Grendel, Dracky untouched",
       _rom_str(rom_bytes, 0x41, 0x4339 + 16) == MT.encode_name('Goober', 'x')
       and _rom_str(rom_bytes, 0x41, 0x4339 + 294) == MT.encode_name('Grendel', 'x')
       and _rom_str(rom_bytes, 0x41, 0x4339 + 156) == MT.encode_name('Dracky', 'x'))
    ok("ROM S108: nicknames 8 / 28 = GOOB / D",
       _rom_str(rom_bytes, 0x41, 0x4739 + 16) == MT.encode_name('GOOB', 'x')
       and _rom_str(rom_bytes, 0x41, 0x4739 + 56) == MT.encode_name('D', 'x'))
    ok("ROM S108: description 8 through dispatch entry 269",
       _rom_str(rom_bytes, 0x4D, 0x4001 + 2 * 269) ==
       MT.encode_desc(["A wobbly blob", "that's always", "grinning - & glad"], 'x'))
    ok("ROM S108: HighLine2Ptrs at monster_text.HIGH_LINE2_PTRS (the extra region's room)",
       sym['HighLine2Ptrs'] == (0x4D, MT.HIGH_LINE2_PTRS))


def _arena_fixture(arena, enemies=None):
    d = base()
    gd = d.setdefault('gamedata', {})
    gd['arena'] = arena
    if enemies:
        gd.setdefault('enemies', {}).update(enemies)
    return d


ARENA_FIX = {"StarryNight": {"matches": {"0": {"size": 1}, "1": {"size": 2},
                                         "2": {"master": {"monster": 40}}}},
             "G": {"fee": 20, "matches": {"1": {"master": {"person": "0x02"}}}},
             "S": {"fee": 65535},
             "King": {"matches": {"0": {"size": 2, "master": {"monster": 19}}}}}


def test_arena_s109():
    """S109 (ROADMAP P3.10b): gamedata.arena — class fees, the master of each
    match, team sizes (1-3; engine bank $6E ArenaTeamFixup)."""
    from editor2.core import arena as AR
    rom = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()

    def rr(bank, addr, n):
        o = bank * 0x4000 + addr - 0x4000
        return rom[o:o + n]
    out, _, _ = compile_data(base())
    ok("S109: no arena -> ArenaMasterSpriteTable == ROM $04:$5E22 (60 B)",
       region_bytes(out, 'patches/bank_004.asm', 'gd_arena_masters_04') == rr(0x04, 0x5E22, 60))
    ok("S109: no arena -> ArenaMasterSpriteTable50 == ROM $50:$6778 (54 B)",
       region_bytes(out, 'patches/bank_050.asm', 'gd_arena_masters_50') == rr(0x50, 0x6778, 54))
    ok("S109: no arena -> ArenaClassFeeTable == ROM $09:$5D23 (16 B: 0 10 50 100 500 1000 5000 10000)",
       region_bytes(out, 'patches/bank_009.asm', 'gd_arena_fees') == rr(0x09, 0x5D23, 16))
    ok("S109: no arena -> every team has 3 monsters (30 x 3)",
       region_bytes(out, 'patches/bank_06e.asm', 'gd_arena_team_sizes') == bytes([3] * 30))
    ok("S109: the formula: G match 1 = EIDs 224-226, Starry Night match 3 = 302-304, "
       "the King = 481-483",
       [AR.eid(0, 0, s) for s in range(3)] == [224, 225, 226]
       and [AR.eid(8, 2, s) for s in range(3)] == [302, 303, 304]
       and [AR.eid(9, 0, s) for s in range(3)] == [481, 482, 483])
    o2, _, _ = compile_data(_arena_fixture(ARENA_FIX))
    m4 = region_bytes(o2, 'patches/bank_004.asm', 'gd_arena_masters_04')
    m5 = region_bytes(o2, 'patches/bank_050.asm', 'gd_arena_masters_50')
    want = bytearray(rr(0x04, 0x5E22, 60))
    want[2 * 26:2 * 26 + 2] = bytes([40 + 0x10, 1])      # Starry match 3: Coatol
    want[2 * 1:2 * 1 + 2] = bytes([0x02, 0])             # G match 2: person $02
    want[2 * 27:2 * 27 + 2] = bytes([19 + 0x10, 1])      # King: GoldSlime
    ok("S109: masters -> bank $04 rows (person = [id, 0], monster = [species+$10, 1])",
       m4 == bytes(want))
    ok("S109: the bank $50 copy == the first 27 rows (no King)", m5 == bytes(want[:54]))
    fees = region_bytes(o2, 'patches/bank_009.asm', 'gd_arena_fees')
    ok("S109: fees G = 20, S = 65535, the rest vanilla",
       fees == bytes([20, 0]) + rr(0x09, 0x5D25, 12) + bytes([0xFF, 0xFF]))
    sz = region_bytes(o2, 'patches/bank_06e.asm', 'gd_arena_team_sizes')
    ok("S109: team sizes -> Starry 1 / 2 / 3, King 2, the rest 3",
       sz == bytes([3] * 24 + [1, 2, 3, 2, 3, 3]))
    # refusals
    expect_error("S109: unknown group refused", _arena_fixture({"Z": {"fee": 1}}), "unknown group")
    expect_error("S109: a fee on Starry Night refused",
                 _arena_fixture({"StarryNight": {"fee": 5}}), "only the classes G-S")
    expect_error("S109: a fee over 65535 refused", _arena_fixture({"A": {"fee": 70000}}), "0-65535")
    expect_error("S109: team size 0 refused",
                 _arena_fixture({"G": {"matches": {"0": {"size": 0}}}}), "1-3 monsters")
    expect_error("S109: team size 4 refused",
                 _arena_fixture({"G": {"matches": {"0": {"size": 4}}}}), "1-3 monsters")
    expect_error("S109: the King has one match",
                 _arena_fixture({"King": {"matches": {"1": {"size": 1}}}}), "one match")
    expect_error("S109: match 3 of a class is '2', not '3'",
                 _arena_fixture({"G": {"matches": {"3": {"size": 1}}}}), 'matches "0"-"2"')
    expect_error("S109: a master that is both a person and a monster refused",
                 _arena_fixture({"G": {"matches": {"0": {"master": {"person": 2, "monster": 8}}}}}),
                 "one of")
    expect_error("S109: a summon as master refused (Iron Rule 8)",
                 _arena_fixture({"G": {"matches": {"0": {"master": {"monster": 216}}}}}),
                 "Iron Rule 8")
    expect_error("S109: species 239 as master refused (draw id $FF)",
                 _arena_fixture({"G": {"matches": {"0": {"master": {"monster": 239}}}}}),
                 "cannot be drawn")
    expect_error("S109: a person id outside the NPC catalog refused ($E0 = the player)",
                 _arena_fixture({"G": {"matches": {"0": {"master": {"person": "0xE0"}}}}}),
                 "not an NPC sprite")
    expect_error("S109: unknown match field refused",
                 _arena_fixture({"G": {"matches": {"0": {"prize": 3}}}}), "unknown field")
    expect_error("S109: a fighting team member that is a summon is refused (Iron Rule 8)",
                 _arena_fixture({}, {"224": {"species": 217}}), "Iron Rule 8")
    _o, _p, w = compile_data(_arena_fixture({"G": {"matches": {"0": {"size": 1}}}},
                                            {"225": {"species": 217}}))
    ok("S109: a summon in a slot the team does not use (size 1, slot 2) is not an error",
       'patches/bank_06e.asm' in _o)
    return o2


def test_arena_rom(rom_bytes, sym):
    """--rom: the built tables at their labels; the two far-call sites; the
    engine routine run from the ROM's bytes for every match."""
    def at(name, n):
        bk, ad = sym[name]
        o = bk * 0x4000 + ad - 0x4000
        return rom_bytes[o:o + n]
    ok("ROM S109: ArenaMasterSpriteTable still at $04:$5E22, ArenaMasterSpriteTable50 at "
       "$50:$6778, ArenaClassFeeTable at $09:$5D23",
       sym['ArenaMasterSpriteTable'] == (0x04, 0x5E22)
       and sym['ArenaMasterSpriteTable50'] == (0x50, 0x6778)
       and sym['ArenaClassFeeTable'] == (0x09, 0x5D23))
    ok("ROM S109: Starry match 3 master = Coatol ($38, 1); King = GoldSlime ($23, 1)",
       at('ArenaMasterSpriteTable', 60)[52:54] == bytes([0x38, 1])
       and at('ArenaMasterSpriteTable', 60)[54:56] == bytes([0x23, 1]))
    site = bytes([0x21, 0x00, 0x6E, 0xD7, 0xC9, 0x00])
    rd = sym['ReadArenaGroup'][1]
    ok("ROM S109: both routine tails far-call bank $6E entry 0 (ld hl,$6E00 / rst $10 / ret / nop)",
       rom_bytes[0x04 * 0x4000:0x05 * 0x4000].count(site) == 1
       and rom_bytes[0x50 * 0x4000:0x51 * 0x4000].count(site) == 1
       and rom_bytes[0x6E * 0x4000 + 1:0x6E * 0x4000 + 3] ==
       bytes([sym['ArenaTeamFixup'][1] & 0xFF, sym['ArenaTeamFixup'][1] >> 8])
       and rd < 0x5E22)
    from editor2.core import arena as AR
    sizes = list(at('ArenaTeamSizeTable', 30))
    bad = []
    for gi in range(10):
        for m in range(3):
            cpu = MiniSM83(rom_bytes, 0x6E)
            cpu.ram[sym['wArenaGroup'][1]] = gi
            cpu.ram[sym['wColiseumBattle'][1]] = m
            cpu.ram[0xDA02] = 2
            for k in range(8):
                cpu.ram[0xD7CA + k] = 0x40 + k
            cpu.run(sym['ArenaTeamFixup'][1])
            n = sizes[3 * gi + m]
            ent = [(cpu.ram.get(0xD7CA + 2 * k), cpu.ram.get(0xD7CB + 2 * k)) for k in range(4)]
            want = [(0x40, 0x41), (0x42, 0x43) if n >= 2 else (0xFF, 0x00), (0x44, 0x45),
                    (0x46, 0x01) if n == 3 else (0xFF, 0x00)]
            if cpu.ram[0xDA02] != n - 1 or ent != want:
                bad.append((gi, m, n, cpu.ram[0xDA02], ent))
    ok("ROM S109: ArenaTeamFixup run from the ROM for all 30 (group, match): $DA02 = size-1, "
       "absent slots' display entries [$FF,$00], $D7D1 = 1", not bad, str(bad[:3]))
    cpu = MiniSM83(rom_bytes, 0x6E)
    cpu.ram[sym['wArenaGroup'][1]] = 8
    cpu.ram[sym['wColiseumBattle'][1]] = 0xFF
    cpu.ram[0xDA02] = 2
    cpu.run(sym['ArenaTeamFixup'][1])
    ok("ROM S109: an index past the table ($FF) leaves the vanilla values", cpu.ram[0xDA02] == 2)
    ok("ROM S109: the table read is the fixture's (Starry 1/2/3, King 2)",
       sizes[24:28] == [1, 2, 3, 2] and AR.ROWS == 30)


def _save_tmp(doc):
    doc.save()
    return os.path.dirname(doc.path)


def main():
    # 1. determinism + example compiles clean
    out1, prj, warns = compile_data(base())
    out1_ex[0] = out1
    out2, _, _ = compile_data(base())
    ok("deterministic emit", out1 == out2)
    b60_ex = out1['patches/bank_060.asm']
    ok("all 26 targets produced (S101: + bank $16 gate table, bank $6B enemies; "
       "S102: + bank $6C tile animation; S103: + the gamedata regions in banks "
       "$01/$03/$06/$07/$12/$13/$4D/$54/$69; S104: + bank $41 Spirit names, bank $6D voices; "
       "S105: + bank $7E and the new-species ns_* regions in $11/$6A; S105 G3: the "
       "follower forks of $09/$0B/$18/$59 no longer have regions; S107: + the art "
       "regions in $09/$0B/$10/$18/$59 and the art banks $7A/$7C/$7F; S107 2c: + the family "
       "icon regions in $2E/$4F; S109: + the arena regions in $04/$50/$6E)",
       sorted(out1) == ['patches/bank_000.asm', 'patches/bank_001.asm',
                        'patches/bank_003.asm', 'patches/bank_004.asm',
                        'patches/bank_006.asm',
                        'patches/bank_007.asm', 'patches/bank_009.asm',
                        'patches/bank_00b.asm', 'patches/bank_010.asm',
                        'patches/bank_011.asm',
                        'patches/bank_012.asm',
                        'patches/bank_013.asm',
                        'patches/bank_014.asm', 'patches/bank_016.asm',
                        'patches/bank_017.asm', 'patches/bank_018.asm',
                        'patches/bank_02e.asm',
                        'patches/bank_041.asm', 'patches/bank_04d.asm',
                        'patches/bank_04f.asm', 'patches/bank_050.asm',
                        'patches/bank_054.asm', 'patches/bank_059.asm',
                        'patches/bank_060.asm', 'patches/bank_064.asm',
                        'patches/bank_067.asm', 'patches/bank_069.asm',
                        'patches/bank_06a.asm', 'patches/bank_06b.asm',
                        'patches/bank_06c.asm', 'patches/bank_06d.asm',
                        'patches/bank_06e.asm',
                        'patches/bank_071.asm',
                        'patches/bank_074.asm', 'patches/bank_07a.asm',
                        'patches/bank_07c.asm', 'patches/bank_07e.asm',
                        'patches/bank_07f.asm',
                        'patches/wram.asm'],
       f"(got {sorted(out1)})")

    # 1b. S94: 4x4 screen grid — screen 12 (row 3) is legal with a 160x512
    # record; the ROM0 $26DD region carries the $6B-$6F records.
    d = base()
    r = d['custom']['rooms'][6]                       # medal_vault $71
    r['screens']['12'] = json.loads(json.dumps(r['screens']['0']))
    r['screens']['12'].pop('states', None)
    r['screens']['12']['npcs'] = []
    r['screens']['12']['exits'] = []
    r['record']['height_px'] = 512
    out, _, _ = compile_data(d)
    ok("4x4 grid: screen index 12 compiles", 'patches/bank_060.asm' in out)
    ok("ROM0 region carries $6B record",
       '$6B gate_island' in out['patches/bank_000.asm'])
    d = base()
    d['custom']['rooms'][6]['screens']['12'] = d['custom']['rooms'][6]['screens']['0']
    # S96: a screen outside the record is a vanilla-legal sub-room screen
    # (Labyrinth $42 / Forest Mazes: entered by exit screen_byte only) —
    # a WARNING that says it cannot be scrolled to, not an error
    _o, _p, w = compile_data(d)
    ok("screen outside the record's scroll area warns (not an error)",
       any('outside the record' in x and '[12]' in x for x in w), f"(got {w})")
    d = base()
    d['custom']['rooms'][0].pop('record')             # gate_island $6B
    expect_error("record required below $70 too (S94)", d, "requires a 'record'")

    # 2. NOT_IMPLEMENTED layers hard-error
    d = base(); d['world'] = {'transitions': [1]}
    expect_error("world layer content hard-errors", d, "NOT_IMPLEMENTED")
    d = base(); d['custom']['music'] = [{'song': 'x'}]
    expect_error("custom.music must be an object", d, "must be an object")
    d = base(); d['custom']['music']['tracks'] = []
    expect_error("custom.music unknown key hard-errors", d, "unknown key")

    # 2b. music validation (M3b, S64)
    d = base()
    d['custom']['music']['songs'][0]['source']['library'] = 'nope'
    expect_error("music library ref must exist", d, "not found")
    d = base()
    d['custom']['music']['songs'][2]['first_id'] = "0x9F"   # collides 0x9E-0xA0
    expect_error("music id overlap rejected", d, "already claimed")
    d = base()
    d['custom']['music']['room_defaults']['0x99'] = 'dq6_town1'
    expect_error("room_defaults mapID range", d, "outside $00-$7F")
    d = base()
    d['custom']['music']['room_defaults']['0x30'] = 0
    expect_error("room_defaults id 0 is the sentinel", d, "sentinel")
    d = base()
    d['custom']['music']['room_defaults']['0x30'] = "0x09"
    _, _, wmr = compile_data(d)
    ok("raw vanilla id assignable to a vanilla room",
       not any('custom.music' in w for w in wmr))
    d = base()
    d['custom']['rooms'][0]['music'] = 'dq6_town1'   # vs room_defaults? none set for 6B in defaults... set conflict:
    d['custom']['music']['room_defaults']['0x6B'] = 'dwm2_bgm07'
    expect_error("rooms[].music vs room_defaults conflict", d, "disagree")
    d = base(); d['custom']['skills'] = [{'id': 'anchor'}]
    expect_error("custom.skills hard-errors", d, "NOT_IMPLEMENTED")

    # 3. validator rules
    # S98: the legacy 'spawn' kind is an $8F EXAMINE SPOT (PyBoy-measured) —
    # script 0 warns (A there re-runs the entry script), any other script
    # is a legitimate examine spot
    d = base()
    _o, _p, w = compile_data(d)
    ok("legacy spawn (script 0) warns as an examine spot",
       any("examine spot (S98)" in x for x in w))
    d = base()
    d['custom']['rooms'][0]['screens']['0']['npcs'][0]['script'] = 1
    compile_data(d)
    ok("legacy spawn with a script compiles (it is an examine spot)", True)

    d = base()
    del d['custom']['rooms'][0]['screens']['0']['exits'][0]['screen_byte']
    expect_error("screen_byte required", d, "screen_byte")

    d = base()
    d['custom']['dialogue'][0]['lines'] = []
    d['custom']['dialogue'][0].pop('choice')
    d['custom']['dialogue'][0]['raw'] = [["box"], "Hi", ["bytes", "0xEE"]]
    del d['custom']['dialogue'][0]['lines']
    expect_error("bare $EE / bad terminator rejected", d, "$")

    d = base()
    d['custom']['rooms'][5].pop('record')
    expect_error("every room requires a record (S94)", d, "requires a 'record'")

    d = base()
    d['build']['compat'] = {'master_table_rooms': ["0x6B", "0x6D"]}
    expect_error("compat list must be dense from $6B", d, "dense ascending")

    d = base()
    d['custom']['wram']['region_size'] = 3
    expect_error("step counters can't exceed wram region", d, "region size")

    d = base()
    d['custom']['palettes'][0]['colors_rgb555'] = \
        d['custom']['palettes'][0]['colors_rgb555'][:7]
    expect_error("palette must be 8x4", d, "8")

    d = base()
    d['custom']['rooms'][0]['scripts'].pop('0')
    expect_error("script index 0 reserved/required", d, "index 0")

    # 4. compat semantics (S70: exposure = ERROR since entry dispatches too)
    d = base()
    d['build']['compat'] = {'master_table_rooms': ["0x6B", "0x6C", "0x6D"]}
    expect_error("narrow compat table errors with uncovered rooms (S70)",
                 d, "not covered")
    d = base()
    d['build']['compat'] = {'master_table_rooms': [
        "0x6B", "0x6C", "0x6D", "0x6E", "0x6F", "0x70", "0x71",
        "0x72", "0x73"]}   # S92: + arena_clone, island_copy
    outc, _, wc = compile_data(d)
    ok("full-coverage compat compiles with legacy-only warning",
       any('legacy-only' in w for w in wc))
    ok("full-coverage compat is byte-identical to the default table",
       outc == out1)

    # 4b. S70 progression validators + lowering
    d = base()
    d['progression']['enemies'][0]['eid'] = 521            # gap from 519
    expect_error("quest enemy EIDs must be dense from 519", d, "dense")
    d = base()
    e0 = d['progression']['enemies'][0]
    for k in range(640):
        e2 = dict(e0); e2['id'] = f"e{k}"; e2['eid'] = 'auto'
        d['progression']['enemies'].append(e2)
    expect_error("project enemy capacity is 640 rows (bank $6B, S101)", d, "capacity")
    # S101: 60 project enemies compile (the S70 bank-$14 tail held 12)
    # (S105: the example has 2 of its own — vault_goldslime + gorbunok_wild)
    d = base()
    for k in range(58):
        e2 = dict(e0); e2['id'] = f"e{k}"; e2['eid'] = 'auto'
        d['progression']['enemies'].append(e2)
    outs60, _, _ = compile_data(d)
    b6b = outs60['patches/bank_06b.asm']
    ok("60 project enemies emit into bank $6B (S101)",
       'PROJECT_ENEMY_ROWS EQU 60' in b6b and 'ProjectEnemy_578:' in b6b)
    # S101: join_as -> a project redirect row ahead of the vanilla 34
    d = base()
    j = dict(e0); j['id'] = 'gs_join'; j['eid'] = 'auto'; j['joinability'] = 7
    d['progression']['enemies'].append(j)
    d['progression']['enemies'][0]['join_as'] = 'gs_join'
    outs_r, _, _ = compile_data(d)
    reg = outs_r['patches/bank_014.asm']
    reg = reg[reg.index('BossRedirectTableExt:'):]
    ok("join_as emits a project redirect row first (S101)",
       reg.index('dw 519, 521') < reg.index('dw 4, 486'))   # S105: gs_join = EID 521
    d['progression']['enemies'][0]['join_as'] = 'nobody'
    expect_error("join_as must name an enemy", d, "neither a progression.enemies id")
    d = base()
    d['progression']['quests'][0]['flags'].pop('done')
    expect_error("quest flags.done required", d, "flags.done")
    d = base()
    d['progression']['quests'][0]['battle'] = {'enemy': 'nope'}
    expect_error("quest battle enemy must resolve", d, "not in progression.enemies")
    d = base()
    d['progression']['extra'] = []
    expect_error("unknown progression key hard-errors", d, "unknown key")
    _, prj_p, _ = compile_data(base())
    ok("quest lowering registers quest:/entry: scripts",
       'quest:medal_vault' in prj_p._scripts and
       'entry:medal_vault' in prj_p._scripts)
    ok("quest flags auto-register from the safe pool",
       prj_p.flag_map().get('vault_guardian_beaten') == 0x0158)
    ok("quest enemy EID auto-allocates from 519",
       prj_p.quest_enemies['vault_goldslime']['_eid'] == 519)

    # 4c. S70 vanilla exit extension validators
    d = base()
    d['custom']['vanilla_exit_extensions'][0]['mapID'] = "0x6B"
    expect_error("extension mapID must be vanilla (< $6B)", d, "VANILLA")
    d = base()
    d['custom']['vanilla_exit_extensions'][0]['steps'][0]['exits'][0]['x'] = 255
    expect_error("extension trigger_x $FF rejected", d, "terminator")
    d = base()
    d['custom']['vanilla_exit_extensions'][0]['steps'][1]['exits'][3]['gate_flag'] = 1
    expect_error("custom-dest extension exits need gate_flag 0", d,
                 "gate_flag=0")

    # 4d. S94b entrance redirects -> per-(room, screen) VanillaExitExtTable
    outs0, prj0, _ = compile_data(base())
    b60_0 = outs0['patches/bank_060.asm']
    ok("redirect lowers to a per-screen ext row (db mapID, screen)",
       "db $01, $08" in b60_0 and "dw $D931" in b60_0
       and "db $05, $03, $72, $00, $01, $04, $07" in b60_0
       and "db $04, $05, $6B, $00, $00, $07, $06" in b60_0,
       "(GreatTree screen 8: both doors re-pointed, counter $D931)")
    gen = [e for e in prj0.vanilla_exit_exts if e.get('_generated')]
    ok("redirect variants cover every VALID vanilla step of that screen",
       len(gen) == 1 and len(gen[0]['steps']) == 3
       and all(len(st['exits']) == 2 for st in gen[0]['steps']))
    ok("ext rows carry the screen byte ($FF = any) for hand-written entries",
       "db $16, $FF" in b60_0)
    d = base()
    d['custom']['entrance_redirects'].append(
        {"mapID": "0x01", "screen": 8, "x": 7, "y": 2, "dest": "room:$6B",
         "screen_byte": "0x00", "spawn_x": 7, "spawn_y": 6})
    outs1, prj1, _ = compile_data(d)
    gen = [e for e in prj1.vanilla_exit_exts if e.get('_generated')][0]
    ok("redirect on a cell with no vanilla exit ADDS a door (vanilla rows kept)",
       all(len(st['exits']) == 3 for st in gen['steps'])
       and gen['steps'][0]['exits'][2]['x'] == 7)
    d = base()
    d['custom']['entrance_redirects'][0]['dest'] = "room:$7F"
    expect_error("redirect to an unknown custom room rejected", d, "7F")
    d = base()
    del d['custom']['entrance_redirects'][0]['screen_byte']
    expect_error("redirect without screen_byte rejected (never guessed)", d,
                 "screen_byte")
    d = base()
    d['custom']['vanilla_exit_extensions'].append(
        {"mapID": "0x01", "screen": 8, "step_counter": "0xD931",
         "steps": [{"exits": []}]})
    expect_error("two overrides for one (room, screen) rejected", d,
                 "already has an exit override")
    d = base()
    d['custom']['vanilla_exit_extensions'].append(
        {"mapID": "0x01", "step_counter": "0xD931", "steps": [{"exits": []}]})
    expect_error("'any'-screen override shadowing a per-screen one rejected", d,
                 "already has an exit override")
    d = base()
    d['custom']['entrance_redirects'][0]['screen'] = 3
    expect_error("redirect on a screen the vanilla room lacks rejected", d,
                 "no screen 3")

    # 4e. S94b per-(screen, state) attr/palette tables (vanilla format)
    b17 = outs0['patches/bank_017.asm']
    ok("bank $17 emits CustomAttrPtrTable -> RoomAttr_ -> ScrAttr_ chain",
       'CustomAttrPtrTable:' in b17 and 'RoomAttr_72:' in b17
       and 'ScrAttr_72_1:' in b17)
    seg = b17.split('ScrAttr_72_1:', 1)[1].split('ScrAttr_72_2:')[0]
    ok("2-state arena_clone screen 1 carries one attr/palette row per state",
       seg.count('dw ') >= 3 and seg.count('    db ') == 2,
       f"(got {seg!r})")

    # 5b. S92 [G-A]: custom.layouts / custom.tilesets / states[]
    d = base(); d['custom']['layouts'][0]['tiles'] = [[0] * 20] * 15
    expect_error("layout grid must be 16x20", d, "16 rows x 20 cols")
    d = base(); d['custom']['tilesets'][0] = {"id": "x"}
    expect_error("tileset needs exactly one source form", d,
                 "'raw2bpp' or 'spec'")
    d = base()
    d['custom']['rooms'][0]['screens']['0']['layout'] = {"id": "nope"}
    expect_error("unknown layout id rejected", d, "not in custom.layouts")
    d = base()
    scr = d['custom']['rooms'][0]['screens']['0']
    scr['states'] = [
        {"npcs": scr['npcs'], "exits": scr['exits']},
        {"npcs": [{"kind": "npc", "sprite": "0x0B", "x": 2, "y": 2,
                   "script": "none"} for _ in range(9)],
         "exits": scr['exits']}]
    del scr['npcs']; del scr['exits']
    expect_error("9 NPCs in one state hits the S91 hard cap", d, "8 HARD")
    d = base()
    scr = d['custom']['rooms'][0]['screens']['0']
    scr['states'] = [{"npcs": scr['npcs'], "exits": scr['exits']}]
    expect_error("states + top-level npcs/exits rejected", d,
                 "BOTH 'states' and top-level")
    d = base()
    scr = d['custom']['rooms'][0]['screens']['0']
    st0 = {"npcs": scr.pop('npcs'), "exits": scr.pop('exits')}
    st1 = {"npcs": list(st0['npcs']) + [
               {"kind": "npc", "sprite": "0x3A", "x": 5, "y": 5,
                "script": "none", "comment": "state-1 extra"}],
           "exits": st0['exits']}
    scr['states'] = [st0, st1]
    outs, prj2, _ = compile_data(d)
    b60 = outs['patches/bank_060.asm']
    ok("2-state screen emits contiguous V0/V1 step entries",
       'CustomRoom0_S0_V0_NPCs' in b60 and 'CustomRoom0_S0_V1_NPCs' in b60
       and b60.count('CustomRoom0_Screen0:') == 1,
       "(expected _V0/_V1 label pairs under one screen block)")
    seg = b60.split('CustomRoom0_Screen0:', 1)[1]\
        .split('CustomRoom0_S0_V0_NPCs:')[0]
    ok("2-state screen block = counter + exactly 2 step entries",
       seg.count('dw ') == 1 + 2 * 2 and seg.count('    db ') == 2,
       f"(got block: {seg!r})")

    # 4b. S97 (ROADMAP P3.5a): state rules -> CustomStateRulePtrTable
    ok("example arena_clone rank state is a flag rule (S97)",
       'CustomRoom7_StateRules' in b60_ex and 'dw $0030' in b60_ex
       and 'wCustomStep_ArenaClone_S1' in b60_ex.split('CustomRoom7_StateRules:')[1][:200],
       "(expected screen-1 rule block for $72)")
    d = base()
    d['custom']['flags'] = [{'name': 'door_open', 'index': 'auto'}]
    r = d['custom']['rooms'][7]                       # arena_clone $72
    r['state_rules'] = [
        {'state': 1, 'when': [{'flag': 'door_open'}, {'flag': '0x0031', 'is': 'clear'}],
         'screens': [1]},
        {'state': 0, 'when': []}]
    outs, prj3, _ = compile_data(d)
    b = outs['patches/bank_060.asm']
    blk = b.split('CustomRoom7_S1_Rules:')[1].split('db $FF')[0]
    ok("rule terms: named flag resolved + 'clear' sets bit 15",
       'db 1, 2' in blk and '$0158' in blk and '$8031' in blk, f"(got {blk!r})")
    ok("unconditional rule = n_terms 0 (the 'otherwise' form)",
       'db 0, 0   ; state 0 when always' in blk or 'db 0, 0' in b.split('CustomRoom7_S1_Rules:')[1],
       "(expected db 0, 0)")
    ok("rules for 1-state screens are omitted (state 0 only fits screens 0/2)",
       b.count('CustomRoom7_S0_Rules:') == 1 and 'CustomRoom7_S2_Rules:' in b)
    ok("rooms without rules get dw $0000",
       '    dw $0000   ; $6B (no rules)' in b)
    d = base()
    d['custom']['rooms'][7]['state_rules'] = [{'state': 5, 'when': []}]
    expect_error("rule state that no screen has", d, "exists on none of the screens")
    d = base()
    d['custom']['rooms'][7]['state_rules'] = [{'state': 1, 'when': [{'flag': 'nope'}]}]
    expect_error("rule with an unknown flag name", d, "neither a named flag")
    d = base()
    d['custom']['rooms'][7]['state_rules'] = [{'state': 1, 'when': [{'flag': '0x0280'}]}]
    _o, _p, w = compile_data(d)
    ok("rule on a non-saved flag warns", any('not in the save image' in x for x in w), f"(got {w})")

    # 4c. S97 (ROADMAP P3.5): NPC type byte = facing | hidden | behaviour
    d = base()
    scr = d['custom']['rooms'][0]['screens']['0']
    scr['npcs'] += [
        {"kind": "npc", "sprite": "0x0B", "x": 1, "y": 6, "facing": "right",
         "behaviour": "pace_x1", "script": "none"},
        {"kind": "npc", "sprite": "0x3A", "x": 8, "y": 6, "facing": "up",
         "hidden": True, "script": 2},
        {"kind": "npc", "sprite": "0x05", "x": 8, "y": 1, "behaviour": "pace_right3",
         "script": "none"},
        {"kind": "npc", "sprite": "0x05", "x": 4, "y": 1, "behaviour": "gate_wander",
         "script": "none"}]
    outs, _, w = compile_data(d)
    b = outs['patches/bank_060.asm']
    ok("behaviour + facing encode the type byte ($38 = right | pace_x1)",
       'db $38, $0B, $01, $06, $FF' in b, "(no $38 row)")
    ok("hidden bit 6 + raw int script index ($60 = up | hidden; script 2)",
       'db $60, $3A, $08, $06, $02' in b, "(no $60 row)")
    ok("a walker path leaving the screen warns",
       any('walks off the screen' in x for x in w), f"(got {w})")
    ok("gate-only behaviour in a room warns",
       any('gate-floor wanderer' in x for x in w), f"(got {w})")
    d = base()
    d['custom']['rooms'][0]['screens']['0']['npcs'].append(
        {"kind": "npc", "sprite": "0x0B", "x": 1, "y": 6, "behaviour": "fly", "script": "none"})
    try:
        compile_data(d)
        ok("unknown behaviour name rejected", False)
    except Exception as e:
        ok("unknown behaviour name rejected", 'behaviour' in str(e), f"(got {e})")

    # 4d. S97 r2: per-box talk text (PyBoy-measured limits: 16 cells on the
    # "*:" line, 18 elsewhere, 2 lines per box; $FA $F7 $EF $EE between boxes)
    from editor2.core import textenc as T
    ok("flow_boxes: 16-cell speaker line, 18 after, 2 lines per box",
       T.flow_boxes('Type 1. I spin in place. And then I spin some more until I get dizzy.')
       == [['Type 1. I spin', 'in place. And then'], ['I spin some more', 'until I get dizzy.']])
    ok("'..' is one glyph ($61) — counts one cell", T.cells('Wait...') == 6)
    asm = '\n'.join(T.render_entry_asm('x', {'boxes': [['Hello there', 'how are you'], ['fine']],
                                               'choice': True}))
    ok("boxes emit WAIT+CLEAR+NEWLINE between boxes and the vanilla choice tail",
       '"how are you", $FA, $F7, $EF, $EE' in asm and '"fine", $E7, $F0' in asm, asm)
    d = base()
    d['custom']['dialogue'].append({'id': 'bx_long', 'boxes': [['This line is too long']]})
    try:
        compile_data(d)
        ok("a box line past its cells is an error", False)
    except Exception as e:
        ok("a box line past its cells is an error", 'max 16' in str(e), f"(got {e})")
    d = base()
    d['custom']['dialogue'].append({'id': 'bx_3', 'boxes': [['a', 'b', 'c']]})
    try:
        compile_data(d)
        ok("a 3-line box is an error", False)
    except Exception as e:
        ok("a 3-line box is an error", '3 lines' in str(e), f"(got {e})")

    # 4e. S98 (ROADMAP P3.7): examine / step-on spots, talk form, doors, edges
    d = base()
    n = d['custom']['rooms'][0]['screens']['0']['npcs']
    n.append({'kind': 'examine', 'x': 1, 'y': 1, 'script': 'give_jerky', 'facing': 'up'})
    n.append({'kind': 'step', 'x': 8, 'y': 1, 'script': 'give_egg'})
    outs, _, w = compile_data(d)
    b = outs['patches/bank_060.asm']
    blk = b[b.find('CustomRoom0_S0_NPCs:'):]
    blk = blk[:blk.find('db $FF')]
    i_ex, i_st, i_npc = blk.find('db $82, $FF, $01, $01'), blk.find('db $90, $FF, $08, $01'), \
        blk.find('db $00, $0B')
    ok("examine spot emits $80|facing ($82 = up), step trigger emits $90",
       i_ex > 0 and i_st > 0, blk)
    ok("spots are emitted BEFORE every NPC (engine scans stop at the first NPC; PyBoy S98)",
       0 < i_ex < i_npc and 0 < i_st < i_npc, blk)
    d = base()
    d['custom']['rooms'][0]['screens']['0']['npcs'].append(
        {'kind': 'examine', 'x': 1, 'y': 1, 'script': 'give_jerky', 'facing': 'sideways'})
    try:
        compile_data(d)
        ok("unknown examine facing rejected", False)
    except Exception as e:
        ok("unknown examine facing rejected", 'facing' in str(e), f"(got {e})")

    # talk form -> ops (question -> check_and_branch $C83C 1 @no)
    d = base()
    d['custom']['dialogue'] += [
        {'id': 't98_q', 'boxes': [['Read the book?']], 'choice': True},
        {'id': 't98_y', 'boxes': [['You read it.']]},
        {'id': 't98_n', 'boxes': [['Maybe later.']]}]
    d['custom']['scripts'].append({'id': 't98', 'talk': {
        'text': 't98_q', 'question': True,
        'yes': {'text': 't98_y', 'set': ['0x0158'],
                'move': {'dest': 'room:$6B', 'screen': 4, 'x': 3, 'y': 2}},
        'no': {'text': 't98_n', 'clear': ['0x0158']}}})
    d['custom']['rooms'][0]['scripts']['4'] = 't98'
    d['custom']['rooms'][0]['screens']['0']['npcs'][1]['script'] = 't98'
    _o, p, w = compile_data(d)
    sc = next(s for s in p.custom['scripts'] if s['id'] == 't98')
    ops = sc['ops']
    ok("talk question lowers to check_and_branch $C83C 1 @no",
       ['op', 'check_and_branch', '0xC83C', '0x0001', '@no'] in ops, ops)
    ok("talk yes: set_flag + map_transition to absolute pixels (screen 4 = row 1)",
       ['op', 'map_transition', '0x006B', f'0x{3*16+8:04X}', f'0x{(8+2)*16+8:04X}'] in ops
       and any(o[:2] == ['op', 'set_flag'] for o in ops if isinstance(o, list)), ops)
    ok("talk no branch after label:no clears the flag",
       'label:no' in ops and ops.index('label:no') <
       max(i for i, o in enumerate(ops) if isinstance(o, list) and o[:2] == ['op', 'clear_flag']))
    d2 = copy.deepcopy(d)
    next(x for x in d2['custom']['dialogue'] if x['id'] == 't98_q')['choice'] = False
    expect_error("YES/NO talk needs a choice dialogue", d2, "choice box")
    d2 = copy.deepcopy(d)
    next(s for s in d2['custom']['scripts'] if s['id'] == 't98')['talk']['yes']['move']['screen'] = 1
    expect_error("talk move to a screen the room lacks", d2, "does not have")
    d2 = copy.deepcopy(d)
    next(s for s in d2['custom']['scripts'] if s['id'] == 't98')['ops'] = [['end']]
    expect_error("talk + ops together rejected", d2, "not both")

    # door pairing + edge exits
    d = base()
    ex0 = d['custom']['rooms'][0]['screens']['0']['exits'][0]
    ex0['door'] = 'door_t98'
    _o, _p, w = compile_data(d)
    ok("a door with one end warns", any('door door_t98: 1 end' in x for x in w), f"(got {w})")
    # S98 r2: door OBJECTS — an unconnected door compiles to nothing (and
    # warns); a linked pair carries `link` both ways
    d = base()
    ex = d['custom']['rooms'][0]['screens']['0']['exits']
    ex.append({'x': 6, 'y': 3, 'door': 'door_9', 'name': 'Shed door'})
    outs, _p, w = compile_data(d)
    ok("an unconnected door warns 'not connected'",
       any("door 'Shed door'" in x and 'not connected' in x for x in w), f"(got {w})")
    b60 = outs['patches/bank_060.asm']
    ok("an unconnected door emits no exit row", 'db $06, $03,' not in b60)
    ok("an unconnected door leaves the ROM data as without it",
       b60 == compile_data(base())[0]['patches/bank_060.asm'])
    d = base()
    ex = d['custom']['rooms'][0]['screens']['0']['exits']
    ex[0].update(door='door_1', name='Island hatch', link='door_2')
    d['custom']['rooms'][1]['screens']['0']['exits'].append(
        {'x': 4, 'y': 4, 'dest': 'room:$6B', 'gate_flag': 0, 'screen_byte': '0x80',
         'spawn_x': 3, 'spawn_y': 1, 'door': 'door_2', 'name': 'Hatch below', 'link': 'door_1'})
    _o, _p, w = compile_data(d)
    ok("a linked door pair compiles without door warnings",
       not any('door' in x.lower() and ('link' in x or 'lead back' in x or 'end(s)' in x)
               for x in w), f"(got {[x for x in w if 'door' in x.lower()]})")
    d['custom']['rooms'][1]['screens']['0']['exits'][-1]['link'] = 'door_7'
    _o, _p, w = compile_data(d)
    ok("a one-sided link warns", any('does not lead back' in x or 'does not exist' in x
                                     for x in w), f"(got {w})")

    d = base()
    d['custom']['rooms'][0]['screens']['0']['exits'].append(
        dict(ex0, x=4, y=7))
    _o, _p, w = compile_data(d)
    ok("bottom-row exit above a neighbour screen warns (walk-on blocks the scroll)",
       any('bottom row borders screen 4' in x for x in w), f"(got {w})")
    d = base()
    d['custom']['rooms'][0]['screens']['0']['exits'][0]['screen_byte'] = '0x03'
    expect_error("exit arriving on a screen the destination lacks", d, "does not have")

    # 5. text label / id assignment
    # S99 (P3.3e): room tile animation -> CustomAnimSrcTable (bank $71)
    d = base()
    outs, _p, w = compile_data(d)
    b71 = outs['patches/bank_071.asm']
    tab = b71.split('CustomAnimSrcTable:', 1)[1].split('\n\n', 1)[0]
    ok("anim table: one row per room from $6B", tab.count('db ') == len(d['custom']['rooms']),
       f"(got {tab})")
    ok("anim table: clone 'source' -> its source map ($72 -> $06)",
       'db $06  ; $72 — source: map $06' in tab, f"(got {tab})")
    ok("anim table: 'none' and placeholders -> $6B (the bare-ret row)",
       'db $6B  ; $6B — none' in tab and 'db $6B  ; $6E — placeholder' in tab, f"(got {tab})")
    ok("anim: ANIM_TABLE_LEN + entry 3 in the template", 'ANIM_TABLE_LEN EQU' in b71
       and 'dw CustomAnimSource' in b71)
    d = base()
    next(r for r in d['custom']['rooms'] if r['id'] == 'gate_island')['animation'] = '0x3D'
    outs, _p, w = compile_data(d)
    ok("anim: borrow '0x3D' emits $3D", 'db $3D  ; $6B — borrow: map $3D'
       in outs['patches/bank_071.asm'])
    for bad, needle in (('0x08', 'cutscene DMG palette'), ('0x70', 'not a vanilla map id'),
                        ('water', "use 'none', 'source'")):
        d = base()
        next(r for r in d['custom']['rooms'] if r['id'] == 'gate_island')['animation'] = bad
        expect_error(f"anim: {bad!r} rejected", d, needle)
    d = base()
    next(r for r in d['custom']['rooms'] if r['id'] == 'gate_island').pop('animation')
    outs, _p, w = compile_data(d)
    ok("anim: absent = legacy Castle ($00) + a warning",
       'db $00  ; $6B — legacy' in outs['patches/bank_071.asm']
       and any('no `animation` set' in x for x in w), f"(got {w})")

    # S100 (P3.7b part 1): custom rooms served on gate floors
    def gdata():
        d = base()
        return d, next(r for r in d['custom']['rooms'] if r['id'] == 'gate_rotation')
    d, _g = gdata()
    outs, _p, w = compile_data(d)
    b71 = outs['patches/bank_071.asm']
    ok("gates: example rule -> GateInsertTable row (gate 1, floors 2-3 = 0-based 1-2, 50%, once bit $01, $6D, $0048/$0068)",
       'db $01, $01, $02, $32, $01, $6D, $48, $00, $68, $00, $00' in b71, "(table missing)")
    ok("gates: entries 4/5 in the template + ROOMFLAGS_TABLE_LEN",
       'dw CustomGateInsert' in b71 and 'dw CustomRoomFlags' in b71
       and 'ROOMFLAGS_TABLE_LEN EQU' in b71)
    ok("gates: stairs-down row keeps the descent bytes",
       'db $05, $03, $00, $80, $00, $00, $00' in outs['patches/bank_060.asm'])
    d, g = gdata()
    g['screens']['0']['exits'] = [{'x': 5, 'y': 3, 'stairs': 'down'}]
    outs, _p, w = compile_data(d)
    ok("gates: compact {x, y, stairs: down} fills the descent bytes",
       'db $05, $03, $00, $80, $00, $00, $00  ; stairs down (next gate floor)'
       in outs['patches/bank_060.asm'])
    d, g = gdata()
    d['custom']['gate_inserts'].append({'room': 'gate_rotation', 'gate': 5,
        'floors': [2, 4], 'chance': 100, 'once_per_dive': True,
        'when': [{'flag': '0x0158', 'is': 'clear'}]})
    outs, _p, w = compile_data(d)
    b71 = outs['patches/bank_071.asm']
    ok("gates: once-per-dive bit + a CLEAR term (bit 15)",
       'db $05, $01, $03, $64, $01, $6D, $48, $00, $68, $00, $01' in b71
       and 'dw $8158' in b71, "(row/term missing)")
    d, g = gdata()
    d['custom']['gate_inserts'][0]['floors'] = [1, 2]
    expect_error("gates: floor 1 rejected (the first floor stays the gate's)", d, "start at floor 2")
    d, g = gdata()
    d['custom']['gate_inserts'][0]['floors'] = [4, 5]
    expect_error("gates: the boss floor rejected", d, "is its boss floor")
    d, g = gdata()
    d['custom']['gate_inserts'][0]['chance'] = 0
    expect_error("gates: chance 0 rejected", d, "chance must be 1-100")
    d, g = gdata()
    g.pop('gate_arrival')
    expect_error("gates: a served room needs gate_arrival", d, "no gate_arrival")
    d, g = gdata()
    g['screens']['0']['exits'] = []
    expect_error("gates: a served room needs a Stairs down exit", d, "no Stairs down exit")
    d, g = gdata()
    g['encounters'] = {'enabled': True, 'gate_id': 0, 'floor': 1}
    expect_error("gates: a FIXED encounter pool in a gate room rejected", d, "FIXED encounter pool")
    d, g = gdata()
    g['encounters'] = {'enabled': True, 'follow_gate': True}
    outs, _p, w = compile_data(d)
    ok("gates: follow_gate encounters -> RoomEncTable gate byte $FF",
       'db $01, $FF, $00  ; $6D — enabled, follows the gate being dived'
       in outs['patches/bank_071.asm'])
    d, g = gdata()
    g['can_save'] = False
    outs, _p, w = compile_data(d)
    ok("gates: can_save false -> CustomRoomFlagsTable bit 0",
       'db $01  ; $6D — no saving' in outs['patches/bank_071.asm'])
    d, g = gdata()
    g['screens']['0']['exits'][0]['gate_flag'] = '0x00'
    g['screens']['0']['exits'][0]['stairs'] = 'down'
    expect_error("gates: a stairs row with other bytes rejected", d, "stairs-down")
    d, g = gdata()
    d['custom']['gate_inserts'] = [
        {'room': 'gate_rotation', 'gate': 1, 'floors': 'all', 'chance': 100},
        {'room': 'gate_rotation', 'gate': 1, 'floors': [3], 'chance': 20}]
    outs, _p, w = compile_data(d)
    ok("gates: a rule shadowed by an earlier 100 % rule warns",
       any('can never be served' in x for x in w), f"(got {w})")
    ok("gates: 'all' = floors 2 .. floors-1 (Villager: 2-4 -> 0-based 1-3)",
       'db $01, $01, $03, $64' in outs['patches/bank_071.asm'])
    d, g = gdata()
    next(r for r in d['custom']['rooms'] if r['id'] == 'gate_island')['screens']['0']['exits'][0]['dest'] = 'room:$6D'
    outs, _p, w = compile_data(d)
    ok("gates: a served room also reachable by a door warns (stairs outside a dive)",
       any('also reachable by a door' in x for x in w), f"(got {[x for x in w if 'gate' in x]})")
    d, g = gdata()
    for i in range(9):
        d['custom']['gate_inserts'].append({'room': 'gate_rotation', 'gate': 7,
            'floors': [2], 'chance': 10, 'once_per_dive': True})
    expect_error("gates: max 8 once-per-dive rules per gate", d, "more than 8 once-per-dive")

    # ---------------- S101 (P3.7b part 2): boss floors, gate settings,
    # monster NPCs, conversation steps (battle / helper exit / arrival)
    def bdata():
        d = base()
        c = d['custom']
        isl = next(r for r in c['rooms'] if r['id'] == 'gate_island')
        isl.pop('encounters', None)
        isl['gate_arrival'] = {'screen': 4, 'x': 3, 'y': 2}
        isl['music'] = '0x0C'
        c['gates'] = [{'gate': 1, 'floors': 3, 'boss': 'gate_island'}]
        for g in c['gate_inserts']:
            g['floors'] = [2, 2]
        return d, isl
    d, isl = bdata()
    outs, _p, w = compile_data(d)
    b16 = outs['patches/bank_016.asm']
    ok("gates16: Villager row = floors 3, boss $6B, arrival TILE (3,10) (screen 4 = row 1)",
       'db $01, $01, $01, $03, $6B, $03, $0A, $01' in b16, "(row missing)")
    ok("gates16: untouched gates keep their vanilla rows",
       'db $00, $00, $00, $05, $30, $07, $02, $01' in b16)
    ok("boss room defaults to no saving (CustomRoomFlagsTable bit 0)",
       'db $01  ; $6B — no saving' in outs['patches/bank_071.asm'])
    d, isl = bdata()
    d['custom']['gates'][0]['floors'] = 1
    expect_error("gates: floors below 2 rejected", d, "floors must be 2-99")
    d, isl = bdata()
    d['custom']['gates'][0]['boss'] = 'nobody'
    expect_error("gates: boss must be a custom room", d, "is not a custom room")
    d, isl = bdata()
    isl.pop('gate_arrival')
    expect_error("gates: a boss room needs gate_arrival", d, "has no gate_arrival")
    d, isl = bdata()
    d['custom']['gates'][0]['boss'] = 'vanilla:$35'
    outs, _p, w = compile_data(d)
    ok("gates: a vanilla boss room reused takes its home gate's arrival (Bazaar $35 -> (1,6))",
       'db $01, $01, $01, $03, $35, $01, $06, $01' in outs['patches/bank_016.asm'])
    d, isl = bdata()
    d['custom']['gate_inserts'][0]['floors'] = [1, 2]
    expect_error("gates: floor 1 still rejected on a normal gate", d, "start at floor 2")
    d['custom']['gates'][0]['hand_made'] = True
    outs, _p, w = compile_data(d)
    ok("gates: hand-made gate takes floor 1 (0-based 0) rules",
       'db $01, $00, $01, $32' in outs['patches/bank_071.asm'])
    ok("gates: hand-made gate warns for a floor with no always-served room",
       any('hand-made but floor' in x for x in w), f"(got {[x for x in w if 'hand' in x]})")
    # monster NPCs
    d, isl = bdata()
    isl['screens']['0']['npcs'].append({'kind': 'npc', 'monster': 28, 'x': 4, 'y': 2,
                                        'script': 'none'})
    isl['screens']['0']['npcs'].append({'kind': 'npc', 'monster': 200, 'x': 6, 'y': 2,
                                        'script': 'none'})
    outs, _p, w = compile_data(d)
    b60 = outs['patches/bank_060.asm']
    ok("monster NPCs: sprite $F0/$F1 + the screen cast [$2C,1,$D8,1,$FF,0,$FF,0]",
       'db $00, $F0, $04, $02, $FF' in b60 and 'db $00, $F1, $06, $02, $FF' in b60
       and 'db $2C, $01, $D8, $01, $FF, $00, $FF, $00' in b60)
    for k, sp in enumerate((1, 2, 3)):
        isl['screens']['0']['npcs'].append({'kind': 'npc', 'monster': sp, 'x': k, 'y': 5,
                                            'script': 'none'})
    expect_error("monster NPCs: at most 4 species per screen", d, "more than 4 different monster")
    # conversation steps
    d, isl = bdata()
    c = d['custom']
    c['dialogue'] += [{'id': 't_hi', 'boxes': [['Hi']]},
                      {'id': 't_q', 'boxes': [['Fight?']], 'choice': True},
                      {'id': 't_win', 'boxes': [['Won']]},
                      {'id': 't_bye', 'boxes': [['Home!']]}]
    c.setdefault('flags', []).append({'name': 'test_cleared', 'index': 'auto'})
    c['scripts'].append({'id': 'conv', 'talk': {'steps': [
        {'if': [{'flag': 'test_cleared'}], 'then': [{'say': 't_win'}, {'end': True}]},
        {'ask': 't_q', 'yes': [{'battle': {'enemies': [11, 31]}}, {'say': 't_win'},
                               {'set': ['test_cleared']},
                               {'helper': {'dest': 'vanilla:$00', 'screen': 1, 'x': 4,
                                           'y': 5, 'say': 't_bye',
                                           'land': {'x': 3, 'y': 3}}}],
         'no': [{'say': 't_hi'}]}]}})
    isl['screens']['0']['npcs'].append({'kind': 'npc', 'monster': 28, 'x': 4, 'y': 2,
                                        'script': 'conv'})
    isl['scripts'][str(max(int(k) for k in isl['scripts']) + 1)] = 'conv'
    outs, _p, w = compile_data(d)
    b60 = outs['patches/bank_060.asm']
    ok("conversation: helper NPC appended hidden at (0,0) with Warubou's sprite $39 (S101 r2)",
       'db $70, $39, $00, $00, $FF' in b60)
    ok("conversation: a fixed landing cell places the helper by pixels (screen 0: 3,3 -> "
       "start (8,13) = land - (48,43))",
       'dw $0008' in b60 and 'dw $000D' in b60 and '; branch_screen' in b60)
    d3 = json.loads(json.dumps(d))
    d3['custom']['scripts'][-1]['talk']['steps'][1]['yes'][3]['helper'].pop('land')
    o3, _p, _w = compile_data(d3)
    b3 = o3['patches/bank_060.asm']
    d4 = json.loads(json.dumps(d))
    hs = d4['custom']['scripts'][-1]['talk']['steps'][1]['yes'][3]['helper']
    hs.update({'castle': 'king', 'king_speech': 0x31})
    o4, _p, _w = compile_data(d4)
    b4 = o4['patches/bank_060.asm']
    j = b4.index('dw $FF3B  ; warp_fade')
    ok("conversation: castle 'king' = $D9E3 := speech, $D92B := 7 right before the $3B warp "
       "(S101 r3, the castle-arrival chain)",
       b4.rfind('dw $D9E3', 0, j) > b4.rfind('dw $FF06', 0, j) and
       b4.rfind('dw $D92B', 0, j) > b4.rfind('dw $D9E3', 0, j) and '$0031' in b4[j - 200:j])
    hs.update({'castle': 'heal'})
    hs.pop('king_speech')
    o4, _p, _w = compile_data(d4)
    b4 = o4['patches/bank_060.asm']
    j = b4.index('dw $FF3B  ; warp_fade')
    ok("conversation: castle 'heal' = $D92B := 6 (the priest's blessing + heal)",
       'dw $D92B' in b4[j - 60:j] and '$0006' in b4[j - 60:j])
    hs.update({'dest': 'room:$6C', 'screen': 0})
    expect_error("conversation: a castle event needs the Castle throne destination", d4,
                 "needs the destination")
    ok("conversation: default landing = beside the player — byte compares on $FF97 / $FF98 "
       "for screen 0's 10 columns / 8 rows, a face-left branch for column 0",
       b3.count('dw $FF97') == 10 + 2 and b3.count('dw $FF98') == 8)
    ok("conversation: 2-enemy boss battle = write_ram2 $DA03/$DA05 + $DA02 + op $5B",
       all(t in b60 for t in ('dw $DA03', 'dw $DA05', '$FF5B  ; boss_battle')))
    ok("conversation: the helper exit ends in the wavy warp $3B to Castle (232,88)",
       'dw $FF3B  ; warp_fade' in b60 and 'dw $00E8' in b60 and 'dw $0058' in b60)
    ok("conversation: the win text re-enters dialog mode (init_dialog after the battle)",
       b60.index('$FF5B') < b60.index('$FF07', b60.index('$FF5B')))
    d2 = json.loads(json.dumps(d))
    d2['custom']['scripts'][-1]['talk']['steps'][1]['ask'] = 't_hi'
    expect_error("conversation: an ask needs a choice dialogue", d2, "choice box")
    d2 = json.loads(json.dumps(d))
    d2['custom']['scripts'][-1]['talk']['steps'][1]['yes'][0]['battle']['enemies'] = [500]
    expect_error("conversation: EIDs 487-517 do not exist", d2, "does not exist")
    d2 = json.loads(json.dumps(d))
    d2['custom']['scripts'][-1]['talk']['steps'].append({'say': 't_hi', 'move': {}})
    expect_error("conversation: a step has exactly one kind", d2, "exactly one of")
    # arrival conversation: screen guard + field-context text
    d, isl = bdata()
    c = d['custom']
    c['dialogue'] += [{'id': 't_hi', 'boxes': [['Hi']]}]
    c['scripts'].append({'id': 'arr', 'talk': {'on_arrival': True, 'screen': 4,
                                                'steps': [{'say': 't_hi'}]}})
    isl['scripts']['0'] = 'arr'
    outs, _p, w = compile_data(d)
    b60 = outs['patches/bank_060.asm']
    i0 = b60.index('$FF0E  ; branch_screen')
    ok("arrival conversation: branch_screen 4 guard, then init_dialog + text",
       b60.index('$FF07  ; init_dialog', i0) > i0)

    # S100 r3: the game adds 19 to the extended copy length in 8 bits (dec/jr
    # nz loop: 0 = 256), so no copy may exceed 256 bytes — an imported blank
    # sheet (900+ leading zero bytes) came out shifted 256 bytes in-game
    from editor2.core import layouts as LZ
    sheet = bytearray(2048)
    for t in range(58, 74):
        sheet[t * 16:t * 16 + 16] = bytes(range(t, t + 16))
    blob = LZ.compress(REPO, bytes(sheet))
    ok("LZSS: a sheet with a 928-byte zero run decodes exactly with the game-accurate decoder",
       LZ.decompress_raw(REPO, blob) == bytes(sheet))
    longest, i, mk = 0, 3, blob[2]
    while i < len(blob):
        if blob[i] == mk:
            ctl = blob[i + 2]
            n = (ctl & 0x0F) + 4
            if n == 0x13:
                n = blob[i + 3] + 0x13
                i += 1
            longest = max(longest, n)
            i += 3
        else:
            i += 1
    ok("LZSS: no back-reference longer than 256 bytes", 0 < longest <= 256, f"(longest {longest})")

    ok("text ids map to CustomText_XX labels",
       prj.text_label(0x0A14) == 'CustomText_14')

    test_tile_anims()
    test_gamedata()
    test_species_and_skills()
    test_monsters_s106()
    outart = test_art_s107()
    outlay = test_walk_layouts_s107()
    outicon = test_family_icons_s107()
    outmt = test_monster_text_s108()
    outar = test_arena_s109()

    if '--rom' in sys.argv:
        from editor2.core import builder as B
        outdir = '/tmp/_t_regression'
        C.write_outputs(out1, outdir)
        rom, sym, md5 = B.build_rom(REPO, outdir, os.path.join(outdir, 'build'))
        ok("REGRESSION: byte-identical to the pinned reference",
           md5 == REFERENCE_MD5, f"(got {md5})")
        # S105 G3: the new-species forks, executed from the ROM's bytes
        test_species_forks_rom('example', open(rom, 'rb').read(), B.parse_sym(sym),
                               {224: 'Gorbunok'})
        # ... and a project that fills all 19 ids (8-letter names, 4-letter
        # nicknames, families spread — every bank it touches must still fit)
        fams = ['Slime', 'Dragon', 'Beast', 'Bird', 'Plant', 'Bug', 'Devil', 'Zombie',
                'Material', 'Boss', 'Spirit']
        L = 'abcdefghijklmnopqrstuvwxyz'
        dmax = _species_fixture([])
        g0 = dmax['custom']['species'][0]
        dmax['custom']['species'] = []
        for k, sid in enumerate(range(221, 240)):
            e = json.loads(json.dumps(g0))
            e.update(id=sid, name='X' + L[k] * 7, short_name='Y' + L[k] * 3)
            e['info']['family'] = fams[k % len(fams)]
            dmax['custom']['species'].append(e)
        outm, _, _ = compile_data(dmax)
        outdirm = '/tmp/_t_species_max'
        C.write_outputs(outm, outdirm)
        romm, symm, _mm = B.build_rom(REPO, outdirm, os.path.join(outdirm, 'build'))
        test_species_forks_rom('19 species', open(romm, 'rb').read(), B.parse_sym(symm),
                               {sid: 'X' + L[k] * 7 for k, sid in enumerate(range(221, 240))})
        # S103 (P3.9): per-table regression on REAL ROM bytes — an empty
        # gamedata puts every owned table back to the original ROM's bytes
        orig_rom = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
        outs0, _, _ = compile_data(gd_fixture({}))
        outdir0 = '/tmp/_t_gd_empty'
        C.write_outputs(outs0, outdir0)
        rom0, sym0, _m0 = B.build_rom(REPO, outdir0, os.path.join(outdir0, 'build'))
        built0 = open(rom0, 'rb').read()
        from editor2.core import gamedata as GDm
        V0 = GDm.vanilla(REPO)
        for tname, tb in V0['tables'].items():
            o = tb['bank'] * 0x4000 + (tb['addr'] - 0x4000 if tb['bank'] else tb['addr'])
            n = len(tb['rows']) * tb['stride']
            if tname == 'special_recipes':
                continue            # runtime-dead $16 copy (not owned); bank $69 below
            ok(f"ROM: empty gamedata -> {tb['label']} == original ROM bytes",
               built0[o:o + n] == orig_rom[o:o + n])
        lb = bytes.fromhex(V0['library']['block'])
        lo = 0x4D * 0x4000 + V0['library']['block_addr'] - 0x4000
        ok("ROM: empty gamedata -> library recipe text == original ROM bytes",
           built0[lo:lo + len(lb)] == lb)
        s69 = B.parse_sym(sym0)['RelocatedSpecialTable']
        fo = s69[0] * 0x4000 + s69[1] - 0x4000
        spo = 0x16 * 0x4000 + 0x0B30
        if True:
            ok("ROM: empty gamedata -> bank $69 special table == the vanilla 825 + $FF",
               built0[fo:fo + 825 * 5 + 1] == orig_rom[spo:spo + 825 * 5 + 1])
        # S101: the emitter's copy of the 34 vanilla fight->join pairs must
        # equal the ROM's BossRedirectTable ($14:$4893)
        from editor2.core import emitters as EM
        orig = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
        o = 0x14 * 0x4000 + 0x0893
        pairs = [(orig[o + 4 * i] | orig[o + 4 * i + 1] << 8,
                  orig[o + 4 * i + 2] | orig[o + 4 * i + 3] << 8) for i in range(35)]
        ok("VANILLA_REDIRECTS == the ROM's BossRedirectTable (34 pairs + $FFFF)",
           pairs[:34] == EM.VANILLA_REDIRECTS and pairs[34][0] == 0xFFFF)
        # S70 no-op property: strip progression + the extension + the quest
        # room/dialogue/music -> the bank $14 region must regenerate the
        # vanilla ds-308 pad and the ROM delta stays out of bank $14
        # entirely (region byte-identity = the emitter's no-op contract).
        d = base()
        # S105: keep progression.enemies — gamedata pool 0 names the
        # example's gorbunok_wild project enemy; only the QUEST goes
        d['progression'].pop('quests')
        d['custom'].pop('vanilla_exit_extensions')
        # S92: the prelude targets entry:medal_vault, which only exists via
        # quest lowering — dangling preludes hard-error (correctly), so the
        # no-quest fixture strips it with the quest content.
        d['custom'].pop('script_preludes', None)
        d['custom']['rooms'] = [r for r in d['custom']['rooms']
                                if r['id'] != 'medal_vault']
        d['custom']['dialogue'] = [x for x in d['custom']['dialogue']
                                   if not x['id'].startswith('vault_')]
        d['custom']['music']['songs'] = [
            s for s in d['custom']['music']['songs'] if s['id'] != 'dwm2_bgm10']
        outs, _, _ = compile_data(d)
        outdir2 = '/tmp/_t_noquest'
        C.write_outputs(outs, outdir2)
        rom2, _, md5f = B.build_rom(REPO, outdir2, os.path.join(outdir2, 'build'))
        ref = open(rom, 'rb').read(); fix = open(rom2, 'rb').read()
        diffs = [i for i in range(len(ref)) if ref[i] != fix[i]]
        banks = {i // 0x4000 for i in diffs}
        # S101: project enemies moved to bank $6B; the bank-$14 tail is the
        # LoadEnemyStats divert + BossRedirectTableExt (vanilla rows only
        # without join_as) — identical in both builds (no join_as either way)
        ok("no-quest build: the bank-$14 tail (divert + redirect table) is unchanged",
           all(fix[0x14 * 0x4000 + 0x3ECC + k] == ref[0x14 * 0x4000 + 0x3ECC + k]
               for k in range(308)))
        ok("no-quest build: bank $6B keeps one zero row",
           fix[0x6B * 0x4000:0x6B * 0x4000 + 1] == b'\x6b')
        ok("no-quest delta confined to owned banks + header",
           banks <= {0, 0x14, 0x17, 0x60, 0x6B, 0x71, 0x74} and
           all(o in (0x14D, 0x14E, 0x14F) for o in diffs if o < 0x4000),
           f"(diff banks {sorted(hex(b) for b in banks)})")

        # S107 (P3.10 part 2a): a project with art, built — the ROM bytes at
        # every table (the bank-$0B copy sits at $4914 in the patched build:
        # addresses come from game.sym), the stream behind each gfx-ID, and
        # TERRY? / the summons (215-220) untouched (Iron Rule 8)
        from editor2.core import art as Am
        from dwm import sprite_codec as SCm
        outdira = '/tmp/_t_art'
        C.write_outputs(outart, outdira)
        roma, syma, _ma = B.build_rom(REPO, outdira, os.path.join(outdira, 'build'))
        ra = open(roma, 'rb').read()
        sya = B.parse_sym(syma)

        def rw(bank, addr):
            o = bank * 0x4000 + (addr - 0x4000 if bank else addr)
            return ra[o] | ra[o + 1] << 8

        ok("ROM art: battle gfx [9] = $7F00, [215]-[220] = the original words",
           rw(0, 0x2B9F + 18) == 0x7F00 and
           all(ra[0x2B9F + 2 * i:0x2BA1 + 2 * i] == orig_rom[0x2B9F + 2 * i:0x2BA1 + 2 * i]
               for i in range(215, 221)))
        starts = {0x01: ('ScreenTransDataTable', 32), 0x06: ('FollowerGfxTable06', 32),
                  0x07: ('FollowerGfxTable07', 32), 0x09: ('FollowerGfxTable09', 32),
                  0x0B: ('FollowerGfxTable0B', 32), 0x12: ('FollowerGfxTable12', 32),
                  0x18: ('FollowerGfxTable18', 0), 0x59: ('FollowerGfxTable59', 0)}
        for bk, (lbl, off) in starts.items():
            b_, a_ = sya[lbl]
            ok(f"ROM art: walking table ${bk:02X} ({lbl} @ ${a_:04X}): [9] = $7F01, [214] = $7F02",
               b_ == bk and rw(bk, a_ + off + 18) == 0x7F01 and rw(bk, a_ + off + 428) == 0x7F02)
        ok("ROM art: $10:$407F[9] = $4E33 (layout 0), $10:$417F[9] = 5; $11:$407F[86] = $4184",
           rw(0x10, 0x407F + 18) == 0x4E33 and ra[0x10 * 0x4000 + 0x17F + 9] == 5
           and rw(0x11, 0x407F + 172) == 0x4184)
        for gid, want in ((0x7F00, 576), (0x7F01, 256), (0x7F02, 256)):
            off = SCm.gfxid_stream_offset(ra, gid)[3]
            ok(f"ROM art: gfx-ID ${gid:04X} resolves to a stream of {want} bytes",
               len(SCm.decode(SCm.read_stream(ra, off))) == want)
        ok("ROM art: battle palette [9] at $17:$62FD+72",
           ra[0x17 * 0x4000 + 0x22FD + 72:0x17 * 0x4000 + 0x22FD + 80] == bytes.fromhex('3412ff6b21430000'))
        # S107 (P3.10 part 2b): the layouts project, built — every chosen
        # layout is what the game reads through the level-1 entry (native or
        # copied), for originals of both banks and the new species
        from editor2.core import walk_layouts as WLm
        outdirl = '/tmp/_t_lay'
        C.write_outputs(outlay, outdirl)
        roml, syml, _ml = B.build_rom(REPO, outdirl, os.path.join(outdirl, 'build'))
        rl = open(roml, 'rb').read()
        syl = B.parse_sym(syml)

        def rwl(bank, addr):
            o = bank * 0x4000 + addr - 0x4000
            return rl[o] | rl[o + 1] << 8

        def want(lid):
            return [sorted(x) for x in WLm.entries(lid).values()]
        only10 = [L['id'] for L in WLm.data()['layouts'] if list(L['instances']) == ['10']]
        only11 = [L['id'] for L in WLm.data()['layouts'] if list(L['instances']) == ['11']]
        both = [L['id'] for L in WLm.data()['layouts'] if len(L['instances']) == 2 and L['id']]
        nl2 = rwl(0x11, syl['NewFollowerL1Table'][1] + 2 * 3)
        checks = [('9 (bank $10, copied)', 0x10, rwl(0x10, 0x407F + 18), only11[0]),
                  ('10 (bank $10, native)', 0x10, rwl(0x10, 0x407F + 20), both[0]),
                  ('200 (bank $11, copied)', 0x11, rwl(0x11, 0x407F + 2 * 72), only10[0]),
                  ('201 (bank $11, layout 0)', 0x11, rwl(0x11, 0x407F + 2 * 73), 0),
                  ('224 Gorbunok (NewFollowerL1Table)', 0x11, nl2, only10[0])]
        for what, bk, l2, lid in checks:
            ok(f"ROM 2b: species {what} -> ${bk:02X}:${l2:04X} draws layout {lid}",
               _layout_sig_rom(rl, bk, l2) == want(lid))
        ok("ROM 2b: the copies sit in the banks' free tails",
           rwl(0x10, 0x407F + 18) >= WLm.COPY_START[0x10] and nl2 >= WLm.COPY_START[0x11])
        ok("ROM 2b: walk_layouts.COPY_START[$11] == the built FollowerLayoutBase11 end",
           syl['FollowerLayoutBase11.done'][1] + 2 == WLm.COPY_START[0x11])
        ok("ROM 2b: FollowerLayoutBase11 is called by both bank-$11 entries "
           "(call at $4008 / $4012)",
           rl[0x11 * 0x4000 + 0x0008] == 0xCD and rwl(0x11, 0x4009) == syl['FollowerLayoutBase11'][1]
           and rl[0x11 * 0x4000 + 0x0012] == 0xCD and rwl(0x11, 0x4013) == syl['FollowerLayoutBase11'][1])

        # S107 (P3.10 part 2c): the icons project, built — the font glyph,
        # both gfx streams decode to the authored tiles; the saved-party
        # readers of banks $07 / $0A far-call FamilyIconGfxFromE (the fork
        # bytes `ld e,a / push bc / ld hl,$6D01 / rst $10 / pop bc` + 6 nops)
        from editor2.core import gamedata as Gm
        outdiri = '/tmp/_t_icon'
        C.write_outputs(outicon, outdiri)
        romi, symi, _mi = B.build_rom(REPO, outdiri, os.path.join(outdiri, 'build'))
        ri = open(romi, 'rb').read()
        ta = Gm.icon_tile(Gm.icon_grid(ICON_A, 'a'))
        ts = Gm.icon_tile(Gm.icon_grid(ICON_S, 's'))
        ok("ROM 2c: font glyphs $4F:$4110 (Slime) / $41B0 (Spirit) = the authored tiles",
           ri[0x4F * 0x4000 + 0x110:][:16] == ta and ri[0x4F * 0x4000 + 0x1B0:][:16] == ts)
        ok("ROM 2c: gfx ids $2E03 / $6D04 decode to the authored tiles",
           SCm.decode(SCm.read_stream(ri, SCm.gfxid_stream_offset(ri, 0x2E03)[3])) == ta and
           SCm.decode(SCm.read_stream(ri, SCm.gfxid_stream_offset(ri, 0x6D04)[3])) == ts)
        fork = bytes.fromhex('5fc52101 6dd7c1'.replace(' ', '')) + bytes(6)
        # S108: names / nicknames / descriptions read back through the tables
        outdirt = '/tmp/_t_monster_text'
        C.write_outputs(outmt, outdirt)
        romt, symt, _mt5 = B.build_rom(REPO, outdirt, os.path.join(outdirt, 'build'))
        test_monster_text_rom(open(romt, 'rb').read(), B.parse_sym(symt))
        # S109: the arena fixture, built — tables, call sites, the engine routine
        outdira = '/tmp/_t_arena'
        C.write_outputs(outar, outdira)
        roma, syma, _ma = B.build_rom(REPO, outdira, os.path.join(outdira, 'build'))
        test_arena_rom(open(roma, 'rb').read(), B.parse_sym(syma))
        n07 = ri[0x07 * 0x4000:0x08 * 0x4000].count(fork)
        n0a = ri[0x0A * 0x4000:0x0B * 0x4000].count(fork)
        ok("ROM 2c: the JOURNAL ($07) and its $0A twin read the saved party's icon through "
           "bank $6D (1 fork in $07; 2 in $0A with the S104 list fork)", n07 == 1 and n0a == 2,
           f"({n07}, {n0a})")

        # S105 (P3.9b acceptance): a BLANK project (File > New project) builds
        # the ORIGINAL ROM's bytes at every new-species site and at every POC
        # site purged this session — names, text, art, info, tables.
        outb, _, _ = compile_data(json.load(open(BLANK)))
        outdirb = '/tmp/_t_blank'
        C.write_outputs(outb, outdirb)
        romb, symb, _mb = B.build_rom(REPO, outdirb, os.path.join(outdirb, 'build'))
        bb = open(romb, 'rb').read()
        sy = B.parse_sym(symb)

        def at(bank, addr, n):
            o = bank * 0x4000 + (addr - 0x4000 if bank else addr)
            return bb[o:o + n] == orig_rom[o:o + n]

        def lab(name, n):
            bk, ad = sy[name]
            return at(bk, ad, n)
        sites = [('battle gfx-IDs [221]-[239] $00:$2D59', at(0, 0x2B9F + 221 * 2, 38)),
                 ('name pointers [221]-[239] $41:$44F3', at(0x41, 0x4339 + 221 * 2, 38)),
                 ('SpellUseText_11 tail $41:$7E06-$7E15 (restored S105)', at(0x41, 0x7E06, 16)),
                 ('bank $41 text extent a $7E38-$7E4E', at(0x41, 0x7E38, 23)),
                 ('bank $41 $7E86-$7F7F (text extents b / c + nickname pointers $7EF3)',
                  at(0x41, 0x7E86, 0x7F80 - 0x7E86)),
                 ('bank $41 $7FF6-$7FFF (text extent d)', at(0x41, 0x7FF6, 10)),
                 ('bank $41 MiscText_03 $728B (text extent e)', at(0x41, 0x728B, 22)),
                 ('detail/recipe words $4D HighLine2Ptrs', lab('HighLine2Ptrs', 4 + 19)),
                 ('info slots 0-18 $6A', lab('NewSpeciesHighInfoTable', 43 * 19)),
                 ('battle palettes $17 NewBattlePalTable', lab('NewBattlePalTable', 8 * 19)),
                 ('recipe pairs $16', lab('NewRecipePairs', 2 * 19)),
                 ('follower attr table $11', lab('NewFollowerAttrTable', 19)),
                 ('follower layout table $11 (S107 2b)', lab('NewFollowerL1Table', 2 * 19)),
                 ('bank $10 zero tail $7A83-$7FFF (layout copies, S107 2b)', at(0x10, 0x7A83, 0x8000 - 0x7A83)),
                 ('family icon glyphs $4F:$4110-$41AF (S107 2c)', at(0x4F, 0x4110, 160)),
                 ('family icon streams $2E:$424A-$42F7 (S107 2c)', at(0x2E, 0x424A, 190)),
                 ('bank $11 zero tail (layout copies, S107 2b)',
                  at(0x11, sy['FollowerLayoutBase11.done'][1] + 2, 0x8000 - sy['FollowerLayoutBase11.done'][1] - 2)),
                 ('ChopClown / Grendal attr $11:$413F', at(0x11, 0x413F, 2)),
                 ('bank $14 free tail $7EAD-$7ECB (old EID 518)', at(0x14, 0x7EAD, 31)),
                 ('special table entries 693 / 803 (S12 mirror)',
                  at(0x16, 0x58B9, 5) and at(0x16, 0x5ADF, 5)),
                 ('bank $36 (Dracky battle sprite; S21 Clam POC)', at(0x36, 0x4000, 0x4000)),
                 ('bank $7E (all zero)', at(0x7E, 0x4000, 0x4000)),
                 ('art banks $7A / $7C / $7F (all zero; S107)',
                  at(0x7A, 0x4000, 0x4000) and at(0x7C, 0x4000, 0x4000) and at(0x7F, 0x4000, 0x4000)),
                 ('the eight walking tables (S107; the bank-$0B copy at its patched address)',
                  all(bb[sy[l][0] * 0x4000 + sy[l][1] - 0x4000 + o:][:430] ==
                      orig_rom[0x01 * 0x4000 + 0x09FF:][:430]
                      for l, o in (('ScreenTransDataTable', 32), ('FollowerGfxTable06', 32),
                                   ('FollowerGfxTable07', 32), ('FollowerGfxTable09', 32),
                                   ('FollowerGfxTable0B', 32), ('FollowerGfxTable12', 32),
                                   ('FollowerGfxTable18', 0), ('FollowerGfxTable59', 0)))),
                 ('bank $10 layout + attr tables (S107)', at(0x10, 0x407F, 384)),
                 ('bank $11 layout + attr tables (S107)', at(0x11, 0x407F, 174 + 87)),
                 ('monster names $41:$5B1F-$628D (S108)', at(0x41, 0x5B1F, 1903)),
                 ('default nicknames $41:$69F2-$6C76 (S108)', at(0x41, 0x69F2, 645)),
                 ('descriptions $4D:$53D3-$7719 (S108)', at(0x4D, 0x53D3, 9031)),
                 ('arena masters $04:$5E22 / $50:$6778, class fees $09:$5D23 (S109)',
                  at(0x04, 0x5E22, 60) and at(0x50, 0x6778, 54) and at(0x09, 0x5D23, 16)),
                 ('arena team sizes all 3 (S109, bank $6E)',
                  bb[0x6E * 0x4000 + sy['ArenaTeamSizeTable'][1] - 0x4000:][:30] == bytes([3] * 30))]
        for what, good in sites:
            ok(f"ROM: blank project -> {what} == original ROM bytes", good)

        # S106: the shared LZ decoder reproduces the manifest of every monster
        # stream (extracted/monster_sprites.json — == the game's own
        # decompressor for all 442, tools/census_lz_decode.py in PyBoy)
        from dwm import sprite_codec as SC
        ms = json.load(open(os.path.join(REPO, 'extracted', 'monster_sprites.json')))['monsters']
        bad = []
        for sid in range(221):
            for kind in ('battle', 'follower'):
                gid = int(ms[str(sid)][kind]['gfx_id'][1:], 16)
                off = SC.gfxid_stream_offset(orig_rom, gid)[3]
                if SC.decode(SC.read_stream(orig_rom, off)).hex() != ms[str(sid)][kind]['tile_bytes_hex']:
                    bad.append((sid, kind))
        ok("ROM: S106 LZ decode of all 442 monster streams == extracted/monster_sprites.json",
           not bad, str(bad[:5]))

    if os.path.exists(os.path.join('/tmp/_t_regression', 'build', 'rom.gbc')):
        test_crash_config_validator()
        ok("crash-config validator PASS/FAIL behavior", True)
    else:
        # pre-S92 the call was unconditional and failed on any fresh machine
        # without --rom (it consumes the --rom regression build's rom.gbc)
        print("  skip: crash-config validator (needs --rom build)")
    print(f"\nALL {PASS} TESTS PASSED")


if __name__ == '__main__':
    main()
