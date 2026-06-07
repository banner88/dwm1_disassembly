; =============================================================================
; BANK $0B — ROOM SYSTEM
; =============================================================================
; This bank contains the entire room loading pipeline:
;   - Tileset/graphics loading (entries 0,1)
;   - Screen/scroll management (entry 2)
;   - NPC interaction dispatch (entries 3,4,5)
;   - Exit detection — runs EVERY STEP (entry 6)
;   - Room initialization after transition (entry 7)
;   - Step block reader (entry 8)
;   - Special room handlers (entry 9)
;
; Cross-bank calls use `rst $10` where HL = (bank << 8) | entry_index.
; rst $10 saves current bank, switches to bank H, calls $4001+(L*2) jump
; table entry, then restores original bank.
;
; Room Data Chain:
;   ptr_table[$4B43 + mapID*2] → screen_ptr_block (up to 4 screen slots × 2)
;     → step_block: [ram_flag_ptr:2] then [step_entry × N] + terminator
;       → step_entry (6 bytes): [step_id:1][tileset:1][interact_ptr:2][exit_ptr:2]
;         → interact_block: NPC entries (5 bytes each) + $FF terminator
;         → exit_block: exit entries (7 bytes each) + $FF terminator
;
; Sources: Mallos31/dwm disassembly, NiyaDev/DWM rst docs,
;          user reverse-engineering (ROUTING_DISCOVERIES.md, NPC_AND_ROUTING_HANDOFF.md)
; =============================================================================

SECTION "ROM Bank $00b", ROMX[$4000], BANK[$b]
    db $0b	; ROM bank ID

; -----------------------------------------------------------------------------
; JUMP TABLE — dispatched via rst $10 with H=$0B
; Called from bank $51 game loop. Entry = L value in HL before rst $10.
; -----------------------------------------------------------------------------
    dw RoomEntry0_TilesetLoader     ; Entry 0: load tileset + apply map change
    dw RoomEntry1_GraphicsLoader    ; Entry 1: load tileset only (no map change)
    dw RoomEntry2_ScreenScroll      ; Entry 2: screen/scroll position manager
    dw RoomEntry3_NPCDispatch       ; Entry 3: NPC interaction handler
    dw RoomEntry4_NPCMovement       ; Entry 4: NPC movement/patrol
    dw RoomEntry5_NPCRender         ; Entry 5: NPC sprite render
    dw RoomEntry6_ExitChecker       ; Entry 6: exit detection (RUNS EVERY STEP)
    dw RoomEntry7_RoomInit          ; Entry 7: room initializer (after transition)
    dw ReadStepBlock                ; Entry 8: read step_id + tileset from ptr table
    dw RoomEntry9_SpecialRooms      ; Entry 9: special room handlers (mazes, arenas)

; =============================================================================
; ENTRY 0: RoomEntry0_TilesetLoader ($4015)
; =============================================================================
; Called during room transitions. If wIsPlayerChangingMaps is set, copies the
; destination map_type from $C96D to wMapID (making the transition "real").
; Then loads the tileset graphics from the tileset table at $26DD (normal) or
; $2A5D (gate worlds). Does NOT read the room pointer table at $4B43.
; -----------------------------------------------------------------------------
RoomEntry0_TilesetLoader:
labelb_4015:
    ld a, [wIsPlayerChangingMaps]   ; $C96C — is a map change pending?
    or a
    jr z, jr_00b_4027               ; skip if no pending change

    ; Apply pending map change: copy destination to active
    ld a, [$c96d]                   ; destination map_type (set by exit checker)
    ld [wMapID], a                  ; $C968 — now the active map
    ld a, [$c96e]                   ; destination gate flag
    ld [wInGateworld], a            ; $C969 — gate/normal mode

jr_00b_4027:
    ld hl, $1605	; rst $10: bank $16, entry 5 — tileset prep function
    rst $10



    ; Select tileset table based on gate flag
    ; Normal rooms: $26DD (bank 0), Gate rooms: $2A5D (bank 0)
    ; Each entry is 8 bytes: [gfx_ptr:2][spawn_data:6]
    ld de, $26dd                    ; tileset_table (normal rooms)
    ld a, [wInGateworld]
    or a
    jr z, jr_00b_4037

    ld de, $2a5d                    ; tileset_table (gate rooms)

jr_00b_4037:
    ; Index into table: DE = tileset_table + wMapID * 8
    ld a, [wMapID]
    ld l, a
    ld h, $00
    add hl, hl                      ; × 2
    add hl, hl                      ; × 4
    add hl, hl                      ; × 8
    add hl, de                      ; HL = &tileset_table[mapID]
    ld e, [hl]
    inc hl
    ld d, [hl]
    inc hl
    push hl
    ld hl, $9000
    call Call_000_1577
    ld a, [wMapID]
    ld a, $08
    jr nz, jr_00b_4076

    ld de, $291d
    ld hl, $8800
    call Call_000_1577
    xor a
    ld [$c8a6], a
    ld [$c8a7], a
    jr jr_00b_4076

    ld a, [$d951]
    cp $07
    jr nz, jr_00b_4076

    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA

jr_00b_4076:
    pop hl
    ld a, [hl+]
    ldh [$9d], a
    ld a, [hl+]
    ldh [$9e], a
    ld a, [hl+]
    ldh [$9f], a
    ld a, [hl]
    ldh [$a0], a
    ld hl, $1606
    rst $10
    ret

; =============================================================================
; ENTRY 1: RoomEntry1_GraphicsLoader ($4088)
; =============================================================================
; Same as Entry 0 but WITHOUT applying pending map change.
; Used for graphics refresh when room doesn't change (e.g., screen scroll).
; Does NOT read the room pointer table at $4B43.
; Reads from tileset table $26DD/$2A5D only.
; -----------------------------------------------------------------------------
RoomEntry1_GraphicsLoader:
labelb_4088:
    ld de, $26dd
    ld a, [wInGateworld]
    or a
    jr z, jr_00b_4094

    ld de, $2a5d

jr_00b_4094:
    ld a, [wMapID]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    inc hl
    push hl
    ld hl, $9000
    call Call_000_1577
    ld a, [wMapID]
    ld a, $08
    jr nz, jr_00b_40c0

    ld de, $291d
    ld hl, $8800
    call Call_000_1577
    xor a
    ld [$c8a6], a
    ld [$c8a7], a

jr_00b_40c0:
    pop hl
    ld a, [hl+]
    ldh [$9d], a
    ld a, [hl+]
    ldh [$9e], a
    ld a, [hl+]
    ldh [$9f], a
    ld a, [hl]
    ldh [$a0], a
    ret

RoomEntry2_ScreenScroll:
labelb_40ce:
    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, $80
    call Call_000_1e0d
    ld a, l
    add a
    add a
    ld [$c925], a
    ld a, $80
    ld c, l
    ld b, h
    call Call_000_1de6
    ld a, l
    ldh [$bb], a
    ld a, h
    ldh [$bc], a
    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, $a0
    call Call_000_1e0d
    ld a, [$c925]
    add l
    ld [$c925], a
    ld a, $a0
    ld c, l
    ld b, h
    call Call_000_1de6
    ld a, l
    ldh [$b7], a
    ld a, h
    ldh [$b8], a
    ld a, [wGameState]
    bit 1, a
    jr nz, jr_00b_4134

    bit 3, a
    jr nz, jr_00b_4134

    ld hl, $1700
    rst $10
    ld a, [$c8ea]
    bit 7, a
    jr nz, jr_00b_4134

    call Call_00b_4239
    ld hl, $c300
    call Call_000_14cf
    ld de, $c300
    call Call_00b_4309
    ld hl, $1701
    rst $10

jr_00b_4134:
    ld a, [wIsGBC]
    or a
    jr z, jr_00b_41b3

    di
    call Call_000_1aa6
    ld a, $01
    ldh [rVBK], a
    ei
    ldh a, [$bb]
    and $f8
    ld l, a
    xor a
    sla l
    rla
    sla l
    rla
    ld h, $98
    add h
    ld h, a
    ldh a, [$b7]
    rrca
    rrca
    rrca
    and $1f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld de, $c200
    ld c, $10

jr_00b_4165:
    ld b, $0a
    push hl

jr_00b_4168:
    ld a, [de]
    swap a
    and $0f
    call Write_gfx_tile
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
    ld a, [de]
    and $0f
    call Write_gfx_tile
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
    inc de
    dec b
    jr nz, jr_00b_4168

    pop hl
    ld a, e
    add $06
    ld e, a
    ld a, d
    adc $00
    ld d, a
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a
    pop bc
    dec c
    jr nz, jr_00b_4165

    di
    call Call_000_1aa6
    ld a, $00
    ldh [rVBK], a
    ei

jr_00b_41b3:
    ldh a, [$bb]
    and $f8
    ld l, a
    xor a
    sla l
    rla
    sla l
    rla
    ld h, $98
    add h
    ld h, a
    ldh a, [$b7]
    rrca
    rrca
    rrca
    and $1f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld de, $c300
    ld c, $10

jr_00b_41d5:
    ld b, $14
    push hl

jr_00b_41d8:
    ld a, [de]
    call Write_gfx_tile
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
    inc de
    dec b
    jr nz, jr_00b_41d8

    pop hl
    ld a, e
    add $0c
    ld e, a
    ld a, d
    adc $00
    ld d, a
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a
    pop bc
    dec c
    jr nz, jr_00b_41d5

    ld a, [$c925]
    ld hl, $c950
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    ret

RoomEntry3_NPCDispatch:
labelb_4213:
    ld hl, $1700
    rst $10
    call Call_00b_4239
    ld hl, $c500
    call Call_000_14cf
    ld de, $c500
    call Call_00b_4309
    ld hl, $1701
    rst $10
    ld a, [$c925]
    ld hl, $c950
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    ret


; =============================================================================
; ENTRY 8: ReadStepBlock ($4239)
; =============================================================================
; Reads step_id and tileset from the room pointer table.
; Returns: DE = [step_id, tileset] (first 2 bytes of current step entry)
;
; THIS IS ONE OF FOUR FUNCTIONS THAT READ THE POINTER TABLE AT $4B43.
; All four share identical pointer-chasing code but return different fields:
;   ReadStepBlock ($4239): returns bytes 0-1 (step_id + tileset) → DE
;   ReadInteractPtr ($4274): skips 2, returns bytes 2-3 (interact_ptr) → HL
;   ExitChecker ($451D): skips 4, returns bytes 4-5 (exit_ptr) → HL
;   ~$44A7 func: skips 4, returns bytes 4-5 (exit_ptr) → HL
;
; For cross-bank rooms, ALL FOUR must be modified to support data
; outside bank $0B. This is the key architectural constraint.
; -----------------------------------------------------------------------------
ReadStepBlock:
Call_00b_4239:
    ld a, [wInGateworld]            ; gate rooms use different path
    or a
    jr z, jr_00b_4244

    ld hl, $1609                    ; rst $10: bank $16, entry 9 — gate step reader
    rst $10
    ret


jr_00b_4244:
    ; === POINTER TABLE READ — shared pattern ===
    ; Step 1: ptr_table[$4B43 + mapID * 2] → screen_ptr_block
    ld hl, $4b43                    ; room pointer table (107 entries × 2 bytes)
    ld a, [wMapID]                  ; current room map_type ($C968)
    add a                           ; mapID × 2 (2 bytes per entry)
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a                         ; HL = &ptr_table[mapID]
    ld a, [hl+]
    ld h, [hl]
    ld l, a                         ; HL = *ptr_table[mapID] → screen_ptr_block

    ; Step 2: screen_ptr_block[$C925 * 2] → step_block
    ld a, [$c925]                   ; screen_index (which screen of multi-screen room)
    add a                           ; × 2 (pointer is 2 bytes)
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a                         ; HL = &screen_ptr_block[screen_index]
    ld a, [hl+]
    ld h, [hl]
    ld l, a                         ; HL = *screen_ptr_block[screen] → step_block

    ; Step 3: step_block[0:2] = ram_flag_ptr, then index by step value
    ; step_block format: [ram_flag_ptr:2][step0:6][step1:6]...[FF]
    ld e, [hl]                      ; ram_flag_ptr low byte
    inc hl
    ld d, [hl]                      ; ram_flag_ptr high byte (DE = RAM address)
    inc hl                          ; HL now points to first step entry
    ld a, [de]                      ; read current step value from RAM
    ; Index: step_value * 6 (each step entry is 6 bytes)
    ld e, a
    add a                           ; × 2
    add e                           ; × 3
    add a                           ; × 6
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a                         ; HL = &step_entries[step_value]

    ; Step 4 (ReadStepBlock specific): return bytes 0-1 as DE
    ld e, [hl]                      ; step_id
    inc hl
    ld d, [hl]                      ; tileset byte
    ret


; =============================================================================
; ReadInteractPtr ($4274)
; =============================================================================
; Reads the interact_ptr (NPC data pointer) from the room pointer table.
; Returns: HL = interact_ptr (bytes 2-3 of current step entry)
;
; Same pointer-chasing as ReadStepBlock but skips step_id+tileset (2 bytes)
; and returns interact_ptr instead.
; Called by Entry 7 (RoomEntry7_RoomInit) to load NPC data after transition.
; -----------------------------------------------------------------------------
ReadInteractPtr:
; ---------------------------------------------------------------------------
; GetCurrentNPCList — Trace room data chain to find NPC interact block
; ---------------------------------------------------------------------------
; Follows the room data pointer chain to find the NPC list for the
; current room, screen, and step:
;
;   $4B43[wMapID × 2] → screen_ptr_block
;   screen_ptr_block[$C925 × 2] → step_block
;   step_block[0:2] → ram_flag_ptr (DE) → [DE] = current step_id
;   step_block + 2 + step_id × 6 → step_entry
;   step_entry[2:4] → interact_ptr = NPC list
;
; Output: HL = pointer to first NPC entry (5-byte entries, $FF terminated)
; ---------------------------------------------------------------------------
Call_00b_4274:
    ld a, [wInGateworld]
    or a
    jr nz, jr_00b_42ac       ; Gate world uses different lookup path

    ; Level 1: map_type → screen_ptr_block
    ld hl, $4b43             ; Room pointer table base
    ld a, [wMapID]
    add a                    ; × 2 (word-sized entries)
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a                  ; HL = $4B43 + wMapID × 2
    ld a, [hl+]
    ld h, [hl]
    ld l, a                  ; HL = screen_ptr_block

    ; Level 2: screen → step_block
    ld a, [$c925]            ; Current screen index
    add a                    ; × 2
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a                  ; HL = step_block

    ; Level 3: read step_id from RAM
    ld e, [hl]
    inc hl
    ld d, [hl]               ; DE = ram_flag_ptr
    inc hl                   ; HL = step_block + 2 (step_entries start)
    ld a, [de]               ; A = current step_id (from RAM)
    ld e, a
    add a                    ; × 2
    add e                    ; × 3
    add a                    ; × 6 (6 bytes per step_entry)
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a                  ; HL = step_entry for current step_id
    inc hl
    inc hl                   ; Skip byte 0 (step_id) and byte 1 (tileset)
    ld a, [hl+]
    ld h, [hl]
    ld l, a                  ; HL = interact_ptr (NPC list)
    ret


jr_00b_42ac:
    ld a, [$c926]
    cp $ff
    jr nz, jr_00b_42b7

    ld hl, $4308
    ret


jr_00b_42b7:
    ld hl, $42c8
    ld a, [$c92b]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ret


    ret c

    ld b, d
    sbc $42
    db $e4
    ld b, d
    ld [$f042], a
    ld b, d
    or $42
    db $fc
    ld b, d
    ld [bc], a
    ld b, e
    rrca
    dec bc
    ld bc, $0101
    rst $38
    rrca
    dec bc
    ld bc, $0101
    rst $38
    rrca
    inc c
    ld bc, $0201
    rst $38
    rrca
    inc c
    ld bc, $0201
    rst $38
    rrca
    ld de, $0101
    inc bc
    rst $38
    rrca
    ld [$0101], sp
    inc b
    rst $38
    rrca
    rrca
    ld bc, $0501
    rst $38
    rrca
    ld b, $01
    ld bc, $ff06
    rst $38

Call_00b_4309:
    ld a, [wInGateworld]
    or a
    ret z

    ld hl, $c960
    ld a, [$c925]
    cp [hl]
    ret nz

    ld a, [$c962]
    ld l, a
    ld a, [$c963]
    ld h, a
    add hl, de
    ld a, $3c
    ld [hl+], a
    inc a
    ld [hl], a
    ld a, l
    add $1f
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, $3e
    ld [hl+], a
    inc a
    ld [hl], a
    ret

RoomEntry4_NPCMovement:
labelb_4332:
    ld a, $00
    ldh [$d6], a
    ld hl, $d7d2
    call Call_00b_433f
    ldh [$d5], a
    ret


Call_00b_433f:
jr_00b_433f:
    ld a, [hl]
    cp $ff
    jr z, jr_00b_4366

    bit 6, a
    jr nz, jr_00b_4357

    call Call_00b_43e5
    jr nz, jr_00b_4357

    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    ret


jr_00b_4357:
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ldh a, [$d6]
    inc a
    ldh [$d6], a
    jr jr_00b_433f

jr_00b_4366:
    ld a, $ff
    ldh [$d6], a
    call Call_00b_4274

jr_00b_436d:
    ld a, [hl]
    cp $ff
    ret z

    bit 7, a
    jr z, jr_00b_43a1

    and $f0
    cp $80
    jr nz, jr_00b_4397

    call Call_00b_4452
    jr nz, jr_00b_4397

    ld a, [hl]
    and $0f
    cp $0f
    jr z, jr_00b_438d

    ld b, a
    ldh a, [$8e]
    cp b
    jr nz, jr_00b_4397

jr_00b_438d:
    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    ret


jr_00b_4397:
    ld a, l
    add $05
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00b_436d

jr_00b_43a1:
    ld a, $ff
    ret

; ---------------------------------------------------------------------------
; Entry 5: NPCScriptIDLookup — Find NPC at facing position, return script_id
; ---------------------------------------------------------------------------
; Called by bank $01 NPCTalkHandler when player presses A.
; Player position is pre-loaded to $FFDB-$FFDE by the caller.
;
; Flow:
;   1. Default $FFD5 = $FF (no NPC)
;   2. Guard: if $FF90 bit 6 set or $D8D7 non-zero → return
;   3. Call Call_00b_43b8:
;      a. Get current room's NPC list (interact block) via Call_00b_4274
;      b. Walk NPC entries (5 bytes each, $FF terminated)
;      c. For each: check type byte (bit 7 must be set = interactable)
;      d. If type & $F0 == $90: check if NPC is at player's facing position
;      e. If match: return byte 4 (script_id) in A
;      f. If no match: advance 5 bytes, check next NPC
;   4. Result stored to $FFD5 by caller
;
; NPC entry format (5 bytes): [type] [sprite] [X] [Y] [script_id]
; Returns: A = script_id ($FF if no interactable NPC found)
; ---------------------------------------------------------------------------
RoomEntry5_NPCRender:
labelb_43a4:
    ld a, $ff
    ldh [$d5], a             ; Default: no NPC found
    ldh a, [$90]
    bit 6, a
    ret nz                   ; Busy flag set → return

    ld a, [$d8d7]
    or a
    ret nz                   ; Script already running → return

    call Call_00b_43b8       ; Search for NPC at facing position
    ldh [$d5], a             ; Store result (script_id or $FF)
    ret


; ---------------------------------------------------------------------------
; NPCSearchAtFacing — Walk NPC list, find match at player's facing position
; ---------------------------------------------------------------------------
Call_00b_43b8:
    call Call_00b_4274       ; Get interact_block pointer for current room/step

jr_00b_43bb:
    ld a, [hl]               ; Read NPC type byte (byte 0)
    cp $ff
    ret z                    ; $FF terminator → no more NPCs, return $FF

    bit 7, a
    jr z, jr_00b_43e2        ; Bit 7 clear → NPC not interactable, return $FF

    and $f0
    cp $90
    jr nz, jr_00b_43d8       ; Type != $9x → skip this NPC

    call Call_00b_4452       ; Check if NPC is at player's facing position
    jr nz, jr_00b_43d8       ; Not at facing position → skip

    ; NPC found at facing position! Read script_id (byte 4)
    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a                  ; HL = NPC entry + 4
    ld a, [hl]               ; A = script_id (byte 4 of NPC entry)
    ret


jr_00b_43d8:
    ld a, l
    add $05                  ; Advance to next NPC entry (+5 bytes)
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00b_43bb           ; Check next NPC

jr_00b_43e2:
    ld a, $ff                ; No interactable NPC → return $FF
    ret


Call_00b_43e5:
    push hl
    push bc
    push de
    ld a, l
    add $05
    ld l, a
    ld a, h
    adc $00
    ld h, a
    bit 0, [hl]
    jr nz, jr_00b_444c

    ld a, l
    add $13
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ldh a, [$db]
    sub [hl]
    inc hl
    ld c, a
    ldh a, [$dc]
    sbc [hl]
    inc hl
    ld b, a
    jr nz, jr_00b_440f

    ld a, c
    cp $10
    jr nc, jr_00b_444c

    jr jr_00b_4422

jr_00b_440f:
    ld a, c
    cpl
    add $01
    ld c, a
    ld a, b
    cpl
    adc $00
    ld b, a
    ld a, b
    or a
    jr nz, jr_00b_444c

    ld a, c
    cp $10
    jr nc, jr_00b_444c

jr_00b_4422:
    ldh a, [$dd]
    sub [hl]
    inc hl
    ld c, a
    ldh a, [$de]
    sbc [hl]
    ld b, a
    jr nz, jr_00b_4434

    ld a, c
    cp $10
    jr nc, jr_00b_444c

    jr jr_00b_4447

jr_00b_4434:
    ld a, c
    cpl
    add $01
    ld c, a
    ld a, b
    cpl
    adc $00
    ld b, a
    ld a, b
    or a
    jr nz, jr_00b_444c

    ld a, c
    cp $10
    jr nc, jr_00b_444c

jr_00b_4447:
    xor a
    pop de
    pop bc
    pop hl
    ret


jr_00b_444c:
    xor a
    inc a
    pop de
    pop bc
    pop hl
    ret


; ---------------------------------------------------------------------------
; CheckNPCAtFacing — Compare NPC position against player's facing position
; ---------------------------------------------------------------------------
; Input:  HL = pointer to NPC entry (byte 0 = type)
;         $FFDB/$FFDC = player facing X position
;         $FFDD/$FFDE = player facing Y position
; Output: Z = NPC is at facing position (match)
;         NZ = NPC is NOT at facing position
;
; Compares NPC entry bytes 2 (X) and 3 (Y) against computed facing coords.
; ---------------------------------------------------------------------------
Call_00b_4452:
    push hl
    push bc
    push de
    inc hl
    inc hl
    ldh a, [$db]
    swap a
    and $0f
    ld b, a
    ldh a, [$dc]
    swap a
    and $f0
    or b
    ld b, a
    ld a, $0a
    call Call_000_1dfb
    cp [hl]
    jr nz, jr_00b_444c

    inc hl
    ldh a, [$dd]
    swap a
    and $0f
    ld b, a
    ldh a, [$de]
    swap a
    and $f0
    or b
    ld b, a
    ld a, $08
    call Call_000_1dfb
    cp [hl]
    jr nz, jr_00b_444c

    jr jr_00b_4447



RoomEntry9_SpecialRooms:
labelb_4488:
    ld a, [$c850]
    or a
    ret nz

    ld a, [$c88e]
    or a
    ret nz

    ld a, [$c88f]
    or a
    ret nz

    ld a, [wGameState]
    bit 0, a
    ret nz

    ldh a, [$90]
    bit 0, a
    ret nz

    ld a, [wInGateworld]
    or a
    ret nz

    ld hl, $4b43
    ld a, [wMapID]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [$c925]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    inc hl
    ld a, [de]
    ld e, a
    add a
    add e
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld bc, $2de7
    ld a, [$c925]
    add a
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    ld a, [bc]
    ld e, a
    inc bc
    ld a, [bc]
    ld d, a

jr_00b_44ec:
    ld a, [hl]
    cp $ff
    ret z

    ld a, [hl]
    or a
    jr z, jr_00b_4504

    cp $09
    jr z, jr_00b_4504

    inc hl
    ld a, [hl]
    dec hl
    or a
    jr z, jr_00b_4504

    cp $07
    jr z, jr_00b_4504

    jr jr_00b_4513

jr_00b_4504:
    ldh a, [$97]
    sub e
    cp [hl]
    jr nz, jr_00b_4513

    inc hl
    ldh a, [$98]
    sub d
    cp [hl]
    dec hl
    jp z, Jump_00b_45a8

jr_00b_4513:
    ld a, l
    add $07
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00b_44ec


; =============================================================================
; ENTRY 6: RoomEntry6_ExitChecker ($451D)
; =============================================================================
; **RUNS EVERY GAME STEP** — checks if player is standing on an exit tile.
; This is the most performance-critical room function.
;
; For non-gate rooms: reads exit_ptr from pointer table, scans exit entries,
; compares player position against each exit's trigger coordinates.
; If match found, writes destination to $C96D and sets transition flag.
;
; For gate rooms: uses separate gate exit logic at Jump_00b_46a7.
;
; CRITICAL FOR CUSTOM ROOMS: This function reads the pointer table during
; EVERY step, including during the fade transition before Entry 7 runs.
; If the pointer table points to invalid data, this function will crash
; or block the state machine from advancing.
; 
; Exit entry format (7 bytes each, in the exit_block):
;   [trigger_X:1][trigger_Y:1][dest_map_type:1][gate_flag:1]
;   [screen_byte:1][spawn_X:1][spawn_Y:1]
; Terminated by $FF.
; -----------------------------------------------------------------------------
RoomEntry6_ExitChecker:
labelb_451d:
;check if text box open
    ld a, [wGameState]              ; $C8EB — current game UI state
    bit 0, a                        ; bit 0 = text box open
    jp nz, Jump_00b_4674            ; skip if text box open

    ldh a, [$90]                    ; animation/movement state
    bit 0, a
    jp nz, Jump_00b_4674            ; skip if animating

    ld a, [wInGateworld]            ; $C969
    or a
    jp nz, Jump_00b_46a7            ; gate rooms use separate exit logic

    ; === POINTER TABLE READ (same pattern as ReadStepBlock) ===
    ; Reads exit_ptr (bytes 4-5 of step entry)
    ld hl, $4b43                    ; room pointer table
    ld a, [wMapID]
    add a                           ; mapID × 2
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a                         ; HL → screen_ptr_block

    ld a, [$c925]                   ; screen_index
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a                         ; HL → step_block

    ld e, [hl]                      ; ram_flag_ptr
    inc hl
    ld d, [hl]
    inc hl
    ld a, [de]                      ; current step value
    ld e, a
    add a
    add e
    add a                           ; × 6
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a                         ; HL → current step entry

    ; Skip step_id(1) + tileset(1) + interact_ptr(2) = 4 bytes → exit_ptr
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a                         ; HL → exit_block (list of 7-byte exit entries)

    ; Load screen offset from $2DE7 table for position comparison
    ld bc, $2de7                    ; screen position offset table (16 entries × 2)
    ld a, [$c925]                   ; screen_index
    add a                           ; × 2
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a                         ; BC → $2DE7[screen_index]
    ld a, [bc]
    ld e, a                         ; E = screen X offset
    inc bc
    ld a, [bc]
    ld d, a                         ; D = screen Y offset

; --- EXIT SCAN LOOP ---
; Iterates through exit entries (7 bytes each), comparing player position.
; HL points to current exit entry, DE = screen offset for position calc.
jr_00b_4578:
    ; Check terminator
    ld a, [hl]
    cp $ff
    jp z, Jump_00b_4674             ; $FF = end of exit list, no match

    ; Skip non-exit entries (type 0x00 = arrival point, 0x09 = special)
    ld a, [hl]
    or a
    jr z, jr_00b_459e               ; skip type $00

    cp $09
    jr z, jr_00b_459e               ; skip type $09

    ; Compare trigger X: player_col - screen_X_offset == exit.trigger_X?
    ldh a, [$97]                    ; player column (pixel units)
    sub e                           ; subtract screen X offset
    cp [hl]                         ; compare with exit trigger_X (byte 0)
    jr nz, jr_00b_459e              ; no match

    ; Validate trigger_Y is reasonable
    inc hl
    ld a, [hl]
    dec hl
    or a
    jr z, jr_00b_459e               ; Y=0 means invalid

    cp $07
    jr z, jr_00b_459e               ; Y=7 means invalid

    ; Compare trigger Y: player_row - screen_Y_offset == exit.trigger_Y?
    inc hl
    ldh a, [$98]                    ; player row (pixel units)
    sub d                           ; subtract screen Y offset
    cp [hl]                         ; compare with exit trigger_Y (byte 1)
    dec hl
    jr z, jr_00b_45a8               ; MATCH! → process transition

jr_00b_459e:
    ; Advance to next exit entry (+7 bytes)
    ld a, l
    add $07
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00b_4578                  ; continue scanning

; =============================================================================
; EXIT MATCH — PROCESS ROOM TRANSITION ($45AB)
; =============================================================================
; Player stepped on an exit. HL points to the matched exit entry.
; Read transition data (bytes 2-6) and set up the room change.
;
; Exit entry layout (HL currently at byte 0):
;   +0: trigger_X (already matched)
;   +1: trigger_Y (already matched)
;   +2: dest_map_type → written to $C96D
;   +3: gate_flag → written to $C96E
;   +4: screen_byte → indexes $2DE7 table for spawn position
;   +5: spawn_X → added to table value, SWAP'd for pixel position
;   +6: spawn_Y → added to table value, SWAP'd for pixel position
;
; THIS IS THE ONLY PATCHABLE TRANSITION CODE PATH for ROM data.
; Other paths ($524B, $52E8, $52F3, $5A16, $46C1) use RAM/register values.
;
; Flat ROM address = $2C000 + (HL - $4000) when breakpoint fires here.
; Use `breakpoint $0B:$45AB` in SameBoy to capture any transition.
; -----------------------------------------------------------------------------
Jump_00b_45a8:
jr_00b_45a8:
    inc hl                          ; skip trigger_X (byte 0)
    inc hl                          ; skip trigger_Y (byte 1)
    ld a, [hl+]                     ; byte 2: dest_map_type
    ld [$c96d], a                   ; → destination map_type
    ld a, [hl+]                     ; byte 3: gate_flag
    ld [$c96e], a                   ; → destination gate flag

    ; === SPAWN POSITION CALCULATION ===
    ; Screen byte (byte 4) indexes $2DE7 table for base position.
    ; Lower nibble selects table entry, bit 7 adds extra $08 to Y.
    ld de, $2de7                    ; spawn offset table
    ld a, [hl+]                     ; byte 4: screen_byte
    push af                         ; save for bit 7 check later
    and $0f                         ; lower nibble = table index
    add a                           ; × 2 (entries are 2 bytes)
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a                         ; DE → $2DE7[screen_byte & $0F]

    ; X position: table[index].X + spawn_X, then SWAP for pixels
    ld a, [de]                      ; table X base
    add [hl]                        ; + spawn_X (byte 5)
    inc de
    inc hl
    swap a                          ; nibble swap = multiply by 16
    ld b, a
    and $f0
    ld c, a
    ld a, b
    and $0f
    ld b, a
    ld a, c
    add $08                         ; add 8 pixel offset
    ld c, a
    ld a, b
    adc $00
    ld b, a
    ld a, c
    ld [$c96f], a                   ; X spawn position low
    ld a, b
    ld [$c970], a                   ; X spawn position high

    ; Y position: same calculation
    ld a, [de]                      ; table Y base
    add [hl]                        ; + spawn_Y (byte 6)
    inc de
    inc hl
    swap a
    ld b, a
    and $f0
    ld c, a
    ld a, b
    and $0f
    ld b, a
    ld a, c
    add $08
    ld c, a
    ld a, b
    adc $00
    ld b, a
    pop af                          ; recover screen_byte
    bit 7, a                        ; bit 7 set = multi-screen offset
    jr z, jr_00b_4601

    ; Add extra $08 to Y for multi-screen rooms (bit 7 of screen_byte)
    ld a, c
    add $08
    ld c, a
    ld a, b
    adc $00
    ld b, a

jr_00b_4601:
    ld a, c
    ld [$c971], a                   ; Y spawn position low
    ld a, b
    ld [$c972], a                   ; Y spawn position high

    ; === TRIGGER THE TRANSITION ===
    ld a, $01
    ld [wIsPlayerChangingMaps], a	; $C96C — signal map change to Entry 0
    ld a, [$c96e]
    or a
    jr nz, jr_00b_466b

    ld a, [wInGateworld]
    or a
    jr nz, jr_00b_4627

    ld a, [wMapID]
    cp $10
    jr nz, jr_00b_4627

    ldh a, [$95]
    cp $68
    jr z, jr_00b_462c

jr_00b_4627:
    call Call_000_2652
    jr z, jr_00b_465b

jr_00b_462c:
    ld a, [wMapID]
    ld l, a
    ld a, [wInGateworld]
    ld h, a
    push hl
    ld a, [$c96d]
    ld l, a
    ld a, [$c96e]
    ld h, a
    ld a, l
    ld [wMapID], a
    ld a, h
    ld [wInGateworld], a
    call Call_000_2652
    pop hl
    push af
    ld a, l
    ld [wMapID], a
    ld a, h
    ld [wInGateworld], a
    pop af
    jr nz, jr_00b_465b

    ld hl, $0109
    rst $10
    jr jr_00b_466b

jr_00b_465b:
    ld a, $03
    call Call_000_1688
    ld hl, $c88f
    inc [hl]
    ld a, $51
    call PlaySoundEffect
    jr jr_00b_4674

jr_00b_466b:
    ld hl, wGameState
    set 5, [hl]
    xor a
    ld [$c905], a

; --- Post-transition or no-exit: special room handling ---
; Checks if current room is a special type (mazes, conveyors, etc.)
; that need per-step processing beyond normal exit checking.
Jump_00b_4674:
jr_00b_4674:
    ld a, [wMapID]
    ld a, [wMapID]                  ; (loaded twice — original bug or intentional?)
    ; Special room map_types that get per-step processing:
    cp $53                          ; Forest Maze
    jr z, jr_00b_46d5

    cp $61                          ; sub-room 1
    jr z, jr_00b_46d5

    cp $62                          ; sub-room 2
    jr z, jr_00b_46d5

    cp $63                          ; sub-room 3
    jr z, jr_00b_46d5

    cp $64                          ; sub-room 4
    jr z, jr_00b_46d5

    cp $54                          ; Conveyor Belt Maze 1
    jr z, jr_00b_46d5

    cp $55                          ; Conveyor Belt Maze 2
    jr z, jr_00b_46d5

    cp $56                          ; Conveyor Belt Maze 3
    jr z, jr_00b_46d5

    cp $57                          ; Maze 1
    jr z, jr_00b_46d5

    cp $58                          ; Maze 2
    jr z, jr_00b_46d5

    cp $59                          ; Maze 3
    jr z, jr_00b_46d5

    ret


; --- Gate world exit handler ---
; For rooms inside gates ($C969 != 0), exit logic is different:
; checks $C960 (gate exit screen) and $FFAA position to detect
; when player reaches the gate floor exit.
Jump_00b_46a7:
    ld hl, $c960
    ld a, [$c925]
    cp [hl]
    jr nz, jr_00b_46d5

    ldh a, [$aa]
    srl a
    srl a
    cp $0f
    jr nz, jr_00b_46d5

    ld a, $01
    ld [wIsPlayerChangingMaps], a
    ld a, $00
    ld [$c96d], a
    ld a, $80
    ld [$c96e], a
    call Call_00b_46da
    ld hl, wGameState
    set 5, [hl]
    xor a
    ld [$c905], a

