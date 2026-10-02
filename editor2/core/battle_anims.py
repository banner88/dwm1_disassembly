"""battle_anims.py — the battle-skill ANIMATIONS as data (ROADMAP P3.11e, S112;
owning prose BATTLE_SKILL_SYSTEM §11 "The animation system — as measured S112").

Pure Python, no Qt. Two halves:

1. DECODER (`decode_rom`) — reads the 45 stock animations ("commands" $00-$2C)
   out of the original ROM. Used by tools/decode_battle_animations.py, which
   writes extracted/battle_animations.json (schema 2); the editor and the
   compiler read that JSON (no ROM needed at edit time).

   One animation number C owns (all PyBoy-measured S112,
   tools/census_battle_anims.py — every frame of all 45 == this model):
     * FRAMES   — bank $5C (C < $0E) / $5D (C < $21) / $5E: `AnimFrameTable`
                  $4071 + 2C -> 32 dw frame pointers (unused slots point at an
                  empty `$80` list; slot $1F = the "blank" frame) -> 4-byte
                  sprites (dy, dx, tile, attr), `$80`-terminated. Drawn by the
                  bank's builder at X = dx + [$c3] + 8, Y = dy + [$c5] + 16,
                  tile + [$c9] (0), attr XOR [$ca] (0); 8x8 OBJ (LCDC $83).
     * TIMELINE — bank $02 sequence table row $60 (`AnimTimelineTable`
                  $02:$46A1 + 2C) -> byte pairs (first, second):
                  (f < $F8, h) = show frame f for h+1 frames; ($FD, s) = play
                  sound s (same frame, no time); ($FE, op) = control
                  (op 4 = jump back to step 1 — the projectile loop of $03/$04);
                  ($FF, $FF) = end. Stepped once per frame by the generic bank
                  $02 sequencer (entry 0) on the struct at $DD62 (+0 active,
                  +1 row $60, +2 C, +3 step, +4 frame, +5 hold).
     * TILES    — gfx id `AnimGfxTable` $50:$5E84 + 2C ($5A00-$5A1F,
                  $5B0A-$5B16): an LZ stream decoded to $8000 (2,048 B = 128
                  tiles; at most 48 are drawn) by bank $50 the frame after the
                  start ($DA80 = 1 -> 2).
     * PALETTE  — OBJ palette 0 = `AnimObjPalettes` $17:$6B0D + 8C (4 RGB555),
                  loaded by bank $17 entry 13 with [$c81e] = C, committed by
                  entry 8. (Stock frames use palette 0 only; attr bit 4 = the
                  DMG OBP1 select.)
     * SHADE    — `AnimObjShadeTable` $00:$3141 + C: the DMG OBP1 byte (GBC: unused).

   How a SKILL shows an animation (bank $5F, by skill id through GetPresentId):
     * a ROUTINE index per caster side — `AnimRoutineIdxParty` $58DD (party
       caster), `AnimRoutineIdxEnemy` $59C3 (enemy caster), `AnimRoutineIdxLink`
       $5AA9 (link battles, the second side) — through `AnimRoutineTable` $58BD:
       0 = at the target / 1 = at the middle (all foes) / 2 = on each target in
       turn / 3 = flies across from the left (those four start the animation),
       4-12, 14, 15 = a SCREEN EFFECT (no sprites; bank $5F entry 5 phase
       $DA83), 13 = nothing;
     * the animation number — `AnimCmdTableFoe` $56ED when a party monster
       hits the enemy side, `AnimCmdTableOwn` $57D5 when an enemy acts on its
       own side (and for 6 listed ids); $FF = none. A target on the PARTY side
       never gets sprites (the party side is not drawn).

2. NEW ANIMATIONS (project data, `custom.animations`) — mashups of stock
   frames: `compose()` turns an authored animation (steps that each pick a
   frame of any stock animation, or a sound) into the bytes the engine reads
   (tile sheet, frames with remapped tiles / palettes, timeline, palettes).
   Numbers $2D.. (45..) — PROJECT_COMPILER §2.28.
"""

import json
import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

