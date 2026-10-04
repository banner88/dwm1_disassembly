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
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_4246          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw Bank0C_ScriptAddr_41FC          ; -> branch target
    dw $FFFF  ; END

Bank0C_ScriptAddr_41FC:
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $4212
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw $41FA
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
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
; S101 r3: Castle_Script00 screen 1 = the CASTLE ARRIVAL dispatch on $D92B
; (the arrival-event code; PyBoy-measured): 0 / 4 -> $4270 (new-game intro +
; story cascade), 6 -> $490A (priest: GreatTree blessing + heal — written by bank
; $07 for the gate return; 8 = the same path, written by bank $50 after a lost
; battle and bank $06), 7 -> $47E0 (a gate boss was beaten: the King's speech
; chain on $D9E3), 1-3/5 -> no event. (The "PlaySE" names below are op $15
; cond_branch [addr] == value.)
Bank0C_ScriptAddr_4246:
    dw $FF15  ; PlaySE
    dw $D92B  ; RAM $D92B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $4270
    dw $FF15  ; PlaySE
    dw $D92B  ; RAM $D92B
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $4270
    dw $FF15  ; PlaySE
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $490A
    dw $FF15  ; PlaySE
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $47E0
    dw $FF15  ; PlaySE
    dw $D92B  ; RAM $D92B
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
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
; ---- $0C:$4804 (S101 r3, PyBoy-measured) — CASTLE ARRIVAL, $D92B = 7 (a gate boss
; was beaten): the King's speech chain. cond_branch $D9E3 == code -> that gate's
; speech ($30 Healer … $4E DeathMore, $C7 Sidoh, $10 Copycat; the vanilla boss win
; tails write the code). No saved flag changes in any speech; each ends with
; $D92B := 3 (or 5 for the post-game codes). An unknown code falls to the $490A
; priest path. The editor's helper step "at the Castle: King's speech" writes
; $D9E3 + $D92B = 7 before its $3B warp (PROJECT_COMPILER §2.18).
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
; ---- $0C:$5066 (S101 r3, ROM scan) — the ONLY other $D9E3 reader: a castle NPC's
; talk. $30 -> "These stairs go up to the monster farm"; $3C -> write $C88A/$C88B
; = 3, op $3E, "The shaking of GreatTree has changed…" (story event); else the herb
; gift (give_item 1, or the inventory-full line).
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
    dw $0024  ; Text $0024: "$42:$522C [HERO] looked at the bookshelf. // :The "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_50FB          ; -> branch target
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw $FFFF  ; END

Bank0C_ScriptAddr_50FB:
    dw $0026  ; Text $0026: "$42:$53F1 [HERO] returned the book to the // books"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script02
; ---------------------------------------------------------------------------
Castle_Script02:
    dw $0027  ; Text $0027: "$42:$541E [HERO] looked at the bookshelf. // The M"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_510D          ; -> branch target
    dw $0028  ; Text $0028: "$42:$5474 :People who understand monster // talk a"
    dw $FFFF  ; END

Bank0C_ScriptAddr_510D:
    dw $0026  ; Text $0026: "$42:$53F1 [HERO] returned the book to the // books"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script03
; ---------------------------------------------------------------------------
Castle_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $003A  ; Text $003A: "$42:$5ED1 [HERO] looked into the jar."
    dw Bank0C_ScriptAddr_5183          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $003B  ; Text $003B: "$42:$5EEB [HERO] looked into the jar. // The jar i"
    dw Bank0C_ScriptAddr_5155          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw Bank0C_ScriptAddr_5127          ; -> branch target
    dw $0379  ; Text $0379: "$46:$728B [HERO] checked out the treasure // chest"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5127:
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF24  ; Cmd24
    dw $5187
    dw $FF07  ; InitDialogMode
    dw $001B  ; Text $001B: "$42:$4C50 [HERO] opened a treasure chest!"
    dw $FF2C  ; CheckInvFull
    dw $5149
    dw $001C  ; Text $001C: "$42:$4C6E [HERO] picked up an Herb."
    dw $FF03  ; SetEventFlag
    dw $003A  ; Text $003A: "$42:$5ED1 [HERO] looked into the jar."
    dw $FF12  ; WriteRAM
    dw $D92A  ; RAM $D92A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF2A  ; GiveItem
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF24  ; Cmd24
    dw $5187
    dw $FF07  ; InitDialogMode
    dw $001B  ; Text $001B: "$42:$4C50 [HERO] opened a treasure chest!"
    dw $FF2C  ; CheckInvFull
    dw $5177
    dw $001C  ; Text $001C: "$42:$4C6E [HERO] picked up an Herb."
    dw $FF03  ; SetEventFlag
    dw $003A  ; Text $003A: "$42:$5ED1 [HERO] looked into the jar."
    dw $FF12  ; WriteRAM
    dw $D92A  ; RAM $D92A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF2A  ; GiveItem
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $013C  ; Text $013C: "$43:$652B [HERO] looked in the treasure chest // I"
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
    dw $003B  ; Text $003B: "$42:$5EEB [HERO] looked into the jar. // The jar i"
    dw Bank0C_ScriptAddr_5203          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $003A  ; Text $003A: "$42:$5ED1 [HERO] looked into the jar."
    dw Bank0C_ScriptAddr_51D5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw Bank0C_ScriptAddr_51A7          ; -> branch target
    dw $0379  ; Text $0379: "$46:$728B [HERO] checked out the treasure // chest"
    dw $FFFF  ; END

Bank0C_ScriptAddr_51A7:
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF24  ; Cmd24
    dw $5207
    dw $FF07  ; InitDialogMode
    dw $001E  ; Text $001E: "$42:$4CEA [HERO] opened a treasure chest!"
    dw $FF2C  ; CheckInvFull
    dw $51C9
    dw $0127  ; Text $0127: "$43:$6083 [HERO] got an Herb."
    dw $FF03  ; SetEventFlag
    dw $003B  ; Text $003B: "$42:$5EEB [HERO] looked into the jar. // The jar i"
    dw $FF12  ; WriteRAM
    dw $D92A  ; RAM $D92A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF2A  ; GiveItem
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF24  ; Cmd24
    dw $5207
    dw $FF07  ; InitDialogMode
    dw $001E  ; Text $001E: "$42:$4CEA [HERO] opened a treasure chest!"
    dw $FF2C  ; CheckInvFull
    dw $51F7
    dw $0127  ; Text $0127: "$43:$6083 [HERO] got an Herb."
    dw $FF03  ; SetEventFlag
    dw $003B  ; Text $003B: "$42:$5EEB [HERO] looked into the jar. // The jar i"
    dw $FF12  ; WriteRAM
    dw $D92A  ; RAM $D92A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF2A  ; GiveItem
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $013C  ; Text $013C: "$43:$652B [HERO] looked in the treasure chest // I"
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
    dw $083B  ; Text $083B: "$3F:$6454 *:[HERO] looked in front."
    dw $FF2C  ; CheckInvFull
    dw Bank0C_ScriptAddr_521F          ; -> branch target
    dw $083C  ; Text $083C: "$3F:$646B Wow, a Sirloin!"
    dw $FF2A  ; GiveItem
    dw $0017  ; Text $0017: "$42:$4BD7 *:Please listen to his wish."
    dw $FFFF  ; END

Bank0C_ScriptAddr_521F:
    dw $083D  ; Text $083D: "$3F:$647E Wow, found a Sirloin! But can't // carry"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script06
; ---------------------------------------------------------------------------
Castle_Script06:
    dw $083B  ; Text $083B: "$3F:$6454 *:[HERO] looked in front."
    dw $FF2C  ; CheckInvFull
    dw Bank0C_ScriptAddr_5231          ; -> branch target
    dw $083E  ; Text $083E: "$3F:$64CE Got a WarpWing."
    dw $FF2A  ; GiveItem
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5231:
    dw $083D  ; Text $083D: "$3F:$647E Wow, found a Sirloin! But can't // carry"
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
    dw $01E0  ; Text $01E0: "$44:$713F *:I heard monsters of the bugs family //"
    dw $FF27  ; Cmd27
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script09
; ---------------------------------------------------------------------------
Castle_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5273          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_526F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_525D          ; -> branch target
    dw $0023  ; Text $0023: "$42:$51DB *:I have a feeling that your // victory "
    dw $FFFF  ; END

Bank0C_ScriptAddr_525D:
    dw $01E4  ; Text $01E4: "$44:$734D *:Let me tell you. [YES/NO]"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $526B
    dw $01E6  ; Text $01E6: "$44:$738A *:The family of the monster you // chose"
    dw $FFFF  ; END

    db $E5
    db $01
    db $FF
    db $FF
Bank0C_ScriptAddr_526F:
    dw $040F  ; Text $040F: "$21:$489E *:We clowns hustle on the Starry // Nigh"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5273:
    dw $05BB
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script10
; ---------------------------------------------------------------------------
Castle_Script10:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_52CD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0118  ; Text $0118: "$43:$596B [HERO] read the blackboard. // :Masters "
    dw Bank0C_ScriptAddr_52C9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_52AF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_529D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw Bank0C_ScriptAddr_5299          ; -> branch target
    dw $0022  ; Text $0022: "$42:$517B *:Everybody will be happy if you // beco"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5299:
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FFFF  ; END

Bank0C_ScriptAddr_529D:
    dw $01E7  ; Text $01E7: "$44:$748B *:Want to learn about breeding // monste"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $52AB
    dw $01E9  ; Text $01E9: "$44:$751E *:When monsters from the same // family "
    dw $FFFF  ; END

    db $E8
    db $01
    db $FF
    db $FF
Bank0C_ScriptAddr_52AF:
    dw $040B  ; Text $040B: "$21:$46FF *:Congratulations on your // participati"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $52C1
    dw $040C  ; Text $040C: "$21:$47D9 *:Oh my! Monster Master [HERO]! // I am "
    dw $FF03  ; SetEventFlag
    dw $0118  ; Text $0118: "$43:$596B [HERO] read the blackboard. // :Masters "
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
    dw $040E  ; Text $040E: "$21:$483B *:Breeding two child-like devils // crea"
    dw $FFFF  ; END

Bank0C_ScriptAddr_52CD:
    dw $05BA
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script11
; ---------------------------------------------------------------------------
Castle_Script11:
    dw $002A  ; Text $002A: "$42:$5608 King:The monster farm is on the // upper"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script12
; ---------------------------------------------------------------------------
Castle_Script12:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_52FD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_52F9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_52F5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw Bank0C_ScriptAddr_52F1          ; -> branch target
    dw $002F  ; Text $002F: "$42:$5A53 *:The tournament is held on the // Starr"
    dw $FFFF  ; END

Bank0C_ScriptAddr_52F1:
    dw $004F  ; Text $004F: "$42:$69A4 *:In the Chamber of Travelers' // Gates "
    dw $FFFF  ; END

Bank0C_ScriptAddr_52F5:
    dw $01F5  ; Text $01F5: "$44:$7C1E *:There's a reason why wild // monsters "
    dw $FFFF  ; END

Bank0C_ScriptAddr_52F9:
    dw $048C  ; Text $048C: "$48:$509C *:Long long ago.. an ancestor of // Wata"
    dw $FFFF  ; END

