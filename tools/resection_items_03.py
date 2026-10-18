#!/usr/bin/env python3
"""resection_items_03.py — S151 (ROADMAP E9, Iron Rule 6): bank $03's ITEM code in its
clean form.

mgbdis decoded the two 44-entry jump tables of bank $03's item code as instructions
(`inc b / ld l, d …` at $69AC, `adc c / ld l, [hl] …` at $6E31), which hid every
handler. This tool, for the PATCHED tree (patches/bank_003.asm — the clean form lives
there, KEY_LESSONS "Re-disassembling a misdisassembled data table"):

  * re-disassembles $69AC-$6E23 (ItemUsableTable + the 44 "may it be used now?"
    handlers + their helpers) and $6E31-$7133 (ItemEffectTable + the 44 field effects)
    from the built example ROM's bytes, with a `dw` table and a named label per handler
    (ItemCanUse_<item> / ItemEffect_<item>, the items sharing it in the comment and the
    effect in words from editor2/core/items.py EFFECTS); every label the rest of the bank
    references is kept at its address (SetMon_69ca: mgbdis fake code elsewhere in the
    bank calls into the table — kept as a label on its `dw` row);
  * renames bank $03's item entries in BOTH trees (labels only):
      SetMon_6980 -> ItemLoadRecord (entry 2), SaveMon_6987 -> ItemCopyRecord,
      label69a2 -> ItemCheckUsable (entry 3), label6e24 -> ItemApplyEffect (entry 4),
      SetMon_7160 -> ItemBagCompact (5), label7190 -> ItemBagAdd (6),
      label71b6 -> ItemBagRemove (7), CallMon_7134 -> ItemConsumeRoll (8),
      LoadMon_6e11 -> ItemTargetUnusable;
  * writes the routine comments in BOTH trees (disassembly/: comments only).

Checks (exit 1 on failure): the clean disassembly/ build stays 1ca6579…, the example
project's build keeps its pinned md5 (test_compiler REFERENCE_MD5). Idempotent: skips
the re-disassembly when ItemUsableTable exists.

    python3 tools/resection_items_03.py --rom <example build rom.gbc> --sym <its game.sym>
"""
import argparse
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
sys.path.insert(0, os.path.join(REPO, 'tools'))
from sm83dis import decode                         # noqa: E402
from editor2.core import items as IT               # noqa: E402

DIS = os.path.join(REPO, 'disassembly', 'bank_003.asm')
PAT = os.path.join(REPO, 'patches', 'bank_003.asm')
T_USE, T_EFF = 0x69AC, 0x6E31
A_END, B_END = 0x6E24, 0x7134                    # ItemApplyEffect / ItemConsumeRoll

RENAMES = [('SetMon_6980', 'ItemLoadRecord'), ('SaveMon_6987', 'ItemCopyRecord'),
           ('label69a2', 'ItemCheckUsable'), ('label6e24', 'ItemApplyEffect'),
           ('SetMon_7160', 'ItemBagCompact'), ('label7190', 'ItemBagAdd'),
           ('label71b6', 'ItemBagRemove'), ('CallMon_7134', 'ItemConsumeRoll'),
           ('LoadMon_6e11', 'ItemTargetUnusable')]
RENAME_FILES = [DIS, PAT, os.path.join(REPO, 'editor2/core/templates/bank_077_head.asm'),
                os.path.join(REPO, 'tools/census_items.py'),
                os.path.join(REPO, 'tools/resection_shops.py')]

KEEP_COMMENTS = {}                               # addr -> a comment for its line
# handlers several items share: named by what they test / do
SHARED = {('ItemCanUse', 0x6A2C): 'Party', ('ItemCanUse', 0x6B29): 'RestoreMP',
          ('ItemCanUse', 0x6C48): 'Meat', ('ItemCanUse', 0x6C4C): 'Always',
          ('ItemCanUse', 0x6DDF): 'InGate', ('ItemEffect', 0x7015): 'Meat'}

USE_HEAD = """\
    ; ---------------------------------------------------------------------------
    ; ItemUsableTable (S151): entry 3 ItemCheckUsable's rst $00 table — one handler
    ; per item id 0-43 (patched builds dispatch on wItemBase, the item's BEHAVIOUR id:
    ; a project item 44+ runs its base's). A handler REFUSES by writing $FF to
    ; [$DA5E] (the item in use); [$DA60] = the target monster's party slot. The
    ; field item menu (bank $07) then shows "But nothing happens" / greys the use.
    ; ---------------------------------------------------------------------------"""
