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
REFERENCE_MD5 = "168c5f1b5b4b3b2568a6d6e2f3f1ab45"   # S60 reference patched build (S58 + CF3 full move: farm slots 3-19 -> SRAM). Prev pin: d31c9300e13b98f516c6bee8b446069d (S58v2)

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
    ok("all five targets produced",
       sorted(out1) == ['patches/bank_017.asm', 'patches/bank_060.asm',
                        'patches/bank_071.asm', 'patches/wram.asm'],
       f"(got {sorted(out1)})")

    # 2. NOT_IMPLEMENTED layers hard-error
    d = base(); d['world'] = {'transitions': [1]}
    expect_error("world layer content hard-errors", d, "NOT_IMPLEMENTED")
    d = base(); d['custom']['music'] = [{'song': 'x'}]
    expect_error("custom.music hard-errors", d, "NOT_IMPLEMENTED")
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
    d['build']['compat']['master_table_rooms'] = ["0x6B", "0x6D"]
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

    # 4. legacy-compat warning present; removing compat drops it
    ok("compat overshoot warning fires",
       any('LEGACY narrow master table' in w for w in warns))
    d = base(); del d['build']['compat']
    _, _, w2 = compile_data(d)
    ok("no compat warning without compat key",
       not any('LEGACY narrow' in w for w in w2))

    # 5. text label / id assignment
    ok("text ids map to CustomText_XX labels",
       prj.text_label(0x0A14) == 'CustomText_14')

    if '--rom' in sys.argv:
        from editor2.core import builder as B
        outdir = '/tmp/_t_regression'
        C.write_outputs(out1, outdir)
        rom, sym, md5 = B.build_rom(REPO, outdir, os.path.join(outdir, 'build'))
        ok("REGRESSION: byte-identical to S53 reference",
           md5 == REFERENCE_MD5, f"(got {md5})")
        d = base(); del d['build']['compat']
        outs, _, _ = compile_data(d)
        outdir2 = '/tmp/_t_fixed'
        C.write_outputs(outs, outdir2)
        rom2, _, md5f = B.build_rom(REPO, outdir2, os.path.join(outdir2, 'build'))
        ref = open(rom, 'rb').read(); fix = open(rom2, 'rb').read()
        diffs = [i for i in range(len(ref)) if ref[i] != fix[i]]
        banks = {i // 0x4000 for i in diffs}
        ok("fixed build delta confined to bank $60 + header",
           banks <= {0, 0x60} and
           all(o in (0x14D, 0x14E, 0x14F) for o in diffs if o < 0x4000))

    print(f"\nALL {PASS} TESTS PASSED")


if __name__ == '__main__':
    main()
