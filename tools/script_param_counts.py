#!/usr/bin/env python3
"""script_param_counts.py — script-opcode parameter counts FROM THE HANDLER
CODE (S96), not from the decompiler's guessed table.

Every bank-$04 script opcode handler reads its parameters the same way:
advance the 16-bit script counter ($D8D5/$D8D6) by one and `call
MapTypeDispatch` ($04:$71EF), which returns the next word in BC from the
map's script bank (BANK04_SCRIPT_ENGINE "Script Data Flow"). So the number
of parameters an opcode consumes on a path = the number of 16-bit counter
INCREMENTS the handler performs on that path (a parameter can be skipped
without being read, so reads alone under-count — the S96 first pass did). This tool walks each of the 102
handlers ($04 ScriptCommandTable, rst $00 after MarkScriptActive) with a
small SM83 control-flow tracer over the ORIGINAL ROM bytes:

  * follows jr/jp (conditional: both edges), call into bank $04 (inlined,
    so a shared "read a param" helper counts), ret ends a path;
  * counts `call MapTypeDispatch`;
  * notes paths that WRITE the script counter from a read value (a branch:
    `ld [wScriptCounter], a` after a read) — the decoder must treat the
    param as a target (see BRANCH below);
  * stops a path at `jp hl`, rst $10 (cross-bank call: opaque), or after
    4096 steps (loops), marking it inexact.

Output: extracted/script_param_counts.json — per opcode {counts: sorted
distinct per-path read counts, handler, exact}. A single count = the
opcode's fixed arity; several = the arity depends on a runtime path (the
decoder then needs a per-opcode rule — listed under `_variable`).

Usage: python3 tools/script_param_counts.py [--rom data/DWM-original.gbc]
       python3 tools/script_param_counts.py --check   (selftest vs the JSON)
"""

import argparse
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'extracted', 'script_param_counts.json')

BANK = 0x04
MAP_TYPE_DISPATCH = 0x71EF        # $04:$71EF (disassembly/game.sym)
MARK_SCRIPT_ACTIVE = 0x5613       # rst $00 dispatch at its end
N_OPS = 102                       # $00-$65 (bank_004 ScriptCommandTable; S96: 102 rows)
W_COUNTER = (0xD8D5, 0xD8D6)      # wScriptCounter / high byte
# counter += 1: ld a,[$D8D5] / add $01 / ld [$D8D5],a / ld a,[$D8D6] / adc $00 /
# ld [$D8D6],a — each occurrence consumes one parameter word (read or skipped)
INC_SEQ = bytes.fromhex('FAD5D8C601EAD5D8FAD6D8CE00EAD6D8')
# Handler tails (game.sym): reaching one ENDS the opcode — what follows is
# the NEXT command's fetch, not a parameter read.
TAILS = {
    0x55F5: 'continue',           # ScriptExecContinue: counter+1, fetch next op
    0x5605: 'continue_same',      # ScriptExecLoop: fetch at the CURRENT counter
    0x7212: 'branch',             # ScriptReturnProcess: counter += (BC-HL)/2
}

L3 = {0x01, 0x11, 0x21, 0x31, 0x08, 0xC2, 0xC3, 0xC4, 0xCA, 0xCC, 0xCD, 0xD2,
      0xD4, 0xDA, 0xDC, 0xEA, 0xFA}
L2 = {0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E, 0x18, 0x20, 0x28, 0x30,
      0x38, 0xC6, 0xCE, 0xD6, 0xDE, 0xE6, 0xEE, 0xF6, 0xFE, 0xE0, 0xF0, 0xE8,
      0xF8, 0x10, 0xCB}


def oplen(op):
    return 3 if op in L3 else 2 if op in L2 else 1


