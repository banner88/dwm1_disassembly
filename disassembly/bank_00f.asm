; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $00f", ROMX[$4000], BANK[$f]

    db $0f ;ROM BANK

    dw LoadScriptRoomData
    dw labelf_402f
    dw labelf_4110

; ---------------------------------------------------------------------------
; ScriptDataLookup — Same triple-index as bank $0C (see bank_00c.asm)
; $D8D3 (map_type) → $41BA → per-map table
; $D8D4 (script_id) → per-NPC data pointer
; $D8D5/$D8D6 (counter) → BC command pair
; ---------------------------------------------------------------------------
LoadScriptRoomData:
    ld a, [wScriptMapType]
    ld l, a
    ld h, $00
    add hl, hl
    ld de, Bank0F_ScriptMasterTable
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

labelf_402f:
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
    call LoadScriptRoomData
    push bc
    call LoadBf_40e7
    pop bc

LoadBf_4075:
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
    jr z, jr_00f_40a0

    ld b, a

jr_00f_409a:
    call LoadBf_40da
    dec b
    jr nz, jr_00f_409a

jr_00f_40a0:
    ld a, l
    ld [$d8e7], a
    ld a, h
    ld [$d8e8], a
    pop bc

jr_00f_40a9:
    ld a, [bc]
    inc bc
    cp $d9
    ret z

    cp $d8
    jr nz, jr_00f_40d2

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
    jr jr_00f_40a9

jr_00f_40d2:
    call Write_gfx_tile
    call LoadBf_40da
    jr jr_00f_40a9

LoadBf_40da:
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


LoadBf_40e7:
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

jr_00f_40f5:
    push hl

jr_00f_40f6:
    ld a, [bc]
    inc bc
    cp $d9
    jr z, jr_00f_410e

    cp $d8
    jr nz, jr_00f_410b

    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00f_40f5

jr_00f_410b:
    ld [hl+], a
    jr jr_00f_40f6

jr_00f_410e:
    pop hl
    ret

labelf_4110:
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
    call LoadScriptRoomData
    push bc
    call LoadBf_4171
    pop bc
    ld a, [wIsGBC]
    or a
    ret z

    di
    call WaitVRAM
    ld a, $01
    ldh [rVBK], a
    ei
    call LoadBf_4075
    di
    call WaitVRAM
    ld a, $00
    ldh [rVBK], a
    ei
    ret


LoadBf_4171:
    ld a, [bc]
    ld l, a
    inc bc
    ld a, [bc]
    ld h, a
    inc bc

jr_00f_4177:
    push hl

jr_00f_4178:
    ld a, [bc]
    inc bc
    cp $d9
    jr z, jr_00f_4193

    cp $d8
    jr nz, jr_00f_418d

    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00f_4177

jr_00f_418d:
    call SaveBf_4195
    inc hl
    jr jr_00f_4178

jr_00f_4193:
    pop hl
    ret


SaveBf_4195:
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
    jr c, jr_00f_41b0

    swap a
    and $f0
    ld d, a
    ld a, [hl]
    and $0f
    jr jr_00f_41b6

jr_00f_41b0:
    and $0f
    ld d, a
    ld a, [hl]
    and $f0

jr_00f_41b6:
    or d
    ld [hl], a
    pop hl
    ret


; ===========================================================================
; Script Data — Bank $0F
; 103 scripts across 32 maps, 273 labels
; ===========================================================================

; ---------------------------------------------------------------------------
; Bank0F_ScriptMasterTable
; ---------------------------------------------------------------------------
Bank0F_ScriptMasterTable:
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    dw Map5F_ScriptPtrTable            ; -> branch target
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $70
    db $6F
    db $9C
    db $42
    db $1A
    db $43
    db $4E
    db $45
    db $CE
    db $46
    db $EE
    db $47
    db $46
    db $4B
    db $48
    db $50
    db $38
    db $51
    db $D6
    db $52
    db $AE
    db $53
    db $86
    db $54
    db $7C
    db $55
    db $60
    db $56
    db $50
    db $57
    db $46
    db $58
    db $12
    db $59
    db $2C
    db $59
    db $3E
    db $59
    db $BC
    db $59
    db $6C
    db $5A
    db $6E
    db $5A
    db $6E
    db $5A
    db $6E
    db $5A
    db $7C
    db $5A
    db $7C
    db $5A
    db $7C
    db $5A
    db $7E
    db $5A
    db $B6
    db $5C
    db $EE
    db $5E
    db $E2
    db $61
    db $94
    db $6B
    db $70
    db $6F
    db $4E
    db $45
    db $6C
    db $5A
    db $6C
    db $5A
    db $6C
    db $5A
    db $6C
    db $5A
    db $4E
    db $45
    db $4E
    db $45
    db $4E
    db $45
    db $4E
    db $45
    db $4E
    db $45
    db $4E
    db $45
    db $4E
    db $45
    db $4E
    db $45
    db $4E
    db $45
    db $4E
    db $45
    db $4E
    db $45
    db $34
    db $6C
; ---------------------------------------------------------------------------
; Map40 Per-Script Table (map_type=$40, 9 scripts)
; ---------------------------------------------------------------------------
Map40_ScriptPtrTable:
    dw Map40_Script00                  ; script 0
    dw Map40_Script01                  ; script 1
    dw Map40_Script02                  ; script 2
    dw Map40_Script03                  ; script 3
    dw Map40_Script04                  ; script 4
    dw Map40_Script05                  ; script 5
    dw Map40_Script06                  ; script 6
    dw Map40_Script07                  ; script 7
    dw Map40_Script08                  ; script 8
; ---------------------------------------------------------------------------
; Map40_Script00
; ---------------------------------------------------------------------------
Map40_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map40_Script01
; ---------------------------------------------------------------------------
Map40_Script01:
    dw $054E  ; Text $054E: "$49:$518E [HERO] read the posting. // :Once you go"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map40_Script02
; ---------------------------------------------------------------------------
Map40_Script02:
    dw $054F  ; Text $054F: "$49:$520B [HERO] read the posting. // :Wanted! Hap"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map40_Script03
; ---------------------------------------------------------------------------
Map40_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $0021  ; Text $0021: "$42:$4D91 King:Oh [HERO]! Will you comply // with "
    dw Bank0F_ScriptAddr_42D0          ; -> branch target
    dw $0550  ; Text $0550: "$49:$5251 *:Hi! We go sip. Sip here!"
    dw $FFFF  ; END

Bank0F_ScriptAddr_42D0:
    dw $0553  ; Text $0553: "$49:$52DB *:You're really too much. But // there's"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map40_Script04
; ---------------------------------------------------------------------------
Map40_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $0021  ; Text $0021: "$42:$4D91 King:Oh [HERO]! Will you comply // with "
    dw Bank0F_ScriptAddr_42DE          ; -> branch target
    dw $0551  ; Text $0551: "$49:$526F *:Boss! You can feel like a king // with"
    dw $FFFF  ; END

Bank0F_ScriptAddr_42DE:
    dw $0554  ; Text $0554: "$49:$5313 *:Boss! You are so strong! // But there'"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map40_Script05
; ---------------------------------------------------------------------------
Map40_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $0021  ; Text $0021: "$42:$4D91 King:Oh [HERO]! Will you comply // with "
    dw Bank0F_ScriptAddr_42EC          ; -> branch target
    dw $0552  ; Text $0552: "$49:$52AB *:Please let the sweet aroma relax // yo"
    dw $FFFF  ; END

Bank0F_ScriptAddr_42EC:
    dw $0555  ; Text $0555: "$49:$534D *:I see you have lots of special // skil"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map40_Script06
; ---------------------------------------------------------------------------
Map40_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $0021  ; Text $0021: "$42:$4D91 King:Oh [HERO]! Will you comply // with "
    dw Bank0F_ScriptAddr_42FC          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D987  ; RAM $D987
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
Bank0F_ScriptAddr_42FC:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map40_Script07
; ---------------------------------------------------------------------------
Map40_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $0021  ; Text $0021: "$42:$4D91 King:Oh [HERO]! Will you comply // with "
    dw Bank0F_ScriptAddr_430A          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D987  ; RAM $D987
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
Bank0F_ScriptAddr_430A:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map40_Script08
; ---------------------------------------------------------------------------
Map40_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $0021  ; Text $0021: "$42:$4D91 King:Oh [HERO]! Will you comply // with "
    dw Bank0F_ScriptAddr_4318          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D987  ; RAM $D987
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
Bank0F_ScriptAddr_4318:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map41 Per-Script Table (map_type=$41, 4 scripts)
; ---------------------------------------------------------------------------
Map41_ScriptPtrTable:
    dw Map41_Script00                  ; script 0
    dw Map41_Script01                  ; script 1
    dw Map41_Script02                  ; script 2
    dw Map41_Script03                  ; script 3
; ---------------------------------------------------------------------------
; Map41_Script00
; ---------------------------------------------------------------------------
Map41_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map41_Script01
; ---------------------------------------------------------------------------
Map41_Script01:
    dw $0556  ; Text $0556: "$49:$5397 *:Mmm... sip sip! Here I come!"
    dw $FF5A  ; Cmd5A
    dw $009C  ; Text $009C: "$1A:$4BDA *:Don't be afraid of monsters you // hav"
    dw $FF07  ; InitDialogMode
    dw $0557  ; Text $0557: "$49:$53B9 *:Wow! You really impressed me!"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0208  ; Text $0208: "$1B:$4555 *:We disobey when we get an unwanted // "
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF3C  ; Cmd3C
    dw $FF07  ; InitDialogMode
    dw $055E  ; Text $055E: "$49:$5526 Watabou:Had a good time!? We got // to g"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0041  ; Text $0041: "$42:$61BD Slio:You can drop off up to 19 // monste"
    dw $FF03  ; SetEventFlag
    dw $0021  ; Text $0021: "$42:$4D91 King:Oh [HERO]! Will you comply // with "
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D95E  ; RAM $D95E
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D987  ; RAM $D987
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF00  ; BranchIfFlagClear
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw Bank0F_ScriptAddr_43DA          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D95E  ; RAM $D95E
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
Bank0F_ScriptAddr_43DA:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map41_Script02
; ---------------------------------------------------------------------------
Map41_Script02:
    dw $0559  ; Text $0559: "$49:$5415 *:Now, sleep tight on my arms...!"
    dw $FF5A  ; Cmd5A
    dw $0099
    dw $FF07  ; InitDialogMode
    dw $055A  ; Text $055A: "$49:$543A *:Oh, you were great. Giggle..."
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0105  ; Text $0105: "$43:$4FE2 *:Its the principal of the // school."
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF3C  ; Cmd3C
    dw $FF07  ; InitDialogMode
    dw $055B  ; Text $055B: "$49:$545D Watabou:Had a good time!? We got // to g"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0041  ; Text $0041: "$42:$61BD Slio:You can drop off up to 19 // monste"
    dw $FF03  ; SetEventFlag
    dw $0021  ; Text $0021: "$42:$4D91 King:Oh [HERO]! Will you comply // with "
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D95E  ; RAM $D95E
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D987  ; RAM $D987
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF00  ; BranchIfFlagClear
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw Bank0F_ScriptAddr_448E          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D95E  ; RAM $D95E
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
Bank0F_ScriptAddr_448E:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map41_Script03
; ---------------------------------------------------------------------------
Map41_Script03:
    dw $055C  ; Text $055C: "$49:$5494 *:I'll let you sleep with my // SleepAir"
    dw $FF5A  ; Cmd5A
    dw $009B
    dw $FF07  ; InitDialogMode
    dw $055D  ; Text $055D: "$49:$54DA *:You're strong! If this is a // dream, "
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0302  ; Text $0302: "$46:$41F5 *:Then you must be a master who's // com"
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF3C  ; Cmd3C
    dw $FF07  ; InitDialogMode
    dw $0558  ; Text $0558: "$49:$53DC Watabou:Had a good time!? We've // got t"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0041  ; Text $0041: "$42:$61BD Slio:You can drop off up to 19 // monste"
    dw $FF03  ; SetEventFlag
    dw $0021  ; Text $0021: "$42:$4D91 King:Oh [HERO]! Will you comply // with "
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D95E  ; RAM $D95E
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D987  ; RAM $D987
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF00  ; BranchIfFlagClear
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw Bank0F_ScriptAddr_4542          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D95E  ; RAM $D95E
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
Bank0F_ScriptAddr_4542:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42 Per-Script Table (map_type=$42, 19 scripts)
; ---------------------------------------------------------------------------
Map42_ScriptPtrTable:
    dw Map42_Script00                  ; script 0
    dw Map42_Script01                  ; script 1
    dw Map42_Script02                  ; script 2
    dw Map42_Script03                  ; script 3
    dw Map42_Script04                  ; script 4
    dw Map42_Script05                  ; script 5
    dw Map42_Script06                  ; script 6
    dw Map42_Script07                  ; script 7
    dw Map42_Script08                  ; script 8
    dw Map42_Script09                  ; script 9
    dw Map42_Script10                  ; script 10
    dw Map42_Script10                  ; script 11
    dw Map42_Script10                  ; script 12
    dw Map42_Script10                  ; script 13
    dw Map42_Script10                  ; script 14
    dw Map42_Script10                  ; script 15
    dw Map42_Script16                  ; script 16
    dw Map42_Script17                  ; script 17
    dw Map42_Script18                  ; script 18
