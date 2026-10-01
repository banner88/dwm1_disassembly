#!/usr/bin/env python3
"""
extract_monster_follower_layouts.py  --  DWM1 monster -> follower-layout auto-map (GFX-4).

This is the AUTHORITATIVE follower-layout extractor. Unlike the Session-24
extract_follower_layouts.py (which brute-force-scanned banks $05/$10/$11 for any
six-pointer table and accepted only exactly-4-entry frames), this tool walks the
*real* in-game dispatch the engine executes, so it (a) maps every species to its
layout, (b) is complete (it includes the 3-entry small/blob layouts the old scan
silently dropped), and (c) reports canonical addresses.

ENGINE PATH (all ROM-verified, see MONSTER_DATA.md "Follower / walking-sprite system"):

  * The active follower's species lives in the party struct at +$09, i.e. $CACA is
    the SPECIES byte (NOT a separate "sprite-class" byte -- the pre-GFX-4 docs were
    wrong about that).
  * GetActiveMonsterStatus ($01:$4986) returns  $ffc7 = species + $10  (the $01
    bit7-of-$cb0b case is a transient status, not a layout selector).
  * The follower render is dispatched via bank $04 entry 2 (NPCInteractDispatch),
    routed by $ffc7 magnitude:
        $ffc7 in $10..$8F  -> bank $10 entry 0, sub = $ffc7-$10 (= species, sp 0..127)
        $ffc7 >= $90       -> bank $11 entry 0, sub = $ffc7-$90 (sp 128..255)
    (Monster followers are always >= $10, so the bank-$04 $401d table -- which is
    for plain NPCs -- is never used for monsters.)
  * Bank $10/$11 entry 0:  ld de,$407f ; call $0d91   -- so the LEVEL-1 table is at
    a FIXED address $407f in the routed bank, indexed by `sub`.  Each level-1 entry
    is a 2-byte pointer to a LEVEL-2 table of six frame pointers
    (down_A, down_B, right_A, right_B, up_A, up_B); left = right with a global X-flip.
  * Each frame is a run of 4-byte metasprite entries (dy, dx, tile_offset, attr),
    $80-terminated; final OAM tile = tile_offset + [$ffc9] (follower base $20/$30/$40
    per party slot); final OAM attr = [$ffca] XOR attr (X-flip = bit5).  tile_offset
    is 0..15 within the monster's 16-tile follower art block.
  * (Bonus, also at a fixed address: a per-species attribute byte table right after
    the level-1 table -- bank $10 $417f, bank $11 $412d (87 entries; S106 fix) --
    ORed into [$ffca] by HramScr2_406e: the follower's palette (low 3 bits) and
    flips (bit5 X, bit6 Y).  Captured here as `attr_base`.)

Anchors reproduced byte-for-byte from this path: Healer (sp9) = a sharing layout;
DarkDrium (sp214) = a non-sharing layout (down 0,0^,1,2 / 0,0^,3,4, right 5,6,7,8 /
5,6,9,A, up B,B^,C,D / B,B^,E,F).

Outputs:
  extracted/follower_layouts.json          (REPLACES the S24 file: complete + canonical)
  extracted/monster_follower_layouts.json  (species -> layout id + addresses, GFX-4 deliverable)

The reassignment primitive (editor): to move a monster onto a clean non-sharing
layout, repoint its LEVEL-1 entry (a same-size 2-byte edit at bank $10/$11 $407f +
sub*2) to a non-sharing level-2 table -- NOT a [$caca] edit ([$caca] is the species).
"""
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(__file__), "..")
ROM = os.path.join(ROOT, "data", "DWM-original.gbc")
OUT_LAYOUTS = os.path.join(ROOT, "extracted", "follower_layouts.json")
OUT_MAP = os.path.join(ROOT, "extracted", "monster_follower_layouts.json")
MONSTERS = os.path.join(ROOT, "extracted", "monsters_full.json")

