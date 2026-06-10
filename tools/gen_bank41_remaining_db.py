#!/usr/bin/env python3
"""Generate labeled db/dw for remaining bank $41 tables.

Converts raw hex in bank $41 into labeled pointer tables and string data:
  - FamilyCodePtrTable at $4739 (215 entries)
  - ItemNamePtrTable at $48E7 (44 entries)
  - ItemDescPtrTable at $493F (44 entries)
  - PersonalityNamePtrTable at $4997 (27 entries)
  - MiscTextPtrTable at $49CD (37 entries)
  - WatabouTextPtrTable at $4A17 (2 entries)
  - ItemUseTextPtrTable at $4A1B (48 entries)
  - SpellUseTextPtrTable at $4A7B (12 entries)
  - Code functions at $4A93 (3 x 7 bytes)
  - Dispatch text strings at $4AA8-$5B1E
  - Fixed SkillNameStrings (222 unique + 1 empty, not 256)
  - Family code strings at $69F2-$6C77
  - Item name strings at $6C78-$6DF7
  - Item description strings at $6DF8-$7158
  - Personality name strings at $7159-$7228
  - Post-personality text strings at $7229-end

Usage:
  python3 tools/gen_bank41_remaining_db.py              # preview
  python3 tools/gen_bank41_remaining_db.py --apply       # apply to bank_041.asm
"""
import os, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(SCRIPT_DIR, '..', 'data', 'DWM-original.gbc')
ASM_PATH = os.path.join(SCRIPT_DIR, '..', 'disassembly', 'bank_041.asm')

BANK = 0x41
BASE = BANK * 0x4000

# Table addresses (from dispatch table at $4001)
FAMILY_PTR    = 0x4739   # 215 entries
ITEM_NAME_PTR = 0x48E7   # 44 entries
ITEM_DESC_PTR = 0x493F   # 44 entries
PERS_PTR      = 0x4997   # 27 entries
MISC1_PTR     = 0x49CD   # 37 entries
WATABOU_PTR   = 0x4A17   # 2 entries
ITEMUSE_PTR   = 0x4A1B   # 48 entries
SPELL_PTR     = 0x4A7B   # 12 entries
CODE_FUNCS    = 0x4A93   # 21 bytes of code
DISP_TEXT     = 0x4AA8   # dispatch text strings start
MON_NAMES     = 0x5B1F   # monster name strings (already labeled)
SKILL_NAMES   = 0x628E   # skill name strings

# Charmap from charmap.asm
CHARMAP = {}
for i, c in enumerate('0123456789'):    CHARMAP[i] = c
for i, c in enumerate('ABCDEFGHIJKLMNOPQRSTUVWXYZ'): CHARMAP[0x24 + i] = c
for i, c in enumerate('abcdefghijklmnopqrstuvwxyz'): CHARMAP[0x3e + i] = c
CHARMAP[0x5c] = "'"
CHARMAP[0x5e] = ','
CHARMAP[0x5f] = '.'
CHARMAP[0x61] = '..'
CHARMAP[0x62] = ' '
CHARMAP[0x63] = '!'
CHARMAP[0x64] = '?'
# $9E maps to special tile (used in COOL[9E]CALM)

ITEM_NAMES = [
    "",  # 0 = no item
    "Herb", "Lovewater", "SageStone", "WorldDew", "Potion",
    "ElfWater", "Antidote", "MoonHerb", "SkyBell", "Laurel",
    "AwakeSand", "WorldLeaf", "LifeAcorn", "MysticNut", "ATKseed",
    "DEFseed", "AGLseed", "INTseed", "BeefJerky", "PorkChop",
    "Rib", "BadMeat", "Sirloin", "BoltStaff", "WindStaff",
    "MistStaff", "LavaStaff", "SnowStaff", "WarpWing", "TinyMedal",
    "QuestBk", "HorrorBK", "BeNiceBK", "CheaterBK", "SmartBK",
    "ComedyBK", "FireStaff", "BeastTail", "WarpStaff", "Repellent",
    "ShinyHarp", "MapHerb", "BookMark",
]