Bank0C_ScriptAddr_52FD:
    dw $05C1
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script13
; ---------------------------------------------------------------------------
Castle_Script13:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_54CD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00AC
    dw Bank0C_ScriptAddr_54BB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_54B3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_54A1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0C_ScriptAddr_5473          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_5445          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0C_ScriptAddr_5417          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_53E9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0C_ScriptAddr_53E5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_53B7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0C_ScriptAddr_5389          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0C_ScriptAddr_5369          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw Bank0C_ScriptAddr_5357          ; -> branch target
    dw $002C  ; Text $002C: "$42:$56FD *:Let me tell you about the legend // of"
    dw $FF03  ; SetEventFlag
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5357:
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5365
    dw $002E  ; Text $002E: "$42:$58EC *:Here it is again. // *:The Starry Nigh"
    dw $FFFF  ; END

    db $1A
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_5369:
    dw $0152  ; Text $0152: "$43:$6F0B *:Are you familiar with the Gate of // V"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5381
    dw $0154  ; Text $0154: "$43:$6FC4 *:Are you familiar with the Gate of // T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5385
    dw $0155  ; Text $0155: "$43:$6FFA *:I see...Hm.."
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
    dw $01A5  ; Text $01A5: "$44:$49EC *:Are you familiar with the Gate of // B"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $53AB
    dw $01A7  ; Text $01A7: "$44:$4ADD *:Are you familiar with the Gate of // M"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $53AF
    dw $01A9  ; Text $01A9: "$44:$4BD6 *:I would like to tell you more. // Do y"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $53B3
    dw $0155  ; Text $0155: "$43:$6FFA *:I see...Hm.."
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
    dw $01EC  ; Text $01EC: "$44:$7717 *:Are you familiar with the Gate of // B"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $53D9
    dw $01EE  ; Text $01EE: "$44:$77C9 Are you familiar with the Gate of // Pea"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $53DD
    dw $01A9  ; Text $01A9: "$44:$4BD6 *:I would like to tell you more. // Do y"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $53E1
    dw $0155  ; Text $0155: "$43:$6FFA *:I see...Hm.."
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
    dw $0274  ; Text $0274: "$45:$5654 *:The number of monsters is // increasin"
    dw $FFFF  ; END

Bank0C_ScriptAddr_53E9:
    dw $02B0  ; Text $02B0: "$45:$737A *:Are you familiar with the // Gate of A"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $540B
    dw $02B2  ; Text $02B2: "$45:$7420 *:Are you familiar with the Gate of // S"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $540F
    dw $01A9  ; Text $01A9: "$44:$4BD6 *:I would like to tell you more. // Do y"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5413
    dw $0155  ; Text $0155: "$43:$6FFA *:I see...Hm.."
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
    dw $0332  ; Text $0332: "$46:$5462 *:Do you know of the Gate of // Wisdom? "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5439
    dw $0334  ; Text $0334: "$46:$5531 *:Are you familiar with the Gate of // J"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $543D
    dw $01A9  ; Text $01A9: "$44:$4BD6 *:I would like to tell you more. // Do y"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5441
    dw $0155  ; Text $0155: "$43:$6FFA *:I see...Hm.."
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
    dw $0361  ; Text $0361: "$46:$6718 Do you know of the Gate of // Happiness?"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5467
    dw $0363  ; Text $0363: "$46:$680E *:Are you familiar with the Gate // of T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $546B
    dw $01A9  ; Text $01A9: "$44:$4BD6 *:I would like to tell you more. // Do y"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $546F
    dw $0155  ; Text $0155: "$43:$6FFA *:I see...Hm.."
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
    dw $03E0  ; Text $03E0: "$47:$4B56 *:Are you familiar with the Gate of // L"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5495
    dw $03E2  ; Text $03E2: "$47:$4C8D *:Do you know of the Gate of // Judgment"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5499
    dw $01A9  ; Text $01A9: "$44:$4BD6 *:I would like to tell you more. // Do y"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $549D
    dw $0155  ; Text $0155: "$43:$6FFA *:I see...Hm.."
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
    dw $0419  ; Text $0419: "$21:$4FF7 *:Do you want me to tell you the // lege"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $54AF
    dw $041B  ; Text $041B: "$21:$507A *:Far beyond the Gate, lives your // fut"
    dw $FFFF  ; END

    db $1A
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_54B3:
    dw $048A  ; Text $048A: "$48:$4EAF *:Let me tell you the legend of the // S"
    dw $FF03  ; SetEventFlag
    dw $00AC
    dw $FFFF  ; END

Bank0C_ScriptAddr_54BB:
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $54C9
    dw $002E  ; Text $002E: "$42:$58EC *:Here it is again. // *:The Starry Nigh"
    dw $FFFF  ; END

    db $8B
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_54CD:
    dw $05BE
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $002F  ; Text $002F: "$42:$5A53 *:The tournament is held on the // Starr"
    dw Bank0C_ScriptAddr_54EB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0111  ; Text $0111: "$43:$547D *:I am Medal Man, the medal // collector"
    dw Bank0C_ScriptAddr_5567          ; -> branch target
Bank0C_ScriptAddr_54EB:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5563          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_555F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_555B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_5557          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_5553          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0C_ScriptAddr_554F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0049  ; Text $0049: "$42:$6651 King:Arrgh! You! You let my // precious "
    dw Bank0C_ScriptAddr_554B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_5547          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0C_ScriptAddr_5543          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0C_ScriptAddr_553F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw Bank0C_ScriptAddr_553B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw Bank0C_ScriptAddr_5537          ; -> branch target
    dw $002B  ; Text $002B: "$42:$5677 *:My kingdom has been losing // in the S"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5537:
    dw $004D  ; Text $004D: "$42:$68DF *:His Majesty seems to be // very upset."
    dw $FFFF  ; END

Bank0C_ScriptAddr_553B:
    dw $005E  ; Text $005E: "$42:$736B *:To get to the arena, go straight // ou"
    dw $FFFF  ; END

Bank0C_ScriptAddr_553F:
    dw $014C  ; Text $014C: "$43:$6B82 *:The Room of Villager & // Talisman is "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5543:
    dw $01A4  ; Text $01A4: "$44:$48D8 *:Congratulations on surviving F // clas"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5547:
    dw $01EA  ; Text $01EA: "$44:$7635 *:Congratulation on surviving E // class"
    dw $FFFF  ; END

Bank0C_ScriptAddr_554B:
    dw $01EB  ; Text $01EB: "$44:$7698 *:[HERO]! Doing good huh? // *:The Room "
    dw $FFFF  ; END

Bank0C_ScriptAddr_554F:
    dw $0273  ; Text $0273: "$45:$5564 *:The Gate of Anger seems // strange! //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5553:
    dw $02AF  ; Text $02AF: "$45:$72AE *:The shaking of GreatTree has // change"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5557:
    dw $0360  ; Text $0360: "$46:$66A8 *:[HERO], why don't you go to // the Baz"
    dw $FFFF  ; END

Bank0C_ScriptAddr_555B:
    dw $0418  ; Text $0418: "$21:$4F4F *:The King fears for your future, // Mas"
    dw $FFFF  ; END

Bank0C_ScriptAddr_555F:
    dw $0489  ; Text $0489: "$48:$4E5A *:Now, head to the arena! // *:A great a"
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
    dw $0050  ; Text $0050: "$42:$6ABA Pulio:Sorry [HERO], It's my fault... // "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script16
; ---------------------------------------------------------------------------
Castle_Script16:
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw Bank0C_ScriptAddr_5583          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0C_ScriptAddr_557F          ; -> branch target
    dw $0016  ; Text $0016: "$42:$4B9C *:His Majesty is in trouble. // Please p"
    dw $FFFF  ; END

Bank0C_ScriptAddr_557F:
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5583:
    dw $0051  ; Text $0051: "$42:$6B5B *:These stairs bring you to the // Chamb"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script17
; ---------------------------------------------------------------------------
Castle_Script17:
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw Bank0C_ScriptAddr_55A5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw Bank0C_ScriptAddr_55A1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0C_ScriptAddr_559D          ; -> branch target
    dw $0017  ; Text $0017: "$42:$4BD7 *:Please listen to his wish."
    dw $FFFF  ; END

Bank0C_ScriptAddr_559D:
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw $FFFF  ; END

Bank0C_ScriptAddr_55A1:
    dw $0052  ; Text $0052: "$42:$6BA3 *:Please bring Hale back as soon // as p"
    dw $FFFF  ; END

Bank0C_ScriptAddr_55A5:
    dw $005F  ; Text $005F: "$42:$73FE *:These stairs go up to the // monster f"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Castle_Script18
; ---------------------------------------------------------------------------
Castle_Script18:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_55E5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_55E1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0C_ScriptAddr_55DD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_55D9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_55D5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw Bank0C_ScriptAddr_55D1          ; -> branch target
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $FFFF  ; END

Bank0C_ScriptAddr_55D1:
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_55D5:
    dw $01F6  ; Text $01F6: "$44:$7D92 *:You are at the castle of // GreatTree."
    dw $FFFF  ; END

Bank0C_ScriptAddr_55D9:
    dw $02B9  ; Text $02B9: "$45:$7788 *:You're at the castle of // GreatTree. "
    dw $FFFF  ; END

Bank0C_ScriptAddr_55DD:
    dw $0857
    dw $FFFF  ; END

Bank0C_ScriptAddr_55E1:
    dw $048D  ; Text $048D: "$48:$51AA *:You're at the castle of // GreatTree. "
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
    dw $001E  ; Text $001E: "$42:$4CEA [HERO] opened a treasure chest!"
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
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0C_ScriptAddr_5641          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0C_ScriptAddr_5799          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_5847          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw Bank0C_ScriptAddr_587F          ; -> branch target
    dw $FFFF  ; END

Bank0C_ScriptAddr_5641:
    dw $FF0E  ; SetMapTransition
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $565B
    dw $FF0E  ; SetMapTransition
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $56BD
    dw $FF0E  ; SetMapTransition
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $56D7
    dw $FF0E  ; SetMapTransition
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
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
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw $57B7
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw $57D9
    dw $FF01  ; BranchIfFlagSet
    dw $000A  ; Text $000A: "$42:$45C1 *:You speak monster talk // don't you? /"
    dw $57B7
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw $57B9
    dw $FF01  ; BranchIfFlagSet
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $0021  ; Text $0021: "$42:$4D91 King:Oh [HERO]! Will you comply // with "
    dw $5865
    dw $FF00  ; BranchIfFlagClear
    dw $011E  ; Text $011E: "$43:$5CAD *:I'm Mick. Who are you? // *:Whew, thos"
    dw $5859
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw $5873
    dw $FF01  ; BranchIfFlagSet
    dw $0043  ; Text $0043: "$42:$6466 Slio:Dn'a wanna know about the // farm? "
    dw $5865
    dw $FF01  ; BranchIfFlagSet
    dw $011E  ; Text $011E: "$43:$5CAD *:I'm Mick. Who are you? // *:Whew, thos"
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
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw $588B
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
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
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0C_ScriptAddr_5927          ; -> branch target
    dw $0019  ; Text $0019: "$42:$4C22 *:Hurry! Go see the King!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5927:
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script02
; ---------------------------------------------------------------------------
GreatTree_Script02:
    dw $001F  ; Text $001F: "$42:$4D08 *:This is the Kingdom of // GreatTree!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script03
; ---------------------------------------------------------------------------
GreatTree_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_596F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $009B
    dw Bank0C_ScriptAddr_596B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_5963          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_595F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_595B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_5957          ; -> branch target
    dw $012F  ; Text $012F: "$43:$6271 *:We can see the ground far below. // *:"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5957:
    dw $01F7  ; Text $01F7: "$44:$7E4A *:Wishing upon the stars on // Starry Ni"
    dw $FFFF  ; END

Bank0C_ScriptAddr_595B:
    dw $02BA  ; Text $02BA: "$45:$780B *:A long time ago, the ancestor of // Wa"
    dw $FFFF  ; END

Bank0C_ScriptAddr_595F:
    dw $036B  ; Text $036B: "$46:$6C63 *:There must be some reason that.. // *:"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5963:
    dw $041C  ; Text $041C: "$21:$5154 *:So you became the master of // GreatTr"
    dw $FF03  ; SetEventFlag
    dw $009B
    dw $FFFF  ; END

Bank0C_ScriptAddr_596B:
    dw $041D  ; Text $041D: "$21:$51C0 *:The Starry Night is coming. The // tou"
    dw $FFFF  ; END

Bank0C_ScriptAddr_596F:
    dw $05D0
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script04
; ---------------------------------------------------------------------------
GreatTree_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5987          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_5983          ; -> branch target
    dw $0062  ; Text $0062: "$42:$74CA *:This is the village of // GreatTree. /"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5983:
    dw $048E  ; Text $048E: "$48:$51F7 *:Good luck at the Starry Night // Tourn"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5987:
    dw $05D1
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script05
; ---------------------------------------------------------------------------
GreatTree_Script05:
    dw $0063  ; Text $0063: "$42:$7527 *:Fhew! I'm glad that I didn't get // hu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script06
; ---------------------------------------------------------------------------
GreatTree_Script06:
    dw $0064  ; Text $0064: "$42:$756F *:Oh [HERO], it's you. // I am getting o"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script07