jr_00b_46d5:
    ld hl, $1608
    rst $10
    ret


Call_00b_46da:
    ld a, [wInGateworld]
    or a
    ret z

    ld hl, $c940
    ld de, $c950
    ld b, $10
    ld c, $00

jr_00b_46e9:
    ld a, [hl]
    and $f0
    cp $f0
    jr z, jr_00b_46f4

    ld a, [de]
    or a
    ret z

    inc c

jr_00b_46f4:
    inc hl
    inc de
    dec b
    jr nz, jr_00b_46e9

    ld a, c
    cp $10
    jr z, jr_00b_4703

    cp $02
    jr z, jr_00b_4709

    ret


jr_00b_4703:
    ld a, $05
    ld [$c92d], a
    ret


jr_00b_4709:
    ld a, $06
    ld [$c92d], a
    ret

; =============================================================================
; ENTRY 7: RoomEntry7_RoomInit ($470F)
; =============================================================================
; Called AFTER the fade transition completes. Initializes the new room:
; loads NPC data via ReadInteractPtr, sets up NPC sprites, positions, etc.
;
; State machine: checks $C8EA bit 7 (transition_phase).
;   If SET → fade still in progress, calls bank 6 fade handler, returns.
;   If CLEAR → fade done, proceeds with room initialization.
;
; CRITICAL: This function only runs AFTER the exit checker + Entry 0 have
; already processed the transition. If the exit checker crashes (e.g., from
; invalid pointer table data), this function NEVER RUNS.
; -----------------------------------------------------------------------------
RoomEntry7_RoomInit:
labelb_470f:
    ld a, [$c8ea]
    bit 7, a
    jr z, jr_00b_471b

    ld hl, $0604
    rst $10
    ret


jr_00b_471b:
    ld hl, $d7d2
    ld bc, $0101
    ld a, $00
    call FillNBytesWithRegA
    call Call_00b_482b
    ld a, $ff
    ld [$d7d2], a
    call Call_00b_4274
    ld a, [wInGateworld]
    or a
    jr z, jr_00b_477e

    ld a, [$c926]
    cp $ff
    jr z, jr_00b_477e

    ld a, [$c925]
    ld b, a
    ld a, [$c926]
    ld [$c925], a
    ld a, b
    ld [$c926], a
    call Call_00b_477e
    ld a, [$c925]
    ld b, a
    ld a, [$c926]
    ld [$c925], a
    ld a, b
    ld [$c926], a
    ld a, [$c927]
    ld l, a
    ld a, [$c928]
    ld h, a
    ld a, l
    ld [$d7ea], a
    ld a, h
    ld [$d7eb], a
    ld a, [$c929]
    ld l, a
    ld a, [$c92a]
    ld h, a
    ld a, l
    ld [$d7ec], a
    ld a, h
    ld [$d7ed], a
    ret


Call_00b_477e:
jr_00b_477e:
    ld de, $d7d2

Jump_00b_4781:
jr_00b_4781:
    ld a, e
    ldh [$d5], a
    ld a, d
    ldh [$d6], a
    ld a, [hl+]
    ld [de], a
    cp $ff
    ret z

    bit 7, a
    jr z, jr_00b_479a

    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00b_4781

jr_00b_479a:
    ldh [$d7], a
    ld bc, $2de7
    ld a, [$c925]
    add a
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    push de
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [bc]
    add [hl]
    ld [de], a
    inc hl
    inc de
    inc bc
    ld a, [bc]
    add [hl]
    ld [de], a
    inc hl
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    inc de
    ldh a, [$d7]
    swap a
    and $03
    ld [de], a
    push hl
    ldh a, [$d5]
    ld e, a
    ldh a, [$d6]
    ld d, a
    ld a, e
    add $11
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    inc hl
    ld a, [hl+]
    ld [de], a
    push hl
    call Call_00b_4839
    pop hl
    push af
    ldh a, [$d5]
    ld e, a
    ldh a, [$d6]
    ld d, a
    ld a, e
    add $16
    ld e, a
    ld a, d
    adc $00
    ld d, a
    pop af
    ld [de], a
    ldh a, [$d5]
    ld e, a
    ldh a, [$d6]
    ld d, a
    ld a, e
    add $18
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld a, [hl+]
    swap a
    ld c, a
    and $f0
    or $08
    ld [de], a
    inc de
    ld a, c
    and $0f
    ld [de], a
    inc de
    ld a, [hl]
    swap a
    ld c, a
    and $f0
    or $08
    ld [de], a
    inc de
    ld a, c
    and $0f
    ld [de], a
    inc de
    pop hl
    pop de
    ld a, e
    add $20
    ld e, a
    ld a, d
    adc $00
    ld d, a
    jp Jump_00b_4781


Call_00b_482b:
    ld hl, $d7be
    ld b, $06

jr_00b_4830:
    ld a, $ff
    ld [hl+], a
    xor a
    ld [hl+], a
    dec b
    jr nz, jr_00b_4830

    ret


Call_00b_4839:
    cp $ff
    ret z

    ld b, $00
    cp $e0
    jr z, jr_00b_48ba

    ld b, $20
    cp $e1
    jr z, jr_00b_48bf

    ld b, $30
    cp $e2
    jr z, jr_00b_48bf

    ld b, $40
    cp $e3
    jr z, jr_00b_48bf

    cp $f0
    jr c, jr_00b_488a

    and $03
    add a
    ld hl, $d7ca
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    inc hl
    dec de
    dec de
    ld a, [hl-]
    ld [de], a
    inc de
    inc de
    ld b, a
    ld a, [hl]
    ld [de], a
    cp $ff
    jr nz, jr_00b_4887

    push de
    ld a, e
    sub $10
    ld e, a
    ld a, d
    sbc $00
    ld d, a
    ld a, $ff
    ld [de], a
    dec de
    dec de
    ld a, $00
    ld [de], a
    pop de
    ld a, $00
    ret


jr_00b_4887:
    ld e, b
    jr jr_00b_488c

jr_00b_488a:
    ld e, $00

jr_00b_488c:
    ld hl, $d7be
    ld b, $06
    ld c, $00
    ld d, a

jr_00b_4894:
    ld a, [hl]
    cp $ff
    jr z, jr_00b_48f6

    cp d
    jr nz, jr_00b_48a2

    inc hl
    ld a, [hl-]
    cp e
    jp z, Jump_00b_4945

jr_00b_48a2:
    ld a, [hl]
    cp $55
    jr z, jr_00b_48ab

    cp $15
    jr nz, jr_00b_48b1

jr_00b_48ab:
    inc hl
    ld a, [hl-]
    or a
    jr nz, jr_00b_48b1

    inc c

jr_00b_48b1:
    inc hl
    inc hl
    inc c
    dec b
    jr nz, jr_00b_4894

    ld a, $50
    ret


jr_00b_48ba:
    ld a, $5e
    ld [de], a
    ld a, b
    ret


jr_00b_48bf:
    sub $e1
    push af
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr nz, jr_00b_48e1

    pop af
    push de
    ld a, e
    sub $10
    ld e, a
    ld a, d
    sbc $00
    ld d, a
    ld a, $ff
    ld [de], a
    pop de
    ld a, $00
    ret


jr_00b_48e1:
    pop af
    ld hl, $ca91
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [de], a
    dec de
    dec de
    ld a, $01
    ld [de], a
    inc de
    inc de
    ld a, b
    ret


jr_00b_48f6:
    ld [hl], d
    inc hl
    ld [hl], e
    push bc
    ld a, e
    or a
    jr nz, jr_00b_490b

    ld hl, $2adf
    ld a, d
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    jr jr_00b_4917

jr_00b_490b:
    ld l, d
    ld h, $00
    add hl, hl
    ld a, l
    add $74
    ld l, a
    ld a, h
    adc $49
    ld h, a

jr_00b_4917:
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, c
    add $80
    ld h, a
    ld a, [wInGateworld]
    or a
    jr z, jr_00b_492a

    ld a, h
    add $07
    ld h, a
    jr jr_00b_493f

jr_00b_492a:
    ld a, [wMapID]
    cp $08
    jr z, jr_00b_493f

    cp $45
    jr nz, jr_00b_493b

    ld a, h
    add $02
    ld h, a
    jr jr_00b_493f

jr_00b_493b:
    ld a, h
    add $05
    ld h, a

jr_00b_493f:
    ld l, $00
    call Call_000_1577
    pop bc

Jump_00b_4945:
    ld a, [wInGateworld]
    or a
    jr nz, jr_00b_4964

    ld a, [wMapID]
    cp $08
    jr z, jr_00b_495e

    cp $45
    jr z, jr_00b_496c

    ld a, c
    add a
    add a
    add a
    add a
    add $50
    ret


jr_00b_495e:
    ld a, c
    add a
    add a
    add a
    add a
    ret


jr_00b_4964:
    ld a, c
    add a
    add a
    add a
    add a
    add $70
    ret


jr_00b_496c:
    ld a, c
    add a
    add a
    add a
    add a
    add $20
    ret

;DATA
    nop
    cpl
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $2f01
    ld [bc], a
    cpl
    inc bc
    cpl
    inc b
    cpl
    dec b
    cpl
    ld b, $2f
    rlca
    cpl
    ld [$092f], sp
    cpl
    ld a, [bc]
    cpl
    dec bc
    cpl
    inc c
    cpl
    dec c
    cpl
    ld c, $2f
    rrca
    cpl
    db $10
    cpl
    nop
    jr c, @+$03

    jr c, jr_00b_49bb

    jr c, @+$05

jr_00b_49bb:
    jr c, jr_00b_49c1

    jr c, @+$07

    jr c, jr_00b_49c7

jr_00b_49c1:
    jr c, @+$09

    jr c, jr_00b_49cd

    jr c, @+$0b

jr_00b_49c7:
    jr c, jr_00b_49d3

    jr c, @+$0d

    jr c, jr_00b_49d9

jr_00b_49cd:
    jr c, @+$0f

    jr c, jr_00b_49df

    jr c, @+$11

jr_00b_49d3:
    jr c, jr_00b_49e5

    jr c, @+$13

    jr c, jr_00b_49eb

jr_00b_49d9:
    jr c, @+$15

    jr c, jr_00b_49f1

    jr c, @+$17

jr_00b_49df:
    jr c, jr_00b_49f7

    jr c, @+$19

    jr c, jr_00b_49fd

jr_00b_49e5:
    jr c, @+$1b

    jr c, jr_00b_4a03

    jr c, @+$1d

jr_00b_49eb:
    jr c, jr_00b_4a09

    jr c, @+$1f

    jr c, jr_00b_4a0f

jr_00b_49f1:
    jr c, @+$21

    jr c, jr_00b_4a15

    jr c, @+$23

jr_00b_49f7:
    jr c, jr_00b_4a1b

    jr c, @+$25

    jr c, jr_00b_4a21

jr_00b_49fd:
    jr c, @+$27

    jr c, jr_00b_4a27

    jr c, @+$29

jr_00b_4a03:
    jr c, jr_00b_4a2d

    jr c, @+$2b

    jr c, jr_00b_4a33

jr_00b_4a09:
    jr c, @+$2d

    jr c, jr_00b_4a39

    jr c, @+$2f

jr_00b_4a0f:
    jr c, jr_00b_4a3f

    jr c, @+$31

    jr c, jr_00b_4a45

jr_00b_4a15:
    jr c, @+$33

    jr c, jr_00b_4a4b

    jr c, jr_00b_4a4e

jr_00b_4a1b:
    jr c, @+$36

    jr c, jr_00b_4a54

    jr c, jr_00b_4a57

jr_00b_4a21:
    jr c, jr_00b_4a5a

    jr c, jr_00b_4a5d

    jr c, jr_00b_4a60

jr_00b_4a27:
    jr c, jr_00b_4a63

    jr c, jr_00b_4a66

    jr c, jr_00b_4a69

jr_00b_4a2d:
    jr c, jr_00b_4a6c

    jr c, jr_00b_4a6f

    jr c, jr_00b_4a72

jr_00b_4a33:
    jr c, @+$42

    jr c, jr_00b_4a78

    jr c, jr_00b_4a7b

jr_00b_4a39:
    jr c, jr_00b_4a7e

    jr c, @+$46

    jr c, jr_00b_4a84

jr_00b_4a3f:
    jr c, @+$48

    jr c, jr_00b_4a8a

    jr c, jr_00b_4a45

jr_00b_4a45:
    add hl, sp
    ld bc, $0239
    add hl, sp
    inc bc

jr_00b_4a4b:
    add hl, sp
    inc b
    add hl, sp

jr_00b_4a4e:
    dec b
    add hl, sp
    ld b, $39
    rlca
    add hl, sp

jr_00b_4a54:
    ld [$0939], sp

jr_00b_4a57:
    add hl, sp
    ld a, [bc]
    add hl, sp

jr_00b_4a5a:
    dec bc
    add hl, sp
    inc c

jr_00b_4a5d:
    add hl, sp
    dec c
    add hl, sp

jr_00b_4a60:
    ld c, $39
    rrca

jr_00b_4a63:
    add hl, sp
    db $10
    add hl, sp

jr_00b_4a66:
    ld de, $1239

jr_00b_4a69:
    add hl, sp
    inc de
    add hl, sp

jr_00b_4a6c:
    inc d
    add hl, sp
    dec d

jr_00b_4a6f:
    add hl, sp
    ld d, $39

jr_00b_4a72:
    rla
    add hl, sp
    jr jr_00b_4aaf

    add hl, de
    add hl, sp

jr_00b_4a78:
    ld a, [de]
    add hl, sp
    dec de

jr_00b_4a7b:
    add hl, sp
    inc e
    add hl, sp

jr_00b_4a7e:
    dec e
    add hl, sp
    ld e, $39
    rra
    add hl, sp

jr_00b_4a84:
    jr nz, jr_00b_4abf

    ld hl, $2239
    add hl, sp

jr_00b_4a8a:
    inc hl
    add hl, sp
    inc h
    add hl, sp
    dec h
    add hl, sp
    ld h, $39
    daa
    add hl, sp
    jr z, jr_00b_4acf

    add hl, hl
    add hl, sp
    ld a, [hl+]
    add hl, sp
    dec hl
    add hl, sp
    inc l
    add hl, sp
    dec l
    add hl, sp
    ld l, $39
    cpl
    add hl, sp
    jr nc, jr_00b_4adf

    ld sp, $3239
    add hl, sp
    inc sp
    add hl, sp
    inc [hl]
    add hl, sp
    dec [hl]

jr_00b_4aaf:
    add hl, sp
    ld [hl], $39
    scf
    add hl, sp
    jr c, jr_00b_4aef

    add hl, sp
    add hl, sp
    ld a, [hl-]
    add hl, sp
    dec sp
    add hl, sp
    inc a
    add hl, sp
    dec a

jr_00b_4abf:
    add hl, sp
    ld a, $39
    ccf
    add hl, sp
    ld b, b
    add hl, sp
    ld b, c
    add hl, sp
    ld b, d
    add hl, sp
    ld b, e
    add hl, sp
    ld b, h
    add hl, sp
    ld b, l

jr_00b_4acf:
    add hl, sp
    ld b, [hl]
    add hl, sp
    ld b, a
    add hl, sp
    nop
    ld a, [hl-]
    ld bc, $023a
    ld a, [hl-]
    inc bc
    ld a, [hl-]
    inc b
    ld a, [hl-]
    dec b

jr_00b_4adf:
    ld a, [hl-]
    ld b, $3a
    rlca
    ld a, [hl-]
    ld [$093a], sp
    ld a, [hl-]
    ld a, [bc]
    ld a, [hl-]
    dec bc
    ld a, [hl-]
    inc c
    ld a, [hl-]
    dec c

jr_00b_4aef:
    ld a, [hl-]
    ld c, $3a
    rrca
    ld a, [hl-]
    db $10
    ld a, [hl-]
    ld de, $123a
    ld a, [hl-]
    inc de
    ld a, [hl-]
    inc d
    ld a, [hl-]
    dec d
    ld a, [hl-]
    ld d, $3a
    rla
    ld a, [hl-]
    jr jr_00b_4b40

    add hl, de
    ld a, [hl-]
    ld a, [de]
    ld a, [hl-]
    dec de
    ld a, [hl-]
    inc e
    ld a, [hl-]
    dec e
    ld a, [hl-]
    ld e, $3a
    rra
    ld a, [hl-]
    jr nz, jr_00b_4b50

    ld hl, $223a
    ld a, [hl-]
    inc hl
    ld a, [hl-]
    inc h
    ld a, [hl-]
    dec h
    ld a, [hl-]
    ld h, $3a
    daa
    ld a, [hl-]
    jr z, jr_00b_4b60

    add hl, hl
    ld a, [hl-]
    ld a, [hl+]
    ld a, [hl-]
    dec hl
    ld a, [hl-]
    inc l
    ld a, [hl-]
    dec l
    ld a, [hl-]
    ld l, $3a
    cpl
    ld a, [hl-]
    jr nc, jr_00b_4b70

    ld sp, $323a
    ld a, [hl-]
    inc sp
    ld a, [hl-]
    inc [hl]
    ld a, [hl-]
    dec [hl]
    ld a, [hl-]

jr_00b_4b40:
    ld [hl], $3a
    rst $38

; =============================================================================
; ROOM DATA SECTION ($4B43 - $7FFF) — AUTO-ANNOTATED
; Generated from extracted/map_table.json, npc_catalog.json, all_exits.json
; =============================================================================

RoomPtrTable:  ; 107 entries x 2B, indexed by wMapID ($C968)
    dw $4C13  ; $00 m00_Castle
    dw $4E23  ; $01 m01_GreatTree_Overworld
    dw $505D  ; $02 m02_Bazaar
    dw $52F2  ; $03 m03_Gate_Hub
    dw $55AE  ; $04 m04_Farm_top_of_GreatTree
    dw $583A  ; $05 m05_Stable
    db $9E  ; $06 m06_Arena_Lobby ptr low
jr_00b_4b50:
    db $59  ; $06 m06_Arena_Lobby ptr high → $599E
    dw $5A2B  ; $07 m07_Arena_Rooms
    dw $5C86  ; $08 m08_Gate_tileset
    dw $5D45  ; $09 m09
    dw $5E6A  ; $0A m0A_Secret_Passage_ThroneMedalMan
    dw $4C13  ; $0B m0B_X
    dw $5E94  ; $0C m0C_Gate_tileset
    dw $5EC0  ; $0D m0D_Old_Man_Gate_Room
    db $13  ; $0E m0E_X ptr low
jr_00b_4b60:
    db $4C  ; $0E m0E_X ptr high → $4C13
    dw $5F4A  ; $0F m0F_X
    dw $5F71  ; $10 m10_Copycat_Room
    dw $4C13  ; $11 m11_X
    dw $5FDB  ; $12 m12_Library
    dw $607D  ; $13 m13_X
    dw $4C13  ; $14 m14_X
    dw $4C13  ; $15 m15_X
    db $39  ; $16 m16_MedalMan_Room ptr low
jr_00b_4b70:
    db $61  ; $16 m16_MedalMan_Room ptr high → $6139
    dw $5F71  ; $17 m17_X
    dw $61F8  ; $18 m18_Well
    dw $62BB  ; $19 m19_X
    dw $62E2  ; $1A m1A_X
    dw $6313  ; $1B m1B_X
    dw $635E  ; $1C m1C_X
    dw $63C5  ; $1D m1D_X
    dw $63F6  ; $1E m1E_X
    dw $6438  ; $1F m1F_X
    dw $4C13  ; $20 m20_X
    dw $4C13  ; $21 m21_X
    dw $4C13  ; $22 m22_X
    dw $64A4  ; $23 m23_Room_of_Beginning
    dw $64DB  ; $24 m24_Room_of_Villager_And_Talisman
    dw $6539  ; $25 m25_Room_of_Memories_And_Bewilder
    dw $6597  ; $26 m26_Room_of_Peace_And_Bravery
    dw $65F5  ; $27 m27_Room_of_Strength_And_Anger
    dw $6658  ; $28 m28_Room_of_Joy_And_Wisdom
    dw $66B6  ; $29 m29_Room_of_Happiness_And_Temptation
    dw $6714  ; $2A m2A_Room_of_Labyrinth_And_Judgment
    dw $6772  ; $2B m2B_Room_of_Reflection
    dw $67A9  ; $2C m2C_Room_of_Ambition_And_Demolition
    dw $6807  ; $2D m2D_Room_of_Mastermind_And_Control
    dw $6865  ; $2E m2E_Room_of_Extinction_And_Sleep
    dw $68CA  ; $2F m2F
    dw $6AAF  ; $30 m30_Boss_Room___Gate_of_Beginning
    dw $6AD4  ; $31 m31_Boss_Room___Gate_of_Villager
    dw $6B12  ; $32 m32_Boss_Room___Gate_of_Talisman
    dw $6B41  ; $33 m33_Boss_Room___Gate_of_Memories
    dw $6B66  ; $34 m34_Boss_Room___Gate_of_Bewilder
    dw $6BC2  ; $35 m35_X
    dw $6BFB  ; $36 m36_Boss_Room___Gate_of_Peace
    dw $6C84  ; $37 m37_Boss_Room___Gate_of_Bravery
    dw $6D17  ; $38 m38_X
    dw $6DFA  ; $39 m39_X
    dw $6E33  ; $3A m3A_X
    dw $6F3E  ; $3B m3B_X
    dw $6F63  ; $3C m3C_X
    dw $6FE3  ; $3D m3D_X
    dw $7023  ; $3E m3E_X
    dw $7052  ; $3F m3F_X
    dw $7077  ; $40 m40_X
    dw $70E4  ; $41 m41_X
    dw $7142  ; $42 m42_Labyrinth
    dw $74DB  ; $43 m43_X
    dw $751E  ; $44 m44_X
    dw $7561  ; $45 m45_X
    dw $75C9  ; $46 m46_Boss_Room___Gate_of_Ambition
    dw $75F8  ; $47 m47_X
    dw $7643  ; $48 m48_X
    dw $7672  ; $49 m49_X
    dw $76A1  ; $4A m4A_X
    dw $76D0  ; $4B m4B_X
    dw $76FF  ; $4C m4C_X
    dw $772E  ; $4D m4D_Boss_Room___Arena_Right_Gate
    dw $775D  ; $4E m4E_X
    dw $77A9  ; $4F m4F_Boss_Room___Unused_Gate
    dw $77DD  ; $50 m50_X
    dw $77FA  ; $51 m51_X
    dw $7817  ; $52 m52_Special___Coliseum
    dw $784B  ; $53 m53_Special___Forest_Maze
    dw $7908  ; $54 m54_Special___Conveyor_Belt_1
    dw $7978  ; $55 m55_Special___Conveyor_Belt_2
    dw $79E8  ; $56 m56_Special___Conveyor_Belt_3
    dw $7A58  ; $57 m57_Special___Maze_1
    dw $7AC8  ; $58 m58_Special___Maze_2
    dw $7B38  ; $59 m59_Special___Maze_3
    dw $7BA8  ; $5A m5A_Special___Treasure_Chest_1
    dw $7BD9  ; $5B m5B_X
    dw $7C0A  ; $5C m5C_Special___Treasure_Chest_3
    dw $7C45  ; $5D m5D_Arena_Battle
    dw $7CE2  ; $5E m5E_X
    dw $77DD  ; $5F m5F_X
    dw $7144  ; $60 m60_Labyrinth_Final_Room
    dw $784D  ; $61 m61_X
    dw $784F  ; $62 m62_X
    dw $7851  ; $63 m63_X
    dw $7853  ; $64 m64_X
    dw $7144  ; $65 m65
    dw $7144  ; $66 m66
    dw $7144  ; $67 m67
    dw $4C23  ; $68 m68
    dw $4C3D  ; $69 m69
    dw $FFFF  ; $6A m6A

; --- ROOM DATA BLOCKS ---
    db $FF, $FF, $FF, $FF, $75, $4C, $FF, $FF, $FF, $FF

m00_Castle_SB0:  ; $4C23
    ; step_block scr0 ram=0xD92A
    ; step_block scr0 ram=0xD92A
    ; step_block scr0 ram=0xD92A
    db $2A, $D9, $01, $2A, $95, $4C, $FC, $4D, $02, $2A, $95, $4C, $FC, $4D, $03, $2A
    db $95, $4C, $FC, $4D, $04, $2A, $95, $4C, $FC, $4D

m00_Castle_SB1:  ; $4C3D
    ; step_block scr1 ram=0xD92B
    ; step_block scr1 ram=0xD92B
    ; step_block scr1 ram=0xD92B
    db $2B, $D9, $05, $2A, $CD, $4C, $FE, $4D, $06, $2A, $EC, $4C, $FE, $4D, $06, $2A
    db $01, $4D, $FE, $4D, $06, $2A, $1B, $4D, $FE, $4D, $06, $2A, $2B, $4D, $FE, $4D
    db $06, $2A, $54, $4D, $FE, $4D, $06, $2A, $88, $4D, $FE, $4D, $05, $2A, $64, $4D
    db $FD, $4D, $06, $2A, $88, $4D, $FE, $4D, $2C, $D9, $07, $2A, $A2, $4D, $06, $4E
    db $07, $2A, $BC, $4D, $06, $4E, $07, $2A, $CC, $4D, $06, $4E, $07, $2A, $DC, $4D
    db $06, $4E, $07, $2A, $EC, $4D, $06, $4E

m00_Castle_X0v0:  ; $4C95
    ; exits s0v0
    ; exits s0v1
    ; exits s0v2
    db $8F, $FF, $01, $01, $01, $8F, $FF, $02, $01, $02, $8F, $FF, $03, $02, $03, $8F
    db $FF, $04, $02, $04, $8F, $FF, $02, $07, $05, $8F, $FF, $03, $07, $06, $8F, $FF
    db $04, $07, $07, $8F, $FF, $05, $07, $08, $8F, $FF, $06, $07, $13
    ; NPC t$01 spr$10 (5,2) scr9
    db $01, $10, $05, $02, $09
    ; NPC t$00 spr$10 (7,4) scr10
    db $00, $10, $07, $04, $0A, $FF

m00_Castle_X1v0:  ; $4CCD
    ; exits s1v0
    ; exits s1v0
    ; exits s1v0
    db $00, $10, $02, $02, $0C
    ; NPC t$00 spr$10 (7,2) scr13
    db $00, $10, $07, $02, $0D
    ; NPC t$30 spr$11 (3,5) scr14
    db $30, $11, $03, $05, $0E
    ; NPC t$60 spr$00 (6,8) scr15
    db $60, $00, $06, $08, $0F
    ; NPC t$00 spr$0D (4,3) scr11
    db $00, $0D, $04, $03, $0B
    ; NPC t$60 spr$37 (5,8) scr255
    db $60, $37, $05, $08, $FF, $FF

m00_Castle_X1v1:  ; $4CEC
    ; exits s1v1
    ; exits s1v1
    ; exits s1v1
    db $00, $10, $02, $02, $0C
    ; NPC t$00 spr$10 (7,2) scr13
    db $00, $10, $07, $02, $0D
    ; NPC t$30 spr$11 (3,5) scr14
    db $30, $11, $03, $05, $0E
    ; NPC t$20 spr$00 (6,6) scr15
    db $20, $00, $06, $06, $0F, $FF

m00_Castle_X1v2:  ; $4D01
    ; exits s1v2
    ; exits s1v2
    ; exits s1v2
    db $00, $10, $02, $02, $0C
    ; NPC t$00 spr$10 (7,2) scr13
    db $00, $10, $07, $02, $0D
    ; NPC t$30 spr$11 (3,5) scr14
    db $30, $11, $03, $05, $0E
    ; NPC t$20 spr$00 (6,6) scr15
    db $20, $00, $06, $06, $0F
    ; NPC t$00 spr$0D (4,3) scr11
    db $00, $0D, $04, $03, $0B, $FF

m00_Castle_X1v3:  ; $4D1B
    ; exits s1v3
    ; exits s1v3
    ; exits s1v3
    db $00, $10, $02, $02, $0C
    ; NPC t$00 spr$10 (7,2) scr13
    db $00, $10, $07, $02, $0D
    ; NPC t$30 spr$11 (3,5) scr14
    db $30, $11, $03, $05, $0E, $FF

m00_Castle_X1v4:  ; $4D2B
    ; exits s1v4
    ; exits s1v4
    ; exits s1v4
    db $00, $10, $02, $02, $0C
    ; NPC t$00 spr$10 (7,2) scr13
    db $00, $10, $07, $02, $0D
    ; NPC t$20 spr$11 (4,6) scr14
    db $20, $11, $04, $06, $0E
    ; NPC t$60 spr$00 (6,6) scr255
    db $60, $00, $06, $06, $FF
    ; NPC t$00 spr$0D (4,3) scr11
    db $00, $0D, $04, $03, $0B
    ; NPC t$60 spr$00 (6,6) scr255
    db $60, $00, $06, $06, $FF
    ; NPC t$40 spr$E0 (4,5) scr255
    db $40, $E0, $04, $05, $FF
    ; NPC t$40 spr$52 (4,6) scr255
    db $40, $52, $04, $06, $FF, $FF

m00_Castle_X1v5:  ; $4D54
    ; exits s1v5
    ; exits s1v5
    ; exits s1v5
    db $00, $10, $02, $02, $0C
    ; NPC t$00 spr$10 (8,2) scr13
    db $00, $10, $08, $02, $0D
    ; NPC t$30 spr$11 (3,5) scr14
    db $30, $11, $03, $05, $0E, $FF

m00_Castle_X1v7:  ; $4D64
    ; exits s1v7
    ; exits s1v7
    ; exits s1v7
    db $00, $10, $02, $02, $0C
    ; NPC t$00 spr$10 (7,2) scr13
    db $00, $10, $07, $02, $0D
    ; NPC t$30 spr$11 (3,5) scr14
    db $30, $11, $03, $05, $0E
    ; NPC t$60 spr$00 (6,6) scr255
    db $60, $00, $06, $06, $FF
    ; NPC t$00 spr$0D (4,3) scr255
    db $00, $0D, $04, $03, $FF
    ; NPC t$60 spr$38 (5,8) scr255
    db $60, $38, $05, $08, $FF
    ; NPC t$40 spr$10 (8,2) scr13
    db $40, $10, $08, $02, $0D, $FF

m00_Castle_X1v6:  ; $4D88
    ; exits s1v6
    ; exits s1v8
    ; exits s1v6
    db $00, $10, $02, $02, $0C
    ; NPC t$00 spr$10 (7,2) scr13
    db $00, $10, $07, $02, $0D
    ; NPC t$30 spr$11 (3,5) scr14
    db $30, $11, $03, $05, $0E
    ; NPC t$60 spr$00 (6,6) scr15
    db $60, $00, $06, $06, $0F
    ; NPC t$40 spr$10 (8,2) scr13
    db $40, $10, $08, $02, $0D, $FF
    ; NPC t$30 spr$0B (2,5) scr16
    db $30, $0B, $02, $05, $10
    ; NPC t$10 spr$0B (7,5) scr17
    db $10, $0B, $07, $05, $11
    ; NPC t$10 spr$0B (6,3) scr18
    db $10, $0B, $06, $03, $12
    ; NPC t$00 spr$11 (4,4) scr255
    db $00, $11, $04, $04, $FF
    ; NPC t$60 spr$E0 (4,7) scr255
    db $60, $E0, $04, $07, $FF, $FF
    ; NPC t$30 spr$0B (2,5) scr16
    db $30, $0B, $02, $05, $10
    ; NPC t$10 spr$0B (7,5) scr17
    db $10, $0B, $07, $05, $11
    ; NPC t$10 spr$0B (6,3) scr18
    db $10, $0B, $06, $03, $12, $FF
    ; NPC t$30 spr$0B (2,5) scr16
    db $30, $0B, $02, $05, $10
    ; NPC t$10 spr$0B (8,5) scr17
    db $10, $0B, $08, $05, $11
    ; NPC t$10 spr$0B (6,3) scr18
    db $10, $0B, $06, $03, $12, $FF
    ; NPC t$30 spr$0B (1,4) scr16
    db $30, $0B, $01, $04, $10
    ; NPC t$10 spr$0B (7,5) scr17
    db $10, $0B, $07, $05, $11
    ; NPC t$10 spr$0B (6,3) scr18
    db $10, $0B, $06, $03, $12, $FF
    ; NPC t$30 spr$0B (1,4) scr16
    db $30, $0B, $01, $04, $10
    ; NPC t$10 spr$0B (8,5) scr17
    db $10, $0B, $08, $05, $11
    ; NPC t$10 spr$0B (6,3) scr18
    db $10, $0B, $06, $03, $12, $FF

m00_Castle_N0v0:  ; $4DFC
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $FF

m00_Castle_N1v7:  ; $4DFD
    ; npcs s1v7
    ; npcs s1v7
    ; npcs s1v7
    db $FF

m00_Castle_N1v0:  ; $4DFE
    ; npcs s1v0
    ; npcs s1v1
    ; npcs s1v2
    db $07, $01
    ; Exit (7,1)->Secret_Passage
    db $0A, $00, $00, $07, $07, $FF, $02, $05
    ; Exit (2,5)->Gate_Hub
    db $03, $00, $01, $02, $05, $07, $05
    ; Exit (7,5)->Farm
    db $04, $00, $05, $07, $05, $04, $07
    ; Exit (4,7)->GreatTree
    db $01, $00, $80, $04, $04, $05, $07
    ; Exit (5,7)->GreatTree
    db $01, $00, $80, $05, $04, $FF

m01_GreatTree_Overworld_SP:  ; $4E23
    ; screen_ptrs $01
    db $43, $4E, $63, $4E, $FF, $FF, $FF, $FF, $6B, $4E, $85, $4E, $FF, $FF, $FF, $FF
    db $8D, $4E, $A1, $4E, $FF, $FF, $FF, $FF, $A9, $4E, $C3, $4E, $FF, $FF, $FF, $FF

m01_GreatTree_Overworld_SB0:  ; $4E43
    ; step_block scr0 ram=0xD92D
    db $2D, $D9, $09, $2A, $D7, $4E, $BE, $4F, $09, $2A, $E2, $4E, $BF, $4F, $09, $2A
    db $ED, $4E, $BF, $4F, $09, $2A, $F8, $4E, $BF, $4F, $09, $2A, $FE, $4E, $BE, $4F

m01_GreatTree_Overworld_SB1:  ; $4E63
    ; step_block scr1 ram=0xD92E
    db $2E, $D9, $0A, $2A, $09, $4F, $CE, $4F, $2F, $D9, $0B, $2A, $0F, $4F, $D6, $4F
    db $0B, $2A, $1F, $4F, $D6, $4F, $0B, $2A, $34, $4F, $D6, $4F, $0B, $2A, $3F, $4F
    db $D6, $4F, $30, $D9, $0C, $2A, $4F, $4F, $E5, $4F, $31, $D9, $0D, $2A, $5A, $4F
    db $E6, $4F, $0D, $2A, $6F, $4F, $E6, $4F, $0D, $2A, $84, $4F, $E6, $4F, $32, $D9
    db $0E, $2A, $94, $4F, $F5, $4F, $33, $D9, $0F, $2A, $9F, $4F, $04, $50, $0F, $2A
    db $A5, $4F, $04, $50, $10, $2A, $B0, $4F, $1A, $50, $10, $2A, $9F, $4F, $1A, $50
    db $34, $D9, $11, $2A, $BB, $4F, $30, $50, $12, $2A, $BC, $4F, $38, $50, $13, $2A
    db $BD, $4F, $47, $50

m01_GreatTree_Overworld_X0v0:  ; $4ED7
    ; exits s0v0
    ; NPC t$20 spr$08 (2,6) scr255
    db $20, $08, $02, $06, $FF
    ; NPC t$10 spr$05 (6,5) scr2
    db $10, $05, $06, $05, $02, $FF

