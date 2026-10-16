#!/usr/bin/env python3
"""recomment_script_banks.py — re-annotate the script data of banks $0C-$0F from
the handler-derived decoder (S148, ROADMAP ARC CAP4 "$3E" box; user: "Do now").

The script data regions of disassembly/bank_00c-00f.asm (from `BankXX_Script
MasterTable:` to the end of the file) were generated in S43 by
tools/gen_script_banks.py on the decompiler's guessed arity table (wrong for 36
opcodes — DOC_AUDIT S96) and its guessed opcode names: about 5,100 parameter words
carried a text preview ("`dw $FF09 ; SetDelay` / `dw $0004 ; Text $0004: "Terry
looked at the bookshelf"`"), many branch targets were bare numbers, and the script
words those targets reach were left as `db` bytes.

This tool rewrites ONLY the annotation of that region (labels kept, bytes
identical — the byte-perfect rebuild is the check):

  * every script of the bank is decoded the way the game runs it
    (`editor2/core/cutscenes.decode_words`: the handler arities of
    extracted/script_param_counts.json, branch targets followed, an op that ENDS
    the script — script_ops.TERMINAL, derived from the handlers — ends the run;
    `$3E` and `$16` yield and continue);
  * a decoded word becomes one `dw` line: an op with its name and what it does
    (`script_ops.sentence`), each parameter with its name, a text id with the
    first words of the text (extracted/dialogue.json, measured), END;
  * a branch-target parameter names its label (an existing one at that address,
    else a new `BankXX_ScriptAddr_XXXX` label);
  * `db` runs that scripts reach become `dw` words; words no script reaches keep
    their bytes with the comment "not reached" (an END after a room change, the
    bytes between scripts);
  * pointer tables, every label and every full-line comment stay where they were;
    an `@BUILD_PROJECT` compiler region (patches/bank_00e.asm, the Milly hook) is
    copied verbatim.

Usage:
  python3 tools/recomment_script_banks.py [--bank 0C] [--file PATH] [--out PATH]
      (default: the four disassembly banks in place)
  python3 tools/recomment_script_banks.py --check     (verify check 5: the files are
      what this tool writes — no stale annotation)
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
sys.path.insert(0, os.path.join(ROOT, 'tools'))

ROM = os.path.join(ROOT, 'data', 'DWM-original.gbc')
SCRIPT_TBL = 0x41BA
BANKS = {0x0C: (0x00, 0x06), 0x0D: (0x06, 0x20), 0x0E: (0x20, 0x40), 0x0F: (0x40, 0x71)}
FILES = {b: os.path.join(ROOT, 'disassembly', f'bank_{b:03x}.asm') for b in BANKS}

LINE_DATA = re.compile(r'^\s*(dw|db)\s+([^;]+?)\s*(;.*)?$')
LINE_LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)(::?)\s*(;.*)?$')


SEP = ' ‖ '        # generated comment ‖ a hand-written one kept from the old line


def hand_comment(comment):
    """The hand-written part of a data line's comment (None = all generated:
    the S43 generator's styles or this tool's)."""
    if not comment:
        return None
    c = comment.lstrip(';').strip()
    if SEP.strip() in c:
        return c.split(SEP.strip(), 1)[1].strip() or None
    if re.match(r'^(Text \$|RAM \$|-> branch target|END\b|Cmd\$?[0-9A-F]{2}$|\[\d+\]|'
                r'script \d+$|Flag \$|\$[0-9A-F]{2} [a-z0-9_]+:|text \$|not reached|END — not|'
                r'map type \$[0-9A-F]{2}: |tile patch \(op|'
                r'[a-z_]+$)', c):
        return None
    try:
        from gen_script_banks import OPCODE_NAMES          # the S43 names
    except Exception:                                    # noqa: BLE001
        OPCODE_NAMES = {}
    if c in set(OPCODE_NAMES.values()):
        return None
    # an old mnemonic restating the step ("npc_moveto npc#0, $00E8", "value 1",
    # "close_text (op $06)") says nothing the decoder does not: only prose stays
    if re.match(r'^\w+ \(op \$[0-9A-F]{2}\)$', c):
        return None
    if not ('(' in c or '<<<' in c or '—' in c or re.search(r'=\s*[A-Za-z"]', c)):
        return None
    return c


class Line:
    __slots__ = ('kind', 'text', 'size', 'value', 'addr', 'frozen', 'label', 'hand')

    def __init__(self, kind, text, size=0, value=None, label=None):
        self.kind, self.text, self.size, self.value, self.label = kind, text, size, value, label
        self.addr, self.frozen, self.hand = None, False, None


def parse(text):
    """(head lines, region lines) — the region starts at the master table label."""
    lines = text.split('\n')
    start = next(i for i, l in enumerate(lines) if re.match(r'^Bank0[CDEF]_ScriptMasterTable:', l))
    head, out = lines[:start], []
    frozen = False
    for l in lines[start:]:
        s = l.strip()
        if s.startswith(';') or not s:
            ln = Line('comment', l)
            if '@BUILD_PROJECT BEGIN' in s:
                frozen = True
            elif '@BUILD_PROJECT END' in s:
                frozen = False
            ln.frozen = frozen
            out.append(ln)
            continue
        m = LINE_LABEL.match(s)
        if m:
            ln = Line('label', l, label=m.group(1))
            ln.frozen = frozen
            out.append(ln)
            continue
        m = LINE_DATA.match(l)
        if not m:
            raise SystemExit(f'unexpected line in the script data region: {l!r}')
        d, v = m.group(1), m.group(2)
        vals = [x.strip() for x in v.split(',')]
        if d == 'dw' and len(vals) != 1:
            raise SystemExit(f'one word per dw line expected: {l!r}')
        ln = Line(d, l, 2 if d == 'dw' else len(vals), vals[0] if len(vals) == 1 else vals)
        ln.hand = hand_comment(m.group(3))
        ln.frozen = frozen
        out.append(ln)
    return head, out


def num(v):
    if v.startswith('$'):
        return int(v[1:], 16)
    if v.lower().startswith('0x'):
        return int(v, 16)
    if v.isdigit():
        return int(v)
    return None


def place(region, rom, bank):
    """Addresses: the region starts at $41BA; every literal byte / label word is
    checked against the ROM (an error = this tool does not understand the file)."""
    a = SCRIPT_TBL
    labels = {}
    for ln in region:
        ln.addr = a
        if ln.kind == 'label':
            labels[ln.label] = a
        a += ln.size
    base = bank * 0x4000 - 0x4000
    for ln in region:
        if ln.kind not in ('dw', 'db'):
            continue
        if isinstance(ln.value, list):                   # db b1, b2, …
            got = list(rom[base + ln.addr: base + ln.addr + ln.size])
            want = [num(x) for x in ln.value]
            if not ln.frozen and got != want:
                raise SystemExit(f'${bank:02X}:{ln.addr:04X}: {ln.text.strip()!r} != ROM')
            continue
        v = num(ln.value)
        if v is None:
            v = labels.get(ln.value)
            if v is None:
                raise SystemExit(f'${bank:02X}:{ln.addr:04X}: unknown label {ln.value}')
        got = rom[base + ln.addr] | (rom[base + ln.addr + 1] << 8 if ln.size == 2 else 0)
        if ln.frozen:
            continue
        if got != (v & (0xFFFF if ln.size == 2 else 0xFF)):
            raise SystemExit(f'${bank:02X}:{ln.addr:04X}: {ln.text.strip()!r} != ROM ${got:04X}')
    return labels, a


class Ctx:
    """script_ops.sentence's context: texts by their first words, labels."""

    def __init__(self, cat, labels_at):
        from editor2.core.ram_names import RamNames
        self.cat, self.labels_at = cat, labels_at
        self.names = RamNames(cat.rooms)

    def actor(self, n):
        return 'the player' if n == 0 else f'NPC {n}'

    def flag(self, n):
        return f'flag ${n:04X}'

    def room(self, m):
        try:
            return self.cat.rooms.name(m)
        except Exception:                                # noqa: BLE001
            return None

    def text(self, tid):
        t = (self.cat.text(tid) or '').replace('\n', ' ')
        t = re.sub(r'\s+', ' ', t).strip()
        return t[:40] + ('…' if len(t) > 40 else '')

    def label(self, target):
        nm = self.labels_at.get(target)
        return nm or f'${target:04X}'