PERSONALITY_NAMES = [
    "HOTBLOOD", "DARING", "DAREDEVIL", "LONE_WOLF", "VAIN",
    "EZ_GOING", "SMUG", "SNOBBY", "RECKLESS", "COOL_CALM",
    "WHIMSY", "NOSY", "WHIZ_KID", "ORDINARY", "HASTY",
    "STUBBORN", "REBEL", "SPOILED", "HUMANE", "UNCERTAIN",
    "CARELESS", "SHREWED", "CAREFREE", "GULLIBLE", "SLY",
    "COWARD", "LAZY",
]


def read_rom():
    with open(ROM_PATH, 'rb') as f:
        return f.read()


def rom_off(addr):
    """Convert bank-relative address to ROM offset."""
    return BASE + (addr - 0x4000)


def read_ptr_table(rom, addr, count):
    off = rom_off(addr)
    return [rom[off + i*2] | (rom[off + i*2 + 1] << 8) for i in range(count)]


def decode_string(rom, addr):
    """Read $F0-terminated string. Returns (decoded_text, raw_bytes_list)."""
    off = rom_off(addr)
    raw = []
    while rom[off] != 0xF0:
        raw.append(rom[off])
        off += 1
    raw.append(0xF0)
    decoded = ''.join(CHARMAP.get(b, '') for b in raw[:-1])
    return decoded, raw


def string_to_db(decoded, raw):
    """Convert raw bytes to a db expression using charmap strings where possible."""
    if not raw or raw == [0xF0]:
        return 'db $F0'

    data_bytes = raw[:-1]
    all_charmap = all(b in CHARMAP for b in data_bytes)

    if all_charmap and decoded:
        return 'db "%s", $F0' % decoded

    # Mixed mode: group charmap runs vs hex bytes
    parts = []
    current_str = []
    for b in data_bytes:
        if b in CHARMAP:
            current_str.append(CHARMAP[b])
        else:
            if current_str:
                parts.append('"%s"' % ''.join(current_str))
                current_str = []
            parts.append('$%02X' % b)
    if current_str:
        parts.append('"%s"' % ''.join(current_str))
    parts.append('$F0')
    return 'db %s' % ', '.join(parts)


def safe_label(name):
    """Make a string safe for use as an assembly label."""
    result = name.replace("'", "").replace("?", "").replace(" ", "_")
    result = result.replace("..", "").replace(".", "").replace(",", "")
    result = result.replace("!", "")
    return result


def build_addr_to_label(ptrs, prefix, names=None):
    """Build addr->label mapping from pointer list, using first occurrence index.
    Returns (addr_to_label dict, index_to_label dict)."""
    addr_to_label = {}  # addr -> label string
    idx_to_label = {}   # index -> label string (for ptr table output)

    for i, ptr in enumerate(ptrs):
        if ptr not in addr_to_label:
            # First occurrence — define the label
            if names and i < len(names) and names[i]:
                lname = safe_label(names[i])
            else:
                decoded, _ = decode_string(read_rom(), ptr)
                lname = safe_label(decoded) or 'Empty'
            label = '%s_%03d_%s' % (prefix, i, lname)
            addr_to_label[ptr] = label
        idx_to_label[i] = addr_to_label[ptr]

    return addr_to_label, idx_to_label


# ---- Global ROM for build_addr_to_label ----
_rom = None
def get_rom():
    global _rom
    if _rom is None:
        _rom = read_rom()
    return _rom


