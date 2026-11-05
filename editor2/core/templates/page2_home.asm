; =============================================================================
; PAGE-2 HOME — the room-load hook of a project whose tilesets use page 2 (S168,
; ROADMAP P3.3g; template editor2/core/templates/page2_home.asm, pasted into the FIRST
; page-2 bank by editor2/core/page2.py; PROJECT_COMPILER §2.76)
; =============================================================================
; Entry 1 (HL = $<home>01) Page2Room — far-called by bank $0B's same-size regions
; memorial_tiles_0 / _1, right after RoomEntry0_TilesetLoader / RoomEntry1_
; GraphicsLoader decoded the room sheet to VRAM bank 0 $9000 (every room load, every
; sheet reload after a full-screen menu / a battle). Since S154 those 7 dead bytes
; were the memorial's hook (bank $79 entry 8 MemRoomTiles, + S158 the hints' visit);
; with page 2 they call here and Page2Room calls that hook at its end when the
; project has statues / monuments (Page2Chain = 1).
;   wPage2On := 0; then on GBC, for a project room (map id >= $6B; $6B-$6F only
;   outside a gate — bank $71 CopyCustomRoomRecord's rule), the Page2Directory row
;   of (wMapRegion, wMapID): wPage2On := 1 and the room's page 2 is copied to VRAM
;   bank 1 $9000 (Page2Copy of the row's bank: this bank's own sheets by a local
;   call, another page-2 bank's by `rst $10` to its entry 0 with E = the index).
; A room without a row leaves bank 1 as it was — no cell of it has attribute bit 3.
; Page2Directory (generated): db region, map id, bank, index … ; db $FF.
; Clobbers A / BC / DE / HL (the caller reloads them).
; =============================================================================
Page2Room:
    xor a
    ld [wPage2On], a
    ld a, [wIsGBC]
    or a
    jr z, .chain                        ; DMG: no VRAM bank 1
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jr c, .chain
    cp $70
    jr nc, .find
    ld a, [wInGateworld]                ; $6B-$6F inside a gate = the ROM0 gate table
    or a
    jr nz, .chain
.find:
    ld hl, Page2Directory
.row:
    ld a, [hl+]                         ; region ($FF = the end)
    cp $ff
    jr z, .chain
    ld b, a
    ld a, [wMapRegion]
    cp b
    jr nz, .skip
    ld a, [wMapID]
    cp [hl]
    jr nz, .skip
    inc hl
    ld a, [hl+]                         ; the sheet's bank
    ld e, [hl]                          ; its index there
    ld d, a
    ld a, $01
    ld [wPage2On], a
    ld a, d
    cp PAGE2_HOME
    jr nz, .far
    call Page2Copy{A}
    jr .chain
.far:
    ld h, a
    ld l, $00
    rst $10                             ; that bank's entry 0 Page2Copy_P<bank> (E = index)
    jr .chain
.skip:
    inc hl
    inc hl
    inc hl
    jr .row
.chain:
    ld a, [Page2Chain]
    or a
    ret z
    ld hl, $7908                        ; bank $79 entry 8 MemRoomTiles (S154 / S158)
    rst $10
    ret
