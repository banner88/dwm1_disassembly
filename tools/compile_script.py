#!/usr/bin/env python3
"""
compile_script.py — Compile human-readable pseudo-code into dw assembly.

This is the reverse of decompile_script.py. Takes the pseudo-code format
and produces RGBDS-compatible `dw` assembly that can be inserted into
script data banks ($0C/$0D/$0E/$0F).

Input format (same as decompiler output):
    MyScript:
        if_flag_set $00F1, goto .post_game
        say $0159
        end
    .post_game:
        set_flag $0160
        say $05D7
        end

Output format (dw assembly):
    MyScript:
        dw $FF01           ; if_flag_set
        dw $00F1           ; flag $00F1
        dw MyScript_post_game ; → .post_game
        dw $0159           ; say
        dw $FFFF           ; end
    MyScript_post_game:
        dw $FF03           ; set_flag
        dw $0160           ; flag $0160
        dw $05D7           ; say
        dw $FFFF           ; end

Usage:
    python3 tools/compile_script.py input.txt              # Compile to stdout
    python3 tools/compile_script.py input.txt -o output.asm # Compile to file
    echo "say \\$0159" | python3 tools/compile_script.py -   # Compile from stdin
    python3 tools/compile_script.py --test                  # Run round-trip test
"""
import sys, re, os

# Opcode name → (opcode number, param count)
OPCODES = {
    # Flow control
    'if_flag_clear':    (0x00, 2),  # flag, branch_addr
    'if_flag_set':      (0x01, 2),  # flag, branch_addr
    'nop':              (0x08, 0),
    'branch_by_screen': (0x0E, 2),  # screen, branch_addr
    'goto':             (0x14, 1),  # branch_addr
    'cond_branch':      (0x15, 3),  # addr, value, branch_addr
    'return':           (0x16, 0),

    # Event flags
    'clear_flag':       (0x02, 1),
    'set_flag':         (0x03, 1),

    # Screen effects
    'screen_effect':    (0x04, 2),
    'fade':             (0x18, 0),
    'map_transition':   (0x0F, 3),
    'screen_setup':     (0x21, 2),

    # Battle
    'battle':           (0x05, 1),
    'arena_battle_setup': (0x1F, 0),
    'set_battle_mode':  (0x20, 1),
    'boss_encounter_setup': (0x35, 0),
    'setup_boss':       (0x36, 1),
    'battle3':          (0x59, 1),

    # Counter/dialog
    'inc_counter':      (0x06, 0),
    'init_dialog':      (0x07, 1),

    # Delay
    'delay':            (0x09, 1),
    'wait_movement':    (0x19, 0),
    'long_delay':       (0x4C, 1),
    'set_secondary_delay': (0x3B, 0),
    'clear_secondary_delay': (0x3C, 0),

    # NPC movement
    'npc_move_x':       (0x0A, 2),
    'npc_move_y':       (0x0B, 2),
    'npc_facing':       (0x0C, 3),
    'npc_write':        (0x0D, 3),
    'npc_moveto':       (0x10, 2),
    'npc_moveto2':      (0x11, 4),
    'npc_walk_x':       (0x1A, 2),
    'npc_walk_y':       (0x1B, 2),
    'trigger_anim':     (0x1C, 1),
    'lock_movement':    (0x1D, 0),
    'unlock_movement':  (0x1E, 0),
    'begin_walk':       (0x22, 0),
    'suppress_movement': (0x26, 0),
    'npc_set_pos_and_face': (0x44, 0),
    'npc_buffer_check': (0x46, 1),
    'npc_set_state':    (0x47, 1),
    'npc_hide':         (0x48, 1),
    'npc_show':         (0x49, 1),

    # RAM operations
    'write_ram':        (0x12, 2),
    'write_ram2':       (0x13, 2),
    'update_screen_vram': (0x24, 0),

    # Sound
    'set_bgm':          (0x40, 1),
    'read_saved_bgm':   (0x4A, 0),
    'restore_bgm':      (0x4B, 0),

    # Gate/map
    'gate_setup':       (0x17, 1),
    'gate_transition':  (0x3A, 3),
    'save_map_return':  (0x41, 2),
    'restore_map':      (0x42, 0),
    'save_gate_info':   (0x4D, 0),
    'restore_from_gate': (0x4E, 0),

    # Monster/inventory
    'check_storage_full': (0x27, 1),  # branch_addr
    'add_monster':      (0x28, 1),
    'give_item':        (0x29, 1),
    'check_level':      (0x2A, 1),
    'check_inv_full':   (0x2C, 1),  # branch_addr (was event_dispatch)
    'monster_slot_dialogue': (0x2D, 1),  # slot index (was check_step)
    'check_monster':    (0x2E, 1),
    'check_story_region': (0x37, 2),  # param, branch_addr

    # State
    'toggle_render':    (0x3D, 0),

    # Misc
    'skip_data':        (0x33, 2),
}

