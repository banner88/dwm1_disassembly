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
REFERENCE_MD5 = "c326fc96e0119503c9c8dd3b065faca6"   # S125 (ROADMAP P3.14d, the hub; built S125, NOT yet user-tested): bank $71 template + entry 9 HubWarp + the HubTable (the example has no custom.hub: one `db $FF`, every send goes to the Castle with the vanilla writes; re-pinned, TEMPLATE_SIZE 865); patches/bank_050.asm ($64AF, $6559), bank_006.asm ($6A25), bank_007.asm ($5012) — the 38-byte Castle writes -> `ld e, HUB_x / ld hl, $7109 / rst $10` (same size); WRAM wHubReason $D2EF carved from wCustomPool. Prev: 6b0738c1c9a2faa917645462ae646022   # S123 r2 (user: the custom gate entrance should run the full start-of-gate whirl, not the floor-change whoosh): bank $60 template + entry 12 CustomDescentFeel (TEMPLATE_SIZE 1293); patches/bank_00b.asm CustomDescentInGate = a far call to it (a custom room's gate ENTRANCE, gate flag 1, keeps wInGateworld 0 = the vanilla portal flow; Stairs down, flag $80, keeps the S41 feel). Prev: e93b23b568069c6b5663378ac03264c1   # S123 (ROADMAP NG3: worlds + NPC colours, built S123, NOT yet user-tested): bank $60 template + entry 11 NpcColourDraw, NpcColourRecord and the $A2 colour prefix in CopyNPCListToBuffer (re-pinned; TEMPLATE_SIZE 1273); bank $06 NPCDrawSlot `ld hl, $0500` -> `$600B` (same size); WRAM wNpcColour.. $D2E3-$D2EE carved from wCustomPool. The example has no worlds and no NPC colours (no $A2 prefix emitted). Prev: bd0652da6d719f060e6d99d26fa2ad10   # S122 (ROADMAP NG2 residual a, built S122, NOT yet user-tested): bank $76 template — GateBossWin rows x6 (+ dw WinTail) and RunWinTail (a re-bossed vanilla gate replays the game's own win bookkeeping); TEMPLATE_SIZE 460; the example re-bosses no vanilla gate (every row $FFFF, $FFFF, $0000). Prev: e43e5f58aafe35fa564c7895f8814bca   # S121 (the Milly hook, ROADMAP P3.16 + E7, built S121, NOT yet user-tested): the example has the hook OFF — patches/bank_04f.asm hero tiles back to the original TERRY (S120b's MILLY now drawn only by the hook, region milly_name_tiles); bank $71 template + entry 8 TextSpriteMode (re-pinned; the bank $06 text_sprite_mode region stays vanilla here — no copy of $08 / $5D in the example). Every other S121 region (banks $01/$04/$09/$0E, bank $79) emits the vanilla text with the hook off. Prev: 97659a4a61c2b536966b1f33719d79a6   # S120b (user: "change TERRY to MILLY as default, but leave otherwise as 4 letters", built S120b, NOT yet user-tested): patches/bank_04f.asm hero-name tiles $D3-$D6 ($4F:$4D40, 64 B, was INCBIN ;TERRY) drawn "MILLY" — the only bytes changed + the header checksum. Prev: d19259a116887ab0516c2bf21ff1b34c   # S119 (ROADMAP P3.8 part B/d, built S119, NOT yet user-tested): bank $04 ScriptCmd24 / ScriptCmd61 bank-$0F far calls SAME-SIZE ($0f01 / $0f02 -> $6009 / $600a) -> bank $60 entries 9 / 10 CustomDrawTiles / CustomDrawAttrs (a custom room's tile patches from bank $60 patch_data; every other script -> bank $0F as before); bank $60 template +entries 9 / 10 (re-pinned). Prev: 110210b0d9e3258474a426f8212d8b4e   # S117b (built S117b, NOT yet user-tested): bank $09 LoadFld9_40fa (the screen push of every bank $09 screen) SAME-SIZE (53 B) -> bank $77 entry 2 ScreenPush (palette attributes in free-colour custom rooms); ShopClose -> ShopBoxBottom (re-seats a top dialog box at the bottom); wPushAttrOn/Row $D241-$D242 from wCustomPool. Prev: 31cc5b31b98e854d55623919640ff949   # S117 (FLAG EXPANSION + ROADMAP NG2 + P3.13c SHOPS, built S117, NOT yet user-tested): shops — bank $09 ShopBuyStockFill choice+copy SAME-SIZE (64 B) -> NEW compiler bank $77 entry 0 ShopFill (wShopID $D240 set by a `shop` script, else the vanilla room rule; ShopPtrTable = the five vanilla lists + custom.shops), the shop close tail SAME-SIZE (10 B) -> entry 1 ShopClose (clears wShopID); ItemInfoTable ($03:$71DA, the old "SpriteFrameDataTable") = region gd_item_info (buy prices); wCustomPool -1 more (wShopID). Then the flags/NG2 engine: built S117, NOT yet user-tested): ROM0 ComputeFlagAddress SAME-SIZE (34 B) -> bank $73 entry 21 FlagAddr (extended flags $1000-$17FF = wExtFlags $D140, saved via SRAM bank 3 "X1" by entries 5/6); bank $0B GetRoomDataPtr SAME-SIZE (21 B) -> bank $60 entry 1 for every non-gate room (CopyNPCListToBuffer: $A0/$A1 condition prefixes -> the hidden bit; VanillaNPCExtTable gate-swirl overrides, empty in the example); bank $50 boss-win branch SAME-SIZE (6 B) -> bank $76 entry 2 GateBossWin (GateClearTable, all $FFFF in the example); bank $73 entry table +1 (every later bank $73 byte shifts 2). Prev: 7bab492185b466d5500ead5b8f1254dc   # S116 (ROADMAP P3.13b the Music tab, built S116, NOT yet user-tested): ROM0 InitBGM SAME-SIZE rewrite (71 B; the vanilla 2-channel id chain -> a 9-byte table scan; ids >= $9E -> bank $71 entry 6 CustomBGMStart = the song's own channel count, CustomBGMChanTable); bank $51 LoadBattle music pick SAME-SIZE (28 B) -> bank $71 entry 7 BattleBGMResolve; bank $71 entry 2 + the gate songs (CustomGateBGMTable, $FF = follow the gate); AudioMasterTableExt rows = region rom0_audio_master (a 5th row [split, $4001, $75] when songs spill); NEW compiler bank $75 (second song bank); the S64 trio padding is gone (the example's songs keep exactly their channels). Prev: c8995d91d8d839ac2f80b3e61b1f38ab   # S115 (ROADMAP NG1 new gates, built S115, test ROM USER-CONFIRMED 2026-10-03 12:39 ("Excellent, confirm works")): bank $16 entry 5's two GateFloorDataTable readers (jr_016_5b72 / jr_016_5be1, 15 B each) are SAME-SIZE calls to GateRowPtr (bank $16 free tail $7CFD): gates 0-31 = the vanilla table, a project NEW gate (32-95) = bank $76 entry 1 NewGateRowCopy -> wGateRowBuf ($D138, 8 B carved from wCustomPool), any other number = the old wrap (gate & 31); bank $76 template +55 B (entry-1 dw, NewGateRowCopy, EncVanillaNumber walks a new gate's source) + NEW_GATE_LEN/NewGateRows/NewGateSource (empty in the example). Prev: dbc4dee947ccc3dbf1fb3092fdf9e143   # S114 (P3.13a, built S114, test ROM USER-CONFIRMED 2026-10-03 09:52 ("Looks good. Give editor files")): bank $01 LoadNextDungeonFloor SAME-SIZE fork (65 B) -> bank $76 EncResolve (NEW compiler bank, template bank_076_head.asm: the vanilla gate+floor rule on byte copies, a gate's own plan, a custom room's own list, flag variants, room rate) + the list copied to wEncListBuf ($D11E); the five list readers (EncounterMonsterSelect x3, SaveRegsForEncounter, LoadFloorAndEncounterData) read wEncListBuf (ld hl / ld bc,0 / pad, same size); the example has no encounter data: census_encounters 633 list choices + 15,192 draws == the model. Prev: 8cf0b93bbb7a91ac27ba4b8de5c40a66   # S113 (P3.12, built S113, NOT yet user-tested): the special breeding table is AUTO-ORDERED (most specific first) whenever a project edits it — the example's 3 overrides + 2 appends move into the species x species block (bank $69 $4050-$5075, 503 B; behaviour per pair unchanged, census_breeding 0/53,056) — + bank $16 BreedCreateOffspring passes the FX1 staging indices $28/$29 (was $14/$15 = farm slots 20/21: every egg +1, no + recipe fired since S71; 2 B at $4072/$4077). Prev: 9ce03bd0e93df966a7000327234af89b   # S112 (P3.11e, built S112, test ROM USER-CONFIRMED 2026-10-02 18:29): the battle-animation engine — bank $6F (CustomAnimTick / Init / Load / Step; compiler file, template bank_06f_head.asm) + bank $70 (sheets) + forks: ROM0 AnimTickSelectAndDraw / AnimStartRenderer ($5E -> $6F, same size), bank $50 AnimLoadFork50, bank $02 ReadSeqStepFork (NEW hand patch), bank $5F AnimRoutineFork / AnimCmdForkDE81 / AnimCmdForkHLA4 + the Effect debugger forks + regions gd_anim_routine / gd_anim_cmd (all $FF = the S111 behaviour, PyBoy A/B identical with the RNG pinned). Prev: 5a1c540487f9043e9d6431685527f1ad   # S111b (built S111, NOT yet user-tested): the built-in custom skills' fixed RATIOS are project data — bank $72 CustomRatioTable (region gd_custom_ratios: MagicBurn burn / damage per MP, Tame damage of ATK, Anchor MP charge, Quake allies' share, Mourn bonus per fallen ally) read by ScaleHL72 (floor(x*n/d), at most 999) in the four handlers + bank $72 entry 7 AnchorKeepMP72 (bank $73 Anchor arrival: rst $10 instead of `>> 2`); defaults = the old constants (PyBoy A/B identical); + CustomTargetBaseTable MagicBurn -> Firebal's row, Tame x3 -> Blaze's (the act-time AI cast them at its own side, measured). Prev: 4a2860cfd148cafa6843221d8be1ad49   # S111 (P3.11c/d, built S111, test ROM USER-CONFIRMED 2026-10-02 15:08 ("Looks good")): the custom skills $DE-$FE are project data (19 regions in $07/$41/$4C/$54/$55/$56/$58/$5F/$72; baseline editor2/core/custom_skills.json = the S110 pin's bytes) + NEW custom skills 234-254 (bank $72 FarSkillFork -> CustomBaseTable runs a stock skill's effect with the new id) + the element override (bank $52: the 24 ladder calls go through ElemLadderA/Breath/Slash in the dead $51B3 pocket -> $72 ElemLevel72; StockElemTable / CustomElemTable all $FF = vanilla) + learn rows from $72 CustomLearnTable via wLearnRowBuf ($06 LearnLoopFork) + CustomSfxTable ($55, $09: S110 custom ids read the next SFX table) + bank $50 SaveBtl_5ad2 keeps custom ids' own names (PROJECT_COMPILER §2.27). The Scorch / Smite name strings were dropped (retired $DE/$DF name the empty string). Prev: 534bfb6245e825445f6d45764ed7305e   # S110 (P3.11 Skills tab; built S110, NOT yet user-tested): skills as project data — new regions gd_skill_names ($41 SkillNameStrings), gd_skill_desc / gd_skill_desc_ptrs / gd_skill_desc_extra ($56, re-sectioned S110), gd_present_proxy_5f / _55 (looks_like). Engine: bank $5f GetPresentId reads StockPresentTable for stock ids (+6 B code + 222 B table from the pad; the 11 call sites + GetAnimPresentId's jr move with it); NEW hand patch bank $55: `ld a,[$db8a]` at $4061 -> call SfxPresentId (+19 B + StockSfxTable 222 B after jr_055_797a, 241 pad nops). Identity tables = vanilla behaviour. Example: the S44 hand rename 215 Sheldodge -> "BugCut" (3 $F0 pad) became gamedata.skills.215.name, so names 216-221 move 3 B down (+ their 40 pointer words). Prev: 482c949ffabbce1ec409c4c9fb7e5f2e   # S109 (P3.10b arena editor; built S109, NOT yet user-tested): arena team sizes — the last 6 bytes of bank $04 ReadArenaGroup ($5E0A) and bank $50 LoadArenaEnemyStats ($6760), `ld a,$01 / ld [$d7d1],a / ret`, became `ld hl,$6E00 / rst $10 / ret / nop`: new hand patch bank $6E ArenaTeamFixup (writes $D7D1 = 1, then $DA02 and the absent slots' display entries from ArenaTeamSizeTable, region gd_arena_team_sizes; all 3 = vanilla). The arena master tables ($04 / $50) and class fees ($09) are compiler regions gd_arena_masters_04 / _50 / gd_arena_fees (empty gamedata.arena = the same bytes). Diff vs the S107 pin (built in a HEAD worktree): exactly those two 6-byte sites + bank $6E $4000-$4059 + the header checksum. Prev: 77ccdab8a746fdc25fcad8d1239c84e4   # S107 (P3.10 part 2c, USER-CONFIRMED 2026-10-01 "Great, can confirm works"): the JOURNAL party line ($07 jr_007_6271) and its bank-$0A twin (jr_00a_5fd9) read the SAVED party member's family icon through bank $6D FamilyIconGfxFromE (same-size forks, 7 B + 6 nops each) — their unclamped 10-entry tables gave a saved Spirit member gfx id $CDE5 / $0A11 and the screen stopped (PyBoy S107); tables re-sectioned SavedPartyFamilyIconTable07 / 0A (both trees). Family icons are compiler regions gd_family_icons ($4F) / gd_family_icon_streams ($2E, new hand patch) / gd_spirit_icon_stream ($6D), empty = the same bytes. Prev: 9740c1c99f9eb11fd2d0edbf3d0a3066   # S107 (P3.10 part 2b, USER-CONFIRMED 2026-10-01 "Can confirm everything works correctly"): walking layouts for new species — bank $11 both follower entries `ld de, FollowerLayoutL1Table11` -> same-size `call FollowerLayoutBase11` (DE = NewFollowerL1Table - 2*$5D for ids 221+); NewAttrHandler no longer rewrites HRAM $C7 (the S105 donor index), NewFollowerAttrTable 1 B per id, new NewFollowerL1Table (ns_follower_layout, 19 dw; Gorbunok = $4184 as before, undeclared $0000); bank $10 / $11 zero tails = compiler regions lay_copies_10 / lay_copies_11 (empty = the same zeros). S107 2a changed no pinned byte. Prev: f22f56e116bc6b3f6b94e7d45a7e5f1e   # S105 G3 (USER-CONFIRMED 2026-09-30 ("Confirm all three appear as expected")): new-species CAPACITY 1 -> 19 (ids 221-239, any subset). The eight follower forks COMPUTE the gfx-ID $7E00+(id-221)*2 into WRAM wNewSpeciesGid ($D10A, carved from wCustomPool) instead of reading per-bank one-entry tables (their ns_follower_gfx_* regions are gone); every other fork gates on id >= 221 (info $03/$6A, NewAttrHandler $11, HighBattlePal $17 (19 x 8 B table), FamilyRecipeResolve $16 (19 x 2 B), HighDetailTextFork $4D (bases -$1BA), LoadModeBaseRedirect $00 (base $7D39)); bank-$01 follower clamp 240+ only; ROM0 battle gfx table re-sectioned $2D56-$2DA7 (19-word region); bank $41 names / nicknames PACKED into 5 free extents (ns_text_a-e) + the nickname pointer table $7EF3 (ns_short_ptr), and SpellUseText_11's tail $7E06-$7E15 restored to vanilla (B9 S28 had zeroed it); bank $7E pointer table 38 entries (Gorbunok 224 = index 6 / 7). The example still declares only Gorbunok (224). Prev: f8a714850b5318844e23b050a16f222e   # S105 (built, never user-tested — superseded in-session by G3): ROADMAP P3.9b purge of the POC CONTENT from the hand overlay. New species are project data (custom.species, editor2/core/species.py): the example re-expresses Gorbunok byte-identically through 17 ns_* regions + the compiler-owned bank $7E, except (a) its wild row moved from the bank-$14 EID-518 slot to project enemy 520 (bank $6B; pool 0 names it) and (b) the walking layout now comes from the donor index NewAttrHandler writes to HRAM $C7 (bank $11) instead of a pointer written at $11:$413F, which had overwritten ChopClown/Grendal's attr bytes (restored $02,$02). Purged: the S21 Dracky->Clam battle sprite (patches/bank_036.asm deleted), the S12 dead-table mirror (entries 693/803). Anchor's 4 dialog scripts + texts moved from the example's medal_vault room to the built-in skill_scripts.json (bank $60 SkillScriptPtrTable, script type $FF; template CustomScriptRead +9 B, re-pinned; bank $72 arms $FF, ids 2-5 unchanged). Prev: 15f21834385eb38e3650d434c622eda2   # S104 r5 (USER-CONFIRMED 2026-09-30 "perfect. Hand off."): library tab DISPLAY order — bank $12 LibTabToFamily / LibTabOrder (Spirit before ???; == gamedata.DISPLAY_ORDER) used by the tab-strip icons (SaveItem_6184 same-size call) and LibScanByFamily; 39 tail fill nops consumed. Prev: e994173e6086fd9f3cfe5095e3f9ba65   # S104 r4 (USER-CONFIRMED 2026-09-30 "Great that fixed it!"): bank $73 CF3SnapRestore restores the extended farm to $BCC7 only (93 chunks + CF3SnapTail4) — the snapshot's 28 lazy tile-image bytes $BCC8-$BCE3 hold the PREVIOUS save's top tile row (commit runs before SaveGameState's tile block); restoring them broke checksum v3 segment 3 when the last two saves were on different screens (user: save wiped on reset, glitchy top row). Prev: d7b762db217656f4432f115c25b39418   # S104 r3 (built; user: save wiped): bank $12 LibScanByFamily writes the library list to wMonList (was $C0D8; FX1 S71 had moved every bank-$12 reader to wMonList, so each tab listed the roster list and a lookup opened species = list index — user S104: the Spirit lookup froze). Prev: eb1535108cdbc9ac24d64dce3db5591e   # S104 r2 (built; user: Spirit library lookup froze): the Spirit icon = mock-up B "ghost wisp" (user pick) in $4F:$41B0 + the bank $6D SpiritIconStream (run marker $00); new compiler regions gd_family_voices (bank $6D FamilyTextPtrTable11) and gd_spirit_names (bank $41 dead fill) — empty gamedata == the r1 bytes. Prev: eee9f5b08b2f847291103961385099d9   # S104 r1 (built; test ROM user-passed except the Library door, which the user project redirects): ROADMAP P3.10a Spirit as the 11th family — new hand-authored bank $6D FAMILY SYSTEMS (FamilyIconGfxActive/FromE, FamilyTextGroupFromE, FamilyDefaultNameId, SpiritIconStream) behind same-size forks in banks $01/$0A/$04/$09; bank $16 family-scan $FA wildcard jr -> 2 nops ($FA = Spirit); bank $4F ??? glyph restored at $41A0, Spirit glyph at $41B0 (byte $1A); bank $41 mode-4 Spirit string "$1A", Spirit default names in the dead $4323 words + tail fill; bank $07 unknown-parent pedigree icon id 10 -> 11 (id 10 = Spirit since B9 drew the Spirit icon for unknown parents). No example project.json change. Prev: 5d1dbc5f50aa46717d662bdc83b3cad4   # S103 (USER-CONFIRMED 2026-09-30 "Rom - all correct"): ROADMAP P3.9 Layer A-lite — the vanilla data tables (MonsterInfoTable, EnemyStatsTable, EncounterPoolData, FamilyRecipeTable, bank $69 special table, Exp/StatGrowth curves (new patches/bank_013.asm), SkillLearnReq/MPCost/RecordData, bank $12 LibFamilyPtrTable, bank $4D library recipe text re-sectioned) are compiler-owned regions fed by `gamedata`; the example re-expresses the pre-S103 hand edits as gamedata (byte-identical) EXCEPT the library recipe text: its 4 B4 family-recipe slots (DrakSlime / GreatDrak / Almiraj / Wyvern) now show the recipes the table really has (coherence Set 1) — the only byte delta, 17 B in bank $4D + header. Prev: 0d60486e57edc2ad31fa28079d4fc9f8   # S102 (built, NOT yet user-tested): own tile animations — new compiler-owned bank $6C (template bank_06c_head.asm: CustomTileAnimate / TileAnimRestart / TileAnimCopy, empty TileAnimRoomTable in the example), bank $71 CustomAnimSource far-calls it first (+4 B), wram.asm carves wTileAnim* from wCustomPool. Prev: 9c81304176bd069ec77cd4c0d2211900   # S101 (built, NOT yet user-tested): ROADMAP P3.7b part 2 custom boss floors — bank $16 GateFloorDataTable is a compiler-owned region (custom.gates: floors 2-99, boss = custom room / vanilla:$xx, hand_made; the example has no custom.gates so the 256 B are vanilla); bank $14 LoadEnemyStats head -> LoadEnemyStatsExt (EID >= 519 -> new compiler-owned bank $6B CopyEnemyRowExt / ProjectEnemyRows, template bank_06b_head.asm pinned) and LookupBossRedirect -> BossRedirectTableExt (project join_as rows, then the vanilla 34) — the old bank-$14 tail enemy row (quest EID 519) moved to bank $6B; bank $60 CustomStateRules calls CustomMonsterCast first (per-screen monster NPC cast -> $D7CA; empty table in the example); bank $71 CustomRoomBGMResolve: the floor before a CUSTOM boss map plays that room's song (or $34). Example project.json: raw script op hex normalised to the new names (branch_screen/npc_write/...; bytes identical). Prev: 7cd7257b94004fdf8b406138dc7122e1   # S100 r3 (built, NOT yet user-tested): (1) stairs/special-room descent from a FREE-COLOUR custom room faded through the room's own colour 1 (user: "background is not CREAM but room-tile coloured") — bank $06 MapTrans_S10_InGate + MapTrans_S12 same-size rewrites far-call bank $73 new entries 19 GateWipeAttr (the 20x14 $E0 fill rows -> attr 7) and 20 GateLeaveFreePal (buffer+HW colour 1 := cream once the room is squeezed; the load fade targets buffer colour 1); vanilla + unmarked rooms early-ret (PyBoy: vanilla $50 pit transition = same pictures, single-scanline timing jitter only); (2) tools/compress_tiles.py MAX_COPY 256 (the game adds 19 in 8 bits: a 257-274 byte copy wrapped and shifted the rest of a sheet 256 B — an imported blank sheet drew as flat colour blocks) + decompress_tiles.py 8-bit like the game; the example sheet re-encodes (its old stream happened to decode right); (3) editor: "Stairs down here" paints the vanilla next-floor well ($51 slots $2C-$2F over the cell's floor). Prev: 91202c74fc9fc80dffc0e397d9d5e083   # S100 r2 (built, NOT yet user-tested): the example gate rule gains once_per_dive (user 14:39: gate_rotation could be floor 2 AND floor 3 of one dive; PyBoy 40 dives: floor 2 19x, floor 3 12x, never both). Prev: 4f13d2af8411c0b4387094221e9c2382   # S100 (built, NOT yet user-tested): ROADMAP P3.7b part 1 gate room insertion — bank $16 GateDecisionFork rewritten (the S41 hardcoded gate-1 -> $6D POC + CustomGate1Setup removed; push/pop BC around the far call because the vanilla special-room test after the fork divides B = wCurrentFloor) -> bank $71 entry 4 CustomGateInsert over the generated GateInsertTable (custom.gate_inserts[]: gate, floors, chance, flag terms, once-per-dive); entry 5 CustomRoomFlags + CustomRoomFlagsTable (can_save) read by the bank $07 save ladder same-size rewrite SaveAllowCheck (vanilla verdicts identical over all 256 mapIDs); entry 1 gate byte $FF = follow the dive (no pin); dive state wGateDiveGate/Mask $DEBC-D persisted via SRAM $BFCA-B in bank $73 entries 5/6; template 164 -> 395 B re-pinned; example project: gate_rotation served on Villager floors 2-3 at 50 % (was every floor), gate_arrival (4,6), stairs tag. PyBoy on the user save: gate-21 decisions identical to the S99 build (no rule = no RNG), floor 2/3 hit 19/40 each, floor 4 0/40, once-per-dive + flag rule + follow-gate encounters + gate/own music + JOURNAL allowed/refused + save-in-room/reload/descend. Prev: d072eb516dabc4799d830c170bbc9d9f   # S99 (built, NOT yet user-tested): ROADMAP P3.3e room tile animation — bank $01 PerRoomVRAMDispatch same-size rewrite (the six wGameState bit/ret-nz guards collapsed into `and $fe / cp $10`, proven equivalent over all 65,536 (wGameState, $C8EF) pairs; freed bytes fund: custom rooms ask bank $71 entry 3 CustomAnimSource for their animation source instead of `call MapIDClampForDispatch` = Castle for all); template bank_071_head.asm + entry 3 (head 142 -> 164 B, re-pinned); generated CustomAnimSrcTable (1 B/room); example project gains explicit `animation` (arena_clone source = $06 bare ret; the rest none) — so tiles 77/78 no longer roll in the example rooms. PyBoy: vanilla rooms frame-converge with the S98 build (sub-frame tile-load timing only), clones animate their source (test_canvas v6 --rom: VRAM == census schedule). Prev: ce24de8b708fe453711075dd0a3e07f8   # S97 round 2 (USER-CONFIRMED 2026-09-26; S98 changed no example/compiler-owned bytes — pin held): text boxes keep palette 7 (cream) in free-colour custom rooms — bank $06 dialog LoadMapS_6939 / state 9 / LoadMapS_6b3d same-size far calls to bank $73 entries 14-16 (row attrs saved to wBoxAttrSave, set to 7, restored cell by cell on close), bank $56 SetB56_48a1 + bank $00 ClearTextBitsRedraw same-size far calls to entries 18/17 for the YES/NO box; wram carves 132 B from wCustomPool. Vanilla + non-free rooms: pixel-identical dialog/choice frames (PyBoy). No example bytes change from the S97 r2 boxes text form (the example uses `lines`). Prev: 6e97fd377f50de47c98dcd665f515da7   # S97 round 1 (USER-CONFIRMED 2026-09-26): ROADMAP P3.5a state rules — bank $60 template entry 8 CustomStateRules (+ CustomReadStep calls it; head 383 -> 492 B, re-pinned) and bank $17 CustomAttrCheck calls StateRulesHook17 first (3 B from the ds-12 reserve -> ds 9; PyBoy-measured: the attr/palette walk reads the step counter BEFORE bank $0B Entry 0, so a rule evaluated only in Entry 0 loads the previous state's palette — A/B proven on the servant clone); generated CustomStateRulePtrTable in bank $60; the example project's S92 rank demo moved from the entry:medal_vault prelude to arena_clone.state_rules (flag $0030 -> screen 1 state 1; PyBoy: identical NPC sets flag clear/set, survives a wiped counter; vault entry script unchanged in behaviour). Also S97: the NPC type byte fields (behaviour/object) in the compiler — no example bytes change from them. Prev: 5db25d15af6298ca8be9e717a4a95b41   # S96 round 4 (USER-CONFIRMED 2026-09-25 ("Everything works"), SameBoy menu/battle): field-menu fix for free-colour rooms (user SameBoy report: washed-out room after closing the menu + colour-1 squares during the open wipe). FreeColor1Hook now keys on a PER-SLOT marker (bit 15 of colour 3 in slots 0-3, compiler-set for free_color1 palettes) and puts it back after the colour-3 pass, so the menu's standalone LoadPal_4102 no longer re-forces cream; bank $06 A-press menu-open tail rewritten same-size (4x `ld [hl+],a`) to far-call bank $73 entry 13 MenuOpenFreePal (hardware colour 1 := cream for marked slots during the tile-$E0 wipe; buffer untouched, menu-close push restores). Vanilla rooms: 619/620 menu frames pixel-identical to the round-3 build (1 mid-redraw text frame shifted by the far call's cycles). Prev: 07a71f202f011530ba7bb7d312666a97   # S96 (built, NOT yet user-tested): bank $17 FreeColor1Hook — LoadPal_4102's colour-1 pass (`ld a, [$c7d1]`) same-size -> jp FreeColor1Hook (bank tail, before room_render_tables): custom rooms whose loaded palette has bit 15 in slot 0 colour 3 (compiler marker for `free_color1` palettes) keep their own colour 1 in slots 0-3; slots 4-6 and every vanilla room unchanged. Example project has no free_color1 palette, so only the hook code moves bytes (room_render_tables shift, label-resolved). PyBoy: Pei import room BG palette RAM slots 0-3 == project (own colour 1), slots 4-7 $6BFF, GreatTree unchanged, holds after screen scroll. Prev: fc1caa987f5d4be1ad86ef7d4e87db20   # S94b (built, NOT yet user-tested): (1) vanilla-format per-(screen, STATE) attr+palette tables — bank $17 CustomAttrPtrTable -> RoomAttr_<mid> (16 dw) -> ScrAttr_<mid>_<k> (dw step counter; per state db attr_entry, attr_bank / dw pal_ptr) read by CustomAttrCheck/CustomPalCheck exactly like the vanilla AttrPtrTable walk (vanilla varies attr AND palette per step: Servant room $3F; clones carry ALL valid vanilla steps as states[] with per-state layout/attr/palette); (2) entrance redirects — custom.entrance_redirects[] lowered to per-(mapID, screen) VanillaExitExtTable rows (db mapID, screen; $FF = any) with every valid vanilla step rebuilt from extracted/map_table.json and only the named door re-pointed; template head 358 -> 383 (VanillaExitResolve keys on wScreenIndex), re-pinned; (3) bank $0B RoomEntry9 (boundary push exits) diverted through bank $60 entry 7 too (same-size rewrite, 5 nops) so y=0/7 extension rows are LIVE; (4) Exit_GreatTree_s8 restored to VANILLA bytes — the S92 Library-door repoint ($72) and the S1-era (4,5)->$6B entrance are now example-project DATA (entrance_redirects). PyBoy: Library door -> $72 scr 1 (14,7); (4,5) -> $6B (7,6); untouched GreatTree screen-12 door -> $0D; MedalMan south edge and OldManGate south edge identical to the original ROM; fresh-project Farm clone + redirect walk-through (test_canvas --rom). Prev: cdadf8346e207c248b151491e3ca2774   # S94 (built, NOT yet user-tested): per-SCREEN attr maps — CustomAttrCheck (patches/bank_017.asm) now reads CustomRoomAttr as dw per room -> 17-byte [bank, entry x16] map emitted by render17 (screens[k].attr > layout item attr > render.attr > $FF vanilla); the S42 base_entry+2 stride is retired (a 6-screen Farm clone PyBoy-verified: each screen its own attr, old rule mismatched 100+ tiles on screens 2/4/5/6). Also S94: ROM0 $26DD rows $6B-$6F are a compiler-owned @BUILD_PROJECT region in patches/bank_000.asm (rom0_records emitter; record required for EVERY room), 4x4 screen grid schema (keys 0-15, subtable width per row), extract_room emits screens[].attr, arena_clone screens 1/2 now carry their OWN attr items (attr_s1/attr_s2 — the faithful clone; under the old stride both showed attr_s2). Prev: df3219623203cf5bc272cb6155f07a01   # S92v5 (USER-CONFIRMED): rank state re-authored as visible-by-removal — rank G+ (flag $0030) removes the (7,6) $12 attendant; user-confirmed vanishing in-game. The v4 swap target $54 renders empty in field contexts (S91) — and that is VANILLA-FAITHFUL: user confirms the real lobby shows only 2 bunnies + 2 desks (the $54 entry is the desk talk-point). USER-CONFIRMED this session: Library-door entrance teleports to the clone; all 3 clone screens accessible on a normal save; postgame right-screen "crash" was a savestate issue, not the ROM. Prev S92v4: rank trigger corrected to EVENT FLAG $0030 (rank G cleared) — the S92v3 $D9CE ladder keyed a transient coliseum variable, not persistent rank (user-reported: G cleared, no state change). Both preludes (entry:medal_vault + arena_clone scr0) now if_flag_set $0030. PyBoy-verified on BOTH user saves: normal (flag 0 -> ctr 0 -> clerk) and postgame (flag 1 -> ctr 1 -> slime in buffer after a screen-seam cross; first-load NPCs predate the entry-script arming per the measured load-order rule, and a seam cross re-reads the screen state mid-visit — no re-entry needed). Postgame right-screen crash NOT reproduced headless (marker tile, NPC talk, north door all clean on the user postgame sav) — handed to user SameBoy debugging. Prev S92v3 (user-directed): GreatTree Library door REPOINTED to arena_clone $72 — in-place same-size byte edit in patches/bank_00b.asm at $0B:$4FE6 (05 03 12 00 04 05 07 -> 05 03 72 00 01 04 07; restore note at the site). NO injected triggers: the $12/$13 vanilla_exit_extensions rows are REMOVED (the v2 gate-room door was behind the 100-monster gate; main-Library injection is blocked by the map-wide replacement-list hazard, KEY_LESSONS S92). PyBoy-verified with real transitions both directions (Library south exit regressed; door -> clone (14,7) scr1; clone south -> GreatTree scr 4). Library itself unreachable while the repoint stands (testing stance, user-approved). Prev S92 pins: d5e052081890dd24137c0738aa240794 (v2 gate-room door), + Library Gate Room ($13) vanilla_exit_extensions row — Arena-clone door at (8,6), bottom-right corner (user-directed entrance; the well/vault chain was not the user's topology). Single sub-room = no cross-screen exit-replacement hazard (Library $12 itself is 2 screens sharing one replacement list — rejected for that reason, KEY_LESSONS S92). Both vanilla steps mirrored verbatim; return door PyBoy-regressed. Prev S92 pins: 9e5b592fd4b1150e1504d1be6b0c7c17 (prelude arming), + custom.script_preludes (entry:medal_vault arms arena_clone S1 rank state pre-transition; PyBoy-measured: state selection reads the counter at destination LOAD before its entry script) + rank demo re-authored as an in-budget NPC SWAP + placeholder zero 26DD rows. Interim S92 pin c3513d85283cac54778d0629f4537d6e (clone content, pre-prelude). S92 base: P3.2 [G-A] banks $64/$67 fold behind project.json + states[] backend [G-G] + P3.2b [G-J] clone extractor. Example project GAINS arena_clone ($72, vanilla Arena Lobby $06 clone via tools/extract_room.py, single-version per user decision, BGM $1E), island_copy ($73, custom->custom clone of gate_island), an authored medal_vault staircase layout+exit, and a 2-state rank demo on arena_clone screen1. The $64/$67 EMISSION is byte-identical to the prior hand-generated banks (proven via --expect-md5 a17bff8e67f3043fbff653c65128ea16 before clone content; the fold itself is zero-delta). NOT yet user-tested (built S92). Prev: a17bff8e67f3043fbff653c65128ea16 S85b: AI-committed Anchor $E4 rewritten to Attack in DispatchBoundsStub (prev S85 4c8de38a758eda5eb256d0af6f3be5b1: DispatchBoundsStub re-route $E5-$E8 -> $62BF (bank $58; AI-committed Tremor/Quake swept the party) + Anchor $E4 true no-op in CustomBattleExec (bank $72). Also absorbs the S84 pin move that was never recorded here: b99455d67012e2f451cd5ed96a5020a1 (S84: DispatchBoundsStub bounds guard for AI-committed ids > $E5, bank $58 $694F). Neither session touched compiler-owned banks; the pin is the whole-ROM regression. Prev: ce1e7369eb3876866e897c278510c3ae (S75v4: + LearnCode2Guard06 (bank $06: custom ids can never stat-learn via the code-2 path) + SlotProbeGuard50 (bank $50: level probe bounds slot index < $28; the stale-$cac0 phantom-slot-40 echo-RAM hazard) + builder-integrated validate_custom_data.py. Prev: 762c0df0e23611bce6c931813e976d0c (S75v2: banner-before-animation (user feedback: MournCountDead shared counter evaluated in the anim fork; banner render + $FE hold state precede the two slash plays; handler keeps only the multiplier; bank $72 only). Prev: a914e4896c3380b061d9bff8cfe509f6 (S75: + custom skill $E9 Mourn (ATK-vs-DEF x (dead allies+1) via the 2nd dispatch trampoline MournDispatch52; double EvilSlash replay; boost banner; banks $06/$07/$14/$41/$4c/$52/$53/$54/$56/$58/$5f/$72/wram -- BATTLE_SKILL_SYSTEM 13.8). This pin supersedes the S73b reference DIRECTLY: the S74 Earthquake bytes were never pinned here (S74 did not touch compiler-owned banks and did not run this chain), so the S74+S75 patched deltas both land in this one pin move. Prev: 224b11766b28de88cdb206c31145e286 (S73b: + skill descriptions for $E0-$E4 (bank $56 table $6667 repoints + 226 string bytes from tail pad) and battle field-only rejection for $E4 (bank $50 FieldOnlySkillA shared predicate: menu $0302 message without consuming the turn + usable-count exclusion; 12-byte mid-pad consumption, shift audit clean). Prev: 8fa605d795a7591871d5ad02058addfb (S73 Anchor reference patched build (custom skill $E4 Anchor: field-cast system RE'd — bank $07 usability whitelist in-place rewrite + Anchor07Post state-4 menu close; bank $14 entry-4 tail -> bank $72 AnchorField14Tail context classifier; script arm protocol ctr=$FFFF; GateAwareDispatch script-type branch (template re-pinned); medal_vault scripts 2-5 + dialogue $0A20-$0A23; bank $73 commit-hook arm 1/2/3 (anchor store / install+3/4-current-MP charge on arrival / GateDecisionFork force-standard); persistent wAnchorGate/Floor $D9D7-8 (flags $01E0-$01EF retired), transient $DEB2-3; PyBoy-verified full round trip via real menu UI both directions, MP 98->24, anchor single-use, error dialogs 4/5, NO paths, Heal/WarpWing/NPC regressions). Prev: 46ba69918c7ddfdfcd8a441d967debb6 (S71v2 FX1 reference patched build (exp-scale veto: drain pays FULL pending per eligible farm monster — vanilla per-monster rate; v1 halved it. USER-CONFIRMED v1 mechanics 2026-07-26: farm menus >17, sleep whole-swap, save/reload, breeding + hatches at scale, "everything works"; v2 delta = drain payout only, PyBoy-verified full 512 payout in both farm regions). Prev: 9c3af0d434f3d5bcd617677a42129778 (S71 FX1 reference patched build (farm expansion 17->37 active slots: array 40 slots (0-2 party, 3-19 farm @$A1FB+s*$95, 20-39 farm @$B124+(s-20)*$95 = the evicted sleep pool's bank-0 home; staging pseudo-slot INDICES 20/21 -> 40/41, addresses unchanged $D665/$D6FA); sleep pool -> SRAM bank 2 ($A010+c*$95, 40 slots, "P1" magic) via bank $73 entries 10-12; one-time F2 reformat gate $BFC8-9 in entry 4 (order load-bearing: legacy sums BEFORE F2 stamp, v3 after); checksum v3 = $A002x$1C5 + $AD9Fx$385 + $BCC8x$338; snapshot R4 dual-region ($A1BF x95 + $B124 x94 chunks); roster lists + canonicalizer map -> wMonList $D001 (C0D8 overflow at 40 slots); exp payout halved at drain (aggregate 37/32~=vanilla 17/16); PyBoy-verified: reformat preserves save, R3->R4 upgrade, 25-farm canonicalize/list/rewind/dual-snapshot/drain/battle). Prev: a5a5e0d5d01949b30bbff9d3253d9748 (S70v3 reference patched build (walk-on boundary exits for custom rooms: Entry 6 scan y=7 skip is data-driven via wCustomY7Cmp $DE74 (carved from the S65 legacy pad), armed fresh by bank $60 entry 7 before every scan - vanilla branch writes $07 (original skip semantics preserved), CustomExitCheck writes $FE (custom-room y=7 rows fire on arrival, PyBoy: 36 frames tap-to-transition, vanilla MedalMan door regression-checked push-only); template head 348->358, re-pinned). Prev: 22d30b66827628b9c8d9d400c48568a4 (S70v2 reference patched build (bug-fix pass, PyBoy-verified: init_dialog $07 protocol - every text outside an NPC interaction gets its own preceding init_dialog, auto-injected by quest lowering (field mode never services the text queue; dismissal tears script dialog mode down); emit_script hard-errors on non-terminated scripts (S70 freeze class); encounter seed 1200 (drain measured 100/step); bank $0B custom-source fast transition (in-place 19-byte window rewrite: exits FROM custom rooms take the town path, 18 frames vs the 385-frame gateworld-return ceremony, a day-one defect, not a regression); write_ram2 $13 opcode; Medal Chamber display strings). Prev: 6a6f4f8791cad0a271d210c7f485569c (S70v1 reference patched build (E2 wiring: progression.quests/enemies lowering -> quest:/entry: scripts + bank $14 tail row EID 519; vanilla_exit_extensions -> VanillaExitExtTable + template entry 7 VanillaExitResolve (re-pinned, head 348 B); bank $0B Entry 6 unified divert (-5 B); bank $01 $4C3E reverted to vanilla ld a,[wMapID] (entry scripts fire at initial entry); legacy compat key retired from the example project; room $71 Medal Vault + dwm2_bgm10). Prev: 94731e601af28503060acf3884348015 (S69v2 reference patched build (roster snapshot: bank-1 magic-gated save-time roster copy restoring vanilla reset-rewind semantics; entries 5/6 tail hooks + CF3SnapXfer/Commit/Restore + wSnapBounce $DE92). Prev: e719d286db0ff66e80755ec3ef1203e0 (S69v1 E3 pin (E3 SRAM 32 KB: 19 ROM0 quadrant-convention RAMB writes retargeted $4100->$6100 (MBC5-ignored), HeaderRAMSize $02->$03, bank $73 entry 9 CF3SRAMBankedCopy + wSRAMXfer* mailbox $DE8B-$DE91). Prev: de0c5a672e7e7e1fb834dd7afe70b9e7 (S65 reference patched build (WRAM migration: NPC/exit buffers -> $CC80/$CD00, step-counter region -> $CD80 (640 B) inside the CF3-freed window; $DE74 region -> static ds 7 pad, wRoomRecScratch stays $DE7B; + bank $73 entry 6 tail zeroes the window after the main-image restore copy). Prev: 7cc0857faad8a950573e865e93f791eb (S64 reference patched build (M3b+M3c: LoadNewBGMIdIntoA same-size rewrite -> bank $71 entry 2 CustomRoomBGMResolve + CustomRoomBGMTable; music emitter owns bank $74; dq6_town1 ids $A4-$A6 from MIDI; Library $12 + gate_island $6B room defaults). Prev: 3009b75ee1e3bd58bc315a39b7324e17 (S63v5 reference patched build (M3a v4 + v5: BGM #07 ids $A1-$A3 in bank $74, room $6C NPC via project.json; bank_060 now compiler-generated via --apply). Prev: c23beed7aadee80a061c0f6c24d7c1f4 (S63 v4, M3a: AudioMasterTableExt + song bank $74 + bank $1E reverted; S62's BGM NPC/set_bgm $9E folded into the example project — S62 had hand-edited bank_060 without updating project/pin, breaking compat==hand byte-identity; restored S63). Prev pins: 168c5f1b5b4b3b2568a6d6e2f3f1ab45 (S60), d31c9300e13b98f516c6bee8b446069d (S58v2)))

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
    ok("skills.0.mp (S110): the BATTLE copy (record +4) follows the field table, no warning",
       rec[4] == 9 and not any('mp_byte' in x for x in w))
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
    expect_error("gamedata: unknown section", gd_fixture({'potions': {}}), 'unknown key')
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
    expect_error("gamedata: an added special row with the SAME parents as a vanilla row "
                 "refused (S113: it could never fire)",
                 gd_fixture({'breeding': {'special': {'appends': [
                     {'p1': 0, 'p2': 27, 'min_plus': 0, 'result': 5, 'plus_mod': 0}]}}}),
                 'same parents')
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
    ok("special append [Spirit x Spirit] -> Snaily: an FF row, auto-ordered among the "
       "family x family rows (S113), not shadowed (no $FA wildcard)",
       bytes([0xFA, 0xFA, 0x00, 0x04, 0x00]) in [sp[i:i + 5] for i in range(0, len(sp) - 1, 5)]
       and len(sp) == 826 * 5 + 1)
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
    # S113 (ROADMAP P3.12): the auto-ordered special table, removes, whole-table form
    test_special_auto_order()
    test_breeding_analysis()
    # the example re-expresses the pre-S103 hand edits
    ex = asm_bytes(region_text(out1_ex[0], 'patches/bank_003.asm', 'gd_monster_info'))
    ok("example gamedata: Dracky + Darkdrium in Spirit (B9)", ex[78 * 43] == 10 and ex[214 * 43] == 10)
    sp = asm_bytes(region_text(out1_ex[0], 'patches/bank_069.asm', 'gd_special_recipes'))
    rows = [sp[i:i + 5] for i in range(0, len(sp) - 1, 5)]
    gor = rows.index(bytes([0x04, 0x2A, 0x00, 0xE0, 0x00]))
    ok("example gamedata: special table = 825 + 2 appends + $FF; S113 auto-order puts the "
       "Gorbunok row (species x species) inside the species x species block",
       len(sp) == 827 * 5 + 1 and all(r[0] < 0xF0 and r[1] < 0xF0 for r in rows[:gor + 1]))