; ---------------------------------------------------------------------------
; Map42_Script00
; ---------------------------------------------------------------------------
Map42_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script01
; ---------------------------------------------------------------------------
Map42_Script01:
    dw $FF12  ; WriteRAM
    dw $D9E9  ; RAM $D9E9
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script02
; ---------------------------------------------------------------------------
Map42_Script02:
    dw $FF12  ; WriteRAM
    dw $D9E9  ; RAM $D9E9
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script03
; ---------------------------------------------------------------------------
Map42_Script03:
    dw $FF12  ; WriteRAM
    dw $D9E9  ; RAM $D9E9
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script04
; ---------------------------------------------------------------------------
Map42_Script04:
    dw $FF12  ; WriteRAM
    dw $D9E9  ; RAM $D9E9
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script05
; ---------------------------------------------------------------------------
Map42_Script05:
    dw $FF12  ; WriteRAM
    dw $D9E9  ; RAM $D9E9
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script06
; ---------------------------------------------------------------------------
Map42_Script06:
    dw $FF12  ; WriteRAM
    dw $D9E9  ; RAM $D9E9
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script07
; ---------------------------------------------------------------------------
Map42_Script07:
    dw $FF12  ; WriteRAM
    dw $D9E9  ; RAM $D9E9
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script08
; ---------------------------------------------------------------------------
Map42_Script08:
    dw $FF12  ; WriteRAM
    dw $D9E9  ; RAM $D9E9
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script09
; ---------------------------------------------------------------------------
Map42_Script09:
    dw $FF12  ; WriteRAM
    dw $D9E9  ; RAM $D9E9
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script10
; ---------------------------------------------------------------------------
Map42_Script10:
    dw $FF12  ; WriteRAM
    dw $D9E9  ; RAM $D9E9
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script16
; ---------------------------------------------------------------------------
Map42_Script16:
    dw $FF01  ; BranchIfFlagSet
    dw $00D5  ; Text $00D5: "$1A:$5A84 *:Well,in a way, fighting becomes // fig"
    dw Bank0F_ScriptAddr_45E2          ; -> branch target
    dw $0561  ; Text $0561: "$49:$558D [HERO] checked out a treasure chest. // "
    dw $FF03  ; SetEventFlag
    dw $00D5  ; Text $00D5: "$1A:$5A84 *:Well,in a way, fighting becomes // fig"
    dw $FFFF  ; END

Bank0F_ScriptAddr_45E2:
    dw $0562  ; Text $0562: "$49:$560A Mimic continues to stick his // tongue o"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script17
; ---------------------------------------------------------------------------
Map42_Script17:
    dw $FF01  ; BranchIfFlagSet
    dw $00D6  ; Text $00D6: "$1A:$5B06 *:I would like to be with someone // wit"
    dw Bank0F_ScriptAddr_46A2          ; -> branch target
    dw $0563  ; Text $0563: "$49:$563A *:Bleat bleat. I cannot believe // that "
    dw $FF03  ; SetEventFlag
    dw $00D6  ; Text $00D6: "$1A:$5B06 *:I would like to be with someone // wit"
    dw $FF5A  ; Cmd5A
    dw $00AF  ; Text $00AF: "$1A:$5162 *:Breathe in breathe out, // breathe in "
    dw $FF07  ; InitDialogMode
    dw $0565  ; Text $0565: "$49:$56FF *:Bleat bleat. I never imagined // such "
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0406  ; Text $0406: "$21:$4411 *:My StoneMan can use Ahhh! // *:Boy mon"
    dw $FF1C  ; CompareRAM
    dw $1602
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0566  ; Text $0566: "$49:$5744 Watabou:You think the doll // looks just"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0042  ; Text $0042: "$42:$6437 Slio:Raise the monster to be // powerful"
    dw $FF03  ; SetEventFlag
    dw $0022  ; Text $0022: "$42:$517B *:Everybody will be happy if you // beco"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D96F  ; RAM $D96F
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D989  ; RAM $D989
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0023  ; Text $0023: "$42:$51DB *:I have a feeling that your // victory "
    dw Bank0F_ScriptAddr_4696          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D96F  ; RAM $D96F
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
Bank0F_ScriptAddr_4696:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0F_ScriptAddr_46A2:
    dw $0564  ; Text $0564: "$49:$56CA *:Bleat bleat. Welcome to a // dead end,"
    dw $FF14  ; ClearGameFlags
    dw $45F2
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map42_Script18
; ---------------------------------------------------------------------------
Map42_Script18:
    dw $FF01  ; BranchIfFlagSet
    dw $00D4
    dw Bank0F_ScriptAddr_46C8          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $011B  ; Text $011B: "$43:$5AF2 *:Who the heck is that old woman at // t"
    dw Bank0F_ScriptAddr_46BE          ; -> branch target
    dw $0842
    dw $FF03  ; SetEventFlag
    dw $011B  ; Text $011B: "$43:$5AF2 *:Who the heck is that old woman at // t"
    dw $FFFF  ; END

Bank0F_ScriptAddr_46BE:
    dw $0842
    dw $055F  ; Text $055F: "$49:$555D Watabou didn't reply."
    dw $FF03  ; SetEventFlag
    dw $00D4
    dw $FFFF  ; END

Bank0F_ScriptAddr_46C8:
    dw $0842
    dw $0560  ; Text $0560: "$49:$5574 It was a Watabou doll!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map43 Per-Script Table (map_type=$43, 3 scripts)
; ---------------------------------------------------------------------------
Map43_ScriptPtrTable:
    dw Map43_Script00                  ; script 0
    dw Map43_Script01                  ; script 1
    dw Map43_Script02                  ; script 2
; ---------------------------------------------------------------------------
; Map43_Script00
; ---------------------------------------------------------------------------
Map43_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map43_Script01
; ---------------------------------------------------------------------------
Map43_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00D7  ; Text $00D7: "$1A:$5B3E *:Hee Hee Hee! Work! Stupid!"
    dw Bank0F_ScriptAddr_46EE          ; -> branch target
    dw $0571  ; Text $0571: "$49:$5BD8 [HERO] touched the blade of the // guill"
    dw $FFFF  ; END

Bank0F_ScriptAddr_46EE:
    dw $0572  ; Text $0572: "$49:$5C2A [HERO] touched the blade of the // guill"
    dw $FF03  ; SetEventFlag
    dw $00D8
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map43_Script02
; ---------------------------------------------------------------------------
Map43_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $00D8
    dw Bank0F_ScriptAddr_472E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00D7  ; Text $00D7: "$1A:$5B3E *:Hee Hee Hee! Work! Stupid!"
    dw Bank0F_ScriptAddr_4726          ; -> branch target
    dw $0567  ; Text $0567: "$49:$57BA *:You abused monsters cruelly // and wip"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_4714          ; -> branch target
    dw $0568  ; Text $0568: "$49:$584E *:If you cannot learn by // listening to"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_473E          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_4714:
    dw $0569  ; Text $0569: "$49:$58B0 *:You recognize your sin, right? // Now "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_4726          ; -> branch target
    dw $056A  ; Text $056A: "$49:$59C8 *:If you cannot learn by // listening to"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_473E          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_4726:
    dw $056B  ; Text $056B: "$49:$5A2A *:Now we're holding a public // executio"
    dw $FF03  ; SetEventFlag
    dw $00D7  ; Text $00D7: "$1A:$5B3E *:Hee Hee Hee! Work! Stupid!"
    dw $FFFF  ; END

Bank0F_ScriptAddr_472E:
    dw $056C  ; Text $056C: "$49:$5A8B *:What? You have something to say // bef"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $473C
    dw $056E  ; Text $056E: "$49:$5B3C *:Then die!"
    dw $FFFF  ; END

    db $6D
    db $05
Bank0F_ScriptAddr_473E:
    dw $FF5A  ; Cmd5A
    dw $00B1
    dw $FF07  ; InitDialogMode
    dw $056F  ; Text $056F: "$49:$5B4C *:You want to have additional sins?"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0302  ; Text $0302: "$46:$41F5 *:Then you must be a master who's // com"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0570  ; Text $0570: "$49:$5B73 Watabou:[HERO]'s monsters trust // you, "
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0043  ; Text $0043: "$42:$6466 Slio:Dn'a wanna know about the // farm? "
    dw $FF03  ; SetEventFlag
    dw $0023  ; Text $0023: "$42:$51DB *:I have a feeling that your // victory "
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D96F  ; RAM $D96F
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D98A  ; RAM $D98A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0022  ; Text $0022: "$42:$517B *:Everybody will be happy if you // beco"
    dw $47E2
    dw $FF12  ; WriteRAM
    dw $D96F  ; RAM $D96F
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map44 Per-Script Table (map_type=$44, 3 scripts)
; ---------------------------------------------------------------------------
Map44_ScriptPtrTable:
    dw Map44_Script00                  ; script 0
    dw Map44_Script01                  ; script 1
    dw Map44_Script02                  ; script 2
; ---------------------------------------------------------------------------
; Map44_Script00
; ---------------------------------------------------------------------------
Map44_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map44_Script01
; ---------------------------------------------------------------------------
Map44_Script01:
    dw $0573  ; Text $0573: "$49:$5CAA *:Aaaarrrggh! Gwrrrr... // *:Gwrrggg..."
    dw $FF5A  ; Cmd5A
    dw $00B3
    dw $FF01  ; BranchIfFlagSet
    dw $00AA  ; Text $00AA: "$1A:$5071 *:If you behave naturally. // You win na"
    dw Bank0F_ScriptAddr_4B24          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $0576  ; Text $0576: "$49:$5D00 *:Aaarrrggh... // *:I can't stand it. I "
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0103  ; Text $0103: "$43:$4F3C *:Hi Ho Hi Ho. // *:Sigh.. I'm starving."
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF1C  ; CompareRAM
    dw $0103  ; Text $0103: "$43:$4F3C *:Hi Ho Hi Ho. // *:Sigh.. I'm starving."
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1C  ; CompareRAM
    dw $0103  ; Text $0103: "$43:$4F3C *:Hi Ho Hi Ho. // *:Sigh.. I'm starving."
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF1C  ; CompareRAM
    dw $0103  ; Text $0103: "$43:$4F3C *:Hi Ho Hi Ho. // *:Sigh.. I'm starving."
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1C  ; CompareRAM
    dw $0103  ; Text $0103: "$43:$4F3C *:Hi Ho Hi Ho. // *:Sigh.. I'm starving."
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1C  ; CompareRAM
    dw $0403  ; Text $0403: "$21:$42E8 *:I'll send my StoneMan to the // farm t"
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $006E  ; Text $006E: "$42:$7C00 Splash! Poop hit [HERO]."
    dw $FF13  ; SetGameFlags
    dw $C8B1  ; RAM $C8B1
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FFE0  ; Cmd$E0
    dw $FF1B  ; MultiRAMWrite
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF49  ; Cmd49
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF48  ; Cmd48
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF10  ; NPCAnimStart
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1D  ; LockMovement
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF1C  ; CompareRAM
    dw $0501  ; Text $0501: "$1F:$71CB *:Squawk! Squawk!"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFE8  ; Cmd$E8
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1D  ; LockMovement
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF4  ; Cmd$F4
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF4  ; Cmd$F4
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF4  ; Cmd$F4
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF4  ; Cmd$F4
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $006E  ; Text $006E: "$42:$7C00 Splash! Poop hit [HERO]."
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFE0  ; Cmd$E0
    dw $FF21  ; TriggerBattle2
    dw $0068  ; Text $0068: "$42:$78FC *:Monsters have personalities too. // *:"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1C  ; CompareRAM
    dw $0D03
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFE0  ; Cmd$E0
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0D  ; WriteNPCByte
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
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
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF07  ; InitDialogMode
    dw $0577  ; Text $0577: "$49:$5D6C *:Look... this sword... // *:It's the Ku"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0F_ScriptAddr_4A60          ; -> branch target
    dw $0578  ; Text $0578: "$49:$5EE8 *:So long! The Orochi won't // trouble y"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_4A62          ; -> branch target
Bank0F_ScriptAddr_4A60:
    dw $0579  ; Text $0579: "$49:$5F58 *:What? You want to know why I am // loo"
Bank0F_ScriptAddr_4A62:
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1C  ; CompareRAM
    dw $1901
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "$46:$4292 *:Eeek! I cannot stand you! // *:I'm gon"
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF01  ; BranchIfFlagSet
    dw $00AA  ; Text $00AA: "$1A:$5071 *:If you behave naturally. // You win na"
    dw Bank0F_ScriptAddr_4AD0          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $057A  ; Text $057A: "$49:$6176 Watabou:Oh, you were saved by // somebod"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_4AD4          ; -> branch target
Bank0F_ScriptAddr_4AD0:
    dw $FF07  ; InitDialogMode
    dw $0575  ; Text $0575: "$49:$5CE9 Watabou:[HERO]! Let's go."
Bank0F_ScriptAddr_4AD4:
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF03  ; SetEventFlag
    dw $0024  ; Text $0024: "$42:$522C [HERO] looked at the bookshelf. // :The "
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0044  ; Text $0044: "$42:$6492 *:You are at the monster farm."
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D95D  ; RAM $D95D
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D98B  ; RAM $D98B
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0F_ScriptAddr_4B24:
    dw $FF07  ; InitDialogMode
    dw $0574  ; Text $0574: "$49:$5CD7 *:Gwwrrggg..."
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0203  ; Text $0203: "$1B:$4417 *:The Room of Peace & Bravery // is open"
    dw $FF14  ; ClearGameFlags
    dw $4A94
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map44_Script02
; ---------------------------------------------------------------------------
Map44_Script02:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map45 Per-Script Table (map_type=$45, 2 scripts)
; ---------------------------------------------------------------------------
Map45_ScriptPtrTable:
    dw Map45_Script00                  ; script 0
    dw Map45_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map45_Script00
