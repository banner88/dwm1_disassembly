"""milly.py — the MILLY HOOK (S121, ROADMAP P3.16 + E7): the romhack's start.

User (S121): "In the intro, when Milayou disappears into dresser when Waroubou
drags her in, do NOT return control to player to play as terry. Instead, play
the disappearing (screen whirling) effect and sound (just like when Terry steps
into dresser)! But redirect to a new custom room. At THIS POINT, player sprite
is no longer Terry, it is MILLY. … Make it so when you tick patch you can
choose where milly appears … This whole thing can be switched off as a 'milly
hook' patch." Answers to the audit: cut right after the first dresser glow;
Milayou's own sprite; Terry's NPC sprites elsewhere stay; a naming step for
cutscenes; an "arrive spinning" tick; the roots room's text editable; no
starter monster (the project gives one).

    custom.milly_hook = {
        "enabled": true,
        "arrive": {"room": "<custom room id>", "screen": 0, "x": 5, "y": 4,
                   "face": "down"},
        "spin": true}                 # Milly spins in like Terry in the roots room

Headless (no Qt). What a build gets with the hook ON (PROJECT_COMPILER §2.34):

* region `milly_bedroom_script` (patches/bank_00e.asm, the bedroom's script 0
  from $0E:$4AA4 = pos 951, 188 bytes): the dresser glow (vanilla 951-955),
  flag MILLY set (Terry stays drawn through the whirl — S121 r2), the hero's name = the default (the 4 font tiles
  $D3-$D6 + $F0 x 4, what the naming screen stores for its offer), then op $3B
  (the wavy whirl, Terry's dresser warp) to the arrival. The rest = $FFFF.
* regions `milly_shape_04a` / `milly_shape_04b` (patches/bank_004.asm): the
  player-SHAPE draw (sprite type 0 — the field player, the naming screen's
  hero icon) asks bank $79 entry 0 for its palette + frame tables;
  `milly_player_sheet` (patches/bank_001.asm): the field sheet load asks
  entry 1; `milly_naming_icon` (patches/bank_009.asm): the naming screen's
  hero icon sheet. All same size (template bank_079_head.asm).
* bank $79 (`hooks79`): the template + Milayou's six frames / palette / gfx-ID
  (the frames are copied to WRAM wMillyLayout at every room load).
* region `milly_name_tiles` (patches/bank_04f.asm): the font's 4 default-name
  tiles drawn "MILLY" (S120b; OFF = the vanilla INCBIN, "TERRY").
* the ARRIVAL room gets a generated entry scene (first of its entry scenes,
  once per game: flag MILLY_ARRIVED) — the hook hides the player before the
  whirl, so the scene shows her: spinning in as a hidden cast NPC with her
  sprite (program $14, exactly vanilla's roots-room spin-in of Terry's NPC
  $5E), then the NPC hidden and the player shown on the same cell in the same
  tick; or (spin off) just shown.

With the hook OFF every one of these is the vanilla / pre-S121 byte stream.
"""

import copy

from . import formats as F
from . import textenc as T

HOOK_FLAG = 0x179F            # the player is Milly (extended flag, saved)
ARRIVED_FLAG = 0x179E         # the arrival scene has played
RESERVED_FLAGS = (ARRIVED_FLAG, HOOK_FLAG)
FLAG_REFS = {'hook:milly': HOOK_FLAG, 'hook:milly_arrived': ARRIVED_FLAG}

