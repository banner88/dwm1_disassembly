#!/usr/bin/env python3
"""
decode_battle_animations.py — S2c-anim: the battle skill-EFFECT animation RENDERER.

This reverses the on-screen battle-effect animation system (the wall the S2c
"message-format" session bounced off — it decoded the MESSAGE path and left the
visual renderer open). The renderer is NOT an opaque blob: it is a metasprite/OAM
animation engine that reuses the SAME 4-byte metasprite format the project already
knows from the follower/walking-sprite engine (GFX-3).

ARCHITECTURE (all ROM-verified — see BATTLE_SKILL_SYSTEM.md §11):

  per-skill descriptor (3 bytes, indexed by skill id $db8a, in bank $5f):
     $5f:$58dd[id]  -> anim routine index 0..7  (selects one of 8 routines $5f:$58bd)
     $5f:$59c3[id]  -> secondary/graphic selector ($0d default)
     $5f:$5aa9[id]  -> secondary/graphic selector ($0d default)

  command byte -> bank select:
     $5f entry 7 (LoadFldUI_5630) reads a per-skill table ($5f:$56ed or $5f:$57d5,
        chosen by caster side) -> $da81 = animation COMMAND byte.
     ROM0 dispatcher ($00:$3004 region) routes $da81:
        < $0e            -> bank $5c entry 0
        < $21            -> bank $5d entry 0
        else             -> bank $5e entry 0
        ($15/$2c/$db8a==$c5 special-cased)

  renderer (each of $5c/$5d/$5e, entry 0):
     reads frame counter $dd66 -> HRAM $c8 (frame index)
     reads $dd68 (phase: 0 = draw frames; nonzero = projectile-move $c3 across screen)
     calls the OAM builder HramB5c_40fc with de = the bank's frame-table base ($4071):

  TWO-LEVEL FRAME TABLE (per bank, base $4071):
     animation = [ base + [$c7]*2 ]        ; $c7 = animation index (set per-skill in $5f)
     frame_ptr = [ animation + [$c8]*2 ]   ; $c8 = current frame ($dd66)
     frame     = list of 4-byte OAM entries, $80-terminated:
         byte0 dy   -> OAM Y = dy + [$c5] + $10        (signed)
         byte1 dx   -> OAM X = dx + [$c3] + $08        (signed)
         byte2 tile -> OAM tile = tile + [$c9]         (tile base, per-skill)
         byte3 attr -> OAM attr = attr XOR [$ca]       (attr base; bit5=X-flip)
     (identical to the follower metasprite format: dy,dx,tile_offset,attr; $80-term.)

  frame advance: the counter struct $dd62/$dd63.../$dd66 is stepped by a generic
     bank-$02 timer routine (rst $10 entry $0205) via the pointer at $d7b4/$d7b5.

WHAT THIS PROVES: a skill's animation is fully described by (routine index, frame
table). "Reuse an existing animation on a new skill id" = set the new id's
$58dd/$59c3/$5aa9 slots (a table edit). "Author a NOVEL animation" = add frame
metasprite lists (this format) + an animation-table entry + the per-skill index —
no opaque renderer left to reverse.

Outputs extracted/battle_animations.json (the frame tables decoded) and prints a
human-readable dump with --dump. --selftest re-checks the ROM anchors.

NOTE ON TABLE EXTENT: $c7 (the animation index) is set to small values by the $5f
routines; the top-level table at $4071 holds animation pointers immediately
followed by the first subtable. We decode the run of in-bank pointers that
dereference to valid $80-terminated metasprite lists and STOP at the first entry
that doesn't (conservative — never invents frames). The per-bank animation count
is reported, not hardcoded.
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_PATH = os.path.join(REPO, "data", "DWM-original.gbc")
OUT = os.path.join(REPO, "extracted", "battle_animations.json")

ANIM_BANKS = [0x5C, 0x5D, 0x5E]
FRAME_TABLE_BASE = 0x4071          # ld de,$4071 in each bank's entry-0
DESC_BANK = 0x5F
DESC_TABLES = {                    # per-skill descriptor tables (indexed by skill id)
    "anim_routine": 0x58DD,        # -> routine index 0..7 ($5f:$58bd)
    "selector_b":  0x59C3,
    "selector_c":  0x5AA9,
}
ROUTINE_TABLE = 0x58BD             # 8 routine pointers in $5f


def load_rom(path=ROM_PATH):
    with open(path, "rb") as f:
        return f.read()


def s8(v):
    return v - 256 if v >= 128 else v


class BankView:
    """Read helper for an $4000-based ROMX bank."""
    def __init__(self, rom, bank):
        self.rom = rom
        self.base = bank * 0x4000
        self.bank = bank

    def b(self, addr):
        return self.rom[self.base + (addr - 0x4000)]

    def w(self, addr):
        return self.b(addr) | (self.b(addr + 1) << 8)

    def in_bank(self, addr):
        return 0x4000 <= addr < 0x8000


def decode_frame(bv, addr, max_sprites=40):
    """Decode one $80-terminated 4-byte metasprite list. Returns (sprites, ok)."""
    sprites = []
    a = addr
    for _ in range(max_sprites + 1):
        by = bv.b(a)
        if by == 0x80:
            return sprites, True
        if not bv.in_bank(a + 3):
            return sprites, False
        dy, dx, tile, attr = bv.b(a), bv.b(a + 1), bv.b(a + 2), bv.b(a + 3)
        sprites.append({"dy": s8(dy), "dx": s8(dx), "tile": tile, "attr": attr})
        a += 4
    return sprites, False     # ran past max_sprites without a terminator -> reject


def decode_animation(bv, sub_addr, max_frames=24):
    """Decode one animation: a sub-table of frame pointers, each a metasprite list.
    Frames repeat at the end (the engine holds the last frame); we stop on the
    first repeated pointer or the first frame that doesn't decode cleanly."""
    frames = []
    prev = None
    a = sub_addr
    for _ in range(max_frames):
        fp = bv.w(a)
        if not bv.in_bank(fp):
            break
        if fp == prev:                 # repeated pointer = end-hold marker
            break
        sprites, ok = decode_frame(bv, fp)
        if not ok:
            break
        frames.append({"addr": f"${fp:04x}", "sprites": sprites})
        prev = fp
        a += 2
    return frames


