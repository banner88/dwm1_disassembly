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
    dw labelc_402f           ; Entry 1: VRAM tile update (screen rendering)
    dw labelc_4110           ; Entry 2: (unknown)

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

labelc_402f:
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

labelc_4110:
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
    dw Castle_ScriptPtrTable           ; [0] Castle
    dw GreatTree_ScriptPtrTable        ; [1] GreatTree
    dw Bazaar_ScriptPtrTable           ; [2] Bazaar
    dw GateHub_ScriptPtrTable          ; [3] GateHub
    dw Farm_ScriptPtrTable             ; [4] Farm
    dw Stable_ScriptPtrTable           ; [5] Stable
; ---------------------------------------------------------------------------
; Castle Per-Script Table (map_type=$00, 20 scripts)
; ---------------------------------------------------------------------------
Castle_ScriptPtrTable:
    dw Castle_Script00                 ; script 0
    dw Castle_Script01                 ; script 1
    dw Castle_Script02                 ; script 2
    dw Castle_Script03                 ; script 3
    dw Castle_Script04                 ; script 4
    dw Castle_Script05                 ; script 5
    dw Castle_Script06                 ; script 6
    dw Castle_Script07                 ; script 7
    dw Castle_Script08                 ; script 8
    dw Castle_Script09                 ; script 9
    dw Castle_Script10                 ; script 10
    dw Castle_Script11                 ; script 11
    dw Castle_Script12                 ; script 12
    dw Castle_Script13                 ; script 13
    dw Castle_Script14                 ; script 14
    dw Castle_Script15                 ; script 15
    dw Castle_Script16                 ; script 16
    dw Castle_Script17                 ; script 17
    dw Castle_Script18                 ; script 18
    dw Castle_Script19                 ; script 19
; ---------------------------------------------------------------------------
; Castle_Script00
; ---------------------------------------------------------------------------
Castle_Script00:
    dw $FF0E  ; SetMapTransition
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_4246          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw Bank0C_ScriptAddr_41FC          ; -> branch target
    dw $FFFF  ; END

Bank0C_ScriptAddr_41FC:
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $00FF  ; Text $00FF: "My rival's watching me from somewhere..."
    dw $4212
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw $41FA
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "Gwrr, Gwrr... // In the back, they teach"
    dw $50A8
    dw $FFFF  ; END

    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $08
    db $FF
    db $0B
    db $FF
    db $04
    db $00
    db $20
    db $00
    db $07
    db $FF
    db $15
    db $00
    db $06
    db $FF
    db $0B
    db $FF
    db $04
    db $00
    db $80
    db $FF
    db $03
    db $FF
    db $01
    db $00
    db $12
    db $FF
    db $2C
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $2D
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $51
    db $D9
    db $00
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_4246:
    dw $FF15  ; PlaySE
    dw $D92B  ; RAM $D92B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $4270
    dw $FF15  ; PlaySE
    dw $D92B  ; RAM $D92B
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $4270
    dw $FF15  ; PlaySE
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $490A
    dw $FF15  ; PlaySE
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $47E0
    dw $FF15  ; PlaySE
    dw $D92B  ; RAM $D92B
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $490A
    dw $FFFF  ; END

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
    dw $FF01  ; if_flag_set $00F1 -> $41FA
    dw $00F1
    dw $41FA
    dw $FF01  ; if_flag_set $00EE -> $44BA
    dw $00EE
    dw $44BA
    dw $FF01  ; if_flag_set $009A -> $41FA
    dw $009A
    dw $41FA
    dw $FF01  ; if_flag_set $0037 -> $4438
    dw $0037
    dw $4438
    dw $FF01  ; if_flag_set $0069 -> $41FA
    dw $0069
    dw $41FA
    dw $FF01  ; if_flag_set $0033 -> $440C
    dw $0033
    dw $440C
    dw $FF01  ; if_flag_set $003E -> $41FA
    dw $003E
    dw $41FA
    dw $FF01  ; if_flag_set $0030 -> $438C
    dw $0030
    dw $438C
    dw $FF01  ; if_flag_set $0008 -> $41FA
    dw $0008
    dw $41FA
    dw $FF01  ; if_flag_set $0007 -> $42EC
    dw $0007
    dw $42EC
    dw $FF01  ; if_flag_set $0002 -> $41FA   (starter-given flag: skip once granted)
    dw $0002
    dw $41FA
    ; --- fall-through: brand-new save, grant the starter ---
    dw $FF10  ; npc_moveto npc#0, $00E8
    dw $0000
    dw $00E8
    dw $FF0B  ; npc_move_y  npc#0, -32
    dw $0000
    dw $FFE0
    dw $FF07  ; init_dialog $0020   (intro text)
    dw $0020
    dw $FF06  ; inc_counter
    dw $FF12  ; write_ram  [$C8F4] = $0000
    dw $C8F4
    dw $0000
    dw $FF13  ; write_ram2 [$C8F2] = $CA42
    dw $C8F2
    dw $CA42
    dw $FF04  ; screen_effect $000F, $0000
    dw $000F
    dw $0000
    dw $FF29  ; add_monster  <<<<<<  STARTER MONSTER GRANT
    dw $0001  ;   enemy = enemy-stats EID $0001 = "Slib" (Lv1 Slime; $14:$4C36).
              ;   Change enemy-stats entry 1 to change the starting monster.
    dw $FF07  ; init_dialog $0021
    dw $0021
    dw $FF06  ; inc_counter
    dw $FF03  ; set_flag $0002   (mark starter granted; cascade above skips hereafter)
    dw $0002
    dw $FF12  ; write_ram  [$D92C] = $0002
    dw $D92C
    dw $0002
    dw $FFFF  ; END
    db $10
    db $FF
    db $00
    db $00
    db $E8
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $E0
    db $FF
    db $07
    db $FF
    db $45
    db $00
    db $06
    db $FF
    db $22
    db $FF
    db $1B
    db $FF
    db $02
    db $00
    db $60
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $18
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $02
    db $00
    db $A0
    db $FF
    db $19
    db $FF
    db $48
    db $FF
    db $02
    db $00
    db $0D
    db $FF
    db $04
    db $00
    db $00
    db $00
    db $00
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $04
    db $00
    db $E0
    db $FF
    db $19
    db $FF
    db $07
    db $FF
    db $46
    db $00
    db $47
    db $00
    db $48
    db $00
    db $49
    db $00
    db $06
    db $FF
    db $4C
    db $FF
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $4A
    db $00
    db $06
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $1C
    db $FF
    db $04
    db $04
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $3D
    db $FF
    db $07
    db $FF
    db $4B
    db $00
    db $4C
    db $00
    db $06
    db $FF
    db $03
    db $FF
    db $08
    db $00
    db $12
    db $FF
    db $2B
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $2C
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $3C
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $3F
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $40
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $44
    db $D9
    db $01
    db $00
    db $14
    db $FF
    db $EE
    db $46
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $12
    db $FF
    db $EC
    db $C8
    db $00
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $0E
    db $00
    db $0D
    db $FF
    db $06
    db $00
    db $00
    db $00
    db $00
    db $00
    db $08
    db $FF
    db $07
    db $FF
    db $47
    db $01
    db $0B
    db $FF
    db $06
    db $00
    db $D0
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $07
    db $FF
    db $48
    db $01
    db $09
    db $FF
    db $02
    db $00
    db $49
    db $FF
    db $06
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $07
    db $FF
    db $49
    db $01
    db $09
    db $FF
    db $02
    db $00
    db $47
    db $FF
    db $06
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $07
    db $FF
    db $4A
    db $01
    db $09
    db $FF
    db $02
    db $00
    db $48
    db $FF
    db $06
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0B
    db $FF
    db $06
    db $00
    db $30
    db $00
    db $0D
    db $FF
    db $06
    db $00
    db $00
    db $00
    db $40
    db $00
    db $07
    db $FF
    db $4B
    db $01
    db $03
    db $FF
    db $3E
    db $00
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $EE
    db $46
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $12
    db $FF
    db $EC
    db $C8
    db $00
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $0E
    db $00
    db $08
    db $FF
    db $07
    db $FF
    db $72
    db $02
    db $03
    db $FF
    db $69
    db $00
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $EE
    db $46
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $12
    db $FF
    db $EC
    db $C8
    db $00
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $0E
    db $00
    db $0D
    db $FF
    db $06
    db $00
    db $00
    db $00
    db $00
    db $00
    db $08
    db $FF
    db $07
    db $FF
    db $10
    db $04
    db $0B
    db $FF
    db $06
    db $00
    db $D0
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $07
    db $FF
    db $11
    db $04
    db $12
    db $04
    db $09
    db $FF
    db $02
    db $00
    db $49
    db $FF
    db $06
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $07
    db $FF
    db $13
    db $04
    db $09
    db $FF
    db $02
    db $00
    db $47
    db $FF
    db $06
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $07
    db $FF
    db $14
    db $04
    db $09
    db $FF
    db $02
    db $00
    db $48
    db $FF
    db $06
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0B
    db $FF
    db $06
    db $00
    db $30
    db $00
    db $0D
    db $FF
    db $06
    db $00
    db $00
    db $00
    db $40
    db $00
    db $07
    db $FF
    db $15
    db $04
    db $03
    db $FF
    db $9A
    db $00
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $EE
    db $46
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $12
    db $FF
    db $EC
    db $C8
    db $00
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $0E
    db $00
    db $08
    db $FF
    db $0B
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $0A
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $4A
    db $FF
    db $03
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $E0
    db $FF
    db $07
    db $FF
    db $B8
    db $05
    db $12
    db $FF
    db $ED
    db $C8
    db $0F
    db $00
    db $0D
    db $FF
    db $07
    db $00
    db $00
    db $00
    db $00
    db $00
    db $08
    db $FF
    db $0A
    db $FF
    db $00
    db $00
    db $10
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $10
    db $00
    db $0A
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $47
    db $FF
    db $00
    db $00
    db $08
    db $FF
    db $45
    db $FF
    db $16
    db $FF
    db $15
    db $FF
    db $B9
    db $CA
    db $01
    db $00
    db $AC
    db $45
    db $21
    db $FF
    db $00
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $00
    db $00
    db $00
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $00
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $D2
    db $00
    db $48
    db $FF
    db $07
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $0D
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $00
    db $00
    db $40
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $18
    db $00
    db $F8
    db $00
    db $15
    db $FF
    db $B9
    db $CA
    db $02
    db $00
    db $AC
    db $45
    db $21
    db $FF
    db $00
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $00
    db $00
    db $00
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $00
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $D2
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $09
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $00
    db $00
    db $40
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $18
    db $00
    db $F8
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $1A
    db $00
    db $58
    db $00
    db $21
    db $FF
    db $00
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $00
    db $00
    db $00
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $00
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $D2
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $00
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $D2
    db $00
    db $15
    db $FF
    db $B9
    db $CA
    db $01
    db $00
    db $F0
    db $45
    db $15
    db $FF
    db $B9
    db $CA
    db $02
    db $00
    db $F0
    db $45
    db $4A
    db $FF
    db $07
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $01
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $00
    db $00
    db $40
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $1C
    db $FF
    db $07
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $07
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $1C
    db $FF
    db $07
    db $04
    db $19
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $0D
    db $FF
    db $07
    db $00
    db $00
    db $00
    db $40
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $00
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $07
    db $FF
    db $B9
    db $05
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $10
    db $00
    db $49
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $24
    db $FF
    db $E2
    db $50
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $01
    db $00
    db $21
    db $FF
    db $51
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $40
    db $00
    db $48
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $03
    db $FF
    db $F1
    db $00
    db $12
    db $FF
    db $2B
    db $D9
    db $05
    db $00
    db $12
    db $FF
    db $2C
    db $D9
    db $04
    db $00
    db $12
    db $FF
    db $2D
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $33
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $34
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $00
    db $00
    db $FF
    db $FF
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $10
    db $00
    db $49
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $24
    db $FF
    db $E2
    db $50
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $01
    db $00
    db $21
    db $FF
    db $51
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $40
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $F0
    db $FF
    db $48
    db $FF
    db $02
    db $00
    db $01
    db $FF
    db $EE
    db $00
    db $9A
    db $47
    db $01
    db $FF
    db $37
    db $00
    db $B6
    db $47
    db $01
    db $FF
    db $33
    db $00
    db $9A
    db $47
    db $01
    db $FF
    db $30
    db $00
    db $A2
    db $47
    db $01
    db $FF
    db $07
    db $00
    db $9A
    db $47
    db $12
    db $FF
    db $ED
    db $C8
    db $00
    db $00
    db $FF
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $07
    db $FF
    db $4C
    db $01
    db $12
    db $FF
    db $ED
    db $C8
    db $00
    db $00
    db $FF
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $07
    db $FF
    db $16
    db $04
    db $06
    db $FF
    db $12
    db $FF
    db $8A
    db $C8
    db $03
    db $00
    db $12
    db $FF
    db $8B
    db $C8
    db $03
    db $00
    db $3E
    db $FF
    db $08
    db $FF
    db $07
    db $FF
    db $17
    db $04
    db $12
    db $FF
    db $ED
    db $C8
    db $00
    db $00
    db $FF
    db $FF
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $12
    db $FF
    db $EC
    db $C8
    db $00
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $0E
    db $00
    db $01
    db $FF
    db $1D
    db $00
    db $04
    db $48
    db $01
    db $FF
    db $33
    db $00
    db $70
    db $49
    db $15
    db $FF
    db $E3
    db $D9
    db $4E
    db $00
    db $C6
    db $4E
    db $15
    db $FF
    db $E3
    db $D9
    db $4D
    db $00
    db $BC
    db $4E
    db $15
    db $FF
    db $E3
    db $D9
    db $4C
    db $00
    db $B2
    db $4E
    db $15
    db $FF
    db $E3
    db $D9
    db $4B
    db $00
    db $A8
    db $4E
    db $15
    db $FF
    db $E3
    db $D9
    db $4A
    db $00
    db $9E
    db $4E
    db $15
    db $FF
    db $E3
    db $D9
    db $49
    db $00
    db $94
    db $4E
    db $15
    db $FF
    db $E3
    db $D9
    db $48
    db $00
    db $8A
    db $4E
    db $15
    db $FF
    db $E3
    db $D9
    db $C7
    db $00
    db $80
    db $4E
    db $15
    db $FF
    db $E3
    db $D9
    db $47
    db $00
    db $76
    db $4E
    db $15
    db $FF
    db $E3
    db $D9
    db $46
    db $00
    db $48
    db $4E
    db $15
    db $FF
    db $E3
    db $D9
    db $45
    db $00
    db $98
    db $4C
    db $01
    db $FF
    db $F1
    db $00
    db $80
    db $49
    db $15
    db $FF
    db $E3
    db $D9
    db $44
    db $00
    db $8E
    db $4C
    db $15
    db $FF
    db $E3
    db $D9
    db $43
    db $00
    db $84
    db $4C
    db $15
    db $FF
    db $E3
    db $D9
    db $42
    db $00
    db $58
    db $4C
    db $15
    db $FF
    db $E3
    db $D9
    db $41
    db $00
    db $2C
    db $4C
    db $15
    db $FF
    db $E3
    db $D9
    db $3F
    db $00
    db $22
    db $4C
    db $15
    db $FF
    db $E3
    db $D9
    db $3E
    db $00
    db $F6
    db $4B
    db $15
    db $FF
    db $E3
    db $D9
    db $3D
    db $00
    db $EC
    db $4B
    db $15
    db $FF
    db $E3
    db $D9
    db $3B
    db $00
    db $E2
    db $4B
    db $15
    db $FF
    db $E3
    db $D9
    db $3A
    db $00
    db $B6
    db $4B
    db $15
    db $FF
    db $E3
    db $D9
    db $10
    db $00
    db $AC
    db $4B
    db $15
    db $FF
    db $E3
    db $D9
    db $39
    db $00
    db $80
    db $4B
    db $15
    db $FF
    db $E3
    db $D9
    db $3C
    db $00
    db $F0
    db $4A
    db $15
    db $FF
    db $E3
    db $D9
    db $38
    db $00
    db $E6
    db $4A
    db $15
    db $FF
    db $E3
    db $D9
    db $37
    db $00
    db $DC
    db $4A
    db $15
    db $FF
    db $E3
    db $D9
    db $36
    db $00
    db $B0
    db $4A
    db $15
    db $FF
    db $E3
    db $D9
    db $35
    db $00
    db $84
    db $4A
    db $15
    db $FF
    db $E3
    db $D9
    db $34
    db $00
    db $7A
    db $4A
    db $15
    db $FF
    db $E3
    db $D9
    db $33
    db $00
    db $4E
    db $4A
    db $15
    db $FF
    db $E3
    db $D9
    db $32
    db $00
    db $44
    db $4A
    db $15
    db $FF
    db $E3
    db $D9
    db $31
    db $00
    db $18
    db $4A
    db $15
    db $FF
    db $E3
    db $D9
    db $30
    db $00
    db $AC
    db $49
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $12
    db $FF
    db $EC
    db $C8
    db $00
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $0E
    db $00
    db $01
    db $FF
    db $09
    db $00
    db $30
    db $49
    db $0D
    db $FF
    db $04
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $FF
    db $F1
    db $00
    db $46
    db $49
    db $0D
    db $FF
    db $02
    db $00
    db $00
    db $00
    db $40
    db $00
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $00
    db $00
    db $08
    db $FF
    db $12
    db $FF
    db $2B
    db $D9
    db $05
    db $00
    db $01
    db $FF
    db $F1
    db $00
    db $66
    db $49
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $01
    db $FF
    db $09
    db $00
    db $66
    db $49
    db $12
    db $FF
    db $2B
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $E3
    db $D9
    db $FF
    db $00
    db $14
    db $FF
    db $00
    db $50
    db $08
    db $FF
    db $07
    db $FF
    db $75
    db $02
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $C5
    db $05
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $CE
    db $07
    db $12
    db $FF
    db $2B
    db $D9
    db $05
    db $00
    db $14
    db $FF
    db $D6
    db $4E
    db $0D
    db $FF
    db $04
    db $00
    db $00
    db $00
    db $00
    db $00
    db $08
    db $FF
    db $07
    db $FF
    db $5A
    db $00
    db $1C
    db $FF
    db $04
    db $04
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $49
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $07
    db $FF
    db $5B
    db $00
    db $0B
    db $FF
    db $04
    db $00
    db $20
    db $00
    db $0D
    db $FF
    db $04
    db $00
    db $00
    db $00
    db $40
    db $00
    db $07
    db $FF
    db $5C
    db $00
    db $03
    db $FF
    db $09
    db $00
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $2C
    db $D9
    db $04
    db $00
    db $12
    db $FF
    db $2D
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $2F
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $3C
    db $D9
    db $02
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $4D
    db $01
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $4E
    db $01
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $51
    db $01
    db $14
    db $FF
    db $1E
    db $4A
    db $08
    db $FF
    db $07
    db $FF
    db $AB
    db $01
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $AC
    db $01
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $AE
    db $01
    db $14
    db $FF
    db $54
    db $4A
    db $08
    db $FF
    db $07
    db $FF
    db $1A
    db $02
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $4E
    db $01
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $F4
    db $01
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $AC
    db $01
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $F2
    db $01
    db $14
    db $FF
    db $B6
    db $4A
    db $08
    db $FF
    db $07
    db $FF
    db $B6
    db $03
    db $14
    db $FF
    db $B6
    db $4A
    db $0D
    db $FF
    db $06
    db $00
    db $00
    db $00
    db $00
    db $00
    db $08
    db $FF
    db $07
    db $FF
    db $A9
    db $02
    db $0B
    db $FF
    db $06
    db $00
    db $F0
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $0B
    db $FF
    db $06
    db $00
    db $F0
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $0B
    db $FF
    db $06
    db $00
    db $F0
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $07
    db $FF
    db $AA
    db $02
    db $09
    db $FF
    db $04
    db $00
    db $49
    db $FF
    db $06
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $07
    db $FF
    db $AB
    db $02
    db $09
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $06
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $07
    db $FF
    db $AC
    db $02
    db $09
    db $FF
    db $08
    db $00
    db $48
    db $FF
    db $06
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $0B
    db $FF
    db $06
    db $00
    db $10
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $0B
    db $FF
    db $06
    db $00
    db $10
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $0B
    db $FF
    db $06
    db $00
    db $10
    db $00
    db $0D
    db $FF
    db $06
    db $00
    db $00
    db $00
    db $40
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $07
    db $FF
    db $AD
    db $02
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $B6
    db $02
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $63
    db $08
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $50
    db $01
    db $14
    db $FF
    db $86
    db $4B
    db $08
    db $FF
    db $07
    db $FF
    db $37
    db $03
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $B7
    db $02
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $3A
    db $03
    db $14
    db $FF
    db $BC
    db $4B
    db $08
    db $FF
    db $07
    db $FF
    db $3B
    db $03
    db $14
    db $FF
    db $BC
    db $4B
    db $08
    db $FF
    db $07
    db $FF
    db $66
    db $03
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $67
    db $03
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $69
    db $03
    db $14
    db $FF
    db $FC
    db $4B
    db $08
    db $FF
    db $07
    db $FF
    db $40
    db $01
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $42
    db $01
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $E5
    db $03
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $67
    db $03
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $14
    db $FF
    db $6A
    db $4F
    db $08
    db $FF
    db $07
    db $FF
    db $E6
    db $03
    db $14
    db $FF
    db $5E
    db $4C
    db $08
    db $FF
    db $07
    db $FF
    db $6A
    db $03
    db $14
    db $FF
    db $5E
    db $4C
    db $08
    db $FF
    db $07
    db $FF
    db $85
    db $04
    db $09
    db $FF
    db $04
    db $00
    db $41
    db $FF
    db $02
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $D2
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $D2
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $E2
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $E7
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $E7
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $F7
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $FB
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $FB
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $FB
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $FF
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $FF
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $FF
    db $00
    db $12
    db $FF
    db $EC
    db $C8
    db $01
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $62
    db $FF
    db $12
    db $FF
    db $9B
    db $C8
    db $D2
    db $00
    db $08
    db $FF
    db $07
    db $FF
    db $D1
    db $08
    db $06
    db $FF
    db $12
    db $FF
    db $9B
    db $C8
    db $FF
    db $00
    db $08
    db $FF
    db $63
    db $FF
    db $27
    db $FF
    db $16
    db $FF
    db $41
    db $FF
    db $3F
    db $00
    db $46
    db $FF
    db $09
    db $FF
    db $18
    db $00
    db $12
    db $FF
    db $EC
    db $C8
    db $00
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $FF
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $FF
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $FF
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $FB
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $FB
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $FB
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $E7
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $E7
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $F7
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $D2
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $D2
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $E2
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $41
    db $FF
    db $09
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $07
    db $FF
    db $86
    db $04
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $88
    db $04
    db $12
    db $FF
    db $2B
    db $D9
    db $03
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $10
    db $00
    db $49
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $24
    db $FF
    db $E2
    db $50
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $01
    db $00
    db $21
    db $FF
    db $51
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $40
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $F0
    db $FF
    db $48
    db $FF
    db $02
    db $00
    db $FF
    db $FF
    db $08
    db $FF
    db $07
    db $FF
    db $C2
    db $05
    db $C3
    db $05
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $3C
    db $FF
    db $07
    db $FF
    db $41
    db $01
    db $06
    db $FF
    db $3D
    db $FF
    db $07
    db $FF
    db $C4
    db $05
    db $12
    db $FF
    db $2B
    db $D9
    db $05
    db $00
    db $14
    db $FF
    db $D6
    db $4E
    db $08
    db $FF
    db $07
    db $FF
    db $C6
    db $05
    db $14
    db $FF
    db $4E
    db $4E
    db $08
    db $FF
    db $07
    db $FF
    db $C7
    db $05
    db $14
    db $FF
    db $4E
    db $4E
    db $08
    db $FF
    db $07
    db $FF
    db $C8
    db $05
    db $14
    db $FF
    db $4E
    db $4E
    db $08
    db $FF
    db $07
    db $FF
    db $C9
    db $05
    db $14
    db $FF
    db $4E
    db $4E
    db $08
    db $FF
    db $07
    db $FF
    db $CA
    db $05
    db $14
    db $FF
    db $4E
    db $4E
    db $08
    db $FF
    db $07
    db $FF
    db $CB
    db $05
    db $14
    db $FF
    db $4E
    db $4E
    db $08
    db $FF
    db $07
    db $FF
    db $CC
    db $05
    db $14
    db $FF
    db $4E
    db $4E
    db $08
    db $FF
    db $07
    db $FF
    db $CD
    db $05
    db $14
    db $FF
    db $4E
    db $4E
    db $08
    db $FF
    db $07
    db $FF
    db $CE
    db $05
    db $12
    db $FF
    db $2B
    db $D9
    db $05
    db $00
    db $14
    db $FF
    db $D6
    db $4E
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $10
    db $00
    db $49
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $24
    db $FF
    db $E2
    db $50
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $01
    db $00
    db $21
    db $FF
    db $51
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $40
    db $00
    db $48
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $14
    db $FF
    db $00
    db $50
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $10
    db $00
    db $49
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $03
    db $00
    db $24
    db $FF
    db $E2
    db $50
    db $22
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $01
    db $00
    db $21
    db $FF
    db $51
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $40
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $F0
    db $FF
    db $48
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $07
    db $FF
    db $4E
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $00
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $FF
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $FF
    db $00
    db $4D
    db $FF
    db $06
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $D2
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $D2
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $E2
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $00
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $2D
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $FF
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $FF
    db $00
    db $4D
    db $FF
    db $06
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $D2
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $D2
    db $00
    db $12
    db $FF
    db $9D
    db $C8
    db $E2
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $27
    db $FF
    db $16
    db $FF
    db $15
    db $FF
    db $E3
    db $D9
    db $30
    db $00
    db $8A
    db $50
    db $15
    db $FF
    db $E3
    db $D9
    db $3C
    db $00
    db $90
    db $50
    db $2C
    db $FF
    db $84
    db $50
    db $07
    db $FF
    db $CB
    db $08
    db $2A
    db $FF
    db $01
    db $00
    db $FF
    db $FF
    db $07
    db $FF
    db $CC
    db $08
    db $FF
    db $FF
    db $07
    db $FF
    db $5E
    db $00
    db $FF
    db $FF
    db $12
    db $FF
    db $8A
    db $C8
    db $03
    db $00
    db $12
    db $FF
    db $8B
    db $C8
    db $03
    db $00
    db $3E
    db $FF
    db $08
    db $FF
    db $07
    db $FF
    db $AE
    db $02
    db $FF
    db $FF
    db $FF
    db $FF
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $00
    db $00
    db $08
    db $FF
    db $0B
    db $FF
    db $04
    db $00
    db $20
    db $00
    db $07
    db $FF
    db $B7
    db $05
    db $06
    db $FF
    db $1B
    db $FF
    db $04
    db $00
    db $70
    db $FF
    db $1B
    db $FF
    db $05
    db $00
    db $70
    db $FF
    db $19
    db $FF
    db $12
    db $FF
    db $2C
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $2D
    db $D9
    db $04
    db $00
    db $0F
    db $FF
    db $00
    db $00
    db $E8
    db $00
    db $78
    db $00
    db $FF
    db $FF
    db $2E
    db $00
    db $44
    db $45
    db $D8
    db $70
    db $71
    db $D8
    db $72
    db $73
    db $D9
