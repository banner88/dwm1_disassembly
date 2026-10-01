; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $00d", ROMX[$4000], BANK[$d]

    db $0d ;ROM Bank

    dw LoadBd_4007
    dw labeld_402f
    dw labeld_4110

; ---------------------------------------------------------------------------
; ScriptDataLookup — Same triple-index as bank $0C (see bank_00c.asm)
; $D8D3 (map_type) → $41BA → per-map table
; $D8D4 (script_id) → per-NPC data pointer
; $D8D5/$D8D6 (counter) → BC command pair
; ---------------------------------------------------------------------------
LoadBd_4007:
    ld a, [wScriptMapType]
    ld l, a
    ld h, $00
    add hl, hl
    ld de, Bank0D_ScriptMasterTable
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [wScriptNPCId]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [wScriptCounter]
    ld l, a
    ld a, [$d8d6]
    ld h, a
    add hl, hl
    add hl, de
    ld c, [hl]
    inc hl
    ld b, [hl]
    dec hl
    ret

labeld_402f:
    ld hl, $ffb7
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
    call LoadBd_4007
    push bc
    call LoadBd_40e7
    pop bc

LoadBd_4075:
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
    jr z, jr_00d_40a0

    ld b, a

jr_00d_409a:
    call LoadBd_40da
    dec b
    jr nz, jr_00d_409a

jr_00d_40a0:
    ld a, l
    ld [$d8e7], a
    ld a, h
    ld [$d8e8], a
    pop bc

jr_00d_40a9:
    ld a, [bc]
    inc bc
    cp $d9
    ret z

    cp $d8
    jr nz, jr_00d_40d2

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
    jr jr_00d_40a9

jr_00d_40d2:
    call Write_gfx_tile
    call LoadBd_40da
    jr jr_00d_40a9

LoadBd_40da:
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


LoadBd_40e7:
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

jr_00d_40f5:
    push hl

jr_00d_40f6:
    ld a, [bc]
    inc bc
    cp $d9
    jr z, jr_00d_410e

    cp $d8
    jr nz, jr_00d_410b

    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00d_40f5

jr_00d_410b:
    ld [hl+], a
    jr jr_00d_40f6

jr_00d_410e:
    pop hl
    ret

labeld_4110:
    ld hl, $ffb7
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
    call LoadBd_4007
    push bc
    call LoadBd_4171
    pop bc
    ld a, [wIsGBC]
    or a
    ret z

    di
    db $cd, $a6, $1a
    ld a, $01
    ldh [rVBK], a
    ei
    call LoadBd_4075
    di
    db $cd, $a6, $1a
    ld a, $00
    ldh [rVBK], a
    ei
    ret


LoadBd_4171:
    ld a, [bc]
    ld l, a
    inc bc
    ld a, [bc]
    ld h, a
    inc bc

jr_00d_4177:
    push hl

jr_00d_4178:
    ld a, [bc]
    inc bc
    cp $d9
    jr z, jr_00d_4193

    cp $d8
    jr nz, jr_00d_418d

    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00d_4177

jr_00d_418d:
    call SaveBd_4195
    inc hl
    jr jr_00d_4178

jr_00d_4193:
    pop hl
    ret


SaveBd_4195:
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
    jr c, jr_00d_41b0

    swap a
    and $f0
    ld d, a
    ld a, [hl]
    and $0f
    jr jr_00d_41b6

jr_00d_41b0:
    and $0f
    ld d, a
    ld a, [hl]
    and $f0

jr_00d_41b6:
    or d
    ld [hl], a
    pop hl
    ret


; ===========================================================================
; Script Data — Bank $0D
; 168 scripts across 26 maps, 614 labels
; ===========================================================================

; ---------------------------------------------------------------------------
; Bank0D_ScriptMasterTable
; ---------------------------------------------------------------------------
Bank0D_ScriptMasterTable:
    dw $7C3E
    dw $7C3E
    dw $7C3E
    dw $7C3E
    dw $7C3E
    dw $7C3E
    dw ArenaLobby_ScriptPtrTable       ; [0] ArenaLobby
    dw ArenaRooms_ScriptPtrTable       ; [1] ArenaRooms
    dw Map08_ScriptPtrTable            ; [2] Map08
    dw Map09_ScriptPtrTable            ; [3] Map09
    dw Map0A_ScriptPtrTable            ; [4] Map0A
    dw Map0B_ScriptPtrTable            ; [5] Map0B
    dw GateTileset_ScriptPtrTable      ; [6] GateTileset
    dw Map0D_ScriptPtrTable            ; [7] Map0D
    dw Map0E_ScriptPtrTable            ; [8] Map0E
    dw Map0F_ScriptPtrTable            ; [9] Map0F
    dw CopycatRoom_ScriptPtrTable      ; [10] CopycatRoom
    dw Map11_ScriptPtrTable            ; [11] Map11
    dw Map12_ScriptPtrTable            ; [12] Map12
    dw Map13_ScriptPtrTable            ; [13] Map13
    dw Map14_ScriptPtrTable            ; [14] Map14
    dw Map15_ScriptPtrTable            ; [15] Map15
    dw MedalMan_ScriptPtrTable         ; [16] MedalMan
    dw Map17_ScriptPtrTable            ; [17] Map17
    dw Well_ScriptPtrTable             ; [18] Well
    dw Map19_ScriptPtrTable            ; [19] Map19
    db $76
    db $6C
    db $36
    db $6E
    db $40
    db $6F
    db $B8
    db $70
    db $6A
    db $72
    db $6C
    db $74
; ---------------------------------------------------------------------------
; ArenaLobby Per-Script Table (map_type=$06, 12 scripts)
; ---------------------------------------------------------------------------
ArenaLobby_ScriptPtrTable:
    dw ArenaLobby_Script00             ; script 0
    dw ArenaLobby_Script01             ; script 1
    dw ArenaLobby_Script02             ; script 2
    dw ArenaLobby_Script03             ; script 3
    dw ArenaLobby_Script04             ; script 4
    dw ArenaLobby_Script05             ; script 5
    dw ArenaLobby_Script06             ; script 6
    dw ArenaLobby_Script07             ; script 7
    dw ArenaLobby_Script08             ; script 8
    dw ArenaLobby_Script09             ; script 9
    dw ArenaLobby_Script10             ; script 10
    dw ArenaLobby_Script11             ; script 11
; ---------------------------------------------------------------------------
; ArenaLobby_Script00
; ---------------------------------------------------------------------------
ArenaLobby_Script00:
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $00F2  ; Text $00F2: "$43:$4912 *:Hm, its not fun."
    dw Bank0D_ScriptAddr_46F2          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_4228          ; -> branch target
    dw $FFFF  ; END

Bank0D_ScriptAddr_4228:
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $00FE  ; Text $00FE: "$43:$4CD1 *:The guy at the entrance! // He's my ri"
    dw $4270
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $4242
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

    db $27
    db $FF
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
    db $CD
    db $D9
    db $00
    db $00
    db $07
    db $FF
    db $01
    db $FF
    db $33
    db $00
    db $6C
    db $42
    db $01
    db $FF
    db $30
    db $00
    db $68
    db $42
    db $E3
    db $00
    db $FF
    db $FF
    db $79
    db $01
    db $FF
    db $FF
    db $3A
    db $04
    db $FF
    db $FF
    db $27
    db $FF
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
    db $01
    db $FF
    db $11
    db $01
    db $C6
    db $42
    db $15
    db $FF
    db $CE
    db $D9
    db $07
    db $00
    db $F6
    db $45
    db $15
    db $FF
    db $CE
    db $D9
    db $06
    db $00
    db $90
    db $45
    db $15
    db $FF
    db $CE
    db $D9
    db $05
    db $00
    db $3A
    db $45
    db $15
    db $FF
    db $CE
    db $D9
    db $04
    db $00
    db $1E
    db $45
    db $15
    db $FF
    db $CE
    db $D9
    db $03
    db $00
    db $32
    db $44
    db $15
    db $FF
    db $CE
    db $D9
    db $02
    db $00
    db $D2
    db $43
    db $15
    db $FF
    db $CE
    db $D9
    db $01
    db $00
    db $92
    db $43
    db $15
    db $FF
    db $CE
    db $D9
    db $00
    db $00
    db $D6
    db $42
    db $FF
    db $FF
    db $07
    db $FF
    db $D1
    db $07
    db $03
    db $FF
    db $FD
    db $00
    db $12
    db $FF
    db $CD
    db $D9
    db $00
    db $00
    db $FF
    db $FF
    db $12
    db $FF
    db $B4
    db $CA
    db $01
    db $00
    db $03
    db $FF
    db $30
    db $00
    db $12
    db $FF
    db $2B
    db $D9
    db $00
    db $00
    db $12
    db $FF
    db $2F
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $31
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $3C
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $41
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $CD
    db $D9
    db $00
    db $00
    db $07
    db $FF
    db $E4
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $00
    db $00
    db $21
    db $FF
    db $51
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0B
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $48
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0B
    db $FF
    db $03
    db $00
    db $E0
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $3D
    db $FF
    db $07
    db $FF
    db $E5
    db $00
    db $1B
    db $FF
    db $03
    db $00
    db $30
    db $00
    db $1B
    db $FF
    db $00
    db $00
    db $30
    db $00
    db $19
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $01
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $03
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $07
    db $00
    db $21
    db $FF
    db $51
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $0F
    db $00
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $40
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $40
    db $00
    db $08
    db $FF
    db $0F
    db $FF
    db $00
    db $00
    db $E8
    db $00
    db $58
    db $00
    db $FF
    db $FF
    db $12
    db $FF
    db $B4
    db $CA
    db $02
    db $00
    db $03
    db $FF
    db $31
    db $00
    db $12
    db $FF
    db $2F
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $31
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $33
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $3C
    db $D9
    db $04
    db $00
    db $12
    db $FF
    db $52
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $53
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $54
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $CD
    db $D9
    db $00
    db $00
    db $07
    db $FF
    db $7A
    db $01
    db $FF
    db $FF
    db $12
    db $FF
    db $B4
    db $CA
    db $03
    db $00
    db $03
    db $FF
    db $32
    db $00
    db $12
    db $FF
    db $3B
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $42
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $CD
    db $D9
    db $00
    db $00
    db $00
    db $FF
    db $31
    db $00
    db $FA
    db $43
    db $07
    db $FF
    db $B6
    db $01
    db $FF
    db $FF
    db $03
    db $FF
    db $31
    db $00
    db $03
    db $FF
    db $49
    db $00
    db $12
    db $FF
    db $2F
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $31
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $33
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $3C
    db $D9
    db $04
    db $00
    db $12
    db $FF
    db $52
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $53
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $54
    db $D9
    db $01
    db $00
    db $07
    db $FF
    db $B7
    db $01
    db $FF
    db $FF
    db $01
    db $FF
    db $32
    db $00
    db $3C
    db $44
    db $03
    db $FF
    db $19
    db $01
    db $12
    db $FF
    db $B4
    db $CA
    db $04
    db $00
    db $03
    db $FF
    db $31
    db $00
    db $03
    db $FF
    db $32
    db $00
    db $03
    db $FF
    db $33
    db $00
    db $12
    db $FF
    db $2B
    db $D9
    db $00
    db $00
    db $12
    db $FF
    db $2F
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $31
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $33
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $3B
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $3C
    db $D9
    db $04
    db $00
    db $12
    db $FF
    db $42
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $52
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $53
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $54
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $CD
    db $D9
    db $00
    db $00
    db $07
    db $FF
    db $1C
    db $02
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $00
    db $00
    db $21
    db $FF
    db $51
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0B
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $48
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0B
    db $FF
    db $03
    db $00
    db $E0
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $3D
    db $FF
    db $07
    db $FF
    db $1D
    db $02
    db $1B
    db $FF
    db $03
    db $00
    db $30
    db $00
    db $1B
    db $FF
    db $00
    db $00
    db $30
    db $00
    db $19
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $01
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $03
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $07
    db $00
    db $21
    db $FF
    db $51
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $0F
    db $00
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $40
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $40
    db $00
    db $08
    db $FF
    db $0F
    db $FF
    db $00
    db $00
    db $E8
    db $00
    db $58
    db $00
    db $FF
    db $FF
    db $12
    db $FF
    db $B4
    db $CA
    db $05
    db $00
    db $03
    db $FF
    db $34
    db $00
    db $12
    db $FF
    db $3B
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $CD
    db $D9
    db $00
    db $00
    db $07
    db $FF
    db $E1
    db $02
    db $FF
    db $FF
    db $12
    db $FF
    db $B4
    db $CA
    db $06
    db $00
    db $03
    db $FF
    db $35
    db $00
    db $12
    db $FF
    db $39
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $3D
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $45
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $46
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $47
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $63
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $64
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $CD
    db $D9
    db $00
    db $00
    db $00
    db $FF
    db $34
    db $00
    db $80
    db $45
    db $07
    db $FF
    db $41
    db $03
    db $FF
    db $FF
    db $03
    db $FF
    db $34
    db $00
    db $12
    db $FF
    db $3B
    db $D9
    db $03
    db $00
    db $07
    db $FF
    db $42
    db $03
    db $FF
    db $FF
    db $12
    db $FF
    db $B4
    db $CA
    db $07
    db $00
    db $03
    db $FF
    db $36
    db $00
    db $12
    db $FF
    db $3D
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $CD
    db $D9
    db $00
    db $00
    db $00
    db $FF
    db $35
    db $00
    db $B2
    db $45
    db $07
    db $FF
    db $9F
    db $03
    db $FF
    db $FF
    db $03
    db $FF
    db $35
    db $00
    db $12
    db $FF
    db $39
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $45
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $46
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $47
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $63
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $64
    db $D9
    db $01
    db $00
    db $00
    db $FF
    db $34
    db $00
    db $E6
    db $45
    db $07
    db $FF
    db $A1
    db $03
    db $FF
    db $FF
    db $03
    db $FF
    db $34
    db $00
    db $12
    db $FF
    db $3B
    db $D9
    db $03
    db $00
    db $07
    db $FF
    db $A0
    db $03
    db $FF
    db $FF
    db $01
    db $FF
    db $36
    db $00
    db $00
    db $46
    db $03
    db $FF
    db $1C
    db $01
    db $12
    db $FF
    db $B4
    db $CA
    db $08
    db $00
    db $03
    db $FF
    db $34
    db $00
    db $03
    db $FF
    db $35
    db $00
    db $03
    db $FF
    db $36
    db $00
    db $03
    db $FF
    db $37
    db $00
    db $12
    db $FF
    db $2B
    db $D9
    db $00
    db $00
    db $12
    db $FF
    db $36
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $37
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $38
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $39
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $3B
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $3D
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $45
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $46
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $47
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $63
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $64
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $CD
    db $D9
    db $00
    db $00
    db $07
    db $FF
    db $F1
    db $03
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $00
    db $00
    db $21
    db $FF
    db $51
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0B
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $48
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0B
    db $FF
    db $03
    db $00
    db $E0
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $3D
    db $FF
    db $07
    db $FF
    db $F2
    db $03
    db $1B
    db $FF
    db $03
    db $00
    db $30
    db $00
    db $1B
    db $FF
    db $00
    db $00
    db $30
    db $00
    db $19
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $01
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $03
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $07
    db $00
    db $21
    db $FF
    db $51
    db $00
    db $0B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $12
    db $FF
    db $ED
    db $C8
    db $0F
    db $00
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $40
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $40
    db $00
    db $08
    db $FF
    db $0F
    db $FF
    db $00
    db $00
    db $E8
    db $00
    db $58
    db $00
    db $FF
    db $FF
Bank0D_ScriptAddr_46F2:
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF44  ; Cmd44
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script01
; ---------------------------------------------------------------------------
ArenaLobby_Script01:
    dw $FF15  ; PlaySE
    dw $C8ED  ; RAM $C8ED
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_470E          ; -> branch target
    dw $FFFF  ; END

Bank0D_ScriptAddr_470E:
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFD0  ; Cmd$D0
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4A  ; Cmd4A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4A  ; Cmd4A
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000E  ; Text $000E: "$42:$483B Terry looked at a stuffed animal. // Som"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script02
; ---------------------------------------------------------------------------
ArenaLobby_Script02:
    dw $FF2D  ; EventDispatch
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script03
; ---------------------------------------------------------------------------
ArenaLobby_Script03:
    dw $FF2D  ; EventDispatch
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script04
; ---------------------------------------------------------------------------
ArenaLobby_Script04:
    dw $FF2D  ; EventDispatch
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script05
; ---------------------------------------------------------------------------
ArenaLobby_Script05:
    dw $00EB  ; Text $00EB: "$43:$475D You hear a voice."
    dw $00EC  ; Text $00EC: "$43:$4772 *:Only those registered are // allowed h"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script06
; ---------------------------------------------------------------------------
ArenaLobby_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $0103  ; Text $0103: "$43:$4F3C *:Hi Ho Hi Ho. // *:Sigh.. I'm starving."
    dw Bank0D_ScriptAddr_4948          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0111  ; Text $0111: "$43:$547D *:I am Medal Man, the medal // collector"
    dw Bank0D_ScriptAddr_4940          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0110  ; Text $0110: "$43:$5375 *:Oh, welcome Mas...ahem. // I am the Me"
    dw Bank0D_ScriptAddr_490E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_48DC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_48A8          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_48A4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $007D
    dw Bank0D_ScriptAddr_4882          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_489A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_4896          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $005A  ; Text $005A: "$42:$70BB King:Oh, [HERO]! Did you bring // back H"
    dw Bank0D_ScriptAddr_4882          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0D_ScriptAddr_488A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0059  ; Text $0059: "$42:$7092 *:You are strong! I like you, // [HERO]."
    dw Bank0D_ScriptAddr_4882          ; -> branch target
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF03  ; SetEventFlag
    dw $0059  ; Text $0059: "$42:$7092 *:You are strong! I like you, // [HERO]."
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_47FE          ; -> branch target
    dw $FFFF  ; END

Bank0D_ScriptAddr_47FE:
    dw $FF04  ; ScreenEffect
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0710  ; Text $0710: "$22:$439E *:Welcome! Which class are you // regist"
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $4878
    dw $FF12  ; WriteRAM
    dw $D999  ; RAM $D999
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF12  ; WriteRAM
    dw $D9CD  ; RAM $D9CD
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF1F  ; EventTrigger
    dw $FF0F  ; SetScreenScroll
    dw $005D  ; Text $005D: "$42:$7314 Slio:[HERO]! Congratulations // on your "
    dw $0078
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

    db $13
    db $07
    db $12
    db $FF
    db $CD
    db $D9
    db $00
    db $00
    db $FF
    db $FF
Bank0D_ScriptAddr_4882:
    dw $0710  ; Text $0710: "$22:$439E *:Welcome! Which class are you // regist"
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_47FE          ; -> branch target
    dw $FFFF  ; END

Bank0D_ScriptAddr_488A:
    dw $0178  ; Text $0178: "$1A:$60D5 *:Oh [HERO],I was waiting for you. // *:"
    dw $FF03  ; SetEventFlag
    dw $005A  ; Text $005A: "$42:$70BB King:Oh, [HERO]! Did you bring // back H"
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_47FE          ; -> branch target
    dw $FFFF  ; END

Bank0D_ScriptAddr_4896:
    dw $027C  ; Text $027C: "$45:$59A0 *:Go to the Room of Strength & // Anger "
    dw $FFFF  ; END

Bank0D_ScriptAddr_489A:
    dw $02E0
    dw $FF03  ; SetEventFlag
    dw $007D
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_47FE          ; -> branch target
Bank0D_ScriptAddr_48A4:
    dw $044D
    dw $FFFF  ; END

Bank0D_ScriptAddr_48A8:
    dw $04AF  ; Text $04AF: "$48:$5D0B *:You made it! Good job! // *:Fight to y"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $48D8
    dw $04B1  ; Text $04B1: "$48:$5D82 *:Announcing the rep of GreatTree, // [H"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $D9CE  ; RAM $D9CE
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF12  ; WriteRAM
    dw $D999  ; RAM $D999
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF14  ; ClearGameFlags
    dw $4824
    dw $FFFF  ; END

    db $B0
    db $04
    db $FF
    db $FF
Bank0D_ScriptAddr_48DC:
    dw $07C7  ; Text $07C7: "$4B:$44EA *:[HERO]! Oh it's [HERO]! Welcome! // *:"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $490A
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $D9CE  ; RAM $D9CE
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw $FF12  ; WriteRAM
    dw $D999  ; RAM $D999
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF14  ; ClearGameFlags
    dw $4824
    dw $FFFF  ; END

    db $C8
    db $07
    db $FF
    db $FF
Bank0D_ScriptAddr_490E:
    dw $07CC  ; Text $07CC: "$4B:$4668 *:Are you ready to challenge the // Mast"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $493C
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $D9CE  ; RAM $D9CE
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw $FF12  ; WriteRAM
    dw $D999  ; RAM $D999
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF14  ; ClearGameFlags
    dw $4824
    dw $FFFF  ; END

    db $CD
    db $07
    db $FF
    db $FF
Bank0D_ScriptAddr_4940:
    dw $07D1  ; Text $07D1: "$4B:$48BB *:Ho Ho, Well done! You // defeated the "
    dw $FF03  ; SetEventFlag
    dw $00FD  ; Text $00FD: "$43:$4C99 *:May I help you? The restaurant is // b"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4948:
    dw $07D2  ; Text $07D2: "$4B:$49AA *:[HERO], to tell you the truth.... // *"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4978
    dw $08D4
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $D9CE  ; RAM $D9CE
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw $FF12  ; WriteRAM
    dw $D999  ; RAM $D999
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF14  ; ClearGameFlags
    dw $4824
    dw $FFFF  ; END

    db $D5
    db $08
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; ArenaLobby_Script07
; ---------------------------------------------------------------------------
ArenaLobby_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $00FE  ; Text $00FE: "$43:$4CD1 *:The guy at the entrance! // He's my ri"
    dw Bank0D_ScriptAddr_4ACA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0111  ; Text $0111: "$43:$547D *:I am Medal Man, the medal // collector"
    dw Bank0D_ScriptAddr_4AC0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0110  ; Text $0110: "$43:$5375 *:Oh, welcome Mas...ahem. // I am the Me"
    dw Bank0D_ScriptAddr_4AAC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_4A98          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00B0  ; Text $00B0: "$1A:$51D0 *:You say I should relax? // Wh...what d"
    dw Bank0D_ScriptAddr_4A84          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_4A7C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A4
    dw Bank0D_ScriptAddr_4A78          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_4A70          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_4A5E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_4A4C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0D_ScriptAddr_4A3A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_4A28          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_4A24          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_4A12          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_4A00          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0D_ScriptAddr_49EE          ; -> branch target
    dw $00E6  ; Text $00E6: "$43:$4490 *:Welcome to the arena! Want to // hear "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_49EA          ; -> branch target
    dw $00E7  ; Text $00E7: "$43:$44CE *:The battle classes go from // S,A down"
    dw $FFFF  ; END

Bank0D_ScriptAddr_49EA:
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $FFFF  ; END

Bank0D_ScriptAddr_49EE:
    dw $00E6  ; Text $00E6: "$43:$4490 *:Welcome to the arena! Want to // hear "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $49FC
    dw $00E7  ; Text $00E7: "$43:$44CE *:The battle classes go from // S,A down"
    dw $FFFF  ; END

    db $7B
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_4A00:
    dw $00E6  ; Text $00E6: "$43:$4490 *:Welcome to the arena! Want to // hear "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4A0E
    dw $00E7  ; Text $00E7: "$43:$44CE *:The battle classes go from // S,A down"
    dw $FFFF  ; END

    db $B8
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_4A12:
    dw $00E6  ; Text $00E6: "$43:$4490 *:Welcome to the arena! Want to // hear "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4A20
    dw $00E7  ; Text $00E7: "$43:$44CE *:The battle classes go from // S,A down"
    dw $FFFF  ; END

    db $1E
    db $02
    db $FF
    db $FF
Bank0D_ScriptAddr_4A24:
    dw $027D  ; Text $027D: "$45:$5A75 *:Until you settle the disaster // behin"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4A28:
    dw $00E6  ; Text $00E6: "$43:$4490 *:Welcome to the arena! Want to // hear "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4A36
    dw $02E2
    dw $FFFF  ; END

    db $E3
    db $02
    db $FF
    db $FF
Bank0D_ScriptAddr_4A3A:
    dw $00E6  ; Text $00E6: "$43:$4490 *:Welcome to the arena! Want to // hear "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4A48
    dw $02E2
    dw $FFFF  ; END

    db $43
    db $03
    db $FF
    db $FF
Bank0D_ScriptAddr_4A4C:
    dw $00E6  ; Text $00E6: "$43:$4490 *:Welcome to the arena! Want to // hear "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4A5A
    dw $02E2
    dw $FFFF  ; END

    db $A2
    db $03
    db $FF
    db $FF
Bank0D_ScriptAddr_4A5E:
    dw $00E6  ; Text $00E6: "$43:$4490 *:Welcome to the arena! Want to // hear "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4A6C
    dw $02E2
    dw $FFFF  ; END

    db $F3
    db $03
    db $FF
    db $FF
Bank0D_ScriptAddr_4A70:
    dw $044E
    dw $FF03  ; SetEventFlag
    dw $00A4
    dw $FFFF  ; END

Bank0D_ScriptAddr_4A78:
    dw $044F
    dw $FFFF  ; END

Bank0D_ScriptAddr_4A7C:
    dw $04B2  ; Text $04B2: "$48:$5DB0 *:The Starry Night Tournament // is foug"
    dw $FF03  ; SetEventFlag
    dw $00B0  ; Text $00B0: "$1A:$51D0 *:You say I should relax? // Wh...what d"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4A84:
    dw $04B3  ; Text $04B3: "$48:$5E79 *:Want to listen to the description // o"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4A92
    dw $01AD  ; Text $01AD: "$44:$4E34 *:Starry Night Tournament is a // match "
    dw $FFFF  ; END

    db $B4
    db $04
    db $14
    db $FF
    db $CC
    db $4A
Bank0D_ScriptAddr_4A98:
    dw $07C9  ; Text $07C9: "$4B:$45DE *:Want to listen to the // description o"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4AA6
    dw $07CA  ; Text $07CA: "$4B:$4617 *:Giggle... It'll be there // after the "
    dw $FFFF  ; END

    db $CB
    db $07
    db $14
    db $FF
    db $CC
    db $4A
Bank0D_ScriptAddr_4AAC:
    dw $07C9  ; Text $07C9: "$4B:$45DE *:Want to listen to the // description o"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4ABA
    dw $07CF  ; Text $07CF: "$4B:$479B *:The Master Monster Tamer will // bring"
    dw $FFFF  ; END

    db $CB
    db $07
    db $14
    db $FF
    db $CC
    db $4A