# Opcodes where the LAST parameter is a branch target address
BRANCH_OPCODES = {
    0x00, 0x01, 0x0E, 0x14, 0x15,  # flow control branches
    0x27,  # check_storage_full
    0x2C,  # check_inv_full (was event_dispatch)
    0x37,  # check_story_region
}

# Additional opcode names not in format_cmd but used in scripts
# (these are for opcodes with less common formatting)
EXTRA_OPCODES = {}
for code in range(0x64):
    found = False
    for name, (opnum, _) in OPCODES.items():
        if opnum == code:
            found = True
            break
    if not found:
        EXTRA_OPCODES[code] = f'cmd_{code:02X}'


def parse_value(s):
    """Parse a value like $00F1, 0x00F1, 123, or a label reference."""
    s = s.strip().rstrip(',')
    if s.startswith('$'):
        return int(s[1:], 16)
    elif s.startswith('0x') or s.startswith('0X'):
        return int(s, 16)
    elif s.lstrip('-+').isdigit():
        v = int(s)
        if v < 0:
            v = v + 0x10000  # convert to unsigned 16-bit
        return v & 0xFFFF
    else:
        return s  # label reference


def parse_line(line, script_label):
    """Parse a single pseudo-code line into (opcode_num, [params], comment)."""
    line = line.strip()
    if not line or line.startswith(';'):
        return None

    # Handle 'end'
    if line == 'end':
        return ('end', [], '')

    # Handle 'say $XXXX' — text ID (not an opcode)
    m = re.match(r'say\s+(\$[0-9a-fA-F]+)', line)
    if m:
        text_id = int(m.group(1)[1:], 16)
        comment = ''
        cm = re.search(r';(.+)$', line)
        if cm:
            comment = cm.group(1).strip()
        return ('text', [text_id], comment)

    # Strip trailing comments
    comment = ''
    cm = re.search(r'\s*;(.+)$', line)
    if cm:
        comment = cm.group(1).strip()
        line = line[:cm.start()].strip()

    # Handle trigger_anim special format: trigger_anim npc#N, jump|anim_N
    m = re.match(r'trigger_anim\s+npc#(\d+),\s*(\w+)', line)
    if m:
        npc = int(m.group(1))
        anim_name = m.group(2)
        anim_map = {'jump': 1, 'anim2': 2}
        anim_val = anim_map.get(anim_name, 0)
        if anim_name.startswith('anim_'):
            try: anim_val = int(anim_name[5:])
            except: pass
        packed = (anim_val << 8) | npc
        return (0x1C, [packed], comment)

    # Try to match each opcode
    for name, (opnum, nparams) in OPCODES.items():
        if line.startswith(name):
            rest = line[len(name):].strip()

            # Parse parameters
            params = []
            if rest:
                # Remove "goto" keyword from branch targets
                rest = re.sub(r',?\s*goto\s+', ', ', rest)
                # Split by comma, handling various formats
                parts = [p.strip() for p in rest.split(',') if p.strip()]
                for part in parts:
                    # Handle "npc#N" format
                    nm = re.match(r'npc#(\d+)', part)
                    if nm:
                        params.append(int(nm.group(1)))
                        continue
                    # Handle "dir=N" format
                    nm = re.match(r'dir=(\d+)', part)
                    if nm:
                        params.append(int(nm.group(1)))
                        continue
                    # Handle "enemy=$XXXX" format
                    nm = re.match(r'\w+=(.+)', part)
                    if nm:
                        params.append(parse_value(nm.group(1)))
                        continue
                    # Handle "N frames" format
                    nm = re.match(r'(\d+)\s+frames?', part)
                    if nm:
                        params.append(int(nm.group(1)))
                        continue
                    # Handle "slot=N" format
                    nm = re.match(r'slot=(\d+)', part)
                    if nm:
                        params.append(int(nm.group(1)))
                        continue
                    # Handle label references (.addr_XXXX)
                    nm = re.match(r'\.(\w+)', part)
                    if nm:
                        label = nm.group(1)
                        params.append(f'.{label}')
                        continue
                    # Handle trigger_anim special format
                    nm = re.match(r'(jump|anim\w*)', part)
                    if nm:
                        anim_map = {'jump': 1}
                        anim_val = anim_map.get(nm.group(1), 0)
                        params.append(anim_val)
                        continue
                    # Generic value
                    params.append(parse_value(part))

            return (opnum, params, comment)

    # Try write_ram special format: write_ram [$XXXX] = $XXXX
    m = re.match(r'write_ram\s+\[\$([0-9a-fA-F]+)\]\s*=\s*\$([0-9a-fA-F]+)', line)
    if m:
        return (0x12, [int(m.group(1), 16), int(m.group(2), 16)], comment)

    m = re.match(r'write_ram2\s+\[\$([0-9a-fA-F]+)\]\s*=\s*\$([0-9a-fA-F]+)', line)
    if m:
        return (0x13, [int(m.group(1), 16), int(m.group(2), 16)], comment)

    # Try npc_write special format: npc_write npc#N, field[$XXXX] = $XX
    m = re.match(r'npc_write\s+npc#(\d+),\s*field\[\$([0-9a-fA-F]+)\]\s*=\s*\$([0-9a-fA-F]+)', line)
    if m:
        return (0x0D, [int(m.group(1)), int(m.group(2), 16), int(m.group(3), 16)], comment)

    print(f"WARNING: Could not parse line: {line}", file=sys.stderr)
    return None


