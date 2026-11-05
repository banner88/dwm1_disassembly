#!/usr/bin/env python3
"""audit_patch_space.py — does a patched build write over anything the ORIGINAL
game still reads? (S167, ROADMAP Phase D "Bank $51 … reference-free" + the
S166 r2 lesson, KEY_LESSONS "an LZ stream may END in a literal $00").

The S166 r2 bug: S128 put code at bank $51 `$7B34`, the first byte of what
looked like a `$00` fill — it was the LAST byte of the LZ stream gfx `$5112`
(the battle YES / NO letters), and the O grew a tail. This tool asks the same
question of EVERY byte a patched build changes in a bank the original game uses
(the 23 vanilla-empty banks $60 … $7F are all-zero in the original and are
handled by the dynamic half, `--poison`):

STATIC (default):
  1. diff — every changed range of the patched ROM against the original in
     banks $00-$7F (the 23 empty banks and the cartridge header left out),
     each classed FILL (the original bytes there were one repeated byte —
     space a patch CLAIMED as free) or EDIT (a hook / an edited table: the
     original bytes were replaced on purpose), with the patched label that
     owns it and the original label before it;
  2. streams — every entry of every bank's `$4001` table (the table
     ROM0 `DecompressTileLayout` reads: gfx id = bank << 8 | index) parsed as
     an LZ stream (`dwm.sprite_codec.read_stream`: the header's length, then
     the body walked to the byte where the decoder stops); a stream whose bytes
     meet a FILL range with its pointer unchanged = a stream a patch cut into
     (the S166 r2 class). Entries that are code (rst $10 entries share the
     table) parse as nonsense lengths and are reported only when they meet a
     FILL range — then they are judged by hand (the JSON says which);
  3. references — every 16-bit number `$4000-$7FFF` written in the ORIGINAL
     disassembly of the same bank (or of ROM0) that points INTO a FILL range
     (a raw pointer the assembler does not move);
  4. context — for every FILL range, the original bytes just before it and the
     last original instruction / data line before it (does code fall through
     into it? does a table run on into it?).

DYNAMIC (`--poison OUT.gbc`): writes the ORIGINAL ROM with every FILL range
(+ optionally the empty banks) overwritten by a different byte — the game run
on both must behave identically (tools/walk_poison_space.py).

Usage:
  python3 tools/audit_patch_space.py --patched <rom.gbc> --sym <game.sym>
        [--clean-sym disassembly/game.sym] [--json extracted/patch_space_audit.json]
        [--poison out.gbc [--poison-byte 0xA5] [--poison-empty]]
"""
import argparse
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

ORIGINAL = os.path.join(REPO, 'data', 'DWM-original.gbc')
BANK = 0x4000
HEADER = (0x0134, 0x0150)          # title … global checksum: differs by design


