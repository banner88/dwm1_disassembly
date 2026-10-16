; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $00f", ROMX[$4000], BANK[$f]

    db $0f ;ROM BANK

    dw LoadScriptRoomData
    dw ScriptBank0FDrawTiles
    dw ScriptBank0FDrawAttrs

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
ScriptBank0FDrawTiles:
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

; S118: script op $61 draw_attrs (ScriptCmd61_DrawAttrs, entry 2): like entry 1
; it reads ONE more script word (a patch address in this bank) and writes the
; patch to VRAM bank 1 (the BG attributes) on GBC.
ScriptBank0FDrawAttrs:
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
    dw Map5F_ScriptPtrTable ; map type $00: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $01: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $02: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $03: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $04: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $05: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $06: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $07: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $08: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $09: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $0A: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $0B: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $0C: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $0D: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $0E: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $0F: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $10: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $11: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $12: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $13: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $14: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $15: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $16: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $17: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $18: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $19: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $1A: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $1B: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $1C: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $1D: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $1E: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $1F: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $20: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $21: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $22: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $23: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $24: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $25: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $26: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $27: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $28: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $29: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $2A: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $2B: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $2C: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $2D: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $2E: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $2F: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $30: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $31: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $32: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $33: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $34: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $35: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $36: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $37: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $38: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $39: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $3A: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $3B: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $3C: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $3D: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $3E: another bank's — filler, never read here
    dw Map5F_ScriptPtrTable ; map type $3F: another bank's — filler, never read here
    dw Map40_ScriptPtrTable ; map type $40: KingSlime Decision Room (3 doors)
    dw Map41_ScriptPtrTable ; map type $41: Boss: Medal (Lipsy variant)
    dw Map42_ScriptPtrTable ; map type $42: Labyrinth
    dw Map43_ScriptPtrTable ; map type $43: Boss: Judgment (Akubar)
    dw Map44_ScriptPtrTable ; map type $44: Boss: Library (Orochi)
    dw Map45_ScriptPtrTable ; map type $45: Boss: Reflection (Durran)
    dw BossAmbition_ScriptPtrTable ; map type $46: Boss: Ambition (DracoLord)
    dw Map47_ScriptPtrTable ; map type $47: Boss: Demolition (Hargon/Sidoh)
    dw Map48_ScriptPtrTable ; map type $48: Boss: Mastermind (Baramos)
    dw Map49_ScriptPtrTable ; map type $49: Boss: Control (Zoma)
    dw Map4A_ScriptPtrTable ; map type $4A: Boss: Extinction (Pizzaro)
    dw Map4B_ScriptPtrTable ; map type $4B: Boss: Sleep (Esterk)
    dw Map4C_ScriptPtrTable ; map type $4C: Boss: Bazaar Edge (Mirudraas)
    dw Map4D_ScriptPtrTable ; map type $4D: Boss: Arena Right (Mudou)
    dw Map4E_ScriptPtrTable ; map type $4E: Boss: Grandpa's Gate (DeathMore)
    dw BossUnused_ScriptPtrTable ; map type $4F: Boss: Unused (DarkDrium)
    dw Map50_ScriptPtrTable ; map type $50: Gate Floor: Item Shop
    dw Map51_ScriptPtrTable ; map type $51: Gate Floor: Priest
    dw Map52_ScriptPtrTable ; map type $52: Gate Floor: Coliseum
    dw Map53_ScriptPtrTable ; map type $53: Forest Maze
    dw Map54_ScriptPtrTable ; map type $54: Conveyor Maze 1
    dw Map54_ScriptPtrTable ; map type $55: Conveyor Maze 2
    dw Map54_ScriptPtrTable ; map type $56: Conveyor Maze 3
    dw Map57_ScriptPtrTable ; map type $57: Maze 1
    dw Map57_ScriptPtrTable ; map type $58: Maze 2
    dw Map57_ScriptPtrTable ; map type $59: Maze 3
    dw Map5A_ScriptPtrTable ; map type $5A: Gate Floor: 6 Chests Diagonal
    dw Map5B_ScriptPtrTable ; map type $5B: Gate Floor: 6 Chests Rows
    dw Map5C_ScriptPtrTable ; map type $5C: Gate Floor: 8 Chests Rows
    dw Map5D_ScriptPtrTable ; map type $5D: Arena Battle
    dw Map5E_ScriptPtrTable ; map type $5E: Arena Setup Room (white, 2 Terrys)
    dw Map5F_ScriptPtrTable ; map type $5F: Gate Floor: Item Shop (unused copy)
    dw Map42_ScriptPtrTable ; map type $60: Labyrinth Final
    dw Map53_ScriptPtrTable ; map type $61: Forest Maze Gate Floor 1
    dw Map53_ScriptPtrTable ; map type $62: Forest Maze Gate Floor 2
    dw Map53_ScriptPtrTable ; map type $63: Forest Maze Gate Floor 3
    dw Map53_ScriptPtrTable ; map type $64: Forest Maze Gate Floor 4
    dw Map42_ScriptPtrTable ; map type $65: Unnamed game room
    dw Map42_ScriptPtrTable ; map type $66: Unnamed game room
    dw Map42_ScriptPtrTable ; map type $67: Unnamed game room
    dw Map42_ScriptPtrTable ; map type $68: Unnamed game room
    dw Map42_ScriptPtrTable ; map type $69: Unnamed game room
    dw Map42_ScriptPtrTable ; map type $6A: Unnamed game room
    dw Map42_ScriptPtrTable ; map type $6B: your room
    dw Map42_ScriptPtrTable ; map type $6C: your room
    dw Map42_ScriptPtrTable ; map type $6D: your room
    dw Map42_ScriptPtrTable ; map type $6E: your room
    dw Map42_ScriptPtrTable ; map type $6F: your room
    dw $6C34                ; map type $70: your room
; ---------------------------------------------------------------------------
; Map40 Per-Script Table (map_type=$40, 9 scripts)
; ---------------------------------------------------------------------------
Map40_ScriptPtrTable:
    dw Map40_Script00       ; script 0
    dw Map40_Script01       ; script 1
    dw Map40_Script02       ; script 2
    dw Map40_Script03       ; script 3
    dw Map40_Script04       ; script 4
    dw Map40_Script05       ; script 5
    dw Map40_Script06       ; script 6
    dw Map40_Script07       ; script 7
    dw Map40_Script08       ; script 8
; ---------------------------------------------------------------------------
; Map40_Script00
; ---------------------------------------------------------------------------
Map40_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map40_Script01
; ---------------------------------------------------------------------------
Map40_Script01:
    dw $054E                ; text $054E: "[HERO] read the posting. :Once you go in…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map40_Script02
; ---------------------------------------------------------------------------
Map40_Script02:
    dw $054F                ; text $054F: "[HERO] read the posting. :Wanted! Happy …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map40_Script03
; ---------------------------------------------------------------------------
Map40_Script03:
    dw $FF01                ; $01 if_flag_set: If flag $0021 is set → Bank0F_ScriptAddr_42D0
    dw $0021                ;   flag
    dw Bank0F_ScriptAddr_42D0 ;   target
    dw $0550                ; text $0550: "*:Hi! We go sip. Sip here!"
    dw $FFFF                ; END

Bank0F_ScriptAddr_42D0:
    dw $0553                ; text $0553: "*:You're really too much. But there's no…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map40_Script04
; ---------------------------------------------------------------------------
Map40_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $0021 is set → Bank0F_ScriptAddr_42DE
    dw $0021                ;   flag
    dw Bank0F_ScriptAddr_42DE ;   target
    dw $0551                ; text $0551: "*:Boss! You can feel like a king with ji…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_42DE:
    dw $0554                ; text $0554: "*:Boss! You are so strong! But there's n…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map40_Script05
; ---------------------------------------------------------------------------
Map40_Script05:
    dw $FF01                ; $01 if_flag_set: If flag $0021 is set → Bank0F_ScriptAddr_42EC
    dw $0021                ;   flag
    dw Bank0F_ScriptAddr_42EC ;   target
    dw $0552                ; text $0552: "*:Please let the sweet aroma relax you!"
    dw $FFFF                ; END

Bank0F_ScriptAddr_42EC:
    dw $0555                ; text $0555: "*:I see you have lots of special skills!…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map40_Script06
; ---------------------------------------------------------------------------
Map40_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $0021 is set → Bank0F_ScriptAddr_42FC
    dw $0021                ;   flag
    dw Bank0F_ScriptAddr_42FC ;   target
    dw $FF12                ; $12 write_ram: Room state of Boss: Medal (Lipsy variant) screen 0 → state 0  [$D987 := 0]
    dw $D987                ;   address
    dw $0000                ;   value
Bank0F_ScriptAddr_42FC:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map40_Script07
; ---------------------------------------------------------------------------
Map40_Script07:
    dw $FF01                ; $01 if_flag_set: If flag $0021 is set → Bank0F_ScriptAddr_430A
    dw $0021                ;   flag
    dw Bank0F_ScriptAddr_430A ;   target
    dw $FF12                ; $12 write_ram: Room state of Boss: Medal (Lipsy variant) screen 0 → state 1  [$D987 := 1]
    dw $D987                ;   address
    dw $0001                ;   value
Bank0F_ScriptAddr_430A:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map40_Script08
; ---------------------------------------------------------------------------
Map40_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $0021 is set → Bank0F_ScriptAddr_4318
    dw $0021                ;   flag
    dw Bank0F_ScriptAddr_4318 ;   target
    dw $FF12                ; $12 write_ram: Room state of Boss: Medal (Lipsy variant) screen 0 → state 2  [$D987 := 2]
    dw $D987                ;   address
    dw $0002                ;   value
Bank0F_ScriptAddr_4318:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map41 Per-Script Table (map_type=$41, 4 scripts)
; ---------------------------------------------------------------------------
Map41_ScriptPtrTable:
    dw Map41_Script00       ; script 0
    dw Map41_Script01       ; script 1
    dw Map41_Script02       ; script 2
    dw Map41_Script03       ; script 3
; ---------------------------------------------------------------------------
; Map41_Script00
; ---------------------------------------------------------------------------
Map41_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map41_Script01
; ---------------------------------------------------------------------------
Map41_Script01:
    dw $0556                ; text $0556: "*:Mmm... sip sip! Here I come!"
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 156 (boss)
    dw $009C                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0557                ; text $0557: "*:Wow! You really impressed me!"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 8, curve 2  [$D8E3 := $0208]
    dw $D8E3                ;   address
    dw $0208                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-left (the flight path set above)
    dw $1502                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $055E                ; text $055E: "Watabou:Had a good time!? We got to get …"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 65  [$D9E3 := 65]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0041                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0021
    dw $0021                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 2  [$D95E := 2]
    dw $D95E                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Medal (Lipsy variant) screen 0 → state 3  [$D987 := 3]
    dw $D987                ;   address
    dw $0003                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $00EE is clear → Bank0F_ScriptAddr_43DA
    dw $00EE                ;   flag
    dw Bank0F_ScriptAddr_43DA ;   target
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 5  [$D95E := 5]
    dw $D95E                ;   address
    dw $0005                ;   value
Bank0F_ScriptAddr_43DA:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map41_Script02
; ---------------------------------------------------------------------------
Map41_Script02:
    dw $0559                ; text $0559: "*:Now, sleep tight on my arms...!"
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 153 (boss)
    dw $0099                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $055A                ; text $055A: "*:Oh, you were great. Giggle..."
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 5, curve 1  [$D8E3 := $0105]
    dw $D8E3                ;   address
    dw $0105                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-left (the flight path set above)
    dw $1502                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $055B                ; text $055B: "Watabou:Had a good time!? We got to get …"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 65  [$D9E3 := 65]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0041                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0021
    dw $0021                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 2  [$D95E := 2]
    dw $D95E                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Medal (Lipsy variant) screen 0 → state 3  [$D987 := 3]
    dw $D987                ;   address
    dw $0003                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $00EE is clear → Bank0F_ScriptAddr_448E
    dw $00EE                ;   flag
    dw Bank0F_ScriptAddr_448E ;   target
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 5  [$D95E := 5]
    dw $D95E                ;   address
    dw $0005                ;   value
Bank0F_ScriptAddr_448E:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map41_Script03
; ---------------------------------------------------------------------------
Map41_Script03:
    dw $055C                ; text $055C: "*:I'll let you sleep with my SleepAir...…"
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 155 (boss)
    dw $009B                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $055D                ; text $055D: "*:You're strong! If this is a dream, ple…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 2, curve 3  [$D8E3 := $0302]
    dw $D8E3                ;   address
    dw $0302                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-left (the flight path set above)
    dw $1502                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0558                ; text $0558: "Watabou:Had a good time!? We've got to g…"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 65  [$D9E3 := 65]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0041                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0021
    dw $0021                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 2  [$D95E := 2]
    dw $D95E                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Medal (Lipsy variant) screen 0 → state 3  [$D987 := 3]
    dw $D987                ;   address
    dw $0003                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $00EE is clear → Bank0F_ScriptAddr_4542
    dw $00EE                ;   flag
    dw Bank0F_ScriptAddr_4542 ;   target
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 5  [$D95E := 5]
    dw $D95E                ;   address
    dw $0005                ;   value
Bank0F_ScriptAddr_4542:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map42 Per-Script Table (map_type=$42, 19 scripts)
; ---------------------------------------------------------------------------
Map42_ScriptPtrTable:
    dw Map42_Script00       ; script 0
    dw Map42_Script01       ; script 1
    dw Map42_Script02       ; script 2
    dw Map42_Script03       ; script 3
    dw Map42_Script04       ; script 4
    dw Map42_Script05       ; script 5
    dw Map42_Script06       ; script 6
    dw Map42_Script07       ; script 7
    dw Map42_Script08       ; script 8
    dw Map42_Script09       ; script 9
    dw Map42_Script10       ; script 10
    dw Map42_Script10       ; script 11
    dw Map42_Script10       ; script 12
    dw Map42_Script10       ; script 13
    dw Map42_Script10       ; script 14
    dw Map42_Script10       ; script 15
    dw Map42_Script16       ; script 16
    dw Map42_Script17       ; script 17
    dw Map42_Script18       ; script 18
; ---------------------------------------------------------------------------
; Map42_Script00
; ---------------------------------------------------------------------------
Map42_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script01
; ---------------------------------------------------------------------------
Map42_Script01:
    dw $FF12                ; $12 write_ram: The current step of a multi-step screen: 1  [$D9E9 := 1]
    dw $D9E9                ;   address
    dw $0001                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script02
; ---------------------------------------------------------------------------
Map42_Script02:
    dw $FF12                ; $12 write_ram: The current step of a multi-step screen: 2  [$D9E9 := 2]
    dw $D9E9                ;   address
    dw $0002                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script03
; ---------------------------------------------------------------------------
Map42_Script03:
    dw $FF12                ; $12 write_ram: The current step of a multi-step screen: 3  [$D9E9 := 3]
    dw $D9E9                ;   address
    dw $0003                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script04
; ---------------------------------------------------------------------------
Map42_Script04:
    dw $FF12                ; $12 write_ram: The current step of a multi-step screen: 4  [$D9E9 := 4]
    dw $D9E9                ;   address
    dw $0004                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script05
; ---------------------------------------------------------------------------
Map42_Script05:
    dw $FF12                ; $12 write_ram: The current step of a multi-step screen: 5  [$D9E9 := 5]
    dw $D9E9                ;   address
    dw $0005                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script06
; ---------------------------------------------------------------------------
Map42_Script06:
    dw $FF12                ; $12 write_ram: The current step of a multi-step screen: 6  [$D9E9 := 6]
    dw $D9E9                ;   address
    dw $0006                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script07
; ---------------------------------------------------------------------------
Map42_Script07:
    dw $FF12                ; $12 write_ram: The current step of a multi-step screen: 7  [$D9E9 := 7]
    dw $D9E9                ;   address
    dw $0007                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script08
; ---------------------------------------------------------------------------
Map42_Script08:
    dw $FF12                ; $12 write_ram: The current step of a multi-step screen: 8  [$D9E9 := 8]
    dw $D9E9                ;   address
    dw $0008                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script09
; ---------------------------------------------------------------------------
Map42_Script09:
    dw $FF12                ; $12 write_ram: The current step of a multi-step screen: 9  [$D9E9 := 9]
    dw $D9E9                ;   address
    dw $0009                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script10
; ---------------------------------------------------------------------------
Map42_Script10:
    dw $FF12                ; $12 write_ram: The current step of a multi-step screen: 0  [$D9E9 := 0]
    dw $D9E9                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script16
; ---------------------------------------------------------------------------
Map42_Script16:
    dw $FF01                ; $01 if_flag_set: If flag $00D5 is set → Bank0F_ScriptAddr_45E2
    dw $00D5                ;   flag
    dw Bank0F_ScriptAddr_45E2 ;   target
    dw $0561                ; text $0561: "[HERO] checked out a treasure chest. The…"
    dw $FF03                ; $03 set_flag: Set flag $00D5
    dw $00D5                ;   flag
    dw $FFFF                ; END

Bank0F_ScriptAddr_45E2:
    dw $0562                ; text $0562: "Mimic continues to stick his tongue out."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map42_Script17