Bank0D_ScriptAddr_4AC0:
    dw $07D3  ; Text $07D3: "$4B:$4A49 *:Oh [HERO]! You really won! // *:Awesom"
    dw $FF03  ; SetEventFlag
    dw $00FE  ; Text $00FE: "$43:$4CD1 *:The guy at the entrance! // He's my ri"
    dw $FF14  ; ClearGameFlags
    dw $4ACC
Bank0D_ScriptAddr_4ACA:
    dw $07D4  ; Text $07D4: "$4B:$4A8D *:Oh [HERO]! Here is your surprise. // *"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $001A  ; Text $001A: "$42:$4C3F *:I see....."
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script08
; ---------------------------------------------------------------------------
ArenaLobby_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $0111  ; Text $0111: "$43:$547D *:I am Medal Man, the medal // collector"
    dw Bank0D_ScriptAddr_4AFC          ; -> branch target
    dw $00E9  ; Text $00E9: "$43:$470E *:Eeek! What? Talk to me // from the fro"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4AFC:
    dw $07D5  ; Text $07D5: "$4B:$4ABB *:What? Where are you? // *:Well whateve"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script09
; ---------------------------------------------------------------------------
ArenaLobby_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $0111  ; Text $0111: "$43:$547D *:I am Medal Man, the medal // collector"
    dw Bank0D_ScriptAddr_4B0A          ; -> branch target
    dw $00EA  ; Text $00EA: "$43:$473F *:Get out of my way! Huff!"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4B0A:
    dw $07D6  ; Text $07D6: "$4B:$4B2F *:Oh no! You tripped over // didn't you!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script10
; ---------------------------------------------------------------------------
ArenaLobby_Script10:
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
; ---------------------------------------------------------------------------
; ArenaLobby_Script11
; ---------------------------------------------------------------------------
ArenaLobby_Script11:
    dw $FF01  ; BranchIfFlagSet
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0D_ScriptAddr_4CF8          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_4CF0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_4CEC          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_4B30          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0096
    dw Bank0D_ScriptAddr_4CE8          ; -> branch target
Bank0D_ScriptAddr_4B30:
    dw $FF01  ; BranchIfFlagSet
    dw $0096
    dw Bank0D_ScriptAddr_4CE4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0095
    dw Bank0D_ScriptAddr_4CC6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_4CA4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_4C82          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_4C7E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $008B
    dw Bank0D_ScriptAddr_4C7A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $008A
    dw Bank0D_ScriptAddr_4C5C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0D_ScriptAddr_4C3A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0089
    dw Bank0D_ScriptAddr_4C36          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $007E
    dw Bank0D_ScriptAddr_4C32          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_4C2A          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw Bank0D_ScriptAddr_4B7E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0119  ; Text $0119: "$43:$59DB *:Superior masters... // *:have a well-b"
    dw Bank0D_ScriptAddr_4D1E          ; -> branch target
Bank0D_ScriptAddr_4B7E:
    dw $FF00  ; BranchIfFlagClear
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_4B8A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw Bank0D_ScriptAddr_4C26          ; -> branch target
Bank0D_ScriptAddr_4B8A:
    dw $FF01  ; BranchIfFlagSet
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw Bank0D_ScriptAddr_4C22          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $004F  ; Text $004F: "$42:$69A4 *:In the Chamber of Travelers' // Gates "
    dw Bank0D_ScriptAddr_4C04          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_4BA2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0119  ; Text $0119: "$43:$59DB *:Superior masters... // *:have a well-b"
    dw Bank0D_ScriptAddr_4CFC          ; -> branch target
Bank0D_ScriptAddr_4BA2:
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_4BE2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw Bank0D_ScriptAddr_4BDE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_4BDA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0D_ScriptAddr_4BD6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0121  ; Text $0121: "$43:$5E8F *:Leeet's Rumble!"
    dw Bank0D_ScriptAddr_4BC4          ; -> branch target
    dw $00ED  ; Text $00ED: "$43:$47A4 *:H...Hello! I'm T..T..Teto. // *:I'm ne"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4BC4:
    dw $044B
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4BD2
    dw $086B  ; Text $086B: "$4E:$42CF *:To win, train your monsters // behind "
    dw $FFFF  ; END

    db $6A
    db $08
    db $FF
    db $FF
Bank0D_ScriptAddr_4BD6:
    dw $017C  ; Text $017C: "$1A:$6384 *:M...my name is Teto. I survived // G c"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4BDA:
    dw $01B9  ; Text $01B9: "$44:$5558 *:Ha ha ha... It's E class. I // survive"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4BDE:
    dw $017D  ; Text $017D: "$1A:$646B *:E class.I am in E class. // *:Ha ha ha"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4BE2:
    dw $FF3C  ; Cmd3C
    dw $021F  ; Text $021F: "$1B:$4D95 *:Oh I'm sorry! I was rude...! // *:Give"
    dw $FF03  ; SetEventFlag
    dw $004F  ; Text $004F: "$42:$69A4 *:In the Chamber of Travelers' // Gates "
    dw $FF03  ; SetEventFlag
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF42  ; SetReturnMap
    dw $0134  ; Text $0134: "$43:$637F The Gate is shut tight."
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FF02  ; ClearEventFlag
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF3C  ; Cmd3C
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4C04:
    dw $FF3C  ; Cmd3C
    dw $022A  ; Text $022A: "$1B:$5027 *:Why don't you breed with my // IceMan?"
    dw $FF03  ; SetEventFlag
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF42  ; SetReturnMap
    dw $0134  ; Text $0134: "$43:$637F The Gate is shut tight."
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FF02  ; ClearEventFlag
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF3C  ; Cmd3C
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4C22:
    dw $022B  ; Text $022B: "$1B:$5091 *:I'll try not to boast so // much anymo"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4C26:
    dw $027E  ; Text $027E: "$45:$5AEB *:I guess staying on the farm means // n"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4C2A:
    dw $02E4
    dw $FF03  ; SetEventFlag
    dw $007E
    dw $FFFF  ; END

Bank0D_ScriptAddr_4C32:
    dw $02E5
    dw $FFFF  ; END

Bank0D_ScriptAddr_4C36:
    dw $02E6
    dw $FFFF  ; END

Bank0D_ScriptAddr_4C3A:
    dw $FF3C  ; Cmd3C
    dw $0344  ; Text $0344: "$46:$5CBD *:[HERO]! You're tough! // *:Way to go. "
    dw $FF03  ; SetEventFlag
    dw $008A
    dw $FF03  ; SetEventFlag
    dw $008B
    dw $FF42  ; SetReturnMap
    dw $0136  ; Text $0136: "$43:$63B3 The Gate is shut tight."
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FF02  ; ClearEventFlag
    dw $008B
    dw $FF3C  ; Cmd3C
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4C5C:
    dw $FF3C  ; Cmd3C
    dw $0854
    dw $FF03  ; SetEventFlag
    dw $008B
    dw $FF42  ; SetReturnMap
    dw $0136  ; Text $0136: "$43:$63B3 The Gate is shut tight."
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FF02  ; ClearEventFlag
    dw $008B
    dw $FF3C  ; Cmd3C
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4C7A:
    dw $034F  ; Text $034F: "$46:$5FF3 *:When two of the same kind of // monste"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4C7E:
    dw $03A3
    dw $FFFF  ; END

Bank0D_ScriptAddr_4C82:
    dw $FF3C  ; Cmd3C
    dw $03F4  ; Text $03F4: "$47:$557F *[HERO], nothing left but S class. // *:"
    dw $FF03  ; SetEventFlag
    dw $0095
    dw $FF03  ; SetEventFlag
    dw $0096
    dw $FF42  ; SetReturnMap
    dw $0139  ; Text $0139: "$43:$644A Wow,a TinyMedal! But cannot carry // any"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FF02  ; ClearEventFlag
    dw $0096
    dw $FF3C  ; Cmd3C
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4CA4:
    dw $FF3C  ; Cmd3C
    dw $0450
    dw $FF03  ; SetEventFlag
    dw $0095
    dw $FF03  ; SetEventFlag
    dw $0096
    dw $FF42  ; SetReturnMap
    dw $0139  ; Text $0139: "$43:$644A Wow,a TinyMedal! But cannot carry // any"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FF02  ; ClearEventFlag
    dw $0096
    dw $FF3C  ; Cmd3C
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4CC6:
    dw $FF3C  ; Cmd3C
    dw $0855
    dw $FF03  ; SetEventFlag
    dw $0096
    dw $FF42  ; SetReturnMap
    dw $0139  ; Text $0139: "$43:$644A Wow,a TinyMedal! But cannot carry // any"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FF02  ; ClearEventFlag
    dw $0096
    dw $FF3C  ; Cmd3C
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4CE4:
    dw $03F7  ; Text $03F7: "$47:$5682 *:When a monster learns two certain // s"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4CE8:
    dw $0451
    dw $FFFF  ; END

Bank0D_ScriptAddr_4CEC:
    dw $04B5  ; Text $04B5: "$48:$5F05 *:You made it! // *:I can't even come cl"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4CF0:
    dw $07D7  ; Text $07D7: "$4B:$4B9F *:[HERO]! Congratulations // on your vic"
    dw $FF03  ; SetEventFlag
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4CF8:
    dw $07D8  ; Text $07D8: "$4B:$4D0E *:I..I heard that monsters exist in // t"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4CFC:
    dw $FF3C  ; Cmd3C
    dw $07D0  ; Text $07D0: "$4B:$4818 *:You survived D class! // *:I'm still i"
    dw $FF03  ; SetEventFlag
    dw $004F  ; Text $004F: "$42:$69A4 *:In the Chamber of Travelers' // Gates "
    dw $FF03  ; SetEventFlag
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF42  ; SetReturnMap
    dw $0134  ; Text $0134: "$43:$637F The Gate is shut tight."
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FF02  ; ClearEventFlag
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF3C  ; Cmd3C
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4D1E:
    dw $0858
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms Per-Script Table (map_type=$07, 27 scripts)
; ---------------------------------------------------------------------------
ArenaRooms_ScriptPtrTable:
    dw ArenaRooms_Script00             ; script 0
    dw ArenaRooms_Script01             ; script 1
    dw ArenaRooms_Script02             ; script 2
    dw ArenaRooms_Script03             ; script 3
    dw ArenaRooms_Script04             ; script 4
    dw ArenaRooms_Script05             ; script 5
    dw ArenaRooms_Script06             ; script 6
    dw ArenaRooms_Script07             ; script 7
    dw ArenaRooms_Script08             ; script 8
    dw ArenaRooms_Script09             ; script 9
    dw ArenaRooms_Script10             ; script 10
    dw ArenaRooms_Script11             ; script 11
    dw ArenaRooms_Script12             ; script 12
    dw ArenaRooms_Script13             ; script 13
    dw ArenaRooms_Script14             ; script 14
    dw ArenaRooms_Script15             ; script 15
    dw ArenaRooms_Script16             ; script 16
    dw ArenaRooms_Script17             ; script 17
    dw ArenaRooms_Script18             ; script 18
    dw ArenaRooms_Script19             ; script 19
    dw ArenaRooms_Script20             ; script 20
    dw ArenaRooms_Script21             ; script 21
    dw ArenaRooms_Script22             ; script 22
    dw ArenaRooms_Script23             ; script 23
    dw ArenaRooms_Script24             ; script 24
    dw ArenaRooms_Script25             ; script 25
    dw ArenaRooms_Script26             ; script 26
; ---------------------------------------------------------------------------
; ArenaRooms_Script00
; ---------------------------------------------------------------------------
ArenaRooms_Script00:
    dw $FF15  ; PlaySE
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_4D70          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_4D68          ; -> branch target
    dw $FFFF  ; END

Bank0D_ScriptAddr_4D68:
    dw $FF12  ; WriteRAM
    dw $D9CB  ; RAM $D9CB
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4D70:
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF1B  ; MultiRAMWrite
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF1B  ; MultiRAMWrite
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF1B  ; MultiRAMWrite
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0050  ; Text $0050: "$42:$6ABA Pulio:Sorry [HERO], It's my fault... // "
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script01
; ---------------------------------------------------------------------------
ArenaRooms_Script01:
    dw $FF15  ; PlaySE
    dw $D9CB  ; RAM $D9CB
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_4EAE          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF24  ; Cmd24
    dw Bank0D_ScriptAddr_4EEC          ; -> branch target
    dw $FF61  ; Cmd61
    dw Bank0D_ScriptAddr_4EFA          ; -> branch target
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF07  ; InitDialogMode
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_4EE6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_4EE0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_4EDA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_4ED4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_4ECE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0D_ScriptAddr_4EC8          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_4EC2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_4EBC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_4EB6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0D_ScriptAddr_4EB0          ; -> branch target
    dw $00F0  ; Text $00F0: "$43:$48CD *:Where did the MiniDrak go?"
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF12  ; WriteRAM
    dw $D9CB  ; RAM $D9CB
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0D_ScriptAddr_4EAE:
    dw $FFFF  ; END

Bank0D_ScriptAddr_4EB0:
    dw $017F  ; Text $017F: "$1A:$65D7 *:An eye ball in an EyeBall! Funny?"
    dw $FF14  ; ClearGameFlags
    dw $4E8C
Bank0D_ScriptAddr_4EB6:
    dw $01BB  ; Text $01BB: "$44:$570B *:BigRoost is roasting big time!"
    dw $FF14  ; ClearGameFlags
    dw $4E8C
Bank0D_ScriptAddr_4EBC:
    dw $022D  ; Text $022D: "$1B:$5192 *:Eyeder wider! Ha! Ha!"
    dw $FF14  ; ClearGameFlags
    dw $4E8C
Bank0D_ScriptAddr_4EC2:
    dw $0280  ; Text $0280: "$45:$5C21 *:MadGopher go mad go far! Funny?"
    dw $FF14  ; ClearGameFlags
    dw $4E8C
Bank0D_ScriptAddr_4EC8:
    dw $0351  ; Text $0351: "$46:$6188 *:Is this an Orc or Pork? // Funny?"
    dw $FF14  ; ClearGameFlags
    dw $4E8C
Bank0D_ScriptAddr_4ECE:
    dw $03A5
    dw $FF14  ; ClearGameFlags
    dw $4E8C
Bank0D_ScriptAddr_4ED4:
    dw $03F9  ; Text $03F9: "$47:$57C0 *:Yeti doesn't say yet. Funny?"
    dw $FF14  ; ClearGameFlags
    dw $4E8C
Bank0D_ScriptAddr_4EDA:
    dw $0453
    dw $FF14  ; ClearGameFlags
    dw $4E8C
Bank0D_ScriptAddr_4EE0:
    dw $04B7  ; Text $04B7: "$48:$5FB0 *:Wyvern!"
    dw $FF14  ; ClearGameFlags
    dw $4E8C
Bank0D_ScriptAddr_4EE6:
    dw $07DA  ; Text $07DA: "$4B:$4E24 *:That's it everyone."
    dw $FF14  ; ClearGameFlags
    dw $4E8C
Bank0D_ScriptAddr_4EEC:
    dw $00C6  ; Text $00C6: "$1A:$56D6 *:I know I'm careless but // I do help m"
    dw $7170
    dw $72D8
    dw $D873  ; RAM $D873
    dw $7170
    dw $72D8
    dw $D973  ; RAM $D973
Bank0D_ScriptAddr_4EFA:
    dw $00C6  ; Text $00C6: "$1A:$56D6 *:I know I'm careless but // I do help m"
    dw $0202  ; Text $0202: "$1B:$43A2 *:Oh! I see! There's a monster // in fro"
    dw $02D8
    dw $D802  ; RAM $D802
    dw $0202  ; Text $0202: "$1B:$43A2 *:Oh! I see! There's a monster // in fro"
    dw $02D8
    dw $D902  ; RAM $D902
; ---------------------------------------------------------------------------
; ArenaRooms_Script02
; ---------------------------------------------------------------------------
ArenaRooms_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_4F26          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_4F22          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_4F1E          ; -> branch target
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw $FFFF  ; END

Bank0D_ScriptAddr_4F1E:
    dw $022C  ; Text $022C: "$1B:$50DB *:Monsters can learn three // special sk"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4F22:
    dw $03A4
    dw $FFFF  ; END

Bank0D_ScriptAddr_4F26:
    dw $01BA  ; Text $01BA: "$44:$55D8 *:The bishop over there taught // me a s"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script03
; ---------------------------------------------------------------------------
ArenaRooms_Script03:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_5022          ; -> branch target
    dw $FF2E  ; Cmd2E
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_4F52          ; -> branch target
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_4F52          ; -> branch target
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0D_ScriptAddr_4F52:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF3C  ; Cmd3C
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_4F8A          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_4F94          ; -> branch target
Bank0D_ScriptAddr_4F7A:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw Bank0D_ScriptAddr_4F9E          ; -> branch target
    dw $00F4  ; Text $00F4: "$43:$49ED *:Darn! Again!"
    dw $FF2F  ; Cmd2F
    dw $D9DF  ; RAM $D9DF
    dw $FFFF  ; END

Bank0D_ScriptAddr_4F8A:
    dw $00F6  ; Text $00F6: "$43:$4A22 *:It's a tie... In this case... // *:I w"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4F94:
    dw $00F5  ; Text $00F5: "$43:$4A00 *:I won! Challenge me anytime!"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0D_ScriptAddr_4F9E:
    dw $00F7  ; Text $00F7: "$43:$4A62 *:You! You're good! // *:Look! I'll tell"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF61  ; Cmd61
    dw $502C
    dw $FF24  ; Cmd24
    dw $5024
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF61  ; Cmd61
    dw $503C
    dw $FF24  ; Cmd24
    dw $5034
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF61  ; Cmd61
    dw $502C
    dw $FF24  ; Cmd24
    dw $5024
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF61  ; Cmd61
    dw $503C
    dw $FF24  ; Cmd24
    dw $5034
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF61  ; Cmd61
    dw $502C
    dw $FF24  ; Cmd24
    dw $5024
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF61  ; Cmd61
    dw $503C
    dw $FF24  ; Cmd24
    dw $5034
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF61  ; Cmd61
    dw $502C
    dw $FF24  ; Cmd24
    dw $5024
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF61  ; Cmd61
    dw $503C
    dw $FF24  ; Cmd24
    dw $5034
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF61  ; Cmd61
    dw $502C
    dw $FF24  ; Cmd24
    dw $5024
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF03  ; SetEventFlag
    dw $000E  ; Text $000E: "$42:$483B Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D94C  ; RAM $D94C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0D_ScriptAddr_5022:
    dw $FFFF  ; END

    db $8A
    db $00
    db $74
    db $75
    db $D8
    db $76
    db $77
    db $D9
    db $8A
    db $00
    db $01
    db $01
    db $D8
    db $01
    db $01
    db $D9
    db $8A
    db $00
    db $66
    db $67
    db $D8
    db $72
    db $73
    db $D9
    db $8A
    db $00
    db $02
    db $02
    db $D8
    db $02
    db $02
    db $D9
; ---------------------------------------------------------------------------
; ArenaRooms_Script04
; ---------------------------------------------------------------------------
ArenaRooms_Script04:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_5022          ; -> branch target
    dw $FF2E  ; Cmd2E
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_506C          ; -> branch target
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_506C          ; -> branch target
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0D_ScriptAddr_506C:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF3C  ; Cmd3C
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_4F8A          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_4F94          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_4F7A          ; -> branch target
; ---------------------------------------------------------------------------
; ArenaRooms_Script05
; ---------------------------------------------------------------------------
ArenaRooms_Script05:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_5022          ; -> branch target
    dw $FF2E  ; Cmd2E
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_50C0          ; -> branch target
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_50C0          ; -> branch target
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0D_ScriptAddr_50C0:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF3C  ; Cmd3C
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_4F8A          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_4F94          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_4F7A          ; -> branch target
; ---------------------------------------------------------------------------
; ArenaRooms_Script06
; ---------------------------------------------------------------------------
ArenaRooms_Script06:
    dw $FF00  ; BranchIfFlagClear
    dw $000E  ; Text $000E: "$42:$483B Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_50F8          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_5120          ; -> branch target
Bank0D_ScriptAddr_50F8:
    dw $FF01  ; BranchIfFlagSet
    dw $000E  ; Text $000E: "$42:$483B Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_511C          ; -> branch target
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5112          ; -> branch target
    dw $00F3  ; Text $00F3: "$43:$4928 *:Select your choice by stepping // on t"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFFF  ; END

Bank0D_ScriptAddr_5112:
    dw $00F2  ; Text $00F2: "$43:$4912 *:Hm, its not fun."
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0D_ScriptAddr_511C:
    dw $00F8  ; Text $00F8: "$43:$4ADE *:You're good..."
    dw $FFFF  ; END

Bank0D_ScriptAddr_5120:
    dw $02E7
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script07
; ---------------------------------------------------------------------------
ArenaRooms_Script07:
    dw $FF00  ; BranchIfFlagClear
    dw $000E  ; Text $000E: "$42:$483B Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_514E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_518C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_517A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_5176          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_5172          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_516E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_516A          ; -> branch target
Bank0D_ScriptAddr_514E:
    dw $FF01  ; BranchIfFlagSet
    dw $000E  ; Text $000E: "$42:$483B Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_5166          ; -> branch target
    dw $00F9  ; Text $00F9: "$43:$4AF2 *:Want to know where the wife // of the "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5162          ; -> branch target
    dw $00FB  ; Text $00FB: "$43:$4B5E *:You can meet her if you win at // rock"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5162:
    dw $00FA  ; Text $00FA: "$43:$4B43 *:I bet you wanna know."
    dw $FFFF  ; END

Bank0D_ScriptAddr_5166:
    dw $013D  ; Text $013D: "$43:$655F *:Have you been using the // Bookmark? /"
    dw $FFFF  ; END

Bank0D_ScriptAddr_516A:
    dw $022E  ; Text $022E: "$1B:$51AD *:I don't know about his // personality "
    dw $FFFF  ; END

Bank0D_ScriptAddr_516E:
    dw $0281  ; Text $0281: "$45:$5C46 *:You beat Mick? You're one tough // coo"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5172:
    dw $02E8
    dw $FFFF  ; END

Bank0D_ScriptAddr_5176:
    dw $03A6
    dw $FFFF  ; END

Bank0D_ScriptAddr_517A:
    dw $03FA  ; Text $03FA: "$47:$57E1 *:You're having trouble with the // mons"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5188
    dw $03FB  ; Text $03FB: "$47:$5821 *:You see the merchant with an // attitu"
    dw $FFFF  ; END

    db $B4
    db $02
    db $FF
    db $FF
Bank0D_ScriptAddr_518C:
    dw $07DD  ; Text $07DD: "$4B:$4EF8 *:A Servant has 4 hands, Skeletor // has"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script08
; ---------------------------------------------------------------------------
ArenaRooms_Script08:
    dw $FF00  ; BranchIfFlagClear
    dw $000E  ; Text $000E: "$42:$483B Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_51B4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00FC  ; Text $00FC: "$43:$4C04 *:These statues are the protectors // of"
    dw Bank0D_ScriptAddr_51D2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_51CE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_51CA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0083
    dw Bank0D_ScriptAddr_51C6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_51C2          ; -> branch target
Bank0D_ScriptAddr_51B4:
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_51BE          ; -> branch target
    dw $00FC  ; Text $00FC: "$43:$4C04 *:These statues are the protectors // of"
    dw $FFFF  ; END

Bank0D_ScriptAddr_51BE:
    dw $022F  ; Text $022F: "$1B:$526E *:These statues stand as the // protecto"
    dw $FFFF  ; END

Bank0D_ScriptAddr_51C2:
    dw $02E9
    dw $FFFF  ; END

Bank0D_ScriptAddr_51C6:
    dw $02EA
    dw $FFFF  ; END

Bank0D_ScriptAddr_51CA:
    dw $04B8  ; Text $04B8: "$48:$5FBE *:Come on! Pray! Pray to the // statue o"
    dw $FFFF  ; END

Bank0D_ScriptAddr_51CE:
    dw $07DB  ; Text $07DB: "$4B:$4E3C *:One of my friends from // abroad is an"
    dw $FFFF  ; END

Bank0D_ScriptAddr_51D2:
    dw $07DC  ; Text $07DC: "$4B:$4EB3 *:You! I heard you finally made // Watab"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script09
; ---------------------------------------------------------------------------
ArenaRooms_Script09:
    dw $0100  ; Text $0100: "$43:$4DEC [HERO] looked into the jar. // An old la"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_51E4          ; -> branch target
    dw $086F  ; Text $086F: "$4E:$4586 :If you choose CHARGE you can // train t"
    dw $FFFF  ; END

Bank0D_ScriptAddr_51E4:
    dw $0870  ; Text $0870: "$4E:$4721 [HERO] returned the old lady's // notebo"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script10
; ---------------------------------------------------------------------------
ArenaRooms_Script10:
    dw $0101  ; Text $0101: "$43:$4E4F [HERO] looked into the jar. // A piece o"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script11
; ---------------------------------------------------------------------------
ArenaRooms_Script11:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_520A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_5206          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_5202          ; -> branch target
    dw $00FD  ; Text $00FD: "$43:$4C99 *:May I help you? The restaurant is // b"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5202:
    dw $0230  ; Text $0230: "$1B:$530D *:Monsters need education too! // *:Pers"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5206:
    dw $03A7
    dw $FFFF  ; END

Bank0D_ScriptAddr_520A:
    dw $07DE  ; Text $07DE: "$4B:$4F53 *:The bishop I know told me an // intens"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script12
; ---------------------------------------------------------------------------
ArenaRooms_Script12:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_523C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_5238          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_5226          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $006B  ; Text $006B: "$42:$7A6A Thwack! // It was the egg of a SkyDragon"
    dw Bank0D_ScriptAddr_5234          ; -> branch target
Bank0D_ScriptAddr_5226:
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_5230          ; -> branch target
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5230:
    dw $0232  ; Text $0232: "$1B:$5433 *:My rival is watching me... // *:But as"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5234:
    dw $03A9
    dw $FFFF  ; END

Bank0D_ScriptAddr_5238:
    dw $0455
    dw $FFFF  ; END

Bank0D_ScriptAddr_523C:
    dw $07E0  ; Text $07E0: "$4B:$5119 *:My slime learned an amazing skill! // "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script13
; ---------------------------------------------------------------------------
ArenaRooms_Script13:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_526E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_526A          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_5258          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $006B  ; Text $006B: "$42:$7A6A Thwack! // It was the egg of a SkyDragon"
    dw Bank0D_ScriptAddr_5266          ; -> branch target
Bank0D_ScriptAddr_5258:
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_5262          ; -> branch target
    dw $00FE  ; Text $00FE: "$43:$4CD1 *:The guy at the entrance! // He's my ri"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5262:
    dw $0231  ; Text $0231: "$1B:$53C2 *:The guy at the entrance to the // rest"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5266:
    dw $03A8
    dw $FFFF  ; END

