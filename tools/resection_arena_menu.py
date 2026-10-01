#!/usr/bin/env python3
"""
resection_arena_menu.py — S109 (ROADMAP P3.10b, Iron Rule 6): annotate the
ARENA CLASS-REGISTRATION MENU of bank $09 in BOTH trees, zero byte change
(clean build stays 1ca6579…; the patched copy gets the identical text, the
compiler then wraps the fee table in the region `gd_arena_fees`).

What it does (all decoded S109, PyBoy-measured on the user's save — SIDEQUEST_MAP
"Arena / gate-boss ROSTER format", section "The class-registration menu"):

  * `label9_4005` (bank $09 entry 0) dispatches on $C8EF, the SCREEN-EFFECT
    type set by script opcode $04 (`TriggerScreenEffect type, text`): the
    16-word table after its `rst $00` was mgbdis fake code -> `ScreenEffectTable09`
    (type 4 = the arena class menu — Arena Lobby script 6 runs `$04 $0004 $0710`).
  * `ArenaClassMenu` ($5B64, was unlabeled): the outer 5-state machine on $C905
    (+ its rst $00 table) and the inner 9-state machine on $C906
    (`ArenaClassMenuRun`, was Jump_009_5c0a) + table, every state labelled.
  * data decoded as code -> db / dw rows:
      $5D1B ArenaClassLetterTable   8 glyphs  G F E D C B A S
      $5D23 ArenaClassFeeTable      8 words   the entry fee per class (G..S)
      $5DA2 ArenaMenuCursorTable    the class cursor table (column word + 4 rows + $FFFF)
      $5EA1 ArenaYesNoCursorTable   the YES/NO cursor table (2 rows + $FFFF)
  * routine renames (references updated in both trees):
      SetFld9_5c28 -> ArenaMenuMarkWon      CallFld9_5c53 -> ArenaMenuDraw
      SetFld9_5c97 -> ArenaMenuDrawLetters  SaveFld9_5cce -> ArenaMenuPutLetter
      SetFld9_5ce0 -> ArenaMenuDrawFees     SaveFld9_5cfb -> ArenaMenuPutFee
      Jump_009_5c0a -> ArenaClassMenuRun

Method: probe-build line addresses (resection_monster_art_tables.probe_map),
spans replaced by the exact ROM bytes, a byte-perfect clean build asserted.
Idempotent (refuses when `ArenaClassFeeTable:` already exists).

Run:  python3 tools/resection_arena_menu.py
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
sys.path.insert(0, os.path.join(REPO, "tools"))
import resection_monster_art_tables as R   # noqa: E402

CLEAN = os.path.join(REPO, "disassembly", "bank_009.asm")
PATCH = os.path.join(REPO, "patches", "bank_009.asm")
BANK = 0x09

RENAMES = [("Jump_009_5c0a", "ArenaClassMenuRun"),
           ("SetFld9_5c28", "ArenaMenuMarkWon"),
           ("CallFld9_5c53", "ArenaMenuDraw"),
           ("SetFld9_5c97", "ArenaMenuDrawLetters"),
           ("SaveFld9_5cce", "ArenaMenuPutLetter"),
           ("SetFld9_5ce0", "ArenaMenuDrawFees"),
           ("SaveFld9_5cfb", "ArenaMenuPutFee")]

CLASSES = "GFEDCBAS"

# label + comment block inserted before the instruction at an address
STATE_LABELS = {
    0x5B72: ("ArenaClassMenu_S0Window",
             ["; outer state 0: menu window position from HRAM $B7/$BB -> $C909/$C90A,",
              "; border tiles to VRAM $8800"]),
    0x5BBA: ("ArenaClassMenu_S1", ["; outer state 1: one frame"]),
    0x5BBF: ("ArenaClassMenu_S2Cursor",
             ["; outer state 2: inner state := 0, cursor := the next class to win:",
              "; $C8E2 (row) = [$CAB4] & 3, $C8E3 (column) = 1 when [$CAB4] >= 4",
              "; ($CAB4 = arena progress tier = classes won, Arena Lobby scr0)"]),
    0x5BF1: ("ArenaClassMenu_S3Run", ["; outer state 3: the inner machine runs until it advances $C905"]),
    0x5BF4: ("ArenaClassMenu_S4Close",
             ["; outer state 4: restore the screen, clear wGameState bit 4 (screen effect",
              "; done) and $C905 -> the script resumes"]),
    0x5C20: ("ArenaClassMenu_State0",
             ["; inner state 0: ArenaMenuMarkWon, next"]),
    0x5C43: ("ArenaClassMenu_State1",
             ["; inner state 1 (after text): draw letters, fees, gold, cursor; next"]),
    0x5D33: ("ArenaClassMenu_State2",
             ["; inner state 2 = the class SELECTION: cursor over 2 columns x 4 rows",
              "; (column $C8E3: G F E D | C B A S; row $C8E2). A on a class whose",
              "; ArenaMenuMarkWon byte is $90 (not won yet) -> state 3; on a won class",
              "; ($AC, the star) -> menu message 6 and state 8. B -> wColiseumBattle := $FF",
              "; (the lobby script's 'Better luck next time' path) and leave."]),
    0x5DAE: ("ArenaClassMenu_State3",
             ["; inner state 3 = the GOLD CHECK: gold (24-bit $CA4B-$CA4D) minus",
              "; ArenaClassFeeTable[4*col + row] (16-bit). Short -> menu message 5 and",
              "; state 8; else $C180 = the class letter (+$F0 end) for message 4",
              "; ('<class> class?') and state 4."]),
    0x5E0A: ("ArenaClassMenu_State4", ["; inner state 4: draw the YES/NO box (cursor $C8DE = YES)"]),
    0x5E2E: ("ArenaClassMenu_State5",
             ["; inner state 5 = YES/NO. B or NO ($C8DE = $81) -> redraw, message 1, back",
              "; to state 2. YES -> `call AddGold` with HL = the fee, E = 0: despite its",
              "; name the ROM0 routine SUBTRACTS (CompareGoldHL: gold - C:D:E, floor 0;",
              "; PyBoy S109: 3800 -> 3750 for E class), then wArenaGroup := 4*col + row",
              "; (the class 0-7 = G..S), next."]),
    0x5EA7: ("ArenaClassMenu_State6", ["; inner state 6: next"]),
    0x5EAC: ("ArenaClassMenu_State7", ["; inner state 7 (after text): outer state 4 = close"]),
    0x5EB6: ("ArenaClassMenu_State8",
             ["; inner state 8 (after the message of a refused choice): redraw,",
              "; message 1, back to state 1"]),
}

ROUTINE_HEADERS = {
    "ArenaMenuMarkWon": [
        "; ArenaMenuMarkWon: $C0D8[0..7] := $90 (selectable), then the first [$CAB4]",
        "; classes := $AC (the star glyph = already won). $CAB4 = classes won."],
    "ArenaMenuDraw": [
        "; ArenaMenuDraw: the menu window, the fee column (ArenaMenuDrawFees), the",
        "; player's gold, the cursor (ArenaMenuCursorTable)."],
    "ArenaMenuDrawLetters": [
        "; ArenaMenuDrawLetters: the four class letters of column [$C8E3]",
        "; (ArenaClassLetterTable) to VRAM $8800 and their four won/selectable",
        "; marks ($C0D8) to $8840."],
    "ArenaMenuPutLetter": ["; ArenaMenuPutLetter: one glyph [DE] -> tile at HL; DE+1, HL+$10"],
    "ArenaMenuDrawFees": [
        "; ArenaMenuDrawFees: the four fees of column [$C8E3] (ArenaClassFeeTable,",
        "; 4 words per column) as numbers, one text row ($40) apart from $00AB."],
    "ArenaMenuPutFee": ["; ArenaMenuPutFee: the 16-bit fee [DE] -> number text at HL; DE+2, HL+$40"],
}


def db(bs):
    return "    db " + ", ".join(f"${b:02x}" for b in bs)


def build_text(lines, addr):
    """Return the new clean text (list of lines)."""
    rom = R.rom()

    def rb(a, n):
        return rom[BANK * 0x4000 + a - 0x4000:BANK * 0x4000 + a - 0x4000 + n]

    def w(a):
        b = rb(a, 2)
        return b[0] | b[1] << 8

    by_addr = {}
    for i, a in addr.items():
        by_addr.setdefault(a, i)

    def line_of(a, text=None):
        i = by_addr.get(a)
        if i is None:
            sys.exit(f"no probed line at ${a:04X}")
        if text and text not in lines[i]:
            sys.exit(f"${a:04X}: expected {text!r}, found {lines[i]!r}")
        return i

    spans = []   # (first line, last line exclusive, [new lines])

    # 1. ScreenEffectTable09: the 32 bytes after label9_4005's rst $00
    i0 = line_of(0x4008, "rst $00") + 1
    i1 = line_of(0x4029, "ld hl, $0a00")
    rows = ["; ScreenEffectTable09 ($09:$4009) — S109: 16 handlers indexed by $C8EF, the",
            "; SCREEN-EFFECT type written by script opcode $04 (TriggerScreenEffect",
            "; type, text). Was mgbdis fake code. Type 4 = the arena class menu.",
            "ScreenEffectTable09:"]
    known = {0x5B64: "ArenaClassMenu", 0x6120: "label9_6120"}
    notes = {0x4029: "bank $0A entry 0", 0x402E: "bank $12 entry 0", 0x4033: "close (no menu)"}
    for k in range(16):
        v = w(0x4009 + 2 * k)
        rows.append(f"    dw {known.get(v, f'${v:04X}'):<20s}; type {k:2d}" +
                    (f" — {notes[v]}" if v in notes else
                     " — ARENA CLASS-REGISTRATION MENU" if v == 0x5B64 else ""))
    spans.append((i0, i1, rows))

    # 2. ArenaClassMenu (outer) + its table
    i0 = line_of(0x5B64, "ld a, [$c905]")
    i1 = line_of(0x5B72, "ld hl, $ffb7")
    rows = ["; ---------------------------------------------------------------------------",
            "; ArenaClassMenu ($09:$5B64, screen effect 4) — S109 annotation. The Arena",
            "; Lobby class REGISTRATION menu: Arena Lobby script 6 `$04 $0004 $0710`",
            "; ('Which class are you registering for?'). Two columns of four classes,",
            "; each with its entry FEE (ArenaClassFeeTable) and a star when already won",
            "; ($CAB4 = classes won). Choosing a class that is not won and paying its fee",
            "; sets wArenaGroup = the class (0-7 = G..S); script 6 then runs opcode $1F",
            "; ArenaBattleSetup (bank $04) and warps to the Arena Battle room ($5D).",
            "; Editor: gamedata.arena.<class>.fee -> region gd_arena_fees (S109).",
            "; ---------------------------------------------------------------------------",
            "ArenaClassMenu:",
            "    ld a, [$c905]",
            "    rst $00",
            "ArenaClassMenuOuterTable:",
            "    dw ArenaClassMenu_S0Window",
            "    dw ArenaClassMenu_S1",
            "    dw ArenaClassMenu_S2Cursor",
            "    dw ArenaClassMenu_S3Run",
            "    dw ArenaClassMenu_S4Close"]
    for k, v in enumerate([0x5B72, 0x5BBA, 0x5BBF, 0x5BF1, 0x5BF4]):
        assert w(0x5B68 + 2 * k) == v
    spans.append((i0, i1, rows))

    # 3. inner table after ArenaClassMenuRun's rst $00
    i0 = line_of(0x5C0E)
    i1 = line_of(0x5C20, "call SetFld9_5c28")
    inner = [0x5C20, 0x5C43, 0x5D33, 0x5DAE, 0x5E0A, 0x5E2E, 0x5EA7, 0x5EAC, 0x5EB6]
    rows = ["ArenaClassMenuStateTable:          ; inner machine, state = $C906"]
    for k, v in enumerate(inner):
        assert w(0x5C0E + 2 * k) == v
        rows.append(f"    dw ArenaClassMenu_State{k}")
    spans.append((i0, i1, rows))

    # 4. class letters + fee table ($5D1B-$5D32)
    i0 = line_of(0x5D1B, "ld a, [hl+]")
    i1 = line_of(0x5D33, "ld de, $5da4")
    letters = rb(0x5D1B, 8)
    rows = ["; ArenaClassLetterTable ($09:$5D1B) — the class letter glyphs G F E D C B A S",
            "; (font: $24 = A); index 4*column + row. Read by ArenaMenuDrawLetters and",
            "; state 3 (the '<class> class?' prompt).",
            "ArenaClassLetterTable:",
            db(letters) + "   ; " + " ".join(CLASSES),
            "; ArenaClassFeeTable ($09:$5D23) — the ENTRY FEE of each class in gold, one",
            "; word per class G..S (index 4*column + row). Read by ArenaMenuDrawFees",
            "; (display), state 3 (gold >= fee?) and state 5 (AddGold). 16-bit: a fee",
            "; is 0-65535. Editor: gamedata.arena.<class>.fee (region gd_arena_fees, S109).",
            "ArenaClassFeeTable:"]
    for k in range(8):
        rows.append(f"    dw {w(0x5D23 + 2 * k):5d}   ; {CLASSES[k]} class")
    spans.append((i0, i1, rows))

    # 5. cursor table $5DA2-$5DAD
    i0 = line_of(0x5DA2, "adc h")
    i1 = line_of(0x5DAE, "ld hl, $5d23")
    cur = [w(0x5DA2 + 2 * k) for k in range(6)]
    rows = ["; ArenaMenuCursorTable ($09:$5DA2) — the class cursor: ArenaMenuDraw passes",
            "; $5DA2 to ReadFld9_44ff (B = C = 4), state 2 passes $5DA4 (the four row",
            "; words, $FFFF-ended) to FuncFld9_42f1 (B = 4).",
            "ArenaMenuCursorTable:",
            "    dw " + ", ".join(f"${v:04X}" for v in cur)]
    spans.append((i0, i1, rows))

    # 6. YES/NO cursor table $5EA1-$5EA6
    i0 = line_of(0x5EA1, "cpl")
    i1 = line_of(0x5EA7, "ld hl, $c906")
    cur = [w(0x5EA1 + 2 * k) for k in range(3)]
    rows = ["; ArenaYesNoCursorTable ($09:$5EA1) — the YES/NO cursor (state 4 FuncFld9_4530,",
            "; state 5 FuncFld9_42f1 with B = 2).",
            "ArenaYesNoCursorTable:",
            "    dw " + ", ".join(f"${v:04X}" for v in cur)]
    spans.append((i0, i1, rows))

    # state labels (inserted before their first instruction)
    inserts = {}
    for a, (lab, com) in STATE_LABELS.items():
        i = line_of(a)
        inserts[i] = com + [f"{lab}:"]

    out = []
    span_at = {s[0]: s for s in spans}
    i = 0
    while i < len(lines):
        if i in span_at:
            s = span_at[i]
            out += s[2]
            i = s[1]
            continue
        if i in inserts:
            out += inserts[i]
        out.append(lines[i])
        i += 1
    txt = "\n".join(out) + "\n"
    # the operand references become labels (same bytes)
    txt = txt.replace("    ld de, $5d1b\n", "    ld de, ArenaClassLetterTable\n")
    txt = txt.replace("    ld de, $5d23\n", "    ld de, ArenaClassFeeTable\n")
    txt = txt.replace("    ld hl, $5d23\n", "    ld hl, ArenaClassFeeTable\n")
    txt = txt.replace("    ld de, $5da2\n", "    ld de, ArenaMenuCursorTable\n")
    txt = txt.replace("    ld de, $5da4\n", "    ld de, ArenaMenuCursorTable + 2\n")
    txt = txt.replace("    ld de, $5ea1\n", "    ld de, ArenaYesNoCursorTable\n")
    for old, new in RENAMES:
        txt = re.sub(r"\b%s\b" % old, new, txt)
    for name, hdr in ROUTINE_HEADERS.items():
        txt = txt.replace(f"\n{name}:\n", "\n" + "\n".join(hdr) + f"\n{name}:\n", 1)
    txt = txt.replace("\nArenaClassMenuRun:\n",
                      "\n; ArenaClassMenuRun: the inner 9-state machine (state $C906), S109\n"
                      "ArenaClassMenuRun:\n", 1)
    txt = txt.replace("label9_4005:\n    ld a, [$c8ef]\n    rst $00\n",
                      "label9_4005:                        ; bank $09 entry 0: screen effects\n"
                      "    ld a, [$c8ef]                   ; the effect type (script opcode $04)\n"
                      "    rst $00\n", 1)
    return txt


def port(orig_clean, new, orig_patch):
    """The patched copy: the same new text over the same lines (the region is
    asserted identical in both trees before), renames applied file-wide."""
    a, b = orig_clean.splitlines(), orig_patch.splitlines()
    lo = next(i for i, l in enumerate(a) if l.startswith("label9_4005:"))
    hi = next(i for i, l in enumerate(a) if "ld a, [$c905]" in l and i > 5100)
    if a[lo - 10:hi] != b[lo - 10:hi]:
        sys.exit("patched bank_009.asm differs from the clean tree in the arena menu "
                 "region — port by hand")
    na = new.splitlines()
    nlo = next(i for i, l in enumerate(na) if l.startswith("label9_4005:"))
    nhi = len(na) - (len(a) - hi)          # the text after the region is unchanged
    if na[nhi:] != a[hi:]:
        sys.exit("tail mismatch")
    txt = "\n".join(b[:lo] + na[nlo:nhi] + b[hi:]) + "\n"
    for old, n2 in RENAMES:
        txt = re.sub(r"\b%s\b" % old, n2, txt)
    open(PATCH, "w").write(txt)
    print("patched bank_009.asm updated")


def main():
    import subprocess
    orig_patch = open(PATCH).read()
    if "ArenaClassFeeTable:" in orig_patch:
        sys.exit("already re-sectioned")
    cur = open(CLEAN).read()
    if "ArenaClassFeeTable:" in cur:            # clean done, patched not yet
        orig_clean = subprocess.run(["git", "show", "HEAD:disassembly/bank_009.asm"],
                                    cwd=REPO, capture_output=True, text=True).stdout
        return port(orig_clean, cur, orig_patch)
    lines, addr = R.probe_map(CLEAN)
    new = build_text(lines, addr)
    open(CLEAN, "w").write(new)
    md5 = R.build()
    R.clean_artifacts()
    print("clean build byte-perfect:", md5)
    port(cur, new, orig_patch)


if __name__ == "__main__":
    main()
