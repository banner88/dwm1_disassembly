; =============================================================================
; BANK $6C — CUSTOM ROOM TILE ANIMATION (S102; compiler-owned, patches/bank_06c.asm)
; =============================================================================
; A custom room's OWN animated tiles (project.json custom.rooms[].tile_anims,
; PROJECT_COMPILER §2.19; ROOM_DATA_FORMAT "Animated tiles" → "Own tile
; animations (S102)"). Independent of the vanilla bank-$01 handlers: those
; animate fixed slots per vanilla room (the room's `animation` source still
; runs, bank $71 entry 3); THESE copy authored frames from this bank into any
; slot of the room's sheet, at any speed.
;
; Entry 0 (HL=$6C00) CustomTileAnimate — far-called every field frame by bank
; $71 entry 3 CustomAnimSource (itself called by the rewritten bank-$01
; PerRoomVRAMDispatch for custom rooms only, AFTER its guards: no animation
; while a menu / text / transition is up, and never on gate maze floors —
; exactly the vanilla conditions). Clobbers A/BC/DE/HL (the caller computes
; its own E afterwards).
;
; Data (generated below the template):
;   TileAnimRoomTable: dw per room, index wMapID - CUSTOM_ROOM_START
;     (TILEANIM_ROOMS entries), $0000 = the room has no own animations.
;   Group list of a room = records, then db 0:
;     +0 period   frames per step (1-255; 0 = end of list)
;     +1 phase    the first step's timer after entering the room (1-period:
;                 the compiler staggers groups so few steps share a frame)
;     +2 seqlen   steps per loop (1-127)
;     +3 nslots   tiles this group changes per step (1-TILEANIM_CAP)
;     +4 dw seq   seqlen x dw: the 16-aligned frame block of each step
;                 (nslots x 16 bytes, in the order of the dest list)
;     +6 nslots x dw  VRAM destination ($9000 + slot*16, VRAM bank 0)
;   Step 0 of every sequence is the art the sheet already holds (the room
;   loads it), so entering a room needs no copy.
;
; State (WRAM, patches/wram.asm, carved from wCustomPool): wTileAnimRoom =
; the map ID whose timers are live (a different custom room restarts them:
; timer := phase, step := 0); wTileAnimState = 2 bytes per group (timer, step).
; A copy writes a WHOLE frame (never a relative roll or swap), so anything
; that reloads the sheet mid-loop (a menu, a battle, a save/load) heals at the
; next step instead of drifting out of phase.
;
; Timing: at most TILEANIM_CAP tiles per field frame; a due group that does
; not fit waits (timer 0) for the next frame. Each tile is one General-Purpose
; DMA of 16 bytes (8 M-cycles, CPU halted — Pan Docs "CGB Registers"),
; started the moment HBlank begins (mode 3 -> 0, polled with interrupts off
; for at most the rest of mode 3, like the vanilla WaitVRAM) or at once in
; VBlank lines 144-151. HBlank >= 87 dots + OAM scan 80 dots (VRAM free) vs
; <= ~44 dots latency + 32 dots transfer: VRAM is never touched in mode 3.
; Line 127 is skipped (the LYC=127 STAT interrupt hides sprites under the
; status bar, LCDCInterruptHandler bank $00 — never delay it). ~1 scanline
; per tile. The game itself never uses HDMA/GDMA (S102 audit: every
; rHDMAx operand in the disassembly is data decoded as code).
; =============================================================================

SECTION "ROM Bank $06C", ROMX[$4000], BANK[$6C]

    db $6C                              ; bank self-ID at $4000

; rst-$10 entry table at $4001
    dw CustomTileAnimate                ; entry 0  (HL=$6C00)

TILEANIM_CAP EQU 8                      ; tiles copied per field frame, at most

CustomTileAnimate:
    ld a, [wMapID]
    sub CUSTOM_ROOM_START
    ret c                               ; vanilla room (never called for one)
    cp TILEANIM_ROOMS
    ret nc                              ; past the table: no own animations
    ld l, a
    ld h, $00
    add hl, hl
    ld de, TileAnimRoomTable
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a                             ; HL = this room's group list
    or h
    ret z                               ; $0000: nothing of its own
    ld a, [wMapID]
    ld b, a
    ld a, [wTileAnimRoom]
    cp b
    call nz, TileAnimRestart            ; another room's timers: restart (HL kept)
    ld a, TILEANIM_CAP
    ld [wTileAnimLeft], a
    ldh a, [rVBK]
    and $01
    ld [wTileAnimVBK], a                ; restored on the way out
    ld de, wTileAnimState