def generate_ptr_table_section(rom):
    """Generate pointer table section ($4739-$4A92) + code funcs ($4A93-$4AA7)."""
    lines = []

    # --- Family Code Pointer Table ---
    family_ptrs = read_ptr_table(rom, FAMILY_PTR, 215)
    # Build label mapping: addr -> first occurrence label
    fam_addr_to_label = {}
    fam_idx_to_label = {}
    for i, ptr in enumerate(family_ptrs):
        if ptr not in fam_addr_to_label:
            decoded, _ = decode_string(rom, ptr)
            lname = safe_label(decoded) or 'Empty'
            fam_addr_to_label[ptr] = 'FamilyCode_%03d_%s' % (i, lname)
        fam_idx_to_label[i] = fam_addr_to_label[ptr]

    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Family Code Pointer Table ($4739)')
    lines.append('; 215 entries x 2 bytes = 430 bytes')
    lines.append('; 2-letter family abbreviation per monster ID (0-214)')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('FamilyCodePtrTable:  ; $4739')

    for i, ptr in enumerate(family_ptrs):
        decoded, _ = decode_string(rom, ptr)
        label = fam_idx_to_label[i]
        lines.append('    dw %s  ; [%d] %s' % (label, i, decoded))

    # --- Item Name Pointer Table ---
    item_ptrs = read_ptr_table(rom, ITEM_NAME_PTR, 44)
    item_addr_to_label = {}
    item_idx_to_label = {}
    for i, ptr in enumerate(item_ptrs):
        if ptr not in item_addr_to_label:
            if i < len(ITEM_NAMES) and ITEM_NAMES[i]:
                lname = ITEM_NAMES[i]
            else:
                decoded, _ = decode_string(rom, ptr)
                lname = safe_label(decoded) or 'Empty'
            item_addr_to_label[ptr] = 'ItemName_%02d_%s' % (i, lname)
        item_idx_to_label[i] = item_addr_to_label[ptr]

    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Item Name Pointer Table ($48E7)')
    lines.append('; 44 entries x 2 bytes = 88 bytes')
    lines.append('; Index 0 = no item (empty), 1-43 = item names')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('ItemNamePtrTable:  ; $48E7')

    for i in range(44):
        decoded, _ = decode_string(rom, item_ptrs[i])
        label = item_idx_to_label[i]
        lines.append('    dw %s  ; [%d] %s' % (label, i, decoded))

    # --- Item Description Pointer Table ---
    desc_ptrs = read_ptr_table(rom, ITEM_DESC_PTR, 44)
    desc_addr_to_label = {}
    desc_idx_to_label = {}
    for i, ptr in enumerate(desc_ptrs):
        if ptr not in desc_addr_to_label:
            desc_addr_to_label[ptr] = 'ItemDesc_%02d' % i
        desc_idx_to_label[i] = desc_addr_to_label[ptr]

    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Item Description Pointer Table ($493F)')
    lines.append('; 44 entries x 2 bytes = 88 bytes')
    lines.append('; Text descriptions for items, with control codes')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('ItemDescPtrTable:  ; $493F')

    for i in range(44):
        comment = ITEM_NAMES[i] if i < len(ITEM_NAMES) and ITEM_NAMES[i] else ('empty' if i == 0 else 'item_%02d' % i)
        label = desc_idx_to_label[i]
        lines.append('    dw %s  ; [%d] %s' % (label, i, comment))

    # --- Personality Name Pointer Table ---
    pers_ptrs = read_ptr_table(rom, PERS_PTR, 27)
    pers_addr_to_label = {}
    pers_idx_to_label = {}
    for i, ptr in enumerate(pers_ptrs):
        if ptr not in pers_addr_to_label:
            if i < len(PERSONALITY_NAMES):
                lname = PERSONALITY_NAMES[i]
            else:
                decoded, _ = decode_string(rom, ptr)
                lname = safe_label(decoded) or 'Unknown'
            pers_addr_to_label[ptr] = 'PersonalityName_%02d_%s' % (i, lname)
        pers_idx_to_label[i] = pers_addr_to_label[ptr]

    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Personality Name Pointer Table ($4997)')
    lines.append('; 27 entries x 2 bytes = 54 bytes')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('PersonalityNamePtrTable:  ; $4997')

    for i in range(27):
        label = pers_idx_to_label[i]
        lines.append('    dw %s  ; [%d]' % (label, i))

    # --- Misc/Watabou/ItemUse/SpellUse pointer tables ---
    # These reference text in the dispatch or post-personality regions
    # We need to collect ALL target addresses and assign labels

    # First pass: collect all target addresses from these 4 tables
    misc_ptrs = read_ptr_table(rom, MISC1_PTR, 37)
    watabou_ptrs = read_ptr_table(rom, WATABOU_PTR, 2)
    itemuse_ptrs = read_ptr_table(rom, ITEMUSE_PTR, 48)
    spell_ptrs = read_ptr_table(rom, SPELL_PTR, 12)

    # Build addr->label for each, first occurrence wins
    misc_a2l = {}
    for i, ptr in enumerate(misc_ptrs):
        if ptr not in misc_a2l:
            misc_a2l[ptr] = 'MiscText_%02d' % i

    watabou_a2l = {}
    for i, ptr in enumerate(watabou_ptrs):
        if ptr not in watabou_a2l:
            watabou_a2l[ptr] = 'WatabouText_%02d' % i

    itemuse_a2l = {}
    for i, ptr in enumerate(itemuse_ptrs):
        if ptr not in itemuse_a2l:
            itemuse_a2l[ptr] = 'ItemUseText_%02d' % i

    spell_a2l = {}
    for i, ptr in enumerate(spell_ptrs):
        if ptr not in spell_a2l:
            spell_a2l[ptr] = 'SpellUseText_%02d' % i

    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Misc Text Pointer Table ($49CD)')
    lines.append('; 37 entries — battle tactics, level up messages, skill learning')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('MiscTextPtrTable:  ; $49CD')
    for i, ptr in enumerate(misc_ptrs):
        label = misc_a2l[ptr]
        lines.append('    dw %s  ; [%d]' % (label, i))

    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Watabou Text Pointer Table ($4A17)')
    lines.append('; 2 entries')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('WatabouTextPtrTable:  ; $4A17')
    for i, ptr in enumerate(watabou_ptrs):
        label = watabou_a2l[ptr]
        lines.append('    dw %s  ; [%d]' % (label, i))

    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Item Use Text Pointer Table ($4A1B)')
    lines.append('; 48 entries — messages when using items in battle/field')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('ItemUseTextPtrTable:  ; $4A1B')
    for i, ptr in enumerate(itemuse_ptrs):
        label = itemuse_a2l[ptr]
        lines.append('    dw %s  ; [%d]' % (label, i))

    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Spell Use Text Pointer Table ($4A7B)')
    lines.append('; 12 entries — messages when casting spells')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('SpellUseTextPtrTable:  ; $4A7B')
    for i, ptr in enumerate(spell_ptrs):
        label = spell_a2l[ptr]
        lines.append('    dw %s  ; [%d]' % (label, i))

    # --- Code Functions ($4A93-$4AA7) ---
    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Code functions ($4A93-$4AA7)')
    lines.append('; 3 small helper functions, 7 bytes each')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('Func_Bank41_GetText:  ; $4A93')
    lines.append('    ld de, $4007')
    lines.append('    call $05B6')
    lines.append('    ret')
    lines.append('')
    lines.append('Func_Bank41_PutText:  ; $4A9A')
    lines.append('    ld de, $4007')
    lines.append('    call $05F6')
    lines.append('    ret')
    lines.append('')
    lines.append('Func_Bank41_GetPutText:  ; $4AA1')
    lines.append('    call Func_Bank41_GetText')
    lines.append('    call $0609')
    lines.append('    ret')

    # Store addr->label maps for use by string sections
    return lines, {
        'fam': fam_addr_to_label,
        'item': item_addr_to_label,
        'desc': desc_addr_to_label,
        'pers': pers_addr_to_label,
        'misc': misc_a2l,
        'watabou': watabou_a2l,
        'itemuse': itemuse_a2l,
        'spell': spell_a2l,
    }


