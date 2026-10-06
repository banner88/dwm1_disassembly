"""script_ops.py — what every script opcode DOES, in words (S118, ROADMAP P3.8).

The display / meaning catalogue of the 102 bank-$04 script opcodes ($00-$65),
read from the HANDLER CODE (disassembly/bank_004.asm, annotated S118) and
MEASURED in PyBoy where the code alone does not say what the player sees
(the movement programs below, the walk speeds, the text-box position bits).
Owning prose: documentation/BANK04_SCRIPT_ENGINE.md "Script opcodes as
measured (S118)".

This module is headless (no Qt) and does NOT change how anything is
compiled: the compiler's own names stay in scriptgen.OPS (adding names there
would make Document._migrate rename raw ops in every existing project). It
only tells the Cutscenes tab and the cutscene model what a step means.

    OPS[code] -> Op(name, params, kind, branch, wait, doc)
        params : parameter names (len = arity; S118: $24 / $61 = 1 — their
                 word is read by the SCRIPT BANK's entry 1 / 2, which the S96
                 handler tracer cannot see; tools/script_param_counts.py now
                 follows that read)
        kind   : 'flow' | 'actor' | 'text' | 'state' | 'world' | 'battle' |
                 'party' | 'item' | 'sound' | 'screen' | 'wait'
        branch : index of the branch-target parameter, or None
        wait   : True when the script stops on this step until something
                 happens (a wait, a walk the script waits for, a battle …)
    sentence(code, params, ctx) -> one readable line.
    PROGRAMS / PLAYER_PROGRAMS -> the movement programs of opcode $1C.
"""

from collections import namedtuple

Op = namedtuple('Op', 'name params kind branch wait doc')

FACING = {0: 'down', 1: 'left', 2: 'up', 3: 'right'}

# Opcode $04's screens (bank $09 ScreenEffectTable09, indexed by the first
# parameter; the second is the text id the screen speaks with). Names only
# for the kinds decoded so far (S109 arena, S117 shops); others print a number.
SCREEN_KINDS = {0: 'the shop', 4: 'the arena class menu', 12: 'the shop',
                2: 'the Vault menu', 3: "Pulio's farm menu (pick up / leave monsters)",
                5: 'the arena party list', 6: 'the Starry Shrine breeding list',
                7: 'the egg appraiser', 8: 'the Library (look up a family)',
                9: 'the Monster Namer (rename a monster)', 10: "the MedalMan's medal exchange",
                11: 'the shrine entry screen', 13: "the list of Travelers' Gates",
                15: 'the naming screen (the name $C8F2 points at)',
                1: 'nothing (closes)', 14: 'nothing (closes)'}

_P = lambda *names: tuple(names)