; ---------------------------------------------------------------------------
; Castle_Script01
; ---------------------------------------------------------------------------
Castle_Script01:
    dw $0024  ; Text $0024: "It's a little kingdom built inside a big"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_50FB          ; -> branch target
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw $FFFF  ; END

Bank0C_ScriptAddr_50FB:
    dw $0026  ; Text $0026: "[HERO] looked at the bookshelf. The Mast"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script02
; ---------------------------------------------------------------------------
Castle_Script02:
    dw $0027  ; Text $0027: "People who understand monster talk and a"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_510D          ; -> branch target
    dw $0028  ; Text $0028: "I wanna be a master. What should I do? /"
    dw $FFFF  ; END

Bank0C_ScriptAddr_510D:
    dw $0026  ; Text $0026: "[HERO] looked at the bookshelf. The Mast"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script03
; ---------------------------------------------------------------------------
Castle_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $003A  ; Text $003A: "[HERO] looked into the jar. The jar is f"
    dw Bank0C_ScriptAddr_5183          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $003B  ; Text $003B: "Hey you! You came here to steal my monst"
    dw Bank0C_ScriptAddr_5155          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw Bank0C_ScriptAddr_5127          ; -> branch target
    dw $0379  ; Text $0379: "Hm.. It seems there are several hidden G"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5127:
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF24  ; Cmd24
    dw $5187
    dw $FF07  ; InitDialogMode
    dw $001B  ; Text $001B: "[HERO] picked up an Herb. // [HERO] foun"
    dw $FF2C  ; CheckInvFull
    dw $5149
    dw $001C  ; Text $001C: "[HERO] found an Herb. But cannot carry a"
    dw $FF03  ; SetEventFlag
    dw $003A  ; Text $003A: "[HERO] looked into the jar. The jar is f"
    dw $FF12  ; WriteRAM
    dw $D92A  ; RAM $D92A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF2A  ; GiveItem
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFFF  ; END

    db $1D
    db $00
    db $21
    db $FF
    db $60
    db $00
    db $24
    db $FF
    db $8C
    db $51
    db $FF
    db $FF
Bank0C_ScriptAddr_5155:
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF24  ; Cmd24
    dw $5187
    dw $FF07  ; InitDialogMode
    dw $001B  ; Text $001B: "[HERO] picked up an Herb. // [HERO] foun"
    dw $FF2C  ; CheckInvFull
    dw $5177
    dw $001C  ; Text $001C: "[HERO] found an Herb. But cannot carry a"
    dw $FF03  ; SetEventFlag
    dw $003A  ; Text $003A: "[HERO] looked into the jar. The jar is f"
    dw $FF12  ; WriteRAM
    dw $D92A  ; RAM $D92A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF2A  ; GiveItem
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFFF  ; END

    db $1D
    db $00
    db $21
    db $FF
    db $60
    db $00
    db $24
    db $FF
    db $8C
    db $51
    db $FF
    db $FF
Bank0C_ScriptAddr_5183:
    dw $013C  ; Text $013C: "I'm Mick. Who are you? Whew, those crazy"
    dw $FFFF  ; END

    db $86
    db $00
    db $0C
    db $0D
    db $D9
    db $86
    db $00
    db $0E
    db $0F
    db $D9
; ---------------------------------------------------------------------------
; Castle_Script04
; ---------------------------------------------------------------------------
Castle_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $003B  ; Text $003B: "Hey you! You came here to steal my monst"
    dw Bank0C_ScriptAddr_5203          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $003A  ; Text $003A: "[HERO] looked into the jar. The jar is f"
    dw Bank0C_ScriptAddr_51D5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw Bank0C_ScriptAddr_51A7          ; -> branch target
    dw $0379  ; Text $0379: "Hm.. It seems there are several hidden G"
    dw $FFFF  ; END

Bank0C_ScriptAddr_51A7:
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF24  ; Cmd24
    dw $5207
    dw $FF07  ; InitDialogMode
    dw $001E  ; Text $001E: "This is the Kingdom of GreatTree! // Wel"
    dw $FF2C  ; CheckInvFull
    dw $51C9
    dw $0127  ; Text $0127: "My journey to the Travelers' Gate is a f"
    dw $FF03  ; SetEventFlag
    dw $003B  ; Text $003B: "Hey you! You came here to steal my monst"
    dw $FF12  ; WriteRAM
    dw $D92A  ; RAM $D92A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF2A  ; GiveItem
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFFF  ; END

    db $28
    db $01
    db $21
    db $FF
    db $60
    db $00
    db $24
    db $FF
    db $0C
    db $52
    db $FF
    db $FF
Bank0C_ScriptAddr_51D5:
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF24  ; Cmd24
    dw $5207
    dw $FF07  ; InitDialogMode
    dw $001E  ; Text $001E: "This is the Kingdom of GreatTree! // Wel"
    dw $FF2C  ; CheckInvFull
    dw $51F7
    dw $0127  ; Text $0127: "My journey to the Travelers' Gate is a f"
    dw $FF03  ; SetEventFlag
    dw $003B  ; Text $003B: "Hey you! You came here to steal my monst"
    dw $FF12  ; WriteRAM
    dw $D92A  ; RAM $D92A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF2A  ; GiveItem
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFFF  ; END

    db $28
    db $01
    db $21
    db $FF
    db $60
    db $00
    db $24
    db $FF
    db $0C
    db $52
    db $FF
    db $FF
Bank0C_ScriptAddr_5203:
    dw $013C  ; Text $013C: "I'm Mick. Who are you? Whew, those crazy"
    dw $FFFF  ; END

    db $88
    db $00
    db $0C
    db $0D
    db $D9
    db $88
    db $00
    db $0E
    db $0F
    db $D9
; ---------------------------------------------------------------------------
; Castle_Script05
; ---------------------------------------------------------------------------
Castle_Script05:
    dw $083B  ; Text $083B: "Just kidding! You're still a kid! // My "
    dw $FF2C  ; CheckInvFull
    dw Bank0C_ScriptAddr_521F          ; -> branch target
    dw $083C  ; Text $083C: "My hubby loves our girl so much.. ..he k"
    dw $FF2A  ; GiveItem
    dw $0017  ; Text $0017: "This is the castle of GreatTree. // Hurr"
    dw $FFFF  ; END

Bank0C_ScriptAddr_521F:
    dw $083D  ; Text $083D: "Steps of My Baby Part 4 I guess I've for"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script06
; ---------------------------------------------------------------------------
Castle_Script06:
    dw $083B  ; Text $083B: "Just kidding! You're still a kid! // My "
    dw $FF2C  ; CheckInvFull
    dw Bank0C_ScriptAddr_5231          ; -> branch target
    dw $083E  ; Text $083E: "Steps of My Baby Part 5 I came up with m"
    dw $FF2A  ; GiveItem
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5231:
    dw $083D  ; Text $083D: "Steps of My Baby Part 4 I guess I've for"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script07
; ---------------------------------------------------------------------------
Castle_Script07:
    dw $0840
    dw $FF33  ; Cmd33
    dw $2710
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script08
; ---------------------------------------------------------------------------
Castle_Script08:
    dw $0841
    dw $FF05  ; TriggerBattle
    dw $01E0  ; Text $01E0: "This is the room of Memories Bewilder. G"
    dw $FF27  ; Cmd27
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script09
; ---------------------------------------------------------------------------
Castle_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5273          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_526F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_525D          ; -> branch target
    dw $0023  ; Text $0023: "[HERO] looked at the bookshelf. The King"
    dw $FFFF  ; END

Bank0C_ScriptAddr_525D:
    dw $01E4  ; Text $01E4: "We're the hosts. You have to win! // The"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $526B
    dw $01E6  ; Text $01E6: "Want to learn about breeding monsters? ["
    dw $FFFF  ; END

    db $E5
    db $01
    db $FF
    db $FF
Bank0C_ScriptAddr_526F:
    dw $040F  ; Text $040F: "You, must obey my command. I want to see"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5273:
    dw $05BB
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script10
; ---------------------------------------------------------------------------
Castle_Script10:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_52CD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0118  ; Text $0118: "I bet you wanna know. // You can meet he"
    dw Bank0C_ScriptAddr_52C9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_52AF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_529D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw Bank0C_ScriptAddr_5299          ; -> branch target
    dw $0022  ; Text $0022: "I have a feeling that your victory will "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5299:
    dw $0053  ; Text $0053: "You will find items scattered around in "
    dw $FFFF  ; END

Bank0C_ScriptAddr_529D:
    dw $01E7  ; Text $01E7: "Victories in the arena will allow you to"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $52AB
    dw $01E9  ; Text $01E9: "Congratulation on surviving E class. The"
    dw $FFFF  ; END

    db $E8
    db $01
    db $FF
    db $FF
Bank0C_ScriptAddr_52AF:
    dw $040B  ; Text $040B: "If you don't want to know, that's fine. "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $52C1
    dw $040C  ; Text $040C: "Don't pick on me! // Ha ha ha! I made Gi"
    dw $FF03  ; SetEventFlag
    dw $0118  ; Text $0118: "I bet you wanna know. // You can meet he"
    dw $FFFF  ; END

    db $0D
    db $04
    db $03
    db $FF
    db $18
    db $01
    db $FF
    db $FF
Bank0C_ScriptAddr_52C9:
    dw $040E  ; Text $040E: "I can see.. I can see! It's a never befo"
    dw $FFFF  ; END

Bank0C_ScriptAddr_52CD:
    dw $05BA
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script11
; ---------------------------------------------------------------------------
Castle_Script11:
    dw $002A  ; Text $002A: "My kingdom has been losing in the Starry"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script12
; ---------------------------------------------------------------------------
Castle_Script12:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_52FD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_52F9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_52F5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw Bank0C_ScriptAddr_52F1          ; -> branch target
    dw $002F  ; Text $002F: "Pulio from the farm is goofy but a very "
    dw $FFFF  ; END

Bank0C_ScriptAddr_52F1:
    dw $004F  ; Text $004F: "PulioSorry [HERO], It's my fault... Puli"
    dw $FFFF  ; END

Bank0C_ScriptAddr_52F5:
    dw $01F5  ; Text $01F5: "You are at the castle of GreatTree. To g"
    dw $FFFF  ; END

Bank0C_ScriptAddr_52F9:
    dw $048C  ; Text $048C: "You're at the castle of GreatTree. Good "
    dw $FFFF  ; END

Bank0C_ScriptAddr_52FD:
    dw $05C1
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script13
; ---------------------------------------------------------------------------
Castle_Script13:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_54CD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00AC
    dw Bank0C_ScriptAddr_54BB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_54B3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_54A1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "[HERO] read the sign. When the GreatTree"
    dw Bank0C_ScriptAddr_5473          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_5445          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "No! You'll be hurt if you fall. // If it"
    dw Bank0C_ScriptAddr_5417          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_53E9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "[HERO] read the sign. Danger, Don't rush"
    dw Bank0C_ScriptAddr_53E5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_53B7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "Watabou brings us capable masters. Hmm. "
    dw Bank0C_ScriptAddr_5389          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw Bank0C_ScriptAddr_5369          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw Bank0C_ScriptAddr_5357          ; -> branch target
    dw $002C  ; Text $002C: "Should I repeat the legend of the Starry"
    dw $FF03  ; SetEventFlag
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5357:
    dw $002D  ; Text $002D: "Here it is again. The Starry Night comes"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5365
    dw $002E  ; Text $002E: "The tournament is held on the Starry Nig"
    dw $FFFF  ; END

    db $1A
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_5369:
    dw $0152  ; Text $0152: "The Gate is shut tight. // The Gate is s"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5381
    dw $0154  ; Text $0154: "The Gate is shut tight. // [HERO] looked"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5385
    dw $0155  ; Text $0155: "[HERO] looked into the barrel. Something"
    dw $FFFF  ; END

    db $53
    db $01
    db $FF
    db $FF
    db $56
    db $01
    db $FF
    db $FF