; ---------------------------------------------------------------------------
Map42_Script17:
    dw $FF01                ; $01 if_flag_set: If flag $00D6 is set → Bank0F_ScriptAddr_46A2
    dw $00D6                ;   flag
    dw Bank0F_ScriptAddr_46A2 ;   target
    dw $0563                ; text $0563: "*:Bleat bleat. I cannot believe that you…"
    dw $FF03                ; $03 set_flag: Set flag $00D6
    dw $00D6                ;   flag
Bank0F_ScriptAddr_45F2:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 175 (boss)
    dw $00AF                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0565                ; text $0565: "*:Bleat bleat. I never imagined such a s…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 6, curve 4  [$D8E3 := $0406]
    dw $D8E3                ;   address
    dw $0406                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-right (the flight path set above)
    dw $1602                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0566                ; text $0566: "Watabou:You think the doll looks just li…"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 66  [$D9E3 := 66]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0042                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0022
    dw $0022                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Labyrinth/Judgment screen 0 → state 1  [$D96F := 1]
    dw $D96F                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Labyrinth screen 1 (+1 room variant(s) sharing it) → state 1  [$D989 := 1]
    dw $D989                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0023 is clear → Bank0F_ScriptAddr_4696
    dw $0023                ;   flag
    dw Bank0F_ScriptAddr_4696 ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Labyrinth/Judgment screen 0 → state 3  [$D96F := 3]
    dw $D96F                ;   address
    dw $0003                ;   value
Bank0F_ScriptAddr_4696:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_46A2:
    dw $0564                ; text $0564: "*:Bleat bleat. Welcome to a dead end, bl…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_45F2
    dw Bank0F_ScriptAddr_45F2 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map42_Script18
; ---------------------------------------------------------------------------
Map42_Script18:
    dw $FF01                ; $01 if_flag_set: If flag $00D4 is set → Bank0F_ScriptAddr_46C8
    dw $00D4                ;   flag
    dw Bank0F_ScriptAddr_46C8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $011B is set → Bank0F_ScriptAddr_46BE
    dw $011B                ;   flag
    dw Bank0F_ScriptAddr_46BE ;   target
    dw $0842                ; text $0842: "Watabou:... ..."
    dw $FF03                ; $03 set_flag: Set flag $011B
    dw $011B                ;   flag
    dw $FFFF                ; END

Bank0F_ScriptAddr_46BE:
    dw $0842                ; text $0842: "Watabou:... ..."
    dw $055F                ; text $055F: "Watabou didn't reply."
    dw $FF03                ; $03 set_flag: Set flag $00D4
    dw $00D4                ;   flag
    dw $FFFF                ; END

Bank0F_ScriptAddr_46C8:
    dw $0842                ; text $0842: "Watabou:... ..."
    dw $0560                ; text $0560: "It was a Watabou doll!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map43 Per-Script Table (map_type=$43, 3 scripts)
; ---------------------------------------------------------------------------
Map43_ScriptPtrTable:
    dw Map43_Script00       ; script 0
    dw Map43_Script01       ; script 1
    dw Map43_Script02       ; script 2
; ---------------------------------------------------------------------------
; Map43_Script00
; ---------------------------------------------------------------------------
Map43_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map43_Script01
; ---------------------------------------------------------------------------
Map43_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00D7 is set → Bank0F_ScriptAddr_46EE
    dw $00D7                ;   flag
    dw Bank0F_ScriptAddr_46EE ;   target
    dw $0571                ; text $0571: "[HERO] touched the blade of the guilloti…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_46EE:
    dw $0572                ; text $0572: "[HERO] touched the blade of the guilloti…"
    dw $FF03                ; $03 set_flag: Set flag $00D8
    dw $00D8                ;   flag
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map43_Script02
; ---------------------------------------------------------------------------
Map43_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $00D8 is set → Bank0F_ScriptAddr_472E
    dw $00D8                ;   flag
    dw Bank0F_ScriptAddr_472E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00D7 is set → Bank0F_ScriptAddr_4726
    dw $00D7                ;   flag
    dw Bank0F_ScriptAddr_4726 ;   target
    dw $0567                ; text $0567: "*:You abused monsters cruelly and wiped …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0F_ScriptAddr_4714  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_4714 ;   target
    dw $0568                ; text $0568: "*:If you cannot learn by listening to me…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_473E
    dw Bank0F_ScriptAddr_473E ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_4714:
    dw $0569                ; text $0569: "*:You recognize your sin, right? Now her…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0F_ScriptAddr_4726  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_4726 ;   target
    dw $056A                ; text $056A: "*:If you cannot learn by listening to me…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_473E
    dw Bank0F_ScriptAddr_473E ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_4726:
    dw $056B                ; text $056B: "*:Now we're holding a public execution o…"
    dw $FF03                ; $03 set_flag: Set flag $00D7
    dw $00D7                ;   flag
    dw $FFFF                ; END

Bank0F_ScriptAddr_472E:
    dw $056C                ; text $056C: "*:What? You have something to say before…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0F_ScriptAddr_473C  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_473C ;   target
    dw $056E                ; text $056E: "*:Then die!"
    dw $FFFF                ; END

Bank0F_ScriptAddr_473C:
    dw $056D                ; text $056D: "*:None of your cheek! If you don't like …"
Bank0F_ScriptAddr_473E:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 177 (boss)
    dw $00B1                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $056F                ; text $056F: "*:You want to have additional sins?"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 2, curve 3  [$D8E3 := $0302]
    dw $D8E3                ;   address
    dw $0302                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0570                ; text $0570: "Watabou:[HERO]'s monsters trust you, [HE…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 67  [$D9E3 := 67]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0043                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0023
    dw $0023                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Labyrinth/Judgment screen 0 → state 2  [$D96F := 2]
    dw $D96F                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Judgment (Akubar) screen 0 → state 1  [$D98A := 1]
    dw $D98A                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0022 is clear → Bank0F_ScriptAddr_47E2
    dw $0022                ;   flag
    dw Bank0F_ScriptAddr_47E2 ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Labyrinth/Judgment screen 0 → state 3  [$D96F := 3]
    dw $D96F                ;   address
    dw $0003                ;   value
Bank0F_ScriptAddr_47E2:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map44 Per-Script Table (map_type=$44, 3 scripts)
; ---------------------------------------------------------------------------
Map44_ScriptPtrTable:
    dw Map44_Script00       ; script 0
    dw Map44_Script01       ; script 1
    dw Map44_Script02       ; script 2
; ---------------------------------------------------------------------------
; Map44_Script00
; ---------------------------------------------------------------------------
Map44_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map44_Script01
; ---------------------------------------------------------------------------
Map44_Script01:
    dw $0573                ; text $0573: "*:Aaaarrrggh! Gwrrrr... *:Gwrrggg..."
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 179 (boss)
    dw $00B3                ;   enemy
    dw $FF01                ; $01 if_flag_set: If flag $00AA is set → Bank0F_ScriptAddr_4B24
    dw $00AA                ;   flag
    dw Bank0F_ScriptAddr_4B24 ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0576                ; text $0576: "*:Aaarrrggh... *:I can't stand it. I jus…"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 3: hop
    dw $0103                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 3: hop
    dw $0103                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 3: hop
    dw $0103                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 3: hop
    dw $0103                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 3: hop
    dw $0103                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 3: jump
    dw $0403                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $6E
    dw $006E                ;   sound
    dw $FF13                ; $13 write_ram2: Shake the screen: 2 up/down, 4 left/right  [$C8B1 := $0402]
    dw $C8B1                ;   address
    dw $0402                ;   value
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 4 walks left 2 tiles
    dw $0004                ;   actor
    dw $FFE0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks left 2 tiles
    dw $0005                ;   actor
    dw $FFE0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 6 walks left 2 tiles
    dw $0006                ;   actor
    dw $FFE0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 6 walks down 1 tile
    dw $0006                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 7 walks left 1 tile
    dw $0007                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 7 walks down 1 tile
    dw $0007                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF49                ; $49 face_left: NPC 5 faces left
    dw $0005                ;   actor
    dw $FF48                ; $48 face_down: NPC 6 faces down
    dw $0006                ;   actor
    dw $FF48                ; $48 face_down: NPC 7 faces down
    dw $0007                ;   actor
    dw $FF10                ; $10 walk_to_x: the player walks to x = 88 px (script waits)
    dw $0000                ;   actor
    dw $0058                ;   x
    dw $FF1B                ; $1B npc_walk_y: the player walks down 2 tiles
    dw $0000                ;   actor
    dw $0020                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: leap 5 tiles right
    dw $0501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 24 px (script waits)
    dw $0001                ;   actor
    dw $FFE8                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 2 tiles
    dw $0001                ;   actor
    dw $FFE0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 12 px
    dw $0001                ;   actor
    dw $000C                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 12 px
    dw $0001                ;   actor
    dw $FFF4                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 12 px
    dw $0001                ;   actor
    dw $000C                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 12 px
    dw $0001                ;   actor
    dw $FFF4                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 12 px
    dw $0001                ;   actor
    dw $000C                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 12 px
    dw $0001                ;   actor
    dw $FFF4                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 12 px
    dw $0001                ;   actor
    dw $000C                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 12 px
    dw $0001                ;   actor
    dw $FFF4                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $6E
    dw $006E                ;   sound
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 2 tiles
    dw $0001                ;   actor
    dw $0020                ;   pixels
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 1-3-2-0 (0 light … 3 dark)  [$C89B := 45]
    dw $C89B                ;   address
    dw $002D                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): all black  [$C89D := 255]
    dw $C89D                ;   address
    dw $00FF                ;   value
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 2-0-2-3 (0 light … 3 dark)  [$C89D := 226]
    dw $C89D                ;   address
    dw $00E2                ;   value
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 1-3-2-0 (0 light … 3 dark)  [$C89B := 45]
    dw $C89B                ;   address
    dw $002D                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): all black  [$C89D := 255]
    dw $C89D                ;   address
    dw $00FF                ;   value
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 2-0-2-3 (0 light … 3 dark)  [$C89D := 226]
    dw $C89D                ;   address
    dw $00E2                ;   value
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 1-3-2-0 (0 light … 3 dark)  [$C89B := 45]
    dw $C89B                ;   address
    dw $002D                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): all black  [$C89D := 255]
    dw $C89D                ;   address
    dw $00FF                ;   value
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 2-0-2-3 (0 light … 3 dark)  [$C89D := 226]
    dw $C89D                ;   address
    dw $00E2                ;   value
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF1A                ; $1A npc_walk_x: the player walks left 2 tiles
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF21                ; $21 sound: Sound effect $68
    dw $0068                ;   sound
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 3: vanish (flicker out)
    dw $0D03                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $00
    dw $0000                ;   sound
    dw $FF1B                ; $1B npc_walk_y: the player walks up 2 tiles
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 8 is hidden
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4 is hidden
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 6 is hidden
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 7 is hidden
    dw $0007                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 2 tiles (script waits)
    dw $0000                ;   actor
    dw $0020                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: the player walks down 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0577                ; text $0577: "*:Look... this sword... *:It's the Kusan…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0F_ScriptAddr_4A60  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_4A60 ;   target
    dw $0578                ; text $0578: "*:So long! The Orochi won't trouble you …"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_4A62
    dw Bank0F_ScriptAddr_4A62 ;   target
Bank0F_ScriptAddr_4A60:
    dw $0579                ; text $0579: "*:What? You want to know why I am lookin…"
Bank0F_ScriptAddr_4A62:
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 2 tiles (script waits)
    dw $0001                ;   actor
    dw $0020                ;   pixels
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF1C                ; $1C trigger_anim: NPC 1: leap 5 tiles left
    dw $1901                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3: stands still (status cleared)  [slot +$05 := $00]
    dw $0003                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 3  [$D8E3 := $0304]
    dw $D8E3                ;   address
    dw $0304                ;   value
Bank0F_ScriptAddr_4A94:
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-left (the flight path set above)
    dw $1502                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF01                ; $01 if_flag_set: If flag $00AA is set → Bank0F_ScriptAddr_4AD0
    dw $00AA                ;   flag
    dw Bank0F_ScriptAddr_4AD0 ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $057A                ; text $057A: "Watabou:Oh, you were saved by somebody. …"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_4AD4
    dw Bank0F_ScriptAddr_4AD4 ;   target
Bank0F_ScriptAddr_4AD0:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0575                ; text $0575: "Watabou:[HERO]! Let's go."
Bank0F_ScriptAddr_4AD4:
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF03                ; $03 set_flag: Set flag $0024
    dw $0024                ;   flag
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 68  [$D9E3 := 68]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0044                ;   value
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Library Gate Room screen 0 → state 1  [$D95D := 1]
    dw $D95D                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Library (Orochi) screen 0 → state 1  [$D98B := 1]
    dw $D98B                ;   address
    dw $0001                ;   value
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_4B24:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0574                ; text $0574: "*:Gwwrrggg..."
    dw $FF0D                ; $0D npc_write: NPC 3: stands still (status cleared)  [slot +$05 := $00]
    dw $0003                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 3, curve 2  [$D8E3 := $0203]
    dw $D8E3                ;   address
    dw $0203                ;   value
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_4A94
    dw Bank0F_ScriptAddr_4A94 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map44_Script02
; ---------------------------------------------------------------------------
Map44_Script02:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map45 Per-Script Table (map_type=$45, 2 scripts)
; ---------------------------------------------------------------------------
Map45_ScriptPtrTable:
    dw Map45_Script00       ; script 0
    dw Map45_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map45_Script00
; ---------------------------------------------------------------------------
Map45_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF15                ; $15 check_and_branch: If “the room state of Boss: Reflection (Durran) screen 0” is state 0 → Bank0F_ScriptAddr_4B6A  [$D98C = 0]
    dw $D98C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_4B6A ;   target
    dw $FF15                ; $15 check_and_branch: If “the room state of Boss: Reflection (Durran) screen 0” is state 1 → Bank0F_ScriptAddr_503C  [$D98C = 1]
    dw $D98C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_503C ;   target
    dw $FF15                ; $15 check_and_branch: If “the room state of Boss: Reflection (Durran) screen 0” is state 2 → Bank0F_ScriptAddr_4B6A  [$D98C = 2]
    dw $D98C                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_4B6A ;   target
    dw $FFFF                ; END

Bank0F_ScriptAddr_4B6A:
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF01                ; $01 if_flag_set: If flag $00AB is set → Bank0F_ScriptAddr_5016
    dw $00AB                ;   flag
    dw Bank0F_ScriptAddr_5016 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00AA is set → Bank0F_ScriptAddr_4F6E
    dw $00AA                ;   flag
    dw Bank0F_ScriptAddr_4F6E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00A9 is set → Bank0F_ScriptAddr_4C04
    dw $00A9                ;   flag
    dw Bank0F_ScriptAddr_4C04 ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $046D                ; text $046D: "*:How do you do? I am the guardian here.…"
    dw $FF03                ; $03 set_flag: Set flag $00A9
    dw $00A9                ;   flag
    dw $FF06                ; $06 close_text: Close the open text box
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
    dw $FF4D                ; $4D long_delay: Wait 2 frames
    dw $0002                ;   frames
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
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
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $046E                ; text $046E: "Durran:Here, fight to your heart's conte…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_4C7A
    dw Bank0F_ScriptAddr_4C7A ;   target
Bank0F_ScriptAddr_4C04:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $046F                ; text $046F: "Durran:Hmm. You came back again. Fight w…"
    dw $FF06                ; $06 close_text: Close the open text box
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
    dw $FF4D                ; $4D long_delay: Wait 2 frames
    dw $0002                ;   frames
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
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
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0470                ; text $0470: "Durran:Here, fight to your heart's conte…"
Bank0F_ScriptAddr_4C7A:
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF13                ; $13 write_ram2: The battle: enemy 1: 342  [$DA03 := $0156]
    dw $DA03                ;   address
    dw $0156                ;   value
    dw $FF13                ; $13 write_ram2: The battle: enemy 2: 342  [$DA05 := $0156]
    dw $DA05                ;   address
    dw $0156                ;   value
    dw $FF12                ; $12 write_ram: The battle: number of enemies: 2 enemies  [$DA02 := 1]
    dw $DA02                ;   address
    dw $0001                ;   value
    dw $FF20                ; $20 start_battle: Start the battle set up above (enemies / count)
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0471                ; text $0471: "Durran:Ha ha ha! You defeated them easil…"
    dw $FF1C                ; $1C trigger_anim: NPC 4: appear (flicker in)
    dw $0804                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
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
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
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
    dw $FF4D                ; $4D long_delay: Wait 2 frames
    dw $0002                ;   frames
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
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
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0472                ; text $0472: "Durran:Let me introduce him to you. He's…"
    dw $FF03                ; $03 set_flag: Set flag $00AA
    dw $00AA                ;   flag
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF05                ; $05 battle: Battle: enemy row 343
    dw $0157                ;   enemy
