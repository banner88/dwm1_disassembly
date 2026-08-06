"""Rebuild the library / encyclopedia recipe TEXT in bank $4D.

Discovered S76 (emulator-reproduced, then ROM-verified in both regions).

The monster-detail page shows a breeding recipe as two lines.  The parent
SPRITES are resolved live -- bank $12 `LoadItem_65a8` far-calls bank $16 entry 1,
which reads `FamilyRecipeTable[species*2]`.  The two lines of TEXT beside them
are NOT computed from anything: they are pre-authored strings baked into bank
`$4D`, reached through its 476-entry dispatch table at **entry = species + 5**.

So randomizing FamilyRecipeTable moved the sprites and left the words frozen at
their vanilla values.  This module regenerates those 221 strings.

String format (derived from the ROM, identical shape in both regions):

    <token1 padded to 9 bytes with the region's space byte><token2>$F0

A token is either a FAMILY token or a SPECIES NAME.  The regions spell families
differently -- German writes the word ("Slime", "Materie"), English writes the
family icon byte followed by "family" (`$10 "family"`) -- so both the family
tokens and the pad byte are EXTRACTED from the ROM being patched rather than
hardcoded.  English also pads token2 out to 9; German leaves it short.  Both
conventions are detected, not assumed.

Correctness gate: before writing anything, `reconstruct_check()` rebuilds all 221
vanilla strings from the vanilla tables and compares them byte-for-byte with the
ROM.  If the format were wrong, that check fails and the randomizer refuses to
touch bank $4D rather than emitting a corrupted text bank.
"""

from __future__ import annotations

BANK4D = 0x4D
BANK_BASE = BANK4D * 0x4000
BANK_END = BANK_BASE + 0x4000
DISPATCH_COUNT = 476
RECIPE_ENTRY_OFFSET = 5          # dispatch entry = species + 5
SPECIES_COUNT = 221
TOKEN1_WIDTH = 9
TERMINATOR = 0xF0
FAMILY_CODE_LO = 0xF0

NAME_BANK_BASE = 0x41 * 0x4000
NAME_STRING_LO, NAME_STRING_HI = 0x4E00, 0x7FFF


class LibraryTextError(RuntimeError):
    pass


def _flat(addr: int) -> int:
    return BANK_BASE + (addr - 0x4000)


class LibraryText:
    """Parses, verifies and rewrites the bank $4D recipe strings."""

    def __init__(self, data: bytes, name_table_base: int):
        self.data = data
        self.ptr = [int.from_bytes(data[BANK_BASE + 1 + 2 * i: BANK_BASE + 3 + 2 * i],
                                   "little")
                    for i in range(DISPATCH_COUNT)]
        self.name_base = name_table_base
        self.pad = self._detect_pad()
        self.pad_token2 = self._detect_token2_padding()
        self.family_tokens = self._extract_family_tokens()

    # -- reading -----------------------------------------------------------
    def entry_bytes(self, entry: int) -> bytes:
        o = _flat(self.ptr[entry])
        end = self.data.find(bytes([TERMINATOR]), o, o + 64)
        if end < 0:
            raise LibraryTextError(f"bank $4D entry {entry}: no $F0 terminator")
        return self.data[o:end]

    def recipe_bytes(self, species: int) -> bytes:
        return self.entry_bytes(species + RECIPE_ENTRY_OFFSET)

    def species_name_bytes(self, species: int) -> bytes:
        o = self.name_base + 2 * species
        addr = int.from_bytes(self.data[o:o + 2], "little")
        if not NAME_STRING_LO <= addr <= NAME_STRING_HI:
            raise LibraryTextError(f"species {species}: name pointer {addr:#06x} "
                                   f"outside the string area")
        p = NAME_BANK_BASE + (addr - 0x4000)
        end = self.data.find(b"\xf0", p, p + 20)
        if end < 0:
            raise LibraryTextError(f"species {species}: unterminated name")
        return self.data[p:end]

    # -- format detection --------------------------------------------------
    def _detect_pad(self) -> int:
        """The byte used to pad token1 out to 9. Species 0's family token is
        short in both regions, so byte 8 of its entry is the pad."""
        return self.recipe_bytes(0)[TOKEN1_WIDTH - 1]

    def _detect_token2_padding(self) -> bool:
        """English pads token2 to 9 as well; German does not."""
        row = self.recipe_bytes(0)
        return len(row) == 2 * TOKEN1_WIDTH

    def _extract_family_tokens(self) -> dict[int, bytes]:
        """Pull each family's spelling straight out of the vanilla strings."""
        tokens: dict[int, bytes] = {}
        pairs = self._vanilla_pairs()
        for species, (a, b) in enumerate(pairs):
            if species >= SPECIES_COUNT:
                break
            row = self.recipe_bytes(species)
            if len(row) < TOKEN1_WIDTH:
                continue
            if a >= FAMILY_CODE_LO and (a - FAMILY_CODE_LO) not in tokens:
                tok = row[:TOKEN1_WIDTH].rstrip(bytes([self.pad]))
                if tok:
                    tokens[a - FAMILY_CODE_LO] = tok
            if b >= FAMILY_CODE_LO and (b - FAMILY_CODE_LO) not in tokens:
                tok = row[TOKEN1_WIDTH:].rstrip(bytes([self.pad]))
                if tok:
                    tokens[b - FAMILY_CODE_LO] = tok
        missing = [f for f in range(10) if f not in tokens]
        if missing:
            raise LibraryTextError(
                f"could not extract library text for families {missing}; this ROM "
                f"spells family names differently and is not supported")
        return tokens

    def _vanilla_pairs(self) -> list[tuple[int, int]]:
        from .romdata import FAMILY_RECIPES
        base, count, stride = FAMILY_RECIPES
        return [(self.data[base + i * stride], self.data[base + i * stride + 1])
                for i in range(count)]

    # -- building ----------------------------------------------------------
    def token(self, matcher: int) -> bytes:
        if matcher >= FAMILY_CODE_LO:
            return self.family_tokens[matcher - FAMILY_CODE_LO]
        return self.species_name_bytes(matcher)

    def build(self, a: int, b: int) -> bytes:
        t1 = self.token(a)[:TOKEN1_WIDTH]
        t2 = self.token(b)
        row = t1.ljust(TOKEN1_WIDTH, bytes([self.pad]))
        row += t2.ljust(TOKEN1_WIDTH, bytes([self.pad])) if self.pad_token2 else t2
        return row + bytes([TERMINATOR])

    def reconstruct_check(self) -> tuple[int, list[int]]:
        """Rebuild every vanilla string and diff against the ROM.

        Returns (matched, mismatched_species).  This is the gate that proves the
        format above is right for THIS ROM before anything is written.
        """
        pairs = self._vanilla_pairs()
        ok, bad = 0, []
        for s in range(SPECIES_COUNT):
            a, b = pairs[s]
            if a == 0xFF or (a, b) == (0, 0):
                continue
            want = self.recipe_bytes(s)
            got = self.build(a, b)[:-1]
            if got == want:
                ok += 1
            else:
                bad.append(s)
        return ok, bad