OPS = {
    0x00: Op('if_flag_clear', _P('flag', 'target'), 'flow', 1, False,
             'Go to target when the event flag is CLEAR (else carry on).'),
    0x01: Op('if_flag_set', _P('flag', 'target'), 'flow', 1, False,
             'Go to target when the event flag is SET.'),
    0x02: Op('clear_flag', _P('flag'), 'state', None, False, 'Clear an event flag.'),
    0x03: Op('set_flag', _P('flag'), 'state', None, False, 'Set an event flag.'),
    0x04: Op('open_screen', _P('kind', 'text'), 'screen', None, True,
             'Open a game screen of bank $09 (0 / 12 = the shop, 4 = the arena '
             'class menu, …) speaking with the text id; plays sound $59 unless '
             'kind is 9 or 10.'),
    0x05: Op('battle', _P('enemy'), 'battle', None, True,
             'Fight one enemy (enemy-stats row). A win resumes the script; a '
             'loss sends you to the Castle.'),
    0x06: Op('close_text', _P(), 'text', None, True, 'Close the open text box.'),
    0x07: Op('init_dialog', _P(), 'text', None, True,
             'Open dialog mode (needed before text in a script that did not '
             'start by talking to someone).'),
    0x08: Op('nop', _P(), 'flow', None, True, 'Nothing (one tick).'),
    0x09: Op('delay', _P('ticks'), 'wait', None, True,
             'Wait. Counts down once every 8 frames (field mode; PyBoy S118).'),
    0x0A: Op('walk_x_wait', _P('actor', 'pixels'), 'actor', None, True,
             'One actor walks left/right by pixels; the script waits for it. '
             '3 px per 4 frames.'),
    0x0B: Op('walk_y_wait', _P('actor', 'pixels'), 'actor', None, True,
             'One actor walks up/down by pixels; the script waits for it.'),
    0x0C: Op('face', _P('actor', 'direction'), 'actor', None, False,
             'Turn an actor: 0 down, 1 left, 2 up, 3 right (0 = the player).'),
    0x0D: Op('npc_write', _P('actor', 'field', 'value'), 'actor', None, False,
             'Write one byte of an actor\'s RAM slot. Field 0 is the type byte: '
             '$00 = shown, $40 = hidden (bit 6). Actor 0: the field word is an '
             'ADDRESS ($FF90 = the player\'s flags; $40 hides the player).'),
    0x0E: Op('branch_screen', _P('screen', 'target'), 'flow', 1, False,
             'Go to target when the current screen is this one.'),
    0x0F: Op('map_transition', _P('map', 'x', 'y'), 'world', None, True,
             'Change room: map (low byte; high byte = the gate flag) and the '
             'arrival in absolute pixels. Ends the script.'),
    0x10: Op('walk_to_x', _P('actor', 'x'), 'actor', None, True,
             'One actor walks to an absolute pixel X; the script waits.'),
    0x11: Op('walk_to_y', _P('actor', 'y'), 'actor', None, True,
             'One actor walks to an absolute pixel Y; the script waits.'),
    0x12: Op('write_ram', _P('address', 'value'), 'state', None, False,
             'Write a byte to RAM (step counters, story variables …).'),
    0x13: Op('write_ram2', _P('address', 'value'), 'state', None, False,
             'Write a 16-bit word to RAM.'),
    0x14: Op('goto', _P('target'), 'flow', 0, False, 'Go to target.'),
    0x15: Op('check_and_branch', _P('address', 'value', 'target'), 'flow', 2, False,
             'Go to target when the RAM byte equals value (YES/NO answers are '
             '$C83C: 0 = YES).'),
    0x16: Op('refresh_sprites', _P(), 'screen', None, True,
             'Redraw the sprites and the screen position (one tick).'),
    0x17: Op('bedroom_tile_swap', _P(), 'screen', None, True,
             'Intro bedroom only (screens 4/5): swap tiles $9380<->$9360 and '
             '$9600<->$9620 (the night look).'),
    0x18: Op('give_monster', _P('enemy'), 'party', None, True,
             'A monster built from the enemy row joins (party if fewer than 3).'),
    0x19: Op('wait_movement', _P(), 'wait', None, True,
             'Wait until every queued movement / animation has finished.'),
    0x1A: Op('npc_walk_x', _P('actor', 'pixels'), 'actor', None, False,
             'Queue a left/right walk for an actor (actors walk together; use '
             'wait_movement). 3 px per 4 frames, double with walk_fast.'),
    0x1B: Op('npc_walk_y', _P('actor', 'pixels'), 'actor', None, False,
             'Queue an up/down walk (after a queued X walk of the same actor).'),
    0x1C: Op('trigger_anim', _P('program_actor'), 'actor', None, False,
             'Run movement program $PP on actor $NN (word $PPNN): jumps, hops, '
             'flights, appearing / vanishing … (PROGRAMS). Use wait_movement.'),
    0x1D: Op('lock_movement', _P(), 'actor', None, False,
             'Walks and programs no longer turn the actors (walk backwards).'),
    0x1E: Op('unlock_movement', _P(), 'actor', None, False,
             'Walks turn the actors again.'),
    0x1F: Op('arena_setup', _P(), 'battle', None, False,
             'Set the arena team from wArenaGroup / wColiseumBattle.'),
    0x20: Op('start_battle', _P(), 'battle', None, True,
             'Start the battle already set up ($DA02-$DA08).'),
    0x21: Op('sound', _P('sound'), 'sound', None, False, 'Play a sound effect.'),
    0x22: Op('walk_fast', _P(), 'actor', None, False,
             'The next queued walks run at double speed (until they finish).'),
    0x23: Op('if_slot_skill_a', _P('slot', 'target'), 'flow', 1, False,
             'Go to target when party monster slot knows one of skills '
             '$00-$05/$44/$5C-$5F (its name to $C180).'),
    0x24: Op('draw_tiles', _P('data'), 'screen', None, True,
             'Draw a tile patch (data = address in this script bank) onto the '
             'visible background.'),
    0x25: Op('remove_monster', _P(), 'party', None, False,
             'Remove the monster picked by the last party check ($D8E1).'),
    0x26: Op('reload_room', _P(), 'world', None, True, 'Reload the room.'),
    0x27: Op('refresh_party', _P(), 'party', None, False,
             'Heal every monster — HP and MP to full, ailments cured (bank $01 entry 9 '
             'IteratePartySlots20 over the 20 slots, PyBoy-measured S125), then entry 3.'),
    0x28: Op('if_storage_full', _P('target'), 'flow', 0, False,
             'Go to target when all 20 monster slots are taken.'),
    0x29: Op('add_monster', _P('enemy'), 'party', None, True,
             'Add a monster (enemy row) to the farm.'),
    0x2A: Op('give_item', _P('item'), 'item', None, True, 'Give an item.'),
    0x2B: Op('if_monster_pedigree', _P('target'), 'flow', 0, False,
             'Go to target when a stored monster of level 10+ matches the 8 '
             'bytes at $04:$605C.'),
    0x2C: Op('check_inv_full', _P('target'), 'flow', 0, False,
             'Go to target when the bag (20) is full.'),
    0x2D: Op('monster_slot_dialogue', _P('slot'), 'text', None, True,
             'Say the family line of party monster slot (arena lobby).'),
    0x2E: Op('pick_from_table', _P('row'), 'state', None, False,
             '$D9E0 := table $04:$620D[row*5 + $D9DF - 1].'),
    0x2F: Op('inc_ram', _P('address'), 'state', None, False, 'Add 1 to a RAM byte.'),
    0x30: Op('if_slot_stat_100', _P('slot', 'target'), 'flow', 1, False,
             'Go to target when party slot\'s $CB19 word >= 100.'),
    0x31: Op('if_seen_100', _P('target'), 'flow', 0, False,
             'Go to target when 100+ species are marked in the library.'),
    0x32: Op('if_slot_species_af', _P('slot', 'target'), 'flow', 1, False,
             'Go to target when party slot is species $AF.'),
    0x33: Op('compare_gold', _P('amount'), 'state', None, False,
             'GIVE amount gold (capped at 99,999) — the name is historical: the handler adds '
             '(S124, code-read; the Castle\'s "Found 10,000G").'),
    0x34: Op('if_slot_skill_b', _P('slot', 'target'), 'flow', 1, False,
             'Go to target when party slot knows skill $0F/$10/$11/$45/$5A.'),
    0x35: Op('refresh_party2', _P(), 'party', None, False, 'Re-count the party.'),
    0x36: Op('mimic_battle', _P(), 'battle', None, True,
             'Fight the Mimic of the current arena tier.'),
    0x37: Op('give_stored_item', _P('index'), 'item', None, False,
             'Give the item stored at $D9CF + index (name to $C180).'),
    0x38: Op('if_slot_skill_c', _P('slot', 'target'), 'flow', 1, False,
             'Go to target when party slot knows skill $84-$87.'),
    0x39: Op('load_text', _P('text'), 'text', None, False,
             'Resolve a text id (TextBankDispatch) without showing it.'),
    0x3A: Op('to_breeding_scene', _P(), 'world', None, True,
             'Go to the breeding ceremony (map $08) with the chosen monster.'),
    0x3B: Op('warp_fade', _P('map', 'x', 'y'), 'world', None, True,
             'Change room with the wavy fade (the boss-win exit).'),
    0x3C: Op('text_box_bottom', _P(), 'text', None, False,
             'The next text box opens at the BOTTOM of the screen (one box; '
             '$D8D8 bit 0, read by bank $06).'),
    0x3D: Op('text_box_top', _P(), 'text', None, False,
             'The next text box opens at the TOP of the screen ($D8D8 bit 1).'),
    0x3E: Op('change_game_mode', _P(), 'screen', None, True,
             'Fade out and switch to the game mode in $C88B (e.g. a naming '
             'screen) — $C88E is the main loop\'s mode request.'),
    0x3F: Op('load_lead_name', _P(), 'text', None, False,
             'Put the first party monster\'s name in $C180 for the next text.'),
    0x40: Op('if_party_has_species', _P('species', 'target'), 'flow', 1, False,
             'Go to target when a monster of that species is in the party.'),
    0x41: Op('set_bgm', _P('song'), 'sound', None, False,
             'Play a song (the current one is kept for restore_bgm).'),
    0x42: Op('save_return_point', _P('enemy', 'actor'), 'world', None, False,
             'A breeder offers its monster: the mate (an enemy row -> $C8F7, named '
             'by the type-5 menu) + this room and the player\'s spot / facing for '
             'the ceremony\'s return; the actor is turned by $44 on the way back '
             '(S127: param 1 was misnamed "text").'),
    0x43: Op('return_to_saved_point', _P(), 'world', None, True,
             'Go back to the room / spot saved by save_return_point.'),
    0x44: Op('back_from_return', _P(), 'text', None, True,
             'After the return: face as saved, turn the saved actor to the '
             'player and say the saved text + 9.'),
    0x45: Op('restore_party_snapshot', _P(), 'party', None, False,
             'Restore the party list from the $CAB9 snapshot.'),
    0x46: Op('wait_dungeon_flags', _P(), 'wait', None, True,
             'Wait until $DDB4/$DDCE/$DDE8/$DE02 are all $FF.'),
    0x47: Op('face_up', _P('actor'), 'actor', None, False, 'Actor faces up (0 = the player).'),
    0x48: Op('face_down', _P('actor'), 'actor', None, False, 'Actor faces down.'),
    0x49: Op('face_left', _P('actor'), 'actor', None, False, 'Actor faces left.'),
    0x4A: Op('face_right', _P('actor'), 'actor', None, False, 'Actor faces right.'),
    0x4B: Op('restore_bgm', _P(), 'sound', None, False,
             'Play the song set_bgm replaced.'),
    0x4C: Op('wait_dpad', _P(), 'wait', None, True,
             'Wait until the player presses a direction on the D-pad.'),
    0x4D: Op('long_delay', _P('frames'), 'wait', None, True,
             'Wait, counting every script tick ($D8D8 bit 2).'),
    0x4E: Op('save_position', _P(), 'world', None, False,
             'Remember this room and the player\'s spot / facing.'),
    0x4F: Op('return_to_saved_position', _P(), 'world', None, True,
             'Go back to the room / spot saved by save_position.'),
    0x50: Op('face_saved', _P(), 'actor', None, False,
             'The player faces as saved; NPC slot 1 ($D7F8 — Grandpa in the shrine) '
             'faces the player.'),
    0x51: Op('library_tier', _P(), 'state', None, False,
             'Count the library entries -> tier 0-11 in $D8E1 (number to $C180).'),
    0x52: Op('random_battle', _P(), 'battle', None, True,
             'Fight 3 random monsters scaled to the party\'s levels.'),
    0x53: Op('npc1_face_player', _P(), 'actor', None, False,
             'NPC 1 turns toward the player.'),
    0x54: Op('give_random_item', _P(), 'item', None, False,
             'Give a random item 1-37.'),
    0x55: Op('take_random_item', _P(), 'item', None, False,
             'Take a random item from the bag (count to $D8E1).'),
    0x56: Op('gold_value', _P(), 'state', None, False,
             'TAKE a tenth of the gold: $D8E1 := nonzero when gold >= 10, the amount to '
             '$C180 for the next text (S124, code-read: AddGold subtracts).'),
    0x57: Op('give_random_item2', _P(), 'item', None, False,
             'Give a random item $13-$17.'),
    0x58: Op('floor_skip', _P(), 'world', None, True,
             'Gate floors: jump about 20 floors deeper.'),
    0x59: Op('train_slot', _P('slot'), 'party', None, False,
             'Raise party slot\'s weakest stat by 20.'),
    0x5A: Op('trigger_battle3', _P('enemy'), 'battle', None, True,
             'Boss fight with one enemy ($DA09 = 3). A win resumes the script.'),
    0x5B: Op('boss_battle', _P(), 'battle', None, True,
             'Boss fight with the preset enemies ($DA02-$DA08).'),
    0x5C: Op('coliseum_init', _P(), 'battle', None, False,
             'Roll the three Coliseum teams and the prize.'),
    0x5D: Op('give_coliseum_prize', _P(), 'item', None, False,
             'Give the Coliseum prize item.'),
    0x5E: Op('reset_ceremony', _P(), 'state', None, False,
             '$D951 := 7 and clear $C0D8 x 40.'),
    0x5F: Op('if_slot_level_below', _P('slot', 'target'), 'flow', 1, False,
             'Go to target when party slot\'s level (+$4B) is AT its cap (+$4C); the cap\'s '
             'digits go to $C190 (S124, code-read — was worded "below").'),
    0x60: Op('if_gold_short', _P('target'), 'flow', 0, False,
             'Go to target when gold < (plus value +$62 of monster [$CA40] + 1) x 10; '
             'else pay it (the breeding fee; S124, code-read).'),
    0x61: Op('draw_attrs', _P('data'), 'screen', None, True,
             'Draw a background patch\'s colours (VRAM bank 1) from data in '
             'this script bank.'),
    0x62: Op('blank_screen', _P(), 'screen', None, True,
             'Fill tile $DA with $FF and the whole background map with it.'),
    0x63: Op('draw_buffer', _P(), 'screen', None, True,
             'Copy the 20x16 $C300 buffer onto the visible background.'),
    0x64: Op('if_party_healthy', _P('target'), 'flow', 0, False,
             'Go to target when every party monster is at full HP and MP.'),
    0x65: Op('wait_dd80', _P(), 'wait', None, True,
             'Wait until [$DD80] & [$DD9A] == $FF.'),
}

