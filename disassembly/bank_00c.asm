; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

; ===========================================================================
; Bank $0C — Script Data Bank (Map Types $00–$05)
; ===========================================================================
; Handles script data for: Castle ($00), GreatTree ($01), Bazaar ($02),
; GateHub ($03), Farm ($04), Stable ($05).
;
; Called by bank $04 Call_004_71ef (ScriptDataRead) when $D8D3 < $06.
; ===========================================================================

SECTION "ROM Bank $00c", ROMX[$4000], BANK[$c]
    ;rom bank
    db $0c

    ;code jump table
    dw ScriptDataLookup      ; Entry 0: Triple-index script data read
    dw ScriptBank0CDrawTiles           ; Entry 1: script op $24 draw_tiles (S118)
    dw ScriptBank0CDrawAttrs           ; Entry 2: script op $61 draw_attrs (S118)

; ---------------------------------------------------------------------------
; Entry 0: ScriptDataLookup — Triple-index script data reader
; ---------------------------------------------------------------------------
; Performs a 3-level lookup to fetch the next script command BC pair:
;
;   Level 1: $D8D3 (map_type) → master table at $41BA
;            $41BA[map_type × 2] → per-map script pointer table
;
;   Level 2: $D8D4 (script_id) → per-map pointer table
;            per_map_table[script_id × 2] → per-NPC script data base
;
;   Level 3: $D8D5/$D8D6 (script counter) → script data
;            script_data[counter × 2] → BC command pair
;
; Input:  $D8D3 = map type, $D8D4 = NPC script_id, $D8D5/$D8D6 = counter
; Output: BC = next script command, HL = pointer to that command in ROM
;
; Script data format: array of 16-bit words (BC pairs).
;   BC = $FFFF:           script end
;   B != $FF:             BC is a 16-bit text ID
;   B == $FF, C = opcode: script command (dispatched by bank $04)
;   Addresses ($4xxx-$7xxx): branch targets for ConditionalBranch commands
; ---------------------------------------------------------------------------
ScriptDataLookup:
LoadBc_4007:
    ld a, [wScriptMapType]            ; Map type (0=Castle, 1=GreatTree, etc.)
    ld l, a
    ld h, $00
    add hl, hl               ; HL = map_type × 2
    ld de, Bank0C_ScriptMasterTable             ; Master script pointer table
    add hl, de               ; HL = $41BA + map_type × 2
    ld e, [hl]
    inc hl
    ld d, [hl]               ; DE = per-map pointer table address

    ld a, [wScriptNPCId]            ; NPC script_id (set before ScriptInit)
    ld l, a
    ld h, $00
    add hl, hl               ; HL = script_id × 2
    add hl, de               ; HL = per-map table + script_id × 2
    ld e, [hl]
    inc hl
    ld d, [hl]               ; DE = per-NPC script data base pointer

    ld a, [wScriptCounter]            ; Script counter low
    ld l, a
    ld a, [$d8d6]            ; Script counter high
    ld h, a
    add hl, hl               ; HL = counter × 2 (each entry is 2 bytes)
    add hl, de               ; HL = script_data + counter × 2
    ld c, [hl]               ; C = command low byte
    inc hl
    ld b, [hl]               ; B = command high byte
    dec hl                   ; HL points back to current entry (for ScriptBranch)
    ret

; S118: script op $24 draw_tiles (bank $04 ScriptCmd24_DrawTiles far-calls
; entry 1 of the map's script bank). It READS ONE MORE SCRIPT WORD itself
; (counter + 1, then the entry-0 lookup): an address in THIS bank of a tile
; patch — [dest offset word, tile bytes …, $D8 = next row, $D9 = end] — drawn
; onto the visible BG map ($FFB7/$FFBB scroll, $D8E7/$D8E8 cursor) and staged
; at $C300+. So op $24 takes 1 parameter (the S96 tracer stops at rst $10).
; Custom rooms (bank $60): $24 goes to bank $0F entry 1, whose lookup reads bank
; $0F's own tables, not bank $60 — MEASURED S119 (PyBoy, a copy of the Castle:
; its chest patch is not drawn). Patched builds: bank $04 calls bank $60
; entries 9 / 10 (CustomDrawTiles / CustomDrawAttrs) instead, which draw a
; custom room's patch from bank $60 and pass everything else on to here.
ScriptBank0CDrawTiles:
    ld hl, $ffb7	;jump table address 2
    ld a, [hl]
    and $f8
    ld [hl], a
    ld hl, $ffbb
    ld a, [hl]
    and $f8
    ld [hl], a
    ldh a, [$bb]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ldh a, [$b7]
    rrca
    rrca
    rrca
    add l
    ld l, a
    ld a, h
    adc $98
    ld h, a
    ld a, h
    and $03
    or $98
    ld h, a
    ld a, l
    ld [$d8e7], a
    ld a, h
    ld [$d8e8], a
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call LoadBc_4007
    push bc
    call LoadBc_40e7
    pop bc

LoadBc_4075:
    ld a, [bc]
    ld l, a
    inc bc
    ld a, [bc]
    ld h, a
    inc bc
    push bc
    ld b, l
    ld a, l
    and $e0
    ld l, a
    ld a, [$d8e7]
    add l
    ld l, a
    ld a, [$d8e8]
    adc h
    and $03
    ld h, a
    ld a, [$d8e8]
    and $fc
    or h
    ld h, a
    ld a, b
    and $1f
    jr z, jr_00c_40a0

    ld b, a

jr_00c_409a:
    call LoadBc_40da
    dec b
    jr nz, jr_00c_409a

jr_00c_40a0:
    ld a, l
    ld [$d8e7], a
    ld a, h
    ld [$d8e8], a
    pop bc

jr_00c_40a9:
    ld a, [bc]
    inc bc
    cp $d9
    ret z

    cp $d8
    jr nz, jr_00c_40d2

    ld a, [$d8e7]
    ld l, a
    ld a, [$d8e8]
    ld h, a
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, h
    and $03
    or $98
    ld h, a
    ld a, l
    ld [$d8e7], a
    ld a, h
    ld [$d8e8], a
    jr jr_00c_40a9

jr_00c_40d2:
    call Write_gfx_tile
    call LoadBc_40da
    jr jr_00c_40a9

LoadBc_40da:
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


LoadBc_40e7:
    ld a, [bc]
    ld l, a
    inc bc
    ld a, [bc]
    ld h, a
    inc bc
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c3
    ld h, a

jr_00c_40f5:
    push hl

jr_00c_40f6:
    ld a, [bc]
    inc bc
    cp $d9
    jr z, jr_00c_410e

    cp $d8
    jr nz, jr_00c_410b

    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00c_40f5

jr_00c_410b:
    ld [hl+], a
    jr jr_00c_40f6

jr_00c_410e:
    pop hl
    ret

; S118: script op $61 draw_attrs (ScriptCmd61_DrawAttrs, entry 2): like entry 1
; it reads ONE more script word (a patch address in this bank) and writes the
; patch to VRAM bank 1 (the BG attributes) on GBC.
ScriptBank0CDrawAttrs:
    ld hl, $ffb7		;jump table address 3
    ld a, [hl]
    and $f8
    ld [hl], a
    ld hl, $ffbb
    ld a, [hl]
    and $f8
    ld [hl], a
    ldh a, [$bb]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ldh a, [$b7]
    rrca
    rrca
    rrca
    add l
    ld l, a
    ld a, h
    adc $98
    ld h, a
    ld a, h
    and $03
    or $98
    ld h, a
    ld a, l
    ld [$d8e7], a
    ld a, h
    ld [$d8e8], a
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call LoadBc_4007
    push bc
    call LoadBc_4171
    pop bc
    ld a, [wIsGBC]
    or a
    ret z

    di
    call WaitVRAM
    ld a, $01
    ldh [rVBK], a
    ei
    call LoadBc_4075
    di
    call WaitVRAM
    ld a, $00
    ldh [rVBK], a
    ei
    ret


LoadBc_4171:
    ld a, [bc]
    ld l, a
    inc bc
    ld a, [bc]
    ld h, a
    inc bc

jr_00c_4177:
    push hl

jr_00c_4178:
    ld a, [bc]
    inc bc
    cp $d9
    jr z, jr_00c_4193

    cp $d8
    jr nz, jr_00c_418d

    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00c_4177

jr_00c_418d:
    call SaveBc_4195
    inc hl
    jr jr_00c_4178

jr_00c_4193:
    pop hl
    ret


SaveBc_4195:
    push hl
    srl h
    rr l
    push af
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c2
    ld h, a
    pop af
    jr c, jr_00c_41b0

    swap a
    and $f0
    ld d, a
    ld a, [hl]
    and $0f
    jr jr_00c_41b6

jr_00c_41b0:
    and $0f
    ld d, a
    ld a, [hl]
    and $f0

jr_00c_41b6:
    or d
    ld [hl], a
    pop hl
    ret


; ===========================================================================
; Script Data — Bank $0C
; 129 scripts across 6 maps, 452 labels
; ===========================================================================

; ---------------------------------------------------------------------------
; Bank0C_ScriptMasterTable
; ---------------------------------------------------------------------------
Bank0C_ScriptMasterTable:
    dw Castle_ScriptPtrTable ; map type $00: Castle
    dw GreatTree_ScriptPtrTable ; map type $01: GreatTree
    dw Bazaar_ScriptPtrTable ; map type $02: Bazaar
    dw GateHub_ScriptPtrTable ; map type $03: Gate Hub
    dw Farm_ScriptPtrTable  ; map type $04: Farm
    dw Stable_ScriptPtrTable ; map type $05: Stable
; ---------------------------------------------------------------------------
; Castle Per-Script Table (map_type=$00, 20 scripts)
; ---------------------------------------------------------------------------
Castle_ScriptPtrTable:
    dw Castle_Script00      ; script 0
    dw Castle_Script01      ; script 1
    dw Castle_Script02      ; script 2
    dw Castle_Script03      ; script 3
    dw Castle_Script04      ; script 4
    dw Castle_Script05      ; script 5
    dw Castle_Script06      ; script 6
    dw Castle_Script07      ; script 7
    dw Castle_Script08      ; script 8
    dw Castle_Script09      ; script 9
    dw Castle_Script10      ; script 10
    dw Castle_Script11      ; script 11
    dw Castle_Script12      ; script 12
    dw Castle_Script13      ; script 13
    dw Castle_Script14      ; script 14
    dw Castle_Script15      ; script 15
    dw Castle_Script16      ; script 16
    dw Castle_Script17      ; script 17
    dw Castle_Script18      ; script 18
    dw Castle_Script19      ; script 19
; ---------------------------------------------------------------------------
; Castle_Script00
; ---------------------------------------------------------------------------
Castle_Script00:
    dw $FF0E                ; $0E branch_screen: If on screen 1 → Bank0C_ScriptAddr_4246
    dw $0001                ;   screen
    dw Bank0C_ScriptAddr_4246 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 5 → Bank0C_ScriptAddr_41FC
    dw $0005                ;   screen
    dw Bank0C_ScriptAddr_41FC ;   target
Bank0C_ScriptAddr_41FA:
    dw $FFFF                ; END

Bank0C_ScriptAddr_41FC:
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is the intro journey (dresser → GreatTree → Castle) → Bank0C_ScriptAddr_4212  [$D951 = 255]
    dw $D951                ;   address
    dw $00FF                ;   value
    dw Bank0C_ScriptAddr_4212 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_41FA
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_41FA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0C_ScriptAddr_50A8
    dw $00EE                ;   flag
    dw Bank0C_ScriptAddr_50A8 ;   target
    dw $FFFF                ; END

Bank0C_ScriptAddr_4212:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0B                ; $0B walk_y_wait: NPC 4 walks down 2 tiles (script waits)
    dw $0004                ;   actor
    dw $0020                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0015                ; text $0015: "*:I'm the minister of this kingdom. Are …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF0B                ; $0B walk_y_wait: NPC 4 walks up 8 tiles (script waits)
    dw $0004                ;   actor
    dw $FF80                ;   pixels
    dw $FF03                ; $03 set_flag: Set flag $0001
    dw $0001                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 5 (+8 room variant(s) sharing it) → state 1  [$D92C := 1]
    dw $D92C                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 0 → state 1  [$D92D := 1]
    dw $D92D                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: 0  [$D951 := 0]
    dw $D951                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
; S101 r3: Castle_Script00 screen 1 = the CASTLE ARRIVAL dispatch on $D92B
; (the arrival-event code; PyBoy-measured): 0 / 4 -> $4270 (new-game intro +
; story cascade), 6 -> $490A (priest: GreatTree blessing + heal — written by bank
; $07 for the gate return; 8 = the same path, written by bank $50 after a lost
; battle and bank $06), 7 -> $47E0 (a gate boss was beaten: the King's speech
; chain on $D9E3), 1-3/5 -> no event.
Bank0C_ScriptAddr_4246:
    dw $FF15                ; $15 check_and_branch: If “the room state of Castle screen 1 (+8 room variant(s) sharing it)” is state 0 → Bank0C_ScriptAddr_4270  [$D92B = 0]
    dw $D92B                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_4270 ;   target
    dw $FF15                ; $15 check_and_branch: If “the room state of Castle screen 1 (+8 room variant(s) sharing it)” is state 4 → Bank0C_ScriptAddr_4270  [$D92B = 4]
    dw $D92B                ;   address
    dw $0004                ;   value
    dw Bank0C_ScriptAddr_4270 ;   target
    dw $FF15                ; $15 check_and_branch: If “the room state of Castle screen 1 (+8 room variant(s) sharing it)” is state 6 → Bank0C_ScriptAddr_490A  [$D92B = 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw Bank0C_ScriptAddr_490A ;   target
    dw $FF15                ; $15 check_and_branch: If “the room state of Castle screen 1 (+8 room variant(s) sharing it)” is state 7 → Bank0C_ScriptAddr_47E0  [$D92B = 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw Bank0C_ScriptAddr_47E0 ;   target
    dw $FF15                ; $15 check_and_branch: If “the room state of Castle screen 1 (+8 room variant(s) sharing it)” is state 8 → Bank0C_ScriptAddr_490A  [$D92B = 8]
    dw $D92B                ;   address
    dw $0008                ;   value
    dw Bank0C_ScriptAddr_490A ;   target
    dw $FFFF                ; END

Bank0C_ScriptAddr_4270:
; =============================================================================
; NEW-GAME INTRO  —  grants the STARTER MONSTER ("Slib").
; -----------------------------------------------------------------------------
; Reached by fall-through when NONE of the story-progress flags below are set,
; i.e. on a brand-new save. Each if_flag_set jumps away once the corresponding
; later-game flag exists; on a fresh game execution falls through to the
; add_monster grant, then sets flag $0002 so the grant runs EXACTLY ONCE
; (the $0002 check is the last gate in the cascade).
;
; STARTER = enemy-stats EID $0001  ($14:$4C36, flat 0x50C36): a dedicated
; always-join (joinability $00) Lv1 Slime, distinct from the wild Slime (EID 2).
; The add_monster ($29) handler ($04:$5F9A) builds it from LoadEnemyStats(EID 1)
; into the first empty $CAC1 storage slot. Editing enemy-stats entry 1 therefore
; changes the starting monster's species / level / stats.
; =============================================================================
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_41FA
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_41FA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0C_ScriptAddr_44BA
    dw $00EE                ;   flag
    dw Bank0C_ScriptAddr_44BA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $009A is set → Bank0C_ScriptAddr_41FA
    dw $009A                ;   flag
    dw Bank0C_ScriptAddr_41FA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_4438
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_4438 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0069 is set → Bank0C_ScriptAddr_41FA
    dw $0069                ;   flag
    dw Bank0C_ScriptAddr_41FA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0C_ScriptAddr_440C
    dw $0033                ;   flag
    dw Bank0C_ScriptAddr_440C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $003E is set → Bank0C_ScriptAddr_41FA
    dw $003E                ;   flag
    dw Bank0C_ScriptAddr_41FA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0C_ScriptAddr_438C
    dw $0030                ;   flag
    dw Bank0C_ScriptAddr_438C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0008 is set → Bank0C_ScriptAddr_41FA
    dw $0008                ;   flag
    dw Bank0C_ScriptAddr_41FA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0007 is set → Bank0C_ScriptAddr_42EC
    dw $0007                ;   flag
    dw Bank0C_ScriptAddr_42EC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0002 is set → Bank0C_ScriptAddr_41FA ‖ if_flag_set $0002 -> $41FA   (starter-given flag: skip once granted)
    dw $0002                ;   flag
    dw Bank0C_ScriptAddr_41FA ;   target
    ; --- fall-through: brand-new save, grant the starter ---
    dw $FF10                ; $10 walk_to_x: the player walks to x = 232 px (script waits)
    dw $0000                ;   actor
    dw $00E8                ;   x
    dw $FF0B                ; $0B walk_y_wait: the player walks up 2 tiles (script waits)
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone) ‖ init_dialog $0020   (intro text)
    dw $0020                ; text $0020: "*:Welcome! I am the King of this kingdom…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF12                ; $12 write_ram: The naming screen's default name: none  [$C8F4 := 0]
    dw $C8F4                ;   address
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The name the naming screen edits: the hero's name  [$C8F2 := $CA42]
    dw $C8F2                ;   address
    dw $CA42                ;   value
    dw $FF04                ; $04 open_screen: Open the naming screen (the name $C8F2 points at)
    dw $000F                ;   kind
    dw $0000                ;   text
    dw $FF29                ; $29 add_monster: Add monster: enemy row 1 ‖ add_monster  <<<<<<  STARTER MONSTER GRANT
    dw $0001                ;   enemy ‖ enemy = enemy-stats EID $0001 = "Slib" (Lv1 Slime; $14:$4C36).
              ;   Change enemy-stats entry 1 to change the starting monster.
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0021                ; text $0021: "King:Oh [HERO]! Will you comply with my …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF03                ; $03 set_flag: Set flag $0002 ‖ set_flag $0002   (mark starter granted; cascade above skips hereafter)
    dw $0002                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 5 (+8 room variant(s) sharing it) → state 2  [$D92C := 2]
    dw $D92C                ;   address
    dw $0002                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_42EC:
    dw $FF10                ; $10 walk_to_x: the player walks to x = 232 px (script waits)
    dw $0000                ;   actor
    dw $00E8                ;   x
    dw $FF0B                ; $0B walk_y_wait: the player walks up 2 tiles (script waits)
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0045                ; text $0045: "King:Oh, this monster is the former king…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 6 tiles
    dw $0002                ;   actor
    dw $0060                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 24 ticks (~192 frames)
    dw $0018                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks up 6 tiles
    dw $0002                ;   actor
    dw $FFA0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 2 tiles
    dw $0004                ;   actor
    dw $FFE0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0046                ; text $0046: "Pulio:Your Majesty, please forgive me."
    dw $0047                ; text $0047: "King:Pulio, did Hale escape as well?"
    dw $0048                ; text $0048: "Pulio:Your Majesty please forgive me! Ha…"
    dw $0049                ; text $0049: "King:Arrgh! You! You let my precious Hal…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF4C                ; $4C wait_dpad: Wait until the player presses a direction on the D-pad
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $004A                ; text $004A: "King:What? [HERO]! You have something to…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 4: jump
    dw $0404                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $004B                ; text $004B: "Pulio:Majesty, Hale escaped through the …"
    dw $004C                ; text $004C: "King:I see. Now [HERO], proceed to the T…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF03                ; $03 set_flag: Set flag $0008
    dw $0008                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 1  [$D92B := 1]
    dw $D92B                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Castle screen 5 (+8 room variant(s) sharing it) → state 3  [$D92C := 3]
    dw $D92C                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 1 → state 1  [$D93C := 1]
    dw $D93C                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 0 → state 1  [$D93F := 1]
    dw $D93F                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 1 → state 1  [$D940 := 1]
    dw $D940                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 6 → state 1  [$D944 := 1]
    dw $D944                ;   address
    dw $0001                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_46EE
    dw Bank0C_ScriptAddr_46EE ;   target
Bank0C_ScriptAddr_438C:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF12                ; $12 write_ram: All field sprites hidden: shown  [$C8EC := 0]
    dw $C8EC                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: the monsters hidden (Terry shown)  [$C8ED := 14]
    dw $C8ED                ;   address
    dw $000E                ;   value
    dw $FF0D                ; $0D npc_write: NPC 6 is shown
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0147                ; text $0147: "King:Oh [HERO]! I heard you survived G c…"
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks up 3 tiles (script waits)
    dw $0006                ;   actor
    dw $FFD0                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0148                ; text $0148: "*:How are you, King of GreatTree? *:I re…"
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF49                ; $49 face_left: NPC 6 faces left
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0149                ; text $0149: "*:Oh, what a cute little child. *:Were y…"
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF47                ; $47 face_up: NPC 6 faces up
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $014A                ; text $014A: "King of GreatLog: King of GreatTree, it'…"
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: NPC 6 faces down
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks down 3 tiles (script waits)
    dw $0006                ;   actor
    dw $0030                ;   pixels
    dw $FF0D                ; $0D npc_write: NPC 6 is hidden
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $014B                ; text $014B: "King:Argh, we will see who has the last …"
    dw $FF03                ; $03 set_flag: Set flag $003E
    dw $003E                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_46EE
    dw Bank0C_ScriptAddr_46EE ;   target
Bank0C_ScriptAddr_440C:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF12                ; $12 write_ram: All field sprites hidden: shown  [$C8EC := 0]
    dw $C8EC                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: the monsters hidden (Terry shown)  [$C8ED := 14]
    dw $C8ED                ;   address
    dw $000E                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0272                ; text $0272: "King:Oh [HERO]! Good work on surviving D…"
    dw $FF03                ; $03 set_flag: Set flag $0069
    dw $0069                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_46EE
    dw Bank0C_ScriptAddr_46EE ;   target
Bank0C_ScriptAddr_4438:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF12                ; $12 write_ram: All field sprites hidden: shown  [$C8EC := 0]
    dw $C8EC                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: the monsters hidden (Terry shown)  [$C8ED := 14]
    dw $C8ED                ;   address
    dw $000E                ;   value
    dw $FF0D                ; $0D npc_write: NPC 6 is shown
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0410                ; text $0410: "King:[HERO]! At last you're in the final…"
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks up 3 tiles (script waits)
    dw $0006                ;   actor
    dw $FFD0                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0411                ; text $0411: "King of GreatLog: How are you, King of G…"
    dw $0412                ; text $0412: "King:Don't be silly! You're sarcastic as…"
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF49                ; $49 face_left: NPC 6 faces left
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0413                ; text $0413: "King of GreatLog: Oh! I didn't notice. K…"
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF47                ; $47 face_up: NPC 6 faces up
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0414                ; text $0414: "King of GreatLog: Ha ha ha ha ha! I'm lo…"
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: NPC 6 faces down
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks down 3 tiles (script waits)
    dw $0006                ;   actor
    dw $0030                ;   pixels
    dw $FF0D                ; $0D npc_write: NPC 6 is hidden
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0415                ; text $0415: "King:Huff! Whatever! He doesn't know how…"
    dw $FF03                ; $03 set_flag: Set flag $009A
    dw $009A                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_46EE
    dw Bank0C_ScriptAddr_46EE ;   target
Bank0C_ScriptAddr_44BA:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF12                ; $12 write_ram: All field sprites hidden: shown  [$C8EC := 0]
    dw $C8EC                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: the monsters hidden (Terry shown)  [$C8ED := 14]
    dw $C8ED                ;   address
    dw $000E                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0B                ; $0B walk_y_wait: NPC 3 walks up 1 tile (script waits)
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 3 walks left 1 tile (script waits)
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF4A                ; $4A face_right: NPC 3 faces right
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks up 2 tiles (script waits)
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05B8                ; text $05B8: "King:[HERO]! It's you [HERO]! King:Where…"
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF0D                ; $0D npc_write: NPC 7 is shown
    dw $0007                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: the player walks down 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: the player walks left 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF45                ; $45 restore_party_snapshot: Restore the party list from the $CAB9 snapshot
    dw $FF16                ; $16 refresh_sprites: Redraw the sprites and the screen position (one tick)
    dw $FF15                ; $15 check_and_branch: If “the Starry Night scene selector” is 1 → Bank0C_ScriptAddr_45AC  [$CAB9 = 1]
    dw $CAB9                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_45AC ;   target
    dw $FF21                ; $21 sound: Sound effect $00
    dw $0000                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 8 is shown
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF48                ; $48 face_down: NPC 7 faces down
    dw $0007                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 2-3 hidden  [$C8ED := 13]
    dw $C8ED                ;   address
    dw $000D                ;   value
    dw $FF0D                ; $0D npc_write: NPC 8 is hidden
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 8: x low byte := 248
    dw $0008                ;   actor
    dw $0018                ;   field
    dw $00F8                ;   value
    dw $FF15                ; $15 check_and_branch: If “the Starry Night scene selector” is 2 → Bank0C_ScriptAddr_45AC  [$CAB9 = 2]
    dw $CAB9                ;   address
    dw $0002                ;   value
    dw Bank0C_ScriptAddr_45AC ;   target
    dw $FF21                ; $21 sound: Sound effect $00
    dw $0000                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 8 is shown
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 3 hidden  [$C8ED := 9]
    dw $C8ED                ;   address
    dw $0009                ;   value
    dw $FF0D                ; $0D npc_write: NPC 8 is hidden
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 8: x low byte := 248
    dw $0008                ;   actor
    dw $0018                ;   field
    dw $00F8                ;   value
    dw $FF0D                ; $0D npc_write: NPC 8: y low byte := 88
    dw $0008                ;   actor
    dw $001A                ;   field
    dw $0058                ;   value
Bank0C_ScriptAddr_45AC:
    dw $FF21                ; $21 sound: Sound effect $00
    dw $0000                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 8 is shown
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF15                ; $15 check_and_branch: If “the Starry Night scene selector” is 1 → Bank0C_ScriptAddr_45F0  [$CAB9 = 1]
    dw $CAB9                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_45F0 ;   target
    dw $FF15                ; $15 check_and_branch: If “the Starry Night scene selector” is 2 → Bank0C_ScriptAddr_45F0  [$CAB9 = 2]
    dw $CAB9                ;   address
    dw $0002                ;   value
    dw Bank0C_ScriptAddr_45F0 ;   target
    dw $FF4A                ; $4A face_right: NPC 7 faces right
    dw $0007                ;   actor
Bank0C_ScriptAddr_45F0:
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF0D                ; $0D npc_write: NPC 8 is hidden
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 7: hop
    dw $0107                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: NPC 7 faces down
    dw $0007                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 7: jump
    dw $0407                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 7 is hidden
    dw $0007                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05B9                ; text $05B9: "King:I have prepared a prize for your vi…"
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks right 1 tile (script waits)
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $50E2)
    dw Bank0C_TilePatch_50E2 ;   data
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF03                ; $03 set_flag: Set flag $00F1
    dw $00F1                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 5  [$D92B := 5]
    dw $D92B                ;   address
    dw $0005                ;   value
    dw $FF12                ; $12 write_ram: Room state of Castle screen 5 (+8 room variant(s) sharing it) → state 4  [$D92C := 4]
    dw $D92C                ;   address
    dw $0004                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 0 → state 3  [$D92D := 3]
    dw $D92D                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 12 → state 2  [$D933 := 2]
    dw $D933                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 13 → state 2  [$D934 := 2]
    dw $D934                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_46EE:
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks right 1 tile (script waits)
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $50E2)
    dw Bank0C_TilePatch_50E2 ;   data
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks left 1 tile (script waits)
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0C_ScriptAddr_479A
    dw $00EE                ;   flag
    dw Bank0C_ScriptAddr_479A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_47B6
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_47B6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0C_ScriptAddr_479A
    dw $0033                ;   flag
    dw Bank0C_ScriptAddr_479A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0C_ScriptAddr_47A2
    dw $0030                ;   flag
    dw Bank0C_ScriptAddr_47A2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0007 is set → Bank0C_ScriptAddr_479A
    dw $0007                ;   flag
    dw Bank0C_ScriptAddr_479A ;   target
