"""
dwm.sprite_codec — the single LZ codec for DWM1 graphics.

This is the ONE place that knows the game's compression format. Both the tile
pipeline (compress_tiles / decompress_tiles) and the monster-sprite tools
(GFX-1: extract_monster_sprites, build_sprite_swap) build on it, so the format
can't drift between two private copies.

FORMAT (verified against the ROM resolver DecompressTileLayout $00:$1627 and the
decompressor $00:$1577 — see MONSTER_DATA.md "Monster sprite graphics system"):

  Stream = 3-byte header [declen_lo, declen_hi, marker] + body.
  Body byte != marker  -> literal, copied to output.
  Body byte == marker  -> back-reference: next two bytes [off_lo, ctrl]
      back_offset = off_lo | ((ctrl >> 4) & 0xF) << 8      (ABSOLUTE into output)
      copy_len    = (ctrl & 0xF) + 4
      if (ctrl & 0xF) == 0xF: copy_len = next_byte + 0x13   (extended)
  Back-references index the output buffer ABSOLUTELY (the game's output base is
  the VRAM dest in HRAM $ac/$ad). For a monster battle/follower stream the early
  part of that buffer is a SHARED tile pool pre-loaded before the stream, so a
  stream with back-refs does NOT decode standalone to a self-contained image —
  it references pool tiles. A stream whose body contains NO marker byte is a pure
  literal copy and IS self-contained (the swap lever used by build_sprite_swap).

ROUND-TRIP CONTRACT (what the editor relies on):
  decode(encode(x)) == x   for any payload x   (SEMANTIC round-trip).
  decode(rom_stream)       == the bytes the game produces.
We deliberately do NOT promise encode(decode(rom_stream)) == rom_stream (byte-
identical re-encoding of a vanilla stream). LZ is many-to-one: many valid streams
decode to the same payload, and the game's original encoder made different greedy
choices than ours. Byte-identical re-encoding has ZERO editor value (the editor
emits NEW art, never re-emits originals) and reverse-engineering the original
heuristic is a research rabbit hole. encode() produces a VALID, compact stream;
that is the correct and sufficient guarantee. (Do not "fix" this.)
"""
from __future__ import annotations

HEADER_LEN = 3
MAX_BACK_OFFSET = 0xFFF            # 12-bit absolute offset
MAX_COPY = 0xFF + 0x13            # extended-length ceiling


# ----------------------------------------------------------------------------
# Core LZ
# ----------------------------------------------------------------------------
def decode(stream: bytes) -> bytes:
    """Decompress a full stream (with 3-byte header). Returns the payload bytes.

    Back-references resolve absolutely into the growing output buffer, matching
    the game. For self-contained (marker-free) streams this is a plain literal
    copy; for pool-referencing streams the referenced low offsets read whatever
    has been produced so far (the caller is responsible for any shared pool if a
    faithful VRAM reproduction is wanted — for extraction we read the stream as
    the game would into a zero-initialised buffer)."""
    if len(stream) < HEADER_LEN:
        raise ValueError("stream shorter than header")
    declen = stream[0] | (stream[1] << 8)
    marker = stream[2]
    out = bytearray()
    p = HEADER_LEN
    n = len(stream)
    while len(out) < declen and p < n:
        b = stream[p]; p += 1
        if b != marker:
            out.append(b)
        else:
            if p + 1 >= n:
                break
            off_lo = stream[p]; ctrl = stream[p + 1]; p += 2
            back = off_lo | (((ctrl >> 4) & 0xF) << 8)
            cnt = (ctrl & 0xF) + 4
            if (ctrl & 0xF) == 0xF:
                if p >= n:
                    break
                cnt = stream[p] + 0x13; p += 1
            for k in range(cnt):
                if len(out) >= declen:
                    break
                ref = back + k
                out.append(out[ref] if 0 <= ref < len(out) else 0)
    return bytes(out[:declen])


def _find_match(data: bytes, pos: int):
    """Greedy longest match earlier in the output buffer (absolute window)."""
    best_off = best_len = 0
    start = max(0, pos - MAX_BACK_OFFSET)
    end = pos
    # only non-overlapping copies (game copies forward without overlap safety)
    for off in range(start, end):
        ln = 0
        maxln = min(MAX_COPY, len(data) - pos, pos - off)  # no overlap past pos
        while ln < maxln and data[off + ln] == data[pos + ln]:
            ln += 1
        if ln > best_len:
            best_len, best_off = ln, off
    return best_off, best_len


def choose_marker(data: bytes) -> int:
    freq = [0] * 256
    for b in data:
        freq[b] += 1
    return freq.index(min(freq))