Bank0D_ScriptAddr_526A:
    dw $0454
    dw $FFFF  ; END

Bank0D_ScriptAddr_526E:
    dw $07DF  ; Text $07DF: "$4B:$5039 *:The guy at the entrance to the // rest"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script14
; ---------------------------------------------------------------------------
ArenaRooms_Script14:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_529A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_5296          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_5292          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_528E          ; -> branch target
    dw $0102  ; Text $0102: "$43:$4EEE *:Hm.. It doesn't listen to me much. // "
    dw $FFFF  ; END

Bank0D_ScriptAddr_528E:
    dw $0233  ; Text $0233: "$1B:$5493 *:It's common sense to bring // BeastTai"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5292:
    dw $02EB
    dw $FFFF  ; END

Bank0D_ScriptAddr_5296:
    dw $0456
    dw $FFFF  ; END

Bank0D_ScriptAddr_529A:
    dw $07E1  ; Text $07E1: "$4B:$5191 *:Hurray! I understand now! // *:I can b"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script15
; ---------------------------------------------------------------------------
ArenaRooms_Script15:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_52C6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_52C2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_52BE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_52BA          ; -> branch target
    dw $0103  ; Text $0103: "$43:$4F3C *:Hi Ho Hi Ho. // *:Sigh.. I'm starving."
    dw $FFFF  ; END

Bank0D_ScriptAddr_52BA:
    dw $0234  ; Text $0234: "$1B:$55A7 *:Hi ho! Hi ho! // *:How long do I need "
    dw $FFFF  ; END

Bank0D_ScriptAddr_52BE:
    dw $02EC  ; Text $02EC: "$1F:$5377 *:Hi ho! Hi ho!"
    dw $FFFF  ; END

Bank0D_ScriptAddr_52C2:
    dw $0457
    dw $FFFF  ; END

Bank0D_ScriptAddr_52C6:
    dw $07E2  ; Text $07E2: "$4B:$5268 *:Hey hey hey! Run! Don't walk! // *:Yo,"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script16
; ---------------------------------------------------------------------------
ArenaRooms_Script16:
    dw $FF01  ; BranchIfFlagSet
    dw $0111  ; Text $0111: "$43:$547D *:I am Medal Man, the medal // collector"
    dw Bank0D_ScriptAddr_53CE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0110  ; Text $0110: "$43:$5375 *:Oh, welcome Mas...ahem. // I am the Me"
    dw Bank0D_ScriptAddr_53BC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_53B8          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_53A6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_5394          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_5382          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0D_ScriptAddr_5370          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_535E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_535A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_5348          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_5336          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0D_ScriptAddr_5324          ; -> branch target
    dw $0104  ; Text $0104: "$43:$4FA8 *:Yo man, wanna know who your // match i"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5320          ; -> branch target
    dw $0105  ; Text $0105: "$43:$4FE2 *:Its the principal of the // school."
    dw $FFFF  ; END

Bank0D_ScriptAddr_5320:
    dw $0106  ; Text $0106: "$43:$500D *:Well,it'll be OK too."
    dw $FFFF  ; END

Bank0D_ScriptAddr_5324:
    dw $0180  ; Text $0180: "$1A:$65FE *:Wanna know who's in the F class? [YES/"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5332
    dw $0181  ; Text $0181: "$1A:$6623 *:The last match in the F class is // wi"
    dw $FFFF  ; END

    db $06
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_5336:
    dw $01BC  ; Text $01BC: "$44:$572F *:Hee hee! Dude! Wanna know who // you'r"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5344
    dw $01BD  ; Text $01BD: "$44:$577E *:Teto in the waiting room will // fight"
    dw $FFFF  ; END

    db $06
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_5348:
    dw $0235  ; Text $0235: "$1B:$55E0 *:Wanna know your opponent // in D class"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5356
    dw $0236  ; Text $0236: "$1B:$560F *:Your last match in D class will be // "
    dw $FFFF  ; END

    db $06
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_535A:
    dw $0282  ; Text $0282: "$45:$5CFD *:Yo, dude! You're not allowed to // fig"
    dw $FFFF  ; END

Bank0D_ScriptAddr_535E:
    dw $02ED  ; Text $02ED: "$1F:$538B *:Yo dude! Do ya wanna know who // your "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $536C
    dw $02EE  ; Text $02EE: "$1F:$53D1 *:Your opponent for the last match // wi"
    dw $FFFF  ; END

    db $06
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_5370:
    dw $0352  ; Text $0352: "$46:$61B1 *:Hee hee! Yo dude, wanna know // who yo"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $537E
    dw $0353  ; Text $0353: "$46:$61F9 *:The last match will be against // the "
    dw $FFFF  ; END

    db $06
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_5382:
    dw $03AA
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5390
    dw $03AB
    dw $FFFF  ; END

    db $06
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_5394:
    dw $03FC  ; Text $03FC: "$47:$58B2 *:Hee hee! Yo dude, wanna know // who're"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $53A2
    dw $03FD  ; Text $03FD: "$47:$58FC *:The last match in S class will be // w"
    dw $FFFF  ; END

    db $FE
    db $03
    db $FF
    db $FF
Bank0D_ScriptAddr_53A6:
    dw $0458
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $53B4
    dw $0459
    dw $FFFF  ; END

    db $59
    db $04
    db $FF
    db $FF
Bank0D_ScriptAddr_53B8:
    dw $07E3  ; Text $07E3: "$4B:$528D *:Yo, dude, go to the reception. // *:Th"
    dw $FFFF  ; END

Bank0D_ScriptAddr_53BC:
    dw $07E4  ; Text $07E4: "$4B:$52D0 *:Yo, dude, wanna know about Master // M"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $53CA
    dw $07E5  ; Text $07E5: "$4B:$5315 *:He has GoldSlime Divinegon, & // Rosev"
    dw $FFFF  ; END

    db $E6
    db $07
    db $FF
    db $FF
Bank0D_ScriptAddr_53CE:
    dw $07E7  ; Text $07E7: "$4B:$5490 *:Darn! You really defeated the // Maste"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script17
; ---------------------------------------------------------------------------
ArenaRooms_Script17:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_5484          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_5480          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_546E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_5460          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_5452          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0D_ScriptAddr_5444          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_5436          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_5428          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_541A          ; -> branch target
    dw $0107  ; Text $0107: "$43:$5027 *:Want to hear about my journey // beyon"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5416          ; -> branch target
    dw $0108  ; Text $0108: "$43:$506B *:StubSucks & GoHoppers, // Anteaters & "
    dw $FFFF  ; END

Bank0D_ScriptAddr_5416:
    dw $0109  ; Text $0109: "$43:$51A8 *:My journey to the Travelers' // Gate i"
    dw $FFFF  ; END

Bank0D_ScriptAddr_541A:
    dw $0876  ; Text $0876: "$4E:$4A84 *:Would you like to hear about the // Ga"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5416          ; -> branch target
    dw $0877  ; Text $0877: "$4E:$4AC1 *:There were MiniDraks, // BigRoosts, Ev"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5428:
    dw $087C  ; Text $087C: "$4E:$5035 *:Would you like to hear about the // Ga"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5416          ; -> branch target
    dw $087D  ; Text $087D: "$4E:$506F *:There were BigRoosts, // SpotSlimes, C"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5436:
    dw $0883  ; Text $0883: "$4E:$54D9 *:Would you like to learn about the // G"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5416          ; -> branch target
    dw $0884  ; Text $0884: "$4E:$5514 *:There were GiantWorms, // Poisongons, "
    dw $FFFF  ; END

Bank0D_ScriptAddr_5444:
    dw $088C  ; Text $088C: "$4E:$5C86 *:Would you like to learn about the // G"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5416          ; -> branch target
    dw $088D  ; Text $088D: "$4E:$5CBF *:There were Snailys, Saccers, // Gulppl"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5452:
    dw $0890  ; Text $0890: "$4E:$5FB3 *:Would you like to hear about the // Ga"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5416          ; -> branch target
    dw $0891  ; Text $0891: "$4E:$5FF1 *:There are Onionos, // Gophecadas, Pixy"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5460:
    dw $089B  ; Text $089B: "$4E:$6889 *:Gate of Labyrinth. Want to // learn ab"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5416          ; -> branch target
    dw $089C  ; Text $089C: "$4E:$68BE *:There are RockSlimes, // Chamelgons, C"
    dw $FFFF  ; END

Bank0D_ScriptAddr_546E:
    dw $089F  ; Text $089F: "$4E:$6B4B *:You want to learn about // the Gate of"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $547C
    dw $08A0  ; Text $08A0: "$4E:$6B85 *:I don't want to tell you this. // *:I "
    dw $FFFF  ; END

    db $A1
    db $08
    db $FF
    db $FF
Bank0D_ScriptAddr_5480:
    dw $08A5  ; Text $08A5: "$4E:$6E90 *:I,I thought you went to the Gate // of"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5484:
    dw $01DD  ; Text $01DD: "$44:$6F3E *:In the far recesses of the // Chamber "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script18
; ---------------------------------------------------------------------------
ArenaRooms_Script18:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_553A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_5536          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_5524          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_5516          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_5508          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0D_ScriptAddr_54FA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_54EC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_54DE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_54D0          ; -> branch target
    dw $010A  ; Text $010A: "$43:$51EE *:Want to know about the monsters // beh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_54CC          ; -> branch target
    dw $0874  ; Text $0874: "$4E:$4957 *:There will be Spookys, ArmyAnts, // An"
    dw $FFFF  ; END

Bank0D_ScriptAddr_54CC:
    dw $0875  ; Text $0875: "$4E:$4A71 *:Humpf, okay."
    dw $FFFF  ; END

Bank0D_ScriptAddr_54D0:
    dw $0878  ; Text $0878: "$4E:$4C5F *:Want to know about the monsters // beh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_54CC          ; -> branch target
    dw $0879  ; Text $0879: "$4E:$4CA5 *:There were Goopis, // PillowRats, Drag"
    dw $FFFF  ; END

Bank0D_ScriptAddr_54DE:
    dw $087E  ; Text $087E: "$4E:$519E *:Want to know about the monsters // beh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_54CC          ; -> branch target
    dw $087F  ; Text $087F: "$4E:$51E3 *:There are Demonites, // BeanMen, 1EyeC"
    dw $FFFF  ; END

Bank0D_ScriptAddr_54EC:
    dw $0885  ; Text $0885: "$4E:$5696 *:Want to know about the monsters // beh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_54CC          ; -> branch target
    dw $0886  ; Text $0886: "$4E:$56DC *:There are MudDolls, // TreeSlimes, Sku"
    dw $FFFF  ; END

Bank0D_ScriptAddr_54FA:
    dw $088E  ; Text $088E: "$4E:$5E49 *:Want to know about the monsters // beh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_54CC          ; -> branch target
    dw $088F  ; Text $088F: "$4E:$5E8D *:There are Facers, // Tonguellas, Flora"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5508:
    dw $0892  ; Text $0892: "$4E:$60F2 *:Want to know about the monsters // beh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_54CC          ; -> branch target
    dw $0893  ; Text $0893: "$4E:$613A *:There are SpikyBoys, // KingCobras, Mo"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5516:
    dw $089D  ; Text $089D: "$4E:$69F4 *:Want to know about the monsters // beh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_54CC          ; -> branch target
    dw $089E  ; Text $089E: "$4E:$6A3A *:There are WeedBugs, // HammerMen, MadG"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5524:
    dw $08A2  ; Text $08A2: "$4E:$6CE4 *:What? You want to know // about the Ga"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5532
    dw $08A3  ; Text $08A3: "$4E:$6D23 *:I see... I don't remember much... // *"
    dw $FFFF  ; END

    db $A4
    db $08
    db $FF
    db $FF
Bank0D_ScriptAddr_5536:
    dw $08A6  ; Text $08A6: "$4E:$6F15 *:Oh, you haven't visited the Gate // of"
    dw $FFFF  ; END

Bank0D_ScriptAddr_553A:
    dw $024D  ; Text $024D: "$45:$4625 *:If you've got money you should // get "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script19
; ---------------------------------------------------------------------------
ArenaRooms_Script19:
    dw $0137  ; Text $0137: "$43:$63CD [HERO] looked into the barrel. // Someth"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script20
; ---------------------------------------------------------------------------
ArenaRooms_Script20:
    dw $FF01  ; BranchIfFlagSet
    dw $003C  ; Text $003C: "$42:$5F28 *:Hey you! You came here to // steal my "
    dw Bank0D_ScriptAddr_555E          ; -> branch target
    dw $0138  ; Text $0138: "$43:$642D [HERO] looked into the barrel."
    dw $FF2C  ; CheckInvFull
    dw Bank0D_ScriptAddr_555A          ; -> branch target
    dw $0129  ; Text $0129: "$43:$60FA Wow! [HERO] got a TinyMedal!"
    dw $FF2A  ; GiveItem
    dw $001E  ; Text $001E: "$42:$4CEA [HERO] opened a treasure chest!"
    dw $FF03  ; SetEventFlag
    dw $003C  ; Text $003C: "$42:$5F28 *:Hey you! You came here to // steal my "
    dw $FFFF  ; END

Bank0D_ScriptAddr_555A:
    dw $0139  ; Text $0139: "$43:$644A Wow,a TinyMedal! But cannot carry // any"
    dw $FFFF  ; END

Bank0D_ScriptAddr_555E:
    dw $013A  ; Text $013A: "$43:$64AE [HERO] looked into the barrel. // Nothin"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script21
; ---------------------------------------------------------------------------
ArenaRooms_Script21:
    dw $013A  ; Text $013A: "$43:$64AE [HERO] looked into the barrel. // Nothin"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script22
; ---------------------------------------------------------------------------
ArenaRooms_Script22:
    dw $013B  ; Text $013B: "$43:$64DE [HERO] looked into the barrel. // A mons"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script23
; ---------------------------------------------------------------------------
ArenaRooms_Script23:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_55CA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_55C0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_55B6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_55AC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_55A2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_5598          ; -> branch target
    dw $010B  ; Text $010B: "$43:$5234 *:This is an llonigirill. C'mon // BeBe,"
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw $FF03  ; SetEventFlag
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5598:
    dw $0237  ; Text $0237: "$1B:$56DF *:These are a pair of hashis. Bebe, // R"
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw $FF03  ; SetEventFlag
    dw $005B  ; Text $005B: "$42:$71FE Pulio:Thank you [HERO]! Now I // can go "
    dw $FFFF  ; END

Bank0D_ScriptAddr_55A2:
    dw $02F1  ; Text $02F1: "$1F:$566E *:This is miso shiru. Bebe, // repeat af"
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw $FF03  ; SetEventFlag
    dw $007F
    dw $FFFF  ; END

Bank0D_ScriptAddr_55AC:
    dw $03AE
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw $FF03  ; SetEventFlag
    dw $0091
    dw $FFFF  ; END

Bank0D_ScriptAddr_55B6:
    dw $045A
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw $FF03  ; SetEventFlag
    dw $00A5  ; Text $00A5: "$1A:$4E6E *:I always think about what kind of // f"
    dw $FFFF  ; END

Bank0D_ScriptAddr_55C0:
    dw $04BC  ; Text $04BC: "$48:$616A *:This is Shoyu! Bebe! Repeat after // m"
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw $FF03  ; SetEventFlag
    dw $00B1
    dw $FFFF  ; END

Bank0D_ScriptAddr_55CA:
    dw $07EA  ; Text $07EA: "$4B:$5574 *:This is Natto. repeat after // me, c'm"
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw $FF03  ; SetEventFlag
    dw $0100  ; Text $0100: "$43:$4DEC [HERO] looked into the jar. // An old la"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script24
; ---------------------------------------------------------------------------
ArenaRooms_Script24:
    dw $FF01  ; BranchIfFlagSet
    dw $0100  ; Text $0100: "$43:$4DEC [HERO] looked into the jar. // An old la"
    dw Bank0D_ScriptAddr_5642          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_562A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00B1
    dw Bank0D_ScriptAddr_563E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_562A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00A5  ; Text $00A5: "$1A:$4E6E *:I always think about what kind of // f"
    dw Bank0D_ScriptAddr_563A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_562A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0091
    dw Bank0D_ScriptAddr_5636          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_562A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $007F
    dw Bank0D_ScriptAddr_5632          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_562A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $005B  ; Text $005B: "$42:$71FE Pulio:Thank you [HERO]! Now I // can go "
    dw Bank0D_ScriptAddr_562E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_562A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw Bank0D_ScriptAddr_5626          ; -> branch target
    dw $010D  ; Text $010D: "$43:$5288 *:....."
    dw $FFFF  ; END

Bank0D_ScriptAddr_5626:
    dw $010E  ; Text $010E: "$43:$5294 *:What the heck is an onigiri? // Why ca"
    dw $FFFF  ; END

Bank0D_ScriptAddr_562A:
    dw $010D  ; Text $010D: "$43:$5288 *:....."
    dw $FFFF  ; END

Bank0D_ScriptAddr_562E:
    dw $0238  ; Text $0238: "$1B:$5724 *:What the heck are hashis? Why // can't"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5632:
    dw $02F2  ; Text $02F2: "$1F:$56AB *:What the heck is miso shiru! Can't // "
    dw $FFFF  ; END

Bank0D_ScriptAddr_5636:
    dw $03AF
    dw $FFFF  ; END

Bank0D_ScriptAddr_563A:
    dw $045B
    dw $FFFF  ; END

Bank0D_ScriptAddr_563E:
    dw $04BD  ; Text $04BD: "$48:$61A0 *:What the heck is Shoyu! // Can't you j"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5642:
    dw $07EB  ; Text $07EB: "$4B:$55A4 *:Natto? What's that? You're // making i"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script25
; ---------------------------------------------------------------------------
ArenaRooms_Script25:
    dw $FF01  ; BranchIfFlagSet
    dw $0111  ; Text $0111: "$43:$547D *:I am Medal Man, the medal // collector"
    dw Bank0D_ScriptAddr_56B4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0110  ; Text $0110: "$43:$5375 *:Oh, welcome Mas...ahem. // I am the Me"
    dw Bank0D_ScriptAddr_56B0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_56AC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_56A8          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_56A4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_56A0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_569C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_5698          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_5694          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0D_ScriptAddr_5690          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0121  ; Text $0121: "$43:$5E8F *:Leeet's Rumble!"
    dw Bank0D_ScriptAddr_568C          ; -> branch target
    dw $010F  ; Text $010F: "$43:$52D7 *:We all gather here seeking // victory."
    dw $FFFF  ; END

Bank0D_ScriptAddr_568C:
    dw $086C  ; Text $086C: "$4E:$43CE *:We gather here at the arena, // seekin"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5690:
    dw $0872  ; Text $0872: "$4E:$4771 *:Hmmm. You survived G class. // Well, I"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5694:
    dw $0873  ; Text $0873: "$4E:$4865 *:Hmm. You survived F class. // Congratu"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5698:
    dw $0880  ; Text $0880: "$4E:$5319 *:You survived E class, You did // bette"
    dw $FFFF  ; END

Bank0D_ScriptAddr_569C:
    dw $0284  ; Text $0284: "$45:$5DA0 *:So you defeated Mick. // *:But remembe"
    dw $FFFF  ; END

Bank0D_ScriptAddr_56A0:
    dw $02F3
    dw $FFFF  ; END

Bank0D_ScriptAddr_56A4:
    dw $03B0
    dw $FFFF  ; END

Bank0D_ScriptAddr_56A8:
    dw $045C  ; Text $045C: "$21:$6D68 *:We all gather here seeking // victory."
    dw $FFFF  ; END

Bank0D_ScriptAddr_56AC:
    dw $07EC  ; Text $07EC: "$4B:$5606 *:Victory... You've conquered // one of "
    dw $FFFF  ; END

Bank0D_ScriptAddr_56B0:
    dw $07ED  ; Text $07ED: "$4B:$569A *:You won! But you know there is // alwa"
    dw $FFFF  ; END

Bank0D_ScriptAddr_56B4:
    dw $07EE  ; Text $07EE: "$4B:$579C *:Y..you defeated the Master // Monster "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script26
; ---------------------------------------------------------------------------
ArenaRooms_Script26:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_56D6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_56D2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_56CE          ; -> branch target
    dw $00EF  ; Text $00EF: "$43:$486E *:In the back, they teach kids // about "
    dw $FFFF  ; END

Bank0D_ScriptAddr_56CE:
    dw $0882  ; Text $0882: "$4E:$53E2 *:When you choose COMMAND, very // wild "
    dw $FFFF  ; END

Bank0D_ScriptAddr_56D2:
    dw $088B  ; Text $088B: "$4E:$5BC4 *:A mnemonic for useful skills // and mo"
    dw $FFFF  ; END

Bank0D_ScriptAddr_56D6:
    dw $017E  ; Text $017E: "$1A:$64BE *:I'm memorizing monsters' skills. // .."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map08 Per-Script Table (map_type=$08, 1 scripts)
; ---------------------------------------------------------------------------
Map08_ScriptPtrTable:
    dw Map08_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map08_Script00
; ---------------------------------------------------------------------------
Map08_Script00:
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_5726          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5792          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_5818          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw Bank0D_ScriptAddr_587A          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw Bank0D_ScriptAddr_58E0          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw Bank0D_ScriptAddr_5920          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw Bank0D_ScriptAddr_596C          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw Bank0D_ScriptAddr_5A40          ; -> branch target
    dw $FFFF  ; END

Bank0D_ScriptAddr_5726:
    dw $FF12  ; WriteRAM
    dw $C8EC  ; RAM $C8EC
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFD0  ; Cmd$D0
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0A  ; NPCMoveX
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFF8  ; Cmd$F8
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0A  ; NPCMoveX
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0F  ; SetScreenScroll
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5792:
    dw $FF15  ; PlaySE
    dw $C88B  ; RAM $C88B
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $57CE
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $06FD  ; Text $06FD: "$4A:$6BB0 [INS 00] & [INS 10] disappeared."
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFD0  ; Cmd$D0
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $00F0  ; Text $00F0: "$43:$48CD *:Where did the MiniDrak go?"
    dw $FF4F  ; Cmd4F
    dw $FFFF  ; END

    db $0D
    db $FF
    db $02
    db $00
    db $18
    db $00
    db $50
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $18
    db $00
    db $60
    db $00
    db $08
    db $FF
    db $07
    db $FF
    db $FD
    db $06
    db $0B
    db $FF
    db $01
    db $00
    db $D0
    db $FF
    db $09
    db $FF
    db $06
    db $00
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
    db $03
    db $00
    db $00
    db $00
    db $40
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $0B
    db $FF
    db $01
    db $00
    db $30
    db $00
    db $12
    db $FF
    db $9A
    db $D9
    db $01
    db $00
    db $0F
    db $FF
    db $5E
    db $00
    db $98
    db $00
    db $48
    db $00
    db $FF
    db $FF
Bank0D_ScriptAddr_5818:
    dw $FF12  ; WriteRAM
    dw $C8EC  ; RAM $C8EC
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFD0  ; Cmd$D0
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF21  ; TriggerBattle2
    dw $005F  ; Text $005F: "$42:$73FE *:These stairs go up to the // monster f"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF07  ; InitDialogMode
    dw $0706  ; Text $0706: "$22:$4259 [INS 10] was born. // Give it a name."
    dw $FF06  ; IncrementCounter
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw $FF4F  ; Cmd4F
    dw $FFFF  ; END

Bank0D_ScriptAddr_587A:
    dw $FF08  ; NOP
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFD0  ; Cmd$D0
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0A  ; NPCMoveX
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFF8  ; Cmd$F8
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0A  ; NPCMoveX
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF0F  ; SetScreenScroll
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FFFF  ; END

Bank0D_ScriptAddr_58E0:
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0050  ; Text $0050: "$42:$6ABA Pulio:Sorry [HERO], It's my fault... // "
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF08  ; NOP
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFD0  ; Cmd$D0
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $00F2  ; Text $00F2: "$43:$4912 *:Hm, its not fun."
    dw $FF43  ; ExecuteReturn
    dw $FFFF  ; END

Bank0D_ScriptAddr_5920:
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw $5CCC
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF1C  ; CompareRAM
    dw $1402
    dw $FF19  ; FadeEffect
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFD0  ; Cmd$D0
    dw $FF07  ; InitDialogMode
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $FF06  ; IncrementCounter
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF19  ; FadeEffect
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0F  ; SetScreenScroll
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw $00F8  ; Text $00F8: "$43:$4ADE *:You're good..."
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FFFF  ; END

Bank0D_ScriptAddr_596C:
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw $5CCC
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw $597A
    dw $FFFF  ; END

    db $09
    db $FF
    db $10
    db $00
    db $0B
    db $FF
    db $04
    db $00
    db $E0
    db $FF
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
    db $08
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
    db $4D
    db $FF
    db $08
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
    db $08
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
    db $4D
    db $FF
    db $08
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
    db $08
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
    db $08
    db $00
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
    db $01
    db $00
    db $00
    db $00
    db $00
    db $00
    db $0B
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $0B
    db $FF
    db $04
    db $00
    db $10
    db $00
    db $07
    db $FF
    db $0E
    db $05
    db $09
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $5E
    db $FF
    db $FF
    db $FF
