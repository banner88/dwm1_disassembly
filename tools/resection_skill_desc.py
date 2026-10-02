#!/usr/bin/env python3
"""
resection_skill_desc.py — bank $56: the SKIL-menu skill DESCRIPTIONS and
their tables as labelled data. S110, ROADMAP P3.11 (Iron Rule 6: the block
was mgbdis raw `db` + fake code in both trees).

WHAT (ROM-verified S110; BATTLE_SKILL_SYSTEM §14.1 "Skill DESCRIPTIONS"):
  * `$56:$502F-$664A` = the description strings, `$F0`-terminated, in skill-id
    order with two SHARED empties: `$6599` (ids 151-212 = the internal battle
    actions + the battle items) and `$664A` (ids 219-255). Ids 0-150 and
    213-218 own one string each (<= 3 lines of <= 18 cells, `$F1` = next line).
  * `$664B` = SkillDescModeTable (2 dw, `ld de, $664b` in SetB56_4901 and its
    RunTextHandler twin): mode 0 -> `$664F` = SkillDebugTextPtrs (12 dw, the
    debug menu's strings at `$4E4C-$502E`), mode 1 -> `$6667` =
    SkillDescPtrTable (256 dw by skill id).
  * Strings become `SkillDesc_NNN_<Name>:` (the two shared empties
    `SkillDesc_Blank` / `SkillDesc_None`), the tables `dw` rows of labels,
    the two `ld de, $664b` become `ld de, SkillDescModeTable`.

  Region bounds: the clean tree's lines were mapped to addresses by a probe
  build (a global label before every line, S110): the block is the 868 lines
  after the `;@TEXT Skill descriptions` marker up to the line before the one
  at $6867. The patched tree's region is the same block with the [S73]/[S74]/
  [S75] `dw SkillDescPtr_E0..E9` rows standing for pairs of fake
  `ld c, d / ld h, [hl]` lines; its end is found by the clean tree's tail
  (KEY_LESSONS S109: map by the shared tail, never search an instruction).

  Labels/comments only: the clean build must stay 1ca6579…. The patched tree
  also gets the compiler region markers (byte-neutral comments):
  gd_skill_desc (the strings), gd_skill_desc_ptrs (table rows 0-221) and the
  fixed-size gd_skill_desc_extra over the bank's free nop pad (PROJECT_COMPILER
  §2.26).

USAGE
  python3 tools/resection_skill_desc.py            # plan (counts, no write)
  python3 tools/resection_skill_desc.py --apply    # both trees + clean build md5 check
"""
import glob
import hashlib
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'
BANK = 0x56
BLOCK_START, BLOCK_END = 0x502F, 0x664B          # strings [start, end)
MODE_TABLE, DEBUG_PTRS, DESC_PTRS = 0x664B, 0x664F, 0x6667
REGION_END = 0x6867                              # first byte after the 256 dw
BLANK, NONE = 0x6599, 0x664A
N_IDS = 222                                      # vanilla skill ids with records
CLEAN_FIRST_LINE = 2845                          # 1-based, = $502F (probe build)
CLEAN_LAST_LINE = 3712                           # 1-based, its last byte = $6866
PAD_NOPS_PATCHED = 2993                          # the patched tree's free pad run


def rom():
    return open(ROM, 'rb').read()


def word(R, bank, addr):
    o = bank * 0x4000 + addr - 0x4000
    return R[o] | R[o + 1] << 8


def string(R, addr):
    o = BANK * 0x4000 + addr - 0x4000
    e = R.index(b'\xf0', o)
    return R[o:e + 1]


def skill_names(R):
    from dwm.text import TABLE
    out = []
    for i in range(256):
        p = word(R, 0x41, 0x4539 + 2 * i)
        q = 0x41 * 0x4000 + p - 0x4000
        e = R.index(b'\xf0', q)
        out.append(''.join(TABLE.get(b, '') for b in R[q:e]))
    return out


def decode(bs):
    from editor2.core import monster_text as MT
    return MT.decode(bs).replace('\n', '/')


def tag(name):
    return re.sub(r'[^A-Za-z0-9]', '', name) or 'X'


