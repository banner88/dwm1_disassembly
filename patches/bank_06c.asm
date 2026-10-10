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
; S139 (ROADMAP ARC CAP2d): bank $6C is the FIRST animation bank, not the
; only one. CustomTileAnimate is a FORWARDER: TileAnimDirectory[wMapID - $6B]
; = (bank, index) of the room's animations — bank $6C itself (a local jump to
; TileAnimPlay with E = index) or an ANIMATION BANK $80+ (rst $10 to that
; bank's entry 0 = TileAnimPlay_A<bank>, E = index). Bank 0 = the room has no
; own animations; an id past the directory (a vanilla id, a stale save past
; the last animated room) returns at once. The player itself is the pinned
; block templates/tileanim_player.asm, pasted below (and into every
; animation bank) — the GDMA must read its frames from the bank it runs in.
; Looked up on EVERY call (nothing cached), like the place banks (S136).
;
; S140 (ROADMAP ARC CAP3a — regions): the directory is indexed by the PLACE
; NUMBER of (wMapRegion, wMapID) — PlaceNum6C (templates/place_number.asm,
; pasted below the head with RegionTable6C / GlobalPlaceIds6C). One region:
; the place number is wMapID - $6B, as before. The player's restart tag
; wTileAnimRoom is dropped ($FF) by the commit when the region changes, so two
; places sharing a map id in different regions restart their timers.
;
; Data (generated below the player):
;   TileAnimDirectory: 2 B per place (bank, index), TILEANIM_ROOMS rows.
;   TileAnimRoomTable: dw per room of THIS bank (the directory's index).
;   Group lists / sequences / 16-aligned frame blocks: tileanim_player.asm.
; =============================================================================

SECTION "ROM Bank $06C", ROMX[$4000], BANK[$6C]

    db $6C                              ; bank self-ID at $4000

; rst-$10 entry table at $4001
    dw CustomTileAnimate                ; entry 0  (HL=$6C00)

TILEANIM_CAP EQU 8                      ; tiles copied per field frame, at most

CustomTileAnimate:
    ld a, [wMapID]
    call PlaceNum6C                     ; S140: HL = the place number (region-aware)
    ret c                               ; vanilla room (never called for one) / no place
    ld a, l
    sub LOW(TILEANIM_ROOMS)
    ld a, h
    sbc HIGH(TILEANIM_ROOMS)
    ret nc                              ; past the directory: no own animations
    add hl, hl
    ld de, TileAnimDirectory
    add hl, de
    ld a, [hl+]                         ; the room's animation bank (0 = none)
    or a
    ret z
    ld e, [hl]                          ; E = its index in that bank's table
    cp $6C
    jp z, TileAnimPlay                  ; bank $6C's own rooms
    ld h, a
    ld l, $00
    rst $10                             ; that bank's entry 0, TileAnimPlay_A<bank>
    ret

; =============================================================================
; TILE ANIMATION PLAYER — plays the own tile animations of the rooms whose
; groups + frames live in THIS bank (S139, ROADMAP ARC CAP2d; template
; editor2/core/templates/tileanim_player.asm; the S102 bank $6C code, moved)
; =============================================================================
; The compiler pastes this block into bank $6C with  = "" and into every
; ANIMATION BANK ($80+, editor2/core/tileanim.py plan) with  = "_A<bank>",
; where TileAnimPlay_A<bank> is the bank's rst $10 entry 0. The code must run
; in the bank that holds the frames: the General-Purpose DMA reads its source
; from the address space as mapped at the moment of the copy.
;
; TileAnimPlay (E = the room's index in TileAnimRoomTable) — reached from
; bank $6C CustomTileAnimate (the forwarder: TileAnimDirectory[wMapID - $6B] =
; bank, index) by a local jump (bank $6C) or `rst $10` (E survives the far
; call's way in: RST_10 / RST_08 touch A, BC, HL only). Clobbers A/BC/DE/HL.
;
; Group list of a room = records, then db 0:
;   +0 period   frames per step (1-255; 0 = end of list)
;   +1 phase    the first step's timer after entering the room (1-period:
;               the compiler staggers groups so few steps share a frame)
;   +2 seqlen   steps per loop (1-127)
;   +3 nslots   tiles this group changes per step (1-TILEANIM_CAP)
;   +4 dw seq   seqlen x dw: the 16-aligned frame block of each step
;               (nslots x 16 bytes, in the order of the dest list), in THIS bank
;   +6 nslots x dw  VRAM destination ($9000 + slot*16, VRAM bank 0)
; Step 0 of every sequence is the art the sheet already holds (the room
; loads it), so entering a room needs no copy.
;
; State (WRAM, patches/wram.asm, carved from wCustomPool): wTileAnimRoom =
; the map ID whose timers are live (a different custom room restarts them:
; timer := phase, step := 0); wTileAnimState = 2 bytes per group (timer, step).
; The state is shared by every animation bank — only one room is on screen.
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

TileAnimPlay:
    ld l, e
    ld h, $00
    add hl, hl
    ld de, TileAnimRoomTable
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a                             ; HL = this room's group list
    or h
    ret z                               ; $0000: nothing here (never emitted)
    ld a, [wMapID]
    ld b, a
    ld a, [wTileAnimRoom]
    cp b
    call nz, TileAnimRestart         ; another room's timers: restart (HL kept)
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
; PlaceNum6C (S140, ROADMAP ARC CAP3a — regions) — the PLACE NUMBER of a custom
; map id in the current region. A custom place is (wMapRegion, wMapID); its
; place number indexes every per-place table the compiler emits (P order:
; region 0's places, then region 1's, ... — each region from id $6B up). This
; block is pasted into every bank whose code indexes such a table (banks $60,
; $6C, $71, $76; suffix = the bank), each with its own copy of the two small
; tables below (emitted by the compiler next to the bank's data):
;   RegionTable6C:    db n_regions, then per region: db count (ids $6B .. $6B
;                      + count - 1 are its places, holes = placeholders), dw base
;                      (the place number of its id $6B)
;   GlobalPlaceIds6C: db (id - $6B) ... db $FF — the GLOBAL places (the arena
;                      copies, which ROM0 ArenaAlias knows by bare id): region 0's
;                      places wherever the player stands; no other region uses
;                      those ids.
; One region (every project up to 128 places): count = the place count, base 0
; — the place number is id - $6B, as the tables were indexed before S140.
;
; PlaceNum6C: A = a map id / script type, region = wMapRegion.
; PlaceNumIn6C: E = a map id / script type, D = the region.
; Out: CF clear = a place, HL = its place number; CF set = none — a vanilla id
; ($00-$6A), a link id or anything >= $EB (REGION_IDS), a region the build
; lacks (a stale save), an id past its region's last place. Keeps BC.
; Clobbers A, DE.
; -----------------------------------------------------------------------------
PlaceNum6C:
    ld e, a
    ld a, [wMapRegion]
    ld d, a
PlaceNumIn6C:
    ld a, e
    sub CUSTOM_ROOM_START
    ret c                               ; a vanilla id
    cp REGION_IDS
    ccf
    ret c                               ; $EB+: a link id / not a place
    ld e, a                             ; E = id - $6B
    ld hl, GlobalPlaceIds6C
.global:
    ld a, [hl+]
    cp $FF
    jr z, .region
    cp e
    jr nz, .global
    ld d, $00                           ; a global place: region 0's
.region:
    ld hl, RegionTable6C
    ld a, d
    cp [hl]
    ccf
    ret c                               ; a region this build does not have
    inc hl
    ld d, a
    add a
    add d                               ; region * 3
    add l
    ld l, a
    adc h
    sub l
    ld h, a                             ; HL -> [count, base lo, base hi]
    ld a, e
    cp [hl]
    ccf
    ret c                               ; past the region's last place
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a                             ; HL = the region's first place number
    ld d, $00
    add hl, de                          ; + (id - $6B); CF clear (no overflow)
    ret

; -----------------------------------------------------------------------------
; TILEANIM DATA (generated by build_project.py from
; custom.rooms[].tile_anims — PROJECT_COMPILER §2.19 / §2.48)
; -----------------------------------------------------------------------------
TILEANIM_ROOMS EQU 0
; S140 (ROADMAP ARC CAP3a): regions — [count, base] per region (PlaceNum6C)
RegionTable6C:
    db 1   ; regions
    db 9
    dw 0   ; region 0: ids $6B-$73, places 0-8
GlobalPlaceIds6C:   ; the arena copies (region 0 wherever you are)
    db $FF
TileAnimDirectory:   ; per PLACE (place number, S140): animation bank (0 = none), index
TileAnimRoomTable:   ; index = TileAnimDirectory's (bank $6C)