m01_GreatTree_Overworld_X0v1:  ; $4EE2
    ; exits s0v1
    ; NPC t$00 spr$08 (2,6) scr1
    db $00, $08, $02, $06, $01
    ; NPC t$00 spr$05 (6,5) scr2
    db $00, $05, $06, $05, $02, $FF

m01_GreatTree_Overworld_X0v2:  ; $4EED
    ; exits s0v2
    db $90, $FF, $06, $06, $12
    ; NPC t$00 spr$05 (6,5) scr2
    db $00, $05, $06, $05, $02, $FF

m01_GreatTree_Overworld_X0v3:  ; $4EF8
    ; exits s0v3
    db $90, $FF, $06, $06, $12, $FF

m01_GreatTree_Overworld_X0v4:  ; $4EFE
    ; exits s0v4
    db $90, $FF, $06, $06, $12
    ; NPC t$20 spr$08 (2,6) scr255
    db $20, $08, $02, $06, $FF, $FF

m01_GreatTree_Overworld_X1v0:  ; $4F09
    ; exits s1v0
    ; NPC t$30 spr$03 (5,2) scr3
    db $30, $03, $05, $02, $03, $FF
    ; NPC t$20 spr$08 (2,6) scr255
    db $20, $08, $02, $06, $FF
    ; NPC t$00 spr$03 (7,3) scr4
    db $00, $03, $07, $03, $04
    ; NPC t$40 spr$0B (4,3) scr255
    db $40, $0B, $04, $03, $FF, $FF, $90, $FF, $06, $06, $13
    ; NPC t$00 spr$03 (7,3) scr4
    db $00, $03, $07, $03, $04
    ; NPC t$00 spr$05 (6,5) scr5
    db $00, $05, $06, $05, $05
    ; NPC t$00 spr$08 (2,6) scr6
    db $00, $08, $02, $06, $06, $FF, $90, $FF, $06, $06, $13
    ; NPC t$00 spr$03 (7,3) scr4
    db $00, $03, $07, $03, $04, $FF, $90, $FF, $06, $06, $13
    ; NPC t$00 spr$03 (7,3) scr4
    db $00, $03, $07, $03, $04
    ; NPC t$00 spr$0B (3,5) scr7
    db $00, $0B, $03, $05, $07, $FF
    ; NPC t$00 spr$0B (3,2) scr8
    db $00, $0B, $03, $02, $08
    ; NPC t$30 spr$0F (6,1) scr9
    db $30, $0F, $06, $01, $09, $FF, $90, $FF, $06, $07, $14
    ; NPC t$20 spr$08 (2,6) scr255
    db $20, $08, $02, $06, $FF
    ; NPC t$17 spr$01 (3,6) scr10
    db $17, $01, $03, $06, $0A
    ; NPC t$00 spr$09 (8,3) scr11
    db $00, $09, $08, $03, $0B, $FF, $90, $FF, $06, $07, $14
    ; NPC t$00 spr$09 (8,3) scr11
    db $00, $09, $08, $03, $0B
    ; NPC t$07 spr$01 (2,7) scr10
    db $07, $01, $02, $07, $0A
    ; NPC t$00 spr$05 (6,6) scr12
    db $00, $05, $06, $06, $0C, $FF, $90, $FF, $06, $07, $14
    ; NPC t$00 spr$09 (8,3) scr11
    db $00, $09, $08, $03, $0B
    ; NPC t$10 spr$04 (3,6) scr13
    db $10, $04, $03, $06, $0D, $FF
    ; NPC t$00 spr$02 (4,2) scr14
    db $00, $02, $04, $02, $0E
    ; NPC t$10 spr$00 (7,4) scr15
    db $10, $00, $07, $04, $0F, $FF
    ; NPC t$20 spr$08 (4,5) scr255
    db $20, $08, $04, $05, $FF, $FF
    ; NPC t$07 spr$01 (1,6) scr16
    db $07, $01, $01, $06, $10
    ; NPC t$00 spr$05 (7,5) scr17
    db $00, $05, $07, $05, $11, $FF
    ; NPC t$07 spr$01 (1,6) scr16
    db $07, $01, $01, $06, $10
    ; NPC t$00 spr$05 (7,5) scr17
    db $00, $05, $07, $05, $11, $FF, $FF, $FF, $FF

m01_GreatTree_Overworld_N0v0:  ; $4FBE
    ; npcs s0v0
    ; npcs s0v4
    db $FF

m01_GreatTree_Overworld_N0v1:  ; $4FBF
    ; npcs s0v1
    ; npcs s0v2
    ; npcs s0v3
    db $04, $04
    ; Exit (4,4)->Castle
    db $00, $00, $05, $04, $07, $05, $04
    ; Exit (5,4)->Castle
    db $00, $00, $05, $05, $07, $FF

m01_GreatTree_Overworld_N1v0:  ; $4FCE
    ; npcs s1v0
    db $03, $02
    ; Exit (3,2)->MedalMan
    db $16, $00, $00, $03, $07, $FF, $04, $03
    ; Exit (4,3)->Arena_Lobby
    db $06, $00, $01, $04, $07, $05, $03
    ; Exit (5,3)->Arena_Lobby
    db $06, $00, $01, $05, $07, $FF, $FF, $05, $03
    ; Exit (5,3)->Library
    db $12, $00, $04, $05, $07, $04, $05
    ; Exit (4,5)->Well
    db $18, $00, $00, $04, $00, $FF, $05, $01
    ; Exit (5,1)->Vault
    db $0F, $00, $00, $05, $07, $09, $03
    ; Exit (9,3)->Bazaar
    db $02, $00, $00, $00, $03, $FF, $04, $06
    ; Exit (4,6)->Starry_Shrine
    db $09, $00, $04, $04, $06, $05, $01
    ; Exit (5,1)->Old_Man_Gate_Room
    db $0D, $00, $00, $05, $07, $04, $04
    ; Exit (4,4)->Copycat_House
    db $10, $00, $00, $04, $07, $FF, $04, $06
    ; Exit (4,6)->Starry_Shrine
    db $09, $00, $04, $04, $06, $05, $01
    ; Exit (5,1)->Old_Man_Gate_Room
    db $0D, $00, $00, $05, $07, $04, $04
    ; Exit (4,4)->Copycat_House
    db $10, $00, $00, $04, $07, $FF, $02, $01
    ; Exit (2,1)->Egg_Evaluator
    db $0C, $00, $00, $02, $07, $FF, $02, $01
    ; Exit (2,1)->Egg_Evaluator
    db $0C, $00, $00, $02, $07, $01, $04
    ; Exit (1,4)->Goopy_Room_1
    db $19, $00, $00, $01, $07, $FF, $02, $01
    ; Exit (2,1)->Egg_Evaluator
    db $0C, $00, $00, $02, $07, $01, $04
    ; Exit (1,4)->Goopy_Room_1
    db $19, $00, $00, $01, $07, $04, $06
    ; Exit (4,6)->Goopy_Room_2
    db $1A, $00, $00, $04, $07, $FF

m02_Bazaar_SP:  ; $505D
    ; screen_ptrs $02
    db $6D, $50, $7B, $50, $8F, $50, $FF, $FF, $A3, $50, $B7, $50, $CB, $50, $FF, $FF

m02_Bazaar_SB0:  ; $506D
    ; step_block scr0 ram=0xD935
    db $35, $D9, $15, $2A, $03, $51, $C3, $52, $15, $2A, $1D, $51, $C3, $52

m02_Bazaar_SB1:  ; $507B
    ; step_block scr1 ram=0xD936
    db $36, $D9, $16, $2A, $3C, $51, $CB, $52, $16, $2A, $4C, $51, $CB, $52, $16, $2A
    db $61, $51, $CB, $52

m02_Bazaar_SB2:  ; $508F
    ; step_block scr2 ram=0xD937
    db $37, $D9, $17, $2A, $76, $51, $CC, $52, $18, $2A, $7C, $51, $CD, $52, $18, $2A
    db $8C, $51, $CD, $52, $38, $D9, $19, $2A, $A1, $51, $CE, $52, $1A, $2A, $AC, $51
    db $CF, $52, $19, $2A, $B7, $51, $CE, $52, $39, $D9, $1B, $2A, $C2, $51, $D0, $52
    db $1C, $2A, $C8, $51, $D1, $52, $1C, $2A, $DD, $51, $D1, $52, $3A, $D9, $1D, $2A
    db $F7, $51, $D2, $52, $1E, $2A, $11, $52, $D3, $52, $1E, $2A, $2B, $52, $D3, $52
    db $1F, $2A, $40, $52, $DB, $52, $1F, $2A, $5A, $52, $DB, $52, $20, $2A, $6F, $52
    db $E3, $52, $20, $2A, $89, $52, $E3, $52, $20, $2A, $9E, $52, $E3, $52, $20, $2A
    db $B3, $52, $E3, $52

m02_Bazaar_X0v0:  ; $5103
    ; exits s0v0
    db $8F, $FF, $06, $02, $01, $8F, $FF, $08, $02, $02, $8F, $FF, $08, $01, $03
    ; NPC t$00 spr$06 (7,2) scr4
    db $00, $06, $07, $02, $04
    ; NPC t$00 spr$03 (3,4) scr5
    db $00, $03, $03, $04, $05, $FF

m02_Bazaar_X0v1:  ; $511D
    ; exits s0v1
    db $8F, $FF, $06, $02, $01, $8F, $FF, $08, $02, $02, $8F, $FF, $08, $01, $03
    ; NPC t$00 spr$06 (7,2) scr4
    db $00, $06, $07, $02, $04
    ; NPC t$00 spr$03 (3,4) scr5
    db $00, $03, $03, $04, $05
    ; NPC t$30 spr$04 (4,5) scr6
    db $30, $04, $04, $05, $06, $FF

m02_Bazaar_X1v0:  ; $513C
    ; exits s1v0
    ; NPC t$00 spr$04 (4,4) scr7
    db $00, $04, $04, $04, $07
    ; NPC t$20 spr$04 (4,5) scr8
    db $20, $04, $04, $05, $08
    ; NPC t$50 spr$39 (10,4) scr255
    db $50, $39, $0A, $04, $FF, $FF

m02_Bazaar_X1v1:  ; $514C
    ; exits s1v1
    ; NPC t$00 spr$04 (4,4) scr7
    db $00, $04, $04, $04, $07
    ; NPC t$20 spr$04 (4,5) scr8
    db $20, $04, $04, $05, $08
    ; NPC t$50 spr$39 (10,4) scr255
    db $50, $39, $0A, $04, $FF
    ; NPC t$00 spr$00 (3,2) scr9
    db $00, $00, $03, $02, $09, $FF

m02_Bazaar_X1v2:  ; $5161
    ; exits s1v2
    ; NPC t$00 spr$04 (4,4) scr7
    db $00, $04, $04, $04, $07
    ; NPC t$20 spr$04 (4,5) scr8
    db $20, $04, $04, $05, $08
    ; NPC t$50 spr$39 (10,4) scr255
    db $50, $39, $0A, $04, $FF
    ; NPC t$02 spr$00 (4,2) scr9
    db $02, $00, $04, $02, $09, $FF

m02_Bazaar_X2v0:  ; $5176
    ; exits s2v0
    ; NPC t$30 spr$0F (1,4) scr10
    db $30, $0F, $01, $04, $0A, $FF

m02_Bazaar_X2v1:  ; $517C
    ; exits s2v1
    db $8F, $FF, $06, $03, $0B
    ; NPC t$32 spr$0F (2,4) scr10
    db $32, $0F, $02, $04, $0A
    ; NPC t$10 spr$06 (7,3) scr12
    db $10, $06, $07, $03, $0C, $FF

m02_Bazaar_X2v2:  ; $518C
    ; exits s2v2
    db $8F, $FF, $06, $03, $0B
    ; NPC t$32 spr$0F (2,4) scr10
    db $32, $0F, $02, $04, $0A
    ; NPC t$10 spr$06 (7,3) scr12
    db $10, $06, $07, $03, $0C
    ; NPC t$00 spr$12 (4,6) scr13
    db $00, $12, $04, $06, $0D, $FF
    ; NPC t$30 spr$06 (3,3) scr14
    db $30, $06, $03, $03, $0E
    ; NPC t$00 spr$0A (8,1) scr15
    db $00, $0A, $08, $01, $0F, $FF
    ; NPC t$30 spr$06 (3,3) scr14
    db $30, $06, $03, $03, $0E
    ; NPC t$00 spr$0A (8,1) scr15
    db $00, $0A, $08, $01, $0F, $FF
    ; NPC t$30 spr$06 (3,3) scr14
    db $30, $06, $03, $03, $0E
    ; NPC t$00 spr$0A (8,1) scr15
    db $00, $0A, $08, $01, $0F, $FF
    ; NPC t$10 spr$05 (8,2) scr16
    db $10, $05, $08, $02, $10, $FF, $8F, $FF, $04, $03, $11, $8F, $FF, $06, $03, $12
    ; NPC t$20 spr$06 (5,3) scr19
    db $20, $06, $05, $03, $13
    ; NPC t$10 spr$05 (8,2) scr16
    db $10, $05, $08, $02, $10, $FF, $8F, $FF, $04, $03, $11, $8F, $FF, $06, $03, $12
    ; NPC t$20 spr$06 (5,3) scr19
    db $20, $06, $05, $03, $13
    ; NPC t$10 spr$05 (8,2) scr16
    db $10, $05, $08, $02, $10
    ; NPC t$00 spr$03 (2,1) scr20
    db $00, $03, $02, $01, $14, $FF, $8F, $FF, $03, $01, $15
    ; NPC t$17 spr$0A (4,1) scr22
    db $17, $0A, $04, $01, $16
    ; NPC t$27 spr$0A (3,2) scr23
    db $27, $0A, $03, $02, $17
    ; NPC t$00 spr$07 (4,3) scr24
    db $00, $07, $04, $03, $18
    ; NPC t$00 spr$4D (7,4) scr255
    db $00, $4D, $07, $04, $FF, $FF
    ; NPC t$17 spr$0A (4,1) scr22
    db $17, $0A, $04, $01, $16
    ; NPC t$27 spr$0A (3,2) scr23
    db $27, $0A, $03, $02, $17
    ; NPC t$00 spr$07 (4,3) scr24
    db $00, $07, $04, $03, $18
    ; NPC t$00 spr$4D (3,1) scr255
    db $00, $4D, $03, $01, $FF
    ; NPC t$00 spr$4D (7,4) scr255
    db $00, $4D, $07, $04, $FF, $FF
    ; NPC t$17 spr$0A (4,1) scr22
    db $17, $0A, $04, $01, $16
    ; NPC t$27 spr$0A (3,2) scr23
    db $27, $0A, $03, $02, $17
    ; NPC t$00 spr$07 (4,3) scr24
    db $00, $07, $04, $03, $18
    ; NPC t$00 spr$4D (7,4) scr255
    db $00, $4D, $07, $04, $FF, $FF, $8F, $FF, $07, $04, $15
    ; NPC t$07 spr$0A (7,3) scr22
    db $07, $0A, $07, $03, $16
    ; NPC t$37 spr$0A (6,4) scr23
    db $37, $0A, $06, $04, $17
    ; NPC t$00 spr$07 (4,2) scr24
    db $00, $07, $04, $02, $18
    ; NPC t$00 spr$4D (3,1) scr255
    db $00, $4D, $03, $01, $FF, $FF, $8F, $FF, $07, $04, $15
    ; NPC t$07 spr$0A (7,3) scr22
    db $07, $0A, $07, $03, $16
    ; NPC t$37 spr$0A (6,4) scr23
    db $37, $0A, $06, $04, $17
    ; NPC t$00 spr$07 (4,2) scr24
    db $00, $07, $04, $02, $18, $FF
    ; NPC t$07 spr$0A (7,3) scr22
    db $07, $0A, $07, $03, $16
    ; NPC t$37 spr$0A (6,4) scr23
    db $37, $0A, $06, $04, $17
    ; NPC t$20 spr$07 (4,2) scr24
    db $20, $07, $04, $02, $18
    ; NPC t$00 spr$4D (3,1) scr255
    db $00, $4D, $03, $01, $FF
    ; NPC t$00 spr$4D (7,4) scr255
    db $00, $4D, $07, $04, $FF, $FF
    ; NPC t$07 spr$0A (7,3) scr22
    db $07, $0A, $07, $03, $16
    ; NPC t$37 spr$0A (6,4) scr23
    db $37, $0A, $06, $04, $17
    ; NPC t$20 spr$07 (4,2) scr24
    db $20, $07, $04, $02, $18
    ; NPC t$00 spr$4D (7,4) scr255
    db $00, $4D, $07, $04, $FF, $FF
    ; NPC t$07 spr$0A (7,3) scr22
    db $07, $0A, $07, $03, $16
    ; NPC t$37 spr$0A (6,4) scr23
    db $37, $0A, $06, $04, $17
    ; NPC t$20 spr$07 (4,2) scr24
    db $20, $07, $04, $02, $18
    ; NPC t$00 spr$4D (3,1) scr255
    db $00, $4D, $03, $01, $FF, $FF
    ; NPC t$07 spr$0A (7,3) scr22
    db $07, $0A, $07, $03, $16
    ; NPC t$37 spr$0A (6,4) scr23
    db $37, $0A, $06, $04, $17
    ; NPC t$20 spr$07 (4,2) scr24
    db $20, $07, $04, $02, $18, $FF

m02_Bazaar_N0v0:  ; $52C3
    ; npcs s0v0
    ; npcs s0v1
    db $00, $03
    ; Exit (0,3)->GreatTree
    db $01, $00, $09, $09, $03, $FF

m02_Bazaar_N1v0:  ; $52CB
    ; npcs s1v0
    ; npcs s1v1
    ; npcs s1v2
    db $FF

m02_Bazaar_N2v0:  ; $52CC
    ; npcs s2v0
    db $FF

m02_Bazaar_N2v1:  ; $52CD
    ; npcs s2v1
    ; npcs s2v2
    db $FF, $FF, $FF, $FF, $FF, $FF, $03, $01
    ; Exit (3,1)->Stable
    db $05, $01, $00, $00, $00, $FF, $03, $01
    ; Exit (3,1)->Stable
    db $05, $01, $00, $00, $00, $FF, $03, $01
    ; Exit (3,1)->Stable
    db $05, $01, $00, $00, $00, $07, $04
    ; Exit (7,4)->Map_1C
    db $1C, $01, $00, $00, $00, $FF

m03_Gate_Hub_SP:  ; $52F2
    ; screen_ptrs $03
    db $02, $53, $1C, $53, $FF, $FF, $FF, $FF, $3C, $53, $5C, $53, $FF, $FF, $FF, $FF

m03_Gate_Hub_SB0:  ; $5302
    ; step_block scr0 ram=0xD93B
    db $3B, $D9, $22, $2A, $6A, $53, $88, $54, $23, $2A, $84, $53, $90, $54, $24, $2A
    db $99, $53, $9F, $54, $25, $2A, $A4, $53, $BC, $54

m03_Gate_Hub_SB1:  ; $531C
    ; step_block scr1 ram=0xD93C
    db $3C, $D9, $26, $2A, $AA, $53, $E0, $54, $27, $2A, $CE, $53, $E8, $54, $27, $2A
    db $E8, $53, $E8, $54, $28, $2A, $F8, $53, $FE, $54, $29, $2A, $03, $54, $1B, $55
    db $3D, $D9, $2A, $2A, $09, $54, $3F, $55, $2B, $2A, $28, $54, $47, $55, $2C, $2A
    db $42, $54, $56, $55, $2D, $2A, $57, $54, $6C, $55, $2D, $2A, $62, $54, $6C, $55
    db $3E, $D9, $2E, $2A, $68, $54, $90, $55, $00, $29, $82, $54, $91, $55

m03_Gate_Hub_X0v0:  ; $536A
    ; exits s0v0
    db $8F, $FF, $04, $01, $01, $8F, $FF, $05, $01, $01, $8F, $FF, $02, $02, $02, $8F
    db $FF, $07, $02, $03
    ; NPC t$20 spr$0B (3,5) scr4
    db $20, $0B, $03, $05, $04, $FF

m03_Gate_Hub_X0v1:  ; $5384
    ; exits s0v1
    db $8F, $FF, $04, $01, $01, $8F, $FF, $05, $01, $01, $8F, $FF, $02, $02, $02
    ; NPC t$20 spr$0B (3,5) scr4
    db $20, $0B, $03, $05, $04, $FF

m03_Gate_Hub_X0v2:  ; $5399
    ; exits s0v2
    db $8F, $FF, $02, $02, $02
    ; NPC t$20 spr$0B (3,5) scr4
    db $20, $0B, $03, $05, $04, $FF

m03_Gate_Hub_X0v3:  ; $53A4
    ; exits s0v3
    ; NPC t$20 spr$0B (3,5) scr4
    db $20, $0B, $03, $05, $04, $FF

m03_Gate_Hub_X1v0:  ; $53AA
    ; exits s1v0
    db $8F, $FF, $04, $01, $05, $8F, $FF, $05, $01, $05, $8F, $FF, $02, $02, $06, $8F
    db $FF, $07, $02, $07
    ; NPC t$30 spr$0B (0,4) scr8
    db $30, $0B, $00, $04, $08
    ; NPC t$30 spr$0B (0,5) scr9
    db $30, $0B, $00, $05, $09
    ; NPC t$20 spr$0B (4,6) scr10
    db $20, $0B, $04, $06, $0A, $FF

m03_Gate_Hub_X1v1:  ; $53CE
    ; exits s1v1
    db $8F, $FF, $02, $02, $06, $8F, $FF, $07, $02, $07
    ; NPC t$30 spr$0B (0,4) scr8
    db $30, $0B, $00, $04, $08
    ; NPC t$30 spr$0B (0,5) scr9
    db $30, $0B, $00, $05, $09
    ; NPC t$20 spr$0B (4,6) scr10
    db $20, $0B, $04, $06, $0A, $FF

m03_Gate_Hub_X1v2:  ; $53E8
    ; exits s1v2
    db $8F, $FF, $02, $02, $06, $8F, $FF, $07, $02, $07
    ; NPC t$22 spr$0B (5,5) scr10
    db $22, $0B, $05, $05, $0A, $FF

m03_Gate_Hub_X1v3:  ; $53F8
    ; exits s1v3
    db $8F, $FF, $07, $02, $07
    ; NPC t$22 spr$0B (5,5) scr10
    db $22, $0B, $05, $05, $0A, $FF

m03_Gate_Hub_X1v4:  ; $5403
    ; exits s1v4
    ; NPC t$22 spr$0B (5,5) scr10
    db $22, $0B, $05, $05, $0A, $FF, $8F, $FF, $04, $01, $0B, $8F, $FF, $05, $01, $0B
    db $8F, $FF, $02, $02, $0C, $8F, $FF, $07, $02, $0D
    ; NPC t$10 spr$0B (9,4) scr14
    db $10, $0B, $09, $04, $0E
    ; NPC t$10 spr$0B (9,5) scr15
    db $10, $0B, $09, $05, $0F, $FF, $8F, $FF, $04, $01, $0B, $8F, $FF, $05, $01, $0B
    db $8F, $FF, $02, $02, $0C
    ; NPC t$10 spr$0B (9,4) scr14
    db $10, $0B, $09, $04, $0E
    ; NPC t$10 spr$0B (9,5) scr15
    db $10, $0B, $09, $05, $0F, $FF, $8F, $FF, $04, $01, $0B, $8F, $FF, $05, $01, $0B
    ; NPC t$10 spr$0B (9,4) scr14
    db $10, $0B, $09, $04, $0E
    ; NPC t$10 spr$0B (9,5) scr15
    db $10, $0B, $09, $05, $0F, $FF
    ; NPC t$10 spr$0B (9,4) scr14
    db $10, $0B, $09, $04, $0E
    ; NPC t$10 spr$0B (9,5) scr15
    db $10, $0B, $09, $05, $0F, $FF
    ; NPC t$00 spr$0B (3,4) scr14
    db $00, $0B, $03, $04, $0E, $FF, $8F, $FF, $04, $01, $10, $8F, $FF, $05, $01, $10
    db $8F, $FF, $02, $02, $11, $8F, $FF, $07, $02, $12
    ; NPC t$20 spr$0B (4,6) scr19
    db $20, $0B, $04, $06, $13, $FF
    ; NPC t$20 spr$0B (4,6) scr19
    db $20, $0B, $04, $06, $13, $FF

m03_Gate_Hub_N0v0:  ; $5488
    ; npcs s0v0
    db $07, $05
    ; Exit (7,5)->Gate_Hub
    db $03, $00, $04, $07, $05, $FF

m03_Gate_Hub_N0v1:  ; $5490
    ; npcs s0v1
    db $07, $05
    ; Exit (7,5)->Gate_Hub
    db $03, $00, $04, $07, $05, $07, $02
    ; Exit (7,2)->Room_PeaceBravery
    db $26, $00, $00, $08, $07, $FF

m03_Gate_Hub_N0v2:  ; $549F
    ; npcs s0v2
    db $07, $05
    ; Exit (7,5)->Gate_Hub
    db $03, $00, $04, $07, $05, $07, $02
    ; Exit (7,2)->Room_PeaceBravery
    db $26, $00, $00, $08, $07, $04, $01
    ; Exit (4,1)->Room_StrengthAnger
    db $27, $00, $00, $04, $07, $05, $01
    ; Exit (5,1)->Room_StrengthAnger
    db $27, $00, $00, $05, $07, $FF

m03_Gate_Hub_N0v3:  ; $54BC
    ; npcs s0v3
    db $07, $05
    ; Exit (7,5)->Gate_Hub
    db $03, $00, $04, $07, $05, $07, $02
    ; Exit (7,2)->Room_PeaceBravery
    db $26, $00, $00, $08, $07, $04, $01
    ; Exit (4,1)->Room_StrengthAnger
    db $27, $00, $00, $04, $07, $05, $01
    ; Exit (5,1)->Room_StrengthAnger
    db $27, $00, $00, $05, $07, $02, $02
    ; Exit (2,2)->Room_JoyWisdom
    db $28, $00, $00, $04, $07, $FF

m03_Gate_Hub_N1v0:  ; $54E0
    ; npcs s1v0
    db $02, $05
    ; Exit (2,5)->Castle
    db $00, $00, $05, $02, $05, $FF

m03_Gate_Hub_N1v1:  ; $54E8
    ; npcs s1v1
    ; npcs s1v2
    db $02, $05
    ; Exit (2,5)->Castle
    db $00, $00, $05, $02, $05, $04, $01
    ; Exit (4,1)->Room_of_Beginning
    db $23, $00, $00, $07, $07, $05, $01
    ; Exit (5,1)->Room_of_Beginning
    db $23, $00, $00, $08, $07, $FF

m03_Gate_Hub_N1v3:  ; $54FE
    ; npcs s1v3
    db $02, $05
    ; Exit (2,5)->Castle
    db $00, $00, $05, $02, $05, $04, $01
    ; Exit (4,1)->Room_of_Beginning
    db $23, $00, $00, $07, $07, $05, $01
    ; Exit (5,1)->Room_of_Beginning
    db $23, $00, $00, $08, $07, $02, $02
    ; Exit (2,2)->Room_VillagerTalisman
    db $24, $00, $00, $06, $07, $FF

m03_Gate_Hub_N1v4:  ; $551B
    ; npcs s1v4
    db $02, $05
    ; Exit (2,5)->Castle
    db $00, $00, $05, $02, $05, $04, $01
    ; Exit (4,1)->Room_of_Beginning
    db $23, $00, $00, $07, $07, $05, $01
    ; Exit (5,1)->Room_of_Beginning
    db $23, $00, $00, $08, $07, $02, $02
    ; Exit (2,2)->Room_VillagerTalisman
    db $24, $00, $00, $06, $07, $07, $02
    ; Exit (7,2)->Room_MemoriesBewilder
    db $25, $00, $00, $01, $07, $FF, $07, $05
    ; Exit (7,5)->Gate_Hub
    db $03, $00, $00, $07, $05, $FF, $07, $05
    ; Exit (7,5)->Gate_Hub
    db $03, $00, $00, $07, $05, $07, $02
    ; Exit (7,2)->Room_HappinessTemptation
    db $29, $00, $00, $04, $07, $FF, $07, $05
    ; Exit (7,5)->Gate_Hub
    db $03, $00, $00, $07, $05, $07, $02
    ; Exit (7,2)->Room_HappinessTemptation
    db $29, $00, $00, $04, $07, $02, $02
    ; Exit (2,2)->Room_LabyrinthJudgment
    db $2A, $00, $00, $04, $07, $FF, $07, $05
    ; Exit (7,5)->Gate_Hub
    db $03, $00, $00, $07, $05, $07, $02
    ; Exit (7,2)->Room_HappinessTemptation
    db $29, $00, $00, $04, $07, $02, $02
    ; Exit (2,2)->Room_LabyrinthJudgment
    db $2A, $00, $00, $04, $07, $04, $01
    ; Exit (4,1)->Room_Reflection
    db $2B, $00, $00, $07, $07, $05, $01
    ; Exit (5,1)->Room_Reflection
    db $2B, $00, $00, $08, $07, $FF, $FF, $02, $02
    ; Exit (2,2)->Room_AmbitionDemolition
    db $2C, $00, $00, $08, $07, $07, $02
    ; Exit (7,2)->Room_MastermindControl
    db $2D, $00, $00, $02, $07, $04, $01
    ; Exit (4,1)->Room_ExtinctionSleep
    db $2E, $00, $00, $06, $07, $05, $01
    ; Exit (5,1)->Room_ExtinctionSleep
    db $2E, $00, $00, $07, $07, $FF

m04_Farm_top_of_GreatTree_SP:  ; $55AE
    ; screen_ptrs $04
    db $BE, $55, $D8, $55, $EC, $55, $FF, $FF, $0C, $56, $26, $56, $3A, $56, $FF, $FF

m04_Farm_top_of_GreatTree_SB0:  ; $55BE
    ; step_block scr0 ram=0xD93F
    db $3F, $D9, $02, $29, $54, $56, $1E, $58, $02, $29, $55, $56, $1E, $58, $02, $29
    db $6A, $56, $1E, $58, $02, $29, $7F, $56, $1E, $58

m04_Farm_top_of_GreatTree_SB1:  ; $55D8
    ; step_block scr1 ram=0xD940
    db $40, $D9, $03, $29, $8F, $56, $1F, $58, $03, $29, $9F, $56, $1F, $58, $03, $29
    db $B4, $56, $1F, $58

m04_Farm_top_of_GreatTree_SB2:  ; $55EC
    ; step_block scr2 ram=0xD941
    db $41, $D9, $04, $29, $D3, $56, $20, $58, $04, $29, $E8, $56, $20, $58, $05, $29
    db $02, $57, $21, $58, $05, $29, $26, $57, $21, $58, $05, $29, $45, $57, $21, $58
    db $42, $D9, $06, $29, $6E, $57, $29, $58, $06, $29, $7E, $57, $29, $58, $06, $29
    db $8E, $57, $29, $58, $06, $29, $9E, $57, $29, $58, $43, $D9, $07, $29, $B3, $57
    db $31, $58, $07, $29, $C3, $57, $31, $58, $07, $29, $D3, $57, $31, $58, $44, $D9
    db $08, $29, $ED, $57, $39, $58, $08, $29, $EE, $57, $39, $58, $08, $29, $F4, $57
    db $39, $58, $08, $29, $FF, $57, $39, $58

m04_Farm_top_of_GreatTree_X0v0:  ; $5654
    ; exits s0v0
    db $FF

m04_Farm_top_of_GreatTree_X0v1:  ; $5655
    ; exits s0v1
    db $90, $FF, $06, $05, $02
    ; NPC t$02 spr$18 (4,1) scr255
    db $02, $18, $04, $01, $FF
    ; NPC t$10 spr$20 (4,6) scr1
    db $10, $20, $04, $06, $01
    ; NPC t$40 spr$53 (6,1) scr255
    db $40, $53, $06, $01, $FF, $FF

m04_Farm_top_of_GreatTree_X0v2:  ; $566A
    ; exits s0v2
    db $90, $FF, $06, $05, $02
    ; NPC t$02 spr$1B (4,1) scr255
    db $02, $1B, $04, $01, $FF
    ; NPC t$00 spr$2C (4,6) scr3
    db $00, $2C, $04, $06, $03
    ; NPC t$40 spr$53 (6,1) scr255
    db $40, $53, $06, $01, $FF, $FF

m04_Farm_top_of_GreatTree_X0v3:  ; $567F
    ; exits s0v3
    ; NPC t$02 spr$1B (4,1) scr255
    db $02, $1B, $04, $01, $FF
    ; NPC t$30 spr$0C (4,6) scr4
    db $30, $0C, $04, $06, $04
    ; NPC t$30 spr$02 (6,5) scr5
    db $30, $02, $06, $05, $05, $FF

m04_Farm_top_of_GreatTree_X1v0:  ; $568F
    ; exits s1v0
    db $90, $FF, $05, $02, $06, $8F, $FF, $04, $01, $07
    ; NPC t$00 spr$19 (6,2) scr8
    db $00, $19, $06, $02, $08, $FF

m04_Farm_top_of_GreatTree_X1v1:  ; $569F
    ; exits s1v1
    db $90, $FF, $05, $02, $06, $8F, $FF, $04, $01, $07
    ; NPC t$00 spr$19 (6,2) scr8
    db $00, $19, $06, $02, $08
    ; NPC t$00 spr$19 (3,4) scr9
    db $00, $19, $03, $04, $09, $FF

m04_Farm_top_of_GreatTree_X1v2:  ; $56B4
    ; exits s1v2
    ; NPC t$00 spr$0D (5,2) scr10
    db $00, $0D, $05, $02, $0A
    ; NPC t$00 spr$0E (4,2) scr11
    db $00, $0E, $04, $02, $0B
    ; NPC t$00 spr$10 (2,3) scr12
    db $00, $10, $02, $03, $0C
    ; NPC t$00 spr$10 (1,4) scr13
    db $00, $10, $01, $04, $0D
    ; NPC t$00 spr$10 (7,3) scr14
    db $00, $10, $07, $03, $0E
    ; NPC t$00 spr$10 (8,4) scr15
    db $00, $10, $08, $04, $0F, $FF

m04_Farm_top_of_GreatTree_X2v0:  ; $56D3
    ; exits s2v0
    db $8F, $FF, $04, $05, $10
    ; NPC t$26 spr$1D (5,6) scr17
    db $26, $1D, $05, $06, $11
    ; NPC t$06 spr$1C (5,3) scr18
    db $06, $1C, $05, $03, $12
    ; NPC t$00 spr$4D (8,2) scr255
    db $00, $4D, $08, $02, $FF, $FF

m04_Farm_top_of_GreatTree_X2v1:  ; $56E8
    ; exits s2v1
    db $90, $FF, $05, $05, $29, $8F, $FF, $04, $05, $10
    ; NPC t$37 spr$1D (1,4) scr17
    db $37, $1D, $01, $04, $11
    ; NPC t$06 spr$1C (5,3) scr18
    db $06, $1C, $05, $03, $12
    ; NPC t$00 spr$4D (8,2) scr255
    db $00, $4D, $08, $02, $FF, $FF

m04_Farm_top_of_GreatTree_X2v2:  ; $5702
    ; exits s2v2
    db $90, $FF, $05, $04, $29, $90, $FF, $05, $05, $29, $90, $FF, $07, $04, $2A, $90
    db $FF, $07, $05, $2A
    ; NPC t$37 spr$1D (4,2) scr17
    db $37, $1D, $04, $02, $11
    ; NPC t$16 spr$1C (5,2) scr18
    db $16, $1C, $05, $02, $12
    ; NPC t$00 spr$4D (8,2) scr255
    db $00, $4D, $08, $02, $FF, $FF