; ---------------------------------------------------------------------------
Map45_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF15  ; PlaySE
    dw $D98C  ; RAM $D98C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_4B6A          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D98C  ; RAM $D98C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0F_ScriptAddr_503C          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D98C  ; RAM $D98C
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0F_ScriptAddr_4B6A          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_4B6A:
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF08  ; NOP
    dw $FF01  ; BranchIfFlagSet
    dw $00AB
    dw $5016
    dw $FF01  ; BranchIfFlagSet
    dw $00AA  ; Text $00AA: "$1A:$5071 *:If you behave naturally. // You win na"
    dw $4F6E
    dw $FF01  ; BranchIfFlagSet
    dw $00A9  ; Text $00A9: "$1A:$5052 *:Moderation in all things!"
    dw $4C04
    dw $FF07  ; InitDialogMode
    dw $046D  ; Text $046D: "$21:$7709 *:How do you do? I am the // guardian he"
    dw $FF03  ; SetEventFlag
    dw $00A9  ; Text $00A9: "$1A:$5052 *:Moderation in all things!"
    dw $FF06  ; IncrementCounter
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF4D  ; SetLongDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF07  ; InitDialogMode
    dw $046E  ; Text $046E: "$21:$7849 Durran:Here, fight to your // heart's co"
    dw $FF14  ; ClearGameFlags
    dw $4C7A
    dw $FF07  ; InitDialogMode
    dw $046F  ; Text $046F: "$21:$787C Durran:Hmm. You came back again. // Figh"
    dw $FF06  ; IncrementCounter
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF4D  ; SetLongDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF07  ; InitDialogMode
    dw $0470  ; Text $0470: "$21:$78E1 Durran:Here, fight to your // heart's co"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF13  ; SetGameFlags
    dw $DA03  ; RAM $DA03
    dw $0156  ; Text $0156: "$43:$700D *:The stone guard fell asleep from // th"
    dw $FF13  ; SetGameFlags
    dw $DA05  ; RAM $DA05
    dw $0156  ; Text $0156: "$43:$700D *:The stone guard fell asleep from // th"
    dw $FF12  ; WriteRAM
    dw $DA02  ; RAM $DA02
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF20  ; Cmd20
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF07  ; InitDialogMode
    dw $0471  ; Text $0471: "$21:$7914 Durran:Ha ha ha! You defeated // them ea"
    dw $FF1C  ; CompareRAM
    dw $0804  ; Text $0804: "$3F:$4771 *:Oh my! So, this is // the GoldSlime! /"
    dw $FF19  ; FadeEffect
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF4D  ; SetLongDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF21  ; TriggerBattle2
    dw $006C  ; Text $006C: "$42:$7AAF [HERO] took the egg of a // SkyDragon! /"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0472
    dw $FF03  ; SetEventFlag
    dw $00AA  ; Text $00AA: "$1A:$5071 *:If you behave naturally. // You win na"
    dw $FF06  ; IncrementCounter
    dw $FF05  ; TriggerBattle
    dw $0157  ; Text $0157: "$43:$7097 *:Who do you think you are! What? // You"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF1C  ; CompareRAM
    dw $0D04
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0038  ; Text $0038: "$42:$5E08 *:I heard that Pulio let the // monsters"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $001A  ; Text $001A: "$42:$4C3F *:I see....."
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF47  ; Cmd47
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF08  ; NOP
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF1C  ; CompareRAM
    dw $0804  ; Text $0804: "$3F:$4771 *:Oh my! So, this is // the GoldSlime! /"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF07  ; InitDialogMode
    dw $0475  ; Text $0475: "$48:$41D2 Durran:Ha ha ha! How easily you // defea"
    dw $FF1C  ; CompareRAM
    dw $0E07
    dw $FF19  ; FadeEffect
    dw $FF1C  ; CompareRAM
    dw $0E07
    dw $FF19  ; FadeEffect
    dw $FF1C  ; CompareRAM
    dw $0E07
    dw $FF19  ; FadeEffect
    dw $FF3C  ; Cmd3C
    dw $FF07  ; InitDialogMode
    dw $0476  ; Text $0476: "$48:$4294 Durran:Want a real thrill? // Fight me! "
    dw $FF03  ; SetEventFlag
    dw $00AB
    dw $FF12  ; WriteRAM
    dw $D98C  ; RAM $D98C
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1C  ; CompareRAM
    dw $1107
    dw $FF19  ; FadeEffect
    dw $FF05  ; TriggerBattle
    dw $00C7  ; Text $00C7: "$1A:$570A *:Careless monster is my middle name."
    dw $FF0B  ; NPCMoveY
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FFF0  ; Cmd$F0
    dw $FF07  ; InitDialogMode
    dw $0479  ; Text $0479: "$48:$4375 Durran:Did I lose? .. I lost... // Durra"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FFA9  ; Cmd$A9
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF48  ; Cmd48
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0B  ; NPCMoveY
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0A  ; NPCMoveX
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0B  ; NPCMoveY
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF07  ; InitDialogMode
    dw $047A  ; Text $047A: "$48:$44B1 TERRY?:..You're strong... // You even de"
    dw $047B  ; Text $047B: "$48:$45FC Do you really want to tell your // true "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4E22
    dw $047D  ; Text $047D: "$48:$4655 TERRY?:No. It's okay... I know..."
    dw $FF14  ; ClearGameFlags
    dw $4E24
    dw $047C  ; Text $047C: "$48:$4636 TERRY?:It's okay. I know..."
    dw $FF1D  ; LockMovement
    dw $FF1C  ; CompareRAM
    dw $0E04
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF07  ; InitDialogMode
    dw $047F  ; Text $047F: "$48:$469A TERRY?:Ahhh... For some reason, // I fee"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0480  ; Text $0480: "$48:$477F TERRY?:[HERO], don't become // like me. "
    dw $FF1D  ; LockMovement
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFC0  ; Cmd$C0
    dw $FF1B  ; MultiRAMWrite
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FFC0  ; Cmd$C0
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF3C  ; Cmd3C
    dw $FF07  ; InitDialogMode
    dw $0481  ; Text $0481: "$48:$485F TERRY?:Farewell [HERO]! // I'm taking of"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $4E92
    dw $0482  ; Text $0482: "$48:$48B0 TERRY?:Take care of your sister. // No m"
    dw $FF14  ; ClearGameFlags
    dw $4E94
    dw $0483  ; Text $0483: "$48:$48EA TERRY?:...You don't want to // hear this"
    dw $FF1D  ; LockMovement
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFF9  ; Cmd$F9
    dw $FF1B  ; MultiRAMWrite
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FFF9  ; Cmd$F9
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFE0  ; Cmd$E0
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF09  ; SetDelay
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0405  ; Text $0405: "$21:$43D8 *:...fine. If you change your // mind, l"
    dw $FF1C  ; CompareRAM
    dw $1506
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF07  ; InitDialogMode
    dw $0484  ; Text $0484: "$48:$4962 Watabou:Let's go back!"
    dw $FF1C  ; CompareRAM
    dw $0406  ; Text $0406: "$21:$4411 *:My StoneMan can use Ahhh! // *:Boy mon"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF49  ; Cmd49
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0045  ; Text $0045: "$42:$64B4 King:Oh, this monster is the // former k"
    dw $FF03  ; SetEventFlag
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D963  ; RAM $D963
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D970  ; RAM $D970
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D98C  ; RAM $D98C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

    db $07
    db $FF
    db $73
    db $04
    db $1C
    db $FF
    db $04
    db $08
    db $19
    db $FF
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
    db $4D
    db $FF
    db $06
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
    db $4D
    db $FF
    db $02
    db $00
    db $21
    db $FF
    db $6C
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
    db $0D
    db $FF
    db $04
    db $00
    db $00
    db $00
    db $00
    db $00
    db $07
    db $FF
    db $74
    db $04
    db $06
    db $FF
    db $05
    db $FF
    db $57
    db $01
    db $14
    db $FF
    db $4A
    db $4D
    db $07
    db $FF
    db $77
    db $04
    db $1C
    db $FF
    db $07
    db $0E
    db $19
    db $FF
    db $1C
    db $FF
    db $07
    db $0E
    db $19
    db $FF
    db $1C
    db $FF
    db $07
    db $0E
    db $19
    db $FF
    db $3C
    db $FF
    db $07
    db $FF
    db $78
    db $04
    db $1C
    db $FF
    db $07
    db $11
    db $19
    db $FF
    db $14
    db $FF
    db $B8
    db $4D
Bank0F_ScriptAddr_503C:
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map45_Script01
; ---------------------------------------------------------------------------
Map45_Script01:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossAmbition Per-Script Table (map_type=$46, 2 scripts)
; ---------------------------------------------------------------------------
BossAmbition_ScriptPtrTable:
    dw BossAmbition_Script00           ; script 0
    dw BossAmbition_Script01           ; script 1
; ---------------------------------------------------------------------------
; BossAmbition_Script00
; ---------------------------------------------------------------------------
BossAmbition_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossAmbition_Script01
; ---------------------------------------------------------------------------
BossAmbition_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00D9  ; Text $00D9: "$1A:$5B8B *:I...if I support everybody,th...the //"
    dw Bank0F_ScriptAddr_5080          ; -> branch target
    dw $057B  ; Text $057B: "$49:$61C9 *:Welcome [HERO]! // *:I'm the King of K"
    dw $FF03  ; SetEventFlag
    dw $00D9  ; Text $00D9: "$1A:$5B8B *:I...if I support everybody,th...the //"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5086          ; -> branch target
    dw $057D  ; Text $057D: "$49:$63E6 DracoLord:What's wrong with it. // It is"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0F_ScriptAddr_5086          ; -> branch target
    dw $057E  ; Text $057E: "$49:$645F DracoLord:You say you're going to // bea"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_5088          ; -> branch target
Bank0F_ScriptAddr_5080:
    dw $057F  ; Text $057F: "$49:$64C2 DracoLord:You came back? // You never le"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_5088          ; -> branch target
Bank0F_ScriptAddr_5086:
    dw $057C  ; Text $057C: "$49:$62FE DracoLord:Great, you agreed! // Now I wi"
Bank0F_ScriptAddr_5088:
    dw $FF5A  ; Cmd5A
    dw $00C9  ; Text $00C9: "$1A:$5798 *:I guarantee a comfortable // environme"
    dw $FF07  ; InitDialogMode
    dw $0580  ; Text $0580: "$49:$6568 DracoLord:You beat me. You're really // "
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "$46:$4292 *:Eeek! I cannot stand you! // *:I'm gon"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0581  ; Text $0581: "$49:$659F Watabou:One down! [HERO]! // Let's go ba"
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0046  ; Text $0046: "$42:$65B6 Pulio:Your Majesty, please // forgive me"
    dw $FF03  ; SetEventFlag
    dw $0026  ; Text $0026: "$42:$53F1 [HERO] returned the book to the // books"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D971  ; RAM $D971
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D98D  ; RAM $D98D
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0028  ; Text $0028: "$42:$5474 :People who understand monster // talk a"
    dw Bank0F_ScriptAddr_512C          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D971  ; RAM $D971
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
Bank0F_ScriptAddr_512C:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map47 Per-Script Table (map_type=$47, 3 scripts)
; ---------------------------------------------------------------------------
Map47_ScriptPtrTable:
    dw Map47_Script00                  ; script 0
    dw Map47_Script01                  ; script 1
    dw Map47_Script02                  ; script 2
; ---------------------------------------------------------------------------
; Map47_Script00
; ---------------------------------------------------------------------------
Map47_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map47_Script01
; ---------------------------------------------------------------------------
Map47_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00DA  ; Text $00DA: "$1A:$5BE6 *:Ohhhh... I...I'm s...scared!"
    dw Bank0F_ScriptAddr_516A          ; -> branch target
    dw $0582  ; Text $0582: "$49:$65CB *:Who is it? // *:Disturbing my rest? //"
    dw $FF03  ; SetEventFlag
    dw $00DA  ; Text $00DA: "$1A:$5BE6 *:Ohhhh... I...I'm s...scared!"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5172          ; -> branch target
    dw $0584  ; Text $0584: "$49:$66A2 Hargon:Then you should know, // Hargon:I"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_5174          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_516A:
    dw $0585  ; Text $0585: "$49:$66FB Hargon:You again! // Hargon:Insolant foo"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_5174          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_5172:
    dw $0583  ; Text $0583: "$49:$6649 Hargon:Then it is unforgivable! // Hargo"
Bank0F_ScriptAddr_5174:
    dw $FF5A  ; Cmd5A
    dw $00CB  ; Text $00CB: "$1A:$5842 *:Don't mix me up with those guys // who"
    dw $FF07  ; InitDialogMode
    dw $0586  ; Text $0586: "$49:$677B Hargon:To my vex... // Hargon:the great "
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "$46:$4292 *:Eeek! I cannot stand you! // *:I'm gon"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0587  ; Text $0587: "$49:$687E Watabou:Hm? I still smell // monster... "
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0047  ; Text $0047: "$42:$65E5 King:Pulio, did Hale escape // as well?"
    dw $FF03  ; SetEventFlag
    dw $0027  ; Text $0027: "$42:$541E [HERO] looked at the bookshelf. // The M"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D98E  ; RAM $D98E
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map47_Script02
; ---------------------------------------------------------------------------
Map47_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $00DB  ; Text $00DB: "$1A:$5C07 *:Brrrr. Shiver... // *:I'm not scared I"
    dw Bank0F_ScriptAddr_5224          ; -> branch target
    dw $0588  ; Text $0588: "$49:$68E2 *:...I...am... the...god...of... // dest"
    dw $FF03  ; SetEventFlag
    dw $00DB  ; Text $00DB: "$1A:$5C07 *:Brrrr. Shiver... // *:I'm not scared I"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_5226          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_5224:
    dw $0589  ; Text $0589: "$49:$6961 Sidoh:...I... destroy...!!"