Bank0C_ScriptAddr_5389:
    dw $01A5  ; Text $01A5: "My years of research lead me to believe "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $53AB
    dw $01A7  ; Text $01A7: "A monster is living deep in a cave. The "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $53AF
    dw $01A9  ; Text $01A9: "The devil settled in a town of ruins. As"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $53B3
    dw $0155  ; Text $0155: "[HERO] looked into the barrel. Something"
    dw $FFFF  ; END

    db $A6
    db $01
    db $FF
    db $FF
    db $A8
    db $01
    db $FF
    db $FF
    db $AA
    db $01
    db $FF
    db $FF
Bank0C_ScriptAddr_53B7:
    dw $01EC  ; Text $01EC: "Despair is a part of hope! Hope is embed"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $53D9
    dw $01EE  ; Text $01EE: "Discretion is the better part of valor. "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $53DD
    dw $01A9  ; Text $01A9: "The devil settled in a town of ruins. As"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $53E1
    dw $0155  ; Text $0155: "[HERO] looked into the barrel. Something"
    dw $FFFF  ; END

    db $ED
    db $01
    db $FF
    db $FF
    db $EF
    db $01
    db $FF
    db $FF
    db $F1
    db $01
    db $FF
    db $FF
Bank0C_ScriptAddr_53E5:
    dw $0274  ; Text $0274: "King[HERO]! Its okay to go to other Trav"
    dw $FFFF  ; END

Bank0C_ScriptAddr_53E9:
    dw $02B0  ; Text $02B0: "The victor made countless eggs vanish in"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $540B
    dw $02B2  ; Text $02B2: "I looked back and the stone statue was n"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $540F
    dw $01A9  ; Text $01A9: "The devil settled in a town of ruins. As"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5413
    dw $0155  ; Text $0155: "[HERO] looked into the barrel. Something"
    dw $FFFF  ; END

    db $B1
    db $02
    db $FF
    db $FF
    db $B3
    db $02
    db $FF
    db $FF
    db $B5
    db $02
    db $FF
    db $FF
Bank0C_ScriptAddr_5417:
    dw $0332  ; Text $0332: "If you want to meet the Dragon, you shou"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5439
    dw $0334  ; Text $0334: "A bird spins a round on the stage. It is"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $543D
    dw $01A9  ; Text $01A9: "The devil settled in a town of ruins. As"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5441
    dw $0155  ; Text $0155: "[HERO] looked into the barrel. Something"
    dw $FFFF  ; END

    db $33
    db $03
    db $FF
    db $FF
    db $35
    db $03
    db $FF
    db $FF
    db $36
    db $03
    db $FF
    db $FF
Bank0C_ScriptAddr_5445:
    dw $0361  ; Text $0361: "In the kingdom I visited, there was a mo"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5467
    dw $0363  ; Text $0363: "The legend of the village of Lifecod. Th"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $546B
    dw $01A9  ; Text $01A9: "The devil settled in a town of ruins. As"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $546F
    dw $0155  ; Text $0155: "[HERO] looked into the barrel. Something"
    dw $FFFF  ; END

    db $62
    db $03
    db $FF
    db $FF
    db $64
    db $03
    db $FF
    db $FF
    db $65
    db $03
    db $FF
    db $FF
Bank0C_ScriptAddr_5473:
    dw $03E0  ; Text $03E0: "A quote from the journal of a journey by"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5495
    dw $03E2  ; Text $03E2: "A quote from the first victor of the tou"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5499
    dw $01A9  ; Text $01A9: "The devil settled in a town of ruins. As"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $549D
    dw $0155  ; Text $0155: "[HERO] looked into the barrel. Something"
    dw $FFFF  ; END

    db $E1
    db $03
    db $FF
    db $FF
    db $E3
    db $03
    db $FF
    db $FF
    db $E4
    db $03
    db $FF
    db $FF
Bank0C_ScriptAddr_54A1:
    dw $0419  ; Text $0419: "Do you know of the Gate of Judgment? [Y/"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $54AF
    dw $041B  ; Text $041B: "Far across the ocean, is the country of "
    dw $FFFF  ; END

    db $1A
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_54B3:
    dw $048A  ; Text $048A: "Oh bless Starry Night and Master [HERO]!"
    dw $FF03  ; SetEventFlag
    dw $00AC
    dw $FFFF  ; END

Bank0C_ScriptAddr_54BB:
    dw $002D  ; Text $002D: "Here it is again. The Starry Night comes"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $54C9
    dw $002E  ; Text $002E: "The tournament is held on the Starry Nig"
    dw $FFFF  ; END

    db $8B
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_54CD:
    dw $05BE
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $54DB
    dw $05BF
    dw $FFFF  ; END

    db $C0
    db $05
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Castle_Script14
; ---------------------------------------------------------------------------
Castle_Script14:
    dw $FF00  ; BranchIfFlagClear
    dw $002F  ; Text $002F: "Pulio from the farm is goofy but a very "
    dw Bank0C_ScriptAddr_54EB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0111  ; Text $0111: "Select your choice by stepping on the pa"
    dw Bank0C_ScriptAddr_5567          ; -> branch target
Bank0C_ScriptAddr_54EB:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5563          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_555F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_555B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_5557          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_5553          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "[HERO] read the sign. Danger, Don't rush"
    dw Bank0C_ScriptAddr_554F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0049  ; Text $0049: "KingWhat? [HERO]! You have something to "
    dw Bank0C_ScriptAddr_554B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_5547          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "Watabou brings us capable masters. Hmm. "
    dw Bank0C_ScriptAddr_5543          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw Bank0C_ScriptAddr_553F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw Bank0C_ScriptAddr_553B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw Bank0C_ScriptAddr_5537          ; -> branch target
    dw $002B  ; Text $002B: "Let me tell you about the legend of the "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5537:
    dw $004D  ; Text $004D: "Give the courageous master [HERO] the po"
    dw $FFFF  ; END

Bank0C_ScriptAddr_553B:
    dw $005E  ; Text $005E: "These stairs go up to the monster farm. "
    dw $FFFF  ; END

Bank0C_ScriptAddr_553F:
    dw $014C  ; Text $014C: "Great! Go to the room above then. // We "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5543:
    dw $01A4  ; Text $01A4: "Are you familiar with the Gate of Bewild"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5547:
    dw $01EA  ; Text $01EA: "[HERO]! Doing good huh? The Room of Peac"
    dw $FFFF  ; END

Bank0C_ScriptAddr_554B:
    dw $01EB  ; Text $01EB: "Are you familiar with the Gate of Braver"
    dw $FFFF  ; END

Bank0C_ScriptAddr_554F:
    dw $0273  ; Text $0273: "The number of monsters is increasing. Wh"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5553:
    dw $02AF  ; Text $02AF: "Are you familiar with the Gate of Anger?"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5557:
    dw $0360  ; Text $0360: "Do you know of the Gate of Happiness? [Y"
    dw $FFFF  ; END

Bank0C_ScriptAddr_555B:
    dw $0418  ; Text $0418: "A quote from the journal of a journey by"
    dw $FFFF  ; END

Bank0C_ScriptAddr_555F:
    dw $0489  ; Text $0489: "Let me tell you the legend of the Starry"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5563:
    dw $05BC
    dw $FFFF  ; END

Bank0C_ScriptAddr_5567:
    dw $05BD
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script15
; ---------------------------------------------------------------------------
Castle_Script15:
    dw $0050  ; Text $0050: "These stairs bring you to the Chamber of"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script16
; ---------------------------------------------------------------------------
Castle_Script16:
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw Bank0C_ScriptAddr_5583          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw Bank0C_ScriptAddr_557F          ; -> branch target
    dw $0016  ; Text $0016: "Please listen to his wish. // This is th"
    dw $FFFF  ; END

Bank0C_ScriptAddr_557F:
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5583:
    dw $0051  ; Text $0051: "Please bring Hale back as soon as possib"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script17
; ---------------------------------------------------------------------------
Castle_Script17:
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw Bank0C_ScriptAddr_55A5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw Bank0C_ScriptAddr_55A1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw Bank0C_ScriptAddr_559D          ; -> branch target
    dw $0017  ; Text $0017: "This is the castle of GreatTree. // Hurr"
    dw $FFFF  ; END

Bank0C_ScriptAddr_559D:
    dw $0031  ; Text $0031: "Watabou brings us capable masters. Hmm. "
    dw $FFFF  ; END

Bank0C_ScriptAddr_55A1:
    dw $0052  ; Text $0052: "When you enter the Travelers' Gates, you"
    dw $FFFF  ; END

Bank0C_ScriptAddr_55A5:
    dw $005F  ; Text $005F: "This is the castle of GreatTree. For the"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script18
; ---------------------------------------------------------------------------
Castle_Script18:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_55E5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_55E1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "No! You'll be hurt if you fall. // If it"
    dw Bank0C_ScriptAddr_55DD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_55D9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_55D5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw Bank0C_ScriptAddr_55D1          ; -> branch target
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_55D1:
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_55D5:
    dw $01F6  ; Text $01F6: "Wishing upon the stars on Starry Night, "
    dw $FFFF  ; END

Bank0C_ScriptAddr_55D9:
    dw $02B9  ; Text $02B9: "A long time ago, the ancestor of Watabou"
    dw $FFFF  ; END

Bank0C_ScriptAddr_55DD:
    dw $0857
    dw $FFFF  ; END

Bank0C_ScriptAddr_55E1:
    dw $048D  ; Text $048D: "Good luck at the Starry Night Tournament"
    dw $FFFF  ; END

Bank0C_ScriptAddr_55E5:
    dw $05CF
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script19
; ---------------------------------------------------------------------------
Castle_Script19:
    dw $0851
    dw $FF2C  ; CheckInvFull
    dw Bank0C_ScriptAddr_55F7          ; -> branch target
    dw $084B
    dw $FF2A  ; GiveItem
    dw $001E  ; Text $001E: "This is the Kingdom of GreatTree! // Wel"
    dw $FFFF  ; END

Bank0C_ScriptAddr_55F7:
    dw $084C
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree Per-Script Table (map_type=$01, 21 scripts)
; ---------------------------------------------------------------------------
GreatTree_ScriptPtrTable:
    dw GreatTree_Script00              ; script 0
    dw GreatTree_Script01              ; script 1
    dw GreatTree_Script02              ; script 2
    dw GreatTree_Script03              ; script 3
    dw GreatTree_Script04              ; script 4
    dw GreatTree_Script05              ; script 5
    dw GreatTree_Script06              ; script 6
    dw GreatTree_Script07              ; script 7
    dw GreatTree_Script08              ; script 8
    dw GreatTree_Script09              ; script 9
    dw GreatTree_Script10              ; script 10
    dw GreatTree_Script11              ; script 11
    dw GreatTree_Script12              ; script 12
    dw GreatTree_Script13              ; script 13
    dw GreatTree_Script14              ; script 14
    dw GreatTree_Script15              ; script 15
    dw GreatTree_Script16              ; script 16
    dw GreatTree_Script17              ; script 17
    dw GreatTree_Script18              ; script 18
    dw GreatTree_Script19              ; script 19
    dw GreatTree_Script20              ; script 20
; ---------------------------------------------------------------------------
; GreatTree_Script00
; ---------------------------------------------------------------------------
GreatTree_Script00:
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $00FF  ; Text $00FF: "My rival's watching me from somewhere..."
    dw Bank0C_ScriptAddr_5641          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0C_ScriptAddr_5799          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_5847          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw Bank0C_ScriptAddr_587F          ; -> branch target
    dw $FFFF  ; END

Bank0C_ScriptAddr_5641:
    dw $FF0E  ; SetMapTransition
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw $565B
    dw $FF0E  ; SetMapTransition
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $56BD
    dw $FF0E  ; SetMapTransition
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $56D7
    dw $FF0E  ; SetMapTransition
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $5737
    dw $FFFF  ; END

    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $08
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $01
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $07
    db $FF
    db $10
    db $00
    db $06
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $1A
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $1A
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $A0
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $A0
    db $FF
    db $19
    db $FF
    db $0F
    db $FF
    db $01
    db $00
    db $28
    db $00
    db $78
    db $01
    db $FF
    db $FF
    db $08
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $80
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $80
    db $FF
    db $19
    db $FF
    db $0F
    db $FF
    db $01
    db $00
    db $28
    db $00
    db $F8
    db $00
    db $FF
    db $FF
    db $08
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $E0
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $E0
    db $FF
    db $19
    db $FF
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $00
    db $00
    db $0B
    db $FF
    db $03
    db $00
    db $10
    db $00
    db $0A
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $07
    db $FF
    db $11
    db $00
    db $06
    db $FF
    db $4A
    db $FF
    db $01
    db $00
    db $07
    db $FF
    db $12
    db $00
    db $06
    db $FF
    db $0B
    db $FF
    db $03
    db $00
    db $10
    db $00
    db $49
    db $FF
    db $03
    db $00
    db $4A
    db $FF
    db $00
    db $00
    db $07
    db $FF
    db $13
    db $00
    db $06
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $90
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $19
    db $FF
    db $0F
    db $FF
    db $01
    db $00
    db $28
    db $00
    db $78
    db $00
    db $FF
    db $FF
    db $08
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $10
    db $00
    db $1B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $20
    db $00
    db $1A
    db $FF
    db $00
    db $00
    db $20
    db $00
    db $19
    db $FF
    db $49
    db $FF
    db $01
    db $00
    db $07
    db $FF
    db $14
    db $00
    db $06
    db $FF
    db $47
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $21
    db $FF
    db $51
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $40
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $0F
    db $FF
    db $00
    db $00
    db $E8
    db $00
    db $F8
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_5799:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw $57B7
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "Gwrr, Gwrr... // In the back, they teach"
    dw $57D9
    dw $FF01  ; BranchIfFlagSet
    dw $000A  ; Text $000A: "Terry looks at the bookshelf. Encycloped"
    dw $57B7
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw $57B9
    dw $FF01  ; BranchIfFlagSet
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $57B7
    dw $FFFF  ; END

    db $08
    db $FF
    db $07
    db $FF
    db $61
    db $00
    db $21
    db $FF
    db $55
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $40
    db $00
    db $19
    db $FF
    db $03
    db $FF
    db $0A
    db $00
    db $12
    db $FF
    db $2D
    db $D9
    db $03
    db $00
    db $FF
    db $FF
    db $08
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $10
    db $00
    db $1B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $20
    db $00
    db $1A
    db $FF
    db $00
    db $00
    db $20
    db $00
    db $19
    db $FF
    db $49
    db $FF
    db $01
    db $00
    db $07
    db $FF
    db $14
    db $00
    db $06
    db $FF
    db $47
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $21
    db $FF
    db $51
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $40
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $12
    db $FF
    db $2C
    db $D9
    db $00
    db $00
    db $12
    db $FF
    db $2D
    db $D9
    db $03
    db $00
    db $0F
    db $FF
    db $00
    db $00
    db $E8
    db $00
    db $F8
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_5847:
    dw $FF01  ; BranchIfFlagSet
    dw $0021  ; Text $0021: "Everybody will be happy if you become th"
    dw $5865
    dw $FF00  ; BranchIfFlagClear
    dw $011E  ; Text $011E: "[HERO] looked into the jar. An old lady'"
    dw $5859
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "Gwrr, Gwrr... // In the back, they teach"
    dw $5873
    dw $FF01  ; BranchIfFlagSet
    dw $0043  ; Text $0043: "You are at the monster farm. // KingOh, "
    dw $5865
    dw $FF01  ; BranchIfFlagSet
    dw $011E  ; Text $011E: "[HERO] looked into the jar. An old lady'"
    dw $5867
    dw $FFFF  ; END

    db $12
    db $FF
    db $5E
    db $D9
    db $01
    db $00
    db $03
    db $FF
    db $43
    db $00
    db $FF
    db $FF
    db $12
    db $FF
    db $5E
    db $D9
    db $04
    db $00
    db $03
    db $FF
    db $43
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_587F:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw $588B
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "Gwrr, Gwrr... // In the back, they teach"
    dw $588D
    dw $FFFF  ; END

    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $08
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $12
    db $FF
    db $8A
    db $C8
    db $03
    db $00
    db $12
    db $FF
    db $8B
    db $C8
    db $03
    db $00
    db $3E
    db $FF
    db $08
    db $FF
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $08
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $01
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $07
    db $FF
    db $B6
    db $05
    db $06
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $1A
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $1A
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $A0
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $A0
    db $FF
    db $19
    db $FF
    db $12
    db $FF
    db $33
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $2D
    db $D9
    db $04
    db $00
    db $0F
    db $FF
    db $01
    db $00
    db $28
    db $00
    db $78
    db $00
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; GreatTree_Script01
; ---------------------------------------------------------------------------
GreatTree_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw Bank0C_ScriptAddr_5927          ; -> branch target
    dw $0019  ; Text $0019: "I see..... // [HERO] opened a treasure c"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5927:
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script02
; ---------------------------------------------------------------------------
GreatTree_Script02:
    dw $001F  ; Text $001F: "Welcome! I am the King of this kingdom. "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script03
; ---------------------------------------------------------------------------
GreatTree_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_596F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $009B
    dw Bank0C_ScriptAddr_596B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_5963          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_595F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_595B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_5957          ; -> branch target
    dw $012F  ; Text $012F: "I am Medal Man, the medal collector. // "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5957:
    dw $01F7  ; Text $01F7: "GreatLog is the closest country to Great"
    dw $FFFF  ; END

Bank0C_ScriptAddr_595B:
    dw $02BA  ; Text $02BA: "I often see the girl who stood in the wa"
    dw $FFFF  ; END

Bank0C_ScriptAddr_595F:
    dw $036B  ; Text $036B: "Hey, the tournament is coming! Good Luck"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5963:
    dw $041C  ; Text $041C: "KingOh, [HERO]! You beat DarkHorn! KingY"
    dw $FF03  ; SetEventFlag
    dw $009B
    dw $FFFF  ; END

Bank0C_ScriptAddr_596B:
    dw $041D  ; Text $041D: "KingOh, [HERO]! You beat Akubar! KingIt'"
    dw $FFFF  ; END

Bank0C_ScriptAddr_596F:
    dw $05D0
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script04
; ---------------------------------------------------------------------------
GreatTree_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5987          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_5983          ; -> branch target
    dw $0062  ; Text $0062: "Fhew! I'm glad that I didn't get hurt! I"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5983:
    dw $048E  ; Text $048E: "You don't have it? You should be able to"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5987:
    dw $05D1
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script05
; ---------------------------------------------------------------------------
GreatTree_Script05:
    dw $0063  ; Text $0063: "Oh [HERO], it's you. I am getting old. J"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script06
; ---------------------------------------------------------------------------
GreatTree_Script06:
    dw $0064  ; Text $0064: "Once I picked up a TinyMedal, back when "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script07