N_STOCK = 45                     # animation numbers $00-$2C
FRAME_BASE = 0x4071              # AnimFrameTable in each frame bank
FRAMES_PER_ANIM = 32             # dw slots per animation (slot $1F = blank)
BLANK_FRAME = 0x1F
TIMELINE_ROW = 0x60              # bank $02 sequence row of the battle animations
SEQ_TOP = 0x40E3                 # bank $02 sequence row table (97 dw)
TIMELINE_TABLE = 0x46A1          # = row $60
GFX_TABLE = 0x5E84               # bank $50 AnimGfxTable (45 dw)
GFX_TABLE_DEBUG = 0x61EE         # bank $5F, the Effect debugger's copy
PAL_TABLE = 0x6B0D               # bank $17 AnimObjPalettes (45 x 8 B)
SHADE_TABLE = 0x3141             # ROM0 AnimObjShadeTable (45 B)
CMD_FOE, CMD_OWN = 0x56ED, 0x57D5          # bank $5F, 232 B each
ROUTINES = 0x58BD                           # bank $5F, 16 dw
RIDX_PARTY, RIDX_ENEMY, RIDX_LINK = 0x58DD, 0x59C3, 0x5AA9   # 230 B each
SKILL_ROWS = 230                 # rows in the routine-index tables
CMD_ROWS = 232                   # rows in the command tables
SHEET_TILES = 128                # the $8000 OBJ block the sheet is decoded into
MAX_SPRITES = 40                 # OAM — the builder stops at [$cb] = 40 (a stock
                                 # frame may list more: animation $05 frame 5 has 47)


def frame_bank(c):
    return 0x5C if c < 0x0E else (0x5D if c < 0x21 else 0x5E)


# ---------------------------------------------------------------------------
# routines (MEASURED S112 — PyBoy, Blaze with each index forced; the users)
# ---------------------------------------------------------------------------
ROUTINE_INFO = {
    0: ('at the target', 'motion'),
    1: ('in the middle of the foes', 'motion'),
    2: ('on each target in turn', 'motion'),
    3: ('flies across from the left', 'motion'),
    4: ('screen blinks (Radiant, the summons)', 'effect'),
    5: ('screen fades dark and back (UltraDown, ThickFog)', 'effect'),
    6: ('screen effect of Chance', 'effect'),
    7: ('screen fades dark twice', 'effect'),
    8: ('link-battle effect of Explodet / BigBang / MegaMagic', 'effect'),
    9: ('screen effect 9 (no skill uses it)', 'effect'),
    10: ('link-battle effect of Lightning / WhiteAir', 'effect'),
    11: ('link-battle effect of Firebal / IceBolt', 'effect'),
    12: ('link-battle effect of Infermore / Vacuum', 'effect'),
    13: ('nothing', 'none'),
    14: ('screen shakes (TwinSlash, Ramming, Kamikaze)', 'effect'),
    15: ('screen effect of an enemy TwinSlash', 'effect'),
}
MOTIONS = [0, 1, 2, 3]
EFFECTS = [4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15]
NOTHING = 13


def _w(R, bank, addr):
    o = bank * 0x4000 + addr - 0x4000 if bank else addr
    return R[o] | R[o + 1] << 8


def _b(R, bank, addr):
    return R[bank * 0x4000 + addr - 0x4000 if bank else addr]


def read_frame(R, bank, ptr):
    sp, a = [], ptr
    while _b(R, bank, a) != 0x80:
        sp.append([_b(R, bank, a + k) for k in range(4)])
        a += 4
        if len(sp) > 255:                  # stock frame $05:5 lists 47 — the
            raise ValueError(f'frame ${bank:02X}:${ptr:04X} has no $80 end')
    return sp, a + 1


def read_timeline(R, c):
    ptr = _w(R, 2, TIMELINE_TABLE + 2 * c)
    steps, a = [], ptr
    while True:
        f, h = _b(R, 2, a), _b(R, 2, a + 1)
        a += 2
        if f == 0xFF:
            break
        if f == 0xFD:
            steps.append({'sound': h})
        elif f == 0xFE:
            steps.append({'op': h})
        else:
            steps.append({'frame': f, 'hold': h})
    return ptr, a, steps