Bank0D_ScriptAddr_5A40:
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw $5CCC
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw $5A4E
    dw $FFFF  ; END

    db $1C
    db $FF
    db $03
    db $08
    db $19
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $05
    db $00
    db $40
    db $00
    db $09
    db $FF
    db $20
    db $00
    db $21
    db $FF
    db $5F
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $40
    db $00
    db $0D
    db $FF
    db $02
    db $00
    db $00
    db $00
    db $00
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $1C
    db $FF
    db $04
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $48
    db $FF
    db $04
    db $00
    db $07
    db $FF
    db $0F
    db $05
    db $09
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $0B
    db $FF
    db $04
    db $00
    db $F0
    db $FF
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
    db $08
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
    db $1C
    db $FF
    db $02
    db $04
    db $19
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $12
    db $FF
    db $CB
    db $D9
    db $01
    db $00
    db $13
    db $FF
    db $A6
    db $C8
    db $00
    db $00
    db $48
    db $FF
    db $04
    db $00
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
    db $01
    db $00
    db $48
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $49
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $48
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $49
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $06
    db $00
    db $48
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $06
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $06
    db $00
    db $49
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $06
    db $00
    db $48
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $49
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $49
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $04
    db $00
    db $21
    db $FF
    db $52
    db $00
    db $12
    db $FF
    db $CB
    db $D9
    db $02
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $49
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $49
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $49
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $49
    db $FF
    db $04
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $04
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
    db $09
    db $FF
    db $01
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $C1
    db $00
    db $12
    db $FF
    db $9C
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
    db $12
    db $FF
    db $9C
    db $C8
    db $FF
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $C1
    db $00
    db $12
    db $FF
    db $9C
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
    db $12
    db $FF
    db $9C
    db $C8
    db $FF
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $12
    db $FF
    db $9B
    db $C8
    db $C1
    db $00
    db $12
    db $FF
    db $9C
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
    db $12
    db $FF
    db $9C
    db $C8
    db $FF
    db $00
    db $09
    db $FF
    db $01
    db $00
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
    db $9B
    db $C8
    db $C1
    db $00
    db $12
    db $FF
    db $9C
    db $C8
    db $D2
    db $00
    db $12
    db $FF
    db $9A
    db $D9
    db $03
    db $00
    db $41
    db $FF
    db $02
    db $00
    db $3B
    db $FF
    db $5E
    db $00
    db $38
    db $00
    db $48
    db $00
    db $FF
    db $FF
    db $0D
    db $FF
    db $01
    db $00
    db $00
    db $00
    db $00
    db $00
    db $1C
    db $FF
    db $02
    db $14
    db $19
    db $FF
    db $48
    db $FF
    db $02
    db $00
    db $1B
    db $FF
    db $01
    db $00
    db $00
    db $00
    db $0B
    db $FF
    db $01
    db $00
    db $D0
    db $FF
    db $07
    db $FF
    db $B5
    db $05
    db $06
    db $FF
    db $1B
    db $FF
    db $02
    db $00
    db $40
    db $00
    db $1B
    db $FF
    db $01
    db $00
    db $30
    db $00
    db $19
    db $FF
    db $48
    db $FF
    db $00
    db $00
    db $12
    db $FF
    db $33
    db $D9
    db $03
    db $00
    db $0F
    db $FF
    db $01
    db $00
    db $48
    db $00
    db $E8
    db $01
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Map09 Per-Script Table (map_type=$09, 12 scripts)
; ---------------------------------------------------------------------------
Map09_ScriptPtrTable:
    dw Map09_Script00                  ; script 0
    dw Map09_Script01                  ; script 1
    dw Map09_Script02                  ; script 2
    dw Map09_Script03                  ; script 3
    dw Map09_Script04                  ; script 4
    dw Map09_Script05                  ; script 5
    dw Map09_Script06                  ; script 6
    dw Map09_Script07                  ; script 7
    dw Map09_Script08                  ; script 8
    dw Map09_Script09                  ; script 9
    dw Map09_Script10                  ; script 10
    dw Map09_Script11                  ; script 11
; ---------------------------------------------------------------------------
; Map09_Script00
; ---------------------------------------------------------------------------
Map09_Script00:
    dw $FF15  ; PlaySE
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5ECE          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $00F0  ; Text $00F0: "$43:$48CD *:Where did the MiniDrak go?"
    dw Bank0D_ScriptAddr_5D52          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_5DA2          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0D_ScriptAddr_5DE4          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_5FA2          ; -> branch target
    dw $FFFF  ; END

Bank0D_ScriptAddr_5D52:
    dw $FF50  ; Cmd50
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9E6  ; RAM $D9E6
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $5D6A
    dw $06FE  ; Text $06FE: "$4A:$6BC8 *:Wow! It's a rare breed!"
    dw $06FF  ; Text $06FF: "$4A:$6BE5 *:Inside it is a baby [INS 20]! // *:Cos"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $5D8E
    dw $0701  ; Text $0701: "$22:$41B7 *:Then I'll send the egg to the // farm!"
    dw $06F1  ; Text $06F1: "$4A:$6A03 *:Anything else?"
    dw $FF4E  ; MapTransition3
    dw $FF04  ; ScreenEffect
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $06F0  ; Text $06F0: "$4A:$69E8 *:What can I do for you?"
    dw $06F2  ; Text $06F2: "$4A:$6A15 *:Create the ultimate monsters!"
    dw $FF06  ; IncrementCounter
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF16  ; Cmd16
    dw $FFFF  ; END

    db $60
    db $FF
    db $98
    db $5D
    db $05
    db $07
    db $3A
    db $FF
    db $FF
    db $FF
    db $0E
    db $07
    db $12
    db $FF
    db $51
    db $D9
    db $00
    db $00
    db $FF
    db $FF
Bank0D_ScriptAddr_5DA2:
    dw $FF50  ; Cmd50
    dw $FF04  ; ScreenEffect
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $0708  ; Text $0708: "$22:$429C *:Take [INS 00] with you now?"
    dw $FF04  ; ScreenEffect
    dw $000B  ; Text $000B: "$42:$476A Terry looks at the bookshelf. // :Encycl"
    dw $06F0  ; Text $06F0: "$4A:$69E8 *:What can I do for you?"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5DCA
    dw $FF14  ; ClearGameFlags
    dw $5DCC
    dw $0707  ; Text $0707: "$22:$427D *:I'll send [INS 00] to the farm."
    dw $06F1  ; Text $06F1: "$4A:$6A03 *:Anything else?"
    dw $FF4E  ; MapTransition3
    dw $FF04  ; ScreenEffect
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $06F0  ; Text $06F0: "$4A:$69E8 *:What can I do for you?"
    dw $06F2  ; Text $06F2: "$4A:$6A15 *:Create the ultimate monsters!"
    dw $FF06  ; IncrementCounter
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF16  ; Cmd16
    dw $FFFF  ; END

Bank0D_ScriptAddr_5DE4:
    dw $FF0E  ; SetMapTransition
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5DF8
    dw $FF0E  ; SetMapTransition
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $5E44
    dw $FF0E  ; SetMapTransition
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $5E80
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
    db $1B
    db $FF
    db $02
    db $00
    db $10
    db $00
    db $1B
    db $FF
    db $00
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $1A
    db $FF
    db $02
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $1B
    db $FF
    db $02
    db $00
    db $10
    db $00
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
    db $02
    db $00
    db $60
    db $00
    db $1B
    db $FF
    db $00
    db $00
    db $60
    db $00
    db $19
    db $FF
    db $0F
    db $FF
    db $09
    db $00
    db $E8
    db $00
    db $88
    db $00
    db $FF
    db $FF
    db $08
    db $FF
    db $1B
    db $FF
    db $04
    db $00
    db $50
    db $00
    db $1B
    db $FF
    db $00
    db $00
    db $50
    db $00
    db $19
    db $FF
    db $1A
    db $FF
    db $04
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $1A
    db $FF
    db $04
    db $00
    db $B0
    db $FF
    db $1A
    db $FF
    db $00
    db $00
    db $B0
    db $FF
    db $19
    db $FF
    db $12
    db $FF
    db $53
    db $D9
    db $02
    db $00
    db $0F
    db $FF
    db $09
    db $00
    db $98
    db $00
    db $E8
    db $00
    db $FF
    db $FF
    db $08
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $C0
    db $FF
    db $1A
    db $FF
    db $00
    db $00
    db $C0
    db $FF
    db $19
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
    db $01
    db $00
    db $00
    db $00
    db $40
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $0A
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
    db $53
    db $D9
    db $00
    db $00
    db $0F
    db $FF
    db $01
    db $00
    db $48
    db $00
    db $E8
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_5ECE:
    dw $FF12  ; WriteRAM
    dw $D84A  ; RAM $D84A
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $FF12  ; WriteRAM
    dw $D84B  ; RAM $D84B
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D86A  ; RAM $D86A
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $FF12  ; WriteRAM
    dw $D86B  ; RAM $D86B
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D88A  ; RAM $D88A
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $FF12  ; WriteRAM
    dw $D88B  ; RAM $D88B
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D8AA  ; RAM $D8AA
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $FF12  ; WriteRAM
    dw $D8AB  ; RAM $D8AB
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF1B  ; MultiRAMWrite
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF1B  ; MultiRAMWrite
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF1B  ; MultiRAMWrite
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0050  ; Text $0050: "$42:$6ABA Pulio:Sorry [HERO], It's my fault... // "
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0D_ScriptAddr_5FA2:
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw $5FAE
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw $5FB0
    dw $FFFF  ; END

    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $50
    db $00
    db $19
    db $FF
    db $49
    db $FF
    db $00
    db $00
    db $07
    db $FF
    db $10
    db $05
    db $0B
    db $FF
    db $00
    db $00
    db $C0
    db $FF
    db $0A
    db $FF
    db $00
    db $00
    db $E0
    db $FF
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
    db $51
    db $D9
    db $07
    db $00
    db $0F
    db $FF
    db $08
    db $00
    db $58
    db $00
    db $78
    db $00
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Map09_Script01
; ---------------------------------------------------------------------------
Map09_Script01:
    dw $083A  ; Text $083A: "$3F:$638B There are letters engraved // on the Gat"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map09_Script02
; ---------------------------------------------------------------------------
Map09_Script02:
    dw $01C1  ; Text $01C1: "$44:$5E5D [HERO] looked at the bookshelf. // :Ever"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6012          ; -> branch target
    dw $01C2  ; Text $01C2: "$44:$5EEA :Breeding is to wed monsters. // :After "
    dw $FFFF  ; END

Bank0D_ScriptAddr_6012:
    dw $0026  ; Text $0026: "$42:$53F1 [HERO] returned the book to the // books"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map09_Script03
; ---------------------------------------------------------------------------
Map09_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_6074          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_6052          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_603A          ; -> branch target
    dw $01C3  ; Text $01C3: "$44:$6055 [HERO] looked at the bookshelf. // :Sayi"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6036          ; -> branch target
    dw $01C4  ; Text $01C4: "$44:$60FD :Monster Journal by Master Monster // Ta"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6036:
    dw $014F  ; Text $014F: "$43:$6DB5 [HERO] returned the diary to the // book"
    dw $FFFF  ; END

Bank0D_ScriptAddr_603A:
    dw $02F4  ; Text $02F4: "$1F:$57FA [HERO] looked at the bookshelf. // :Sayi"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6036          ; -> branch target
    dw $02F5  ; Text $02F5: "$1F:$588F :Monster Diary by the Master // Monster "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6036          ; -> branch target
    dw $02F6  ; Text $02F6: "$1F:$595A :[HERO] has already conquered D class! /"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6052:
    dw $04C0  ; Text $04C0: "$48:$62F0 [HERO] looked at the bookshelf. // :Sayi"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6036          ; -> branch target
    dw $02F5  ; Text $02F5: "$1F:$588F :Monster Diary by the Master // Monster "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6036          ; -> branch target
    dw $04C1  ; Text $04C1: "$48:$6383 :[HERO] already conquered D class! // :H"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6036          ; -> branch target
    dw $04C2  ; Text $04C2: "$48:$646B :At last [HERO] will participate // in t"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6074:
    dw $07F4  ; Text $07F4: "$4B:$5E00 :[HERO] looks at the bookshelf. // :Sayi"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6036          ; -> branch target
    dw $02F5  ; Text $02F5: "$1F:$588F :Monster Diary by the Master // Monster "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6036          ; -> branch target
    dw $04C1  ; Text $04C1: "$48:$6383 :[HERO] already conquered D class! // :H"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6036          ; -> branch target
    dw $07F5  ; Text $07F5: "$4B:$5E7A :At last, [HERO] will compete in // the "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6036          ; -> branch target
    dw $07F6  ; Text $07F6: "$4B:$5F0C :At last, [HERO] got a victory! // :I re"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map09_Script04
; ---------------------------------------------------------------------------
Map09_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_60BE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_60BA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_60B6          ; -> branch target
    dw $01BF  ; Text $01BF: "$44:$5A5D *:Hey! Lemme tell ya. // when you breed."
    dw $FFFF  ; END

Bank0D_ScriptAddr_60B6:
    dw $03B1
    dw $FFFF  ; END

Bank0D_ScriptAddr_60BA:
    dw $04BE  ; Text $04BE: "$48:$61DE *:Splash Splash! When the Starry // Nigh"
    dw $FFFF  ; END

Bank0D_ScriptAddr_60BE:
    dw $07F2  ; Text $07F2: "$4B:$5CAD *:Splash, splash! Congratulations. // Le"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map09_Script07
; ---------------------------------------------------------------------------
Map09_Script07:
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
; ---------------------------------------------------------------------------
; Map09_Script05
; ---------------------------------------------------------------------------
Map09_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $0103  ; Text $0103: "$43:$4F3C *:Hi Ho Hi Ho. // *:Sigh.. I'm starving."
    dw Bank0D_ScriptAddr_6102          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0111  ; Text $0111: "$43:$547D *:I am Medal Man, the medal // collector"
    dw Bank0D_ScriptAddr_613C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0102  ; Text $0102: "$43:$4EEE *:Hm.. It doesn't listen to me much. // "
    dw Bank0D_ScriptAddr_6102          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0110  ; Text $0110: "$43:$5375 *:Oh, welcome Mas...ahem. // I am the Me"
    dw Bank0D_ScriptAddr_6126          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0101  ; Text $0101: "$43:$4E4F [HERO] looked into the jar. // A piece o"
    dw Bank0D_ScriptAddr_6102          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_6110          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0045  ; Text $0045: "$42:$64B4 King:Oh, this monster is the // former k"
    dw Bank0D_ScriptAddr_6102          ; -> branch target
    dw $01BE  ; Text $01BE: "$44:$589C *:Oh, long time no see! Remember me? // "
    dw $FF03  ; SetEventFlag
    dw $0045  ; Text $0045: "$42:$64B4 King:Oh, this monster is the // former k"
    dw $FF4E  ; MapTransition3
    dw $FF04  ; ScreenEffect
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $06F0  ; Text $06F0: "$4A:$69E8 *:What can I do for you?"
    dw $06F2  ; Text $06F2: "$4A:$6A15 *:Create the ultimate monsters!"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6102:
    dw $06F0  ; Text $06F0: "$4A:$69E8 *:What can I do for you?"
    dw $FF4E  ; MapTransition3
    dw $FF04  ; ScreenEffect
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $06F0  ; Text $06F0: "$4A:$69E8 *:What can I do for you?"
    dw $06F2  ; Text $06F2: "$4A:$6A15 *:Create the ultimate monsters!"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6110:
    dw $07EF  ; Text $07EF: "$4B:$5835 *:I also was brought here by // Watabou "
    dw $FF03  ; SetEventFlag
    dw $0045  ; Text $0045: "$42:$64B4 King:Oh, this monster is the // former k"
    dw $FF03  ; SetEventFlag
    dw $0101  ; Text $0101: "$43:$4E4F [HERO] looked into the jar. // A piece o"
    dw $FF4E  ; MapTransition3
    dw $FF04  ; ScreenEffect
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $06F0  ; Text $06F0: "$4A:$69E8 *:What can I do for you?"
    dw $06F2  ; Text $06F2: "$4A:$6A15 *:Create the ultimate monsters!"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6126:
    dw $07F0  ; Text $07F0: "$4B:$59B7 *:Ha Ha Ha! I made a comeback! // *:You'"
    dw $FF03  ; SetEventFlag
    dw $0045  ; Text $0045: "$42:$64B4 King:Oh, this monster is the // former k"
    dw $FF03  ; SetEventFlag
    dw $0102  ; Text $0102: "$43:$4EEE *:Hm.. It doesn't listen to me much. // "
    dw $FF4E  ; MapTransition3
    dw $FF04  ; ScreenEffect
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $06F0  ; Text $06F0: "$4A:$69E8 *:What can I do for you?"
    dw $06F2  ; Text $06F2: "$4A:$6A15 *:Create the ultimate monsters!"
    dw $FFFF  ; END

Bank0D_ScriptAddr_613C:
    dw $07F1  ; Text $07F1: "$4B:$5B94 *:You...! I have nothing to say. // *:Yo"
    dw $FF03  ; SetEventFlag
    dw $0045  ; Text $0045: "$42:$64B4 King:Oh, this monster is the // former k"
    dw $FF03  ; SetEventFlag
    dw $0103  ; Text $0103: "$43:$4F3C *:Hi Ho Hi Ho. // *:Sigh.. I'm starving."
    dw $FF4E  ; MapTransition3
    dw $FF04  ; ScreenEffect
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $06F0  ; Text $06F0: "$4A:$69E8 *:What can I do for you?"
    dw $06F2  ; Text $06F2: "$4A:$6A15 *:Create the ultimate monsters!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map09_Script06
; ---------------------------------------------------------------------------
Map09_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_6170          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_616C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_6168          ; -> branch target
    dw $01C0  ; Text $01C0: "$44:$5CA5 *:After breeding, the parent // monsters"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6168:
    dw $03B2
    dw $FFFF  ; END

Bank0D_ScriptAddr_616C:
    dw $04BF  ; Text $04BF: "$48:$624D *:I would like to go deep in the // cham"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6170:
    dw $07F3  ; Text $07F3: "$4B:$5D46 *:Congratulations on your victory! // Le"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map09_Script08
; ---------------------------------------------------------------------------
Map09_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_617E          ; -> branch target
    dw $01C5  ; Text $01C5: "$44:$61D0 *:Master Monster Tamer is in the // back"
    dw $FFFF  ; END

Bank0D_ScriptAddr_617E:
    dw $07F7  ; Text $07F7: "$4B:$6088 *:I heard you won with style. // *:The M"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map09_Script09
; ---------------------------------------------------------------------------
Map09_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $0123  ; Text $0123: "$43:$5F06 Watabou:Doing well huh? // Let's go home"
    dw Bank0D_ScriptAddr_61AE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_61A6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_61A2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_619E          ; -> branch target
    dw $01C6  ; Text $01C6: "$44:$6238 *:The level of a newborn monster // is a"
    dw $FFFF  ; END

Bank0D_ScriptAddr_619E:
    dw $03B3
    dw $FFFF  ; END

Bank0D_ScriptAddr_61A2:
    dw $04C3  ; Text $04C3: "$48:$64E0 *:The combination with the same // monst"
    dw $FFFF  ; END

Bank0D_ScriptAddr_61A6:
    dw $07F8  ; Text $07F8: "$4B:$60EE *:Hey, listen! A different // monster wa"
    dw $FF03  ; SetEventFlag
    dw $0123  ; Text $0123: "$43:$5F06 Watabou:Doing well huh? // Let's go home"
    dw $FFFF  ; END

Bank0D_ScriptAddr_61AE:
    dw $0850
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map09_Script10
; ---------------------------------------------------------------------------
Map09_Script10:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_61D0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_61CC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_61C8          ; -> branch target
    dw $01C7  ; Text $01C7: "$44:$62F4 *:The secret of breeding is to // collec"
    dw $FFFF  ; END

Bank0D_ScriptAddr_61C8:
    dw $03B4
    dw $FFFF  ; END

Bank0D_ScriptAddr_61CC:
    dw $04C4  ; Text $04C4: "$48:$65D3 *:Many Stars fall from the sky on // the"
    dw $FFFF  ; END

Bank0D_ScriptAddr_61D0:
    dw $07F9  ; Text $07F9: "$4B:$61BA *:Where did those millions of stars // t"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map09_Script11
; ---------------------------------------------------------------------------
Map09_Script11:
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFB0  ; Cmd$B0
    dw $FF12  ; WriteRAM
    dw $D9E2  ; RAM $D9E2
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0F  ; SetScreenScroll
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $01C8  ; Text $01C8: "$44:$6413 *:Oh! What a cute monster master // you "
    dw $00F8  ; Text $00F8: "$43:$4ADE *:You're good..."
; ---------------------------------------------------------------------------
; Map0A Per-Script Table (map_type=$0A, 1 scripts)
; ---------------------------------------------------------------------------
Map0A_ScriptPtrTable:
    dw Map0A_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map0A_Script00
; ---------------------------------------------------------------------------
Map0A_Script00:
    dw $FF01  ; BranchIfFlagSet
    dw $0021  ; Text $0021: "$42:$4D91 King:Oh [HERO]! Will you comply // with "
    dw Bank0D_ScriptAddr_61F6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $011E  ; Text $011E: "$43:$5CAD *:I'm Mick. Who are you? // *:Whew, thos"
    dw Bank0D_ScriptAddr_61F8          ; -> branch target
Bank0D_ScriptAddr_61F6:
    dw $FFFF  ; END

Bank0D_ScriptAddr_61F8:
    dw $FF12  ; WriteRAM
    dw $D95E  ; RAM $D95E
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF03  ; SetEventFlag
    dw $0043  ; Text $0043: "$42:$6466 Slio:Dn'a wanna know about the // farm? "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0B Per-Script Table (map_type=$0B, 1 scripts)
; ---------------------------------------------------------------------------
Map0B_ScriptPtrTable:
    dw Map0B_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map0B_Script00
; ---------------------------------------------------------------------------
Map0B_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateTileset Per-Script Table (map_type=$0C, 6 scripts)
; ---------------------------------------------------------------------------
GateTileset_ScriptPtrTable:
    dw GateTileset_Script00            ; script 0
    dw GateTileset_Script01            ; script 1
    dw GateTileset_Script02            ; script 2
    dw GateTileset_Script03            ; script 3
    dw GateTileset_Script04            ; script 4
    dw GateTileset_Script05            ; script 5
; ---------------------------------------------------------------------------
; GateTileset_Script00
; ---------------------------------------------------------------------------
GateTileset_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateTileset_Script01
; ---------------------------------------------------------------------------
GateTileset_Script01:
    dw $01C9  ; Text $01C9: "$44:$65A2 [HERO] looked at the bookshelf. // :Gend"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateTileset_Script02
; ---------------------------------------------------------------------------
GateTileset_Script02:
    dw $01CA  ; Text $01CA: "$44:$6655 [HERO] looked at the bookshelf. // :The "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateTileset_Script03
; ---------------------------------------------------------------------------
GateTileset_Script03:
    dw $01CB  ; Text $01CB: "$44:$6762 [HERO] looked at the bookshelf. // :Skil"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; GateTileset_Script04
; ---------------------------------------------------------------------------
GateTileset_Script04:
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
; ---------------------------------------------------------------------------
; GateTileset_Script05
; ---------------------------------------------------------------------------
GateTileset_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $0104  ; Text $0104: "$43:$4FA8 *:Yo man, wanna know who your // match i"
    dw Bank0D_ScriptAddr_624C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_625C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0046  ; Text $0046: "$42:$65B6 Pulio:Your Majesty, please // forgive me"
    dw Bank0D_ScriptAddr_624C          ; -> branch target
    dw $FF3C  ; Cmd3C
    dw $01C8  ; Text $01C8: "$44:$6413 *:Oh! What a cute monster master // you "
    dw $FF03  ; SetEventFlag
    dw $0046  ; Text $0046: "$42:$65B6 Pulio:Your Majesty, please // forgive me"
    dw $FF04  ; ScreenEffect
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0750  ; Text $0750: "$22:$4C44 *:Oh my little [HERO], // welcome!"
    dw $FF3C  ; Cmd3C
    dw $0752  ; Text $0752: "$22:$4C89 *:Oh! You're leaving so soon. // *:Come "
    dw $FFFF  ; END

Bank0D_ScriptAddr_624C:
    dw $FF3C  ; Cmd3C
    dw $0750  ; Text $0750: "$22:$4C44 *:Oh my little [HERO], // welcome!"
    dw $FF04  ; ScreenEffect
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0750  ; Text $0750: "$22:$4C44 *:Oh my little [HERO], // welcome!"
    dw $FF3C  ; Cmd3C
    dw $0752  ; Text $0752: "$22:$4C89 *:Oh! You're leaving so soon. // *:Come "
    dw $FFFF  ; END

Bank0D_ScriptAddr_625C:
    dw $FF3C  ; Cmd3C
    dw $07FA  ; Text $07FA: "$4B:$6207 *:Hi [HERO]! Welcome home! // *:How have"
    dw $FF03  ; SetEventFlag
    dw $0104  ; Text $0104: "$43:$4FA8 *:Yo man, wanna know who your // match i"
    dw $FF04  ; ScreenEffect
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0750  ; Text $0750: "$22:$4C44 *:Oh my little [HERO], // welcome!"
    dw $FF3C  ; Cmd3C
    dw $0752  ; Text $0752: "$22:$4C89 *:Oh! You're leaving so soon. // *:Come "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0D Per-Script Table (map_type=$0D, 10 scripts)
; ---------------------------------------------------------------------------
Map0D_ScriptPtrTable:
    dw Map0D_Script00                  ; script 0
    dw Map0D_Script01                  ; script 1
    dw Map0D_Script02                  ; script 2
    dw Map0D_Script03                  ; script 3
    dw Map0D_Script04                  ; script 4
    dw Map0D_Script05                  ; script 5
    dw Map0D_Script06                  ; script 6
    dw Map0D_Script07                  ; script 7
    dw Map0D_Script08                  ; script 8
    dw Map0D_Script09                  ; script 9
; ---------------------------------------------------------------------------
; Map0D_Script00
; ---------------------------------------------------------------------------
Map0D_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0D_Script01
; ---------------------------------------------------------------------------
Map0D_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $0047  ; Text $0047: "$42:$65E5 King:Pulio, did Hale escape // as well?"
    dw Bank0D_ScriptAddr_62A2          ; -> branch target
    dw $01D1  ; Text $01D1: "$44:$69E8 [SOUND 60][HERO] looked inside the // dr"
    dw $FF2C  ; CheckInvFull
    dw Bank0D_ScriptAddr_629E          ; -> branch target
    dw $0129  ; Text $0129: "$43:$60FA Wow! [HERO] got a TinyMedal!"
    dw $FF2A  ; GiveItem
    dw $001E  ; Text $001E: "$42:$4CEA [HERO] opened a treasure chest!"
    dw $FF03  ; SetEventFlag
    dw $0047  ; Text $0047: "$42:$65E5 King:Pulio, did Hale escape // as well?"
    dw $FFFF  ; END

Bank0D_ScriptAddr_629E:
    dw $01D2  ; Text $01D2: "$44:$6A0F Wow! A TinyMedal! But cannot carry // an"
    dw $FFFF  ; END

Bank0D_ScriptAddr_62A2:
    dw $01D1  ; Text $01D1: "$44:$69E8 [SOUND 60][HERO] looked inside the // dr"
    dw $01D3  ; Text $01D3: "$44:$6A75 The dresser is filled with girl's // dre"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0D_Script02
; ---------------------------------------------------------------------------
Map0D_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_630C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_62EA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_62D2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_62C4          ; -> branch target
    dw $01D4  ; Text $01D4: "$44:$6AA6 [HERO] looked at the bookshelf. // :Jour"
    dw $FFFF  ; END

Bank0D_ScriptAddr_62C4:
    dw $02FB  ; Text $02FB: "$1F:$5BB0 [HERO] looked at the bookshelf. // :Jour"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $633C
    dw $02FC
    dw $FFFF  ; END

Bank0D_ScriptAddr_62D2:
    dw $02FB  ; Text $02FB: "$1F:$5BB0 [HERO] looked at the bookshelf. // :Jour"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $633C
    dw $03B7
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $633C
    dw $03B8
    dw $FFFF  ; END

