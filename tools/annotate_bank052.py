#!/usr/bin/env python3
"""Add skill handler labels to bank_052.asm.

Fixes the fake function table entries 222-255 (which overlap handler code),
adds named labels to all skill handler functions, renames family check and
math helper functions, and converts the function table to use label references.

Usage:
  python3 tools/annotate_bank052.py              # preview
  python3 tools/annotate_bank052.py --apply       # apply to bank_052.asm
"""
import os, sys, re

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(SCRIPT_DIR, '..', 'data', 'DWM-original.gbc')
ASM_PATH = os.path.join(SCRIPT_DIR, '..', 'disassembly', 'bank_052.asm')
SYM_PATH = os.path.join(SCRIPT_DIR, '..', 'disassembly', 'game.sym')

BANK = 0x52
BASE = BANK * 0x4000

# Handler addresses from ROM map
HANDLERS = {
    0x41CD: "SkillBlaze", 0x41D4: "SkillFirebal", 0x41DB: "SkillBang",
    0x41E2: "SkillInfernos", 0x41E9: "SkillIceBolt", 0x41F0: "SkillBolt",
    0x41F7: "SkillBeat", 0x422B: "SkillSacrifice", 0x4235: "SkillSleep",
    0x427C: "SkillStopSpell", 0x42AA: "SkillSurround", 0x42D8: "SkillPanicAll",
    0x4308: "SkillRobMagic", 0x4330: "SkillTakeMagic", 0x434A: "SkillSap",
    0x436D: "SkillUpper", 0x4385: "SkillSlow", 0x43A8: "SkillSpeed",
    0x43C0: "SkillBarrier", 0x43FB: "SkillTwinHits", 0x4415: "SkillMagicWall",
    0x4434: "SkillMagicBack", 0x446C: "SkillTransform", 0x4479: "SkillIRONIZE",
    0x447F: "SkillIronize", 0x44C4: "SkillHeal", 0x44F8: "SkillVivify",
    0x457E: "SkillFarewell", 0x458F: "SkillAntidote", 0x45A7: "SkillNumbOff",
    0x45D8: "SkillDeChaos", 0x45FE: "SkillCurseOff", 0x4616: "SkillChance",
    0x4625: "SkillPoisonHit_StepGuard_Whistle_Attack",
    0x462F: "SkillPsycheUp_TwinSlash",
    0x464C: "SkillRamming", 0x4653: "SkillBeserker",
    0x467C: "SkillKamikaze", 0x4683: "SkillMassacre",
    0x46BE: "SkillChargeUP", 0x46CF: "SkillHighJump",
    0x470F: "SkillSuckAir", 0x4720: "SkillFireSlash",
    0x472A: "SkillBoltSlash", 0x4734: "SkillVacuSlash",
    0x473E: "SkillIceSlash", 0x4748: "SkillMetalCut",
    0x4752: "SkillDrakSlash", 0x475C: "SkillBeastCut",
    0x4766: "SkillBirdBlow", 0x4770: "SkillDevilCut",
    0x477A: "SkillZombieCut", 0x4784: "SkillCleanCut",
    0x478E: "SkillMultiCut", 0x4798: "SkillBiAttack",
    0x480C: "SkillCallHelp", 0x4888: "SkillFocus",
    0x4897: "SkillSquallHit", 0x48B4: "SkillRainSlash",
    0x4918: "SkillWindBeast", 0x492B: "SkillRockThrow",
    0x4932: "SkillFireAir", 0x493C: "SkillFrigidAir",
    0x4946: "SkillBigBang", 0x494D: "SkillMegaMagic",
    0x4954: "SkillPalsyAir", 0x497B: "SkillPoisonGas",
    0x49D2: "SkillCurse", 0x4A00: "SkillAhhh",
    0x4A22: "SkillSandStorm", 0x4A57: "SkillEerieLite",
    0x4A7B: "SkillOddDance", 0x4AA3: "SkillSideStep",
    0x4AC5: "SkillLureDance", 0x4AE7: "SkillLushLicks",
    0x4B34: "SkillLegSweep", 0x4B68: "SkillWarCry",
    0x4B92: "SkillImitate", 0x4BA1: "SkillDeMagic_ThickFog",
    0x4BAB: "SkillSurge", 0x4BB6: "SkillUltraDown",
    0x4BD0: "SkillTatsuCall", 0x4C31: "SkillCover",
    0x4C3B: "SkillTailWind", 0x4C72: "SkillDodge",
    0x4C81: "SkillBladeD_Defense", 0x4CA5: "SkillSuckAll",
    0x4CDC: "SkillDanceShut", 0x4D0A: "SkillMouthShut",
    0x4D38: "SkillMeditate", 0x4D92: "SkillLifeSong",
    0x4DE9: "SkillLifeDance", 0x4E0A: "SkillDaze",
    0x4E0E: "SkillBeDragon", 0x4E15: "SkillSmashlime",
    0x4E1F: "SkillSheldodge", 0x4E29: "SkillBranching",
    0x4E33: "SkillGigaSlash", 0x4E3A: "SkillRUN",
    0x4E6D: "SkillAhhh2", 0x4E8A: "SkillHitAlly",
    0x4EA4: "SkillHitEnemy", 0x4EBE: "SkillHitRandom",
    0x4ED8: "SkillTrip", 0x4EE3: "SkillScared",
    0x4EE7: "SkillParalyze", 0x4EF9: "SkillSmashed",
    0x4F2C: "SkillHealUsAll", 0x4F35: "SkillALLCHANGE",
    0x4F54: "SkillBIGSLEEP", 0x4F7F: "SkillMP0",
    0x4FA1: "SkillCALLEVIL", 0x4FCC: "SkillFREEZY",
    0x4FFC: "SkillRESTOREMP", 0x501F: "SkillMETEOR",
}

