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
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)

from editor2.core import compiler as C
from editor2.core import validators as V
from editor2.core.project import Project, ProjectError

EXAMPLE = os.path.join(REPO, 'editor2/example-project/project.json')
REFERENCE_MD5 = "0d60486e57edc2ad31fa28079d4fc9f8"   # S102 (built, NOT yet user-tested): own tile animations — new compiler-owned bank $6C (template bank_06c_head.asm: CustomTileAnimate / TileAnimRestart / TileAnimCopy, empty TileAnimRoomTable in the example), bank $71 CustomAnimSource far-calls it first (+4 B), wram.asm carves wTileAnim* from wCustomPool. Prev: 9c81304176bd069ec77cd4c0d2211900   # S101 (built, NOT yet user-tested): ROADMAP P3.7b part 2 custom boss floors — bank $16 GateFloorDataTable is a compiler-owned region (custom.gates: floors 2-99, boss = custom room / vanilla:$xx, hand_made; the example has no custom.gates so the 256 B are vanilla); bank $14 LoadEnemyStats head -> LoadEnemyStatsExt (EID >= 519 -> new compiler-owned bank $6B CopyEnemyRowExt / ProjectEnemyRows, template bank_06b_head.asm pinned) and LookupBossRedirect -> BossRedirectTableExt (project join_as rows, then the vanilla 34) — the old bank-$14 tail enemy row (quest EID 519) moved to bank $6B; bank $60 CustomStateRules calls CustomMonsterCast first (per-screen monster NPC cast -> $D7CA; empty table in the example); bank $71 CustomRoomBGMResolve: the floor before a CUSTOM boss map plays that room's song (or $34). Example project.json: raw script op hex normalised to the new names (branch_screen/npc_write/...; bytes identical). Prev: 7cd7257b94004fdf8b406138dc7122e1   # S100 r3 (built, NOT yet user-tested): (1) stairs/special-room descent from a FREE-COLOUR custom room faded through the room's own colour 1 (user: "background is not CREAM but room-tile coloured") — bank $06 MapTrans_S10_InGate + MapTrans_S12 same-size rewrites far-call bank $73 new entries 19 GateWipeAttr (the 20x14 $E0 fill rows -> attr 7) and 20 GateLeaveFreePal (buffer+HW colour 1 := cream once the room is squeezed; the load fade targets buffer colour 1); vanilla + unmarked rooms early-ret (PyBoy: vanilla $50 pit transition = same pictures, single-scanline timing jitter only); (2) tools/compress_tiles.py MAX_COPY 256 (the game adds 19 in 8 bits: a 257-274 byte copy wrapped and shifted the rest of a sheet 256 B — an imported blank sheet drew as flat colour blocks) + decompress_tiles.py 8-bit like the game; the example sheet re-encodes (its old stream happened to decode right); (3) editor: "Stairs down here" paints the vanilla next-floor well ($51 slots $2C-$2F over the cell's floor). Prev: 91202c74fc9fc80dffc0e397d9d5e083   # S100 r2 (built, NOT yet user-tested): the example gate rule gains once_per_dive (user 14:39: gate_rotation could be floor 2 AND floor 3 of one dive; PyBoy 40 dives: floor 2 19x, floor 3 12x, never both). Prev: 4f13d2af8411c0b4387094221e9c2382   # S100 (built, NOT yet user-tested): ROADMAP P3.7b part 1 gate room insertion — bank $16 GateDecisionFork rewritten (the S41 hardcoded gate-1 -> $6D POC + CustomGate1Setup removed; push/pop BC around the far call because the vanilla special-room test after the fork divides B = wCurrentFloor) -> bank $71 entry 4 CustomGateInsert over the generated GateInsertTable (custom.gate_inserts[]: gate, floors, chance, flag terms, once-per-dive); entry 5 CustomRoomFlags + CustomRoomFlagsTable (can_save) read by the bank $07 save ladder same-size rewrite SaveAllowCheck (vanilla verdicts identical over all 256 mapIDs); entry 1 gate byte $FF = follow the dive (no pin); dive state wGateDiveGate/Mask $DEBC-D persisted via SRAM $BFCA-B in bank $73 entries 5/6; template 164 -> 395 B re-pinned; example project: gate_rotation served on Villager floors 2-3 at 50 % (was every floor), gate_arrival (4,6), stairs tag. PyBoy on the user save: gate-21 decisions identical to the S99 build (no rule = no RNG), floor 2/3 hit 19/40 each, floor 4 0/40, once-per-dive + flag rule + follow-gate encounters + gate/own music + JOURNAL allowed/refused + save-in-room/reload/descend. Prev: d072eb516dabc4799d830c170bbc9d9f   # S99 (built, NOT yet user-tested): ROADMAP P3.3e room tile animation — bank $01 PerRoomVRAMDispatch same-size rewrite (the six wGameState bit/ret-nz guards collapsed into `and $fe / cp $10`, proven equivalent over all 65,536 (wGameState, $C8EF) pairs; freed bytes fund: custom rooms ask bank $71 entry 3 CustomAnimSource for their animation source instead of `call MapIDClampForDispatch` = Castle for all); template bank_071_head.asm + entry 3 (head 142 -> 164 B, re-pinned); generated CustomAnimSrcTable (1 B/room); example project gains explicit `animation` (arena_clone source = $06 bare ret; the rest none) — so tiles 77/78 no longer roll in the example rooms. PyBoy: vanilla rooms frame-converge with the S98 build (sub-frame tile-load timing only), clones animate their source (test_canvas v6 --rom: VRAM == census schedule). Prev: ce24de8b708fe453711075dd0a3e07f8   # S97 round 2 (USER-CONFIRMED 2026-09-26; S98 changed no example/compiler-owned bytes — pin held): text boxes keep palette 7 (cream) in free-colour custom rooms — bank $06 dialog LoadMapS_6939 / state 9 / LoadMapS_6b3d same-size far calls to bank $73 entries 14-16 (row attrs saved to wBoxAttrSave, set to 7, restored cell by cell on close), bank $56 SetB56_48a1 + bank $00 ClearTextBitsRedraw same-size far calls to entries 18/17 for the YES/NO box; wram carves 132 B from wCustomPool. Vanilla + non-free rooms: pixel-identical dialog/choice frames (PyBoy). No example bytes change from the S97 r2 boxes text form (the example uses `lines`). Prev: 6e97fd377f50de47c98dcd665f515da7   # S97 round 1 (USER-CONFIRMED 2026-09-26): ROADMAP P3.5a state rules — bank $60 template entry 8 CustomStateRules (+ CustomReadStep calls it; head 383 -> 492 B, re-pinned) and bank $17 CustomAttrCheck calls StateRulesHook17 first (3 B from the ds-12 reserve -> ds 9; PyBoy-measured: the attr/palette walk reads the step counter BEFORE bank $0B Entry 0, so a rule evaluated only in Entry 0 loads the previous state's palette — A/B proven on the servant clone); generated CustomStateRulePtrTable in bank $60; the example project's S92 rank demo moved from the entry:medal_vault prelude to arena_clone.state_rules (flag $0030 -> screen 1 state 1; PyBoy: identical NPC sets flag clear/set, survives a wiped counter; vault entry script unchanged in behaviour). Also S97: the NPC type byte fields (behaviour/object) in the compiler — no example bytes change from them. Prev: 5db25d15af6298ca8be9e717a4a95b41   # S96 round 4 (USER-CONFIRMED 2026-09-25 ("Everything works"), SameBoy menu/battle): field-menu fix for free-colour rooms (user SameBoy report: washed-out room after closing the menu + colour-1 squares during the open wipe). FreeColor1Hook now keys on a PER-SLOT marker (bit 15 of colour 3 in slots 0-3, compiler-set for free_color1 palettes) and puts it back after the colour-3 pass, so the menu's standalone LoadPal_4102 no longer re-forces cream; bank $06 A-press menu-open tail rewritten same-size (4x `ld [hl+],a`) to far-call bank $73 entry 13 MenuOpenFreePal (hardware colour 1 := cream for marked slots during the tile-$E0 wipe; buffer untouched, menu-close push restores). Vanilla rooms: 619/620 menu frames pixel-identical to the round-3 build (1 mid-redraw text frame shifted by the far call's cycles). Prev: 07a71f202f011530ba7bb7d312666a97   # S96 (built, NOT yet user-tested): bank $17 FreeColor1Hook — LoadPal_4102's colour-1 pass (`ld a, [$c7d1]`) same-size -> jp FreeColor1Hook (bank tail, before room_render_tables): custom rooms whose loaded palette has bit 15 in slot 0 colour 3 (compiler marker for `free_color1` palettes) keep their own colour 1 in slots 0-3; slots 4-6 and every vanilla room unchanged. Example project has no free_color1 palette, so only the hook code moves bytes (room_render_tables shift, label-resolved). PyBoy: Pei import room BG palette RAM slots 0-3 == project (own colour 1), slots 4-7 $6BFF, GreatTree unchanged, holds after screen scroll. Prev: fc1caa987f5d4be1ad86ef7d4e87db20   # S94b (built, NOT yet user-tested): (1) vanilla-format per-(screen, STATE) attr+palette tables — bank $17 CustomAttrPtrTable -> RoomAttr_<mid> (16 dw) -> ScrAttr_<mid>_<k> (dw step counter; per state db attr_entry, attr_bank / dw pal_ptr) read by CustomAttrCheck/CustomPalCheck exactly like the vanilla AttrPtrTable walk (vanilla varies attr AND palette per step: Servant room $3F; clones carry ALL valid vanilla steps as states[] with per-state layout/attr/palette); (2) entrance redirects — custom.entrance_redirects[] lowered to per-(mapID, screen) VanillaExitExtTable rows (db mapID, screen; $FF = any) with every valid vanilla step rebuilt from extracted/map_table.json and only the named door re-pointed; template head 358 -> 383 (VanillaExitResolve keys on wScreenIndex), re-pinned; (3) bank $0B RoomEntry9 (boundary push exits) diverted through bank $60 entry 7 too (same-size rewrite, 5 nops) so y=0/7 extension rows are LIVE; (4) Exit_GreatTree_s8 restored to VANILLA bytes — the S92 Library-door repoint ($72) and the S1-era (4,5)->$6B entrance are now example-project DATA (entrance_redirects). PyBoy: Library door -> $72 scr 1 (14,7); (4,5) -> $6B (7,6); untouched GreatTree screen-12 door -> $0D; MedalMan south edge and OldManGate south edge identical to the original ROM; fresh-project Farm clone + redirect walk-through (test_canvas --rom). Prev: cdadf8346e207c248b151491e3ca2774   # S94 (built, NOT yet user-tested): per-SCREEN attr maps — CustomAttrCheck (patches/bank_017.asm) now reads CustomRoomAttr as dw per room -> 17-byte [bank, entry x16] map emitted by render17 (screens[k].attr > layout item attr > render.attr > $FF vanilla); the S42 base_entry+2 stride is retired (a 6-screen Farm clone PyBoy-verified: each screen its own attr, old rule mismatched 100+ tiles on screens 2/4/5/6). Also S94: ROM0 $26DD rows $6B-$6F are a compiler-owned @BUILD_PROJECT region in patches/bank_000.asm (rom0_records emitter; record required for EVERY room), 4x4 screen grid schema (keys 0-15, subtable width per row), extract_room emits screens[].attr, arena_clone screens 1/2 now carry their OWN attr items (attr_s1/attr_s2 — the faithful clone; under the old stride both showed attr_s2). Prev: df3219623203cf5bc272cb6155f07a01   # S92v5 (USER-CONFIRMED): rank state re-authored as visible-by-removal — rank G+ (flag $0030) removes the (7,6) $12 attendant; user-confirmed vanishing in-game. The v4 swap target $54 renders empty in field contexts (S91) — and that is VANILLA-FAITHFUL: user confirms the real lobby shows only 2 bunnies + 2 desks (the $54 entry is the desk talk-point). USER-CONFIRMED this session: Library-door entrance teleports to the clone; all 3 clone screens accessible on a normal save; postgame right-screen "crash" was a savestate issue, not the ROM. Prev S92v4: rank trigger corrected to EVENT FLAG $0030 (rank G cleared) — the S92v3 $D9CE ladder keyed a transient coliseum variable, not persistent rank (user-reported: G cleared, no state change). Both preludes (entry:medal_vault + arena_clone scr0) now if_flag_set $0030. PyBoy-verified on BOTH user saves: normal (flag 0 -> ctr 0 -> clerk) and postgame (flag 1 -> ctr 1 -> slime in buffer after a screen-seam cross; first-load NPCs predate the entry-script arming per the measured load-order rule, and a seam cross re-reads the screen state mid-visit — no re-entry needed). Postgame right-screen crash NOT reproduced headless (marker tile, NPC talk, north door all clean on the user postgame sav) — handed to user SameBoy debugging. Prev S92v3 (user-directed): GreatTree Library door REPOINTED to arena_clone $72 — in-place same-size byte edit in patches/bank_00b.asm at $0B:$4FE6 (05 03 12 00 04 05 07 -> 05 03 72 00 01 04 07; restore note at the site). NO injected triggers: the $12/$13 vanilla_exit_extensions rows are REMOVED (the v2 gate-room door was behind the 100-monster gate; main-Library injection is blocked by the map-wide replacement-list hazard, KEY_LESSONS S92). PyBoy-verified with real transitions both directions (Library south exit regressed; door -> clone (14,7) scr1; clone south -> GreatTree scr 4). Library itself unreachable while the repoint stands (testing stance, user-approved). Prev S92 pins: d5e052081890dd24137c0738aa240794 (v2 gate-room door), + Library Gate Room ($13) vanilla_exit_extensions row — Arena-clone door at (8,6), bottom-right corner (user-directed entrance; the well/vault chain was not the user's topology). Single sub-room = no cross-screen exit-replacement hazard (Library $12 itself is 2 screens sharing one replacement list — rejected for that reason, KEY_LESSONS S92). Both vanilla steps mirrored verbatim; return door PyBoy-regressed. Prev S92 pins: 9e5b592fd4b1150e1504d1be6b0c7c17 (prelude arming), + custom.script_preludes (entry:medal_vault arms arena_clone S1 rank state pre-transition; PyBoy-measured: state selection reads the counter at destination LOAD before its entry script) + rank demo re-authored as an in-budget NPC SWAP + placeholder zero 26DD rows. Interim S92 pin c3513d85283cac54778d0629f4537d6e (clone content, pre-prelude). S92 base: P3.2 [G-A] banks $64/$67 fold behind project.json + states[] backend [G-G] + P3.2b [G-J] clone extractor. Example project GAINS arena_clone ($72, vanilla Arena Lobby $06 clone via tools/extract_room.py, single-version per user decision, BGM $1E), island_copy ($73, custom->custom clone of gate_island), an authored medal_vault staircase layout+exit, and a 2-state rank demo on arena_clone screen1. The $64/$67 EMISSION is byte-identical to the prior hand-generated banks (proven via --expect-md5 a17bff8e67f3043fbff653c65128ea16 before clone content; the fold itself is zero-delta). NOT yet user-tested (built S92). Prev: a17bff8e67f3043fbff653c65128ea16 S85b: AI-committed Anchor $E4 rewritten to Attack in DispatchBoundsStub (prev S85 4c8de38a758eda5eb256d0af6f3be5b1: DispatchBoundsStub re-route $E5-$E8 -> $62BF (bank $58; AI-committed Tremor/Quake swept the party) + Anchor $E4 true no-op in CustomBattleExec (bank $72). Also absorbs the S84 pin move that was never recorded here: b99455d67012e2f451cd5ed96a5020a1 (S84: DispatchBoundsStub bounds guard for AI-committed ids > $E5, bank $58 $694F). Neither session touched compiler-owned banks; the pin is the whole-ROM regression. Prev: ce1e7369eb3876866e897c278510c3ae (S75v4: + LearnCode2Guard06 (bank $06: custom ids can never stat-learn via the code-2 path) + SlotProbeGuard50 (bank $50: level probe bounds slot index < $28; the stale-$cac0 phantom-slot-40 echo-RAM hazard) + builder-integrated validate_custom_data.py. Prev: 762c0df0e23611bce6c931813e976d0c (S75v2: banner-before-animation (user feedback: MournCountDead shared counter evaluated in the anim fork; banner render + $FE hold state precede the two slash plays; handler keeps only the multiplier; bank $72 only). Prev: a914e4896c3380b061d9bff8cfe509f6 (S75: + custom skill $E9 Mourn (ATK-vs-DEF x (dead allies+1) via the 2nd dispatch trampoline MournDispatch52; double EvilSlash replay; boost banner; banks $06/$07/$14/$41/$4c/$52/$53/$54/$56/$58/$5f/$72/wram -- BATTLE_SKILL_SYSTEM 13.8). This pin supersedes the S73b reference DIRECTLY: the S74 Earthquake bytes were never pinned here (S74 did not touch compiler-owned banks and did not run this chain), so the S74+S75 patched deltas both land in this one pin move. Prev: 224b11766b28de88cdb206c31145e286 (S73b: + skill descriptions for $E0-$E4 (bank $56 table $6667 repoints + 226 string bytes from tail pad) and battle field-only rejection for $E4 (bank $50 FieldOnlySkillA shared predicate: menu $0302 message without consuming the turn + usable-count exclusion; 12-byte mid-pad consumption, shift audit clean). Prev: 8fa605d795a7591871d5ad02058addfb (S73 Anchor reference patched build (custom skill $E4 Anchor: field-cast system RE'd — bank $07 usability whitelist in-place rewrite + Anchor07Post state-4 menu close; bank $14 entry-4 tail -> bank $72 AnchorField14Tail context classifier; script arm protocol ctr=$FFFF; GateAwareDispatch script-type branch (template re-pinned); medal_vault scripts 2-5 + dialogue $0A20-$0A23; bank $73 commit-hook arm 1/2/3 (anchor store / install+3/4-current-MP charge on arrival / GateDecisionFork force-standard); persistent wAnchorGate/Floor $D9D7-8 (flags $01E0-$01EF retired), transient $DEB2-3; PyBoy-verified full round trip via real menu UI both directions, MP 98->24, anchor single-use, error dialogs 4/5, NO paths, Heal/WarpWing/NPC regressions). Prev: 46ba69918c7ddfdfcd8a441d967debb6 (S71v2 FX1 reference patched build (exp-scale veto: drain pays FULL pending per eligible farm monster — vanilla per-monster rate; v1 halved it. USER-CONFIRMED v1 mechanics 2026-07-26: farm menus >17, sleep whole-swap, save/reload, breeding + hatches at scale, "everything works"; v2 delta = drain payout only, PyBoy-verified full 512 payout in both farm regions). Prev: 9c3af0d434f3d5bcd617677a42129778 (S71 FX1 reference patched build (farm expansion 17->37 active slots: array 40 slots (0-2 party, 3-19 farm @$A1FB+s*$95, 20-39 farm @$B124+(s-20)*$95 = the evicted sleep pool's bank-0 home; staging pseudo-slot INDICES 20/21 -> 40/41, addresses unchanged $D665/$D6FA); sleep pool -> SRAM bank 2 ($A010+c*$95, 40 slots, "P1" magic) via bank $73 entries 10-12; one-time F2 reformat gate $BFC8-9 in entry 4 (order load-bearing: legacy sums BEFORE F2 stamp, v3 after); checksum v3 = $A002x$1C5 + $AD9Fx$385 + $BCC8x$338; snapshot R4 dual-region ($A1BF x95 + $B124 x94 chunks); roster lists + canonicalizer map -> wMonList $D001 (C0D8 overflow at 40 slots); exp payout halved at drain (aggregate 37/32~=vanilla 17/16); PyBoy-verified: reformat preserves save, R3->R4 upgrade, 25-farm canonicalize/list/rewind/dual-snapshot/drain/battle). Prev: a5a5e0d5d01949b30bbff9d3253d9748 (S70v3 reference patched build (walk-on boundary exits for custom rooms: Entry 6 scan y=7 skip is data-driven via wCustomY7Cmp $DE74 (carved from the S65 legacy pad), armed fresh by bank $60 entry 7 before every scan - vanilla branch writes $07 (original skip semantics preserved), CustomExitCheck writes $FE (custom-room y=7 rows fire on arrival, PyBoy: 36 frames tap-to-transition, vanilla MedalMan door regression-checked push-only); template head 348->358, re-pinned). Prev: 22d30b66827628b9c8d9d400c48568a4 (S70v2 reference patched build (bug-fix pass, PyBoy-verified: init_dialog $07 protocol - every text outside an NPC interaction gets its own preceding init_dialog, auto-injected by quest lowering (field mode never services the text queue; dismissal tears script dialog mode down); emit_script hard-errors on non-terminated scripts (S70 freeze class); encounter seed 1200 (drain measured 100/step); bank $0B custom-source fast transition (in-place 19-byte window rewrite: exits FROM custom rooms take the town path, 18 frames vs the 385-frame gateworld-return ceremony, a day-one defect, not a regression); write_ram2 $13 opcode; Medal Chamber display strings). Prev: 6a6f4f8791cad0a271d210c7f485569c (S70v1 reference patched build (E2 wiring: progression.quests/enemies lowering -> quest:/entry: scripts + bank $14 tail row EID 519; vanilla_exit_extensions -> VanillaExitExtTable + template entry 7 VanillaExitResolve (re-pinned, head 348 B); bank $0B Entry 6 unified divert (-5 B); bank $01 $4C3E reverted to vanilla ld a,[wMapID] (entry scripts fire at initial entry); legacy compat key retired from the example project; room $71 Medal Vault + dwm2_bgm10). Prev: 94731e601af28503060acf3884348015 (S69v2 reference patched build (roster snapshot: bank-1 magic-gated save-time roster copy restoring vanilla reset-rewind semantics; entries 5/6 tail hooks + CF3SnapXfer/Commit/Restore + wSnapBounce $DE92). Prev: e719d286db0ff66e80755ec3ef1203e0 (S69v1 E3 pin (E3 SRAM 32 KB: 19 ROM0 quadrant-convention RAMB writes retargeted $4100->$6100 (MBC5-ignored), HeaderRAMSize $02->$03, bank $73 entry 9 CF3SRAMBankedCopy + wSRAMXfer* mailbox $DE8B-$DE91). Prev: de0c5a672e7e7e1fb834dd7afe70b9e7 (S65 reference patched build (WRAM migration: NPC/exit buffers -> $CC80/$CD00, step-counter region -> $CD80 (640 B) inside the CF3-freed window; $DE74 region -> static ds 7 pad, wRoomRecScratch stays $DE7B; + bank $73 entry 6 tail zeroes the window after the main-image restore copy). Prev: 7cc0857faad8a950573e865e93f791eb (S64 reference patched build (M3b+M3c: LoadNewBGMIdIntoA same-size rewrite -> bank $71 entry 2 CustomRoomBGMResolve + CustomRoomBGMTable; music emitter owns bank $74; dq6_town1 ids $A4-$A6 from MIDI; Library $12 + gate_island $6B room defaults). Prev: 3009b75ee1e3bd58bc315a39b7324e17 (S63v5 reference patched build (M3a v4 + v5: BGM #07 ids $A1-$A3 in bank $74, room $6C NPC via project.json; bank_060 now compiler-generated via --apply). Prev: c23beed7aadee80a061c0f6c24d7c1f4 (S63 v4, M3a: AudioMasterTableExt + song bank $74 + bank $1E reverted; S62's BGM NPC/set_bgm $9E folded into the example project — S62 had hand-edited bank_060 without updating project/pin, breaking compat==hand byte-identity; restored S63). Prev pins: 168c5f1b5b4b3b2568a6d6e2f3f1ab45 (S60), d31c9300e13b98f516c6bee8b446069d (S58v2)))

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

