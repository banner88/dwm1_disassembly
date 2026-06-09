"""DWM1 text encoding: charmap, DTE pairs, decode/encode."""

END_OF_STRING = 0xF0

# Single-byte character map (byte -> string)
TABLE = {
    0x00: "0", 0x01: "1", 0x02: "2", 0x03: "3", 0x04: "4",
    0x05: "5", 0x06: "6", 0x07: "7", 0x08: "8", 0x09: "9",
    0x0A: "<0>", 0x0B: "<1>", 0x0C: "<2>", 0x0D: "<3>",
    0x10: "<slime>", 0x11: "<dragon>", 0x12: "<beast>",
    0x13: "<bird>", 0x14: "<plant>", 0x15: "<bug>",
    0x16: "<devil>", 0x17: "<zombie>", 0x18: "<material>",
    0x19: "<???>",
    0x24: "A", 0x25: "B", 0x26: "C", 0x27: "D", 0x28: "E",
    0x29: "F", 0x2A: "G", 0x2B: "H", 0x2C: "I", 0x2D: "J",
    0x2E: "K", 0x2F: "L", 0x30: "M", 0x31: "N", 0x32: "O",
    0x33: "P", 0x34: "Q", 0x35: "R", 0x36: "S", 0x37: "T",
    0x38: "U", 0x39: "V", 0x3A: "W", 0x3B: "X", 0x3C: "Y",
    0x3D: "Z",
    0x3E: "a", 0x3F: "b", 0x40: "c", 0x41: "d", 0x42: "e",
    0x43: "f", 0x44: "g", 0x45: "h", 0x46: "i", 0x47: "j",
    0x48: "k", 0x49: "l", 0x4A: "m", 0x4B: "n", 0x4C: "o",
    0x4D: "p", 0x4E: "q", 0x4F: "r", 0x50: "s", 0x51: "t",
    0x52: "u", 0x53: "v", 0x54: "w", 0x55: "x", 0x56: "y",
    0x57: "z",
    0x5C: "'", 0x5D: "<right>", 0x5E: ",", 0x5F: ".", 0x60: ";",
    0x61: "..", 0x62: " ", 0x63: "!", 0x64: "?",
}

# DTE (Dual-Tile Encoding) pairs: single byte -> two characters
DTE = {
    0x65: "ll", 0x66: "'l", 0x67: "'t", 0x68: "'s", 0x69: "'r",
    0x6A: "'m", 0x6B: "n'", 0x6C: "'v", 0x6D: "th", 0x6E: "he",
    0x6F: "be", 0x70: "or", 0x71: "an", 0x72: "in", 0x73: "er",
    0x74: "re", 0x75: "on", 0x76: "st", 0x77: "ou", 0x78: "te",
    0x79: "nd", 0x7A: "to", 0x7B: "it", 0x7C: "es", 0x7D: "at",
    0x7E: "en", 0x7F: "al",
}

# Control codes
CONTROLS = {
    0xE7: "<END>", 0xE8: "<PAUSE>", 0xE9: "<NUM>",
    0xEA: "<BOX>", 0xEB: "<ITEM>", 0xEC: "<NAME>",
    0xED: "<MONSTER>", 0xEE: "\n", 0xEF: "<PAGE>",
    0xF0: "<SECTION>", 0xF6: "<HERO>", 0xF7: "<CLEAR>",
    0xFA: "<WAIT>", 0xFF: "<CHOICE>",
}

# Build reverse lookups for encoding
REVERSE_SINGLE = {v: k for k, v in TABLE.items()}
REVERSE_MULTI = {v: k for k, v in DTE.items()}


def decode(data: bytes) -> tuple[str, int]:
    """Decode DWM text bytes to string. Returns (string, bytes_consumed)."""
    result = []
    i = 0
    while i < len(data):
        b = data[i]
        if b == END_OF_STRING:
            i += 1
            break
        if b in TABLE:
            result.append(TABLE[b])
        elif b in DTE:
            result.append(DTE[b])
        elif b in CONTROLS:
            result.append(CONTROLS[b])
            # BOX control has 2 parameter bytes
            if b == 0xEA and i + 2 < len(data):
                i += 2
        else:
            result.append(f"[{b:02X}]")
        i += 1
    return "".join(result), i


def encode(text: str) -> bytes:
    """Encode a string to DWM text bytes (terminated with F0)."""
    result = []
    i = 0
    while i < len(text):
        # Try 2-char DTE first
        if i + 1 < len(text):
            pair = text[i:i+2]
            if pair in REVERSE_MULTI:
                result.append(REVERSE_MULTI[pair])
                i += 2
                continue
        # Single char
        ch = text[i]
        if ch in REVERSE_SINGLE:
            result.append(REVERSE_SINGLE[ch])
        elif ch == "\n":
            result.append(0xEE)
        else:
            raise ValueError(f"Cannot encode character: {ch!r}")
        i += 1
    result.append(END_OF_STRING)
    return bytes(result)
