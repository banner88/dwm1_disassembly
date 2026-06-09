"""Randomize DWM1 stats / skills / names.

Modes:
  light  : shuffle base skills only
  medium : light + level caps + resistances (default)
  chaos  : medium + names within same byte-length, plus family
"""
import argparse
import json
import random
from collections import defaultdict
from pathlib import Path

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["light", "medium", "chaos"], default="medium")
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()
    random.seed(args.seed)

    monsters = json.loads(Path("extracted/monsters_full.json").read_text())
    monster_edits = {}

    # Skill pool shuffle (always)
    all_skills = [s for m in monsters for s in m["base_skills"]]
    random.shuffle(all_skills)
    skills_iter = iter(all_skills)

    # Level caps + resistances (medium+)
    if args.mode in ("medium", "chaos"):
        caps = [m["level_cap"] for m in monsters]; random.shuffle(caps)
        ress = [m["resistances"] for m in monsters]; random.shuffle(ress)
    else:
        caps = [m["level_cap"] for m in monsters]
        ress = [m["resistances"] for m in monsters]

    # Chaos: family
    if args.mode == "chaos":
        FAMILY_IDS = list(range(9))
        random.shuffle(FAMILY_IDS)
        fam_map = {i: FAMILY_IDS[i % 9] for i in range(9)}
    else:
        fam_map = None

    for idx, m in enumerate(monsters):
        e = {
            "level_cap": int(caps[idx]),
            "base_skills": [next(skills_iter) for _ in range(3)],
            "resistances": list(ress[idx]),
        }
        if fam_map is not None:
            orig_fam_id = ["Slime","Dragon","Beast","Flying","Plant","Bug","Devil","Zombie","Material","???"].index(m["family"])
            if orig_fam_id < 9:
                e["family"] = fam_map[orig_fam_id]
        monster_edits[str(m["id"])] = e

    # Chaos: name shuffle within same byte-length groups (so we never overflow)
    text_edits = {}
    if args.mode == "chaos":
        names = monsters  # monsters_full.json already has name_byte_length and name_offset
        groups = defaultdict(list)
        for n in names:
            if n.get("name_byte_length"):
                groups[n["name_byte_length"]].append(n)
        for length, group in groups.items():
            if len(group) <= 1: continue
            new_order = [g["name"] for g in group]
            random.shuffle(new_order)
            for g, new_name in zip(group, new_order):
                text_edits[g["name_offset"]] = new_name

    edits = {
        "monster_stats": monster_edits,
        "text": text_edits,
        "raw_bytes": {},
        "_meta": {"mode": args.mode, "seed": args.seed},
    }
    Path("extracted/edits.json").write_text(json.dumps(edits, indent=2))
    print(f"Wrote {args.mode} randomization (seed={args.seed})")
    print(f"  monster edits: {len(monster_edits)}")
    print(f"  text edits:    {len(text_edits)}")

if __name__ == "__main__":
    main()