m04_Farm_top_of_GreatTree_X2v3:  ; $5726
    ; exits s2v3
    db $90, $FF, $05, $04, $29, $90, $FF, $05, $05, $29, $90, $FF, $07, $04, $2A, $90
    db $FF, $07, $05, $2A
    ; NPC t$37 spr$1D (4,2) scr17
    db $37, $1D, $04, $02, $11
    ; NPC t$16 spr$1C (5,2) scr18
    db $16, $1C, $05, $02, $12, $FF

m04_Farm_top_of_GreatTree_X2v4:  ; $5745
    ; exits s2v4
    db $90, $FF, $05, $04, $29, $90, $FF, $05, $05, $29, $90, $FF, $07, $04, $2A, $90
    db $FF, $07, $05, $2A
    ; NPC t$36 spr$1D (4,2) scr17
    db $36, $1D, $04, $02, $11
    ; NPC t$16 spr$1C (5,2) scr18
    db $16, $1C, $05, $02, $12
    ; NPC t$10 spr$08 (4,5) scr19
    db $10, $08, $04, $05, $13
    ; NPC t$10 spr$0F (5,6) scr20
    db $10, $0F, $05, $06, $14, $FF, $8F, $FF, $02, $01, $15
    ; NPC t$17 spr$05 (2,2) scr22
    db $17, $05, $02, $02, $16
    ; NPC t$00 spr$3F (6,4) scr23
    db $00, $3F, $06, $04, $17, $FF, $8F, $FF, $02, $01, $15
    ; NPC t$17 spr$05 (2,2) scr22
    db $17, $05, $02, $02, $16
    ; NPC t$00 spr$3F (5,4) scr23
    db $00, $3F, $05, $04, $17, $FF, $8F, $FF, $02, $01, $15
    ; NPC t$17 spr$05 (2,2) scr22
    db $17, $05, $02, $02, $16
    ; NPC t$00 spr$1A (5,4) scr24
    db $00, $1A, $05, $04, $18, $FF, $8F, $FF, $02, $01, $15
    ; NPC t$17 spr$05 (2,2) scr22
    db $17, $05, $02, $02, $16
    ; NPC t$00 spr$1A (6,4) scr24
    db $00, $1A, $06, $04, $18
    ; NPC t$03 spr$00 (6,1) scr25
    db $03, $00, $06, $01, $19, $FF
    ; NPC t$00 spr$00 (5,3) scr26
    db $00, $00, $05, $03, $1A
    ; NPC t$00 spr$3A (5,2) scr27
    db $00, $3A, $05, $02, $1B
    ; NPC t$30 spr$44 (4,6) scr28
    db $30, $44, $04, $06, $1C, $FF
    ; NPC t$00 spr$00 (5,3) scr26
    db $00, $00, $05, $03, $1A
    ; NPC t$00 spr$3A (5,2) scr27
    db $00, $3A, $05, $02, $1B
    ; NPC t$30 spr$45 (4,6) scr29
    db $30, $45, $04, $06, $1D, $FF
    ; NPC t$00 spr$00 (5,3) scr26
    db $00, $00, $05, $03, $1A
    ; NPC t$00 spr$3A (5,2) scr27
    db $00, $3A, $05, $02, $1B
    ; NPC t$32 spr$01 (4,5) scr30
    db $32, $01, $04, $05, $1E
    ; NPC t$00 spr$11 (7,5) scr31
    db $00, $11, $07, $05, $1F
    ; NPC t$33 spr$0B (2,2) scr32
    db $33, $0B, $02, $02, $20, $FF, $FF
    ; NPC t$00 spr$46 (3,3) scr33
    db $00, $46, $03, $03, $21, $FF
    ; NPC t$02 spr$47 (2,1) scr34
    db $02, $47, $02, $01, $22
    ; NPC t$00 spr$48 (3,3) scr35
    db $00, $48, $03, $03, $23, $FF
    ; NPC t$10 spr$12 (5,1) scr36
    db $10, $12, $05, $01, $24
    ; NPC t$10 spr$12 (5,2) scr37
    db $10, $12, $05, $02, $25
    ; NPC t$10 spr$12 (5,3) scr38
    db $10, $12, $05, $03, $26
    ; NPC t$01 spr$04 (1,2) scr39
    db $01, $04, $01, $02, $27
    ; NPC t$00 spr$0F (2,5) scr40
    db $00, $0F, $02, $05, $28
    ; NPC t$40 spr$54 (5,0) scr255
    db $40, $54, $05, $00, $FF, $FF

m04_Farm_top_of_GreatTree_N0v0:  ; $581E
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $FF

m04_Farm_top_of_GreatTree_N1v0:  ; $581F
    ; npcs s1v0
    ; npcs s1v1
    ; npcs s1v2
    db $FF

m04_Farm_top_of_GreatTree_N2v0:  ; $5820
    ; npcs s2v0
    ; npcs s2v1
    db $FF

m04_Farm_top_of_GreatTree_N2v2:  ; $5821
    ; npcs s2v2
    ; npcs s2v3
    ; npcs s2v4
    db $08, $02
    ; Exit (8,2)->Map_0B
    db $0B, $01, $00, $00, $00, $FF, $06, $04
    ; Exit (6,4)->Stable
    db $05, $00, $02, $06, $04, $FF, $07, $05
    ; Exit (7,5)->Castle
    db $00, $00, $05, $07, $05, $FF, $FF

m05_Stable_SP:  ; $583A
    ; screen_ptrs $05
    db $40, $58, $4E, $58, $5C, $58

m05_Stable_SB0:  ; $5840
    ; step_block scr0 ram=0xD945
    db $45, $D9, $0A, $29, $76, $58, $69, $59, $0B, $29, $86, $58, $78, $59

m05_Stable_SB1:  ; $584E
    ; step_block scr1 ram=0xD946
    db $46, $D9, $0C, $29, $AA, $58, $87, $59, $0C, $29, $BF, $58, $87, $59

m05_Stable_SB2:  ; $585C
    ; step_block scr2 ram=0xD947
    db $47, $D9, $0D, $29, $E3, $58, $96, $59, $0D, $29, $07, $59, $96, $59, $0D, $29
    db $26, $59, $96, $59, $0D, $29, $4A, $59, $96, $59

m05_Stable_X0v0:  ; $5876
    ; exits s0v0
    ; NPC t$01 spr$3B (2,2) scr1
    db $01, $3B, $02, $02, $01
    ; NPC t$36 spr$3A (4,6) scr2
    db $36, $3A, $04, $06, $02
    ; NPC t$00 spr$3A (5,6) scr3
    db $00, $3A, $05, $06, $03, $FF

m05_Stable_X0v1:  ; $5886
    ; exits s0v1
    db $8F, $FF, $04, $03, $04, $8F, $FF, $05, $03, $04, $8F, $FF, $04, $04, $04, $8F
    db $FF, $05, $04, $04
    ; NPC t$01 spr$1B (2,2) scr5
    db $01, $1B, $02, $02, $05
    ; NPC t$06 spr$2A (4,6) scr6
    db $06, $2A, $04, $06, $06
    ; NPC t$00 spr$16 (5,6) scr7
    db $00, $16, $05, $06, $07, $FF

m05_Stable_X1v0:  ; $58AA
    ; exits s1v0
    db $8F, $FF, $04, $02, $FF, $8F, $FF, $05, $02, $FF, $8F, $FF, $04, $03, $08, $8F
    db $FF, $05, $03, $08, $FF

m05_Stable_X1v1:  ; $58BF
    ; exits s1v1
    db $8F, $FF, $04, $02, $FF, $8F, $FF, $05, $02, $FF, $8F, $FF, $04, $03, $08, $8F
    db $FF, $05, $03, $08
    ; NPC t$00 spr$49 (1,1) scr9
    db $00, $49, $01, $01, $09
    ; NPC t$10 spr$4A (8,3) scr10
    db $10, $4A, $08, $03, $0A
    ; NPC t$20 spr$4B (3,6) scr11
    db $20, $4B, $03, $06, $0B, $FF

m05_Stable_X2v0:  ; $58E3
    ; exits s2v0
    db $8F, $FF, $04, $03, $0C, $8F, $FF, $05, $03, $0D, $8F, $FF, $07, $00, $0E, $8F
    db $FF, $08, $00, $0F
    ; NPC t$06 spr$25 (2,1) scr17
    db $06, $25, $02, $01, $11
    ; NPC t$00 spr$3E (8,2) scr18
    db $00, $3E, $08, $02, $12
    ; NPC t$37 spr$21 (3,3) scr16
    db $37, $21, $03, $03, $10, $FF

m05_Stable_X2v1:  ; $5907
    ; exits s2v1
    db $8F, $FF, $04, $03, $0C, $8F, $FF, $05, $03, $0D, $8F, $FF, $07, $00, $0E, $8F
    db $FF, $08, $00, $0F
    ; NPC t$06 spr$25 (2,1) scr17
    db $06, $25, $02, $01, $11
    ; NPC t$00 spr$3E (8,2) scr18
    db $00, $3E, $08, $02, $12, $FF

m05_Stable_X2v2:  ; $5926
    ; exits s2v2
    db $8F, $FF, $04, $03, $0C, $8F, $FF, $05, $03, $0D, $8F, $FF, $07, $00, $0E, $8F
    db $FF, $08, $00, $0F
    ; NPC t$06 spr$25 (2,1) scr17
    db $06, $25, $02, $01, $11
    ; NPC t$00 spr$3D (8,2) scr20
    db $00, $3D, $08, $02, $14
    ; NPC t$37 spr$39 (3,3) scr19
    db $37, $39, $03, $03, $13, $FF

m05_Stable_X2v3:  ; $594A
    ; exits s2v3
    db $8F, $FF, $04, $03, $0C, $8F, $FF, $05, $03, $0D, $8F, $FF, $07, $00, $0E, $8F
    db $FF, $08, $00, $0F
    ; NPC t$06 spr$25 (2,1) scr17
    db $06, $25, $02, $01, $11
    ; NPC t$00 spr$3D (8,2) scr20
    db $00, $3D, $08, $02, $14, $FF

m05_Stable_N0v0:  ; $5969
    ; npcs s0v0
    db $04, $00
    ; Exit (4,0)->Map_1B
    db $1B, $00, $00, $04, $07, $05, $00
    ; Exit (5,0)->Map_1B
    db $1B, $00, $00, $05, $07, $FF

m05_Stable_N0v1:  ; $5978
    ; npcs s0v1
    db $04, $00
    ; Exit (4,0)->Map_1B
    db $1B, $00, $00, $04, $07, $05, $00
    ; Exit (5,0)->Map_1B
    db $1B, $00, $00, $05, $07, $FF

m05_Stable_N1v0:  ; $5987
    ; npcs s1v0
    ; npcs s1v1
    db $04, $00
    ; Exit (4,0)->Map_1C
    db $1C, $00, $00, $04, $07, $05, $00
    ; Exit (5,0)->Map_1C
    db $1C, $00, $00, $05, $07, $FF

m05_Stable_N2v0:  ; $5996
    ; npcs s2v0
    ; npcs s2v1
    ; npcs s2v2
    db $06, $04
    ; Exit (6,4)->Farm
    db $04, $00, $04, $06, $04, $FF

m06_Arena_Lobby_SP:  ; $599E
    ; screen_ptrs $06
    db $A6, $59, $AE, $59, $B6, $59, $FF, $FF

m06_Arena_Lobby_SB0:  ; $59A6
    ; step_block scr0 ram=0xD948
    db $48, $D9, $0F, $29, $BE, $59, $0C, $5A

m06_Arena_Lobby_SB1:  ; $59AE
    ; step_block scr1 ram=0xD949
    db $49, $D9, $10, $29, $D8, $59, $14, $5A

m06_Arena_Lobby_SB2:  ; $59B6
    ; step_block scr2 ram=0xD94A
    db $4A, $D9, $11, $29, $01, $5A, $23, $5A

m06_Arena_Lobby_X0v0:  ; $59BE
    ; exits s0v0
    db $90, $FF, $05, $04, $01
    ; NPC t$50 spr$E0 (5,4) scr255
    db $50, $E0, $05, $04, $FF
    ; NPC t$70 spr$E1 (3,5) scr2
    db $70, $E1, $03, $05, $02
    ; NPC t$40 spr$E2 (2,4) scr3
    db $40, $E2, $02, $04, $03
    ; NPC t$50 spr$E3 (3,3) scr4
    db $50, $E3, $03, $03, $04, $FF

m06_Arena_Lobby_X1v0:  ; $59D8
    ; exits s1v0
    db $8F, $FF, $04, $02, $05, $8F, $FF, $05, $02, $05, $8F, $FF, $03, $04, $06, $8F
    db $FF, $06, $06, $07
    ; NPC t$37 spr$12 (2,4) scr8
    db $37, $12, $02, $04, $08
    ; NPC t$17 spr$12 (7,6) scr9
    db $17, $12, $07, $06, $09
    ; NPC t$60 spr$11 (4,8) scr14
    db $60, $11, $04, $08, $0E
    ; NPC t$40 spr$54 (6,5) scr255
    db $40, $54, $06, $05, $FF, $FF

m06_Arena_Lobby_X2v0:  ; $5A01
    ; exits s2v0
    db $82, $FF, $06, $05, $0A
    ; NPC t$00 spr$0B (6,4) scr11
    db $00, $0B, $06, $04, $0B, $FF

m06_Arena_Lobby_N0v0:  ; $5A0C
    ; npcs s0v0
    db $05, $00
    ; Exit (5,0)->Arena_Rooms
    db $07, $00, $04, $05, $07, $FF

m06_Arena_Lobby_N1v0:  ; $5A14
    ; npcs s1v0
    db $04, $07
    ; Exit (4,7)->GreatTree
    db $01, $00, $84, $04, $03, $05, $07
    ; Exit (5,7)->GreatTree
    db $01, $00, $84, $05, $03, $FF

m06_Arena_Lobby_N2v0:  ; $5A23
    ; npcs s2v0
    db $04, $00
    ; Exit (4,0)->Arena_Rooms
    db $07, $00, $06, $04, $07, $FF

m07_Arena_Rooms_SP:  ; $5A2B
    ; screen_ptrs $07
    db $3B, $5A, $43, $5A, $75, $5A, $FF, $FF, $7D, $5A, $8B, $5A, $93, $5A, $FF, $FF

m07_Arena_Rooms_SB0:  ; $5A3B
    ; step_block scr0 ram=0xD94B
    db $4B, $D9, $13, $29, $9B, $5A, $29, $5C

m07_Arena_Rooms_SB1:  ; $5A43
    ; step_block scr1 ram=0xD94C
    db $4C, $D9, $14, $29, $B5, $5A, $31, $5C, $15, $29, $B5, $5A, $32, $5C, $16, $29
    db $D4, $5A, $3A, $5C, $16, $29, $F8, $5A, $3A, $5C, $17, $29, $17, $5B, $49, $5C
    db $17, $29, $40, $5B, $49, $5C, $17, $29, $64, $5B, $49, $5C, $17, $29, $88, $5B
    db $49, $5C

m07_Arena_Rooms_SB2:  ; $5A75
    ; step_block scr2 ram=0xD94D
    db $4D, $D9, $18, $29, $A7, $5B, $5F, $5C, $4E, $D9, $19, $29, $C1, $5B, $67, $5C
    db $19, $29, $D1, $5B, $67, $5C, $4F, $D9, $1A, $29, $E1, $5B, $6F, $5C, $50, $D9
    db $1B, $29, $F1, $5B, $7E, $5C

m07_Arena_Rooms_X0v0:  ; $5A9B
    ; exits s0v0
    db $82, $FF, $03, $04, $01
    ; NPC t$00 spr$41 (8,3) scr2
    db $00, $41, $08, $03, $02
    ; NPC t$40 spr$52 (3,4) scr255
    db $40, $52, $03, $04, $FF
    ; NPC t$40 spr$E0 (3,4) scr255
    db $40, $E0, $03, $04, $FF
    ; NPC t$00 spr$11 (4,2) scr26
    db $00, $11, $04, $02, $1A, $FF

m07_Arena_Rooms_X1v0:  ; $5AB5
    ; exits s1v0
    ; exits s1v1
    db $90, $FF, $03, $05, $03, $90, $FF, $04, $05, $04, $90, $FF, $05, $05, $05
    ; NPC t$06 spr$1F (4,2) scr6
    db $06, $1F, $04, $02, $06
    ; NPC t$00 spr$08 (3,6) scr7
    db $00, $08, $03, $06, $07
    ; NPC t$00 spr$08 (7,5) scr8
    db $00, $08, $07, $05, $08, $FF

m07_Arena_Rooms_X1v2:  ; $5AD4
    ; exits s1v2
    db $90, $FF, $03, $05, $03, $90, $FF, $04, $05, $04, $90, $FF, $05, $05, $05
    ; NPC t$06 spr$1F (4,2) scr6
    db $06, $1F, $04, $02, $06
    ; NPC t$00 spr$08 (3,6) scr7
    db $00, $08, $03, $06, $07
    ; NPC t$00 spr$08 (7,5) scr8
    db $00, $08, $07, $05, $08
    ; NPC t$00 spr$4D (2,4) scr255
    db $00, $4D, $02, $04, $FF, $FF

m07_Arena_Rooms_X1v3:  ; $5AF8
    ; exits s1v3
    db $90, $FF, $03, $05, $03, $90, $FF, $04, $05, $04, $90, $FF, $05, $05, $05
    ; NPC t$06 spr$1F (4,2) scr6
    db $06, $1F, $04, $02, $06
    ; NPC t$00 spr$08 (3,6) scr7
    db $00, $08, $03, $06, $07
    ; NPC t$00 spr$08 (7,5) scr8
    db $00, $08, $07, $05, $08, $FF

m07_Arena_Rooms_X1v4:  ; $5B17
    ; exits s1v4
    db $90, $FF, $03, $05, $03, $90, $FF, $04, $05, $04, $90, $FF, $05, $05, $05
    ; NPC t$06 spr$1F (4,2) scr6
    db $06, $1F, $04, $02, $06
    ; NPC t$00 spr$08 (3,6) scr7
    db $00, $08, $03, $06, $07
    ; NPC t$00 spr$08 (7,5) scr8
    db $00, $08, $07, $05, $08
    ; NPC t$00 spr$4D (2,4) scr255
    db $00, $4D, $02, $04, $FF
    ; NPC t$00 spr$4D (6,4) scr255
    db $00, $4D, $06, $04, $FF, $FF

m07_Arena_Rooms_X1v5:  ; $5B40
    ; exits s1v5
    db $90, $FF, $03, $05, $03, $90, $FF, $04, $05, $04, $90, $FF, $05, $05, $05
    ; NPC t$06 spr$1F (4,2) scr6
    db $06, $1F, $04, $02, $06
    ; NPC t$00 spr$08 (3,6) scr7
    db $00, $08, $03, $06, $07
    ; NPC t$00 spr$08 (7,5) scr8
    db $00, $08, $07, $05, $08
    ; NPC t$00 spr$4D (6,4) scr255
    db $00, $4D, $06, $04, $FF, $FF

m07_Arena_Rooms_X1v6:  ; $5B64
    ; exits s1v6
    db $90, $FF, $03, $05, $03, $90, $FF, $04, $05, $04, $90, $FF, $05, $05, $05
    ; NPC t$06 spr$1F (4,2) scr6
    db $06, $1F, $04, $02, $06
    ; NPC t$00 spr$08 (3,6) scr7
    db $00, $08, $03, $06, $07
    ; NPC t$00 spr$08 (7,5) scr8
    db $00, $08, $07, $05, $08
    ; NPC t$00 spr$4D (2,4) scr255
    db $00, $4D, $02, $04, $FF, $FF

m07_Arena_Rooms_X1v7:  ; $5B88
    ; exits s1v7
    db $90, $FF, $03, $05, $03, $90, $FF, $04, $05, $04, $90, $FF, $05, $05, $05
    ; NPC t$06 spr$1F (4,2) scr6
    db $06, $1F, $04, $02, $06
    ; NPC t$00 spr$08 (3,6) scr7
    db $00, $08, $03, $06, $07
    ; NPC t$00 spr$08 (7,5) scr8
    db $00, $08, $07, $05, $08, $FF

m07_Arena_Rooms_X2v0:  ; $5BA7
    ; exits s2v0
    db $8F, $FF, $01, $02, $09, $8F, $FF, $02, $02, $0A
    ; NPC t$00 spr$04 (3,4) scr11
    db $00, $04, $03, $04, $0B
    ; NPC t$00 spr$0B (6,2) scr12
    db $00, $0B, $06, $02, $0C
    ; NPC t$17 spr$0A (8,5) scr13
    db $17, $0A, $08, $05, $0D, $FF
    ; NPC t$07 spr$09 (2,1) scr14
    db $07, $09, $02, $01, $0E
    ; NPC t$04 spr$42 (8,5) scr15
    db $04, $42, $08, $05, $0F
    ; NPC t$30 spr$0A (1,6) scr16
    db $30, $0A, $01, $06, $10, $FF
    ; NPC t$04 spr$09 (8,5) scr14
    db $04, $09, $08, $05, $0E
    ; NPC t$06 spr$42 (2,1) scr15
    db $06, $42, $02, $01, $0F
    ; NPC t$30 spr$0A (1,6) scr16
    db $30, $0A, $01, $06, $10, $FF
    ; NPC t$00 spr$0B (5,1) scr17
    db $00, $0B, $05, $01, $11
    ; NPC t$20 spr$0F (5,2) scr18
    db $20, $0F, $05, $02, $12
    ; NPC t$22 spr$17 (4,5) scr255
    db $22, $17, $04, $05, $FF, $FF, $8F, $FF, $08, $03, $13, $8F, $FF, $07, $04, $14
    db $8F, $FF, $06, $05, $15, $8F, $FF, $06, $06, $16
    ; NPC t$06 spr$0A (3,2) scr23
    db $06, $0A, $03, $02, $17
    ; NPC t$26 spr$20 (3,3) scr24
    db $26, $20, $03, $03, $18
    ; NPC t$30 spr$0B (2,6) scr25
    db $30, $0B, $02, $06, $19
    ; NPC t$40 spr$E0 (5,0) scr255
    db $40, $E0, $05, $00, $FF
    ; NPC t$40 spr$E1 (5,0) scr255
    db $40, $E1, $05, $00, $FF
    ; NPC t$40 spr$E2 (5,0) scr255
    db $40, $E2, $05, $00, $FF
    ; NPC t$40 spr$E3 (5,0) scr255
    db $40, $E3, $05, $00, $FF, $FF

m07_Arena_Rooms_N0v0:  ; $5C29
    ; npcs s0v0
    db $05, $01
    ; Exit (5,1)->Monster_School
    db $1D, $00, $00, $05, $07, $FF

m07_Arena_Rooms_N1v0:  ; $5C31
    ; npcs s1v0
    db $FF

m07_Arena_Rooms_N1v1:  ; $5C32
    ; npcs s1v1
    db $05, $02
    ; Exit (5,2)->Queen_Room
    db $1F, $00, $00, $05, $02, $FF

m07_Arena_Rooms_N1v2:  ; $5C3A
    ; npcs s1v2
    ; npcs s1v3
    db $05, $02
    ; Exit (5,2)->Queen_Room
    db $1F, $00, $00, $05, $02, $02, $04
    ; Exit (2,4)->Map_0E
    db $0E, $01, $00, $00, $00, $FF

m07_Arena_Rooms_N1v4:  ; $5C49
    ; npcs s1v4
    ; npcs s1v5
    ; npcs s1v6
    db $05, $02
    ; Exit (5,2)->Queen_Room
    db $1F, $00, $00, $05, $02, $02, $04
    ; Exit (2,4)->Map_0E
    db $0E, $01, $00, $00, $00, $06, $04
    ; Exit (6,4)->Monster_School
    db $1D, $01, $00, $00, $00, $FF

m07_Arena_Rooms_N2v0:  ; $5C5F
    ; npcs s2v0
    db $05, $01
    ; Exit (5,1)->Restaurant
    db $1E, $00, $00, $05, $07, $FF, $05, $07
    ; Exit (5,7)->Arena_Lobby
    db $06, $00, $00, $05, $00, $FF, $04, $07
    ; Exit (4,7)->Arena_Lobby
    db $06, $00, $01, $04, $03, $05, $07
    ; Exit (5,7)->Arena_Lobby
    db $06, $00, $01, $05, $03, $FF, $04, $07
    ; Exit (4,7)->Arena_Lobby
    db $06, $00, $02, $04, $00, $FF

m08_Gate_tileset_SP:  ; $5C86
    ; screen_ptrs $08
    db $88, $5C

m08_Gate_tileset_SB0:  ; $5C88
    ; step_block scr0 ram=0xD951
    db $51, $D9, $1E, $29, $C0, $5C, $FF, $FF, $1E, $29, $D0, $5C, $FF, $FF, $1E, $29
    db $E0, $5C, $FF, $FF, $1E, $29, $E0, $5C, $FF, $FF, $1E, $29, $F0, $5C, $FF, $FF
    db $1E, $29, $00, $5D, $FF, $FF, $1E, $29, $10, $5D, $FF, $FF, $1E, $29, $1B, $5D
    db $FF, $FF, $1E, $29, $30, $5D, $FF, $FF
    ; NPC t$20 spr$08 (5,8) scr255
    db $20, $08, $05, $08, $FF
    ; NPC t$40 spr$F0 (5,4) scr255
    db $40, $F0, $05, $04, $FF
    ; NPC t$40 spr$F1 (5,4) scr255
    db $40, $F1, $05, $04, $FF, $FF
    ; NPC t$20 spr$08 (5,8) scr255
    db $20, $08, $05, $08, $FF
    ; NPC t$00 spr$55 (5,4) scr255
    db $00, $55, $05, $04, $FF
    ; NPC t$00 spr$55 (5,4) scr255
    db $00, $55, $05, $04, $FF, $FF
    ; NPC t$20 spr$08 (5,8) scr255
    db $20, $08, $05, $08, $FF
    ; NPC t$40 spr$F0 (5,4) scr255
    db $40, $F0, $05, $04, $FF
    ; NPC t$40 spr$55 (5,4) scr255
    db $40, $55, $05, $04, $FF, $FF
    ; NPC t$20 spr$08 (5,8) scr255
    db $20, $08, $05, $08, $FF
    ; NPC t$40 spr$F0 (5,4) scr255
    db $40, $F0, $05, $04, $FF
    ; NPC t$40 spr$F1 (5,4) scr255
    db $40, $F1, $05, $04, $FF, $FF
    ; NPC t$20 spr$08 (5,8) scr255
    db $20, $08, $05, $08, $FF
    ; NPC t$00 spr$55 (5,4) scr255
    db $00, $55, $05, $04, $FF
    ; NPC t$00 spr$55 (5,4) scr255
    db $00, $55, $05, $04, $FF, $FF
    ; NPC t$60 spr$08 (5,8) scr255
    db $60, $08, $05, $08, $FF
    ; NPC t$20 spr$5E (5,4) scr255
    db $20, $5E, $05, $04, $FF, $FF
    ; NPC t$60 spr$08 (5,8) scr255
    db $60, $08, $05, $08, $FF
    ; NPC t$70 spr$21 (0,4) scr255
    db $70, $21, $00, $04, $FF
    ; NPC t$40 spr$55 (5,4) scr255
    db $40, $55, $05, $04, $FF
    ; NPC t$20 spr$5E (5,7) scr255
    db $20, $5E, $05, $07, $FF, $FF
    ; NPC t$20 spr$08 (5,7) scr255
    db $20, $08, $05, $07, $FF
    ; NPC t$40 spr$21 (5,4) scr255
    db $40, $21, $05, $04, $FF
    ; NPC t$40 spr$55 (5,4) scr255
    db $40, $55, $05, $04, $FF
    ; NPC t$20 spr$5E (5,6) scr255
    db $20, $5E, $05, $06, $FF, $FF, $FF, $FF, $55, $5D, $FF, $FF, $FF, $FF, $69, $5D
    db $7D, $5D, $FF, $FF, $FF, $FF, $52, $D9, $20, $29, $8B, $5D, $5F, $5E, $20, $29
    db $BE, $5D, $5F, $5E, $20, $29, $F6, $5D, $5F, $5E, $53, $D9, $21, $29, $29, $5E
    db $60, $5E, $21, $29, $2F, $5E, $60, $5E, $21, $29, $29, $5E, $68, $5E, $54, $D9
    db $22, $29, $30, $5E, $69, $5E, $22, $29, $4A, $5E, $69, $5E, $8F, $FF, $05, $00
    db $01, $8F, $FF, $07, $00, $02, $8F, $FF, $08, $00, $03
    ; NPC t$00 spr$26 (2,1) scr4
    db $00, $26, $02, $01, $04
    ; NPC t$00 spr$08 (5,1) scr5
    db $00, $08, $05, $01, $05
    ; NPC t$00 spr$0F (6,4) scr6
    db $00, $0F, $06, $04, $06
    ; NPC t$40 spr$E0 (5,0) scr255
    db $40, $E0, $05, $00, $FF
    ; NPC t$40 spr$E1 (5,0) scr255
    db $40, $E1, $05, $00, $FF
    ; NPC t$40 spr$E2 (5,0) scr255
    db $40, $E2, $05, $00, $FF
    ; NPC t$40 spr$E3 (5,0) scr255
    db $40, $E3, $05, $00, $FF, $FF, $8F, $FF, $05, $00, $01, $8F, $FF, $07, $00, $02
    db $8F, $FF, $08, $00, $03, $81, $FF, $05, $03, $07
    ; NPC t$00 spr$26 (2,1) scr4
    db $00, $26, $02, $01, $04
    ; NPC t$00 spr$08 (4,3) scr5
    db $00, $08, $04, $03, $05
    ; NPC t$00 spr$0F (6,4) scr6
    db $00, $0F, $06, $04, $06
    ; NPC t$40 spr$E0 (7,0) scr255
    db $40, $E0, $07, $00, $FF
    ; NPC t$40 spr$E1 (7,0) scr255
    db $40, $E1, $07, $00, $FF
    ; NPC t$40 spr$E2 (7,0) scr255
    db $40, $E2, $07, $00, $FF
    ; NPC t$40 spr$E3 (7,0) scr255
    db $40, $E3, $07, $00, $FF, $FF, $8F, $FF, $05, $00, $01, $8F, $FF, $07, $00, $02
    db $8F, $FF, $08, $00, $03
    ; NPC t$40 spr$26 (2,2) scr4
    db $40, $26, $02, $02, $04
    ; NPC t$30 spr$08 (6,5) scr255
    db $30, $08, $06, $05, $FF
    ; NPC t$40 spr$E0 (2,0) scr255
    db $40, $E0, $02, $00, $FF
    ; NPC t$40 spr$E0 (7,0) scr255
    db $40, $E0, $07, $00, $FF
    ; NPC t$40 spr$E1 (7,0) scr255
    db $40, $E1, $07, $00, $FF
    ; NPC t$40 spr$E2 (7,0) scr255
    db $40, $E2, $07, $00, $FF
    ; NPC t$40 spr$E3 (7,0) scr255
    db $40, $E3, $07, $00, $FF, $FF
    ; NPC t$10 spr$08 (8,6) scr255
    db $10, $08, $08, $06, $FF, $FF, $FF, $90, $FF, $08, $01, $0B
    ; NPC t$00 spr$07 (3,2) scr8
    db $00, $07, $03, $02, $08
    ; NPC t$00 spr$0B (2,4) scr9
    db $00, $0B, $02, $04, $09
    ; NPC t$00 spr$11 (7,5) scr10
    db $00, $11, $07, $05, $0A
    ; NPC t$00 spr$08 (4,1) scr255
    db $00, $08, $04, $01, $FF, $FF, $90, $FF, $08, $01, $0B
    ; NPC t$00 spr$07 (3,2) scr8
    db $00, $07, $03, $02, $08
    ; NPC t$00 spr$0B (2,4) scr9
    db $00, $0B, $02, $04, $09
    ; NPC t$00 spr$11 (7,5) scr10
    db $00, $11, $07, $05, $0A, $FF, $FF, $04, $06
    ; Exit (4,6)->GreatTree
    db $01, $00, $0C, $04, $06, $FF, $FF, $FF

m0A_Secret_Passage_ThroneMedalMan_SP:  ; $5E6A
    ; screen_ptrs $0A
    db $72, $5E, $7A, $5E, $FF, $FF, $FF, $FF

m0A_Secret_Passage_ThroneMedalMan_SB0:  ; $5E72
    ; step_block scr0 ram=0xD955
    db $55, $D9, $24, $29, $82, $5E, $84, $5E

m0A_Secret_Passage_ThroneMedalMan_SB1:  ; $5E7A
    ; step_block scr1 ram=0xD956
    db $56, $D9, $25, $29, $83, $5E, $8C, $5E

m0A_Secret_Passage_ThroneMedalMan_X0v0:  ; $5E82
    ; exits s0v0
    db $FF

m0A_Secret_Passage_ThroneMedalMan_X1v0:  ; $5E83
    ; exits s1v0
    db $FF

m0A_Secret_Passage_ThroneMedalMan_N0v0:  ; $5E84
    ; npcs s0v0
    db $07, $07
    ; Exit (7,7)->Castle
    db $00, $00, $81, $07, $01, $FF

m0A_Secret_Passage_ThroneMedalMan_N1v0:  ; $5E8C
    ; npcs s1v0
    db $03, $07
    ; Exit (3,7)->MedalMan
    db $16, $00, $80, $03, $01, $FF

m0C_Gate_tileset_SP:  ; $5E94
    ; screen_ptrs $0C
    db $96, $5E

m0C_Gate_tileset_SB0:  ; $5E96
    ; step_block scr0 ram=0xD957
    db $57, $D9, $27, $29, $9E, $5E, $B8, $5E

m0C_Gate_tileset_X0v0:  ; $5E9E
    ; exits s0v0
    db $8F, $FF, $01, $01, $01, $8F, $FF, $02, $01, $02, $8F, $FF, $03, $01, $03, $82
    db $FF, $02, $04, $04
    ; NPC t$00 spr$0F (2,3) scr5
    db $00, $0F, $02, $03, $05, $FF

m0C_Gate_tileset_N0v0:  ; $5EB8
    ; npcs s0v0
    db $02, $07
    ; Exit (2,7)->GreatTree
    db $01, $00, $8D, $02, $01, $FF

m0D_Old_Man_Gate_Room_SP:  ; $5EC0
    ; screen_ptrs $0D
    db $C2, $5E

m0D_Old_Man_Gate_Room_SB0:  ; $5EC2
    ; step_block scr0 ram=0xD958
    db $58, $D9, $01, $30, $D0, $5E, $3B, $5F, $01, $30, $08, $5F, $3B, $5F

m0D_Old_Man_Gate_Room_X0v0:  ; $5ED0
    ; exits s0v0
    db $90, $FF, $06, $04, $08, $90, $FF, $07, $05, $08, $90, $FF, $08, $05, $09, $8F
    db $FF, $02, $01, $01, $8F, $FF, $03, $01, $02, $8F, $FF, $01, $05, $03, $8F, $FF
    db $01, $06, $04
    ; NPC t$00 spr$05 (3,5) scr5
    db $00, $05, $03, $05, $05
    ; NPC t$00 spr$04 (6,3) scr6
    db $00, $04, $06, $03, $06
    ; NPC t$00 spr$08 (8,4) scr7
    db $00, $08, $08, $04, $07
    ; NPC t$00 spr$4D (8,2) scr255
    db $00, $4D, $08, $02, $FF, $FF

