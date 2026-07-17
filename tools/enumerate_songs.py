#!/usr/bin/env python3
"""enumerate_songs.py — DWM1 sound engine song enumerator + stream decoder (M1).

Engine facts (verified against disassembly/bank_000.asm, S61):
  * Master sound table @ ROM0 $3466: rows [base_id, ptr_lo, ptr_hi, bank],
    terminated by base $FF. Lookup: first row whose base > id; use PREVIOUS row.
      $00-$20 -> $1C:$4001, $21-$36 -> $1D:$4001, $37-$9D -> $1E:$4001
  * Per-id record @ bank:$4001 + (id-base)*4: [state_slot, hw_channel, seq_lo, seq_hi]
    state_slot in {$00,$1A,$34,$4E,$68,$82} = 6x 26-byte channel blocks @ $DD80.
    hw_channel 0-3 = pulse1/pulse2/wave/noise. A multi-channel sound occupies
    CONSECUTIVE ids (AudioProcess increments $DE24; AudioUpdate1x/2x/3x chain).
  * Stream: 4-byte in-stream header, then 2-byte (cmd,param) pairs.
    Position is a PAIR INDEX: addr = seq_base + pos*2 (AudioGetEnvelope:
    add hl,hl). Initial pos = 2 (skips the header).
  * Pairs: cmd < $A0        note: low nibble = semitone 0-11 (>=$0C = rest/off,
                            noise ch: raw index into $37C5 table, $1F = rest),
                            high nibble = octave downshift; param = length ticks.
           $A0 xx           envelope/keyoff ctl (xx swapped -> $EB)
           $A1 xx           instrument: wave ch = wave id (16B from $316E+xx*16
                            -> FF30), pulse = value -> $ED
           $A2 xx           pulse duty (bits 7-6 of $E9) / wave out-level ($F1)
           $A3 xx           tempo/groove: bit7=0: (xx&$0F)*2 -> tick reload
                            $FA/$FB, bits 4-6 -> $E5 high | $80
           $A5 xx           $F9 pan/enable mask ctl (xx=$01: swap current)
           $A6 xx           NR50 master volume direct
           $A7 xx           rest: xx -> length counter $EC, no retrigger
           $A8 xx           $FC (unk fx)
           $AE xx           $E9 bit4 = alt tuning half (+$18 into note table)
           $AF xx           $E9 low nibble = per-frame pitch-slide rate
           $B1-$BF xx       loop ctl: n=cmd&$0F is the repeat count; param
                            selects counter $EE (xx=0) or $EF (xx!=0); on
                            elapsed falls through, else jumps to $FD mark /
                            $FC target
           $B0 $FC lo hi    jump: set pos = hi<<8|lo (pair index)   [3 bytes,
                            self-realigning since next fetch recomputes addr]
           $C0-$CF xx       vibrato/effect: rate=(cmd&$0F)<<4 -> $F0, xx -> $F1
           $D0-$DF xx       pitch slide up   (cmd&$0F)  -> $F3, xx -> $F4/$F5
           $E0-$EF xx       pitch slide down (-(cmd&$0F))-> $F3, xx -> $F4/$F5
           $FD xx           set loop mark = current pos ($F8/$FE)
           $FF              channel end (pos := $FFFF, sweep off)
  * Note pitch table @ ROM0 $3A53 (24 words: 12 + 12 alt), noise table @ $37C5,
    wave instruments @ ROM0 $316E (16 bytes each).

Usage:
  python3 tools/enumerate_songs.py [--rom data/DWM-original.gbc] [--decode ID]
  python3 tools/enumerate_songs.py --json extracted/songs.json
"""
import argparse, hashlib, json, sys
from pathlib import Path

MASTER_TABLE = 0x3466
NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
SLOT_NAMES = {0x00: "SE0", 0x1A: "SE1", 0x34: "BGM-A", 0x4E: "BGM-B",
              0x68: "BGM-C", 0x82: "BGM-D"}
HW = ["pulse1", "pulse2", "wave", "noise"]


def read_rom(path):
    data = Path(path).read_bytes()
    return data


def ba(bank, addr):
    return bank * 0x4000 + (addr - 0x4000)


def master_rows(rom):
    rows = []
    o = MASTER_TABLE
    while True:
        base, lo, hi, bank = rom[o:o + 4]
        if base == 0xFF:
            break
        rows.append((base, lo | hi << 8, bank))
        o += 4
    return rows


def id_record(rom, rows, sid):
    row = None
    for base, ptr, bank in rows:
        if sid >= base:
            row = (base, ptr, bank)
    base, ptr, bank = row
    o = ba(bank, ptr) + (sid - base) * 4
    slot, hwch, lo, hi = rom[o:o + 4]
    return {"id": sid, "slot": slot, "hw": hwch, "seq": lo | hi << 8,
            "bank": bank}