Bank0D_ScriptAddr_62EA:
    dw $02FB  ; Text $02FB: "$1F:$5BB0 [HERO] looked at the bookshelf. // :Jour"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $633C
    dw $03B7
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $633C
    dw $04CA  ; Text $04CA: "$48:$6857 :Journal of My Baby, Part 3 // :Flatter "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $633C
    dw $04CB  ; Text $04CB: "$48:$691E :Journal of My Baby, Part 4 // :I guess "
    dw $FFFF  ; END

Bank0D_ScriptAddr_630C:
    dw $02FB  ; Text $02FB: "$1F:$5BB0 [HERO] looked at the bookshelf. // :Jour"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $633C
    dw $03B7
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $633C
    dw $04CA  ; Text $04CA: "$48:$6857 :Journal of My Baby, Part 3 // :Flatter "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $633C
    dw $07FE  ; Text $07FE: "$4B:$6352 :Steps of My Baby Part 4 // :I guess I'v"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $633C
    dw $07FF
    dw $FF03  ; SetEventFlag
    dw $0105  ; Text $0105: "$43:$4FE2 *:Its the principal of the // school."
    dw $FFFF  ; END

    db $4F
    db $01
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Map0D_Script03
; ---------------------------------------------------------------------------
Map0D_Script03:
    dw $01D5  ; Text $01D5: "$44:$6B3C [HERO] looked into the jar. // Someone i"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0D_Script04
; ---------------------------------------------------------------------------
Map0D_Script04:
    dw $015D  ; Text $015D: "$43:$7229 [HERO] looked into the jar. // But there"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0D_Script05
; ---------------------------------------------------------------------------
Map0D_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_63A0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_6384          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_6360          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw Bank0D_ScriptAddr_6372          ; -> branch target
Bank0D_ScriptAddr_6360:
    dw $01CC  ; Text $01CC: "$44:$6859 *:You, do you know my daughter? [YES/NO]"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_636E          ; -> branch target
    dw $01CE  ; Text $01CE: "$44:$68F6 *:See, isn't she the prettiest girl // i"
    dw $FFFF  ; END

Bank0D_ScriptAddr_636E:
    dw $01CD  ; Text $01CD: "$44:$687C *:You don't!? Such a pretty, // gentle &"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6372:
    dw $02F7  ; Text $02F7: "$1F:$5A32 *:My daughter is the prettiest in // Gre"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6380
    dw $02F8
    dw $FFFF  ; END

    db $F9
    db $02
    db $FF
    db $FF
Bank0D_ScriptAddr_6384:
    dw $04C5  ; Text $04C5: "$48:$6634 *:Do you know my daughter? [YES/NO]"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $639C
    dw $04C7  ; Text $04C7: "$48:$66D1 *:She's the most graceful girl in // Gre"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6380
    dw $04C8  ; Text $04C8: "$48:$6713 *:You're promising! // Let me tell you s"
    dw $FFFF  ; END

    db $C6
    db $04
    db $FF
    db $FF
Bank0D_ScriptAddr_63A0:
    dw $07FB  ; Text $07FB: "$4B:$626B *:Congratulations on your victory. // I "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $63AE
    dw $07FC  ; Text $07FC: "$4B:$62DD *:Just kidding! You're still a // kid!"
    dw $FFFF  ; END

    db $FC
    db $07
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Map0D_Script06
; ---------------------------------------------------------------------------
Map0D_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_63DA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_63D6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_63D2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_63CE          ; -> branch target
    dw $01CF  ; Text $01CF: "$44:$692F *:What does the person living // next to"
    dw $FFFF  ; END

Bank0D_ScriptAddr_63CE:
    dw $02FA  ; Text $02FA: "$1F:$5B8B *:My grandpa is really stubborn."
    dw $FFFF  ; END

Bank0D_ScriptAddr_63D2:
    dw $03B5
    dw $FFFF  ; END

Bank0D_ScriptAddr_63D6:
    dw $04C9  ; Text $04C9: "$48:$6813 *:My hubby adores our girl.. // *:Read h"
    dw $FFFF  ; END

Bank0D_ScriptAddr_63DA:
    dw $07FD  ; Text $07FD: "$4B:$6308 *:My hubby loves our girl so much.. // *"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0D_Script07
; ---------------------------------------------------------------------------
Map0D_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $0107  ; Text $0107: "$43:$5027 *:Want to hear about my journey // beyon"
    dw Bank0D_ScriptAddr_6428          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0106  ; Text $0106: "$43:$500D *:Well,it'll be OK too."
    dw Bank0D_ScriptAddr_6416          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F3  ; Text $00F3: "$43:$4928 *:Select your choice by stepping // on t"
    dw Bank0D_ScriptAddr_63FE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_63FA          ; -> branch target
    dw $01D0  ; Text $01D0: "$44:$6983 *:I am never going to let anyone // thro"
    dw $FFFF  ; END

Bank0D_ScriptAddr_63FA:
    dw $0800  ; Text $0800: "$3F:$456C *:I won't give this Travelers' // Gate t"
    dw $FFFF  ; END

Bank0D_ScriptAddr_63FE:
    dw $0801  ; Text $0801: "$3F:$45DC *:Oh, I see. I heard about you // from m"
    dw $FF40  ; Cmd40
    dw $0013  ; Text $0013: "$42:$4AAC *:Good luck at the Starry Night // Tourn"
    dw $640E
    dw $0803  ; Text $0803: "$3F:$4720 *:If you show me a GoldSlime, // *:I'll "
    dw $FF03  ; SetEventFlag
    dw $0106  ; Text $0106: "$43:$500D *:Well,it'll be OK too."
    dw $FFFF  ; END

    db $02
    db $08
    db $03
    db $FF
    db $07
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_6416:
    dw $FF40  ; Cmd40
    dw $0013  ; Text $0013: "$42:$4AAC *:Good luck at the Starry Night // Tourn"
    dw $6420
    dw $0805  ; Text $0805: "$3F:$47F6 *:If you show me a GoldSlime, // *:I'll "
    dw $FFFF  ; END

    db $04
    db $08
    db $03
    db $FF
    db $07
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_6428:
    dw $0806  ; Text $0806: "$3F:$4847 *:Please care for my granddaughter! // *"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0D_Script08
; ---------------------------------------------------------------------------
Map0D_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $0107  ; Text $0107: "$43:$5027 *:Want to hear about my journey // beyon"
    dw Bank0D_ScriptAddr_643E          ; -> branch target
    dw $FF10  ; NPCAnimStart
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0078
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFFF  ; END

Bank0D_ScriptAddr_643E:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0D_Script09
; ---------------------------------------------------------------------------
Map0D_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $0107  ; Text $0107: "$43:$5027 *:Want to hear about my journey // beyon"
    dw Bank0D_ScriptAddr_6452          ; -> branch target
    dw $FF10  ; NPCAnimStart
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0088
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6452:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0E Per-Script Table (map_type=$0E, 1 scripts)
; ---------------------------------------------------------------------------
Map0E_ScriptPtrTable:
    dw Map0E_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map0E_Script00
; ---------------------------------------------------------------------------
Map0E_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0F Per-Script Table (map_type=$0F, 3 scripts)
; ---------------------------------------------------------------------------
Map0F_ScriptPtrTable:
    dw Map0F_Script00                  ; script 0
    dw Map0F_Script01                  ; script 1
    dw Map0F_Script02                  ; script 2
; ---------------------------------------------------------------------------
; Map0F_Script00
; ---------------------------------------------------------------------------
Map0F_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0F_Script01
; ---------------------------------------------------------------------------
Map0F_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $0041  ; Text $0041: "$42:$61BD Slio:You can drop off up to 19 // monste"
    dw Bank0D_ScriptAddr_6476          ; -> branch target
    dw $0182  ; Text $0182: "$1A:$6713 *:Greetings. I manage the Vault. // *:Yo"
    dw $FF03  ; SetEventFlag
    dw $0041  ; Text $0041: "$42:$61BD Slio:You can drop off up to 19 // monste"
    dw $FF04  ; ScreenEffect
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $06A0  ; Text $06A0: "$4A:$60C3 *:Vault. May I help you?"
    dw $06A2  ; Text $06A2: "$4A:$60F3 *:Come again anytime."
    dw $FFFF  ; END

Bank0D_ScriptAddr_6476:
    dw $06A0  ; Text $06A0: "$4A:$60C3 *:Vault. May I help you?"
    dw $FF04  ; ScreenEffect
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $06A0  ; Text $06A0: "$4A:$60C3 *:Vault. May I help you?"
    dw $06A2  ; Text $06A2: "$4A:$60F3 *:Come again anytime."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map0F_Script02
; ---------------------------------------------------------------------------
Map0F_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $0124  ; Text $0124: "$43:$5F34 *:For the 2nd match, the victory // agai"
    dw Bank0D_ScriptAddr_64B2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_64AA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0113  ; Text $0113: "$43:$5555 *:Welcome to the Master School! // *:I a"
    dw Bank0D_ScriptAddr_64A6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_649E          ; -> branch target
    dw $0184  ; Text $0184: "$1A:$67F2 *:If you're wiped out, most // of your i"
    dw $FFFF  ; END

Bank0D_ScriptAddr_649E:
    dw $04CC  ; Text $04CC: "$48:$69CC *:I heard a wish will come true // when "
    dw $FF03  ; SetEventFlag
    dw $0113  ; Text $0113: "$43:$5555 *:Welcome to the Master School! // *:I a"
    dw $FFFF  ; END

Bank0D_ScriptAddr_64A6:
    dw $0852
    dw $FFFF  ; END

Bank0D_ScriptAddr_64AA:
    dw $0807  ; Text $0807: "$3F:$48B2 *:Oh [HERO], will you listen to me? // M"
    dw $FF03  ; SetEventFlag
    dw $0124  ; Text $0124: "$43:$5F34 *:For the 2nd match, the victory // agai"
    dw $FFFF  ; END

Bank0D_ScriptAddr_64B2:
    dw $0853
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; CopycatRoom Per-Script Table (map_type=$10, 8 scripts)
; ---------------------------------------------------------------------------
CopycatRoom_ScriptPtrTable:
    dw CopycatRoom_Script00            ; script 0
    dw CopycatRoom_Script01            ; script 1
    dw CopycatRoom_Script02            ; script 2
    dw CopycatRoom_Script03            ; script 3
    dw CopycatRoom_Script04            ; script 4
    dw CopycatRoom_Script05            ; script 5
    dw CopycatRoom_Script06            ; script 6
    dw CopycatRoom_Script07            ; script 7
; ---------------------------------------------------------------------------
; CopycatRoom_Script00
; ---------------------------------------------------------------------------
CopycatRoom_Script00:
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; CopycatRoom_Script01
; ---------------------------------------------------------------------------
CopycatRoom_Script01:
    dw $01F0  ; Text $01F0: "$44:$78A6 [SOUND 60][HERO] looked into the dresser"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; CopycatRoom_Script02
; ---------------------------------------------------------------------------
CopycatRoom_Script02:
    dw $0276  ; Text $0276: "$45:$5750 [HERO] looked at the bookshelf. // :Seek"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; CopycatRoom_Script03
; ---------------------------------------------------------------------------
CopycatRoom_Script03:
    dw $02B8  ; Text $02B8: "$45:$7733 [HERO] looked at the bookshelf. // :Make"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; CopycatRoom_Script04
; ---------------------------------------------------------------------------
CopycatRoom_Script04:
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
; ---------------------------------------------------------------------------
; CopycatRoom_Script05
; ---------------------------------------------------------------------------
CopycatRoom_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $0081
    dw Bank0D_ScriptAddr_6550          ; -> branch target
    dw $02FD
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_64F4          ; -> branch target
    dw $02FE  ; Text $02FE: "$1F:$5D5C *:Good excuse. // *:You are so funny."
    dw $FFFF  ; END

Bank0D_ScriptAddr_64F4:
    dw $02FF  ; Text $02FF: "$1F:$5D87 *:Then did you sneak in to steal // some"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6502
    dw $0300  ; Text $0300: "$46:$4180 *:Hey, little thief, I think // it's pas"
    dw $FFFF  ; END

    db $01
    db $03
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $10
    db $65
    db $FE
    db $02
    db $FF
    db $FF
    db $02
    db $03
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $24
    db $65
    db $03
    db $03
    db $03
    db $FF
    db $81
    db $00
    db $14
    db $FF
    db $52
    db $65
    db $01
    db $03
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $32
    db $65
    db $FE
    db $02
    db $FF
    db $FF
    db $02
    db $03
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $46
    db $65
    db $03
    db $03
    db $03
    db $FF
    db $81
    db $00
    db $14
    db $FF
    db $52
    db $65
    db $04
    db $03
    db $03
    db $FF
    db $81
    db $00
    db $14
    db $FF
    db $52
    db $65
Bank0D_ScriptAddr_6550:
    dw $0305  ; Text $0305: "$46:$42D5 *:You again!? I'm really gonna // get yo"
    dw $FF5A  ; Cmd5A
    dw $0067  ; Text $0067: "$42:$77B7 *:You can enter the locked rooms // only"
    dw $FF07  ; InitDialogMode
    dw $0306  ; Text $0306: "$46:$4308 *:You don't seem to be a bad guy // afte"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0205  ; Text $0205: "$1B:$4486 K-thump! Something // hit [HERO]."
    dw $FF1C  ; CompareRAM
    dw $1503
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0123  ; Text $0123: "$43:$5F06 Watabou:Doing well huh? // Let's go home"
    dw $FF1C  ; CompareRAM
    dw $0403  ; Text $0403: "$21:$42E8 *:I'll send my StoneMan to the // farm t"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF03  ; SetEventFlag
    dw $001B  ; Text $001B: "$42:$4C50 [HERO] opened a treasure chest!"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D941  ; RAM $D941
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF12  ; WriteRAM
    dw $D95A  ; RAM $D95A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; CopycatRoom_Script06
; ---------------------------------------------------------------------------
CopycatRoom_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $0108  ; Text $0108: "$43:$506B *:StubSucks & GoHoppers, // Anteaters & "
    dw Bank0D_ScriptAddr_6628          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $001B  ; Text $001B: "$42:$4C50 [HERO] opened a treasure chest!"
    dw Bank0D_ScriptAddr_6604          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_6620          ; -> branch target
Bank0D_ScriptAddr_6604:
    dw $FF01  ; BranchIfFlagSet
    dw $0082  ; Text $0082: "$1A:$4691 *:I don't like fighting in a // group."
    dw Bank0D_ScriptAddr_661C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001B  ; Text $001B: "$42:$4C50 [HERO] opened a treasure chest!"
    dw Bank0D_ScriptAddr_6614          ; -> branch target
    dw $01D6  ; Text $01D6: "$44:$6BAB *:Get out! I'm not gonna give my // Bett"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6614:
    dw $0307  ; Text $0307: "$46:$4359 *:It can't be! My Betty is... // *:actua"
    dw $FF03  ; SetEventFlag
    dw $0082  ; Text $0082: "$1A:$4691 *:I don't like fighting in a // group."
    dw $FFFF  ; END

Bank0D_ScriptAddr_661C:
    dw $0308  ; Text $0308: "$46:$43A5 *:Betty was actually // a CopyCat! Noooo"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6620:
    dw $0808  ; Text $0808: "$3F:$49D2 *:I was thinking after I realized // Bet"
    dw $FF03  ; SetEventFlag
    dw $0108  ; Text $0108: "$43:$506B *:StubSucks & GoHoppers, // Anteaters & "
    dw $FFFF  ; END

Bank0D_ScriptAddr_6628:
    dw $0809  ; Text $0809: "$3F:$4AE6 *:...there was a real Betty // somewhere"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; CopycatRoom_Script07
; ---------------------------------------------------------------------------
CopycatRoom_Script07:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map11 Per-Script Table (map_type=$11, 1 scripts)
; ---------------------------------------------------------------------------
Map11_ScriptPtrTable:
    dw Map11_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map11_Script00
; ---------------------------------------------------------------------------
Map11_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12 Per-Script Table (map_type=$12, 18 scripts)
; ---------------------------------------------------------------------------
Map12_ScriptPtrTable:
    dw Map12_Script00                  ; script 0
    dw Map12_Script01                  ; script 1
    dw Map12_Script02                  ; script 2
    dw Map12_Script03                  ; script 3
    dw Map12_Script04                  ; script 4
    dw Map12_Script05                  ; script 5
    dw Map12_Script06                  ; script 6
    dw Map12_Script07                  ; script 7
    dw Map12_Script08                  ; script 8
    dw Map12_Script09                  ; script 9
    dw Map12_Script10                  ; script 10
    dw Map12_Script11                  ; script 11
    dw Map12_Script12                  ; script 12
    dw Map12_Script13                  ; script 13
    dw Map12_Script14                  ; script 14
    dw Map12_Script15                  ; script 15
    dw Map12_Script16                  ; script 16
    dw Map12_Script17                  ; script 17
; ---------------------------------------------------------------------------
; Map12_Script00
; ---------------------------------------------------------------------------
Map12_Script00:
    dw $FF00  ; BranchIfFlagClear
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_666E          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0042  ; Text $0042: "$42:$6437 Slio:Raise the monster to be // powerful"
    dw Bank0D_ScriptAddr_666E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0092
    dw Bank0D_ScriptAddr_6670          ; -> branch target
Bank0D_ScriptAddr_666E:
    dw $FFFF  ; END

Bank0D_ScriptAddr_6670:
    dw $FF03  ; SetEventFlag
    dw $0093
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script01
; ---------------------------------------------------------------------------
Map12_Script01:
    dw $0188  ; Text $0188: "$1A:$6964 [HERO] looked at the bookshelf. // :Fami"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script02
; ---------------------------------------------------------------------------
Map12_Script02:
    dw $0189  ; Text $0189: "$1A:$69F0 [HERO] looked at the bookshelf. // The 9"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script03
; ---------------------------------------------------------------------------
Map12_Script03:
    dw $018A  ; Text $018A: "$1A:$6AA5 [HERO] looked at the bookshelf. // :Seon"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script04
; ---------------------------------------------------------------------------
Map12_Script04:
    dw $018B  ; Text $018B: "$1A:$6B1E [HERO] looked at the bookshelf. // :Seon"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script05
; ---------------------------------------------------------------------------
Map12_Script05:
    dw $018C  ; Text $018C: "$1A:$6B90 [HERO] looked at the bookshelf. // :Seon"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script06
; ---------------------------------------------------------------------------
Map12_Script06:
    dw $018D  ; Text $018D: "$1A:$6C0C [HERO] looked at the bookshelf. // :Seon"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script07
; ---------------------------------------------------------------------------
Map12_Script07:
    dw $018E
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script08
; ---------------------------------------------------------------------------
Map12_Script08:
    dw $018F
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script09
; ---------------------------------------------------------------------------
Map12_Script09:
    dw $0190
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script10
; ---------------------------------------------------------------------------
Map12_Script10:
    dw $0191
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script11
; ---------------------------------------------------------------------------
Map12_Script11:
    dw $0192
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script12
; ---------------------------------------------------------------------------
Map12_Script12:
    dw $0193  ; Text $0193: "$1A:$6EEA [HERO] read a poster. // :Knowledge is t"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script13
; ---------------------------------------------------------------------------
Map12_Script13:
    dw $FF01  ; BranchIfFlagSet
    dw $0109  ; Text $0109: "$43:$51A8 *:My journey to the Travelers' // Gate i"
    dw Bank0D_ScriptAddr_66EA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_66E2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_66DE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_66DA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_66D6          ; -> branch target
    dw $0185  ; Text $0185: "$1A:$68D2 *:Did you know? [YES/NO]"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_66D2          ; -> branch target
    dw $0186  ; Text $0186: "$1A:$68E6 *:Oh, well."
    dw $FFFF  ; END

Bank0D_ScriptAddr_66D2:
    dw $0187  ; Text $0187: "$1A:$68F6 *:I heard there is a wedding place // fo"
    dw $FFFF  ; END

Bank0D_ScriptAddr_66D6:
    dw $0239  ; Text $0239: "$1B:$576C *:I wonder how the Master Monster // Tam"
    dw $FFFF  ; END

Bank0D_ScriptAddr_66DA:
    dw $0309  ; Text $0309: "$46:$43D9 *:The quake of GreatTree must // have so"
    dw $FFFF  ; END

Bank0D_ScriptAddr_66DE:
    dw $04CD  ; Text $04CD: "$48:$6ACB *:I'm looking for a book. // *:I can't f"
    dw $FFFF  ; END

Bank0D_ScriptAddr_66E2:
    dw $080A  ; Text $080A: "$3F:$4B51 *:I've been looking for a // book, & I f"
    dw $FF03  ; SetEventFlag
    dw $0109  ; Text $0109: "$43:$51A8 *:My journey to the Travelers' // Gate i"
    dw $FFFF  ; END

Bank0D_ScriptAddr_66EA:
    dw $080B  ; Text $080B: "$3F:$4C6E *:It says when the best monster // maste"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script14
; ---------------------------------------------------------------------------
Map12_Script14:
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
; ---------------------------------------------------------------------------
; Map12_Script15
; ---------------------------------------------------------------------------
Map12_Script15:
    dw $FF01  ; BranchIfFlagSet
    dw $010A  ; Text $010A: "$43:$51EE *:Want to know about the monsters // beh"
    dw Bank0D_ScriptAddr_6718          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_6728          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0042  ; Text $0042: "$42:$6437 Slio:Raise the monster to be // powerful"
    dw Bank0D_ScriptAddr_6718          ; -> branch target
    dw $0194
    dw $FF03  ; SetEventFlag
    dw $0042  ; Text $0042: "$42:$6437 Slio:Raise the monster to be // powerful"
    dw $FF04  ; ScreenEffect
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $0740  ; Text $0740: "$22:$4B7A *:You're at the library. Which // family"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $0742  ; Text $0742: "$22:$4BD7 *:You're always welcome."
    dw $FFFF  ; END

Bank0D_ScriptAddr_6718:
    dw $0740  ; Text $0740: "$22:$4B7A *:You're at the library. Which // family"
    dw $FF04  ; ScreenEffect
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $0740  ; Text $0740: "$22:$4B7A *:You're at the library. Which // family"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $0742  ; Text $0742: "$22:$4BD7 *:You're always welcome."
    dw $FFFF  ; END

Bank0D_ScriptAddr_6728:
    dw $080C  ; Text $080C: "$3F:$4D1B *:Even after the Starry Night, // monste"
    dw $FF03  ; SetEventFlag
    dw $010A  ; Text $010A: "$43:$51EE *:Want to know about the monsters // beh"
    dw $FF04  ; ScreenEffect
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $0740  ; Text $0740: "$22:$4B7A *:You're at the library. Which // family"
    dw $FF08  ; NOP
    dw $FF07  ; InitDialogMode
    dw $0742  ; Text $0742: "$22:$4BD7 *:You're always welcome."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script16
; ---------------------------------------------------------------------------
Map12_Script16:
    dw $FF01  ; BranchIfFlagSet
    dw $011F  ; Text $011F: "$43:$5D7D *:You are at the Room of Beginning. // *"
    dw Bank0D_ScriptAddr_6748          ; -> branch target
    dw $0869  ; Text $0869: "$4E:$41C3 *:Hi. Welcome to the library. // *:You'r"
    dw $FF03  ; SetEventFlag
    dw $011F  ; Text $011F: "$43:$5D7D *:You are at the Room of Beginning. // *"
Bank0D_ScriptAddr_6748:
    dw $FF51  ; Cmd51
    dw $0790  ; Text $0790: "$22:$534F *:How many monsters have you // had as y"
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_67AC          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_67B0          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_67B4          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw Bank0D_ScriptAddr_67B8          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw Bank0D_ScriptAddr_67BC          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw Bank0D_ScriptAddr_67C0          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw Bank0D_ScriptAddr_67C4          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw Bank0D_ScriptAddr_67C8          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw Bank0D_ScriptAddr_67CC          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw Bank0D_ScriptAddr_67D0          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $000A  ; Text $000A: "$42:$45C1 *:You speak monster talk // don't you? /"
    dw Bank0D_ScriptAddr_67D4          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D8E1  ; RAM $D8E1
    dw $000B  ; Text $000B: "$42:$476A Terry looks at the bookshelf. // :Encycl"
    dw Bank0D_ScriptAddr_67D8          ; -> branch target
Bank0D_ScriptAddr_67AC:
    dw $0791  ; Text $0791: "$22:$53B5 *:You just started didn't you? // *:Good"
    dw $FFFF  ; END

Bank0D_ScriptAddr_67B0:
    dw $0792  ; Text $0792: "$22:$53F8 *:You're still a beginner. // Are you us"
    dw $FFFF  ; END

Bank0D_ScriptAddr_67B4:
    dw $0793  ; Text $0793: "$22:$5434 *:Have you tried breeding your // monste"
    dw $FFFF  ; END

Bank0D_ScriptAddr_67B8:
    dw $0794  ; Text $0794: "$22:$554B *:Finally, you look more like // a monst"
    dw $FFFF  ; END

Bank0D_ScriptAddr_67BC:
    dw $0795  ; Text $0795: "$22:$55C1 *:For the time being, you should // aim "
    dw $FFFF  ; END

Bank0D_ScriptAddr_67C0:
    dw $0796  ; Text $0796: "$22:$565B *:At last you exceeded 50 kinds. // *:Bu"
    dw $FFFF  ; END

Bank0D_ScriptAddr_67C4:
    dw $0797  ; Text $0797: "$22:$56F8 *:You have lots of monsters! You're a //"
    dw $FFFF  ; END

Bank0D_ScriptAddr_67C8:
    dw $0798  ; Text $0798: "$22:$5732 *:Great! Over 100 species! // *:Nobody c"
    dw $FFFF  ; END

Bank0D_ScriptAddr_67CC:
    dw $0799  ; Text $0799: "$22:$577F *:You're amazing! // *:You reached the h"
    dw $FFFF  ; END

Bank0D_ScriptAddr_67D0:
    dw $079A  ; Text $079A: "$22:$57E3 *:At last you're challenging a // record"
    dw $FFFF  ; END

Bank0D_ScriptAddr_67D4:
    dw $079B  ; Text $079B: "$22:$589D *:Unbelievable number of // monsters! Ho"
    dw $FFFF  ; END

Bank0D_ScriptAddr_67D8:
    dw $079C  ; Text $079C: "$22:$58FB *:Ta-da! Congratulations! // *:At last, "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map12_Script17
; ---------------------------------------------------------------------------
Map12_Script17:
    dw $FF31  ; Cmd31
    dw Bank0D_ScriptAddr_67E8          ; -> branch target
    dw $0195  ; Text $0195: "$1A:$701A *:In the back, important books // are ke"
    dw $FF03  ; SetEventFlag
    dw $0092
    dw $FFFF  ; END