def generate_dispatch_text_section(rom):
    """Generate dispatch text strings ($4AA8-$5B1E) as raw hex with address comments."""
    lines = []
    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Dispatch Text Strings ($4AA8-$5B1E)')
    lines.append('; Various game text referenced by dispatch table at $4001')
    lines.append('; Contains control codes: $F1=newline, $F2=continue,')
    lines.append('; $F7=end, $F9=param, $FA=wait, $ED=prefix, etc.')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')

    # Collect all labeled addresses in this region from all tables
    all_labels = {}  # addr -> label

    # Dispatch table entries pointing into this region
    for i in range(73):
        off = 1 + i * 2
        ptr = rom[BASE + off] | (rom[BASE + off + 1] << 8)
        if 0x4AA8 <= ptr < 0x5B1F and ptr not in all_labels:
            all_labels[ptr] = 'DispatchText_%02d' % i

    # Misc/watabou/itemuse/spell text in this region
    for table_addr, count, prefix in [
        (MISC1_PTR, 37, 'MiscText'),
        (WATABOU_PTR, 2, 'WatabouText'),
        (ITEMUSE_PTR, 48, 'ItemUseText'),
        (SPELL_PTR, 12, 'SpellUseText'),
    ]:
        ptrs = read_ptr_table(rom, table_addr, count)
        for i, ptr in enumerate(ptrs):
            if 0x4AA8 <= ptr < 0x5B1F and ptr not in all_labels:
                all_labels[ptr] = '%s_%02d' % (prefix, i)

    # Output with labels at known addresses
    sorted_label_addrs = sorted(all_labels.keys())
    label_set = set(sorted_label_addrs)

    addr = 0x4AA8
    end_addr = 0x5B1F
    while addr < end_addr:
        if addr in label_set:
            lines.append('%s:' % all_labels[addr])
        remaining = end_addr - addr
        chunk = min(16, remaining)
        # Don't split across a label boundary
        for la in sorted_label_addrs:
            if addr < la < addr + chunk:
                chunk = la - addr
                break
        off = rom_off(addr)
        hex_vals = ', '.join('$%02X' % rom[off + j] for j in range(chunk))
        lines.append('    db %s  ; $%04X' % (hex_vals, addr))
        addr += chunk

    return lines