def plan(R):
    """-> (strings [(addr, label, bytes)], ptr_labels [256], debug [12 words])"""
    names = skill_names(R)
    ptrs = [word(R, BANK, DESC_PTRS + 2 * i) for i in range(256)]
    if word(R, BANK, MODE_TABLE) != DEBUG_PTRS or word(R, BANK, MODE_TABLE + 2) != DESC_PTRS:
        raise SystemExit('mode table at $664B is not [$664F, $6667]')
    owner = {}
    for i, p in enumerate(ptrs):
        owner.setdefault(p, i)
    strings, a = [], BLOCK_START
    for p in sorted(owner):
        if p != a:
            raise SystemExit(f'string ${p:04X} is not contiguous (expected ${a:04X})')
        s = string(R, p)
        if p == BLANK:
            lab = 'SkillDesc_Blank'
        elif p == NONE:
            lab = 'SkillDesc_None'
        else:
            i = owner[p]
            lab = f'SkillDesc_{i:03d}_{tag(names[i])}'
        strings.append((p, lab, s))
        a += len(s)
    if a != BLOCK_END:
        raise SystemExit(f'strings end at ${a:04X}, expected ${BLOCK_END:04X}')
    by_addr = {p: lab for p, lab, _s in strings}
    for i in range(N_IDS):
        if ptrs[i] not in by_addr:
            raise SystemExit(f'skill {i}: pointer ${ptrs[i]:04X} outside the block')
    labels = [by_addr.get(p) for p in ptrs]
    debug = [word(R, BANK, DEBUG_PTRS + 2 * k) for k in range(12)]
    return strings, labels, debug, names


def block_text(strings, labels, debug, names, patched_rows=None, markers=False):
    """patched_rows: {id: the hand `dw SkillDescPtr_..` line} kept as-is."""
    out = ['; ' + '=' * 77,
           '; SKILL DESCRIPTIONS ($502F-$664A) — the SKIL-menu info box, text mode 1 of',
           '; SkillDescModeTable. One string per skill id 0-150 / 213-218 (<= 3 lines of',
           '; <= 18 cells, $F1 = next line, $F0 = end); ids 151-212 (internal battle',
           '; actions + battle items) share SkillDesc_Blank, ids 219-255 SkillDesc_None.',
           '; S110 re-section (tools/resection_skill_desc.py; was raw db + mgbdis fake',
           '; code); bytes unchanged. Patched tree: compiler regions gd_skill_desc /',
           '; gd_skill_desc_ptrs (gamedata.skills.<id>.description, PROJECT_COMPILER',
           '; §2.26; BATTLE_SKILL_SYSTEM §14.1).',
           '; ' + '=' * 77]
    if markers:
        out.append('; @BUILD_PROJECT BEGIN gd_skill_desc')
    out.append('SkillDescStrings:')
    for p, lab, s in strings:
        out.append(f'{lab}:  ; ${p:04X} "{decode(s)}"')
        out.append('    db ' + ', '.join(f'${b:02X}' for b in s))
    if markers:
        out.append('; @BUILD_PROJECT END gd_skill_desc')
    out += ['SkillDescModeTable:  ; $664B — `ld de, SkillDescModeTable` + CallTextEngine /',
            ';   RunTextHandler (SetB56_4901): text mode 0 = the debug menu strings,',
            ';   mode 1 = the skill descriptions (index = skill id)',
            '    dw SkillDebugTextPtrs, SkillDescPtrTable',
            'SkillDebugTextPtrs:  ; $664F — mode 0: 12 debug-menu strings at $4E4C-$502E',
            ';   ("MESSEGE DEBUG", "TESTMES", ... "INVALID NUMBER!"; left as raw words —',
            ';   their bytes are still mgbdis fake code above)']
    for k in range(0, 12, 6):
        out.append('    dw ' + ', '.join(f'${w:04X}' for w in debug[k:k + 6]))
    out.append('SkillDescPtrTable:  ; $6667 — 256 dw by skill id (mode 1)')
    if markers:
        out.append('; @BUILD_PROJECT BEGIN gd_skill_desc_ptrs')
    for i in range(256):
        if markers and i == N_IDS:
            out.append('; @BUILD_PROJECT END gd_skill_desc_ptrs')
        if patched_rows and i in patched_rows:
            out.append(patched_rows[i])
        else:
            out.append(f'    dw {labels[i]:<28}; [{i:3d}] {names[i] or "-"}')
    return out


def _clean_tail(L):
    """The clean tree's lines after the region (the shared tail anchor)."""
    return L[CLEAN_LAST_LINE:]