# The NPC sprite drawn as the player: Milayou ($14). Measured / read S121 from
# the ROM (test_compiler --rom re-reads them): bank $05 level-2 table
# $05:$407F[$14] -> six frame lists (dy, dx, tile, attr) — down A/B, side A/B,
# up A/B, the same order as the player's own frames ($04:$7237); palette byte
# $05:$4152[$14]; sheet gfx-ID ROM0 $2ADF[$14] (16 tiles, bank $31).
SPRITE = 0x14
SPRITE_ATTR = 0x03
SPRITE_GFX = 0x3114
SPRITE_FRAMES = [
    [(0xF0, 0xF8, 0, 0x00), (0xF0, 0xFF, 0, 0x20), (0xF8, 0xF8, 1, 0x00), (0xF8, 0x00, 2, 0x00)],
    [(0xF0, 0xF8, 0, 0x00), (0xF0, 0xFF, 0, 0x20), (0xF8, 0xFF, 1, 0x20), (0xF8, 0xF7, 2, 0x20)],
    [(0xF0, 0x00, 4, 0x00), (0xF8, 0xF8, 5, 0x00), (0xF8, 0x00, 6, 0x00), (0xF0, 0xF8, 3, 0x00)],
    [(0xF0, 0x00, 4, 0x00), (0xF8, 0xF8, 7, 0x00), (0xF8, 0x00, 8, 0x00), (0xF0, 0xF8, 12, 0x00)],
    [(0xF0, 0xF8, 9, 0x00), (0xF0, 0xFF, 9, 0x20), (0xF8, 0xF8, 10, 0x00), (0xF8, 0x00, 11, 0x00)],
    [(0xF0, 0xF8, 13, 0x00), (0xF0, 0xFF, 13, 0x20), (0xF8, 0xF8, 14, 0x00), (0xF8, 0x00, 15, 0x00)],
]

# The bedroom ($2F) script 0 from pos 951 ($0E:$4AA4) to its end at pos 1044
# ($0E:$4B5E): the dresser glow, Terry runs up, Watabou comes out of the dresser
# and talks, jumps back in, flag $0000, $D974 := 1, end (control to Terry).
BEDROOM_BANK, BEDROOM_ADDR, BEDROOM_POS = 0x0E, 0x4AA4, 951
BEDROOM_WORDS = [
    0xFF21, 0x0060, 0xFF17, 0xFF09, 0x0008, 0xFF22, 0xFF1B, 0x0000, 0xFFE0, 0xFF19,
    0xFF22, 0xFF1A, 0x0000, 0x0030, 0xFF19, 0xFF09, 0x000C, 0xFF21, 0x0060, 0xFF17,
    0xFF09, 0x0008, 0xFF0D, 0x0001, 0x0000, 0x0000, 0xFF21, 0x0055, 0xFF1C, 0x1201,
    0xFF19, 0xFF07, 0x0009, 0xFF06, 0xFF09, 0x0003, 0xFF49, 0x0001, 0xFF09, 0x0003,
    0xFF4A, 0x0001, 0xFF09, 0x0003, 0xFF48, 0x0001, 0xFF09, 0x0005, 0xFF49, 0x0001,
    0xFF09, 0x0005, 0xFF1C, 0x0100, 0xFF19, 0xFF09, 0x0004, 0xFF1C, 0x0101, 0xFF19,
    0xFF09, 0x0008, 0xFF0A, 0x0001, 0xFFD0, 0xFF07, 0x000A, 0xFF06, 0xFF0A, 0x0001,
    0x0030, 0xFF47, 0x0001, 0xFF09, 0x0002, 0xFF1C, 0x0201, 0xFF19, 0xFF0D, 0x0001,
    0x0000, 0x0040, 0xFF0B, 0x0001, 0xFFF0, 0xFF21, 0x0060, 0xFF17, 0xFF03, 0x0000,
    0xFF12, 0xD974, 0x0001, 0xFFFF]
assert len(BEDROOM_WORDS) == 94

HERO_NAME = 0xCA42            # 8 bytes; text code $F6 prints them (TEXT_SYSTEM)
HERO_DEFAULT = [0xD3, 0xD4, 0xD5, 0xD6, 0xF0, 0xF0, 0xF0, 0xF0]

# patches/bank_04f.asm: the 4 default-name font tiles $D3-$D6 ($4F:$4D40) —
# S120b's "MILLY" (textenc.MILLY_GLYPHS), the vanilla file says TERRY.
MILLY_TILES = [T.MILLY_GLYPHS[0xD3 + k].hex() for k in range(4)]
TERRY_INCBIN = '    INCBIN "gfx/image_04f_4d40.2bpp"\t;TERRY'