; ---------------------------------------------------------------------------
GreatTree_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_59C9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $009C  ; Text $009C: "Warubou? I'm not Warubou. I am Watabou! "
    dw Bank0C_ScriptAddr_59C5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_59BD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_59B9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_59B5          ; -> branch target
    dw $01AF  ; Text $01AF: "I want you to win the tournament this ti"
    dw $FFFF  ; END

Bank0C_ScriptAddr_59B5:
    dw $02BB  ; Text $02BB: "The Kingdom of DeadTree is almost dead. "
    dw $FFFF  ; END

Bank0C_ScriptAddr_59B9:
    dw $036C  ; Text $036C: "One of my relatives is living in the kin"
    dw $FFFF  ; END

Bank0C_ScriptAddr_59BD:
    dw $041E  ; Text $041E: "Hey are you really aiming for S class? ["
    dw $FF03  ; SetEventFlag
    dw $009C  ; Text $009C: "Warubou? I'm not Warubou. I am Watabou! "
    dw $FFFF  ; END

Bank0C_ScriptAddr_59C5:
    dw $041F  ; Text $041F: "You'll never get there with such patheti"
    dw $FFFF  ; END

Bank0C_ScriptAddr_59C9:
    dw $05D2
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script08
; ---------------------------------------------------------------------------
GreatTree_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5A19          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_5A07          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $000B  ; Text $000B: "Terry looked at the bookshelf. Too diffi"
    dw Bank0C_ScriptAddr_59F5          ; -> branch target
    dw $012B  ; Text $012B: "..... // What the heck is an onigiri? Wh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_59F1          ; -> branch target
    dw $012D  ; Text $012D: "We all gather here seeking victory. The "
    dw $FF03  ; SetEventFlag
    dw $000B  ; Text $000B: "Terry looked at the bookshelf. Too diffi"
    dw $FFFF  ; END

Bank0C_ScriptAddr_59F1:
    dw $012C  ; Text $012C: "What the heck is an onigiri? Why can't y"
    dw $FFFF  ; END

Bank0C_ScriptAddr_59F5:
    dw $012B  ; Text $012B: "..... // What the heck is an onigiri? Wh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5A03
    dw $012E  ; Text $012E: "Oh, welcome Mas...ahem. I am the Medal M"
    dw $FFFF  ; END

    db $2C
    db $01
    db $FF
    db $FF
Bank0C_ScriptAddr_5A07:
    dw $012B  ; Text $012B: "..... // What the heck is an onigiri? Wh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5A15
    dw $0490  ; Text $0490: "Many people are heading to GreatTree. Th"
    dw $FFFF  ; END

    db $8F
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_5A19:
    dw $05D3
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5A27
    dw $05D4
    dw $FFFF  ; END

    db $D5
    db $05
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; GreatTree_Script09
; ---------------------------------------------------------------------------
GreatTree_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5A67          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_5A63          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_5A5F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_5A5B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_5A57          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_5A53          ; -> branch target
    dw $0065  ; Text $0065: "Would you like to see the list of Travel"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A53:
    dw $01F8  ; Text $01F8: "You've been babied forever! Can someone "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A57:
    dw $02BC  ; Text $02BC: "I want us to win this time! The Stars wi"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A5B:
    dw $036D  ; Text $036D: "To tell the truth, Watabou hasn't brough"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A5F:
    dw $0420  ; Text $0420: "Then go home, liar! // You're in the Cha"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A63:
    dw $0491  ; Text $0491: "Watabou will be happy if you win! It say"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A67:
    dw $05D6
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script10
; ---------------------------------------------------------------------------
GreatTree_Script10:
    dw $0157  ; Text $0157: "Wow,a TinyMedal! But cannot carry any mo"
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script11
; ---------------------------------------------------------------------------
GreatTree_Script11:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5A87          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_5A83          ; -> branch target
    dw $0159  ; Text $0159: "[HERO] looked into the barrel. A monster"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A83:
    dw $0492  ; Text $0492: "You can win! ...I feel it! I heard a wis"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A87:
    dw $05D7  ; Text $05D7: "But the Mimic isn't doing anything but l"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script12
; ---------------------------------------------------------------------------
GreatTree_Script12:
    dw $0158  ; Text $0158: "[HERO] looked into the barrel. Nothing i"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script13
; ---------------------------------------------------------------------------
GreatTree_Script13:
    dw $FF01  ; BranchIfFlagSet
    dw $0114  ; Text $0114: "It's a tie... In this case... I win anyw"
    dw Bank0C_ScriptAddr_5ACF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5AC7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_5AC3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_5ABF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_5ABB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_5AB7          ; -> branch target
    dw $01B0  ; Text $01B0: "I heard you got stronger. But I still do"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5AB7:
    dw $02BD  ; Text $02BD: "Right to the Bazaar! There are new store"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5ABB:
    dw $036E  ; Text $036E: "Bazaar to the right! A third store has o"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5ABF:
    dw $0421  ; Text $0421: "You're in the Chamber of Travelers' Gate"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5AC3:
    dw $0493  ; Text $0493: "Proceed to the Vault. Good luck! // Go r"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5AC7:
    dw $05D8
    dw $FF03  ; SetEventFlag
    dw $0114  ; Text $0114: "It's a tie... In this case... I win anyw"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5ACF:
    dw $084F
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script14
; ---------------------------------------------------------------------------
GreatTree_Script14:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5AE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_5AE3          ; -> branch target
    dw $015A  ; Text $015A: "[HERO] looked in the treasure chest It w"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5AE3:
    dw $0494  ; Text $0494: "Go right to the Bazaar! It's [HERO]! I'l"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5AE7:
    dw $05D9
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script15
; ---------------------------------------------------------------------------
GreatTree_Script15:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5B2B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00AD  ; Text $00AD: "see..... // [HERO] opened a treasure che"
    dw Bank0C_ScriptAddr_5B27          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_5B1F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_5B1B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_5B17          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_5B13          ; -> branch target
    dw $015B  ; Text $015B: "Have you been using the Bookmark? It's v"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B13:
    dw $02BE  ; Text $02BE: "D... Do ya know there was a big quake? ["
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B17:
    dw $036F  ; Text $036F: "You'll always be a loser! What's wrong w"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B1B:
    dw $0422  ; Text $0422: "Behind the Gate of Labyrinth there reall"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B1F:
    dw $0495  ; Text $0495: "Go right to the Bazaar! Oh [HERO]! I'll "
    dw $FF03  ; SetEventFlag
    dw $00AD  ; Text $00AD: "see..... // [HERO] opened a treasure che"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B27:
    dw $0496  ; Text $0496: "Are you... really competing in the tourn"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B2B:
    dw $05DA
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script16
; ---------------------------------------------------------------------------
GreatTree_Script16:
    dw $FF01  ; BranchIfFlagSet
    dw $002F  ; Text $002F: "Pulio from the farm is goofy but a very "
    dw Bank0C_ScriptAddr_5D8B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F4  ; Text $00F4: "Darn! Again! // I won! Challenge me anyt"
    dw Bank0C_ScriptAddr_5D87          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0107  ; Text $0107: "Eeek! What? Talk to me from the front! /"
    dw Bank0C_ScriptAddr_5D7F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0106  ; Text $0106: "The last battle in G class is with the p"
    dw Bank0C_ScriptAddr_5D7F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F3  ; Text $00F3: "Select your choice by stepping on the pa"
    dw Bank0C_ScriptAddr_5D7B          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $00F2  ; Text $00F2: "Hm, its not fun. // Select your choice b"
    dw Bank0C_ScriptAddr_5B59          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0105  ; Text $0105: "The battle classes go from S,A down to G"
    dw Bank0C_ScriptAddr_5C4B          ; -> branch target
Bank0C_ScriptAddr_5B59:
    dw $FF01  ; BranchIfFlagSet
    dw $00F2  ; Text $00F2: "Hm, its not fun. // Select your choice b"
    dw Bank0C_ScriptAddr_5C2B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5C23          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00AE  ; Text $00AE: "e monsters here. SlioBut the monsters wi"
    dw Bank0C_ScriptAddr_5C11          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_5BFB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_5BF3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "[HERO] read the sign. When the GreatTree"
    dw Bank0C_ScriptAddr_5BD9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_5BD1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "No! You'll be hurt if you fall. // If it"
    dw Bank0C_ScriptAddr_5BC9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_5BAF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "[HERO] read the sign. Danger, Don't rush"
    dw Bank0C_ScriptAddr_5BA7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_5B9F          ; -> branch target
    dw $01B1  ; Text $01B1: "Whew! At last we made it to the bottom. "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B9F:
    dw $01F9
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5BA7:
    dw $0277  ; Text $0277: "The Room of Strength Anger is in the mid"
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5BAF:
    dw $02BF
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5BC1
    dw $02C0
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FFFF  ; END

    db $C1
    db $02
    db $03
    db $FF
    db $80
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_5BC9:
    dw $033C  ; Text $033C: "Well done on surviving C class! Go left "
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5BD1:
    dw $0370  ; Text $0370: "Hey! Down the stairs is the Shrine of St"
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5BD9:
    dw $03E7  ; Text $03E7: "You'll never get there with such patheti"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5BEB
    dw $03E8  ; Text $03E8: "Then go home, liar! // You're in the Cha"
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FFFF  ; END

    db $E9
    db $03
    db $03
    db $FF
    db $80
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_5BF3:
    dw $0423  ; Text $0423: "DuckKite is a troublesome monster. It ma"
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5BFB:
    dw $0497  ; Text $0497: "...Don't lose. // ...Don't lose. Don't m"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5C0D
    dw $0498  ; Text $0498: "...Don't lose. Don't make me say it agai"
    dw $FF03  ; SetEventFlag
    dw $00AE  ; Text $00AE: "e monsters here. SlioBut the monsters wi"
    dw $FFFF  ; END

    db $9A
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_5C11:
    dw $0497  ; Text $0497: "...Don't lose. // ...Don't lose. Don't m"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5C1F
    dw $0499  ; Text $0499: "You're right! It's impossible for you to"
    dw $FFFF  ; END

    db $9B
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_5C23:
    dw $05DC
    dw $FF03  ; SetEventFlag
    dw $00F2  ; Text $00F2: "Hm, its not fun. // Select your choice b"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5C2B:
    dw $05DD  ; Text $05DD: "e you back the monster that fell in the "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5C43
    dw $05DF  ; Text $05DF: "o back to sleep. Sweet dreams! // Milayo"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5C47
    dw $05E1  ; Text $05E1: "I don't have such a name! Don't lie to m"
    dw $FFFF  ; END

    db $DE
    db $05
    db $FF
    db $FF
    db $E0
    db $05
    db $FF
    db $FF
Bank0C_ScriptAddr_5C4B:
    dw $05DD  ; Text $05DD: "e you back the monster that fell in the "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5D73
    dw $05DF  ; Text $05DF: "o back to sleep. Sweet dreams! // Milayo"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5D77
    dw $05E2  ; Text $05E2: "Yep. It's Santi. How did you know? Santi"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF1C  ; CompareRAM
    dw $0600  ; Text $0600: "Humpf, I don't need you! // I don't have"
    dw $FF19  ; FadeEffect
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $0027  ; Text $0027: "People who understand monster talk and a"
    dw $5CB5
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $0028  ; Text $0028: "I wanna be a master. What should I do? /"
    dw $5CB5
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $0029  ; Text $0029: "KingThe monster farm is on the upper lev"
    dw $5CB5
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF14  ; ClearGameFlags
    dw $5CDF
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFE0  ; Cmd$E0
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF19  ; FadeEffect
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $05E3  ; Text $05E3: "SantiWait here for me! // SantiTalk to m"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF21  ; TriggerBattle2
    dw $0051  ; Text $0051: "Please bring Hale back as soon as possib"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF09  ; SetDelay
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF21  ; TriggerBattle2
    dw $0051  ; Text $0051: "Please bring Hale back as soon as possib"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF07  ; InitDialogMode
    dw $05E4  ; Text $05E4: "SantiTalk to my Grandpa!! // SantiC'mon,"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFB0  ; Cmd$B0
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF03  ; SetEventFlag
    dw $00F3  ; Text $00F3: "Select your choice by stepping on the pa"
    dw $FFFF  ; END

    db $DE
    db $05
    db $FF
    db $FF
    db $E0
    db $05
    db $FF
    db $FF
Bank0C_ScriptAddr_5D7B:
    dw $05E5  ; Text $05E5: "SantiC'mon, go talk to my Grandpa! // Sa"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5D7F:
    dw $05E6  ; Text $05E6: "SantiYou talked to my Grandpa, right? Sa"
    dw $FF03  ; SetEventFlag
    dw $00F4  ; Text $00F4: "Darn! Again! // I won! Challenge me anyt"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5D87:
    dw $05E7  ; Text $05E7: "SantiDon't just stand there! Go to the T"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5D8B:
    dw $05E8  ; Text $05E8: "SantiWas the Travelers' Gate useful to y"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $5D99
    dw $05EA  ; Text $05EA: "SantiI...I'm... happy....blush. // Oh ou"
    dw $FFFF  ; END

    db $E9
    db $05
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; GreatTree_Script17
; ---------------------------------------------------------------------------
GreatTree_Script17:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5DCB          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_5DAF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0083
    dw Bank0C_ScriptAddr_5DC7          ; -> branch target
Bank0C_ScriptAddr_5DAF:
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_5DC3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_5DBF          ; -> branch target
    dw $01B2  ; Text $01B2: "Meet the old man of the Shrine of Starry"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5DBF:
    dw $02C2
    dw $FFFF  ; END

Bank0C_ScriptAddr_5DC3:
    dw $0371  ; Text $0371: "Welcome to the Bazaar! There are more st"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5DC7:
    dw $049C  ; Text $049C: "A surprise awaits you in your future! Hm"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5DCB:
    dw $05DB  ; Text $05DB: "s that seemed to draw you in. // ...... "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script18
; ---------------------------------------------------------------------------
GreatTree_Script18:
    dw $FF12  ; WriteRAM
    dw $D9E8  ; RAM $D9E8
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF19  ; FadeEffect
    dw $FF12  ; WriteRAM
    dw $C842  ; RAM $C842
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF12  ; WriteRAM
    dw $C846  ; RAM $C846
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script19
; ---------------------------------------------------------------------------
GreatTree_Script19:
    dw $FF12  ; WriteRAM
    dw $D9E8  ; RAM $D9E8
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF19  ; FadeEffect
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script20
; ---------------------------------------------------------------------------
GreatTree_Script20:
    dw $FF12  ; WriteRAM
    dw $D9E8  ; RAM $D9E8
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw $FF19  ; FadeEffect
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar Per-Script Table (map_type=$02, 25 scripts)
; ---------------------------------------------------------------------------
Bazaar_ScriptPtrTable:
    dw Bazaar_Script00                 ; script 0
    dw Bazaar_Script01                 ; script 1
    dw Bazaar_Script02                 ; script 2
    dw Bazaar_Script03                 ; script 3
    dw Bazaar_Script04                 ; script 4
    dw Bazaar_Script05                 ; script 5
    dw Bazaar_Script06                 ; script 6
    dw Bazaar_Script07                 ; script 7
    dw Bazaar_Script08                 ; script 8
    dw Bazaar_Script09                 ; script 9
    dw Bazaar_Script10                 ; script 10
    dw Bazaar_Script11                 ; script 11
    dw Bazaar_Script12                 ; script 12
    dw Bazaar_Script13                 ; script 13
    dw Bazaar_Script14                 ; script 14
    dw Bazaar_Script15                 ; script 15
    dw Bazaar_Script16                 ; script 16
    dw Bazaar_Script17                 ; script 17
    dw Bazaar_Script18                 ; script 18
    dw Bazaar_Script19                 ; script 19
    dw Bazaar_Script20                 ; script 20
    dw Bazaar_Script21                 ; script 21
    dw Bazaar_Script22                 ; script 22
    dw Bazaar_Script23                 ; script 23
    dw Bazaar_Script24                 ; script 24
; ---------------------------------------------------------------------------
; Bazaar_Script00
; ---------------------------------------------------------------------------
Bazaar_Script00:
    dw $FF0E  ; SetMapTransition
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_5E57          ; -> branch target
    dw $FFFF  ; END

Bank0C_ScriptAddr_5E57:
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw $5E8D
    dw $FF00  ; BranchIfFlagClear
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw $5E69
    dw $FF01  ; BranchIfFlagSet
    dw $004B  ; Text $004B: "KingI see. Now [HERO], proceed to the Tr"
    dw $5E8D
    dw $FF00  ; BranchIfFlagClear
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw $5E75
    dw $FF01  ; BranchIfFlagSet
    dw $004A  ; Text $004A: "PulioMajesty, Hale escaped through the T"
    dw $5E89
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw $5E8D
    dw $FF01  ; BranchIfFlagSet
    dw $004B  ; Text $004B: "KingI see. Now [HERO], proceed to the Tr"
    dw $5E8D
    dw $FF01  ; BranchIfFlagSet
    dw $004A  ; Text $004A: "PulioMajesty, Hale escaped through the T"
    dw $5E89
    dw $FFFF  ; END

    db $03
    db $FF
    db $4B
    db $00
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Bazaar_Script01
; ---------------------------------------------------------------------------
Bazaar_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $003F  ; Text $003F: "I'm Slio. I am the grandson of Grandpa S"
    dw Bank0C_ScriptAddr_5EAB          ; -> branch target
    dw $003A  ; Text $003A: "[HERO] looked into the jar. The jar is f"
    dw $FF2C  ; CheckInvFull
    dw Bank0C_ScriptAddr_5EA7          ; -> branch target
    dw $0129  ; Text $0129: "This is an llonigirill. C'mon BeBe, repe"
    dw $FF03  ; SetEventFlag
    dw $003F  ; Text $003F: "I'm Slio. I am the grandson of Grandpa S"
    dw $FF2A  ; GiveItem
    dw $001E  ; Text $001E: "This is the Kingdom of GreatTree! // Wel"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5EA7:
    dw $012A  ; Text $012A: "BeBeBoo Baa Boo Baa. // ..... // What th"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5EAB:
    dw $015D  ; Text $015D: "How many times do I have to say it?! I d"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script02
; ---------------------------------------------------------------------------
Bazaar_Script02:
    dw $015E  ; Text $015E: "KingWell done, [HERO]! You beat another "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script03
; ---------------------------------------------------------------------------
Bazaar_Script03:
    dw $015E  ; Text $015E: "KingWell done, [HERO]! You beat another "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script04
; ---------------------------------------------------------------------------
Bazaar_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $0115  ; Text $0115: "You! You're good! Look! I'll tell you ab"
    dw Bank0C_ScriptAddr_5ED9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5EE5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0112  ; Text $0112: "Darn! Again! // I won! Challenge me anyt"
    dw Bank0C_ScriptAddr_5ED9          ; -> branch target
    dw $0196
    dw $FF03  ; SetEventFlag
    dw $0112  ; Text $0112: "Darn! Again! // I won! Challenge me anyt"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0680  ; Text $0680: "MilayouCome back when you wanna breed. /"
    dw $0682  ; Text $0682: "MilayouWhich monster will you pick for m"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5ED9:
    dw $0680  ; Text $0680: "MilayouCome back when you wanna breed. /"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0680  ; Text $0680: "MilayouCome back when you wanna breed. /"
    dw $0682  ; Text $0682: "MilayouWhich monster will you pick for m"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5EE5:
    dw $024A  ; Text $024A: "[HERO] looked at the candle. Whoa! It's "
    dw $FF03  ; SetEventFlag
    dw $0115  ; Text $0115: "You! You're good! Look! I'll tell you ab"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0680  ; Text $0680: "MilayouCome back when you wanna breed. /"
    dw $0682  ; Text $0682: "MilayouWhich monster will you pick for m"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script05
