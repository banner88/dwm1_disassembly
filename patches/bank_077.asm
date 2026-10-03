; =============================================================================
; BANK $77 — SHOPS (S117, ROADMAP P3.13c; compiler-owned, patches/bank_077.asm)
; =============================================================================
; A shop = script opcode $04 $0000 $0680 (screen effect type 0, bank $09; the
; outer / menu / BUY / SELL machines are annotated there: ShopOuterStateTable,
; ShopMenuTable, ShopBuyStateTable, ShopSellStateTable). BUY state 0
; (ShopBuyStockFill) filled the item list at $C0D8 from one of five lists in
; bank $09 by the room: map $50 -> the gate-floor shop, else wScreenIndex 0
; Bazaar / 2 Starry Night / 4 Bookstore / anything else the Rare item shop.
; Patched: that choice + copy (64 B) is `ld hl, $7700 / rst $10 / ret` + nops
; (patches/bank_009.asm) -> entry 0 below.
;
; Entry 0 (HL=$7700) ShopFill: wShopID ($D240) != 0 -> list wShopID - 1 of
;   ShopPtrTable (a `shop` script wrote it right before the opcode; it stays
;   set for the whole visit — every BUY re-runs this fill, measured S117 —
;   and entry 1 clears it at the close), else the vanilla room rule on
;   ShopPtrTable 0-4 (the
;   five vanilla lists in the vanilla order: Bazaar, Starry, Bookstore, Rare,
;   gate floor). Then $C0D8 := 20 zero bytes and the list ($FF-terminated) is
;   copied there — exactly what bank $09 did. An out-of-range wShopID falls
;   back to the room rule. Clobbers A/BC/DE/HL.
; Entry 1 (HL=$7701) ShopClose: bank $09's shop close (outer state 4, reached
;   by QUIT and by B at the menu), a same-size call replacing its tail
;   `ld hl,wGameState / res 4,[hl] / xor a / ld [$c905],a / ret`: does exactly
;   that, plus wShopID := 0; then ShopBoxBottom (S117b, below) puts the
;   dialog box back at the bottom when the shopkeeper's greeting opened it at
;   the top. Clobbers A/BC/DE/HL.
; Entry 2 (HL=$7702) ScreenPush (S117b): bank $09 LoadFld9_40fa's job — push
;   the 18 x 32 screen image at $C500 (the room's tiles from $C300 + the
;   HUD + the menu windows drawn into it) to the BG map at [$C909] — made a
;   same-size far call (patches/bank_009.asm), so EVERY bank $09 screen
;   (shops, the arena class menu, the other screen effects) comes here.
;   Identical tile writes, same order. PLUS, only in a FREE-COLOUR custom
;   room (GBC, wMapID >= CUSTOM_ROOM_START, a slot 0-3 marker — the S97 r2
;   BoxAttrActive test): after each row's tiles, the row's GBC attributes —
;   a menu / font tile (id >= $80, the $8800 font block) gets palette 7
;   (cream / black), a room tile (rows 0-15) gets its own palette back from
;   the room's attribute buffer $C200 (nibble [row*16 + col/2], high nibble
;   for even columns); HUD rows 16-17 keep theirs for room tiles. Vanilla
;   menus rely on every colour 1 being cream; a free-colour room broke that
;   (user S117: "menu glitches with background colours from custom tiles").
;   Clobbers A/BC/DE/HL.
; Data (generated below): SHOP_COUNT, ShopPtrTable (dw per list),
;   ShopList_n (item ids, $FF).
; =============================================================================

SECTION "ROM Bank $077", ROMX[$4000], BANK[$77]

    db $77                              ; bank self-ID at $4000

    dw ShopFill                         ; entry 0 (HL=$7700)
    dw ShopClose                        ; entry 1 (HL=$7701)
    dw ScreenPush                       ; entry 2 (HL=$7702, S117b)

ShopFill:
    ld a, [wShopID]
    or a
    jr z, .room
    dec a
    cp SHOP_COUNT
    jr c, .list
.room:
    ld a, [wMapID]
    cp $50                              ; the gate-floor shop room
    ld a, 4
    jr z, .list
    ld a, [wScreenIndex]
    or a
    jr z, .list                         ; screen 0 -> 0 Bazaar
    ld b, 1
    cp 2
    jr z, .scr                          ; screen 2 -> 1 Starry Night
    ld b, 2
    cp 4
    jr z, .scr                          ; screen 4 -> 2 Bookstore
    ld b, 3                             ; any other -> 3 Rare item shop