CAST = '__milly_hook'           # the cast member's actor name in the arrival room
SCENE_ID = '__milly_arrival'
FACES = ('down', 'left', 'up', 'right')


class HookError(ValueError):
    pass


def hook(custom):
    """The hook's settings when it is ON, else None."""
    h = (custom or {}).get('milly_hook')
    if not isinstance(h, dict) or not h.get('enabled'):
        return None
    return h


def arrival(custom):
    """(room id, screen, x, y, face) of the arrival, or a HookError."""
    h = hook(custom) or {}
    a = h.get('arrive')
    if not isinstance(a, dict) or not a.get('room'):
        raise HookError('custom.milly_hook: pick where Milly arrives (arrive.room)')
    try:
        k, x, y = int(a.get('screen', 0)), int(a['x']), int(a['y'])
    except (KeyError, TypeError, ValueError):
        raise HookError('custom.milly_hook.arrive: screen / x / y must be numbers')
    face = a.get('face', 'down')
    if face not in FACES:
        raise HookError(f'custom.milly_hook.arrive.face {face!r}: down / left / up / right')
    if not (0 <= k <= 15 and 0 <= x <= 9 and 0 <= y <= 7):
        raise HookError(f'custom.milly_hook.arrive: screen {k} cell ({x}, {y}) is outside '
                        'the room (screens 0-15, cells 0-9 x 0-7)')
    return str(a['room']), k, x, y, face


# ------------------------------------------------------------------ the arrival scene

def lower(prj):
    """Project pass (before the cutscenes are lowered): the arrival room gets a
    hidden cast member with Milly's sprite at the arrival cell (every state of
    the screen, one NPC number — cutscene_doc.add_cast's rule) and a generated
    entry scene put FIRST, played once per game. Mutates the project's copy."""
    if hook(prj.custom) is None:
        return
    rid, k, x, y, face = arrival(prj.custom)
    room = next((r for r in prj.custom.get('rooms') or [] if r.get('id') == rid), None)
    if room is None:
        raise HookError(f'custom.milly_hook: arrival room {rid!r} is not a room of this project')
    scr = (room.get('screens') or {}).get(str(k))
    if scr is None:
        raise HookError(f'custom.milly_hook: room {rid!r} has no screen {k}')
    spin = bool((hook(prj.custom) or {}).get('spin', True))
    # S121 r2 (user: "terry NPC sprite vanishes abruptly and its a bit jarring"): Terry
    # stays in the bedroom through the whirl (the flag only takes effect at the next
    # field load), so the player is hidden HERE, as the arrival scene's first step
    steps = [{'hide': {'actor': 'player'}}]
    if spin:
        states = scr['states'] if scr.get('states') else [scr]
        from . import cutscene_build as CB
        counts = [sum(1 for e in st.get('npcs') or [] if CB.is_npc_entry(e)) for st in states]
        n = max(counts) + 1
        if n > 8:
            raise HookError(f'custom.milly_hook: room {rid!r} screen {k} has 8 NPCs in a state — '
                            'the spin-in needs one more NPC slot (turn "arrive spinning" off or '
                            'remove an NPC)')
        for st, c in zip(states, counts):
            lst = st.setdefault('npcs', [])
            for _ in range(n - 1 - c):
                lst.append({'kind': 'npc', 'sprite': '0xFF', 'x': 0, 'y': 0, 'hidden': True,
                            'script': 'none', 'comment': 'hidden pad (Milly hook cast)'})
            lst.append({'kind': 'npc', 'sprite': f'0x{SPRITE:02X}', 'x': x, 'y': y,
                        'facing': face, 'hidden': True, 'cast': True, 'script': 'none',
                        'actor': CAST, 'comment': 'Milly hook: Milly spinning in (S121)'})
        steps += [{'show': {'actor': CAST, 'how': 'spin'}},
                  {'face': {'actor': CAST, 'dir': face}},
                  {'hide': {'actor': CAST}}]
    steps += [{'show': {'actor': 'player'}},
              {'face': {'actor': 'player', 'dir': face}}]
    scene = {'id': SCENE_ID, 'name': 'Milly arrives (Milly hook)', 'screen': k,
             'trigger': {'on': 'entry', 'once': f'0x{ARRIVED_FLAG:04X}'},
             'player_start': {'x': x, 'y': y, 'face': face}, 'steps': steps,
             '_then_next': True}
    room['cutscenes'] = [scene] + list(room.get('cutscenes') or [])


