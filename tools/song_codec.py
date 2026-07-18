#!/usr/bin/env python3
"""song_codec.py — DWM1 song round-trip codec (M2) + DWM2 GBS extractor (M3 feed).

M2 keystone: decode ALL audio data in banks $1C/$1D/$1E to a structured spec,
re-emit BYTE-IDENTICAL full banks. `--selftest` proves it (exit 0 only if all
three 16 KB banks reproduce exactly, including orphan records, orphan streams,
unreferenced regions, and filler).

Layout model (established empirically S62, 158/158 referenced streams align):
  * bank byte at $4000 (= bank number), records from $4001.
  * record = 4 bytes [state_slot, hw_channel, seq_lo, seq_hi]; reachable ids
    $00-$9D map via the master table @ ROM0 $3466. Bank $1E additionally holds
    FOUR ORPHAN RECORDS at $419D-$41AC (the id-$9E..$A1 slots — the master
    table's open-ended last row still resolves ids >= $9E here; vanilla never
    plays them). Their seq pointers reference four orphan streams at
    $5B5E/$5C54/$5F53/$62C6.
  * stream = 4-byte header + token list. Linear token grammar (byte-exact):
      cmd <  $A0 : 2 bytes  note/rest (noise ch: raw noise-table index)
      $A0-$AF    : 2 bytes  ctl (unknown $Ax = engine no-op)
      $B0-$BF    : 2 bytes  loop ctl (count = cmd & $0F; prm selects ctr A/B)
      $C0-$CF    : 2 bytes  fx (rate/param)
      $D0-$DF    : 2 bytes  pitch slide up
      $E0-$EF    : 2 bytes  pitch slide down
      $FC lo hi  : 3 bytes  jump to PAIR INDEX hi:lo (streams relocatable)
      $FD xx     : 2 bytes  set loop mark
      $FF        : 1 byte   channel end
    Referenced streams tile each bank contiguously; a stream's extent runs to
    the next referenced start. The last/orphan stream extent runs to its first
    terminator ($FF, or a $FC whose target lies at/before the jump itself).
  * everything after the last decoded stream to $7FFF = raw "unreferenced"
    blob (bank $1D/$1E tails contain further unreferenced stream-like data;
    preserved verbatim, deliberately not interpreted).

DWM2 (GBS rip DMG-BQLJ-JPN.gbs, S61): same stream grammar. GBS header $70
bytes, load=$0FA0; master table @ virtual $3DC2; table banks $40..$43 map to
file banks 1..4 (file offset = $70 + ($4000-load) + (bank-$40)*$4000 +
addr-$4000). DWM2 state slots are 32-byte ($00/$20/$40/$60/$80/$A0); a port to
DWM1 rewrites them to DWM1's 26-byte slots ($00/$1A/$34/$4E/$68/$82).

Usage:
  python3 tools/song_codec.py decode   [--rom data/DWM-original.gbc] --out extracted/songs_spec.json
  python3 tools/song_codec.py selftest [--rom data/DWM-original.gbc]
  python3 tools/song_codec.py extract-gbs --gbs FILE --id 0x16 [--out spec.json]
  python3 tools/song_codec.py build-port --gbs FILE --id 0x16 --records-at 0x419D \
          --streams-at 0x6B80 --bank 0x1E [--asm out.inc]
"""
import argparse, hashlib, json, sys
from pathlib import Path

MASTER_TABLE = 0x3466
AUDIO_BANKS = (0x1C, 0x1D, 0x1E)
# --- Custom song bank (M3a, S63) -------------------------------------------
# The extended master table (AudioMasterTableExt @ ROM0 $3FE8, patches/
# bank_000.asm) adds row [base=$9E, ptr=$4001, bank=$74]: custom ids $9E-$FC
# resolve to bank $74 with the exact vanilla-bank layout (bank byte @ $4000,
# records from $4001). Record area is FIXED at 95 slots (ids $9E-$FC,
# $4001-$417C, unassigned slots $00) so adding songs later never relocates
# existing streams; streams start at $4180.
SONG_BANK = 0x74
SONG_BANK_FIRST_ID = 0x9E
SONG_BANK_RECORDS_AT = 0x4001
SONG_BANK_RECORD_SLOTS = 0xFD - SONG_BANK_FIRST_ID  # 95 (ids $9E-$FC; $FD-$FF reserved/sentinels)
SONG_BANK_STREAMS_AT = 0x4180
DWM1_SLOTS = {0: 0x00, 1: 0x1A, 2: 0x34, 3: 0x4E, 4: 0x68, 5: 0x82}
# DWM2 32-byte-state slot -> DWM1 26-byte-state slot (same channel role order)
DWM2_TO_DWM1_SLOT = {0x00: 0x00, 0x20: 0x1A, 0x40: 0x34,
                     0x60: 0x4E, 0x80: 0x68, 0xA0: 0x82}
CTL_NAMES = {0xA0: "envelope", 0xA1: "instrument", 0xA2: "duty_outlevel",
             0xA3: "tempo_groove", 0xA5: "pan_ctl", 0xA6: "nr50",
             0xA7: "rest_hold", 0xA8: "fx_fc", 0xAE: "alt_tuning",
             0xAF: "slide_rate"}

# Canonical DWM2 GBS subsong index -> track name, from the zophar.net GBS rip
# m3u playlist set for DMG-BQLJ-JPN.gbs ("Dragon Warrior Monsters 2 - Cobi's
# Journey (EMU)"); internal ids come from the GBS song map @ $0FC0 (S63).
# BGM numbering is the rip's, NOT subsong order (e.g. BGM #17 = subsong 23).
DWM2_GBS_TRACKS = {
    0: "BGM #01", 1: "BGM #02", 2: "BGM #03", 3: "BGM #04", 4: "BGM #05",
    5: "BGM #06", 6: "BGM #07", 7: "BGM #08", 8: "BGM #09", 9: "BGM #10",
    10: "BGM #11", 11: "BGM #12", 12: "BGM #13", 13: "BGM #14",
    14: "BGM #15", 15: "BGM #16", 16: "Jingle #01", 17: "Jingle #02",
    18: "Jingle #03", 19: "Jingle #04", 20: "Jingle #05", 21: "Jingle #06",
    22: "Jingle #07", 23: "BGM #17", 24: "Jingle #08", 25: "Jingle #09",
    26: "Jingle #10", 27: "Jingle #11", 28: "BGM #18", 29: "BGM #19",
    30: "Jingle #12",
}
DWM2_SONG_MAP_ADDR = 0x0FC0     # GBS: subsong index -> engine-internal id