Bank0C_ScriptAddr_479A:
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_47A2:
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $014C                ; text $014C: "*:The Room of Villager & Talisman is in …"
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_47B6:
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0416                ; text $0416: "*:Oh Monster Master [HERO]! GreatTree is…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF12                ; $12 write_ram: The game mode: the bank $02 picture scenes (the ceremony, the tree)  [$C88A := 3]
    dw $C88A                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: The next game mode: the bank $02 picture scenes (the ceremony, the tree)  [$C88B := 3]
    dw $C88B                ;   address
    dw $0003                ;   value
    dw $FF3E                ; $3E change_game_mode: Fade out and switch to the game mode in $C88B (e.g. a naming screen) — $C88E is the main loop's mode request
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0417                ; text $0417: "*:I assume GreatTree is encouraging you …"
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_47E0:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF12                ; $12 write_ram: All field sprites hidden: shown  [$C8EC := 0]
    dw $C8EC                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: the monsters hidden (Terry shown)  [$C8ED := 14]
    dw $C8ED                ;   address
    dw $000E                ;   value
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_4804
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_4804 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0C_ScriptAddr_4970
    dw $0033                ;   flag
    dw Bank0C_ScriptAddr_4970 ;   target
; ---- $0C:$4804 (S101 r3, PyBoy-measured) — CASTLE ARRIVAL, $D92B = 7 (a gate boss
; was beaten): the King's speech chain. cond_branch $D9E3 == code -> that gate's
; speech ($30 Healer … $4E DeathMore, $C7 Sidoh, $10 Copycat; the vanilla boss win
; tails write the code). No saved flag changes in any speech; each ends with
; $D92B := 3 (or 5 for the post-game codes). An unknown code falls to the $490A
; priest path. The editor's helper step "at the Castle: King's speech" writes
; $D9E3 + $D92B = 7 before its $3B warp (PROJECT_COMPILER §2.18).
Bank0C_ScriptAddr_4804:
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 78  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4EC6  [$D9E3 = 78]
    dw $D9E3                ;   address
    dw $004E                ;   value
    dw Bank0C_ScriptAddr_4EC6 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 77  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4EBC  [$D9E3 = 77]
    dw $D9E3                ;   address
    dw $004D                ;   value
    dw Bank0C_ScriptAddr_4EBC ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 76  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4EB2  [$D9E3 = 76]
    dw $D9E3                ;   address
    dw $004C                ;   value
    dw Bank0C_ScriptAddr_4EB2 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 75  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4EA8  [$D9E3 = 75]
    dw $D9E3                ;   address
    dw $004B                ;   value
    dw Bank0C_ScriptAddr_4EA8 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 74  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4E9E  [$D9E3 = 74]
    dw $D9E3                ;   address
    dw $004A                ;   value
    dw Bank0C_ScriptAddr_4E9E ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 73  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4E94  [$D9E3 = 73]
    dw $D9E3                ;   address
    dw $0049                ;   value
    dw Bank0C_ScriptAddr_4E94 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 72  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4E8A  [$D9E3 = 72]
    dw $D9E3                ;   address
    dw $0048                ;   value
    dw Bank0C_ScriptAddr_4E8A ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 199  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4E80  [$D9E3 = 199]
    dw $D9E3                ;   address
    dw $00C7                ;   value
    dw Bank0C_ScriptAddr_4E80 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 71  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4E76  [$D9E3 = 71]
    dw $D9E3                ;   address
    dw $0047                ;   value
    dw Bank0C_ScriptAddr_4E76 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 70  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4E48  [$D9E3 = 70]
    dw $D9E3                ;   address
    dw $0046                ;   value
    dw Bank0C_ScriptAddr_4E48 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 69  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4C98  [$D9E3 = 69]
    dw $D9E3                ;   address
    dw $0045                ;   value
    dw Bank0C_ScriptAddr_4C98 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_4980
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_4980 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 68  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4C8E  [$D9E3 = 68]
    dw $D9E3                ;   address
    dw $0044                ;   value
    dw Bank0C_ScriptAddr_4C8E ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 67  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4C84  [$D9E3 = 67]
    dw $D9E3                ;   address
    dw $0043                ;   value
    dw Bank0C_ScriptAddr_4C84 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 66  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4C58  [$D9E3 = 66]
    dw $D9E3                ;   address
    dw $0042                ;   value
    dw Bank0C_ScriptAddr_4C58 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 65  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4C2C  [$D9E3 = 65]
    dw $D9E3                ;   address
    dw $0041                ;   value
    dw Bank0C_ScriptAddr_4C2C ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 63  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4C22  [$D9E3 = 63]
    dw $D9E3                ;   address
    dw $003F                ;   value
    dw Bank0C_ScriptAddr_4C22 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 62  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4BF6  [$D9E3 = 62]
    dw $D9E3                ;   address
    dw $003E                ;   value
    dw Bank0C_ScriptAddr_4BF6 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 61  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4BEC  [$D9E3 = 61]
    dw $D9E3                ;   address
    dw $003D                ;   value
    dw Bank0C_ScriptAddr_4BEC ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 59  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4BE2  [$D9E3 = 59]
    dw $D9E3                ;   address
    dw $003B                ;   value
    dw Bank0C_ScriptAddr_4BE2 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 58  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4BB6  [$D9E3 = 58]
    dw $D9E3                ;   address
    dw $003A                ;   value
    dw Bank0C_ScriptAddr_4BB6 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 16  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4BAC  [$D9E3 = 16]
    dw $D9E3                ;   address
    dw $0010                ;   value
    dw Bank0C_ScriptAddr_4BAC ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 57  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4B80  [$D9E3 = 57]
    dw $D9E3                ;   address
    dw $0039                ;   value
    dw Bank0C_ScriptAddr_4B80 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 60  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4AF0  [$D9E3 = 60]
    dw $D9E3                ;   address
    dw $003C                ;   value
    dw Bank0C_ScriptAddr_4AF0 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 56  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4AE6  [$D9E3 = 56]
    dw $D9E3                ;   address
    dw $0038                ;   value
    dw Bank0C_ScriptAddr_4AE6 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 55  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4ADC  [$D9E3 = 55]
    dw $D9E3                ;   address
    dw $0037                ;   value
    dw Bank0C_ScriptAddr_4ADC ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 54  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4AB0  [$D9E3 = 54]
    dw $D9E3                ;   address
    dw $0036                ;   value
    dw Bank0C_ScriptAddr_4AB0 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 53  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4A84  [$D9E3 = 53]
    dw $D9E3                ;   address
    dw $0035                ;   value
    dw Bank0C_ScriptAddr_4A84 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 52  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4A7A  [$D9E3 = 52]
    dw $D9E3                ;   address
    dw $0034                ;   value
    dw Bank0C_ScriptAddr_4A7A ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 51  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4A4E  [$D9E3 = 51]
    dw $D9E3                ;   address
    dw $0033                ;   value
    dw Bank0C_ScriptAddr_4A4E ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 50  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4A44  [$D9E3 = 50]
    dw $D9E3                ;   address
    dw $0032                ;   value
    dw Bank0C_ScriptAddr_4A44 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 49  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_4A18  [$D9E3 = 49]
    dw $D9E3                ;   address
    dw $0031                ;   value
    dw Bank0C_ScriptAddr_4A18 ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 48  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_49AC  [$D9E3 = 48]
    dw $D9E3                ;   address
    dw $0030                ;   value
    dw Bank0C_ScriptAddr_49AC ;   target
Bank0C_ScriptAddr_490A:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF12                ; $12 write_ram: All field sprites hidden: shown  [$C8EC := 0]
    dw $C8EC                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: the monsters hidden (Terry shown)  [$C8ED := 14]
    dw $C8ED                ;   address
    dw $000E                ;   value
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0C_ScriptAddr_4930
    dw $0009                ;   flag
    dw Bank0C_ScriptAddr_4930 ;   target
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
Bank0C_ScriptAddr_4930:
    dw $FF00                ; $00 if_flag_clear: If flag $00F1 is clear → Bank0C_ScriptAddr_4946
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_4946 ;   target
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
Bank0C_ScriptAddr_4946:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 5  [$D92B := 5]
    dw $D92B                ;   address
    dw $0005                ;   value
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_4966
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_4966 ;   target
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0C_ScriptAddr_4966
    dw $0009                ;   flag
    dw Bank0C_ScriptAddr_4966 ;   target
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 1  [$D92B := 1]
    dw $D92B                ;   address
    dw $0001                ;   value
Bank0C_ScriptAddr_4966:
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 255  [$D9E3 := 255]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $00FF                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_5000
    dw Bank0C_ScriptAddr_5000 ;   target
Bank0C_ScriptAddr_4970:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0275                ; text $0275: "King:[HERO]! Its okay to go to other Tra…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4980:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05C5                ; text $05C5: "King:Oh [HERO] You have good intentions!…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $07CE                ; text $07CE: "King:No, it's not an exaggeration. I'd d…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 5  [$D92B := 5]
    dw $D92B                ;   address
    dw $0005                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4ED6
    dw Bank0C_ScriptAddr_4ED6 ;   target
Bank0C_ScriptAddr_49AC:
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $005A                ; text $005A: "King:Oh, [HERO]! Did you bring back Hale…"
    dw $FF1C                ; $1C trigger_anim: NPC 4: jump
    dw $0404                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $005B                ; text $005B: "Pulio:Thank you [HERO]! Now I can go bac…"
    dw $FF0B                ; $0B walk_y_wait: NPC 4 walks down 2 tiles (script waits)
    dw $0004                ;   actor
    dw $0020                ;   pixels
    dw $FF0D                ; $0D npc_write: NPC 4 is hidden
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $005C                ; text $005C: "King:[HERO]. Go to the arena. King:Your …"
    dw $FF03                ; $03 set_flag: Set flag $0009
    dw $0009                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Castle screen 5 (+8 room variant(s) sharing it) → state 4  [$D92C := 4]
    dw $D92C                ;   address
    dw $0004                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 0 → state 2  [$D92D := 2]
    dw $D92D                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 4 → state 1  [$D92F := 1]
    dw $D92F                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 1 → state 2  [$D93C := 2]
    dw $D93C                ;   address
    dw $0002                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4A18:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $014D                ; text $014D: "King:Oh [HERO]! You beat the Dragon! Kin…"
Bank0C_ScriptAddr_4A1E:
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $014E                ; text $014E: "King:Well maybe I'm exaggerating a littl…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4A44:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0151                ; text $0151: "King:Oh [HERO]! You beat Golem! King:Wel…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4A1E
    dw Bank0C_ScriptAddr_4A1E ;   target
Bank0C_ScriptAddr_4A4E:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $01AB                ; text $01AB: "King:Oh [HERO]! You beat MadCat! King:Th…"
Bank0C_ScriptAddr_4A54:
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $01AC                ; text $01AC: "King:It reminds me. Have you been going …"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4A7A:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $01AE                ; text $01AE: "King:Oh [HERO]! You defeated FaceTree! K…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4A54
    dw Bank0C_ScriptAddr_4A54 ;   target
Bank0C_ScriptAddr_4A84:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $021A                ; text $021A: "King:Oh [HERO]! You beat MadKnight! King…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $014E                ; text $014E: "King:Well maybe I'm exaggerating a littl…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4AB0:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $01F4                ; text $01F4: "King:Oh,[HERO] you beat FangSlime! King:…"
Bank0C_ScriptAddr_4AB6:
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $01AC                ; text $01AC: "King:It reminds me. Have you been going …"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4ADC:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $01F2                ; text $01F2: "King:Oh [HERO]! You beat BigEye! King:Wh…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4AB6
    dw Bank0C_ScriptAddr_4AB6 ;   target
Bank0C_ScriptAddr_4AE6:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $03B6                ; text $03B6: "King:Oh, [HERO] You beat Gigantes! King:…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4AB6
    dw Bank0C_ScriptAddr_4AB6 ;   target
Bank0C_ScriptAddr_4AF0:
    dw $FF0D                ; $0D npc_write: NPC 6 is shown
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02A9                ; text $02A9: "King:Oh [HERO]!! Welcome back! King:I he…"
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks up 1 tile (script waits)
    dw $0006                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks up 1 tile (script waits)
    dw $0006                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks up 1 tile (script waits)
    dw $0006                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02AA                ; text $02AA: "*:Oh... This kingdom is full of energy. …"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF49                ; $49 face_left: NPC 6 faces left
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02AB                ; text $02AB: "*:You look especially merry. Are you a s…"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF47                ; $47 face_up: NPC 6 faces up
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02AC                ; text $02AC: "DeadTree King:... King of GreatTree, hav…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF48                ; $48 face_down: NPC 6 faces down
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks down 1 tile (script waits)
    dw $0006                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks down 1 tile (script waits)
    dw $0006                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks down 1 tile (script waits)
    dw $0006                ;   actor
    dw $0010                ;   pixels
    dw $FF0D                ; $0D npc_write: NPC 6 is hidden
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02AD                ; text $02AD: "King:DeadTree! You will see! King:...[HE…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4B80:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02B6                ; text $02B6: "King:Oh, [HERO] You beat StoneMan! King:…"
Bank0C_ScriptAddr_4B86:
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0863                ; text $0863: "King:Hmm. It's an exaggeration. King:I a…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4BAC:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0150                ; text $0150: "King:Oh [HERO]! You beat CopyCat! King:C…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4B86
    dw Bank0C_ScriptAddr_4B86 ;   target
Bank0C_ScriptAddr_4BB6:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0337                ; text $0337: "King:Well done, [HERO]! You defeated Sky…"
Bank0C_ScriptAddr_4BBC:
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02B7                ; text $02B7: "King:Well [HERO]. Are you talking to the…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4BE2:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $033A                ; text $033A: "King:Well done, [HERO]! You defeated Fun…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4BBC
    dw Bank0C_ScriptAddr_4BBC ;   target
Bank0C_ScriptAddr_4BEC:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $033B                ; text $033B: "King:Well done, [HERO]! You defeated Dig…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4BBC
    dw Bank0C_ScriptAddr_4BBC ;   target
Bank0C_ScriptAddr_4BF6:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0366                ; text $0366: "King:Oh [HERO]! You beat Jamirus. King:O…"
Bank0C_ScriptAddr_4BFC:
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0367                ; text $0367: "King:[HERO], At ease. King:It's a good i…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4C22:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0369                ; text $0369: "King:Oh [HERO]! You beat Servant! King:W…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4BFC
    dw Bank0C_ScriptAddr_4BFC ;   target
Bank0C_ScriptAddr_4C2C:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0140                ; text $0140: "King:Well done, [HERO]! You beat another…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0142                ; text $0142: "King:Train hard! You're dismissed. King:…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4C58:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $03E5                ; text $03E5: "King:Oh, [HERO]! You beat DarkHorn! King…"
Bank0C_ScriptAddr_4C5E:
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0367                ; text $0367: "King:[HERO], At ease. King:It's a good i…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4F6A
    dw Bank0C_ScriptAddr_4F6A ;   target
Bank0C_ScriptAddr_4C84:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $03E6                ; text $03E6: "King:Oh, [HERO]! You beat Akubar! King:I…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4C5E
    dw Bank0C_ScriptAddr_4C5E ;   target
Bank0C_ScriptAddr_4C8E:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $036A                ; text $036A: "King:Oh, [HERO]! You beat Orochi! King:T…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4C5E
    dw Bank0C_ScriptAddr_4C5E ;   target
Bank0C_ScriptAddr_4C98:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0485                ; text $0485: "King:[HERO]! How was it? What lies in yo…"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF41                ; $41 set_bgm: Music $02
    dw $0002                ;   song
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 2-0-2-3 (0 light … 3 dark)  [$C89D := 226]
    dw $C89D                ;   address
    dw $00E2                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 3-1-2-3 (0 light … 3 dark)  [$C89B := 231]
    dw $C89B                ;   address
    dw $00E7                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 3-1-2-3 (0 light … 3 dark)  [$C89C := 231]
    dw $C89C                ;   address
    dw $00E7                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 3-1-3-3 (0 light … 3 dark)  [$C89D := 247]
    dw $C89D                ;   address
    dw $00F7                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 3-2-3-3 (0 light … 3 dark)  [$C89B := 251]
    dw $C89B                ;   address
    dw $00FB                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 3-2-3-3 (0 light … 3 dark)  [$C89C := 251]
    dw $C89C                ;   address
    dw $00FB                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 3-2-3-3 (0 light … 3 dark)  [$C89D := 251]
    dw $C89D                ;   address
    dw $00FB                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): all black  [$C89B := 255]
    dw $C89B                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): all black  [$C89D := 255]
    dw $C89D                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: All field sprites hidden: hidden  [$C8EC := 1]
    dw $C8EC                ;   address
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF62                ; $62 blank_screen: Fill tile $DA with $FF and the whole background map with it
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $08D1                ; text $08D1: "The Starry Night is coming soon. The who…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF12                ; $12 write_ram: The background palette (fade): all black  [$C89B := 255]
    dw $C89B                ;   address
    dw $00FF                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF63                ; $63 draw_buffer: Copy the 20x16 $C300 buffer onto the visible background
    dw $FF27                ; $27 refresh_party: Heal every monster — HP and MP to full, ailments cured (bank $01 entry 9 IteratePartySlots20 over the 20 slots, PyBoy-measured S125), then entry 3
    dw $FF16                ; $16 refresh_sprites: Redraw the sprites and the screen position (one tick)
    dw $FF41                ; $41 set_bgm: Music $3F
    dw $003F                ;   song
    dw $FF46                ; $46 wait_dungeon_flags: Wait until the running effect / animation finishes
    dw $FF09                ; $09 delay: Wait 24 ticks (~192 frames)
    dw $0018                ;   ticks
    dw $FF12                ; $12 write_ram: All field sprites hidden: shown  [$C8EC := 0]
    dw $C8EC                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The background palette (fade): all black  [$C89B := 255]
    dw $C89B                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): all black  [$C89D := 255]
    dw $C89D                ;   address
    dw $00FF                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 3-2-3-3 (0 light … 3 dark)  [$C89B := 251]
    dw $C89B                ;   address
    dw $00FB                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 3-2-3-3 (0 light … 3 dark)  [$C89C := 251]
    dw $C89C                ;   address
    dw $00FB                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 3-2-3-3 (0 light … 3 dark)  [$C89D := 251]
    dw $C89D                ;   address
    dw $00FB                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 3-1-2-3 (0 light … 3 dark)  [$C89B := 231]
    dw $C89B                ;   address
    dw $00E7                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 3-1-2-3 (0 light … 3 dark)  [$C89C := 231]
    dw $C89C                ;   address
    dw $00E7                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 3-1-3-3 (0 light … 3 dark)  [$C89D := 247]
    dw $C89D                ;   address
    dw $00F7                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 2-0-2-3 (0 light … 3 dark)  [$C89D := 226]
    dw $C89D                ;   address
    dw $00E2                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF41                ; $41 set_bgm: Music $09
    dw $0009                ;   song
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0486                ; text $0486: "King:Oh [HERO]! Did you rest? King:Tonig…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0488                ; text $0488: "King:Anyway! Your wish will come true wh…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 3  [$D92B := 3]
    dw $D92B                ;   address
    dw $0003                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks right 1 tile (script waits)
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $50E2)
    dw Bank0C_TilePatch_50E2 ;   data
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks left 1 tile (script waits)
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FFFF                ; END
Bank0C_ScriptAddr_4E48:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05C2                ; text $05C2: "King:Oh, [HERO]! You beat DracoLord!"
Bank0C_ScriptAddr_4E4E:
    dw $05C3                ; text $05C3: "King:You could beat an evil lord. King:I…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0141                ; text $0141: "*:Oh...King..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05C4                ; text $05C4: "King:Just kidding! King:Ha ha ha ha! Wor…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 5  [$D92B := 5]
    dw $D92B                ;   address
    dw $0005                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4ED6
    dw Bank0C_ScriptAddr_4ED6 ;   target
Bank0C_ScriptAddr_4E76:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05C6                ; text $05C6: "King:Oh [HERO]! You beat Hargon!"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4E4E
    dw Bank0C_ScriptAddr_4E4E ;   target
Bank0C_ScriptAddr_4E80:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05C7                ; text $05C7: "King:Oh [HERO]! You beat Sidoh!"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4E4E
    dw Bank0C_ScriptAddr_4E4E ;   target
Bank0C_ScriptAddr_4E8A:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05C8                ; text $05C8: "King:Oh [HERO]! You beat Baramos!"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4E4E
    dw Bank0C_ScriptAddr_4E4E ;   target
Bank0C_ScriptAddr_4E94:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05C9                ; text $05C9: "King:Oh [HERO]! You beat Zoma!"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4E4E
    dw Bank0C_ScriptAddr_4E4E ;   target
Bank0C_ScriptAddr_4E9E:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05CA                ; text $05CA: "King:Oh [HERO]! You beat Pizzaro!"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4E4E
    dw Bank0C_ScriptAddr_4E4E ;   target
Bank0C_ScriptAddr_4EA8:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05CB                ; text $05CB: "King:Oh [HERO]! You beat Esterk!"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4E4E
    dw Bank0C_ScriptAddr_4E4E ;   target
Bank0C_ScriptAddr_4EB2:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05CC                ; text $05CC: "King:Oh [HERO]! You beat Mirudraas!"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4E4E
    dw Bank0C_ScriptAddr_4E4E ;   target
Bank0C_ScriptAddr_4EBC:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05CD                ; text $05CD: "King:Oh [HERO]! You beat Mudou!"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4E4E
    dw Bank0C_ScriptAddr_4E4E ;   target
Bank0C_ScriptAddr_4EC6:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05CE                ; text $05CE: "King:Oh [HERO]! You beat DeathMore! King…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 5  [$D92B := 5]
    dw $D92B                ;   address
    dw $0005                ;   value
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_4ED6
    dw Bank0C_ScriptAddr_4ED6 ;   target
Bank0C_ScriptAddr_4ED6:
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks right 1 tile (script waits)
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $50E2)
    dw Bank0C_TilePatch_50E2 ;   data
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_5000
    dw Bank0C_ScriptAddr_5000 ;   target
Bank0C_ScriptAddr_4F6A:
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks right 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks right 1 tile (script waits)
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $50E2)
    dw Bank0C_TilePatch_50E2 ;   data
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks left 1 tile (script waits)
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
Bank0C_ScriptAddr_5000:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $004E                ; text $004E: "*:Give the courageous master [HERO] the …"
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): all black  [$C89D := 255]
    dw $C89D                ;   address
    dw $00FF                ;   value
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 2-0-2-3 (0 light … 3 dark)  [$C89D := 226]
    dw $C89D                ;   address
    dw $00E2                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 1-3-2-0 (0 light … 3 dark)  [$C89B := 45]
    dw $C89B                ;   address
    dw $002D                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): all black  [$C89D := 255]
    dw $C89D                ;   address
    dw $00FF                ;   value
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 2-0-2-3 (0 light … 3 dark)  [$C89D := 226]
    dw $C89D                ;   address
    dw $00E2                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF27                ; $27 refresh_party: Heal every monster — HP and MP to full, ailments cured (bank $01 entry 9 IteratePartySlots20 over the 20 slots, PyBoy-measured S125), then entry 3
    dw $FF16                ; $16 refresh_sprites: Redraw the sprites and the screen position (one tick)
; ---- $0C:$5066 (S101 r3, ROM scan) — the ONLY other $D9E3 reader: a castle NPC's
; talk. $30 -> "These stairs go up to the monster farm"; $3C -> write $C88A/$C88B
; = 3, op $3E, "The shaking of GreatTree has changed…" (story event); else the herb
; gift (give_item 1, or the inventory-full line).
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 48  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_508A  [$D9E3 = 48]
    dw $D9E3                ;   address
    dw $0030                ;   value
    dw Bank0C_ScriptAddr_508A ;   target
    dw $FF15                ; $15 check_and_branch: If “the King's speech for the next Castle arrival” is 60  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_5090  [$D9E3 = 60]
    dw $D9E3                ;   address
    dw $003C                ;   value
    dw Bank0C_ScriptAddr_5090 ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_5084
    dw Bank0C_ScriptAddr_5084 ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $08CB                ; text $08CB: "*:For [HERO]'s safe journey, I'll give y…"
    dw $FF2A                ; $2A give_item: Give item 1
    dw $0001                ;   item
    dw $FFFF                ; END
Bank0C_ScriptAddr_5084:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $08CC                ; text $08CC: "*:For [HERO]'s safe journey, I'll give y…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_508A:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $005E                ; text $005E: "*:To get to the arena, go straight out o…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5090:
    dw $FF12                ; $12 write_ram: The game mode: the bank $02 picture scenes (the ceremony, the tree)  [$C88A := 3]
    dw $C88A                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: The next game mode: the bank $02 picture scenes (the ceremony, the tree)  [$C88B := 3]
    dw $C88B                ;   address
    dw $0003                ;   value
    dw $FF3E                ; $3E change_game_mode: Fade out and switch to the game mode in $C88B (e.g. a naming screen) — $C88E is the main loop's mode request
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02AE                ; text $02AE: "*:This shaking is evidence of the growth…"
    dw $FFFF                ; END
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0C_ScriptAddr_50A8:
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0B                ; $0B walk_y_wait: NPC 4 walks down 2 tiles (script waits)
    dw $0004                ;   actor
    dw $0020                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05B7                ; text $05B7: "*:Oh, Monster Master [HERO]! Where have …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 9 tiles
    dw $0004                ;   actor
    dw $FF70                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 9 tiles
    dw $0005                ;   actor
    dw $FF70                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF12                ; $12 write_ram: Room state of Castle screen 5 (+8 room variant(s) sharing it) → state 3  [$D92C := 3]
    dw $D92C                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 0 → state 4  [$D92D := 4]
    dw $D92D                ;   address
    dw $0004                ;   value
    dw $FF0F                ; $0F map_transition: Go to Castle at (14, 7)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0078                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0C_TilePatch_50E2:
    db $2E, $00, $44, $45, $D8, $70, $71, $D8, $72, $73, $D9  ; tile patch (op $24): BG offset $002E (row 1, column 14), tiles 44 45 / 70 71 / 72 73; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Castle_Script01
; ---------------------------------------------------------------------------
Castle_Script01:
    dw $0024                ; text $0024: "[HERO] looked at the bookshelf. :The Kin…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_50FB  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_50FB ;   target
    dw $0025                ; text $0025: ":It's a little kingdom built inside a bi…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_50FB:
    dw $0026                ; text $0026: "[HERO] returned the book to the bookshel…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script02
; ---------------------------------------------------------------------------
Castle_Script02:
    dw $0027                ; text $0027: "[HERO] looked at the bookshelf. The Mast…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_510D  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_510D ;   target
    dw $0028                ; text $0028: ":People who understand monster talk and …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_510D:
    dw $0026                ; text $0026: "[HERO] returned the book to the bookshel…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script03
; ---------------------------------------------------------------------------
Castle_Script03:
    dw $FF01                ; $01 if_flag_set: If flag $003A is set → Bank0C_ScriptAddr_5183
    dw $003A                ;   flag
    dw Bank0C_ScriptAddr_5183 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $003B is set → Bank0C_ScriptAddr_5155
    dw $003B                ;   flag
    dw Bank0C_ScriptAddr_5155 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0008 is set → Bank0C_ScriptAddr_5127
    dw $0008                ;   flag
    dw Bank0C_ScriptAddr_5127 ;   target
    dw $0379                ; text $0379: "[HERO] checked out the treasure chest! I…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5127:
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5187)
    dw Bank0C_TilePatch_5187 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $001B                ; text $001B: "[HERO] opened a treasure chest!"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_5149
    dw Bank0C_ScriptAddr_5149 ;   target
    dw $001C                ; text $001C: "[HERO] picked up an Herb."
    dw $FF03                ; $03 set_flag: Set flag $003A
    dw $003A                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 0 (+8 room variant(s) sharing it) → state 1  [$D92A := 1]
    dw $D92A                ;   address
    dw $0001                ;   value
    dw $FF2A                ; $2A give_item: Give item 1
    dw $0001                ;   item
    dw $FFFF                ; END

Bank0C_ScriptAddr_5149:
    dw $001D                ; text $001D: "[HERO] found an Herb. But cannot carry a…"
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $518C)
    dw Bank0C_TilePatch_518C ;   data
    dw $FFFF                ; END