Bank0F_ScriptAddr_4D4A:
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 4: vanish (flicker out)
    dw $0D04                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 4: x low byte := 56
    dw $0004                ;   actor
    dw $0018                ;   field
    dw $0038                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4: y low byte := 72
    dw $0004                ;   actor
    dw $001A                ;   field
    dw $0048                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0D                ; $0D npc_write: NPC 4: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0004                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 4: appear (flicker in)
    dw $0804                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0475                ; text $0475: "Durran:Ha ha ha! How easily you defeated…"
    dw $FF1C                ; $1C trigger_anim: NPC 7: float up 1 tile
    dw $0E07                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1C                ; $1C trigger_anim: NPC 7: float up 1 tile
    dw $0E07                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1C                ; $1C trigger_anim: NPC 7: float up 1 tile
    dw $0E07                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0476                ; text $0476: "Durran:Want a real thrill? Fight me! Dur…"
    dw $FF03                ; $03 set_flag: Set flag $00AB
    dw $00AB                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Boss: Reflection (Durran) screen 0 → state 2  [$D98C := 2]
    dw $D98C                ;   address
    dw $0002                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 7: drop 4 tiles
    dw $1107                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
Bank0F_ScriptAddr_4DB8:
    dw $FF05                ; $05 battle: Battle: enemy row 199
    dw $00C7                ;   enemy
    dw $FF0B                ; $0B walk_y_wait: NPC 7 walks up 1 tile (script waits)
    dw $0007                ;   actor
    dw $FFF0                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0479                ; text $0479: "Durran:Did I lose? .. I lost... Durran:Y…"
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 7 walks up 87 px
    dw $0007                ;   actor
    dw $FFA9                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 7 is hidden
    dw $0007                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 4: stands still (status cleared)  [slot +$05 := $00]
    dw $0004                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 4 walks down 1 tile (script waits)
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 4 walks right 1 tile (script waits)
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 4 walks down 1 tile (script waits)
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $047A                ; text $047A: "TERRY?:..You're strong... You even defea…"
    dw $047B                ; text $047B: "Do you really want to tell your true nam…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0F_ScriptAddr_4E22  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_4E22 ;   target
    dw $047D                ; text $047D: "TERRY?:No. It's okay... I know..."
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_4E24
    dw Bank0F_ScriptAddr_4E24 ;   target
Bank0F_ScriptAddr_4E22:
    dw $047C                ; text $047C: "TERRY?:It's okay. I know..."
Bank0F_ScriptAddr_4E24:
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1C                ; $1C trigger_anim: NPC 4: float up 1 tile
    dw $0E04                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $047F                ; text $047F: "TERRY?:Ahhh... For some reason, I feel r…"
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0005                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 4 tiles
    dw $0005                ;   actor
    dw $0040                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 5: stands still (status cleared)  [slot +$05 := $00]
    dw $0005                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0480                ; text $0480: "TERRY?:[HERO], don't become like me. TER…"
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 4 tiles
    dw $0004                ;   actor
    dw $FFC0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 4 tiles
    dw $0005                ;   actor
    dw $FFC0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF0D                ; $0D npc_write: NPC 4: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0004                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0005                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0481                ; text $0481: "TERRY?:Farewell [HERO]! I'm taking off. …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0F_ScriptAddr_4E92  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_4E92 ;   target
    dw $0482                ; text $0482: "TERRY?:Take care of your sister. No matt…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_4E94
    dw Bank0F_ScriptAddr_4E94 ;   target
Bank0F_ScriptAddr_4E92:
    dw $0483                ; text $0483: "TERRY?:...You don't want to hear this, b…"
Bank0F_ScriptAddr_4E94:
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 7 px
    dw $0004                ;   actor
    dw $FFF9                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 7 px
    dw $0005                ;   actor
    dw $FFF9                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 1 tile
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF0D                ; $0D npc_write: NPC 4 is hidden
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 2 tiles (script waits)
    dw $0001                ;   actor
    dw $FFE0                ;   pixels
    dw $FF0D                ; $0D npc_write: NPC 1: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF09                ; $09 delay: Wait 24 ticks (~192 frames)
    dw $0018                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 6 is shown
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 5, curve 4  [$D8E3 := $0405]
    dw $D8E3                ;   address
    dw $0405                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 6: fly in down-left (the flight path set above)
    dw $1506                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 6 faces up
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 6 faces right
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 6 faces down
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 6 faces left
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0484                ; text $0484: "Watabou:Let's go back!"
    dw $FF1C                ; $1C trigger_anim: NPC 6: jump
    dw $0406                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 6 faces up
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 6 faces right
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 6 faces down
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF49                ; $49 face_left: NPC 6 faces left
    dw $0006                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 69  [$D9E3 := 69]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0045                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0025
    dw $0025                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable: KingSlime Room screen 0 → state 2  [$D963 := 2]
    dw $D963                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Reflection screen 0 → state 1  [$D970 := 1]
    dw $D970                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Reflection (Durran) screen 0 → state 1  [$D98C := 1]
    dw $D98C                ;   address
    dw $0001                ;   value
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_4F6E:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0473                ; text $0473: "Durran:Ha ha ha! You came again!! Durran…"
    dw $FF1C                ; $1C trigger_anim: NPC 4: appear (flicker in)
    dw $0804                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
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
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
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
    dw $FF4D                ; $4D long_delay: Wait 2 frames
    dw $0002                ;   frames
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
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
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0474                ; text $0474: "Durran:Come on Terry! Fight to your hear…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF05                ; $05 battle: Battle: enemy row 343
    dw $0157                ;   enemy
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_4D4A
    dw Bank0F_ScriptAddr_4D4A ;   target
Bank0F_ScriptAddr_5016:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0477                ; text $0477: "Durran:How was it? Learn anything? Durra…"
    dw $FF1C                ; $1C trigger_anim: NPC 7: float up 1 tile
    dw $0E07                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1C                ; $1C trigger_anim: NPC 7: float up 1 tile
    dw $0E07                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1C                ; $1C trigger_anim: NPC 7: float up 1 tile
    dw $0E07                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0478                ; text $0478: "Durran:Here I come!!"
    dw $FF1C                ; $1C trigger_anim: NPC 7: drop 4 tiles
    dw $1107                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_4DB8
    dw Bank0F_ScriptAddr_4DB8 ;   target
Bank0F_ScriptAddr_503C:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map45_Script01
; ---------------------------------------------------------------------------
Map45_Script01:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossAmbition Per-Script Table (map_type=$46, 2 scripts)
; ---------------------------------------------------------------------------
BossAmbition_ScriptPtrTable:
    dw BossAmbition_Script00 ; script 0
    dw BossAmbition_Script01 ; script 1
; ---------------------------------------------------------------------------
; BossAmbition_Script00
; ---------------------------------------------------------------------------
BossAmbition_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossAmbition_Script01
; ---------------------------------------------------------------------------
BossAmbition_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00D9 is set → Bank0F_ScriptAddr_5080
    dw $00D9                ;   flag
    dw Bank0F_ScriptAddr_5080 ;   target
    dw $057B                ; text $057B: "*:Welcome [HERO]! *:I'm the King of King…"
    dw $FF03                ; $03 set_flag: Set flag $00D9
    dw $00D9                ;   flag
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0F_ScriptAddr_5086  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5086 ;   target
    dw $057D                ; text $057D: "DracoLord:What's wrong with it. It is no…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0F_ScriptAddr_5086  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_5086 ;   target
    dw $057E                ; text $057E: "DracoLord:You say you're going to beat m…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_5088
    dw Bank0F_ScriptAddr_5088 ;   target
Bank0F_ScriptAddr_5080:
    dw $057F                ; text $057F: "DracoLord:You came back? You never learn…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_5088
    dw Bank0F_ScriptAddr_5088 ;   target
Bank0F_ScriptAddr_5086:
    dw $057C                ; text $057C: "DracoLord:Great, you agreed! Now I will …"
Bank0F_ScriptAddr_5088:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 201 (boss)
    dw $00C9                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0580                ; text $0580: "DracoLord:You beat me. You're really som…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 3  [$D8E3 := $0304]
    dw $D8E3                ;   address
    dw $0304                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0581                ; text $0581: "Watabou:One down! [HERO]! Let's go back!"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 70  [$D9E3 := 70]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0046                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0026
    dw $0026                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Ambition/Demolition screen 0 → state 1  [$D971 := 1]
    dw $D971                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Ambition (DracoLord) screen 0 → state 1  [$D98D := 1]
    dw $D98D                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0028 is clear → Bank0F_ScriptAddr_512C
    dw $0028                ;   flag
    dw Bank0F_ScriptAddr_512C ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Ambition/Demolition screen 0 → state 3  [$D971 := 3]
    dw $D971                ;   address
    dw $0003                ;   value
Bank0F_ScriptAddr_512C:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map47 Per-Script Table (map_type=$47, 3 scripts)
; ---------------------------------------------------------------------------
Map47_ScriptPtrTable:
    dw Map47_Script00       ; script 0
    dw Map47_Script01       ; script 1
    dw Map47_Script02       ; script 2
; ---------------------------------------------------------------------------
; Map47_Script00
; ---------------------------------------------------------------------------
Map47_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map47_Script01
; ---------------------------------------------------------------------------
Map47_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00DA is set → Bank0F_ScriptAddr_516A
    dw $00DA                ;   flag
    dw Bank0F_ScriptAddr_516A ;   target
    dw $0582                ; text $0582: "*:Who is it? *:Disturbing my rest? *:You…"
    dw $FF03                ; $03 set_flag: Set flag $00DA
    dw $00DA                ;   flag
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0F_ScriptAddr_5172  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5172 ;   target
    dw $0584                ; text $0584: "Hargon:Then you should know, Hargon:I'm …"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_5174
    dw Bank0F_ScriptAddr_5174 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_516A:
    dw $0585                ; text $0585: "Hargon:You again! Hargon:Insolant fool! …"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_5174
    dw Bank0F_ScriptAddr_5174 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_5172:
    dw $0583                ; text $0583: "Hargon:Then it is unforgivable! Hargon:I…"
Bank0F_ScriptAddr_5174:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 203 (boss)
    dw $00CB                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0586                ; text $0586: "Hargon:To my vex... Hargon:the great Har…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 3  [$D8E3 := $0304]
    dw $D8E3                ;   address
    dw $0304                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0587                ; text $0587: "Watabou:Hm? I still smell monster... Wat…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 71  [$D9E3 := 71]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0047                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0027
    dw $0027                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Demolition (Hargon/Sidoh) screen 0 → state 1  [$D98E := 1]
    dw $D98E                ;   address
    dw $0001                ;   value
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map47_Script02
; ---------------------------------------------------------------------------
Map47_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $00DB is set → Bank0F_ScriptAddr_5224
    dw $00DB                ;   flag
    dw Bank0F_ScriptAddr_5224 ;   target
    dw $0588                ; text $0588: "*:...I...am... the...god...of... destruc…"
    dw $FF03                ; $03 set_flag: Set flag $00DB
    dw $00DB                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_5226
    dw Bank0F_ScriptAddr_5226 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_5224:
    dw $0589                ; text $0589: "Sidoh:...I... destroy...!!"
Bank0F_ScriptAddr_5226:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 205 (boss)
    dw $00CD                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $058A                ; text $058A: "Sidoh:............"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 3  [$D8E3 := $0304]
    dw $D8E3                ;   address
    dw $0304                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $058B                ; text $058B: "Watabou:There was a monster still here. …"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 199  [$D9E3 := 199]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $00C7                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0028
    dw $0028                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Ambition/Demolition screen 0 → state 2  [$D971 := 2]
    dw $D971                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Demolition (Hargon/Sidoh) screen 0 → state 2  [$D98E := 2]
    dw $D98E                ;   address
    dw $0002                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0026 is clear → Bank0F_ScriptAddr_52CA
    dw $0026                ;   flag
    dw Bank0F_ScriptAddr_52CA ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Ambition/Demolition screen 0 → state 3  [$D971 := 3]
    dw $D971                ;   address
    dw $0003                ;   value
Bank0F_ScriptAddr_52CA:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map48 Per-Script Table (map_type=$48, 2 scripts)
; ---------------------------------------------------------------------------
Map48_ScriptPtrTable:
    dw Map48_Script00       ; script 0
    dw Map48_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map48_Script00
; ---------------------------------------------------------------------------
Map48_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map48_Script01
; ---------------------------------------------------------------------------
Map48_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00DC is set → Bank0F_ScriptAddr_52FC
    dw $00DC                ;   flag
    dw Bank0F_ScriptAddr_52FC ;   target
    dw $058C                ; text $058C: "*:At last you came here, pathetic thing!…"
    dw $FF03                ; $03 set_flag: Set flag $00DC
    dw $00DC                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_52FE
    dw Bank0F_ScriptAddr_52FE ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_52FC:
    dw $058D                ; text $058D: "Baramos:Fool! You still disobey me! Bara…"
Bank0F_ScriptAddr_52FE:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 207 (boss)
    dw $00CF                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $058E                ; text $058E: "Baramos:Arhg... y..you... Baramos:How da…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 1  [$D8E3 := $0104]
    dw $D8E3                ;   address
    dw $0104                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $058F                ; text $058F: "Watabou: Excellent [HERO]. Leeet's go ba…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 72  [$D9E3 := 72]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0048                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0029
    dw $0029                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Mastermind/Control screen 0 → state 1  [$D972 := 1]
    dw $D972                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Mastermind (Baramos) screen 0 → state 1  [$D98F := 1]
    dw $D98F                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $002A is clear → Bank0F_ScriptAddr_53A2
    dw $002A                ;   flag
    dw Bank0F_ScriptAddr_53A2 ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Mastermind/Control screen 0 → state 3  [$D972 := 3]
    dw $D972                ;   address
    dw $0003                ;   value
Bank0F_ScriptAddr_53A2:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map49 Per-Script Table (map_type=$49, 2 scripts)
; ---------------------------------------------------------------------------
Map49_ScriptPtrTable:
    dw Map49_Script00       ; script 0
    dw Map49_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map49_Script00
; ---------------------------------------------------------------------------
Map49_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map49_Script01
; ---------------------------------------------------------------------------
Map49_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00DD is set → Bank0F_ScriptAddr_53D4
    dw $00DD                ;   flag
    dw Bank0F_ScriptAddr_53D4 ;   target
    dw $0590                ; text $0590: "*:Welcome to my altar of sacrifice! *:I …"
    dw $FF03                ; $03 set_flag: Set flag $00DD
    dw $00DD                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_53D6
    dw Bank0F_ScriptAddr_53D6 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_53D4:
    dw $0591                ; text $0591: "Zoma:Hmm, you seem to never learn. Zoma:…"
Bank0F_ScriptAddr_53D6:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 209 (boss)
    dw $00D1                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0592                ; text $0592: "Zoma:...What is your name... son? Zoma:I…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 2  [$D8E3 := $0204]
    dw $D8E3                ;   address
    dw $0204                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0593                ; text $0593: "Watabou:There're lots of strong monsters…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 73  [$D9E3 := 73]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0049                ;   value
    dw $FF03                ; $03 set_flag: Set flag $002A
    dw $002A                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Mastermind/Control screen 0 → state 2  [$D972 := 2]
    dw $D972                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Control (Zoma) screen 0 → state 1  [$D990 := 1]
    dw $D990                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0029 is clear → Bank0F_ScriptAddr_547A
    dw $0029                ;   flag
    dw Bank0F_ScriptAddr_547A ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Mastermind/Control screen 0 → state 3  [$D972 := 3]
    dw $D972                ;   address
    dw $0003                ;   value
Bank0F_ScriptAddr_547A:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map4A Per-Script Table (map_type=$4A, 2 scripts)
; ---------------------------------------------------------------------------
Map4A_ScriptPtrTable:
    dw Map4A_Script00       ; script 0
    dw Map4A_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map4A_Script00
; ---------------------------------------------------------------------------
Map4A_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map4A_Script01
; ---------------------------------------------------------------------------
Map4A_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00DE is set → Bank0F_ScriptAddr_54B4
    dw $00DE                ;   flag
    dw Bank0F_ScriptAddr_54B4 ;   target
    dw $0594                ; text $0594: "*:Gwwrrrr...! Who are you? *:I am Pizzar…"
    dw $FF03                ; $03 set_flag: Set flag $00DE
    dw $00DE                ;   flag
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0F_ScriptAddr_54C4  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_54C4 ;   target
    dw $0596                ; text $0596: "Pizzaro:Then, I will tell you! Gwrrr...!…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_54CC
    dw Bank0F_ScriptAddr_54CC ;   target
Bank0F_ScriptAddr_54B4:
    dw $0597                ; text $0597: "Pizzaro:Gwwrrr...! Pizzaro:You want to d…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0F_ScriptAddr_54CA  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_54CA ;   target
    dw $0599                ; text $0599: "Pizzaro:Then, what brought you here! Piz…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_54CC
    dw Bank0F_ScriptAddr_54CC ;   target
Bank0F_ScriptAddr_54C4:
    dw $0595                ; text $0595: "Pizzaro:Gwwrrr! Regret showing yourself……"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_54CC
    dw Bank0F_ScriptAddr_54CC ;   target
Bank0F_ScriptAddr_54CA:
    dw $0598                ; text $0598: "Pizzaro:Then, die!"