def dwm2_slug(name):
    """'BGM #07' -> 'dwm2_bgm07'; 'Jingle #03' -> 'dwm2_jingle03'."""
    kind, num = name.split(" #")
    return f"dwm2_{kind.lower()}{int(num):02d}"


# ---------------------------------------------------------------- readers ---
class RomReader:
    """DWM1 ROM: flat file, bank n at n*0x4000, banked addr $4000-$7FFF."""
    def __init__(self, path):
        self.data = Path(path).read_bytes()

    def off(self, bank, addr):
        if bank == 0:
            return addr
        return bank * 0x4000 + (addr - 0x4000)

    def rd(self, bank, addr, n=1):
        o = self.off(bank, addr)
        return self.data[o:o + n]


class GbsReader:
    """DWM2 GBS rip: header $70, load addr from header; table banks $40+k
    live at file banks 1+k."""
    def __init__(self, path):
        self.data = Path(path).read_bytes()
        assert self.data[:3] == b"GBS", "not a GBS file"
        self.load = self.data[6] | self.data[7] << 8
        self.first_bank_off = 0x70 + (0x4000 - self.load)

    def off(self, bank, addr):
        if bank < 0x40:                      # virtual bank-0 region
            return 0x70 + (addr - self.load)
        return self.first_bank_off + (bank - 0x40) * 0x4000 + (addr - 0x4000)

    def rd(self, bank, addr, n=1):
        o = self.off(bank, addr)
        return self.data[o:o + n]


# ------------------------------------------------------------ master table ---
def master_rows(reader, table_addr=MASTER_TABLE):
    rows, o = [], table_addr
    while True:
        b = reader.rd(0, o, 4)
        if b[0] == 0xFF:
            break
        rows.append((b[0], b[1] | b[2] << 8, b[3]))
        o += 4
    return rows


def id_record(reader, rows, sid):
    row = None
    for base, ptr, bank in rows:
        if sid >= base:
            row = (base, ptr, bank)
    base, ptr, bank = row
    b = reader.rd(bank, ptr + (sid - base) * 4, 4)
    return {"id": sid, "slot": b[0], "hw": b[1],
            "seq": b[2] | b[3] << 8, "bank": bank}


# ----------------------------------------------------------- token grammar ---
def decode_tokens(reader, bank, start, end=None):
    """Linear decode from `start`. If `end` given, decode exactly [start,end)
    (multiple terminators allowed inside). If None, stop after the first
    terminator: $FF, or a $FC jumping to a pair at/before itself.
    Returns (header4, tokens, end_addr)."""
    hdr = list(reader.rd(bank, start, 4))
    a = start + 4
    toks = []
    while True:
        if end is not None and a >= end:
            if a != end:
                raise ValueError(f"stream ${start:04X} overran its extent "
                                 f"(at ${a:04X}, extent end ${end:04X})")
            break
        cmd = reader.rd(bank, a)[0]
        if cmd == 0xFF:
            toks.append({"op": "end"})
            a += 1
            if end is None:
                break
            continue
        prm = reader.rd(bank, a + 1)[0]
        if cmd < 0xA0:
            toks.append({"op": "note", "byte": cmd, "len": prm})
        elif 0xB0 <= cmd <= 0xBF and prm == 0xFC:
            # loop-jump form: [Bn][FC] pair + [lo][hi] target pair (4 bytes).
            # Engine (AudioCheckC0..AudioReadPairHL): the Bn's PARAM byte is
            # inspected at AudioCheckFC; $FC takes the jump reading the NEXT
            # pair as the target pair-index; on counter elapse the target
            # pair is skipped (pos+1). B0 = unconditional. There is no
            # standalone 3-byte $FC token (top-level $FC is a 2-byte no-op).
            b = reader.rd(bank, a + 2, 2)
            toks.append({"op": "loop_jump", "n": cmd & 0x0F,
                         "target": b[0] | b[1] << 8})
            a += 4
            back = (start + (b[0] | b[1] << 8) * 2) < a
            if end is None and cmd == 0xB0 and back:
                break
            continue
        elif cmd <= 0xAF:
            t = {"op": "ctl", "byte": cmd, "prm": prm}
            if cmd in CTL_NAMES:
                t["name"] = CTL_NAMES[cmd]
            toks.append(t)
        elif cmd <= 0xBF:
            toks.append({"op": "loop", "n": cmd & 0x0F, "prm": prm})
        elif cmd <= 0xCF:
            toks.append({"op": "fx", "n": cmd & 0x0F, "prm": prm})
        elif cmd <= 0xDF:
            toks.append({"op": "slide_up", "n": cmd & 0x0F, "prm": prm})
        elif cmd <= 0xEF:
            toks.append({"op": "slide_down", "n": cmd & 0x0F, "prm": prm})
        elif cmd == 0xFD:
            toks.append({"op": "mark", "prm": prm})
        else:                       # $F0-$FB, $FE: 2-byte no-op (engine: the
            # AudioCheckFD chain falls to AudioIncHLLoop for any $F0+ byte
            # that is not $FD/$FF; $FC acts as a jump only via the $Bn gate)
            toks.append({"op": "noop_hi", "byte": cmd, "prm": prm})
        a += 2
    return hdr, toks, a


def emit_tokens(hdr, toks):
    out = bytearray(hdr)
    for t in toks:
        op = t["op"]
        if op == "end":
            out.append(0xFF)
        elif op == "loop_jump":
            out += bytes((0xB0 | t["n"], 0xFC,
                          t["target"] & 0xFF, t["target"] >> 8))
        elif op == "note":
            out += bytes((t["byte"], t["len"]))
        elif op == "ctl":
            out += bytes((t["byte"], t["prm"]))
        elif op == "loop":
            out += bytes((0xB0 | t["n"], t["prm"]))
        elif op == "fx":
            out += bytes((0xC0 | t["n"], t["prm"]))
        elif op == "slide_up":
            out += bytes((0xD0 | t["n"], t["prm"]))
        elif op == "slide_down":
            out += bytes((0xE0 | t["n"], t["prm"]))
        elif op == "mark":
            out += bytes((0xFD, t["prm"]))
        elif op == "noop_hi":
            out += bytes((t["byte"], t["prm"]))
        else:
            raise ValueError(f"unknown token op {op!r}")
    return bytes(out)


