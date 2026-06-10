#!/usr/bin/env python3
"""
gen_script_banks.py — Generate annotated assembly for script data banks $0C-$0F.

Converts misassembled code back into proper dw data tables with labels,
opcode names, text snippets, and structural comments.

Usage:
    python3 tools/gen_script_banks.py                  # Preview
    python3 tools/gen_script_banks.py --apply           # Apply to .asm files
    python3 tools/gen_script_banks.py --bank 0x0C       # Single bank
"""

import argparse, json, os, sys
from collections import defaultdict

ROM_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data', 'DWM-original.gbc')
ASM_DIR  = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'disassembly')
TEXT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'extracted', 'text_id_map.json')

OPCODE_NAMES = {
    0x00:'BranchIfFlagClear',0x01:'BranchIfFlagSet',0x02:'ClearEventFlag',
    0x03:'SetEventFlag',0x04:'ScreenEffect',0x05:'TriggerBattle',
    0x06:'IncrementCounter',0x07:'InitDialogMode',0x08:'NOP',
    0x09:'SetDelay',0x0A:'NPCMoveX',0x0B:'NPCMoveY',
    0x0C:'SetNPCFacing',0x0D:'WriteNPCByte',0x0E:'SetMapTransition',
    0x0F:'SetScreenScroll',0x10:'NPCAnimStart',0x11:'NPCAnimSetup',
    0x12:'WriteRAM',0x13:'SetGameFlags',0x14:'ClearGameFlags',
    0x15:'PlaySE',0x16:'Cmd16',0x17:'SetupBossBattle',
    0x18:'NPCVisibility',0x19:'FadeEffect',0x1A:'Cmd1A',
    0x1B:'MultiRAMWrite',0x1C:'CompareRAM',0x1D:'LockMovement',
    0x1E:'UnlockMovement',0x1F:'EventTrigger',0x20:'Cmd20',
    0x21:'TriggerBattle2',0x22:'Cmd22',0x23:'PlaySE2',
    0x24:'Cmd24',0x25:'Cmd25',0x26:'Cmd26',0x27:'Cmd27',
    0x28:'CheckStorageFull',0x29:'AddMonster',0x2A:'GiveItem',
    0x2B:'CheckMonsterLevel',0x2C:'CheckInvFull',0x2D:'EventDispatch',
    0x2E:'Cmd2E',0x2F:'Cmd2F',0x30:'Cmd30',0x31:'Cmd31',
    0x32:'Cmd32',0x33:'Cmd33',0x34:'Cmd34',0x35:'Cmd35',
    0x36:'Cmd36',0x37:'Cmd37',0x38:'BattleSetup',0x39:'Cmd39',
    0x3A:'Cmd3A',0x3B:'Cmd3B',0x3C:'Cmd3C',0x3D:'Cmd3D',
    0x3E:'Cmd3E',0x3F:'Cmd3F',0x40:'Cmd40',0x41:'SetBGM',
    0x42:'SetReturnMap',0x43:'ExecuteReturn',0x44:'Cmd44',
    0x45:'Cmd45',0x46:'Cmd46',0x47:'Cmd47',0x48:'Cmd48',
    0x49:'Cmd49',0x4A:'Cmd4A',0x4B:'Cmd4B',0x4C:'RestoreBGM',
    0x4D:'SetLongDelay',0x4E:'MapTransition3',0x4F:'Cmd4F',
    0x50:'Cmd50',0x51:'Cmd51',0x52:'Cmd52',0x53:'Cmd53',
    0x54:'BattleConfig',0x55:'Cmd55',0x56:'Cmd56',0x57:'Cmd57',
    0x58:'Cmd58',0x59:'Cmd59',0x5A:'Cmd5A',0x5B:'Cmd5B',
    0x5C:'Cmd5C',0x5D:'Cmd5D',0x5E:'Cmd5E',0x5F:'Cmd5F',
    0x60:'Cmd60',0x61:'Cmd61',0x62:'Cmd62',0x63:'Cmd63',
}