def compile_script(text, base_label='Script'):
    """Compile pseudo-code text into dw assembly."""
    lines = text.strip().split('\n')
    output = []
    current_label = base_label
    local_labels = {}  # .name → full_label_name
    words = []  # (value_or_label, comment)

    # Pass 1: collect labels and build word list
    word_list = []  # list of (value_or_label_ref, comment, is_label_def)

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith(';'):
            continue

        # Label definition (script label)
        m = re.match(r'^(\w+):$', stripped)
        if m:
            current_label = m.group(1)
            word_list.append(('LABEL_DEF', current_label, ''))
            continue

        # Local label definition (.addr_XXXX:)
        m = re.match(r'^\.(\w+):$', stripped)
        if m:
            local_name = m.group(1)
            full_name = f'{current_label}_{local_name}'
            local_labels[f'.{local_name}'] = full_name
            word_list.append(('LABEL_DEF', full_name, ''))
            continue

        parsed = parse_line(stripped, current_label)
        if parsed is None:
            continue

        kind, params, comment = parsed

        if kind == 'end':
            word_list.append(('WORD', 0xFFFF, '; end'))
        elif kind == 'text':
            text_id = params[0]
            cmt = f'; say ${text_id:04X}'
            if comment:
                cmt += f'  {comment}'
            word_list.append(('WORD', text_id, cmt))
        else:
            opnum = kind
            # Emit opcode word
            opcode_word = 0xFF00 | opnum
            op_name = None
            for name, (num, _) in OPCODES.items():
                if num == opnum:
                    op_name = name
                    break
            word_list.append(('WORD', opcode_word, f'; {op_name or f"cmd_{opnum:02X}"}'))

            # Emit parameter words
            for i, p in enumerate(params):
                if isinstance(p, str) and p.startswith('.'):
                    # Label reference — resolve later
                    word_list.append(('LABEL_REF', p, f'; → {p}'))
                elif isinstance(p, str):
                    word_list.append(('LABEL_REF', p, f'; → {p}'))
                else:
                    word_list.append(('WORD', p & 0xFFFF, f'; ${p:04X}'))

    # Pass 2: generate output
    output_lines = []
    for kind, value, comment in word_list:
        if kind == 'LABEL_DEF':
            output_lines.append(f'{value}:')
        elif kind == 'WORD':
            output_lines.append(f'    dw ${value:04X}  {comment}')
        elif kind == 'LABEL_REF':
            ref = value
            if ref in local_labels:
                ref = local_labels[ref]
            output_lines.append(f'    dw {ref}  {comment}')

    return '\n'.join(output_lines)