Bank0D_ScriptAddr_67E8:
    dw $03B9
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0B  ; NPCMoveY
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFE0  ; Cmd$E0
    dw $FF21  ; TriggerBattle2
    dw $0051  ; Text $0051: "$42:$6B5B *:These stairs bring you to the // Chamb"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF12  ; WriteRAM
    dw $D95C  ; RAM $D95C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF03  ; SetEventFlag
    dw $0120  ; Text $0120: "$43:$5DE8 *:Ladies & Gents! Welcome to the // Aren"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13 Per-Script Table (map_type=$13, 16 scripts)
; ---------------------------------------------------------------------------
Map13_ScriptPtrTable:
    dw Map13_Script00                  ; script 0
    dw Map13_Script01                  ; script 1
    dw Map13_Script02                  ; script 2
    dw Map13_Script03                  ; script 3
    dw Map13_Script04                  ; script 4
    dw Map13_Script05                  ; script 5
    dw Map13_Script06                  ; script 6
    dw Map13_Script07                  ; script 7
    dw Map13_Script08                  ; script 8
    dw Map13_Script09                  ; script 9
    dw Map13_Script10                  ; script 10
    dw Map13_Script11                  ; script 11
    dw Map13_Script12                  ; script 12
    dw Map13_Script13                  ; script 13
    dw Map13_Script14                  ; script 14
    dw Map13_Script15                  ; script 15
; ---------------------------------------------------------------------------
; Map13_Script00
; ---------------------------------------------------------------------------
Map13_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script01
; ---------------------------------------------------------------------------
Map13_Script01:
    dw $03BB
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script02
; ---------------------------------------------------------------------------
Map13_Script02:
    dw $03BC  ; Text $03BC: "$1B:$6D41 [HERO] looked at the bookshelf. // :Ever"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script03
; ---------------------------------------------------------------------------
Map13_Script03:
    dw $03BD  ; Text $03BD: "$1B:$6DF4 [HERO] looked at the bookshelf. // :Ever"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script04
; ---------------------------------------------------------------------------
Map13_Script04:
    dw $03BE  ; Text $03BE: "$1B:$6EA6 [HERO] looked at the bookshelf. // :Ever"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script05
; ---------------------------------------------------------------------------
Map13_Script05:
    dw $03BF  ; Text $03BF: "$1B:$6F55 [HERO] looked at the bookshelf. // :Ever"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script06
; ---------------------------------------------------------------------------
Map13_Script06:
    dw $03C0  ; Text $03C0: "$1B:$7005 [HERO] looked at the bookshelf. // :Ever"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script07
; ---------------------------------------------------------------------------
Map13_Script07:
    dw $03C1
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script08
; ---------------------------------------------------------------------------
Map13_Script08:
    dw $03C2  ; Text $03C2: "$1B:$715D [HERO] looked at the bookshelf. // :Ever"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script09
; ---------------------------------------------------------------------------
Map13_Script09:
    dw $03C3  ; Text $03C3: "$1B:$720E [HERO] looked at the bookshelf. // :Ever"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script10
; ---------------------------------------------------------------------------
Map13_Script10:
    dw $03C4  ; Text $03C4: "$1B:$72BC [HERO] looked at the bookshelf. // :Ever"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script11
; ---------------------------------------------------------------------------
Map13_Script11:
    dw $03C5  ; Text $03C5: "$1B:$736C [HERO] looked at the bookshelf. // :Ever"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script12
; ---------------------------------------------------------------------------
Map13_Script12:
    dw $03C6  ; Text $03C6: "$1B:$741B [HERO] looked at the bookshelf. // :Ever"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script13
; ---------------------------------------------------------------------------
Map13_Script13:
    dw $03C7  ; Text $03C7: "$1B:$74CC [HERO] looked at the bookshelf. // :Ever"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script14
; ---------------------------------------------------------------------------
Map13_Script14:
    dw $03C8  ; Text $03C8: "$47:$40C1 :[HERO] looked at the bookshelf. // :Eve"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map13_Script15
; ---------------------------------------------------------------------------
Map13_Script15:
    dw $FF01  ; BranchIfFlagSet
    dw $02C1
    dw Bank0D_ScriptAddr_6894          ; -> branch target
    dw $03BA
    dw $FFFF  ; END

Bank0D_ScriptAddr_6894:
    dw $080D  ; Text $080D: "$3F:$4DE4 *:Congratulations on your victory! // It"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map14 Per-Script Table (map_type=$14, 1 scripts)
; ---------------------------------------------------------------------------
Map14_ScriptPtrTable:
    dw Map14_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map14_Script00
; ---------------------------------------------------------------------------
Map14_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map15 Per-Script Table (map_type=$15, 1 scripts)
; ---------------------------------------------------------------------------
Map15_ScriptPtrTable:
    dw Map15_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map15_Script00
; ---------------------------------------------------------------------------
Map15_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; MedalMan Per-Script Table (map_type=$16, 4 scripts)
; ---------------------------------------------------------------------------
MedalMan_ScriptPtrTable:
    dw MedalMan_Script00               ; script 0
    dw MedalMan_Script01               ; script 1
    dw MedalMan_Script02               ; script 2
    dw MedalMan_Script03               ; script 3
; ---------------------------------------------------------------------------
; MedalMan_Script00
; ---------------------------------------------------------------------------
MedalMan_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; MedalMan_Script01
; ---------------------------------------------------------------------------
MedalMan_Script01:
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
; ---------------------------------------------------------------------------
; MedalMan_Script02
; ---------------------------------------------------------------------------
MedalMan_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw Bank0D_ScriptAddr_68D2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0038  ; Text $0038: "$42:$5E08 *:I heard that Pulio let the // monsters"
    dw Bank0D_ScriptAddr_68C8          ; -> branch target
    dw $0110  ; Text $0110: "$43:$5375 *:Oh, welcome Mas...ahem. // I am the Me"
    dw $FF03  ; SetEventFlag
    dw $0038  ; Text $0038: "$42:$5E08 *:I heard that Pulio let the // monsters"
    dw $FF04  ; ScreenEffect
    dw $000A  ; Text $000A: "$42:$45C1 *:You speak monster talk // don't you? /"
    dw $0720  ; Text $0720: "$22:$44E7 *:I'm collecting medals that are // scat"
    dw $FFFF  ; END

Bank0D_ScriptAddr_68C8:
    dw $0720  ; Text $0720: "$22:$44E7 *:I'm collecting medals that are // scat"
    dw $FF04  ; ScreenEffect
    dw $000A  ; Text $000A: "$42:$45C1 *:You speak monster talk // don't you? /"
    dw $0720  ; Text $0720: "$22:$44E7 *:I'm collecting medals that are // scat"
    dw $FFFF  ; END

Bank0D_ScriptAddr_68D2:
    dw $072E  ; Text $072E: "$22:$49DD *:Thank you [HERO]! You're so kind!"
    dw $FF04  ; ScreenEffect
    dw $000A  ; Text $000A: "$42:$45C1 *:You speak monster talk // don't you? /"
    dw $0720  ; Text $0720: "$22:$44E7 *:I'm collecting medals that are // scat"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; MedalMan_Script03
; ---------------------------------------------------------------------------
MedalMan_Script03:
    dw $FF00  ; BranchIfFlagClear
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw Bank0D_ScriptAddr_68FA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $005C  ; Text $005C: "$42:$7236 King:[HERO]. Go to the arena. // King:Yo"
    dw Bank0D_ScriptAddr_695C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0043  ; Text $0043: "$42:$6466 Slio:Dn'a wanna know about the // farm? "
    dw Bank0D_ScriptAddr_6954          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $011E  ; Text $011E: "$43:$5CAD *:I'm Mick. Who are you? // *:Whew, thos"
    dw Bank0D_ScriptAddr_6950          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0050  ; Text $0050: "$42:$6ABA Pulio:Sorry [HERO], It's my fault... // "
    dw Bank0D_ScriptAddr_6948          ; -> branch target
Bank0D_ScriptAddr_68FA:
    dw $FF00  ; BranchIfFlagClear
    dw $005C  ; Text $005C: "$42:$7236 King:[HERO]. Go to the arena. // King:Yo"
    dw Bank0D_ScriptAddr_6912          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_6944          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_6940          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_693C          ; -> branch target
Bank0D_ScriptAddr_6912:
    dw $FF01  ; BranchIfFlagSet
    dw $0043  ; Text $0043: "$42:$6466 Slio:Dn'a wanna know about the // farm? "
    dw Bank0D_ScriptAddr_6934          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $011E  ; Text $011E: "$43:$5CAD *:I'm Mick. Who are you? // *:Whew, thos"
    dw Bank0D_ScriptAddr_6930          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0050  ; Text $0050: "$42:$6ABA Pulio:Sorry [HERO], It's my fault... // "
    dw Bank0D_ScriptAddr_6928          ; -> branch target
    dw $0112  ; Text $0112: "$43:$54AC *:Both the Medal Man & myself // love me"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6928:
    dw $0144  ; Text $0144: "$43:$6765 *:Thanks [HERO]! For bringing the // med"
    dw $FF03  ; SetEventFlag
    dw $011E  ; Text $011E: "$43:$5CAD *:I'm Mick. Who are you? // *:Whew, thos"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6930:
    dw $0868  ; Text $0868: "$4E:$4143 *:To show my appreciation, I'll // open "
    dw $FFFF  ; END

Bank0D_ScriptAddr_6934:
    dw $0145  ; Text $0145: "$43:$681D *:I found it! A big trial's // waiting f"
    dw $FF03  ; SetEventFlag
    dw $005C  ; Text $005C: "$42:$7236 King:[HERO]. Go to the arena. // King:Yo"
    dw $FFFF  ; END

Bank0D_ScriptAddr_693C:
    dw $023A  ; Text $023A: "$1B:$57D1 *:The man is always pacing // around. //"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6940:
    dw $03C9  ; Text $03C9: "$47:$4175 *:He looks a bit nervous. // I wonder wh"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6944:
    dw $0339  ; Text $0339: "$46:$5738 *:That man always looks the same // but."
    dw $FFFF  ; END

Bank0D_ScriptAddr_6948:
    dw $0144  ; Text $0144: "$43:$6765 *:Thanks [HERO]! For bringing the // med"
    dw $FF03  ; SetEventFlag
    dw $011E  ; Text $011E: "$43:$5CAD *:I'm Mick. Who are you? // *:Whew, thos"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6950:
    dw $0868  ; Text $0868: "$4E:$4143 *:To show my appreciation, I'll // open "
    dw $FFFF  ; END

Bank0D_ScriptAddr_6954:
    dw $0145  ; Text $0145: "$43:$681D *:I found it! A big trial's // waiting f"
    dw $FF03  ; SetEventFlag
    dw $005C  ; Text $005C: "$42:$7236 King:[HERO]. Go to the arena. // King:Yo"
    dw $FFFF  ; END

Bank0D_ScriptAddr_695C:
    dw $080E  ; Text $080E: "$3F:$4E1E *:The Medal Man said you can pass!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map17 Per-Script Table (map_type=$17, 1 scripts)
; ---------------------------------------------------------------------------
Map17_ScriptPtrTable:
    dw Map17_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map17_Script00
; ---------------------------------------------------------------------------
Map17_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Well Per-Script Table (map_type=$18, 9 scripts)
; ---------------------------------------------------------------------------
Well_ScriptPtrTable:
    dw Well_Script00                   ; script 0
    dw Well_Script01                   ; script 1
    dw Well_Script02                   ; script 2
    dw Well_Script03                   ; script 3
    dw Well_Script04                   ; script 4
    dw Well_Script05                   ; script 5
    dw Well_Script06                   ; script 6
    dw Well_Script07                   ; script 7
    dw Well_Script08                   ; script 8
; ---------------------------------------------------------------------------
; Well_Script00
; ---------------------------------------------------------------------------
Well_Script00:
    dw $FF0E  ; SetMapTransition
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6984          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw Bank0D_ScriptAddr_69AE          ; -> branch target
    dw $FFFF  ; END

Bank0D_ScriptAddr_6984:
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF01  ; BranchIfFlagSet
    dw $006A  ; Text $006A: "$42:$7A53 Splat... Poop hit [HERO]."
    dw $69A6
    dw $FF00  ; BranchIfFlagClear
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw $69AC
    dw $FF00  ; BranchIfFlagClear
    dw $005E  ; Text $005E: "$42:$736B *:To get to the arena, go straight // ou"
    dw $69AC
    dw $FF03  ; SetEventFlag
    dw $006A  ; Text $006A: "$42:$7A53 Splat... Poop hit [HERO]."
    dw $FF12  ; WriteRAM
    dw $D960  ; RAM $D960
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFFF  ; END

    db $03
    db $FF
    db $6B
    db $00
    db $FF
    db $FF
    db $FF
    db $FF
Bank0D_ScriptAddr_69AE:
    dw $FF01  ; BranchIfFlagSet
    dw $006A  ; Text $006A: "$42:$7A53 Splat... Poop hit [HERO]."
    dw $69BA
    dw $FF01  ; BranchIfFlagSet
    dw $005E  ; Text $005E: "$42:$736B *:To get to the arena, go straight // ou"
    dw $69BC
    dw $FFFF  ; END

    db $03
    db $FF
    db $6A
    db $00
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Well_Script01
; ---------------------------------------------------------------------------
Well_Script01:
    dw $0199  ; Text $0199: "$44:$41AE [HERO] looked at the bookshelf. // :My r"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Well_Script02
; ---------------------------------------------------------------------------
Well_Script02:
    dw $019A  ; Text $019A: "$44:$4328 [HERO] looked at the bookshelf. // :The "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Well_Script03
; ---------------------------------------------------------------------------
Well_Script03:
    dw $019B  ; Text $019B: "$44:$44C6 [HERO] looked at the bookshelf. // :The "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Well_Script04
; ---------------------------------------------------------------------------
Well_Script04:
    dw $019D  ; Text $019D: "$44:$45EE [HERO] looked into the big kettle. // .."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Well_Script05
; ---------------------------------------------------------------------------
Well_Script05:
    dw $019C  ; Text $019C: "$44:$45A4 [HERO] looked into the jar. // It was a "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Well_Script06
; ---------------------------------------------------------------------------
Well_Script06:
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
; ---------------------------------------------------------------------------
; Well_Script07
; ---------------------------------------------------------------------------
Well_Script07:
    dw $FF00  ; BranchIfFlagClear
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw Bank0D_ScriptAddr_69E6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_6AD4          ; -> branch target
Bank0D_ScriptAddr_69E6:
    dw $FF01  ; BranchIfFlagSet
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw Bank0D_ScriptAddr_6AD0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $006A  ; Text $006A: "$42:$7A53 Splat... Poop hit [HERO]."
    dw Bank0D_ScriptAddr_6AC8          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $005E  ; Text $005E: "$42:$736B *:To get to the arena, go straight // ou"
    dw Bank0D_ScriptAddr_6AC4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $005D  ; Text $005D: "$42:$7314 Slio:[HERO]! Congratulations // on your "
    dw Bank0D_ScriptAddr_6A1A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_6A12          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_6A0E          ; -> branch target
    dw $0197
    dw $FFFF  ; END

Bank0D_ScriptAddr_6A0E:
    dw $01D7  ; Text $01D7: "$44:$6BF9 *:Oh,it was you. Appearances can be // m"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6A12:
    dw $023B  ; Text $023B: "$1B:$583C *:I recognize you are a superior // mast"
    dw $FF03  ; SetEventFlag
    dw $005D  ; Text $005D: "$42:$7314 Slio:[HERO]! Congratulations // on your "
    dw $FFFF  ; END

Bank0D_ScriptAddr_6A1A:
    dw $0243  ; Text $0243: "$1B:$5AF9 *:Did you bring a monster with // a thun"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $6A28
    dw $023C  ; Text $023C: "$1B:$593F *:I see. If you find a monster // with a"
    dw $FFFF  ; END

    db $15
    db $FF
    db $8D
    db $CA
    db $01
    db $00
    db $46
    db $6A
    db $34
    db $FF
    db $00
    db $00
    db $4A
    db $6A
    db $34
    db $FF
    db $01
    db $00
    db $88
    db $6A
    db $34
    db $FF
    db $02
    db $00
    db $9E
    db $6A
    db $3D
    db $02
    db $FF
    db $FF
    db $5D
    db $08
    db $FF
    db $FF
    db $3E
    db $02
    db $3F
    db $02
    db $15
    db $FF
    db $3C
    db $C8
    db $00
    db $00
    db $AE
    db $6A
    db $34
    db $FF
    db $01
    db $00
    db $66
    db $6A
    db $34
    db $FF
    db $02
    db $00
    db $7A
    db $6A
    db $41
    db $02
    db $FF
    db $FF
    db $42
    db $02
    db $15
    db $FF
    db $3C
    db $C8
    db $00
    db $00
    db $AE
    db $6A
    db $34
    db $FF
    db $02
    db $00
    db $7A
    db $6A
    db $41
    db $02
    db $FF
    db $FF
    db $42
    db $02
    db $15
    db $FF
    db $3C
    db $C8
    db $00
    db $00
    db $AE
    db $6A
    db $41
    db $02
    db $FF
    db $FF
    db $3E
    db $02
    db $3F
    db $02
    db $15
    db $FF
    db $3C
    db $C8
    db $00
    db $00
    db $AE
    db $6A
    db $34
    db $FF
    db $02
    db $00
    db $7A
    db $6A
    db $41
    db $02
    db $FF
    db $FF
    db $3E
    db $02
    db $3F
    db $02
    db $15
    db $FF
    db $3C
    db $C8
    db $00
    db $00
    db $AE
    db $6A
    db $41
    db $02
    db $FF
    db $FF
    db $06
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $25
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $07
    db $FF
    db $40
    db $02
    db $03
    db $FF
    db $5E
    db $00
    db $FF
    db $FF
Bank0D_ScriptAddr_6AC4:
    dw $0240  ; Text $0240: "$1B:$5A37 *:Now I can carry out my experiment! // "
    dw $FFFF  ; END

Bank0D_ScriptAddr_6AC8:
    dw $0285  ; Text $0285: "$45:$5E77 *:[HERO], as you see, the // experiment "
    dw $FF03  ; SetEventFlag
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6AD0:
    dw $0286  ; Text $0286: "$45:$5F60 *:I failed. Sorry, but you // have to gi"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6AD4:
    dw $080F  ; Text $080F: "$3F:$4E44 *:I heard you won the tournament. // *:D"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Well_Script08
; ---------------------------------------------------------------------------
Well_Script08:
    dw $FF00  ; BranchIfFlagClear
    dw $0125  ; Text $0125: "$43:$5F9D *:I'm the principal of the // Master Sch"
    dw Bank0D_ScriptAddr_6AE4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_6B0A          ; -> branch target
Bank0D_ScriptAddr_6AE4:
    dw $FF01  ; BranchIfFlagSet
    dw $006A  ; Text $006A: "$42:$7A53 Splat... Poop hit [HERO]."
    dw Bank0D_ScriptAddr_6B02          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $005D  ; Text $005D: "$42:$7314 Slio:[HERO]! Congratulations // on your "
    dw Bank0D_ScriptAddr_6AFE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_6AFA          ; -> branch target
    dw $0198  ; Text $0198: "$44:$4157 *:Good evening. Or is it day? // *:I'm a"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6AFA:
    dw $01D8  ; Text $01D8: "$44:$6CF0 *:My professor is a genius and // handso"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6AFE:
    dw $0244  ; Text $0244: "$45:$4158 *:Even though its for research... // It'"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6B02:
    dw $0287  ; Text $0287: "$45:$5FE0 *:He paid for it! He shouldn't have // o"
    dw $FF03  ; SetEventFlag
    dw $0125  ; Text $0125: "$43:$5F9D *:I'm the principal of the // Master Sch"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6B0A:
    dw $0810  ; Text $0810: "$3F:$4EA2 *:Well, well. You won but its none // of"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map19 Per-Script Table (map_type=$19, 5 scripts)
; ---------------------------------------------------------------------------
Map19_ScriptPtrTable:
    dw Map19_Script00                  ; script 0
    dw Map19_Script01                  ; script 1
    dw Map19_Script02                  ; script 2
    dw Map19_Script03                  ; script 3
    dw Map19_Script04                  ; script 4
; ---------------------------------------------------------------------------
; Map19_Script00
; ---------------------------------------------------------------------------
Map19_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map19_Script01
; ---------------------------------------------------------------------------
Map19_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $0083
    dw Bank0D_ScriptAddr_6B48          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $000E  ; Text $000E: "$42:$483B Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_6B2A          ; -> branch target
    dw $030A  ; Text $030A: "$46:$442A *:What? You can't even beat my // brothe"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6B2A:
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6B3E
    dw $030B  ; Text $030B: "$46:$44A4 *:Ready! Rock-Paper- // Scissors... Go!"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFFF  ; END

    db $F2
    db $00
    db $12
    db $FF
    db $DF
    db $D9
    db $00
    db $00
    db $FF
    db $FF
Bank0D_ScriptAddr_6B48:
    dw $030D  ; Text $030D: "$46:$456E *:Go to one of my brothers! // Something"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map19_Script02
; ---------------------------------------------------------------------------
Map19_Script02:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6BD0          ; -> branch target
    dw $FF2E  ; Cmd2E
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6B74          ; -> branch target
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6B74          ; -> branch target
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0D_ScriptAddr_6B74:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6BAA          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_6BB4          ; -> branch target
Bank0D_ScriptAddr_6B9A:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw Bank0D_ScriptAddr_6BBE          ; -> branch target
    dw $00F4  ; Text $00F4: "$43:$49ED *:Darn! Again!"
    dw $FF2F  ; Cmd2F
    dw $D9DF  ; RAM $D9DF
    dw $FFFF  ; END

Bank0D_ScriptAddr_6BAA:
    dw $00F6  ; Text $00F6: "$43:$4A22 *:It's a tie... In this case... // *:I w"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6BB4:
    dw $00F5  ; Text $00F5: "$43:$4A00 *:I won! Challenge me anytime!"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6BBE:
    dw $030C  ; Text $030C: "$46:$44D1 *:You...You are one tough kid!! // *:Oka"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF03  ; SetEventFlag
    dw $0083
    dw $FF12  ; WriteRAM
    dw $D94C  ; RAM $D94C
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
Bank0D_ScriptAddr_6BD0:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map19_Script03
; ---------------------------------------------------------------------------
Map19_Script03:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6BD0          ; -> branch target
    dw $FF2E  ; Cmd2E
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6BFA          ; -> branch target
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6BFA          ; -> branch target
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0D_ScriptAddr_6BFA:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6BAA          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6BB4          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_6B9A          ; -> branch target
; ---------------------------------------------------------------------------
; Map19_Script04
; ---------------------------------------------------------------------------
Map19_Script04:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6BD0          ; -> branch target
    dw $FF2E  ; Cmd2E
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6C4C          ; -> branch target
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6C4C          ; -> branch target
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0D_ScriptAddr_6C4C:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_6BAA          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6BB4          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_6B9A          ; -> branch target
; ---------------------------------------------------------------------------
; Map1A Per-Script Table (map_type=$1A, 7 scripts)
; ---------------------------------------------------------------------------
Map1A_ScriptPtrTable:
    dw Map1A_Script00                  ; script 0
    dw Map1A_Script01                  ; script 1
    dw Map1A_Script02                  ; script 2
    dw Map1A_Script03                  ; script 3
    dw Map1A_Script04                  ; script 4
    dw Map1A_Script05                  ; script 5
    dw Map1A_Script06                  ; script 6
; ---------------------------------------------------------------------------
; Map1A_Script00
; ---------------------------------------------------------------------------
Map1A_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1A_Script01
; ---------------------------------------------------------------------------
Map1A_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw Bank0D_ScriptAddr_6CB4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0083
    dw Bank0D_ScriptAddr_6C96          ; -> branch target
    dw $030A  ; Text $030A: "$46:$442A *:What? You can't even beat my // brothe"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6C96:
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6CAA
    dw $030B  ; Text $030B: "$46:$44A4 *:Ready! Rock-Paper- // Scissors... Go!"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFFF  ; END

    db $F2
    db $00
    db $12
    db $FF
    db $DF
    db $D9
    db $00
    db $00
    db $FF
    db $FF
Bank0D_ScriptAddr_6CB4:
    dw $0813  ; Text $0813: "$3F:$4FE1 *:Go to the arena. Something good'll // "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1A_Script02
; ---------------------------------------------------------------------------
Map1A_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $010B  ; Text $010B: "$43:$5234 *:This is an llonigirill. C'mon // BeBe,"
    dw Bank0D_ScriptAddr_6CC8          ; -> branch target
    dw $FF3C  ; Cmd3C
    dw $0811  ; Text $0811: "$3F:$4EDD *:I'm a monster namer. My job is // to c"
    dw $FF03  ; SetEventFlag
    dw $010B  ; Text $010B: "$43:$5234 *:This is an llonigirill. C'mon // BeBe,"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6CC8:
    dw $FF3C  ; Cmd3C
    dw $0780  ; Text $0780: "$22:$51D9 *:I'm the Master Monster Namer. // Wanna"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6CF2
    dw $FF04  ; ScreenEffect
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw $0780  ; Text $0780: "$22:$51D9 *:I'm the Master Monster Namer. // Wanna"
    dw $FF15  ; PlaySE
    dw $C8F4  ; RAM $C8F4
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $6CF2
    dw $FF06  ; IncrementCounter
    dw $FF04  ; ScreenEffect
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF3C  ; Cmd3C
    dw $FF07  ; InitDialogMode
    dw $FF14  ; ClearGameFlags
    dw $6CD4
    dw $FF3C  ; Cmd3C
    dw $0782  ; Text $0782: "$22:$523D *:Come back when you need me."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1A_Script03
; ---------------------------------------------------------------------------
Map1A_Script03:
    dw $0814  ; Text $0814: "$3F:$5020 *:The dude there will change the // name"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1A_Script04
; ---------------------------------------------------------------------------
Map1A_Script04:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6D90          ; -> branch target
    dw $FF2E  ; Cmd2E
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6D24          ; -> branch target
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6D24          ; -> branch target
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0D_ScriptAddr_6D24:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6D5A          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_6D64          ; -> branch target
Bank0D_ScriptAddr_6D4A:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw Bank0D_ScriptAddr_6D6E          ; -> branch target
    dw $00F4  ; Text $00F4: "$43:$49ED *:Darn! Again!"
    dw $FF2F  ; Cmd2F
    dw $D9DF  ; RAM $D9DF
    dw $FFFF  ; END

Bank0D_ScriptAddr_6D5A:
    dw $00F6  ; Text $00F6: "$43:$4A22 *:It's a tie... In this case... // *:I w"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6D64:
    dw $00F5  ; Text $00F5: "$43:$4A00 *:I won! Challenge me anytime!"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6D6E:
    dw $0812  ; Text $0812: "$3F:$4F63 *:Y..you! You're strong! // *:Look, I'll"
    dw $FF12  ; WriteRAM
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF03  ; SetEventFlag
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw $FF01  ; BranchIfFlagSet
    dw $001E  ; Text $001E: "$42:$4CEA [HERO] opened a treasure chest!"
    dw $6D88
    dw $FF12  ; WriteRAM
    dw $D94C  ; RAM $D94C
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFFF  ; END

    db $12
    db $FF
    db $4C
    db $D9
    db $05
    db $00
    db $FF
    db $FF