def apply_tree(path, R, plan_, clean_lines, write):
    strings, labels, debug, names = plan_
    L = open(path).read().split('\n')
    if any(l.startswith('SkillDescStrings:') for l in L):
        print(f'{path}: already re-sectioned')
        return False
    patched = 'patches' in path
    if not patched:
        s, e = CLEAN_FIRST_LINE - 1, CLEAN_LAST_LINE        # [s, e)
        if '@TEXT Skill descriptions' not in L[s - 1]:
            raise SystemExit(f'{path}: line {s} is not the @TEXT marker')
    else:
        s = next(i for i, l in enumerate(L) if '@TEXT Skill descriptions' in l) + 1
        tail = _clean_tail(clean_lines)
        # the region ends where the clean tree's tail (from $6867) begins: the
        # first 40 tail lines are identical in both trees (verified on apply)
        sig = tail[:40]
        e = next(i for i in range(s, len(L)) if L[i:i + 40] == sig)
    labs = [m.group(1) for l in L[s:e] for m in [re.match(r'^([A-Za-z_][\w.]*):', l)] if m]
    rest = '\n'.join(L[:s] + L[e:])
    tree = os.path.dirname(path)
    others = ''.join(open(f).read() for f in glob.glob(os.path.join(tree, '*.asm'))
                     if not f.endswith('bank_056.asm'))
    hand = [x for x in labs if x.startswith('SkillDescPtr_')]
    used = [x for x in labs if x not in hand
            and re.search(r'\b' + re.escape(x) + r'\b', rest + others)]
    if used:
        raise SystemExit(f'{path}: labels inside the region are referenced: {used}')
    rows = None
    if patched:
        rows = {}
        for l in L[s:e]:
            m = re.match(r'\s+dw (SkillDescPtr_E([0-9A-F]))\b', l)
            if m:
                rows[0xE0 + int(m.group(2), 16)] = l
        if sorted(rows) != list(range(0xE0, 0xEA)):
            raise SystemExit(f'{path}: expected the [S73]-[S75] rows $E0-$E9, found '
                             f'{[hex(k) for k in sorted(rows)]}')
    new = block_text(strings, labels, debug, names, rows, markers=patched)
    L = L[:s] + new + L[e:]
    # the two `ld de, $664b` sites
    n = 0
    for k, l in enumerate(L):
        if re.match(r'\s+ld de, \$664b\s*$', l):
            L[k] = l.replace('$664b', 'SkillDescModeTable')
            n += 1
    if n != 2:
        raise SystemExit(f'{path}: found {n} `ld de, $664b`, expected 2')
    if patched:
        L = _extra_region(L)
    print(f'{path}: region lines {s + 1}-{e} ({e - s}) -> {len(strings)} strings + tables; '
          f'{len(labs)} old labels dropped ({len(hand)} hand rows kept); 2 ld de relabelled')
    if write:
        open(path, 'w').write('\n'.join(L))
    return True


def _extra_region(L):
    """Patched tree: the 2,993-nop pad before the [S73] custom descriptions
    becomes the fixed-size region gd_skill_desc_extra (vanilla content = the
    same 2,993 zero bytes as `ds`)."""
    i = 0
    while i < len(L):
        if L[i].strip() == 'nop':
            j = i
            while j < len(L) and L[j].strip() in ('nop', ''):
                j += 1
            n = sum(1 for x in L[i:j] if x.strip() == 'nop')
            if n == PAD_NOPS_PATCHED:
                block = ['; S110: the bank\'s free pad ($7291, 2,993 B) is the compiler region',
                         '; gd_skill_desc_extra — descriptions that no longer fit SkillDescStrings',
                         '; and the own descriptions of skills that share SkillDesc_Blank / _None',
                         '; (PROJECT_COMPILER §2.26); fixed size, so the [S73] strings below keep',
                         '; their addresses. No edits = 2,993 zero bytes (the old nops).',
                         '; @BUILD_PROJECT BEGIN gd_skill_desc_extra',
                         f'    ds {PAD_NOPS_PATCHED}, $00',
                         '; @BUILD_PROJECT END gd_skill_desc_extra']
                return L[:i] + block + L[j:]
            i = j
        else:
            i += 1
    raise SystemExit(f'patched bank_056: no {PAD_NOPS_PATCHED}-nop pad run found')


def clean_md5():
    dis = os.path.join(REPO, 'disassembly')
    for f in ('game.o', 'game.gbc', 'game.sym', 'game.map'):
        try:
            os.remove(os.path.join(dis, f))
        except FileNotFoundError:
            pass
    subprocess.run(['make'], cwd=dis, check=True, capture_output=True)
    m = hashlib.md5(open(os.path.join(dis, 'game.gbc'), 'rb').read()).hexdigest()
    for f in ('game.o', 'game.gbc', 'game.sym', 'game.map'):
        try:
            os.remove(os.path.join(dis, f))
        except FileNotFoundError:
            pass
    return m


def main():
    R = rom()
    p = plan(R)
    write = '--apply' in sys.argv
    clean_path = os.path.join(REPO, 'disassembly', 'bank_056.asm')
    clean_lines = open(clean_path).read().split('\n')
    if any(l.startswith('SkillDescStrings:') for l in clean_lines):
        import subprocess as sp
        clean_lines = sp.run(['git', 'show', 'HEAD:disassembly/bank_056.asm'], cwd=REPO,
                             capture_output=True, text=True, check=True).stdout.split('\n')
    print(f'{len(p[0])} strings, {sum(1 for x in p[1] if x)} table rows')
    for tree in ('disassembly', 'patches'):
        apply_tree(os.path.join(REPO, tree, 'bank_056.asm'), R, p, clean_lines, write)
    if write:
        m = clean_md5()
        print('clean build md5', m, 'OK' if m == ORIGINAL_MD5 else 'MISMATCH')
        if m != ORIGINAL_MD5:
            sys.exit(1)


if __name__ == '__main__':
    main()
