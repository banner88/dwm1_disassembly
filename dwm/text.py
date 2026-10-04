"""DWM1 text encoding: charmap, the one-cell contraction glyphs, decode/encode."""

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

# S120: there is NO letter-pair DTE in this game. $65-$71 are one-cell glyphs of
# the text font (bank $4F $4010 + code*16, rendered and shown in PyBoy S120):
# $65 = the double quote, $66-$71 = apostrophe contractions ("don't" = "don" +
# $67, "I'll" = "I" + $66 + "l"). $72-$7F are blank tiles (never used). The old
# table here ("ll", "th", "he", "be", "or", "an", "in" …) came from another game's
# DTE and mis-decoded every 'd 'y 'e 'c 'n 'T and every quote (TEXT_SYSTEM
# "Glyphs, speakers and voices (S120)"; DOC_AUDIT S120).
DTE = {
    0x65: '"', 0x66: "'l", 0x67: "'t", 0x68: "'s", 0x69: "'r",
    0x6A: "'m", 0x6B: "'y", 0x6C: "'v", 0x6D: "'d", 0x6E: "'e",
    0x6F: "'c", 0x70: "'n", 0x71: "'T",
}
# the other glyphs of the text font that dialogue uses (S120)
TABLE.update({0x96: "[", 0x97: "]", 0x9C: "-", 0x9D: "~", 0x9E: "/", 0x9F: "*",
              0xA0: "(", 0xA1: ")", 0xA2: "+", 0xA3: ":", 0xA4: "\u2026",
              0xB6: "&"})

# Control codes
# (S120 names: $E7 = the YES/NO choice, not an end; $EA / $EB = the voice
# openers (blip $5B / $5A) — they take NO parameter bytes, the "*:" after them
# is ordinary text; $EC = text speed from the menu, $ED = print at once)
CONTROLS = {
    0xE7: "<CHOICE>", 0xE8: "<POS>", 0xE9: "<SOUND>",
    0xEA: "<VOICE_LOW>", 0xEB: "<VOICE_HIGH>", 0xEC: "<SPEED>",
    0xED: "<FAST>", 0xEE: "\n", 0xEF: "<PAGE>",
    0xF0: "<SECTION>", 0xF6: "<HERO>", 0xF7: "<CLEAR>",
    0xFA: "<WAIT>", 0xFF: "<CHOICE2>",
}
PARAMS = {0xE8: 2, 0xE9: 1, 0xF8: 1, 0xF9: 1, 0xFB: 1, 0xFC: 1}   # control codes with parameter bytes (bank $56 TextCodeTable, S120)

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
            i += PARAMS.get(b, 0)
        elif b == 0xF9 and i + 1 < len(data):
            result.append(f"<INS {data[i + 1]:02X}>")
            i += 1
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