Bank0D_ScriptAddr_6D90:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1A_Script05
; ---------------------------------------------------------------------------
Map1A_Script05:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6D90          ; -> branch target
    dw $FF2E  ; Cmd2E
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6DBA          ; -> branch target
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6DBA          ; -> branch target
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0D_ScriptAddr_6DBA:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6D5A          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6D64          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_6D4A          ; -> branch target
; ---------------------------------------------------------------------------
; Map1A_Script06
; ---------------------------------------------------------------------------
Map1A_Script06:
    dw $FF15  ; PlaySE
    dw $D9DF  ; RAM $D9DF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6D90          ; -> branch target
    dw $FF2E  ; Cmd2E
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0D_ScriptAddr_6E0C          ; -> branch target
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6E0C          ; -> branch target
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0D_ScriptAddr_6E0C:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_6D5A          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9E0  ; RAM $D9E0
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6D64          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_6D4A          ; -> branch target
; ---------------------------------------------------------------------------
; Map1B Per-Script Table (map_type=$1B, 4 scripts)
; ---------------------------------------------------------------------------
Map1B_ScriptPtrTable:
    dw Map1B_Script00                  ; script 0
    dw Map1B_Script01                  ; script 1
    dw Map1B_Script02                  ; script 2
    dw Map1B_Script03                  ; script 3
; ---------------------------------------------------------------------------
; Map1B_Script00
; ---------------------------------------------------------------------------
Map1B_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1B_Script01
; ---------------------------------------------------------------------------
Map1B_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0D_ScriptAddr_6E4A          ; -> branch target
    dw $0245  ; Text $0245: "$45:$41B2 *:A skill such as Vivify can evolve // i"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6E4A:
    dw $0354  ; Text $0354: "$46:$62E7 *:BigBang, Hellblast // MultiCut.... // "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6E58
    dw $0355  ; Text $0355: "$46:$632D *:I see. you've grown to be a // respect"
    dw $FFFF  ; END

    db $56
    db $03
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Map1B_Script02
; ---------------------------------------------------------------------------
Map1B_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_6EAC          ; -> branch target
    dw $03CA  ; Text $03CA: "$47:$41E2 *:I'm the Monster Minister! // *:Do you "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6E7A          ; -> branch target
    dw $03CC  ; Text $03CC: "$47:$4279 *:How about the monsters living // behin"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6E7E          ; -> branch target
    dw $03CD  ; Text $03CD: "$47:$42E9 *:Behind the Gate of Villager, // Stubsu"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6E7A:
    dw $03CB  ; Text $03CB: "$47:$423E *:If you don't want to know, // that's f"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6E7E:
    dw $03CE  ; Text $03CE: "$47:$4397 *:How about monsters living // behind th"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6E8C
    dw $03CF  ; Text $03CF: "$47:$43F3 *:Behind the Gate of Memories are, // Go"
    dw $FFFF  ; END

    db $D0
    db $03
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $9A
    db $6E
    db $D1
    db $03
    db $FF
    db $FF
    db $D2
    db $03
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $A8
    db $6E
    db $D3
    db $03
    db $FF
    db $FF
    db $D4
    db $03
    db $FF
    db $FF
Bank0D_ScriptAddr_6EAC:
    dw $04CE  ; Text $04CE: "$48:$6B4F *:I am the Monster Minister. // All hail"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6EC4
    dw $04CF  ; Text $04CF: "$48:$6BC7 *:How about the monsters behind // the G"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6EC8
    dw $04D0  ; Text $04D0: "$48:$6C1A *:Behind the Gate of Joy live // Snailys"
    dw $FFFF  ; END

    db $CB
    db $03
    db $FF
    db $FF
    db $D1
    db $04
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $D6
    db $6E
    db $D2
    db $04
    db $FF
    db $FF
    db $D3
    db $04
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $E4
    db $6E
    db $D4
    db $04
    db $FF
    db $FF
    db $D5
    db $04
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $F2
    db $6E
    db $D6
    db $04
    db $FF
    db $FF
    db $CB
    db $03
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Map1B_Script03
; ---------------------------------------------------------------------------
Map1B_Script03:
    dw $0830  ; Text $0830: "$3F:$5E30 *:I'm the Monster Minister Jr. // All ha"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6F0E          ; -> branch target
    dw $0832  ; Text $0832: "$3F:$5EBD *:Wanna know about the monsters // behin"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_6F12          ; -> branch target
    dw $0833  ; Text $0833: "$3F:$5F12 *:Behind the Gate of Villager live // St"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6F0E:
    dw $0831  ; Text $0831: "$3F:$5E9B *:Don't wanna listen? Snivel..."
    dw $FFFF  ; END

Bank0D_ScriptAddr_6F12:
    dw $0834  ; Text $0834: "$3F:$5FAD *:Wanna know about the monsters // behin"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6F20
    dw $0835  ; Text $0835: "$3F:$6002 *:Behind the Gate of Memories live, // G"
    dw $FFFF  ; END

    db $36
    db $08
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $2E
    db $6F
    db $37
    db $08
    db $FF
    db $FF
    db $38
    db $08
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $3C
    db $6F
    db $39
    db $08
    db $FF
    db $FF
    db $31
    db $08
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Map1C Per-Script Table (map_type=$1C, 7 scripts)
; ---------------------------------------------------------------------------
Map1C_ScriptPtrTable:
    dw Map1C_Script00                  ; script 0
    dw Map1C_Script01                  ; script 1
    dw Map1C_Script02                  ; script 2
    dw Map1C_Script03                  ; script 3
    dw Map1C_Script04                  ; script 4
    dw Map1C_Script05                  ; script 5
    dw Map1C_Script06                  ; script 6
; ---------------------------------------------------------------------------
; Map1C_Script00
; ---------------------------------------------------------------------------
Map1C_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1C_Script01
; ---------------------------------------------------------------------------
Map1C_Script01:
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF24  ; Cmd24
    dw Bank0D_ScriptAddr_6FCC          ; -> branch target
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $001A  ; Text $001A: "$42:$4C3F *:I see....."
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $001A  ; Text $001A: "$42:$4C3F *:I see....."
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF07  ; InitDialogMode
    dw $FF01  ; BranchIfFlagSet
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw Bank0D_ScriptAddr_6F8E          ; -> branch target
    dw $0249  ; Text $0249: "$45:$4475 *:Argh, who woke us up?"
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_6F94          ; -> branch target
Bank0D_ScriptAddr_6F8E:
    dw $0357  ; Text $0357: "$46:$639D *:Even though we are Horks, we // don't "
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_6F94          ; -> branch target
Bank0D_ScriptAddr_6F94:
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF24  ; Cmd24
    dw Bank0D_ScriptAddr_6FB6          ; -> branch target
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6FB6:
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $1514
    dw $1514
    dw $16D8
    dw $1617
    dw $D817  ; RAM $D817
    dw $1918
    dw $1918
    dw $1AD8
    dw $1A1B
    dw $D91B  ; RAM $D91B
Bank0D_ScriptAddr_6FCC:
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $1D1C
    dw $1D1C
    dw $1ED8
    dw $1E1F
    dw $D81F  ; RAM $D81F
    dw $2120
    dw $2120
    dw $22D8
    dw $2223
    dw $D923  ; RAM $D923
; ---------------------------------------------------------------------------
; Map1C_Script02
; ---------------------------------------------------------------------------
Map1C_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_6FF6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_6FF2          ; -> branch target
    dw $024B  ; Text $024B: "$45:$4519 [HERO] looked at the candle. // Whoa! It"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6FF2:
    dw $04DA  ; Text $04DA: "$48:$7228 *:Flaring.... I am MadCandle. // *:My fl"
    dw $FFFF  ; END

Bank0D_ScriptAddr_6FF6:
    dw $0817  ; Text $0817: "$3F:$50FE *:New lives were born on the // Starry N"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1C_Script03
; ---------------------------------------------------------------------------
Map1C_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_700E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_700A          ; -> branch target
    dw $024B  ; Text $024B: "$45:$4519 [HERO] looked at the candle. // Whoa! It"
    dw $FFFF  ; END

Bank0D_ScriptAddr_700A:
    dw $04DA  ; Text $04DA: "$48:$7228 *:Flaring.... I am MadCandle. // *:My fl"
    dw $FFFF  ; END

Bank0D_ScriptAddr_700E:
    dw $0818  ; Text $0818: "$3F:$5133 *:My flame became more intense than // u"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1C_Script04
; ---------------------------------------------------------------------------
Map1C_Script04:
    dw $0246  ; Text $0246: "$45:$42DE *:Monsters fight differently // dependin"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_7020          ; -> branch target
    dw $0247  ; Text $0247: "$45:$43BE *:Order the same command again & // agai"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7020:
    dw $0248  ; Text $0248: "$45:$443F *:A good personality makes // good thing"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1C_Script05
; ---------------------------------------------------------------------------
Map1C_Script05:
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF24  ; Cmd24
    dw Bank0D_ScriptAddr_6FCC          ; -> branch target
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $001A  ; Text $001A: "$42:$4C3F *:I see....."
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $001A  ; Text $001A: "$42:$4C3F *:I see....."
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF07  ; InitDialogMode
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_7086          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_7080          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_707A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_7074          ; -> branch target
    dw $03D6  ; Text $03D6: "$47:$479A *:Ha ha ha! I made Gigantes a coward!"
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_6F94          ; -> branch target
Bank0D_ScriptAddr_7074:
    dw $0348  ; Text $0348: "$46:$5E21 *:Ha ha ha! I made Gigantes // smug!"
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_6F94          ; -> branch target
Bank0D_ScriptAddr_707A:
    dw $045E  ; Text $045E: "$21:$6EA2 *:Ha ha ha! I made Gigantes // an uncert"
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_6F94          ; -> branch target
Bank0D_ScriptAddr_7080:
    dw $04D8  ; Text $04D8: "$48:$7137 *:Ha ha ha! I made Gigantes brave! // *:"
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_6F94          ; -> branch target
Bank0D_ScriptAddr_7086:
    dw $0816  ; Text $0816: "$3F:$50B8 *:Is the Starry Night already // over? /"
    dw $FF14  ; ClearGameFlags
    dw Bank0D_ScriptAddr_6F94          ; -> branch target
; ---------------------------------------------------------------------------
; Map1C_Script06
; ---------------------------------------------------------------------------
Map1C_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_70B4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_70B0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_70AC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_70A8          ; -> branch target
    dw $03D5  ; Text $03D5: "$47:$4784 *:Don't pick on me!"
    dw $FFFF  ; END

Bank0D_ScriptAddr_70A8:
    dw $0345  ; Text $0345: "$46:$5D21 *:I'm the King of the world!!"
    dw $FFFF  ; END

Bank0D_ScriptAddr_70AC:
    dw $045D  ; Text $045D: "$21:$6E5F *:What should I do? That looks // nice, "
    dw $FFFF  ; END

Bank0D_ScriptAddr_70B0:
    dw $04D7  ; Text $04D7: "$48:$7116 *:I will do anything for you!"
    dw $FFFF  ; END

Bank0D_ScriptAddr_70B4:
    dw $0815  ; Text $0815: "$3F:$5065 *:Ho Ho Ho. I made the Servant // carele"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1D Per-Script Table (map_type=$1D, 7 scripts)
; ---------------------------------------------------------------------------
Map1D_ScriptPtrTable:
    dw Map1D_Script00                  ; script 0
    dw Map1D_Script01                  ; script 1
    dw Map1D_Script02                  ; script 2
    dw Map1D_Script03                  ; script 3
    dw Map1D_Script04                  ; script 4
    dw Map1D_Script05                  ; script 5
    dw Map1D_Script06                  ; script 6
; ---------------------------------------------------------------------------
; Map1D_Script00
; ---------------------------------------------------------------------------
Map1D_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1D_Script01
; ---------------------------------------------------------------------------
Map1D_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_70E8          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_70D8          ; -> branch target
    dw $0117  ; Text $0117: "$43:$581F [HERO] read the blackboard. // :Do's & D"
    dw $FFFF  ; END

Bank0D_ScriptAddr_70D8:
    dw $0889  ; Text $0889: "$4E:$5A0C [HERO] reads the blackboard. // *:There "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $70E6
    dw $088A  ; Text $088A: "$4E:$5B17 *:Namely, dragons with Metaly // parents"
    dw $FFFF  ; END

    db $FF
    db $FF
Bank0D_ScriptAddr_70E8:
    dw $0889  ; Text $0889: "$4E:$5A0C [HERO] reads the blackboard. // *:There "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $70E6
    dw $08C6
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1D_Script02
; ---------------------------------------------------------------------------
Map1D_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_710A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_7106          ; -> branch target
    dw $0118  ; Text $0118: "$43:$596B [HERO] read the blackboard. // :Masters "
    dw $FFFF  ; END

Bank0D_ScriptAddr_7106:
    dw $034E  ; Text $034E: "$46:$5FA0 [HERO] read the blackboard. // :The prin"
    dw $FFFF  ; END

Bank0D_ScriptAddr_710A:
    dw $04B9  ; Text $04B9: "$48:$602C [HERO] reads the blackboard. // :The pri"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1D_Script03
; ---------------------------------------------------------------------------
Map1D_Script03:
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
; ---------------------------------------------------------------------------
; Map1D_Script04
; ---------------------------------------------------------------------------
Map1D_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $010D  ; Text $010D: "$43:$5288 *:....."
    dw Bank0D_ScriptAddr_71AE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_7198          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_7180          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_7172          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_715A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0D_ScriptAddr_714C          ; -> branch target
    dw $0113  ; Text $0113: "$43:$5555 *:Welcome to the Master School! // *:I a"
    dw $FF03  ; SetEventFlag
    dw $0039  ; Text $0039: "$42:$5E3E *:Hey, Mr.Monster Master. I wonder // wh"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_7148          ; -> branch target
    dw $0114  ; Text $0114: "$43:$562E *:Sometimes monsters you beat // will be"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7148:
    dw $0871  ; Text $0871: "$4E:$4755 *:Hmmm. It's unfortunate."
    dw $FFFF  ; END

Bank0D_ScriptAddr_714C:
    dw $019E  ; Text $019E: "$44:$4645 *:Welcome to the Master School! // *:[HE"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_7148          ; -> branch target
    dw $0114  ; Text $0114: "$43:$562E *:Sometimes monsters you beat // will be"
    dw $FFFF  ; END

Bank0D_ScriptAddr_715A:
    dw $01D9  ; Text $01D9: "$44:$6D60 *:Welcome to the Master School! // *:Tod"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_7148          ; -> branch target
    dw $087A  ; Text $087A: "$4E:$4DFE *:There are characteristics // for monst"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_7148          ; -> branch target
    dw $087B  ; Text $087B: "$4E:$4EF1 *:Dragons with Metaly // parents // *:ar"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7172:
    dw $0288  ; Text $0288: "$45:$6070 *:Welcome to the Master School. // *:Tod"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_7148          ; -> branch target
    dw $0887  ; Text $0887: "$4E:$582A *:When the family of the pedigree // and"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7180:
    dw $0894  ; Text $0894: "$4E:$62B5 *:The Hork downstairs wants // to learn "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_7148          ; -> branch target
    dw $0895  ; Text $0895: "$4E:$6352 *:Monsters can inherit all the // skills"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0D_ScriptAddr_7148          ; -> branch target
    dw $0896  ; Text $0896: "$4E:$6493 *:Its parents only learned Heal, // *:am"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7198:
    dw $0819  ; Text $0819: "$3F:$519F *:[HERO], Well done! // Congratulations "
    dw $FF03  ; SetEventFlag
    dw $010D  ; Text $010D: "$43:$5288 *:....."
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $71AA
    dw $028C  ; Text $028C: "$45:$62B9 *:The names of the monsters available //"
    dw $FFFF  ; END

    db $8D
    db $02
    db $FF
    db $FF
Bank0D_ScriptAddr_71AE:
    dw $081A  ; Text $081A: "$3F:$52ED *:Just like you, the Master // Monster T"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $71AA
    dw $028C  ; Text $028C: "$45:$62B9 *:The names of the monsters available //"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1D_Script05
; ---------------------------------------------------------------------------
Map1D_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_7206          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_71EA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_71DC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0D_ScriptAddr_71D8          ; -> branch target
    dw $0115  ; Text $0115: "$43:$5793 *:It's helpful to take a WarpWing // wit"
    dw $FFFF  ; END

Bank0D_ScriptAddr_71D8:
    dw $019F  ; Text $019F: "$44:$46DB *:It's always better to have a // WarpWi"
    dw $FFFF  ; END

Bank0D_ScriptAddr_71DC:
    dw $01DA  ; Text $01DA: "$44:$6DDB *:I took notes about how to catch // mon"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $7230
    dw $01DC  ; Text $01DC: "$44:$6E39 [HERO] opens the notebook. // :Giving mo"
    dw $FFFF  ; END

Bank0D_ScriptAddr_71EA:
    dw $0897  ; Text $0897: "$4E:$6607 *:I took notes on how to change // the g"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $71F8
    dw $0898  ; Text $0898: "$4E:$6662 [HERO] opened the notebook. // :When the"
    dw $FFFF  ; END

    db $99
    db $08
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $30
    db $72
    db $DC
    db $01
    db $FF
    db $FF
Bank0D_ScriptAddr_7206:
    dw $028E  ; Text $028E: "$45:$63DB *:Congratulations on your victory! // Ou"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $7214
    dw $02EF  ; Text $02EF: "$1F:$54DB [HERO] opened the notebook. // :Monsters"
    dw $FFFF  ; END

    db $F0
    db $02
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $22
    db $72
    db $98
    db $08
    db $FF
    db $FF
    db $99
    db $08
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $30
    db $72
    db $DC
    db $01
    db $FF
    db $FF
    db $DB
    db $01
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Map1D_Script06
; ---------------------------------------------------------------------------
Map1D_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_7266          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_7262          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_725E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw Bank0D_ScriptAddr_725A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw Bank0D_ScriptAddr_7256          ; -> branch target
    dw $0116  ; Text $0116: "$43:$57F4 *:Here's the Monster Master // School."
    dw $FFFF  ; END

Bank0D_ScriptAddr_7256:
    dw $01A0  ; Text $01A0: "$44:$474D *:You are good. You beat the // teacher!"
    dw $FFFF  ; END

Bank0D_ScriptAddr_725A:
    dw $01DE  ; Text $01DE: "$44:$7035 *:There are foreign masters // who... //"
    dw $FFFF  ; END

Bank0D_ScriptAddr_725E:
    dw $0888  ; Text $0888: "$4E:$5973 *:There are foreign masters // whose mon"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7262:
    dw $089A  ; Text $089A: "$4E:$67FD *:Foreign masters have lots of kinds // "
    dw $FFFF  ; END

Bank0D_ScriptAddr_7266:
    dw $030F  ; Text $030F: "$46:$4671 *:Foreign masters have many kinds // of "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1E Per-Script Table (map_type=$1E, 5 scripts)
; ---------------------------------------------------------------------------
Map1E_ScriptPtrTable:
    dw Map1E_Script00                  ; script 0
    dw Map1E_Script01                  ; script 1
    dw Map1E_Script02                  ; script 2
    dw Map1E_Script03                  ; script 3
    dw Map1E_Script04                  ; script 4
; ---------------------------------------------------------------------------
; Map1E_Script00
; ---------------------------------------------------------------------------
Map1E_Script00:
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $00F2  ; Text $00F2: "$43:$4912 *:Hm, its not fun."
    dw Bank0D_ScriptAddr_727E          ; -> branch target
    dw $FFFF  ; END

Bank0D_ScriptAddr_727E:
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF44  ; Cmd44
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1E_Script01
; ---------------------------------------------------------------------------
Map1E_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_72DA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_72D6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0097
    dw Bank0D_ScriptAddr_72D2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_72CA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_72C6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0D_ScriptAddr_72C2          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_72BE          ; -> branch target
    dw $0119  ; Text $0119: "$43:$59DB *:Superior masters... // *:have a well-b"
    dw $FFFF  ; END

Bank0D_ScriptAddr_72BE:
    dw $024E  ; Text $024E: "$45:$46BC *:When you receive an offer to breed, //"
    dw $FFFF  ; END

Bank0D_ScriptAddr_72C2:
    dw $030E  ; Text $030E: "$46:$45BD *:May I help you [HERO]! I heard a // ru"
    dw $FFFF  ; END

Bank0D_ScriptAddr_72C6:
    dw $03DB  ; Text $03DB: "$47:$4908 *:I heard a rumor that a terrible // mas"
    dw $FFFF  ; END

Bank0D_ScriptAddr_72CA:
    dw $03FF
    dw $FF03  ; SetEventFlag
    dw $0097
    dw $FFFF  ; END

Bank0D_ScriptAddr_72D2:
    dw $0400  ; Text $0400: "$21:$4106 *:I heard a rumor that a terrible // mas"
    dw $FFFF  ; END

Bank0D_ScriptAddr_72D6:
    dw $0461
    dw $FFFF  ; END

Bank0D_ScriptAddr_72DA:
    dw $0821  ; Text $0821: "$3F:$55D0 *:Once a famous master told me... // *:A"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1E_Script02
; ---------------------------------------------------------------------------
Map1E_Script02:
    dw $FF00  ; BranchIfFlagClear
    dw $000E  ; Text $000E: "$42:$483B Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_7302          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_7320          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_731C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_7318          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw Bank0D_ScriptAddr_7314          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_7310          ; -> branch target
Bank0D_ScriptAddr_7302:
    dw $FF01  ; BranchIfFlagSet
    dw $000E  ; Text $000E: "$42:$483B Terry looked at a stuffed animal. // Som"
    dw Bank0D_ScriptAddr_730C          ; -> branch target
    dw $011A  ; Text $011A: "$43:$5A92 *:Army Bomb Army, Bubble Army...! // *:U"
    dw $FFFF  ; END

Bank0D_ScriptAddr_730C:
    dw $013E  ; Text $013E: "$43:$65F7 *:Uuu Hmm... // *:I wonder who'll win th"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7310:
    dw $0881  ; Text $0881: "$4E:$5357 *:IceMan has a relative!! // *:It is cal"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7314:
    dw $03DC  ; Text $03DC: "$47:$49C7 *:Oops...I lost ...I guess I'll // try t"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7318:
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FFFF  ; END

Bank0D_ScriptAddr_731C:
    dw $0462  ; Text $0462: "$21:$704B *:I think I'll go to bed. // But yet.. n"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7320:
    dw $0822  ; Text $0822: "$3F:$56D3 *:Uuu.. yawn! Who won? // *:Oh, her Maje"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1E_Script03
; ---------------------------------------------------------------------------
Map1E_Script03:
    dw $FF00  ; BranchIfFlagClear
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw Bank0D_ScriptAddr_7330          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw Bank0D_ScriptAddr_738A          ; -> branch target
Bank0D_ScriptAddr_7330:
    dw $FF01  ; BranchIfFlagSet
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw Bank0D_ScriptAddr_7386          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $005F  ; Text $005F: "$42:$73FE *:These stairs go up to the // monster f"
    dw Bank0D_ScriptAddr_7368          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw Bank0D_ScriptAddr_7346          ; -> branch target
    dw $011B  ; Text $011B: "$43:$5AF2 *:Who the heck is that old woman at // t"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7346:
    dw $FF3C  ; Cmd3C
    dw $024F  ; Text $024F: "$45:$47B2 *:Hic, yo brother. Wanna have a breed //"
    dw $FF03  ; SetEventFlag
    dw $005F  ; Text $005F: "$42:$73FE *:These stairs go up to the // monster f"
    dw $FF03  ; SetEventFlag
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF42  ; SetReturnMap
    dw $0132  ; Text $0132: "$43:$6302 The Gate is shut tight."
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0610  ; Text $0610: "$4A:$5131 *:Tut, stingy. Hic..."
    dw $FF02  ; ClearEventFlag
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF3C  ; Cmd3C
    dw $0610  ; Text $0610: "$4A:$5131 *:Tut, stingy. Hic..."
    dw $FFFF  ; END

Bank0D_ScriptAddr_7368:
    dw $FF3C  ; Cmd3C
    dw $025A  ; Text $025A: "$45:$4A7E *:Want to match with my CatFly?"
    dw $FF03  ; SetEventFlag
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF42  ; SetReturnMap
    dw $0132  ; Text $0132: "$43:$6302 The Gate is shut tight."
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0610  ; Text $0610: "$4A:$5131 *:Tut, stingy. Hic..."
    dw $FF02  ; ClearEventFlag
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF3C  ; Cmd3C
    dw $0610  ; Text $0610: "$4A:$5131 *:Tut, stingy. Hic..."
    dw $FFFF  ; END

Bank0D_ScriptAddr_7386:
    dw $025B  ; Text $025B: "$45:$4AA0 *:You are aiming for D class now? // Wat"
    dw $FFFF  ; END

Bank0D_ScriptAddr_738A:
    dw $028B  ; Text $028B: "$45:$61B0 *:How did you beat Mick! I'm glad // you"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1E_Script04
; ---------------------------------------------------------------------------
Map1E_Script04:
    dw $FF00  ; BranchIfFlagClear
    dw $0094
    dw Bank0D_ScriptAddr_739A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_7468          ; -> branch target
Bank0D_ScriptAddr_739A:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0D_ScriptAddr_7464          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0D_ScriptAddr_7460          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $011D  ; Text $011D: "$43:$5C1B *:Here is her majesty the Queen // of Gr"
    dw Bank0D_ScriptAddr_745C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $011C  ; Text $011C: "$43:$5B5E *:I am the Queen of GreatTree. // I like"
    dw Bank0D_ScriptAddr_7454          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw Bank0D_ScriptAddr_73BE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0098
    dw Bank0D_ScriptAddr_7450          ; -> branch target
Bank0D_ScriptAddr_73BE:
    dw $FF01  ; BranchIfFlagSet
    dw $0098
    dw Bank0D_ScriptAddr_744C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw Bank0D_ScriptAddr_742A          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $0085
    dw Bank0D_ScriptAddr_73D6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0094
    dw Bank0D_ScriptAddr_7426          ; -> branch target
Bank0D_ScriptAddr_73D6:
    dw $FF01  ; BranchIfFlagSet
    dw $0085
    dw Bank0D_ScriptAddr_7422          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0084
    dw Bank0D_ScriptAddr_7404          ; -> branch target
    dw $FF3C  ; Cmd3C
    dw $0310  ; Text $0310: "$46:$4760 *:How do you do? My name is May. // It's"
    dw $FF03  ; SetEventFlag
    dw $0084
    dw $FF03  ; SetEventFlag
    dw $0085
    dw $FF42  ; SetReturnMap
    dw $0135  ; Text $0135: "$43:$6399 The Gate is shut tight."
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0640  ; Text $0640: "$4A:$5817 *:Please come to me when you want // to "
    dw $FF02  ; ClearEventFlag
    dw $0085
    dw $FF3C  ; Cmd3C
    dw $0640  ; Text $0640: "$4A:$5817 *:Please come to me when you want // to "
    dw $FFFF  ; END