; ---------------------------------------------------------------------------
GreatTree_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_59C9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $009C  ; Text $009C: "$1A:$4BDA *:Don't be afraid of monsters you // hav"
    dw Bank0C_ScriptAddr_59C5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_59BD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_59B9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_59B5          ; -> branch target
    dw $01AF  ; Text $01AF: "$44:$4FA7 *:The girl down below who blocked // a p"
    dw $FFFF  ; END

Bank0C_ScriptAddr_59B5:
    dw $02BB  ; Text $02BB: "$45:$787B *:I often see the girl who stood in // t"
    dw $FFFF  ; END

Bank0C_ScriptAddr_59B9:
    dw $036C  ; Text $036C: "$46:$6CC8 *:Hey, the tournament is // coming! Good"
    dw $FFFF  ; END

Bank0C_ScriptAddr_59BD:
    dw $041E  ; Text $041E: "$21:$5205 *:Hey, I heard you became the rep! // Yo"
    dw $FF03  ; SetEventFlag
    dw $009C  ; Text $009C: "$1A:$4BDA *:Don't be afraid of monsters you // hav"
    dw $FFFF  ; END

Bank0C_ScriptAddr_59C5:
    dw $041F  ; Text $041F: "$21:$529E *:Just competing in the Starry // Night "
    dw $FFFF  ; END

Bank0C_ScriptAddr_59C9:
    dw $05D2
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script08
; ---------------------------------------------------------------------------
GreatTree_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5A19          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_5A07          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $000B  ; Text $000B: "$42:$476A Terry looks at the bookshelf. // :Encycl"
    dw Bank0C_ScriptAddr_59F5          ; -> branch target
    dw $012B  ; Text $012B: "$43:$617F *:Hey you, do you have a TinyMedal? [YES"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_59F1          ; -> branch target
    dw $012D  ; Text $012D: "$43:$61EB *:I see. Go to the room above then. // *"
    dw $FF03  ; SetEventFlag
    dw $000B  ; Text $000B: "$42:$476A Terry looks at the bookshelf. // :Encycl"
    dw $FFFF  ; END

Bank0C_ScriptAddr_59F1:
    dw $012C  ; Text $012C: "$43:$61A6 *:You don't have it? What are you // doi"
    dw $FFFF  ; END

Bank0C_ScriptAddr_59F5:
    dw $012B  ; Text $012B: "$43:$617F *:Hey you, do you have a TinyMedal? [YES"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5A03
    dw $012E  ; Text $012E: "$43:$624A *:Great! Go to the room above then."
    dw $FFFF  ; END

    db $2C
    db $01
    db $FF
    db $FF
Bank0C_ScriptAddr_5A07:
    dw $012B  ; Text $012B: "$43:$617F *:Hey you, do you have a TinyMedal? [YES"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5A15
    dw $0490  ; Text $0490: "$48:$52CC *:Bring them to the Medal Man // upstair"
    dw $FFFF  ; END

    db $8F
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_5A19:
    dw $05D3
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5A67          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_5A63          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_5A5F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_5A5B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_5A57          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_5A53          ; -> branch target
    dw $0065  ; Text $0065: "$42:$75F1 *:Once I picked up a TinyMedal, // *:bac"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A53:
    dw $01F8  ; Text $01F8: "$44:$7E9F *:GreatLog is the closest country // to "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A57:
    dw $02BC  ; Text $02BC: "$45:$78F3 *:The Kingdom of DeadTree is almost // d"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A5B:
    dw $036D  ; Text $036D: "$46:$6D33 *:One of my relatives is // living in th"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A5F:
    dw $0420  ; Text $0420: "$21:$5307 *:Many people are heading to // GreatTre"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A63:
    dw $0491  ; Text $0491: "$48:$533F *:Many people are heading to // GreatTre"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A67:
    dw $05D6
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script10
; ---------------------------------------------------------------------------
GreatTree_Script10:
    dw $0157  ; Text $0157: "$43:$7097 *:Who do you think you are! What? // You"
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script11
; ---------------------------------------------------------------------------
GreatTree_Script11:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5A87          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_5A83          ; -> branch target
    dw $0159  ; Text $0159: "$43:$7142 *:{AC} is added to the monster level // "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A83:
    dw $0492  ; Text $0492: "$48:$53B5 *:Watabou will be happy if you // win! /"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5A87:
    dw $05D7  ; Text $05D7: "$18:$6BB0 *:The victorious master // eventually be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script12
; ---------------------------------------------------------------------------
GreatTree_Script12:
    dw $0158  ; Text $0158: "$43:$7107 *:Almost there to the bottom! // *:What "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script13
; ---------------------------------------------------------------------------
GreatTree_Script13:
    dw $FF01  ; BranchIfFlagSet
    dw $0114  ; Text $0114: "$43:$562E *:Sometimes monsters you beat // will be"
    dw Bank0C_ScriptAddr_5ACF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5AC7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_5AC3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_5ABF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_5ABB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_5AB7          ; -> branch target
    dw $01B0  ; Text $01B0: "$44:$5005 *:I want you to win the tournament // th"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5AB7:
    dw $02BD  ; Text $02BD: "$45:$795E *:I want us to win this time! // *:The S"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5ABB:
    dw $036E  ; Text $036E: "$46:$6D7B *:To tell the truth, Watabou // hasn't b"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5ABF:
    dw $0421  ; Text $0421: "$21:$5379 *:You'll win! I can feel it! // *:I hear"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5AC3:
    dw $0493  ; Text $0493: "$48:$542C *:You can win! ...I feel it! // *:I hear"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5AC7:
    dw $05D8
    dw $FF03  ; SetEventFlag
    dw $0114  ; Text $0114: "$43:$562E *:Sometimes monsters you beat // will be"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5ACF:
    dw $084F
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script14
; ---------------------------------------------------------------------------
GreatTree_Script14:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5AE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_5AE3          ; -> branch target
    dw $015A  ; Text $015A: "$43:$71C9 *:Enter here to the Vault."
    dw $FFFF  ; END

Bank0C_ScriptAddr_5AE3:
    dw $0494  ; Text $0494: "$48:$54B9 *:Proceed to the Vault. Good luck!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5AE7:
    dw $05D9
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script15
; ---------------------------------------------------------------------------
GreatTree_Script15:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5B2B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00AD  ; Text $00AD: "$1A:$50DB *:Oh boy, oh boy. The fight is // always"
    dw Bank0C_ScriptAddr_5B27          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_5B1F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_5B1B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_5B17          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_5B13          ; -> branch target
    dw $015B  ; Text $015B: "$43:$71E7 *:The Bazaar's to the right!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B13:
    dw $02BE  ; Text $02BE: "$45:$79F3 *:Right to the Bazaar! There are // new "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B17:
    dw $036F  ; Text $036F: "$46:$6DED *:Bazaar to the right! A third // store "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B1B:
    dw $0422  ; Text $0422: "$21:$5407 *:Go right to the Bazaar! // More stores"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B1F:
    dw $0495  ; Text $0495: "$48:$54DF *:Go right to the Bazaar! // *:It's [HER"
    dw $FF03  ; SetEventFlag
    dw $00AD  ; Text $00AD: "$1A:$50DB *:Oh boy, oh boy. The fight is // always"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B27:
    dw $0496  ; Text $0496: "$48:$5524 *:Go right to the Bazaar! // *:Oh [HERO]"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B2B:
    dw $05DA
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script16
; ---------------------------------------------------------------------------
GreatTree_Script16:
    dw $FF01  ; BranchIfFlagSet
    dw $002F  ; Text $002F: "$42:$5A53 *:The tournament is held on the // Starr"
    dw Bank0C_ScriptAddr_5D8B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F4  ; Text $00F4: "$43:$49ED *:Darn! Again!"
    dw Bank0C_ScriptAddr_5D87          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0107  ; Text $0107: "$43:$5027 *:Want to hear about my journey // beyon"
    dw Bank0C_ScriptAddr_5D7F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0106  ; Text $0106: "$43:$500D *:Well,it'll be OK too."
    dw Bank0C_ScriptAddr_5D7F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F3  ; Text $00F3: "$43:$4928 *:Select your choice by stepping // on t"
    dw Bank0C_ScriptAddr_5D7B          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $00F2  ; Text $00F2: "$43:$4912 *:Hm, its not fun."
    dw Bank0C_ScriptAddr_5B59          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0105  ; Text $0105: "$43:$4FE2 *:Its the principal of the // school."
    dw Bank0C_ScriptAddr_5C4B          ; -> branch target
Bank0C_ScriptAddr_5B59:
    dw $FF01  ; BranchIfFlagSet
    dw $00F2  ; Text $00F2: "$43:$4912 *:Hm, its not fun."
    dw Bank0C_ScriptAddr_5C2B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5C23          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00AE  ; Text $00AE: "$1A:$5123 *:I want to help you // guys. // *:But I"
    dw Bank0C_ScriptAddr_5C11          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_5BFB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_5BF3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0C_ScriptAddr_5BD9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_5BD1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0C_ScriptAddr_5BC9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_5BAF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0C_ScriptAddr_5BA7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_5B9F          ; -> branch target
    dw $01B1  ; Text $01B1: "$44:$50F1 *:I heard you got stronger. // *:But I s"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5B9F:
    dw $01F9
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5BA7:
    dw $0277  ; Text $0277: "$45:$57C1 *:I heard you defeated Mick. // You're g"
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5BAF:
    dw $02BF
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5BC1
    dw $02C0
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
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
    dw $033C  ; Text $033C: "$46:$5888 *:What? You won C class? Shoo, // shoo! "
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5BD1:
    dw $0370  ; Text $0370: "$46:$6E26 *:You'll always be a loser! // What's wr"
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5BD9:
    dw $03E7  ; Text $03E7: "$47:$4F66 *:Hey are you really aiming // for S cla"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5BEB
    dw $03E8  ; Text $03E8: "$47:$4F97 *:You'll never get there with such // pa"
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
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
    dw $0423  ; Text $0423: "$21:$5441 *:Rep? A kid like you? Liar! // *:Helloo"
    dw $FF03  ; SetEventFlag
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5BFB:
    dw $0497  ; Text $0497: "$48:$5568 *:Are you... really competing // in the "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5C0D
    dw $0498  ; Text $0498: "$48:$55A1 *:...Don't lose."
    dw $FF03  ; SetEventFlag
    dw $00AE  ; Text $00AE: "$1A:$5123 *:I want to help you // guys. // *:But I"
    dw $FFFF  ; END

    db $9A
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_5C11:
    dw $0497  ; Text $0497: "$48:$5568 *:Are you... really competing // in the "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5C1F
    dw $0499  ; Text $0499: "$48:$55B5 *:...Don't lose. Don't make me say // it"
    dw $FFFF  ; END

    db $9B
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_5C23:
    dw $05DC
    dw $FF03  ; SetEventFlag
    dw $00F2  ; Text $00F2: "$43:$4912 *:Hm, its not fun."
    dw $FFFF  ; END

