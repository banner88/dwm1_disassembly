#!/usr/bin/env python3
"""census_text_override.py — the game's own texts, edited, measured in the game
(S150, ROADMAP P3.6 / Phase F T-author; PROJECT_COMPILER §2.58, TEXT_SYSTEM
"Edited game text (S150)").

Every text the game shows or copies is found by ROM0 SaveBankAndSwitch (level 1:
the mode's per-id TABLE in the current bank; level 2: the text's address at
table + 2 * id). S150 hooks its level-1 read (TextLevel1Hook -> bank $60 entry
14 -> the text home bank) so an edited text — keyed by its pointer SLOT — is read
from wherever the build put it.

The census boots a built ROM to the title screen in PyBoy and, for EVERY slot of
the editor's index (extracted/dialogue.json: the 2,560 text ids + every table —
editor2/core/gametext.py), stub-calls the game's own two text entry points with
that table (a WRAM word as the mode list, mode 0, id = the slot's index, the
table's bank mapped):

  show   ROM0 CallTextEngine ($05B6): the text the engine will print = the bytes
         at bank [$C824], address [$C82D] up to the closing $F0 — must be the
         project's edit (gamedata.text, encoded + $F0) or, unedited, the
         original bytes at the slot's original address;
  copy   ROM0 RunTextHandler ($05F6) with the buffer [$C837] = $C100: the buffer
         must hold the same bytes (an edited text in another bank is copied by
         that bank's TextOvrCopy).

Usage:
  census_text_override.py --make DIR [--base PROJECT]   a census project: the base
        project (default editor2/example-project) with EVERY text edited (the
        markup's letters swapped in case, non-name texts one glyph longer — '~'
        first), built into DIR/build/build
  census_text_override.py --project DIR [--rom ROM] [--negative] [--out F]
  census_text_override.py --selftest   (verify check 5, offline: every original
        text reads back through the markup codec — editor2/core/textmark.py,
        both styles — and the saved census is clean)
--negative: two pokes of the built ROM, one per class — (a) the first TextOvrDir
row's table byte + 1 (that table's edits are no longer found), (b)
SaveBankAndSwitchCopy's `ld a, $01` -> `ld a, $00` (a copy is looked up as a
show, so an edited text in another bank is copied from the wrong bank): each
must FAIL. Writes extracted/text_override_census.json.
"""
import argparse
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
try:
    from tools.pyboy_harness import boot, adv                     # noqa: E402
except ImportError:
    boot = adv = None
from editor2.core import gametext as GT, textmark as TM           # noqa: E402

OUT = os.path.join(REPO, 'extracted', 'text_override_census.json')
STUB = 0xDD40
MARK = STUB - 1
WTABLE = 0xDD30                 # the WRAM "mode list": one word = the slot's table
BUF = 0xC100                    # the copy buffer (the dialog backup area; idle at the title)
BUF_SIZE = 0x400
CALL_SHOW, CALL_COPY = 0x05B6, 0x05F6


# --------------------------------------------------------------------------- make
def edited_markup(x):
    """The census edit of an original text: letters swapped in case; a non-name
    text one glyph longer ('~' first)."""
    m = x.markup()
    # tokens are case-insensitive; {$xx} escapes stay hex
    s = m.swapcase()
    if x.source not in GT.MAX_GLYPHS:
        s = '~' + s
    return s