def decode_rom(R):
    """-> the schema-2 dict of extracted/battle_animations.json (minus _generator)."""
    from dwm.sprite_codec import decode, gfxid_stream_offset, read_stream
    if _w(R, 2, SEQ_TOP + 2 * TIMELINE_ROW) != TIMELINE_TABLE:
        raise ValueError('bank $02 sequence row $60 is not $46A1')
    anims, extents = [], {0x5C: [], 0x5D: [], 0x5E: [], 0x02: [], 0x5A: [], 0x5B: []}
    for c in range(N_STOCK):
        bank = frame_bank(c)
        tab = _w(R, bank, FRAME_BASE + 2 * c)
        ptrs = [_w(R, bank, tab + 2 * i) for i in range(FRAMES_PER_ANIM)]
        frames, uniq = [], {}
        for p in ptrs:
            if p not in uniq:
                sp, end = read_frame(R, bank, p)
                uniq[p] = (sp, end)
                extents[bank].append((p, end))
            frames.append(uniq[p][0])
        extents[bank].append((tab, tab + 2 * FRAMES_PER_ANIM))
        tptr, tend, steps = read_timeline(R, c)
        extents[0x02].append((tptr, tend))
        gid = _w(R, 0x50, GFX_TABLE + 2 * c)
        gb, gi, saddr, off = gfxid_stream_offset(R, gid)
        stream = read_stream(R, off)
        sheet = decode(stream)
        extents[gb].append((saddr, saddr + len(stream)))
        used = sorted({s[2] for fr in frames for s in fr})
        pal = [_w(R, 0x17, PAL_TABLE + 8 * c + 2 * k) for k in range(4)]
        anims.append({
            'id': c, 'frame_bank': bank, 'frame_table': tab,
            'frame_ptrs': ptrs, 'frames': frames,
            'timeline_ptr': tptr, 'timeline': steps,
            'gfx_id': gid, 'stream_addr': saddr, 'stream_len': len(stream),
            'sheet_len': len(sheet),
            'tiles': {str(t): sheet[16 * t:16 * t + 16].hex() for t in used if 16 * t + 16 <= len(sheet)},
            'palette': pal, 'shade': _b(R, 0, SHADE_TABLE + c),
            'gfx_id_debug': _w(R, 0x5F, GFX_TABLE_DEBUG + 2 * c),
        })
    skills = []
    for i in range(CMD_ROWS):
        row = {'id': i, 'cmd_foe': _b(R, 0x5F, CMD_FOE + i), 'cmd_own': _b(R, 0x5F, CMD_OWN + i)}
        if i < SKILL_ROWS:
            row.update({'party': _b(R, 0x5F, RIDX_PARTY + i), 'enemy': _b(R, 0x5F, RIDX_ENEMY + i),
                        'link': _b(R, 0x5F, RIDX_LINK + i)})
        skills.append(row)
    return {'schema': 2, 'animations': anims, 'skills': skills,
            'routines': [_w(R, 0x5F, ROUTINES + 2 * k) for k in range(16)],
            'extents': {f'{k:02X}': sorted(v) for k, v in extents.items()}}


# ---------------------------------------------------------------------------
# the vanilla data for the editor / compiler
# ---------------------------------------------------------------------------
_VAN = {}


def vanilla(repo_root=None):
    repo = repo_root or REPO
    if repo not in _VAN:
        _VAN[repo] = json.load(open(os.path.join(repo, 'extracted', 'battle_animations.json')))
    return _VAN[repo]


def stock(c, repo_root=None):
    return vanilla(repo_root)['animations'][c]


def tile_bytes(c, t, repo_root=None):
    h = stock(c, repo_root)['tiles'].get(str(t))
    return bytes.fromhex(h) if h else bytes(16)


def frame_count(c, repo_root=None):
    """Distinct frames the timeline of C shows (0 .. max used; the blank $1F aside)."""
    a = stock(c, repo_root)
    used = [s['frame'] for s in a['timeline'] if 'frame' in s and s['frame'] != BLANK_FRAME]
    return (max(used) + 1) if used else 0


def sound_ids(repo_root=None):
    """{sound id: [stock animations that cue it]}"""
    out = {}
    for a in vanilla(repo_root)['animations']:
        for s in a['timeline']:
            if 'sound' in s:
                out.setdefault(s['sound'], []).append(a['id'])
    return out


SHADE_ORDER = (1, 2, 0, 3)       # bank $17 $440C: byte offsets 2, 4, 0, 6
IDENTITY_SHADE = 0xD2            # codes 2, 0, 1, 3 -> colours 0, 1, 2, 3 (the battle
                                 # BG default $D2 is the same identity)