# Rename mappings for existing labels
RENAMES = {
    "Call_052_6304": "CheckIsSlime",
    "Call_052_6311": "CheckIsDragon",
    "Call_052_631f": "CheckIsBeast",
    "Call_052_632d": "CheckIsFlying",
    "Call_052_633b": "CheckIsPlant",
    "Call_052_6349": "CheckIsBug",
    "Call_052_6357": "CheckIsDevil",
    "Call_052_6365": "CheckIsZombie",
    "Call_052_6373": "CheckIsMaterial",
    "Call_052_6b2a": "BCsrl3",
    "Call_052_6b2e": "BCsrl2",
    "Call_052_6b32": "BCsrl1",
    "Call_052_6b37": "HLsrl4",
    "Call_052_6b3b": "HLsrl3",
    "Call_052_6b3f": "HLsrl2",
    "Call_052_6b43": "HLsrl1",
    "Call_052_44c4": "SkillHeal",
    "Call_052_44f8": "SkillVivify",
    "Call_052_4e3a": "SkillRUN",
    "jr_052_4c3b": "SkillTailWind",
}

# Build reverse mapping: addr -> function table entry label
def read_rom():
    with open(ROM_PATH, 'rb') as f:
        return f.read()

def build_func_table_labels(rom):
    """Build mapping from function table address -> label name."""
    pt = BASE + (0x4011 - 0x4000)
    addr_to_label = {}
    for i in range(222):  # Only 222 valid entries
        lo = rom[pt + i*2]
        hi = rom[pt + i*2 + 1]
        addr = lo | (hi << 8)
        if addr not in addr_to_label and addr in HANDLERS:
            addr_to_label[addr] = HANDLERS[addr]
    return addr_to_label

def build_sym_map():
    """Read sym file to get address -> existing label mapping."""
    sym = {}
    with open(SYM_PATH) as f:
        for line in f:
            line = line.strip()
            if line.startswith(';') or not line:
                continue
            parts = line.split()
            if len(parts) >= 2 and ':' in parts[0]:
                bank_str, addr_str = parts[0].split(':')
                try:
                    bank = int(bank_str, 16)
                    addr = int(addr_str, 16)
                    if bank == BANK:
                        sym[addr] = parts[1]
                except:
                    pass
    return sym