Bank0C_ScriptAddr_5C2B:
    dw $05DD  ; Text $05DD: "$18:$6EF3 *:I was... ...worried. // *:...Hey you! "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5C43
    dw $05DF  ; Text $05DF: "$18:$6F4E *:Then say it! [YES/NO]"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5C47
    dw $05E1  ; Text $05E1: "$4A:$42B0 *:I don't have such a name! // Don't lie"
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
    dw $05DD  ; Text $05DD: "$18:$6EF3 *:I was... ...worried. // *:...Hey you! "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5D73
    dw $05DF  ; Text $05DF: "$18:$6F4E *:Then say it! [YES/NO]"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5D77
    dw $05E2  ; Text $05E2: "$4A:$4339 *:Yep. It's Santi. How did you know? // "
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF1C  ; CompareRAM
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FF19  ; FadeEffect
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $0027  ; Text $0027: "$42:$541E [HERO] looked at the bookshelf. // The M"
    dw $5CB5
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $0028  ; Text $0028: "$42:$5474 :People who understand monster // talk a"
    dw $5CB5
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $0029  ; Text $0029: "$42:$55D7 *:I wanna be a master. // What should I "
    dw $5CB5
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF14  ; ClearGameFlags
    dw $5CDF
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFE0  ; Cmd$E0
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF19  ; FadeEffect
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $05E3  ; Text $05E3: "$4A:$437E Santi:Wait here for me!"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF21  ; TriggerBattle2
    dw $0051  ; Text $0051: "$42:$6B5B *:These stairs bring you to the // Chamb"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF21  ; TriggerBattle2
    dw $0051  ; Text $0051: "$42:$6B5B *:These stairs bring you to the // Chamb"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF07  ; InitDialogMode
    dw $05E4  ; Text $05E4: "$4A:$439A Santi:Talk to my Grandpa!!"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFB0  ; Cmd$B0
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF03  ; SetEventFlag
    dw $00F3  ; Text $00F3: "$43:$4928 *:Select your choice by stepping // on t"
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
    dw $05E5  ; Text $05E5: "$4A:$43B8 Santi:C'mon, go talk to my // Grandpa!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5D7F:
    dw $05E6  ; Text $05E6: "$4A:$43E5 Santi:You talked to my Grandpa, // right"
    dw $FF03  ; SetEventFlag
    dw $00F4  ; Text $00F4: "$43:$49ED *:Darn! Again!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5D87:
    dw $05E7  ; Text $05E7: "$4A:$445B Santi:Don't just stand there! // Go to t"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5D8B:
    dw $05E8  ; Text $05E8: "$4A:$449A Santi:Was the Travelers' Gate // useful "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5D99
    dw $05EA  ; Text $05EA: "$4A:$44E9 Santi:I...I'm... happy....blush."
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
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5DCB          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_5DAF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0083
    dw Bank0C_ScriptAddr_5DC7          ; -> branch target
Bank0C_ScriptAddr_5DAF:
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_5DC3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_5DBF          ; -> branch target
    dw $01B2  ; Text $01B2: "$44:$513D *:Whew! At last we made it to the // bot"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5DBF:
    dw $02C2
    dw $FFFF  ; END

Bank0C_ScriptAddr_5DC3:
    dw $0371  ; Text $0371: "$46:$6E9B *:Hey! Down the stairs is the // Shrine "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5DC7:
    dw $049C  ; Text $049C: "$48:$5658 *:The Master Monster Tamer // downstairs"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5DCB:
    dw $05DB  ; Text $05DB: "$18:$6DB6 *:Congratulations! Down the stairs to //"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script18
; ---------------------------------------------------------------------------
GreatTree_Script18:
    dw $FF12  ; WriteRAM
    dw $D9E8  ; RAM $D9E8
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF19  ; FadeEffect
    dw $FF12  ; WriteRAM
    dw $C842  ; RAM $C842
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF12  ; WriteRAM
    dw $C846  ; RAM $C846
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script19
; ---------------------------------------------------------------------------
GreatTree_Script19:
    dw $FF12  ; WriteRAM
    dw $D9E8  ; RAM $D9E8
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF19  ; FadeEffect
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GreatTree_Script20
; ---------------------------------------------------------------------------
GreatTree_Script20:
    dw $FF12  ; WriteRAM
    dw $D9E8  ; RAM $D9E8
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
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
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_5E57          ; -> branch target
    dw $FFFF  ; END

Bank0C_ScriptAddr_5E57:
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw $5E8D
    dw $FF00  ; BranchIfFlagClear
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw $5E69
    dw $FF01  ; BranchIfFlagSet
    dw $004B  ; Text $004B: "$42:$6791 Pulio:Majesty, Hale escaped // through t"
    dw $5E8D
    dw $FF00  ; BranchIfFlagClear
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw $5E75
    dw $FF01  ; BranchIfFlagSet
    dw $004A  ; Text $004A: "$42:$66CC King:What? [HERO]! // You have something"
    dw $5E89
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw $5E8D
    dw $FF01  ; BranchIfFlagSet
    dw $004B  ; Text $004B: "$42:$6791 Pulio:Majesty, Hale escaped // through t"
    dw $5E8D
    dw $FF01  ; BranchIfFlagSet
    dw $004A  ; Text $004A: "$42:$66CC King:What? [HERO]! // You have something"
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
    dw $003F  ; Text $003F: "$42:$602C *:I'm Pulio I take care // of this farm."
    dw Bank0C_ScriptAddr_5EAB          ; -> branch target
    dw $003A  ; Text $003A: "$42:$5ED1 [HERO] looked into the jar."
    dw $FF2C  ; CheckInvFull
    dw Bank0C_ScriptAddr_5EA7          ; -> branch target
    dw $0129  ; Text $0129: "$43:$60FA Wow! [HERO] got a TinyMedal!"
    dw $FF03  ; SetEventFlag
    dw $003F  ; Text $003F: "$42:$602C *:I'm Pulio I take care // of this farm."
    dw $FF2A  ; GiveItem
    dw $001E  ; Text $001E: "$42:$4CEA [HERO] opened a treasure chest!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5EA7:
    dw $012A  ; Text $012A: "$43:$6114 Wow! A TinyMedal was found! But // canno"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5EAB:
    dw $015D  ; Text $015D: "$43:$7229 [HERO] looked into the jar. // But there"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script02
; ---------------------------------------------------------------------------
Bazaar_Script02:
    dw $015E  ; Text $015E: "$43:$7263 [HERO] looked into the jar. // It was fi"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script03
; ---------------------------------------------------------------------------
Bazaar_Script03:
    dw $015E  ; Text $015E: "$43:$7263 [HERO] looked into the jar. // It was fi"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script04
; ---------------------------------------------------------------------------
Bazaar_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $0115  ; Text $0115: "$43:$5793 *:It's helpful to take a WarpWing // wit"
    dw Bank0C_ScriptAddr_5ED9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5EE5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0112  ; Text $0112: "$43:$54AC *:Both the Medal Man & myself // love me"
    dw Bank0C_ScriptAddr_5ED9          ; -> branch target
    dw $0196
    dw $FF03  ; SetEventFlag
    dw $0112  ; Text $0112: "$43:$54AC *:Both the Medal Man & myself // love me"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $0682  ; Text $0682: "$4A:$5F3E *:Thank you. Come again!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5ED9:
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $0682  ; Text $0682: "$4A:$5F3E *:Thank you. Come again!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5EE5:
    dw $024A  ; Text $024A: "$45:$4490 *:Since [HERO] won{A4} // *:Customers ha"
    dw $FF03  ; SetEventFlag
    dw $0115  ; Text $0115: "$43:$5793 *:It's helpful to take a WarpWing // wit"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $0682  ; Text $0682: "$4A:$5F3E *:Thank you. Come again!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script05
; ---------------------------------------------------------------------------
Bazaar_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5F1D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_5F19          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_5F15          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_5F11          ; -> branch target
    dw $015C  ; Text $015C: "$43:$7206 *:Hello, welcome to the Bazaar!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F11:
    dw $02C3
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F15:
    dw $0372  ; Text $0372: "$46:$6F0B *:Welcome to the Bazaar! There are // mo"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F19:
    dw $0424  ; Text $0424: "$21:$5495 *:Master [HERO]! // Welcome to the Bazaa"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F1D:
    dw $05EB  ; Text $05EB: "$4A:$450C *:Oh our hero [HERO]! Welcome to // the "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script06
; ---------------------------------------------------------------------------
Bazaar_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_5F3F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_5F3B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_5F37          ; -> branch target
    dw $02C4
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F37:
    dw $0373  ; Text $0373: "$46:$6F4B *:I love festivals! I'm // looking forwa"
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F3B:
    dw $0425  ; Text $0425: "$21:$54C0 *:The Starry Night is almost here! // I "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F3F:
    dw $05EC  ; Text $05EC: "$4A:$453C *:What a good feeling to be // the winni"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script07
; ---------------------------------------------------------------------------
Bazaar_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_608F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_608B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_6087          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $004B  ; Text $004B: "$42:$6791 Pulio:Majesty, Hale escaped // through t"
    dw Bank0C_ScriptAddr_6083          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $004A  ; Text $004A: "$42:$66CC King:What? [HERO]! // You have something"
    dw Bank0C_ScriptAddr_607F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_5F6B          ; -> branch target
    dw $015F  ; Text $015F: "$43:$72B3 *:Rumor has it that the // BeastTail is "
    dw $FFFF  ; END

Bank0C_ScriptAddr_5F6B:
    dw $01FA
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF07  ; InitDialogMode
    dw $01FB
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0305  ; Text $0305: "$46:$42D5 *:You again!? I'm really gonna // get yo"
    dw $FF1C  ; CompareRAM
    dw $1503
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $00D7  ; Text $00D7: "$1A:$5B3E *:Hee Hee Hee! Work! Stupid!"
    dw $5FD1
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $00D8
    dw $5FD1
    dw $FF15  ; PlaySE
    dw $FF92  ; Cmd$92
    dw $00D9  ; Text $00D9: "$1A:$5B8B *:I...if I support everybody,th...the //"
    dw $5FD1
    dw $FF14  ; ClearGameFlags
    dw $5FD7
    dw $FF11  ; NPCAnimSetup
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0038  ; Text $0038: "$42:$5E08 *:I heard that Pulio let the // monsters"
    dw $FF10  ; NPCAnimStart
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00F8  ; Text $00F8: "$43:$4ADE *:You're good..."
    dw $FF11  ; NPCAnimSetup
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0068  ; Text $0068: "$42:$78FC *:Monsters have personalities too. // *:"
    dw $FF0A  ; NPCMoveX
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFF0  ; Cmd$F0
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF47  ; Cmd47
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $0054  ; Text $0054: "$42:$6DC6 *:You will find items scattered // aroun"
    dw $FF1D  ; LockMovement
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFB0  ; Cmd$B0
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0404  ; Text $0404: "$21:$4349 *:Well, I thought to... but... // you ha"
    dw $FF1C  ; CompareRAM
    dw $1703
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF03  ; SetEventFlag
    dw $004A  ; Text $004A: "$42:$66CC King:What? [HERO]! // You have something"
    dw $FFFF  ; END

Bank0C_ScriptAddr_607F:
    dw $01FC
    dw $FFFF  ; END

Bank0C_ScriptAddr_6083:
    dw $01FD
    dw $FFFF  ; END

Bank0C_ScriptAddr_6087:
    dw $0374  ; Text $0374: "$46:$6FAF *:This kingdom is becoming // more livel"
    dw $FFFF  ; END

Bank0C_ScriptAddr_608B:
    dw $0426  ; Text $0426: "$21:$5554 *:For victory! I will sing for // your v"
    dw $FFFF  ; END

Bank0C_ScriptAddr_608F:
    dw $05ED  ; Text $05ED: "$4A:$45A7 *:La la la [HERO] and // Milayou La la l"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script08
; ---------------------------------------------------------------------------
Bazaar_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_60BB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_60B7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_60B3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $004B  ; Text $004B: "$42:$6791 Pulio:Majesty, Hale escaped // through t"
    dw Bank0C_ScriptAddr_60AF          ; -> branch target
    dw $0160  ; Text $0160: "$43:$73A2 *:During this season, everyone // speaks"
    dw $FFFF  ; END

Bank0C_ScriptAddr_60AF:
    dw $01FE
    dw $FFFF  ; END

Bank0C_ScriptAddr_60B3:
    dw $0375  ; Text $0375: "$46:$701C *:I heard that wishes on the // Starry N"
    dw $FFFF  ; END

Bank0C_ScriptAddr_60B7:
    dw $0427  ; Text $0427: "$21:$55B9 *:Everybody is partying because // it's "
    dw $FFFF  ; END

Bank0C_ScriptAddr_60BB:
    dw $05EE  ; Text $05EE: "$4A:$460C *:I didn't think you could win..."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script09
; ---------------------------------------------------------------------------
Bazaar_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_60FD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_60F9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0079
    dw Bank0C_ScriptAddr_60E7          ; -> branch target
    dw $02C5
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $60F5
    dw $0029  ; Text $0029: "$42:$55D7 *:I wanna be a master. // What should I "
    dw $FFFF  ; END

    db $C7
    db $02
    db $FF
    db $FF
Bank0C_ScriptAddr_60F9:
    dw $0428  ; Text $0428: "$21:$5622 *:Eek eek eek! // *:Mister! I wanna be a"
    dw $FFFF  ; END