MAP_NAMES = {
    0x00:'Castle',0x01:'GreatTree',0x02:'Bazaar',0x03:'GateHub',
    0x04:'Farm',0x05:'Stable',0x06:'ArenaLobby',0x07:'ArenaRooms',
    0x08:'Map08',0x09:'Map09',0x0A:'Map0A',0x0B:'Map0B',
    0x0C:'GateTileset',0x0D:'Map0D',0x0E:'Map0E',0x0F:'Map0F',
    0x10:'CopycatRoom',0x11:'Map11',0x12:'Map12',0x13:'Map13',
    0x14:'Map14',0x15:'Map15',0x16:'MedalMan',0x17:'Map17',
    0x18:'Well',0x19:'Map19',0x1A:'Map1A',0x1B:'Map1B',
    0x1C:'Map1C',0x1D:'Map1D',0x1E:'Map1E',0x1F:'Map1F',
    0x20:'Map20',0x21:'Map21',0x22:'Map22',0x23:'Map23',
    0x24:'RoomVillagerTalisman',0x25:'RoomMemoriesBewilder',
    0x26:'RoomPeaceBravery',0x27:'Map27',
    0x28:'RoomJoyWisdom',0x29:'RoomHappinessTemptation',
    0x2A:'RoomLabyrinthJudgment',0x2B:'Map2B',
    0x2C:'RoomAmbitionDemolition',0x2D:'RoomMastermindControl',
    0x2E:'Map2E',0x2F:'Map2F',
    0x30:'BossBeginning',0x31:'BossVillager',0x32:'BossTalisman',
    0x33:'BossMemories',0x34:'BossBewilder',0x35:'Map35',
    0x36:'BossPeace',0x37:'BossBravery',0x38:'Map38',0x39:'Map39',
    0x3A:'Map3A',0x3B:'Map3B',0x3C:'Map3C',0x3D:'Map3D',
    0x3E:'Map3E',0x3F:'Map3F',0x40:'Map40',0x41:'Map41',
    0x42:'Map42',0x43:'Map43',0x44:'Map44',0x45:'Map45',
    0x46:'BossAmbition',0x47:'Map47',0x48:'Map48',0x49:'Map49',
    0x4A:'Map4A',0x4B:'Map4B',0x4C:'Map4C',0x4D:'Map4D',
    0x4E:'Map4E',0x4F:'BossUnused',0x50:'Map50',0x51:'Map51',
}

BANK_CONFIG = {
    0x0C: {'map_range': (0x00, 0x05), 'asm': 'bank_00c.asm'},
    0x0D: {'map_range': (0x06, 0x1F), 'asm': 'bank_00d.asm'},
    0x0E: {'map_range': (0x20, 0x3F), 'asm': 'bank_00e.asm'},
    0x0F: {'map_range': (0x40, 0x5F), 'asm': 'bank_00f.asm'},
}

def load_text_map():
    try:
        with open(TEXT_PATH) as f:
            raw = json.load(f)
        return {int(k): (v.get('text','') if isinstance(v,dict) else str(v))[:45]
                for k,v in raw.items()}
    except: return {}

def rw(rom, bank, addr):
    """Read word from bank:addr"""
    off = bank * 0x4000 + (addr - 0x4000)
    return rom[off] | (rom[off+1] << 8)

def rb(rom, bank, addr):
    """Read byte from bank:addr"""
    return rom[bank * 0x4000 + (addr - 0x4000)]