# ----------------------------------------------------------------- decode ---
def decode_dwm1(reader):
    rows = master_rows(reader)
    records = [id_record(reader, rows, sid) for sid in range(0x9E)]
    spec = {"_generator": "tools/song_codec.py decode vs data/DWM-original.gbc",
            "master_table": [{"base": b, "ptr": p, "bank": bk}
                             for b, p, bk in rows],
            "banks": {}}
    for bank in AUDIO_BANKS:
        recs = [r for r in records if r["bank"] == bank]
        rec_end = 0x4001 + len(recs) * 4
        # orphan records: record-shaped bytes between the reachable records
        # and the first referenced stream (bank $1E: 4 records, ids $9E-$A1)
        starts = sorted({r["seq"] for r in recs})
        orphans = []
        o = rec_end
        while o + 4 <= starts[0]:
            b = reader.rd(bank, o, 4)
            orphans.append({"slot": b[0], "hw": b[1], "seq": b[2] | b[3] << 8})
            o += 4
        if o != starts[0]:
            raise ValueError(f"bank ${bank:02X}: records region does not "
                             f"tile to first stream (${o:04X} vs "
                             f"${starts[0]:04X})")
        all_starts = sorted(set(starts) | {x["seq"] for x in orphans})
        streams = {}
        for i, s in enumerate(all_starts):
            nxt = all_starts[i + 1] if i + 1 < len(all_starts) else None
            hdr, toks, end = decode_tokens(reader, bank, s, nxt)
            streams[f"{s:04X}"] = {"header": hdr, "tokens": toks}
            last_end = end
        tail = reader.rd(bank, last_end, 0x8000 - last_end)
        spec["banks"][f"{bank:02X}"] = {
            "bank_byte": reader.rd(bank, 0x4000)[0],
            "records": [{"id": r["id"], "slot": r["slot"], "hw": r["hw"],
                         "seq": r["seq"]} for r in recs],
            "orphan_records": orphans,
            "streams": streams,
            "unreferenced": {"addr": last_end, "hex": tail.hex()},
        }
    return spec


# ------------------------------------------------------------------- emit ---
def emit_bank(bank_spec):
    img = bytearray()
    img.append(bank_spec["bank_byte"])
    for r in bank_spec["records"] + bank_spec["orphan_records"]:
        img += bytes((r["slot"], r["hw"], r["seq"] & 0xFF, r["seq"] >> 8))
    for addr in sorted(bank_spec["streams"], key=lambda x: int(x, 16)):
        s = bank_spec["streams"][addr]
        if 0x4000 + len(img) != int(addr, 16):
            raise ValueError(f"stream ${addr} does not start where emission "
                             f"reached (${0x4000 + len(img):04X})")
        img += emit_tokens(s["header"], s["tokens"])
    un = bank_spec["unreferenced"]
    if 0x4000 + len(img) != un["addr"]:
        raise ValueError("unreferenced blob does not start where emission "
                         f"reached (${0x4000 + len(img):04X} vs "
                         f"${un['addr']:04X})")
    img += bytes.fromhex(un["hex"])
    if len(img) != 0x4000:
        raise ValueError(f"bank image is {len(img)} bytes, expected 16384")
    return bytes(img)


def selftest(rom_path):
    reader = RomReader(rom_path)
    spec = decode_dwm1(reader)
    ok = True
    n_streams = sum(len(b["streams"]) for b in spec["banks"].values())
    for bk_hex, bank_spec in spec["banks"].items():
        bank = int(bk_hex, 16)
        want = reader.data[bank * 0x4000:(bank + 1) * 0x4000]
        got = emit_bank(bank_spec)
        if got == want:
            print(f"  bank ${bk_hex}: byte-identical "
                  f"({len(bank_spec['streams'])} streams, "
                  f"{len(bank_spec['records'])} records, "
                  f"{len(bank_spec['orphan_records'])} orphan records)")
        else:
            ok = False
            d = next(i for i in range(0x4000) if got[i] != want[i])
            print(f"  bank ${bk_hex}: FAIL first diff at ${0x4000 + d:04X} "
                  f"(got {got[d]:02X} want {want[d]:02X})")
    print(f"selftest: {n_streams} streams decoded; "
          + ("PASS (all banks byte-identical)" if ok else "FAIL"))
    return ok


# -------------------------------------------------------------- GBS side ---
def gbs_master_table_addr(g):
    """DWM2 rip: locate the master table (rows [base,lo,hi,bank] with base
    strictly ascending from 0, ptr $4001, banks ascending from $40)."""
    d = g.data
    for o in range(0x70, min(len(d), 0x70 + 0x4000) - 16):
        if (d[o] == 0x00 and d[o + 1] == 0x01 and d[o + 2] == 0x40
                and d[o + 3] == 0x40 and d[o + 7] == 0x41):
            return g.load + (o - 0x70)
    raise ValueError("GBS master table not found")


# DWM2 driver grammar (RE'd S62 from the GBS driver, sanctioned by ROADMAP
# M3's "fix $AC + header diffs" plan; handlers at GBS $35A7/$361C/$37D8/$381A,
# slot resolver $3D5D):
#   FD slot   : set mark[slot & $0F] = {counter:=0, pos after this pair}
#               (4 slots x 3 bytes per channel @ $DCC0 + ch*12)
#   Bn slot   : n>=1: inc mark counter; while counter < n+1 jump to mark[slot]
#               => the marked section plays n+1 times total
#   B0 $Fx    : unconditional jump to mark[x]; B0 with param < $F0 = no-op
#   AC n, tgt : counted CALL: save return pos, jump to pair (tgt_u16 >> 1);
#               the pair after AC is the 16-bit LE byte-offset target, NOT a
#               command. Phrase plays n times; on countdown exhaustion the
#               target pair is skipped and main flow continues.
#   AD x      : RETURN to the saved AC position (single return slot, no
#               nesting). Phrases live PAST the stream's $FF terminator.
#   headers   : all four fields parse identically to DWM1 (verified: GBS
#               $3503 vs DWM1 header parse) — carried verbatim.
# DWM1-native translation: inline each called phrase at its call site
# (n times), convert slot loops to the Bn/$FC loop-jump form (both engines
# play counted loops n+1 times; B0 = unconditional in both).

def _dwm2_pair(reader, bank, seq, p):
    b = reader.rd(bank, seq + p * 2, 2)
    return b[0], b[1]


def _classify(cmd, prm):
    """Map a non-flow DWM2 pair to a DWM1 token (verbatim bytes)."""
    if cmd < 0xA0:
        return {"op": "note", "byte": cmd, "len": prm}
    if cmd <= 0xAF:
        t = {"op": "ctl", "byte": cmd, "prm": prm}
        if cmd in CTL_NAMES:
            t["name"] = CTL_NAMES[cmd]
        return t
    if cmd <= 0xBF:
        return {"op": "loop", "n": cmd & 0x0F, "prm": prm}
    if cmd <= 0xCF:
        return {"op": "fx", "n": cmd & 0x0F, "prm": prm}
    if cmd <= 0xDF:
        return {"op": "slide_up", "n": cmd & 0x0F, "prm": prm}
    if cmd <= 0xEF:
        return {"op": "slide_down", "n": cmd & 0x0F, "prm": prm}
    return {"op": "noop_hi", "byte": cmd, "prm": prm}


