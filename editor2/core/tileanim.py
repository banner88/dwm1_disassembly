"""tileanim.py — a custom room's OWN animated tiles (S102).

User (S102): "I just want animated tiles and for the UI to tell me wtf is
happening … I want to mostly make them myself"; "from-scratch animations with
clearly explained budget. Also if I can set speed that would be great."

project.json `custom.rooms[].tile_anims[]` (PROJECT_COMPILER §2.19):

    {"id": "cloud", "name": "Cloud",
     "motion": "flip" | "drift_right" | "drift_left" | "sway",
     "speed": 32,                     # game frames per step (1-255)
     "rows": [[112, 111, 76, 78]],    # sheet slots, row-major (left -> right)
     "frames": [[hex32, ...], ...],   # flip: frames 1..N-1, one 16-byte tile
                                      #   (32 hex chars) per slot, rows order;
                                      #   frame 0 = the sheet's own art
     "order": "loop" | "pingpong",    # flip only (default loop)
     "strip": true,                   # drift/sway: pixels flow across a row's
                                      #   tiles (false: each tile wraps alone)
     "amplitude": 1}                  # sway: pixels each way (1-3)

Engine: bank $6C CustomTileAnimate (templates/bank_06c_head.asm). Every step
copies a WHOLE frame into the slot (from ROM), so the slot index — and the
tile's walkability — never changes, and a sheet reload heals at the next step.
Budget (plain numbers the editor shows):
  * tileset space: an animated tile uses the slot it already has; frames live
    in bank $6C (FRAME_BYTES_MAX), not on the tileset;
  * load: the game copies at most CAP tiles per frame; `load()` = tiles per
    frame the room asks for on average (sum of slots / speed) against CAP.
Pure data + bytes; no Qt.
"""
from math import gcd

CAP = 8                  # TILEANIM_CAP (bank $6C): tiles copied per field frame
MAX_GROUPS = 32          # TILEANIM_MAX_GROUPS (patches/wram.asm)
MAX_FRAMES = 8           # flip: frames per animation (incl. the sheet's own)
MAX_STRIP = 4            # drift/sway strip: tiles per row
MAX_SLOTS = 32           # tiles per animation
SPEED_MIN, SPEED_MAX = 1, 255
BANK_BYTES = 0x4000
FPS = 59.73

MOTIONS = ('flip', 'drift_right', 'drift_left', 'sway')
MOTION_LABEL = {
    'flip': 'Flip through frames',
    'drift_right': 'Drift right',
    'drift_left': 'Drift left',
    'sway': 'Sway (back and forth)',
}

SPEED_PRESETS = [(4, 'very fast'), (8, 'fast'), (16, 'quick'), (32, 'normal (like the game)'),
                 (64, 'slow'), (128, 'very slow')]


def speed_words(speed):
    """'every 32 frames (≈ 1.9 per second)'."""
    per_s = FPS / max(1, speed)
    rate = f'{per_s:.1f}' if per_s < 10 else f'{per_s:.0f}'
    return f'every {speed} frame{"s" if speed != 1 else ""} (≈ {rate} per second)'


def _val(v):
    if isinstance(v, int):
        return v
    s = str(v).strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


def slots_of(item):
    return [_val(s) for row in item.get('rows') or [] for s in row]


# ------------------------------------------------------------- pixel helpers
def _rows_bits(tiles):
    """tiles (list of 16-byte 2bpp) side by side -> per pixel row y, the two
    bitplanes as wide ints (leftmost pixel = MSB)."""
    w = len(tiles)
    out = []
    for y in range(8):
        lo = hi = 0
        for t in tiles:
            lo = (lo << 8) | t[y * 2]
            hi = (hi << 8) | t[y * 2 + 1]
        out.append((lo, hi))
    return out, w * 8


def _bits_rows(rows, n_tiles):
    tiles = [bytearray(16) for _ in range(n_tiles)]
    for y, (lo, hi) in enumerate(rows):
        for k in range(n_tiles):
            sh = (n_tiles - 1 - k) * 8
            tiles[k][y * 2] = (lo >> sh) & 0xFF
            tiles[k][y * 2 + 1] = (hi >> sh) & 0xFF
    return [bytes(t) for t in tiles]