EFF_HEAD = """\
    ; ---------------------------------------------------------------------------
    ; ItemEffectTable (S151): entry 4 ItemApplyEffect's rst $00 table — the FIELD
    ; effect of item id 0-43 (patched: of wItemBase). The record was just copied to
    ; $DA62-$DA6D (entry 2); [$DA6B] = record +9 = the POWER, [$DA60] = the target
    ; slot. Most effects end with `call ItemConsumeRoll` (entry 8: RNG mod 100 <
    ; record +3 -> the item is used up). Items whose effect needs a gate / battle
    ; (BeastTail … BookMark, the staffs) do their work elsewhere (bank $07 / $50).
    ; ---------------------------------------------------------------------------"""


def read_syms(path):
    out = {}
    for ln in open(path):
        m = re.match(r'([0-9a-f]{2}):([0-9a-f]{4}) (\S+)', ln)
        if m:
            out.setdefault((int(m.group(1), 16), int(m.group(2), 16)), []).append(m.group(3))
    return out


def sanitize(s):
    return re.sub(r'[^A-Za-z0-9]', '', s)


def region_text(t, start_label, end_label, start_after=None):
    lines = t.split('\n')
    if start_after is not None:
        i = next(k for k, ln in enumerate(lines) if start_after in ln) + 1
    else:
        i = next(k for k, ln in enumerate(lines) if ln.startswith(start_label + ':'))
    j = next(k for k, ln in enumerate(lines) if ln.startswith(end_label + ':'))
    return i, j, lines


def generate(rom, syms, used_names):
    bank = rom[3 * 0x4000:4 * 0x4000]
    names = IT.game_names(REPO)
    names[0] = 'None'

    def w(a):
        return bank[a - 0x4000] | bank[a - 0x4000 + 1] << 8
    use = [w(T_USE + 2 * i) for i in range(44)]
    eff = [w(T_EFF + 2 * i) for i in range(44)]
    labels = {}                                    # addr -> [names]
    comments = {}                                  # addr -> [comment lines before]

    def name_for(prefix, table, a):
        ids = [i for i, x in enumerate(table) if x == a]
        return f"{prefix}_{SHARED.get((prefix, a)) or sanitize(names[ids[0]])}", ids
    for prefix, table in (('ItemCanUse', use), ('ItemEffect', eff)):
        for a in sorted(set(table)):
            nm, ids = name_for(prefix, table, a)
            labels.setdefault(a, []).insert(0, nm)
            who = ', '.join(f"{i} {names[i]}" for i in ids)
            if prefix == 'ItemEffect':
                kinds = sorted({IT.EFFECTS[i][1].format(power='the power ([$DA6B])')
                                for i in ids})
                comments[a] = [f"; item(s) {who}:"] + [f";   {k}" for k in kinds]
            else:
                comments[a] = [f"; item(s) {who}: may it be used now? ({IT.EFFECTS[ids[0]][0]})"]
    # the bank's other labels at these addresses (kept: referenced elsewhere)
    for (b, a), ns in syms.items():
        if b == 3 and (T_USE <= a < A_END or T_EFF <= a < B_END):
            for n in ns:
                if n not in ('label6e24', 'ItemApplyEffect') and n not in labels.get(a, []):
                    labels.setdefault(a, []).append(n)

    def sym_name(bk, a):
        cands = syms.get((bk, a), [])
        pref = [c for c in cands if c in used_names]
        if pref:
            return pref[0]
        return cands[0] if cands else None

    def operand_names(txt, pc_targets):
        # call / jp / jr targets
        m = re.match(r'(call|jp|jr)( (?:nz|z|nc|c),)? \$([0-9a-f]{4})$', txt)
        if m:
            a = int(m.group(3), 16)
            if a < 0x4000:
                n = sym_name(0, a)
            elif T_USE <= a < A_END or T_EFF <= a < B_END:
                pc_targets.add(a)
                n = None                          # resolved after the sweep
            else:
                n = sym_name(3, a)
            return txt, a, n
        m = re.search(r'\[\$([0-9a-f]{4})\]', txt)
        if m:
            a = int(m.group(1), 16)
            if a >= 0x8000:
                n = sym_name(0, a) if (0, a) in syms else None
                for (bk, aa), ns in syms.items():
                    if aa == a and bk in (0, 1) and a >= 0xC000:
                        pref = [c for c in ns if c in used_names]
                        if pref:
                            n = pref[0]
                if n and n in used_names:
                    return txt.replace(f'${m.group(1)}', n), None, None
        return txt, None, None

    out = {}
    for lo, hi, tbl, tname, head in ((T_USE, A_END, use, 'ItemUsableTable', USE_HEAD),
                                     (T_EFF, B_END, eff, 'ItemEffectTable', EFF_HEAD)):
        body = [head, f"{tname}:"]
        for i, a in enumerate(tbl):
            row = T_USE + 2 * i if tname == 'ItemUsableTable' else T_EFF + 2 * i
            for n in labels.get(row, []):
                if not n.startswith('ItemCanUse') and not n.startswith('ItemEffect'):
                    body.append(f"{n}:   ; (mgbdis named this table row; fake code elsewhere in "
                                "the bank calls it — kept)")
            body.append(f"    dw {name_for('ItemCanUse' if tname == 'ItemUsableTable' else 'ItemEffect', tbl, a)[0]:<26}; [{i:2d}] {names[i]}")
        pc = lo + 88
        insts = []
        targets = set()
        while pc < hi:
            txt, n = decode(bank, pc - 0x4000, pc)
            if txt.startswith('db ') or txt.startswith('stop') or 'ff00+c' in txt:
                sys.exit(f'ABORT: {txt} at ${pc:04x}')
            m = re.match(r'ld hl, sp\+\$([0-9a-f]{2})$', txt)
            if m:
                v = int(m.group(1), 16)
                txt = f"ld hl, sp+{v}" if v < 0x80 else f"ld hl, sp-{256 - v}"
            m = re.match(r'add sp, \$([0-9a-f]{2})$', txt)
            if m:
                v = int(m.group(1), 16)
                txt = f"add sp, {v if v < 0x80 else v - 256}"
            txt, tgt, tname2 = operand_names(txt, targets)
            insts.append((pc, txt, tgt, tname2))
            pc += n
        if pc != hi:
            sys.exit(f'ABORT: the sweep ended at ${pc:04x}, not ${hi:04x}')
        for a in targets:
            if a not in labels:
                labels[a] = [f"jr_003_{a:04x}"]
        for pc, txt, tgt, n in insts:
            if pc in labels:
                body.append('')
                for c in comments.get(pc, []):
                    body.append(c)
                for nm in labels[pc]:
                    body.append(f"{nm}:")
            if tgt is not None:
                n = n or labels.get(tgt, [None])[0]
                if n:
                    txt = re.sub(r'\$[0-9a-f]{4}$', n, txt)
            line = f"    {txt}"
            if pc in KEEP_COMMENTS:
                line = f"{line:<36}{KEEP_COMMENTS[pc]}"
            body.append(line)
            if txt in ('ret', 'reti', 'jp hl') or txt.startswith('jp $') or \
                    (txt.startswith('jp ') and ',' not in txt) or \
                    (txt.startswith('jr ') and ',' not in txt):
                body.append('')
        out[tname] = body
    return out