Bank0C_ScriptAddr_60FD:
    dw $05EF  ; Text $05EF: "$4A:$4630 *:Giggle giggle! Listen listen! // *:I c"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script10
; ---------------------------------------------------------------------------
Bazaar_Script10:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6161          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_614F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $007A
    dw Bank0C_ScriptAddr_613D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_6127          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_6123          ; -> branch target
    dw $0161  ; Text $0161: "$43:$7425 *:There were stores here at the // last "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6123:
    dw $01FF
    dw $FFFF  ; END

Bank0C_ScriptAddr_6127:
    dw $02C8
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $614B
    dw $02CA
    dw $FFFF  ; END

    db $C9
    db $02
    db $FF
    db $FF
Bank0C_ScriptAddr_614F:
    dw $0429  ; Text $0429: "$21:$565C *:Festivals are fun! // *:Want to learn "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $615D
    dw $02CA
    dw $FFFF  ; END

    db $2A
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_6161:
    dw $05F0  ; Text $05F0: "$4A:$46B2 *:Well well, Congratulations!! // I love"
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
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
; ---------------------------------------------------------------------------
; Bazaar_Script12
; ---------------------------------------------------------------------------
Bazaar_Script12:
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $0682  ; Text $0682: "$4A:$5F3E *:Thank you. Come again!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script13
; ---------------------------------------------------------------------------
Bazaar_Script13:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6191          ; -> branch target
    dw $042B  ; Text $042B: "$21:$56F9 *:Hi little master! // *:What a gloomy f"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_618D          ; -> branch target
    dw $042D  ; Text $042D: "$21:$5769 *:...tickle,tickle ... tickle,tickle // "
    dw $FFFF  ; END

Bank0C_ScriptAddr_618D:
    dw $042C  ; Text $042C: "$21:$5753 *:Okay. Good luck!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6191:
    dw $05F2  ; Text $05F2: "$4A:$47E8 *:Hi! // *:How about a reward for your /"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $619F
    dw $05F4  ; Text $05F4: "$4A:$482E *:...tickle ...tickle, tickle // *:tickl"
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
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_61BD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_61B9          ; -> branch target
    dw $0163  ; Text $0163: "$43:$74A7 *:You? A master? You're just a kid. // *"
    dw $FFFF  ; END

Bank0C_ScriptAddr_61B9:
    dw $0200  ; Text $0200: "$1B:$430E *:Keep out! Keep out! // I don't need an"
    dw $FFFF  ; END

Bank0C_ScriptAddr_61BD:
    dw $042F  ; Text $042F: "$21:$5873 *:I've been alone for a long time. // *:"
    dw $FF03  ; SetEventFlag
    dw $009D
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $0682  ; Text $0682: "$4A:$5F3E *:Thank you. Come again!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_61CD:
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $0682  ; Text $0682: "$4A:$5F3E *:Thank you. Come again!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script15
; ---------------------------------------------------------------------------
Bazaar_Script15:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6223          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_6215          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_6203          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_61FF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_61FB          ; -> branch target
    dw $0162  ; Text $0162: "$43:$746A *:The store there is terrible! // He won"
    dw $FFFF  ; END

Bank0C_ScriptAddr_61FB:
    dw $0201  ; Text $0201: "$1B:$4344 *:Who does he think he is! // *:If he do"
    dw $FFFF  ; END

Bank0C_ScriptAddr_61FF:
    dw $02CC
    dw $FFFF  ; END

Bank0C_ScriptAddr_6203:
    dw $042E  ; Text $042E: "$21:$57DD *:Oh joy! Starry Night! // *:It seems th"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6211
    dw $0383  ; Text $0383: "$46:$7708 *:Having a monster read a QuestBk // mak"
    dw $FFFF  ; END

    db $A4
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_6215:
    dw $03EF  ; Text $03EF: "$47:$5386 *:Yeah! The Starry Night // has arrived!"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6211
    dw $0383  ; Text $0383: "$46:$7708 *:Having a monster read a QuestBk // mak"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6223:
    dw $05F5  ; Text $05F5: "$4A:$4886 *:Oh, what a joy! [HERO] won! // *:That "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6211
    dw $0383  ; Text $0383: "$46:$7708 *:Having a monster read a QuestBk // mak"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script16
; ---------------------------------------------------------------------------
Bazaar_Script16:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6291          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_627F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_626D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_625B          ; -> branch target
    dw $0164  ; Text $0164: "$43:$74E4 *:So, you don't have enough money // to "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6269
    dw $02CE
    dw $FFFF  ; END

    db $CF
    db $02
    db $FF
    db $FF
Bank0C_ScriptAddr_626D:
    dw $0376  ; Text $0376: "$46:$7081 *:New stores have opened! // *:Want to l"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $627B
    dw $0378  ; Text $0378: "$46:$711A *:Sirloin is the tastiest meat // in the"
    dw $FFFF  ; END

    db $77
    db $03
    db $FF
    db $FF
Bank0C_ScriptAddr_627F:
    dw $0430  ; Text $0430: "$21:$5931 *:Congratulations on becoming the // rep"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $628D
    dw $0378  ; Text $0378: "$46:$711A *:Sirloin is the tastiest meat // in the"
    dw $FFFF  ; END

    db $31
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_6291:
    dw $05F6  ; Text $05F6: "$4A:$4940 *:Oh, the hero of GreatTree, // Master ["
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $629F
    dw $0378  ; Text $0378: "$46:$711A *:Sirloin is the tastiest meat // in the"
    dw $FFFF  ; END

    db $F7
    db $05
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Bazaar_Script17
; ---------------------------------------------------------------------------
Bazaar_Script17:
    dw $0379  ; Text $0379: "$46:$728B [HERO] checked out the treasure // chest"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script18
; ---------------------------------------------------------------------------
Bazaar_Script18:
    dw $0379  ; Text $0379: "$46:$728B [HERO] checked out the treasure // chest"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script19
; ---------------------------------------------------------------------------
Bazaar_Script19:
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $0682  ; Text $0682: "$4A:$5F3E *:Thank you. Come again!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script20
; ---------------------------------------------------------------------------
Bazaar_Script20:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_62C1          ; -> branch target
    dw $0432  ; Text $0432: "$21:$59DB *:Lemme tell you a scary story. // There"
    dw $FFFF  ; END

Bank0C_ScriptAddr_62C1:
    dw $05F8  ; Text $05F8: "$4A:$49F5 *:The monstrous master was your // siste"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script21
; ---------------------------------------------------------------------------
Bazaar_Script21:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_62CF          ; -> branch target
    dw $0165  ; Text $0165: "$43:$751B [HERO] looked in front. // There are som"
    dw $FFFF  ; END

Bank0C_ScriptAddr_62CF:
    dw $045F  ; Text $045F: "$21:$6EDB [HERO] looked in front. // The fire is b"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Bazaar_Script22
; ---------------------------------------------------------------------------
Bazaar_Script22:
    dw $FF01  ; BranchIfFlagSet
    dw $00F6  ; Text $00F6: "$43:$4A22 *:It's a tie... In this case... // *:I w"
    dw Bank0C_ScriptAddr_6431          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_642D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $009E  ; Text $009E: "$1A:$4C68 *:As my wishes dictate..."
    dw Bank0C_ScriptAddr_6429          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_62F1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw Bank0C_ScriptAddr_6413          ; -> branch target
Bank0C_ScriptAddr_62F1:
    dw $FF01  ; BranchIfFlagSet
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw Bank0C_ScriptAddr_640F          ; -> branch target
    dw $0166  ; Text $0166: "$43:$754F *:Darn,why can't I start the fire? // *:"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0C_ScriptAddr_6305          ; -> branch target
    dw $0167  ; Text $0167: "$43:$75B4 *:Can you give me a monster that // make"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6305:
    dw $FF15  ; PlaySE
    dw $CA8D  ; RAM $CA8D
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6323
    dw $FF23  ; PlaySE2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $6327
    dw $FF23  ; PlaySE2
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6365
    dw $FF23  ; PlaySE2
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $637B
    dw $0168  ; Text $0168: "$43:$75E9 *:You don't have one? Come on!"
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
    dw $016F  ; Text $016F: "$43:$7700 *:Where does this Travelers' Gate // go?"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6413:
    dw $0434  ; Text $0434: "$21:$5B31 *:I'm betting on which kingdom // will w"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6421
    dw $0435  ; Text $0435: "$21:$5B77 *:Whaat? 100 thousand in // gold for [HE"
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
    dw $05F9  ; Text $05F9: "$4A:$4AE9 *:Hey! Our hero [HERO]! // *:The two of "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6431:
    dw $07A0  ; Text $07A0: "$22:$59A0 *:Looking at the Travelers' Gate // make"
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
    dw $00F6  ; Text $00F6: "$43:$4A22 *:It's a tie... In this case... // *:I w"
    dw Bank0C_ScriptAddr_6559          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F5  ; Text $00F5: "$43:$4A00 *:I won! Challenge me anytime!"
    dw Bank0C_ScriptAddr_648D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6485          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_6473          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw Bank0C_ScriptAddr_6481          ; -> branch target
Bank0C_ScriptAddr_6473:
    dw $FF01  ; BranchIfFlagSet
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw Bank0C_ScriptAddr_647D          ; -> branch target
    dw $0170  ; Text $0170: "$1A:$5DE0 *:AArrggh! I'm starving!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_647D:
    dw $0171  ; Text $0171: "$1A:$5DFB *:Gwrrr! Is this the // Travelers' Gate?"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6481:
    dw $0438
    dw $FFFF  ; END

Bank0C_ScriptAddr_6485:
    dw $05FA  ; Text $05FA: "$4A:$4B52 *:Missing... Something missing. // *:Ent"
    dw $FF03  ; SetEventFlag
    dw $00F5  ; Text $00F5: "$43:$4A00 *:I won! Challenge me anytime!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_648D:
    dw $05FB  ; Text $05FB: "$4A:$4C7B *:...I wonder if you brought a // monste"
    dw $FF38  ; BattleSetup
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $64A5
    dw $FF38  ; BattleSetup
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $64A5
    dw $FF38  ; BattleSetup
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $64A5
    dw $0204  ; Text $0204: "$1B:$444A *:Oh well, nobody's here. // I wanna hav"
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
    dw $07A1  ; Text $07A1: "$22:$5A1C *:I wonder where this Travelers' // Gate"
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
    dw $00F3  ; Text $00F3: "$43:$4928 *:Select your choice by stepping // on t"
    dw Bank0C_ScriptAddr_661D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_660F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_6601          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_65F3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_65E5          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_65D7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0045  ; Text $0045: "$42:$64B4 King:Oh, this monster is the // former k"
    dw Bank0C_ScriptAddr_65C9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0C_ScriptAddr_65BB          ; -> branch target
    dw $0172  ; Text $0172: "$1A:$5E29 *:I am an old gypsy woman. // Want me to"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $0173  ; Text $0173: "$1A:$5E68 *:Hmm,When you are recognized // as bein"
    dw $FFFF  ; END

Bank0C_ScriptAddr_65BB:
    dw $0172  ; Text $0172: "$1A:$5E29 *:I am an old gypsy woman. // Want me to"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $01B3  ; Text $01B3: "$44:$51AF *:Meet the old man of the Shrine // of S"
    dw $FFFF  ; END

Bank0C_ScriptAddr_65C9:
    dw $0172  ; Text $0172: "$1A:$5E29 *:I am an old gypsy woman. // Want me to"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $0202  ; Text $0202: "$1B:$43A2 *:Oh! I see! There's a monster // in fro"
    dw $FFFF  ; END

Bank0C_ScriptAddr_65D7:
    dw $0172  ; Text $0172: "$1A:$5E29 *:I am an old gypsy woman. // Want me to"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $02D0
    dw $FFFF  ; END

Bank0C_ScriptAddr_65E5:
    dw $0172  ; Text $0172: "$1A:$5E29 *:I am an old gypsy woman. // Want me to"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $037A  ; Text $037A: "$46:$72C5 *:Hm.. It seems there are several // hid"
    dw $FFFF  ; END