Bank0F_ScriptAddr_5226:
    dw $FF5A  ; Cmd5A
    dw $00CD  ; Text $00CD: "$1A:$58B8 *:Just sit back and wait for the // figh"
    dw $FF07  ; InitDialogMode
    dw $058A  ; Text $058A: "$49:$697F Sidoh:............"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "$46:$4292 *:Eeek! I cannot stand you! // *:I'm gon"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $058B  ; Text $058B: "$49:$6996 Watabou:There was a monster // still her"
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $00C7  ; Text $00C7: "$1A:$570A *:Careless monster is my middle name."
    dw $FF03  ; SetEventFlag
    dw $0028  ; Text $0028: "$42:$5474 :People who understand monster // talk a"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D971  ; RAM $D971
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D98E  ; RAM $D98E
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF00  ; BranchIfFlagClear
    dw $0026  ; Text $0026: "$42:$53F1 [HERO] returned the book to the // books"
    dw $52CA
    dw $FF12  ; WriteRAM
    dw $D971  ; RAM $D971
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map48 Per-Script Table (map_type=$48, 2 scripts)
; ---------------------------------------------------------------------------
Map48_ScriptPtrTable:
    dw Map48_Script00                  ; script 0
    dw Map48_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map48_Script00
; ---------------------------------------------------------------------------
Map48_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map48_Script01
; ---------------------------------------------------------------------------
Map48_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00DC  ; Text $00DC: "$1A:$5C58 *:Oh no! Shouldn't be!! Why... why am //"
    dw Bank0F_ScriptAddr_52FC          ; -> branch target
    dw $058C  ; Text $058C: "$49:$69E2 *:At last you came here, pathetic // thi"
    dw $FF03  ; SetEventFlag
    dw $00DC  ; Text $00DC: "$1A:$5C58 *:Oh no! Shouldn't be!! Why... why am //"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_52FE          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_52FC:
    dw $058D  ; Text $058D: "$49:$6B13 Baramos:Fool! You still disobey me! // B"
Bank0F_ScriptAddr_52FE:
    dw $FF5A  ; Cmd5A
    dw $00CF
    dw $FF07  ; InitDialogMode
    dw $058E  ; Text $058E: "$49:$6C07 Baramos:Arhg... y..you... // Baramos:How"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0104  ; Text $0104: "$43:$4FA8 *:Yo man, wanna know who your // match i"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $058F  ; Text $058F: "$49:$6C40 Watabou: Excellent [HERO]. // Leeet's go"
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FF03  ; SetEventFlag
    dw $0029  ; Text $0029: "$42:$55D7 *:I wanna be a master. // What should I "
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D972  ; RAM $D972
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D98F  ; RAM $D98F
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $002A  ; Text $002A: "$42:$5608 King:The monster farm is on the // upper"
    dw $53A2
    dw $FF12  ; WriteRAM
    dw $D972  ; RAM $D972
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map49 Per-Script Table (map_type=$49, 2 scripts)
; ---------------------------------------------------------------------------
Map49_ScriptPtrTable:
    dw Map49_Script00                  ; script 0
    dw Map49_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map49_Script00
; ---------------------------------------------------------------------------
Map49_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map49_Script01
; ---------------------------------------------------------------------------
Map49_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00DD  ; Text $00DD: "$1A:$5CBE The door is shut tight."
    dw Bank0F_ScriptAddr_53D4          ; -> branch target
    dw $0590  ; Text $0590: "$49:$6C6E *:Welcome to my altar of // sacrifice! /"
    dw $FF03  ; SetEventFlag
    dw $00DD  ; Text $00DD: "$1A:$5CBE The door is shut tight."
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_53D6          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_53D4:
    dw $0591  ; Text $0591: "$49:$6DC6 Zoma:Hmm, you seem to never learn. // Zo"
Bank0F_ScriptAddr_53D6:
    dw $FF5A  ; Cmd5A
    dw $00D1  ; Text $00D1: "$1A:$59B0 *:Huh? it's okay, let's heal // for the "
    dw $FF07  ; InitDialogMode
    dw $0592  ; Text $0592: "$49:$6E75 Zoma:...What is your name... son? // Zom"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0204  ; Text $0204: "$1B:$444A *:Oh well, nobody's here. // I wanna hav"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0593  ; Text $0593: "$49:$6F7F Watabou:There're lots of strong // monst"
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0049  ; Text $0049: "$42:$6651 King:Arrgh! You! You let my // precious "
    dw $FF03  ; SetEventFlag
    dw $002A  ; Text $002A: "$42:$5608 King:The monster farm is on the // upper"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D972  ; RAM $D972
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D990  ; RAM $D990
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0029  ; Text $0029: "$42:$55D7 *:I wanna be a master. // What should I "
    dw $547A
    dw $FF12  ; WriteRAM
    dw $D972  ; RAM $D972
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map4A Per-Script Table (map_type=$4A, 2 scripts)
; ---------------------------------------------------------------------------
Map4A_ScriptPtrTable:
    dw Map4A_Script00                  ; script 0
    dw Map4A_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map4A_Script00
; ---------------------------------------------------------------------------
Map4A_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map4A_Script01
; ---------------------------------------------------------------------------
Map4A_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00DE  ; Text $00DE: "$1A:$5CD8 *:... ... ... ... // *:zzz ..."
    dw Bank0F_ScriptAddr_54B4          ; -> branch target
    dw $0594  ; Text $0594: "$49:$6FBD *:Gwwrrrr...! Who are you? // *:I am Piz"
    dw $FF03  ; SetEventFlag
    dw $00DE  ; Text $00DE: "$1A:$5CD8 *:... ... ... ... // *:zzz ..."
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_54C4          ; -> branch target
    dw $0596  ; Text $0596: "$49:$7110 Pizzaro:Then, I will tell you! // Gwrrr."
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_54CC          ; -> branch target
Bank0F_ScriptAddr_54B4:
    dw $0597  ; Text $0597: "$49:$71AD Pizzaro:Gwwrrr...! // Pizzaro:You want t"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_54CA          ; -> branch target
    dw $0599  ; Text $0599: "$49:$71F7 Pizzaro:Then, what brought you here! // "
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_54CC          ; -> branch target
Bank0F_ScriptAddr_54C4:
    dw $0595  ; Text $0595: "$49:$70C7 Pizzaro:Gwwrrr! Regret showing // yourse"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_54CC          ; -> branch target
Bank0F_ScriptAddr_54CA:
    dw $0598  ; Text $0598: "$49:$71E1 Pizzaro:Then, die!"
Bank0F_ScriptAddr_54CC:
    dw $FF5A  ; Cmd5A
    dw $00D3  ; Text $00D3: "$1A:$5A17 *:[HERO], would you care for // a massag"
    dw $FF07  ; InitDialogMode
    dw $059A  ; Text $059A: "$49:$723A Pizzaro:Gwwrr...! My body is // burning."
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0104  ; Text $0104: "$43:$4FA8 *:Yo man, wanna know who your // match i"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $059B  ; Text $059B: "$49:$72B1 Watabou:Rosalie was Pizzaro's // lover. "
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $004A  ; Text $004A: "$42:$66CC King:What? [HERO]! // You have something"
    dw $FF03  ; SetEventFlag
    dw $002B  ; Text $002B: "$42:$5677 *:My kingdom has been losing // in the S"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D973  ; RAM $D973
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D991  ; RAM $D991
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $002C  ; Text $002C: "$42:$56FD *:Let me tell you about the legend // of"
    dw Bank0F_ScriptAddr_5570          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D973  ; RAM $D973
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
Bank0F_ScriptAddr_5570:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map4B Per-Script Table (map_type=$4B, 2 scripts)
; ---------------------------------------------------------------------------
Map4B_ScriptPtrTable:
    dw Map4B_Script00                  ; script 0
    dw Map4B_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map4B_Script00
; ---------------------------------------------------------------------------
Map4B_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map4B_Script01
; ---------------------------------------------------------------------------
Map4B_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00DF  ; Text $00DF: "$1A:$5CFC *:I'm sleepy. Can we go home // now?"
    dw Bank0F_ScriptAddr_55A8          ; -> branch target
    dw $059C  ; Text $059C: "$49:$735E *:Ggggrrr... // *:Who is disturb- ing my"
    dw $FF03  ; SetEventFlag
    dw $00DF  ; Text $00DF: "$1A:$5CFC *:I'm sleepy. Can we go home // now?"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_55AE          ; -> branch target
    dw $059D  ; Text $059D: "$49:$7471 Esterk:Then go away. // Esterk:I will re"
    dw $FFFF  ; END

Bank0F_ScriptAddr_55A8:
    dw $059F  ; Text $059F: "$49:$750A Esterk:Gggrrr... // Esterk:You again... "
    dw $FF14  ; ClearGameFlags
    dw $55B0
Bank0F_ScriptAddr_55AE:
    dw $059E  ; Text $059E: "$49:$74B5 Esterk:There is no choice. // Esterk:I c"
    dw $FF5A  ; Cmd5A
    dw $00D5  ; Text $00D5: "$1A:$5A84 *:Well,in a way, fighting becomes // fig"
    dw $FF07  ; InitDialogMode
    dw $05A0  ; Text $05A0: "$49:$7598 Esterk:Ggggrrr... What's wrong with // m"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0102  ; Text $0102: "$43:$4EEE *:Hm.. It doesn't listen to me much. // "
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $05A1  ; Text $05A1: "$49:$7640 Watabou:Even if we're in a dream, // Wat"
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $004B  ; Text $004B: "$42:$6791 Pulio:Majesty, Hale escaped // through t"
    dw $FF03  ; SetEventFlag
    dw $002C  ; Text $002C: "$42:$56FD *:Let me tell you about the legend // of"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D973  ; RAM $D973
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D992  ; RAM $D992
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $002B  ; Text $002B: "$42:$5677 *:My kingdom has been losing // in the S"
    dw $5654
    dw $FF12  ; WriteRAM
    dw $D973  ; RAM $D973
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map4C Per-Script Table (map_type=$4C, 2 scripts)
; ---------------------------------------------------------------------------
Map4C_ScriptPtrTable:
    dw Map4C_Script00                  ; script 0
    dw Map4C_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map4C_Script00
; ---------------------------------------------------------------------------
Map4C_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map4C_Script01
; ---------------------------------------------------------------------------
Map4C_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw Bank0F_ScriptAddr_568E          ; -> branch target
    dw $05A2  ; Text $05A2: "$49:$76C0 *:At last, you came here. // *:The Monst"
    dw $FF03  ; SetEventFlag
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5694          ; -> branch target
    dw $05A4  ; Text $05A4: "$49:$780F *:You don't know my name? You fool! // *"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_5696          ; -> branch target
Bank0F_ScriptAddr_568E:
    dw $05A5  ; Text $05A5: "$49:$78E6 Mirudraas:Ha ha ha! // Mirudraas:Monster"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_5696          ; -> branch target
Bank0F_ScriptAddr_5694:
    dw $05A3  ; Text $05A3: "$49:$7730 *:Ha ha ha!! You have good // intentions"
Bank0F_ScriptAddr_5696:
    dw $FF5A  ; Cmd5A
    dw $00D7  ; Text $00D7: "$1A:$5B3E *:Hee Hee Hee! Work! Stupid!"
    dw $FF07  ; InitDialogMode
    dw $05A6  ; Text $05A6: "$49:$796D Mirudraas:How.. could I be // defeated.."
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0D02
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0203  ; Text $0203: "$1B:$4417 *:The Room of Peace & Bravery // is open"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $05A7  ; Text $05A7: "$49:$7A09 Watabou:You really became // strong. Now"
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $004C  ; Text $004C: "$42:$67D1 King:I see. Now [HERO], proceed // to th"
    dw $FF03  ; SetEventFlag
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D93A  ; RAM $D93A
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D993  ; RAM $D993
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0014  ; Text $0014: "$42:$4AE0 *:Now it's time to go see the King."
    dw Bank0F_ScriptAddr_5744          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D93A  ; RAM $D93A
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
Bank0F_ScriptAddr_5744:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map4D Per-Script Table (map_type=$4D, 2 scripts)
; ---------------------------------------------------------------------------
Map4D_ScriptPtrTable:
    dw Map4D_Script00                  ; script 0
    dw Map4D_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map4D_Script00
; ---------------------------------------------------------------------------
Map4D_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map4D_Script01
; ---------------------------------------------------------------------------
Map4D_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00E0  ; Text $00E0: "$1A:$5D25 *:Toiling away doesn't help. // Relax!"
    dw Bank0F_ScriptAddr_5794          ; -> branch target
    dw $05A8  ; Text $05A8: "$49:$7A47 *:Welcome, you worthless... // *:I am Mu"
    dw $FF03  ; SetEventFlag
    dw $00E0  ; Text $00E0: "$1A:$5D25 *:Toiling away doesn't help. // Relax!"
Bank0F_ScriptAddr_5770:
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_577E          ; -> branch target
    dw $05A9  ; Text $05A9: "$49:$7A8E Mudou:Hm? You already know my // name, r"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_5770          ; -> branch target
Bank0F_ScriptAddr_577E:
    dw $05AA  ; Text $05AA: "$49:$7AC2 Mudou:Fine. Now, // Mudou:are you prepar"
Bank0F_ScriptAddr_5780:
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_578E          ; -> branch target
    dw $05AB  ; Text $05AB: "$49:$7AF2 Mudou:Huh? Did you prepare your // coffi"
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_5780          ; -> branch target
Bank0F_ScriptAddr_578E:
    dw $05AC  ; Text $05AC: "$49:$7B39 Mudou:Fine. Let's begin."
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_5796          ; -> branch target
Bank0F_ScriptAddr_5794:
    dw $05AD  ; Text $05AD: "$49:$7B54 Mudou:Annoying worthless things. // I'll"