; ---------------------------------------------------------------------------
Bazaar_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5F1D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_5F19          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_5F15          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_5F11          ; -> branch target
    dw $015C  ; Text $015C: "Uuu Hmm... I wonder who'll win this year"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F11:
    dw $02C3
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F15:
    dw $0372  ; Text $0372: "I love festivals! I'm looking forward to"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F19:
    dw $0424  ; Text $0424: "Copycopy. I wanna copycopy an Unicorn to"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F1D:
    dw $05EB  ; Text $05EB: "Oh our hero [HERO]! Welcome to the Bazaa"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script06
; ---------------------------------------------------------------------------
Bazaar_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_5F3F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_5F3B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_5F37          ; -> branch target
    dw $02C4
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F37:
    dw $0373  ; Text $0373: "This kingdom is becoming more lively. I "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F3B:
    dw $0425  ; Text $0425: "Hello! I am Helo. My former master wante"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F3F:
    dw $05EC  ; Text $05EC: "What a good feeling to be the winning ki"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script07
; ---------------------------------------------------------------------------
Bazaar_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_608F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_608B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_6087          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $004B  ; Text $004B: "KingI see. Now [HERO], proceed to the Tr"
    dw Bank0C_ScriptAddr_6083          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $004A  ; Text $004A: "PulioMajesty, Hale escaped through the T"
    dw Bank0C_ScriptAddr_607F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_5F6B          ; -> branch target
    dw $015F  ; Text $015F: "Oh...King... // KingTrain hard! You're d"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F6B:
    dw $01FA
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF07  ; InitDialogMode
    dw $01FB
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0305  ; Text $0305: "You don't seem to be a bad guy after all"
    dw $FF1C  ; CompareRAM
    dw $1503
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $00D7  ; Text $00D7: "ree... Want to read the book?[Y/N] // It"
    dw $5FD1
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $00D8
    dw $5FD1
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $00D9  ; Text $00D9: "g that your victory will help you find y"
    dw $5FD1
    dw $FF14  ; ClearGameFlags
    dw $5FD7
    dw $FF11  ; NPCAnimSetup
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0038  ; Text $0038: "Hey, Mr.Monster Master. I wonder what I "
    dw $FF10  ; NPCAnimStart
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00F8  ; Text $00F8: "You're good... // Want to know where the"
    dw $FF11  ; NPCAnimSetup
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0068  ; Text $0068: "Hey Master! Dn'a have an egg?[Y/N] // Sp"
    dw $FF0A  ; NPCMoveX
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FFF0  ; Cmd$F0
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF47  ; Cmd47
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $0054  ; Text $0054: "Hale was the cherished pet of the King. "
    dw $FF1D  ; LockMovement
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FFB0  ; Cmd$B0
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0404  ; Text $0404: "Behind the Gate of Villager, Stubsucks, "
    dw $FF1C  ; CompareRAM
    dw $1703
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF03  ; SetEventFlag
    dw $004A  ; Text $004A: "PulioMajesty, Hale escaped through the T"
    dw $FFFF  ; END

Bank0C_ScriptAddr_607F:
    dw $01FC
    dw $FFFF  ; END

Bank0C_ScriptAddr_6083:
    dw $01FD
    dw $FFFF  ; END

Bank0C_ScriptAddr_6087:
    dw $0374  ; Text $0374: "I heard that wishes on the Starry Night "
    dw $FFFF  ; END

Bank0C_ScriptAddr_608B:
    dw $0426  ; Text $0426: "Yeah! The Starry Night has arrived! That"
    dw $FFFF  ; END

Bank0C_ScriptAddr_608F:
    dw $05ED  ; Text $05ED: "La la la [HERO] and Milayou La la la... "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script08
; ---------------------------------------------------------------------------
Bazaar_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_60BB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_60B7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_60B3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $004B  ; Text $004B: "KingI see. Now [HERO], proceed to the Tr"
    dw Bank0C_ScriptAddr_60AF          ; -> branch target
    dw $0160  ; Text $0160: "KingTrain hard! You're dismissed. KingBu"
    dw $FFFF  ; END

Bank0C_ScriptAddr_60AF:
    dw $01FE
    dw $FFFF  ; END

Bank0C_ScriptAddr_60B3:
    dw $0375  ; Text $0375: "New stores have opened! Want to learn ab"
    dw $FFFF  ; END

Bank0C_ScriptAddr_60B7:
    dw $0427  ; Text $0427: "I wonder what will happen if I use Chanc"
    dw $FFFF  ; END

Bank0C_ScriptAddr_60BB:
    dw $05EE  ; Text $05EE: "I didn't think you could win... // Giggl"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script09
; ---------------------------------------------------------------------------
Bazaar_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_60FD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_60F9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0079
    dw Bank0C_ScriptAddr_60E7          ; -> branch target
    dw $02C5
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_60E3          ; -> branch target
    dw $02C6
    dw $FF03  ; SetEventFlag
    dw $0079
    dw $FFFF  ; END

Bank0C_ScriptAddr_60E3:
    dw $02C7
    dw $FFFF  ; END

Bank0C_ScriptAddr_60E7:
    dw $02C5
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $60F5
    dw $0029  ; Text $0029: "KingThe monster farm is on the upper lev"
    dw $FFFF  ; END

    db $C7
    db $02
    db $FF
    db $FF
Bank0C_ScriptAddr_60F9:
    dw $0428  ; Text $0428: "Well done! You survived S class! Now you"
    dw $FFFF  ; END

Bank0C_ScriptAddr_60FD:
    dw $05EF  ; Text $05EF: "Giggle giggle! Listen listen! I can be a"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script10
; ---------------------------------------------------------------------------
Bazaar_Script10:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6161          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_614F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $007A
    dw Bank0C_ScriptAddr_613D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_6127          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_6123          ; -> branch target
    dw $0161  ; Text $0161: "Empty // Thanks [HERO]! For bringing the"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6123:
    dw $01FF
    dw $FFFF  ; END

Bank0C_ScriptAddr_6127:
    dw $02C8
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6139
    dw $02CA
    dw $FF03  ; SetEventFlag
    dw $007A
    dw $FFFF  ; END

    db $C9
    db $02
    db $FF
    db $FF
Bank0C_ScriptAddr_613D:
    dw $02CB
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $614B
    dw $02CA
    dw $FFFF  ; END

    db $C9
    db $02
    db $FF
    db $FF
Bank0C_ScriptAddr_614F:
    dw $0429  ; Text $0429: "Monster Master [HERO]! You became our re"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $615D
    dw $02CA
    dw $FFFF  ; END

    db $2A
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_6161:
    dw $05F0  ; Text $05F0: "Well well, Congratulations!! I love fest"
    dw $FFFF  ; END

    db $F1
    db $05
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Bazaar_Script11
; ---------------------------------------------------------------------------
Bazaar_Script11:
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
; ---------------------------------------------------------------------------
; Bazaar_Script12
; ---------------------------------------------------------------------------
Bazaar_Script12:
    dw $0680  ; Text $0680: "MilayouCome back when you wanna breed. /"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0680  ; Text $0680: "MilayouCome back when you wanna breed. /"
    dw $0682  ; Text $0682: "MilayouWhich monster will you pick for m"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script13
; ---------------------------------------------------------------------------
Bazaar_Script13:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6191          ; -> branch target
    dw $042B  ; Text $042B: "[HERO], nothing left but S class. I'll h"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_618D          ; -> branch target
    dw $042D  ; Text $042D: "There are cliffs that you can jump down."
    dw $FFFF  ; END

Bank0C_ScriptAddr_618D:
    dw $042C  ; Text $042C: "Tut! Not in here either! // There are cl"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6191:
    dw $05F2  ; Text $05F2: "Hi! How about a reward for your victory?"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $619F
    dw $05F4  ; Text $05F4: "...tickle ...tickle, tickle tickle, tick"
    dw $FFFF  ; END

    db $F3
    db $05
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Bazaar_Script14
; ---------------------------------------------------------------------------
Bazaar_Script14:
    dw $FF01  ; BranchIfFlagSet
    dw $009D
    dw Bank0C_ScriptAddr_61CD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_61BD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_61B9          ; -> branch target
    dw $0163  ; Text $0163: "I found it! A big trial's waiting for ya"
    dw $FFFF  ; END

Bank0C_ScriptAddr_61B9:
    dw $0200  ; Text $0200: "[HERO] looked at the bookshelf. My resea"
    dw $FFFF  ; END

Bank0C_ScriptAddr_61BD:
    dw $042F  ; Text $042F: "You, listen to my request. I want to see"
    dw $FF03  ; SetEventFlag
    dw $009D
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0680  ; Text $0680: "MilayouCome back when you wanna breed. /"
    dw $0682  ; Text $0682: "MilayouWhich monster will you pick for m"
    dw $FFFF  ; END

Bank0C_ScriptAddr_61CD:
    dw $0680  ; Text $0680: "MilayouCome back when you wanna breed. /"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0680  ; Text $0680: "MilayouCome back when you wanna breed. /"
    dw $0682  ; Text $0682: "MilayouWhich monster will you pick for m"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script15
; ---------------------------------------------------------------------------
Bazaar_Script15:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6223          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_6215          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_6203          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_61FF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_61FB          ; -> branch target
    dw $0162  ; Text $0162: "Thanks [HERO]! For bringing the medals! "
    dw $FFFF  ; END

Bank0C_ScriptAddr_61FB:
    dw $0201  ; Text $0201: "[HERO] looked at the bookshelf. The secr"
    dw $FFFF  ; END

Bank0C_ScriptAddr_61FF:
    dw $02CC
    dw $FFFF  ; END

Bank0C_ScriptAddr_6203:
    dw $042E  ; Text $042E: "When a monster learns two certain skills"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6211
    dw $0383  ; Text $0383: "My parents' ancestors were bred a lot. T"
    dw $FFFF  ; END

    db $A4
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_6215:
    dw $03EF  ; Text $03EF: "I wonder what will happen if I use Chanc"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6211
    dw $0383  ; Text $0383: "My parents' ancestors were bred a lot. T"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6223:
    dw $05F5  ; Text $05F5: "Oh, what a joy! [HERO] won! That merchan"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6211
    dw $0383  ; Text $0383: "My parents' ancestors were bred a lot. T"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script16
; ---------------------------------------------------------------------------
Bazaar_Script16:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6291          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_627F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_626D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_625B          ; -> branch target
    dw $0164  ; Text $0164: "WatabouRight on! [HERO]! I'll take you b"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_6257          ; -> branch target
    dw $08CE
    dw $FFFF  ; END

Bank0C_ScriptAddr_6257:
    dw $08CF
    dw $FFFF  ; END

Bank0C_ScriptAddr_625B:
    dw $02CD
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6269
    dw $02CE
    dw $FFFF  ; END

    db $CF
    db $02
    db $FF
    db $FF
Bank0C_ScriptAddr_626D:
    dw $0376  ; Text $0376: "No?! You must be a heck of a master to s"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $627B
    dw $0378  ; Text $0378: "[HERO] checked out the treasure chest! I"
    dw $FFFF  ; END

    db $77
    db $03
    db $FF
    db $FF
Bank0C_ScriptAddr_627F:
    dw $0430  ; Text $0430: "Yeti doesn't say yet. Funny? // You're h"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $628D
    dw $0378  ; Text $0378: "[HERO] checked out the treasure chest! I"
    dw $FFFF  ; END

    db $31
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_6291:
    dw $05F6  ; Text $05F6: "Oh, the hero of GreatTree, Master [HERO]"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $629F
    dw $0378  ; Text $0378: "[HERO] checked out the treasure chest! I"
    dw $FFFF  ; END

    db $F7
    db $05
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Bazaar_Script17
; ---------------------------------------------------------------------------
Bazaar_Script17:
    dw $0379  ; Text $0379: "Hm.. It seems there are several hidden G"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script18
; ---------------------------------------------------------------------------
Bazaar_Script18:
    dw $0379  ; Text $0379: "Hm.. It seems there are several hidden G"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script19
; ---------------------------------------------------------------------------
Bazaar_Script19:
    dw $0680  ; Text $0680: "MilayouCome back when you wanna breed. /"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0680  ; Text $0680: "MilayouCome back when you wanna breed. /"
    dw $0682  ; Text $0682: "MilayouWhich monster will you pick for m"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script20
; ---------------------------------------------------------------------------
Bazaar_Script20:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_62C1          ; -> branch target
    dw $0432  ; Text $0432: "You see the merchant with an attitude at"
    dw $FFFF  ; END

Bank0C_ScriptAddr_62C1:
    dw $05F8  ; Text $05F8: "The monstrous master was your sister!! I"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script21
; ---------------------------------------------------------------------------
Bazaar_Script21:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_62CF          ; -> branch target
    dw $0165  ; Text $0165: "KingOh [HERO]! I heard you survived G cl"
    dw $FFFF  ; END

Bank0C_ScriptAddr_62CF:
    dw $045F  ; Text $045F: "0000000000000000000000000000000000000000"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script22
; ---------------------------------------------------------------------------
Bazaar_Script22:
    dw $FF01  ; BranchIfFlagSet
    dw $00F6  ; Text $00F6: "It's a tie... In this case... I win anyw"
    dw Bank0C_ScriptAddr_6431          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_642D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $009E  ; Text $009E: "ed a treasure chest! // [HERO] picked up"
    dw Bank0C_ScriptAddr_6429          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_62F1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw Bank0C_ScriptAddr_6413          ; -> branch target
Bank0C_ScriptAddr_62F1:
    dw $FF01  ; BranchIfFlagSet
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw Bank0C_ScriptAddr_640F          ; -> branch target
    dw $0166  ; Text $0166: "How are you, King of GreatTree? I realiz"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0C_ScriptAddr_6305          ; -> branch target
    dw $0167  ; Text $0167: "Oh, what a cute little child. Were you p"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6305:
    dw $FF15  ; PlaySE
    dw $CA8D  ; RAM $CA8D
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6323
    dw $FF23  ; PlaySE2
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $6327
    dw $FF23  ; PlaySE2
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6365
    dw $FF23  ; PlaySE2
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $637B
    dw $0168  ; Text $0168: "King of GreatLog King of GreatTree, it's"
    dw $FFFF  ; END

    db $D9
    db $04
    db $FF
    db $FF
    db $69
    db $01
    db $6A
    db $01
    db $15
    db $FF
    db $3C
    db $C8
    db $00
    db $00
    db $8B
    db $63
    db $23
    db $FF
    db $01
    db $00
    db $43
    db $63
    db $23
    db $FF
    db $02
    db $00
    db $57
    db $63
    db $6D
    db $01
    db $FF
    db $FF
    db $6E
    db $01
    db $15
    db $FF
    db $3C
    db $C8
    db $00
    db $00
    db $8B
    db $63
    db $23
    db $FF
    db $02
    db $00
    db $57
    db $63
    db $6D
    db $01
    db $FF
    db $FF
    db $6E
    db $01
    db $15
    db $FF
    db $3C
    db $C8
    db $00
    db $00
    db $8B
    db $63
    db $6D
    db $01
    db $FF
    db $FF
    db $69
    db $01
    db $6A
    db $01
    db $15
    db $FF
    db $3C
    db $C8
    db $00
    db $00
    db $8B
    db $63
    db $23
    db $FF
    db $02
    db $00
    db $57
    db $63
    db $6D
    db $01
    db $FF
    db $FF
    db $69
    db $01
    db $6A
    db $01
    db $15
    db $FF
    db $3C
    db $C8
    db $00
    db $00
    db $8B
    db $63
    db $6D
    db $01
    db $FF
    db $FF
    db $6B
    db $01
    db $D3
    db $08
    db $06
    db $FF
    db $25
    db $FF
    db $61
    db $FF
    db $3D
    db $64
    db $24
    db $FF
    db $35
    db $64
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $4D
    db $64
    db $24
    db $FF
    db $45
    db $64
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $3D
    db $64
    db $24
    db $FF
    db $35
    db $64
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $4D
    db $64
    db $24
    db $FF
    db $45
    db $64
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $3D
    db $64
    db $24
    db $FF
    db $35
    db $64
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $4D
    db $64
    db $24
    db $FF
    db $45
    db $64
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $3D
    db $64
    db $24
    db $FF
    db $35
    db $64
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $4D
    db $64
    db $24
    db $FF
    db $45
    db $64
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $3D
    db $64
    db $24
    db $FF
    db $35
    db $64
    db $09
    db $FF
    db $04
    db $00
    db $07
    db $FF
    db $6C
    db $01
    db $03
    db $FF
    db $40
    db $00
    db $12
    db $FF
    db $3A
    db $D9
    db $01
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_640F:
    dw $016F  ; Text $016F: "KingOh [HERO]! You beat Golem! KingWell "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6413:
    dw $0434  ; Text $0434: "The last match in S class will be with t"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6421
    dw $0435  ; Text $0435: "Well, you're strong so you may not need "
    dw $FFFF  ; END

    db $36
    db $04
    db $03
    db $FF
    db $9E
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_6429:
    dw $0437
    dw $FFFF  ; END

Bank0C_ScriptAddr_642D:
    dw $05F9  ; Text $05F9: "Hey! Our hero [HERO]! The two of us are "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6431:
    dw $07A0  ; Text $07A0: "Item shop. May I help you? // Anything e"
    dw $FFFF  ; END

    db $46
    db $00
    db $70
    db $71
    db $D8
    db $72
    db $73
    db $D9
    db $46
    db $00
    db $03
    db $03
    db $D8
    db $03
    db $03
    db $D9
    db $46
    db $00
    db $40
    db $41
    db $D8
    db $42
    db $43
    db $D9
    db $46
    db $00
    db $02
    db $02
    db $D8
    db $02
    db $02
    db $D9
; ---------------------------------------------------------------------------
; Bazaar_Script23
; ---------------------------------------------------------------------------
Bazaar_Script23:
    dw $FF01  ; BranchIfFlagSet
    dw $00F6  ; Text $00F6: "It's a tie... In this case... I win anyw"
    dw Bank0C_ScriptAddr_6559          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F5  ; Text $00F5: "I won! Challenge me anytime! // It's a t"
    dw Bank0C_ScriptAddr_648D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6485          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_6473          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw Bank0C_ScriptAddr_6481          ; -> branch target
Bank0C_ScriptAddr_6473:
    dw $FF01  ; BranchIfFlagSet
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw Bank0C_ScriptAddr_647D          ; -> branch target
    dw $0170  ; Text $0170: "Are you familiar with the Gate of Villag"
    dw $FFFF  ; END

Bank0C_ScriptAddr_647D:
    dw $0171  ; Text $0171: "Dragon loves girls.It carried a princess"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6481:
    dw $0438
    dw $FFFF  ; END

Bank0C_ScriptAddr_6485:
    dw $05FA  ; Text $05FA: "Missing... Something missing. Entertainm"
    dw $FF03  ; SetEventFlag
    dw $00F5  ; Text $00F5: "I won! Challenge me anytime! // It's a t"
    dw $FFFF  ; END

