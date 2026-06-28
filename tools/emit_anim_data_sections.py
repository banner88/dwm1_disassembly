#!/usr/bin/env python3
"""
emit_anim_data_sections.py — emit rgbasm `db`/`dw` directives for the battle-effect
presentation data tables that mgbdis mis-rendered as instructions.

These regions are byte-verified (BATTLE_SKILL_SYSTEM.md §11; offsets confirmed against
the ROM and the live SameBoy traces). This tool emits the EXACT bytes as labeled data
directives so the disassembly can be corrected with zero risk of a hand-typed boundary
error: the emitted block is generated FROM the ROM, and the post-splice rebuild must
reproduce MD5 1ca6579359f21d8e27b446f865bf6b83 or the change is rejected.

Run: python3 tools/emit_anim_data_sections.py --bank 5f   (prints the data block)
     python3 tools/emit_anim_data_sections.py --verify    (checks region byte coverage)

This is a code-generation helper, not part of the build. It does not write files.
"""
import argparse
import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(REPO, "data", "DWM-original.gbc")


def load(bank):
    rom = open(ROM, "rb").read()
    base = bank * 0x4000
    return rom[base:base + 0x4000]


def db_lines(data, start_addr, label=None, comment=None, per=16):
    """Emit `db` lines for raw bytes starting at start_addr ($4000-based)."""
    out = []
    if comment:
        out.append(f"; {comment}")
    if label:
        out.append(f"{label}:")
    for i in range(0, len(data), per):
        chunk = data[i:i + per]
        out.append("    db " + ", ".join(f"${b:02x}" for b in chunk))
    return out


def dw_lines(data, start_addr, label=None, comment=None, per=8):
    """Emit `dw` lines (little-endian 16-bit) for a pointer table."""
    out = []
    if comment:
        out.append(f"; {comment}")
    if label:
        out.append(f"{label}:")
    words = [data[i] | (data[i + 1] << 8) for i in range(0, len(data) - 1, 2)]
    for i in range(0, len(words), per):
        chunk = words[i:i + per]
        out.append("    dw " + ", ".join(f"${w:04x}" for w in chunk))
    return out


# Region map: (bank, start, end_exclusive, kind, label, comment)
REGIONS = {
    0x5f: [
        (0x56ed, 0x57d5, "db", "AnimCmdTableA_56ed",
         "Layer-2 animation COMMAND table A (by skill id), $ff=no-anim. §11.4"),
        (0x57d5, 0x58bd, "db", "AnimCmdTableB_57d5",
         "Layer-2 animation COMMAND table B (other-side select). §11.4"),
        (0x58bd, 0x58dd, "dw", "AnimRoutinePtrTable_58bd",
         "Layer-1 routine ptr table (index from $58dd/$59c3/$5aa9). $0d->$55cc=ret=no-vis. §11.1"),
        (0x58dd, 0x59c3, "db", "AnimIdxTablePartySide_58dd",
         "Layer-1 anim-routine index, PARTY-caster side (by skill id). §11.1"),
        (0x59c3, 0x5aa9, "db", "AnimIdxTableEnemySide_59c3",
         "Layer-1 anim-routine index, ENEMY-caster side (by skill id). §11.1"),
        (0x5aa9, 0x5b8f, "db", "AnimIdxTableSpecial_5aa9",
         "Layer-1 anim-routine index, special-phase select ($d9ed==1 && $d9ee==5). §11.1"),
    ],
}


def emit_bank(bank):
    data = load(bank)
    lines = []
    for start, end, kind, label, comment in REGIONS[bank]:
        seg = data[start - 0x4000:end - 0x4000]
        c = f"{comment}  [${bank:02x}:${start:04x}-${end-1:04x}, {end-start} bytes]"
        if kind == "dw":
            lines += dw_lines(seg, start, label, c)
        else:
            lines += db_lines(seg, start, label, c)
        lines.append("")
    return "\n".join(lines)


def verify(bank):
    """Confirm regions are contiguous and report coverage."""
    regs = REGIONS[bank]
    ok = True
    for i in range(len(regs) - 1):
        if regs[i][1] != regs[i + 1][0]:
            print(f"  GAP/OVERLAP between {regs[i][3]} (ends {regs[i][1]:04x}) "
                  f"and {regs[i+1][3]} (starts {regs[i+1][0]:04x})")
            ok = False
    total = regs[-1][1] - regs[0][0]
    print(f"  bank ${bank:02x}: {len(regs)} regions, "
          f"${regs[0][0]:04x}-${regs[-1][1]-1:04x} = {total} bytes contiguous: {ok}")
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bank", type=lambda x: int(x, 16), default=0x5f)
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args()
    if args.verify:
        for bk in REGIONS:
            verify(bk)
        return
    print(emit_bank(args.bank))


if __name__ == "__main__":
    main()