class Tracer:
    def __init__(self, rom):
        self.rom = rom

    def rd(self, addr):
        if addr < 0x4000:
            return self.rom[addr]
        return self.rom[BANK * 0x4000 + addr - 0x4000]

    def rw(self, addr):
        return self.rd(addr) | (self.rd(addr + 1) << 8)

    def paths(self, start):
        """Enumerate paths from `start` to a ret. Returns a list of
        (reads, writes_counter, exact) per distinct terminal state."""
        results = set()
        tails = TAILS
        # state: (pc, reads, callstack tuple, wrote_counter, steps, visited)
        stack = [(start, 0, (), False, 0, frozenset())]
        seen_states = set()
        while stack:
            pc, reads, cs, wrote, steps, vis = stack.pop()
            key = (pc, reads, cs, wrote)
            if key in seen_states:
                continue
            seen_states.add(key)
            if steps > 4096 or len(results) > 64:
                results.add((reads, wrote, False, 'opaque'))
                continue
            if pc in tails and pc != start:
                results.add((reads, wrote or tails[pc] == 'branch', True, tails[pc]))
                continue
            if all(self.rd(pc + i) == b for i, b in enumerate(INC_SEQ)):
                # the 16-bit counter increment = one parameter word consumed
                stack.append((pc + len(INC_SEQ), reads + 1, cs, wrote, steps + 1, vis))
                continue
            op = self.rd(pc)
            n = oplen(op)
            nxt = pc + n
            imm16 = self.rw(pc + 1) if n == 3 else None
            rel = self.rd(pc + 1) if n == 2 else None
            st = steps + 1
            if op in (0xC9, 0xD9):                       # ret / reti
                if cs:
                    stack.append((cs[-1], reads, cs[:-1], wrote, st, vis))
                else:
                    results.add((reads, wrote, True, 'ret'))
                continue
            if op in (0xC0, 0xC8, 0xD0, 0xD8):           # ret cc: both
                if cs:
                    stack.append((cs[-1], reads, cs[:-1], wrote, st, vis))
                else:
                    results.add((reads, wrote, True, 'ret'))
                stack.append((nxt, reads, cs, wrote, st, vis))
                continue
            if op == 0xE9:                               # jp hl: opaque
                results.add((reads, wrote, False, 'opaque'))
                continue
            if op == 0xC3:                               # jp nn
                stack.append((imm16, reads, cs, wrote, st, vis))
                continue
            if op in (0xC2, 0xCA, 0xD2, 0xDA):           # jp cc,nn
                stack.append((imm16, reads, cs, wrote, st, vis))
                stack.append((nxt, reads, cs, wrote, st, vis))
                continue
            if op == 0x18:                               # jr e
                stack.append((nxt + (rel - 256 if rel > 127 else rel), reads, cs, wrote, st, vis))
                continue
            if op in (0x20, 0x28, 0x30, 0x38):           # jr cc,e
                stack.append((nxt + (rel - 256 if rel > 127 else rel), reads, cs, wrote, st, vis))
                stack.append((nxt, reads, cs, wrote, st, vis))
                continue
            if op in (0xCD, 0xC4, 0xCC, 0xD4, 0xDC):     # call (cc)
                if imm16 == MAP_TYPE_DISPATCH:
                    stack.append((nxt, reads, cs, wrote, st, vis))
                elif 0x4000 <= imm16 < 0x8000 and len(cs) < 8:
                    stack.append((imm16, reads, cs + (nxt,), wrote, st, vis))
                else:                                    # ROM0 helper: opaque, returns
                    stack.append((nxt, reads, cs, wrote, st, vis))
                if op != 0xCD:
                    stack.append((nxt, reads, cs, wrote, st, vis))
                continue
            if op in (0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF):  # rst
                stack.append((nxt, reads, cs, wrote, st, vis))
                continue
            if op == 0xEA and imm16 in W_COUNTER:        # ld [wScriptCounter], a
                stack.append((nxt, reads, cs, True, st, vis))
                continue
            stack.append((nxt, reads, cs, wrote, st, vis))
        return results


def handler_table(rom, t):
    # MarkScriptActive ends with `ld a, c / rst $00` — the dw table follows
    a = MARK_SCRIPT_ACTIVE
    for _ in range(64):
        if t.rd(a) == 0xC7:
            return [t.rw(a + 1 + 2 * i) for i in range(N_OPS)]
        a += 1
    raise SystemExit('ScriptCommandTable not found after MarkScriptActive')


def analyse(rom):
    t = Tracer(rom)
    tbl = handler_table(rom, t)
    out = {}
    for op, h in enumerate(tbl):
        res = t.paths(h)
        # a path ending in 'continue_same' re-fetches at the current counter:
        # its last read was NOT consumed (e.g. a skipped optional word) — the
        # decoder cares about how far the counter moved, i.e. reads - 1 there
        moved = {(r - 1 if k == 'continue_same' else r) for r, _w, _e, k in res}
        counts = sorted(moved)
        out[f'0x{op:02X}'] = {
            'handler': f'$04:{h:04X}',
            'counts': counts,
            'ends': sorted({k for _r, _w, _e, k in res}),
            'branch_paths': sorted({r for r, w, _e, k in res if w}),
            'exact': all(e for _r, _w, e, _k in res),
        }
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', default=os.path.join(ROOT, 'data', 'DWM-original.gbc'))
    ap.add_argument('--check', '--selftest', dest='check', action='store_true')
    a = ap.parse_args()
    if not os.path.exists(a.rom):
        print('SKIP: no ROM')
        return 0
    rom = open(a.rom, 'rb').read()
    res = analyse(rom)
    doc = {'_generator': 'tools/script_param_counts.py (S96) over the original ROM '
                         '(md5 1ca6579359f21d8e27b446f865bf6b83)',
           '_method': 'per-path count of `call MapTypeDispatch` ($04:$71EF) in each '
                      'bank-$04 script opcode handler; counter writes = branch paths',
           '_variable': sorted(k for k, v in res.items() if len(v['counts']) > 1),
           'ops': res}
    if a.check:
        old = json.load(open(OUT))
        if old.get('ops') != res:
            print('FAIL: extracted/script_param_counts.json differs from the ROM analysis')
            return 1
        print('OK: script_param_counts.json == handler analysis')
        return 0
    with open(OUT, 'w') as f:
        json.dump(doc, f, indent=1)
        f.write('\n')
    print(f'wrote {OUT}: variable-arity ops {doc["_variable"]}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