Bank0F_ScriptAddr_54CC:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 211 (boss)
    dw $00D3                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $059A                ; text $059A: "Pizzaro:Gwwrr...! My body is burning...!…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 1  [$D8E3 := $0104]
    dw $D8E3                ;   address
    dw $0104                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $059B                ; text $059B: "Watabou:Rosalie was Pizzaro's lover. Wat…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 74  [$D9E3 := 74]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $004A                ;   value
    dw $FF03                ; $03 set_flag: Set flag $002B
    dw $002B                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Extinction/Sleep screen 0 → state 1  [$D973 := 1]
    dw $D973                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Extinction (Pizzaro) screen 0 → state 1  [$D991 := 1]
    dw $D991                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $002C is clear → Bank0F_ScriptAddr_5570
    dw $002C                ;   flag
    dw Bank0F_ScriptAddr_5570 ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Extinction/Sleep screen 0 → state 3  [$D973 := 3]
    dw $D973                ;   address
    dw $0003                ;   value
Bank0F_ScriptAddr_5570:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map4B Per-Script Table (map_type=$4B, 2 scripts)
; ---------------------------------------------------------------------------
Map4B_ScriptPtrTable:
    dw Map4B_Script00       ; script 0
    dw Map4B_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map4B_Script00
; ---------------------------------------------------------------------------
Map4B_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map4B_Script01
; ---------------------------------------------------------------------------
Map4B_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00DF is set → Bank0F_ScriptAddr_55A8
    dw $00DF                ;   flag
    dw Bank0F_ScriptAddr_55A8 ;   target
    dw $059C                ; text $059C: "*:Ggggrrr... *:Who is disturb- ing my re…"
    dw $FF03                ; $03 set_flag: Set flag $00DF
    dw $00DF                ;   flag
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0F_ScriptAddr_55AE  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_55AE ;   target
    dw $059D                ; text $059D: "Esterk:Then go away. Esterk:I will rest.…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_55A8:
    dw $059F                ; text $059F: "Esterk:Gggrrr... Esterk:You again... Est…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_55B0
    dw Bank0F_ScriptAddr_55B0 ;   target
Bank0F_ScriptAddr_55AE:
    dw $059E                ; text $059E: "Esterk:There is no choice. Esterk:I cann…"
Bank0F_ScriptAddr_55B0:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 213 (boss)
    dw $00D5                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05A0                ; text $05A0: "Esterk:Ggggrrr... What's wrong with me..…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 2, curve 1  [$D8E3 := $0102]
    dw $D8E3                ;   address
    dw $0102                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05A1                ; text $05A1: "Watabou:Even if we're in a dream, Watabo…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 75  [$D9E3 := 75]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $004B                ;   value
    dw $FF03                ; $03 set_flag: Set flag $002C
    dw $002C                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Extinction/Sleep screen 0 → state 2  [$D973 := 2]
    dw $D973                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Sleep (Esterk) screen 0 → state 1  [$D992 := 1]
    dw $D992                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $002B is clear → Bank0F_ScriptAddr_5654
    dw $002B                ;   flag
    dw Bank0F_ScriptAddr_5654 ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Extinction/Sleep screen 0 → state 3  [$D973 := 3]
    dw $D973                ;   address
    dw $0003                ;   value
Bank0F_ScriptAddr_5654:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map4C Per-Script Table (map_type=$4C, 2 scripts)
; ---------------------------------------------------------------------------
Map4C_ScriptPtrTable:
    dw Map4C_Script00       ; script 0
    dw Map4C_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map4C_Script00
; ---------------------------------------------------------------------------
Map4C_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map4C_Script01
; ---------------------------------------------------------------------------
Map4C_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00E2 is set → Bank0F_ScriptAddr_568E
    dw $00E2                ;   flag
    dw Bank0F_ScriptAddr_568E ;   target
    dw $05A2                ; text $05A2: "*:At last, you came here. *:The Monster …"
    dw $FF03                ; $03 set_flag: Set flag $00E2
    dw $00E2                ;   flag
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0F_ScriptAddr_5694  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5694 ;   target
    dw $05A4                ; text $05A4: "*:You don't know my name? You fool! *:Th…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_5696
    dw Bank0F_ScriptAddr_5696 ;   target
Bank0F_ScriptAddr_568E:
    dw $05A5                ; text $05A5: "Mirudraas:Ha ha ha! Mirudraas:Monster Ma…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_5696
    dw Bank0F_ScriptAddr_5696 ;   target
Bank0F_ScriptAddr_5694:
    dw $05A3                ; text $05A3: "*:Ha ha ha!! You have good intentions. *…"
Bank0F_ScriptAddr_5696:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 215 (boss)
    dw $00D7                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05A6                ; text $05A6: "Mirudraas:How.. could I be defeated... M…"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: vanish (flicker out)
    dw $0D02                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 3, curve 2  [$D8E3 := $0203]
    dw $D8E3                ;   address
    dw $0203                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05A7                ; text $05A7: "Watabou:You really became strong. Now, l…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 76  [$D9E3 := 76]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $004C                ;   value
    dw $FF03                ; $03 set_flag: Set flag $002D
    dw $002D                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 7  [$D93A := 7]
    dw $D93A                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Bazaar Edge (Mirudraas) screen 0 → state 1  [$D993 := 1]
    dw $D993                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0014 is clear → Bank0F_ScriptAddr_5744
    dw $0014                ;   flag
    dw Bank0F_ScriptAddr_5744 ;   target
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 8  [$D93A := 8]
    dw $D93A                ;   address
    dw $0008                ;   value
Bank0F_ScriptAddr_5744:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map4D Per-Script Table (map_type=$4D, 2 scripts)
; ---------------------------------------------------------------------------
Map4D_ScriptPtrTable:
    dw Map4D_Script00       ; script 0
    dw Map4D_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map4D_Script00
; ---------------------------------------------------------------------------
Map4D_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map4D_Script01
; ---------------------------------------------------------------------------
Map4D_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00E0 is set → Bank0F_ScriptAddr_5794
    dw $00E0                ;   flag
    dw Bank0F_ScriptAddr_5794 ;   target
    dw $05A8                ; text $05A8: "*:Welcome, you worthless... *:I am Mudou…"
    dw $FF03                ; $03 set_flag: Set flag $00E0
    dw $00E0                ;   flag
Bank0F_ScriptAddr_5770:
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0F_ScriptAddr_577E  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_577E ;   target
    dw $05A9                ; text $05A9: "Mudou:Hm? You already know my name, righ…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_5770
    dw Bank0F_ScriptAddr_5770 ;   target
Bank0F_ScriptAddr_577E:
    dw $05AA                ; text $05AA: "Mudou:Fine. Now, Mudou:are you prepared?…"
Bank0F_ScriptAddr_5780:
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0F_ScriptAddr_578E  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_578E ;   target
    dw $05AB                ; text $05AB: "Mudou:Huh? Did you prepare your coffins …"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_5780
    dw Bank0F_ScriptAddr_5780 ;   target
Bank0F_ScriptAddr_578E:
    dw $05AC                ; text $05AC: "Mudou:Fine. Let's begin."
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_5796
    dw Bank0F_ScriptAddr_5796 ;   target
Bank0F_ScriptAddr_5794:
    dw $05AD                ; text $05AD: "Mudou:Annoying worthless things. I'll ex…"
Bank0F_ScriptAddr_5796:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 217 (boss)
    dw $00D9                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05AE                ; text $05AE: "Mudou:I was beaten by worthless... it me…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 1  [$D8E3 := $0104]
    dw $D8E3                ;   address
    dw $0104                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05AF                ; text $05AF: "Watabou:Well, shall we go back?"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 77  [$D9E3 := 77]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $004D                ;   value
    dw $FF03                ; $03 set_flag: Set flag $002E
    dw $002E                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Arena Rooms screen 1 → state 6  [$D94C := 6]
    dw $D94C                ;   address
    dw $0006                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Arena Right (Mudou) screen 0 → state 1  [$D994 := 1]
    dw $D994                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $001E is clear → Bank0F_ScriptAddr_583A
    dw $001E                ;   flag
    dw Bank0F_ScriptAddr_583A ;   target
    dw $FF12                ; $12 write_ram: Room state of Arena Rooms screen 1 → state 7  [$D94C := 7]
    dw $D94C                ;   address
    dw $0007                ;   value
Bank0F_ScriptAddr_583A:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map4E Per-Script Table (map_type=$4E, 2 scripts)
; ---------------------------------------------------------------------------
Map4E_ScriptPtrTable:
    dw Map4E_Script00       ; script 0
    dw Map4E_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map4E_Script00
; ---------------------------------------------------------------------------
Map4E_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map4E_Script01
; ---------------------------------------------------------------------------
Map4E_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00E1 is set → Bank0F_ScriptAddr_586C
    dw $00E1                ;   flag
    dw Bank0F_ScriptAddr_586C ;   target
    dw $05B0                ; text $05B0: "*:Ha ha ha! *:Just because I let you pla…"
    dw $FF03                ; $03 set_flag: Set flag $00E1
    dw $00E1                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_586E
    dw Bank0F_ScriptAddr_586E ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_586C:
    dw $05B1                ; text $05B1: "DeathMore:Ha ha ha You came back. DeathM…"
Bank0F_ScriptAddr_586E:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 219 (boss)
    dw $00DB                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05B2                ; text $05B2: "DeathMore:Argh.. I..lost... DeathMore:I …"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 3  [$D8E3 := $0304]
    dw $D8E3                ;   address
    dw $0304                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05B3                ; text $05B3: "Watabou: DeathMore is the most powerful …"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 78  [$D9E3 := 78]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $004E                ;   value
    dw $FF03                ; $03 set_flag: Set flag $002F
    dw $002F                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Old Man Gate Room screen 0 → state 1  [$D958 := 1]
    dw $D958                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Grandpa's Gate (DeathMore) screen 0 → state 1  [$D995 := 1]
    dw $D995                ;   address
    dw $0001                ;   value
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; BossUnused Per-Script Table (map_type=$4F, 3 scripts)
; ---------------------------------------------------------------------------
BossUnused_ScriptPtrTable:
    dw BossUnused_Script00  ; script 0
    dw BossUnused_Script01  ; script 1
    dw BossUnused_Script02  ; script 2
; ---------------------------------------------------------------------------
; BossUnused_Script00
; ---------------------------------------------------------------------------
BossUnused_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossUnused_Script01
; ---------------------------------------------------------------------------
BossUnused_Script01:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossUnused_Script02
; ---------------------------------------------------------------------------
BossUnused_Script02:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map50 Per-Script Table (map_type=$50, 2 scripts)
; ---------------------------------------------------------------------------
Map50_ScriptPtrTable:
    dw Map50_Script00       ; script 0
    dw Map50_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map50_Script00
; ---------------------------------------------------------------------------
Map50_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map50_Script01
; ---------------------------------------------------------------------------
Map50_Script01:
    dw $0680                ; text $0680: "*:Item shop. May I help you?"
    dw $FF04                ; $04 open_screen: Open the shop (its texts begin “*:Item shop. May I help you?”)
    dw $0000                ;   kind
    dw $0680                ;   text
    dw $0682                ; text $0682: "*:Thank you. Come again!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map51 Per-Script Table (map_type=$51, 3 scripts)
; ---------------------------------------------------------------------------
Map51_ScriptPtrTable:
    dw Map51_Script00       ; script 0
    dw Map51_Script01       ; script 1
    dw Map51_Script02       ; script 2
; ---------------------------------------------------------------------------
; Map51_Script00
; ---------------------------------------------------------------------------
Map51_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map51_Script02
; ---------------------------------------------------------------------------
Map51_Script02:
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
; ---------------------------------------------------------------------------
; Map51_Script01
; ---------------------------------------------------------------------------
Map51_Script01:
    dw $FF64                ; $64 if_party_healthy: Go to target when every party monster is at full HP and MP → Bank0F_ScriptAddr_59B8
    dw Bank0F_ScriptAddr_59B8 ;   target
    dw $09FF                ; text $09FF: "*:Let there be light! HEAL!!!"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF41                ; $41 set_bgm: Music $41
    dw $0041                ;   song
    dw $FF46                ; $46 wait_dungeon_flags: Wait until the running effect / animation finishes
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
    dw $FF35                ; $35 refresh_party2: Re-count the party
    dw $FF16                ; $16 refresh_sprites: Redraw the sprites and the screen position (one tick)
    dw $FF4B                ; $4B restore_bgm: Play the song set_bgm replaced
    dw $FFFF                ; END

Bank0F_ScriptAddr_59B8:
    dw $09F6                ; text $09F6: "*:Every journey has its danger. *:Take c…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map52 Per-Script Table (map_type=$52, 1 scripts)
; ---------------------------------------------------------------------------
Map52_ScriptPtrTable:
    dw Map52_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map52_Script00
; ---------------------------------------------------------------------------
Map52_Script00:
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 1  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_59F0  [$D9CD = 0]
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_59F0 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 2  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_5A06  [$D9CD = 1]
    dw $D9CD                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_5A06 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 3  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_5A0E  [$D9CD = 2]
    dw $D9CD                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_5A0E ;   target
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 4  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_5A16  [$D9CD = 3]
    dw $D9CD                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_5A16 ;   target
    dw $FFFF                ; END

Bank0F_ScriptAddr_59F0:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 1” is already opened → Bank0F_ScriptAddr_5A00  [$D9CF = 0]
    dw $D9CF                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5A00 ;   target
    dw $09F3                ; text $09F3: "*:A big applause for the brave challenge…"
    dw $FF20                ; $20 start_battle: Start the battle set up above (enemies / count)
    dw $FFFF                ; END

Bank0F_ScriptAddr_5A00:
    dw $09FE                ; text $09FE: "*:Welcome to the coliseum daredevils! *:…"
    dw $FF20                ; $20 start_battle: Start the battle set up above (enemies / count)
    dw $FFFF                ; END
Bank0F_ScriptAddr_5A06:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09FD                ; text $09FD: "*:Just like a veteran! *:How about the n…"
    dw $FF20                ; $20 start_battle: Start the battle set up above (enemies / count)
    dw $FFFF                ; END

Bank0F_ScriptAddr_5A0E:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09FC                ; text $09FC: "*:Is there anybody who can beat you!! He…"
    dw $FF20                ; $20 start_battle: Start the battle set up above (enemies / count)
    dw $FFFF                ; END

Bank0F_ScriptAddr_5A16:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 2” is already opened → Bank0F_ScriptAddr_5A2A  [$D9D0 = 0]
    dw $D9D0                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5A2A ;   target
    dw $FF5D                ; $5D give_coliseum_prize: Give the Coliseum prize item
    dw $09F1                ; text $09F1: "*:Oh! Nobody can beat you anymore!!"
    dw $09EF                ; text $09EF: "Got a [INS 00] as the reward!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_5A2C
    dw Bank0F_ScriptAddr_5A2C ;   target
Bank0F_ScriptAddr_5A2A:
    dw $09F1                ; text $09F1: "*:Oh! Nobody can beat you anymore!!"
Bank0F_ScriptAddr_5A2C:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5A48
    dw Bank0F_ScriptAddr_5A48 ;   target
    dw $FF5C                ; $5C coliseum_init: Roll the three Coliseum teams and the prize
    dw $09F0                ; text $09F0: "*:The next reward is 1 [INS 00]! *:Would…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0F_ScriptAddr_5A48  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_5A48 ;   target
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF0F                ; $0F map_transition: Go to Gate Floor: Coliseum at (6, 6)
    dw $0052                ;   map
    dw $0068                ;   x
    dw $0068                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_5A48:
    dw $09F2                ; text $09F2: "*:Until next time, so long!"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF12                ; $12 write_ram: The room change in progress: yes  [$C96C := 1]
    dw $C96C                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: The warp destination (gate): 0  [$C96D := 0]  (meaning inferred from the scripts that use it)
    dw $C96D                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The warp kind: 128  [$C96E := 128]  (meaning inferred from the scripts that use it)
    dw $C96E                ;   address
    dw $0080                ;   value
    dw $FF12                ; $12 write_ram: The field state: 32  [$C8EB := 32]
    dw $C8EB                ;   address
    dw $0020                ;   value
    dw $FF12                ; $12 write_ram: The battle-transition state: 0  [$C905 := 0]
    dw $C905                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Map53 Per-Script Table (map_type=$53, 1 scripts)
; ---------------------------------------------------------------------------
Map53_ScriptPtrTable:
    dw Map53_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map54 Per-Script Table (map_type=$54, 2 scripts)
; ---------------------------------------------------------------------------
Map54_ScriptPtrTable:
    dw Map54_Script00       ; script 0
    dw Map54_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map54_Script00
; ---------------------------------------------------------------------------
Map54_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map54_Script01
; ---------------------------------------------------------------------------
Map54_Script01:
    dw $FF1C                ; $1C trigger_anim: the player: pause 64 frames (followers catch up)
    dw $0600                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map57 Per-Script Table (map_type=$57, 1 scripts)
; ---------------------------------------------------------------------------
Map57_ScriptPtrTable:
    dw Map53_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map5A Per-Script Table (map_type=$5A, 7 scripts)
