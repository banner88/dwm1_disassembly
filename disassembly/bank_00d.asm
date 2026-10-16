; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $00d", ROMX[$4000], BANK[$d]

    db $0d ;ROM Bank

    dw LoadBd_4007
    dw ScriptBank0DDrawTiles
    dw ScriptBank0DDrawAttrs

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
ScriptBank0DDrawTiles:
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

; S118: script op $61 draw_attrs (ScriptCmd61_DrawAttrs, entry 2): like entry 1
; it reads ONE more script word (a patch address in this bank) and writes the
; patch to VRAM bank 1 (the BG attributes) on GBC.
ScriptBank0DDrawAttrs:
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
    dw $7C3E                ; map type $00: another bank's — filler, never read here
    dw $7C3E                ; map type $01: another bank's — filler, never read here
    dw $7C3E                ; map type $02: another bank's — filler, never read here
    dw $7C3E                ; map type $03: another bank's — filler, never read here
    dw $7C3E                ; map type $04: another bank's — filler, never read here
    dw $7C3E                ; map type $05: another bank's — filler, never read here
    dw ArenaLobby_ScriptPtrTable ; map type $06: Arena Lobby
    dw ArenaRooms_ScriptPtrTable ; map type $07: Arena Rooms
    dw Map08_ScriptPtrTable ; map type $08: Starry Shrine Breeding Cutscene
    dw Map09_ScriptPtrTable ; map type $09: Starry Shrine
    dw Map0A_ScriptPtrTable ; map type $0A: Secret Passage
    dw Map0B_ScriptPtrTable ; map type $0B: Castle (unused copy 1)
    dw GateTileset_ScriptPtrTable ; map type $0C: Egg Evaluator
    dw Map0D_ScriptPtrTable ; map type $0D: Old Man Gate Room
    dw Map0E_ScriptPtrTable ; map type $0E: Castle (unused copy 2)
    dw Map0F_ScriptPtrTable ; map type $0F: Vault
    dw CopycatRoom_ScriptPtrTable ; map type $10: Copycat House
    dw Map11_ScriptPtrTable ; map type $11: Castle (unused copy 3)
    dw Map12_ScriptPtrTable ; map type $12: Library
    dw Map13_ScriptPtrTable ; map type $13: Library Gate Room
    dw Map14_ScriptPtrTable ; map type $14: Castle (unused copy 4)
    dw Map15_ScriptPtrTable ; map type $15: Castle (unused copy 5)
    dw MedalMan_ScriptPtrTable ; map type $16: MedalMan
    dw Map17_ScriptPtrTable ; map type $17: Copycat House (Glitched)
    dw Well_ScriptPtrTable  ; map type $18: Well
    dw Map19_ScriptPtrTable ; map type $19: Goopy Room 1 (scr8)
    dw Map1A_ScriptPtrTable ; map type $1A: Goopy Room 2 (scr8)
    dw Map1B_ScriptPtrTable ; map type $1B: Stable: KingSlime Room
    dw Map1C_ScriptPtrTable ; map type $1C: Stable: Coffin Room
    dw Map1D_ScriptPtrTable ; map type $1D: Monster School
    dw Map1E_ScriptPtrTable ; map type $1E: Restaurant
    dw Map1F_ScriptPtrTable ; map type $1F: Queen Room
; ---------------------------------------------------------------------------
; ArenaLobby Per-Script Table (map_type=$06, 12 scripts)
; ---------------------------------------------------------------------------
ArenaLobby_ScriptPtrTable:
    dw ArenaLobby_Script00  ; script 0
    dw ArenaLobby_Script01  ; script 1
    dw ArenaLobby_Script02  ; script 2
    dw ArenaLobby_Script03  ; script 3
    dw ArenaLobby_Script04  ; script 4
    dw ArenaLobby_Script05  ; script 5
    dw ArenaLobby_Script06  ; script 6
    dw ArenaLobby_Script07  ; script 7
    dw ArenaLobby_Script08  ; script 8
    dw ArenaLobby_Script09  ; script 9
    dw ArenaLobby_Script10  ; script 10
    dw ArenaLobby_Script11  ; script 11
; ---------------------------------------------------------------------------
; ArenaLobby_Script00
; ---------------------------------------------------------------------------
ArenaLobby_Script00:
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is back to the Arena Lobby / Restaurant / Queen → Bank0D_ScriptAddr_46F2  [$D951 = 242]
    dw $D951                ;   address
    dw $00F2                ;   value
    dw Bank0D_ScriptAddr_46F2 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 1 → Bank0D_ScriptAddr_4228
    dw $0001                ;   screen
    dw Bank0D_ScriptAddr_4228 ;   target
    dw $FFFF                ; END

Bank0D_ScriptAddr_4228:
    dw $FF15                ; $15 check_and_branch: If “the arena match” is the special match  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_4270  [$D9CD = 254]
    dw $D9CD                ;   address
    dw $00FE                ;   value
    dw Bank0D_ScriptAddr_4270 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena match” is none  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_4242  [$D9CD = 255]
    dw $D9CD                ;   address
    dw $00FF                ;   value
    dw Bank0D_ScriptAddr_4242 ;   target
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_4242:
    dw $FF27                ; $27 refresh_party: Heal every monster — HP and MP to full, ailments cured (bank $01 entry 9 IteratePartySlots20 over the 20 slots, PyBoy-measured S125), then entry 3
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_426C
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_426C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0D_ScriptAddr_4268
    dw $0030                ;   flag
    dw Bank0D_ScriptAddr_4268 ;   target
    dw $00E3                ; text $00E3: "*:Too bad. You need more training. *:The…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4268:
    dw $0179                ; text $0179: "*:Too bad. Your monsters are too weak. *…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_426C:
    dw $043A                ; text $043A: "*:It's unfortunate but you have weak mon…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4270:
    dw $FF27                ; $27 refresh_party: Heal every monster — HP and MP to full, ailments cured (bank $01 entry 9 IteratePartySlots20 over the 20 slots, PyBoy-measured S125), then entry 3
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0D_ScriptAddr_42C6
    dw $0111                ;   flag
    dw Bank0D_ScriptAddr_42C6 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class S  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_45F6  [$D9CE = 7]
    dw $D9CE                ;   address
    dw $0007                ;   value
    dw Bank0D_ScriptAddr_45F6 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class A  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_4590  [$D9CE = 6]
    dw $D9CE                ;   address
    dw $0006                ;   value
    dw Bank0D_ScriptAddr_4590 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class B  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_453A  [$D9CE = 5]
    dw $D9CE                ;   address
    dw $0005                ;   value
    dw Bank0D_ScriptAddr_453A ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class C  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_451E  [$D9CE = 4]
    dw $D9CE                ;   address
    dw $0004                ;   value
    dw Bank0D_ScriptAddr_451E ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class D  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_4432  [$D9CE = 3]
    dw $D9CE                ;   address
    dw $0003                ;   value
    dw Bank0D_ScriptAddr_4432 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class E  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_43D2  [$D9CE = 2]
    dw $D9CE                ;   address
    dw $0002                ;   value
    dw Bank0D_ScriptAddr_43D2 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class F  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_4392  [$D9CE = 1]
    dw $D9CE                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4392 ;   target
    dw $FF15                ; $15 check_and_branch: If “the arena class” is class G  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_42D6  [$D9CE = 0]
    dw $D9CE                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_42D6 ;   target
    dw $FFFF                ; END
Bank0D_ScriptAddr_42C6:
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $07D1                ; text $07D1: "*:Ho Ho, Well done! You defeated the Mas…"
    dw $FF03                ; $03 set_flag: Set flag $00FD
    dw $00FD                ;   flag
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
Bank0D_ScriptAddr_42D6:
    dw $FF12                ; $12 write_ram: The arena classes won: 1 (up to class G)  [$CAB4 := 1]
    dw $CAB4                ;   address
    dw $0001                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0030
    dw $0030                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 0  [$D92B := 0]
    dw $D92B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 4 → state 2  [$D92F := 2]
    dw $D92F                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 8 → state 1  [$D931 := 1]
    dw $D931                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 1 → state 3  [$D93C := 3]
    dw $D93C                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 2 → state 1  [$D941 := 1]
    dw $D941                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $00E4                ; text $00E4: "*:Well done! You survived G class!"
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 3 walks up 1 tile (script waits)
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 3 walks up 2 tiles (script waits)
    dw $0003                ;   actor
    dw $FFE0                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $00E5                ; text $00E5: "*:Oh, Sir [HERO]. Congratulations on you…"
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 3 tiles
    dw $0003                ;   actor
    dw $0030                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks down 3 tiles
    dw $0000                ;   actor
    dw $0030                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 1 hidden  [$C8ED := 3]
    dw $C8ED                ;   address
    dw $0003                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 1-2 hidden  [$C8ED := 7]
    dw $C8ED                ;   address
    dw $0007                ;   value
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0F                ; $0F map_transition: Go to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0D_ScriptAddr_4392:
    dw $FF12                ; $12 write_ram: The arena classes won: 2 (up to class F)  [$CAB4 := 2]
    dw $CAB4                ;   address
    dw $0002                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0031
    dw $0031                ;   flag
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 4 → state 3  [$D92F := 3]
    dw $D92F                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 8 → state 2  [$D931 := 2]
    dw $D931                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 12 → state 1  [$D933 := 1]
    dw $D933                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 1 → state 4  [$D93C := 4]
    dw $D93C                ;   address
    dw $0004                ;   value
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 1 → state 1  [$D952 := 1]
    dw $D952                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 4 → state 1  [$D953 := 1]
    dw $D953                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 5 → state 1  [$D954 := 1]
    dw $D954                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $017A                ; text $017A: "*:Well done! You survived F class! *:The…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_43D2:
    dw $FF12                ; $12 write_ram: The arena classes won: 3 (up to class E)  [$CAB4 := 3]
    dw $CAB4                ;   address
    dw $0003                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0032
    dw $0032                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 0 → state 1  [$D93B := 1]
    dw $D93B                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 4 → state 1  [$D942 := 1]
    dw $D942                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0031 is clear → Bank0D_ScriptAddr_43FA
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_43FA ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $01B6                ; text $01B6: "*:Well done! You survived E class! *:The…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_43FA:
    dw $FF03                ; $03 set_flag: Set flag $0031
    dw $0031                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0049
    dw $0049                ;   flag
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 4 → state 3  [$D92F := 3]
    dw $D92F                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 8 → state 2  [$D931 := 2]
    dw $D931                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 12 → state 1  [$D933 := 1]
    dw $D933                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 1 → state 4  [$D93C := 4]
    dw $D93C                ;   address
    dw $0004                ;   value
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 1 → state 1  [$D952 := 1]
    dw $D952                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 4 → state 1  [$D953 := 1]
    dw $D953                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 5 → state 1  [$D954 := 1]
    dw $D954                ;   address
    dw $0001                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $01B7                ; text $01B7: "*:Well done! You survived E class! *:The…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4432:
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_443C
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_443C ;   target
    dw $FF03                ; $03 set_flag: Set flag $0119
    dw $0119                ;   flag
Bank0D_ScriptAddr_443C:
    dw $FF12                ; $12 write_ram: The arena classes won: 4 (up to class D)  [$CAB4 := 4]
    dw $CAB4                ;   address
    dw $0004                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0031
    dw $0031                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0032
    dw $0032                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0033
    dw $0033                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 0  [$D92B := 0]
    dw $D92B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 4 → state 3  [$D92F := 3]
    dw $D92F                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 8 → state 2  [$D931 := 2]
    dw $D931                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 12 → state 1  [$D933 := 1]
    dw $D933                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 0 → state 2  [$D93B := 2]
    dw $D93B                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 1 → state 4  [$D93C := 4]
    dw $D93C                ;   address
    dw $0004                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 4 → state 1  [$D942 := 1]
    dw $D942                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 1 → state 1  [$D952 := 1]
    dw $D952                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 4 → state 1  [$D953 := 1]
    dw $D953                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 5 → state 1  [$D954 := 1]
    dw $D954                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $021C                ; text $021C: "*:Great work! You survived D class!!"
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 3 walks up 1 tile (script waits)
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 3 walks up 2 tiles (script waits)
    dw $0003                ;   actor
    dw $FFE0                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $021D                ; text $021D: "*:Oh! Monster Master [HERO]. Congratulat…"
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 3 tiles
    dw $0003                ;   actor
    dw $0030                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks down 3 tiles
    dw $0000                ;   actor
    dw $0030                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 1 hidden  [$C8ED := 3]
    dw $C8ED                ;   address
    dw $0003                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 1-2 hidden  [$C8ED := 7]
    dw $C8ED                ;   address
    dw $0007                ;   value
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0F                ; $0F map_transition: Go to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0D_ScriptAddr_451E:
    dw $FF12                ; $12 write_ram: The arena classes won: 5 (up to class C)  [$CAB4 := 5]
    dw $CAB4                ;   address
    dw $0005                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0034
    dw $0034                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 0 → state 3  [$D93B := 3]
    dw $D93B                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02E1                ; text $02E1: "*:Well done! You survived C class! *:The…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_453A:
    dw $FF12                ; $12 write_ram: The arena classes won: 6 (up to class B)  [$CAB4 := 6]
    dw $CAB4                ;   address
    dw $0006                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0035
    dw $0035                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 5 → state 1  [$D939 := 1]
    dw $D939                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 4 → state 1  [$D93D := 1]
    dw $D93D                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 0 → state 1  [$D945 := 1]
    dw $D945                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 1 → state 1  [$D946 := 1]
    dw $D946                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 2 → state 2  [$D947 := 2]
    dw $D947                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable: KingSlime Room screen 0 → state 1  [$D963 := 1]
    dw $D963                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable: Coffin Room screen 0 → state 1  [$D964 := 1]
    dw $D964                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0034 is clear → Bank0D_ScriptAddr_4580
    dw $0034                ;   flag
    dw Bank0D_ScriptAddr_4580 ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0341                ; text $0341: "*:Well done!! You survived B class! *:Th…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4580:
    dw $FF03                ; $03 set_flag: Set flag $0034
    dw $0034                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 0 → state 3  [$D93B := 3]
    dw $D93B                ;   address
    dw $0003                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0342                ; text $0342: "*:Well done!! You survived B class! *:Th…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4590:
    dw $FF12                ; $12 write_ram: The arena classes won: 7 (up to class A)  [$CAB4 := 7]
    dw $CAB4                ;   address
    dw $0007                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0036
    dw $0036                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 4 → state 2  [$D93D := 2]
    dw $D93D                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0035 is clear → Bank0D_ScriptAddr_45B2
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_45B2 ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $039F                ; text $039F: "*:Well done! You survived A class! *:The…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_45B2:
    dw $FF03                ; $03 set_flag: Set flag $0035
    dw $0035                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 5 → state 1  [$D939 := 1]
    dw $D939                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 0 → state 1  [$D945 := 1]
    dw $D945                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 1 → state 1  [$D946 := 1]
    dw $D946                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 2 → state 2  [$D947 := 2]
    dw $D947                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable: KingSlime Room screen 0 → state 1  [$D963 := 1]
    dw $D963                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable: Coffin Room screen 0 → state 1  [$D964 := 1]
    dw $D964                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0034 is clear → Bank0D_ScriptAddr_45E6
    dw $0034                ;   flag
    dw Bank0D_ScriptAddr_45E6 ;   target
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $03A1                ; text $03A1: "*:Well done! You survived A class. *:The…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_45E6:
    dw $FF03                ; $03 set_flag: Set flag $0034
    dw $0034                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 0 → state 3  [$D93B := 3]
    dw $D93B                ;   address
    dw $0003                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $03A0                ; text $03A0: "*:Well done! You survived A class. *:The…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_45F6:
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_4600
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_4600 ;   target
    dw $FF03                ; $03 set_flag: Set flag $011C
    dw $011C                ;   flag
Bank0D_ScriptAddr_4600:
    dw $FF12                ; $12 write_ram: The arena classes won: 8 (up to class S)  [$CAB4 := 8]
    dw $CAB4                ;   address
    dw $0008                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0034
    dw $0034                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0035
    dw $0035                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0036
    dw $0036                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0037
    dw $0037                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 0  [$D92B := 0]
    dw $D92B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 1 → state 2  [$D936 := 2]
    dw $D936                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 2 → state 2  [$D937 := 2]
    dw $D937                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 4 → state 2  [$D938 := 2]
    dw $D938                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 5 → state 2  [$D939 := 2]
    dw $D939                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 0 → state 3  [$D93B := 3]
    dw $D93B                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 4 → state 3  [$D93D := 3]
    dw $D93D                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 0 → state 1  [$D945 := 1]
    dw $D945                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 1 → state 1  [$D946 := 1]
    dw $D946                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 2 → state 2  [$D947 := 2]
    dw $D947                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable: KingSlime Room screen 0 → state 1  [$D963 := 1]
    dw $D963                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable: Coffin Room screen 0 → state 1  [$D964 := 1]
    dw $D964                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $03F1                ; text $03F1: "*:Well done! You survived S class! *:Now…"
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 3 walks up 1 tile (script waits)
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 3 walks up 2 tiles (script waits)
    dw $0003                ;   actor
    dw $FFE0                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $03F2                ; text $03F2: "*:Monster Master [HERO]! You became our …"
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 3 tiles
    dw $0003                ;   actor
    dw $0030                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks down 3 tiles
    dw $0000                ;   actor
    dw $0030                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 1 hidden  [$C8ED := 3]
    dw $C8ED                ;   address
    dw $0003                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 1-2 hidden  [$C8ED := 7]
    dw $C8ED                ;   address
    dw $0007                ;   value
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0F                ; $0F map_transition: Go to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0D_ScriptAddr_46F2:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF44                ; $44 back_from_return: After the return: face as saved, turn the saved actor to the player and say the saved text + 9
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: 0  [$D951 := 0]
    dw $D951                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script01
; ---------------------------------------------------------------------------
ArenaLobby_Script01:
    dw $FF15                ; $15 check_and_branch: If “hidden sprites” is everyone shown → Bank0D_ScriptAddr_470E  [$C8ED = 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_470E ;   target
    dw $FFFF                ; END

Bank0D_ScriptAddr_470E:
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: the player walks left 3 tiles (script waits)
    dw $0000                ;   actor
    dw $FFD0                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: the player walks down 2 tiles (script waits)
    dw $0000                ;   actor
    dw $0020                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 3 hidden  [$C8ED := 9]
    dw $C8ED                ;   address
    dw $0009                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 2-3 hidden  [$C8ED := 13]
    dw $C8ED                ;   address
    dw $000D                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4A                ; $4A face_right: NPC 3 faces right
    dw $0003                ;   actor
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: the monsters hidden (Terry shown)  [$C8ED := 14]
    dw $C8ED                ;   address
    dw $000E                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script02
; ---------------------------------------------------------------------------
ArenaLobby_Script02:
    dw $FF2D                ; $2D monster_slot_dialogue: The NPC says the family line of party monster 1
    dw $0000                ;   slot
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script03
; ---------------------------------------------------------------------------
ArenaLobby_Script03:
    dw $FF2D                ; $2D monster_slot_dialogue: The NPC says the family line of party monster 2
    dw $0001                ;   slot
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script04
; ---------------------------------------------------------------------------
ArenaLobby_Script04:
    dw $FF2D                ; $2D monster_slot_dialogue: The NPC says the family line of party monster 3
    dw $0002                ;   slot
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script05
; ---------------------------------------------------------------------------
ArenaLobby_Script05:
    dw $00EB                ; text $00EB: "You hear a voice."
    dw $00EC                ; text $00EC: "*:Only those registered are allowed here…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script06
; ---------------------------------------------------------------------------
ArenaLobby_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $0103 is set → Bank0D_ScriptAddr_4948
    dw $0103                ;   flag
    dw Bank0D_ScriptAddr_4948 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0D_ScriptAddr_4940
    dw $0111                ;   flag
    dw Bank0D_ScriptAddr_4940 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0110 is set → Bank0D_ScriptAddr_490E
    dw $0110                ;   flag
    dw Bank0D_ScriptAddr_490E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_48DC
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_48DC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_48A8
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_48A8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_48A4
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_48A4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $007D is set → Bank0D_ScriptAddr_4882
    dw $007D                ;   flag
    dw Bank0D_ScriptAddr_4882 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_489A
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_489A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_4896
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_4896 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $005A is set → Bank0D_ScriptAddr_4882
    dw $005A                ;   flag
    dw Bank0D_ScriptAddr_4882 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0D_ScriptAddr_488A
    dw $0030                ;   flag
    dw Bank0D_ScriptAddr_488A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0059 is set → Bank0D_ScriptAddr_4882
    dw $0059                ;   flag
    dw Bank0D_ScriptAddr_4882 ;   target
    dw $00E2                ; text $00E2: "*:Welcome to the arena. *:Huh? Me? I'm f…"
    dw $FF03                ; $03 set_flag: Set flag $0059
    dw $0059                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_47FE
    dw Bank0D_ScriptAddr_47FE ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_47FE:
    dw $FF04                ; $04 open_screen: Open the arena class menu (its texts begin “*:Welcome! Which class are you registeri…”)
    dw $0004                ;   kind
    dw $0710                ;   text
    dw $FF15                ; $15 check_and_branch: If “the arena match” is none  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_4878  [$D9CD = 255]
    dw $D9CD                ;   address
    dw $00FF                ;   value
    dw Bank0D_ScriptAddr_4878 ;   target
    dw $FF12                ; $12 write_ram: Room state of Arena Battle screen 0 → state 0  [$D999 := 0]
    dw $D999                ;   address
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
Bank0D_ScriptAddr_4824:
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 1 hidden  [$C8ED := 3]
    dw $C8ED                ;   address
    dw $0003                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 1-2 hidden  [$C8ED := 7]
    dw $C8ED                ;   address
    dw $0007                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FF1F                ; $1F arena_setup: Set the arena team from wArenaGroup / wColiseumBattle
    dw $FF0F                ; $0F map_transition: Go to Arena Battle at (7, 5)
    dw $005D                ;   map
    dw $0078                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_4878:
    dw $0713                ; text $0713: "*:Better luck next time."
    dw $FF12                ; $12 write_ram: The arena match: match 1  [$D9CD := 0]  (meaning inferred from the scripts that use it)
    dw $D9CD                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
Bank0D_ScriptAddr_4882:
    dw $0710                ; text $0710: "*:Welcome! Which class are you registeri…"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_47FE
    dw Bank0D_ScriptAddr_47FE ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_488A:
    dw $0178                ; text $0178: "*:Oh [HERO],I was waiting for you. *:You…"
    dw $FF03                ; $03 set_flag: Set flag $005A
    dw $005A                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_47FE
    dw Bank0D_ScriptAddr_47FE ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_4896:
    dw $027C                ; text $027C: "*:Go to the Room of Strength & Anger in …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_489A:
    dw $02E0                ; text $02E0: "*:Oh, [HERO]! I was waiting for you! *:T…"
    dw $FF03                ; $03 set_flag: Set flag $007D
    dw $007D                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_47FE
    dw Bank0D_ScriptAddr_47FE ;   target
Bank0D_ScriptAddr_48A4:
    dw $044D                ; text $044D: "*:The arena is currently being prepared.…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_48A8:
    dw $04AF                ; text $04AF: "*:You made it! Good job! *:Fight to your…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_48D8  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_48D8 ;   target
    dw $04B1                ; text $04B1: "*:Announcing the rep of GreatTree, [HERO…"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: The arena class: the Starry Night tournament  [$D9CE := 8]  (meaning inferred from the scripts that use it)
    dw $D9CE                ;   address
    dw $0008                ;   value
    dw $FF12                ; $12 write_ram: Room state of Arena Battle screen 0 → state 1  [$D999 := 1]
    dw $D999                ;   address
    dw $0001                ;   value
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4824
    dw Bank0D_ScriptAddr_4824 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_48D8:
    dw $04B0                ; text $04B0: "*:Let me know when you're ready."
    dw $FFFF                ; END
Bank0D_ScriptAddr_48DC:
    dw $07C7                ; text $07C7: "*:[HERO]! Oh it's [HERO]! Welcome! *:As …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_490A  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_490A ;   target
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: The arena class: the King's match  [$D9CE := 9]  (meaning inferred from the scripts that use it)
    dw $D9CE                ;   address
    dw $0009                ;   value
    dw $FF12                ; $12 write_ram: Room state of Arena Battle screen 0 → state 4  [$D999 := 4]
    dw $D999                ;   address
    dw $0004                ;   value
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4824
    dw Bank0D_ScriptAddr_4824 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_490A:
    dw $07C8                ; text $07C8: "*:Are you scared?"
    dw $FFFF                ; END
Bank0D_ScriptAddr_490E:
    dw $07CC                ; text $07CC: "*:Are you ready to challenge the Master …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_493C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_493C ;   target
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: The arena class: the King's match  [$D9CE := 9]  (meaning inferred from the scripts that use it)
    dw $D9CE                ;   address
    dw $0009                ;   value
    dw $FF12                ; $12 write_ram: Room state of Arena Battle screen 0 → state 4  [$D999 := 4]
    dw $D999                ;   address
    dw $0004                ;   value
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4824
    dw Bank0D_ScriptAddr_4824 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_493C:
    dw $07CD                ; text $07CD: "*:If you survive him, there will be noth…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4940:
    dw $07D1                ; text $07D1: "*:Ho Ho, Well done! You defeated the Mas…"
    dw $FF03                ; $03 set_flag: Set flag $00FD
    dw $00FD                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_4948:
    dw $07D2                ; text $07D2: "*:[HERO], to tell you the truth.... *:Th…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_4978  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4978 ;   target
    dw $08D4                ; text $08D4: "*:You said good!! Good luck!"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks up 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: The arena class: the King's match  [$D9CE := 9]  (meaning inferred from the scripts that use it)
    dw $D9CE                ;   address
    dw $0009                ;   value
    dw $FF12                ; $12 write_ram: Room state of Arena Battle screen 0 → state 4  [$D999 := 4]
    dw $D999                ;   address
    dw $0004                ;   value
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4824
    dw Bank0D_ScriptAddr_4824 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_4978:
    dw $08D5                ; text $08D5: "*:Gran was looking forward to fighting y…"
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; ArenaLobby_Script07
; ---------------------------------------------------------------------------
ArenaLobby_Script07:
    dw $FF01                ; $01 if_flag_set: If flag $00FE is set → Bank0D_ScriptAddr_4ACA
    dw $00FE                ;   flag
    dw Bank0D_ScriptAddr_4ACA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0D_ScriptAddr_4AC0
    dw $0111                ;   flag
    dw Bank0D_ScriptAddr_4AC0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0110 is set → Bank0D_ScriptAddr_4AAC
    dw $0110                ;   flag
    dw Bank0D_ScriptAddr_4AAC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_4A98
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_4A98 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00B0 is set → Bank0D_ScriptAddr_4A84
    dw $00B0                ;   flag
    dw Bank0D_ScriptAddr_4A84 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_4A7C
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_4A7C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00A4 is set → Bank0D_ScriptAddr_4A78
    dw $00A4                ;   flag
    dw Bank0D_ScriptAddr_4A78 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_4A70
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_4A70 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_4A5E
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_4A5E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_4A4C
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_4A4C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0D_ScriptAddr_4A3A
    dw $0034                ;   flag
    dw Bank0D_ScriptAddr_4A3A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_4A28
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_4A28 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_4A24
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_4A24 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_4A12
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_4A12 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_4A00
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_4A00 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0D_ScriptAddr_49EE
    dw $0030                ;   flag
    dw Bank0D_ScriptAddr_49EE ;   target
    dw $00E6                ; text $00E6: "*:Welcome to the arena! Want to hear abo…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_49EA  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_49EA ;   target
    dw $00E7                ; text $00E7: "*:The battle classes go from S,A down to…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_49EA:
    dw $00E8                ; text $00E8: "*:The last battle in G class is with the…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_49EE:
    dw $00E6                ; text $00E6: "*:Welcome to the arena! Want to hear abo…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_49FC  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_49FC ;   target
    dw $00E7                ; text $00E7: "*:The battle classes go from S,A down to…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_49FC:
    dw $017B                ; text $017B: "*:The last match in F class will be agai…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4A00:
    dw $00E6                ; text $00E6: "*:Welcome to the arena! Want to hear abo…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_4A0E  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4A0E ;   target
    dw $00E7                ; text $00E7: "*:The battle classes go from S,A down to…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4A0E:
    dw $01B8                ; text $01B8: "*:The last match of the E class is with.…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4A12:
    dw $00E6                ; text $00E6: "*:Welcome to the arena! Want to hear abo…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_4A20  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4A20 ;   target
    dw $00E7                ; text $00E7: "*:The battle classes go from S,A down to…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4A20:
    dw $021E                ; text $021E: "*:Sir Mick in the Queen's room *:will be…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4A24:
    dw $027D                ; text $027D: "*:Until you settle the disaster behind t…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4A28:
    dw $00E6                ; text $00E6: "*:Welcome to the arena! Want to hear abo…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_4A36  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4A36 ;   target
    dw $02E2                ; text $02E2: "*:The classes are S to G, starting from …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4A36:
    dw $02E3                ; text $02E3: "*:The last match will be against the mas…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4A3A:
    dw $00E6                ; text $00E6: "*:Welcome to the arena! Want to hear abo…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_4A48  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4A48 ;   target
    dw $02E2                ; text $02E2: "*:The classes are S to G, starting from …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4A48:
    dw $0343                ; text $0343: "*:The last match will be against the tir…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4A4C:
    dw $00E6                ; text $00E6: "*:Welcome to the arena! Want to hear abo…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_4A5A  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4A5A ;   target
    dw $02E2                ; text $02E2: "*:The classes are S to G, starting from …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4A5A:
    dw $03A2                ; text $03A2: "*:The last match of A class is going to …"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4A5E:
    dw $00E6                ; text $00E6: "*:Welcome to the arena! Want to hear abo…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_4A6C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4A6C ;   target
    dw $02E2                ; text $02E2: "*:The classes are S to G, starting from …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4A6C:
    dw $03F3                ; text $03F3: "*:The last match in S class will be with…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4A70:
    dw $044E                ; text $044E: "*:I heard his Majesty commanded you to g…"
    dw $FF03                ; $03 set_flag: Set flag $00A4
    dw $00A4                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_4A78:
    dw $044F                ; text $044F: "*:They say you see the future behind the…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4A7C:
    dw $04B2                ; text $04B2: "*:The Starry Night Tournament is fought …"
    dw $FF03                ; $03 set_flag: Set flag $00B0
    dw $00B0                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_4A84:
    dw $04B3                ; text $04B3: "*:Want to listen to the description of t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_4A92  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4A92 ;   target
    dw $01AD                ; text $01AD: "*:Starry Night Tournament is a match amo…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4A92:
    dw $04B4                ; text $04B4: "*:Everybody in the kingdom is behind you…"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4ACC
    dw Bank0D_ScriptAddr_4ACC ;   target
Bank0D_ScriptAddr_4A98:
    dw $07C9                ; text $07C9: "*:Want to listen to the description of t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_4AA6  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4AA6 ;   target
    dw $07CA                ; text $07CA: "*:Giggle... It'll be there after the fig…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4AA6:
    dw $07CB                ; text $07CB: "*:Oh [HERO]!, Good luck! *kiss*"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4ACC
    dw Bank0D_ScriptAddr_4ACC ;   target
Bank0D_ScriptAddr_4AAC:
    dw $07C9                ; text $07C9: "*:Want to listen to the description of t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_4ABA  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4ABA ;   target
    dw $07CF                ; text $07CF: "*:The Master Monster Tamer will bring ve…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4ABA:
    dw $07CB                ; text $07CB: "*:Oh [HERO]!, Good luck! *kiss*"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4ACC
    dw Bank0D_ScriptAddr_4ACC ;   target
Bank0D_ScriptAddr_4AC0:
    dw $07D3                ; text $07D3: "*:Oh [HERO]! You really won! *:Awesome! …"
    dw $FF03                ; $03 set_flag: Set flag $00FE
    dw $00FE                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4ACC
    dw Bank0D_ScriptAddr_4ACC ;   target
Bank0D_ScriptAddr_4ACA:
    dw $07D4                ; text $07D4: "*:Oh [HERO]! Here is your surprise. *kis…"
Bank0D_ScriptAddr_4ACC:
    dw $FF0D                ; $0D npc_write: NPC 4: restart its animation from the first frame  [slot +$10 := 0]
    dw $0004                ;   actor
    dw $0010                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4: y low byte := 96
    dw $0004                ;   actor
    dw $001A                ;   field
    dw $0060                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 4 is hidden
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script08
; ---------------------------------------------------------------------------
ArenaLobby_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0D_ScriptAddr_4AFC
    dw $0111                ;   flag
    dw Bank0D_ScriptAddr_4AFC ;   target
    dw $00E9                ; text $00E9: "*:Eeek! What? Talk to me from the front!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4AFC:
    dw $07D5                ; text $07D5: "*:What? Where are you? *:Well whatever..…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script09
; ---------------------------------------------------------------------------
ArenaLobby_Script09:
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0D_ScriptAddr_4B0A
    dw $0111                ;   flag
    dw Bank0D_ScriptAddr_4B0A ;   target
    dw $00EA                ; text $00EA: "*:Get out of my way! Huff!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4B0A:
    dw $07D6                ; text $07D6: "*:Oh no! You tripped over didn't you!? *…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaLobby_Script10
; ---------------------------------------------------------------------------
ArenaLobby_Script10:
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
; ---------------------------------------------------------------------------
; ArenaLobby_Script11
; ---------------------------------------------------------------------------
ArenaLobby_Script11:
    dw $FF01                ; $01 if_flag_set: If flag $00FF is set → Bank0D_ScriptAddr_4CF8
    dw $00FF                ;   flag
    dw Bank0D_ScriptAddr_4CF8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_4CF0
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_4CF0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_4CEC
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_4CEC ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0037 is clear → Bank0D_ScriptAddr_4B30
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_4B30 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0096 is set → Bank0D_ScriptAddr_4CE8
    dw $0096                ;   flag
    dw Bank0D_ScriptAddr_4CE8 ;   target
Bank0D_ScriptAddr_4B30:
    dw $FF01                ; $01 if_flag_set: If flag $0096 is set → Bank0D_ScriptAddr_4CE4
    dw $0096                ;   flag
    dw Bank0D_ScriptAddr_4CE4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0095 is set → Bank0D_ScriptAddr_4CC6
    dw $0095                ;   flag
    dw Bank0D_ScriptAddr_4CC6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_4CA4
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_4CA4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_4C82
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_4C82 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_4C7E
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_4C7E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $008B is set → Bank0D_ScriptAddr_4C7A
    dw $008B                ;   flag
    dw Bank0D_ScriptAddr_4C7A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $008A is set → Bank0D_ScriptAddr_4C5C
    dw $008A                ;   flag
    dw Bank0D_ScriptAddr_4C5C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0D_ScriptAddr_4C3A
    dw $0034                ;   flag
    dw Bank0D_ScriptAddr_4C3A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0089 is set → Bank0D_ScriptAddr_4C36
    dw $0089                ;   flag
    dw Bank0D_ScriptAddr_4C36 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $007E is set → Bank0D_ScriptAddr_4C32
    dw $007E                ;   flag
    dw Bank0D_ScriptAddr_4C32 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_4C2A
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_4C2A ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0058 is clear → Bank0D_ScriptAddr_4B7E
    dw $0058                ;   flag
    dw Bank0D_ScriptAddr_4B7E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0119 is set → Bank0D_ScriptAddr_4D1E
    dw $0119                ;   flag
    dw Bank0D_ScriptAddr_4D1E ;   target
Bank0D_ScriptAddr_4B7E:
    dw $FF00                ; $00 if_flag_clear: If flag $0033 is clear → Bank0D_ScriptAddr_4B8A
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_4B8A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0058 is set → Bank0D_ScriptAddr_4C26
    dw $0058                ;   flag
    dw Bank0D_ScriptAddr_4C26 ;   target
Bank0D_ScriptAddr_4B8A:
    dw $FF01                ; $01 if_flag_set: If flag $0058 is set → Bank0D_ScriptAddr_4C22
    dw $0058                ;   flag
    dw Bank0D_ScriptAddr_4C22 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $004F is set → Bank0D_ScriptAddr_4C04
    dw $004F                ;   flag
    dw Bank0D_ScriptAddr_4C04 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0033 is clear → Bank0D_ScriptAddr_4BA2
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_4BA2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0119 is set → Bank0D_ScriptAddr_4CFC
    dw $0119                ;   flag
    dw Bank0D_ScriptAddr_4CFC ;   target
Bank0D_ScriptAddr_4BA2:
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_4BE2
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_4BE2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0048 is set → Bank0D_ScriptAddr_4BDE
    dw $0048                ;   flag
    dw Bank0D_ScriptAddr_4BDE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_4BDA
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_4BDA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0D_ScriptAddr_4BD6
    dw $0030                ;   flag
    dw Bank0D_ScriptAddr_4BD6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0121 is set → Bank0D_ScriptAddr_4BC4
    dw $0121                ;   flag
    dw Bank0D_ScriptAddr_4BC4 ;   target
    dw $00ED                ; text $00ED: "*:H...Hello! I'm T..T..Teto. *:I'm nervo…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4BC4:
    dw $044B                ; text $044B: "*:H..H..Hello! M..my name is T..T..Teto.…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_4BD2  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4BD2 ;   target
    dw $086B                ; text $086B: "*:To win, train your monsters behind the…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4BD2:
    dw $086A                ; text $086A: "*:W, Well, it's no use asking me. *:Ask …"
    dw $FFFF                ; END
Bank0D_ScriptAddr_4BD6:
    dw $017C                ; text $017C: "*:M...my name is Teto. I survived G clas…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4BDA:
    dw $01B9                ; text $01B9: "*:Ha ha ha... It's E class. I survived E…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4BDE:
    dw $017D                ; text $017D: "*:E class.I am in E class. *:Ha ha ha. D…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4BE2:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $021F                ; text $021F: "*:Oh I'm sorry! I was rude...! *:Give me…"
    dw $FF03                ; $03 set_flag: Set flag $004F
    dw $004F                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0058
    dw $0058                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 1 offers its monster for breeding (enemy row 308); remember this room and Terry's spot for the ceremony's way back
    dw $0134                ;   enemy
    dw $0001                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Come to me when you want to breed with…”)
    dw $0005                ;   kind
    dw $0600                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0058
    dw $0058                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0600                ; text $0600: "*:Come to me when you want to breed with…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4C04:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $022A                ; text $022A: "*:Why don't you breed with my IceMan? *:…"
    dw $FF03                ; $03 set_flag: Set flag $0058
    dw $0058                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 1 offers its monster for breeding (enemy row 308); remember this room and Terry's spot for the ceremony's way back
    dw $0134                ;   enemy
    dw $0001                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Come to me when you want to breed with…”)
    dw $0005                ;   kind
    dw $0600                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0058
    dw $0058                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0600                ; text $0600: "*:Come to me when you want to breed with…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4C22:
    dw $022B                ; text $022B: "*:I'll try not to boast so much anymore!…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4C26:
    dw $027E                ; text $027E: "*:I guess staying on the farm means no s…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4C2A:
    dw $02E4                ; text $02E4: "*:Oh [HERO]! Please listen! *:I've advan…"
    dw $FF03                ; $03 set_flag: Set flag $007E
    dw $007E                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_4C32:
    dw $02E5                ; text $02E5: "*:The last fight in C class is going to …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4C36:
    dw $02E6                ; text $02E6: "*:[HERO]! We'll have to fight again!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4C3A:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0344                ; text $0344: "*:[HERO]! You're tough! *:Way to go. Say…"
    dw $FF03                ; $03 set_flag: Set flag $008A
    dw $008A                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $008B
    dw $008B                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 1 offers its monster for breeding (enemy row 310); remember this room and Terry's spot for the ceremony's way back
    dw $0136                ;   enemy
    dw $0001                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Come to me when you want to breed with…”)
    dw $0005                ;   kind
    dw $0600                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $008B
    dw $008B                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0600                ; text $0600: "*:Come to me when you want to breed with…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4C5C:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0854                ; text $0854: "*:Would you like to breed with my Eyeder…"
    dw $FF03                ; $03 set_flag: Set flag $008B
    dw $008B                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 1 offers its monster for breeding (enemy row 310); remember this room and Terry's spot for the ceremony's way back
    dw $0136                ;   enemy
    dw $0001                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Come to me when you want to breed with…”)
    dw $0005                ;   kind
    dw $0600                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $008B
    dw $008B                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0600                ; text $0600: "*:Come to me when you want to breed with…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4C7A:
    dw $034F                ; text $034F: "*:When two of the same kind of monsters …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4C7E:
    dw $03A3                ; text $03A3: "*:Breeding the same monsters creates the…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4C82:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $03F4                ; text $03F4: "*[HERO], nothing left but S class. *:I'l…"
    dw $FF03                ; $03 set_flag: Set flag $0095
    dw $0095                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0096
    dw $0096                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 1 offers its monster for breeding (enemy row 313); remember this room and Terry's spot for the ceremony's way back
    dw $0139                ;   enemy
    dw $0001                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Come to me when you want to breed with…”)
    dw $0005                ;   kind
    dw $0600                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0096
    dw $0096                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0600                ; text $0600: "*:Come to me when you want to breed with…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4CA4:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0450                ; text $0450: "*:Hi [HERO], Congratulations. *:I'll hel…"
    dw $FF03                ; $03 set_flag: Set flag $0095
    dw $0095                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0096
    dw $0096                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 1 offers its monster for breeding (enemy row 313); remember this room and Terry's spot for the ceremony's way back
    dw $0139                ;   enemy
    dw $0001                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Come to me when you want to breed with…”)
    dw $0005                ;   kind
    dw $0600                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0096
    dw $0096                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0600                ; text $0600: "*:Come to me when you want to breed with…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4CC6:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0855                ; text $0855: "*:Would you like to breed with my Yeti?"
    dw $FF03                ; $03 set_flag: Set flag $0096
    dw $0096                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 1 offers its monster for breeding (enemy row 313); remember this room and Terry's spot for the ceremony's way back
    dw $0139                ;   enemy
    dw $0001                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Come to me when you want to breed with…”)
    dw $0005                ;   kind
    dw $0600                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0096
    dw $0096                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0600                ; text $0600: "*:Come to me when you want to breed with…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4CE4:
    dw $03F7                ; text $03F7: "*:When a monster learns two certain skil…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4CE8:
    dw $0451                ; text $0451: "*:Starry Night Tournament... What a grea…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4CEC:
    dw $04B5                ; text $04B5: "*:You made it! *:I can't even come close…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4CF0:
    dw $07D7                ; text $07D7: "*:[HERO]! Congratulations on your victor…"
    dw $FF03                ; $03 set_flag: Set flag $00FF
    dw $00FF                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_4CF8:
    dw $07D8                ; text $07D8: "*:I..I heard that monsters exist in this…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4CFC:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $07D0                ; text $07D0: "*:You survived D class! *:I'm still in E…"
    dw $FF03                ; $03 set_flag: Set flag $004F
    dw $004F                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0058
    dw $0058                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 1 offers its monster for breeding (enemy row 308); remember this room and Terry's spot for the ceremony's way back
    dw $0134                ;   enemy
    dw $0001                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Come to me when you want to breed with…”)
    dw $0005                ;   kind
    dw $0600                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0058
    dw $0058                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0600                ; text $0600: "*:Come to me when you want to breed with…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4D1E:
    dw $0858                ; text $0858: "*:When they're left on the farm, they do…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms Per-Script Table (map_type=$07, 27 scripts)