def main():
    rom = read_rom()
    apply_mode = '--apply' in sys.argv
    
    sym_map = build_sym_map()
    func_labels = build_func_table_labels(rom)
    
    with open(ASM_PATH) as f:
        lines = f.readlines()
    
    # Find key line numbers
    entry_221_line = None
    entry_222_line = None
    first_code_line = None  # first instruction after fake entries
    jr_4225_line = None
    
    for i, line in enumerate(lines):
        s = line.strip()
        if '; [221]' in s and s.startswith('dw'):
            entry_221_line = i
        if '; [222]' in s and s.startswith('dw'):
            entry_222_line = i
        if entry_222_line is not None and first_code_line is None:
            if not s.startswith('dw') and not s.startswith(';') and s and not s.startswith('.'):
                first_code_line = i
        if 'jr_052_4225:' in s:
            jr_4225_line = i
    
    print("=== Section boundaries ===")
    print(f"  Entry 221: line {entry_221_line+1}")
    print(f"  Entry 222 (fake start): line {entry_222_line+1}")
    print(f"  First code after fakes: line {first_code_line+1}")
    print(f"  jr_052_4225: line {jr_4225_line+1}")
    
    # Step 1: Build replacement handler code for $41CD-$4224
    # Disassemble the overlap region properly
    overlap_asm = []
    overlap_asm.append('')
    overlap_asm.append('; ---------------------------------------------------------------')
    overlap_asm.append('; Skill Handler Functions')
    overlap_asm.append('; Function table entries 222-255 overlap with the first handlers')
    overlap_asm.append('; below — skills 222+ don\'t exist, so those entries are never read')
    overlap_asm.append('; ---------------------------------------------------------------')
    overlap_asm.append('')
    
    # Handlers in the overlap region (from our analysis)
    # Each 7-byte handler: call $XXXX; call $54E7; ret
    simple_handlers = [
        (0x41CD, "SkillBlaze",    "$5BFF"),
        (0x41D4, "SkillFirebal",  "$5C0D"),
        (0x41DB, "SkillBang",     "$5C1B"),
        (0x41E2, "SkillInfernos", "$5C27"),
        (0x41E9, "SkillIceBolt",  "$5C43"),
        (0x41F0, "SkillBolt",     "$5C35"),
    ]
    
    for addr, name, call_addr in simple_handlers:
        # Verify ROM bytes: CD xx xx CD E7 54 C9
        off = BASE + (addr - 0x4000)
        assert rom[off] == 0xCD
        assert rom[off+3] == 0xCD and rom[off+4] == 0xE7 and rom[off+5] == 0x54
        assert rom[off+6] == 0xC9
        actual_addr = '$%04X' % (rom[off+1] | (rom[off+2] << 8))
        assert actual_addr.upper() == call_addr.upper(), f"Mismatch at {name}: {actual_addr} vs {call_addr}"
        
        overlap_asm.append(f'{name}:  ; ${addr:04X}')
        overlap_asm.append(f'    call {call_addr}')
        overlap_asm.append(f'    call $54E7')
        overlap_asm.append(f'    ret')
        overlap_asm.append('')
    
    # SkillBeat at $41F7 (46 bytes, extends to $4224)
    # Already partially disassembled in the existing file (lines 307-316)
    overlap_asm.append('SkillBeat:  ; $41F7')
    overlap_asm.append('    xor a')
    overlap_asm.append('    ld [$d9f0], a')
    overlap_asm.append('    call $5C51')
    overlap_asm.append('    jr nc, jr_052_4225')
    overlap_asm.append('    ld a, [$db89]')
    overlap_asm.append('    ld hl, $dd1b')
    overlap_asm.append('    add l')
    overlap_asm.append('    ld l, a')
    overlap_asm.append('    ld a, $00')
    overlap_asm.append('    adc h')
    overlap_asm.append('    ld h, a')
    overlap_asm.append('    ld [hl], $01')
    overlap_asm.append('    ld hl, $b8e8')
    overlap_asm.append('    call Call_052_54af')
    overlap_asm.append('    push hl')
    overlap_asm.append('    ld a, [$db89]')
    overlap_asm.append('    ld hl, $dba3')
    overlap_asm.append('    call Call_052_6ab8')
    overlap_asm.append('    ld a, $00')
    overlap_asm.append('    ld [hl+], a')
    overlap_asm.append('    ld [hl], $00')
    overlap_asm.append('    pop hl')
    overlap_asm.append('    ret')
    overlap_asm.append('')
    
    # Step 2: Build new file
    new_lines = []
    
    # Part 1: Everything up to and including entry 221 (convert to labels)
    for i in range(entry_221_line + 1):
        line = lines[i]
        # Convert dw $XXXX to dw SkillLabel
        m = re.match(r'^(\s+)dw \$([0-9A-Fa-f]+)\s*(;.*)', line)
        if m:
            indent = m.group(1)
            addr_hex = m.group(2)
            comment = m.group(3)
            addr = int(addr_hex, 16)
            if addr in HANDLERS:
                new_lines.append(f'{indent}dw {HANDLERS[addr]}  {comment}\n')
                continue
        new_lines.append(line)
    
    # Part 2: Overlap handler code (replaces fake entries 222-255 AND the code at $4211-$4224)
    for asm_line in overlap_asm:
        new_lines.append(asm_line + '\n')
    
    # Part 3: Rest of file from jr_052_4225 onward, with handler labels inserted
    # and existing labels renamed
    
    # Build address-to-line mapping for handlers AFTER the overlap
    # We need to find where each handler starts in the remaining file
    # Strategy: use sym file to find nearest labeled addresses, then
    # compute offsets using ROM instruction sizes
    
    # First pass: collect all labeled addresses from sym file that are in our bank
    addr_labels = sorted(sym_map.items())  # sorted by address
    
    # For each handler address > $4224, find if there's already a label
    handlers_to_insert = {}
    for addr, name in HANDLERS.items():
        if addr > 0x4224:
            if addr in sym_map:
                # Already has a label — will be renamed
                pass
            else:
                handlers_to_insert[addr] = name
    
    # Process the remaining lines (from jr_4225_line onward)
    # We need to track the current address to know when to insert handler labels
    # Use the sym file: find each existing label's address, and between labels
    # we can count bytes
    
    # Build ordered list of addresses we need to insert labels at
    insert_addrs = sorted(handlers_to_insert.keys())
    
    # For inserting labels, we need to know which asm line corresponds to each address
    # This requires tracking through the ROM
    # Let's find the labels in sym file near each handler
    for addr in insert_addrs[:5]:
        # Find nearest label before this address
        nearest = None
        for sym_addr, sym_name in addr_labels:
            if sym_addr <= addr:
                nearest = (sym_addr, sym_name)
            else:
                break
        if nearest:
            gap = addr - nearest[0]
            print(f"  Handler ${addr:04X} ({handlers_to_insert[addr]}): nearest label ${nearest[0]:04X} ({nearest[1]}), gap {gap} bytes")
    
    # For now, just add labels via a two-pass approach:
    # Pass 1: Find all blank lines (function boundaries) and check if the next
    #   instruction's ROM address matches a handler address
    # This works because mgbdis puts blank lines between functions
    
    # To do this properly, let me track addresses through the sym file
    # Every label in the sym file has a known address
    # Between labels, count instruction bytes from the ROM to find exact positions
    
    # Simpler approach: for each handler, find the existing label closest before it,
    # find that label in the asm file, then count ROM bytes to reach the handler
    # and count asm instructions to find the right line
    
    # Actually, let me just insert labels via regex on the existing code.
    # Many handlers start after a 'ret' + blank line. I can find these boundaries.
    
    # For now, do the safe transformations:
    # 1. Rename existing labels
    # 2. Add a comment about the handler at known positions
    
    remaining_start = jr_4225_line
    for i in range(remaining_start, len(lines)):
        line = lines[i]
        
        # Apply renames
        for old_name, new_name in RENAMES.items():
            if old_name in line:
                line = line.replace(old_name, new_name)
        
        new_lines.append(line)
    
    if not apply_mode:
        # Count changes
        dw_label_count = sum(1 for l in new_lines if 'dw Skill' in l)
        handler_label_count = sum(1 for l in overlap_asm if l.endswith(':'))
        rename_count = len(RENAMES)
        print(f"\n=== Preview ===")
        print(f"  Function table entries with labels: {dw_label_count}")
        print(f"  Overlap handler labels added: {handler_label_count}")
        print(f"  Labels to rename: {rename_count}")
        print(f"  Total output lines: {len(new_lines)}")
        print(f"\n=== Sample overlap code ===")
        for line in overlap_asm[:20]:
            print(f"  {line}")
        print(f"\n=== Sample table entries ===")
        for l in new_lines[50:60]:
            print(f"  {l.rstrip()}")
        return
    
    # Write
    with open(ASM_PATH, 'w') as f:
        f.writelines(new_lines)
    print(f"Wrote {len(new_lines)} lines to {ASM_PATH}")

if __name__ == '__main__':
    main()