def generate_fixed_skill_names(rom):
    """Generate corrected SkillNameStrings (222 unique + 1 empty)."""
    lines = []
    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Skill Name Strings ($628E)')
    lines.append('; 222 unique entries + 1 empty terminator, $F0 terminated')
    lines.append('; Pointer table at $4539 references these by label')
    lines.append('; Entries 222-255 in the pointer table point to the empty entry')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('SkillNameStrings:')

    skill_ptrs = read_ptr_table(rom, 0x4539, 256)

    # Build unique addr -> first index mapping
    unique = {}
    for i, ptr in enumerate(skill_ptrs):
        if ptr not in unique:
            unique[ptr] = i

    for addr in sorted(unique.keys()):
        first_idx = unique[addr]
        decoded, raw = decode_string(rom, addr)
        if first_idx == 222 and not decoded:
            # Empty entry — match existing ptr table label
            label = 'SkillName_222_Unused_222'
        else:
            lname = safe_label(decoded) or 'Empty_%d' % first_idx
            label = 'SkillName_%03d_%s' % (first_idx, lname)
        db_str = string_to_db(decoded, raw)
        lines.append('%s: %s' % (label, db_str))

    return lines


def generate_family_code_strings(rom, addr_to_label):
    """Generate family code string entries ($69F2-$6C77)."""
    lines = []
    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Family Code Strings ($69F2-$6C77)')
    lines.append('; 2-letter family abbreviation + $F0 terminator')
    lines.append('; Indexed by FamilyCodePtrTable at $4739')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('FamilyCodeStrings:')

    for addr in sorted(addr_to_label.keys()):
        label = addr_to_label[addr]
        decoded, raw = decode_string(rom, addr)
        db_str = string_to_db(decoded, raw)
        lines.append('%s: %s' % (label, db_str))

    return lines