m0D_Old_Man_Gate_Room_X0v1:  ; $5F08
    ; exits s0v1
    db $90, $FF, $06, $04, $08, $90, $FF, $07, $05, $08, $90, $FF, $08, $05, $09, $8F
    db $FF, $02, $01, $01, $8F, $FF, $03, $01, $02, $8F, $FF, $01, $05, $03, $8F, $FF
    db $01, $06, $04
    ; NPC t$00 spr$05 (3,5) scr5
    db $00, $05, $03, $05, $05
    ; NPC t$00 spr$04 (6,3) scr6
    db $00, $04, $06, $03, $06
    ; NPC t$00 spr$08 (8,4) scr7
    db $00, $08, $08, $04, $07, $FF

m0D_Old_Man_Gate_Room_N0v0:  ; $5F3B
    ; npcs s0v0
    ; npcs s0v1
    db $05, $07
    ; Exit (5,7)->GreatTree
    db $01, $00, $8C, $05, $01, $08, $02
    ; Exit (8,2)->Restaurant
    db $1E, $01, $00, $00, $00, $FF

m0F_X_SP:  ; $5F4A
    ; screen_ptrs $0F
    db $4C, $5F

m0F_X_SB0:  ; $5F4C
    ; step_block scr0 ram=0xD959
    db $59, $D9, $03, $30, $54, $5F, $69, $5F

m0F_X_X0v0:  ; $5F54
    ; exits s0v0
    db $8F, $FF, $05, $03, $01, $8F, $FF, $03, $05, $02
    ; NPC t$00 spr$09 (5,2) scr1
    db $00, $09, $05, $02, $01
    ; NPC t$30 spr$02 (2,5) scr2
    db $30, $02, $02, $05, $02, $FF

m0F_X_N0v0:  ; $5F69
    ; npcs s0v0
    db $05, $07
    ; Exit (5,7)->GreatTree
    db $01, $00, $89, $05, $01, $FF

m10_Copycat_Room_SP:  ; $5F71
    ; screen_ptrs $10
    ; screen_ptrs $17
    db $73, $5F

m10_Copycat_Room_SB0:  ; $5F73
    ; step_block scr0 ram=0xD95A
    ; step_block scr0 ram=0xD95A
    db $5A, $D9, $05, $30, $81, $5F, $C4, $5F, $06, $30, $A5, $5F, $CC, $5F

m10_Copycat_Room_X0v0:  ; $5F81
    ; exits s0v0
    ; exits s0v0
    db $8F, $FF, $02, $01, $01, $8F, $FF, $03, $01, $02, $8F, $FF, $04, $01, $03, $82
    db $FF, $05, $04, $04
    ; NPC t$20 spr$03 (5,3) scr5
    db $20, $03, $05, $03, $05
    ; NPC t$00 spr$0A (4,6) scr6
    db $00, $0A, $04, $06, $06
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF, $FF

m10_Copycat_Room_X0v1:  ; $5FA5
    ; exits s0v1
    ; exits s0v1
    db $90, $FF, $07, $06, $07, $90, $FF, $08, $05, $07, $8F, $FF, $02, $01, $01, $8F
    db $FF, $03, $01, $02, $8F, $FF, $04, $01, $03
    ; NPC t$00 spr$0A (4,6) scr6
    db $00, $0A, $04, $06, $06, $FF

m10_Copycat_Room_N0v0:  ; $5FC4
    ; npcs s0v0
    ; npcs s0v0
    db $04, $07
    ; Exit (4,7)->GreatTree
    db $01, $00, $8C, $04, $04, $FF

m10_Copycat_Room_N0v1:  ; $5FCC
    ; npcs s0v1
    ; npcs s0v1
    db $04, $07
    ; Exit (4,7)->GreatTree
    db $01, $00, $8C, $04, $04, $08, $06
    ; Exit (8,6)->Castle
    db $00, $00, $01, $04, $05, $FF

m12_Library_SP:  ; $5FDB
    ; screen_ptrs $12
    db $EB, $5F, $FF, $FF, $FF, $FF, $FF, $FF, $F3, $5F, $FF, $FF, $FF, $FF, $FF, $FF

m12_Library_SB0:  ; $5FEB
    ; step_block scr0 ram=0xD95B
    db $5B, $D9, $08, $30, $01, $60, $6D, $60, $5C, $D9, $09, $30, $43, $60, $6E, $60
    db $09, $30, $5D, $60, $6E, $60

m12_Library_X0v0:  ; $6001
    ; exits s0v0
    db $8F, $FF, $01, $01, $01, $8F, $FF, $02, $01, $02, $8F, $FF, $03, $01, $03, $8F
    db $FF, $04, $01, $04, $8F, $FF, $07, $01, $05, $8F, $FF, $08, $01, $06, $8F, $FF
    db $02, $04, $07, $8F, $FF, $03, $04, $08, $8F, $FF, $04, $04, $09, $8F, $FF, $06
    db $04, $0A, $8F, $FF, $07, $04, $0B, $8F, $FF, $06, $01, $0C
    ; NPC t$10 spr$02 (2,6) scr13
    db $10, $02, $02, $06, $0D, $FF, $82, $FF, $04, $03, $0E
    ; NPC t$00 spr$02 (4,2) scr15
    db $00, $02, $04, $02, $0F
    ; NPC t$00 spr$03 (6,3) scr17
    db $00, $03, $06, $03, $11
    ; NPC t$30 spr$03 (1,6) scr16
    db $30, $03, $01, $06, $10
    ; NPC t$40 spr$54 (6,2) scr255
    db $40, $54, $06, $02, $FF, $FF, $82, $FF, $04, $03, $0E
    ; NPC t$00 spr$02 (4,2) scr15
    db $00, $02, $04, $02, $0F
    ; NPC t$30 spr$03 (1,6) scr16
    db $30, $03, $01, $06, $10, $FF

m12_Library_N0v0:  ; $606D
    ; npcs s0v0
    db $FF, $05, $07
    ; Exit (5,7)->GreatTree
    db $01, $00, $88, $05, $03, $06, $01
    ; Exit (6,1)->Library_Gate_Room
    db $13, $00, $00, $06, $07, $FF

m13_X_SP:  ; $607D
    ; screen_ptrs $13
    db $7F, $60

m13_X_SB0:  ; $607F
    ; step_block scr0 ram=0xD95D
    db $5D, $D9, $0B, $30, $8D, $60, $2A, $61, $0B, $30, $DE, $60, $2A, $61

m13_X_X0v0:  ; $608D
    ; exits s0v0
    db $8F, $FF, $01, $01, $01, $8F, $FF, $02, $01, $02, $8F, $FF, $03, $01, $03, $8F
    db $FF, $04, $01, $04, $8F, $FF, $05, $01, $05, $8F, $FF, $06, $01, $06, $8F, $FF
    db $07, $01, $07, $8F, $FF, $08, $01, $08, $8F, $FF, $01, $04, $09, $8F, $FF, $02
    db $04, $0A, $8F, $FF, $03, $04, $0B, $8F, $FF, $04, $04, $0C, $8F, $FF, $07, $04
    db $0D, $8F, $FF, $08, $04, $0E
    ; NPC t$10 spr$03 (6,4) scr15
    db $10, $03, $06, $04, $0F
    ; NPC t$00 spr$4D (1,6) scr255
    db $00, $4D, $01, $06, $FF, $FF

m13_X_X0v1:  ; $60DE
    ; exits s0v1
    db $8F, $FF, $01, $01, $01, $8F, $FF, $02, $01, $02, $8F, $FF, $03, $01, $03, $8F
    db $FF, $04, $01, $04, $8F, $FF, $05, $01, $05, $8F, $FF, $06, $01, $06, $8F, $FF
    db $07, $01, $07, $8F, $FF, $08, $01, $08, $8F, $FF, $01, $04, $09, $8F, $FF, $02
    db $04, $0A, $8F, $FF, $03, $04, $0B, $8F, $FF, $04, $04, $0C, $8F, $FF, $07, $04
    db $0D, $8F, $FF, $08, $04, $0E
    ; NPC t$10 spr$03 (6,4) scr15
    db $10, $03, $06, $04, $0F, $FF

m13_X_N0v0:  ; $612A
    ; npcs s0v0
    ; npcs s0v1
    db $06, $07
    ; Exit (6,7)->Library
    db $12, $00, $84, $06, $01, $01, $06
    ; Exit (1,6)->Map_14
    db $14, $01, $00, $00, $00, $FF

m16_MedalMan_Room_SP:  ; $6139
    ; screen_ptrs $16
    db $3B, $61

m16_MedalMan_Room_SB0:  ; $613B
    ; step_block scr0 ram=0xD95E
    db $5E, $D9, $0D, $30, $61, $61, $CB, $61, $0E, $30, $71, $61, $D3, $61, $0E, $30
    db $86, $61, $D3, $61, $0D, $30, $96, $61, $E9, $61, $0E, $30, $A6, $61, $D3, $61
    db $0E, $30, $BB, $61, $D3, $61

m16_MedalMan_Room_X0v0:  ; $6161
    ; exits s0v0
    db $82, $FF, $02, $04, $01
    ; NPC t$00 spr$13 (2,3) scr2
    db $00, $13, $02, $03, $02
    ; NPC t$00 spr$4C (3,2) scr3
    db $00, $4C, $03, $02, $03, $FF

m16_MedalMan_Room_X0v1:  ; $6171
    ; exits s0v1
    db $82, $FF, $02, $04, $01
    ; NPC t$00 spr$13 (2,3) scr2
    db $00, $13, $02, $03, $02
    ; NPC t$00 spr$4C (3,2) scr3
    db $00, $4C, $03, $02, $03
    ; NPC t$00 spr$4D (1,6) scr255
    db $00, $4D, $01, $06, $FF, $FF

m16_MedalMan_Room_X0v2:  ; $6186
    ; exits s0v2
    db $82, $FF, $02, $04, $01
    ; NPC t$00 spr$13 (2,3) scr2
    db $00, $13, $02, $03, $02
    ; NPC t$00 spr$4C (3,2) scr3
    db $00, $4C, $03, $02, $03, $FF

m16_MedalMan_Room_X0v3:  ; $6196
    ; exits s0v3
    db $82, $FF, $02, $04, $01
    ; NPC t$00 spr$13 (2,3) scr2
    db $00, $13, $02, $03, $02
    ; NPC t$00 spr$4C (1,2) scr3
    db $00, $4C, $01, $02, $03, $FF

m16_MedalMan_Room_X0v4:  ; $61A6
    ; exits s0v4
    db $82, $FF, $02, $04, $01
    ; NPC t$00 spr$13 (2,3) scr2
    db $00, $13, $02, $03, $02
    ; NPC t$00 spr$4C (1,2) scr3
    db $00, $4C, $01, $02, $03
    ; NPC t$00 spr$4D (1,6) scr255
    db $00, $4D, $01, $06, $FF, $FF

m16_MedalMan_Room_X0v5:  ; $61BB
    ; exits s0v5
    db $82, $FF, $02, $04, $01
    ; NPC t$00 spr$13 (2,3) scr2
    db $00, $13, $02, $03, $02
    ; NPC t$00 spr$4C (1,2) scr3
    db $00, $4C, $01, $02, $03, $FF

m16_MedalMan_Room_N0v0:  ; $61CB
    ; npcs s0v0
    db $03, $07
    ; Exit (3,7)->GreatTree
    db $01, $00, $81, $03, $02, $FF

m16_MedalMan_Room_N0v1:  ; $61D3
    ; npcs s0v1
    ; npcs s0v2
    ; npcs s0v4
    db $03, $07
    ; Exit (3,7)->GreatTree
    db $01, $00, $81, $03, $02, $03, $01
    ; Exit (3,1)->Secret_Passage
    db $0A, $00, $01, $03, $07, $01, $06
    ; Exit (1,6)->Map_11
    db $11, $01, $00, $00, $00, $FF

m16_MedalMan_Room_N0v3:  ; $61E9
    ; npcs s0v3
    db $03, $07
    ; Exit (3,7)->GreatTree
    db $01, $00, $81, $03, $02, $03, $01
    ; Exit (3,1)->Secret_Passage
    db $0A, $00, $01, $03, $07, $FF

m18_Well_SP:  ; $61F8
    ; screen_ptrs $18
    db $08, $62, $FF, $FF, $FF, $FF, $FF, $FF, $10, $62, $FF, $FF, $FF, $FF, $FF, $FF

m18_Well_SB0:  ; $6208
    ; step_block scr0 ram=0xD95F
    db $5F, $D9, $10, $30, $24, $62, $AA, $62, $60, $D9, $11, $30, $25, $62, $B2, $62
    db $12, $30, $5D, $62, $B3, $62, $12, $30, $86, $62, $B3, $62

m18_Well_X0v0:  ; $6224
    ; exits s0v0
    db $FF, $8F, $FF, $01, $01, $01, $8F, $FF, $07, $01, $02, $8F, $FF, $08, $01, $03
    db $8F, $FF, $02, $05, $04, $8F, $FF, $03, $05, $04, $8F, $FF, $02, $06, $04, $8F
    db $FF, $03, $06, $04, $8F, $FF, $01, $06, $05, $82, $FF, $06, $04, $06
    ; NPC t$07 spr$43 (6,3) scr7
    db $07, $43, $06, $03, $07
    ; NPC t$02 spr$07 (6,5) scr8
    db $02, $07, $06, $05, $08, $FF, $8F, $FF, $01, $01, $01, $8F, $FF, $07, $01, $02
    db $8F, $FF, $08, $01, $03, $8F, $FF, $01, $06, $05, $82, $FF, $06, $04, $06
    ; NPC t$07 spr$43 (6,3) scr7
    db $07, $43, $06, $03, $07
    ; NPC t$02 spr$07 (6,5) scr8
    db $02, $07, $06, $05, $08
    ; NPC t$00 spr$4D (2,6) scr255
    db $00, $4D, $02, $06, $FF, $FF, $8F, $FF, $01, $01, $01, $8F, $FF, $07, $01, $02
    db $8F, $FF, $08, $01, $03, $8F, $FF, $01, $06, $05, $82, $FF, $06, $04, $06
    ; NPC t$07 spr$43 (6,3) scr7
    db $07, $43, $06, $03, $07
    ; NPC t$02 spr$07 (6,5) scr8
    db $02, $07, $06, $05, $08, $FF

m18_Well_N0v0:  ; $62AA
    ; npcs s0v0
    db $04, $00
    ; Exit (4,0)->GreatTree
    db $01, $00, $08, $04, $05, $FF, $FF, $02, $06
    ; Exit (2,6)->Gate_08
    db $08, $01, $00, $00, $00, $FF

m19_X_SP:  ; $62BB
    ; screen_ptrs $19
    db $BD, $62

m19_X_SB0:  ; $62BD
    ; step_block scr0 ram=0xD961
    db $61, $D9, $14, $30, $C5, $62, $DA, $62

m19_X_X0v0:  ; $62C5
    ; exits s0v0
    db $90, $FF, $01, $04, $02, $90, $FF, $02, $04, $03, $90, $FF, $03, $04, $04
    ; NPC t$06 spr$1F (2,2) scr1
    db $06, $1F, $02, $02, $01, $FF

m19_X_N0v0:  ; $62DA
    ; npcs s0v0
    db $01, $07
    ; Exit (1,7)->GreatTree
    db $01, $00, $8D, $01, $04, $FF

m1A_X_SP:  ; $62E2
    ; screen_ptrs $1A
    db $E4, $62

m1A_X_SB0:  ; $62E4
    ; step_block scr0 ram=0xD962
    db $62, $D9, $16, $30, $EC, $62, $0B, $63

m1A_X_X0v0:  ; $62EC
    ; exits s0v0
    db $90, $FF, $03, $04, $04, $90, $FF, $04, $04, $05, $90, $FF, $05, $04, $06
    ; NPC t$06 spr$1F (4,2) scr1
    db $06, $1F, $04, $02, $01
    ; NPC t$00 spr$11 (5,5) scr2
    db $00, $11, $05, $05, $02
    ; NPC t$08 spr$3B (2,6) scr3
    db $08, $3B, $02, $06, $03, $FF

m1A_X_N0v0:  ; $630B
    ; npcs s0v0
    db $04, $07
    ; Exit (4,7)->GreatTree
    db $01, $00, $8D, $04, $06, $FF

m1B_X_SP:  ; $6313
    ; screen_ptrs $1B
    db $15, $63

m1B_X_SB0:  ; $6315
    ; step_block scr0 ram=0xD963
    db $63, $D9, $18, $30, $29, $63, $4F, $63, $18, $30, $34, $63, $4F, $63, $18, $30
    db $3F, $63, $4F, $63

m1B_X_X0v0:  ; $6329
    ; exits s0v0
    ; NPC t$00 spr$22 (4,2) scr1
    db $00, $22, $04, $02, $01
    ; NPC t$00 spr$FF (5,2) scr1
    db $00, $FF, $05, $02, $01, $FF

m1B_X_X0v1:  ; $6334
    ; exits s0v1
    ; NPC t$00 spr$24 (4,2) scr2
    db $00, $24, $04, $02, $02
    ; NPC t$00 spr$FF (5,2) scr2
    db $00, $FF, $05, $02, $02, $FF

m1B_X_X0v2:  ; $633F
    ; exits s0v2
    ; NPC t$00 spr$3B (3,3) scr3
    db $00, $3B, $03, $03, $03
    ; NPC t$00 spr$24 (4,2) scr2
    db $00, $24, $04, $02, $02
    ; NPC t$00 spr$FF (5,2) scr2
    db $00, $FF, $05, $02, $02, $FF

m1B_X_N0v0:  ; $634F
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $04, $07
    ; Exit (4,7)->Stable
    db $05, $00, $80, $04, $00, $05, $07
    ; Exit (5,7)->Stable
    db $05, $00, $80, $05, $00, $FF

m1C_X_SP:  ; $635E
    ; screen_ptrs $1C
    db $60, $63

m1C_X_SB0:  ; $6360
    ; step_block scr0 ram=0xD964
    db $64, $D9, $1A, $30, $6E, $63, $B6, $63, $1A, $30, $92, $63, $B6, $63

m1C_X_X0v0:  ; $636E
    ; exits s0v0
    db $8F, $FF, $04, $02, $01, $8F, $FF, $05, $02, $01, $8F, $FF, $01, $04, $02, $8F
    db $FF, $08, $04, $03
    ; NPC t$40 spr$41 (4,2) scr1
    db $40, $41, $04, $02, $01
    ; NPC t$40 spr$41 (5,2) scr1
    db $40, $41, $05, $02, $01
    ; NPC t$02 spr$40 (3,5) scr4
    db $02, $40, $03, $05, $04, $FF

m1C_X_X0v1:  ; $6392
    ; exits s0v1
    db $8F, $FF, $04, $02, $05, $8F, $FF, $05, $02, $05, $8F, $FF, $01, $04, $02, $8F
    db $FF, $08, $04, $03
    ; NPC t$40 spr$2B (4,2) scr5
    db $40, $2B, $04, $02, $05
    ; NPC t$40 spr$2B (5,2) scr5
    db $40, $2B, $05, $02, $05
    ; NPC t$02 spr$1E (3,5) scr6
    db $02, $1E, $03, $05, $06, $FF

m1C_X_N0v0:  ; $63B6
    ; npcs s0v0
    ; npcs s0v1
    db $04, $07
    ; Exit (4,7)->Stable
    db $05, $00, $81, $04, $00, $05, $07
    ; Exit (5,7)->Stable
    db $05, $00, $81, $05, $00, $FF

m1D_X_SP:  ; $63C5
    ; screen_ptrs $1D
    db $C7, $63

m1D_X_SB0:  ; $63C7
    ; step_block scr0 ram=0xD965
    db $65, $D9, $1C, $30, $CF, $63, $EE, $63

m1D_X_X0v0:  ; $63CF
    ; exits s0v0
    db $8F, $FF, $04, $01, $01, $8F, $FF, $06, $01, $02, $8F, $FF, $05, $03, $03
    ; NPC t$07 spr$11 (5,2) scr4
    db $07, $11, $05, $02, $04
    ; NPC t$27 spr$00 (3,5) scr5
    db $27, $00, $03, $05, $05
    ; NPC t$20 spr$02 (8,6) scr6
    db $20, $02, $08, $06, $06, $FF

m1D_X_N0v0:  ; $63EE
    ; npcs s0v0
    db $05, $07
    ; Exit (5,7)->Arena_Rooms
    db $07, $00, $80, $05, $01, $FF

m1E_X_SP:  ; $63F6
    ; screen_ptrs $1E
    db $F8, $63

m1E_X_SB0:  ; $63F8
    ; step_block scr0 ram=0xD966
    db $66, $D9, $1E, $30, $06, $64, $30, $64, $1E, $30, $1B, $64, $30, $64

m1E_X_X0v0:  ; $6406
    ; exits s0v0
    db $8F, $FF, $05, $03, $01
    ; NPC t$00 spr$05 (5,2) scr1
    db $00, $05, $05, $02, $01
    ; NPC t$37 spr$0F (2,3) scr2
    db $37, $0F, $02, $03, $02
    ; NPC t$20 spr$0B (6,4) scr3
    db $20, $0B, $06, $04, $03, $FF

m1E_X_X0v1:  ; $641B
    ; exits s0v1
    db $8F, $FF, $05, $03, $01
    ; NPC t$00 spr$05 (5,2) scr1
    db $00, $05, $05, $02, $01
    ; NPC t$37 spr$0F (2,3) scr2
    db $37, $0F, $02, $03, $02
    ; NPC t$20 spr$0C (6,4) scr4
    db $20, $0C, $06, $04, $04, $FF

m1E_X_N0v0:  ; $6430
    ; npcs s0v0
    ; npcs s0v1
    db $05, $07
    ; Exit (5,7)->Arena_Rooms
    db $07, $00, $82, $05, $01, $FF

m1F_X_SP:  ; $6438
    ; screen_ptrs $1F
    db $3A, $64

m1F_X_SB0:  ; $643A
    ; step_block scr0 ram=0xD967
    db $67, $D9, $01, $2D, $4E, $64, $9C, $64, $01, $2D, $68, $64, $9C, $64, $01, $2D
    db $82, $64, $9C, $64

m1F_X_X0v0:  ; $644E
    ; exits s0v0
    db $8F, $FF, $02, $06, $01
    ; NPC t$00 spr$0E (5,6) scr2
    db $00, $0E, $05, $06, $02
    ; NPC t$00 spr$11 (7,3) scr3
    db $00, $11, $07, $03, $03
    ; NPC t$00 spr$02 (4,4) scr4
    db $00, $02, $04, $04, $04, $81, $FF, $05, $04, $07, $FF

m1F_X_X0v1:  ; $6468
    ; exits s0v1
    db $8F, $FF, $02, $06, $01
    ; NPC t$00 spr$0E (5,6) scr2
    db $00, $0E, $05, $06, $02
    ; NPC t$00 spr$11 (7,3) scr3
    db $00, $11, $07, $03, $03
    ; NPC t$00 spr$13 (4,4) scr5
    db $00, $13, $04, $04, $05, $81, $FF, $05, $04, $08, $FF

m1F_X_X0v2:  ; $6482
    ; exits s0v2
    db $8F, $FF, $02, $06, $01
    ; NPC t$00 spr$0E (5,6) scr2
    db $00, $0E, $05, $06, $02
    ; NPC t$00 spr$11 (7,3) scr3
    db $00, $11, $07, $03, $03
    ; NPC t$00 spr$14 (4,4) scr6
    db $00, $14, $04, $04, $06, $81, $FF, $05, $04, $09, $FF

m1F_X_N0v0:  ; $649C
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $05, $02
    ; Exit (5,2)->Arena_Rooms
    db $07, $00, $01, $05, $02, $FF

m23_Room_of_Beginning_SP:  ; $64A4
    ; screen_ptrs $23
    db $A6, $64

m23_Room_of_Beginning_SB0:  ; $64A6
    ; step_block scr0 ram=0xD968
    db $68, $D9, $03, $2D, $B4, $64, $C5, $64, $03, $2D, $BF, $64, $C5, $64

m23_Room_of_Beginning_X0v0:  ; $64B4
    ; exits s0v0
    ; NPC t$00 spr$0B (8,5) scr1
    db $00, $0B, $08, $05, $01
    ; NPC t$00 spr$4D (8,2) scr255
    db $00, $4D, $08, $02, $FF, $FF

m23_Room_of_Beginning_X0v1:  ; $64BF
    ; exits s0v1
    ; NPC t$00 spr$0B (8,5) scr1
    db $00, $0B, $08, $05, $01, $FF

m23_Room_of_Beginning_N0v0:  ; $64C5
    ; npcs s0v0
    ; npcs s0v1
    db $07, $07
    ; Exit (7,7)->Gate_Hub
    db $03, $00, $81, $04, $01, $08, $07
    ; Exit (8,7)->Gate_Hub
    db $03, $00, $81, $05, $01, $08, $02
    ; Exit (8,2)->Castle
    db $00, $01, $00, $00, $00, $FF

m24_Room_of_Villager_And_Talisman_SP:  ; $64DB
    ; screen_ptrs $24
    db $DD, $64

m24_Room_of_Villager_And_Talisman_SB0:  ; $64DD
    ; step_block scr0 ram=0xD969
    db $69, $D9, $05, $2D, $F7, $64, $23, $65, $05, $2D, $07, $65, $23, $65, $05, $2D
    db $12, $65, $23, $65, $05, $2D, $1D, $65, $23, $65

m24_Room_of_Villager_And_Talisman_X0v0:  ; $64F7
    ; exits s0v0
    ; NPC t$10 spr$0B (7,5) scr1
    db $10, $0B, $07, $05, $01
    ; NPC t$00 spr$4D (2,2) scr255
    db $00, $4D, $02, $02, $FF
    ; NPC t$00 spr$4D (2,6) scr255
    db $00, $4D, $02, $06, $FF, $FF

m24_Room_of_Villager_And_Talisman_X0v1:  ; $6507
    ; exits s0v1
    ; NPC t$10 spr$0B (7,5) scr1
    db $10, $0B, $07, $05, $01
    ; NPC t$00 spr$4D (2,6) scr255
    db $00, $4D, $02, $06, $FF, $FF

m24_Room_of_Villager_And_Talisman_X0v2:  ; $6512
    ; exits s0v2
    ; NPC t$10 spr$0B (7,5) scr1
    db $10, $0B, $07, $05, $01
    ; NPC t$00 spr$4D (2,2) scr255
    db $00, $4D, $02, $02, $FF, $FF

m24_Room_of_Villager_And_Talisman_X0v3:  ; $651D
    ; exits s0v3
    ; NPC t$10 spr$0B (7,5) scr1
    db $10, $0B, $07, $05, $01, $FF

m24_Room_of_Villager_And_Talisman_N0v0:  ; $6523
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $06, $07
    ; Exit (6,7)->Gate_Hub
    db $03, $00, $81, $02, $02, $02, $02
    ; Exit (2,2)->GreatTree
    db $01, $01, $00, $00, $00, $02, $06
    ; Exit (2,6)->Bazaar
    db $02, $01, $00, $00, $00, $FF

m25_Room_of_Memories_And_Bewilder_SP:  ; $6539
    ; screen_ptrs $25
    db $3B, $65

m25_Room_of_Memories_And_Bewilder_SB0:  ; $653B
    ; step_block scr0 ram=0xD96A
    db $6A, $D9, $07, $2D, $55, $65, $81, $65, $07, $2D, $65, $65, $81, $65, $07, $2D
    db $70, $65, $81, $65, $07, $2D, $7B, $65, $81, $65

m25_Room_of_Memories_And_Bewilder_X0v0:  ; $6555
    ; exits s0v0
    ; NPC t$00 spr$0B (6,3) scr1
    db $00, $0B, $06, $03, $01
    ; NPC t$00 spr$4D (5,1) scr255
    db $00, $4D, $05, $01, $FF
    ; NPC t$00 spr$4D (7,1) scr255
    db $00, $4D, $07, $01, $FF, $FF

m25_Room_of_Memories_And_Bewilder_X0v1:  ; $6565
    ; exits s0v1
    ; NPC t$00 spr$0B (6,3) scr1
    db $00, $0B, $06, $03, $01
    ; NPC t$00 spr$4D (7,1) scr255
    db $00, $4D, $07, $01, $FF, $FF

m25_Room_of_Memories_And_Bewilder_X0v2:  ; $6570
    ; exits s0v2
    ; NPC t$00 spr$0B (6,3) scr1
    db $00, $0B, $06, $03, $01
    ; NPC t$00 spr$4D (5,1) scr255
    db $00, $4D, $05, $01, $FF, $FF

m25_Room_of_Memories_And_Bewilder_X0v3:  ; $657B
    ; exits s0v3
    ; NPC t$00 spr$0B (6,3) scr1
    db $00, $0B, $06, $03, $01, $FF

m25_Room_of_Memories_And_Bewilder_N0v0:  ; $6581
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $01, $07
    ; Exit (1,7)->Gate_Hub
    db $03, $00, $81, $07, $02, $05, $01
    ; Exit (5,1)->Gate_Hub
    db $03, $01, $00, $00, $00, $07, $01
    ; Exit (7,1)->Farm
    db $04, $01, $00, $00, $00, $FF

m26_Room_of_Peace_And_Bravery_SP:  ; $6597
    ; screen_ptrs $26
    db $99, $65

m26_Room_of_Peace_And_Bravery_SB0:  ; $6599
    ; step_block scr0 ram=0xD96B
    db $6B, $D9, $09, $2D, $B3, $65, $DF, $65, $09, $2D, $C3, $65, $DF, $65, $09, $2D
    db $CE, $65, $DF, $65, $09, $2D, $D9, $65, $DF, $65

m26_Room_of_Peace_And_Bravery_X0v0:  ; $65B3
    ; exits s0v0
    ; NPC t$00 spr$0B (8,5) scr1
    db $00, $0B, $08, $05, $01
    ; NPC t$00 spr$4D (3,3) scr255
    db $00, $4D, $03, $03, $FF
    ; NPC t$00 spr$4D (6,3) scr255
    db $00, $4D, $06, $03, $FF, $FF

m26_Room_of_Peace_And_Bravery_X0v1:  ; $65C3
    ; exits s0v1
    ; NPC t$00 spr$0B (8,5) scr1
    db $00, $0B, $08, $05, $01
    ; NPC t$00 spr$4D (6,3) scr255
    db $00, $4D, $06, $03, $FF, $FF

m26_Room_of_Peace_And_Bravery_X0v2:  ; $65CE
    ; exits s0v2
    ; NPC t$00 spr$0B (8,5) scr1
    db $00, $0B, $08, $05, $01
    ; NPC t$00 spr$4D (3,3) scr255
    db $00, $4D, $03, $03, $FF, $FF

m26_Room_of_Peace_And_Bravery_X0v3:  ; $65D9
    ; exits s0v3
    ; NPC t$00 spr$0B (8,5) scr1
    db $00, $0B, $08, $05, $01, $FF

m26_Room_of_Peace_And_Bravery_N0v0:  ; $65DF
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $08, $07
    ; Exit (8,7)->Gate_Hub
    db $03, $00, $80, $07, $02, $03, $03
    ; Exit (3,3)->Arena_Lobby
    db $06, $01, $00, $00, $00, $06, $03
    ; Exit (6,3)->Arena_Rooms
    db $07, $01, $00, $00, $00, $FF

m27_Room_of_Strength_And_Anger_SP:  ; $65F5
    ; screen_ptrs $27
    db $F7, $65

m27_Room_of_Strength_And_Anger_SB0:  ; $65F7
    ; step_block scr0 ram=0xD96C
    db $6C, $D9, $0B, $2D, $0B, $66, $3B, $66, $0B, $2D, $20, $66, $3B, $66, $0B, $2D
    db $30, $66, $3B, $66

m27_Room_of_Strength_And_Anger_X0v0:  ; $660B
    ; exits s0v0
    ; NPC t$01 spr$0B (2,4) scr1
    db $01, $0B, $02, $04, $01
    ; NPC t$01 spr$0B (8,5) scr2
    db $01, $0B, $08, $05, $02
    ; NPC t$00 spr$4D (2,3) scr255
    db $00, $4D, $02, $03, $FF
    ; NPC t$00 spr$4D (7,3) scr255
    db $00, $4D, $07, $03, $FF, $FF

m27_Room_of_Strength_And_Anger_X0v1:  ; $6620
    ; exits s0v1
    ; NPC t$20 spr$0B (1,6) scr1
    db $20, $0B, $01, $06, $01
    ; NPC t$10 spr$0B (8,5) scr2
    db $10, $0B, $08, $05, $02
    ; NPC t$00 spr$4D (2,3) scr255
    db $00, $4D, $02, $03, $FF, $FF

m27_Room_of_Strength_And_Anger_X0v2:  ; $6630
    ; exits s0v2
    ; NPC t$20 spr$0B (1,6) scr1
    db $20, $0B, $01, $06, $01
    ; NPC t$10 spr$0B (8,5) scr2
    db $10, $0B, $08, $05, $02, $FF

m27_Room_of_Strength_And_Anger_N0v0:  ; $663B
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $04, $07
    ; Exit (4,7)->Gate_Hub
    db $03, $00, $80, $04, $01, $05, $07
    ; Exit (5,7)->Gate_Hub
    db $03, $00, $80, $05, $01, $02, $03
    ; Exit (2,3)->Starry_Shrine
    db $09, $01, $00, $00, $00, $07, $03
    ; Exit (7,3)->Secret_Passage
    db $0A, $01, $00, $00, $00, $FF

m28_Room_of_Joy_And_Wisdom_SP:  ; $6658
    ; screen_ptrs $28
    db $5A, $66

m28_Room_of_Joy_And_Wisdom_SB0:  ; $665A
    ; step_block scr0 ram=0xD96D
    db $6D, $D9, $0D, $2D, $74, $66, $A0, $66, $0D, $2D, $84, $66, $A0, $66, $0D, $2D
    db $8F, $66, $A0, $66, $0D, $2D, $9A, $66, $A0, $66

m28_Room_of_Joy_And_Wisdom_X0v0:  ; $6674
    ; exits s0v0
    ; NPC t$10 spr$0B (6,6) scr1
    db $10, $0B, $06, $06, $01
    ; NPC t$00 spr$4D (3,2) scr255
    db $00, $4D, $03, $02, $FF
    ; NPC t$00 spr$4D (5,2) scr255
    db $00, $4D, $05, $02, $FF, $FF

m28_Room_of_Joy_And_Wisdom_X0v1:  ; $6684
    ; exits s0v1
    ; NPC t$10 spr$0B (6,6) scr1
    db $10, $0B, $06, $06, $01
    ; NPC t$00 spr$4D (3,2) scr255
    db $00, $4D, $03, $02, $FF, $FF

m28_Room_of_Joy_And_Wisdom_X0v2:  ; $668F
    ; exits s0v2
    ; NPC t$10 spr$0B (6,6) scr1
    db $10, $0B, $06, $06, $01
    ; NPC t$00 spr$4D (5,2) scr255
    db $00, $4D, $05, $02, $FF, $FF

m28_Room_of_Joy_And_Wisdom_X0v3:  ; $669A
    ; exits s0v3
    ; NPC t$10 spr$0B (6,6) scr1
    db $10, $0B, $06, $06, $01, $FF

m28_Room_of_Joy_And_Wisdom_N0v0:  ; $66A0
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $04, $07
    ; Exit (4,7)->Gate_Hub
    db $03, $00, $80, $02, $02, $03, $02
    ; Exit (3,2)->Egg_Evaluator
    db $0C, $01, $00, $00, $00, $05, $02
    ; Exit (5,2)->Old_Man_Gate_Room
    db $0D, $01, $00, $00, $00, $FF

m29_Room_of_Happiness_And_Temptation_SP:  ; $66B6
    ; screen_ptrs $29
    db $B8, $66