def roll(tiles, dx):
    """Roll a row of tiles by dx pixels (positive = right), wrapping inside
    the row's width."""
    rows, width = _rows_bits(tiles)
    dx %= width
    if dx == 0:
        return [bytes(t) for t in tiles]
    mask = (1 << width) - 1
    out = []
    for lo, hi in rows:
        out.append((((lo >> dx) | (lo << (width - dx))) & mask,
                    ((hi >> dx) | (hi << (width - dx))) & mask))
    return _bits_rows(out, len(tiles))


# ------------------------------------------------------------- frames
def _hex16(h):
    b = bytes.fromhex(h)
    if len(b) != 16:
        raise ValueError('a tile frame must be 16 bytes (32 hex characters)')
    return b


def offsets(item):
    """drift/sway: the pixel offset of each step."""
    m = item['motion']
    rows = item.get('rows') or [[]]
    strip = item.get('strip', True)
    width = (len(rows[0]) if strip else 1) * 8
    if m == 'drift_right':
        return list(range(width))
    if m == 'drift_left':
        return [(-k) % width for k in range(width)]
    if m == 'sway':
        a = max(1, min(3, _val(item.get('amplitude', 1))))
        return list(range(0, a + 1)) + list(range(a - 1, -a - 1, -1)) + list(range(-a + 1, 0))
    raise ValueError(m)


def steps(item, sheet):
    """The animation as the game plays it: (frames, seq) where frames[i] =
    list of 16-byte tiles (one per slot, slots_of order) and seq = frame
    index per step (step 0 = frame 0 = the sheet's own art)."""
    sl = slots_of(item)
    base = [bytes(sheet[s * 16:s * 16 + 16]) for s in sl]
    m = item['motion']
    if m == 'flip':
        frames = [base] + [[_hex16(h) for h in f] for f in item.get('frames') or []]
        n = len(frames)
        if item.get('order') == 'pingpong' and n > 2:
            seq = list(range(n)) + list(range(n - 2, 0, -1))
        else:
            seq = list(range(n))
        return frames, seq
    rows = item.get('rows') or []
    strip = item.get('strip', True)
    offs = offsets(item)
    uniq = sorted(set(offs), key=offs.index)
    frames = []
    for dx in uniq:
        f = []
        i = 0
        for row in rows:
            tiles = base[i:i + len(row)]
            i += len(row)
            if strip:
                f += roll(tiles, dx)
            else:
                f += [roll([t], dx)[0] for t in tiles]
        frames.append(f)
    return frames, [uniq.index(dx) for dx in offs]


def groups(item, sheet):
    """Engine groups of one animation (<= CAP slots each; same timing):
    [(slot list, frame blocks, seq)] — frame block = bytes (nslots x 16)."""
    frames, seq = steps(item, sheet)
    sl = slots_of(item)
    out = []
    for a in range(0, len(sl), CAP):
        part = sl[a:a + CAP]
        blocks = [b''.join(f[a:a + CAP]) for f in frames]
        out.append((part, blocks, seq))
    return out