def generate_item_name_strings(rom, item_a2l, desc_a2l):
    """Generate item name + empty-item-desc entries."""
    lines = []

    # The ItemName[0] empty entry is at the END of family codes region
    # It's a shared $F0 byte. Find it.
    item_ptrs = read_ptr_table(rom, ITEM_NAME_PTR, 44)
    desc_ptrs = read_ptr_table(rom, ITEM_DESC_PTR, 44)

    # ItemName[0] points to $6C77 (just $F0)
    # Output that first
    if item_ptrs[0] not in [p for p in item_ptrs[1:]]:
        # It's unique to entry 0
        label = item_a2l[item_ptrs[0]]
        lines.append('%s: db $F0  ; no item' % label)

    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Item Name Strings ($6C78-$6DF7)')
    lines.append('; 43 items, $F0 terminated, charmap encoded')
    lines.append('; Indexed by ItemNamePtrTable at $48E7')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('ItemNameStrings:')

    # Output unique item name strings (skip the empty entry)
    for addr in sorted(item_a2l.keys()):
        if addr == item_ptrs[0]:
            continue  # already output
        label = item_a2l[addr]
        decoded, raw = decode_string(rom, addr)
        db_str = string_to_db(decoded, raw)
        lines.append('%s: %s' % (label, db_str))

    # ItemDesc[0] empty entry at $6DF7
    if desc_ptrs[0] not in [p for p in desc_ptrs[1:]]:
        label = desc_a2l[desc_ptrs[0]]
        lines.append('%s: db $F0  ; no description' % label)

    return lines


def generate_item_desc_strings(rom, desc_a2l):
    """Generate item description string entries."""
    lines = []
    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Item Description Strings ($6DF8-$7158)')
    lines.append('; 43 entries with control codes ($F1=newline)')
    lines.append('; Indexed by ItemDescPtrTable at $493F')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('ItemDescStrings:')

    desc_ptrs = read_ptr_table(rom, ITEM_DESC_PTR, 44)

    for addr in sorted(desc_a2l.keys()):
        if addr == desc_ptrs[0]:
            continue  # empty entry already output
        label = desc_a2l[addr]
        decoded, raw = decode_string(rom, addr)
        db_str = string_to_db(decoded, raw)
        # Find which item this is for comment
        for i, ptr in enumerate(desc_ptrs):
            if ptr == addr:
                comment = '  ; %s' % ITEM_NAMES[i] if i < len(ITEM_NAMES) and ITEM_NAMES[i] else ''
                break
        else:
            comment = ''
        lines.append('%s: %s%s' % (label, db_str, comment))

    return lines


def generate_personality_strings(rom, pers_a2l):
    """Generate personality name string entries."""
    lines = []
    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Personality Name Strings ($7159-$7228)')
    lines.append('; 27 entries, $F0 terminated')
    lines.append('; Indexed by PersonalityNamePtrTable at $4997')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')
    lines.append('PersonalityNameStrings:')

    for addr in sorted(pers_a2l.keys()):
        label = pers_a2l[addr]
        decoded, raw = decode_string(rom, addr)
        db_str = string_to_db(decoded, raw)
        lines.append('%s: %s' % (label, db_str))

    return lines