Bank0F_ScriptAddr_5796:
    dw $FF5A  ; Cmd5A
    dw $00D9  ; Text $00D9: "$1A:$5B8B *:I...if I support everybody,th...the //"
    dw $FF07  ; InitDialogMode
    dw $05AE  ; Text $05AE: "$49:$7B91 Mudou:I was beaten by worthless... // it"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0104  ; Text $0104: "$43:$4FA8 *:Yo man, wanna know who your // match i"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $05AF
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $004D  ; Text $004D: "$42:$68DF *:His Majesty seems to be // very upset."
    dw $FF03  ; SetEventFlag
    dw $002E  ; Text $002E: "$42:$58EC *:Here it is again. // *:The Starry Nigh"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D94C  ; RAM $D94C
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D994  ; RAM $D994
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $001E  ; Text $001E: "$42:$4CEA [HERO] opened a treasure chest!"
    dw Bank0F_ScriptAddr_583A          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D94C  ; RAM $D94C
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
Bank0F_ScriptAddr_583A:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map4E Per-Script Table (map_type=$4E, 2 scripts)
; ---------------------------------------------------------------------------
Map4E_ScriptPtrTable:
    dw Map4E_Script00                  ; script 0
    dw Map4E_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map4E_Script00
; ---------------------------------------------------------------------------
Map4E_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map4E_Script01
; ---------------------------------------------------------------------------
Map4E_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00E1
    dw Bank0F_ScriptAddr_586C          ; -> branch target
    dw $05B0
    dw $FF03  ; SetEventFlag
    dw $00E1
    dw $FF14  ; ClearGameFlags
    dw Bank0F_ScriptAddr_586E          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_586C:
    dw $05B1
Bank0F_ScriptAddr_586E:
    dw $FF5A  ; Cmd5A
    dw $00DB  ; Text $00DB: "$1A:$5C07 *:Brrrr. Shiver... // *:I'm not scared I"
    dw $FF07  ; InitDialogMode
    dw $05B2
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "$46:$4292 *:Eeek! I cannot stand you! // *:I'm gon"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $05B3
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $004E  ; Text $004E: "$42:$6966 *:Give the courageous master // [HERO] t"
    dw $FF03  ; SetEventFlag
    dw $002F  ; Text $002F: "$42:$5A53 *:The tournament is held on the // Starr"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D958  ; RAM $D958
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D995  ; RAM $D995
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossUnused Per-Script Table (map_type=$4F, 3 scripts)
; ---------------------------------------------------------------------------
BossUnused_ScriptPtrTable:
    dw BossUnused_Script00             ; script 0
    dw BossUnused_Script01             ; script 1
    dw BossUnused_Script02             ; script 2
; ---------------------------------------------------------------------------
; BossUnused_Script00
; ---------------------------------------------------------------------------
BossUnused_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossUnused_Script01
; ---------------------------------------------------------------------------
BossUnused_Script01:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossUnused_Script02
; ---------------------------------------------------------------------------
BossUnused_Script02:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map50 Per-Script Table (map_type=$50, 2 scripts)
; ---------------------------------------------------------------------------
Map50_ScriptPtrTable:
    dw Map50_Script00                  ; script 0
    dw Map50_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map50_Script00
; ---------------------------------------------------------------------------
Map50_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map50_Script01
; ---------------------------------------------------------------------------
Map50_Script01:
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $FF04  ; ScreenEffect
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0680  ; Text $0680: "$4A:$5F0B *:Item shop. May I help you?"
    dw $0682  ; Text $0682: "$4A:$5F3E *:Thank you. Come again!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map51 Per-Script Table (map_type=$51, 3 scripts)
; ---------------------------------------------------------------------------
Map51_ScriptPtrTable:
    dw Map51_Script00                  ; script 0
    dw Map51_Script01                  ; script 1
    dw Map51_Script02                  ; script 2
; ---------------------------------------------------------------------------
; Map51_Script00
; ---------------------------------------------------------------------------
Map51_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map51_Script02
; ---------------------------------------------------------------------------
Map51_Script02:
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
; ---------------------------------------------------------------------------
; Map51_Script01
; ---------------------------------------------------------------------------
Map51_Script01:
    dw $FF64  ; Cmd$64
    dw Bank0F_ScriptAddr_59B8          ; -> branch target
    dw $09FF
    dw $FF06  ; IncrementCounter
    dw $FF41  ; SetBGM
    dw $0041  ; Text $0041: "$42:$61BD Slio:You can drop off up to 19 // monste"
    dw $FF46  ; Cmd46
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89C  ; RAM $C89C
    dw $00D2
    dw $FF12  ; WriteRAM
    dw $C89D  ; RAM $C89D
    dw $00E2  ; Text $00E2: "$43:$4193 *:Welcome to the arena. // *:Huh? Me? I'"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF35  ; Cmd35
    dw $FF16  ; Cmd16
    dw $FF4B  ; Cmd4B
    dw $FFFF  ; END

Bank0F_ScriptAddr_59B8:
    dw $09F6
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map52 Per-Script Table (map_type=$52, 1 scripts)
; ---------------------------------------------------------------------------
Map52_ScriptPtrTable:
    dw Map52_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map52_Script00
; ---------------------------------------------------------------------------
Map52_Script00:
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_59F0          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0F_ScriptAddr_5A06          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0F_ScriptAddr_5A0E          ; -> branch target
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw Bank0F_ScriptAddr_5A16          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_59F0:
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9CF  ; RAM $D9CF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $5A00
    dw $09F3  ; Text $09F3: "$4F:$6840 *:A big applause for the brave // challe"
    dw $FF20  ; Cmd20
    dw $FFFF  ; END

    db $FE
    db $09
    db $20
    db $FF
    db $FF
    db $FF
Bank0F_ScriptAddr_5A06:
    dw $FF07  ; InitDialogMode
    dw $09FD  ; Text $09FD: "$4F:$6A6D *:Just like a veteran! // *:How about th"
    dw $FF20  ; Cmd20
    dw $FFFF  ; END

Bank0F_ScriptAddr_5A0E:
    dw $FF07  ; InitDialogMode
    dw $09FC  ; Text $09FC: "$4F:$6A0A *:Is there anybody who can beat you!! //"
    dw $FF20  ; Cmd20
    dw $FFFF  ; END

Bank0F_ScriptAddr_5A16:
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D0  ; RAM $D9D0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $5A2A
    dw $FF5D  ; Cmd5D
    dw $09F1
    dw $09EF  ; Text $09EF: "$4F:$6787 Got a [INS 00] as the reward!"
    dw $FF14  ; ClearGameFlags
    dw $5A2C
    dw $09F1
    dw $FF2C  ; CheckInvFull
    dw $5A48
    dw $FF5C  ; Cmd5C
    dw $09F0  ; Text $09F0: "$4F:$67A2 *:The next reward is 1 [INS 00]! // *:Wo"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $5A48
    dw $FF06  ; IncrementCounter
    dw $FF0F  ; SetScreenScroll
    dw $0052  ; Text $0052: "$42:$6BA3 *:Please bring Hale back as soon // as p"
    dw $0068  ; Text $0068: "$42:$78FC *:Monsters have personalities too. // *:"
    dw $0068  ; Text $0068: "$42:$78FC *:Monsters have personalities too. // *:"
    dw $FFFF  ; END

    db $F2
    db $09
    db $06
    db $FF
    db $12
    db $FF
    db $6C
    db $C9
    db $01
    db $00
    db $12
    db $FF
    db $6D
    db $C9
    db $00
    db $00
    db $12
    db $FF
    db $6E
    db $C9
    db $80
    db $00
    db $12
    db $FF
    db $EB
    db $C8
    db $20
    db $00
    db $12
    db $FF
    db $05
    db $C9
    db $00
    db $00
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Map53 Per-Script Table (map_type=$53, 1 scripts)
; ---------------------------------------------------------------------------
Map53_ScriptPtrTable:
    dw Map53_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map54 Per-Script Table (map_type=$54, 2 scripts)
; ---------------------------------------------------------------------------
Map54_ScriptPtrTable:
    dw Map54_Script00                  ; script 0
    dw Map54_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map54_Script00
; ---------------------------------------------------------------------------
Map54_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map54_Script01
; ---------------------------------------------------------------------------
Map54_Script01:
    dw $FF1C  ; CompareRAM
    dw $0600  ; Text $0600: "$4A:$4E50 *:Come to me when you want to breed // w"
    dw $FF19  ; FadeEffect
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map57 Per-Script Table (map_type=$57, 1 scripts)
; ---------------------------------------------------------------------------
Map57_ScriptPtrTable:
    dw Map53_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map5A Per-Script Table (map_type=$5A, 7 scripts)
; ---------------------------------------------------------------------------
Map5A_ScriptPtrTable:
    dw Map5A_Script00                  ; script 0
    dw Map5A_Script01                  ; script 1
    dw Map5A_Script02                  ; script 2
    dw Map5A_Script03                  ; script 3
    dw Map5A_Script04                  ; script 4
    dw Map5A_Script05                  ; script 5
    dw Map5A_Script06                  ; script 6
; ---------------------------------------------------------------------------
; Map5A_Script00
; ---------------------------------------------------------------------------
Map5A_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map5A_Script01
; ---------------------------------------------------------------------------
Map5A_Script01:
    dw $FF15  ; PlaySE
    dw $D9CF  ; RAM $D9CF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5AC8          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5AE2          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9CF  ; RAM $D9CF
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5ABA          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5ACC          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9CF  ; RAM $D9CF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5ABA:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9CF  ; RAM $D9CF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5AC8:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5ACC:
    dw $FF37  ; Cmd37
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5ADA
    dw $FFFF  ; END

    db $82
    db $00
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5AE2:
    dw $0082  ; Text $0082: "$1A:$4691 *:I don't like fighting in a // group."
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5A_Script02
; ---------------------------------------------------------------------------
Map5A_Script02:
    dw $FF15  ; PlaySE
    dw $D9D0  ; RAM $D9D0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5B24          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5B3E          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D0  ; RAM $D9D0
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5B16          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5B28          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D0  ; RAM $D9D0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5B16:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D0  ; RAM $D9D0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5B24:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5B28:
    dw $FF37  ; Cmd37
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5B36
    dw $FFFF  ; END

    db $90
    db $00
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5B3E:
    dw $0090
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5A_Script03
; ---------------------------------------------------------------------------
Map5A_Script03:
    dw $FF15  ; PlaySE
    dw $D9D1  ; RAM $D9D1
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5B80          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5B9A          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D1  ; RAM $D9D1
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5B72          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5B84          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D1  ; RAM $D9D1
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5B72:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D1  ; RAM $D9D1
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5B80:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5B84:
    dw $FF37  ; Cmd37
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5B92
    dw $FFFF  ; END

    db $C6
    db $00
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5B9A:
    dw $00C6  ; Text $00C6: "$1A:$56D6 *:I know I'm careless but // I do help m"
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5A_Script04
; ---------------------------------------------------------------------------
Map5A_Script04:
    dw $FF15  ; PlaySE
    dw $D9D2  ; RAM $D9D2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5BDC          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5BF6          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D2  ; RAM $D9D2
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5BCE          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5BE0          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D2  ; RAM $D9D2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5BCE:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D2  ; RAM $D9D2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5BDC:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5BE0:
    dw $FF37  ; Cmd37
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5BEE
    dw $FFFF  ; END

    db $CC
    db $00
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5BF6:
    dw $00CC  ; Text $00CC: "$1A:$5885 *:Grrr...Nobody can catch me // by surpr"
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5A_Script05
; ---------------------------------------------------------------------------
Map5A_Script05:
    dw $FF15  ; PlaySE
    dw $D9D3  ; RAM $D9D3
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5C38          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5C52          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D3  ; RAM $D9D3
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5C2A          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5C3C          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D3  ; RAM $D9D3
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5C2A:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D3  ; RAM $D9D3
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5C38:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5C3C:
    dw $FF37  ; Cmd37
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5C4A
    dw $FFFF  ; END

    db $44
    db $01
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5C52:
    dw $0144  ; Text $0144: "$43:$6765 *:Thanks [HERO]! For bringing the // med"
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5A_Script06
; ---------------------------------------------------------------------------
Map5A_Script06:
    dw $FF15  ; PlaySE
    dw $D9D4  ; RAM $D9D4
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5C94          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5CAE          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D4  ; RAM $D9D4
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5C86          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5C98          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D4  ; RAM $D9D4
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5C86:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D4  ; RAM $D9D4
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5C94:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5C98:
    dw $FF37  ; Cmd37
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5CA6
    dw $FFFF  ; END

    db $4E
    db $01
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5CAE:
    dw $014E  ; Text $014E: "$43:$6D0E King:Well maybe I'm exaggerating a // li"
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5B Per-Script Table (map_type=$5B, 7 scripts)
; ---------------------------------------------------------------------------
Map5B_ScriptPtrTable:
    dw Map5B_Script00                  ; script 0
    dw Map5B_Script01                  ; script 1
    dw Map5B_Script02                  ; script 2
    dw Map5B_Script03                  ; script 3
    dw Map5B_Script04                  ; script 4
    dw Map5B_Script05                  ; script 5
    dw Map5B_Script06                  ; script 6