m29_Room_of_Happiness_And_Temptation_SB0:  ; $66B8
    ; step_block scr0 ram=0xD96E
    db $6E, $D9, $0F, $2D, $D2, $66, $FE, $66, $0F, $2D, $E2, $66, $FE, $66, $0F, $2D
    db $ED, $66, $FE, $66, $0F, $2D, $F8, $66, $FE, $66

m29_Room_of_Happiness_And_Temptation_X0v0:  ; $66D2
    ; exits s0v0
    ; NPC t$10 spr$0B (7,6) scr1
    db $10, $0B, $07, $06, $01
    ; NPC t$00 spr$4D (3,2) scr255
    db $00, $4D, $03, $02, $FF
    ; NPC t$00 spr$4D (6,2) scr255
    db $00, $4D, $06, $02, $FF, $FF

m29_Room_of_Happiness_And_Temptation_X0v1:  ; $66E2
    ; exits s0v1
    ; NPC t$10 spr$0B (7,6) scr1
    db $10, $0B, $07, $06, $01
    ; NPC t$00 spr$4D (6,2) scr255
    db $00, $4D, $06, $02, $FF, $FF

m29_Room_of_Happiness_And_Temptation_X0v2:  ; $66ED
    ; exits s0v2
    ; NPC t$10 spr$0B (7,6) scr1
    db $10, $0B, $07, $06, $01
    ; NPC t$00 spr$4D (3,2) scr255
    db $00, $4D, $03, $02, $FF, $FF

m29_Room_of_Happiness_And_Temptation_X0v3:  ; $66F8
    ; exits s0v3
    ; NPC t$10 spr$0B (7,6) scr1
    db $10, $0B, $07, $06, $01, $FF

m29_Room_of_Happiness_And_Temptation_N0v0:  ; $66FE
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $04, $07
    ; Exit (4,7)->Gate_Hub
    db $03, $00, $84, $07, $02, $03, $02
    ; Exit (3,2)->Vault
    db $0F, $01, $00, $00, $00, $06, $02
    ; Exit (6,2)->Copycat_House
    db $10, $01, $00, $00, $00, $FF

m2A_Room_of_Labyrinth_And_Judgment_SP:  ; $6714
    ; screen_ptrs $2A
    db $16, $67

m2A_Room_of_Labyrinth_And_Judgment_SB0:  ; $6716
    ; step_block scr0 ram=0xD96F
    db $6F, $D9, $11, $2D, $30, $67, $5C, $67, $11, $2D, $40, $67, $5C, $67, $11, $2D
    db $4B, $67, $5C, $67, $11, $2D, $56, $67, $5C, $67

m2A_Room_of_Labyrinth_And_Judgment_X0v0:  ; $6730
    ; exits s0v0
    ; NPC t$00 spr$0B (5,2) scr1
    db $00, $0B, $05, $02, $01
    ; NPC t$00 spr$4D (2,4) scr255
    db $00, $4D, $02, $04, $FF
    ; NPC t$00 spr$4D (7,4) scr255
    db $00, $4D, $07, $04, $FF, $FF

m2A_Room_of_Labyrinth_And_Judgment_X0v1:  ; $6740
    ; exits s0v1
    ; NPC t$00 spr$0B (5,2) scr1
    db $00, $0B, $05, $02, $01
    ; NPC t$00 spr$4D (7,4) scr255
    db $00, $4D, $07, $04, $FF, $FF

m2A_Room_of_Labyrinth_And_Judgment_X0v2:  ; $674B
    ; exits s0v2
    ; NPC t$00 spr$0B (5,2) scr1
    db $00, $0B, $05, $02, $01
    ; NPC t$00 spr$4D (2,4) scr255
    db $00, $4D, $02, $04, $FF, $FF

m2A_Room_of_Labyrinth_And_Judgment_X0v3:  ; $6756
    ; exits s0v3
    ; NPC t$00 spr$0B (5,2) scr1
    db $00, $0B, $05, $02, $01, $FF

m2A_Room_of_Labyrinth_And_Judgment_N0v0:  ; $675C
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $04, $07
    ; Exit (4,7)->Gate_Hub
    db $03, $00, $84, $02, $02, $02, $04
    ; Exit (2,4)->Library
    db $12, $01, $00, $00, $00, $07, $04
    ; Exit (7,4)->Library_Gate_Room
    db $13, $01, $00, $00, $00, $FF

m2B_Room_of_Reflection_SP:  ; $6772
    ; screen_ptrs $2B
    db $74, $67

m2B_Room_of_Reflection_SB0:  ; $6774
    ; step_block scr0 ram=0xD970
    db $70, $D9, $13, $2D, $82, $67, $93, $67, $13, $2D, $8D, $67, $93, $67

m2B_Room_of_Reflection_X0v0:  ; $6782
    ; exits s0v0
    ; NPC t$30 spr$0B (1,6) scr1
    db $30, $0B, $01, $06, $01
    ; NPC t$00 spr$4D (3,2) scr255
    db $00, $4D, $03, $02, $FF, $FF

m2B_Room_of_Reflection_X0v1:  ; $678D
    ; exits s0v1
    ; NPC t$30 spr$0B (1,6) scr1
    db $30, $0B, $01, $06, $01, $FF

m2B_Room_of_Reflection_N0v0:  ; $6793
    ; npcs s0v0
    ; npcs s0v1
    db $07, $07
    ; Exit (7,7)->Gate_Hub
    db $03, $00, $84, $04, $01, $08, $07
    ; Exit (8,7)->Gate_Hub
    db $03, $00, $84, $05, $01, $03, $02
    ; Exit (3,2)->Map_15
    db $15, $01, $00, $00, $00, $FF

m2C_Room_of_Ambition_And_Demolition_SP:  ; $67A9
    ; screen_ptrs $2C
    db $AB, $67

m2C_Room_of_Ambition_And_Demolition_SB0:  ; $67AB
    ; step_block scr0 ram=0xD971
    db $71, $D9, $15, $2D, $C5, $67, $F1, $67, $15, $2D, $D5, $67, $F1, $67, $15, $2D
    db $E0, $67, $F1, $67, $15, $2D, $EB, $67, $F1, $67

m2C_Room_of_Ambition_And_Demolition_X0v0:  ; $67C5
    ; exits s0v0
    ; NPC t$30 spr$0B (1,6) scr1
    db $30, $0B, $01, $06, $01
    ; NPC t$00 spr$4D (1,3) scr255
    db $00, $4D, $01, $03, $FF
    ; NPC t$00 spr$4D (3,3) scr255
    db $00, $4D, $03, $03, $FF, $FF

m2C_Room_of_Ambition_And_Demolition_X0v1:  ; $67D5
    ; exits s0v1
    ; NPC t$30 spr$0B (1,6) scr1
    db $30, $0B, $01, $06, $01
    ; NPC t$00 spr$4D (3,3) scr255
    db $00, $4D, $03, $03, $FF, $FF

m2C_Room_of_Ambition_And_Demolition_X0v2:  ; $67E0
    ; exits s0v2
    ; NPC t$30 spr$0B (1,6) scr1
    db $30, $0B, $01, $06, $01
    ; NPC t$00 spr$4D (1,3) scr255
    db $00, $4D, $01, $03, $FF, $FF

m2C_Room_of_Ambition_And_Demolition_X0v3:  ; $67EB
    ; exits s0v3
    ; NPC t$30 spr$0B (1,6) scr1
    db $30, $0B, $01, $06, $01, $FF

m2C_Room_of_Ambition_And_Demolition_N0v0:  ; $67F1
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $08, $07
    ; Exit (8,7)->Gate_Hub
    db $03, $00, $85, $02, $02, $01, $03
    ; Exit (1,3)->MedalMan
    db $16, $01, $00, $00, $00, $03, $03
    ; Exit (3,3)->Map_17
    db $17, $01, $00, $00, $00, $FF

m2D_Room_of_Mastermind_And_Control_SP:  ; $6807
    ; screen_ptrs $2D
    db $09, $68

m2D_Room_of_Mastermind_And_Control_SB0:  ; $6809
    ; step_block scr0 ram=0xD972
    db $72, $D9, $17, $2D, $23, $68, $4F, $68, $17, $2D, $33, $68, $4F, $68, $17, $2D
    db $3E, $68, $4F, $68, $17, $2D, $49, $68, $4F, $68

m2D_Room_of_Mastermind_And_Control_X0v0:  ; $6823
    ; exits s0v0
    ; NPC t$00 spr$0B (2,2) scr1
    db $00, $0B, $02, $02, $01
    ; NPC t$00 spr$4D (6,2) scr255
    db $00, $4D, $06, $02, $FF
    ; NPC t$00 spr$4D (6,4) scr255
    db $00, $4D, $06, $04, $FF, $FF

m2D_Room_of_Mastermind_And_Control_X0v1:  ; $6833
    ; exits s0v1
    ; NPC t$00 spr$0B (2,2) scr1
    db $00, $0B, $02, $02, $01
    ; NPC t$00 spr$4D (6,4) scr255
    db $00, $4D, $06, $04, $FF, $FF

m2D_Room_of_Mastermind_And_Control_X0v2:  ; $683E
    ; exits s0v2
    ; NPC t$00 spr$0B (2,2) scr1
    db $00, $0B, $02, $02, $01
    ; NPC t$00 spr$4D (6,2) scr255
    db $00, $4D, $06, $02, $FF, $FF

m2D_Room_of_Mastermind_And_Control_X0v3:  ; $6849
    ; exits s0v3
    ; NPC t$00 spr$0B (2,2) scr1
    db $00, $0B, $02, $02, $01, $FF

m2D_Room_of_Mastermind_And_Control_N0v0:  ; $684F
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $02, $07
    ; Exit (2,7)->Gate_Hub
    db $03, $00, $85, $07, $02, $06, $02
    ; Exit (6,2)->Well
    db $18, $01, $00, $00, $00, $06, $04
    ; Exit (6,4)->Goopy_Room_1
    db $19, $01, $00, $00, $00, $FF

m2E_Room_of_Extinction_And_Sleep_SP:  ; $6865
    ; screen_ptrs $2E
    db $67, $68

m2E_Room_of_Extinction_And_Sleep_SB0:  ; $6867
    ; step_block scr0 ram=0xD973
    db $73, $D9, $19, $2D, $81, $68, $AD, $68, $19, $2D, $91, $68, $AD, $68, $19, $2D
    db $9C, $68, $AD, $68, $19, $2D, $A7, $68, $AD, $68

m2E_Room_of_Extinction_And_Sleep_X0v0:  ; $6881
    ; exits s0v0
    ; NPC t$00 spr$0B (3,4) scr1
    db $00, $0B, $03, $04, $01
    ; NPC t$00 spr$4D (2,2) scr255
    db $00, $4D, $02, $02, $FF
    ; NPC t$00 spr$4D (4,2) scr255
    db $00, $4D, $04, $02, $FF, $FF

m2E_Room_of_Extinction_And_Sleep_X0v1:  ; $6891
    ; exits s0v1
    ; NPC t$00 spr$0B (3,4) scr1
    db $00, $0B, $03, $04, $01
    ; NPC t$00 spr$4D (4,2) scr255
    db $00, $4D, $04, $02, $FF, $FF

m2E_Room_of_Extinction_And_Sleep_X0v2:  ; $689C
    ; exits s0v2
    ; NPC t$00 spr$0B (3,4) scr1
    db $00, $0B, $03, $04, $01
    ; NPC t$00 spr$4D (2,2) scr255
    db $00, $4D, $02, $02, $FF, $FF

m2E_Room_of_Extinction_And_Sleep_X0v3:  ; $68A7
    ; exits s0v3
    ; NPC t$00 spr$0B (3,4) scr1
    db $00, $0B, $03, $04, $01, $FF

m2E_Room_of_Extinction_And_Sleep_N0v0:  ; $68AD
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $06, $07
    ; Exit (6,7)->Gate_Hub
    db $03, $00, $85, $04, $01, $07, $07
    ; Exit (7,7)->Gate_Hub
    db $03, $00, $85, $05, $01, $02, $02
    ; Exit (2,2)->Goopy_Room_2
    db $1A, $01, $00, $00, $00, $04, $02
    ; Exit (4,2)->Map_1B
    db $1B, $01, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $D6, $68
    db $02, $69, $74, $D9, $1B, $2D, $10, $69, $AD, $6A, $1B, $2D, $43, $69, $AD, $6A
    db $1B, $2D, $67, $69, $AD, $6A, $1B, $2D, $A4, $69, $AD, $6A, $1B, $2D, $E1, $69
    db $AD, $6A, $1B, $2D, $28, $6A, $AD, $6A, $1B, $2D, $67, $69, $AD, $6A, $75, $D9
    db $1C, $2D, $65, $6A, $AE, $6A, $1C, $2D, $8E, $6A, $AE, $6A, $8F, $FF, $01, $01
    db $01, $8F, $FF, $02, $01, $02, $8F, $FF, $07, $01, $03, $8F, $FF, $08, $01, $04
    db $8F, $FF, $05, $04, $05, $8F, $FF, $04, $01, $06, $8F, $FF, $05, $01, $06
    ; NPC t$50 spr$14 (5,3) scr7
    db $50, $14, $05, $03, $07
    ; NPC t$00 spr$51 (6,4) scr7
    db $00, $51, $06, $04, $07
    ; NPC t$40 spr$50 (3,4) scr255
    db $40, $50, $03, $04, $FF, $FF, $8F, $FF, $01, $01, $01, $8F, $FF, $02, $01, $02
    db $8F, $FF, $07, $01, $03, $8F, $FF, $08, $01, $04, $8F, $FF, $05, $04, $05, $8F
    db $FF, $04, $01, $06, $8F, $FF, $05, $01, $06, $FF, $8F, $FF, $01, $01, $01, $8F
    db $FF, $02, $01, $02, $8F, $FF, $07, $01, $03, $8F, $FF, $08, $01, $04, $8F, $FF
    db $05, $04, $05, $8F, $FF, $04, $01, $06, $8F, $FF, $05, $01, $06
    ; NPC t$50 spr$14 (7,4) scr7
    db $50, $14, $07, $04, $07
    ; NPC t$50 spr$21 (11,0) scr255
    db $50, $21, $0B, $00, $FF
    ; NPC t$00 spr$51 (6,4) scr7
    db $00, $51, $06, $04, $07
    ; NPC t$40 spr$5F (5,3) scr255
    db $40, $5F, $05, $03, $FF
    ; NPC t$40 spr$50 (3,4) scr255
    db $40, $50, $03, $04, $FF, $FF, $8F, $FF, $01, $01, $01, $8F, $FF, $02, $01, $02
    db $8F, $FF, $07, $01, $03, $8F, $FF, $08, $01, $04, $8F, $FF, $05, $04, $05, $8F
    db $FF, $04, $01, $06, $8F, $FF, $05, $01, $06
    ; NPC t$50 spr$14 (7,4) scr7
    db $50, $14, $07, $04, $07
    ; NPC t$50 spr$21 (11,0) scr255
    db $50, $21, $0B, $00, $FF
    ; NPC t$00 spr$51 (6,4) scr7
    db $00, $51, $06, $04, $07
    ; NPC t$40 spr$5F (5,3) scr255
    db $40, $5F, $05, $03, $FF
    ; NPC t$40 spr$50 (3,4) scr255
    db $40, $50, $03, $04, $FF, $FF, $90, $FF, $02, $03, $0D, $90, $FF, $04, $03, $0E
    db $8F, $FF, $01, $01, $01, $8F, $FF, $02, $01, $02, $8F, $FF, $07, $01, $03, $8F
    db $FF, $08, $01, $04, $8F, $FF, $05, $04, $05, $8F, $FF, $04, $01, $06, $8F, $FF
    db $05, $01, $06
    ; NPC t$10 spr$14 (7,4) scr7
    db $10, $14, $07, $04, $07
    ; NPC t$40 spr$21 (11,4) scr255
    db $40, $21, $0B, $04, $FF
    ; NPC t$70 spr$14 (7,4) scr7
    db $70, $14, $07, $04, $07
    ; NPC t$40 spr$5F (5,3) scr255
    db $40, $5F, $05, $03, $FF
    ; NPC t$40 spr$50 (3,4) scr255
    db $40, $50, $03, $04, $FF, $FF, $8F, $FF, $01, $01, $01, $8F, $FF, $02, $01, $02
    db $8F, $FF, $07, $01, $03, $8F, $FF, $08, $01, $04, $8F, $FF, $05, $04, $05, $8F
    db $FF, $04, $01, $06, $8F, $FF, $05, $01, $06
    ; NPC t$50 spr$14 (6,4) scr6
    db $50, $14, $06, $04, $06
    ; NPC t$50 spr$21 (11,0) scr255
    db $50, $21, $0B, $00, $FF
    ; NPC t$00 spr$51 (6,4) scr6
    db $00, $51, $06, $04, $06
    ; NPC t$00 spr$5F (4,5) scr255
    db $00, $5F, $04, $05, $FF
    ; NPC t$00 spr$50 (3,4) scr255
    db $00, $50, $03, $04, $FF, $FF, $8F, $FF, $01, $01, $08, $8F, $FF, $02, $01, $09
    db $8F, $FF, $08, $01, $0A, $8F, $FF, $08, $05, $0B, $8F, $FF, $05, $01, $0C
    ; NPC t$40 spr$21 (8,1) scr255
    db $40, $21, $08, $01, $FF
    ; NPC t$40 spr$39 (8,1) scr255
    db $40, $39, $08, $01, $FF
    ; NPC t$50 spr$14 (0,4) scr7
    db $50, $14, $00, $04, $07, $FF, $8F, $FF, $01, $01, $08, $8F, $FF, $02, $01, $09
    db $8F, $FF, $08, $01, $0A, $8F, $FF, $08, $05, $0B, $8F, $FF, $05, $01, $0C
    ; NPC t$40 spr$21 (8,2) scr255
    db $40, $21, $08, $02, $FF, $FF, $FF, $FF

m30_Boss_Room___Gate_of_Beginning_SP:  ; $6AAF
    ; screen_ptrs $30
    db $B1, $6A

m30_Boss_Room___Gate_of_Beginning_SB0:  ; $6AB1
    ; step_block scr0 ram=0xD976
    db $76, $D9, $0D, $26, $BF, $6A, $CB, $6A, $0E, $26, $CA, $6A, $CC, $6A

m30_Boss_Room___Gate_of_Beginning_X0v0:  ; $6ABF
    ; exits s0v0
    ; NPC t$00 spr$16 (1,2) scr1
    db $00, $16, $01, $02, $01
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF, $FF

m30_Boss_Room___Gate_of_Beginning_X0v1:  ; $6ACA
    ; exits s0v1
    db $FF

m30_Boss_Room___Gate_of_Beginning_N0v0:  ; $6ACB
    ; npcs s0v0
    db $FF

m30_Boss_Room___Gate_of_Beginning_N0v1:  ; $6ACC
    ; npcs s0v1
    db $01, $02
    ; Exit (1,2)->Castle
    db $00, $00, $01, $04, $05, $FF

m31_Boss_Room___Gate_of_Villager_SP:  ; $6AD4
    ; screen_ptrs $31
    db $D6, $6A

m31_Boss_Room___Gate_of_Villager_SB0:  ; $6AD6
    ; step_block scr0 ram=0xD977
    db $77, $D9, $10, $26, $E4, $6A, $09, $6B, $11, $26, $03, $6B, $0A, $6B

m31_Boss_Room___Gate_of_Villager_X0v0:  ; $6AE4
    ; exits s0v0
    db $8F, $FF, $04, $01, $02, $8F, $FF, $05, $01, $02, $8F, $FF, $04, $02, $02, $8F
    db $FF, $05, $02, $02
    ; NPC t$00 spr$0E (8,3) scr1
    db $00, $0E, $08, $03, $01
    ; NPC t$70 spr$21 (0,0) scr255
    db $70, $21, $00, $00, $FF, $FF

m31_Boss_Room___Gate_of_Villager_X0v1:  ; $6B03
    ; exits s0v1
    ; NPC t$00 spr$0E (8,3) scr1
    db $00, $0E, $08, $03, $01, $FF

m31_Boss_Room___Gate_of_Villager_N0v0:  ; $6B09
    ; npcs s0v0
    db $FF

m31_Boss_Room___Gate_of_Villager_N0v1:  ; $6B0A
    ; npcs s0v1
    db $04, $01
    ; Exit (4,1)->Castle
    db $00, $00, $01, $04, $05, $FF

m32_Boss_Room___Gate_of_Talisman_SP:  ; $6B12
    ; screen_ptrs $32
    db $14, $6B

m32_Boss_Room___Gate_of_Talisman_SB0:  ; $6B14
    ; step_block scr0 ram=0xD978
    db $78, $D9, $16, $24, $22, $6B, $38, $6B, $17, $24, $37, $6B, $39, $6B

m32_Boss_Room___Gate_of_Talisman_X0v0:  ; $6B22
    ; exits s0v0
    db $90, $FF, $05, $04, $02
    ; NPC t$00 spr$20 (4,4) scr1
    db $00, $20, $04, $04, $01
    ; NPC t$40 spr$39 (8,0) scr255
    db $40, $39, $08, $00, $FF
    ; NPC t$50 spr$21 (10,1) scr255
    db $50, $21, $0A, $01, $FF, $FF

m32_Boss_Room___Gate_of_Talisman_X0v1:  ; $6B37
    ; exits s0v1
    db $FF

m32_Boss_Room___Gate_of_Talisman_N0v0:  ; $6B38
    ; npcs s0v0
    db $FF

m32_Boss_Room___Gate_of_Talisman_N0v1:  ; $6B39
    ; npcs s0v1
    db $05, $04
    ; Exit (5,4)->Castle
    db $00, $00, $01, $04, $05, $FF

m33_Boss_Room___Gate_of_Memories_SP:  ; $6B41
    ; screen_ptrs $33
    db $43, $6B

m33_Boss_Room___Gate_of_Memories_SB0:  ; $6B43
    ; step_block scr0 ram=0xD979
    db $79, $D9, $13, $26, $51, $6B, $5D, $6B, $14, $26, $5C, $6B, $5E, $6B

m33_Boss_Room___Gate_of_Memories_X0v0:  ; $6B51
    ; exits s0v0
    ; NPC t$00 spr$3C (4,4) scr1
    db $00, $3C, $04, $04, $01
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF, $FF

m33_Boss_Room___Gate_of_Memories_X0v1:  ; $6B5C
    ; exits s0v1
    db $FF

m33_Boss_Room___Gate_of_Memories_N0v0:  ; $6B5D
    ; npcs s0v0
    db $FF

m33_Boss_Room___Gate_of_Memories_N0v1:  ; $6B5E
    ; npcs s0v1
    db $01, $04
    ; Exit (1,4)->Castle
    db $00, $00, $01, $04, $05, $FF

m34_Boss_Room___Gate_of_Bewilder_SP:  ; $6B66
    ; screen_ptrs $34
    db $68, $6B

m34_Boss_Room___Gate_of_Bewilder_SB0:  ; $6B68
    ; step_block scr0 ram=0xD97A
    db $7A, $D9, $16, $26, $76, $6B, $B9, $6B, $17, $26, $B3, $6B, $BA, $6B

m34_Boss_Room___Gate_of_Bewilder_X0v0:  ; $6B76
    ; exits s0v0
    db $90, $FF, $07, $01, $07, $90, $FF, $04, $04, $08, $90, $FF, $05, $05, $09, $90
    db $FF, $01, $03, $0A, $8F, $FF, $00, $06, $01, $8F, $FF, $04, $01, $02, $8F, $FF
    db $05, $01, $02
    ; NPC t$06 spr$25 (1,2) scr3
    db $06, $25, $01, $02, $03
    ; NPC t$06 spr$25 (8,0) scr4
    db $06, $25, $08, $00, $04
    ; NPC t$06 spr$25 (5,3) scr5
    db $06, $25, $05, $03, $05
    ; NPC t$06 spr$25 (6,6) scr6
    db $06, $25, $06, $06, $06
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF, $FF

m34_Boss_Room___Gate_of_Bewilder_X0v1:  ; $6BB3
    ; exits s0v1
    db $8F, $FF, $00, $06, $01, $FF

m34_Boss_Room___Gate_of_Bewilder_N0v0:  ; $6BB9
    ; npcs s0v0
    db $FF

m34_Boss_Room___Gate_of_Bewilder_N0v1:  ; $6BBA
    ; npcs s0v1
    db $05, $01
    ; Exit (5,1)->Castle
    db $00, $00, $01, $04, $05, $FF

m35_X_SP:  ; $6BC2
    ; screen_ptrs $35
    db $C4, $6B

m35_X_SB0:  ; $6BC4
    ; step_block scr0 ram=0xD97B
    db $7B, $D9, $19, $26, $D2, $6B, $F2, $6B, $1A, $26, $E7, $6B, $F3, $6B

m35_X_X0v0:  ; $6BD2
    ; exits s0v0
    db $8F, $FF, $06, $06, $01, $82, $FF, $05, $00, $02
    ; NPC t$10 spr$1D (7,3) scr3
    db $10, $1D, $07, $03, $03
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF, $FF

m35_X_X0v1:  ; $6BE7
    ; exits s0v1
    db $8F, $FF, $06, $06, $01, $82, $FF, $05, $00, $02, $FF

m35_X_N0v0:  ; $6BF2
    ; npcs s0v0
    db $FF

m35_X_N0v1:  ; $6BF3
    ; npcs s0v1
    db $07, $03
    ; Exit (7,3)->Castle
    db $00, $00, $01, $04, $05, $FF

m36_Boss_Room___Gate_of_Peace_SP:  ; $6BFB
    ; screen_ptrs $36
    db $FD, $6B

m36_Boss_Room___Gate_of_Peace_SB0:  ; $6BFD
    ; step_block scr0 ram=0xD97C
    db $7C, $D9, $1C, $26, $0B, $6C, $7B, $6C, $1D, $26, $52, $6C, $7C, $6C

m36_Boss_Room___Gate_of_Peace_X0v0:  ; $6C0B
    ; exits s0v0
    db $82, $FF, $06, $02, $01, $80, $FF, $06, $02, $01, $82, $FF, $08, $02, $02, $80
    db $FF, $08, $02, $02, $82, $FF, $06, $04, $03, $80, $FF, $06, $04, $03, $82, $FF
    db $08, $04, $04, $80, $FF, $08, $04, $04, $8F, $FF, $04, $06, $07
    ; NPC t$00 spr$12 (3,1) scr5
    db $00, $12, $03, $01, $05
    ; NPC t$00 spr$12 (3,2) scr6
    db $00, $12, $03, $02, $06
    ; NPC t$30 spr$02 (3,6) scr7
    db $30, $02, $03, $06, $07
    ; NPC t$20 spr$17 (8,5) scr8
    db $20, $17, $08, $05, $08
    ; NPC t$70 spr$21 (0,2) scr255
    db $70, $21, $00, $02, $FF, $FF

m36_Boss_Room___Gate_of_Peace_X0v1:  ; $6C52
    ; exits s0v1
    db $8F, $FF, $06, $02, $01, $8F, $FF, $08, $02, $02, $8F, $FF, $06, $04, $03, $8F
    db $FF, $08, $04, $04, $8F, $FF, $04, $06, $07
    ; NPC t$00 spr$12 (3,1) scr5
    db $00, $12, $03, $01, $05
    ; NPC t$00 spr$12 (3,2) scr6
    db $00, $12, $03, $02, $06
    ; NPC t$30 spr$02 (3,6) scr7
    db $30, $02, $03, $06, $07, $FF

m36_Boss_Room___Gate_of_Peace_N0v0:  ; $6C7B
    ; npcs s0v0
    db $FF

m36_Boss_Room___Gate_of_Peace_N0v1:  ; $6C7C
    ; npcs s0v1
    db $08, $06
    ; Exit (8,6)->Castle
    db $00, $00, $01, $04, $05, $FF

m37_Boss_Room___Gate_of_Bravery_SP:  ; $6C84
    ; screen_ptrs $37
    db $86, $6C

m37_Boss_Room___Gate_of_Bravery_SB0:  ; $6C86
    ; step_block scr0 ram=0xD97D
    db $7D, $D9, $1B, $25, $94, $6C, $0E, $6D, $1C, $25, $DB, $6C, $0F, $6D

m37_Boss_Room___Gate_of_Bravery_X0v0:  ; $6C94
    ; exits s0v0
    db $90, $FF, $04, $04, $03, $90, $FF, $03, $05, $03, $90, $FF, $03, $06, $03, $90
    db $FF, $06, $04, $04, $90, $FF, $06, $05, $04, $90, $FF, $05, $06, $04, $90, $FF
    db $05, $03, $02
    ; NPC t$40 spr$E0 (5,0) scr255
    db $40, $E0, $05, $00, $FF
    ; NPC t$40 spr$E1 (5,0) scr255
    db $40, $E1, $05, $00, $FF
    ; NPC t$40 spr$E2 (5,0) scr255
    db $40, $E2, $05, $00, $FF
    ; NPC t$40 spr$E3 (5,0) scr255
    db $40, $E3, $05, $00, $FF
    ; NPC t$00 spr$19 (4,1) scr1
    db $00, $19, $04, $01, $01
    ; NPC t$60 spr$15 (4,8) scr255
    db $60, $15, $04, $08, $FF
    ; NPC t$50 spr$21 (10,1) scr255
    db $50, $21, $0A, $01, $FF, $FF

m37_Boss_Room___Gate_of_Bravery_X0v1:  ; $6CDB
    ; exits s0v1
    db $90, $FF, $04, $04, $03, $90, $FF, $03, $05, $03, $90, $FF, $03, $06, $03, $90
    db $FF, $06, $04, $04, $90, $FF, $06, $05, $04, $90, $FF, $05, $06, $04
    ; NPC t$40 spr$E0 (5,0) scr255
    db $40, $E0, $05, $00, $FF
    ; NPC t$40 spr$E1 (5,0) scr255
    db $40, $E1, $05, $00, $FF
    ; NPC t$40 spr$E2 (5,0) scr255
    db $40, $E2, $05, $00, $FF
    ; NPC t$40 spr$E3 (5,0) scr255
    db $40, $E3, $05, $00, $FF, $FF

m37_Boss_Room___Gate_of_Bravery_N0v0:  ; $6D0E
    ; npcs s0v0
    db $FF

m37_Boss_Room___Gate_of_Bravery_N0v1:  ; $6D0F
    ; npcs s0v1
    db $04, $01
    ; Exit (4,1)->Castle
    db $00, $00, $01, $04, $05, $FF

m38_X_SP:  ; $6D17
    ; screen_ptrs $38
    db $19, $6D

m38_X_SB0:  ; $6D19
    ; step_block scr0 ram=0xD97E
    db $7E, $D9, $01, $25, $27, $6D, $F1, $6D, $02, $25, $96, $6D, $F2, $6D

m38_X_X0v0:  ; $6D27
    ; exits s0v0
    db $90, $FF, $04, $00, $02, $90, $FF, $05, $00, $03, $90, $FF, $06, $00, $04, $90
    db $FF, $01, $01, $05, $90, $FF, $05, $02, $06, $90, $FF, $08, $02, $07, $90, $FF
    db $02, $04, $08, $90, $FF, $03, $04, $09, $90, $FF, $04, $04, $0A, $90, $FF, $07
    db $04, $0B, $90, $FF, $08, $04, $0C, $90, $FF, $07, $05, $0D, $90, $FF, $01, $06
    db $0E, $90, $FF, $05, $06, $0F, $90, $FF, $06, $02, $10
    ; NPC t$40 spr$E0 (8,0) scr255
    db $40, $E0, $08, $00, $FF
    ; NPC t$40 spr$E1 (8,0) scr255
    db $40, $E1, $08, $00, $FF
    ; NPC t$40 spr$E2 (8,0) scr255
    db $40, $E2, $08, $00, $FF
    ; NPC t$40 spr$E3 (8,0) scr255
    db $40, $E3, $08, $00, $FF
    ; NPC t$40 spr$39 (2,0) scr255
    db $40, $39, $02, $00, $FF
    ; NPC t$00 spr$1E (8,5) scr1
    db $00, $1E, $08, $05, $01
    ; NPC t$70 spr$21 (0,0) scr255
    db $70, $21, $00, $00, $FF, $FF

m38_X_X0v1:  ; $6D96
    ; exits s0v1
    db $90, $FF, $04, $00, $02, $90, $FF, $05, $00, $03, $90, $FF, $06, $00, $04, $90
    db $FF, $01, $01, $05, $90, $FF, $05, $02, $06, $90, $FF, $08, $02, $07, $90, $FF
    db $02, $04, $08, $90, $FF, $03, $04, $09, $90, $FF, $04, $04, $0A, $90, $FF, $07
    db $04, $0B, $90, $FF, $08, $04, $0C, $90, $FF, $07, $05, $0D, $90, $FF, $01, $06
    db $0E, $90, $FF, $05, $06, $0F
    ; NPC t$40 spr$E0 (8,0) scr255
    db $40, $E0, $08, $00, $FF
    ; NPC t$40 spr$E1 (8,0) scr255
    db $40, $E1, $08, $00, $FF
    ; NPC t$40 spr$E2 (8,0) scr255
    db $40, $E2, $08, $00, $FF
    ; NPC t$40 spr$E3 (8,0) scr255
    db $40, $E3, $08, $00, $FF, $FF

m38_X_N0v0:  ; $6DF1
    ; npcs s0v0
    db $FF

m38_X_N0v1:  ; $6DF2
    ; npcs s0v1
    db $08, $05
    ; Exit (8,5)->Castle
    db $00, $00, $01, $04, $05, $FF

m39_X_SP:  ; $6DFA
    ; screen_ptrs $39
    db $FC, $6D

m39_X_SB0:  ; $6DFC
    ; step_block scr0 ram=0xD97F
    db $7F, $D9, $04, $23, $0A, $6E, $2A, $6E, $05, $23, $24, $6E, $2B, $6E

m39_X_X0v0:  ; $6E0A
    ; exits s0v0
    db $90, $FF, $06, $06, $04, $8F, $FF, $08, $06, $01, $8F, $FF, $07, $04, $02
    ; NPC t$00 spr$2C (1,1) scr3
    db $00, $2C, $01, $01, $03
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF, $FF

m39_X_X0v1:  ; $6E24
    ; exits s0v1
    db $8F, $FF, $07, $04, $02, $FF

m39_X_N0v0:  ; $6E2A
    ; npcs s0v0
    db $FF

m39_X_N0v1:  ; $6E2B
    ; npcs s0v1
    db $07, $06
    ; Exit (7,6)->Castle
    db $00, $00, $01, $04, $05, $FF

m3A_X_SP:  ; $6E33
    ; screen_ptrs $3A
    db $35, $6E

m3A_X_SB0:  ; $6E35
    ; step_block scr0 ram=0xD980
    db $80, $D9, $04, $25, $43, $6E, $35, $6F, $05, $25, $D0, $6E, $36, $6F

m3A_X_X0v0:  ; $6E43
    ; exits s0v0
    db $90, $FF, $02, $02, $02, $90, $FF, $02, $03, $02, $90, $FF, $02, $05, $02, $90
    db $FF, $02, $06, $02, $90, $FF, $04, $02, $02, $90, $FF, $04, $04, $02, $90, $FF
    db $04, $06, $02, $90, $FF, $06, $02, $02, $90, $FF, $06, $03, $02, $90, $FF, $06
    db $05, $02, $90, $FF, $06, $06, $02, $90, $FF, $08, $02, $02, $90, $FF, $08, $03
    db $02, $90, $FF, $08, $04, $02, $90, $FF, $08, $05, $02, $90, $FF, $08, $06, $02
    db $90, $FF, $01, $05, $03, $90, $FF, $02, $04, $04, $90, $FF, $05, $03, $05, $90
    db $FF, $05, $04, $06, $90, $FF, $07, $03, $07, $90, $FF, $07, $05, $08
    ; NPC t$40 spr$E0 (1,0) scr255
    db $40, $E0, $01, $00, $FF
    ; NPC t$40 spr$E1 (1,0) scr255
    db $40, $E1, $01, $00, $FF
    ; NPC t$40 spr$E2 (1,0) scr255
    db $40, $E2, $01, $00, $FF, $40, $E3, $01, $00, $FF, $00, $18, $01, $01, $01, $50
    db $21, $0A, $00, $FF, $FF