def generate_post_personality_text(rom, label_maps):
    """Generate text strings from $7229 to end of bank ($7FFF)."""
    lines = []
    lines.append('')
    lines.append('; ---------------------------------------------------------------')
    lines.append('; Game Text Strings ($7229-$7FFF)')
    lines.append('; Battle tactics, level up messages, item/spell use text, etc.')
    lines.append('; Contains control codes throughout')
    lines.append('; ---------------------------------------------------------------')
    lines.append('')

    # Collect all labeled addresses in this region
    all_text_addrs = {}  # addr -> label

    for name, a2l in [('misc', label_maps['misc']),
                       ('watabou', label_maps['watabou']),
                       ('itemuse', label_maps['itemuse']),
                       ('spell', label_maps['spell'])]:
        for addr, label in a2l.items():
            if addr >= 0x7229 and addr not in all_text_addrs:
                all_text_addrs[addr] = label

    # Also check dispatch entries for this region
    for i in range(73):
        off = 1 + i * 2
        ptr = rom[BASE + off] | (rom[BASE + off + 1] << 8)
        if ptr >= 0x7229 and ptr not in all_text_addrs:
            all_text_addrs[ptr] = 'DispatchText_%02d' % i

    sorted_addrs = sorted(all_text_addrs.keys())
    label_set = set(sorted_addrs)

    # Output region from $7229 to $7FFF (inclusive = $8000 exclusive)
    addr = 0x7229
    end_addr = 0x8000
    while addr < end_addr:
        if addr in label_set:
            lines.append('%s:' % all_text_addrs[addr])
        remaining = end_addr - addr
        chunk = min(16, remaining)
        # Don't split across a label boundary
        for la in sorted_addrs:
            if addr < la < addr + chunk:
                chunk = la - addr
                break
        off = rom_off(addr)
        hex_vals = ', '.join('$%02X' % rom[off + j] for j in range(chunk))
        lines.append('    db %s  ; $%04X' % (hex_vals, addr))
        addr += chunk

    return lines