; ---------------------------------------------------------------------------
; Map5B_Script00
; ---------------------------------------------------------------------------
Map5B_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map5B_Script01
; ---------------------------------------------------------------------------
Map5B_Script01:
    dw $FF15  ; PlaySE
    dw $D9CF  ; RAM $D9CF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5D00          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5D1A          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9CF  ; RAM $D9CF
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5CF2          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5D04          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9CF  ; RAM $D9CF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5CF2:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9CF  ; RAM $D9CF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5D00:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5D04:
    dw $FF37  ; Cmd37
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5D12
    dw $FFFF  ; END

    db $C6
    db $00
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5D1A:
    dw $00C6  ; Text $00C6: "$1A:$56D6 *:I know I'm careless but // I do help m"
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5B_Script02
; ---------------------------------------------------------------------------
Map5B_Script02:
    dw $FF15  ; PlaySE
    dw $D9D0  ; RAM $D9D0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5D5C          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5D76          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D0  ; RAM $D9D0
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5D4E          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5D60          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D0  ; RAM $D9D0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5D4E:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D0  ; RAM $D9D0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5D5C:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5D60:
    dw $FF37  ; Cmd37
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5D6E
    dw $FFFF  ; END

    db $CC
    db $00
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5D76:
    dw $00CC  ; Text $00CC: "$1A:$5885 *:Grrr...Nobody can catch me // by surpr"
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5B_Script03
; ---------------------------------------------------------------------------
Map5B_Script03:
    dw $FF15  ; PlaySE
    dw $D9D1  ; RAM $D9D1
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5DB8          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5DD2          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D1  ; RAM $D9D1
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5DAA          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5DBC          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D1  ; RAM $D9D1
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5DAA:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D1  ; RAM $D9D1
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5DB8:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5DBC:
    dw $FF37  ; Cmd37
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5DCA
    dw $FFFF  ; END

    db $06
    db $01
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5DD2:
    dw $0106  ; Text $0106: "$43:$500D *:Well,it'll be OK too."
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5B_Script04
; ---------------------------------------------------------------------------
Map5B_Script04:
    dw $FF15  ; PlaySE
    dw $D9D2  ; RAM $D9D2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5E14          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5E2E          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D2  ; RAM $D9D2
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5E06          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5E18          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D2  ; RAM $D9D2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5E06:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D2  ; RAM $D9D2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5E14:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5E18:
    dw $FF37  ; Cmd37
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5E26
    dw $FFFF  ; END

    db $0C
    db $01
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5E2E:
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5B_Script05
; ---------------------------------------------------------------------------
Map5B_Script05:
    dw $FF15  ; PlaySE
    dw $D9D3  ; RAM $D9D3
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5E70          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5E8A          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D3  ; RAM $D9D3
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5E62          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5E74          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D3  ; RAM $D9D3
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5E62:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D3  ; RAM $D9D3
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5E70:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5E74:
    dw $FF37  ; Cmd37
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5E82
    dw $FFFF  ; END

    db $46
    db $01
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5E8A:
    dw $0146  ; Text $0146: "$43:$685F Watabou:Right on! [HERO]! // I'll take y"
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5B_Script06
; ---------------------------------------------------------------------------
Map5B_Script06:
    dw $FF15  ; PlaySE
    dw $D9D4  ; RAM $D9D4
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5ECC          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5EE6          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D4  ; RAM $D9D4
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5EBE          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5ED0          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D4  ; RAM $D9D4
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5EBE:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D4  ; RAM $D9D4
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5ECC:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5ED0:
    dw $FF37  ; Cmd37
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5EDE
    dw $FFFF  ; END

    db $4C
    db $01
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5EE6:
    dw $014C  ; Text $014C: "$43:$6B82 *:The Room of Villager & // Talisman is "
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5C Per-Script Table (map_type=$5C, 9 scripts)
; ---------------------------------------------------------------------------
Map5C_ScriptPtrTable:
    dw Map5C_Script00                  ; script 0
    dw Map5C_Script01                  ; script 1
    dw Map5C_Script02                  ; script 2
    dw Map5C_Script03                  ; script 3
    dw Map5C_Script04                  ; script 4
    dw Map5C_Script05                  ; script 5
    dw Map5C_Script06                  ; script 6
    dw Map5C_Script07                  ; script 7
    dw Map5C_Script08                  ; script 8
; ---------------------------------------------------------------------------
; Map5C_Script00
; ---------------------------------------------------------------------------
Map5C_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map5C_Script01
; ---------------------------------------------------------------------------
Map5C_Script01:
    dw $FF15  ; PlaySE
    dw $D9CF  ; RAM $D9CF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5F3C          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5F56          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9CF  ; RAM $D9CF
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5F2E          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5F40          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9CF  ; RAM $D9CF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5F2E:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9CF  ; RAM $D9CF
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5F3C:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5F40:
    dw $FF37  ; Cmd37
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5F4E
    dw $FFFF  ; END

    db $86
    db $00
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5F56:
    dw $0086
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5C_Script02
; ---------------------------------------------------------------------------
Map5C_Script02:
    dw $FF15  ; PlaySE
    dw $D9D0  ; RAM $D9D0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5F98          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_5FB2          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D0  ; RAM $D9D0
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5F8A          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5F9C          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D0  ; RAM $D9D0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5F8A:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D0  ; RAM $D9D0
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5F98:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5F9C:
    dw $FF37  ; Cmd37
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $5FAA
    dw $FFFF  ; END

    db $88
    db $00
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_5FB2:
    dw $0088
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5C_Script03
; ---------------------------------------------------------------------------
Map5C_Script03:
    dw $FF15  ; PlaySE
    dw $D9D1  ; RAM $D9D1
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_5FF4          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_600E          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D1  ; RAM $D9D1
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_5FE6          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_5FF8          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D1  ; RAM $D9D1
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5FE6:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D1  ; RAM $D9D1
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5FF4:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_5FF8:
    dw $FF37  ; Cmd37
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $6006
    dw $FFFF  ; END

    db $8A
    db $00
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_600E:
    dw $008A
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5C_Script04
; ---------------------------------------------------------------------------
Map5C_Script04:
    dw $FF15  ; PlaySE
    dw $D9D2  ; RAM $D9D2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_6050          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_606A          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D2  ; RAM $D9D2
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_6042          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_6054          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D2  ; RAM $D9D2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_6042:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D2  ; RAM $D9D2
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_6050:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_6054:
    dw $FF37  ; Cmd37
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $6062
    dw $FFFF  ; END

    db $8C
    db $00
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_606A:
    dw $008C
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5C_Script05
; ---------------------------------------------------------------------------
Map5C_Script05:
    dw $FF15  ; PlaySE
    dw $D9D3  ; RAM $D9D3
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_60AC          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_60C6          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D3  ; RAM $D9D3
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_609E          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_60B0          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D3  ; RAM $D9D3
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_609E:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D3  ; RAM $D9D3
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_60AC:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_60B0:
    dw $FF37  ; Cmd37
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $60BE
    dw $FFFF  ; END

    db $86
    db $01
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_60C6:
    dw $0186  ; Text $0186: "$1A:$68E6 *:Oh, well."
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5C_Script06
; ---------------------------------------------------------------------------
Map5C_Script06:
    dw $FF15  ; PlaySE
    dw $D9D4  ; RAM $D9D4
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_6108          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_6122          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D4  ; RAM $D9D4
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_60FA          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_610C          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D4  ; RAM $D9D4
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_60FA:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D4  ; RAM $D9D4
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_6108:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_610C:
    dw $FF37  ; Cmd37
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $611A
    dw $FFFF  ; END

    db $88
    db $01
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_6122:
    dw $0188  ; Text $0188: "$1A:$6964 [HERO] looked at the bookshelf. // :Fami"
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5C_Script07
; ---------------------------------------------------------------------------
Map5C_Script07:
    dw $FF15  ; PlaySE
    dw $D9D5  ; RAM $D9D5
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_6164          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_617E          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D5  ; RAM $D9D5
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_6156          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_6168          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D5  ; RAM $D9D5
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_6156:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D5  ; RAM $D9D5
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_6164:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_6168:
    dw $FF37  ; Cmd37
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $6176
    dw $FFFF  ; END

    db $8A
    db $01
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_617E:
    dw $018A  ; Text $018A: "$1A:$6AA5 [HERO] looked at the bookshelf. // :Seon"
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5C_Script08
; ---------------------------------------------------------------------------
Map5C_Script08:
    dw $FF15  ; PlaySE
    dw $D9D6  ; RAM $D9D6
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_61C0          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0053  ; Text $0053: "$42:$6BD9 *:When you enter the Travelers' // Gates"
    dw $FF24  ; Cmd24
    dw Bank0F_ScriptAddr_61DA          ; -> branch target
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9D6  ; RAM $D9D6
    dw $00FF  ; Text $00FF: "$43:$4D02 *:My rival's watching me from // somewhe"
    dw Bank0F_ScriptAddr_61B2          ; -> branch target
    dw $FF2C  ; CheckInvFull
    dw Bank0F_ScriptAddr_61C4          ; -> branch target
    dw $FF37  ; Cmd37
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $09FA
    dw $FF12  ; WriteRAM
    dw $D9D6  ; RAM $D9D6
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_61B2:
    dw $09F9  ; Text $09F9: "$4F:$696F [HERO] opened the treasure chest! // The"
    dw $FF06  ; IncrementCounter
    dw $FF36  ; Cmd36
    dw $FF12  ; WriteRAM
    dw $D9D6  ; RAM $D9D6
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0F_ScriptAddr_61C0:
    dw $09F8  ; Text $09F8: "$4F:$692E [HERO] checked the treasure chest. // Bu"
    dw $FFFF  ; END

Bank0F_ScriptAddr_61C4:
    dw $FF37  ; Cmd37
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $09FA
    dw $09F4  ; Text $09F4: "$4F:$6894 Can not carry anymore!"
    dw $FF24  ; Cmd24
    dw $61D2
    dw $FFFF  ; END

    db $8C
    db $01
    db $30
    db $31
    db $D8
    db $34
    db $35
    db $D9
Bank0F_ScriptAddr_61DA:
    dw $018C  ; Text $018C: "$1A:$6B90 [HERO] looked at the bookshelf. // :Seon"
    dw $3332
    dw $34D8
    dw $D935  ; RAM $D935
; ---------------------------------------------------------------------------
; Map5D Per-Script Table (map_type=$5D, 1 scripts)
; ---------------------------------------------------------------------------
Map5D_ScriptPtrTable:
    dw Map5D_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map5D_Script00
; ---------------------------------------------------------------------------
Map5D_Script00:
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw Bank0F_ScriptAddr_6A64          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw Bank0F_ScriptAddr_64CC          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0F_ScriptAddr_62E0          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0F_ScriptAddr_62C6          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0F_ScriptAddr_6248          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw Bank0F_ScriptAddr_6224          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_6224:
    dw $FF41  ; SetBGM
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw $FF07  ; InitDialogMode
    dw $0126  ; Text $0126: "$43:$6020 *:Congratulations! We have a new // winn"
    dw $FF06  ; IncrementCounter
    dw $FF46  ; Cmd46
    dw $FF41  ; SetBGM
    dw $0061  ; Text $0061: "$42:$749A *:Oh boy! This looks dangerous! // Oh, n"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF12  ; WriteRAM
    dw $D9CD  ; RAM $D9CD
    dw $00FE  ; Text $00FE: "$43:$4CD1 *:The guy at the entrance! // He's my ri"
    dw $FF0F  ; SetScreenScroll
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FFFF  ; END

Bank0F_ScriptAddr_6248:
    dw $FF41  ; SetBGM
    dw $003A  ; Text $003A: "$42:$5ED1 [HERO] looked into the jar."
    dw $FF07  ; InitDialogMode
    dw $0124  ; Text $0124: "$43:$5F34 *:For the 2nd match, the victory // agai"
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $62B2
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $62AC
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $62A6
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $62A0
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $629A
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $6294
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $628E
    dw $085B
    dw $FF14  ; ClearGameFlags
    dw $62B4
    dw $085C
    dw $FF14  ; ClearGameFlags
    dw $62B4
    dw $085F
    dw $FF14  ; ClearGameFlags
    dw $62B4
    dw $085E
    dw $FF14  ; ClearGameFlags
    dw $62B4
    dw $085F
    dw $FF14  ; ClearGameFlags
    dw $62B4
    dw $0860
    dw $FF14  ; ClearGameFlags
    dw $62B4
    dw $0861
    dw $FF14  ; ClearGameFlags
    dw $62B4
    dw $0862
    dw $FF06  ; IncrementCounter
    dw $FF46  ; Cmd46
    dw $FF41  ; SetBGM
    dw $0061  ; Text $0061: "$42:$749A *:Oh boy! This looks dangerous! // Oh, n"
    dw $FF12  ; WriteRAM
    dw $D9CD  ; RAM $D9CD
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF14  ; ClearGameFlags
    dw $62EC
Bank0F_ScriptAddr_62C6:
    dw $FF41  ; SetBGM
    dw $003A  ; Text $003A: "$42:$5ED1 [HERO] looked into the jar."
    dw $FF07  ; InitDialogMode
    dw $0122  ; Text $0122: "$43:$5EA4 *:For the 1st match, the victory // goes"
    dw $FF06  ; IncrementCounter
    dw $FF46  ; Cmd46
    dw $FF41  ; SetBGM
    dw $0061  ; Text $0061: "$42:$749A *:Oh boy! This looks dangerous! // Oh, n"
    dw $FF12  ; WriteRAM
    dw $D9CD  ; RAM $D9CD
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF14  ; ClearGameFlags
    dw $62EC