; ---------------------------------------------------------------------------
ArenaRooms_ScriptPtrTable:
    dw ArenaRooms_Script00  ; script 0
    dw ArenaRooms_Script01  ; script 1
    dw ArenaRooms_Script02  ; script 2
    dw ArenaRooms_Script03  ; script 3
    dw ArenaRooms_Script04  ; script 4
    dw ArenaRooms_Script05  ; script 5
    dw ArenaRooms_Script06  ; script 6
    dw ArenaRooms_Script07  ; script 7
    dw ArenaRooms_Script08  ; script 8
    dw ArenaRooms_Script09  ; script 9
    dw ArenaRooms_Script10  ; script 10
    dw ArenaRooms_Script11  ; script 11
    dw ArenaRooms_Script12  ; script 12
    dw ArenaRooms_Script13  ; script 13
    dw ArenaRooms_Script14  ; script 14
    dw ArenaRooms_Script15  ; script 15
    dw ArenaRooms_Script16  ; script 16
    dw ArenaRooms_Script17  ; script 17
    dw ArenaRooms_Script18  ; script 18
    dw ArenaRooms_Script19  ; script 19
    dw ArenaRooms_Script20  ; script 20
    dw ArenaRooms_Script21  ; script 21
    dw ArenaRooms_Script22  ; script 22
    dw ArenaRooms_Script23  ; script 23
    dw ArenaRooms_Script24  ; script 24
    dw ArenaRooms_Script25  ; script 25
    dw ArenaRooms_Script26  ; script 26
; ---------------------------------------------------------------------------
; ArenaRooms_Script00
; ---------------------------------------------------------------------------
ArenaRooms_Script00:
    dw $FF15                ; $15 check_and_branch: If “the party is falling through a hole” is yes  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_4D70  [$D9E5 = 1]
    dw $D9E5                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4D70 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 0 → Bank0D_ScriptAddr_4D68
    dw $0000                ;   screen
    dw Bank0D_ScriptAddr_4D68 ;   target
    dw $FFFF                ; END

Bank0D_ScriptAddr_4D68:
    dw $FF12                ; $12 write_ram: The room effect phase: not shown yet  [$D9CB := 0]
    dw $D9CB                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_4D70:
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 1 tile
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 1 tile
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 6 is shown
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 1 tile
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 6 walks down 1 tile
    dw $0006                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 7 is shown
    dw $0007                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 2 tiles
    dw $0004                ;   actor
    dw $0020                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 3 tiles
    dw $0005                ;   actor
    dw $0030                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 6 walks down 4 tiles
    dw $0006                ;   actor
    dw $0040                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 7 walks down 5 tiles
    dw $0007                ;   actor
    dw $0050                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
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
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The party is falling through a hole: no  [$D9E5 := 0]  (meaning inferred from the scripts that use it)
    dw $D9E5                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script01
; ---------------------------------------------------------------------------
ArenaRooms_Script01:
    dw $FF15                ; $15 check_and_branch: If “the room effect phase” is shown / step 1 → Bank0D_ScriptAddr_4EAE  [$D9CB = 1]
    dw $D9CB                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4EAE ;   target
    dw $FF21                ; $21 sound: Sound effect $6C
    dw $006C                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $4EEC)
    dw Bank0D_ScriptAddr_4EEC ;   data
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $4EFA)
    dw Bank0D_ScriptAddr_4EFA ;   data
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_4EE6
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_4EE6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_4EE0
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_4EE0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_4EDA
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_4EDA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_4ED4
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_4ED4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_4ECE
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_4ECE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0D_ScriptAddr_4EC8
    dw $0034                ;   flag
    dw Bank0D_ScriptAddr_4EC8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_4EC2
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_4EC2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_4EBC
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_4EBC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_4EB6
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_4EB6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0D_ScriptAddr_4EB0
    dw $0030                ;   flag
    dw Bank0D_ScriptAddr_4EB0 ;   target
    dw $00F0                ; text $00F0: "*:Where did the MiniDrak go?"
Bank0D_ScriptAddr_4E8C:
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 4 tiles
    dw $0003                ;   actor
    dw $0040                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 4 tiles
    dw $0003                ;   actor
    dw $0040                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: The room effect phase: shown / step 1  [$D9CB := 1]
    dw $D9CB                ;   address
    dw $0001                ;   value
Bank0D_ScriptAddr_4EAE:
    dw $FFFF                ; END

Bank0D_ScriptAddr_4EB0:
    dw $017F                ; text $017F: "*:An eye ball in an EyeBall! Funny?"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4E8C
    dw Bank0D_ScriptAddr_4E8C ;   target
Bank0D_ScriptAddr_4EB6:
    dw $01BB                ; text $01BB: "*:BigRoost is roasting big time!"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4E8C
    dw Bank0D_ScriptAddr_4E8C ;   target
Bank0D_ScriptAddr_4EBC:
    dw $022D                ; text $022D: "*:Eyeder wider! Ha! Ha!"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4E8C
    dw Bank0D_ScriptAddr_4E8C ;   target
Bank0D_ScriptAddr_4EC2:
    dw $0280                ; text $0280: "*:MadGopher go mad go far! Funny?"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4E8C
    dw Bank0D_ScriptAddr_4E8C ;   target
Bank0D_ScriptAddr_4EC8:
    dw $0351                ; text $0351: "*:Is this an Orc or Pork? Funny?"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4E8C
    dw Bank0D_ScriptAddr_4E8C ;   target
Bank0D_ScriptAddr_4ECE:
    dw $03A5                ; text $03A5: "*:MadRaven Heaven."
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4E8C
    dw Bank0D_ScriptAddr_4E8C ;   target
Bank0D_ScriptAddr_4ED4:
    dw $03F9                ; text $03F9: "*:Yeti doesn't say yet. Funny?"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4E8C
    dw Bank0D_ScriptAddr_4E8C ;   target
Bank0D_ScriptAddr_4EDA:
    dw $0453                ; text $0453: "*:Gigantes goes on gigantic protests."
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4E8C
    dw Bank0D_ScriptAddr_4E8C ;   target
Bank0D_ScriptAddr_4EE0:
    dw $04B7                ; text $04B7: "*:Wyvern!"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4E8C
    dw Bank0D_ScriptAddr_4E8C ;   target
Bank0D_ScriptAddr_4EE6:
    dw $07DA                ; text $07DA: "*:That's it everyone."
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4E8C
    dw Bank0D_ScriptAddr_4E8C ;   target
Bank0D_ScriptAddr_4EEC:
    db $C6, $00, $70, $71, $D8, $72, $73, $D8, $70, $71, $D8, $72, $73, $D9  ; tile patch (op $24): BG offset $00C6 (row 6, column 6), tiles 70 71 / 72 73 / 70 71 / 72 73; $D8 = next row, $D9 = end
Bank0D_ScriptAddr_4EFA:
    db $C6, $00, $02, $02, $D8, $02, $02, $D8, $02, $02, $D8, $02, $02, $D9  ; tile patch (op $61): BG offset $00C6 (row 6, column 6), colours 02 02 / 02 02 / 02 02 / 02 02; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; ArenaRooms_Script02
; ---------------------------------------------------------------------------
ArenaRooms_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_4F26
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_4F26 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_4F22
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_4F22 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_4F1E
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_4F1E ;   target
    dw $00EE                ; text $00EE: "*:Gwrr, Gwrr..."
    dw $FFFF                ; END

Bank0D_ScriptAddr_4F1E:
    dw $022C                ; text $022C: "*:Monsters can learn three special skill…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_4F22:
    dw $03A4                ; text $03A4: "*:Hhhg hhhg. Vivify, Vivify."
    dw $FFFF                ; END

Bank0D_ScriptAddr_4F26:
    dw $01BA                ; text $01BA: "*:The bishop over there taught me a song…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script03
; ---------------------------------------------------------------------------
ArenaRooms_Script03:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is playing → Bank0D_ScriptAddr_5022  [$D9DF = 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_5022 ;   target
    dw $FF2E                ; $2E pick_from_table: Goopy game: draw the next pick (row 0)
    dw $0000                ;   row
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_4F52  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_4F52 ;   target
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_4F52  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4F52 ;   target
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
Bank0D_ScriptAddr_4F52:
    dw $FF0D                ; $0D npc_write: NPC 1: walk animation on  [slot +$05 := $01]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_4F8A  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_4F8A ;   target
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 2 → Bank0D_ScriptAddr_4F94  [$D9E0 = 2]
    dw $D9E0                ;   address
    dw $0002                ;   value
    dw Bank0D_ScriptAddr_4F94 ;   target
Bank0D_ScriptAddr_4F7A:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is won → Bank0D_ScriptAddr_4F9E  [$D9DF = 5]
    dw $D9DF                ;   address
    dw $0005                ;   value
    dw Bank0D_ScriptAddr_4F9E ;   target
    dw $00F4                ; text $00F4: "*:Darn! Again!"
    dw $FF2F                ; $2F inc_ram: Add 1 to the Goopy game round  [$D9DF + 1]
    dw $D9DF                ;   address
    dw $FFFF                ; END

Bank0D_ScriptAddr_4F8A:
    dw $00F6                ; text $00F6: "*:It's a tie... In this case... *:I win …"
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_4F94:
    dw $00F5                ; text $00F5: "*:I won! Challenge me anytime!"
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_4F9E:
    dw $00F7                ; text $00F7: "*:You! You're good! *:Look! I'll tell yo…"
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $502C)
    dw Bank0D_TilePatch_502C ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5024)
    dw Bank0D_TilePatch_5024 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $503C)
    dw Bank0D_TilePatch_503C ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5034)
    dw Bank0D_TilePatch_5034 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $502C)
    dw Bank0D_TilePatch_502C ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5024)
    dw Bank0D_TilePatch_5024 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $503C)
    dw Bank0D_TilePatch_503C ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5034)
    dw Bank0D_TilePatch_5034 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $502C)
    dw Bank0D_TilePatch_502C ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5024)
    dw Bank0D_TilePatch_5024 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $503C)
    dw Bank0D_TilePatch_503C ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5034)
    dw Bank0D_TilePatch_5034 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $502C)
    dw Bank0D_TilePatch_502C ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5024)
    dw Bank0D_TilePatch_5024 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $503C)
    dw Bank0D_TilePatch_503C ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5034)
    dw Bank0D_TilePatch_5034 ;   data
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF61                ; $61 draw_attrs: Change the colours of part of the screen (tile patch $502C)
    dw Bank0D_TilePatch_502C ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5024)
    dw Bank0D_TilePatch_5024 ;   data
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF03                ; $03 set_flag: Set flag $000E
    dw $000E                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Arena Rooms screen 1 → state 1  [$D94C := 1]
    dw $D94C                ;   address
    dw $0001                ;   value
Bank0D_ScriptAddr_5022:
    dw $FFFF                ; END

Bank0D_TilePatch_5024:
    db $8A, $00, $74, $75, $D8, $76, $77, $D9  ; tile patch (op $24): BG offset $008A (row 4, column 10), tiles 74 75 / 76 77; $D8 = next row, $D9 = end
Bank0D_TilePatch_502C:
    db $8A, $00, $01, $01, $D8, $01, $01, $D9  ; tile patch (op $61): BG offset $008A (row 4, column 10), colours 01 01 / 01 01; $D8 = next row, $D9 = end
Bank0D_TilePatch_5034:
    db $8A, $00, $66, $67, $D8, $72, $73, $D9  ; tile patch (op $24): BG offset $008A (row 4, column 10), tiles 66 67 / 72 73; $D8 = next row, $D9 = end
Bank0D_TilePatch_503C:
    db $8A, $00, $02, $02, $D8, $02, $02, $D9  ; tile patch (op $61): BG offset $008A (row 4, column 10), colours 02 02 / 02 02; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; ArenaRooms_Script04