def decode_bank(bv, max_anims=64):
    """Decode the two-level frame table for one animation bank.

    The top-level table at $4071 holds animation sub-table pointers; index = $c7.
    Some banks ($5d/$5e) start with a run of repeated DEFAULT pointers (e.g.
    $4173) for unused indices, then the distinct animations. The table EXTENT is
    determined structurally: the top table ends where the first byte of frame
    data begins, i.e. at the LOWEST address any top-table entry points to. We
    therefore: (1) read entries while each is an in-bank pointer to a valid
    $80-terminated metasprite sub-table, (2) track the minimum target address,
    (3) stop when the read cursor reaches that minimum (= start of the data).
    Repeated default pointers are kept as entries (they ARE valid table slots)
    but flagged so the count isn't mistaken for distinct animations."""
    raw = []                       # (index, sub_addr)
    a = FRAME_TABLE_BASE
    min_target = 0x8000
    for idx in range(max_anims):
        if a >= min_target:        # cursor reached the data region -> table ended
            break
        sub = bv.w(a)
        if not bv.in_bank(sub):
            break
        f0 = bv.w(sub)             # sub-table[0] must point to a valid first frame
        if not bv.in_bank(f0):
            break
        _, ok = decode_frame(bv, f0)
        if not ok:
            break
        raw.append((idx, sub))
        if sub < min_target:
            min_target = sub
        a += 2

    anims = []
    seen = {}
    for idx, sub in raw:
        is_default = sub in seen
        frames = seen.get(sub)
        if frames is None:
            frames = decode_animation(bv, sub)
            seen[sub] = frames
        anims.append({
            "index": idx,
            "subtable": f"${sub:04x}",
            "frame_count": len(frames),
            "is_default_slot": is_default,   # repeat of an earlier pointer (unused index)
            "frames": [] if is_default else frames,
        })
    distinct = len({s for _, s in raw})
    return anims, distinct


def decode_descriptors(rom, num_skills=222):
    """Per-skill animation descriptor: the 3 bytes in bank $5f, indexed by skill id."""
    bv = BankView(rom, DESC_BANK)
    routines = [bv.w(ROUTINE_TABLE + i * 2) for i in range(8)]
    out = []
    for sid in range(num_skills):
        rec = {"id": sid}
        for name, tbl in DESC_TABLES.items():
            rec[name] = bv.b(tbl + sid)
        out.append(rec)
    return routines, out