.scr:
    ld a, b
.list:
    add a
    ld l, a
    ld h, $00
    ld de, ShopPtrTable
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    ld hl, $c0d8                        ; the shop list buffer (20 B)
    ld b, 20
    xor a
.clr:
    ld [hl+], a
    dec b
    jr nz, .clr
    pop hl
    ld de, $c0d8
.copy:
    ld a, [hl+]
    ld [de], a
    inc de
    cp $ff
    jr nz, .copy
    ret

ShopClose:
    ld hl, wGameState
    res 4, [hl]
    xor a
    ld [$c905], a
    ld [wShopID], a
    ; fall through

; S117b — the dialog box after a shop. The shop's screens assume the field
; dialog box sits at the BOTTOM (rows 13-17): its close draws the box frame
; there and the dialog types "Thank you. Come again!" into it. The dialog box
; goes to the TOP (rows 0-4) when the player stands in the lower half of the
; screen (bank $06: player y - scroll y >= $50) — vanilla shopkeepers never
; allow that, a project shopkeeper can. Then the dialog's close restored the
; top rows (already redrawn by the shop) and the bottom box stayed on screen
; (measured S117b). Here, when [$C919] is not the bottom: re-seat the box at
; the bottom — base := [$C909] + $01A0 (bank $06's own wrap), the $C100 tile
; backup := the room's tiles of rows 13-15 ($C300) and the HUD rows 16-17
; ($C1C0), and the S97 r2 attribute save (wBoxAttrSave / wBoxAttrMask bits
; 0-4) := the room's palettes of rows 13-15 from $C200 in a free-colour room
; (HUD rows: no attribute restore). A bottom box (every vanilla shop) is left
; exactly as it is.
ShopBoxBottom:
    ld a, [$c909]
    ld l, a
    ld a, [$c90a]
    ld h, a
    ld de, $01a0
    add hl, de
    ld a, h
    and $03
    ld b, a
    ld a, [$c90a]
    and $fc
    or b
    ld h, a
    ld a, [$c919]
    cp l
    jr nz, .reseat
    ld a, [$c91a]
    cp h
    ret z
.reseat:
    ld a, l
    ld [$c919], a
    ld a, h
    ld [$c91a], a
    ld hl, $c300 + 13 * 32              ; rows 13-15: the room
    ld de, $c100
    ld c, 3
.room:
    call .copy20
    dec c
    jr nz, .room
    ld hl, $c1c0                        ; rows 16-17: the HUD
    ld c, 2
.hud:
    call .copy20
    dec c
    jr nz, .hud
    ld a, [wBoxAttrMask]
    and $e0                             ; rows 0-4: nothing to restore yet
    ld [wBoxAttrMask], a
    call PushAttrActive
    or a
    ret z
    ld hl, wBoxAttrSave
    ld b, 13                            ; B = screen row
.arow:
    ld c, 0                             ; C = column
.acol:
    push hl
    ld a, b
    swap a
    ld l, a
    ld a, c
    srl a
    add l
    ld l, a
    ld h, HIGH($c200)
    ld a, [hl]
    pop hl
    bit 0, c
    jr nz, .alow
    swap a
.alow:
    and $0f
    ld [hl+], a
    inc c
    ld a, c
    cp 20
    jr nz, .acol
    inc b
    ld a, b
    cp 16
    jr nz, .arow
    ld a, [wBoxAttrMask]
    or $07                              ; rows 0-2 of the box = screen rows 13-15
    ld [wBoxAttrMask], a
    ret
.copy20:                                ; 20 bytes [HL] -> [DE]; HL += 32
    push hl
    ld b, 20
.c20:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, .c20
    pop hl
    ld a, l
    add 32
    ld l, a
    ld a, h
    adc 0
    ld h, a
    ret

ScreenPush:
    call PushAttrActive
    ld [wPushAttrOn], a                 ; $80 = also write attributes
    ld a, [$c909]
    ld l, a
    ld a, [$c90a]
    ld h, a
    ld de, $c500
    ld c, $12                           ; 18 rows
.row:
    push hl                             ; the row's map address
    push de                             ; the row's buffer address
    ld b, $20
.tile:
    ld a, [de]
    call Write_gfx_tile                 ; ROM0, as bank $09 did
    call PushNextCol
    inc de
    dec b
    jr nz, .tile
    pop de
    pop hl
    ld a, [wPushAttrOn]
    or a
    call nz, PushRowAttrs               ; keeps HL / DE / C
    push bc
    ld a, e
    add $20
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a
    pop bc
    dec c
    jr nz, .row
    ret

PushNextCol:                            ; HL -> next column, wrapping in the 32-cell map row
    ld a, l
    and $e0
    push af
    ld a, l
    inc a
    and $1f
    ld l, a
    pop af
    or l
    ld l, a
    ret

PushAttrActive:                         ; A = $80 in a free-colour custom room on GBC, else 0
    ld a, [wIsGBC]
    or a
    ret z
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jr c, .no
    ld a, [$c79e]                       ; colour 3 high bytes of BG slots 0-3
    ld b, a
    ld a, [$c7a6]
    or b
    ld b, a
    ld a, [$c7ae]
    or b
    ld b, a
    ld a, [$c7b6]
    or b
    and $80
    ret
.no:
    xor a
    ret

; HL = the row's map address, DE = the row's $C500 address, C = rows left
; (18 - C = this row). Writes the attributes of the 20 visible columns.
PushRowAttrs:
    push hl
    push de
    push bc
    ld a, $12
    sub c
    ld [wPushAttrRow], a
    ld c, $00                           ; C = column
.col:
    ld a, [de]
    cp $80
    ld b, $07                           ; a menu / font tile -> palette 7
    jr nc, .put
    ld a, [wPushAttrRow]
    cp $10
    jr nc, .skip                        ; HUD rows: room tiles keep theirs
    push hl
    swap a                              ; row * 16
    ld l, a
    ld a, c
    srl a                               ; col / 2
    add l
    ld l, a
    ld h, HIGH($c200)
    ld a, [hl]
    pop hl
    bit 0, c
    jr nz, .low
    swap a
.low:
    and $0f
    ld b, a
.put:
    di
.w:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, .w                           ; mode 0/1 (VRAM free; mode 2 follows)
    ld a, $01
    ldh [rVBK], a
    ld [hl], b
    xor a
    ldh [rVBK], a
    ei
.skip:
    push bc
    call PushNextCol
    pop bc
    inc de
    inc c
    ld a, c
    cp $14
    jr nz, .col
    pop bc
    pop de
    pop hl
    ret

; =============================================================================
; SHOP LISTS (generated by editor2 `shops77` from gamedata.shops + custom.shops,
; PROJECT_COMPILER §2.32). Order: the five vanilla shops, then the project's.
; =============================================================================

SHOP_COUNT EQU 5
ShopPtrTable:
    dw ShopList_0   ; 0: Bazaar item shop
    dw ShopList_1   ; 1: Starry Night shop
    dw ShopList_2   ; 2: Bookstore
    dw ShopList_3   ; 3: Rare item shop
    dw ShopList_4   ; 4: Gate-floor shop

ShopList_0:  ; Bazaar item shop — Herb, Lovewater, Antidote, Repellant, BeefJerky, PorkChop, WarpWing, BeastTail
    db $01, $02, $07, $28, $13, $14, $1d, $26, $ff
ShopList_1:  ; Starry Night shop — Potion, WorldDew, SageStone, WorldLeaf, MapHerb, BookMark, Rib, MistStaff
    db $05, $04, $03, $0c, $2a, $2b, $15, $1a, $ff
ShopList_2:  ; Bookstore — QuestBk, HorrorBk, BeniceBk, CheaterBk, SmartBk, ComedyBk
    db $1f, $20, $21, $22, $23, $24, $ff
ShopList_3:  ; Rare item shop — Sirloin, ShinyHarp, WindStaff, LavaStaff, BoltStaff, SnowStaff, FireStaff
    db $17, $29, $19, $1b, $18, $1c, $25, $ff
ShopList_4:  ; Gate-floor shop — Herb, Lovewater, Antidote, MoonHerb, AwakeSand, SkyBell, Laurel, WorldLeaf
    db $01, $02, $07, $08, $0b, $09, $0a, $0c, $ff