; ---------------------------------------------------------------------------
ArenaRooms_Script04:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is playing → Bank0D_ScriptAddr_5022  [$D9DF = 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_5022 ;   target
    dw $FF2E                ; $2E pick_from_table: Goopy game: draw the next pick (row 1)
    dw $0001                ;   row
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_506C  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_506C ;   target
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_506C  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_506C ;   target
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
Bank0D_ScriptAddr_506C:
    dw $FF0D                ; $0D npc_write: NPC 1: walk animation on  [slot +$05 := $01]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_4F8A  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4F8A ;   target
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_4F94  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_4F94 ;   target
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4F7A
    dw Bank0D_ScriptAddr_4F7A ;   target
; ---------------------------------------------------------------------------
; ArenaRooms_Script05
; ---------------------------------------------------------------------------
ArenaRooms_Script05:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is playing → Bank0D_ScriptAddr_5022  [$D9DF = 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_5022 ;   target
    dw $FF2E                ; $2E pick_from_table: Goopy game: draw the next pick (row 2)
    dw $0002                ;   row
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_50C0  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_50C0 ;   target
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_50C0  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_50C0 ;   target
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
Bank0D_ScriptAddr_50C0:
    dw $FF0D                ; $0D npc_write: NPC 1: walk animation on  [slot +$05 := $01]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 2 → Bank0D_ScriptAddr_4F8A  [$D9E0 = 2]
    dw $D9E0                ;   address
    dw $0002                ;   value
    dw Bank0D_ScriptAddr_4F8A ;   target
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_4F94  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_4F94 ;   target
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_4F7A
    dw Bank0D_ScriptAddr_4F7A ;   target
; ---------------------------------------------------------------------------
; ArenaRooms_Script06
; ---------------------------------------------------------------------------
ArenaRooms_Script06:
    dw $FF00                ; $00 if_flag_clear: If flag $000E is clear → Bank0D_ScriptAddr_50F8
    dw $000E                ;   flag
    dw Bank0D_ScriptAddr_50F8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_5120
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_5120 ;   target
Bank0D_ScriptAddr_50F8:
    dw $FF01                ; $01 if_flag_set: If flag $000E is set → Bank0D_ScriptAddr_511C
    dw $000E                ;   flag
    dw Bank0D_ScriptAddr_511C ;   target
    dw $00F1                ; text $00F1: "*:Let's play rock- paper-scissors! [YES/…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5112  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5112 ;   target
    dw $00F3                ; text $00F3: "*:Select your choice by stepping on the …"
    dw $FF12                ; $12 write_ram: The Goopy game round: 1  [$D9DF := 1]
    dw $D9DF                ;   address
    dw $0001                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_5112:
    dw $00F2                ; text $00F2: "*:Hm, its not fun."
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_511C:
    dw $00F8                ; text $00F8: "*:You're good..."
    dw $FFFF                ; END

Bank0D_ScriptAddr_5120:
    dw $02E7                ; text $02E7: "*:I wonder how my brothers are doing. Th…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script07
; ---------------------------------------------------------------------------
ArenaRooms_Script07:
    dw $FF00                ; $00 if_flag_clear: If flag $000E is clear → Bank0D_ScriptAddr_514E
    dw $000E                ;   flag
    dw Bank0D_ScriptAddr_514E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_518C
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_518C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_517A
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_517A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_5176
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_5176 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_5172
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_5172 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_516E
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_516E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_516A
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_516A ;   target
Bank0D_ScriptAddr_514E:
    dw $FF01                ; $01 if_flag_set: If flag $000E is set → Bank0D_ScriptAddr_5166
    dw $000E                ;   flag
    dw Bank0D_ScriptAddr_5166 ;   target
    dw $00F9                ; text $00F9: "*:Want to know where the wife of the Kin…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5162  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5162 ;   target
    dw $00FB                ; text $00FB: "*:You can meet her if you win at rock- p…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5162:
    dw $00FA                ; text $00FA: "*:I bet you wanna know."
    dw $FFFF                ; END

Bank0D_ScriptAddr_5166:
    dw $013D                ; text $013D: "*:Have you been using the Bookmark? *:It…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_516A:
    dw $022E                ; text $022E: "*:I don't know about his personality but…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_516E:
    dw $0281                ; text $0281: "*:You beat Mick? You're one tough cookie…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5172:
    dw $02E8                ; text $02E8: "*:Do ya know! *:A BeastTail has a specia…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5176:
    dw $03A6                ; text $03A6: "*:A monster with a bad personality becom…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_517A:
    dw $03FA                ; text $03FA: "*:You're having trouble with the monster…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5188  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5188 ;   target
    dw $03FB                ; text $03FB: "*:You see the merchant with an attitude …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5188:
    dw $02B4                ; text $02B4: "*:I see. It's okay then. Sorry to bother…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_518C:
    dw $07DD                ; text $07DD: "*:A Servant has 4 hands, Skeletor has 6 …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script08
; ---------------------------------------------------------------------------
ArenaRooms_Script08:
    dw $FF00                ; $00 if_flag_clear: If flag $000E is clear → Bank0D_ScriptAddr_51B4
    dw $000E                ;   flag
    dw Bank0D_ScriptAddr_51B4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00FC is set → Bank0D_ScriptAddr_51D2
    dw $00FC                ;   flag
    dw Bank0D_ScriptAddr_51D2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_51CE
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_51CE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_51CA
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_51CA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0083 is set → Bank0D_ScriptAddr_51C6
    dw $0083                ;   flag
    dw Bank0D_ScriptAddr_51C6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_51C2
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_51C2 ;   target
Bank0D_ScriptAddr_51B4:
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_51BE
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_51BE ;   target
    dw $00FC                ; text $00FC: "*:These statues are the protectors of Gr…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_51BE:
    dw $022F                ; text $022F: "*:These statues stand as the protector o…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_51C2:
    dw $02E9                ; text $02E9: "*:I had a strange dream. This statue sta…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_51C6:
    dw $02EA                ; text $02EA: "*:Oh! It's a miracle! The statue is movi…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_51CA:
    dw $04B8                ; text $04B8: "*:Come on! Pray! Pray to the statue of W…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_51CE:
    dw $07DB                ; text $07DB: "*:One of my friends from abroad is an ol…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_51D2:
    dw $07DC                ; text $07DC: "*:You! I heard you finally made Watabou …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script09
; ---------------------------------------------------------------------------
ArenaRooms_Script09:
    dw $0100                ; text $0100: "[HERO] looked into the jar. An old lady'…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_51E4  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_51E4 ;   target
    dw $086F                ; text $086F: ":If you choose CHARGE you can train the …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_51E4:
    dw $0870                ; text $0870: "[HERO] returned the old lady's notebook …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script10
; ---------------------------------------------------------------------------
ArenaRooms_Script10:
    dw $0101                ; text $0101: "[HERO] looked into the jar. A piece of p…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script11
; ---------------------------------------------------------------------------
ArenaRooms_Script11:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_520A
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_520A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_5206
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_5206 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_5202
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_5202 ;   target
    dw $00FD                ; text $00FD: "*:May I help you? The restaurant is back…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5202:
    dw $0230                ; text $0230: "*:Monsters need education too! *:Persona…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5206:
    dw $03A7                ; text $03A7: "*:I learned a new song from a bishop I k…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_520A:
    dw $07DE                ; text $07DE: "*:The bishop I know told me an intense s…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script12
; ---------------------------------------------------------------------------
ArenaRooms_Script12:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_523C
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_523C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_5238
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_5238 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0035 is clear → Bank0D_ScriptAddr_5226
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_5226 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $006B is set → Bank0D_ScriptAddr_5234
    dw $006B                ;   flag
    dw Bank0D_ScriptAddr_5234 ;   target
Bank0D_ScriptAddr_5226:
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_5230
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_5230 ;   target
    dw $00FF                ; text $00FF: "*:My rival's watching me from somewhere.…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5230:
    dw $0232                ; text $0232: "*:My rival is watching me... *:But as lo…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5234:
    dw $03A9                ; text $03A9: "*:My rival is watching me from... *:If I…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5238:
    dw $0455                ; text $0455: "*:My rival must be watching me... *:He c…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_523C:
    dw $07E0                ; text $07E0: "*:My slime learned an amazing skill! *:W…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script13
; ---------------------------------------------------------------------------
ArenaRooms_Script13:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_526E
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_526E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_526A
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_526A ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0035 is clear → Bank0D_ScriptAddr_5258
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_5258 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $006B is set → Bank0D_ScriptAddr_5266
    dw $006B                ;   flag
    dw Bank0D_ScriptAddr_5266 ;   target
Bank0D_ScriptAddr_5258:
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_5262
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_5262 ;   target
    dw $00FE                ; text $00FE: "*:The guy at the entrance! He's my rival…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5262:
    dw $0231                ; text $0231: "*:The guy at the entrance to the restaur…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5266:
    dw $03A8                ; text $03A8: "*:The guy at the entrance to the restaur…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_526A:
    dw $0454                ; text $0454: "*:The guy at the entrance to the restaur…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_526E:
    dw $07DF                ; text $07DF: "*:The guy at the entrance to the restaur…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script14
; ---------------------------------------------------------------------------
ArenaRooms_Script14:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_529A
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_529A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_5296
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_5296 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_5292
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_5292 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_528E
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_528E ;   target
    dw $0102                ; text $0102: "*:Hm.. It doesn't listen to me much. *:S…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_528E:
    dw $0233                ; text $0233: "*:It's common sense to bring BeastTail o…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5292:
    dw $02EB                ; text $02EB: "*:There are stores behind the Travelers'…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5296:
    dw $0456                ; text $0456: "*:I've been training a BombCrag to run a…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_529A:
    dw $07E1                ; text $07E1: "*:Hurray! I understand now! *:I can be a…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script15
; ---------------------------------------------------------------------------
ArenaRooms_Script15:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_52C6
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_52C6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_52C2
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_52C2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_52BE
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_52BE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_52BA
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_52BA ;   target
    dw $0103                ; text $0103: "*:Hi Ho Hi Ho. *:Sigh.. I'm starving... …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_52BA:
    dw $0234                ; text $0234: "*:Hi ho! Hi ho! *:How long do I need to …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_52BE:
    dw $02EC                ; text $02EC: "*:Hi ho! Hi ho!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_52C2:
    dw $0457                ; text $0457: "*:Scurry away Scurry away! *:It's easy t…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_52C6:
    dw $07E2                ; text $07E2: "*:Hey hey hey! Run! Don't walk! *:Yo, du…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script16
; ---------------------------------------------------------------------------
ArenaRooms_Script16:
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0D_ScriptAddr_53CE
    dw $0111                ;   flag
    dw Bank0D_ScriptAddr_53CE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0110 is set → Bank0D_ScriptAddr_53BC
    dw $0110                ;   flag
    dw Bank0D_ScriptAddr_53BC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_53B8
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_53B8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_53A6
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_53A6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_5394
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_5394 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_5382
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_5382 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0D_ScriptAddr_5370
    dw $0034                ;   flag
    dw Bank0D_ScriptAddr_5370 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_535E
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_535E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_535A
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_535A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_5348
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_5348 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_5336
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_5336 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0D_ScriptAddr_5324
    dw $0030                ;   flag
    dw Bank0D_ScriptAddr_5324 ;   target
    dw $0104                ; text $0104: "*:Yo man, wanna know who your match is i…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5320  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5320 ;   target
    dw $0105                ; text $0105: "*:Its the principal of the school."
    dw $FFFF                ; END

Bank0D_ScriptAddr_5320:
    dw $0106                ; text $0106: "*:Well,it'll be OK too."
    dw $FFFF                ; END

Bank0D_ScriptAddr_5324:
    dw $0180                ; text $0180: "*:Wanna know who's in the F class? [YES/…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5332  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5332 ;   target
    dw $0181                ; text $0181: "*:The last match in the F class is with …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5332:
    dw $0106                ; text $0106: "*:Well,it'll be OK too."
    dw $FFFF                ; END
Bank0D_ScriptAddr_5336:
    dw $01BC                ; text $01BC: "*:Hee hee! Dude! Wanna know who you're g…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5344  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5344 ;   target
    dw $01BD                ; text $01BD: "*:Teto in the waiting room will fight yo…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5344:
    dw $0106                ; text $0106: "*:Well,it'll be OK too."
    dw $FFFF                ; END
Bank0D_ScriptAddr_5348:
    dw $0235                ; text $0235: "*:Wanna know your opponent in D class? […"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5356  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5356 ;   target
    dw $0236                ; text $0236: "*:Your last match in D class will be wit…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5356:
    dw $0106                ; text $0106: "*:Well,it'll be OK too."
    dw $FFFF                ; END
Bank0D_ScriptAddr_535A:
    dw $0282                ; text $0282: "*:Yo, dude! You're not allowed to fight …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_535E:
    dw $02ED                ; text $02ED: "*:Yo dude! Do ya wanna know who your opp…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_536C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_536C ;   target
    dw $02EE                ; text $02EE: "*:Your opponent for the last match will …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_536C:
    dw $0106                ; text $0106: "*:Well,it'll be OK too."
    dw $FFFF                ; END
Bank0D_ScriptAddr_5370:
    dw $0352                ; text $0352: "*:Hee hee! Yo dude, wanna know who you'r…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_537E  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_537E ;   target
    dw $0353                ; text $0353: "*:The last match will be against the man…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_537E:
    dw $0106                ; text $0106: "*:Well,it'll be OK too."
    dw $FFFF                ; END
Bank0D_ScriptAddr_5382:
    dw $03AA                ; text $03AA: "*:Hee hee. Yo dude! Wanna know who you'r…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5390  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5390 ;   target
    dw $03AB                ; text $03AB: "*:The last fight in A class will be with…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5390:
    dw $0106                ; text $0106: "*:Well,it'll be OK too."
    dw $FFFF                ; END
Bank0D_ScriptAddr_5394:
    dw $03FC                ; text $03FC: "*:Hee hee! Yo dude, wanna know who're yo…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_53A2  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_53A2 ;   target
    dw $03FD                ; text $03FD: "*:The last match in S class will be with…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_53A2:
    dw $03FE                ; text $03FE: "*:Well, you're strong so you may not nee…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_53A6:
    dw $0458                ; text $0458: "*:Hee hee! Yo dude. Wanna know who you'r…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_53B4  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_53B4 ;   target
    dw $0459                ; text $0459: "*:Hee hee! I dunno either."
    dw $FFFF                ; END

Bank0D_ScriptAddr_53B4:
    dw $0459                ; text $0459: "*:Hee hee! I dunno either."
    dw $FFFF                ; END
Bank0D_ScriptAddr_53B8:
    dw $07E3                ; text $07E3: "*:Yo, dude, go to the reception. *:The c…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_53BC:
    dw $07E4                ; text $07E4: "*:Yo, dude, wanna know about Master Mons…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_53CA  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_53CA ;   target
    dw $07E5                ; text $07E5: "*:He has GoldSlime Divinegon, & Rosevine…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_53CA:
    dw $07E6                ; text $07E6: "*:Hurray! I understand now! *:I can be a…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_53CE:
    dw $07E7                ; text $07E7: "*:Darn! You really defeated the Master M…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script17
; ---------------------------------------------------------------------------
ArenaRooms_Script17:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_5484
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_5484 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_5480
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_5480 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_546E
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_546E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_5460
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_5460 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_5452
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_5452 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0D_ScriptAddr_5444
    dw $0034                ;   flag
    dw Bank0D_ScriptAddr_5444 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_5436
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_5436 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_5428
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_5428 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_541A
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_541A ;   target
    dw $0107                ; text $0107: "*:Want to hear about my journey beyond t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5416  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5416 ;   target
    dw $0108                ; text $0108: "*:StubSucks & GoHoppers, Anteaters & Gre…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5416:
    dw $0109                ; text $0109: "*:My journey to the Travelers' Gate is a…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_541A:
    dw $0876                ; text $0876: "*:Would you like to hear about the Gate …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5416  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5416 ;   target
    dw $0877                ; text $0877: "*:There were MiniDraks, BigRoosts, EvilS…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5428:
    dw $087C                ; text $087C: "*:Would you like to hear about the Gate …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5416  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5416 ;   target
    dw $087D                ; text $087D: "*:There were BigRoosts, SpotSlimes, Coil…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5436:
    dw $0883                ; text $0883: "*:Would you like to learn about the Gate…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5416  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5416 ;   target
    dw $0884                ; text $0884: "*:There were GiantWorms, Poisongons, Gia…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5444:
    dw $088C                ; text $088C: "*:Would you like to learn about the Gate…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5416  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5416 ;   target
    dw $088D                ; text $088D: "*:There were Snailys, Saccers, Gulpples,…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5452:
    dw $0890                ; text $0890: "*:Would you like to hear about the Gate …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5416  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5416 ;   target
    dw $0891                ; text $0891: "*:There are Onionos, Gophecadas, Pixys, …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5460:
    dw $089B                ; text $089B: "*:Gate of Labyrinth. Want to learn about…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5416  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5416 ;   target
    dw $089C                ; text $089C: "*:There are RockSlimes, Chamelgons, Cact…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_546E:
    dw $089F                ; text $089F: "*:You want to learn about the Gate of Re…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_547C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_547C ;   target
    dw $08A0                ; text $08A0: "*:I don't want to tell you this. *:I thi…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_547C:
    dw $08A1                ; text $08A1: "*:I don't want to be reminded of that Tr…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_5480:
    dw $08A5                ; text $08A5: "*:I,I thought you went to the Gate of Re…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5484:
    dw $01DD                ; text $01DD: "*:In the far recesses of the Chamber of …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script18
; ---------------------------------------------------------------------------
ArenaRooms_Script18:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_553A
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_553A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_5536
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_5536 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_5524
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_5524 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_5516
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_5516 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_5508
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_5508 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0D_ScriptAddr_54FA
    dw $0034                ;   flag
    dw Bank0D_ScriptAddr_54FA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_54EC
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_54EC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_54DE
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_54DE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_54D0
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_54D0 ;   target
    dw $010A                ; text $010A: "*:Want to know about the monsters behind…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_54CC  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_54CC ;   target
    dw $0874                ; text $0874: "*:There will be Spookys, ArmyAnts, Antea…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_54CC:
    dw $0875                ; text $0875: "*:Humpf, okay."
    dw $FFFF                ; END

Bank0D_ScriptAddr_54D0:
    dw $0878                ; text $0878: "*:Want to know about the monsters behind…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_54CC  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_54CC ;   target
    dw $0879                ; text $0879: "*:There were Goopis, PillowRats, DragonK…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_54DE:
    dw $087E                ; text $087E: "*:Want to know about the monsters behind…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_54CC  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_54CC ;   target
    dw $087F                ; text $087F: "*:There are Demonites, BeanMen, 1EyeClow…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_54EC:
    dw $0885                ; text $0885: "*:Want to know about the monsters behind…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_54CC  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_54CC ;   target
    dw $0886                ; text $0886: "*:There are MudDolls, TreeSlimes, SkulRi…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_54FA:
    dw $088E                ; text $088E: "*:Want to know about the monsters behind…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_54CC  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_54CC ;   target
    dw $088F                ; text $088F: "*:There are Facers, Tonguellas, Florajay…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5508:
    dw $0892                ; text $0892: "*:Want to know about the monsters behind…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_54CC  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_54CC ;   target
    dw $0893                ; text $0893: "*:There are SpikyBoys, KingCobras, Mommo…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5516:
    dw $089D                ; text $089D: "*:Want to know about the monsters behind…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_54CC  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_54CC ;   target
    dw $089E                ; text $089E: "*:There are WeedBugs, HammerMen, MadGees…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5524:
    dw $08A2                ; text $08A2: "*:What? You want to know about the Gate …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5532  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5532 ;   target
    dw $08A3                ; text $08A3: "*:I see... I don't remember much... *:Bu…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5532:
    dw $08A4                ; text $08A4: "*:Tut, you remind me of bad memories!"
    dw $FFFF                ; END
Bank0D_ScriptAddr_5536:
    dw $08A6                ; text $08A6: "*:Oh, you haven't visited the Gate of Re…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_553A:
    dw $024D                ; text $024D: "*:If you've got money you should get a S…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script19
; ---------------------------------------------------------------------------
ArenaRooms_Script19:
    dw $0137                ; text $0137: "[HERO] looked into the barrel. Something…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script20
; ---------------------------------------------------------------------------
ArenaRooms_Script20:
    dw $FF01                ; $01 if_flag_set: If flag $003C is set → Bank0D_ScriptAddr_555E
    dw $003C                ;   flag
    dw Bank0D_ScriptAddr_555E ;   target
    dw $0138                ; text $0138: "[HERO] looked into the barrel."
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_555A
    dw Bank0D_ScriptAddr_555A ;   target
    dw $0129                ; text $0129: "Wow! [HERO] got a TinyMedal!"
    dw $FF2A                ; $2A give_item: Give item 30
    dw $001E                ;   item
    dw $FF03                ; $03 set_flag: Set flag $003C
    dw $003C                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_555A:
    dw $0139                ; text $0139: "Wow,a TinyMedal! But cannot carry any mo…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_555E:
    dw $013A                ; text $013A: "[HERO] looked into the barrel. Nothing i…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script21
; ---------------------------------------------------------------------------
ArenaRooms_Script21:
    dw $013A                ; text $013A: "[HERO] looked into the barrel. Nothing i…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script22
; ---------------------------------------------------------------------------
ArenaRooms_Script22:
    dw $013B                ; text $013B: "[HERO] looked into the barrel. A monster…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script23
; ---------------------------------------------------------------------------
ArenaRooms_Script23:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_55CA
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_55CA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_55C0
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_55C0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_55B6
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_55B6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_55AC
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_55AC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_55A2
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_55A2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_5598
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_5598 ;   target
    dw $010B                ; text $010B: "*:This is an "onigiri". C'mon BeBe, repe…"
    dw $010C                ; text $010C: "BeBe:Boo Baa Boo Baa."
    dw $FF03                ; $03 set_flag: Set flag $000F
    dw $000F                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_5598:
    dw $0237                ; text $0237: "*:These are a pair of hashis. Bebe, Repe…"
    dw $010C                ; text $010C: "BeBe:Boo Baa Boo Baa."
    dw $FF03                ; $03 set_flag: Set flag $005B
    dw $005B                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_55A2:
    dw $02F1                ; text $02F1: "*:This is miso shiru. Bebe, repeat after…"
    dw $010C                ; text $010C: "BeBe:Boo Baa Boo Baa."
    dw $FF03                ; $03 set_flag: Set flag $007F
    dw $007F                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_55AC:
    dw $03AE                ; text $03AE: "*:This is a medama-yaki Bebe! Repeat aft…"
    dw $010C                ; text $010C: "BeBe:Boo Baa Boo Baa."
    dw $FF03                ; $03 set_flag: Set flag $0091
    dw $0091                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_55B6:
    dw $045A                ; text $045A: "*:I'm your mother. C'mon Bebe, repeat af…"
    dw $010C                ; text $010C: "BeBe:Boo Baa Boo Baa."
    dw $FF03                ; $03 set_flag: Set flag $00A5
    dw $00A5                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_55C0:
    dw $04BC                ; text $04BC: "*:This is Shoyu! Bebe! Repeat after me. …"
    dw $010C                ; text $010C: "BeBe:Boo Baa Boo Baa."
    dw $FF03                ; $03 set_flag: Set flag $00B1
    dw $00B1                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_55CA:
    dw $07EA                ; text $07EA: "*:This is Natto. repeat after me, c'mon."
    dw $010C                ; text $010C: "BeBe:Boo Baa Boo Baa."
    dw $FF03                ; $03 set_flag: Set flag $0100
    dw $0100                ;   flag
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script24
; ---------------------------------------------------------------------------
ArenaRooms_Script24:
    dw $FF01                ; $01 if_flag_set: If flag $0100 is set → Bank0D_ScriptAddr_5642
    dw $0100                ;   flag
    dw Bank0D_ScriptAddr_5642 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_562A
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_562A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00B1 is set → Bank0D_ScriptAddr_563E
    dw $00B1                ;   flag
    dw Bank0D_ScriptAddr_563E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_562A
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_562A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00A5 is set → Bank0D_ScriptAddr_563A
    dw $00A5                ;   flag
    dw Bank0D_ScriptAddr_563A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_562A
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_562A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0091 is set → Bank0D_ScriptAddr_5636
    dw $0091                ;   flag
    dw Bank0D_ScriptAddr_5636 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_562A
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_562A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $007F is set → Bank0D_ScriptAddr_5632
    dw $007F                ;   flag
    dw Bank0D_ScriptAddr_5632 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_562A
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_562A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $005B is set → Bank0D_ScriptAddr_562E
    dw $005B                ;   flag
    dw Bank0D_ScriptAddr_562E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_562A
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_562A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $000F is set → Bank0D_ScriptAddr_5626
    dw $000F                ;   flag
    dw Bank0D_ScriptAddr_5626 ;   target
    dw $010D                ; text $010D: "*:....."
    dw $FFFF                ; END

Bank0D_ScriptAddr_5626:
    dw $010E                ; text $010E: "*:What the heck is an onigiri? Why can't…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_562A:
    dw $010D                ; text $010D: "*:....."
    dw $FFFF                ; END

Bank0D_ScriptAddr_562E:
    dw $0238                ; text $0238: "*:What the heck are hashis? Why can't yo…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5632:
    dw $02F2                ; text $02F2: "*:What the heck is miso shiru! Can't you…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5636:
    dw $03AF                ; text $03AF: "*:What the heck is a medama-yaki! This i…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_563A:
    dw $045B                ; text $045B: "*:Why do you have to be MY mother!!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_563E:
    dw $04BD                ; text $04BD: "*:What the heck is Shoyu! Can't you just…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5642:
    dw $07EB                ; text $07EB: "*:Natto? What's that? You're making it u…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script25
; ---------------------------------------------------------------------------
ArenaRooms_Script25:
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0D_ScriptAddr_56B4
    dw $0111                ;   flag
    dw Bank0D_ScriptAddr_56B4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0110 is set → Bank0D_ScriptAddr_56B0
    dw $0110                ;   flag
    dw Bank0D_ScriptAddr_56B0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_56AC
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_56AC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_56A8
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_56A8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_56A4
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_56A4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_56A0
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_56A0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_569C
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_569C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_5698
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_5698 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_5694
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_5694 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0D_ScriptAddr_5690
    dw $0030                ;   flag
    dw Bank0D_ScriptAddr_5690 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0121 is set → Bank0D_ScriptAddr_568C
    dw $0121                ;   flag
    dw Bank0D_ScriptAddr_568C ;   target
    dw $010F                ; text $010F: "*:We all gather here seeking victory. *:…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_568C:
    dw $086C                ; text $086C: "*:We gather here at the arena, seeking v…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5690:
    dw $0872                ; text $0872: "*:Hmmm. You survived G class. Well, I gu…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5694:
    dw $0873                ; text $0873: "*:Hmm. You survived F class. Congratulat…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_5698:
    dw $0880                ; text $0880: "*:You survived E class, You did better t…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_569C:
    dw $0284                ; text $0284: "*:So you defeated Mick. *:But remember. …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_56A0:
    dw $02F3                ; text $02F3: "*:We all gather here, seeking victory. *…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_56A4:
    dw $03B0                ; text $03B0: "*:We gather hear seeking victory. *:When…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_56A8:
    dw $045C                ; text $045C: "*:We all gather here seeking victory. *:…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_56AC:
    dw $07EC                ; text $07EC: "*:Victory... You've conquered one of the…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_56B0:
    dw $07ED                ; text $07ED: "*:You won! But you know there is always …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_56B4:
    dw $07EE                ; text $07EE: "*:Y..you defeated the Master Monster Tam…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; ArenaRooms_Script26
; ---------------------------------------------------------------------------
ArenaRooms_Script26:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_56D6
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_56D6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_56D2
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_56D2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_56CE
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_56CE ;   target
    dw $00EF                ; text $00EF: "*:In the back, they teach kids about the…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_56CE:
    dw $0882                ; text $0882: "*:When you choose COMMAND, very wild mon…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_56D2:
    dw $088B                ; text $088B: "*:A mnemonic for useful skills and monst…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_56D6:
    dw $017E                ; text $017E: "*:I'm memorizing monsters' skills. ..mum…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map08 Per-Script Table (map_type=$08, 1 scripts)
; ---------------------------------------------------------------------------
Map08_ScriptPtrTable:
    dw Map08_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map08_Script00
; ---------------------------------------------------------------------------
Map08_Script00:
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is 0 → Bank0D_ScriptAddr_5726  [$D951 = 0]
    dw $D951                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_5726 ;   target
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is 1 → Bank0D_ScriptAddr_5792  [$D951 = 1]
    dw $D951                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5792 ;   target
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is naming the newborn → Bank0D_ScriptAddr_5818  [$D951 = 2]
    dw $D951                ;   address
    dw $0002                ;   value
    dw Bank0D_ScriptAddr_5818 ;   target
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is 4 → Bank0D_ScriptAddr_587A  [$D951 = 4]
    dw $D951                ;   address
    dw $0004                ;   value
    dw Bank0D_ScriptAddr_587A ;   target
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is 5 → Bank0D_ScriptAddr_58E0  [$D951 = 5]
    dw $D951                ;   address
    dw $0005                ;   value
    dw Bank0D_ScriptAddr_58E0 ;   target
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is from the intro bedroom → Bank0D_ScriptAddr_5920  [$D951 = 6]
    dw $D951                ;   address
    dw $0006                ;   value
    dw Bank0D_ScriptAddr_5920 ;   target
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is the breeding ceremony → Bank0D_ScriptAddr_596C  [$D951 = 7]
    dw $D951                ;   address
    dw $0007                ;   value
    dw Bank0D_ScriptAddr_596C ;   target
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is after the ceremony → Bank0D_ScriptAddr_5A40  [$D951 = 8]
    dw $D951                ;   address
    dw $0008                ;   value
    dw Bank0D_ScriptAddr_5A40 ;   target
    dw $FFFF                ; END

Bank0D_ScriptAddr_5726:
    dw $FF12                ; $12 write_ram: All field sprites hidden: shown  [$C8EC := 0]
    dw $C8EC                ;   address
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 3 tiles (script waits)
    dw $0001                ;   actor
    dw $FFD0                ;   pixels
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks left 8 px (script waits)
    dw $0002                ;   actor
    dw $FFF8                ;   pixels
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 3 walks right 8 px (script waits)
    dw $0003                ;   actor
    dw $0008                ;   pixels
    dw $FF48                ; $48 face_down: NPC 3 faces down
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 3 tiles (script waits)
    dw $0001                ;   actor
    dw $0030                ;   pixels
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: 1  [$D951 := 1]
    dw $D951                ;   address
    dw $0001                ;   value
    dw $FF0F                ; $0F map_transition: Go to Starry Shrine Breeding Cutscene at (4, 4)
    dw $0008                ;   map
    dw $0048                ;   x
    dw $0048                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_5792:
    dw $FF15                ; $15 check_and_branch: If “the next game mode” is the field → Bank0D_ScriptAddr_57CE  [$C88B = 1]
    dw $C88B                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_57CE ;   target
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $06FD                ; text $06FD: "[INS 00] & [INS 10] disappeared."
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 3 tiles (script waits)
    dw $0001                ;   actor
    dw $FFD0                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 3 tiles (script waits)
    dw $0001                ;   actor
    dw $0030                ;   pixels
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: back to the Starry Shrine (breeding)  [$D951 := 240]
    dw $D951                ;   address
    dw $00F0                ;   value
    dw $FF4F                ; $4F return_to_saved_position: Go back to the room / spot saved by save_position
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_57CE:
    dw $FF0D                ; $0D npc_write: NPC 2: x low byte := 80
    dw $0002                ;   actor
    dw $0018                ;   field
    dw $0050                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3: x low byte := 96
    dw $0003                ;   actor
    dw $0018                ;   field
    dw $0060                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $06FD                ; text $06FD: "[INS 00] & [INS 10] disappeared."
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 3 tiles (script waits)
    dw $0001                ;   actor
    dw $FFD0                ;   pixels
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 3 tiles (script waits)
    dw $0001                ;   actor
    dw $0030                ;   pixels
    dw $FF12                ; $12 write_ram: Room state of Arena Setup Room (white, 2 Terrys) screen 0 → state 1  [$D99A := 1]
    dw $D99A                ;   address
    dw $0001                ;   value
    dw $FF0F                ; $0F map_transition: Go to Arena Setup Room (white, 2 Terrys) at (9, 4)
    dw $005E                ;   map
    dw $0098                ;   x
    dw $0048                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0D_ScriptAddr_5818:
    dw $FF12                ; $12 write_ram: All field sprites hidden: shown  [$C8EC := 0]
    dw $C8EC                ;   address
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 3 tiles (script waits)
    dw $0001                ;   actor
    dw $FFD0                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 3 tiles (script waits)
    dw $0001                ;   actor
    dw $0030                ;   pixels
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3: talking pose (faces the player)  [slot +$05 := $40]
    dw $0003                ;   actor
    dw $0005                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 32 ticks (~256 frames)
    dw $0020                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $5F
    dw $005F                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0706                ; text $0706: "[INS 10] was born. Give it a name."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: naming the newborn  [$D951 := 2]
    dw $D951                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: back to the Starry Shrine  [$D951 := 241]
    dw $D951                ;   address
    dw $00F1                ;   value
    dw $FF4F                ; $4F return_to_saved_position: Go back to the room / spot saved by save_position
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_587A:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 3 tiles (script waits)
    dw $0001                ;   actor
    dw $FFD0                ;   pixels
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks left 8 px (script waits)
    dw $0002                ;   actor
    dw $FFF8                ;   pixels
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 3 walks right 8 px (script waits)
    dw $0003                ;   actor
    dw $0008                ;   pixels
    dw $FF48                ; $48 face_down: NPC 3 faces down
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 3 tiles (script waits)
    dw $0001                ;   actor
    dw $0030                ;   pixels
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: 5  [$D951 := 5]
    dw $D951                ;   address
    dw $0005                ;   value
    dw $FF0F                ; $0F map_transition: Go to Starry Shrine Breeding Cutscene at (4, 4)
    dw $0008                ;   map
    dw $0048                ;   x
    dw $0048                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_58E0:
    dw $FF0D                ; $0D npc_write: NPC 2: x low byte := 80
    dw $0002                ;   actor
    dw $0018                ;   field
    dw $0050                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3: x low byte := 96
    dw $0003                ;   actor
    dw $0018                ;   field
    dw $0060                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 3 tiles (script waits)
    dw $0001                ;   actor
    dw $FFD0                ;   pixels
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 3 tiles (script waits)
    dw $0001                ;   actor
    dw $0030                ;   pixels
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: back to the Arena Lobby / Restaurant / Queen  [$D951 := 242]
    dw $D951                ;   address
    dw $00F2                ;   value
    dw $FF43                ; $43 return_to_saved_point: Go back to the room / spot saved by save_return_point
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_5920:
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0D_ScriptAddr_5CCC
    dw $00EE                ;   flag
    dw Bank0D_ScriptAddr_5CCC ;   target
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: appear spinning (slow flicker)
    dw $1402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 0 tiles
    dw $0001                ;   actor
    dw $0000                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 3 tiles (script waits)
    dw $0001                ;   actor
    dw $FFD0                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $000F                ; text $000F: "*:Oh, you must be the master. You must h…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 4 tiles
    dw $0002                ;   actor
    dw $0040                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 3 tiles
    dw $0001                ;   actor
    dw $0030                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: the intro journey (dresser → GreatTree → Castle)  [$D951 := 255]
    dw $D951                ;   address
    dw $00FF                ;   value
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF0F                ; $0F map_transition: Go to Starry Shrine at (15, 0)
    dw $0009                ;   map
    dw $00F8                ;   x
    dw $0008                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0D_ScriptAddr_596C:
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0D_ScriptAddr_5CCC
    dw $00EE                ;   flag
    dw Bank0D_ScriptAddr_5CCC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0D_ScriptAddr_597A
    dw $00E4                ;   flag
    dw Bank0D_ScriptAddr_597A ;   target
    dw $FFFF                ; END

Bank0D_ScriptAddr_597A:
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 4 walks up 2 tiles (script waits)
    dw $0004                ;   actor
    dw $FFE0                ;   pixels
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): all black  [$C89D := 255]
    dw $C89D                ;   address
    dw $00FF                ;   value
    dw $FF4D                ; $4D long_delay: Wait 8 frames
    dw $0008                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 2-0-2-3 (0 light … 3 dark)  [$C89D := 226]
    dw $C89D                ;   address
    dw $00E2                ;   value
    dw $FF4D                ; $4D long_delay: Wait 8 frames
    dw $0008                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): all black  [$C89D := 255]
    dw $C89D                ;   address
    dw $00FF                ;   value
    dw $FF4D                ; $4D long_delay: Wait 8 frames
    dw $0008                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 2-0-2-3 (0 light … 3 dark)  [$C89D := 226]
    dw $C89D                ;   address
    dw $00E2                ;   value
    dw $FF4D                ; $4D long_delay: Wait 8 frames
    dw $0008                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): all black  [$C89D := 255]
    dw $C89D                ;   address
    dw $00FF                ;   value
    dw $FF4D                ; $4D long_delay: Wait 8 frames
    dw $0008                ;   frames
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): shades 2-0-2-3 (0 light … 3 dark)  [$C89D := 226]
    dw $C89D                ;   address
    dw $00E2                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 1 tile (script waits)
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 4 walks down 1 tile (script waits)
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $050E                ; text $050E: "*:It is filled with the stars that fell …"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF5E                ; $5E reset_ceremony: Start the breeding ceremony (stage := 7) and clear the ceremony buffer
    dw $FFFF                ; END
Bank0D_ScriptAddr_5A40:
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0D_ScriptAddr_5CCC
    dw $00EE                ;   flag
    dw Bank0D_ScriptAddr_5CCC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0D_ScriptAddr_5A4E
    dw $00E4                ;   flag
    dw Bank0D_ScriptAddr_5A4E ;   target
    dw $FFFF                ; END

Bank0D_ScriptAddr_5A4E:
    dw $FF1C                ; $1C trigger_anim: NPC 3: appear (flicker in)
    dw $0803                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3: talking pose (faces the player)  [slot +$05 := $40]
    dw $0003                ;   actor
    dw $0005                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 32 ticks (~256 frames)
    dw $0020                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $5F
    dw $005F                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 4: hop
    dw $0104                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $050F                ; text $050F: "*:Yes. This is the new spirit of GreatTr…"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 4 walks up 1 tile (script waits)
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 2 (fade): all black  [$C89D := 255]
    dw $C89D                ;   address
    dw $00FF                ;   value
    dw $FF4D                ; $4D long_delay: Wait 8 frames
    dw $0008                ;   frames
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
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF12                ; $12 write_ram: The room effect phase: shown / step 1  [$D9CB := 1]
    dw $D9CB                ;   address
    dw $0001                ;   value
    dw $FF13                ; $13 write_ram2: The field frame counter: 0  [$C8A6 := $0000]
    dw $C8A6                ;   address
    dw $0000                ;   value
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
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
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF21                ; $21 sound: Sound effect $52
    dw $0052                ;   sound
    dw $FF12                ; $12 write_ram: The room effect phase: stopped  [$D9CB := 2]
    dw $D9CB                ;   address
    dw $0002                ;   value
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 4 faces up
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 1-0-0-3 (0 light … 3 dark)  [$C89B := 193]
    dw $C89B                ;   address
    dw $00C1                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 1-0-0-3 (0 light … 3 dark)  [$C89B := 193]
    dw $C89B                ;   address
    dw $00C1                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 1-0-0-3 (0 light … 3 dark)  [$C89B := 193]
    dw $C89B                ;   address
    dw $00C1                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): all black  [$C89C := 255]
    dw $C89C                ;   address
    dw $00FF                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 1-0-0-3 (0 light … 3 dark)  [$C89B := 193]
    dw $C89B                ;   address
    dw $00C1                ;   value
    dw $FF12                ; $12 write_ram: Sprite palette 1 (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89C := 210]
    dw $C89C                ;   address
    dw $00D2                ;   value
    dw $FF12                ; $12 write_ram: Room state of Arena Setup Room (white, 2 Terrys) screen 0 → state 3  [$D99A := 3]
    dw $D99A                ;   address
    dw $0003                ;   value
    dw $FF41                ; $41 set_bgm: Music $02
    dw $0002                ;   song
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Arena Setup Room (white, 2 Terrys) at (3, 4)
    dw $005E                ;   map
    dw $0038                ;   x
    dw $0048                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0D_ScriptAddr_5CCC:
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: appear spinning (slow flicker)
    dw $1402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 0 tiles
    dw $0001                ;   actor
    dw $0000                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 3 tiles (script waits)
    dw $0001                ;   actor
    dw $FFD0                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05B5                ; text $05B5: "*:Oh, [HERO]! Welcome back!! *:I believe…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 4 tiles
    dw $0002                ;   actor
    dw $0040                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 3 tiles
    dw $0001                ;   actor
    dw $0030                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 12 → state 3  [$D933 := 3]
    dw $D933                ;   address
    dw $0003                ;   value
    dw $FF0F                ; $0F map_transition: Go to GreatTree at (4, 30)
    dw $0001                ;   map
    dw $0048                ;   x
    dw $01E8                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