def build(rom, num_skills=222):
    banks = {}
    for bank in ANIM_BANKS:
        bv = BankView(rom, bank)
        anims, distinct = decode_bank(bv)
        banks[f"${bank:02x}"] = {
            "frame_table_base": f"${FRAME_TABLE_BASE:04x}",
            "table_slots": len(anims),
            "distinct_animations": distinct,
            "animations": anims,
        }
    routines, descriptors = decode_descriptors(rom, num_skills)
    return {
        "_generator": "tools/decode_battle_animations.py (ROM=data/DWM-original.gbc)",
        "_doc": "BATTLE_SKILL_SYSTEM.md §11 (battle-effect animation renderer)",
        "metasprite_format": "4 bytes/sprite: dy,dx,tile_offset,attr ; $80-terminated "
                             "(OAM Y=dy+[$c5]+$10, X=dx+[$c3]+$08, tile=tile+[$c9], attr=attr^[$ca])",
        "routine_table_5f_58bd": [f"${r:04x}" for r in routines],
        "descriptor_tables": {k: f"$5f:${v:04x}" for k, v in DESC_TABLES.items()},
        "anim_banks": banks,
        "per_skill_descriptors": descriptors,
    }


def selftest(rom):
    """Re-verify the ROM anchors that ground this RE."""
    ok = True
    bv = BankView(rom, 0x5C)
    # anchor 1: top-table[0] = $414d, its frame[0] = $418d = the 2-sprite seed frame
    assert bv.w(0x4071) == 0x414D, "top-table[0] != $414d"
    assert bv.w(0x414D) == 0x418D, "anim0 frame[0] ptr != $418d"
    f, good = decode_frame(bv, 0x418D)
    assert good and f == [{"dy": -8, "dx": -8, "tile": 0, "attr": 0},
                          {"dy": -8, "dx": 0, "tile": 1, "attr": 0}], "anim0 frame0 mismatch"
    print("  [ok] $5c anim0 frame0 = 2-sprite seed (dy,dx,tile,attr verified)")
    # anchor 2: all 8 top-level anims decode cleanly in-bank
    bank = build(rom)["anim_banks"]["$5c"]
    assert bank["distinct_animations"] >= 8, f"expected >=8 anims, got {bank['distinct_animations']}"
    print(f"  [ok] $5c decodes {bank['distinct_animations']} distinct animations, all in-bank")
    # anchor 3: descriptor table — Blaze(0)/Blazemore(1)/Blazemost(2) share routine index 0
    bv5f = BankView(rom, 0x5F)
    assert [bv5f.b(0x58DD + i) for i in range(3)] == [0, 0, 0], "fire family routine idx != 0"
    print("  [ok] $5f:$58dd[0..2] = 0,0,0 (Blaze family shares anim routine 0)")
    # anchor 4: routine table has 8 entries pointing in-bank
    routines = [bv5f.w(ROUTINE_TABLE + i * 2) for i in range(8)]
    assert all(0x4000 <= r < 0x8000 for r in routines), "routine ptr OOB"
    print(f"  [ok] $5f:$58bd routine table = {[hex(r) for r in routines]}")
    return ok


def dump(data):
    for bk, info in data["anim_banks"].items():
        print(f"\n=== animation bank {bk}  (base {info['frame_table_base']}, "
              f"{info['distinct_animations']} distinct of {info['table_slots']} slots) ===")
        for an in info["animations"]:
            print(f"  anim {an['index']} @ {an['subtable']}: {an['frame_count']} frames")
            for fi, fr in enumerate(an["frames"]):
                sp = ", ".join(f"({s['dy']:+d},{s['dx']:+d},t{s['tile']},a{s['attr']:02x})"
                               for s in fr["sprites"])
                print(f"      frame {fi} @ {fr['addr']}: [{sp}]")
    print(f"\n=== $5f:$58bd routines ===\n  {data['routine_table_5f_58bd']}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", default=ROM_PATH)
    ap.add_argument("--count", type=int, default=222, help="skill count for descriptor table")
    ap.add_argument("--dump", action="store_true", help="human-readable frame dump")
    ap.add_argument("--selftest", action="store_true", help="verify ROM anchors")
    ap.add_argument("--no-write", action="store_true")
    args = ap.parse_args()
    rom = load_rom(args.rom)

    if args.selftest:
        print("decode_battle_animations selftest:")
        selftest(rom)
        print("SELFTEST PASS")
        return

    data = build(rom, args.count)
    if args.dump:
        dump(data)
    if not args.no_write:
        with open(OUT, "w") as f:
            json.dump(data, f, indent=1)
        print(f"wrote {OUT} "
              f"({sum(b['distinct_animations'] for b in data['anim_banks'].values())} distinct animations across "
              f"{len(data['anim_banks'])} banks)")


if __name__ == "__main__":
    main()
