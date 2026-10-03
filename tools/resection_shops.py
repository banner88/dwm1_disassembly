#!/usr/bin/env python3
"""
resection_shops.py — S117 (ROADMAP P3.13c Shops, Iron Rule 6): annotate the
SHOP system in BOTH trees, zero byte change (clean build stays 1ca6579…).

What was decoded S117 (PyBoy-measured on the user's save — DATA_STRUCTURES
"Shops (S117)"):
  * bank $03 entry 2 (SetMon_6980 -> $DA62..$DA6D) copies a 12-byte ITEM
    RECORD from the table mgbdis named `SpriteFrameDataTable` ($03:$71DA):
    44 records (ids 0-43), +1/+2 = the BUY PRICE (16-bit LE, == the FAQ's
    shop lists), +$0B bit 2 = kept on a lost battle (SIDEQUEST_MAP). Was fake
    code -> `ItemInfoTable` db rows (the reference in SaveMon_6987 renamed).
  * bank $09 screen-effect type 0 (script opcode $04 $0000 $0680) = THE SHOP:
    outer machine on $C905 ($45F3, `ShopOuterStateTable` 5 dw), the
    BUY / SELL / QUIT menu (`ShopMenuTable` 3 dw), the BUY inner machine on
    $C906 (`ShopBuyStateTable` 11 dw; state 0 = the stock fill) and the SELL
    inner machine (`ShopSellStateTable` 13 dw). All were fake code.
  * routine renames (references updated in both trees):
      LoadFld9_45e5 -> ScreenEffectSay   (HL += the opcode's text base $C8F0)
      SetFld9_4875  -> ShopCountItems    ($C0D8 list -> [$C8E9], <= 20)
      SetFld9_47cd  -> ShopDrawNames     (3 visible rows from [$C8E3])
      SetFld9_480a  -> ShopDrawPrices    (their buy prices)
      SetFld9_4bc8  -> ShopSellPrice     (HL = what the shop pays for [$DA5E])

Method: bank $03 = resection_monster_art_tables.splice (probe-build line
addresses; the patched copy gets the identical text replacement); bank $09 =
tools/resection_shops_09.py (exact text blocks: the shop states use `.local`
labels, so the probe-build splice cannot place those tables — it widened the
window to whole routines on its first run S117, caught and reverted).
Idempotent.

Run:  python3 tools/resection_shops.py
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
sys.path.insert(0, os.path.join(REPO, "tools"))
import resection_monster_art_tables as R   # noqa: E402

ITEMS = os.path.join(REPO, "disassembly", "items.inc")


def item_names():
    out = {}
    for l in open(ITEMS):
        m = re.match(r"DEF (ITEM_\w+) EQU \$([0-9A-Fa-f]+)", l)
        if m:
            out[int(m.group(2), 16)] = m.group(1)
    return out


GROUPS = {0: "HP/MP restore", 1: "status cure / field", 2: "seed / nut / book",
          3: "meat", 4: "staff", 5: "WarpWing", 6: "TinyMedal", 7: "key / field"}


def rows_items():
    nm = item_names()
    base, n = 0x71DA, 44
    data = R.rb(0x03, base, n * 12)
    segs = [(None, 0, "ItemInfoTable:"),
            (None, 0, "    ; ITEM RECORDS ($03:$71DA, 44 x 12 B, index = item id; S117 — was"),
            (None, 0, "    ; mgbdis fake code under the name SpriteFrameDataTable). Bank $03"),
            (None, 0, "    ; entry 2 copies one to $DA62-$DA6D for [$DA5E]. Fields decoded so far:"),
            (None, 0, "    ;   +$00 group (0 HP/MP restore, 1 cure, 2 seeds / nuts / books,"),
            (None, 0, "    ;        3 meat, 4 staff, 5 WarpWing, 6 TinyMedal, 7 key / field)"),
            (None, 0, "    ;   +$01/+$02 BUY PRICE, 16-bit LE ($DA63/$DA64; the shop lists, the"),
            (None, 0, "    ;        sell price = bank $09 ShopSellPrice; == the FAQ's prices)"),
            (None, 0, "    ;   +$0B flags: bit 2 = kept after a lost battle (bank $50)"),
            (None, 0, "    ;   +$03-$0A: not decoded yet (ROADMAP E9 item authoring)."),
            (None, 0, "    ; The patched build owns this table as compiler region gd_item_info"),
            (None, 0, "    ; (gamedata.items: prices). Re-sectioned S117 (tools/resection_shops.py).")]
    for i in range(n):
        r = data[12 * i:12 * i + 12]
        what = (f"{nm.get(i, 'none')} — {GROUPS.get(r[0], '?')}, price {r[1] | r[2] << 8}"
                if i else "id 0 = no item")
        segs.append((base + 12 * i, 12, R.db(r) + f"   ; [{i:2d}] {what}"))
    return segs, data


def rows_table(base, n, label, notes, names=None):
    data = R.rb(0x09, base, 2 * n)
    segs = [(None, 0, f"{label}:")] + [(None, 0, "    ; " + x) for x in notes]
    for i in range(n):
        w = data[2 * i] | data[2 * i + 1] << 8
        tail = (names or {}).get(i, "")
        segs.append((base + 2 * i, 2, f"    dw ${w:04x}   ; [{i:2d}]" + (f" {tail}" if tail else "")))
    return segs, data


RENAMES = [("LoadFld9_45e5", "ScreenEffectSay"), ("SetFld9_4875", "ShopCountItems"),
           ("SetFld9_47cd", "ShopDrawNames"), ("SetFld9_480a", "ShopDrawPrices"),
           ("SetFld9_4bc8", "ShopSellPrice")]

HEADERS = {
    "ScreenEffectSay": [
        "; ScreenEffectSay (S117): HL = a text OFFSET; adds the screen effect's text",
        "; base [$C8F0/$C8F1] (script opcode $04's second word — $0680 for the shops:",
        "; $0681 Anything else? $0683 What would you like? $0685 How many? ...) and",
        "; queues it (ROM0 TextBankDispatch)."],
    "ShopCountItems": [
        "; ShopCountItems (S117): [$C8E9] := the number of items in the shop list at",
        "; $C0D8 (stops at 0 / $FF, at most 20)."],
    "ShopDrawNames": [
        "; ShopDrawNames (S117): the names of the 3 visible list rows from [$C8E3]",
        "; (the first row shown) to VRAM $8800."],
    "ShopDrawPrices": [
        "; ShopDrawPrices (S117): the BUY price of the 3 visible rows (ItemInfoTable",
        "; +1/+2 via bank $03 entry 2 -> $DA63/$DA64) as numbers + 'G'."],
    "ShopSellPrice": [
        "; ShopSellPrice (S117): HL = what the shop PAYS for item [$DA5E]: the full",
        "; price in the gate-floor shop (map $50); a staff ($18-$1C, $25 FireStaff,",
        "; $27 WarpStaff) price / 10; anything else price - price / 4 (3/4)."],
}


def renames():
    for tree in (R.DIS, R.PAT):
        p = os.path.join(tree, "bank_009.asm")
        if not os.path.exists(p):
            continue
        t = open(p).read()
        for a, b in RENAMES:
            if re.search(rf"^{b}:", t, re.M):
                continue
            t = re.sub(rf"\b{a}\b", b, t)
            t = t.replace(f"\n{b}:\n", "\n" + "\n".join(HEADERS[b]) + f"\n{b}:\n", 1)
        open(p, "w").write(t)
    for tree in (R.DIS, R.PAT):
        p = os.path.join(tree, "bank_003.asm")
        t = open(p).read()
        t = t.replace("SpriteFrameDataTable:   ; (mgbdis name, kept: referenced by the readers / patches)\n", "")
        t = re.sub(r"(add LOW|adc HIGH)\(SpriteFrameDataTable\)", r"\1(ItemInfoTable)", t)
        open(p, "w").write(t)
    R.build()
    R.clean_artifacts()


def main():
    R.splice("bank_003.asm", 0x03, 0x71DA, 44 * 12, rows_items, "ItemInfoTable",
             old_base="SpriteFrameDataTable")
    # bank $09: tools/resection_shops_09.py (exact text blocks — the splice
    # probe cannot place tables inside `.local`-label scopes)
    renames()


if __name__ == "__main__":
    main()
