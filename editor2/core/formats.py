"""formats.py — ROM byte-format encoders. THE single home for each format.

Every encoder cites the doc that owns its format. If an understanding is
corrected, fix it HERE (one function) and rebuild; content in project.json
never encodes bytes directly. (Design commitment S53: "semantic schema,
formats defined once with doc citations".)
"""

# ---------------------------------------------------------------------------
# Small value helpers
# ---------------------------------------------------------------------------

def val(x):
    """Parse '0x6B' / '$6B' / 107 / 'SYMBOL' → int or symbol string."""
    if isinstance(x, int):
        return x
    if isinstance(x, str):
        s = x.strip()
        if s.startswith('$'):
            return int(s[1:], 16)
        if s.lower().startswith('0x'):
            return int(s, 16)
        if s.lstrip('-').isdigit():
            return int(s)
        return s  # symbol pass-through (resolved by rgbasm)
    raise ValueError(f"unparseable value: {x!r}")


def hexb(n):
    return f"${n:02X}"


def hexw(n):
    return f"${n:04X}"


FACING = {  # ROOM_DATA_FORMAT.md "NPC entries": bits 4-5 of type byte
    'down': 0x00, 'left': 0x10, 'up': 0x20, 'right': 0x30,
    'down_static': 0x40, 'up_static': 0x60,
}
FACING_NAMES = ['down', 'left', 'up', 'right']      # slot +$06 value order

# S97: the NPC type byte's low nibble picks the per-frame behaviour routine
# (bank $06 NPCBehaviourTable — ROOM_DATA_FORMAT "NPC behaviour types",
# PyBoy-measured). Bit 6 = HIDDEN (inactive entry): not drawn, not solid,
# no behaviour, cannot be talked to (bank $06 NPCBehaviourTable caller, entry 0
# collision + entry 1 draw loops all skip it). Names are the schema vocabulary.
BEHAVIOURS = {
    'stand': 0x0, 'spin': 0x1, 'pace_x2': 0x2, 'square': 0x3, 'figure8': 0x4,
    'pace_right3': 0x5, 'stand_fixed': 0x6, 'stand_return': 0x7,
    'pace_x1': 0x8, 'pace_x2_left': 0x9, 'sway': 0xA,
    'gate_wander_meet': 0xE, 'gate_wander': 0xF,
}
BEHAVIOUR_NAMES = {v: k for k, v in BEHAVIOURS.items()}
GATE_ONLY_BEHAVIOURS = {0xE, 0xF}      # act only on the gate wanderer screen ($C926)
# tile offsets from the NPC's home that each patterned walker visits
# (measured PyBoy S97, Bazaar slot 0); the walkers never test tiles.
BEHAVIOUR_PATHS = {
    0x2: [(dx, 0) for dx in (1, 2, 1, 0, -1, -2, -1, 0)],
    0x3: [(0, 1), (0, 2), (1, 2), (2, 2), (2, 1), (2, 0), (1, 0), (0, 0)],
    0x4: [(-1, 0), (-2, 0), (-3, 0), (-3, -1), (-3, -2), (-3, -3), (-4, -3),
          (-5, -3), (-6, -3), (-6, -2), (-6, -1), (-6, 0), (-5, 0), (-4, 0),
          (-3, 0), (-3, -1), (-3, -2), (-3, -3), (-2, -3), (-1, -3), (0, -3),
          (0, -2), (0, -1), (0, 0)],
    0x5: [(1, 0), (2, 0), (3, 0), (2, 0), (1, 0), (0, 0)],
    0x8: [(1, 0), (0, 0), (-1, 0), (0, 0)],
    0x9: [(-1, 0), (-2, 0), (-1, 0), (0, 0), (1, 0), (2, 0), (1, 0), (0, 0)],
    0xA: [(1, 0), (0, 0), (-1, 0), (0, 0)],
}