Bank0C_ScriptAddr_65F3:
    dw $0172  ; Text $0172: "$1A:$5E29 *:I am an old gypsy woman. // Want me to"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $0433  ; Text $0433: "$21:$5A81 *:Ohh!! You'll really go to see // your "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6601:
    dw $0172  ; Text $0172: "$1A:$5E29 *:I am an old gypsy woman. // Want me to"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $049D  ; Text $049D: "$48:$56B5 *:A surprise awaits you // in your futur"
    dw $FFFF  ; END

Bank0C_ScriptAddr_660F:
    dw $0172  ; Text $0172: "$1A:$5E29 *:I am an old gypsy woman. // Want me to"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_662F          ; -> branch target
    dw $0358  ; Text $0358: "$46:$63D6 *:..Hm. A girl... named San... // someth"
    dw $FFFF  ; END

Bank0C_ScriptAddr_661D:
    dw $0172  ; Text $0172: "$1A:$5E29 *:I am an old gypsy woman. // Want me to"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $662B
    dw $03D7  ; Text $03D7: "$47:$47C3 *:I can see.. I can see! It's a // never"
    dw $FFFF  ; END

    db $49
    db $03
    db $FF
    db $FF
Bank0C_ScriptAddr_662F:
    dw $0174  ; Text $0174: "$1A:$5EDA *:Well. You have to create your own // w"
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
    dw $0133  ; Text $0133: "$43:$631C The Gate is shut tight. // Something's e"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script02
; ---------------------------------------------------------------------------
GateHub_Script02:
    dw $0132  ; Text $0132: "$43:$6302 The Gate is shut tight."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script03
; ---------------------------------------------------------------------------
GateHub_Script03:
    dw $0134  ; Text $0134: "$43:$637F The Gate is shut tight."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script04
; ---------------------------------------------------------------------------
GateHub_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6759          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_6741          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_6729          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_6711          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0C_ScriptAddr_66F9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_66E1          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0C_ScriptAddr_66C9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_66B1          ; -> branch target
    dw $0066  ; Text $0066: "$42:$7779 *:Would you like to see the list of // T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_66AD          ; -> branch target
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
Bank0C_ScriptAddr_66AD:
    dw $047E  ; Text $047E: "$48:$467A *:Good luck on your journey!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_66B1:
    dw $0066  ; Text $0066: "$42:$7779 *:Would you like to see the list of // T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $66C5
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $0203  ; Text $0203: "$1B:$4417 *:The Room of Peace & Bravery // is open"
    dw $FFFF  ; END

Bank0C_ScriptAddr_66C9:
    dw $0066  ; Text $0066: "$42:$7779 *:Would you like to see the list of // T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $66DD
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $0278  ; Text $0278: "$45:$5839 *:The Room of Strength & Anger // is in "
    dw $FFFF  ; END

Bank0C_ScriptAddr_66E1:
    dw $0066  ; Text $0066: "$42:$7779 *:Would you like to see the list of // T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $66F5
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $02D1  ; Text $02D1: "$1F:$4772 *:The room in the center is the Room // "
    dw $FFFF  ; END

Bank0C_ScriptAddr_66F9:
    dw $0066  ; Text $0066: "$42:$7779 *:Would you like to see the list of // T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $670D
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $033D  ; Text $033D: "$46:$58CD *:Well done on surviving C class! // Go "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6711:
    dw $0066  ; Text $0066: "$42:$7779 *:Would you like to see the list of // T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6725
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $037B  ; Text $037B: "$46:$7350 *:Go left to the Room of // Joy & Wisdom"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6729:
    dw $0066  ; Text $0066: "$42:$7779 *:Would you like to see the list of // T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $673D
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $0439
    dw $FFFF  ; END

Bank0C_ScriptAddr_6741:
    dw $0066  ; Text $0066: "$42:$7779 *:Would you like to see the list of // T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6755
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $049E  ; Text $049E: "$48:$5726 *:I wish you good luck! All rooms // are"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6759:
    dw $0066  ; Text $0066: "$42:$7779 *:Would you like to see the list of // T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $676D
    dw $FF04  ; ScreenEffect
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $07A2  ; Text $07A2: "$22:$5A54 *:Oh, Master [HERO] Welcome back! // *:G"
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
    dw $0130  ; Text $0130: "$43:$62CE The Gate is shut tight."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script07
; ---------------------------------------------------------------------------
GateHub_Script07:
    dw $0131  ; Text $0131: "$43:$62E8 The Gate is shut tight."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script08
; ---------------------------------------------------------------------------
GateHub_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw Bank0C_ScriptAddr_6785          ; -> branch target
    dw $0054  ; Text $0054: "$42:$6DC6 *:You will find items scattered // aroun"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6785:
    dw $0067  ; Text $0067: "$42:$77B7 *:You can enter the locked rooms // only"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script09
; ---------------------------------------------------------------------------
GateHub_Script09:
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script10
; ---------------------------------------------------------------------------
GateHub_Script10:
    dw $FF01  ; BranchIfFlagSet
    dw $00F8  ; Text $00F8: "$43:$4ADE *:You're good..."
    dw Bank0C_ScriptAddr_67EB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_67E3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_67DF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_67DB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0C_ScriptAddr_67D7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_67D3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0C_ScriptAddr_67CF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0C_ScriptAddr_67CB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw Bank0C_ScriptAddr_67C7          ; -> branch target
    dw $0056  ; Text $0056: "$42:$6F1C *:Welcome to the Chamber of // Travelers"
    dw $FFFF  ; END

Bank0C_ScriptAddr_67C7:
    dw $0487  ; Text $0487: "$48:$4B62 *:You're at the Chamber of // Travelers'"
    dw $FFFF  ; END

Bank0C_ScriptAddr_67CB:
    dw $0175  ; Text $0175: "$1A:$5F0D *:Here's the Travelers' // Chamber. // *"
    dw $FFFF  ; END

Bank0C_ScriptAddr_67CF:
    dw $01B4  ; Text $01B4: "$44:$521A *:Here you are at the Chamber of // Trav"
    dw $FFFF  ; END

Bank0C_ScriptAddr_67D3:
    dw $08D0
    dw $FFFF  ; END

Bank0C_ScriptAddr_67D7:
    dw $0279  ; Text $0279: "$45:$5878 *:You're at the Chamber of // Traverlers"
    dw $FFFF  ; END

Bank0C_ScriptAddr_67DB:
    dw $02D2
    dw $FFFF  ; END

Bank0C_ScriptAddr_67DF:
    dw $043B
    dw $FFFF  ; END

Bank0C_ScriptAddr_67E3:
    dw $07A4  ; Text $07A4: "$22:$5BC8 *:Oh it's Sir [HERO]! // You're at the C"
    dw $FF03  ; SetEventFlag
    dw $00F8  ; Text $00F8: "$43:$4ADE *:You're good..."
    dw $FFFF  ; END

Bank0C_ScriptAddr_67EB:
    dw $07A5  ; Text $07A5: "$22:$5CD0 *:Ah it's Master [HERO]! // You're at th"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script11
; ---------------------------------------------------------------------------
GateHub_Script11:
    dw $0136  ; Text $0136: "$43:$63B3 The Gate is shut tight."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script12
; ---------------------------------------------------------------------------
GateHub_Script12:
    dw $0135  ; Text $0135: "$43:$6399 The Gate is shut tight."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script13
; ---------------------------------------------------------------------------
GateHub_Script13:
    dw $00DD  ; Text $00DD: "$1A:$5CBE The door is shut tight."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script14
; ---------------------------------------------------------------------------
GateHub_Script14:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6831          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A0  ; Text $00A0: "$1A:$4CC3 *:Tonight,we are focusing on // attackin"
    dw Bank0C_ScriptAddr_682D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_6825          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0C_ScriptAddr_6821          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_681D          ; -> branch target
    dw $0067  ; Text $0067: "$42:$77B7 *:You can enter the locked rooms // only"
    dw $FFFF  ; END

Bank0C_ScriptAddr_681D:
    dw $037C  ; Text $037C: "$46:$7443 *:The Room of Happiness & // Temptation "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6821:
    dw $03EA  ; Text $03EA: "$47:$4FEB *:You're in the Chamber of // Travelers'"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6825:
    dw $043C
    dw $FF03  ; SetEventFlag
    dw $00A0  ; Text $00A0: "$1A:$4CC3 *:Tonight,we are focusing on // attackin"
    dw $FFFF  ; END

Bank0C_ScriptAddr_682D:
    dw $043D
    dw $FFFF  ; END

Bank0C_ScriptAddr_6831:
    dw $07A6  ; Text $07A6: "$22:$5DDA *:The path on the right side was // just"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateHub_Script15
; ---------------------------------------------------------------------------
GateHub_Script15:
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_6863          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0022  ; Text $0022: "$42:$517B *:Everybody will be happy if you // beco"
    dw Bank0C_ScriptAddr_6847          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_685F          ; -> branch target
Bank0C_ScriptAddr_6847:
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0C_ScriptAddr_685B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_6857          ; -> branch target
    dw $0068  ; Text $0068: "$42:$78FC *:Monsters have personalities too. // *:"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6857:
    dw $037D  ; Text $037D: "$46:$747D *:Good work! Have you // found strong mo"
    dw $FFFF  ; END

Bank0C_ScriptAddr_685B:
    dw $03EB  ; Text $03EB: "$47:$5090 *:Behind the Gate of Labyrinth // there "
    dw $FFFF  ; END

Bank0C_ScriptAddr_685F:
    dw $043E
    dw $FFFF  ; END

Bank0C_ScriptAddr_6863:
    dw $04A0  ; Text $04A0: "$48:$58AF *:What kind of future did you see // beh"
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
    dw $00FA  ; Text $00FA: "$43:$4B43 *:I bet you wanna know."
    dw Bank0C_ScriptAddr_687B          ; -> branch target
    dw $07A8  ; Text $07A8: "$22:$5FA8 *:Welcome to the new Chamber of // Trave"
    dw $FF03  ; SetEventFlag
    dw $00FA  ; Text $00FA: "$43:$4B43 *:I bet you wanna know."
    dw $FFFF  ; END

Bank0C_ScriptAddr_687B:
    dw $07A9  ; Text $07A9: "$22:$617B *:Welcome to the new Chamber of // Trave"
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
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_68E3          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw Bank0C_ScriptAddr_6965          ; -> branch target
    dw $FFFF  ; END

Bank0C_ScriptAddr_68E3:
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw $68E1
    dw $FF01  ; BranchIfFlagSet
    dw $00E5  ; Text $00E5: "$43:$4420 *:Oh, Sir [HERO]. Congratulations on // "
    dw $68E1
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
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
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $68E1
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF61  ; Cmd61
    dw $6A55
    dw $FF24  ; Cmd24
    dw $69EF
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF61  ; Cmd61
    dw $6A5D
    dw $FF24  ; Cmd24
    dw $69F7
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF61  ; Cmd61
    dw $6A6B
    dw $FF24  ; Cmd24
    dw $6A05
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF61  ; Cmd61
    dw $6A7F
    dw $FF24  ; Cmd24
    dw $6A19
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF61  ; Cmd61
    dw $6A93
    dw $FF24  ; Cmd24
    dw $6A2D
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF61  ; Cmd61
    dw $6AA7
    dw $FF24  ; Cmd24
    dw $6A41
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFB0  ; Cmd$B0
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1C  ; CompareRAM
    dw $0700  ; Text $0700: "$22:$419E *:OK! Wait overnight."
    dw $FF19  ; FadeEffect
    dw $FF1C  ; CompareRAM
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FF19  ; FadeEffect
    dw $FF12  ; WriteRAM
    dw $D9E2  ; RAM $D9E2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
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
    dw $0045  ; Text $0045: "$42:$64B4 King:Oh, this monster is the // former k"
    dw Bank0C_ScriptAddr_6ADD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0C_ScriptAddr_6AD9          ; -> branch target
    dw $0069  ; Text $0069: "$42:$7A31 *:Hey Master! Dn'a have an egg? [YES/NO]"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_6AD5          ; -> branch target
    dw $086E  ; Text $086E: "$4E:$44DC *:Eggs will be eggs forever if // left a"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6AD5:
    dw $086D  ; Text $086D: "$4E:$44B6 *:All monsters are born from eggs."
    dw $FFFF  ; END

