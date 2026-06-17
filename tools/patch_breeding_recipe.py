#!/usr/bin/env python3
"""patch_breeding_recipe.py — overwrite SPECIAL breeding-recipe entries in bank $16.

The special recipe table lives at $16:$4B30 (825 entries x 5 bytes, $FF
terminated). Each entry is [p1_match, p2_match, min_plus, result_species,
plus_mod], where p1/p2 match a specific species ID (0-220) OR a family code
($F0-$F9). The engine scans top-to-bottom and returns the FIRST entry that
matches both parents and whose min_plus <= offspring plus (see
BREEDING_SYSTEM.md / disassembly bank_016.asm LoadBrd_471c).

This tool performs a SAME-SIZE, in-place overwrite of chosen entry indices in
disassembly/bank_016.asm and writes the result to patches/bank_016.asm. It
only rewrites the specific `$xx` db tokens for the targeted 5-byte entries;
every other byte of the file is preserved verbatim, so the assembled bank is
byte-identical to the original except for the targeted entries (zero shift —
no inserted bytes, safe for bank $16's embedded data).

It deliberately does NOT insert entries (that would shift the table and break
embedded pointers). To add a new recipe, target a dead/shadowed entry index
(see --list-dead) so vanilla behaviour is unaffected.

Usage:
    # Overwrite entry 803 with Anteater(53) x BattleRex(42) -> GoldSlime(19):
    python3 tools/patch_breeding_recipe.py \
        --set 803=53,42,0,19,0 --set 693=42,53,0,19,0

    python3 tools/patch_breeding_recipe.py --list-dead   # show shadowed entries
    python3 tools/patch_breeding_recipe.py --dump 803    # print one entry
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(REPO, "disassembly", "bank_016.asm")
OUT = os.path.join(REPO, "patches", "bank_016.asm")
LABEL = "SpecialRecipeTable:"
N_ENTRIES = 825
ENTRY_SIZE = 5
TABLE_BYTES = N_ENTRIES * ENTRY_SIZE  # 4125

DB_RE = re.compile(r"\$[0-9a-fA-F]{2}")


def load_lines():
    with open(SRC) as f:
        return f.readlines()


def find_table_tokens(lines):
    """Return a flat list of (line_index, match_start, match_end, value) for
    every db byte token in the SpecialRecipeTable region, in order, covering
    exactly the first TABLE_BYTES bytes after the label."""
    # locate label line
    start = None
    for i, ln in enumerate(lines):
        if ln.strip().startswith(LABEL):
            start = i + 1
            break
    if start is None:
        sys.exit(f"ERROR: {LABEL} not found in {SRC}")

    tokens = []  # (line_index, span_start, span_end, hexvalue)
    i = start
    while i < len(lines) and len(tokens) < TABLE_BYTES:
        ln = lines[i]
        stripped = ln.strip()
        if not stripped.startswith("db"):
            # table must be a contiguous run of db lines
            sys.exit(f"ERROR: non-db line inside table at line {i+1}: {stripped!r}")
        for m in DB_RE.finditer(ln):
            if len(tokens) >= TABLE_BYTES:
                break
            tokens.append((i, m.start(), m.end(), int(m.group()[1:], 16)))
        i += 1
    if len(tokens) < TABLE_BYTES:
        sys.exit(f"ERROR: only found {len(tokens)} table bytes, expected {TABLE_BYTES}")
    return tokens


def entry_bytes(tokens, idx):
    base = idx * ENTRY_SIZE
    return [tokens[base + k][3] for k in range(ENTRY_SIZE)]


def list_dead(tokens):
    """A fully-shadowed entry j: some earlier entry i has identical (b0,b1)
    matchers and min_plus_i <= min_plus_j, so i always wins first."""
    ents = [entry_bytes(tokens, j) for j in range(N_ENTRIES)]
    dead = []
    for j in range(N_ENTRIES):
        b0, b1, b2, b3, b4 = ents[j]
        for i in range(j):
            a0, a1, a2, a3, a4 = ents[i]
            if a0 == b0 and a1 == b1 and a2 <= b2:
                dead.append((j, i))
                break
    return dead


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", action="append", default=[],
                    help="IDX=b0,b1,b2,b3,b4  (decimal). Repeatable.")
    ap.add_argument("--list-dead", action="store_true")
    ap.add_argument("--dump", type=int, default=None)
    ap.add_argument("--out", default=OUT)
    args = ap.parse_args()

    lines = load_lines()
    tokens = find_table_tokens(lines)

    if args.list_dead:
        for j, i in list_dead(tokens):
            print(f"  entry {j} shadowed by entry {i}: "
                  f"{entry_bytes(tokens, j)}  (shadower {entry_bytes(tokens, i)})")
        return
    if args.dump is not None:
        b = entry_bytes(tokens, args.dump)
        print(f"entry {args.dump} = " + " ".join("$%02X" % x for x in b)
              + f"  ({b})")
        return
    if not args.set:
        ap.error("nothing to do; pass --set / --list-dead / --dump")

    # Parse overrides
    overrides = {}
    for spec in args.set:
        idx_s, _, vals_s = spec.partition("=")
        idx = int(idx_s)
        vals = [int(x, 0) for x in vals_s.split(",")]
        if len(vals) != ENTRY_SIZE:
            sys.exit(f"ERROR: entry {idx} needs {ENTRY_SIZE} bytes, got {vals}")
        for v in vals:
            if not 0 <= v <= 0xFF:
                sys.exit(f"ERROR: byte {v} out of range in entry {idx}")
        if not 0 <= idx < N_ENTRIES:
            sys.exit(f"ERROR: entry index {idx} out of range 0..{N_ENTRIES-1}")
        overrides[idx] = vals

    # Apply edits to a mutable copy of the lines, rewriting only target tokens.
    new_lines = list(lines)
    # Build per-line replacement plan: (line_index -> list of (start,end,newtext))
    edits_by_line = {}
    for idx, vals in overrides.items():
        before = entry_bytes(tokens, idx)
        for k in range(ENTRY_SIZE):
            li, s, e, _old = tokens[idx * ENTRY_SIZE + k]
            edits_by_line.setdefault(li, []).append((s, e, "$%02x" % vals[k]))
        print(f"entry {idx}: {['$%02X'%x for x in before]} -> "
              f"{['$%02X'%x for x in vals]}")

    for li, edits in edits_by_line.items():
        ln = new_lines[li]
        for s, e, txt in sorted(edits, key=lambda t: t[0], reverse=True):
            ln = ln[:s] + txt + ln[e:]
        new_lines[li] = ln

    with open(args.out, "w") as f:
        f.writelines(new_lines)

    # Self-check: re-parse output, confirm table size intact and edits applied.
    with open(args.out) as f:
        out_lines = f.readlines()
    out_tokens = find_table_tokens(out_lines)
    assert len(out_tokens) == TABLE_BYTES, "table size changed!"
    for idx, vals in overrides.items():
        assert entry_bytes(out_tokens, idx) == vals, f"entry {idx} mismatch"
    print(f"wrote {args.out}  (table size intact: {TABLE_BYTES} bytes, "
          f"{len(overrides)} entries overwritten)")


if __name__ == "__main__":
    main()