def free_blocks(data: bytes, ptrs: list[int]) -> list[tuple[int, int]]:
    """Space available for the rebuilt strings, as (flat_start, flat_end).

    Block 1 is the old recipe-string region, which we are wholly replacing.
    Block 2 is the unused tail of the bank.  Anything else in bank $4D is left
    alone.
    """
    lo = _flat(ptrs[RECIPE_ENTRY_OFFSET])
    hi = _flat(ptrs[RECIPE_ENTRY_OFFSET + SPECIES_COUNT])
    if hi <= lo:
        raise LibraryTextError("recipe string region has non-positive size")

    # Refuse if any dispatch entry OUTSIDE the recipe range points into block 1.
    for i, p in enumerate(ptrs):
        if RECIPE_ENTRY_OFFSET <= i < RECIPE_ENTRY_OFFSET + SPECIES_COUNT:
            continue
        if lo <= _flat(p) < hi:
            raise LibraryTextError(
                f"dispatch entry {i} points inside the recipe string region; "
                f"refusing to repack")

    tail = BANK_END
    while tail > hi and data[tail - 1] in (0x00, 0xFF):
        tail -= 1
    blocks = [(lo, hi)]
    if BANK_END - tail > 16:
        blocks.append((tail, BANK_END))
    return blocks


def rewrite(rom, pairs: list[tuple[int, int]], name_table_base: int) -> dict:
    """Regenerate all 221 recipe strings in place. Returns a stats dict."""
    lib = LibraryText(bytes(rom.data), name_table_base)
    ok, bad = lib.reconstruct_check()
    total = ok + len(bad)
    # A handful of vanilla strings are hand-authored with typos the tables do not
    # have ("Mistfigur" for Mystfigur, "Whiteking" for WhiteKing, ZapBird's parent
    # spelled "?????"), so an exact 221/221 is not achievable and not required.
    # A high match rate is what proves the format; a low one means this ROM is
    # laid out differently and must not be written.
    if total == 0 or ok < 0.95 * total:
        raise LibraryTextError(
            f"bank $4D format check failed: only {ok} of {total} vanilla strings "
            f"reconstructed (species {bad[:8]}). Refusing to write.")

    rows = {}
    for s in range(SPECIES_COUNT):
        a, b = pairs[s]
        if a == 0xFF or (a, b) == (0, 0):
            rows[s] = lib.recipe_bytes(s) + bytes([TERMINATOR])   # keep as-is
        else:
            rows[s] = lib.build(a, b)

    blocks = free_blocks(bytes(rom.data), lib.ptr)
    need = sum(len(r) for r in rows.values())
    capacity = sum(hi - lo for lo, hi in blocks)
    if need > capacity:
        raise LibraryTextError(
            f"rebuilt library text needs {need} bytes, bank $4D has {capacity}")

    # Blank the region we own, then pack.
    for lo, hi in blocks:
        rom.data[lo:hi] = bytes(hi - lo)

    cursor = iter(blocks)
    lo, hi = next(cursor)
    new_ptr = {}
    for s in range(SPECIES_COUNT):
        blob = rows[s]
        if lo + len(blob) > hi:
            lo, hi = next(cursor)
        new_ptr[s] = 0x4000 + (lo - BANK_BASE)
        rom.data[lo:lo + len(blob)] = blob
        lo += len(blob)

    for s, addr in new_ptr.items():
        i = s + RECIPE_ENTRY_OFFSET
        o = BANK_BASE + 1 + 2 * i
        rom.data[o:o + 2] = addr.to_bytes(2, "little")

    return {"verified": ok, "vanilla_quirks": bad, "bytes_used": need,
            "capacity": capacity,
            "blocks": len(blocks), "pad": lib.pad, "pad_token2": lib.pad_token2,
            "families": {f: bytes(t).hex() for f, t in sorted(lib.family_tokens.items())}}