L1_BASE = 0x407F          # level-1 table address in the routed bank
ATTR_BASE = {0x10: 0x417F,  # per-species attr/palette byte table (HramScr2_406e),
             0x11: 0x412D}  # AFTER each bank's level-1 table: bank $10's has 128
                            # entries, bank $11's only 87 (species 128-214) —
                            # S106 fix: one $417F for both read bank $11's level-2
                            # layout bytes as attrs (MONSTER_DATA follower section)
FRAME_NAMES = ["down_A", "down_B", "right_A", "right_B", "up_A", "up_B"]

# Collectible species range and known non-collectible specials (PROJECT_STATE B7).
COLLECTIBLE_MAX = 214
SPECIAL_NONCOLLECTIBLE = {
    215: "TERRY? (Durran story enemy)",
    216: "summon tier 1 (Tatsu)",
    217: "summon tier 2 (Diago)",
    218: "summon tier 3 (Samsi)",
    219: "summon tier 4 (Bazoo)",
    220: "reserved/blank",
}
MAX_SPECIES = 220


def load_rom():
    with open(ROM, "rb") as f:
        return f.read()


def fileoff(bank, addr):
    return bank * 0x4000 + (addr - 0x4000)


def rd16(rom, bank, addr):
    o = fileoff(bank, addr)
    return rom[o] | (rom[o + 1] << 8)


def rd8(rom, bank, addr):
    return rom[fileoff(bank, addr)]


def route(species):
    """species -> (ffc7, bank, sub) for the follower render path."""
    ffc7 = species + 0x10
    if ffc7 >= 0x90:
        return ffc7, 0x11, ffc7 - 0x90
    return ffc7, 0x10, ffc7 - 0x10


def read_frame(rom, bank, addr):
    """Decode one metasprite frame: 4-byte (dy,dx,tile,attr) entries, $80-terminated.

    Returns a list of {dy,dx,tile,xflip} (1..8 entries) or None if malformed
    (tile out of 0..15, no terminator within 8 entries, or OOB).
    """
    o = fileoff(bank, addr)
    ents = []
    for i in range(9):
        if o + i * 4 + 3 >= len(rom):
            return None
        dy = rom[o + i * 4]
        if dy == 0x80:
            break
        dx, tile, attr = rom[o + i * 4 + 1], rom[o + i * 4 + 2], rom[o + i * 4 + 3]
        if tile > 0x0F:
            return None
        sdy = dy - 256 if dy >= 128 else dy
        sdx = dx - 256 if dx >= 128 else dx
        ents.append({"dy": sdy, "dx": sdx, "tile": tile, "xflip": bool(attr & 0x20),
                     "yflip": bool(attr & 0x40)})
    if not (1 <= len(ents) <= 8):
        return None
    return ents


def read_layout(rom, bank, l2_addr):
    """Decode the six frames at a level-2 table. Returns list[6] of frame-entry-lists, or None."""
    frames = []
    for j in range(6):
        fp = rd16(rom, bank, l2_addr + j * 2)
        if not (0x4000 <= fp <= 0x7FFF):
            return None
        fr = read_frame(rom, bank, fp)
        if fr is None:
            return None
        frames.append(fr)
    return frames


def frame_sig(frame):
    # position-aware signature: tile mapping AND geometry both define a layout
    # (S107: + Y-flip — one entry in the whole ROM uses it, species 139's
    # right_B; the count stays 155 because that layout is unique anyway)
    return tuple(sorted((e["dy"], e["dx"], e["tile"], e["xflip"], e["yflip"]) for e in frame))


def raw_frame(rom, bank, addr):
    """The frame's bytes as stored, incl. the $80 terminator (S107: the
    compiler copies these into the other follower bank — PROJECT_COMPILER
    §2.23 "walking layouts")."""
    o = fileoff(bank, addr)
    n = 0
    while rom[o + n] != 0x80:
        n += 4
    return rom[o:o + n + 1]


