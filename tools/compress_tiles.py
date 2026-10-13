#!/usr/bin/env python3
"""LZSS compressor for DWM1 tile data.

Produces compressed data compatible with the game's decompressor
(Call_000_14cf / Call_000_1577).

Format:
  Header: [output_length:2 LE][marker_byte:1]
  Body: literal bytes + back-references
  Back-reference: [marker][offset_lo][control]
    control high nibble = offset_hi (bits 11-8)
    control low nibble = copy_length - 4 (0-14)
    If low nibble == 0x0F: next byte = copy_length - 19

The marker byte is chosen to minimize occurrences in the input data.
"""
import os, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(SCRIPT_DIR, '..', 'data', 'DWM-original.gbc')


def choose_marker(data):
    """Choose the least frequent byte value as the marker."""
    freq = [0] * 256
    for b in data:
        freq[b] += 1
    return freq.index(min(freq))


# S100 r3: the game adds 19 to the extended length byte in 8 bits ($00:DecompressTileLayout
# HandleCompressedRun `add $13`; the copy loop is dec/jr nz, so 0 = 256). A copy of
# 257-274 bytes therefore wraps to 1-18 in the game and the rest of the sheet lands
# 256 bytes early (user S100: imported room drawn as flat colour blocks — its blank
# tileset opens with a 900+ byte zero run). 256 is the longest copy the game decodes.
MAX_COPY = 256


def find_best_match(data, pos, min_len=4, max_len=MAX_COPY):
    """Find the longest match starting at pos from earlier in the buffer."""
    best_offset = 0
    best_length = 0
    
    # Search window: 0 to pos-1 (back-reference from output buffer start)
    # Max offset = 0xFFF (12 bits: 4 high + 8 low)
    search_start = max(0, pos - 0xFFF)
    
    for off in range(search_start, pos):
        length = 0
        while (pos + length < len(data) and 
               length < max_len and
               data[off + length] == data[pos + length]):
            length += 1
            # Handle overlapping copies (repeating patterns)
            if off + length >= pos:
                # Wrap: copy from start of match
                break
        
        if length >= min_len and length > best_length:
            best_length = length
            best_offset = off
    
    return best_offset, best_length


class _Matcher:
    """S145 (ROADMAP ARC CAP4d): `find_best_match` with the SAME answer, fast.

    Measured S145: a fresh 160-room project (own tilesets) spent 16 s in the brute-force
    search above on the editor's first space measurement (every distinct stream, every
    editor start; S142's scale probe used copies — identical streams, memo hits — and
    never saw it); it ran in the meter's thread and held the interpreter, so opening the
    project took 22 s instead of 4.4.

    `find_best_match`'s answer is: over off = search_start .. pos-1 ascending, the common
    prefix of data[off:] and data[pos:] capped at L = min(pos - off, len - pos, max_len)
    (the `off + length >= pos` break caps it at pos - off); the FIRST offset with the
    largest length >= min_len. A length >= 4 needs the 4 bytes at off == those at pos and
    pos - off >= 4, so only offsets in the 4-gram index qualify (min_len 4 only); each
    candidate's length is found by slice compares (binary search); the scan stops once no
    later candidate can be longer (L shrinks as off grows). Byte-identical to the
    reference on every stream checked (`selftest`, TOOLS_AND_DATA S145)."""

    def __init__(self, data, min_len=4, max_len=MAX_COPY):
        assert min_len == 4
        self.d = bytes(data)
        self.n = len(self.d)
        self.max_len = max_len
        self.index = {}
        self.upto = 0                       # positions < upto are indexed

    def best(self, pos):
        from bisect import bisect_left
        d, n = self.d, self.n
        while self.upto <= pos - 4:         # an offset needs pos - off >= 4
            i = self.upto
            self.index.setdefault(d[i:i + 4], []).append(i)
            self.upto += 1
        if pos + 4 > n:
            return 0, 0
        cand = self.index.get(d[pos:pos + 4])
        if not cand:
            return 0, 0
        top = min(n - pos, self.max_len)
        lo = bisect_left(cand, max(0, pos - 0xFFF))
        best_off = best_len = 0
        for j in range(lo, len(cand)):
            off = cand[j]
            cap = min(pos - off, top)
            if cap <= best_len:
                break                       # later offsets are nearer: shorter caps
            if d[off:off + cap] == d[pos:pos + cap]:
                ln = cap
            else:
                a, b = 4, cap - 1           # d[off:off+a] equal, d[off:off+b+1] not
                while a < b:
                    mid = (a + b + 1) // 2
                    if d[off:off + mid] == d[pos:pos + mid]:
                        a = mid
                    else:
                        b = mid - 1
                ln = a
            if ln > best_len:
                best_off, best_len = off, ln
                if best_len >= top:
                    break
        return best_off, best_len