Bank0C_ScriptAddr_5155:
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5187)
    dw Bank0C_TilePatch_5187 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $001B                ; text $001B: "[HERO] opened a treasure chest!"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_5177
    dw Bank0C_ScriptAddr_5177 ;   target
    dw $001C                ; text $001C: "[HERO] picked up an Herb."
    dw $FF03                ; $03 set_flag: Set flag $003A
    dw $003A                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 0 (+8 room variant(s) sharing it) → state 3  [$D92A := 3]
    dw $D92A                ;   address
    dw $0003                ;   value
    dw $FF2A                ; $2A give_item: Give item 1
    dw $0001                ;   item
    dw $FFFF                ; END

Bank0C_ScriptAddr_5177:
    dw $001D                ; text $001D: "[HERO] found an Herb. But cannot carry a…"
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $518C)
    dw Bank0C_TilePatch_518C ;   data
    dw $FFFF                ; END
Bank0C_ScriptAddr_5183:
    dw $013C                ; text $013C: "[HERO] looked in the treasure chest It w…"
    dw $FFFF                ; END

Bank0C_TilePatch_5187:
    db $86, $00, $0C, $0D, $D9  ; tile patch (op $24): BG offset $0086 (row 4, column 6), tiles 0C 0D; $D8 = next row, $D9 = end
Bank0C_TilePatch_518C:
    db $86, $00, $0E, $0F, $D9  ; tile patch (op $24): BG offset $0086 (row 4, column 6), tiles 0E 0F; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Castle_Script04
; ---------------------------------------------------------------------------
Castle_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $003B is set → Bank0C_ScriptAddr_5203
    dw $003B                ;   flag
    dw Bank0C_ScriptAddr_5203 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $003A is set → Bank0C_ScriptAddr_51D5
    dw $003A                ;   flag
    dw Bank0C_ScriptAddr_51D5 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0008 is set → Bank0C_ScriptAddr_51A7
    dw $0008                ;   flag
    dw Bank0C_ScriptAddr_51A7 ;   target
    dw $0379                ; text $0379: "[HERO] checked out the treasure chest! I…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_51A7:
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5207)
    dw Bank0C_TilePatch_5207 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $001E                ; text $001E: "[HERO] opened a treasure chest!"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_51C9
    dw Bank0C_ScriptAddr_51C9 ;   target
    dw $0127                ; text $0127: "[HERO] got an Herb."
    dw $FF03                ; $03 set_flag: Set flag $003B
    dw $003B                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 0 (+8 room variant(s) sharing it) → state 2  [$D92A := 2]
    dw $D92A                ;   address
    dw $0002                ;   value
    dw $FF2A                ; $2A give_item: Give item 1
    dw $0001                ;   item
    dw $FFFF                ; END

Bank0C_ScriptAddr_51C9:
    dw $0128                ; text $0128: "[HERO] found an Herb. But cannot carry a…"
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $520C)
    dw Bank0C_TilePatch_520C ;   data
    dw $FFFF                ; END
Bank0C_ScriptAddr_51D5:
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5207)
    dw Bank0C_TilePatch_5207 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $001E                ; text $001E: "[HERO] opened a treasure chest!"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_51F7
    dw Bank0C_ScriptAddr_51F7 ;   target
    dw $0127                ; text $0127: "[HERO] got an Herb."
    dw $FF03                ; $03 set_flag: Set flag $003B
    dw $003B                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 0 (+8 room variant(s) sharing it) → state 3  [$D92A := 3]
    dw $D92A                ;   address
    dw $0003                ;   value
    dw $FF2A                ; $2A give_item: Give item 1
    dw $0001                ;   item
    dw $FFFF                ; END

Bank0C_ScriptAddr_51F7:
    dw $0128                ; text $0128: "[HERO] found an Herb. But cannot carry a…"
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $520C)
    dw Bank0C_TilePatch_520C ;   data
    dw $FFFF                ; END
Bank0C_ScriptAddr_5203:
    dw $013C                ; text $013C: "[HERO] looked in the treasure chest It w…"
    dw $FFFF                ; END

Bank0C_TilePatch_5207:
    db $88, $00, $0C, $0D, $D9  ; tile patch (op $24): BG offset $0088 (row 4, column 8), tiles 0C 0D; $D8 = next row, $D9 = end
Bank0C_TilePatch_520C:
    db $88, $00, $0E, $0F, $D9  ; tile patch (op $24): BG offset $0088 (row 4, column 8), tiles 0E 0F; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Castle_Script05
; ---------------------------------------------------------------------------
Castle_Script05:
    dw $083B                ; text $083B: "*:[HERO] looked in front."
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_521F
    dw Bank0C_ScriptAddr_521F ;   target
    dw $083C                ; text $083C: "Wow, a Sirloin!"
    dw $FF2A                ; $2A give_item: Give item 23
    dw $0017                ;   item
    dw $FFFF                ; END

Bank0C_ScriptAddr_521F:
    dw $083D                ; text $083D: "Wow, found a Sirloin! But can't carry an…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script06
; ---------------------------------------------------------------------------
Castle_Script06:
    dw $083B                ; text $083B: "*:[HERO] looked in front."
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_5231
    dw Bank0C_ScriptAddr_5231 ;   target
    dw $083E                ; text $083E: "Got a WarpWing."
    dw $FF2A                ; $2A give_item: Give item 29
    dw $001D                ;   item
    dw $FFFF                ; END

Bank0C_ScriptAddr_5231:
    dw $083D                ; text $083D: "Wow, found a Sirloin! But can't carry an…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script07
; ---------------------------------------------------------------------------
Castle_Script07:
    dw $0840                ; text $0840: "Found 10,000G Got 10,000G"
    dw $FF33                ; $33 compare_gold: Give 10000 G
    dw $2710                ;   amount
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script08
; ---------------------------------------------------------------------------
Castle_Script08:
    dw $0841                ; text $0841: "A Slime appeared."
    dw $FF05                ; $05 battle: Battle: enemy row 480
    dw $01E0                ;   enemy
    dw $FF27                ; $27 refresh_party: Heal every monster — HP and MP to full, ailments cured (bank $01 entry 9 IteratePartySlots20 over the 20 slots, PyBoy-measured S125), then entry 3
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script09
; ---------------------------------------------------------------------------
Castle_Script09:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5273
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5273 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_526F
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_526F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_525D
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_525D ;   target
    dw $0023                ; text $0023: "*:I have a feeling that your victory wil…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_525D:
    dw $01E4                ; text $01E4: "*:Let me tell you. [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_526B  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_526B ;   target
    dw $01E6                ; text $01E6: "*:The family of the monster you chose fo…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_526B:
    dw $01E5                ; text $01E5: "*:We're the hosts. You have to win!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_526F:
    dw $040F                ; text $040F: "*:We clowns hustle on the Starry Night! …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5273:
    dw $05BB                ; text $05BB: "*:[HERO], thanks to you, it was the best…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script10
; ---------------------------------------------------------------------------
Castle_Script10:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_52CD
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_52CD ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0118 is set → Bank0C_ScriptAddr_52C9
    dw $0118                ;   flag
    dw Bank0C_ScriptAddr_52C9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_52AF
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_52AF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_529D
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_529D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0008 is set → Bank0C_ScriptAddr_5299
    dw $0008                ;   flag
    dw Bank0C_ScriptAddr_5299 ;   target
    dw $0022                ; text $0022: "*:Everybody will be happy if you become …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5299:
    dw $0053                ; text $0053: "*:When you enter the Travelers' Gates, y…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_529D:
    dw $01E7                ; text $01E7: "*:Want to learn about breeding monsters?…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_52AB  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_52AB ;   target
    dw $01E9                ; text $01E9: "*:When monsters from the same family are…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_52AB:
    dw $01E8                ; text $01E8: "*:Victories in the arena will allow you …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_52AF:
    dw $040B                ; text $040B: "*:Congratulations on your participation …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_52C1  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_52C1 ;   target
    dw $040C                ; text $040C: "*:Oh my! Monster Master [HERO]! I am not…"
    dw $FF03                ; $03 set_flag: Set flag $0118
    dw $0118                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_52C1:
    dw $040D                ; text $040D: "*:Even I can be of help? I'm touched!"
    dw $FF03                ; $03 set_flag: Set flag $0118
    dw $0118                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_52C9:
    dw $040E                ; text $040E: "*:Breeding two child-like devils creates…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_52CD:
    dw $05BA                ; text $05BA: "*:Sir [HERO], Thank you for the victory."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script11
; ---------------------------------------------------------------------------
Castle_Script11:
    dw $002A                ; text $002A: "King:The monster farm is on the upper le…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script12
; ---------------------------------------------------------------------------
Castle_Script12:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_52FD
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_52FD ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_52F9
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_52F9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_52F5
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_52F5 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0008 is set → Bank0C_ScriptAddr_52F1
    dw $0008                ;   flag
    dw Bank0C_ScriptAddr_52F1 ;   target
    dw $002F                ; text $002F: "*:The tournament is held on the Starry N…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_52F1:
    dw $004F                ; text $004F: "*:In the Chamber of Travelers' Gates exi…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_52F5:
    dw $01F5                ; text $01F5: "*:There's a reason why wild monsters don…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_52F9:
    dw $048C                ; text $048C: "*:Long long ago.. an ancestor of Watabou…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_52FD:
    dw $05C1                ; text $05C1: "*:Long long ago.. An ancestor of Watabou…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script13
; ---------------------------------------------------------------------------
Castle_Script13:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_54CD
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_54CD ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00AC is set → Bank0C_ScriptAddr_54BB
    dw $00AC                ;   flag
    dw Bank0C_ScriptAddr_54BB ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_54B3
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_54B3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_54A1
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_54A1 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0C_ScriptAddr_5473
    dw $0036                ;   flag
    dw Bank0C_ScriptAddr_5473 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_5445
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_5445 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0C_ScriptAddr_5417
    dw $0034                ;   flag
    dw Bank0C_ScriptAddr_5417 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_53E9
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_53E9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0C_ScriptAddr_53E5
    dw $0033                ;   flag
    dw Bank0C_ScriptAddr_53E5 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_53B7
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_53B7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0C_ScriptAddr_5389
    dw $0031                ;   flag
    dw Bank0C_ScriptAddr_5389 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0C_ScriptAddr_5369
    dw $0030                ;   flag
    dw Bank0C_ScriptAddr_5369 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0003 is set → Bank0C_ScriptAddr_5357
    dw $0003                ;   flag
    dw Bank0C_ScriptAddr_5357 ;   target
    dw $002C                ; text $002C: "*:Let me tell you about the legend of th…"
    dw $FF03                ; $03 set_flag: Set flag $0003
    dw $0003                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5357:
    dw $002D                ; text $002D: "*:Should I repeat the legend of the Star…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5365  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5365 ;   target
    dw $002E                ; text $002E: "*:Here it is again. *:The Starry Night c…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5365:
    dw $001A                ; text $001A: "*:I see....."
    dw $FFFF                ; END
Bank0C_ScriptAddr_5369:
    dw $0152                ; text $0152: "*:Are you familiar with the Gate of Vill…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5381  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5381 ;   target
    dw $0154                ; text $0154: "*:Are you familiar with the Gate of Tali…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5385  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5385 ;   target
    dw $0155                ; text $0155: "*:I see...Hm.."
    dw $FFFF                ; END

Bank0C_ScriptAddr_5381:
    dw $0153                ; text $0153: "*:Dragon loves girls.It carried a prince…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5385:
    dw $0156                ; text $0156: "*:The stone guard fell asleep from the f…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5389:
    dw $01A5                ; text $01A5: "*:Are you familiar with the Gate of Bewi…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_53AB  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_53AB ;   target
    dw $01A7                ; text $01A7: "*:Are you familiar with the Gate of Memo…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_53AF  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_53AF ;   target
    dw $01A9                ; text $01A9: "*:I would like to tell you more. Do you …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_53B3  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_53B3 ;   target
    dw $0155                ; text $0155: "*:I see...Hm.."
    dw $FFFF                ; END

Bank0C_ScriptAddr_53AB:
    dw $01A6                ; text $01A6: "*:My years of research lead me to believ…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_53AF:
    dw $01A8                ; text $01A8: "*:A monster is living deep in a cave. *:…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_53B3:
    dw $01AA                ; text $01AA: "*:The devil settled in a town of ruins. …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_53B7:
    dw $01EC                ; text $01EC: "*:Are you familiar with the Gate of Brav…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_53D9  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_53D9 ;   target
    dw $01EE                ; text $01EE: "Are you familiar with the Gate of Peace?…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_53DD  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_53DD ;   target
    dw $01A9                ; text $01A9: "*:I would like to tell you more. Do you …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_53E1  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_53E1 ;   target
    dw $0155                ; text $0155: "*:I see...Hm.."
    dw $FFFF                ; END

Bank0C_ScriptAddr_53D9:
    dw $01ED                ; text $01ED: "*:Despair is a part of hope! Hope is emb…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_53DD:
    dw $01EF                ; text $01EF: "*:Discretion is the better part of valor…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_53E1:
    dw $01F1                ; text $01F1: "*:In an enormous underground dungeon. *:…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_53E5:
    dw $0274                ; text $0274: "*:The number of monsters is increasing. …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_53E9:
    dw $02B0                ; text $02B0: "*:Are you familiar with the Gate of Ange…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_540B  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_540B ;   target
    dw $02B2                ; text $02B2: "*:Are you familiar with the Gate of Stre…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_540F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_540F ;   target
    dw $01A9                ; text $01A9: "*:I would like to tell you more. Do you …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5413  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5413 ;   target
    dw $0155                ; text $0155: "*:I see...Hm.."
    dw $FFFF                ; END

Bank0C_ScriptAddr_540B:
    dw $02B1                ; text $02B1: "*:The victor made countless eggs vanish …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_540F:
    dw $02B3                ; text $02B3: "*:I looked back and the stone statue was…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5413:
    dw $02B5                ; text $02B5: "*:Sometimes a lie makes people happy but…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5417:
    dw $0332                ; text $0332: "*:Do you know of the Gate of Wisdom? [YE…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5439  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5439 ;   target
    dw $0334                ; text $0334: "*:Are you familiar with the Gate of Joy?…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_543D  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_543D ;   target
    dw $01A9                ; text $01A9: "*:I would like to tell you more. Do you …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5441  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5441 ;   target
    dw $0155                ; text $0155: "*:I see...Hm.."
    dw $FFFF                ; END

Bank0C_ScriptAddr_5439:
    dw $0333                ; text $0333: "*:If you want to meet the Dragon, you sh…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_543D:
    dw $0335                ; text $0335: "*:A bird spins a round on the stage. *:I…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5441:
    dw $0336                ; text $0336: "*:A mysterious spring where mysterious s…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5445:
    dw $0361                ; text $0361: "Do you know of the Gate of Happiness? [Y…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5467  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5467 ;   target
    dw $0363                ; text $0363: "*:Are you familiar with the Gate of Temp…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_546B  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_546B ;   target
    dw $01A9                ; text $01A9: "*:I would like to tell you more. Do you …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_546F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_546F ;   target
    dw $0155                ; text $0155: "*:I see...Hm.."
    dw $FFFF                ; END

Bank0C_ScriptAddr_5467:
    dw $0362                ; text $0362: "*:In the kingdom I visited, there was a …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_546B:
    dw $0364                ; text $0364: "*:The legend of the village of Lifecod. …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_546F:
    dw $0365                ; text $0365: "*:Choose one of the three Gates! One is …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5473:
    dw $03E0                ; text $03E0: "*:Are you familiar with the Gate of Laby…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5495  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5495 ;   target
    dw $03E2                ; text $03E2: "*:Do you know of the Gate of Judgment? […"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5499  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5499 ;   target
    dw $01A9                ; text $01A9: "*:I would like to tell you more. Do you …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_549D  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_549D ;   target
    dw $0155                ; text $0155: "*:I see...Hm.."
    dw $FFFF                ; END

Bank0C_ScriptAddr_5495:
    dw $03E1                ; text $03E1: "*:A quote from the journal of a journey …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5499:
    dw $03E3                ; text $03E3: "*:A quote from the first victor of the t…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_549D:
    dw $03E4                ; text $03E4: "*:Far across the ocean, is the country o…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_54A1:
    dw $0419                ; text $0419: "*:Do you want me to tell you the legend …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_54AF  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_54AF ;   target
    dw $041B                ; text $041B: "*:Far beyond the Gate, lives your future…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_54AF:
    dw $041A                ; text $041A: "*:Be careful behind the Gate of Reflecti…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_54B3:
    dw $048A                ; text $048A: "*:Let me tell you the legend of the Star…"
    dw $FF03                ; $03 set_flag: Set flag $00AC
    dw $00AC                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_54BB:
    dw $002D                ; text $002D: "*:Should I repeat the legend of the Star…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_54C9  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_54C9 ;   target
    dw $002E                ; text $002E: "*:Here it is again. *:The Starry Night c…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_54C9:
    dw $048B                ; text $048B: "*:Oh bless Starry Night and Master [HERO…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_54CD:
    dw $05BE                ; text $05BE: "*:The King gave you a special permission…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_54DB  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_54DB ;   target
    dw $05BF                ; text $05BF: "*:The Starry Night comes after every 47t…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_54DB:
    dw $05C0                ; text $05C0: "*:The story of Monster Master [HERO] wil…"
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Castle_Script14
; ---------------------------------------------------------------------------
Castle_Script14:
    dw $FF00                ; $00 if_flag_clear: If flag $002F is clear → Bank0C_ScriptAddr_54EB
    dw $002F                ;   flag
    dw Bank0C_ScriptAddr_54EB ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0C_ScriptAddr_5567
    dw $0111                ;   flag
    dw Bank0C_ScriptAddr_5567 ;   target
Bank0C_ScriptAddr_54EB:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5563
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5563 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_555F
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_555F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_555B
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_555B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_5557
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_5557 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_5553
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_5553 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0C_ScriptAddr_554F
    dw $0033                ;   flag
    dw Bank0C_ScriptAddr_554F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0049 is set → Bank0C_ScriptAddr_554B
    dw $0049                ;   flag
    dw Bank0C_ScriptAddr_554B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_5547
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_5547 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0C_ScriptAddr_5543
    dw $0031                ;   flag
    dw Bank0C_ScriptAddr_5543 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0C_ScriptAddr_553F
    dw $0030                ;   flag
    dw Bank0C_ScriptAddr_553F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0C_ScriptAddr_553B
    dw $0009                ;   flag
    dw Bank0C_ScriptAddr_553B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0008 is set → Bank0C_ScriptAddr_5537
    dw $0008                ;   flag
    dw Bank0C_ScriptAddr_5537 ;   target
    dw $002B                ; text $002B: "*:My kingdom has been losing in the Star…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5537:
    dw $004D                ; text $004D: "*:His Majesty seems to be very upset. *:…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_553B:
    dw $005E                ; text $005E: "*:To get to the arena, go straight out o…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_553F:
    dw $014C                ; text $014C: "*:The Room of Villager & Talisman is in …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5543:
    dw $01A4                ; text $01A4: "*:Congratulations on surviving F class. …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5547:
    dw $01EA                ; text $01EA: "*:Congratulation on surviving E class. *…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_554B:
    dw $01EB                ; text $01EB: "*:[HERO]! Doing good huh? *:The Room of …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_554F:
    dw $0273                ; text $0273: "*:The Gate of Anger seems strange! *:It …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5553:
    dw $02AF                ; text $02AF: "*:The shaking of GreatTree has changed t…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5557:
    dw $0360                ; text $0360: "*:[HERO], why don't you go to the Bazaar…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_555B:
    dw $0418                ; text $0418: "*:The King fears for your future, Master…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_555F:
    dw $0489                ; text $0489: "*:Now, head to the arena! *:A great audi…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5563:
    dw $05BC                ; text $05BC: "*:His majesty gave you a reward for the …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5567:
    dw $05BD                ; text $05BD: "*:Master Monster [HERO], please stay her…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script15
; ---------------------------------------------------------------------------
Castle_Script15:
    dw $0050                ; text $0050: "Pulio:Sorry [HERO], It's my fault... Pul…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script16
; ---------------------------------------------------------------------------
Castle_Script16:
    dw $FF01                ; $01 if_flag_set: If flag $0008 is set → Bank0C_ScriptAddr_5583
    dw $0008                ;   flag
    dw Bank0C_ScriptAddr_5583 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0002 is set → Bank0C_ScriptAddr_557F
    dw $0002                ;   flag
    dw Bank0C_ScriptAddr_557F ;   target
    dw $0016                ; text $0016: "*:His Majesty is in trouble. Please prov…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_557F:
    dw $0030                ; text $0030: "*:Pulio from the farm is goofy but a ver…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5583:
    dw $0051                ; text $0051: "*:These stairs bring you to the Chamber …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script17
; ---------------------------------------------------------------------------
Castle_Script17:
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0C_ScriptAddr_55A5
    dw $0009                ;   flag
    dw Bank0C_ScriptAddr_55A5 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0008 is set → Bank0C_ScriptAddr_55A1
    dw $0008                ;   flag
    dw Bank0C_ScriptAddr_55A1 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0002 is set → Bank0C_ScriptAddr_559D
    dw $0002                ;   flag
    dw Bank0C_ScriptAddr_559D ;   target
    dw $0017                ; text $0017: "*:Please listen to his wish."
    dw $FFFF                ; END

Bank0C_ScriptAddr_559D:
    dw $0031                ; text $0031: "*:Upper floor, the monster farm. *:Pulio…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_55A1:
    dw $0052                ; text $0052: "*:Please bring Hale back as soon as poss…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_55A5:
    dw $005F                ; text $005F: "*:These stairs go up to the monster farm…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script18
; ---------------------------------------------------------------------------
Castle_Script18:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_55E5
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_55E5 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_55E1
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_55E1 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0C_ScriptAddr_55DD
    dw $0034                ;   flag
    dw Bank0C_ScriptAddr_55DD ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_55D9
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_55D9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_55D5
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_55D5 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0C_ScriptAddr_55D1
    dw $0009                ;   flag
    dw Bank0C_ScriptAddr_55D1 ;   target
    dw $0018                ; text $0018: "*:This is the castle of GreatTree."
    dw $FFFF                ; END

Bank0C_ScriptAddr_55D1:
    dw $0060                ; text $0060: "*:This is the castle of GreatTree. *:For…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_55D5:
    dw $01F6                ; text $01F6: "*:You are at the castle of GreatTree. *:…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_55D9:
    dw $02B9                ; text $02B9: "*:You're at the castle of GreatTree. *:T…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_55DD:
    dw $0857                ; text $0857: "*:You're at the castle of GreatTree. *:I…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_55E1:
    dw $048D                ; text $048D: "*:You're at the castle of GreatTree. Goo…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_55E5:
    dw $05CF                ; text $05CF: "*:Yes, you're at the castle of GreatTree…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Castle_Script19
; ---------------------------------------------------------------------------
Castle_Script19:
    dw $0851                ; text $0851: "[HERO] touched in front."
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_55F7
    dw Bank0C_ScriptAddr_55F7 ;   target
    dw $084B                ; text $084B: "*:Wow, a TinyMedal!!"
    dw $FF2A                ; $2A give_item: Give item 30
    dw $001E                ;   item
    dw $FFFF                ; END

Bank0C_ScriptAddr_55F7:
    dw $084C                ; text $084C: "*:Wow, a TinyMedal was found! But can't …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree Per-Script Table (map_type=$01, 21 scripts)
; ---------------------------------------------------------------------------
GreatTree_ScriptPtrTable:
    dw GreatTree_Script00   ; script 0
    dw GreatTree_Script01   ; script 1
    dw GreatTree_Script02   ; script 2
    dw GreatTree_Script03   ; script 3
    dw GreatTree_Script04   ; script 4
    dw GreatTree_Script05   ; script 5
    dw GreatTree_Script06   ; script 6
    dw GreatTree_Script07   ; script 7
    dw GreatTree_Script08   ; script 8
    dw GreatTree_Script09   ; script 9
    dw GreatTree_Script10   ; script 10
    dw GreatTree_Script11   ; script 11
    dw GreatTree_Script12   ; script 12
    dw GreatTree_Script13   ; script 13
    dw GreatTree_Script14   ; script 14
    dw GreatTree_Script15   ; script 15
    dw GreatTree_Script16   ; script 16
    dw GreatTree_Script17   ; script 17
    dw GreatTree_Script18   ; script 18
    dw GreatTree_Script19   ; script 19
    dw GreatTree_Script20   ; script 20
; ---------------------------------------------------------------------------
; GreatTree_Script00
; ---------------------------------------------------------------------------
GreatTree_Script00:
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is the intro journey (dresser → GreatTree → Castle) → Bank0C_ScriptAddr_5641  [$D951 = 255]
    dw $D951                ;   address
    dw $00FF                ;   value
    dw Bank0C_ScriptAddr_5641 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 0 → Bank0C_ScriptAddr_5799
    dw $0000                ;   screen
    dw Bank0C_ScriptAddr_5799 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 1 → Bank0C_ScriptAddr_5847
    dw $0001                ;   screen
    dw Bank0C_ScriptAddr_5847 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 12 → Bank0C_ScriptAddr_587F
    dw $000C                ;   screen
    dw Bank0C_ScriptAddr_587F ;   target
    dw $FFFF                ; END

Bank0C_ScriptAddr_5641:
    dw $FF0E                ; $0E branch_screen: If on screen 12 → Bank0C_ScriptAddr_565B
    dw $000C                ;   screen
    dw Bank0C_ScriptAddr_565B ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 8 → Bank0C_ScriptAddr_56BD
    dw $0008                ;   screen
    dw Bank0C_ScriptAddr_56BD ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 4 → Bank0C_ScriptAddr_56D7
    dw $0004                ;   screen
    dw Bank0C_ScriptAddr_56D7 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 0 → Bank0C_ScriptAddr_5737
    dw $0000                ;   screen
    dw Bank0C_ScriptAddr_5737 ;   target
    dw $FFFF                ; END

Bank0C_ScriptAddr_565B:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0010                ; text $0010: "*:This kingdom is created inside a big t…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks left 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks left 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 6 tiles
    dw $0001                ;   actor
    dw $FFA0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 6 tiles
    dw $0000                ;   actor
    dw $FFA0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0F                ; $0F map_transition: Go to GreatTree at (2, 23)
    dw $0001                ;   map
    dw $0028                ;   x
    dw $0178                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0C_ScriptAddr_56BD:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 8 tiles
    dw $0001                ;   actor
    dw $FF80                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 8 tiles
    dw $0000                ;   actor
    dw $FF80                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0F                ; $0F map_transition: Go to GreatTree at (2, 15)
    dw $0001                ;   map
    dw $0028                ;   x
    dw $00F8                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0C_ScriptAddr_56D7:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 2 tiles
    dw $0001                ;   actor
    dw $FFE0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 2 tiles
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0B                ; $0B walk_y_wait: NPC 3 walks down 1 tile (script waits)
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 3 walks left 1 tile (script waits)
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0011                ; text $0011: "*:Hey, is he the new master Watabou brou…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0012                ; text $0012: "*:Yes indeed, I'm taking him to see the …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF0B                ; $0B walk_y_wait: NPC 3 walks down 1 tile (script waits)
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0013                ; text $0013: "*:Good luck at the Starry Night Tourname…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 7 tiles
    dw $0001                ;   actor
    dw $FF90                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 7 tiles
    dw $0000                ;   actor
    dw $FF90                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0F                ; $0F map_transition: Go to GreatTree at (2, 7)
    dw $0001                ;   map
    dw $0028                ;   x
    dw $0078                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0C_ScriptAddr_5737:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 2 tiles
    dw $0001                ;   actor
    dw $0020                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks right 2 tiles
    dw $0000                ;   actor
    dw $0020                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0014                ; text $0014: "*:Now it's time to go see the King."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0F                ; $0F map_transition: Go to Castle at (14, 15)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $00F8                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0C_ScriptAddr_5799:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_57B7
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_57B7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0C_ScriptAddr_57D9
    dw $00EE                ;   flag
    dw Bank0C_ScriptAddr_57D9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $000A is set → Bank0C_ScriptAddr_57B7
    dw $000A                ;   flag
    dw Bank0C_ScriptAddr_57B7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0C_ScriptAddr_57B9
    dw $0009                ;   flag
    dw Bank0C_ScriptAddr_57B9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0001 is set → Bank0C_ScriptAddr_57B7
    dw $0001                ;   flag
    dw Bank0C_ScriptAddr_57B7 ;   target
Bank0C_ScriptAddr_57B7:
    dw $FFFF                ; END