def layout_sig(frames):
    return tuple(frame_sig(fr) for fr in frames)


def tiles_in(frames, idxs):
    s = set()
    for i in idxs:
        for e in frames[i]:
            s.add(e["tile"])
    return s


def classify(frames):
    down = tiles_in(frames, [0, 1])
    right = tiles_in(frames, [2, 3])
    up = tiles_in(frames, [4, 5])
    sharing = bool((up & right) or (up & down) or (down & right))
    return {
        "down_tiles": sorted(down),
        "right_tiles": sorted(right),
        "up_tiles": sorted(up),
        "sharing": sharing,
        "tile_count": len(down | right | up),
    }


def frame_out(frame):
    return [
        {"dy": e["dy"], "dx": e["dx"], "tile": e["tile"], "xflip": e["xflip"],
         "yflip": e["yflip"]}
        for e in frame
    ]


def load_names():
    try:
        d = json.load(open(MONSTERS))
        mons = d["monsters"] if isinstance(d, dict) and "monsters" in d else d
        return {m["id"]: m["name"] for m in mons}
    except Exception:
        return {}


def build(rom):
    names = load_names()
    # First pass: per-species records + collect layout signatures with usage counts.
    species_recs = []
    sig_count = {}
    sig_example = {}
    sig_frames = {}
    sig_inst = {}           # sig -> {bank: set(l2)} (S107: where it already exists)
    bank_frames = {0x10: {}, 0x11: {}}   # bank -> {frame addr: raw hex}
    for sp in range(0, MAX_SPECIES + 1):
        ffc7, bank, sub = route(sp)
        l1_addr = L1_BASE + sub * 2
        l2_addr = rd16(rom, bank, l1_addr)
        attr_base = rd8(rom, bank, ATTR_BASE[bank] + sub)
        frames = read_layout(rom, bank, l2_addr)
        rec = {
            "species": sp,
            "name": names.get(sp, f"sp{sp}"),
            "collectible": sp <= COLLECTIBLE_MAX,
            "ffc7": ffc7,
            "bank": bank,
            "l1_index": sub,
            "l1_addr": l1_addr,
            "l2_addr": l2_addr,
            "attr_base": attr_base,
        }
        if sp in SPECIAL_NONCOLLECTIBLE:
            rec["note"] = SPECIAL_NONCOLLECTIBLE[sp]
        if frames is None:
            rec["layout_id"] = None
            rec["decode_ok"] = False
        else:
            sig = layout_sig(frames)
            sig_count[sig] = sig_count.get(sig, 0) + 1
            if sig not in sig_example:
                sig_example[sig] = {"bank": bank, "addr": l2_addr, "species": sp}
                sig_frames[sig] = frames
            rec["_sig"] = sig
            rec["decode_ok"] = True
            sig_inst.setdefault(sig, {}).setdefault(bank, set()).add(l2_addr)
            for j in range(6):
                fp = rd16(rom, bank, l2_addr + j * 2)
                bank_frames[bank][fp] = raw_frame(rom, bank, fp).hex()
        species_recs.append(rec)

    # Assign layout ids by descending usage (stable: ties broken by example addr).
    ordered = sorted(sig_count.keys(), key=lambda s: (-sig_count[s], sig_example[s]["bank"], sig_example[s]["addr"]))
    sig_id = {s: i for i, s in enumerate(ordered)}

    layouts = []
    for s in ordered:
        frames = sig_frames[s]
        cls = classify(frames)
        ex = sig_example[s]
        ptrs = [rd16(rom, ex["bank"], ex["addr"] + j * 2) for j in range(6)]
        layouts.append({
            "id": sig_id[s],
            "used_by_species": sig_count[s],
            "example_l2": ex,
            "classification": cls,
            "frames": {FRAME_NAMES[j]: frame_out(frames[j]) for j in range(6)},
            # S107 (P3.10 part 2b): the level-2 tables of this layout in each
            # follower bank (a species can only point at its OWN bank's), and
            # the example's stored bytes — frame j = raw[share[j]] (frames the
            # example's table points at twice are stored once)
            "instances": {f"{b:02x}": sorted(v) for b, v in sorted(sig_inst[s].items())},
            "raw": [raw_frame(rom, ex["bank"], p).hex() for p in dict.fromkeys(ptrs)],
            "share": [list(dict.fromkeys(ptrs)).index(p) for p in ptrs],
        })

    # Finalize per-species map (resolve sig -> id, drop temp).
    monster_map = []
    for rec in species_recs:
        sig = rec.pop("_sig", None)
        rec["layout_id"] = sig_id.get(sig) if sig is not None else None
        rec["sharing"] = (
            layouts[rec["layout_id"]]["classification"]["sharing"]
            if rec["layout_id"] is not None else None
        )
        monster_map.append(rec)

    frames_by_bank = {f"{b:02x}": [[a, h] for a, h in sorted(fr.items())]
                      for b, fr in bank_frames.items()}
    return layouts, monster_map, frames_by_bank