Bank0D_ScriptAddr_7404:
    dw $FF3C  ; Cmd3C
    dw $031B  ; Text $031B: "$46:$4C3E *:What do you say? Why don't you // bree"
    dw $FF03  ; SetEventFlag
    dw $0085
    dw $FF42  ; SetReturnMap
    dw $0135  ; Text $0135: "$43:$6399 The Gate is shut tight."
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF04  ; ScreenEffect
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0640  ; Text $0640: "$4A:$5817 *:Please come to me when you want // to "
    dw $FF02  ; ClearEventFlag
    dw $0085
    dw $FF3C  ; Cmd3C
    dw $0640  ; Text $0640: "$4A:$5817 *:Please come to me when you want // to "
    dw $FFFF  ; END

Bank0D_ScriptAddr_7422:
    dw $031C  ; Text $031C: "$46:$4C7B *:I'm trying to pick up all the // items"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7426:
    dw $02A8  ; Text $02A8: "$45:$6C7D *:Soon you will become powerful! // *:Du"
    dw $FFFF  ; END

Bank0D_ScriptAddr_742A:
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $7444
    dw $FF28  ; CheckStorageFull
    dw $7448
    dw $0403  ; Text $0403: "$21:$42E8 *:I'll send my StoneMan to the // farm t"
    dw $FF29  ; AddMonster
    dw $013A  ; Text $013A: "$43:$64AE [HERO] looked into the barrel. // Nothin"
    dw $FF03  ; SetEventFlag
    dw $0098
    dw $FFFF  ; END

    db $05
    db $04
    db $FF
    db $FF
    db $04
    db $04
    db $FF
    db $FF
Bank0D_ScriptAddr_744C:
    dw $0406  ; Text $0406: "$21:$4411 *:My StoneMan can use Ahhh! // *:Boy mon"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7450:
    dw $0463  ; Text $0463: "$21:$7084 *:[HERO]. Let me tell you. // *:When you"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7454:
    dw $0859
    dw $FF03  ; SetEventFlag
    dw $011D  ; Text $011D: "$43:$5C1B *:Here is her majesty the Queen // of Gr"
    dw $FFFF  ; END

Bank0D_ScriptAddr_745C:
    dw $085A
    dw $FFFF  ; END

Bank0D_ScriptAddr_7460:
    dw $04DD  ; Text $04DD: "$48:$737A *:[HERO], lemme tell you. // *:I heard a"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7464:
    dw $0823  ; Text $0823: "$3F:$5713 *:The rumor of the dreadful master // wa"
    dw $FFFF  ; END

Bank0D_ScriptAddr_7468:
    dw $0824  ; Text $0824: "$3F:$57BE May:Don't you think Divinegon // looks l"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map1F Per-Script Table (map_type=$1F, 0 scripts)
; ---------------------------------------------------------------------------
Map1F_ScriptPtrTable:
    dw $7480
    dw $749C
    dw $74AA
    dw $7994
    dw $7A22
    dw $7B10
    dw $7BE4
    dw $7A1E
    dw $7B0C
    dw $7BE0
    dw $FF15  ; PlaySE
    dw $D951  ; RAM $D951
    dw $00F2  ; Text $00F2: "$43:$4912 *:Hm, its not fun."
    dw Bank0D_ScriptAddr_748A          ; -> branch target
    dw $FFFF  ; END

Bank0D_ScriptAddr_748A:
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF44  ; Cmd44
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

    db $01
    db $FF
    db $F1
    db $00
    db $A6
    db $74
    db $F3
    db $01
    db $FF
    db $FF
    db $02
    db $00
    db $FF
    db $FF
    db $01
    db $FF
    db $55
    db $01
    db $90
    db $79
    db $01
    db $FF
    db $56
    db $01
    db $80
    db $79
    db $00
    db $FF
    db $54
    db $01
    db $C2
    db $74
    db $40
    db $FF
    db $2C
    db $00
    db $66
    db $79
    db $01
    db $FF
    db $52
    db $01
    db $5E
    db $79
    db $01
    db $FF
    db $53
    db $01
    db $4E
    db $79
    db $00
    db $FF
    db $51
    db $01
    db $DA
    db $74
    db $40
    db $FF
    db $C7
    db $00
    db $34
    db $79
    db $01
    db $FF
    db $4F
    db $01
    db $2C
    db $79
    db $01
    db $FF
    db $50
    db $01
    db $1C
    db $79
    db $00
    db $FF
    db $4E
    db $01
    db $F2
    db $74
    db $40
    db $FF
    db $6C
    db $00
    db $02
    db $79
    db $01
    db $FF
    db $4C
    db $01
    db $FA
    db $78
    db $01
    db $FF
    db $4D
    db $01
    db $EA
    db $78
    db $00
    db $FF
    db $4B
    db $01
    db $0A
    db $75
    db $40
    db $FF
    db $80
    db $00
    db $D0
    db $78
    db $01
    db $FF
    db $49
    db $01
    db $C8
    db $78
    db $01
    db $FF
    db $4A
    db $01
    db $B8
    db $78
    db $00
    db $FF
    db $48
    db $01
    db $22
    db $75
    db $40
    db $FF
    db $59
    db $00
    db $9E
    db $78
    db $01
    db $FF
    db $46
    db $01
    db $96
    db $78
    db $01
    db $FF
    db $47
    db $01
    db $86
    db $78
    db $00
    db $FF
    db $45
    db $01
    db $3A
    db $75
    db $40
    db $FF
    db $42
    db $00
    db $6C
    db $78
    db $01
    db $FF
    db $43
    db $01
    db $64
    db $78
    db $01
    db $FF
    db $44
    db $01
    db $54
    db $78
    db $00
    db $FF
    db $42
    db $01
    db $52
    db $75
    db $40
    db $FF
    db $AA
    db $00
    db $3A
    db $78
    db $01
    db $FF
    db $41
    db $01
    db $32
    db $78
    db $00
    db $FF
    db $F1
    db $00
    db $64
    db $75
    db $01
    db $FF
    db $3F
    db $01
    db $2A
    db $78
    db $01
    db $FF
    db $3F
    db $01
    db $26
    db $78
    db $01
    db $FF
    db $40
    db $01
    db $16
    db $78
    db $00
    db $FF
    db $3E
    db $01
    db $7C
    db $75
    db $40
    db $FF
    db $55
    db $00
    db $FC
    db $77
    db $01
    db $FF
    db $3C
    db $01
    db $F4
    db $77
    db $01
    db $FF
    db $3D
    db $01
    db $E4
    db $77
    db $00
    db $FF
    db $3B
    db $01
    db $94
    db $75
    db $40
    db $FF
    db $A8
    db $00
    db $CA
    db $77
    db $01
    db $FF
    db $39
    db $01
    db $C2
    db $77
    db $01
    db $FF
    db $3A
    db $01
    db $B2
    db $77
    db $00
    db $FF
    db $38
    db $01
    db $AC
    db $75
    db $40
    db $FF
    db $7F
    db $00
    db $98
    db $77
    db $01
    db $FF
    db $36
    db $01
    db $90
    db $77
    db $01
    db $FF
    db $37
    db $01
    db $80
    db $77
    db $00
    db $FF
    db $35
    db $01
    db $C4
    db $75
    db $40
    db $FF
    db $40
    db $00
    db $66
    db $77
    db $01
    db $FF
    db $33
    db $01
    db $5E
    db $77
    db $01
    db $FF
    db $34
    db $01
    db $4E
    db $77
    db $00
    db $FF
    db $32
    db $01
    db $DC
    db $75
    db $40
    db $FF
    db $10
    db $00
    db $34
    db $77
    db $00
    db $FF
    db $1D
    db $00
    db $E8
    db $75
    db $01
    db $FF
    db $30
    db $01
    db $2C
    db $77
    db $01
    db $FF
    db $30
    db $01
    db $28
    db $77
    db $01
    db $FF
    db $31
    db $01
    db $18
    db $77
    db $00
    db $FF
    db $2F
    db $01
    db $00
    db $76
    db $40
    db $FF
    db $BC
    db $00
    db $FE
    db $76
    db $01
    db $FF
    db $2D
    db $01
    db $F6
    db $76
    db $01
    db $FF
    db $2E
    db $01
    db $E6
    db $76
    db $00
    db $FF
    db $2C
    db $01
    db $18
    db $76
    db $40
    db $FF
    db $49
    db $00
    db $CC
    db $76
    db $01
    db $FF
    db $2A
    db $01
    db $C4
    db $76
    db $01
    db $FF
    db $2B
    db $01
    db $B4
    db $76
    db $00
    db $FF
    db $29
    db $01
    db $30
    db $76
    db $40
    db $FF
    db $0F
    db $00
    db $9A
    db $76
    db $01
    db $FF
    db $27
    db $01
    db $92
    db $76
    db $01
    db $FF
    db $28
    db $01
    db $7E
    db $76
    db $00
    db $FF
    db $26
    db $01
    db $48
    db $76
    db $40
    db $FF
    db $02
    db $00
    db $64
    db $76
    db $00
    db $FF
    db $45
    db $00
    db $54
    db $76
    db $01
    db $FF
    db $31
    db $00
    db $5C
    db $76
    db $1C
    db $01
    db $03
    db $FF
    db $61
    db $00
    db $FF
    db $FF
    db $50
    db $03
    db $03
    db $FF
    db $26
    db $01
    db $FF
    db $FF
    db $59
    db $03
    db $2C
    db $FF
    db $76
    db $76
    db $5B
    db $03
    db $03
    db $FF
    db $27
    db $01
    db $2A
    db $FF
    db $17
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $28
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $5B
    db $03
    db $03
    db $FF
    db $27
    db $01
    db $2A
    db $FF
    db $17
    db $00
    db $FF
    db $FF
    db $C5
    db $08
    db $FF
    db $FF
    db $5C
    db $03
    db $03
    db $FF
    db $29
    db $01
    db $FF
    db $FF
    db $AC
    db $03
    db $2C
    db $FF
    db $AC
    db $76
    db $AD
    db $03
    db $03
    db $FF
    db $2A
    db $01
    db $2A
    db $FF
    db $12
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $2B
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $AD
    db $03
    db $03
    db $FF
    db $2A
    db $01
    db $2A
    db $FF
    db $12
    db $00
    db $FF
    db $FF
    db $D8
    db $03
    db $03
    db $FF
    db $2C
    db $01
    db $FF
    db $FF
    db $D9
    db $03
    db $2C
    db $FF
    db $DE
    db $76
    db $DA
    db $03
    db $03
    db $FF
    db $2D
    db $01
    db $2A
    db $FF
    db $11
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $2E
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $DA
    db $03
    db $03
    db $FF
    db $2D
    db $01
    db $2A
    db $FF
    db $11
    db $00
    db $FF
    db $FF
    db $F8
    db $03
    db $03
    db $FF
    db $2F
    db $01
    db $FF
    db $FF
    db $4A
    db $03
    db $2C
    db $FF
    db $10
    db $77
    db $4B
    db $03
    db $03
    db $FF
    db $30
    db $01
    db $2A
    db $FF
    db $10
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $31
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $4B
    db $03
    db $03
    db $FF
    db $30
    db $01
    db $2A
    db $FF
    db $10
    db $00
    db $FF
    db $FF
    db $4C
    db $03
    db $FF
    db $FF
    db $1D
    db $03
    db $03
    db $FF
    db $32
    db $01
    db $FF
    db $FF
    db $4D
    db $03
    db $2C
    db $FF
    db $46
    db $77
    db $07
    db $04
    db $03
    db $FF
    db $33
    db $01
    db $2A
    db $FF
    db $0D
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $34
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $07
    db $04
    db $03
    db $FF
    db $33
    db $01
    db $2A
    db $FF
    db $0D
    db $00
    db $FF
    db $FF
    db $52
    db $04
    db $03
    db $FF
    db $35
    db $01
    db $FF
    db $FF
    db $60
    db $04
    db $2C
    db $FF
    db $78
    db $77
    db $64
    db $04
    db $03
    db $FF
    db $36
    db $01
    db $2A
    db $FF
    db $0F
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $37
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $64
    db $04
    db $03
    db $FF
    db $36
    db $01
    db $2A
    db $FF
    db $0F
    db $00
    db $FF
    db $FF
    db $65
    db $04
    db $03
    db $FF
    db $38
    db $01
    db $FF
    db $FF
    db $B6
    db $04
    db $2C
    db $FF
    db $AA
    db $77
    db $BA
    db $04
    db $03
    db $FF
    db $39
    db $01
    db $2A
    db $FF
    db $0E
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $3A
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $BA
    db $04
    db $03
    db $FF
    db $39
    db $01
    db $2A
    db $FF
    db $0E
    db $00
    db $FF
    db $FF
    db $DB
    db $04
    db $03
    db $FF
    db $3B
    db $01
    db $FF
    db $FF
    db $DC
    db $04
    db $2C
    db $FF
    db $DC
    db $77
    db $E8
    db $07
    db $03
    db $FF
    db $3C
    db $01
    db $2A
    db $FF
    db $20
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $3D
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $E8
    db $07
    db $03
    db $FF
    db $3C
    db $01
    db $2A
    db $FF
    db $20
    db $00
    db $FF
    db $FF
    db $E9
    db $07
    db $03
    db $FF
    db $3E
    db $01
    db $FF
    db $FF
    db $1B
    db $08
    db $2C
    db $FF
    db $0E
    db $78
    db $1C
    db $08
    db $03
    db $FF
    db $3F
    db $01
    db $2A
    db $FF
    db $22
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $40
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $1C
    db $08
    db $03
    db $FF
    db $3F
    db $01
    db $2A
    db $FF
    db $22
    db $00
    db $FF
    db $FF
    db $1D
    db $08
    db $FF
    db $FF
    db $25
    db $08
    db $03
    db $FF
    db $41
    db $01
    db $FF
    db $FF
    db $1E
    db $08
    db $03
    db $FF
    db $42
    db $01
    db $FF
    db $FF
    db $1F
    db $08
    db $2C
    db $FF
    db $4C
    db $78
    db $20
    db $08
    db $03
    db $FF
    db $43
    db $01
    db $2A
    db $FF
    db $24
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $44
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $20
    db $08
    db $03
    db $FF
    db $43
    db $01
    db $2A
    db $FF
    db $24
    db $00
    db $FF
    db $FF
    db $A7
    db $08
    db $03
    db $FF
    db $45
    db $01
    db $FF
    db $FF
    db $A8
    db $08
    db $2C
    db $FF
    db $7E
    db $78
    db $A9
    db $08
    db $03
    db $FF
    db $46
    db $01
    db $2A
    db $FF
    db $23
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $47
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $A9
    db $08
    db $03
    db $FF
    db $46
    db $01
    db $2A
    db $FF
    db $23
    db $00
    db $FF
    db $FF
    db $AA
    db $08
    db $03
    db $FF
    db $48
    db $01
    db $FF
    db $FF
    db $AB
    db $08
    db $2C
    db $FF
    db $B0
    db $78
    db $AC
    db $08
    db $03
    db $FF
    db $49
    db $01
    db $2A
    db $FF
    db $21
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $4A
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $AC
    db $08
    db $03
    db $FF
    db $49
    db $01
    db $2A
    db $FF
    db $21
    db $00
    db $FF
    db $FF
    db $AD
    db $08
    db $03
    db $FF
    db $4B
    db $01
    db $FF
    db $FF
    db $AE
    db $08
    db $2C
    db $FF
    db $E2
    db $78
    db $AF
    db $08
    db $03
    db $FF
    db $4C
    db $01
    db $2A
    db $FF
    db $1F
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $4D
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $AF
    db $08
    db $03
    db $FF
    db $4C
    db $01
    db $2A
    db $FF
    db $1F
    db $00
    db $FF
    db $FF
    db $B0
    db $08
    db $03
    db $FF
    db $4E
    db $01
    db $FF
    db $FF
    db $B1
    db $08
    db $2C
    db $FF
    db $14
    db $79
    db $B2
    db $08
    db $03
    db $FF
    db $4F
    db $01
    db $2A
    db $FF
    db $0D
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $50
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $B2
    db $08
    db $03
    db $FF
    db $4F
    db $01
    db $2A
    db $FF
    db $0D
    db $00
    db $FF
    db $FF
    db $B3
    db $08
    db $03
    db $FF
    db $51
    db $01
    db $FF
    db $FF
    db $B4
    db $08
    db $2C
    db $FF
    db $46
    db $79
    db $B5
    db $08
    db $03
    db $FF
    db $52
    db $01
    db $2A
    db $FF
    db $1E
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $53
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $B5
    db $08
    db $03
    db $FF
    db $52
    db $01
    db $2A
    db $FF
    db $1E
    db $00
    db $FF
    db $FF
    db $B6
    db $08
    db $03
    db $FF
    db $54
    db $01
    db $FF
    db $FF
    db $B7
    db $08
    db $2C
    db $FF
    db $78
    db $79
    db $B8
    db $08
    db $03
    db $FF
    db $55
    db $01
    db $2A
    db $FF
    db $1E
    db $00
    db $FF
    db $FF
    db $5A
    db $03
    db $03
    db $FF
    db $56
    db $01
    db $FF
    db $FF
    db $2C
    db $FF
    db $8E
    db $76
    db $B8
    db $08
    db $03
    db $FF
    db $55
    db $01
    db $2A
    db $FF
    db $1E
    db $00
    db $FF
    db $FF
    db $B9
    db $08
    db $FF
    db $FF
    db $01
    db $FF
    db $57
    db $01
    db $1A
    db $7A
    db $01
    db $FF
    db $F1
    db $00
    db $12
    db $7A
    db $01
    db $FF
    db $3F
    db $01
    db $0E
    db $7A
    db $01
    db $FF
    db $3C
    db $01
    db $0A
    db $7A
    db $01
    db $FF
    db $39
    db $01
    db $06
    db $7A
    db $01
    db $FF
    db $36
    db $01
    db $02
    db $7A
    db $01
    db $FF
    db $33
    db $01
    db $FE
    db $79
    db $01
    db $FF
    db $1D
    db $00
    db $FA
    db $79
    db $01
    db $FF
    db $2D
    db $01
    db $F6
    db $79
    db $01
    db $FF
    db $2A
    db $01
    db $F2
    db $79
    db $01
    db $FF
    db $27
    db $01
    db $EE
    db $79
    db $00
    db $FF
    db $45
    db $00
    db $E2
    db $79
    db $01
    db $FF
    db $31
    db $00
    db $EA
    db $79
    db $1D
    db $01
    db $03
    db $FF
    db $62
    db $00
    db $FF
    db $FF
    db $BA
    db $08
    db $FF
    db $FF
    db $BB
    db $08
    db $FF
    db $FF
    db $BC
    db $08
    db $FF
    db $FF
    db $BD
    db $08
    db $FF
    db $FF
    db $1E
    db $03
    db $FF
    db $FF
    db $BF
    db $08
    db $FF
    db $FF
    db $C0
    db $08
    db $FF
    db $FF
    db $C1
    db $08
    db $FF
    db $FF
    db $C2
    db $08
    db $FF
    db $FF
    db $C3
    db $08
    db $FF
    db $FF
    db $26
    db $08
    db $03
    db $FF
    db $57
    db $01
    db $FF
    db $FF
    db $4E
    db $08
    db $FF
    db $FF
    db $4A
    db $FF
    db $01
    db $00
    db $01
    db $FF
    db $6E
    db $00
    db $08
    db $7B
    db $01
    db $FF
    db $6D
    db $00
    db $EA
    db $7A
    db $01
    db $FF
    db $33
    db $00
    db $C8
    db $7A
    db $01
    db $FF
    db $67
    db $00
    db $C4
    db $7A
    db $01
    db $FF
    db $66
    db $00
    db $A6
    db $7A
    db $01
    db $FF
    db $65
    db $00
    db $84
    db $7A
    db $01
    db $FF
    db $64
    db $00
    db $7C
    db $7A
    db $01
    db $FF
    db $63
    db $00
    db $74
    db $7A
    db $01
    db $FF
    db $32
    db $00
    db $6C
    db $7A
    db $00
    db $FF
    db $45
    db $00
    db $64
    db $7A
    db $01
    db $FF
    db $31
    db $00
    db $68
    db $7A
    db $1E
    db $01
    db $FF
    db $FF
    db $BE
    db $08
    db $FF
    db $FF
    db $5E
    db $02
    db $03
    db $FF
    db $63
    db $00
    db $FF
    db $FF
    db $5F
    db $02
    db $03
    db $FF
    db $64
    db $00
    db $FF
    db $FF
    db $60
    db $02
    db $03
    db $FF
    db $65
    db $00
    db $FF
    db $FF
    db $3C
    db $FF
    db $61
    db $02
    db $03
    db $FF
    db $66
    db $00
    db $03
    db $FF
    db $67
    db $00
    db $42
    db $FF
    db $31
    db $01
    db $03
    db $00
    db $04
    db $FF
    db $05
    db $00
    db $20
    db $06
    db $02
    db $FF
    db $67
    db $00
    db $3C
    db $FF
    db $20
    db $06
    db $FF
    db $FF
    db $3C
    db $FF
    db $6C
    db $02
    db $03
    db $FF
    db $67
    db $00
    db $42
    db $FF
    db $31
    db $01
    db $03
    db $00
    db $04
    db $FF
    db $05
    db $00
    db $20
    db $06
    db $02
    db $FF
    db $67
    db $00
    db $3C
    db $FF
    db $20
    db $06
    db $FF
    db $FF
    db $6D
    db $02
    db $FF
    db $FF
    db $3C
    db $FF
    db $8F
    db $02
    db $03
    db $FF
    db $6D
    db $00
    db $03
    db $FF
    db $6E
    db $00
    db $42
    db $FF
    db $33
    db $01
    db $03
    db $00
    db $04
    db $FF
    db $05
    db $00
    db $30
    db $06
    db $02
    db $FF
    db $6E
    db $00
    db $3C
    db $FF
    db $30
    db $06
    db $FF
    db $FF
    db $3C
    db $FF
    db $9A
    db $02
    db $03
    db $FF
    db $6E
    db $00
    db $42
    db $FF
    db $33
    db $01
    db $03
    db $00
    db $04
    db $FF
    db $05
    db $00
    db $30
    db $06
    db $02
    db $FF
    db $6E
    db $00
    db $3C
    db $FF
    db $30
    db $06
    db $FF
    db $FF
    db $9B
    db $02
    db $FF
    db $FF
    db $4A
    db $FF
    db $01
    db $00
    db $01
    db $FF
    db $A8
    db $00
    db $DC
    db $7B
    db $01
    db $FF
    db $A7
    db $00
    db $D4
    db $7B
    db $01
    db $FF
    db $A6
    db $00
    db $B6
    db $7B
    db $01
    db $FF
    db $37
    db $00
    db $94
    db $7B
    db $01
    db $FF
    db $88
    db $00
    db $90
    db $7B
    db $01
    db $FF
    db $87
    db $00
    db $88
    db $7B
    db $01
    db $FF
    db $86
    db $00
    db $6A
    db $7B
    db $3C
    db $FF
    db $1F
    db $03
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $66
    db $7B
    db $21
    db $03
    db $03
    db $FF
    db $86
    db $00
    db $03
    db $FF
    db $87
    db $00
    db $42
    db $FF
    db $37
    db $01
    db $03
    db $00
    db $04
    db $FF
    db $05
    db $00
    db $50
    db $06
    db $02
    db $FF
    db $87
    db $00
    db $3C
    db $FF
    db $50
    db $06
    db $FF
    db $FF
    db $20
    db $03
    db $FF
    db $FF
    db $3C
    db $FF
    db $4D
    db $08
    db $03
    db $FF
    db $87
    db $00
    db $42
    db $FF
    db $37
    db $01
    db $03
    db $00
    db $04
    db $FF
    db $05
    db $00
    db $50
    db $06
    db $02
    db $FF
    db $87
    db $00
    db $3C
    db $FF
    db $50
    db $06
    db $FF
    db $FF
    db $2C
    db $03
    db $03
    db $FF
    db $88
    db $00
    db $FF
    db $FF
    db $2D
    db $03
    db $FF
    db $FF
    db $3C
    db $FF
    db $66
    db $04
    db $03
    db $FF
    db $A6
    db $00
    db $03
    db $FF
    db $A7
    db $00
    db $42
    db $FF
    db $3B
    db $01
    db $03
    db $00
    db $04
    db $FF
    db $05
    db $00
    db $50
    db $06
    db $02
    db $FF
    db $A7
    db $00
    db $3C
    db $FF
    db $50
    db $06
    db $FF
    db $FF
    db $3C
    db $FF
    db $56
    db $08
    db $03
    db $FF
    db $A7
    db $00
    db $42
    db $FF
    db $3B
    db $01
    db $03
    db $00
    db $04
    db $FF
    db $05
    db $00
    db $50
    db $06
    db $02
    db $FF
    db $A7
    db $00
    db $3C
    db $FF
    db $50
    db $06
    db $FF
    db $FF
    db $68
    db $04
    db $03
    db $FF
    db $A8
    db $00
    db $FF
    db $FF
    db $69
    db $04
    db $FF
    db $FF
    db $4A
    db $FF
    db $01
    db $00
    db $01
    db $FF
    db $55
    db $01
    db $3A
    db $7C
    db $01
    db $FF
    db $0F
    db $01
    db $36
    db $7C
    db $01
    db $FF
    db $0E
    db $01
    db $18
    db $7C
    db $3C
    db $FF
    db $27
    db $08
    db $03
    db $FF
    db $0E
    db $01
    db $03
    db $FF
    db $0F
    db $01
    db $42
    db $FF
    db $3C
    db $01
    db $03
    db $00
    db $04
    db $FF
    db $05
    db $00
    db $60
    db $06
    db $02
    db $FF
    db $0F
    db $01
    db $3C
    db $FF
    db $60
    db $06
    db $FF
    db $FF
    db $3C
    db $FF
    db $28
    db $08
    db $03
    db $FF
    db $0F
    db $01
    db $42
    db $FF
    db $3C
    db $01
    db $03
    db $00
    db $04
    db $FF
    db $05
    db $00
    db $60
    db $06
    db $02
    db $FF
    db $0F
    db $01
    db $3C
    db $FF
    db $60
    db $06
    db $FF
    db $FF
    db $29
    db $08
    db $FF
    db $FF
    db $C4
    db $08
    db $FF
    db $FF
    db $40
    db $7C
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