def test_special_auto_order():
    from editor2.core import gamedata as G
    from editor2.core.breeding import Breeding, matcher_kind
    from editor2.core.project import Project
    V0 = G.vanilla(REPO)
    van = [bytes.fromhex(r) for r in V0['tables']['special_recipes']['rows']]

    def model(gd):
        return Project(gd_fixture(gd), os.path.dirname(EXAMPLE)).gamedata()
    g0 = model({})
    b0 = Breeding(g0)
    ok("S113: no special edits = the vanilla order (825 rows, no sort)",
       [bytes(e) for e in g0.special] == van)
    # Slime x [Dragon] is a vanilla species x family row; a NEW Slime x DragonKid
    # (species x species) row must beat it for DragonKid wherever it is written
    hit = b0.resolve(8, 20)
    g1 = model({'breeding': {'special': {'appends': [
        {'p1': 8, 'p2': 'DragonKid', 'result': 'Healer'}]}}})   # 8 = the species
    b1 = Breeding(g1)   # ("Slime" as a matcher is the FAMILY — names of families win)
    rows = [bytes(e) for e in g1.special]
    kinds = [matcher_kind(e[0], e[1]) for e in g1.special]
    rank = {'SS': 0, 'SF': 1, 'FS': 2, 'FF': 3}
    ok("S113: an append is auto-placed (species x species block) and wins",
       b1.resolve(8, 20).species == 9 and b1.resolve(8, 20).how == 'special'
       and all(rank[kinds[i]] <= rank[kinds[i + 1]] for i in range(len(kinds) - 1)),
       f"vanilla {hit} -> {b1.resolve(8, 20)}")
    ok("S113: the sort keeps every other cross's result (all pairs, plus 0 / 4 / 5)",
       all(b0.resolve(x, y, pl).species == b1.resolve(x, y, pl).species
           for x in range(0, 215, 3) for y in range(215) for pl in (0, 4)
           if (x, y) != (8, 20)))
    ok("S113: + rows first within a block (Slime x Slime +5 -> KingSlime before the "
       "plain species x species rows)", rows[0] == bytes([8, 8, 5, 15, 0]), rows[0].hex())
    # removes
    g2 = model({'breeding': {'special': {'removes': [{'index': 0}]}}})
    ok("S113: removes.index drops vanilla entry 0 (824 rows left)",
       len(g2.special) == 824 and van[0] not in [bytes(e) for e in g2.special])
    expect_error("S113: a removed entry cannot also be overridden",
                 gd_fixture({'breeding': {'special': {'overrides': [{'index': 3, 'result': 5}],
                                                      'removes': [{'index': 3}]}}}), 'not both')
    # table form
    g3 = model({'breeding': {'special': {'table': [
        {'p1': 'Spirit', 'p2': 'Spirit', 'result': 'Healer'},
        {'p1': 8, 'p2': 8, 'min_plus': 5, 'result': 'KingSlime'},
        {'p1': 8, 'p2': 'Dragon', 'result': 'Snaily', 'plus_mod': 2}]}}})
    ok("S113: special.table replaces the whole table, sorted (SS, SF, FF)",
       [tuple(e[:2]) for e in g3.special] == [(8, 8), (8, 0xF1), (0xFA, 0xFA)]
       and [s[0] for s in g3.special_src] == ['table'] * 3)
    expect_error("S113: table + appends refused",
                 gd_fixture({'breeding': {'special': {'table': [], 'appends': [
                     {'p1': 'Slime', 'p2': 'Slime', 'result': 'Healer'}]}}}), 'cannot be combined')
    expect_error("S113: two table rows with the same parents refused",
                 gd_fixture({'breeding': {'special': {'table': [
                     {'p1': 'Slime', 'p2': 'Slime', 'result': 'Healer'},
                     {'p1': 'Slime', 'p2': 'Slime', 'result': 'Snaily'}]}}}), 'same parents')
    ok("S113: same parents with a different min plus are two routes, both kept",
       len(model({'breeding': {'special': {'table': [
           {'p1': 'Slime', 'p2': 'Slime', 'result': 'Healer'},
           {'p1': 'Slime', 'p2': 'Slime', 'min_plus': 4, 'result': 'Snaily'}]}}}).special) == 2)
    out, _, _ = compile_data(gd_fixture({'breeding': {'special': {'table': []}}}))
    ok("S113: an empty table = no special recipes (just the $FF)",
       asm_bytes(region_text(out, 'patches/bank_069.asm', 'gd_special_recipes')) == b'\xff')


def test_breeding_analysis():
    """S113 (P3.12): editor2/core/breeding.py — the indexed resolver == the
    line-for-line twin (the census proves the twin == the game), the vanilla
    tree (every species reachable, DeathMore 9 deep), the example's edits."""
    import random
    from editor2.core.project import Project
    from editor2.core.breeding import Analysis, offspring_plus
    for label, data in (('vanilla', gd_fixture({})),
                        ('example', json.load(open(EXAMPLE)))):
        A = Analysis(Project(data, os.path.dirname(EXAMPLE)))
        rng = random.Random(113)
        same = True
        for _ in range(20000):
            a, b = rng.choice(A.species), rng.choice(A.species)
            p1, p2, l1, l2 = rng.randrange(100), rng.randrange(100), rng.randrange(1, 100), rng.randrange(1, 100)
            slow = A.br.resolve(a, b, p1, p2, l1, l2)
            fast = A.fast.resolve(a, b, offspring_plus(p1, p2, l1, l2))
            if (slow.species, slow.how, slow.index) != fast:
                same = False
                break
        ok(f"S113 breeding ({label}): indexed resolver == the twin (20,000 random crosses)", same)
        if label == 'vanilla':
            mx = max(v for v in A.depth.values() if v < 99)
            ok("S113 breeding (vanilla tables): every species 0-214 obtainable or breedable "
               "(only the example's Gorbunok, with no recipe here, is not), deepest = "
               "DeathMore at 9", A.unreachable() == [224] and mx == 9
               and A.names[[s for s in A.species if A.depth[s] == 9][0]] == 'DeathMore')
            ok("S113 breeding (vanilla): the two dead special rows (693, 803) never fire",
               A.never_fires()[0] == [693, 803])
            ok("S113 breeding (vanilla): Watabou / StoneMan / SkyDragon come from story gifts",
               all(any('gift' in h for h in A.roots.get(s, [])) for s in (109, 197, 43)),
               str({s: A.roots.get(s) for s in (109, 197, 43)}))
        else:
            # the generator (breed_gen): seeded, compiles, keeps pinned recipes
            from editor2.core import breed_gen as BG
            prj = Project(json.load(open(EXAMPLE)), os.path.dirname(EXAMPLE))
            P1 = BG.propose(prj, seed=5, pins=[224])
            P2 = BG.propose(Project(json.load(open(EXAMPLE)), os.path.dirname(EXAMPLE)),
                            seed=5, pins=[224])
            gd = BG.to_gamedata(P1)
            P12 = BG.propose(Project(json.load(open(EXAMPLE)), os.path.dirname(EXAMPLE)),
                             seed=3, max_depth=12)
            A12 = Analysis(Project(BG.apply_to(json.load(open(EXAMPLE)), BG.to_gamedata(P12)),
                                   os.path.dirname(EXAMPLE)))
            ok("S113b generator: no depth cap — Deepest 12 reaches 12 (vanilla's tree is 9; "
               "the ceiling is the number of monsters not obtainable without breeding)",
               max(v for v in A12.depth.values() if v < 99) == 12 and not A12.unreachable()
               and abs(sum(BG.default_profile(12).values()) - 1) < 1e-9, str(A12.histogram()))
            ok("S113 generator: same seed = same proposal",
               gd == BG.to_gamedata(P2))
            d2 = BG.apply_to(json.load(open(EXAMPLE)), gd)
            out_g, _pg, _wg = compile_data(d2)
            A2 = Analysis(Project(d2, os.path.dirname(EXAMPLE)))
            mx2 = max(v for v in A2.depth.values() if v < 99)
            ok("S113 generator: the proposal compiles, every species reachable, depth >= 4, "
               "the pinned Snaily x BattleRex -> Gorbunok row kept",
               out_g is not None and not A2.unreachable() and mx2 >= 4
               and [4, 42, 0, 224, 0] in [list(e) for e in A2.br.special],
               f"depth {A2.histogram()} unreachable {A2.unreachable()}")
            ok("S113 breeding (example): Gorbunok (224) is bred from Snaily x BattleRex and "
               "met wild (encounter list 0) — depth 0",
               (4, 42) in A.produce.get(224, {}) and A.depth[224] == 0
               and any('wild' in h for h in A.roots[224]))


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
    # -- S105 gamedata fix: a Spirit parent is family code $FA (S113: the shadow
    #    checks became the auto-order + the resolver twin, editor2/core/breeding.py)
    d = base()
    d['gamedata']['monsters']['0'] = {'family': 'Spirit'}      # DrakSlime -> Spirit
    d['gamedata']['breeding']['special']['appends'] = [
        {'p1': 'Spirit', 'p2': 'Dragon', 'min_plus': 0, 'result': 'Healer', 'plus_mod': 0},
        {'p1': 'DrakSlime', 'p2': 'Dragon', 'min_plus': 0, 'result': 'Snaily', 'plus_mod': 0}]
    from editor2.core.project import Project as _P
    from editor2.core.breeding import Breeding as _B
    _br = _B(_P(d, os.path.dirname(EXAMPLE)).gamedata())
    _a, _b = _br.resolve(0, 28), _br.resolve(78, 28)
    ok("a Spirit pedigree matches [Spirit x ...] (fam_code $FA, S105); the more specific "
       "[DrakSlime x Dragon] row beats it for DrakSlime (S113 auto-order)",
       (_a.species, _a.how) == (4, 'special') and (_b.species, _b.how) == (9, 'special'),
       f"{_a} {_b}")


class MiniSM83:
    """S105 G3: just enough SM83 to RUN the new-species forks from real ROM
    bytes (straight-line code, no calls): the tests below feed every species
    id through each fork and compare HL / the WRAM gid / HRAM with what the
    fork must return. An opcode outside this set raises (the forks changed)."""
    def __init__(self, rom, bank):
        self.rom, self.bank = rom, bank
        self.a = self.b = self.d = self.e = self.h = self.l = 0
        self.c_ = 0                       # register C (self.c is the carry flag)
        self.z = self.c = False
        self.ram = {}
        self.stack = []
        self.calls = {}                   # S125: addr -> fn(cpu) for a stubbed `call`

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

    def run(self, pc, limit=2000):
        for _ in range(limit):
            op = self.rd(pc)
            n = self.rd(pc + 1)
            nn = n | self.rd(pc + 2) << 8
            e = n - 256 if n > 127 else n
            hl = self.h << 8 | self.l
            pc += 1
            if op == 0xC9 or (op in (0xC0, 0xC8, 0xD0, 0xD8) and
                              {0xC0: not self.z, 0xC8: self.z, 0xD0: not self.c,
                               0xD8: self.c}[op]):
                if self.stack and isinstance(self.stack[-1], tuple) and \
                        self.stack[-1][:1] == ('ret',):
                    pc = self.stack.pop()[1]       # S111: return from a `call`
                    continue
                return
            elif op in (0xC0, 0xC8, 0xD0, 0xD8):
                pass
            # S111: the custom-skill forks (register moves, 16-bit adds, calls,
            # pushes of BC / DE, srl, the copy loop)
            elif op == 0x4F: self.c_ = self.a
            elif op == 0x5F: self.e = self.a
            elif op == 0x57: self.d = self.a
            elif op == 0x7B: self.a = self.e
            elif op == 0x79: self.a = self.c_
            elif op == 0x4D: self.c_ = self.l
            elif op == 0x44: self.b = self.h
            elif op == 0x0E: self.c_ = n; pc += 1
            elif op == 0x06: self.b = n; pc += 1
            elif op == 0x1E: self.e = n; pc += 1
            elif op == 0x26: self.h = n; pc += 1
            elif op == 0x2E: self.l = n; pc += 1
            elif op == 0x01: self.b, self.c_ = nn >> 8, nn & 0xFF; pc += 2
            elif op in (0x09, 0x29):
                v = (self.b << 8 | self.c_) if op == 0x09 else hl
                r = hl + v; self.c = r > 0xFFFF
                self.h, self.l = (r >> 8) & 0xFF, r & 0xFF
            elif op == 0xC5: self.stack.append((self.b, self.c_))
            elif op == 0xC1: self.b, self.c_ = self.stack.pop()
            elif op == 0xD5: self.stack.append((self.d, self.e))
            elif op == 0xD1: self.d, self.e = self.stack.pop()
            elif op == 0xCD and nn in self.calls:                # S125: a stubbed call
                self.calls[nn](self); pc += 2
            elif op == 0xCD: self.stack.append(('ret', pc + 2)); pc = nn; continue
            # S125 HubWarp
            elif op == 0x95: self.a = self._cmp(self.l)          # sub l
            elif op == 0x15: self.d = (self.d - 1) & 0xFF; self.z = self.d == 0
            elif op == 0xCB and n == 0xB8: self.b &= 0x7F; pc += 1        # res 7, b
            elif op == 0xCB and n == 0x7B: self.z = not (self.e & 0x80); pc += 1  # bit 7, e
            elif op == 0xCB and n == 0x3F:
                self.c = bool(self.a & 1); self.a >>= 1; self.z = self.a == 0; pc += 1
            # S111 ratios: ScaleHL72 / Div16by8_72 / Mul16by8_72 / RatioBC72
            elif op == 0xCB and n == 0x38:                        # srl b
                self.c = bool(self.b & 1); self.b >>= 1; self.z = self.b == 0; pc += 1
            elif op == 0xCB and n == 0x23:                        # sla e
                self.c = bool(self.e & 0x80); self.e = (self.e << 1) & 0xFF
                self.z = self.e == 0; pc += 1
            elif op == 0xCB and n == 0x12:                        # rl d
                r = self.d << 1 | int(self.c); self.c = r > 0xFF; self.d = r & 0xFF
                self.z = self.d == 0; pc += 1
            elif op == 0x17:                                      # rla
                r = self.a << 1 | int(self.c); self.c = r > 0xFF; self.a = r & 0xFF
                self.z = False
            elif op == 0x2C: self.l = (self.l + 1) & 0xFF; self.z = self.l == 0
            elif op == 0x05: self.b = (self.b - 1) & 0xFF; self.z = self.b == 0
            elif op == 0xB9: self._cmp(self.c_)
            elif op == 0x90: self.a = self._cmp(self.b)
            elif op == 0x54: self.d = self.h
            elif op == 0x5D: self.e = self.l
            elif op == 0x62: self.h = self.d
            elif op == 0x6B: self.l = self.e
            elif op == 0x4E: self.c_ = self.rd(hl)
            elif op == 0x92: self.a = self._cmp(self.d)
            elif op == 0x91: self.a = self._cmp(self.c_)
            elif op == 0x12: self.ram[self.d << 8 | self.e] = self.a
            elif op == 0x13:
                de = ((self.d << 8 | self.e) + 1) & 0xFFFF; self.d, self.e = de >> 8, de & 0xFF
            elif op == 0x1C: self.e = (self.e + 1) & 0xFF; self.z = self.e == 0
            elif op == 0x0D: self.c_ = (self.c_ - 1) & 0xFF; self.z = self.c_ == 0
            elif op == 0x3C: self.a = (self.a + 1) & 0xFF; self.z = self.a == 0
            elif op == 0xAF: self.a = 0; self.z, self.c = True, False
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
            elif op == 0xE5: self.stack.append((self.h, self.l))         # S110
            elif op == 0xE1: self.h, self.l = self.stack.pop()
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


# --- S110 (ROADMAP P3.11): skills — names, SKIL text, looks_like, MP copies ---

def _sk_fixture(skills):
    d = base()
    d.setdefault('gamedata', {})['skills'] = skills
    return d


SK_FIX = {"0": {"name": "Flarebolt",
                "description": ["Scorches one foe", "with a bright", "blue fireball"],
                "looks_like": 6, "mp": 5},
          "170": {"description": ["Becomes a", "dragon"]},
          "43": {"mp": 7},
          "55": {"mp": 4},
          "50": {"mp": "ALL"},
          "215": {"name": "BugCut"}}


def test_skills_s110():
    """S110: gamedata.skills.<id>.name / description / looks_like (editor2/core/
    skills.py) and the decoded MP semantics (gamedata.py: battle record +4 and
    the field $07 table move together)."""
    from editor2.core import skills as SK
    from editor2.core import monster_text as MT
    rom = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    d0 = base()
    d0['gamedata'].pop('skills', None)
    out, _, _ = compile_data(d0)
    nb = region_bytes(out, 'patches/bank_041.asm', 'gd_skill_names')
    db_ = region_bytes(out, 'patches/bank_056.asm', 'gd_skill_desc')
    ok("S110: no edits -> the skill-name block == ROM $41:$628E-$69F1 (1,892 B)",
       nb == rom[0x41 * 0x4000 + 0x228E:][:1892])
    ok("S110: no edits -> the description block == ROM $56:$502F-$664A (5,660 B)",
       db_ == rom[0x56 * 0x4000 + 0x102F:][:5660])
    rows = [l.split(';')[0].split()[1] for l in
            region_text(out, 'patches/bank_056.asm', 'gd_skill_desc_ptrs')]
    ok("S110: no edits -> the 222 description pointer rows name the vanilla strings",
       rows == [SK.desc_label(i) for i in range(222)])
    ok("S110: no edits -> gd_skill_desc_extra = 2,993 zero bytes (the old nop pad)",
       region_bytes(out, 'patches/bank_056.asm', 'gd_skill_desc_extra') == bytes(2993))
    ok("S110: no edits -> both looks-like tables are the identity",
       region_bytes(out, 'patches/bank_05f.asm', 'gd_present_proxy_5f') == bytes(range(222))
       and region_bytes(out, 'patches/bank_055.asm', 'gd_present_proxy_55') == bytes(range(222)))
    dis41 = open(os.path.join(REPO, 'disassembly', 'bank_041.asm')).read()
    dis56 = open(os.path.join(REPO, 'disassembly', 'bank_056.asm')).read()
    ok("S110: every skill name / description label is the clean tree's",
       all(f"{SK.name_label(s)}:" in dis41 for s in range(223))
       and all(f"{SK.desc_label(s)}:" in dis56 for s in range(222)))
    van = SK.vanilla(REPO)
    ok("S110: every vanilla skill name / description re-encodes (round trip)",
       all(MT.encode_name(MT.decode(van['names'][s]), 'x', 1, 9) == van['names'][s]
           for s in range(222))
       and all(MT.encode_desc(MT.desc_lines(van['descs'][s]), 'x') == van['descs'][s]
               for s in range(222) if van['descs'][s]))
    # the example: S44's BugCut is project data now
    oe, _, _ = compile_data(base())
    ok("S110: the example renames 215 Sheldodge -> BugCut (was a hand edit)",
       'SkillName_215_Sheldodge:  ; "BugCut"' in
       "\n".join(region_text(oe, 'patches/bank_041.asm', 'gd_skill_names')))
    # edits
    o2, _, w2 = compile_data(_sk_fixture(SK_FIX))
    nb = region_bytes(o2, 'patches/bank_041.asm', 'gd_skill_names')
    ok("S110: the name block keeps 1,892 B and starts with Flarebolt, then Blazemore",
       len(nb) == 1892 and nb.startswith(MT.encode_name('Flarebolt', 'x') + b'\xf0'
                                         + van['names'][1] + b'\xf0'))
    dtx = "\n".join(region_text(o2, 'patches/bank_056.asm', 'gd_skill_desc'))
    ext = "\n".join(region_text(o2, 'patches/bank_056.asm', 'gd_skill_desc_extra'))
    ptr = region_text(o2, 'patches/bank_056.asm', 'gd_skill_desc_ptrs')
    ok("S110: Blaze's new text sits under its label in the block",
       'SkillDesc_000_Blaze:  ; "Scorches one foe/with a bright/blue fireball"' in dtx)
    ok("S110: the string pushed out of the full block (LIFE) moves to the extra region "
       "under its label; 170 gets its OWN string there and its pointer row",
       'SkillDesc_218_LIFE:' in ext and 'SkillDescOwn_170:' in ext
       and ptr[170].split()[1] == 'SkillDescOwn_170' and ptr[171].split()[1] == 'SkillDesc_Blank')
    lk = region_bytes(o2, 'patches/bank_05f.asm', 'gd_present_proxy_5f')
    ok("S110: looks_like 0 -> 6 in both tables, the rest identity",
       lk[0] == 6 and lk[1:] == bytes(range(1, 222))
       and region_bytes(o2, 'patches/bank_055.asm', 'gd_present_proxy_55') == lk)
    mp = asm_bytes(region_text(o2, 'patches/bank_007.asm', 'gd_skill_mp'))
    rec = asm_bytes(region_text(o2, 'patches/bank_054.asm', 'gd_skill_records'))
    r4 = lambda i: rec[19 * i + 4]
    w16 = lambda i: mp[2 * i] | mp[2 * i + 1] << 8
    ok("S110: mp -> both copies (Blaze 5 / 5, Heal 7 / 7)",
       (w16(0), r4(0), w16(43), r4(43)) == (5, 5, 7, 7))
    ok("S110: StepGuard (field-only) mp 4 -> the field table only (battle byte stays 0)",
       (w16(55), r4(55)) == (4, 0))
    ok("S110: Farewell 'ALL' == the original (999 / battle 1)", (w16(50), r4(50)) == (999, 1))
    ok("S110: no mp_byte warning any more", not any('mp_byte' in x for x in w2))
    # refusals
    expect_error("S110: a 10-letter skill name is refused",
                 _sk_fixture({"0": {"name": "Abcdefghij"}}), "1-9 characters")
    expect_error("S110: a 19-cell SKIL line is refused",
                 _sk_fixture({"0": {"description": ["a" * 19]}}), "19 cells")
    expect_error("S110: four SKIL lines are refused",
                 _sk_fixture({"0": {"description": ["a", "b", "c", "d"]}}), "1-3 lines")
    _o, _, ws = compile_data(_sk_fixture({"0": {"looks_like": 0x84}, "1": {"looks_like": 44}}))
    ok("S110: a summon's look and a heal's look on an attack are ALLOWED with a warning "
       "(census: no look stalls a battle)",
       any('summon' in x for x in ws) and any('other side' in x for x in ws))
    expect_error("S110: looks_like past the vanilla ids is refused",
                 _sk_fixture({"0": {"looks_like": 222}}), "vanilla skill id")
    expect_error("S110: mp over 255 is refused (one battle byte)",
                 _sk_fixture({"0": {"mp": 300}}), "0-255")
    expect_error("S110: 'All MP' on Blaze is refused (code, Farewell / MegaMagic only)",
                 _sk_fixture({"0": {"mp": "ALL"}}), "All MP")
    expect_error("S110: a number for Farewell's MP is refused",
                 _sk_fixture({"50": {"mp": 3}}), "always takes all MP")
    expect_error("S110: an unnamed target mode is refused",
                 _sk_fixture({"0": {"record": {"target_mode": 0x33}}}), "target_mode")
    expect_error("S110/S111: ids 222-223 are the retired POCs (custom skills are 224-254)",
                 _sk_fixture({"222": {"name": "X"}}), "retired")
    oa, _, _ = compile_data(_sk_fixture({"0": {"record": {"target_mode": 0x12}}}))
    ok("S110: target mode 'all foes' accepted for Blaze",
       asm_bytes(region_text(oa, 'patches/bank_054.asm', 'gd_skill_records'))[2] == 0x12)
    # name spill: lengthened names go to the shared bank-$41 extents
    longer = {str(s): {"name": "Q" + "abcdefgh"[: 8]} for s in range(0, 40)
              if len(van['names'][s]) < 9}
    o4, _, _ = compile_data(_sk_fixture(longer))
    allx = o4['patches/bank_041.asm']
    ok("S110: lengthened skill names spill into the ns_text_* extents (labels defined once)",
       len(SK.bank41_spills(_sk_fixture(longer), REPO)) > 0
       and all(allx.count(f"{SK.name_label(int(k))}:") == 1 for k in longer))
    big = {str(s): {"name": "Qabcdefgh"} for s in range(0, 222)}
    expect_error("S110: more lengthened names than the shared extents hold are refused",
                 _sk_fixture(big), "bank $41 text")
    return o2


