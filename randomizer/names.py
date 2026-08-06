"""Read monster and skill names out of the ROM being randomized.

The randomizer never writes names -- this exists purely so the spoiler log for a
German ROM reads in German.  Bank $41 holds two `dw` pointer tables into
$F0-terminated strings.  Their base addresses differ by region (English $4339 /
$4539; German $4337 / $4537 -- the German build's preceding data is 2 bytes
shorter), so the base is located by scoring candidates rather than hardcoded.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dwm import text as dwm_text

NAME_BANK = 0x41
BANK_BASE = NAME_BANK * 0x4000
STRING_LO, STRING_HI = 0x4E00, 0x7FFF

MONSTER_HINT, MONSTER_COUNT = 0x4339, 221
SKILL_HINT, SKILL_COUNT = 0x4539, 222


def _flat(addr: int) -> int:
    return BANK_BASE + (addr - 0x4000)


# The German build re-uses five slots of the single-byte charmap that the
# English font spends on punctuation.  Derived S76 by decoding known names:
# "Z<5D>ngler"=Züngler (Tonguella), "K<5D><5E>chen"=Küßchen (Lipsy),
# "D<5B>mon"=Dämon, "L<5C>wenhals"=Löwenhals, "MP<9C>Klau"=MP-Klau,
# "K<5C>nig<64>Leo"=König Leo.  German names use no DTE bytes at all.
GERMAN_OVERLAY = {0x5B: "ä", 0x5C: "ö", 0x5D: "ü", 0x5E: "ß",
                  0x64: " ", 0x9C: "-"}
# $5B is undefined in the English charmap, so its presence is a clean tell.
_GERMAN_TELL = 0x5B


def _raw(rom: bytes, addr: int, limit: int = 16) -> bytes | None:
    if not STRING_LO <= addr <= STRING_HI:
        return None
    o = _flat(addr)
    end = rom.find(b"\xf0", o, o + limit + 1)
    if end < 0 or end == o:
        return None
    return rom[o:end]


def _decode(raw: bytes, overlay: dict) -> str:
    out = []
    for b in raw:
        if b in overlay:
            out.append(overlay[b])
        elif b in dwm_text.TABLE:
            out.append(dwm_text.TABLE[b])
        elif b in dwm_text.DTE:
            out.append(dwm_text.DTE[b])
        else:
            out.append(f"<{b:02X}>")
    return "".join(out)


def _read_string(rom: bytes, addr: int, limit: int = 16) -> str | None:
    raw = _raw(rom, addr, limit)
    if raw is None:
        return None
    s = _decode(raw, {})
    return s or None


def _score_base(rom: bytes, base: int, count: int) -> int:
    """How many of `count` consecutive dw entries decode to a plausible name."""
    good = 0
    o = _flat(base)
    for i in range(count):
        addr = int.from_bytes(rom[o + 2 * i : o + 2 * i + 2], "little")
        if _read_string(rom, addr) is not None:
            good += 1
    return good


def _locate(rom: bytes, hint: int, count: int, window: int = 32) -> int:
    best, best_score = hint, -1
    for delta in range(-window, window + 1):
        base = hint + delta
        score = _score_base(rom, base, count)
        # Prefer the highest score; on a tie prefer the candidate nearest the
        # hint, which keeps the English ROM pinned to its documented address.
        if score > best_score or (score == best_score and abs(delta) < abs(best - hint)):
            best, best_score = base, score
    if best_score < count * 0.9:
        raise ValueError(f"name table near {hint:#06x}: only {best_score}/{count} "
                         f"entries decoded")
    return best


def _rows(rom: bytes, base: int, count: int) -> list[bytes | None]:
    o = _flat(base)
    return [_raw(rom, int.from_bytes(rom[o + 2 * i : o + 2 * i + 2], "little"))
            for i in range(count)]


def _table(rows: list[bytes | None], overlay: dict, prefix: str) -> list[str]:
    return [(_decode(r, overlay) if r else "") or f"{prefix}{i}"
            for i, r in enumerate(rows)]


def load(rom: bytes, layout=None) -> dict:
    """Return {'species': [...221], 'skills': [...222]} for this ROM."""
    mon_rows = _rows(rom, _locate(rom, MONSTER_HINT, MONSTER_COUNT), MONSTER_COUNT)
    skl_rows = _rows(rom, _locate(rom, SKILL_HINT, SKILL_COUNT), SKILL_COUNT)
    overlay = {}
    if any(r and _GERMAN_TELL in r for r in mon_rows + skl_rows):
        overlay = GERMAN_OVERLAY
    return {"species": _table(mon_rows, overlay, "species#"),
            "skills": _table(skl_rows, overlay, "skill#"),
            "charmap": "german" if overlay else "english"}