def selftest(rom, layouts, monster_map):
    ok = True
    by_sp = {m["species"]: m for m in monster_map}

    # 1) coverage: every collectible species decodes to a layout
    missing = [m["species"] for m in monster_map if m["collectible"] and m["layout_id"] is None]
    if missing:
        ok = False
        print(f"  FAIL: {len(missing)} collectible species failed to decode: {missing[:10]}")
    else:
        print(f"  OK: all {COLLECTIBLE_MAX+1} collectible species (0..{COLLECTIBLE_MAX}) map to a layout")

    # 2) Healer (sp9) is a sharing layout
    h = by_sp[9]
    if not (h["bank"] == 0x10 and h["sharing"] is True):
        ok = False
        print(f"  FAIL: Healer sp9 expected bank $10 + sharing, got bank ${h['bank']:02x} sharing={h['sharing']}")
    else:
        print(f"  OK: Healer sp9 -> bank $10 idx {h['l1_index']} L2=${h['l2_addr']:04x} (sharing layout {h['layout_id']})")

    # 3) DarkDrium (sp214) is non-sharing with the known tile pattern
    d = by_sp[214]
    dl = layouts[d["layout_id"]] if d["layout_id"] is not None else None
    want = {
        "down_A": [(0, False), (0, True), (1, False), (2, False)],
        "down_B": [(0, False), (0, True), (3, False), (4, False)],
        "right_A": [(5, False), (6, False), (7, False), (8, False)],
        "right_B": [(5, False), (6, False), (9, False), (10, False)],
        "up_A": [(11, False), (11, True), (12, False), (13, False)],
        "up_B": [(11, False), (11, True), (14, False), (15, False)],
    }
    got = {fn: sorted((e["tile"], e["xflip"]) for e in dl["frames"][fn]) for fn in want} if dl else {}
    want_s = {fn: sorted(v) for fn, v in want.items()}
    if d["bank"] == 0x11 and dl and not dl["classification"]["sharing"] and got == want_s:
        print(f"  OK: DarkDrium sp214 -> bank $11 idx {d['l1_index']} L2=${d['l2_addr']:04x} (non-sharing layout {d['layout_id']}, tile pattern matches)")
    else:
        ok = False
        print(f"  FAIL: DarkDrium sp214 layout mismatch. bank=${d['bank']:02x} sharing={dl['classification']['sharing'] if dl else '?'}")
        print(f"        got={got}")

    # 4) S107: the stored bytes (`raw` + `share`) decode to the layout's own
    #    frames, and every listed instance IS that layout in its bank
    bad = []
    for L in layouts:
        want = layout_sig([[{**e} for e in L["frames"][fn]] for fn in FRAME_NAMES])
        dec = []
        for j in range(6):
            r = bytes.fromhex(L["raw"][L["share"][j]])
            fr = []
            for o in range(0, len(r) - 1, 4):
                dy, dx, t, at = r[o:o + 4]
                fr.append({"dy": dy - 256 if dy > 127 else dy, "dx": dx - 256 if dx > 127 else dx,
                           "tile": t, "xflip": bool(at & 0x20), "yflip": bool(at & 0x40)})
            dec.append(fr)
        if layout_sig(dec) != want:
            bad.append((L["id"], "raw"))
        for bk, addrs in L["instances"].items():
            for a in addrs:
                if layout_sig(read_layout(rom, int(bk, 16), a)) != want:
                    bad.append((L["id"], bk, a))
    if bad:
        ok = False
        print(f"  FAIL: stored bytes / instances do not match: {bad[:5]}")
    else:
        n10 = sum('10' in L["instances"] for L in layouts)
        n11 = sum('11' in L["instances"] for L in layouts)
        print(f"  OK: raw bytes of all {len(layouts)} layouts decode to their frames; "
              f"instances: {n10} layouts exist in bank $10, {n11} in bank $11")

    # 5) stats
    n_share = sum(1 for L in layouts if L["classification"]["sharing"])
    sp_share = sum(1 for m in monster_map if m["sharing"] is True)
    sp_non = sum(1 for m in monster_map if m["sharing"] is False)
    print(f"  layouts: {len(layouts)} total ({n_share} sharing / {len(layouts)-n_share} non-sharing)")
    print(f"  species on sharing(blob) layout: {sp_share}   on non-sharing: {sp_non}")
    return ok