out1_ex = [None]


def main():
    # 1. determinism + example compiles clean
    out1, prj, warns = compile_data(base())
    out1_ex[0] = out1
    out2, _, _ = compile_data(base())
    ok("deterministic emit", out1 == out2)
    b60_ex = out1['patches/bank_060.asm']
    ok("all twelve targets produced (S101: + bank $16 gate table, bank $6B enemies; "
       "S102: + bank $6C tile animation)",
       sorted(out1) == ['patches/bank_000.asm',
                        'patches/bank_014.asm', 'patches/bank_016.asm',
                        'patches/bank_017.asm',
                        'patches/bank_060.asm', 'patches/bank_064.asm',
                        'patches/bank_067.asm', 'patches/bank_06b.asm',
                        'patches/bank_06c.asm',
                        'patches/bank_071.asm',
                        'patches/bank_074.asm', 'patches/wram.asm'],
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
    d = base()
    for k in range(59):
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
       reg.index('dw 519, 520') < reg.index('dw 4, 486'))
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

    if '--rom' in sys.argv:
        from editor2.core import builder as B
        outdir = '/tmp/_t_regression'
        C.write_outputs(out1, outdir)
        rom, sym, md5 = B.build_rom(REPO, outdir, os.path.join(outdir, 'build'))
        ok("REGRESSION: byte-identical to the pinned reference",
           md5 == REFERENCE_MD5, f"(got {md5})")
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
        d.pop('progression')
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