def rom_bytes(item, sheet=None):
    """Bank-$6C bytes the animation costs (records + sequences + frames)."""
    n = len(slots_of(item))
    if item['motion'] == 'flip':
        nf = 1 + len(item.get('frames') or [])
        seqlen = nf if item.get('order') != 'pingpong' or nf <= 2 else 2 * nf - 2
    else:
        offs = offsets(item)
        nf, seqlen = len(set(offs)), len(offs)
    ng = -(-n // CAP)
    return ng * 6 + 2 * n + ng * 2 * seqlen + nf * n * 16


# ------------------------------------------------------------- schedule
def _lcm(a, b):
    return a * b // gcd(a, b)


HORIZON = 4096


def schedule(items):
    """Stagger the room's animations so few steps land on one frame.
    Returns {item index: phase (1..speed)} — greedy, deterministic: biggest
    first, each takes the phase that keeps the busiest frame lowest."""
    order = sorted(range(len(items)),
                   key=lambda i: (-len(slots_of(items[i])), _val(items[i]['speed']),
                                  str(items[i].get('id'))))
    h = 1
    for it in items:
        h = min(HORIZON, _lcm(h, _val(it['speed'])))
    load = [0] * h
    out = {}
    for i in order:
        p = _val(items[i]['speed'])
        n = len(slots_of(items[i]))
        best = None
        for ph in range(1, p + 1):
            peak = max(load[t] for t in range(ph % h, h, p)) + n if h else n
            if best is None or peak < best[0]:
                best = (peak, ph)
            if peak <= n:
                break
        ph = best[1]
        for t in range(ph % h, h, p):
            load[t] += n
        out[i] = ph
    return out


def load(items):
    """{'per_frame': average tiles per frame, 'pct': of CAP, 'peak': busiest
    frame after staggering, 'changes_s': tile changes per second}."""
    avg = sum(len(slots_of(it)) / _val(it['speed']) for it in items)
    peak = 0
    if items:
        ph = schedule(items)
        h = 1
        for it in items:
            h = min(HORIZON, _lcm(h, _val(it['speed'])))
        arr = [0] * h
        for i, it in enumerate(items):
            p = _val(it['speed'])
            for t in range(ph[i] % h, h, p):
                arr[t] += len(slots_of(it))
        peak = max(arr)
    return {'per_frame': avg, 'pct': 100.0 * avg / CAP, 'peak': peak,
            'changes_s': avg * FPS}


def load_words(items):
    """One plain line for the UI."""
    if not items:
        return 'nothing animated in this room'
    L = load(items)
    pct = L['pct']
    if pct <= 60:
        tag = 'fine'
    elif pct <= 100:
        tag = 'busy but fine — the game spreads the changes out'
    else:
        tag = 'TOO MUCH — animations will run slower than set'
    return f"{pct:.0f}% of what the game can change per frame ({tag})"


# ------------------------------------------------------------- checks
def problems(room, items, sheet, vanilla_slots=()):
    """Plain-language errors for the compiler and the editor."""
    errs = []
    seen = {}
    ids = set()
    if len(items) and 'tileset' not in (room.get('record') or {}):
        errs.append('animated tiles need the room to have its own tileset copy')
    ngroups = 0
    for it in items:
        name = it.get('name') or it.get('id') or 'animation'
        if it.get('id') in ids:
            errs.append(f'{name}: two animations share the id {it.get("id")!r}')
        ids.add(it.get('id'))
        if it.get('motion') not in MOTIONS:
            errs.append(f'{name}: unknown motion {it.get("motion")!r}')
            continue
        try:
            sp = _val(it.get('speed'))
        except Exception:
            sp = -1
        if not SPEED_MIN <= sp <= SPEED_MAX:
            errs.append(f'{name}: speed must be 1-255 frames per step')
        sl = slots_of(it)
        if not sl:
            errs.append(f'{name}: no tiles')
            continue
        if len(sl) > MAX_SLOTS:
            errs.append(f'{name}: {len(sl)} tiles — one animation can have at most {MAX_SLOTS}')
        ngroups += -(-len(sl) // CAP)
        for s in sl:
            if not 0 <= s < 128:
                errs.append(f'{name}: tile slot {s} outside 0-127')
            elif s in seen and seen[s] is not it:
                errs.append(f'{name}: tile slot {s} is already animated by '
                            f'{seen[s].get("name") or seen[s].get("id")}')
            elif s in seen:
                errs.append(f'{name}: tile slot {s} appears twice')
            seen[s] = it
            if s in vanilla_slots:
                errs.append(f'{name}: tile slot {s} is also moved by the vanilla animation '
                            'copied into this room — two animations would fight over it')
        if it['motion'] == 'flip':
            fr = it.get('frames') or []
            if not fr:
                errs.append(f'{name}: a flip needs at least one more frame')
            if len(fr) + 1 > MAX_FRAMES:
                errs.append(f'{name}: {len(fr) + 1} frames — at most {MAX_FRAMES}')
            for f in fr:
                if len(f) != len(sl):
                    errs.append(f'{name}: a frame has {len(f)} tiles, the animation {len(sl)}')
                    break
                try:
                    [_hex16(h) for h in f]
                except Exception:
                    errs.append(f'{name}: a frame is not 16-byte tiles')
                    break
        else:
            rows = it.get('rows')
            if it.get('strip', True):
                if len({len(r) for r in rows}) > 1:
                    errs.append(f'{name}: a drifting strip needs rows of equal length')
                if max(len(r) for r in rows) > MAX_STRIP:
                    errs.append(f'{name}: a drifting strip can be at most {MAX_STRIP} tiles '
                                'wide (the frames get big fast)')
    if ngroups > MAX_GROUPS:
        errs.append(f'{ngroups} animation groups in this room — at most {MAX_GROUPS} '
                    f'(every {CAP} tiles of one animation are one group)')
    return errs


# ------------------------------------------------------------- preview
class Player:
    """The game's playback of a room's own animations over its sheet —
    same timers, same staggering, same per-frame cap (bank $6C)."""

    def __init__(self, items, sheet):
        self.base = bytes(sheet)
        self.sheet = bytearray(sheet)
        self.groups = []           # [slots, blocks, seq, period, timer, step]
        try:
            ph = schedule(items)
        except Exception:
            ph = {}
        for i, it in enumerate(items):
            try:
                gs = groups(it, self.base)
            except Exception:
                continue
            for part, blocks, seq in gs:
                self.groups.append([part, blocks, seq, _val(it['speed']), ph.get(i, 1), 0])

    def reset(self):
        self.sheet = bytearray(self.base)
        for g in self.groups:
            g[5] = 0

    def step(self, n=1):
        changed = False
        for _ in range(n):
            left = CAP
            for g in self.groups:
                part, blocks, seq, period = g[0], g[1], g[2], g[3]
                if g[4]:
                    g[4] -= 1
                    if g[4]:
                        continue
                if len(part) > left and left != CAP:
                    continue                       # waits for the next frame
                left = max(0, left - len(part))
                g[4] = period
                g[5] = (g[5] + 1) % len(seq)
                blk = blocks[seq[g[5]]]
                for k, s in enumerate(part):
                    self.sheet[s * 16:s * 16 + 16] = blk[k * 16:k * 16 + 16]
                changed = True
        return changed


# ------------------------------------------------------------- animation banks (S139)
# ROADMAP ARC CAP2d (PROJECT_COMPILER §2.48; ARCHITECTURE "Animation banks"):
# a room's own animations (its group records, sequences and 16-aligned frame
# blocks — never split) live in ONE ANIMATION BANK: bank $6C first, then
# banks $80+ (Project._take_ext_bank('anims'), after the stream and place
# banks), first fit in map id order. Bank $6C holds the forwarder + the
# directory (TileAnimDirectory: per room bank, index); every animation bank
# carries the pinned player (templates/tileanim_player.asm) because the GDMA
# reads its frames from the bank it runs in.
ANIM_HOME = 0x6C
ALIGN_PAD = 15                         # the 16-aligned frame section: <= 15 pad bytes
DIR_ROW_BYTES = 2                      # TileAnimDirectory: db bank, index
TABLE_ROW_BYTES = 2                    # TileAnimRoomTable{A}: dw group list
DATA_MARKER = "TILEANIM DATA (generated"


def suffix(bank):
    """The player block's label suffix in `bank` ("" in bank $6C)."""
    return '' if bank == ANIM_HOME else f"_A{bank:02X}"


def anim_bank_file(bank):
    return f"bank_{bank:03x}.asm"


def player(bank):
    """The pinned player block (templates/tileanim_player.asm) for `bank`."""
    from .emitters import template
    text = template('tileanim_player.asm').replace('{A}', suffix(bank))
    if '{A}' in text:
        raise RuntimeError("tileanim_player.asm: an unreplaced {…} placeholder")
    return text.rstrip('\n')


def room_lines(prj, r):
    """(lines, frames) of one room's animations: lines = its group records +
    sequences (label TileAnimRoom_<idx>), frames = [(label, 16n bytes)] for the
    bank's aligned frame section. Labels are global (the room index is unique)."""
    from . import formats as F
    ri = F.val(r['mapID']) - 0x6B
    items = prj.tile_anims(r)
    sheet = prj.room_sheet(r) or bytes(2048)
    phases = schedule(items)
    lines = [f"TileAnimRoom_{ri}:   ; {r['id']} — {load_words(items)}"]
    seqs, frames = [], []
    for i, it in enumerate(items):
        for g, (part, blocks, seq) in enumerate(groups(it, sheet)):
            tag = f"{ri}_{i}_{g}"
            speed = _val(it['speed'])
            lines.append(f"    db {speed}, {phases[i]}, {len(seq)}, {len(part)}"
                         f"   ; {it.get('name') or it.get('id')}: "
                         f"{MOTION_LABEL[it['motion']].lower()}, {speed_words(speed)}")
            lines.append(f"    dw TileAnimSeq_{tag}")
            lines.append("    dw " + ", ".join(f"${0x9000 + s * 16:04X}" for s in part)
                         + "   ; slots " + ", ".join(str(s) for s in part))
            seqs.append((tag, seq))
            for k, b in enumerate(blocks):
                frames.append((f"TileAnimFrame_{tag}_{k}", bytes(b)))
    lines.append("    db 0   ; end")
    for tag, seq in seqs:
        lines.append(f"TileAnimSeq_{tag}:")
        lines.append("    dw " + ", ".join(f"TileAnimFrame_{tag}_{k}" for k in seq))
    return lines, frames


def anim_rooms(prj):
    """The rooms with own animations, in map id order (placeholders never)."""
    from . import formats as F
    rooms = [r for r in prj.rooms if not r.get('placeholder') and prj.tile_anims(r)]
    # S140 (ROADMAP ARC CAP3a): place-number order (= map id order in one region)
    return sorted(rooms, key=lambda r: prj.place_number(F.val(r['mapID'])))


def plan(prj):
    """Where every room's animations live (cached on the Project).
    {'home': {mapID: (bank, index)}, 'banks': {bank: [(room, lines, frames)]},
     'overflow': [bank, …], 'used': {bank: bytes}, 'dir_rows': n,
     'room_bytes': {mapID: bytes}}"""
    cached = getattr(prj, '_anim_plan', None)
    if cached is not None:
        return cached
    from . import formats as F
    from . import validators as V
    from . import places as PL
    from .project import ProjectError
    PL.plan(prj)                      # stream + place banks take their $80+ numbers first
    rooms = anim_rooms(prj)
    dir_rows = (max(prj.place_number(F.val(r['mapID'])) for r in rooms) + 1) if rooms else 0
    fixed_home = ((V.TEMPLATE_SIZE.get(ANIM_HOME) or 0) + DIR_ROW_BYTES * dir_rows + ALIGN_PAD
                  + V._payload_bytes("\n".join(prj.region_table_lines('6C'))))
    cap = {ANIM_HOME: BANK_BYTES - fixed_home}
    bank_cap = BANK_BYTES - V.ANIM_TEMPLATE_SIZE - ALIGN_PAD
    used = {ANIM_HOME: 0}
    banks = {ANIM_HOME: []}
    order = [ANIM_HOME]
    home, room_bytes = {}, {}
    taken0 = list(getattr(prj, '_ext_taken', None) or [])
    try:
        for r in rooms:
            lines, frames = room_lines(prj, r)
            size = (V._payload_bytes("\n".join(lines)) + sum(len(b) for _l, b in frames)
                    + TABLE_ROW_BYTES)
            mid = F.val(r['mapID'])
            room_bytes[mid] = size
            for b in order:
                if used[b] + size <= cap[b]:
                    break
            else:
                if size > bank_cap:
                    raise ProjectError(
                        f"room {r.get('id')!r}: its animated tiles need {size} bytes — more "
                        f"than one bank holds ({bank_cap}); make strips narrower, use fewer "
                        "frames or split the animations over two rooms (ARC CAP2d, "
                        "PROJECT_COMPILER §2.48)")
                b = prj._take_ext_bank('anims')
                order.append(b)
                cap[b] = bank_cap
                used[b] = 0
                banks[b] = []
            home[mid] = (b, len(banks[b]))
            banks[b].append((r, lines, frames))
            used[b] += size
    except Exception:
        prj._ext_taken = taken0          # a failed plan gives its banks back
        raise
    out = {'home': home, 'banks': banks, 'overflow': [b for b in order if b != ANIM_HOME],
           'used': {b: (fixed_home if b == ANIM_HOME else V.ANIM_TEMPLATE_SIZE + ALIGN_PAD)
                    + used[b] for b in order},
           'dir_rows': dir_rows, 'room_bytes': room_bytes, 'room_cap': bank_cap}
    prj._anim_plan = out
    return out


def _bank_data(p, bank):
    """The generated data of one animation bank (after the marker)."""
    A = suffix(bank)
    ent = p['banks'][bank]
    out = [f"TileAnimRoomTable{A}:   ; index = TileAnimDirectory's (bank ${bank:02X})"]
    for r, _l, _f in ent:
        out.append(f"    dw TileAnimRoom_{_room_idx(r)}   ; {_hexb(r['mapID'])} {r.get('id', '')}")
    for r, lines, _f in ent:
        out.append("")
        out += lines
    frames = [fr for _r, _l, fs in ent for fr in fs]
    if frames:
        from . import formats as F
        out += ["",
                f'SECTION "Bank ${bank:02X} tile animation frames", ROMX, BANK[${bank:02X}], ALIGN[4]',
                "; frame blocks (nslots x 16 B 2bpp, 16-aligned for the GDMA source)"]
        for label, b in frames:
            out.append(f"{label}:")
            for a in range(0, len(b), 16):
                out.append(F.db_line(list(b[a:a + 16])))
    return out


def _room_idx(r):
    from . import formats as F
    return F.val(r['mapID']) - 0x6B


def _hexb(v):
    from . import formats as F
    return F.hexb(F.val(v))


def emit_bank_06c(prj, warnings):
    """Bank $6C: the template head (CustomTileAnimate, the forwarder), the
    player, PlaceNum6C (S140), then TILEANIM_ROOMS + the region tables +
    TileAnimDirectory + bank $6C's own rooms."""
    from . import emitters as E
    from . import formats as F
    p = plan(prj)
    lines = [E.template('bank_06c_head.asm').rstrip('\n'), "", player(ANIM_HOME), ""]
    lines += prj.place_number_block('6C') + [""]
    lines += ["; " + "-" * 77,
              "; " + DATA_MARKER + " by build_project.py from",
              "; custom.rooms[].tile_anims — PROJECT_COMPILER §2.19 / §2.48)",
              "; " + "-" * 77,
              f"TILEANIM_ROOMS EQU {p['dir_rows']}"]
    lines += prj.region_table_lines('6C')
    lines.append("TileAnimDirectory:   ; per PLACE (place number, S140): animation bank (0 = none), index")
    for i in range(p['dir_rows']):
        r = prj.rooms[i]
        mid = F.val(r['mapID'])
        name = r.get('id', '')
        if mid in p['home']:
            b, k = p['home'][mid]
            lines.append(f"    db ${b:02X}, {k}   ; {F.hexb(mid)} {name}")
        else:
            lines.append(f"    db 0, 0   ; {F.hexb(mid)} {name} (none)")
    lines += _bank_data(p, ANIM_HOME)
    return "\n".join(lines) + "\n"


def emit_anim_banks(prj, warnings):
    """{target: text} — one whole file per animation bank $80+ (none when every
    room's animations fit bank $6C). INCLUDEd by bank_ext.asm."""
    from . import emitters as E
    p = plan(prj)
    out = {}
    for b in p['overflow']:
        lines = E.banner(f"BANK ${b:02X} — ANIMATION BANK (generated, S139)", [
            "Rooms' own animated tiles that did not fit bank $6C (ROADMAP ARC",
            "CAP2d; editor2/core/tileanim.py plan, first fit). Bank $6C's",
            "CustomTileAnimate looks the room up in TileAnimDirectory and calls",
            "this bank's entry 0 (TileAnimPlay at $4001) with E = its index here.",
            "The self-ID byte is load-bearing (rst $10 reads [$4000]).",
            "Generated by build_project.py — do not hand-edit."])
        A = suffix(b)
        lines.append(f'SECTION "ROM Bank ${b:03X}", ROMX[$4000], BANK[${b:02X}]')
        lines.append(f"    db ${b:02X}  ; bank self-ID")
        lines.append(f"    dw TileAnimPlay{A}   ; entry 0 (HL=${b:02X}00), E = the room's index")
        lines.append(player(b))
        lines.append("")
        lines += E.banner(DATA_MARKER + f") — bank ${b:02X}")
        lines += _bank_data(p, b)
        out[f"file:patches/{anim_bank_file(b)}"] = "\n".join(lines).rstrip("\n") + "\n"
    return out