def roles(rom, bank):
    """addr -> role for every word some script of the bank runs, + the pointer
    table words. role = ('op', step) | ('param', step, k) | ('text', step) |
    ('end', step) | ('master', map type, of this bank) | ('ptr', map type, index) |
    ('patch', address, length, op)."""
    from editor2.core import cutscenes as CS
    lo, hi = BANKS[bank]
    out, conflicts = {}, []

    def sig(r):
        if r[0] in ('op', 'param', 'text', 'end'):
            return (r[0], r[1].code, r[1].params) + tuple(r[2:])
        return r

    def put(a, r):
        old = out.get(a)
        if old is None:
            out[a] = r
        elif sig(old) != sig(r):
            conflicts.append((a, old, r))
    # the master table: one row per FULL map type from $41BA up to the first per-map
    # table (rows of other banks' map types are filler — BANK04 "Script Data Banks")
    first = min(CS._rw(rom, bank, SCRIPT_TBL + 2 * m) for m in range(lo, hi))
    for m in range((first - SCRIPT_TBL) // 2):
        out[SCRIPT_TBL + 2 * m] = ('master', m, lo <= m < hi)
    for m in range(lo, hi):
        try:
            ptrs = CS.vanilla_script_ptrs(rom, m)
        except Exception:                                # noqa: BLE001
            continue
        tbl = CS._rw(rom, bank, SCRIPT_TBL + 2 * m)
        for i in range(len(ptrs)):
            out[tbl + 2 * i] = ('ptr', m, i)
        for i in range(len(ptrs)):
            sc = CS.decode_vanilla(rom, m, i)
            for st in sc.steps.values():
                if st.code == CS.END:
                    put(st.addr, ('end', st))
                elif st.code == CS.TEXT:
                    put(st.addr, ('text', st))
                else:
                    put(st.addr, ('op', st))
                    for k in range(len(st.params)):
                        put(st.addr + 2 + 2 * k, ('param', st, k))
                    if st.code in (0x24, 0x61) and 0x4000 <= st.params[0] < 0x8000:
                        # the tile patch the op's script-bank entry reads (BANK04 "Tile
                        # patches"): [BG offset word, tiles…, $D8 next row, $D9 end]
                        p0 = st.params[0]
                        o = bank * 0x4000 + p0 - 0x4000
                        k = o + 2
                        while rom[k] != 0xD9 and k - o < 512:
                            k += 1
                        put(p0, ('patch', p0, k - o + 1, st.code))
    return out, conflicts


def rewrite(text, rom, bank):
    from editor2.core import cutscenes as CS, script_ops as SO
    head, region = parse(text)
    labels, end = place(region, rom, bank)
    rl, conflicts = roles(rom, bank)
    if conflicts:
        raise SystemExit(f'${bank:02X}: scripts disagree about {len(conflicts)} word(s), e.g. '
                         f'{conflicts[0][0]:04X}')
    base = bank * 0x4000 - 0x4000
    rw = lambda a: rom[base + a] | (rom[base + a + 1] << 8)
    # labels at addresses (first defined wins as the name a reference uses)
    at = {}
    for nm, a in labels.items():
        at.setdefault(a, nm)
    pref = 'Bank%02X_ScriptAddr_' % bank
    # targets that need a new label
    new_labels = {}
    for a, r in rl.items():
        if r[0] == 'param':
            st, k = r[1], r[2]
            op = SO.OPS.get(st.code)
            if op is not None and op.branch == k:
                t = st.params[k]
                if t not in at and t not in new_labels:
                    new_labels[t] = f'{pref}{t:04X}'
    for a, r in rl.items():
        if r[0] == 'patch' and a not in at and a not in new_labels:
            new_labels[a] = 'Bank%02X_TilePatch_%04X' % (bank, a)
    names = dict(at)
    names.update(new_labels)
    cat = CS.Catalogue(rom)
    ctx = Ctx(cat, names)
    # which addresses have an anchor (a label / comment line before a byte)
    anchors = {}
    for ln in region:
        if ln.kind in ('label', 'comment'):
            anchors.setdefault(ln.addr, []).append(ln)
    out = list(head)
    n = len(region)
    emitted_new = set()

    def emit_anchors(a):
        for ln in anchors.pop(a, []):
            out.append(ln.text)
        if a in new_labels and a not in emitted_new:
            emitted_new.add(a)
            out.append(f'{new_labels[a]}:')

    def comment_for(a):
        r = rl.get(a)
        if r is None:
            return None
        kind = r[0]
        if kind == 'master':
            m, mine = r[1], r[2]
            return (f'map type ${m:02X}: {ctx.room(m) or "?"}' if mine else
                    f'map type ${m:02X}: another bank\'s — filler, never read here')
        if kind == 'ptr':
            return f'script {r[2]}'
        if kind == 'end':
            return 'END'
        if kind == 'text':
            st = r[1]
            t = ctx.text(st.params[0])
            return f'text ${st.params[0]:04X}' + (f': "{t}"' if t else '')
        if kind == 'op':
            st = r[1]
            op = SO.OPS[st.code]
            try:
                s = SO.sentence(st.code, st.params, ctx)
            except Exception:                            # noqa: BLE001
                s = SO.first_sentence(op.doc)
            return f'${st.code:02X} {op.name}: {s}'
        st, k = r[1], r[2]
        op = SO.OPS[st.code]
        return f'  {op.params[k]}'

    last = max(rl)                                   # the last byte any role covers

    def dead_word(w):
        if w == 0xFFFF:
            return 'END — not reached (after a room change / no script runs here)'
        if w >> 8 == 0xFF and (w & 0xFF) in SO.OPS:
            return f'not reached — as a script word: ${w & 0xFF:02X} {SO.OPS[w & 0xFF].name}'
        t = ctx.text(w) if w < 0x0A00 else ''
        return 'not reached' + (f' — as a script word: text ${w:04X}: "{t}"' if t else '')

    # walk byte by byte over the region's lines
    data = [ln for ln in region]
    pos = 0
    while pos < n:
        ln = data[pos]
        if ln.kind in ('label', 'comment'):
            if ln.addr in anchors and ln in anchors[ln.addr]:
                emit_anchors(ln.addr)
            pos += 1
            continue
        a = ln.addr
        emit_anchors(a)
        if ln.frozen:
            out.append(ln.text)
            pos += 1
            continue
        r = rl.get(a)
        if r is not None and r[0] == 'patch':
            length = r[2]
            covered, j = 0, pos
            while covered < length and j < n:
                if data[j].kind in ('dw', 'db'):
                    covered += data[j].size
                elif data[j].addr != a:
                    break                                # a label / comment inside
                j += 1
            if covered == length and not any(x in anchors for x in range(a + 1, a + length)) \
                    and not any(d.frozen for d in data[pos:j]):
                b = rom[base + a: base + a + length]
                off = b[0] | b[1] << 8
                rows, row = [], []
                for x in b[2:-1]:
                    if x == 0xD8:
                        rows.append(row)
                        row = []
                    else:
                        row.append(x)
                rows.append(row)
                what = 'tiles' if r[3] == 0x24 else 'colours'
                body = ' / '.join(' '.join(f'{x:02X}' for x in rw_) for rw_ in rows)
                out.append('    db ' + ', '.join(f'${x:02X}' for x in b)
                           + f'  ; tile patch (op ${r[3]:02X}): BG offset ${off:04X} (row '
                           f'{off // 32}, column {off % 32}), {what} {body}; $D8 = next row, '
                           f'$D9 = end')
                pos = j
                continue
        # a decoded word: 2 bytes; the next byte must not carry an anchor
        if r is not None and (a + 1) not in anchors and not \
                any(d.frozen for d in data[pos:pos + 2] if d.kind in ('dw', 'db')):
            # consume the lines that cover bytes a, a+1
            covered, j = 0, pos
            while covered < 2 and j < n:
                if data[j].kind in ('dw', 'db'):
                    covered += data[j].size
                j += 1
            if covered == 2:
                w = rw(a)
                kind = r[0]
                val = f'${w:04X}'
                if kind == 'param':
                    st, k = r[1], r[2]
                    op = SO.OPS[st.code]
                    if op.branch == k:
                        val = names[st.params[k]]
                    elif st.code in (0x24, 0x61) and (st.params[0] in names) and \
                            rl.get(st.params[0], ('',))[0] == 'patch':
                        val = names[st.params[0]]
                elif kind in ('master', 'ptr'):
                    # a table word: the label it points at (the one the old line named)
                    olds = [d.value for d in data[pos:j] if d.kind == 'dw' and num(d.value) is None]
                    val = olds[0] if olds else names.get(w, val)
                hands = [d.hand for d in data[pos:j] if d.kind in ('dw', 'db') and d.hand]
                out.append(f'    dw {val:<20} ; {comment_for(a)}'
                           + (SEP + ' / '.join(hands) if hands else ''))
                pos = j
                continue
        # not reached by any script: keep the bytes, say so. Between scripts (before
        # the bank's tail) a pair of single db lines becomes one word with what it
        # would mean as a script word — dead fragments, ENDs after a room change
        if ln.kind == 'db' and ln.size == 1 and a < last and (a + 1) not in anchors \
                and pos + 1 < n and data[pos + 1].kind == 'db' and data[pos + 1].size == 1 \
                and not data[pos + 1].frozen and (a + 1) not in rl:
            w = rw(a)
            out.append(f'    dw ${w:04X}{"":<15} ; {dead_word(w)}')
            pos += 2
            continue
        if ln.kind == 'dw':
            w = rw(a)
            val = ln.value if isinstance(ln.value, str) and num(ln.value) is None \
                else f'${w:04X}'
            why = dead_word(w) if a < last else 'not reached by any script path'
            out.append(f'    dw {val:<20} ; {why}' + (SEP + ln.hand if ln.hand else ''))
        else:
            out.append('    db ' + ', '.join(f'${x:02X}' for x in rom[base + a: base + a + ln.size])
                       + (f'  ;{SEP}{ln.hand}' if ln.hand else ''))
        pos += 1
    for a in sorted(anchors):
        for ln in anchors[a]:
            out.append(ln.text)
    missing = set(new_labels) - emitted_new
    if missing:
        raise SystemExit(f'${bank:02X}: new labels not placed: '
                         + ', '.join(f'${x:04X}' for x in sorted(missing)))
    return '\n'.join(out), len(new_labels)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--bank')
    ap.add_argument('--file')
    ap.add_argument('--out')
    ap.add_argument('--check', '--selftest', dest='check', action='store_true')
    a = ap.parse_args()
    if not os.path.exists(ROM):
        print('SKIP: no ROM')
        return 0
    rom = open(ROM, 'rb').read()
    banks = [int(a.bank, 16)] if a.bank else sorted(BANKS)
    jobs = [(b, a.file or FILES[b]) for b in banks]
    if not a.bank and not a.file:
        # the patched tree's copy of bank $0E (the Milly hook's compiler region is
        # copied verbatim; the rest is the clean bank's script data)
        jobs.append((0x0E, os.path.join(ROOT, 'patches', 'bank_00e.asm')))
    bad = 0
    for b, path in jobs:
        text = open(path).read()
        new, nl = rewrite(text, rom, b)
        if a.check:
            if new != text:
                print(f'FAIL: {os.path.relpath(path, ROOT)} is not what '
                      'recomment_script_banks.py writes (stale script annotation)')
                bad += 1
            continue
        out = a.out or path
        with open(out, 'w') as f:
            f.write(new)
        print(f'${b:02X}: {os.path.relpath(out, ROOT) if out.startswith(ROOT) else out} '
              f'(+{nl} branch-target labels)')
    if a.check:
        if bad:
            return 1
        print('OK: the script banks carry the decoder\'s annotation')
    return 0


if __name__ == '__main__':
    sys.exit(main())