; ---------------------------------------------------------------------------
; Map09 Per-Script Table (map_type=$09, 12 scripts)
; ---------------------------------------------------------------------------
Map09_ScriptPtrTable:
    dw Map09_Script00       ; script 0
    dw Map09_Script01       ; script 1
    dw Map09_Script02       ; script 2
    dw Map09_Script03       ; script 3
    dw Map09_Script04       ; script 4
    dw Map09_Script05       ; script 5
    dw Map09_Script06       ; script 6
    dw Map09_Script07       ; script 7
    dw Map09_Script08       ; script 8
    dw Map09_Script09       ; script 9
    dw Map09_Script10       ; script 10
    dw Map09_Script11       ; script 11
; ---------------------------------------------------------------------------
; Map09_Script00
; ---------------------------------------------------------------------------
Map09_Script00:
    dw $FF15                ; $15 check_and_branch: If “the party is falling through a hole” is yes  (meaning inferred from the scripts that use it) → Bank0D_ScriptAddr_5ECE  [$D9E5 = 1]
    dw $D9E5                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5ECE ;   target
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is back to the Starry Shrine (breeding) → Bank0D_ScriptAddr_5D52  [$D951 = 240]
    dw $D951                ;   address
    dw $00F0                ;   value
    dw Bank0D_ScriptAddr_5D52 ;   target
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is back to the Starry Shrine → Bank0D_ScriptAddr_5DA2  [$D951 = 241]
    dw $D951                ;   address
    dw $00F1                ;   value
    dw Bank0D_ScriptAddr_5DA2 ;   target
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is the intro journey (dresser → GreatTree → Castle) → Bank0D_ScriptAddr_5DE4  [$D951 = 255]
    dw $D951                ;   address
    dw $00FF                ;   value
    dw Bank0D_ScriptAddr_5DE4 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 1 → Bank0D_ScriptAddr_5FA2
    dw $0001                ;   screen
    dw Bank0D_ScriptAddr_5FA2 ;   target
    dw $FFFF                ; END

Bank0D_ScriptAddr_5D52:
    dw $FF50                ; $50 face_saved: The player faces as saved; NPC slot 1 ($D7F8 — Grandpa in the shrine) faces the player
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the "rare breed" mark” is not rare → Bank0D_ScriptAddr_5D6A  [$D9E6 = 0]
    dw $D9E6                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_5D6A ;   target
    dw $06FE                ; text $06FE: "*:Wow! It's a rare breed!"
Bank0D_ScriptAddr_5D6A:
    dw $06FF                ; text $06FF: "*:Inside it is a baby [INS 20]! *:Costs …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0D_ScriptAddr_5D8E  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_5D8E ;   target
    dw $0701                ; text $0701: "*:Then I'll send the egg to the farm!"
    dw $06F1                ; text $06F1: "*:Anything else?"
    dw $FF4E                ; $4E save_position: Remember this room and the player's spot / facing
    dw $FF04                ; $04 open_screen: Open the Starry Shrine breeding list (its texts begin “*:What can I do for you?”)
    dw $0006                ;   kind
    dw $06F0                ;   text
    dw $06F2                ; text $06F2: "*:Create the ultimate monsters!"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: 0  [$D951 := 0]
    dw $D951                ;   address
    dw $0000                ;   value
    dw $FF16                ; $16 refresh_sprites: Redraw the sprites and the screen position (one tick)
    dw $FFFF                ; END

Bank0D_ScriptAddr_5D8E:
    dw $FF60                ; $60 if_gold_short: Go to target when gold < (plus value +$62 of monster [$CA40] + 1) x 10; else pay it (the breeding fee; S124, code-read) → Bank0D_ScriptAddr_5D98
    dw Bank0D_ScriptAddr_5D98 ;   target
    dw $0705                ; text $0705: "*:OK! Wait overnight."
    dw $FF3A                ; $3A to_breeding_scene: Go to the breeding ceremony (map $08) with the chosen monster
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0D_ScriptAddr_5D98:
    dw $070E                ; text $070E: "*:Oh, you don't have enough money."
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: 0  [$D951 := 0]
    dw $D951                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
Bank0D_ScriptAddr_5DA2:
    dw $FF50                ; $50 face_saved: The player faces as saved; NPC slot 1 ($D7F8 — Grandpa in the shrine) faces the player
    dw $FF04                ; $04 open_screen: Open the naming screen (the name $C8F2 points at)
    dw $000F                ;   kind
    dw $0000                ;   text
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0708                ; text $0708: "*:Take [INS 00] with you now?"
    dw $FF04                ; $04 open_screen: Open the shrine entry screen (its texts begin “*:What can I do for you?”)
    dw $000B                ;   kind
    dw $06F0                ;   text
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_5DCA  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_5DCA ;   target
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_5DCC
    dw Bank0D_ScriptAddr_5DCC ;   target
Bank0D_ScriptAddr_5DCA:
    dw $0707                ; text $0707: "*:I'll send [INS 00] to the farm."
Bank0D_ScriptAddr_5DCC:
    dw $06F1                ; text $06F1: "*:Anything else?"
    dw $FF4E                ; $4E save_position: Remember this room and the player's spot / facing
    dw $FF04                ; $04 open_screen: Open the Starry Shrine breeding list (its texts begin “*:What can I do for you?”)
    dw $0006                ;   kind
    dw $06F0                ;   text
    dw $06F2                ; text $06F2: "*:Create the ultimate monsters!"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: 0  [$D951 := 0]
    dw $D951                ;   address
    dw $0000                ;   value
    dw $FF16                ; $16 refresh_sprites: Redraw the sprites and the screen position (one tick)
    dw $FFFF                ; END

Bank0D_ScriptAddr_5DE4:
    dw $FF0E                ; $0E branch_screen: If on screen 1 → Bank0D_ScriptAddr_5DF8
    dw $0001                ;   screen
    dw Bank0D_ScriptAddr_5DF8 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 5 → Bank0D_ScriptAddr_5E44
    dw $0005                ;   screen
    dw Bank0D_ScriptAddr_5E44 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 4 → Bank0D_ScriptAddr_5E80
    dw $0004                ;   screen
    dw Bank0D_ScriptAddr_5E80 ;   target
    dw $FFFF                ; END

Bank0D_ScriptAddr_5DF8:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks left 1 tile
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks left 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 6 tiles
    dw $0002                ;   actor
    dw $0060                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks down 6 tiles
    dw $0000                ;   actor
    dw $0060                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0F                ; $0F map_transition: Go to Starry Shrine at (14, 8)
    dw $0009                ;   map
    dw $00E8                ;   x
    dw $0088                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0D_ScriptAddr_5E44:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 5 tiles
    dw $0004                ;   actor
    dw $0050                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks down 5 tiles
    dw $0000                ;   actor
    dw $0050                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 4 walks left 1 tile
    dw $0004                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1A                ; $1A npc_walk_x: NPC 4 walks left 5 tiles
    dw $0004                ;   actor
    dw $FFB0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks left 5 tiles
    dw $0000                ;   actor
    dw $FFB0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 4 → state 2  [$D953 := 2]
    dw $D953                ;   address
    dw $0002                ;   value
    dw $FF0F                ; $0F map_transition: Go to Starry Shrine at (9, 14)
    dw $0009                ;   map
    dw $0098                ;   x
    dw $00E8                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0D_ScriptAddr_5E80:
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 4 tiles
    dw $0001                ;   actor
    dw $FFC0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: the player walks left 4 tiles
    dw $0000                ;   actor
    dw $FFC0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: the player walks left 1 tile (script waits)
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
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 4 → state 0  [$D953 := 0]
    dw $D953                ;   address
    dw $0000                ;   value
    dw $FF0F                ; $0F map_transition: Go to GreatTree at (4, 30)
    dw $0001                ;   map
    dw $0048                ;   x
    dw $01E8                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0D_ScriptAddr_5ECE:
    dw $FF12                ; $12 write_ram: NPC 4: X position: 24  [$D84A := 24]
    dw $D84A                ;   address
    dw $0018                ;   value
    dw $FF12                ; $12 write_ram: NPC 4: X position (high): 1  [$D84B := 1]
    dw $D84B                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: NPC 5: X position: 24  [$D86A := 24]
    dw $D86A                ;   address
    dw $0018                ;   value
    dw $FF12                ; $12 write_ram: NPC 5: X position (high): 1  [$D86B := 1]
    dw $D86B                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: NPC 6: X position: 24  [$D88A := 24]
    dw $D88A                ;   address
    dw $0018                ;   value
    dw $FF12                ; $12 write_ram: NPC 6: X position (high): 1  [$D88B := 1]
    dw $D88B                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: NPC 7: X position: 24  [$D8AA := 24]
    dw $D8AA                ;   address
    dw $0018                ;   value
    dw $FF12                ; $12 write_ram: NPC 7: X position (high): 1  [$D8AB := 1]
    dw $D8AB                ;   address
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 1 tile
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 1 tile
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 6 is shown
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 1 tile
    dw $0004                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 1 tile
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 6 walks down 1 tile
    dw $0006                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 7 is shown
    dw $0007                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 2 tiles
    dw $0004                ;   actor
    dw $0020                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 3 tiles
    dw $0005                ;   actor
    dw $0030                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 6 walks down 4 tiles
    dw $0006                ;   actor
    dw $0040                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 7 walks down 5 tiles
    dw $0007                ;   actor
    dw $0050                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
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
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The party is falling through a hole: no  [$D9E5 := 0]  (meaning inferred from the scripts that use it)
    dw $D9E5                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_5FA2:
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0D_ScriptAddr_5FAE
    dw $00EE                ;   flag
    dw Bank0D_ScriptAddr_5FAE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0D_ScriptAddr_5FB0
    dw $00E4                ;   flag
    dw Bank0D_ScriptAddr_5FB0 ;   target
Bank0D_ScriptAddr_5FAE:
    dw $FFFF                ; END

Bank0D_ScriptAddr_5FB0:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks down 5 tiles
    dw $0000                ;   actor
    dw $0050                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0510                ; text $0510: "*:Now! Step to the back!"
    dw $FF0B                ; $0B walk_y_wait: the player walks up 4 tiles (script waits)
    dw $0000                ;   actor
    dw $FFC0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: the player walks left 2 tiles (script waits)
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
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
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: the breeding ceremony  [$D951 := 7]
    dw $D951                ;   address
    dw $0007                ;   value
    dw $FF0F                ; $0F map_transition: Go to Starry Shrine Breeding Cutscene at (5, 7)
    dw $0008                ;   map
    dw $0058                ;   x
    dw $0078                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
; ---------------------------------------------------------------------------
; Map09_Script01
; ---------------------------------------------------------------------------
Map09_Script01:
    dw $083A                ; text $083A: "There are letters engraved on the Gate..…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map09_Script02
; ---------------------------------------------------------------------------
Map09_Script02:
    dw $01C1                ; text $01C1: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6012  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6012 ;   target
    dw $01C2                ; text $01C2: ":Breeding is to wed monsters. :After bre…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6012:
    dw $0026                ; text $0026: "[HERO] returned the book to the bookshel…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map09_Script03
; ---------------------------------------------------------------------------
Map09_Script03:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_6074
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_6074 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_6052
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_6052 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_603A
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_603A ;   target
    dw $01C3                ; text $01C3: "[HERO] looked at the bookshelf. :Saying …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6036  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6036 ;   target
    dw $01C4                ; text $01C4: ":Monster Journal by Master Monster Tamer…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6036:
    dw $014F                ; text $014F: "[HERO] returned the diary to the bookshe…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_603A:
    dw $02F4                ; text $02F4: "[HERO] looked at the bookshelf. :Saying …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6036  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6036 ;   target
    dw $02F5                ; text $02F5: ":Monster Diary by the Master Monster Tam…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6036  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6036 ;   target
    dw $02F6                ; text $02F6: ":[HERO] has already conquered D class! :…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6052:
    dw $04C0                ; text $04C0: "[HERO] looked at the bookshelf. :Saying …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6036  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6036 ;   target
    dw $02F5                ; text $02F5: ":Monster Diary by the Master Monster Tam…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6036  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6036 ;   target
    dw $04C1                ; text $04C1: ":[HERO] already conquered D class! :He f…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6036  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6036 ;   target
    dw $04C2                ; text $04C2: ":At last [HERO] will participate in the …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6074:
    dw $07F4                ; text $07F4: ":[HERO] looks at the bookshelf. :Saying …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6036  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6036 ;   target
    dw $02F5                ; text $02F5: ":Monster Diary by the Master Monster Tam…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6036  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6036 ;   target
    dw $04C1                ; text $04C1: ":[HERO] already conquered D class! :He f…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6036  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6036 ;   target
    dw $07F5                ; text $07F5: ":At last, [HERO] will compete in the tou…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6036  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6036 ;   target
    dw $07F6                ; text $07F6: ":At last, [HERO] got a victory! :I remem…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map09_Script04
; ---------------------------------------------------------------------------
Map09_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_60BE
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_60BE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_60BA
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_60BA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_60B6
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_60B6 ;   target
    dw $01BF                ; text $01BF: "*:Hey! Lemme tell ya. when you breed... …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_60B6:
    dw $03B1                ; text $03B1: "*:Splash splash! Lemme tell ya! *:Someti…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_60BA:
    dw $04BE                ; text $04BE: "*:Splash Splash! When the Starry Night n…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_60BE:
    dw $07F2                ; text $07F2: "*:Splash, splash! Congratulations. Lemme…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map09_Script07
; ---------------------------------------------------------------------------
Map09_Script07:
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
; ---------------------------------------------------------------------------
; Map09_Script05
; ---------------------------------------------------------------------------
Map09_Script05:
    dw $FF01                ; $01 if_flag_set: If flag $0103 is set → Bank0D_ScriptAddr_6102
    dw $0103                ;   flag
    dw Bank0D_ScriptAddr_6102 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0111 is set → Bank0D_ScriptAddr_613C
    dw $0111                ;   flag
    dw Bank0D_ScriptAddr_613C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0102 is set → Bank0D_ScriptAddr_6102
    dw $0102                ;   flag
    dw Bank0D_ScriptAddr_6102 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0110 is set → Bank0D_ScriptAddr_6126
    dw $0110                ;   flag
    dw Bank0D_ScriptAddr_6126 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0101 is set → Bank0D_ScriptAddr_6102
    dw $0101                ;   flag
    dw Bank0D_ScriptAddr_6102 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_6110
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_6110 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0045 is set → Bank0D_ScriptAddr_6102
    dw $0045                ;   flag
    dw Bank0D_ScriptAddr_6102 ;   target
    dw $01BE                ; text $01BE: "*:Oh, long time no see! Remember me? *:I…"
    dw $FF03                ; $03 set_flag: Set flag $0045
    dw $0045                ;   flag
    dw $FF4E                ; $4E save_position: Remember this room and the player's spot / facing
    dw $FF04                ; $04 open_screen: Open the Starry Shrine breeding list (its texts begin “*:What can I do for you?”)
    dw $0006                ;   kind
    dw $06F0                ;   text
    dw $06F2                ; text $06F2: "*:Create the ultimate monsters!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6102:
    dw $06F0                ; text $06F0: "*:What can I do for you?"
    dw $FF4E                ; $4E save_position: Remember this room and the player's spot / facing
    dw $FF04                ; $04 open_screen: Open the Starry Shrine breeding list (its texts begin “*:What can I do for you?”)
    dw $0006                ;   kind
    dw $06F0                ;   text
    dw $06F2                ; text $06F2: "*:Create the ultimate monsters!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6110:
    dw $07EF                ; text $07EF: "*:I also was brought here by Watabou a l…"
    dw $FF03                ; $03 set_flag: Set flag $0045
    dw $0045                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0101
    dw $0101                ;   flag
    dw $FF4E                ; $4E save_position: Remember this room and the player's spot / facing
    dw $FF04                ; $04 open_screen: Open the Starry Shrine breeding list (its texts begin “*:What can I do for you?”)
    dw $0006                ;   kind
    dw $06F0                ;   text
    dw $06F2                ; text $06F2: "*:Create the ultimate monsters!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6126:
    dw $07F0                ; text $07F0: "*:Ha Ha Ha! I made a comeback! *:You're …"
    dw $FF03                ; $03 set_flag: Set flag $0045
    dw $0045                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0102
    dw $0102                ;   flag
    dw $FF4E                ; $4E save_position: Remember this room and the player's spot / facing
    dw $FF04                ; $04 open_screen: Open the Starry Shrine breeding list (its texts begin “*:What can I do for you?”)
    dw $0006                ;   kind
    dw $06F0                ;   text
    dw $06F2                ; text $06F2: "*:Create the ultimate monsters!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_613C:
    dw $07F1                ; text $07F1: "*:You...! I have nothing to say. *:You &…"
    dw $FF03                ; $03 set_flag: Set flag $0045
    dw $0045                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0103
    dw $0103                ;   flag
    dw $FF4E                ; $4E save_position: Remember this room and the player's spot / facing
    dw $FF04                ; $04 open_screen: Open the Starry Shrine breeding list (its texts begin “*:What can I do for you?”)
    dw $0006                ;   kind
    dw $06F0                ;   text
    dw $06F2                ; text $06F2: "*:Create the ultimate monsters!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map09_Script06
; ---------------------------------------------------------------------------
Map09_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_6170
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_6170 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_616C
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_616C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_6168
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_6168 ;   target
    dw $01C0                ; text $01C0: "*:After breeding, the parent monsters wi…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6168:
    dw $03B2                ; text $03B2: "*:Breeding monsters is addictive! I can'…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_616C:
    dw $04BF                ; text $04BF: "*:I would like to go deep in the chamber…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6170:
    dw $07F3                ; text $07F3: "*:Congratulations on your victory! Let m…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map09_Script08
; ---------------------------------------------------------------------------
Map09_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_617E
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_617E ;   target
    dw $01C5                ; text $01C5: "*:Master Monster Tamer is in the back. *…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_617E:
    dw $07F7                ; text $07F7: "*:I heard you won with style. *:The Mast…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map09_Script09
; ---------------------------------------------------------------------------
Map09_Script09:
    dw $FF01                ; $01 if_flag_set: If flag $0123 is set → Bank0D_ScriptAddr_61AE
    dw $0123                ;   flag
    dw Bank0D_ScriptAddr_61AE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_61A6
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_61A6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_61A2
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_61A2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_619E
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_619E ;   target
    dw $01C6                ; text $01C6: "*:The level of a newborn monster is alwa…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_619E:
    dw $03B3                ; text $03B3: "*:I didn't know! *:When you breed Dragon…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_61A2:
    dw $04C3                ; text $04C3: "*:The combination with the same monsters…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_61A6:
    dw $07F8                ; text $07F8: "*:Hey, listen! A different monster was b…"
    dw $FF03                ; $03 set_flag: Set flag $0123
    dw $0123                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_61AE:
    dw $0850                ; text $0850: "*:A different monster was born through t…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map09_Script10
; ---------------------------------------------------------------------------
Map09_Script10:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_61D0
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_61D0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_61CC
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_61CC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_61C8
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_61C8 ;   target
    dw $01C7                ; text $01C7: "*:The secret of breeding is to collect m…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_61C8:
    dw $03B4                ; text $03B4: "*:Are you using the library? If you go t…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_61CC:
    dw $04C4                ; text $04C4: "*:Many Stars fall from the sky on the St…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_61D0:
    dw $07F9                ; text $07F9: "*:Where did those millions of stars that…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map09_Script11
; ---------------------------------------------------------------------------
Map09_Script11:
    dw $FF0B                ; $0B walk_y_wait: the player walks up 5 tiles (script waits)
    dw $0000                ;   actor
    dw $FFB0                ;   pixels
    dw $FF12                ; $12 write_ram: Arriving at the Farm by the Shrine warp: yes  [$D9E2 := 1]  (meaning inferred from the scripts that use it)
    dw $D9E2                ;   address
    dw $0001                ;   value
    dw $FF0F                ; $0F map_transition: Go to Farm at (28, 15)
    dw $0004                ;   map
    dw $01C8                ;   x
    dw $00F8                ;   y
; ---------------------------------------------------------------------------
; Map0A Per-Script Table (map_type=$0A, 1 scripts)
; ---------------------------------------------------------------------------
Map0A_ScriptPtrTable:
    dw Map0A_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map0A_Script00
; ---------------------------------------------------------------------------
Map0A_Script00:
    dw $FF01                ; $01 if_flag_set: If flag $0021 is set → Bank0D_ScriptAddr_61F6
    dw $0021                ;   flag
    dw Bank0D_ScriptAddr_61F6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $011E is set → Bank0D_ScriptAddr_61F8
    dw $011E                ;   flag
    dw Bank0D_ScriptAddr_61F8 ;   target
Bank0D_ScriptAddr_61F6:
    dw $FFFF                ; END

Bank0D_ScriptAddr_61F8:
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 4  [$D95E := 4]
    dw $D95E                ;   address
    dw $0004                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0043
    dw $0043                ;   flag
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0B Per-Script Table (map_type=$0B, 1 scripts)
; ---------------------------------------------------------------------------
Map0B_ScriptPtrTable:
    dw Map0B_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map0B_Script00
; ---------------------------------------------------------------------------
Map0B_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateTileset Per-Script Table (map_type=$0C, 6 scripts)
; ---------------------------------------------------------------------------
GateTileset_ScriptPtrTable:
    dw GateTileset_Script00 ; script 0
    dw GateTileset_Script01 ; script 1
    dw GateTileset_Script02 ; script 2
    dw GateTileset_Script03 ; script 3
    dw GateTileset_Script04 ; script 4
    dw GateTileset_Script05 ; script 5
; ---------------------------------------------------------------------------
; GateTileset_Script00
; ---------------------------------------------------------------------------
GateTileset_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateTileset_Script01
; ---------------------------------------------------------------------------
GateTileset_Script01:
    dw $01C9                ; text $01C9: "[HERO] looked at the bookshelf. :Gender …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateTileset_Script02
; ---------------------------------------------------------------------------
GateTileset_Script02:
    dw $01CA                ; text $01CA: "[HERO] looked at the bookshelf. :The lim…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateTileset_Script03
; ---------------------------------------------------------------------------
GateTileset_Script03:
    dw $01CB                ; text $01CB: "[HERO] looked at the bookshelf. :Skills …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; GateTileset_Script04
; ---------------------------------------------------------------------------
GateTileset_Script04:
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
; ---------------------------------------------------------------------------
; GateTileset_Script05
; ---------------------------------------------------------------------------
GateTileset_Script05:
    dw $FF01                ; $01 if_flag_set: If flag $0104 is set → Bank0D_ScriptAddr_624C
    dw $0104                ;   flag
    dw Bank0D_ScriptAddr_624C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_625C
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_625C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0046 is set → Bank0D_ScriptAddr_624C
    dw $0046                ;   flag
    dw Bank0D_ScriptAddr_624C ;   target
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $01C8                ; text $01C8: "*:Oh! What a cute monster master you are…"
    dw $FF03                ; $03 set_flag: Set flag $0046
    dw $0046                ;   flag
    dw $FF04                ; $04 open_screen: Open the egg appraiser (its texts begin “*:Oh my little [HERO], welcome!”)
    dw $0007                ;   kind
    dw $0750                ;   text
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0752                ; text $0752: "*:Oh! You're leaving so soon. *:Come aga…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_624C:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0750                ; text $0750: "*:Oh my little [HERO], welcome!"
    dw $FF04                ; $04 open_screen: Open the egg appraiser (its texts begin “*:Oh my little [HERO], welcome!”)
    dw $0007                ;   kind
    dw $0750                ;   text
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0752                ; text $0752: "*:Oh! You're leaving so soon. *:Come aga…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_625C:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $07FA                ; text $07FA: "*:Hi [HERO]! Welcome home! *:How have yo…"
    dw $FF03                ; $03 set_flag: Set flag $0104
    dw $0104                ;   flag
    dw $FF04                ; $04 open_screen: Open the egg appraiser (its texts begin “*:Oh my little [HERO], welcome!”)
    dw $0007                ;   kind
    dw $0750                ;   text
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0752                ; text $0752: "*:Oh! You're leaving so soon. *:Come aga…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0D Per-Script Table (map_type=$0D, 10 scripts)
; ---------------------------------------------------------------------------
Map0D_ScriptPtrTable:
    dw Map0D_Script00       ; script 0
    dw Map0D_Script01       ; script 1
    dw Map0D_Script02       ; script 2
    dw Map0D_Script03       ; script 3
    dw Map0D_Script04       ; script 4
    dw Map0D_Script05       ; script 5
    dw Map0D_Script06       ; script 6
    dw Map0D_Script07       ; script 7
    dw Map0D_Script08       ; script 8
    dw Map0D_Script09       ; script 9
; ---------------------------------------------------------------------------
; Map0D_Script00
; ---------------------------------------------------------------------------
Map0D_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0D_Script01
; ---------------------------------------------------------------------------
Map0D_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $0047 is set → Bank0D_ScriptAddr_62A2
    dw $0047                ;   flag
    dw Bank0D_ScriptAddr_62A2 ;   target
    dw $01D1                ; text $01D1: "[SOUND 60][HERO] looked inside the dress…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_629E
    dw Bank0D_ScriptAddr_629E ;   target
    dw $0129                ; text $0129: "Wow! [HERO] got a TinyMedal!"
    dw $FF2A                ; $2A give_item: Give item 30
    dw $001E                ;   item
    dw $FF03                ; $03 set_flag: Set flag $0047
    dw $0047                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_629E:
    dw $01D2                ; text $01D2: "Wow! A TinyMedal! But cannot carry any m…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_62A2:
    dw $01D1                ; text $01D1: "[SOUND 60][HERO] looked inside the dress…"
    dw $01D3                ; text $01D3: "The dresser is filled with girl's dresse…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0D_Script02
; ---------------------------------------------------------------------------
Map0D_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_630C
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_630C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_62EA
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_62EA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_62D2
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_62D2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_62C4
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_62C4 ;   target
    dw $01D4                ; text $01D4: "[HERO] looked at the bookshelf. :Journal…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_62C4:
    dw $02FB                ; text $02FB: "[HERO] looked at the bookshelf. :Journal…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_633C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_633C ;   target
    dw $02FC                ; text $02FC: ":Journal of My Baby, Part 2. :My baby le…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_62D2:
    dw $02FB                ; text $02FB: "[HERO] looked at the bookshelf. :Journal…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_633C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_633C ;   target
    dw $03B7                ; text $03B7: ":Journal of My Baby, Part 2 :My baby lea…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_633C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_633C ;   target
    dw $03B8                ; text $03B8: ":Journal of My Baby, Part 3 :Reward them…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_62EA:
    dw $02FB                ; text $02FB: "[HERO] looked at the bookshelf. :Journal…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_633C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_633C ;   target
    dw $03B7                ; text $03B7: ":Journal of My Baby, Part 2 :My baby lea…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_633C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_633C ;   target
    dw $04CA                ; text $04CA: ":Journal of My Baby, Part 3 :Flatter wit…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_633C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_633C ;   target
    dw $04CB                ; text $04CB: ":Journal of My Baby, Part 4 :I guess I'v…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_630C:
    dw $02FB                ; text $02FB: "[HERO] looked at the bookshelf. :Journal…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_633C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_633C ;   target
    dw $03B7                ; text $03B7: ":Journal of My Baby, Part 2 :My baby lea…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_633C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_633C ;   target
    dw $04CA                ; text $04CA: ":Journal of My Baby, Part 3 :Flatter wit…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_633C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_633C ;   target
    dw $07FE                ; text $07FE: ":Steps of My Baby Part 4 :I guess I've f…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_633C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_633C ;   target
    dw $07FF                ; text $07FF: ":Steps of My Baby Part 5 :I came up with…"
    dw $FF03                ; $03 set_flag: Set flag $0105
    dw $0105                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_633C:
    dw $014F                ; text $014F: "[HERO] returned the diary to the bookshe…"
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Map0D_Script03
; ---------------------------------------------------------------------------
Map0D_Script03:
    dw $01D5                ; text $01D5: "[HERO] looked into the jar. Someone is l…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0D_Script04
; ---------------------------------------------------------------------------
Map0D_Script04:
    dw $015D                ; text $015D: "[HERO] looked into the jar. But there wa…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0D_Script05
; ---------------------------------------------------------------------------
Map0D_Script05:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_63A0
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_63A0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_6384
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_6384 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $001D is clear → Bank0D_ScriptAddr_6360
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_6360 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0080 is set → Bank0D_ScriptAddr_6372
    dw $0080                ;   flag
    dw Bank0D_ScriptAddr_6372 ;   target
Bank0D_ScriptAddr_6360:
    dw $01CC                ; text $01CC: "*:You, do you know my daughter? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_636E  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_636E ;   target
    dw $01CE                ; text $01CE: "*:See, isn't she the prettiest girl in G…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_636E:
    dw $01CD                ; text $01CD: "*:You don't!? Such a pretty, gentle & gr…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6372:
    dw $02F7                ; text $02F7: "*:My daughter is the prettiest in GreatT…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6380  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6380 ;   target
    dw $02F8                ; text $02F8: "*:You're a promising child! I'll give yo…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6380:
    dw $02F9                ; text $02F9: "*:Leave me alone!"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6384:
    dw $04C5                ; text $04C5: "*:Do you know my daughter? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_639C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_639C ;   target
    dw $04C7                ; text $04C7: "*:She's the most graceful girl in GreatT…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6380  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6380 ;   target
    dw $04C8                ; text $04C8: "*:You're promising! Let me tell you some…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_639C:
    dw $04C6                ; text $04C6: "*:No!? You don't know such a cute kind a…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_63A0:
    dw $07FB                ; text $07FB: "*:Congratulations on your victory. I kne…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_63AE  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_63AE ;   target
    dw $07FC                ; text $07FC: "*:Just kidding! You're still a kid!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_63AE:
    dw $07FC                ; text $07FC: "*:Just kidding! You're still a kid!"
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Map0D_Script06
; ---------------------------------------------------------------------------
Map0D_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_63DA
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_63DA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_63D6
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_63D6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_63D2
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_63D2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_63CE
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_63CE ;   target
    dw $01CF                ; text $01CF: "*:What does the person living next to yo…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_63CE:
    dw $02FA                ; text $02FA: "*:My grandpa is really stubborn."
    dw $FFFF                ; END

Bank0D_ScriptAddr_63D2:
    dw $03B5                ; text $03B5: "*:The person next to me sings a lot and …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_63D6:
    dw $04C9                ; text $04C9: "*:My hubby adores our girl.. *:Read his …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_63DA:
    dw $07FD                ; text $07FD: "*:My hubby loves our girl so much.. *:..…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0D_Script07