def validate(prj):
    """(errors, warnings) of the hook (validators.validate)."""
    errs, warns = [], []
    if hook(prj.custom) is None:
        return errs, warns
    try:
        rid, k, x, y, face = arrival(prj.custom)
    except HookError as ex:
        return [str(ex)], warns
    room = next((r for r in prj.rooms if r.get('id') == rid), None)
    if room is None:
        errs.append(f'custom.milly_hook: arrival room {rid!r} is not a room of this project')
        return errs, warns
    if room.get('placeholder'):
        errs.append(f'custom.milly_hook: arrival room {rid!r} is a placeholder')
    for fl in prj.custom.get('flags') or []:
        if fl.get('_index') in RESERVED_FLAGS:
            errs.append(f"custom.flags {fl.get('name')!r}: flag {F.hexw(fl['_index'])} is the "
                        'Milly hook\'s own flag')
    return errs, warns


# ------------------------------------------------------------------ emitters

def _word_line(w, note=''):
    return f'    dw ${w:04X}' + (f'   ; {note}' if note else '')


def bedroom_lines(prj):
    h = hook(prj.custom)
    if h is None:
        out = ['; vanilla (Milly hook off): the dresser glow, Terry runs up, Watabou, end']
        out += [_word_line(w) for w in BEDROOM_WORDS]
        return out
    rid, k, x, y, face = arrival(prj.custom)
    room = next((r for r in prj.rooms if r.get('id') == rid), None)
    if room is None:
        raise HookError(f'custom.milly_hook: arrival room {rid!r} is not a room of this project')
    mid = F.val(room['mapID'])
    px = ((k % 4) * 10 + x) * 16 + 8
    py = ((k // 4) * 8 + y) * 16 + 8
    seq = [
        ([0xFF21, 0x0060], 'sound $60 — the dresser glows (vanilla pos 951)'),
        ([0xFF17], 'bedroom_tile_swap: the dresser glow'),
        ([0xFF09, 0x0008], 'delay 8'),
        ([0xFF03, HOOK_FLAG], f'set flag ${HOOK_FLAG:04X}: from now the player is Milly (bank $79)'),
    ]
    for i in range(0, 8, 2):
        seq.append(([0xFF13, HERO_NAME + i, HERO_DEFAULT[i] | HERO_DEFAULT[i + 1] << 8],
                    'the hero\'s name = the default MILLY tiles + $F0' if i == 0 else ''))
    if F.mid_region(mid):
        # S140 (ROADMAP ARC CAP3a): the new game stands in region 0 — an arrival
        # room of another region needs the warp's region (op $12 write_ram
        # wWarpRegion = region + 1; bank $73 RegionCommit enters it)
        seq.append(([0xFF12, 'wWarpRegion', F.mid_region(mid) + 1],
                    f'write_ram wWarpRegion: the whirl enters region {F.mid_region(mid)}'))
    seq.append(([0xFF3B, mid & 0xFF, px, py],
                f'warp_fade: the whirl to room ${mid:02X} ({rid}) screen {k} cell ({x}, {y})'))
    seq.append(([0xFFFF], 'end'))
    words, out = [], ['; Milly hook ON (S121, editor2/core/milly.py; custom.milly_hook)']
    for ws, note in seq:
        out.append('    dw ' + ', '.join(w if isinstance(w, str) else f'${w:04X}' for w in ws)
                   + (f'   ; {note}' if note else ''))
        words += ws
    if len(words) > len(BEDROOM_WORDS):
        raise HookError('internal: the hook script is longer than the bedroom tail')
    pad = len(BEDROOM_WORDS) - len(words)
    out.append(f'    dw ' + ', '.join(['$FFFF'] * pad) + '   ; (unused: end words, same size)')
    return out


def emit_region_bedroom(prj, warnings):
    return '\n'.join(bedroom_lines(prj)) + '\n'


def emit_region_shape_04a(prj, warnings):
    """bank $04 entry 2, type < $10 (10 bytes before the ret's own)."""
    if hook(prj.custom) is None:
        return ('    call HramScr_4126\n'
                '    ld de, data_4137        ; load 4137 into de\n')
    return ('    ld hl, $7900                   ; Milly hook: bank $79 entry 0 MillyShapeTable\n'
            '    rst $10                        ;   (palette into $FFCA, DE = the frame tables)\n'
            '    nop\n    nop\n')


def emit_region_shape_04b(prj, warnings):
    """bank $04 entry 3, type < $10."""
    if hook(prj.custom) is None:
        return ('    call HramScr_4126\n'
                '    ld de, data_4137       ;  load 4137 into de\n')
    return ('    ld hl, $7900                   ; Milly hook: bank $79 entry 0 MillyShapeTable\n'
            '    rst $10\n'
            '    nop\n    nop\n')


def emit_region_naming_icon(prj, warnings):
    """bank $09 FollowerGfxTable09 entry 0: the sheet of the naming screen's
    hero icon (type 0, VRAM $8500)."""
    if hook(prj.custom) is None:
        return '    dw $2f00   ; [  0] default\n'
    return (f'    dw ${SPRITE_GFX:04x}   ; [  0] the hero (naming screen icon) — Milly hook: '
            f'NPC sprite ${SPRITE:02X}\'s sheet (was $2f00)\n')


def emit_region_sheet(prj, warnings):
    if hook(prj.custom) is None:
        return '    ld de, $2f00\n    ld hl, $8000\n    call WaitDMATransfer\n'
    return ('    ld hl, $7901                   ; Milly hook: bank $79 entry 1 MillyPlayerSheet\n'
            '    rst $10                        ;   (was ld de, $2f00 / ld hl, $8000 / call WaitDMATransfer)\n'
            '    nop\n    nop\n    nop\n    nop\n    nop\n')


def emit_region_name_tiles(prj, warnings):
    if hook(prj.custom) is None:
        return TERRY_INCBIN + '\n'
    out = ['; Milly hook: the new-game hero name tiles $D3-$D6 drawn "MILLY" (S120b bytes)']
    for k, hx in enumerate(MILLY_TILES):
        b = bytes.fromhex(hx)
        out.append('    db ' + ', '.join(f'${x:02x}' for x in b) + ('\t;MILLY' if k == 0 else ''))
    return '\n'.join(out) + '\n'


LAYOUT_FRAMES = 21            # the player's level-2 table has 21 frames ($04:$7237)
WRAM_LAYOUT_SIZE = 160        # patches/wram.asm wMillyLayout


def layout_image():
    """[(asm line)] the WRAM frame-table image (copied by MillyPlayerSheet):
    L1 (1 word) -> L2 (21 words: frames 0-5 = the sprite's own, 6-20 = empty)
    -> the six frame lists -> an empty list. Pointers are WRAM addresses."""
    l2 = 2
    fr0 = l2 + 2 * LAYOUT_FRAMES
    offs, o = [], fr0
    for fr in SPRITE_FRAMES:
        offs.append(o)
        o += 4 * len(fr) + 1
    empty = o
    size = o + 1
    if size > WRAM_LAYOUT_SIZE:
        raise HookError('internal: the frame tables outgrow wMillyLayout')
    out = ['MillyLayoutImage:',
           f'    dw wMillyLayout + {l2}   ; level 1 [$FFC7 = 0] -> level 2']
    names = ['down A', 'down B', 'side A', 'side B', 'up A', 'up B']
    for i in range(LAYOUT_FRAMES):
        tgt = offs[i] if i < len(offs) else empty
        out.append(f'    dw wMillyLayout + {tgt}   ; frame {i}'
                   + (f' {names[i]}' if i < len(names) else ' (none on an NPC sheet)'))
    for i, fr in enumerate(SPRITE_FRAMES):
        out.append('    db ' + ', '.join(f'${dy:02x}, ${dx:02x}, ${t:02x}, ${a:02x}'
                                          for dy, dx, t, a in fr) + f', $80   ; frame {i}')
    out.append('    db $80   ; the empty frame')
    out.append('MillyLayoutImageEnd:')
    return out


def emit_bank_079(prj, warnings, head):
    if hook(prj.custom) is None:
        return ('; BANK $79 — story hooks (S121): EMPTY, the Milly hook is off (vanilla zeros).\n'
                'SECTION "ROM Bank $079", ROMX[$4000], BANK[$79]\n'
                '    ds $4000, $00\n')
    out = [head.rstrip('\n'), '',
           '; ' + '=' * 77,
           '; MILLY HOOK DATA (generated by editor2 `hooks79`, editor2/core/milly.py):',
           f'; the player drawn as NPC sprite ${SPRITE:02X} (Milayou) — bank $05 frames, palette,',
           '; sheet gfx-ID (ROM0 $2ADF).',
           '; ' + '=' * 77,
           f'MillyPlayerAttr:  db ${SPRITE_ATTR:02X}          ; $05:$4152[${SPRITE:02X}]',
           f'MillyPlayerGfx:   dw ${SPRITE_GFX:04X}        ; ROM0 $2ADF[${SPRITE:02X}]']
    out += layout_image()
    return '\n'.join(out) + '\n'


REGIONS = [
    ('milly_bedroom_script', 'patches/bank_00e.asm', emit_region_bedroom, 0x0E),
    ('milly_shape_04a', 'patches/bank_004.asm', emit_region_shape_04a, 0x04),
    ('milly_shape_04b', 'patches/bank_004.asm', emit_region_shape_04b, 0x04),
    ('milly_player_sheet', 'patches/bank_001.asm', emit_region_sheet, 0x01),
    ('milly_naming_icon', 'patches/bank_009.asm', emit_region_naming_icon, 0x09),
    ('milly_name_tiles', 'patches/bank_04f.asm', emit_region_name_tiles, 0x4F),
]


def apply_preview_glyphs(custom):
    """The editor's text previews draw the default name as the build will: MILLY
    with the hook on, the ROM's TERRY otherwise (textenc.use_hero_glyphs)."""
    T.use_hero_glyphs(hook(custom) is not None)


# ------------------------------------------------------------------ the roots room

ROOTS_SOURCE = 0x08               # the tree-root chamber (Terry's dresser arrival)
ROOTS_NAME = 'Roots room (Milly)'
ROOTS_SCENE = 'milly_roots'
WARUBOU_SPRITE = 0x39             # grey Warubou (the east room's NPC 2)
ROOTS_ARRIVAL = (0, 5, 4, 'down')  # where Terry's NPC spins in ($08 state 6: (5, 4))
ROOTS_TEXT = [                      # "Warubou:" takes 8 of box 1 line 1's 18 cells
    ['Heh heh!', 'You came through!'],
    ['You must be the', 'girl, Milayou.'],
    ['This is GreatLog,', 'my kingdom.'],
    ['Come along. The', 'King wants you.'],
]
# S121 r3 (user: "Waroubou text box, naming screen, then another box so I can sandwich it
# between"): with the naming option his lines are split around a "Name the hero" step
ROOTS_TEXT_ASK = [
    ['Heh heh!', 'You came through!'],
    ['This is GreatLog,', 'my kingdom.'],
    ['And who might', 'you be, girl?'],
]
ROOTS_TEXT_AFTER = [
    ['{hero}, eh?', 'Heh heh!'],
    ['Come along. The', 'King wants you.'],
]


def _say(boxes):
    return {'say': {'boxes': [list(b) for b in boxes], 'speaker': 'Warubou'}}


def has_naming(scene):
    """Does the roots scene open the naming screen (a top-level name_hero step)?"""
    return any('name_hero' in st for st in scene.get('steps') or [])


def set_naming(scene, on):
    """Add / remove the naming screen in the roots scene: ON puts "Name the hero"
    + a text box (ROOTS_TEXT_AFTER) right after Warubou's first text; OFF removes
    each name_hero step and the text box right after it. Mutates `scene`."""
    steps = scene.setdefault('steps', [])
    if on:
        if has_naming(scene):
            return
        i = next((j for j, st in enumerate(steps) if 'say' in st), None)
        if i is None:
            i = next((j for j, st in enumerate(steps) if 'move' in st), len(steps)) - 1
        steps[i + 1:i + 1] = [{'name_hero': True}, _say(ROOTS_TEXT_AFTER)]
        return
    out, skip = [], False
    for st in steps:
        if skip and 'say' in st:
            skip = False
            continue
        skip = False
        if 'name_hero' in st:
            skip = True
            continue
        out.append(st)
    steps[:] = out


def roots_scene(dest=None, naming=True):
    """The roots room's own scene (an ordinary editable cutscene): Warubou walks
    up from below the screen as the old man does for Terry, talks, and Milly
    follows him out. `dest` = the move step's {dest, screen, x, y}; `naming` =
    his lines are split around the naming screen (S121 r3)."""
    dest = dest or {'dest': 'vanilla:$01', 'screen': 12, 'x': 4, 'y': 6}
    talk = ([_say(ROOTS_TEXT_ASK), {'name_hero': True}, _say(ROOTS_TEXT_AFTER)] if naming
            else [_say(ROOTS_TEXT)])
    return {
        'id': ROOTS_SCENE, 'name': 'Warubou meets Milly', 'screen': 0,
        'trigger': {'on': 'entry', 'once': 'milly_roots_seen'},
        'player_start': {'x': 5, 'y': 4, 'face': 'down'},
        'steps': [
            {'wait': {'frames': 48}},
            {'walk': {'actor': 'Warubou', 'to': [5, 5]}},
            *talk,
            {'walk': {'actor': 'Warubou', 'to': [5, 9], 'together': True}},
            {'walk': {'actor': 'player', 'to': [5, 7]}},
            {'move': dict(dest)},
        ]}


def roots_npcs():
    """Warubou below the bottom edge (cell (5, 8)), facing up — the old man's
    vanilla entry ($08 states 0-4: `$20, $08, $05, $08, $FF`) with sprite $39."""
    return [{'kind': 'raw', 'bytes': ['0x20', f'0x{WARUBOU_SPRITE:02X}', '0x05', '0x08', '0xFF'],
             'actor': 'Warubou',
             'comment': 'Warubou: below the screen, facing up (the old man\'s place in vanilla $08)'}]


def make_roots_room(room):
    """Turn a fresh copy of vanilla $08 (Document.clone_vanilla) into the roots
    room: one state, its own state counter (not $D951 — the breeding ceremony
    writes that), no game scripts (vanilla $08's entry script hides the player
    and runs the ceremony / Terry), Warubou, the scene. Mutates `room`."""
    scr = room['screens']['0']
    for key in ('states',):
        scr.pop(key, None)
    scr['npcs'] = roots_npcs()
    scr['exits'] = []
    scr['step_counter'] = 'auto'
    room['scripts'] = {}
    room['animation'] = 'none'     # map $08's bank-$01 handler pulses a DMG palette only
    room['cutscenes'] = [roots_scene()]
    return room
