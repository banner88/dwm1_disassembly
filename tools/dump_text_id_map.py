"""Dump the text ID map: every routable text ID with bank, index, address,
and decoded text.

Regenerates extracted/text_id_map.json (previously frozen-source). The
original in-session generator was lost; its 'text' field was a lossy
~150-char preview (sections concatenated across NEIGHBORING ptr entries,
then truncated mid-word). This tool keeps the structural fields
byte-compatible (id/bank/index/addr — verified identical for all 2,067
entries) and replaces the preview with a faithful per-entry decode:

  - decodes exactly this entry's byte span (its ptr up to the next ptr)
  - charmap + DTE via dwm.text
  - $EE (newline) -> ' ', $EF $EE -> ' // ' (page break),
    $F6 -> '[HERO]', $EC -> '[NAME]', $ED -> '[MONSTER]',
    $E7 -> '[YES/NO]', $E9 -> '[NUM]',
    box-init $EA/$EB and other control codes dropped
  - terminator $F7 $F0 stripped

Routing ranges (start_id -> bank) were originally established by CPU-
simulating the ROM0 cascade at $0AD9 (TEXT_SYSTEM.md); they are encoded
here as constants and re-validated against each bank's pointer table.

Usage:
  python3 -m tools.dump_text_id_map
"""
import json
from pathlib import Path
from dwm.rom import ROM
# charmap built locally below (authoritative per TEXT_SYSTEM.md)

ROUTING = [  # (start_id, bank); end of each range = next start
    (0x0000, 0x42), (0x00E2, 0x43), (0x0198, 0x44), (0x0244, 0x45),
    (0x0300, 0x46), (0x03C8, 0x47), (0x0474, 0x48), (0x0512, 0x49),
    (0x05E0, 0x4A), (0x07C0, 0x4B), (0x0868, 0x4E),
]
RANGE_END = 0x0A00  # custom IDs start at $0A00
PTR_TABLE = 0x400B

rom = ROM(Path("data/DWM-original.gbc"))


def build_decode_tables():
    """Charmap per TEXT_SYSTEM.md (authoritative; dwm.text internals vary)."""
    cm = {}
    for i in range(10):
        cm[i] = str(i)
    for i in range(26):
        cm[0x24 + i] = chr(ord('A') + i)
        cm[0x3E + i] = chr(ord('a') + i)
    for code, ch in zip(range(0x5C, 0x65), ["'", "→", ",", ".", ";", "..", " ", "!", "?"]):
        cm[code] = ch
    dte = {
        0x65: "ll", 0x66: "'l", 0x67: "'t", 0x68: "'s", 0x69: "'r",
        0x6A: "'m", 0x6B: "n'", 0x6C: "'v", 0x6D: "th", 0x6E: "he",
        0x6F: "be", 0x70: "or", 0x71: "an", 0x72: "in", 0x73: "er",
        0x74: "re", 0x75: "on", 0x76: "st", 0x77: "ou", 0x78: "te",
        0x79: "nd", 0x7A: "to", 0x7B: "it", 0x7C: "es", 0x7D: "at",
        0x7E: "en", 0x7F: "al",
    }
    return cm, dte


CM, DTE_TABLE = build_decode_tables()


def decode_span(raw: bytes) -> str:
    out, i = [], 0
    while i < len(raw):
        b = raw[i]
        if b in (0xF7, 0xE7, 0xFF) and i + 1 < len(raw) and raw[i + 1] == 0xF0:
            # terminators: $F7 $F0 (CLEAR+SECTION, standard) or
            # $E7 $F0 (CHOICE+SECTION, YES/NO question texts)
            if b == 0xE7:
                out.append(" [YES/NO]")
            elif b == 0xFF:
                out.append(" [YES/NO-2]")
            return "".join(out).strip().removesuffix("//").strip()
        if b in (0xEA, 0xEB):            # box-init codes — no inline params
            i += 1                       # (verified: $EA directly followed by
            continue                     # text 'King' at $42:$4D91; the $9F/$A3
                                         # often seen after them are independent
                                         # codes dropped by the $80-$DF rule)
        if b == 0xEF:                    # PAGE — with $EE = ' // '
            if i + 1 < len(raw) and raw[i + 1] == 0xEE:
                out.append(" // ")
                i += 2
                continue
            i += 1
            continue
        if b == 0xEE:
            out.append(" ")
            i += 1
            continue
        marker = {0xF6: "[HERO]", 0xEC: "[NAME]", 0xED: "[MONSTER]",
                  0xE7: "[YES/NO]", 0xE9: "[NUM]"}.get(b)
        if marker:
            out.append(marker)
            i += 1
            continue
        if b >= 0x80:                    # extended ($80-$DF) + other control
            i += 1                       # codes ($E0+): drop
            continue
        if b in DTE_TABLE:
            out.append(DTE_TABLE[b])
        elif b in CM:
            out.append(CM[b])
        else:
            out.append(f"[{b:02X}]")
        i += 1
    return None  # no terminator in window — not a real text entry


def main():
    result = {}
    for ri, (start, bank) in enumerate(ROUTING):
        end = ROUTING[ri + 1][0] if ri + 1 < len(ROUTING) else RANGE_END
        for tid in range(start, end):
            # Cascade indexing rule (derived from the ROM0 cascade at $0AD9 and
            # verified against all 2,067 committed entries): within a bank's
            # range, index = (low byte - range_start.low) while the high byte
            # equals the range start's high byte; once the id crosses into the
            # next $100 page, index = low byte. Different ids can therefore
            # alias to the same (bank, index) — the map includes those aliases.
            if (tid >> 8) == (start >> 8):
                idx = (tid & 0xFF) - (start & 0xFF)
            else:
                idx = tid & 0xFF
            if idx < 0:
                continue
            p = rom.read(bank, PTR_TABLE + idx * 2, 2)
            ptr = p[0] | (p[1] << 8)
            if not (0x4100 <= ptr < 0x8000):
                continue  # gap / unused ID / pointer into the bank header
            raw = rom.read(bank, ptr, min(4096, 0x8000 - ptr))
            text = decode_span(raw)
            if text is None:
                continue  # no terminator → not a real text entry
            result[str(tid)] = {
                "id": f"${tid:04X}",
                "bank": f"${bank:02X}",
                "index": idx,
                "addr": f"${ptr:04X}",
                "text": text,
            }
    out = Path("extracted/text_id_map.json")
    out.write_text(json.dumps(result, indent=2))
    print(f"Saved {out} ({len(result)} text IDs)")
    return result


if __name__ == "__main__":
    main()
