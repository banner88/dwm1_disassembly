#!/usr/bin/env python3
"""refresh_script_text_comments.py — re-write the `; Text $XXXX: "…"` previews
in the script banks $0C-$0F (clean tree) from the MEASURED text-id map
(extracted/dialogue.json, tools/dump_dialogue.py). S108.

Why: the previews were generated (gen_script_banks.py) from the pre-S108
text_id_map.json, which MODELLED the cascade (each bank's pointer table read
at a fixed $400B — bank $42's mode-0 table starts at $4009, so its "id 0" was
the measured id 1 — plus a guessed per-page index rule) and had no entry for
the ids the corpus banks forward to the overflow banks ($1A $1B $1F $21 $22
$3F $18 $4F): only 62 of its 2,061 entries matched the game, so most of the
6,520 previews named the wrong line or none (DOC_AUDIT S108). Also the id lists on bank $47's
TextStr_47_<addr> labels (the S43 T1 re-section took them from the same map).
Comments only: the clean build must stay 1ca6579…

  python3 tools/refresh_script_text_comments.py           # plan (counts)
  python3 tools/refresh_script_text_comments.py --apply   # rewrite + clean build md5 check
"""
import hashlib
import json
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIS = os.path.join(REPO, 'disassembly')
BANKS = ('bank_00c.asm', 'bank_00d.asm', 'bank_00e.asm', 'bank_00f.asm')
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'
PAT = re.compile(r'(; Text \$([0-9A-F]{4}): )"([^"]*)"(\s*)$')
WIDTH = 40


def preview(text):
    t = text.replace(' ▼', '').replace('\n\n', ' // ').replace('\n', ' ')
    t = re.sub(r'\s+', ' ', t).replace('"', "'").strip()
    return t[:WIDTH]


def main():
    d = json.load(open(os.path.join(REPO, 'extracted', 'dialogue.json')))
    texts = {int(e['id'][1:], 16): e for e in d['text_ids']}
    apply = '--apply' in sys.argv
    total = changed = 0
    for name in BANKS:
        path = os.path.join(DIS, name)
        lines = open(path).read().split('\n')
        for k, line in enumerate(lines):
            m = PAT.search(line)
            if not m:
                continue
            total += 1
            tid = int(m.group(2), 16)
            e = texts.get(tid)
            new = (f'{e["bank"]}:{e["addr"]} ' + preview(e['text'])) if e else '(no such id)'
            if m.group(3) != new:
                changed += 1
                lines[k] = line[:m.start()] + m.group(1) + f'"{new}"' + m.group(4)
        if apply:
            open(path, 'w').write('\n'.join(lines))
    print(f'{total} previews, {changed} rewritten')
    # bank $47 (T1 re-section, S43): the TextStr_47_<addr> labels carry the ids
    # that point at each string — from the same faulty map; refresh them too
    by_addr = {}
    for e in d['text_ids']:
        if e['bank'] == '$47':
            by_addr.setdefault(int(e['addr'][1:], 16), []).append(e['id'])
    path = os.path.join(DIS, 'bank_047.asm')
    lines = open(path).read().split('\n')
    n47 = 0
    for k, line in enumerate(lines):
        m = re.match(r'^(TextStr_47_([0-9a-f]{4}):\s*); (id [$0-9A-F ]+|\(region entry / unlisted fragment\))\s*$', line)
        if not m:
            continue
        ids = by_addr.get(int(m.group(2), 16))
        new = ('id ' + ' '.join(ids)) if ids else '(no text id points here: a mid-string fragment)'
        if m.group(3).strip() != new:
            lines[k] = f'{m.group(1)}; {new}'
            n47 += 1
    print(f'bank $47: {n47} TextStr id comments rewritten')
    if apply:
        open(path, 'w').write('\n'.join(lines))
    if apply:
        for f in ('game.o', 'game.gbc', 'game.sym', 'game.map'):
            p = os.path.join(DIS, f)
            if os.path.exists(p):
                os.remove(p)
        subprocess.run(['make'], cwd=DIS, check=True, capture_output=True)
        m5 = hashlib.md5(open(os.path.join(DIS, 'game.gbc'), 'rb').read()).hexdigest()
        print('clean build md5', m5, 'OK' if m5 == ORIGINAL_MD5 else 'MISMATCH')
        return 0 if m5 == ORIGINAL_MD5 else 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
