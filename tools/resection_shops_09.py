#!/usr/bin/env python3
"""resection_shops_09.py — S117 (Iron Rule 6): the bank $09 half of the SHOP
annotation (tools/resection_shops.py did bank $03's ItemInfoTable; its
probe-build splice cannot place bank $09's tables — the shop states use
`.local` labels, so no probe lands near them). Exact text blocks are replaced
in BOTH trees (asserted to occur once each) and the clean build must stay
1ca6579…. Idempotent (skips when ShopOuterStateTable exists). Contents: see
tools/resection_shops.py's docstring (same session, same decode)."""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "tools"))
import resection_monster_art_tables as R   # noqa: E402
import resection_shops as S                # noqa: E402

def dw(ws, names=None):
    return [f"    dw ${w:04x}   ; [{i:2d}]" + (f" {names[i]}" if names and i in names else "")
            for i, w in enumerate(ws)]

BLOCKS = [
 ("""    ld a, [$c905]
    rst $00

    ld bc, $4c46
    ld b, [hl]
    sub c
    ld b, [hl]
    rst $20
    ld b, [hl]
    pop af
    ld b, [hl]
    ld hl, $ffb7
""", ["ShopOuterMachine:",
      "    ; SHOP (screen effect type 0 = script opcode $04 $0000 <text base>; S117).",
      "    ; Outer machine on $C905: 0 window, 1 one frame, 2 gold box, 3 menu",
      "    ; cursor, 4 = the BUY / SELL / QUIT choice (ShopMenuTable).",
      "    ld a, [$c905]",
      "    rst $00",
      "ShopOuterStateTable:"] + dw([0x4601, 0x464C, 0x4691, 0x46E7, 0x46F1],
      {4: "-> state 4 = the menu choice (the wMenu_selection dispatch)"}) +
      ["    ld hl, $ffb7"]),
 ("""    ld hl, $6100
    nop
    and c
    nop
    rst $38
    rst $38
    ld a, [wMenu_selection]
    rst $00


    rlca
    ld b, a
    db $eb
    ld c, d
    pop af
    ld b, [hl]
""", ["ShopMenuCursorTable:",
      "    ; the BUY / SELL / QUIT cursor table (column word, rows, $FFFF; S117)",
      "    db $21, $00, $61, $00, $a1, $00, $ff, $ff",
      "    ld a, [wMenu_selection]",
      "    rst $00",
      "ShopMenuTable:"] + dw([0x4707, 0x4AEB, 0x46F1],
      {0: "BUY  (ShopBuyStateTable)", 1: "SELL (ShopSellStateTable)", 2: "QUIT (close: wGameState bit 4 off, $C905 := 0)"})),
 ("""    ld a, [$c906]
    rst $00


    ld hl, $9547
    ld b, a
    sub b
    ld c, b
    ld hl, sp+$48
    ld [$4c49], sp
    ld c, c
    sub e
    ld c, c
    ld a, [$1e49]
    ld c, d
    ld l, d
    ld c, d
    jp z, $214a

    inc bc
    nop


    call LoadFld9_45e5
""", ["    ld a, [$c906]",
      "    rst $00",
      "ShopBuyStateTable:",
      "    ; BUY inner machine on $C906 (S117). State 0 = the STOCK FILL below."] +
      dw([0x4721, 0x4795, 0x4890, 0x48F8, 0x4908, 0x494C, 0x4993, 0x49FA, 0x4A1E, 0x4A6A, 0x4ACA],
         {0: "ShopBuyStockFill"}) +
      ["ShopBuyStockFill:",
       "    ; buy state 0: 'What would you like?' (text base + 3), then the shop's",
       "    ; list -> $C0D8 (20 B, $FF-terminated): map $50 (the gate-floor shop) ->",
       "    ; GateworldShopInventory, else by wScreenIndex 0 Bazaar / 2 StarryNight /",
       "    ; 4 Bookstore / 5 (and any other screen) RareItemShopInventory — so a",
       "    ; vanilla shop is chosen by the SCREEN it stands on. Patched builds",
       "    ; replace the choice + copy with a same-size far call to bank $77",
       "    ; ShopFill (the project's shops, gamedata.shops; S117).",
       "    ld hl, $0003",
       "    call LoadFld9_45e5"]),
 ("""    ld a, [$c906]
    rst $00
    add hl, bc
    ld c, e
    daa
    ld c, e
    add c
    ld c, h
    jp hl


    ld c, h
    ld sp, hl
    ld c, h
    ld l, e
    ld c, l
    cp e
    ld c, l
    dec b
    ld c, [hl]
    add hl, hl
    ld c, [hl]
    ld [hl], e
    ld c, [hl]
    cp h
    ld c, [hl]
    db $dd
    ld c, [hl]
    add sp, $4e
""", ["    ld a, [$c906]",
      "    rst $00",
      "ShopSellStateTable:",
      "    ; SELL inner machine on $C906 (S117); state 0 builds the sellable list."] +
      dw([0x4B09, 0x4B27, 0x4C81, 0x4CE9, 0x4CF9, 0x4D6B, 0x4DBB, 0x4E05, 0x4E29, 0x4E73,
          0x4EBC, 0x4EDD, 0x4EE8])),
]


def main():
    for tree in (R.DIS, R.PAT):
        p = os.path.join(tree, "bank_009.asm")
        t = open(p).read()
        if "ShopOuterStateTable:" in t:
            print(f"{p}: already done")
            continue
        for old, new in BLOCKS:
            n = t.count(old)
            if n != 1:
                sys.exit(f"ABORT {p}: block occurs {n} times:\n{old[:120]}")
            t = t.replace(old, "\n".join(new) + "\n")
        t = t.replace("    ld de, $46df\n", "    ld de, ShopMenuCursorTable\n")
        open(p, "w").write(t)
    R.build()
    R.clean_artifacts()
    S.renames()
    print("bank $09 shop tables re-sectioned; clean byte-perfect")


if __name__ == "__main__":
    main()