def shade_map(shade):
    """The DMG shade as the colour permutation the GBC commit applies (bank $17
    Jump_017_4341 / SavePal_4376, MEASURED S112 on screen): hardware colour i
    of every OBJ palette = buffer colour SHADE_ORDER[(shade >> 2i) & 3]."""
    return [SHADE_ORDER[(shade >> (2 * i)) & 3] for i in range(4)]


def display_palette(c, repo_root=None):
    """Stock animation C's colours as the screen shows them (shade applied)."""
    a = stock(c, repo_root)
    m = shade_map(a['shade'])
    return [a['palette'][m[i]] for i in range(4)]


# ---------------------------------------------------------------------------
# 2. NEW ANIMATIONS — custom.animations (PROJECT_COMPILER §2.28)
# ---------------------------------------------------------------------------
#
#   "custom": {"animations": [
#     {"id": "spark_bolt", "name": "Spark bolt",
#      "steps": [{"from": 16, "frame": 0, "hold": 4},   # Zap's frame 0, 5 frames
#                {"sound": 130},                          # sound $82, no time
#                {"blank": true, "hold": 8},              # nothing, 9 frames
#                {"from": 6, "frame": 3, "hold": 5}]}]}   # Bang's frame 3
#
# Number of an animation = $2D + its index in the list. A step's frame keeps
# its sprites (positions, flips) and its source's colours: every source
# animation gets its own OBJ palette slot (in order of first use).

FIRST_CUSTOM = 0x2D
MAX_CUSTOM = 32                  # the Effect debugger lists $00-$4C
MAX_SOURCES = 4                  # OBJ palette slots 0-3
MAX_TILES = SHEET_TILES          # the $8000 block
MAX_FRAMES = 200                 # frame index < $F8 ($1F is free to use here)
MAX_STEPS = 120                  # pairs (the step index is a byte; + the end)
CUSTOM_BANK, SHEET_BANK = 0x6F, 0x70


class AnimError(ValueError):
    pass


def custom_list(prj_or_data):
    d = prj_or_data if isinstance(prj_or_data, dict) else prj_or_data.data
    return list(((d.get('custom') or {}).get('animations')) or [])


def number_of(prj_or_data, ref):
    """An animation reference -> its number: a stock number 0-44 or the id of
    a custom.animations entry ($2D + index). None if unknown."""
    if isinstance(ref, int) or (isinstance(ref, str) and ref.lstrip('$').isdigit()):
        v = int(ref)
        return v if 0 <= v < N_STOCK else None
    for i, a in enumerate(custom_list(prj_or_data)):
        if a.get('id') == ref:
            return FIRST_CUSTOM + i
    return None


def anim_label(prj_or_data, number, repo_root=None):
    if number is None:
        return '-'
    if number < N_STOCK:
        return f'${number:02X} {stock_name(number, repo_root)}'
    lst = custom_list(prj_or_data)
    i = number - FIRST_CUSTOM
    return f'${number:02X} {lst[i].get("name") or lst[i].get("id")}' if 0 <= i < len(lst) else f'${number:02X}'


def stock_users(c, repo_root=None):
    names = _skill_names(repo_root)
    out = []
    for row in vanilla(repo_root)['skills']:
        if row['cmd_foe'] == c or row['cmd_own'] == c:
            out.append(names.get(row['id'], str(row['id'])))
    return out


def stock_name(c, repo_root=None):
    u = stock_users(c, repo_root)
    return u[0] if u else 'unused'


_NAMES = {}


def _skill_names(repo_root=None):
    repo = repo_root or REPO
    if repo not in _NAMES:
        try:
            _NAMES[repo] = {r['id']: r['name'] for r in json.load(open(os.path.join(
                repo, 'extracted', 'skill_records.json')))['records']}
        except (OSError, ValueError, KeyError):
            _NAMES[repo] = {}
    return _NAMES[repo]


def _int(v, what):
    try:
        return int(v, 0) if isinstance(v, str) else int(v)
    except (TypeError, ValueError):
        raise AnimError(f'{what}: {v!r} is not a number')


