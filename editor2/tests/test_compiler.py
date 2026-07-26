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
REFERENCE_MD5 = "46ba69918c7ddfdfcd8a441d967debb6"   # S71v2 FX1 reference patched build (exp-scale veto: drain pays FULL pending per eligible farm monster — vanilla per-monster rate; v1 halved it. USER-CONFIRMED v1 mechanics 2026-07-26: farm menus >17, sleep whole-swap, save/reload, breeding + hatches at scale, "everything works"; v2 delta = drain payout only, PyBoy-verified full 512 payout in both farm regions). Prev: 9c3af0d434f3d5bcd617677a42129778 (S71 FX1 reference patched build (farm expansion 17->37 active slots: array 40 slots (0-2 party, 3-19 farm @$A1FB+s*$95, 20-39 farm @$B124+(s-20)*$95 = the evicted sleep pool's bank-0 home; staging pseudo-slot INDICES 20/21 -> 40/41, addresses unchanged $D665/$D6FA); sleep pool -> SRAM bank 2 ($A010+c*$95, 40 slots, "P1" magic) via bank $73 entries 10-12; one-time F2 reformat gate $BFC8-9 in entry 4 (order load-bearing: legacy sums BEFORE F2 stamp, v3 after); checksum v3 = $A002x$1C5 + $AD9Fx$385 + $BCC8x$338; snapshot R4 dual-region ($A1BF x95 + $B124 x94 chunks); roster lists + canonicalizer map -> wMonList $D001 (C0D8 overflow at 40 slots); exp payout halved at drain (aggregate 37/32~=vanilla 17/16); PyBoy-verified: reformat preserves save, R3->R4 upgrade, 25-farm canonicalize/list/rewind/dual-snapshot/drain/battle). Prev: a5a5e0d5d01949b30bbff9d3253d9748 (S70v3 reference patched build (walk-on boundary exits for custom rooms: Entry 6 scan y=7 skip is data-driven via wCustomY7Cmp $DE74 (carved from the S65 legacy pad), armed fresh by bank $60 entry 7 before every scan - vanilla branch writes $07 (original skip semantics preserved), CustomExitCheck writes $FE (custom-room y=7 rows fire on arrival, PyBoy: 36 frames tap-to-transition, vanilla MedalMan door regression-checked push-only); template head 348->358, re-pinned). Prev: 22d30b66827628b9c8d9d400c48568a4 (S70v2 reference patched build (bug-fix pass, PyBoy-verified: init_dialog $07 protocol - every text outside an NPC interaction gets its own preceding init_dialog, auto-injected by quest lowering (field mode never services the text queue; dismissal tears script dialog mode down); emit_script hard-errors on non-terminated scripts (S70 freeze class); encounter seed 1200 (drain measured 100/step); bank $0B custom-source fast transition (in-place 19-byte window rewrite: exits FROM custom rooms take the town path, 18 frames vs the 385-frame gateworld-return ceremony, a day-one defect, not a regression); write_ram2 $13 opcode; Medal Chamber display strings). Prev: 6a6f4f8791cad0a271d210c7f485569c (S70v1 reference patched build (E2 wiring: progression.quests/enemies lowering -> quest:/entry: scripts + bank $14 tail row EID 519; vanilla_exit_extensions -> VanillaExitExtTable + template entry 7 VanillaExitResolve (re-pinned, head 348 B); bank $0B Entry 6 unified divert (-5 B); bank $01 $4C3E reverted to vanilla ld a,[wMapID] (entry scripts fire at initial entry); legacy compat key retired from the example project; room $71 Medal Vault + dwm2_bgm10). Prev: 94731e601af28503060acf3884348015 (S69v2 reference patched build (roster snapshot: bank-1 magic-gated save-time roster copy restoring vanilla reset-rewind semantics; entries 5/6 tail hooks + CF3SnapXfer/Commit/Restore + wSnapBounce $DE92). Prev: e719d286db0ff66e80755ec3ef1203e0 (S69v1 E3 pin (E3 SRAM 32 KB: 19 ROM0 quadrant-convention RAMB writes retargeted $4100->$6100 (MBC5-ignored), HeaderRAMSize $02->$03, bank $73 entry 9 CF3SRAMBankedCopy + wSRAMXfer* mailbox $DE8B-$DE91). Prev: de0c5a672e7e7e1fb834dd7afe70b9e7 (S65 reference patched build (WRAM migration: NPC/exit buffers -> $CC80/$CD00, step-counter region -> $CD80 (640 B) inside the CF3-freed window; $DE74 region -> static ds 7 pad, wRoomRecScratch stays $DE7B; + bank $73 entry 6 tail zeroes the window after the main-image restore copy). Prev: 7cc0857faad8a950573e865e93f791eb (S64 reference patched build (M3b+M3c: LoadNewBGMIdIntoA same-size rewrite -> bank $71 entry 2 CustomRoomBGMResolve + CustomRoomBGMTable; music emitter owns bank $74; dq6_town1 ids $A4-$A6 from MIDI; Library $12 + gate_island $6B room defaults). Prev: 3009b75ee1e3bd58bc315a39b7324e17 (S63v5 reference patched build (M3a v4 + v5: BGM #07 ids $A1-$A3 in bank $74, room $6C NPC via project.json; bank_060 now compiler-generated via --apply). Prev: c23beed7aadee80a061c0f6c24d7c1f4 (S63 v4, M3a: AudioMasterTableExt + song bank $74 + bank $1E reverted; S62's BGM NPC/set_bgm $9E folded into the example project — S62 had hand-edited bank_060 without updating project/pin, breaking compat==hand byte-identity; restored S63). Prev pins: 168c5f1b5b4b3b2568a6d6e2f3f1ab45 (S60), d31c9300e13b98f516c6bee8b446069d (S58v2)

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
    return C.compile_project(tmp, REPO)


