; =============================================================================
; PAGE-2 SHEET COPIER — every page-2 bank's entry 0 (S168, ROADMAP P3.3g;
; template editor2/core/templates/page2_copy.asm, pasted by editor2/core/page2.py
; with {A} = "_P<bank>"; PROJECT_COMPILER §2.76, ROOM_DATA_FORMAT "Page 2: the
; second 128 tiles (S168)")
; =============================================================================
; A project tileset may hold 256 tiles: page 1 = the room sheet the game loads to
; VRAM bank 0 $9000-$97FF (ids $00-$7F), page 2 = 128 more tiles in VRAM BANK 1
; $9000-$97FF, drawn by every background cell whose GBC attribute has bit 3 (the
; attribute nibble 8-15: bank 1 + palette 0-7; the attr buffer $C200 carries it to
; the map unchanged — bank $0B jr_00b_4165, ROM0 CopyRowAttrGBCLoop /
; CopyColAttrGBCLoop). The original game never writes VRAM bank 1's tile area nor
; sets attribute bit 3 (tools/census_vram_bank1.py, extracted/vram_bank1_census.json).
;
; Page2Copy{A} (E = the sheet's index in this bank) — reached from the page-2 home
; bank's Page2Room by a local call (the home bank's own sheets) or `rst $10` to this
; bank's entry 0 (E survives RST_10's way in). Copies the sheet (2048 B, stored RAW —
; the LZ decoder cannot write VRAM bank 1: the VBlank handler leaves VBK 0 between
; its per-byte writes, S141) to VRAM bank 1 $9000 with General-Purpose DMA, the way
; the own-tile animation player does (templates/tileanim_player.asm, S102):
;  * LCD off: one transfer of 128 blocks;
;  * LCD on: 64 transfers of 2 blocks (32 B), each started the moment HBlank begins
;    (mode 3 -> 0, polled with interrupts off) or at once in VBlank lines 144-151;
;    2 blocks = 16 M-cycles = 64 dots + <= ~44 dots of latency < HBlank (>= 87 dots)
;    + the OAM scan (80 dots, VRAM free), so VRAM is never written in mode 3; line 127
;    (the LYC status-bar split) is skipped. ~64 scanlines in all.
; Then tiles $E0-$FF of bank 1 := bank 0's (Page2Mirror: the blank tile $E0 the field
; menu / the gate-wipe transitions fill the whole map with, under the room's attributes,
; for a few frames before their own attribute fill, and the window frames a window draws
; a row before that row's attributes — a page-2 cell then reads bank 1).
; VBK is 0 again before interrupts come back on. Clobbers A / BC / DE / HL.
; =============================================================================
Page2Copy{A}:
    ld a, e
    add a
    add a
    add a                               ; index * 8 = the sheet's high-byte offset
    add HIGH(Page2Sheets{A})
    ld h, a
    ld l, LOW(Page2Sheets{A})           ; = 0 (ALIGN[8])
    ld de, $9000
    ld b, 64                            ; 64 x 32 B
.chunk:
    ld a, h
    ldh [rHDMA1], a
    ld a, l
    ldh [rHDMA2], a
    ld a, d
    ldh [rHDMA3], a
    ld a, e
    ldh [rHDMA4], a
    ld c, $01                           ; 2 blocks
    call Page2Dma{A}
    ld a, l
    add $20
    ld l, a
    jr nc, .src
    inc h
.src:
    ld a, e
    add $20
    ld e, a
    jr nc, .dst
    inc d
.dst:
    dec b
    jr nz, .chunk
    ; fall through

; Tiles $E0-$FF of VRAM bank 0 ($8E00-$8FFF: the blank, the window frames, the
; arrows) -> the same tiles of VRAM bank 1, byte by byte (a VRAM-to-VRAM copy: the
; DMA cannot read VRAM). A window draws a row's tiles before its attributes (bank $77
; ScreenPush, the dialog box rows): for those few frames a frame tile over a page-2
; cell reads bank 1 — the copy makes it the same picture (as in a free-colour room,
; only the palette is the room's until the row's attributes follow; measured S168:
; the windows never rewrite $E0-$FF in bank 0 except $E5 / $E6).
Page2Mirror{A}:
    ld hl, $8e00
    ld bc, $0200
.byte:
    di
.w0:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, .w0
    ld d, [hl]                          ; VRAM bank 0 (VBK is 0 in the field)
    ld a, $01
    ldh [rVBK], a
.w1:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, .w1
    ld [hl], d
    xor a
    ldh [rVBK], a
    ei
    inc hl
    dec bc
    ld a, b
    or c
    jr nz, .byte
    ret

; One General-Purpose DMA of C + 1 blocks into VRAM bank 1 (source / destination
; already in HDMA1-4), started safely as described above.
Page2Dma{A}:
.wait:
    ldh a, [rLCDC]
    bit 7, a
    jr z, .now                          ; LCD off: VRAM is free
    ldh a, [rSTAT]
    and $03
    cp $01
    jr z, .vblank
    cp $03
    jr nz, .wait                        ; until pixel transfer (interrupts on)
    di
    ldh a, [rSTAT]
    and $03
    cp $03
    jr nz, .retry                       ; an interrupt ran in between
    ldh a, [rLY]
    cp 127
    jr z, .retry                        ; the LYC=127 status-bar split line
    ld a, $01
    ldh [rVBK], a
.hblank:
    ldh a, [rSTAT]
    and $03
    jr nz, .hblank
    ld a, c
    ldh [rHDMA5], a                     ; General-Purpose DMA, C + 1 blocks of 16 B
    xor a
    ldh [rVBK], a
    ei
    ret
.vblank:
    di
    ldh a, [rLY]
    cp 152
    jr nc, .retry                       ; too close to line 0
    cp 144
    jr c, .retry
.go:
    ld a, $01
    ldh [rVBK], a
    ld a, c
    ldh [rHDMA5], a
    xor a
    ldh [rVBK], a
    ei
    ret
.now:
    di
    jr .go
.retry:
    ei
    jr .wait
