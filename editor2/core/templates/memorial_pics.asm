; =============================================================================
; THE MEMORIAL'S PICTURE BANK (S154; editor2/core/memorial.py — PROJECT_COMPILER
; §2.62, DATA_STRUCTURES "The memorial (S154)"). Engine template (sha256-pinned):
; the bank number at $4000, entry 0 MemPicDraw, then MemPics (generated): one
; 64-byte standing picture per species id 0-239 (4 tiles TL, TR, BL, BR — the
; species' walking frame "down A" as the game draws it, its layout's flips baked
; in, fitted into 16 x 16; ids that are no monster are blank). Only built when the
; project has memorial statues; bank $79 MemPicBank names the bank.
;
; Entry 0 MemPicDraw — far-called by bank $79 MemRoomTiles with wMemDraw = species,
; the statue's 4 BG tile ids (TL, TR, BL, BR), then its SHADE MAP (S154 r2): bits 1-0
; = the palette index the monster's colour 1 is drawn in, bits 3-2 its colour 2,
; bits 5-4 its colour 3 ($39 = 1 / 2 / 3, as the picture). Each picture byte pair
; (one row of 8 pixels, low / high plane) is laid over the tile's own pixels in VRAM
; bank 0: where the picture has colour 0 (both planes 0) the tile keeps its pixel
; (the background the author drew — the floor behind the statue: "transparent"),
; elsewhere the mapped index wins. The editor gives the statue a palette slot equal
; to the background's with ONE index the background does not use set to grey, and
; maps the monster's middle shade there (memorial_doc). Tile id < $80 = $9000 + id *
; 16 (the room's own sheet), else $8000 + id * 16. Every VRAM access waits for STAT
; mode 0 / 1 with interrupts off (ROM0 Write_gfx_tile's way), so it works with the
; LCD on or off. Clobbers all.
; =============================================================================

; (the generator writes the SECTION line and the bank's number at $4000 first)
    dw MemPicDraw

MemPicDraw:
    xor a
    ldh [rVBK], a
    ld a, [wMemDraw]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl                      ; x64
    ld de, MemPics
    add hl, de                      ; HL = the species' picture
    ld de, wMemDraw + 1
    ld c, 4
.tile:
    push bc
    push de
    ld a, [de]                      ; the tile id
    push hl
    ld b, a
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl                      ; x16
    ld a, h
    add $80
    bit 7, b
    jr nz, .vram
    add $10                         ; ids $00-$7F: the $9000 block
.vram:
    ld h, a
    ld d, h
    ld e, l                         ; DE = the tile in VRAM
    pop hl                          ; HL = the picture's bytes
    ld b, 8
.row:
    ld a, [hl+]
    ld [wMemTmp], a                 ; low plane
    ld a, [hl+]
    ld [wMemTmp + 1], a             ; high plane
    ld c, a
    ld a, [wMemTmp]
    or c
    jr z, .clear                    ; all colour 0: the tile keeps the row
    push bc
    push de
    push hl
    call MemShade                   ; wMemTmp = the row in the mapped indices
    pop hl
    pop de
    pop bc
    ld c, a                         ; C = where the tile shows through
    call MemVramRead
    and c
    push hl
    ld hl, wMemTmp
    or [hl]
    pop hl
    call MemVramWrite
    inc de
    call MemVramRead
    and c
    push hl
    ld hl, wMemTmp + 1
    or [hl]
    pop hl
    call MemVramWrite
    inc de
    jr .nextRow
.clear:
    inc de
    inc de
.nextRow:
    dec b
    jr nz, .row
    pop de
    inc de
    pop bc
    dec c
    jr nz, .tile
    ret

; wMemTmp = one picture row (low, high plane) -> wMemTmp = that row with each of
; the monster's colours 1 / 2 / 3 in the palette index the shade map (wMemDraw + 5)
; names; A = the pixels of colour 0 (where the tile shows through). Clobbers BC, DE,
; HL.
MemShade:
    ld a, [wMemTmp]
    ld b, a                         ; B = low plane
    ld a, [wMemTmp + 1]
    ld c, a                         ; C = high plane
    and b
    ld h, a                         ; H = colour 3 pixels
    ld a, c
    cpl
    and b
    ld l, a                         ; L = colour 1 pixels
    ld a, b
    cpl
    and c
    ld e, a                         ; E = colour 2 pixels
    ld a, b
    or c
    cpl
    push af                         ; the see-through pixels
    ld a, [wMemDraw + 5]
    ld d, a                         ; D = the shade map
    ld bc, $0000                    ; B = the new low plane, C = the new high plane
    bit 0, d
    jr z, .c1hi
    ld a, b
    or l
    ld b, a
.c1hi:
    bit 1, d
    jr z, .c2lo
    ld a, c
    or l
    ld c, a
.c2lo:
    bit 2, d
    jr z, .c2hi
    ld a, b
    or e
    ld b, a
.c2hi:
    bit 3, d
    jr z, .c3lo
    ld a, c
    or e
    ld c, a
.c3lo:
    bit 4, d
    jr z, .c3hi
    ld a, b
    or h
    ld b, a
.c3hi:
    bit 5, d
    jr z, .done
    ld a, c
    or h
    ld c, a
.done:
    ld a, b
    ld [wMemTmp], a
    ld a, c
    ld [wMemTmp + 1], a
    pop af
    ret

; A = [DE] in VRAM (STAT mode 0 / 1, interrupts off around the read).
MemVramRead:
    di
.wait:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, .wait
    ld a, [de]
    ei
    ret

; [DE] := A in VRAM (the same wait).
MemVramWrite:
    push af
    di
.wait:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, .wait
    pop af
    ld [de], a
    ei
    ret

MemPics:
