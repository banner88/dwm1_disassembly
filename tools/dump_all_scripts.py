"""Dump ALL NPC scripts from banks $0C-$0F into extracted/all_scripts.json.

Replaces the previous frozen-source file, which was a PARTIAL dump
(209 scripts over 56 map types, produced by lost in-session code with an
NPC-data join). This tool dumps the complete set — every script reachable
from every map type's pointer table — and its count is acceptance-tested
against the asm label census (518 *_ScriptNN labels in bank_00c-00f.asm).

Routing (BANK04_SCRIPT_ENGINE.md / ARCHITECTURE.md):
  map_type < $06 -> bank $0C;  < $20 -> $0D;  < $40 -> $0E;  >= $40 -> $0F
  master table: bank:$41BA + map_type*2 -> per-map script ptr table
  script data:  dw words; $FFxx = opcode xx, $FFFF = end, else text id/param

Schema per entry:
  map_type, map_name, bank, script_id, ptr_table_addr, data_addr,
  words (raw dw stream as hex), commands (decoded: opcode/text/param/end)

Usage:
  python3 -m tools.dump_all_scripts
"""
import json
from pathlib import Path

ROM_PATH = Path("data/DWM-original.gbc")
MASTER_TABLE = 0x41BA

# import shared knowledge from the decompiler
import sys
sys.path.insert(0, str(Path(__file__).parent))
from decompile_script import MAP_NAMES, PARAM_COUNTS  # type: ignore

# Simple opcode name table (reconciled with handler analysis 2026-06-13)
OPCODE_NAMES = {
    0x00: "if_flag_clear", 0x01: "if_flag_set", 0x02: "clear_flag",
    0x03: "set_flag", 0x04: "screen_effect", 0x05: "battle",
    0x06: "inc_counter", 0x07: "init_dialog", 0x08: "nop",
    0x09: "delay", 0x0A: "npc_move_x", 0x0B: "npc_move_y",
    0x0C: "npc_facing", 0x0D: "npc_write", 0x0E: "branch_by_screen",
    0x0F: "map_transition", 0x10: "npc_moveto", 0x11: "npc_moveto2",
    0x12: "write_ram", 0x13: "write_ram2", 0x14: "goto",
    0x15: "cond_branch", 0x16: "return", 0x17: "gate_setup",
    0x18: "fade", 0x19: "wait_movement", 0x1A: "npc_walk_x",
    0x1B: "npc_walk_y", 0x1C: "trigger_anim", 0x1D: "lock_movement",
    0x1E: "unlock_movement", 0x1F: "arena_battle_setup",
    0x20: "set_battle_mode", 0x21: "screen_setup", 0x22: "begin_walk",
    0x24: "update_screen_vram", 0x26: "suppress_movement",
    0x27: "post_battle_check", 0x28: "check_storage_full",
    0x29: "add_monster", 0x2A: "give_item", 0x2B: "check_monster_level",
    0x2C: "check_inv_full",
    0x2D: "monster_slot_dialogue", 0x31: "check_party_level",
    0x33: "skip_data", 0x35: "boss_encounter_setup", 0x36: "setup_boss",
    0x37: "check_story_region", 0x3A: "gate_transition",
    0x3B: "map_transition_fade", 0x3C: "set_secondary_delay",
    0x3D: "clear_secondary_delay", 0x40: "check_monster_bgm",
    0x41: "set_bgm", 0x42: "save_map_return",
    0x44: "npc_set_pos_and_face",
    0x46: "check_dungeon_flags", 0x47: "npc_buffer_write",
    0x48: "npc_hide", 0x49: "npc_show", 0x4A: "read_saved_bgm",
    0x4B: "restore_bgm", 0x4C: "long_delay", 0x4D: "set_long_delay",
    0x4E: "save_gate_info", 0x51: "check_and_branch",
    0x59: "battle3", 0x5A: "trigger_battle3", 0x61: "call_script_bank_e2",
}


def bank_for(map_type: int) -> int:
    if map_type < 0x06:
        return 0x0C
    if map_type < 0x20:
        return 0x0D
    if map_type < 0x40:
        return 0x0E
    return 0x0F


def rw(rom: bytes, bank: int, addr: int) -> int:
    f = bank * 0x4000 + (addr - 0x4000)
    return rom[f] | (rom[f + 1] << 8)


def dump_script(rom: bytes, bank: int, start: int):
    """Decode one script's dw stream until $FFFF (with safety cap)."""
    words, commands = [], []
    addr = start
    pending_params = 0
    for _ in range(512):
        if not (0x4000 <= addr < 0x7FFF):
            break
        w = rw(rom, bank, addr)
        words.append(f"${w:04X}")
        if pending_params:
            commands.append({"addr": f"${addr:04X}", "type": "param",
                             "value": w})
            pending_params -= 1
        elif w == 0xFFFF:
            commands.append({"addr": f"${addr:04X}", "type": "end"})
            addr += 2
            break
        elif (w >> 8) == 0xFF:
            op = w & 0xFF
            commands.append({"addr": f"${addr:04X}", "type": "opcode",
                             "opcode": op,
                             "name": OPCODE_NAMES.get(op, f"op_{op:02X}")})
            pending_params = PARAM_COUNTS.get(op, 0)
        else:
            commands.append({"addr": f"${addr:04X}", "type": "text_or_param",
                             "value": w})
        addr += 2
    return words, commands


def main():
    rom = ROM_PATH.read_bytes()
    out = []
    for map_type in range(0x6B):  # original map types $00-$6A
        bank = bank_for(map_type)
        tbl_ptr = rw(rom, bank, MASTER_TABLE + map_type * 2)
        if not (0x4000 <= tbl_ptr < 0x8000):
            continue
        # read script pointers until the first non-bank-local word
        ptrs, a = [], tbl_ptr
        while len(ptrs) < 100:
            p = rw(rom, bank, a)
            if not (0x4000 <= p < 0x8000):
                break
            ptrs.append(p)
            a += 2
        name = MAP_NAMES.get(map_type, f"Map{map_type:02X}")
        for sid, ptr in enumerate(ptrs):
            words, commands = dump_script(rom, bank, ptr)
            out.append({
                "map_type": map_type,
                "map_name": name,
                "bank": bank,
                "script_id": sid,
                "ptr_table_addr": f"${tbl_ptr + sid * 2:04X}",
                "data_addr": f"${ptr:04X}",
                "command_count": len(commands),
                "words": words,
                "commands": commands,
            })
    Path("extracted/all_scripts.json").write_text(json.dumps(out, indent=1))
    n_maps = len({e["map_type"] for e in out})
    print(f"Saved extracted/all_scripts.json: {len(out)} scripts "
          f"across {n_maps} map types")
    return out


if __name__ == "__main__":
    main()