; ---------------------------------------------------------------------------
Map5A_ScriptPtrTable:
    dw Map5A_Script00       ; script 0
    dw Map5A_Script01       ; script 1
    dw Map5A_Script02       ; script 2
    dw Map5A_Script03       ; script 3
    dw Map5A_Script04       ; script 4
    dw Map5A_Script05       ; script 5
    dw Map5A_Script06       ; script 6
; ---------------------------------------------------------------------------
; Map5A_Script00
; ---------------------------------------------------------------------------
Map5A_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map5A_Script01
; ---------------------------------------------------------------------------
Map5A_Script01:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 1” is already opened → Bank0F_ScriptAddr_5AC8  [$D9CF = 0]
    dw $D9CF                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5AC8 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5AE2)
    dw Bank0F_ScriptAddr_5AE2 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 1” is empty → Bank0F_ScriptAddr_5ABA  [$D9CF = 255]
    dw $D9CF                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5ABA ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5ACC
    dw Bank0F_ScriptAddr_5ACC ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 1 (and empty it)
    dw $0000                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 1: already opened  [$D9CF := 0]
    dw $D9CF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5ABA:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 1: already opened  [$D9CF := 0]
    dw $D9CF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5AC8:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5ACC:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 1 (and empty it)
    dw $0000                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5ADA)
    dw Bank0F_TilePatch_5ADA ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5ADA:
    db $82, $00, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0082 (row 4, column 2), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5AE2:
    db $82, $00, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0082 (row 4, column 2), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5A_Script02
; ---------------------------------------------------------------------------
Map5A_Script02:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 2” is already opened → Bank0F_ScriptAddr_5B24  [$D9D0 = 0]
    dw $D9D0                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5B24 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5B3E)
    dw Bank0F_ScriptAddr_5B3E ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 2” is empty → Bank0F_ScriptAddr_5B16  [$D9D0 = 255]
    dw $D9D0                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5B16 ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5B28
    dw Bank0F_ScriptAddr_5B28 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 2 (and empty it)
    dw $0001                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 2: already opened  [$D9D0 := 0]
    dw $D9D0                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5B16:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 2: already opened  [$D9D0 := 0]
    dw $D9D0                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5B24:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5B28:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 2 (and empty it)
    dw $0001                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5B36)
    dw Bank0F_TilePatch_5B36 ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5B36:
    db $90, $00, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0090 (row 4, column 16), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5B3E:
    db $90, $00, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0090 (row 4, column 16), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5A_Script03
; ---------------------------------------------------------------------------
Map5A_Script03:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 3” is already opened → Bank0F_ScriptAddr_5B80  [$D9D1 = 0]
    dw $D9D1                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5B80 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5B9A)
    dw Bank0F_ScriptAddr_5B9A ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 3” is empty → Bank0F_ScriptAddr_5B72  [$D9D1 = 255]
    dw $D9D1                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5B72 ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5B84
    dw Bank0F_ScriptAddr_5B84 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 3 (and empty it)
    dw $0002                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 3: already opened  [$D9D1 := 0]
    dw $D9D1                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5B72:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 3: already opened  [$D9D1 := 0]
    dw $D9D1                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5B80:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5B84:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 3 (and empty it)
    dw $0002                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5B92)
    dw Bank0F_TilePatch_5B92 ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5B92:
    db $C6, $00, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $00C6 (row 6, column 6), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5B9A:
    db $C6, $00, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $00C6 (row 6, column 6), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5A_Script04
; ---------------------------------------------------------------------------
Map5A_Script04:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 4” is already opened → Bank0F_ScriptAddr_5BDC  [$D9D2 = 0]
    dw $D9D2                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5BDC ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5BF6)
    dw Bank0F_ScriptAddr_5BF6 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 4” is empty → Bank0F_ScriptAddr_5BCE  [$D9D2 = 255]
    dw $D9D2                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5BCE ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5BE0
    dw Bank0F_ScriptAddr_5BE0 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 4 (and empty it)
    dw $0003                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 4: already opened  [$D9D2 := 0]
    dw $D9D2                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5BCE:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 4: already opened  [$D9D2 := 0]
    dw $D9D2                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5BDC:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5BE0:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 4 (and empty it)
    dw $0003                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5BEE)
    dw Bank0F_TilePatch_5BEE ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5BEE:
    db $CC, $00, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $00CC (row 6, column 12), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5BF6:
    db $CC, $00, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $00CC (row 6, column 12), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5A_Script05
; ---------------------------------------------------------------------------
Map5A_Script05:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 5” is already opened → Bank0F_ScriptAddr_5C38  [$D9D3 = 0]
    dw $D9D3                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5C38 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5C52)
    dw Bank0F_ScriptAddr_5C52 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 5” is empty → Bank0F_ScriptAddr_5C2A  [$D9D3 = 255]
    dw $D9D3                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5C2A ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5C3C
    dw Bank0F_ScriptAddr_5C3C ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 5 (and empty it)
    dw $0004                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 5: already opened  [$D9D3 := 0]
    dw $D9D3                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5C2A:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 5: already opened  [$D9D3 := 0]
    dw $D9D3                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5C38:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5C3C:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 5 (and empty it)
    dw $0004                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5C4A)
    dw Bank0F_TilePatch_5C4A ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5C4A:
    db $44, $01, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0144 (row 10, column 4), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5C52:
    db $44, $01, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0144 (row 10, column 4), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5A_Script06
; ---------------------------------------------------------------------------
Map5A_Script06:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 6” is already opened → Bank0F_ScriptAddr_5C94  [$D9D4 = 0]
    dw $D9D4                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5C94 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CAE)
    dw Bank0F_ScriptAddr_5CAE ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 6” is empty → Bank0F_ScriptAddr_5C86  [$D9D4 = 255]
    dw $D9D4                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5C86 ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5C98
    dw Bank0F_ScriptAddr_5C98 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 6 (and empty it)
    dw $0005                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 6: already opened  [$D9D4 := 0]
    dw $D9D4                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5C86:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 6: already opened  [$D9D4 := 0]
    dw $D9D4                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5C94:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5C98:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 6 (and empty it)
    dw $0005                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CA6)
    dw Bank0F_TilePatch_5CA6 ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5CA6:
    db $4E, $01, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $014E (row 10, column 14), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5CAE:
    db $4E, $01, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $014E (row 10, column 14), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5B Per-Script Table (map_type=$5B, 7 scripts)
; ---------------------------------------------------------------------------
Map5B_ScriptPtrTable:
    dw Map5B_Script00       ; script 0
    dw Map5B_Script01       ; script 1
    dw Map5B_Script02       ; script 2
    dw Map5B_Script03       ; script 3
    dw Map5B_Script04       ; script 4
    dw Map5B_Script05       ; script 5
    dw Map5B_Script06       ; script 6
; ---------------------------------------------------------------------------
; Map5B_Script00
; ---------------------------------------------------------------------------
Map5B_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map5B_Script01
; ---------------------------------------------------------------------------
Map5B_Script01:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 1” is already opened → Bank0F_ScriptAddr_5D00  [$D9CF = 0]
    dw $D9CF                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5D00 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5D1A)
    dw Bank0F_ScriptAddr_5D1A ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 1” is empty → Bank0F_ScriptAddr_5CF2  [$D9CF = 255]
    dw $D9CF                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5CF2 ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5D04
    dw Bank0F_ScriptAddr_5D04 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 1 (and empty it)
    dw $0000                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 1: already opened  [$D9CF := 0]
    dw $D9CF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5CF2:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 1: already opened  [$D9CF := 0]
    dw $D9CF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5D00:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5D04:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 1 (and empty it)
    dw $0000                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5D12)
    dw Bank0F_TilePatch_5D12 ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5D12:
    db $C6, $00, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $00C6 (row 6, column 6), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5D1A:
    db $C6, $00, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $00C6 (row 6, column 6), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5B_Script02
; ---------------------------------------------------------------------------
Map5B_Script02:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 2” is already opened → Bank0F_ScriptAddr_5D5C  [$D9D0 = 0]
    dw $D9D0                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5D5C ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5D76)
    dw Bank0F_ScriptAddr_5D76 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 2” is empty → Bank0F_ScriptAddr_5D4E  [$D9D0 = 255]
    dw $D9D0                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5D4E ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5D60
    dw Bank0F_ScriptAddr_5D60 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 2 (and empty it)
    dw $0001                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 2: already opened  [$D9D0 := 0]
    dw $D9D0                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5D4E:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 2: already opened  [$D9D0 := 0]
    dw $D9D0                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5D5C:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5D60:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 2 (and empty it)
    dw $0001                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5D6E)
    dw Bank0F_TilePatch_5D6E ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5D6E:
    db $CC, $00, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $00CC (row 6, column 12), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5D76:
    db $CC, $00, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $00CC (row 6, column 12), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5B_Script03
; ---------------------------------------------------------------------------
Map5B_Script03:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 3” is already opened → Bank0F_ScriptAddr_5DB8  [$D9D1 = 0]
    dw $D9D1                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5DB8 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5DD2)
    dw Bank0F_ScriptAddr_5DD2 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 3” is empty → Bank0F_ScriptAddr_5DAA  [$D9D1 = 255]
    dw $D9D1                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5DAA ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5DBC
    dw Bank0F_ScriptAddr_5DBC ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 3 (and empty it)
    dw $0002                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 3: already opened  [$D9D1 := 0]
    dw $D9D1                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5DAA:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 3: already opened  [$D9D1 := 0]
    dw $D9D1                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5DB8:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5DBC:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 3 (and empty it)
    dw $0002                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5DCA)
    dw Bank0F_TilePatch_5DCA ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5DCA:
    db $06, $01, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0106 (row 8, column 6), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5DD2:
    db $06, $01, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0106 (row 8, column 6), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5B_Script04
; ---------------------------------------------------------------------------
Map5B_Script04:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 4” is already opened → Bank0F_ScriptAddr_5E14  [$D9D2 = 0]
    dw $D9D2                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5E14 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5E2E)
    dw Bank0F_ScriptAddr_5E2E ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 4” is empty → Bank0F_ScriptAddr_5E06  [$D9D2 = 255]
    dw $D9D2                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5E06 ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5E18
    dw Bank0F_ScriptAddr_5E18 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 4 (and empty it)
    dw $0003                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 4: already opened  [$D9D2 := 0]
    dw $D9D2                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5E06:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 4: already opened  [$D9D2 := 0]
    dw $D9D2                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5E14:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5E18:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 4 (and empty it)
    dw $0003                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5E26)
    dw Bank0F_TilePatch_5E26 ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5E26:
    db $0C, $01, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $010C (row 8, column 12), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5E2E:
    db $0C, $01, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $010C (row 8, column 12), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5B_Script05
; ---------------------------------------------------------------------------
Map5B_Script05:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 5” is already opened → Bank0F_ScriptAddr_5E70  [$D9D3 = 0]
    dw $D9D3                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5E70 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5E8A)
    dw Bank0F_ScriptAddr_5E8A ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 5” is empty → Bank0F_ScriptAddr_5E62  [$D9D3 = 255]
    dw $D9D3                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5E62 ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5E74
    dw Bank0F_ScriptAddr_5E74 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 5 (and empty it)
    dw $0004                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 5: already opened  [$D9D3 := 0]
    dw $D9D3                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5E62:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 5: already opened  [$D9D3 := 0]
    dw $D9D3                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5E70:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5E74:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 5 (and empty it)
    dw $0004                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5E82)
    dw Bank0F_TilePatch_5E82 ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5E82:
    db $46, $01, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0146 (row 10, column 6), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5E8A:
    db $46, $01, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0146 (row 10, column 6), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5B_Script06
; ---------------------------------------------------------------------------
Map5B_Script06:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 6” is already opened → Bank0F_ScriptAddr_5ECC  [$D9D4 = 0]
    dw $D9D4                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5ECC ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5EE6)
    dw Bank0F_ScriptAddr_5EE6 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 6” is empty → Bank0F_ScriptAddr_5EBE  [$D9D4 = 255]
    dw $D9D4                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5EBE ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5ED0
    dw Bank0F_ScriptAddr_5ED0 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 6 (and empty it)
    dw $0005                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 6: already opened  [$D9D4 := 0]
    dw $D9D4                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5EBE:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 6: already opened  [$D9D4 := 0]
    dw $D9D4                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5ECC:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5ED0:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 6 (and empty it)
    dw $0005                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5EDE)
    dw Bank0F_TilePatch_5EDE ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5EDE:
    db $4C, $01, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $014C (row 10, column 12), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5EE6:
    db $4C, $01, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $014C (row 10, column 12), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5C Per-Script Table (map_type=$5C, 9 scripts)
; ---------------------------------------------------------------------------
Map5C_ScriptPtrTable:
    dw Map5C_Script00       ; script 0
    dw Map5C_Script01       ; script 1
    dw Map5C_Script02       ; script 2
    dw Map5C_Script03       ; script 3
    dw Map5C_Script04       ; script 4
    dw Map5C_Script05       ; script 5
    dw Map5C_Script06       ; script 6
    dw Map5C_Script07       ; script 7
    dw Map5C_Script08       ; script 8
; ---------------------------------------------------------------------------
; Map5C_Script00
; ---------------------------------------------------------------------------
Map5C_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map5C_Script01
; ---------------------------------------------------------------------------
Map5C_Script01:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 1” is already opened → Bank0F_ScriptAddr_5F3C  [$D9CF = 0]
    dw $D9CF                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5F3C ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5F56)
    dw Bank0F_ScriptAddr_5F56 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 1” is empty → Bank0F_ScriptAddr_5F2E  [$D9CF = 255]
    dw $D9CF                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5F2E ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5F40
    dw Bank0F_ScriptAddr_5F40 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 1 (and empty it)
    dw $0000                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 1: already opened  [$D9CF := 0]
    dw $D9CF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5F2E:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 1: already opened  [$D9CF := 0]
    dw $D9CF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5F3C:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5F40:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 1 (and empty it)
    dw $0000                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5F4E)
    dw Bank0F_TilePatch_5F4E ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5F4E:
    db $86, $00, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0086 (row 4, column 6), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5F56:
    db $86, $00, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0086 (row 4, column 6), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5C_Script02
; ---------------------------------------------------------------------------
Map5C_Script02:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 2” is already opened → Bank0F_ScriptAddr_5F98  [$D9D0 = 0]
    dw $D9D0                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5F98 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5FB2)
    dw Bank0F_ScriptAddr_5FB2 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 2” is empty → Bank0F_ScriptAddr_5F8A  [$D9D0 = 255]
    dw $D9D0                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5F8A ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5F9C
    dw Bank0F_ScriptAddr_5F9C ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 2 (and empty it)
    dw $0001                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 2: already opened  [$D9D0 := 0]
    dw $D9D0                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5F8A:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 2: already opened  [$D9D0 := 0]
    dw $D9D0                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5F98:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5F9C:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 2 (and empty it)
    dw $0001                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5FAA)
    dw Bank0F_TilePatch_5FAA ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_5FAA:
    db $88, $00, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0088 (row 4, column 8), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_5FB2:
    db $88, $00, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0088 (row 4, column 8), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5C_Script03
; ---------------------------------------------------------------------------
Map5C_Script03:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 3” is already opened → Bank0F_ScriptAddr_5FF4  [$D9D1 = 0]
    dw $D9D1                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_5FF4 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $600E)
    dw Bank0F_ScriptAddr_600E ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 3” is empty → Bank0F_ScriptAddr_5FE6  [$D9D1 = 255]
    dw $D9D1                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_5FE6 ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_5FF8
    dw Bank0F_ScriptAddr_5FF8 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 3 (and empty it)
    dw $0002                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 3: already opened  [$D9D1 := 0]
    dw $D9D1                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5FE6:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 3: already opened  [$D9D1 := 0]
    dw $D9D1                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_5FF4:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_5FF8:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 3 (and empty it)
    dw $0002                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6006)
    dw Bank0F_TilePatch_6006 ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_6006:
    db $8A, $00, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $008A (row 4, column 10), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_600E:
    db $8A, $00, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $008A (row 4, column 10), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5C_Script04
; ---------------------------------------------------------------------------
Map5C_Script04:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 4” is already opened → Bank0F_ScriptAddr_6050  [$D9D2 = 0]
    dw $D9D2                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_6050 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $606A)
    dw Bank0F_ScriptAddr_606A ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 4” is empty → Bank0F_ScriptAddr_6042  [$D9D2 = 255]
    dw $D9D2                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_6042 ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_6054
    dw Bank0F_ScriptAddr_6054 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 4 (and empty it)
    dw $0003                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 4: already opened  [$D9D2 := 0]
    dw $D9D2                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_6042:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 4: already opened  [$D9D2 := 0]
    dw $D9D2                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_6050:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_6054:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 4 (and empty it)
    dw $0003                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6062)
    dw Bank0F_TilePatch_6062 ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_6062:
    db $8C, $00, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $008C (row 4, column 12), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_606A:
    db $8C, $00, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $008C (row 4, column 12), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5C_Script05