def make_project(out_dir, base):
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)
    shutil.copytree(base, out_dir, ignore=shutil.ignore_patterns('build'))
    pj = os.path.join(out_dir, 'project.json')
    d = json.load(open(pj))
    ix = GT.index(REPO)
    n = 0
    for k in ix.order:
        x = ix.entries[k]
        if x.owner:
            continue
        GT.set_edit(d, x.source, x.key, edited_markup(x))
        n += 1
    json.dump(d, open(pj, 'w'), indent=1, ensure_ascii=False)
    r = subprocess.run([sys.executable, os.path.join(REPO, 'tools', 'build_project.py'),
                        '--project', out_dir, '--build'], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(r.stdout[-3000:] + r.stderr[-3000:])
    print(f'census project: {n} texts edited, built into {out_dir}/build/build')
    return os.path.join(out_dir, 'build', 'build', 'rom.gbc')


# --------------------------------------------------------------------------- census
def sym_table(rom):
    out = {}
    for line in open(os.path.join(os.path.dirname(rom), 'game.sym')):
        m = re.match(r'([0-9a-f]+):([0-9a-f]+) (\S+)', line)
        if m:
            out[m.group(3)] = (int(m.group(1), 16), int(m.group(2), 16))
    return out


def run_stub(p, bank, table, idx, call):
    m = p.memory
    code = [0xF3,                                   # di
            0x3E, bank, 0xEA, 0x00, 0x21,           # ld a, bank / ld [$2100], a
            0x3E, 0x00, 0xEA, 0x22, 0xC8,           # ld a, 0 / ld [$c822], a
            0x3E, idx, 0xEA, 0x23, 0xC8,            # ld a, idx / ld [$c823], a
            0x11, WTABLE & 0xFF, WTABLE >> 8,       # ld de, WTABLE
            0xCD, call & 0xFF, call >> 8,           # call CallTextEngine / RunTextHandler
            0x3E, 0xA5, 0xEA, MARK & 0xFF, MARK >> 8,
            0x18, 0xFE]
    for i, b in enumerate(code):
        m[STUB + i] = b
    m[WTABLE], m[WTABLE + 1] = table & 0xFF, table >> 8
    m[0xC837], m[0xC838] = BUF & 0xFF, BUF >> 8
    m[MARK] = 0
    p.register_file.PC = STUB
    for _ in range(400):
        p.tick(1, False)
        if m[MARK] == 0xA5:
            return True
    return False


def rom_text(rom, bank, addr):
    if not 0x4000 <= addr < 0x8000:
        return None
    t = TM.scan(rom, bank * 0x4000 + addr - 0x4000)
    return None if t is None else t + b'\xf0'


def census(project, rom_path, quiet=False, max_fails=None):
    from editor2.core.project import Project
    prj = Project.load(project)
    prj.repo_root = REPO
    edits = {(x.source, x.key): raw for x, raw in GT.resolve(prj, REPO)}
    rom = open(rom_path, 'rb').read()
    ix = GT.index(REPO)
    tmp = tempfile.mkdtemp()
    rc = os.path.join(tmp, 'census.gbc')
    shutil.copy(rom_path, rc)
    p = boot(rc)
    adv(p, 600)
    st = io.BytesIO()
    p.save_state(st)
    res = {'slots': 0, 'edited': 0, 'show_ok': 0, 'copy_ok': 0, 'fails': []}
    t0 = time.time()
    seen = set()
    for k in ix.order:
        x = ix.entries[k]
        if x.slot in seen:
            continue
        seen.add(x.slot)
        res['slots'] += 1
        want = edits.get((x.source, x.key))
        if want is None:
            # unedited: what THIS build's slot points at (a gamedata region may
            # have moved it — e.g. a custom skill's description)
            o = x.bank * 0x4000 + x.table + 2 * x.index - 0x4000
            want = rom_text(rom, x.bank, rom[o] | rom[o + 1] << 8)
        else:
            res['edited'] += 1
        for mode, call in (('show', CALL_SHOW), ('copy', CALL_COPY)):
            st.seek(0)
            p.load_state(st)
            ok = run_stub(p, x.bank, x.table, x.index, call)
            m = p.memory
            if not ok:
                got, where = None, 'no return'
            elif mode == 'show':
                b, a = m[0xC824], m[0xC82D] | m[0xC82E] << 8
                got, where = rom_text(rom, b, a), f'${b:02X}:${a:04X}'
            else:
                buf = bytes(m[BUF + i] for i in range(BUF_SIZE))
                e = buf.find(b'\xf0')
                got, where = (buf[:e + 1] if e >= 0 else None), 'buffer'
            exp = want
            if mode == 'copy' and want is not None:
                # RunTextHandler (and TextOvrCopy) copy up to the first $F0 BYTE —
                # a parameter $F0 ($FB $F0, the battle tutorial) ends the copy too
                exp = want[:want.index(0xF0) + 1]
            if got == exp:
                res[mode + '_ok'] += 1
            else:
                res['fails'].append({'text': f'{x.source} {x.key}', 'mode': mode, 'at': where,
                                     'want': exp.hex() if exp else None,
                                     'got': got.hex() if got else None})
        if max_fails is not None and len(res['fails']) >= max_fails:
            res['stopped'] = True
            break
        if not quiet and res['slots'] % 500 == 0:
            print(f"  {res['slots']} slots ({time.time() - t0:.0f} s), "
                  f"{len(res['fails'])} fails")
    # the S105 G3 redirect (ROM0 LoadModeBaseRedirect until S150, now bank $60 entry
    # 14): bank $41 mode 7 ($4739, the 2-letter default nicknames) for an id >= $DD
    # reads $7D39 (the new species' short names) — every id 0-255, both modes
    res['redirect'] = 0
    for idx in range(256):
        tab = 0x7D39 if idx >= 0xDD else 0x4739
        o = 0x41 * 0x4000 + tab + 2 * idx - 0x4000
        want = rom_text(rom, 0x41, rom[o] | rom[o + 1] << 8)
        for mode, call in (('show', CALL_SHOW), ('copy', CALL_COPY)):
            st.seek(0)
            p.load_state(st)
            ok = run_stub(p, 0x41, 0x4739, idx, call)
            m = p.memory
            if mode == 'show':
                got = rom_text(rom, m[0xC824], m[0xC82D] | m[0xC82E] << 8) if ok else None
                exp = want
            else:
                buf = bytes(m[BUF + i] for i in range(64))
                got = buf[:buf.find(b'\xf0') + 1] if ok and b'\xf0' in buf else None
                exp = want[:want.index(0xF0) + 1] if want else None
            if got == exp:
                res['redirect'] += 1
            else:
                res['fails'].append({'text': f'mode 7 nickname {idx}', 'mode': mode,
                                     'want': exp.hex() if exp else None,
                                     'got': got.hex() if got else None})
    p.stop(save=False)
    return res


def summary(res):
    return (f"{res['slots']} slots ({res['edited']} edited): show {res['show_ok']} / "
            f"{res['slots']}, copy {res['copy_ok']} / {res['slots']}; the nickname "
            f"redirect {res.get('redirect', 0)} / 512; {len(res['fails'])} FAIL")


def negative_rom(rom, cls):
    sy = sym_table(rom)
    data = bytearray(open(rom, 'rb').read())
    off = lambda b, a: b * 0x4000 + (a - 0x4000) if b else a          # noqa: E731
    if cls == 'dir':
        lab = next(k for k in sy if re.fullmatch(r'TextOvrDir_T[0-9A-F]{2}', k))
        b, a = sy[lab]
        data[off(b, a) + 1] = (data[off(b, a) + 1] + 1) & 0xFF
    else:
        b, a = sy['SaveBankAndSwitchCopy']
        assert data[off(b, a):off(b, a) + 2] == bytes([0x3E, 0x01])
        data[off(b, a) + 1] = 0x00
    tmp = tempfile.mkdtemp()
    out = os.path.join(tmp, 'negative.gbc')
    open(out, 'wb').write(data)
    shutil.copy(os.path.join(os.path.dirname(rom), 'game.sym'), tmp)
    return out


# --------------------------------------------------------------------------- selftest
def codec_check():
    """Every original text reads back through the markup codec (both styles)."""
    d = json.load(open(os.path.join(REPO, 'extracted', 'dialogue.json')))
    n = bad = 0
    for e in d['text_ids'] + d['table_entries']:
        if not e.get('raw'):
            continue
        raw = bytes.fromhex(e['raw'])
        for style in TM.STYLES:
            n += 1
            try:
                if TM.encode(TM.decode(raw, style), style) != raw:
                    bad += 1
            except TM.MarkupError:
                bad += 1
    return n, bad


def selftest():
    n, bad = codec_check()
    if bad:
        print(f'FAIL: the markup codec loses {bad} of {n} original texts (textmark.py)')
        return 1
    msg = f'OK: the markup codec reads back all {n // 2} original texts (both styles)'
    if os.path.exists(OUT):
        res = json.load(open(OUT))
        if res.get('fails') or res.get('show_ok') != res.get('slots') or \
                res.get('copy_ok') != res.get('slots') or res.get('redirect') != 512:
            print(f'FAIL: {OUT}: {summary(res)}')
            return 1
        msg += f'; census {summary(res)}'
    print(msg)
    return 0


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--make')
    ap.add_argument('--base', default=os.path.join(REPO, 'editor2', 'example-project'))
    ap.add_argument('--project')
    ap.add_argument('--rom')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args(argv)
    if a.selftest:
        return selftest()
    if a.make:
        make_project(a.make, a.base)
        return 0
    if not a.project:
        ap.error('--project, --make or --selftest')
    rom = a.rom or os.path.join(a.project, 'build', 'build', 'rom.gbc')
    if a.negative:
        rc = 0
        for cls in ('dir', 'copy'):
            res = census(a.project, negative_rom(rom, cls), quiet=True, max_fails=20)
            print(f'NEGATIVE {cls}: {summary(res)}')
            if not res['fails']:
                print(f'  ERROR: the {cls} poke went unnoticed')
                rc = 1
        return rc
    res = census(a.project, rom)
    print(summary(res))
    for f in res['fails'][:20]:
        print('  FAIL', f)
    json.dump({'_generator': 'tools/census_text_override.py (S150): every text slot of '
               'extracted/dialogue.json stub-called through ROM0 CallTextEngine / '
               'RunTextHandler in PyBoy on a build of ' + os.path.basename(os.path.abspath(a.project)),
               **res},
              open(a.out, 'w'), indent=1)
    return 1 if res['fails'] else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