Bank0C_ScriptAddr_57B9:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0061                ; text $0061: "*:Oh boy! This looks dangerous! Oh, no!"
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 4 tiles
    dw $0001                ;   actor
    dw $0040                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF03                ; $03 set_flag: Set flag $000A
    dw $000A                ;   flag
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 0 → state 3  [$D92D := 3]
    dw $D92D                ;   address
    dw $0003                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_57D9:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 2 tiles
    dw $0001                ;   actor
    dw $0020                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks right 2 tiles
    dw $0000                ;   actor
    dw $0020                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0014                ; text $0014: "*:Now it's time to go see the King."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF12                ; $12 write_ram: Room state of Castle screen 5 (+8 room variant(s) sharing it) → state 0  [$D92C := 0]
    dw $D92C                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 0 → state 3  [$D92D := 3]
    dw $D92D                ;   address
    dw $0003                ;   value
    dw $FF0F                ; $0F map_transition: Go to Castle at (14, 15)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $00F8                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0C_ScriptAddr_5847:
    dw $FF01                ; $01 if_flag_set: If flag $0021 is set → Bank0C_ScriptAddr_5865
    dw $0021                ;   flag
    dw Bank0C_ScriptAddr_5865 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $011E is clear → Bank0C_ScriptAddr_5859
    dw $011E                ;   flag
    dw Bank0C_ScriptAddr_5859 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0C_ScriptAddr_5873
    dw $00EE                ;   flag
    dw Bank0C_ScriptAddr_5873 ;   target
Bank0C_ScriptAddr_5859:
    dw $FF01                ; $01 if_flag_set: If flag $0043 is set → Bank0C_ScriptAddr_5865
    dw $0043                ;   flag
    dw Bank0C_ScriptAddr_5865 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $011E is set → Bank0C_ScriptAddr_5867
    dw $011E                ;   flag
    dw Bank0C_ScriptAddr_5867 ;   target
Bank0C_ScriptAddr_5865:
    dw $FFFF                ; END

Bank0C_ScriptAddr_5867:
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 1  [$D95E := 1]
    dw $D95E                ;   address
    dw $0001                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0043
    dw $0043                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_5873:
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 4  [$D95E := 4]
    dw $D95E                ;   address
    dw $0004                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0043
    dw $0043                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_587F:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_588B
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_588B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0C_ScriptAddr_588D
    dw $00EE                ;   flag
    dw Bank0C_ScriptAddr_588D ;   target
Bank0C_ScriptAddr_588B:
    dw $FFFF                ; END

Bank0C_ScriptAddr_588D:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF12                ; $12 write_ram: The game mode: the bank $02 picture scenes (the ceremony, the tree)  [$C88A := 3]
    dw $C88A                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: The next game mode: the bank $02 picture scenes (the ceremony, the tree)  [$C88B := 3]
    dw $C88B                ;   address
    dw $0003                ;   value
    dw $FF3E                ; $3E change_game_mode: Fade out and switch to the game mode in $C88B (e.g. a naming screen) — $C88E is the main loop's mode request
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05B6                ; text $05B6: "*:Oh, GreatTree is shaking! It's welcomi…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks left 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks left 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 6 tiles
    dw $0001                ;   actor
    dw $FFA0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 6 tiles
    dw $0000                ;   actor
    dw $FFA0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 12 → state 3  [$D933 := 3]
    dw $D933                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 0 → state 4  [$D92D := 4]
    dw $D92D                ;   address
    dw $0004                ;   value
    dw $FF0F                ; $0F map_transition: Go to GreatTree at (2, 7)
    dw $0001                ;   map
    dw $0028                ;   x
    dw $0078                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
; ---------------------------------------------------------------------------
; GreatTree_Script01
; ---------------------------------------------------------------------------
GreatTree_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $0002 is set → Bank0C_ScriptAddr_5927
    dw $0002                ;   flag
    dw Bank0C_ScriptAddr_5927 ;   target
    dw $0019                ; text $0019: "*:Hurry! Go see the King!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5927:
    dw $0032                ; text $0032: "*:Watabou brings us capable masters. *:H…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script02
; ---------------------------------------------------------------------------
GreatTree_Script02:
    dw $001F                ; text $001F: "*:This is the Kingdom of GreatTree!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script03
; ---------------------------------------------------------------------------
GreatTree_Script03:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_596F
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_596F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $009B is set → Bank0C_ScriptAddr_596B
    dw $009B                ;   flag
    dw Bank0C_ScriptAddr_596B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_5963
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_5963 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_595F
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_595F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_595B
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_595B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_5957
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_5957 ;   target
    dw $012F                ; text $012F: "*:We can see the ground far below. *:Gre…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5957:
    dw $01F7                ; text $01F7: "*:Wishing upon the stars on Starry Night…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_595B:
    dw $02BA                ; text $02BA: "*:A long time ago, the ancestor of Watab…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_595F:
    dw $036B                ; text $036B: "*:There must be some reason that.. *:Wat…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5963:
    dw $041C                ; text $041C: "*:So you became the master of GreatTree.…"
    dw $FF03                ; $03 set_flag: Set flag $009B
    dw $009B                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_596B:
    dw $041D                ; text $041D: "*:The Starry Night is coming. The tourna…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_596F:
    dw $05D0                ; text $05D0: "*:Why did Watabou's ancestor want the to…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script04
; ---------------------------------------------------------------------------
GreatTree_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5987
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5987 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_5983
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_5983 ;   target
    dw $0062                ; text $0062: "*:This is the village of GreatTree. *:Th…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5983:
    dw $048E                ; text $048E: "*:Good luck at the Starry Night Tourname…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5987:
    dw $05D1                ; text $05D1: "*:The village of GreatTree is filled wit…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script05
; ---------------------------------------------------------------------------
GreatTree_Script05:
    dw $0063                ; text $0063: "*:Fhew! I'm glad that I didn't get hurt!…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script06
; ---------------------------------------------------------------------------
GreatTree_Script06:
    dw $0064                ; text $0064: "*:Oh [HERO], it's you. I am getting old.…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script07
; ---------------------------------------------------------------------------
GreatTree_Script07:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_59C9
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_59C9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $009C is set → Bank0C_ScriptAddr_59C5
    dw $009C                ;   flag
    dw Bank0C_ScriptAddr_59C5 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_59BD
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_59BD ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_59B9
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_59B9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_59B5
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_59B5 ;   target
    dw $01AF                ; text $01AF: "*:The girl down below who blocked a path…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_59B5:
    dw $02BB                ; text $02BB: "*:I often see the girl who stood in the …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_59B9:
    dw $036C                ; text $036C: "*:Hey, the tournament is coming! Good Lu…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_59BD:
    dw $041E                ; text $041E: "*:Hey, I heard you became the rep! You'r…"
    dw $FF03                ; $03 set_flag: Set flag $009C
    dw $009C                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_59C5:
    dw $041F                ; text $041F: "*:Just competing in the Starry Night Tou…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_59C9:
    dw $05D2                ; text $05D2: "*:The girl downstairs has been looking f…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script08
; ---------------------------------------------------------------------------
GreatTree_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5A19
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5A19 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_5A07
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_5A07 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $000B is set → Bank0C_ScriptAddr_59F5
    dw $000B                ;   flag
    dw Bank0C_ScriptAddr_59F5 ;   target
    dw $012B                ; text $012B: "*:Hey you, do you have a TinyMedal? [YES…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_59F1  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_59F1 ;   target
    dw $012D                ; text $012D: "*:I see. Go to the room above then. *:Yo…"
    dw $FF03                ; $03 set_flag: Set flag $000B
    dw $000B                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_59F1:
    dw $012C                ; text $012C: "*:You don't have it? What are you doing?…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_59F5:
    dw $012B                ; text $012B: "*:Hey you, do you have a TinyMedal? [YES…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5A03  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5A03 ;   target
    dw $012E                ; text $012E: "*:Great! Go to the room above then."
    dw $FFFF                ; END

Bank0C_ScriptAddr_5A03:
    dw $012C                ; text $012C: "*:You don't have it? What are you doing?…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5A07:
    dw $012B                ; text $012B: "*:Hey you, do you have a TinyMedal? [YES…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5A15  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5A15 ;   target
    dw $0490                ; text $0490: "*:Bring them to the Medal Man upstairs. …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5A15:
    dw $048F                ; text $048F: "*:You don't have it? You should be able …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5A19:
    dw $05D3                ; text $05D3: "*:Even if there is no more rewards given…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5A27  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5A27 ;   target
    dw $05D4                ; text $05D4: "*:Great, it's so great. But I would not …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5A27:
    dw $05D5                ; text $05D5: "*:Yes. It's the right way."
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; GreatTree_Script09
; ---------------------------------------------------------------------------
GreatTree_Script09:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5A67
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5A67 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_5A63
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_5A63 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_5A5F
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_5A5F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_5A5B
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_5A5B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_5A57
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_5A57 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_5A53
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_5A53 ;   target
    dw $0065                ; text $0065: "*:Once I picked up a TinyMedal, *:back w…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5A53:
    dw $01F8                ; text $01F8: "*:GreatLog is the closest country to Gre…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5A57:
    dw $02BC                ; text $02BC: "*:The Kingdom of DeadTree is almost dead…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5A5B:
    dw $036D                ; text $036D: "*:One of my relatives is living in the k…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5A5F:
    dw $0420                ; text $0420: "*:Many people are heading to GreatTree. …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5A63:
    dw $0491                ; text $0491: "*:Many people are heading to GreatTree. …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5A67:
    dw $05D6                ; text $05D6: "*:I feel the air is sparkling. *:I wonde…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script10
; ---------------------------------------------------------------------------
GreatTree_Script10:
    dw $0157                ; text $0157: "*:Who do you think you are! What? You're…"
    dw $FF03                ; $03 set_flag: Set flag $0080
    dw $0080                ;   flag
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script11
; ---------------------------------------------------------------------------
GreatTree_Script11:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5A87
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5A87 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_5A83
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_5A83 ;   target
    dw $0159                ; text $0159: "*:{AC} is added to the monster level whe…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5A83:
    dw $0492                ; text $0492: "*:Watabou will be happy if you win! *:It…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5A87:
    dw $05D7                ; text $05D7: "*:The victorious master eventually becom…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script12
; ---------------------------------------------------------------------------
GreatTree_Script12:
    dw $0158                ; text $0158: "*:Almost there to the bottom! *:What is …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script13
; ---------------------------------------------------------------------------
GreatTree_Script13:
    dw $FF01                ; $01 if_flag_set: If flag $0114 is set → Bank0C_ScriptAddr_5ACF
    dw $0114                ;   flag
    dw Bank0C_ScriptAddr_5ACF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5AC7
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5AC7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_5AC3
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_5AC3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_5ABF
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_5ABF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_5ABB
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_5ABB ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_5AB7
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_5AB7 ;   target
    dw $01B0                ; text $01B0: "*:I want you to win the tournament this …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5AB7:
    dw $02BD                ; text $02BD: "*:I want us to win this time! *:The Star…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5ABB:
    dw $036E                ; text $036E: "*:To tell the truth, Watabou hasn't brou…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5ABF:
    dw $0421                ; text $0421: "*:You'll win! I can feel it! *:I heard t…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5AC3:
    dw $0493                ; text $0493: "*:You can win! ...I feel it! *:I heard a…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5AC7:
    dw $05D8                ; text $05D8: "*:A well won victory! I'm so happy! *:I …"
    dw $FF03                ; $03 set_flag: Set flag $0114
    dw $0114                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5ACF:
    dw $084F                ; text $084F: "*:I heard my wish will come true with th…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script14
; ---------------------------------------------------------------------------
GreatTree_Script14:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5AE7
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5AE7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_5AE3
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_5AE3 ;   target
    dw $015A                ; text $015A: "*:Enter here to the Vault."
    dw $FFFF                ; END

Bank0C_ScriptAddr_5AE3:
    dw $0494                ; text $0494: "*:Proceed to the Vault. Good luck!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5AE7:
    dw $05D9                ; text $05D9: "*:Enter here to the Vault. Congratulatio…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script15
; ---------------------------------------------------------------------------
GreatTree_Script15:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5B2B
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5B2B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00AD is set → Bank0C_ScriptAddr_5B27
    dw $00AD                ;   flag
    dw Bank0C_ScriptAddr_5B27 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_5B1F
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_5B1F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_5B1B
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_5B1B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_5B17
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_5B17 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_5B13
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_5B13 ;   target
    dw $015B                ; text $015B: "*:The Bazaar's to the right!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5B13:
    dw $02BE                ; text $02BE: "*:Right to the Bazaar! There are new sto…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5B17:
    dw $036F                ; text $036F: "*:Bazaar to the right! A third store has…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5B1B:
    dw $0422                ; text $0422: "*:Go right to the Bazaar! More stores ha…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5B1F:
    dw $0495                ; text $0495: "*:Go right to the Bazaar! *:It's [HERO]!…"
    dw $FF03                ; $03 set_flag: Set flag $00AD
    dw $00AD                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5B27:
    dw $0496                ; text $0496: "*:Go right to the Bazaar! *:Oh [HERO]! I…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5B2B:
    dw $05DA                ; text $05DA: "*:Go right to the Bazaar! Hey you were s…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script16
; ---------------------------------------------------------------------------
GreatTree_Script16:
    dw $FF01                ; $01 if_flag_set: If flag $002F is set → Bank0C_ScriptAddr_5D8B
    dw $002F                ;   flag
    dw Bank0C_ScriptAddr_5D8B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F4 is set → Bank0C_ScriptAddr_5D87
    dw $00F4                ;   flag
    dw Bank0C_ScriptAddr_5D87 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0107 is set → Bank0C_ScriptAddr_5D7F
    dw $0107                ;   flag
    dw Bank0C_ScriptAddr_5D7F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0106 is set → Bank0C_ScriptAddr_5D7F
    dw $0106                ;   flag
    dw Bank0C_ScriptAddr_5D7F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F3 is set → Bank0C_ScriptAddr_5D7B
    dw $00F3                ;   flag
    dw Bank0C_ScriptAddr_5D7B ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $00F2 is clear → Bank0C_ScriptAddr_5B59
    dw $00F2                ;   flag
    dw Bank0C_ScriptAddr_5B59 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0105 is set → Bank0C_ScriptAddr_5C4B
    dw $0105                ;   flag
    dw Bank0C_ScriptAddr_5C4B ;   target
Bank0C_ScriptAddr_5B59:
    dw $FF01                ; $01 if_flag_set: If flag $00F2 is set → Bank0C_ScriptAddr_5C2B
    dw $00F2                ;   flag
    dw Bank0C_ScriptAddr_5C2B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5C23
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5C23 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00AE is set → Bank0C_ScriptAddr_5C11
    dw $00AE                ;   flag
    dw Bank0C_ScriptAddr_5C11 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_5BFB
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_5BFB ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_5BF3
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_5BF3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0C_ScriptAddr_5BD9
    dw $0036                ;   flag
    dw Bank0C_ScriptAddr_5BD9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_5BD1
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_5BD1 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0C_ScriptAddr_5BC9
    dw $0034                ;   flag
    dw Bank0C_ScriptAddr_5BC9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_5BAF
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_5BAF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0C_ScriptAddr_5BA7
    dw $0033                ;   flag
    dw Bank0C_ScriptAddr_5BA7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_5B9F
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_5B9F ;   target
    dw $01B1                ; text $01B1: "*:I heard you got stronger. *:But I stil…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5B9F:
    dw $01F9                ; text $01F9: "*:You've been babied forever! *:Can some…"
    dw $FF03                ; $03 set_flag: Set flag $0080
    dw $0080                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5BA7:
    dw $0277                ; text $0277: "*:I heard you defeated Mick. You're gett…"
    dw $FF03                ; $03 set_flag: Set flag $0080
    dw $0080                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5BAF:
    dw $02BF                ; text $02BF: "*:D... Do ya know there was a big quake?…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5BC1  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5BC1 ;   target
    dw $02C0                ; text $02C0: "*:Who makes such a darn big quake?"
    dw $FF03                ; $03 set_flag: Set flag $0080
    dw $0080                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5BC1:
    dw $02C1                ; text $02C1: "*:Hey watch out! Look where you're going…"
    dw $FF03                ; $03 set_flag: Set flag $0080
    dw $0080                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_5BC9:
    dw $033C                ; text $033C: "*:What? You won C class? Shoo, shoo! It'…"
    dw $FF03                ; $03 set_flag: Set flag $0080
    dw $0080                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5BD1:
    dw $0370                ; text $0370: "*:You'll always be a loser! What's wrong…"
    dw $FF03                ; $03 set_flag: Set flag $0080
    dw $0080                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5BD9:
    dw $03E7                ; text $03E7: "*:Hey are you really aiming for S class?…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5BEB  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5BEB ;   target
    dw $03E8                ; text $03E8: "*:You'll never get there with such pathe…"
    dw $FF03                ; $03 set_flag: Set flag $0080
    dw $0080                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5BEB:
    dw $03E9                ; text $03E9: "*:Then go home, liar!"
    dw $FF03                ; $03 set_flag: Set flag $0080
    dw $0080                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_5BF3:
    dw $0423                ; text $0423: "*:Rep? A kid like you? Liar! *:Helloooo!…"
    dw $FF03                ; $03 set_flag: Set flag $0080
    dw $0080                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5BFB:
    dw $0497                ; text $0497: "*:Are you... really competing in the tou…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5C0D  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5C0D ;   target
    dw $0498                ; text $0498: "*:...Don't lose."
    dw $FF03                ; $03 set_flag: Set flag $00AE
    dw $00AE                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5C0D:
    dw $049A                ; text $049A: "*:You're right! It's impossible for you …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5C11:
    dw $0497                ; text $0497: "*:Are you... really competing in the tou…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5C1F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5C1F ;   target
    dw $0499                ; text $0499: "*:...Don't lose. Don't make me say it ag…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5C1F:
    dw $049B                ; text $049B: "*:...you. Don't you regret saying that?"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5C23:
    dw $05DC                ; text $05DC: "*:You fool! Where have you been for such…"
    dw $FF03                ; $03 set_flag: Set flag $00F2
    dw $00F2                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5C2B:
    dw $05DD                ; text $05DD: "*:I was... ...worried. *:...Hey you! You…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5C43  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5C43 ;   target
    dw $05DF                ; text $05DF: "*:Then say it! [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5C47  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5C47 ;   target
    dw $05E1                ; text $05E1: "*:I don't have such a name! Don't lie to…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5C43:
    dw $05DE                ; text $05DE: "*:Huff, I don't need you!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5C47:
    dw $05E0                ; text $05E0: "*:Humpf, I don't need you!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5C4B:
    dw $05DD                ; text $05DD: "*:I was... ...worried. *:...Hey you! You…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5D73  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5D73 ;   target
    dw $05DF                ; text $05DF: "*:Then say it! [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5D77  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5D77 ;   target
    dw $05E2                ; text $05E2: "*:Yep. It's Santi. How did you know? San…"
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF1C                ; $1C trigger_anim: the player: pause 64 frames (followers catch up)
    dw $0600                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF15                ; $15 check_and_branch: If “Terry's X position (pixels)” is 39 → Bank0C_ScriptAddr_5CB5  [$FF92 = 39]
    dw $FF92                ;   address
    dw $0027                ;   value
    dw Bank0C_ScriptAddr_5CB5 ;   target
    dw $FF15                ; $15 check_and_branch: If “Terry's X position (pixels)” is 40 → Bank0C_ScriptAddr_5CB5  [$FF92 = 40]
    dw $FF92                ;   address
    dw $0028                ;   value
    dw Bank0C_ScriptAddr_5CB5 ;   target
    dw $FF15                ; $15 check_and_branch: If “Terry's X position (pixels)” is 41 → Bank0C_ScriptAddr_5CB5  [$FF92 = 41]
    dw $FF92                ;   address
    dw $0029                ;   value
    dw Bank0C_ScriptAddr_5CB5 ;   target
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks right 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_5CDF
    dw Bank0C_ScriptAddr_5CDF ;   target
Bank0C_ScriptAddr_5CB5:
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks left 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks right 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
Bank0C_ScriptAddr_5CDF:
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 2 tiles
    dw $0001                ;   actor
    dw $FFE0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 2 tiles
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 2 tiles
    dw $0001                ;   actor
    dw $0020                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks right 2 tiles
    dw $0000                ;   actor
    dw $0020                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05E3                ; text $05E3: "Santi:Wait here for me!"
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 1 tile (script waits)
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 32 ticks (~256 frames)
    dw $0020                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 1 tile (script waits)
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05E4                ; text $05E4: "Santi:Talk to my Grandpa!!"
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks right 1 tile (script waits)
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 3 tiles (script waits)
    dw $0001                ;   actor
    dw $0030                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks left 5 tiles (script waits)
    dw $0001                ;   actor
    dw $FFB0                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 1 tile (script waits)
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF03                ; $03 set_flag: Set flag $00F3
    dw $00F3                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5D73:
    dw $05DE                ; text $05DE: "*:Huff, I don't need you!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5D77:
    dw $05E0                ; text $05E0: "*:Humpf, I don't need you!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_5D7B:
    dw $05E5                ; text $05E5: "Santi:C'mon, go talk to my Grandpa!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5D7F:
    dw $05E6                ; text $05E6: "Santi:You talked to my Grandpa, right? S…"
    dw $FF03                ; $03 set_flag: Set flag $00F4
    dw $00F4                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_5D87:
    dw $05E7                ; text $05E7: "Santi:Don't just stand there! Go to the …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5D8B:
    dw $05E8                ; text $05E8: "Santi:Was the Travelers' Gate useful to …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_5D99  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_5D99 ;   target
    dw $05EA                ; text $05EA: "Santi:I...I'm... happy....blush."
    dw $FFFF                ; END

Bank0C_ScriptAddr_5D99:
    dw $05E9                ; text $05E9: "Santi:Y...Ya big fool!"
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; GreatTree_Script17
; ---------------------------------------------------------------------------
GreatTree_Script17:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5DCB
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5DCB ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0025 is clear → Bank0C_ScriptAddr_5DAF
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_5DAF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0083 is set → Bank0C_ScriptAddr_5DC7
    dw $0083                ;   flag
    dw Bank0C_ScriptAddr_5DC7 ;   target
Bank0C_ScriptAddr_5DAF:
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_5DC3
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_5DC3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_5DBF
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_5DBF ;   target
    dw $01B2                ; text $01B2: "*:Whew! At last we made it to the bottom…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5DBF:
    dw $02C2                ; text $02C2: "*:Thanks to the quake, you can go right …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5DC3:
    dw $0371                ; text $0371: "*:Hey! Down the stairs is the Shrine of …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5DC7:
    dw $049C                ; text $049C: "*:The Master Monster Tamer downstairs sa…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5DCB:
    dw $05DB                ; text $05DB: "*:Congratulations! Down the stairs to th…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script18
; ---------------------------------------------------------------------------
GreatTree_Script18:
    dw $FF12                ; $12 write_ram: Player input locked (scripted scroll): locked  [$D9E8 := 1]
    dw $D9E8                ;   address
    dw $0001                ;   value
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks down 6 tiles
    dw $0000                ;   actor
    dw $0060                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF12                ; $12 write_ram: The buttons held: none  [$C842 := 0]
    dw $C842                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The buttons pressed this frame: none  [$C846 := 0]
    dw $C846                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script19
; ---------------------------------------------------------------------------
GreatTree_Script19:
    dw $FF12                ; $12 write_ram: Player input locked (scripted scroll): locked  [$D9E8 := 1]
    dw $D9E8                ;   address
    dw $0001                ;   value
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks down 6 tiles
    dw $0000                ;   actor
    dw $0060                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GreatTree_Script20
; ---------------------------------------------------------------------------
GreatTree_Script20:
    dw $FF12                ; $12 write_ram: Player input locked (scripted scroll): locked  [$D9E8 := 1]
    dw $D9E8                ;   address
    dw $0001                ;   value
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks down 3 tiles
    dw $0000                ;   actor
    dw $0030                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar Per-Script Table (map_type=$02, 25 scripts)
; ---------------------------------------------------------------------------
Bazaar_ScriptPtrTable:
    dw Bazaar_Script00      ; script 0
    dw Bazaar_Script01      ; script 1
    dw Bazaar_Script02      ; script 2
    dw Bazaar_Script03      ; script 3
    dw Bazaar_Script04      ; script 4
    dw Bazaar_Script05      ; script 5
    dw Bazaar_Script06      ; script 6
    dw Bazaar_Script07      ; script 7
    dw Bazaar_Script08      ; script 8
    dw Bazaar_Script09      ; script 9
    dw Bazaar_Script10      ; script 10
    dw Bazaar_Script11      ; script 11
    dw Bazaar_Script12      ; script 12
    dw Bazaar_Script13      ; script 13
    dw Bazaar_Script14      ; script 14
    dw Bazaar_Script15      ; script 15
    dw Bazaar_Script16      ; script 16
    dw Bazaar_Script17      ; script 17
    dw Bazaar_Script18      ; script 18
    dw Bazaar_Script19      ; script 19
    dw Bazaar_Script20      ; script 20
    dw Bazaar_Script21      ; script 21
    dw Bazaar_Script22      ; script 22
    dw Bazaar_Script23      ; script 23
    dw Bazaar_Script24      ; script 24
; ---------------------------------------------------------------------------
; Bazaar_Script00
; ---------------------------------------------------------------------------
Bazaar_Script00:
    dw $FF0E                ; $0E branch_screen: If on screen 1 → Bank0C_ScriptAddr_5E57
    dw $0001                ;   screen
    dw Bank0C_ScriptAddr_5E57 ;   target
    dw $FFFF                ; END

Bank0C_ScriptAddr_5E57:
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_5E8D
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_5E8D ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $001D is clear → Bank0C_ScriptAddr_5E69
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_5E69 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $004B is set → Bank0C_ScriptAddr_5E8D
    dw $004B                ;   flag
    dw Bank0C_ScriptAddr_5E8D ;   target
Bank0C_ScriptAddr_5E69:
    dw $FF00                ; $00 if_flag_clear: If flag $001D is clear → Bank0C_ScriptAddr_5E75
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_5E75 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $004A is set → Bank0C_ScriptAddr_5E89
    dw $004A                ;   flag
    dw Bank0C_ScriptAddr_5E89 ;   target
Bank0C_ScriptAddr_5E75:
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_5E8D
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_5E8D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $004B is set → Bank0C_ScriptAddr_5E8D
    dw $004B                ;   flag
    dw Bank0C_ScriptAddr_5E8D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $004A is set → Bank0C_ScriptAddr_5E89
    dw $004A                ;   flag
    dw Bank0C_ScriptAddr_5E89 ;   target
    dw $FFFF                ; END

Bank0C_ScriptAddr_5E89:
    dw $FF03                ; $03 set_flag: Set flag $004B
    dw $004B                ;   flag
Bank0C_ScriptAddr_5E8D:
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Bazaar_Script01
; ---------------------------------------------------------------------------
Bazaar_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $003F is set → Bank0C_ScriptAddr_5EAB
    dw $003F                ;   flag
    dw Bank0C_ScriptAddr_5EAB ;   target
    dw $003A                ; text $003A: "[HERO] looked into the jar."
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_5EA7
    dw Bank0C_ScriptAddr_5EA7 ;   target
    dw $0129                ; text $0129: "Wow! [HERO] got a TinyMedal!"
    dw $FF03                ; $03 set_flag: Set flag $003F
    dw $003F                ;   flag
    dw $FF2A                ; $2A give_item: Give item 30
    dw $001E                ;   item
    dw $FFFF                ; END

Bank0C_ScriptAddr_5EA7:
    dw $012A                ; text $012A: "Wow! A TinyMedal was found! But cannot c…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5EAB:
    dw $015D                ; text $015D: "[HERO] looked into the jar. But there wa…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script02
; ---------------------------------------------------------------------------
Bazaar_Script02:
    dw $015E                ; text $015E: "[HERO] looked into the jar. It was fille…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script03
; ---------------------------------------------------------------------------
Bazaar_Script03:
    dw $015E                ; text $015E: "[HERO] looked into the jar. It was fille…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script04