def translate_dwm2_stream(reader, bank, seq, region_end):
    """Walk a DWM2 stream in program order (true DWM2 grammar) and emit an
    equivalent DWM1-native token list. Counted loops become the Bn/$FC
    loop-jump form; counted loops whose body CONTAINS another counted loop
    are UNROLLED (DWM1 has a single $EF counter for the jump form, so
    counted spans must not nest; DWM2 nests freely via per-slot counters).
    Returns (header, tokens)."""
    hdr = list(reader.rd(bank, seq, 4))
    max_pairs = (region_end - seq) // 2

    # ---- stage 1: IR in program order --------------------------------
    # items: ("tok", token) | ("label", lbl) | ("loopn", n, lbl) |
    #        ("jump0", lbl)
    ir = []
    marks = {}                       # slot -> current label
    nlabels = [0]

    def fresh():
        nlabels[0] += 1
        return nlabels[0]

    def walk(p, in_phrase, depth):
        while True:
            if p >= max_pairs:
                raise ValueError(f"walk overran region at pair {p}")
            cmd, prm = _dwm2_pair(reader, bank, seq, p)
            if cmd == 0xFF:
                if in_phrase:
                    raise ValueError("phrase hit $FF before $AD")
                ir.append(("tok", {"op": "end"}))
                return
            if cmd == 0xFD:
                lbl = fresh()
                marks[prm & 0x0F] = lbl
                ir.append(("label", lbl))
                p += 1
                continue
            if cmd == 0xAC:
                if depth >= 1:
                    raise ValueError("nested $AC call (driver has a single "
                                     "return slot; must not happen)")
                lo, hi = _dwm2_pair(reader, bank, seq, p + 1)
                tgt = (lo | hi << 8) >> 1
                for _ in range(max(prm, 1)):
                    walk(tgt, True, depth + 1)
                p += 2
                continue
            if cmd == 0xAD:
                if not in_phrase:
                    raise ValueError("$AD outside a phrase")
                return
            if 0xB0 <= cmd <= 0xBF:
                n = cmd & 0x0F
                if n == 0 and (prm & 0xF0) != 0xF0:
                    p += 1               # DWM2: B0 with param < $F0 = no-op
                    continue
                slot = prm & 0x0F
                if slot not in marks:
                    raise ValueError(f"loop to unset mark slot {slot} "
                                     f"at pair {p}")
                if n == 0:
                    ir.append(("jump0", marks[slot]))
                    if not in_phrase:
                        return           # unconditional jump ends the flow
                else:
                    ir.append(("loopn", n, marks[slot]))
                p += 1
                continue
            ir.append(("tok", _classify(cmd, prm)))
            p += 1

    walk(2, False, 0)
    if not (ir and ir[-1] == ("tok", {"op": "end"})):
        ir.append(("tok", {"op": "end"}))

    # ---- stage 2: unroll counted loops that contain counted loops ----
    def label_index(items, lbl):
        for i, it in enumerate(items):
            if it[0] == "label" and it[1] == lbl:
                return i
        raise ValueError(f"label {lbl} not found")

    def unroll(items):
        changed = True
        while changed:
            changed = False
            for i, it in enumerate(items):
                if it[0] != "loopn":
                    continue
                li = label_index(items, it[2])
                body = items[li + 1:i]
                if not any(b[0] == "loopn" for b in body):
                    continue
                # unroll: body plays n+1 times; inner labels must be
                # per-copy fresh so inner loops bind within their copy
                copies = []
                for _ in range(it[1] + 1):
                    remap = {}
                    for b in body:
                        if b[0] == "label":
                            remap[b[1]] = fresh()
                            copies.append(("label", remap[b[1]]))
                        elif b[0] == "loopn":
                            copies.append(("loopn", b[1],
                                           remap.get(b[2], b[2])))
                        elif b[0] == "jump0":
                            copies.append(("jump0", remap.get(b[1], b[1])))
                        else:
                            copies.append(b)
                items = items[:li] + copies + items[i + 1:]
                changed = True
                break
        return items

    ir = unroll(ir)

    # ---- stage 3: layout (labels -> pair indices) --------------------
    widths = {"end": 1, "loop_jump": 2}
    pos = 2
    label_pos = {}
    for it in ir:
        if it[0] == "label":
            label_pos[it[1]] = pos
        elif it[0] == "tok":
            pos += widths.get(it[1]["op"], 1)
        else:
            pos += 2                     # loopn/jump0 emit loop_jump
    toks = []
    pos = 2
    for it in ir:
        if it[0] == "label":
            continue
        if it[0] == "tok":
            toks.append(it[1])
            pos += widths.get(it[1]["op"], 1)
        elif it[0] == "loopn":
            toks.append({"op": "loop_jump", "n": it[1],
                         "target": label_pos[it[2]]})
            pos += 2
        else:                            # jump0
            toks.append({"op": "loop_jump", "n": 0,
                         "target": label_pos[it[1]]})
            pos += 2

    # ---- stage 4: validate no counted spans nest ---------------------
    spans = []
    pos = 2
    for t in toks:
        w = widths.get(t["op"], 1)
        if t["op"] == "loop_jump" and t["n"] >= 1 and t["target"] < pos:
            spans.append((t["target"], pos))
        pos += w
    for i, (a1, b1) in enumerate(spans):
        for a2, b2 in spans[i + 1:]:
            if not (b1 <= a2 or b2 <= a1):
                raise ValueError(f"counted loop spans still overlap after "
                                 f"unrolling: ({a1},{b1}) vs ({a2},{b2})")
    return hdr, toks


# ------------------------------------------------ trace equivalence proof ---
def _trace_dwm2(reader, bank, seq, region_end, max_events=200000):
    """Execute a DWM2 stream per DWM2 driver semantics; return the ordered
    list of non-flow pairs executed (stops after the outer loop wraps)."""
    max_pairs = (region_end - seq) // 2
    marks = {}
    p, ret, countdown = 2, None, 0
    trace, wraps = [], 0
    while len(trace) < max_events:
        cmd, prm = _dwm2_pair(reader, bank, seq, p)
        if cmd == 0xFF:
            trace.append(("END",))
            break
        if cmd == 0xFD:
            marks[prm & 0x0F] = [0, p + 1]
            p += 1
            continue
        if cmd == 0xAC:
            if countdown == 0:
                countdown = prm
                lo, hi = _dwm2_pair(reader, bank, seq, p + 1)
                ret = p
                p = (lo | hi << 8) >> 1
                continue
            countdown -= 1
            if countdown == 0:
                p += 2
                continue
            lo, hi = _dwm2_pair(reader, bank, seq, p + 1)
            p = (lo | hi << 8) >> 1
            continue
        if cmd == 0xAD:
            p = ret
            continue
        if 0xB0 <= cmd <= 0xBF:
            n = cmd & 0x0F
            if n == 0:
                if (prm & 0xF0) == 0xF0:
                    p = marks[prm & 0x0F][1]
                    wraps += 1
                    if wraps >= 2:
                        trace.append(("WRAP",))
                        break
                    continue
                p += 1
                continue
            m = marks[prm & 0x0F]
            m[0] += 1
            if m[0] < n + 1:
                p = m[1]
            else:
                p += 1
            continue
        trace.append((cmd, prm))
        p += 1
    return trace


