"""Match NPC script IDs to text pointer tables.

For each room, finds which text pointer table(s) contain dialogue
at the indices matching the NPCs' script bytes.

Usage:
    uv run python -m tools.match_npc_text
"""
import json
from pathlib import Path
from collections import defaultdict

def main():
    catalog = json.loads(Path("extracted/npc_catalog.json").read_text())
    all_text = json.loads(Path("extracted/all_text.json").read_text())

    # Build room → script_ids mapping (unique scripts per room, excluding 0xFF)
    room_scripts = defaultdict(set)
    room_names = {}
    for npc in catalog:
        mt = npc["map_type"]
        room_names[mt] = npc.get("room", f"Map_{mt:02X}")
        if npc["script"] != 0xFF:
            room_scripts[mt].add(npc["script"])

    # Build text table index: for each table, what indices have valid text?
    tables = all_text.get("tables", [])
    table_index = []
    for t in tables:
        valid_indices = {}
        for entry in t["entries"]:
            if entry["text"] is not None:
                valid_indices[entry["index"]] = entry["text"][:80]
        table_index.append({
            "label": t["label"],
            "bank": t["bank"],
            "offset": t["table_offset"],
            "count": t["count"],
            "valid": valid_indices,
        })

    print("=" * 90)
    print("NPC SCRIPT → TEXT MATCHING")
    print("=" * 90)

    # For each room, find tables where the script_ids match valid text indices
    matches_found = 0
    room_text_map = {}

    for mt in sorted(room_scripts.keys()):
        scripts = sorted(room_scripts[mt])
        if not scripts:
            continue

        name = room_names.get(mt, f"Map_{mt:02X}")
        max_script = max(scripts)

        # Find tables where ALL script_ids have valid text
        perfect = []
        partial = []

        for ti, t in enumerate(table_index):
            if t["count"] <= max_script:
                continue  # table too small

            hits = sum(1 for s in scripts if s in t["valid"])
            if hits == len(scripts):
                perfect.append((ti, t))
            elif hits > 0 and hits >= len(scripts) * 0.5:
                partial.append((ti, t, hits))

        if perfect or partial:
            print(f"\n--- 0x{mt:02X} {name} --- scripts: {[f'0x{s:02X}' for s in scripts]}")

        if perfect:
            matches_found += 1
            # Show best match (prefer smaller tables = more specific)
            perfect.sort(key=lambda x: x[1]["count"])
            best_ti, best = perfect[0]

            room_text_map[f"0x{mt:02X}"] = {
                "table_bank": best["bank"],
                "table_offset": best["offset"],
                "table_label": best["label"],
            }

            print(f"  ✓ MATCH: {best['label']} (bank {best['bank']} @ {best['offset']}, "
                  f"{best['count']} entries)")
            for s in scripts:
                txt = best["valid"].get(s, "(no text)")
                print(f"    script 0x{s:02X} → {txt!r}")

            if len(perfect) > 1:
                print(f"    ({len(perfect)-1} other possible tables)")

        elif partial:
            partial.sort(key=lambda x: -x[2])
            best_ti, best, hits = partial[0]
            print(f"  ? PARTIAL ({hits}/{len(scripts)} match): "
                  f"{best['label']} (bank {best['bank']} @ {best['offset']})")
            for s in scripts:
                txt = best["valid"].get(s, "(MISSING)")
                marker = "✓" if s in best["valid"] else "✗"
                print(f"    {marker} script 0x{s:02X} → {txt!r}")

    print(f"\n{'=' * 90}")
    print(f"Matched {matches_found}/{len(room_scripts)} rooms to text tables")

    # Save mapping
    out_path = Path("extracted/npc_text_mapping.json")
    out_path.write_text(json.dumps(room_text_map, indent=2))
    print(f"Saved to {out_path}")

    # Also output a combined view: NPC + their likely text
    combined = []
    for npc in catalog:
        mt = npc["map_type"]
        mapping = room_text_map.get(f"0x{mt:02X}")
        text = None
        if mapping and npc["script"] != 0xFF:
            # Find the text
            for t in tables:
                if t["bank"] == mapping["table_bank"] and t["table_offset"] == mapping["table_offset"]:
                    for entry in t["entries"]:
                        if entry["index"] == npc["script"] and entry["text"]:
                            text = entry["text"]
                            break
                    break
        combined.append({**npc, "dialogue_preview": text[:100] if text else None})

    combined_path = Path("extracted/npc_with_text.json")
    combined_path.write_text(json.dumps(combined, indent=2))
    print(f"NPC+text catalog saved to {combined_path}")


if __name__ == "__main__":
    main()