; ---------------------------------------------------------------------------
Bazaar_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $0115 is set → Bank0C_ScriptAddr_5ED9
    dw $0115                ;   flag
    dw Bank0C_ScriptAddr_5ED9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5EE5
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5EE5 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0112 is set → Bank0C_ScriptAddr_5ED9
    dw $0112                ;   flag
    dw Bank0C_ScriptAddr_5ED9 ;   target
    dw $0196                ; text $0196: "*:Welcome to the item shop. *:Journeys a…"
    dw $FF03                ; $03 set_flag: Set flag $0112
    dw $0112                ;   flag
    dw $FF04                ; $04 open_screen: Open the shop (its texts begin “*:Item shop. May I help you?”)
    dw $0000                ;   kind
    dw $0680                ;   text
    dw $0682                ; text $0682: "*:Thank you. Come again!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5ED9:
    dw $0680                ; text $0680: "*:Item shop. May I help you?"
    dw $FF04                ; $04 open_screen: Open the shop (its texts begin “*:Item shop. May I help you?”)
    dw $0000                ;   kind
    dw $0680                ;   text
    dw $0682                ; text $0682: "*:Thank you. Come again!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5EE5:
    dw $024A                ; text $024A: "*:Since [HERO] won… *:Customers have flo…"
    dw $FF03                ; $03 set_flag: Set flag $0115
    dw $0115                ;   flag
    dw $FF04                ; $04 open_screen: Open the shop (its texts begin “*:Item shop. May I help you?”)
    dw $0000                ;   kind
    dw $0680                ;   text
    dw $0682                ; text $0682: "*:Thank you. Come again!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script05
; ---------------------------------------------------------------------------
Bazaar_Script05:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5F1D
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5F1D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_5F19
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_5F19 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_5F15
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_5F15 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_5F11
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_5F11 ;   target
    dw $015C                ; text $015C: "*:Hello, welcome to the Bazaar!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5F11:
    dw $02C3                ; text $02C3: "*:Welcome to the Bazaar! We have new sto…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5F15:
    dw $0372                ; text $0372: "*:Welcome to the Bazaar! There are more …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5F19:
    dw $0424                ; text $0424: "*:Master [HERO]! Welcome to the Bazaar!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5F1D:
    dw $05EB                ; text $05EB: "*:Oh our hero [HERO]! Welcome to the Baz…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script06
; ---------------------------------------------------------------------------
Bazaar_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_5F3F
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_5F3F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_5F3B
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_5F3B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_5F37
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_5F37 ;   target
    dw $02C4                ; text $02C4: "*:I love festivals! I'm looking forward …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5F37:
    dw $0373                ; text $0373: "*:I love festivals! I'm looking forward …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5F3B:
    dw $0425                ; text $0425: "*:The Starry Night is almost here! I am …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5F3F:
    dw $05EC                ; text $05EC: "*:What a good feeling to be the winning …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script07
; ---------------------------------------------------------------------------
Bazaar_Script07:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_608F
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_608F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_608B
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_608B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_6087
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_6087 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $004B is set → Bank0C_ScriptAddr_6083
    dw $004B                ;   flag
    dw Bank0C_ScriptAddr_6083 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $004A is set → Bank0C_ScriptAddr_607F
    dw $004A                ;   flag
    dw Bank0C_ScriptAddr_607F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_5F6B
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_5F6B ;   target
    dw $015F                ; text $015F: "*:Rumor has it that the BeastTail is an …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_5F6B:
    dw $01FA                ; text $01FA: "*:Do you know the name of the spirit of …"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $01FB                ; text $01FB: "*:Warubou? Hee hee hee! It's a weird nam…"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 5, curve 3  [$D8E3 := $0305]
    dw $D8E3                ;   address
    dw $0305                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 3: fly in down-left (the flight path set above)
    dw $1503                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF15                ; $15 check_and_branch: If “Terry's X position (pixels)” is 215 → Bank0C_ScriptAddr_5FD1  [$FF92 = 215]
    dw $FF92                ;   address
    dw $00D7                ;   value
    dw Bank0C_ScriptAddr_5FD1 ;   target
    dw $FF15                ; $15 check_and_branch: If “Terry's X position (pixels)” is 216 → Bank0C_ScriptAddr_5FD1  [$FF92 = 216]
    dw $FF92                ;   address
    dw $00D8                ;   value
    dw Bank0C_ScriptAddr_5FD1 ;   target
    dw $FF15                ; $15 check_and_branch: If “Terry's X position (pixels)” is 217 → Bank0C_ScriptAddr_5FD1  [$FF92 = 217]
    dw $FF92                ;   address
    dw $00D9                ;   value
    dw Bank0C_ScriptAddr_5FD1 ;   target
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_5FD7
    dw Bank0C_ScriptAddr_5FD7 ;   target
Bank0C_ScriptAddr_5FD1:
    dw $FF11                ; $11 walk_to_y: the player walks to y = 56 px (script waits)
    dw $0000                ;   actor
    dw $0038                ;   y
Bank0C_ScriptAddr_5FD7:
    dw $FF10                ; $10 walk_to_x: the player walks to x = 248 px (script waits)
    dw $0000                ;   actor
    dw $00F8                ;   x
    dw $FF11                ; $11 walk_to_y: the player walks to y = 104 px (script waits)
    dw $0000                ;   actor
    dw $0068                ;   y
    dw $FF0A                ; $0A walk_x_wait: NPC 3 walks left 1 tile (script waits)
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF47                ; $47 face_up: NPC 3 faces up
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $54
    dw $0054                ;   sound
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks up 5 tiles
    dw $0002                ;   actor
    dw $FFB0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: walk animation on  [slot +$05 := $01]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 4  [$D8E3 := $0404]
    dw $D8E3                ;   address
    dw $0404                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 3: fly off up-left (the flight path set above)
    dw $1703                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF03                ; $03 set_flag: Set flag $004A
    dw $004A                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_607F:
    dw $01FC                ; text $01FC: "*:Oh gosh! I wonder if that lady is okay…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6083:
    dw $01FD                ; text $01FD: "*:The name of the spirit of GreatLog is …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6087:
    dw $0374                ; text $0374: "*:This kingdom is becoming more lively. …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_608B:
    dw $0426                ; text $0426: "*:For victory! I will sing for your vict…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_608F:
    dw $05ED                ; text $05ED: "*:La la la [HERO] and Milayou La la la..…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script08
; ---------------------------------------------------------------------------
Bazaar_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_60BB
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_60BB ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_60B7
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_60B7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_60B3
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_60B3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $004B is set → Bank0C_ScriptAddr_60AF
    dw $004B                ;   flag
    dw Bank0C_ScriptAddr_60AF ;   target
    dw $0160                ; text $0160: "*:During this season, everyone speaks on…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_60AF:
    dw $01FE                ; text $01FE: "*:Warubou... It's a name that I will nev…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_60B3:
    dw $0375                ; text $0375: "*:I heard that wishes on the Starry Nigh…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_60B7:
    dw $0427                ; text $0427: "*:Everybody is partying because it's the…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_60BB:
    dw $05EE                ; text $05EE: "*:I didn't think you could win..."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script09
; ---------------------------------------------------------------------------
Bazaar_Script09:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_60FD
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_60FD ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_60F9
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_60F9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0079 is set → Bank0C_ScriptAddr_60E7
    dw $0079                ;   flag
    dw Bank0C_ScriptAddr_60E7 ;   target
    dw $02C5                ; text $02C5: "*:Hi, are you a monster master? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_60E3  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_60E3 ;   target
    dw $02C6                ; text $02C6: "*:Wow that's great! I wanna be a monster…"
    dw $FF03                ; $03 set_flag: Set flag $0079
    dw $0079                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_60E3:
    dw $02C7                ; text $02C7: "*:I heard that only people who have the …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_60E7:
    dw $02C5                ; text $02C5: "*:Hi, are you a monster master? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_60F5  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_60F5 ;   target
    dw $0029                ; text $0029: "*:I wanna be a master. What should I do?"
    dw $FFFF                ; END

Bank0C_ScriptAddr_60F5:
    dw $02C7                ; text $02C7: "*:I heard that only people who have the …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_60F9:
    dw $0428                ; text $0428: "*:Eek eek eek! *:Mister! I wanna be a ma…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_60FD:
    dw $05EF                ; text $05EF: "*:Giggle giggle! Listen listen! *:I can …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script10
; ---------------------------------------------------------------------------
Bazaar_Script10:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6161
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6161 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_614F
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_614F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $007A is set → Bank0C_ScriptAddr_613D
    dw $007A                ;   flag
    dw Bank0C_ScriptAddr_613D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_6127
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_6127 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_6123
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_6123 ;   target
    dw $0161                ; text $0161: "*:There were stores here at the last Sta…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6123:
    dw $01FF                ; text $01FF: "*:When GreatTree grows, huge earthquakes…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6127:
    dw $02C8                ; text $02C8: "*:Wow! The quake made the Bazaar bigger!…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6139  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6139 ;   target
    dw $02CA                ; text $02CA: "*:A SageStone and WorldDew recover HP. *…"
    dw $FF03                ; $03 set_flag: Set flag $007A
    dw $007A                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_6139:
    dw $02C9                ; text $02C9: "*:No? You must be a veteran!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_613D:
    dw $02CB                ; text $02CB: "*:I did research on what's available in …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_614B  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_614B ;   target
    dw $02CA                ; text $02CA: "*:A SageStone and WorldDew recover HP. *…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_614B:
    dw $02C9                ; text $02C9: "*:No? You must be a veteran!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_614F:
    dw $0429                ; text $0429: "*:Festivals are fun! *:Want to learn abo…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_615D  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_615D ;   target
    dw $02CA                ; text $02CA: "*:A SageStone and WorldDew recover HP. *…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_615D:
    dw $042A                ; text $042A: "*:Oh, of course. You're the rep!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6161:
    dw $05F0                ; text $05F0: "*:Well well, Congratulations!! I love fe…"
    dw $FFFF                ; END

    dw $05F1                ; not reached — as a script word: text $05F1: "*:Well of course! You're the victor!"
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
; ---------------------------------------------------------------------------
; Bazaar_Script11
; ---------------------------------------------------------------------------
Bazaar_Script11:
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
; ---------------------------------------------------------------------------
; Bazaar_Script12
; ---------------------------------------------------------------------------
Bazaar_Script12:
    dw $0680                ; text $0680: "*:Item shop. May I help you?"
    dw $FF04                ; $04 open_screen: Open the shop (its texts begin “*:Item shop. May I help you?”)
    dw $0000                ;   kind
    dw $0680                ;   text
    dw $0682                ; text $0682: "*:Thank you. Come again!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script13
; ---------------------------------------------------------------------------
Bazaar_Script13:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6191
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6191 ;   target
    dw $042B                ; text $042B: "*:Hi little master! *:What a gloomy face…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_618D  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_618D ;   target
    dw $042D                ; text $042D: "*:...tickle,tickle ... tickle,tickle *:t…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_618D:
    dw $042C                ; text $042C: "*:Okay. Good luck!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6191:
    dw $05F2                ; text $05F2: "*:Hi! *:How about a reward for your vict…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_619F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_619F ;   target
    dw $05F4                ; text $05F4: "*:...tickle ...tickle, tickle *:tickle, …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_619F:
    dw $05F3                ; text $05F3: "*:Okay."
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Bazaar_Script14
; ---------------------------------------------------------------------------
Bazaar_Script14:
    dw $FF01                ; $01 if_flag_set: If flag $009D is set → Bank0C_ScriptAddr_61CD
    dw $009D                ;   flag
    dw Bank0C_ScriptAddr_61CD ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_61BD
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_61BD ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_61B9
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_61B9 ;   target
    dw $0163                ; text $0163: "*:You? A master? You're just a kid. *:Sc…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_61B9:
    dw $0200                ; text $0200: "*:Keep out! Keep out! I don't need any b…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_61BD:
    dw $042F                ; text $042F: "*:I've been alone for a long time. *:I'm…"
    dw $FF03                ; $03 set_flag: Set flag $009D
    dw $009D                ;   flag
    dw $FF04                ; $04 open_screen: Open the shop (its texts begin “*:Item shop. May I help you?”)
    dw $0000                ;   kind
    dw $0680                ;   text
    dw $0682                ; text $0682: "*:Thank you. Come again!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_61CD:
    dw $0680                ; text $0680: "*:Item shop. May I help you?"
    dw $FF04                ; $04 open_screen: Open the shop (its texts begin “*:Item shop. May I help you?”)
    dw $0000                ;   kind
    dw $0680                ;   text
    dw $0682                ; text $0682: "*:Thank you. Come again!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script15
; ---------------------------------------------------------------------------
Bazaar_Script15:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6223
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6223 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_6215
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_6215 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_6203
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_6203 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_61FF
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_61FF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_61FB
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_61FB ;   target
    dw $0162                ; text $0162: "*:The store there is terrible! He won't …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_61FB:
    dw $0201                ; text $0201: "*:Who does he think he is! *:If he doesn…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_61FF:
    dw $02CC                ; text $02CC: "*:Look what the quake did to us! *:That …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6203:
    dw $042E                ; text $042E: "*:Oh joy! Starry Night! *:It seems the m…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6211  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6211 ;   target
    dw $0383                ; text $0383: "*:Having a monster read a QuestBk makes …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6211:
    dw $04A4                ; text $04A4: "*:There's something good about having a …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6215:
    dw $03EF                ; text $03EF: "*:Yeah! The Starry Night has arrived! *:…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6211  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6211 ;   target
    dw $0383                ; text $0383: "*:Having a monster read a QuestBk makes …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6223:
    dw $05F5                ; text $05F5: "*:Oh, what a joy! [HERO] won! *:That mer…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6211  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6211 ;   target
    dw $0383                ; text $0383: "*:Having a monster read a QuestBk makes …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script16
; ---------------------------------------------------------------------------
Bazaar_Script16:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6291
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6291 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_627F
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_627F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_626D
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_626D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_625B
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_625B ;   target
    dw $0164                ; text $0164: "*:So, you don't have enough money to buy…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6257  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6257 ;   target
    dw $08CE                ; text $08CE: "*:Well then, go pick up a lot of items b…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6257:
    dw $08CF                ; text $08CF: "*:Yes. What is important is not money!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_625B:
    dw $02CD                ; text $02CD: "*:There is nothing around here. It looks…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6269  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6269 ;   target
    dw $02CE                ; text $02CE: "*:It'll be better if stores are built he…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6269:
    dw $02CF                ; text $02CF: "*:Don't say that. It is almost the Starr…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_626D:
    dw $0376                ; text $0376: "*:New stores have opened! *:Want to lear…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_627B  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_627B ;   target
    dw $0378                ; text $0378: "*:Sirloin is the tastiest meat in the wo…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_627B:
    dw $0377                ; text $0377: "*:No?! You must be a heck of a master to…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_627F:
    dw $0430                ; text $0430: "*:Congratulations on becoming the rep of…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_628D  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_628D ;   target
    dw $0378                ; text $0378: "*:Sirloin is the tastiest meat in the wo…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_628D:
    dw $0431                ; text $0431: "*:You said no... That's the rep of Great…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6291:
    dw $05F6                ; text $05F6: "*:Oh, the hero of GreatTree, Master [HER…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_629F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_629F ;   target
    dw $0378                ; text $0378: "*:Sirloin is the tastiest meat in the wo…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_629F:
    dw $05F7                ; text $05F7: "*:Yes, of course. The victor wouldn't as…"
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Bazaar_Script17
; ---------------------------------------------------------------------------
Bazaar_Script17:
    dw $0379                ; text $0379: "[HERO] checked out the treasure chest! I…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script18
; ---------------------------------------------------------------------------
Bazaar_Script18:
    dw $0379                ; text $0379: "[HERO] checked out the treasure chest! I…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script19
; ---------------------------------------------------------------------------
Bazaar_Script19:
    dw $0680                ; text $0680: "*:Item shop. May I help you?"
    dw $FF04                ; $04 open_screen: Open the shop (its texts begin “*:Item shop. May I help you?”)
    dw $0000                ;   kind
    dw $0680                ;   text
    dw $0682                ; text $0682: "*:Thank you. Come again!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script20
; ---------------------------------------------------------------------------
Bazaar_Script20:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_62C1
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_62C1 ;   target
    dw $0432                ; text $0432: "*:Lemme tell you a scary story. There's …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_62C1:
    dw $05F8                ; text $05F8: "*:The monstrous master was your sister!!…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script21
; ---------------------------------------------------------------------------
Bazaar_Script21:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_62CF
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_62CF ;   target
    dw $0165                ; text $0165: "[HERO] looked in front. There are some y…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_62CF:
    dw $045F                ; text $045F: "[HERO] looked in front. The fire is burn…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Bazaar_Script22
; ---------------------------------------------------------------------------
Bazaar_Script22:
    dw $FF01                ; $01 if_flag_set: If flag $00F6 is set → Bank0C_ScriptAddr_6431
    dw $00F6                ;   flag
    dw Bank0C_ScriptAddr_6431 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_642D
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_642D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $009E is set → Bank0C_ScriptAddr_6429
    dw $009E                ;   flag
    dw Bank0C_ScriptAddr_6429 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0037 is clear → Bank0C_ScriptAddr_62F1
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_62F1 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0040 is set → Bank0C_ScriptAddr_6413
    dw $0040                ;   flag
    dw Bank0C_ScriptAddr_6413 ;   target
Bank0C_ScriptAddr_62F1:
    dw $FF01                ; $01 if_flag_set: If flag $0040 is set → Bank0C_ScriptAddr_640F
    dw $0040                ;   flag
    dw Bank0C_ScriptAddr_640F ;   target
    dw $0166                ; text $0166: "*:Darn,why can't I start the fire? *:Hey…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0C_ScriptAddr_6305  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_6305 ;   target
    dw $0167                ; text $0167: "*:Can you give me a monster that makes f…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6305:
    dw $FF15                ; $15 check_and_branch: If “the number of monsters in the party” is 1 → Bank0C_ScriptAddr_6323  [$CA8D = 1]
    dw $CA8D                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6323 ;   target
    dw $FF23                ; $23 if_slot_skill_a: If party monster 1 knows skill $00 / skill $01 / skill $02 / skill $03 / skill $04 / skill $05 / skill $44 / skill $5C / skill $5D / skill $5E / skill $5F → Bank0C_ScriptAddr_6327
    dw $0000                ;   slot
    dw Bank0C_ScriptAddr_6327 ;   target
    dw $FF23                ; $23 if_slot_skill_a: If party monster 2 knows skill $00 / skill $01 / skill $02 / skill $03 / skill $04 / skill $05 / skill $44 / skill $5C / skill $5D / skill $5E / skill $5F → Bank0C_ScriptAddr_6365
    dw $0001                ;   slot
    dw Bank0C_ScriptAddr_6365 ;   target
    dw $FF23                ; $23 if_slot_skill_a: If party monster 3 knows skill $00 / skill $01 / skill $02 / skill $03 / skill $04 / skill $05 / skill $44 / skill $5C / skill $5D / skill $5E / skill $5F → Bank0C_ScriptAddr_637B
    dw $0002                ;   slot
    dw Bank0C_ScriptAddr_637B ;   target
    dw $0168                ; text $0168: "*:You don't have one? Come on!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6323:
    dw $04D9                ; text $04D9: "*:Oh, you have it! Then... *:Hm? You onl…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6327:
    dw $0169                ; text $0169: "*:Oh you have one! Then..."
    dw $016A                ; text $016A: "Can you give us your [INS 00]? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0C_ScriptAddr_638B  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_638B ;   target
    dw $FF23                ; $23 if_slot_skill_a: If party monster 2 knows skill $00 / skill $01 / skill $02 / skill $03 / skill $04 / skill $05 / skill $44 / skill $5C / skill $5D / skill $5E / skill $5F → Bank0C_ScriptAddr_6343
    dw $0001                ;   slot
    dw Bank0C_ScriptAddr_6343 ;   target
    dw $FF23                ; $23 if_slot_skill_a: If party monster 3 knows skill $00 / skill $01 / skill $02 / skill $03 / skill $04 / skill $05 / skill $44 / skill $5C / skill $5D / skill $5E / skill $5F → Bank0C_ScriptAddr_6357
    dw $0002                ;   slot
    dw Bank0C_ScriptAddr_6357 ;   target
    dw $016D                ; text $016D: "*:Well,too bad..."
    dw $FFFF                ; END
Bank0C_ScriptAddr_6343:
    dw $016E                ; text $016E: "*:Well then, can I have [INS 00]? [YES/N…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0C_ScriptAddr_638B  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_638B ;   target
    dw $FF23                ; $23 if_slot_skill_a: If party monster 3 knows skill $00 / skill $01 / skill $02 / skill $03 / skill $04 / skill $05 / skill $44 / skill $5C / skill $5D / skill $5E / skill $5F → Bank0C_ScriptAddr_6357
    dw $0002                ;   slot
    dw Bank0C_ScriptAddr_6357 ;   target
    dw $016D                ; text $016D: "*:Well,too bad..."
    dw $FFFF                ; END
Bank0C_ScriptAddr_6357:
    dw $016E                ; text $016E: "*:Well then, can I have [INS 00]? [YES/N…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0C_ScriptAddr_638B  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_638B ;   target
    dw $016D                ; text $016D: "*:Well,too bad..."
    dw $FFFF                ; END
Bank0C_ScriptAddr_6365:
    dw $0169                ; text $0169: "*:Oh you have one! Then..."
    dw $016A                ; text $016A: "Can you give us your [INS 00]? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0C_ScriptAddr_638B  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_638B ;   target
    dw $FF23                ; $23 if_slot_skill_a: If party monster 3 knows skill $00 / skill $01 / skill $02 / skill $03 / skill $04 / skill $05 / skill $44 / skill $5C / skill $5D / skill $5E / skill $5F → Bank0C_ScriptAddr_6357
    dw $0002                ;   slot
    dw Bank0C_ScriptAddr_6357 ;   target
    dw $016D                ; text $016D: "*:Well,too bad..."
    dw $FFFF                ; END
Bank0C_ScriptAddr_637B:
    dw $0169                ; text $0169: "*:Oh you have one! Then..."
    dw $016A                ; text $016A: "Can you give us your [INS 00]? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0C_ScriptAddr_638B  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_638B ;   target
    dw $016D                ; text $016D: "*:Well,too bad..."
    dw $FFFF                ; END
Bank0C_ScriptAddr_638B:
    dw $016B                ; text $016B: "[HERO] gave your [INS 00]!"
    dw $08D3                ; text $08D3: "*:Yeay! Thanks a lot! *:Now I can light …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF25                ; $25 remove_monster: Remove the monster picked by the last party check ($D8E1)
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $643D)
    dw Bank0C_TilePatch_643D ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6435)
    dw Bank0C_TilePatch_6435 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $644D)
    dw Bank0C_TilePatch_644D ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6445)
    dw Bank0C_TilePatch_6445 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $643D)
    dw Bank0C_TilePatch_643D ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6435)
    dw Bank0C_TilePatch_6435 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $644D)
    dw Bank0C_TilePatch_644D ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6445)
    dw Bank0C_TilePatch_6445 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $643D)
    dw Bank0C_TilePatch_643D ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6435)
    dw Bank0C_TilePatch_6435 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $644D)
    dw Bank0C_TilePatch_644D ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6445)
    dw Bank0C_TilePatch_6445 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $643D)
    dw Bank0C_TilePatch_643D ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6435)
    dw Bank0C_TilePatch_6435 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $644D)
    dw Bank0C_TilePatch_644D ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6445)
    dw Bank0C_TilePatch_6445 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $643D)
    dw Bank0C_TilePatch_643D ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6435)
    dw Bank0C_TilePatch_6435 ;   data
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $016C                ; text $016C: "*:Wow! No way! *:Such a thing in a place…"
    dw $FF03                ; $03 set_flag: Set flag $0040
    dw $0040                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 1  [$D93A := 1]
    dw $D93A                ;   address
    dw $0001                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_640F:
    dw $016F                ; text $016F: "*:Where does this Travelers' Gate go?"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6413:
    dw $0434                ; text $0434: "*:I'm betting on which kingdom will win.…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6421  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6421 ;   target
    dw $0435                ; text $0435: "*:Whaat? 100 thousand in gold for [HERO]…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6421:
    dw $0436                ; text $0436: "*:My god, up close, I see you're [HERO]!…"
    dw $FF03                ; $03 set_flag: Set flag $009E
    dw $009E                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_6429:
    dw $0437                ; text $0437: "*:I bet on [HERO]! Do your best!!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_642D:
    dw $05F9                ; text $05F9: "*:Hey! Our hero [HERO]! *:The two of us …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6431:
    dw $07A0                ; text $07A0: "*:Looking at the Travelers' Gate makes m…"
    dw $FFFF                ; END

Bank0C_TilePatch_6435:
    db $46, $00, $70, $71, $D8, $72, $73, $D9  ; tile patch (op $24): BG offset $0046 (row 2, column 6), tiles 70 71 / 72 73; $D8 = next row, $D9 = end
Bank0C_TilePatch_643D:
    db $46, $00, $03, $03, $D8, $03, $03, $D9  ; tile patch (op $61): BG offset $0046 (row 2, column 6), colours 03 03 / 03 03; $D8 = next row, $D9 = end
Bank0C_TilePatch_6445:
    db $46, $00, $40, $41, $D8, $42, $43, $D9  ; tile patch (op $24): BG offset $0046 (row 2, column 6), tiles 40 41 / 42 43; $D8 = next row, $D9 = end
Bank0C_TilePatch_644D:
    db $46, $00, $02, $02, $D8, $02, $02, $D9  ; tile patch (op $61): BG offset $0046 (row 2, column 6), colours 02 02 / 02 02; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Bazaar_Script23
; ---------------------------------------------------------------------------
Bazaar_Script23:
    dw $FF01                ; $01 if_flag_set: If flag $00F6 is set → Bank0C_ScriptAddr_6559
    dw $00F6                ;   flag
    dw Bank0C_ScriptAddr_6559 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F5 is set → Bank0C_ScriptAddr_648D
    dw $00F5                ;   flag
    dw Bank0C_ScriptAddr_648D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6485
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6485 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0037 is clear → Bank0C_ScriptAddr_6473
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_6473 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0040 is set → Bank0C_ScriptAddr_6481
    dw $0040                ;   flag
    dw Bank0C_ScriptAddr_6481 ;   target
Bank0C_ScriptAddr_6473:
    dw $FF01                ; $01 if_flag_set: If flag $0040 is set → Bank0C_ScriptAddr_647D
    dw $0040                ;   flag
    dw Bank0C_ScriptAddr_647D ;   target
    dw $0170                ; text $0170: "*:AArrggh! I'm starving!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_647D:
    dw $0171                ; text $0171: "*:Gwrrr! Is this the Travelers' Gate?"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6481:
    dw $0438                ; text $0438: "*:GWWRRR! It's GreatLog! Of course it sh…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6485:
    dw $05FA                ; text $05FA: "*:Missing... Something missing. *:Entert…"
    dw $FF03                ; $03 set_flag: Set flag $00F5
    dw $00F5                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_648D:
    dw $05FB                ; text $05FB: "*:...I wonder if you brought a monster w…"
    dw $FF38                ; $38 if_slot_skill_c: If party monster 1 knows skill $84 / skill $85 / skill $86 / skill $87 → Bank0C_ScriptAddr_64A5
    dw $0000                ;   slot
    dw Bank0C_ScriptAddr_64A5 ;   target
    dw $FF38                ; $38 if_slot_skill_c: If party monster 2 knows skill $84 / skill $85 / skill $86 / skill $87 → Bank0C_ScriptAddr_64A5
    dw $0001                ;   slot
    dw Bank0C_ScriptAddr_64A5 ;   target
    dw $FF38                ; $38 if_slot_skill_c: If party monster 3 knows skill $84 / skill $85 / skill $86 / skill $87 → Bank0C_ScriptAddr_64A5
    dw $0002                ;   slot
    dw Bank0C_ScriptAddr_64A5 ;   target
    dw $0204                ; text $0204: "*:Oh well, nobody's here. I wanna have e…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_64A5:
    dw $05FC                ; text $05FC: "*:Oh! You brought it here! Show me the m…"
    dw $05FD                ; text $05FD: "[INS 00] cast Call! But nothing happened…"
    dw $05FE                ; text $05FE: "*:What the heck? Nothing happened! What'…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6565)
    dw Bank0C_TilePatch_6565 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $655D)
    dw Bank0C_TilePatch_655D ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6575)
    dw Bank0C_TilePatch_6575 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $656D)
    dw Bank0C_TilePatch_656D ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6565)
    dw Bank0C_TilePatch_6565 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $655D)
    dw Bank0C_TilePatch_655D ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6575)
    dw Bank0C_TilePatch_6575 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $656D)
    dw Bank0C_TilePatch_656D ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6565)
    dw Bank0C_TilePatch_6565 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $655D)
    dw Bank0C_TilePatch_655D ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6575)
    dw Bank0C_TilePatch_6575 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $656D)
    dw Bank0C_TilePatch_656D ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6565)
    dw Bank0C_TilePatch_6565 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $655D)
    dw Bank0C_TilePatch_655D ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6575)
    dw Bank0C_TilePatch_6575 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $656D)
    dw Bank0C_TilePatch_656D ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6565)
    dw Bank0C_TilePatch_6565 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $655D)
    dw Bank0C_TilePatch_655D ;   data
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05FF                ; text $05FF: "*:You knew it right? This is the Travele…"
    dw $FF03                ; $03 set_flag: Set flag $00F6
    dw $00F6                ;   flag
    dw $FF00                ; $00 if_flag_clear: If flag $0015 is clear → Bank0C_ScriptAddr_652D
    dw $0015                ;   flag
    dw Bank0C_ScriptAddr_652D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $002D is set → Bank0C_ScriptAddr_6551
    dw $002D                ;   flag
    dw Bank0C_ScriptAddr_6551 ;   target