def behaviour_value(b):
    """'pace_x2' / 2 / '0x2' -> 0-15."""
    if isinstance(b, str) and b in BEHAVIOURS:
        return BEHAVIOURS[b]
    v = val(b)
    if not isinstance(v, int) or not 0 <= v <= 15:
        raise ValueError(f"unknown NPC behaviour {b!r}")
    return v


def npc_type_byte(facing='down', behaviour=0, hidden=False):
    """Type byte = facing (bits 4-5) | hidden (bit 6) | behaviour (bits 0-3)."""
    t = FACING[facing] if isinstance(facing, str) else val(facing)
    return (t | (0x40 if hidden else 0) | behaviour_value(behaviour)) & 0x7F


def npc_path(behaviour):
    """Tiles (dx, dy) a behaviour walks through, home included."""
    return [(0, 0)] + BEHAVIOUR_PATHS.get(behaviour_value(behaviour), [])


# ---------------------------------------------------------------------------
# Interact block entries — ROOM_DATA_FORMAT.md "Interact Block":
# 5-byte entries, $FF terminated; terminator is the FIRST byte of an entry
# only (KEY_LESSONS v3-v4: internal bytes may legitimately be $FF).
# ---------------------------------------------------------------------------

def npc_spawn_entry(x, y, script=0x00):
    """LEGACY name (S1-era schema kind 'spawn'): the bytes are an $8F EXAMINE
    SPOT (S98, PyBoy-measured — ROOM_DATA_FORMAT "Interact entries ≥ $80"):
    pressing A while standing on or facing the cell runs script `script`.
    Nothing in the engine reads it as a spawn (arrival = the source exit's
    bytes 4-6, KEY_LESSONS S4). Kept byte-identical for old projects; the
    editor no longer creates it (validators warn: script 0 = the room's entry
    script runs on an A press there)."""
    return [0x8F, 0xFF, x, y, script]


# S98 (PyBoy-measured; bank $0B RoomEntry4_TalkTargetLookup /
# RoomEntry5_StepTriggerLookup, ROOM_DATA_FORMAT "Interact entries ≥ $80"):
#   $80-$83 / $8F  EXAMINE SPOT — answers an A press from the player's own cell
#                  or the faced cell; low nibble = the facing the player must
#                  have ($FF8E: 0 down 1 left 2 up 3 right) or $F = any.
#   $90            STEP-ON TRIGGER — runs its script when the player WALKS
#                  onto the cell (not on arrival through a door/warp).
# Byte 1 is $FF in every vanilla entry; byte 4 = the room's script index.
EXAMINE_FACING = {'any': 0xF, 'down': 0x0, 'left': 0x1, 'up': 0x2, 'right': 0x3}
EXAMINE_FACING_NAMES = {v: k for k, v in EXAMINE_FACING.items()}


def examine_entry(x, y, script_id, facing='any'):
    """Examine spot: [$80 | facing nibble, $FF, x, y, script]."""
    nib = EXAMINE_FACING[facing] if isinstance(facing, str) else int(facing) & 0x0F
    return [0x80 | nib, 0xFF, x, y, script_id]


def step_trigger_entry(x, y, script_id):
    """Step-on trigger: [$90, $FF, x, y, script]."""
    return [0x90, 0xFF, x, y, script_id]


def npc_entry(facing, sprite, x, y, script_id, behaviour=0, hidden=False):
    """NPC entry: byte0 type (facing bits 4-5 | hidden bit 6 | behaviour
    bits 0-3, S97), byte1 sprite, byte2/3 X/Y grid, byte4 script_id ($FF = no
    script). ROOM_DATA_FORMAT.md. Defaults reproduce the pre-S97 bytes."""
    return [npc_type_byte(facing, behaviour, hidden), sprite, x, y, script_id]


# ---------------------------------------------------------------------------
# Exit checker block — ROOM_DATA_FORMAT.md "Exit Checker Block":
# 7-byte entries, $FF terminated.
#   [trig_x, trig_y, dest_mt, gate_flag, screen_byte, spawn_x, spawn_y]
# screen_byte indexes the $2DE7 spawn-offset table; NEVER guessed
# (KEY_LESSONS v14-v18 + S40: a stale $01 stranded the player off-map).
# ---------------------------------------------------------------------------