def expand_source(c, first=None, last=None, repo_root=None):
    """The steps of stock animation C (optionally only frames first..last of
    its timeline, by STEP order) — what 'Add frames from …' inserts."""
    out = []
    for s in stock(c, repo_root)['timeline']:
        if 'frame' in s:
            if s['frame'] == BLANK_FRAME:
                out.append({'blank': True, 'hold': s['hold']})
            else:
                out.append({'from': c, 'frame': s['frame'], 'hold': s['hold']})
        elif 'sound' in s:
            out.append({'sound': s['sound']})
    if first is not None or last is not None:
        frames = [i for i, s in enumerate(out) if 'from' in s]
        lo = frames[first or 0] if frames else 0
        hi = frames[last] if (last is not None and last < len(frames)) else len(out) - 1
        # keep the sound cues that sit right before a kept frame
        while lo > 0 and 'sound' in out[lo - 1]:
            lo -= 1
        out = out[lo:hi + 1]
    return out


def compose(entry, repo_root=None):
    """An authored animation -> the bytes the engine reads:
    {'frames': [[(dy, dx, tile, attr)]], 'blank': index, 'timeline': [(a, b)],
     'palettes': [[4 x RGB555]], 'sheet': bytes, 'sources': [c], 'tiles': n,
     'warnings': [...]}. Raises AnimError."""
    steps = entry.get('steps') or []
    name = entry.get('name') or entry.get('id') or '?'
    if not isinstance(steps, list) or not any('from' in s for s in steps if isinstance(s, dict)):
        raise AnimError(f'animation {name!r}: needs at least one frame step')
    sources, frames, fidx, tiles, tidx, warnings = [], [], {}, [], {}, []
    timeline = []
    blank = None
    for k, s in enumerate(steps):
        if not isinstance(s, dict):
            raise AnimError(f'animation {name!r} step {k + 1}: not an object')
        if 'sound' in s:
            v = _int(s['sound'], f'animation {name!r} step {k + 1} sound')
            if not 0 <= v <= 0xFE:
                raise AnimError(f'animation {name!r} step {k + 1}: sound {v} outside 0-254')
            timeline.append((0xFD, v))
            continue
        hold = _int(s.get('hold', 0), f'animation {name!r} step {k + 1} hold')
        if not 0 <= hold <= 255:
            raise AnimError(f'animation {name!r} step {k + 1}: hold {hold} outside 0-255')
        if s.get('blank'):
            if blank is None:
                blank = len(frames)
                frames.append([])
            timeline.append((blank, hold))
            continue
        if 'from' not in s:
            raise AnimError(f'animation {name!r} step {k + 1}: needs from + frame, blank or sound')
        c = _int(s['from'], f'animation {name!r} step {k + 1} from')
        f = _int(s.get('frame', 0), f'animation {name!r} step {k + 1} frame')
        if not 0 <= c < N_STOCK:
            raise AnimError(f'animation {name!r} step {k + 1}: animation {c} is not one of the 45 ($00-$2C)')
        if not 0 <= f < FRAMES_PER_ANIM:
            raise AnimError(f'animation {name!r} step {k + 1}: frame {f} outside 0-31')
        if c not in sources:
            if len(sources) == MAX_SOURCES:
                raise AnimError(f'animation {name!r}: frames from more than {MAX_SOURCES} animations '
                                '(one colour set each, four OBJ palettes)')
            sources.append(c)
        slot = sources.index(c)
        if (c, f) not in fidx:
            sp = []
            for dy, dx, t, at in stock(c, repo_root)['frames'][f]:
                if str(t) not in stock(c, repo_root)['tiles']:
                    warnings.append(f'animation {name!r}: ${c:02X} frame {f} draws tile {t}, '
                                    'outside its sheet — drawn empty')
                if (c, t) not in tidx:
                    tidx[(c, t)] = len(tiles)
                    tiles.append(tile_bytes(c, t, repo_root))
                sp.append((dy, dx, tidx[(c, t)], (at & 0xF8) | slot))
            fidx[(c, f)] = len(frames)
            frames.append(sp)
        timeline.append((fidx[(c, f)], hold))
    if len(tiles) > MAX_TILES:
        raise AnimError(f'animation {name!r}: its frames draw {len(tiles)} different tiles, '
                        f'at most {MAX_TILES} fit (the $8000 block) — use fewer source frames')
    if len(frames) > MAX_FRAMES:
        raise AnimError(f'animation {name!r}: {len(frames)} different frames, at most {MAX_FRAMES}')
    if len(timeline) > MAX_STEPS:
        raise AnimError(f'animation {name!r}: {len(timeline)} steps, at most {MAX_STEPS}')
    pals = [display_palette(c, repo_root) for c in sources]
    return {'frames': frames, 'blank': blank, 'timeline': timeline, 'palettes': pals,
            'sheet': b''.join(tiles), 'sources': sources, 'tiles': len(tiles),
            'warnings': warnings}


