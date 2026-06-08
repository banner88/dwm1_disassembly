"""DWM1 English text codec. Table from romhacking.net wiki."""

TABLE: dict[int, str] = {
    **{i: str(i) for i in range(10)},                  # 0x00-0x09 = "0"-"9"
    **{0x24 + i: chr(ord('A') + i) for i in range(26)},# 0x24-0x3D = A-Z
    **{0x3E + i: chr(ord('a') + i) for i in range(26)},# 0x3E-0x57 = a-z
    0x5C: "'",  0x5E: ",", 0x5F: ".", 0x60: ";",  0x61: "..",
    0x62: " ",  0x63: "!", 0x64: "?", 0x65: '"',
    0x66: "'l", 0x67: "'t", 0x68: "'s", 0x69: "'r",
    0x6A: "'m", 0x6B: "'y", 0x6C: "'v", 0x6D: "'d",
    0x6E: "'e", 0x6F: "'c", 0x70: "'n", 0x71: "'T",
    0x87: "'t",
}
END_OF_STRING = 0xF0

# For decoding: single byte -> string fragment
# For encoding: prefer longer matches first (so "'s" beats "'")
REVERSE_SINGLE: dict[str, int] = {v: k for k, v in TABLE.items() if len(v) == 1}
REVERSE_MULTI:  dict[str, int] = {v: k for k, v in TABLE.items() if len(v) > 1}


def decode(data: bytes) -> tuple[str, int]:
    """Decode bytes until 0xF0. Returns (text, bytes_consumed_incl_terminator).
    Unknown bytes become {XX} escapes for safe round-tripping."""
    out: list[str] = []
    for i, b in enumerate(data):
        if b == END_OF_STRING:
            return "".join(out), i + 1
        if b in TABLE:
            out.append(TABLE[b])
        else:
            out.append(f"{{{b:02X}}}")
    raise ValueError("No 0xF0 terminator in slice")


def encode(s: str) -> bytes:
    """Encode string to bytes incl. terminator. Handles {XX} escapes."""
    out = bytearray()
    i = 0
    while i < len(s):
        if s[i] == "{":
            end = s.index("}", i)
            out.append(int(s[i+1:end], 16))
            i = end + 1
            continue
        # Try 2-char multibyte tokens first
        if i + 1 < len(s) and s[i:i+2] in REVERSE_MULTI:
            out.append(REVERSE_MULTI[s[i:i+2]])
            i += 2
            continue
        if s[i] in REVERSE_SINGLE:
            out.append(REVERSE_SINGLE[s[i]])
            i += 1
            continue
        raise ValueError(f"Cannot encode {s[i]!r} at pos {i} in {s!r}")
    out.append(END_OF_STRING)
    return bytes(out)