def round_trip_test():
    """Test compile against known decompiled scripts."""
    test_input = """\
TestScript:
    if_flag_set $00F1, goto .post_game
    if_flag_set $0037, goto .s_class
    say $0159
    end
.s_class:
    say $01E4
    end
.post_game:
    set_flag $0160
    say $05D7
    end
"""
    result = compile_script(test_input)
    print("=== INPUT ===")
    print(test_input)
    print("=== OUTPUT ===")
    print(result)
    print()

    # Verify structure
    lines = [l.strip() for l in result.split('\n') if l.strip()]
    labels = [l for l in lines if l.endswith(':')]
    words = [l for l in lines if l.startswith('dw')]
    print(f"Labels: {len(labels)}")
    print(f"Words: {len(words)}")

    # Check expected words
    expected_words = [
        '$FF01',  # if_flag_set
        '$00F1',  # flag
        'TestScript_post_game',  # branch target
        '$FF01',  # if_flag_set
        '$0037',  # flag
        'TestScript_s_class',  # branch target
        '$0159',  # say
        '$FFFF',  # end
        '$01E4',  # say
        '$FFFF',  # end
        '$FF03',  # set_flag
        '$0160',  # flag
        '$05D7',  # say
        '$FFFF',  # end
    ]
    print(f"\nExpected {len(expected_words)} words, got {len(words)}")

    # More complex test
    test2 = """\
GiftScript:
    say $0100
    check_inv_full, goto .full
    give_item $0005
    set_flag $0160
    say $0101
    end
.full:
    say $0102
    end
"""
    result2 = compile_script(test2)
    print("\n=== GIFT SCRIPT TEST ===")
    print(result2)

    # Cutscene test
    test3 = """\
CutsceneScript:
    lock_movement
    npc_show npc#3
    delay 10 frames
    begin_walk
    npc_walk_x npc#3, +48
    wait_movement
    trigger_anim npc#3, jump
    delay 30 frames
    npc_hide npc#3
    unlock_movement
    say $0200
    end
"""
    result3 = compile_script(test3)
    print("\n=== CUTSCENE TEST ===")
    print(result3)


if __name__ == '__main__':
    if '--test' in sys.argv:
        round_trip_test()
    elif len(sys.argv) >= 2 and sys.argv[1] != '-':
        with open(sys.argv[1]) as f:
            text = f.read()
        result = compile_script(text)
        if '-o' in sys.argv:
            idx = sys.argv.index('-o')
            with open(sys.argv[idx + 1], 'w') as f:
                f.write(result)
            print(f"Written to {sys.argv[idx + 1]}")
        else:
            print(result)
    elif len(sys.argv) >= 2 and sys.argv[1] == '-':
        text = sys.stdin.read()
        print(compile_script(text))
    else:
        print(__doc__)