def main():
    rom = load_rom()
    layouts, monster_map, frames_by_bank = build(rom)

    gen = {
        "_generator": "tools/extract_monster_follower_layouts.py (ROM: DWM-original.gbc md5 1ca6579359f21d8e27b446f865bf6b83)",
    }

    if "--selftest" in sys.argv:
        print("extract_monster_follower_layouts.py --selftest")
        ok = selftest(rom, layouts, monster_map)
        # S107: the committed JSON files == what the ROM gives now (the editor
        # and the compiler read them: walk_layouts.py, sprite_render.py)
        try:
            on_disk = json.load(open(OUT_LAYOUTS))
            same = (on_disk.get("layouts") == json.loads(json.dumps(layouts)) and
                    on_disk.get("bank_frames") == json.loads(json.dumps(frames_by_bank)))
            m_disk = json.load(open(OUT_MAP))
            same = same and m_disk.get("monsters") == json.loads(json.dumps(monster_map))
        except (OSError, ValueError):
            same = False
        print(f"  {'OK' if same else 'FAIL'}: extracted/follower_layouts.json + "
              "monster_follower_layouts.json == the ROM")
        ok = ok and same
        print("SELFTEST:", "PASS" if ok else "FAIL")
        sys.exit(0 if ok else 1)

    with open(OUT_LAYOUTS, "w") as f:
        json.dump({**gen, "layout_count": len(layouts), "layouts": layouts,
                   # S107: every frame the species' tables use, per bank
                   # ([address, stored bytes]) — a layout copied into the
                   # other bank reuses a byte-identical frame already there
                   "bank_frames": frames_by_bank}, f, indent=1)
    with open(OUT_MAP, "w") as f:
        json.dump({**gen,
                   "level1_table": {"bank_10": L1_BASE, "bank_11": L1_BASE,
                                    "note": "ffc7=species+$10; <$90 -> bank $10 idx ffc7-$10, >=$90 -> bank $11 idx ffc7-$90"},
                   "species_count": len(monster_map),
                   "monsters": monster_map}, f, indent=1)

    n_share = sum(1 for L in layouts if L["classification"]["sharing"])
    print(f"wrote {os.path.relpath(OUT_LAYOUTS)}: {len(layouts)} layouts "
          f"({n_share} sharing / {len(layouts)-n_share} non-sharing)")
    print(f"wrote {os.path.relpath(OUT_MAP)}: {len(monster_map)} species (0..{MAX_SPECIES})")


if __name__ == "__main__":
    main()