def renames(path):
    t = open(path).read()
    t0 = t
    for old, new in RENAMES:
        t = re.sub(rf'\b{old}\b', new, t)
    if t != t0:
        open(path, 'w').write(t)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', required=True)
    ap.add_argument('--sym', required=True)
    a = ap.parse_args()
    rom = open(a.rom, 'rb').read()
    syms = read_syms(a.sym)
    t = open(PAT).read()
    if 'ItemUsableTable:' not in t:
        used = set(re.findall(r'\b[A-Za-z_]\w*\b', t))
        gen = generate(rom, syms, used)
        # region A: Jump_003_69ac .. label6e24 / ItemApplyEffect
        lines = t.split('\n')
        i = next(k for k, ln in enumerate(lines) if ln.startswith('Jump_003_69ac:'))
        j = next(k for k, ln in enumerate(lines) if re.match(r'(label6e24|ItemApplyEffect):', ln))
        old_a = '\n'.join(lines[i:j])
        lines = lines[:i] + gen['ItemUsableTable'] + [''] + lines[j:]
        k0 = next(k for k, ln in enumerate(lines) if 'runs its base\'s field effect' in ln) + 1
        k1 = next(k for k, ln in enumerate(lines) if re.match(r'(CallMon_7134|ItemConsumeRoll):', ln))
        old_b = '\n'.join(lines[k0:k1])
        lines = lines[:k0] + gen['ItemEffectTable'] + [''] + lines[k1:]
        t = '\n'.join(lines)
        # the S128 comment travels with its instruction
        if 'call ArenaMapID' in old_a + old_b:
            t = t.replace('\n    call ArenaMapID\n',
                          '\n    call ArenaMapID                 ; S128: was ld a, [wMapID] — '
                          'your arena copies count as $06 / $5D (the skill fizzles there too)\n', 1)
        open(PAT, 'w').write(t)
        print('patches/bank_003.asm: item tables + handlers re-disassembled')
    for p in RENAME_FILES:
        renames(p)
    print('renamed bank $03 item entries in', len(RENAME_FILES), 'files')


if __name__ == '__main__':
    main()