def compress_lz(data, reference=False):
    """Compress data using DWM1's LZSS format.

    Returns compressed bytes including the 3-byte header.
    reference=True (S145): the original brute-force search (`find_best_match`);
    the default `_Matcher` gives the same bytes, fast.
    """
    marker = choose_marker(data)
    output = []
    matcher = None if reference else _Matcher(data)

    # Header
    out_len = len(data)
    output.append(out_len & 0xFF)
    output.append((out_len >> 8) & 0xFF)
    output.append(marker)

    pos = 0
    while pos < len(data):
        offset, length = (find_best_match(data, pos) if matcher is None
                          else matcher.best(pos))
        
        if length >= 4:
            # Back-reference
            output.append(marker)
            output.append(offset & 0xFF)
            
            adj_len = length - 4
            offset_hi = (offset >> 8) & 0x0F
            
            if adj_len <= 0x0E:
                control = (offset_hi << 4) | adj_len
                output.append(control)
            else:
                # Extended length
                control = (offset_hi << 4) | 0x0F
                output.append(control)
                output.append(adj_len - 0x0F)
            
            pos += length
        else:
            # Literal byte
            b = data[pos]
            output.append(b)
            if b == marker:
                # Marker byte appearing as literal — need to escape it
                # Actually in this format, marker ALWAYS starts a back-ref.
                # If the literal IS the marker, we need a zero-length back-ref
                # or choose a different marker. The game handles this by
                # choosing a marker that doesn't appear in the data.
                # Our choose_marker() picks the least frequent, but it might
                # still appear. Handle by encoding as a self-referencing copy.
                if pos > 0:
                    # Encode as back-ref to the same position
                    output[-1] = marker  # already set
                    output.append(pos & 0xFF)
                    output.append(((pos >> 8) & 0x0F) << 4 | 0)  # length=4
                    # But this copies 4 bytes from pos, which is current position...
                    # This is tricky. For now, just pick a marker that has 0 occurrences.
                    pass
            pos += 1
    
    return bytes(output)


def selftest():
    """S145: the fast matcher == the reference search, byte for byte, on seeded random
    inputs of every shape the editor makes (noise, sparse floors, repeating patterns with
    errors, all-zero sheets, 16 B - 4 KB) and — with the ROM — on 48 of the game's own
    tile layouts and sheets decompressed from banks $28-$2F. Exit 1 on any difference."""
    import random
    rnd = random.Random(145)
    corpus = []
    for i in range(48):
        n = rnd.choice([16, 64, 320, 2048, 4096])
        kind = i % 4
        if kind == 0:
            b = bytes(rnd.randrange(256) for _ in range(n))
        elif kind == 1:
            b = bytes(rnd.choice([0, 0, 0, 1, 2, 0x33]) for _ in range(n))
        elif kind == 2:
            pat = bytes(rnd.randrange(4) for _ in range(rnd.randrange(1, 40)))
            b = bytes(x if rnd.random() > 0.02 else rnd.randrange(256)
                      for x in (pat * (n // len(pat) + 1))[:n])
        else:
            b = bytes(n)
        corpus.append(('random %d' % i, b))
    if os.path.exists(ROM_PATH):
        sys.path.insert(0, os.path.join(SCRIPT_DIR, '..'))
        from tools.decompress_tiles import decompress_lz
        rom = open(ROM_PATH, 'rb').read()
        for bank in range(0x28, 0x30):
            for sid in range(0, 12, 2):
                try:
                    res = decompress_lz(rom, bank, sid)
                except Exception:                  # noqa: BLE001
                    res = None
                if res and res[0]:
                    corpus.append((f'ROM ${bank:02X} #{sid}', bytes(res[0])))
    else:
        print('  (no ROM: the game\'s own streams skipped)')
    bad = [name for name, b in corpus if compress_lz(b) != compress_lz(b, reference=True)]
    print(f'compress_tiles selftest: {len(corpus)} inputs, {len(bad)} differ'
          + (f' — {bad[:5]}' if bad else ''))
    return not bad


def main():
    if '--selftest' in sys.argv:
        sys.exit(0 if selftest() else 1)
    # Test: compress and decompress, verify roundtrip
    sys.path.insert(0, os.path.join(SCRIPT_DIR, '..'))
    from tools.decompress_tiles import decompress_lz
    
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    
    # Test with Castle screen 5 tile layout (bank $2A, step_id $07)
    result = decompress_lz(rom, 0x2A, 0x07)
    if not result:
        print("Failed to decompress test data")
        return
    
    original, addr = result
    print(f"Original: {len(original)} bytes from ${addr:04X}")
    
    # Compress
    compressed = compress_lz(original)
    print(f"Compressed: {len(compressed)} bytes (ratio: {len(compressed)/len(original):.2f})")
    
    # Decompress our compressed output and verify
    # We need to decompress without the bank/pointer table lookup
    # Parse header manually
    out_len = compressed[0] | (compressed[1] << 8)
    marker = compressed[2]
    src = 3
    
    output = bytearray(out_len)
    out_pos = 0
    
    while out_pos < out_len and src < len(compressed):
        b = compressed[src]
        src += 1
        
        if b != marker:
            output[out_pos] = b
            out_pos += 1
        else:
            offset_low = compressed[src]; src += 1
            control = compressed[src]; src += 1
            copy_len = (control & 0x0F) + 4
            if copy_len == 0x13:
                copy_len = compressed[src] + 0x13; src += 1
            offset_high = (control >> 4) & 0x0F
            back_offset = (offset_high << 8) | offset_low
            
            for i in range(copy_len):
                if out_pos >= out_len: break
                ref = back_offset + i
                output[out_pos] = output[ref] if ref < out_len else 0
                out_pos += 1
    
    if bytes(output) == original:
        print("✓ Roundtrip VERIFIED — compress→decompress matches original!")
    else:
        # Find first difference
        for i in range(min(len(output), len(original))):
            if output[i] != original[i]:
                print(f"✗ MISMATCH at byte {i}: got ${output[i]:02X} expected ${original[i]:02X}")
                break
        print(f"Output length: {len(output)}, expected: {len(original)}")


if __name__ == '__main__':
    main()
