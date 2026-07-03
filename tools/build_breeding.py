#!/usr/bin/env python3
"""build_breeding.py — round-trip decoder/encoder for the DWM1 breeding tables.

This is the **keystone (ROADMAP Phase 2B, B1)** for the breeding overhaul. Before
any new recipes can be authored and compiled (B2-B6), we must be able to decode
BOTH vanilla breeding tables and re-emit them BYTE-IDENTICAL. The family table's
positional/separator encoding is subtle (result species == slot index), so this
fidelity guarantee is non-negotiable.

Tables (bank $16, ROM-verified):
  * SPECIAL recipe table  $16:$4B30 — 825 entries x 5 bytes, $FF terminator at $5B4D.
      entry = [p1_match, p2_match, min_plus, result_species, plus_mod]
      p1/p2 match a species ID (0-220) OR a family code ($F0-$F9, $FA="any family").
      Scanned FIRST; first match wins (see BREEDING_SYSTEM.md, bank_016.asm).
  * FAMILY recipe table    $16:$4974 — flat stream of 2-byte pairs, $0000 terminator.
      The result species IS the positional slot index: pair k lives at slot k, and a
      matching [B,C] pair at slot k yields offspring species k. $FFFF pairs are
      separators (advance the slot counter, store no recipe). Total 222 pairs / 444 B.

What this tool does (B1 scope — the keystone, nothing more):
  * decode_special / decode_family : ROM bytes -> structured Python.
  * encode_special / encode_family : structured -> bytes (must round-trip).
  * emit_*_asm                     : structured -> RGBDS `db` text (for B2+ patching);
                                     verified self-consistent by re-parsing in selftest.
  * --selftest  : decode from ROM, re-encode, assert byte-identical to the ROM slices,
                  and assert the ASM emission re-parses to the same bytes. PASS/FAIL.
  * (default)   : run selftest AND (re)generate extracted/breeding_tables.json — the
                  regenerable, round-trip-faithful, name-annotated representation.

It does NOT yet author new recipes, invert author intent into slot order, or emit
patches/ ASM. Those are B2-B6 and live in later sessions / later code paths here.

Usage:
    python3 tools/build_breeding.py --selftest      # prove byte-perfect round-trip
    python3 tools/build_breeding.py                 # selftest + regenerate JSON
    python3 tools/build_breeding.py --check-disasm  # also diff disassembly db bytes
"""
import argparse
import hashlib
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_PATH = os.path.join(REPO, "data", "DWM-original.gbc")
DISASM = os.path.join(REPO, "disassembly", "bank_016.asm")
MONSTERS = os.path.join(REPO, "extracted", "monsters_full.json")
OUT_JSON = os.path.join(REPO, "extracted", "breeding_tables.json")
EXTRA_RECIPES = os.path.join(REPO, "extracted", "breeding_extra_recipes.json")
FAMILY_DEFAULTS = os.path.join(REPO, "extracted", "breeding_family_defaults.json")
SPECIAL_SPEC = os.path.join(REPO, "extracted", "breeding_special.json")
NEW_SPECIES_SPEC = os.path.join(REPO, "extracted", "new_species.json")
PATCH_BANK16 = os.path.join(REPO, "patches", "bank_016.asm")
ORIGINAL_MD5 = "1ca6579359f21d8e27b446f865bf6b83"

# --- ROM geometry (bank $16) -------------------------------------------------
BANK = 0x16
SPECIAL_ADDR = 0x4B30          # bank-relative
FAMILY_ADDR = 0x4974           # bank-relative
SPECIAL_COUNT = 825            # VANILLA base count (decode/round-trip; never changes)
SPECIAL_ENTRY = 5

# --- B3: special-table capacity extension (bank $69) -------------------------
# The relocated bank $69 table (B2) can grow past the 825 vanilla entries because
# its scanner walks to the $FF terminator with no hardcoded count. B3 appends the
# recipes in EXTRA_RECIPES after the base entries. The spec target is 1x-2x the
# vanilla size; bank $69 (16 KB) easily holds 1650*5 = 8250 B + scanner.
SPECIAL_CAPACITY_MAX = 1650    # 2x vanilla; spec ceiling for the appended table
# Bytes available in bank $69 for (scanner + table). Bank is $4000..$7FFF.
# db $69 (1) + jump table dw (2) + scanner code; the table follows. We assert the
# whole emitted bank fits with margin rather than hardcoding the scanner length.
BANK69_SIZE = 0x4000
SPECIAL_TERMINATOR = 0xFF      # single byte at $5B4D
FAMILY_TERMINATOR = (0x00, 0x00)   # terminating pair
SEPARATOR = (0xFF, 0xFF)           # advances slot, stores no recipe

FAMILY_CODES = {
    0xF0: "Slime", 0xF1: "Dragon", 0xF2: "Beast", 0xF3: "Flying", 0xF4: "Plant",
    0xF5: "Bug", 0xF6: "Devil", 0xF7: "Zombie", 0xF8: "Material", 0xF9: "Boss",
    0xFA: "AnyFamily",  # wildcard (preserved by the two-pass family search)
}


def file_off(addr):
    """bank-relative $4xxx -> absolute file offset."""
    return BANK * 0x4000 + (addr - 0x4000)


def load_rom():
    with open(ROM_PATH, "rb") as f:
        return f.read()


def load_monster_names():
    try:
        data = json.load(open(MONSTERS))
        return {m["id"]: m["name"] for m in data}
    except Exception:
        return {}


def load_new_species():
    """Read extracted/new_species.json -> {id: name} for the ADD-NEW-species
    entries (Phase N, ids >= 221). These ids are valid breeding RESULTS even
    though they are above the vanilla 0-220 range: each is a real species whose
    info/enemy-stats/etc. are authored by build_new_species.py. Missing file or
    no entries -> {} (the tool then only allows vanilla 0-220 results).

    Only ids that are genuinely declared here are admitted, so a phantom id in
    the 220-223 dead range can never slip through as a recipe result."""
    try:
        spec = json.load(open(NEW_SPECIES_SPEC))
    except Exception:
        return {}
    out = {}
    for s in spec.get("species", []):
        sid = s.get("id")
        if isinstance(sid, int):
            out[sid] = s.get("name", "newspecies_$%02X" % sid)
    return out


def species_name(code, names):
    """Annotate a matcher/result byte with a human label."""
    if code in FAMILY_CODES:
        return "[%s]" % FAMILY_CODES[code]
    return names.get(code, "species_$%02X" % code)


# --- SPECIAL table -----------------------------------------------------------
def decode_special(rom):
    off = file_off(SPECIAL_ADDR)
    entries = []
    for i in range(SPECIAL_COUNT):
        b = rom[off + i * SPECIAL_ENTRY: off + (i + 1) * SPECIAL_ENTRY]
        entries.append(list(b))
    term = rom[off + SPECIAL_COUNT * SPECIAL_ENTRY]
    if term != SPECIAL_TERMINATOR:
        raise ValueError("special terminator at $%04X is $%02X, expected $FF"
                         % (SPECIAL_ADDR + SPECIAL_COUNT * SPECIAL_ENTRY, term))
    return entries