def exit_entry(x, y, dest_mt, gate_flag, screen_byte, spawn_x, spawn_y):
    return [x, y, dest_mt, gate_flag, screen_byte, spawn_x, spawn_y]


# ---------------------------------------------------------------------------
# Step entry — ROOM_DATA_FORMAT.md "Step Entry (6 bytes)":
#   [step_id, tileset_bank, interact_ptr:2, exit_ptr:2]
# In bank $60 screens these are emitted as: db step_id, bank / dw npcs / dw exits
# preceded by the screen's `dw <ram step counter>` (CROSSBANK_ROOMS "Step 3").
# ---------------------------------------------------------------------------

# (emitted structurally by the emitter; no packing needed here)


# ---------------------------------------------------------------------------
# Custom26DDTable record — PROJECT_STATE "Bank allocation" + patches/bank_071.asm:
# 8 bytes [step_id, gfx_bank, width_lo, width_hi, height_lo, height_hi,
#          threshold, pad]. width/height in PIXELS, LE
# (ROOM_DATA_FORMAT "Tileset Graphics System": 160px per column, 128px per row;
#  KEY_LESSONS S10: dimensions gate multi-screen movement).
# ---------------------------------------------------------------------------

def record_26dd(gfx_id, gfx_bank, width_px, height_px, threshold, pad=0x00):
    return [gfx_id, gfx_bank,
            width_px & 0xFF, (width_px >> 8) & 0xFF,
            height_px & 0xFF, (height_px >> 8) & 0xFF,
            threshold, pad]


# ---------------------------------------------------------------------------
# RoomEncTable row — CROSSBANK_ROOMS "Editor build spec #1" as built S42
# (patches/bank_071.asm): 3 bytes [enabled, gate_id, floor], indexed mapID-$6B.
# ---------------------------------------------------------------------------

def enc_row(enabled, gate_id=0, floor=0):
    return [1 if enabled else 0, gate_id, floor]


# ---------------------------------------------------------------------------
# BG palette block — GATE_GENERATION §7.1 / KEY_LESSONS S39:
# 8 sub-palettes × 4 colours × RGB555 LE. Engine FORCES idx1=$6BFF, idx3=$0000
# at runtime; validators warn when data disagrees (it will merely be
# overwritten, but authoring against the forced values avoids surprises).
# Custom rooms may only LOAD slots 0-3 (KEY_LESSONS S8) — enforced by the
# engine code (CustomPalCheck b=$04), not by data; slots 4-7 here are the
# room's authored mirror set and are ignored by the loader.
# ---------------------------------------------------------------------------

def palette_row(row):
    """One sub-palette (4 RGB555 ints/strings) → 8 bytes LE."""
    assert len(row) == 4, "each sub-palette needs exactly 4 colours"
    out = []
    for c in row:
        c = val(c)
        out += [c & 0xFF, (c >> 8) & 0xFF]
    return out


def palette_block(colors):
    """colors = 8 rows of 4 RGB555 → 64 bytes LE (full block)."""
    assert len(colors) == 8, "palette needs exactly 8 sub-palettes"
    out = []
    for row in colors:
        out += palette_row(row)
    return out


def db_line(bytes_, comment=None, per_line=None):
    """Render a db line (or several) from a byte/symbol list."""
    def fmt(b):
        return hexb(b) if isinstance(b, int) else str(b)
    if per_line:
        lines = []
        for i in range(0, len(bytes_), per_line):
            chunk = ", ".join(fmt(b) for b in bytes_[i:i + per_line])
            lines.append(f"    db {chunk}")
        if comment:
            lines[0] += f"  ; {comment}"
        return "\n".join(lines)
    chunk = ", ".join(fmt(b) for b in bytes_)
    s = f"    db {chunk}"
    if comment:
        s += f"  ; {comment}"
    return s