assert len(OPS) == 102

# Opcodes whose next step depends on a run-time condition (for the path model).
CONDITIONAL = {c for c, o in OPS.items() if o.branch is not None and c != 0x14}
TERMINAL = {0x0F, 0x3A, 0x3B, 0x3E, 0x43, 0x4F, 0x58}   # the room / game mode changes: the scene ends

# ---------------------------------------------------------------- programs
# Opcode $1C programs, MEASURED S118 (PyBoy, an NPC in GreatTree screen 0 and
# the player; tools/census_cutscenes.py --programs): per program the name, the
# net pixel move (dx, dy) when it ends, the frames it takes, and what it does
# to the type byte (shown / hidden). Programs $15-$18 read $D8E3 / $D8E4
# (write_ram2 $D8E3 first): the numbers are for $D8E3 = $D8E4 = 3.
# xlow: the program steps ONLY the low byte of the pixel X (`inc/dec [hl]` on
# slot +$18, no carry — $05 / $0C / $19): X wraps inside its 256-px page.
Program = namedtuple('Program', 'name dx dy frames show xlow', defaults=(False,))

PROGRAMS = {          # NPC actors (1-8)
    0x00: Program('walk (the queued dx / dy)', 0, 0, 0, None),
    0x01: Program('hop', 0, 0, 13, None),
    0x02: Program('jump up 2 tiles', 0, -32, 23, None),
    0x04: Program('jump', 0, 0, 17, None),
    0x05: Program('leap 5 tiles right', 80, -8, 40, None, True),
    0x08: Program('appear (flicker in)', 0, 0, 255, True),
    0x09: Program('spin jump', 0, 0, 17, None),
    0x0A: Program('jump up and stay (38 px)', 0, -38, 16, None),
    0x0B: Program('double jump up (58 px)', 0, -58, 37, None),
    0x0C: Program('run off left, sinking', -114, 46, 57, None, True),
    0x0D: Program('vanish (flicker out)', 0, 0, 255, False),
    0x0E: Program('float up 1 tile', 0, -16, 66, None),
    0x0F: Program('leap up 4 tiles', 0, -64, 35, None),
    0x10: Program('hop, then drop 4 tiles', 0, 64, 35, None),
    0x11: Program('drop 4 tiles', 0, 64, 22, None),
    0x12: Program('hop, then drop 2 tiles', 0, 32, 27, None),
    0x13: Program('rise high, hang, settle 40 px up', 0, -40, 66, None),
    0x14: Program('appear spinning (slow flicker)', 0, 0, 0, True),
    0x15: Program('fly in down-left ($D8E3/$D8E4)', -48, 43, 24, None),
    0x16: Program('fly in down-right ($D8E3/$D8E4)', 48, 43, 24, None),
    0x17: Program('fly off up-left ($D8E3 curve)', -48, -44, 26, None),
    0x18: Program('fly off up-right ($D8E3 curve)', 48, -44, 26, None),
    0x19: Program('leap 5 tiles left', -80, 8, 41, None, True),
}
PLAYER_PROGRAMS = {   # actor 0 (the player; buffer $D8E9)
    0x00: Program('walk (the queued dx / dy)', 0, 0, 0, None),
    0x01: Program('hop', 0, 0, 13, None),
    0x03: Program('spin and float up 3 tiles', 0, -48, 63, None),
    0x04: Program('jump', 0, 0, 17, None),
    0x06: Program('pause 64 frames (followers catch up)', 0, 0, 64, None),
    0x07: Program('leap 4 tiles left', -64, 0, 32, None),
    0x1A: Program('spin jump', 0, 0, 17, None),
}