; ---------------------------------------------------------------------------
Map5C_Script05:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 5” is already opened → Bank0F_ScriptAddr_60AC  [$D9D3 = 0]
    dw $D9D3                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_60AC ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $60C6)
    dw Bank0F_ScriptAddr_60C6 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 5” is empty → Bank0F_ScriptAddr_609E  [$D9D3 = 255]
    dw $D9D3                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_609E ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_60B0
    dw Bank0F_ScriptAddr_60B0 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 5 (and empty it)
    dw $0004                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 5: already opened  [$D9D3 := 0]
    dw $D9D3                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_609E:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 5: already opened  [$D9D3 := 0]
    dw $D9D3                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_60AC:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_60B0:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 5 (and empty it)
    dw $0004                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $60BE)
    dw Bank0F_TilePatch_60BE ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_60BE:
    db $86, $01, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0186 (row 12, column 6), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_60C6:
    db $86, $01, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0186 (row 12, column 6), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5C_Script06
; ---------------------------------------------------------------------------
Map5C_Script06:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 6” is already opened → Bank0F_ScriptAddr_6108  [$D9D4 = 0]
    dw $D9D4                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_6108 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6122)
    dw Bank0F_ScriptAddr_6122 ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 6” is empty → Bank0F_ScriptAddr_60FA  [$D9D4 = 255]
    dw $D9D4                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_60FA ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_610C
    dw Bank0F_ScriptAddr_610C ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 6 (and empty it)
    dw $0005                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 6: already opened  [$D9D4 := 0]
    dw $D9D4                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_60FA:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 6: already opened  [$D9D4 := 0]
    dw $D9D4                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_6108:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_610C:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 6 (and empty it)
    dw $0005                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $611A)
    dw Bank0F_TilePatch_611A ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_611A:
    db $88, $01, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0188 (row 12, column 8), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_6122:
    db $88, $01, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $0188 (row 12, column 8), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5C_Script07
; ---------------------------------------------------------------------------
Map5C_Script07:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 7” is already opened → Bank0F_ScriptAddr_6164  [$D9D5 = 0]
    dw $D9D5                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_6164 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $617E)
    dw Bank0F_ScriptAddr_617E ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 7” is empty → Bank0F_ScriptAddr_6156  [$D9D5 = 255]
    dw $D9D5                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_6156 ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_6168
    dw Bank0F_ScriptAddr_6168 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 7 (and empty it)
    dw $0006                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 7: already opened  [$D9D5 := 0]
    dw $D9D5                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_6156:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 7: already opened  [$D9D5 := 0]
    dw $D9D5                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_6164:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_6168:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 7 (and empty it)
    dw $0006                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6176)
    dw Bank0F_TilePatch_6176 ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_6176:
    db $8A, $01, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $018A (row 12, column 10), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_617E:
    db $8A, $01, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $018A (row 12, column 10), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5C_Script08
; ---------------------------------------------------------------------------
Map5C_Script08:
    dw $FF15                ; $15 check_and_branch: If “treasure chest 8” is already opened → Bank0F_ScriptAddr_61C0  [$D9D6 = 0]
    dw $D9D6                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_61C0 ;   target
    dw $FF21                ; $21 sound: Sound effect $53
    dw $0053                ;   sound
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $61DA)
    dw Bank0F_ScriptAddr_61DA ;   data
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “treasure chest 8” is empty → Bank0F_ScriptAddr_61B2  [$D9D6 = 255]
    dw $D9D6                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_61B2 ;   target
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_61C4
    dw Bank0F_ScriptAddr_61C4 ;   target
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 8 (and empty it)
    dw $0007                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $FF12                ; $12 write_ram: Treasure chest 8: already opened  [$D9D6 := 0]
    dw $D9D6                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_61B2:
    dw $09F9                ; text $09F9: "[HERO] opened the treasure chest! The tr…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF36                ; $36 mimic_battle: Fight the Mimic of the current arena tier
    dw $FF12                ; $12 write_ram: Treasure chest 8: already opened  [$D9D6 := 0]
    dw $D9D6                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0F_ScriptAddr_61C0:
    dw $09F8                ; text $09F8: "[HERO] checked the treasure chest. But t…"
    dw $FFFF                ; END

Bank0F_ScriptAddr_61C4:
    dw $FF37                ; $37 give_stored_item: Give the item in treasure chest 8 (and empty it)
    dw $0007                ;   index
    dw $09FA                ; text $09FA: "[HERO] opened the treasure chest! [HERO]…"
    dw $09F4                ; text $09F4: "Can not carry anymore!"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $61D2)
    dw Bank0F_TilePatch_61D2 ;   data
    dw $FFFF                ; END

Bank0F_TilePatch_61D2:
    db $8C, $01, $30, $31, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $018C (row 12, column 12), tiles 30 31 / 34 35; $D8 = next row, $D9 = end
Bank0F_ScriptAddr_61DA:
    db $8C, $01, $32, $33, $D8, $34, $35, $D9  ; tile patch (op $24): BG offset $018C (row 12, column 12), tiles 32 33 / 34 35; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map5D Per-Script Table (map_type=$5D, 1 scripts)
; ---------------------------------------------------------------------------
Map5D_ScriptPtrTable:
    dw Map5D_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map5D_Script00
; ---------------------------------------------------------------------------
Map5D_Script00:
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF15                ; $15 check_and_branch: If “the arena class” is the King's match  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6A64  [$D9CE = 9]
    dw $D9CE                ;   address
    dw $0009                ;   value
    dw Bank0F_ScriptAddr_6A64 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is the Starry Night tournament  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_64CC  [$D9CE = 8]
    dw $D9CE                ;   address
    dw $0008                ;   value
    dw Bank0F_ScriptAddr_64CC ;   target
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 1  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_62E0  [$D9CD = 0]
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_62E0 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 2  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_62C6  [$D9CD = 1]
    dw $D9CD                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_62C6 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 3  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6248  [$D9CD = 2]
    dw $D9CD                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6248 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 4  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6224  [$D9CD = 3]
    dw $D9CD                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_6224 ;   target
    dw $FFFF                ; END

Bank0F_ScriptAddr_6224:
    dw $FF41                ; $41 set_bgm: Music $37
    dw $0037                ;   song
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0126                ; text $0126: "*:Congratulations! We have a new winner!…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF46                ; $46 wait_dungeon_flags: Wait until the running effect / animation finishes
    dw $FF41                ; $41 set_bgm: Music $61
    dw $0061                ;   song
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF12                ; $12 write_ram: The arena match: the special match  [$D9CD := 254]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $00FE                ;   value
    dw $FF0F                ; $0F map_transition: Go to Arena Lobby at (14, 4)
    dw $0006                ;   map
    dw $00E8                ;   x
    dw $0048                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_6248:
    dw $FF41                ; $41 set_bgm: Music $3A
    dw $003A                ;   song
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0124                ; text $0124: "*:For the 2nd match, the victory again g…"
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class S  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_62B2  [$D9CE = 7]
    dw $D9CE                ;   address
    dw $0007                ;   value
    dw Bank0F_ScriptAddr_62B2 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class A  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_62AC  [$D9CE = 6]
    dw $D9CE                ;   address
    dw $0006                ;   value
    dw Bank0F_ScriptAddr_62AC ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class B  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_62A6  [$D9CE = 5]
    dw $D9CE                ;   address
    dw $0005                ;   value
    dw Bank0F_ScriptAddr_62A6 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class C  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_62A0  [$D9CE = 4]
    dw $D9CE                ;   address
    dw $0004                ;   value
    dw Bank0F_ScriptAddr_62A0 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class D  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_629A  [$D9CE = 3]
    dw $D9CE                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_629A ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class E  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6294  [$D9CE = 2]
    dw $D9CE                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6294 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class F  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_628E  [$D9CE = 1]
    dw $D9CE                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_628E ;   target
    dw $085B                ; text $085B: "*:Here is the Principal of the Master Sc…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_62B4
    dw Bank0F_ScriptAddr_62B4 ;   target
Bank0F_ScriptAddr_628E:
    dw $085C                ; text $085C: "*:Here's the strange doctor from the bot…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_62B4
    dw Bank0F_ScriptAddr_62B4 ;   target
Bank0F_ScriptAddr_6294:
    dw $085F                ; text $085F: "*:Here's Master Teto!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_62B4
    dw Bank0F_ScriptAddr_62B4 ;   target
Bank0F_ScriptAddr_629A:
    dw $085E                ; text $085E: "*:Our favorite! Here's Master Mick!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_62B4
    dw Bank0F_ScriptAddr_62B4 ;   target
Bank0F_ScriptAddr_62A0:
    dw $085F                ; text $085F: "*:Here's Master Teto!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_62B4
    dw Bank0F_ScriptAddr_62B4 ;   target
Bank0F_ScriptAddr_62A6:
    dw $0860                ; text $0860: "*:Here's the tired guy from the restaura…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_62B4
    dw Bank0F_ScriptAddr_62B4 ;   target
Bank0F_ScriptAddr_62AC:
    dw $0861                ; text $0861: "*:Here's Master May."
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_62B4
    dw Bank0F_ScriptAddr_62B4 ;   target
Bank0F_ScriptAddr_62B2:
    dw $0862                ; text $0862: "*:Here's the medal loving master, Medal …"
Bank0F_ScriptAddr_62B4:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF46                ; $46 wait_dungeon_flags: Wait until the running effect / animation finishes
    dw $FF41                ; $41 set_bgm: Music $61
    dw $0061                ;   song
    dw $FF12                ; $12 write_ram: The arena match: match 4  [$D9CD := 3]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0003                ;   value
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_62EC
    dw Bank0F_ScriptAddr_62EC ;   target
Bank0F_ScriptAddr_62C6:
    dw $FF41                ; $41 set_bgm: Music $3A
    dw $003A                ;   song
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0122                ; text $0122: "*:For the 1st match, the victory goes to…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF46                ; $46 wait_dungeon_flags: Wait until the running effect / animation finishes
    dw $FF41                ; $41 set_bgm: Music $61
    dw $0061                ;   song
    dw $FF12                ; $12 write_ram: The arena match: match 3  [$D9CD := 2]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0002                ;   value
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_62EC
    dw Bank0F_ScriptAddr_62EC ;   target
Bank0F_ScriptAddr_62E0:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0120                ; text $0120: "*:Ladies & Gents! Welcome to the Arena! …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF12                ; $12 write_ram: The arena match: match 2  [$D9CD := 1]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0001                ;   value
Bank0F_ScriptAddr_62EC:
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 4 tiles
    dw $0001                ;   actor
    dw $FFC0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks up 4 tiles
    dw $0002                ;   actor
    dw $FFC0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 4 tiles
    dw $0003                ;   actor
    dw $FFC0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 4 tiles
    dw $0004                ;   actor
    dw $FFC0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks up 1 tile
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 1 tile
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks left 1 tile
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 1 tile
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks left 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 4 walks left 1 tile
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4A                ; $4A face_right: NPC 3 faces right
    dw $0003                ;   actor
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 4  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6378  [$D9CD = 3]
    dw $D9CD                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_6378 ;   target
    dw $0121                ; text $0121: "*:Leeet's Rumble!"
    dw $FF03                ; $03 set_flag: Set flag $0121
    dw $0121                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_6378:
    dw $FF00                ; $00 if_flag_clear: If flag $0099 is clear → Bank0F_ScriptAddr_6386
    dw $0099                ;   flag
    dw Bank0F_ScriptAddr_6386 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class S  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_649A  [$D9CE = 7]
    dw $D9CE                ;   address
    dw $0007                ;   value
    dw Bank0F_ScriptAddr_649A ;   target
Bank0F_ScriptAddr_6386:
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class S  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6490  [$D9CE = 7]
    dw $D9CE                ;   address
    dw $0007                ;   value
    dw Bank0F_ScriptAddr_6490 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0094 is clear → Bank0F_ScriptAddr_639C
    dw $0094                ;   flag
    dw Bank0F_ScriptAddr_639C ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class A  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_648A  [$D9CE = 6]
    dw $D9CE                ;   address
    dw $0006                ;   value
    dw Bank0F_ScriptAddr_648A ;   target
Bank0F_ScriptAddr_639C:
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class A  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6480  [$D9CE = 6]
    dw $D9CE                ;   address
    dw $0006                ;   value
    dw Bank0F_ScriptAddr_6480 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0122 is clear → Bank0F_ScriptAddr_63B2
    dw $0122                ;   flag
    dw Bank0F_ScriptAddr_63B2 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class B  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_647A  [$D9CE = 5]
    dw $D9CE                ;   address
    dw $0005                ;   value
    dw Bank0F_ScriptAddr_647A ;   target
Bank0F_ScriptAddr_63B2:
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class B  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6470  [$D9CE = 5]
    dw $D9CE                ;   address
    dw $0005                ;   value
    dw Bank0F_ScriptAddr_6470 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0089 is clear → Bank0F_ScriptAddr_63C8
    dw $0089                ;   flag
    dw Bank0F_ScriptAddr_63C8 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class C  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_646A  [$D9CE = 4]
    dw $D9CE                ;   address
    dw $0004                ;   value
    dw Bank0F_ScriptAddr_646A ;   target
Bank0F_ScriptAddr_63C8:
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class C  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6460  [$D9CE = 4]
    dw $D9CE                ;   address
    dw $0004                ;   value
    dw Bank0F_ScriptAddr_6460 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0068 is clear → Bank0F_ScriptAddr_63DE
    dw $0068                ;   flag
    dw Bank0F_ScriptAddr_63DE ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class D  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_645A  [$D9CE = 3]
    dw $D9CE                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_645A ;   target
Bank0F_ScriptAddr_63DE:
    dw $FF00                ; $00 if_flag_clear: If flag $0067 is clear → Bank0F_ScriptAddr_63EC
    dw $0067                ;   flag
    dw Bank0F_ScriptAddr_63EC ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class D  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6450  [$D9CE = 3]
    dw $D9CE                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_6450 ;   target
Bank0F_ScriptAddr_63EC:
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class D  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6446  [$D9CE = 3]
    dw $D9CE                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_6446 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0048 is clear → Bank0F_ScriptAddr_6402
    dw $0048                ;   flag
    dw Bank0F_ScriptAddr_6402 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class E  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6440  [$D9CE = 2]
    dw $D9CE                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6440 ;   target
Bank0F_ScriptAddr_6402:
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class E  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6436  [$D9CE = 2]
    dw $D9CE                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6436 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0044 is clear → Bank0F_ScriptAddr_6418
    dw $0044                ;   flag
    dw Bank0F_ScriptAddr_6418 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class F  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6430  [$D9CE = 1]
    dw $D9CE                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6430 ;   target
Bank0F_ScriptAddr_6418:
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class F  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6426  [$D9CE = 1]
    dw $D9CE                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6426 ;   target
    dw $0125                ; text $0125: "*:I'm the principal of the Master School…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_6426:
    dw $01A2                ; text $01A2: "*:I'm conducting secret research at the …"
    dw $FF03                ; $03 set_flag: Set flag $0044
    dw $0044                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_6430:
    dw $01A3                ; text $01A3: "*:Being a master and a fighter is one fo…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_6436:
    dw $01E2                ; text $01E2: "*:Hey [HERO]. Welcome. *:I am Master Tet…"
    dw $FF03                ; $03 set_flag: Set flag $0048
    dw $0048                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_6440:
    dw $01E3                ; text $01E3: "*:Welcome back. Don't worry about losing…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_6446:
    dw $026F                ; text $026F: "*:You're my opponent? Is this a joke? *:…"
    dw $FF03                ; $03 set_flag: Set flag $0068
    dw $0068                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_6450:
    dw $0270                ; text $0270: "*:I wondered who it would be. Its' you! …"
    dw $FF03                ; $03 set_flag: Set flag $0068
    dw $0068                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_645A:
    dw $0271                ; text $0271: "*:You again? It'll be the same no matter…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_6460:
    dw $0330                ; text $0330: "*Hello [HERO]! I was expecting you. *:Be…"
    dw $FF03                ; $03 set_flag: Set flag $0089
    dw $0089                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_646A:
    dw $0331                ; text $0331: "*:How are you? I'm ready. *:Let's just b…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_6470:
    dw $035E                ; text $035E: "*:Oooo! Ahhhh! Where am I? *:What? The a…"
    dw $FF03                ; $03 set_flag: Set flag $0122
    dw $0122                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_647A:
    dw $035F                ; text $035F: "*:Hmm. You again? I hope you got better!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_6480:
    dw $03DE                ; text $03DE: "*:Welcome to A class. I was expecting yo…"
    dw $FF03                ; $03 set_flag: Set flag $0094
    dw $0094                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_648A:
    dw $03DF                ; text $03DF: "*:Maybe you'll do better next time [HERO…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_6490:
    dw $0409                ; text $0409: "*:Winning is not about luck but about on…"
    dw $FF03                ; $03 set_flag: Set flag $0099
    dw $0099                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_649C
    dw Bank0F_ScriptAddr_649C ;   target
Bank0F_ScriptAddr_649A:
    dw $040A                ; text $040A: "*:Perfect your ability and luck will fol…"