def walk_stream(rom, bank, seq):
    """Walk one channel stream; return (byte_ranges, events, terminated)."""
    events = []
    visited = set()
    pos = 2                      # engine starts at pair index 2 (skips header)
    maxpos = 2
    terminated = None
    hdr = [rom[ba(bank, seq) + i] for i in range(4)]
    while True:
        if pos in visited:
            terminated = "loop"
            break
        visited.add(pos)
        maxpos = max(maxpos, pos)
        a = ba(bank, seq + pos * 2)
        if a >= len(rom) or (a // 0x4000) != bank:
            terminated = "overrun"
            break
        cmd, prm = rom[a], rom[a + 1]
        if cmd == 0xFF:
            events.append((pos, "END", cmd, None))
            terminated = "end"
            break
        if cmd == 0xFD:
            events.append((pos, "MARK", cmd, prm))
            pos += 1
            continue
        if cmd == 0xFC:
            # 3-byte jump: FC lo hi  (only reachable via $B0-gate in engine,
            # but appears standalone in data; next fetch recomputes addr)
            lo, hi = rom[a + 1], rom[a + 2]
            tgt = lo | hi << 8
            events.append((pos, "JUMP", cmd, tgt))
            pos = tgt
            continue
        if 0xB0 <= cmd <= 0xBF:
            # loop ctl consumes its pair; the *engine* then inspects the next
            # byte for $FC/mark-return. Statically we take both arms: record
            # and continue linearly (the $FC that follows is walked when hit).
            events.append((pos, f"LOOPx{cmd & 0x0F}", cmd, prm))
            pos += 1
            continue
        if cmd >= 0xA0:
            events.append((pos, f"CTL{cmd & 0xFF:02X}", cmd, prm))
            pos += 1
            continue
        events.append((pos, "NOTE", cmd, prm))
        pos += 1
    lo_addr = seq
    hi_addr = seq + maxpos * 2 + 2
    return hdr, (lo_addr, hi_addr), events, terminated


def group_sounds(records):
    """Consecutive ids with strictly increasing slots form one sound."""
    groups, cur = [], []
    for r in records:
        if cur and r["slot"] <= cur[-1]["slot"]:
            groups.append(cur)
            cur = []
        cur.append(r)
    if cur:
        groups.append(cur)
    return groups


def fmt_note(cmd, prm, hw):
    if hw == 3:
        return f"noise[{cmd:02X}] len={prm}"
    semi, octd = cmd & 0x0F, cmd >> 4
    if semi >= 0x0C:
        return f"rest len={prm}"
    return f"{NOTE_NAMES[semi]}(oct-{octd}) len={prm}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", default="data/DWM-original.gbc")
    ap.add_argument("--decode", type=lambda x: int(x, 0), default=None,
                    help="decode all channels of the sound containing this id")
    ap.add_argument("--json", default=None, help="write enumeration JSON here")
    args = ap.parse_args()

    rom = read_rom(args.rom)
    rows = master_rows(rom)
    print(f"master table @ ${MASTER_TABLE:04X}: "
          + ", ".join(f"ids>=${b:02X} -> ${bk:02X}:{p:04X}"
                      for b, p, bk in rows))

    records = [id_record(rom, rows, sid) for sid in range(0x00, 0x9E)]
    groups = group_sounds(records)

    out = []
    for gi, g in enumerate(groups):
        chans = []
        for r in g:
            hdr, (lo, hi), events, term = walk_stream(rom, r["bank"], r["seq"])
            n_notes = sum(1 for e in events if e[1] == "NOTE")
            chans.append({
                "id": r["id"], "slot": SLOT_NAMES.get(r["slot"], hex(r["slot"])),
                "hw": HW[r["hw"]], "bank": r["bank"], "seq": r["seq"],
                "end": hi, "bytes": hi - lo, "header": hdr,
                "notes": n_notes, "terminated": term,
            })
        out.append({"sound": gi, "first_id": g[0]["id"], "channels": chans})

    n_bad = 0
    for s in out:
        ids = f"${s['channels'][0]['id']:02X}-${s['channels'][-1]['id']:02X}"
        kind = "BGM" if s["channels"][0]["slot"].startswith("BGM") else "SE "
        spans = ", ".join(f"{c['hw']}@${c['bank']:02X}:{c['seq']:04X}"
                          f"+{c['bytes']}B[{c['terminated']}]"
                          for c in s["channels"])
        for c in s["channels"]:
            if c["terminated"] == "overrun":
                n_bad += 1
        print(f"sound {s['sound']:3d} ids {ids} {kind}: {spans}")

    print(f"\n{len(out)} sounds, {len(records)} channel streams, "
          f"{n_bad} overruns")

    if args.decode is not None:
        for s in out:
            if any(c["id"] == args.decode for c in s["channels"]):
                for c in s["channels"]:
                    r = next(x for x in records if x["id"] == c["id"])
                    hdr, span, events, term = walk_stream(rom, r["bank"],
                                                          r["seq"])
                    print(f"\n== id ${c['id']:02X} {c['hw']} "
                          f"${c['bank']:02X}:{c['seq']:04X} header="
                          + " ".join(f"{b:02X}" for b in hdr))
                    for pos, kind, cmd, prm in events:
                        if kind == "NOTE":
                            txt = fmt_note(cmd, prm, r["hw"])
                        else:
                            txt = f"{kind} {'' if prm is None else hex(prm)}"
                        print(f"  {pos:5d}: {cmd:02X} {txt}")

    if args.json:
        payload = {
            "_generator": "tools/enumerate_songs.py vs data/DWM-original.gbc "
                          f"(md5 {hashlib.md5(rom).hexdigest()})",
            "master_table": MASTER_TABLE, "sounds": out,
        }
        Path(args.json).write_text(json.dumps(payload, indent=1))
        print(f"wrote {args.json}")

    return 1 if n_bad else 0


if __name__ == "__main__":
    sys.exit(main())
