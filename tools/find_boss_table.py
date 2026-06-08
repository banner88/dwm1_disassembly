"""Search ROM for boss EID table using known boss enemy_stats_ids.

We know these boss EIDs from watchpointing $DA03:
  Gate 0 (Beginning) → EID 11 (0x0B)
  Gate 1 (Villager)  → EID 31 (0x1F)
  Gate 2 (Talisman)  → EID 32 (0x20)
  Gate 3 (Memories)  → EID 51 (0x33)
  Gate 4 (Bewilder)  → EID 53 (0x35)

This script searches for any location in ROM where these values appear
at a consistent stride (1 byte, 2 bytes, 4 bytes, 8 bytes, etc.).

Usage:
  uv run python -m tools.find_boss_table
"""

from pathlib import Path

rom_data = Path("data/DWM-original.gbc").read_bytes()

# Known boss EIDs: (gate_index, eid_value)
KNOWN = [
    (0, 0x0B),   # Healer
    (1, 0x1F),   # Dragon
    (2, 0x20),   # Golem
    (3, 0x33),   # MadCat
    (4, 0x35),   # FaceTree
]

rom_len = len(rom_data)

print(f"ROM size: {rom_len} bytes (0x{rom_len:X})")
print(f"Searching for boss EID table with {len(KNOWN)} known values...")
print()

# Strategy 1: Search for values at a fixed stride from a base address
# If table[gate] is at base + gate * stride, then:
#   rom[base + 0*stride] == 0x0B
#   rom[base + 1*stride] == 0x1F
#   rom[base + 2*stride] == 0x20
#   rom[base + 3*stride] == 0x33
#   rom[base + 4*stride] == 0x35

results = []

for stride in range(1, 64):  # try strides 1-63 bytes
    for base in range(rom_len - 5 * stride):
        match = True
        for gate_idx, eid_val in KNOWN:
            addr = base + gate_idx * stride
            if addr >= rom_len:
                match = False
                break
            if rom_data[addr] != eid_val:
                match = False
                break
        if match:
            # Verify: read all 32 potential entries
            entries = []
            valid = True
            for g in range(32):
                a = base + g * stride
                if a >= rom_len:
                    valid = False
                    break
                entries.append(rom_data[a])

            if valid:
                results.append((base, stride, entries))

print(f"Found {len(results)} candidate locations\n")

# Filter: remove candidates where most values are 0x00 or 0xFF (unlikely for a real table)
filtered = []
for base, stride, entries in results:
    nonzero = sum(1 for e in entries[:31] if 0 < e < 0xFF)
    if nonzero >= 20:  # at least 20 of 31 gates should have real EIDs
        filtered.append((base, stride, entries))

print(f"After filtering (≥20 non-zero entries): {len(filtered)} candidates\n")

# Also try 2-byte LE values (EID stored as 16-bit)
results_16 = []
for stride in range(2, 64):
    for base in range(rom_len - 5 * stride):
        match = True
        for gate_idx, eid_val in KNOWN:
            addr = base + gate_idx * stride
            if addr + 1 >= rom_len:
                match = False
                break
            val = rom_data[addr] | (rom_data[addr + 1] << 8)
            if val != eid_val:
                match = False
                break
        if match:
            entries = []
            valid = True
            for g in range(32):
                a = base + g * stride
                if a + 1 >= rom_len:
                    valid = False
                    break
                entries.append(rom_data[a] | (rom_data[a + 1] << 8))
            if valid:
                # Filter: reasonable EID values (0-500)
                reasonable = sum(1 for e in entries[:31] if 0 < e < 500)
                if reasonable >= 20:
                    results_16.append((base, stride, entries))

print(f"16-bit search: {len(results_16)} candidates\n")

# Print all results
for label, res_list in [("8-bit", filtered), ("16-bit LE", results_16)]:
    if not res_list:
        continue
    print(f"{'=' * 80}")
    print(f"  {label} RESULTS")
    print(f"{'=' * 80}")
    for base, stride, entries in res_list:
        # Calculate bank:address
        if base < 0x4000:
            bank_str = f"$00:${base:04X}"
        else:
            bank = base // 0x4000
            offset = 0x4000 + (base % 0x4000)
            bank_str = f"${bank:02X}:${offset:04X}"

        print(f"\n  Base: 0x{base:05X} ({bank_str})  Stride: {stride}")
        print(f"  {'Gate':>5s}  {'EID':>5s}  {'Match':>6s}")
        print(f"  {'─' * 20}")
        for g in range(min(32, len(entries))):
            known_val = dict(KNOWN).get(g)
            mark = " ✓" if known_val is not None and entries[g] == known_val else ""
            if known_val is not None and entries[g] != known_val:
                mark = " ✗"
            print(f"  {g:5d}  {entries[g]:5d}{mark}")