; ---------------------------------------------------------------------------
Map0D_Script07:
    dw $FF01                ; $01 if_flag_set: If flag $0107 is set → Bank0D_ScriptAddr_6428
    dw $0107                ;   flag
    dw Bank0D_ScriptAddr_6428 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0106 is set → Bank0D_ScriptAddr_6416
    dw $0106                ;   flag
    dw Bank0D_ScriptAddr_6416 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F3 is set → Bank0D_ScriptAddr_63FE
    dw $00F3                ;   flag
    dw Bank0D_ScriptAddr_63FE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_63FA
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_63FA ;   target
    dw $01D0                ; text $01D0: "*:I am never going to let anyone through…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_63FA:
    dw $0800                ; text $0800: "*:I won't give this Travelers' Gate to a…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_63FE:
    dw $0801                ; text $0801: "*:Oh, I see. I heard about you from my g…"
    dw $FF40                ; $40 if_party_has_species: If a species $13 is in the party → Bank0D_ScriptAddr_640E
    dw $0013                ;   species
    dw Bank0D_ScriptAddr_640E ;   target
    dw $0803                ; text $0803: "*:If you show me a GoldSlime, *:I'll let…"
    dw $FF03                ; $03 set_flag: Set flag $0106
    dw $0106                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_640E:
    dw $0802                ; text $0802: "*:Oh my! So, this is the GoldSlime! *:Fa…"
    dw $FF03                ; $03 set_flag: Set flag $0107
    dw $0107                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_6416:
    dw $FF40                ; $40 if_party_has_species: If a species $13 is in the party → Bank0D_ScriptAddr_6420
    dw $0013                ;   species
    dw Bank0D_ScriptAddr_6420 ;   target
    dw $0805                ; text $0805: "*:If you show me a GoldSlime, *:I'll let…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6420:
    dw $0804                ; text $0804: "*:Oh my! So, this is the GoldSlime! *:Fa…"
    dw $FF03                ; $03 set_flag: Set flag $0107
    dw $0107                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_6428:
    dw $0806                ; text $0806: "*:Please care for my granddaughter! *:Th…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0D_Script08
; ---------------------------------------------------------------------------
Map0D_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $0107 is set → Bank0D_ScriptAddr_643E
    dw $0107                ;   flag
    dw Bank0D_ScriptAddr_643E ;   target
    dw $FF10                ; $10 walk_to_x: NPC 3 walks to x = 120 px (script waits)
    dw $0003                ;   actor
    dw $0078                ;   x
    dw $FF48                ; $48 face_down: NPC 3 faces down
    dw $0003                ;   actor
    dw $FFFF                ; END

Bank0D_ScriptAddr_643E:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0D_Script09
; ---------------------------------------------------------------------------
Map0D_Script09:
    dw $FF01                ; $01 if_flag_set: If flag $0107 is set → Bank0D_ScriptAddr_6452
    dw $0107                ;   flag
    dw Bank0D_ScriptAddr_6452 ;   target
    dw $FF10                ; $10 walk_to_x: NPC 3 walks to x = 136 px (script waits)
    dw $0003                ;   actor
    dw $0088                ;   x
    dw $FF48                ; $48 face_down: NPC 3 faces down
    dw $0003                ;   actor
    dw $FFFF                ; END

Bank0D_ScriptAddr_6452:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0E Per-Script Table (map_type=$0E, 1 scripts)
; ---------------------------------------------------------------------------
Map0E_ScriptPtrTable:
    dw Map0E_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map0E_Script00
; ---------------------------------------------------------------------------
Map0E_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0F Per-Script Table (map_type=$0F, 3 scripts)
; ---------------------------------------------------------------------------
Map0F_ScriptPtrTable:
    dw Map0F_Script00       ; script 0
    dw Map0F_Script01       ; script 1
    dw Map0F_Script02       ; script 2
; ---------------------------------------------------------------------------
; Map0F_Script00
; ---------------------------------------------------------------------------
Map0F_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0F_Script01
; ---------------------------------------------------------------------------
Map0F_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $0041 is set → Bank0D_ScriptAddr_6476
    dw $0041                ;   flag
    dw Bank0D_ScriptAddr_6476 ;   target
    dw $0182                ; text $0182: "*:Greetings. I manage the Vault. *:You c…"
    dw $FF03                ; $03 set_flag: Set flag $0041
    dw $0041                ;   flag
    dw $FF04                ; $04 open_screen: Open the Vault menu (its texts begin “*:Vault. May I help you?”)
    dw $0002                ;   kind
    dw $06A0                ;   text
    dw $06A2                ; text $06A2: "*:Come again anytime."
    dw $FFFF                ; END

Bank0D_ScriptAddr_6476:
    dw $06A0                ; text $06A0: "*:Vault. May I help you?"
    dw $FF04                ; $04 open_screen: Open the Vault menu (its texts begin “*:Vault. May I help you?”)
    dw $0002                ;   kind
    dw $06A0                ;   text
    dw $06A2                ; text $06A2: "*:Come again anytime."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map0F_Script02
; ---------------------------------------------------------------------------
Map0F_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $0124 is set → Bank0D_ScriptAddr_64B2
    dw $0124                ;   flag
    dw Bank0D_ScriptAddr_64B2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_64AA
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_64AA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0113 is set → Bank0D_ScriptAddr_64A6
    dw $0113                ;   flag
    dw Bank0D_ScriptAddr_64A6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_649E
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_649E ;   target
    dw $0184                ; text $0184: "*:If you're wiped out, most of your item…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_649E:
    dw $04CC                ; text $04CC: "*:I heard a wish will come true when you…"
    dw $FF03                ; $03 set_flag: Set flag $0113
    dw $0113                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_64A6:
    dw $0852                ; text $0852: "*:[HERO], please win for me! *:I wanna b…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_64AA:
    dw $0807                ; text $0807: "*:Oh [HERO], will you listen to me? My b…"
    dw $FF03                ; $03 set_flag: Set flag $0124
    dw $0124                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_64B2:
    dw $0853                ; text $0853: "*:My boss told me I will be an apprentic…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; CopycatRoom Per-Script Table (map_type=$10, 8 scripts)
; ---------------------------------------------------------------------------
CopycatRoom_ScriptPtrTable:
    dw CopycatRoom_Script00 ; script 0
    dw CopycatRoom_Script01 ; script 1
    dw CopycatRoom_Script02 ; script 2
    dw CopycatRoom_Script03 ; script 3
    dw CopycatRoom_Script04 ; script 4
    dw CopycatRoom_Script05 ; script 5
    dw CopycatRoom_Script06 ; script 6
    dw CopycatRoom_Script07 ; script 7
; ---------------------------------------------------------------------------
; CopycatRoom_Script00
; ---------------------------------------------------------------------------
CopycatRoom_Script00:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; CopycatRoom_Script01
; ---------------------------------------------------------------------------
CopycatRoom_Script01:
    dw $01F0                ; text $01F0: "[SOUND 60][HERO] looked into the dresser…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; CopycatRoom_Script02
; ---------------------------------------------------------------------------
CopycatRoom_Script02:
    dw $0276                ; text $0276: "[HERO] looked at the bookshelf. :Seeking…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; CopycatRoom_Script03
; ---------------------------------------------------------------------------
CopycatRoom_Script03:
    dw $02B8                ; text $02B8: "[HERO] looked at the bookshelf. :Make Yo…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; CopycatRoom_Script04
; ---------------------------------------------------------------------------
CopycatRoom_Script04:
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
; ---------------------------------------------------------------------------
; CopycatRoom_Script05
; ---------------------------------------------------------------------------
CopycatRoom_Script05:
    dw $FF01                ; $01 if_flag_set: If flag $0081 is set → Bank0D_ScriptAddr_6550
    dw $0081                ;   flag
    dw Bank0D_ScriptAddr_6550 ;   target
    dw $02FD                ; text $02FD: "*:Who? Who are you? How did you get here…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_64F4  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_64F4 ;   target
    dw $02FE                ; text $02FE: "*:Good excuse. *:You are so funny."
    dw $FFFF                ; END

Bank0D_ScriptAddr_64F4:
    dw $02FF                ; text $02FF: "*:Then did you sneak in to steal somethi…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6502  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6502 ;   target
    dw $0300                ; text $0300: "*:Hey, little thief, I think it's past y…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6502:
    dw $0301                ; text $0301: "*:You snuck in here because I'm so beaut…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6510  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6510 ;   target
    dw $02FE                ; text $02FE: "*:Good excuse. *:You are so funny."
    dw $FFFF                ; END
Bank0D_ScriptAddr_6510:
    dw $0302                ; text $0302: "*:Then you must be a master who's come t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6524  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6524 ;   target
    dw $0303                ; text $0303: "*:You sure don't know how to behave in f…"
    dw $FF03                ; $03 set_flag: Set flag $0081
    dw $0081                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6552
    dw Bank0D_ScriptAddr_6552 ;   target
Bank0D_ScriptAddr_6524:
    dw $0301                ; text $0301: "*:You snuck in here because I'm so beaut…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6532  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6532 ;   target
    dw $02FE                ; text $02FE: "*:Good excuse. *:You are so funny."
    dw $FFFF                ; END
Bank0D_ScriptAddr_6532:
    dw $0302                ; text $0302: "*:Then you must be a master who's come t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6546  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6546 ;   target
    dw $0303                ; text $0303: "*:You sure don't know how to behave in f…"
    dw $FF03                ; $03 set_flag: Set flag $0081
    dw $0081                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6552
    dw Bank0D_ScriptAddr_6552 ;   target
Bank0D_ScriptAddr_6546:
    dw $0304                ; text $0304: "*:Eeek! I cannot stand you! *:I'm gonna …"
    dw $FF03                ; $03 set_flag: Set flag $0081
    dw $0081                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6552
    dw Bank0D_ScriptAddr_6552 ;   target
Bank0D_ScriptAddr_6550:
    dw $0305                ; text $0305: "*:You again!? I'm really gonna get you n…"
Bank0D_ScriptAddr_6552:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 103 (boss)
    dw $0067                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0306                ; text $0306: "*:You don't seem to be a bad guy after a…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 5, curve 2  [$D8E3 := $0205]
    dw $D8E3                ;   address
    dw $0205                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 3: fly in down-left (the flight path set above)
    dw $1503                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 3 faces up
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 3 faces right
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 3 faces down
    dw $0003                ;   actor
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0123                ; text $0123: "Watabou:Doing well huh? Let's go home."
    dw $FF1C                ; $1C trigger_anim: NPC 3: jump
    dw $0403                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 3 faces up
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 3 faces right
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 3 faces down
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 16  [$D9E3 := 16]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0010                ;   value
    dw $FF03                ; $03 set_flag: Set flag $001B
    dw $001B                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 2 → state 3  [$D941 := 3]
    dw $D941                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Copycat House screen 0 (+1 room variant(s) sharing it) → state 1  [$D95A := 1]
    dw $D95A                ;   address
    dw $0001                ;   value
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; CopycatRoom_Script06
; ---------------------------------------------------------------------------
CopycatRoom_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $0108 is set → Bank0D_ScriptAddr_6628
    dw $0108                ;   flag
    dw Bank0D_ScriptAddr_6628 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $001B is clear → Bank0D_ScriptAddr_6604
    dw $001B                ;   flag
    dw Bank0D_ScriptAddr_6604 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_6620
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_6620 ;   target
Bank0D_ScriptAddr_6604:
    dw $FF01                ; $01 if_flag_set: If flag $0082 is set → Bank0D_ScriptAddr_661C
    dw $0082                ;   flag
    dw Bank0D_ScriptAddr_661C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001B is set → Bank0D_ScriptAddr_6614
    dw $001B                ;   flag
    dw Bank0D_ScriptAddr_6614 ;   target
    dw $01D6                ; text $01D6: "*:Get out! I'm not gonna give my Betty t…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6614:
    dw $0307                ; text $0307: "*:It can't be! My Betty is... *:actually…"
    dw $FF03                ; $03 set_flag: Set flag $0082
    dw $0082                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_661C:
    dw $0308                ; text $0308: "*:Betty was actually a CopyCat! Nooooooo…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6620:
    dw $0808                ; text $0808: "*:I was thinking after I realized Betty …"
    dw $FF03                ; $03 set_flag: Set flag $0108
    dw $0108                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_6628:
    dw $0809                ; text $0809: "*:...there was a real Betty somewhere...…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; CopycatRoom_Script07
; ---------------------------------------------------------------------------
CopycatRoom_Script07:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map11 Per-Script Table (map_type=$11, 1 scripts)
; ---------------------------------------------------------------------------
Map11_ScriptPtrTable:
    dw Map11_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map11_Script00
; ---------------------------------------------------------------------------
Map11_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12 Per-Script Table (map_type=$12, 18 scripts)
; ---------------------------------------------------------------------------
Map12_ScriptPtrTable:
    dw Map12_Script00       ; script 0
    dw Map12_Script01       ; script 1
    dw Map12_Script02       ; script 2
    dw Map12_Script03       ; script 3
    dw Map12_Script04       ; script 4
    dw Map12_Script05       ; script 5
    dw Map12_Script06       ; script 6
    dw Map12_Script07       ; script 7
    dw Map12_Script08       ; script 8
    dw Map12_Script09       ; script 9
    dw Map12_Script10       ; script 10
    dw Map12_Script11       ; script 11
    dw Map12_Script12       ; script 12
    dw Map12_Script13       ; script 13
    dw Map12_Script14       ; script 14
    dw Map12_Script15       ; script 15
    dw Map12_Script16       ; script 16
    dw Map12_Script17       ; script 17
; ---------------------------------------------------------------------------
; Map12_Script00
; ---------------------------------------------------------------------------
Map12_Script00:
    dw $FF00                ; $00 if_flag_clear: If flag $0036 is clear → Bank0D_ScriptAddr_666E
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_666E ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0042 is clear → Bank0D_ScriptAddr_666E
    dw $0042                ;   flag
    dw Bank0D_ScriptAddr_666E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0092 is set → Bank0D_ScriptAddr_6670
    dw $0092                ;   flag
    dw Bank0D_ScriptAddr_6670 ;   target
Bank0D_ScriptAddr_666E:
    dw $FFFF                ; END

Bank0D_ScriptAddr_6670:
    dw $FF03                ; $03 set_flag: Set flag $0093
    dw $0093                ;   flag
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script01
; ---------------------------------------------------------------------------
Map12_Script01:
    dw $0188                ; text $0188: "[HERO] looked at the bookshelf. :Family.…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script02
; ---------------------------------------------------------------------------
Map12_Script02:
    dw $0189                ; text $0189: "[HERO] looked at the bookshelf. The 9 fa…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script03
; ---------------------------------------------------------------------------
Map12_Script03:
    dw $018A                ; text $018A: "[HERO] looked at the bookshelf. :Seon Pr…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script04
; ---------------------------------------------------------------------------
Map12_Script04:
    dw $018B                ; text $018B: "[HERO] looked at the bookshelf. :Seon Pr…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script05
; ---------------------------------------------------------------------------
Map12_Script05:
    dw $018C                ; text $018C: "[HERO] looked at the bookshelf. :Seon Pr…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script06
; ---------------------------------------------------------------------------
Map12_Script06:
    dw $018D                ; text $018D: "[HERO] looked at the bookshelf. :Seon Pr…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script07
; ---------------------------------------------------------------------------
Map12_Script07:
    dw $018E                ; text $018E: "[HERO] looked at the bookshelf. :Seon Pr…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script08
; ---------------------------------------------------------------------------
Map12_Script08:
    dw $018F                ; text $018F: "[HERO] looked at the bookshelf. :Seon Pr…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script09
; ---------------------------------------------------------------------------
Map12_Script09:
    dw $0190                ; text $0190: "[HERO] looked at the bookshelf. :Seon Pr…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script10
; ---------------------------------------------------------------------------
Map12_Script10:
    dw $0191                ; text $0191: "[HERO] looked at the bookshelf. :Seon Pr…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script11
; ---------------------------------------------------------------------------
Map12_Script11:
    dw $0192                ; text $0192: "[HERO] looked at the bookshelf. :Seon Pr…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script12
; ---------------------------------------------------------------------------
Map12_Script12:
    dw $0193                ; text $0193: "[HERO] read a poster. :Knowledge is the …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script13
; ---------------------------------------------------------------------------
Map12_Script13:
    dw $FF01                ; $01 if_flag_set: If flag $0109 is set → Bank0D_ScriptAddr_66EA
    dw $0109                ;   flag
    dw Bank0D_ScriptAddr_66EA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_66E2
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_66E2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_66DE
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_66DE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_66DA
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_66DA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_66D6
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_66D6 ;   target
    dw $0185                ; text $0185: "*:Did you know? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_66D2  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_66D2 ;   target
    dw $0186                ; text $0186: "*:Oh, well."
    dw $FFFF                ; END

Bank0D_ScriptAddr_66D2:
    dw $0187                ; text $0187: "*:I heard there is a wedding place for t…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_66D6:
    dw $0239                ; text $0239: "*:I wonder how the Master Monster Tamer …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_66DA:
    dw $0309                ; text $0309: "*:The quake of GreatTree must have some …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_66DE:
    dw $04CD                ; text $04CD: "*:I'm looking for a book. *:I can't find…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_66E2:
    dw $080A                ; text $080A: "*:I've been looking for a book, & I foun…"
    dw $FF03                ; $03 set_flag: Set flag $0109
    dw $0109                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_66EA:
    dw $080B                ; text $080B: "*:It says when the best monster master o…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script14
; ---------------------------------------------------------------------------
Map12_Script14:
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
; ---------------------------------------------------------------------------
; Map12_Script15
; ---------------------------------------------------------------------------
Map12_Script15:
    dw $FF01                ; $01 if_flag_set: If flag $010A is set → Bank0D_ScriptAddr_6718
    dw $010A                ;   flag
    dw Bank0D_ScriptAddr_6718 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_6728
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_6728 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0042 is set → Bank0D_ScriptAddr_6718
    dw $0042                ;   flag
    dw Bank0D_ScriptAddr_6718 ;   target
    dw $0194                ; text $0194: "*:Welcome. You are in the library. *:Vis…"
    dw $FF03                ; $03 set_flag: Set flag $0042
    dw $0042                ;   flag
    dw $FF04                ; $04 open_screen: Open the Library (look up a family) (its texts begin “*:You're at the library. Which family ar…”)
    dw $0008                ;   kind
    dw $0740                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0742                ; text $0742: "*:You're always welcome."
    dw $FFFF                ; END

Bank0D_ScriptAddr_6718:
    dw $0740                ; text $0740: "*:You're at the library. Which family ar…"
    dw $FF04                ; $04 open_screen: Open the Library (look up a family) (its texts begin “*:You're at the library. Which family ar…”)
    dw $0008                ;   kind
    dw $0740                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0742                ; text $0742: "*:You're always welcome."
    dw $FFFF                ; END

Bank0D_ScriptAddr_6728:
    dw $080C                ; text $080C: "*:Even after the Starry Night, monsters …"
    dw $FF03                ; $03 set_flag: Set flag $010A
    dw $010A                ;   flag
    dw $FF04                ; $04 open_screen: Open the Library (look up a family) (its texts begin “*:You're at the library. Which family ar…”)
    dw $0008                ;   kind
    dw $0740                ;   text
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0742                ; text $0742: "*:You're always welcome."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script16
; ---------------------------------------------------------------------------
Map12_Script16:
    dw $FF01                ; $01 if_flag_set: If flag $011F is set → Bank0D_ScriptAddr_6748
    dw $011F                ;   flag
    dw Bank0D_ScriptAddr_6748 ;   target
    dw $0869                ; text $0869: "*:Hi. Welcome to the library. *:You're a…"
    dw $FF03                ; $03 set_flag: Set flag $011F
    dw $011F                ;   flag
Bank0D_ScriptAddr_6748:
    dw $FF51                ; $51 library_tier: Count the library: tier 0-11 (to the check result) and the number (for the next text)
    dw $0790                ; text $0790: "*:How many monsters have you had as you …"
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 0 → Bank0D_ScriptAddr_67AC  [$D8E1 = 0]
    dw $D8E1                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_67AC ;   target
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 1 → Bank0D_ScriptAddr_67B0  [$D8E1 = 1]
    dw $D8E1                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_67B0 ;   target
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 2 → Bank0D_ScriptAddr_67B4  [$D8E1 = 2]
    dw $D8E1                ;   address
    dw $0002                ;   value
    dw Bank0D_ScriptAddr_67B4 ;   target
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 3 → Bank0D_ScriptAddr_67B8  [$D8E1 = 3]
    dw $D8E1                ;   address
    dw $0003                ;   value
    dw Bank0D_ScriptAddr_67B8 ;   target
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 4 → Bank0D_ScriptAddr_67BC  [$D8E1 = 4]
    dw $D8E1                ;   address
    dw $0004                ;   value
    dw Bank0D_ScriptAddr_67BC ;   target
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 5 → Bank0D_ScriptAddr_67C0  [$D8E1 = 5]
    dw $D8E1                ;   address
    dw $0005                ;   value
    dw Bank0D_ScriptAddr_67C0 ;   target
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 6 → Bank0D_ScriptAddr_67C4  [$D8E1 = 6]
    dw $D8E1                ;   address
    dw $0006                ;   value
    dw Bank0D_ScriptAddr_67C4 ;   target
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 7 → Bank0D_ScriptAddr_67C8  [$D8E1 = 7]
    dw $D8E1                ;   address
    dw $0007                ;   value
    dw Bank0D_ScriptAddr_67C8 ;   target
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 8 → Bank0D_ScriptAddr_67CC  [$D8E1 = 8]
    dw $D8E1                ;   address
    dw $0008                ;   value
    dw Bank0D_ScriptAddr_67CC ;   target
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 9 → Bank0D_ScriptAddr_67D0  [$D8E1 = 9]
    dw $D8E1                ;   address
    dw $0009                ;   value
    dw Bank0D_ScriptAddr_67D0 ;   target
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 10 → Bank0D_ScriptAddr_67D4  [$D8E1 = 10]
    dw $D8E1                ;   address
    dw $000A                ;   value
    dw Bank0D_ScriptAddr_67D4 ;   target
    dw $FF15                ; $15 check_and_branch: If “the last check's result” is 11 → Bank0D_ScriptAddr_67D8  [$D8E1 = 11]
    dw $D8E1                ;   address
    dw $000B                ;   value
    dw Bank0D_ScriptAddr_67D8 ;   target
Bank0D_ScriptAddr_67AC:
    dw $0791                ; text $0791: "*:You just started didn't you? *:Good lu…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_67B0:
    dw $0792                ; text $0792: "*:You're still a beginner. Are you using…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_67B4:
    dw $0793                ; text $0793: "*:Have you tried breeding your monsters …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_67B8:
    dw $0794                ; text $0794: "*:Finally, you look more like a monster …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_67BC:
    dw $0795                ; text $0795: "*:For the time being, you should aim to …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_67C0:
    dw $0796                ; text $0796: "*:At last you exceeded 50 kinds. *:But t…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_67C4:
    dw $0797                ; text $0797: "*:You have lots of monsters! You're a go…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_67C8:
    dw $0798                ; text $0798: "*:Great! Over 100 species! *:Nobody can …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_67CC:
    dw $0799                ; text $0799: "*:You're amazing! *:You reached the high…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_67D0:
    dw $079A                ; text $079A: "*:At last you're challenging a record no…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_67D4:
    dw $079B                ; text $079B: "*:Unbelievable number of monsters! How f…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_67D8:
    dw $079C                ; text $079C: "*:Ta-da! Congratulations! *:At last, you…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map12_Script17
; ---------------------------------------------------------------------------
Map12_Script17:
    dw $FF31                ; $31 if_seen_100: Go to target when 100+ species are marked in the library → Bank0D_ScriptAddr_67E8
    dw Bank0D_ScriptAddr_67E8 ;   target
    dw $0195                ; text $0195: "*:In the back, important books are kept.…"
    dw $FF03                ; $03 set_flag: Set flag $0092
    dw $0092                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_67E8:
    dw $03B9                ; text $03B9: "*:You collected more than 100 monsters a…"
    dw $FF0D                ; $0D npc_write: NPC 4: restart its animation from the first frame  [slot +$10 := 0]
    dw $0004                ;   actor
    dw $0010                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 4 is hidden
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 2 walks up 2 tiles (script waits)
    dw $0002                ;   actor
    dw $FFE0                ;   pixels
    dw $FF21                ; $21 sound: Sound effect $51
    dw $0051                ;   sound
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: Room state of Library screen 4 → state 1  [$D95C := 1]
    dw $D95C                ;   address
    dw $0001                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0120
    dw $0120                ;   flag
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13 Per-Script Table (map_type=$13, 16 scripts)
; ---------------------------------------------------------------------------
Map13_ScriptPtrTable:
    dw Map13_Script00       ; script 0
    dw Map13_Script01       ; script 1
    dw Map13_Script02       ; script 2
    dw Map13_Script03       ; script 3
    dw Map13_Script04       ; script 4
    dw Map13_Script05       ; script 5
    dw Map13_Script06       ; script 6
    dw Map13_Script07       ; script 7
    dw Map13_Script08       ; script 8
    dw Map13_Script09       ; script 9
    dw Map13_Script10       ; script 10
    dw Map13_Script11       ; script 11
    dw Map13_Script12       ; script 12
    dw Map13_Script13       ; script 13
    dw Map13_Script14       ; script 14
    dw Map13_Script15       ; script 15
; ---------------------------------------------------------------------------
; Map13_Script00
; ---------------------------------------------------------------------------
Map13_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script01
; ---------------------------------------------------------------------------
Map13_Script01:
    dw $03BB                ; text $03BB: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script02
; ---------------------------------------------------------------------------
Map13_Script02:
    dw $03BC                ; text $03BC: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script03
; ---------------------------------------------------------------------------
Map13_Script03:
    dw $03BD                ; text $03BD: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script04
; ---------------------------------------------------------------------------
Map13_Script04:
    dw $03BE                ; text $03BE: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script05
; ---------------------------------------------------------------------------
Map13_Script05:
    dw $03BF                ; text $03BF: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script06
; ---------------------------------------------------------------------------
Map13_Script06:
    dw $03C0                ; text $03C0: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script07
; ---------------------------------------------------------------------------
Map13_Script07:
    dw $03C1                ; text $03C1: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script08
; ---------------------------------------------------------------------------
Map13_Script08:
    dw $03C2                ; text $03C2: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script09
; ---------------------------------------------------------------------------
Map13_Script09:
    dw $03C3                ; text $03C3: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script10
; ---------------------------------------------------------------------------
Map13_Script10:
    dw $03C4                ; text $03C4: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script11
; ---------------------------------------------------------------------------
Map13_Script11:
    dw $03C5                ; text $03C5: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script12
; ---------------------------------------------------------------------------
Map13_Script12:
    dw $03C6                ; text $03C6: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script13
; ---------------------------------------------------------------------------
Map13_Script13:
    dw $03C7                ; text $03C7: "[HERO] looked at the bookshelf. :Everyth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script14
; ---------------------------------------------------------------------------
Map13_Script14:
    dw $03C8                ; text $03C8: ":[HERO] looked at the bookshelf. :Everyt…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map13_Script15
; ---------------------------------------------------------------------------
Map13_Script15:
    dw $FF01                ; $01 if_flag_set: If flag $02C1 is set → Bank0D_ScriptAddr_6894
    dw $02C1                ;   flag
    dw Bank0D_ScriptAddr_6894 ;   target
    dw $03BA                ; text $03BA: "*:This room is yours!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6894:
    dw $080D                ; text $080D: "*:Congratulations on your victory! It's …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map14 Per-Script Table (map_type=$14, 1 scripts)
; ---------------------------------------------------------------------------
Map14_ScriptPtrTable:
    dw Map14_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map14_Script00
; ---------------------------------------------------------------------------
Map14_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map15 Per-Script Table (map_type=$15, 1 scripts)
; ---------------------------------------------------------------------------
Map15_ScriptPtrTable:
    dw Map15_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map15_Script00
; ---------------------------------------------------------------------------
Map15_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; MedalMan Per-Script Table (map_type=$16, 4 scripts)
; ---------------------------------------------------------------------------
MedalMan_ScriptPtrTable:
    dw MedalMan_Script00    ; script 0
    dw MedalMan_Script01    ; script 1
    dw MedalMan_Script02    ; script 2
    dw MedalMan_Script03    ; script 3
; ---------------------------------------------------------------------------
; MedalMan_Script00
; ---------------------------------------------------------------------------
MedalMan_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; MedalMan_Script01
; ---------------------------------------------------------------------------
MedalMan_Script01:
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
; ---------------------------------------------------------------------------
; MedalMan_Script02
; ---------------------------------------------------------------------------
MedalMan_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $0053 is set → Bank0D_ScriptAddr_68D2
    dw $0053                ;   flag
    dw Bank0D_ScriptAddr_68D2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0038 is set → Bank0D_ScriptAddr_68C8
    dw $0038                ;   flag
    dw Bank0D_ScriptAddr_68C8 ;   target
    dw $0110                ; text $0110: "*:Oh, welcome Mas...ahem. I am the Medal…"
    dw $FF03                ; $03 set_flag: Set flag $0038
    dw $0038                ;   flag
    dw $FF04                ; $04 open_screen: Open the MedalMan's medal exchange (its texts begin “*:I'm collecting medals that are scatter…”)
    dw $000A                ;   kind
    dw $0720                ;   text
    dw $FFFF                ; END

Bank0D_ScriptAddr_68C8:
    dw $0720                ; text $0720: "*:I'm collecting medals that are scatter…"
    dw $FF04                ; $04 open_screen: Open the MedalMan's medal exchange (its texts begin “*:I'm collecting medals that are scatter…”)
    dw $000A                ;   kind
    dw $0720                ;   text
    dw $FFFF                ; END

Bank0D_ScriptAddr_68D2:
    dw $072E                ; text $072E: "*:Thank you [HERO]! You're so kind!"
    dw $FF04                ; $04 open_screen: Open the MedalMan's medal exchange (its texts begin “*:I'm collecting medals that are scatter…”)
    dw $000A                ;   kind
    dw $0720                ;   text
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; MedalMan_Script03
; ---------------------------------------------------------------------------
MedalMan_Script03:
    dw $FF00                ; $00 if_flag_clear: If flag $00EE is clear → Bank0D_ScriptAddr_68FA
    dw $00EE                ;   flag
    dw Bank0D_ScriptAddr_68FA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $005C is set → Bank0D_ScriptAddr_695C
    dw $005C                ;   flag
    dw Bank0D_ScriptAddr_695C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0043 is set → Bank0D_ScriptAddr_6954
    dw $0043                ;   flag
    dw Bank0D_ScriptAddr_6954 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $011E is set → Bank0D_ScriptAddr_6950
    dw $011E                ;   flag
    dw Bank0D_ScriptAddr_6950 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0050 is set → Bank0D_ScriptAddr_6948
    dw $0050                ;   flag
    dw Bank0D_ScriptAddr_6948 ;   target