def _trace_dwm1(hdr, toks, max_events=200000):
    """Execute a DWM1 token stream per DWM1 engine semantics (loop_jump via
    the $EF counter incl. the elapse pair-skip landing after the target
    pair); return the ordered non-flow trace."""
    blob = emit_tokens(hdr, toks)
    # rebuild a pair-indexed view
    trace, wraps = [], 0
    ef = 0
    p = 2
    while len(trace) < max_events:
        o = p * 2
        cmd = blob[o]
        if cmd == 0xFF:
            trace.append(("END",))
            break
        prm = blob[o + 1]
        if 0xB0 <= cmd <= 0xBF and prm == 0xFC:
            n = cmd & 0x0F
            lo, hi = blob[o + 2], blob[o + 3]
            tgt = lo | hi << 8
            if n == 0:
                p = tgt
                wraps += 1
                if wraps >= 2:
                    trace.append(("WRAP",))
                    break
                continue
            # $EF counter: fresh 0 -> dec wraps to $FF -> reload n, take;
            # then dec to 0 = elapsed -> skip the target pair (pos+1 after
            # the pre-incremented pos, which sits at the target pair)
            ef = (ef - 1) & 0xFF
            if ef == 0:
                p += 2                  # elapse: skip the lo/hi pair
                continue
            if ef & 0x80:
                ef = n
            p = tgt
            continue
        if cmd == 0xFD:
            p += 1                      # DWM1 mark: unused by translation
            continue
        trace.append((cmd, prm))
        p += 1
    return trace


def prove_translation(reader, bank, seq, region_end, hdr, toks):
    t2 = _trace_dwm2(reader, bank, seq, region_end)
    t1 = _trace_dwm1(hdr, toks)
    if t1 != t2:
        n = min(len(t1), len(t2))
        d = next((i for i in range(n) if t1[i] != t2[i]), n)
        raise ValueError(f"trace divergence at event {d}: "
                         f"dwm1={t1[d:d+4]} dwm2={t2[d:d+4]} "
                         f"(lens {len(t1)}/{len(t2)})")
    return len(t1)


def extract_gbs_song(gbs_path, first_id):
    g = GbsReader(gbs_path)
    rows = master_rows(g, gbs_master_table_addr(g))
    # collect all record seqs in the song's bank to bound stream regions
    all_seqs = set()
    for sid in range(0x100):
        try:
            r = id_record(g, rows, sid)
        except Exception:
            break
        if r["bank"] == id_record(g, rows, first_id)["bank"]:
            all_seqs.add(r["seq"])
    chans = []
    sid = first_id
    prev_slot = -1
    while True:
        r = id_record(g, rows, sid)
        if r["slot"] <= prev_slot:
            break
        region_end = min([s for s in all_seqs if s > r["seq"]],
                         default=0x8000)
        hdr, toks = translate_dwm2_stream(g, r["bank"], r["seq"], region_end)
        n_ev = prove_translation(g, r["bank"], r["seq"], region_end,
                                 hdr, toks)
        blob = emit_tokens(hdr, toks)
        chans.append({"id": sid, "slot": r["slot"], "hw": r["hw"],
                      "bank": r["bank"], "seq": r["seq"], "header": hdr,
                      "tokens": toks, "bytes": len(blob),
                      "proved_events": n_ev})
        prev_slot = r["slot"]
        sid += 1
    return {"_generator": f"tools/song_codec.py extract-gbs {gbs_path} "
                          f"--id {first_id:#x} (DWM2->DWM1 translation, "
                          f"trace-equivalence proved)",
            "first_id": first_id, "channels": chans}


def foreign_cmds(chans):
    """Commands whose DWM1 semantics are unverified/no-op (report for the
    user's ear test)."""
    from collections import Counter
    c = Counter()
    for ch in chans:
        for t in ch["tokens"]:
            if t["op"] == "ctl" and "name" not in t:
                c[f"${t['byte']:02X}"] += 1
    return dict(c)


def extract_gbs_library(gbs_path, out_path):
    """Translate + prove EVERY DWM2 subsong into a DWM1-native song library
    (extracted/dwm2_song_library.json): the full inbuilt-DWM2 catalog the
    editor picks from, so the GBS never needs re-uploading. Channels carry
    DWM1 state slots (DWM2_TO_DWM1_SLOT applied) and per-channel proof
    counts; foreign ctl cmds (DWM1 no-ops) are reported per song."""
    import hashlib
    raw = Path(gbs_path).read_bytes()
    load = int.from_bytes(raw[6:8], "little")
    songs = []
    for idx in sorted(DWM2_GBS_TRACKS):
        internal = raw[0x70 + (DWM2_SONG_MAP_ADDR - load) + idx]
        song = extract_gbs_song(gbs_path, internal)
        chans = [{"slot": DWM2_TO_DWM1_SLOT[c["slot"]], "hw": c["hw"],
                  "header": c["header"], "tokens": c["tokens"],
                  "bytes": c["bytes"], "proved_events": c["proved_events"],
                  "dwm2_src": f"${c['bank']:02X}:${c['seq']:04X}"}
                 for c in song["channels"]]
        name = DWM2_GBS_TRACKS[idx]
        songs.append({"id": dwm2_slug(name), "name": name, "gbs_index": idx,
                      "dwm2_internal_id": internal, "channels": chans,
                      "channel_count": len(chans),
                      "total_bytes": sum(c["bytes"] for c in chans),
                      "foreign_cmds": foreign_cmds(song["channels"])})
        print(f"  {name:11s} (gbs {idx:2d}, id ${internal:02X}): "
              f"{len(chans)}ch {songs[-1]['total_bytes']:5d} B, proved "
              f"{[c['proved_events'] for c in chans]}"
              + (f", foreign {songs[-1]['foreign_cmds']}"
                 if songs[-1]["foreign_cmds"] else ""))
    lib = {"_generator": f"tools/song_codec.py extract-gbs-library "
                         f"(DWM2->DWM1 translation, per-channel "
                         f"trace-equivalence proved; slots are DWM1)",
           "_source_gbs": {"file": Path(gbs_path).name,
                           "md5": hashlib.md5(raw).hexdigest()},
           "songs": songs}
    Path(out_path).write_text(json.dumps(lib, indent=1))
    total = sum(s["total_bytes"] for s in songs)
    print(f"wrote {out_path}: {len(songs)} songs, {total} stream bytes "
          f"(bank $74 stream capacity is {0x8000 - SONG_BANK_STREAMS_AT} B — "
          f"the library is a catalog; only ASSIGNED songs are baked)")