Bank0F_ScriptAddr_649C:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 4 walks right 1 tile
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 6 walks left 1 tile
    dw $0006                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 7 walks left 1 tile
    dw $0007                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 8 walks left 1 tile (script waits)
    dw $0008                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF20                ; $20 start_battle: Start the battle set up above (enemies / count)
    dw $FFFF                ; END

Bank0F_ScriptAddr_64CC:
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 1  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6998  [$D9CD = 0]
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_6998 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 2  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_697E  [$D9CD = 1]
    dw $D9CD                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_697E ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 3  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_671A  [$D9CD = 2]
    dw $D9CD                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_671A ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 4  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_64EE  [$D9CD = 3]
    dw $D9CD                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_64EE ;   target
    dw $FFFF                ; END

Bank0F_ScriptAddr_64EE:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: the monsters hidden (Terry shown)  [$C8ED := 14]
    dw $C8ED                ;   address
    dw $000E                ;   value
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $04E9                ; text $04E9: "Milayou:[HERO]! You were strong!"
    dw $FF41                ; $41 set_bgm: Music $3C
    dw $003C                ;   song
    dw $FF46                ; $46 wait_dungeon_flags: Wait until the running effect / animation finishes
    dw $FF41                ; $41 set_bgm: Music $61
    dw $0061                ;   song
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 7 is shown
    dw $0007                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 6, curve 4  [$D8E3 := $0406]
    dw $D8E3                ;   address
    dw $0406                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1C                ; $1C trigger_anim: NPC 7: fly in down-left (the flight path set above)
    dw $1507                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF41                ; $41 set_bgm: Music $02
    dw $0002                ;   song
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 7: jump
    dw $0407                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
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
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4 is hidden
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $04EA                ; text $04EA: "Warubou:Milayou! You're useless now!"
    dw $FF0A                ; $0A walk_x_wait: NPC 7 walks left 1 tile (script waits)
    dw $0007                ;   actor
    dw $FFF0                ;   pixels
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks left 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks up 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks left 3 tiles
    dw $0000                ;   actor
    dw $FFD0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $65
    dw $0065                ;   sound
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
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
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
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
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
    dw $FF48                ; $48 face_down: NPC 7 faces down
    dw $0007                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $57
    dw $0057                ;   sound
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1B                ; $1B npc_walk_y: NPC 7 walks up 1 tile
    dw $0007                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF21                ; $21 sound: Sound effect $57
    dw $0057                ;   sound
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1B                ; $1B npc_walk_y: NPC 7 walks up 1 tile
    dw $0007                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks left 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1B                ; $1B npc_walk_y: NPC 7 walks up 1 tile
    dw $0007                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 7 walks up 40 px
    dw $0007                ;   actor
    dw $FFD8                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 40 px
    dw $0001                ;   actor
    dw $FFD8                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 7 is hidden
    dw $0007                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF1C                ; $1C trigger_anim: the player: jump
    dw $0400                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: the player: hop
    dw $0100                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1C                ; $1C trigger_anim: the player: hop
    dw $0100                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF03                ; $03 set_flag: Set flag $00E4
    dw $00E4                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Farm screen 0 → state 3  [$D93F := 3]
    dw $D93F                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 1 → state 2  [$D940 := 2]
    dw $D940                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 2 → state 4  [$D941 := 4]
    dw $D941                ;   address
    dw $0004                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 4 → state 3  [$D942 := 3]
    dw $D942                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 5 → state 2  [$D943 := 2]
    dw $D943                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 6 → state 3  [$D944 := 3]
    dw $D944                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 1 → state 2  [$D952 := 2]
    dw $D952                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: The intro bedroom screen 4 state: 2  [$D974 := 2]
    dw $D974                ;   address
    dw $0002                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The game mode: the bank $02 picture scenes (the ceremony, the tree)  [$C88A := 3]
    dw $C88A                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: The next game mode: the field  [$C88B := 1]
    dw $C88B                ;   address
    dw $0001                ;   value
    dw $FF3E                ; $3E change_game_mode: Fade out and switch to the game mode in $C88B (e.g. a naming screen) — $C88E is the main loop's mode request
    dw $FFFF                ; END
Bank0F_ScriptAddr_671A:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: the monsters hidden (Terry shown)  [$C8ED := 14]
    dw $C8ED                ;   address
    dw $000E                ;   value
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF12                ; $12 write_ram: The arena match: match 4  [$D9CD := 3]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0003                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $04E3                ; text $04E3: "*:Ladies & Gents, Let's begin the final …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF41                ; $41 set_bgm: Music $37
    dw $0037                ;   song
    dw $FF46                ; $46 wait_dungeon_flags: Wait until the running effect / animation finishes
    dw $FF41                ; $41 set_bgm: Music $61
    dw $0061                ;   song
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF4A                ; $4A face_right: NPC 6 faces right
    dw $0006                ;   actor
    dw $FF4A                ; $4A face_right: NPC 7 faces right
    dw $0007                ;   actor
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF47                ; $47 face_up: NPC 5 faces up
    dw $0005                ;   actor
    dw $FF47                ; $47 face_up: NPC 6 faces up
    dw $0006                ;   actor
    dw $FF47                ; $47 face_up: NPC 7 faces up
    dw $0007                ;   actor
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF49                ; $49 face_left: NPC 5 faces left
    dw $0005                ;   actor
    dw $FF49                ; $49 face_left: NPC 6 faces left
    dw $0006                ;   actor
    dw $FF49                ; $49 face_left: NPC 7 faces left
    dw $0007                ;   actor
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $04E4                ; text $04E4: "*:And now, the feared talk of the town..…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF41                ; $41 set_bgm: Music $61
    dw $0061                ;   song
    dw $FF1C                ; $1C trigger_anim: the player: jump
    dw $0400                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 3 ticks (~24 frames)
    dw $0003                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF41                ; $41 set_bgm: Music $02
    dw $0002                ;   song
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $65
    dw $0065                ;   sound
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
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
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
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
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
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 8 is shown
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 8 is hidden
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0D                ; $0D npc_write: NPC 1: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF41                ; $41 set_bgm: Music $61
    dw $0061                ;   song
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF01                ; $01 if_flag_set: If flag $0158 is set → Bank0F_ScriptAddr_68A0
    dw $0158                ;   flag
    dw Bank0F_ScriptAddr_68A0 ;   target
    dw $04E5                ; text $04E5: "Milayou:Why...I Can't believe.. why [HER…"
    dw $FF03                ; $03 set_flag: Set flag $0158
    dw $0158                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_68A2
    dw Bank0F_ScriptAddr_68A2 ;   target
Bank0F_ScriptAddr_68A0:
    dw $04E6                ; text $04E6: "Milayou:[HERO], Are you challenging me a…"
Bank0F_ScriptAddr_68A2:
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF0D                ; $0D npc_write: NPC 8: x low byte := 56
    dw $0008                ;   actor
    dw $0018                ;   field
    dw $0038                ;   value
    dw $FF0D                ; $0D npc_write: NPC 8: y low byte := 104
    dw $0008                ;   actor
    dw $001A                ;   field
    dw $0068                ;   value
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 8 is shown
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 8 is hidden
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 8: y low byte := 72
    dw $0008                ;   actor
    dw $001A                ;   field
    dw $0048                ;   value
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 8 is shown
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 8 is hidden
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 8: y low byte := 88
    dw $0008                ;   actor
    dw $001A                ;   field
    dw $0058                ;   value
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 8 is shown
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 8 is hidden
    dw $0008                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 4 walks right 1 tile
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 5 walks left 1 tile
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 6 walks left 1 tile
    dw $0006                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 7 walks left 1 tile
    dw $0007                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF20                ; $20 start_battle: Start the battle set up above (enemies / count)
    dw $FFFF                ; END
Bank0F_ScriptAddr_697E:
    dw $FF41                ; $41 set_bgm: Music $3A
    dw $003A                ;   song
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $04E1                ; text $04E1: "*:The rep of GreatTree won by *:enchanti…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF46                ; $46 wait_dungeon_flags: Wait until the running effect / animation finishes
    dw $FF41                ; $41 set_bgm: Music $61
    dw $0061                ;   song
    dw $FF12                ; $12 write_ram: The arena match: match 3  [$D9CD := 2]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0002                ;   value
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_69AA
    dw Bank0F_ScriptAddr_69AA ;   target
Bank0F_ScriptAddr_6998:
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $04DF                ; text $04DF: "*:Ladies & Gents! Welcome! *:Tonight is …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF12                ; $12 write_ram: The arena match: match 2  [$D9CD := 1]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0001                ;   value
Bank0F_ScriptAddr_69AA:
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 4 tiles
    dw $0001                ;   actor
    dw $FFC0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks up 4 tiles
    dw $0002                ;   actor
    dw $FFC0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 4 tiles
    dw $0003                ;   actor
    dw $FFC0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 4 tiles
    dw $0004                ;   actor
    dw $FFC0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks up 1 tile
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 1 tile
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks left 1 tile
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 1 tile
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks left 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 4 walks left 1 tile
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4A                ; $4A face_right: NPC 3 faces right
    dw $0003                ;   actor
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 3  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6A32  [$D9CD = 2]
    dw $D9CD                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6A32 ;   target
    dw $04E0                ; text $04E0: "*:BigTrunk vs. GreatTree! *:Let's begin!…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6A34
    dw Bank0F_ScriptAddr_6A34 ;   target
Bank0F_ScriptAddr_6A32:
    dw $04E2                ; text $04E2: "*:DeadTree vs. GreatTree! *:Let's begin!…"
Bank0F_ScriptAddr_6A34:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 4 walks right 1 tile
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 6 walks left 1 tile
    dw $0006                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 7 walks left 1 tile
    dw $0007                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 8 walks left 1 tile (script waits)
    dw $0008                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF20                ; $20 start_battle: Start the battle set up above (enemies / count)
    dw $FFFF                ; END
Bank0F_ScriptAddr_6A64:
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FF15                ; $15 check_and_branch: If “the arena match” is match 1  (meaning inferred from the scripts that use it) → Bank0F_ScriptAddr_6AA6  [$D9CD = 0]
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_6AA6 ;   target
    dw $FF41                ; $41 set_bgm: Music $37
    dw $0037                ;   song
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0F_ScriptAddr_6A84
    dw $0111                ;   flag
    dw Bank0F_ScriptAddr_6A84 ;   target
    dw $084A                ; text $084A: "*:Ladies & Gents! He made it! [HERO] won…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6A86
    dw Bank0F_ScriptAddr_6A86 ;   target
Bank0F_ScriptAddr_6A84:
    dw $08D8                ; text $08D8: "*:Ladies & Gents! The victory goes to [H…"
Bank0F_ScriptAddr_6A86:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF46                ; $46 wait_dungeon_flags: Wait until the running effect / animation finishes
    dw $FF41                ; $41 set_bgm: Music $61
    dw $0061                ;   song
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF12                ; $12 write_ram: The arena match: the special match  [$D9CD := 254]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $00FE                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0111
    dw $0111                ;   flag
    dw $FF0F                ; $0F map_transition: Go to Arena Lobby at (14, 4)
    dw $0006                ;   map
    dw $00E8                ;   x
    dw $0048                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0F_ScriptAddr_6AA6:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0F_ScriptAddr_6AC0
    dw $0111                ;   flag
    dw Bank0F_ScriptAddr_6AC0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0110 is set → Bank0F_ScriptAddr_6ABA
    dw $0110                ;   flag
    dw Bank0F_ScriptAddr_6ABA ;   target
    dw $0845                ; text $0845: "*:Ladies & Gents, welcome back [HERO]! *…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6AC2
    dw Bank0F_ScriptAddr_6AC2 ;   target
Bank0F_ScriptAddr_6ABA:
    dw $0848                ; text $0848: "*:Ladies & Gents, please welcome [HERO]!…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6AC2
    dw Bank0F_ScriptAddr_6AC2 ;   target
Bank0F_ScriptAddr_6AC0:
    dw $08D6                ; text $08D6: "*:Everybody listen! The Master Monster T…"
Bank0F_ScriptAddr_6AC2:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF12                ; $12 write_ram: The arena match: match 4  [$D9CD := 3]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0003                ;   value
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 4 tiles
    dw $0001                ;   actor
    dw $FFC0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks up 4 tiles
    dw $0002                ;   actor
    dw $FFC0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 4 tiles
    dw $0003                ;   actor
    dw $FFC0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 4 tiles
    dw $0004                ;   actor
    dw $FFC0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks up 1 tile
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 1 tile
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks left 1 tile
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 1 tile
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks left 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 4 walks left 1 tile
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4A                ; $4A face_right: NPC 3 faces right
    dw $0003                ;   actor
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0F_ScriptAddr_6B5E
    dw $0111                ;   flag
    dw Bank0F_ScriptAddr_6B5E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0110 is set → Bank0F_ScriptAddr_6B58
    dw $0110                ;   flag
    dw Bank0F_ScriptAddr_6B58 ;   target
    dw $0846                ; text $0846: "*:Whoa! The challenger is the Master Mon…"
    dw $0847                ; text $0847: "*:Ha Ha. [HERO], surprised? *:I couldn't…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6B60
    dw Bank0F_ScriptAddr_6B60 ;   target
Bank0F_ScriptAddr_6B58:
    dw $0849                ; text $0849: "*:Ha Ha Ha. You came again. *:How are yo…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6B60
    dw Bank0F_ScriptAddr_6B60 ;   target
Bank0F_ScriptAddr_6B5E:
    dw $08D7                ; text $08D7: "*:Hm. [HERO]. *:Even though I lost, it d…"
Bank0F_ScriptAddr_6B60:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 4 walks right 1 tile
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 6 walks left 1 tile
    dw $0006                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 7 walks left 1 tile
    dw $0007                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 8 walks left 1 tile (script waits)
    dw $0008                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF03                ; $03 set_flag: Set flag $0110
    dw $0110                ;   flag
    dw $FF20                ; $20 start_battle: Start the battle set up above (enemies / count)
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Map5E Per-Script Table (map_type=$5E, 1 scripts)
; ---------------------------------------------------------------------------
Map5E_ScriptPtrTable:
    dw Map5E_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map5E_Script00
; ---------------------------------------------------------------------------
Map5E_Script00:
    dw $FF15                ; $15 check_and_branch: If “the room state of Arena Setup Room (white, 2 Terrys) screen 0” is state 3 → Bank0F_ScriptAddr_6C1A  [$D99A = 3]
    dw $D99A                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_6C1A ;   target
    dw $FF15                ; $15 check_and_branch: If “the room state of Arena Setup Room (white, 2 Terrys) screen 0” is state 2 → Bank0F_ScriptAddr_6C18  [$D99A = 2]
    dw $D99A                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6C18 ;   target
    dw $FF15                ; $15 check_and_branch: If “the room state of Arena Setup Room (white, 2 Terrys) screen 0” is state 1 → Bank0F_ScriptAddr_6BB0  [$D99A = 1]
    dw $D99A                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6BB0 ;   target
    dw $FFFF                ; END

Bank0F_ScriptAddr_6BB0:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $2E07)
    dw $2E07                ;   data
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks right 4 tiles (script waits)
    dw $0001                ;   actor
    dw $0040                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks left 3 tiles (script waits)
    dw $0000                ;   actor
    dw $FFD0                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF39                ; $39 load_text: Prepare text $09F7 without showing it: “[HERO] received [INS 20]. Please raise i…”
    dw $09F7                ;   text
    dw $FF0A                ; $0A walk_x_wait: the player walks right 3 tiles (script waits)
    dw $0000                ;   actor
    dw $0030                ;   pixels
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: The game mode: the title screen  [$C88A := 0]
    dw $C88A                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The next game mode: the field  [$C88B := 1]
    dw $C88B                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: The mode-change request: 1  [$C88E := 1]
    dw $C88E                ;   address
    dw $0001                ;   value
    dw $FF26                ; $26 reload_room: Reload the room
    dw $FFFF                ; END

Bank0F_ScriptAddr_6C18:
    dw $FFFF                ; END

Bank0F_ScriptAddr_6C1A:
    dw $FF09                ; $09 delay: Wait 40 ticks (~320 frames)
    dw $0028                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $9D
    dw $009D                ;   sound
    dw $FF09                ; $09 delay: Wait 40 ticks (~320 frames)
    dw $0028                ;   ticks
    dw $FF41                ; $41 set_bgm: Music $02
    dw $0002                ;   song
    dw $FF0F                ; $0F map_transition: Go to Intro Bedroom (2-screen, crashes) at (3, 12)
    dw $002F                ;   map
    dw $0038                ;   x
    dw $00C8                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

    dw $6C42                ; script 0
    dw $6C44                ; script 1
    dw $6D72                ; script 2
    dw $6E52                ; script 3
    dw $6ED0                ; script 4
    dw $6EF6                ; script 5
    dw $6F42                ; script 6
    dw $FFFF                ; END
    dw $FF53                ; $53 npc1_face_player: NPC 1 turns toward the player
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If $C92C = 1 → Bank0F_ScriptAddr_6C72  [$C92C = 1]
    dw $C92C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6C72 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 2 → Bank0F_ScriptAddr_6C7A  [$C92C = 2]
    dw $C92C                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6C7A ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 3 → Bank0F_ScriptAddr_6C82  [$C92C = 3]
    dw $C92C                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_6C82 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 4 → Bank0F_ScriptAddr_6C8A  [$C92C = 4]
    dw $C92C                ;   address
    dw $0004                ;   value
    dw Bank0F_ScriptAddr_6C8A ;   target
    dw $09C0                ; text $09C0: "*:You're a wimp. But I'm not going to sh…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6C92
    dw Bank0F_ScriptAddr_6C92 ;   target