def empty_banks(orig):
    """Banks whose every byte is one value in the original (measured: 23, all $00)."""
    out = []
    for b in range(1, len(orig) // BANK):
        d = orig[b * BANK:(b + 1) * BANK]
        if len(set(d)) == 1:
            out.append(b)
    return out


def addr_of(off):
    b = off // BANK
    return b, (off if b == 0 else BANK + off % BANK)


def load_sym(path):
    """{bank: [(addr, label)] sorted}"""
    out = {}
    if not path or not os.path.exists(path):
        return out
    for ln in open(path, encoding='utf-8', errors='replace'):
        m = re.match(r'([0-9A-Fa-f]{2}):([0-9A-Fa-f]{4}) (\S+)', ln)
        if m:
            out.setdefault(int(m.group(1), 16), []).append((int(m.group(2), 16), m.group(3)))
    for v in out.values():
        v.sort()
    return out


def label_at(sym, bank, addr):
    """The last label at or before (bank, addr), with its distance."""
    best = None
    for a, l in sym.get(bank, []):
        if a <= addr:
            best = (l, addr - a)
        else:
            break
    return best


def diff_ranges(orig, pat, skip_banks):
    n = min(len(orig), len(pat))
    rng = []
    i = 0
    while i < n:
        if orig[i] != pat[i] and not (HEADER[0] <= i < HEADER[1]) and (i // BANK) not in skip_banks:
            j = i
            while j < n and orig[j] != pat[j] and (j // BANK) == (i // BANK):
                j += 1
            rng.append((i, j))
            i = j
        else:
            i += 1
    return rng


MIN_RUN = 8                        # a shorter run of $00 / $FF is a value, not space


def classify(orig, a, b):
    """FILL = the patch wrote into a run of >= MIN_RUN equal $00 / $FF bytes of the
    original (space it claimed); EDIT = it replaced original code / data in place."""
    vals = set(orig[a:b])
    if len(vals) == 1 and orig[a] in (0x00, 0xFF):
        s, e = fill_extent(orig, a, b)
        if e - s >= MIN_RUN:
            return 'FILL', orig[a]
    return 'EDIT', None


def fill_extent(orig, a, b):
    """The whole run of the fill byte around [a, b) in the original (the claimed space)."""
    v = orig[a]
    s = a
    lo = (a // BANK) * BANK
    while s > lo and orig[s - 1] == v:
        s -= 1
    e = b
    hi = lo + BANK
    while e < hi and orig[e] == v:
        e += 1
    return s, e


# ------------------------------------------------------------------ streams
def stream_extent(rom, off):
    """(end, declen) of an LZ stream at file offset off, walked like ROM0's
    decoder; None when it runs out of its bank or the length is absurd."""
    bank_end = (off // BANK + 1) * BANK
    if off + 3 > bank_end:
        return None
    declen = rom[off] | (rom[off + 1] << 8)
    if declen == 0 or declen > 0x2000:
        return None
    marker = rom[off + 2]
    p = off + 3
    produced = 0
    while produced < declen:
        if p >= bank_end:
            return None
        b = rom[p]
        p += 1
        if b != marker:
            produced += 1
        else:
            if p + 1 >= bank_end:
                return None
            ctrl = rom[p + 1]
            cnt = (ctrl & 0xF) + 4
            p += 2
            if (ctrl & 0xF) == 0xF:
                cnt = ((rom[p] + 0x13) & 0xFF) or 0x100
                p += 1
            produced += cnt
    return p, declen


def table_entries(rom, bank):
    """The bank's `$4001` table: entries until the lowest pointer seen."""
    base = bank * BANK
    ents = []
    lowest = 0x8000
    i = 0
    while True:
        a = 0x4001 + 2 * i
        if a + 2 > lowest or a >= 0x8000 - 1:
            break
        ptr = rom[base + a - BANK] | (rom[base + a - BANK + 1] << 8)
        if not (0x4000 <= ptr < 0x8000):
            break
        ents.append((i, ptr))
        if ptr >= a + 2:
            lowest = min(lowest, ptr)
        i += 1
    return ents


def far_call_entries():
    """(bank, index) pairs the original code far-calls (`ld hl, $BBII` then `rst $10`
    within 3 lines) — those `$4001` entries are code, never streams."""
    out = set()
    dis = os.path.join(REPO, 'disassembly')
    pat = re.compile(r'ld hl, \$([0-9a-fA-F]{2})([0-9a-fA-F]{2})\b')
    for fn in sorted(os.listdir(dis)):
        if not fn.endswith('.asm'):
            continue
        lines = open(os.path.join(dis, fn), encoding='utf-8', errors='replace').read().splitlines()
        for i, ln in enumerate(lines):
            m = pat.search(ln.split(';', 1)[0])
            if m and any('rst $10' in x.split(';', 1)[0] for x in lines[i + 1:i + 4]):
                out.add((int(m.group(1), 16), int(m.group(2), 16)))
    return out


def stream_census(orig, pat, fills, edits, banks):
    hits, edited, total = [], [], 0
    code = far_call_entries()
    for bank in banks:
        if bank == 0:
            continue
        ents = table_entries(orig, bank)
        starts = sorted({ptr for _i, ptr in ents})
        for idx, ptr in ents:
            if (bank, idx) in code:
                continue
            off = bank * BANK + ptr - BANK
            ext = stream_extent(orig, off)
            if not ext:
                continue
            end, declen = ext
            # streams are disjoint: an "extent" that runs over another entry's start
            # is code (rst $10 entries share the table), not a stream
            end_a = BANK + (end - bank * BANK)
            if any(ptr < q < end_a for q in starts) or ptr < 0x4001 + 2 * len(ents):
                continue
            total += 1
            pptr = pat[bank * BANK + 1 + 2 * idx - 0] | (pat[bank * BANK + 2 + 2 * idx] << 8)
            gid = f'${bank:02X}{idx:02X}'
            for (a, b) in fills:
                if a < end and off < b and not any(x['gfx_id'] == gid for x in hits):
                    hits.append({'gfx_id': gid, 'stream': f'${bank:02X}:{ptr:04X}',
                                 'stream_end': f'${bank:02X}:{BANK + end % BANK:04X}',
                                 'declen': declen, 'fill': f'${bank:02X}:{BANK + a % BANK:04X}',
                                 'pointer_unchanged': pptr == ptr,
                                 'stream_bytes_unchanged': orig[off:end] == pat[off:end]})
            for (a, b) in edits:
                if a < end and off < b and pptr == ptr:
                    edited.append({'gfx_id': gid, 'stream': f'${bank:02X}:{ptr:04X}',
                                   'edit': f'${bank:02X}:{BANK + a % BANK:04X}-{BANK + (b - 1) % BANK:04X}'})
    return total, hits, edited


# ------------------------------------------------------------------ references
NUM = re.compile(r'\$([0-9A-Fa-f]{4})\b')


def raw_refs(fills_by_bank):
    """Raw 16-bit numbers in the ORIGINAL disassembly (same bank / ROM0) that
    land in a FILL range of that bank."""
    out = []
    dis = os.path.join(REPO, 'disassembly')
    for bank, ranges in fills_by_bank.items():
        files = [f'bank_{bank:03x}.asm']
        for fn in files:
            p = os.path.join(dis, fn)
            if not os.path.exists(p):
                continue
            for no, ln in enumerate(open(p, encoding='utf-8', errors='replace'), 1):
                code = ln.split(';', 1)[0]
                for m in NUM.finditer(code):
                    v = int(m.group(1), 16)
                    for (a, b) in ranges:
                        if a <= v < b:
                            out.append({'bank': f'${bank:02X}', 'value': f'${v:04X}',
                                        'file': fn, 'line': no, 'text': ln.strip()[:100]})
    return out


def label_refs(fills_by_bank, clean_sym):
    """Labels of the CLEAN build that sit inside a changed FILL range and are named
    anywhere in the original disassembly (mgbdis turns every referenced address into
    a label, so a jump / call / pointer into claimed space shows up here)."""
    inside = {}
    for bank, ranges in fills_by_bank.items():
        for a, l in clean_sym.get(bank, []):
            if any(s <= a < e for s, e in ranges):
                inside[l] = (bank, a)
    out = []
    if not inside:
        return out
    dis = os.path.join(REPO, 'disassembly')
    pat = re.compile(r'\b(' + '|'.join(re.escape(l) for l in inside) + r')\b')
    for fn in sorted(os.listdir(dis)):
        if not fn.endswith('.asm'):
            continue
        for no, ln in enumerate(open(os.path.join(dis, fn), encoding='utf-8', errors='replace'), 1):
            code = ln.split(';', 1)[0]
            for m in pat.finditer(code):
                if code.strip().startswith(m.group(1) + ':'):
                    continue                      # the definition itself
                b, a = inside[m.group(1)]
                out.append({'label': m.group(1), 'at': f'${b:02X}:{a:04X}', 'file': fn,
                            'line': no, 'text': ln.strip()[:100]})
    return out


def context_line(bank, addr, clean_sym):
    """The original label before addr and the source lines that end there."""
    lab = label_at(clean_sym, bank, addr - 1)
    return lab


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--patched', action='append', required=True)
    ap.add_argument('--sym', action='append', default=[])
    ap.add_argument('--clean-sym', default=os.path.join(REPO, 'disassembly', 'game.sym'))
    ap.add_argument('--json')
    ap.add_argument('--poison')
    ap.add_argument('--poison-byte', default='0xA5')
    ap.add_argument('--poison-empty', action='store_true')
    args = ap.parse_args()

    orig = open(ORIGINAL, 'rb').read()
    empty = empty_banks(orig)
    clean_sym = load_sym(args.clean_sym)
    report = {'_generator': 'tools/audit_patch_space.py (S167) on data/DWM-original.gbc + '
                            + ', '.join(os.path.relpath(p, REPO) if p.startswith(REPO) else os.path.basename(p)
                                        for p in args.patched),
              'empty_banks': [f'${b:02X}' for b in empty], 'builds': []}
    all_fill = {}
    for k, pp in enumerate(args.patched):
        pat = open(pp, 'rb').read()
        psym = load_sym(args.sym[k] if k < len(args.sym) else None)
        rng = diff_ranges(orig, pat, set(empty))
        fills, edits, rows = [], [], []
        for a, b in rng:
            kind, val = classify(orig, a, b)
            bank, addr = addr_of(a)
            row = {'bank': f'${bank:02X}', 'start': f'${addr:04X}', 'end': f'${addr + (b - a) - 1:04X}',
                   'bytes': b - a, 'kind': kind}
            pl = label_at(psym, bank, addr)
            if pl:
                row['patched_label'] = f'{pl[0]}+{pl[1]}' if pl[1] else pl[0]
            ol = label_at(clean_sym, bank, addr)
            if ol:
                row['original_label'] = f'{ol[0]}+{ol[1]}' if ol[1] else ol[0]
            if kind == 'FILL':
                s, e = fill_extent(orig, a, b)
                row['fill_byte'] = f'${val:02X}'
                row['claimed_run'] = f'${addr_of(s)[1]:04X}-${addr_of(e - 1)[1]:04X}'
                row['before'] = orig[max(s - 8, (s // BANK) * BANK):s].hex(' ')
                prev = label_at(clean_sym, bank, addr_of(s)[1] - 1)
                if prev:
                    row['original_label_before_run'] = f'{prev[0]}+{prev[1]}'
                fills.append((a, b))
                all_fill.setdefault(bank, []).append((addr, addr + (b - a)))
            else:
                edits.append((a, b))
            rows.append(row)
        banks = sorted({a // BANK for a, _ in rng})
        total, hits, edited = stream_census(orig, pat, fills, edits, range(1, len(orig) // BANK))
        bstats = {}
        for r in rows:
            s = bstats.setdefault(r['bank'], {'FILL': 0, 'EDIT': 0})
            s[r['kind']] += r['bytes']
        ecount = {}
        for r in rows:
            if r['kind'] == 'EDIT':
                ecount[r['bank']] = ecount.get(r['bank'], 0) + 1
        report['builds'].append({'rom': os.path.basename(pp),
                                 'fill_ranges': [r for r in rows if r['kind'] == 'FILL'],
                                 'edit_ranges_by_bank': ecount, 'bytes_by_bank': bstats,
                                 'streams_parsed': total, 'streams_meeting_fill': hits,
                                 'streams_with_edited_bytes': edited})
        print(f'{os.path.basename(pp)}: {len(rows)} changed ranges in {len(banks)} banks; '
              f'FILL {sum(r["bytes"] for r in rows if r["kind"] == "FILL")} B, '
              f'EDIT {sum(r["bytes"] for r in rows if r["kind"] == "EDIT")} B; '
              f'{total} streams parsed, {len(hits)} meet a FILL range, '
              f'{len(edited)} have edited bytes')
        for h in hits:
            print('  STREAM/FILL', h)
    # merge the claimed runs
    for b in all_fill:
        all_fill[b] = sorted(set(all_fill[b]))
    report['changed_fill'] = {f'${b:02X}': [f'${s:04X}-${e - 1:04X}' for s, e in v]
                              for b, v in sorted(all_fill.items())}
    refs = raw_refs(all_fill)
    report['raw_refs_into_claimed'] = refs
    lrefs = label_refs(all_fill, clean_sym)
    report['label_refs_into_claimed'] = lrefs
    print(f'labels inside a claimed run that the original code names: {len(lrefs)}')
    for r in lrefs[:60]:
        print('  LABEL', r)
    print(f'raw numbers in the original disassembly pointing into a claimed run: {len(refs)}')
    for r in refs[:60]:
        print('  REF', r)
    if args.json:
        with open(args.json, 'w') as f:
            json.dump(report, f, indent=1)
            f.write('\n')
        print('wrote', args.json)
    if args.poison:
        pb = int(args.poison_byte, 0)
        rom = bytearray(orig)
        n = 0
        for bank, v in all_fill.items():
            for s, e in v:
                for a in range(s, e):
                    off = (a if bank == 0 else bank * BANK + a - BANK)
                    rom[off] = pb
                    n += 1
        if args.poison_empty:
            for bank in empty:
                for off in range(bank * BANK + 1, (bank + 1) * BANK):
                    rom[off] = pb
                    n += 1
        open(args.poison, 'wb').write(bytes(rom))
        print(f'poisoned ROM: {n} bytes set to ${pb:02X} -> {args.poison}')


if __name__ == '__main__':
    main()