def test_skills_rom(rom_bytes, sym):
    """--rom: the built SK_FIX ROM — names / texts through the game's tables,
    the looks-like tables, the bank $55 fork, and GetPresentId / SfxPresentId
    RUN from the built ROM for every id."""
    from editor2.core import monster_text as MT
    ok("ROM S110: skill 0's name through SkillNamePtrTable = Flarebolt, 1 = Blazemore",
       _rom_str(rom_bytes, 0x41, 0x4539) == MT.encode_name('Flarebolt', 'x')
       and _rom_str(rom_bytes, 0x41, 0x4539 + 2) == MT.encode_name('Blazemore', 'x'))
    ok("ROM S110: SKIL texts through SkillDescPtrTable: 0 new, 170 own, 171 still empty",
       _rom_str(rom_bytes, 0x56, 0x6667) ==
       MT.encode_desc(["Scorches one foe", "with a bright", "blue fireball"], 'x')
       and _rom_str(rom_bytes, 0x56, 0x6667 + 340) == MT.encode_desc(["Becomes a", "dragon"], 'x')
       and _rom_str(rom_bytes, 0x56, 0x6667 + 342) == b'')
    ok("ROM S110: SkillDescModeTable still at $664B ([$664F, $6667])",
       sym['SkillDescModeTable'] == (0x56, 0x664B) and sym['SkillDescPtrTable'] == (0x56, 0x6667))
    b5f, a5f = sym['StockPresentTable']
    b55, a55 = sym['StockSfxTable']
    t5f = rom_bytes[b5f * 0x4000 + a5f - 0x4000:][:222]
    t55 = rom_bytes[b55 * 0x4000 + a55 - 0x4000:][:222]
    ok("ROM S110: StockPresentTable / StockSfxTable = identity but 0 -> 6",
       t5f == t55 == bytes([6]) + bytes(range(1, 222)))
    sfx = sym['SfxPresentId'][1]
    ok("ROM S110: bank $55 $4061 = call SfxPresentId (was ld a, [$db8a])",
       rom_bytes[0x55 * 0x4000 + 0x61:][:3] == bytes([0xCD, sfx & 0xFF, sfx >> 8]))
    cpt = sym['CustomProxyTable'][1]
    bad = []
    for sid in list(range(222)) + list(range(0xDE, 0xEA)):
        cpu = MiniSM83(rom_bytes, 0x5F)
        cpu.ram[0xDB8A] = sid
        cpu.h, cpu.l = 0x12, 0x34
        cpu.run(sym['GetPresentId'][1])
        want = t5f[sid] if sid < 0xDE else rom_bytes[0x5F * 0x4000 + cpt - 0x4000 + sid - 0xDE]
        if cpu.a != want or (cpu.h, cpu.l) != (0x12, 0x34):
            bad.append(('5f', sid, cpu.a))
        cpu = MiniSM83(rom_bytes, 0x55)
        cpu.ram[0xDB8A] = sid
        cpu.h, cpu.l = 0x40, 0x84
        cpu.run(sfx)
        csx = sym['CustomSfxTable'][1]
        want = t55[sid] if sid < 0xDE else rom_bytes[0x55 * 0x4000 + csx - 0x4000 + sid - 0xDE]
        if cpu.a != want or (cpu.h, cpu.l) != (0x40, 0x84):
            bad.append(('55', sid, cpu.a))
    ok("ROM S110: GetPresentId / SfxPresentId RUN for ids 0-221 + $DE-$E9 return the "
       "table / custom proxy / (S111) CustomSfxTable and keep HL", not bad, f"{bad[:4]}")
    o = 0x54 * 0x4000 + 0x01CF
    ok("ROM S110: Blaze's battle MP (record +4) = 5",
       rom_bytes[o + 4] == 5)



# --- S111 (ROADMAP P3.11c/d): the custom skills as project data ---

CS_FIX = {
    "229": {"name": "Rumble", "learn": {"level": 1, "prereqs": [72]}, "mp": 8,
            "quake_power": {"min": 60, "max": 80}, "element": "Explosion",
            "announce": ["{name} makes", "the ground rumble!"],
            "description": ["Shakes all foes,", "then allies a bit,", "never flyers"]},
    "234": {"base": 16, "name": "Thunder", "description": ["Calls thunder down", "on every foe"],
            "learn": {"level": 1, "prereqs": [16]}, "mp": 6, "looks_like": 6, "sounds_like": 6,
            "record": {"party_min": 60, "party_range": 15}},
    "235": {"base": 94, "name": "FrostBite", "description": ["A freezing breath",
                                                              "that hits all foes"],
            "learn": {"level": 1, "prereqs": [94]}, "looks_like": 98, "sounds_like": 98,
            "element": "IceBreath"},
    "0": {"element": "Ice"},
    "224": {"burn": "1/4", "damage_per_mp": 3},
    "226": {"damage_of_atk": [1, 2]},
    "228": {"mp_charge": "1/2"},
    "230": {"ally_damage": "1/2"},
    "233": {"per_fallen": "1/2"}}


def _cs_regions_committed():
    """{region: lines} of every S111 custom-skill region as committed in patches/."""
    from editor2.core import custom_skills as CS
    out = {}
    for name, f, _fn, _b in CS.REGIONS:
        L = open(os.path.join(REPO, f)).read().split('\n')
        b = L.index(f"; @BUILD_PROJECT BEGIN {name}")
        e = L.index(f"; @BUILD_PROJECT END {name}")
        out[name] = (f, L[b + 1:e])
    return out


def test_custom_skills_s111():
    """S111: gamedata.skills.<222-254> (editor2/core/custom_skills.py) — the
    built-in custom skills' data and NEW custom skills (base = a stock skill's
    effect), the element override, the custom sound table."""
    from editor2.core import custom_skills as CS
    from editor2.core import monster_text as MT
    from editor2.core import gamedata as G
    B = CS.baseline()
    ok("S111: custom_skills.json holds the 12 ids $DE-$E9 (+ banners, tame, quake)",
       sorted(B['skills']) == list(range(0xDE, 0xEA))
       and set(B['banners']) == {'quake_allies', 'quake_flew', 'mourn_boost'})
    ok("S111: 20 compiler regions (+ gd_custom_ratios), each in a patch file that has it",
       len(CS.REGIONS) == 20 and all(len(v[1]) > 0 for v in _cs_regions_committed().values()))
    # (1) the committed patches carry the example's output (no edits >= 222)
    oe, prj, _ = compile_data(base())
    com = _cs_regions_committed()
    bad = [n for n, (f, lines) in com.items() if region_text(oe, f, n) != lines]
    ok("S111: example -> every custom-skill region == the committed patches/ text", not bad,
       f"{bad}")
    sk, ex, _w = CS.resolve(base(), REPO)
    ok("S111: example -> the 10 built-ins (224-233) exist, no new skill",
       sorted(sk) == list(range(0xE0, 0xEA)))
    ok("S111: example -> every built-in's record / MP / learn row / announce / looks == "
       "custom_skills.json (the S110 pin's bytes)",
       all(sk[s]['record'] == bytes.fromhex(B['skills'][s]['record'])
           and sk[s]['mp'] == B['skills'][s]['mp']
           and sk[s]['learn'] == (bytes.fromhex(B['skills'][s]['learn'])
                                  if B['skills'][s]['learn'] else None)
           and sk[s]['template'] == B['skills'][s]['announce_template']
           and sk[s]['proxy'] == B['skills'][s]['proxy'] for s in sk))
    ok("S111: example -> CustomBaseTable = 33 x $FF, CustomSfxTable = 33 x $09 "
       "(the party sound kind: S110 custom ids overshot into the next table)",
       region_bytes(oe, 'patches/bank_072.asm', 'gd_custom_base') == b'\xff' * 33
       and region_bytes(oe, 'patches/bank_055.asm', 'gd_custom_sfx') == b'\x09' * 33)
    el = region_bytes(oe, 'patches/bank_072.asm', 'gd_skill_elements')
    ok("S111: example -> no element overrides (222 stock + 33 custom = $FF)",
       el == b'\xff' * (222 + 33))
    ok("S111: example -> CustomRatioTable = the S49-S75 constants (1/2, 1, 1/4 x3, 3/4, "
       "1/3 x4, 1)",
       region_bytes(oe, 'patches/bank_072.asm', 'gd_custom_ratios') ==
       bytes([1, 2, 1, 1, 1, 4, 1, 4, 1, 4, 3, 4, 1, 3, 1, 3, 1, 3, 1, 3, 1, 1]))
    ok("S111: example -> CustomTargetBaseTable: MagicBurn = Firebal's row, Tame x3 = "
       "Blaze's (the AI no longer casts them at its own side), Quake = Firebal's, Mourn = "
       "Attack's", region_bytes(oe, 'patches/bank_058.asm', 'gd_custom_target')[:12] ==
       bytes([0xE5, 0xE5, 0x03, 0x00, 0x00, 0x00, 0xE5, 0x03, 0x03, 0x03, 0x03, 0x3A]))
    # (2) edits
    o2, p2, w2 = compile_data(_sk_fixture(CS_FIX))
    ok("S111: ratios: MagicBurn 1/4 + 3, TameMore 1/2, Anchor 1/2, Quake 1/2, Mourn 1/2; "
       "the rest the originals",
       region_bytes(o2, 'patches/bank_072.asm', 'gd_custom_ratios') ==
       bytes([1, 4, 3, 1, 1, 4, 1, 2, 1, 4, 1, 2, 1, 3, 1, 2, 1, 3, 1, 3, 1, 2]))
    sk2, ex2, _ = CS.resolve(_sk_fixture(CS_FIX), REPO)
    ok("S111: 234 Thunder / 235 FrostBite are new skills on bases Zap / Scorching",
       sorted(s for s in sk2 if s >= 0xEA) == [0xEA, 0xEB]
       and sk2[0xEA]['handler'] == sk2[0xEB]['handler'] == 'clone'
       and (sk2[0xEA]['base'], sk2[0xEB]['base']) == (16, 94))
    cb = region_bytes(o2, 'patches/bank_072.asm', 'gd_custom_base')
    ok("S111: CustomBaseTable[$EA] = 16, [$EB] = 94, the rest $FF",
       cb == b'\xff' * 12 + bytes([16, 94]) + b'\xff' * 19)
    ok("S111: CustomSfxTable / CustomProxyTable: Thunder sounds + looks like Blaze's "
       "row 6, FrostBite like IceStorm (98)",
       region_bytes(o2, 'patches/bank_055.asm', 'gd_custom_sfx')[12:14] == bytes([6, 98])
       and region_bytes(o2, 'patches/bank_05f.asm', 'gd_custom_present')[12:14] == bytes([6, 98]))
    ok("S111: CustomTargetBaseTable: a new skill uses its base's AI target row",
       region_bytes(o2, 'patches/bank_058.asm', 'gd_custom_target')[12:14] == bytes([16, 94]))
    el2 = region_bytes(o2, 'patches/bank_072.asm', 'gd_skill_elements')
    ice, ib, ex_ = (G.RESIST_NAMES.index(n) for n in ('Ice', 'IceBreath', 'Explosion'))
    ok("S111: element overrides: Blaze (stock 0) -> Ice, Tremor ($E5, project 'Rumble') -> "
       "Explosion, FrostBite -> IceBreath, everything else $FF",
       el2[0] == ice and el2[222 + 7] == ex_ and el2[222 + 13] == ib
       and el2[1:222] == b'\xff' * 221
       and sum(1 for x in el2[222:] if x != 0xFF) == 2)
    ok("S111: the AI element (record +5) follows: Blaze = Ice+1, FrostBite = IceBreath+1",
       sk2[0xEB]['record'][5] == ib + 1
       and region_bytes(o2, 'patches/bank_054.asm', 'gd_skill_records')[5] == ice + 1)
    ok("S111: Thunder's record: Zap's with party power 60 / 15 and MP 6 at +4",
       sk2[0xEA]['record'][4] == 6 and sk2[0xEA]['mp'] == 6)
    ok("S111: Tremor's quake_power {60, 80} -> QuakePowerTable row (60, 20); the "
       "other three keep the baseline",
       region_bytes(o2, 'patches/bank_072.asm', 'gd_quake_power')[0:2] == bytes([60, 20])
       and region_bytes(o2, 'patches/bank_072.asm', 'gd_quake_power')[2:] ==
       region_bytes(oe, 'patches/bank_072.asm', 'gd_quake_power')[2:])
    nm = o2['patches/bank_041.asm']
    ok("S111: the names Rumble / Thunder / FrostBite are emitted in bank $41 (the custom "
       "region, then the shared ns_text_* extents when it is full)",
       all(f'SkillName_{i}_{n}:' in nm and f'dw SkillName_{i}_{n} ' in nm
           for i, n in ((229, 'Rumble'), (234, 'Thunder'), (235, 'FrostBite'))))
    lr = region_bytes(o2, 'patches/bank_072.asm', 'gd_custom_learn')
    ok("S111: CustomLearnTable: 31 rows x 18 B; Thunder's row = level 1, prereq Zap",
       len(lr) == 31 * 18 and lr[18 * (0xEA - 0xE0)] == 1
       and 16 in lr[18 * (0xEA - 0xE0):18 * (0xEA - 0xE0) + 18][1:]
       and lr[18 * (0xEC - 0xE0)] == 0xFF)
    ok("S111: the own announce line is encoded with the name insert",
       sk2[0xE5]['template'] == 0xFD and bytes([0xF9, 0x00]) in sk2[0xE5]['message'])
    ok("S111: the names reach the editor list (CS.names)",
       CS.names(_sk_fixture(CS_FIX), REPO).get(0xEA) == 'Thunder')
    # (3) refusals
    def fx(extra):
        return _sk_fixture(dict(extra))
    expect_error("S111: id 222 is retired", fx({"222": {"name": "X"}}), "retired")
    expect_error("S111: id 255 is out of range", fx({"255": {"name": "X"}}), "222-254")
    expect_error("S111: MagicBurn's MP is a share (burn)", fx({"224": {"mp": 3}}), "set `burn`")
    expect_error("S111: Quake's power words are refused",
                 fx({"230": {"record": {"party_min": 9}}}), "power fields")
    expect_error("S111: Anchor has no element", fx({"228": {"element": "Fire"}}),
                 "deals no damage")
    expect_error("S111: `base` only on new skills", fx({"230": {"base": 0}}), "own code")
    expect_error("S111: a new skill needs a base", fx({"240": {"name": "X"}}), "needs `base`")
    expect_error("S111: a new skill needs a name", fx({"240": {"base": 16}}), "needs a name")
    expect_error("S111: a field skill is not a base", fx({"240": {"base": 0x37, "name": "X"}}),
                 "field skill")
    expect_error("S111: a battle action is not a base", fx({"240": {"base": 58, "name": "X"}}),
                 "not a skill")
    expect_error("S111: a base whose copy differs is refused (census)",
                 fx({"240": {"base": 18, "name": "X"}}), "does not behave")
    expect_error("S111: element on a non-elemental base",
                 fx({"240": {"base": 21, "name": "X", "element": "Fire"}}), "does not test")
    expect_error("S111: announce + announce_as", fx({"230": {"announce": ["a"],
                                                             "announce_as": 3}}), "not both")
    expect_error("S111: MagicBurn cannot burn more than all its MP",
                 fx({"224": {"burn": "3/2"}}), "at most 1")
    expect_error("S111: a ratio needs a denominator of 1-255",
                 fx({"230": {"ally_damage": "1/0"}}), "denominator 1-255")
    expect_error("S111: a ratio is a fraction", fx({"233": {"per_fallen": "half"}}),
                 "a fraction like")
    expect_error("S111: ratio keys belong to their skill", fx({"224": {"ally_damage": "1/2"}}),
                 "unknown key")
    expect_error("S111: Quake's own side at most 2x", fx({"230": {"ally_damage": 3}}),
                 "at most 2")
    expect_error("S111: quake_power max below min",
                 fx({"230": {"quake_power": {"min": 50, "max": 40}}}), "quake_power")
    expect_error("S111: a learn prereq must exist",
                 fx({"240": {"base": 16, "name": "X", "learn": {"level": 1, "prereqs": [250]}}}),
                 "250")
    # (4) the bank budgets
    big = {str(s): {"base": 16, "name": "ABCDEFGHI",
                    "description": ["Eighteen chars abc", "Eighteen chars abc",
                                    "Eighteen chars abc"]} for s in range(234, 255)}
    ob, _, _ = compile_data(fx(big))
    ok("S111: all 21 new skills with 9-letter names + full 3-line texts compile (the "
       "names / texts spill into the shared extents; --rom builds it)",
       all(f'SkillName_{s}_ABCDEFGHI:' in ob['patches/bank_041.asm'] for s in range(234, 255)))
    CS_MAX[0] = big
    return o2, ob


CS_MAX = [None]