Bank0F_ScriptAddr_6C72:
    dw $09C3                ; text $09C3: "*:You have good monsters with you. Let's…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6C92
    dw Bank0F_ScriptAddr_6C92 ;   target
Bank0F_ScriptAddr_6C7A:
    dw $09C6                ; text $09C6: "*:I'm a master from DeadTree! Let's figh…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6C92
    dw Bank0F_ScriptAddr_6C92 ;   target
Bank0F_ScriptAddr_6C82:
    dw $09C9                ; text $09C9: "*:You're like a dizzy person on a cliff."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6C92
    dw Bank0F_ScriptAddr_6C92 ;   target
Bank0F_ScriptAddr_6C8A:
    dw $09CC                ; text $09CC: "*:I'm a master of GreatLog. I'll fight y…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6C92
    dw Bank0F_ScriptAddr_6C92 ;   target
Bank0F_ScriptAddr_6C92:
    dw $FF52                ; $52 random_battle: Fight 3 random monsters scaled to the party's levels
    dw $FF15                ; $15 check_and_branch: If $DB55 = 1 → Bank0F_ScriptAddr_6CDC  [$DB55 = 1]
    dw $DB55                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6CDC ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If $C92C = 1 → Bank0F_ScriptAddr_6CC4  [$C92C = 1]
    dw $C92C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6CC4 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 2 → Bank0F_ScriptAddr_6CCA  [$C92C = 2]
    dw $C92C                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6CCA ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 3 → Bank0F_ScriptAddr_6CD0  [$C92C = 3]
    dw $C92C                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_6CD0 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 4 → Bank0F_ScriptAddr_6CD6  [$C92C = 4]
    dw $C92C                ;   address
    dw $0004                ;   value
    dw Bank0F_ScriptAddr_6CD6 ;   target
    dw $09C1                ; text $09C1: "*:L..Lost? Need more training!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D1C
    dw Bank0F_ScriptAddr_6D1C ;   target
Bank0F_ScriptAddr_6CC4:
    dw $09C4                ; text $09C4: "*:How annoying..."
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D1C
    dw Bank0F_ScriptAddr_6D1C ;   target
Bank0F_ScriptAddr_6CCA:
    dw $09C7                ; text $09C7: "*:I'll beat you next time! You wait!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D1C
    dw Bank0F_ScriptAddr_6D1C ;   target
Bank0F_ScriptAddr_6CD0:
    dw $09CA                ; text $09CA: "*:Old soldiers shouldn't talk just leave…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D1C
    dw Bank0F_ScriptAddr_6D1C ;   target
Bank0F_ScriptAddr_6CD6:
    dw $09CD                ; text $09CD: "*:Darn! I lost! It can't be!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D1C
    dw Bank0F_ScriptAddr_6D1C ;   target
Bank0F_ScriptAddr_6CDC:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If $C92C = 1 → Bank0F_ScriptAddr_6D04  [$C92C = 1]
    dw $C92C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6D04 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 2 → Bank0F_ScriptAddr_6D0A  [$C92C = 2]
    dw $C92C                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6D0A ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 3 → Bank0F_ScriptAddr_6D10  [$C92C = 3]
    dw $C92C                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_6D10 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 4 → Bank0F_ScriptAddr_6D16  [$C92C = 4]
    dw $C92C                ;   address
    dw $0004                ;   value
    dw Bank0F_ScriptAddr_6D16 ;   target
    dw $09C2                ; text $09C2: "*:Come back after more training."
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
Bank0F_ScriptAddr_6D04:
    dw $09C5                ; text $09C5: "*:It was a good fight."
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
Bank0F_ScriptAddr_6D0A:
    dw $09C8                ; text $09C8: "*:I knew the master from GreatTree was a…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
Bank0F_ScriptAddr_6D10:
    dw $09CB                ; text $09CB: "*:Watch your back next time."
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
Bank0F_ScriptAddr_6D16:
    dw $09CE                ; text $09CE: "*:I can accept your challenge again if I…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
Bank0F_ScriptAddr_6D1C:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_6D2A
    dw Bank0F_ScriptAddr_6D2A ;   target
    dw $FF2A                ; $2A give_item: Give item 29
    dw $001D                ;   item
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09EA                ; text $09EA: "[HERO] got a WarpWing!"
Bank0F_ScriptAddr_6D2A:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_6D32
    dw Bank0F_ScriptAddr_6D32 ;   target
    dw $FF54                ; $54 give_random_item: Give a random item 1-37
    dw $09EB                ; text $09EB: "[HERO] got a [INS 00]!"
Bank0F_ScriptAddr_6D32:
    dw $FF1C                ; $1C trigger_anim: NPC 1: vanish (flicker out)
    dw $0D01                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FFFF                ; END
Bank0F_ScriptAddr_6D3A:
    dw $FF55                ; $55 take_random_item: Take a random item from the bag (count to $D8E1)
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 0 → Bank0F_ScriptAddr_6D46  [$D8E1 = 0]
    dw $D8E1                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_6D46 ;   target
    dw $09EC                ; text $09EC: "[HERO]'s [INS 00] was taken away!"
Bank0F_ScriptAddr_6D46:
    dw $FF55                ; $55 take_random_item: Take a random item from the bag (count to $D8E1)
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 0 → Bank0F_ScriptAddr_6D52  [$D8E1 = 0]
    dw $D8E1                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_6D52 ;   target
    dw $09EC                ; text $09EC: "[HERO]'s [INS 00] was taken away!"
Bank0F_ScriptAddr_6D52:
    dw $FF56                ; $56 gold_value: Take a tenth of the gold (the check result: had 10 G or more)
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 0 → Bank0F_ScriptAddr_6D5E  [$D8E1 = 0]
    dw $D8E1                ;   address
    dw $0000                ;   value
    dw Bank0F_ScriptAddr_6D5E ;   target
    dw $09ED                ; text $09ED: "[INS 00] in Gold was taken away!"
Bank0F_ScriptAddr_6D5E:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_6D6A
    dw Bank0F_ScriptAddr_6D6A ;   target
    dw $FF2A                ; $2A give_item: Give item 29
    dw $001D                ;   item
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09F5                ; text $09F5: "Got a WarpWing!"
Bank0F_ScriptAddr_6D6A:
    dw $FF1C                ; $1C trigger_anim: NPC 1: vanish (flicker out)
    dw $0D01                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FFFF                ; END
    dw $FF15                ; $15 check_and_branch: If “NPC 1: shown / type” is 15 → Bank0F_ScriptAddr_6D7E  [$D7D2 = 15]
    dw $D7D2                ;   address
    dw $000F                ;   value
    dw Bank0F_ScriptAddr_6D7E ;   target
    dw $FF53                ; $53 npc1_face_player: NPC 1 turns toward the player
    dw $FF08                ; $08 nop: Nothing (one tick)
Bank0F_ScriptAddr_6D7E:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If $C92C = 1 → Bank0F_ScriptAddr_6DA8  [$C92C = 1]
    dw $C92C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6DA8 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 2 → Bank0F_ScriptAddr_6DB0  [$C92C = 2]
    dw $C92C                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6DB0 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 3 → Bank0F_ScriptAddr_6DB8  [$C92C = 3]
    dw $C92C                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_6DB8 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 4 → Bank0F_ScriptAddr_6DC0  [$C92C = 4]
    dw $C92C                ;   address
    dw $0004                ;   value
    dw Bank0F_ScriptAddr_6DC0 ;   target
    dw $09CF                ; text $09CF: "*:Oh, such a cute little master. Will yo…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6DC8
    dw Bank0F_ScriptAddr_6DC8 ;   target
Bank0F_ScriptAddr_6DA8:
    dw $09D2                ; text $09D2: "*:I'm from GreatLog. Would you like to f…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6DC8
    dw Bank0F_ScriptAddr_6DC8 ;   target
Bank0F_ScriptAddr_6DB0:
    dw $09D5                ; text $09D5: "*:It's too dangerous for you. Go home!"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6DC8
    dw Bank0F_ScriptAddr_6DC8 ;   target
Bank0F_ScriptAddr_6DB8:
    dw $09D8                ; text $09D8: "*:So, you're the master of GreatTree. I …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6DC8
    dw Bank0F_ScriptAddr_6DC8 ;   target
Bank0F_ScriptAddr_6DC0:
    dw $09DB                ; text $09DB: "*:Aren't you a little big headed? There'…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6DC8
    dw Bank0F_ScriptAddr_6DC8 ;   target
Bank0F_ScriptAddr_6DC8:
    dw $FF52                ; $52 random_battle: Fight 3 random monsters scaled to the party's levels
    dw $FF15                ; $15 check_and_branch: If $DB55 = 1 → Bank0F_ScriptAddr_6E12  [$DB55 = 1]
    dw $DB55                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6E12 ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If $C92C = 1 → Bank0F_ScriptAddr_6DFA  [$C92C = 1]
    dw $C92C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6DFA ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 2 → Bank0F_ScriptAddr_6E00  [$C92C = 2]
    dw $C92C                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6E00 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 3 → Bank0F_ScriptAddr_6E06  [$C92C = 3]
    dw $C92C                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_6E06 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 4 → Bank0F_ScriptAddr_6E0C  [$C92C = 4]
    dw $C92C                ;   address
    dw $0004                ;   value
    dw Bank0F_ScriptAddr_6E0C ;   target
    dw $09D0                ; text $09D0: "*:So you did it. Watch out for the next …"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D1C
    dw Bank0F_ScriptAddr_6D1C ;   target
Bank0F_ScriptAddr_6DFA:
    dw $09D3                ; text $09D3: "*:How dare you! I won't forget your face…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D1C
    dw Bank0F_ScriptAddr_6D1C ;   target
Bank0F_ScriptAddr_6E00:
    dw $09D6                ; text $09D6: "*:Oh, I guess there is nothing to worry …"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D1C
    dw Bank0F_ScriptAddr_6D1C ;   target
Bank0F_ScriptAddr_6E06:
    dw $09D9                ; text $09D9: "*:You're as good as the rumors. I was co…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D1C
    dw Bank0F_ScriptAddr_6D1C ;   target
Bank0F_ScriptAddr_6E0C:
    dw $09DC                ; text $09DC: "*:Oh, you're a bit better than me."
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D1C
    dw Bank0F_ScriptAddr_6D1C ;   target
Bank0F_ScriptAddr_6E12:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If $C92C = 1 → Bank0F_ScriptAddr_6E3A  [$C92C = 1]
    dw $C92C                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6E3A ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 2 → Bank0F_ScriptAddr_6E40  [$C92C = 2]
    dw $C92C                ;   address
    dw $0002                ;   value
    dw Bank0F_ScriptAddr_6E40 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 3 → Bank0F_ScriptAddr_6E46  [$C92C = 3]
    dw $C92C                ;   address
    dw $0003                ;   value
    dw Bank0F_ScriptAddr_6E46 ;   target
    dw $FF15                ; $15 check_and_branch: If $C92C = 4 → Bank0F_ScriptAddr_6E4C  [$C92C = 4]
    dw $C92C                ;   address
    dw $0004                ;   value
    dw Bank0F_ScriptAddr_6E4C ;   target
    dw $09D1                ; text $09D1: "*:Giggle, just because I'm a girl, it wo…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
Bank0F_ScriptAddr_6E3A:
    dw $09D4                ; text $09D4: "*:It came to me after the fight. I am st…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
Bank0F_ScriptAddr_6E40:
    dw $09D7                ; text $09D7: "*:Be careful! Go straight home!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
Bank0F_ScriptAddr_6E46:
    dw $09DA                ; text $09DA: "*:I'm bummed. You're not as good as the …"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
Bank0F_ScriptAddr_6E4C:
    dw $09DD                ; text $09DD: "*:See, you played good and got knocked o…"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
    dw $09DE                ; text $09DE: "*:It must be the destiny to meet you her…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF52                ; $52 random_battle: Fight 3 random monsters scaled to the party's levels
    dw $FF15                ; $15 check_and_branch: If $DB55 = 1 → Bank0F_ScriptAddr_6EC8  [$DB55 = 1]
    dw $DB55                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6EC8 ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09DF                ; text $09DF: "*:As I promised... Restore POWER..."
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
    dw $FF1C                ; $1C trigger_anim: NPC 1: vanish (flicker out)
    dw $0D01                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FFFF                ; END
Bank0F_ScriptAddr_6EC8:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09E0                ; text $09E0: "*:Behave!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
    dw $09E1                ; text $09E1: "*:I'm a wizard and a master! *:If you wi…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF52                ; $52 random_battle: Fight 3 random monsters scaled to the party's levels
    dw $FF15                ; $15 check_and_branch: If $DB55 = 1 → Bank0F_ScriptAddr_6EEE  [$DB55 = 1]
    dw $DB55                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6EEE ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09E2                ; text $09E2: "*:I'll show you my power. Close your eye…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF58                ; $58 floor_skip: Gate floors: jump about 20 floors deeper
    dw $FF1C                ; not reached — as a script word: $1C trigger_anim
    dw $0D01                ; not reached
    dw $FF19                ; not reached — as a script word: $19 wait_movement
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0F_ScriptAddr_6EEE:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09E3                ; text $09E3: "*:Ho, ho, ho. Sucker!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
    dw $09E4                ; text $09E4: "*:I'm a master too. Want to fight? *:If …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF52                ; $52 random_battle: Fight 3 random monsters scaled to the party's levels
    dw $FF15                ; $15 check_and_branch: If $DB55 = 1 → Bank0F_ScriptAddr_6F3A  [$DB55 = 1]
    dw $DB55                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6F3A ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09E5                ; text $09E5: "*:Here is the medicine."
    dw $FF59                ; $59 train_slot: party monster 1: raise its weakest stat by 20
    dw $0000                ;   slot
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 255 → Bank0F_ScriptAddr_6F32  [$D8E1 = 255]
    dw $D8E1                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_6F32 ;   target
    dw $09EE                ; text $09EE: "[INS 00]'s [INS 10] increases by 20!"
    dw $FF59                ; $59 train_slot: party monster 2: raise its weakest stat by 20
    dw $0001                ;   slot
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 255 → Bank0F_ScriptAddr_6F32  [$D8E1 = 255]
    dw $D8E1                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_6F32 ;   target
    dw $09EE                ; text $09EE: "[INS 00]'s [INS 10] increases by 20!"
    dw $FF59                ; $59 train_slot: party monster 3: raise its weakest stat by 20
    dw $0002                ;   slot
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 255 → Bank0F_ScriptAddr_6F32  [$D8E1 = 255]
    dw $D8E1                ;   address
    dw $00FF                ;   value
    dw Bank0F_ScriptAddr_6F32 ;   target
    dw $09EE                ; text $09EE: "[INS 00]'s [INS 10] increases by 20!"
Bank0F_ScriptAddr_6F32:
    dw $FF1C                ; $1C trigger_anim: NPC 1: vanish (flicker out)
    dw $0D01                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FFFF                ; END
Bank0F_ScriptAddr_6F3A:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09E6                ; text $09E6: "*:Too bad! See you again!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
    dw $09E7                ; text $09E7: "*:I'm a master and a merchant. *:Why not…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF52                ; $52 random_battle: Fight 3 random monsters scaled to the party's levels
    dw $FF15                ; $15 check_and_branch: If $DB55 = 1 → Bank0F_ScriptAddr_6F68  [$DB55 = 1]
    dw $DB55                ;   address
    dw $0001                ;   value
    dw Bank0F_ScriptAddr_6F68 ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09E8                ; text $09E8: "*:It was close. Oh well."
Bank0F_ScriptAddr_6F54:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0F_ScriptAddr_6F60
    dw Bank0F_ScriptAddr_6F60 ;   target
    dw $FF57                ; $57 give_random_item2: Give a random item $13-$17
    dw $09EB                ; text $09EB: "[HERO] got a [INS 00]!"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6F54
    dw Bank0F_ScriptAddr_6F54 ;   target
Bank0F_ScriptAddr_6F60:
    dw $FF1C                ; $1C trigger_anim: NPC 1: vanish (flicker out)
    dw $0D01                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FFFF                ; END
Bank0F_ScriptAddr_6F68:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $09E9                ; text $09E9: "*:Do you understand my power now?"
    dw $FF14                ; $14 goto: Go to Bank0F_ScriptAddr_6D3A
    dw Bank0F_ScriptAddr_6D3A ;   target
; ---------------------------------------------------------------------------
; Map5F Per-Script Table (map_type=$5F, 0 scripts)
; ---------------------------------------------------------------------------
Map5F_ScriptPtrTable:
    dw Map53_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map53_Script00
; ---------------------------------------------------------------------------
Map53_Script00:
    dw $FFFF                ; END

    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