def duration(entry_or_stock, repo_root=None):
    """Frames an animation lasts (hold + 1 per frame step)."""
    if isinstance(entry_or_stock, int):
        return sum(s['hold'] + 1 for s in stock(entry_or_stock, repo_root)['timeline'] if 'frame' in s)
    return sum(_int(s.get('hold', 0), 'hold') + 1 for s in entry_or_stock.get('steps', [])
               if isinstance(s, dict) and 'sound' not in s)


# ---------------------------------------------------------------------------
# a skill's presentation (gamedata.skills.<id>.presentation)
# ---------------------------------------------------------------------------
#   {"kind": "animation", "animation": 16 | "spark_bolt", "motion": 0-3}
#   {"kind": "effect", "effect": 4-12 | 14 | 15}
#   {"kind": "none"}
# -> SkillRoutineOverride / SkillAnimOverride rows (bank $5F). Applied only on
# the sides where the skill's look shows something (vanilla side behaviour).

PRESENT_KINDS = ('animation', 'effect', 'none')
N_SKILL_IDS = 0xFF               # ids 0-$FE (stock 0-221, custom 222-254)


def presentation_bytes(prj_or_data, pres, what='presentation'):
    """-> (routine, number) (each $FF = keep the look's)."""
    if pres is None:
        return 0xFF, 0xFF
    if not isinstance(pres, dict) or pres.get('kind') not in PRESENT_KINDS:
        raise AnimError(f'{what}: kind must be one of {", ".join(PRESENT_KINDS)}')
    k = pres['kind']
    if k == 'none':
        return NOTHING, 0xFF
    if k == 'effect':
        e = _int(pres.get('effect'), f'{what} effect')
        if e not in EFFECTS:
            raise AnimError(f'{what}: screen effect {e} is not one of {EFFECTS}')
        return e, 0xFF
    n = number_of(prj_or_data, pres.get('animation'))
    if n is None:
        raise AnimError(f'{what}: animation {pres.get("animation")!r} is neither a stock number '
                        '0-44 nor a custom.animations id')
    m = _int(pres.get('motion', 0), f'{what} motion')
    if m not in MOTIONS:
        raise AnimError(f'{what}: motion {m} is not one of 0-3')
    return m, n


def override_tables(prj_or_data):
    """-> (routine table 256 B, number table 256 B) from gamedata.skills."""
    d = prj_or_data if isinstance(prj_or_data, dict) else prj_or_data.data
    sk = ((d.get('gamedata') or {}).get('skills')) or {}
    rt, ct = bytearray([0xFF] * 256), bytearray([0xFF] * 256)
    for sid, row in sk.items():
        if not isinstance(row, dict) or 'presentation' not in row:
            continue
        i = _int(sid, 'skill id')
        if not 0 <= i < N_SKILL_IDS:
            raise AnimError(f'skill {sid}: presentation only for ids 0-254')
        rt[i], ct[i] = presentation_bytes(d, row['presentation'], f'skill {sid} presentation')
    return bytes(rt), bytes(ct)


def check(prj):
    """Validate custom.animations + every skill presentation. -> warnings;
    raises AnimError."""
    lst = custom_list(prj)
    if len(lst) > MAX_CUSTOM:
        raise AnimError(f'custom.animations: {len(lst)} animations, at most {MAX_CUSTOM}')
    ids, warnings = set(), []
    for a in lst:
        if not isinstance(a, dict) or not a.get('id'):
            raise AnimError('custom.animations: every animation needs an id')
        if a['id'] in ids:
            raise AnimError(f'custom.animations: id {a["id"]!r} used twice')
        ids.add(a['id'])
        warnings += compose(a)['warnings']
    override_tables(prj)
    return warnings


# ---------------------------------------------------------------------------
# emitters (bank $6F file, bank $70 file, the two bank $5F regions)
# ---------------------------------------------------------------------------

def _db(bs, comment=None):
    s = '    db ' + ', '.join(f'${b:02X}' for b in bs)
    return s + (f'   ; {comment}' if comment else '')