Bank0C_ScriptAddr_648D:
    dw $05FB  ; Text $05FB: "...I wonder if you brought a monster wit"
    dw $FF38  ; BattleSetup
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $64A5
    dw $FF38  ; BattleSetup
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $64A5
    dw $FF38  ; BattleSetup
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $64A5
    dw $0204  ; Text $0204: "[HERO] looked into the big kettle. ...So"
    dw $FFFF  ; END

    db $FC
    db $05
    db $FD
    db $05
    db $FE
    db $05
    db $06
    db $FF
    db $61
    db $FF
    db $65
    db $65
    db $24
    db $FF
    db $5D
    db $65
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $75
    db $65
    db $24
    db $FF
    db $6D
    db $65
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $65
    db $65
    db $24
    db $FF
    db $5D
    db $65
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $75
    db $65
    db $24
    db $FF
    db $6D
    db $65
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $65
    db $65
    db $24
    db $FF
    db $5D
    db $65
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $75
    db $65
    db $24
    db $FF
    db $6D
    db $65
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $65
    db $65
    db $24
    db $FF
    db $5D
    db $65
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $75
    db $65
    db $24
    db $FF
    db $6D
    db $65
    db $09
    db $FF
    db $01
    db $00
    db $61
    db $FF
    db $65
    db $65
    db $24
    db $FF
    db $5D
    db $65
    db $09
    db $FF
    db $04
    db $00
    db $07
    db $FF
    db $FF
    db $05
    db $03
    db $FF
    db $F6
    db $00
    db $00
    db $FF
    db $15
    db $00
    db $2D
    db $65
    db $01
    db $FF
    db $2D
    db $00
    db $51
    db $65
    db $01
    db $FF
    db $2D
    db $00
    db $49
    db $65
    db $01
    db $FF
    db $15
    db $00
    db $41
    db $65
    db $12
    db $FF
    db $3A
    db $D9
    db $05
    db $00
    db $FF
    db $FF
    db $12
    db $FF
    db $3A
    db $D9
    db $06
    db $00
    db $FF
    db $FF
    db $12
    db $FF
    db $3A
    db $D9
    db $07
    db $00
    db $FF
    db $FF
    db $12
    db $FF
    db $3A
    db $D9
    db $08
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_6559:
    dw $07A1  ; Text $07A1: "Anything else? // Thank you. Come again!"
    dw $FFFF  ; END

    db $0E
    db $01
    db $70
    db $71
    db $D8
    db $72
    db $73
    db $D9
    db $0E
    db $01
    db $03
    db $03
    db $D8
    db $03
    db $03
    db $D9
    db $0E
    db $01
    db $40
    db $41
    db $D8
    db $42
    db $43
    db $D9
    db $0E
    db $01
    db $02
    db $02
    db $D8
    db $02
    db $02
    db $D9
; ---------------------------------------------------------------------------
; Bazaar_Script24
; ---------------------------------------------------------------------------
Bazaar_Script24:
    dw $FF01  ; BranchIfFlagSet
    dw $00F3  ; Text $00F3: "Select your choice by stepping on the pa"
    dw Bank0C_ScriptAddr_661D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_660F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_6601          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_65F3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_65E5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_65D7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0045  ; Text $0045: "PulioYour Majesty, please forgive me. //"
    dw Bank0C_ScriptAddr_65C9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "Watabou brings us capable masters. Hmm. "
    dw Bank0C_ScriptAddr_65BB          ; -> branch target
    dw $0172  ; Text $0172: "Are you familiar with the Gate of Talism"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $0173  ; Text $0173: "I see...Hm.. // The stone guard fell asl"
    dw $FFFF  ; END

Bank0C_ScriptAddr_65BB:
    dw $0172  ; Text $0172: "Are you familiar with the Gate of Talism"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $01B3  ; Text $01B3: "Here you are at the Chamber of Travelers"
    dw $FFFF  ; END

Bank0C_ScriptAddr_65C9:
    dw $0172  ; Text $0172: "Are you familiar with the Gate of Talism"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $0202  ; Text $0202: "[HERO] looked at the bookshelf. The Mast"
    dw $FFFF  ; END

Bank0C_ScriptAddr_65D7:
    dw $0172  ; Text $0172: "Are you familiar with the Gate of Talism"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $02D0
    dw $FFFF  ; END

Bank0C_ScriptAddr_65E5:
    dw $0172  ; Text $0172: "Are you familiar with the Gate of Talism"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $037A  ; Text $037A: "Go left to the Room of Joy Wisdom. In th"
    dw $FFFF  ; END

Bank0C_ScriptAddr_65F3:
    dw $0172  ; Text $0172: "Are you familiar with the Gate of Talism"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $0433  ; Text $0433: "Hee hee! Yo dude, wanna know who're you "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6601:
    dw $0172  ; Text $0172: "Are you familiar with the Gate of Talism"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $049D  ; Text $049D: "I wish you good luck! All rooms are now "
    dw $FFFF  ; END

Bank0C_ScriptAddr_660F:
    dw $0172  ; Text $0172: "Are you familiar with the Gate of Talism"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $0358  ; Text $0358: "Oh, that's a WingSlime! Cute! For bringi"
    dw $FFFF  ; END

Bank0C_ScriptAddr_661D:
    dw $0172  ; Text $0172: "Are you familiar with the Gate of Talism"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $662B
    dw $03D7  ; Text $03D7: "You, must obey my command. I want to see"
    dw $FFFF  ; END

    db $49
    db $03
    db $FF
    db $FF
Bank0C_ScriptAddr_662F:
    dw $0174  ; Text $0174: "The stone guard fell asleep from the flu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub Per-Script Table (map_type=$03, 20 scripts)
; ---------------------------------------------------------------------------
GateHub_ScriptPtrTable:
    dw GateHub_Script00                ; script 0
    dw GateHub_Script01                ; script 1
    dw GateHub_Script02                ; script 2
    dw GateHub_Script03                ; script 3
    dw GateHub_Script04                ; script 4
    dw GateHub_Script05                ; script 5
    dw GateHub_Script06                ; script 6
    dw GateHub_Script07                ; script 7
    dw GateHub_Script08                ; script 8
    dw GateHub_Script09                ; script 9
    dw GateHub_Script10                ; script 10
    dw GateHub_Script11                ; script 11
    dw GateHub_Script12                ; script 12
    dw GateHub_Script13                ; script 13
    dw GateHub_Script14                ; script 14
    dw GateHub_Script15                ; script 15
    dw GateHub_Script16                ; script 16
    dw GateHub_Script17                ; script 17
    dw GateHub_Script18                ; script 18
    dw GateHub_Script19                ; script 19
; ---------------------------------------------------------------------------
; GateHub_Script00
; ---------------------------------------------------------------------------
GateHub_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script01
; ---------------------------------------------------------------------------
GateHub_Script01:
    dw $0133  ; Text $0133: "It's helpful to take a WarpWing with you"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script02
; ---------------------------------------------------------------------------
GateHub_Script02:
    dw $0132  ; Text $0132: "Sometimes monsters you beat will become "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script03
; ---------------------------------------------------------------------------
GateHub_Script03:
    dw $0134  ; Text $0134: "Here's the Monster Master School. // [HE"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script04
; ---------------------------------------------------------------------------
GateHub_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6759          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_6741          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_6729          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_6711          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "No! You'll be hurt if you fall. // If it"
    dw Bank0C_ScriptAddr_66F9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_66E1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "[HERO] read the sign. Danger, Don't rush"
    dw Bank0C_ScriptAddr_66C9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_66B1          ; -> branch target
    dw $0066  ; Text $0066: "You can enter the locked rooms only when"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_66AD          ; -> branch target
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
Bank0C_ScriptAddr_66AD:
    dw $047E  ; Text $047E: "TERRY?Ahhh... For some reason, I feel re"
    dw $FFFF  ; END

Bank0C_ScriptAddr_66B1:
    dw $0066  ; Text $0066: "You can enter the locked rooms only when"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $66C5
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $0203  ; Text $0203: "[HERO] looked into the jar. It was a den"
    dw $FFFF  ; END

Bank0C_ScriptAddr_66C9:
    dw $0066  ; Text $0066: "You can enter the locked rooms only when"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $66DD
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $0278  ; Text $0278: "You're at the Chamber of Traverlers' Gat"
    dw $FFFF  ; END

Bank0C_ScriptAddr_66E1:
    dw $0066  ; Text $0066: "You can enter the locked rooms only when"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $66F5
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $02D1  ; Text $02D1: "0000000000000000000000000000000000000000"
    dw $FFFF  ; END

Bank0C_ScriptAddr_66F9:
    dw $0066  ; Text $0066: "You can enter the locked rooms only when"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $670D
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $033D  ; Text $033D: "You gotta have MetalCut to defeat Metaly"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6711:
    dw $0066  ; Text $0066: "You can enter the locked rooms only when"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6725
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $037B  ; Text $037B: "The Room of Happiness Temptation are now"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6729:
    dw $0066  ; Text $0066: "You can enter the locked rooms only when"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $673D
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $0439
    dw $FFFF  ; END

Bank0C_ScriptAddr_6741:
    dw $0066  ; Text $0066: "You can enter the locked rooms only when"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6755
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $049E  ; Text $049E: "All Gates are now yours! The Room of Joy"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6759:
    dw $0066  ; Text $0066: "You can enter the locked rooms only when"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $676D
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $07A2  ; Text $07A2: "Thank you. Come again! // What would you"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script05
; ---------------------------------------------------------------------------
GateHub_Script05:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script06
; ---------------------------------------------------------------------------
GateHub_Script06:
    dw $0130  ; Text $0130: "Both the Medal Man myself love medals! I"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script07
; ---------------------------------------------------------------------------
GateHub_Script07:
    dw $0131  ; Text $0131: "Welcome to the Master School! I am the p"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script08
; ---------------------------------------------------------------------------
GateHub_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw Bank0C_ScriptAddr_6785          ; -> branch target
    dw $0054  ; Text $0054: "Hale was the cherished pet of the King. "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6785:
    dw $0067  ; Text $0067: "Monsters have personalities too. Dependi"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script09
; ---------------------------------------------------------------------------
GateHub_Script09:
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script10
; ---------------------------------------------------------------------------
GateHub_Script10:
    dw $FF01  ; BranchIfFlagSet
    dw $00F8  ; Text $00F8: "You're good... // Want to know where the"
    dw Bank0C_ScriptAddr_67EB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_67E3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_67DF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_67DB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "[HERO] read the sign. Danger, Don't rush"
    dw Bank0C_ScriptAddr_67D7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_67D3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "Watabou brings us capable masters. Hmm. "
    dw Bank0C_ScriptAddr_67CF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw Bank0C_ScriptAddr_67CB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw Bank0C_ScriptAddr_67C7          ; -> branch target
    dw $0056  ; Text $0056: "We are at the Chamber of Travelers' Gate"
    dw $FFFF  ; END

Bank0C_ScriptAddr_67C7:
    dw $0487  ; Text $0487: "KingAnyway! Your wish will come true whe"
    dw $FFFF  ; END

Bank0C_ScriptAddr_67CB:
    dw $0175  ; Text $0175: "Who do you think you are! What? You're a"
    dw $FFFF  ; END

Bank0C_ScriptAddr_67CF:
    dw $01B4  ; Text $01B4: "The place to hatch eggs? Now I remember!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_67D3:
    dw $08D0
    dw $FFFF  ; END

Bank0C_ScriptAddr_67D7:
    dw $0279  ; Text $0279: "BattleRex uses EvilSlash. It also uses M"
    dw $FFFF  ; END

Bank0C_ScriptAddr_67DB:
    dw $02D2
    dw $FFFF  ; END

Bank0C_ScriptAddr_67DF:
    dw $043B
    dw $FFFF  ; END

Bank0C_ScriptAddr_67E3:
    dw $07A4  ; Text $07A4: "What would you like? // How many? // <sl"
    dw $FF03  ; SetEventFlag
    dw $00F8  ; Text $00F8: "You're good... // Want to know where the"
    dw $FFFF  ; END

Bank0C_ScriptAddr_67EB:
    dw $07A5  ; Text $07A5: "How many? // <slime> X 0 is G. // You do"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script11
; ---------------------------------------------------------------------------
GateHub_Script11:
    dw $0136  ; Text $0136: "[HERO] read the blackboard. Masters are "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script12
; ---------------------------------------------------------------------------
GateHub_Script12:
    dw $0135  ; Text $0135: "[HERO] read the blackboard. Do's Don'ts "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script13
; ---------------------------------------------------------------------------
GateHub_Script13:
    dw $00DD  ; Text $00DD: "u leave the monsters here. SlioBut the m"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script14
; ---------------------------------------------------------------------------
GateHub_Script14:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6831          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A0  ; Text $00A0: "o to bed! // Milayou... zzz. // Terry lo"
    dw Bank0C_ScriptAddr_682D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_6825          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "[HERO] read the sign. When the GreatTree"
    dw Bank0C_ScriptAddr_6821          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_681D          ; -> branch target
    dw $0067  ; Text $0067: "Monsters have personalities too. Dependi"
    dw $FFFF  ; END

Bank0C_ScriptAddr_681D:
    dw $037C  ; Text $037C: "Good work! Have you found strong monster"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6821:
    dw $03EA  ; Text $03EA: "Behind the Gate of Labyrinth there reall"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6825:
    dw $043C
    dw $FF03  ; SetEventFlag
    dw $00A0  ; Text $00A0: "o to bed! // Milayou... zzz. // Terry lo"
    dw $FFFF  ; END

Bank0C_ScriptAddr_682D:
    dw $043D
    dw $FFFF  ; END

Bank0C_ScriptAddr_6831:
    dw $07A6  ; Text $07A6: "<slime> X 0 is G. // You don't have enou"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script15
; ---------------------------------------------------------------------------
GateHub_Script15:
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_6863          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0022  ; Text $0022: "I have a feeling that your victory will "
    dw Bank0C_ScriptAddr_6847          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_685F          ; -> branch target
Bank0C_ScriptAddr_6847:
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "[HERO] read the sign. When the GreatTree"
    dw Bank0C_ScriptAddr_685B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_6857          ; -> branch target
    dw $0068  ; Text $0068: "Hey Master! Dn'a have an egg?[Y/N] // Sp"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6857:
    dw $037D  ; Text $037D: "SMACK! Something hit [HERO] and bounced "
    dw $FFFF  ; END

Bank0C_ScriptAddr_685B:
    dw $03EB  ; Text $03EB: "DuckKite is a troublesome monster. It ma"
    dw $FFFF  ; END

Bank0C_ScriptAddr_685F:
    dw $043E
    dw $FFFF  ; END

Bank0C_ScriptAddr_6863:
    dw $04A0  ; Text $04A0: "We'll spend the Starry Night, together j"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script16
; ---------------------------------------------------------------------------
GateHub_Script16:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script17
; ---------------------------------------------------------------------------
GateHub_Script17:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script18
; ---------------------------------------------------------------------------
GateHub_Script18:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script19
; ---------------------------------------------------------------------------
GateHub_Script19:
    dw $FF01  ; BranchIfFlagSet
    dw $00FA  ; Text $00FA: "I bet you wanna know. // You can meet he"
    dw Bank0C_ScriptAddr_687B          ; -> branch target
    dw $07A8  ; Text $07A8: "You can only carry 20 items! // Thank yo"
    dw $FF03  ; SetEventFlag
    dw $00FA  ; Text $00FA: "I bet you wanna know. // You can meet he"
    dw $FFFF  ; END

Bank0C_ScriptAddr_687B:
    dw $07A9  ; Text $07A9: "Thank you! // Which items will you sell "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm Per-Script Table (map_type=$04, 43 scripts)
; ---------------------------------------------------------------------------
Farm_ScriptPtrTable:
    dw Farm_Script00                   ; script 0
    dw Farm_Script01                   ; script 1
    dw Farm_Script02                   ; script 2
    dw Farm_Script03                   ; script 3
    dw Farm_Script04                   ; script 4
    dw Farm_Script05                   ; script 5
    dw Farm_Script06                   ; script 6
    dw Farm_Script07                   ; script 7
    dw Farm_Script08                   ; script 8
    dw Farm_Script09                   ; script 9
    dw Farm_Script10                   ; script 10
    dw Farm_Script11                   ; script 11
    dw Farm_Script12                   ; script 12
    dw Farm_Script13                   ; script 13
    dw Farm_Script14                   ; script 14
    dw Farm_Script15                   ; script 15
    dw Farm_Script16                   ; script 16
    dw Farm_Script17                   ; script 17
    dw Farm_Script18                   ; script 18
    dw Farm_Script19                   ; script 19
    dw Farm_Script20                   ; script 20
    dw Farm_Script21                   ; script 21
    dw Farm_Script22                   ; script 22
    dw Farm_Script23                   ; script 23
    dw Farm_Script24                   ; script 24
    dw Farm_Script25                   ; script 25
    dw Farm_Script26                   ; script 26
    dw Farm_Script27                   ; script 27
    dw Farm_Script28                   ; script 28
    dw Farm_Script29                   ; script 29
    dw Farm_Script30                   ; script 30
    dw Farm_Script31                   ; script 31
    dw Farm_Script32                   ; script 32
    dw Farm_Script33                   ; script 33
    dw Farm_Script34                   ; script 34
    dw Farm_Script35                   ; script 35
    dw Farm_Script36                   ; script 36
    dw Farm_Script37                   ; script 37
    dw Farm_Script38                   ; script 38
    dw Farm_Script39                   ; script 39
    dw Farm_Script40                   ; script 40
    dw Farm_Script41                   ; script 41
    dw Farm_Script42                   ; script 42
; ---------------------------------------------------------------------------
; Farm_Script00
; ---------------------------------------------------------------------------
Farm_Script00:
    dw $FF0E  ; SetMapTransition
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_68E3          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw Bank0C_ScriptAddr_6965          ; -> branch target
    dw $FFFF  ; END

