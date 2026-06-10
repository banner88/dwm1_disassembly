#!/usr/bin/env python3
"""Generate db statements for encounter data in bank $01.

Covers:
  - Gate base pool index ($6A22, 32 bytes)
  - Floor breakpoint pointers ($6A42, 64 bytes)
  - Floor breakpoint data ($6A82, variable, $FF-terminated)
  - Encounter pool data ($6AAE, 128 pools × 26 bytes)
"""
import json, os, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(SCRIPT_DIR, '..', 'data', 'DWM-original.gbc')
ENCOUNTERS_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'encounters.json')
MONSTERS_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'monsters_full.json')
GATE_NAMES_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'gate_names.json')

BANK = 0x01
POOL_ENTRY_SIZE = 26
NUM_POOLS = 128

# Labels referenced from code outside the data region
EMBEDDED_LABELS = {
    0x7407: "Call_001_7407",
    0x7420: "Call_001_7420",
    0x747B: "Call_001_747b",
}


def main():
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    with open(MONSTERS_PATH) as f:
        mon_names = {m['id']: m['name'] for m in json.load(f)}

    gate_names = {}
    try:
        with open(GATE_NAMES_PATH) as f:
            gn = json.load(f)
            if isinstance(gn, list):
                gate_names = {i: g.get('name', f'Gate {i}') if isinstance(g, dict) else str(g) for i, g in enumerate(gn)}
            elif isinstance(gn, dict):
                gate_names = {int(k): v if isinstance(v, str) else v.get('name', f'Gate {k}') for k, v in gn.items()}
    except:
        pass

    enc_data = {}
    try:
        with open(ENCOUNTERS_PATH) as f:
            enc_data = json.load(f)
    except:
        pass

    base = BANK * 0x4000
    lines = []

    # ===== GATE BASE POOL INDEX TABLE =====
    lines.append("; ---------------------------------------------------------------")
    lines.append("; Encounter Data ($6A22-$77AD)")
    lines.append("; ---------------------------------------------------------------")
    lines.append("")
    lines.append("; Gate base pool index table ($6A22)")
    lines.append("; 32 bytes: gate_id → base pool index in pool data at $6AAE")
    lines.append("GateBasePoolIndex:")
    offset = base + (0x6A22 - 0x4000)
    data = rom[offset:offset + 32]
    for i in range(0, 32, 8):
        chunk = data[i:i + 8]
        vals = ", ".join(str(b) for b in chunk)
        gnames = [gate_names.get(i + j, f"G{i+j}") for j in range(8)]
        comment = ", ".join(gnames)
        lines.append(f"    db {vals}  ; Gates {i}-{i+7}")
    lines.append("")

    # ===== FLOOR BREAKPOINT POINTERS =====
    lines.append("; Floor breakpoint table pointers ($6A42)")
    lines.append("; 32 × dw: gate_id → pointer to floor threshold list")
    lines.append("GateFloorBreakpoints:")
    offset = base + (0x6A42 - 0x4000)
    data = rom[offset:offset + 64]
    for i in range(32):
        ptr = data[i * 2] | (data[i * 2 + 1] << 8)
        gname = gate_names.get(i, f"Gate {i}")
        lines.append(f"    dw ${ptr:04X}  ; [{i}] {gname}")
    lines.append("")

    # ===== FLOOR BREAKPOINT DATA =====
    lines.append("; Floor breakpoint data ($6A82)")
    lines.append("; Variable-length lists of floor thresholds, $FF-terminated")
    lines.append("; Referenced by pointers above")
    lines.append("FloorBreakpointData:")
    bp_start = base + (0x6A82 - 0x4000)
    bp_end = base + (0x6AAE - 0x4000)
    bp_data = rom[bp_start:bp_end]
    for i in range(0, len(bp_data), 16):
        chunk = bp_data[i:min(i + 16, len(bp_data))]
        vals = ", ".join(f"${b:02X}" for b in chunk)
        addr = 0x6A82 + i
        lines.append(f"    db {vals}  ; ${addr:04X}")
    lines.append("")

    # ===== ENCOUNTER POOL DATA =====
    lines.append("; ---------------------------------------------------------------")
    lines.append("; Encounter Pool Data ($6AAE)")
    lines.append("; 128 pools x 26 bytes = 3328 bytes")
    lines.append(";")
    lines.append("; Format (26 bytes per pool):")
    lines.append(";   +$00-$09  Header (10 bytes)")
    lines.append(";   +$0A-$13  EID slots (5 x 2 bytes LE, $0000 = unused)")
    lines.append(";   +$14-$18  Weights (5 x 1 byte, 0 = unused)")
    lines.append(";   +$19      Unknown (usually 8 or 15)")
    lines.append("; ---------------------------------------------------------------")
    lines.append("")
    lines.append("EncounterPoolData:")

    pool_base = base + (0x6AAE - 0x4000)

    # Build label lookup for embedded labels
    label_by_pool = {}
    for addr, name in EMBEDDED_LABELS.items():
        pool_offset = addr - 0x6AAE
        pool_idx = pool_offset // POOL_ENTRY_SIZE
        byte_idx = pool_offset % POOL_ENTRY_SIZE
        label_by_pool.setdefault(pool_idx, []).append((byte_idx, name))

    # Find which gate each pool belongs to
    gate_base_offset = base + (0x6A22 - 0x4000)
    gate_bases = list(rom[gate_base_offset:gate_base_offset + 32])

    def pool_gate(pool_idx):
        """Find which gate a pool belongs to."""
        for g in range(31, -1, -1):
            if pool_idx >= gate_bases[g]:
                return g, gate_names.get(g, f"Gate {g}")
        return -1, "?"

    for i in range(NUM_POOLS):
        offset = pool_base + i * POOL_ENTRY_SIZE
        raw = rom[offset:offset + POOL_ENTRY_SIZE]
        pool_addr = 0x6AAE + i * POOL_ENTRY_SIZE

        header = list(raw[0:10])
        eids = [raw[10 + j * 2] | (raw[10 + j * 2 + 1] << 8) for j in range(5)]
        weights = list(raw[20:25])
        extra = raw[25]

        gate_id, gname = pool_gate(i)

        # Monster names for EIDs
        eid_strs = []
        for eid in eids:
            if eid == 0:
                eid_strs.append("(none)")
            else:
                # Look up species from enemy stats
                es_offset = 0x14 * 0x4000 + (0x4C1D - 0x4000) + eid * 25
                species = rom[es_offset]
                eid_strs.append(mon_names.get(species, f"sp{species}"))

        lines.append(f"; --- Pool {i} (${pool_addr:04X}): {gname} ---")

        has_labels = i in label_by_pool
        if has_labels:
            labels = sorted(label_by_pool[i])

        label_name = f"EncounterPool_{i:03d}"
        lines.append(f"{label_name}:")

        if not has_labels:
            h_str = ", ".join(f"${b:02X}" for b in header)
            lines.append(f"    db {h_str}  ; Header")
            eid_vals = ", ".join(str(e) for e in eids)
            eid_names = ", ".join(eid_strs)
            lines.append(f"    dw {eid_vals}  ; EIDs: {eid_names}")
            w_str = ", ".join(str(w) for w in weights)
            lines.append(f"    db {w_str}  ; Weights")
            lines.append(f"    db {extra}  ; Extra")
        else:
            # Need to handle embedded labels within this entry
            # Output byte by byte for the affected regions
            byte_labels = {b: n for b, n in labels}
            # Header
            if any(0 <= b < 10 for b in byte_labels):
                lines.append("    ; Header")
                pos = 0
                while pos < 10:
                    if pos in byte_labels:
                        lines.append(f"{byte_labels[pos]}:")
                    next_break = 10
                    for lb in byte_labels:
                        if lb > pos and lb < next_break:
                            next_break = lb
                    chunk = raw[pos:next_break]
                    vals = ", ".join(f"${b:02X}" for b in chunk)
                    lines.append(f"    db {vals}")
                    pos = next_break
            else:
                h_str = ", ".join(f"${b:02X}" for b in header)
                lines.append(f"    db {h_str}  ; Header")

            # EIDs — use db when labels split word boundaries
            if any(10 <= b < 20 for b in byte_labels):
                lines.append("    ; EIDs (split by label)")
                pos = 10
                while pos < 20:
                    if pos in byte_labels:
                        lines.append(f"{byte_labels[pos]}:")
                    next_break = 20
                    for lb in byte_labels:
                        if lb > pos and lb < next_break:
                            next_break = lb
                    chunk = list(raw[pos:next_break])
                    vals = ", ".join(f"${b:02X}" for b in chunk)
                    lines.append(f"    db {vals}")
                    pos = next_break
            else:
                eid_vals = ", ".join(str(e) for e in eids)
                lines.append(f"    dw {eid_vals}  ; EIDs")

            # Weights + extra
            if any(20 <= b < 26 for b in byte_labels):
                lines.append("    ; Weights + extra")
                pos = 20
                while pos < 26:
                    if pos in byte_labels:
                        lines.append(f"{byte_labels[pos]}:")
                    next_break = 26
                    for lb in byte_labels:
                        if lb > pos and lb < next_break:
                            next_break = lb
                    chunk = raw[pos:next_break]
                    vals = ", ".join(str(b) for b in chunk)
                    lines.append(f"    db {vals}")
                    pos = next_break
            else:
                w_str = ", ".join(str(w) for w in weights)
                lines.append(f"    db {w_str}  ; Weights")
                lines.append(f"    db {extra}  ; Extra")

        lines.append("")

    sys.stdout.write("\n".join(lines) + "\n")


if __name__ == '__main__':
    main()