def emit_bank_06f(prj, warnings, template_text):
    lst = custom_list(prj)
    comp = [compose(a) for a in lst]
    n = len(lst)
    out = ['; generated by build_project.py (custom.animations, PROJECT_COMPILER §2.28)',
           f'CUSTOM_ANIM_COUNT EQU {n}', '', template_text.rstrip('\n'), '',
           '; ' + '-' * 77,
           '; NEW ANIMATION DATA (generated; row k = animation $2D + k, the last row',
           '; = CustomAnimNone)',
           '; ' + '-' * 77]

    def table(label, rows, none):
        out.append(f'{label}:')
        for r in rows:
            out.append(f'    dw {r}')
        out.append(f'    dw {none}')
    table('CustomAnimFrameTable', [f'CustomAnim{k}_Frames' for k in range(n)], 'CustomAnimNoneFrames')
    table('CustomAnimTimelines', [f'CustomAnim{k}_Timeline' for k in range(n)], 'CustomAnimNoneTimeline')
    table('CustomAnimPalettes', [f'CustomAnim{k}_Palettes' for k in range(n)], 'CustomAnimNonePalette')
    out.append('CustomAnimGfxIds:')
    for k in range(n):
        out.append(f'    dw ${SHEET_BANK:02X}{k:02X}   ; bank $70 stream {k}')
    out.append(f'    dw ${SHEET_BANK:02X}{n:02X}   ; (CustomAnimNone: an empty sheet)')
    for k, (a, c) in enumerate(zip(lst, comp)):
        num = FIRST_CUSTOM + k
        out.append('')
        out.append(f'; ${num:02X} {a.get("name") or a["id"]} ({a["id"]}) — from '
                   + ', '.join(f'${s:02X} {stock_name(s)}' for s in c['sources'])
                   + f'; {len(c["frames"])} frames, {c["tiles"]} tiles, {duration(a)} frames long')
        out.append(f'CustomAnim{k}_Frames:')
        for i in range(len(c['frames'])):
            out.append(f'    dw CustomAnim{k}_F{i}')
        for i, fr in enumerate(c['frames']):
            out.append(f'CustomAnim{k}_F{i}:' + ('   ; blank' if i == c['blank'] else ''))
            for sp in fr:
                out.append(_db(sp))
            out.append('    db $80')
        out.append(f'CustomAnim{k}_Timeline:')
        for x, y in c['timeline']:
            what = f'sound ${y:02X}' if x == 0xFD else (f'blank for {y + 1} frames' if x == c['blank']
                                                        else f'frame {x} for {y + 1} frames')
            out.append(_db((x, y), what))
        out.append(_db((0xFF, 0xFF), 'end'))
        out.append(f'CustomAnim{k}_Palettes:')
        out.append(f'    db {len(c["palettes"])}')
        for s, p in zip(c['sources'], c['palettes']):
            out.append('    dw ' + ', '.join(f'${w:04X}' for w in p) + f'   ; slot of ${s:02X}')
    return '\n'.join(out) + '\n'


def emit_bank_070(prj, warnings):
    from dwm.sprite_codec import encode_safe
    lst = custom_list(prj)
    comp = [compose(a) for a in lst]
    out = ['; =============================================================================',
           '; BANK $70 — the tile sheets of the project\'s NEW battle animations (S112;',
           '; compiler-generated from custom.animations, PROJECT_COMPILER §2.28): one LZ',
           '; stream per animation (the tiles its frames draw, gathered from the stock',
           '; sheets), gfx id $70xx, decoded to $8000 by bank $50 AnimLoadFork50 /',
           '; the Effect debugger. The last stream = CustomAnimNone\'s (one empty tile).',
           '; =============================================================================',
           'SECTION "ROM Bank $070", ROMX[$4000], BANK[$70]',
           '    db $70',
           'CustomAnimSheetPtrs:']
    for k in range(len(lst) + 1):
        out.append(f'    dw CustomAnimSheet{k}')
    for k, c in enumerate(comp + [{'sheet': bytes(16)}]):
        stream = encode_safe(c['sheet'] or bytes(16))
        out.append(f'CustomAnimSheet{k}:   ; {len(c["sheet"]) // 16} tiles, {len(stream)} B')
        for i in range(0, len(stream), 16):
            out.append(_db(stream[i:i + 16]))
    return '\n'.join(out) + '\n'