Bank0D_ScriptAddr_68FA:
    dw $FF00                ; $00 if_flag_clear: If flag $005C is clear → Bank0D_ScriptAddr_6912
    dw $005C                ;   flag
    dw Bank0D_ScriptAddr_6912 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_6944
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_6944 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_6940
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_6940 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_693C
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_693C ;   target
Bank0D_ScriptAddr_6912:
    dw $FF01                ; $01 if_flag_set: If flag $0043 is set → Bank0D_ScriptAddr_6934
    dw $0043                ;   flag
    dw Bank0D_ScriptAddr_6934 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $011E is set → Bank0D_ScriptAddr_6930
    dw $011E                ;   flag
    dw Bank0D_ScriptAddr_6930 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0050 is set → Bank0D_ScriptAddr_6928
    dw $0050                ;   flag
    dw Bank0D_ScriptAddr_6928 ;   target
    dw $0112                ; text $0112: "*:Both the Medal Man & myself love medal…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6928:
    dw $0144                ; text $0144: "*:Thanks [HERO]! For bringing the medals…"
    dw $FF03                ; $03 set_flag: Set flag $011E
    dw $011E                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_6930:
    dw $0868                ; text $0868: "*:To show my appreciation, I'll open the…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6934:
    dw $0145                ; text $0145: "*:I found it! A big trial's waiting for …"
    dw $FF03                ; $03 set_flag: Set flag $005C
    dw $005C                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_693C:
    dw $023A                ; text $023A: "*:The man is always pacing around. *:Som…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6940:
    dw $03C9                ; text $03C9: "*:He looks a bit nervous. I wonder why? …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6944:
    dw $0339                ; text $0339: "*:That man always looks the same but... …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6948:
    dw $0144                ; text $0144: "*:Thanks [HERO]! For bringing the medals…"
    dw $FF03                ; $03 set_flag: Set flag $011E
    dw $011E                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_6950:
    dw $0868                ; text $0868: "*:To show my appreciation, I'll open the…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6954:
    dw $0145                ; text $0145: "*:I found it! A big trial's waiting for …"
    dw $FF03                ; $03 set_flag: Set flag $005C
    dw $005C                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_695C:
    dw $080E                ; text $080E: "*:The Medal Man said you can pass!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map17 Per-Script Table (map_type=$17, 1 scripts)
; ---------------------------------------------------------------------------
Map17_ScriptPtrTable:
    dw Map17_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map17_Script00
; ---------------------------------------------------------------------------
Map17_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Well Per-Script Table (map_type=$18, 9 scripts)
; ---------------------------------------------------------------------------
Well_ScriptPtrTable:
    dw Well_Script00        ; script 0
    dw Well_Script01        ; script 1
    dw Well_Script02        ; script 2
    dw Well_Script03        ; script 3
    dw Well_Script04        ; script 4
    dw Well_Script05        ; script 5
    dw Well_Script06        ; script 6
    dw Well_Script07        ; script 7
    dw Well_Script08        ; script 8
; ---------------------------------------------------------------------------
; Well_Script00
; ---------------------------------------------------------------------------
Well_Script00:
    dw $FF0E                ; $0E branch_screen: If on screen 0 → Bank0D_ScriptAddr_6984
    dw $0000                ;   screen
    dw Bank0D_ScriptAddr_6984 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 4 → Bank0D_ScriptAddr_69AE
    dw $0004                ;   screen
    dw Bank0D_ScriptAddr_69AE ;   target
    dw $FFFF                ; END

Bank0D_ScriptAddr_6984:
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF01                ; $01 if_flag_set: If flag $006A is set → Bank0D_ScriptAddr_69A6
    dw $006A                ;   flag
    dw Bank0D_ScriptAddr_69A6 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0032 is clear → Bank0D_ScriptAddr_69AC
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_69AC ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $005E is clear → Bank0D_ScriptAddr_69AC
    dw $005E                ;   flag
    dw Bank0D_ScriptAddr_69AC ;   target
    dw $FF03                ; $03 set_flag: Set flag $006A
    dw $006A                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Well screen 4 → state 1  [$D960 := 1]
    dw $D960                ;   address
    dw $0001                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_69A6:
    dw $FF03                ; $03 set_flag: Set flag $006B
    dw $006B                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_69AC:
    dw $FFFF                ; END
Bank0D_ScriptAddr_69AE:
    dw $FF01                ; $01 if_flag_set: If flag $006A is set → Bank0D_ScriptAddr_69BA
    dw $006A                ;   flag
    dw Bank0D_ScriptAddr_69BA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $005E is set → Bank0D_ScriptAddr_69BC
    dw $005E                ;   flag
    dw Bank0D_ScriptAddr_69BC ;   target
Bank0D_ScriptAddr_69BA:
    dw $FFFF                ; END

Bank0D_ScriptAddr_69BC:
    dw $FF03                ; $03 set_flag: Set flag $006A
    dw $006A                ;   flag
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Well_Script01
; ---------------------------------------------------------------------------
Well_Script01:
    dw $0199                ; text $0199: "[HERO] looked at the bookshelf. :My rese…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Well_Script02
; ---------------------------------------------------------------------------
Well_Script02:
    dw $019A                ; text $019A: "[HERO] looked at the bookshelf. :The sec…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Well_Script03
; ---------------------------------------------------------------------------
Well_Script03:
    dw $019B                ; text $019B: "[HERO] looked at the bookshelf. :The Mas…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Well_Script04
; ---------------------------------------------------------------------------
Well_Script04:
    dw $019D                ; text $019D: "[HERO] looked into the big kettle. ...So…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Well_Script05
; ---------------------------------------------------------------------------
Well_Script05:
    dw $019C                ; text $019C: "[HERO] looked into the jar. It was a den…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Well_Script06
; ---------------------------------------------------------------------------
Well_Script06:
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
; ---------------------------------------------------------------------------
; Well_Script07
; ---------------------------------------------------------------------------
Well_Script07:
    dw $FF00                ; $00 if_flag_clear: If flag $006C is clear → Bank0D_ScriptAddr_69E6
    dw $006C                ;   flag
    dw Bank0D_ScriptAddr_69E6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_6AD4
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_6AD4 ;   target
Bank0D_ScriptAddr_69E6:
    dw $FF01                ; $01 if_flag_set: If flag $006C is set → Bank0D_ScriptAddr_6AD0
    dw $006C                ;   flag
    dw Bank0D_ScriptAddr_6AD0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $006A is set → Bank0D_ScriptAddr_6AC8
    dw $006A                ;   flag
    dw Bank0D_ScriptAddr_6AC8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $005E is set → Bank0D_ScriptAddr_6AC4
    dw $005E                ;   flag
    dw Bank0D_ScriptAddr_6AC4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $005D is set → Bank0D_ScriptAddr_6A1A
    dw $005D                ;   flag
    dw Bank0D_ScriptAddr_6A1A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_6A12
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_6A12 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_6A0E
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_6A0E ;   target
    dw $0197                ; text $0197: "*:I am an expert monster researcher and …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6A0E:
    dw $01D7                ; text $01D7: "*:Oh,it was you. Appearances can be misl…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6A12:
    dw $023B                ; text $023B: "*:I recognize you are a superior master.…"
    dw $FF03                ; $03 set_flag: Set flag $005D
    dw $005D                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_6A1A:
    dw $0243                ; text $0243: "*:Did you bring a monster with a thunder…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0D_ScriptAddr_6A28  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6A28 ;   target
    dw $023C                ; text $023C: "*:I see. If you find a monster with a th…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6A28:
    dw $FF15                ; $15 check_and_branch: If “the number of monsters in the party” is 1 → Bank0D_ScriptAddr_6A46  [$CA8D = 1]
    dw $CA8D                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6A46 ;   target
    dw $FF34                ; $34 if_slot_skill_b: If party monster 1 knows skill $0F / skill $10 / skill $11 / skill $45 / skill $5A → Bank0D_ScriptAddr_6A4A
    dw $0000                ;   slot
    dw Bank0D_ScriptAddr_6A4A ;   target
    dw $FF34                ; $34 if_slot_skill_b: If party monster 2 knows skill $0F / skill $10 / skill $11 / skill $45 / skill $5A → Bank0D_ScriptAddr_6A88
    dw $0001                ;   slot
    dw Bank0D_ScriptAddr_6A88 ;   target
    dw $FF34                ; $34 if_slot_skill_b: If party monster 3 knows skill $0F / skill $10 / skill $11 / skill $45 / skill $5A → Bank0D_ScriptAddr_6A9E
    dw $0002                ;   slot
    dw Bank0D_ScriptAddr_6A9E ;   target
    dw $023D                ; text $023D: "*:Oh well, you don't have one? Remember,…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6A46:
    dw $085D                ; text $085D: "*:Oh you brought it back... Then.. *:Wel…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6A4A:
    dw $023E                ; text $023E: "*:Oh, you brought one! Then..."
    dw $023F                ; text $023F: "*:Can I have your [INS 00]? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0D_ScriptAddr_6AAE  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6AAE ;   target
    dw $FF34                ; $34 if_slot_skill_b: If party monster 2 knows skill $0F / skill $10 / skill $11 / skill $45 / skill $5A → Bank0D_ScriptAddr_6A66
    dw $0001                ;   slot
    dw Bank0D_ScriptAddr_6A66 ;   target
    dw $FF34                ; $34 if_slot_skill_b: If party monster 3 knows skill $0F / skill $10 / skill $11 / skill $45 / skill $5A → Bank0D_ScriptAddr_6A7A
    dw $0002                ;   slot
    dw Bank0D_ScriptAddr_6A7A ;   target
    dw $0241                ; text $0241: "*:Oh well... next time!"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6A66:
    dw $0242                ; text $0242: "*:Now, can I have your [INS 00]? [YES/NO…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0D_ScriptAddr_6AAE  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6AAE ;   target
    dw $FF34                ; $34 if_slot_skill_b: If party monster 3 knows skill $0F / skill $10 / skill $11 / skill $45 / skill $5A → Bank0D_ScriptAddr_6A7A
    dw $0002                ;   slot
    dw Bank0D_ScriptAddr_6A7A ;   target
    dw $0241                ; text $0241: "*:Oh well... next time!"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6A7A:
    dw $0242                ; text $0242: "*:Now, can I have your [INS 00]? [YES/NO…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0D_ScriptAddr_6AAE  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6AAE ;   target
    dw $0241                ; text $0241: "*:Oh well... next time!"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6A88:
    dw $023E                ; text $023E: "*:Oh, you brought one! Then..."
    dw $023F                ; text $023F: "*:Can I have your [INS 00]? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0D_ScriptAddr_6AAE  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6AAE ;   target
    dw $FF34                ; $34 if_slot_skill_b: If party monster 3 knows skill $0F / skill $10 / skill $11 / skill $45 / skill $5A → Bank0D_ScriptAddr_6A7A
    dw $0002                ;   slot
    dw Bank0D_ScriptAddr_6A7A ;   target
    dw $0241                ; text $0241: "*:Oh well... next time!"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6A9E:
    dw $023E                ; text $023E: "*:Oh, you brought one! Then..."
    dw $023F                ; text $023F: "*:Can I have your [INS 00]? [YES/NO]"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0D_ScriptAddr_6AAE  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6AAE ;   target
    dw $0241                ; text $0241: "*:Oh well... next time!"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6AAE:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF25                ; $25 remove_monster: Remove the monster picked by the last party check ($D8E1)
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0240                ; text $0240: "*:Now I can carry out my experiment! Tha…"
    dw $FF03                ; $03 set_flag: Set flag $005E
    dw $005E                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_6AC4:
    dw $0240                ; text $0240: "*:Now I can carry out my experiment! Tha…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6AC8:
    dw $0285                ; text $0285: "*:[HERO], as you see, the experiment fai…"
    dw $FF03                ; $03 set_flag: Set flag $006C
    dw $006C                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_6AD0:
    dw $0286                ; text $0286: "*:I failed. Sorry, but you have to give …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6AD4:
    dw $080F                ; text $080F: "*:I heard you won the tournament. *:Did …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Well_Script08
; ---------------------------------------------------------------------------
Well_Script08:
    dw $FF00                ; $00 if_flag_clear: If flag $0125 is clear → Bank0D_ScriptAddr_6AE4
    dw $0125                ;   flag
    dw Bank0D_ScriptAddr_6AE4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_6B0A
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_6B0A ;   target
Bank0D_ScriptAddr_6AE4:
    dw $FF01                ; $01 if_flag_set: If flag $006A is set → Bank0D_ScriptAddr_6B02
    dw $006A                ;   flag
    dw Bank0D_ScriptAddr_6B02 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $005D is set → Bank0D_ScriptAddr_6AFE
    dw $005D                ;   flag
    dw Bank0D_ScriptAddr_6AFE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_6AFA
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_6AFA ;   target
    dw $0198                ; text $0198: "*:Good evening. Or is it day? *:I'm an a…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6AFA:
    dw $01D8                ; text $01D8: "*:My professor is a genius and handsome.…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6AFE:
    dw $0244                ; text $0244: "*:Even though its for research... It's c…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6B02:
    dw $0287                ; text $0287: "*:He paid for it! He shouldn't have offe…"
    dw $FF03                ; $03 set_flag: Set flag $0125
    dw $0125                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_6B0A:
    dw $0810                ; text $0810: "*:Well, well. You won but its none of my…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map19 Per-Script Table (map_type=$19, 5 scripts)
; ---------------------------------------------------------------------------
Map19_ScriptPtrTable:
    dw Map19_Script00       ; script 0
    dw Map19_Script01       ; script 1
    dw Map19_Script02       ; script 2
    dw Map19_Script03       ; script 3
    dw Map19_Script04       ; script 4
; ---------------------------------------------------------------------------
; Map19_Script00
; ---------------------------------------------------------------------------
Map19_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map19_Script01
; ---------------------------------------------------------------------------
Map19_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $0083 is set → Bank0D_ScriptAddr_6B48
    dw $0083                ;   flag
    dw Bank0D_ScriptAddr_6B48 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $000E is set → Bank0D_ScriptAddr_6B2A
    dw $000E                ;   flag
    dw Bank0D_ScriptAddr_6B2A ;   target
    dw $030A                ; text $030A: "*:What? You can't even beat my brothers?…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6B2A:
    dw $00F1                ; text $00F1: "*:Let's play rock- paper-scissors! [YES/…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6B3E  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6B3E ;   target
    dw $030B                ; text $030B: "*:Ready! Rock-Paper- Scissors... Go!"
    dw $FF12                ; $12 write_ram: The Goopy game round: 1  [$D9DF := 1]
    dw $D9DF                ;   address
    dw $0001                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_6B3E:
    dw $00F2                ; text $00F2: "*:Hm, its not fun."
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
Bank0D_ScriptAddr_6B48:
    dw $030D                ; text $030D: "*:Go to one of my brothers! Something go…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map19_Script02
; ---------------------------------------------------------------------------
Map19_Script02:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is playing → Bank0D_ScriptAddr_6BD0  [$D9DF = 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6BD0 ;   target
    dw $FF2E                ; $2E pick_from_table: Goopy game: draw the next pick (row 3)
    dw $0003                ;   row
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_6B74  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6B74 ;   target
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_6B74  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6B74 ;   target
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
Bank0D_ScriptAddr_6B74:
    dw $FF0D                ; $0D npc_write: NPC 1: walk animation on  [slot +$05 := $01]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_6BAA  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6BAA ;   target
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 2 → Bank0D_ScriptAddr_6BB4  [$D9E0 = 2]
    dw $D9E0                ;   address
    dw $0002                ;   value
    dw Bank0D_ScriptAddr_6BB4 ;   target
Bank0D_ScriptAddr_6B9A:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is won → Bank0D_ScriptAddr_6BBE  [$D9DF = 5]
    dw $D9DF                ;   address
    dw $0005                ;   value
    dw Bank0D_ScriptAddr_6BBE ;   target
    dw $00F4                ; text $00F4: "*:Darn! Again!"
    dw $FF2F                ; $2F inc_ram: Add 1 to the Goopy game round  [$D9DF + 1]
    dw $D9DF                ;   address
    dw $FFFF                ; END

Bank0D_ScriptAddr_6BAA:
    dw $00F6                ; text $00F6: "*:It's a tie... In this case... *:I win …"
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_6BB4:
    dw $00F5                ; text $00F5: "*:I won! Challenge me anytime!"
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_6BBE:
    dw $030C                ; text $030C: "*:You...You are one tough kid!! *:Okay. …"
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0083
    dw $0083                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Arena Rooms screen 1 → state 2  [$D94C := 2]
    dw $D94C                ;   address
    dw $0002                ;   value
Bank0D_ScriptAddr_6BD0:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map19_Script03
; ---------------------------------------------------------------------------
Map19_Script03:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is playing → Bank0D_ScriptAddr_6BD0  [$D9DF = 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6BD0 ;   target
    dw $FF2E                ; $2E pick_from_table: Goopy game: draw the next pick (row 4)
    dw $0004                ;   row
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_6BFA  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6BFA ;   target
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_6BFA  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6BFA ;   target
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
Bank0D_ScriptAddr_6BFA:
    dw $FF0D                ; $0D npc_write: NPC 1: walk animation on  [slot +$05 := $01]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_6BAA  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6BAA ;   target
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_6BB4  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6BB4 ;   target
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6B9A
    dw Bank0D_ScriptAddr_6B9A ;   target
; ---------------------------------------------------------------------------
; Map19_Script04
; ---------------------------------------------------------------------------
Map19_Script04:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is playing → Bank0D_ScriptAddr_6BD0  [$D9DF = 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6BD0 ;   target
    dw $FF2E                ; $2E pick_from_table: Goopy game: draw the next pick (row 5)
    dw $0005                ;   row
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_6C4C  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6C4C ;   target
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_6C4C  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6C4C ;   target
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
Bank0D_ScriptAddr_6C4C:
    dw $FF0D                ; $0D npc_write: NPC 1: walk animation on  [slot +$05 := $01]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 2 → Bank0D_ScriptAddr_6BAA  [$D9E0 = 2]
    dw $D9E0                ;   address
    dw $0002                ;   value
    dw Bank0D_ScriptAddr_6BAA ;   target
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_6BB4  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6BB4 ;   target
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6B9A
    dw Bank0D_ScriptAddr_6B9A ;   target
; ---------------------------------------------------------------------------
; Map1A Per-Script Table (map_type=$1A, 7 scripts)
; ---------------------------------------------------------------------------
Map1A_ScriptPtrTable:
    dw Map1A_Script00       ; script 0
    dw Map1A_Script01       ; script 1
    dw Map1A_Script02       ; script 2
    dw Map1A_Script03       ; script 3
    dw Map1A_Script04       ; script 4
    dw Map1A_Script05       ; script 5
    dw Map1A_Script06       ; script 6
; ---------------------------------------------------------------------------
; Map1A_Script00
; ---------------------------------------------------------------------------
Map1A_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1A_Script01
; ---------------------------------------------------------------------------
Map1A_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $010C is set → Bank0D_ScriptAddr_6CB4
    dw $010C                ;   flag
    dw Bank0D_ScriptAddr_6CB4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0083 is set → Bank0D_ScriptAddr_6C96
    dw $0083                ;   flag
    dw Bank0D_ScriptAddr_6C96 ;   target
    dw $030A                ; text $030A: "*:What? You can't even beat my brothers?…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6C96:
    dw $00F1                ; text $00F1: "*:Let's play rock- paper-scissors! [YES/…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6CAA  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6CAA ;   target
    dw $030B                ; text $030B: "*:Ready! Rock-Paper- Scissors... Go!"
    dw $FF12                ; $12 write_ram: The Goopy game round: 1  [$D9DF := 1]
    dw $D9DF                ;   address
    dw $0001                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_6CAA:
    dw $00F2                ; text $00F2: "*:Hm, its not fun."
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
Bank0D_ScriptAddr_6CB4:
    dw $0813                ; text $0813: "*:Go to the arena. Something good'll be …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1A_Script02
; ---------------------------------------------------------------------------
Map1A_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $010B is set → Bank0D_ScriptAddr_6CC8
    dw $010B                ;   flag
    dw Bank0D_ScriptAddr_6CC8 ;   target
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0811                ; text $0811: "*:I'm a monster namer. My job is to chan…"
    dw $FF03                ; $03 set_flag: Set flag $010B
    dw $010B                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_6CC8:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0780                ; text $0780: "*:I'm the Master Monster Namer. Wanna ch…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6CF2  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6CF2 ;   target
Bank0D_ScriptAddr_6CD4:
    dw $FF04                ; $04 open_screen: Open the Monster Namer (rename a monster) (its texts begin “*:I'm the Master Monster Namer. Wanna ch…”)
    dw $0009                ;   kind
    dw $0780                ;   text
    dw $FF15                ; $15 check_and_branch: If “the naming screen's default name” is 255 → Bank0D_ScriptAddr_6CF2  [$C8F4 = 255]
    dw $C8F4                ;   address
    dw $00FF                ;   value
    dw Bank0D_ScriptAddr_6CF2 ;   target
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF04                ; $04 open_screen: Open the naming screen (the name $C8F2 points at)
    dw $000F                ;   kind
    dw $0000                ;   text
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6CD4
    dw Bank0D_ScriptAddr_6CD4 ;   target
Bank0D_ScriptAddr_6CF2:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0782                ; text $0782: "*:Come back when you need me."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1A_Script03
; ---------------------------------------------------------------------------
Map1A_Script03:
    dw $0814                ; text $0814: "*:The dude there will change the name of…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1A_Script04
; ---------------------------------------------------------------------------
Map1A_Script04:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is playing → Bank0D_ScriptAddr_6D90  [$D9DF = 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6D90 ;   target
    dw $FF2E                ; $2E pick_from_table: Goopy game: draw the next pick (row 6)
    dw $0006                ;   row
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_6D24  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6D24 ;   target
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_6D24  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6D24 ;   target
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
Bank0D_ScriptAddr_6D24:
    dw $FF0D                ; $0D npc_write: NPC 1: walk animation on  [slot +$05 := $01]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_6D5A  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6D5A ;   target
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 2 → Bank0D_ScriptAddr_6D64  [$D9E0 = 2]
    dw $D9E0                ;   address
    dw $0002                ;   value
    dw Bank0D_ScriptAddr_6D64 ;   target
Bank0D_ScriptAddr_6D4A:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is won → Bank0D_ScriptAddr_6D6E  [$D9DF = 5]
    dw $D9DF                ;   address
    dw $0005                ;   value
    dw Bank0D_ScriptAddr_6D6E ;   target
    dw $00F4                ; text $00F4: "*:Darn! Again!"
    dw $FF2F                ; $2F inc_ram: Add 1 to the Goopy game round  [$D9DF + 1]
    dw $D9DF                ;   address
    dw $FFFF                ; END

Bank0D_ScriptAddr_6D5A:
    dw $00F6                ; text $00F6: "*:It's a tie... In this case... *:I win …"
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_6D64:
    dw $00F5                ; text $00F5: "*:I won! Challenge me anytime!"
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_6D6E:
    dw $0812                ; text $0812: "*:Y..you! You're strong! *:Look, I'll gi…"
    dw $FF12                ; $12 write_ram: The Goopy game round: playing  [$D9DF := 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw $FF03                ; $03 set_flag: Set flag $010C
    dw $010C                ;   flag
    dw $FF01                ; $01 if_flag_set: If flag $001E is set → Bank0D_ScriptAddr_6D88
    dw $001E                ;   flag
    dw Bank0D_ScriptAddr_6D88 ;   target
    dw $FF12                ; $12 write_ram: Room state of Arena Rooms screen 1 → state 4  [$D94C := 4]
    dw $D94C                ;   address
    dw $0004                ;   value
    dw $FFFF                ; END

Bank0D_ScriptAddr_6D88:
    dw $FF12                ; $12 write_ram: Room state of Arena Rooms screen 1 → state 5  [$D94C := 5]
    dw $D94C                ;   address
    dw $0005                ;   value
    dw $FFFF                ; END
Bank0D_ScriptAddr_6D90:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1A_Script05
; ---------------------------------------------------------------------------
Map1A_Script05:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is playing → Bank0D_ScriptAddr_6D90  [$D9DF = 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6D90 ;   target
    dw $FF2E                ; $2E pick_from_table: Goopy game: draw the next pick (row 7)
    dw $0007                ;   row
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_6DBA  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6DBA ;   target
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_6DBA  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6DBA ;   target
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
Bank0D_ScriptAddr_6DBA:
    dw $FF0D                ; $0D npc_write: NPC 1: walk animation on  [slot +$05 := $01]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_6D5A  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6D5A ;   target
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_6D64  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6D64 ;   target
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6D4A
    dw Bank0D_ScriptAddr_6D4A ;   target
; ---------------------------------------------------------------------------
; Map1A_Script06
; ---------------------------------------------------------------------------
Map1A_Script06:
    dw $FF15                ; $15 check_and_branch: If “the Goopy game round” is playing → Bank0D_ScriptAddr_6D90  [$D9DF = 0]
    dw $D9DF                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6D90 ;   target
    dw $FF2E                ; $2E pick_from_table: Goopy game: draw the next pick (row 8)
    dw $0008                ;   row
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 0 → Bank0D_ScriptAddr_6E0C  [$D9E0 = 0]
    dw $D9E0                ;   address
    dw $0000                ;   value
    dw Bank0D_ScriptAddr_6E0C ;   target
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_6E0C  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6E0C ;   target
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
Bank0D_ScriptAddr_6E0C:
    dw $FF0D                ; $0D npc_write: NPC 1: walk animation on  [slot +$05 := $01]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0001                ;   value
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 2 → Bank0D_ScriptAddr_6D5A  [$D9E0 = 2]
    dw $D9E0                ;   address
    dw $0002                ;   value
    dw Bank0D_ScriptAddr_6D5A ;   target
    dw $FF15                ; $15 check_and_branch: If “the Goopy game's pick” is 1 → Bank0D_ScriptAddr_6D64  [$D9E0 = 1]
    dw $D9E0                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6D64 ;   target
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6D4A
    dw Bank0D_ScriptAddr_6D4A ;   target
; ---------------------------------------------------------------------------
; Map1B Per-Script Table (map_type=$1B, 4 scripts)
; ---------------------------------------------------------------------------
Map1B_ScriptPtrTable:
    dw Map1B_Script00       ; script 0
    dw Map1B_Script01       ; script 1
    dw Map1B_Script02       ; script 2
    dw Map1B_Script03       ; script 3
; ---------------------------------------------------------------------------
; Map1B_Script00
; ---------------------------------------------------------------------------
Map1B_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1B_Script01
; ---------------------------------------------------------------------------
Map1B_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0D_ScriptAddr_6E4A
    dw $0034                ;   flag
    dw Bank0D_ScriptAddr_6E4A ;   target
    dw $0245                ; text $0245: "*:A skill such as Vivify can evolve into…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6E4A:
    dw $0354                ; text $0354: "*:BigBang, Hellblast MultiCut.... *:You …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6E58  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6E58 ;   target
    dw $0355                ; text $0355: "*:I see. you've grown to be a respectabl…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6E58:
    dw $0356                ; text $0356: "*:Ho ho ho!! They were names of special …"
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Map1B_Script02
; ---------------------------------------------------------------------------
Map1B_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_6EAC
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_6EAC ;   target
    dw $03CA                ; text $03CA: "*:I'm the Monster Minister! *:Do you wan…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6E7A  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6E7A ;   target
    dw $03CC                ; text $03CC: "*:How about the monsters living behind t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6E7E  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6E7E ;   target
    dw $03CD                ; text $03CD: "*:Behind the Gate of Villager, Stubsucks…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6E7A:
    dw $03CB                ; text $03CB: "*:If you don't want to know, that's fine…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6E7E:
    dw $03CE                ; text $03CE: "*:How about monsters living behind the G…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6E8C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6E8C ;   target
    dw $03CF                ; text $03CF: "*:Behind the Gate of Memories are, Goopi…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6E8C:
    dw $03D0                ; text $03D0: "*:How about the monsters behind the Gate…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6E9A  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6E9A ;   target
    dw $03D1                ; text $03D1: "*:Behind the Gate of Peace live BigRoost…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6E9A:
    dw $03D2                ; text $03D2: "*:How about monsters behind the Gates of…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6EA8  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6EA8 ;   target
    dw $03D3                ; text $03D3: "*:Behind the Gate of Strength live MudDo…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6EA8:
    dw $03D4                ; text $03D4: "*:If you don't want to know, that's fine…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6EAC:
    dw $04CE                ; text $04CE: "*:I am the Monster Minister. All hail! *…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6EC4  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6EC4 ;   target
    dw $04CF                ; text $04CF: "*:How about the monsters behind the Gate…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6EC8  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6EC8 ;   target
    dw $04D0                ; text $04D0: "*:Behind the Gate of Joy live Snailys, S…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6EC4:
    dw $03CB                ; text $03CB: "*:If you don't want to know, that's fine…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6EC8:
    dw $04D1                ; text $04D1: "*:How about the monsters behind the Gate…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6ED6  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6ED6 ;   target
    dw $04D2                ; text $04D2: "*:Behind the Gate of Happiness live Onio…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6ED6:
    dw $04D3                ; text $04D3: "*:How about the monsters behind the Gate…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6EE4  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6EE4 ;   target
    dw $04D4                ; text $04D4: "*:Behind the Gate of Labyrinth live Cham…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6EE4:
    dw $04D5                ; text $04D5: "*:How about the monsters living behind t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6EF2  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6EF2 ;   target
    dw $04D6                ; text $04D6: "*:Behind the Gate of Reflection live Evi…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6EF2:
    dw $03CB                ; text $03CB: "*:If you don't want to know, that's fine…"
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Map1B_Script03
; ---------------------------------------------------------------------------
Map1B_Script03:
    dw $0830                ; text $0830: "*:I'm the Monster Minister Jr. All hail!…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6F0E  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6F0E ;   target
    dw $0832                ; text $0832: "*:Wanna know about the monsters behind t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6F12  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6F12 ;   target
    dw $0833                ; text $0833: "*:Behind the Gate of Villager live Stubs…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6F0E:
    dw $0831                ; text $0831: "*:Don't wanna listen? Snivel..."
    dw $FFFF                ; END

Bank0D_ScriptAddr_6F12:
    dw $0834                ; text $0834: "*:Wanna know about the monsters behind t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6F20  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6F20 ;   target
    dw $0835                ; text $0835: "*:Behind the Gate of Memories live, Goop…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6F20:
    dw $0836                ; text $0836: "*:Wanna know about the monsters behind t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6F2E  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6F2E ;   target
    dw $0837                ; text $0837: "*:Behind the Gate of Peace, there will b…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6F2E:
    dw $0838                ; text $0838: "*:Wanna know about the monsters behind t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_6F3C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_6F3C ;   target
    dw $0839                ; text $0839: "*:Behind the Gate of Strength, there wil…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_6F3C:
    dw $0831                ; text $0831: "*:Don't wanna listen? Snivel..."
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Map1C Per-Script Table (map_type=$1C, 7 scripts)
; ---------------------------------------------------------------------------
Map1C_ScriptPtrTable:
    dw Map1C_Script00       ; script 0
    dw Map1C_Script01       ; script 1
    dw Map1C_Script02       ; script 2
    dw Map1C_Script03       ; script 3
    dw Map1C_Script04       ; script 4
    dw Map1C_Script05       ; script 5
    dw Map1C_Script06       ; script 6
; ---------------------------------------------------------------------------
; Map1C_Script00
; ---------------------------------------------------------------------------
Map1C_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1C_Script01
; ---------------------------------------------------------------------------
Map1C_Script01:
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6FCC)
    dw Bank0D_ScriptAddr_6FCC ;   data
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: y low byte := 32
    dw $0001                ;   actor
    dw $001A                ;   field
    dw $0020                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2: y low byte := 32
    dw $0002                ;   actor
    dw $001A                ;   field
    dw $0020                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF01                ; $01 if_flag_set: If flag $0034 is set → Bank0D_ScriptAddr_6F8E
    dw $0034                ;   flag
    dw Bank0D_ScriptAddr_6F8E ;   target
    dw $0249                ; text $0249: "*:Argh, who woke us up?"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6F94
    dw Bank0D_ScriptAddr_6F94 ;   target
Bank0D_ScriptAddr_6F8E:
    dw $0357                ; text $0357: "*:Even though we are Horks, we don't lik…"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6F94
    dw Bank0D_ScriptAddr_6F94 ;   target
Bank0D_ScriptAddr_6F94:
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6FB6)
    dw Bank0D_ScriptAddr_6FB6 ;   data
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FFFF                ; END

Bank0D_ScriptAddr_6FB6:
    db $48, $00, $14, $15, $14, $15, $D8, $16, $17, $16, $17, $D8, $18, $19, $18, $19, $D8, $1A, $1B, $1A, $1B, $D9  ; tile patch (op $24): BG offset $0048 (row 2, column 8), tiles 14 15 14 15 / 16 17 16 17 / 18 19 18 19 / 1A 1B 1A 1B; $D8 = next row, $D9 = end
Bank0D_ScriptAddr_6FCC:
    db $48, $00, $1C, $1D, $1C, $1D, $D8, $1E, $1F, $1E, $1F, $D8, $20, $21, $20, $21, $D8, $22, $23, $22, $23, $D9  ; tile patch (op $24): BG offset $0048 (row 2, column 8), tiles 1C 1D 1C 1D / 1E 1F 1E 1F / 20 21 20 21 / 22 23 22 23; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map1C_Script02
; ---------------------------------------------------------------------------
Map1C_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_6FF6
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_6FF6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_6FF2
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_6FF2 ;   target
    dw $024B                ; text $024B: "[HERO] looked at the candle. Whoa! It's …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6FF2:
    dw $04DA                ; text $04DA: "*:Flaring.... I am MadCandle. *:My flame…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_6FF6:
    dw $0817                ; text $0817: "*:New lives were born on the Starry Nigh…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1C_Script03
; ---------------------------------------------------------------------------
Map1C_Script03:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_700E
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_700E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_700A
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_700A ;   target
    dw $024B                ; text $024B: "[HERO] looked at the candle. Whoa! It's …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_700A:
    dw $04DA                ; text $04DA: "*:Flaring.... I am MadCandle. *:My flame…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_700E:
    dw $0818                ; text $0818: "*:My flame became more intense than usua…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1C_Script04
; ---------------------------------------------------------------------------
Map1C_Script04:
    dw $0246                ; text $0246: "*:Monsters fight differently depending o…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7020  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7020 ;   target
    dw $0247                ; text $0247: "*:Order the same command again & again u…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7020:
    dw $0248                ; text $0248: "*:A good personality makes good things h…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1C_Script05
; ---------------------------------------------------------------------------
Map1C_Script05:
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6FCC)
    dw Bank0D_ScriptAddr_6FCC ;   data
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: y low byte := 32
    dw $0001                ;   actor
    dw $001A                ;   field
    dw $0020                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2: y low byte := 32
    dw $0002                ;   actor
    dw $001A                ;   field
    dw $0020                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_7086
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_7086 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_7080
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_7080 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_707A
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_707A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_7074
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_7074 ;   target
    dw $03D6                ; text $03D6: "*:Ha ha ha! I made Gigantes a coward!"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6F94
    dw Bank0D_ScriptAddr_6F94 ;   target
Bank0D_ScriptAddr_7074:
    dw $0348                ; text $0348: "*:Ha ha ha! I made Gigantes smug!"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6F94
    dw Bank0D_ScriptAddr_6F94 ;   target
Bank0D_ScriptAddr_707A:
    dw $045E                ; text $045E: "*:Ha ha ha! I made Gigantes an uncertain…"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6F94
    dw Bank0D_ScriptAddr_6F94 ;   target
Bank0D_ScriptAddr_7080:
    dw $04D8                ; text $04D8: "*:Ha ha ha! I made Gigantes brave! *:Boo…"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6F94
    dw Bank0D_ScriptAddr_6F94 ;   target
Bank0D_ScriptAddr_7086:
    dw $0816                ; text $0816: "*:Is the Starry Night already over? *:Oh…"
    dw $FF14                ; $14 goto: Go to Bank0D_ScriptAddr_6F94
    dw Bank0D_ScriptAddr_6F94 ;   target
; ---------------------------------------------------------------------------
; Map1C_Script06
; ---------------------------------------------------------------------------
Map1C_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_70B4
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_70B4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_70B0
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_70B0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_70AC
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_70AC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_70A8
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_70A8 ;   target
    dw $03D5                ; text $03D5: "*:Don't pick on me!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_70A8:
    dw $0345                ; text $0345: "*:I'm the King of the world!!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_70AC:
    dw $045D                ; text $045D: "*:What should I do? That looks nice, thi…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_70B0:
    dw $04D7                ; text $04D7: "*:I will do anything for you!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_70B4:
    dw $0815                ; text $0815: "*:Ho Ho Ho. I made the Servant careless!…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1D Per-Script Table (map_type=$1D, 7 scripts)
; ---------------------------------------------------------------------------
Map1D_ScriptPtrTable:
    dw Map1D_Script00       ; script 0
    dw Map1D_Script01       ; script 1
    dw Map1D_Script02       ; script 2
    dw Map1D_Script03       ; script 3
    dw Map1D_Script04       ; script 4
    dw Map1D_Script05       ; script 5
    dw Map1D_Script06       ; script 6
; ---------------------------------------------------------------------------
; Map1D_Script00
; ---------------------------------------------------------------------------
Map1D_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1D_Script01
; ---------------------------------------------------------------------------
Map1D_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_70E8
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_70E8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_70D8
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_70D8 ;   target
    dw $0117                ; text $0117: "[HERO] read the blackboard. :Do's & Don'…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_70D8:
    dw $0889                ; text $0889: "[HERO] reads the blackboard. *:There are…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_70E6  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_70E6 ;   target
    dw $088A                ; text $088A: "*:Namely, dragons with Metaly parents *:…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_70E6:
    dw $FFFF                ; END
Bank0D_ScriptAddr_70E8:
    dw $0889                ; text $0889: "[HERO] reads the blackboard. *:There are…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_70E6  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_70E6 ;   target
    dw $08C6                ; text $08C6: "*:In other words, a Dragon with Metaly a…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1D_Script02
; ---------------------------------------------------------------------------
Map1D_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_710A
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_710A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_7106
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_7106 ;   target
    dw $0118                ; text $0118: "[HERO] read the blackboard. :Masters are…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7106:
    dw $034E                ; text $034E: "[HERO] read the blackboard. :The princip…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_710A:
    dw $04B9                ; text $04B9: "[HERO] reads the blackboard. :The princi…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1D_Script03
; ---------------------------------------------------------------------------
Map1D_Script03:
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
; ---------------------------------------------------------------------------
; Map1D_Script04
; ---------------------------------------------------------------------------
Map1D_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $010D is set → Bank0D_ScriptAddr_71AE
    dw $010D                ;   flag
    dw Bank0D_ScriptAddr_71AE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_7198
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_7198 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_7180
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_7180 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_7172
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_7172 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_715A
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_715A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0D_ScriptAddr_714C
    dw $0030                ;   flag
    dw Bank0D_ScriptAddr_714C ;   target
    dw $0113                ; text $0113: "*:Welcome to the Master School! *:I am t…"
    dw $FF03                ; $03 set_flag: Set flag $0039
    dw $0039                ;   flag
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7148  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7148 ;   target
    dw $0114                ; text $0114: "*:Sometimes monsters you beat will becom…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7148:
    dw $0871                ; text $0871: "*:Hmmm. It's unfortunate."
    dw $FFFF                ; END

Bank0D_ScriptAddr_714C:
    dw $019E                ; text $019E: "*:Welcome to the Master School! *:[HERO]…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7148  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7148 ;   target
    dw $0114                ; text $0114: "*:Sometimes monsters you beat will becom…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_715A:
    dw $01D9                ; text $01D9: "*:Welcome to the Master School! *:Today'…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7148  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7148 ;   target
    dw $087A                ; text $087A: "*:There are characteristics for monsters…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7148  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7148 ;   target
    dw $087B                ; text $087B: "*:Dragons with Metaly parents *:are more…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7172:
    dw $0288                ; text $0288: "*:Welcome to the Master School. *:Today'…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7148  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7148 ;   target
    dw $0887                ; text $0887: "*:When the family of the pedigree and th…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7180:
    dw $0894                ; text $0894: "*:The Hork downstairs wants to learn Viv…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7148  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7148 ;   target
    dw $0895                ; text $0895: "*:Monsters can inherit all the skills of…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7148  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7148 ;   target
    dw $0896                ; text $0896: "*:Its parents only learned Heal, *:among…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7198:
    dw $0819                ; text $0819: "*:[HERO], Well done! Congratulations on …"
    dw $FF03                ; $03 set_flag: Set flag $010D
    dw $010D                ;   flag
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_71AA  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_71AA ;   target
    dw $028C                ; text $028C: "*:The names of the monsters available on…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_71AA:
    dw $028D                ; text $028D: "*:Hmm. Indeed. The victor, [HERO] won't …"
    dw $FFFF                ; END
Bank0D_ScriptAddr_71AE:
    dw $081A                ; text $081A: "*:Just like you, the Master Monster Tame…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_71AA  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_71AA ;   target
    dw $028C                ; text $028C: "*:The names of the monsters available on…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1D_Script05
; ---------------------------------------------------------------------------
Map1D_Script05:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_7206
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_7206 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_71EA
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_71EA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_71DC
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_71DC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0D_ScriptAddr_71D8
    dw $0030                ;   flag
    dw Bank0D_ScriptAddr_71D8 ;   target
    dw $0115                ; text $0115: "*:It's helpful to take a WarpWing with y…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_71D8:
    dw $019F                ; text $019F: "*:It's always better to have a WarpWing …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_71DC:
    dw $01DA                ; text $01DA: "*:I took notes about how to catch monste…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7230  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7230 ;   target
    dw $01DC                ; text $01DC: "[HERO] opens the notebook. :Giving monst…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_71EA:
    dw $0897                ; text $0897: "*:I took notes on how to change the gend…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_71F8  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_71F8 ;   target
    dw $0898                ; text $0898: "[HERO] opened the notebook. :When the fa…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_71F8:
    dw $0899                ; text $0899: "*:I took notes on how to catch monsters.…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7230  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7230 ;   target
    dw $01DC                ; text $01DC: "[HERO] opens the notebook. :Giving monst…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7206:
    dw $028E                ; text $028E: "*:Congratulations on your victory! Our a…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7214  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7214 ;   target
    dw $02EF                ; text $02EF: "[HERO] opened the notebook. :Monsters ca…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7214:
    dw $02F0                ; text $02F0: "*:I took notes on how to change the gend…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7222  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7222 ;   target
    dw $0898                ; text $0898: "[HERO] opened the notebook. :When the fa…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7222:
    dw $0899                ; text $0899: "*:I took notes on how to catch monsters.…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7230  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7230 ;   target
    dw $01DC                ; text $01DC: "[HERO] opens the notebook. :Giving monst…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7230:
    dw $01DB                ; text $01DB: "*:Let me know if you do!"
    dw $FFFF                ; END
; ---------------------------------------------------------------------------
; Map1D_Script06
; ---------------------------------------------------------------------------
Map1D_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_7266
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_7266 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_7262
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_7262 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_725E
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_725E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_725A
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_725A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0030 is set → Bank0D_ScriptAddr_7256
    dw $0030                ;   flag
    dw Bank0D_ScriptAddr_7256 ;   target
    dw $0116                ; text $0116: "*:Here's the Monster Master School."
    dw $FFFF                ; END

Bank0D_ScriptAddr_7256:
    dw $01A0                ; text $01A0: "*:You are good. You beat the teacher!"
    dw $FFFF                ; END

Bank0D_ScriptAddr_725A:
    dw $01DE                ; text $01DE: "*:There are foreign masters who... *:...…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_725E:
    dw $0888                ; text $0888: "*:There are foreign masters whose monste…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7262:
    dw $089A                ; text $089A: "*:Foreign masters have lots of kinds of …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7266:
    dw $030F                ; text $030F: "*:Foreign masters have many kinds of mon…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1E Per-Script Table (map_type=$1E, 5 scripts)
; ---------------------------------------------------------------------------
Map1E_ScriptPtrTable:
    dw Map1E_Script00       ; script 0
    dw Map1E_Script01       ; script 1
    dw Map1E_Script02       ; script 2
    dw Map1E_Script03       ; script 3
    dw Map1E_Script04       ; script 4
; ---------------------------------------------------------------------------
; Map1E_Script00
; ---------------------------------------------------------------------------
Map1E_Script00:
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is back to the Arena Lobby / Restaurant / Queen → Bank0D_ScriptAddr_727E  [$D951 = 242]
    dw $D951                ;   address
    dw $00F2                ;   value
    dw Bank0D_ScriptAddr_727E ;   target
    dw $FFFF                ; END

Bank0D_ScriptAddr_727E:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF44                ; $44 back_from_return: After the return: face as saved, turn the saved actor to the player and say the saved text + 9
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: 0  [$D951 := 0]
    dw $D951                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1E_Script01
; ---------------------------------------------------------------------------
Map1E_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_72DA
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_72DA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_72D6
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_72D6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0097 is set → Bank0D_ScriptAddr_72D2
    dw $0097                ;   flag
    dw Bank0D_ScriptAddr_72D2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_72CA
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_72CA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_72C6
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_72C6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_72C2
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_72C2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_72BE
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_72BE ;   target
    dw $0119                ; text $0119: "*:Superior masters... *:have a well-bala…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_72BE:
    dw $024E                ; text $024E: "*:When you receive an offer to breed, ta…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_72C2:
    dw $030E                ; text $030E: "*:May I help you [HERO]! I heard a rumor…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_72C6:
    dw $03DB                ; text $03DB: "*:I heard a rumor that a terrible master…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_72CA:
    dw $03FF                ; text $03FF: "*:You must be something to beat May! *:I…"
    dw $FF03                ; $03 set_flag: Set flag $0097
    dw $0097                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_72D2:
    dw $0400                ; text $0400: "*:I heard a rumor that a terrible master…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_72D6:
    dw $0461                ; text $0461: "*:I heard a rumor about an awful master …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_72DA:
    dw $0821                ; text $0821: "*:Once a famous master told me... *:A kn…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1E_Script02
; ---------------------------------------------------------------------------
Map1E_Script02:
    dw $FF00                ; $00 if_flag_clear: If flag $000E is clear → Bank0D_ScriptAddr_7302
    dw $000E                ;   flag
    dw Bank0D_ScriptAddr_7302 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_7320
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_7320 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_731C
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_731C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_7318
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_7318 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0035 is set → Bank0D_ScriptAddr_7314
    dw $0035                ;   flag
    dw Bank0D_ScriptAddr_7314 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_7310
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_7310 ;   target
Bank0D_ScriptAddr_7302:
    dw $FF01                ; $01 if_flag_set: If flag $000E is set → Bank0D_ScriptAddr_730C
    dw $000E                ;   flag
    dw Bank0D_ScriptAddr_730C ;   target
    dw $011A                ; text $011A: "*:Army Bomb Army, Bubble Army...! *:Uuu …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_730C:
    dw $013E                ; text $013E: "*:Uuu Hmm... *:I wonder who'll win this …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7310:
    dw $0881                ; text $0881: "*:IceMan has a relative!! *:It is called…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7314:
    dw $03DC                ; text $03DC: "*:Oops...I lost ...I guess I'll try to g…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7318:
    dw $0401                ; text $0401: "*:I think I'm gonna quit staying up all …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_731C:
    dw $0462                ; text $0462: "*:I think I'll go to bed. But yet.. not …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7320:
    dw $0822                ; text $0822: "*:Uuu.. yawn! Who won? *:Oh, her Majesty…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1E_Script03
; ---------------------------------------------------------------------------
Map1E_Script03:
    dw $FF00                ; $00 if_flag_clear: If flag $0033 is clear → Bank0D_ScriptAddr_7330
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_7330 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0060 is set → Bank0D_ScriptAddr_738A
    dw $0060                ;   flag
    dw Bank0D_ScriptAddr_738A ;   target
Bank0D_ScriptAddr_7330:
    dw $FF01                ; $01 if_flag_set: If flag $0060 is set → Bank0D_ScriptAddr_7386
    dw $0060                ;   flag
    dw Bank0D_ScriptAddr_7386 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $005F is set → Bank0D_ScriptAddr_7368
    dw $005F                ;   flag
    dw Bank0D_ScriptAddr_7368 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_7346
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_7346 ;   target
    dw $011B                ; text $011B: "*:Who the heck is that old woman at the …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7346:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $024F                ; text $024F: "*:Hic, yo brother. Wanna have a breed wi…"
    dw $FF03                ; $03 set_flag: Set flag $005F
    dw $005F                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0060
    dw $0060                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 306); remember this room and Terry's spot for the ceremony's way back
    dw $0132                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Tut, stingy. Hic...”)
    dw $0005                ;   kind
    dw $0610                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0060
    dw $0060                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0610                ; text $0610: "*:Tut, stingy. Hic..."
    dw $FFFF                ; END

Bank0D_ScriptAddr_7368:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $025A                ; text $025A: "*:Want to match with my CatFly?"
    dw $FF03                ; $03 set_flag: Set flag $0060
    dw $0060                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 306); remember this room and Terry's spot for the ceremony's way back
    dw $0132                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Tut, stingy. Hic...”)
    dw $0005                ;   kind
    dw $0610                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0060
    dw $0060                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0610                ; text $0610: "*:Tut, stingy. Hic..."
    dw $FFFF                ; END