# ------------------------------------------------------------- build-port ---
def build_port(gbs_path, first_id, bank, records_at, streams_at):
    song = extract_gbs_song(gbs_path, first_id)
    chans = song["channels"]
    blobs = [emit_tokens(c["header"], c["tokens"]) for c in chans]
    recs, streams, pos = [], [], streams_at
    for c, blob in zip(chans, blobs):
        slot = DWM2_TO_DWM1_SLOT[c["slot"]]
        recs.append((slot, c["hw"], pos))
        streams.append((pos, blob))
        pos += len(blob)
    rec_bytes = b"".join(bytes((s, h, a & 0xFF, a >> 8)) for s, h, a in recs)
    return {"song": song, "records_at": records_at, "record_bytes": rec_bytes,
            "streams": streams, "stream_end": pos, "bank": bank,
            "foreign": foreign_cmds(chans)}


def port_asm(port):
    lines = [f"; --- DWM2 song port (generated by tools/song_codec.py "
             f"build-port) ---",
             f"; records at ${port['records_at']:04X} "
             f"(slots rewritten DWM2->DWM1), streams "
             f"${port['streams'][0][0]:04X}-${port['stream_end'] - 1:04X}, "
             f"bank ${port['bank']:02X}",
             f"; DWM1-foreign ctl cmds (engine no-ops here): "
             f"{port['foreign']}"]
    def db(bs):
        return [f"    db {', '.join(f'${b:02X}' for b in bs[i:i + 16])}"
                for i in range(0, len(bs), 16)]
    lines.append(f"; record trio @ ${port['records_at']:04X}:")
    lines += db(port["record_bytes"])
    for addr, blob in port["streams"]:
        lines.append(f"; stream @ ${addr:04X} ({len(blob)} bytes):")
        lines += db(blob)
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------- bank1e patch ---
def gen_bank1e_patch(rom_path, gbs_path, first_id=0x16,
                     records_at=0x419D, streams_at=0x6B80):
    """Emit a complete patches/bank_01e.asm: the vanilla 16 KB bank as pure
    `db` data with the DWM2 song port applied. Refuses to overwrite anything
    but the expected orphan-record bytes and $00 filler."""
    rom = RomReader(rom_path)
    bank = bytearray(rom.data[0x1E * 0x4000:0x1F * 0x4000])
    port = build_port(gbs_path, first_id, 0x1E, records_at, streams_at)
    rb = port["record_bytes"]
    ro = records_at - 0x4000
    expected_orphans = bytes.fromhex("4e015e5b3400545c4e01535f")
    if bytes(bank[ro:ro + len(rb)]) != expected_orphans[:len(rb)]:
        raise ValueError("orphan-record bytes at $419D are not the expected "
                         "vanilla values — refusing to patch")
    bank[ro:ro + len(rb)] = rb
    so = streams_at - 0x4000
    blob = b"".join(b for _, b in port["streams"])
    if any(bank[so:so + len(blob)]):
        raise ValueError(f"target stream region ${streams_at:04X}+"
                         f"{len(blob)} is not all $00 filler — refusing")
    bank[so:so + len(blob)] = blob
    lines = [
        "; =============================================================================",
        "; BANK $1E — vanilla audio data bank + DWM2 song port (S62)",
        "; GENERATED by tools/song_codec.py patch-bank1e — do not hand-edit data;",
        "; regenerate instead. Whole bank emitted as data (the clean disassembly's",
        "; bank_01e.asm is raw mgbdis with audio data misassembled as instructions).",
        ";",
        f"; Port: DWM2 BGM #06 (GBS internal id $16) -> DWM1 ids $9E/$9F/$A0.",
        f";   record trio  @ ${records_at:04X} (overwrites the vanilla orphan",
        ";                   records — the id-$9E..$A0 slots the master table's",
        ";                   open last row already resolves; no ROM0 changes)",
        f";   streams      @ ${streams_at:04X}-${streams_at + len(blob) - 1:04X} "
        f"({len(blob)} bytes, in vanilla $00 filler)",
        f";   state slots rewritten DWM2 32-byte -> DWM1 26-byte "
        f"($40/$60/$80 -> $34/$4E/$68)",
        f";   DWM1-foreign ctl cmds carried verbatim (engine 2-byte no-ops): "
        f"{port['foreign']}",
        "; Everything else in this bank is byte-identical to vanilla.",
        "; =============================================================================",
        "",
        'SECTION "ROM Bank $01e", ROMX[$4000], BANK[$1e]',
        "",
    ]
    for i in range(0, 0x4000, 16):
        chunk = bank[i:i + 16]
        addr = 0x4000 + i
        tag = ""
        if addr == records_at & 0xFFF0 or (records_at & 0xFFF0) == addr:
            tag = "  ; DWM2 port records begin in this row"
        if addr == streams_at & 0xFFF0:
            tag = "  ; DWM2 port streams begin in this row"
        lines.append("    db " + ", ".join(f"${b:02X}" for b in chunk) + tag)
    return "\n".join(lines) + "\n", port


# ------------------------------------------------------- custom song bank ---
def parse_patch_asm(path):
    """Parse a pure-`db` full-bank patch (e.g. the S62 bank_01e.asm) back
    into its 16 KB image. Only `db $XX, ...` lines carry bytes."""
    img = bytearray()
    for line in Path(path).read_text().splitlines():
        s = line.split(";")[0].strip()
        if not s.startswith("db "):
            continue
        for tok in s[3:].split(","):
            tok = tok.strip()
            if tok.startswith("$"):
                img.append(int(tok[1:], 16))
    if len(img) != 0x4000:
        raise ValueError(f"{path}: parsed {len(img)} bytes, expected 16384")
    return bytes(img)


class ImageReader:
    """Reader over a single parsed bank image (banked addrs $4000-$7FFF)."""
    def __init__(self, img, bank):
        self.img, self.bank = img, bank

    def rd(self, bank, addr, n=1):
        assert bank == self.bank
        return self.img[addr - 0x4000:addr - 0x4000 + n]


