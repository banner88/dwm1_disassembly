"""Internal gate ID -> gate name, derived from the gate-indexed ROM table (S100 rewrite).

WHY THE REWRITE (S100, DOC_AUDIT S100): the old version keyed gate names on the
boss FIGHT/JOIN redirect table at $14:$4897, read as if it were indexed by gate
id. It is not: that table has one row per boss (the Gate of Demolition has two,
Hargon and Sidoh), so every gate from 23 up came out one name late (23 "Demolition
(Hargon)", 24 "Demolition (Sidoh)", 25 "Mastermind" ... 31 "Unused"). A second,
hand-written list (tools/gate_reference.py) had its own error in the other
direction (gates 12-17 in FAQ chapter order instead of ROM id order).

THE GATE-INDEXED SOURCE: GateFloorDataTable ($16:$70A6, 32 x 8 B, indexed by
wGateID — the loader at $16:$5B72 reads it with wGateID*8; GATE_GENERATION.md §1).
Two of its fields identify a gate independently of each other:
  byte 3 = last_floor (the gate's floor count INCLUDING the boss floor: the boss
           floor is served when wCurrentFloor+1 == last_floor, wCurrentFloor
           counting from 0) — cross-checked here against the FAQ "Levels: N"
           box of every gate;
  byte 4 = boss map type (the bank $0B room served on the boss floor) — named
           through dwm/map_names.py.
Every gate must agree on BOTH or the tool fails (non-zero exit).

Output: extracted/gate_names.json
  {"_generator": ..., "gates": [{"id", "name", "faq_name", "floors",
    "boss_map", "boss_room", "floor_types", "depth_tier", "boss_spawn", "row",
    "cleared_flag", "cleared_flags"} x 32]}

S117 (ROADMAP NG2): + the gate's CLEARED flag, read from the boss room's own
scripts in the ROM (the script decoder of tools/dump_all_scripts.py): every
vanilla boss win tail ends `set_flag F` ... `write_ram $D92B 7` (the castle
return) — F is the gate's cleared flag, the one the portal rooms' swirl
objects follow (the boss script also moves the portal room's step counter:
measured S117, Villager/Talisman room $24, counter $D969). The Medal Gate's
GateFloorDataTable boss map is the KingSlime decision room $40; its bosses
fight in $41, so both rooms are scanned. "cleared_flags" lists every such
flag in script order (the Gate of Demolition has two: $27 Hargon, $28 Sidoh
when $D9E3 = $C7); "cleared_flag" = the first; null for the unused gate 31.
Readers: tools/dump_room_data.py, tools/gen_encounter_db.py, editor2 Gates tab
(editor2/core/gates.py).

Usage:  python3 -m tools.map_gate_names [--check]
  --check / --selftest  exit non-zero if extracted/gate_names.json differs from
           the ROM derivation (verify_integrity check 5).
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
from dwm.map_names import MAP_NAMES  # noqa: E402

ROM_PATH = ROOT / "data" / "DWM-original.gbc"
OUT = ROOT / "extracted" / "gate_names.json"

GATE_TABLE_BANK, GATE_TABLE_ADDR, GATE_ROW = 0x16, 0x70A6, 8

# boss map type (ROM fact, GateFloorDataTable byte 4) -> (editor name, FAQ box
# title, FAQ "Levels:" value). The FAQ column is the independent witness.
BOSS_MAP_TO_GATE = {
    0x30: ("Gate of Beginning", "Gate 1 - Beginning", 5),
    0x31: ("Gate of Villager", "Gate 2 - Villager", 5),
    0x32: ("Gate of Talisman", "Gate 3 - Talisman", 6),
    0x33: ("Gate of Memories", "Gate 4 - Memories", 5),
    0x34: ("Gate of Bewilder", "Gate 5 - Bewilder", 6),
    0x35: ("Bazaar Gate", "Bazaar Gate", 9),
    0x36: ("Gate of Peace", "Gate 6 - Peace", 8),
    0x37: ("Gate of Bravery", "Gate 7 - Bravery", 9),
    0x38: ("Well Gate", "Well Gate", 12),
    0x39: ("Gate of Strength", "Gate 9 - Strength", 11),
    0x3C: ("Gate of Anger", "Gate 8 - Anger", 11),
    0x10: ("Farm Gate", "Monster Farm Gate", 12),        # boss = the Copycat House room
    0x3B: ("Gate of Joy", "Gate 10 - Joy", 14),
    0x3A: ("Gate of Wisdom", "Gate 11 - Wisdom", 15),
    0x3D: ("Arena - Left Gate", "Goopi's Gate", 16),
    0x3E: ("Gate of Happiness", "Gate 12 - Happiness", 18),
    0x3F: ("Gate of Temptation", "Gate 13 - Temptation", 20),
    0x40: ("Medal Gate", "Medal King's Gate", 19),        # boss room = KingSlime decision room
    0x42: ("Gate of Labyrinth", "Gate 14 - Labyrinth", 23),
    0x43: ("Gate of Judgement", "Gate 15 - Judgement", 25),
    0x44: ("Library Gate", "Library Gate", 25),
    0x45: ("Gate of Reflection", "Gate 16 - Reflection", 29),
    0x46: ("Gate of Ambition", "Gate 17 - Ambition", 30),
    0x47: ("Gate of Demolition", "Gate 18 - Demolition", 29),
    0x48: ("Gate of Mastermind", "Gate 19 - Mastermind", 27),
    0x49: ("Gate of Control", "Gate 20 - Control", 30),
    0x4A: ("Gate of Extinction", "Gate 21 - Extinction", 30),
    0x4B: ("Gate of Sleep", "Gate 22 - Sleep", 30),
    0x4C: ("Bazaar Edge Gate", "Bazaar Gate 2", 30),
    0x4D: ("Arena - Right Gate", "Goopi's Gate 2", 27),
    0x4E: ("Old Man's Gate", "Grandpa's Gate", 30),
    0x4F: ("Unused Gate", "??? (99 floors)", 99),
}


def cleared_flags(rom: bytes, boss_map: int) -> list:
    """Flags a boss room's scripts set right before `write_ram $D92B 7` (the
    vanilla boss-win tail) — within the 12 script words before it."""
    from tools.dump_all_scripts import bank_for, rw, dump_script, MASTER_TABLE
    found = []
    for mt in (boss_map, boss_map + 1) if boss_map == 0x40 else (boss_map,):
        bank = bank_for(mt)
        tbl = rw(rom, bank, MASTER_TABLE + mt * 2)
        if not 0x4000 <= tbl < 0x8000:
            continue
        a = tbl
        for _ in range(100):
            ptr = rw(rom, bank, a)
            if not 0x4000 <= ptr < 0x8000:
                break
            a += 2
            words = [int(w[1:], 16) for w in dump_script(rom, bank, ptr)[0]]
            for i in range(len(words) - 2):
                if words[i:i + 3] == [0xFF12, 0xD92B, 0x0007]:
                    back = words[max(0, i - 12):i]
                    fl = [back[j + 1] for j in range(len(back) - 1) if back[j] == 0xFF03]
                    if fl and fl[-1] not in found:
                        found.append(fl[-1])
    return found


# S122 (ROADMAP NG2 residual a): the vanilla win tail after `write_ram $D92B 7`
# — the boss script's story bookkeeping (the portal room's step counter, the
# boss room's state, "both gates of this portal cleared" tests) up to its first
# op that is not bookkeeping (close_text / the warp …). A re-bossed vanilla
# gate's custom boss win replays it (bank $76 GateBossWin -> RunWinTail).
WIN_TAIL_OPS = {0x00, 0x01, 0x02, 0x03, 0x12, 0x13, 0x14}


def _arity():
    d = json.loads((ROOT / "extracted" / "script_param_counts.json").read_text())
    return {int(k, 16): v["counts"][0] for k, v in d["ops"].items()}


def win_tails(rom: bytes, boss_map: int) -> list:
    """[{flag, bank, start, ops: [[addr, op, [params]], …]}] — every boss-room
    script's win tail (ops reachable from the word after `$FF12 $D92B $0007`;
    branch targets followed; an op outside WIN_TAIL_OPS ends a path and is
    listed with op = that opcode and no params, as a stop). Deduplicated by
    content (the Medal Gate's three boss scripts share one tail)."""
    from tools.dump_all_scripts import bank_for, rw, dump_script, MASTER_TABLE
    ar = _arity()
    out, seen_ops = [], set()
    for mt in (boss_map, boss_map + 1) if boss_map == 0x40 else (boss_map,):
        bank = bank_for(mt)
        tbl = rw(rom, bank, MASTER_TABLE + mt * 2)
        if not 0x4000 <= tbl < 0x8000:
            continue
        a = tbl
        for _ in range(100):
            ptr = rw(rom, bank, a)
            if not 0x4000 <= ptr < 0x8000:
                break
            a += 2
            cmds = dump_script(rom, bank, ptr)[1]
            for i, c in enumerate(cmds):
                if c.get("type") != "opcode" or c.get("opcode") != 0x12:
                    continue
                pa = [x.get("value") for x in cmds[i + 1:i + 3]]
                if pa != [0xD92B, 0x0007]:
                    continue
                start = int(c["addr"][1:], 16) + 6
                flag = None
                for b in cmds[max(0, i - 24):i]:
                    if b.get("type") == "opcode" and b.get("opcode") == 0x03:
                        k = cmds.index(b)
                        flag = cmds[k + 1].get("value")
                ops, todo, done = {}, [start], set()
                while todo:
                    at = todo.pop()
                    while at not in done and 0x4000 <= at < 0x8000:
                        done.add(at)
                        w = rw(rom, bank, at)
                        if w >> 8 != 0xFF:
                            ops[at] = [at, w, []]
                            break
                        op = w & 0xFF
                        if op not in WIN_TAIL_OPS:
                            ops[at] = [at, op, []]
                            break
                        n = ar[op]
                        prm = [rw(rom, bank, at + 2 + 2 * j) for j in range(n)]
                        ops[at] = [at, op, prm]
                        if op in (0x00, 0x01):
                            todo.append(prm[1])
                        if op == 0x14:
                            todo.append(prm[0])
                            break
                        at += 2 + 2 * n
                def rel(o):        # flow targets relative to the tail's start
                    prm = list(o[2])
                    if o[1] in (0x00, 0x01):
                        prm[1] -= start
                    elif o[1] == 0x14:
                        prm[0] -= start
                    return (o[0] - start, o[1], tuple(prm))
                key = tuple(rel(o) for o in sorted(ops.values()))
                if (flag, key) in seen_ops:
                    continue
                seen_ops.add((flag, key))
                out.append({"flag": None if flag is None else f"0x{flag:04X}",
                            "bank": f"0x{bank:02X}", "start": f"0x{start:04X}",
                            "ops": [[f"0x{o[0]:04X}", o[1], [f"0x{x:04X}" for x in o[2]]]
                                    for o in sorted(ops.values())]})
    return out


def derive(rom: bytes) -> dict:
    base = GATE_TABLE_BANK * 0x4000 + GATE_TABLE_ADDR - 0x4000
    gates, problems = [], []
    for g in range(32):
        row = rom[base + g * GATE_ROW: base + (g + 1) * GATE_ROW]
        ft1, ft2, ft3, last, boss, sx, sy, tier = row
        if boss not in BOSS_MAP_TO_GATE:
            problems.append(f"gate {g}: boss map ${boss:02X} not in the name table")
            continue
        name, faq, faq_levels = BOSS_MAP_TO_GATE[boss]
        if faq_levels != last:
            problems.append(f"gate {g} ({name}): ROM floors {last} != FAQ Levels {faq_levels}")
        gates.append({
            "id": g,
            "name": name,
            "faq_name": faq,
            "floors": last,
            "boss_map": f"0x{boss:02X}",
            "boss_room": MAP_NAMES.get(boss, f"map ${boss:02X}"),
            "floor_types": [ft1, ft2, ft3],
            "depth_tier": tier,
            # S101: the boss room's arrival TILE (absolute; entry 5 boss path
            # writes 16*b+8 pixels) and the raw 8-byte row, so the compiler can
            # re-emit the table byte-identically (patches/bank_016.asm region
            # gate_floor_table) without reading the ROM.
            "boss_spawn": [sx, sy],
            "row": row.hex(),
        })
        cf = cleared_flags(rom, boss)
        gates[-1]["cleared_flag"] = f"0x{cf[0]:04X}" if cf else None
        gates[-1]["cleared_flags"] = [f"0x{x:04X}" for x in cf]
        gates[-1]["win_tails"] = win_tails(rom, boss)
    if len({x["boss_map"] for x in gates}) != len(gates):
        problems.append("two gates share a boss map")
    if problems:
        raise SystemExit("map_gate_names: ROM/FAQ disagreement:\n  " + "\n  ".join(problems))
    return {
        "_generator": "tools/map_gate_names.py (S100) from data/DWM-original.gbc "
                      "GateFloorDataTable $16:$70A6 (floors byte 3 + boss map byte 4; "
                      "S101: + boss_spawn bytes 5/6 + the raw row; S117: + cleared_flag(s) "
                      "from the boss rooms' win tails; S122: + win_tails, the tails' "
                      "bookkeeping ops), "
                      "cross-checked vs FULL_FAQ.txt 'Levels:'",
        "gates": gates,
    }


def load_names(path=OUT) -> dict:
    """{gate id: name} from gate_names.json (any historical shape)."""
    gn = json.loads(Path(path).read_text())
    if isinstance(gn, dict) and "gates" in gn:
        return {x["id"]: x["name"] for x in gn["gates"]}
    if isinstance(gn, list):
        return {i: (g.get("name") if isinstance(g, dict) else str(g)) for i, g in enumerate(gn)}
    return {int(k): v for k, v in gn.items() if not str(k).startswith("_")}


def main():
    rom = ROM_PATH.read_bytes()
    data = derive(rom)
    text = json.dumps(data, indent=1) + "\n"
    if "--check" in sys.argv or "--selftest" in sys.argv:
        if not OUT.exists() or OUT.read_text() != text:
            raise SystemExit("map_gate_names --check: extracted/gate_names.json is stale")
        print("map_gate_names --check: OK (32 gates, ROM floors == FAQ, boss maps unique)")
        return
    OUT.write_text(text)
    for x in data["gates"]:
        print(f"{x['id']:3d}  {x['floors']:3d} fl  boss {x['boss_map']}  {x['name']}")
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