m3A_X_X0v1:  ; $6ED0
    ; exits s0v1
    db $90, $FF, $02, $02, $02, $90, $FF, $02, $03, $02, $90, $FF, $02, $05, $02, $90
    db $FF, $02, $06, $02, $90, $FF, $04, $02, $02, $90, $FF, $04, $04, $02, $90, $FF
    db $04, $06, $02, $90, $FF, $06, $02, $02, $90, $FF, $06, $03, $02, $90, $FF, $06
    db $05, $02, $90, $FF, $06, $06, $02, $90, $FF, $08, $02, $02, $90, $FF, $08, $03
    db $02, $90, $FF, $08, $04, $02, $90, $FF, $08, $05, $02, $90, $FF, $08, $06, $02
    ; NPC t$40 spr$E0 (1,0) scr255
    db $40, $E0, $01, $00, $FF
    ; NPC t$40 spr$E1 (1,0) scr255
    db $40, $E1, $01, $00, $FF
    ; NPC t$40 spr$E2 (1,0) scr255
    db $40, $E2, $01, $00, $FF
    ; NPC t$40 spr$E3 (1,0) scr255
    db $40, $E3, $01, $00, $FF, $FF

m3A_X_N0v0:  ; $6F35
    ; npcs s0v0
    db $FF

m3A_X_N0v1:  ; $6F36
    ; npcs s0v1
    db $01, $01
    ; Exit (1,1)->Castle
    db $00, $00, $01, $04, $05, $FF

m3B_X_SP:  ; $6F3E
    ; screen_ptrs $3B
    db $40, $6F

m3B_X_SB0:  ; $6F40
    ; step_block scr0 ram=0xD981
    db $81, $D9, $07, $24, $4E, $6F, $5A, $6F, $08, $24, $59, $6F, $5B, $6F

m3B_X_X0v0:  ; $6F4E
    ; exits s0v0
    ; NPC t$05 spr$1B (3,4) scr1
    db $05, $1B, $03, $04, $01
    ; NPC t$50 spr$21 (10,1) scr255
    db $50, $21, $0A, $01, $FF, $FF

m3B_X_X0v1:  ; $6F59
    ; exits s0v1
    db $FF

m3B_X_N0v0:  ; $6F5A
    ; npcs s0v0
    db $FF

m3B_X_N0v1:  ; $6F5B
    ; npcs s0v1
    db $05, $03
    ; Exit (5,3)->Castle
    db $00, $00, $01, $04, $05, $FF

m3C_X_SP:  ; $6F63
    ; screen_ptrs $3C
    db $65, $6F

m3C_X_SB0:  ; $6F65
    ; step_block scr0 ram=0xD982
    db $82, $D9, $07, $23, $79, $6F, $DA, $6F, $09, $23, $79, $6F, $DB, $6F, $08, $23
    db $B6, $6F, $DB, $6F

m3C_X_X0v0:  ; $6F79
    ; exits s0v0
    ; exits s0v1
    db $8F, $FF, $04, $02, $01, $8F, $FF, $02, $03, $02, $8F, $FF, $01, $04, $03, $8F
    db $FF, $08, $04, $04, $8F, $FF, $06, $05, $05, $8F, $FF, $03, $03, $06, $8F, $FF
    db $07, $04, $07
    ; NPC t$60 spr$15 (2,6) scr255
    db $60, $15, $02, $06, $FF
    ; NPC t$70 spr$21 (0,0) scr255
    db $70, $21, $00, $00, $FF
    ; NPC t$00 spr$23 (5,1) scr8
    db $00, $23, $05, $01, $08
    ; NPC t$00 spr$FF (5,1) scr8
    db $00, $FF, $05, $01, $08
    ; NPC t$00 spr$FF (6,1) scr8
    db $00, $FF, $06, $01, $08, $FF

m3C_X_X0v2:  ; $6FB6
    ; exits s0v2
    db $8F, $FF, $04, $02, $01, $8F, $FF, $02, $03, $02, $8F, $FF, $01, $04, $03, $8F
    db $FF, $08, $04, $04, $8F, $FF, $06, $05, $05, $8F, $FF, $03, $03, $06, $8F, $FF
    db $07, $04, $07, $FF

m3C_X_N0v0:  ; $6FDA
    ; npcs s0v0
    db $FF

m3C_X_N0v1:  ; $6FDB
    ; npcs s0v1
    ; npcs s0v2
    db $06, $01
    ; Exit (6,1)->Castle
    db $00, $00, $01, $04, $05, $FF

m3D_X_SP:  ; $6FE3
    ; screen_ptrs $3D
    db $E5, $6F

m3D_X_SB0:  ; $6FE5
    ; step_block scr0 ram=0xD983
    db $83, $D9, $07, $25, $F3, $6F, $22, $70, $07, $25, $17, $70, $22, $70

m3D_X_X0v0:  ; $6FF3
    ; exits s0v0
    db $90, $FF, $04, $04, $01, $90, $FF, $05, $04, $02
    ; NPC t$40 spr$E1 (4,4) scr255
    db $40, $E1, $04, $04, $FF
    ; NPC t$40 spr$5F (4,2) scr255
    db $40, $5F, $04, $02, $FF
    ; NPC t$40 spr$05 (4,2) scr255
    db $40, $05, $04, $02, $FF
    ; NPC t$40 spr$39 (0,0) scr255
    db $40, $39, $00, $00, $FF
    ; NPC t$60 spr$E0 (5,4) scr255
    db $60, $E0, $05, $04, $FF, $FF

m3D_X_X0v1:  ; $7017
    ; exits s0v1
    db $90, $FF, $04, $04, $03, $90, $FF, $05, $04, $03, $FF

m3D_X_N0v0:  ; $7022
    ; npcs s0v0
    ; npcs s0v1
    db $FF

m3E_X_SP:  ; $7023
    ; screen_ptrs $3E
    db $25, $70

m3E_X_SB0:  ; $7025
    ; step_block scr0 ram=0xD984
    db $84, $D9, $09, $25, $33, $70, $49, $70, $0A, $25, $48, $70, $4A, $70

m3E_X_X0v0:  ; $7033
    ; exits s0v0
    ; NPC t$50 spr$21 (10,1) scr255
    db $50, $21, $0A, $01, $FF
    ; NPC t$00 spr$28 (4,5) scr1
    db $00, $28, $04, $05, $01
    ; NPC t$00 spr$FF (4,4) scr1
    db $00, $FF, $04, $04, $01
    ; NPC t$00 spr$FF (5,4) scr1
    db $00, $FF, $05, $04, $01, $FF

m3E_X_X0v1:  ; $7048
    ; exits s0v1
    db $FF

m3E_X_N0v0:  ; $7049
    ; npcs s0v0
    db $FF

m3E_X_N0v1:  ; $704A
    ; npcs s0v1
    db $01, $03
    ; Exit (1,3)->Castle
    db $00, $00, $01, $04, $05, $FF

m3F_X_SP:  ; $7052
    ; screen_ptrs $3F
    db $54, $70

m3F_X_SB0:  ; $7054
    ; step_block scr0 ram=0xD985
    db $85, $D9, $01, $24, $62, $70, $6E, $70, $02, $24, $6D, $70, $6F, $70

m3F_X_X0v0:  ; $7062
    ; exits s0v0
    ; NPC t$00 spr$2B (1,5) scr1
    db $00, $2B, $01, $05, $01
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF, $FF

m3F_X_X0v1:  ; $706D
    ; exits s0v1
    db $FF

m3F_X_N0v0:  ; $706E
    ; npcs s0v0
    db $FF

m3F_X_N0v1:  ; $706F
    ; npcs s0v1
    db $01, $05
    ; Exit (1,5)->Castle
    db $00, $00, $01, $04, $05, $FF

m40_X_SP:  ; $7077
    ; screen_ptrs $40
    db $79, $70

m40_X_SB0:  ; $7079
    ; step_block scr0 ram=0xD986
    db $86, $D9, $16, $25, $81, $70, $B9, $70

m40_X_X0v0:  ; $7081
    ; exits s0v0
    db $90, $FF, $01, $01, $06, $90, $FF, $02, $01, $06, $90, $FF, $04, $01, $07, $90
    db $FF, $05, $01, $07, $90, $FF, $07, $01, $08, $90, $FF, $08, $01, $08, $8F, $FF
    db $03, $03, $01, $8F, $FF, $06, $03, $02
    ; NPC t$00 spr$05 (2,2) scr3
    db $00, $05, $02, $02, $03
    ; NPC t$00 spr$05 (5,2) scr4
    db $00, $05, $05, $02, $04
    ; NPC t$00 spr$05 (8,2) scr5
    db $00, $05, $08, $02, $05, $FF

m40_X_N0v0:  ; $70B9
    ; npcs s0v0
    db $01, $01
    ; Exit (1,1)->Boss_Medal_Lipsy
    db $41, $00, $00, $01, $06, $02, $01
    ; Exit (2,1)->Boss_Medal_Lipsy
    db $41, $00, $00, $02, $06, $04, $01
    ; Exit (4,1)->Boss_Medal_Lipsy
    db $41, $00, $00, $04, $06, $05, $01
    ; Exit (5,1)->Boss_Medal_Lipsy
    db $41, $00, $00, $05, $06, $07, $01
    ; Exit (7,1)->Boss_Medal_Lipsy
    db $41, $00, $00, $07, $06, $08, $01
    ; Exit (8,1)->Boss_Medal_Lipsy
    db $41, $00, $00, $08, $06, $FF

m41_X_SP:  ; $70E4
    ; screen_ptrs $41
    db $E6, $70

m41_X_SB0:  ; $70E6
    ; step_block scr0 ram=0xD987
    db $87, $D9, $18, $25, $00, $71, $2B, $71, $18, $25, $0B, $71, $2B, $71, $18, $25
    db $20, $71, $2B, $71, $19, $25, $42, $4B, $2C, $71

m41_X_X0v0:  ; $7100
    ; exits s0v0
    ; NPC t$00 spr$1C (1,4) scr1
    db $00, $1C, $01, $04, $01
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF, $FF

m41_X_X0v1:  ; $710B
    ; exits s0v1
    ; NPC t$00 spr$22 (4,3) scr2
    db $00, $22, $04, $03, $02
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF
    ; NPC t$00 spr$FF (4,3) scr2
    db $00, $FF, $04, $03, $02
    ; NPC t$00 spr$FF (5,3) scr2
    db $00, $FF, $05, $03, $02, $FF

m41_X_X0v2:  ; $7120
    ; exits s0v2
    ; NPC t$00 spr$3E (7,4) scr3
    db $00, $3E, $07, $04, $03
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF, $FF

m41_X_N0v0:  ; $712B
    ; npcs s0v0
    ; npcs s0v1
    ; npcs s0v2
    db $FF

m41_X_N0v3:  ; $712C
    ; npcs s0v3
    db $01, $02
    ; Exit (1,2)->Castle
    db $00, $00, $01, $04, $05, $04, $02
    ; Exit (4,2)->Castle
    db $00, $00, $01, $04, $05, $07, $02
    ; Exit (7,2)->Castle
    db $00, $00, $01, $04, $05, $FF

m42_Labyrinth_SP:  ; $7142
    ; screen_ptrs $42
    db $46, $71

m60_Labyrinth_Final_Room_SP:  ; $7144
    ; screen_ptrs $60
    db $84, $71

m42_Labyrinth_SB0:  ; $7146
    ; step_block scr0 ram=0xD988
    db $88, $D9, $13, $24, $92, $71, $BE, $73, $13, $24, $C0, $71, $7E, $73, $13, $24
    db $EE, $71, $7E, $73, $13, $24, $1C, $72, $FE, $73, $13, $24, $4A, $72, $7E, $73
    db $13, $24, $78, $72, $3E, $74, $13, $24, $A6, $72, $7E, $73, $13, $24, $D4, $72
    db $7E, $73, $13, $24, $02, $73, $7E, $73, $13, $24, $30, $73, $7E, $74

m42_Labyrinth_SB1:  ; $7184
    ; step_block scr1 ram=0xD989
    ; step_block scr0 ram=0xD989
    db $89, $D9, $14, $24, $5E, $73, $BE, $74, $14, $24, $73, $73, $BE, $74

m42_Labyrinth_X0v0:  ; $7192
    ; exits s0v0
    db $90, $FF, $04, $04, $0F, $90, $FF, $02, $07, $01, $90, $FF, $07, $07, $01, $90
    db $FF, $09, $02, $0F, $90, $FF, $09, $05, $0F, $90, $FF, $02, $00, $04, $90, $FF
    db $07, $00, $04, $90, $FF, $00, $02, $0F, $90, $FF, $00, $05, $0F, $FF

m42_Labyrinth_X0v1:  ; $71C0
    ; exits s0v1
    db $90, $FF, $04, $04, $0F, $90, $FF, $02, $07, $02, $90, $FF, $07, $07, $02, $90
    db $FF, $09, $02, $0F, $90, $FF, $09, $05, $0F, $90, $FF, $02, $00, $0F, $90, $FF
    db $07, $00, $0F, $90, $FF, $00, $02, $0F, $90, $FF, $00, $05, $0F, $FF

m42_Labyrinth_X0v2:  ; $71EE
    ; exits s0v2
    db $90, $FF, $04, $04, $0F, $90, $FF, $02, $07, $03, $90, $FF, $07, $07, $03, $90
    db $FF, $09, $02, $0F, $90, $FF, $09, $05, $0F, $90, $FF, $02, $00, $0F, $90, $FF
    db $07, $00, $0F, $90, $FF, $00, $02, $0F, $90, $FF, $00, $05, $0F, $FF

m42_Labyrinth_X0v3:  ; $721C
    ; exits s0v3
    db $90, $FF, $04, $04, $0F, $90, $FF, $02, $07, $0F, $90, $FF, $07, $07, $0F, $90
    db $FF, $09, $02, $0F, $90, $FF, $09, $05, $03, $90, $FF, $02, $00, $0F, $90, $FF
    db $07, $00, $0F, $90, $FF, $00, $02, $0F, $90, $FF, $00, $05, $0F, $FF

m42_Labyrinth_X0v4:  ; $724A
    ; exits s0v4
    db $90, $FF, $04, $04, $0F, $90, $FF, $02, $07, $0F, $90, $FF, $07, $07, $0F, $90
    db $FF, $09, $02, $0F, $90, $FF, $09, $05, $0F, $90, $FF, $02, $00, $05, $90, $FF
    db $07, $00, $05, $90, $FF, $00, $02, $0F, $90, $FF, $00, $05, $0F, $FF

m42_Labyrinth_X0v5:  ; $7278
    ; exits s0v5
    db $90, $FF, $04, $04, $0F, $90, $FF, $02, $07, $0F, $90, $FF, $07, $07, $0F, $90
    db $FF, $09, $02, $0F, $90, $FF, $09, $05, $0F, $90, $FF, $02, $00, $06, $90, $FF
    db $07, $00, $06, $90, $FF, $00, $02, $0F, $90, $FF, $00, $05, $05, $FF

m42_Labyrinth_X0v6:  ; $72A6
    ; exits s0v6
    db $90, $FF, $04, $04, $0F, $90, $FF, $02, $07, $0F, $90, $FF, $07, $07, $0F, $90
    db $FF, $09, $02, $0F, $90, $FF, $09, $05, $0F, $90, $FF, $02, $00, $0F, $90, $FF
    db $07, $00, $0F, $90, $FF, $00, $02, $07, $90, $FF, $00, $05, $07, $FF

m42_Labyrinth_X0v7:  ; $72D4
    ; exits s0v7
    db $90, $FF, $04, $04, $0F, $90, $FF, $02, $07, $08, $90, $FF, $07, $07, $08, $90
    db $FF, $09, $02, $0F, $90, $FF, $09, $05, $0F, $90, $FF, $02, $00, $0F, $90, $FF
    db $07, $00, $0F, $90, $FF, $00, $02, $0F, $90, $FF, $00, $05, $0F, $FF

m42_Labyrinth_X0v8:  ; $7302
    ; exits s0v8
    db $90, $FF, $04, $04, $0F, $90, $FF, $02, $07, $09, $90, $FF, $07, $07, $09, $90
    db $FF, $09, $02, $0F, $90, $FF, $09, $05, $0F, $90, $FF, $02, $00, $0F, $90, $FF
    db $07, $00, $0F, $90, $FF, $00, $02, $0F, $90, $FF, $00, $05, $0F, $FF

m42_Labyrinth_X0v9:  ; $7330
    ; exits s0v9
    db $90, $FF, $04, $04, $0F, $90, $FF, $02, $07, $0F, $90, $FF, $07, $07, $0F, $90
    db $FF, $09, $02, $0F, $90, $FF, $09, $05, $0F, $90, $FF, $02, $00, $0F, $90, $FF
    db $07, $00, $0F, $90, $FF, $00, $02, $09, $90, $FF, $00, $05, $0F, $FF

m42_Labyrinth_X1v0:  ; $735E
    ; exits s1v0
    ; exits s0v0
    db $8F, $FF, $03, $02, $10, $8F, $FF, $03, $05, $12
    ; NPC t$00 spr$1A (6,2) scr17
    db $00, $1A, $06, $02, $11
    ; NPC t$70 spr$21 (0,1) scr255
    db $70, $21, $00, $01, $FF, $FF

m42_Labyrinth_X1v1:  ; $7373
    ; exits s1v1
    ; exits s0v1
    db $8F, $FF, $03, $02, $10, $8F, $FF, $03, $05, $12, $FF

m42_Labyrinth_N0v1:  ; $737E
    ; npcs s0v1
    ; npcs s0v2
    ; npcs s0v4
    db $05, $05
    ; Exit (5,5)->Castle
    db $00, $00, $01, $04, $05, $02, $00
    ; Exit (2,0)->Labyrinth
    db $42, $00, $00, $02, $07, $07, $00
    ; Exit (7,0)->Labyrinth
    db $42, $00, $00, $07, $07, $00, $02
    ; Exit (0,2)->Labyrinth
    db $42, $00, $00, $09, $02, $00, $05
    ; Exit (0,5)->Labyrinth
    db $42, $00, $00, $09, $05, $02, $07
    ; Exit (2,7)->Labyrinth
    db $42, $00, $00, $02, $00, $07, $07
    ; Exit (7,7)->Labyrinth
    db $42, $00, $00, $07, $00, $09, $02
    ; Exit (9,2)->Labyrinth
    db $42, $00, $00, $00, $02, $09, $05
    ; Exit (9,5)->Labyrinth
    db $42, $00, $00, $00, $05, $FF

m42_Labyrinth_N0v0:  ; $73BE
    ; npcs s0v0
    db $05, $05
    ; Exit (5,5)->Castle
    db $00, $00, $01, $04, $05, $02, $00
    ; Exit (2,0)->Labyrinth
    db $42, $00, $00, $02, $07, $07, $00
    ; Exit (7,0)->Labyrinth
    db $42, $00, $00, $07, $07, $00, $02
    ; Exit (0,2)->Labyrinth
    db $42, $00, $00, $09, $02, $00, $05
    ; Exit (0,5)->Labyrinth
    db $42, $00, $00, $09, $05, $02, $07
    ; Exit (2,7)->Labyrinth
    db $42, $00, $00, $02, $00, $07, $07
    ; Exit (7,7)->Labyrinth
    db $42, $00, $00, $07, $00, $09, $02
    ; Exit (9,2)->Map_60
    db $60, $00, $00, $00, $02, $09, $05
    ; Exit (9,5)->Labyrinth
    db $42, $00, $00, $00, $05, $FF

m42_Labyrinth_N0v3:  ; $73FE
    ; npcs s0v3
    db $05, $05
    ; Exit (5,5)->Castle
    db $00, $00, $01, $04, $05, $02, $00
    ; Exit (2,0)->Labyrinth
    db $42, $00, $00, $02, $07, $07, $00
    ; Exit (7,0)->Labyrinth
    db $42, $00, $00, $07, $07, $00, $02
    ; Exit (0,2)->Labyrinth
    db $42, $00, $00, $09, $02, $00, $05
    ; Exit (0,5)->Labyrinth
    db $42, $00, $00, $09, $05, $02, $07
    ; Exit (2,7)->Labyrinth
    db $42, $00, $00, $02, $00, $07, $07
    ; Exit (7,7)->Labyrinth
    db $42, $00, $00, $07, $00, $09, $02
    ; Exit (9,2)->Labyrinth
    db $42, $00, $00, $00, $02, $09, $05
    ; Exit (9,5)->Map_60
    db $60, $00, $00, $00, $05, $FF

m42_Labyrinth_N0v5:  ; $743E
    ; npcs s0v5
    db $05, $05
    ; Exit (5,5)->Castle
    db $00, $00, $01, $04, $05, $02, $00
    ; Exit (2,0)->Labyrinth
    db $42, $00, $00, $02, $07, $07, $00
    ; Exit (7,0)->Labyrinth
    db $42, $00, $00, $07, $07, $00, $02
    ; Exit (0,2)->Labyrinth
    db $42, $00, $00, $09, $02, $00, $05
    ; Exit (0,5)->Map_60
    db $60, $00, $00, $09, $05, $02, $07
    ; Exit (2,7)->Labyrinth
    db $42, $00, $00, $02, $00, $07, $07
    ; Exit (7,7)->Labyrinth
    db $42, $00, $00, $07, $00, $09, $02
    ; Exit (9,2)->Labyrinth
    db $42, $00, $00, $00, $02, $09, $05
    ; Exit (9,5)->Labyrinth
    db $42, $00, $00, $00, $05, $FF

m42_Labyrinth_N0v9:  ; $747E
    ; npcs s0v9
    db $05, $05
    ; Exit (5,5)->Castle
    db $00, $00, $01, $04, $05, $02, $00
    ; Exit (2,0)->Labyrinth
    db $42, $00, $00, $02, $07, $07, $00
    ; Exit (7,0)->Labyrinth
    db $42, $00, $00, $07, $07, $00, $02
    ; Exit (0,2)->Map_60
    db $60, $00, $00, $09, $02, $00, $05
    ; Exit (0,5)->Labyrinth
    db $42, $00, $00, $09, $05, $02, $07
    ; Exit (2,7)->Labyrinth
    db $42, $00, $00, $02, $00, $07, $07
    ; Exit (7,7)->Labyrinth
    db $42, $00, $00, $07, $00, $09, $02
    ; Exit (9,2)->Labyrinth
    db $42, $00, $00, $00, $02, $09, $05
    ; Exit (9,5)->Labyrinth
    db $42, $00, $00, $00, $05, $FF

m42_Labyrinth_N1v0:  ; $74BE
    ; npcs s1v0
    ; npcs s1v1
    ; npcs s0v0
    db $00, $02
    ; Exit (0,2)->Labyrinth
    db $42, $00, $00, $09, $02, $00, $05
    ; Exit (0,5)->Labyrinth
    db $42, $00, $00, $09, $05, $09, $02
    ; Exit (9,2)->Labyrinth
    db $42, $00, $00, $00, $02, $09, $05
    ; Exit (9,5)->Labyrinth
    db $42, $00, $00, $00, $05, $FF

m43_X_SP:  ; $74DB
    ; screen_ptrs $43
    db $DD, $74

m43_X_SB0:  ; $74DD
    ; step_block scr0 ram=0xD98A
    db $8A, $D9, $10, $24, $EB, $74, $15, $75, $11, $24, $0A, $75, $16, $75

m43_X_X0v0:  ; $74EB
    ; exits s0v0
    db $82, $FF, $07, $05, $01, $82, $FF, $08, $05, $01
    ; NPC t$50 spr$21 (10,1) scr255
    db $50, $21, $0A, $01, $FF
    ; NPC t$06 spr$27 (4,2) scr2
    db $06, $27, $04, $02, $02
    ; NPC t$00 spr$FF (4,2) scr2
    db $00, $FF, $04, $02, $02
    ; NPC t$00 spr$FF (5,2) scr2
    db $00, $FF, $05, $02, $02, $FF

m43_X_X0v1:  ; $750A
    ; exits s0v1
    db $82, $FF, $07, $05, $01, $82, $FF, $08, $05, $01, $FF

m43_X_N0v0:  ; $7515
    ; npcs s0v0
    db $FF

m43_X_N0v1:  ; $7516
    ; npcs s0v1
    db $02, $05
    ; Exit (2,5)->Castle
    db $00, $00, $01, $04, $05, $FF

m44_X_SP:  ; $751E
    ; screen_ptrs $44
    db $20, $75

m44_X_SB0:  ; $7520
    ; step_block scr0 ram=0xD98B
    db $8B, $D9, $19, $24, $2E, $75, $58, $75, $1A, $24, $57, $75, $59, $75

m44_X_X0v0:  ; $752E
    ; exits s0v0
    ; NPC t$60 spr$15 (0,7) scr2
    db $60, $15, $00, $07, $02
    ; NPC t$50 spr$21 (10,1) scr255
    db $50, $21, $0A, $01, $FF
    ; NPC t$00 spr$24 (5,2) scr1
    db $00, $24, $05, $02, $01
    ; NPC t$60 spr$E0 (5,3) scr255
    db $60, $E0, $05, $03, $FF
    ; NPC t$60 spr$E1 (5,4) scr255
    db $60, $E1, $05, $04, $FF
    ; NPC t$60 spr$E2 (5,4) scr255
    db $60, $E2, $05, $04, $FF
    ; NPC t$60 spr$E3 (5,4) scr255
    db $60, $E3, $05, $04, $FF
    ; NPC t$00 spr$FF (6,2) scr1
    db $00, $FF, $06, $02, $01, $FF

m44_X_X0v1:  ; $7557
    ; exits s0v1
    db $FF

m44_X_N0v0:  ; $7558
    ; npcs s0v0
    db $FF

m44_X_N0v1:  ; $7559
    ; npcs s0v1
    db $06, $01
    ; Exit (6,1)->Castle
    db $00, $00, $01, $04, $05, $FF

m45_X_SP:  ; $7561
    ; screen_ptrs $45
    db $63, $75

m45_X_SB0:  ; $7563
    ; step_block scr0 ram=0xD98C
    db $8C, $D9, $0A, $24, $77, $75, $C0, $75, $0B, $24, $BF, $75, $C1, $75, $0A, $24
    db $9B, $75, $C0, $75

m45_X_X0v0:  ; $7577
    ; exits s0v0
    ; NPC t$20 spr$E0 (4,7) scr255
    db $20, $E0, $04, $07, $FF
    ; NPC t$40 spr$2B (4,6) scr255
    db $40, $2B, $04, $06, $FF
    ; NPC t$40 spr$2B (5,6) scr255
    db $40, $2B, $05, $06, $FF
    ; NPC t$40 spr$15 (4,6) scr255
    db $40, $15, $04, $06, $FF
    ; NPC t$40 spr$39 (4,0) scr255
    db $40, $39, $04, $00, $FF
    ; NPC t$50 spr$21 (10,1) scr255
    db $50, $21, $0A, $01, $FF
    ; NPC t$00 spr$29 (4,5) scr255
    db $00, $29, $04, $05, $FF, $FF

m45_X_X0v2:  ; $759B
    ; exits s0v2
    ; NPC t$20 spr$E0 (4,7) scr255
    db $20, $E0, $04, $07, $FF
    ; NPC t$40 spr$2B (4,6) scr255
    db $40, $2B, $04, $06, $FF
    ; NPC t$40 spr$2B (5,6) scr255
    db $40, $2B, $05, $06, $FF
    ; NPC t$20 spr$15 (3,4) scr255
    db $20, $15, $03, $04, $FF
    ; NPC t$40 spr$39 (4,0) scr255
    db $40, $39, $04, $00, $FF
    ; NPC t$50 spr$21 (10,1) scr255
    db $50, $21, $0A, $01, $FF
    ; NPC t$00 spr$29 (4,5) scr255
    db $00, $29, $04, $05, $FF, $FF

m45_X_X0v1:  ; $75BF
    ; exits s0v1
    db $FF

m45_X_N0v0:  ; $75C0
    ; npcs s0v0
    ; npcs s0v2
    db $FF

m45_X_N0v1:  ; $75C1
    ; npcs s0v1
    db $05, $05
    ; Exit (5,5)->Castle
    db $00, $00, $01, $04, $05, $FF

m46_Boss_Room___Gate_of_Ambition_SP:  ; $75C9
    ; screen_ptrs $46
    db $CB, $75

m46_Boss_Room___Gate_of_Ambition_SB0:  ; $75CB
    ; step_block scr0 ram=0xD98D
    db $8D, $D9, $01, $23, $D9, $75, $EF, $75, $02, $23, $EE, $75, $F0, $75

m46_Boss_Room___Gate_of_Ambition_X0v0:  ; $75D9
    ; exits s0v0
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF
    ; NPC t$00 spr$2D (4,3) scr1
    db $00, $2D, $04, $03, $01
    ; NPC t$00 spr$FF (4,3) scr1
    db $00, $FF, $04, $03, $01
    ; NPC t$00 spr$FF (5,3) scr1
    db $00, $FF, $05, $03, $01, $FF

m46_Boss_Room___Gate_of_Ambition_X0v1:  ; $75EE
    ; exits s0v1
    db $FF

m46_Boss_Room___Gate_of_Ambition_N0v0:  ; $75EF
    ; npcs s0v0
    db $FF

m46_Boss_Room___Gate_of_Ambition_N0v1:  ; $75F0
    ; npcs s0v1
    db $02, $04
    ; Exit (2,4)->Castle
    db $00, $00, $01, $04, $05, $FF

m47_X_SP:  ; $75F8
    ; screen_ptrs $47
    db $FA, $75

m47_X_SB0:  ; $75FA
    ; step_block scr0 ram=0xD98E
    db $8E, $D9, $1C, $24, $0E, $76, $39, $76, $1C, $24, $23, $76, $3A, $76, $1D, $24
    db $38, $76, $3B, $76

m47_X_X0v0:  ; $760E
    ; exits s0v0
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF
    ; NPC t$00 spr$2E (4,3) scr1
    db $00, $2E, $04, $03, $01
    ; NPC t$00 spr$FF (5,3) scr1
    db $00, $FF, $05, $03, $01
    ; NPC t$00 spr$FF (4,3) scr1
    db $00, $FF, $04, $03, $01, $FF

m47_X_X0v1:  ; $7623
    ; exits s0v1
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF
    ; NPC t$00 spr$2F (4,3) scr2
    db $00, $2F, $04, $03, $02
    ; NPC t$00 spr$FF (5,3) scr2
    db $00, $FF, $05, $03, $02
    ; NPC t$00 spr$FF (4,3) scr2
    db $00, $FF, $04, $03, $02, $FF

m47_X_X0v2:  ; $7638
    ; exits s0v2
    db $FF

m47_X_N0v0:  ; $7639
    ; npcs s0v0
    db $FF

m47_X_N0v1:  ; $763A
    ; npcs s0v1
    db $FF

m47_X_N0v2:  ; $763B
    ; npcs s0v2
    db $03, $04
    ; Exit (3,4)->Castle
    db $00, $00, $01, $04, $05, $FF

m48_X_SP:  ; $7643
    ; screen_ptrs $48
    db $45, $76

m48_X_SB0:  ; $7645
    ; step_block scr0 ram=0xD98F
    db $8F, $D9, $0D, $24, $53, $76, $69, $76, $0E, $24, $68, $76, $6A, $76

m48_X_X0v0:  ; $7653
    ; exits s0v0
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF
    ; NPC t$00 spr$30 (4,1) scr1
    db $00, $30, $04, $01, $01
    ; NPC t$00 spr$FF (4,1) scr1
    db $00, $FF, $04, $01, $01
    ; NPC t$00 spr$FF (5,1) scr1
    db $00, $FF, $05, $01, $01, $FF

m48_X_X0v1:  ; $7668
    ; exits s0v1
    db $FF

m48_X_N0v0:  ; $7669
    ; npcs s0v0
    db $FF

m48_X_N0v1:  ; $766A
    ; npcs s0v1
    db $04, $01
    ; Exit (4,1)->Castle
    db $00, $00, $01, $04, $05, $FF

m49_X_SP:  ; $7672
    ; screen_ptrs $49
    db $74, $76

m49_X_SB0:  ; $7674
    ; step_block scr0 ram=0xD990
    db $90, $D9, $0C, $25, $82, $76, $98, $76, $0D, $25, $97, $76, $99, $76

m49_X_X0v0:  ; $7682
    ; exits s0v0
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF
    ; NPC t$00 spr$31 (4,2) scr1
    db $00, $31, $04, $02, $01
    ; NPC t$00 spr$FF (4,2) scr1
    db $00, $FF, $04, $02, $01
    ; NPC t$00 spr$FF (5,2) scr1
    db $00, $FF, $05, $02, $01, $FF

m49_X_X0v1:  ; $7697
    ; exits s0v1
    db $FF

m49_X_N0v0:  ; $7698
    ; npcs s0v0
    db $FF

m49_X_N0v1:  ; $7699
    ; npcs s0v1
    db $02, $04
    ; Exit (2,4)->Castle
    db $00, $00, $01, $04, $05, $FF

m4A_X_SP:  ; $76A1
    ; screen_ptrs $4A
    db $A3, $76

m4A_X_SB0:  ; $76A3
    ; step_block scr0 ram=0xD991
    db $91, $D9, $0B, $23, $B1, $76, $C7, $76, $0C, $23, $C6, $76, $C8, $76

m4A_X_X0v0:  ; $76B1
    ; exits s0v0
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF
    ; NPC t$00 spr$32 (4,1) scr1
    db $00, $32, $04, $01, $01
    ; NPC t$00 spr$FF (4,1) scr1
    db $00, $FF, $04, $01, $01
    ; NPC t$00 spr$FF (5,1) scr1
    db $00, $FF, $05, $01, $01, $FF

m4A_X_X0v1:  ; $76C6
    ; exits s0v1
    db $FF

m4A_X_N0v0:  ; $76C7
    ; npcs s0v0
    db $FF

m4A_X_N0v1:  ; $76C8
    ; npcs s0v1
    db $05, $03
    ; Exit (5,3)->Castle
    db $00, $00, $01, $04, $05, $FF

m4B_X_SP:  ; $76D0
    ; screen_ptrs $4B
    db $D2, $76

m4B_X_SB0:  ; $76D2
    ; step_block scr0 ram=0xD992
    db $92, $D9, $0E, $23, $E0, $76, $F6, $76, $0F, $23, $F5, $76, $F7, $76

m4B_X_X0v0:  ; $76E0
    ; exits s0v0
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF
    ; NPC t$00 spr$33 (4,1) scr1
    db $00, $33, $04, $01, $01
    ; NPC t$00 spr$FF (4,1) scr1
    db $00, $FF, $04, $01, $01
    ; NPC t$00 spr$FF (5,1) scr1
    db $00, $FF, $05, $01, $01, $FF

m4B_X_X0v1:  ; $76F5
    ; exits s0v1
    db $FF

m4B_X_N0v0:  ; $76F6
    ; npcs s0v0
    db $FF

m4B_X_N0v1:  ; $76F7
    ; npcs s0v1
    db $04, $03
    ; Exit (4,3)->Castle
    db $00, $00, $01, $04, $05, $FF

m4C_X_SP:  ; $76FF
    ; screen_ptrs $4C
    db $01, $77