Bank0C_ScriptAddr_68E3:
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "Gwrr, Gwrr... // In the back, they teach"
    dw $68E1
    dw $FF01  ; BranchIfFlagSet
    dw $00E5  ; Text $00E5: "Oh, Sir [HERO]. Congratulations on your "
    dw $68E1
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "Well done! You survived G class! // Oh, "
    dw $68F7
    dw $FFFF  ; END

    db $47
    db $FF
    db $00
    db $00
    db $07
    db $FF
    db $EF
    db $04
    db $0A
    db $FF
    db $00
    db $00
    db $10
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $01
    db $00
    db $47
    db $FF
    db $02
    db $00
    db $47
    db $FF
    db $03
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $05
    db $00
    db $47
    db $FF
    db $06
    db $00
    db $09
    db $FF
    db $10
    db $00
    db $12
    db $FF
    db $8A
    db $C8
    db $03
    db $00
    db $12
    db $FF
    db $8B
    db $C8
    db $00
    db $00
    db $3E
    db $FF
    db $03
    db $FF
    db $E5
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $07
    db $FF
    db $F0
    db $04
    db $15
    db $FF
    db $3C
    db $C8
    db $00
    db $00
    db $61
    db $69
    db $F1
    db $04
    db $FF
    db $FF
    db $F2
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_6965:
    dw $FF15  ; PlaySE
    dw $D9E2  ; RAM $D9E2
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $68E1
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF61  ; Cmd61
    dw $6A55
    dw $FF24  ; Cmd24
    dw $69EF
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF61  ; Cmd61
    dw $6A5D
    dw $FF24  ; Cmd24
    dw $69F7
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF61  ; Cmd61
    dw $6A6B
    dw $FF24  ; Cmd24
    dw $6A05
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF61  ; Cmd61
    dw $6A7F
    dw $FF24  ; Cmd24
    dw $6A19
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF61  ; Cmd61
    dw $6A93
    dw $FF24  ; Cmd24
    dw $6A2D
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF61  ; Cmd61
    dw $6AA7
    dw $FF24  ; Cmd24
    dw $6A41
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFB0  ; Cmd$B0
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF1C  ; CompareRAM
    dw $0700  ; Text $0700: "Humpf, I don't need you! // I don't have"
    dw $FF19  ; FadeEffect
    dw $FF1C  ; CompareRAM
    dw $0600  ; Text $0600: "Humpf, I don't need you! // I don't have"
    dw $FF19  ; FadeEffect
    dw $FF12  ; WriteRAM
    dw $D9E2  ; RAM $D9E2
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

    db $D0
    db $01
    db $40
    db $41
    db $D8
    db $42
    db $43
    db $D9
    db $90
    db $01
    db $40
    db $41
    db $D8
    db $42
    db $43
    db $D8
    db $44
    db $45
    db $D8
    db $46
    db $47
    db $D9
    db $50
    db $01
    db $40
    db $41
    db $D8
    db $42
    db $43
    db $D8
    db $44
    db $45
    db $D8
    db $46
    db $47
    db $D8
    db $48
    db $49
    db $D8
    db $4A
    db $4B
    db $D9
    db $10
    db $01
    db $40
    db $41
    db $D8
    db $42
    db $43
    db $D8
    db $44
    db $45
    db $D8
    db $46
    db $47
    db $D8
    db $48
    db $49
    db $D8
    db $4A
    db $4B
    db $D9
    db $D0
    db $00
    db $40
    db $41
    db $D8
    db $42
    db $43
    db $D8
    db $44
    db $45
    db $D8
    db $46
    db $47
    db $D8
    db $48
    db $49
    db $D8
    db $4A
    db $4B
    db $D9
    db $90
    db $00
    db $40
    db $41
    db $D8
    db $42
    db $43
    db $D8
    db $44
    db $45
    db $D8
    db $46
    db $47
    db $D8
    db $48
    db $49
    db $D8
    db $4A
    db $4B
    db $D9
    db $D0
    db $01
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D9
    db $90
    db $01
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D9
    db $50
    db $01
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D9
    db $10
    db $01
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D9
    db $D0
    db $00
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D9
    db $90
    db $00
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D8
    db $00
    db $00
    db $D9
; ---------------------------------------------------------------------------
; Farm_Script01
; ---------------------------------------------------------------------------
Farm_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $0045  ; Text $0045: "PulioYour Majesty, please forgive me. //"
    dw Bank0C_ScriptAddr_6ADD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "Watabou brings us capable masters. Hmm. "
    dw Bank0C_ScriptAddr_6AD9          ; -> branch target
    dw $0069  ; Text $0069: "Splat... Poop hit [HERO]. // Thwack! It "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_6AD5          ; -> branch target
    dw $086E  ; Text $086E: "If you choose CHARGE you can train the m"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6AD5:
    dw $086D  ; Text $086D: "Eggs will be eggs forever if left alone."
    dw $FFFF  ; END

Bank0C_ScriptAddr_6AD9:
    dw $01B5  ; Text $01B5: "Well done! You survived E class! The Kin"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6ADD:
    dw $0206  ; Text $0206: "It's always better to have a WarpWing wi"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script02
; ---------------------------------------------------------------------------
Farm_Script02:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF10  ; NPCAnimStart
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0068  ; Text $0068: "Hey Master! Dn'a have an egg?[Y/N] // Sp"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $001A  ; Text $001A: "[HERO] opened a treasure chest! // [HERO"
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6B8F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_6B87          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_6B7F          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_6B2F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_6B77          ; -> branch target
Bank0C_ScriptAddr_6B2F:
    dw $FF01  ; BranchIfFlagSet
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_6B6F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw Bank0C_ScriptAddr_6B43          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $006A  ; Text $006A: "Thwack! It was the egg of a SkyDragon th"
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B43:
    dw $FF07  ; InitDialogMode
    dw $006B  ; Text $006B: "[HERO] took the egg of a SkyDragon! But,"
    dw $FF28  ; CheckStorageFull
    dw Bank0C_ScriptAddr_6B69          ; -> branch target
    dw $006C  ; Text $006C: "Could not keep the egg because there are"
    dw $FF06  ; IncrementCounter
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF03  ; SetEventFlag
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw $FF29  ; AddMonster
    dw $015E  ; Text $015E: "KingWell done, [HERO]! You beat another "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6B69:
    dw $006D  ; Text $006D: "Splash! Poop hit [HERO]. // Treats! Beef"
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B6F:
    dw $FF07  ; InitDialogMode
    dw $006E  ; Text $006E: "Treats! BeefJerky, PorkChop, Rib. BeefJe"
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B77:
    dw $FF07  ; InitDialogMode
    dw $0205  ; Text $0205: "Welcome to the Master School! [HERO]! It"
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B7F:
    dw $FF07  ; InitDialogMode
    dw $02D3
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B87:
    dw $FF07  ; InitDialogMode
    dw $037E  ; Text $037E: "We monsters become lively when the Starr"
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B8F:
    dw $FF07  ; InitDialogMode
    dw $07AA  ; Text $07AA: "Which items will you sell to me? // You "
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B97:
    dw $FF06  ; IncrementCounter
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script03
; ---------------------------------------------------------------------------
Farm_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6BBF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_6BBB          ; -> branch target
    dw $02D4
    dw $FFFF  ; END

Bank0C_ScriptAddr_6BBB:
    dw $037F  ; Text $037F: "There are monsters with amazing skills! "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6BBF:
    dw $07AB  ; Text $07AB: "You don't have items I can buy. // How m"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script04
; ---------------------------------------------------------------------------
Farm_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $0094
    dw Bank0C_ScriptAddr_6BCD          ; -> branch target
    dw $04EB  ; Text $04EB: "Florajays, ArmorPedes, and Pteranods, Ma"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6BCD:
    dw $04EC
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script05
; ---------------------------------------------------------------------------
Farm_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $00E3  ; Text $00E3: "Too bad. You need more training. There a"
    dw Bank0C_ScriptAddr_6BDF          ; -> branch target
    dw $04ED
    dw $FF03  ; SetEventFlag
    dw $00E3  ; Text $00E3: "Too bad. You need more training. There a"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6BDF:
    dw $04EE
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script06
; ---------------------------------------------------------------------------
Farm_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6C0F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_6BFF          ; -> branch target
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0014  ; Text $0014: "I'm the minister of this kingdom. Are yo"
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6BFF:
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0014  ; Text $0014: "I'm the minister of this kingdom. Are yo"
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0209  ; Text $0209: "I'm conducting secret research at the bo"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C0F:
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0014  ; Text $0014: "I'm the minister of this kingdom. Are yo"
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $07AE  ; Text $07AE: "You can only have up to 99999G! // Thank"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script07
; ---------------------------------------------------------------------------
Farm_Script07:
    dw $0034  ; Text $0034: "No! You'll be hurt if you fall. // If it"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script08
; ---------------------------------------------------------------------------
Farm_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6C4B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_6C47          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_6C43          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw Bank0C_ScriptAddr_6C3F          ; -> branch target
    dw $0033  ; Text $0033: "[HERO] read the sign. Danger, Don't rush"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C3F:
    dw $006F  ; Text $006F: "If you take monsters on a journey, they "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C43:
    dw $0207  ; Text $0207: "You are good. You beat the teacher! // H"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C47:
    dw $0380  ; Text $0380: "I heard there is something that can chan"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C4B:
    dw $07AC  ; Text $07AC: "How many would you like to sell? // <sli"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script09
; ---------------------------------------------------------------------------
Farm_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6C6D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_6C69          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_6C65          ; -> branch target
    dw $0070
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C65:
    dw $0208  ; Text $0208: "Here's the Room of Villager Talisman. Go"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C69:
    dw $0381  ; Text $0381: "Hello. The stable is below here. Bleat. "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C6D:
    dw $07AD  ; Text $07AD: "<slime> X 0 is G. // You can only have u"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script10
; ---------------------------------------------------------------------------
Farm_Script10:
    dw $04F3
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script11
; ---------------------------------------------------------------------------
Farm_Script11:
    dw $FF01  ; BranchIfFlagSet
    dw $00E6  ; Text $00E6: "Welcome to the arena! Want to hear about"
    dw Bank0C_ScriptAddr_6C83          ; -> branch target
    dw $04F4
    dw $FF03  ; SetEventFlag
    dw $00E6  ; Text $00E6: "Welcome to the arena! Want to hear about"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C83:
    dw $04F5
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script12
; ---------------------------------------------------------------------------
Farm_Script12:
    dw $04F7
    dw $FF1C  ; CompareRAM
    dw $0903  ; Text $0903: "We gather here at the arena, seeking vic"
    dw $FF19  ; FadeEffect
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script13
; ---------------------------------------------------------------------------
Farm_Script13:
    dw $04F9
    dw $FF1C  ; CompareRAM
    dw $0904  ; Text $0904: "All monsters are born from eggs. // Eggs"
    dw $FF19  ; FadeEffect
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script14
; ---------------------------------------------------------------------------
Farm_Script14:
    dw $04F6
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script15
; ---------------------------------------------------------------------------
Farm_Script15:
    dw $04F8
    dw $FF1C  ; CompareRAM
    dw $0906  ; Text $0906: "If you choose CHARGE you can train the m"
    dw $FF19  ; FadeEffect
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script16
; ---------------------------------------------------------------------------
Farm_Script16:
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script17
; ---------------------------------------------------------------------------
Farm_Script17:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6CDF          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $007C
    dw Bank0C_ScriptAddr_6CBF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_6CDB          ; -> branch target
Bank0C_ScriptAddr_6CBF:
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_6CD3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw Bank0C_ScriptAddr_6CCF          ; -> branch target
    dw $0036  ; Text $0036: "[HERO] read the sign. When the GreatTree"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6CCF:
    dw $0176  ; Text $0176: "Almost there to the bottom! What is down"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6CD3:
    dw $02D5
    dw $FF03  ; SetEventFlag
    dw $007C
    dw $FFFF  ; END

Bank0C_ScriptAddr_6CDB:
    dw $04A1  ; Text $04A1: "Hello. Down to the stable. Bleat. Everyb"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6CDF:
    dw $07AF  ; Text $07AF: "Thanks again! // Vault. May I help you? "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script18
; ---------------------------------------------------------------------------
Farm_Script18:
    dw $02D6
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script19
; ---------------------------------------------------------------------------
Farm_Script19:
    dw $FF01  ; BranchIfFlagSet
    dw $00E7  ; Text $00E7: "The battle classes go from S,A down to G"
    dw Bank0C_ScriptAddr_6D9B          ; -> branch target
    dw $04FB
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0C_ScriptAddr_6CFF          ; -> branch target
    dw $04FD
    dw $FF03  ; SetEventFlag
    dw $00E7  ; Text $00E7: "The battle classes go from S,A down to G"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6CFF:
    dw $04FC
    dw $FF47  ; Cmd47
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FFF0  ; Cmd$F0
    dw $FF10  ; NPCAnimStart
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0188  ; Text $0188: "Can you give us your 0?[Y/N] // [HERO] g"
    dw $FF11  ; NPCAnimSetup
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0F  ; SetScreenScroll
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw $0118  ; Text $0118: "I bet you wanna know. // You can meet he"
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6D9B:
    dw $04FE
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0C_ScriptAddr_6CFF          ; -> branch target
    dw $04FD
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script20
; ---------------------------------------------------------------------------
Farm_Script20:
    dw $04FA
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script21
; ---------------------------------------------------------------------------
Farm_Script21:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6E05          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "Well done! You survived G class! // Oh, "
    dw Bank0C_ScriptAddr_6E01          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $007B
    dw Bank0C_ScriptAddr_6DFD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_6DEB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw Bank0C_ScriptAddr_6DE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw Bank0C_ScriptAddr_6DD5          ; -> branch target
    dw $003B  ; Text $003B: "Hey you! You came here to steal my monst"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6DD5:
    dw $003A  ; Text $003A: "[HERO] looked into the jar. The jar is f"
    dw $FF2C  ; CheckInvFull
    dw $6E09
    dw $0129  ; Text $0129: "This is an llonigirill. C'mon BeBe, repe"
    dw $FF03  ; SetEventFlag
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF2A  ; GiveItem
    dw $001E  ; Text $001E: "This is the Kingdom of GreatTree! // Wel"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6DE7:
    dw $003B  ; Text $003B: "Hey you! You came here to steal my monst"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6DEB:
    dw $003A  ; Text $003A: "[HERO] looked into the jar. The jar is f"
    dw $FF2C  ; CheckInvFull
    dw $6E09
    dw $0129  ; Text $0129: "This is an llonigirill. C'mon BeBe, repe"
    dw $FF03  ; SetEventFlag
    dw $007B
    dw $FF2A  ; GiveItem
    dw $001E  ; Text $001E: "This is the Kingdom of GreatTree! // Wel"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6DFD:
    dw $003B  ; Text $003B: "Hey you! You came here to steal my monst"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E01:
    dw $0502  ; Text $0502: "DurranHow was it? Learn anything? Durran"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E05:
    dw $07B1  ; Text $07B1: "Vault. May I help you? // Something else"
    dw $FFFF  ; END

    db $2A
    db $01
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Farm_Script22
; ---------------------------------------------------------------------------
Farm_Script22:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6E3F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "Well done! You survived G class! // Oh, "
    dw Bank0C_ScriptAddr_6E3B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_6E37          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_6E33          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_6E2F          ; -> branch target
    dw $0039  ; Text $0039: "[HERO] looked into the jar. // [HERO] lo"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E2F:
    dw $020B  ; Text $020B: "Congratulations on surviving F class. Th"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E33:
    dw $02D8
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E37:
    dw $04A3  ; Text $04A3: "There's something good about having a go"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E3B:
    dw $04FF
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E3F:
    dw $07B0  ; Text $07B0: "Vault. May I help you? // Something else"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script23
; ---------------------------------------------------------------------------
Farm_Script23:
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_6E57          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw Bank0C_ScriptAddr_6E53          ; -> branch target
    dw $0038  ; Text $0038: "Hey, Mr.Monster Master. I wonder what I "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E53:
    dw $0071
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E57:
    dw $020A  ; Text $020A: "Being a master and a fighter is one form"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script24
; ---------------------------------------------------------------------------
Farm_Script24:
    dw $FF01  ; BranchIfFlagSet
    dw $00FC  ; Text $00FC: "These statues are the protectors of Grea"
    dw Bank0C_ScriptAddr_6E8D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6E89          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "Well done! You survived G class! // Oh, "
    dw Bank0C_ScriptAddr_6E85          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_6E81          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_6E7D          ; -> branch target
    dw $02D7
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E7D:
    dw $0382  ; Text $0382: "Having a monster read a QuestBk makes th"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E81:
    dw $04A2  ; Text $04A2: "The Starry Night is soon. Yeah! Ha ha ha"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E85:
    dw $0500  ; Text $0500: "DurranHa ha ha! How easily you defeated "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E89:
    dw $07B2  ; Text $07B2: "Vault. May I help you? // Something else"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E8D:
    dw $07B3  ; Text $07B3: "Vault. May I help you? // Something else"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script25
; ---------------------------------------------------------------------------
Farm_Script25:
    dw $0501  ; Text $0501: "DurranWant a real thrill? Fight me! Durr"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script26
; ---------------------------------------------------------------------------
Farm_Script26:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6EE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "Well done! You survived G class! // Oh, "
    dw Bank0C_ScriptAddr_6F03          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0C_ScriptAddr_6EE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw Bank0C_ScriptAddr_6EE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw Bank0C_ScriptAddr_6EF3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw Bank0C_ScriptAddr_6EE7          ; -> branch target
    dw $003C  ; Text $003C: "C'mon, I'll give you a beating. Sniff sn"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_6ED5          ; -> branch target
    dw $003D  ; Text $003D: "You came here to get monsters? // I'm Pu"
    dw $003F  ; Text $003F: "I'm Slio. I am the grandson of Grandpa S"
    dw $FF03  ; SetEventFlag
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF04  ; ScreenEffect
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $06C0  ; Text $06C0: "Vault. May I help you? // Something else"
    dw $06C2  ; Text $06C2: "Come again anytime. // What would you li"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6ED5:
    dw $003E  ; Text $003E: "I'm Pulio I take care of this farm. Puli"
    dw $003F  ; Text $003F: "I'm Slio. I am the grandson of Grandpa S"
    dw $FF03  ; SetEventFlag
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF04  ; ScreenEffect
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $06C0  ; Text $06C0: "Vault. May I help you? // Something else"
    dw $06C2  ; Text $06C2: "Come again anytime. // What would you li"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6EE7:
    dw $06C0  ; Text $06C0: "Vault. May I help you? // Something else"
    dw $FF04  ; ScreenEffect
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $06C0  ; Text $06C0: "Vault. May I help you? // Something else"
    dw $06C2  ; Text $06C2: "Come again anytime. // What would you li"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6EF3:
    dw $0072
    dw $FF03  ; SetEventFlag
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw $FF04  ; ScreenEffect
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $06C0  ; Text $06C0: "Vault. May I help you? // Something else"
    dw $06C2  ; Text $06C2: "Come again anytime. // What would you li"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6F03:
    dw $0504  ; Text $0504: "DurranDid I lose? .. I lost... DurranYou"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script27
; ---------------------------------------------------------------------------
Farm_Script27:
    dw $FF00  ; BranchIfFlagClear
    dw $00E4  ; Text $00E4: "Well done! You survived G class! // Oh, "
    dw Bank0C_ScriptAddr_6F13          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A2  ; Text $00A2: "n drop off 19 more monsters at the farm."
    dw Bank0C_ScriptAddr_6FF9          ; -> branch target
Bank0C_ScriptAddr_6F13:
    dw $FF01  ; BranchIfFlagSet
    dw $00A3
    dw Bank0C_ScriptAddr_6FE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A2  ; Text $00A2: "n drop off 19 more monsters at the farm."
    dw Bank0C_ScriptAddr_6FCD          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_6F31          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A1  ; Text $00A1: "e Starry Night! KingLegend has it that t"
    dw Bank0C_ScriptAddr_6F9F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_6F71          ; -> branch target