def _table_region(bs, head):
    out = [head]
    for i in range(0, 256, 16):
        out.append(_db(bs[i:i + 16], f'[{i:3d}-{i + 15:3d}]'))
    return '\n'.join(out) + '\n'


def emit_routine_region(prj, warnings):
    rt, _ct = override_tables(prj)
    return _table_region(rt, '; SkillRoutineOverride rows (gamedata.skills.<id>.presentation; $FF = the look\'s)')


def emit_cmd_region(prj, warnings):
    _rt, ct = override_tables(prj)
    return _table_region(ct, '; SkillAnimOverride rows (gamedata.skills.<id>.presentation; $FF = the look\'s)')


# ---------------------------------------------------------------------------
# preview (pure data — the Qt tab paints the rows): what the screen shows
# ---------------------------------------------------------------------------
SCREEN_W, SCREEN_H = 160, 144
ORIGIN_X, ORIGIN_Y = 0x50, 0x60          # the debugger / "middle of the foes"


def _rgb(w):
    r, g, b = w & 31, (w >> 5) & 31, (w >> 10) & 31
    return (r * 255 // 31, g * 255 // 31, b * 255 // 31)


def _tile_px(t16):
    out = []
    for r in range(8):
        lo, hi = t16[2 * r], t16[2 * r + 1]
        out.append([((lo >> (7 - c)) & 1) | (((hi >> (7 - c)) & 1) << 1) for c in range(8)])
    return out


def draw_frame(sprites, tile_fn, palettes, ox=ORIGIN_X, oy=ORIGIN_Y, w=SCREEN_W, h=SCREEN_H):
    """-> {(x, y): (r, g, b)} for one frame: sprites (dy, dx, tile, attr) at the
    renderer's position, 8x8, flips from attr bits 5 / 6, palette attr & 7,
    colour 0 transparent, the FIRST sprite on top (CGB OAM priority — KEY_LESSONS
    S107 2b), at most 40 sprites (the builder's cut)."""
    px = {}
    for dy, dx, t, at in reversed(list(sprites)[:MAX_SPRITES]):
        sdy, sdx = (dy - 256 if dy > 127 else dy), (dx - 256 if dx > 127 else dx)
        x0, y0 = ox + sdx, oy + sdy
        pal = palettes[at & 7] if (at & 7) < len(palettes) else palettes[0]
        cols = [_rgb(c) for c in pal]
        rows = _tile_px(tile_fn(t))
        for r in range(8):
            for c in range(8):
                v = rows[7 - r if at & 0x40 else r][7 - c if at & 0x20 else c]
                if v and 0 <= x0 + c < w and 0 <= y0 + r < h:
                    px[(x0 + c, y0 + r)] = cols[v]
    return px


def stock_view(c, repo_root=None):
    """(frames, tile_fn, palettes, timeline pairs) of stock animation C as shown."""
    a = stock(c, repo_root)
    pairs = []
    for s in a['timeline']:
        if 'frame' in s:
            pairs.append((s['frame'], s['hold']))
        elif 'sound' in s:
            pairs.append((0xFD, s['sound']))
    return (a['frames'], lambda t, c=c: tile_bytes(c, t, repo_root),
            [display_palette(c, repo_root)], pairs)


def custom_view(entry, repo_root=None):
    comp = compose(entry, repo_root)
    sheet = comp['sheet']
    return (comp['frames'], lambda t: sheet[16 * t:16 * t + 16] if 16 * t + 16 <= len(sheet) else bytes(16),
            comp['palettes'], comp['timeline'])


def schedule(pairs):
    """Timeline pairs -> [(frame index, [sounds cued as it starts])], one per
    screen frame (frame f held h + 1 frames; sounds take no time) — the
    sequencer's rule, measured S112."""
    out, pending = [], []
    for a, b in pairs:
        if a == 0xFD:
            pending.append(b)
            continue
        if a >= 0xF8:
            continue                     # control ops (the projectile loop) — previewed once
        for k in range(b + 1):
            out.append((a, pending if k == 0 else []))
        pending = []
    return out


def sound_file(sid, repo_root=None):
    p = os.path.join(repo_root or REPO, 'extracted', 'anim_sounds', f'sfx_{sid:02x}.wav')
    return p if os.path.exists(p) else None