Bank0C_ScriptAddr_652D:
    dw $FF01                ; $01 if_flag_set: If flag $002D is set → Bank0C_ScriptAddr_6549
    dw $002D                ;   flag
    dw Bank0C_ScriptAddr_6549 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0015 is set → Bank0C_ScriptAddr_6541
    dw $0015                ;   flag
    dw Bank0C_ScriptAddr_6541 ;   target
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 5  [$D93A := 5]
    dw $D93A                ;   address
    dw $0005                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_6541:
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 6  [$D93A := 6]
    dw $D93A                ;   address
    dw $0006                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_6549:
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 7  [$D93A := 7]
    dw $D93A                ;   address
    dw $0007                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_6551:
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 8  [$D93A := 8]
    dw $D93A                ;   address
    dw $0008                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_6559:
    dw $07A1                ; text $07A1: "*:I wonder where this Travelers' Gate le…"
    dw $FFFF                ; END

Bank0C_TilePatch_655D:
    db $0E, $01, $70, $71, $D8, $72, $73, $D9  ; tile patch (op $24): BG offset $010E (row 8, column 14), tiles 70 71 / 72 73; $D8 = next row, $D9 = end
Bank0C_TilePatch_6565:
    db $0E, $01, $03, $03, $D8, $03, $03, $D9  ; tile patch (op $61): BG offset $010E (row 8, column 14), colours 03 03 / 03 03; $D8 = next row, $D9 = end
Bank0C_TilePatch_656D:
    db $0E, $01, $40, $41, $D8, $42, $43, $D9  ; tile patch (op $24): BG offset $010E (row 8, column 14), tiles 40 41 / 42 43; $D8 = next row, $D9 = end
Bank0C_TilePatch_6575:
    db $0E, $01, $02, $02, $D8, $02, $02, $D9  ; tile patch (op $61): BG offset $010E (row 8, column 14), colours 02 02 / 02 02; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Bazaar_Script24
; ---------------------------------------------------------------------------
Bazaar_Script24:
    dw $FF01                ; $01 if_flag_set: If flag $00F3 is set → Bank0C_ScriptAddr_661D
    dw $00F3                ;   flag
    dw Bank0C_ScriptAddr_661D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_660F
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_660F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_6601
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_6601 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_65F3
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_65F3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_65E5
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_65E5 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_65D7
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_65D7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0045 is set → Bank0C_ScriptAddr_65C9
    dw $0045                ;   flag
    dw Bank0C_ScriptAddr_65C9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0C_ScriptAddr_65BB
    dw $0031                ;   flag
    dw Bank0C_ScriptAddr_65BB ;   target
    dw $0172                ; text $0172: "*:I am an old gypsy woman. Want me to te…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_662F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_662F ;   target
    dw $0173                ; text $0173: "*:Hmm,When you are recognized as being m…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_65BB:
    dw $0172                ; text $0172: "*:I am an old gypsy woman. Want me to te…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_662F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_662F ;   target
    dw $01B3                ; text $01B3: "*:Meet the old man of the Shrine of Star…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_65C9:
    dw $0172                ; text $0172: "*:I am an old gypsy woman. Want me to te…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_662F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_662F ;   target
    dw $0202                ; text $0202: "*:Oh! I see! There's a monster in front …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_65D7:
    dw $0172                ; text $0172: "*:I am an old gypsy woman. Want me to te…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_662F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_662F ;   target
    dw $02D0                ; text $02D0: "*:Hm. It seems there are several gates h…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_65E5:
    dw $0172                ; text $0172: "*:I am an old gypsy woman. Want me to te…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_662F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_662F ;   target
    dw $037A                ; text $037A: "*:Hm.. It seems there are several hidden…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_65F3:
    dw $0172                ; text $0172: "*:I am an old gypsy woman. Want me to te…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_662F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_662F ;   target
    dw $0433                ; text $0433: "*:Ohh!! You'll really go to see your fut…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6601:
    dw $0172                ; text $0172: "*:I am an old gypsy woman. Want me to te…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_662F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_662F ;   target
    dw $049D                ; text $049D: "*:A surprise awaits you in your future! …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_660F:
    dw $0172                ; text $0172: "*:I am an old gypsy woman. Want me to te…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_662F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_662F ;   target
    dw $0358                ; text $0358: "*:..Hm. A girl... named San... something…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_661D:
    dw $0172                ; text $0172: "*:I am an old gypsy woman. Want me to te…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_662B  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_662B ;   target
    dw $03D7                ; text $03D7: "*:I can see.. I can see! It's a never be…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_662B:
    dw $0349                ; text $0349: "*:Well. You have to find your own way!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_662F:
    dw $0174                ; text $0174: "*:Well. You have to create your own way.…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub Per-Script Table (map_type=$03, 20 scripts)
; ---------------------------------------------------------------------------
GateHub_ScriptPtrTable:
    dw GateHub_Script00     ; script 0
    dw GateHub_Script01     ; script 1
    dw GateHub_Script02     ; script 2
    dw GateHub_Script03     ; script 3
    dw GateHub_Script04     ; script 4
    dw GateHub_Script05     ; script 5
    dw GateHub_Script06     ; script 6
    dw GateHub_Script07     ; script 7
    dw GateHub_Script08     ; script 8
    dw GateHub_Script09     ; script 9
    dw GateHub_Script10     ; script 10
    dw GateHub_Script11     ; script 11
    dw GateHub_Script12     ; script 12
    dw GateHub_Script13     ; script 13
    dw GateHub_Script14     ; script 14
    dw GateHub_Script15     ; script 15
    dw GateHub_Script16     ; script 16
    dw GateHub_Script17     ; script 17
    dw GateHub_Script18     ; script 18
    dw GateHub_Script19     ; script 19
; ---------------------------------------------------------------------------
; GateHub_Script00
; ---------------------------------------------------------------------------
GateHub_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script01
; ---------------------------------------------------------------------------
GateHub_Script01:
    dw $0133                ; text $0133: "The Gate is shut tight. Something's engr…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script02
; ---------------------------------------------------------------------------
GateHub_Script02:
    dw $0132                ; text $0132: "The Gate is shut tight."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script03
; ---------------------------------------------------------------------------
GateHub_Script03:
    dw $0134                ; text $0134: "The Gate is shut tight."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script04
; ---------------------------------------------------------------------------
GateHub_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6759
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6759 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_6741
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_6741 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_6729
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_6729 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_6711
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_6711 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0C_ScriptAddr_66F9
    dw $0034                ;   flag
    dw Bank0C_ScriptAddr_66F9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_66E1
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_66E1 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0C_ScriptAddr_66C9
    dw $0033                ;   flag
    dw Bank0C_ScriptAddr_66C9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_66B1
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_66B1 ;   target
    dw $0066                ; text $0066: "*:Would you like to see the list of Trav…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_66AD  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_66AD ;   target
    dw $FF04                ; $04 open_screen: Open the list of Travelers' Gates
    dw $000D                ;   kind
    dw $0000                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
Bank0C_ScriptAddr_66AD:
    dw $047E                ; text $047E: "*:Good luck on your journey!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_66B1:
    dw $0066                ; text $0066: "*:Would you like to see the list of Trav…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_66C5  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_66C5 ;   target
    dw $FF04                ; $04 open_screen: Open the list of Travelers' Gates
    dw $000D                ;   kind
    dw $0000                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
Bank0C_ScriptAddr_66C5:
    dw $0203                ; text $0203: "*:The Room of Peace & Bravery is open no…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_66C9:
    dw $0066                ; text $0066: "*:Would you like to see the list of Trav…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_66DD  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_66DD ;   target
    dw $FF04                ; $04 open_screen: Open the list of Travelers' Gates
    dw $000D                ;   kind
    dw $0000                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
Bank0C_ScriptAddr_66DD:
    dw $0278                ; text $0278: "*:The Room of Strength & Anger is in the…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_66E1:
    dw $0066                ; text $0066: "*:Would you like to see the list of Trav…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_66F5  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_66F5 ;   target
    dw $FF04                ; $04 open_screen: Open the list of Travelers' Gates
    dw $000D                ;   kind
    dw $0000                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
Bank0C_ScriptAddr_66F5:
    dw $02D1                ; text $02D1: "*:The room in the center is the Room of …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_66F9:
    dw $0066                ; text $0066: "*:Would you like to see the list of Trav…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_670D  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_670D ;   target
    dw $FF04                ; $04 open_screen: Open the list of Travelers' Gates
    dw $000D                ;   kind
    dw $0000                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
Bank0C_ScriptAddr_670D:
    dw $033D                ; text $033D: "*:Well done on surviving C class! Go lef…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6711:
    dw $0066                ; text $0066: "*:Would you like to see the list of Trav…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6725  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6725 ;   target
    dw $FF04                ; $04 open_screen: Open the list of Travelers' Gates
    dw $000D                ;   kind
    dw $0000                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
Bank0C_ScriptAddr_6725:
    dw $037B                ; text $037B: "*:Go left to the Room of Joy & Wisdom. *…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6729:
    dw $0066                ; text $0066: "*:Would you like to see the list of Trav…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_673D  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_673D ;   target
    dw $FF04                ; $04 open_screen: Open the list of Travelers' Gates
    dw $000D                ;   kind
    dw $0000                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
Bank0C_ScriptAddr_673D:
    dw $0439                ; text $0439: "*:Good work on surviving S class. All ro…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6741:
    dw $0066                ; text $0066: "*:Would you like to see the list of Trav…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6755  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6755 ;   target
    dw $FF04                ; $04 open_screen: Open the list of Travelers' Gates
    dw $000D                ;   kind
    dw $0000                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
Bank0C_ScriptAddr_6755:
    dw $049E                ; text $049E: "*:I wish you good luck! All rooms are no…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6759:
    dw $0066                ; text $0066: "*:Would you like to see the list of Trav…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_676D  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_676D ;   target
    dw $FF04                ; $04 open_screen: Open the list of Travelers' Gates
    dw $000D                ;   kind
    dw $0000                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
Bank0C_ScriptAddr_676D:
    dw $07A2                ; text $07A2: "*:Oh, Master [HERO] Welcome back! *:Go l…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script05
; ---------------------------------------------------------------------------
GateHub_Script05:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script06
; ---------------------------------------------------------------------------
GateHub_Script06:
    dw $0130                ; text $0130: "The Gate is shut tight."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script07
; ---------------------------------------------------------------------------
GateHub_Script07:
    dw $0131                ; text $0131: "The Gate is shut tight."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script08
; ---------------------------------------------------------------------------
GateHub_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0C_ScriptAddr_6785
    dw $0009                ;   flag
    dw Bank0C_ScriptAddr_6785 ;   target
    dw $0054                ; text $0054: "*:You will find items scattered around i…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6785:
    dw $0067                ; text $0067: "*:You can enter the locked rooms only wh…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script09
; ---------------------------------------------------------------------------
GateHub_Script09:
    dw $0055                ; text $0055: "*:Hale was the cherished pet of the King…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script10
; ---------------------------------------------------------------------------
GateHub_Script10:
    dw $FF01                ; $01 if_flag_set: If flag $00F8 is set → Bank0C_ScriptAddr_67EB
    dw $00F8                ;   flag
    dw Bank0C_ScriptAddr_67EB ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_67E3
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_67E3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_67DF
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_67DF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_67DB
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_67DB ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0C_ScriptAddr_67D7
    dw $0033                ;   flag
    dw Bank0C_ScriptAddr_67D7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_67D3
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_67D3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0C_ScriptAddr_67CF
    dw $0031                ;   flag
    dw Bank0C_ScriptAddr_67CF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0C_ScriptAddr_67CB
    dw $0030                ;   flag
    dw Bank0C_ScriptAddr_67CB ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0010 is set → Bank0C_ScriptAddr_67C7
    dw $0010                ;   flag
    dw Bank0C_ScriptAddr_67C7 ;   target
    dw $0056                ; text $0056: "*:Welcome to the Chamber of Travelers' G…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_67C7:
    dw $0487                ; text $0487: "*:You're at the Chamber of Travelers' Ga…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_67CB:
    dw $0175                ; text $0175: "*:Here's the Travelers' Chamber. *:The R…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_67CF:
    dw $01B4                ; text $01B4: "*:Here you are at the Chamber of Travele…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_67D3:
    dw $08D0                ; text $08D0: "*:You're at the Chamber of Travelers' Ga…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_67D7:
    dw $0279                ; text $0279: "*:You're at the Chamber of Traverlers' G…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_67DB:
    dw $02D2                ; text $02D2: "*:You're at the Chamber of Travelers' Ga…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_67DF:
    dw $043B                ; text $043B: "*:Go left to the Room of Villager & Tali…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_67E3:
    dw $07A4                ; text $07A4: "*:Oh it's Sir [HERO]! You're at the Cham…"
    dw $FF03                ; $03 set_flag: Set flag $00F8
    dw $00F8                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_67EB:
    dw $07A5                ; text $07A5: "*:Ah it's Master [HERO]! You're at the C…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script11
; ---------------------------------------------------------------------------
GateHub_Script11:
    dw $0136                ; text $0136: "The Gate is shut tight."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script12
; ---------------------------------------------------------------------------
GateHub_Script12:
    dw $0135                ; text $0135: "The Gate is shut tight."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script13
; ---------------------------------------------------------------------------
GateHub_Script13:
    dw $00DD                ; text $00DD: "The door is shut tight."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script14
; ---------------------------------------------------------------------------
GateHub_Script14:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6831
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6831 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00A0 is set → Bank0C_ScriptAddr_682D
    dw $00A0                ;   flag
    dw Bank0C_ScriptAddr_682D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_6825
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_6825 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0C_ScriptAddr_6821
    dw $0036                ;   flag
    dw Bank0C_ScriptAddr_6821 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_681D
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_681D ;   target
    dw $0067                ; text $0067: "*:You can enter the locked rooms only wh…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_681D:
    dw $037C                ; text $037C: "*:The Room of Happiness & Temptation are…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6821:
    dw $03EA                ; text $03EA: "*:You're in the Chamber of Travelers' Ga…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6825:
    dw $043C                ; text $043C: "*:At last you became the Master of Great…"
    dw $FF03                ; $03 set_flag: Set flag $00A0
    dw $00A0                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_682D:
    dw $043D                ; text $043D: "*:Oh, the rep of GreatTree, Master [HERO…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6831:
    dw $07A6                ; text $07A6: "*:The path on the right side was just op…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script15
; ---------------------------------------------------------------------------
GateHub_Script15:
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_6863
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_6863 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0022 is clear → Bank0C_ScriptAddr_6847
    dw $0022                ;   flag
    dw Bank0C_ScriptAddr_6847 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_685F
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_685F ;   target
Bank0C_ScriptAddr_6847:
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0C_ScriptAddr_685B
    dw $0036                ;   flag
    dw Bank0C_ScriptAddr_685B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_6857
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_6857 ;   target
    dw $0068                ; text $0068: "*:Monsters have personalities too. *:Dep…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6857:
    dw $037D                ; text $037D: "*:Good work! Have you found strong monst…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_685B:
    dw $03EB                ; text $03EB: "*:Behind the Gate of Labyrinth there rea…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_685F:
    dw $043E                ; text $043E: "*:They say people see the future behind …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6863:
    dw $04A0                ; text $04A0: "*:What kind of future did you see behind…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script16
; ---------------------------------------------------------------------------
GateHub_Script16:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script17
; ---------------------------------------------------------------------------
GateHub_Script17:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script18
; ---------------------------------------------------------------------------
GateHub_Script18:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateHub_Script19
; ---------------------------------------------------------------------------
GateHub_Script19:
    dw $FF01                ; $01 if_flag_set: If flag $00FA is set → Bank0C_ScriptAddr_687B
    dw $00FA                ;   flag
    dw Bank0C_ScriptAddr_687B ;   target
    dw $07A8                ; text $07A8: "*:Welcome to the new Chamber of Traveler…"
    dw $FF03                ; $03 set_flag: Set flag $00FA
    dw $00FA                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_687B:
    dw $07A9                ; text $07A9: "*:Welcome to the new Chamber of Traveler…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm Per-Script Table (map_type=$04, 43 scripts)
; ---------------------------------------------------------------------------
Farm_ScriptPtrTable:
    dw Farm_Script00        ; script 0
    dw Farm_Script01        ; script 1
    dw Farm_Script02        ; script 2
    dw Farm_Script03        ; script 3
    dw Farm_Script04        ; script 4
    dw Farm_Script05        ; script 5
    dw Farm_Script06        ; script 6
    dw Farm_Script07        ; script 7
    dw Farm_Script08        ; script 8
    dw Farm_Script09        ; script 9
    dw Farm_Script10        ; script 10
    dw Farm_Script11        ; script 11
    dw Farm_Script12        ; script 12
    dw Farm_Script13        ; script 13
    dw Farm_Script14        ; script 14
    dw Farm_Script15        ; script 15
    dw Farm_Script16        ; script 16
    dw Farm_Script17        ; script 17
    dw Farm_Script18        ; script 18
    dw Farm_Script19        ; script 19
    dw Farm_Script20        ; script 20
    dw Farm_Script21        ; script 21
    dw Farm_Script22        ; script 22
    dw Farm_Script23        ; script 23
    dw Farm_Script24        ; script 24
    dw Farm_Script25        ; script 25
    dw Farm_Script26        ; script 26
    dw Farm_Script27        ; script 27
    dw Farm_Script28        ; script 28
    dw Farm_Script29        ; script 29
    dw Farm_Script30        ; script 30
    dw Farm_Script31        ; script 31
    dw Farm_Script32        ; script 32
    dw Farm_Script33        ; script 33
    dw Farm_Script34        ; script 34
    dw Farm_Script35        ; script 35
    dw Farm_Script36        ; script 36
    dw Farm_Script37        ; script 37
    dw Farm_Script38        ; script 38
    dw Farm_Script39        ; script 39
    dw Farm_Script40        ; script 40
    dw Farm_Script41        ; script 41
    dw Farm_Script42        ; script 42
; ---------------------------------------------------------------------------
; Farm_Script00
; ---------------------------------------------------------------------------
Farm_Script00:
    dw $FF0E                ; $0E branch_screen: If on screen 1 → Bank0C_ScriptAddr_68E3
    dw $0001                ;   screen
    dw Bank0C_ScriptAddr_68E3 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 6 → Bank0C_ScriptAddr_6965
    dw $0006                ;   screen
    dw Bank0C_ScriptAddr_6965 ;   target
Bank0C_ScriptAddr_68E1:
    dw $FFFF                ; END

Bank0C_ScriptAddr_68E3:
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0C_ScriptAddr_68E1
    dw $00EE                ;   flag
    dw Bank0C_ScriptAddr_68E1 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E5 is set → Bank0C_ScriptAddr_68E1
    dw $00E5                ;   flag
    dw Bank0C_ScriptAddr_68E1 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0C_ScriptAddr_68F7
    dw $00E4                ;   flag
    dw Bank0C_ScriptAddr_68F7 ;   target
    dw $FFFF                ; END

Bank0C_ScriptAddr_68F7:
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $04EF                ; text $04EF: "King:Oh [HERO]! Well done! You won!! Kin…"
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF47                ; $47 face_up: NPC 3 faces up
    dw $0003                ;   actor
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF47                ; $47 face_up: NPC 5 faces up
    dw $0005                ;   actor
    dw $FF47                ; $47 face_up: NPC 6 faces up
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF12                ; $12 write_ram: The game mode: the bank $02 picture scenes (the ceremony, the tree)  [$C88A := 3]
    dw $C88A                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: The next game mode: the title screen  [$C88B := 0]
    dw $C88B                ;   address
    dw $0000                ;   value
    dw $FF3E                ; $3E change_game_mode: Fade out and switch to the game mode in $C88B (e.g. a naming screen) — $C88E is the main loop's mode request
    dw $FF03                ; $03 set_flag: Set flag $00E5
    dw $00E5                ;   flag
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $04F0                ; text $04F0: "King:Your wish will be granted by the st…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0C_ScriptAddr_6961  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_6961 ;   target
    dw $04F1                ; text $04F1: "King:You don't want to. I understand. Yo…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6961:
    dw $04F2                ; text $04F2: "King:Oh!! You will stay in GreatTree. Ki…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6965:
    dw $FF15                ; $15 check_and_branch: If “arriving at the Farm by the Shrine warp” is no  (meaning inferred from the scripts that use it) → Bank0C_ScriptAddr_68E1  [$D9E2 = 0]
    dw $D9E2                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_68E1 ;   target
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6A55)
    dw Bank0C_TilePatch_6A55 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $69EF)
    dw Bank0C_TilePatch_69EF ;   data
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6A5D)
    dw Bank0C_TilePatch_6A5D ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $69F7)
    dw Bank0C_TilePatch_69F7 ;   data
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6A6B)
    dw Bank0C_TilePatch_6A6B ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6A05)
    dw Bank0C_TilePatch_6A05 ;   data
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6A7F)
    dw Bank0C_TilePatch_6A7F ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6A19)
    dw Bank0C_TilePatch_6A19 ;   data
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6A93)
    dw Bank0C_TilePatch_6A93 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6A2D)
    dw Bank0C_TilePatch_6A2D ;   data
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $6AA7)
    dw Bank0C_TilePatch_6AA7 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6A41)
    dw Bank0C_TilePatch_6A41 ;   data
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks up 5 tiles (script waits)
    dw $0000                ;   actor
    dw $FFB0                ;   pixels
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1C                ; $1C trigger_anim: the player: leap 4 tiles left
    dw $0700                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1C                ; $1C trigger_anim: the player: pause 64 frames (followers catch up)
    dw $0600                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF12                ; $12 write_ram: Arriving at the Farm by the Shrine warp: no  [$D9E2 := 0]  (meaning inferred from the scripts that use it)
    dw $D9E2                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0C_TilePatch_69EF:
    db $D0, $01, $40, $41, $D8, $42, $43, $D9  ; tile patch (op $24): BG offset $01D0 (row 14, column 16), tiles 40 41 / 42 43; $D8 = next row, $D9 = end
Bank0C_TilePatch_69F7:
    db $90, $01, $40, $41, $D8, $42, $43, $D8, $44, $45, $D8, $46, $47, $D9  ; tile patch (op $24): BG offset $0190 (row 12, column 16), tiles 40 41 / 42 43 / 44 45 / 46 47; $D8 = next row, $D9 = end
Bank0C_TilePatch_6A05:
    db $50, $01, $40, $41, $D8, $42, $43, $D8, $44, $45, $D8, $46, $47, $D8, $48, $49, $D8, $4A, $4B, $D9  ; tile patch (op $24): BG offset $0150 (row 10, column 16), tiles 40 41 / 42 43 / 44 45 / 46 47 / 48 49 / 4A 4B; $D8 = next row, $D9 = end
Bank0C_TilePatch_6A19:
    db $10, $01, $40, $41, $D8, $42, $43, $D8, $44, $45, $D8, $46, $47, $D8, $48, $49, $D8, $4A, $4B, $D9  ; tile patch (op $24): BG offset $0110 (row 8, column 16), tiles 40 41 / 42 43 / 44 45 / 46 47 / 48 49 / 4A 4B; $D8 = next row, $D9 = end
Bank0C_TilePatch_6A2D:
    db $D0, $00, $40, $41, $D8, $42, $43, $D8, $44, $45, $D8, $46, $47, $D8, $48, $49, $D8, $4A, $4B, $D9  ; tile patch (op $24): BG offset $00D0 (row 6, column 16), tiles 40 41 / 42 43 / 44 45 / 46 47 / 48 49 / 4A 4B; $D8 = next row, $D9 = end
Bank0C_TilePatch_6A41:
    db $90, $00, $40, $41, $D8, $42, $43, $D8, $44, $45, $D8, $46, $47, $D8, $48, $49, $D8, $4A, $4B, $D9  ; tile patch (op $24): BG offset $0090 (row 4, column 16), tiles 40 41 / 42 43 / 44 45 / 46 47 / 48 49 / 4A 4B; $D8 = next row, $D9 = end
Bank0C_TilePatch_6A55:
    db $D0, $01, $00, $00, $D8, $00, $00, $D9  ; tile patch (op $61): BG offset $01D0 (row 14, column 16), colours 00 00 / 00 00; $D8 = next row, $D9 = end
Bank0C_TilePatch_6A5D:
    db $90, $01, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D9  ; tile patch (op $61): BG offset $0190 (row 12, column 16), colours 00 00 / 00 00 / 00 00 / 00 00; $D8 = next row, $D9 = end
Bank0C_TilePatch_6A6B:
    db $50, $01, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D9  ; tile patch (op $61): BG offset $0150 (row 10, column 16), colours 00 00 / 00 00 / 00 00 / 00 00 / 00 00 / 00 00; $D8 = next row, $D9 = end
Bank0C_TilePatch_6A7F:
    db $10, $01, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D9  ; tile patch (op $61): BG offset $0110 (row 8, column 16), colours 00 00 / 00 00 / 00 00 / 00 00 / 00 00 / 00 00; $D8 = next row, $D9 = end
Bank0C_TilePatch_6A93:
    db $D0, $00, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D9  ; tile patch (op $61): BG offset $00D0 (row 6, column 16), colours 00 00 / 00 00 / 00 00 / 00 00 / 00 00 / 00 00; $D8 = next row, $D9 = end
Bank0C_TilePatch_6AA7:
    db $90, $00, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D8, $00, $00, $D9  ; tile patch (op $61): BG offset $0090 (row 4, column 16), colours 00 00 / 00 00 / 00 00 / 00 00 / 00 00 / 00 00; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Farm_Script01
; ---------------------------------------------------------------------------
Farm_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $0045 is set → Bank0C_ScriptAddr_6ADD
    dw $0045                ;   flag
    dw Bank0C_ScriptAddr_6ADD ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0C_ScriptAddr_6AD9
    dw $0031                ;   flag
    dw Bank0C_ScriptAddr_6AD9 ;   target
    dw $0069                ; text $0069: "*:Hey Master! D'ya have an egg? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6AD5  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6AD5 ;   target
    dw $086E                ; text $086E: "*:Eggs will be eggs forever if left alon…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6AD5:
    dw $086D                ; text $086D: "*:All monsters are born from eggs."
    dw $FFFF                ; END

Bank0C_ScriptAddr_6AD9:
    dw $01B5                ; text $01B5: "*:The place to hatch eggs? Now I remembe…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6ADD:
    dw $0206                ; text $0206: "*:There's a person who will evaluate egg…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script02