Bank0C_ScriptAddr_6F31:
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "Well done! You survived G class! // Oh, "
    dw Bank0C_ScriptAddr_6FC9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A1  ; Text $00A1: "e Starry Night! KingLegend has it that t"
    dw Bank0C_ScriptAddr_6F9F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw Bank0C_ScriptAddr_6F71          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw Bank0C_ScriptAddr_6F5F          ; -> branch target
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF03  ; SetEventFlag
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_6F5B          ; -> branch target
    dw $0041  ; Text $0041: "SlioRaise the monster to be powerful! //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6F5B:
    dw $0042  ; Text $0042: "SlioDn'a wanna know about the farm? [Y/N"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6F5F:
    dw $0043  ; Text $0043: "You are at the monster farm. // KingOh, "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6F6D
    dw $0041  ; Text $0041: "SlioRaise the monster to be powerful! //"
    dw $FFFF  ; END

    db $42
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_6F71:
    dw $043F
    dw $FF03  ; SetEventFlag
    dw $00A1  ; Text $00A1: "e Starry Night! KingLegend has it that t"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6F97
    dw $FF28  ; CheckStorageFull
    dw $6F9B
    dw $0442
    dw $FF03  ; SetEventFlag
    dw $00A2  ; Text $00A2: "n drop off 19 more monsters at the farm."
    dw $FF29  ; AddMonster
    dw $015F  ; Text $015F: "Oh...King... // KingTrain hard! You're d"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FFFF  ; END

    db $40
    db $04
    db $FF
    db $FF
    db $41
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_6F9F:
    dw $0443
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6FC1
    dw $FF28  ; CheckStorageFull
    dw $6FC5
    dw $0442
    dw $FF03  ; SetEventFlag
    dw $00A2  ; Text $00A2: "n drop off 19 more monsters at the farm."
    dw $FF29  ; AddMonster
    dw $015F  ; Text $015F: "Oh...King... // KingTrain hard! You're d"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FFFF  ; END

    db $40
    db $04
    db $FF
    db $FF
    db $41
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_6FC9:
    dw $005D  ; Text $005D: "To get to the arena, go straight out of "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6FCD:
    dw $0444
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6FDF
    dw $0446
    dw $FF03  ; SetEventFlag
    dw $00A3
    dw $FFFF  ; END

    db $45
    db $04
    db $03
    db $FF
    db $A3
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_6FE7:
    dw $0447
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $6FF5
    dw $0446
    dw $FFFF  ; END

    db $45
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_6FF9:
    dw $0503  ; Text $0503: "DurranHere I come!! // DurranDid I lose?"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script28
; ---------------------------------------------------------------------------
Farm_Script28:
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_701B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw Bank0C_ScriptAddr_7017          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw Bank0C_ScriptAddr_7013          ; -> branch target
    dw $0044  ; Text $0044: "KingOh, this monster is the former king'"
    dw $FFFF  ; END

Bank0C_ScriptAddr_7013:
    dw $0073
    dw $FFFF  ; END

Bank0C_ScriptAddr_7017:
    dw $0177  ; Text $0177: "is added to the monster level when it fu"
    dw $FFFF  ; END

Bank0C_ScriptAddr_701B:
    dw $020C  ; Text $020C: "Are you familiar with the Gate of Bewild"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script29
; ---------------------------------------------------------------------------
Farm_Script29:
    dw $02D9
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_706F          ; -> branch target
    dw $FF15  ; PlaySE
    dw $CA8D  ; RAM $CA8D
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0C_ScriptAddr_706B          ; -> branch target
    dw $FF5F  ; Cmd5F
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0C_ScriptAddr_703D          ; -> branch target
    dw $08C7
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_703F          ; -> branch target
Bank0C_ScriptAddr_703D:
    dw $08D2
Bank0C_ScriptAddr_703F:
    dw $FF15  ; PlaySE
    dw $CA8D  ; RAM $CA8D
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_706B          ; -> branch target
    dw $FF5F  ; Cmd5F
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_7053          ; -> branch target
    dw $08C7
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_7055          ; -> branch target
Bank0C_ScriptAddr_7053:
    dw $08D2
Bank0C_ScriptAddr_7055:
    dw $FF15  ; PlaySE
    dw $CA8D  ; RAM $CA8D
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw Bank0C_ScriptAddr_706B          ; -> branch target
    dw $FF5F  ; Cmd5F
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw Bank0C_ScriptAddr_7069          ; -> branch target
    dw $08C7
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_706B          ; -> branch target
Bank0C_ScriptAddr_7069:
    dw $08D2
Bank0C_ScriptAddr_706B:
    dw $08CD
    dw $FFFF  ; END

Bank0C_ScriptAddr_706F:
    dw $08CA
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script30
; ---------------------------------------------------------------------------
Farm_Script30:
    dw $0505  ; Text $0505: "TERRY?..You're strong... You even defeat"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script31
; ---------------------------------------------------------------------------
Farm_Script31:
    dw $0506  ; Text $0506: "Do you really want to tell your true nam"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script32
; ---------------------------------------------------------------------------
Farm_Script32:
    dw $0507  ; Text $0507: "TERRY?It's okay. I know... // TERRY?No. "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script33
; ---------------------------------------------------------------------------
Farm_Script33:
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw Bank0C_ScriptAddr_7089          ; -> branch target
    dw $0074
    dw $FFFF  ; END

Bank0C_ScriptAddr_7089:
    dw $020D  ; Text $020D: "My years of research lead me to believe "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script34
; ---------------------------------------------------------------------------
Farm_Script34:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_70AB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_70A7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_70A3          ; -> branch target
    dw $02DA
    dw $FFFF  ; END

Bank0C_ScriptAddr_70A3:
    dw $0384  ; Text $0384: "I'm pretty much a coward. I wish there w"
    dw $FFFF  ; END

Bank0C_ScriptAddr_70A7:
    dw $04A5  ; Text $04A5: "As the Starry Night nears, it makes even"
    dw $FFFF  ; END

Bank0C_ScriptAddr_70AB:
    dw $07B5  ; Text $07B5: "Vault. May I help you? // Something else"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script35
; ---------------------------------------------------------------------------
Farm_Script35:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0C_ScriptAddr_70D3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0C_ScriptAddr_70CF          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw Bank0C_ScriptAddr_70C7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $006A  ; Text $006A: "Thwack! It was the egg of a SkyDragon th"
    dw Bank0C_ScriptAddr_70CB          ; -> branch target
Bank0C_ScriptAddr_70C7:
    dw $02DB
    dw $FFFF  ; END

Bank0C_ScriptAddr_70CB:
    dw $0385  ; Text $0385: "Down below, behind the Gtae of Temptatio"
    dw $FFFF  ; END

Bank0C_ScriptAddr_70CF:
    dw $04A6  ; Text $04A6: "Power is flowing all around me! Watch me"
    dw $FFFF  ; END

Bank0C_ScriptAddr_70D3:
    dw $07B6  ; Text $07B6: "Vault. May I help you? // Something else"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script36
; ---------------------------------------------------------------------------
Farm_Script36:
    dw $FF01  ; BranchIfFlagSet
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw Bank0C_ScriptAddr_7111          ; -> branch target
    dw $0368  ; Text $0368: "KingOh [HERO]! You beat Servant! KingWha"
    dw $FF03  ; SetEventFlag
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0090
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $001A  ; Text $001A: "[HERO] opened a treasure chest! // [HERO"
    dw $0090
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FFFF  ; END

Bank0C_ScriptAddr_7111:
    dw $0338  ; Text $0338: "That man always looks the same but... He"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script37
; ---------------------------------------------------------------------------
Farm_Script37:
    dw $0508  ; Text $0508: "TERRY?No. It's okay... I know... // Good"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script38
; ---------------------------------------------------------------------------
Farm_Script38:
    dw $0509  ; Text $0509: "Good luck on your journey! // TERRY?Ahhh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0C_ScriptAddr_7127          ; -> branch target
    dw $050A  ; Text $050A: "TERRY?Ahhh... For some reason, I feel re"
    dw $FFFF  ; END

Bank0C_ScriptAddr_7127:
    dw $050B  ; Text $050B: "TERRY?[HERO], don't become like me. TERR"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script39
; ---------------------------------------------------------------------------
Farm_Script39:
    dw $050C  ; Text $050C: "TERRY?Farewell [HERO]! I'm taking off. T"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script40
; ---------------------------------------------------------------------------
Farm_Script40:
    dw $050D  ; Text $050D: "TERRY?Take care of your sister. No matte"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script41
; ---------------------------------------------------------------------------
Farm_Script41:
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "This kingdom is created inside a big tre"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0F  ; SetScreenScroll
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $0198  ; Text $0198: "[HERO] looked at the bookshelf. My resea"
    dw $00D8
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script42
; ---------------------------------------------------------------------------
Farm_Script42:
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "This kingdom is created inside a big tre"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0F  ; SetScreenScroll
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw $0118  ; Text $0118: "I bet you wanna know. // You can meet he"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Stable Per-Script Table (map_type=$05, 0 scripts)
; ---------------------------------------------------------------------------
Stable_ScriptPtrTable:
    dw $71F9
    dw $71FB
    dw $7213
    dw $7217
    dw $722F
    dw $7257
    dw $7283
    dw $72A5
    dw $72D1
    dw $7331
    dw $7359
    dw $7383
    dw $73AB
    dw $73C3
    dw $73DB
    dw $73FB
    dw $742B
    dw $75BB
    dw $75BF
    dw $75D7
    dw $7647
    dw $FFFF  ; END

    db $01
    db $FF
    db $34
    db $00
    db $0F
    db $72
    db $01
    db $FF
    db $33
    db $00
    db $0B
    db $72
    db $0E
    db $02
    db $FF
    db $FF
    db $7A
    db $02
    db $FF
    db $FF
    db $3E
    db $03
    db $FF
    db $FF
    db $0F
    db $02
    db $FF
    db $FF
    db $01
    db $FF
    db $34
    db $00
    db $2B
    db $72
    db $01
    db $FF
    db $33
    db $00
    db $27
    db $72
    db $10
    db $02
    db $FF
    db $FF
    db $7B
    db $02
    db $FF
    db $FF
    db $3F
    db $03
    db $FF
    db $FF
    db $00
    db $FF
    db $22
    db $00
    db $41
    db $72
    db $01
    db $FF
    db $F1
    db $00
    db $53
    db $72
    db $01
    db $FF
    db $25
    db $00
    db $4F
    db $72
    db $01
    db $FF
    db $22
    db $00
    db $4B
    db $72
    db $89
    db $03
    db $FF
    db $FF
    db $8A
    db $03
    db $FF
    db $FF
    db $A9
    db $04
    db $FF
    db $FF
    db $BA
    db $07
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $7F
    db $72
    db $01
    db $FF
    db $25
    db $00
    db $7B
    db $72
    db $01
    db $FF
    db $37
    db $00
    db $77
    db $72
    db $01
    db $FF
    db $36
    db $00
    db $73
    db $72
    db $86
    db $03
    db $FF
    db $FF
    db $EC
    db $03
    db $FF
    db $FF
    db $48
    db $04
    db $FF
    db $FF
    db $A7
    db $04
    db $FF
    db $FF
    db $B7
    db $07
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $A1
    db $72
    db $01
    db $FF
    db $37
    db $00
    db $9D
    db $72
    db $01
    db $FF
    db $36
    db $00
    db $99
    db $72
    db $87
    db $03
    db $FF
    db $FF
    db $ED
    db $03
    db $FF
    db $FF
    db $49
    db $04
    db $FF
    db $FF
    db $B8
    db $07
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $CD
    db $72
    db $01
    db $FF
    db $25
    db $00
    db $C9
    db $72
    db $01
    db $FF
    db $37
    db $00
    db $C5
    db $72
    db $01
    db $FF
    db $36
    db $00
    db $C1
    db $72
    db $88
    db $03
    db $FF
    db $FF
    db $EE
    db $03
    db $FF
    db $FF
    db $4A
    db $04
    db $FF
    db $FF
    db $A8
    db $04
    db $FF
    db $FF
    db $B9
    db $07
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $2D
    db $73
    db $00
    db $FF
    db $83
    db $00
    db $F5
    db $72
    db $00
    db $FF
    db $1E
    db $01
    db $EF
    db $72
    db $00
    db $FF
    db $25
    db $00
    db $EF
    db $72
    db $01
    db $FF
    db $20
    db $01
    db $29
    db $73
    db $01
    db $FF
    db $1E
    db $01
    db $25
    db $73
    db $01
    db $FF
    db $83
    db $00
    db $21
    db $73
    db $01
    db $FF
    db $7C
    db $00
    db $1D
    db $73
    db $01
    db $FF
    db $1D
    db $00
    db $0B
    db $73
    db $11
    db $02
    db $FF
    db $FF
    db $DC
    db $02
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $19
    db $73
    db $DD
    db $02
    db $FF
    db $FF
    db $DE
    db $02
    db $FF
    db $FF
    db $DF
    db $02
    db $FF
    db $FF
    db $8B
    db $03
    db $FF
    db $FF
    db $8C
    db $03
    db $FF
    db $FF
    db $AA
    db $04
    db $FF
    db $FF
    db $BB
    db $07
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $55
    db $73
    db $00
    db $FF
    db $22
    db $00
    db $43
    db $73
    db $01
    db $FF
    db $25
    db $00
    db $51
    db $73
    db $01
    db $FF
    db $22
    db $00
    db $4D
    db $73
    db $8D
    db $03
    db $FF
    db $FF
    db $8E
    db $03
    db $FF
    db $FF
    db $AB
    db $04
    db $FF
    db $FF
    db $BC
    db $07
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $7D
    db $73
    db $00
    db $FF
    db $22
    db $00
    db $6B
    db $73
    db $01
    db $FF
    db $25
    db $00
    db $79
    db $73
    db $01
    db $FF
    db $22
    db $00
    db $75
    db $73
    db $8F
    db $03
    db $FF
    db $FF
    db $90
    db $03
    db $FF
    db $FF
    db $AC
    db $04
    db $FF
    db $FF
    db $BD
    db $07
    db $BE
    db $07
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $A7
    db $73
    db $00
    db $FF
    db $22
    db $00
    db $95
    db $73
    db $01
    db $FF
    db $25
    db $00
    db $A3
    db $73
    db $01
    db $FF
    db $22
    db $00
    db $9F
    db $73
    db $91
    db $03
    db $FF
    db $FF
    db $92
    db $03
    db $FF
    db $FF
    db $AD
    db $04
    db $FF
    db $FF
    db $BF
    db $07
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $BF
    db $73
    db $01
    db $FF
    db $35
    db $00
    db $BB
    db $73
    db $19
    db $02
    db $FF
    db $FF
    db $9C
    db $03
    db $FF
    db $FF
    db $19
    db $02
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $D7
    db $73
    db $01
    db $FF
    db $35
    db $00
    db $D3
    db $73
    db $19
    db $02
    db $FF
    db $FF
    db $9C
    db $03
    db $FF
    db $FF
    db $19
    db $02
    db $FF
    db $FF
    db $01
    db $FF
    db $4E
    db $00
    db $F7
    db $73
    db $D1
    db $01
    db $2C
    db $FF
    db $F3
    db $73
    db $29
    db $01
    db $03
    db $FF
    db $4E
    db $00
    db $2A
    db $FF
    db $1E
    db $00
    db $FF
    db $FF
    db $D2
    db $01
    db $FF
    db $FF
    db $8A
    db $02
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $0D
    db $74
    db $01
    db $FF
    db $90
    db $00
    db $27
    db $74
    db $01
    db $FF
    db $35
    db $00
    db $11
    db $74
    db $1B
    db $02
    db $FF
    db $FF
    db $D1
    db $01
    db $2C
    db $FF
    db $23
    db $74
    db $9D
    db $03
    db $03
    db $FF
    db $90
    db $00
    db $2A
    db $FF
    db $1D
    db $00
    db $FF
    db $FF
    db $9E
    db $03
    db $FF
    db $FF
    db $8A
    db $02
    db $FF
    db $FF
    db $00
    db $FF
    db $2F
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $2E
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $2D
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $2C
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $2B
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $2A
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $29
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $28
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $27
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $26
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $25
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $24
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $23
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $22
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $21
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $20
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $1F
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $1E
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $1D
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $1C
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $1B
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $1A
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $19
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $18
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $17
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $16
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $15
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $14
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $13
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $12
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $11
    db $00
    db $F1
    db $74
    db $00
    db $FF
    db $10
    db $00
    db $F1
    db $74
    db $01
    db $FF
    db $FB
    db $00
    db $67
    db $75
    db $01
    db $FF
    db $FB
    db $00
    db $63
    db $75
    db $01
    db $FF
    db $F1
    db $00
    db $5B
    db $75
    db $01
    db $FF
    db $4D
    db $00
    db $19
    db $75
    db $01
    db $FF
    db $4C
    db $00
    db $11
    db $75
    db $12
    db $02
    db $03
    db $FF
    db $4C
    db $00
    db $FF
    db $FF
    db $13
    db $02
    db $03
    db $FF
    db $4D
    db $00
    db $FF
    db $FF
    db $14
    db $02
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $25
    db $75
    db $15
    db $02
    db $16
    db $02
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $00
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $05
    db $00
    db $00
    db $00
    db $49
    db $FF
    db $03
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $13
    db $FF
    db $E3
    db $D8
    db $03
    db $00
    db $1C
    db $FF
    db $03
    db $17
    db $19
    db $FF
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $40
    db $00
    db $12
    db $FF
    db $47
    db $D9
    db $01
    db $00
    db $FF
    db $FF
    db $C0
    db $07
    db $03
    db $FF
    db $FB
    db $00
    db $FF
    db $FF
    db $C1
    db $07
    db $FF
    db $FF
    db $C2
    db $07
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $B3
    db $75
    db $28
    db $FF
    db $B7
    db $75
    db $C5
    db $07
    db $03
    db $FF
    db $FC
    db $00
    db $29
    db $FF
    db $DF
    db $00
    db $12
    db $FF
    db $47
    db $D9
    db $01
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $00
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $05
    db $00
    db $00
    db $00
    db $49
    db $FF
    db $03
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $13
    db $FF
    db $E3
    db $D8
    db $03
    db $00
    db $1C
    db $FF
    db $03
    db $17
    db $19
    db $FF
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $40
    db $00
    db $FF
    db $FF
    db $C3
    db $07
    db $FF
    db $FF
    db $C4
    db $07
    db $FF
    db $FF
    db $18
    db $02
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $D3
    db $75
    db $01
    db $FF
    db $34
    db $00
    db $CF
    db $75
    db $17
    db $02
    db $FF
    db $FF
    db $40
    db $03
    db $FF
    db $FF
    db $C6
    db $07
    db $FF
    db $FF
    db $01
    db $FF
    db $8E
    db $00
    db $F3
    db $75
    db $01
    db $FF
    db $8D
    db $00
    db $EB
    db $75
    db $93
    db $03
    db $03
    db $FF
    db $8D
    db $00
    db $FF
    db $FF
    db $94
    db $03
    db $03
    db $FF
    db $8E
    db $00
    db $FF
    db $FF
    db $95
    db $03
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $05
    db $76
    db $96
    db $03
    db $97
    db $03
    db $14
    db $FF
    db $13
    db $76
    db $98
    db $03
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $05
    db $76
    db $99
    db $03
    db $9A
    db $03
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $00
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $05
    db $00
    db $00
    db $00
    db $49
    db $FF
    db $03
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $13
    db $FF
    db $E3
    db $D8
    db $03
    db $00
    db $1C
    db $FF
    db $03
    db $17
    db $19
    db $FF
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $40
    db $00
    db $12
    db $FF
    db $47
    db $D9
    db $03
    db $00
    db $FF
    db $FF
    db $01
    db $FF
    db $F1
    db $00
    db $6F
    db $76
    db $01
    db $FF
    db $25
    db $00
    db $6B
    db $76
    db $01
    db $FF
    db $37
    db $00
    db $67
    db $76
    db $01
    db $FF
    db $36
    db $00
    db $63
    db $76
    db $9B
    db $03
    db $FF
    db $FF
    db $F0
    db $03
    db $FF
    db $FF
    db $4C
    db $04
    db $FF
    db $FF
    db $AE
    db $04
    db $FF
    db $FF
    db $C6
    db $07
    db $FF
    db $FF
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