Bank0D_ScriptAddr_7386:
    dw $025B                ; text $025B: "*:You are aiming for D class now? Watch …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_738A:
    dw $028B                ; text $028B: "*:How did you beat Mick! I'm glad you br…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1E_Script04
; ---------------------------------------------------------------------------
Map1E_Script04:
    dw $FF00                ; $00 if_flag_clear: If flag $0094 is clear → Bank0D_ScriptAddr_739A
    dw $0094                ;   flag
    dw Bank0D_ScriptAddr_739A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_7468
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_7468 ;   target
Bank0D_ScriptAddr_739A:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_7464
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_7464 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0D_ScriptAddr_7460
    dw $0025                ;   flag
    dw Bank0D_ScriptAddr_7460 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $011D is set → Bank0D_ScriptAddr_745C
    dw $011D                ;   flag
    dw Bank0D_ScriptAddr_745C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $011C is set → Bank0D_ScriptAddr_7454
    dw $011C                ;   flag
    dw Bank0D_ScriptAddr_7454 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0037 is clear → Bank0D_ScriptAddr_73BE
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_73BE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0098 is set → Bank0D_ScriptAddr_7450
    dw $0098                ;   flag
    dw Bank0D_ScriptAddr_7450 ;   target
Bank0D_ScriptAddr_73BE:
    dw $FF01                ; $01 if_flag_set: If flag $0098 is set → Bank0D_ScriptAddr_744C
    dw $0098                ;   flag
    dw Bank0D_ScriptAddr_744C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0036 is set → Bank0D_ScriptAddr_742A
    dw $0036                ;   flag
    dw Bank0D_ScriptAddr_742A ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0085 is clear → Bank0D_ScriptAddr_73D6
    dw $0085                ;   flag
    dw Bank0D_ScriptAddr_73D6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0094 is set → Bank0D_ScriptAddr_7426
    dw $0094                ;   flag
    dw Bank0D_ScriptAddr_7426 ;   target
Bank0D_ScriptAddr_73D6:
    dw $FF01                ; $01 if_flag_set: If flag $0085 is set → Bank0D_ScriptAddr_7422
    dw $0085                ;   flag
    dw Bank0D_ScriptAddr_7422 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0084 is set → Bank0D_ScriptAddr_7404
    dw $0084                ;   flag
    dw Bank0D_ScriptAddr_7404 ;   target
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0310                ; text $0310: "*:How do you do? My name is May. It's ni…"
    dw $FF03                ; $03 set_flag: Set flag $0084
    dw $0084                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0085
    dw $0085                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 309); remember this room and Terry's spot for the ceremony's way back
    dw $0135                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Please come to me when you want to bre…”)
    dw $0005                ;   kind
    dw $0640                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0085
    dw $0085                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0640                ; text $0640: "*:Please come to me when you want to bre…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7404:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $031B                ; text $031B: "*:What do you say? Why don't you breed w…"
    dw $FF03                ; $03 set_flag: Set flag $0085
    dw $0085                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 309); remember this room and Terry's spot for the ceremony's way back
    dw $0135                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Please come to me when you want to bre…”)
    dw $0005                ;   kind
    dw $0640                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0085
    dw $0085                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0640                ; text $0640: "*:Please come to me when you want to bre…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7422:
    dw $031C                ; text $031C: "*:I'm trying to pick up all the items I …"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7426:
    dw $02A8                ; text $02A8: "*:Soon you will become powerful! *:Durin…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_742A:
    dw $0402                ; text $0402: "*:You defeated me. I didn't even have a …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7444  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7444 ;   target
    dw $FF28                ; $28 if_storage_full: Go to target when all 20 monster slots are taken → Bank0D_ScriptAddr_7448
    dw Bank0D_ScriptAddr_7448 ;   target
    dw $0403                ; text $0403: "*:I'll send my StoneMan to the farm then…"
    dw $FF29                ; $29 add_monster: Add monster: enemy row 314
    dw $013A                ;   enemy
    dw $FF03                ; $03 set_flag: Set flag $0098
    dw $0098                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_7444:
    dw $0405                ; text $0405: "*:...fine. If you change your mind, let …"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7448:
    dw $0404                ; text $0404: "*:Well, I thought to... but... you have …"
    dw $FFFF                ; END
Bank0D_ScriptAddr_744C:
    dw $0406                ; text $0406: "*:My StoneMan can use Ahhh! *:Boy monste…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7450:
    dw $0463                ; text $0463: "*:[HERO]. Let me tell you. *:When you pu…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7454:
    dw $0859                ; text $0859: "*:.... You won S class! *:I've never fou…"
    dw $FF03                ; $03 set_flag: Set flag $011D
    dw $011D                ;   flag
    dw $FFFF                ; END

Bank0D_ScriptAddr_745C:
    dw $085A                ; text $085A: "*:I've never fought with you but it mean…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7460:
    dw $04DD                ; text $04DD: "*:[HERO], lemme tell you. *:I heard a te…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7464:
    dw $0823                ; text $0823: "*:The rumor of the dreadful master was a…"
    dw $FFFF                ; END

Bank0D_ScriptAddr_7468:
    dw $0824                ; text $0824: "May:Don't you think Divinegon looks like…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map1F Per-Script Table (map_type=$1F, 0 scripts)
; ---------------------------------------------------------------------------
Map1F_ScriptPtrTable:
    dw $7480                ; script 0
    dw $749C                ; script 1
    dw $74AA                ; script 2
    dw $7994                ; script 3
    dw $7A22                ; script 4
    dw $7B10                ; script 5
    dw $7BE4                ; script 6
    dw $7A1E                ; script 7
    dw $7B0C                ; script 8
    dw $7BE0                ; script 9
    dw $FF15                ; $15 check_and_branch: If “the breeding-shrine stage / return code” is back to the Arena Lobby / Restaurant / Queen → Bank0D_ScriptAddr_748A  [$D951 = 242]
    dw $D951                ;   address
    dw $00F2                ;   value
    dw Bank0D_ScriptAddr_748A ;   target
    dw $FFFF                ; END

Bank0D_ScriptAddr_748A:
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF44                ; $44 back_from_return: After the return: face as saved, turn the saved actor to the player and say the saved text + 9
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: 0  [$D951 := 0]
    dw $D951                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_74A6
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_74A6 ;   target
    dw $01F3                ; text $01F3: "[HERO] checked out the stuffed animal. T…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_74A6:
    dw $0002                ; text $0002: "Terry looked at a stuffed animal. Someth…"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $0155 is set → Bank0D_ScriptAddr_7990
    dw $0155                ;   flag
    dw Bank0D_ScriptAddr_7990 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0156 is set → Bank0D_ScriptAddr_7980
    dw $0156                ;   flag
    dw Bank0D_ScriptAddr_7980 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0154 is clear → Bank0D_ScriptAddr_74C2
    dw $0154                ;   flag
    dw Bank0D_ScriptAddr_74C2 ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $2C is in the party → Bank0D_ScriptAddr_7966
    dw $002C                ;   species
    dw Bank0D_ScriptAddr_7966 ;   target
Bank0D_ScriptAddr_74C2:
    dw $FF01                ; $01 if_flag_set: If flag $0152 is set → Bank0D_ScriptAddr_795E
    dw $0152                ;   flag
    dw Bank0D_ScriptAddr_795E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0153 is set → Bank0D_ScriptAddr_794E
    dw $0153                ;   flag
    dw Bank0D_ScriptAddr_794E ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0151 is clear → Bank0D_ScriptAddr_74DA
    dw $0151                ;   flag
    dw Bank0D_ScriptAddr_74DA ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $C7 is in the party → Bank0D_ScriptAddr_7934
    dw $00C7                ;   species
    dw Bank0D_ScriptAddr_7934 ;   target
Bank0D_ScriptAddr_74DA:
    dw $FF01                ; $01 if_flag_set: If flag $014F is set → Bank0D_ScriptAddr_792C
    dw $014F                ;   flag
    dw Bank0D_ScriptAddr_792C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0150 is set → Bank0D_ScriptAddr_791C
    dw $0150                ;   flag
    dw Bank0D_ScriptAddr_791C ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $014E is clear → Bank0D_ScriptAddr_74F2
    dw $014E                ;   flag
    dw Bank0D_ScriptAddr_74F2 ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $6C is in the party → Bank0D_ScriptAddr_7902
    dw $006C                ;   species
    dw Bank0D_ScriptAddr_7902 ;   target
Bank0D_ScriptAddr_74F2:
    dw $FF01                ; $01 if_flag_set: If flag $014C is set → Bank0D_ScriptAddr_78FA
    dw $014C                ;   flag
    dw Bank0D_ScriptAddr_78FA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $014D is set → Bank0D_ScriptAddr_78EA
    dw $014D                ;   flag
    dw Bank0D_ScriptAddr_78EA ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $014B is clear → Bank0D_ScriptAddr_750A
    dw $014B                ;   flag
    dw Bank0D_ScriptAddr_750A ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $80 is in the party → Bank0D_ScriptAddr_78D0
    dw $0080                ;   species
    dw Bank0D_ScriptAddr_78D0 ;   target
Bank0D_ScriptAddr_750A:
    dw $FF01                ; $01 if_flag_set: If flag $0149 is set → Bank0D_ScriptAddr_78C8
    dw $0149                ;   flag
    dw Bank0D_ScriptAddr_78C8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $014A is set → Bank0D_ScriptAddr_78B8
    dw $014A                ;   flag
    dw Bank0D_ScriptAddr_78B8 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0148 is clear → Bank0D_ScriptAddr_7522
    dw $0148                ;   flag
    dw Bank0D_ScriptAddr_7522 ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $59 is in the party → Bank0D_ScriptAddr_789E
    dw $0059                ;   species
    dw Bank0D_ScriptAddr_789E ;   target
Bank0D_ScriptAddr_7522:
    dw $FF01                ; $01 if_flag_set: If flag $0146 is set → Bank0D_ScriptAddr_7896
    dw $0146                ;   flag
    dw Bank0D_ScriptAddr_7896 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0147 is set → Bank0D_ScriptAddr_7886
    dw $0147                ;   flag
    dw Bank0D_ScriptAddr_7886 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0145 is clear → Bank0D_ScriptAddr_753A
    dw $0145                ;   flag
    dw Bank0D_ScriptAddr_753A ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $42 is in the party → Bank0D_ScriptAddr_786C
    dw $0042                ;   species
    dw Bank0D_ScriptAddr_786C ;   target
Bank0D_ScriptAddr_753A:
    dw $FF01                ; $01 if_flag_set: If flag $0143 is set → Bank0D_ScriptAddr_7864
    dw $0143                ;   flag
    dw Bank0D_ScriptAddr_7864 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0144 is set → Bank0D_ScriptAddr_7854
    dw $0144                ;   flag
    dw Bank0D_ScriptAddr_7854 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0142 is clear → Bank0D_ScriptAddr_7552
    dw $0142                ;   flag
    dw Bank0D_ScriptAddr_7552 ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $AA is in the party → Bank0D_ScriptAddr_783A
    dw $00AA                ;   species
    dw Bank0D_ScriptAddr_783A ;   target
Bank0D_ScriptAddr_7552:
    dw $FF01                ; $01 if_flag_set: If flag $0141 is set → Bank0D_ScriptAddr_7832
    dw $0141                ;   flag
    dw Bank0D_ScriptAddr_7832 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $00F1 is clear → Bank0D_ScriptAddr_7564
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_7564 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $013F is set → Bank0D_ScriptAddr_782A
    dw $013F                ;   flag
    dw Bank0D_ScriptAddr_782A ;   target
Bank0D_ScriptAddr_7564:
    dw $FF01                ; $01 if_flag_set: If flag $013F is set → Bank0D_ScriptAddr_7826
    dw $013F                ;   flag
    dw Bank0D_ScriptAddr_7826 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0140 is set → Bank0D_ScriptAddr_7816
    dw $0140                ;   flag
    dw Bank0D_ScriptAddr_7816 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $013E is clear → Bank0D_ScriptAddr_757C
    dw $013E                ;   flag
    dw Bank0D_ScriptAddr_757C ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $55 is in the party → Bank0D_ScriptAddr_77FC
    dw $0055                ;   species
    dw Bank0D_ScriptAddr_77FC ;   target
Bank0D_ScriptAddr_757C:
    dw $FF01                ; $01 if_flag_set: If flag $013C is set → Bank0D_ScriptAddr_77F4
    dw $013C                ;   flag
    dw Bank0D_ScriptAddr_77F4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $013D is set → Bank0D_ScriptAddr_77E4
    dw $013D                ;   flag
    dw Bank0D_ScriptAddr_77E4 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $013B is clear → Bank0D_ScriptAddr_7594
    dw $013B                ;   flag
    dw Bank0D_ScriptAddr_7594 ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $A8 is in the party → Bank0D_ScriptAddr_77CA
    dw $00A8                ;   species
    dw Bank0D_ScriptAddr_77CA ;   target
Bank0D_ScriptAddr_7594:
    dw $FF01                ; $01 if_flag_set: If flag $0139 is set → Bank0D_ScriptAddr_77C2
    dw $0139                ;   flag
    dw Bank0D_ScriptAddr_77C2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $013A is set → Bank0D_ScriptAddr_77B2
    dw $013A                ;   flag
    dw Bank0D_ScriptAddr_77B2 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0138 is clear → Bank0D_ScriptAddr_75AC
    dw $0138                ;   flag
    dw Bank0D_ScriptAddr_75AC ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $7F is in the party → Bank0D_ScriptAddr_7798
    dw $007F                ;   species
    dw Bank0D_ScriptAddr_7798 ;   target
Bank0D_ScriptAddr_75AC:
    dw $FF01                ; $01 if_flag_set: If flag $0136 is set → Bank0D_ScriptAddr_7790
    dw $0136                ;   flag
    dw Bank0D_ScriptAddr_7790 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0137 is set → Bank0D_ScriptAddr_7780
    dw $0137                ;   flag
    dw Bank0D_ScriptAddr_7780 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0135 is clear → Bank0D_ScriptAddr_75C4
    dw $0135                ;   flag
    dw Bank0D_ScriptAddr_75C4 ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $40 is in the party → Bank0D_ScriptAddr_7766
    dw $0040                ;   species
    dw Bank0D_ScriptAddr_7766 ;   target
Bank0D_ScriptAddr_75C4:
    dw $FF01                ; $01 if_flag_set: If flag $0133 is set → Bank0D_ScriptAddr_775E
    dw $0133                ;   flag
    dw Bank0D_ScriptAddr_775E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0134 is set → Bank0D_ScriptAddr_774E
    dw $0134                ;   flag
    dw Bank0D_ScriptAddr_774E ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0132 is clear → Bank0D_ScriptAddr_75DC
    dw $0132                ;   flag
    dw Bank0D_ScriptAddr_75DC ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $10 is in the party → Bank0D_ScriptAddr_7734
    dw $0010                ;   species
    dw Bank0D_ScriptAddr_7734 ;   target