m4C_X_SB0:  ; $7701
    ; step_block scr0 ram=0xD993
    db $93, $D9, $11, $23, $0F, $77, $25, $77, $12, $23, $24, $77, $26, $77

m4C_X_X0v0:  ; $770F
    ; exits s0v0
    ; NPC t$50 spr$21 (10,2) scr255
    db $50, $21, $0A, $02, $FF
    ; NPC t$00 spr$34 (4,2) scr1
    db $00, $34, $04, $02, $01
    ; NPC t$00 spr$FF (4,3) scr1
    db $00, $FF, $04, $03, $01
    ; NPC t$00 spr$FF (5,3) scr1
    db $00, $FF, $05, $03, $01, $FF

m4C_X_X0v1:  ; $7724
    ; exits s0v1
    db $FF

m4C_X_N0v0:  ; $7725
    ; npcs s0v0
    db $FF

m4C_X_N0v1:  ; $7726
    ; npcs s0v1
    db $04, $04
    ; Exit (4,4)->Castle
    db $00, $00, $01, $04, $05, $FF

m4D_Boss_Room___Arena_Right_Gate_SP:  ; $772E
    ; screen_ptrs $4D
    db $30, $77

m4D_Boss_Room___Arena_Right_Gate_SB0:  ; $7730
    ; step_block scr0 ram=0xD994
    db $94, $D9, $0F, $25, $3E, $77, $54, $77, $10, $25, $53, $77, $55, $77

m4D_Boss_Room___Arena_Right_Gate_X0v0:  ; $773E
    ; exits s0v0
    ; NPC t$50 spr$21 (10,0) scr255
    db $50, $21, $0A, $00, $FF
    ; NPC t$00 spr$35 (4,1) scr1
    db $00, $35, $04, $01, $01
    ; NPC t$00 spr$FF (4,1) scr1
    db $00, $FF, $04, $01, $01
    ; NPC t$00 spr$FF (5,1) scr1
    db $00, $FF, $05, $01, $01, $FF

m4D_Boss_Room___Arena_Right_Gate_X0v1:  ; $7753
    ; exits s0v1
    db $FF

m4D_Boss_Room___Arena_Right_Gate_N0v0:  ; $7754
    ; npcs s0v0
    db $FF

m4D_Boss_Room___Arena_Right_Gate_N0v1:  ; $7755
    ; npcs s0v1
    db $03, $03
    ; Exit (3,3)->Castle
    db $00, $00, $01, $04, $05, $FF

m4E_X_SP:  ; $775D
    ; screen_ptrs $4E
    db $6D, $77, $FF, $FF, $FF, $FF, $FF, $FF, $7B, $77, $FF, $FF, $FF, $FF, $FF, $FF

m4E_X_SB0:  ; $776D
    ; step_block scr0 ram=0xD995
    db $95, $D9, $12, $25, $83, $77, $9F, $77, $13, $25, $9D, $77, $A0, $77, $96, $D9
    db $14, $25, $9E, $77, $A8, $77

m4E_X_X0v0:  ; $7783
    ; exits s0v0
    ; NPC t$50 spr$21 (10,1) scr255
    db $50, $21, $0A, $01, $FF
    ; NPC t$0A spr$36 (4,2) scr1
    db $0A, $36, $04, $02, $01
    ; NPC t$00 spr$FF (3,3) scr1
    db $00, $FF, $03, $03, $01
    ; NPC t$00 spr$FF (4,3) scr1
    db $00, $FF, $04, $03, $01
    ; NPC t$00 spr$FF (5,3) scr1
    db $00, $FF, $05, $03, $01, $FF

m4E_X_X0v1:  ; $779D
    ; exits s0v1
    db $FF, $FF

m4E_X_N0v0:  ; $779F
    ; npcs s0v0
    db $FF

m4E_X_N0v1:  ; $77A0
    ; npcs s0v1
    db $04, $04
    ; Exit (4,4)->Castle
    db $00, $00, $01, $04, $05, $FF, $FF

m4F_Boss_Room___Unused_Gate_SP:  ; $77A9
    ; screen_ptrs $4F
    db $AB, $77

m4F_Boss_Room___Unused_Gate_SB0:  ; $77AB
    ; step_block scr0 ram=0xD997
    db $97, $D9, $04, $24, $B9, $77, $D4, $77, $05, $24, $D3, $77, $D5, $77

m4F_Boss_Room___Unused_Gate_X0v0:  ; $77B9
    ; exits s0v0
    db $90, $FF, $04, $04, $01, $90, $FF, $05, $04, $01
    ; NPC t$40 spr$37 (4,3) scr2
    db $40, $37, $04, $03, $02
    ; NPC t$40 spr$FF (4,3) scr2
    db $40, $FF, $04, $03, $02
    ; NPC t$40 spr$FF (5,3) scr2
    db $40, $FF, $05, $03, $02, $FF

m4F_Boss_Room___Unused_Gate_X0v1:  ; $77D3
    ; exits s0v1
    db $FF

m4F_Boss_Room___Unused_Gate_N0v0:  ; $77D4
    ; npcs s0v0
    db $FF

m4F_Boss_Room___Unused_Gate_N0v1:  ; $77D5
    ; npcs s0v1
    db $03, $05
    ; Exit (3,5)->Castle
    db $00, $00, $01, $04, $05, $FF

m50_X_SP:  ; $77DD
    ; screen_ptrs $50
    ; screen_ptrs $5F
    db $DF, $77

m50_X_SB0:  ; $77DF
    ; step_block scr0 ram=0xD998
    ; step_block scr0 ram=0xD998
    db $98, $D9, $01, $26, $E7, $77, $F2, $77

m50_X_X0v0:  ; $77E7
    ; exits s0v0
    ; exits s0v0
    db $8F, $FF, $04, $03, $01
    ; NPC t$00 spr$06 (4,2) scr1
    db $00, $06, $04, $02, $01, $FF

m50_X_N0v0:  ; $77F2
    ; npcs s0v0
    ; npcs s0v0
    db $01, $06, $00, $80, $00, $00, $00, $FF

m51_X_SP:  ; $77FA
    ; screen_ptrs $51
    db $FC, $77

m51_X_SB0:  ; $77FC
    ; step_block scr0 ram=0xD998
    db $98, $D9, $03, $26, $04, $78, $0F, $78

m51_X_X0v0:  ; $7804
    ; exits s0v0
    db $82, $FF, $04, $03, $02
    ; NPC t$00 spr$11 (4,2) scr1
    db $00, $11, $04, $02, $01, $FF

m51_X_N0v0:  ; $780F
    ; npcs s0v0
    db $08, $02, $00, $80, $00, $00, $00, $FF

m52_Special___Coliseum_SP:  ; $7817
    ; screen_ptrs $52
    db $19, $78

m52_Special___Coliseum_SB0:  ; $7819
    ; step_block scr0 ram=0xD998
    db $98, $D9, $05, $26, $21, $78, $4A, $78

m52_Special___Coliseum_X0v0:  ; $7821
    ; exits s0v0
    ; NPC t$00 spr$0B (4,3) scr255
    db $00, $0B, $04, $03, $FF
    ; NPC t$00 spr$F0 (3,3) scr255
    db $00, $F0, $03, $03, $FF
    ; NPC t$00 spr$F1 (5,3) scr255
    db $00, $F1, $05, $03, $FF
    ; NPC t$00 spr$F2 (6,3) scr255
    db $00, $F2, $06, $03, $FF
    ; NPC t$20 spr$E1 (5,5) scr255
    db $20, $E1, $05, $05, $FF
    ; NPC t$20 spr$E2 (3,5) scr255
    db $20, $E2, $03, $05, $FF
    ; NPC t$20 spr$E3 (6,5) scr255
    db $20, $E3, $06, $05, $FF
    ; NPC t$20 spr$E0 (4,5) scr255
    db $20, $E0, $04, $05, $FF, $FF

m52_Special___Coliseum_N0v0:  ; $784A
    ; npcs s0v0
    db $FF

m53_Special___Forest_Maze_SP:  ; $784B
    ; screen_ptrs $53
    db $55, $78

m61_X_SP:  ; $784D
    ; screen_ptrs $61
    db $5D, $78

m62_X_SP:  ; $784F
    ; screen_ptrs $62
    db $65, $78

m63_X_SP:  ; $7851
    ; screen_ptrs $63
    db $6D, $78

m64_X_SP:  ; $7853
    ; screen_ptrs $64
    db $75, $78

m53_Special___Forest_Maze_SB0:  ; $7855
    ; step_block scr0 ram=0xD998
    db $98, $D9, $19, $23, $7D, $78, $7E, $78

m53_Special___Forest_Maze_SB1:  ; $785D
    ; step_block scr1 ram=0xD998
    ; step_block scr0 ram=0xD998
    db $98, $D9, $1A, $23, $7D, $78, $9B, $78

m53_Special___Forest_Maze_SB2:  ; $7865
    ; step_block scr2 ram=0xD998
    ; step_block scr1 ram=0xD998
    ; step_block scr0 ram=0xD998
    db $98, $D9, $1B, $23, $7D, $78, $B8, $78

m53_Special___Forest_Maze_SB3:  ; $786D
    ; step_block scr3 ram=0xD998
    ; step_block scr2 ram=0xD998
    ; step_block scr1 ram=0xD998
    db $98, $D9, $1C, $23, $7D, $78, $CE, $78

m53_Special___Forest_Maze_SB4:  ; $7875
    ; step_block scr4 ram=0xD998
    ; step_block scr3 ram=0xD998
    ; step_block scr2 ram=0xD998
    db $98, $D9, $1D, $23, $7D, $78, $F9, $78

m53_Special___Forest_Maze_X0v0:  ; $787D
    ; exits s0v0
    ; exits s1v0
    ; exits s2v0
    db $FF

m53_Special___Forest_Maze_N0v0:  ; $787E
    ; npcs s0v0
    db $00, $03
    ; Exit (0,3)->Map_62
    db $62, $00, $00, $09, $03, $01, $00
    ; Exit (1,0)->Map_61
    db $61, $00, $00, $01, $07, $08, $00
    ; Exit (8,0)->Map_63
    db $63, $00, $00, $08, $07, $09, $03
    ; Exit (9,3)->Map_61
    db $61, $00, $00, $00, $03, $FF

m53_Special___Forest_Maze_N1v0:  ; $789B
    ; npcs s1v0
    ; npcs s0v0
    db $01, $07
    ; Exit (1,7)->Forest_Maze
    db $53, $00, $00, $01, $00, $08, $07
    ; Exit (8,7)->Forest_Maze
    db $53, $00, $00, $08, $00, $00, $03
    ; Exit (0,3)->Forest_Maze
    db $53, $00, $00, $09, $03, $01, $00
    ; Exit (1,0)->Map_62
    db $62, $00, $00, $01, $07, $FF

m53_Special___Forest_Maze_N2v0:  ; $78B8
    ; npcs s2v0
    ; npcs s1v0
    ; npcs s0v0
    db $01, $07
    ; Exit (1,7)->Map_61
    db $61, $00, $00, $01, $00, $08, $00
    ; Exit (8,0)->Map_61
    db $61, $00, $00, $08, $07, $09, $03
    ; Exit (9,3)->Forest_Maze
    db $53, $00, $00, $00, $03, $FF

m53_Special___Forest_Maze_N3v0:  ; $78CE
    ; npcs s3v0
    ; npcs s2v0
    ; npcs s1v0
    db $08, $07
    ; Exit (8,7)->Map_62
    db $62, $00, $00, $08, $00, $09, $05
    ; Exit (9,5)->Map_63
    db $63, $00, $00, $00, $05, $01, $00
    ; Exit (1,0)->Map_63
    db $63, $00, $00, $01, $07, $04, $00
    ; Exit (4,0)->Map_64
    db $64, $00, $00, $04, $07, $00, $05
    ; Exit (0,5)->Map_63
    db $63, $00, $00, $09, $05, $01, $07
    ; Exit (1,7)->Map_63
    db $63, $00, $00, $01, $00, $FF

m53_Special___Forest_Maze_N4v0:  ; $78F9
    ; npcs s4v0
    ; npcs s3v0
    ; npcs s2v0
    db $04, $07
    ; Exit (4,7)->Map_63
    db $63, $00, $00, $04, $00, $04, $04, $00, $80, $00, $00, $00, $FF

m54_Special___Conveyor_Belt_1_SP:  ; $7908
    ; screen_ptrs $54
    db $20, $79, $28, $79, $30, $79, $FF, $FF, $38, $79, $40, $79, $48, $79, $FF, $FF
    db $50, $79, $58, $79, $60, $79, $FF, $FF

m54_Special___Conveyor_Belt_1_SB0:  ; $7920
    ; step_block scr0 ram=0xD998
    db $98, $D9, $01, $37, $42, $4B, $68, $79

m54_Special___Conveyor_Belt_1_SB1:  ; $7928
    ; step_block scr1 ram=0xD998
    db $98, $D9, $02, $37, $42, $4B, $69, $79

m54_Special___Conveyor_Belt_1_SB2:  ; $7930
    ; step_block scr2 ram=0xD998
    db $98, $D9, $03, $37, $42, $4B, $6A, $79, $98, $D9, $04, $37, $42, $4B, $6B, $79
    db $98, $D9, $05, $37, $42, $4B, $6C, $79, $98, $D9, $06, $37, $42, $4B, $6D, $79
    db $98, $D9, $07, $37, $42, $4B, $6E, $79, $98, $D9, $08, $37, $42, $4B, $6F, $79
    db $98, $D9, $09, $37, $42, $4B, $70, $79

m54_Special___Conveyor_Belt_1_N0v0:  ; $7968
    ; npcs s0v0
    db $FF

m54_Special___Conveyor_Belt_1_N1v0:  ; $7969
    ; npcs s1v0
    db $FF

m54_Special___Conveyor_Belt_1_N2v0:  ; $796A
    ; npcs s2v0
    db $FF, $FF, $FF, $FF, $FF, $FF, $08, $02, $00, $80, $00, $00, $00, $FF

m55_Special___Conveyor_Belt_2_SP:  ; $7978
    ; screen_ptrs $55
    db $90, $79, $98, $79, $A0, $79, $FF, $FF, $A8, $79, $B0, $79, $B8, $79, $FF, $FF
    db $C0, $79, $C8, $79, $D0, $79, $FF, $FF

m55_Special___Conveyor_Belt_2_SB0:  ; $7990
    ; step_block scr0 ram=0xD998
    db $98, $D9, $0B, $37, $42, $4B, $D8, $79

m55_Special___Conveyor_Belt_2_SB1:  ; $7998
    ; step_block scr1 ram=0xD998
    db $98, $D9, $0C, $37, $42, $4B, $D9, $79

m55_Special___Conveyor_Belt_2_SB2:  ; $79A0
    ; step_block scr2 ram=0xD998
    db $98, $D9, $0D, $37, $42, $4B, $DA, $79, $98, $D9, $0E, $37, $42, $4B, $DB, $79
    db $98, $D9, $0F, $37, $42, $4B, $DC, $79, $98, $D9, $10, $37, $42, $4B, $DD, $79
    db $98, $D9, $11, $37, $42, $4B, $DE, $79, $98, $D9, $12, $37, $42, $4B, $E6, $79
    db $98, $D9, $13, $37, $42, $4B, $E7, $79

m55_Special___Conveyor_Belt_2_N0v0:  ; $79D8
    ; npcs s0v0
    db $FF

m55_Special___Conveyor_Belt_2_N1v0:  ; $79D9
    ; npcs s1v0
    db $FF

m55_Special___Conveyor_Belt_2_N2v0:  ; $79DA
    ; npcs s2v0
    db $FF, $FF, $FF, $FF, $06, $06, $00, $80, $00, $00, $00, $FF, $FF, $FF

m56_Special___Conveyor_Belt_3_SP:  ; $79E8
    ; screen_ptrs $56
    db $00, $7A, $08, $7A, $10, $7A, $FF, $FF, $18, $7A, $20, $7A, $28, $7A, $FF, $FF
    db $30, $7A, $38, $7A, $40, $7A, $FF, $FF

m56_Special___Conveyor_Belt_3_SB0:  ; $7A00
    ; step_block scr0 ram=0xD998
    db $98, $D9, $15, $37, $42, $4B, $48, $7A

m56_Special___Conveyor_Belt_3_SB1:  ; $7A08
    ; step_block scr1 ram=0xD998
    db $98, $D9, $16, $37, $42, $4B, $49, $7A

m56_Special___Conveyor_Belt_3_SB2:  ; $7A10
    ; step_block scr2 ram=0xD998
    db $98, $D9, $17, $37, $42, $4B, $4A, $7A, $98, $D9, $18, $37, $42, $4B, $52, $7A
    db $98, $D9, $19, $37, $42, $4B, $53, $7A, $98, $D9, $1A, $37, $42, $4B, $54, $7A
    db $98, $D9, $1B, $37, $42, $4B, $55, $7A, $98, $D9, $1C, $37, $42, $4B, $56, $7A
    db $98, $D9, $1D, $37, $42, $4B, $57, $7A

m56_Special___Conveyor_Belt_3_N0v0:  ; $7A48
    ; npcs s0v0
    db $FF

m56_Special___Conveyor_Belt_3_N1v0:  ; $7A49
    ; npcs s1v0
    db $FF

m56_Special___Conveyor_Belt_3_N2v0:  ; $7A4A
    ; npcs s2v0
    db $03, $03, $00, $80, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF

m57_Special___Maze_1_SP:  ; $7A58
    ; screen_ptrs $57
    db $70, $7A, $78, $7A, $80, $7A, $FF, $FF, $88, $7A, $90, $7A, $98, $7A, $FF, $FF
    db $A0, $7A, $A8, $7A, $B0, $7A, $FF, $FF

m57_Special___Maze_1_SB0:  ; $7A70
    ; step_block scr0 ram=0xD998
    db $98, $D9, $1F, $37, $42, $4B, $B8, $7A

m57_Special___Maze_1_SB1:  ; $7A78
    ; step_block scr1 ram=0xD998
    db $98, $D9, $20, $37, $42, $4B, $B9, $7A

m57_Special___Maze_1_SB2:  ; $7A80
    ; step_block scr2 ram=0xD998
    db $98, $D9, $21, $37, $42, $4B, $BA, $7A, $98, $D9, $22, $37, $42, $4B, $BB, $7A
    db $98, $D9, $23, $37, $42, $4B, $BC, $7A, $98, $D9, $24, $37, $42, $4B, $BD, $7A
    db $98, $D9, $25, $37, $42, $4B, $BE, $7A, $98, $D9, $26, $37, $42, $4B, $C6, $7A
    db $98, $D9, $27, $37, $42, $4B, $C7, $7A

m57_Special___Maze_1_N0v0:  ; $7AB8
    ; npcs s0v0
    db $FF

m57_Special___Maze_1_N1v0:  ; $7AB9
    ; npcs s1v0
    db $FF

m57_Special___Maze_1_N2v0:  ; $7ABA
    ; npcs s2v0
    db $FF, $FF, $FF, $FF, $01, $06, $00, $80, $00, $00, $00, $FF, $FF, $FF

m58_Special___Maze_2_SP:  ; $7AC8
    ; screen_ptrs $58
    db $E0, $7A, $E8, $7A, $F0, $7A, $FF, $FF, $F8, $7A, $00, $7B, $08, $7B, $FF, $FF
    db $10, $7B, $18, $7B, $20, $7B, $FF, $FF

m58_Special___Maze_2_SB0:  ; $7AE0
    ; step_block scr0 ram=0xD998
    db $98, $D9, $29, $37, $42, $4B, $28, $7B

m58_Special___Maze_2_SB1:  ; $7AE8
    ; step_block scr1 ram=0xD998
    db $98, $D9, $2A, $37, $42, $4B, $29, $7B

m58_Special___Maze_2_SB2:  ; $7AF0
    ; step_block scr2 ram=0xD998
    db $98, $D9, $2B, $37, $42, $4B, $2A, $7B, $98, $D9, $2C, $37, $42, $4B, $2B, $7B
    db $98, $D9, $2D, $37, $42, $4B, $2C, $7B, $98, $D9, $2E, $37, $42, $4B, $2D, $7B
    db $98, $D9, $2F, $37, $42, $4B, $2E, $7B, $98, $D9, $30, $37, $42, $4B, $2F, $7B
    db $98, $D9, $31, $37, $42, $4B, $37, $7B

m58_Special___Maze_2_N0v0:  ; $7B28
    ; npcs s0v0
    db $FF

m58_Special___Maze_2_N1v0:  ; $7B29
    ; npcs s1v0
    db $FF

m58_Special___Maze_2_N2v0:  ; $7B2A
    ; npcs s2v0
    db $FF, $FF, $FF, $FF, $FF, $03, $06, $00, $80, $00, $00, $00, $FF, $FF

m59_Special___Maze_3_SP:  ; $7B38
    ; screen_ptrs $59
    db $50, $7B, $58, $7B, $60, $7B, $FF, $FF, $68, $7B, $70, $7B, $78, $7B, $FF, $FF
    db $80, $7B, $88, $7B, $90, $7B, $FF, $FF

m59_Special___Maze_3_SB0:  ; $7B50
    ; step_block scr0 ram=0xD998
    db $98, $D9, $33, $37, $42, $4B, $98, $7B

m59_Special___Maze_3_SB1:  ; $7B58
    ; step_block scr1 ram=0xD998
    db $98, $D9, $34, $37, $42, $4B, $99, $7B

m59_Special___Maze_3_SB2:  ; $7B60
    ; step_block scr2 ram=0xD998
    db $98, $D9, $35, $37, $42, $4B, $9A, $7B, $98, $D9, $36, $37, $42, $4B, $9B, $7B
    db $98, $D9, $37, $37, $42, $4B, $9C, $7B, $98, $D9, $38, $37, $42, $4B, $9D, $7B
    db $98, $D9, $39, $37, $42, $4B, $9E, $7B, $98, $D9, $3A, $37, $42, $4B, $9F, $7B
    db $98, $D9, $3B, $37, $42, $4B, $A0, $7B

m59_Special___Maze_3_N0v0:  ; $7B98
    ; npcs s0v0
    db $FF

m59_Special___Maze_3_N1v0:  ; $7B99
    ; npcs s1v0
    db $FF

m59_Special___Maze_3_N2v0:  ; $7B9A
    ; npcs s2v0
    db $FF, $FF, $FF, $FF, $FF, $FF, $08, $06, $00, $80, $00, $00, $00, $FF

m5A_Special___Treasure_Chest_1_SP:  ; $7BA8
    ; screen_ptrs $5A
    db $AA, $7B

m5A_Special___Treasure_Chest_1_SB0:  ; $7BAA
    ; step_block scr0 ram=0xD998
    db $98, $D9, $07, $26, $B2, $7B, $D1, $7B

m5A_Special___Treasure_Chest_1_X0v0:  ; $7BB2
    ; exits s0v0
    db $8F, $FF, $01, $02, $01, $8F, $FF, $08, $02, $02, $8F, $FF, $03, $03, $03, $8F
    db $FF, $06, $03, $04, $8F, $FF, $02, $05, $05, $8F, $FF, $07, $05, $06, $FF

m5A_Special___Treasure_Chest_1_N0v0:  ; $7BD1
    ; npcs s0v0
    db $05, $06, $00, $80, $00, $00, $00, $FF

m5B_X_SP:  ; $7BD9
    ; screen_ptrs $5B
    db $DB, $7B

m5B_X_SB0:  ; $7BDB
    ; step_block scr0 ram=0xD998
    db $98, $D9, $09, $26, $E3, $7B, $02, $7C

m5B_X_X0v0:  ; $7BE3
    ; exits s0v0
    db $8F, $FF, $03, $03, $01, $8F, $FF, $06, $03, $02, $8F, $FF, $03, $04, $03, $8F
    db $FF, $06, $04, $04, $8F, $FF, $03, $05, $05, $8F, $FF, $06, $05, $06, $FF

m5B_X_N0v0:  ; $7C02
    ; npcs s0v0
    db $05, $02, $00, $80, $00, $00, $00, $FF

m5C_Special___Treasure_Chest_3_SP:  ; $7C0A
    ; screen_ptrs $5C
    db $0C, $7C

m5C_Special___Treasure_Chest_3_SB0:  ; $7C0C
    ; step_block scr0 ram=0xD998
    db $98, $D9, $0B, $26, $14, $7C, $3D, $7C

m5C_Special___Treasure_Chest_3_X0v0:  ; $7C14
    ; exits s0v0
    db $8F, $FF, $03, $02, $01, $8F, $FF, $04, $02, $02, $8F, $FF, $05, $02, $03, $8F
    db $FF, $06, $02, $04, $8F, $FF, $03, $06, $05, $8F, $FF, $04, $06, $06, $8F, $FF
    db $05, $06, $07, $8F, $FF, $06, $06, $08, $FF

m5C_Special___Treasure_Chest_3_N0v0:  ; $7C3D
    ; npcs s0v0
    db $03, $04, $00, $80, $00, $00, $00, $FF

m5D_Arena_Battle_SP:  ; $7C45
    ; screen_ptrs $5D
    db $47, $7C

m5D_Arena_Battle_SB0:  ; $7C47
    ; step_block scr0 ram=0xD999
    db $99, $D9, $14, $23, $67, $7C, $FF, $FF, $15, $23, $67, $7C, $FF, $FF, $15, $23
    db $90, $7C, $FF, $FF, $15, $23, $B9, $7C, $FF, $FF, $15, $23, $67, $7C, $FF, $FF
    ; NPC t$10 spr$F0 (4,9) scr255
    db $10, $F0, $04, $09, $FF
    ; NPC t$10 spr$F1 (4,10) scr255
    db $10, $F1, $04, $0A, $FF
    ; NPC t$10 spr$F3 (4,11) scr255
    db $10, $F3, $04, $0B, $FF
    ; NPC t$10 spr$F2 (4,12) scr255
    db $10, $F2, $04, $0C, $FF
    ; NPC t$10 spr$E0 (7,5) scr255
    db $10, $E0, $07, $05, $FF
    ; NPC t$10 spr$E1 (6,5) scr255
    db $10, $E1, $06, $05, $FF
    ; NPC t$10 spr$E2 (6,4) scr255
    db $10, $E2, $06, $04, $FF
    ; NPC t$10 spr$E3 (6,6) scr255
    db $10, $E3, $06, $06, $FF, $FF
    ; NPC t$40 spr$F0 (4,5) scr255
    db $40, $F0, $04, $05, $FF
    ; NPC t$70 spr$F3 (3,4) scr255
    db $70, $F3, $03, $04, $FF
    ; NPC t$70 spr$F1 (3,5) scr255
    db $70, $F1, $03, $05, $FF
    ; NPC t$70 spr$F2 (3,6) scr255
    db $70, $F2, $03, $06, $FF
    ; NPC t$10 spr$E1 (6,5) scr255
    db $10, $E1, $06, $05, $FF
    ; NPC t$10 spr$E2 (6,4) scr255
    db $10, $E2, $06, $04, $FF
    ; NPC t$10 spr$E3 (6,6) scr255
    db $10, $E3, $06, $06, $FF
    ; NPC t$40 spr$52 (4,5) scr255
    db $40, $52, $04, $05, $FF, $FF
    ; NPC t$30 spr$F0 (2,5) scr255
    db $30, $F0, $02, $05, $FF
    ; NPC t$30 spr$F3 (3,4) scr255
    db $30, $F3, $03, $04, $FF
    ; NPC t$30 spr$F1 (3,5) scr255
    db $30, $F1, $03, $05, $FF
    ; NPC t$30 spr$F2 (3,6) scr255
    db $30, $F2, $03, $06, $FF
    ; NPC t$10 spr$E1 (6,5) scr255
    db $10, $E1, $06, $05, $FF
    ; NPC t$10 spr$E2 (6,4) scr255
    db $10, $E2, $06, $04, $FF
    ; NPC t$50 spr$39 (10,1) scr255
    db $50, $39, $0A, $01, $FF
    ; NPC t$10 spr$E3 (6,6) scr255
    db $10, $E3, $06, $06, $FF, $FF

m5E_X_SP:  ; $7CE2
    ; screen_ptrs $5E
    db $E4, $7C

m5E_X_SB0:  ; $7CE4
    ; step_block scr0 ram=0xD99A
    db $9A, $D9, $17, $23, $FE, $7C, $FF, $FF, $17, $23, $0E, $7D, $FF, $FF, $17, $23
    db $19, $7D, $FF, $FF, $17, $23, $42, $4B, $FF, $FF
    ; NPC t$10 spr$E0 (7,5) scr255
    db $10, $E0, $07, $05, $FF
    ; NPC t$40 spr$57 (4,0) scr255
    db $40, $57, $04, $00, $FF
    ; NPC t$40 spr$52 (4,5) scr255
    db $40, $52, $04, $05, $FF, $FF
    ; NPC t$70 spr$08 (0,4) scr255
    db $70, $08, $00, $04, $FF
    ; NPC t$40 spr$55 (5,4) scr255
    db $40, $55, $05, $04, $FF, $FF
    ; NPC t$20 spr$E0 (5,5) scr255
    db $20, $E0, $05, $05, $FF
    ; NPC t$50 spr$21 (9,5) scr255
    db $50, $21, $09, $05, $FF, $FF, $E0, $1F, $70, $8F, $18, $E7, $83, $7C, $07, $F8
    db $C1, $3E, $81, $FF, $C0, $FF, $C0, $FF, $81, $FF, $81, $FF, $03, $FF, $03, $FF
    db $81, $FF, $04, $04, $0A, $0E, $35, $3B, $CA, $F7, $33, $CF, $81, $FF, $67, $FF
    db $9C, $7F, $1C, $E3, $36, $C9, $22, $DD, $82, $7D, $C0, $3F, $C1, $3E, $49, $B6
    db $1D, $E2, $07, $F8, $70, $8F, $C1, $3E, $83, $7C, $C1, $3E, $60, $9F, $0E, $F1
    db $1C, $E3, $C0, $FF, $81, $FF, $81, $FF, $03, $FF, $03, $FF, $81, $FF, $81, $FF
    db $C0, $FF, $01, $01, $82, $83, $4D, $CE, $B2, $FD, $CC, $F3, $62, $FF, $9D, $FF
    db $72, $FD, $11, $EE, $41, $BE, $60, $9F, $E0, $1F, $A4, $5B, $8E, $71, $0E, $F1
    db $1B, $E4, $C1, $3E, $07, $F8, $0E, $F1, $07, $F8, $81, $7E, $38, $C7, $70, $8F
    db $1C, $E3, $81, $FF, $03, $FF, $03, $FF, $81, $FF, $81, $FF, $C0, $FF, $C0, $FF
    db $81, $FF, $40, $40, $A0, $E0, $53, $B3, $AC, $7F, $33, $FC, $18, $FF, $76, $FF
    db $C9, $F7, $30, $CF, $70, $8F, $52, $AD, $47, $B8, $07, $F8, $8D, $72, $88, $77
    db $A0, $5F, $1C, $E3, $38, $C7, $1C, $E3, $06, $F9, $E0, $1F, $C1, $3E, $70, $8F
    db $07, $F8, $03, $FF, $81, $FF, $81, $FF, $C0, $FF, $C0, $FF, $81, $FF, $81, $FF
    db $03, $FF, $00, $FF, $00, $FF, $00, $FF, $10, $EF, $20, $CF, $40, $8F, $40, $9E
    db $40, $88, $00, $FF, $00, $FF, $00, $FF, $08, $F7, $04, $F3, $02, $F1, $02, $79
    db $02, $11, $20, $C0, $60, $80, $A0, $10, $92, $22, $97, $17, $97, $17, $BE, $3E
    db $B8, $38, $04, $03, $06, $01, $05, $08, $49, $44, $E9, $E8, $E9, $E8, $7D, $7C
    db $1D, $1C, $04, $FB, $0E, $F5, $0F, $F6, $0F, $F7, $0F, $F7, $3F, $CF, $7D, $AD
    db $78, $A8, $20, $DF, $70, $AF, $F0, $6F, $F0, $EF, $F0, $EF, $FC, $F3, $BE, $B5
    db $1E, $15, $70, $B0, $60, $A0, $60, $A0, $20, $C0, $20, $C0, $10, $E0, $10, $E0
    db $10, $E0, $0E, $0D, $06, $05, $06, $05, $04, $03, $04, $03, $08, $07, $08, $07
    db $08, $07, $00, $FF, $00, $FF, $00, $FF, $10, $EF, $20, $CF, $40, $8F, $40, $9E
    db $40, $88, $00, $FF, $00, $FF, $00, $FF, $08, $F7, $04, $F3, $02, $F1, $02, $79
    db $02, $11, $20, $C0, $60, $80, $A0, $10, $92, $22, $97, $17, $97, $17, $BE, $3E
    db $B8, $38, $04, $03, $06, $01, $05, $08, $49, $44, $E9, $E8, $E9, $E8, $7D, $7C
    db $1D, $1C, $04, $FB, $0E, $F5, $0F, $F6, $0F, $F7, $0F, $F7, $3F, $CF, $7D, $AD
    db $78, $A8, $20, $DF, $70, $AF, $F0, $6F, $F0, $EF, $F0, $EF, $FC, $F3, $BE, $B5
    db $1E, $15, $70, $B0, $60, $A0, $60, $A0, $20, $C0, $20, $C0, $10, $E0, $10, $E0
    db $10, $E0, $0E, $0D, $06, $05, $06, $05, $04, $03, $04, $03, $08, $07, $08, $07
    db $08, $07, $10, $10, $28, $38, $D4, $EC, $2B, $DF, $CC, $3F, $26, $FF, $D9, $FF
    db $27, $DF, $06, $F9, $1D, $E2, $3B, $C4, $F7, $08, $2E, $D1, $6D, $92, $6D, $92
    db $B6, $48, $C0, $3F, $6A, $95, $BA, $45, $BA, $45, $DC, $23, $6A, $95, $6E, $91
    db $DC, $23, $00, $FF, $40, $BA, $A0, $5F, $40, $BF, $00, $FF, $08, $57, $14, $EB
    db $08, $F7, $04, $04, $0A, $0E, $35, $3B, $CA, $F7, $33, $CF, $81, $FF, $67, $FF
    db $9C, $7F, $03, $FC, $16, $E9, $0E, $F1, $FD, $02, $1B, $E4, $36, $C9, $55, $AA
    db $BA, $44, $60, $9F, $BA, $45, $DA, $25, $DE, $21, $EC, $13, $F6, $09, $76, $89
    db $EE, $11, $00, $FF, $00, $FA, $08, $F7, $14, $EB, $09, $F6, $82, $5D, $01, $EE
    db $00, $FF, $01, $01, $82, $83, $4D, $CE, $B2, $FD, $CC, $F3, $62, $FF, $9D, $FF
    db $72, $FD, $06, $F9, $1D, $E2, $3B, $C4, $F7, $08, $2E, $D1, $6D, $92, $6D, $92
    db $B6, $48, $C0, $3F, $6A, $95, $BA, $45, $BA, $45, $DC, $23, $6A, $95, $6E, $91
    db $DC, $23, $00, $FF, $02, $F8, $05, $FA, $02, $FD, $00, $FF, $40, $1F, $A0, $4F
    db $40, $BF, $40, $40, $A0, $E0, $53, $B3, $AC, $7F, $33, $FC, $18, $FF, $76, $FF
    db $C9, $F7, $03, $FC, $16, $E9, $0E, $F1, $FD, $02, $1B, $E4, $36, $C9, $55, $AA
    db $BA, $44, $60, $9F, $BA, $45, $DA, $25, $DE, $21, $EC, $13, $F6, $09, $76, $89
    db $EE, $11, $00, $FF, $00, $FA, $80, $7F, $41, $BE, $90, $6F, $28, $57, $10, $CF
    db $00, $FF
