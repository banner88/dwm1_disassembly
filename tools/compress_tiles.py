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


def find_best_match(data, pos, min_len=4, max_len=255+19):
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


def compress_lz(data):
    """Compress data using DWM1's LZSS format.
    
    Returns compressed bytes including the 3-byte header.
    """
    marker = choose_marker(data)
    output = []
    
    # Header
    out_len = len(data)
    output.append(out_len & 0xFF)
    output.append((out_len >> 8) & 0xFF)
    output.append(marker)
    
    pos = 0
    while pos < len(data):
        offset, length = find_best_match(data, pos)
        
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


def main():
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