class ScriptBank:
    def __init__(self, rom, bank_num, text_map):
        self.rom = rom
        self.bank = bank_num
        self.text_map = text_map
        self.cfg = BANK_CONFIG[bank_num]
        self.master = []       # [(map_type, tbl_ptr)]
        self.map_tables = {}   # map_type -> [(script_id, data_ptr)]
        self.labels = {}       # addr -> label_name
        self.label_addrs = set()
        # regions: sorted list of (start_addr, end_addr, type, metadata)
        self.regions = []

    def parse(self):
        mt_lo, mt_hi = self.cfg['map_range']
        num = mt_hi - mt_lo + 1
        
        # Master table
        for i in range(num):
            map_type = mt_lo + i
            ptr = rw(self.rom, self.bank, 0x41BA + map_type * 2)
            self.master.append((map_type, ptr))
        
        # Per-map tables: determine sizes from consecutive table pointers
        tbl_ptrs = sorted(set(p for _,p in self.master))
        
        # Find first script data address
        all_script_ptrs = set()
        for _, tbl_ptr in self.master:
            # Read first entry to get a script data ptr
            ptr = rw(self.rom, self.bank, tbl_ptr)
            if 0x4000 <= ptr <= 0x7FFF:
                all_script_ptrs.add(ptr)
        
        first_data = min(all_script_ptrs) if all_script_ptrs else 0x7FFF
        
        for map_type, tbl_ptr in self.master:
            # Table ends at next table or first script data
            tbl_end = first_data
            for tp in tbl_ptrs:
                if tp > tbl_ptr:
                    tbl_end = tp
                    break
            
            scripts = []
            addr = tbl_ptr
            while addr < tbl_end:
                ptr = rw(self.rom, self.bank, addr)
                if ptr < 0x4000 or ptr > 0x7FFF:
                    break
                scripts.append((len(scripts), ptr))
                all_script_ptrs.add(ptr)
                addr += 2
            self.map_tables[map_type] = scripts
        
        # Scan script data to find branch targets
        branch_targets = set()
        for script_ptr in sorted(all_script_ptrs):
            addr = script_ptr
            for i in range(5000):
                val = rw(self.rom, self.bank, addr + i*2)
                if val == 0xFFFF:
                    break
                # If val is an address in the data region, it MIGHT be a branch target
                if first_data <= val <= 0x7FFF and val not in all_script_ptrs:
                    # Only count if it's on the same alignment as this script
                    if (val % 2) == (script_ptr % 2):
                        branch_targets.add(val)
            
        # Build labels
        pfx = f'Bank{self.bank:02X}_'
        self.labels[0x41BA] = f'{pfx}ScriptMasterTable'
        for mt, tbl_ptr in self.master:
            name = MAP_NAMES.get(mt, f'Map{mt:02X}')
            if tbl_ptr not in self.labels:
                self.labels[tbl_ptr] = f'{name}_ScriptPtrTable'
            for sid, dptr in self.map_tables.get(mt, []):
                if dptr not in self.labels:
                    self.labels[dptr] = f'{name}_Script{sid:02d}'
        for bt in branch_targets:
            if bt not in self.labels:
                self.labels[bt] = f'{pfx}ScriptAddr_{bt:04X}'
        
        self.label_addrs = set(self.labels.keys())
        
        # Build regions
        self._build_regions(all_script_ptrs, branch_targets, first_data)
        
        return self

    def _build_regions(self, script_ptrs, branch_targets, first_data):
        """Build sorted regions covering the entire data area."""
        mt_lo, mt_hi = self.cfg['map_range']
        num = mt_hi - mt_lo + 1
        
        # Master table region
        master_end = 0x41BA + (mt_hi + 1) * 2
        self.regions.append((0x41BA, master_end, 'master', None))
        
        # Per-map table regions
        for mt, tbl_ptr in self.master:
            scripts = self.map_tables.get(mt, [])
            tbl_end = tbl_ptr + len(scripts) * 2
            self.regions.append((tbl_ptr, tbl_end, 'table', mt))
        
        # Script data regions: from each script ptr, read until $FFFF
        for script_ptr in sorted(script_ptrs):
            addr = script_ptr
            for i in range(5000):
                val = rw(self.rom, self.bank, addr + i*2)
                if val == 0xFFFF:
                    end = addr + (i+1)*2
                    self.regions.append((script_ptr, end, 'script', None))
                    break
        
        # Branch target blocks: from each bt, read until $FFFF
        # Only add if not already covered by a script region
        script_ranges = set()
        for start, end, typ, _ in self.regions:
            if typ == 'script':
                for a in range(start, end):
                    script_ranges.add(a)
        
        for bt in sorted(branch_targets):
            if bt in script_ranges:
                continue
            addr = bt
            for i in range(5000):
                val = rw(self.rom, self.bank, addr + i*2)
                if val == 0xFFFF:
                    end = addr + (i+1)*2
                    self.regions.append((bt, end, 'branch', None))
                    break
        
        self.regions.sort()

    def _annotate(self, val):
        """Annotate a dw value."""
        if val == 0xFFFF: return '  ; END'
        hi, lo = (val >> 8) & 0xFF, val & 0xFF
        if hi == 0xFF:
            return f'  ; {OPCODE_NAMES.get(lo, f"Cmd${lo:02X}")}'
        if val in self.labels:
            return f'  ; -> {self.labels[val]}'
        if val in self.text_map:
            t = self.text_map[val].replace('\n',' // ')[:40]
            return f'  ; Text ${val:04X}: "{t}"'
        if 0xC000 <= val <= 0xFFFF:
            return f'  ; RAM ${val:04X}'
        return ''

    def generate(self):
        """Generate the data section assembly."""
        lines = []
        mt_lo, mt_hi = self.cfg['map_range']
        
        lines.append('')
        lines.append('; ===========================================================================')
        lines.append(f'; Script Data — Bank ${self.bank:02X}')
        total = sum(len(v) for v in self.map_tables.values())
        lines.append(f'; {total} scripts across {len(self.map_tables)} maps, {len(self.labels)} labels')
        lines.append('; ===========================================================================')
        lines.append('')
        
        # Emit all data byte-by-byte from $41BA to $7FFF using db pairs
        # Place labels at known addresses, use dw where aligned, db for strays
        
        # First: build a byte-level map of the entire data region
        # For each byte, determine: is it part of a known dw region, or stray?
        
        # Collect all "word starts": addresses where we know a dw begins
        word_starts = set()
        
        # Master table words
        for i in range(mt_hi - mt_lo + 1):
            word_starts.add(0x41BA + i*2)
        
        # Per-map table words
        for mt, tbl_ptr in self.master:
            for sid, _ in self.map_tables.get(mt, []):
                word_starts.add(tbl_ptr + sid * 2)
        
        # Script data words (from each script start, stepping by 2)
        all_script_starts = set()
        for mt in self.map_tables:
            for sid, ptr in self.map_tables[mt]:
                all_script_starts.add(ptr)
        
        for sptr in sorted(all_script_starts):
            for i in range(5000):
                addr = sptr + i*2
                if addr > 0x7FFF: break
                word_starts.add(addr)
                val = rw(self.rom, self.bank, addr)
                if val == 0xFFFF: break
        
        # Branch target block words  
        for bt in sorted(self.labels.keys()):
            if bt < 0x41BA or bt in all_script_starts: continue
            if bt not in word_starts:
                # This is a branch target that starts a new word sequence
                for i in range(5000):
                    addr = bt + i*2
                    if addr > 0x7FFF: break
                    word_starts.add(addr)
                    val = rw(self.rom, self.bank, addr)
                    if val == 0xFFFF: break
        
        # Now iterate from $41BA to the last used byte
        # Find the actual end of data
        max_word = max(word_starts) if word_starts else 0x41BA
        data_end = max_word + 2  # include the last word
        
        addr = 0x41BA
        prev_was_end = False
        
        while addr < data_end and addr <= 0x7FFF:
            # Emit label if needed
            if addr in self.labels:
                label = self.labels[addr]
                # Add section header for tables and scripts
                if '_ScriptPtrTable' in label or label == 'ScriptMasterTable':
                    if label == 'ScriptMasterTable':
                        lines.append('; ---------------------------------------------------------------------------')
                        lines.append('; Master Script Pointer Table (map_type -> per-map table)')
                        lines.append('; ---------------------------------------------------------------------------')
                    else:
                        mt_name = label.replace('_ScriptPtrTable', '')
                        # Find map type
                        mt_id = None
                        for mt, _ in self.master:
                            if MAP_NAMES.get(mt, f'Map{mt:02X}') == mt_name:
                                mt_id = mt
                                break
                        num_scripts = len(self.map_tables.get(mt_id, []))
                        lines.append('; ---------------------------------------------------------------------------')
                        lines.append(f'; {mt_name} Per-Script Table (map_type=${mt_id:02X}, {num_scripts} scripts)')
                        lines.append('; ---------------------------------------------------------------------------')
                elif '_Script' in label and 'Addr' not in label:
                    lines.append('; ---------------------------------------------------------------------------')
                    lines.append(f'; {label}')
                    lines.append('; ---------------------------------------------------------------------------')
                
                lines.append(f'{label}:')
                prev_was_end = False
            
            if addr in word_starts:
                # Emit as dw
                val = rw(self.rom, self.bank, addr)
                
                # For pointer tables, use label references
                comment = ''
                master_start = 0x41BA + mt_lo * 2
                master_region_end = 0x41BA + (mt_hi + 1) * 2
                if master_start <= addr < master_region_end:
                    # Master table entry
                    mt_id = (addr - 0x41BA) // 2
                    tgt_label = self.labels.get(val, f'${val:04X}')
                    name = MAP_NAMES.get(mt_id, f'Map{mt_id:02X}')
                    mt_idx = mt_id - mt_lo
                    lines.append(f'    dw {tgt_label:<32s}; [{mt_idx}] {name}')
                else:
                    # Check if this is a per-map table entry
                    is_table_entry = False
                    for mt, tbl_ptr in self.master:
                        scripts = self.map_tables.get(mt, [])
                        tbl_end = tbl_ptr + len(scripts) * 2
                        if tbl_ptr <= addr < tbl_end and (addr - tbl_ptr) % 2 == 0:
                            sid = (addr - tbl_ptr) // 2
                            tgt_label = self.labels.get(val, f'${val:04X}')
                            lines.append(f'    dw {tgt_label:<32s}; script {sid}')
                            is_table_entry = True
                            break
                    
                    if not is_table_entry:
                        # Script data word — check if value is a label ref
                        if val in self.labels and val != 0xFFFF and (val >> 8) != 0xFF:
                            tgt = self.labels[val]
                            lines.append(f'    dw {tgt:<32s}; -> branch target')
                        else:
                            ann = self._annotate(val)
                            lines.append(f'    dw ${val:04X}{ann}')
                
                if val == 0xFFFF:
                    lines.append('')
                    prev_was_end = True
                else:
                    prev_was_end = False
                
                addr += 2
            else:
                # Stray byte(s) between word-aligned regions
                b = rb(self.rom, self.bank, addr)
                lines.append(f'    db ${b:02X}')
                addr += 1
        
        # Emit any remaining bytes to fill the bank to $7FFF
        while addr <= 0x7FFF:
            if addr in word_starts:
                val = rw(self.rom, self.bank, addr)
                ann = self._annotate(val)
                if addr in self.labels:
                    lines.append(f'{self.labels[addr]}:')
                lines.append(f'    dw ${val:04X}{ann}')
                addr += 2
            else:
                b = rb(self.rom, self.bank, addr)
                lines.append(f'    db ${b:02X}')
                addr += 1
        
        return lines

    def stats(self):
        total = sum(len(v) for v in self.map_tables.values())
        return {'bank': self.bank, 'maps': len(self.map_tables),
                'scripts': total, 'labels': len(self.labels)}