def expect_error(name, data, needle):
    try:
        compile_data(data)
    except (ProjectError, C.CompileError) as e:
        ok(name, needle in str(e), f"(got: {e})")
        return
    print(f"FAIL: {name} — expected error containing {needle!r}")
    sys.exit(1)


def main():
    # 1. determinism + example compiles clean
    out1, prj, warns = compile_data(base())
    out2, _, _ = compile_data(base())
    ok("deterministic emit", out1 == out2)
    ok("all six targets produced",
       sorted(out1) == ['patches/bank_014.asm', 'patches/bank_017.asm',
                        'patches/bank_060.asm', 'patches/bank_071.asm',
                        'patches/bank_074.asm', 'patches/wram.asm'],
       f"(got {sorted(out1)})")

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
    d = base()
    d['custom']['rooms'][0]['screens']['0']['npcs'][0]['script'] = 1
    expect_error("spawn script must be 0", d, "spawn entry script must be 0")

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
    expect_error("mapID >= $70 requires record", d, "requires a 'record'")

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
        "0x6B", "0x6C", "0x6D", "0x6E", "0x6F", "0x70", "0x71"]}
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
    for k in range(12):
        e2 = dict(e0); e2['id'] = f"e{k}"; e2['eid'] = 'auto'
        d['progression']['enemies'].append(e2)
    expect_error("quest enemy capacity is 12 rows", d, "capacity")
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

    # 5. text label / id assignment
    ok("text ids map to CustomText_XX labels",
       prj.text_label(0x0A14) == 'CustomText_14')

    if '--rom' in sys.argv:
        from editor2.core import builder as B
        outdir = '/tmp/_t_regression'
        C.write_outputs(out1, outdir)
        rom, sym, md5 = B.build_rom(REPO, outdir, os.path.join(outdir, 'build'))
        ok("REGRESSION: byte-identical to the S70 reference",
           md5 == REFERENCE_MD5, f"(got {md5})")
        # S70 no-op property: strip progression + the extension + the quest
        # room/dialogue/music -> the bank $14 region must regenerate the
        # vanilla ds-308 pad and the ROM delta stays out of bank $14
        # entirely (region byte-identity = the emitter's no-op contract).
        d = base()
        d.pop('progression')
        d['custom'].pop('vanilla_exit_extensions')
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
        ok("no-quest build regenerates the vanilla ds-308 zero tail",
           all(fix[0x14 * 0x4000 + 0x3ECC + k] == 0 for k in range(308)),
           "(quest_enemy_stats region no-op contract)")
        ok("no-quest delta confined to owned banks + header",
           banks <= {0, 0x14, 0x17, 0x60, 0x71, 0x74} and
           all(o in (0x14D, 0x14E, 0x14F) for o in diffs if o < 0x4000),
           f"(diff banks {sorted(hex(b) for b in banks)})")

    print(f"\nALL {PASS} TESTS PASSED")


if __name__ == '__main__':
    main()
