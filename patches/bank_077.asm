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
;   S126 (ROADMAP P3.14e1): a FULL-SCREEN effect — the list of Travelers'
;   Gates ($C8EF 13) and the naming screen (15), whose pictures are drawn
;   into the room's own tile slots ($9000, ids < $80: the gate names' bitmap
;   $38-$7F, the letters) — gets palette 7 on every cell (wPushAttrOn = $81;
;   measured S126: the gate names / letters took the room's palettes in a
;   free-colour room). The library / farm CHECK / egg INFO full screens write
;   their own attributes.
;   S126: a room-row cell whose tile is < $80 but NOT the room's own tile
;   there ($C300 + the cell = the $C500 cell - $200: the composer copied the
;   room from $C300, so a real room cell always matches) is a picture the
;   screen drew into the room's tile slots (the farm / library family icons)
;   -> palette 7 too (measured S126: they took the room's colours).
;   S126: banks $0A ScreenPush0A and $12 ScreenPush12 (byte-identical copies
;   of bank $09's push) are same-size far calls here too.
; Entry 3 (HL=$7703) SayText (S126, ROADMAP P3.14e1): a screen effect's text.
;   Bank $09 ScreenEffectSay / $0A ScreenEffectSay0A / $12 ScreenEffectSay12 (the
;   say helpers: text = op $04's base [$C8F0] + an offset) call SayAny09 /
;   0A / 12 (bank-local, DE := HL) instead of ROM0 TextBankDispatch. DE >=
;   $0A00 -> the project's own text (bank $60 entry 5 CustomTextDisplay, the
;   bank $04 TextQueueCheck_Ext rule). Else the generated ServiceSetTable:
;   first the pairs of line set [wServiceLines] (a service / shop script
;   writes it around the opcode), then set 0 (the pairs for every NPC of a
;   kind: "everywhere" sets, the medal reward lines): a listed vanilla id
;   becomes the project's text. Else ROM0 TextBankDispatch (unchanged).
;   Clobbers all.
; Entries 4 / 5 / 6 (S126, ROADMAP P3.14e1) — service screens in custom rooms:
;   6 ServiceOpenTiles: the farm (FarmScreenOpen, bank $12) and the egg
;     appraiser (EggScreenOpen, bank $0A) draw their icons into the room's
;     tile slots $60-$7F and never restore them (their vanilla rooms leave
;     those slots unused; measured S126). In a custom room (wMapID >=
;     CUSTOM_ROOM_START) and once per screen (wServiceTileSaved): copy
;     $9600-$97FF (VRAM bank 0, 512 B, each byte in mode 0/1) to
;     wServiceTileSave.
;   4 ServiceCloseBox: the Vault's and the farm's close tails (same-size far
;     calls): the tiles back if saved, then ShopClose (wGameState bit 4 off,
;     $C905 := 0, wShopID := 0, ShopBoxBottom — both left the dialog box on
;     the screen when talked to from the lower half, measured S126).
;   5 ServiceCloseTiles: the egg appraiser's close: the tiles back if saved,
;     then exactly the replaced tail (bit 4 off, $C905 := 0).
;   "The tiles back" also sets $FFD4 := $80 (S126 r2): the farm leaves $60
;     there (bank $12 $44A7) — the text-box sprite rule's threshold —
;     so at the next talk every sprite over a BG tile >= $60 vanished in a
;     room drawn with such ids (vanilla: reset by the next map load).
; Entries 7 / 8 / 9 (S127, ROADMAP P3.14e2) — breeding NPCs (PROJECT_COMPILER §2.40):
;   7 BreedClose: bank $0A's three breeding screens — 5 (a master offering their
;     own monster: "Why not breed with my …?"), 6 (Grandpa's BREED / HATCH menu)
;     and 11 ("Take … with you now?") — end with `ld hl, $0103 / rst $10 / ret`;
;     those 5 bytes are a same-size call of this entry (patches/bank_00a.asm).
;     It does the bank $01 entry 3 call, then, in a CUSTOM room: ShopBoxBottom (S127 r3:
;     the dialog box re-seated at the bottom, as after a shop), $FFD4 := $80
;     (types 5 / 6 / 11 leave $78 / $40 / $40 — the text-box sprite rule's
;     threshold, so the next talk hid every sprite standing on a room tile >= it)
;     and the room's own sheet again at $9000 (tiles $00-$7F: the record through
;     bank $71 entry 0, as bank $0B RoomEntry1 does, then ROM0 WaitDMATransfer —
;     the field menu's close heals the room the same way). The screens draw
;     their icons and the INFO pages' pictures into $40-$7F and never restore
;     them; vanilla rooms do not draw with those slots (measured S127: after
;     BREED -> INFO -> back, slots $40-$48 / $61-$7A stayed overwritten).
;   8 BreedSlotEID: bank $14 LoadEnemyStatsExt for a pseudo enemy row $0F00 + k
;     (a random breeder's op $42): slot k of wBreedSlots — state 0 = roll it now
;     (BreedRoll with the slot's pool), then wTempEnemyStatsId / $DA13 := the
;     slot's real row, which LoadEnemyStats then copies (so the mate's name,
;     picture and the egg's parent come from the real row). Keeps DE.
;   9 PartyAvgLevel: A = E := the average level of the party (list $CA8E,
;     records +$4B; 0 with no monster). A far caller reads E (rst $10 returns
;     through `pop af`, so A comes back as the caller's bank). For BreedRoll and the bank $71 gate rooms' chance
;     by level (entry 4).
;  10 ScriptCommand (E = command): a project script's op $24 $FF00 + E (bank $60
;     CustomDrawTiles hands a word $FFxx here — P3.14b's reserved range). 0 =
;     insert slot 0 ($C180, text $F9 $00) := the species name of the breeding
;     mate in $C8F7/$C8F8 (op $42's row; a random breeder's $0F00 + k rolls
;     here): bank $14 entry 0 LoadEnemyStats, then the name of [$DA18] in text
;     mode 5 (what the type 5 screen's LoadFldA_4ba2 does) — a breeder asks
;     "Why not breed with my [INS 00]?" BEFORE its menu opens. Others: nothing.
;   BreedRoll (A = pool): the player's place on the pool's scales — average party
;     level; arena classes won ($CAB4) x 12; monsters seen (Library bits $CA94,
;     0-$EF, as op $31 counts them) / 2; the pool's story milestones that are ON
;     x 100 / their number — then the band with the smallest sum of distances
;     over the scales the pool checks (the first band wins a tie), then a mate:
;     RNG16 mod the band's total weight walked over its mates' weights.
; Entries 12-15 (S141 r3, ROADMAP ARC CAP3b — the user on the S141 test ROMs: after breeding
;   an NPC vanished and another turned into letters, and r2's reload at the close left them
;   so WHILE the menu was open): a custom room's NPC sprite sheets 3-5 live in VRAM BANK 1.
;   The room's NPC sheets are DMA'd (bank $0B CmpRoom_4839 at the room load, bank $06 entry
;   4 ReloadNPCSheets after a full screen) to page $80 + c + 5 in towns (sheet c of the
;   cache $D7BE, tile base $50 + 16c), so sheets 3-5 sit at $8800-$8AFF — the BG tiles
;   $80-$AF every WINDOWED screen (the shop, the Vault, the farm, the egg appraiser, the
;   namer, Grandpa, a master, "Take…") loads its window graphics
;   into (bank $09 `ld de, $2E0F / ld hl, $8800`, …) — VRAM bank 0 only; VRAM bank 1's
;   tile area is unused in the field (PyBoy S141: all zero, the menus never write it).
;   Vanilla rooms that host these menus never show a 4th sheet.
;   12 NpcSheetLoad0B / 13 NpcSheetLoad06: the two loaders' page choice + DMA, moved here
;     (same size in banks $0B / $06; [wNpcSheetIdx] = c, DE = the gfx id): the vanilla
;     rules exactly — $80 + c, + 7 on a gate floor, map $08 + 0 (bank $06's copy: page $08
;     itself — its `ld h, a` after `cp $08`, a vanilla quirk kept), map $45 + 2, else + 5
;     — and, in a CUSTOM room (wMapID >= CUSTOM_ROOM_START, not a gate floor) for a page
;     >= $88: DMA to VRAM bank 0 as before (the LZ stream copies back from its own
;     destination), then copy the 256 bytes to the same page of VRAM BANK 1
;     (NpcSheetToBank1: per byte di / read bank 0 / VBK 1 / write / VBK 0 / ei — the
;     VBlank handler's scroll copy sets VBK 0 behind itself, ProcessSpriteTransfer).
;   14 NpcDrawPlain / 15 NpcDrawMonster: bank $06 NPCDrawSlot's two builder calls (bank
;     $60 entry 11 NpcColourDraw for an NPC, bank $04 entry 2 for a monster; same size):
;     the call as before, then — the tile base $FFC9 >= $80 in a custom room, not a gate
;     floor (= exactly the sheets the loaders put in bank 1) — OAM attr bit 3 (VRAM bank 1)
;     on every piece the call wrote (shadow OAM $C000 + 4n, n from the old to the new
;     $FFCB).
; Data (generated below): SHOP_COUNT, ShopPtrTable (dw per list),
;   ShopList_n (item ids, $FF), SERVICE_SET_COUNT + ServiceSetTable +
;   ServicePairs_n (S126).
; =============================================================================

SECTION "ROM Bank $077", ROMX[$4000], BANK[$77]

    db $77                              ; bank self-ID at $4000

    dw ShopFill                         ; entry 0 (HL=$7700)
    dw ShopClose                        ; entry 1 (HL=$7701)
    dw ScreenPush                       ; entry 2 (HL=$7702, S117b)
    dw SayText                          ; entry 3 (HL=$7703, S126)
    dw ServiceCloseBox                  ; entry 4 (HL=$7704, S126)
    dw ServiceCloseTiles                ; entry 5 (HL=$7705, S126)
    dw ServiceOpenTiles                 ; entry 6 (HL=$7706, S126)
    dw BreedClose                       ; entry 7 (HL=$7707, S127)
    dw BreedSlotEID                     ; entry 8 (HL=$7708, S127)
    dw PartyAvgLevel                    ; entry 9 (HL=$7709, S127)
    dw ScriptCommand                    ; entry 10 (HL=$770A, S127)
    dw StoryCheck                       ; entry 11 (HL=$770B, S129)
    dw NpcSheetLoad0B                   ; entry 12 (HL=$770C, S141 r3)
    dw NpcSheetLoad06                   ; entry 13 (HL=$770D, S141 r3)
    dw NpcDrawPlain                     ; entry 14 (HL=$770E, S141 r3)
    dw NpcDrawMonster                   ; entry 15 (HL=$770F, S141 r3)

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
    call ShopSetPick                    ; S129: the shop's item set by flags
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
    or a
    jr z, .set                          ; not a free-colour custom room: tiles only
    ld b, a
    ld a, [wGameState]
    bit 4, a                            ; a screen effect (op $04) running?
    jr z, .keep
    ld a, [$c8ef]
    cp $0d                              ; S126: the list of Travelers' Gates
    jr z, .full
    cp $0f                              ; S126: the naming screen
    jr nz, .keep
.full:
    ld b, $81                           ; every cell palette 7 (full-screen picture)
.keep:
    ld a, b
.set:
    ld [wPushAttrOn], a                 ; $80 = also write attributes, +1 = all palette 7
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
    ld b, $07
    ld a, [wPushAttrOn]
    rra
    jr c, .put                          ; S126: a full-screen effect -> palette 7 everywhere
    ld a, [de]
    cp $80                              ; a menu / font tile -> palette 7
    jr nc, .put
    ld a, [wPushAttrRow]
    cp $10
    jr nc, .skip                        ; HUD rows: room tiles keep theirs
    push hl
    ld h, d
    ld l, e
    dec h
    dec h                               ; HL = $C300 + the same cell: the room's own tile
    ld a, [de]
    cp [hl]
    pop hl
    jr nz, .put                         ; S126: a picture drawn into the room's tile slots
                                        ; (family icons, the gate names) -> palette 7
    ld a, [wPushAttrRow]
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

; -----------------------------------------------------------------------------
; Entry 3: SayText (S126) — DE = text id (see the header)
; -----------------------------------------------------------------------------
SayText:
    ld a, d
    cp $0a
    jr nc, .custom                      ; the project's own text id
    ld a, [wServiceLines]
    or a
    jr z, .global
    cp SERVICE_SET_COUNT + 1
    jr nc, .global                      ; out of range: ignore
    call SetPairs                       ; HL = set n's pairs
    call ScanPairs
    jr c, .custom
.global:
    xor a
    call SetPairs                       ; set 0: every NPC of the kind
    call ScanPairs
    jr c, .custom
    ld h, d
    ld l, e
    jp TextBankDispatch                 ; ROM0, as the say helpers did
.custom:
    ld a, d
    sub $0a
    ld [$c822], a                       ; the two-level index (bank $04 TextQueueCheck_Ext)
    ld a, e
    ld [$c823], a
    ld hl, $6005                        ; bank $60 entry 5 CustomTextDisplay
    rst $10
    ret

SetPairs:                               ; A = set number -> HL = ServiceSetTable[A]
    add a
    ld hl, ServiceSetTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ret

; HL = pairs (dw vanilla id, dw the project's id; $FFFF ends), DE = the id.
; Found: CF set, DE = the project's id. Else CF clear, DE kept.
ScanPairs:
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a
    and c
    inc a
    ret z                               ; $FFFF (and cleared CF; inc keeps it)
    ld a, c
    cp e
    jr nz, .next
    ld a, b
    cp d
    jr nz, .next
    ld a, [hl+]
    ld e, a
    ld d, [hl]
    scf
    ret
.next:
    inc hl
    inc hl
    jr ScanPairs

; -----------------------------------------------------------------------------
; Entries 4 / 5 / 6 (S126): service screens' room tiles $60-$7F (see the header)
; -----------------------------------------------------------------------------
ServiceOpenTiles:
    ld a, [wServiceTileSaved]
    or a
    ret nz                              ; this screen's tiles are already saved
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    ret c                               ; vanilla rooms: unchanged
    ld a, 1
    ld [wServiceTileSaved], a
    xor a
    ldh [rVBK], a
    ld hl, $9600
    ld de, wServiceTileSave
    ld bc, $0200
.copy:
    di
.w:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, .w                           ; mode 0/1 (VRAM free; mode 2 follows)
    ld a, [hl+]
    ei
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .copy
    ret

ServiceTilesBack:
    ld a, [wServiceTileSaved]
    or a
    ret z
    xor a
    ld [wServiceTileSaved], a
    ldh [rVBK], a
    ld a, $80                           ; hSpriteHideTile ($FFD4) back to the font tiles: the
    ldh [$d4], a                        ; farm sets $60 (bank $12 $44A7), bank $0A types 5 / 6 / 11 $78 / $40,
                                        ; and while a text box is open every sprite piece over
                                        ; a BG tile >= it is skipped (ROM0 SaveHLBC) — in a room
                                        ; drawn with those ids ALL sprites vanished at the next
                                        ; talk (user S126; vanilla resets it at the next map load)
    ld hl, $9600
    ld de, wServiceTileSave
    ld bc, $0200
.copy:
    ld a, [de]
    inc de
    push bc
    ld b, a
    di
.w:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, .w
    ld [hl], b
    ei
    inc hl
    pop bc
    dec bc
    ld a, b
    or c
    jr nz, .copy
    ret

ServiceCloseBox:
    call ServiceTilesBack
    jp ShopClose

ServiceCloseTiles:
    call ServiceTilesBack
    ld hl, wGameState
    res 4, [hl]
    xor a
    ld [$c905], a
    ret

; -----------------------------------------------------------------------------
; Entries 7 / 8 / 9 (S127): breeding NPCs (see the header)
; -----------------------------------------------------------------------------
BreedClose:
    ld hl, $0103                        ; bank $01 entry 3 — the replaced tail's call
    rst $10
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    ret c                               ; vanilla rooms: unchanged
    call ShopBoxBottom                  ; S127 r3: the dialog box back at the bottom (a talk
                                        ;   from the lower half opened it at the top; the
                                        ;   farewell's scroll then drew there — measured)
    ld a, $80
    ldh [$d4], a                        ; the text-box sprite threshold back to the font
    ld hl, $7100                        ; bank $71 entry 0: the room's record -> wRoomRecScratch
    rst $10
    ld hl, wRoomRecScratch
    ld e, [hl]
    inc hl
    ld d, [hl]                          ; DE = the room sheet's gfx id
    ld hl, $9000
    jp WaitDMATransfer                  ; tiles $00-$7F = the room's own again

BreedSlotEID:
    push de
    ld a, [wTempEnemyStatsId]
    and BREED_SLOTS - 1
    add a
    add a
    ld e, a
    ld d, $00
    ld hl, wBreedSlots
    add hl, de                          ; HL = the slot [state, pool, lo, hi]
    ld a, [hl]
    or a
    jr nz, .have
    push hl
    inc hl
    ld a, [hl]                          ; the pool
    call BreedRoll                      ; BC = the mate's enemy row
    pop hl
    ld a, $01
    ld [hl+], a                         ; state 1: rolled for this appearance
    inc hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    dec hl
    dec hl
    dec hl
.have:
    inc hl
    inc hl
    ld a, [hl+]
    ld [wTempEnemyStatsId], a
    ld a, [hl]
    ld [$da13], a
    pop de
    ret

PartyAvgLevel:
    ld de, $0000                        ; DE = the levels added up
    ld b, $00                           ; B = monsters
    ld c, $03                           ; C = list entries left
    ld hl, $ca8e                        ; the party list (slot numbers, $FF = none)
.next:
    ld a, [hl+]
    cp $ff
    jr z, .skip
    push hl
    ld hl, $cac1 + $4b                  ; record +$4B = the level
    call GetMonsterDataPtr              ; keeps BC / DE
    ld a, [hl]
    pop hl
    add e
    ld e, a
    ld a, d
    adc $00
    ld d, a
    inc b
.skip:
    dec c
    jr nz, .next
    ld a, b
    or a
    jr nz, .some
    ld e, a                             ; no monster: 0 (A = E = 0)
    ret
.some:
    ld c, $00                           ; C = the quotient
.div:
    ld a, e
    sub b
    ld e, a
    ld a, d
    sbc $00
    ld d, a
    jr c, .done
    inc c
    jr .div
.done:
    ld a, c
    ld e, a                             ; E too: a far caller gets A back as its bank
    ret                                 ;   (rst $10 returns through pop af)

; A = pool -> BC = the mate's enemy row (see the header). Clobbers all.
BreedRoll:
    cp BREED_POOL_COUNT
    jr c, .ok
    ld bc, $0001                        ; no such pool (cannot be built): row 1
    ret
.ok:
    add a
    ld hl, BreedPoolPtrs
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a                             ; HL = the pool
    ld a, [hl+]
    ld [wBreedMask], a
    ld a, [hl+]
    ld [wBreedStep], a
    push hl
    call PartyAvgLevel
    ld [wBreedVals], a
    ld a, [$cab4]                       ; arena classes won, 0-8
    add a
    add a
    ld b, a                             ; x4
    add a                               ; x8
    add b                               ; x12
    ld [wBreedVals + 1], a
    ld bc, $0000                        ; B = Library bit, C = seen
.seen:
    push bc
    ld hl, $ca94
    ld a, b
    call TestBitInArray                 ; Z = not seen
    pop bc
    jr z, .unseen
    inc c
.unseen:
    inc b
    ld a, b
    cp $f0
    jr nz, .seen
    ld a, c
    srl a
    ld [wBreedVals + 2], a
    pop hl
    ld a, [hl+]                         ; milestones
    ld b, a
    ld c, $00                           ; C = milestones ON
    or a
    jr z, .msDone
.ms:
    push bc
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    push hl
    call TestEventFlag                  ; Z = clear, NZ = set
    pop hl
    pop bc
    jr z, .msOff
    inc c
.msOff:
    dec b
    jr nz, .ms
.msDone:
    xor a                               ; story = milestones ON x the step
    ld b, c
    inc b
.mul:
    dec b
    jr z, .mulDone
    ld e, a
    ld a, [wBreedStep]
    add e
    jr .mul
.mulDone:
    ld [wBreedVals + 3], a
    ; the band nearest to the player: HL = the band count
    ld a, [hl+]
    ld b, a                             ; B = bands left
    ld de, $ffff                        ; DE = the best distance
    push hl                             ; [sp] = the best band (the first, for now)
.band:
    push bc
    push de
    push hl
    ld de, wBreedVals
    ld bc, $0000                        ; BC = this band's distance
    ld a, [wBreedMask]
.scale:
    srl a                               ; CF = this scale counts
    push af
    jr nc, .scaleNext
    ld a, [de]
    sub [hl]
    jr nc, .pos
    cpl
    inc a                               ; |player - target|
.pos:
    add c
    ld c, a
    jr nc, .scaleNext
    inc b
.scaleNext:
    inc hl
    inc de
    pop af
    push af
    ld a, e
    cp LOW(wBreedVals + 4)
    jr z, .sumDone
    pop af
    jr .scale
.sumDone:
    pop af                              ; HL = the band's mate count
    pop hl                              ; HL = this band
    pop de                              ; DE = the best so far
    ld a, b                             ; this distance < the best?
    cp d
    jr c, .better
    jr nz, .worse
    ld a, c
    cp e
    jr nc, .worse
.better:
    ld d, b
    ld e, c
    pop bc                              ; bands left
    add sp, 2                           ; drop the old best band
    push hl                             ; the new best band
    jr .after
.worse:
    pop bc
.after:
    push de
    ld de, $0004
    add hl, de                          ; HL = the mate count
    ld a, [hl+]
    inc hl                              ; past the total weight
    ld e, a
    add a
    add e                               ; 3 bytes a mate
    ld e, a
    ld d, $00
    add hl, de                          ; HL = the next band
    pop de
    dec b
    jr nz, .band
    pop hl                              ; HL = the nearest band
    ld de, $0004
    add hl, de
    ld a, [hl+]
    ld b, a                             ; B = mates
    ld a, [hl+]                         ; the total weight
    push hl
    push bc
    ld c, a
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, c
    call Div16x8To16                    ; A = RNG16 mod the total (clobbers DE, HL)
    pop bc
    pop hl
    ld c, a                             ; C = the roll
.mate:
    ld e, [hl]
    inc hl
    ld d, [hl]
    inc hl
    ld a, c
    sub [hl]                            ; roll - this mate's weight
    inc hl
    jr c, .picked
    ld c, a
    dec b
    jr nz, .mate
.picked:
    ld b, d
    ld c, e
    ret

ScriptCommand:
    ld a, e
    or a
    jp nz, StoryCommand                 ; S129: 1-255 = the project's story commands
    ld a, [$c8f7]
    ld [wTempEnemyStatsId], a
    ld a, [$c8f8]
    ld [$da13], a
    ld hl, $1400                        ; bank $14 entry 0: LoadEnemyStats
    rst $10
    ld a, [$da18]                       ; the row's species
    ld l, a
    ld h, $05                           ; text mode 5: a species name
    ld de, $c180                        ; insert slot 0
    jp SetupVRAMParams

; =============================================================================
; S129 (ROADMAP P3.14b) — STORY CHECKS, STORY COMMANDS, SHOP ITEM SETS
; =============================================================================
; STORY CHECKS are "virtual event flags": flag $1800 + n IS check n of the
; project (STORY_CHECK_COUNT of them, StoryCheckPtrs, generated). ROM0
; ComputeFlagAddress -> bank $73 entry 21 FlagAddr routes a flag $18xx here
; (entry 11, E = n), then answers the address of wStoryFlag — so every reader
; of event flags (script ops $00 / $01 if_flag_*, room state rules, NPC
; shown_when, the hub / music / shop-set / gate-room / arena-lock rules, the
; breeding pools' milestones) tests a check exactly like a flag, with no change
; of its own. Writing one (ops $02 / $03) only writes the scratch byte.
; Entry 11 StoryCheck (E = n): wStoryFlag := $FF when check n holds, else $00.
;   Clobbers all. A record = [kind, params…]:
;     0 item     [item, count]   the bag holds >= count of that item
;     1 gold     [lo, mid, hi]   gold >= the amount (24-bit, wCurrGold LE)
;     2 species  [species, where] a monster of that species is owned
;     3 family   [family, where]  a monster of that family is owned
;     4 monsters [count, where]  >= count monsters are owned
;        where: 0 = every monster you own (array slots 0-39: in-use +$00 != 0,
;        not an egg +$63 == 0 — the party, the farm; the sleep pool not) /
;        1 = the party (list $CA8E)
;     5 level    [level, mode]   mode 0 = a party monster is at that level or
;        higher, 1 = the party's average level (PartyAvgLevel) is, 2 = every
;        party monster is (and the party is not empty)
;     6 seen     [count]         >= count species seen in the Library (bits
;        $CA94, ids 0-$EF — what op $31 counts)
;     7 chance   [percent]       RNG16 mod 100 < percent (rolled at each read)
;     8 arena    [classes]       arena classes won ($CAB4) >= classes
;     9 all      [n, n x dw flag] every term holds (bit 15 = must be OFF)
;    10 any      [n, n x dw flag] at least one term holds
;    11 bag_room [count]         >= count free bag slots ($00 / $FF)
;   A term of 9 / 10 may be another check (its own flag $18xx): the compiler
;   orders them without cycles; the nested read overwrites wStoryFlag only
;   after the outer test has consumed it.
; STORY COMMANDS: a project script's op $24 $FF00 + n (bank $60 CustomDrawTiles
; -> entry 10 ScriptCommand, E = n; n = 0 is the S127 mate's name) runs
; command n of StoryCmdPtrs (n - 1, generated) — [kind, params…]:
;     0 take_item [item, count]  remove up to count of that item from the bag
;        (the last ones first; the bag closes up, $FF fills the end);
;        $D8E1 := how many were taken
;     1 give_gold [lo, mid, hi]  ROM0 CompareGold (adds; capped at 99,999)
;     2 take_gold [lo, mid, hi]  ROM0 AddGold (subtracts; floor 0)
;     3 give_item [item, count]  room for all of them ($00 / $FF slots) ->
;        put them in, $D8E1 := 1; else nothing, $D8E1 := 0
;   Op $24 yields (BANK04_SCRIPT_ENGINE "Breeding"): a later text needs
;   init_dialog — the compiler adds it.
; SHOP ITEM SETS: ShopFill picks list a, then ShopSetPick walks ShopSetTable
;   ([shop list, n, n x dw flag, the set's list] ..., $FF): the FIRST row of
;   that shop whose terms all hold replaces the list — the shop sells another
;   set once flags (or checks) say so. No row = the shop's own list.
; =============================================================================

StoryCheck:
    ld a, e
    cp STORY_CHECK_COUNT
    jr nc, StoryFalse
    ld l, a
    ld h, $00
    add hl, hl
    ld de, StoryCheckPtrs
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a                             ; HL = the record
    ld a, [hl+]                         ; the kind
    cp STORY_KINDS
    jr nc, StoryFalse
    push hl                             ; [sp] = the params (each kind pops it)
    add a
    ld l, a
    ld h, $00
    ld de, StoryKindTable
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp hl

StoryFalse:
    xor a
    ld [wStoryFlag], a
    ret

StoryTrue:
    ld a, $ff
    ld [wStoryFlag], a
    ret

STORY_KINDS EQU 12
StoryKindTable:
    dw StoryItem                        ; 0
    dw StoryGold                        ; 1
    dw StorySpecies                     ; 2
    dw StoryFamily                      ; 3
    dw StoryMonsters                    ; 4
    dw StoryLevel                       ; 5
    dw StorySeen                        ; 6
    dw StoryChance                      ; 7
    dw StoryArena                       ; 8
    dw StoryAll                         ; 9
    dw StoryAny                         ; 10
    dw StoryBagRoom                     ; 11

; A >= the param -> true. (shared tail: C = the count, [HL] = the minimum)
StoryAtLeast:
    ld a, c
    cp [hl]
    jr nc, StoryTrue
    jr StoryFalse

StoryItem:
    pop hl
    ld a, [hl+]
    ld d, a                             ; D = the item
    push hl
    call BagCount                       ; C = how many
    pop hl
    jr StoryAtLeast

StoryGold:
    pop hl
    ld de, wCurrGoldLo
    ld a, [de]
    sub [hl]
    inc hl
    inc de
    ld a, [de]
    sbc [hl]
    inc hl
    inc de
    ld a, [de]
    sbc [hl]
    jr nc, StoryTrue
    jr StoryFalse

StorySpecies:
    ld d, $09                           ; record +$09 = the species
    jr StoryOwnsOne

StoryFamily:
    ld d, $0a                           ; record +$0A = the family

StoryOwnsOne:
    pop hl
    ld a, [hl+]
    ld e, a                             ; E = the value
    ld a, [hl]                          ; where
    call MonCount
    ld a, c
    or a
    jr nz, StoryTrue
    jr StoryFalse

StoryMonsters:
    pop hl
    inc hl
    ld a, [hl-]                         ; where
    push hl
    ld d, $ff                           ; every monster
    call MonCount
    pop hl
    jr StoryAtLeast

StoryLevel:
    pop hl
    ld a, [hl+]
    ld e, a                             ; E = the level
    ld a, [hl]                          ; the mode
    cp 1
    jr z, .avg
    ld d, a                             ; D = 0 any / 2 all
    ld hl, $ca8e                        ; the party list
    ld b, 3
    ld c, $00                           ; C = members at / above the level
    push de
    ld d, $00                           ; D = members
.m:
    ld a, [hl+]
    cp $ff
    jr z, .mn
    inc d
    push hl
    push bc
    push de
    ld hl, $cac1 + $4b                  ; record +$4B = the level
    call GetMonsterDataPtr              ; keeps BC / DE
    pop de
    pop bc
    ld a, [hl]
    pop hl
    cp e
    jr c, .mn
    inc c
.mn:
    dec b
    jr nz, .m
    ld a, d                             ; members
    pop de                              ; D = the mode
    ld b, a
    ld a, d
    or a
    ld a, c
    jr nz, .all
    or a                                ; any: one is
    jp nz, StoryTrue
    jp StoryFalse
.all:
    ld a, b
    or a
    jp z, StoryFalse                    ; no party
    cp c
    jp z, StoryTrue
    jp StoryFalse
.avg:
    push de
    call PartyAvgLevel                  ; A = the average (in-bank call)
    pop de
    cp e
    jp nc, StoryTrue
    jp StoryFalse

StorySeen:
    ld bc, $0000                        ; B = Library bit, C = seen
.s:
    push bc
    ld hl, $ca94
    ld a, b
    call TestBitInArray                 ; Z = not seen
    pop bc
    jr z, .u
    inc c
.u:
    inc b
    ld a, b
    cp $f0
    jr nz, .s
    pop hl
    jp StoryAtLeast

StoryChance:
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, 100
    call Div16x8To16                    ; A = RNG16 mod 100
    ld c, a
    pop hl
    ld a, c
    cp [hl]
    jp c, StoryTrue
    jp StoryFalse

StoryArena:
    pop hl
    ld a, [$cab4]                       ; arena classes won
    ld c, a
    jp StoryAtLeast

StoryAll:
    pop hl
    call TermsHold                      ; CF = 0: every term holds
    jp nc, StoryTrue
    jp StoryFalse

StoryAny:
    pop hl
    ld a, [hl+]
    or a
    jp z, StoryFalse
    ld d, a                             ; D = terms left
.t:
    push de
    call TermOne                        ; CF = 0: this term holds; HL past it
    pop de
    jp nc, StoryTrue
    dec d
    jr nz, .t
    jp StoryFalse

StoryBagRoom:
    ld hl, wInventory
    ld bc, $1400                        ; B = 20 slots, C = free
.f:
    ld a, [hl+]
    or a
    jr z, .free
    cp $ff
    jr nz, .used
.free:
    inc c
.used:
    dec b
    jr nz, .f
    pop hl
    jp StoryAtLeast

; HL -> [n] [n x dw flag (bit 15 = must be OFF)]. Out: CF = 0 every term holds,
; CF = 1 one fails; HL past the terms either way. Clobbers A, BC, DE.
TermsHold:
    ld a, [hl+]
    or a
    ret z                               ; no terms (CF = 0)
    ld d, a
.t:
    push de
    call TermOne
    pop de
    jr c, .fail
    dec d
    jr nz, .t
    and a
    ret
.fail:
    dec d                               ; skip the terms left
    ld a, d
    add a
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    scf
    ret

; HL -> dw flag (bit 15 = must be OFF). Out: CF = 0 it holds; HL += 2.
; Clobbers A, BC, E.
TermOne:
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    push hl
    ld a, b
    and $80
    ld e, a                             ; E bit 7 = the term wants OFF
    res 7, b
    call TestEventFlag                  ; Z = OFF, NZ = ON (keeps DE)
    pop hl
    jr z, .off
    bit 7, e
    jr nz, .no                          ; ON, but must be OFF
    and a
    ret
.off:
    bit 7, e
    jr z, .no                           ; OFF, but must be ON
    and a
    ret
.no:
    scf
    ret

; D = item -> C = how many of it the bag holds. Clobbers A, B, HL.
BagCount:
    ld hl, wInventory
    ld bc, $1400                        ; B = 20 slots, C = 0
.l:
    ld a, [hl+]
    cp d
    jr nz, .n
    inc c
.n:
    dec b
    jr nz, .l
    ret

; A = where (0 every monster you own, 1 the party), D = the record field to
; match ($FF = none: every monster counts), E = the value -> C = how many.
; Eggs (+$63 != 0) never count. Keeps DE. Clobbers A, B, HL.
MonCount:
    ld c, $00
    or a
    jr nz, .party
    ld b, $00                           ; B = slot 0-39
.slot:
    ld a, b
    ld hl, $cac1                        ; +$00 in use
    call GetMonsterDataPtr              ; keeps BC / DE
    ld a, [hl]
    or a
    jr z, .next
    ld a, b
    ld hl, $cac1 + $63                  ; +$63 the egg flag
    call GetMonsterDataPtr
    ld a, [hl]
    or a
    jr nz, .next
    call MonMatch
    jr nz, .next
    inc c
.next:
    inc b
    ld a, b
    cp 40
    jr nz, .slot
    ret
.party:
    ld hl, $ca8e
    ld a, 3
.p:
    push af
    ld a, [hl+]
    cp $ff
    jr z, .pn
    push hl
    ld b, a
    call MonMatch
    pop hl
    jr nz, .pn
    inc c
.pn:
    pop af
    dec a
    jr nz, .p
    ret

; B = slot -> Z = the monster matches (D = the field, E = the value; D = $FF:
; always). Keeps BC / DE. Clobbers A, HL.
MonMatch:
    ld a, d
    cp $ff
    ret z
    add LOW($cac1)
    ld l, a
    ld a, HIGH($cac1)
    adc $00
    ld h, a
    ld a, b
    call GetMonsterDataPtr
    ld a, [hl]
    cp e
    ret

; E = command n (1-255) -> run StoryCmdPtrs[n - 1]. Clobbers all.
StoryCommand:
    dec a
    cp STORY_CMD_COUNT
    ret nc
    ld l, a
    ld h, $00
    add hl, hl
    ld de, StoryCmdPtrs
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [hl+]                         ; the kind
    or a
    jr z, .take
    dec a
    jr z, .giveGold
    dec a
    jr z, .takeGold
    dec a
    ret nz
    ; 3 give_item [item, count]: room for all, or nothing
    ld a, [hl+]
    ld d, a                             ; D = the item
    ld e, [hl]                          ; E = how many
    ld hl, wInventory
    ld bc, $1400                        ; C = free slots
.free:
    ld a, [hl+]
    or a
    jr z, .isFree
    cp $ff
    jr nz, .notFree
.isFree:
    inc c
.notFree:
    dec b
    jr nz, .free
    ld a, c
    cp e
    ld a, $00
    jr c, .result                       ; no room for them all
    ld hl, wInventory
.put:
    ld a, [hl]
    or a
    jr z, .putHere
    cp $ff
    jr nz, .putNext
.putHere:
    ld [hl], d
    dec e
    jr z, .putDone
.putNext:
    inc hl
    jr .put
.putDone:
    ld a, $01
.result:
    ld [$d8e1], a
    ret
.giveGold:
    call .amount
    jp CompareGold                      ; ROM0: adds E:H:L, capped at 99,999
.takeGold:
    call .amount
    jp AddGold                          ; ROM0: subtracts E:H:L, floor 0
.amount:                                ; HL -> [lo, mid, hi] -> E:H:L
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld e, [hl]
    ld h, a
    ld l, c
    ret
.take:                                  ; 0 take_item [item, count]
    ld a, [hl+]
    ld d, a                             ; D = the item
    ld e, [hl]                          ; E = at most this many
    ld c, $00                           ; C = taken
.again:
    ld a, e
    or a
    jr z, .taken
    ld hl, wInventory + 19              ; the last one first
    ld b, 20
.find:
    ld a, [hl]
    cp d
    jr z, .found
    dec hl
    dec b
    jr nz, .find
    jr .taken                           ; none left
.found:
    ld a, b                             ; B = slot + 1: close the bag up
.shift:
    cp 20
    jr z, .last
    inc hl
    ld a, [hl-]
    ld [hl+], a
    inc b
    ld a, b
    jr .shift
.last:
    ld a, $ff
    ld [wInventory + 19], a
    inc c
    dec e
    jr .again
.taken:
    ld a, c
    ld [$d8e1], a
    ret

; A = the shop list ShopFill picked -> A = the list to sell (ShopSetTable).
; Keeps nothing but A's meaning; clobbers BC, DE, HL.
ShopSetPick:
    ld c, a                             ; C = the shop
    ld hl, ShopSetTable
.row:
    ld a, [hl+]
    cp $ff
    jr z, .none
    cp c
    jr nz, .skip
    push bc
    call TermsHold                      ; CF = 0: the set applies; HL past the terms
    pop bc
    jr c, .noTerms
    ld a, [hl]                          ; the set's list
    ret
.noTerms:
    inc hl                              ; past the list byte
    jr .row
.skip:
    ld a, [hl+]                         ; n
    add a
    inc a                               ; terms + the list byte
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    jr .row
.none:
    ld a, c
    ret

; -----------------------------------------------------------------------------
; Entries 12-15 (S141 r3): a custom room's NPC sheets 3-5 in VRAM bank 1 (see the header)
; -----------------------------------------------------------------------------
NpcSheetLoad06:
    ld a, [wInGateworld]
    or a
    jr nz, NpcSheetLoad0B
    ld a, [wMapID]
    cp $08
    jr nz, NpcSheetLoad0B
    ld hl, $0800                        ; bank $06's own map-$08 page (vanilla, kept)
    jp WaitDMATransfer

NpcSheetLoad0B:
    ld a, [wNpcSheetIdx]
    add $80
    ld h, a                             ; H = $80 + c
    ld l, $00
    ld a, [wInGateworld]
    or a
    jr z, .town
    ld a, h
    add $07
    ld h, a
    jp WaitDMATransfer                  ; a gate floor: + 7 (vanilla)
.town:
    ld a, [wMapID]
    cp $08
    jp z, WaitDMATransfer               ; map $08: + 0 (vanilla)
    cp $45
    jr nz, .five
    ld a, h
    add $02
    ld h, a
    jp WaitDMATransfer                  ; map $45: + 2 (vanilla)
.five:
    ld a, h
    add $05
    ld h, a                             ; + 5 (vanilla)
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jp c, WaitDMATransfer               ; a vanilla room: as before
    ld a, h
    cp $88
    jp c, WaitDMATransfer               ; sheets 0-2 ($8500-$87FF): bank 0 as before
    push hl
    call WaitDMATransfer                ; bank 0 first (the stream reads back its output)
    pop hl
NpcSheetToBank1:                        ; HL = the page: 256 bytes bank 0 -> bank 1
    ld b, $00
.byte:
    di
.w0:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, .w0
    ld c, [hl]                          ; VRAM bank 0 (VBK is 0 in the field)
    ld a, $01
    ldh [rVBK], a
.w1:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, .w1
    ld [hl], c
    xor a
    ldh [rVBK], a
    ei
    inc hl
    dec b
    jr nz, .byte
    ret

NpcDrawPlain:
    ld hl, $600b                        ; bank $60 entry 11 NpcColourDraw (S123)
    jr NpcDrawBank
NpcDrawMonster:
    ld hl, $0402                        ; bank $04 entry 2 (a monster's follower art)
NpcDrawBank:                            ; (BC / DE pass through to the builder unchanged)
    ldh a, [$cb]
    push af                             ; the first OAM piece it will write
    ldh a, [$c9]
    push af                             ; the tile base
    rst $10
    pop af
    ld d, a                             ; D = the tile base
    pop af
    ld e, a                             ; E = the first piece
    ld a, d
    cp $80
    ret c                               ; sheets 0-2, the party, the player: bank 0
    ld a, [wInGateworld]
    or a
    ret nz
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    ret c                               ; vanilla rooms: bank 0 (as before)
    ldh a, [$cb]
    sub e
    ret z
    ret c
    ld b, a                             ; B = the pieces written
    ld l, e
    ld h, $00
    add hl, hl
    add hl, hl
    ld de, $c003                        ; shadow OAM + 3 = the attr byte
    add hl, de
    ld de, $0004
.piece:
    set 3, [hl]                         ; tiles from VRAM bank 1
    add hl, de
    dec b
    jr nz, .piece
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

; ShopSetTable (S129, custom.shop_sets): [shop, n, n x dw flag (bit 15 = must be OFF), the set's list], $FF ends — bank $77 ShopSetPick
ShopSetTable:
    db $ff

; S126 (P3.14e1): the service lines the project replaces (bank $77 entry 3
; SayText; editor2/core/services.py). Set 0 applies to every NPC of a kind,
; set n while a script's wServiceLines = n.
SERVICE_SET_COUNT EQU 0
ServiceSetTable:
    dw ServicePairs_0   ; every NPC (everywhere sets, medal rewards)
ServicePairs_0:
    dw $FFFF

; S127 (P3.14e2): breeding pools (custom.breeding_pools; editor2/core/breeders.py).
; Pool: [measure mask (1 level, 2 arena, 4 seen, 8 story), story step,
;  milestones n, dw flag x n, bands n] + per band [level, arena x12,
;  seen / 2, story x step (the band's points), mates n, total weight]
;  + per mate [dw enemy row, db weight]. Read by entry 8 / BreedRoll.
BREED_POOL_COUNT EQU 0
BreedPoolPtrs:

; =============================================================================
; STORY CHECKS + STORY COMMANDS (S129, ROADMAP P3.14b; generated by editor2
; story.py from custom.checks, the quests / milestones and the scripts' story
; steps — PROJECT_COMPILER §2.42). Check n = event flag $1800 + n.
; =============================================================================
STORY_CHECK_COUNT EQU 2
StoryCheckPtrs:
    dw StoryCheck_0   ; flag $1800 = has_2_medals
    dw StoryCheck_1   ; flag $1801 = vault_rich
StoryCheck_0:  ; has_2_medals
    db $00, $1e, $02
StoryCheck_1:  ; vault_rich
    db $01, $e8, $03, $00

STORY_CMD_COUNT EQU 2
StoryCmdPtrs:
    dw StoryCmd_1   ; op $24 $FF01: take_item
    dw StoryCmd_2   ; op $24 $FF02: give_gold
StoryCmd_1:
    db $00, $1e, $02
StoryCmd_2:
    db $01, $f4, $01, $00

