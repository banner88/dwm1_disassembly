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
; Data (generated below the player):
;   TileAnimDirectory: 2 B per room (bank, index), TILEANIM_ROOMS rows.
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
    sub CUSTOM_ROOM_START
    ret c                               ; vanilla room (never called for one)
    cp TILEANIM_ROOMS
    ret nc                              ; past the directory: no own animations
    ld l, a
    ld h, $00
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