Bank0D_ScriptAddr_75DC:
    dw $FF00                ; $00 if_flag_clear: If flag $001D is clear → Bank0D_ScriptAddr_75E8
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_75E8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0130 is set → Bank0D_ScriptAddr_772C
    dw $0130                ;   flag
    dw Bank0D_ScriptAddr_772C ;   target
Bank0D_ScriptAddr_75E8:
    dw $FF01                ; $01 if_flag_set: If flag $0130 is set → Bank0D_ScriptAddr_7728
    dw $0130                ;   flag
    dw Bank0D_ScriptAddr_7728 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0131 is set → Bank0D_ScriptAddr_7718
    dw $0131                ;   flag
    dw Bank0D_ScriptAddr_7718 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $012F is clear → Bank0D_ScriptAddr_7600
    dw $012F                ;   flag
    dw Bank0D_ScriptAddr_7600 ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $BC is in the party → Bank0D_ScriptAddr_76FE
    dw $00BC                ;   species
    dw Bank0D_ScriptAddr_76FE ;   target
Bank0D_ScriptAddr_7600:
    dw $FF01                ; $01 if_flag_set: If flag $012D is set → Bank0D_ScriptAddr_76F6
    dw $012D                ;   flag
    dw Bank0D_ScriptAddr_76F6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $012E is set → Bank0D_ScriptAddr_76E6
    dw $012E                ;   flag
    dw Bank0D_ScriptAddr_76E6 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $012C is clear → Bank0D_ScriptAddr_7618
    dw $012C                ;   flag
    dw Bank0D_ScriptAddr_7618 ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $49 is in the party → Bank0D_ScriptAddr_76CC
    dw $0049                ;   species
    dw Bank0D_ScriptAddr_76CC ;   target
Bank0D_ScriptAddr_7618:
    dw $FF01                ; $01 if_flag_set: If flag $012A is set → Bank0D_ScriptAddr_76C4
    dw $012A                ;   flag
    dw Bank0D_ScriptAddr_76C4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $012B is set → Bank0D_ScriptAddr_76B4
    dw $012B                ;   flag
    dw Bank0D_ScriptAddr_76B4 ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0129 is clear → Bank0D_ScriptAddr_7630
    dw $0129                ;   flag
    dw Bank0D_ScriptAddr_7630 ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $0F is in the party → Bank0D_ScriptAddr_769A
    dw $000F                ;   species
    dw Bank0D_ScriptAddr_769A ;   target
Bank0D_ScriptAddr_7630:
    dw $FF01                ; $01 if_flag_set: If flag $0127 is set → Bank0D_ScriptAddr_7692
    dw $0127                ;   flag
    dw Bank0D_ScriptAddr_7692 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0128 is set → Bank0D_ScriptAddr_767E
    dw $0128                ;   flag
    dw Bank0D_ScriptAddr_767E ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0126 is clear → Bank0D_ScriptAddr_7648
    dw $0126                ;   flag
    dw Bank0D_ScriptAddr_7648 ;   target
    dw $FF40                ; $40 if_party_has_species: If a species $02 is in the party → Bank0D_ScriptAddr_7664
    dw $0002                ;   species
    dw Bank0D_ScriptAddr_7664 ;   target
Bank0D_ScriptAddr_7648:
    dw $FF00                ; $00 if_flag_clear: If flag $0045 is clear → Bank0D_ScriptAddr_7654
    dw $0045                ;   flag
    dw Bank0D_ScriptAddr_7654 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_765C
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_765C ;   target
Bank0D_ScriptAddr_7654:
    dw $011C                ; text $011C: "*:I am the Queen of GreatTree. I like to…"
    dw $FF03                ; $03 set_flag: Set flag $0061
    dw $0061                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_765C:
    dw $0350                ; text $0350: "*:I am the Queen of GreatTree. *:Will yo…"
    dw $FF03                ; $03 set_flag: Set flag $0126
    dw $0126                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7664:
    dw $0359                ; text $0359: "*:Oh, that's a WingSlime! Cute! *:For br…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_7676
    dw Bank0D_ScriptAddr_7676 ;   target
    dw $035B                ; text $035B: "*:It is a Sirloin. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0127
    dw $0127                ;   flag
    dw $FF2A                ; $2A give_item: Give item 23
    dw $0017                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7676:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $0128
    dw $0128                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_767E:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $035B                ; text $035B: "*:It is a Sirloin. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0127
    dw $0127                ;   flag
    dw $FF2A                ; $2A give_item: Give item 23
    dw $0017                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_768E:
    dw $08C5                ; text $08C5: "*:I'd like to give you a reward, but you…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7692:
    dw $035C                ; text $035C: "*:You, comply with my next wish. *:I wan…"
    dw $FF03                ; $03 set_flag: Set flag $0129
    dw $0129                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_769A:
    dw $03AC                ; text $03AC: "*:Amazing! It's a KingSlime! *:Well done…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_76AC
    dw Bank0D_ScriptAddr_76AC ;   target
    dw $03AD                ; text $03AD: "*:It's an INTseed. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $012A
    dw $012A                ;   flag
    dw $FF2A                ; $2A give_item: Give item 18
    dw $0012                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_76AC:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $012B
    dw $012B                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_76B4:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $03AD                ; text $03AD: "*:It's an INTseed. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $012A
    dw $012A                ;   flag
    dw $FF2A                ; $2A give_item: Give item 18
    dw $0012                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_76C4:
    dw $03D8                ; text $03D8: "*:You, must obey my command. *:I want to…"
    dw $FF03                ; $03 set_flag: Set flag $012C
    dw $012C                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_76CC:
    dw $03D9                ; text $03D9: "*:Oh! It's a FloraJay! What a funny face…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_76DE
    dw Bank0D_ScriptAddr_76DE ;   target
    dw $03DA                ; text $03DA: "*:This is an AGLseed. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $012D
    dw $012D                ;   flag
    dw $FF2A                ; $2A give_item: Give item 17
    dw $0011                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_76DE:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $012E
    dw $012E                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_76E6:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $03DA                ; text $03DA: "*:This is an AGLseed. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $012D
    dw $012D                ;   flag
    dw $FF2A                ; $2A give_item: Give item 17
    dw $0011                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_76F6:
    dw $03F8                ; text $03F8: "*:You, listen to my request. *:I want to…"
    dw $FF03                ; $03 set_flag: Set flag $012F
    dw $012F                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_76FE:
    dw $034A                ; text $034A: "*:Oh! It's a CurseLamp! Nasty! *:Well do…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_7710
    dw Bank0D_ScriptAddr_7710 ;   target
    dw $034B                ; text $034B: "This is a DEFseed. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0130
    dw $0130                ;   flag
    dw $FF2A                ; $2A give_item: Give item 16
    dw $0010                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7710:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $0131
    dw $0131                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7718:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $034B                ; text $034B: "This is a DEFseed. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0130
    dw $0130                ;   flag
    dw $FF2A                ; $2A give_item: Give item 16
    dw $0010                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7728:
    dw $034C                ; text $034C: "*:I'm satisfied. Come back when you get …"
    dw $FFFF                ; END
Bank0D_ScriptAddr_772C:
    dw $031D                ; text $031D: "*:You, must comply with my next wish. *I…"
    dw $FF03                ; $03 set_flag: Set flag $0132
    dw $0132                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7734:
    dw $034D                ; text $034D: "*:Oh! That's Metaly! How shiny! *:Well d…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_7746
    dw Bank0D_ScriptAddr_7746 ;   target
    dw $0407                ; text $0407: "*:It's a LifeAcorn. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0133
    dw $0133                ;   flag
    dw $FF2A                ; $2A give_item: Give item 13
    dw $000D                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7746:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $0134
    dw $0134                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_774E:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $0407                ; text $0407: "*:It's a LifeAcorn. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0133
    dw $0133                ;   flag
    dw $FF2A                ; $2A give_item: Give item 13
    dw $000D                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_775E:
    dw $0452                ; text $0452: "*:You, obey my command. *:I want to see …"
    dw $FF03                ; $03 set_flag: Set flag $0135
    dw $0135                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7766:
    dw $0460                ; text $0460: "*:Oh! It's a WildApe! The monkey looks s…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_7778
    dw Bank0D_ScriptAddr_7778 ;   target
    dw $0464                ; text $0464: "*:This is a ATKseed. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0136
    dw $0136                ;   flag
    dw $FF2A                ; $2A give_item: Give item 15
    dw $000F                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7778:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $0137
    dw $0137                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7780:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $0464                ; text $0464: "*:This is a ATKseed. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0136
    dw $0136                ;   flag
    dw $FF2A                ; $2A give_item: Give item 15
    dw $000F                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7790:
    dw $0465                ; text $0465: "*:Obey my command. *:Bring me HornBeet f…"
    dw $FF03                ; $03 set_flag: Set flag $0138
    dw $0138                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7798:
    dw $04B6                ; text $04B6: "*:Oh! Its a HornBeet! What a magnificent…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_77AA
    dw Bank0D_ScriptAddr_77AA ;   target
    dw $04BA                ; text $04BA: "*:Here is MysticNut. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0139
    dw $0139                ;   flag
    dw $FF2A                ; $2A give_item: Give item 14
    dw $000E                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_77AA:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $013A
    dw $013A                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_77B2:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $04BA                ; text $04BA: "*:Here is MysticNut. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0139
    dw $0139                ;   flag
    dw $FF2A                ; $2A give_item: Give item 14
    dw $000E                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_77C2:
    dw $04DB                ; text $04DB: "*:You must listen to my request! *:Bring…"
    dw $FF03                ; $03 set_flag: Set flag $013B
    dw $013B                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_77CA:
    dw $04DC                ; text $04DC: "*:Oh, it is a Reaper! What a sharp scyth…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_77DC
    dw Bank0D_ScriptAddr_77DC ;   target
    dw $07E8                ; text $07E8: "*:It's a HorrorBK. Take good care of it."
    dw $FF03                ; $03 set_flag: Set flag $013C
    dw $013C                ;   flag
    dw $FF2A                ; $2A give_item: Give item 32
    dw $0020                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_77DC:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $013D
    dw $013D                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_77E4:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $07E8                ; text $07E8: "*:It's a HorrorBK. Take good care of it."
    dw $FF03                ; $03 set_flag: Set flag $013C
    dw $013C                ;   flag
    dw $FF2A                ; $2A give_item: Give item 32
    dw $0020                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_77F4:
    dw $07E9                ; text $07E9: "*:You, must obey! *:Bring me a Phoenix! …"
    dw $FF03                ; $03 set_flag: Set flag $013E
    dw $013E                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_77FC:
    dw $081B                ; text $081B: "*:Oh, it's a Phoenix! It looks like a Bl…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_780E
    dw Bank0D_ScriptAddr_780E ;   target
    dw $081C                ; text $081C: "*:Here's CheaterBK. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $013F
    dw $013F                ;   flag
    dw $FF2A                ; $2A give_item: Give item 34
    dw $0022                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_780E:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $0140
    dw $0140                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7816:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $081C                ; text $081C: "*:Here's CheaterBK. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $013F
    dw $013F                ;   flag
    dw $FF2A                ; $2A give_item: Give item 34
    dw $0022                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7826:
    dw $081D                ; text $081D: "*:I'm satisfied. [HERO], win a victory!"
    dw $FFFF                ; END
Bank0D_ScriptAddr_782A:
    dw $0825                ; text $0825: "*:Your big sister Milayou is here. *:Suc…"
    dw $FF03                ; $03 set_flag: Set flag $0141
    dw $0141                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7832:
    dw $081E                ; text $081E: "*:I have to go back to the castle... *:.…"
    dw $FF03                ; $03 set_flag: Set flag $0142
    dw $0142                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_783A:
    dw $081F                ; text $081F: "*:Oh! It's the A WhiteKing! How sad... *…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_784C
    dw Bank0D_ScriptAddr_784C ;   target
    dw $0820                ; text $0820: "*:Here's ComedyBK. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0143
    dw $0143                ;   flag
    dw $FF2A                ; $2A give_item: Give item 36
    dw $0024                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_784C:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $0144
    dw $0144                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7854:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $0820                ; text $0820: "*:Here's ComedyBK. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0143
    dw $0143                ;   flag
    dw $FF2A                ; $2A give_item: Give item 36
    dw $0024                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7864:
    dw $08A7                ; text $08A7: "*:You, must obey me. *:I want to see a K…"
    dw $FF03                ; $03 set_flag: Set flag $0145
    dw $0145                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_786C:
    dw $08A8                ; text $08A8: "*:Oh, It is KingLeo! How majestic! *:Wel…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_787E
    dw Bank0D_ScriptAddr_787E ;   target
    dw $08A9                ; text $08A9: "*:It's a SmartBk Use it wisely!"
    dw $FF03                ; $03 set_flag: Set flag $0146
    dw $0146                ;   flag
    dw $FF2A                ; $2A give_item: Give item 35
    dw $0023                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_787E:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $0147
    dw $0147                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7886:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $08A9                ; text $08A9: "*:It's a SmartBk Use it wisely!"
    dw $FF03                ; $03 set_flag: Set flag $0146
    dw $0146                ;   flag
    dw $FF2A                ; $2A give_item: Give item 35
    dw $0023                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7896:
    dw $08AA                ; text $08AA: "*:You, must obey me! *:Bring me a RainHa…"
    dw $FF03                ; $03 set_flag: Set flag $0148
    dw $0148                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_789E:
    dw $08AB                ; text $08AB: "*:Oh, It is RainHawk! What beautiful win…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_78B0
    dw Bank0D_ScriptAddr_78B0 ;   target
    dw $08AC                ; text $08AC: "*:It's a BeNiceBK. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0149
    dw $0149                ;   flag
    dw $FF2A                ; $2A give_item: Give item 33
    dw $0021                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_78B0:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $014A
    dw $014A                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_78B8:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $08AC                ; text $08AC: "*:It's a BeNiceBK. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0149
    dw $0149                ;   flag
    dw $FF2A                ; $2A give_item: Give item 33
    dw $0021                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_78C8:
    dw $08AD                ; text $08AD: "*:You must obey me! *:I want to see an A…"
    dw $FF03                ; $03 set_flag: Set flag $014B
    dw $014B                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_78D0:
    dw $08AE                ; text $08AE: "*:Oh! it is Armorpion! What a scary look…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_78E2
    dw Bank0D_ScriptAddr_78E2 ;   target
    dw $08AF                ; text $08AF: "*:It is QuestBK. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $014C
    dw $014C                ;   flag
    dw $FF2A                ; $2A give_item: Give item 31
    dw $001F                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_78E2:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $014D
    dw $014D                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_78EA:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $08AF                ; text $08AF: "*:It is QuestBK. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $014C
    dw $014C                ;   flag
    dw $FF2A                ; $2A give_item: Give item 31
    dw $001F                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_78FA:
    dw $08B0                ; text $08B0: "*:You must obey me. *:I want to see a Ro…"
    dw $FF03                ; $03 set_flag: Set flag $014E
    dw $014E                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7902:
    dw $08B1                ; text $08B1: "*:It's a Rosevine! How snaky it is! *:We…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_7914
    dw Bank0D_ScriptAddr_7914 ;   target
    dw $08B2                ; text $08B2: "It's a LifeAcorn. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $014F
    dw $014F                ;   flag
    dw $FF2A                ; $2A give_item: Give item 13
    dw $000D                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7914:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $0150
    dw $0150                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_791C:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $08B2                ; text $08B2: "It's a LifeAcorn. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $014F
    dw $014F                ;   flag
    dw $FF2A                ; $2A give_item: Give item 13
    dw $000D                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_792C:
    dw $08B3                ; text $08B3: "*:You must obey me. *:I want to see a Go…"
    dw $FF03                ; $03 set_flag: Set flag $0151
    dw $0151                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7934:
    dw $08B4                ; text $08B4: "*:It's GoldGolem! I could be blinded by …"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_7946
    dw Bank0D_ScriptAddr_7946 ;   target
    dw $08B5                ; text $08B5: "*:It's a TinyMedal. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0152
    dw $0152                ;   flag
    dw $FF2A                ; $2A give_item: Give item 30
    dw $001E                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7946:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $0153
    dw $0153                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_794E:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $08B5                ; text $08B5: "*:It's a TinyMedal. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0152
    dw $0152                ;   flag
    dw $FF2A                ; $2A give_item: Give item 30
    dw $001E                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_795E:
    dw $08B6                ; text $08B6: "*:You must obey me. *:I want to see a Di…"
    dw $FF03                ; $03 set_flag: Set flag $0154
    dw $0154                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7966:
    dw $08B7                ; text $08B7: "*:It's Divinegon! How noble! *:Well done…"
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_7978
    dw Bank0D_ScriptAddr_7978 ;   target
    dw $08B8                ; text $08B8: "*:It's a TinyMedal. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0155
    dw $0155                ;   flag
    dw $FF2A                ; $2A give_item: Give item 30
    dw $001E                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7978:
    dw $035A                ; text $035A: "*:...but you don't have any more room to…"
    dw $FF03                ; $03 set_flag: Set flag $0156
    dw $0156                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7980:
    dw $FF2C                ; $2C check_inv_full: Go to target when the bag (20) is full → Bank0D_ScriptAddr_768E
    dw Bank0D_ScriptAddr_768E ;   target
    dw $08B8                ; text $08B8: "*:It's a TinyMedal. Use it wisely."
    dw $FF03                ; $03 set_flag: Set flag $0155
    dw $0155                ;   flag
    dw $FF2A                ; $2A give_item: Give item 30
    dw $001E                ;   item
    dw $FFFF                ; END
Bank0D_ScriptAddr_7990:
    dw $08B9                ; text $08B9: "*:[HERO], my hearts content. *:There's n…"
    dw $FFFF                ; END
    dw $FF01                ; $01 if_flag_set: If flag $0157 is set → Bank0D_ScriptAddr_7A1A
    dw $0157                ;   flag
    dw Bank0D_ScriptAddr_7A1A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0D_ScriptAddr_7A12
    dw $00F1                ;   flag
    dw Bank0D_ScriptAddr_7A12 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $013F is set → Bank0D_ScriptAddr_7A0E
    dw $013F                ;   flag
    dw Bank0D_ScriptAddr_7A0E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $013C is set → Bank0D_ScriptAddr_7A0A
    dw $013C                ;   flag
    dw Bank0D_ScriptAddr_7A0A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0139 is set → Bank0D_ScriptAddr_7A06
    dw $0139                ;   flag
    dw Bank0D_ScriptAddr_7A06 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0136 is set → Bank0D_ScriptAddr_7A02
    dw $0136                ;   flag
    dw Bank0D_ScriptAddr_7A02 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0133 is set → Bank0D_ScriptAddr_79FE
    dw $0133                ;   flag
    dw Bank0D_ScriptAddr_79FE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0D_ScriptAddr_79FA
    dw $001D                ;   flag
    dw Bank0D_ScriptAddr_79FA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $012D is set → Bank0D_ScriptAddr_79F6
    dw $012D                ;   flag
    dw Bank0D_ScriptAddr_79F6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $012A is set → Bank0D_ScriptAddr_79F2
    dw $012A                ;   flag
    dw Bank0D_ScriptAddr_79F2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0127 is set → Bank0D_ScriptAddr_79EE
    dw $0127                ;   flag
    dw Bank0D_ScriptAddr_79EE ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0045 is clear → Bank0D_ScriptAddr_79E2
    dw $0045                ;   flag
    dw Bank0D_ScriptAddr_79E2 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_79EA
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_79EA ;   target
Bank0D_ScriptAddr_79E2:
    dw $011D                ; text $011D: "*:Here is her majesty the Queen of Great…"
    dw $FF03                ; $03 set_flag: Set flag $0062
    dw $0062                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_79EA:
    dw $08BA                ; text $08BA: "*:Her Majesty, the Queen of GreatTree, *…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_79EE:
    dw $08BB                ; text $08BB: "*:Her Majesty desires a KingSlime. *:I h…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_79F2:
    dw $08BC                ; text $08BC: "*:Her Majesty desires a Florajay. *:I he…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_79F6:
    dw $08BD                ; text $08BD: "*:Her Majesty desires a CurseLamp. *:I h…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_79FA:
    dw $031E                ; text $031E: "*:Here's the Queen of GreatTree. *:And h…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_79FE:
    dw $08BF                ; text $08BF: "*:Her Majesty desires WildApe. *:I wonde…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7A02:
    dw $08C0                ; text $08C0: "*:Her Majesty desires a HornBeet. *:I he…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7A06:
    dw $08C1                ; text $08C1: "*:Her Majesty desires a Reaper. *:I hear…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7A0A:
    dw $08C2                ; text $08C2: "*:Her Majesty desires a Phoenix. *:I hea…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7A0E:
    dw $08C3                ; text $08C3: "*:Her Majesty, the Queen of GreatTree. *…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7A12:
    dw $0826                ; text $0826: "*:Here's her Majesty, the Queen of Great…"
    dw $FF03                ; $03 set_flag: Set flag $0157
    dw $0157                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7A1A:
    dw $084E                ; text $084E: "*:Since the Starry Night, the Queen has …"
    dw $FFFF                ; END
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF01                ; $01 if_flag_set: If flag $006E is set → Bank0D_ScriptAddr_7B08
    dw $006E                ;   flag
    dw Bank0D_ScriptAddr_7B08 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $006D is set → Bank0D_ScriptAddr_7AEA
    dw $006D                ;   flag
    dw Bank0D_ScriptAddr_7AEA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0033 is set → Bank0D_ScriptAddr_7AC8
    dw $0033                ;   flag
    dw Bank0D_ScriptAddr_7AC8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0067 is set → Bank0D_ScriptAddr_7AC4
    dw $0067                ;   flag
    dw Bank0D_ScriptAddr_7AC4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0066 is set → Bank0D_ScriptAddr_7AA6
    dw $0066                ;   flag
    dw Bank0D_ScriptAddr_7AA6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0065 is set → Bank0D_ScriptAddr_7A84
    dw $0065                ;   flag
    dw Bank0D_ScriptAddr_7A84 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0064 is set → Bank0D_ScriptAddr_7A7C
    dw $0064                ;   flag
    dw Bank0D_ScriptAddr_7A7C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0063 is set → Bank0D_ScriptAddr_7A74
    dw $0063                ;   flag
    dw Bank0D_ScriptAddr_7A74 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0032 is set → Bank0D_ScriptAddr_7A6C
    dw $0032                ;   flag
    dw Bank0D_ScriptAddr_7A6C ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $0045 is clear → Bank0D_ScriptAddr_7A64
    dw $0045                ;   flag
    dw Bank0D_ScriptAddr_7A64 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0031 is set → Bank0D_ScriptAddr_7A68
    dw $0031                ;   flag
    dw Bank0D_ScriptAddr_7A68 ;   target
Bank0D_ScriptAddr_7A64:
    dw $011E                ; text $011E: "*:I'm Mick. Who are you? *:Whew, those c…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7A68:
    dw $08BE                ; text $08BE: "*:I'm Mick. Those clingy fans are annoyi…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7A6C:
    dw $025E                ; text $025E: "*:I'm Mick. It's hard to deal with all m…"
    dw $FF03                ; $03 set_flag: Set flag $0063
    dw $0063                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7A74:
    dw $025F                ; text $025F: "*:The Queen gave me a personal invitatio…"
    dw $FF03                ; $03 set_flag: Set flag $0064
    dw $0064                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7A7C:
    dw $0260                ; text $0260: "*:If you become famous, you'll be invite…"
    dw $FF03                ; $03 set_flag: Set flag $0065
    dw $0065                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7A84:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0261                ; text $0261: "*:Why are you bugging me so much? *:I'll…"
    dw $FF03                ; $03 set_flag: Set flag $0066
    dw $0066                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0067
    dw $0067                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 305); remember this room and Terry's spot for the ceremony's way back
    dw $0131                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Well, if you want to breed again, stop…”)
    dw $0005                ;   kind
    dw $0620                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0067
    dw $0067                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0620                ; text $0620: "*:Well, if you want to breed again, stop…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7AA6:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $026C                ; text $026C: "You want to breed with my LizardMan?"
    dw $FF03                ; $03 set_flag: Set flag $0067
    dw $0067                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 305); remember this room and Terry's spot for the ceremony's way back
    dw $0131                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Well, if you want to breed again, stop…”)
    dw $0005                ;   kind
    dw $0620                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0067
    dw $0067                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0620                ; text $0620: "*:Well, if you want to breed again, stop…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7AC4:
    dw $026D                ; text $026D: "*:Breeding with monsters of another mast…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7AC8:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $028F                ; text $028F: "Mick:I should simply accept my defeat...…"
    dw $FF03                ; $03 set_flag: Set flag $006D
    dw $006D                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $006E
    dw $006E                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 307); remember this room and Terry's spot for the ceremony's way back
    dw $0133                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “Mick:I'll be on my journey by the time y…”)
    dw $0005                ;   kind
    dw $0630                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $006E
    dw $006E                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0630                ; text $0630: "Mick:I'll be on my journey by the time y…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7AEA:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $029A                ; text $029A: "Mick:As proof of my friendship let's bre…"
    dw $FF03                ; $03 set_flag: Set flag $006E
    dw $006E                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 307); remember this room and Terry's spot for the ceremony's way back
    dw $0133                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “Mick:I'll be on my journey by the time y…”)
    dw $0005                ;   kind
    dw $0630                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $006E
    dw $006E                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0630                ; text $0630: "Mick:I'll be on my journey by the time y…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7B08:
    dw $029B                ; text $029B: "Mick:I'm going on a journey now. Mick:[H…"
    dw $FFFF                ; END
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF01                ; $01 if_flag_set: If flag $00A8 is set → Bank0D_ScriptAddr_7BDC
    dw $00A8                ;   flag
    dw Bank0D_ScriptAddr_7BDC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00A7 is set → Bank0D_ScriptAddr_7BD4
    dw $00A7                ;   flag
    dw Bank0D_ScriptAddr_7BD4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00A6 is set → Bank0D_ScriptAddr_7BB6
    dw $00A6                ;   flag
    dw Bank0D_ScriptAddr_7BB6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0037 is set → Bank0D_ScriptAddr_7B94
    dw $0037                ;   flag
    dw Bank0D_ScriptAddr_7B94 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0088 is set → Bank0D_ScriptAddr_7B90
    dw $0088                ;   flag
    dw Bank0D_ScriptAddr_7B90 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0087 is set → Bank0D_ScriptAddr_7B88
    dw $0087                ;   flag
    dw Bank0D_ScriptAddr_7B88 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0086 is set → Bank0D_ScriptAddr_7B6A
    dw $0086                ;   flag
    dw Bank0D_ScriptAddr_7B6A ;   target
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $031F                ; text $031F: "*:I'm Medal Man, just a passer-by. *:I g…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0D_ScriptAddr_7B66  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0D_ScriptAddr_7B66 ;   target
    dw $0321                ; text $0321: "*:Oh! You believe me! As I promised, you…"
    dw $FF03                ; $03 set_flag: Set flag $0086
    dw $0086                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0087
    dw $0087                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 311); remember this room and Terry's spot for the ceremony's way back
    dw $0137                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Pay me a visit when you want to breed.”)
    dw $0005                ;   kind
    dw $0650                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0087
    dw $0087                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0650                ; text $0650: "*:Pay me a visit when you want to breed."
    dw $FFFF                ; END
Bank0D_ScriptAddr_7B66:
    dw $0320                ; text $0320: "*:Being a master requires trust!"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7B6A:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $084D                ; text $084D: "*:Why don't you breed with my FangSlime?"
    dw $FF03                ; $03 set_flag: Set flag $0087
    dw $0087                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 311); remember this room and Terry's spot for the ceremony's way back
    dw $0137                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Pay me a visit when you want to breed.”)
    dw $0005                ;   kind
    dw $0650                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $0087
    dw $0087                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0650                ; text $0650: "*:Pay me a visit when you want to breed."
    dw $FFFF                ; END
Bank0D_ScriptAddr_7B88:
    dw $032C                ; text $032C: "*:Because you trusted me, I'll give you …"
    dw $FF03                ; $03 set_flag: Set flag $0088
    dw $0088                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7B90:
    dw $032D                ; text $032D: "*:Metaly is a precious monster. *:Go dow…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7B94:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0466                ; text $0466: "*:You're amazing! I didn't know you were…"
    dw $FF03                ; $03 set_flag: Set flag $00A6
    dw $00A6                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $00A7
    dw $00A7                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 315); remember this room and Terry's spot for the ceremony's way back
    dw $013B                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Pay me a visit when you want to breed.”)
    dw $0005                ;   kind
    dw $0650                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $00A7
    dw $00A7                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0650                ; text $0650: "*:Pay me a visit when you want to breed."
    dw $FFFF                ; END
Bank0D_ScriptAddr_7BB6:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0856                ; text $0856: "*:You want to breed with my Metaly?"
    dw $FF03                ; $03 set_flag: Set flag $00A7
    dw $00A7                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 315); remember this room and Terry's spot for the ceremony's way back
    dw $013B                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “*:Pay me a visit when you want to breed.”)
    dw $0005                ;   kind
    dw $0650                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $00A7
    dw $00A7                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0650                ; text $0650: "*:Pay me a visit when you want to breed."
    dw $FFFF                ; END
Bank0D_ScriptAddr_7BD4:
    dw $0468                ; text $0468: "*:For your victory, let me tell you some…"
    dw $FF03                ; $03 set_flag: Set flag $00A8
    dw $00A8                ;   flag
    dw $FFFF                ; END
Bank0D_ScriptAddr_7BDC:
    dw $0469                ; text $0469: "*:I can't say it loud but... *:When you …"
    dw $FFFF                ; END
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF01                ; $01 if_flag_set: If flag $0155 is set → Bank0D_ScriptAddr_7C3A
    dw $0155                ;   flag
    dw Bank0D_ScriptAddr_7C3A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $010F is set → Bank0D_ScriptAddr_7C36
    dw $010F                ;   flag
    dw Bank0D_ScriptAddr_7C36 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $010E is set → Bank0D_ScriptAddr_7C18
    dw $010E                ;   flag
    dw Bank0D_ScriptAddr_7C18 ;   target
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0827                ; text $0827: "Milayou:Terry, how are you? The Queen sa…"
    dw $FF03                ; $03 set_flag: Set flag $010E
    dw $010E                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $010F
    dw $010F                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 316); remember this room and Terry's spot for the ceremony's way back
    dw $013C                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “Milayou:Come back when you wanna breed.”)
    dw $0005                ;   kind
    dw $0660                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $010F
    dw $010F                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0660                ; text $0660: "Milayou:Come back when you wanna breed."
    dw $FFFF                ; END
Bank0D_ScriptAddr_7C18:
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0828                ; text $0828: "Milayou:Let's breed my Skeletor!"
    dw $FF03                ; $03 set_flag: Set flag $010F
    dw $010F                ;   flag
    dw $FF42                ; $42 save_return_point: NPC 3 offers its monster for breeding (enemy row 316); remember this room and Terry's spot for the ceremony's way back
    dw $013C                ;   enemy
    dw $0003                ;   actor
    dw $FF04                ; $04 open_screen: Open the arena party list (its texts begin “Milayou:Come back when you wanna breed.”)
    dw $0005                ;   kind
    dw $0660                ;   text
    dw $FF02                ; $02 clear_flag: Clear flag $010F
    dw $010F                ;   flag
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $0660                ; text $0660: "Milayou:Come back when you wanna breed."
    dw $FFFF                ; END
Bank0D_ScriptAddr_7C36:
    dw $0829                ; text $0829: "Milayou:Now, I want to go search for bet…"
    dw $FFFF                ; END
Bank0D_ScriptAddr_7C3A:
    dw $08C4                ; text $08C4: "Milayou:Have you caught monsters of the …"
    dw $FFFF                ; END
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