.group:
    ld a, [hl]                          ; +0 period (0 = end of the list)
    or a
    jr z, .done
    ld a, [de]                          ; timer
    or a
    jr z, .due                          ; deferred last frame: still due
    dec a
    ld [de], a
    jr z, .due
.next:
    inc de
    inc de                              ; next group's state
    inc hl
    inc hl
    inc hl                              ; +3 nslots
    ld a, [hl]
    add a
    add 3                               ; +3 -> next record at +6 + 2*nslots
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    jr .group
.done:
    ld a, [wTileAnimVBK]
    ldh [rVBK], a
    ret

.due:
    push hl                             ; record
    inc hl
    inc hl
    inc hl
    ld c, [hl]                          ; C = nslots
    ld a, [wTileAnimLeft]
    ld b, a
    sub c
    jr nc, .budgetOk
    ld a, b
    cp TILEANIM_CAP
    jr z, .budgetAll                    ; first copy this frame: always go
    pop hl
    jr .next                            ; no room this frame: timer stays 0
.budgetAll:
    xor a
.budgetOk:
    ld [wTileAnimLeft], a
    pop hl
    push hl
    ld a, [hl+]                         ; +0 period
    ld [de], a                          ; timer := period
    inc hl                              ; +2 seqlen
    inc de
    ld a, [de]                          ; step
    inc a
    cp [hl]
    jr c, .stepOk
    xor a                               ; wrap (also heals a stale step >= seqlen)
.stepOk:
    ld [de], a
    dec de
    inc hl
    inc hl                              ; +4 dw seq
    add a                               ; 2*step (seqlen <= 127)
    ld b, a
    ld a, [hl+]
    ld h, [hl]
    add b
    ld l, a
    adc h
    sub l
    ld h, a                             ; HL = &seq[step]
    ld a, [hl+]
    ld [wTileAnimSrc], a
    ld a, [hl]
    ld [wTileAnimSrc + 1], a            ; the frame block
    pop hl
    push hl
    push de
    ld de, 6
    add hl, de                          ; +6 dest list
    ld b, c
.tile:
    call TileAnimCopy
    dec b
    jr nz, .tile
    pop de
    pop hl
    jr .next

; (Re)start every group of the list at HL for map B: timer := phase, step 0.
; HL preserved.
TileAnimRestart:
    ld a, b
    ld [wTileAnimRoom], a
    push hl
    ld de, wTileAnimState
.loop:
    ld a, [hl]                          ; period (0 = end)
    or a
    jr z, .end
    inc hl
    ld a, [hl]                          ; +1 phase
    ld [de], a
    inc de
    xor a
    ld [de], a                          ; step 0 = the sheet's own art
    inc de
    inc hl
    inc hl                              ; +3 nslots
    ld a, [hl]
    add a
    add 3
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    jr .loop
.end:
    pop hl
    ret

; Copy ONE tile: 16 bytes from wTileAnimSrc (this bank, 16-aligned) to the
; VRAM address at [HL] (dw); HL += 2, wTileAnimSrc += 16. B/C/DE kept.
TileAnimCopy:
    ld a, [wTileAnimSrc + 1]
    ldh [rHDMA1], a
    ld a, [wTileAnimSrc]
    ldh [rHDMA2], a
    add $10
    ld [wTileAnimSrc], a
    jr nc, .srcOk
    ld a, [wTileAnimSrc + 1]
    inc a
    ld [wTileAnimSrc + 1], a
.srcOk:
    ld a, [hl+]
    ldh [rHDMA4], a                     ; destination low
    ld a, [hl+]
    ldh [rHDMA3], a                     ; destination high ($90-$97)
.wait:
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
    xor a
    ldh [rVBK], a                       ; the room sheet lives in VRAM bank 0
.hblank:
    ldh a, [rSTAT]
    and $03
    jr nz, .hblank                      ; A = 0 as HBlank begins
    ldh [rHDMA5], a                     ; General-Purpose DMA, 1 block of 16 B
    ei
    ret
.vblank:
    di
    ldh a, [rLY]
    cp 152
    jr nc, .retry                       ; too close to line 0
    cp 144
    jr c, .retry
    xor a
    ldh [rVBK], a
    ldh [rHDMA5], a
    ei
    ret
.retry:
    ei
    jr .wait

; -----------------------------------------------------------------------------
; TILEANIM DATA (generated by build_project.py from
; custom.rooms[].tile_anims — PROJECT_COMPILER §2.19)
; -----------------------------------------------------------------------------
TILEANIM_ROOMS EQU 0
TileAnimRoomTable:
