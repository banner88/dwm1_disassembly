#!/usr/bin/env python3
"""annotate_text_slots.py — S150 (ROADMAP P3.6 / Phase F; Iron Rule 6): name every
text POINTER SLOT in the text banks' head tables, comments only.

Most text banks open with a block mgbdis called a "Cross-bank dispatch table
(N entries)": `dw $XXXX ; Entry N` lines from $4001. Only the first words are
far-call entries (the bank's show / copy routines); the rest are the bank's MODE
LIST (the words SaveBankAndSwitch's level 1 reads at DE + 2 * mode) and its
per-id TABLES (level 2: table + 2 * id = the slot a text is read through). This
tool appends to each such line what it is, from the MEASURED data:

  * a text id's slot (extracted/dialogue.json `table` / `index`, hooked in PyBoy —
    tools/dump_dialogue.py):        `; Entry 4 — text $0000 "Milayou:Terry! Wait! …"`
  * a table row's slot (the tables of dialogue.json): `— battle_message #3 "…"`
  * a mode-list word (DE of the bank's `ld de, nn / call CallTextEngine`):
                                    `— mode 2 -> table $423B`
  * an entry routine:               `— entry 0: show [$C822] / [$C823] …`

Comments only (the clean build stays 1ca6579…; the patched build's md5 is
unchanged). Idempotent: an `Entry N` line's tail after "Entry N" is rewritten.
Runs over disassembly/ and the same banks in patches/ (when present).

  python3 tools/annotate_text_slots.py            # rewrite in place
  python3 tools/annotate_text_slots.py --check    # exit 1 when a file would change (= --selftest, verify check 5)
"""
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
LINE = re.compile(r'^(\s*dw\s+[^;\s]+)(\s*;\s*Entry (\d+))(.*)$')


def preview(text, n=34):
    t = ' '.join((text or '').replace('▼', ' ').split())
    t = t.replace('"', "'")
    return t if len(t) <= n else t[:n - 1] + '…'


def slots():
    """{bank: {addr: [what, …]}} from dialogue.json + the mode lists from the ROM."""
    d = json.load(open(os.path.join(REPO, 'extracted', 'dialogue.json'), encoding='utf-8'))
    out = {}
    first = {}
    for e in d['text_ids']:
        b, t = int(e['bank'][1:], 16), int(e['table'][1:], 16)
        a = t + 2 * e['index']
        out.setdefault(b, {}).setdefault(a, []).append(f"text {e['id']} \"{preview(e['text'])}\"")
        first.setdefault((b, t), None)
    titles = {t['source']: t for t in d['tables']}
    for e in d['table_entries']:
        b, t = int(e['bank'][1:], 16), int(e['table'][1:], 16)
        a = t + 2 * e['index']
        out.setdefault(b, {}).setdefault(a, []).append(f"{e['source']} #{e['index']} \"{preview(e['text'])}\"")
    rom = open(ROM, 'rb').read()
    for b in sorted(out):
        base = b * 0x4000
        # the bank's mode lists: every `ld de, nn / call CallTextEngine (or RunTextHandler)`
        cfgs = set()
        for m in re.finditer(rb'\x11(..)\xcd(\xb6|\xf6)\x05', rom[base:base + 0x4000], re.S):
            cfgs.add(m.group(1)[0] | m.group(1)[1] << 8)
        tables = {t for (bb, t) in [(int(e['bank'][1:], 16), int(e['table'][1:], 16))
                                     for e in d['text_ids'] + d['table_entries']] if bb == b}
        for c in cfgs:
            for mode in range(16):
                a = c + 2 * mode
                if not 0x4000 <= a < 0x8000:
                    break
                w = rom[base + a - 0x4000] | rom[base + a - 0x3FFF] << 8
                if w not in tables:
                    continue
                out[b].setdefault(a, []).insert(0, f"mode {mode} -> table ${w:04X} (mode list ${c:04X})")
        for t in tables:
            lst = out[b].get(t)
            if lst is not None and not lst[0].startswith('['):
                lst.insert(0, f"[table ${t:04X}]")
    return out


def annotate(path, bank, marks):
    lines = open(path, encoding='utf-8').read().split('\n')
    changed = 0
    for i, ln in enumerate(lines):
        m = LINE.match(ln)
        if not m:
            continue
        n = int(m.group(3))
        addr = 0x4001 + 2 * n
        what = marks.get(addr)
        if not what:
            continue
        new = f"{m.group(1)}{m.group(2)} — " + '; '.join(what)
        if new != ln:
            lines[i] = new
            changed += 1
    return '\n'.join(lines), changed


def main():
    check = '--check' in sys.argv or '--selftest' in sys.argv
    marks = slots()
    total = 0
    stale = []
    for b, mk in sorted(marks.items()):
        for tree in ('disassembly', 'patches'):
            p = os.path.join(REPO, tree, f'bank_{b:03x}.asm')
            if not os.path.exists(p):
                continue
            text, n = annotate(p, b, mk)
            if n:
                if check:
                    stale.append(p)
                else:
                    open(p, 'w', encoding='utf-8').write(text)
                total += n
    if check:
        if stale:
            print(f'FAIL: {len(stale)} file(s) lack the text-slot comments: {stale[:4]} — run '
                  'tools/annotate_text_slots.py')
            return 1
        print('OK: every head-table text slot carries its comment')
        return 0
    print(f'annotated {total} lines')
    return 0


if __name__ == '__main__':
    sys.exit(main())