Bank0C_ScriptAddr_6AD9:
    dw $01B5  ; Text $01B5: "$44:$5325 *:The place to hatch eggs? // Now I reme"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6ADD:
    dw $0206  ; Text $0206: "$1B:$44A7 *:There's a person who will // evaluate "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script02
; ---------------------------------------------------------------------------
Farm_Script02:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF10  ; NPCAnimStart
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0068  ; Text $0068: "$42:$78FC *:Monsters have personalities too. // *:"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $001A  ; Text $001A: "$42:$4C3F *:I see....."
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6B8F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_6B87          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_6B7F          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw Bank0C_ScriptAddr_6B2F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_6B77          ; -> branch target
Bank0C_ScriptAddr_6B2F:
    dw $FF01  ; BranchIfFlagSet
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw Bank0C_ScriptAddr_6B6F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw Bank0C_ScriptAddr_6B43          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $006A  ; Text $006A: "$42:$7A53 Splat... Poop hit [HERO]."
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B43:
    dw $FF07  ; InitDialogMode
    dw $006B  ; Text $006B: "$42:$7A6A Thwack! // It was the egg of a SkyDragon"
    dw $FF28  ; CheckStorageFull
    dw Bank0C_ScriptAddr_6B69          ; -> branch target
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF06  ; IncrementCounter
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF03  ; SetEventFlag
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $FF29  ; AddMonster
    dw $015E  ; Text $015E: "$43:$7263 [HERO] looked into the jar. // It was fi"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6B69:
    dw $006D  ; Text $006D: "$42:$7B2F Could not keep the egg because there // "
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B6F:
    dw $FF07  ; InitDialogMode
    dw $006E  ; Text $006E: "$42:$7C00 Splash! Poop hit [HERO]."
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B77:
    dw $FF07  ; InitDialogMode
    dw $0205  ; Text $0205: "$1B:$4486 K-thump! Something // hit [HERO]."
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B7F:
    dw $FF07  ; InitDialogMode
    dw $02D3
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B87:
    dw $FF07  ; InitDialogMode
    dw $037E  ; Text $037E: "$46:$74EB SMACK! // Something hit [HERO] and // bo"
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B8F:
    dw $FF07  ; InitDialogMode
    dw $07AA  ; Text $07AA: "$22:$634E Splat, // a FunkyBird is flying above!"
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_6B97          ; -> branch target
Bank0C_ScriptAddr_6B97:
    dw $FF06  ; IncrementCounter
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script03
; ---------------------------------------------------------------------------
Farm_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6BBF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_6BBB          ; -> branch target
    dw $02D4
    dw $FFFF  ; END

Bank0C_ScriptAddr_6BBB:
    dw $037F  ; Text $037F: "$46:$751F *:We monsters become lively when // the "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6BBF:
    dw $07AB  ; Text $07AB: "$22:$6379 *:I wonder where we monsters came // fro"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script04
; ---------------------------------------------------------------------------
Farm_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $0094
    dw Bank0C_ScriptAddr_6BCD          ; -> branch target
    dw $04EB  ; Text $04EB: "$1F:$64E6 *:Congratulations! [HERO]! // *:From now"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6BCD:
    dw $04EC
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script05
; ---------------------------------------------------------------------------
Farm_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $00E3  ; Text $00E3: "$43:$436D *:Too bad. You need more // training. //"
    dw Bank0C_ScriptAddr_6BDF          ; -> branch target
    dw $04ED
    dw $FF03  ; SetEventFlag
    dw $00E3  ; Text $00E3: "$43:$436D *:Too bad. You need more // training. //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6BDF:
    dw $04EE
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script06
; ---------------------------------------------------------------------------
Farm_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6C0F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_6BFF          ; -> branch target
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0014  ; Text $0014: "$42:$4AE0 *:Now it's time to go see the King."
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw $FFFF  ; END

Bank0C_ScriptAddr_6BFF:
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0014  ; Text $0014: "$42:$4AE0 *:Now it's time to go see the King."
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0209  ; Text $0209: "$1B:$45C3 *:There are cliffs where you can // jump"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C0F:
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0014  ; Text $0014: "$42:$4AE0 *:Now it's time to go see the King."
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $07AE  ; Text $07AE: "$22:$644A *:The Starry Night is over!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script07
; ---------------------------------------------------------------------------
Farm_Script07:
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script08
; ---------------------------------------------------------------------------
Farm_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6C4B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_6C47          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_6C43          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw Bank0C_ScriptAddr_6C3F          ; -> branch target
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C3F:
    dw $006F  ; Text $006F: "$42:$7C16 *:Treats! BeefJerky, // PorkChop, Rib. /"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C43:
    dw $0207  ; Text $0207: "$1B:$44E7 *:BadMeat is bad and poisonous. // *:But"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C47:
    dw $0380  ; Text $0380: "$46:$758F *:There are monsters with // amazing ski"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C4B:
    dw $07AC  ; Text $07AC: "$22:$63BD *:The sky is crystal clear! // The stars"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script09
; ---------------------------------------------------------------------------
Farm_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6C6D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_6C69          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_6C65          ; -> branch target
    dw $0070
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C65:
    dw $0208  ; Text $0208: "$1B:$4555 *:We disobey when we get an unwanted // "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C69:
    dw $0381  ; Text $0381: "$46:$75F9 *:I heard there is something that can //"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6C6D:
    dw $07AD  ; Text $07AD: "$22:$63FD *:I wonder if I can be a lone wolf // if"
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
    dw $00E6  ; Text $00E6: "$43:$4490 *:Welcome to the arena! Want to // hear "
    dw Bank0C_ScriptAddr_6C83          ; -> branch target
    dw $04F4
    dw $FF03  ; SetEventFlag
    dw $00E6  ; Text $00E6: "$43:$4490 *:Welcome to the arena! Want to // hear "
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
    dw $0903  ; Text $0903: "$4F:$5E80 *:You're a wimp. But I'm not going // to"
    dw $FF19  ; FadeEffect
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script13
; ---------------------------------------------------------------------------
Farm_Script13:
    dw $04F9
    dw $FF1C  ; CompareRAM
    dw $0904  ; Text $0904: "$4F:$5E80 *:You're a wimp. But I'm not going // to"
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
    dw $0906  ; Text $0906: "$4F:$5E80 *:You're a wimp. But I'm not going // to"
    dw $FF19  ; FadeEffect
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script16
; ---------------------------------------------------------------------------
Farm_Script16:
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script17
; ---------------------------------------------------------------------------
Farm_Script17:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6CDF          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $007C
    dw Bank0C_ScriptAddr_6CBF          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_6CDB          ; -> branch target
Bank0C_ScriptAddr_6CBF:
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_6CD3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0C_ScriptAddr_6CCF          ; -> branch target
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6CCF:
    dw $0176  ; Text $0176: "$1A:$5FFD *:Hmm. Can't go this way either."
    dw $FFFF  ; END

Bank0C_ScriptAddr_6CD3:
    dw $02D5
    dw $FF03  ; SetEventFlag
    dw $007C
    dw $FFFF  ; END

Bank0C_ScriptAddr_6CDB:
    dw $04A1  ; Text $04A1: "$48:$593A *:We'll spend the Starry Night, // toget"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6CDF:
    dw $07AF  ; Text $07AF: "$22:$6469 *:We spent the Starry Night // together,"
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
    dw $00E7  ; Text $00E7: "$43:$44CE *:The battle classes go from // S,A down"
    dw Bank0C_ScriptAddr_6D9B          ; -> branch target
    dw $04FB
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0C_ScriptAddr_6CFF          ; -> branch target
    dw $04FD
    dw $FF03  ; SetEventFlag
    dw $00E7  ; Text $00E7: "$43:$44CE *:The battle classes go from // S,A down"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6CFF:
    dw $04FC
    dw $FF47  ; Cmd47
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFF0  ; Cmd$F0
    dw $FF10  ; NPCAnimStart
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0188  ; Text $0188: "$1A:$6964 [HERO] looked at the bookshelf. // :Fami"
    dw $FF11  ; NPCAnimSetup
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0F  ; SetScreenScroll
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw $0118  ; Text $0118: "$43:$596B [HERO] read the blackboard. // :Masters "
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6D9B:
    dw $04FE
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
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
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6E05          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw Bank0C_ScriptAddr_6E01          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $007B
    dw Bank0C_ScriptAddr_6DFD          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_6DEB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw Bank0C_ScriptAddr_6DE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw Bank0C_ScriptAddr_6DD5          ; -> branch target
    dw $003B  ; Text $003B: "$42:$5EEB [HERO] looked into the jar. // The jar i"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6DD5:
    dw $003A  ; Text $003A: "$42:$5ED1 [HERO] looked into the jar."
    dw $FF2C  ; CheckInvFull
    dw $6E09
    dw $0129  ; Text $0129: "$43:$60FA Wow! [HERO] got a TinyMedal!"
    dw $FF03  ; SetEventFlag
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF2A  ; GiveItem
    dw $001E  ; Text $001E: "$42:$4CEA [HERO] opened a treasure chest!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6DE7:
    dw $003B  ; Text $003B: "$42:$5EEB [HERO] looked into the jar. // The jar i"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6DEB:
    dw $003A  ; Text $003A: "$42:$5ED1 [HERO] looked into the jar."
    dw $FF2C  ; CheckInvFull
    dw $6E09
    dw $0129  ; Text $0129: "$43:$60FA Wow! [HERO] got a TinyMedal!"
    dw $FF03  ; SetEventFlag
    dw $007B
    dw $FF2A  ; GiveItem
    dw $001E  ; Text $001E: "$42:$4CEA [HERO] opened a treasure chest!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6DFD:
    dw $003B  ; Text $003B: "$42:$5EEB [HERO] looked into the jar. // The jar i"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E01:
    dw $0502  ; Text $0502: "$1F:$71E1 [HERO] looked into the jar. // The jar w"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E05:
    dw $07B1  ; Text $07B1: "$22:$64FA [HERO] looked into the jar. // *:A fragm"
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
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6E3F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw Bank0C_ScriptAddr_6E3B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_6E37          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_6E33          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_6E2F          ; -> branch target
    dw $0039  ; Text $0039: "$42:$5E3E *:Hey, Mr.Monster Master. I wonder // wh"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E2F:
    dw $020B  ; Text $020B: "$1B:$4665 *:Hi! monster master! I catch // a lot h"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E33:
    dw $02D8
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E37:
    dw $04A3  ; Text $04A3: "$48:$59F3 *:The Starry Night is soon. Yeah! // Ha "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E3B:
    dw $04FF
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E3F:
    dw $07B0  ; Text $07B0: "$22:$64CF *:Hey you! I fished out a // big one!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script23
; ---------------------------------------------------------------------------
Farm_Script23:
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_6E57          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw Bank0C_ScriptAddr_6E53          ; -> branch target
    dw $0038  ; Text $0038: "$42:$5E08 *:I heard that Pulio let the // monsters"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E53:
    dw $0071
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E57:
    dw $020A  ; Text $020A: "$1B:$4616 *:Hey! The Monster Stable is down // the"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script24
; ---------------------------------------------------------------------------
Farm_Script24:
    dw $FF01  ; BranchIfFlagSet
    dw $00FC  ; Text $00FC: "$43:$4C04 *:These statues are the protectors // of"
    dw Bank0C_ScriptAddr_6E8D          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6E89          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw Bank0C_ScriptAddr_6E85          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_6E81          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_6E7D          ; -> branch target
    dw $02D7
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E7D:
    dw $0382  ; Text $0382: "$46:$7659 *:Hello. The stable is below // here. Bl"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E81:
    dw $04A2  ; Text $04A2: "$48:$597F *:Hello. Down to the stable. // Bleat. /"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E85:
    dw $0500  ; Text $0500: "$1F:$71B9 *:No running!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E89:
    dw $07B2  ; Text $07B2: "$22:$653C *:Go down to the stable. Bleat! // Watab"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6E8D:
    dw $07B3  ; Text $07B3: "$22:$658B *:Go down to the stable. Bleat! // Keep "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script25
; ---------------------------------------------------------------------------
Farm_Script25:
    dw $0501  ; Text $0501: "$1F:$71CB *:Squawk! Squawk!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script26