def main():
    rom = read_rom()
    apply_mode = '--apply' in sys.argv

    # Generate all sections
    ptr_section, label_maps = generate_ptr_table_section(rom)
    dispatch_section = generate_dispatch_text_section(rom)
    skill_section = generate_fixed_skill_names(rom)
    family_section = generate_family_code_strings(rom, label_maps['fam'])
    item_section = generate_item_name_strings(rom, label_maps['item'], label_maps['desc'])
    desc_section = generate_item_desc_strings(rom, label_maps['desc'])
    pers_section = generate_personality_strings(rom, label_maps['pers'])
    post_pers_section = generate_post_personality_text(rom, label_maps)

    if not apply_mode:
        print('=== POINTER TABLES ===')
        print('\n'.join(ptr_section[:30]))
        print('  ... (%d total lines)' % len(ptr_section))
        print()
        print('=== DISPATCH TEXT ===')
        print('(%d lines)' % len(dispatch_section))
        print()
        print('=== FIXED SKILL NAMES ===')
        print('\n'.join(skill_section[:15]))
        print('  ... (%d total lines)' % len(skill_section))
        print()
        print('=== FAMILY CODES ===')
        print('\n'.join(family_section[:15]))
        print('  ... (%d total lines)' % len(family_section))
        print()
        print('=== ITEM NAMES ===')
        print('\n'.join(item_section))
        print()
        print('=== ITEM DESCS ===')
        print('\n'.join(desc_section[:10]))
        print('  ... (%d total lines)' % len(desc_section))
        print()
        print('=== PERSONALITY ===')
        print('\n'.join(pers_section))
        print()
        print('=== POST-PERSONALITY TEXT ===')
        print('(%d lines)' % len(post_pers_section))
        print()
        print('=== SUMMARY ===')
        for name, section in [
            ('Pointer tables', ptr_section),
            ('Dispatch text', dispatch_section),
            ('Fixed skill names', skill_section),
            ('Family codes', family_section),
            ('Item names', item_section),
            ('Item descs', desc_section),
            ('Personality', pers_section),
            ('Post-personality', post_pers_section),
        ]:
            print('  %s: %d lines' % (name, len(section)))
        return

    # === APPLY MODE ===
    with open(ASM_PATH, 'r') as f:
        asm_lines = f.readlines()

    # Find section boundaries
    raw_start = None      # "--- Other pointer/data tables" comment
    mon_names_hdr = None  # Comment block before MonsterNameStrings
    mon_names_label = None # MonsterNameStrings: label line
    skill_hdr = None      # Start of skill name comment block
    skill_end = None      # Line after last SkillName_XXX: db line

    for i, line in enumerate(asm_lines):
        s = line.strip()
        if s.startswith('; --- Other pointer/data tables'):
            raw_start = i
        if s == 'MonsterNameStrings:':
            mon_names_label = i
        if 'SkillNameStrings:' in s and not s.startswith(';') and not s.startswith('dw'):
            # Found the label itself
            pass

    # Find the comment block before MonsterNameStrings
    if mon_names_label is not None:
        j = mon_names_label
        while j > 0 and (asm_lines[j-1].strip().startswith(';') or asm_lines[j-1].strip() == ''):
            j -= 1
        mon_names_hdr = j

    # Find skill names section: comment block + label + all db lines
    for i, line in enumerate(asm_lines):
        if 'SkillNameStrings:' in line.strip() and not line.strip().startswith(';'):
            j = i
            while j > 0 and (asm_lines[j-1].strip().startswith(';') or asm_lines[j-1].strip() == ''):
                j -= 1
            skill_hdr = j

    # Find end of skill names: last SkillName_ db line
    for i in range(len(asm_lines) - 1, -1, -1):
        if 'SkillName_' in asm_lines[i] and ': db' in asm_lines[i]:
            skill_end = i + 1
            break

    if None in (raw_start, mon_names_hdr, skill_hdr, skill_end):
        print('ERROR: Could not find section boundaries')
        print('raw_start=%s mon_names_hdr=%s skill_hdr=%s skill_end=%s' %
              (raw_start, mon_names_hdr, skill_hdr, skill_end))
        sys.exit(1)

    print('Section boundaries (0-indexed):')
    print('  Header+code+MonsterPtrTable+SkillPtrTable: 0-%d' % (raw_start - 1))
    print('  Raw tables to replace: %d-%d' % (raw_start, mon_names_hdr - 1))
    print('  MonsterNameStrings (preserve): %d-%d' % (mon_names_hdr, skill_hdr - 1))
    print('  SkillNameStrings (replace): %d-%d' % (skill_hdr, skill_end - 1))
    print('  After skills (replace): %d-%d' % (skill_end, len(asm_lines) - 1))

    # Build new file
    new_lines = []

    # Part 1: Header + code + MonsterNamePtrTable + SkillNamePtrTable (preserve)
    new_lines.extend(asm_lines[:raw_start])

    # Part 2: New pointer tables + code functions
    new_lines.extend(line + '\n' for line in ptr_section)

    # Part 3: Dispatch text strings
    new_lines.extend(line + '\n' for line in dispatch_section)

    # Part 4: MonsterNameStrings (preserve)
    new_lines.extend(asm_lines[mon_names_hdr:skill_hdr])

    # Part 5: Fixed SkillNameStrings
    new_lines.extend(line + '\n' for line in skill_section)

    # Part 6: Family code strings
    new_lines.extend(line + '\n' for line in family_section)

    # Part 7: Item name strings
    new_lines.extend(line + '\n' for line in item_section)

    # Part 8: Item description strings
    new_lines.extend(line + '\n' for line in desc_section)

    # Part 9: Personality name strings
    new_lines.extend(line + '\n' for line in pers_section)

    # Part 10: Post-personality text to end of bank
    new_lines.extend(line + '\n' for line in post_pers_section)

    with open(ASM_PATH, 'w') as f:
        f.writelines(new_lines)

    print('Wrote %d lines to %s' % (len(new_lines), ASM_PATH))


if __name__ == '__main__':
    main()
