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


# ---------------------------------------------------------------------------
# Interact block entries — ROOM_DATA_FORMAT.md "Interact Block":
# 5-byte entries, $FF terminated; terminator is the FIRST byte of an entry
# only (KEY_LESSONS v3-v4: internal bytes may legitimately be $FF).
# ---------------------------------------------------------------------------

def npc_spawn_entry(x, y, script=0x00):
    """Spawn point entry: type $8F, param $FF. ROOM_DATA_FORMAT.md.
    Byte 4 (script) MUST be 0 (KEY_LESSONS 'Spawn point NPC entry can be
    talked to' — the interaction scan includes spawn entries; script 0 =
    room entry no-op). Enforced by validators (spawn_script_zero)."""
    return [0x8F, 0xFF, x, y, script]


def npc_entry(facing, sprite, x, y, script_id):
    """NPC entry: byte0 type/facing, byte1 sprite, byte2/3 X/Y grid,
    byte4 script_id ($FF = no script). ROOM_DATA_FORMAT.md."""
    t = FACING[facing] if isinstance(facing, str) else facing
    return [t, sprite, x, y, script_id]


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