def encode(payload: bytes, marker: int | None = None, literal_only: bool = False) -> bytes:
    """Compress payload into a valid stream (3-byte header + body).

    literal_only=True forces a self-contained marker-free body (pure literal copy
    — the swap lever; larger but independent of any shared pool). Otherwise a
    greedy LZ pass is used. Guarantees decode(encode(x)) == x."""
    if marker is None:
        marker = choose_marker(payload)
    out = bytearray([len(payload) & 0xFF, (len(payload) >> 8) & 0xFF, marker])
    if literal_only:
        # marker must not occur in payload for a clean literal copy
        if marker in payload:
            raise ValueError("literal_only requires a marker absent from payload; "
                             "none free" if len(set(payload)) == 256 else
                             "pick a marker not in payload")
        out += payload
        return bytes(out)

    pos = 0
    n = len(payload)
    while pos < n:
        off, ln = _find_match(payload, pos)
        # encoding a back-ref costs 3 bytes; only worth it for len>=4 and never
        # when the literal byte equals the marker (which would be misread)
        if ln >= 4:
            ctrl_lo = ln - 4
            hi = (off >> 8) & 0xF
            out.append(marker)
            out.append(off & 0xFF)
            if ctrl_lo <= 0x0E:
                out.append((hi << 4) | ctrl_lo)
            else:
                out.append((hi << 4) | 0x0F)
                out.append(ctrl_lo - 0x0F)
            pos += ln
        else:
            b = payload[pos]
            if b == marker:
                # a literal equal to the marker would be misread as a back-ref.
                # emit a 4-byte self-copy back-ref of this single byte? not safe.
                # simplest correct fix: re-encode whole payload with a marker that
                # is guaranteed absent (caller's choose_marker already minimises;
                # if the least-frequent byte still appears we must escape). Encode
                # as a back-reference to itself is impossible (no prior copy). So
                # fall back: choose a marker value that does not occur at all.
                raise _MarkerCollision(b)
            out.append(b)
            pos += 1
    return bytes(out)


class _MarkerCollision(Exception):
    def __init__(self, byte): self.byte = byte


def encode_safe(payload: bytes, literal_only: bool = False) -> bytes:
    """encode() with automatic marker selection that retries if the chosen marker
    appears as a literal. Prefers a byte value entirely absent from the payload
    (so no literal can collide); falls back to least-frequent otherwise."""
    absent = [b for b in range(256) if b not in set(payload)]
    if absent:
        return encode(payload, marker=absent[0], literal_only=literal_only)
    # payload uses all 256 values: pick least frequent and accept that literals
    # equal to it must be encoded as back-refs (greedy pass will usually cover
    # them; if not, encode() raises and we surface it).
    return encode(payload, marker=choose_marker(payload), literal_only=literal_only)


# ----------------------------------------------------------------------------
# Tile <-> image helpers (2bpp planar, GB format)
# ----------------------------------------------------------------------------
def tiles_to_indices(data: bytes, cols: int, rows: int):
    """Decode 2bpp tile bytes (16 B/tile, row-major cols x rows) into a 2D list
    of palette indices [y][x], size (rows*8) x (cols*8)."""
    h, w = rows * 8, cols * 8
    grid = [[0] * w for _ in range(h)]
    for tj in range(rows):
        for ti in range(cols):
            base = (tj * cols + ti) * 16
            for r in range(8):
                lo = data[base + r * 2]
                hi = data[base + r * 2 + 1]
                for c in range(8):
                    bit = 7 - c
                    v = ((lo >> bit) & 1) | (((hi >> bit) & 1) << 1)
                    grid[tj * 8 + r][ti * 8 + c] = v
    return grid


def indices_to_tiles(grid, cols: int, rows: int) -> bytes:
    """Inverse of tiles_to_indices: 2D index grid -> 2bpp tile bytes."""
    out = bytearray()
    for tj in range(rows):
        for ti in range(cols):
            for r in range(8):
                lo = hi = 0
                for c in range(8):
                    v = grid[tj * 8 + r][ti * 8 + c] & 3
                    bit = 7 - c
                    lo |= (v & 1) << bit
                    hi |= ((v >> 1) & 1) << bit
                out.append(lo); out.append(hi)
    return bytes(out)


# ----------------------------------------------------------------------------
# ROM stream addressing
# ----------------------------------------------------------------------------
def bank_base(bank: int) -> int:
    return bank * 0x4000


def gfxid_stream_offset(rom: bytes, gfxid: int):
    """Resolve a gfx-ID (bank<<8 | index) to (bank, index, stream_addr, file_off)
    via the per-bank pointer table at $<bank>:$4001 + index*2."""
    bank = (gfxid >> 8) & 0xFF
    index = gfxid & 0xFF
    ptbl = bank_base(bank) + 1  # $4001 in bank space == base + 1
    e = ptbl + index * 2
    stream_addr = rom[e] | (rom[e + 1] << 8)
    file_off = bank_base(bank) + (stream_addr - 0x4000)
    return bank, index, stream_addr, file_off


def read_stream(rom: bytes, file_off: int) -> bytes:
    """Read a full stream (header + body) from a ROM file offset, by decoding the
    declared length and walking the body to its true end."""
    declen = rom[file_off] | (rom[file_off + 1] << 8)
    marker = rom[file_off + 2]
    p = file_off + 3
    produced = 0
    while produced < declen:
        b = rom[p]; p += 1
        if b != marker:
            produced += 1
        else:
            ctrl = rom[p + 1]
            cnt = (ctrl & 0xF) + 4
            p += 2
            if (ctrl & 0xF) == 0xF:
                cnt = rom[p] + 0x13; p += 1
            produced += cnt
    return rom[file_off:p]
