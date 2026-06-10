#!/usr/bin/env python3
"""Generate db statements for exp and growth tables in bank $13.

Covers:
  - Experience tables at $41E6 (32 tables × 297 bytes)
  - Growth rate tables at $6706 (32 tables × 99 bytes)
"""
import os, sys

ROM_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data', 'DWM-original.gbc')

BANK = 0x13
EXP_TABLE_ADDR = 0x41E6
EXP_TABLE_SIZE = 297  # 99 levels × 3 bytes
NUM_EXP_TABLES = 32
GROWTH_TABLE_ADDR = 0x6706
GROWTH_TABLE_SIZE = 99  # 99 levels × 1 byte
NUM_GROWTH_TABLES = 32


def main():
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    base = BANK * 0x4000
    lines = []

    # ===== EXP TABLES =====
    lines.append("; ---------------------------------------------------------------")
    lines.append("; Experience Curve Tables ($41E6)")
    lines.append("; 32 tables x 297 bytes (99 levels x 3 bytes) = 9504 bytes")
    lines.append("; Each entry: 24-bit LE cumulative exp required for that level")
    lines.append("; Monster info byte +$02 (exp_table) selects which table to use")
    lines.append("; ---------------------------------------------------------------")
    lines.append("")
    lines.append("ExpCurveTables:")

    for t in range(NUM_EXP_TABLES):
        offset = base + (EXP_TABLE_ADDR - 0x4000) + t * EXP_TABLE_SIZE
        lines.append(f"")
        lines.append(f"; --- Exp Curve {t} ---")
        lines.append(f"ExpCurve_{t:02d}:")

        for lv_start in range(0, 99, 10):
            lv_end = min(lv_start + 10, 99)
            vals = []
            for lv in range(lv_start, lv_end):
                b0 = rom[offset + lv * 3]
                b1 = rom[offset + lv * 3 + 1]
                b2 = rom[offset + lv * 3 + 2]
                exp = b0 | (b1 << 8) | (b2 << 16)
                vals.append(f"${b0:02X},${b1:02X},${b2:02X}")
            db_vals = ", ".join(vals)
            lines.append(f"    db {db_vals}  ; Lv {lv_start+1}-{lv_end}")

    # ===== GROWTH TABLES =====
    lines.append("")
    lines.append("; ---------------------------------------------------------------")
    lines.append("; Stat Growth Tables ($6706)")
    lines.append("; 32 tables x 99 bytes = 3168 bytes")
    lines.append("; Each byte: stat increment when leveling to that level")
    lines.append("; Monster info bytes +$09-$0E index into these tables")
    lines.append("; ---------------------------------------------------------------")
    lines.append("")
    lines.append("StatGrowthTables:")

    for t in range(NUM_GROWTH_TABLES):
        offset = base + (GROWTH_TABLE_ADDR - 0x4000) + t * GROWTH_TABLE_SIZE
        lines.append(f"")
        lines.append(f"; --- Growth Curve {t} ---")
        lines.append(f"GrowthCurve_{t:02d}:")

        for lv_start in range(0, 99, 20):
            lv_end = min(lv_start + 20, 99)
            vals = [str(rom[offset + lv]) for lv in range(lv_start, lv_end)]
            db_vals = ", ".join(vals)
            lines.append(f"    db {db_vals}  ; Lv {lv_start+1}-{lv_end}")

    sys.stdout.write("\n".join(lines) + "\n")


if __name__ == '__main__':
    main()