Bank0F_ScriptAddr_62E0:
    dw $FF07  ; InitDialogMode
    dw $0120  ; Text $0120: "$43:$5DE8 *:Ladies & Gents! Welcome to the // Aren"
    dw $FF06  ; IncrementCounter
    dw $FF12  ; WriteRAM
    dw $D9CD  ; RAM $D9CD
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFC0  ; Cmd$C0
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFC0  ; Cmd$C0
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFC0  ; Cmd$C0
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFC0  ; Cmd$C0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4A  ; Cmd4A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4A  ; Cmd4A
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF07  ; InitDialogMode
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $6378
    dw $0121  ; Text $0121: "$43:$5E8F *:Leeet's Rumble!"
    dw $FF03  ; SetEventFlag
    dw $0121  ; Text $0121: "$43:$5E8F *:Leeet's Rumble!"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $FF00  ; BranchIfFlagClear
    dw $0099
    dw $6386
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $649A
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $6490
    dw $FF00  ; BranchIfFlagClear
    dw $0094
    dw $639C
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $648A
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $6480
    dw $FF00  ; BranchIfFlagClear
    dw $0122  ; Text $0122: "$43:$5EA4 *:For the 1st match, the victory // goes"
    dw $63B2
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $647A
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $6470
    dw $FF00  ; BranchIfFlagClear
    dw $0089
    dw $63C8
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $646A
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $6460
    dw $FF00  ; BranchIfFlagClear
    dw $0068  ; Text $0068: "$42:$78FC *:Monsters have personalities too. // *:"
    dw $63DE
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $645A
    dw $FF00  ; BranchIfFlagClear
    dw $0067  ; Text $0067: "$42:$77B7 *:You can enter the locked rooms // only"
    dw $63EC
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $6450
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $6446
    dw $FF00  ; BranchIfFlagClear
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $6402
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $6440
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $6436
    dw $FF00  ; BranchIfFlagClear
    dw $0044  ; Text $0044: "$42:$6492 *:You are at the monster farm."
    dw $6418
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6430
    dw $FF15  ; PlaySE
    dw $D9CE  ; RAM $D9CE
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $6426
    dw $0125  ; Text $0125: "$43:$5F9D *:I'm the principal of the // Master Sch"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $01A2  ; Text $01A2: "$44:$47F5 *:I'm conducting secret research // at t"
    dw $FF03  ; SetEventFlag
    dw $0044  ; Text $0044: "$42:$6492 *:You are at the monster farm."
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $01A3  ; Text $01A3: "$44:$488A *:Being a master and a fighter // is one"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $01E2  ; Text $01E2: "$44:$7283 *:Hey [HERO]. Welcome. // *:I am Master "
    dw $FF03  ; SetEventFlag
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $01E3  ; Text $01E3: "$44:$7309 *:Welcome back. Don't worry about // los"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $026F  ; Text $026F: "$45:$51D8 *:You're my opponent? // Is this a joke?"
    dw $FF03  ; SetEventFlag
    dw $0068  ; Text $0068: "$42:$78FC *:Monsters have personalities too. // *:"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $0270  ; Text $0270: "$45:$523B *:I wondered who it would be. // Its' yo"
    dw $FF03  ; SetEventFlag
    dw $0068  ; Text $0068: "$42:$78FC *:Monsters have personalities too. // *:"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $0271  ; Text $0271: "$45:$52D1 *:You again? It'll be the same // no mat"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $0330  ; Text $0330: "$46:$53BF *Hello [HERO]! I was expecting you. // *"
    dw $FF03  ; SetEventFlag
    dw $0089
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $0331  ; Text $0331: "$46:$5410 *:How are you? I'm ready. // *:Let's jus"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $035E  ; Text $035E: "$46:$6609 *:Oooo! Ahhhh! Where am I? // *:What? Th"
    dw $FF03  ; SetEventFlag
    dw $0122  ; Text $0122: "$43:$5EA4 *:For the 1st match, the victory // goes"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $035F  ; Text $035F: "$46:$6677 *:Hmm. You again? I hope you got // bett"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $03DE  ; Text $03DE: "$47:$4A8C *:Welcome to A class. I was // expecting"
    dw $FF03  ; SetEventFlag
    dw $0094
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $03DF  ; Text $03DF: "$47:$4AEC *:Maybe you'll do better next // time [H"
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $0409  ; Text $0409: "$21:$4553 *:Winning is not about luck but // about"
    dw $FF03  ; SetEventFlag
    dw $0099
    dw $FF14  ; ClearGameFlags
    dw $649C
    dw $040A  ; Text $040A: "$21:$462C *:Perfect your ability and luck // will "
    dw $FF06  ; IncrementCounter
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FFF0  ; Cmd$F0
    dw $FF0A  ; NPCMoveX
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF20  ; Cmd20
    dw $FFFF  ; END

Bank0F_ScriptAddr_64CC:
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $6998
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $697E
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $671A
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $64EE
    dw $FFFF  ; END

    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $12
    db $FF
    db $ED
    db $C8
    db $0E
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $07
    db $FF
    db $E9
    db $04
    db $41
    db $FF
    db $3C
    db $00
    db $46
    db $FF
    db $41
    db $FF
    db $61
    db $00
    db $09
    db $FF
    db $10
    db $00
    db $0D
    db $FF
    db $07
    db $00
    db $00
    db $00
    db $00
    db $00
    db $13
    db $FF
    db $E3
    db $D8
    db $06
    db $04
    db $22
    db $FF
    db $1C
    db $FF
    db $07
    db $15
    db $19
    db $FF
    db $41
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $1C
    db $FF
    db $07
    db $04
    db $19
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
    db $0D
    db $FF
    db $04
    db $00
    db $00
    db $00
    db $40
    db $00
    db $4D
    db $FF
    db $06
    db $00
    db $21
    db $FF
    db $6C
    db $00
    db $09
    db $FF
    db $01
    db $00
    db $07
    db $FF
    db $EA
    db $04
    db $0A
    db $FF
    db $07
    db $00
    db $F0
    db $FF
    db $22
    db $FF
    db $1A
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $19
    db $FF
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
    db $48
    db $FF
    db $05
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $00
    db $00
    db $D0
    db $FF
    db $19
    db $FF
    db $21
    db $FF
    db $65
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
    db $4D
    db $FF
    db $06
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
    db $4D
    db $FF
    db $06
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
    db $48
    db $FF
    db $07
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $21
    db $FF
    db $57
    db $00
    db $49
    db $FF
    db $01
    db $00
    db $1D
    db $FF
    db $1B
    db $FF
    db $07
    db $00
    db $F0
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $1E
    db $FF
    db $21
    db $FF
    db $57
    db $00
    db $48
    db $FF
    db $01
    db $00
    db $1D
    db $FF
    db $1B
    db $FF
    db $07
    db $00
    db $F0
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
    db $1E
    db $FF
    db $47
    db $FF
    db $00
    db $00
    db $1D
    db $FF
    db $1B
    db $FF
    db $07
    db $00
    db $F0
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
    db $22
    db $FF
    db $1B
    db $FF
    db $07
    db $00
    db $D8
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $D8
    db $FF
    db $19
    db $FF
    db $0D
    db $FF
    db $07
    db $00
    db $00
    db $00
    db $40
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $0D
    db $FF
    db $01
    db $00
    db $00
    db $00
    db $40
    db $00
    db $1E
    db $FF
    db $1C
    db $FF
    db $00
    db $04
    db $19
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $1C
    db $FF
    db $00
    db $01
    db $19
    db $FF
    db $1C
    db $FF
    db $00
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $03
    db $FF
    db $E4
    db $00
    db $12
    db $FF
    db $3F
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $40
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $41
    db $D9
    db $04
    db $00
    db $12
    db $FF
    db $42
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $43
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $44
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $52
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $74
    db $D9
    db $02
    db $00
    db $08
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
    db $01
    db $00
    db $3E
    db $FF
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
    db $12
    db $FF
    db $ED
    db $C8
    db $0E
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $12
    db $FF
    db $CD
    db $D9
    db $03
    db $00
    db $07
    db $FF
    db $E3
    db $04
    db $06
    db $FF
    db $41
    db $FF
    db $37
    db $00
    db $46
    db $FF
    db $41
    db $FF
    db $61
    db $00
    db $4A
    db $FF
    db $05
    db $00
    db $4A
    db $FF
    db $06
    db $00
    db $4A
    db $FF
    db $07
    db $00
    db $4A
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $0C
    db $00
    db $47
    db $FF
    db $05
    db $00
    db $47
    db $FF
    db $06
    db $00
    db $47
    db $FF
    db $07
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $0C
    db $00
    db $49
    db $FF
    db $05
    db $00
    db $49
    db $FF
    db $06
    db $00
    db $49
    db $FF
    db $07
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $0C
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $07
    db $FF
    db $E4
    db $04
    db $06
    db $FF
    db $41
    db $FF
    db $61
    db $00
    db $1C
    db $FF
    db $00
    db $04
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $4A
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $03
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $03
    db $00
    db $48
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $03
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $41
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $21
    db $FF
    db $65
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
    db $4D
    db $FF
    db $06
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
    db $4D
    db $FF
    db $06
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
    db $21
    db $FF
    db $6C
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $00
    db $00
    db $00
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $0D
    db $FF
    db $01
    db $00
    db $00
    db $00
    db $00
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $00
    db $00
    db $40
    db $00
    db $08
    db $FF
    db $0D
    db $FF
    db $01
    db $00
    db $05
    db $00
    db $80
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $41
    db $FF
    db $61
    db $00
    db $09
    db $FF
    db $10
    db $00
    db $0D
    db $FF
    db $01
    db $00
    db $05
    db $00
    db $00
    db $00
    db $08
    db $FF
    db $4A
    db $FF
    db $01
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $07
    db $FF
    db $01
    db $FF
    db $58
    db $01
    db $A0
    db $68
    db $E5
    db $04
    db $03
    db $FF
    db $58
    db $01
    db $14
    db $FF
    db $A2
    db $68
    db $E6
    db $04
    db $09
    db $FF
    db $04
    db $00
    db $1D
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $1A
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $1E
    db $FF
    db $0D
    db $FF
    db $08
    db $00
    db $18
    db $00
    db $38
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $1A
    db $00
    db $68
    db $00
    db $21
    db $FF
    db $6C
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $00
    db $00
    db $00
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $0D
    db $FF
    db $04
    db $00
    db $00
    db $00
    db $00
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
    db $01
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $1A
    db $00
    db $48
    db $00
    db $21
    db $FF
    db $6C
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $00
    db $00
    db $00
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $0D
    db $FF
    db $02
    db $00
    db $00
    db $00
    db $00
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
    db $01
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
    db $6C
    db $00
    db $0D
    db $FF
    db $08
    db $00
    db $00
    db $00
    db $00
    db $00
    db $09
    db $FF
    db $08
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
    db $08
    db $00
    db $00
    db $00
    db $40
    db $00
    db $09
    db $FF
    db $0C
    db $00
    db $22
    db $FF
    db $1A
    db $FF
    db $02
    db $00
    db $10
    db $00
    db $1A
    db $FF
    db $03
    db $00
    db $10
    db $00
    db $1A
    db $FF
    db $04
    db $00
    db $10
    db $00
    db $1A
    db $FF
    db $05
    db $00
    db $F0
    db $FF
    db $1A
    db $FF
    db $06
    db $00
    db $F0
    db $FF
    db $1A
    db $FF
    db $07
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $20
    db $FF
    db $FF
    db $FF
    db $41
    db $FF
    db $3A
    db $00
    db $07
    db $FF
    db $E1
    db $04
    db $06
    db $FF
    db $46
    db $FF
    db $41
    db $FF
    db $61
    db $00
    db $12
    db $FF
    db $CD
    db $D9
    db $02
    db $00
    db $14
    db $FF
    db $AA
    db $69
    db $12
    db $FF
    db $ED
    db $C8
    db $00
    db $00
    db $07
    db $FF
    db $DF
    db $04
    db $06
    db $FF
    db $12
    db $FF
    db $CD
    db $D9
    db $01
    db $00
    db $1B
    db $FF
    db $01
    db $00
    db $C0
    db $FF
    db $1B
    db $FF
    db $02
    db $00
    db $C0
    db $FF
    db $1B
    db $FF
    db $03
    db $00
    db $C0
    db $FF
    db $1B
    db $FF
    db $04
    db $00
    db $C0
    db $FF
    db $19
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $02
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $04
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
    db $02
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $04
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1B
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1A
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $1A
    db $FF
    db $04
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $4A
    db $FF
    db $01
    db $00
    db $4A
    db $FF
    db $02
    db $00
    db $4A
    db $FF
    db $03
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $07
    db $FF
    db $15
    db $FF
    db $CD
    db $D9
    db $02
    db $00
    db $32
    db $6A
    db $E0
    db $04
    db $14
    db $FF
    db $34
    db $6A
    db $E2
    db $04
    db $06
    db $FF
    db $1A
    db $FF
    db $02
    db $00
    db $10
    db $00
    db $1A
    db $FF
    db $03
    db $00
    db $10
    db $00
    db $1A
    db $FF
    db $04
    db $00
    db $10
    db $00
    db $1A
    db $FF
    db $06
    db $00
    db $F0
    db $FF
    db $1A
    db $FF
    db $07
    db $00
    db $F0
    db $FF
    db $0A
    db $FF
    db $08
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $20
    db $FF
    db $FF
    db $FF