# The fly programs $15-$18 depend on $D8E3 (length: 8 frames and 16 px across per
# unit) and $D8E4 (the curve). (program, $D8E3, $D8E4): (dx, dy, frames), measured
# for an NPC S118 (tools/census_cutscenes.py --fly; user report round S118b).
FLY = {
    (0x15, 1, 0): (-16, 23, 8),
    (0x15, 1, 1): (-16, 10, 8),
    (0x15, 1, 2): (-16, 13, 8),
    (0x15, 1, 3): (-16, 18, 8),
    (0x15, 1, 4): (-16, 23, 8),
    (0x15, 1, 5): (-16, 23, 8),
    (0x15, 2, 0): (-32, 40, 16),
    (0x15, 2, 1): (-32, 14, 16),
    (0x15, 2, 2): (-32, 25, 16),
    (0x15, 2, 3): (-32, 32, 16),
    (0x15, 2, 4): (-32, 40, 16),
    (0x15, 2, 5): (-32, 40, 16),
    (0x15, 3, 0): (-48, 53, 24),
    (0x15, 3, 1): (-48, 16, 24),
    (0x15, 3, 2): (-48, 30, 24),
    (0x15, 3, 3): (-48, 43, 24),
    (0x15, 3, 4): (-48, 53, 24),
    (0x15, 3, 5): (-48, 53, 24),
    (0x15, 4, 0): (-64, 60, 33),
    (0x15, 4, 1): (-64, 16, 33),
    (0x15, 4, 2): (-64, 32, 33),
    (0x15, 4, 3): (-64, 47, 33),
    (0x15, 4, 4): (-64, 60, 33),
    (0x15, 4, 5): (-64, 60, 33),
    (0x15, 5, 0): (-80, 64, 41),
    (0x15, 5, 1): (-80, 16, 41),
    (0x15, 5, 2): (-80, 32, 41),
    (0x15, 5, 3): (-80, 48, 41),
    (0x15, 5, 4): (-80, 64, 41),
    (0x15, 5, 5): (-80, 64, 41),
    (0x15, 6, 0): (-96, 64, 49),
    (0x15, 6, 1): (-96, 16, 49),
    (0x15, 6, 2): (-96, 32, 49),
    (0x15, 6, 3): (-96, 48, 49),
    (0x15, 6, 4): (-96, 64, 49),
    (0x15, 6, 5): (-96, 64, 49),
    (0x15, 7, 0): (-112, 64, 57),
    (0x15, 7, 1): (-112, 16, 57),
    (0x15, 7, 2): (-112, 32, 57),
    (0x15, 7, 3): (-112, 48, 57),
    (0x15, 7, 4): (-112, 64, 57),
    (0x15, 7, 5): (-112, 64, 57),
    (0x15, 8, 0): (-128, 64, 65),
    (0x15, 8, 1): (-128, 16, 65),
    (0x15, 8, 2): (-128, 32, 65),
    (0x15, 8, 3): (-128, 48, 65),
    (0x15, 8, 4): (-128, 64, 65),
    (0x15, 8, 5): (-128, 64, 65),
    (0x15, 9, 0): (-144, 64, 73),
    (0x15, 9, 1): (-144, 16, 73),
    (0x15, 9, 2): (-144, 32, 73),
    (0x15, 9, 3): (-144, 48, 73),
    (0x15, 9, 4): (-144, 64, 73),
    (0x15, 9, 5): (-144, 64, 73),
    (0x16, 1, 0): (16, 23, 8),
    (0x16, 1, 1): (16, 10, 8),
    (0x16, 1, 2): (16, 13, 8),
    (0x16, 1, 3): (16, 18, 8),
    (0x16, 1, 4): (16, 23, 8),
    (0x16, 1, 5): (16, 23, 8),
    (0x16, 2, 0): (32, 40, 16),
    (0x16, 2, 1): (32, 14, 16),
    (0x16, 2, 2): (32, 25, 16),
    (0x16, 2, 3): (32, 32, 16),
    (0x16, 2, 4): (32, 40, 16),
    (0x16, 2, 5): (32, 40, 16),
    (0x16, 3, 0): (48, 53, 24),
    (0x16, 3, 1): (48, 16, 24),
    (0x16, 3, 2): (48, 30, 24),
    (0x16, 3, 3): (48, 43, 24),
    (0x16, 3, 4): (48, 53, 24),
    (0x16, 3, 5): (48, 53, 24),
    (0x16, 4, 0): (64, 60, 33),
    (0x16, 4, 1): (64, 16, 33),
    (0x16, 4, 2): (64, 32, 33),
    (0x16, 4, 3): (64, 47, 33),
    (0x16, 4, 4): (64, 60, 33),
    (0x16, 4, 5): (64, 60, 33),
    (0x16, 5, 0): (80, 64, 41),
    (0x16, 5, 1): (80, 16, 41),
    (0x16, 5, 2): (80, 32, 41),
    (0x16, 5, 3): (80, 48, 41),
    (0x16, 5, 4): (80, 64, 41),
    (0x16, 5, 5): (80, 64, 41),
    (0x16, 6, 0): (96, 64, 49),
    (0x16, 6, 1): (96, 16, 49),
    (0x16, 6, 2): (96, 32, 49),
    (0x16, 6, 3): (96, 48, 49),
    (0x16, 6, 4): (96, 64, 49),
    (0x16, 6, 5): (96, 64, 49),
    (0x16, 7, 0): (112, 64, 57),
    (0x16, 7, 1): (112, 16, 57),
    (0x16, 7, 2): (112, 32, 57),
    (0x16, 7, 3): (112, 48, 57),
    (0x16, 7, 4): (112, 64, 57),
    (0x16, 7, 5): (112, 64, 57),
    (0x16, 8, 0): (128, 64, 65),
    (0x16, 8, 1): (128, 16, 65),
    (0x16, 8, 2): (128, 32, 65),
    (0x16, 8, 3): (128, 48, 65),
    (0x16, 8, 4): (128, 64, 65),
    (0x16, 8, 5): (128, 64, 65),
    (0x16, 9, 0): (144, 64, 73),
    (0x16, 9, 1): (144, 16, 73),
    (0x16, 9, 2): (144, 32, 73),
    (0x16, 9, 3): (144, 48, 73),
    (0x16, 9, 4): (144, 64, 73),
    (0x16, 9, 5): (144, 64, 73),
    (0x17, 1, 0): (-16, -20, 9),
    (0x17, 1, 1): (-16, -20, 9),
    (0x17, 1, 2): (-16, -20, 9),
    (0x17, 1, 3): (-16, -20, 9),
    (0x17, 1, 4): (-16, -20, 9),
    (0x17, 1, 5): (-16, -20, 9),
    (0x17, 2, 0): (-32, -34, 17),
    (0x17, 2, 1): (-32, -34, 17),
    (0x17, 2, 2): (-32, -34, 17),
    (0x17, 2, 3): (-32, -34, 17),
    (0x17, 2, 4): (-32, -34, 17),
    (0x17, 2, 5): (-32, -34, 17),
    (0x17, 3, 0): (-48, -44, 26),
    (0x17, 3, 1): (-48, -44, 26),
    (0x17, 3, 2): (-48, -44, 26),
    (0x17, 3, 3): (-48, -44, 26),
    (0x17, 3, 4): (-48, -44, 26),
    (0x17, 3, 5): (-48, -44, 26),
    (0x17, 4, 0): (-64, -48, 34),
    (0x17, 4, 1): (-64, -48, 34),
    (0x17, 4, 2): (-64, -48, 34),
    (0x17, 4, 3): (-64, -48, 34),
    (0x17, 4, 4): (-64, -48, 34),
    (0x17, 4, 5): (-64, -48, 34),
    (0x17, 5, 0): (-80, -48, 42),
    (0x17, 5, 1): (-80, -48, 42),
    (0x17, 5, 2): (-80, -48, 42),
    (0x17, 5, 3): (-80, -48, 42),
    (0x17, 5, 4): (-80, -48, 42),
    (0x17, 5, 5): (-80, -48, 42),
    (0x17, 6, 0): (-96, -48, 50),
    (0x17, 6, 1): (-96, -48, 50),
    (0x17, 6, 2): (-96, -48, 50),
    (0x17, 6, 3): (-96, -48, 50),
    (0x17, 6, 4): (-96, -48, 50),
    (0x17, 6, 5): (-96, -48, 50),
    (0x17, 7, 0): (-112, -48, 58),
    (0x17, 7, 1): (-112, -48, 58),
    (0x17, 7, 2): (-112, -48, 58),
    (0x17, 7, 3): (-112, -48, 58),
    (0x17, 7, 4): (-112, -48, 58),
    (0x17, 7, 5): (-112, -48, 58),
    (0x17, 8, 0): (-128, -48, 66),
    (0x17, 8, 1): (-128, -48, 66),
    (0x17, 8, 2): (-128, -48, 66),
    (0x17, 8, 3): (-128, -48, 66),
    (0x17, 8, 4): (-128, -48, 66),
    (0x17, 8, 5): (-128, -48, 66),
    (0x17, 9, 0): (-144, -48, 74),
    (0x17, 9, 1): (-144, -48, 74),
    (0x17, 9, 2): (-144, -48, 74),
    (0x17, 9, 3): (-144, -48, 74),
    (0x17, 9, 4): (-144, -48, 74),
    (0x17, 9, 5): (-144, -48, 74),
    (0x18, 1, 0): (16, -20, 9),
    (0x18, 1, 1): (16, -20, 9),
    (0x18, 1, 2): (16, -20, 9),
    (0x18, 1, 3): (16, -20, 9),
    (0x18, 1, 4): (16, -20, 9),
    (0x18, 1, 5): (16, -20, 9),
    (0x18, 2, 0): (32, -34, 17),
    (0x18, 2, 1): (32, -34, 17),
    (0x18, 2, 2): (32, -34, 17),
    (0x18, 2, 3): (32, -34, 17),
    (0x18, 2, 4): (32, -34, 17),
    (0x18, 2, 5): (32, -34, 17),
    (0x18, 3, 0): (48, -44, 26),
    (0x18, 3, 1): (48, -44, 26),
    (0x18, 3, 2): (48, -44, 26),
    (0x18, 3, 3): (48, -44, 26),
    (0x18, 3, 4): (48, -44, 26),
    (0x18, 3, 5): (48, -44, 26),
    (0x18, 4, 0): (64, -48, 34),
    (0x18, 4, 1): (64, -48, 34),
    (0x18, 4, 2): (64, -48, 34),
    (0x18, 4, 3): (64, -48, 34),
    (0x18, 4, 4): (64, -48, 34),
    (0x18, 4, 5): (64, -48, 34),
    (0x18, 5, 0): (80, -48, 42),
    (0x18, 5, 1): (80, -48, 42),
    (0x18, 5, 2): (80, -48, 42),
    (0x18, 5, 3): (80, -48, 42),
    (0x18, 5, 4): (80, -48, 42),
    (0x18, 5, 5): (80, -48, 42),
    (0x18, 6, 0): (96, -48, 50),
    (0x18, 6, 1): (96, -48, 50),
    (0x18, 6, 2): (96, -48, 50),
    (0x18, 6, 3): (96, -48, 50),
    (0x18, 6, 4): (96, -48, 50),
    (0x18, 6, 5): (96, -48, 50),
    (0x18, 7, 0): (112, -48, 58),
    (0x18, 7, 1): (112, -48, 58),
    (0x18, 7, 2): (112, -48, 58),
    (0x18, 7, 3): (112, -48, 58),
    (0x18, 7, 4): (112, -48, 58),
    (0x18, 7, 5): (112, -48, 58),
    (0x18, 8, 0): (128, -48, 66),
    (0x18, 8, 1): (128, -48, 66),
    (0x18, 8, 2): (128, -48, 66),
    (0x18, 8, 3): (128, -48, 66),
    (0x18, 8, 4): (128, -48, 66),
    (0x18, 8, 5): (128, -48, 66),
    (0x18, 9, 0): (144, -48, 74),
    (0x18, 9, 1): (144, -48, 74),
    (0x18, 9, 2): (144, -48, 74),
    (0x18, 9, 3): (144, -48, 74),
    (0x18, 9, 4): (144, -48, 74),
    (0x18, 9, 5): (144, -48, 74),
}