def import_port(asm_path, bank, records_at, first_id, n_channels):
    """Recover a ported song (records + decoded streams) from a generated
    full-bank patch .asm into the song-library channel format (the same
    shape extract-gbs emits). Streams re-emit byte-identically (M2
    round-trip property), so this migration is lossless."""
    img = parse_patch_asm(asm_path)
    reader = ImageReader(img, bank)
    chans = []
    for k in range(n_channels):
        b = reader.rd(bank, records_at + k * 4, 4)
        slot, hw, seq = b[0], b[1], b[2] | b[3] << 8
        hdr, toks, end = decode_tokens(reader, bank, seq)
        # The S62 translator emits an unreachable safety $FF after a final
        # backward loop_jump; decode_tokens stops at the jump. Re-append it
        # so the migrated stream is byte-identical to the trace-proven blob.
        if toks[-1]["op"] != "end" and reader.rd(bank, end)[0] == 0xFF:
            toks.append({"op": "end"})
        blob = emit_tokens(hdr, toks)
        if bytes(blob) != bytes(reader.rd(bank, seq, len(blob))):
            raise ValueError(f"channel {k}: round-trip mismatch @ ${seq:04X}")
        chans.append({"slot": slot, "hw": hw, "header": hdr,
                      "tokens": toks, "bytes": len(blob)})
    return {"first_id": first_id, "channels": chans}


def emit_song_bank(library):
    """library = {"songs": [{"id", "first_id", "channels": [...]}, ...]}.
    Emits the full bank $74 image: bank byte, fixed 95-slot record area
    ($00 = unassigned), streams tiled from SONG_BANK_STREAMS_AT."""
    img = bytearray(0x4000)
    img[0] = SONG_BANK
    pos = SONG_BANK_STREAMS_AT
    placements = []
    for song in library["songs"]:
        fid = song["first_id"]
        for k, c in enumerate(song["channels"]):
            sid = fid + k
            if not (SONG_BANK_FIRST_ID <= sid <= 0xFC):
                raise ValueError(f"song id ${sid:02X} outside $9E-$FC")
            ro = (SONG_BANK_RECORDS_AT - 0x4000) + (sid - SONG_BANK_FIRST_ID) * 4
            if any(img[ro:ro + 4]):
                raise ValueError(f"record slot for id ${sid:02X} already used")
            blob = emit_tokens(c["header"], c["tokens"])
            img[ro:ro + 4] = bytes((c["slot"], c["hw"],
                                    pos & 0xFF, pos >> 8))
            img[pos - 0x4000:pos - 0x4000 + len(blob)] = blob
            placements.append((sid, pos, len(blob)))
            pos += len(blob)
    if pos > 0x8000:
        raise ValueError(f"streams overflow bank ${SONG_BANK:02X} "
                         f"(end ${pos:04X})")
    return bytes(img), placements, pos


def song_bank_asm(library):
    img, placements, end = emit_song_bank(library)
    names = ", ".join(f"{s.get('id','?')} (ids ${s['first_id']:02X}+)"
                      for s in library["songs"])
    lines = [
        "; =============================================================================",
        f"; BANK $74 — custom song bank (M3a, S63)",
        "; GENERATED by tools/song_codec.py emit-song-bank — do not hand-edit;",
        f";   regenerate from {library.get('_source', 'the song library JSON')}.",
        ";",
        "; Resolved by AudioMasterTableExt (ROM0 $3FE8, patches/bank_000.asm) row",
        f";   [base=${SONG_BANK_FIRST_ID:02X}, ptr=${SONG_BANK_RECORDS_AT:04X}, bank=${SONG_BANK:02X}] — custom ids ${SONG_BANK_FIRST_ID:02X}-$FC.",
        f"; Layout (vanilla audio-bank convention): $4000 bank byte; $4001-$417C",
        f";   fixed {SONG_BANK_RECORD_SLOTS}-slot record area ($00 = unassigned id); streams from",
        f";   ${SONG_BANK_STREAMS_AT:04X} (fixed record area => adding songs never moves old streams).",
        f"; Songs: {names}",
        f"; Stream bytes end ${end - 1:04X}; free ${end:04X}-$7FFF ({0x8000 - end} bytes).",
        "; =============================================================================",
        "",
        'SECTION "ROM Bank $074", ROMX[$4000], BANK[$74]',
        "",
    ]
    pl = {p[1]: (p[0], p[2]) for p in placements}
    for i in range(0, 0x4000, 16):
        addr = 0x4000 + i
        tag = ""
        if addr == SONG_BANK_RECORDS_AT & 0xFFF0:
            tag = "  ; record area begins ($4001)"
        for a in range(addr, addr + 16):
            if a in pl:
                tag = f"  ; id ${pl[a][0]:02X} stream @ ${a:04X} ({pl[a][1]} B)"
        chunk = img[i:i + 16]
        lines.append("    db " + ", ".join(f"${b:02X}" for b in chunk) + tag)
    return "\n".join(lines) + "\n"