def test_custom_skills_rom(tag, rom_bytes, sym, prj_data):
    """--rom: the S111 forks RUN from the built ROM's bytes (MiniSM83) for every
    custom id, against custom_skills.resolve() of the project they were built from."""
    from editor2.core import custom_skills as CS
    from tools import extract_custom_skills as X
    sk, ex, _ = CS.resolve(prj_data, REPO)

    def at(lbl, off=0, n=1):
        b, a = sym[lbl]
        o = b * 0x4000 + (a - 0x4000 if b else a) + off
        return rom_bytes[o:o + n]
    bad = []
    rptr = sym['CustomRecordPtrTable'][1]
    for sid in range(0xDE, 0xFF):
        cpu = MiniSM83(rom_bytes, 0x54)
        cpu.c_, cpu.b = sid, 0
        cpu.run(sym['Fork54_RecordIndex'][1])
        hl = cpu.h << 8 | cpu.l
        if hl != rptr + 2 * (sid - 0xDE):
            bad.append(('54', sid, hex(hl)))
            continue
        rp = rom_bytes[0x54 * 0x4000 + hl - 0x4000] | rom_bytes[0x54 * 0x4000 + hl - 0x3FFF] << 8
        rec = rom_bytes[0x54 * 0x4000 + rp - 0x4000:][:19]
        want = sk[sid]['record'] if sid in sk else rom_bytes[0x54 * 0x4000 + 0x1CF:][:19]
        if rec != want:
            bad.append(('rec', sid))
    ok(f"ROM S111 {tag}: Fork54_RecordIndex RUN for $DE-$FE -> each id's own 19-B record "
       "(unused ids: Blaze's $41CF)", not bad, f"{bad[:4]}")
    bad = []
    for sid in range(0xDE, 0xFF):
        cpu = MiniSM83(rom_bytes, 0x07)
        cpu.h, cpu.l = 0, sid
        cpu.run(sym['MPPtrFromId'][1])
        hl = cpu.h << 8 | cpu.l
        mp = rom_bytes[0x07 * 0x4000 + hl - 0x4000] | rom_bytes[0x07 * 0x4000 + hl - 0x3FFF] << 8
        want = sk[sid]['mp'] if sid in sk else 0
        if mp != (want or 0):
            bad.append((hex(sid), mp, want))
    ok(f"ROM S111 {tag}: MPPtrFromId RUN for $DE-$FE -> the field MP (= record +4)",
       not bad, f"{bad[:4]}")
    bad = []
    for sid in range(0xDE, 0xFF):
        cpu = MiniSM83(rom_bytes, 0x58)
        cpu.a = sid
        cpu.run(sym['AnnounceIdxFork'][1])
        hl = cpu.h << 8 | cpu.l
        got = rom_bytes[0x58 * 0x4000 + hl - 0x4000]
        want = sk[sid]['template'] if sid in sk else 0xFF
        if sid in (0xDE, 0xDF):
            want = CS.baseline()['skills'][sid]['announce_template']
        if got != want:
            bad.append((hex(sid), hex(got), hex(want)))
    ok(f"ROM S111 {tag}: AnnounceIdxFork RUN for $DE-$FE -> each id's announce template",
       not bad, f"{bad[:4]}")
    bad = []
    for sid in [0, 16, 94, 221] + list(range(0xDE, 0xFF)):
        cpu = MiniSM83(rom_bytes, 0x72)
        cpu.ram[0xDB8A] = sid
        cpu.run(sym['FarSkillFork'][1])
        hl = cpu.h << 8 | cpu.l
        v = sk.get(sid)
        if sid < 0xDE or (v and v['base'] is not None):
            want = 0x4011 + 2 * (sid if sid < 0xDE else v['base'])
        elif sid == 0xE9:
            want = sym['MournDispatchPtr'][1]
        else:
            want = 0x7FED
        if hl != want:
            bad.append((hex(sid), hex(hl), hex(want)))
    ok(f"ROM S111 {tag}: FarSkillFork RUN -> a new skill = its base's handler pointer, "
       "the built-ins / unused ids = CustomSkillPtr (Mourn its own)", not bad, f"{bad[:4]}")
    # ElemLevel72: packed resistances = $1B in every byte -> the level IS the pair index
    bad = []
    stock_el = at('StockElemTable', 0, 222)
    cust_el = at('CustomElemTable', 0, 33)
    for sid in list(range(0, 222, 7)) + list(range(0xDE, 0xFF)):
        cpu = MiniSM83(rom_bytes, 0x72)
        cpu.ram[0xDB8A] = sid
        cpu.ram[sym['wBattleTargetIdx'][1]] = 4
        for o in range(56):
            cpu.ram[0xDD28 + o] = 0x1B
        cpu.e = 0x77
        cpu.run(sym['ElemLevel72'][1])
        t = stock_el[sid] if sid < 222 else cust_el[sid - 0xDE]
        want = 0x77 if t == 0xFF else (0 if t == 0xFE else (t + 1) % 4)
        if cpu.e != want:
            bad.append((hex(sid), cpu.e, want))
    ok(f"ROM S111 {tag}: ElemLevel72 RUN -> no override keeps the handler's level, an "
       "override reads the target's packed level for that resistance", not bad, f"{bad[:4]}")
    # CustomLearnRow72: walk the custom rows like the bank $06 scanner does
    seen, e = [], 0xE0
    buf = sym['wLearnRowBuf'][1]
    for _ in range(40):
        cpu = MiniSM83(rom_bytes, 0x72)
        cpu.e = e
        cpu.run(sym['CustomLearnRow72'][1], limit=5000)
        if cpu.e == 0xFF:
            break
        seen.append((cpu.e, bytes(cpu.ram.get(buf + k, 0) for k in range(18))))
        e = cpu.e + 1
        if e > 0xFE:
            break
    want = [(s, sk[s]['learn']) for s in sorted(sk) if sk[s]['learn']]
    ok(f"ROM S111 {tag}: CustomLearnRow72 RUN -> visits exactly the learnable custom "
       "skills and copies each 18-B row into wLearnRowBuf", seen == want,
       f"{[hex(s) for s, _ in seen]} vs {[hex(s) for s, _ in want]}")
    # names / texts through the game's pointer tables
    from editor2.core import monster_text as MT
    bad = [s for s in sk if _rom_str(rom_bytes, 0x41, sym['SkillNamePtrTable'][1] + 2 * s)
           != sk[s]['name']]
    bad += [('d', s) for s in sk if sk[s]['desc'] is not None and
            _rom_str(rom_bytes, 0x56, sym['SkillDescPtrTable'][1] + 2 * s) != sk[s]['desc']]
    ok(f"ROM S111 {tag}: every custom skill's name / SKIL text through the game's pointer "
       "tables", not bad, f"{bad[:4]}")
    ok(f"ROM S111 {tag}: bank $50 SaveBtl_5ad2 keeps a custom id's own name (ret nc at $DE)",
       at('SaveBtl_5ad2', 0, 3) == bytes([0xFE, 0xDE, 0xD0]))
    # [S111] the ratios: the table == resolve(); ScaleHL72 / AnchorKeepMP72 RUN
    tab = at('CustomRatioTable', 0, CS.RATIO_TABLE)
    ok(f"ROM S111 {tag}: CustomRatioTable == the project's ratios",
       all(tuple(tab[o:o + 2]) == tuple(ex['ratios'][o]) for o in ex['ratios']))
    bad = []
    for hl, b_, c_ in ((0, 1, 2), (1, 1, 2), (999, 1, 2), (203, 1, 4), (300, 1, 4), (60, 1, 3),
                       (61, 1, 3), (250, 1, 1), (999, 255, 1), (65535, 255, 255), (65535, 1, 255),
                       (777, 0, 9), (500, 7, 3), (12345, 3, 200)):
        cpu = MiniSM83(rom_bytes, 0x72)
        cpu.h, cpu.l, cpu.b, cpu.c_ = hl >> 8, hl & 255, b_, c_
        cpu.run(sym['ScaleHL72'][1], limit=5000)
        if (cpu.h << 8 | cpu.l) != min(999, hl * b_ // c_):
            bad.append((hl, b_, c_, cpu.h << 8 | cpu.l))
    n_, d_ = ex['ratios'][10]
    for mp in (0, 1, 3, 4, 203, 999):
        cpu = MiniSM83(rom_bytes, 0x72)
        cpu.d, cpu.e = mp >> 8, mp & 255
        cpu.run(sym['AnchorKeepMP72'][1], limit=5000)
        if (cpu.d << 8 | cpu.e) != mp * (d_ - n_) // d_:
            bad.append(('anchor', mp, cpu.d << 8 | cpu.e))
    ok(f"ROM S111 {tag}: ScaleHL72 (floor(HL*B/C), at most 999) and AnchorKeepMP72 (MP "
       "kept = MP x (1 - the charge)) RUN from the ROM", not bad, f"{bad[:4]}")
    o73 = 0x73 * 0x4000 + sym['CF2WarpCommitDrain.mpPtr'][1] - 0x4000
    ok(f"ROM S111 {tag}: bank $73's Anchor arrival asks bank $72 entry 7 (ld hl,$7207 / rst $10)",
       bytes([0x21, 0x07, 0x72, 0xD7]) in rom_bytes[o73:o73 + 12])
    if tag == 'example':
        r = X.Rom.__new__(X.Rom)
        r.d, r.s = rom_bytes, sym
        got = X.same_as_json(X.extract(r), json.load(open(X.OUT)))
        Bj = json.load(open(X.OUT))
        ok("ROM S111 example: tools/extract_custom_skills.py reads custom_skills.json back "
           "out of the build (the move kept every byte)",
           all(got[k] == Bj[k] for k in got), f"{[k for k in got if got[k] != Bj[k]]}")


# --- S112 (ROADMAP P3.11e): new battle animations + a skill's own presentation ---

def _an_fixture(anims, skills):
    d = base()
    d.setdefault('custom', {})['animations'] = anims
    sk = d.setdefault('gamedata', {}).setdefault('skills', {})
    sk.update(skills)
    return d


def _an_steps():
    from editor2.core import battle_anims as BA
    zap, bang = BA.expand_source(0x10), BA.expand_source(0x06)
    return zap[:4] + [s for s in bang if 'from' in s or 'sound' in s] + [{'blank': True, 'hold': 2}]


AN_FIX = None


def test_anims_s112():
    global AN_FIX
    from editor2.core import battle_anims as BA
    out0, _p, _w = compile_data(base())
    ok("S112: no animations -> the bank $5F override regions are all $FF (256 + 256)",
       region_bytes(out0, 'patches/bank_05f.asm', 'gd_anim_routine') == b'\xff' * 256 and
       region_bytes(out0, 'patches/bank_05f.asm', 'gd_anim_cmd') == b'\xff' * 256)
    ok("S112: no animations -> bank $6F counts 0 rows (CustomAnimNone only)",
       'CUSTOM_ANIM_COUNT EQU 0' in out0['patches/bank_06f.asm'])
    steps = _an_steps()
    AN_FIX = _an_fixture(
        [{'id': 'spark_storm', 'name': 'Spark storm', 'steps': steps},
         {'id': 'only_bang', 'steps': BA.expand_source(0x06)}],
        {'16': {'presentation': {'kind': 'animation', 'animation': 'spark_storm', 'motion': 2}},
         '94': {'presentation': {'kind': 'effect', 'effect': 4}},
         '64': {'presentation': {'kind': 'animation', 'animation': 0x26, 'motion': 0}},
         '0': {'presentation': {'kind': 'none'}},
         '234': {'base': 16, 'name': 'Thunder',
                 'presentation': {'kind': 'animation', 'animation': 'only_bang', 'motion': 1}}})
    o, _p, w = compile_data(AN_FIX)
    rt = region_bytes(o, 'patches/bank_05f.asm', 'gd_anim_routine')
    ct = region_bytes(o, 'patches/bank_05f.asm', 'gd_anim_cmd')
    ok("S112: presentation rows (Zap 2 / $2D, Scorching effect 4, EvilSlash 0 / $26, Blaze "
       "nothing 13, new skill 234 middle / $2E; every other id $FF)",
       (rt[16], ct[16], rt[94], ct[94], rt[64], ct[64], rt[0], ct[0], rt[234], ct[234]) ==
       (2, 0x2D, 4, 0xFF, 0, 0x26, 13, 0xFF, 1, 0x2E) and
       sum(1 for i in range(256) if rt[i] != 0xFF or ct[i] != 0xFF) == 5, f"{rt[:4]}")
    c = BA.compose(AN_FIX['custom']['animations'][0])
    ok("S112: compose — two sources (Zap, Bang) in palette slots 0 / 1, tiles = the union of "
       "the frames' tiles, the sprites' attr low bits = the slot",
       c['sources'] == [0x10, 0x06] and
       c['tiles'] == len({(s['from'], sp[2]) for s in steps if 'from' in s
                          for sp in BA.stock(s['from'])['frames'][s['frame']]}) and
       all(sp[3] & 7 in (0, 1) for fr in c['frames'] for sp in fr))
    ok("S112: compose — the timeline keeps every step (frames, holds, sounds) in order",
       [(x, y) for x, y in c['timeline'] if x == 0xFD] ==
       [(0xFD, s['sound']) for s in steps if 'sound' in s] and len(c['timeline']) == len(steps))
    ok("S112: compose — palettes are the sources' colours as the screen shows them "
       "(the DMG shade baked in; the engine uses the identity shade $D2)",
       c['palettes'][0] == BA.display_palette(0x10) and c['palettes'][1] == BA.display_palette(6)
       and BA.shade_map(BA.IDENTITY_SHADE) == [0, 1, 2, 3])
    b6f = o['patches/bank_06f.asm']
    ok("S112: bank $6F holds 2 rows + CustomAnimNone, bank $70 3 sheets",
       'CUSTOM_ANIM_COUNT EQU 2' in b6f and o['patches/bank_070.asm'].count('CustomAnimSheet') >= 6)
    for name, bad, needle in (
            ('unknown animation', {'16': {'presentation': {'kind': 'animation', 'animation': 'nope'}}},
             'neither a stock number'),
            ('motion 4', {'16': {'presentation': {'kind': 'animation', 'animation': 3, 'motion': 4}}},
             'motion 4'),
            ('effect 13', {'16': {'presentation': {'kind': 'effect', 'effect': 13}}},
             'screen effect 13'),
            ('kind', {'16': {'presentation': {'kind': 'sparkle'}}}, 'kind must be')):
        expect_error(f"S112 refuses a presentation: {name}", _an_fixture([], bad), needle)
    for name, anims, needle in (
            ('frame from $2D', [{'id': 'a', 'steps': [{'from': 45, 'frame': 0}]}], 'not one of the 45'),
            ('frame 32', [{'id': 'a', 'steps': [{'from': 1, 'frame': 32}]}], 'outside 0-31'),
            ('no frame', [{'id': 'a', 'steps': [{'sound': 130}]}], 'at least one frame'),
            ('5 sources', [{'id': 'a', 'steps': [{'from': k, 'frame': 0} for k in (0, 1, 2, 3, 6)]}],
             'more than 4'),
            ('duplicate id', [{'id': 'a', 'steps': [{'from': 1, 'frame': 0}]},
                              {'id': 'a', 'steps': [{'from': 1, 'frame': 0}]}], 'used twice'),
            ('33 animations', [{'id': f'a{k}', 'steps': [{'from': 1, 'frame': 0}]} for k in range(33)],
             'at most 32')):
        expect_error(f"S112 refuses an animation: {name}", _an_fixture(anims, {}), needle)
    big = _an_fixture([{'id': f'a{k}', 'steps': _an_steps()} for k in range(32)], {})
    _o32, _p32, _w32 = compile_data(big)
    ok("S112: 32 animations compile (bank space accounted)", 'patches/bank_070.asm' in _o32)
    return o, _o32


def test_anims_rom(tag, rom_bytes, sym, prj_data):
    """--rom: the built tables read back == compose(); the fork bytes in place."""
    from editor2.core import battle_anims as BA
    from dwm import sprite_codec as SC

    def addr(lbl):
        b, a = sym[lbl]
        return b * 0x4000 + (a - 0x4000 if b else a)

    def w(o):
        return rom_bytes[o] | rom_bytes[o + 1] << 8

    def bank6f(a):
        return 0x6F * 0x4000 + a - 0x4000
    lst = BA.custom_list(prj_data)
    bad = []
    for k, a in enumerate(lst):
        c = BA.compose(a)
        fl = w(addr('CustomAnimFrameTable') + 2 * k)
        for i, fr in enumerate(c['frames']):
            fp = w(bank6f(fl) + 2 * i)
            got, q = [], bank6f(fp)
            while rom_bytes[q] != 0x80:
                got.append(tuple(rom_bytes[q:q + 4])); q += 4
            if got != [tuple(sp) for sp in fr]:
                bad.append((k, 'frame', i))
        tl = bank6f(w(addr('CustomAnimTimelines') + 2 * k))
        pairs = [tuple(rom_bytes[tl + 2 * i:tl + 2 * i + 2]) for i in range(len(c['timeline']) + 1)]
        if pairs != list(c['timeline']) + [(0xFF, 0xFF)]:
            bad.append((k, 'timeline'))
        gid = w(addr('CustomAnimGfxIds') + 2 * k)
        sheet = SC.decode(SC.read_stream(rom_bytes, SC.gfxid_stream_offset(rom_bytes, gid)[3]))
        if sheet != c['sheet']:
            bad.append((k, 'sheet'))
        pp = bank6f(w(addr('CustomAnimPalettes') + 2 * k))
        pals = [[w(pp + 1 + 8 * s + 2 * j) for j in range(4)] for s in range(rom_bytes[pp])]
        if pals != c['palettes']:
            bad.append((k, 'palettes'))
    ok(f"ROM S112 {tag}: every new animation's frames / timeline / sheet / palettes read back "
       "through the bank $6F tables == compose()", not bad, f"{bad[:4]}")
    ok(f"ROM S112 {tag}: ROM0 routes $21+ to bank $6F (ld hl,$6f00 / ld hl,$6f01), bank $02 "
       "ReadSeqStep starts with jp ReadSeqStepFork",
       rom_bytes.count(bytes([0x21, 0x00, 0x6F, 0xD7]), 0, 0x4000) == 1 and
       rom_bytes.count(bytes([0x21, 0x01, 0x6F, 0xD7]), 0, 0x4000) == 1 and
       rom_bytes[addr('ReadSeqStep')] == 0xC3 and
       w(addr('ReadSeqStep') + 1) == sym['ReadSeqStepFork'][1])
    rt, ct = BA.override_tables(prj_data)
    ok(f"ROM S112 {tag}: SkillRoutineOverride / SkillAnimOverride == the project's rows",
       rom_bytes[addr('SkillRoutineOverride'):][:256] == rt and
       rom_bytes[addr('SkillAnimOverride'):][:256] == ct)


def _en_fixture():
    d = base()
    c = d['custom']
    c.setdefault('flags', []).extend([{'name': 'enc_a', 'index': 'auto'},
                                      {'name': 'enc_b', 'index': 'auto'}])
    c['encounter_lists'] = [
        {'id': 'wolves', 'name': 'Wolves', 'rate': 5, 'size_chance': [1, 4, 5],
         'slot_chance': [5, 3, 2, 0, 0], 'eids': [20, 21, 22, 0, 0],
         'max_count': [2, 3, 2, 0, 0], 'maze_size': 8},
        {'id': 'lone', 'rate': 2, 'size_chance': [7, 0, 0], 'slot_chance': [7, 0, 0, 0, 0],
         'eids': ['gorbunok_wild', 0, 0, 0, 0], 'max_count': [1, 0, 0, 0, 0]}]
    rooms = {r['id']: r for r in c['rooms']}
    rooms['gate_island']['encounters'] = {
        'enabled': True, 'list': 'wolves', 'rate': 6,
        'variants': [{'when': [{'flag': 'enc_a'}], 'list': 'lone'},
                     {'when': [{'flag': 'enc_b'}, {'flag': 'enc_a', 'is': 'clear'}], 'list': 40}]}
    rooms['ember_keystone']['encounters'] = {'enabled': True, 'gate_id': 3, 'floor': 2, 'rate': 1}
    c['gates'] = [{'gate': 1, 'encounters': {
                       'floors': [{'floors': [1, 2], 'list': 'lone'}, {'floors': 3, 'list': 77}],
                       'variants': [{'when': [{'flag': 'enc_a'}],
                                     'floors': [{'floors': 'all', 'list': 'wolves'}]}]}},
                  {'gate': 3, 'encounters': {'floors': [{'floors': [2, 3], 'list': 'wolves'}]}}]
    return d


EN_FIX = None


def test_encounters_s114():
    """S114 (P3.13a): the encounter-list choice — bank $76, project lists, room
    lists / variants / rates, gate plans."""
    global EN_FIX
    from editor2.core import encounters as EN
    from editor2.core import gamedata as GDm
    out0, prj0, _w = compile_data(base())
    b76 = out0['patches/bank_076.asm']
    ok("S114: the example has no plans / lists of its own (GATE_PLAN_LEN 0, no project list)",
       'GATE_PLAN_LEN EQU 0' in b76 and '; list 128' not in b76)
    v = GDm.vanilla(REPO)['tables']
    want = [int(r, 16) for r in v['gate_base_pool']['rows']]
    ok("S114: bank $76 VanillaGateBase == bank $01 GateBasePoolIndex (ROM copy)",
       all(f"    db {', '.join(str(x) for x in want[k:k + 8])}" in b76 for k in range(0, 32, 8)))
    # the vanilla rule against the regenerated extracted/encounters.json
    enc = json.load(open(os.path.join(REPO, 'extracted', 'encounters.json')))
    bad = []
    for gid in range(32):
        for fg in enc[str(gid)]['floor_groups']:
            for f in range(fg['floors'][0], fg['floors'][1] + 1):
                if EN.vanilla_number(REPO, gid, f) != fg['pool_index']:
                    bad.append((gid, f))
    ok("S114: vanilla_number == extracted/encounters.json for every gate floor (the game's "
       "numbering: Villager list 1 = floors 1-2, list 2 from floor 3)",
       not bad and EN.vanilla_number(REPO, 1, 2) == 1 and EN.vanilla_number(REPO, 1, 3) == 2,
       f"{bad[:5]}")
    pct = GDm.vanilla(REPO)['chance_percent']
    ok("S114: real chances — the first slot with a chance takes draw 0 (+1), the slot ending "
       "at 100 loses one (Slime / Dracky / Anteater 30/50/20 -> 31/50/19)",
       EN.real_chances([3, 5, 2, 0, 0], pct) == [31, 50, 19, 0, 0])
    ok("S114: steps between battles outside gates — code 3 = the counter mean / 100 "
       "(measured drain 100 per step), code 7 = half of it",
       abs(EN.steps_between(REPO, 3) - EN.mean_counter(REPO) / 100) < 1e-9 and
       abs(EN.steps_between(REPO, 7) * 2 - EN.steps_between(REPO, 3)) < 1e-9)
    EN_FIX = _en_fixture()
    o, prj, w = compile_data(EN_FIX)
    b = o['patches/bank_076.asm']
    ok("S114: project lists emitted in order as numbers 128 / 129 (26 B each)",
       '; list 128: wolves' in b and '; list 129: lone' in b and
       '    db $05, $03, $01, $04, $05, $05, $03, $02, $00, $00' in b and
       '    dw 20, 21, 22, 0, 0' in b and '    dw 520, 0, 0, 0, 0' in b)
    fa, fb = prj.flag_map()['enc_a'], prj.flag_map()['enc_b']
    ok("S114: room $6B -> variant list (enc_a -> 129; enc_b set + enc_a clear -> 40; else 128), "
       "rate code 6; $70 keeps the gate's list with rate code 1",
       f'    dw EncRoomVariants_6B\n    db $06' in b and f'    dw ${fa:04X}' in b and
       f'    dw ${fb:04X}' in b and f'    dw ${fa | 0x8000:04X}' in b and
       '    dw 129  ; -> list 129' in b and '    dw 40  ; -> list 40' in b and
       '    dw 128  ; otherwise list 128' in b and '    dw 0\n    db $01  ; $70' in b)
    ok("S114: gate plans — GATE_PLAN_LEN 4; Villager floors 1-2 -> 129, 3 -> 77, 4 -> its "
       "vanilla 2; its enc_a variant -> 128 on every floor; Memories floors 2-3 -> 128",
       'GATE_PLAN_LEN EQU 4' in b and
       'EncGateRuns_01_d:\n    db $02, 129' in b and '    db $03, 77' in b and
       '    db $FF, 2' in b and 'EncGateRuns_01_0:\n    db $04, 128' in b and
       'EncGateRuns_03_d:\n    db $01, 5' in b and '    db $03, 128' in b)
    b71 = o['patches/bank_071.asm']
    ok("S114: a room with its own list never pins a gate (RoomEncTable gate byte $FF); the "
       "gate+floor room keeps its pin",
       '$6B — enabled, its own list (bank $76)' in b71 and 'db $01, $FF, $00  ; $6B' in b71
       and 'db $01, $03, $02  ; $70' in b71)
    M = EN.resolve(prj)
    ok("S114: the model — gate_list with and without enc_a; the vanilla value stays",
       M.gate_list(1, 1) == 129 and M.gate_list(1, 1, {fa: True}) == 128 and
       M.gate_list(1, 4) == 2 and M.gate_list(5, 1) == EN.vanilla_number(REPO, 5, 1))
    lb = M.list_bytes(128)
    n1, e1, r1 = EN.simulate_battle(lb, pct, 1, 2)
    ok("S114: simulate_battle is deterministic and draws only the list's monsters",
       EN.simulate_battle(lb, pct, 1, 2) == (n1, e1, r1) and set(e1) <= {20, 21, 22})

    def fx(mut):
        d = _en_fixture()
        mut(d)
        return d
    rooms = lambda d: {r['id']: r for r in d['custom']['rooms']}
    for name, mut, needle in (
            ('an unknown list id', lambda d: rooms(d)['gate_island']['encounters'].update(
                list='nope'), 'neither a list number'),
            ('a list number past the project\'s', lambda d: rooms(d)['gate_island']['encounters'].update(
                list=200), 'does not exist'),
            ('variants without a list', lambda d: rooms(d)['ember_keystone']['encounters'].update(
                variants=[{'when': [{'flag': 'enc_a'}], 'list': 3}]), 'variants need a `list`'),
            ('a variant with no flag term', lambda d: rooms(d)['gate_island']['encounters'].update(
                variants=[{'when': [], 'list': 3}]), 'at least one flag term'),
            ('rate 8', lambda d: rooms(d)['gate_island']['encounters'].update(rate=8),
             'outside 0-7'),
            ('a list under 100 %', lambda d: d['custom']['encounter_lists'][0].update(
                slot_chance=[5, 3, 0, 0, 0]), 'less than 100'),
            ('a freezing 2-monster list', lambda d: d['custom']['encounter_lists'][1].update(
                size_chance=[5, 5, 0], max_count=[0, 0, 0, 0, 0]), 'forever'),
            ('two lists with one id', lambda d: d['custom']['encounter_lists'].append(
                dict(d['custom']['encounter_lists'][0])), 'used twice'),
            ('a floor in two runs', lambda d: d['custom']['gates'][0]['encounters'].update(
                floors=[{'floors': [1, 3], 'list': 3}, {'floors': 2, 'list': 4}]), 'two runs'),
            ('a floor past the gate', lambda d: d['custom']['gates'][1]['encounters'].update(
                floors=[{'floors': [2, 9], 'list': 3}]), 'this gate has floors'),
            ('an unknown room key', lambda d: rooms(d)['gate_island']['encounters'].update(
                pool=3), 'unknown keys'),
            ('129 lists', lambda d: d['custom']['encounter_lists'].extend(
                [dict(d['custom']['encounter_lists'][1], id=f'x{k}') for k in range(127)]),
             'at most 128')):
        expect_error(f"S114 refuses {name}", fx(mut), needle)
    big = fx(lambda d: d['custom']['encounter_lists'].extend(
        [dict(d['custom']['encounter_lists'][1], id=f'x{k}') for k in range(126)]))
    ob, _pb, _wb = compile_data(big)
    ok("S114: 128 project lists compile (numbers 128-255, bank $76 accounted)",
       '; list 255: x125' in ob['patches/bank_076.asm'])
    # the editor model (encounters_doc) — sparse writes, copies, refusals
    from editor2.core.document import Document
    import shutil
    tmpd = '/tmp/_t_enc_doc'
    if os.path.exists(tmpd):
        shutil.rmtree(tmpd)
    shutil.copytree(os.path.dirname(EXAMPLE), tmpd, ignore=shutil.ignore_patterns('build'))
    json.dump(_en_fixture(), open(os.path.join(tmpd, 'project.json'), 'w'), indent=1)
    doc = Document(os.path.join(tmpd, 'project.json'))
    doc.set_enc_list(7, {'rate': 6})
    doc.set_enc_list(7, {'rate': GDm._rows(GDm.vanilla(REPO), 'encounter_pools')[7][0]})
    ok("S114 doc: a game list set back to its original value leaves no gamedata key",
       '7' not in (doc.data.get('gamedata') or {}).get('encounters', {}))
    lid, num = doc.new_enc_list(copy_from=12, name='Peace copy')
    M2, _p2 = doc.enc_model()
    ok("S114 doc: New list = a byte copy of the source as number 130",
       num == 130 and M2.list_bytes(130) == M2.list_bytes(12) and lid == 'peace_copy')
    try:
        doc.delete_enc_list('wolves')
        refused = False
    except ValueError as ex:
        refused = 'still used' in str(ex)
    ok("S114 doc: a list in use cannot be deleted", refused)
    doc.delete_enc_list('peace_copy')
    doc.set_gate_floor_list(3, 4, 'lone')
    doc.set_gate_floor_list(3, 4, None)
    doc.set_gate_floor_list(3, 2, None)
    doc.set_gate_floor_list(3, 3, None)
    ok("S114 doc: gate floors back to the game's rule prune the plan and the gates entry",
       all(int(g['gate']) != 3 for g in doc.data['custom'].get('gates', [])))
    doc.set_room_battles('dusk_mirror', 'own', list_ref='lone', rate=4)
    ok("S114 doc: a room switched to its own list (+ rate) keeps no gate pin",
       doc.room_battles('dusk_mirror') == {'mode': 'own', 'gate_id': 0, 'floor': 1,
                                           'list': 'lone', 'rate': 4, 'variants': []})
    use = doc.enc_usage()
    ok("S114 doc: usage lists the room and the variant",
       any(u['label'] == 'room dusk_mirror' for u in use.get(129, [])) and
       any('when enc_a is set' in u['label'] for u in use.get(129, [])))
    return o


def test_encounters_rom(tag, rom_bytes, sym, prj_data, orig):
    """--rom: the same-size bank $01 forks + the bank $76 tables read back."""
    from editor2.core import encounters as EN
    from editor2.core.project import Project

    def addr(lbl):
        b, a = sym[lbl]
        return b * 0x4000 + (a - 0x4000 if b else a)
    lndf = addr('LoadNextDungeonFloor')
    ok(f"ROM S114 {tag}: LoadNextDungeonFloor at $01:$69E1 starts with ld hl,$7600 / rst $10; "
       "GateBasePoolIndex..EncounterPoolData unmoved ($6A22-$6AAD == the ROM)",
       sym['LoadNextDungeonFloor'] == (1, 0x69E1) and
       rom_bytes[lndf:lndf + 4] == bytes([0x21, 0x00, 0x76, 0xD7]) and
       sym['GateBasePoolIndex'] == (1, 0x6A22) and
       rom_bytes[0x6A22:0x6AAE] == orig[0x6A22:0x6AAE])
    buf = sym['wEncListBuf'][1]
    n = rom_bytes[0x4000:0x8000].count(bytes([0x21, buf & 0xFF, buf >> 8]))
    ok(f"ROM S114 {tag}: the readers use wEncListBuf ($D11E): ld hl,wEncListBuf + 2 / 5 / 10 / "
       "20 / 25 in bank $01",
       all(rom_bytes[0x4000:0x8000].count(bytes([0x21, (buf + k) & 0xFF, (buf + k) >> 8, 0x01,
                                                 0x00, 0x00])) == 1 for k in (2, 5, 10, 20, 25)),
       f"(plain ld hl,buf hits {n})")
    prj = Project(copy.deepcopy(prj_data), os.path.dirname(EXAMPLE))
    M = EN.resolve(prj)
    pl = addr('ProjectEncLists')
    ok(f"ROM S114 {tag}: ProjectEncLists in bank $76 == the model's lists",
       all(rom_bytes[pl + 26 * k:pl + 26 * (k + 1)] == M.list_bytes(128 + k)
           for k in range(len(M.lists))))
    vb = addr('VanillaGateBase')
    ok(f"ROM S114 {tag}: VanillaGateBase == bank $01 GateBasePoolIndex bytes",
       rom_bytes[vb:vb + 32] == orig[0x6A22:0x6A42])


def _ng_fixture():
    """S115 (NG1): two new gates — 32 a 4-floor copy of Memories (3) with a custom boss
    room, its own floors 1-2 list, a served room and an entrance; 33 a plain copy of
    Anger (10) with nothing else (no entrance, vanilla boss)."""
    from editor2.core import gates as GT
    d = base()
    c = d['custom']
    rooms = {r['id']: r for r in c['rooms']}
    rooms['medal_vault']['gate_arrival'] = {'screen': 0, 'x': 4, 'y': 6}
    c['gates'] = [{'gate': 32, 'copy_of': 3, 'name': 'Ember Gate', 'floors': 4,
                   'boss': 'medal_vault',
                   'encounters': {'floors': [{'floors': [1, 2], 'list': 40}]}},
                  {'gate': 33, 'copy_of': 10, 'name': 'Plain copy'}]
    c['gate_inserts'].append({'room': 'gate_rotation', 'gate': 32, 'floors': [2, 3],
                              'chance': 100})
    rooms['ember_keystone']['screens']['0']['exits'].append(GT.gate_entrance_row(5, 2, 32))
    return d


NG_FIX = None


def test_new_gates_s115():
    """S115 (ROADMAP NG1): new gates 32-95 — schema, bank $76 rows, entrances."""
    global NG_FIX
    from editor2.core import encounters as EN
    from editor2.core import gates as GT
    out0, _p0, _w0 = compile_data(base())
    b76_0 = out0['patches/bank_076.asm']
    ok("S115: the example has no new gates (NEW_GATE_LEN 0, empty NewGateRows / NewGateSource)",
       'NEW_GATE_LEN EQU 0' in b76_0 and
       'NewGateSource:  ; db per gate 32+: the vanilla gate it copies\n\n' in b76_0)
    NG_FIX = _ng_fixture()
    o, prj, w = compile_data(NG_FIX)
    b = o['patches/bank_076.asm']
    van = {g['id']: g for g in GT.vanilla_gates(REPO)}
    r10 = ', '.join(f"${x:02X}" for x in bytes.fromhex(van[10]['row']))
    ok("S115: NewGateRows — gate 32 = Memories' floor types / tier + 4 floors + boss $71 at "
       "tile (4,6); gate 33 = Anger's row byte for byte; NewGateSource 3, 10",
       'NEW_GATE_LEN EQU 2' in b and
       '    db $02, $01, $02, $04, $71, $04, $06, $01  ; gate 32 Ember Gate' in b and
       f'    db {r10}  ; gate 33 Plain copy' in b and
       '    db 3  ; gate 32' in b and '    db 10  ; gate 33' in b)

    def region(out, path, name):
        t = out[path] if path in out else None
        if t is None:
            t = [v for k, v in out.items() if k.endswith(path)][0]
        a = t.index(f"; @BUILD_PROJECT BEGIN {name}")
        return t[a:t.index(f"; @BUILD_PROJECT END {name}")]
    g16 = region(o, 'patches/bank_016.asm', 'gate_floor_table')
    ok("S115: GateFloorDataTable stays 32 rows, identical to the example's (new gates live "
       "in bank $76)",
       g16 == region(out0, 'patches/bank_016.asm', 'gate_floor_table') and
       g16.count('    db ') == 32)
    rows = prj.gate_insert_rows()
    ok("S115: a custom room can be served on a new gate (GateInsertTable gate byte $20)",
       any(r['gate'] == 32 and r['first'] == 2 and r['last'] == 3 for r in rows) and
       'db $20, $01, $02, $64' in o['patches/bank_071.asm'])
    M = EN.resolve(prj)
    ok("S115: encounters — a new gate's floor value / unplanned floors walk the gate it copies; "
       "its own plan wins on floors 1-2",
       M.vanilla(32, 1) == EN.vanilla_number(REPO, 3, 1) and M.gate_list(32, 1) == 40 and
       M.gate_list(32, 2) == 40 and M.gate_list(32, 3) == EN.vanilla_number(REPO, 3, 3) and
       M.vanilla(33, 7) == EN.vanilla_number(REPO, 10, 7) and
       'GATE_PLAN_LEN EQU 33' in b and '    dw EncGatePlan_20  ; gate 32: its own plan' in b)
    cfg = prj.gate_configs()
    ok("S115: gate_configs — new gates carry name / source / floors (33 = Anger's 11)",
       cfg[32]['name'] == 'Ember Gate' and cfg[32]['source'] == 3 and cfg[32]['new'] and
       cfg[33]['floors'] == 11 and cfg[33]['boss_map'] == 0x3C and not cfg[3]['new'])
    ok("S115: warnings — gate 33 has no entrance and ends in a vanilla boss room; gate 32 "
       "has neither warning",
       any('new gate 33 (Plain copy) has no entrance' in x for x in w) and
       any('new gate 33 (Plain copy) ends in a VANILLA boss room' in x for x in w) and
       not any('new gate 32' in x for x in w))
    ok("S115: the entrance exit row is the vanilla portal form (gate_flag 1, dest 32, "
       "screen 0, spawn 0,0)",
       '$05, $02, $20, $01, $00, $00, $00' in o['patches/bank_060.asm'] and
       'gate entrance (gate 32)' in o['patches/bank_060.asm'])

    def fx(mut):
        d = _ng_fixture()
        mut(d)
        return d
    gates = lambda d: d['custom']['gates']
    for name, mut, needle in (
            ('a new gate without copy_of', lambda d: gates(d)[1].pop('copy_of'), 'needs "copy_of"'),
            ('a new gate without a name', lambda d: gates(d)[1].pop('name'), 'needs a "name"'),
            ('copy_of a new gate', lambda d: gates(d)[1].update(copy_of=32), 'needs "copy_of"'),
            ('gate number 96', lambda d: gates(d)[1].update(gate=96), '32-95'),
            ('a name on a vanilla gate', lambda d: gates(d).append({'gate': 4, 'name': 'x'}),
             'only apply to new gates'),
            ('a rule on an undefined gate', lambda d: d['custom']['gate_inserts'].append(
                {'room': 'gate_rotation', 'gate': 40, 'floors': 2}), 'new gates (got 40)'),
            ('an entrance to an undefined gate', lambda d: [
                r for r in d['custom']['rooms'] if r['id'] == 'ember_keystone'][0][
                'screens']['0']['exits'].append(GT.gate_entrance_row(6, 2, 40)),
             'neither a vanilla gate')):
        expect_error(f"S115 refuses {name}", fx(mut), needle)
    # the editor model
    from editor2.core.document import Document
    import shutil
    tmpd = '/tmp/_t_ng_doc'
    if os.path.exists(tmpd):
        shutil.rmtree(tmpd)
    shutil.copytree(os.path.dirname(EXAMPLE), tmpd, ignore=shutil.ignore_patterns('build'))
    json.dump(_ng_fixture(), open(os.path.join(tmpd, 'project.json'), 'w'), indent=1)
    doc = Document(os.path.join(tmpd, 'project.json'))
    n = doc.new_gate(copy_of=0, name='Tiny gate', floors=3)
    ok("S115 doc: New gate takes the next free number (34) and lists in all_gates",
       n == 34 and [g['name'] for g in doc.all_gates() if g['id'] == 34] == ['Tiny gate'] and
       doc.gate_floor_count(34) == 3 and doc.gate_floor_count(33) == 11)
    rm = doc.room('dusk_mirror')
    doc.add_gate_entrance(rm, 0, 0, 2, 3, 34)
    ok("S115 doc: Gate entrance here — a portal-form exit row named after the gate",
       len(doc.gate_entrances(34)) == 1 and
       doc.gate_entrances(34)[0][3]['comment'] == 'gate entrance: Tiny gate')
    try:
        doc.add_gate_entrance(rm, 0, 0, 3, 3, 50)
        refused = False
    except ValueError:
        refused = True
    try:
        doc.set_gate_setting(34, name='')
        refused2 = False
    except ValueError:
        refused2 = True
    ok("S115 doc: no entrance to an undefined gate; a new gate cannot lose its name",
       refused and refused2)
    gone = doc.delete_gate(32)
    ok("S115 doc: Delete gate removes its rules and entrances too",
       gone == {'rules': 1, 'entrances': 1} and not doc.gate_entrances(32) and
       all(int(r['gate']) != 32 for r in doc.gate_inserts()) and
       32 not in doc.new_gate_ids())
    doc.save()
    compile_data(json.load(open(os.path.join(tmpd, 'project.json'))))
    ok("S115 doc: the edited project still compiles", True)
    return o


def test_new_gates_rom(tag, rom_bytes, sym, prj_data, orig):
    """--rom: the two same-size bank $16 forks, GateRowPtr, and bank $76's rows."""
    from editor2.core.project import Project

    def addr(lbl):
        b, a = sym[lbl]
        return b * 0x4000 + (a - 0x4000 if b else a)
    grp = sym['GateRowPtr'][1]
    call = bytes([0xCD, grp & 0xFF, grp >> 8])
    a1 = 0x16 * 0x4000 + 0x5B76 - 0x4000
    a2 = 0x16 * 0x4000 + 0x5BE1 - 0x4000
    ok(f"ROM S115 {tag}: entry 5's row readers are same-size calls to GateRowPtr "
       "($16:$5B76 call + 12 nops; $5BE1 call + inc hl x4 + 8 nops); the code around "
       "them == the ROM",
       sym['jr_016_5b72'] == (0x16, 0x5B72) and sym['jr_016_5be1'] == (0x16, 0x5BE1) and
       rom_bytes[a1:a1 + 15] == call + bytes(12) and
       rom_bytes[a2:a2 + 15] == call + bytes([0x23] * 4) + bytes(8) and
       rom_bytes[a1 - 4:a1] == orig[a1 - 4:a1] and
       rom_bytes[a1 + 15:a1 + 40] == orig[a1 + 15:a1 + 40] and
       rom_bytes[a2 + 15:a2 + 40] == orig[a2 + 15:a2 + 40])
    gt = addr('GateFloorDataTable')
    prj = Project(copy.deepcopy(prj_data), os.path.dirname(EXAMPLE))
    cfg = prj.gate_configs()
    ok(f"ROM S115 {tag}: GateFloorDataTable unmoved at $16:$70A6 == the project's 32 rows",
       sym['GateFloorDataTable'] == (0x16, 0x70A6) and
       all(rom_bytes[gt + 8 * g:gt + 8 * g + 8] == bytes(cfg[g]['row']) for g in range(32)))
    new = sorted(g for g in cfg if g >= 32)
    nr, ns = addr('NewGateRows'), addr('NewGateSource')
    ok(f"ROM S115 {tag}: NewGateRows / NewGateSource in bank $76 == the project's new gates "
       f"({len(new)})",
       all(rom_bytes[nr + 8 * (g - 32):nr + 8 * (g - 31)] == bytes(cfg[g]['row']) and
           rom_bytes[ns + g - 32] == cfg[g]['source'] for g in new) and
       sym.get('wGateRowBuf') == (1, 0xD138))


def _mu_fixture():
    """S116 (P3.13b): the example + songs that spill into bank $75 (a 4-channel, a
    5-channel and a 2-channel one), gate songs, battle songs, fights, names."""
    d = base()
    m = d['custom']['music']
    m['songs'] += [{'id': 'big15', 'source': {'library': 'dwm2_bgm15'}, 'first_id': 'auto'},
                   {'id': 'drums04', 'source': {'library': 'dwm2_bgm04'}, 'first_id': 'auto'},
                   {'id': 'five', 'source': {'library': 'dwm2_jingle09'}, 'first_id': 'auto'},
                   {'id': 'two', 'source': {'library': 'dwm2_jingle02'}, 'first_id': 'auto'}]
    m['names'] = {'0x09': 'Castle theme', 'big15': 'Big one'}
    m['gates'] = {'2': {'floors': 'drums04', 'battles': '0x0C'}, '5': {'battles': 'two'}}
    m['battle'] = {'normal': '0x31', 'boss': 'five', 'arena': 'big15', 'starry': 'drums04',
                   'rooms': {'0x01': '0x1E', '0x6C': 'two'}, 'fights': {'325': 'big15', '11': '0x2B'}}
    return d


MU_FIX = None


def _s117_fixture():
    """S117 (flag expansion + NG2): NG_FIX + 18 auto flags (16 vanilla-safe,
    then $1000 / $1001), an explicit extended flag, gate 1 re-bossed to
    Talisman's boss room, a swirl NPC over gate 32's entrance, an NPC shown
    only while a flag is set, the $24 Talisman portal re-routed to gate 32."""
    from editor2.core import gates as GT
    d = _ng_fixture()
    c = d['custom']
    c['flags'] = c.get('flags', []) + [{'name': f'auto{i}', 'index': 'auto'} for i in range(18)]
    c['flags'].append({'name': 'bell', 'index': '0x1100'})
    c['gates'].append({'gate': 1, 'boss': 'vanilla:$32'})
    rooms = {r['id']: r for r in c['rooms']}
    scr = rooms['ember_keystone']['screens']['0']
    scr.setdefault('npcs', []).append(GT.swirl_npc(5, 2, 32))
    scr['npcs'].append({'kind': 'npc', 'x': 7, 'y': 5, 'sprite': '0x4C', 'facing': 'down',
                        'script': None, 'shown_when': [{'flag': 'bell', 'is': 'set'}]})
    c.setdefault('entrance_redirects', []).append(
        {'mapID': '0x24', 'screen': 0, 'x': 2, 'y': 6, 'dest': 'gate:32', 'gate_flag': 1,
         'screen_byte': '0x00', 'spawn_x': 0, 'spawn_y': 0})
    return d


S117_FIX = None


def test_flags_ng2_s117():
    """S117: extended flags $1000-$17FF; NG2 gate cleared marks, swirl objects,
    flag-conditioned NPCs, vanilla portal swirl overrides, GateClearTable."""
    global S117_FIX
    from editor2.core import project as PJ
    from editor2.core import gates as GT
    ok("S117: flag_persistent — vanilla <$0278 and the extended $1000-$17FF are saved",
       PJ.flag_persistent(0x0158) and not PJ.flag_persistent(0x0278) and
       PJ.flag_persistent(0x1000) and PJ.flag_persistent(0x17FF) and
       not PJ.flag_persistent(0x1800) and not PJ.flag_persistent(0x0300))
    S117_FIX = _s117_fixture()
    o, prj, w = compile_data(S117_FIX)
    fm = prj.flag_map()
    ok("S117: the allocator takes the 16 vanilla-safe flags first, then $1000 up; an "
       "explicit extended index is kept",
       fm['auto0'] == 0x0158 and fm['auto15'] == 0x0167 and fm['auto16'] == 0x1000 and
       fm['auto17'] == 0x1001 and fm['bell'] == 0x1100, str(fm))
    ok("S117: gate:N — an unchanged vanilla gate = its own flag (Talisman $12), a re-bossed "
       "vanilla gate = $17A0 + 1, a new gate = $17A0 + 32",
       prj.resolve_flag_ref('gate:2') == 0x12 and prj.resolve_flag_ref('gate:1') == 0x17A1 and
       prj.resolve_flag_ref('gate:32') == 0x17C0 and prj.resolve_flag_ref('gate:0') == 0x10)
    for ref, needle in (('gate:31', 'no cleared flag'), ('gate:50', 'no such gate'),
                        ('0x0300', 'outside the event flags'), ('0x1800', 'outside the event flags')):
        try:
            prj.resolve_flag_ref(ref, 'test')
            ok(f"S117 refuses flag {ref}", False)
        except PJ.ProjectError as e:
            ok(f"S117 refuses flag {ref} ({needle})", needle in str(e), str(e))
    b60 = o['patches/bank_060.asm']
    ok("S117: a swirl NPC is emitted behind an $A1 prefix on gate 32's flag ($17C0, shown "
       "while CLEAR); the shown_when NPC behind an $A0 prefix on $1100 (shown while SET)",
       '$A1, $C0, $17, $FF, $FF' in b60 and '$00, $4D, $05, $02, $FF' in b60 and
       '$A0, $00, $11, $FF, $FF' in b60 and
       b60.index('$A1, $C0, $17, $FF, $FF') < b60.index('$00, $4D, $05, $02, $FF'))
    ov = prj.vanilla_swirl_overrides()
    r24 = [x for x in ov if x['mapID'] == 0x24]
    ok("S117: room $24 gets an NPC override (gate 1 re-bossed, its Talisman portal re-routed "
       "to gate 32): 4 versions, every version swirl-conditioned on $17A1 at (2,2) and "
       "$17C0 at (2,6)",
       len(r24) == 1 and r24[0]['step_counter'] == 0xD969 and len(r24[0]['steps']) == 4 and
       all(any(en['cond'] and en['cond'][0] == 0x17A1 and en['bytes'][2:4] == [2, 2]
               for en in st) and
           any(en['cond'] and en['cond'][0] == 0x17C0 and en['bytes'][2:4] == [2, 6]
               for en in st) for st in r24[0]['steps']), str(r24)[:400])
    ok("S117: only rooms whose portals changed get an override ($24 alone here)",
       [x['mapID'] for x in ov] == [0x24])
    ok("S117: VanillaNPCExtTable row + the variant lists in bank $60",
       'VanillaNPCExtTable:\n' in b60 and '    db $24, 0' in b60 and 'VNpc24_0_V3:' in b60)
    b76 = o['patches/bank_076.asm']
    ok("S117: GateClearTable — gate 1 ($17A1 + its vanilla $0011), gate 32 ($17C0 only), "
       "unchanged gates none; one row per gate 0-33",
       'GATE_CLEAR_LEN EQU 34' in b76 and '    dw $17A1, $0011, WinTail_1  ; gate 1' in b76 and
       '    dw $17C0, $FFFF, $0000  ; gate 32' in b76 and
       '    dw $FFFF, $FFFF, $0000  ; gate 0: its own boss scripts set its flag' in b76)
    ok("S122: re-bossed Villager replays the game's own win tail (WinTail_1: $D969 := 1, "
       "$D977 := 1, if Talisman's $0012 is clear skip, else $D969 := 3; the text close -> end)",
       'WinTail_1:' in b76 and '    dw $FF12, $D969, $0001' in b76 and
       '    dw $FF00, $0012, .t0_506A' in b76 and '    dw $FF12, $D969, $0003' in b76 and
       '    dw $FF14, WinTail_1_end  ; op $06 ends' in b76 and 'WinTail_32' not in b76)
    o0, _p0, _w0 = compile_data(base())
    ok("S117: the example — empty VanillaNPCExtTable, GateClearTable all $FFFF (32 rows), "
       "no prefixes",
       'VanillaNPCExtTable:\n    db $FF' in o0['patches/bank_060.asm'] and
       'GATE_CLEAR_LEN EQU 32' in o0['patches/bank_076.asm'] and
       '$A0, ' not in o0['patches/bank_060.asm'] and '$A1, ' not in o0['patches/bank_060.asm'])
    d = _s117_fixture()
    d['custom']['flags'].append({'name': 'gateflag', 'index': '0x17A0'})
    expect_error("S117 refuses a named flag on the gates' reserved $17A0-$17FF", d,
                 'outside EVENT_FLAGS.md safe')
    d = _s117_fixture()
    [r for r in d['custom']['rooms'] if r['id'] == 'ember_keystone'][0]['screens']['0'][
        'npcs'].append(GT.swirl_npc(1, 1, 31))
    expect_error("S117 refuses a swirl of the unused gate 31 (no cleared flag)", d,
                 'no cleared flag')
    # the editor model
    from editor2.core.document import Document
    import shutil
    tmpd = '/tmp/_t_s117_doc'
    if os.path.exists(tmpd):
        shutil.rmtree(tmpd)
    shutil.copytree(os.path.dirname(EXAMPLE), tmpd, ignore=shutil.ignore_patterns('build'))
    json.dump(_ng_fixture(), open(os.path.join(tmpd, 'project.json'), 'w'), indent=1)
    doc = Document(os.path.join(tmpd, 'project.json'))
    rm = doc.room('dusk_mirror')
    full = doc.add_gate_entrance(rm, 0, 0, 2, 3, 32)
    sw = doc.gate_swirls(32)
    ok("S117 doc: Gate entrance here adds the swirl object (swirl_of 32) on the same cell",
       not full and len(sw) == 1 and (sw[0][3]['x'], sw[0][3]['y']) == (2, 3) and
       sw[0][3]['sprite'] == '0x4d')
    ex = doc.exits_of(rm, 0, 0)
    doc.remove_exit(rm, 0, 0, [i for i, e in enumerate(ex) if GT.is_gate_entrance(e)][-1])
    ok("S117 doc: deleting the gate entrance takes its swirl with it", not doc.gate_swirls(32))
    doc.add_gate_entrance(rm, 0, 0, 2, 3, 32)
    i = doc.add_portal_redirect(0x24, 0, 2, 2, 32)
    ok("S117 doc: a vanilla portal re-routed to gate 32 (redirect gate:32, gate_flag 1)",
       doc.portal_redirects(32) and doc.custom['entrance_redirects'][i]['dest'] == 'gate:32')
    txt1, txt32 = doc.gate_cleared_text(1), doc.gate_cleared_text(32)
    ok("S117 doc: cleared-flag lines (Villager = the game's $0011; gate 32 its own $17C0)",
       '$0011' in txt1 and "the game's own" in txt1 and '$17C0' in txt32 and 'new gate' in txt32,
       f"{txt1!r} / {txt32!r}")
    doc.set_gate_setting(1, boss='vanilla:$32')
    ok("S117 doc: re-bossing Villager gives it its own flag ($17A1) + its vanilla $0011",
       '$17A1' in doc.gate_cleared_text(1) and '$0011' in doc.gate_cleared_text(1))
    gone = doc.delete_gate(32)
    ok("S117 doc: deleting a new gate removes its swirls and its portal re-routes",
       not doc.gate_swirls(32) and not doc.portal_redirects(32) and gone['entrances'] >= 2,
       str(gone))
    return o


def test_flags_ng2_rom(tag, rom, sym, origb):
    """S117 ROM-level: run the built engine on dwm/sm83 — ComputeFlagAddress for
    every index 0-$1FFF == the vanilla formula outside $1000-$17FF and wExtFlags
    inside (BC / DE preserved); CustomReadInteract on a fixture room (hidden bits
    from the prefixes) and on room $24 (override variant by its counter);
    GateBossWin sets the table's flags only on a boss floor."""
    from dwm.sm83 import CPU
    ram = {}
    st = {'bank': 1}

    def rd(a):
        if a < 0x4000:
            return rom[a]
        if a < 0x8000:
            return rom[st['bank'] * 0x4000 + a - 0x4000]
        return ram.get(a, 0)

    def wr(a, v):
        if 0x2000 <= a < 0x3000:
            st['bank'] = v or 1
        elif a >= 0x8000:
            ram[a] = v & 0xFF
    cpu = CPU(rd, wr)
    S = lambda n: sym[n][1]
    ext = S('wExtFlags')
    bad = []
    for idx in range(0, 0x2000):
        st['bank'] = 1
        cpu.call(S('ComputeFlagAddress'), bc=idx, de=0x1234, sp=0xDFF0)
        if 0x1000 <= idx < 0x1800:
            want = (ext + (idx - 0x1000) // 8) & 0xFFFF
        else:
            want = (0xD99B + idx // 8) & 0xFFFF
        if (cpu.hl, cpu.a, cpu.bc, cpu.de) != (want, 0x80 >> (idx & 7), idx, 0x1234):
            bad.append(idx)
    ok(f"ROM {tag}: ComputeFlagAddress over 0-$1FFF — vanilla formula outside $1000-$17FF, "
       "wExtFlags inside, BC / DE preserved", not bad, f"({bad[:6]})")
    ok(f"ROM {tag}: ROM0 ComputeFlagAddress keeps its address and the mask table $26D5",
       S('ComputeFlagAddress') == 0x26B3 and rom[0x26D5:0x26DD] == bytes([0x80 >> i for i in range(8)]))
    return cpu, ram, st


def test_s117_engine_rom(rom, sym, origb):
    cpu, ram, st = test_flags_ng2_rom('S117_FIX', rom, sym, origb)
    S = lambda n: sym[n][1]
    ext = S('wExtFlags')

    def setf(idx, on=True):
        a = (ext + (idx - 0x1000) // 8) if idx >= 0x1000 else 0xD99B + idx // 8
        m = 0x80 >> (idx & 7)
        ram[a] = (ram.get(a, 0) | m) if on else (ram.get(a, 0) & ~m & 0xFF)

    def npcs(mid, scr, counter=None):
        ram[S('wMapID')] = mid
        ram[S('wScreenIndex')] = scr
        if counter is not None:
            ram[counter[0]] = counter[1]
        st['bank'] = 0x60
        cpu.call(S('CustomReadInteract'), sp=0xDFF0)
        hl = cpu.hl
        if hl == 0:
            return None
        out, a = [], hl
        while ram.get(a, 0) != 0xFF and len(out) < 25:
            out.append(tuple(ram.get(a + k, 0) for k in range(5)))
            a += 5
        return out
    mid = 0x70                               # ember_keystone
    l0 = npcs(mid, 0)
    sw = [e for e in l0 if e[1] == 0x4D and e[2:4] == (5, 2)]
    sl = [e for e in l0 if e[1] == 0x4C]
    ok("ROM S117_FIX: custom room — no prefix reaches the buffer; flags clear -> the swirl "
       "shown, the bell NPC hidden (type bit 6)",
       not any(e[0] & 0xF0 == 0xA0 for e in l0) and sw and not sw[0][0] & 0x40 and
       sl and sl[0][0] & 0x40, str(l0))
    setf(0x17C0)
    setf(0x1100)
    l1 = npcs(mid, 0)
    sw = [e for e in l1 if e[1] == 0x4D and e[2:4] == (5, 2)]
    sl = [e for e in l1 if e[1] == 0x4C]
    ok("ROM S117_FIX: gate 32 cleared + bell set -> the swirl hidden, the bell NPC shown; "
       "the other entries byte-identical",
       sw[0][0] & 0x40 and not sl[0][0] & 0x40 and
       [e for e in l1 if e[1] not in (0x4D, 0x4C)] == [e for e in l0 if e[1] not in (0x4D, 0x4C)],
       str(l1))
    setf(0x17C0, False)
    res = {}
    for step in range(4):
        lst = npcs(0x24, 0, (0xD969, step))
        res[step] = {e[2:4]: bool(e[0] & 0x40) for e in lst if e[1] == 0x4D}
    ok("ROM S117_FIX: room $24 — every version shows both swirls while gates 1 (re-bossed) "
       "and 32 are not cleared", all(r == {(2, 2): False, (2, 6): False} for r in res.values()),
       str(res))
    setf(0x17A1)
    r2 = {e[2:4]: bool(e[0] & 0x40) for e in npcs(0x24, 0, (0xD969, 1)) if e[1] == 0x4D}
    ok("ROM S117_FIX: gate 1 cleared ($17A1) -> its (2,2) swirl hidden, (2,6) still shown",
       r2 == {(2, 2): True, (2, 6): False}, str(r2))
    ok("ROM S117_FIX: a vanilla room without an override returns HL = 0 (the vanilla path)",
       npcs(0x25, 0) is None and npcs(0x01, 8) is None)

    def win(gate, boss, cur, last, ingate=0, mapid=None):
        for k in list(ram):
            if ext <= k < ext + 256 or 0xD99B <= k < 0xD9FB:
                ram[k] = 0
        ram[S('wInGateworld')] = ingate
        ram[S('wMapID')] = boss if mapid is None else mapid
        ram[S('wBossMapType')] = boss
        ram[S('wCurrentFloor')] = cur
        ram[S('wLastFloor')] = last
        ram[S('wGateID')] = gate
        ram[0xC8ED] = 0
        st['bank'] = 0x76
        cpu.call(S('GateBossWin'), sp=0xDFF0)
        setb = sorted(i for i in list(range(0x300)) + list(range(0x1000, 0x1800))
                      if ram.get((ext + (i - 0x1000) // 8) if i >= 0x1000 else 0xD99B + i // 8, 0)
                      & (0x80 >> (i & 7)))
        return setb, ram[0xC8ED]
    ok("ROM S117_FIX: GateBossWin on gate 32's boss floor sets $17C0 (and the displaced "
       "$C8ED = $0E)", win(32, 0x71, 3, 4) == ([0x17C0], 0x0E), str(win(32, 0x71, 3, 4)))
    ok("ROM S117_FIX: GateBossWin on re-bossed gate 1 sets $17A1 and its vanilla $0011",
       win(1, 0x32, 4, 5)[0] == [0x11, 0x17A1], str(win(1, 0x32, 4, 5)))
    ok("ROM S117_FIX: GateBossWin sets nothing for an unchanged gate (2), off the boss floor, "
       "in a maze, or in another room",
       win(2, 0x32, 5, 6) == ([], 0x0E) and win(32, 0x71, 2, 4)[0] == [] and
       win(32, 0x71, 3, 4, ingate=1)[0] == [] and win(32, 0x71, 3, 4, mapid=0x70)[0] == [])


def _shop_fixture():
    """S117 (P3.13c): the example + Herb at 12 G, the Bazaar list reordered and
    cut to 4, a project shop (12 items) and a shopkeeper script for it."""
    d = base()
    gd = d.setdefault('gamedata', {})
    gd['items'] = {'1': {'price': 12}, '40': {'price': 150}}
    gd['shops'] = {'bazaar': [29, 1, 7, 40]}
    c = d['custom']
    c['shops'] = [{'id': 'pier', 'name': 'Pier stall',
                   'items': [1, 2, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15]}]
    c['dialogue'].append({'id': 'pier_hello', 'boxes': [['Welcome to', 'the pier!']]})
    c['scripts'].append({'id': 'pier_keeper', 'shop': {'shop': 'pier', 'text': 'pier_hello'}})
    return d


SHOP_FIX = None


def test_shops_s117():
    """S117 (P3.13c): item prices, the vanilla shop lists, project shops,
    shopkeeper scripts."""
    global SHOP_FIX
    from editor2.core import shops as SH
    o0, p0, _w0 = compile_data(base())
    r0 = SH.resolve(p0)
    ok("S117 shops: the example = the five vanilla lists (FAQ: Bazaar Herb Lovewater "
       "Antidote Repellent BeefJerky PorkChop WarpWing BeastTail) and vanilla prices",
       [l[2] for l in r0['lists']][0] == [1, 2, 7, 40, 19, 20, 29, 38] and
       r0['prices'][1] == 8 and r0['prices'][38] == 400 and len(r0['lists']) == 5 and
       'SHOP_COUNT EQU 5' in o0['patches/bank_077.asm'])
    ok("S117 shops: sell price rule (ShopSellPrice): 3/4, staffs 1/10, the gate shop full",
       SH.sell_price(1, 8) == 6 and SH.sell_price(0x18, 3000) == 300 and
       SH.sell_price(1, 8, gate_shop=True) == 8)
    SHOP_FIX = _shop_fixture()
    o, prj, w = compile_data(SHOP_FIX)
    b77 = o['patches/bank_077.asm']
    b03 = [v for k, v in o.items() if 'bank_003.asm' in k][0]
    ok("S117 shops: bank $77 — six lists (5 vanilla + Pier stall), Bazaar edited",
       'SHOP_COUNT EQU 6' in b77 and '    db $1d, $01, $07, $28, $ff' in b77 and
       '(custom.shops \'pier\')' in b77 and
       '    db $01, $02, $05, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f, $ff' in b77)
    ok("S117 shops: gd_item_info — Herb 12 G ($0C), Repellent 150 G ($96), others untouched",
       '$00, $0c, $00, $64' in b03 and '$07, $96, $00, $64' in b03 and
       '$00, $50, $00, $64' in b03)
    sc = [x for x in prj.custom['scripts'] if x['id'] == 'pier_keeper'][0]
    ok("S117 shops: a shop script lowers to greeting / write_ram wShopID 6 / op $04 0 "
       "$0680 / text $0682 / end",
       sc['ops'][1:] == [['op', 'write_ram', 'wShopID', 6], ['op', '0x04', 0, 0x0680],
                         ['text', 0x0682], ['end']] and sc['ops'][0][0] == 'text' and
       sc['ops'][0][1] == prj.text_id('pier_hello') if hasattr(prj, 'text_id') else
       sc['ops'][1:] == [['op', 'write_ram', 'wShopID', 6], ['op', '0x04', 0, 0x0680],
                         ['text', 0x0682], ['end']] and sc['ops'][0][1] >= 0x0A00,
       str(sc['ops']))
    def fx(mut):
        d = _shop_fixture()
        mut(d)
        return d
    for name, mut, needle in (
            ('an item id 44', lambda d: d['custom']['shops'][0]['items'].append(44), 'items are 1-43'),
            ('21 items', lambda d: d['custom']['shops'][0].update(items=[1] * 21), 'at most 20'),
            ('an empty list', lambda d: d['gamedata']['shops'].update(bazaar=[]), '1-20 item ids'),
            ('a price of 70000', lambda d: d['gamedata']['items'].update({'2': {'price': 70000}}),
             '0-65535'),
            ('an unknown vanilla shop', lambda d: d['gamedata']['shops'].update(pier=[1]),
             'unknown shop'),
            ('a shop script naming no shop', lambda d: d['custom']['scripts'].append(
                {'id': 'x', 'shop': {'shop': 'nowhere'}}), "unknown shop 'nowhere'"),
            ('two shops with one id', lambda d: d['custom']['shops'].append(
                {'id': 'pier', 'items': [1]}), 'used twice')):
        expect_error(f"S117 shops refuses {name}", fx(mut), needle)
    return o


def test_shops_rom(tag, rom, sym, origb, nlists, want_lists):
    """S117: ShopFill run from the built ROM == the ORIGINAL bank $09 choice +
    copy (run from the original ROM) for every map x screen; wShopID picks a
    list and is cleared."""
    from dwm.sm83 import CPU

    def mk(r):
        ram = {}
        st = {'bank': 9}

        def rd(a):
            if a < 0x4000:
                return r[a]
            if a < 0x8000:
                return r[st['bank'] * 0x4000 + a - 0x4000]
            return ram.get(a, 0)

        def wr(a, v):
            if 0x2000 <= a < 0x3000:
                st['bank'] = v or 1
            elif a >= 0x8000:
                ram[a] = v & 0xFF
        return CPU(rd, wr), ram, st
    S = lambda n: sym[n][1]
    co, ro, so = mk(origb)
    cn, rn, sn = mk(rom)
    bad = []
    for mid in list(range(0x6B)) + [0x6B, 0x70, 0x80, 0xFE]:
        for scr in range(16):
            out = []
            for cpu, ram, st in ((co, ro, so), (cn, rn, sn)):
                for k in range(0xC0D8, 0xC0F0):
                    ram[k] = 0xEE
                ram[0xC968], ram[0xC925] = mid, scr
                ram[S('wShopID')] = 0
                st['bank'] = 9
                cpu.call(0x472B, sp=0xDFF0)
                out.append(tuple(ram.get(k) for k in range(0xC0D8, 0xC0F0)))
            if want_lists is None and out[0] != out[1]:
                bad.append((mid, scr))
    ok(f"ROM {tag}: ShopFill (bank $77) == the original bank $09 stock fill for every "
       "map $00-$6A (+ custom ids) x screen 0-15 ($C0D8 + the 20-byte clear)",
       not bad, f"({bad[:5]})")
    if want_lists:
        for n, lst in enumerate(want_lists):
            for k in range(0xC0D8, 0xC0F0):
                rn[k] = 0xEE
            rn[S('wShopID')] = n + 1
            sn['bank'] = 9
            cn.call(0x472B, sp=0xDFF0)
            got = [rn.get(0xC0D8 + i) for i in range(len(lst) + 1)]
            ok(f"ROM {tag}: wShopID {n + 1} -> list {n} copied ({len(lst)} items + $FF), "
               "the rest of the 20 bytes zero, wShopID kept for the visit",
               got == lst + [0xFF] and all(rn.get(0xC0D8 + i) == 0 for i in range(len(lst) + 1, 20))
               and rn[S('wShopID')] == n + 1, str(got))
        rn[0xC8EB] = 0x11
        rn[0xC905] = 4
        sn['bank'] = 0x77
        cn.call(S('ShopClose'), sp=0xDFF0)
        ok(f"ROM {tag}: ShopClose — wShopID 0, wGameState bit 4 off, $C905 0",
           rn[S('wShopID')] == 0 and rn[0xC8EB] == 0x01 and rn[0xC905] == 0)
    ok(f"ROM {tag}: bank $09 keeps its address map (ShopBuyStockFill $4721, BazaarInventory "
       "$476B, ShopSellPrice $4BC8) and calls $7700 at $472B",
       rom[0x09 * 0x4000 + 0x472B - 0x4000: 0x09 * 0x4000 + 0x472B - 0x4000 + 5] ==
       bytes([0x21, 0x00, 0x77, 0xD7, 0xC9]) and
       rom[0x09 * 0x4000 + 0x476B - 0x4000: 0x09 * 0x4000 + 0x476B - 0x4000 + 9] ==
       origb[0x09 * 0x4000 + 0x476B - 0x4000: 0x09 * 0x4000 + 0x476B - 0x4000 + 9])


def test_sprite_budget_s117b():
    """S117b: the hardware sprite limits as build warnings (user: "Just warning
    is fine for now, and Ill build around it")."""
    from editor2.core import formats as F
    row = [{'kind': 'npc', 'x': x, 'y': 5} for x in (1, 4, 7)]
    w = F.sprite_budget(row)
    ok("S117b sprite limits: 3 NPCs on one row -> 'row 5 has 3 NPCs … shows only 1'",
       len(w) == 1 and w[0].startswith('row 5 has 3 NPCs') and 'only 1' in w[0], str(w))
    ok("S117b sprite limits: one NPC per row, hidden NPCs and spots do not warn",
       F.sprite_budget([{'kind': 'npc', 'x': 1, 'y': y} for y in range(6)] +
                       [{'kind': 'npc', 'x': 3, 'y': 2, 'hidden': True},
                        {'kind': 'examine', 'x': 5, 'y': 2},
                        {'kind': 'raw', 'bytes': [0x40, 6, 8, 2, 4]}]) == [])
    w = F.sprite_budget([{'kind': 'npc', 'x': 1, 'y': y} for y in range(7)])
    ok("S117b sprite limits: 7 NPCs -> 'only the first 6 … are drawn' (40 pieces, party 16)",
       len(w) == 1 and w[0].startswith('7 NPCs on screen') and 'first 6' in w[0], str(w))
    w = F.sprite_budget([{'kind': 'raw', 'bytes': [0, 6, x, 3, 4]} for x in (1, 5)])
    ok("S117b sprite limits: raw entries count by their y byte", len(w) == 1 and 'row 3' in w[0])
    d = base()
    _o, _p, warns = compile_data(d)
    n0 = sum('sprite pieces' in x for x in warns)
    r = next(r for r in d['custom']['rooms'] if not r.get('placeholder'))
    k = next(iter(r['screens']))
    sc = r['screens'][k]
    tgt = sc['states'][0] if sc.get('states') else sc
    tgt.setdefault('npcs', []).extend({'kind': 'npc', 'x': x, 'y': 7, 'sprite': '0x06',
                                       'script': None} for x in (1, 3, 5))
    _o, _p, warns = compile_data(d)
    ok("S117b sprite limits: the build warns for a room row with 3+ NPCs",
       sum('sprite pieces' in x for x in warns) > n0 and
       any(f"room {r['id']} screen {k}" in x and 'row 7 has' in x for x in warns),
       str([x for x in warns if 'sprite pieces' in x][:2]))


def test_clone_follows_game_s118c():
    """S118c (user S118b: the copied GreatTree showed the old man where the game
    shows the man by the cliff — "obviously" fix it): a screen whose
    step_counter names `vanilla` uses the ORIGINAL room's counter (an EQU, no
    byte in the region); a bad address is refused; state rules keep their own
    counter; the editor migrates rooms cloned before S118c."""
    d = base()
    r = next(x for x in d['custom']['rooms'] if x['id'] == 'gate_island')
    r['screens']['0']['step_counter'] = {'label': 'wCustomStep_t118_S0', 'vanilla': '0xD92D'}
    out, prj, _w = compile_data(d)
    txt = '\n'.join(v for v in out.values() if isinstance(v, str))
    ok("S118c clone state: the label is an EQU of the game's counter",
       'wCustomStep_t118_S0 EQU $D92D' in txt)
    ok("S118c clone state: nothing allocated for it in the $CD80 region",
       all(lbl != 'wCustomStep_t118_S0' for lbl, _a, _c in prj.step_counter_allocation()))
    d2 = base()
    r2 = next(x for x in d2['custom']['rooms'] if x['id'] == 'gate_island')
    r2['screens']['0']['step_counter'] = {'label': 'wCustomStep_t118_S0', 'vanilla': '0xC000'}
    expect_error("S118c clone state: a non-counter address is refused", d2,
                 "is not one of the game's room-state counters")
    import shutil
    import tempfile
    from editor2.core.document import Document
    tmp = tempfile.mkdtemp()
    d3 = base()
    r3 = next(x for x in d3['custom']['rooms'] if x['id'] == 'gate_island')
    r3['source_mapID'] = '0x01'
    for k, scr in r3['screens'].items():
        scr['step_counter'] = {'label': f'wCustomStep_gate_island_S{k}'}
    json.dump(d3, open(os.path.join(tmp, 'project.json'), 'w'))
    src_assets = os.path.join(os.path.dirname(EXAMPLE), 'assets')
    if os.path.isdir(src_assets):
        shutil.copytree(src_assets, os.path.join(tmp, 'assets'), dirs_exist_ok=True)
    doc = Document(tmp)
    r4 = next(x for x in doc.custom['rooms'] if x['id'] == 'gate_island')
    ok("S118c clone state: a pre-S118c clone is migrated on open (GreatTree screens 0 / 4)",
       r4['screens']['0']['step_counter'].get('vanilla') == '0xD92D' and
       r4['screens']['4']['step_counter'].get('vanilla') == '0xD92F' and
       any('follow the game' in n for n in doc.migrations), str(doc.migrations))
    shutil.rmtree(tmp, ignore_errors=True)


def _cs_fixture(scenes, cast=True, flags=('cs_seen',)):
    d = base()
    r = next(x for x in d['custom']['rooms'] if x['id'] == 'gate_island')
    npcs = r['screens']['0']['npcs']
    npcs[1]['actor'] = 'Guard'
    npcs[2]['actor'] = 'Bard'
    if cast:
        npcs.append({'kind': 'npc', 'sprite': '0x0B', 'x': 1, 'y': 3, 'facing': 'right',
                     'hidden': True, 'cast': True, 'script': 'none', 'actor': 'Ghost'})
    r['cutscenes'] = scenes
    d['custom']['flags'] = [{'name': f, 'index': 'auto'} for f in flags]
    return d, r


def test_cutscene_unnamed_npc_s119r2():
    """S119 r2 (user: "Why cant I select npc in a custom room when creating new
    cutscene? Want to select npc in Cities_FOUNT"): every NPC of the screen can be
    picked — one without a scene name is named when picked (a shopkeeper ->
    'Shopkeeper', else 'NPC n'), the trigger / steps hold the name."""
    import shutil
    import tempfile
    from editor2.core.document import Document
    from editor2.core import cutscene_doc as CD
    tmp = tempfile.mkdtemp()
    d = base()
    json.dump(d, open(os.path.join(tmp, 'project.json'), 'w'))
    src_assets = os.path.join(os.path.dirname(EXAMPLE), 'assets')
    if os.path.isdir(src_assets):
        shutil.copytree(src_assets, os.path.join(tmp, 'assets'), dirs_exist_ok=True)
    doc = Document(tmp)
    r = doc.room('gate_island')
    un = CD.unnamed_npcs(r, 0)
    ok("S119 r2 unnamed NPCs: the screen's NPCs without a name are listed",
       len(un) >= 2 and all(not e.get('actor') for _k, _n, e in un), str(un))
    k, n, _e = un[0]
    sid = CD.new_cutscene(doc, 'gate_island', 'Talk test', 0, 'talk', CD.npc_token(k, n))
    r, sc = CD.find(doc, sid)
    nm = sc['trigger'].get('actor')
    named = dict(CD.npc_rows(r, 0, k))[n].get('actor')
    ok("S119 r2 unnamed NPCs: picked for a talk scene -> named, the trigger holds the name",
       bool(nm) and nm == named and not CD.is_token(nm), f'{nm} / {named}')
    k2, n2, _e2 = CD.unnamed_npcs(r, 0)[0]
    step = {'walk': {'actor': CD.npc_token(k2, n2), 'to': [1, 1]}}
    out = CD.resolve_tokens(doc, 'gate_island', 0, step)
    ok("S119 r2 unnamed NPCs: a step's NPC token -> a fresh unique name",
       out['walk']['actor'] not in (nm, None) and not CD.has_tokens(out)
       and dict(CD.npc_rows(r, 0, k2))[n2].get('actor') == out['walk']['actor'], str(out))
    ok("S119 r2 unnamed NPCs: a named NPC's token gives its name back (no rename)",
       CD.resolve_tokens(doc, 'gate_island', 0, CD.npc_token(k, n)) == nm)
    shutil.rmtree(tmp, ignore_errors=True)


def test_cutscene_error_not_at_open_s119b():
    """S119b (user's editor would not open: "gamedata.encounters.0.eids[3] =
    'klamutra': no such enemy row" — a scene's too-long text made Project() fail,
    the Families tab fell back to a model without the project's enemies): a
    cutscene problem lets Project() build (the editor's models need it) and stops
    the BUILD with its message."""
    import copy
    d, r = _cs_fixture([{'id': 'longline', 'screen': 0, 'trigger': {'on': 'talk', 'actor': 'Guard'},
                         'steps': [{'say': {'boxes': [['Oh hello there! I am a shopkeep! '
                                                       'Stuck there for AGES.']]}}]}])
    prj = Project(copy.deepcopy(d), os.path.dirname(EXAMPLE))
    ok("S119b cutscene error: Project() still builds (the editor's models)",
       bool(prj.cutscene_error) and 'line 1 is' in prj.cutscene_error, str(prj.cutscene_error))
    ok("S119b cutscene error: the project's game data model works",
       prj.gamedata() is not None)
    expect_error("S119b cutscene error: the build stops with the scene's message", d,
                 'cutscenes[longline]')


def test_hero_default_s120b():
    """S120b (user: "change TERRY to MILLY as default, but leave otherwise as 4
    letters") — S121 moved it under the Milly hook: patches/bank_04f.asm region
    milly_name_tiles is the vanilla TERRY INCBIN; the hook draws the MILLY tiles
    (= textenc.MILLY_GLYPHS, what the previews draw while the hook is on); {hero}
    still counts 4 cells."""
    from editor2.core import milly as MH
    from editor2.core import textenc as Tx
    src = open(os.path.join(REPO, 'patches', 'bank_04f.asm')).read()
    body = src.split('; @BUILD_PROJECT BEGIN milly_name_tiles\n')[1].split(
        '; @BUILD_PROJECT END milly_name_tiles')[0]
    ok("S121: patches/bank_04f.asm region milly_name_tiles = the vanilla TERRY INCBIN",
       body == MH.TERRY_INCBIN + '\n', repr(body))
    ok("S121: milly.MILLY_TILES == textenc.MILLY_GLYPHS (the S120b drawing, 64 B)",
       b''.join(bytes.fromhex(h) for h in MH.MILLY_TILES) ==
       b''.join(Tx.MILLY_GLYPHS[c] for c in (0xD3, 0xD4, 0xD5, 0xD6)))
    ok("S120b: the original font still says TERRY there (clean tree untouched)",
       'image_04f_4d40.2bpp' in open(os.path.join(REPO, 'disassembly', 'bank_04f.asm')).read())
    ok("S120b: {hero} still counts 4 cells", Tx.TOKENS['{hero}'][1] == 4 and
       Tx.cells('Hi {hero}!') == 8)
    Tx.use_hero_glyphs(True)
    on = dict(Tx.PATCHED_GLYPHS)
    Tx.use_hero_glyphs(False)
    ok("S121: previews draw MILLY only with the hook (use_hero_glyphs)",
       on == Tx.MILLY_GLYPHS and Tx.PATCHED_GLYPHS == {})


def _milly_fixture(spin=True, arrive=None):
    d = base()
    d['custom']['milly_hook'] = {'enabled': True, 'spin': spin,
                                 'arrive': arrive or {'room': 'gate_island', 'screen': 0,
                                                      'x': 4, 'y': 4, 'face': 'right'}}
    return d


def _region(text, name):
    return text.split(f'; @BUILD_PROJECT BEGIN {name}\n')[1].split(
        f'; @BUILD_PROJECT END {name}')[0]


def test_milly_hook_s121():
    """S121 (ROADMAP P3.16 + E7, user: "In the intro, when Milayou disappears into
    dresser … do NOT return control to player to play as terry … At THIS POINT,
    player sprite is no longer Terry, it is MILLY … This whole thing can be switched
    off as a 'milly hook' patch")."""
    import shutil
    from editor2.core import milly as MH
    from editor2.core import cutscene_build as CB
    from editor2.core.document import Document
    from editor2.core.project import FLAG_SAFE_RANGES
    off, _p, _w = compile_data(base())
    vanilla = {
        'patches/bank_00e.asm': 'milly_bedroom_script', 'patches/bank_004.asm': 'milly_shape_04a',
        'patches/bank_001.asm': 'milly_player_sheet', 'patches/bank_009.asm': 'milly_naming_icon',
        'patches/bank_04f.asm': 'milly_name_tiles'}
    for f, reg in vanilla.items():
        ok(f"S121 hook off: {f} region {reg} == the committed (vanilla) text",
           _region(off[f], reg) == _region(open(os.path.join(REPO, f)).read(), reg))
    ok("S121 hook off: bank $79 stays the empty bank", 'ds $4000, $00' in off['patches/bank_079.asm']
       and 'MillyShapeTable' not in off['patches/bank_079.asm'])
    on, prj, _w = compile_data(_milly_fixture())
    b79 = on['patches/bank_079.asm']
    ok("S121 hook on: bank $79 = the template (entries 0/1) + Milayou's palette, sheet and frames",
       'dw MillyShapeTable' in b79 and 'dw MillyPlayerSheet' in b79 and
       'MillyPlayerAttr:' in b79 and 'dw $3114' in b79 and 'MillyLayoutImageEnd:' in b79)
    img = MH.layout_image()
    ok("S121: the frame-table image fits wMillyLayout (160 B)",
       0 < len(img) <= MH.WRAM_LAYOUT_SIZE, f"({len(img)} B)")
    ed = _region(on['patches/bank_00e.asm'], 'milly_bedroom_script')
    words = [int(w, 16) for ln in ed.split('\n') for w in re.findall(r'\$([0-9A-Fa-f]{4})', ln.split(';')[0])]
    ok("S121 hook on: the bedroom tail is exactly 94 words (same size)", len(words) == 94,
       f"({len(words)})")
    i = words.index(0xFF3B)
    ok("S121 hook on: glow sound $60, flag $179F set, the name MILLY, then warp_fade to the room",
       words[:2] == [0xFF21, 0x0060] and [0xFF03, 0x179F] == words[words.index(0xFF03):words.index(0xFF03) + 2]
       and words[i + 1] & 0xFF == 0x6B and words[i + 4] == 0xFFFF)
    for f, want in (('patches/bank_004.asm', 'ld hl, $7900'), ('patches/bank_001.asm', 'ld hl, $7901'),
                    ('patches/bank_009.asm', 'dw $3114')):
        ok(f"S121 hook on: {f} redirect ({want})", want in on[f])
    code = lambda t: [ln.split(';')[0].strip() for ln in t.split('\n') if ln.split(';')[0].strip()]
    ok("S121 hook on: both bank $04 metasprite paths redirected (6 bytes each)",
       code(_region(on['patches/bank_004.asm'], 'milly_shape_04a')) ==
       code(_region(on['patches/bank_004.asm'], 'milly_shape_04b')) ==
       ['ld hl, $7900', 'rst $10', 'nop', 'nop'])
    ok("S121 hook on: the MILLY tiles in bank $4F", ';MILLY' in _region(on['patches/bank_04f.asm'], 'milly_name_tiles')
       or 'MILLY' in _region(on['patches/bank_04f.asm'], 'milly_name_tiles'))
    ok("S121: the hook's flags are not in the named-flag pool",
       all(not (lo <= f <= hi) for f in MH.RESERVED_FLAGS for lo, hi in FLAG_SAFE_RANGES))
    ok("S121: hook:milly resolves to $179F", prj.resolve_flag_ref('hook:milly', 't') == 0x179F)
    # the arrival scene: the cast NPC (Milayou's sprite) + the entry scene in gate_island
    r = next(x for x in prj.custom['rooms'] if x['id'] == 'gate_island')
    ok("S121 hook on: the arrival room carries the hidden cast (sprite $14) and the scene",
       MH.CAST in json.dumps(r) and MH.SCENE_ID in json.dumps(r))
    expect_error("S121: hook on without an arrival is an error",
                 _milly_fixture(arrive={'room': ''}), 'pick where Milly arrives')
    expect_error("S121: arrival in a room that does not exist",
                 _milly_fixture(arrive={'room': 'nope', 'screen': 0, 'x': 4, 'y': 4}), 'nope')
    # the naming step
    ok("S121: name_hero is a step kind", 'name_hero' in CB.STEP_KINDS and
       CB.STEP_NAMES['name_hero'] == 'Name the hero')
    # the roots room, made the way the editor makes it
    tmp = '/tmp/_t_milly_roots'
    shutil.rmtree(tmp, ignore_errors=True)
    shutil.copytree(os.path.dirname(EXAMPLE), tmp, ignore=shutil.ignore_patterns('build'))
    doc = Document(os.path.join(tmp, 'project.json'))
    rid = doc.create_roots_room(REPO, None)
    room = doc.room(rid)
    ok("S121: Create the roots room = a copy of $08 with Warubou and the scene, keeps sprites over text",
       room.get('source_mapID') in ('0x08', 8) and room.get('text_keeps_sprites') is True and
       [sc['id'] for sc in room.get('cutscenes') or []] == [MH.ROOTS_SCENE])
    ok("S121: the roots room becomes the arrival when there was none",
       doc.milly_hook()['arrive']['room'] == rid)
    doc.set_milly_hook(enabled=True)
    sc = room['cutscenes'][0]
    kinds = lambda: [next(iter(st)) for st in sc['steps']]
    ok("S121 r3: a new roots room asks her name — say / Name the hero / say",
       doc.roots_naming(rid) and kinds()[2:5] == ['say', 'name_hero', 'say'], kinds())
    doc.set_roots_naming(rid, False)
    ok("S121 r3: naming off = one text, no naming screen",
       not doc.roots_naming(rid) and kinds().count('say') == 1 and 'name_hero' not in kinds(),
       kinds())
    doc.set_roots_naming(rid, True)
    ok("S121 r3: naming on again = the naming screen + a box right after his text",
       kinds()[2:5] == ['say', 'name_hero', 'say'] and
       sc['steps'][4]['say']['boxes'] == [list(b) for b in MH.ROOTS_TEXT_AFTER], kinds())
    doc.set_roots_scene_destination(rid, {'dest': 'room:$6B', 'screen': 0, 'x': 4, 'y': 4})
    ok("S121: the roots scene's destination is its last move step",
       doc.roots_scene_destination(rid) == {'dest': 'room:$6B', 'screen': 0, 'x': 4, 'y': 4})
    # S121 r3 (user: "Redirect from ROOTS ROOM into SBOSS" crashed): a move to a screen
    # the room lacks is refused at build (PyBoy: screen 12 of a 2-screen room = crash)
    doc.set_roots_scene_destination(rid, {'dest': 'room:$6D', 'screen': 12, 'x': 4, 'y': 6})
    doc.save()
    try:
        C.compile_project(tmp, REPO)
        bad = 'no error'
    except (ProjectError, C.CompileError) as e:
        bad = str(e)
    ok("S121 r3: a move to a screen the room does not have stops the build",
       'has no screen 12' in bad and 'its screens: 0' in bad, bad)
    from editor2.core.project import vanilla_screens
    ok("S121 r3: game rooms' screens known (GreatTree has 12, the Castle 1)",
       12 in vanilla_screens()[0x01] and 1 in vanilla_screens()[0x00])
    doc.set_roots_scene_destination(rid, {'dest': 'room:$6B', 'screen': 0, 'x': 4, 'y': 4})
    doc.save()
    outr, prjr, _w = C.compile_project(tmp, REPO)
    ok("S121: the roots-room project compiles (arrival + Warubou's scene + Name the hero)",
       'MillyShapeTable' in outr['patches/bank_079.asm'])
    ok("S121: the roots room keeps sprites over text (room flag bit 1, bank $06 region on)",
       'ld hl, $7108' in outr['patches/bank_006.asm'])
    return on


def test_maze_s122():
    """S122 (ROADMAP P3.7b part 2 + Phase 2C — user: "can I currently use gate
    themes for custom room build? … I would love to use them for custom rooms as
    an option for tileset, properly coloured"; "include carve trace")."""
    import shutil
    from editor2.core import maze as MZ
    from editor2.core.document import Document
    from editor2.core.render_project import ProjectRenderer
    rom = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    M = MZ.MazeRom(rom)
    ok("S122: maze tables read from the ROM (shape modes 0,0,0,1,2; piece 0 opens all four "
       "sides, piece 15 none; the carve starts at cell 5; 21 patterns)",
       M.shape == [0, 0, 0, 1, 2] and M.openings(0) == 15 and M.openings(15) == 0 and
       M.order[0] == 5 and len(M.patterns) == 21)
    J = json.load(open(os.path.join(REPO, 'extracted', 'maze_pieces.json')))
    ox = lambda sc: M.origin[sc][0] | M.origin[sc][1] << 8          # noqa: E731
    oy = lambda sc: M.origin[sc][2] | M.origin[sc][3] << 8          # noqa: E731
    same = 0
    for smp in J['samples']:
        i, g = smp['input'], smp['game']
        e = M.generate(i['seed'], i['size'], i['ft3'], i['progress'], i['npc_state'])
        st, sx, sy = e['stairs']
        ar, ax, ay = e['arrival']
        n = e['npc']
        fine = (e['mode'] == g['mode'] and e['grid'] == g['grid'] and
                [st, [ox(st) + sx, oy(st) + sy]] == [g['stairs_screen'], list(g['stairs_abs'])] and
                [ar, [ox(ar) + ax, oy(ar) + ay]] == [g['arrival_screen'], list(g['arrival_abs'])] and
                ((n is None and g['npc_screen'] == 0xFF) or
                 (n is not None and [n['screen'], n['kind']] == [g['npc_screen'], g['npc_kind']])) and
                [[t['kind'], t['sub'], t['screen'], t['x'], t['y']] for t in e['items']] ==
                [[t['kind'], t['sub'], t['screen'], t['x'], t['y']] for t in g['items']] and
                e['rng'] == g['rng'])
        same += fine
    ok(f"S122: the floor model == {len(J['samples'])} floors recorded from the game "
       "(grid, shape mode, stairs, NPC, arrival, items, RNG — tools/census_maze.py)",
       len(J['samples']) >= 25 and same == len(J['samples']), f'({same} equal)')
    ok("S122: the census JSON says 0 mismatches on its floors and 0 differing screens",
       J['census']['floors']['mismatches'] == 0 and J['census']['screens']['with_differences'] == 0)
    mode, g, _s = M.carve(0x8192, 2)
    ok("S122: maze size 2 can carve an EMPTY floor (the game spins: census freeze probe)",
       mode == 0 and all(c & 0xF0 == 0xF0 for c in g) and
       J['census']['freeze_probe']['builder_finished'] is False)
    empty = sum(1 for sz in range(3, 16) for sd in range(0, 65536, 97)
                if all(c & 0xF0 == 0xF0 for c in M.carve(sd, sz)[1]))
    ok("S122: sizes 3-15 never carve an empty floor (model sweep)", empty == 0)
    for bad in (0, 1, 2, 16, 255):
        d = base()
        d.setdefault('gamedata', {}).setdefault('encounters', {})['3'] = {'maze_size': bad}
        expect_error(f"S122 refuses maze_size {bad}", d, 'gate floors need 3-15')
    for good in (3, 15):
        d = base()
        d.setdefault('gamedata', {}).setdefault('encounters', {})['3'] = {'maze_size': good}
        compile_data(d)
        ok(f"S122: maze_size {good} compiles", True)
    # the editor model
    tmpd = '/tmp/_t_maze_doc'
    if os.path.exists(tmpd):
        shutil.rmtree(tmpd)
    shutil.copytree(os.path.dirname(EXAMPLE), tmpd, ignore=shutil.ignore_patterns('build'))
    doc = Document(os.path.join(tmpd, 'project.json'))
    r = ProjectRenderer(REPO, doc.project_dir, doc.data)
    doc.vanilla = r
    ok("S122: the example's S39 island rooms ($28:$0D) are gate theme 13",
       doc.gate_theme(doc.room('gate_island')) == 13 and doc.gate_theme(doc.room('arena_clone')) is None)
    rid = doc.new_room('Ice test', 0, r, gate_theme=4)
    room = doc.room(rid)
    pal = doc.palette(room['render']['palette'])
    words = [[int(c, 16) for c in row] for row in pal['colors_rgb555'][:4]]
    ok("S122: New room on gate theme 4 = sheet $28:$04, threshold $30, no animation, the "
       "theme's four palettes, protected tiles $00-$3F, a floor of tile $33",
       room['record']['gfx_bank'] == '0x28' and room['record']['gfx_id'] == '0x04' and
       room['record']['collision_threshold'] == '0x30' and room['animation'] == 'none' and
       words == M.theme_palette_words(4) and doc.gate_theme(room) == 4 and
       doc.room_sources_vocab(room) == set(range(0x40)) and
       doc.layout(room['screens']['0']['layout']['id'])['tiles'][0][0] == 0x33)
    lid = doc.stamp_maze_screen(rid, 0, 0, 0x5C, 0, r)
    tiles, attr = M.cell_grids(0x5C, 0)
    sc = room['screens']['0']
    ok("S122: Maze screen = the cell's tiles AND palette slots in a new layout item; the "
       "screen points at it for both; the floor item stays (the room's default attr)",
       doc.layout(lid)['tiles'] == tiles and doc.layout(lid)['attr'] == attr and
       sc['layout'] == {'id': lid} and sc['attr'] == {'id': lid} and lid != f'{rid}_s0' and
       doc.has_layout(f'{rid}_s0'))
    lid2 = doc.stamp_maze_screen(rid, 0, 0, 0x0C, 0, r)
    ok("S122: a second Maze screen replaces the first (the screen owned it alone)",
       not doc.has_layout(lid) and doc.layout(lid2)['tiles'] == M.cell_grids(0x0C, 0)[0])
    nts = len(doc.custom.get('tilesets') or [])
    mt = doc.well_metatile(room, 0, 0, 3, 3)
    ok("S122: Stairs down in a gate-theme room paints the theme's own stairs ($3C-$3F, no "
       "import)", mt['tiles'] == [0x3C, 0x3D, 0x3E, 0x3F] and
       len(doc.custom.get('tilesets') or []) == nts and 'tileset' not in room['record'])
    doc.set_room_tileset('dusk_mirror', 'gate', 9)
    pid, kept = doc.use_theme_palette('dusk_mirror', 9)
    dm = doc.room('dusk_mirror')
    ok("S122: Change tileset -> gate theme 9 (+ its colours as the room default)",
       dm['record']['gfx_id'] == '0x09' and dm['render']['palette'] == pid and
       doc.gate_theme(dm) == 9)
    doc.save()
    out, _p, _w = C.compile_project(tmpd, REPO)
    ok("S122: the project with a theme room compiles (bank $71 record row $28/$04/$30)",
       'patches/bank_071.asm' in out and 'Ice test' in json.dumps(doc.data))
    # a project copy of a theme sheet is still the theme (origin)
    tid = doc.set_room_tileset(rid, 'own')
    ok("S122: an own copy of a theme sheet is still that theme (tileset origin)",
       doc.gate_theme(doc.room(rid)) == 4 and tid != '28:04')
    return out

def _world_fixture():
    """S123 (ROADMAP NG3): the example + a world built with the editor's own
    operations (WorldsMixin): two new rooms joined by doors, the portal in the
    example's dusk_mirror room, a mini-boss (Make boss) with its own flag, the
    end boss turning the world's cleared flag ON, a battle room with its own
    list (+ a variant after clearing), the swirl going green once cleared, and
    an NPC drawn in another colour. Returns (doc, gid, rooms)."""
    import shutil
    from editor2.core.document import Document
    from editor2.core.render_project import ProjectRenderer
    tmpd = '/tmp/_t_world_doc'
    if os.path.exists(tmpd):
        shutil.rmtree(tmpd)
    shutil.copytree(os.path.dirname(EXAMPLE), tmpd, ignore=shutil.ignore_patterns('build'))
    doc = Document(os.path.join(tmpd, 'project.json'))
    r = ProjectRenderer(REPO, doc.project_dir, doc.data)
    doc.vanilla = r
    start = doc.new_room('World start', 0, r, gate_theme=9)
    cave = doc.new_room('World cave', 0, r, gate_theme=1)
    gid = doc.new_world('Test World', start, 0, 4, 4)
    doc.add_world_room(gid, cave)
    doc.set_cleared_swirl(gid, 1)
    for y in (3, 4):
        a = doc.add_door(start, 0, 9, y)
        b = doc.add_door(cave, 0, 0, y)
        doc.link_doors(a, b)
    # the way out: a one-way exit back to the example's dusk_mirror
    doc.add_teleport(doc.room(start), 0, 0, 1, 6, 'room:$6C', 0, 4, 4)
    doc.add_world_entrance(doc.room('dusk_mirror'), 0, 0, 4, 2, gid)
    doc.room(cave)['encounters'] = {'enabled': True, 'list': 3, 'rate': 5,
                                    'variants': [{'when': [{'flag': f'gate:{gid}'}],
                                                  'list': 4}]}
    i = doc.add_npc(doc.room(cave), 0, 0, 6, 3, 0, monster=197)
    j = doc.add_npc(doc.room(cave), 0, 0, 6, 4, 0, monster=197)
    sid = doc.make_boss(doc.room(cave), 0, 0, i, [99], 'cave_guard_beaten',
                        intro=[['I guard the cave']])
    doc.update_npc(doc.room(cave), 0, 0, j, script=sid)
    doc.set_npc_shown_when(doc.room(cave), 0, 0, j, [{'flag': 'cave_guard_beaten',
                                                       'is': 'clear'}])
    k = doc.add_npc(doc.room(cave), 0, 0, 3, 6, 0, monster=43)
    doc.make_boss(doc.room(cave), 0, 0, k, [125], 'cave_king_beaten',
                  intro=[['I am the king']], end_of_world=gid)
    c = doc.add_npc(doc.room(start), 0, 0, 2, 2, 0x14)
    doc.set_npc_colour(doc.room(start), 0, 0, c, 4)
    v = doc.add_npc(doc.room(start), 0, 0, 6, 6, 0x08)
    vs = doc.new_conversation(doc.room(start), {'steps': [
        {'if': [{'flag': f'gate:{gid}', 'is': 'set'}],
         'then': [{'say': {'boxes': [['It is cleared']]}}],
         'else': [{'say': {'boxes': [['Not yet']]}}]}]}, name='villager')
    doc.update_npc(doc.room(start), 0, 0, v, script=vs)
    doc.save()
    return doc, gid, {'start': start, 'cave': cave}


def _flag_sites_fixture():
    """S124: the example + one of every flag site the world / S117 / encounter
    fixtures do not have: a simple talk (YES sets, NO clears), a cutscene whose
    start tests flags ON / OFF / once and whose steps test, set, clear and ask, an
    NPC drawn in a colour while a flag is ON, a gate-floor room rule on a flag, a
    script prelude with a raw flag op; plus a flag nothing turns ON and an unused one."""
    d, r = _cs_fixture([{
        'id': 'ks_scene', 'name': 'Sites', 'screen': 0,
        'trigger': {'on': 'entry', 'when_on': ['ks_a'], 'when_off': ['ks_b'], 'once': 'ks_c'},
        'steps': [{'if': [{'flag': 'ks_a'}, {'flag': 'gate:1', 'is': 'clear'}],
                   'then': [{'set': ['ks_b']}], 'else': [{'clear': ['ks_a']}]},
                  {'ask': {'boxes': [['Again?']]}, 'yes': [{'set': ['ks_d']}],
                   'no': [{'clear': ['ks_d']}]}]}],
        flags=('ks_a', 'ks_b', 'ks_c', 'ks_d', 'ks_never', 'ks_unused'))
    c = d['custom']
    c['dialogue'] += [{'id': 'ks_q', 'boxes': [['Ring the bell?']], 'choice': True},
                      {'id': 'ks_y', 'boxes': [['Dong.']]}]
    c['scripts'].append({'id': 'ks_talk', 'talk': {
        'text': 'ks_q', 'question': True, 'yes': {'text': 'ks_y', 'set': ['ks_a']},
        'no': {'clear': ['ks_b', '0x1005']}}})
    r['scripts']['7'] = 'ks_talk'
    npcs = r['screens']['0']['npcs']
    npcs[2]['script'] = 'ks_talk'
    npcs[1]['colour'] = {'palette': 1, 'when': 'ks_d'}
    npcs.append({'kind': 'npc', 'sprite': '0x0B', 'x': 8, 'y': 6, 'facing': 'down',
                 'script': None, 'shown_when': [{'flag': 'ks_never'}]})
    c['gate_inserts'][0]['when'] = [{'flag': 'ks_b'}, {'flag': 'ks_c', 'is': 'clear'}]
    c['script_preludes']['give_jerky'] = [['op', 'set_flag', '0x1006']]
    # S125: a hub rule on a flag + a talk that sends the player home
    c['hub'] = {'rules': [{'when': [{'flag': 'ks_d', 'is': 'clear'}], 'room': 'gate_island',
                           'screen': 0, 'x': 4, 'y': 4}, {'room': 'castle'}]}
    c['scripts'][-1]['talk']['no']['move'] = {'dest': 'hub'}
    return d


def _hub_fixture(rules=None, scenes=(), flags=('hub_moved',)):
    """S125: the example with a hub — gate_island screen 0 (4,4) while hub_moved is
    OFF, the Castle after."""
    d, r = _cs_fixture(list(scenes), flags=flags)
    d['custom']['hub'] = {'rules': rules if rules is not None else [
        {'when': [{'flag': 'hub_moved', 'is': 'clear'}], 'room': 'gate_island',
         'screen': 0, 'x': 4, 'y': 4, 'comment': 'the main game'},
        {'room': 'castle', 'comment': 'the post-game'}]}
    return d, r


def CD_find(doc, sid):
    from editor2.core import cutscene_doc as CD
    return CD.find(doc, sid)[1]


def _ops_of(prj, sid):
    return prj._scripts[sid]['ops']


def test_hub_s125():
    """S125 (ROADMAP P3.14d): custom.hub — the rules -> HubTable, the script ladders
    (a conversation's / cutscene's move to "the hub", the Anchor skill's gate exit),
    the hub room's arrival script (arrival scenes first, the default heal), the
    Heal step, and the refusals. No hub = the vanilla Castle, byte for byte."""
    from editor2.core import cutscene_build as CB
    from editor2.core import formats as F
    out, prj, _w = compile_data(base())
    b71 = out['patches/bank_071.asm']
    i = b71.index('HubTable:')
    ok("S125: no custom.hub -> HubTable is one `db $FF` (every send: the Castle)",
       b71[i:].split('\n')[1].strip() == 'db $FF' and prj.hub_rules() == [])
    sk = json.load(open(os.path.join(REPO, 'editor2', 'core', 'skill_scripts.json')))
    a0 = next(x for x in sk['scripts'] if x['id'] == 'skill:anchor_gate_confirm')['ops']
    a1 = next(x for x in prj.skill_scripts if x['id'] == 'skill:anchor_gate_confirm')['ops']
    def notext(ops):            # the ops without texts, numbers as numbers
        return [[int(p, 16) if isinstance(p, str) and p.startswith('0x') else p for p in x]
                for x in ops if isinstance(x, list) and x[0] != 'text']
    ok("S125: no hub -> the Anchor skill's gate exit is untouched", notext(a0) == notext(a1))
    ok("S125: the reasons agree (Project / cutscenes / patches/wram.asm HUB_* EQUs)",
       CB.ARRIVAL_NUM == Project.HUB_REASONS and CB.W_HUB_REASON == Project.W_HUB_REASON
       and all(f'HUB_{k.upper()} EQU {v}' in open(os.path.join(REPO, 'patches', 'wram.asm')).read()
               for k, v in Project.HUB_REASONS.items()
               if k not in ('lost', 'wiped', 'warpwing', 'final_lost'))
       and all(f'HUB_{n} EQU {v}' in open(os.path.join(REPO, 'patches', 'wram.asm')).read()
               for n, v in (('LOST', 1), ('WIPED', 2), ('WARPWING', 3), ('FINAL_LOST', 4))))

    # a hub: gate_island while hub_moved is OFF, then the Castle
    welcome = {'id': 'hub_welcome', 'name': 'Welcome back', 'screen': 0,
               'trigger': {'on': 'entry', 'arrival': ['lost', 'wiped']},
               'steps': [{'say': {'boxes': [['You lost!', 'Rest now.']]}}, {'heal': {}}]}
    plain = {'id': 'hub_plain', 'name': 'Plain entry', 'screen': 0,
             'trigger': {'on': 'entry', 'once': 'hub_once'},
             'steps': [{'say': {'boxes': [['Hello.']]}}]}
    d, r = _hub_fixture(scenes=[plain, welcome], flags=('hub_moved', 'hub_once'))
    d['custom']['dialogue'].append({'id': 'hub_bye', 'boxes': [['Off you go.']]})
    d['custom']['scripts'].append({'id': 'hub_sender', 'talk': {'steps': [
        {'say': 'hub_bye'}, {'move': {'dest': 'hub'}}]}})
    r['scripts']['8'] = 'hub_sender'
    r['screens']['0']['npcs'][2]['script'] = 'hub_sender'
    out, prj, _w = compile_data(d)
    hm = prj.resolve_flag_ref('hub_moved')
    rules = prj.hub_rules()
    ok("S125: the rules resolve (room, pixel = 16*cell+8, terms, the Castle)",
       len(rules) == 2 and rules[0]['mapID'] == 0x6B and (rules[0]['px'], rules[0]['py']) == (72, 72)
       and rules[0]['terms'] == [(hm, True)] and rules[1]['castle']
       and (rules[1]['mapID'], rules[1]['px'], rules[1]['py']) == (0, 0xE8, 0x58), rules)
    b71 = out['patches/bank_071.asm']
    tab = b71[b71.index('HubTable:'):].split('\n')
    want = [F.db_line([1]).split(';')[0].strip(),
            f'dw ${hm | 0x8000:04X}',
            F.db_line([0x6B, 72, 0, 72, 0]).split(';')[0].strip(),
            F.db_line([0]).split(';')[0].strip(),
            F.db_line([0, 0xE8, 0, 0x58, 0]).split(';')[0].strip(), 'db $FF']
    got = [x.split(';')[0].strip() for x in tab[1:7]]
    ok("S125: HubTable = [1, dw flag|$8000, $6B 72 0 72 0] [0, 0 $E8 0 $58 0] $FF", got == want,
       f'{got} != {want}')
    a1 = next(x for x in prj.skill_scripts if x['id'] == 'skill:anchor_gate_confirm')['ops']
    flat = [x for x in a1 if isinstance(x, list)]
    ok("S125: the Anchor skill's gate exit -> the hub ladder (reason WarpWing = 3; the "
       "Castle branch keeps $D92B := 6)",
       any(x[:3] == ['op', 'if_flag_set', hm] for x in flat)
       and flat.index(['op', 'write_ram', '0xD2EF', 3]) + 1 ==
       flat.index(['op', 'map_transition', '0x006B', '0x0048', '0x0048'])
       and flat.index(['op', 'write_ram', '0xD92B', 6]) + 1 ==
       flat.index(['op', 'map_transition', '0x0000', '0x00E8', '0x0058']), flat)
    snd = _ops_of(prj, 'hub_sender')
    ok("S125: a conversation's move to the hub = the ladder (reason home = 5)",
       ['op', 'write_ram', '0xD2EF', 5] in snd
       and ['op', 'map_transition', '0x006B', '0x0048', '0x0048'] in snd
       and ['op', 'write_ram', '0xD92B', 6] in snd, snd)
    room = prj.room_by_id('gate_island')
    eid = room['scripts']['0']
    ent = _ops_of(prj, eid)
    flat = [x for x in ent if isinstance(x, list)]
    iw = next(k for k, x in enumerate(ent) if x == ['op', 'check_and_branch', '0xD2EF', 1,
                                                     '@cs_hub_welcome_arr'])
    ip = next(k for k, x in enumerate(ent) if isinstance(x, list) and x[1:3] == ['if_flag_set',
                                                prj.resolve_flag_ref('hub_once')])
    ok("S125: the arrival scene plays first (before an ordinary entry scene listed before it)",
       eid == 'cut:gate_island:entry' and iw < ip, ent[:12])
    ok("S125: the arrival guard = reason 1 or 2, then the scene takes the reason",
       ['op', 'check_and_branch', '0xD2EF', 2, '@cs_hub_welcome_arr'] in flat
       and ent[ent.index('label:cs_hub_welcome_arr') + 1] == ['op', 'write_ram', '0xD2EF', 0])
    ok("S125: the Heal step = op $27 refresh_party", ['op', 'refresh_party'] in flat)
    dflt = CB.hub_default_ops()
    kd = next(k for k in range(len(ent)) if ent[k:k + 4] == dflt)
    ok("S125: the hub room's default welcome after the arrival scenes, before the other "
       "entry scenes (one may warp away): a reason no scene took -> heal + take it",
       iw < kd < ip and ent.count(dflt[0]) == 1, kd)
    _o2, prj2, _w2 = compile_data(_hub_fixture()[0])
    e2 = _ops_of(prj2, prj2.room_by_id('gate_island')['scripts']['0'])
    ok("S125: a hub room's arrival script starts with the WarpWing reveal ($C8EC := 0)",
       ent[:5] == CB.hub_reveal_ops() and e2[:5] == CB.hub_reveal_ops(), ent[:5])
    ok("S125: a hub room without scenes still gets the welcome, then its own entry script",
       e2[5:10] == CB.hub_default_ops() + ['label:cut_orig']
       and any(isinstance(x, list) for x in e2[10:]), e2[:12])
    _o3, prj3, _w3 = compile_data(_hub_fixture(rules=[{'room': 'castle'}])[0])
    a3 = next(x for x in prj3.skill_scripts if x['id'] == 'skill:anchor_gate_confirm')['ops']
    ok("S125: a hub that is only the Castle -> the Anchor exit is the original ops",
       notext(a3) == notext(a0))
    d4, _r4 = _hub_fixture()
    d4['custom']['scripts'].append({'id': 'hub_helper', 'talk': {'steps': [
        {'helper': {'dest': 'hub', 'castle': 'king', 'king_speech': '0x31'}}]}})
    _r4['scripts']['8'] = 'hub_helper'
    _r4['screens']['0']['npcs'][2]['script'] = 'hub_helper'
    _o4, prj4, _w4 = compile_data(d4)
    hh = [x for x in _ops_of(prj4, 'hub_helper') if isinstance(x, list)]
    ok("S125: the helper exit to the hub: warp_fade, the Castle branch keeps the King's speech",
       ['op', 'warp_fade', '0x006B', '0x0048', '0x0048'] in hh
       and ['op', 'write_ram', '0xD92B', 7] in hh and ['op', 'write_ram', '0xD92B', 6] not in hh
       and hh[-2] == ['op', 'warp_fade', '0x0000', '0x00E8', '0x0058'], hh[-6:])

    # S125 review: a `once` arrival scene that skips leaves the reason to the default heal
    d8, _r8 = _hub_fixture(scenes=[dict(welcome, trigger={'on': 'entry', 'arrival': ['lost'],
                                                         'once': 'hub_once'})],
                           flags=('hub_moved', 'hub_once'))
    _o8, prj8, _w8 = compile_data(d8)
    e8 = _ops_of(prj8, prj8.room_by_id('gate_island')['scripts']['0'])
    io = next(k for k, x in enumerate(e8) if isinstance(x, list) and x[1] == 'if_flag_set'
              and x[2] == prj8.resolve_flag_ref('hub_once'))
    ic = e8.index(['op', 'write_ram', '0xD2EF', 0])
    ok("S125: an arrival scene's `once` test comes before it takes the reason", io < ic,
       (io, ic))

    # the validator's warnings
    d5, r5 = _hub_fixture(scenes=[dict(welcome, steps=[{'say': {'boxes': [['Hi.']]}}])])
    r6 = next(x for x in d5['custom']['rooms'] if x['id'] == 'dusk_mirror')
    r6['cutscenes'] = [dict(welcome, id='stray', name='Stray')]
    _o5, _p5, w5 = compile_data(d5)
    ok("S125 warns: a loss arrival scene without a Heal step",
       any('Welcome back' in w and 'no Heal step' in w for w in w5), w5[:3])
    ok("S125 warns: an arrival scene in a room no hub rule sends the player to",
       any('Stray' in w and 'never plays' in w for w in w5))

    # the editor's document side (editor2/core/hub_doc.py)
    import shutil
    import tempfile
    from editor2.core.document import Document
    tmp = tempfile.mkdtemp()
    json.dump(base(), open(os.path.join(tmp, 'project.json'), 'w'))
    shutil.copytree(os.path.join(os.path.dirname(EXAMPLE), 'assets'),
                    os.path.join(tmp, 'assets'), dirs_exist_ok=True)
    doc = Document(tmp)
    nm = doc.add_flag('hub_moved')
    i0 = doc.add_hub_rule({'room': 'castle'})
    i1 = doc.add_hub_rule({'when': [{'flag': nm, 'is': 'clear'}], 'room': 'gate_island',
                           'screen': 0, 'x': 4, 'y': 4}, index=0)
    ok("S125 doc: rules added in order (the conditional one first), described in words",
       (i0, i1) == (0, 0) and [r['room'] for r in doc.hub_rules()] == ['gate_island', 'castle']
       and doc.hub_rule_text(doc.hub_rules()[0]).startswith('while hub_moved is OFF → ')
       and 'Castle' in doc.hub_rule_text(doc.hub_rules()[1]), doc.hub_rules())
    ok("S125 doc: moving the unconditional rule up is reported as a problem",
       doc.move_hub_rule(1, -1) == 0 and any('never applies' in t for t in doc.hub_problems()))
    doc.move_hub_rule(0, 1)
    new = doc.add_arrival_scenes('gate_island')
    sc = [CD_find(doc, x) for x in new]
    ok("S125 doc: Add the arrival scenes -> loss (+heal) / WarpWing (+heal) / home, at the "
       "hub cell",
       len(new) == 3 and sc[0]['trigger']['arrival'] == ['lost', 'wiped', 'final_lost']
       and sc[0]['steps'][-1] == {'heal': {}} and sc[2]['trigger']['arrival'] == ['home']
       and sc[0]['player_start'] == {'x': 4, 'y': 4, 'face': 'down'}, sc)
    ok("S125 doc: a second Add skips the reasons already taken", doc.add_arrival_scenes('gate_island') == [])
    doc.save()
    _o7, prj7, w7 = C.compile_project(tmp, REPO)
    ok("S125 doc: the project builds with the hub and its arrival scenes, no hub warnings",
       prj7.hub_rules()[0]['room_id'] == 'gate_island'
       and not [w for w in w7 if 'arrival' in w], [w for w in w7 if 'arrival' in w])
    doc.remove_hub_rule(0)
    doc.remove_hub_rule(0)
    ok("S125 doc: removing every rule removes custom.hub (the Castle again)",
       'hub' not in doc.custom and doc.hub_rules() == [])

    # refusals
    def bad(rules, needle, tag):
        expect_error(f"S125 refuses {tag}", _hub_fixture(rules=rules)[0], needle)
    bad([{'room': 'castle'}, {'room': 'gate_island', 'x': 1, 'y': 1}],
        'always wins', 'a rule after one with no conditions')
    bad([{'room': 'nowhere', 'x': 1, 'y': 1}], 'not a custom room', 'an unknown room')
    bad([{'room': 'gate_island', 'screen': 7, 'x': 1, 'y': 1}], 'has no screen 7',
        'a screen the room does not have')
    bad([{'room': 'gate_island', 'x': 10, 'y': 1}], 'outside the 10x8', 'a cell off the screen')
    bad([{'room': 'gate_island'}], 'x / y is required', 'a rule without its cell')
    sc = dict(welcome, trigger={'on': 'talk', 'actor': 'Guard', 'arrival': ['lost']})
    expect_error("S125 refuses arrival reasons on a talk scene",
                 _hub_fixture(scenes=[sc])[0], 'belong to an arrival (entry) scene')
    sc = dict(welcome, trigger={'on': 'entry', 'arrival': ['napping']})
    expect_error("S125 refuses an unknown arrival reason", _hub_fixture(scenes=[sc])[0],
                 "arrival reasons ['napping']")


def test_hub_rom(rom_ex, sym_ex):
    """S125 on real bytes: the four engine Castle sends are same-size calls of bank $71
    entry 9 (the original 38 bytes were the Castle writes); HubWarp RUN from the ROM
    (MiniSM83) over the example (no hub) and a hub fixture."""
    from editor2.core import builder as B
    orig = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    castle = lambda code: bytes([0x3E, code, 0xEA, 0x2B, 0xD9, 0x21, 0x00, 0x00, 0x7D, 0xEA])
    for lab, reason, code in (('jr_050_64af', 4, 8), ('jr_050_6559', 1, 8),
                              ('jr_006_6a25', 2, 8), ('jr_007_5012', 3, 6)):
        bk, adr = sym_ex[lab + '.hubWarped']
        o = bk * 0x4000 + adr - 0x4000 - 38
        ok(f"S125: {lab}: the 38 Castle bytes ($D92B := {code}) -> ld e, {reason} / "
           "ld hl, $7109 / rst $10 / jr +30",
           orig[o:o + 10] == castle(code) and
           rom_ex[o:o + 8] == bytes([0x1E, reason, 0x21, 0x09, 0x71, 0xD7, 0x18, 30]) and
           rom_ex[o + 38:o + 43] == orig[o + 38:o + 43] and rom_ex[o + 38:o + 40] == b'\x3e\x01',
           rom_ex[o:o + 8].hex())
    e9 = 0x71 * 0x4000 + 1 + 2 * 9
    ok("S125: bank $71 entry 9 -> HubWarp; wHubReason = $D2EF",
       (rom_ex[e9] | rom_ex[e9 + 1] << 8) == sym_ex['HubWarp'][1]
       and sym_ex['wHubReason'][1] == 0xD2EF)

    def run(rom, sym, reason, flags_set=()):
        cpu = MiniSM83(rom, 0x71)
        cpu.e = reason

        def tef(c):                     # TestEventFlag: BC = flag; Z = clear
            c.z = (c.b << 8 | c.c_) not in flags_set
        cpu.calls[sym['TestEventFlag'][1]] = tef
        cpu.run(sym['HubWarp'][1])
        m = cpu.ram
        return (m.get(sym['wWarpGateId'][1]), m.get(sym['wWarpFlag'][1]),
                m.get(sym['wWarpSpawnXLo'][1]) | m.get(sym['wWarpSpawnXHi'][1], 0) << 8,
                m.get(sym['wWarpSpawnYLo'][1]) | m.get(sym['wWarpSpawnYHi'][1], 0) << 8,
                m.get(0xD92B), m.get(0xD2EF))
    ok("S125: HubWarp, no hub, a lost battle -> map 0 ($E8, $58), $D92B = 8, reason 0",
       run(rom_ex, sym_ex, 1) == (0, 0, 0xE8, 0x58, 8, 0), run(rom_ex, sym_ex, 1))
    ok("S125: HubWarp, no hub, the WarpWing -> map 0, $D92B = 6",
       run(rom_ex, sym_ex, 3) == (0, 0, 0xE8, 0x58, 6, 0))
    d, _r = _hub_fixture()
    outh, prjh, _w = compile_data(d)
    outdir = '/tmp/_t_hub_rom'
    C.write_outputs(outh, outdir)
    rom, sym, _md5 = B.build_rom(REPO, outdir, os.path.join(outdir, 'build'))
    rb, sy = open(rom, 'rb').read(), B.parse_sym(sym)
    hm = prjh.resolve_flag_ref('hub_moved')
    ok("S125: HubWarp, hub_moved OFF -> gate_island ($6B) at (72, 72), reason kept, "
       "$D92B untouched",
       run(rb, sy, 1) == (0x6B, 0, 72, 72, None, 1), run(rb, sy, 1))
    ok("S125: HubWarp, hub_moved ON -> the Castle rule: the vanilla writes",
       run(rb, sy, 2, {hm}) == (0, 0, 0xE8, 0x58, 8, 0) and
       run(rb, sy, 3, {hm}) == (0, 0, 0xE8, 0x58, 6, 0), run(rb, sy, 2, {hm}))


def test_flag_index_s124():
    """S124 (ROADMAP P3.14a): every flag of a project and every place that touches it
    (editor2/core/flag_index.py) — the index finds EVERY flag the compiler resolves and
    every flag op it emits (a new site cannot be forgotten); Rename rewrites every use
    and the ROM does not change; numbers are pinned on open with the compiler's own
    numbering; new flags skip $0158 (the game's, Arena Battle); the problems."""
    import copy
    import shutil
    from editor2.core import flag_index as FI
    from editor2.core.document import Document

    def at(data, tag):
        tmp = f'/tmp/_t_flags_{tag}'
        if os.path.exists(tmp):
            shutil.rmtree(tmp)
        os.makedirs(tmp)
        json.dump(data, open(os.path.join(tmp, 'project.json'), 'w'))
        shutil.copytree(os.path.join(os.path.dirname(EXAMPLE), 'assets'),
                        os.path.join(tmp, 'assets'), dirs_exist_ok=True)
        return tmp

    kinds = set()
    fx = {'example': base(), 's117': _s117_fixture(), 'enc': _en_fixture(),
          'milly': _milly_fixture(), 'sites': _flag_sites_fixture()}
    for tag, data in fx.items():
        missed, fi = FI.compiler_coverage(at(data, tag), REPO)
        ok(f"S124 flag index: finds every flag the compiler resolves / emits ({tag})",
           not missed, missed[:5])
        kinds |= {u.kind for u in fi.uses}
    wdoc, _gid, _rooms = _world_fixture()
    missed, fi = FI.compiler_coverage(wdoc.project_dir, REPO)
    ok("S124 flag index: finds every flag the compiler resolves / emits (world)",
       not missed, missed[:5])
    kinds |= {u.kind for u in fi.uses}
    want = set(FI.KINDS) - {'game', 'game_engine'}
    ok("S124 flag index: the fixtures exercise every flag site",
       want <= kinds, sorted(want - kinds))

    # sentences + problems on the sites fixture
    sites = _flag_sites_fixture()
    fi = FI.FlagIndex(sites, repo=REPO)
    sent = [s for _t, s in fi.triggers_sentences()]
    ok("S124: a cutscene start reads as a sentence",
       any(s.startswith('When you enter') and 'ks_a is ON' in s and 'ks_b is OFF' in s
           and '“Sites” plays (once)' in s for s in sent), sent)
    ok("S124: an NPC shown by a flag / drawn in a colour read as sentences",
       any('ks_never is ON → the NPC at (8, 6) is there' in s for s in sent)
       and any('drawn in colour 1' in s for s in sent), sent)
    ks_a = fi.flags[fi.named['ks_a']]
    on = [u for u in ks_a.uses if u.role == FI.ON]
    ok("S124: who turns ks_a ON — the talk's YES answer, with the place (r3: called by "
       "the NPC's name, its actor)",
       any(u.kind == 'talk' and 'if the answer is YES' in u.what and
           'talking to Bard at (5, 6)' in u.what for u in on), [(u.kind, u.what) for u in on])
    probs = {(p.code, p.idx) for p in fi.problems()}
    ok("S124 problems: a tested flag nothing turns ON / an unused flag",
       ('never_on', fi.named['ks_never']) in probs and
       ('unused', fi.named['ks_unused']) in probs, probs)
    # S124 r2 (user: flag $0080 "Looks like it just randomly turns on by a million
    # things"): the game's uses say WHO / WHERE / WHEN and one script = one group
    rom_p = os.path.join(REPO, 'data', 'DWM-original.gbc')
    if os.path.exists(rom_p):
        from editor2.core.cutscenes import Catalogue
        gi = FI.FlagIndex({'custom': {}}, repo=REPO, catalogue=Catalogue(open(rom_p, 'rb').read()))
        f80 = gi.flags[0x0080]
        ons = gi.groups([u for u in f80.uses if u.role == FI.ON])
        santi = [g for h, g in ons if 'Santi' in h.who]
        tests = [u for u in f80.uses if u.role == FI.TEST]
        ok("S124 r2: $0080 = 2 setters (Santi's two scripts), Santi named by her own lines, "
           "9 branches each with its rung; her father's check says when it is asked",
           len(ons) == 2 and len(santi) == 1 and len(santi[0]) == 9 and
           any('arena class S won' in u.when for u in santi[0]) and len(tests) == 1 and
           'Gate of Anger cleared' in tests[0].when and 'Old Man Gate Room' in tests[0].where,
           [(h.who, len(g)) for h, g in ons])
        ok("S124 r2: a game flag without a game name is labelled by who sets it",
           f80.label.startswith('set by talking to'), f80.label)
        # S124 r3 (user: "You dont actually show the correct NPC … That's NOT where
        # Santi is"): every game use carries its places — map, screen, STATE, cell, NPC n
        pl = [p for u in santi[0] for p in (u.places or [])]
        ok("S124 r3: Santi's script = GreatTree screen 12, states 1 and 2, NPC 1 at (1, 6)",
           {(p['map'], p['screen'], p['state'], p['x'], p['y'], p['n']) for p in pl} ==
           {(1, 12, 1, 1, 6, 1), (1, 12, 2, 1, 6, 1)}, pl)
        h0 = [h for h, _g in ons if 'Santi' not in h.who][0]
        ok("S124 r3: the other setter = screen 8 states 0 / 1 (the young Santi), nav = its place",
           [(p['screen'], p['state'], p['x'], p['y']) for p in h0.places] ==
           [(8, 0, 3, 6), (8, 1, 2, 7)] and h0.nav == h0.places[0], h0.places)
        from editor2.core import npc_names as NN
        cu = {}
        NN.set_vanilla_name(cu, 1, 8, 0, 2, 'Young Santi')
        ok("S124 r3: naming a game room's NPC names the same sprite + cell in other states "
           "only", cu['_editor']['npc_names'] == {'01:8:0:2': 'Young Santi'},
           cu['_editor']['npc_names'])
        gi2 = FI.FlagIndex({'custom': cu}, repo=REPO, catalogue=gi.catalogue)
        whos = [h.who for h, _g in gi2.groups([u for u in gi2.flags[0x0080].uses
                                               if u.role == FI.ON])]
        ok("S124 r3: your NPC name is the 'who' (before the game's speaker name)",
           any(w.startswith('talking to Young Santi at (3, 6)') for w in whos), whos)
        NN.set_vanilla_name(cu, 1, 8, 0, 2, '')
        ok("S124 r3: an empty name removes it (and the empty table)", '_editor' in cu and
           not cu['_editor'].get('npc_names'), cu)
    ex = FI.FlagIndex(base(), repo=REPO)
    ok("S124 problems: the example's first flag is $0158 — the game's (Arena Battle)",
       any(p.code == 'game_shares' and p.idx == 0x0158 for p in ex.problems()))

    # pinning on open = the compiler's numbers; the build does not change
    out0, prj0, _w = compile_data(copy.deepcopy(sites))
    p = os.path.join(at(sites, 'pin'), 'project.json')
    doc = Document(p)
    ok("S124: opening pins every flag number (a migration note)",
       any('flag number' in n for n in doc.migrations) and
       all(str(f.get('index')) != 'auto' for f in doc.flags()))
    ok("S124: pinned numbers == the compiler's", doc.flag_numbers() == prj0.flag_map(),
       (doc.flag_numbers(), prj0.flag_map()))
    out1, _p, _w = compile_data(copy.deepcopy(doc.data))
    ok("S124: pinning changes no generated byte", out0 == out1)
    # rename everywhere: the ROM stays the same
    doc.rename_flag('ks_a', 'Bell rung')
    s = json.dumps(doc.data)
    ok("S124 rename: no use of the old name is left", '"ks_a"' not in s and 'bell_rung' in s)
    out2, prj2, _w = compile_data(copy.deepcopy(doc.data))
    ok("S124 rename: the generated bytes are unchanged", out2 == out0)
    ok("S124 rename: same number", prj2.flag_map()['bell_rung'] == prj0.flag_map()['ks_a'])
    # S124 r3: naming NPCs (a project room's — its actor name — and a game room's —
    # custom._editor.npc_names) changes no generated byte; the index uses the names
    from editor2.core import cutscene_doc as CD
    from editor2.core import npc_names as NN
    named = None
    for r in doc.rooms:
        for k in doc.screen_keys(r):
            rows = CD.npc_rows(r, k, 0)
            if rows:
                named = (r['id'], k, rows[0][0])
                break
        if named:
            break
    if named:
        doc.name_npc('Bell keeper', room=named[0], screen=named[1], state=0, n=named[2])
        ok("S124 r3: a project NPC's name = its actor name",
           NN.name_of(doc.data['custom'], room=doc.room(named[0]), screen=named[1], state=0,
                      n=named[2]) == 'Bell keeper')
    doc.name_npc('Santi', mid=1, screen=12, state=1, n=1)
    ok("S124 r3: a game room's NPC name = editor data, every state with that NPC",
       doc.data['custom']['_editor']['npc_names'] == {'01:12:1:1': 'Santi', '01:12:2:1': 'Santi'},
       doc.data['custom'].get('_editor'))
    out3, _p, _w = compile_data(copy.deepcopy(doc.data))
    ok("S124 r3: naming NPCs changes no generated byte", out3 == out0)
    doc.name_npc('', mid=1, screen=12, state=1, n=1)
    ok("S124 r3: an empty name removes it", 'npc_names' not in
       (doc.data['custom'].get('_editor') or {}))
    # delete / add / renumber
    try:
        doc.delete_flag('bell_rung')
        ok("S124 delete: refused while used", False)
    except ValueError as e:
        ok("S124 delete: refused while used", 'still used' in str(e))
    doc.delete_flag('ks_unused')
    ok("S124 delete: an unused flag goes", doc.flag_entry('ks_unused') is None)
    taken = set(doc.flag_numbers().values())
    nm = doc.add_flag('Brand new')
    n = doc.flag_numbers()[nm]
    ok("S124 add: a fixed number, the lowest free, never $0158",
       str(doc.flag_entry(nm)['index']).startswith('0x') and n not in taken and n != 0x0158
       and n == min(i for i in list(range(0x0159, 0x0168)) + list(range(0x1000, 0x179E))
                    if i not in taken), n)
    ex_doc = Document(os.path.join(at(base(), 'ex'), 'project.json'))
    old = ex_doc.flag_numbers()['vault_guardian_beaten']
    new = ex_doc.renumber_flag('vault_guardian_beaten')
    ok("S124 renumber: $0158 -> a free number", old == 0x0158 and new not in (0x0158, old)
       and ex_doc.flag_numbers()['vault_guardian_beaten'] == new, (old, new))
    try:
        doc.add_flag('Brand new')
        ok("S124 add: a duplicate name is refused", False)
    except ValueError:
        ok("S124 add: a duplicate name is refused", True)


def test_worlds_s123():
    """S123 (ROADMAP NG3): worlds, NPC colours, the Vanish step (PROJECT_COMPILER
    §2.36). Engine facts measured in PyBoy on the user's save (GATE_GENERATION
    §7.11): the portal = the game's gate entry, the start room = floor 1."""
    from editor2.core import gates as G
    doc, gid, rooms = _world_fixture()
    w = doc.world(gid)
    g = doc.gate_setting(gid)
    ok("S123: New world = a new gate 32+ (copy of gate 0, 2 floors, hand-made) with a "
       "world block (start cell, rooms, saving calm)",
       gid == 32 and g['copy_of'] == 0 and g['floors'] == 2 and g['hand_made'] and
       w['start'] == {'room': rooms['start'], 'screen': 0, 'x': 4, 'y': 4} and
       w['rooms'] == [rooms['start'], rooms['cave']] and w['saving'] == 'calm')
    ent = doc.gate_entrances(gid)
    sw = doc.gate_swirls(gid)
    ok("S123: World entrance = a gate entrance (gate_flag 1, dest gate:32) + the swirl "
       "object + the still swirl art on the cell",
       len(ent) == 1 and ent[0][0]['id'] == 'dusk_mirror' and ent[0][3]['dest'] == 'gate:32'
       and len(sw) == 1 and sw[0][3]['swirl_of'] == 32)
    cave = doc.room(rooms['cave'])
    npcs = doc.npc_entries(cave, 0, 0)
    ok("S123: Make boss = its own named flag, a conversation (say, battle, flags ON, "
       "vanish) and 'shown while the flag is OFF'",
       any(f['name'] == 'cave_guard_beaten' for f in doc.flags()) and
       npcs[0]['shown_when'] == [{'flag': 'cave_guard_beaten', 'is': 'clear'}] and
       [list(st)[0] for st in doc.conversation(npcs[0]['script'])['steps']] ==
       ['say', 'battle', 'set', 'vanish'])
    king = doc.conversation(npcs[2]['script'])['steps']
    ok("S123: the end boss also turns the world's cleared flag (gate:32) ON",
       king[2] == {'set': ['cave_king_beaten', 'gate:32']})
    rep = doc.world_report(gid)
    ok("S123: world report — rooms, saving by the calm rule, cleared by the king, a way "
       "out, no problems",
       [x['id'] for x in rep['rooms']] == [rooms['start'], rooms['cave']] and
       rep['rooms'][0]['save'] is True and rep['rooms'][1]['save'] is False and
       rep['leaves'] and rep['cleared_by'] and rep['problems'] == [], str(rep['problems']))
    # NPC colour: kept through an ordinary edit (the S119 rebuild rule)
    st = doc.npc_entries(doc.room(rooms['start']), 0, 0)
    ci = next(i for i, e in enumerate(st) if e.get('colour') is not None)
    doc.update_npc(doc.room(rooms['start']), 0, 0, ci, facing='left')
    ok("S123: an NPC's colour survives update_npc (facing changed)",
       doc.npc_entries(doc.room(rooms['start']), 0, 0)[ci].get('colour') == 4)
    out, prj, warns = C.compile_project(doc.project_dir, REPO)
    a60 = out['patches/bank_060.asm']
    a71 = out['patches/bank_071.asm']
    start_mid = int(doc.room(rooms['start'])['mapID'], 16)
    ok("S123: the world's start room is served on its floor 1 at 100 % (GateInsertTable "
       "row gate 32, floors 0-0, chance 100, the start cell (4,4) = pixels 72/72)",
       f"db $20, $00, $00, $64, $00, ${start_mid:02X}, $48, $00, $48, $00, $00" in a71,
       a71[a71.find('GateInsertTable:'):a71.find('GateInsertTable:') + 600])
    ok("S123: the swirl of a world that turns green: an $A2 prefix (palette 1 while "
       "gate:32 = $17C0 is SET), no $A1 hide",
       'db $A2, $01, $C0, $17, $FF' in a60 and 'db $A1, $C0, $17, $FF, $FF' not in a60)
    ok("S123: an NPC colour (palette 4, always) = db $A2, $04, $FF, $FF, $FF",
       'db $A2, $04, $FF, $FF, $FF' in a60)
    ok("S123: Vanish = the 'vanish (flicker out)' program on the boss slots ($0D01 / "
       "$0D02 — the guard pair) + wait_movement; the king is slot 3",
       'dw $0D01' in a60 and 'dw $0D02' in a60 and 'dw $0D03' in a60)
    fl = {r['id']: prj.room_flags(r) for r in prj.rooms if not r.get('placeholder')}
    ok("S123: saving 'calm' — the start room (no battles) allows the JOURNAL, the battle "
       "room refuses it (room flag bit 0)",
       fl[rooms['start']] & 1 == 0 and fl[rooms['cave']] & 1 == 1)
    ok("S123: a world compiles without the served-room warnings (no Stairs down needed, "
       "doors are its way on) and without the vanilla-boss-room warning",
       not any('Stairs down' in x or 'ordinary exit' in x or 'VANILLA boss room' in x
               for x in warns), str(warns))
    # errors
    d = json.load(open(doc.path))
    g0 = next(x for x in d['custom']['gates'] if x['gate'] == 32)
    for what, mut, needle in (
            ('a world on a game gate', lambda x: x['custom']['gates'].append(
                {'gate': 3, 'world': copy.deepcopy(g0['world'])}), 'a world is a NEW gate'),
            ('a world with 3 floors', lambda x: next(
                y for y in x['custom']['gates'] if y['gate'] == 32).__setitem__('floors', 3),
             'a world has 2 floors'),
            ('a world with a boss floor', lambda x: next(
                y for y in x['custom']['gates'] if y['gate'] == 32).__setitem__('boss', 'gate_rotation'),
             'a world has no boss FLOOR'),
            ('a rule serving a room on a world', lambda x: x['custom'].setdefault(
                'gate_inserts', []).append({'room': 'gate_rotation', 'gate': 32, 'floors': 1,
                                            'chance': 50}), 'is a WORLD'),
            ('an unknown saving rule', lambda x: next(
                y for y in x['custom']['gates'] if y['gate'] == 32)['world'].__setitem__(
                    'saving', 'sometimes'), 'saving must be one of'),
            ('a start cell outside the screen', lambda x: next(
                y for y in x['custom']['gates'] if y['gate'] == 32)['world']['start'].__setitem__(
                    'x', 12), 'outside the 10x8 screen'),
            ('cleared_swirl 9', lambda x: next(
                y for y in x['custom']['gates'] if y['gate'] == 32).__setitem__('cleared_swirl', 9),
             'cleared_swirl must be')):
        dd = copy.deepcopy(d)
        mut(dd)
        _expect_dir_error(f"S123 refuses {what}", doc.project_dir, dd, needle)
    dd = copy.deepcopy(d)
    st0 = next(r for r in dd['custom']['rooms'] if r['id'] == rooms['start'])
    st0['screens']['0']['npcs'][ci]['colour'] = 9
    _expect_dir_error("S123 refuses NPC colour 9", doc.project_dir, dd, 'OBJ palette 0-7')
    dd = copy.deepcopy(d)
    cv = next(r for r in dd['custom']['rooms'] if r['id'] == rooms['cave'])
    cv['screens']['0']['npcs'][0]['colour'] = 2
    _expect_dir_error("S123 refuses a colour on a monster NPC", doc.project_dir, dd,
                      'own walking colours')
    # warnings
    dd = copy.deepcopy(d)
    for sc in dd['custom']['scripts']:
        for stp in (sc.get('talk') or {}).get('steps') or []:
            if 'set' in stp:
                stp['set'] = [f for f in stp['set'] if f != 'gate:32']
    ws = _dir_warnings(doc.project_dir, dd)
    ok("S123 warns: nothing turns the world's cleared flag ON",
       any('nothing turns its cleared flag' in x for x in ws), str(ws))
    dd = copy.deepcopy(d)
    for r in dd['custom']['rooms']:
        if r['id'] == rooms['start']:
            ex = r['screens']['0']['exits']
            ex[:] = [e for e in ex if not str(e.get('dest', '')).startswith('room:$6C')]
            for e in ex:
                if e.get('door'):
                    for k in ('dest', 'gate_flag', 'screen_byte', 'spawn_x', 'spawn_y', 'link'):
                        e.pop(k, None)
    ws = _dir_warnings(doc.project_dir, dd)
    ok("S123 warns: a world room no door reaches + no way out of the world",
       any('cannot be reached' in x for x in ws) and any('no door, exit or warp' in x
                                                        for x in ws), str(ws))
    # delete keeps the rooms
    n_rooms = len(doc.rooms)
    doc.delete_world(gid)
    ok("S123: Delete world = its gate, portal and swirl gone; its rooms stay",
       doc.world(gid) is None and not doc.gate_entrances(gid) and not doc.gate_swirls(gid)
       and len(doc.rooms) == n_rooms)
    return out


def _expect_dir_error(name, project_dir, data, needle):
    tmp = '/tmp/_t_world_err'
    import shutil
    if os.path.exists(tmp):
        shutil.rmtree(tmp)
    shutil.copytree(project_dir, tmp, ignore=shutil.ignore_patterns('build'))
    json.dump(data, open(os.path.join(tmp, 'project.json'), 'w'))
    try:
        C.compile_project(tmp, REPO)
    except (ProjectError, C.CompileError) as e:
        ok(name, needle in str(e), f"(got: {e})")
        return
    print(f"FAIL: {name} — expected error containing {needle!r}")
    sys.exit(1)


def _dir_warnings(project_dir, data):
    tmp = '/tmp/_t_world_warn'
    import shutil
    if os.path.exists(tmp):
        shutil.rmtree(tmp)
    shutil.copytree(project_dir, tmp, ignore=shutil.ignore_patterns('build'))
    json.dump(data, open(os.path.join(tmp, 'project.json'), 'w'))
    _out, _p, w = C.compile_project(tmp, REPO)
    return w


def test_worlds_rom(rom_ex, sym_ex, out_world):
    """S123 on real bytes: the bank $06 NPC draw redirect is same-size (the labels
    after it unmoved), entry 11 points at NpcColourDraw, the WRAM carve, and the
    world fixture's ROM builds."""
    from editor2.core import builder as B
    orig = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    b6 = 6 * 0x4000
    site = rom_ex.find(bytes([0x21, 0x0B, 0x60, 0xD7]), b6, b6 + 0x4000)
    ok("S123: bank $06 NPCDrawSlot calls bank $60 entry 11 ($21 $0B $60 $D7) where the "
       "original called bank $05 entry 0 ($21 $00 $05 $D7)",
       site > 0 and orig[site:site + 4] == bytes([0x21, 0x00, 0x05, 0xD7]) and
       rom_ex[b6:b6 + 0x4000].count(bytes([0x21, 0x0B, 0x60, 0xD7])) == 1)
    diff6 = [i for i in range(b6, b6 + 0x4000) if rom_ex[i] != orig[i]]
    ok("S123: NPCDrawSlot's redirect changes 2 bytes there (bank $06 otherwise as before)",
       {site + 1, site + 2} <= set(diff6))
    nc = sym_ex.get('NpcColourDraw')
    e11 = 0x60 * 0x4000 + 1 + 2 * 11
    ok("S123: bank $60 entry 11 -> NpcColourDraw; wNpcColour = $D2E3 (WRAM carve)",
       nc is not None and (rom_ex[e11] | rom_ex[e11 + 1] << 8) == nc[1] and
       sym_ex.get('wNpcColour', (0, 0))[1] == 0xD2E3, f"{nc} {sym_ex.get('wNpcColour')}")
    outdir = '/tmp/_t_world_rom'
    C.write_outputs(out_world, outdir)
    rom, sym, md5 = B.build_rom(REPO, outdir, os.path.join(outdir, 'build'))
    ok("S123: the world fixture builds a ROM", os.path.exists(rom))


def test_milly_rom(rb_off, sym_off, out_on):
    """S121 on real bytes: the constants of editor2/core/milly.py against the
    original ROM; the example (hook off) keeps the vanilla bytes; a hook-on build
    has the MILLY tiles, the new bedroom tail, Milayou's frame tables in bank $79
    resolving (relative to wMillyLayout) to her own six frames, and no label moved
    in the banks the hook touches (every region is same-size)."""
    from editor2.core import builder as B
    from editor2.core import milly as MH
    from editor2.core import textenc as Tx
    orig = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    w = lambda r, o: r[o] | r[o + 1] << 8
    B5 = 5 * 0x4000
    l1 = w(orig, B5 + 0x407F - 0x4000 + 2 * MH.SPRITE)
    frames = []
    for k in range(6):
        o = B5 + w(orig, B5 + l1 - 0x4000 + 2 * k) - 0x4000
        f = []
        while orig[o] != 0x80:
            f.append(list(orig[o:o + 4]))
            o += 4
        frames.append(f)
    ok("ROM S121: milly.SPRITE_FRAMES == Milayou's six frames ($05:$407F[$14])",
       frames == [[list(x) for x in f] for f in MH.SPRITE_FRAMES])
    ok("ROM S121: SPRITE_ATTR == $05:$4152[$14], SPRITE_GFX == ROM0 $2ADF[$14]",
       orig[B5 + 0x4152 - 0x4000 + MH.SPRITE] == MH.SPRITE_ATTR and
       w(orig, 0x2ADF + 2 * MH.SPRITE) == MH.SPRITE_GFX)
    bed = 0x0E * 0x4000 + 0x4AA4 - 0x4000
    ok("ROM S121: milly.BEDROOM_WORDS == the original bedroom tail ($0E:$4AA4, 94 words)",
       [w(orig, bed + 2 * i) for i in range(94)] == MH.BEDROOM_WORDS)
    font = lambda r: r[Tx.FONT_ROM_OFFSET + 0xD3 * 16:][:64]
    ok("ROM S121 hook off (example): bedroom tail, hero tiles (TERRY), bank $79 = original",
       rb_off[bed:bed + 188] == orig[bed:bed + 188] and font(rb_off) == font(orig) and
       rb_off[0x79 * 0x4000:0x7A * 0x4000] == orig[0x79 * 0x4000:0x7A * 0x4000])
    outdir = '/tmp/_t_milly_on'
    C.write_outputs(out_on, outdir)
    rom_on, sym_on_p, _m = B.build_rom(REPO, outdir, os.path.join(outdir, 'build'))
    rb = open(rom_on, 'rb').read()
    sym = B.parse_sym(sym_on_p)
    ok("ROM S121 hook on: hero tiles $D3-$D6 = textenc.MILLY_GLYPHS",
       font(rb) == b''.join(Tx.MILLY_GLYPHS[c] for c in (0xD3, 0xD4, 0xD5, 0xD6)))
    words = [w(rb, bed + 2 * i) for i in range(94)]
    ok("ROM S121 hook on: the bedroom tail sets $179F and whirls (warp_fade) to the arrival room",
       words[:2] == [0xFF21, 0x0060] and 0x179F in words and 0xFF3B in words and
       words[words.index(0xFF3B) + 1] == 0x006B)
    b79 = 0x79 * 0x4000
    ok("ROM S121 hook on: bank $79 self-id + entries 0/1",
       rb[b79] == 0x79 and w(rb, b79 + 1) == sym['MillyShapeTable'][1] and
       w(rb, b79 + 3) == sym['MillyPlayerSheet'][1])
    base_w = sym['wMillyLayout'][1]
    img_o = b79 + sym['MillyLayoutImage'][1] - 0x4000
    n = sym['MillyLayoutImageEnd'][1] - sym['MillyLayoutImage'][1]
    img = rb[img_o:img_o + n]
    ww = lambda o: img[o] | img[o + 1] << 8
    l2 = ww(0) - base_w
    got = []
    for k in range(6):
        o = ww(l2 + 2 * k) - base_w
        f = []
        while img[o] != 0x80:
            f.append(list(img[o:o + 4]))
            o += 4
        got.append(f)
    ok("ROM S121 hook on: the WRAM frame-table image resolves to her six frames; 21 level-2 "
       "entries; it fits wMillyLayout",
       got == frames and n <= MH.WRAM_LAYOUT_SIZE and
       all(img[ww(l2 + 2 * k) - base_w] == 0x80 for k in range(6, MH.LAYOUT_FRAMES)) and
       sym['wMillyLayout'][1] + MH.WRAM_LAYOUT_SIZE == sym['wNpcColour'][1])   # S123: wNpcColour follows it (was wCustomPool)
    moved = [k for k, v in sym_off.items() if v[0] in (0x01, 0x04, 0x09, 0x0E, 0x4F)
             and sym.get(k) != v]
    ok("ROM S121: hook on moves no label in banks $01/$04/$09/$0E/$4F (same-size regions)",
       not moved, f"({moved[:5]})")


def test_dialogue_s120():
    """S120 (ROADMAP P3.6, measured in PyBoy on the user's save — TEXT_SYSTEM
    "Glyphs, speakers and voices (S120)"): one-cell contractions + the font's
    extra glyphs, {hero} / {lead} inserts, the speaker label and the voice."""
    import copy
    from editor2.core import textenc as T
    ok("S120 text: contractions are ONE glyph each (don't = don + $67)",
       T.encode("I'll don't it's") == [0x2C, 0x66, 0x49, 0x62, 0x41, 0x4C, 0x4B, 0x67,
                                        0x62, 0x46, 0x51, 0x68] and T.cells("don't") == 4)
    ok("S120 text: an apostrophe before another letter stays $5C",
       T.encode("'a") == [0x5C, 0x3E])
    ok("S120 text: the extra glyphs - & ( ) + : / ~ [ ] \" * …",
       T.encode('-&()+:/~[]"*\u2026') == [0x9C, 0xB6, 0xA0, 0xA1, 0xA2, 0xA3, 0x9E, 0x9D,
                                          0x96, 0x97, 0x65, 0x9F, 0xA4])
    ok("S120 text: {hero} = $F6 (4 cells), {lead} = $F9 $00 (9 cells)",
       T.encode('{hero}{lead}') == [0xF6, 0xF9, 0x00] and T.cells('{hero}{lead}') == 13)
    try:
        T.encode('{boss}')
        ok("S120 text: an unknown insert is refused", False)
    except T.TextError as e:
        ok("S120 text: an unknown insert is refused", 'unknown insert' in str(e))
    plain = {'boxes': [['Hello there', 'how are you']]}
    ok("S120 text: no speaker / voice = the pre-S120 bytes ($EA $9F $A3 …)",
       T.render_entry_asm('x', plain)[1] == '    db $EA, $9F, $A3')
    ok("S120 text: speaker name + high voice = $EB name $A3; line 1 = 18 - 8 cells",
       T.entry_bytes({'boxes': [['Hi']], 'speaker': 'Milayou', 'voice': 'high'})[:9]
       == [0xEB, 0x30, 0x46, 0x49, 0x3E, 0x56, 0x4C, 0x52, 0xA3]
       and T.line_limit(0, 0, 'Milayou') == 10 and T.line_limit(0, 1, 'Milayou') == 18)
    ok("S120 text: the hero speaks, silently = $F6 $A3, no opener",
       T.entry_bytes({'boxes': [['Hi']], 'speaker': 'hero', 'voice': 'none'})[:2] == [0xF6, 0xA3])
    ok("S120 text: no speaker label = a full 18-cell first line",
       T.line_limit(0, 0, '') == 18 and T.entry_bytes({'boxes': [['Hi']], 'speaker': ''})[:1]
       == [0xEA])
    asm = '\n'.join(T.render_entry_asm('x', {'boxes': [["I'll go: x&y"]]}))
    ok("S120 text: charmap runs stay quoted, the rest is hex",
       'db $EA, $9F, $A3' in asm and '"I", $66, "l go", $A3, " x", $B6, "y"' in asm, asm)
    expect_error("S120 text: a raw string with a non-charmap character is refused",
                 _with_dialogue({'id': 'rw', 'raw': [['box'], 'Name: x', ['bytes', 'F7', 'F0']]}),
                 'not charmap characters')
    expect_error("S120 text: the speaker's cells count on line 1",
                 _with_dialogue({'id': 'sp', 'boxes': [["I'll show you"]], 'speaker': 'Milayou'}),
                 'max 10')
    expect_error("S120 text: a bad voice is refused",
                 _with_dialogue({'id': 'vc', 'boxes': [['Hi']], 'voice': 'loud'}), 'voice')
    # {lead} -> op $3F load_lead_name right before the text (once)
    d = _with_dialogue({'id': 'ld', 'boxes': [['Your {lead}', 'is strong!']]})
    d['custom']['scripts'].append({'id': 'ld_s', 'ops': [['text', 'ld'], ['end']]})
    prj = Project(copy.deepcopy(d), os.path.dirname(EXAMPLE))
    ops = prj._scripts['ld_s']['ops']
    ok("S120 {lead}: op load_lead_name ($3F) is put right before the text",
       ops[0] == ['op', 'load_lead_name'] and ops[1][0] == 'text' and len(ops) == 3, ops)
    # a cutscene's own {lead} text: emitted by the lowering, not twice
    d2, _r = _cs_fixture([{'id': 'ldc', 'screen': 0, 'trigger': {'on': 'talk', 'actor': 'Guard'},
                           'steps': [{'say': {'boxes': [['Hi {hero}!']], 'speaker': 'hero',
                                              'voice': 'none'}},
                                     {'say': {'boxes': [['Your {lead}']]}}]}])
    prj2 = Project(copy.deepcopy(d2), os.path.dirname(EXAMPLE))
    cut = [s for sid, s in prj2._scripts.items() if str(sid).startswith('cut:')]
    flat = [o for s in cut for o in s['ops']]
    ok("S120 {lead} in a cutscene: one load_lead_name, before its text",
       flat.count(['op', 'load_lead_name']) == 1
       and flat[flat.index(['op', 'load_lead_name']) + 1][0] == 'text', flat)
    ent = [e for e in prj2._dialogue if e.get('speaker') == 'hero']
    ok("S120 cutscene say keeps its speaker / voice", len(ent) == 1 and ent[0]['voice'] == 'none')
    from dwm.text import decode
    ok("S120 dwm.text decodes the contractions ($6B 'y, $6D 'd — was \"n'\" / \"th\")",
       decode(bytes([0x27, 0x6B, 0x3E, 0x62, 0x2C, 0x6D, 0xF0]))[0] == "D'ya I'd")


def test_gate_rows_s120():
    """S120 (ROADMAP P3.7b part 2): a gate's floor-type rows (bytes 0-2) and depth tier
    (byte 7) — vanilla gates in the bank $16 region, new gates in NewGateRows. Measured
    in PyBoy on the user's save: gate 5 with maze_row 0 rolls floor type 13 (its only
    type), wFloorType2/3 = 10/12, tier 3 (vanilla build: type 12, 2/3, tier 1)."""
    import copy
    d = base()
    d['custom'].setdefault('gates', []).extend([
        {'gate': 5, 'maze_row': 0, 'special_row': 10, 'contents_row': 12, 'depth': 3},
        {'gate': 32, 'copy_of': 3, 'name': 'Rowed', 'maze_row': 9, 'depth': 2}])
    prj = Project(copy.deepcopy(d), os.path.dirname(EXAMPLE))
    cfg = prj.gate_configs()
    ok("S120 gate rows: gate 5 row = 00 0A 0C … 03", cfg[5]['row'][:3] == [0, 10, 12]
       and cfg[5]['row'][7] == 3 and cfg[5]['row'][3:7] == [9, 0x35, 1, 6], cfg[5]['row'])
    ok("S120 gate rows: a new gate keeps its source's other bytes",
       cfg[32]['row'] == [9, 1, 2, 5, 0x33, 4, 6, 2], cfg[32]['row'])
    out, _p, _w = compile_data(d)
    b16 = out['patches/bank_016.asm']
    ok("S120 gate rows: the bank $16 region carries gate 5's bytes",
       'db $00, $0A, $0C, $09, $35, $01, $06, $03' in b16)
    ok("S120 gate rows: NewGateRows carries gate 32's bytes",
       'db $09, $01, $02, $05, $33, $04, $06, $02' in out['patches/bank_076.asm'].replace('$9,', '$09,'))
    for key, bad in (('maze_row', 16), ('special_row', -1), ('contents_row', 16), ('depth', 4)):
        dd = base()
        dd['custom']['gates'] = [{'gate': 1, key: bad}]
        expect_error(f"S120 gate rows: {key} {bad} is refused", dd, key)


def _with_dialogue(entry):
    d = base()
    d['custom']['dialogue'].append(entry)
    return d


def test_cutscenes_s119():
    """S119 (ROADMAP P3.8 part B, user: "Should be specific NPCs … everything in
    tiles"): rooms[].cutscenes[] -> ordinary scripts wired to their trigger.
    The ops / model come from editor2/core/cutscene_build.py (PyBoy-measured
    rules: init_dialog before every text after a yielding step, close before
    end, $10 / $11 exact walks for an unknown start)."""
    from editor2.core import cutscene_build as CB
    entry = {'id': 'welcome', 'screen': 0, 'player_start': {'x': 7, 'y': 6},
             'trigger': {'on': 'entry', 'once': 'cs_seen'},
             'steps': [{'show': {'actor': 'Ghost', 'how': 'flicker'}},
                       {'walk': {'actor': 'Ghost', 'to': [3, 3], 'together': True}},
                       {'walk': {'actor': 'player', 'to': [7, 4]}},
                       {'face': {'actor': 'Ghost', 'toward': 'player'}},
                       {'say': {'boxes': [['Boo!']]}},
                       {'anim': {'actor': 'Guard', 'move': 'hop'}},
                       {'fly': {'actor': 'Ghost', 'dir': 'off_right', 'length': 3, 'curve': 3}},
                       {'tiles': {'x': 1, 'y': 1, 'rows': [[{'tiles': [1, 2, 3, 4], 'pal': 2}]]}},
                       {'shake': {'frames': 12}}]}
    talk = {'id': 'guard_talk', 'screen': 0, 'trigger': {'on': 'talk', 'actor': 'Guard'},
            'steps': [{'say': {'boxes': [['Halt!']]}}, {'walk': {'actor': 'player', 'to': [2, 5]}},
                      {'say': {'boxes': [['Go on.']]}}]}
    d, r = _cs_fixture([entry, talk])
    out, prj, _w = compile_data(d)
    rr = prj.room_by_id('gate_island')
    ok("S119 cutscenes: the entry trigger script replaces script 0",
       rr['scripts']['0'] == 'cut:gate_island:entry')
    ent = prj.script('cut:gate_island:entry')['ops']
    ok("S119 cutscenes: the room's own arrival script runs after the scenes (inlined)",
       'label:cut_orig' in ent and any(isinstance(o, list) and o[:2] == ['op', 'write_ram2']
                                       for o in ent[ent.index('label:cut_orig'):]))
    fl = prj.flag_map()['cs_seen']
    ok("S119 cutscenes: once = test + set the flag first",
       ['op', 'if_flag_set', fl, '@cs_welcome_skip'] in ent and ['op', 'set_flag', fl] in ent)
    ok("S119 cutscenes: multi-screen room -> the scene is guarded by its screen",
       ent[0] == ['op', 'branch_screen', 0, '@cs_welcome_go'])
    ok("S119 cutscenes: the cast member is NPC 3 (after Guard / Bard), flicker-in = program $08",
       ['op', 'trigger_anim', '0x0803'] in ent)
    ok("S119 cutscenes: a known start -> a queued walk in pixels (2 tiles right = $0020)",
       ['op', 'npc_walk_x', 3, '0x0020'] in ent)
    i = ent.index(['op', 'npc_walk_y', 0, '0xFFE0'])
    ok("S119 cutscenes: 'together' walks share one wait_movement",
       ent[i + 1] == ['op', 'wait_movement'] and ['op', 'npc_walk_x', 3, '0x0020'] in ent[:i])
    ok("S119 cutscenes: face toward the player (Ghost (3,3), player (7,4)) -> right",
       ['op', 'face_right', 3] in ent)
    k = ent.index(['op', 'init_dialog'])
    ok("S119 cutscenes: init_dialog before the text, close_text after it",
       isinstance(ent[k + 1], list) and ent[k + 1][0] == 'text' and ent[k + 2] == ['op', 'close_text'])
    ok("S119 cutscenes: fly off = $D8E3 path then program $18",
       ['op', 'write_ram2', '0xD8E3', '0x0303'] in ent and ['op', 'trigger_anim', '0x1803'] in ent)
    ok("S119 cutscenes: shake = $C8B1 / $C8B2 frames",
       ['op', 'write_ram', '0xC8B1', 12] in ent and ['op', 'write_ram', '0xC8B2', 12] in ent)
    pname = 'cs_welcome_1'
    ok("S119 cutscenes: a tiles step -> ops $24 / $61 on the room's patch_data",
       ['op', '0x24', f'patch:{pname}'] in ent and ['op', '0x61', f'patch:{pname}_attr'] in ent
       and rr['patch_data'][pname] == [32 * 2 + 2, 0, 1, 2, 0xD8, 3, 4, 0xD9]
       and rr['patch_data'][pname + '_attr'] == [32 * 2 + 2, 0, 2, 2, 0xD8, 2, 2, 0xD9])
    txt = out['patch:bank_060.asm'] if 'patch:bank_060.asm' in out else \
        next(v for kk, v in out.items() if kk.endswith('bank_060.asm'))
    ok("S119 cutscenes: the patch is emitted in bank $60 and the op points at it",
       'CustomRoom0_Patch_cs_welcome_1:' in txt and 'dw CustomRoom0_Patch_cs_welcome_1' in txt)
    ok("S119 cutscenes: bank $60 entries 9 / 10 exist in every build",
       'dw CustomDrawTiles' in txt and 'dw CustomDrawAttrs' in txt)
    tid = next(i for i, sid in rr['scripts'].items() if sid == 'cut:gate_island:talk_0_Guard')
    g = rr['screens']['0']['npcs'][1]
    ok("S119 cutscenes: the talked-to NPC runs the talk trigger script",
       g['script'] == 'cut:gate_island:talk_0_Guard' and int(tid) >= 4)
    tk = prj.script('cut:gate_island:talk_0_Guard')['ops']
    ok("S119 cutscenes: talk scene — where the player stands is unknown -> exact walks $10 / $11",
       ['op', '0x10', 0, '0x0028'] in tk and ['op', '0x11', 0, '0x0058'] in tk)
    ok("S119 cutscenes: a second text after a walk opens the dialog again (measured S119)",
       sum(1 for o in tk if o == ['op', 'init_dialog']) == 2)
    ok("S119 cutscenes: after the talk scene the NPC's own script (give_jerky) is kept",
       'label:cut_orig' in tk and len(tk) > tk.index('label:cut_orig') + 1)
    # problems
    d2, r2 = _cs_fixture([dict(entry, steps=[{'walk': {'actor': 'Nobody', 'to': [1, 1]}}])])
    expect_error("S119 cutscenes: an unknown actor is refused", d2, 'no NPC named')
    d3, r3 = _cs_fixture([dict(talk, trigger={'on': 'talk', 'actor': 'Ghost'})])
    expect_error("S119 cutscenes: nobody can talk to a hidden cast member", d3, 'is hidden')
    d4, r4 = _cs_fixture([entry])
    scr = r4['screens']['0']
    scr['states'] = [{'npcs': scr.pop('npcs'), 'exits': scr.pop('exits')},
                     {'npcs': [{'kind': 'npc', 'sprite': '0x0B', 'x': 4, 'y': 4, 'script': 'none'},
                               {'kind': 'npc', 'sprite': '0x0B', 'x': 2, 'y': 7, 'actor': 'Guard',
                                'script': 'give_jerky'}], 'exits': []}]
    expect_error("S119 cutscenes: an actor at different NPC numbers in two room states is refused",
                 d4, 'different NPC number')
    d5, r5 = _cs_fixture([dict(entry, steps=[{'tiles': {'x': 9, 'y': 7, 'rows': [[{'tiles': [1, 2, 3, 4], 'pal': 0}] * 2]}}])])
    expect_error("S119 cutscenes: a tile piece past the screen edge is refused", d5,
                 'inside the screen')
    # the editor's model (no project needed)
    lw = CB.analyse(r, entry, custom=d['custom'], flag_names=['cs_seen'])
    last = lw.info[-1]['state']
    ok("S119 cutscenes: the model — the Ghost flew off 48 px right / 44 up from (3, 3)",
       (last['Ghost']['x'], last['Ghost']['y']) == (3 * 16 + 8 + 48, 3 * 16 + 8 - 44)
       and lw.errors == [], str(lw.errors))
    ok("S119 cutscenes: the model's frame time grows with the walks / texts / programs",
       lw.info[-1]['t1'] > lw.info[0]['t1'] > 0)
    return out


def test_screen_push_rom(tag, rom, sym, origb):
    """S117b: bank $09's screen push (LoadFld9_40fa) is a same-size far call to
    bank $77 ScreenPush — the same BG tile writes in the same order as the
    original routine; palette attributes only in a free-colour custom room
    (menu tiles >= $80 -> 7, room tiles <- $C200); ShopClose re-seats a TOP
    dialog box at the bottom (base, $C100 tile backup, the attr save)."""
    import random
    from dwm.sm83 import CPU
    S = lambda n: sym[n][1]

    def mk(r):
        ram, v1, st, log = {}, {}, {'bank': 9}, []

        def rd(a):
            if a < 0x4000:
                return r[a]
            if a < 0x8000:
                return r[st['bank'] * 0x4000 + a - 0x4000]
            if 0x8000 <= a < 0xA000 and ram.get(0xFF4F, 0) & 1:
                return v1.get(a, 0)
            return ram.get(a, 0)

        def wr(a, v):
            if 0x2000 <= a < 0x3000:
                st['bank'] = v or 1
            elif 0x8000 <= a < 0xA000:
                if ram.get(0xFF4F, 0) & 1:
                    v1[a] = v & 0xFF
                    log.append(('a', a, v & 0xFF))
                else:
                    ram[a] = v & 0xFF
                    log.append(('t', a, v & 0xFF))
            elif a >= 0xA000:
                ram[a] = v & 0xFF
        return CPU(rd, wr), ram, v1, st, log

    rnd = random.Random(117)
    buf = [rnd.choice([rnd.randrange(0x80), 0x80 + rnd.randrange(0x80)]) for _ in range(18 * 32)]
    c200 = [rnd.randrange(8) << 4 | rnd.randrange(8) for _ in range(256)]
    c300 = [rnd.randrange(0x80) for _ in range(512)]
    hud = [rnd.randrange(0x100) for _ in range(64)]

    def setup(ram, mid, gbc, free, base=0x9A04):
        for i, t in enumerate(buf):
            ram[0xC500 + i] = t
        for i, b in enumerate(c200):
            ram[0xC200 + i] = b
        for i, b in enumerate(c300):
            ram[0xC300 + i] = b
        for i, b in enumerate(hud):
            ram[0xC1C0 + i] = b
        ram[0xC909], ram[0xC90A] = base & 0xFF, base >> 8
        ram[0xC968] = mid
        ram[0xC81D] = gbc
        for a in (0xC79E, 0xC7A6, 0xC7AE, 0xC7B6):
            ram[a] = 0x2A
        if free:
            ram[0xC7A6] = 0xAA
        ram[0xFF41] = 0                                    # STAT: mode 0

    def run(r, mid, gbc, free):
        cpu, ram, v1, st, log = mk(r)
        setup(ram, mid, gbc, free)
        st['bank'] = 9
        cpu.call(0x40FA, sp=0xDFF0)
        return [e for e in log if e[0] == 't'], v1
    oo, _ = run(origb, 0x02, 1, False)
    bad = []
    for name, mid, gbc, free in (('vanilla room', 0x02, 1, True), ('custom room', 0x71, 1, False),
                                 ('DMG', 0x6E, 0, True)):
        nt, v1 = run(rom, mid, gbc, free)
        if nt != oo or v1:
            bad.append(name)
    ok(f"ROM {tag}: ScreenPush == the original LoadFld9_40fa (576 tile writes, same order) with "
       "NO attribute writes in a vanilla room, a non-free custom room and on DMG",
       not bad and len(oo) == 576, f"({bad}, {len(oo)})")
    nt, v1 = run(rom, 0x6E, 1, True)
    want, wbad = {}, []
    for r in range(18):
        for c in range(20):
            t = buf[r * 32 + c]
            a = 0x9A04 + r * 32
            a = (a & 0xFFE0) | ((a + c) & 0x1F)
            a = 0x9800 | (a & 0x3FF)
            if t >= 0x80:
                want[a] = 7
            elif r < 16:
                b = c200[r * 16 + c // 2]
                want[a] = (b >> 4) if c % 2 == 0 else (b & 0x0F)
    for a, v in want.items():
        if v1.get(a) != v:
            wbad.append((hex(a), v, v1.get(a)))
    ok(f"ROM {tag}: ScreenPush in a FREE-COLOUR custom room — the same tile writes; menu tiles "
       "(>= $80) get palette 7, room tiles their $C200 palette, HUD room tiles untouched "
       "(map-row wrap included)",
       nt == oo and not wbad and len(v1) == len(want), f"({wbad[:4]}, {len(v1)}, {len(want)})")
    # ShopClose: a TOP dialog box is re-seated at the bottom
    for free in (False, True):
        cpu, ram, v1, st, log = mk(rom)
        setup(ram, 0x6E, 1, free, base=0x9800)
        ram[0xC919], ram[0xC91A] = 0x00, 0x98             # the box at the top
        mask = S('wBoxAttrMask')
        ram[mask] = 0x3F
        for i in range(100):
            ram[0xC100 + i] = 0xEE
        st['bank'] = 0x77
        cpu.call(S('ShopClose'), sp=0xDFF0)
        bk = [ram.get(0xC100 + i) for i in range(100)]
        wantbk = (c300[13 * 32:13 * 32 + 20] + c300[14 * 32:14 * 32 + 20] +
                  c300[15 * 32:15 * 32 + 20] + hud[0:20] + hud[32:52])
        sv = [ram.get(S('wBoxAttrSave') + i) for i in range(60)]
        wantsv = [(c200[r * 16 + c // 2] >> 4) if c % 2 == 0 else (c200[r * 16 + c // 2] & 15)
                  for r in (13, 14, 15) for c in range(20)]
        good = ((ram[0xC919], ram[0xC91A]) == (0xA0, 0x99) and bk == wantbk and
                (ram[mask] == (0x27 if free else 0x20)) and (sv == wantsv or not free))
        ok(f"ROM {tag}: ShopClose re-seats a TOP dialog box at the bottom ($99A0, the $C100 backup "
           f"= room rows 13-15 + the HUD{', the attr save = $C200 rows 13-15' if free else ''}"
           f") — {'free-colour' if free else 'plain'} custom room", good,
           f"({hex(ram[0xC919])}, {bk[:4]}, {hex(ram[mask])})")
    cpu, ram, v1, st, log = mk(rom)
    setup(ram, 0x02, 1, False, base=0x9800)
    ram[0xC919], ram[0xC91A] = 0xA0, 0x99                 # already at the bottom
    for i in range(100):
        ram[0xC100 + i] = 0xEE
    ram[S('wBoxAttrMask')] = 0x1F
    st['bank'] = 0x77
    cpu.call(S('ShopClose'), sp=0xDFF0)
    ok(f"ROM {tag}: ShopClose leaves a BOTTOM dialog box (every vanilla shop) untouched",
       all(ram.get(0xC100 + i) == 0xEE for i in range(100)) and ram[S('wBoxAttrMask')] == 0x1F
       and (ram[0xC919], ram[0xC91A]) == (0xA0, 0x99))
    ok(f"ROM {tag}: bank $09 LoadFld9_40fa = `ld hl,$7702 / rst $10 / ret` + 48 nops (53 B; "
       "LoadFld9_412f keeps its address)",
       rom[0x09 * 0x4000 + 0x40FA - 0x4000: 0x09 * 0x4000 + 0x412F - 0x4000] ==
       bytes([0x21, 0x02, 0x77, 0xD7, 0xC9]) + bytes(48) and
       rom[0x09 * 0x4000 + 0x412F - 0x4000: 0x09 * 0x4000 + 0x4140 - 0x4000] ==
       origb[0x09 * 0x4000 + 0x412F - 0x4000: 0x09 * 0x4000 + 0x4140 - 0x4000])


def test_music_s116():
    """S116 (ROADMAP P3.13b): two song banks, channel counts, gate + battle music."""
    global MU_FIX
    from editor2.core import music as MUS
    out0, prj0, _w0 = compile_data(base())
    P0 = prj0.music_plan()
    b71 = out0['patches/bank_071.asm']
    ok("S116: the example's 4 songs keep their own channel counts (3 each — the S64 trio "
       "padding is gone) in CustomBGMChanTable; nothing spills into bank $75",
       [P0.chan_table[i - 0x9E] for i in (0x9E, 0xA1, 0xA4, 0xA7)] == [3, 3, 3, 3] and
       sum(1 for x in P0.chan_table if x) == 4 and P0.split is None and
       'CustomBGMChanTable:' in b71 and 'BattleFightBGMTable:\n    db $FF, $FF' in b71)
    reg = '\n'.join(region_text(out0, 'patches/bank_000.asm', 'rom0_audio_master'))
    ok("S116: rom0_audio_master = the 3 vanilla rows + the bank $74 row + $FF (24 B, as "
       "before S116)",
       '    db $9E, $01, $40, $74' in reg and '$75' not in reg.split('sentinel')[0] and
       asm_bytes(reg.splitlines()) == bytes([0, 1, 0x40, 0x1C, 0x21, 1, 0x40, 0x1D, 0x37, 1,
                                             0x40, 0x1E, 0x9E, 1, 0x40, 0x74] + [0xFF] * 8))
    b75 = out0['patches/bank_075.asm']
    ok("S116: bank $75 = its bank byte + zeros when nothing spills",
       'SECTION "ROM Bank $075", ROMX[$4000], BANK[$75]' in b75 and
       '    db $75, $00, $00' in b75)
    MU_FIX = _mu_fixture()
    o, prj, w = compile_data(MU_FIX)
    P = prj.music_plan()
    sid = P.song_ids
    ok("S116: songs past 16,000 stream bytes go to bank $75 from the split id; the master "
       "table gains the row [split, $4001, $75]",
       P.split is not None and all(r['bank'] == (0x75 if r['first_id'] >= P.split else 0x74)
                                   for r in P.songs) and
       P.stream_bytes[0x74] <= 16000 and P.stream_bytes[0x75] <= 16000 and
       f'    db ${P.split:02X}, $01, $40, $75' in
       '\n'.join(region_text(o, 'patches/bank_000.asm', 'rom0_audio_master')))
    ok("S116: channel counts — BGM #04 4 (its noise channel on slot $82), Jingle #09 5 (two "
       "on the sound-effect slots), Jingle #02 2; the SE-slot warning",
       P.chan_table[sid['drums04'] - 0x9E] == 4 and P.chan_table[sid['five'] - 0x9E] == 5 and
       P.chan_table[sid['two'] - 0x9E] == 2 and
       [c['slot'] for c in next(r for r in P.songs if r['id'] == 'drums04')['channels']]
       == [0x34, 0x4E, 0x68, 0x82] and
       any('song five: plays on a sound-effect slot' in x for x in w))
    imgs = MUS.bank_images(prj)
    b75b = imgs[0x75]
    r = next(r for r in P.songs if r['bank'] == 0x75)
    ro = 1 + (r['first_id'] - P.split) * 4
    ok("S116: bank $75's records are indexed from the split id (record of the first song "
       "there at $4001 + (id - split) * 4, its stream in bank $75)",
       b75b[0] == 0x75 and b75b[ro] == r['channels'][0]['slot'] and
       0x4180 <= (b75b[ro + 2] | b75b[ro + 3] << 8) < 0x8000)
    ok("S116: gate tables — gate 2 floors = BGM #04, battles $0C; gate 5 battles = Jingle "
       "#02; served rooms with no song of their own are marked $FF (follow the gate)",
       P.gate_bgm[2] == sid['drums04'] and P.gate_battle[2] == 0x0C and
       P.gate_battle[5] == sid['two'] and
       any(P.room_bgm[int(str(rr['mapID']), 0)] == MUS.FOLLOW_GATE
           for rr in prj.rooms if rr.get('id') in prj.gate_rooms()))
    ok("S116: no gate song -> no $FF marks (the example: vanilla path byte-for-byte)",
       MUS.FOLLOW_GATE not in P0.room_bgm and MUS.FOLLOW_GATE not in P0.room_battle)
    ok("S116: battle settings + per-room + fights (sorted by EID)",
       P.battle == {'normal': 0x31, 'boss': sid['five'], 'arena': sid['big15'],
                    'starry': sid['drums04']} and
       P.room_battle[0x01] == 0x1E and P.room_battle[0x6C] == sid['two'] and
       P.fights == [(11, 0x2B), (325, sid['big15'])] and
       F_db_has(o['patches/bank_071.asm'], [11, 0, 0x2B]))
    # the models
    ctx = dict(in_gate=1, map=0x0D, gate=2, floor=0, last=5, boss_map=0x31)
    ok("S116 model: a maze floor of gate 2 plays its song; the floor before a VANILLA boss "
       "room keeps the vanilla boss song (0 = vanilla); another gate is vanilla",
       MUS.model_room_bgm(P, ctx) == sid['drums04'] and
       MUS.model_room_bgm(P, dict(ctx, floor=3)) == 0 and
       MUS.model_room_bgm(P, dict(ctx, gate=3)) == 0)
    bctx = dict(link=0, map=0x0D, starry=0, eid=5, in_gate=1, gate=2, mode=0)
    ok("S116 model: battles — a fight's own song > the arena > the room > the gate > boss > "
       "normal; link battles vanilla",
       MUS.model_battle_bgm(P, dict(bctx, eid=325)) == sid['big15'] and
       MUS.model_battle_bgm(P, bctx) == 0x0C and
       MUS.model_battle_bgm(P, dict(bctx, gate=4)) == 0x31 and
       MUS.model_battle_bgm(P, dict(bctx, gate=4, mode=3)) == sid['five'] and
       MUS.model_battle_bgm(P, dict(bctx, in_gate=0, map=0x5D, starry=2)) == sid['drums04'] and
       MUS.model_battle_bgm(P, dict(bctx, in_gate=0, map=0x5D, starry=1)) == sid['big15'] and
       MUS.model_battle_bgm(P, dict(bctx, in_gate=0, map=0x01)) == 0x1E and
       MUS.model_battle_bgm(P, dict(bctx, link=1, eid=325)) == 0x27)

    def fx(mut):
        d = _mu_fixture()
        mut(d)
        return d
    mus = lambda d: d['custom']['music']
    six = {'channels': [{'slot': s_, 'hw': 0, 'header': [0, 0, 0, 0], 'tokens': [{'op': 'end'}]}
                        for s_ in (0x00, 0x1A, 0x34, 0x4E, 0x68, 0x82, 0x34)]}
    for name, mut, needle in (
            ('an unknown music key', lambda d: mus(d).update(tempo=1), "unknown key(s) ['tempo']"),
            ('a gate outside 0-95', lambda d: mus(d)['gates'].update({'96': {'floors': 'two'}}),
             'outside 0-95'),
            ('a song for an undefined gate', lambda d: mus(d)['gates'].update(
                {'40': {'floors': 'two'}}), 'gate 40 is not defined'),
            ('an unknown battle key', lambda d: mus(d)['battle'].update(victory='two'),
             "unknown key(s) ['victory']"),
            ('a song id that does not exist', lambda d: mus(d)['battle'].update(boss='nope'),
             "'nope' is not a defined song id"),
            ('two channels on one slot', lambda d: mus(d)['songs'].append(
                {'id': 'bad', 'source': {'inline': six}}), 'two channels on slot $34'),
            ('more than the two banks', lambda d: mus(d)['songs'].extend(
                [{'id': f'x{k}', 'source': {'library': 'dwm2_bgm15'}} for k in range(2)]),
             'more than the two song banks')):
        expect_error(f"S116 refuses {name}", fx(mut), needle)
    # the editor model
    from editor2.core.document import Document
    import shutil
    import struct
    tmpd = '/tmp/_t_mu_doc'
    if os.path.exists(tmpd):
        shutil.rmtree(tmpd)
    shutil.copytree(os.path.dirname(EXAMPLE), tmpd, ignore=shutil.ignore_patterns('build'))
    doc = Document(os.path.join(tmpd, 'project.json'))
    s7 = doc.add_library_song('dwm2_bgm07')
    ok("S116 doc: Add to the project — a second copy of a catalog song gets its own id",
       s7 == 'dwm2_bgm07_2' and doc.project_song(s7)['source'] == {'library': 'dwm2_bgm07'})
    # a tiny MIDI file: 4 melodic channels + drums -> automatic 3 + noise
    ev = b''
    for ch in range(4):
        for k in range(8):
            ev += bytes([0x00, 0x90 | ch, 60 + ch * 3 + k, 90, 0x30, 0x80 | ch, 60 + ch * 3 + k, 0])
    ev += bytes([0x00, 0x99, 38, 100, 0x10, 0x89, 38, 0])
    ev += b'\x00\xff\x2f\x00'
    mid = b'MThd' + struct.pack('>IHHH', 6, 0, 1, 96) + b'MTrk' + struct.pack('>I', len(ev)) + ev
    open('/tmp/_t_mu.mid', 'wb').write(mid)
    sidm, wm = doc.import_midi('/tmp/_t_mu.mid', 'My Tune')
    asset = os.path.join(tmpd, doc.midi_asset(sidm))
    ent = json.load(open(asset))
    ok("S116 doc: Import MIDI — automatic: 3 of 4 melodic channels kept (warned), drums on "
       "the noise channel; the song file is in the project's assets/music/",
       sidm == 'my_tune' and os.path.exists(asset) and
       [c['slot'] for c in ent['channels']] == [0x34, 0x4E, 0x68, 0x82] and
       any('kept the 3 that play longest' in x for x in wm) and
       doc.project_song(sidm)['source'] == {'file': 'assets/music/my_tune.json'})
    doc.set_room_music_id(0x6C, sidm)            # a custom room: rooms[].music
    doc.set_room_music_id(0x30, 0x2B)            # a vanilla room: room_defaults
    doc.set_gate_music(3, floors=sidm, battles=s7)
    doc.set_battle_music('starry', s7)
    doc.set_fight_music(325, sidm)
    doc.set_song_name('0x09', 'Castle theme')
    ok("S116 doc: room / gate / battle / fight assignments land where the compiler reads them",
       doc.room('dusk_mirror').get('music') == 'my_tune' and
       doc.music()['room_defaults']['0x30'] == '0x2B' and
       doc.music()['gates']['3'] == {'floors': 'my_tune', 'battles': s7} and
       doc.music()['battle'] == {'starry': s7, 'fights': {'325': 'my_tune'}} and
       doc.song_name('0x09') == 'Castle theme' and
       set(doc.song_uses(sidm)) == {'room dusk_mirror', 'gate 3 floors', 'fight EID 325'})
    doc.save()
    C.compile_project(tmpd, REPO)                # the imported song file travels with it
    uses, f = doc.remove_song(sidm)
    ok("S116 doc: Remove from the project clears every assignment of the song",
       f == 'assets/music/my_tune.json' and doc.room('dusk_mirror').get('music') is None and
       doc.music()['gates']['3'] == {'battles': s7} and 'fights' not in doc.music()['battle'])
    return o


def F_db_has(text, values):
    want = ', '.join(f'${v:02X}' for v in values)
    return any(want in ln for ln in text.splitlines() if ln.strip().startswith('db '))


def test_music_rom(tag, rom_bytes, sym, prj_data, orig):
    """--rom: the same-size ROM0 / bank $51 rewrites, the tables, and every project song
    started by the BUILT ROM's own InitBGM in the editor's sound engine (the interpreter
    runs the patched code: InitBGM -> bank $71 CustomBGMStart -> AudioProcess)."""
    from editor2.core import music as MUS
    from editor2.core import sound_engine as SE
    from editor2.core.project import Project
    ok(f"ROM S116 {tag}: InitBGM keeps $1AE5 and PlaySoundEffect $1B2C (71-byte rewrite); "
       "the battle pick keeps LoadBattle's $4073-$408E window",
       sym['InitBGM'] == (0, 0x1AE5) and sym['PlaySoundEffect'] == (0, 0x1B2C) and
       rom_bytes[0x1B2C:0x1B30] == orig[0x1B2C:0x1B30] and
       rom_bytes[0x51 * 0x4000 + 0x0073 + 12:0x51 * 0x4000 + 0x0073 + 16] ==
       bytes([0x21, 0x07, 0x71, 0xD7]) and
       rom_bytes[0x51 * 0x4000 + 0x008F:0x51 * 0x4000 + 0x0100] ==
       orig[0x51 * 0x4000 + 0x008F:0x51 * 0x4000 + 0x0100])
    prj = Project(copy.deepcopy(prj_data), os.path.dirname(EXAMPLE))
    prj.repo_root = REPO
    P = prj.music_plan()
    b, a = sym['CustomBGMChanTable']
    t = b * 0x4000 + a - 0x4000
    imgs = MUS.bank_images(prj)
    ok(f"ROM S116 {tag}: CustomBGMChanTable and song banks $74 / $75 == the plan",
       list(rom_bytes[t:t + 95]) == P.chan_table and
       all(rom_bytes[bk * 0x4000:(bk + 1) * 0x4000] == imgs[bk] for bk in (0x74, 0x75)))
    bad = []
    for r in P.songs:
        m = SE.Machine(rom_bytes)
        m._call(SE.INIT_AUDIO)
        m.start_bgm(r['first_id'])
        w = m.wram
        live = [s for s in MUS.SLOTS if not (w[0xDD80 - 0xC000 + s] == 0xFF and
                                            w[0xDD80 - 0xC000 + s + 0x19] == 0xFF)]
        if live != sorted(c['slot'] for c in r['channels']):
            bad.append((r['id'], live))
    ok(f"ROM S116 {tag}: the built InitBGM starts every project song with exactly its channels "
       f"({len(P.songs)} songs)", not bad, f"({bad})")
    m = SE.Machine(rom_bytes)
    m._call(SE.INIT_AUDIO)
    m.start_bgm(0x27)
    live27 = [s for s in MUS.SLOTS if m.wram[0xDD80 - 0xC000 + s] != 0xFF]
    m2 = SE.Machine(rom_bytes)
    m2._call(SE.INIT_AUDIO)
    m2.start_bgm(0x4D)
    live4d = [s for s in MUS.SLOTS if m2.wram[0xDD80 - 0xC000 + s] != 0xFF]
    ok(f"ROM S116 {tag}: vanilla ids keep their channel counts ($27 four, $4D two)",
       live27 == [0x34, 0x4E, 0x68, 0x82] and live4d == [0x34, 0x4E])


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
       "icon regions in $2E/$4F; S109: + the arena regions in $04/$50/$6E; S110: + the "
       "skill regions in $55/$56/$5F; S111: + the custom-skill regions in $4C/$58/$72; "
       "S112: + the new-animation banks $6F/$70; S114: + the encounter bank $76; S116: + the "
       "second song bank $75; S117: + the shop bank $77; S121: + the Milly hook's bedroom "
       "script $0E and bank $79)",
       sorted(out1) == ['patches/bank_000.asm', 'patches/bank_001.asm',
                        'patches/bank_003.asm', 'patches/bank_004.asm',
                        'patches/bank_006.asm',
                        'patches/bank_007.asm', 'patches/bank_009.asm',
                        'patches/bank_00b.asm', 'patches/bank_00e.asm',
                        'patches/bank_010.asm',
                        'patches/bank_011.asm',
                        'patches/bank_012.asm',
                        'patches/bank_013.asm',
                        'patches/bank_014.asm', 'patches/bank_016.asm',
                        'patches/bank_017.asm', 'patches/bank_018.asm',
                        'patches/bank_02e.asm',
                        'patches/bank_041.asm', 'patches/bank_04c.asm',
                        'patches/bank_04d.asm',
                        'patches/bank_04f.asm', 'patches/bank_050.asm',
                        'patches/bank_054.asm', 'patches/bank_055.asm',
                        'patches/bank_056.asm', 'patches/bank_058.asm',
                        'patches/bank_059.asm',
                        'patches/bank_05f.asm',
                        'patches/bank_060.asm', 'patches/bank_064.asm',
                        'patches/bank_067.asm', 'patches/bank_069.asm',
                        'patches/bank_06a.asm', 'patches/bank_06b.asm',
                        'patches/bank_06c.asm', 'patches/bank_06d.asm',
                        'patches/bank_06e.asm', 'patches/bank_06f.asm',
                        'patches/bank_070.asm',
                        'patches/bank_071.asm', 'patches/bank_072.asm',
                        'patches/bank_074.asm', 'patches/bank_075.asm',
                        'patches/bank_076.asm', 'patches/bank_077.asm',
                        'patches/bank_079.asm', 'patches/bank_07a.asm',
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
    outsk = test_skills_s110()
    outcs, outcsmax = test_custom_skills_s111()
    outan, outan32 = test_anims_s112()
    outen = test_encounters_s114()
    outng = test_new_gates_s115()
    outmu = test_music_s116()
    out117 = test_flags_ng2_s117()
    outshop = test_shops_s117()
    test_sprite_budget_s117b()
    test_clone_follows_game_s118c()
    test_cutscenes_s119()
    test_cutscene_unnamed_npc_s119r2()
    test_cutscene_error_not_at_open_s119b()
    test_dialogue_s120()
    test_gate_rows_s120()
    test_hero_default_s120b()
    out121 = test_milly_hook_s121()
    test_maze_s122()
    out123 = test_worlds_s123()
    test_flag_index_s124()
    test_hub_s125()

    if '--rom' in sys.argv:
        from editor2.core import builder as B
        outdir = '/tmp/_t_regression'
        C.write_outputs(out1, outdir)
        rom, sym, md5 = B.build_rom(REPO, outdir, os.path.join(outdir, 'build'))
        ok("REGRESSION: byte-identical to the pinned reference",
           md5 == REFERENCE_MD5, f"(got {md5})")
        # S121: the Milly hook — off in the example (vanilla bytes), on in a fixture
        test_milly_rom(open(rom, 'rb').read(), B.parse_sym(sym), out121)
        # S123: worlds + NPC colours
        test_worlds_rom(open(rom, 'rb').read(), B.parse_sym(sym), out123)
        # S125: the hub
        test_hub_rom(open(rom, 'rb').read(), B.parse_sym(sym))
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
        # S110: the skills fixture, built
        outdirs = '/tmp/_t_skills'
        C.write_outputs(outsk, outdirs)
        roms, syms, _ms = B.build_rom(REPO, outdirs, os.path.join(outdirs, 'build'))
        test_skills_rom(open(roms, 'rb').read(), B.parse_sym(syms))
        # S111: the custom-skill forks, on the example build and on CS_FIX's
        test_custom_skills_rom('example', open(rom, 'rb').read(), B.parse_sym(sym), base())
        outdircs = '/tmp/_t_cskills'
        C.write_outputs(outcs, outdircs)
        romc, symc, _mc = B.build_rom(REPO, outdircs, os.path.join(outdircs, 'build'))
        test_custom_skills_rom('CS_FIX', open(romc, 'rb').read(), B.parse_sym(symc),
                               _sk_fixture(CS_FIX))
        outdircm = '/tmp/_t_cskills_max'
        C.write_outputs(outcsmax, outdircm)
        romcm, symcm, _mcm = B.build_rom(REPO, outdircm, os.path.join(outdircm, 'build'))
        test_custom_skills_rom('21 new', open(romcm, 'rb').read(), B.parse_sym(symcm),
                               _sk_fixture(CS_MAX[0]))
        # S112: the new-animation tables, on the example build (none) and the fixture
        test_anims_rom('example', open(rom, 'rb').read(), B.parse_sym(sym), base())
        outdiran = '/tmp/_t_anims'
        C.write_outputs(outan, outdiran)
        roman, syman, _man = B.build_rom(REPO, outdiran, os.path.join(outdiran, 'build'))
        test_anims_rom('AN_FIX', open(roman, 'rb').read(), B.parse_sym(syman), AN_FIX)
        outdiran32 = '/tmp/_t_anims32'
        C.write_outputs(outan32, outdiran32)
        roman32, syman32, _m32 = B.build_rom(REPO, outdiran32, os.path.join(outdiran32, 'build'))
        test_anims_rom('32 new', open(roman32, 'rb').read(), B.parse_sym(syman32),
                       _an_fixture([{'id': f'a{k}', 'steps': _an_steps()} for k in range(32)], {}))
        # S114: the encounter forks + bank $76 tables, on the example and EN_FIX builds
        origb = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
        test_encounters_rom('example', open(rom, 'rb').read(), B.parse_sym(sym), base(), origb)
        outdiren = '/tmp/_t_enc'
        C.write_outputs(outen, outdiren)
        romen, symen, _men = B.build_rom(REPO, outdiren, os.path.join(outdiren, 'build'))
        test_encounters_rom('EN_FIX', open(romen, 'rb').read(), B.parse_sym(symen), EN_FIX, origb)
        # S115: the new-gate forks + bank $76 rows, on the example and NG_FIX builds
        test_new_gates_rom('example', open(rom, 'rb').read(), B.parse_sym(sym), base(), origb)
        outdirng = '/tmp/_t_ng'
        C.write_outputs(outng, outdirng)
        romng, symng, _mng = B.build_rom(REPO, outdirng, os.path.join(outdirng, 'build'))
        test_new_gates_rom('NG_FIX', open(romng, 'rb').read(), B.parse_sym(symng), NG_FIX, origb)
        # S116: the music rewrites + tables, on the example and MU_FIX builds
        test_music_rom('example', open(rom, 'rb').read(), B.parse_sym(sym), base(), origb)
        outdirmu = '/tmp/_t_mu'
        C.write_outputs(outmu, outdirmu)
        rommu, symmu, _mmu = B.build_rom(REPO, outdirmu, os.path.join(outdirmu, 'build'))
        test_music_rom('MU_FIX', open(rommu, 'rb').read(), B.parse_sym(symmu), MU_FIX, origb)
        # S117: flag expansion + NG2 engine, executed from the built ROMs
        test_flags_ng2_rom('example', open(rom, 'rb').read(), B.parse_sym(sym), origb)
        outdir117 = '/tmp/_t_s117'
        C.write_outputs(out117, outdir117)
        rom117, sym117, _m117 = B.build_rom(REPO, outdir117, os.path.join(outdir117, 'build'))
        test_s117_engine_rom(open(rom117, 'rb').read(), B.parse_sym(sym117), origb)
        # S117 (P3.13c): shops — the example == the original, SHOP_FIX's lists
        test_shops_rom('example', open(rom, 'rb').read(), B.parse_sym(sym), origb, 5, None)
        # S117b: the bank $09 screen push + the dialog box after a shop
        test_screen_push_rom('example', open(rom, 'rb').read(), B.parse_sym(sym), origb)
        outdirsh = '/tmp/_t_shops'
        C.write_outputs(outshop, outdirsh)
        romsh, symsh, _msh = B.build_rom(REPO, outdirsh, os.path.join(outdirsh, 'build'))
        from editor2.core import shops as SHm
        _o, _psh, _w = compile_data(SHOP_FIX)
        test_shops_rom('SHOP_FIX', open(romsh, 'rb').read(), B.parse_sym(symsh), origb, 6,
                       [l[2] for l in SHm.resolve(_psh)['lists']])
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
                  bb[0x6E * 0x4000 + sy['ArenaTeamSizeTable'][1] - 0x4000:][:30] == bytes([3] * 30)),
                 ('skill names $41:$628E-$69F1 (S110)', at(0x41, 0x628E, 1892)),
                 ('skill descriptions + mode table + 222 pointer rows $56:$502F-$6842 (S110)',
                  at(0x56, 0x502F, 0x6667 + 444 - 0x502F)),
                 ('bank $56 pad $7291 (S110 gd_skill_desc_extra)', at(0x56, 0x7291, 2993)),
                 ('looks-like tables identity (S110, banks $5F / $55)',
                  bb[0x5F * 0x4000 + sy['StockPresentTable'][1] - 0x4000:][:222] == bytes(range(222))
                  and bb[0x55 * 0x4000 + sy['StockSfxTable'][1] - 0x4000:][:222] == bytes(range(222)))]
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