Bank0F_ScriptAddr_6A64:
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF15  ; PlaySE
    dw $D9CD  ; RAM $D9CD
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $6AA6
    dw $FF41  ; SetBGM
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw $FF07  ; InitDialogMode
    dw $FF01  ; BranchIfFlagSet
    dw $0111  ; Text $0111: "$43:$547D *:I am Medal Man, the medal // collector"
    dw $6A84
    dw $084A
    dw $FF14  ; ClearGameFlags
    dw $6A86
    dw $08D8
    dw $FF06  ; IncrementCounter
    dw $FF46  ; Cmd46
    dw $FF41  ; SetBGM
    dw $0061  ; Text $0061: "$42:$749A *:Oh boy! This looks dangerous! // Oh, n"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF12  ; WriteRAM
    dw $D9CD  ; RAM $D9CD
    dw $00FE  ; Text $00FE: "$43:$4CD1 *:The guy at the entrance! // He's my ri"
    dw $FF03  ; SetEventFlag
    dw $0111  ; Text $0111: "$43:$547D *:I am Medal Man, the medal // collector"
    dw $FF0F  ; SetScreenScroll
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FFFF  ; END

    db $07
    db $FF
    db $01
    db $FF
    db $11
    db $01
    db $C0
    db $6A
    db $01
    db $FF
    db $10
    db $01
    db $BA
    db $6A
    db $45
    db $08
    db $14
    db $FF
    db $C2
    db $6A
    db $48
    db $08
    db $14
    db $FF
    db $C2
    db $6A
    db $D6
    db $08
    db $06
    db $FF
    db $12
    db $FF
    db $CD
    db $D9
    db $03
    db $00
    db $1B
    db $FF
    db $01
    db $00
    db $C0
    db $FF
    db $1B
    db $FF
    db $02
    db $00
    db $C0
    db $FF
    db $1B
    db $FF
    db $03
    db $00
    db $C0
    db $FF
    db $1B
    db $FF
    db $04
    db $00
    db $C0
    db $FF
    db $19
    db $FF
    db $1A
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $02
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $04
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
    db $02
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $1B
    db $FF
    db $04
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1B
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $1A
    db $FF
    db $03
    db $00
    db $F0
    db $FF
    db $1A
    db $FF
    db $04
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $4A
    db $FF
    db $01
    db $00
    db $4A
    db $FF
    db $02
    db $00
    db $4A
    db $FF
    db $03
    db $00
    db $4A
    db $FF
    db $04
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $07
    db $FF
    db $01
    db $FF
    db $11
    db $01
    db $5E
    db $6B
    db $01
    db $FF
    db $10
    db $01
    db $58
    db $6B
    db $46
    db $08
    db $47
    db $08
    db $14
    db $FF
    db $60
    db $6B
    db $49
    db $08
    db $14
    db $FF
    db $60
    db $6B
    db $D7
    db $08
    db $06
    db $FF
    db $1A
    db $FF
    db $02
    db $00
    db $10
    db $00
    db $1A
    db $FF
    db $03
    db $00
    db $10
    db $00
    db $1A
    db $FF
    db $04
    db $00
    db $10
    db $00
    db $1A
    db $FF
    db $06
    db $00
    db $F0
    db $FF
    db $1A
    db $FF
    db $07
    db $00
    db $F0
    db $FF
    db $0A
    db $FF
    db $08
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $03
    db $FF
    db $10
    db $01
    db $20
    db $FF
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Map5E Per-Script Table (map_type=$5E, 1 scripts)
; ---------------------------------------------------------------------------
Map5E_ScriptPtrTable:
    dw Map5E_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map5E_Script00
; ---------------------------------------------------------------------------
Map5E_Script00:
    dw $FF15  ; PlaySE
    dw $D99A  ; RAM $D99A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw Bank0F_ScriptAddr_6C1A          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D99A  ; RAM $D99A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw Bank0F_ScriptAddr_6C18          ; -> branch target
    dw $FF15  ; PlaySE
    dw $D99A  ; RAM $D99A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0F_ScriptAddr_6BB0          ; -> branch target
    dw $FFFF  ; END

Bank0F_ScriptAddr_6BB0:
    dw $FF24  ; Cmd24
    dw $2E07
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFD0  ; Cmd$D0
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF39  ; Cmd39
    dw $09F7
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF12  ; WriteRAM
    dw $C88A  ; RAM $C88A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF12  ; WriteRAM
    dw $C88B  ; RAM $C88B
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $C88E  ; RAM $C88E
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF26  ; Cmd26
    dw $FFFF  ; END

Bank0F_ScriptAddr_6C18:
    dw $FFFF  ; END

Bank0F_ScriptAddr_6C1A:
    dw $FF09  ; SetDelay
    dw $0028  ; Text $0028: "$42:$5474 :People who understand monster // talk a"
    dw $FF21  ; TriggerBattle2
    dw $009D
    dw $FF09  ; SetDelay
    dw $0028  ; Text $0028: "$42:$5474 :People who understand monster // talk a"
    dw $FF41  ; SetBGM
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0F  ; SetScreenScroll
    dw $002F  ; Text $002F: "$42:$5A53 *:The tournament is held on the // Starr"
    dw $0038  ; Text $0038: "$42:$5E08 *:I heard that Pulio let the // monsters"
    dw $00C8
    dw $FFFF  ; END

    db $42
    db $6C
    db $44
    db $6C
    db $72
    db $6D
    db $52
    db $6E
    db $D0
    db $6E
    db $F6
    db $6E
    db $42
    db $6F
    db $FF
    db $FF
    db $53
    db $FF
    db $08
    db $FF
    db $07
    db $FF
    db $15
    db $FF
    db $2C
    db $C9
    db $01
    db $00
    db $72
    db $6C
    db $15
    db $FF
    db $2C
    db $C9
    db $02
    db $00
    db $7A
    db $6C
    db $15
    db $FF
    db $2C
    db $C9
    db $03
    db $00
    db $82
    db $6C
    db $15
    db $FF
    db $2C
    db $C9
    db $04
    db $00
    db $8A
    db $6C
    db $C0
    db $09
    db $06
    db $FF
    db $14
    db $FF
    db $92
    db $6C
    db $C3
    db $09
    db $06
    db $FF
    db $14
    db $FF
    db $92
    db $6C
    db $C6
    db $09
    db $06
    db $FF
    db $14
    db $FF
    db $92
    db $6C
    db $C9
    db $09
    db $06
    db $FF
    db $14
    db $FF
    db $92
    db $6C
    db $CC
    db $09
    db $06
    db $FF
    db $14
    db $FF
    db $92
    db $6C
    db $52
    db $FF
    db $15
    db $FF
    db $55
    db $DB
    db $01
    db $00
    db $DC
    db $6C
    db $07
    db $FF
    db $15
    db $FF
    db $2C
    db $C9
    db $01
    db $00
    db $C4
    db $6C
    db $15
    db $FF
    db $2C
    db $C9
    db $02
    db $00
    db $CA
    db $6C
    db $15
    db $FF
    db $2C
    db $C9
    db $03
    db $00
    db $D0
    db $6C
    db $15
    db $FF
    db $2C
    db $C9
    db $04
    db $00
    db $D6
    db $6C
    db $C1
    db $09
    db $14
    db $FF
    db $1C
    db $6D
    db $C4
    db $09
    db $14
    db $FF
    db $1C
    db $6D
    db $C7
    db $09
    db $14
    db $FF
    db $1C
    db $6D
    db $CA
    db $09
    db $14
    db $FF
    db $1C
    db $6D
    db $CD
    db $09
    db $14
    db $FF
    db $1C
    db $6D
    db $07
    db $FF
    db $15
    db $FF
    db $2C
    db $C9
    db $01
    db $00
    db $04
    db $6D
    db $15
    db $FF
    db $2C
    db $C9
    db $02
    db $00
    db $0A
    db $6D
    db $15
    db $FF
    db $2C
    db $C9
    db $03
    db $00
    db $10
    db $6D
    db $15
    db $FF
    db $2C
    db $C9
    db $04
    db $00
    db $16
    db $6D
    db $C2
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $C5
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $C8
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $CB
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $CE
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $06
    db $FF
    db $2C
    db $FF
    db $2A
    db $6D
    db $2A
    db $FF
    db $1D
    db $00
    db $07
    db $FF
    db $EA
    db $09
    db $2C
    db $FF
    db $32
    db $6D
    db $54
    db $FF
    db $EB
    db $09
    db $1C
    db $FF
    db $01
    db $0D
    db $19
    db $FF
    db $FF
    db $FF
    db $55
    db $FF
    db $15
    db $FF
    db $E1
    db $D8
    db $00
    db $00
    db $46
    db $6D
    db $EC
    db $09
    db $55
    db $FF
    db $15
    db $FF
    db $E1
    db $D8
    db $00
    db $00
    db $52
    db $6D
    db $EC
    db $09
    db $56
    db $FF
    db $15
    db $FF
    db $E1
    db $D8
    db $00
    db $00
    db $5E
    db $6D
    db $ED
    db $09
    db $2C
    db $FF
    db $6A
    db $6D
    db $2A
    db $FF
    db $1D
    db $00
    db $07
    db $FF
    db $F5
    db $09
    db $1C
    db $FF
    db $01
    db $0D
    db $19
    db $FF
    db $FF
    db $FF
    db $15
    db $FF
    db $D2
    db $D7
    db $0F
    db $00
    db $7E
    db $6D
    db $53
    db $FF
    db $08
    db $FF
    db $07
    db $FF
    db $15
    db $FF
    db $2C
    db $C9
    db $01
    db $00
    db $A8
    db $6D
    db $15
    db $FF
    db $2C
    db $C9
    db $02
    db $00
    db $B0
    db $6D
    db $15
    db $FF
    db $2C
    db $C9
    db $03
    db $00
    db $B8
    db $6D
    db $15
    db $FF
    db $2C
    db $C9
    db $04
    db $00
    db $C0
    db $6D
    db $CF
    db $09
    db $06
    db $FF
    db $14
    db $FF
    db $C8
    db $6D
    db $D2
    db $09
    db $06
    db $FF
    db $14
    db $FF
    db $C8
    db $6D
    db $D5
    db $09
    db $06
    db $FF
    db $14
    db $FF
    db $C8
    db $6D
    db $D8
    db $09
    db $06
    db $FF
    db $14
    db $FF
    db $C8
    db $6D
    db $DB
    db $09
    db $06
    db $FF
    db $14
    db $FF
    db $C8
    db $6D
    db $52
    db $FF
    db $15
    db $FF
    db $55
    db $DB
    db $01
    db $00
    db $12
    db $6E
    db $07
    db $FF
    db $15
    db $FF
    db $2C
    db $C9
    db $01
    db $00
    db $FA
    db $6D
    db $15
    db $FF
    db $2C
    db $C9
    db $02
    db $00
    db $00
    db $6E
    db $15
    db $FF
    db $2C
    db $C9
    db $03
    db $00
    db $06
    db $6E
    db $15
    db $FF
    db $2C
    db $C9
    db $04
    db $00
    db $0C
    db $6E
    db $D0
    db $09
    db $14
    db $FF
    db $1C
    db $6D
    db $D3
    db $09
    db $14
    db $FF
    db $1C
    db $6D
    db $D6
    db $09
    db $14
    db $FF
    db $1C
    db $6D
    db $D9
    db $09
    db $14
    db $FF
    db $1C
    db $6D
    db $DC
    db $09
    db $14
    db $FF
    db $1C
    db $6D
    db $07
    db $FF
    db $15
    db $FF
    db $2C
    db $C9
    db $01
    db $00
    db $3A
    db $6E
    db $15
    db $FF
    db $2C
    db $C9
    db $02
    db $00
    db $40
    db $6E
    db $15
    db $FF
    db $2C
    db $C9
    db $03
    db $00
    db $46
    db $6E
    db $15
    db $FF
    db $2C
    db $C9
    db $04
    db $00
    db $4C
    db $6E
    db $D1
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $D4
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $D7
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $DA
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $DD
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $DE
    db $09
    db $06
    db $FF
    db $52
    db $FF
    db $15
    db $FF
    db $55
    db $DB
    db $01
    db $00
    db $C8
    db $6E
    db $07
    db $FF
    db $DF
    db $09
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
    db $1C
    db $FF
    db $01
    db $0D
    db $19
    db $FF
    db $FF
    db $FF
    db $07
    db $FF
    db $E0
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $E1
    db $09
    db $06
    db $FF
    db $52
    db $FF
    db $15
    db $FF
    db $55
    db $DB
    db $01
    db $00
    db $EE
    db $6E
    db $07
    db $FF
    db $E2
    db $09
    db $06
    db $FF
    db $58
    db $FF
    db $1C
    db $FF
    db $01
    db $0D
    db $19
    db $FF
    db $FF
    db $FF
    db $07
    db $FF
    db $E3
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $E4
    db $09
    db $06
    db $FF
    db $52
    db $FF
    db $15
    db $FF
    db $55
    db $DB
    db $01
    db $00
    db $3A
    db $6F
    db $07
    db $FF
    db $E5
    db $09
    db $59
    db $FF
    db $00
    db $00
    db $15
    db $FF
    db $E1
    db $D8
    db $FF
    db $00
    db $32
    db $6F
    db $EE
    db $09
    db $59
    db $FF
    db $01
    db $00
    db $15
    db $FF
    db $E1
    db $D8
    db $FF
    db $00
    db $32
    db $6F
    db $EE
    db $09
    db $59
    db $FF
    db $02
    db $00
    db $15
    db $FF
    db $E1
    db $D8
    db $FF
    db $00
    db $32
    db $6F
    db $EE
    db $09
    db $1C
    db $FF
    db $01
    db $0D
    db $19
    db $FF
    db $FF
    db $FF
    db $07
    db $FF
    db $E6
    db $09
    db $14
    db $FF
    db $3A
    db $6D
    db $E7
    db $09
    db $06
    db $FF
    db $52
    db $FF
    db $15
    db $FF
    db $55
    db $DB
    db $01
    db $00
    db $68
    db $6F
    db $07
    db $FF
    db $E8
    db $09
    db $2C
    db $FF
    db $60
    db $6F
    db $57
    db $FF
    db $EB
    db $09
    db $14
    db $FF
    db $54
    db $6F
    db $1C
    db $FF
    db $01
    db $0D
    db $19
    db $FF
    db $FF
    db $FF
    db $07
    db $FF
    db $E9
    db $09
    db $14
    db $FF
    db $3A
    db $6D
; ---------------------------------------------------------------------------
; Map5F Per-Script Table (map_type=$5F, 0 scripts)
; ---------------------------------------------------------------------------
Map5F_ScriptPtrTable:
    dw Map53_Script00                  ; -> branch target
; ---------------------------------------------------------------------------
; Map53_Script00
; ---------------------------------------------------------------------------
Map53_Script00:
    dw $FFFF  ; END

    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