; ---------------------------------------------------------------------------
Farm_Script02:
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF10                ; $10 walk_to_x: NPC 1 walks to x = 104 px (script waits)
    dw $0001                ;   actor
    dw $0068                ;   x
    dw $FF0D                ; $0D npc_write: NPC 3: y low byte := 24
    dw $0003                ;   actor
    dw $001A                ;   field
    dw $0018                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 4 tiles
    dw $0003                ;   actor
    dw $0040                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6B8F
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6B8F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_6B87
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_6B87 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_6B7F
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_6B7F ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $000D is clear → Bank0C_ScriptAddr_6B2F
    dw $000D                ;   flag
    dw Bank0C_ScriptAddr_6B2F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_6B77
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_6B77 ;   target
Bank0C_ScriptAddr_6B2F:
    dw $FF01                ; $01 if_flag_set: If flag $000D is set → Bank0C_ScriptAddr_6B6F
    dw $000D                ;   flag
    dw Bank0C_ScriptAddr_6B6F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $000C is set → Bank0C_ScriptAddr_6B43
    dw $000C                ;   flag
    dw Bank0C_ScriptAddr_6B43 ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $006A                ; text $006A: "Splat... Poop hit [HERO]."
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_6B97
    dw Bank0C_ScriptAddr_6B97 ;   target
Bank0C_ScriptAddr_6B43:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $006B                ; text $006B: "Thwack! It was the egg of a SkyDragon th…"
    dw $FF28                ; $28 if_storage_full: Go to target when all 20 monster slots are taken → Bank0C_ScriptAddr_6B69
    dw Bank0C_ScriptAddr_6B69 ;   target
    dw $006C                ; text $006C: "[HERO] took the egg of a SkyDragon! But,…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF0D                ; $0D npc_write: NPC 1 is shown (type := $02)
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0002                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1: walk-pattern phase := 1
    dw $0001                ;   actor
    dw $0008                ;   field
    dw $0001                ;   value
    dw $FF03                ; $03 set_flag: Set flag $000D
    dw $000D                ;   flag
    dw $FF29                ; $29 add_monster: Add monster: enemy row 350
    dw $015E                ;   enemy
    dw $FFFF                ; END

Bank0C_ScriptAddr_6B69:
    dw $006D                ; text $006D: "Could not keep the egg because there are…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_6B97
    dw Bank0C_ScriptAddr_6B97 ;   target
Bank0C_ScriptAddr_6B6F:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $006E                ; text $006E: "Splash! Poop hit [HERO]."
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_6B97
    dw Bank0C_ScriptAddr_6B97 ;   target
Bank0C_ScriptAddr_6B77:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0205                ; text $0205: "K-thump! Something hit [HERO]."
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_6B97
    dw Bank0C_ScriptAddr_6B97 ;   target
Bank0C_ScriptAddr_6B7F:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02D3                ; text $02D3: "Splash! Something hit [HERO]."
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_6B97
    dw Bank0C_ScriptAddr_6B97 ;   target
Bank0C_ScriptAddr_6B87:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $037E                ; text $037E: "SMACK! Something hit [HERO] and bounced …"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_6B97
    dw Bank0C_ScriptAddr_6B97 ;   target
Bank0C_ScriptAddr_6B8F:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $07AA                ; text $07AA: "Splat, a FunkyBird is flying above!"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_6B97
    dw Bank0C_ScriptAddr_6B97 ;   target
Bank0C_ScriptAddr_6B97:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF0D                ; $0D npc_write: NPC 1 is shown (type := $02)
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0002                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1: walk-pattern phase := 1
    dw $0001                ;   actor
    dw $0008                ;   field
    dw $0001                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script03
; ---------------------------------------------------------------------------
Farm_Script03:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6BBF
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6BBF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_6BBB
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_6BBB ;   target
    dw $02D4                ; text $02D4: "*:Where do monsters come from? *:Sometim…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6BBB:
    dw $037F                ; text $037F: "*:We monsters become lively when the Sta…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6BBF:
    dw $07AB                ; text $07AB: "*:I wonder where we monsters came from a…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script04
; ---------------------------------------------------------------------------
Farm_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $0094 is set → Bank0C_ScriptAddr_6BCD
    dw $0094                ;   flag
    dw Bank0C_ScriptAddr_6BCD ;   target
    dw $04EB                ; text $04EB: "*:Congratulations! [HERO]! *:From now on…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6BCD:
    dw $04EC                ; text $04EC: "May: Congratulations! That's my [HERO]! …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script05
; ---------------------------------------------------------------------------
Farm_Script05:
    dw $FF01                ; $01 if_flag_set: If flag $00E3 is set → Bank0C_ScriptAddr_6BDF
    dw $00E3                ;   flag
    dw Bank0C_ScriptAddr_6BDF ;   target
    dw $04ED                ; text $04ED: "Mick:Hey [HERO]! I came back from my jou…"
    dw $FF03                ; $03 set_flag: Set flag $00E3
    dw $00E3                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_6BDF:
    dw $04EE                ; text $04EE: "Mick: Congratulations! Please stay as my…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script06
; ---------------------------------------------------------------------------
Farm_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6C0F
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6C0F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_6BFF
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_6BFF ;   target
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF0D                ; $0D npc_write: NPC 1: show the facing sideways frame now  [slot +$14 := 2]
    dw $0001                ;   actor
    dw $0014                ;   field
    dw $0002                ;   value
    dw $0035                ; text $0035: "*:No! You'll be hurt if you fall."
    dw $FFFF                ; END

Bank0C_ScriptAddr_6BFF:
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF0D                ; $0D npc_write: NPC 1: show the facing sideways frame now  [slot +$14 := 2]
    dw $0001                ;   actor
    dw $0014                ;   field
    dw $0002                ;   value
    dw $0209                ; text $0209: "*:There are cliffs where you can jump of…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6C0F:
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF0D                ; $0D npc_write: NPC 1: show the facing sideways frame now  [slot +$14 := 2]
    dw $0001                ;   actor
    dw $0014                ;   field
    dw $0002                ;   value
    dw $07AE                ; text $07AE: "*:The Starry Night is over!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script07
; ---------------------------------------------------------------------------
Farm_Script07:
    dw $0034                ; text $0034: "[HERO] read the sign. :Danger, Don't rus…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script08
; ---------------------------------------------------------------------------
Farm_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6C4B
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6C4B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_6C47
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_6C47 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_6C43
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_6C43 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0C_ScriptAddr_6C3F
    dw $0009                ;   flag
    dw Bank0C_ScriptAddr_6C3F ;   target
    dw $0033                ; text $0033: "*:I wonder where I can get treats."
    dw $FFFF                ; END

Bank0C_ScriptAddr_6C3F:
    dw $006F                ; text $006F: "*:Treats! BeefJerky, PorkChop, Rib. *:Be…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6C43:
    dw $0207                ; text $0207: "*:BadMeat is bad and poisonous. *:But Ba…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6C47:
    dw $0380                ; text $0380: "*:There are monsters with amazing skills…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6C4B:
    dw $07AC                ; text $07AC: "*:The sky is crystal clear! The stars cl…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script09
; ---------------------------------------------------------------------------
Farm_Script09:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6C6D
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6C6D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_6C69
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_6C69 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_6C65
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_6C65 ;   target
    dw $0070                ; text $0070: "*:If you take monsters on a journey, the…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6C65:
    dw $0208                ; text $0208: "*:We disobey when we get an unwanted com…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6C69:
    dw $0381                ; text $0381: "*:I heard there is something that can ch…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6C6D:
    dw $07AD                ; text $07AD: "*:I wonder if I can be a lone wolf if I …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script10
; ---------------------------------------------------------------------------
Farm_Script10:
    dw $04F3                ; text $04F3: "King:[HERO], go to the chamber deep in t…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script11
; ---------------------------------------------------------------------------
Farm_Script11:
    dw $FF01                ; $01 if_flag_set: If flag $00E6 is set → Bank0C_ScriptAddr_6C83
    dw $00E6                ;   flag
    dw Bank0C_ScriptAddr_6C83 ;   target
    dw $04F4                ; text $04F4: "*:[HERO]! I thank you for your victory! …"
    dw $FF03                ; $03 set_flag: Set flag $00E6
    dw $00E6                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_6C83:
    dw $04F5                ; text $04F5: "*:Tonight is the Starry Night. The night…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script12
; ---------------------------------------------------------------------------
Farm_Script12:
    dw $04F7                ; text $04F7: "*:You did it! [HERO]!! *:I knew you'd wi…"
    dw $FF1C                ; $1C trigger_anim: NPC 3: spin jump
    dw $0903                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script13
; ---------------------------------------------------------------------------
Farm_Script13:
    dw $04F9                ; text $04F9: "*:Hey! Congrats!"
    dw $FF1C                ; $1C trigger_anim: NPC 4: spin jump
    dw $0904                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script14
; ---------------------------------------------------------------------------
Farm_Script14:
    dw $04F6                ; text $04F6: "*:Congratulations! Tonight is the Starry…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script15
; ---------------------------------------------------------------------------
Farm_Script15:
    dw $04F8                ; text $04F8: "*:You did it! You won!"
    dw $FF1C                ; $1C trigger_anim: NPC 6: spin jump
    dw $0906                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script16
; ---------------------------------------------------------------------------
Farm_Script16:
    dw $0037                ; text $0037: "[HERO] read the sign. :When the GreatTre…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script17
; ---------------------------------------------------------------------------
Farm_Script17:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6CDF
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6CDF ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $007C is clear → Bank0C_ScriptAddr_6CBF
    dw $007C                ;   flag
    dw Bank0C_ScriptAddr_6CBF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_6CDB
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_6CDB ;   target
Bank0C_ScriptAddr_6CBF:
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_6CD3
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_6CD3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0C_ScriptAddr_6CCF
    dw $0030                ;   flag
    dw Bank0C_ScriptAddr_6CCF ;   target
    dw $0036                ; text $0036: "*:If it was not for this hole... *:Oh my…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6CCF:
    dw $0176                ; text $0176: "*:Hmm. Can't go this way either."
    dw $FFFF                ; END

Bank0C_ScriptAddr_6CD3:
    dw $02D5                ; text $02D5: "*:Oh look! The cliffs are now connected!…"
    dw $FF03                ; $03 set_flag: Set flag $007C
    dw $007C                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_6CDB:
    dw $04A1                ; text $04A1: "*:We'll spend the Starry Night, together…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6CDF:
    dw $07AF                ; text $07AF: "*:We spent the Starry Night together, ju…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script18
; ---------------------------------------------------------------------------
Farm_Script18:
    dw $02D6                ; text $02D6: "*:Oh Darling! *Kiss* *Kiss*"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script19
; ---------------------------------------------------------------------------
Farm_Script19:
    dw $FF01                ; $01 if_flag_set: If flag $00E7 is set → Bank0C_ScriptAddr_6D9B
    dw $00E7                ;   flag
    dw Bank0C_ScriptAddr_6D9B ;   target
    dw $04FB                ; text $04FB: "*:I was a master once. *:I won a victory…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0C_ScriptAddr_6CFF  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_6CFF ;   target
    dw $04FD                ; text $04FD: "*:Let me know when you want to go down i…"
    dw $FF03                ; $03 set_flag: Set flag $00E7
    dw $00E7                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_6CFF:
    dw $04FC                ; text $04FC: "*:Now let us go! To the Shrine of Starry…"
    dw $FF47                ; $47 face_up: NPC 3 faces up
    dw $0003                ;   actor
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF10                ; $10 walk_to_x: the player walks to x = 392 px (script waits)
    dw $0000                ;   actor
    dw $0188                ;   x
    dw $FF11                ; $11 walk_to_y: the player walks to y = 88 px (script waits)
    dw $0000                ;   actor
    dw $0058                ;   y
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks right 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks right 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF1A                ; $1A npc_walk_x: the player walks right 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0F                ; $0F map_transition: Go to Starry Shrine at (17, 0)
    dw $0009                ;   map
    dw $0118                ;   x
    dw $0008                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0C_ScriptAddr_6D9B:
    dw $04FE                ; text $04FE: "*:I was a master once. *:I won a victory…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0C_ScriptAddr_6CFF  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_6CFF ;   target
    dw $04FD                ; text $04FD: "*:Let me know when you want to go down i…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script20
; ---------------------------------------------------------------------------
Farm_Script20:
    dw $04FA                ; text $04FA: "*:Oh my dear [HERO]! Congratulations! *:…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script21
; ---------------------------------------------------------------------------
Farm_Script21:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6E05
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6E05 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0C_ScriptAddr_6E01
    dw $00E4                ;   flag
    dw Bank0C_ScriptAddr_6E01 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $007B is set → Bank0C_ScriptAddr_6DFD
    dw $007B                ;   flag
    dw Bank0C_ScriptAddr_6DFD ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_6DEB
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_6DEB ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0004 is set → Bank0C_ScriptAddr_6DE7
    dw $0004                ;   flag
    dw Bank0C_ScriptAddr_6DE7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0C_ScriptAddr_6DD5
    dw $0009                ;   flag
    dw Bank0C_ScriptAddr_6DD5 ;   target
    dw $003B                ; text $003B: "[HERO] looked into the jar. The jar is f…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6DD5:
    dw $003A                ; text $003A: "[HERO] looked into the jar."
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_6E09
    dw Bank0C_ScriptAddr_6E09 ;   target
    dw $0129                ; text $0129: "Wow! [HERO] got a TinyMedal!"
    dw $FF03                ; $03 set_flag: Set flag $0004
    dw $0004                ;   flag
    dw $FF2A                ; $2A give_item: Give item 30
    dw $001E                ;   item
    dw $FFFF                ; END

Bank0C_ScriptAddr_6DE7:
    dw $003B                ; text $003B: "[HERO] looked into the jar. The jar is f…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6DEB:
    dw $003A                ; text $003A: "[HERO] looked into the jar."
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_6E09
    dw Bank0C_ScriptAddr_6E09 ;   target
    dw $0129                ; text $0129: "Wow! [HERO] got a TinyMedal!"
    dw $FF03                ; $03 set_flag: Set flag $007B
    dw $007B                ;   flag
    dw $FF2A                ; $2A give_item: Give item 30
    dw $001E                ;   item
    dw $FFFF                ; END

Bank0C_ScriptAddr_6DFD:
    dw $003B                ; text $003B: "[HERO] looked into the jar. The jar is f…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E01:
    dw $0502                ; text $0502: "[HERO] looked into the jar. The jar was …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E05:
    dw $07B1                ; text $07B1: "[HERO] looked into the jar. *:A fragment…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E09:
    dw $012A                ; text $012A: "Wow! A TinyMedal was found! But cannot c…"
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Farm_Script22
; ---------------------------------------------------------------------------
Farm_Script22:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6E3F
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6E3F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0C_ScriptAddr_6E3B
    dw $00E4                ;   flag
    dw Bank0C_ScriptAddr_6E3B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_6E37
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_6E37 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_6E33
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_6E33 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_6E2F
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_6E2F ;   target
    dw $0039                ; text $0039: "*:Hey, Mr.Monster Master. I wonder what …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E2F:
    dw $020B                ; text $020B: "*:Hi! monster master! I catch a lot here…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E33:
    dw $02D8                ; text $02D8: "*:Mostly garbage, but sometimes I catch …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E37:
    dw $04A3                ; text $04A3: "*:The Starry Night is soon. Yeah! Ha ha …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E3B:
    dw $04FF                ; text $04FF: "*:Okay I'll fish for stars!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E3F:
    dw $07B0                ; text $07B0: "*:Hey you! I fished out a big one!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script23
; ---------------------------------------------------------------------------
Farm_Script23:
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_6E57
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_6E57 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0C_ScriptAddr_6E53
    dw $0009                ;   flag
    dw Bank0C_ScriptAddr_6E53 ;   target
    dw $0038                ; text $0038: "*:I heard that Pulio let the monsters es…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E53:
    dw $0071                ; text $0071: "*:Yo! Pulio was happy!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E57:
    dw $020A                ; text $020A: "*:Hey! The Monster Stable is down there.…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script24
; ---------------------------------------------------------------------------
Farm_Script24:
    dw $FF01                ; $01 if_flag_set: If flag $00FC is set → Bank0C_ScriptAddr_6E8D
    dw $00FC                ;   flag
    dw Bank0C_ScriptAddr_6E8D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6E89
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6E89 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0C_ScriptAddr_6E85
    dw $00E4                ;   flag
    dw Bank0C_ScriptAddr_6E85 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_6E81
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_6E81 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_6E7D
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_6E7D ;   target
    dw $02D7                ; text $02D7: "*:Hello. Go down to the stable. Bleeeat."
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E7D:
    dw $0382                ; text $0382: "*:Hello. The stable is below here. Bleat…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E81:
    dw $04A2                ; text $04A2: "*:Hello. Down to the stable. Bleat. *:Ev…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E85:
    dw $0500                ; text $0500: "*:No running!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E89:
    dw $07B2                ; text $07B2: "*:Go down to the stable. Bleat! Watabou …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6E8D:
    dw $07B3                ; text $07B3: "*:Go down to the stable. Bleat! Keep it …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script25
; ---------------------------------------------------------------------------
Farm_Script25:
    dw $0501                ; text $0501: "*:Squawk! Squawk!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script26
; ---------------------------------------------------------------------------
Farm_Script26:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_6EE7
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6EE7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0C_ScriptAddr_6F03
    dw $00E4                ;   flag
    dw Bank0C_ScriptAddr_6F03 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_6EE7
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_6EE7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $000C is set → Bank0C_ScriptAddr_6EE7
    dw $000C                ;   flag
    dw Bank0C_ScriptAddr_6EE7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0C_ScriptAddr_6EF3
    dw $0009                ;   flag
    dw Bank0C_ScriptAddr_6EF3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0005 is set → Bank0C_ScriptAddr_6EE7
    dw $0005                ;   flag
    dw Bank0C_ScriptAddr_6EE7 ;   target
    dw $003C                ; text $003C: "*:Hey you! You came here to steal my mon…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6ED5  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6ED5 ;   target
    dw $003D                ; text $003D: "*:C'mon, I'll give you a beating. Sniff …"
    dw $003F                ; text $003F: "*:I'm Pulio I take care of this farm. Pu…"
    dw $FF03                ; $03 set_flag: Set flag $0005
    dw $0005                ;   flag
    dw $FF04                ; $04 open_screen: Open Pulio's farm menu (pick up / leave monsters) (its texts begin “Pulio:Hey there! Whadayagonnado?”)
    dw $0003                ;   kind
    dw $06C0                ;   text
    dw $06C2                ; text $06C2: "Pulio:Later! We'll be here for ya!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6ED5:
    dw $003E                ; text $003E: "*:You came here to get monsters?"
    dw $003F                ; text $003F: "*:I'm Pulio I take care of this farm. Pu…"
    dw $FF03                ; $03 set_flag: Set flag $0005
    dw $0005                ;   flag
    dw $FF04                ; $04 open_screen: Open Pulio's farm menu (pick up / leave monsters) (its texts begin “Pulio:Hey there! Whadayagonnado?”)
    dw $0003                ;   kind
    dw $06C0                ;   text
    dw $06C2                ; text $06C2: "Pulio:Later! We'll be here for ya!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6EE7:
    dw $06C0                ; text $06C0: "Pulio:Hey there! Whadayagonnado?"
    dw $FF04                ; $04 open_screen: Open Pulio's farm menu (pick up / leave monsters) (its texts begin “Pulio:Hey there! Whadayagonnado?”)
    dw $0003                ;   kind
    dw $06C0                ;   text
    dw $06C2                ; text $06C2: "Pulio:Later! We'll be here for ya!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6EF3:
    dw $0072                ; text $0072: "Pulio:Thank you [HERO]! I'm saved! Pulio…"
    dw $FF03                ; $03 set_flag: Set flag $000C
    dw $000C                ;   flag
    dw $FF04                ; $04 open_screen: Open Pulio's farm menu (pick up / leave monsters) (its texts begin “Pulio:Hey there! Whadayagonnado?”)
    dw $0003                ;   kind
    dw $06C0                ;   text
    dw $06C2                ; text $06C2: "Pulio:Later! We'll be here for ya!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6F03:
    dw $0504                ; text $0504: "Pulio:If you didn't help me... Pulio:I w…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script27
; ---------------------------------------------------------------------------
Farm_Script27:
    dw $FF00                ; $00 if_flag_clear: If flag $00E4 is clear → Bank0C_ScriptAddr_6F13
    dw $00E4                ;   flag
    dw Bank0C_ScriptAddr_6F13 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00A2 is set → Bank0C_ScriptAddr_6FF9
    dw $00A2                ;   flag
    dw Bank0C_ScriptAddr_6FF9 ;   target
Bank0C_ScriptAddr_6F13:
    dw $FF01                ; $01 if_flag_set: If flag $00A3 is set → Bank0C_ScriptAddr_6FE7
    dw $00A3                ;   flag
    dw Bank0C_ScriptAddr_6FE7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00A2 is set → Bank0C_ScriptAddr_6FCD
    dw $00A2                ;   flag
    dw Bank0C_ScriptAddr_6FCD ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $00F1 is clear → Bank0C_ScriptAddr_6F31
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_6F31 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00A1 is set → Bank0C_ScriptAddr_6F9F
    dw $00A1                ;   flag
    dw Bank0C_ScriptAddr_6F9F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_6F71
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_6F71 ;   target
Bank0C_ScriptAddr_6F31:
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0C_ScriptAddr_6FC9
    dw $00E4                ;   flag
    dw Bank0C_ScriptAddr_6FC9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00A1 is set → Bank0C_ScriptAddr_6F9F
    dw $00A1                ;   flag
    dw Bank0C_ScriptAddr_6F9F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_6F71
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_6F71 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0006 is set → Bank0C_ScriptAddr_6F5F
    dw $0006                ;   flag
    dw Bank0C_ScriptAddr_6F5F ;   target
    dw $0040                ; text $0040: "*:I'm Slio. I am the grandson of Grandpa…"
    dw $FF03                ; $03 set_flag: Set flag $0006
    dw $0006                ;   flag
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6F5B  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6F5B ;   target
    dw $0041                ; text $0041: "Slio:You can drop off up to 19 monsters …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6F5B:
    dw $0042                ; text $0042: "Slio:Raise the monster to be powerful!"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6F5F:
    dw $0043                ; text $0043: "Slio:D'ya wanna know about the farm? [YE…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6F6D  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6F6D ;   target
    dw $0041                ; text $0041: "Slio:You can drop off up to 19 monsters …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6F6D:
    dw $0042                ; text $0042: "Slio:Raise the monster to be powerful!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6F71:
    dw $043F                ; text $043F: "Slio:Will you do me a favor? Slio:I wann…"
    dw $FF03                ; $03 set_flag: Set flag $00A1
    dw $00A1                ;   flag
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6F97  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6F97 ;   target
    dw $FF28                ; $28 if_storage_full: Go to target when all 20 monster slots are taken → Bank0C_ScriptAddr_6F9B
    dw Bank0C_ScriptAddr_6F9B ;   target
    dw $0442                ; text $0442: "Slio:Thank you [HERO]! I'll wait for you…"
    dw $FF03                ; $03 set_flag: Set flag $00A2
    dw $00A2                ;   flag
    dw $FF29                ; $29 add_monster: Add monster: enemy row 351
    dw $015F                ;   enemy
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FFFF                ; END

Bank0C_ScriptAddr_6F97:
    dw $0440                ; text $0440: "Slio:I guess I'm useless to you now... S…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6F9B:
    dw $0441                ; text $0441: "Slio:[HERO], you have too many monsters …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6F9F:
    dw $0443                ; text $0443: "Slio:[HERO]! You're going to take me wit…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6FC1  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6FC1 ;   target
    dw $FF28                ; $28 if_storage_full: Go to target when all 20 monster slots are taken → Bank0C_ScriptAddr_6FC5
    dw Bank0C_ScriptAddr_6FC5 ;   target
    dw $0442                ; text $0442: "Slio:Thank you [HERO]! I'll wait for you…"
    dw $FF03                ; $03 set_flag: Set flag $00A2
    dw $00A2                ;   flag
    dw $FF29                ; $29 add_monster: Add monster: enemy row 351
    dw $015F                ;   enemy
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FFFF                ; END

Bank0C_ScriptAddr_6FC1:
    dw $0440                ; text $0440: "Slio:I guess I'm useless to you now... S…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6FC5:
    dw $0441                ; text $0441: "Slio:[HERO], you have too many monsters …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6FC9:
    dw $005D                ; text $005D: "Slio:[HERO]! Congratulations on your vic…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6FCD:
    dw $0444                ; text $0444: "*:How are you? I'm Slim! I'm the sister …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6FDF  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6FDF ;   target
    dw $0446                ; text $0446: "*:You can drop off up to 19 monsters and…"
    dw $FF03                ; $03 set_flag: Set flag $00A3
    dw $00A3                ;   flag
    dw $FFFF                ; END

Bank0C_ScriptAddr_6FDF:
    dw $0445                ; text $0445: "*:As might be expected [HERO]! You have …"
    dw $FF03                ; $03 set_flag: Set flag $00A3
    dw $00A3                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_6FE7:
    dw $0447                ; text $0447: "*:Do you want to know about the farm? [Y…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_6FF5  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_6FF5 ;   target
    dw $0446                ; text $0446: "*:You can drop off up to 19 monsters and…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_6FF5:
    dw $0445                ; text $0445: "*:As might be expected [HERO]! You have …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_6FF9:
    dw $0503                ; text $0503: "*:Someday I will follow [HERO]... *:Oh m…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script28
; ---------------------------------------------------------------------------
Farm_Script28:
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_701B
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_701B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0C_ScriptAddr_7017
    dw $0030                ;   flag
    dw Bank0C_ScriptAddr_7017 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $000C is set → Bank0C_ScriptAddr_7013
    dw $000C                ;   flag
    dw Bank0C_ScriptAddr_7013 ;   target
    dw $0044                ; text $0044: "*:You are at the monster farm."
    dw $FFFF                ; END

Bank0C_ScriptAddr_7013:
    dw $0073                ; text $0073: "*:This is the monster farm. *:You can fi…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_7017:
    dw $0177                ; text $0177: "*:You are at the Monster Farm. *:The Mad…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_701B:
    dw $020C                ; text $020C: "*:You're at the Monster Farm. *:Go left …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script29
; ---------------------------------------------------------------------------
Farm_Script29:
    dw $02D9                ; text $02D9: "*:Do you want to know the limit of growt…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_706F  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_706F ;   target
    dw $FF15                ; $15 check_and_branch: If “the number of monsters in the party” is 0 → Bank0C_ScriptAddr_706B  [$CA8D = 0]
    dw $CA8D                ;   address
    dw $0000                ;   value
    dw Bank0C_ScriptAddr_706B ;   target
    dw $FF5F                ; $5F if_slot_level_below: Go to target when party slot's level (+$4B) is AT its cap (+$4C); the cap's digits go to $C190 (S124, code-read — was worded "below") (slot 0) → Bank0C_ScriptAddr_703D
    dw $0000                ;   slot
    dw Bank0C_ScriptAddr_703D ;   target
    dw $08C7                ; text $08C7: "*:The growth limit of [INS 00] is [Lv][I…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_703F
    dw Bank0C_ScriptAddr_703F ;   target
Bank0C_ScriptAddr_703D:
    dw $08D2                ; text $08D2: "*:[INS 00] is at its growth limit! Baooo…"
Bank0C_ScriptAddr_703F:
    dw $FF15                ; $15 check_and_branch: If “the number of monsters in the party” is 1 → Bank0C_ScriptAddr_706B  [$CA8D = 1]
    dw $CA8D                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_706B ;   target
    dw $FF5F                ; $5F if_slot_level_below: Go to target when party slot's level (+$4B) is AT its cap (+$4C); the cap's digits go to $C190 (S124, code-read — was worded "below") (slot 1) → Bank0C_ScriptAddr_7053
    dw $0001                ;   slot
    dw Bank0C_ScriptAddr_7053 ;   target
    dw $08C7                ; text $08C7: "*:The growth limit of [INS 00] is [Lv][I…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_7055
    dw Bank0C_ScriptAddr_7055 ;   target
Bank0C_ScriptAddr_7053:
    dw $08D2                ; text $08D2: "*:[INS 00] is at its growth limit! Baooo…"
Bank0C_ScriptAddr_7055:
    dw $FF15                ; $15 check_and_branch: If “the number of monsters in the party” is 2 → Bank0C_ScriptAddr_706B  [$CA8D = 2]
    dw $CA8D                ;   address
    dw $0002                ;   value
    dw Bank0C_ScriptAddr_706B ;   target
    dw $FF5F                ; $5F if_slot_level_below: Go to target when party slot's level (+$4B) is AT its cap (+$4C); the cap's digits go to $C190 (S124, code-read — was worded "below") (slot 2) → Bank0C_ScriptAddr_7069
    dw $0002                ;   slot
    dw Bank0C_ScriptAddr_7069 ;   target
    dw $08C7                ; text $08C7: "*:The growth limit of [INS 00] is [Lv][I…"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_706B
    dw Bank0C_ScriptAddr_706B ;   target