def program(prog, actor):
    tbl = PLAYER_PROGRAMS if actor == 0 else PROGRAMS
    return tbl.get(prog) or Program(f'program ${prog:02X} (does nothing for '
                                    f'{"the player" if actor == 0 else "an NPC"})',
                                    0, 0, 0, None)


def s16(v):
    v &= 0xFFFF
    return v - 0x10000 if v & 0x8000 else v


def _px(v):
    v = s16(v)
    t = abs(v) / 16
    tiles = (f'{t:g} tile' + ('' if t == 1 else 's')) if v % 16 == 0 else f'{abs(v)} px'
    return tiles


def sentence(code, params, ctx=None, target=None):
    """One readable line for a step. ctx (optional) provides:
    ctx.actor(n) -> 'Terry' / 'NPC 2 (Old man)'; ctx.text(id) -> first line;
    ctx.flag(n) -> name; ctx.ram(addr) -> name."""
    actor = (lambda n: ctx.actor(n)) if ctx else (lambda n: 'the player' if n == 0 else f'NPC {n}')
    flag = (lambda n: ctx.flag(n)) if ctx and hasattr(ctx, 'flag') else (lambda n: f'flag ${n:04X}')
    ram = (lambda a: ctx.ram(a)) if ctx and hasattr(ctx, 'ram') else (lambda a: f'${a:04X}')
    p = list(params) + [0] * 4
    op0 = OPS.get(code)
    if target is not None and op0 is not None and op0.branch is not None:
        p[op0.branch] = target           # show the decoded step, not the raw word
    if code == 0x100:
        return 'End — control returns to the player'
    if code == 0x101:
        t = ctx.text(p[0]) if ctx and hasattr(ctx, 'text') else ''
        return f'Text ${p[0]:04X}' + (f': “{t}”' if t else '')
    op = OPS.get(code)
    if op is None:
        return f'Unknown opcode ${code:02X}'
    a0 = p[0]
    if code in (0x1A, 0x0A):
        d = s16(p[1])
        return f'{actor(a0)} walks {"right" if d > 0 else "left"} {_px(d)}' + \
            (' (script waits)' if code == 0x0A else '')
    if code in (0x1B, 0x0B):
        d = s16(p[1])
        return f'{actor(a0)} walks {"down" if d > 0 else "up"} {_px(d)}' + \
            (' (script waits)' if code == 0x0B else '')
    if code == 0x10:
        return f'{actor(a0)} walks to x = {s16(p[1])} px (script waits)'
    if code == 0x11:
        return f'{actor(a0)} walks to y = {s16(p[1])} px (script waits)'
    if code == 0x1C:
        prog, n = (a0 >> 8) & 0xFF, a0 & 0xFF
        nm = program(prog, n).name.replace('($D8E3/$D8E4)', '(the flight path set above)') \
            .replace('($D8E3 curve)', '(the flight path set above)')
        return f'{actor(n)}: {nm}'
    if code in (0x47, 0x48, 0x49, 0x4A):
        return f'{actor(a0)} faces {FACING[{0x47: 2, 0x48: 0, 0x49: 1, 0x4A: 3}[code]]}'
    if code == 0x0C:
        return f'{actor(a0)} faces {FACING.get(p[1] & 3)}'
    if code == 0x0D:
        if a0 == 0:
            if p[1] == 0xFF90:
                return ('The player is ' + ('hidden' if p[2] & 0x40 else 'shown')
                        + (f' (player flags := ${p[2]:02X})' if p[2] not in (0, 0x40) else ''))
            return f'RAM {ram(p[1])} := ${p[2]:02X}'
        if p[1] == 0:
            return f'{actor(a0)} is ' + ('hidden' if p[2] & 0x40 else 'shown') + \
                (f' (type := ${p[2]:02X})' if p[2] not in (0, 0x40) else '')
        if p[1] in (0x18, 0x1A):
            return f'{actor(a0)}: {"x" if p[1] == 0x18 else "y"} low byte := {p[2]}'
        if p[1] == 5:                   # +$05 status (ROOM_DATA_FORMAT "NPC RAM slot")
            w = {0: 'stands still (status cleared)', 1: 'walk animation on',
                 0x40: 'talking pose (faces the player)',
                 0x80: 'animation frozen (kept out of the animation picker)'}.get(p[2])
            if w:
                return f'{actor(a0)}: {w}  [slot +$05 := ${p[2]:02X}]'
        if p[1] == 0x10 and p[2] == 0:
            return f'{actor(a0)}: restart its animation from the first frame  [slot +$10 := 0]'
        if p[1] == 0x14:
            cel = {0: 'facing down', 1: 'facing down (step)', 2: 'facing sideways',
                   3: 'facing sideways (step)', 4: 'facing up', 5: 'facing up (step)'}.get(p[2])
            if cel:
                return f'{actor(a0)}: show the {cel} frame now  [slot +$14 := {p[2]}]'
        fld = {6: 'facing', 8: 'walk-pattern phase', 0x19: 'X position (high)',
               0x1B: 'Y position (high)'}.get(p[1])
        if fld:
            return f'{actor(a0)}: {fld} := {p[2]}'
        return f'{actor(a0)}: slot byte +${p[1]:02X} := ${p[2]:02X}'
    names = getattr(ctx, 'names', None) if ctx else None
    if code in (0x00, 0x01):
        return f'If {flag(a0)} is {"clear" if code == 0 else "set"} → {ctx_label(ctx, p[1])}'
    if code == 0x0E:
        return f'If on screen {a0} → {ctx_label(ctx, p[1])}'
    if code == 0x15:
        if names is not None:
            return (f'If {names.test(a0, p[1] & 0xFF)} → {ctx_label(ctx, p[2])}  '
                    f'[${a0:04X} = {p[1] & 0xFF}]')
        return f'If {ram(a0)} = {p[1]} → {ctx_label(ctx, p[2])}'
    if code == 0x14:
        return f'Go to {ctx_label(ctx, a0)}'
    if code in (0x02, 0x03):
        return f'{"Clear" if code == 2 else "Set"} {flag(a0)}'
    names = getattr(ctx, 'names', None) if ctx else None
    if names is not None and code == 0x12:
        return names.write(a0, p[1] & 0xFF)
    if names is not None and code == 0x13:
        return names.write(a0, p[1] & 0xFFFF, word=True)
    if names is not None and code == 0x2F:
        return names.inc(a0)
    if code == 0x12:
        return f'{ram(a0)} := {p[1] & 0xFF}'
    if code == 0x13:
        return f'{ram(a0)} := ${p[1]:04X} (word)'
    if code == 0x09:
        return f'Wait {a0} ticks (~{a0 * 8} frames)'
    if code == 0x4D:
        return f'Wait {a0} frames'
    if code in (0x0F, 0x3B):
        m = a0 & 0xFF
        rn = ctx.room(m) if ctx and hasattr(ctx, 'room') else None
        return (f'{"Warp (wavy fade)" if code == 0x3B else "Go"} to room ${m:02X}'
                + (f' ({rn})' if rn else '')
                + (f' (gate flag ${a0 >> 8:02X})' if a0 >> 8 else '')
                + f' at ({s16(p[1]) // 16}, {s16(p[2]) // 16})')
    if code == 0x21:
        w = ctx.sound(a0) if ctx and hasattr(ctx, 'sound') else ''
        return f'Sound effect ${a0:02X}' + (f' ({w})' if w else '')
    if code == 0x41:
        w = ctx.music(a0) if ctx and hasattr(ctx, 'music') else ''
        return f'Music ${a0:02X}' + (f' ({w})' if w else '')
    if code == 0x04:
        k = SCREEN_KINDS.get(a0, f'game screen {a0}')
        t = ctx.text(p[1]) if ctx and hasattr(ctx, 'text') and p[1] else ''
        return f'Open {k}' + (f' (its texts begin “{t}”)' if t else '')
    enemy = (lambda r: ctx.enemy(r)) if ctx and hasattr(ctx, 'enemy') else (lambda r: '')
    if code in (0x05, 0x5A):
        e = enemy(a0)
        return f'Battle: {e + " — " if e else ""}enemy row {a0}' + (' (boss)' if code == 0x5A else '')
    if code == 0x2A:
        it = ctx.item(a0) if ctx and hasattr(ctx, 'item') else ''
        return f'Give item {it or a0}' + (f' (item {a0})' if it else '')
    if code in (0x29, 0x18):
        e = enemy(a0)
        return (f'{"Add" if code == 0x29 else "Join"} monster: {e + " — " if e else ""}'
                f'enemy row {a0}')
    if code in (0x24, 0x61):
        pt = ctx.patch(a0) if ctx and hasattr(ctx, 'patch') else None
        what = 'Change the look of' if code == 0x24 else 'Change the colours of'
        if pt:
            w, h, col, row = pt
            return (f'{what} a {w}×{h}-tile piece of the screen at cell ({col // 2}, {row // 2}) '
                    f'(a door / chest / floor piece opening or closing)  [patch ${a0:04X}]')
        return f'{what} part of the screen (tile patch ${a0:04X})'
    # S118f (user: "I want everything interpretable"): the remaining ops in words
    skill = (lambda k: ctx.skill(k)) if ctx and hasattr(ctx, 'skill') else (lambda k: f'skill ${k:02X}')
    species = (lambda k: ctx.species(k)) if ctx and hasattr(ctx, 'species') else (lambda k: f'species ${k:02X}')
    slot = lambda k: f'party monster {k + 1}'
    to = lambda: ctx_label(ctx, p[op.branch]) if op.branch is not None else ''
    if code == 0x23:
        return (f'If {slot(a0)} knows ' + ' / '.join(skill(k) for k in (0, 1, 2, 3, 4, 5, 0x44, 0x5C, 0x5D, 0x5E, 0x5F))
                + f' → {to()}')
    if code == 0x34:
        return f'If {slot(a0)} knows ' + ' / '.join(skill(k) for k in (0x0F, 0x10, 0x11, 0x45, 0x5A)) + f' → {to()}'
    if code == 0x38:
        return f'If {slot(a0)} knows ' + ' / '.join(skill(k) for k in (0x84, 0x85, 0x86, 0x87)) + f' → {to()}'
    if code == 0x30:
        return f"If {slot(a0)}'s ATK is 100 or more → {to()}"
    if code == 0x32:
        return f'If {slot(a0)} is a {species(0xAF)} → {to()}'
    if code == 0x40:
        return f'If a {species(a0)} is in the party → {to()}'
    if code == 0x2D:
        return f'The NPC says the family line of {slot(a0)}'
    if code == 0x2E:
        return f'Goopy game: draw the next pick (row {a0})'
    if code == 0x33:
        return f'Give {a0} G'
    if code == 0x37:
        return f'Give the item in treasure chest {a0 + 1} (and empty it)'
    if code == 0x39:
        t = ctx.text(a0) if ctx and hasattr(ctx, 'text') else ''
        return f'Prepare text ${a0:04X} without showing it' + (f': “{t}”' if t else '')
    if code == 0x42:
        e = enemy(a0)
        return (f"{actor(p[1])} offers its monster for breeding ({e or 'enemy row %d' % a0}); "
                "remember this room and Terry's spot for the ceremony's way back")
    if code == 0x59:
        return f"{slot(a0)}: raise its weakest stat by 20"
    if code in (0x20, 0x5B):
        return ('Start the battle set up above (enemies / count)'
                + (' — a boss battle' if code == 0x5B else ''))
    if code == 0x5E:
        return 'Start the breeding ceremony (stage := 7) and clear the ceremony buffer'
    if code == 0x17:
        return 'Switch the intro bedroom to its night look (tile swap)'
    if code in (0x46, 0x65):
        return 'Wait until the running effect / animation finishes'
    if code == 0x51:
        return 'Count the library: tier 0-11 (to the check result) and the number (for the next text)'
    if code == 0x56:
        return 'Take a tenth of the gold (the check result: had 10 G or more)'
    if op.branch is not None:
        tgt = p[op.branch]
        args = ', '.join(f'{n} {p[i]}' for i, n in enumerate(op.params) if i != op.branch)
        return f'{op.doc.split(".")[0]}{" (" + args + ")" if args else ""} → {ctx_label(ctx, tgt)}'
    if op.params:
        args = ', '.join(f'{n} ${p[i]:04X}' for i, n in enumerate(op.params))
        return f'{op.name.replace("_", " ")} ({args})'
    return op.doc.split('. ')[0].rstrip('.')


def ctx_label(ctx, target):
    if ctx is not None and hasattr(ctx, 'label'):
        return ctx.label(target)
    return f'${target:04X}'