; ---------------------------------------------------------------------------
Farm_Script26:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6EE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw Bank0C_ScriptAddr_6F03          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0C_ScriptAddr_6EE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw Bank0C_ScriptAddr_6EE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw Bank0C_ScriptAddr_6EF3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw Bank0C_ScriptAddr_6EE7          ; -> branch target
    dw $003C  ; Text $003C: "$42:$5F28 *:Hey you! You came here to // steal my "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_6ED5          ; -> branch target
    dw $003D  ; Text $003D: "$42:$5F5F *:C'mon, I'll give you a beating. // Sni"
    dw $003F  ; Text $003F: "$42:$602C *:I'm Pulio I take care // of this farm."
    dw $FF03  ; SetEventFlag
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF04  ; ScreenEffect
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $06C0  ; Text $06C0: "$4A:$63D3 Pulio:Hey there! Whadayagonnado?"
    dw $06C2  ; Text $06C2: "$4A:$640D Pulio:Later! We'll be here for ya!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6ED5:
    dw $003E  ; Text $003E: "$42:$6007 *:You came here to get monsters?"
    dw $003F  ; Text $003F: "$42:$602C *:I'm Pulio I take care // of this farm."
    dw $FF03  ; SetEventFlag
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF04  ; ScreenEffect
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $06C0  ; Text $06C0: "$4A:$63D3 Pulio:Hey there! Whadayagonnado?"
    dw $06C2  ; Text $06C2: "$4A:$640D Pulio:Later! We'll be here for ya!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6EE7:
    dw $06C0  ; Text $06C0: "$4A:$63D3 Pulio:Hey there! Whadayagonnado?"
    dw $FF04  ; ScreenEffect
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $06C0  ; Text $06C0: "$4A:$63D3 Pulio:Hey there! Whadayagonnado?"
    dw $06C2  ; Text $06C2: "$4A:$640D Pulio:Later! We'll be here for ya!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6EF3:
    dw $0072
    dw $FF03  ; SetEventFlag
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF04  ; ScreenEffect
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $06C0  ; Text $06C0: "$4A:$63D3 Pulio:Hey there! Whadayagonnado?"
    dw $06C2  ; Text $06C2: "$4A:$640D Pulio:Later! We'll be here for ya!"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6F03:
    dw $0504  ; Text $0504: "$1F:$7280 Pulio:If you didn't help me... // Pulio:"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script27
; ---------------------------------------------------------------------------
Farm_Script27:
    dw $FF00  ; BranchIfFlagClear
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw Bank0C_ScriptAddr_6F13          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A2  ; Text $00A2: "$1A:$4D94 *:My pal fighting next to me is on // my"
    dw Bank0C_ScriptAddr_6FF9          ; -> branch target
Bank0C_ScriptAddr_6F13:
    dw $FF01  ; BranchIfFlagSet
    dw $00A3
    dw Bank0C_ScriptAddr_6FE7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A2  ; Text $00A2: "$1A:$4D94 *:My pal fighting next to me is on // my"
    dw Bank0C_ScriptAddr_6FCD          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_6F31          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A1  ; Text $00A1: "$1A:$4D62 *:Am I always doing unnecessary // stuff"
    dw Bank0C_ScriptAddr_6F9F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_6F71          ; -> branch target
Bank0C_ScriptAddr_6F31:
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw Bank0C_ScriptAddr_6FC9          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A1  ; Text $00A1: "$1A:$4D62 *:Am I always doing unnecessary // stuff"
    dw Bank0C_ScriptAddr_6F9F          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0C_ScriptAddr_6F71          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw Bank0C_ScriptAddr_6F5F          ; -> branch target
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF03  ; SetEventFlag
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_6F5B          ; -> branch target
    dw $0041  ; Text $0041: "$42:$61BD Slio:You can drop off up to 19 // monste"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6F5B:
    dw $0042  ; Text $0042: "$42:$6437 Slio:Raise the monster to be // powerful"
    dw $FFFF  ; END

Bank0C_ScriptAddr_6F5F:
    dw $0043  ; Text $0043: "$42:$6466 Slio:Dn'a wanna know about the // farm? "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6F6D
    dw $0041  ; Text $0041: "$42:$61BD Slio:You can drop off up to 19 // monste"
    dw $FFFF  ; END

    db $42
    db $00
    db $FF
    db $FF
Bank0C_ScriptAddr_6F71:
    dw $043F
    dw $FF03  ; SetEventFlag
    dw $00A1  ; Text $00A1: "$1A:$4D62 *:Am I always doing unnecessary // stuff"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6F97
    dw $FF28  ; CheckStorageFull
    dw $6F9B
    dw $0442
    dw $FF03  ; SetEventFlag
    dw $00A2  ; Text $00A2: "$1A:$4D94 *:My pal fighting next to me is on // my"
    dw $FF29  ; AddMonster
    dw $015F  ; Text $015F: "$43:$72B3 *:Rumor has it that the // BeastTail is "
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
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
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6FC1
    dw $FF28  ; CheckStorageFull
    dw $6FC5
    dw $0442
    dw $FF03  ; SetEventFlag
    dw $00A2  ; Text $00A2: "$1A:$4D94 *:My pal fighting next to me is on // my"
    dw $FF29  ; AddMonster
    dw $015F  ; Text $015F: "$43:$72B3 *:Rumor has it that the // BeastTail is "
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
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
    dw $005D  ; Text $005D: "$42:$7314 Slio:[HERO]! Congratulations // on your "
    dw $FFFF  ; END

Bank0C_ScriptAddr_6FCD:
    dw $0444
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6FF5
    dw $0446
    dw $FFFF  ; END

    db $45
    db $04
    db $FF
    db $FF
Bank0C_ScriptAddr_6FF9:
    dw $0503  ; Text $0503: "$1F:$7237 *:Someday I will follow // [HERO]... // "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script28
; ---------------------------------------------------------------------------
Farm_Script28:
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_701B          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0C_ScriptAddr_7017          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw Bank0C_ScriptAddr_7013          ; -> branch target
    dw $0044  ; Text $0044: "$42:$6492 *:You are at the monster farm."
    dw $FFFF  ; END

Bank0C_ScriptAddr_7013:
    dw $0073
    dw $FFFF  ; END

Bank0C_ScriptAddr_7017:
    dw $0177  ; Text $0177: "$1A:$6020 *:You are at the Monster Farm. // *:The "
    dw $FFFF  ; END

Bank0C_ScriptAddr_701B:
    dw $020C  ; Text $020C: "$1B:$46CF *:You're at the Monster Farm. // *:Go le"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script29
; ---------------------------------------------------------------------------
Farm_Script29:
    dw $02D9
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_706F          ; -> branch target
    dw $FF15  ; PlaySE
    dw $CA8D  ; RAM $CA8D
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0C_ScriptAddr_706B          ; -> branch target
    dw $FF5F  ; Cmd5F
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0C_ScriptAddr_703D          ; -> branch target
    dw $08C7
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_703F          ; -> branch target
Bank0C_ScriptAddr_703D:
    dw $08D2
Bank0C_ScriptAddr_703F:
    dw $FF15  ; PlaySE
    dw $CA8D  ; RAM $CA8D
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_706B          ; -> branch target
    dw $FF5F  ; Cmd5F
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_7053          ; -> branch target
    dw $08C7
    dw $FF14  ; ClearGameFlags
    dw Bank0C_ScriptAddr_7055          ; -> branch target
Bank0C_ScriptAddr_7053:
    dw $08D2
Bank0C_ScriptAddr_7055:
    dw $FF15  ; PlaySE
    dw $CA8D  ; RAM $CA8D
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0C_ScriptAddr_706B          ; -> branch target
    dw $FF5F  ; Cmd5F
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
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
    dw $0505  ; Text $0505: "$1F:$732E *:Yo, I heard you won. // *:Isn't it jus"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script31
; ---------------------------------------------------------------------------
Farm_Script31:
    dw $0506  ; Text $0506: "$1F:$737D *:Oh! [HERO]!! You did it, you // did it"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script32
; ---------------------------------------------------------------------------
Farm_Script32:
    dw $0507  ; Text $0507: "$1F:$73DC *:You won!! Yeh yeh!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script33
; ---------------------------------------------------------------------------
Farm_Script33:
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0C_ScriptAddr_7089          ; -> branch target
    dw $0074
    dw $FFFF  ; END

Bank0C_ScriptAddr_7089:
    dw $020D  ; Text $020D: "$1B:$4754 *:The Travelers' Gates are hidden // eve"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script34
; ---------------------------------------------------------------------------
Farm_Script34:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_70AB          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_70A7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_70A3          ; -> branch target
    dw $02DA
    dw $FFFF  ; END

Bank0C_ScriptAddr_70A3:
    dw $0384  ; Text $0384: "$46:$7840 *:My parents' ancestors were // bred a l"
    dw $FFFF  ; END

Bank0C_ScriptAddr_70A7:
    dw $04A5  ; Text $04A5: "$48:$5A67 *:As the Starry Night nears, I // want t"
    dw $FFFF  ; END

Bank0C_ScriptAddr_70AB:
    dw $07B5  ; Text $07B5: "$22:$662C *:Have you met all the monsters? // Ther"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script35
; ---------------------------------------------------------------------------
Farm_Script35:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0C_ScriptAddr_70D3          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0C_ScriptAddr_70CF          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0C_ScriptAddr_70C7          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $006A  ; Text $006A: "$42:$7A53 Splat... Poop hit [HERO]."
    dw Bank0C_ScriptAddr_70CB          ; -> branch target
Bank0C_ScriptAddr_70C7:
    dw $02DB
    dw $FFFF  ; END

Bank0C_ScriptAddr_70CB:
    dw $0385  ; Text $0385: "$46:$78AB *:I'm pretty much a coward. // *:I wish "
    dw $FFFF  ; END

Bank0C_ScriptAddr_70CF:
    dw $04A6  ; Text $04A6: "$48:$5AA4 *:As the Starry Night nears, it // makes"
    dw $FFFF  ; END

Bank0C_ScriptAddr_70D3:
    dw $07B6  ; Text $07B6: "$22:$666D *:My buddy is living behind the // Gate "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script36
; ---------------------------------------------------------------------------
Farm_Script36:
    dw $FF01  ; BranchIfFlagSet
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw Bank0C_ScriptAddr_7111          ; -> branch target
    dw $0368  ; Text $0368: "$46:$6AAD *:Oh [HERO], It's me. // The receptionis"
    dw $FF03  ; SetEventFlag
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0090
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $001A  ; Text $001A: "$42:$4C3F *:I see....."
    dw $0090
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FFFF  ; END

Bank0C_ScriptAddr_7111:
    dw $0338  ; Text $0338: "$46:$5717 *:What's wrong? You look pale!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script37
; ---------------------------------------------------------------------------
Farm_Script37:
    dw $0508  ; Text $0508: "$1F:$73F4 *:[HERO]! You did great!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script38
; ---------------------------------------------------------------------------
Farm_Script38:
    dw $0509  ; Text $0509: "$1F:$740B *:You did it! Want a reward? [YES/NO]"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0C_ScriptAddr_7127          ; -> branch target
    dw $050A  ; Text $050A: "$1F:$742B *:... tickle. Tickle, tickle. // *:Tickl"
    dw $FFFF  ; END

Bank0C_ScriptAddr_7127:
    dw $050B  ; Text $050B: "$1F:$7472 *:Giggle.."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script39
; ---------------------------------------------------------------------------
Farm_Script39:
    dw $050C  ; Text $050C: "$1F:$7481 *:I danced too much and I feel // dizzy!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script40
; ---------------------------------------------------------------------------
Farm_Script40:
    dw $050D  ; Text $050D: "$1F:$74AF *:It's unbelievable to // fight against "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script41
; ---------------------------------------------------------------------------
Farm_Script41:
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0F  ; SetScreenScroll
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0198  ; Text $0198: "$44:$4157 *:Good evening. Or is it day? // *:I'm a"
    dw $00D8
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Farm_Script42
; ---------------------------------------------------------------------------
Farm_Script42:
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0F  ; SetScreenScroll
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw $0118  ; Text $0118: "$43:$596B [HERO] read the blackboard. // :Masters "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
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