Bank0C_ScriptAddr_7069:
    dw $08D2                ; text $08D2: "*:[INS 00] is at its growth limit! Baooo…"
Bank0C_ScriptAddr_706B:
    dw $08CD                ; text $08CD: "*:When it hits the limit, the level won'…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_706F:
    dw $08CA                ; text $08CA: "*:You're at the monster farm. Baoooom!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script30
; ---------------------------------------------------------------------------
Farm_Script30:
    dw $0505                ; text $0505: "*:Yo, I heard you won. *:Isn't it just a…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script31
; ---------------------------------------------------------------------------
Farm_Script31:
    dw $0506                ; text $0506: "*:Oh! [HERO]!! You did it, you did it. *…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script32
; ---------------------------------------------------------------------------
Farm_Script32:
    dw $0507                ; text $0507: "*:You won!! Yeh yeh!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script33
; ---------------------------------------------------------------------------
Farm_Script33:
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0C_ScriptAddr_7089
    dw $0032                ;   flag
    dw Bank0C_ScriptAddr_7089 ;   target
    dw $0074                ; text $0074: "*:Old monsters like myself can no longer…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_7089:
    dw $020D                ; text $020D: "*:The Travelers' Gates are hidden everyw…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script34
; ---------------------------------------------------------------------------
Farm_Script34:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_70AB
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_70AB ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_70A7
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_70A7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_70A3
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_70A3 ;   target
    dw $02DA                ; text $02DA: "*:Despite my looks I have a high growth …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_70A3:
    dw $0384                ; text $0384: "*:My parents' ancestors were bred a lot.…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_70A7:
    dw $04A5                ; text $04A5: "*:As the Starry Night nears, I want to s…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_70AB:
    dw $07B5                ; text $07B5: "*:Have you met all the monsters? There a…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script35
; ---------------------------------------------------------------------------
Farm_Script35:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_70D3
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_70D3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_70CF
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_70CF ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0035 is clear → Bank0C_ScriptAddr_70C7
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_70C7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $006A is set → Bank0C_ScriptAddr_70CB
    dw $006A                ;   flag
    dw Bank0C_ScriptAddr_70CB ;   target
Bank0C_ScriptAddr_70C7:
    dw $02DB                ; text $02DB: "*:My hometown is the Gate of Peace."
    dw $FFFF                ; END

Bank0C_ScriptAddr_70CB:
    dw $0385                ; text $0385: "*:I'm pretty much a coward. *:I wish the…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_70CF:
    dw $04A6                ; text $04A6: "*:As the Starry Night nears, it makes ev…"
    dw $FFFF                ; END

Bank0C_ScriptAddr_70D3:
    dw $07B6                ; text $07B6: "*:My buddy is living behind the Gate of …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script36
; ---------------------------------------------------------------------------
Farm_Script36:
    dw $FF01                ; $01 if_flag_set: If flag $00E8 is set → Bank0C_ScriptAddr_7111
    dw $00E8                ;   flag
    dw Bank0C_ScriptAddr_7111 ;   target
    dw $0368                ; text $0368: "*:Oh [HERO], It's me. The receptionist! …"
    dw $FF03                ; $03 set_flag: Set flag $00E8
    dw $00E8                ;   flag
    dw $FF0D                ; $0D npc_write: NPC 6: restart its animation from the first frame  [slot +$10 := 0]
    dw $0006                ;   actor
    dw $0010                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 6: x low byte := 144
    dw $0006                ;   actor
    dw $0018                ;   field
    dw $0090                ;   value
    dw $FF0D                ; $0D npc_write: NPC 6: y low byte := 144
    dw $0006                ;   actor
    dw $001A                ;   field
    dw $0090                ;   value
    dw $FF0D                ; $0D npc_write: NPC 6 is shown
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 6 is hidden
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FFFF                ; END

Bank0C_ScriptAddr_7111:
    dw $0338                ; text $0338: "*:What's wrong? You look pale!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script37
; ---------------------------------------------------------------------------
Farm_Script37:
    dw $0508                ; text $0508: "*:[HERO]! You did great!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script38
; ---------------------------------------------------------------------------
Farm_Script38:
    dw $0509                ; text $0509: "*:You did it! Want a reward? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_7127  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_7127 ;   target
    dw $050A                ; text $050A: "*:... tickle. Tickle, tickle. *:Tickle, …"
    dw $FFFF                ; END

Bank0C_ScriptAddr_7127:
    dw $050B                ; text $050B: "*:Giggle.."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script39
; ---------------------------------------------------------------------------
Farm_Script39:
    dw $050C                ; text $050C: "*:I danced too much and I feel dizzy!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script40
; ---------------------------------------------------------------------------
Farm_Script40:
    dw $050D                ; text $050D: "*:It's unbelievable to fight against a s…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Farm_Script41
; ---------------------------------------------------------------------------
Farm_Script41:
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks down 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 1 hidden  [$C8ED := 3]
    dw $C8ED                ;   address
    dw $0003                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks down 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 1-2 hidden  [$C8ED := 7]
    dw $C8ED                ;   address
    dw $0007                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks down 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF12                ; $12 write_ram: The party is falling through a hole: yes  [$D9E5 := 1]  (meaning inferred from the scripts that use it)
    dw $D9E5                ;   address
    dw $0001                ;   value
    dw $FF0F                ; $0F map_transition: Go to Arena Rooms at (25, 13)
    dw $0007                ;   map
    dw $0198                ;   x
    dw $00D8                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Farm_Script42
; ---------------------------------------------------------------------------
Farm_Script42:
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks down 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 1 hidden  [$C8ED := 3]
    dw $C8ED                ;   address
    dw $0003                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks down 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 1-2 hidden  [$C8ED := 7]
    dw $C8ED                ;   address
    dw $0007                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks down 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF12                ; $12 write_ram: The party is falling through a hole: yes  [$D9E5 := 1]  (meaning inferred from the scripts that use it)
    dw $D9E5                ;   address
    dw $0001                ;   value
    dw $FF0F                ; $0F map_transition: Go to Starry Shrine at (17, 5)
    dw $0009                ;   map
    dw $0118                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Stable Per-Script Table (map_type=$05, 0 scripts)
; ---------------------------------------------------------------------------
Stable_ScriptPtrTable:
    dw $71F9                ; script 0
    dw $71FB                ; script 1
    dw $7213                ; script 2
    dw $7217                ; script 3
    dw $722F                ; script 4
    dw $7257                ; script 5
    dw $7283                ; script 6
    dw $72A5                ; script 7
    dw $72D1                ; script 8
    dw $7331                ; script 9
    dw $7359                ; script 10
    dw $7383                ; script 11
    dw $73AB                ; script 12
    dw $73C3                ; script 13
    dw $73DB                ; script 14
    dw $73FB                ; script 15
    dw $742B                ; script 16
    dw $75BB                ; script 17
    dw $75BF                ; script 18
    dw $75D7                ; script 19
    dw $7647                ; script 20
    dw $FFFF                ; END

    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0C_ScriptAddr_720F
    dw $0034                ;   flag
    dw Bank0C_ScriptAddr_720F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0C_ScriptAddr_720B
    dw $0033                ;   flag
    dw Bank0C_ScriptAddr_720B ;   target
    dw $020E                ; text $020E: "*:Hi Master. Do you know MetalCut? *:I h…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_720B:
    dw $027A                ; text $027A: "*:BattleRex uses EvilSlash. *:It also us…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_720F:
    dw $033E                ; text $033E: "*:You gotta have MetalCut to defeat Meta…"
    dw $FFFF                ; END
    dw $020F                ; text $020F: "*:Oh sis, I'm sleepy! Let's go to bed!"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0C_ScriptAddr_722B
    dw $0034                ;   flag
    dw Bank0C_ScriptAddr_722B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0C_ScriptAddr_7227
    dw $0033                ;   flag
    dw Bank0C_ScriptAddr_7227 ;   target
    dw $0210                ; text $0210: "*:BigEye is great at IceBolt!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7227:
    dw $027B                ; text $027B: "*:There's a strange stone statue behind …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_722B:
    dw $033F                ; text $033F: "*:There's a technique that can paralyze …"
    dw $FFFF                ; END
    dw $FF00                ; $00 if_flag_clear: If flag $0022 is clear → Bank0C_ScriptAddr_7241
    dw $0022                ;   flag
    dw Bank0C_ScriptAddr_7241 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_7253
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_7253 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_724F
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_724F ;   target
Bank0C_ScriptAddr_7241:
    dw $FF01                ; $01 if_flag_set: If flag $0022 is set → Bank0C_ScriptAddr_724B
    dw $0022                ;   flag
    dw Bank0C_ScriptAddr_724B ;   target
    dw $0389                ; text $0389: "*:Go up 3 times, left once! ....zzz... *…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_724B:
    dw $038A                ; text $038A: "*:...zzz..."
    dw $FFFF                ; END
Bank0C_ScriptAddr_724F:
    dw $04A9                ; text $04A9: "*:Zzz..... ..zzz. Bust! *:Mm? Is it alre…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7253:
    dw $07BA                ; text $07BA: "*:ZZZ... there are monsters that do not …"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_727F
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_727F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_727B
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_727B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_7277
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_7277 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0C_ScriptAddr_7273
    dw $0036                ;   flag
    dw Bank0C_ScriptAddr_7273 ;   target
    dw $0386                ; text $0386: "*:Down below, behind the Gtae of Temptat…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7273:
    dw $03EC                ; text $03EC: "*:DuckKite is a troublesome monster. *:I…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7277:
    dw $0448                ; text $0448: "*:I heard the monster called Durran uses…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_727B:
    dw $04A7                ; text $04A7: "*:Power is flowing all around me! *:Watc…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_727F:
    dw $07B7                ; text $07B7: "*:Yippee! Congratulations on your victor…"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_72A1
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_72A1 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_729D
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_729D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0C_ScriptAddr_7299
    dw $0036                ;   flag
    dw Bank0C_ScriptAddr_7299 ;   target
    dw $0387                ; text $0387: "*:Copycopy. I wanna copycopy DeadNite co…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7299:
    dw $03ED                ; text $03ED: "*:Copycopy. I wanna copycopy an Unicorn …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_729D:
    dw $0449                ; text $0449: "*:Copycopy. I wanna copycopy Balzak toda…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_72A1:
    dw $07B8                ; text $07B8: "*:Copycopy. I wanna copycopy Watabou som…"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_72CD
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_72CD ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_72C9
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_72C9 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_72C5
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_72C5 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0C_ScriptAddr_72C1
    dw $0036                ;   flag
    dw Bank0C_ScriptAddr_72C1 ;   target
    dw $0388                ; text $0388: "*:Hello! I am Helo. *:My former master w…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_72C1:
    dw $03EE                ; text $03EE: "*:Hello! I am Helo. *:My former master w…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_72C5:
    dw $044A                ; text $044A: "*:Hello! I'm Helo *:My former master wan…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_72C9:
    dw $04A8                ; text $04A8: "*:When the Starry Night nears, my skin b…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_72CD:
    dw $07B9                ; text $07B9: "*:I wanna be with a wonderful master lik…"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_732D
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_732D ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0083 is clear → Bank0C_ScriptAddr_72F5
    dw $0083                ;   flag
    dw Bank0C_ScriptAddr_72F5 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $011E is clear → Bank0C_ScriptAddr_72EF
    dw $011E                ;   flag
    dw Bank0C_ScriptAddr_72EF ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0025 is clear → Bank0C_ScriptAddr_72EF
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_72EF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0120 is set → Bank0C_ScriptAddr_7329
    dw $0120                ;   flag
    dw Bank0C_ScriptAddr_7329 ;   target
Bank0C_ScriptAddr_72EF:
    dw $FF01                ; $01 if_flag_set: If flag $011E is set → Bank0C_ScriptAddr_7325
    dw $011E                ;   flag
    dw Bank0C_ScriptAddr_7325 ;   target
Bank0C_ScriptAddr_72F5:
    dw $FF01                ; $01 if_flag_set: If flag $0083 is set → Bank0C_ScriptAddr_7321
    dw $0083                ;   flag
    dw Bank0C_ScriptAddr_7321 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $007C is set → Bank0C_ScriptAddr_731D
    dw $007C                ;   flag
    dw Bank0C_ScriptAddr_731D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0C_ScriptAddr_730B
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_730B ;   target
    dw $0211                ; text $0211: "*:I've lived here a long time. *:So I kn…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_730B:
    dw $02DC                ; text $02DC: "*:Did you see the changes on the farm? […"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_7319  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_7319 ;   target
    dw $02DD                ; text $02DD: "*:At last, MadKnight was able to reunite…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7319:
    dw $02DE                ; text $02DE: "*:Go quick. You can see the good stuff!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_731D:
    dw $02DF                ; text $02DF: "*:Goopi loves Paper-Rock- Scissors. *:It…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7321:
    dw $038B                ; text $038B: "*:There is a man who collects medals in …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7325:
    dw $038C                ; text $038C: "*:I feel the strong presence of a powerf…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7329:
    dw $04AA                ; text $04AA: "*:I feel it! GreatTree is shaking! *:It …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_732D:
    dw $07BB                ; text $07BB: "*:Did you find all the hidden Travelers'…"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_7355
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_7355 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0022 is clear → Bank0C_ScriptAddr_7343
    dw $0022                ;   flag
    dw Bank0C_ScriptAddr_7343 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_7351
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_7351 ;   target
Bank0C_ScriptAddr_7343:
    dw $FF01                ; $01 if_flag_set: If flag $0022 is set → Bank0C_ScriptAddr_734D
    dw $0022                ;   flag
    dw Bank0C_ScriptAddr_734D ;   target
    dw $038D                ; text $038D: "*:Go right immediately! *:Then you can m…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_734D:
    dw $038E                ; text $038E: "*:My hometown is behind the Gate of Temp…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7351:
    dw $04AB                ; text $04AB: "*:Of course GreatTree will triumph!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7355:
    dw $07BC                ; text $07BC: "*:Mr. DeadNoble is good at Call!"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_737D
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_737D ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0022 is clear → Bank0C_ScriptAddr_736B
    dw $0022                ;   flag
    dw Bank0C_ScriptAddr_736B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_7379
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_7379 ;   target
Bank0C_ScriptAddr_736B:
    dw $FF01                ; $01 if_flag_set: If flag $0022 is set → Bank0C_ScriptAddr_7375
    dw $0022                ;   flag
    dw Bank0C_ScriptAddr_7375 ;   target
    dw $038F                ; text $038F: "*:Have you met the DarkHorn deep inside …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7375:
    dw $0390                ; text $0390: "*:Sometimes I wanna go back behind the G…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7379:
    dw $04AC                ; text $04AC: "*:It's GreatLog! GreatLog, will carry th…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_737D:
    dw $07BD                ; text $07BD: "*:I..I am going to show you a great skil…"
    dw $07BE                ; text $07BE: "But nothing happened."
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_73A7
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_73A7 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0022 is clear → Bank0C_ScriptAddr_7395
    dw $0022                ;   flag
    dw Bank0C_ScriptAddr_7395 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_73A3
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_73A3 ;   target
Bank0C_ScriptAddr_7395:
    dw $FF01                ; $01 if_flag_set: If flag $0022 is set → Bank0C_ScriptAddr_739F
    dw $0022                ;   flag
    dw Bank0C_ScriptAddr_739F ;   target
    dw $0391                ; text $0391: "*:The dragon is always sleeping and he t…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_739F:
    dw $0392                ; text $0392: "*:Behind the Gate of Judgment, there are…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_73A3:
    dw $04AD                ; text $04AD: "*:I believe DeadTree will be victorious!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_73A7:
    dw $07BF                ; text $07BF: "*:I'm HammerMan. I am the strongest of t…"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_73BF
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_73BF ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_73BB
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_73BB ;   target
    dw $0219                ; text $0219: "[HERO] looked in front. Delicious lookin…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_73BB:
    dw $039C                ; text $039C: "[HERO] looked in front. A nasty looking …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_73BF:
    dw $0219                ; text $0219: "[HERO] looked in front. Delicious lookin…"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_73D7
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_73D7 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_73D3
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_73D3 ;   target
    dw $0219                ; text $0219: "[HERO] looked in front. Delicious lookin…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_73D3:
    dw $039C                ; text $039C: "[HERO] looked in front. A nasty looking …"
    dw $FFFF                ; END
Bank0C_ScriptAddr_73D7:
    dw $0219                ; text $0219: "[HERO] looked in front. Delicious lookin…"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $004E is set → Bank0C_ScriptAddr_73F7
    dw $004E                ;   flag
    dw Bank0C_ScriptAddr_73F7 ;   target
    dw $01D1                ; text $01D1: "[SOUND 60][HERO] looked inside the dress…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_73F3
    dw Bank0C_ScriptAddr_73F3 ;   target
    dw $0129                ; text $0129: "Wow! [HERO] got a TinyMedal!"
    dw $FF03                ; $03 set_flag: Set flag $004E
    dw $004E                ;   flag
    dw $FF2A                ; $2A give_item: Give item 30
    dw $001E                ;   item
    dw $FFFF                ; END
Bank0C_ScriptAddr_73F3:
    dw $01D2                ; text $01D2: "Wow! A TinyMedal! But cannot carry any m…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_73F7:
    dw $028A                ; text $028A: "[SOUND 60][HERO] looked into the dresser…"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_740D
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_740D ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0090 is set → Bank0C_ScriptAddr_7427
    dw $0090                ;   flag
    dw Bank0C_ScriptAddr_7427 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0C_ScriptAddr_7411
    dw $0035                ;   flag
    dw Bank0C_ScriptAddr_7411 ;   target
Bank0C_ScriptAddr_740D:
    dw $021B                ; text $021B: "[SOUND 60][HERO] looked into the dresser…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7411:
    dw $01D1                ; text $01D1: "[SOUND 60][HERO] looked inside the dress…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0C_ScriptAddr_7423
    dw Bank0C_ScriptAddr_7423 ;   target
    dw $039D                ; text $039D: "[HERO] got a WarpWing!"
    dw $FF03                ; $03 set_flag: Set flag $0090
    dw $0090                ;   flag
    dw $FF2A                ; $2A give_item: Give item 29
    dw $001D                ;   item
    dw $FFFF                ; END
Bank0C_ScriptAddr_7423:
    dw $039E                ; text $039E: "Found a WarpWing! But cannot carry any m…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7427:
    dw $028A                ; text $028A: "[SOUND 60][HERO] looked into the dresser…"
    dw $FFFF                ; END
    dw $FF00                ; $00 if_flag_clear: If flag $002F is clear → Bank0C_ScriptAddr_74F1
    dw $002F                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $002E is clear → Bank0C_ScriptAddr_74F1
    dw $002E                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $002D is clear → Bank0C_ScriptAddr_74F1
    dw $002D                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $002C is clear → Bank0C_ScriptAddr_74F1
    dw $002C                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $002B is clear → Bank0C_ScriptAddr_74F1
    dw $002B                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $002A is clear → Bank0C_ScriptAddr_74F1
    dw $002A                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0029 is clear → Bank0C_ScriptAddr_74F1
    dw $0029                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0028 is clear → Bank0C_ScriptAddr_74F1
    dw $0028                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0027 is clear → Bank0C_ScriptAddr_74F1
    dw $0027                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0026 is clear → Bank0C_ScriptAddr_74F1
    dw $0026                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0025 is clear → Bank0C_ScriptAddr_74F1
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0024 is clear → Bank0C_ScriptAddr_74F1
    dw $0024                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0023 is clear → Bank0C_ScriptAddr_74F1
    dw $0023                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0022 is clear → Bank0C_ScriptAddr_74F1
    dw $0022                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0021 is clear → Bank0C_ScriptAddr_74F1
    dw $0021                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0020 is clear → Bank0C_ScriptAddr_74F1
    dw $0020                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $001F is clear → Bank0C_ScriptAddr_74F1
    dw $001F                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $001E is clear → Bank0C_ScriptAddr_74F1
    dw $001E                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $001D is clear → Bank0C_ScriptAddr_74F1
    dw $001D                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $001C is clear → Bank0C_ScriptAddr_74F1
    dw $001C                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $001B is clear → Bank0C_ScriptAddr_74F1
    dw $001B                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $001A is clear → Bank0C_ScriptAddr_74F1
    dw $001A                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0019 is clear → Bank0C_ScriptAddr_74F1
    dw $0019                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0018 is clear → Bank0C_ScriptAddr_74F1
    dw $0018                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0017 is clear → Bank0C_ScriptAddr_74F1
    dw $0017                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0016 is clear → Bank0C_ScriptAddr_74F1
    dw $0016                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0015 is clear → Bank0C_ScriptAddr_74F1
    dw $0015                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0014 is clear → Bank0C_ScriptAddr_74F1
    dw $0014                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0013 is clear → Bank0C_ScriptAddr_74F1
    dw $0013                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0012 is clear → Bank0C_ScriptAddr_74F1
    dw $0012                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0011 is clear → Bank0C_ScriptAddr_74F1
    dw $0011                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0010 is clear → Bank0C_ScriptAddr_74F1
    dw $0010                ;   flag
    dw Bank0C_ScriptAddr_74F1 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00FB is set → Bank0C_ScriptAddr_7567
    dw $00FB                ;   flag
    dw Bank0C_ScriptAddr_7567 ;   target
Bank0C_ScriptAddr_74F1:
    dw $FF01                ; $01 if_flag_set: If flag $00FB is set → Bank0C_ScriptAddr_7563
    dw $00FB                ;   flag
    dw Bank0C_ScriptAddr_7563 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_755B
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_755B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $004D is set → Bank0C_ScriptAddr_7519
    dw $004D                ;   flag
    dw Bank0C_ScriptAddr_7519 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $004C is set → Bank0C_ScriptAddr_7511
    dw $004C                ;   flag
    dw Bank0C_ScriptAddr_7511 ;   target
    dw $0212                ; text $0212: "Watabou:Chomp chomp...."
    dw $FF03                ; $03 set_flag: Set flag $004C
    dw $004C                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_7511:
    dw $0213                ; text $0213: "Watabou:Crunch crunch..."
    dw $FF03                ; $03 set_flag: Set flag $004D
    dw $004D                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_7519:
    dw $0214                ; text $0214: "Watabou:Want some? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_7525  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_7525 ;   target
    dw $0215                ; text $0215: "[HERO] got leftovers from Watabou. [HERO…"
Bank0C_ScriptAddr_7525:
    dw $0216                ; text $0216: "Watabou:you gotta win!"
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3: stands still (status cleared)  [slot +$05 := $00]
    dw $0003                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 3, curve 0  [$D8E3 := $0003]
    dw $D8E3                ;   address
    dw $0003                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 3: fly off up-left (the flight path set above)
    dw $1703                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 2 → state 1  [$D947 := 1]
    dw $D947                ;   address
    dw $0001                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_755B:
    dw $07C0                ; text $07C0: "Watabou:[HERO], so you made it! Watabou:…"
    dw $FF03                ; $03 set_flag: Set flag $00FB
    dw $00FB                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_7563:
    dw $07C1                ; text $07C1: "Watabou:There are still Travelers' Gates…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7567:
    dw $07C2                ; text $07C2: "Watabou:You made it! [HERO]!! You beat'e…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_75B3  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_75B3 ;   target
    dw $FF28                ; $28 if_storage_full: Go to target when all 20 monster slots are taken → Bank0C_ScriptAddr_75B7
    dw Bank0C_ScriptAddr_75B7 ;   target
    dw $07C5                ; text $07C5: "Watabou:Good to meet you [HERO]. I'll be…"
    dw $FF03                ; $03 set_flag: Set flag $00FC
    dw $00FC                ;   flag
    dw $FF29                ; $29 add_monster: Add monster: enemy row 223
    dw $00DF                ;   enemy
    dw $FF12                ; $12 write_ram: Room state of Stable screen 2 → state 1  [$D947 := 1]
    dw $D947                ;   address
    dw $0001                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3: stands still (status cleared)  [slot +$05 := $00]
    dw $0003                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 3, curve 0  [$D8E3 := $0003]
    dw $D8E3                ;   address
    dw $0003                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 3: fly off up-left (the flight path set above)
    dw $1703                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FFFF                ; END
Bank0C_ScriptAddr_75B3:
    dw $07C3                ; text $07C3: "Watabou:Oh well, you don't need me... [H…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_75B7:
    dw $07C4                ; text $07C4: "Watabou:Hey, you have too many pals! Wat…"
    dw $FFFF                ; END
    dw $0218                ; text $0218: "*:Zzz.. You're at the Monster Stable. *:…"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_75D3
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_75D3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0C_ScriptAddr_75CF
    dw $0034                ;   flag
    dw Bank0C_ScriptAddr_75CF ;   target
    dw $0217                ; text $0217: "*:No monster can stay up under my SleepA…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_75CF:
    dw $0340                ; text $0340: "*:It's strange. My power of SleepAir is.…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_75D3:
    dw $07C6                ; text $07C6: "*:Watabou's magic spell Chance, is very …"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $008E is set → Bank0C_ScriptAddr_75F3
    dw $008E                ;   flag
    dw Bank0C_ScriptAddr_75F3 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $008D is set → Bank0C_ScriptAddr_75EB
    dw $008D                ;   flag
    dw Bank0C_ScriptAddr_75EB ;   target
    dw $0393                ; text $0393: "Warubou:Chomp chomp.."
    dw $FF03                ; $03 set_flag: Set flag $008D
    dw $008D                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_75EB:
    dw $0394                ; text $0394: "Warubou:Crunch crunch.."
    dw $FF03                ; $03 set_flag: Set flag $008E
    dw $008E                ;   flag
    dw $FFFF                ; END
Bank0C_ScriptAddr_75F3:
    dw $0395                ; text $0395: "Warubou:What are you looking at? Want to…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_7605  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_7605 ;   target
    dw $0396                ; text $0396: "[HERO] got leftovers from Warubou! It's …"
    dw $0397                ; text $0397: "Warubou:Ha! Serves you right!"
    dw $FF14                ; $14 goto: Go to Bank0C_ScriptAddr_7613
    dw Bank0C_ScriptAddr_7613 ;   target
Bank0C_ScriptAddr_7605:
    dw $0398                ; text $0398: "Warubou:What? Don't you wanna eat this? …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0C_ScriptAddr_7605  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0C_ScriptAddr_7605 ;   target
    dw $0399                ; text $0399: "[HERO] got leftovers from Warubou. It's …"
    dw $039A                ; text $039A: "Warubou:Ha! Serves you right!"
Bank0C_ScriptAddr_7613:
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3: stands still (status cleared)  [slot +$05 := $00]
    dw $0003                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 3, curve 0  [$D8E3 := $0003]
    dw $D8E3                ;   address
    dw $0003                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 3: fly off up-left (the flight path set above)
    dw $1703                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 2 → state 3  [$D947 := 3]
    dw $D947                ;   address
    dw $0003                ;   value
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0C_ScriptAddr_766F
    dw $00F1                ;   flag
    dw Bank0C_ScriptAddr_766F ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0C_ScriptAddr_766B
    dw $0025                ;   flag
    dw Bank0C_ScriptAddr_766B ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0C_ScriptAddr_7667
    dw $0037                ;   flag
    dw Bank0C_ScriptAddr_7667 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0C_ScriptAddr_7663
    dw $0036                ;   flag
    dw Bank0C_ScriptAddr_7663 ;   target
    dw $039B                ; text $039B: "*:WhipBird can do Call. Eeeek!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7663:
    dw $03F0                ; text $03F0: "*:I wonder what will happen if I use Cha…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_7667:
    dw $044C                ; text $044C: "*:Do ya know GigaSlash? It's great. EEEE…"
    dw $FFFF                ; END
Bank0C_ScriptAddr_766B:
    dw $04AE                ; text $04AE: "*:You win, GreatTree happy. Eek!"
    dw $FFFF                ; END
Bank0C_ScriptAddr_766F:
    dw $07C6                ; text $07C6: "*:Watabou's magic spell Chance, is very …"
    dw $FFFF                ; END
    db $75
    db $76
    db $FF
    db $FF
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