# ------------------------------------------------------------------- main ---
def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    d = sub.add_parser("decode")
    d.add_argument("--rom", default="data/DWM-original.gbc")
    d.add_argument("--out", default="extracted/songs_spec.json")
    s = sub.add_parser("selftest")
    s.add_argument("--rom", default="data/DWM-original.gbc")
    e = sub.add_parser("extract-gbs")
    e.add_argument("--gbs", required=True)
    e.add_argument("--id", type=lambda x: int(x, 0), required=True)
    e.add_argument("--out", default=None)
    p = sub.add_parser("build-port")
    p.add_argument("--gbs", required=True)
    p.add_argument("--id", type=lambda x: int(x, 0), required=True)
    p.add_argument("--bank", type=lambda x: int(x, 0), default=0x1E)
    p.add_argument("--records-at", type=lambda x: int(x, 0), default=0x419D)
    p.add_argument("--streams-at", type=lambda x: int(x, 0), default=0x6B80)
    p.add_argument("--asm", default=None)
    q = sub.add_parser("patch-bank1e")   # historical (S62 orphan-slot route, retired by M3a)
    q.add_argument("--rom", default="data/DWM-original.gbc")
    q.add_argument("--gbs", required=True)
    q.add_argument("--id", type=lambda x: int(x, 0), default=0x16)
    q.add_argument("--out", default="patches/bank_01e.asm")
    i = sub.add_parser("import-port")    # one-shot S62->S63 migration helper
    i.add_argument("--asm", required=True)
    i.add_argument("--bank", type=lambda x: int(x, 0), default=0x1E)
    i.add_argument("--records-at", type=lambda x: int(x, 0), default=0x419D)
    i.add_argument("--first-id", type=lambda x: int(x, 0), default=0x9E)
    i.add_argument("--channels", type=int, default=3)
    i.add_argument("--song-id", default="imported")
    i.add_argument("--library", default="extracted/midi_song_library.json")
    b = sub.add_parser("emit-song-bank")
    b.add_argument("--library", default="extracted/midi_song_library.json")
    b.add_argument("--out", default="patches/bank_074.asm")
    gl = sub.add_parser("extract-gbs-library")  # ALL subsongs -> DWM1-native catalog (S64, M3b)
    gl.add_argument("--gbs", required=True)
    gl.add_argument("--out", default="extracted/dwm2_song_library.json")
    # NOTE (S64): extracted/custom_songs.json is RETIRED — song ownership
    # moved to project.json custom.music + the repo-committed library JSONs
    # (extracted/dwm2_song_library.json, extracted/midi_song_library.json);
    # the editor2 music emitter calls song_bank_asm directly. The --library
    # defaults below now point at the MIDI library for ad-hoc use.
    a2 = sub.add_parser("add-gbs-song")   # extract-gbs + DWM2->DWM1 slot map + library append
    a2.add_argument("--gbs", required=True)
    a2.add_argument("--id", type=lambda x: int(x, 0), required=True,
                    help="DWM2 internal id (GBS song map @ $0FC0[gbs_index])")
    a2.add_argument("--first-id", type=lambda x: int(x, 0), required=True,
                    help="DWM1 id for channel 0 (>= 0x9E)")
    a2.add_argument("--song-id", required=True)
    a2.add_argument("--library", default="extracted/midi_song_library.json")
    args = ap.parse_args()

    if args.cmd == "decode":
        spec = decode_dwm1(RomReader(args.rom))
        Path(args.out).write_text(json.dumps(spec, indent=1))
        n = sum(len(b["streams"]) for b in spec["banks"].values())
        print(f"wrote {args.out}: {n} streams across banks "
              + ", ".join(f"${k}" for k in spec["banks"]))
    elif args.cmd == "selftest":
        sys.exit(0 if selftest(args.rom) else 1)
    elif args.cmd == "extract-gbs":
        song = extract_gbs_song(args.gbs, args.id)
        print(f"song first_id ${song['first_id']:02X}: "
              f"{len(song['channels'])} channels, "
              f"{sum(c['bytes'] for c in song['channels'])} bytes; "
              f"DWM1-foreign cmds: {foreign_cmds(song['channels'])}")
        if args.out:
            Path(args.out).write_text(json.dumps(song, indent=1))
            print(f"wrote {args.out}")
    elif args.cmd == "build-port":
        port = build_port(args.gbs, args.id, args.bank,
                          args.records_at, args.streams_at)
        total = port["stream_end"] - port["streams"][0][0]
        print(f"port: {len(port['streams'])} streams, {total} stream bytes "
              f"@ ${port['streams'][0][0]:04X}-${port['stream_end'] - 1:04X} "
              f"bank ${port['bank']:02X}; records "
              f"@ ${port['records_at']:04X}; foreign: {port['foreign']}")
        if args.asm:
            Path(args.asm).write_text(port_asm(port))
            print(f"wrote {args.asm}")
    elif args.cmd == "patch-bank1e":
        text, port = gen_bank1e_patch(args.rom, args.gbs, args.id)
        Path(args.out).write_text(text)
        blob = sum(len(b) for _, b in port["streams"])
        print(f"wrote {args.out}: full bank $1E as data + port "
              f"({blob} stream bytes @ $6B80, records @ $419D, "
              f"foreign {port['foreign']})")
    elif args.cmd == "import-port":
        song = import_port(args.asm, args.bank, args.records_at,
                           args.first_id, args.channels)
        song["id"] = args.song_id
        p = Path(args.library)
        lib = json.loads(p.read_text()) if p.exists() else {
            "_generator": "tools/song_codec.py import-port / emit-song-bank "
                          "(M3a song library; superseded by project.json in M3b)",
            "songs": []}
        lib["songs"] = [s for s in lib["songs"] if s.get("id") != args.song_id]
        lib["songs"].append(song)
        lib["songs"].sort(key=lambda s: s["first_id"])
        p.write_text(json.dumps(lib, indent=1))
        print(f"imported '{args.song_id}' (ids ${args.first_id:02X}+"
              f"{len(song['channels'])-1}, "
              f"{sum(c['bytes'] for c in song['channels'])} stream bytes) "
              f"-> {args.library} ({len(lib['songs'])} songs)")
    elif args.cmd == "emit-song-bank":
        lib = json.loads(Path(args.library).read_text())
        lib["_source"] = args.library
        text = song_bank_asm(lib)
        Path(args.out).write_text(text)
        img, placements, end = emit_song_bank(lib)
        print(f"wrote {args.out}: {len(lib['songs'])} songs, "
              f"{len(placements)} streams, streams end ${end - 1:04X}, "
              f"free {0x8000 - end} bytes")
    elif args.cmd == "extract-gbs-library":
        extract_gbs_library(args.gbs, args.out)
    elif args.cmd == "add-gbs-song":
        song = extract_gbs_song(args.gbs, args.id)
        chans = [{"slot": DWM2_TO_DWM1_SLOT[c["slot"]], "hw": c["hw"],
                  "header": c["header"], "tokens": c["tokens"],
                  "bytes": c["bytes"], "proved_events": c["proved_events"],
                  "dwm2_src": f"${c['bank']:02X}:${c['seq']:04X}"}
                 for c in song["channels"]]
        entry = {"id": args.song_id, "first_id": args.first_id,
                 "channels": chans,
                 "dwm2_internal_id": song["first_id"],
                 "foreign_cmds": foreign_cmds(song["channels"])}
        p = Path(args.library)
        lib = json.loads(p.read_text()) if p.exists() else {
            "_generator": "tools/song_codec.py import-port / add-gbs-song / "
                          "emit-song-bank (M3a song library; superseded by "
                          "project.json in M3b)", "songs": []}
        lib["songs"] = [s for s in lib["songs"] if s.get("id") != args.song_id]
        lib["songs"].append(entry)
        lib["songs"].sort(key=lambda s: s["first_id"])
        p.write_text(json.dumps(lib, indent=1))
        print(f"added '{args.song_id}': DWM2 id ${song['first_id']:02X} -> "
              f"DWM1 ids ${args.first_id:02X}-"
              f"${args.first_id + len(chans) - 1:02X}, "
              f"{sum(c['bytes'] for c in chans)} stream bytes, "
              f"proved {[c['proved_events'] for c in chans]} events, "
              f"foreign {entry['foreign_cmds']}")


if __name__ == "__main__":
    main()
