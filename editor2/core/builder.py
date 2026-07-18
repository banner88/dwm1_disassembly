"""builder.py — stage → rgbasm → ROM + manifest, always restoring the tree.

Uses the SAME staging mechanism as tools/verify_integrity.py check 2 (the
PATCH_FILES / PATCH_NEW_FILES lists are parsed from that script so there is
one source of truth): copy patches/ over disassembly/, overlay the
compiler's generated files, `make`, capture game.gbc + game.sym, restore.

The manifest (EDITOR_DESIGN §6) is the debugging bridge: it maps generated
content back to addresses so a SameBoy break can be traced to the
project.json field that produced the bytes.
"""

import hashlib
import json
import os
import re
import shutil
import subprocess

BUILD_ARTIFACTS = ['game.o', 'game.gbc', 'game.sym', 'game.map']


def _patch_lists(repo):
    src = open(os.path.join(repo, 'tools/verify_integrity.py')).read()
    pf = re.search(r'PATCH_FILES\s*=\s*\[(.*?)\]', src, re.S).group(1)
    pnf = re.search(r'PATCH_NEW_FILES\s*=\s*\[(.*?)\]', src, re.S).group(1)
    return (re.findall(r'"([^"]+)"', pf), re.findall(r'"([^"]+)"', pnf))


def md5(path_or_bytes):
    data = (path_or_bytes if isinstance(path_or_bytes, bytes)
            else open(path_or_bytes, 'rb').read())
    return hashlib.md5(data).hexdigest()


def build_rom(repo, generated_dir, out_dir):
    """Stage patches + generated over disassembly/, build, capture, restore.
    Returns (rom_path, sym_path, rom_md5)."""
    dis = os.path.join(repo, 'disassembly')
    patches = os.path.join(repo, 'patches')
    patch_files, patch_new = _patch_lists(repo)

    backups = {}
    for f in patch_files:
        p = os.path.join(dis, f)
        backups[f] = open(p, 'rb').read() if os.path.exists(p) else None
    try:
        # 1. the proven hand-authored overlay
        for f in patch_files + patch_new:
            p = os.path.join(patches, f)
            if os.path.exists(p):
                shutil.copy(p, os.path.join(dis, f))
        # 2. the compiler's generated files layered on top
        gen_patches = os.path.join(generated_dir, 'patches')
        if os.path.isdir(gen_patches):
            for f in sorted(os.listdir(gen_patches)):
                shutil.copy(os.path.join(gen_patches, f),
                            os.path.join(dis, f))
        r = subprocess.run(['make'], cwd=dis, capture_output=True, text=True)
        if r.returncode != 0:
            tail = "\n".join((r.stdout + r.stderr).splitlines()[-25:])
            raise RuntimeError(f"build failed:\n{tail}")
        os.makedirs(out_dir, exist_ok=True)
        rom_path = os.path.join(out_dir, 'rom.gbc')
        sym_path = os.path.join(out_dir, 'game.sym')
        shutil.copy(os.path.join(dis, 'game.gbc'), rom_path)
        shutil.copy(os.path.join(dis, 'game.sym'), sym_path)
        return rom_path, sym_path, md5(rom_path)
    finally:
        for f, data in backups.items():
            if data is not None:
                open(os.path.join(dis, f), 'wb').write(data)
        for f in patch_new:
            p = os.path.join(dis, f)
            if os.path.exists(p):
                os.remove(p)
        for a in BUILD_ARTIFACTS:
            p = os.path.join(dis, a)
            if os.path.exists(p):
                os.remove(p)


def parse_sym(sym_path):
    """game.sym → {symbol: (bank, addr)}."""
    out = {}
    for line in open(sym_path):
        m = re.match(r'([0-9A-Fa-f]{2,3}):([0-9A-Fa-f]{4})\s+(\S+)', line)
        if m:
            out[m.group(3)] = (int(m.group(1), 16), int(m.group(2), 16))
    return out


def bank_usage(rom_path, bank):
    data = open(rom_path, 'rb').read()
    chunk = data[bank * 0x4000:(bank + 1) * 0x4000]
    last = max((i for i, b in enumerate(chunk) if b), default=-1)
    return last + 1


def write_manifest(out_dir, prj, project_path, rom_path, sym_path, rom_md5,
                   compiler_warnings):
    from . import compiler as C
    syms = parse_sym(sym_path)
    owned = {}
    for name, (bank, addr) in syms.items():
        if bank in (0x60, 0x71) or name.startswith('wCustomStep_') or \
                name.startswith('CustomRoomPal') or \
                name.startswith('CustomRoomAttr') or \
                name.startswith('CustomPaletteColors'):
            owned[name] = f"{bank:02x}:{addr:04x}"
    texts = {}
    for tid in sorted(prj._text_by_id):
        lbl = prj.text_label(tid)
        loc = owned.get(lbl)
        e = prj._text_by_id[tid]
        texts[f"${tid:04X}"] = {"label": lbl, "addr": loc,
                                "id": e.get('id', '')}
    # script bodies: collect straight from the sym table (labels contain _Scr)
    scripts = {n: a for n, a in owned.items() if '_Scr' in n}
    manifest = {
        "project": os.path.abspath(project_path),
        "project_sha256": C.content_hash(project_path),
        "rom_md5": rom_md5,
        "bank_usage": {f"${b:02X}": bank_usage(rom_path, b)
                       for b in (0x60, 0x71, 0x74)},
        "music": {sid: f"${fid:02X}"
                  for sid, fid in (prj.music_song_ids().items()
                                   if prj.custom.get('music') else [])},
        "texts": texts,
        "scripts": scripts,
        "flags": {k: f"${v:04X}" for k, v in prj.flag_map().items()},
        "step_counters": {lbl: f"${addr:04X}"
                          for lbl, addr, _ in prj.step_counter_allocation()},
        "symbols": owned,
        "warnings": compiler_warnings,
    }
    path = os.path.join(out_dir, 'manifest.json')
    with open(path, 'w') as f:
        json.dump(manifest, f, indent=2, sort_keys=True)
    return path