def encode_special(entries):
    """Structured -> raw bytes, INCLUDING the trailing $FF terminator."""
    if len(entries) != SPECIAL_COUNT:
        raise ValueError("special must have %d entries, got %d"
                         % (SPECIAL_COUNT, len(entries)))
    out = bytearray()
    for e in entries:
        if len(e) != SPECIAL_ENTRY:
            raise ValueError("special entry must be %d bytes: %r" % (SPECIAL_ENTRY, e))
        out.extend(e)
    out.append(SPECIAL_TERMINATOR)
    return bytes(out)


# --- FAMILY table ------------------------------------------------------------
def decode_family(rom):
    """Decode the positional pair stream from $4974 up to and including $0000."""
    start = file_off(FAMILY_ADDR)
    end = file_off(SPECIAL_ADDR)          # family table runs right up to special
    raw = rom[start:end]
    if len(raw) % 2 != 0:
        raise ValueError("family table length %d is not even" % len(raw))
    pairs = []
    for slot in range(len(raw) // 2):
        b, c = raw[slot * 2], raw[slot * 2 + 1]
        if (b, c) == FAMILY_TERMINATOR:
            kind = "terminator"
        elif (b, c) == SEPARATOR:
            kind = "separator"
        else:
            kind = "recipe"
        pairs.append({"slot": slot, "b": b, "c": c, "kind": kind})
    # sanity: exactly one terminator, and it is the last pair
    if pairs[-1]["kind"] != "terminator":
        raise ValueError("family table does not end with $0000 terminator")
    if sum(1 for p in pairs if p["kind"] == "terminator") != 1:
        raise ValueError("family table has more than one $0000 terminator")
    return pairs


def encode_family(pairs):
    """Structured -> raw bytes (the full 444-byte stream including terminator)."""
    out = bytearray()
    for p in pairs:
        out.append(p["b"])
        out.append(p["c"])
    return bytes(out)


# --- ASM emission (for B2+; verified self-consistent here) -------------------
def _emit_db(values, per_line=16):
    lines = []
    for i in range(0, len(values), per_line):
        chunk = values[i:i + per_line]
        lines.append("    db " + ", ".join("$%02x" % v for v in chunk))
    return "\n".join(lines)


def emit_special_asm(entries):
    body = encode_special(entries)   # bytes incl terminator
    return "SpecialRecipeTable:\n" + _emit_db(body)


def emit_family_asm(pairs):
    body = encode_family(pairs)
    return "FamilyRecipeTable:\n" + _emit_db(body)


_DB_TOKEN = re.compile(r"\$[0-9a-fA-F]{2}")


def parse_db_bytes(asm_text):
    """Parse every `$xx` token from `db` lines into a byte list."""
    out = []
    for line in asm_text.splitlines():
        if "db " in line:
            out.extend(int(t[1:], 16) for t in _DB_TOKEN.findall(line))
    return out


# --- disassembly cross-check -------------------------------------------------
def disasm_table_bytes(label, count):
    """Pull `count` bytes of db tokens starting just after `label:` in bank_016.asm."""
    with open(DISASM) as f:
        lines = f.readlines()
    start = None
    for i, ln in enumerate(lines):
        if ln.strip().startswith(label + ":"):
            start = i + 1
            break
    if start is None:
        raise ValueError("label %s not found in %s" % (label, DISASM))
    out = []
    for ln in lines[start:]:
        if "db " not in ln:
            # allow blank/comment lines inside the table; stop at next label
            if re.match(r"^[A-Za-z_.][\w.]*:", ln):
                break
            continue
        out.extend(int(t[1:], 16) for t in _DB_TOKEN.findall(ln))
        if len(out) >= count:
            break
    return out[:count]


# --- selftest ----------------------------------------------------------------
def selftest(rom, check_disasm=False, verbose=True):
    ok = True

    def say(msg):
        if verbose:
            print(msg)

    # ROM ground-truth slices
    spec_off = file_off(SPECIAL_ADDR)
    spec_len = SPECIAL_COUNT * SPECIAL_ENTRY + 1      # + terminator
    rom_special = rom[spec_off: spec_off + spec_len]
    fam_off = file_off(FAMILY_ADDR)
    rom_family = rom[fam_off: spec_off]

    # 1) SPECIAL round-trip
    entries = decode_special(rom)
    re_special = encode_special(entries)
    if re_special == rom_special:
        say("  [special] decode->encode == ROM ($4B30, %d B incl $FF): OK"
            % len(re_special))
    else:
        ok = False
        say("  [special] MISMATCH: re-encoded != ROM slice")

    # 2) FAMILY round-trip
    pairs = decode_family(rom)
    re_family = encode_family(pairs)
    if re_family == rom_family:
        say("  [family ] decode->encode == ROM ($4974, %d B): OK" % len(re_family))
    else:
        ok = False
        say("  [family ] MISMATCH: re-encoded != ROM slice")

    # 3) ASM emission self-consistency (bytes <-> db text)
    if parse_db_bytes(emit_special_asm(entries)) == list(rom_special):
        say("  [special] ASM emit re-parses to ROM bytes: OK")
    else:
        ok = False
        say("  [special] ASM emit re-parse MISMATCH")
    if parse_db_bytes(emit_family_asm(pairs)) == list(rom_family):
        say("  [family ] ASM emit re-parses to ROM bytes: OK")
    else:
        ok = False
        say("  [family ] ASM emit re-parse MISMATCH")

    # 4) optional: disassembly db bytes == ROM
    if check_disasm:
        ds = disasm_table_bytes("SpecialRecipeTable", spec_len)
        df = disasm_table_bytes("FamilyRecipeTable", len(rom_family))
        if ds == list(rom_special):
            say("  [special] disassembly db == ROM: OK")
        else:
            ok = False
            say("  [special] disassembly db != ROM")
        if df == list(rom_family):
            say("  [family ] disassembly db == ROM: OK")
        else:
            ok = False
            say("  [family ] disassembly db != ROM")

    return ok


# --- JSON regeneration -------------------------------------------------------
def build_json(rom):
    names = load_monster_names()
    entries = decode_special(rom)
    pairs = decode_family(rom)

    special = []
    for i, e in enumerate(entries):
        p1, p2, min_plus, result, plus_mod = e
        special.append({
            "index": i,
            "p1": p1, "p2": p2, "min_plus": min_plus,
            "result": result, "plus_mod": plus_mod,
            "p1_name": species_name(p1, names),
            "p2_name": species_name(p2, names),
            "result_name": species_name(result, names),
        })

    family = []
    for p in pairs:
        rec = {"slot": p["slot"], "b": p["b"], "c": p["c"], "kind": p["kind"]}
        if p["kind"] == "recipe":
            rec["b_name"] = species_name(p["b"], names)
            rec["c_name"] = species_name(p["c"], names)
            rec["result"] = p["slot"]
            rec["result_name"] = species_name(p["slot"], names)
        family.append(rec)

    n_recipes = sum(1 for p in pairs if p["kind"] == "recipe")
    n_sep = sum(1 for p in pairs if p["kind"] == "separator")

    return {
        "_generator": "tools/build_breeding.py",
        "_rom_source": "data/DWM-original.gbc",
        "_rom_md5": hashlib.md5(rom).hexdigest(),
        "_note": ("Round-trip-faithful decode of both vanilla breeding tables. "
                  "Re-emitting via build_breeding.py is byte-identical to ROM "
                  "(see --selftest). Family result species == positional slot index."),
        "special_table": {
            "base_addr": "$16:$%04X" % SPECIAL_ADDR,
            "entry_count": SPECIAL_COUNT,
            "entry_size": SPECIAL_ENTRY,
            "terminator": "$%02X" % SPECIAL_TERMINATOR,
            "format": ["p1", "p2", "min_plus", "result", "plus_mod"],
            "entries": special,
        },
        "family_table": {
            "base_addr": "$16:$%04X" % FAMILY_ADDR,
            "pair_count": len(pairs),
            "recipe_count": n_recipes,
            "separator_count": n_sep,
            "terminator": "$%02X%02X" % FAMILY_TERMINATOR,
            "encoding": "positional: result species == slot index; $FFFF separator advances slot",
            "slots": family,
        },
    }


# --- B3: appended special recipes (capacity extension) -----------------------
def load_extra_recipes():
    """Load hand-authored recipes to APPEND after the 825 base entries (B3).

    Returns a list of 5-byte [p1,p2,min_plus,result,plus_mod] entries (ints).
    Missing file -> [] (tool still emits the base table, i.e. behaves like B2).
    Underscore-prefixed keys in the JSON are comments and are ignored."""
    if not os.path.exists(EXTRA_RECIPES):
        return []
    spec = json.load(open(EXTRA_RECIPES))
    out = []
    for r in spec.get("recipes", []):
        entry = [int(r["p1"]), int(r["p2"]), int(r["min_plus"]),
                 int(r["result"]), int(r["plus_mod"])]
        for b in entry:
            if not (0 <= b <= 0xFF):
                raise ValueError("extra recipe byte out of range 0-255: %r" % (entry,))
        # p1/p2 may be a species id (0-220) or a family code ($F0-$FA); result
        # must be a real species id (0-220) since it is written to $DA71.
        if not (0 <= entry[3] <= 220):
            raise ValueError("extra recipe result must be a species id 0-220: $%02X"
                             % entry[3])
        out.append(entry)
    return out


def first_match_index(rom, entries, p1, p2):
    """Index of the first base entry that would match a (p1_species,p2_species)
    cross regardless of plus, or None. Used to warn when an appended recipe is
    SHADOWED (an earlier entry matches the same parents and wins first), which
    would make the appended recipe dead. Family-code matching is approximated by
    the parents' family bytes from the monster info table."""
    f1, f2 = species_family_code(rom, p1), species_family_code(rom, p2)
    for i, e in enumerate(entries):
        if e[0] in (p1, f1) and e[1] in (p2, f2):
            return i
    return None


def species_family_code(rom, sp):
    """Family code ($F0-$F9) for a species id, read from monster info table
    $03:$4461 (byte 0 = family 0-9). Returns None for codes (>=$F0) or OOB."""
    if sp is None or sp >= 0xF0 or sp > 220:
        return None
    off = 0x03 * 0x4000 + (0x4461 - 0x4000) + sp * 43
    fam = rom[off]
    return 0xF0 + fam if fam <= 9 else None


# --- B4: family-defaults authoring (in-place rewrite of $16:$4974) -----------
# The family recipe table is POSITIONAL: offspring species == slot index. An
# override is keyed by `result` (the offspring species) and supplies the parent
# matchers written at that slot. We start from the VANILLA ROM decode and apply
# only the overrides, so the emitted table differs from vanilla at exactly the
# overridden slots and stays 222 pairs / 444 bytes (zero shift -> bank $16's
# downstream embedded pointers never move).

# Family NAME -> code. "Bird" and "Flying" are both $F3 (FamilyTextPtrTable names
# the family "Bird"; monsters_full.json labels those species "Flying").
_FAMILY_NAME_TO_CODE = {
    "slime": 0xF0, "dragon": 0xF1, "beast": 0xF2, "bird": 0xF3, "flying": 0xF3,
    "plant": 0xF4, "bug": 0xF5, "devil": 0xF6, "zombie": 0xF7, "material": 0xF8,
    "boss": 0xF9, "anyfamily": 0xFA, "any": 0xFA,
}


def _name_to_id(names):
    """Reverse of the id->name map (lowercased) for resolving species by name."""
    return {v.lower(): k for k, v in names.items()}


def resolve_matcher(token, names, *, mate_side):
    """Resolve a p1/p2 matcher token to a byte.

    token may be: an int (species id 0-220, or a raw code $F0-$FA), a family
    name (Slime/Dragon/.../Boss, Flying=Bird), '$FA'/'AnyFamily', or a species
    name. $FA (AnyFamily wildcard) is only meaningful on the mate side (parent 2)
    per the scanner; reject it on the pedigree side."""
    if isinstance(token, int):
        b = token
    else:
        s = str(token).strip()
        key = s.lower()
        if key in _FAMILY_NAME_TO_CODE:
            b = _FAMILY_NAME_TO_CODE[key]
        elif s.startswith("$"):
            b = int(s[1:], 16)
        elif key in _name_to_id(names):
            b = _name_to_id(names)[key]
        else:
            raise ValueError("cannot resolve breeding matcher %r (not a family "
                             "name, species name, id, or $hex code)" % (token,))
    if not (0 <= b <= 0xFF):
        raise ValueError("matcher byte out of range: %r -> $%X" % (token, b))
    if b == 0xFA and not mate_side:
        raise ValueError("AnyFamily ($FA) wildcard is mate-side (parent 2) only")
    if b > 0xFA:
        raise ValueError("matcher $%02X is above the family-code range" % b)
    return b


def load_family_overrides(names):
    """Load hand-authored family-default overrides (B4).

    Returns a list of {result:int, b:int, c:int}. Missing file -> [] (the tool
    then re-emits the vanilla family table unchanged). Underscore keys ignored."""
    if not os.path.exists(FAMILY_DEFAULTS):
        return []
    spec = json.load(open(FAMILY_DEFAULTS))
    out = []
    for o in spec.get("overrides", []):
        result = o["result"]
        if isinstance(result, str):           # allow a species name for `result`
            key = result.strip().lower()
            nid = _name_to_id(names)
            if key not in nid:
                raise ValueError("override result %r is not a known species" % result)
            result = nid[key]
        result = int(result)
        if not (0 <= result <= 220):
            raise ValueError("override result must be species id 0-220 (the "
                             "$0000 terminator slot is reserved): %r" % result)
        b = resolve_matcher(o["p1"], names, mate_side=False)
        c = resolve_matcher(o["p2"], names, mate_side=True)
        out.append({"result": result, "b": b, "c": c})
    return out


def apply_family_overrides(pairs, overrides):
    """Apply overrides to a decoded vanilla family pair list (in place by slot).

    pairs is the list returned by decode_family (slots 0..N with one terminator).
    Each override sets pairs[result] = its matcher. Validates positional 1:1
    (no two overrides share a result) and that the target slot is not the
    terminator. Returns the modified pairs and asserts the length is invariant."""
    seen = {}
    for o in overrides:
        r = o["result"]
        if r in seen:
            raise ValueError("positional conflict: result species %d is claimed "
                             "by two overrides (the family table is strictly 1:1; "
                             "move one cross to the SPECIAL table)" % r)
        seen[r] = o
        if r >= len(pairs):
            raise ValueError("override result %d is past the family table" % r)
        if pairs[r]["kind"] == "terminator":
            raise ValueError("override result %d targets the $0000 terminator" % r)
        pairs[r]["b"] = o["b"]
        pairs[r]["c"] = o["c"]
        pairs[r]["kind"] = "recipe"
    return pairs


def family_shadow_warnings(rom, pairs, overrides, names):
    """Warn when an authored family cross will not surface in-game.

    Two shadow classes: (1) a SPECIAL-table entry matches the same parents by
    family code and wins (special is checked before family); (2) another FAMILY
    recipe carries the identical [b,c] family-code pair (last family match wins,
    so a duplicate at a higher slot would out-rank a lower one). Species-specific
    shadowing depends on the player's exact monsters and is left to play-test."""
    warn = []
    sp = decode_special(rom)
    for o in overrides:
        b, c, r = o["b"], o["c"], o["result"]
        rn = species_name(r, names)
        # (1) special-table family-code shadow
        for i, e in enumerate(sp):
            if e[0] == b and e[1] == c:
                warn.append("family cross [%s x %s -> %s] is SHADOWED by SPECIAL "
                            "entry %d (-> %s); the family default will not fire"
                            % (species_name(b, names), species_name(c, names),
                               rn, i, species_name(e[3], names)))
                break
        # (2) duplicate family-code matcher at another (higher) slot
        if 0xF0 <= b <= 0xFA and 0xF0 <= c <= 0xFA:
            dups = [p["slot"] for p in pairs
                    if p["kind"] == "recipe" and p["slot"] != r
                    and p["b"] == b and p["c"] == c]
            higher = [s for s in dups if s > r]
            if higher:
                warn.append("family cross -> %s at slot %d is out-ranked by an "
                            "identical matcher at slot(s) %s (last family match "
                            "wins)" % (rn, r, higher))
    return warn


def emit_family_db_block(pairs):
    """The db lines for the family table body (no label), 16 bytes/line."""
    return _emit_db(list(encode_family(pairs)))


def build_family_pairs(rom):
    """Vanilla family decode + B4 overrides applied. Returns (pairs, overrides,
    warnings)."""
    names = load_monster_names()
    pairs = decode_family(rom)
    overrides = load_family_overrides(names)
    apply_family_overrides(pairs, overrides)
    warnings = family_shadow_warnings(rom, pairs, overrides, names)
    body = encode_family(pairs)
    if len(body) != 444:
        raise ValueError("family table is %d bytes, expected 444 (zero-shift "
                         "invariant violated)" % len(body))
    return pairs, overrides, warnings


def write_family_table(rom):
    """Rewrite the FamilyRecipeTable db block in patches/bank_016.asm in place.

    Replaces only the bytes BETWEEN the `FamilyRecipeTable:` label and the next
    label (`SpecialRecipeTable:`); the special table and everything else are
    untouched."""
    pairs, overrides, warnings = build_family_pairs(rom)
    with open(PATCH_BANK16) as f:
        text = f.read()
    m = re.search(r"(FamilyRecipeTable:\n)(.*?)(\n[A-Za-z_][A-Za-z0-9_]*:)",
                  text, re.S)
    if not m:
        raise ValueError("FamilyRecipeTable block not found in patches/bank_016.asm")
    new_block = emit_family_db_block(pairs)
    new_text = text[:m.start(2)] + new_block + text[m.end(2):]
    with open(PATCH_BANK16, "w") as f:
        f.write(new_text)
    return overrides, warnings


# --- B2: relocation harness (bank $69 special-table scanner) -----------------
# The special table can't grow in place (code follows its $FF terminator at
# $5B4D) and bank $16 is shift-sensitive (embedded pointers at $70A6+). B2
# relocates the SPECIAL-table scan to free bank $69 and calls it via `rst $10`
# (H=$69, L=0 -> jump-table entry 0). The scanner below is a faithful,
# instruction-level port of bank $16's in-bank scan (jr_016_46f5) + per-entry
# check (LoadBrd_471c at $471C). It reads the same RAM ($DA6F/$DA70/$DA73/$DA74
# /$DA77), writes the same RAM ($DA71 result, $DA77 += plus_mod), and ends with
# `ret` so control returns to bank $16's plus-clamp at $4710. Vanilla behaviour
# is preserved exactly (regression); the relocated table is byte-identical to
# the vanilla special table (emitted via encode_special).
BANK69_SCANNER_ASM = """\
SECTION "ROM Bank $069", ROMX[$4000], BANK[$69]
    db $69                        ; bank self-ID at $4000

; Jump table at $4001 (rst $10 with HL=$6900 dispatches entry 0)
    dw RelocatedSpecialScan

; -----------------------------------------------------------------------------
; RelocatedSpecialScan (B2) — faithful port of bank $16 special-table scan.
; Called via `ld hl,$6900; rst $10` from bank $16 (LoadBrd_4653, in place of the
; old in-bank scan at $46F2-$470F). Plus value + parent family codes are already
; computed in bank $16 RAM before the call. On return, bank $16 clamps $DA77.
; Inputs  (RAM): $DA6F p1 species, $DA70 p2 species, $DA73 p1 family,
;                $DA74 p2 family, $DA77 offspring plus.
; Outputs (RAM): $DA71 result species (untouched if no match), $DA77 += plus_mod.
; -----------------------------------------------------------------------------
RelocatedSpecialScan:
    ld hl, RelocatedSpecialTable      ; relocated table: 825 base + appended (B3); scan to $FF
.scan:
    ld a, [hl]
    cp $ff                            ; $FF = end of table
    jr z, .done
    push hl
    call .checkentry                  ; port of LoadBrd_471c
    pop hl
    ld a, [$da71]
    cp $ff
    jr nz, .done                      ; match found -> stop
    ld a, l
    add $05                           ; advance to next 5-byte entry
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr .scan
.done:
    ret                               ; back to bank $16 plus-clamp ($4710)

; Port of LoadBrd_471c ($471C): match one 5-byte entry against the parents.
.checkentry:
    ld a, [$da6f]                     ; parent 1 species (specific)
    cp [hl]
    jr z, .e2
    ld a, [$da73]                     ; parent 1 family code
    cp [hl]
    jr nz, .edone
.e2:
    inc hl
    ld a, [$da70]                     ; parent 2 species (specific)
    cp [hl]
    jr z, .e3
    ld a, [$da74]                     ; parent 2 family code
    cp [hl]
    jr nz, .edone
.e3:
    inc hl
    ld a, [$da77]                     ; offspring plus value
    cp [hl]
    jr c, .edone                      ; plus < threshold -> skip
    inc hl
    ld a, [hl]                        ; result species ID
    ld [$da71], a
    inc hl
    ld a, [$da77]
    add [hl]                          ; add plus modifier
    ld [$da77], a
.edone:
    ret

RelocatedSpecialTable:
"""


# --- B5: full special-table authoring (ROADMAP Phase 2B) ---------------------
# B5 makes build_breeding.py the SOLE OWNER of the whole special recipe table as
# authored data. The base is the 825 vanilla entries decoded from the ROM (the
# canonical source); authored OVERRIDES edit any base entry in place (addressed
# by index OR by parents), and authored APPENDS add new entries past index 824
# (the B3 capacity mechanism). The result is emitted only to bank $69 (B2/B3
# relocation); bank $16's vanilla special table stays byte-identical to the ROM
# forever (it is already runtime-dead — B2 redirects the scan via `rst $10`), so
# there is a SINGLE source of truth (the JSON) and a single emit target. This is
# the precedence-aware machinery the editor will sit on; the actual recipe
# content is authored later in the editor UI.
#
# Spec file: extracted/breeding_special.json
#   { "base": "rom",                       # always the vanilla ROM 825 entries
#     "overrides": [ {index|match, ...} ], # edit a base entry in place
#     "appends":   [ {p1,p2,...} ] }       # new entries (B3), first-match-wins
#
# Override addressing:
#   {"index": N, "result": ..., ...}                 # edit base entry N
#   {"match": {"p1":..., "p2":...}, "result": ...}   # edit the FIRST base entry
#                                                    # that matches those parents
# Any of p1/p2/min_plus/result/plus_mod present in an override replaces that
# field; absent fields keep the base entry's value. Appends require all five.
SPECIAL_FIELDS = ("p1", "p2", "min_plus", "result", "plus_mod")


def _resolve_recipe_fields(spec, names, *, require_all, base=None,
                           extra_result_ids=frozenset()):
    """Resolve a JSON recipe dict to a 5-byte entry [p1,p2,min_plus,result,
    plus_mod]. p1/p2 go through resolve_matcher (names/family/$hex/id). result
    must resolve to a real species id 0-220 OR a declared NEW species id (>=221,
    passed in `extra_result_ids` from new_species.json) — it is written to
    $DA71. min_plus and plus_mod are raw 0-255. When `base` is given (override
    case), absent fields inherit from it; when require_all is True (append
    case), all five fields must be present."""
    out = list(base) if base is not None else [None] * 5

    def has(k):
        return k in spec and spec[k] is not None

    if has("p1"):
        out[0] = resolve_matcher(spec["p1"], names, mate_side=False)
    if has("p2"):
        out[1] = resolve_matcher(spec["p2"], names, mate_side=True)
    if has("min_plus"):
        out[2] = int(spec["min_plus"])
    if has("result"):
        r = spec["result"]
        if isinstance(r, str):
            key = r.strip().lower()
            nid = _name_to_id(names)
            if key not in nid:
                raise ValueError("recipe result %r is not a known species" % r)
            r = nid[key]
        out[3] = int(r)
    if has("plus_mod"):
        out[4] = int(spec["plus_mod"])

    if require_all and any(v is None for v in out):
        missing = [f for f, v in zip(SPECIAL_FIELDS, out) if v is None]
        raise ValueError("append recipe is missing field(s) %s: %r"
                         % (missing, spec))
    for i, v in enumerate(out):
        if v is None:
            continue
        if not (0 <= v <= 0xFF):
            raise ValueError("recipe byte %s out of range 0-255: %r"
                             % (SPECIAL_FIELDS[i], spec))
    # result must be a concrete species id, never a family code. Vanilla ids are
    # 0-220; a NEW species (Phase N, id>=221) is also valid IFF it is declared in
    # new_species.json (passed in extra_result_ids), so a phantom dead-range id
    # (220-223 with no authored data) still can't be used as a result.
    if out[3] is not None and not (0 <= out[3] <= 220
                                   or out[3] in extra_result_ids):
        hint = ("" if out[3] <= 220 else
                " (new-species ids must be declared in new_species.json)")
        raise ValueError("recipe result must be a species id 0-220 or a declared "
                         "new species (got $%02X)%s: %r"
                         % (out[3], hint, spec))
    return out


def _entry_matches(entry, p1, p2, f1, f2):
    """True if a 5-byte special `entry` would match a cross with pedigree
    species p1 (family code f1) and mate species p2 (family code f2), ignoring
    the plus threshold. Mirrors the scanner: byte0 ∈ {p1, f1}, byte1 ∈ {p2, f2};
    the mate-side $FA wildcard matches any family-coded mate."""
    b0, b1 = entry[0], entry[1]
    m0 = b0 == p1 or (f1 is not None and b0 == f1)
    m1 = b1 == p2 or (f2 is not None and b1 == f2) or (b1 == 0xFA and f2 is not None)
    return m0 and m1


def _first_match_in(entries, p1, p2, f1, f2, *, upto=None):
    """Index of the first entry (optionally only the first `upto` entries) that
    matches the cross, or None."""
    end = len(entries) if upto is None else upto
    for i in range(end):
        if _entry_matches(entries[i], p1, p2, f1, f2):
            return i
    return None


def load_special_spec(rom, names):
    """Load extracted/breeding_special.json and produce the full authored entry
    list plus structured override/append records for reporting.

    Returns (entries, overrides, appends) where:
      * entries  = list of 5-byte lists (base 825 with overrides applied, then
                   appends, NO terminator) — ready for emission.
      * overrides = [{index, before, after, label}]
      * appends   = [{entry, label}]
    Missing file -> the spec is treated as the pure ROM base with no edits, so
    --emit-special is a faithful no-op equivalent to the relocated vanilla table.
    """
    base_entries = decode_special(rom)            # 825 vanilla 5-byte lists
    entries = [list(e) for e in base_entries]

    # NEW species (Phase N, id>=221) are valid breeding results. Merge their
    # names so report labels read "Gorbunok" not "species_$E0", and collect
    # their ids so _resolve_recipe_fields admits them as results.
    new_species = load_new_species()
    for sid, nm in new_species.items():
        names.setdefault(sid, nm)
    new_ids = frozenset(new_species)

    spec = {}
    if os.path.exists(SPECIAL_SPEC):
        spec = json.load(open(SPECIAL_SPEC))

    base_mode = spec.get("base", "rom")
    if base_mode != "rom":
        raise ValueError("breeding_special.json: base must be \"rom\" (the "
                         "authored base is always the vanilla ROM 825 entries); "
                         "got %r" % base_mode)

    # --- overrides: edit a base entry in place -------------------------------
    overrides = []
    seen_idx = {}
    for o in spec.get("overrides", []):
        if "index" in o and o["index"] is not None:
            idx = int(o["index"])
            if not (0 <= idx < SPECIAL_COUNT):
                raise ValueError("override index %d out of range 0-%d"
                                 % (idx, SPECIAL_COUNT - 1))
        elif "match" in o and o["match"]:
            mp = o["match"]
            p1 = resolve_matcher(mp["p1"], names, mate_side=False)
            p2 = resolve_matcher(mp["p2"], names, mate_side=True)
            f1 = species_family_code(rom, p1)
            f2 = species_family_code(rom, p2)
            idx = _first_match_in(entries, p1, p2, f1, f2)
            if idx is None:
                raise ValueError("override match %r resolves to no base entry "
                                 "(no special currently fires for that cross — "
                                 "use an append instead)" % (mp,))
        else:
            raise ValueError("override must have either \"index\" or \"match\": %r" % o)
        if idx in seen_idx:
            raise ValueError("two overrides target base entry %d "
                             "(the second would clobber the first): %r and %r"
                             % (idx, seen_idx[idx], o))
        seen_idx[idx] = o
        before = list(entries[idx])
        after = _resolve_recipe_fields(o, names, require_all=False, base=before,
                                        extra_result_ids=new_ids)
        entries[idx] = after
        overrides.append({
            "index": idx, "before": before, "after": after,
            "label": "%s x %s -> %s (was %s)" % (
                species_name(after[0], names), species_name(after[1], names),
                species_name(after[3], names), species_name(before[3], names)),
        })

    # --- appends: new entries past index 824 (B3 mechanism) -----------------
    appends = []
    for a in spec.get("appends", []):
        entry = _resolve_recipe_fields(a, names, require_all=True,
                                       extra_result_ids=new_ids)
        appends.append({
            "entry": entry,
            "label": "%s x %s -> %s" % (
                species_name(entry[0], names), species_name(entry[1], names),
                species_name(entry[3], names)),
        })

    full = entries + [a["entry"] for a in appends]
    return full, overrides, appends


def special_shadow_report(rom, full, overrides, appends, names):
    """Whole-table first-match-wins precedence analysis (the editor's live
    validator). Returns (errors, warnings).

    ERRORS (build-failing):
      * an APPEND is shadowed by an earlier entry matching the same parents
        (species-level) — the appended recipe is dead.
      * an OVERRIDE entry is itself shadowed by an earlier entry (its edit can
        never surface for that cross).
    WARNINGS (informational):
      * an OVERRIDE or APPEND newly SHADOWS a later entry that produces a
        different result (collateral: that later cross now resolves earlier).
      * for an override that CHANGES a result species R away from its old value,
        list any OTHER surviving entries that still produce R (so "edited this
        cross" is not mistaken for "removed R from the game").
    Species-level checks use each matcher's concrete species when it is a real
    id, and the parents' family bytes when it is a family code; this mirrors the
    scanner closely enough to catch real shadows without simulating every
    possible parent pair.
    """
    errors, warnings = [], []

    def fam_of(code):
        # For a matcher that is itself a family code, the "family" is the code;
        # for a species id, look up its family byte.
        if 0xF0 <= code <= 0xFA:
            return code
        return species_family_code(rom, code)

    # APPEND shadow check (errors): does any earlier entry match these parents?
    base_len = len(full) - len(appends)
    for k, a in enumerate(appends):
        e = a["entry"]
        p1, p2 = e[0], e[1]
        f1, f2 = fam_of(p1), fam_of(p2)
        hit = _first_match_in(full, p1, p2, f1, f2, upto=base_len + k)
        if hit is not None and hit < base_len + k:
            errors.append("append [%s] is SHADOWED by entry %d [%s -> %s] and "
                          "will never fire"
                          % (a["label"], hit,
                             "%s x %s" % (species_name(full[hit][0], names),
                                          species_name(full[hit][1], names)),
                             species_name(full[hit][3], names)))

    # OVERRIDE shadow check (errors) + collateral / residual-result (warnings)
    for o in overrides:
        idx = o["index"]
        e = o["after"]
        p1, p2 = e[0], e[1]
        f1, f2 = fam_of(p1), fam_of(p2)
        earlier = _first_match_in(full, p1, p2, f1, f2, upto=idx)
        if earlier is not None:
            errors.append("override at entry %d [%s] is SHADOWED by earlier "
                          "entry %d [%s -> %s]; its edit cannot surface"
                          % (idx, o["label"], earlier,
                             "%s x %s" % (species_name(full[earlier][0], names),
                                          species_name(full[earlier][1], names)),
                             species_name(full[earlier][3], names)))
        # collateral: does this entry now shadow a later DIFFERENT-result entry
        # for the same parents?
        later = _first_match_in(full[idx + 1:], p1, p2, f1, f2)
        if later is not None:
            j = idx + 1 + later
            if full[j][3] != e[3]:
                warnings.append("override at entry %d now precedes entry %d "
                                "[%s -> %s] for the same parents (that cross "
                                "resolved later before)"
                                % (idx, j,
                                   "%s x %s" % (species_name(full[j][0], names),
                                                species_name(full[j][1], names)),
                                   species_name(full[j][3], names)))
        # residual result: if the override changed the RESULT species, list the
        # other surviving entries that still produce the OLD result.
        old_r = o["before"][3]
        if old_r != e[3]:
            residual = [i for i, x in enumerate(full)
                        if i != idx and x[3] == old_r]
            if residual:
                warnings.append("entry %d no longer yields %s, but %d other "
                                "entr%s still do (e.g. %s); editing one cross "
                                "does not remove %s from breeding"
                                % (idx, species_name(old_r, names), len(residual),
                                   "y" if len(residual) == 1 else "ies",
                                   ", ".join("#%d" % i for i in residual[:6])
                                   + ("…" if len(residual) > 6 else ""),
                                   species_name(old_r, names)))
    return errors, warnings


def build_authored_special(rom):
    """Full authored special table (bytes, no terminator) + structured records.
    Returns (full_entries, overrides, appends, errors, warnings)."""
    names = load_monster_names()
    full, overrides, appends = load_special_spec(rom, names)
    total = len(full)
    if total > SPECIAL_CAPACITY_MAX:
        raise ValueError("authored special table has %d entries > capacity %d"
                         % (total, SPECIAL_CAPACITY_MAX))
    errors, warnings = special_shadow_report(rom, full, overrides, appends, names)
    return full, overrides, appends, errors, warnings


def emit_bank69_from_spec(rom):
    """patches/bank_069.asm text built from the AUTHORED special table (B5):
    same scanner as B2/B3, table = authored 825 (base+overrides) + appends +
    single $FF terminator. Raises on capacity or shadow ERRORS."""
    full, overrides, appends, errors, warnings = build_authored_special(rom)
    if errors:
        raise ValueError("authored special table has shadow ERRORS:\n  "
                         + "\n  ".join(errors))
    body = [b for e in full for b in e] + [0xFF]
    if len(body) > BANK69_SIZE - 0x200:
        raise ValueError("authored table too large for bank $69: %d bytes"
                         % len(body))
    note = ("; The table below is the AUTHORED special table (B5):\n"
            ";   825 base entries (vanilla ROM) with %d in-place override(s)\n"
            ";   + %d appended recipe(s); single $FF terminator.\n"
            "; Source of truth: extracted/breeding_special.json.\n"
            "; Bank $16's vanilla special table is left byte-identical to the\n"
            "; ROM (runtime-dead via the B2 rst $10 redirect).\n"
            % (len(overrides), len(appends)))
    header = ("; ============================================================="
              "================\n"
              "; BANK $69 - Relocated SPECIAL breeding-recipe scanner (B2) +\n"
              ";           FULL authored special table (B5)\n"
              "; ============================================================="
              "================\n"
              "; Generated by tools/build_breeding.py --emit-special\n"
              ";\n"
              "; ROADMAP Phase 2B / B5. The scanner (unchanged from B2/B3) walks\n"
              "; to the $FF terminator with no hardcoded count. The whole table\n"
              "; is authored data owned by build_breeding.py; edit any base entry\n"
              "; in place or append new ones via breeding_special.json.\n"
              ";\n"
              + note +
              "; ============================================================="
              "================\n\n")
    return header + BANK69_SCANNER_ASM + _emit_db(body) + "\n"


def write_bank69_from_spec(rom):
    path = os.path.join(REPO, "patches", "bank_069.asm")
    with open(path, "w") as f:
        f.write(emit_bank69_from_spec(rom))
    return path


def read_patched_special_table():
    """Parse the SPECIAL table from patches/bank_016.asm (the source of truth for
    the patched build) so the relocated copy carries ALL existing patched edits
    (e.g. the Session-12 Anteater x BattleRex -> GoldSlime override), not the
    vanilla bytes. Falls back to the vanilla ROM table only if the patch file or
    label is absent."""
    path = os.path.join(REPO, "patches", "bank_016.asm")
    if not os.path.exists(path):
        return None
    text = open(path).read()
    if "SpecialRecipeTable:" not in text:
        return None
    seg = text.split("SpecialRecipeTable:", 1)[1]
    # table runs up to the next label (the disassembly puts label16_5b4e: next)
    seg = re.split(r"\n[A-Za-z_][A-Za-z0-9_]*:", seg, 1)[0]
    data = parse_db_bytes(seg)
    want = SPECIAL_COUNT * SPECIAL_ENTRY + 1          # 825*5 + terminator
    if len(data) < want:
        raise ValueError("patched SpecialRecipeTable too short: %d < %d"
                         % (len(data), want))
    data = data[:want]
    if data[-1] != 0xFF:
        raise ValueError("patched SpecialRecipeTable not $FF-terminated (got $%02X)"
                         % data[-1])
    return data


def build_relocated_table(rom):
    """Return (table_bytes, base_count, extras). The relocated bank $69 table is:
    825 patched/vanilla base entries (NO terminator) + appended B3 extras + a
    single $FF terminator. Validates capacity, byte ranges, bank fit, and warns
    on shadowed (dead) appended recipes."""
    patched = read_patched_special_table()
    if patched is not None:
        base = list(patched)
        src = "patched bank_016.asm (carries existing custom recipe edits)"
    else:
        base = list(encode_special(decode_special(rom)))   # fallback: vanilla ROM
        src = "vanilla ROM (patches/bank_016.asm not found)"
    assert base[-1] == 0xFF, "base table must be $FF-terminated"
    base_body = base[:-1]                       # drop terminator; 825*5 bytes
    assert len(base_body) == SPECIAL_COUNT * SPECIAL_ENTRY

    extras = load_extra_recipes()
    base_entries = decode_special(rom) if patched is None else \
        [base_body[i:i + 5] for i in range(0, len(base_body), 5)]

    # Validations -------------------------------------------------------------
    total = SPECIAL_COUNT + len(extras)
    if total > SPECIAL_CAPACITY_MAX:
        raise ValueError("special capacity exceeded: %d entries > max %d"
                         % (total, SPECIAL_CAPACITY_MAX))
    warnings = []
    for k, e in enumerate(extras):
        # Only species-id parents can be shadow-checked precisely; family-coded
        # appended parents are rarer and skipped (matching is approximate).
        if e[0] < 0xF0 and e[1] < 0xF0:
            hit = first_match_index(rom, base_entries, e[0], e[1])
            if hit is not None:
                warnings.append("appended recipe #%d (%s) is SHADOWED by base "
                                "entry %d and will never fire" % (k, e, hit))

    body = list(base_body) + [b for e in extras for b in e] + [0xFF]

    # Bank fit: scanner is small and fixed; assert the whole bank fits with
    # margin. Table offset within the bank isn't known until link, so bound the
    # table size conservatively against the full 16 KB bank.
    if len(body) > BANK69_SIZE - 0x200:        # keep >=512 B headroom for scanner
        raise ValueError("relocated table too large for bank $69: %d bytes"
                         % len(body))
    return bytes(body), src, extras, warnings


def emit_bank69_asm(rom):
    """Full patches/bank_069.asm text: header note + scanner + relocated table.

    The relocated table = the 825 PATCHED base entries (so custom recipes from
    earlier sessions survive) followed by the B3 appended recipes from
    extracted/breeding_extra_recipes.json, then a single $FF terminator. The
    bank $69 scanner walks to $FF, so appended entries (>index 824) are scanned
    with normal first-match-wins precedence."""
    table, src, extras, _warn = build_relocated_table(rom)
    note = ("; The table below = 825 base entries from\n"
            ";   " + src + "\n"
            "; then %d APPENDED recipe(s) (B3) from\n"
            ";   extracted/breeding_extra_recipes.json\n"
            "; proving the table grows past index 824 (capacity 1x-2x, max %d).\n"
            % (len(extras), SPECIAL_CAPACITY_MAX))
    header = ("; ============================================================="
              "================\n"
              "; BANK $69 - Relocated SPECIAL breeding-recipe scanner (B2) +\n"
              ";           appended-recipe capacity extension (B3)\n"
              "; ============================================================="
              "================\n"
              "; Generated by tools/build_breeding.py --emit-relocation\n"
              ";\n"
              "; ROADMAP Phase 2B / B2 (relocation harness) + B3 (capacity 1x-2x).\n"
              "; The special-recipe scan was moved here from bank $16 and is\n"
              "; invoked via `rst $10` (ld hl,$6900). The scanner walks to the\n"
              "; $FF terminator with no hardcoded count, so the table can grow.\n"
              ";\n"
              + note +
              "; ============================================================="
              "================\n\n")
    return header + BANK69_SCANNER_ASM + _emit_db(list(table)) + "\n"


def write_bank69(rom):
    path = os.path.join(REPO, "patches", "bank_069.asm")
    with open(path, "w") as f:
        f.write(emit_bank69_asm(rom))
    return path


def main():
    ap = argparse.ArgumentParser(description="DWM1 breeding round-trip encoder (B1) + relocation (B2).")
    ap.add_argument("--selftest", action="store_true",
                    help="prove byte-perfect round-trip against ROM and exit")
    ap.add_argument("--check-disasm", action="store_true",
                    help="also verify disassembly db bytes match the ROM")
    ap.add_argument("--no-write", action="store_true",
                    help="run selftest but do not write the JSON")
    ap.add_argument("--emit-relocation", action="store_true",
                    help="write patches/bank_069.asm (B2 relocated scanner+table). "
                         "LEGACY: superseded by --emit-special (B5); the B3 "
                         "appends file breeding_extra_recipes.json was deleted "
                         "S51 (absence tolerated -> base table only)")
    ap.add_argument("--emit-family", action="store_true",
                    help="rewrite the FamilyRecipeTable in patches/bank_016.asm "
                         "in place from breeding_family_defaults.json (B4)")
    ap.add_argument("--emit-special", action="store_true",
                    help="write patches/bank_069.asm from the AUTHORED special "
                         "table (B5): vanilla 825 base + in-place overrides + "
                         "appends, from breeding_special.json")
    args = ap.parse_args()

    if not os.path.exists(ROM_PATH):
        print("ERROR: ROM not found at %s" % ROM_PATH, file=sys.stderr)
        return 2
    rom = load_rom()
    md5 = hashlib.md5(rom).hexdigest()
    if md5 != ORIGINAL_MD5:
        print("ERROR: ROM MD5 %s != expected %s" % (md5, ORIGINAL_MD5), file=sys.stderr)
        return 2

    print("build_breeding.py — breeding table round-trip (B1)")
    print("ROM: data/DWM-original.gbc  MD5 %s OK" % md5)
    ok = selftest(rom, check_disasm=args.check_disasm)
    print("ROUND-TRIP: %s" % ("PASS" if ok else "FAIL"))
    if not ok:
        return 1

    if args.selftest:
        return 0

    if args.emit_relocation:
        path = write_bank69(rom)
        # Self-checks (B2 + B3):
        #  - the FIRST 825 entries must equal the PATCHED bank_016 table (so the
        #    relocation preserves the in-progress build, incl. the Session-12
        #    Anteater(53) x BattleRex(42) -> GoldSlime(19) recipe, both orders);
        #  - the appended (>824) recipes must be present and end with $FF;
        #  - capacity must be within SPECIAL_CAPACITY_MAX with no shadow warnings.
        emitted = emit_bank69_asm(rom)
        tbl = parse_db_bytes(emitted.split("RelocatedSpecialTable:")[1])
        patched = read_patched_special_table()
        ref = patched if patched is not None else \
            list(rom[file_off(SPECIAL_ADDR): file_off(SPECIAL_ADDR) + SPECIAL_COUNT * SPECIAL_ENTRY + 1])
        base_len = SPECIAL_COUNT * SPECIAL_ENTRY            # 4125 (no terminator)
        base_match = tbl[:base_len] == list(ref)[:base_len]

        _table, _src, extras, warnings = build_relocated_table(rom)
        total = SPECIAL_COUNT + len(extras)
        appended_ok = (
            len(tbl) == base_len + len(extras) * SPECIAL_ENTRY + 1
            and tbl[-1] == 0xFF
            and all(tbl[base_len + k * 5: base_len + k * 5 + 5] == extras[k]
                    for k in range(len(extras)))
        )

        def _has(t, p):
            return any(t[i:i + len(p)] == p for i in range(len(t) - len(p) + 1))
        fwd = _has(tbl[:base_len], [0x35, 0x2a, 0x00, 0x13, 0x00])
        rev = _has(tbl[:base_len], [0x2a, 0x35, 0x00, 0x13, 0x00])

        print("wrote %s" % os.path.relpath(path, REPO))
        print("  base 825 entries == patched bank_016 table: %s"
              % ("OK" if base_match else "MISMATCH"))
        print("  Anteater x BattleRex -> GoldSlime present (both orders): %s"
              % ("OK" if (fwd and rev) else "MISSING"))
        print("  appended recipes (B3): %d  -> total %d / max %d (%s)"
              % (len(extras), total, SPECIAL_CAPACITY_MAX,
                 "OK" if total <= SPECIAL_CAPACITY_MAX else "OVER CAPACITY"))
        print("  appended bytes placed + $FF-terminated: %s"
              % ("OK" if appended_ok else "BAD"))
        for w in warnings:
            print("  WARNING: " + w)
        if not (base_match and appended_ok and total <= SPECIAL_CAPACITY_MAX
                and not warnings):
            return 1

    if args.emit_special:
        names = load_monster_names()
        path = write_bank69_from_spec(rom)
        full, overrides, appends, errors, warnings = build_authored_special(rom)
        # Self-checks: re-parse the emitted table and confirm it equals the
        # authored bytes, ends with $FF, and that every untouched base entry is
        # still vanilla-identical (only the overridden indices may differ).
        emitted = emit_bank69_from_spec(rom)
        tbl = parse_db_bytes(emitted.split("RelocatedSpecialTable:")[1])
        want = [b for e in full for b in e] + [0xFF]
        emit_ok = tbl == want and tbl[-1] == 0xFF
        van = decode_special(rom)
        changed = {o["index"] for o in overrides}
        base_part = [tbl[i * 5:i * 5 + 5] for i in range(SPECIAL_COUNT)]
        untouched_ok = all(base_part[i] == van[i]
                           for i in range(SPECIAL_COUNT) if i not in changed)
        overrides_ok = all(base_part[o["index"]] == o["after"] for o in overrides)
        total = len(full)
        print("wrote %s" % os.path.relpath(path, REPO))
        print("  base 825 (vanilla ROM) + %d override(s) + %d append(s) = %d entries"
              % (len(overrides), len(appends), total))
        for o in overrides:
            print("    override #%d: %s" % (o["index"], o["label"]))
        for a in appends:
            print("    append:      %s" % a["label"])
        print("  emitted table == authored bytes + $FF: %s"
              % ("OK" if emit_ok else "MISMATCH"))
        print("  untouched base entries == vanilla: %s"
              % ("OK" if untouched_ok else "MISMATCH"))
        print("  overrides present at their indices: %s"
              % ("OK" if overrides_ok else "BAD"))
        print("  capacity %d / max %d: %s"
              % (total, SPECIAL_CAPACITY_MAX,
                 "OK" if total <= SPECIAL_CAPACITY_MAX else "OVER"))
        for w in warnings:
            print("  NOTE: " + w)
        for e in errors:
            print("  ERROR: " + e)
        if not (emit_ok and untouched_ok and overrides_ok
                and total <= SPECIAL_CAPACITY_MAX and not errors):
            return 1
        return 0

    if args.emit_family:
        names = load_monster_names()
        overrides, warnings = write_family_table(rom)
        # Self-checks: parse the rewritten FamilyRecipeTable bytes back, confirm
        # every untouched slot stayed vanilla-identical, the length is invariant,
        # and each authored cross is present at its slot.
        text = open(PATCH_BANK16).read()
        m = re.search(r"FamilyRecipeTable:\n(.*?)\n[A-Za-z_][A-Za-z0-9_]*:",
                      text, re.S)
        body = parse_db_bytes(m.group(1))
        new_pairs = [{"slot": i, "b": body[2 * i], "c": body[2 * i + 1]}
                     for i in range(len(body) // 2)]
        van = decode_family(rom)
        applied = {o["result"]: o for o in overrides}
        untouched_ok = all(
            new_pairs[p["slot"]]["b"] == p["b"]
            and new_pairs[p["slot"]]["c"] == p["c"]
            for p in van if p["slot"] not in applied
        )
        roundtrip_ok = all(
            new_pairs[r]["b"] == o["b"] and new_pairs[r]["c"] == o["c"]
            for r, o in applied.items()
        )
        len_ok = len(body) == 444
        print("wrote patches/bank_016.asm (FamilyRecipeTable)")
        print("  applied %d family-default override(s):" % len(overrides))
        for o in overrides:
            print("    %s x %s -> %s (slot %d)"
                  % (species_name(o["b"], names), species_name(o["c"], names),
                     species_name(o["result"], names), o["result"]))
        print("  untouched slots == vanilla: %s" % ("OK" if untouched_ok else "MISMATCH"))
        print("  overrides present at their slots: %s" % ("OK" if roundtrip_ok else "BAD"))
        print("  table length 444 B (zero shift): %s" % ("OK" if len_ok else "BAD"))
        for w in warnings:
            print("  WARNING: " + w)
        if not (untouched_ok and roundtrip_ok and len_ok and not warnings):
            return 1
        return 0

    if not args.no_write:
        data = build_json(rom)
        with open(OUT_JSON, "w") as f:
            json.dump(data, f, indent=2)
        print("wrote %s (%d special entries, %d family pairs)"
              % (os.path.relpath(OUT_JSON, REPO),
                 len(data["special_table"]["entries"]),
                 len(data["family_table"]["slots"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