def find_code_end(asm_path):
    """Find the line index (0-based) after the last code 'ret'."""
    with open(asm_path) as f:
        lines = f.readlines()
    ret_count = 0
    for i, line in enumerate(lines):
        if line.strip() == 'ret':
            ret_count += 1
            if ret_count == 6:
                return i + 1  # include ret, cut after
    return 350  # fallback

def process_bank(bank_num, rom, text_map, apply=False):
    cfg = BANK_CONFIG[bank_num]
    parser = ScriptBank(rom, bank_num, text_map).parse()
    data_lines = parser.generate()
    
    asm_path = os.path.join(ASM_DIR, cfg['asm'])
    with open(asm_path) as f:
        existing = f.readlines()
    
    boundary = find_code_end(asm_path)
    code_section = existing[:boundary + 1]
    if code_section and code_section[-1].strip():
        code_section.append('\n')
    
    new_content = ''.join(code_section) + '\n'.join(data_lines) + '\n'
    st = parser.stats()
    
    if apply:
        with open(asm_path, 'w') as f:
            f.write(new_content)
        print(f"  Bank ${bank_num:02X}: {cfg['asm']} — {st['scripts']} scripts, "
              f"{st['labels']} labels, {boundary + 1 + len(data_lines)} lines")
    else:
        print(f"\n=== Bank ${bank_num:02X} ({cfg['asm']}) ===")
        print(f"  Scripts: {st['scripts']}, Labels: {st['labels']}")
        print(f"  Code: {boundary+1} lines, Data: {len(data_lines)} lines")
        print(f"  Total: {boundary+1+len(data_lines)} (was {len(existing)})")
        for line in data_lines[:40]:
            print(f"    {line}")
    
    return st

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--bank', type=lambda x: int(x,0))
    args = ap.parse_args()
    
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    text_map = load_text_map()
    
    banks = [args.bank] if args.bank else [0x0C, 0x0D, 0x0E, 0x0F]
    for b in banks:
        process_bank(b, rom, text_map, args.apply)
    
    if args.apply:
        print("\nVerify: cd disassembly && rm -f game.o game.gbc game.sym game.map && make && md5sum game.gbc")

if __name__ == '__main__':
    main()
